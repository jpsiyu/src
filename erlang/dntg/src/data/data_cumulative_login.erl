%%%--------------------------------------
%%% @Module  : data_cumulative_login
%%% @Author : hhl
%%% @Email : 
%%% @Created : 2014.3.6
%%% @Description: 
%%%--------------------------------------

-module(data_cumulative_login).

-export([get_config/1,
         get_sign_gift/0,  
         get_sign_good_days/1, 
         get_login_week_count/2,
         day_span/1,
         get_drop_count/1,
         sign_add_count/1,
         get_mouth_days/0]).


%%======================================================大闹天空==================================
get_config(Type)->
    case Type of
        define_goods -> {{501202, 1}, 1000};
        define_goods_list -> [{{222001,1},50},{{222101,1},50},{{111041,2},40},{{206101,1},70},
                               {{111041,1},100},{{231201,1},50},{{601601,1},100},{{501202,1},100},{{612501,1},100}];
        undefined -> []
    end.

%% 初始化签到礼包(新用户和每月更新)
get_sign_gift() ->
    [{2,  [{624201, 1, 0, 0}, {624801, 1, 0, 0}, {111481, 1, 1, 0}, {111491, 1, 1, 0}]},
     {5,  [{624201, 2, 0, 0}, {624801, 2, 0, 0}, {111481, 2, 1, 0}, {111491, 2, 1, 0}]},
     {10, [{624201, 3, 0, 0}, {624801, 3, 0, 0}, {111481, 3, 1, 0}, {111491, 3, 1, 0}]},
     {17, [{624201, 4, 0, 0}, {624801, 4, 0, 0}, {111481, 4, 1, 0}, {111491, 4, 1, 0}]},
     {26, [{624201, 5, 0, 0}, {624801, 5, 0, 0}, {111481, 5, 1, 0}, {111491, 5, 1, 0}]}].



%% %% {等级,等级,[{{物品类型id, 数量},概率}]}
%% get_drop_goods_list() ->
%%     [{0, 49,[{{222001,1},1000},{{111041,2},500},{{206101,1},1000},{{111041,1},1500},{{231201,1},1000},
%%              {{601601,1},1000},{{671001,1},500},{{205101,1},1500},{{624201,1},1000},{{624801,1},1000}]},
%%      {50,59,[{{222001,1},1000},{{111041,2},500},{{206101,1},1000},{{111041,1},1500},{{231201,1},1000},
%%              {{601601,1},1000},{{671001,1},500},{{205101,1},1500},{{624201,1},1000},{{624801,1},1000}]},
%%      {60,99,[{{222001,1},1000},{{111041,2},500},{{206101,1},1000},{{111041,1},1500},{{231201,1},1000},
%%              {{601601,1},1000},{{671001,1},500},{{205101,1},1500},{{624201,1},1000},{{624801,1},1000}]}].

%% 获取今天以前的签到有礼包领取的时间
get_sign_good_days(SignCount)->
    L = [2,5,10,17,26],
    lists:foldl(fun(X, H)-> if
                             SignCount >= X -> [X|H];
                             true -> H
                            end
                end, [], L).    

%% 一个月的时间
get_mouth_days() ->
    [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31].

%% 记录的更新时间与现在的时间间隔
get_login_week_count(Time, LoginWeekCount)->
    DaySpan = day_span(Time),
    if
        DaySpan =:= 0 ->    %% 今天更新过
            NewLoginWeekCount = LoginWeekCount;
        DaySpan =:= 1 ->    %% 昨天的登录过，连续登录累加1
            NewLoginWeekCount = LoginWeekCount+1;
        true ->             %% 间断过,初始化为1
            NewLoginWeekCount = 1
    end,
    NewLoginWeekCount.
%%　上一次退出时间和今天的时间天数间隔
day_span(LastLogoutTime)->
    util:diff_day(LastLogoutTime).


%% 获取翻牌次数
get_drop_count(Count)->
    if
        Count =:= 1 -> DropCount = 1;
        Count =:= 2 -> DropCount = 2;
        Count >=  3 -> DropCount = 3;
        true -> DropCount = 1
    end,
    DropCount.  


%%　根据vip类型来确定补签的次数
sign_add_count(VipType)->
    case VipType of
        0 -> 0;
        1 -> 2;
        2 -> 3;
        3 -> 4;
        _ -> 0
    end.














