%%%------------------------------------
%%% @Module  : city_war
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.13
%%% @Description: 城战
%%%------------------------------------

%% 活动时间控制
-record(city_war_state, 
    {
        config_begin_hour = 0,
        config_begin_minute = 0,
        config_end_hour = 0,
        config_end_minute = 0,
        end_seize_hour = 0,
        end_seize_minute = 0,
        apply_end_hour = 0,
        apply_end_minute = 0,
        open_days = 0,
        seize_days = 0
    }
).

%% 城战内信息
-record(city_war_info, {
        %% 进攻方帮派信息 {GuildId, {OnlineNum, Score, EtsGuild}}
        attacker_info = dict:new(),
        %% 防守方帮派信息 {GuildId, {OnlineNum, Score, EtsGuild}}
        defender_info = dict:new(),
        %% 玩家信息 {PlayerId, {State, Score}}  State: 1.进攻 2.防守
        player_info = dict:new(),
        %% 怪物信息 {Type, {MonId, Blood}}   Type: 1-5.城门   Blood: 血量百分比
        monster_info = dict:new(),
        %% 在线总人数
        attacker_online_num = 0,
        defender_online_num = 0,
        %% 进攻方复活点
        attacker_revive_place = [],
        %% 防守方复活点
        defender_revive_place = [],
        %% 进攻方医仙数量
        attacker_doctor_num = 0,
        %% 进攻方鬼巫数量
        attacker_ghost_num = 0,
        %% 防守方医仙数量
        defender_doctor_num = 0,
        %% 防守方鬼巫数量
        defender_ghost_num = 0,
        %% 可抢夺复活点怪物
        revive_mon_id = [],
        %% 车房1炸弹
        bomb_list1 = [],
        %% 车房2炸弹
        bomb_list2 = [],
        %% 复活点攻城车弩车
        car1_list1 = [],
        car1_list2 = [],
        car2_list1 = [],
        car2_list2 = [],
        %% 场上存在攻城车数量
        total_car_num = 0,
        %% 场上存在箭塔数量
        total_tower_num = 0,
        %% 死亡列表
        die_list = [],
        %% 第几场
        count = 1,
        %% 下次复活时间
        next_revive_time = 0,
        %% 采集攻城车数量
        collect_car_num = 0,
        %% 进攻援助方数量
        att_aid_num = 0,
        %% 防守援助方数量
        def_aid_num = 0
}).
