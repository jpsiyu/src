%%%--------------------------------------
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3头文件
%%%--------------------------------------

%% 活动状态：0未开始，1活动中，4结束
-define(KF_3V3_STATUS_NO_START, 0).
-define(KF_3V3_STATUS_ACTION, 1).
-define(KF_3V3_STATUS_STOP, 4).
%% 玩家状态：0不在准备区，1在准备区，2单人报名匹配中，3队伍匹配中，4pk中
-define(KF_PLAYER_NOT_IN_PREPARE, 0).
-define(KF_PLAYER_IN_PREPARE, 1).
-define(KF_PLAYER_SINGLE, 2).
-define(KF_PLAYER_TEAM, 3).
-define(KF_PLAYER_PK, 4).
%% 守护神怪id
-define(KF_GUARDER_A, 25304).
-define(KF_GUARDER_B, 25305).
%% 技能怪id
-define(KF_3V3_SKILL_1, 25306).
-define(KF_3V3_SKILL_2, 25307).
-define(KF_3V3_SKILL_3, 25308).

%% 跨服节点进程状态，保存了活动核心数据
-record(kf_3v3_state, {
	loop = 0,					%% 当前场次
	status = 0,					%% 0还未开启  1开启报名中 4已结束
	pk_time = 0,				%% 每场战斗持续时长（秒）
	start_time = 0,				%% 本场活动开始时间
	end_time = 0,	 		 	%% 本场活动结束时间
	room_no = 1,				%% 房间号，每满指定人数，房间号+1
	room_num = 0,				%% 房间人数
	player_dict = dict:new(), 	%% 玩家列表:(key:[平台,服务器id,玩家Id]  value：#bd_3v3_player)
	single_dict = dict:new(),	%% 单人匹配列表:(key:[平台,服务器id,玩家Id] value:[匹配时间，参数])
	team_dict = dict:new()		%% 队伍匹配报名:(key:队伍id value:[匹配时间,参数,[[平台,服务器id,玩家Id], ...]]）
}).

%% 3v3 pk核心数据
-record(pk_state, {
	team_id_a = 0,
	team_id_b = 0,
	win_team_id = 0,	%% 胜利队伍id
	players_a = [],		%% [[Platform, ServerNum, Id], ...]
	players_b = [],
	player_dict = dict:new(),
	occupy_a = 0,		%% 占领值
	occupy_b = 0,		%% 占领值
	mon_1 = 0,			%% 神坛1
	mon_2 = 0,			%% 神坛2
	mon_3 = 0,			%% 神坛3
	skill_1 = [0, 0],	%% 技能1 伤害加成,怪物id:25306, 值为[X,Y]为坐标，[0, 0]表示该技能被使用了
	skill_2 = [0, 0],	%% 技能2 回血,怪物id:25307
	skill_3 = [0, 0],	%% 技能3 加速,怪物id:25308
	start_time = 0,		%% 开始战斗时间
	activity_end_time = 0,	%% 活动结束时间
	pk_time = 0,		%% 战斗时间（秒）
	scene_id = 0,		%% 场景id
	copy_id = 0,		%% 战斗场景copyid
	kill_dict = dict:new()	%% 杀人统计，格式：[平台,服务器id,玩家Id] => {最后一次杀人时间, 最后一次杀的人id}
}).

%% 玩家数据
-record(bd_3v3_player, {
	platform = "",		%% 平台标识
	server_num = 0,		%% 服务器id
	node = none,		%% 玩家所在节点
	id = 0,				%% 玩家Id
	name = "",			%% 玩家名称
	country = 0,		%% 玩家国家
	career = 0,			%% 职业
	sex = 0,			%% 性别
	image = 0,			%% 头像
	lv = 0,				%% 等级
	vip_lv = 0,			%% vip等级
	combat_power = 0,	%% 玩家战力
	max_combat_power = 0,%% 玩家最高战力

	status =  1,		%% 0不在准备区，1在准备区，2已经报名待匹配队友，3已经入队待匹配对手，4战斗中
	leave = 0,			%% 离开状态，掉线或挂机离开pk场景后，刷新掉线为1，挂机为2
	pk_num = 0,			%% [当天]参与pk次数
	pk_win_num = 0,		%% [当次]参与pk获胜次数
	pk_lose_num = 0,	%% [当次]参与pk失败次数
	goods_num = 0,		%% 可以获得勋章的数量
	player_pt = 0,		%% 玩家跨服声望
	pt = 0,				%% 本轮声望
	score = 1000,		%% 本轮积分
	copy_id = 0,		%% 准备区副本Id
	team_id = 0,		%% 队伍id(这是在mod_kf_3v3进程中自增长的队伍id)
	pk_pid,				%% pk进程id
	group = 0,			%% 分组，值有1和2
	pk_result = [0, 0, 0, 0, 0, 0],%% pk结果单，格式：[胜利1或失败0, 勋章, 积分, 声望, 经验, 是否双倍奖励]
	cd_end_time = 0,	%% CD结束时间，非法退出pk状态中的玩家，需要在CD时间之后才能继续报名
	onhook = 0,			%% 挂机次数
	occupy_num = 0,		%% 占领数
	occupy_score = 0,	%% 占领积分
	kill_num = 0,		%% 击杀数
	kill_score = 0,		%% 击杀积分
	help_num = 0,		%% 助攻数
	help_score = 0,		%% 助攻积分
	die_num = 0,		%% 被杀数
	die_score = 0,		%% 被杀数据
	mvp = 0,			%% 是否mvp
	mvp_num = 0,		%% 成为mvp的次数
	report = 0,			%% 当场pk举报次数
	total_report = 0	%% 被举报总次数
}).

%% 3v3当前轮比赛积分排行榜玩家数据
-record(bd_3v3_rank, {
	platform = "",
	server_num = 0,
	id = 0,
	name = [],
	country = 0,
	sex = 0,
	career = 0,
	lv = 0,
	score = 0,
	pk_num = 0,
	pk_win_num = 0
}).

%% 3v3当前轮对阵表双方玩家数据
-record(bd_3v3_fight, {
	result = 0,			%% 对阵结果，1赢，2输
	player_a = [],		%% 格式：[[Platform, ServerNum, Id, Name, Country, Sex, Career, Lv]]
	player_b = []
}).

%% 协助进程状态数据
-record(helper_state, {
	team_no = 1,				%% 队伍id，分每个队伍分配一个唯一的队伍id
	pk_log_dict = dict:new(),	%% 对阵日志，格式：key => [Platform, ServerNum, Id], value => [#bd_3v3_fight, ...]
	score_dict = [[], 0]		%% 积分前100名数据，格式：[数据列表, 更新时间]
}).

-define(SQL_KF_3V3_SELECT, <<"SELECT pt, mvp, kf3v3_pk_num, kf3v3_pk_win FROM player_kf_1v1 WHERE id=~p">>).
-define(SQL_KF_3V3_INSERT, <<"INSERT INTO player_kf_1v1 SET id=~p,pt=~p,mvp=~p,kf3v3_pk_num=~p,
	kf3v3_pk_win=~p,kf3v3_report=~p,last_time=~p">>).
-define(SQL_KF_3V3_UPDATE, <<"UPDATE player_kf_1v1 SET pt=~p,mvp=mvp+~p,kf3v3_pk_num=kf3v3_pk_num+~p,
	kf3v3_pk_win=kf3v3_pk_win+~p,kf3v3_report=~p,last_time=~p WHERE id=~p">>).
-define(SQL_KF_3V3_REPORT_NUM, <<"SELECT `kf3v3_report` FROM player_kf_1v1 WHERE id=~p">>).
-define(SQL_KF_3V3_CLEAN_DATA, <<"UPDATE player_kf_1v1 SET mvp=0, kf3v3_pk_num=0, kf3v3_pk_win=0">>).
-define(SQL_KF_3V3_CLEAN_REPORT, <<"UPDATE player_kf_1v1 SET `kf3v3_report`=0 WHERE id>0">>).

%% 本服3v3周积分排行榜相关
-define(SQL_BD_3V3_RANK_GET, <<"SELECT pt,score,win,lose FROM rank_bd_3v3 WHERE id=~p">>).
-define(SQL_BD_3V3_RANK_INSERT, <<"INSERT INTO rank_bd_3v3 SET id=~p,pt=~p,score=~p,win=~p,lose=~p,last_time=~p">>).
-define(SQL_BD_3V3_RANK_UPDATE, <<"UPDATE rank_bd_3v3 SET pt=~p,score=score+~p,win=win+~p,lose=lose+~p,last_time=~p WHERE id=~p">>).
-define(SQL_BD_3V3_RANK_SELECT, <<"SELECT pl.id, pl.nickname, pl.realm, pl.career, pl.sex, pl.lv,
	bd.pt, bd.score, bd.win, bd.lose FROM rank_bd_3v3 AS bd LEFT JOIN player_low AS pl ON bd.id=pl.id
	ORDER BY bd.score DESC LIMIT ~p">>).
-define(SQL_BD_3V3_RANK_ID, <<"SELECT id FROM rank_bd_3v3 WHERE score>~p ORDER BY score DESC">>).
-define(SQL_BD_3V3_RANK_TRUNCATE, <<"TRUNCATE TABLE rank_bd_3v3">>).

