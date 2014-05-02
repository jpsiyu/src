%%%------------------------------------
%%% @Module  : data_money_config
%%% @Author  : HHL
%%% @Email   : 
%%% @Created : 2014.2.27
%%% @Description: 摇钱树
%%%------------------------------------
-module(data_money_config).

%% ====================================================================
%% API functions
%% ====================================================================
-export([get_config/1,
         get_free_base_jishu/1,
         get_free_times/1,
         get_coin_mutil_rate/2,
         get_normal_timespan/1,
         get_level_coefficient/1,
         get_free_gold/1,
         get/2,
         get_coin_ka_id/1,
         shake_count_need/1,
         get_coin_ka_num/1,
         get_coin_good_type/1,
         get_rand_num/0]).


get_config(Type)->
    case Type of
        gold_shake_time -> 20;
        _ -> undefine
    end.
        
    
%%　0非vip、1黄金vip、2白金vip、3砖石vip
get_free_times(VipType) ->
    case VipType of
        0 -> 4;
        1 -> 6;
        2 -> 7;
        3 -> 8;
        _ -> 4
    end.


%% 倍数,1:免费, 2:元宝
get_coin_mutil_rate(Type, NowShake)->
    Rand = util:rand(1, 10000),
    case Type of
        1 -> 
            if
                NowShake =:= 4 ->
                    if
                        Rand < 800 ->
                            4;
                        Rand < 5000 ->
                            2;
                        true ->
                            1
                    end;
                true ->
                    if
                        Rand < 800 ->
                            4;
                        Rand < 2000 ->
                            2;
                        true ->
                            1
                    end
            end;
        2 ->
            if
                Rand < 300 ->
                    4;
                Rand < 800 ->
                    2;
                true ->
                    1
            end
    end.

%% 获取冷却时间消耗的元宝
get_free_gold(Times)->
    case Times of
        1 -> 1;
        2 -> 2;
        3 -> 3;
        4 -> 4;
        5 -> 5;
        6 -> 6;
        7 -> 7;
        8 -> 8;
        _ -> 0
    end.


%% 非vip玩家摇钱有冷却时间，分别为：15分钟、30分钟、60分钟
get_normal_timespan(Times) ->
    case Times of
        0 -> 0;
        1 -> 5*60;
        2 -> 10*60;
        3 -> 15*60;
        _ -> 0
    end.
        
   
%% 等级加强系数
get_level_coefficient(Lv)->
    if
        Lv >=  0 andalso Lv =< 30 -> LevelCoefficient = 1;
        Lv >= 31 andalso Lv =< 35 -> LevelCoefficient = 1.05;
        Lv >= 36 andalso Lv =< 40 -> LevelCoefficient = 1.1;
        Lv >= 41 andalso Lv =< 45 -> LevelCoefficient = 1.18;
        Lv >= 46 andalso Lv =< 50 -> LevelCoefficient = 1.25;
        Lv >= 51 andalso Lv =< 55 -> LevelCoefficient = 1.35;
        Lv >= 56 andalso Lv =< 60 -> LevelCoefficient = 1.45;
        Lv >= 61 andalso Lv =< 65 -> LevelCoefficient = 1.57;
        Lv >= 66 andalso Lv =< 70 -> LevelCoefficient = 1.7;
        Lv >= 71 andalso Lv =< 75 -> LevelCoefficient = 1.75;
        Lv >= 76 andalso Lv =< 79 -> LevelCoefficient = 1.85;
        Lv >= 80 ->LevelCoefficient = 2;
        true -> LevelCoefficient = 1
    end,
    LevelCoefficient.

%% 免费次数的基础系数
get_free_base_jishu(Count)->
    case Count of
        1 -> 1.4;
        2 -> 1.5;
        3 -> 1.6;
        4 -> 1.7;
        5 -> 1.7;
        6 -> 1.7;
        7 -> 1.7;
        8 -> 1.7;
        _ -> 1.4
    end.


%% 元宝摇钱计算的元宝数量
get_gold_num(Lv, Count)->
    round((2*Count-1)*(Lv + 50)*(Lv+50)/6400).


%%获取元宝摇钱的基础系数和元宝消耗
get(Lv, 1) -> [2,     get_gold_num(Lv, 1)];
get(Lv, 2) -> [2.14,  get_gold_num(Lv, 2)];
get(Lv, 3) -> [2.288, get_gold_num(Lv, 3)];
get(Lv, 4) -> [2.445, get_gold_num(Lv, 4)];
get(Lv, 5) -> [2.612, get_gold_num(Lv, 5)];
get(Lv, 6) -> [2.789, get_gold_num(Lv, 6)];
get(Lv, 7) -> [2.976, get_gold_num(Lv, 7)];
get(Lv, 8) -> [3.175, get_gold_num(Lv, 8)];
get(Lv, 9) -> [3.386, get_gold_num(Lv, 9)];
get(Lv, 10)-> [3.609, get_gold_num(Lv, 10)];
get(Lv, 11)-> [3.846, get_gold_num(Lv, 11)];
get(Lv, 12)-> [4.097, get_gold_num(Lv, 12)];
get(Lv, 13)-> [4.363, get_gold_num(Lv, 13)];
get(Lv, 14)-> [4.645, get_gold_num(Lv, 14)];
get(Lv, 15)-> [4.944, get_gold_num(Lv, 15)];
get(Lv, 16)-> [5.261, get_gold_num(Lv, 16)];
get(Lv, 17)-> [5.597, get_gold_num(Lv, 17)];
get(Lv, 18)-> [5.953, get_gold_num(Lv, 18)];
get(Lv, 19)-> [6.33,  get_gold_num(Lv, 19)];
get(Lv, 20)-> [6.73,  get_gold_num(Lv, 20)];
get(_ , _) -> [].


%% 根据8890的次数来获取铜钱卡id
get_coin_ka_id(Type) ->
    case Type of
        1 -> 221101;
        2 -> 221101;
        3 -> 221101;
        _ -> 221101
    end.   

%% 根据8890的次数来获取需要摇钱的次数
shake_count_need(Type) ->
    case Type of
        0 -> 6;
        1 -> 12;
        2 -> 18;
        _ -> 24
    end.

%% 根据8890的次数来获取能够获取的铜钱卡数量
get_coin_ka_num(Type) ->
    case Type of
        0 -> 5;
        1 -> 10;
        2 -> 15;
        _ -> 25
    end.

%% 通过摇钱次数来确定能够获取哪一个等级的物品类型
get_coin_good_type(NowShakeCount) ->
    if
        NowShakeCount >= 24 -> Level = 4;
        NowShakeCount >= 18 -> Level = 3;
        NowShakeCount >= 12 -> Level = 2;
        NowShakeCount >= 6 -> Level = 1;
        true -> Level = 0
    end,
    Level.

%% -5,5之间加减
get_rand_num()->
    L = lists:seq(-5, 5, 1),
    Nth = util:rand(1, 11),
    lists:nth(Nth, L).
    


        
        
                       




