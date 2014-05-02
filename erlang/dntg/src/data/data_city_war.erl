%%%------------------------------------
%%% @Module  : data_city_war
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.13
%%% @Description: 城战
%%%------------------------------------
-module(data_city_war).
-export(
    [
        get_city_war_config/1,
        get_border_time/0,
        get_border_time2/0,
        get_repair_xy/2
    ]
).

%% 城战配置
get_city_war_config(Type) ->
    case Type of
        %% 活动开始结束时间
        begin_end_time -> [[20, 30], [21, 0]];
        %% 结束抢夺进攻权时间
        end_seize_time -> [20, 0];
        %% 报名结束时间
        apply_end_time -> [20, 0];
        %% 开放时间
        open_days -> 6;
        %% 抢夺时间
        seize_days -> 5;
        %% 场景ID
        scene_id -> 109;
        %% 最低参与等级
        min_lv -> 40;
        %% 默认出口
        leave_scene -> [102, 103, 122];
        %% 进攻方默认出生点
        get_attacker_born -> [[16, 179]];
        %% 防守方默认出生点
        get_defender_born -> [[97, 79]];
        %% 可抢夺复活点
        can_rob_born -> [];
        %% 炸弹生成坐标
        bomb_place -> [[56, 136], [56, 136]];
        %% 攻城车生成坐标
        car_place1 -> [[56, 136], [16, 179]];
        %% 弩车生成坐标
        car_place2 -> [[56, 136], [16, 179]];
        %% 活动最大参与人数
        max_attacker_online_num -> 150;
        max_defender_online_num -> 150;
        %max_online_num -> 2;
        %% 医仙、鬼巫最大人数
        max_other_career_num -> 2;
        %max_other_career_num -> 1;
        %% 可打复活旗子
        mon1 -> 40400;
        %% 不可打复活旗子(蓝 防守)
        mon2 -> 40411;
        %% 没占领复活旗子
        mon3 -> 40412;
        %% 不可打复活旗子(红 进攻)
        mon4 -> 40413;
        %% 采集炸弹ID
        bomb_id1 -> 40419;
        %% 爆炸炸弹ID
        bomb_id2 -> 40420;
        %% 采集攻城车
        car_id1 -> 40432;
        %car_id1 -> 40431;
        %% 采集弩车
        car_id2 -> 40432;
        %% 城门怪ID
        door_mon_id1 -> 40464;
        door_mon_id2 -> 40440;
        door_mon_id3 -> 40474;
        %% 龙珠怪ID
        center_mon_id1 -> 40469;
        center_mon_id2 -> 40450;
        center_mon_id3 -> 40479;
        %% 箭塔怪ID
        tower_mon_id1 -> 40461;
        tower_mon_id2 -> 40421;
        tower_mon_id3 -> 40471;
        %% 箭塔坐标
        tower_xy -> [[60, 170], [47, 157], [33, 143], [20, 131], [113, 109], [101, 97], [83, 81], [71, 69], [137, 47], [125, 35]];
        %% 城门怪坐标
        door_mon_place -> [[132, 48], [78, 83], [108, 110], [28, 144], [54, 170]];
        %% 每个车房停留炸弹的最大数量
        get_all_bomb_list1 -> [[66, 115], [64, 115], [65, 111], [64, 119], [63, 111]];
        get_all_bomb_list2 -> [[81, 134], [83, 133], [85, 133], [84, 135], [82, 136]];
        %% 每个复活点停留攻城车的坐标
        get_all_car1_list1 -> [[21, 172], [23, 180]];
        get_all_car1_list2 -> [[53, 124], [48, 127], [44, 120]];
        get_all_car2_list1 -> [[29, 181], [31, 173]];
        get_all_car2_list2 -> [[72, 146], [73, 154], [78, 156]];
        %% 场上最多存在攻城车数量
        get_max_total_car_num -> 6;
        %get_max_total_car_num -> 4;
        %% 特效怪物
        special_mon_id1 -> 40451;
        special_xy1 -> [[138, 28], [86, 65], [122, 99], [31, 122], [69, 164], [88, 90], [94, 95]];
        special_mon_id2 -> 40452;
        special_xy2 -> [[128, 47], [75, 82], [110, 115], [24, 143], [56, 176], [84, 99], [93, 108]];
        %% 最低可获得奖励积分
        min_score -> 20;
        %% 守护神ID
        att_mon_id -> 40414;
        def_mon_id -> 40415;
        %% 最大援助帮派数量
        max_aid_num -> 5;
        _ -> void
    end.

%% 获得上次帮战时间的临界时间
get_border_time() ->
    case calendar:day_of_the_week(date()) of
        1 -> util:unixdate() - 2 * 24 * 60 * 60;
        2 -> util:unixdate() - 3 * 24 * 60 * 60;
        3 -> util:unixdate() - 1 * 24 * 60 * 60;
        4 -> util:unixdate() - 2 * 24 * 60 * 60;
        5 -> util:unixdate() - 1 * 24 * 60 * 60;
        6 -> util:unixdate() - 2 * 24 * 60 * 60;
        7 -> util:unixdate() - 1 * 24 * 60 * 60
    end.

%% 获得本周帮战时间的临界时间
get_border_time2() ->
    case calendar:day_of_the_week(date()) of
        1 -> util:unixdate() - 0 * 24 * 60 * 60;
        2 -> util:unixdate() - 1 * 24 * 60 * 60;
        3 -> util:unixdate() - 2 * 24 * 60 * 60;
        4 -> util:unixdate() - 3 * 24 * 60 * 60;
        5 -> util:unixdate() - 4 * 24 * 60 * 60;
        6 -> util:unixdate() - 5 * 24 * 60 * 60;
        7 -> util:unixdate() - 6 * 24 * 60 * 60
    end.

get_repair_xy(X, Y) ->
    case [X, Y] of
        [16, 179] -> [17, 186];
        [97, 79] -> [97, 86];
        [56, 136] -> [56, 143];
        _ -> [79, 117]
    end.
