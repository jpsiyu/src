%%%--------------------------------------
%%% @Module  : lib_recharge
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.24
%%% @Description: 充值相关
%%%--------------------------------------

-module(lib_recharge).
-include("server.hrl").
-include("gift.hrl").
-include("recharge.hrl").
-export([
	pay/1,
    get_recharge/0,
	pay_by_goods/3,
    get_total/1
]).

%% 取出一批待处理的充值记录
get_recharge() ->
	PayList = case catch lib_recharge_ds:get_all_recharge() of
		[] ->
			[];
		List when is_list(List) -> 
			List;
		_ -> 
			[]
	end,
	PayList.

%% 充值
%% 定时器每分钟会调用一次该接口
%% 返回：[#player_status, 邮件数量]
pay(PS) ->
	RoleId = PS#player_status.id,

	%% 原充值总额
	OldRechargeMoney = lib_recharge_ds:get_total(RoleId),

	%% 取出玩家所有充值待处理记录
    case catch lib_recharge_ds:get_my_all_recharge(RoleId) of
		%% 没有充值记录要处理
		[] ->
			[PS, 0];

		PayList when is_list(PayList) ->
			TransFun = fun() ->
				LoopFun = fun([Id, _Type, Gold, _Ctime, PayNo], [Status, TotalRecharge, SingleOrderList]) ->
					case PayNo of
						undefined ->
							[Status, TotalRecharge, SingleOrderList];
						_ ->
							%% 增加元宝
							Status1 = lib_player:add_money(Status, Gold, gold),

							%% 修改充值记录状态为已经处理
							lib_recharge_ds:finish_recharge(Id),

							%% 充值日志
							log:log_produce(pay, gold, Status, Status1, lists:concat(["PayNo : ", binary_to_list(PayNo)])),

							[Status1, TotalRecharge + Gold, [Gold | SingleOrderList]]
					end
				end, %% function LoopFun end
				[NewStatus, NewTotalRecharge, NewSingleOrderList] = lists:foldl(LoopFun, [PS, OldRechargeMoney, []], PayList),

				%% 更新充值总额
				lib_recharge_ds:update_total_recharge(RoleId, NewTotalRecharge),

				{ok, NewStatus, NewTotalRecharge, NewSingleOrderList}
			end, %% function TransFun end

			case db:transaction(TransFun) of
				{ok, PNewStatus, PNewRecharge, PNewOrderList} ->
					%% 发送首充礼包通知
					private_send_first_recharge(PS),

					%% 首充礼包处理
					case OldRechargeMoney =< 0 of
						true ->
							lib_recharge_ds:first_recharge_gift(RoleId);
						_ ->
							skip
					end,

					%% 充值邮件
					NowTime = util:unixtime(),
					{{Y, M, D}, {H, N, _S}} = calendar:now_to_local_time(util:unixtime_to_now(NowTime)),
					Title = data_recharge_text:get_mail_title(),
					GetMoney = PNewRecharge - OldRechargeMoney,
					Content = io_lib:format(data_recharge_text:get_email_content(), [Y, M, D, H, N, GetMoney]),
					mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[RoleId], Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0]),

					spawn(fun() -> 
						%% 活动：充值任务
						%% 在活动时间内，且开服大于5天，才会触发
						lib_activity:pay_task_do_recharge(PNewStatus),

						%% 活动：普通充值任务
						lib_activity:finish_pay_task(PNewStatus, PNewRecharge),

	                    %% 合服活动：统计合服后N天充值总额
	                    lib_activity_merge:update_recharge(PS, PNewRecharge - OldRechargeMoney),

						%% [幸福回归] -- 回归首充奖励
						catch lib_activity:back_activity_charge_award(PNewStatus, PNewRecharge - OldRechargeMoney),

						%% [开服活动] 充值活动
						catch lib_activity:count_31490(PNewStatus),

						%% 单笔充值总额相关活动
						private_single_order_recharge(PS#player_status.pid, RoleId, PNewOrderList)		  
					end),

					[PNewStatus#player_status{is_pay = true}, 1];
				_Error ->
					util:errlog("do recharge error, Error = ~p~n", [_Error]),
					[PS, 0]
			end;
		_ ->
			[PS, 0]
	end.

%% 使用物品充值
%% 走充值逻辑，但不涉及影响游戏收入统计，流水统计
pay_by_goods(PS, Gold, GoodsId) ->
	RoleId = PS#player_status.id,

	%% 原充值总额
	OldRechargeMoney = lib_recharge_ds:get_total(RoleId),

	%% 增加元宝
	PS1 = lib_player:add_money(PS, Gold, gold),
	
	%% 更新充值总额
	lib_recharge_ds:update_total_recharge(RoleId, OldRechargeMoney + Gold),
	
	%% 发送首充礼包通知
	private_send_first_recharge(PS1),
	
	%% 首充礼包处理
	case OldRechargeMoney =< 0 of
		true ->
			lib_recharge_ds:first_recharge_gift(RoleId);
		_ ->
			skip
	end,

	%% 充值邮件
	NowTime = util:unixtime(),
	{{Y, M, D}, {H, N, _S}} = calendar:now_to_local_time(util:unixtime_to_now(NowTime)),
	Title = data_recharge_text:get_mail_title(),
	Content = io_lib:format(data_recharge_text:get_email_content(), [Y, M, D, H, N, Gold]),
	mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[RoleId], Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
    %% 写入元宝道具日志
	log:log_gold_goods(RoleId, Gold, GoodsId),

	%% 活动：充值任务
	%% 在活动时间内，且开服大于5天，才会触发
	lib_activity:pay_task_do_recharge(PS1),

	%% 活动：普通充值任务
	lib_activity:finish_pay_task(PS1, OldRechargeMoney + Gold),

	%% 合服活动：统计合服后N天充值总额
	lib_activity_merge:update_recharge(PS1, Gold),

	%% [幸福回归] -- 回归首充奖励
	catch lib_activity:back_activity_charge_award(PS1, Gold),
	
	%% [开服活动] 充值活动
	catch lib_activity:count_31490(PS1),

	%% 日志
	log:log_produce(get_gold, gold, PS, PS1, ""),
	
	%% 单笔充值总额相关活动
	private_single_order_recharge(PS#player_status.pid, RoleId, [Gold]),

	{ok, PS1}.

%% 获取充值总额
get_total(RoleId) ->
	lib_recharge_ds:get_total(RoleId).

%% 发送首充礼包通知
private_send_first_recharge(PS) ->
	{ok, Bin} = pt_314:write(31413, lib_activity:get_recharge_activity_data(PS)),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin).

%% 单笔充值总额相关活动
private_single_order_recharge(PId, RoleId, PNewOrderList) ->
	case PNewOrderList of
		[] -> skip;
		_ -> [lib_activity_festival:update_single_recharge_gift_list(RoleId, PId, Gold) || Gold <- PNewOrderList]
	end.
