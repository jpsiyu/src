%%%--------------------------------------
%%% @Module  : lib_fish
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.9.17
%%% @Description: 全民垂钓 
%%%--------------------------------------

-module(lib_fish).
-include("server.hrl").
-include("scene.hrl").
-include("fish.hrl").
-include("team.hrl").
-export([
    get_switch/0,
	init_env/0,
	gm_init_env/0,
    offline/1,
    enter/2,
    start_fishing/2,
    end_fishing/1,
    share_score/3,
    steal_fish/2,
    finish_steal/1,
    get_step_award/1,
    get_score_award/1,
    timer_get_next_time/2,
    broadcast/2,
    check_time_from_timer/2,
    init_room_boss/1,
    remove_all_mon/1,
    init_mon/1,
    create_fish_boss/3,
	refresh_award/1,
    send_msg/3,
	set_service_in_manage/4
]).

%% 功能开关
%% 返回：false关，true开
get_switch() ->
	lib_switch:get_switch(fish).

%% 初始化活动数据
%% 该方法是在活动未开启时调用的，将生成好所有房间的鱼
init_env() ->
	SceneId = data_fish:get_sceneid(),
	RoomList = [1,2,3,4,5,6,7,8,9,10],

	%% 清理所有房间的怪
	lists:foreach(fun(RoomId) -> 
		lib_mon:clear_scene_mon(SceneId, RoomId, 0),
		timer:sleep(2000)
	end, RoomList),

	%% 生成所有房间的怪
	lists:foreach(fun(RoomId) -> 
		init_room_boss(RoomId),
		timer:sleep(5000)
	end, RoomList),

	ok.

%% 秘籍，重新生成鱼
gm_init_env() ->
	mod_disperse:cast_to_unite(lib_fish, init_env, []),
	ok.

%% 下线回写数据
offline(PS) ->
    case get_switch() of
        true ->
            Fish = PS#player_status.fish,
            case Fish#status_fish.score /= undefined of
                true ->
                    FishStat = util:term_to_string(Fish#status_fish.fish_stat),
                    StepAward = util:term_to_string(Fish#status_fish.step_award),
                    db:execute(
                        io_lib:format(?SQL_FISH_UPDATE, [
						    Fish#status_fish.score,
						    Fish#status_fish.exp,
						    Fish#status_fish.llpt,
						    Fish#status_fish.steal_num,
						    FishStat,
						    StepAward,
						    Fish#status_fish.score_award,
						    Fish#status_fish.login_day,
						    PS#player_status.id
						])
                    );
                _ ->
                    skip
            end;
        _ ->
            skip
    end.

%% 进入场景
enter(PS, RoomId) ->
	case PS#player_status.lv >= data_fish:require_lv() of
		true ->
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
									SceneId = data_fish:get_sceneid(),
									{X, Y} = data_fish:get_enter_xy(),

									%% 切换到地图场景中，并保存进入场景前的坐标，用于退出时还原坐标。移动速度也会保存。
									mod_exit:insert_last_xy(PS#player_status.id, PS#player_status.scene, PS#player_status.x, PS#player_status.y),
									%% 切换到场景
									lib_scene:change_scene_queue(PS, SceneId, RoomId, X, Y, 0),									
									%% 初始化ps数据
									NewPS2 = private_init_player_status(PS, WeekRange, TimeRange),

									%% 活跃度：参与捕抓蝴蝶或钓鱼活动
									mod_active:trigger(NewPS2#player_status.status_active, 13, 0, NewPS2#player_status.vip#status_vip.vip_type),

									{ok, NewPS2};
								_ ->
									%% 房间人数已满
									{error, 10}
							end;
						_ ->
							%% 不在活动时间内
							{error, 3}
					end;
				_ ->
					%% 无法进入场景
					{error, 6}
			end;
		_ ->
			%% 等级不足
			{error, 2}
	end.

%% 抛杆
%% MonId : 场景中的怪物id（非怪物类型）
start_fishing(PS, MonId) ->
	case PS#player_status.scene =:= data_fish:get_sceneid() of
		true ->
			%% 检查怪是否存在
			case private_is_mon_exist(PS, MonId) of
				true ->
					Fish = PS#player_status.fish#status_fish{
						fishing_time = util:unixtime(),
						fishing_monid = MonId
					},
					{ok, PS#player_status{fish = Fish}};
				_ ->
					{error, 2}
			end;
		_ ->
			{error, 3}
	end.

%% 收杆
end_fishing(PS) ->
    Now = util:unixtime(),
    StartTime = PS#player_status.fish#status_fish.fishing_time,
    MonId = PS#player_status.fish#status_fish.fishing_monid,
    SpaceTime = round((Now - StartTime) rem 20),
    case SpaceTime > 9 andalso SpaceTime < 15 andalso MonId > 0 of
        true ->
            %% 判断怪是否还存在，有没有被其他人钓走
            case lib_mon:get_scene_mon_by_ids(PS#player_status.scene, [MonId], [all]) of
                [Mon] when is_record(Mon, ets_mon), Mon#ets_mon.hp > 0 ->
					%% 从场景中将怪移除
                    lib_mon:clear_scene_mon_by_ids(PS#player_status.scene, PS#player_status.copy_id, 1, [MonId]),

                    [NewPS, AddScore, FishScore] = private_get_award(PS, Mon#ets_mon.mid),

                    %% 刷新客户端收益
                    refresh_award(NewPS),

                    %% 发玩家属性变化通知
                    case AddScore > 0 of
                        true -> lib_player:send_attribute_change_notify(NewPS, 2);
                        _ -> skip
                    end,

                    %% 跟队友共享积分
                    case PS#player_status.pid_team > 0 of
                        %% 为所有队员增加积分
                        true ->
                            Members = lib_team:get_members(PS#player_status.pid_team),
                            ShareScore = round(FishScore * private_is_three_career(Members)),
                            case ShareScore of
                                0 ->
                                    skip;
                                _ ->
                                    [private_share_score(Mem#mb.id, PS#player_status.copy_id, ShareScore) || Mem <- Members, Mem#mb.id /= PS#player_status.id]
                            end;
                        _ ->
                            skip
                    end,

                    %% 弹出翻牌面板
                    LimitUp = data_fish:get_score_limitup(),
                    case PS#player_status.fish#status_fish.score < LimitUp andalso 
                        NewPS#player_status.fish#status_fish.score >= LimitUp of
                        true ->
                            {ok, BinData} = pt_331:write(33125, 1),
                            lib_server_send:send_to_sid(PS#player_status.sid, BinData);
                        _ ->
                            skip
                    end,

                    %% 重新生成怪物
                    case lists:member(Mon#ets_mon.mid, [?FISH_ID_1, ?FISH_ID_2]) of
                        true ->
							mod_disperse:cast_to_unite(
								lib_fish,
								create_fish_boss,
								[1, PS#player_status.copy_id, Mon#ets_mon.mid]
							);
                        _ ->
                            skip
                    end,
                    {ok, NewPS, Mon#ets_mon.mid};
                _ ->
                    {error, 4}
            end;

        %% 没钓到鱼，初始化钓鱼的两个数据
        _ ->
            Fish = PS#player_status.fish#status_fish{
                fishing_time = 0,
                fishing_monid = 0
            },
            NewPS = PS#player_status{fish = Fish},
            {ok, NewPS, 0}
    end.

%% 分享队友积分
share_score(PS, CopyId, Score) ->
	case PS#player_status.scene =:= data_fish:get_sceneid() andalso PS#player_status.copy_id =:= CopyId of
		true ->
			LimitUp = data_fish:get_score_limitup(),
			case is_integer(PS#player_status.fish#status_fish.score) andalso 
				PS#player_status.fish#status_fish.score < LimitUp of
				true ->
					AddScore = case PS#player_status.fish#status_fish.score + Score > LimitUp of
						true -> LimitUp - PS#player_status.fish#status_fish.score;
						_ -> Score
					end,

					TmpExp = data_fish:get_exp(PS#player_status.lv, AddScore),
					Exp = private_offline_award(TmpExp),
					LLPT = data_fish:get_llpt(PS#player_status.lv, AddScore),
					%% 多倍奖励处理
					MultiAward = private_get_multi_award_time(PS),
					Exp2 = round(Exp * MultiAward),
					LLPT2 = round(LLPT * MultiAward),
					%% 加到玩家身上
					NewPS = lib_player:add_pt(llpt, PS, LLPT2),
					NewPS2 = lib_player:add_exp(NewPS, Exp2, 0),

					%% 发玩家属性变化通知
					case AddScore > 0 of
						true -> lib_player:send_attribute_change_notify(NewPS2, 2);
						_ -> skip
					end,

                    Fish = NewPS2#player_status.fish#status_fish{
						score = PS#player_status.fish#status_fish.score + AddScore,
						exp = PS#player_status.fish#status_fish.exp + Exp2,
						llpt = PS#player_status.fish#status_fish.llpt + LLPT2
					},

					%% 如果达到满分，则弹出翻牌面板
                    case PS#player_status.fish#status_fish.score < LimitUp andalso Fish#status_fish.score >= LimitUp of
                        true ->
                            {ok, BinData} = pt_331:write(33125, 1),
                            lib_server_send:send_to_sid(PS#player_status.sid, BinData);
                        _ ->
                            skip
                    end,

					NewPS3 = NewPS2#player_status{fish = Fish},

					%% 刷新客户端收益
					refresh_award(NewPS3),

					NewPS3;
				_ ->
					PS
			end;
		_ ->
			PS
	end.

%% 偷鱼
steal_fish(PS, PlayerId) ->
	%% 偷鱼基础判断
	case private_base_check_steal(PS, PlayerId)	of
		{ok, PlayerFish} ->
			%% 判断对方是否有在钓鱼
			case PlayerFish#status_fish.fishing_time > 0 of
				true ->
					Fish = PS#player_status.fish,
					%% 判断偷鱼者的鱼数量是否足够
					case private_get_fish_num(Fish#status_fish.fish_stat, 0) > 0 of
						true ->
							%% 判断被偷鱼者的鱼数量是否足够
							case private_get_fish_num(PlayerFish#status_fish.fish_stat, 0) > 0 of
								true ->
									%% 判断是否已经在偷别人的鱼了，不能重复偷鱼
									case Fish#status_fish.steal_playerid =:= 0 of
										true ->
											NewFish = Fish#status_fish{
												steal_playerid = PlayerId,
												steal_time = util:unixtime()
											},
											{ok,
												PS#player_status{fish = NewFish}
											};
										_ ->
											{error, 9}
									end;
								_ ->
									{error, 8}
							end;
						_ ->
							{error, 7}
					end;
				_ ->
					{error, 11}
			end;
		{error, ErrorCode} ->
			{error, ErrorCode}
	end.

%% 完成偷鱼读条
finish_steal(PS) ->
	Fish = PS#player_status.fish,
	%% 判断是否真的有偷鱼
	case Fish#status_fish.steal_playerid > 0 of	
		true ->
			%% 判断偷鱼时间是否达到
			case Fish#status_fish.steal_time + data_fish:get_steal_cd() =< util:unixtime() of
				true ->
					case lib_player:get_player_info(Fish#status_fish.steal_playerid, fish_data) of
						[PlayerPid, PlayerFish, _, _] ->
							%% 判断被偷玩家是否还在钓鱼
							case PlayerFish#status_fish.fishing_time > 0 of
								%% 偷鱼成功
								true ->
									[FishId, NewFish, NewPlayerFish, Exp, LLPT] = private_steal_successful(PS, Fish, PlayerFish),

									NewPS = case Exp > 0 of
										true ->
											lib_player:add_exp(PS, Exp, 0);
										_ ->
											PS
									end,
									NewPS2 = case LLPT > 0 of
										true ->
											lib_player:add_pt(llpt, PS, LLPT);
										_ ->
											NewPS
									end,
									NewPS3 = NewPS2#player_status{fish = NewFish},

									%% 保存被偷者数据
									gen_server:cast(PlayerPid, {set_data, [{save_fish_status, NewPlayerFish}]}),

									case Exp > 0 orelse LLPT > 0 of
										true ->
											lib_player:send_attribute_change_notify(NewPS3, 2);
										_ ->
											skip
									end,

									case FishId > 0 of
										true ->
											%% 提示对方：好难过，鱼篓中的XXX鱼被偷走一条
											send_msg(Fish#status_fish.steal_playerid, 1, FishId),
											%% 刷新自己的鱼数量
											refresh_award(NewPS3);
										_ ->
											skip
									end,

									%% 如果达到满分，则弹出翻牌面板
		                            LimitUp = data_fish:get_score_limitup(),
		                            case Fish#status_fish.score < LimitUp andalso NewFish#status_fish.score >= LimitUp of
		                                true ->
		                                    {ok, BinData} = pt_331:write(33125, 1),
		                                    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		                                _ ->
		                                    skip
		                            end,

									{ok, NewPS3, FishId};

								%% 对方已经收起鱼篓，偷鱼失败
								_ ->
									%% 提示对方成功守护鱼篓
									send_msg(Fish#status_fish.steal_playerid, 2, 0),
									[NewFish, FishId] = private_steal_fail(Fish),
                                    NewPS = PS#player_status{fish = NewFish},
                                    case FishId > 0 of
                                        true ->
                                            refresh_award(NewPS);
                                        _ ->
                                            skip
                                    end,
									{error, NewPS, FishId}
							end;
						_ ->
							{error, 4}
					end;
				_ ->
					{error, 2}
			end;
		_ ->
			{error, 2}
	end.

%% 获取阶段奖励
get_step_award(PS) ->
	Fish = PS#player_status.fish,
	case length(Fish#status_fish.step_award) < 5 of
		%% 奖励未领取满
		true ->
			%% 统计各种鱼的数量
			NewStat = 
				lists:foldl(fun({Id, Num}, Stat) -> 
					private_count_fish_num(Id, Num, Stat)
				end, [0, 0, 0, 0, 0, 0], Fish#status_fish.fish_stat),

			LevelResult = 
				lists:foldl(fun({RequireStat, Level}, AwardList) -> 
					case private_is_reach_require(RequireStat, NewStat) of
						true ->
							[Level | AwardList];
						_ ->
							AwardList
					end
				end, [], data_fish:get_step_award_data()),

			LevelResult2 = 
				lists:foldl(fun(LV, AwardList2) -> 
					case lists:member(LV, Fish#status_fish.step_award) of
						true ->
							AwardList2; 
						_ ->
							[LV | AwardList2]
					end
				end, [], LevelResult),
			
			case length(LevelResult2) > 0 of
				true ->
					TargetLevel = lists:max(LevelResult2),
					case data_fish:get_step_award(TargetLevel) of
						[] ->
							{error, 2};
						[GoodsId, GoodsNum] ->
							case private_fetch_step_award(PS, GoodsId, GoodsNum, 2) of
								{ok} ->
									NewFish = Fish#status_fish{
										step_award = [TargetLevel | Fish#status_fish.step_award]				 
									},

									{ok, PS#player_status{fish = NewFish}};
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
	end.

%% 翻牌
get_score_award(PS) ->
	case PS#player_status.fish#status_fish.score >= data_fish:get_score_limitup() of
		true ->
			case PS#player_status.fish#status_fish.score_award =:= 0 of
				true ->
					Rand = util:rand(1, 100),
					[[_, _, GoodsTypeId, GoodsNum, Bind]] = 
						lists:filter(fun([Start, End, _, _, _]) -> 
							Rand >= Start andalso Rand =< End
						end, data_fish:get_score_award()),
					case private_fetch_step_award(PS, GoodsTypeId, GoodsNum, Bind) of
						{ok} ->
							NewFish = PS#player_status.fish#status_fish{
								score_award = 1				 
							},

							{ok, PS#player_status{fish = NewFish}, GoodsTypeId, GoodsNum, Bind};
						{error, ErrorCode} ->
							{error, ErrorCode}
					end;
				_ ->
					{error, 3}
			end;
		_ ->
			{error, 2}
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
					data_fish:timer_refresh_time();

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
broadcast(WeekRange, TimeRange) ->
	case get_switch() of
		true ->
			case lists:member(util:get_day_of_week(), WeekRange) of
				true ->
					NowTS = util:unixtime(),
					[BeginTS, EndTS] = private_get_activity_unixtime(TimeRange),
					if
						%% 活动开始1分钟内
						(NowTS >= BeginTS) andalso (NowTS < BeginTS + 60) ->
                            %% 设置需要广播
		    	            mod_daily_dict:set_special_info(fish_send_tv, 0),
                            %% 传闻活动开始
                            case mod_daily_dict:get_special_info(fish_send_tv) of
                                0 ->
                                    lib_chat:send_TV({all}, 1, 2, ["startFishing", 0]),
                                    mod_daily_dict:set_special_info(fish_send_tv, 1);
                                _ ->
                                    skip
                            end,
							%% 广播活动开始
							private_broadcast_begin(EndTS - NowTS);

						%% 在活动开始1分钟后 到 结束时间前2分钟，广播活动开始
						(NowTS >= BeginTS + 60) andalso (NowTS < EndTS - 120) ->
							%% 广播活动开始
							private_broadcast_begin(EndTS - NowTS);

						%% 在结束时间及超过结束时间1分钟内，广播活动结束，让一部分人先退出场景
						(NowTS >= EndTS) andalso (NowTS < EndTS + 60) ->
							%% 广播活动结束
							private_broadcast_end();

						%% 在结束时间1分钟后2分钟内，再发一次活动结束广播
						(NowTS >= EndTS + 60) andalso (NowTS < EndTS + 120) ->
							%% 广播活动结束
							private_broadcast_end(),

							%% 重置回正常的活动时间，避免通过管理后台秘籍开启活动后影响下一次的活动时间
							timer_unite_fish:set_time(data_fish:require_activity_week(), data_fish:require_activity_time());
						true ->
							skip
					end;
				_ ->
					skip
			end;
		_ ->
			skip
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

%% 活动开始前，会初始化好鱼
init_room_boss(RoomId) ->
	mod_scene_agent:apply_call(data_fish:get_sceneid(), lib_fish, init_mon, [RoomId]).

%% 活动结束时，清除掉所有怪
remove_all_mon(RoomId) ->
	SceneId = data_fish:get_sceneid(),
	%% 清除怪物
    lib_mon:clear_scene_mon(SceneId, RoomId, 1).

%% [场景进程调用] 生成怪物
init_mon(RoomId) ->
	SceneId = data_fish:get_sceneid(),

	%% 生成普通怪
	lists:map(fun({Id, X, Y}) -> 
                mod_mon_create:create_mon(Id, SceneId, X, Y, 0, RoomId, 0, [])
	end, data_fish:get_mon_position()),

    FishList = data_fish:get_refresh_boss_position(),

	%% 生成最大boss
	OraList2 = util:list_shuffle(FishList),
	OraList3 = lists:sublist(OraList2, data_fish:get_refresh_boss_num(?FISH_ID_1)),
	lists:map(fun({OraX, OraY}) ->
                mod_mon_create:create_mon(?FISH_ID_1, SceneId, OraX, OraY, 0, RoomId, 0, [])
	end, OraList3),

	%% 生成第二大boss
	PurList2 = util:list_shuffle(FishList),
	PurList3 = lists:sublist(PurList2, data_fish:get_refresh_boss_num(?FISH_ID_2)),
	lists:map(fun({PurX, PurY}) ->
                mod_mon_create:create_mon(?FISH_ID_2, SceneId, PurX, PurY, 0, RoomId, 1, [])
	end, PurList3),
	ok.

%% 大boss被杀死后重新生成
%% ServerType : 1为公共线，0为游戏线
%% CopyId : 房间ID
%% MonId : 怪物ID
create_fish_boss(ServerType, CopyId, MonId) ->
	spawn(fun() -> 
		MonSleep = data_fish:get_refresh_boss_time(MonId),
		timer:sleep(MonSleep * 1000),

		SceneId = data_fish:get_sceneid(),
		case data_fish:get_boss_position(MonId) of
			{X, Y} ->
                lib_mon:sync_create_mon(MonId, SceneId, X, Y, 0, CopyId, 1, [{auto_lv, data_fish:require_lv()}]),
	 			%% 最大鱼发送传闻
	 			case MonId =:= ?FISH_ID_1 of
	 				true ->
	 					lib_chat:send_TV({scene, SceneId, CopyId}, ServerType, 2, ["qicaijinli", 1]);
	 				_ ->
	 					skip
	 			end;
			_ ->
				skip
		end	  
	end).

%% 刷新玩家客户端收益显示
refresh_award(PS) ->
	List = lists:map(fun({Id, Num}) -> 
		<<Id:32, Num:16>>
	end, PS#player_status.fish#status_fish.fish_stat),
	Data = [
		PS#player_status.fish#status_fish.score,
		PS#player_status.fish#status_fish.exp,
		PS#player_status.fish#status_fish.llpt,
		List
	],
	{ok, BinData} = pt_331:write(33119, Data),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData).

%% 发送消息
send_msg(RoleId, Type, FishId) ->
	{ok, BinData} = pt_331:write(33121, [Type, FishId]),
	lib_server_send:send_to_uid(RoleId, BinData).

%% 管理后台秘籍重开钓鱼活动
%% StartH : 开始小时
%% StartM：开始分钟
%% EndH：结束小时
%% EndM：结束分钟
set_service_in_manage(StartH, StartM, EndH, EndM) ->
	WeekRange = data_fish:require_activity_week(),
	ThisDay = util:get_day_of_week(),
	case lists:member(ThisDay, WeekRange) of
		true ->
			timer_unite_fish:set_time(WeekRange, [{StartH, StartM}, {EndH, EndM}]);
		_ ->
			timer_unite_fish:set_time([ThisDay | WeekRange], [{StartH, StartM}, {EndH, EndM}])
	end.

%% 初始化ps缓存数据
private_init_player_status(PS, WeekRange, TimeRange) ->
	Today = util:unixdate(),
	case PS#player_status.fish#status_fish.score == undefined orelse 
		PS#player_status.fish#status_fish.login_day < Today of
		%% 今天没初始化过，需要初始化一次
		true ->
			case db:get_row(io_lib:format(?SQL_FISH_SELECT, [PS#player_status.id])) of
				[_, Score, Exp, LLPT, StealNum, FishStat, StepAward, ScoreAward, DayTime] ->
					%% 数据过时，需要再初始化一次
					case DayTime < Today of
						true ->
							db:execute(io_lib:format(
								?SQL_FISH_UPDATE,
								[0, 0, 0, 0, '[]', '[]', 0, Today, PS#player_status.id]
							)),
							PS#player_status{
								fish = #status_fish{
									score = 0,
									login_day = Today,
									weekrange = WeekRange,
									timerange = TimeRange
								}
							};
						_ ->
							PS#player_status{
								fish = #status_fish{
									score = Score,
									exp = Exp,
									llpt = LLPT,
									steal_num = StealNum,
									fish_stat = util:to_term(FishStat),
									step_award = util:to_term(StepAward),
									score_award = ScoreAward,
									login_day = Today,
									weekrange = WeekRange,
									timerange = TimeRange
								}
							}
					end;

				%% 之前没玩家垂钓，插入新记录
				_ ->
					db:execute(io_lib:format(?SQL_FISH_INSERT, [PS#player_status.id])),
					PS#player_status{
						fish = #status_fish{
							score = 0,
							login_day = Today,
							weekrange = WeekRange,
							timerange = TimeRange
						}
					}
			end;

		_ ->
			Fish = PS#player_status.fish#status_fish{
				fishing_time = 0,
				fishing_monid = 0,
				steal_playerid = 0,
				steal_time = 0
			},
			PS#player_status{fish = Fish}
	end.

%% 奖励多倍奖励
private_get_multi_award_time(PS) ->
    lib_multiple:get_multiple_by_type(8, PS#player_status.all_multiple_data).

%% 格式化鱼数据，增加一只鱼
private_format_fish_stat(Stat, FishId) ->
	[NewStat, NewExist] = 
		lists:foldl(fun({Id, Num}, [List, Exist]) -> 
			case FishId =:= Id of
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
			[{FishId, 1} | NewStat]
	end.

%% 获得收益
%% 返回：[#player_status, 玩家实际获得的积分, 鱼对应的积分]
private_get_award(PS, FishId) ->
	Fish = PS#player_status.fish,
	Score = data_fish:get_fish_score_by_id(FishId),
	ScoreLimit = data_fish:get_score_limitup(),
	case Fish#status_fish.score >= ScoreLimit of
		%% 积分已满，不处理
		true ->
			NewFish = PS#player_status.fish#status_fish{
				fishing_time = 0,
				fishing_monid = 0,
                fish_stat = private_format_fish_stat(Fish#status_fish.fish_stat, FishId)
			},
			[PS#player_status{fish = NewFish}, 0, Score];
		_ ->
			%% 真正可获得的积分
			AddScore = case Fish#status_fish.score + Score > ScoreLimit of
				true ->
					ScoreLimit - Fish#status_fish.score;
				_ ->
					Score
			end,

			TmpExp = data_fish:get_exp(PS#player_status.lv, AddScore),
			Exp = private_offline_award(TmpExp),
			
			LLPT = data_fish:get_llpt(PS#player_status.lv, AddScore),
			%% 多倍奖励处理
			MultiAward = private_get_multi_award_time(PS),
			Exp2 = round(Exp * MultiAward),
			LLPT2 = round(LLPT * MultiAward),
			%% 加到玩家身上
			NewPS = lib_player:add_pt(llpt, PS, LLPT2),
			NewPS2 = lib_player:add_exp(NewPS, Exp2, 0),

			NewFish = Fish#status_fish{
				score = Fish#status_fish.score + AddScore,
				exp = Fish#status_fish.exp + Exp2,
				llpt = Fish#status_fish.llpt + LLPT2,
				fishing_time = 0,
				fishing_monid = 0,
				fish_stat = private_format_fish_stat(Fish#status_fish.fish_stat, FishId)
			},

			[NewPS2#player_status{fish = NewFish}, AddScore, Score]
	end.

%% 偷鱼：基础检查
%% PlayerId : 被偷玩家id
private_base_check_steal(PS, PlayerId) ->
	case PS#player_status.id /= PlayerId of
		true ->
			SceneId = data_fish:get_sceneid(),
			CopyId = PS#player_status.copy_id,
			case PS#player_status.scene =:= SceneId of
				true ->
					case lib_player:get_player_info(PlayerId, fish_data) of
						[_, PlayerFish, PlayerSceneId, PlayerCopyId] ->
							case PlayerFish#status_fish.score /= undefined andalso
								PlayerSceneId =:= SceneId andalso 
								PlayerCopyId =:= CopyId	of
								%% 对方玩家也在同一场景中
								true ->
									case PlayerFish#status_fish.steal_num < data_fish:get_stealing_num() of
										true ->
                                            %% 同个队伍不能偷鱼
                                            case PS#player_status.pid_team > 0 of
                                                true ->
                                                    Members = lib_team:get_mb_ids(PS#player_status.pid_team),
                                                    case lists:member(PlayerId, Members) of
                                                        true ->
	                                                        {error, 12};
                                                        _ ->
                                                            {ok, PlayerFish}
                                                    end;
                                                _ ->
                                                    {ok, PlayerFish}
                                            end;
										_ ->
											{error, 10}
									end;
								_ ->
									{error, 6}
							end;
						_ ->
							{error, 4}
					end;
				_ ->
					{error, 5}
			end;
		_ ->
			{error, 3}
	end.

%% 偷鱼成功，处理偷者和被偷者的鱼和积分
private_steal_successful(PS, MyFish, PlayerFish) ->
    MyLevel = PS#player_status.lv,
	%% 从被偷者身上取出一条鱼，并可能减少身上的积分
	[FishId, NewPlayerFish] = private_be_stealed(PlayerFish),

	[LastMyStat, LastMyScore, LastMyExp, LastMyLLPT] =
	case FishId > 0 of
		true ->
			%% 偷者身上增加一条鱼，可能增加身上的积分
			[NewMyStat, NewMyExist] = 
				lists:foldl(fun({Id, Num}, [MyStat, MyExist]) -> 
					case Id =:= FishId of
						true ->
							[[{Id, Num + 1} | MyStat], MyExist + 1];
						_ ->
							[[{Id, Num} | MyStat], MyExist]
					end
				end, [[], 0], MyFish#status_fish.fish_stat),

			NewMyStat2 = case NewMyExist > 0 of
				true ->
					NewMyStat;
				_ ->
					[{FishId, 1} | NewMyStat]
			end,
			
			[NewMyScore, MyExp, MyLLPT] = 
				case MyFish#status_fish.score >= data_fish:get_score_limitup() of
					true ->
						[MyFish#status_fish.score, 0, 0];
					_ ->
						LimitUp = data_fish:get_score_limitup(),
						FishScore = data_fish:get_fish_score_by_id(FishId),
						AddScore = case MyFish#status_fish.score + FishScore > LimitUp of
							true -> 
								LimitUp - MyFish#status_fish.score;
							_ ->
								FishScore
						end,
						TmpExp1 = data_fish:get_exp(MyLevel, AddScore),
						TmpExp = private_offline_award(TmpExp1),

						TmpLLPT = data_fish:get_llpt(MyLevel, AddScore),
						MutilAward = private_get_multi_award_time(PS),
						Exp = round(TmpExp * MutilAward),
						LLPT = round(TmpLLPT * MutilAward),
						[MyFish#status_fish.score + AddScore, Exp, LLPT]
				end,
			[NewMyStat2, NewMyScore, MyExp, MyLLPT];
		_ ->
			[MyFish#status_fish.fish_stat, MyFish#status_fish.score, 0, 0]
	end,

	NewMyFish = MyFish#status_fish{
		score = LastMyScore,
		fish_stat = LastMyStat,
        steal_playerid = 0,
        steal_time = 0
	},
	[FishId, NewMyFish, NewPlayerFish, LastMyExp, LastMyLLPT].

%% 偷鱼失败，处理偷者的鱼和积分
%% 返回：[#status_fish, 损失的鱼id或0]
private_steal_fail(StatusFish) ->
	List = [Id || {Id, _} <- StatusFish#status_fish.fish_stat],
	case length(List) > 0 of
		true ->
			FishId = util:list_rand(List),
			NewList = 
				lists:foldl(fun({Id2, Num2}, TmpStat) -> 
					case Id2 == FishId of
						true ->
							case Num2 =< 1 of
								true ->
									TmpStat;
								_ ->
									[{Id2, Num2 - 1} | TmpStat]
							end;
						_ ->
							[{Id2, Num2} | TmpStat]
					end
				end, [], StatusFish#status_fish.fish_stat),
			NewStatusFish = StatusFish#status_fish{fish_stat = NewList},
			[NewStatusFish#status_fish{steal_playerid=0, steal_time=0}, FishId];
		_ ->
            [StatusFish#status_fish{steal_playerid=0, steal_time=0}, 0]
	end.

%% 被偷者，随机扣除一条鱼，并有可能减少积分
%% 返回：[被扣的鱼id, #status_fish]
private_be_stealed(StatusFish) ->
	List = [Id || {Id, _} <- StatusFish#status_fish.fish_stat],
	case length(List) > 0 of
		true ->
			FishId = util:list_rand(List),
			NewList = 
				lists:foldl(fun({Id2, Num2}, TmpStat) -> 
					case Id2 == FishId of
						true ->
							case Num2 =< 1 of
								true ->
									TmpStat;
								_ ->
									[{Id2, Num2 - 1} | TmpStat]
							end;
						_ ->
							[{Id2, Num2} | TmpStat]
					end
				end, [], StatusFish#status_fish.fish_stat),
			NewStatusFish = 
				case StatusFish#status_fish.score >= data_fish:get_score_limitup() of
					true ->
						StatusFish#status_fish{
							steal_num = StatusFish#status_fish.steal_num + 1,
							fish_stat = NewList
						};
					_ ->
						Score = StatusFish#status_fish.score - data_fish:get_fish_score_by_id(FishId),
						NewScore = case Score < 0 of
							true -> 0;
							_ -> Score
						end,

						StatusFish#status_fish{
							score = NewScore,
							steal_num = StatusFish#status_fish.steal_num + 1,
							fish_stat = NewList
						}
				end,
			[FishId, NewStatusFish];
		_ ->
			[0, StatusFish]
	end.

%% 取出活动时间
private_get_activity_unixtime([{StartH, StartM}, {EndH, EndM}]) ->
	TodayTS = util:unixdate(),
	BeginTS = TodayTS + StartH * 3600 + StartM * 60,
	EndTS = TodayTS + EndH * 3600 + EndM * 60,
	[BeginTS, EndTS].

%% 广播活动开始
%% 参数：Second	倒计时秒数
private_broadcast_begin(Second) ->
	{ok, BinData} = pt_331:write(33140, Second),
	lib_unite_send:send_to_all(data_fish:require_lv(), 100, BinData).

%% 广播活动结束
private_broadcast_end() ->
	{ok, BinData} = pt_331:write(33141, 1),
	lib_unite_send:send_to_all(data_fish:require_lv(), 100, BinData).

%% 从定时器获得活动开始周期及房间数据
%% 返回：[WeekRange, TimeRange, RoomList]
private_get_data_from_timer() ->
	mod_fish:get_data().

%% 检查指定房间人数是否满了
private_is_room_full(_RoomId, _RoomList) ->
	false.

%% 判断怪物存不存在
private_is_mon_exist(PS, MonId) ->
    case lib_mon:get_scene_mon_by_ids(PS#player_status.scene, [MonId], all) of
		[Fish] when is_record(Fish, ets_mon), Fish#ets_mon.hp > 0 -> 
			%% 判断与鱼的位置是否过远
			case abs(PS#player_status.x - Fish#ets_mon.x) =< 5 andalso abs(PS#player_status.y - Fish#ets_mon.y) =< 5 of
				false -> false;
				true -> true
			end;
		_ ->
			false
	end.

%% 将分享到队友的积分发到玩家进程处理
private_share_score(RoleId, CopyId, Score) ->
	case misc:get_player_process(RoleId) of
		Pid when is_pid(Pid) ->
			catch gen_server:cast(Pid, {share_fish_score, [CopyId, Score]});
		_ ->
			skip
	end.

%% 各种鱼的数量是否都达到要求
private_is_reach_require(Require, Stat) ->
    [A1, A2, A3, A4, A5, A6] = Stat,
    [B1, B2, B3, B4, B5, B6] = Require,
    A1>=B1 andalso A2>=B2 andalso A3>=B3 andalso A4>=B4 andalso A5>=B5 andalso A6>=B6.

%% 统计各种鱼的数量
private_count_fish_num(10041, Num, [V1, V2, V3, V4, V5, V6]) -> [V1 + Num, V2, V3, V4, V5, V6];
private_count_fish_num(10042, Num, [V1, V2, V3, V4, V5, V6]) -> [V1, V2 + Num, V3, V4, V5, V6];
private_count_fish_num(10043, Num, [V1, V2, V3, V4, V5, V6]) -> [V1, V2, V3 + Num, V4, V5, V6];
private_count_fish_num(10044, Num, [V1, V2, V3, V4, V5, V6]) -> [V1, V2, V3, V4 + Num, V5, V6];
private_count_fish_num(10045, Num, [V1, V2, V3, V4, V5, V6]) -> [V1, V2, V3, V4, V5 + Num, V6];
private_count_fish_num(10046, Num, [V1, V2, V3, V4, V5, V6]) -> [V1, V2, V3, V4, V5, V6 + Num].

%% 取得鱼的数量
private_get_fish_num([], Num) -> Num;
private_get_fish_num([{_, FishNum} | T], Num) -> 
	private_get_fish_num(T, FishNum + Num).

%% 三职业可获得积分共享比例
private_is_three_career(Members) ->
 	L = [R#mb.career || R <- Members],
 	Result = [lists:member(N, L) || N <- [1,2,3]],
 	case Result =:= [true, true, true] of
 		true -> data_fish:team_share_rate();
 		_ -> 1
 	end.

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

%% 下线经验奖励
private_offline_award(Award) ->
	case lib_off_line:activity_time() of
		true -> round(Award * (1 + 0.2));
		_ -> Award
	end.
