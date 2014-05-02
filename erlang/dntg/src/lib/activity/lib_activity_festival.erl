%%%-------------------------------------- 
%%% @Module  : lib_activity_festival
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.8.22
%%% @Description: 应节日需求运营活动
%%%--------------------------------------

-module(lib_activity_festival).
-include("designation.hrl").
-include("rank.hrl").
-include("server.hrl").
-include("unite.hrl").
-include("gift.hrl").
-include("rank_cls.hrl").
-include("activity.hrl").
-include("daily.hrl").
-export([
	qixi_bind_design_for_rank/1,		%% 七夕，排行榜绑定称号活动
	do_middle_and_national/0,			%% 中秋国庆活动：发放魅力榜奖励
	bind_middle_and_national_design/2,	%% 中秋国庆活动：绑定魅力榜称号
	handle_charm_rank_in_manage/1,		%% 管理后台执行魅力鲜花榜奖励
	handle_charm_rank_in_manage2/1		%% 管理后台执行魅力鲜花榜奖励
]).
-compile(export_all).

%% 排行榜 七夕
%% 活动期间每日鲜花榜第1名获得称号
qixi_bind_design_for_rank(RoleId) ->
	%% 称号：七夕宝贝
	DesignId = 201402,
	%% 活动开始，结束时间
	[StartTime, EndTime] = private_qixi_bind_design_time(),
	Now = util:unixtime(),
	%% 在活动期间内，第一名的玩家会绑定称号
	case Now >= StartTime andalso Now < EndTime of
		true ->
			lib_designation:bind_design(RoleId, DesignId, "", 1);
		_ ->
			skip
	end,
	%% 在活动结束后的第一天内，把获得了该称号的玩家的称号取消掉
	case Now >= EndTime andalso Now < EndTime + 86400 of
		true ->
			case db:get_all(io_lib:format(?SQL_DESIGN_GET_ROLE_BY_DESIGN, [DesignId])) of
			    	List when is_list(List) ->
					lists:map(fun([OldRoleId]) -> 
						lib_designation:remove_design_in_server(OldRoleId, DesignId)
					end, List);
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%% [公共线] 处理鲜花魅力榜奖励
do_middle_and_national() ->
	NowTime = util:unixtime(),
    NowDay = util:unixdate(NowTime),
	[Start, End] = data_activity:get_charm_time(),
	%% 在活动规则的期间内，每天凌晨的0:0:0至0:30:0时处理奖励
	case NowTime >= Start andalso NowTime =< End + 1800 andalso NowTime >= NowDay andalso NowTime < NowDay + 1800 of
		true ->
			case db:get_row(io_lib:format(?sql_daily_role_sel_type, [0, 1000])) of
				[] ->
					db:execute(io_lib:format(?sql_daily_role_upd, [0, 1000, 1, NowTime])),
					private_send_middle_and_national_award(?RK_CHARM_DAY_HUHUA),
					private_send_middle_and_national_award(?RK_CHARM_DAY_FLOWER);
				[_, _, Count, RefreshTime] ->
					case Count /= 1 orelse RefreshTime < NowDay of
						true ->
							db:execute(io_lib:format(?sql_daily_role_upd, [0, 1000, 1, NowTime])),
							private_send_middle_and_national_award(?RK_CHARM_DAY_HUHUA),
							private_send_middle_and_national_award(?RK_CHARM_DAY_FLOWER);
						_ ->
							skip
					end;
				_ ->
					skip
			end;
		_ ->
			%% 如果在活动结束后的第二天，清理西游第一美和西游第一帅称号
			case NowTime > End + 86400 andalso NowTime < End + 86400 + 1800 of
				true ->
                    private_remove_designation(201402),
					private_remove_designation(201408);
				_ ->
					skip
			end
	end.

%% 中秋国庆活动：绑定鲜花魅力榜称号
bind_middle_and_national_design(RankType, RoleId) ->
	NowTime = util:unixtime(),
	[Start, End] = data_activity:get_charm_time(),
	case NowTime >= Start andalso NowTime =< End of
		true ->
			%% 绑定称号
			DesignId = case RankType == ?RK_CHARM_DAY_FLOWER of
				true -> 201402;
				_ -> 201408
			end,
			lib_designation:bind_design_in_server(RoleId, DesignId, "", 1);
		_ ->
			skip
	end.

%% 管理后台补发魅力鲜花榜奖励
%% Sex : 1男，2女
handle_charm_rank_in_manage(Sex) ->
	mod_disperse:cast_to_unite(lib_activity_festival, handle_charm_rank_in_manage2, [Sex]).
handle_charm_rank_in_manage2(Sex) ->
	spawn(fun() -> 
		%% 这里的时间写死
%% 		StartTime = util:unixdate(),
%% 		EndTime = StartTime + 86400,
		StartTime = 1352563200,
		EndTime = StartTime + 86400,
		private_handle_charm_rank_1(Sex, StartTime, EndTime)
	end).

private_handle_charm_rank_1(Sex, Start, End) ->
	%% 查出收到多少花
	Sql = <<"SELECT toid,flower FROM (
		SELECT toid, SUM(num) AS flower FROM log_flower 
		WHERE sex=~p and toid<>fromid AND time BETWEEN ~p AND ~p 
		GROUP BY toid ORDER BY flower DESC
		) AS result LIMIT 100">>,
	List1 = db:get_all(io_lib:format(Sql, [Sex, Start, End])),

	%% 查出送了多少花
	Sql2 = <<"SELECT fromid,flower FROM (
		SELECT log.fromid, SUM(num) AS flower FROM log_flower as log left join player_low as pl on log.fromid=pl.id 
		WHERE pl.sex=~p and log.time BETWEEN ~p AND ~p 
		GROUP BY log.fromid ORDER BY flower DESC
		) AS result LIMIT 100">>,
	List2 = db:get_all(io_lib:format(Sql2, [Sex, Start, End])),

	private_handle_charm_rank_2(
		private_to_tuple(List1),
		private_to_tuple(List2)
	).

private_handle_charm_rank_2(List1, List2) ->

	Length1 = length(List1),
	Length2 = length(List2),
	[L1, L2] = if
		Length1 >= Length2 -> [List1, List2];
		true -> [List2, List1]
	end,

	case length(L1) > 0 of
		true ->
			%% 合并前100名
			LastList = 
			lists:foldl(fun({Id, Flower}, List) -> 
				case lists:keysearch(Id, 1, L2) of
					{value, _} -> 
						{_, NewFlower} = private_handle_1(L2, {Id, Flower}),
						[{Id, NewFlower} | List];
					false -> 
						[{Id, Flower} | List]
				end
			end, [], L1),

			%% 取出前10名送奖励
			private_handle_charm_rank_3(LastList);
		_ ->
			skip
	end.

private_handle_1([], {CId, CFlower}) -> {CId, CFlower};
private_handle_1([{Id, Flower} | Tail], {CId, CFlower}) ->
	case Id =:= CId of
		true -> {Id, Flower + CFlower};
		_ -> private_handle_1(Tail, {CId, CFlower})
	end.

private_handle_charm_rank_3(List) ->
	%% 排序
	F1 = fun({_Id1, Flower1}, {_Id2, Flower2}) -> 
		Flower1 >= Flower2
	end,
	List2 = lists:sort(F1, List),
	%% 取前10名
	Length = length(List2),
	List3 = 
	if
		Length >= 10 -> lists:sublist(List2, 10);
		true -> lists:sublist(List2, Length)
	end,
	%% 发奖励
	List4 = [[LastId] || {LastId, _} <- List3],
	[OneList, SecondList, ThirdList, FouthList, _] = 
	lists:foldl(fun([Id], [TmpOneList, TmpSecondList, TmpThirdList, TmpFouthList, Position]) -> 
		if
            Position == 1 ->
                [[Id | TmpOneList], TmpSecondList, TmpThirdList, TmpFouthList, Position+1];
			Position == 2 ->
                [TmpOneList, [Id | TmpSecondList], TmpThirdList, TmpFouthList, Position+1];
            Position == 3 ->
                [TmpOneList, TmpSecondList, [Id | TmpThirdList], TmpFouthList, Position+1];
            Position >= 4 andalso Position =< 10 ->
                [TmpOneList, TmpSecondList, TmpThirdList, [Id | TmpFouthList], Position+1];
            true ->
                [TmpOneList, TmpSecondList, TmpThirdList, TmpFouthList, Position+1]
        end
	end, [[], [], [], [], 1], List4),

	Title = data_activity_text:get_middle_and_national_charm_title(),

	%% 处理第一名
	case OneList of
		[] ->
			skip;
		_ ->
			%% 发邮件奖励
			private_send_gift_mail(
                OneList,
                Title,
                data_activity_text:get_middle_and_national_charm_content(1),
                private_get_goodsid_by_gift(data_activity:get_charm_gift(1)),
				1
            )
	end,

	%% 处理第二名
	case SecondList of
		[] ->
			skip;
		_ ->
			%% 发邮件奖励
			private_send_gift_mail(
                SecondList,
                Title,
                data_activity_text:get_middle_and_national_charm_content(2),
                private_get_goodsid_by_gift(data_activity:get_charm_gift(2)),
				1
            )
	end,
	
	%% 处理第三名
	case ThirdList of
		[] ->
			skip;
		_ ->
			%% 发邮件奖励
			private_send_gift_mail(
                ThirdList,
                Title,
                data_activity_text:get_middle_and_national_charm_content(3),
                private_get_goodsid_by_gift(data_activity:get_charm_gift(3)),
				1
            )
	end,
	
	%% 处理第四至十名
	case FouthList of
		[] ->
			skip;
		_ ->
			%% 发邮件奖励
			private_send_gift_mail(
                FouthList,
                Title,
                data_activity_text:get_middle_and_national_charm_content(4),
                private_get_goodsid_by_gift(data_activity:get_charm_gift(4)),
				1
            )
	end.
	
private_to_tuple(List) -> 
	lists:map(fun(Row) -> 
		list_to_tuple(Row)		  
	end, List).
	




%% 移除称号
private_remove_designation(DesignId) ->
	case db:get_all(io_lib:format(?SQL_DESIGN_GET_ROLE_BY_DESIGN, [DesignId])) of
	    List when is_list(List) ->
			lists:map(fun([OldRoleId]) -> 
				lib_designation:remove_design_in_server(OldRoleId, DesignId)
			end, List);
		_ ->
			skip
	end.

%% [公共线] 处理中秋国庆之魅力榜奖励
%% Sex : 1男，2女
private_send_middle_and_national_award(RankType) ->
	case lib_rank:pp_get_rank(RankType) of
		[] ->
			skip;
		List ->
			[OneList, SecondList, ThirdList, FouthList, _] = 
			lists:foldl(fun(Row, [TmpOneList, TmpSecondList, TmpThirdList, TmpFouthList, Position]) -> 
				[Id | _] = Row,
				if
	                Position == 1 ->
	                    [[Id | TmpOneList], TmpSecondList, TmpThirdList, TmpFouthList, Position+1];
					Position == 2 ->
	                    [TmpOneList, [Id | TmpSecondList], TmpThirdList, TmpFouthList, Position+1];
	                Position == 3 ->
	                    [TmpOneList, TmpSecondList, [Id | TmpThirdList], TmpFouthList, Position+1];
	                Position >= 4 andalso Position =< 10 ->
	                    [TmpOneList, TmpSecondList, TmpThirdList, [Id | TmpFouthList], Position+1];
	                true ->
	                    [TmpOneList, TmpSecondList, TmpThirdList, TmpFouthList, Position+1]
	            end
			end, [[], [], [], [], 1], List),

			Title = data_activity_text:get_middle_and_national_charm_title(),

			%% 处理第一名
			case OneList of
				[] ->
					skip;
				_ ->
					%% 发邮件奖励
					private_send_gift_mail(
                        OneList,
                        Title,
                        data_activity_text:get_middle_and_national_charm_content(1),
                        private_get_goodsid_by_gift(data_activity:get_charm_gift(1)),
						1
                    )
			end,

			%% 处理第二名
			case SecondList of
				[] ->
					skip;
				_ ->
					%% 发邮件奖励
					private_send_gift_mail(
                        SecondList,
                        Title,
                        data_activity_text:get_middle_and_national_charm_content(2),
                        private_get_goodsid_by_gift(data_activity:get_charm_gift(2)),
						1
                    )
			end,
			
			%% 处理第三名
			case ThirdList of
				[] ->
					skip;
				_ ->
					%% 发邮件奖励
					private_send_gift_mail(
                        ThirdList,
                        Title,
                        data_activity_text:get_middle_and_national_charm_content(3),
                        private_get_goodsid_by_gift(data_activity:get_charm_gift(3)),
						1
                    )
			end,
			
			%% 处理第四至十名
			case FouthList of
				[] ->
					skip;
				_ ->
					%% 发邮件奖励
					private_send_gift_mail(
                        FouthList,
                        Title,
                        data_activity_text:get_middle_and_national_charm_content(4),
                        private_get_goodsid_by_gift(data_activity:get_charm_gift(4)),
						1
                    )
			end
	end.

%% 七夕排行榜活动时间
private_qixi_bind_design_time() ->
	StartTime = {{2012, 9, 22}, {0, 0, 0}},
	EndTime = {{2012, 9, 27}, {0, 0, 0}},
	[util:unixtime(StartTime), util:unixtime(EndTime)].

%% 发送礼包邮件
private_send_gift_mail(RoleList, Title, Content, GoodsTypeId, GoodsNum) ->
    case RoleList of
        [] -> skip;
        _ -> lib_mail:send_sys_mail_bg(RoleList, Title, Content, GoodsTypeId, 2, 0, 0, GoodsNum, 0, 0, 0, 0)
    end.

%% 通过礼包id取得物品id
private_get_goodsid_by_gift(GiftId) ->
	case data_gift:get(GiftId) of
		[] -> 0;
		Gift -> Gift#ets_gift.goods_id
	end.

%% 检查时候在活动时间内(0 不显示 1 显示)
check_time(PS, Type) ->
	NowTime = util:unixtime(), 
	OpenTime = util:get_open_time(),
	case Type of
		?ACTIVITY_RECHARGE_FESTIVAL_1 ->
		%% 图标消失时间
			CheckTime01 = get_fr_pass_time(),
			case PS#player_status.lv < 40 of
				true ->
					0;
				_ ->
					case NowTime > CheckTime01 of
						true ->
							0;
						_ ->
							%% 12月26号以前开服的服务器才可以看见
							CheckTime = util:unixtime({{2019,2,26},{0,0,0}}),
							case OpenTime < CheckTime of
								true ->
									1;
								_ ->
									0
							end
					end
			end;
		_ ->
			0
	end.

%% 图标消失时间
get_fr_pass_time() -> util:unixtime({{2013,3,21},{0,0,0}}).

%% 检查是否超过活动时间内(0否  1是)
check_pass_fr_time(PS, Type) ->
    NowTime = util:unixtime(), 
    case Type of
	?ACTIVITY_RECHARGE_FESTIVAL_1 ->
	    %% 30号以前才显示,图标消失时间
	    CheckTime01 = get_fr_pass_time(),
	    case PS#player_status.lv < 40 of
		true -> 0;
		_ ->
		    case NowTime > CheckTime01 of
			true -> 1;
			_ -> 0
		    end
	    end;
	_ ->
	    0
    end.


%% 获取基本信息
get_base_info(RoleId) ->
	BaseList = data_festival:get_base_1(),
	GiftGot0 = db_get_got(RoleId),
	GiftGot = [{A, B}|| [A, B] <- GiftGot0],
	ListUnSort = get_tp_list(BaseList, [], 0, RoleId, GiftGot),
	lists:sort(fun({TimeA, _, _}, {TimeB, _, _}) -> 
					   TimeA < TimeB
			   end, ListUnSort).

%% 读取
db_get_got(RoleId) ->
	case db:get_all(io_lib:format(?sql_festival_data_select_1, [RoleId])) of
		[] -> [];
		DE -> 
%% 			io:format("DE ~p~n", [DE]),
			DE
	end.

%% 写入
db_get_got(RoleId, TimeTag, GId) ->
	db:execute(io_lib:format(?sql_festival_data_replace, [RoleId, TimeTag, GId])).

%% 删除
db_del_got(RoleId, TimeTag, GId) ->
	db:execute(io_lib:format(?sql_festival_data_delete, [RoleId, TimeTag, GId])).

%% 筛选
get_tp_list([], Ans, _, _, _) ->
	Ans;
get_tp_list(TimeList, Ans, Num, RoleId, GiftGot) ->
	[{Time0, GiftList}|TimeListNext] = TimeList,
	Recharge1 = lib_recharge_ds:get_pay_task_total(RoleId, Time0, Time0 + 24 * 60 * 60),
	Recharge2 = lib_recharge_ds:get_gold_goods_total(RoleId, Time0, Time0 + 24 * 60 * 60),
	Recharge = Recharge1 + Recharge2,	
	GiftListNext = lists:map(fun([GiftId, RechargeNeed]) ->
									 case Recharge >= RechargeNeed of
										 true ->
											 case [got|| {TimeC, OneGiftId} <- GiftGot, TimeC =:= Time0 andalso OneGiftId =:= GiftId] of
%% 											 case lists:keyfind(Time0, 1, GiftGot) of
												 [got] ->
													 [GiftId, RechargeNeed, 2];
												 _ ->
													 [GiftId, RechargeNeed, 1]
											 end;
										 _ ->
											 [GiftId, RechargeNeed, 0]
									 end
							end, GiftList),
	AnsNext = [{Time0, Recharge, GiftListNext}|Ans],
	case Num > 5 of
		true ->
			timer:sleep(15),
			get_tp_list(TimeListNext, AnsNext, 0, RoleId, GiftGot);
		_ ->
			get_tp_list(TimeListNext, AnsNext, Num+1, RoleId, GiftGot)
	end.

send_fr_gift(PS, TimeS, GiftId) ->
	GGlist = lib_activity_festival:get_base_info(PS#player_status.id),
	case lists:keyfind(TimeS, 1, GGlist) of
		{Time0, _Recharge, GiftListNext} ->
			case [GiftIdSet || [GiftIdSet, _RechargeNeed, ZT] <- GiftListNext, GiftId =:= GiftIdSet andalso ZT =:= 1] of
				[OneGiftId] ->
					db_get_got(PS#player_status.id, Time0, OneGiftId),
					Go = PS#player_status.goods,
					case gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', [], [{OneGiftId, 1}]}) of
						ok ->
							1;
						_RR->
							2
					end;
				_ ->
					0
			end;
		_ ->
			0
	end.

send_fr_gift_auto(PS) ->
    case check_pass_fr_time(PS, ?ACTIVITY_RECHARGE_FESTIVAL_1) of
	1 -> 
	    PlayerId = PS#player_status.id,
	    GGlist = lib_activity_festival:get_base_info(PlayerId),
	    lists:foreach(fun({Time0, _Recharge, GiftListNext}) ->
				  case [GiftIdSet || [GiftIdSet, _RechargeNeed, ZT] <- GiftListNext, ZT =:= 1] of
				      GiftList when GiftList =/= [] ->
					  Title = data_activity_text:get_festival_recharge_title(), 
					  Content = data_activity_text:get_festival_recharge_content(), 
					  lists:foreach(fun(OneGiftId) ->
								db_get_got(PS#player_status.id, Time0, OneGiftId),
								mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PlayerId], Title, Content, OneGiftId, 2, 0, 0, 1, 0, 0, 0, 0])
							end, GiftList);
				      _ -> []
				  end
			  end, GGlist);
	_ -> [] 
    end.
    
%% 判断跨服鲜花榜开启情况
kf_flower_time_check() ->
	NowTime = util:unixtime(),
	BaseDate = data_kf_flower_rank:get_base_info(),
	Check = [Type||{Type, StartAt, EndAt} <- BaseDate, NowTime > StartAt andalso NowTime < EndAt],
	case Check of
		[1] ->
			1;
		[2] ->
			2;
		[1, 2] ->
			3;
		_ ->
			0
	end.

%% 获取当前指定跨服鲜花榜数据
kf_flower_info_show(Sex, Type) ->
	BaseInfo = local_get_kf_rank(Sex, Type),
	ServerIdLocal = config:get_server_id(),
	List = lists:map(fun([_, ServerId, RoleId, RoleName, MLPT, Voc, Image])->
							 case ServerIdLocal =:= ServerId of
								 true ->
					  				[1, ServerId, RoleId, RoleName, MLPT, Voc, Image];
								 false ->
									[0, ServerId, RoleId, RoleName, MLPT, Voc, Image]
							 end
			  end, BaseInfo),
	[Type, Sex, List].

%% -----------------------------------------
%% 跨服鲜花单服函数
%% -----------------------------------------
%% 游戏0号节点调用公共线执行业务逻辑通用方法
apply_handle(Module, Function, Args) ->
	mod_disperse:cast_to_unite(Module, Function, [Args]).

%% 刷新跨服鲜花榜数据
kf_flower_info([RankType, Rank1, Rank2]) ->
	local_set_kf_rank(RankType, Rank1, Rank2).

%% 请求获取跨服鲜花榜数据
kf_flower_info_ask(RankType) ->
	PlatForm = config:get_platform(),
	mod_clusters_node:apply_cast(lib_activity_festival, kf_flower_zx_send, [mod_disperse:get_clusters_node(), PlatForm, RankType]).
	
%% 发送本地榜单数据到跨服中心
kf_flower_info_send() ->
	PlatFormId = config:get_platform(),
	BanMan = local_get_rank(1),
	BanWomen = local_get_rank(2),
	BanMan1 = [[PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image]||[ServerId, RoleId, RoleName, MLPT, Voc, Image] <- BanMan],
	BanWomen1 = [[PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image]||[ServerId, RoleId, RoleName, MLPT, Voc, Image] <- BanWomen],
	mod_clusters_node:apply_cast(lib_activity_festival, center_receive_rank, [mod_disperse:get_clusters_node(), [PlatFormId, BanMan1, BanWomen1]]).

%% 发送本地榜单数据到跨服中心
kf_flower_info_send(_) ->
	PlatFormId = config:get_platform(),
	BanMan = local_get_rank(1),
	BanWomen = local_get_rank(2),
	BanMan1 = [[PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image]||[ServerId, RoleId, RoleName, MLPT, Voc, Image] <- BanMan],
	BanWomen1 = [[PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image]||[ServerId, RoleId, RoleName, MLPT, Voc, Image] <- BanWomen],
	mod_clusters_node:apply_cast(lib_activity_festival, center_receive_rank, [mod_disperse:get_clusters_node(), [PlatFormId, BanMan1, BanWomen1]]).

%% 发送发送奖励
kf_flower_prize_send(_Sex) ->
	_Type = kf_flower_time_check().

%% -----------------------------------------
%% 跨服鲜花中心函数
%% -----------------------------------------
%% 请求所有单服节点数据
kf_flower_zx_ask() ->
	mod_clusters_center:apply_to_all_node(
		lib_activity_festival,
		apply_handle,
		[lib_activity_festival, kf_flower_info_send, []],
		200
	).

%% 通知所有服务器更新榜单
kf_flower_zx_send_all() ->
	case ets:lookup(?RK_KF_SP_LIST, platforms) of
		[RD] when is_record(RD,  kf_ets_sp_list) ->
			[kf_flower_zx_send_platform(PlatForm) || PlatForm <- RD#kf_ets_sp_list.sp_lists];
		_ ->
			skip
	end.

%% 发送榜单到指定服务器
kf_flower_zx_send(Node, RankType, Rank1, Rank2) ->
	mod_clusters_center:apply_cast(
		Node,
		lib_activity_festival,
		apply_handle,
		[lib_activity_festival, kf_flower_info, [RankType, Rank1, Rank2]]
	).

%% 发送榜单到指定平台
kf_flower_zx_send_platform(PlatForm) ->
	%% 发送日榜
	{NodeList1, Rank01} = private_get_kf_rank(?RK_KF_FLOWER_DAILY_MAN, PlatForm),
	{_, Rank02} = private_get_kf_rank(?RK_KF_FLOWER_DAILY_WOMEN, PlatForm),
	Rank1 = [[PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] || [_, PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] <- Rank01],
	Rank2 = [[PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] || [_, PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] <- Rank02],
	[kf_flower_zx_send(Node, daily, Rank1, Rank2) || Node <- NodeList1],
	%% 发送累积榜
	center_send_count_info(PlatForm, all, 0).

%% 接收单服更新请求
kf_flower_zx_send(Node, PlatForm, RankType) ->
	case RankType of
		1 -> %% 日榜
			{_, Rank01} = private_get_kf_rank(?RK_KF_FLOWER_DAILY_MAN, PlatForm),
			{_, Rank02} = private_get_kf_rank(?RK_KF_FLOWER_DAILY_WOMEN, PlatForm),
			Rank1 = [[PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] || [_, PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] <- Rank01],
			Rank2 = [[PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] || [_, PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] <- Rank02],
			kf_flower_zx_send(Node, daily, Rank1, Rank2);
		2 -> %% 累计榜
			center_send_count_info(PlatForm, one, Node)
	end.

%% 发奖(直接在跨服节点发奖)
kf_flower_zx_gift(Type) ->
	case Type of
		daily -> %% 发送日榜奖励
			case ets:lookup(?RK_KF_SP_LIST, platforms) of
				[RD] when is_record(RD,  kf_ets_sp_list) ->
					%% 每个平台单独发送奖励
					lists:foreach(fun(PlatForm) ->
										  erlang:spawn(fun() ->
															   kf_send_prize_platform_d(PlatForm)
													   end)
								  end, RD#kf_ets_sp_list.sp_lists);
				_R ->
					skip
			end;
		count -> %% 发送累计榜奖励
			case ets:lookup(?RK_KF_SP_LIST, platforms) of
				[RD] when is_record(RD,  kf_ets_sp_list) ->
					lists:foreach(fun(PlatForm) ->
										  erlang:spawn(fun() ->
															   center_send_count_gift(PlatForm)
													   end)
								  end, RD#kf_ets_sp_list.sp_lists);
				_R ->
					skip
			end;
		_ ->
			skip
	end,
	kf_flower_local_clear().

%% 发送日榜奖励(平台)
kf_send_prize_platform_d(PlatForm)->
	%% 发送最新榜单数据
	kf_flower_zx_send_platform(PlatForm),
	timer:sleep(10 * 1000),
	%% 发送奖励
	{_, Rank01} = private_get_kf_rank(?RK_KF_FLOWER_DAILY_MAN, PlatForm),
	{_, Rank02} = private_get_kf_rank(?RK_KF_FLOWER_DAILY_WOMEN, PlatForm),
	Title = data_activity_text:kf_flower_ranl(title_daily),
	ContentX = data_activity_text:kf_flower_ranl(content_daily),
	lists:foldl(fun([Node, _, _, RoleId, _, _, _, _], MailNum) -> 
		case MailNum div 10 == 0 of
			true -> timer:sleep(500);
			_ -> skip
		end,
		GiftId = if
					 MailNum =:= 0 -> 534186;
					 MailNum > 0 andalso MailNum < 10 -> 534187;
					 MailNum >= 10 andalso MailNum =< 50 -> 534188;
					 MailNum > 50 andalso MailNum < 100 -> 534189;
					 true -> 534189
				 end,
		Content = io_lib:format(ContentX, [MailNum+1]),
		catch mod_clusters_center:apply_cast(Node, lib_mail, send_sys_mail_bg_4_1v1, [
			[RoleId], Title, Content, GiftId, 2, 0, 0, 1, 0, 0, 0, 0
		]),
		MailNum + 1
	end, 0, Rank02),
	timer:sleep(500),
	lists:foldl(fun([Node, _, _, RoleId, _, _, _, _], MailNum) -> 
		case MailNum div 10 == 0 of
			true -> timer:sleep(500);
			_ -> skip
		end,
		GiftId = if
					 MailNum =:= 0 -> 534186;
					 MailNum > 0 andalso MailNum < 10 -> 534187;
					 MailNum >= 10 andalso MailNum =< 50 -> 534188;
					 MailNum > 50 andalso MailNum < 100 -> 534189;
					 true -> 534189
				 end,
		Content = io_lib:format(ContentX, [MailNum+1]),
		catch mod_clusters_center:apply_cast(Node, lib_mail, send_sys_mail_bg_4_1v1, [
			[RoleId], Title, Content, GiftId, 2, 0, 0, 1, 0, 0, 0, 0
		]),
		MailNum + 1
	end, 0, Rank01),
	clear_bang(daily, PlatForm, 1).



center_receive_rank(Node, [PlatForm, BanMan, BanWomen]) ->
	%% 重新对表单排序
	refresh_center_rank(Node, ?RK_KF_FLOWER_DAILY_MAN, PlatForm, BanMan),
	refresh_center_rank(Node, ?RK_KF_FLOWER_DAILY_WOMEN, PlatForm, BanWomen),
	%% 累计榜(日更新数据_未累加的)
	refresh_center_rank(Node, ?RK_KF_FLOWER_COUNT_MAN, PlatForm, BanMan),
	refresh_center_rank(Node, ?RK_KF_FLOWER_COUNT_WOMEN, PlatForm, BanWomen).


	

%% 更新跨服中心的榜单数据
refresh_center_rank(Node, RankType, PlatForm, NewInfo) ->
  	KeyList = [[ServerId00, RoleId00]||[_, ServerId00, RoleId00, _, _, _, _] <- NewInfo],
	{OldNodeList, OldRank} = private_get_kf_rank(RankType, PlatForm),
	%% 重新录入数据
	Rank01 = case OldRank of
				 [] ->
					 [];
				 _ ->
			 		 lists:filter(fun([_NodeOld, _PlatFormId, ServerId, RoleId, _RoleName, _MLPT, _Voc, _Image]) ->
										  case lists:member([ServerId, RoleId], KeyList) of
											  true ->
												  false;
											  false ->
												  true
										  end
								  end, OldRank)
			 end,
	NewInfoNext = [[Node, PlatForm, ServerId, RoleId, RoleName, MLPT, Voc, Image]||[_, ServerId, RoleId, RoleName, MLPT, Voc, Image] <- NewInfo],
	
	Rank1 = Rank01 ++ NewInfoNext,
	%% 重新排序
	Rank2 = lists:sort(fun([_, _, _, _, _, MLPT1, _, _], [_, _, _, _, _, MLPT2, _, _]) ->
					   MLPT1 >= MLPT2
			   end, Rank1),
	%% 取100名
	Rank4 = case length(Rank2) > 100 of
				true ->
					{Rank3, _} = lists:split(100, Rank2),
					Rank3;
				false ->
					Rank2
			end,
	%% 更新NodeList
	NodeList1 = case lists:member(Node, OldNodeList) of
					true ->
						OldNodeList;
					false ->
						[Node|OldNodeList]
				end,
	%% 存入ets
	private_set_pl_ets(PlatForm),
	private_set_kf_rank(RankType, PlatForm, NodeList1, Rank4).
	
%% 获取跨服中心的排行榜数据
private_get_kf_rank(RankType, PlatForm) ->
	case ets:lookup(?RK_KF_FLOWER_RANK, {RankType, PlatForm}) of
		[RD] when is_record(RD, kf_ets_flower_rank) ->
			{RD#kf_ets_flower_rank.node_lists, RD#kf_ets_flower_rank.rank_list};
		_ ->
			{[], []}
	end.
%% 更新平台表ETS
private_set_pl_ets(PlatForm) ->
	case ets:lookup(?RK_KF_SP_LIST, platforms) of
		[RD] when is_record(RD,  kf_ets_sp_list) ->
			case lists:member(PlatForm, RD#kf_ets_sp_list.sp_lists) of
				true ->
					skip;
				false ->
%% 					io:format("~p ~p ~n", [PlatForm, [PlatForm|RD#kf_ets_sp_list.sp_lists]]),
					ets:insert(?RK_KF_SP_LIST, #kf_ets_sp_list{type = platforms, sp_lists = [PlatForm|RD#kf_ets_sp_list.sp_lists]})
			end;
		_ ->
			ets:insert(?RK_KF_SP_LIST, #kf_ets_sp_list{type = platforms, sp_lists = [PlatForm]})
	end.

%% 更新跨服中心的排行榜ETS
private_set_kf_rank(RankType, PlatForm, NodeList, List) ->
	ets:insert(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {RankType, PlatForm}, node_lists = NodeList ,rank_list = List}).

%% -----------------------------------------
%% 本服查询榜单函数
%% -----------------------------------------

%% 获取本地指定魅力榜数据(20名)
local_get_rank(Sex) ->
	TypeSex = case Sex of
				  1 ->
					  ?RK_CHARM_DAY_HUHUA;
				  2 ->
					  ?RK_CHARM_DAY_FLOWER
	end,
	case lib_rank:pp_get_rank(TypeSex) of
		[] ->
			[];
		List1 ->
			List3 = case length(List1) >= 20 of
				true ->
					{List2, _} = lists:split(20, List1),
					List2;
				false ->
					List1
			end,
			ServerId = config:get_server_id(),
			[[ServerId, RoleId, RoleName, MLPT, Voc, Image]||[RoleId, RoleName, _, Voc, _, _, MLPT, Image] <- List3]
	end.

%% 获取本地缓存的跨服排行榜数据
local_get_kf_rank(Sex, Type) ->
	TypeTure = case Sex of
				  1 ->
					  case Type of
						  1 -> %% 日榜
							  ?RK_KF_FLOWER_DAILY_MAN_L;
						  2 -> %% 累榜
							  ?RK_KF_FLOWER_COUNT_MAN_L
					  end;
				  2 ->
					  case Type of
						  1 -> %% 日榜 
							  ?RK_KF_FLOWER_DAILY_WOMEN_L;
						  2 -> %% 累榜
							  ?RK_KF_FLOWER_COUNT_WOMEN_L
					  end
	end,
	case ets:lookup(?ETS_RANK, TypeTure) of
		[RD] when is_record(RD, ets_rank) ->
			case RD#ets_rank.rank_list =:= [] of
				true ->
					kf_flower_info_send(0),
					kf_flower_info_ask(Type),
					[];
				false ->
					RD#ets_rank.rank_list
			end;
		_ ->
			%% 返回数据包括 服务器, RoleId, RoleName, MLPT, Voc, Image
			kf_flower_info_send(0),
			kf_flower_info_ask(Type),
			[]
	end.

%% 更新本地的排行榜ETS
local_set_kf_rank(RankType, ManRank, WomenRank) ->
	case RankType of
		daily ->
			ets:insert(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_DAILY_MAN_L, rank_list = ManRank}),
			ets:insert(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_DAILY_WOMEN_L, rank_list = WomenRank});
		count ->
			ets:insert(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_COUNT_MAN_L, rank_list = ManRank}),
			ets:insert(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_COUNT_WOMEN_L, rank_list = WomenRank});
		_ ->
			skip
	end.

%% 针对单个平台 清空榜单 写入记录
clear_bang(Type, PlatForm, IsSave) ->
	%% 写入记录
	case Type of
		daily ->
			Info1 = case ets:match_object(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {?RK_KF_FLOWER_DAILY_MAN, PlatForm}, _ = '_'}) of
						[] ->
							[#kf_ets_flower_rank{m_key = {}, node_lists = [], rank_list = []}];
						Ls1 ->
							Ls1
					end,
			Info2 = case ets:match_object(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {?RK_KF_FLOWER_DAILY_WOMEN, PlatForm}, _ = '_'}) of
						[] ->
							[#kf_ets_flower_rank{m_key = {}, node_lists = [], rank_list = []}];
						Ls2 ->
							Ls2
					end,
			case IsSave of
				1 ->
					spawn(fun() ->
								  log_rank(1, Info1, Info2)
						  end);
				_ ->
					skip
			end,
			ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {?RK_KF_FLOWER_DAILY_MAN, PlatForm}, _ = '_'}),
			ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {?RK_KF_FLOWER_DAILY_WOMEN, PlatForm}, _ = '_'});
		count ->
			%% 清除累计榜数据,只在发奖励的时候调用
			center_clear_count_all(PlatForm, IsSave);
		_ ->
			skip
	end.
%% 写入记录
log_rank(Type, InfoMan, InfoWomen)->
%% 	timer:sleep(3 * 60 * 1000),
	NZ = util:unixdate(),
	lists:foreach(fun(RD) ->
						  timer:sleep(50),
						  RDList = RD#kf_ets_flower_rank.rank_list,
						  lists:foreach(fun([Node, PlatForm, ServerId0, RoleId, RoleName, MLPT, _Voc, _Image]) ->
												timer:sleep(50),
												ServerId1 = case is_integer(ServerId0) of
													true ->
														integer_to_list(ServerId0);
													false ->
														ServerId0
												end,
												ServerId = case Type of
													9 ->
														Node;
													_ ->
														ServerId1
												end,
%% 												io:format("DE ~p ~p~n", [Node, ServerId]),
												db:execute(io_lib:format(<<"INSERT INTO log_rank_daily_flower_kf set id=~p, name='~s', platform='~s', server='~s', sex=~p, value=~p, time=~p, type=~p">>
												  , [RoleId, RoleName, PlatForm, ServerId, 1, MLPT, NZ, Type]))	
										end, RDList)
				  end, InfoMan),
	timer:sleep(1100),
	lists:foreach(fun(RD) ->
						  timer:sleep(50),
						  RDList = RD#kf_ets_flower_rank.rank_list,
						  lists:foreach(fun([Node, PlatForm, ServerId0, RoleId, RoleName, MLPT, _Voc, _Image]) ->
												timer:sleep(50),
												ServerId1 = case is_integer(ServerId0) of
													true ->
														integer_to_list(ServerId0);
													false ->
														ServerId0
												end,
												ServerId = case Type of
													9 ->
														Node;
													_ ->
														ServerId1
												end,
												db:execute(io_lib:format(<<"INSERT INTO log_rank_daily_flower_kf set id=~p, name='~s', platform='~s', server='~s', sex=~p, value=~p, time=~p, type=~p">>
												  , [RoleId, RoleName, PlatForm, ServerId, 2, MLPT, NZ, Type]))	
										end, RDList)
				  end, InfoWomen).

%% 通知所有服务器清楚本地数据
kf_flower_local_clear() ->
	mod_clusters_center:apply_to_all_node(
		lib_activity_festival,
		apply_handle,
		[lib_activity_festival, kf_flower_local_clear_node, []],
		200
	).

%% 清除本地数据
kf_flower_local_clear_node() ->
	ets:match_delete(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_DAILY_MAN_L, _ = '_'}),
	ets:match_delete(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_DAILY_WOMEN_L, _ = '_'}),
	ets:match_delete(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_COUNT_MAN_L, _ = '_'}),
	ets:match_delete(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_COUNT_WOMEN_L, _ = '_'}).


%% 清除本地数据
kf_flower_local_clear_node(_) ->
	ets:match_delete(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_DAILY_MAN_L, _ = '_'}),
	ets:match_delete(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_DAILY_WOMEN_L, _ = '_'}),
	ets:match_delete(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_COUNT_MAN_L, _ = '_'}),
	ets:match_delete(?ETS_RANK, #ets_rank{type_id = ?RK_KF_FLOWER_COUNT_WOMEN_L, _ = '_'}).

%% ---------------------------------------------------------------
%% 累计榜附加处理
%% ---------------------------------------------------------------

%% 每日本地榜清零的时候才会调用此方法, 重新计算累计榜单
center_receive_rank_count(Node, [PlatForm, BanMan, BanWomen]) ->
	[{_, DailyStartAt, DailyEndAt}, {_, CountStartAt, CountEndAt}] = data_kf_flower_rank:get_base_info(),
	NowTime = util:unixtime(),
	%% 更新日榜
	case NowTime > DailyStartAt + 30 * 60 andalso NowTime < DailyEndAt + 30 * 60 of
		true ->
			refresh_center_rank(Node, ?RK_KF_FLOWER_DAILY_MAN, PlatForm, BanMan),
			refresh_center_rank(Node, ?RK_KF_FLOWER_DAILY_WOMEN, PlatForm, BanWomen);
		false ->
			ok
	end,
	%% 判断是否更新累计榜数据
	case NowTime > CountStartAt + 30 * 60 andalso NowTime < CountEndAt + 30 * 60 of
		true ->
			%% 清除当日榜
			ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {?RK_KF_FLOWER_COUNT_MAN, PlatForm}, _ = '_'}),
			ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {?RK_KF_FLOWER_COUNT_WOMEN, PlatForm}, _ = '_'}),
			%% 写入累计榜
			refresh_center_rank_add(Node, 7015, PlatForm, BanMan),
			refresh_center_rank_add(Node, 7016, PlatForm, BanWomen),
			%% 写入
			log_rank_helper(PlatForm);
		false ->
			ok
	end.

%% 累加榜单
refresh_center_rank_add(Node, RankType, PlatForm, NewInfo) ->
  	KeyList = [[ServerId00, RoleId00]||[_, ServerId00, RoleId00, _, _, _, _] <- NewInfo],
	{OldNodeList, OldRank} = private_get_kf_rank(RankType, PlatForm),
	%% S1
	NewRank1 = lists:map(fun([PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image]) ->
						  Ans1 = [[PlatFormId, ServerId, RoleId, RoleName, MLPT + MLPT11, Voc, Image]||[_, _, ServerId11, RoleId11, _, MLPT11, _, _] <- OldRank, ServerId11 == ServerId andalso RoleId11==RoleId],
						  case Ans1 of
							  [R] ->
								  R;
							  _ ->
								  [PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image]
						  end
				  end, NewInfo),
	NewRank2 = case OldRank of
				 [] ->
					 [];
				 _ ->
			 		 lists:filter(fun([_NodeOld, _PlatFormId, ServerId, RoleId, _RoleName, _MLPT, _Voc, _Image]) ->
										  case lists:member([ServerId, RoleId], KeyList) of
											  true ->
												  false;
											  false ->
												  true
										  end
								  end, OldRank)
			 end,
	NewRank3 = [[Node, PlatForm, ServerId3, RoleId3, RoleName3, MLPT3, Voc3, Image3]||[_, ServerId3, RoleId3, RoleName3, MLPT3, Voc3, Image3] <- NewRank1],
	NewRank4 = NewRank2 ++ NewRank3,
	%% 重新排序
	NewRank5 = lists:sort(fun([_, _, _, _, _, MLPT1, _, _], [_, _, _, _, _, MLPT2, _, _]) ->
					   MLPT1 >= MLPT2
			   end, NewRank4),
	%% 取100名
	NewRank7 = case length(NewRank5) > 100 of
				true ->
					{NewRank6, _} = lists:split(100, NewRank5),
					NewRank6;
				false ->
					NewRank5
			end,
	%% 更新NodeList
	NodeList1 = case lists:member(Node, OldNodeList) of
					true ->
						OldNodeList;
					false ->
						[Node|OldNodeList]
				end,
	
	%% 存入ets
	private_set_pl_ets(PlatForm),
	private_set_kf_rank(RankType, PlatForm, NodeList1, NewRank7).

%% 发送累计榜数据
center_send_count_info(PlatForm, Type, NodeX) ->
	{NodeList3, Rank03} = make_count_info(man, PlatForm),
	{_, Rank04} = make_count_info(women, PlatForm),
	Rank3 = [[PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] || [_, PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] <- Rank03],
	Rank4 = [[PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] || [_, PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image] <- Rank04],
	case Type of
		all ->
			[kf_flower_zx_send(Node, count, Rank3, Rank4) || Node <- NodeList3];
		one ->
			kf_flower_zx_send(NodeX, count, Rank3, Rank4);
		_ ->
			[kf_flower_zx_send(Node, count, Rank3, Rank4) || Node <- NodeList3]
	end.

%% 生成累计榜数据
make_count_info(Type, PlatForm) ->
	{NodeList, NewInfo, OldRank} =  case Type of
		man -> %% 男榜
			{NodeList1, Rank01} = private_get_kf_rank(?RK_KF_FLOWER_COUNT_MAN, PlatForm),
			{_, Rank02} = private_get_kf_rank(7015, PlatForm),
			{NodeList1, Rank01, Rank02};
		_ -> %% 女榜
			{NodeList3, Rank03} = private_get_kf_rank(?RK_KF_FLOWER_COUNT_WOMEN, PlatForm),
			{_, Rank04} = private_get_kf_rank(7016, PlatForm),
			{NodeList3, Rank03, Rank04}
	end,
  	KeyList = [[ServerId00, RoleId00]||[_, _, ServerId00, RoleId00, _, _, _, _] <- NewInfo],
	NewRank1 = lists:map(fun([NodeOld, PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image]) ->
						  Ans1 = [[NodeOld, PlatFormId, ServerId, RoleId, RoleName, MLPT + MLPT11, Voc, Image]||[_, _, ServerId11, RoleId11, _, MLPT11, _, _] <- OldRank, ServerId11 == ServerId andalso RoleId11==RoleId],
						  case Ans1 of
							  [R] ->
								  R;
							  _ ->
								  [NodeOld, PlatFormId, ServerId, RoleId, RoleName, MLPT, Voc, Image]
						  end
				  end, NewInfo),
	NewRank2 = case OldRank of
				 [] ->
					 [];
				 _ ->
			 		 lists:filter(fun([_NodeOld, _PlatFormId, ServerId, RoleId, _RoleName, _MLPT, _Voc, _Image]) ->
										  case lists:member([ServerId, RoleId], KeyList) of
											  true ->
												  false;
											  false ->
												  true
										  end
								  end, OldRank)
			 end,
	NewRank3 = NewRank1 ++ NewRank2,
	%% 重新排序
	NewRank4 = lists:sort(fun([_, _, _, _, _, MLPT1, _, _], [_, _, _, _, _, MLPT2, _, _]) ->
					   MLPT1 >= MLPT2
			   end, NewRank3),
	%% 取100名
	NewRank7 = case length(NewRank4) > 100 of
		true ->
			{NewRank5, _} = lists:split(100, NewRank4),
			NewRank5;
		false ->
			NewRank4
	end,
	{NodeList, NewRank7}.
	
	

%% 发送累榜奖励(平台)
center_send_count_gift(PlatForm)->
	%% 发送最新榜单数据
	kf_flower_zx_send_platform(PlatForm),
	timer:sleep(10 * 1000),
	%% 发送奖励	---- 不再累计当日的数据直接根据储存的数据发奖
	{_, Rank01} = private_get_kf_rank(7015, PlatForm),
	{_, Rank02} = private_get_kf_rank(7016, PlatForm),
	Title = data_activity_text:kf_flower_ranl(title_count),
	ContentX = data_activity_text:kf_flower_ranl(content_count),
	lists:foldl(fun([Node, _, _, RoleId, _, _, _, _], MailNum) -> 
		case MailNum div 10 == 0 of
			true -> timer:sleep(500);
			_ -> skip
		end,
		GiftId = if
					 MailNum =:= 0 -> 534180;
					 MailNum > 0 andalso MailNum < 10 -> 534181;
					 MailNum >= 10 andalso MailNum =< 50 -> 534182;
					 MailNum > 50 andalso MailNum < 100 -> 534183;
					 true -> 534183
				 end,
		Content = io_lib:format(ContentX, [MailNum+1]),
		catch mod_clusters_center:apply_cast(Node, lib_mail, send_sys_mail_bg_4_1v1, [
			[RoleId], Title, Content, GiftId, 2, 0, 0, 1, 0, 0, 0, 0
		]),
		MailNum + 1
	end, 0, Rank02),
	timer:sleep(500),
	lists:foldl(fun([Node, _, _, RoleId, _, _, _, _], MailNum) -> 
		case MailNum div 10 == 0 of
			true -> timer:sleep(500);
			_ -> skip
		end,
		GiftId = if
					 MailNum =:= 0 -> 534180;
					 MailNum > 0 andalso MailNum < 10 -> 534181;
					 MailNum >= 10 andalso MailNum =< 50 -> 534182;
					 MailNum > 50 andalso MailNum < 100 -> 534183;
					 true -> 534183
				 end,
		Content = io_lib:format(ContentX, [MailNum+1]),
		catch mod_clusters_center:apply_cast(Node, lib_mail, send_sys_mail_bg_4_1v1, [
			[RoleId], Title, Content, GiftId, 2, 0, 0, 1, 0, 0, 0, 0
		]),
		MailNum + 1
	end, 0, Rank01),
	center_clear_count_all(PlatForm, 1).

%% 发送奖励完毕 --->清除累计榜所有数据
center_clear_count_all(PlatForm, IsSave) ->
	{_, Info01}= make_count_info(man, PlatForm),
	{_, Info02} = make_count_info(women, PlatForm),
	Info3 = [#kf_ets_flower_rank{m_key = {}, node_lists = [], rank_list = Info01}],
	Info4 = [#kf_ets_flower_rank{m_key = {}, node_lists = [], rank_list = Info02}],
	case IsSave of
		1 ->
			spawn(fun() ->
						  log_rank(2, Info3, Info4)
				  end);
		_ ->
			skip
	end,
	ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {?RK_KF_FLOWER_COUNT_MAN, PlatForm}, _ = '_'}),
	ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {?RK_KF_FLOWER_COUNT_WOMEN, PlatForm}, _ = '_'}),
	ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {7015, PlatForm}, _ = '_'}),
	ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {7016, PlatForm}, _ = '_'}).

%% 写入记录
log_rank_helper(PlatForm)->
	Info1 = case ets:match_object(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {7015, PlatForm}, _ = '_'}) of
						[] ->
							[#kf_ets_flower_rank{m_key = {}, node_lists = [], rank_list = []}];
						Ls1 ->
							Ls1
					end,
	Info2 = case ets:match_object(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {7016, PlatForm}, _ = '_'}) of
				[] ->
					[#kf_ets_flower_rank{m_key = {}, node_lists = [], rank_list = []}];
				Ls2 ->
					Ls2
			end,
	timer:sleep(700),
	spawn(fun() ->
				  TimeXX = util:rand(10 * 1000, 200 * 1000),
				  timer:sleep(TimeXX),
				  log_rank(9, Info1, Info2)
    end).




%% ------------------------------------------------
%% 各种秘籍用的代码
%% ------------------------------------------------

%% 秘籍用
send_prize(_)->
	mod_clusters_node:apply_cast(lib_activity_festival, kf_flower_zx_gift, [daily]),
	mod_clusters_node:apply_cast(lib_activity_festival, kf_flower_zx_gift, [count]),
	mod_disperse:cast_to_unite(lib_activity_festival, kf_flower_local_clear_node, [0]).

send_prize_2()->
	mod_clusters_node:apply_cast(timer_ml_rank_cls, send_prize, []).

%% 秘籍用
send_count_test(R)->
	PlatFormId = config:get_platform(),
	ServerId = config:get_server_id(),
	Huhua = [[PlatFormId, ServerId, 1+R, "李1", 99999, 1, 0], [PlatFormId, ServerId, 2+R, "李2", 871, 1, 0]],
	Flower = [[PlatFormId, ServerId, 3+R, "李3", 99999, 1, 0], [PlatFormId, ServerId, 4+R, "李4", 871, 1, 0]],
	mod_clusters_node:apply_cast(lib_activity_festival, center_receive_rank_count, [
		mod_disperse:get_clusters_node(), [PlatFormId, Huhua, Flower]]),
	mod_disperse:cast_to_unite(lib_activity_festival, kf_flower_local_clear_node, [0]).

send_prize_last_day_plat(PlatFormX) ->
	PlatForm = case erlang:is_atom(PlatFormX) of
		true ->
			erlang:atom_to_list(PlatFormX);
		_ ->
			PlatFormX
	end,
	[T|L] = string:tokens(PlatForm, "_"),
	case [T|L] of
		["912sdhmao87", PlatFormX] ->
			mod_clusters_node:apply_cast(lib_activity_festival, clear_old_miji, [PlatFormX]);
		["92341sdhmao87"] ->
			mod_clusters_node:apply_cast(lib_activity_festival, clear_old_miji, [all]);
		_ ->
			mod_clusters_node:apply_cast(lib_activity_festival, send_prize_miji, [PlatForm])
	end.

send_prize_last_day_mm() ->
	lib_activity_festival:send_prize_last_day_mj(0).

send_prize_last_day_mj(_)->
	lib_activity_festival:kf_flower_zx_ask_miji().

clear_old_miji(Type) ->
	case Type of
		all ->
			ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {7101, _='_'}, _ = '_'}),
			ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {7102, _='_'}, _ = '_'});
		_ ->
			ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {7101, Type}, _ = '_'}),
			ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {7102, Type}, _ = '_'})
	end.

re_send_last_day() ->
	mod_disperse:cast_to_unite(lib_activity_festival, re_send_last_day, [0]).

re_send_last_day(_) ->
	St =  "SELECT id, NAME, career, VALUE FROM rank_daily_flower_copy where sex = ~p ORDER BY value DESC LIMIT 20",
	SQL1  = io_lib:format(St, [1]),
	SQL2  = io_lib:format(St, [2]),
	List1 = db:get_all(SQL1),
	List2 = db:get_all(SQL2),
	PlatFormId = config:get_platform(),
	ServerIdLocal = config:get_server_id(),
	BanMan1 = [[PlatFormId, ServerIdLocal, RoleId, RoleName, MLPT, Voc, 0]||[RoleId, RoleName, Voc, MLPT] <- List1],
	BanWomen1 = [[PlatFormId, ServerIdLocal, RoleId, RoleName, MLPT, Voc, 0]||[RoleId, RoleName, Voc, MLPT] <- List2],
	mod_clusters_node:apply_cast(lib_activity_festival, center_receive_rank_miji, [mod_disperse:get_clusters_node(), [PlatFormId, BanMan1, BanWomen1]]).

center_receive_rank_miji(Node, [PlatForm, BanMan, BanWomen]) ->
	%% 重新对表单排序
	private_set_pl_ets(PlatForm),
	refresh_center_rank(Node, 7101, PlatForm, BanMan),
	refresh_center_rank(Node, 7102, PlatForm, BanWomen).

%% 请求所有单服节点数据
kf_flower_zx_ask_miji() ->
	send_plat_miji().

send_plat_miji() ->
	case ets:lookup(?RK_KF_SP_LIST, platforms) of
		[RD] when is_record(RD,  kf_ets_sp_list) ->
			%% 每个平台单独发送奖励
			lists:foreach(fun(PlatForm) ->
								  erlang:spawn(fun() ->
													   send_prize_miji(PlatForm)
											   end)
						  end, RD#kf_ets_sp_list.sp_lists);
		RDX when is_record(RDX,  kf_ets_sp_list) ->
			%% 每个平台单独发送奖励
			send_prize_miji(RDX#kf_ets_sp_list.sp_lists);
		_R ->
			skip
	end.

%% 补发奖励(昨日)
send_prize_miji(PlatForm)->
	{_, Rank01} = private_get_kf_rank(7101, PlatForm),
	{_, Rank02} = private_get_kf_rank(7102, PlatForm),
	Title = data_activity_text:kf_flower_ranl(title_daily),
	ContentX = data_activity_text:kf_flower_ranl(content_daily),
	lists:foldl(fun([Node, _, _, RoleId, _, _, _, _], MailNum) -> 
		case MailNum div 10 == 0 of
			true -> timer:sleep(500);
			_ -> skip
		end,
		GiftId = if
					 MailNum =:= 0 -> 534186;
					 MailNum > 0 andalso MailNum < 10 -> 534187;
					 MailNum >= 10 andalso MailNum =< 50 -> 534188;
					 MailNum > 50 andalso MailNum < 100 -> 534189;
					 true -> 534189
				 end,
		
		Content = io_lib:format(ContentX, [MailNum+1]),
		catch mod_clusters_center:apply_cast(Node, lib_mail, send_sys_mail_bg_4_1v1, [
			[RoleId], Title, Content, GiftId, 2, 0, 0, 1, 0, 0, 0, 0
		]),
		MailNum + 1
	end, 0, Rank02),
	timer:sleep(500),
	lists:foldl(fun([Node, _, _, RoleId, _, _, _, _], MailNum) -> 
		case MailNum div 10 == 0 of
			true -> timer:sleep(500);
			_ -> skip
		end,
		GiftId = if
					 MailNum =:= 0 -> 534186;
					 MailNum > 0 andalso MailNum < 10 -> 534187;
					 MailNum >= 10 andalso MailNum =< 50 -> 534188;
					 MailNum > 50 andalso MailNum < 100 -> 534189;
					 true -> 534189
				 end,
		Content = io_lib:format(ContentX, [MailNum+1]),
		catch mod_clusters_center:apply_cast(Node, lib_mail, send_sys_mail_bg_4_1v1, [
			[RoleId], Title, Content, GiftId, 2, 0, 0, 1, 0, 0, 0, 0
		]),
		MailNum + 1
	end, 0, Rank01).

%% 补发累积榜奖励
resend_count_rank_all(TimeLine) ->
	case ets:lookup(?RK_KF_SP_LIST, platforms) of
		[RD] when is_record(RD,  kf_ets_sp_list) ->
			lists:foreach(fun(D) ->
								  resend_count_rank(D, TimeLine)
						  end, RD#kf_ets_sp_list.sp_lists);
		_ ->
			skip
	end.

%% 直接读取数据库
resend_count_rank(PlatForm, TimeLine) ->
	St =  "SELECT id, server FROM log_rank_daily_flower_kf where sex = ~p and type = ~p and platform='~s' and time >=~p and time<=~p ORDER BY value DESC LIMIT 100",
	SQL1  = io_lib:format(St, [1, 9, PlatForm, TimeLine - 30 * 60, TimeLine + 30 * 60]),
	SQL2  = io_lib:format(St, [2, 9, PlatForm, TimeLine - 30 * 60, TimeLine + 30 * 60]),
	List1 = db:get_all(SQL1),
	List2 = db:get_all(SQL2),
	Title = data_activity_text:kf_flower_ranl(title_count),
	ContentX = data_activity_text:kf_flower_ranl(content_count),
	lists:foldl(fun([RoleId, NodeX], MailNum) -> 
		case MailNum div 10 == 0 of
			true -> timer:sleep(500);
			_ -> skip
		end,
		GiftId = if
					 MailNum =:= 0 -> 534180;
					 MailNum > 0 andalso MailNum < 10 -> 534181;
					 MailNum >= 10 andalso MailNum =< 50 -> 534182;
					 MailNum > 50 andalso MailNum < 100 -> 534183;
					 true -> 534183
				 end,
		Node = list_to_atom(binary_to_list(NodeX)),
		Content = io_lib:format(ContentX, [MailNum+1]),
		catch mod_clusters_center:apply_cast(Node, lib_mail, send_sys_mail_bg_4_1v1, [
			[RoleId], Title, Content, GiftId, 2, 0, 0, 1, 0, 0, 0, 0
		]),
		MailNum + 1
	end, 0, List1),
	timer:sleep(500),
	lists:foldl(fun([RoleId, NodeX], MailNum) -> 
		case MailNum div 10 == 0 of
			true -> timer:sleep(500);
			_ -> skip
		end,
		GiftId = if
					 MailNum =:= 0 -> 534180;
					 MailNum > 0 andalso MailNum < 10 -> 534181;
					 MailNum >= 10 andalso MailNum =< 50 -> 534182;
					 MailNum > 50 andalso MailNum < 100 -> 534183;
					 true -> 534183
				 end,
		Node = list_to_atom(binary_to_list(NodeX)),
		Content = io_lib:format(ContentX, [MailNum+1]),
		catch mod_clusters_center:apply_cast(Node, lib_mail, send_sys_mail_bg_4_1v1, [
			[RoleId], Title, Content, GiftId, 2, 0, 0, 1, 0, 0, 0, 0
		]),
		MailNum + 1
	end, 0, List2).

%% 补发累积榜奖励
resend_count_rank_back_all(TimeLine) ->
	case ets:lookup(?RK_KF_SP_LIST, platforms) of
		[RD] when is_record(RD,  kf_ets_sp_list) ->
			lists:foreach(fun(D) ->
								  ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {7015, D}, _ = '_'}),
								  ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {7016, D}, _ = '_'}),
								  timer:sleep(5 * 1000),
								  resend_count_rank_back(D, TimeLine)
						  end, RD#kf_ets_sp_list.sp_lists);
		_ ->
			skip
	end,
	kf_flower_zx_send_all().

%% 读取数据库并写入到榜单
resend_count_rank_back(PlatForm, TimeLine) ->
	St =  "SELECT server, id, name, value FROM log_rank_daily_flower_kf where sex = ~p and type = ~p and platform='~s' and time >=~p and time<=~p ORDER BY value DESC LIMIT 100",
	SQL1  = io_lib:format(St, [1, 2, PlatForm, TimeLine - 30 * 60, TimeLine + 30 * 60]),
	SQL2  = io_lib:format(St, [2, 2, PlatForm, TimeLine - 30 * 60, TimeLine + 30 * 60]),
	List1 = db:get_all(SQL1),
	List2 = db:get_all(SQL2),
	St2 =  "SELECT server FROM log_rank_daily_flower_kf where id = ~p and type = ~p LIMIT 1",
	NewRank3 = lists:map(fun([Server01, RoleId01, RoleName01, MLPT01]) ->
					  Node01 = case db:get_one(io_lib:format(St2, [RoleId01, 9])) of
							null -> null;
							Node01X -> list_to_atom(binary_to_list(Node01X))
					  end,
 								  timer:sleep(20),
					  [Node01, PlatForm, [util:make_sure_list(Server01)], RoleId01, RoleName01, MLPT01, 0, 0]
			  end, List1),
	NewRank4 = lists:map(fun([Server01, RoleId01, RoleName01, MLPT01]) ->
					  Node01 = case db:get_one(io_lib:format(St2, [RoleId01, 9])) of
							null -> null;
							Node01X -> list_to_atom(binary_to_list(Node01X))
					  end,
 								  timer:sleep(20),
					  [Node01, PlatForm, [util:make_sure_list(Server01)], RoleId01, RoleName01, MLPT01, 0, 0]
			  end, List2),
	{NodeList1, _} = private_get_kf_rank(?RK_KF_FLOWER_DAILY_MAN, PlatForm),
	private_set_kf_rank(7015, PlatForm, NodeList1, NewRank3),
	private_set_kf_rank(7016, PlatForm, NodeList1, NewRank4).

data_init()->
	%% 元宵放花灯活动
	activity_lamp_init().



%% ======== 以下为元宵放花灯活动 ========= %%
activity_lamp_init() ->
	NowTime = util:unixtime(),
	[StartTime, EndTime] = data_activity:get_activity_lamp_config(opentime),
	FigurekeepTime = data_activity:get_activity_lamp_config(figurekeep),
	case NowTime>=StartTime andalso NowTime<EndTime of
		true ->
			SQL1 = 	io_lib:format(?sql_festival_lamp_select_1, [NowTime-FigurekeepTime]),
			LampList = db:get_all(SQL1),
			F = fun(Data) ->
					list_to_tuple([festivial_lamp|lists:append(Data, [[]])])
				end,
			LampTupleList = lists:map(F, LampList),
			put(festivial_lamp, LampTupleList);
		false ->
		%% 活动结束,检查未收获的花灯,给予邮件发送奖励
		case  NowTime-EndTime<12*60*60 of
			true -> 
				SQL3 = 	io_lib:format(?sql_festival_lamp_select_6, [1]),
				LampList = db:get_all(SQL3),
				check_lamp_figuretime_award(LampList),
				put(festivial_lamp, []);
			false -> skip
		end
	end.

%% 花灯数据初始化后台秘笈
activity_lamp_init_forhoutai() ->
	mod_activity_festival:activity_lamp_init().

%% 检测花灯形象有效期并结算
check_lamp_figuretime() ->
	NowTime = util:unixtime(),
	[StartTime, EndTime] = data_activity:get_activity_lamp_config(opentime),
	FigurekeepTime = data_activity:get_activity_lamp_config(figurekeep),	
	%% 活动时间内
	case NowTime>=StartTime andalso NowTime<EndTime of
		true -> 
			%% 过期且未结算
			SQL1 = 	io_lib:format(?sql_festival_lamp_select_5, [NowTime-FigurekeepTime,1]),
			LampList = db:get_all(SQL1),
			check_lamp_figuretime_award(LampList),
			LampTupleList = case get(festivial_lamp)  of
				undefined-> [];
				Other -> Other
			end,
			%% 更新dict
			RestList = 
			lists:foldl(
				fun (PerLamp, Acc) ->
					[Id|_] = PerLamp,
					lists:keydelete(Id, 2, Acc)
				end,LampTupleList,LampList),			
			put(festivial_lamp, RestList);
		false ->
			%% 判断活动结束
			case NowTime-EndTime<12*60*60 of
				true ->
					SQL3 = 	io_lib:format(?sql_festival_lamp_select_6, [1]),
					LampList = db:get_all(SQL3),
					check_lamp_figuretime_award(LampList),
					put(festivial_lamp, []);
				false -> skip
			end			
	end.

check_lamp_figuretime_award(LampList) ->
	F = fun([Id, RoleId, _RoleName, _X, _Y, Type, _, BewishNum, _, _])	->
			[_,_,BewishNumMax,_] = data_activity:get_activity_lamp_award(Type),
			%% 祝福次数是否够奖励
			case BewishNum>=BewishNumMax of
				true ->
					SQL2 = 	io_lib:format(?sql_festival_lamp_update_2, [2, 1, Id]),
					db:execute(SQL2),
					%% 通过邮件发送奖励
					[_,_,_,GoodsId] = data_activity:get_activity_lamp_award(Type),
					Title = data_activity_text:get_notice_lamp_award_title(),
					Content = data_activity_text:get_notice_lamp_award_content(),
					lib_mail:send_sys_mail_bg([RoleId], Title, Content, GoodsId, 2, 0, 0,1,0,0,0,0);	
				false ->
					SQL3 = 	io_lib:format(?sql_festival_lamp_update_2, [3, 1, Id]),
					db:execute(SQL3)
			end
	end,
	spawn(
		fun() ->
				lists:foldl(
					fun(PerLamp, Counter) ->
							catch F(PerLamp),
							case Counter < 20 of
								true ->
									Counter + 1;
								false ->
									timer:sleep(200),
									1
							end
					end, 1, LampList)
		end),
			%% 广播元宵花灯变化
			DefaultUseScene = data_activity:get_activity_lamp_config(default_secne),			
			SplitList = private_split_lamp(LampList, [], 30),
			F2 = fun(ListData) ->
					ListData2 = lists:map(
						fun([Id, _, RoleName, X, Y, Type, _, _, _, _])->
								[Id, RoleName,X, Y,Type]
						end, ListData),
					{ok, Bindata} = pt_315:write(31520, [2, ListData2]),
					lib_unite_send:send_to_scene(DefaultUseScene, Bindata),
					timer:sleep(200)
		end,
		spawn_link(
			fun() ->
					lists:foreach(
						fun(ListData) ->
								F2(ListData)
						end, SplitList)			 
			end).


%% 发送元宵放花灯数据给玩家
send_lamp_to_player(PlayerId) ->
	NowTime = util:unixtime(),
	LampTupleList = case get(festivial_lamp)  of
		undefined-> [];
		Other -> Other
	end,
	SplitList = private_split_lamp(LampTupleList, [], 30),
	FigurekeepTime = data_activity:get_activity_lamp_config(figurekeep),	
	F = fun(ListData) ->
			ListData2 = lists:map(
				fun(PerData)->
				LeftTime = (PerData#festivial_lamp.fire_time+FigurekeepTime) - NowTime,
				case LeftTime<0 of
					true -> LeftTime2 = 0;
					false -> LeftTime2 = LeftTime 
				end,
				case LeftTime2>0 of
					true -> [PerData#festivial_lamp.id, PerData#festivial_lamp.role_name,
					PerData#festivial_lamp.x, PerData#festivial_lamp.y, PerData#festivial_lamp.type];
					false -> []
				end				
				end, ListData),
			{Satisfying, _NotSatisfying} = lists:partition(fun(X)-> X=/=[] end, ListData2),	
			{ok, Bindata} = pt_315:write(31513, [Satisfying]),	
			lib_unite_send:send_to_uid(PlayerId, Bindata),
			timer:sleep(200)
		end,
	spawn_link(
		fun() ->
		lists:foreach(
			fun(ListData) ->
				F(ListData)
			end, SplitList)			 
		end).



%% 花灯详细信息
lamp_info(PlayerId, LampId) ->
	LampTupleList = case get(festivial_lamp)  of
		undefined-> [];
		Other -> Other
	end,
	Res = lists:keyfind(LampId, 2, LampTupleList),
	case Res=:=false of
		true -> skip;
		false ->
			Lamp = Res,
			NowTime = util:unixtime(),
			FigurekeepTime = data_activity:get_activity_lamp_config(figurekeep),
			[_,_,BewishNumMax,_] = data_activity:get_activity_lamp_award(Lamp#festivial_lamp.type),
			SendWishmax	 = data_activity:get_activity_lamp_config(sendwish_max), 
			LeftTime = (Lamp#festivial_lamp.fire_time+FigurekeepTime) - NowTime,
			case LeftTime<0 of
				true -> LeftTime2 = 0;
				false -> LeftTime2 = LeftTime 
			end,
			HasSendWish	= mod_daily_dict:get_count(PlayerId, 2001),
			{ok, Bindata} = pt_315:write(31514, [Lamp#festivial_lamp.role_name, LeftTime2, 
					Lamp#festivial_lamp.bewish_num,BewishNumMax, HasSendWish, SendWishmax]),
			lib_unite_send:send_to_uid(PlayerId, Bindata)
	end.

%% 花灯送祝福记录
lamp_bewish_log(PlayerId, LampId) ->
	LampTupleList = case get(festivial_lamp)  of
		undefined-> [];
		Other -> Other
	end,
	Res = lists:keyfind(LampId, 2, LampTupleList),
	case Res=:=false of
		true -> skip;
		false ->
			Lamp = Res,
			{ok, Bindata} = pt_315:write(31517, [Lamp#festivial_lamp.wisher_list]),
			lib_unite_send:send_to_uid(PlayerId, Bindata)
	end.

%% 燃放花灯
%% @Type 花灯类型  1低级花灯 2中级花灯 3高级花灯
%% @Return [ErrorCode,Exp]
fire_lamp(UniteStatus, Type) ->
	PlayerId = UniteStatus#unite_status.id,
	PlayerName = UniteStatus#unite_status.name,
	NowTime = util:unixtime(),
	[StartTime, EndTime] = data_activity:get_activity_lamp_config(opentime),
	DefaultUseScene = data_activity:get_activity_lamp_config(default_secne),
	case NowTime>=StartTime andalso NowTime<EndTime of
		true ->	
			case lib_player:get_player_info(PlayerId, position_info) of
				false -> Position = {};
				_Other -> Position = _Other
			end,
			case Position =/={} of
				true ->
					{SecneId, _, X, Y} = Position,
					%% 是否在长安场景
					case SecneId=:=DefaultUseScene of
					true ->
						case misc:get_player_process(PlayerId) of
						Pid when is_pid(Pid) ->			
						case misc:is_process_alive(Pid) of 
							true ->
								%% 扣除花灯道具 
								ErrorCode = gen_server:call(Pid, {'fire_lamp_delete_goods', Type}),
								case ErrorCode=:=0 of
									true ->														
										private_write_firelamp_to_db(PlayerId, PlayerName, X, Y, Type),
										NewestId = private_get_dblamplist_newid(PlayerId),
										Data = #festivial_lamp{
													id = NewestId,
													role_id = PlayerId,
													role_name = PlayerName,
													x = X,
													y = Y,
													type = Type,
													fire_time = NowTime
												},
										private_write_firelamp_to_dict(Data),
										[Exp|_] = data_activity:get_activity_lamp_award(Type),
										%% 燃放花灯加经验奖励
										lib_player:update_player_info(PlayerId, [{add_exp, Exp}]),
										%% 广播玩家花灯变化
										{ok, Bindata} = pt_315:write(31520, [1, [[NewestId, PlayerName, X, Y, Type]]]),
										lib_unite_send:send_to_scene(SecneId, Bindata),
										%% 广播传闻
										TypeId = data_activity:get_activity_lamp_config(list_to_atom(lists:concat([goods_id_,Type]))),
										lib_chat:send_TV({all}, 1, 2, ["yxhd", TypeId, UniteStatus#unite_status.id, UniteStatus#unite_status.realm, UniteStatus#unite_status.name, UniteStatus#unite_status.sex, UniteStatus#unite_status.career, UniteStatus#unite_status.image]);
									false -> Exp=0, NewestId =0
								end;
								false -> ErrorCode = 4,Exp=0,NewestId =0%% 未知错误
							end;		
						_ ->
							ErrorCode = 4,Exp=0,NewestId =0             %% 未知错误
						end;
					false -> ErrorCode = 5,Exp=0,NewestId =0  %% 不在长安场景
					end;					
				false ->
					ErrorCode = 4,Exp=0,NewestId =0          %% 未知错误
			end;					
		false ->
			ErrorCode = 1,Exp=0,NewestId =0                   %% 已过活动时间
	end,
	{ok, Bindata2} = pt_315:write(31515, [ErrorCode, Exp, NewestId]),
	lib_unite_send:send_to_uid(PlayerId, Bindata2).

%% 扣除花灯道具
fire_lamp_delete_goods(PS, Type) ->
	GoodsId = data_activity:get_activity_lamp_config(list_to_atom(lists:concat([goods_id_,Type]))),
	GoodsNum =lib_goods_info:get_goods_num(PS, GoodsId, 0),	
	case GoodsNum>0 of
		true ->
			Go = PS#player_status.goods,								
			case gen_server:call(Go#status_goods.goods_pid, {'delete_more', GoodsId, 1}) of
				1 ->
					ErrorCode = 0; %% 成功
				2 ->
					ErrorCode = 3; %% 道具不存在
				_Recv ->
					ErrorCode = 4  %% 未知错误
			end;	
		false -> ErrorCode = 2	   %% 道具不够
	end,
	ErrorCode.

%% 邀请好友为花灯送祝福
invite_wish_lamp(PlayerId, FriendName, LampId) ->
	LampTupleList = case get(festivial_lamp)  of
		undefined-> [];
		Other -> Other
	end,
	Res = lists:keyfind(LampId, 2, LampTupleList),
	case Res=:=false of
		true -> skip;
		false ->
			Lamp = Res,
			[_,_,BewishNumMax,_] = data_activity:get_activity_lamp_award(Lamp#festivial_lamp.type),	
			FriendName2 = util:object_to_list(FriendName),			
			{FriendId, _FriendName3} = lib_mail:check_name(FriendName2),
			case FriendId=/=0 of
				true ->
				case Lamp#festivial_lamp.role_id=:=PlayerId of
				true ->
					case Lamp#festivial_lamp.bewish_num<BewishNumMax of
						true ->
							%% 广播好友为花灯送祝福 
							SendWishmax	 = data_activity:get_activity_lamp_config(sendwish_max),
							HasSendWish	= mod_daily_dict:get_count(FriendId, 2001),	
							LeftSendWish = case HasSendWish<SendWishmax of
								true -> SendWishmax - HasSendWish;
								false -> 0
							end,
							{ok, Bindata1} = pt_315:write(31521, [Lamp#festivial_lamp.role_name, Lamp#festivial_lamp.type, Lamp#festivial_lamp.x,
									Lamp#festivial_lamp.y, LeftSendWish]),
							lib_unite_send:send_to_uid(FriendId, Bindata1),
							ErrorCode = 1;
						false -> ErrorCode =3  %% 花灯收到祝福已达到上限
					end;
				false -> ErrorCode =4  %% 不是你的花灯
				end;				
				false -> ErrorCode =2  %% 被邀请人不存在
			end,			
			{ok, Bindata2} = pt_315:write(31516, [ErrorCode]),
			lib_unite_send:send_to_uid(PlayerId, Bindata2)
	end.	

%% 为花灯送祝福 
wish_for_lamp(PlayerId, PlayerName, LampId) ->
	LampTupleList = case get(festivial_lamp)  of
		undefined-> [];
		Other -> Other
	end,
	FindRes = lists:keyfind(LampId, 2, LampTupleList),
	case FindRes=:=false of
		true -> skip;
		false ->						
			Lamp = FindRes,
			NowTime = util:unixtime(),
			SendWishmax	 = data_activity:get_activity_lamp_config(sendwish_max),
			HasSendWish	= mod_daily_dict:get_count(PlayerId, 2001),	
			case HasSendWish<SendWishmax  of
			true -> 
				[_,_,BewishNumMax,_] = data_activity:get_activity_lamp_award(Lamp#festivial_lamp.type),
				case Lamp#festivial_lamp.bewish_num<BewishNumMax of
					true ->
						case Lamp#festivial_lamp.role_id =/= PlayerId of
						true ->
							WishCdTime = data_activity:get_activity_lamp_config(wish_cd_time),
							LastWishTime = 
							case get({festivial_lamp_wish, PlayerId}) of
								undefined -> 0;
								Other2 -> Other2
							end, 
							case NowTime-LastWishTime>WishCdTime of
								true ->								
									TimeandWishNum = private_get_dblamp_timeandnum(LampId),
									case TimeandWishNum =/=[] of
										true ->
											[_FetchState, Time, WishNum] = TimeandWishNum,
											FigurekeepTime = data_activity:get_activity_lamp_config(figurekeep),
											case Time>NowTime-FigurekeepTime of
												true ->								
													%% 记录祝福时间
													put({festivial_lamp_wish, PlayerId}, NowTime),
													mod_daily_dict:increment(PlayerId, 2001),
													%% 更新被祝福次数(db|dict)
													SQL1 = io_lib:format(?sql_festival_lamp_update_1, [WishNum+1, LampId]),	
													db:execute(SQL1),
													Wisher_list = Lamp#festivial_lamp.wisher_list,
													NewLamp = Lamp#festivial_lamp{bewish_num=WishNum+1, wisher_list=[PlayerName|Wisher_list]},
													private_update_lamp_dict(NewLamp),
													%% 祝福值满发送邮件通知收取
													case WishNum+1>=BewishNumMax of
														true ->
															Title = data_activity_text:get_notice_lamp_wish_max_title(), 
															Content = data_activity_text:get_notice_lamp_wish_max_content(),
															Content2 = io_lib:format(Content, [Lamp#festivial_lamp.x, Lamp#festivial_lamp.y]),
															lib_mail:send_sys_mail_bg([Lamp#festivial_lamp.role_id], Title, Content2, 0, 0, 0, 0, 0,0,0,0,0);	
														false -> skip
													end,
													%% 获得奖励
													case misc:get_player_process(PlayerId) of
														Pid when is_pid(Pid) ->			
															case misc:is_process_alive(Pid) of 	
																true -> 
																	Response = gen_server:call(Pid, {'wish_for_lamp_award', Lamp#festivial_lamp.type}),
																	[ErrorCode, Exp, GoodsId, _NewPS] = Response,
																	Res =ErrorCode;
																false -> Res =8, Exp=0, GoodsId =0  %%未知错误
															end;
														_ -> Res =8, Exp=0, GoodsId =0  %%未知错误
													end;
												false -> Res =2, Exp=0, GoodsId =0  %%花灯已过燃放时间
											end;									
										false -> Res =8, Exp=0, GoodsId =0  %%未知错误
									end;
								false -> Res =5, Exp=0, GoodsId =0  %%CD未结束
							end; 
						false -> Res =7, Exp=0, GoodsId =0  %%不可以为自己的花灯祝福
						end;						
					false -> Res =4, Exp=0, GoodsId =0  %%花灯收到祝福已达上限 
				end;
			false ->  Res =3, Exp=0, GoodsId =0  %%今日送出祝福已达上限 
			end,
			{ok, Bindata} = pt_315:write(31518, [Res, Exp, GoodsId]),
			lib_unite_send:send_to_uid(PlayerId, Bindata)
	end.

%% 前往祝福奖励
wish_for_lamp_award(PS, Type) ->
	[_,WishAward|_] = data_activity:get_activity_lamp_award(Type),	
	{Exp, GoodsId} = WishAward,
	%% 领取物品经验
	NewPS = lib_player:add_exp(PS, Exp, 0),
	%% 领取物品
	Go = PS#player_status.goods,
	GiveList = [{GoodsId, 1}],	
	case gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', [], GiveList}) of
		ok ->
			lib_gift_new:send_goods_notice_msg(PS, [{goods, GoodsId, 1}]),							
			ErrorCode = 1;	
		{fail, 2} ->	%% 物品不存在
			ErrorCode = 6;
		{fail, 3} ->    %% 背包空间不足
			ErrorCode = 7;
		_Error ->       %% 未知错误
			ErrorCode = 8
	end,
	[ErrorCode, Exp, GoodsId, NewPS].

%% 收获花灯 
gain_lamp(PlayerId, LampId) ->
	LampTupleList = case get(festivial_lamp)  of
		undefined-> [];
		Other -> Other
	end,
	FindRes = lists:keyfind(LampId, 2, LampTupleList),
	case FindRes=:=false of
		true -> skip;
		false ->						
			Lamp = FindRes,
			case Lamp#festivial_lamp.role_id=:=PlayerId of
			true ->
				TimeandWishNum = private_get_dblamp_timeandnum(LampId),
				case TimeandWishNum =/=[] of
					true ->
					[FetchState, _Time, WishNum] = TimeandWishNum,
					[_,_,BewishNumMax,_] = data_activity:get_activity_lamp_award(Lamp#festivial_lamp.type),
					case WishNum>=BewishNumMax of
						true ->
							case FetchState=:=1 of
							true ->
								case misc:get_player_process(PlayerId) of
									Pid when is_pid(Pid) ->			
										case misc:is_process_alive(Pid) of 	
											true -> 
												Response = gen_server:call(Pid, {'gain_lamp_goods', Lamp#festivial_lamp.type}),
												[Res, GoodsId] = Response,
												case Res=:=1 of
													true ->
														%% 更新db以及dict
														SQL1 = io_lib:format(?sql_festival_lamp_update_2, [2,2,LampId]),
														db:execute(SQL1),														
														List = lists:keydelete(Lamp#festivial_lamp.id, 2, LampTupleList),
														put(festivial_lamp, List),
														%% 广播元宵花灯变化
														DefaultUseScene = data_activity:get_activity_lamp_config(default_secne),
														{ok, Bindata1} = pt_315:write(31520, [2, [[LampId, Lamp#festivial_lamp.role_name,
																		Lamp#festivial_lamp.x, Lamp#festivial_lamp.y, Lamp#festivial_lamp.type]]]),
														lib_unite_send:send_to_scene(DefaultUseScene, Bindata1);
													false -> skip
												end;										    	
											false -> Res =6, GoodsId =0  %%未知错误
										end;
									_ -> Res =6, GoodsId =0  %%未知错误
								end;
							false -> Res =7,GoodsId =0 %% 已经收获
							end;							
						false ->
							Res =2,GoodsId =0 %% 花灯祝福值未满
					end;
					false -> Res =6,GoodsId =0 %% 未知错误
				end;
			false -> Res =3,GoodsId =0 %% 不是你的花灯
			end,
			{ok, Bindata2} = pt_315:write(31519, [Res,GoodsId]),
			lib_unite_send:send_to_uid(PlayerId, Bindata2)
	end.
			
%% 收获花灯奖励物品
gain_lamp_goods(PS, Type) ->
	[_,_,_,GoodsId] = data_activity:get_activity_lamp_award(Type),	
	%% 领取物品
	Go = PS#player_status.goods,
	GiveList = [{GoodsId, 1}],	
	case gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', [], GiveList}) of
		ok ->
			lib_gift_new:send_goods_notice_msg(PS, [{goods, GoodsId, 1}]),							
			ErrorCode = 1;	
		{fail, 2} ->	%% 物品不存在
			ErrorCode = 4;
		{fail, 3} ->    %% 背包空间不足
			ErrorCode = 5;
		_Error ->       %% 未知错误
			ErrorCode = 6
	end,
	[ErrorCode,GoodsId].

private_write_firelamp_to_db(RoleId, RoleName, X, Y, Type) ->
	NowTime = util:unixtime(),
	SQL = io_lib:format(?sql_festival_lamp_insert,[RoleId, RoleName, X, Y, Type, NowTime]),
	db:execute(SQL).

private_get_dblamplist_newid(Id) ->
	SQL = io_lib:format(?sql_festival_lamp_select_3, [Id]),
	QueredId = db:get_one(SQL),
	case QueredId of
		null -> QueredId2 =1;
		_Other -> QueredId2 = QueredId
	end,
	QueredId2.

private_get_dblamp_timeandnum(LampId) ->
	SQL = io_lib:format(?sql_festival_lamp_select_4, [LampId]),
	TimeAndWishNum = db:get_row(SQL),
	case TimeAndWishNum of
		[] -> [];
		Other -> Other
	end.

private_write_firelamp_to_dict(Data) ->	
	case get(festivial_lamp)  of
		undefined-> put(festivial_lamp, [Data]);
		Other -> 
			Other2 = Other ++ [Data],
			put(festivial_lamp, Other2)
	end.

private_update_lamp_dict(LampInfo) ->
	LampTupleList = case get(festivial_lamp)  of
		undefined-> [];
		Other -> Other
	end,
    List = lists:keydelete(LampInfo#festivial_lamp.id, 2, LampTupleList),
    List1 = List ++ [LampInfo],
    put(festivial_lamp, List1).

private_split_lamp([], SplitList, _N) ->
	SplitList;
private_split_lamp(LampData, SplitList, N) ->
	case length(LampData)>=N of
		true -> 
			{List1, List2} = lists:split(N, LampData),
			private_split_lamp(List2, [List1|SplitList], N);
		false ->
			private_split_lamp([], [LampData|SplitList], N)
	end.



%% -----------单笔充值活动-------------
init_single_recharge_gift_list() ->
    L = data_recharge_award:get_single_recharge_award_gift(),
    lists:map(fun({Quota,GiftId}) -> {Quota,GiftId,0} end, L).

check_single_time() ->
    Day = data_recharge_award:get_single_day(),
    OpenDay = util:get_open_day(),
    Now = util:unixtime(),
    case OpenDay >= Day of
	true ->
	    [Start, End] = data_recharge_award:get_single_recharge_award_time(),
	    Start =< Now andalso Now =< End;
	false -> false
    end.

send_gift_list(PlayerId, List) ->
    [_, End] = data_recharge_award:get_single_recharge_award_time(),
    Now = util:unixtime(),
    _RemainTime = End - Now,
    RemainTime = case _RemainTime > 0 of
		     true -> _RemainTime;
		     false -> 0
		 end,
    {ok, Bin} = pt_315:write(31530, [List, RemainTime]),
    lib_server_send:send_to_uid(PlayerId, Bin).

update_single_recharge_gift_list(PlayerId, PlayerPid, RechargeNum) ->
    case check_single_time() of
	true ->
	    case self() =:= PlayerPid of
		true ->
		    update_single_recharge_gift_list_sub(PlayerId, RechargeNum);
		false ->
		    gen_server:cast(PlayerPid, {'apply_cast', lib_activity_festival, update_single_recharge_gift_list_sub, [PlayerId, RechargeNum]})
	    end;
	false -> []
    end.

update_single_recharge_gift_list_sub(PlayerId, RechargeNum) ->
    Key = "get_single_recharge" ++ PlayerId,
    case get(Key) of
	undefined ->
	    case db:get_one(io_lib:format(<<"select gift from festival_single_recharge where player_id=~p">>, [PlayerId])) of
		null ->
		    InitList = init_single_recharge_gift_list(),
		    QuotaList = lists:filter(fun({Quota,_,_}) -> RechargeNum >= Quota end, InitList),
		    case QuotaList =:= [] of
			false ->
			    {MaxQuota,GiftId,Num} = util:max_ex(QuotaList, 1),
			    NewList = lists:keyreplace(MaxQuota, 1, InitList, {MaxQuota,GiftId,Num+1}),
			    db:execute(io_lib:format(<<"insert into festival_single_recharge(player_id,gift) values(~p,'~s')">>, [PlayerId, util:term_to_string(NewList)])),
			    put(Key, NewList),
			    send_gift_list(PlayerId, NewList);
			true -> []
		    end;
		R ->
		    InitList = lib_goods_util:to_term(R),
		    QuotaList = lists:filter(fun({Quota,_,_}) -> RechargeNum >= Quota end, InitList),
		    case QuotaList =:= [] of
			false ->
			    {MaxQuota,GiftId,Num} = util:max_ex(QuotaList, 1),
			    NewList = lists:keyreplace(MaxQuota, 1, InitList, {MaxQuota,GiftId,Num+1}),
			    db:execute(io_lib:format(<<"update festival_single_recharge set gift='~s' where player_id=~p">>, [util:term_to_string(NewList), PlayerId])),
			    put(Key, NewList),
			    send_gift_list(PlayerId, NewList);
			true -> []
		    end
	    end;
	List ->
	    QuotaList = lists:filter(fun({Quota,_,_}) -> RechargeNum >= Quota end, List),
	    case QuotaList =:= [] of
		false ->
		    {MaxQuota,GiftId,Num} = util:max_ex(QuotaList, 1),
		    NewList = lists:keyreplace(MaxQuota, 1, List, {MaxQuota,GiftId,Num+1}),
		    db:execute(io_lib:format(<<"update festival_single_recharge set gift='~s' where player_id=~p">>, [util:term_to_string(NewList), PlayerId])),
		    put(Key, NewList),
		    send_gift_list(PlayerId, NewList);
		true -> []
	    end
    end.

get_single_recharge_gift(PS, GiftId) ->
    case check_single_time() of
	true ->
	    PlayerId = PS#player_status.id,
	    Key = "get_single_recharge" ++ PlayerId,
	    case get(Key) of
		undefined -> {false, 0};
		List ->
		    case lists:keyfind(GiftId, 2, List) of
			false -> {false, 0};
			{Quota, GiftId, Num} ->
			    case Num =< 0 of
				true -> {false, 0};
				false ->
				    case gen_server:call(PS#player_status.goods#status_goods.goods_pid, {'give_more_bind', [], [{GiftId, 1}]}) of
					ok ->
					    NewList = lists:keyreplace(GiftId, 2, List, {Quota,GiftId,Num-1}),
					    db:execute(io_lib:format(<<"update festival_single_recharge set gift='~s' where player_id=~p">>, [util:term_to_string(NewList), PlayerId])),
					    put(Key, NewList),
					    send_gift_list(PlayerId, NewList),
					    true;
					{fail, 3} -> {false, 2};
					_ -> {false, 0}
				    end
			    end
		    end
	    end;
	false -> {false, 0}
    end.

%% @return:List = [{额度,礼包ID,可领数量},...]
get_single_recharge_gift_list(PlayerId) ->
    case check_single_time() of
	true ->
	    Key = "get_single_recharge" ++ PlayerId,
	    case get(Key) of
		undefined ->
		    case db:get_one(io_lib:format(<<"select gift from festival_single_recharge where player_id=~p">>, [PlayerId])) of
			null ->
			    InitList = init_single_recharge_gift_list(),
			    db:execute(io_lib:format(<<"insert into festival_single_recharge(player_id, gift) values(~p,'~s')">>, [PlayerId, util:term_to_string(InitList)])),
			    put(Key, InitList),
			    InitList;
			R ->
			    InitList = lib_goods_util:to_term(R),
			    put(Key, InitList),
			    InitList
		    end;
		List ->
		    List
	    end;
	false ->
	    [_,End] = data_recharge_award:get_single_recharge_award_time(),
	    Key = "get_single_recharge" ++ PlayerId,
	    case get(Key) of
		undefined ->
		    case util:unixtime() > End of
			true ->
			    case db:get_one(io_lib:format(<<"select gift from festival_single_recharge where player_id=~p">>, [PlayerId])) of
				null ->
				    put(Key, []),
				    [];
				One ->
				    R = lib_goods_util:to_term(One),
				    Title = data_activity_text:get_single_recharge_title(),
				    Content = data_activity_text:get_single_recharge_content(),
				    SendList = lists:filter(fun({_,_,Num}) -> Num > 0 end, R),
				    lists:foreach(fun({_,GiftId,GiftNum}) -> mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PlayerId], Title, Content, GiftId, 2, 0, 0, GiftNum, 0, 0, 0, 0]) end, SendList),
				    db:execute(io_lib:format(<<"delete from festival_single_recharge where player_id=~p">>,[PlayerId])),
				    put(Key, []),
				    []
			    end;
			false ->
			    put(Key, []),
			    []
		    end;
		V when V =:= [] -> V;
		R ->
		    case util:unixtime() > End of
			true ->
			    Title = data_activity_text:get_single_recharge_title(),
			    Content = data_activity_text:get_single_recharge_content(),
			    SendList = lists:filter(fun({_,_,Num}) -> Num > 0 end, R),
			    lists:foreach(fun({_,GiftId,GiftNum}) -> mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PlayerId], Title, Content, GiftId, 2, 0, 0, GiftNum, 0, 0, 0, 0]) end, SendList),
			    erase(Key),
			    db:execute(io_lib:format(<<"delete from festival_single_recharge where player_id=~p">>,[PlayerId])),
			    put(Key, []),
			    [];
			false -> R
		    end
	    end
    end.

