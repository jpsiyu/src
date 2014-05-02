%%%------------------------------------
%%% @Module     : data_national
%%% @Author     : huangyongxing
%%% @Email      : huangyongxing@yeah.net
%%% @Created    : 2011.12.22
%%% @Description: 国家系统
%%%------------------------------------
-module(data_national).
-compile(export_all).

%% 前百名实力计算
get_power_by_order(CombatPower, Order) ->
    if
        Order =< 20 -> CombatPower * 1.2;
        Order =< 50 -> CombatPower * 1.1;
        Order =< 100 -> CombatPower;
        true -> 0
    end.

%% 经验加成比例 -> float()
get_exp_addition(WorldLevel, RoleLevel) ->
    LevelGap = WorldLevel - RoleLevel,
    if
        LevelGap =< 5 -> 0;
        WorldLevel < 50 -> 0;
        RoleLevel < 35 -> 0;
        true ->
            LevelGap / RoleLevel * WorldLevel / 40 
    end.

%% 国家守护技能加成值
get_skill_addition(WorldLevel, StrongestPower, NationalPower, NationalOrder) ->
    BaseAdditionList = get_base_skill_addition(WorldLevel),
    Factor = get_factor_of_skill_addition(StrongestPower, NationalPower, NationalOrder),
    [round(BaseAddition * Factor) || BaseAddition <- BaseAdditionList].

%% 国家守护技能基础值 -> [防御, 全抗]
get_base_skill_addition(WorldLevel) ->
    if
        WorldLevel =< 40 -> [0, 0];
        WorldLevel =< 50 -> [100, 100];
        WorldLevel =< 60 -> [150, 150];
        WorldLevel =< 70 -> [200, 200];
        WorldLevel =< 80 -> [250, 250];
        true -> [300, 300]
    end.

%% 国家守护技能加成系数 -> float()
get_factor_of_skill_addition(StrongestPower, NationalPower, NationalOrder) ->
    if
        NationalOrder =< 1 -> Factor = 1;
        true -> Factor = StrongestPower / NationalPower
    end,
    if
        Factor =< 1.2 -> 1;
        Factor =< 2 -> Factor;
        true -> 2
    end.

%% [持续时间, 冷却时间]
national_defend_time() ->
    [600, 7200].

%% 功勋任务加成系数 -> float()
get_factor_of_exploit_task(StrongestPower, NationalPower, NationalOrder) ->
    if
        NationalOrder =< 1 -> Factor = 1;
        true -> Factor = StrongestPower / NationalPower
    end,
    if
        Factor =< 1 -> 1;
        Factor =< 2 -> Factor;
        true -> 2
    end.

%% 获得特定任务加成系数
get_factor_of_task(PowerRanking, LevelRanking) ->
    if
        LevelRanking =< 1 -> 1;
        true ->
            if
                PowerRanking =< 1 -> 1;
                PowerRanking == 2 -> 1.1;
                true -> 1.2
            end
    end.
