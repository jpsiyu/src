%%%--------------------------------------
%%% @Module  : tower.hrl
%%% @Author  : zhenghehe
%%% @Created : 2012.02.07
%%% @Description : 锁妖塔record
%%%--------------------------------------

-define(ETS_TOWER_MASTER, ets_tower_master). 

%% 锁妖塔各层霸主表
-record(ets_tower_master, {
        sid = 0,             %% 场景id
        players = [],        %% 霸主
        passtime = 0,        %% 完成时间
        reward = [],         %% 已经领取奖励的霸主
        dun_id = 0           %% 塔副本id
    }).



%% 锁妖塔配置
-record(tower, {
        sid = 0,            %% 该层资源id
        time = 0,           %% 该层限制时间
        exp = 0,            %% 每层的经验
        level = 0,          %% 层数
        llpt = 0,           %% 每层的历练声望
        items = [],         %% 每层的奖励物品
        total_exp = 0,      %% 累计到该层的经验
        total_llpt = 0,     %% 累计到该层的历练声望
        total_items = [],   %% 累计到该层的奖励物品
        master_exp = 0,     %% 该层霸主每天能领取的经验
        master_llpt = 0,    %% 该层霸主每天能领取的历练声望
        be_master = 0,      %% 是否设置霸主
        honour = 0,         %% 荣誉
        total_honour = 0,   %% 累计荣誉
        king_honour = 0,    %% 帝王谷荣誉
        total_king_honour = 0,  %% 累计帝王谷荣誉
        box_rate=0,         %% 产生箱子概率.
        box_count=0,        %% 产生箱子数量.
        box_mon_rate=[],    %% 箱子ID集合.
        mon_place=[]        %% 随机坐标集合.
    }).

%% 锁妖塔怪物配置
-record(tower_mon,{
        id = 0,             %% 怪物id
        time = 0            %% 增加时间
    }).

%% 塔奖励保存
-record(ets_tower_reward, {
        player_id = 0,          %% 玩家id
        dungeon_pid = 0,        %% 塔副本进程id
        dungeon_time = 0,       %% 塔副本开启时间
        fin_sid = 0,            %% 完成的层数id
        reward_sid = 0,         %% 已经获取的层数id
        begin_sid = 0,          %% 副本开始场景id
        exreward = 1,           %% 奖励附加的百分比
        active_scene = 0,       %% 跳层场景id
        member_ids   = []       %% 队员ids
    }).