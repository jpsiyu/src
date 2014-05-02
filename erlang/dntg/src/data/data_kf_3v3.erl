%%%--------------------------------------
%%% @Module : data_kf_3v3
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3配置
%%%--------------------------------------

-module(data_kf_3v3).
-include("kf_3v3.hrl").
-compile(export_all).

get_config(Type) ->
	case Type of
		%% 开放日期
		%open_day -> [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];
        %% 3v3诸天争霸时间暂停开启
        open_day -> [5,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];
		%% 开放时间
		open_time-> [[14, 1], [21, 1]];
		%% TODO
%%		open_time-> [[14, 1]];
		%% 活动时长(秒)
		activity_time -> 3540;
		%% 每场战斗耗时(秒)
		pk_time -> 300;
		%% 队伍人数要求
		team_person -> 3;
		%% TODO
%% 		team_person -> 2;
		%% 挂机开关，1为开，0为关
		onhook_switch -> 1;
		%% TODO
%% 		onhook_switch -> 0;
		%% 挂机判断，如果小于指定值，则认定为挂机，格式：[占领数，杀人数，助攻数据，被杀数]
		onhook_match -> [1, 1, 1, 3];
		%% 匹配时间延迟，在弹出活动开始面板后延迟30秒才开始进行匹配
		matching_delay -> 20;
		%% 每次匹配间隔时间
		matching_time -> 20;
		%% CD时间(秒)，在PK状态中非法退出比赛，需要等待指定时间后才能继续报名
		cd_time -> 300;
		%% TODO
%% 		cd_time -> 120;
		%% 每天前15场有奖励
		pk_limit -> 15;
		%% 被举报次数达到后无法单独报名
		report_deny_single_signup -> 80;
		%% TODO
%% 		report_deny_single_signup -> 20;
		%% 举报时，如果玩家在第N分钟的评分少于下面值，则举报可成功，下面分别为第2~5分钟的配置
		report_conf -> [10, 20, 30, 40];
		%% 计算占领神坛占有值秒数
		occupy_time -> 12;
		%% 每次增加10点占领值
		occupy_value -> 10;
		%% TODO
%% 		occupy_value -> 20;
		%% 占领到500才胜利 
		occupy_max -> 500;
		%% 三个神坛坐标
		occupy_xy -> [[10, 58], [33, 36], [51, 17]];
		%% 守护神怪物id及坐标: A方[怪物id, X, Y, 阵营标识]，B方
		guarder_list -> [[?KF_GUARDER_A, 19, 18, 1], [?KF_GUARDER_B, 50, 56, 2]];
		%% 技能随机点
		skill_list -> [[39,30],[40,45],[26,45],[26,31],[13,37],[54,40],[22,22],[47,51],[60,26],[3,61],[31,61],[38,10]];
		%% 技能刷新时间
		skill_time -> 30;
		%% 准备区场景id
		scene_id1 -> 252;
		%% 准备区进入坐标
		position1 -> [[54, 45], [69, 60], [68, 45], [53, 60]];
		%% 战斗区场景id
		scene_pk_ids -> [253, 254, 255, 256];
		%% 战斗区双方进入坐标，A方坐标，B方坐标
		position2 -> [[19, 20], [50, 58]];
		%% 离开3v3的位置[场景类型ID, X坐标, Y坐标]
		leave_scene -> [102, 118, 148];
		%% 胜利、失败或获得的竞技勋章数量
		win_goods_num -> 30;
		lose_goods_num -> 10;
		%% 前3场2倍奖励
		multi_num -> 3;
		multi_award -> 2;
		%% 开启房间人口上限
		room_max_num -> 80;
		%% 勋章Id
		xunzhang_id -> 523501;
		%% 达标mvp次数
		daobiao_num -> 5;
		%% 本场积分前100名缓存时间
		top_score_cache -> 300;
		%% 杀人，被杀，助攻，占领
		max_pt -> 1000;
		min_pt -> -500;
		min_score -> 500;
		max_score -> 3500;

		%% 杀人积分上限
		kill_score_max -> 30;
		%% 每次杀人积分
		kill_score_each -> 10;
		help_score_max -> 20;
		help_score_each -> 5;
		die_score_max -> 10;
		die_score_each -> 2;
		occupy_score_max -> 30;
		cooupy_score_each -> 15;

		%% 玩家要求：等级
		min_lv -> 50;
		%% 玩家要求：战力
		min_power -> 7000;
		%% 开服天数
		min_open_server -> 1;
		%% 发放本地周积分榜奖励需要的积分要求
		bd_rank_award_score -> 2000;

		_ -> void
	end.

%% 随机取一个pk场景id
get_rand_pk_sceneid() ->
	List = get_config(scene_pk_ids),
	util:list_rand(List).

%% 获取多倍奖励
get_multi_award(PkNum) ->
	case PkNum < get_config(multi_num) of
		true -> get_config(multi_award);
		_ -> 1
	end.

%% 获取技能id
get_all_skill_id() -> [25306, 25307, 25308].

%% 获取所有的神坛怪物id
get_occupy_ids() -> 
	[25301, 25302, 25303, 25311, 25312, 25313, 25314, 25315, 25316].

%% 获取神坛怪物id
%% @param 神坛i编号,为1,2,3
%% @param 占领方,0为默认, 1为红方A, 2为蓝方B
get_monid_by_occupy(1, 0) -> 25301;
get_monid_by_occupy(1, 1) -> 25311;
get_monid_by_occupy(1, 2) -> 25314;
get_monid_by_occupy(2, 0) -> 25302;
get_monid_by_occupy(2, 1) -> 25312;
get_monid_by_occupy(2, 2) -> 25315;
get_monid_by_occupy(3, 0) -> 25303;
get_monid_by_occupy(3, 1) -> 25313;
get_monid_by_occupy(3, 2) -> 25316;
get_monid_by_occupy(_, _) -> 0.

%% 通过神坛怪物id获得是哪个神坛
get_occupy_by_monid(25301) -> 1;
get_occupy_by_monid(25311) -> 1;
get_occupy_by_monid(25314) -> 1;
get_occupy_by_monid(25302) -> 2;
get_occupy_by_monid(25312) -> 2;
get_occupy_by_monid(25315) -> 2;
get_occupy_by_monid(25303) -> 3;
get_occupy_by_monid(25313) -> 3;
get_occupy_by_monid(25316) -> 3.

%% 队友匹配参数差距
get_single_param_gap(0) -> 3000;
get_single_param_gap(1) -> 5000;
get_single_param_gap(2) -> 8000;
get_single_param_gap(3) -> 12000;
get_single_param_gap(4) -> 18000;
get_single_param_gap(5) -> 30000;
get_single_param_gap(_) -> 30000.

%% 队伍匹配参数差距
get_team_param_gap(0) -> 2000;
get_team_param_gap(1) -> 4000;
get_team_param_gap(2) -> 8000;
get_team_param_gap(3) -> 15000;
get_team_param_gap(4) -> 60000;
get_team_param_gap(5) -> 100000;
get_team_param_gap(_) -> 100000.

%% 获取声望等级
%% @param Pt 声望
%% @return 等级
get_pt_lv(Pt) ->
	List = [
		[1, 0, 699],
		[2, 700, 2599],
		[3, 2600, 6099],
		[4, 6100, 11449],
		[5, 12000, 18949],
		[6, 20000, 28749],
		[7, 30000, 41099],
		[8, 43000, 56199],
		[9, 58000, 74199],
		[10, 76000, 95299],
		[11, 98000, 119649],
		[12, 123000, 161999],
		[13, 165000, 208999],
		[14, 212000, 261999],
		[15, 265000, 338999],
		[16, 342000, 423999],
		[17, 427000, 517999],
		[18, 521000, 9999999]
	],
	private_get_pt_lv(List, Pt).

private_get_pt_lv([], _Pt) -> 1;
private_get_pt_lv([[Lv, Min, Max] | Tail], Pt) ->
	case Pt >= Min andalso Pt =< Max of
		true -> Lv;
		_ -> private_get_pt_lv(Tail, Pt)
	end.

%% 随机获取一个进入准备区坐标点
get_position1() ->
	PosList = get_config(position1),
	Pos = util:rand(1, length(PosList)),
	lists:nth(Pos, PosList).

%% 计算队友匹配参数
%% 玩家历史战力小于等于 40000 时，用下面公式：
%%		队友匹配参数=历史战力+等级*200+胜率（百分比）*2000+队友匹配时间*500 + (胜利次数*2 - 总次数)*200
%% 玩家历史战力大于 40000 时，用以下公式
%% 		队友匹配参数=历史战力+等级*100+胜率（百分比）*1000+队友匹配时间*250
count_member_param(HistoryPower, Lv, TotalNum, WinNum, MatchingTime) ->
	%% 算出胜率
	WinRate = case TotalNum =:= 0 of
		true -> 0;
		_ -> WinNum / TotalNum
	end,
	case HistoryPower =< 40000 of
		true ->
			round(HistoryPower + Lv * 200 + WinRate * 2000 + MatchingTime * 500 + (WinNum * 2 - TotalNum) * 200);
		_ ->
			round(HistoryPower + Lv * 200 + WinRate * 1000 + MatchingTime * 250)
	end.

%% 计算队手匹配参数
%% 玩家历史战力小于等于 40000 时，用下面公式：
%%		队友匹配参数=平均历史战力+平均等级*200+平均胜率（百分比）*2000+对手匹配时间*500 + (平均胜利次数*2 - 平均总次数)*200
%% 玩家历史战力大于 40000 时，用以下公式
%% 		队友匹配参数=平均历史战力+平均等级*100+平均胜率（百分比）*1000+对手匹配时间*250
count_team_param(TotalPower, MaxPower, TotalLv, MaxLv, AllNum, AllWinNum, MatchingTime) ->
	%% 取平均历史最高战力
	TmpHistoryPower = TotalPower / 3,
	HistoryPower = case MaxPower - TmpHistoryPower > 8000 of
		true ->	MaxPower;
		_ -> TmpHistoryPower
	end,

	%% 取平均等级
	TmpLv = TotalLv / 3,
	Lv = case MaxLv - TmpLv > 5 of
		true -> MaxLv;
		_ -> TmpLv
	end,

	TotalNum = AllNum / 3,
	WinNum = AllWinNum / 3,
	
	%% 算出胜率
	WinRate = case TotalNum =< 0 of
		true -> 0;
		_ -> WinNum / TotalNum
	end,
	case HistoryPower =< 40000 of
		true ->
			round(HistoryPower + Lv * 200 + WinRate * 2000 + MatchingTime * 500 + (WinNum * 2 - TotalNum) * 200);
		_ ->
			round(HistoryPower + Lv * 200 + WinRate * 1000 + MatchingTime * 250)
	end.

%% 计算赢方可获得积分
%% @param OccupyValueA	赢方占领值
%% @param OccupyValueB	输方占领值
count_win_score(OccupyValueA, OccupyValueB) ->
	%% 200*［1+（赢占领值-输占领值）/2000］
	round(200 * (1 + (OccupyValueA - OccupyValueB) / 2000)).

%% 计算赢方可获得经验
%% @param Lv	玩家经验
count_win_exp(Lv) ->
	%% 等级*等级*60
	Lv * Lv * 60.

%% 计算赢方可获得经验
%% @param Lv	玩家经验
count_lose_exp(Lv) ->
	%% 等级*等级*20
	Lv * Lv * 20.

%% 输方扣除声望根据vip等级略有下调
count_lose_pt(VipLv, Score) ->
	List = [{0, 0}, {1, 0.05}, {2, 0.1}, {3, 0.15}, {4, 0.2}, {5, 0.25}, {6, 0.3}, {7, 0.35}, {8, 0.4}, {9, 0.45}, {10, 0.5}],
	case lists:keyfind(VipLv, 1, List) of
		false -> 
			Score;
		{_Lv, Rate} -> 
			Score * (1- Rate)
	end.

%% 获取评分
eva_score(Occupy, Kill, Helper, _Die) ->
	Occupy * 15 + Kill * 10 + Helper * 5.

%% 举报次数对奖励的影响
get_award_after_report(Award, ReportNum) ->
	TupleList = [{2, 0.75}, {3, 0.5}, {4, 0.25}, {5, 0}],
	case lists:keyfind(ReportNum, 1, TupleList) of
		false -> round(Award);
		{_, Rate} -> round(Award * Rate)
	end.

%% 每场比赛结束后减举报次数
sub_report(Score, Mvp) ->
	case Mvp > 0 of
		%% 是MVP,则举报次数减3次
		true -> 3;
		_ ->
			if
				Score >= 100 -> 3;
				Score >= 75 -> 2;
				Score >= 50 -> 1;
				true -> 0
			end
	end.

%% 是否可以清掉玩家被举报次数数据
is_can_clean_report_data() ->
	CleanDay = [1, 15],
	{_, _, Day} = date(),
	lists:member(Day, CleanDay).
