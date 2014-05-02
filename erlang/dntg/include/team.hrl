%% ---------------------------------------------------------
%% Author:  zhenghehe
%% Created: 2012-2-2
%% Description: 组队 ets
%% --------------------------------------------------------
%%------------------------------组队ETS宏定义---------------------------------
-define(ETS_DUNGEON_ENLIST, ets_dungeon_enlist).                %% 副本招募
-define(ETS_DUNGEON_ENLIST2, ets_dungeon_enlist2).              %% 副本招募2
-define(ETS_TMB_OFFLINE, ets_tmb_offline).                      %% 队伍暂离成员列表
-define(ETS_TEAM, ets_team).                                    %% 队伍缓存
-define(ETS_TEAM_ENLIST, ets_team_enlist).                      %% 组队招募面板
%%------------------------------组队ETS宏定义----------------------------------
%% 队伍暂离成员列表
-record(ets_tmb_offline, {
        id = 0,             %% 角色id
        team_pid = none,    %% 组队进程pid
        offtime = 0,        %% 离线时间
        dungeon_scene = 0,  %% 离开时副本的场景id
        dungeon_pid = none, %% 副本进程
        dungeon_begin_sid = 0  %% 副本刚开始id
    }).

%%队伍资料
-record(team, 
    {
        leaderid = 0,                       %% 队长id
        leaderpid = none,                   %% 队长pid
		leader_dungeon_data_pid = 0,        %% 队长副本数据管理pid
        teamname = [],                      %% 队名
        member = [],                        %% 队员列表
        dungeon_pid = none,                 %% 副本进程id
        free_location = [],                 %% 空闲位置
        distribution_type = 0,              %% 拾取模式(0:自由拾取 1:随机拾取 2:轮流拾取)
        turn = 0,                           %% 轮流标记,初始为自由拾取
        dungeon_scene = 0,                  %% 副本场景id
        %drop_choosing_l = [],              %% 掉落包正在捡取列表(保留10个)
        %drop_choose_success_l = [],        %% 掉落包捡取成功列表(保留10个)
        join_type = 2,                      %% 1:不自动，2:自动
        create_type = 0,                    %% 0:普通创建；2:副本创建
        create_sid = 0,                     %% 副本创建时的副本地图id
		is_allow_mem_invite = 0,            %% 队员邀请玩家加入队伍(0:不允许，1:允许)
		is_double_drop = 0,                 %% 九重天双倍掉落 0:不是，1:是.
        goto_dungeon = [],                  %% 传送到副本区标志
        arbitrate = [0, 0, 0, 0, [], 0],    %% 队伍仲裁记录, [记录号，类型，赞成次数，反对次数， 已投票队员id]
        id = 0
    }
).

%%队员数据
-record(mb, 
    {
        id = 0,                             %% 队员id
        pid = none,                         %% 队员pid
        nickname = [],                      %% 队员名字
        location = 0,                       %% 队员所处位置
        lv = 0,                             %% 队员等级
        career = 0,                         %% 队员职业
        sht_exp = {0, 1}                    %% {关系人id, 额外经验}
    }
).

%% 队伍缓存
-record(ets_team, {
        team_pid = 0,
        mb_num = 0,
        join_type = 0
    }).

%% 队伍招募宣言
-record(ets_team_enlist, {
        id = 0,
        name = <<"">>,
        career = 0,
        lv = 0,
        %online_flag = 0,
        type = 0,
        sub_type = 0,
        low_lv = 0,
        high_lv = 0,
        lim_career = 0,
        sex = 0,
        leader = 0,
        msg = <<"">>
    }).

-define(TEAM_MEMBER_MAX, 4).
-define(WUBIANHAI_MEMBER_MAX, 3).
%% %% 副本组队招募
%% -record(ets_dungeon_enlist, {
%%         id = 0,
%%         sid = 0,
%%         nickname = []
%%     }).

%% 副本组队招募(8.29)
-record(ets_dungeon_enlist2, {
        id = 0,
        sid = 0,
        %line = 0,
        nickname = [],
        is_need_fire = 1,
        is_need_ice = 2,
        is_need_drug = 3,
        lv = 0,
        att = 0,
        def = 0,
        combatpower = 0,
        mb_num = 1
    }).

