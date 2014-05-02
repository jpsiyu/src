%%%--------------------------------------
%%% @Module : lib_kf_3v3
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3主要逻辑处理模块
%%%--------------------------------------

-module(lib_kf_3v3).
-include("unite.hrl").
-include("server.hrl").
-include("kf_3v3.hrl").
-include("team.hrl").
-export([
	make_win/1,
	match_single_list/1,
	match_team_list/3,
	get_second_of_day/0,
	game_send_pk_result/3,
	get_player_from_dict/2,
	refresh_right_info/4,
	get_occupy_data/1,
	update_player_kf3v3_info/2,
	update_player_info_offline/2,
	update_player_info/2,
	update_player_after_pk/2,
	get_top_score_list/1,
	make_one_team/2,
	sort_player_by_score/1,
	before_pk_init_skill/1,
	reset_to_default_scene/1,
	mail_award/1,
	move_team_to_pk_scene/3,
	send_kill_occupy_tv/4,
	refresh_pk_info_by_state/1,
	reborn_occupy/4,
	create_skill_mon/1,
	make_copyid_by_teamid/2,
	clean_week_data/0,
	clean_report_data/0,
	get_report_num/1,
	sign_up/1,
	gm_start_activity/1,
	gm_start_activity2/1,
	gm_open/4
]).

%% 战斗结束核心算法
%% 战斗时间到了，或是提前结束战斗，都需要经该方法处理
make_win(PkState) ->
 	%% 处理mvp
	[State, SortPlayerList] = private_get_mvp(PkState),

	%% 找出两个队伍参与的玩家
	TmpPlayerListA = [get_player_from_dict(PlayerKeyA, State#pk_state.player_dict) || PlayerKeyA <- State#pk_state.players_a],
	TmpPlayerListB = [get_player_from_dict(PlayerKeyB, State#pk_state.player_dict) || PlayerKeyB <- State#pk_state.players_b],

	%% 得出获胜队伍id
	WinteamId = case State#pk_state.win_team_id > 0 of
		%% 提前结束（占领值谁先达到500谁就赢）
		true -> State#pk_state.win_team_id;
		%% 正常跑完pk时间结束，先判断神坛数谁多，再判断占领值谁多，多的就是赢方
		_ -> private_get_win_teamid(State)
	end,

	%% 获取挂机人数
	OnhookNumA = private_get_onhook_num(TmpPlayerListA),
	OnhookNumB = private_get_onhook_num(TmpPlayerListB),
	PkLimit = data_kf_3v3:get_config(pk_limit),

	if
		%% A方赢
		WinteamId =:= State#pk_state.team_id_a ->
			%% 战斗结果，0都输，1A方赢，2B方赢
			%% A方结果
			WinAddNumA = 1,
			%% B方结果
			WinAddNumB = 0,
			%% 重置战斗结果，下面计算收益时会重新赋值
			PlayerListA = privte_reset_result_after_pk(TmpPlayerListA, WinAddNumA),
			PlayerListB = privte_reset_result_after_pk(TmpPlayerListB, WinAddNumB),
			%% 为玩家增加积分
			TmpPlayerList1A = [private_count_add_score(PkLimit, WinAddNumA, State#pk_state.occupy_a, State#pk_state.occupy_b, OnhookNumA, PlayerScoreA) || PlayerScoreA <- PlayerListA],
			TmpPlayerList1B = [private_count_add_score(PkLimit, WinAddNumB, State#pk_state.occupy_a, State#pk_state.occupy_b, OnhookNumB, PlayerScoreB) || PlayerScoreB <- PlayerListB],
			%% 为玩家增加声望
			[WinPt, LosePt] = private_count_pt(PlayerListA, PlayerListB),
			TmpPlayerList2A = [private_after_pk_add_pt(PlayerPtA, WinPt, WinAddNumA) || PlayerPtA <- TmpPlayerList1A],
			TmpPlayerList2B = [private_after_pk_add_pt(PlayerPtB, LosePt, WinAddNumB) || PlayerPtB <- TmpPlayerList1B],
			%% 为玩家增加经验
			TmpPlayerList3A = [private_after_pk_add_exp(PlayerExpA, 1) || PlayerExpA <- TmpPlayerList2A],
			TmpPlayerList3B = [private_after_pk_add_exp(PlayerExpB, 0) || PlayerExpB <- TmpPlayerList2B],
			%% 增加勋章
			TmpPlayerList4A = [private_after_pk_add_goods(PlayerGoodsA, 1, OnhookNumA) || PlayerGoodsA <- TmpPlayerList3A],
			TmpPlayerList4B = [private_after_pk_add_goods(PlayerGoodsB, 0, OnhookNumB) || PlayerGoodsB <- TmpPlayerList3B];

		%% B方赢
		WinteamId =:= State#pk_state.team_id_b ->
			WinAddNumA = 0,
			WinAddNumB = 1,
			PlayerListA = privte_reset_result_after_pk(TmpPlayerListA, WinAddNumA),
			PlayerListB = privte_reset_result_after_pk(TmpPlayerListB, WinAddNumB),
			TmpPlayerList1A = [private_count_add_score(PkLimit, WinAddNumA, State#pk_state.occupy_b, State#pk_state.occupy_a, OnhookNumA, PlayerScoreA) || PlayerScoreA <- PlayerListA],
			TmpPlayerList1B = [private_count_add_score(PkLimit, WinAddNumB, State#pk_state.occupy_b, State#pk_state.occupy_a, OnhookNumB, PlayerScoreB) || PlayerScoreB <- PlayerListB],
			[WinPt, LosePt] = private_count_pt(PlayerListB, PlayerListA),
			TmpPlayerList2A = [private_after_pk_add_pt(PlayerPtA, LosePt, WinAddNumA) || PlayerPtA <- TmpPlayerList1A],
			TmpPlayerList2B = [private_after_pk_add_pt(PlayerPtB, WinPt, WinAddNumB) || PlayerPtB <- TmpPlayerList1B],
			TmpPlayerList3A = [private_after_pk_add_exp(PlayerExpA, 0) || PlayerExpA <- TmpPlayerList2A],
			TmpPlayerList3B = [private_after_pk_add_exp(PlayerExpB, 1) || PlayerExpB <- TmpPlayerList2B],
			TmpPlayerList4A = [private_after_pk_add_goods(PlayerGoodsA, 0, OnhookNumA) || PlayerGoodsA <- TmpPlayerList3A],
			TmpPlayerList4B = [private_after_pk_add_goods(PlayerGoodsB, 1, OnhookNumB) || PlayerGoodsB <- TmpPlayerList3B];

		%% 没有人输赢，即都输
		true ->
			WinAddNumA = 0,
			WinAddNumB = 0,
			PlayerListA = privte_reset_result_after_pk(TmpPlayerListA, WinAddNumA),
			PlayerListB = privte_reset_result_after_pk(TmpPlayerListB, WinAddNumB),
			TmpPlayerList1A = [private_count_add_score(PkLimit, WinAddNumA, State#pk_state.occupy_b, State#pk_state.occupy_a, OnhookNumA, PlayerScoreA) || PlayerScoreA <- PlayerListA],
			TmpPlayerList1B = [private_count_add_score(PkLimit, WinAddNumB, State#pk_state.occupy_b, State#pk_state.occupy_a, OnhookNumB, PlayerScoreB) || PlayerScoreB <- PlayerListB],
			[_WinPt, LosePt] = private_count_pt(PlayerListA, PlayerListB),
			TmpPlayerList2A = [private_after_pk_add_pt(PlayerPtA, LosePt, WinAddNumA) || PlayerPtA <- TmpPlayerList1A],
			TmpPlayerList2B = [private_after_pk_add_pt(PlayerPtB, LosePt, WinAddNumB) || PlayerPtB <- TmpPlayerList1B],
			TmpPlayerList3A = [private_after_pk_add_exp(PlayerExpA, 0) || PlayerExpA <- TmpPlayerList2A],
			TmpPlayerList3B = [private_after_pk_add_exp(PlayerExpB, 0) || PlayerExpB <- TmpPlayerList2B],
			TmpPlayerList4A = [private_after_pk_add_goods(PlayerGoodsA, 0, OnhookNumA) || PlayerGoodsA <- TmpPlayerList3A],
			TmpPlayerList4B = [private_after_pk_add_goods(PlayerGoodsB, 0, OnhookNumB) || PlayerGoodsB <- TmpPlayerList3B]
	end,

	PlayerList2A = TmpPlayerList4A,
	PlayerList2B = TmpPlayerList4B,

	spawn(fun() -> 
		%% 将对阵记录保存起来
		mod_kf_3v3_helper:insert_pk_log(PlayerList2A, PlayerList2B),

		%% 发送结果，提示战报，及增加玩家经验等
		private_send_pk_result(State, PlayerList2A, PlayerList2B, SortPlayerList)
	end),

	[State, PlayerList2A, PlayerList2B].

%% 匹配队友
%% 单个玩家报名需要先匹配队友，成功匹配后组成队伍，再等待匹配对手
%% @param State 		进程状态
%% @return NewState		新状态
match_single_list(State) ->
	List = dict:to_list(State#kf_3v3_state.single_dict),
	case List of
		[] ->
			State;
		_ ->
			%% 单人报名列表，按计算的参数倒序
			F = fun({_DictKey1, [_Num1, Param1]}, {_DictKey2, [_Num2, Param2]}) ->
				Param1 >= Param2
			end,
			SortList = lists:sort(F, List),
			private_match_single_list(SortList, State)
	end.

%% 匹配队伍
match_team_list([], State, _SleepTime) ->
	State;
match_team_list([One | Tail], State, SleepTime) -> 
	[NewState, NewTail] = private_match_team_list(One, Tail, State, SleepTime),
	match_team_list(NewTail, NewState, SleepTime + 100).

%% 获取现在距离今天0点秒数
get_second_of_day() ->
	{{_, _, _}, {Hour, Minute, Second}} = calendar:local_time(),
	(Hour * 60 + Minute) * 60 + Second.

%% [游戏线] 每一场pk结束后弹出战报结果，及增加玩家经验
game_send_pk_result(Id, Bin48408, Exp) ->
	mod_disperse:cast_to_unite(lib_unite_send, send_to_uid, [Id, Bin48408]),
	lib_player:update_player_info(Id, [{add_exp, Exp}]).

%% 从场景玩家中取出指定玩家数据
%% @return #bd_3v3_player | false
get_player_from_dict(PlayerDictKey, Dict) ->
	case dict:is_key(PlayerDictKey, Dict) of
		true ->
			case dict:fetch(PlayerDictKey, Dict) of
				Player when is_record(Player, bd_3v3_player) -> Player;
				_ -> false
			end;
		_ -> false
	end.

%% 刷新准备区右边数据
%% @param Status	活动状态
%% @param Loop		当前场次
%% @param LeftTime	剩余活动时间
%% @param Player	#bd_3v3_player
refresh_right_info(Status, Loop, LeftTime, Player) ->
	NewSignUp = case Player#bd_3v3_player.status > 1 of
		true -> 1;
		_ -> 0
	end,
	{ok, BinData} = pt_484:write(48404, [
		Status, Loop, LeftTime, Player#bd_3v3_player.pk_num, Player#bd_3v3_player.pk_win_num, NewSignUp
	]),
	mod_clusters_center:apply_cast(Player#bd_3v3_player.node, lib_unite_send, cluster_to_uid, [
		Player#bd_3v3_player.id, BinData
	]).

%% 获取占领数据
%% @param State	#pk_state
%% @return [[A方占领神坛数, A方占领值], [B方占领神坛数, B方占领值]]
get_occupy_data(State) ->
	List = [State#pk_state.mon_1, State#pk_state.mon_2, State#pk_state.mon_3],
	[OccupyNumA, OccupyNumB] = 
	lists:foldl(fun(TeamId, [TmpOccupyNumA, TmpOccupyNumB]) -> 
		if
			TeamId =:= 0 -> [TmpOccupyNumA, TmpOccupyNumB];
			TeamId =:= State#pk_state.team_id_a -> [TmpOccupyNumA + 1, TmpOccupyNumB];
			true -> [TmpOccupyNumA, TmpOccupyNumB + 1]
		end
	end, [0, 0], List),
	[[OccupyNumA, State#pk_state.occupy_a], [OccupyNumB, State#pk_state.occupy_b]].

%% 更新玩家数据
%% 活动结束后，mod_kf_3v3会将玩家的数据，从跨服节点cast到游戏节点来更新
%% 需要区分处理玩家在线或不在线的情况
update_player_kf3v3_info(RoleId, Data) ->
	case misc:get_player_process(RoleId) of
		Pid when is_pid(Pid) ->
			gen_server:cast(Pid, {'set_data', Data});
		_ ->
			update_player_info_offline(RoleId, Data)
	end.

%% 活动结束后，更新玩家的声望，积分，战斗次数；更新本地周积分排行榜
%% @return	NewPS
update_player_info(PS, [Pt, PkNum, PkWinNum, MvpNum, GoodsNum, Score, TotalReport]) ->
	NowTime = util:unixtime(),
	%% 更新玩家的声望，积分，战斗次数
	RoleId = PS#player_status.id,
	[LastPt, LastMvpNum, LastPkNum, LastPkWinNum] = 
	case db:get_row(io_lib:format(?SQL_KF_3V3_SELECT, [RoleId])) of
		[] ->
			Pt2 = if
				Pt < 0 -> 0;
				true -> Pt
			end,
			db:execute(io_lib:format(?SQL_KF_3V3_INSERT, [
				RoleId, Pt2, MvpNum, PkNum, PkWinNum, TotalReport, util:unixtime()
			])),
			[Pt2, MvpNum, PkWinNum, MvpNum];
		[OldPt, OldMvpNum, OldPkNum, OldPkWinNum] ->
			Pt2 = OldPt + Pt,
			Pt3 = if
				Pt2 < 0 -> 0;
				true -> Pt2
			end,
			db:execute(io_lib:format(?SQL_KF_3V3_UPDATE, [
				Pt3, MvpNum, PkNum, PkWinNum, TotalReport, util:unixtime(), RoleId
			])),
			[Pt3, OldMvpNum + MvpNum, OldPkNum + PkNum, OldPkWinNum + PkWinNum]
	end,
	NewStatusKf1v1 = PS#player_status.kf_1v1#status_kf_1v1{
		pt = LastPt
	},
	NewStatusKf3v3 = PS#player_status.kf_3v3#status_kf_3v3{
		mvp = LastMvpNum,
		kf3v3_pk_num = LastPkNum,
		kf3v3_pk_win = LastPkWinNum,
		kf3v3_score_week = PS#player_status.kf_3v3#status_kf_3v3.kf3v3_score_week + Score
	},
	mod_daily:set_count(PS#player_status.dailypid, RoleId, 5705, PkNum),

	%% 更新本地3v3排行榜
	case db:get_row(io_lib:format(?SQL_BD_3V3_RANK_GET, [RoleId])) of
		[] ->
			RankPt = if
				Pt < 0 -> 0;
				true -> Pt
			end,
			db:execute(io_lib:format(?SQL_BD_3V3_RANK_INSERT, [RoleId, RankPt, Score, PkWinNum, PkNum - PkWinNum, NowTime]));
		[OldRankpt, _OldRankScore, _OldRankWin, _OldRankLose] ->
			RankPt = OldRankpt + Pt,
			RankPt2 = if
				RankPt < 0 -> 0;
				true -> RankPt
			end,
			db:execute(io_lib:format(?SQL_BD_3V3_RANK_UPDATE, [RankPt2, Score, PkWinNum, PkNum - PkWinNum, NowTime, RoleId]))
	end,

	%% 召回活动
	catch lib_off_line:add_off_line_count(PS#player_status.id, 16, 1, GoodsNum),

	catch lib_qixi:update_player_task(PS#player_status.id, 8, PkWinNum),

	PS#player_status{
		kf_1v1 = NewStatusKf1v1,
		kf_3v3 = NewStatusKf3v3
	}.

%% 活动结束后，更新玩家的声望,积分,战斗次数(玩家不在线时的处理)
update_player_info_offline(RoleId, Data) ->
	[{kf_3v3, [Pt, PkNum, PkWinNum, MvpNum, GoodsNum, Score, TotalReport]}] = Data,
	NowTime = util:unixtime(),

	[LastPt] = 
	case db:get_row(io_lib:format(?SQL_KF_3V3_SELECT, [RoleId])) of
		[] ->
			Pt2 = if
				Pt < 0 -> 0;
				true -> Pt
			end,
			db:execute(io_lib:format(?SQL_KF_3V3_INSERT, [
				RoleId, Pt2, MvpNum, PkNum, PkWinNum, TotalReport, NowTime
			])),
			[Pt2];
		[OldPt, _OldMvpNum, _OldPkNum, _OldPkWinNum] ->
			Pt2 = OldPt + Pt,
			Pt3 = if
				Pt2 < 0 -> 0;
				true -> Pt2
			end,
			db:execute(io_lib:format(?SQL_KF_3V3_UPDATE, [
				Pt3, MvpNum, PkNum, PkWinNum, TotalReport, NowTime, RoleId
			])),
			[Pt3]
	end,
	lib_daily:update_count(RoleId, 5705, PkNum, NowTime),
	
	%% 更新本地3v3排行榜
	db:execute(io_lib:format(?SQL_BD_3V3_RANK_INSERT, [RoleId, LastPt, Score, PkWinNum, PkNum - PkWinNum, NowTime])),

	%% 召回活动
	catch lib_off_line:add_off_line_count(RoleId, 16, 1, GoodsNum),
	
	catch lib_qixi:update_player_task(RoleId, 8, PkWinNum).


%% pk结束后：将玩家pk完状态重置为在准备区的状态
update_player_after_pk(Player, [State, PlayerList]) ->
	Key = [Player#bd_3v3_player.platform, Player#bd_3v3_player.server_num, Player#bd_3v3_player.id],
	OldPlayer = dict:fetch(Key, State#kf_3v3_state.player_dict),

	%% 将玩家传送出pk场景
	private_move_player_after_pk(State, Player, OldPlayer),

	Status = case State#kf_3v3_state.status =:= ?KF_3V3_STATUS_ACTION of
		true ->
			case OldPlayer#bd_3v3_player.status =:= ?KF_PLAYER_NOT_IN_PREPARE of
				true -> 0;
				_ -> 1
			end;
		_ -> 
			0
	end,

	[WinAddNum | _] = Player#bd_3v3_player.pk_result,
	[WinNum, LoseNum] = case WinAddNum of
			1 -> [1, 0];
		_ -> [0, 1]
	end,

	[CdTime, OnHook] = case Player#bd_3v3_player.report >= 4 of
		true ->
			NewOnHook = Player#bd_3v3_player.onhook + 1,
			NewCdTime = case Player#bd_3v3_player.cd_end_time > 0 of
				true -> Player#bd_3v3_player.cd_end_time + NewOnHook * data_kf_3v3:get_config(cd_time);
				_ -> util:unixtime() + NewOnHook * data_kf_3v3:get_config(cd_time)
			end,
			[NewCdTime, NewOnHook];
		_ ->
			[Player#bd_3v3_player.cd_end_time, Player#bd_3v3_player.onhook]
	end,

	SubReportNum = data_kf_3v3:sub_report(Player#bd_3v3_player.score, Player#bd_3v3_player.mvp),
	NewReport = case Player#bd_3v3_player.report - SubReportNum >= 0 of
		true -> Player#bd_3v3_player.report - SubReportNum;
		_ -> 0
	end,

	NewPlayer = Player#bd_3v3_player{
		status =  Status,
		leave = 0,
		pk_num = Player#bd_3v3_player.pk_num + 1,
		pk_win_num = Player#bd_3v3_player.pk_win_num + WinNum,
		pk_lose_num = Player#bd_3v3_player.pk_lose_num + LoseNum,
		cd_end_time = CdTime,
		onhook = OnHook,
		team_id = 0,
		group = 0,
		occupy_num = 0,
		occupy_score = 0,
		kill_num = 0,
		kill_score = 0,
		help_num = 0,
		help_score = 0,
		die_num = 0,
		die_score = 0,
		mvp = 0,
		report = 0,
		total_report = Player#bd_3v3_player.total_report + NewReport,
		pk_pid = none
	},

	NewState = State#kf_3v3_state{
		player_dict = dict:store(Key, NewPlayer, State#kf_3v3_state.player_dict)
	},
	[NewState, [NewPlayer | PlayerList]].

%% 获取前100名玩家积分列表数据
%% @return [#bd_3v3_rank, ...]
get_top_score_list(State) ->
	List = dict:to_list(State#kf_3v3_state.player_dict),
	SortList = sort_player_by_score(List),
	Length = length(SortList),
	if
		Length > 100 ->
			{NewSortList, _} = lists:split(100, SortList);
		true->
			NewSortList = SortList
	end,
	private_player_top_format(NewSortList, []).

%% 将原本一个队伍中的三个玩家构造成一个队伍
%% @return NewState
make_one_team(PlayerList, State) ->
	%% 生成唯一队伍id
	TeamNo = mod_kf_3v3_helper:receive_team_no(),

	%% 将队伍加进队伍报名队列
	[NewState, PlayerKeyList, NewPlayerList, TotalPower, MaxPower, TotalLv, MaxLv, TotalNum, TotalWinNum] = 
	lists:foldl(fun(Player, [TmpState, TmpPlayerKeyList, TmpPlayerList, TmpTotalPower, TmpMaxPower, TmpTotalLv, TmpMaxLv, TmpTotalNum, TmpTotalWinNum]) -> 
		DictKey = [Player#bd_3v3_player.platform, Player#bd_3v3_player.server_num, Player#bd_3v3_player.id],
		NewPlayer = Player#bd_3v3_player{
			status = ?KF_PLAYER_TEAM,
			team_id = TeamNo
		},
		NewPlayerDict = dict:store(DictKey, NewPlayer, TmpState#kf_3v3_state.player_dict),
		[
			TmpState#kf_3v3_state{player_dict = NewPlayerDict},
			[[Player#bd_3v3_player.platform, Player#bd_3v3_player.server_num, Player#bd_3v3_player.id] | TmpPlayerKeyList],
			[NewPlayer | TmpPlayerList],
			TmpTotalPower + Player#bd_3v3_player.max_combat_power,
			max(Player#bd_3v3_player.max_combat_power, TmpMaxPower),
			TmpTotalLv + Player#bd_3v3_player.lv,
			max(Player#bd_3v3_player.lv, TmpMaxLv),
			TmpTotalNum + Player#bd_3v3_player.pk_num,
			TmpTotalWinNum + Player#bd_3v3_player.pk_win_num
		]
	end, [State, [], [], 0, 0, 0, 0, 0, 0], PlayerList),
	Param = data_kf_3v3:count_team_param(TotalPower, MaxPower, TotalLv, MaxLv, TotalNum, TotalWinNum, 0),
	NewTeamDict = dict:store(TeamNo, [0, Param, PlayerKeyList], NewState#kf_3v3_state.team_dict),

	%% 刷新队员为报名状态
	LeftTime = State#kf_3v3_state.end_time - get_second_of_day(),
	[refresh_right_info(State#kf_3v3_state.status, State#kf_3v3_state.loop, LeftTime, RePlayer) || RePlayer <- NewPlayerList],

	NewState#kf_3v3_state{
		team_dict = NewTeamDict
	}.

%% 排序玩家记录
%% 规则：先按玩家积分，再按玩家胜率
sort_player_by_score(PlayerDictList)->
	lists:sort(fun({_K1, PlayerA}, {_K2, PlayerB}) ->
		if
			PlayerA#bd_3v3_player.score > PlayerB#bd_3v3_player.score ->
				true;
			PlayerA#bd_3v3_player.score > PlayerB#bd_3v3_player.score ->
				WinRateA = PlayerA#bd_3v3_player.pk_win_num / PlayerA#bd_3v3_player.pk_num,
				WinRateB = PlayerB#bd_3v3_player.pk_win_num / PlayerB#bd_3v3_player.pk_num,
				WinRateA >= WinRateB;
			true ->
				false
		end
	end, PlayerDictList).

%% pk前：计算好技能要出现的位置
%% 返回三个坐标点
before_pk_init_skill(List) ->
	List2 = util:list_shuffle(List),
	[XY1, XY2, XY3 | _] = List2,
	[XY1, XY2, XY3].

%% 玩家登录时，如所在场景是在3v3准备区或战斗场景中，即设置回长安
%% @param PS
%% @return NewPS
reset_to_default_scene(PS)->
	SceneId1 = data_kf_3v3:get_config(scene_id1),
	Kf3v3InPkScene = lists:member(PS#player_status.scene, data_kf_3v3:get_config(scene_pk_ids)),
	[SceneId, X, Y] = data_kf_3v3:get_config(leave_scene),
	if
		PS#player_status.scene =:= SceneId1 orelse Kf3v3InPkScene =:= true ->
			PS#player_status{scene = SceneId, copy_id = 0, x = Y, y = X};
		true ->
			PS
	end.

%% 比赛结束后，发邮件通知玩家获得勋章奖励
mail_award(PlayerList) ->
	%% 跨服竞技勋章
	GoodsTypeId = data_kf_3v3:get_config(xunzhang_id),
	Title = data_kf_text:get_3v3_mail_title(),
	Content = data_kf_text:get_3v3_mail_content(),

	F = fun(FunPlayer) ->
		Content2 = io_lib:format(Content, [
			(FunPlayer#bd_3v3_player.pk_win_num + FunPlayer#bd_3v3_player.pk_lose_num),
			FunPlayer#bd_3v3_player.pk_win_num,
			FunPlayer#bd_3v3_player.pk_lose_num,
			FunPlayer#bd_3v3_player.goods_num
		]),
		[FunPlayer#bd_3v3_player.node, FunPlayer#bd_3v3_player.id, Title, Content2, GoodsTypeId, FunPlayer#bd_3v3_player.goods_num]
	end,
	NewPlayerList = [F(Player) || {_PlayerDictKey, Player} <- PlayerList, Player#bd_3v3_player.goods_num > 0],

	lists:foldl(fun([MailNode, MailId, MailTitle, MailContent, MailGoodsId, MailGoodsNum], MailNum) -> 
		case MailNum div 10 == 0 of
			true -> timer:sleep(500);
			_ -> skip
		end,
		catch mod_clusters_center:apply_cast(MailNode, lib_mail, send_sys_mail_bg_4_1v1, [
			[MailId], MailTitle, MailContent, MailGoodsId, 2, 0, 0, MailGoodsNum, 0, 0, 0, 0
		]),
		MailNum + 1
	end, 0, NewPlayerList).

%% 将参与比赛的两个队伍传送到pk场景
move_team_to_pk_scene(State, PlayerListA, PlayerListB) ->
	%% 构造pk场景中的排行数据
	SortBinList = private_format_pk_sort(PlayerListA ++ PlayerListB),
	[[X1, Y1], [X2, Y2]] = data_kf_3v3:get_config(position2),
	[private_move_to_pk_scene(1, PlayerA, State, SortBinList, State#pk_state.scene_id, State#pk_state.copy_id, X1, Y1) || PlayerA <- PlayerListA],
	[private_move_to_pk_scene(2, PlayerB, State, SortBinList, State#pk_state.scene_id, State#pk_state.copy_id, X2, Y2) || PlayerB <- PlayerListB].

%% 占领神坛发传闻
%% @param GetPlayer	占领神坛的玩家
%% @param Side		1红色A方，2蓝色B方
%% @param Position	神坛位置：1:左 2：中 3：右
send_kill_occupy_tv(GetPlayer, State, Side, Position) ->
	TvFun = fun(Player) ->
		Msg = [
			"captureST", GetPlayer#bd_3v3_player.id, GetPlayer#bd_3v3_player.country,
			GetPlayer#bd_3v3_player.name, GetPlayer#bd_3v3_player.sex,
			GetPlayer#bd_3v3_player.career, 0, Side, Position
		],
		MsgList = lib_chat:make_send_tv_list(Msg, []),
		Content = lists:concat(MsgList),
		{ok, Data} = pt_110:write(11014, [2, Content]),
		mod_clusters_center:apply_cast(Player#bd_3v3_player.node, lib_unite_send, cluster_to_uid, [Player#bd_3v3_player.id, Data])
	end,

	Fun = fun(FunKey) ->
		case dict:is_key(FunKey, State#pk_state.player_dict) of
			true ->
				FunPlayer = dict:fetch(FunKey, State#pk_state.player_dict),
				TvFun(FunPlayer);
			_ ->
				skip
		end
	end,
	
	lists:foreach(Fun, State#pk_state.players_a),
	lists:foreach(Fun, State#pk_state.players_b).

%% 刷新战斗区右边数据
refresh_pk_info_by_state(State) ->
	TmpPlayerListA = [get_player_from_dict(PlayerKeyA, State#pk_state.player_dict) || PlayerKeyA <- State#pk_state.players_a],
	TmpPlayerListB = [get_player_from_dict(PlayerKeyB, State#pk_state.player_dict) || PlayerKeyB <- State#pk_state.players_b],
	%% 构造pk场景中的排行数据
	SortBinList = private_format_pk_sort(TmpPlayerListA ++ TmpPlayerListB),

	[private_refresh_pk_info(1, PlayerA, State, SortBinList) || PlayerA <- TmpPlayerListA],
	[private_refresh_pk_info(2, PlayerB, State, SortBinList) || PlayerB <- TmpPlayerListB].

%% 重新生成神坛
%% @param CopyId	战斗副本id
%% @param OccupyNum	第几个神坛，分别有1、2、3
%% @param Side		1表示A方，2表示B方
reborn_occupy(CopyId, OccupyNum, Side, SceneId) ->
	MonId = data_kf_3v3:get_monid_by_occupy(OccupyNum, Side),
	[TargetX, TargetY, _] = 
	lists:foldl(fun([X, Y], [TmpX, TmpY, TmpNum]) -> 
		case TmpNum =:= OccupyNum of
			true ->
				[X, Y, TmpNum + 1];
			_ ->
				[TmpX, TmpY, TmpNum + 1]
		end
	end, [0, 0, 1], data_kf_3v3:get_config(occupy_xy)),
    lib_mon:async_create_mon(MonId, SceneId, TargetX, TargetY, 1, CopyId, 1, [{group, Side}]).

%% 刷新技能
create_skill_mon(State) ->
	ConfigXYList = data_kf_3v3:get_config(skill_list),
	SkillList = [State#pk_state.skill_1, State#pk_state.skill_2, State#pk_state.skill_3],
	NewList = lists:foldl(fun(FElement, FConfigXYList) -> 
		lists:delete(FElement, FConfigXYList)
	end, ConfigXYList, SkillList),
	NewList2 = util:list_shuffle(NewList),
	[[X1, Y1], [X2, Y2], [X3, Y3] | _] = NewList2,

	SceneId = State#pk_state.scene_id,
	CopyId = State#pk_state.copy_id,

	State1 = if
		State#pk_state.skill_1 =:= [0, 0] ->
            lib_mon:async_create_mon(?KF_3V3_SKILL_1, SceneId, X1, Y1, 1, CopyId, 1, []),
			State#pk_state{skill_1 = [X1, Y1]};
		true ->
			State
	end,
	State2 = if
		State1#pk_state.skill_2 =:= [0, 0] ->
            lib_mon:async_create_mon(?KF_3V3_SKILL_2, SceneId, X2, Y2, 1, CopyId, 1, []),
			State1#pk_state{skill_2 = [X2, Y2]};
		true ->
			State1
	end,
	State3 = if
		State2#pk_state.skill_3 =:= [0, 0] ->
            lib_mon:async_create_mon(?KF_3V3_SKILL_3, SceneId, X3, Y3, 1, CopyId, 1, []),
			State2#pk_state{skill_2 = [X3, Y3]};
		true ->
			State2
	end,
	State3.

%% 构造战斗场景copyid
make_copyid_by_teamid(TeamIdA, TeamIdB) -> 
	TeamIdA * 100000 + TeamIdB.

%% 清掉玩家身上每周mvp,pk次数,pk胜利数据
clean_week_data() ->
	db:execute(?SQL_KF_3V3_CLEAN_DATA, []).

%% 清掉玩家身上被举报次数
clean_report_data() ->
	case data_kf_3v3:is_can_clean_report_data() of
		true -> db:execute(?SQL_KF_3V3_CLEAN_REPORT, []);
		_ -> skip
	end.

%% 获取被举报次数
get_report_num(Id) ->
	case db:get_one(io_lib:format(?SQL_KF_3V3_REPORT_NUM, [Id])) of
		null -> 0;
		Num -> Num
	end.

%% 报名
%% 返回：{ok} | {error, ErrorCode}
sign_up(US) ->
	%% 再次判断战力及等级，避免该场景被非法进入
	case lib_player:get_player_info(US#unite_status.id, kf_3v3_info) of
		{CombatPower, _MaxCombatPower, _Scene, _VipLv, _Kf1v1Data} ->
			%% 再次判断玩家等级及战力是否满足要求
			case CombatPower >= data_kf_3v3:get_config(min_power) andalso 
				US#unite_status.lv >= data_kf_3v3:get_config(min_lv) of
				true ->
					case US#unite_status.team_id > 0 of
						%% 队伍报名
						true ->
							%% 如果有队伍，需要队长才有报名权限
							case lib_player:get_player_info(US#unite_status.id, pid_team) of
								false ->
									{error, 7};
								TeamPid ->
									%% 取队长id
									LeaderId = lib_team:get_leaderid(TeamPid),
									case LeaderId =:= US#unite_status.id of
										true ->
											MbIds = lib_team:get_mb_ids(TeamPid),
											MemLen = length(MbIds),
											case MemLen =:= data_kf_3v3:get_config(team_person) of
												true ->
													mod_clusters_node:apply_cast(mod_kf_3v3, sign_up_team, [
														mod_disperse:get_clusters_node(),
														US#unite_status.platform,
														US#unite_status.server_num,
														US#unite_status.id,
														MbIds
													]),
													{ok};
												_ ->
													case MemLen of
														1 ->
															mod_clusters_node:apply_cast(mod_kf_3v3, sign_up_single, [
																mod_disperse:get_clusters_node(),
																config:get_platform(),
																config:get_server_num(),
																US#unite_status.id
															]),
															{ok};
														_ ->
															{error, 8}
													end
											end;
										_ ->
											{error, 9}
									end
							end;

						%% 单人报名
						_ ->
							mod_clusters_node:apply_cast(mod_kf_3v3, sign_up_single, [
								mod_disperse:get_clusters_node(),
								config:get_platform(),
								config:get_server_num(),
								US#unite_status.id
							]),
							{ok}
					end;
				_ ->
					{error, 4}
			end;
		_ ->
			{error, 3}
	end.

%% 管理后台通过秘籍小工具激活3v3活动图标，让玩家可以点击进入准备区
gm_start_activity(Status) ->
	mod_disperse:cast_to_unite(lib_kf_3v3, gm_start_activity2, [Status]),
	ok.
gm_start_activity2(Status) ->
	mod_kf_3v3_state:set_status(Status),
	L = mod_chat_agent:get_sid(all, 0),
	{ok, BinData} = pt_484:write(48401, Status),
	lists:foreach(fun(Sid) -> 
		lib_unite_send:send_to_sid(Sid, BinData)		  
	end, L).

%% 秘籍：开启活动
%% 填过去时间，则停止活动
%% @param Hour				开始小时
%% @param Minute			开始分钟
%% @param ActivityTime		活动时间（分钟）
%% @param PkTime			每场战斗时间（分钟）
gm_open(Hour, Minute, ActivityTime, PkTime) ->
	ActivityTime2 = ActivityTime * 60,
	PkTime2 = PkTime * 60,
	mod_clusters_node:apply_cast(mod_kf_3v3_mgr, mt_start_link, [Hour, Minute, ActivityTime2, PkTime2]),
	ok.

%%------------------------------ 本模块私有方法  ------------------------------%%

%% pk后：在计算收益前先重置战斗显示结果数据
privte_reset_result_after_pk(PlayerList, WinOrLose) ->
	lists:map(fun(Player) ->
		%% 显示输赢
		Result = if
			%% 刷新掉线或被踢，都显示成输
			Player#bd_3v3_player.leave =:= 1 -> 0;
			Player#bd_3v3_player.leave =:= 2 -> 0;
			true -> WinOrLose
		end,
		%% 显示是否双倍奖励
		DoubleAward = case data_kf_3v3:get_multi_award(Player#bd_3v3_player.pk_num) of
			1 -> 0;
			_ -> 1
		end,
		Player#bd_3v3_player{pk_result = [Result, 0, 0, 0, 0, DoubleAward]}
	end, PlayerList).

%% 计算可获得的积分
%% @param PkLimit 		每天前面N场战斗有奖励
%% @param WinResult		1赢0输
%% @param WinOccupy		赢占领值
%% @param LoseOccupy	输占领值
%% @param OnhookNum		挂机人数
private_count_add_score(PkLimit, TmpWinResult, WinOccupy, LoseOccupy, OnhookNum, Player) ->
	case Player#bd_3v3_player.leave of
		%% 挂机被踢，没奖励
		2 -> Player;
		_ ->
			WinResult = case Player#bd_3v3_player.leave of
				%% 掉线刷新，算输
				1 -> 0;
				_ -> TmpWinResult
			end,
			case Player#bd_3v3_player.pk_num < PkLimit of
				true ->
					AddScore = case WinResult of
						1 ->
							TmpScore = 100 * (1 + (WinOccupy - LoseOccupy) / 2000 + Player#bd_3v3_player.mvp * 0.25) + 
								Player#bd_3v3_player.occupy_score + 
								Player#bd_3v3_player.kill_score + 
								Player#bd_3v3_player.help_score + 
								Player#bd_3v3_player.die_score + 
								100 * OnhookNum / 3,
							data_kf_3v3:get_award_after_report(
								TmpScore * data_kf_3v3:get_multi_award(Player#bd_3v3_player.pk_num),
								Player#bd_3v3_player.report
							);
						_ ->
							TmpScore = 25 * (1 + (LoseOccupy - WinOccupy) / 2000 + Player#bd_3v3_player.mvp * 0.25) + 
								Player#bd_3v3_player.occupy_score + 
								Player#bd_3v3_player.kill_score + 
								Player#bd_3v3_player.help_score + 
								Player#bd_3v3_player.die_score + 
								25 * OnhookNum / 3,
							data_kf_3v3:get_award_after_report(
								TmpScore * data_kf_3v3:get_multi_award(Player#bd_3v3_player.pk_num),
								Player#bd_3v3_player.report
							)
					end,
					AddScore2 = round(AddScore),

					MaxScore = data_kf_3v3:get_config(max_score),
					MinScore = data_kf_3v3:get_config(min_score),
					NewScore = Player#bd_3v3_player.score + AddScore2,
					NewScore2 = if
						NewScore > MaxScore -> MaxScore;
						NewScore < MinScore -> MinScore;
						true -> NewScore
					end,

					%% pk结果
					[WinOrLose, GoodsNum, _Score, Pt, Exp, DoubleAward] = Player#bd_3v3_player.pk_result,
					Player#bd_3v3_player{
						score = NewScore2,
						pk_result = [WinOrLose, GoodsNum, AddScore2, Pt, Exp, DoubleAward]
					};
				_ ->
					Player
			end
	end.

%% 计算声望
%% @param PlayerListA	赢方队伍玩家列表，格式：[#bd_3v3_player, ...]
%% @param PlayerListB	输队伍玩家列表，格式：[#bd_3v3_player, ...]
%% @return [赢方获得声望，输方扣除声望]
private_count_pt(PlayerListA, PlayerListB) ->
	LenA = length(PlayerListA),
	LenB = length(PlayerListB),

	%% 赢方平均声望
	TotalPtLvA = lists:foldl(fun(PlayerA, TmpPtLvA) ->
		TmpPtLvA + data_kf_3v3:get_pt_lv(PlayerA#bd_3v3_player.player_pt)
	end, 0, PlayerListA),
	AvePtLvA = round(TotalPtLvA / LenA),

	%% 输方平均声望
	TotalPtLvB = lists:foldl(fun(PlayerB, TmpPtLvB) ->
		TmpPtLvB + data_kf_3v3:get_pt_lv(PlayerB#bd_3v3_player.player_pt)
	end, 0, PlayerListB),
	AvePtLvB = round(TotalPtLvB / LenB),

	%% 赢方可增加声望
	TmpAddPtA = round(AvePtLvB * 450 / (AvePtLvB + AvePtLvA * 2)),
	AddPtA = case TmpAddPtA < 0 of
		true -> 1;
		_ -> TmpAddPtA
	end,

	%% 输方扣除声望
	%% 输方平均声望等级*3*(20+输方平均声望等级*5）/（输方平均声望等级+赢方平均声望等级*2）
	AddPtB = round(AvePtLvB * 3 * (20 + AvePtLvB * 5) / (AvePtLvB + AvePtLvA * 2)),

	[AddPtA, AddPtB].

%% pk结束后：为玩家增加声望
%% @param Player		#bd_3v3_player
%% @param WinOrLose		0输1赢
%% @param OldAddPt		添加或扣除的声望
%% @return #bd_3v3_player
private_after_pk_add_pt(Player, OldAddPt, TmpWinOrLose) ->
	case Player#bd_3v3_player.leave of
		2 -> Player;
		_ ->
			WinOrLose = case Player#bd_3v3_player.leave of
				1 -> 0;
				_ -> TmpWinOrLose
			end,
			case Player#bd_3v3_player.pk_num < data_kf_3v3:get_config(pk_limit) of
				true ->
					AddPt = case WinOrLose of
						1 ->
							data_kf_3v3:get_award_after_report(
								OldAddPt * data_kf_3v3:get_multi_award(Player#bd_3v3_player.pk_num),
								Player#bd_3v3_player.report
							);
						_ -> 
							%% 玩家声望等级小于6级，不扣声望
							case data_kf_3v3:get_pt_lv(Player#bd_3v3_player.pt) < 9 of
								true -> 0;
								_ -> 0 - data_kf_3v3:count_lose_pt(Player#bd_3v3_player.vip_lv, OldAddPt)
							end
					end,
					AddPt2 = round(AddPt),

					MaxPt = data_kf_3v3:get_config(max_pt),
					MinPt = data_kf_3v3:get_config(min_pt),
					NewPt = round(Player#bd_3v3_player.pt + AddPt2),
					NewPt2 = if
						NewPt > MaxPt -> MaxPt;
						NewPt < MinPt -> MinPt;
						true -> NewPt
					end,
		
					%% pk结果
					[OldWinOrLose, GoodsNum, Score, _Pt, Exp, OldDoubleAward] = Player#bd_3v3_player.pk_result,
					Player#bd_3v3_player{
						pt = NewPt2,
						pk_result = [OldWinOrLose, GoodsNum, Score, AddPt2, Exp, OldDoubleAward]
					};
				_ ->
					Player
			end
	end.

%% pk结束后：为玩家增加经验
%% @param Player			#bd_3v3_player
%% @param WinOrLose			0输1赢
%% @return #bd_3v3_player
private_after_pk_add_exp(Player, TmpWinOrLose) ->
	case Player#bd_3v3_player.leave of
		2 -> Player;
		_ ->
			WinOrLose = case Player#bd_3v3_player.leave of
				1 -> 0;
				_ -> TmpWinOrLose
			end,
			case Player#bd_3v3_player.pk_num < data_kf_3v3:get_config(pk_limit) of
				true ->
					TmpAddExp = 
					if
						WinOrLose =:= 0 -> data_kf_3v3:count_lose_exp(Player#bd_3v3_player.lv);
						true -> data_kf_3v3:count_win_exp(Player#bd_3v3_player.lv)
					end,
					AddExp = data_kf_3v3:get_award_after_report(
						round(TmpAddExp * data_kf_3v3:get_multi_award(Player#bd_3v3_player.pk_num)),
						Player#bd_3v3_player.report
					),

					%% pk结果
					[OldWinOrLose, GoodsNum, Score, Pt, _Exp, OldDoubleAward] = Player#bd_3v3_player.pk_result,
					Player#bd_3v3_player{
						pk_result = [OldWinOrLose, GoodsNum, Score, Pt, AddExp, OldDoubleAward]
					};
				_ ->
					Player
			end
	end.

%% pk结束后：增加勋章
%% @param Player			#bd_3v3_player
%% @param WinOrLose			0输1赢
%% @param ,OnhookNum		挂机人数
%% @return #bd_3v3_player
private_after_pk_add_goods(Player, TmpWinOrLose, OnhookNum) ->
	case Player#bd_3v3_player.leave of
		2 -> Player;
		_ ->
			WinOrLose = case Player#bd_3v3_player.leave of
				1 -> 0;
				_ -> TmpWinOrLose
			end,
			case Player#bd_3v3_player.pk_num < data_kf_3v3:get_config(pk_limit) of
				true ->
					WinAddNum = data_kf_3v3:get_config(win_goods_num),
					LoseAddNum = data_kf_3v3:get_config(lose_goods_num),
					TmpAddGoodsNum = if
						WinOrLose =:= 0 -> 
							LoseAddNum * (1 + Player#bd_3v3_player.mvp * 0.3) + LoseAddNum * OnhookNum / 2;
						true -> 
							WinAddNum * (1 + Player#bd_3v3_player.mvp * 0.3) + WinAddNum * OnhookNum / 2
					end,
					AddGoodsNum2 = data_kf_3v3:get_award_after_report(
						TmpAddGoodsNum * data_kf_3v3:get_multi_award(Player#bd_3v3_player.pk_num),
						Player#bd_3v3_player.report
					),

					%% pk结果
					[OldWinOrLose, _GoodsNum, Score, Pt, Exp, OldDoubleAward] = Player#bd_3v3_player.pk_result,
					Player#bd_3v3_player{
						goods_num = Player#bd_3v3_player.goods_num + AddGoodsNum2,
						pk_result = [OldWinOrLose, AddGoodsNum2, Score, Pt, Exp, OldDoubleAward]
					};
				_ ->
					Player
			end
	end.

%% 发送pk结果单
private_send_pk_result(State, PlayerListA, PlayerListB, SortPlayerList) ->
	SortBinList = lists:map(fun(SortPlayer) -> 
		Name = pt:write_string(SortPlayer#bd_3v3_player.name),
		OccupyNum = SortPlayer#bd_3v3_player.occupy_num,
		KillNum = SortPlayer#bd_3v3_player.kill_num,
		HelpNum = SortPlayer#bd_3v3_player.help_num,
		DieNum = SortPlayer#bd_3v3_player.die_num,
		Mvp = SortPlayer#bd_3v3_player.mvp,
		EvaScore = data_kf_3v3:eva_score(OccupyNum, KillNum, HelpNum, DieNum),
		Group = SortPlayer#bd_3v3_player.group,
		<<Name/binary, OccupyNum:16, KillNum:16, HelpNum:16, DieNum:16, Mvp:8, EvaScore:32, Group:8>>
	end, SortPlayerList),

	[[OccupyA, _], [OccupyB, _]] = get_occupy_data(State),

	F = fun(Player, Side) -> 
		[OldWinOrLose, GoodsNum, Score, Pt, Exp, DoubleAward] = Player#bd_3v3_player.pk_result,
		case Side of
			1 ->
				{ok, BinData} = pt_484:write(48408, [
					OldWinOrLose, GoodsNum, Score, Pt, Exp, OccupyA, State#pk_state.occupy_a, 
					OccupyB, State#pk_state.occupy_b, SortBinList, DoubleAward
				]);
			_ ->
				{ok, BinData} = pt_484:write(48408, [
					OldWinOrLose, GoodsNum, Score, Pt, Exp, OccupyB, State#pk_state.occupy_b, 
					OccupyA, State#pk_state.occupy_a, SortBinList, DoubleAward
				])
		end,
		mod_clusters_center:apply_cast(Player#bd_3v3_player.node, lib_kf_3v3, game_send_pk_result, [
			Player#bd_3v3_player.id, BinData, Exp
		])
	end,
	[F(PlayerA, 1) || PlayerA <- PlayerListA],
	[F(PlayerB, 2) || PlayerB <- PlayerListB].

%% 正常跑完pk时间结束，判定获胜队伍
%% @return 获胜队伍id，0表示打平手
private_get_win_teamid(State) ->
	[[TeamNumA, TeamValueA], [TeamNumB, TeamValueB]] = get_occupy_data(State),
	if
		TeamNumA > TeamNumB -> State#pk_state.team_id_a;
		TeamNumB > TeamNumA -> State#pk_state.team_id_b;
		true ->
			if
				TeamValueA >= TeamValueB andalso TeamValueA > 0 -> State#pk_state.team_id_a;
				TeamValueB > TeamValueA -> State#pk_state.team_id_b;
				true -> 0
			end
	end.

%% 格式化当前积分前100名排行数据格式
private_player_top_format([], List) -> 
	lists:reverse(List);
private_player_top_format([{_Key, Value} | T], List) ->	
	RankData = #bd_3v3_rank{
		platform = Value#bd_3v3_player.platform,
		server_num = Value#bd_3v3_player.server_num,
		id = Value#bd_3v3_player.id,
		name = Value#bd_3v3_player.name,
		country = Value#bd_3v3_player.country,
		sex = Value#bd_3v3_player.sex,
		career = Value#bd_3v3_player.career,
		lv = Value#bd_3v3_player.lv,
		score = Value#bd_3v3_player.score,
		pk_num = Value#bd_3v3_player.pk_num,
		pk_win_num = Value#bd_3v3_player.pk_win_num
	},
	NewList = [RankData | List],
	private_player_top_format(T, NewList).

%% 匹配对伍核心逻辑
%% 找出与第一个队伍参数相近的最多20个队伍，再随机1个队伍，进入pk
private_match_team_list(One, Tail, State, SleepTime) ->
	{OneTeamNo, [OneNum, OneParam, OnePlayers]} = One,
	ParamGap = data_kf_3v3:get_team_param_gap(OneNum),

	[TargetList, _] = 
	lists:foldl(fun({TeamNo, [Num, Param, Players]}, [TmpTargetList, TmpLimit]) -> 
		case TmpLimit < 20 of
			true ->
				case OneParam + ParamGap >= Param andalso OneParam - ParamGap =< Param of
					true ->
						[[{TeamNo, [Num, Param, Players]} | TmpTargetList], TmpLimit + 1];
					_ ->
						[TmpTargetList, TmpLimit]
				end;
			_ ->
				[TmpTargetList, TmpLimit]
		end
	end, [[], 0], Tail),

	Num = length(TargetList),
	if
		%% 如果1个目标队伍都没有
		Num < 1 ->
			NewState = private_update_team_param(One, State),
			[NewState, Tail];

		%% 从最多20个队伍中，随机取一个队伍出来
		true ->
			TargetOne = util:list_rand(TargetList),
			{TargetOneTeamNo, [_, _, TargetOnePlayers]} = TargetOne,

			%% 将这个队伍从报名表中清除
			NewState1 = private_remove_from_team(OneTeamNo, State),
			NewState2 = private_remove_from_team(TargetOneTeamNo, NewState1),
			Tail2 = lists:delete(TargetOne, Tail),

			%% 开启pk进程
			{ok, PkPid} = mod_kf_3v3_pk:start(NewState2, OnePlayers, TargetOnePlayers, OneTeamNo, TargetOneTeamNo, SleepTime),

			spawn(fun() ->
				%% 计算神坛占领度
				OccupyTime = data_kf_3v3:get_config(occupy_time),
				timer:sleep(OccupyTime * 1000),
				mod_kf_3v3_pk:count_occupy_value(PkPid, OccupyTime, OccupyTime, State#kf_3v3_state.pk_time)
			end),

			spawn(fun() ->
				%% 刷新技能
				SkillTime = data_kf_3v3:get_config(skill_time),
				timer:sleep(SkillTime * 1000),
				mod_kf_3v3_pk:refresh_skill(PkPid, SkillTime, SkillTime, State#kf_3v3_state.pk_time)
			end),

			spawn(fun() -> 
				%% 通知服务结束战斗
				timer:sleep(State#kf_3v3_state.pk_time * 1000),
				mod_kf_3v3_pk:end_each_war(PkPid)
			end),

			%% 将队伍id保存到参赛玩家身上
			NewState3 = private_update_player_before_pk(OnePlayers, NewState2, PkPid),
			NewState4 = private_update_player_before_pk(TargetOnePlayers, NewState3, PkPid),

			[NewState4, Tail2]
	end.

%% 更新队伍报名参数，并回写到状态中
%% 返回：NewState
private_update_team_param(SingleValue, State) ->
	{TeamNo, [Num, _Param, PlayerList]} = SingleValue,
	%% 如果匹配时间已经到5，则不需要再处理，否则需要增加1匹配时间，然后重新计算匹配参数
	case Num < 5 of
		true ->
			%% 计算新的队伍匹配参数
			NewNum = Num + 1,
			NewParam = private_count_team_param(PlayerList, NewNum, State),

			%% 修改单人报名中的参数
			State#kf_3v3_state{
				team_dict = dict:store(TeamNo, [Num + 1, NewParam, PlayerList], State#kf_3v3_state.team_dict)
			};
		_ ->
			State
	end.

%% 将队伍加进队伍报名队列
%% @param PlayerList 	队伍中的玩家列表[[Platform, ServerNum, id], ...]
%% @param MatchingTime 	匹配时间
%% @param State 		状态数据
%% @return 队伍匹配参数
private_count_team_param(PlayerList, MatchingTime, State) ->
	[TotalPower, MaxPower, TotalLv, MaxLv, TotalNum, TotalWinNum] = 
	lists:foldl(fun(DictKey, [TmpTotalPower, TmpMaxPower, TmpTotalLv, TmpMaxLv, TmpTotalNum, TmpTotalWinNum]) -> 
		case dict:fetch(DictKey, State#kf_3v3_state.player_dict) of
			Player when is_record(Player, bd_3v3_player) ->
				NewTmpMaxPower = case Player#bd_3v3_player.max_combat_power >= TmpMaxPower of
					true -> Player#bd_3v3_player.max_combat_power;
					_ -> TmpMaxPower
				end,
				NewTmpMaxLv = case Player#bd_3v3_player.lv >= TmpMaxLv of
					true -> Player#bd_3v3_player.lv;
					_ -> TmpMaxLv
				end,
				[
					TmpTotalPower + Player#bd_3v3_player.max_combat_power,
					NewTmpMaxPower,
					TmpTotalLv + Player#bd_3v3_player.lv,
					NewTmpMaxLv,
					TmpTotalNum + Player#bd_3v3_player.pk_num,
					TmpTotalWinNum + Player#bd_3v3_player.pk_win_num
				];
			_ ->
				[TmpTotalPower, TmpMaxPower, TmpTotalLv, TmpMaxLv, TmpTotalNum, TmpTotalWinNum]
		end
	end, [0, 0, 0, 0, 0, 0], PlayerList),

	data_kf_3v3:count_team_param(TotalPower, MaxPower, TotalLv, MaxLv, TotalNum, TotalWinNum, MatchingTime).

%% 将队伍从报名表中移除
%% @param TeamNo 队伍id
%% @param State	状态数据
%% 返回：NewState
private_remove_from_team(TeamNo, State) ->
	State#kf_3v3_state{
		team_dict = dict:erase(TeamNo, State#kf_3v3_state.team_dict)
	}.

%% 匹配队友列表
private_match_single_list([], State) ->
	State;
private_match_single_list([One | Tail], State) -> 
	%% 开始匹配
	[NewState, NewTail] = private_match_single(One, Tail, State),
	private_match_single_list(NewTail, NewState).

%% 匹配队友核心逻辑
%% 找出与第一个玩家参数相近的最多20个玩家，再随机2个玩家，组成pk队伍
private_match_single(One, Tail, State) ->
	{OneDictKey, [OneNum, OneParam]} = One,
	ParamGap = data_kf_3v3:get_single_param_gap(OneNum),

	[TargetList, _] = 
	lists:foldl(fun({DictKey, [_Num, Param]}, [TmpTargetList, TmpLimit]) -> 
		case TmpLimit < 20 of
			true ->
				case OneParam + ParamGap >= Param andalso OneParam - ParamGap =< Param of
					true ->
						[[DictKey | TmpTargetList], TmpLimit + 1];
					_ ->
						[TmpTargetList, TmpLimit]
				end;
			_ ->
				[TmpTargetList, TmpLimit]
		end
	end, [[], 0], Tail),

	Num = length(TargetList),
	TeamPerson = data_kf_3v3:get_config(team_person),

	if
		%% 如果找不到可以组队的玩家
		Num < TeamPerson - 1 ->
			NewState = private_update_single_param(One, State),
			[NewState, Tail];

		true ->
			if
				TeamPerson == 1 ->
					%% 将这三个从报名表中清除
					NewState1 = private_remove_from_single(OneDictKey, State),
					%% 将三个组成一个队伍，放到队伍匹配表
					NewState4 = private_single_make_team([OneDictKey], NewState1),
					Tail2 = Tail;
				TeamPerson == 2 ->
					[TargetOneSingle | _] = TargetList,
					%% 将这三个从报名表中清除
					NewState1 = private_remove_from_single(OneDictKey, State),
					NewState2 = private_remove_from_single(TargetOneSingle, NewState1),
					%% 将三个组成一个队伍，放到队伍匹配表
					NewState4 = private_single_make_team([OneDictKey, TargetOneSingle], NewState2),
					%% 将这两个玩家从Tail中移除
					Tail2 = private_remove_from_tail(TargetOneSingle, Tail);
				true ->
					[TargetOneSingle, TargetTwoSingle] = private_rand_two_from_list(TargetList),
					%% 将这三个从报名表中清除
					NewState1 = private_remove_from_single(OneDictKey, State),
					NewState2 = private_remove_from_single(TargetOneSingle, NewState1),
					NewState3 = private_remove_from_single(TargetTwoSingle, NewState2),
					%% 将三个组成一个队伍，放到队伍匹配表
					NewState4 = private_single_make_team([OneDictKey, TargetOneSingle, TargetTwoSingle], NewState3),
					%% 将这两个玩家从Tail中移除
					Tail1 = private_remove_from_tail(TargetOneSingle, Tail),
					Tail2 = private_remove_from_tail(TargetTwoSingle, Tail1)
			end,

			[NewState4, Tail2]
	end.

%% 从列表中随机取两个
private_rand_two_from_list(List) ->
	One = util:list_rand(List),
	LeftList = lists:delete(One, List),
	Two = util:list_rand(LeftList),
	[One, Two].

private_remove_from_tail(PlayerDictKey, Tail) ->
	lists:filter(fun({Key, [_Num, _Param]}) -> 
		Key /= PlayerDictKey
	end, Tail).

%% 将三个单独的玩家构造成一个队伍
private_single_make_team(PlayerList, State) ->
	%% 生成队伍号
	TeamNo = mod_kf_3v3_helper:receive_team_no(),

	%% 将队伍加进队伍报名队列
	[NewState, NewPlayerList, TotalPower, MaxPower, TotalLv, MaxLv, TotalNum, TotalWinNum] = 
	lists:foldl(fun(DictKey, [TmpState, TmpPlayerList, TmpTotalPower, TmpMaxPower, TmpTotalLv, TmpMaxLv, TmpTotalNum, TmpTotalWinNum]) -> 
		Player = dict:fetch(DictKey, TmpState#kf_3v3_state.player_dict),
		NewPlayer = Player#bd_3v3_player{
			status = 3,
			team_id = TeamNo
		},
		NewPlayerDict = dict:store(DictKey, NewPlayer, TmpState#kf_3v3_state.player_dict),

		[
			TmpState#kf_3v3_state{player_dict = NewPlayerDict},
			[DictKey | TmpPlayerList],
			TmpTotalPower + Player#bd_3v3_player.max_combat_power, 
			max(Player#bd_3v3_player.max_combat_power, TmpMaxPower),
			TmpTotalLv + Player#bd_3v3_player.lv,
			max(Player#bd_3v3_player.lv, TmpMaxLv),
			TmpTotalNum + Player#bd_3v3_player.pk_num,
			TmpTotalWinNum + Player#bd_3v3_player.pk_win_num
		]
	end, [State, [], 0, 0, 0, 0, 0, 0], PlayerList),

	Param = data_kf_3v3:count_team_param(TotalPower, MaxPower, TotalLv, MaxLv, TotalNum, TotalWinNum, 0),
	NewTeamDict = dict:store(TeamNo, [0, Param, NewPlayerList], NewState#kf_3v3_state.team_dict),

	NewState#kf_3v3_state{
		team_dict = NewTeamDict				  
	}.

%% 更新单个玩家报名参数，并回写到状态中
%% 返回：NewState
private_update_single_param(SingleValue, State) ->
	{DictKey, [Num, _Param]} = SingleValue,

	%% 根据key从玩家列表中找出指定玩家记录
	Player = dict:fetch(DictKey, State#kf_3v3_state.player_dict),
	%% 如果匹配时间已经到5，则不需要再处理，否则需要增加1匹配时间，然后重新计算匹配参数
	case Num < 5 of
		true ->
			NewParam = data_kf_3v3:count_member_param(
				Player#bd_3v3_player.max_combat_power,
				Player#bd_3v3_player.lv,
				Player#bd_3v3_player.pk_num,
				Player#bd_3v3_player.pk_win_num,
				Num + 1
			),

			%% 修改单人报名中的参数
			State#kf_3v3_state{
				single_dict = dict:store(DictKey, [Num + 1, NewParam], State#kf_3v3_state.single_dict)
			};
		_ ->
			State
	end.

%% 将玩家从单人报名表中移除
private_remove_from_single(DictKey, State) ->
	State#kf_3v3_state{
		single_dict = dict:erase(DictKey, State#kf_3v3_state.single_dict)
	}.

%% pk前：更新玩家数据
private_update_player_before_pk(PlayerList, State, PkPid) ->
	lists:foldl(fun(Key, FState) -> 
		Player = dict:fetch(Key, FState#kf_3v3_state.player_dict),
		NewPlayer = Player#bd_3v3_player{
			status = 4,
			leave = 0,
			pk_pid = PkPid
		},
		FState#kf_3v3_state{
			player_dict = dict:store(Key, NewPlayer, FState#kf_3v3_state.player_dict)
		}
	end, State, PlayerList).

%% 构造mvp列表
%% @return [排序后的列表，0为无mvp1为有mvp，mvp玩家#bd_3v3_player]
private_formate_mvp_list(PlayerListA, PlayerListB) ->
	List = PlayerListA ++ PlayerListB,
	List2 = lists:sort(fun(Player1, Player2) -> 
		EvaScore1 = data_kf_3v3:eva_score(Player1#bd_3v3_player.occupy_num, Player1#bd_3v3_player.kill_num, Player1#bd_3v3_player.help_num, Player1#bd_3v3_player.die_num),
		EvaScore2 = data_kf_3v3:eva_score(Player2#bd_3v3_player.occupy_num, Player2#bd_3v3_player.kill_num, Player2#bd_3v3_player.help_num, Player2#bd_3v3_player.die_num),
		EvaScore1 > EvaScore2
	end, List),
	[TargetPlayer| _] = List2,

	MvpStat = [TargetPlayer#bd_3v3_player.occupy_num, TargetPlayer#bd_3v3_player.kill_num, TargetPlayer#bd_3v3_player.help_num, TargetPlayer#bd_3v3_player.die_num],
	case MvpStat of
		[0, 0, 0, 0] -> 
			[List2, 0, TargetPlayer];
		_ ->
			TargetPlayer2 = TargetPlayer#bd_3v3_player{
				mvp = 1,
				mvp_num = TargetPlayer#bd_3v3_player.mvp_num + 1
			},
			SortList = lists:map(fun(SortPlayer) -> 
				case [SortPlayer#bd_3v3_player.platform, SortPlayer#bd_3v3_player.server_num, SortPlayer#bd_3v3_player.id] =:= 
					[TargetPlayer#bd_3v3_player.platform, TargetPlayer#bd_3v3_player.server_num, TargetPlayer#bd_3v3_player.id] of
					true ->
						SortPlayer#bd_3v3_player{
							mvp = 1,
							mvp_num = SortPlayer#bd_3v3_player.mvp_num + 1
						};
					_ ->
						SortPlayer
				end
			end, List2),
			[SortList, 1, TargetPlayer2]
	end.

%% 找出mvp
%% @return [NewState, 排序后的玩家列表]
private_get_mvp(State) ->
	%% 找出两个队伍参与的玩家
	TmpPlayerListA = [get_player_from_dict(PlayerKeyA, State#pk_state.player_dict) || PlayerKeyA <- State#pk_state.players_a],
	TmpPlayerListB = [get_player_from_dict(PlayerKeyB, State#pk_state.player_dict) || PlayerKeyB <- State#pk_state.players_b],
	[SortList, MvpResult, MvpPlayer] = private_formate_mvp_list(TmpPlayerListA, TmpPlayerListB),
	NewState = case MvpResult of
		1 ->
			MvpKey = [MvpPlayer#bd_3v3_player.platform, MvpPlayer#bd_3v3_player.server_num, MvpPlayer#bd_3v3_player.id],
			State#pk_state{
				player_dict = dict:store(MvpKey, MvpPlayer, State#pk_state.player_dict)
			};
		_ ->
			State
	end,
	[NewState, SortList].

%% 获取挂机人数
private_get_onhook_num(PlayerList) ->
	lists:foldl(fun(Player, Num) ->
		case Player#bd_3v3_player.leave =:= 2 of
			true -> Num + 1;
			_ -> Num
		end
	end, 0, PlayerList).

%% 格式化pk场景中排行数据
private_format_pk_sort(PlayerList) ->
	lists:map(fun(Player) -> 
		Platform = pt:write_string(Player#bd_3v3_player.platform),
		ServerNum = Player#bd_3v3_player.server_num,
		Id = Player#bd_3v3_player.id,
		Name = pt:write_string(Player#bd_3v3_player.name),
		EvaScore = data_kf_3v3:eva_score(Player#bd_3v3_player.occupy_num, Player#bd_3v3_player.kill_num, Player#bd_3v3_player.help_num, Player#bd_3v3_player.die_num),
		Report = Player#bd_3v3_player.report,
		Group = Player#bd_3v3_player.group,
		<<Platform/binary, ServerNum:16, Id:32, Name/binary, EvaScore:32, Report:16, Group:8>>
	end, PlayerList).

%% 将玩家传送入战斗场景
%% @param Side	1为红方A，2为蓝方B
private_move_to_pk_scene(Side, Player, State, SortBinList, SceneId, CopyId, X, Y) ->
	StatusResult = case Side of
		1 ->
			case Player#bd_3v3_player.status =:= ?KF_PLAYER_TEAM andalso Player#bd_3v3_player.team_id > 0 andalso 
				Player#bd_3v3_player.team_id =:= State#pk_state.team_id_a of
				true ->	true;
				_ -> false
			end;
		_ ->
			case Player#bd_3v3_player.status =:= ?KF_PLAYER_TEAM andalso Player#bd_3v3_player.team_id > 0 andalso 
				Player#bd_3v3_player.team_id =:= State#pk_state.team_id_b of
				true ->	true;
				_ -> false
			end
	end,

	case StatusResult of
		true ->
			%% 排队进入场景
			mod_clusters_center:apply_cast(Player#bd_3v3_player.node, lib_scene, player_change_scene_queue, [
				Player#bd_3v3_player.id, SceneId, CopyId, X, Y, [{resume_hp_lim, ok}, {group, Side}]
			]),

			%% 刷新右手边数据
			private_refresh_pk_info(Side, Player, State, SortBinList),

			%% 更新玩家ps数据，将所属A方或B方记到ps中，方便复活时知道要在哪个坐标点出现
			mod_clusters_center:apply_cast(
				Player#bd_3v3_player.node,
				lib_player,
				update_player_info,
				[Player#bd_3v3_player.id, [{kf_3v3_pk, Side}]]
			);
		_ ->
			skip
	end.

%% 刷新战斗区右边数据
private_refresh_pk_info(Side, Player, State, SortBinList) ->
	TmpLeftTime = State#pk_state.start_time + State#pk_state.pk_time - util:unixtime(),
	LeftTime = case TmpLeftTime < 0 of
		true -> 0;
		_ -> TmpLeftTime
	end,
	[[OccupyNumA, OccupyValueA], [OccupyNumB, OccupyValueB]] = get_occupy_data(State),
	case Side of
		1 -> {ok, BinData} = pt_484:write(48412, [LeftTime, OccupyNumA, OccupyValueA, OccupyNumB, OccupyValueB, SortBinList]);
		_ -> {ok, BinData} = pt_484:write(48412, [LeftTime, OccupyNumB, OccupyValueB, OccupyNumA, OccupyValueA, SortBinList])
	end,
	mod_clusters_center:apply_cast(Player#bd_3v3_player.node, lib_unite_send, cluster_to_uid, [
		Player#bd_3v3_player.id, BinData
	]).

%% pk结束后：将玩家传送到指定场景
private_move_player_after_pk(State, Player, OldPlayer) ->
	MoveFun = fun(MoveNode, MoveId, MoveSceneId, MoveCopyId, MoveX, MoveY) -> 
		mod_clusters_center:apply_cast(MoveNode, lib_scene, player_change_scene_queue, [
			MoveId, MoveSceneId, MoveCopyId, MoveX, MoveY, [{group, 0}, {soul_pk_change, 0}]
		])
	end,

	F = fun(FunPlayer, FunOldPlayer, FunSceneId, FunCopyId, FunX, FunY) -> 
		case FunOldPlayer#bd_3v3_player.status =:= ?KF_PLAYER_PK of
			%% 传到指定场景
			true ->
				MoveFun(FunPlayer#bd_3v3_player.node, FunPlayer#bd_3v3_player.id, FunSceneId, FunCopyId, FunX, FunY);
			%% 中间可能是掉线刷新，或挂机被踢，已经退出pk场景，所以这里不需要处理
			_ ->
				skip
		end
	end,

	case State#kf_3v3_state.status =:= ?KF_3V3_STATUS_ACTION of
		%% 传到跨服准备区
		true ->
			spawn(fun()->
				SceneId = data_kf_3v3:get_config(scene_id1),
				[X, Y] = data_kf_3v3:get_position1(),
				F(Player, OldPlayer, SceneId, Player#bd_3v3_player.copy_id, X, Y)
			end);

		%% 传到长安
		_ ->
			spawn(fun()->
				[SceneId, X, Y] = data_kf_3v3:get_config(leave_scene),
				F(Player, OldPlayer, SceneId, 0, X, Y)
			end)
	end.
