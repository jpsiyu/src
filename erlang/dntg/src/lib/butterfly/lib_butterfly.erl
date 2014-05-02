%%%--------------------------------------
%%% @Module  : lib_butterfly
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.6
%%% @Description: 捕蝴蝶活动
%%%--------------------------------------

-module(lib_butterfly).
-include("server.hrl").
-include("scene.hrl").
-include("butterfly.hrl").
-include("team.hrl").
-export([
	get_switch/0,				%% 开关
	offline/1,					%% 下线保存数据
	enter/2, 					%% 进入蝴蝶谷场景地图
	kill_mon/2, 				%% 怪物蝴蝶死亡时调用
	add_score/2,				%% 自己捕抓到蝴蝶，增加积分和蝴蝶数量
	share_score/3,				%% 分享队友积分
	get_step_award/2,			%% 获取阶段奖励
	timer_get_next_time/2,		%% 定时器调用：获得下次需要处理倒计时秒数，供定时器状态机使用
	broadcast/4,				%% 定时器调用：广播活动开始或结束
	check_time_from_timer/2,	%% 检查是否在活动时间内
	create_boss/3,				%% 生成紫色，橙色蝴蝶
	init_butterfly_mon/1,		%% 初始化房间怪物
	init_room_boss/1,			%% 初始化房间怪物
	remove_all_mon/1			%% 移除所有怪物
]).

%% 功能开关
%% 返回：false关，true开
get_switch() ->
	lib_switch:get_switch(butterfly).

%% 下线回写数据
offline(PS) ->
    case get_switch() of
        true ->
            Butterfly = PS#player_status.butterfly,
            case Butterfly#player_butterfly.score /= undefined of
                true ->
                    GetStat = util:term_to_string(Butterfly#player_butterfly.get_stat),
                    StepAward = util:term_to_string(Butterfly#player_butterfly.step_award),
                    db:execute(
                        io_lib:format(?SQL_BUTTERFLY_UPDATE, [
                                Butterfly#player_butterfly.score,
                                Butterfly#player_butterfly.exp,
                                Butterfly#player_butterfly.llpt,
                                GetStat,
                                StepAward,
                                Butterfly#player_butterfly.score_award,
                                Butterfly#player_butterfly.login_day,
                                PS#player_status.id
                            ])
                    );
                _ ->
                    skip
            end;
        _ ->
            skip
    end.

%% 进入蝴蝶谷场景地图
enter(PS, RoomId) ->
	%% 判断是否可以传送
	case lib_player:is_transferable(PS) of
		true ->
			%% 从公共线定时器中获取活动周期及时间
			[WeekRange, TimeRange, RoomList] = private_get_data_from_timer(),
			%% 判断是否在活动时间内
			case check_time_from_timer(WeekRange, TimeRange) of
				true ->
					%% 判断房间是否满员
					case private_is_room_full(RoomId, RoomList) of
						false ->
							{SceneId, X, Y} = data_butterfly:get_scene(),

							%% 切换到地图场景中，并保存进入场景前的坐标，用于退出时还原坐标。移动速度也会保存。
							mod_exit:insert_last_xy(PS#player_status.id, PS#player_status.scene, PS#player_status.x, PS#player_status.y),

							%% 切换场景
							lib_scene:change_scene_queue(PS, SceneId, RoomId, X, Y, 0),									

							%% 初始化ps数据
							NewPS2 = private_init_player_status(PS, WeekRange, TimeRange),

							%% 房间人数加1
							mod_butterfly:change_num(RoomId, 1),

	                        %% 活跃度：参与捕抓蝴蝶活动
	                        mod_active:trigger(PS#player_status.status_active, 13, 0, PS#player_status.vip#status_vip.vip_type),

							%% 刷新道具数量
							lib_butterfly_goods:refresh_item_num(NewPS2),

							%% 还原道具buff
							lib_butterfly_goods:recover_buff_time(NewPS2),

							{ok, NewPS2,
								NewPS2#player_status.butterfly#player_butterfly.score,
								data_butterfly:get_score_limitup(),
								NewPS2#player_status.butterfly#player_butterfly.exp,
								NewPS2#player_status.butterfly#player_butterfly.llpt,
								private_format_get_stat(NewPS2#player_status.butterfly),
								private_format_award(NewPS2#player_status.butterfly)
							};
						_ ->
							%% 房间人数已满
							{error, 5}
					end;
				_ ->
					%% 不在活动时间内
					{error, 3}
			end;
		_ ->
			%% 无法进入蝴蝶谷场景
			{error, 4}
	end.

%% 怪物蝴蝶死亡时调用
%% 可获得积分、经验与历练声望
kill_mon(MonId, RoleId) ->
	case get_switch() of
		true ->
			%% 判断怪物是否蝴蝶中的一种
			case lists:member(MonId, data_butterfly:get_mon_ids()) of
				true ->
					%% 发给捕到蝴蝶的玩家主进程处理
					private_cast_to_role(RoleId, add_butterfly_score, MonId);
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%% 自己捕抓到蝴蝶，增加积分和蝴蝶数量
add_score(Status, MonId) ->
	%% 判断等级是否满足
	case Status#player_status.lv >= data_butterfly:require_level() of
		true ->
			%% 判断是否在活动时间内
			case check_time_from_timer(Status#player_status.butterfly#player_butterfly.weekrange, Status#player_status.butterfly#player_butterfly.timerange) of
				true ->
					%% 取出队员
					case Status#player_status.pid_team > 0 of
						true ->
							Members = lib_team:get_members(Status#player_status.pid_team);
						_ ->
							Members = []
					end,

					%% 蝴蝶对应的积分
					Score = data_butterfly:get_butterfly_score(MonId),
					Score2 = round(Score * private_is_three_career(Members)),

					%% 处理自己积分
					NewStatus = private_add_score(Status, MonId, Score2),

					%% 为所有队员增加积分
					case NewStatus#player_status.pid_team > 0 of
                        true ->
							[private_cast_to_role(Mem#mb.id, share_butterfly_score, [NewStatus#player_status.copy_id, Score2]) || Mem <- Members, Mem#mb.id /= Status#player_status.id];
                        _ ->
                            skip
                    end,

					%% 只为最后一个击杀怪物的玩家获得道具
					private_bind_item(NewStatus, MonId),

					%% 指定分钟后重新生成boss
					case (MonId =:= ?BUTTERFLY_ORANGE_ID) or (MonId =:= ?BUTTERFLY_PURPLE_ID) of
						true ->
							timer:apply_after(
								data_butterfly:get_refresh_boss_time(MonId) * 1000, 
								lib_butterfly, create_boss, [0, Status#player_status.copy_id, MonId]
							);
						_ ->
							skip
					end,
					NewStatus;
				_ ->
					Status
			end;
		_ ->
			Status
	end.

%% 与队友分享积分
share_score(PS, CopyId, Score) ->
	case PS#player_status.scene =:= data_butterfly:get_sceneid() andalso PS#player_status.copy_id =:= CopyId of
		true ->
			Butterfly = PS#player_status.butterfly,
			LimitUp = data_butterfly:get_score_limitup(),
			case is_integer(Butterfly#player_butterfly.score) andalso Butterfly#player_butterfly.score < LimitUp of
				true ->
					AddScore = case Butterfly#player_butterfly.score + Score > LimitUp of
						true ->
							LimitUp - Butterfly#player_butterfly.score;
						_ ->
							Score
					end,
					%% 增加经验与历练
					MultiAward = private_get_multi_award_time(PS),
					TmpExp = data_butterfly:get_exp(PS#player_status.lv, AddScore),
					Exp = private_offline_award(TmpExp),
					
					Exp2 = round(Exp * MultiAward),
					LLPT = data_butterfly:get_llpt(PS#player_status.lv, AddScore),
					LLPT2 = round(LLPT * MultiAward),
					NewPS = lib_player:add_pt(llpt, PS, LLPT2),
					NewPS2 = lib_player:add_exp(NewPS, Exp2, 0),
					NewButterfly = Butterfly#player_butterfly{
						score = Butterfly#player_butterfly.score + AddScore,
						exp = Butterfly#player_butterfly.exp + Exp2,
						llpt = Butterfly#player_butterfly.llpt + LLPT2
					},
		
					NewPS3 = NewPS2#player_status{butterfly = NewButterfly},
		
					%% 刷新收益
					refresh_award(NewPS3),

					%% 如果达到满分，需要弹出翻牌
					case NewButterfly#player_butterfly.score >= LimitUp of
						true ->
							private_get_full_award(NewPS3);
						_ ->
							skip
					end,

					%% 发玩家属性变化通知
					case AddScore > 0 of
						true -> lib_player:send_attribute_change_notify(NewPS3, 2);
						_ -> skip
					end,

					NewPS3;
				_ ->
					PS
			end;
		_ ->
			PS
	end.

%% 获取阶段奖励
%% Level : 奖励等级，1为特等奖，2为一等奖，3为二等奖，4为三等奖
get_step_award(PS, Level) ->
	case lists:member(Level, [1,2,3,4]) of
		true ->
			Butterfly = PS#player_status.butterfly,
			%% 判断是否已经领取过奖励
			case lists:member(Level, Butterfly#player_butterfly.step_award) of
				%% 奖励未领取满
				false ->
					%% 统计各种蝴蝶的数量
					NewStat = 
						lists:foldl(fun({Id, Num}, Stat) -> 
							private_count_butterfly_num(Id, Num, Stat)
						end, [0, 0, 0, 0, 0], Butterfly#player_butterfly.get_stat),

					LevelResult = 
						lists:foldl(fun({RequireStat, TargetLevel}, AwardList) -> 
							case private_is_reach_require(RequireStat, NewStat) of
								true ->
									[TargetLevel | AwardList];
								_ ->
									AwardList
							end
						end, [], data_butterfly:get_step_award_data()),

					%% 判断是否达到奖励要求
					case lists:member(Level, LevelResult) of
						true ->
							case data_butterfly:get_step_award(Level) of
								[] ->
									{error, 2};
								[GoodsId, GoodsNum] ->
									case private_fetch_step_award(PS, GoodsId, GoodsNum, 2) of
										{ok} ->
											NewButterfly = Butterfly#player_butterfly{
												step_award = [Level | Butterfly#player_butterfly.step_award]				 
											},
		
											{ok, PS#player_status{butterfly = NewButterfly}};
										{error, ErrorCode} ->
											{error, ErrorCode}
									end
							end;
						_ ->
							{error, 2}
					end;

				%% 奖励已经领满
				_ ->
					{error, 3}
			end;
		_ ->
			{error, 999}
	end.

%% 获得下次需要处理倒计时秒数，供定时器状态机使用
timer_get_next_time(WeekRange, TimeRange) ->
	NowTS = util:unixtime(),
	[BeginTS, EndTS] = private_get_activity_unixtime(TimeRange),
	NextTime = case lists:member(util:get_day_of_week(), WeekRange) of
		%% 今天有活动
		true ->
			if
				%% 在开始1分钟前
				NowTS < BeginTS - 60 ->
					BeginTS - NowTS - 60;

				%% 在开始时间前
				NowTS < BeginTS ->
					60;

				%% 在活动期间，每隔指定秒数发一次活动开始广播
				(NowTS >= BeginTS) andalso (NowTS < EndTS + 120) ->
					data_butterfly:timer_refresh_time();

				%% 超过活动结束时间，则休眠到明天活动开始时
				NowTS >= EndTS + 120 ->
					BeginTS + 86400 - NowTS - 60;

				%% 异常情况每半个钟处理一次
				true ->
					1800
			end;

		%% 星期几不对，到第二天活动开始时再次触发
		_ ->
			BeginTS + 86400 - NowTS - 60
	end,
	NextTime.

%% 广播活动开始，前端会出现活动图标
broadcast(WeekRange, TimeRange, CreateBoss, RemoveBoss) ->
	case get_switch() of
		true ->
			case lists:member(util:get_day_of_week(), WeekRange) of
				true ->
					NowTS = util:unixtime(),
					[BeginTS, EndTS] = private_get_activity_unixtime(TimeRange),
					if
						%% 活动开始1分钟内生成好蝴蝶
						(NowTS >= BeginTS) andalso (NowTS < BeginTS + 60) ->
							%% 初始化房间并生成怪物
							mod_butterfly:init_room(),
							%% 广播活动开始
							private_broadcast_begin(EndTS - NowTS),
							[CreateBoss, RemoveBoss];

						%% 在活动开始 到 结束时间2分钟之前，广播活动开始
						(NowTS >= BeginTS + 60) andalso (NowTS < EndTS - 120) ->
							%% 广播活动开始
							private_broadcast_begin(EndTS - NowTS),
							[CreateBoss, RemoveBoss];

						%% 在结束时间及超过结束时间1分钟内，广播活动结束，让一部分人先退出场景
						(NowTS >= EndTS) andalso (NowTS < EndTS + 60) ->
							%% 广播活动结束
							private_broadcast_end(),
							[CreateBoss, RemoveBoss];

						%% 在结束时间1分钟后2分钟内，再发一次活动结束广播
						(NowTS >= EndTS + 60) andalso (NowTS < EndTS + 120) ->
							%% 广播活动结束
							private_broadcast_end(),
							%% 清除房间数据
							mod_butterfly:clean_room(),
							[CreateBoss, RemoveBoss];
						true ->
							[CreateBoss, RemoveBoss]
					end;
				_ ->
					[CreateBoss, RemoveBoss]
			end;
		_ ->
			[CreateBoss, RemoveBoss]
	end.

%% 检查是否在活动时间内
%% 返回：true是，false否
check_time_from_timer(WeekRange, TimeRange) ->
	case lists:member(util:get_day_of_week(), WeekRange) of
		true ->
			[StartTime, EndTime] = private_get_activity_unixtime(TimeRange),
			NowTime = util:unixtime(),
			case NowTime >= StartTime andalso NowTime < EndTime of
				true ->
					true;
				%% 活动有规定时间
				_ ->
					false
			end;
		%% 活动有规定星期几
		_ ->
			false
	end.

%% 紫色和橙色蝴蝶被杀死后重新生成
%% ServerType : 1为公共线，0为游戏线
%% CopyId : 房间ID
%% MonId : 怪物ID
create_boss(ServerType, CopyId, MonId) ->
	{SceneId, _, _} = data_butterfly:get_scene(),
	case data_butterfly:get_boss_position(MonId) of
		{X, Y} ->
            lib_mon:async_create_mon(MonId, SceneId, X, Y, 0, CopyId, 1, [{auto_lv, data_butterfly:require_level()}]),
			%% 橙色蝴蝶发送传闻
			case MonId =:= ?BUTTERFLY_ORANGE_ID of
				true ->
					lib_chat:send_TV({scene, SceneId, CopyId}, ServerType, 2, ["catchBf", 1]);
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%% 活动结束时，清除掉所有蝴蝶
remove_all_mon(RoomId) ->
	{SceneId, _, _} = data_butterfly:get_scene(),
    %% 清理场景
    mod_scene_agent:apply_cast(SceneId, mod_scene, clear_scene, [SceneId, RoomId]),
	%% 清除怪物
    lib_mon:clear_scene_mon(SceneId, RoomId, 1).

%% [场景进程调用] 生成怪物
init_butterfly_mon(RoomId) ->
	{SceneId, _, _} = data_butterfly:get_scene(),

	%% 生成各种蝴蝶（不包括橙色，紫色蝴蝶）
	lists:map(fun({Id, X, Y}) -> 
                mod_mon_create:create_mon(Id, SceneId, X, Y, 0, RoomId, 0, [])
	end, data_butterfly:get_mon_position()),

	%% 生成2只橙色蝴蝶
	OraList = data_butterfly:get_refresh_boss_position(?BUTTERFLY_ORANGE_ID),
	OraList2 = util:list_shuffle(OraList),
	OraList3 = lists:sublist(OraList2, data_butterfly:get_refresh_boss_num(?BUTTERFLY_ORANGE_ID)),
	lists:map(fun({OraX, OraY}) ->
                mod_mon_create:create_mon(?BUTTERFLY_ORANGE_ID, SceneId, OraX, OraY, 0, RoomId, 0, [])
	end, OraList3),

	%% 生成8只紫色蝴蝶
	PurList = data_butterfly:get_refresh_boss_position(?BUTTERFLY_PURPLE_ID),
	PurList2 = util:list_shuffle(PurList),
	PurList3 = lists:sublist(PurList2, data_butterfly:get_refresh_boss_num(?BUTTERFLY_PURPLE_ID)),
	lists:map(fun({PurX, PurY}) ->
                mod_mon_create:create_mon(?BUTTERFLY_PURPLE_ID, SceneId, PurX, PurY, 0, RoomId, 0, [])
	end, PurList3),
	ok.

%% 活动开始前，会初始化好蝴蝶
init_room_boss(RoomId) ->
	{SceneId, _, _} = data_butterfly:get_scene(),
	mod_scene_agent:apply_call(SceneId, lib_butterfly, init_butterfly_mon, [RoomId]).

%% 奖励多倍奖励
private_get_multi_award_time(PS) ->
	lib_multiple:get_multiple_by_type(2,PS#player_status.all_multiple_data).

%% 取出活动时间
private_get_activity_unixtime([{StartH, StartM}, {EndH, EndM}]) ->
	TodayTS = util:unixdate(),
	BeginTS = TodayTS + StartH * 3600 + StartM * 60,
	EndTS = TodayTS + EndH * 3600 + EndM * 60,
	[BeginTS, EndTS].

%% 广播活动开始
%% 参数：Second	倒计时秒数
private_broadcast_begin(Second) ->	
	{ok, BinData} = pt_342:write(34201, Second),
	lib_unite_send:send_to_all(data_butterfly:require_level(), 100, BinData).

%% 广播活动结束
private_broadcast_end() ->
	{ok, BinData} = pt_342:write(34202, 1),
	lib_unite_send:send_to_all(data_butterfly:require_level(), 100, BinData).

%% 杀怪获得道具
private_bind_item(PS, MonId) ->
	RoleId = PS#player_status.id,
	F = fun(ItemId, List) ->
		case data_butterfly:get_item_rate(MonId, ItemId) of
			0 ->
				List;
			Rand ->
				case util:rand(1, 100) =< Rand of
					true ->
						[{ItemId, 1} | List];
					_ ->
						List
				end
		end
	end,
%% 	NewList = lists:foldl(F, [], [1, 2, 3]),
	NewList = lists:foldl(F, [], [1]),
	case length(NewList) > 0 of
		true ->
			lists:map(fun({Type, Num}) -> 
				%% 道具数量加到计数器中
				if
					Type =:= 1 ->
						mod_daily:plus_count(PS#player_status.dailypid, RoleId, ?BUTTERFLY_CACHE_SPEED_UP, Num);
					Type =:= 2 ->
						mod_daily:plus_count(PS#player_status.dailypid, RoleId, ?BUTTERFLY_CACHE_SPEED_DOWN, Num);
					Type =:= 3 ->
						mod_daily:plus_count(PS#player_status.dailypid, RoleId, ?BUTTERFLY_CACHE_DOUBLE, Num);
					true ->
						skip
				end
			end, NewList),

			%% 发送已经获得的道具
			F2 = fun(Pitem) ->
				{SendType, SendNum} = Pitem,
				<<SendType:8, SendNum:16>>
			end,
			SendList = [F2(SendItem) || SendItem <- NewList],
			{ok, SendBinData} = pt_342:write(34211, SendList),
			lib_server_send:send_to_sid(PS#player_status.sid, SendBinData);
		_ ->
			skip
	end.

%% 增加自己的收益
%% MonId : 怪物id
private_add_score(PS, MonId, ButterflyScore) ->
	%% 满积分上限
	LimitUp = data_butterfly:get_score_limitup(),
	Butterfly = PS#player_status.butterfly,

	%% 积分已经达到上限，经验跟历练不会再增加
	case Butterfly#player_butterfly.score < LimitUp of
		true ->
			AddScore = 
				case Butterfly#player_butterfly.score + ButterflyScore > LimitUp of
					true ->
						LimitUp - Butterfly#player_butterfly.score;
					_ ->
						ButterflyScore
				end,

			%% 增加经验与历练
			MultiAward = private_get_multi_award_time(PS),
			TmpExp = data_butterfly:get_exp(PS#player_status.lv, AddScore),
			Exp = private_offline_award(TmpExp),
			
			Exp2 = round(Exp * MultiAward),
			LLPT = data_butterfly:get_llpt(PS#player_status.lv, AddScore),
			LLPT2 = round(LLPT * MultiAward),
			NewPS = lib_player:add_pt(llpt, PS, LLPT2),
			NewPS2 = lib_player:add_exp(NewPS, Exp2, 0),

			NewGetStat = private_format_butterfly_stat(Butterfly#player_butterfly.get_stat, MonId),
			NewButterfly = Butterfly#player_butterfly{
				score = Butterfly#player_butterfly.score + AddScore,
				exp = Butterfly#player_butterfly.exp + Exp2,
				llpt = Butterfly#player_butterfly.llpt + LLPT2,
				get_stat = NewGetStat
			},

			NewPS3 = NewPS2#player_status{butterfly = NewButterfly},

			%% 刷新属性
			lib_player:send_attribute_change_notify(NewPS3, 2),

			%% 刷新收益
			refresh_award(NewPS3),

			%% 如果是橙色蝴蝶，需要提示信息
			case MonId =:= ?BUTTERFLY_ORANGE_ID of
				true ->
					{ok, OrangeBinData} = pt_342:write(34214, [MonId, AddScore]),
					lib_server_send:send_to_sid(PS#player_status.sid, OrangeBinData);
				_ ->
					skip
			end,

			%% 如果达到满分，需要弹出翻牌
			case NewButterfly#player_butterfly.score >= LimitUp of
				true ->
					private_get_full_award(NewPS3);
				_ ->
					skip
			end,
			NewPS3;
		_ ->
			NewGetStat = private_format_butterfly_stat(Butterfly#player_butterfly.get_stat, MonId),
			NewButterfly = Butterfly#player_butterfly{
				get_stat = NewGetStat									  
			},
			NewPS = PS#player_status{butterfly = NewButterfly},
			%% 刷新收益
			refresh_award(NewPS),
			NewPS
	end.

%% 刷新收益
refresh_award(PS) ->
	%% 取出最新值并广播给玩家
	{ok, BinData} = pt_342:write(34212, [
		PS#player_status.butterfly#player_butterfly.score,
		PS#player_status.butterfly#player_butterfly.exp,
		PS#player_status.butterfly#player_butterfly.llpt, 
		private_format_get_stat(PS#player_status.butterfly),
		private_format_award(PS#player_status.butterfly)
	]),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData).

%% 获得满积分奖励，并弹出翻牌窗口
private_get_full_award(PS) ->
	%% 查出可以抽几等奖
	case data_butterfly:get_max_score_award(private_get_full_award_position()) of
		[GoodsTypeId, GoodsNum, Bind] ->
			%% 送物品奖励
			case mod_other_call:send_bind_goods(PS, GoodsTypeId, GoodsNum, Bind) of
				ok ->
					{ok,BinData} = pt_342:write(34215, [1, GoodsTypeId, 1, 1]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData);
				 {fail, Res} ->
					{ok,BinData} = pt_342:write(34215, [Res, GoodsTypeId, 1, 1]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData);
				_ ->
					{ok,BinData} = pt_342:write(34215, [999, GoodsTypeId, 1, 1]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			end;
		_ ->
			skip
	end.

%% 满积分可以中多少等奖
private_get_full_award_position() ->
	Rand = util:rand(1, 100),
	List = data_butterfly:get_max_score_award_rate(),
	F = fun({Min, Max, TargetId}, ReturnNum) ->
		case Rand >= Min andalso Rand =< Max of
			true ->
				TargetId;
			_ ->
				ReturnNum
		end
	end,
	Num = lists:foldl(F, 0, List),
	Num.

%% 从定时器获得活动开始周期及房间数据
%% 返回：[WeekRange, TimeRange, RoomList]
private_get_data_from_timer() ->
	mod_butterfly:get_data().

%% 检查指定房间人数是否满了
private_is_room_full(RoomId, RoomList) ->
	private_get_room_num(RoomId, RoomList) >= data_butterfly:get_room_limit().

%% 取得指定房间人数
private_get_room_num(_RoomId, []) ->
	1000;
private_get_room_num(RoomId, [{Id, Num} | T]) ->
	case RoomId =:= Id of
		true -> Num;
		_ -> private_get_room_num(RoomId, T)
	end.

%% 初始化ps缓存数据
private_init_player_status(PS, WeekRange, TimeRange) ->
	Today = util:unixdate(),
	case PS#player_status.butterfly#player_butterfly.score == undefined orelse 
		PS#player_status.butterfly#player_butterfly.login_day < Today of
		%% 今天没初始化过，需要初始化一次
		true ->
			case db:get_row(io_lib:format(?SQL_BUTTERFLY_SELECT, [PS#player_status.id])) of
				[_, Score, Exp, LLPT, GetStat, StepAward, ScoreAward, DayTime] ->
					%% 数据过时，需要再初始化一次
					case DayTime < Today of
						true ->
							db:execute(io_lib:format(
								?SQL_BUTTERFLY_UPDATE,
								[0, 0, 0, '[]', '[]', 0, Today, PS#player_status.id]
							)),
							Butterfly = #player_butterfly{
								speed = PS#player_status.speed,
								score = 0,
								login_day = Today,
								weekrange = WeekRange,
								timerange = TimeRange
							},
							PS#player_status{
								butterfly = Butterfly
							};
						_ ->
							Butterfly = #player_butterfly{
								speed = PS#player_status.speed,
								score = Score,
								exp = Exp,
								llpt = LLPT,
								get_stat = util:to_term(GetStat),
								step_award = util:to_term(StepAward),
								score_award = ScoreAward,
								login_day = Today,
								weekrange = WeekRange,
								timerange = TimeRange
							},
							PS#player_status{
								butterfly = Butterfly
							}
					end;

				%% 之前没玩过，插入新记录
				_ ->
					db:execute(io_lib:format(?SQL_BUTTERFLY_INSERT, [PS#player_status.id])),
					Butterfly = #player_butterfly{
						speed = PS#player_status.speed,
						score = 0,
						login_day = Today,
						weekrange = WeekRange,
						timerange = TimeRange
					},
					PS#player_status{
						butterfly = Butterfly
					}
			end;
		_ ->
			Butterfly = PS#player_status.butterfly#player_butterfly{
				speed = PS#player_status.speed
			},
			PS#player_status{
				butterfly = Butterfly
			}
	end.

%% 获取是否有三个不同职业
private_is_three_career(Members) ->
 	L = [R#mb.career || R <- Members],
 	Result = [lists:member(N, L) || N <- [1,2,3]],
 	case Result =:= [true, true, true] of
 		true -> data_butterfly:get_tree_career_rate();
 		_ -> 1
 	end.

%% 统计各种蝴蝶的数量
private_count_butterfly_num(?BUTTERFLY_ORANGE_ID, Num, [V1, V2, V3, V4, V5]) -> [V1 + Num, V2, V3, V4, V5];
private_count_butterfly_num(?BUTTERFLY_PURPLE_ID, Num, [V1, V2, V3, V4, V5]) -> [V1, V2 + Num, V3, V4, V5];
private_count_butterfly_num(?BUTTERFLY_BLUE_ID, Num, [V1, V2, V3, V4, V5]) -> [V1, V2, V3 + Num, V4, V5];
private_count_butterfly_num(?BUTTERFLY_GREEN_ID, Num, [V1, V2, V3, V4, V5]) -> [V1, V2, V3, V4 + Num, V5];
private_count_butterfly_num(?BUTTERFLY_WHITE_ID, Num, [V1, V2, V3, V4, V5]) -> [V1, V2, V3, V4, V5 + Num].

%% 各种蝴蝶的数量是否都达到要求
private_is_reach_require(Require, Stat) ->
    [A1, A2, A3, A4, A5] = Stat,
    [B1, B2, B3, B4, B5] = Require,
    A1>=B1 andalso A2>=B2 andalso A3>=B3 andalso A4>=B4 andalso A5>=B5.

%% 领取物品奖励
private_fetch_step_award(PS, GoodsTypeId, GoodsNum, Bind) ->
	case mod_other_call:send_bind_goods(PS, GoodsTypeId, GoodsNum, Bind) of
		ok -> {ok};
		{fail, ErrorCode} -> 
			if 
				ErrorCode == 2 ->
					{error, 10};
				ErrorCode == 3 ->
					{error, 11};
				true ->
					{error, 999}
			end;
		_ ->
			{error, 999}
	end.

%% 格式化已捕到的蝴蝶数据
private_format_get_stat(Butterfly) ->
	lists:map(fun({ButterflyId, ButterflyNum}) ->
		Index = data_butterfly:get_butterfly_index(ButterflyId),
		<<Index:32, ButterflyNum:16>>
	end, Butterfly#player_butterfly.get_stat).

%% 格式化已获得阶段奖励数据
private_format_award(Butterfly) ->
	%% 统计各种蝴蝶的数量
	NewStat = 
		lists:foldl(fun({Id, Num}, Stat) -> 
			private_count_butterfly_num(Id, Num, Stat)
		end, [0, 0, 0, 0, 0], Butterfly#player_butterfly.get_stat),

	LevelResult = 
		lists:foldl(fun({RequireStat, Level}, AwardList) -> 
			case private_is_reach_require(RequireStat, NewStat) of
				true ->
					[Level | AwardList];
				_ ->
					AwardList
			end
		end, [], data_butterfly:get_step_award_data()),

	Step = [1,2,3,4],
	F = fun(StepId) ->
		case lists:member(StepId, Butterfly#player_butterfly.step_award) of
			%% 已经领取过奖励
			true ->
				<<StepId:8, 2:8>>;
			%% 没领取过需要判断是否达到要求
			_ ->
				case lists:member(StepId, LevelResult) of
					true ->
						<<StepId:8, 1:8>>;
					_ ->
						<<StepId:8, 0:8>>
				end
		end
	end,
	[F(Id) || Id <- Step].

%% 格式化蝴蝶数据，增加一只蝴蝶
private_format_butterfly_stat(Stat, ButterflyId) ->
	[NewStat, NewExist] = 
		lists:foldl(fun({Id, Num}, [List, Exist]) -> 
			case ButterflyId =:= Id of
				true ->
					[[{Id, Num + 1} | List], Exist + 1];
				_ ->
					[[{Id, Num} | List], Exist]
			end
		end, [[], 0], Stat),
	case NewExist =:= 1 of
		true ->
			NewStat;
		_ ->
			[{ButterflyId, 1} | NewStat]
	end.

%% cast到玩家进程处理
private_cast_to_role(RoleId, Action, Args) ->
	case misc:get_player_process(RoleId) of
		Pid when is_pid(Pid) ->
			catch gen_server:cast(Pid, {Action, [Args]});
		_ ->
			skip
	end.

%% 下线经验奖励
private_offline_award(Award) ->
	case lib_off_line:activity_time() of
		true -> round(Award * (1 + 0.2));
		_ -> Award
	end.
