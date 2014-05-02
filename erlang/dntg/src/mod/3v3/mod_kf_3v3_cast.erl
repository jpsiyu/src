%%%--------------------------------------
%%% @Module : mod_kf_3v3_cast
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3主要逻辑处理进程
%%%--------------------------------------

-module(mod_kf_3v3_cast).
-include("kf_3v3.hrl").
-export([handle_cast/2]).

%% 挂机
handle_cast({onhook, Platform, ServerNum, Id}, State) ->
	PlayerDictKey = [Platform, ServerNum, Id],
	case dict:is_key(PlayerDictKey, State#kf_3v3_state.player_dict) of
		true ->
			Player = dict:fetch(PlayerDictKey, State#kf_3v3_state.player_dict),
			case Player#bd_3v3_player.status =:= ?KF_PLAYER_PK andalso is_pid(Player#bd_3v3_player.pk_pid) of
				true ->
					mod_kf_3v3_pk:onhook(Player#bd_3v3_player.pk_pid, Platform, ServerNum, Id);
				_ ->
					skip
			end;
		_ ->
			skip
	end,
	{noreply, State};

%% 举报
handle_cast({report, FromPlatform, FromServerNum, FromId, ToPlatform, ToServerNum, ToId}, State) ->
	PlayerDictKey = [FromPlatform, FromServerNum, FromId],
	case dict:is_key(PlayerDictKey, State#kf_3v3_state.player_dict) of
		true ->
			Player = dict:fetch(PlayerDictKey, State#kf_3v3_state.player_dict),
			case Player#bd_3v3_player.status =:= ?KF_PLAYER_PK andalso is_pid(Player#bd_3v3_player.pk_pid) of
				true ->
					mod_kf_3v3_pk:report(Player#bd_3v3_player.pk_pid, FromPlatform, FromServerNum, FromId, ToPlatform, ToServerNum, ToId);
				_ ->
					skip
			end;
		_ ->
			skip
	end,
	{noreply, State};

%% 进入准备区
handle_cast({enter_prepare, Args}, State) ->
	[USInfo, Node, CombatPower, MaxCombatPower, Pt, _Score, PkNum, Report] = Args,
	[Platform, ServerNum, Id, Name, Lv, Realm, Career, Sex, Image, VipLv] = USInfo,
	case State#kf_3v3_state.status =:= ?KF_3V3_STATUS_ACTION of
		true ->
			%% 玩家列表索引下标
			PlayerDictKey = [Platform, ServerNum, Id],
			[X, Y] = data_kf_3v3:get_position1(),

			case dict:is_key(PlayerDictKey, State#kf_3v3_state.player_dict) of
				%% 当场活动，玩家之前有进入过
				true ->
					Player = dict:fetch(PlayerDictKey, State#kf_3v3_state.player_dict),
					NewMaxCombatPower = max(Player#bd_3v3_player.max_combat_power, MaxCombatPower),
					NewPlayer = Player#bd_3v3_player{
						lv = Lv,
						vip_lv = VipLv,
						sex = Sex,
						image = Image,
						combat_power = CombatPower,
						max_combat_power = max(CombatPower, NewMaxCombatPower),
						status = 1,
						leave = 0,
						team_id = 0,
						group = 0
					},
					NewState = State#kf_3v3_state{
						player_dict = dict:store(PlayerDictKey, NewPlayer, State#kf_3v3_state.player_dict)
					};

				%% 玩家第一次进入准备场景
				_ ->
					RoomMaxNum = data_kf_3v3:get_config(room_max_num),
					%% 人数达到上限后，新建副本
					if
						State#kf_3v3_state.room_num < RoomMaxNum ->
							RoomNo = State#kf_3v3_state.room_no,
							RoomNum = State#kf_3v3_state.room_num + 1;
						%% 满员了，新建房间
						true ->
							RoomNo = State#kf_3v3_state.room_no + 1,
							RoomNum = 1
					end,

					%% 构建玩家记录
					NewPlayer = #bd_3v3_player{
						platform = Platform,
						server_num = ServerNum,										   
						node = Node,								   
						id = Id,
						name = Name,
						country = Realm,
						sex = Sex,
						career = Career,
						image = Image,
						lv = Lv,
						vip_lv = VipLv,
						combat_power = CombatPower,
						max_combat_power = max(CombatPower, MaxCombatPower),
						copy_id = RoomNo,
						player_pt = Pt,
						pk_num = PkNum,
						total_report = Report
					},
					NewState = State#kf_3v3_state{
						player_dict = dict:store(PlayerDictKey, NewPlayer, State#kf_3v3_state.player_dict),
						room_no = RoomNo,
						room_num = RoomNum
					}
			end,

			%% 提示进入准备区成功
			{ok, BinData} = pt_484:write(48402, [1]),
			mod_clusters_center:apply_cast(Node, lib_unite_send, cluster_to_uid, [
				Id, BinData
			]),

			%% 排队进入准备区
			mod_clusters_center:apply_cast(Node, lib_scene, player_change_scene_queue, [
				Id, data_kf_3v3:get_config(scene_id1), NewPlayer#bd_3v3_player.copy_id, X, Y, 0
			]),

			%% 刷新准备区右手边数据
			LeftTime = State#kf_3v3_state.end_time - util:unixtime(),
			lib_kf_3v3:refresh_right_info(State#kf_3v3_state.status, State#kf_3v3_state.loop, LeftTime, NewPlayer),

			{noreply, NewState};

		%% 不在活动时间内, 重新刷新状态到每个游戏节点
		_ ->
			mod_clusters_center:apply_to_all_node(mod_kf_3v3_state, set_status, [State#kf_3v3_state.status]),

			%% 告诉玩家进入准备区失败
			{ok, BinData} = pt_484:write(48402, [5]),
			mod_clusters_center:apply_cast(Node, lib_unite_send, cluster_to_uid, [Id, BinData]),

			{noreply, State}
	end;

%% 退出准备区
handle_cast({exit_prepare, Platform, ServerNum, Id}, State) ->
	PlayerDictKey = [Platform, ServerNum, Id],
	case dict:is_key(PlayerDictKey, State#kf_3v3_state.player_dict) of
		true ->
			Player = dict:fetch(PlayerDictKey, State#kf_3v3_state.player_dict),
			%% 只有没报名报状态，才可以退出3v3
			case Player#bd_3v3_player.status =:= ?KF_PLAYER_IN_PREPARE of
				true ->
					NewPlayer = Player#bd_3v3_player{
						status = 0,
						leave = 0
					},
					NewState = State#kf_3v3_state{
						player_dict = dict:store(PlayerDictKey, NewPlayer, State#kf_3v3_state.player_dict),
						single_dict = dict:erase(PlayerDictKey, State#kf_3v3_state.single_dict)					  
					},

					{ok, BinData} = pt_484:write(48403, 1),
					mod_clusters_center:apply_cast(Player#bd_3v3_player.node, lib_unite_send, cluster_to_uid, [Id, BinData]),

					%% 排队离开准备区
					[SceneId, X, Y] = data_kf_3v3:get_config(leave_scene),
					mod_clusters_center:apply_cast(Player#bd_3v3_player.node, lib_scene, player_change_scene_queue, [
						Id, SceneId, 0, X, Y, [{soul_pk_change, 0}]
					]),

					{noreply, NewState};
				_ ->
					{ok, BinData} = pt_484:write(48403, 3),
					mod_clusters_center:apply_cast(Player#bd_3v3_player.node, lib_unite_send, cluster_to_uid, [Id, BinData]),
					{noreply, State}
			end;
		_ ->
			{noreply, State}
	end;

%% 报名：单个玩家报名
handle_cast({sign_up_single, Node, Platform, ServerNum, Id}, State) ->
	PlayerDictKey = [Platform, ServerNum, Id],
	case State#kf_3v3_state.status =:= ?KF_3V3_STATUS_ACTION of
		true ->
			NowTime = lib_kf_3v3:get_second_of_day(),
			case State#kf_3v3_state.end_time > NowTime of
				true ->
					case dict:is_key(PlayerDictKey, State#kf_3v3_state.player_dict) of
						true ->
							Player = dict:fetch(PlayerDictKey, State#kf_3v3_state.player_dict),
							case Player#bd_3v3_player.status > ?KF_PLAYER_IN_PREPARE of
								%% 已经报过名
								true ->
									NewState = State,
									Reply = [10, 0];
								_ ->
									%% 判断是否有CD限制
									UnixTime = util:unixtime(),
									case UnixTime >= Player#bd_3v3_player.cd_end_time of
										true ->
											%% 判断是否被举报次数超过指定数字，是的话不允许单独报名
											case Player#bd_3v3_player.total_report >= data_kf_3v3:get_config(report_deny_single_signup) of
												true ->
													NewState = State,
													Reply = [15, 0];
												_ ->
													NewPlayer = Player#bd_3v3_player{status = ?KF_PLAYER_SINGLE},

													%% 计算队友匹配参数
													SortValue = data_kf_3v3:count_member_param(
														Player#bd_3v3_player.max_combat_power,
														Player#bd_3v3_player.lv,
														Player#bd_3v3_player.pk_num,
														Player#bd_3v3_player.pk_win_num,
														0
													),
													NewState = State#kf_3v3_state{
														player_dict = dict:store(PlayerDictKey, NewPlayer, State#kf_3v3_state.player_dict),
														single_dict = dict:store(PlayerDictKey, [0, SortValue], State#kf_3v3_state.single_dict)	   
													},
													Reply = [1, 0]
											end;
										_ ->
											NewState = State,
											Reply = [3, Player#bd_3v3_player.cd_end_time - UnixTime]
									end
							end;
						_ ->
							NewState = State,
							Reply = [2, 0]
					end;
				_ ->
					NewState = State,
					Reply = [5, 0]
			end;
		_ ->
			NewState = State,
			Reply = [5, 0]
	end,

	{ok, BinData} = pt_484:write(48410, Reply),
	mod_clusters_center:apply_cast(Node, lib_unite_send, cluster_to_uid, [Id, BinData]),
    {noreply, NewState};

%% 报名：队伍报名
handle_cast({sign_up_team, Node, Platform, ServerNum, Id, MemberIds}, State) ->
	case State#kf_3v3_state.status =:= ?KF_3V3_STATUS_ACTION of
		true ->
			NowTime = lib_kf_3v3:get_second_of_day(),
			case State#kf_3v3_state.end_time > NowTime of
				true ->
					%% 取出成员，要求必须在准备场景，且状态为1
					CheckInList = [[Platform, ServerNum, MemId] || MemId <- MemberIds],
					UnixTime = util:unixtime(),
					[PlayerList, Error] = 
					lists:foldl(fun(PlayerDictKey, [TmpPlayerList, TmpError]) -> 
						case lib_kf_3v3:get_player_from_dict(PlayerDictKey, State#kf_3v3_state.player_dict)	of
							false ->
								[TmpPlayerList, 11];
							Player ->
								case Player#bd_3v3_player.status =:= ?KF_PLAYER_IN_PREPARE of
									true ->
										case Player#bd_3v3_player.cd_end_time =< UnixTime of
											true ->
												[[Player | TmpPlayerList], TmpError];
											_ ->
												[TmpPlayerList, 14]
										end;
									_ ->
										[TmpPlayerList, 11]
								end
						end
					end, [[], 1], CheckInList),

					case length(PlayerList) /= data_kf_3v3:get_config(team_person) of
						true ->
							NewState = State,
							Reply = [Error, 0];
						_ ->
							NewState = lib_kf_3v3:make_one_team(PlayerList, State),
							Reply = [1, 0]
					end;
				_ ->
					NewState = State,
					Reply = [5, 0]
			end;
		_ ->
			NewState = State,
			Reply = [5, 0]
	end,
	{ok, BinData} = pt_484:write(48410, Reply),
	mod_clusters_center:apply_cast(Node, lib_unite_send, cluster_to_uid, [Id, BinData]),

    {noreply, NewState};

%% 开始匹配逻辑
%% 流程：先匹配队友，完成之后，新起进程，休眠N秒后匹配队手
handle_cast({start_matching}, State) ->
	LastState = 
	case State#kf_3v3_state.status =:= ?KF_3V3_STATUS_ACTION of
		true -> 
			NowTime = lib_kf_3v3:get_second_of_day(),
			case State#kf_3v3_state.end_time > NowTime of
				true ->
					%% 开始匹配队友
					NewState = lib_kf_3v3:match_single_list(State),

					spawn(fun() ->
						%% 1秒后开始匹配队伍
						timer:sleep(1000),
						mod_kf_3v3:team_matching()
					end),

					NewState;
				_ ->
					State
			end;
		_ ->
			State
	end,
	{noreply, LastState};

%% 匹配队伍
handle_cast({team_matching}, State) ->
	List = dict:to_list(State#kf_3v3_state.team_dict),
	case List of
		[] ->
			NewState = State;
		_ ->
			%% 排序队伍报名列表，按参数倒序
			F = fun({_TeamNo1, [_Num1, Param1, _Players1]}, {_TeamNo2, [_Num2, Param2, _Players2]}) ->
				Param1 >= Param2
			end,
			SortList = lists:sort(F, List),
			NewState = lib_kf_3v3:match_team_list(SortList, State, 0)
	end,

	spawn(fun() -> 
		%% 休眠指定时间后重新发起匹配流程
		SleepTime = data_kf_3v3:get_config(matching_time),
		timer:sleep(SleepTime * 1000),
		mod_kf_3v3:start_matching()
	end),

	{noreply, NewState};

%% 刷新或掉线处理
handle_cast({when_logout, Platform, ServerNum, Id}, State) ->
	PlayerDictKey = [Platform, ServerNum, Id],
	LastState = 
	case dict:is_key(PlayerDictKey, State#kf_3v3_state.player_dict) of
		true ->
			Player = dict:fetch(PlayerDictKey, State#kf_3v3_state.player_dict),
			if
				%% 只是在准备区
				Player#bd_3v3_player.status =:= ?KF_PLAYER_IN_PREPARE ->
					NewPlayer = Player#bd_3v3_player{
						status = 0
					},
					State#kf_3v3_state{
						player_dict = dict:store(PlayerDictKey, NewPlayer, State#kf_3v3_state.player_dict)
					};

				true ->
					%% 报了名之后掉线，需要增加cd时间
					CdEndTime = case Player#bd_3v3_player.cd_end_time > 0 of
						true -> Player#bd_3v3_player.cd_end_time;
						_ -> util:unixtime() + data_kf_3v3:get_config(cd_time)
					end,

					State2 = State#kf_3v3_state{
						single_dict = dict:erase(PlayerDictKey, State#kf_3v3_state.single_dict)
					},

					%% 设置玩家新状态
					NewPlayer = Player#bd_3v3_player{
						status = 0,
						leave = 1,
						cd_end_time = CdEndTime
					},

					%% 设置pk进程中的玩家为离开状态
					case Player#bd_3v3_player.status =:= ?KF_PLAYER_PK andalso is_pid(Player#bd_3v3_player.pk_pid) of
						true ->
							mod_kf_3v3_pk:when_logout(Player#bd_3v3_player.pk_pid, Platform, ServerNum, Id);
						_ ->
							skip
					end,

					State2#kf_3v3_state{
						player_dict = dict:store(PlayerDictKey, NewPlayer, State2#kf_3v3_state.player_dict)
					}

					%% 刷新左边组队面板
%% 					Room = dict:fetch(Player#bd_3v3_player.room_id, State#kf_3v3_state.room_dict),
%% 					PlayerListA = [lib_kf_3v3:get_player_from_dict(PlayerKeyA, State3#kf_3v3_state.player_dict) || PlayerKeyA <- Room#bd_3v3_room.players_a],
%% 					PlayerListB = [lib_kf_3v3:get_player_from_dict(PlayerKeyB, State3#kf_3v3_state.player_dict) || PlayerKeyB <- Room#bd_3v3_room.players_b],
%% 					lib_kf_3v3_pk:send_partner_info(PlayerListA, PlayerListB),
			end;
		_ ->
			State
	end,
	{noreply, LastState};

%% 在战斗场景中被杀死
handle_cast({when_kill, KillerPlatform, KillerServerNum, KillerId, DiePlatform, DieServerNum, DieId, HelpList}, State) ->
	PlayerDictKey = [KillerPlatform, KillerServerNum, KillerId],
	case dict:is_key(PlayerDictKey, State#kf_3v3_state.player_dict) of
		true ->
			Player = dict:fetch(PlayerDictKey, State#kf_3v3_state.player_dict),
			case Player#bd_3v3_player.status =:= ?KF_PLAYER_PK andalso is_pid(Player#bd_3v3_player.pk_pid) of
				true ->
					mod_kf_3v3_pk:when_kill(Player#bd_3v3_player.pk_pid, KillerPlatform, KillerServerNum, KillerId, DiePlatform, DieServerNum, DieId, HelpList);
				_ ->
					skip
			end;
		_ ->
			skip
	end,
	{noreply, State};

%% 跨服节点开启3v3活动
%% @param Loop		当天第几场活动
%% @param StartTime	活动开始时间
%% @param EndTime	活动结束时间
%% @param PkTime	每场战斗耗时(分钟)
handle_cast({open_3v3, Loop, StartTime, EndTime, PkTime}, _State) ->
	NewState = #kf_3v3_state{
		loop = Loop,
		status = ?KF_3V3_STATUS_ACTION,
		start_time = StartTime,
		end_time = EndTime,
		pk_time = PkTime
	},

	%% 清除所有对阵日志
	mod_kf_3v3_helper:clear_pk_log(),

	spawn(fun() -> 
		%% 开始匹配
		SleepTime = data_kf_3v3:get_config(matching_delay),
		timer:sleep(SleepTime * 1000),
		mod_kf_3v3:start_matching()
	end),

	{noreply, NewState};

%% 按照时间停止活动，只是禁止玩家进入准备区，和报名
handle_cast({stop_3v3}, State) ->
	spawn(fun() ->
		%% 结束后等待pk时间加1分钟后，正式结算整场比赛数据
		NowTime = lib_kf_3v3:get_second_of_day(),
		SleepTime = State#kf_3v3_state.end_time + State#kf_3v3_state.pk_time + 60 - NowTime,
				timer:sleep(SleepTime * 1000),
		mod_kf_3v3:end_3v3()
	end),
	NewState = State#kf_3v3_state{
		status = ?KF_3V3_STATUS_STOP					  
	},
	{noreply, NewState};

%% 活动正式结束，开始结算整场活动奖励
handle_cast({end_3v3}, State) ->
	PlayerDictList = dict:to_list(State#kf_3v3_state.player_dict),

	spawn(fun() ->
		%% 循环每个玩家进行数据处理
		lists:foreach(fun({_K, Player}) -> 
			%% 发送活动结束协议
			{ok, BinData} = pt_484:write(48409, []),
			mod_clusters_center:apply_cast(Player#bd_3v3_player.node, lib_unite_send, cluster_to_uid, [
				Player#bd_3v3_player.id, BinData
			]),
			%% 将声望,战斗次数,成为mvp次数入库
			mod_clusters_center:apply_cast(Player#bd_3v3_player.node, lib_kf_3v3, update_player_kf3v3_info, [
				Player#bd_3v3_player.id,
				[{kf_3v3, [
					Player#bd_3v3_player.pt,
					Player#bd_3v3_player.pk_win_num + Player#bd_3v3_player.pk_lose_num,
					Player#bd_3v3_player.pk_win_num,
					Player#bd_3v3_player.mvp_num,
					Player#bd_3v3_player.goods_num,
					Player#bd_3v3_player.score,
					Player#bd_3v3_player.total_report
				]}]
			]),

			%% 将还没退出准备区的玩家传送到长安
			[SceneId, X, Y] = data_kf_3v3:get_config(leave_scene),
			case Player#bd_3v3_player.status > ?KF_PLAYER_NOT_IN_PREPARE of
				true ->
					mod_clusters_center:apply_cast(Player#bd_3v3_player.node, lib_scene, player_change_scene_queue, [
						Player#bd_3v3_player.id, SceneId, 0, X, Y, [{group, 0}, {soul_pk_change, 0}]
					]);
				_ ->
					skip
			end,

			spawn(fun() -> 
				%% 更新周榜数据表
				mod_rank_cls:update_3v3_rank_user([Player])			  
			end)
		end, PlayerDictList),

		spawn(fun() -> 
			%% 将mvp榜数据发到各游戏节点
			timer:sleep(8 * 1000),
			mod_rank_cls:broadcast_kf_3v3_rank()
		end)
	end),

	spawn(fun() -> 
		%% 发送勋章奖励
		lib_kf_3v3:mail_award(PlayerDictList)
	end),

	spawn(fun() ->
		%% 清理场景
		PrepareSceneId = data_kf_3v3:get_config(scene_id1),
		ClearSceneIds = [PrepareSceneId] ++ data_kf_3v3:get_config(scene_pk_ids),
		lists:foreach(fun(PkSceneId) -> 
			spawn(fun() -> 
				mod_scene_init:clear_scene(PkSceneId)
			end)
		end, ClearSceneIds)  
	end),

	%% 清除整场活动数据
	NewState = State#kf_3v3_state{
		status = ?KF_3V3_STATUS_STOP,
		player_dict = dict:new(),
		single_dict = dict:new(),
		team_dict = dict:new()
	},

	{noreply, NewState};

%% 神坛被占领
handle_cast({mon_die, Platform, ServerNum, Id, MonId}, State) ->
	PlayerDictKey = [Platform, ServerNum, Id],
	case dict:is_key(PlayerDictKey, State#kf_3v3_state.player_dict) of
		true ->
			Player = dict:fetch(PlayerDictKey, State#kf_3v3_state.player_dict),
			case Player#bd_3v3_player.status =:= ?KF_PLAYER_PK andalso is_pid(Player#bd_3v3_player.pk_pid) of
				true ->
					mod_kf_3v3_pk:mon_die(Player#bd_3v3_player.pk_pid, Platform, ServerNum, Id, MonId);
				_ ->
					skip
			end;
		_ ->
			skip
	end,
	{noreply, State};

%% 技能被使用
handle_cast({use_skill, Platform, ServerNum, Id, MonId}, State) ->
	PlayerDictKey = [Platform, ServerNum, Id],
	case dict:is_key(PlayerDictKey, State#kf_3v3_state.player_dict) of
		true ->
			Player = dict:fetch(PlayerDictKey, State#kf_3v3_state.player_dict),
			case Player#bd_3v3_player.status =:= ?KF_PLAYER_PK andalso is_pid(Player#bd_3v3_player.pk_pid) of
				true ->
					mod_kf_3v3_pk:use_skill(Player#bd_3v3_player.pk_pid, Platform, ServerNum, Id, MonId);
				_ ->
					skip
			end;
		_ ->
			skip
	end,
	{noreply, State};

%% 获取积分列表
handle_cast({get_score_rank, Platform, ServerNum, Node, Id}, State) ->
	mod_kf_3v3_helper:get_score_rank(Platform, ServerNum, Node, Id, State),
	{noreply, State};

%% 设置活动状态
handle_cast({set_status, Status}, State) ->
	{noreply, State#kf_3v3_state{status = Status}};

%% 结束pk，结算收益，更新玩家数据
handle_cast({end_pk, _PkState, PlayerListA, PlayerListB}, State) ->
	%% 更新两个队伍的玩家数据
	[NewState1, PlayerList3A] = lists:foldl(fun lib_kf_3v3:update_player_after_pk/2, [State, []], PlayerListA),
	[NewState2, PlayerList3B] = lists:foldl(fun lib_kf_3v3:update_player_after_pk/2, [NewState1, []], PlayerListB),

	%% 玩家战斗完成后刷新准备区右手边数据
	spawn(fun() -> 
		LeftTime = NewState2#kf_3v3_state.end_time - lib_kf_3v3:get_second_of_day(),
		case LeftTime > 0 of
			true ->
				[lib_kf_3v3:refresh_right_info(1, 1, LeftTime, RePlayerA) || RePlayerA <- PlayerList3A],
				[lib_kf_3v3:refresh_right_info(1, 1, LeftTime, RePlayerB) || RePlayerB <- PlayerList3B];
			_ ->
				skip
		end
	end),

	{noreply, NewState2};

handle_cast(_Msg, State) ->
    {noreply, State}.
