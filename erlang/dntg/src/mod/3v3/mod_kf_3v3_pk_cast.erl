%%%--------------------------------------
%%% @Module : mod_kf_3v3_pk_cast
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3pk进程
%%%--------------------------------------

-module(mod_kf_3v3_pk_cast).
-include("kf_3v3.hrl").
-compile(export_all).

handle_cast({onhook, Platform, ServerNum, Id}, State) ->
	PlayerDictKey = [Platform, ServerNum, Id],
	OnhookPlayer = dict:fetch(PlayerDictKey, State#pk_state.player_dict),
	[OccupyNum, KillNum, HelpNum, DieNum] = data_kf_3v3:get_config(onhook_match),
	Result =
		(OnhookPlayer#bd_3v3_player.occupy_num < OccupyNum) andalso 
		(OnhookPlayer#bd_3v3_player.kill_num < KillNum) andalso
		(OnhookPlayer#bd_3v3_player.help_num < HelpNum) andalso
		(OnhookPlayer#bd_3v3_player.die_num < DieNum),

	LastState = 
	case Result of
		true ->
			OnhookPlayer2 = OnhookPlayer#bd_3v3_player{
				report = OnhookPlayer#bd_3v3_player.report + 1
			},
			State#pk_state{
				player_dict = dict:store(PlayerDictKey, OnhookPlayer2, State#pk_state.player_dict)
			};
		_ ->
			State
	end,

	{noreply, LastState};

%% 举报
handle_cast({report, FromPlatform, FromServerNum, FromId, ToPlatform, ToServerNum, ToId}, State) ->
	FromKey = [FromPlatform, FromServerNum, FromId],
	ToKey = [ToPlatform, ToServerNum, ToId],

	LastState = 
	case dict:is_key(FromKey, State#pk_state.player_dict) andalso dict:is_key(ToKey, State#pk_state.player_dict) of
		true ->
			FromPlayer = dict:fetch(FromKey, State#pk_state.player_dict),
			ToPlayer = dict:fetch(ToKey, State#pk_state.player_dict),
			Node = FromPlayer#bd_3v3_player.node,
			Step = (util:unixtime() - State#pk_state.start_time) div 60,
			EvaScore = data_kf_3v3:eva_score(ToPlayer#bd_3v3_player.occupy_num, ToPlayer#bd_3v3_player.kill_num, ToPlayer#bd_3v3_player.help_num, ToPlayer#bd_3v3_player.die_num),
			[Munite2, Munite3, Munite4, Munite5] = data_kf_3v3:get_config(report_conf),
			Result = if
				Step =:= 1 andalso EvaScore < Munite2 -> true;
				Step =:= 2 andalso EvaScore < Munite3 -> true;
				Step =:= 3 andalso EvaScore < Munite4 -> true;
				Step =:= 4 andalso EvaScore < Munite5 -> true;
				true -> false
			end,
			case Result of
				true ->
					{ok, BinData} = pt_484:write(48424, [1, 0]),
					mod_clusters_center:apply_cast(Node, lib_unite_send, cluster_to_uid, [
						FromId, BinData
					]),
					NewToPlayer = ToPlayer#bd_3v3_player{
						report = ToPlayer#bd_3v3_player.report + 1
					},
					State#pk_state{
						player_dict = dict:store(ToKey, NewToPlayer, State#pk_state.player_dict)
					};
				_ ->
					{ok, BinData} = pt_484:write(48424, [0, 0]),
					mod_clusters_center:apply_cast(Node, lib_unite_send, cluster_to_uid, [
						FromId, BinData
					]),
					State
			end;
		_ ->
			State
	end,
	{noreply, LastState};

handle_cast({mon_die, Platform, ServerNum, Id, MonId}, State) ->
	PlayerDictKey = [Platform, ServerNum, Id],
	LastState = case dict:is_key(PlayerDictKey, State#pk_state.player_dict) of
		true ->
			Player = dict:fetch(PlayerDictKey, State#pk_state.player_dict),
			TeamId = Player#bd_3v3_player.team_id,
			OccupyNum = data_kf_3v3:get_occupy_by_monid(MonId),
			NewState = 
			if
				OccupyNum =:= 1 -> State#pk_state{mon_1 = TeamId};
				OccupyNum =:= 2 -> State#pk_state{mon_2 = TeamId};
				true -> State#pk_state{mon_3 = TeamId}
			end,

			%% 占领数加1
			AddOccupyScore = case Player#bd_3v3_player.occupy_score >= data_kf_3v3:get_config(occupy_score_max) of
				true -> 0;
				_ -> data_kf_3v3:get_config(cooupy_score_each)
			end,
			NewPlayer = Player#bd_3v3_player{
				occupy_num = Player#bd_3v3_player.occupy_num + 1,
				occupy_score = Player#bd_3v3_player.occupy_score + AddOccupyScore
			},
			NewState2 = NewState#pk_state{
				player_dict = dict:store(PlayerDictKey, NewPlayer, NewState#pk_state.player_dict)					  
			},
			spawn(fun() -> 
				%% 重新生成怪物
				WinSide = case TeamId =:= State#pk_state.team_id_a of
					true -> 1;
					_ -> 2
				end,
				lib_kf_3v3:reborn_occupy(State#pk_state.copy_id, OccupyNum, WinSide, State#pk_state.scene_id),
				%% 刷新pk场景右手边数据
				lib_kf_3v3:refresh_pk_info_by_state(NewState2),
				%% 发传闻
				lib_kf_3v3:send_kill_occupy_tv(Player, NewState2, WinSide, OccupyNum)
			end),

			NewState2;
		_ ->
			State
	end,
	{noreply, LastState};

handle_cast({count_occupy_value, PkPid, TotalTime, SleepTime, PkTime}, State) ->
	LastState = 
	case TotalTime < PkTime of
		true ->
			OccupyValue = data_kf_3v3:get_config(occupy_value),
			OccupyMax = data_kf_3v3:get_config(occupy_max),
			[[OccupyA, _], [OccupyB, _]] = lib_kf_3v3:get_occupy_data(State),
			AddA = State#pk_state.occupy_a + OccupyValue * OccupyA,
			AddB = State#pk_state.occupy_b + OccupyValue * OccupyB,
			AddA2 = case AddA > OccupyMax of
				true -> OccupyMax;
				_ -> AddA
			end,
			AddB2 = case AddB > OccupyMax of
				true -> OccupyMax;
				_ -> AddB
			end,
			NewState = State#pk_state{
				occupy_a = AddA2,
				occupy_b = AddB2
			},

			NewState2 = if
				NewState#pk_state.occupy_a >= OccupyMax ->
					NewState#pk_state{win_team_id = NewState#pk_state.team_id_a};
				NewState#pk_state.occupy_b >= OccupyMax ->
					NewState#pk_state{win_team_id = NewState#pk_state.team_id_b};
				true ->
					NewState
			end,

			case NewState2#pk_state.win_team_id > 0 of
				true ->
					%% 通知服务结束战斗
					mod_kf_3v3_pk:end_each_war_forward(PkPid);
				_ ->
					spawn(fun() -> 
						%% 刷新pk场景右手边数据
						lib_kf_3v3:refresh_pk_info_by_state(NewState2),

						%% 继续计算占领值
						timer:sleep(SleepTime * 1000),
						mod_kf_3v3_pk:count_occupy_value(PkPid, TotalTime + SleepTime, SleepTime, PkTime)
					end)
			end,
			NewState2;
		_ ->
			State
	end,
	{noreply, LastState};

%% 使用技能
handle_cast({use_skill, Platform, ServerNum, Id, MonId}, State) ->
	PlayerDictKey = [Platform, ServerNum, Id],
	LastState = 
	case dict:is_key(PlayerDictKey, State#pk_state.player_dict) of
		true ->
			if
				MonId =:= ?KF_3V3_SKILL_1 -> State#pk_state{skill_1 = [0, 0]};
				MonId =:= ?KF_3V3_SKILL_2 -> State#pk_state{skill_2 = [0, 0]};
				true -> State#pk_state{skill_3 = [0, 0]}
			end;
		_ ->
			State
	end,
	{noreply, LastState};

handle_cast({refresh_skill, PkPid, TotalTime, SleepTime, PkTime}, State) ->
	LastState = 
	case TotalTime < PkTime of
		true ->
			NewState = lib_kf_3v3:create_skill_mon(State),
			spawn(fun() -> 
				%% 继续刷新技能
				timer:sleep(SleepTime * 1000),
				mod_kf_3v3_pk:refresh_skill(PkPid, TotalTime + SleepTime, SleepTime, PkTime)
			end),
			NewState;
		_ ->
			State
	end,
	{noreply, LastState};

handle_cast({when_kill, KillerPlatform, KillerServerNum, KillerId, DiePlatform, DieServerNum, DiedId, HitList}, State) ->
	NowTime = util:unixtime(),
	%% 处理杀人
	KillerKey = [KillerPlatform, KillerServerNum, KillerId],
	KillPlayer = dict:fetch(KillerKey, State#pk_state.player_dict),
	[NewState, NewKillPlayer] = case dict:is_key(KillerKey, State#pk_state.kill_dict) of
		true ->
			[State2, AddKillScore] = 
			case KillPlayer#bd_3v3_player.kill_score >= data_kf_3v3:get_config(kill_score_max) of
				true ->
					[State, 0];
				_ ->
					%% {最后一次杀人时间, 最后一次杀的人id}
					{LastTime, LastId} = dict:fetch(KillerKey, State#pk_state.kill_dict),
					case LastId =:= DiedId andalso LastTime + 30 > NowTime of
						true -> 
							[State, 0];
						_ ->
							TmpState = State#pk_state{
								kill_dict = dict:store(KillerKey, {NowTime, DiedId}, State#pk_state.kill_dict)
							},
							[TmpState, data_kf_3v3:get_config(kill_score_each)]
					end
			end,
			KillPlayer2 = KillPlayer#bd_3v3_player{
				kill_num = KillPlayer#bd_3v3_player.kill_num + 1,
				kill_score = KillPlayer#bd_3v3_player.kill_score + AddKillScore
			},
			[State2, KillPlayer2];
		_ ->
			State2 = State#pk_state{
				kill_dict = dict:store(KillerKey, {NowTime, DiedId}, State#pk_state.kill_dict)
			},
			KillPlayer2 = KillPlayer#bd_3v3_player{
				kill_num = 1,
				kill_score = data_kf_3v3:get_config(kill_score_each)
			},
			[State2, KillPlayer2]
	end,
	NewState2 = NewState#pk_state{
		player_dict = dict:store(KillerKey, NewKillPlayer, NewState#pk_state.player_dict)
	},

	%% 处理被杀
	DieKey = [DiePlatform, DieServerNum, DiedId],
	DiePlayer = dict:fetch(DieKey, NewState2#pk_state.player_dict),
	AddDieScore = case DiePlayer#bd_3v3_player.die_score >= data_kf_3v3:get_config(die_score_max) of
		true -> 0;
		_ -> data_kf_3v3:get_config(die_score_each)
	end,
	NewDiePlayer = DiePlayer#bd_3v3_player{
		die_num = DiePlayer#bd_3v3_player.die_num + 1,
		die_score = DiePlayer#bd_3v3_player.die_score + AddDieScore
	},
	NewState3 = NewState2#pk_state{
		player_dict = dict:store(DieKey, NewDiePlayer, NewState2#pk_state.player_dict)
	},

	%% 处理助攻
	HelpScoreLimit = data_kf_3v3:get_config(help_score_max),
	AddHelpEachScore = data_kf_3v3:get_config(help_score_each),
	NewState4 = lists:foldl(fun({[HitId, HitPlatfrom, HitSreverNum], Time}, TmpState) -> 
		Time2 = round(Time / 1000),
		case NowTime - Time2 =< 5 of
			true ->
				HitKey = [HitPlatfrom, HitSreverNum, HitId],
				HelpPlayer = dict:fetch(HitKey, TmpState#pk_state.player_dict),
				AddHelpScore = case HelpPlayer#bd_3v3_player.help_score >= HelpScoreLimit of
					true -> 0;
					_ -> AddHelpEachScore
				end,
				HelpPlayer2 = HelpPlayer#bd_3v3_player{
					help_num = HelpPlayer#bd_3v3_player.help_num + 1,
					help_score = HelpPlayer#bd_3v3_player.help_score + AddHelpScore
				},
				TmpState#pk_state{
					player_dict = dict:store(HitKey, HelpPlayer2, TmpState#pk_state.player_dict)
				};
			_ ->
				TmpState
		end
	end, NewState3, HitList),

	{noreply, NewState4};

%% 刷新或掉线处理
handle_cast({when_logout, Platform, ServerNum, Id}, State) ->
	Key = [Platform, ServerNum, Id],
	LastState = 
	case dict:is_key(Key, State#pk_state.player_dict) of
		true ->
			Player = dict:fetch(Key, State#pk_state.player_dict),
			NewPlayer = Player#bd_3v3_player{
				status = ?KF_PLAYER_NOT_IN_PREPARE,
				leave = 1
			},
			State#pk_state{
				player_dict = dict:store(Key, NewPlayer, State#pk_state.player_dict)
			};

			%% 广播队友数据
%% 			PlayerListA = [lib_kf_3v3_pk:get_player_from_pk_state(PlayerKeyA, State2) || PlayerKeyA <- State2#pk_state.players_a],
%% 			PlayerListB = [lib_kf_3v3_pk:get_player_from_pk_state(PlayerKeyB, State2) || PlayerKeyB <- State2#pk_state.players_b],
%% 			lib_kf_3v3_pk:send_partner_info(PlayerListA, PlayerListB),
		_ ->
			State
	end,
	{noreply, LastState};

handle_cast({end_each_war}, State) ->
	LastState = case State#pk_state.win_team_id of
		0 -> 
			[NewState, PlayerListA, PlayerListB] = lib_kf_3v3:make_win(State),
			mod_kf_3v3:end_pk(NewState, PlayerListA, PlayerListB),
			NewState;
		_ ->
			State
	end,
	{stop, normal, LastState};

handle_cast({end_each_war_forward}, State) ->
	[NewState, PlayerListA, PlayerListB] = lib_kf_3v3:make_win(State),
	mod_kf_3v3:end_pk(NewState, PlayerListA, PlayerListB),
	{stop, normal, NewState};

handle_cast(_Msg, State) ->
    {noreply, State}.
