%% ---------------------------------------------------------
%% Author:  zhenghehe
%% Created: 2012-2-2
%% Description: 副本 ets
%% --------------------------------------------------------

-define(DUNGEON_LOG_KEY(Id), lists:concat(["dungeon_log_", Id])). 	%% 副本日志.
-define(DUNGEON_EQUIP_LOG_KEY(Id), lists:concat(["dungeon_equip_log_", Id])). 	%% 装备副本日志.
-define(DUNGEON_RECORD, dungeon_record).                            %% 副本记录.                 

%% 副本类型定义.
-define(DUNGEON_TYPE_NORMAL, 0).     %% 普通副本.
-define(DUNGEON_TYPE_STORY, 1).      %% 剧情副本.
-define(DUNGEON_TYPE_COIN, 2).       %% 铜币副本.
-define(DUNGEON_TYPE_PET, 3).        %% 宠物副本.
-define(DUNGEON_TYPE_EXP, 4).        %% 经验副本.
-define(DUNGEON_TYPE_TOWER, 5).      %% 爬塔副本.
-define(DUNGEON_TYPE_NEWER_PET, 6).  %% 新手宠物副本.
-define(DUNGEON_TYPE_KINGDOM_RUSH, 7).  %% 皇家守卫军塔防副本.
-define(DUNGEON_TYPE_MULTI_KING, 8).    %% 多人皇家守卫军塔防副本.
-define(DUNGEON_TYPE_LIAN, 9).          %% 连连看副本.
-define(DUNGEON_TYPE_FLY, 10).          %% 飞行副本.
-define(DUNGEON_TYPE_ACTIVITY, 11).     %% 活动副本.
-define(DUNGEON_TYPE_DNTK_EQUIP, 20).        %% 大闹天空装备副本

%% 所有副本.
-define(DUNGEON_LIST, [233,300,500,561,562,563,564,565,566,567,568,569,570,
					   571,572,573,574,575,576,577,578,579,580,630,650,900,
					   910]).

%% 断线重连的副本场景ID.
-define(BACK_DUNGEON_LIST, [224,225,226,227,230,233,234,630,650,
							340,341,342,343,344,345,346,347,348,349,
							350,351,352,353,354,355,356,357,358,359,
							360,361,362,363,364,365,368,366,367,373,
							369,370,371,372,374,375]).

%% 副本退出类型定义.
-define(DUN_EXIT_CLICK_BUTTON, 1).  %% 1.玩家点击退出按钮,
-define(DUN_EXIT_NO_TIME, 2).       %% 2.副本时间结束.
-define(DUN_EXIT_PLAYER_LOGOUT, 3). %% 3.玩家下线.
-define(DUN_EXIT_OTHER, 4).         %% 4.异常退出.
-define(DUN_EXIT_PRINCESS_DIE, 5).  %% 5.塔防副本龙儿死掉.
-define(DUN_EXIT_CLICK_BUTTON_TRY_AGAIN, 10).    %% 6.副本点击再来一下


%% --------------------------------- 基本副本 ----------------------------------

%% 副本数据
-record(dungeon, {
    id = 1,                      %% 副本id
    name = <<"">>,               %% 副本名称
    def = 0,                     %% 进入副本的默认场景
    npc = 0,                     %% npcid
    time = 0,                    %% 限制时间
    count = 0,                   %% 次数
    out = {0, 0, 0},             %% 传出副本时场景和坐标{场景id, x, y}
    condition = [],              %% 副本进入条件
    scene = [],                  %% 整个副本所有的场景 {场景id, 是否激活}  只有激活的场景才能进入
    requirement = [],            %% 场景的激活条件    [影响场景, 是否完成, kill, npcId, 需要数量, 现在数量]
    kill_npc = [],               %% 击杀怪物统计    [影响场景, 是否完成, kill, npcId, 需要数量, 现在数量]
    type = 0,                    %% 副本类型[0普通副本,1剧情副本，2铜币副本，3宠物副本，4经验副本，5爬塔副本].
	enter_time = []              %% 时间限制[开始时间，结束时间].
}).

%% 副本服务状态信息.
-record(dungeon_state, {
    begin_sid = 0,               %% 副本开始场景资源id
    team_pid = 0,                %% 队伍进程id
    time = 0,                    %% 副本开始时间
    role_list = [],              %% 玩家列表.
    scene_requirement_list = [], %% 场景激活条件列表
    kill_npc = [],               %% 击杀怪物统计    [影响场景, 是否完成, kill, npcId, 需要数量, 现在数量]
	kill_npc_flag = 0,           %% 是否请求了击杀怪物统计.
    scene_list = [],             %% 场景列表
    level = 1,                   %% 等级
    tower_state = 0,             %% 塔状态
    active_scene = 0,            %% 跳的场景
    appoint_state = {0, 0},      %% {情缘副本状态(1..3:第1到第3波，4:boss波), 所杀怪数}
    appoint_mon_name_list = [],  %% 情缘副本怪物名字列表
	think_count = 1,             %% 宠物副本想法次数.
	think_timer = 0,             %% 宠物副本想法定时器进程ID.
	random_timer = 0,            %% 随机变身定时器进程ID.
	turn_back_timer = 0,         %% 变身还原定时器进程ID.
    coin_dun = [],               %% 钱多多副本记录record() = #coin_dun{}
    exp_dun  = [],               %% 经验副本记录record() = #exp_dun{}
	kill_mon_count = 0,          %% 杀怪数量
	out_scene = [102,111,135],   %% 传去的场景和坐标（剧情副本用）
	type = 0,                    %% 副本类型[0普通副本,1剧情副本，2铜币副本，3宠物副本，4经验副本，5爬塔副本].
    close_timer = [],            %% 副本结束定时器timerRef
	whpt = 0,                    %% 武魂值，剧情副本杀死BOSS获得武魂值.
	is_send_record = true,       %% 是否发送副本通关记录给客户端.
    is_die = 0,                  %% 封魔录和装备副本是否死亡
	logout_type = ?DUN_EXIT_OTHER %% 退出副本的方式[1退出按钮,2时间结束,3玩家下线,4异常退出].
}).

%% 副本场景信息.
-record(dungeon_scene, {
	id,                          %% 场景的唯一id.
	did,                         %% 副本id.
	sid,                         %% 场景资源id.
	enable = true,               %% 能不能进去.
	tip = <<>>,                  %% 场景提示.
	begin_time = 0,              %% 开始时间.
	timer_ref = 0                %% 场景的定时器.
}).

%% 玩家信息.
-record(dungeon_player, {
	id,                          %% 角色ID
	pid,                         %% 玩家进程ID
	dungeon_data_pid             %% 玩家副本数据进程ID.
}).

%% 副本记录.
-record(dungeon_record, {
        player_id = 0,           %% 角色id.
        dungeon_pid = 0,         %% 副本进程pid.
        scene_id = 0,            %% 场景id.
        end_time = 0             %% 结束时间.
    }).

%% 副本日志.
-record(dungeon_log, {
        id           = {0, 0},   %% {角色id, 副本id}.
        total_count  = 0,        %% 进入副本总次数.
		record_level = 0,        %% 副本通关等级.
		pass_time    = 0,        %% 副本通关时间.
        cooling_time = 0,        %% 进入副本冷却时间.
		gift = 0                 %% 副本礼包.
    }).

%% --------------------------------- 宠物副本 ----------------------------------

%% 宠物副本表
-record(ets_pet_dungeon, {
    dungeon_pid = 0,             %% 进程pid
    total_mon_list = [],         %% 全部怪物列表
    mon_list = []                %% 怪物列表
 }).


%% --------------------------------- 经验副本 ----------------------------------
-record(exp_dun, {
        level = 1,              %% 波数
        kill_mon_num = 0,       %% 本波已经击杀的怪物数量
        need_kill_mon_num = 0,  %% 本波需要击杀的怪物数量
        total_kill_mon_num = 0  %% 总共击杀的怪物数量
    }).

%% --------------------------------- 铜币副本 ----------------------------------

%% 铜币副本表
-record(ets_coin_dungeon, {
    player_id = 0,               %% 玩家id
    combo = 0,                   %% 连斩数
    max_combo = 0,               %% 最高连斩数
    coin = 0,                    %% 铜钱
    bcoin = 0,                   %% 绑定铜钱
    total_send_coin = 0,         %% 已经发放的铜钱
    total_send_bcoin = 0         %% 已经发放的绑定铜钱
}).

%% 铜币副本数据.
-record(coin_dun, {
	mon_level = 0,               %% 小怪等级.
	boss_level = 0,              %% BOSS等级.	
	last_kill_time = 0,          %% 上次杀死小怪时间.
	combo = 0,                   %% 当前连斩数.
	max_combo = 0,			     %% 最大连斩数.
	kill_mon = 0,                %% 击杀小怪个数.
	kill_boss = 0,               %% 击杀BOSS个数.
	coin = 0,                    %% 物品个数.
	bcoin = 0,                   %% 绑定铜币个数.
    total_send_coin = 0,         %% 已经发放的物品.
    total_send_bcoin = 0,        %% 已经发放的绑定铜钱.
	coin_num = 0,                %% 摇奖得到的金币数
	is_can_next = 0,             %% 是否能刷下一个boss
	next_level_ref = 0,          %% 刷下一个boss的定时器
	begin_time = 0,              %% 开始的时间.
    dun_end_time = 0,            %% 副本结束时间
    step = 0,                    %% 副本阶段(（1刷连斩阶段，2打boss阶段, 3摇奖阶段)
    kill_boss_lim_timer = 0      %% 击杀boss限制定时器
}).

-define(PICK_COIN,    60).       %% 新版钱多多使其金币时间(秒)
-define(LOTTERY_TIME, 5).        %% 摇奖时间(秒)

%% 铜币副本怪物列表.
-define(COIN_DUN_MON_LIST, [65001,65002,65003,65004,65005,65006,65007,65008,65009,65010]).

%% 铜币副本水晶怪物列表.
-define(COIN_DUN_CRYSTAL_LIST, [65022, 65022]).

%% 铜币副本等级列表.
%-define(COIN_DUN_LEVEL_LIST, [{1, 65001, 65011}, {2, 65002, 65012}, {3, 65003, 65013}, 
%							  {4, 65004, 65014}, {5, 65005, 65015}, {6, 65006, 65016}, 
%							  {7, 65007, 65017}, {8, 65008, 65018}, {9, 65009, 65019}, 
%							  {10, 65010, 65020},{11, 65010, 65025},{12, 65010, 65026}]).

-define(COIN_DUN_LEVEL_LIST, [{1, 65001, 65011}, {2, 65002, 65012}, {3, 65003, 65013}, 
							  {4, 65004, 65014}, {5, 65005, 65015}]).
   
%% 小怪坐标.
-define(COIN_DUN_MON_LOCA, [
	{19, 49},{27, 72},{9, 49},{32, 51},{40, 49},{20, 72},{27, 67},{21, 43},{34, 67},{37, 52},
	{11, 59},{39, 57},{9, 64},{38, 63},{26, 48},{14, 56},{32, 43},{24, 66},{38, 69},{30, 65},
	{31, 72},{34, 62},{15, 61},{36, 44},{24, 73},{15, 71},{23, 48},{28, 43},{42, 54},{35, 55},
	{13, 46},{16, 51},{17, 44},{12, 52},{42, 61},{29, 48},{12, 67},{34, 48},{21, 67},{15, 66},
	{7, 56},{24, 42},{18, 65}]).

%% 金币坐标.
-define(COIN_DUN_COIN_LOCA, [
	{17, 49},{35, 46},{10, 57},{37, 65},{38, 55},{37, 60},{24, 51},{36, 53},{28, 67},{26, 68},
	{24, 61},{14, 62},{36, 49},{23, 72},{11, 52},{32, 51},{33, 70},{22, 52},{26, 59},{15, 51},
	{35, 56},{30, 63},{21, 70},{28, 60},{16, 62},{10, 61},{19, 62},{38, 62},{27, 56},{13, 56},
	{15, 67},{25, 71},{33, 64},{27, 71},{31, 65},{35, 60},{13, 50},{34, 50},{35, 64},{34, 67},
	{12, 58},{17, 45},{34, 47},{25, 66},{16, 56},{27, 47},{17, 65},{11, 55},{20, 44},{19, 54},
	{39, 59},{20, 48},{9, 53},{21, 67},{19, 66},{34, 62},{24, 43},{22, 60},{29, 48},{11, 64},
	{20, 59},{23, 68},{25, 48},{25, 55},{30, 45},{32, 46},{33, 57},{23, 65},{29, 71},{30, 67},
	{23, 46},{19, 46},{15, 64},{23, 56},{29, 57},{19, 70},{15, 47},{25, 45},{37, 57},{31, 49},
	{22, 44},{34, 53},{38, 52},{13, 66},{21, 55},{19, 50},{26, 51},{28, 44},{39, 55},{13, 60},
	{17, 51},{31, 70},{22, 48},{16, 58},{26, 43},{28, 53},{30, 52},{14, 58},{14, 53},{17, 68}]).

%% 铜钱副本各个阶段
-define(KILL_MON_STEP,  1). %% 刷连斩阶段
-define(KILL_BOSS_STEP, 2). %% 杀boss阶段
-define(LOTTERY_STEP,   3). %% 摇奖阶段

%% --------------------------------- 爬塔副本 ----------------------------------

%% 爬塔副本状态.
-record(tower_state, {
	esid = [],             %% 已经进过的场景.
	csid = [],             %% 已经通关的场景.
	btime = 0,             %% 开始的时间.
	etime = 0,             %% 该层已经结束的时间.
	extand_time = 0,       %% 增加的时间.
	rewarder = [],         %% 判断是否已经领取过
	exreward = 1,          %% 三种职业提高20%的奖励
	close_timer = 0,       %% 关闭爬塔副本定时器.
    ratio = 0,             %% 掉落的倍率
    max_ids = []           %% 记录进入过的玩家id
}).

%% --------------------------------- 剧情副本 ----------------------------------

%% 剧情副本挂机状态.
-record(auto_story_dun_record, {
	id = 0,                %% 玩家id.
	dungeon_list = [],     %% 挂机副本id列表.
	begin_time = 0,        %% 开始时间.
	exp = 0,               %% 获得的经验.
	wuhun = 0,             %% 获得的武魂.
	finish = 0,            %% 完成了几个.
	chapter = 0,           %% 第几章.
	state = 0,             %% 挂机状态[0=没有挂机,1=挂机中].
    dungeon_id = 0,        %% 挂机副本
    auto_num = 0,          %% 挂机次数
    drop_data_list = []    %% 挂机副本掉落记录
}).

%% 剧情副本掉落.
-record(auto_drop_record, {
	dungeon_id = 0,        %% 副本id.
    drop_no = 0,           %% 第几次掉落    
	exp = 0,               %% 获得的经验.
	wuhun = 0,             %% 获得的武魂.
	goods_list = []        %% 物品列表，[{物品id,物品数量}...].
}).

%% 剧情副本霸主表
-record(ets_story_master, {
        chapter     = 0,        %% 第几章
        player_id   = 0,        %% 霸主id
		player_name = <<"">>,   %% 霸主名字
        sex         = 0,
        career      = 0,
		score       = 0,        %% 霸主积分
        passtime    = 0,        %% 完成时间
		record_list = []        %% 通关记录列表
    }).

-define(AUTO_STORY_DUNGEON_KEY(Id), lists:concat(["auto_story_dungeon_", Id])). %% 剧情副本自动挂机数据.
-define(ETS_STORY_MASTER, ets_story_master).

%% --------------------------------- 大闹天空手游装备精力副本 ----------------------------------
-define(DUNGEON_EQUIP_MASTER, equip_master).                        %% equip master info

-define(ETS_EQUIP_MASTER, ets_equip_master).                        %% ets equip master info

-record(dntk_equip_dun_state, {
        dun_id = 0,                 %% 副本id
        equip_dun_pid = 0,          %% 副本pid
        total_exp  = 0,             %% 累积经验
        start_time = 0,             %% 开始时间
        end_time = 0,               %%　副本结束时间
        kill_count = 0,             %% 杀怪数
        extract_count = 0,          %% 抽取次数 
        goods = [],                 %% 以抽取的物品
        all_goods = [],              %% 所有的转盘物品
        npc_list = [],              %% npc列表
        npc_count = 0               %% npc数量
    }).


-record(dntk_equip_dun_config,{
        id = 0,                 %%  副本id  
        f_rotary_gift = [],     %%  第一次通关转盘物品[{goods_id, num, rate},{物品id, 数量, 概率}],概率从小到大填
        s_rotary_gift = [],     %%  第二次以后转盘物品[{goods_id, num, rate},{物品id, 数量, 概率}],概率从小到大填
        pass_gift = [],         %%  首次通关奖励列表[{goods_id, num}]
        extraction_count = 0,   %%  抽奖次数
        send = 0,               %%  是否发送通关奖励
        level_condition = [],   %%  通关每个星级评分标准   [{level, time}, {星级, 通关时间}...],通关时间从小到大填
        gold = 0                %%  全部抽取物品的元宝数
        }).


-record(dntk_equip_dun_log,{
        id = 0,             %%  id = {role_id, dun_id}
        sort_id = 0,        %%  副本排序id标示
        total_count = 0,    %%  总次数                
        level = 0,          %%  星级评分
        best_time = 0,      %%  最佳时间
        is_opne = 0,        %%  开启
        gift = 0,           %%  礼包
        time = 0,           %%  更新时间
        name = "",          %%  玩家昵称
        career = 0,         %%  职业
        sex = 0,            %%  性别
        is_kill_boss        %%  玩家是够击杀了boss
        }).

%% 装备副本霸主时间
-record(dntk_equip_dun_master, {                    
        dun_id = 0,             %% 副本id标示
        role_id = 0,            %% 玩家id
        name = "",              %% 玩家名字
        career = 0,             %% 玩家职业
        sex = 0,                %% 玩家性别  
        pass_time = 0,          %% 通关时间
        time = 0
        }).


