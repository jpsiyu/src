%%%--------------------------------------
%%% @Module  : pp_activity_daily
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.24
%%% @Description: 每日活动列表
%%%--------------------------------------

-module(pp_activity_daily).
-include("server.hrl").
-include("unite.hrl").
-include("common.hrl").
-include("gift.hrl").
-include("activity.hrl").
-include("rank.hrl").
-export([handle/3,reflash_31483/1,no_list_to_string/2]).

%% 获取每日活动列表面板数据
handle(31401, PS, get_info) ->
	GiftListIds = lists:concat([
		?FIRST_RECHARGE_GIFT_ID, ",", 
		?NEWER_CARD_GIFT_ID, ",",
		?MOBILE_GIFT_ID, ",",
		?OTHER_GIFT_ID	
	]),
	Sql = io_lib:format(?SQL_GIFT_LIST_FETCH_MUTIL_ROW, [PS#player_status.id, GiftListIds]),
	Result = db:get_all(Sql),
	Data = case Result of
		[] ->
			private_format_info([]);
		List ->
			private_format_info(List)
	end,
	{ok, Bin} = pt_314:write(31401, Data),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 领取首充礼包
%% int:8	领取结果，1成功，2未充值，3已领取，4礼包数据有误，5背包格子不足，10失败
handle(31402, PS, fetch_gift) ->
	Status = lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?FIRST_RECHARGE_GIFT_ID),
	case Status of
		%% 未充过值
		-1 ->
			{ok, Bin} = pt_314:write(31402, 2),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		%% 已领取过奖励
		1 ->
			{ok, Bin} = pt_314:write(31402, 3),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		_ ->
			G = PS#player_status.goods,
			%% 先领取武器
			case lib_activity:fetch_first_recharge_weapon(PS, ?FIRST_RECHARGE_GIFT_ID, G) of
				{ok} ->
					case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, ?FIRST_RECHARGE_GIFT_ID}) of
						{ok, [ok, NewPS]} ->
							lib_gift_new:update_to_received(PS#player_status.id, ?FIRST_RECHARGE_GIFT_ID),
							%% 领取首充礼包时发传闻
							lib_activity:send_first_charge_cw(PS),
							{ok, Bin} = pt_314:write(31402, 1),
							lib_server_send:send_to_sid(PS#player_status.sid, Bin),
							
							%% 刷新任务中的首充任务为完成状态
							NewPS3 = case lib_task:is_finish(200140, NewPS) of
								true ->
									case pp_task:handle(30004, NewPS, [200140, {}]) of
										{ok, NewPS2} ->
											NewPS2;
										_ ->
											NewPS
									end;
								_ ->
									NewPS
							end,
							{ok, NewPS3};
						{ok, [error, ErrorCode]} ->
							{ok, Bin} = pt_314:write(31402, ErrorCode),
							lib_server_send:send_to_sid(PS#player_status.sid, Bin)
					end;
				{error, WeaponErr} ->
					{ok, Bin} = pt_314:write(31402, WeaponErr),
					lib_server_send:send_to_sid(PS#player_status.sid, Bin)
			end
	end;

%% 领取新手礼包
handle(31403, PS, Key) ->
	%% 检查号卡是否符合规则
	case lib_gift_check:check_gift_card(PS#player_status.accname, Key) of
		true ->
			%% 获取该领取的领取状态
			Status = lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?NEWER_CARD_GIFT_ID),
			case Status of
				-1 ->
					G = PS#player_status.goods,
					case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, ?NEWER_CARD_GIFT_ID}) of
						{ok, [ok, NewPS]} ->
							lib_gift_new:trigger_finish(PS#player_status.id, ?NEWER_CARD_GIFT_ID),
							{ok, Bin} = pt_314:write(31403, 1),
							lib_server_send:send_to_sid(PS#player_status.sid, Bin),
							{ok, NewPS};
						{ok, [error, ErrorCode]} ->
							if
								ErrorCode =:= 105 ->
									{ok, Bin} = pt_314:write(31403, 5),
									lib_server_send:send_to_sid(PS#player_status.sid, Bin);
								true ->
									{ok, Bin} = pt_314:write(31403, 4),
									lib_server_send:send_to_sid(PS#player_status.sid, Bin)
							end
					end;

				%% 已经领取过
				_ -> 
					{ok, Bin} = pt_314:write(31403, 3),
					lib_server_send:send_to_sid(PS#player_status.sid, Bin)
			end;
		_ ->
			{ok, Bin} = pt_314:write(31403, 2),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin)
	end;

%% 领取收藏游戏奖励
%% int:8	领取结果，1成功，2奖励已经赠送，3失败
handle(31404, PS, _) ->
	case lib_activity:collect_game_award(PS) of
		{error, ErrorCode} ->
			{ok, Bin} = pt_314:write(31404, ErrorCode),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		{ok, NewPS} ->
			{ok, Bin} = pt_314:write(31404, 1),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin),
			{ok, NewPS}
	end;

%% 请求是否获取过收藏游戏的奖励
%% int:8	领取结果，1成功，2奖励已经赠送，3失败
handle(31405, PS, _) ->
	Result = lib_activity:is_get_collect_award(PS#player_status.id),
	{ok, Bin} = pt_314:write(31405, Result),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% [活跃度] 查询面板数据
handle(31406, PS, get_active_info) ->
    %%pp_goods:handle(15084, PS, [30055 , 1001, 2]),
	NowTime = util:unixtime(),
	NowDay = util:unixdate(NowTime),
	case NowTime < NowDay + 300 of
		true -> skip;
		_ ->
			%% 三个任务需要特殊处理
%% 			Dailyhb = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6000001),		%% 皇榜
			Dailypl = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6000002),		%% 平乱
			Dailyzyt = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6000000),	%% 诛妖帖
%% 			case Dailyhb >= 5 of
%% 				true -> mod_active:check_finish(PS#player_status.status_active, 10, Dailyhb);
%% 				_ -> skip
%% 			end,
			case Dailypl >= 10 of
				true -> mod_active:check_finish(PS#player_status.status_active, 9, Dailypl);
				_ -> skip
			end,
			case Dailyzyt >= 3 of
				true -> mod_active:check_finish(PS#player_status.status_active, 11, Dailyzyt);
				_ -> skip
			end,

			%% 在线时长
			OnlineTime = lib_player:get_online_time_today(PS#player_status.id, PS#player_status.last_login_time),
			case OnlineTime >= 1.5 * 3600 of
				true -> mod_active:check_finish(PS#player_status.status_active, 14, 1);
				_ -> skip
			end
	end,

	[Active, LimitUp, OptList, AwardList] = mod_active:get_info(PS#player_status.status_active, PS),
	{ok, Bin} = pt_314:write(31406, [Active, LimitUp, OptList, AwardList]),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% [活跃度] 领取奖励
handle(31407, PS, get_my_allactive) ->
    AllActive = mod_active:get_my_allactive(PS#player_status.status_active),
    {ok, Bin} = pt_314:write(31407, [AllActive]),
    io:format("31407:~p~n",[[AllActive]]),
    lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% [活跃度] 领取奖励
%% handle(31407, PS, get_active_award) ->
%% 	case mod_active:fetch_award(PS#player_status.status_active, PS) of
%% 		{ok, NewPS, GiftList} ->
%% 			F = fun(GId) ->
%% 				<<GId:32>>
%% 			end,
%% 			NewGiftList = [F(Id) || Id <- GiftList],
%% 			{ok, Bin} = pt_314:write(31407, [1, NewGiftList]),
%% 			lib_server_send:send_to_sid(PS#player_status.sid, Bin),
%% 			{ok, NewPS};
%% 		{error, ErrorCode} ->
%% 			{ok, Bin} = pt_314:write(31407, [ErrorCode, []]),
%% 			lib_server_send:send_to_sid(PS#player_status.sid, Bin)
%% 	end;

%% 通过输入卡号领取奖励
handle(31408, PS, [CardType, TmpNewCardNo]) ->
	TmpNewCardNo1 = re:replace(TmpNewCardNo, "\"", "", [{return, list}, global]),
	NewCardNo = re:replace(TmpNewCardNo1, "\'", "", [{return, list}, global]),
	case lib_interface:trigger_card(PS, CardType, NewCardNo) of
		{ok, NewPS, GiftId} ->
			{ok, Bin} = pt_314:write(31408, [GiftId, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin),
			{ok, NewPS};
		{error, ErrorCode} ->
			{ok, Bin} = pt_314:write(31408, [0, ErrorCode]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		_ ->
			skip
	end;

%% [活跃度] 剩余项数
handle(31409, PS, get_active_left) ->
    ActiveSum = data_active:get_active_sum(PS#player_status.lv),
    ActiveDo = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 60000010),
    ActiveLeft = 
    case ActiveSum > ActiveDo of
        true -> ActiveSum - ActiveDo;
        _ -> 0
    end,
    {ok, Bin} = pt_314:write(31409, [ActiveLeft]),
    lib_server_send:send_to_uid(PS#player_status.id, Bin),
    {ok, PS};


%% [升级向前冲] 打开面板需要的数值
handle(31410, PS, _) ->
	[NewPS, List] = lib_activity:get_level_forward_data(PS),
	{ok, Bin} = pt_314:write(31410, List),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin),
	{ok, NewPS};

%% [升级向前冲] 领取奖励
handle(31411, PS, _) ->
	case lib_activity:fetch_level_forward_award(PS) of
		{ok, NewPS, Level} ->
			{ok, Bin} = pt_314:write(31411, [Level, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin),
			{ok, NewPS};
		{error, ErrorCode} ->
			{ok, Bin} = pt_314:write(31411, [0, ErrorCode]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		_ ->
			skip
	end;

%%  [首服充值活动] 打开面板
handle(31413, PS, _) ->
	[Recharge, List, LeftSecond] = lib_activity:get_recharge_activity_data(PS),
	{ok, Bin} = pt_314:write(31413, [Recharge, List, LeftSecond]),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%%  [首服充值活动] 领取礼包
handle(31414, PS, GiftId) ->
	case lib_activity:fetch_recharge_activity_gift(PS, GiftId) of
		{ok, NewPS} ->
			{ok, Bin} = pt_314:write(31414, [GiftId, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin),
			{ok, NewPS};
		{error, ErrorCode} ->
			LastPS = 
			case ErrorCode of
				2 ->
					case lib_task:is_finish(200140, PS) of
						true ->
							case pp_task:handle(30004, PS, [200140, {}]) of
								{ok, NewPS} ->
									NewPS;
								_ ->
									PS
							end;
						_ ->
							PS
					end;
				_ ->
					PS
			end,
			{ok, Bin} = pt_314:write(31414, [GiftId, ErrorCode]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin),
			{ok, LastPS};
		_ ->
			skip
	end;

%% [开服7天内每天登录奖励] 打开面板
handle(31415, PS, _) ->
    List = lib_activity:get_seven_day_login_data(PS),
    {ok, Bin} = pt_314:write(31415, List),
    lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% [开服7天内每天登录奖励] 领取奖励
handle(31416, PS, Day) ->
	case is_integer(Day) of
		true ->
			case lib_activity:get_seven_day_login_gift(PS, Day) of
		        {ok, NewPS, GiftId} ->
		            {ok, Bin} = pt_314:write(31416, [GiftId, 1]),
		        	lib_server_send:send_to_sid(PS#player_status.sid, Bin),
		            {ok, NewPS};
		        {error, ErrorCode} ->
                    io:format("~p ~p ErrorCode:~p~n", [?MODULE, ?LINE, ErrorCode]),
		            {ok, Bin} = pt_314:write(31416, [0, ErrorCode]),
		        	lib_server_send:send_to_sid(PS#player_status.sid, Bin)
		    end;
		_ ->
			{ok, Bin} = pt_314:write(31416, [0, 999]),
        	lib_server_send:send_to_sid(PS#player_status.sid, Bin)
	end;


%% [中秋国庆活动] 查看活跃度数据
handle(31417, PS, _) ->
	NowTime = util:unixtime(),
	%% 活动时间戳
	[Start, End] = data_activity:get_active_time(),
	case NowTime >= Start andalso NowTime =< End of
		true ->
			%% 礼包id
			GiftId = data_activity:get_active_gift(),
			%% 当前活跃度
			Active = mod_active:get_my_active(PS#player_status.status_active),

			{ok, Bin} = pt_314:write(
				31417,
				private_format_handle_31417(PS#player_status.dailypid, PS#player_status.id, Active, GiftId)
			),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		_ ->
			{ok, Bin} = pt_314:write(31417, []),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin)
	end;

%% [中秋国庆活动] 领取活跃度礼包
handle(31418, PS, Type) ->
	case lib_activity:fetch_active_gift(PS, Type) of
		{ok, NewPS, GiftId} ->
			{ok, Bin} = pt_314:write(31418, [Type, GiftId, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin),
			{ok, NewPS};
		{error, ErrorCode} ->
			{ok, Bin} = pt_314:write(31418, [Type, 0, ErrorCode]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin)
	end;

%% [充值送礼] 打开面板 
handle(31420, PS, _) -> 
	{ok, Bin} = pt_314:write(31420, lib_activity:get_recharge_award_data(PS)),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 临时，春节版 [充值送礼] 打开面板 
handle(31430, PS, _) -> 
	{ok, Bin} = pt_314:write(31430, lib_activity:get_recharge_award_data_tmp(PS)),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%%  [充值送礼] 领取礼包
handle(31421, PS, GiftId) -> 
	case lib_activity:fetch_recharge_award_gift(PS, GiftId) of
		{ok, NewPS} ->
			{ok, Bin} = pt_314:write(31421, [GiftId, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin),
			{ok, NewPS};
		{error, ErrorCode} ->
			{ok, Bin} = pt_314:write(31414, [GiftId, ErrorCode]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		_ ->
			skip
	end;

%% 临时，春节版 [充值送礼] 领取礼包
handle(31431, PS, GiftId) -> 
	case lib_activity:fetch_recharge_award_gift_tmp(PS, GiftId) of
		{ok, NewPS} ->
			{ok, Bin} = pt_314:write(31431, [GiftId, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin),
			{ok, NewPS};
		{error, ErrorCode} ->
			{ok, Bin} = pt_314:write(31414, [GiftId, ErrorCode]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		_ ->
			skip
	end;

%% 开服前10天每天领取绑定元宝状态
handle(31450, PS, _) ->
    case util:check_open_day(10) of
        true ->
            case mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6631451) of
                0 -> 
                    Error = 1;
                _ -> 
                    Error = 0
            end;
        false -> 
            Error = 0
    end,
	{ok, Bin} = pt_314:write(31450, Error),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 开服前10天每天领取绑定元宝
%% Res: 1或者2
handle(31451, PS, [Res]) ->
    case util:check_open_day(10) of
        true ->
            case Res =:= 1 orelse Res =:= 2 of
                true ->
                    ResType = 6631450 + Res,
                    case mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, ResType) of
                        0 -> 
                            mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, ResType, 1),
                            NewPS = lib_goods_util:add_money(PS, 10, bgold),
                            lib_player:refresh_client(PS#player_status.id, 2),
                            Error = 1;
                        _ -> 
                            NewPS = PS,
                            Error = 3
                    end;
                false -> 
                    NewPS = PS,
                    Error = 3
            end;
        false ->
            NewPS = PS,
            Error = 2
    end,
    {ok, Bin} = pt_314:write(31451, Error),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin),
    {ok, NewPS};

%% 获取活动奖励领取统计
handle(31480, PS, TypeList) ->
	NowTime = util:unixtime(),
	[private_handle_31480(PS, Type, NowTime) || Type <- TypeList],
	
	%% ---- 顺便放在这里触发 ---%%

	%% 世界等级经验加成
	lib_rank_helper:world_add_buff(PS),

	%% [斗战封神活动] 跨服战力排行活动
	lib_activity_kf_power:send_power_to_kf(PS);

%% 活动倍率数据
handle(31482, PS, []) ->
	_DataList = PS#player_status.all_multiple_data,
	NowTime = util:unixtime(),
	%%过滤掉过期的
	DataList = [{Type,Multiple,BeginTime,EndTime}||
				[_Id,Type,Multiple,BeginTime,EndTime]<-_DataList,
				NowTime=<EndTime],
	{ok,DataBin} = pt_314:write(31482, DataList),
	lib_server_send:send_to_sid(PS#player_status.sid, DataBin),
	ok;

%% 查询消费礼包 
handle(31483, PS, []) ->
	reflash_31483(PS);

%% 领取消费礼包 
handle(31484, PS, [T_No]) ->
	{Type,_New_PS,DataList,_,_} = get_consumption_list(PS),
	if
		Type=:=4-> %%正常情况
			case DataList of
				[]->%%无符合条件
					Result = 3,
					New_PS = _New_PS;
				_->
					% 唯一序号相同，切可领取状态
					_New_DataList = [{_No,GoodTypeId,GoodNum}||
									{_No,GoodTypeId,GoodNum,_Type,_Need_Eqout,_Need_Times,_Eqout,_Times}<-DataList,
									_No=:=T_No,
									_Type=:=1],
					if
						0<length(_New_DataList)->
							G = PS#player_status.goods,
							New_DataList = [{GoodTypeId, 1}||{_No,GoodTypeId, _GoodNum}<-_New_DataList],
							case gen_server:call(G#status_goods.goods_pid, {'give_more', _New_PS, New_DataList}) of
								ok ->									
									Consumption = PS#player_status.consumption,
									No_List = [No||{No,_GoodTypeId,_GoodNum}<-_New_DataList],
									GoodTypeIDList = [_GoodTypeId||{_No,_GoodTypeId,_GoodNum}<-_New_DataList],
									New_Gift = no_list_to_string(No_List,Consumption#status_consumption.gift),									
									case catch data_consumption_gift:all_data() of
									{'EXIT', Why} ->
										New_PS = _New_PS,
										catch util:errlog("data_consumption_gift error: ~p", [Why]);
									All_Data ->
										[TopOne|_] = All_Data,
										{_,_,_,GiftData} = TopOne,
										case lists:keyfind(repeat, 2, GiftData) of
											false -> 
												lib_player:update_consumption_gift(PS#player_status.id,New_Gift),
												New_PS = _New_PS#player_status{
													consumption = Consumption#status_consumption{gift=New_Gift}						   
												};
											%% 可重复领取的礼包处理
											GiftTuple -> 
											{_,_,_,_,RepeatGoodsId,_} =GiftTuple,
											case lists:member(RepeatGoodsId, GoodTypeIDList) of
												true ->
												lib_player:update_consumption_gift2(PS#player_status.id,New_Gift),
													New_PS = _New_PS#player_status{
														consumption = Consumption#status_consumption{
															gift=New_Gift,repeat_count=Consumption#status_consumption.repeat_count+1}
													};
												false ->
												lib_player:update_consumption_gift(PS#player_status.id,New_Gift),
													New_PS = _New_PS#player_status{
														consumption = Consumption#status_consumption{gift=New_Gift}						   
													}
											end
										end
									end,
									Result = 1;
								%% 物品类型不存在
								{fail, 2} ->
									New_PS = _New_PS,
									Result = 5;
								%% 背包格子不足
								{fail, 3} ->
									New_PS = _New_PS,
									Result = 2;
								%% 其他错误
								_ ->
									New_PS = _New_PS,
									Result = 5
							end;
						true-> % 无符合条件
							Result = 3,
							New_PS = _New_PS
					end
			end;
		true-> %%过期处理
			Result = 4,
			New_PS = _New_PS
	end,
	
	{ok,DataBin} = pt_314:write(31484, [Result]),
	lib_server_send:send_to_sid(PS#player_status.sid, DataBin),
	{ok,New_PS};

%% [合服] 打开面板需要的数据
handle(31485, PS, _) ->
	DayTime = lib_activity_merge:get_activity_day(),
	{ok,DataBin} = pt_314:write(31485, DayTime),
	lib_server_send:send_to_sid(PS#player_status.sid, DataBin);

%% [通用] 领取奖励
handle(31486, PS, In) ->
	case lib_activity:get_common_award(PS, In) of
		{ok, NewPS} ->
			{ok,DataBin} = pt_314:write(31486, [In, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, DataBin),
			{ok, NewPS};
		{error, Err} ->
			{ok,DataBin} = pt_314:write(31486, [In, Err]),
			lib_server_send:send_to_sid(PS#player_status.sid, DataBin)
	end;

%% [合服充值礼包] 打开面板
handle(31487, PS, _) ->
	case PS#player_status.mergetime of
		0 ->
			skip;
		_ ->
			case lib_activity_merge:get_recharge_gift_data(PS) of
				[Recharge, LeftSecond, List] ->
					{ok, Bin} = pt_314:write(31487, [Recharge, List, LeftSecond]),
					lib_server_send:send_to_sid(PS#player_status.sid, Bin);
				_ ->
					skip
			end
	end;

%% [合服充值礼包] 领取奖励
handle(31488, PS, GiftId) ->
	case lib_activity_merge:fetch_recharge_gift(PS, GiftId) of
		{ok} ->
			{ok, Bin} = pt_314:write(31488, [GiftId, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin),
			
			%% 刷新面板数据
			handle(31487, PS, get_data);
		{error, ErrorCode} ->
			{ok, Bin} = pt_314:write(31488, [GiftId, ErrorCode]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		_ ->
			skip
	end;

%% [幸福回归] 领取奖励
handle(31489, PS, _) ->
	[ErrorCode, NewPS] = lib_activity:get_back_activity_award(PS),
	{ok, Bin} = pt_314:write(31489, [ErrorCode]),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin),
	{ok, NewPS};

%% 开服充值累计送礼包活动基本信息
handle(31490, PS, _) ->
	OpenTime = util:get_open_time(),
	Recharge1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, OpenTime, OpenTime + 5 * 24 * 60 * 60),
	Recharge2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, OpenTime, OpenTime + 5 * 24 * 60 * 60),
	Recharge = Recharge1 + Recharge2,
	TotalNum = Recharge div 500,
	RechageNeed = 500 - Recharge rem 500,
	case TotalNum > 0 of
		true ->
			NumGot = lib_activity:get_kf5_gift_num(PS),
			NumNow = case NumGot > TotalNum of
				true ->
					0;
				false ->
					TotalNum - NumGot
			end,
			{ok, Bin} = pt_314:write(31490, [NumNow, RechageNeed]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		false ->
			{ok, Bin} = pt_314:write(31490, [0, RechageNeed]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin)
	end,
	{ok, PS};

%% 开服充值累计送礼包活动领取礼包
handle(31491, PS, _) ->
	OpenTime = util:get_open_time(),
	Recharge1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, OpenTime, OpenTime + 5 * 24 * 60 * 60),
	Recharge2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, OpenTime, OpenTime + 5 * 24 * 60 * 60),
	Recharge = Recharge1 + Recharge2,
%% 	io:format("Recharge  2 ~p~n", [Recharge]),
	TotalNum = Recharge div 500,
	case TotalNum > 0 of
		true ->
			NumGot = lib_activity:get_kf5_gift_num(PS),
			Res = case NumGot > TotalNum of
				true ->
					2;
				false ->
					Res1 = lib_activity:get_one_kf5_gigt(PS, TotalNum),
					case Res1 of
						1 ->
							Go = PS#player_status.goods,
							case gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', [], [{534095, 1}]}) of
								ok ->
									0;
								_RR->
									1
							end;
						_R ->
							1
					end
			end,
			{ok, Bin} = pt_314:write(31491, [Res]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		false ->
			{ok, Bin} = pt_314:write(31491, [2]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin)
	end,
	{ok, PS};

%% 开服充值累计送礼包活动基本信息
handle(31492, PS, _) ->
	{ok, Bin} = pt_314:write(31492, [1]),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin),
	{ok, PS};

%% 消费返元宝查询
handle(31493, PS, _) ->
	NowTime = util:unixtime(),		
	[_StartTime, EndTime] = data_consume_returngold:get_time(),
	case PS#player_status.lv <40 of
		true ->
			ListData = [], LeftTime = 0;
		false ->
		case data_consume_returngold:is_openning() of
			true ->
				ListData = lib_activity:fetch_consume_returngold_data(PS),
				LeftTime = EndTime-NowTime;
			false -> ListData = [], LeftTime = 0
		end
	end,
	{ok, Bin} = pt_314:write(31493, [ListData, LeftTime]),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 领取消费返元宝
handle(31494, PS, [Id]) when is_integer(Id) ->
	Result = lib_activity:gain_consume_returngold(Id, PS),	
	case Result of
		{ok, ErrorCode} -> handle(31493, PS, []);
		{error, ErrorCode} -> skip
	end,
	{ok, Bin} = pt_314:write(31494, [ErrorCode]),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 错误处理
handle(Cmd, _Status, _Data) ->
	util:errlog("pp_activity_daily: cmd[~p] no match", [Cmd]),
	{error, "pp_activity_daily no match"}.

%%组织领取礼包列表
no_list_to_string([], Str) ->
	Str;
no_list_to_string(List, Str) when Str=:="'" orelse Str =:=","->
	no_list_to_string(List, "");
no_list_to_string([No|T], Str) when No=:= "'" ->
	no_list_to_string(T,Str);
no_list_to_string([No|T] ,Str)->
	New_Str = lists:concat([Str,",",No]),
	no_list_to_string(T,New_Str).

reflash_31483(PS)->
	NowTime = util:unixtime(),
	{_Type,New_PS,DataList,_T_BeginTime,T_EndTime} = get_consumption_list(PS),
	if
		T_EndTime-NowTime<0->
			RestTime = 0;
		true->
			RestTime = T_EndTime-NowTime
	end,
%%	% 合服期间内不出现消费返利
%%	case PS#player_status.mergetime>0 andalso lib_activity_merge:get_merge_day() =< 5 of
%%		true -> NewDataList = [], NewRestTime = 0;
%%		false -> NewDataList = DataList, NewRestTime = RestTime
%%	end,
	NewDataList = DataList, NewRestTime = RestTime,
	{ok,DataBin} = pt_314:write(31483, [NewDataList,NewRestTime]),
	lib_server_send:send_to_sid(PS#player_status.sid, DataBin),
	{ok,New_PS}.
%%获取消费礼包列表
get_consumption_list(PS)->
	Consumption = PS#player_status.consumption,
	case data_consumption_gift:get_element() of
		[]-> %无策划数据情况
			lib_player:delete_player_consumption(PS#player_status.id),
			New_Consumption = #status_consumption{},
			New_PS = PS#player_status{consumption = New_Consumption},
			Type = 2,%%过期
			DataList = [],
			T_BeginTime=0,T_EndTime=0;
		{BeginTime,EndTime,GiftList}->
			if
				Consumption#status_consumption.end_time >= (EndTime + 15*24*60*60) -> %不一致结束时间，将视为过期数据[加上时间差用于热更容错]
					lib_player:delete_player_consumption(PS#player_status.id),
					New_Consumption = #status_consumption{},
					New_PS = PS#player_status{consumption = New_Consumption},
					GiftStrList = string:tokens("", ","),
					Type = 4; %%过期
				true-> %%合法数据
					New_PS = PS,
					Gift = Consumption#status_consumption.gift,
					GiftStrList = string:tokens(Gift, ","),
					Type = 4 %%正常
			end,
			T_BeginTime=BeginTime,T_EndTime=EndTime,
			DataList = get_datalist(GiftList,GiftStrList,Consumption,[])
	end,
	{Type,New_PS,DataList,T_BeginTime,T_EndTime}.

%%获取未领取礼包数组
get_datalist(GiftList,GiftStrList,Consumption,ResultList)->
	case GiftList of
		[]->ResultList;
		[{No,Type,Need_Eqout,Need_Times,Goods_id,Goods_num}|T]->
			Flag = lists:member(integer_to_list(No), GiftStrList),
			case Type of
				all->
					Eqout = Consumption#status_consumption.eqout_taobao+
							Consumption#status_consumption.eqout_shangcheng+
							Consumption#status_consumption.eqout_petcz+
							Consumption#status_consumption.eqout_petqn+
							Consumption#status_consumption.eqout_smsx+
							Consumption#status_consumption.eqout_smgm+
							Consumption#status_consumption.eqout_petjn+
							Consumption#status_consumption.eqout_cmsd,
					Times = Consumption#status_consumption.times_taobao+
							Consumption#status_consumption.times_shangcheng+
							Consumption#status_consumption.times_petcz+
							Consumption#status_consumption.times_petqn+
							Consumption#status_consumption.times_smsx+
							Consumption#status_consumption.times_smgm+
							Consumption#status_consumption.times_petjn+
							Consumption#status_consumption.times_cmsd;
				repeat->
					Eqout = Consumption#status_consumption.eqout_taobao+
							Consumption#status_consumption.eqout_shangcheng+
							Consumption#status_consumption.eqout_petcz+
							Consumption#status_consumption.eqout_petqn+
							Consumption#status_consumption.eqout_smsx+
							Consumption#status_consumption.eqout_smgm+
							Consumption#status_consumption.eqout_petjn+
							Consumption#status_consumption.eqout_cmsd,
					Times = Consumption#status_consumption.times_taobao+
							Consumption#status_consumption.times_shangcheng+
							Consumption#status_consumption.times_petcz+
							Consumption#status_consumption.times_petqn+
							Consumption#status_consumption.times_smsx+
							Consumption#status_consumption.times_smgm+
							Consumption#status_consumption.times_petjn+
							Consumption#status_consumption.times_cmsd;
				taobao->
					Eqout = Consumption#status_consumption.eqout_taobao,
					Times = Consumption#status_consumption.times_taobao;
				shangcheng->
					Eqout = Consumption#status_consumption.eqout_shangcheng,
					Times = Consumption#status_consumption.times_shangcheng;
				petcz->
					Eqout = Consumption#status_consumption.eqout_petcz,
					Times = Consumption#status_consumption.times_petcz;
				petqn->
					Eqout = Consumption#status_consumption.eqout_petqn,
					Times = Consumption#status_consumption.times_petqn;
				smsx->
					Eqout = Consumption#status_consumption.eqout_smsx,
					Times = Consumption#status_consumption.times_smsx;
				smgm->
					Eqout = Consumption#status_consumption.eqout_smgm,
					Times = Consumption#status_consumption.times_smgm;
				petjn->
					Eqout = Consumption#status_consumption.eqout_petjn,
					Times = Consumption#status_consumption.times_petjn;
				cmsd->
					Eqout = Consumption#status_consumption.eqout_cmsd,
					Times = Consumption#status_consumption.times_cmsd;
				_->
					Eqout = 0,Times = 0
			end,
			if
				Need_Eqout =< Eqout andalso Need_Times =< Times andalso Type=/=repeat-> %%符合条件，且未领取过
					case Flag of
						false-> % 未领取
							get_datalist(T,GiftStrList,Consumption,ResultList++[{No,Goods_id,Goods_num,1,Need_Eqout,Need_Times,Eqout,Times}]);
						true->  % 已领取
							get_datalist(T,GiftStrList,Consumption,ResultList++[{No,Goods_id,Goods_num,2,Need_Eqout,Need_Times,Eqout,Times}])
					end;
				Type=:=repeat -> %% 重复礼包处理					
					RepeatCount = Consumption#status_consumption.repeat_count,					
					CanFetchTotal = Eqout div Need_Eqout,
					case CanFetchTotal>RepeatCount of
						true ->
						%% 可领取
						Goods_num2 = CanFetchTotal-RepeatCount,
						get_datalist(T,GiftStrList,Consumption,ResultList++[{No,Goods_id,Goods_num2,1,Need_Eqout,Need_Times,Eqout,Times}]);
						false ->
						%% 不可领
						get_datalist(T,GiftStrList,Consumption,ResultList++[{No,Goods_id,0,0,Need_Eqout,Need_Times,Eqout,Times}])
					end;
				true->
					get_datalist(T,GiftStrList,Consumption,ResultList++[{No,Goods_id,Goods_num,0,Need_Eqout,Need_Times,Eqout,Times}])
			end
	end.

%% 组织数据
private_format_info([]) ->
	[<<?FIRST_RECHARGE_GIFT_ID:32, 1:8>>, <<?NEWER_CARD_GIFT_ID:32, 1:8>>, <<?MOBILE_GIFT_ID:32, 1:8>>, <<?OTHER_GIFT_ID:32, 1:8>>];
private_format_info(List)  when is_list(List) ->
	GiftIds = [?FIRST_RECHARGE_GIFT_ID, ?NEWER_CARD_GIFT_ID, ?MOBILE_GIFT_ID, ?OTHER_GIFT_ID],

	F2 = fun([_RoleId, RoleGiftId, Status], [GiftId, NewList]) ->
		if
			RoleGiftId =:= GiftId ->
				NewStatus = Status + 1,
				[GiftId, [NewStatus]];
			true ->
				[GiftId, NewList]
		end
	end,

	F = fun(GiftId) ->
		[_, Result]= lists:foldl(F2, [GiftId, []], List),
		case Result of
			[] ->
				<<GiftId:32, 1:8>>;
			[Status] ->
				<<GiftId:32, Status:8>>
		end
	end,

	[F(Id) || Id <- GiftIds].

%% 中秋国庆活动：获取活跃度礼包状态
private_get_active_gift_status(Pid, RoleId, Active, RequireActive, CacheKey) ->
	case mod_daily:get_count(Pid, RoleId, CacheKey) of
		1 -> 2;
		_ ->
			case Active >= RequireActive of
				true -> 1;
				_ -> 0
			end
	end.

private_format_handle_31417(DailyPid, RoleId, Active, GiftId) ->
	ConfList = data_activity:get_active_conf(),
	lists:map(fun([Type, RequireActive, CacheKey]) -> 
		AwardStatus = private_get_active_gift_status(DailyPid, RoleId, Active, RequireActive, CacheKey),
		<<Type:8, RequireActive:8, GiftId:32, AwardStatus:8>>
	end, ConfList).

private_handle_31480(PS, Type, NowTime) ->
	if 
		%% 如果是首充礼包或充值回馈礼包，需要具体判断
		Type =:= 102 ->
			%% 特殊时间
			SpecialTime = util:unixdate(util:unixtime(data_activity:get_special_day())),
			%% 开服时间
			OpenTime = util:unixdate(util:get_open_time()),
			%% 特殊活动时间段，秒数
			SpaceTime = data_activity:get_special_daynum() * 86400,
			%% 正常活动时间段
			CommonTime = data_activity:get_common_daynum() * 86400,

			%% 老服，有新活动
			case OpenTime < SpecialTime andalso NowTime < SpecialTime + SpaceTime of
				true ->
				    	case lib_activity:get_finish_stat(PS, Type) of
						[Status, Level] ->
							case Status =:= 0 of
								true ->
									{ok, Bin} = pt_314:write(31480, [Type, 2, Level]),
									lib_server_send:send_to_sid(PS#player_status.sid, Bin);
								_ ->
									skip
							end;
						_ ->
							skip
					end;
				_ ->
					%% 如果老服已经过了活动时间，而且首充还没有充，则显示首充图标
					case lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_1) of
						1 ->
							skip;
						_ ->
							{ok, Bin} = pt_314:write(31480, [Type, 1, 10]),
							lib_server_send:send_to_sid(PS#player_status.sid, Bin)
					end
			end,

			%% 新服，有新活动
			case OpenTime >= SpecialTime andalso NowTime < OpenTime + CommonTime of
				true ->
					case lib_activity:get_finish_stat(PS, Type) of
						[Status2, Level2] ->
							case Status2 =:= 0 of
								true ->
									case lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_1) of
										%% 已经领取了首充礼包，下面需要视情况决定要不要显示“充值回馈”图标
										1 ->
											{ok, Bin2} = pt_314:write(31480, [Type, 2, Level2]),
											lib_server_send:send_to_sid(PS#player_status.sid, Bin2);
										_ ->
											{ok, Bin2} = pt_314:write(31480, [Type, 1, Level2]),
											lib_server_send:send_to_sid(PS#player_status.sid, Bin2)
								    	end;
								_ ->
									{ok, Bin2} = pt_314:write(31480, [Type, 2, Level2]),
									lib_server_send:send_to_sid(PS#player_status.sid, Bin2)
							end;
						_ ->
							skip
					end;
			    _ ->
					skip
			end;

		%% 中秋国庆活动鲜花榜和护花榜
		Type =:= 103 ->
			[Start, End] = data_activity:get_charm_time(),
			case NowTime >= Start andalso NowTime =< End of
				true ->
					{ok, Bin} = pt_314:write(31480, [Type, 1, 1]),
					lib_server_send:send_to_sid(PS#player_status.sid, Bin);
				_ ->
					skip
			end;

		%% 合服图标
		Type =:= 104 ->
			%% 判断是否有合过服
			case lib_activity_merge:get_activity_day() of
				0 ->
					skip;
				DayTime ->
					%% 判断是否在合服后的第N天内
					case DayTime + data_merge:get_longest_day() * 86400 < util:unixtime() of
						true ->
							skip;
						_ ->
							{ok, Bin} = pt_314:write(31480, [Type, 0, 1]),
							lib_server_send:send_to_sid(PS#player_status.sid, Bin)
					end
			end;

		%% 幸福回归图标
		Type =:= 108 ->
			[Status, Level] = lib_activity:get_back_activity_stat(PS, 1),
			{ok, Bin} = pt_314:write(31480, [Type, Status, Level]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);

		%% 斗战封神活动
		Type =:= 112 ->
			case PS#player_status.lv >= data_activity:get_kf_power_config(level) of
				true ->
					case data_activity_time:get_time_by_type(13) of
						[StartTime112, EndTime112] ->
							case NowTime >= StartTime112 andalso NowTime =< EndTime112 of
								true -> 
									{ok, Bin} = pt_314:write(31480, [Type, 0, 0]),
									lib_server_send:send_to_sid(PS#player_status.sid, Bin);
								_ -> skip
							end;
						_ -> skip
					end;
				_ -> skip
			end;

		%% 100服活动
		Type =:= 113 ->
			case lib_activity_100servers:get_conf() of
				[] ->
					skip;
				[_Gold, _GiftId, StartTime, EndTime] ->
					case NowTime >= StartTime andalso NowTime =< EndTime of
						true ->
							case lib_activity:get_finish_stat(PS, Type) of
								[Status, Level] ->
									{ok, Bin} = pt_314:write(31480, [Type, Status, Level]),
									lib_server_send:send_to_sid(PS#player_status.sid, Bin);
								_ ->
									skip
							end;
						_ ->
							skip
					end
			end;

		%% 节日充值活动:类型1图标
		Type =:= 111 ->
			Status = lib_activity_festival:check_time(PS, Type),
			{ok, Bin} = pt_314:write(31480, [Type, Status, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);

		true ->
			case lib_activity:get_finish_stat(PS, Type) of
				[Status, Level] ->
					{ok, Bin} = pt_314:write(31480, [Type, Status, Level]),
					lib_server_send:send_to_sid(PS#player_status.sid, Bin);
				_ ->
					skip
			end
	end.
