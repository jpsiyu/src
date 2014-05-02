%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-5
%% Description: 神秘商店
%% --------------------------------------------------------
-module(lib_secret_shop).
-compile(export_all).
-include("shop.hrl").
-include("server.hrl").
-include("goods.hrl").
-include("unite.hrl").

%% 初始化商店
init_secret_shop(RoleId, Lv) ->
    case get_shop_db(RoleId) of
        [] ->
            GoodsList = data_secret_shop:get_goods(),
            %% 限制物品
            LimGoods = [{B#base_secret_shop.goods_id, B#base_secret_shop.lim_min} || B <- GoodsList, B#base_secret_shop.lim_min > 0],
            Count = 0,
            FreeTime = 3,
            {ok, NewGoodsList, NewCount} = batch_refresh(1, [], Count, [GoodsList, LimGoods, Lv]),
            NewShopInfo = add_shop(RoleId, NewCount, NewGoodsList, LimGoods, FreeTime),
            {ok, NewShopInfo};
        Data ->
            NewShopInfo = new(Data, Lv, RoleId),
            {ok, NewShopInfo}
    end.

%% 刷新商店
refresh(PlayerStatus, GoodsStatus, ShopInfo, GoodsInfo, Type, Num) ->
    GoodsList = data_secret_shop:get_goods(),
    Count = ShopInfo#ets_secret_shop.count,
    LimGoods = ShopInfo#ets_secret_shop.lim_goods,
    Lv = PlayerStatus#player_status.lv,
    {ok, NewGoodsList, NewCount} = batch_refresh(Num, [], Count, [GoodsList, LimGoods, Lv]),
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            if Type =:= 1 ->
                    %% 花费金钱
                    Cost = 10 * Num,
                    _NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, gold),
                    %%消费返礼--神秘商店刷新
                    NewPlayerStatus = lib_player:add_consumption(smsx, _NewPlayerStatus, Cost, Num),
                    %% refresh secret:神秘商店刷新
                    log:log_consume(refresh_secret, gold, PlayerStatus, NewPlayerStatus, "refresh secret"),
                    log:log_secret_shop(1, PlayerStatus#player_status.id, 0, Num),
                    ShopInfo1 = ShopInfo,
                    NewStatus = GoodsStatus;
               Type =:= 2 ->
                    %% 扣除道具
                    {ok, NewStatus, _} = lib_goods:delete_one(GoodsStatus, GoodsInfo, Num),
                    log:log_secret_shop(2, PlayerStatus#player_status.id, GoodsInfo#goods.goods_id, Num),
                    ShopInfo1 = ShopInfo,
                    NewPlayerStatus = PlayerStatus;
               Type =:= 3 ->    
                   %% 免费刷新
                    log:log_secret_shop(3, PlayerStatus#player_status.id, 0, Num),
                    Free = ShopInfo#ets_secret_shop.free_time,
                    ShopInfo1 = ShopInfo#ets_secret_shop{free_time = (Free - 1)},
                    mod_daily_dict:increment(PlayerStatus#player_status.id, 8001),
                    NewStatus = GoodsStatus,
                    NewPlayerStatus = PlayerStatus;
               Type =:= 4 ->
                   %% 自动刷新
                    log:log_secret_shop(4, PlayerStatus#player_status.id, 0, Num),
                    mod_daily_dict:set_count(PlayerStatus#player_status.id, 8002, util:unixtime()),
                    ShopInfo1 = ShopInfo#ets_secret_shop{time = util:unixtime()},
                    NewStatus = GoodsStatus,
                    NewPlayerStatus = PlayerStatus;
               true ->
                    ShopInfo1 = ShopInfo#ets_secret_shop{time = util:unixtime()},
                    NewStatus = GoodsStatus,
                    NewPlayerStatus = PlayerStatus
            end,
            NewShopInfo = update_shop(ShopInfo1, Num, NewCount, NewGoodsList),
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus1 = NewStatus#goods_status{dict = Dict},
            {ok, NewPlayerStatus, NewStatus1, NewShopInfo}
        end,
    lib_goods_util:transaction(F).

%% 自动刷新
auto_refresh_shop(ShopInfo, UniteStatus) ->
    GoodsList = data_secret_shop:get_goods(),
    LimGoods = ShopInfo#ets_secret_shop.lim_goods,
    Count = ShopInfo#ets_secret_shop.count,
    Lv = UniteStatus#unite_status.lv,
    {ok, NewGoodsList} = auto_refresh(1, [], Count, [GoodsList, LimGoods, Lv]),
    log:log_secret_shop(4, UniteStatus#unite_status.id, 0, 1),
    NewShopInfo = update_shop(ShopInfo, 1, Count, NewGoodsList),
    NewShopInfo.

%% 批量刷新
batch_refresh(0, List, Count, _) -> {ok, List, Count};
batch_refresh(Num, List, Count, [GoodsList, LimGoods, Lv]) ->
    GoodsList2 = filter_goods(GoodsList, [LimGoods, Lv, Count]),
    Rand = data_secret_shop:get_max_ratio(),
    {ok, NewList} = refresh_goods(6, GoodsList2, List, Rand),
    batch_refresh(Num-1, NewList, Count+1, [GoodsList, LimGoods, Lv]).

%%自动刷新时用
auto_refresh(0, List, _, _) -> {ok, List};
auto_refresh(Num, List, Count, [GoodsList, LimGoods, Lv]) ->
    GoodsList2 = filter_goods(GoodsList, [LimGoods, Lv, Count]),
    Rand = data_secret_shop:get_max_ratio(),
    {ok, NewList} = refresh_goods(6, GoodsList2, List, Rand),
    auto_refresh(Num-1, NewList, Count, [GoodsList, LimGoods, Lv]).

%% 所有物品的概率之和
%% get_rand(GoodsList) ->
%%     F = fun(Info, Sum) ->
%%             case is_record(Info, base_secret_shop) of
%%                 true ->
%%                     Info#base_secret_shop.ratio + Sum;
%%                 false ->
%%                     Sum
%%             end
%%         end,
%%     lists:foldl(F, 0, GoodsList).

%% 过滤物品列表
filter_goods([], _) -> [];
filter_goods([Info|L], [LimGoods, Lv, Count]) ->
    %% 等级限制
    case (Info#base_secret_shop.min_lv > Lv andalso Info#base_secret_shop.min_lv > 0) 
        orelse (Info#base_secret_shop.max_lv < Lv andalso Info#base_secret_shop.max_lv > 0) of
        true -> 
            Filter = true;
        false ->
            %% 最少次数限制
            case lists:keyfind(Info#base_secret_shop.goods_id, 1, LimGoods) of
                {_,Min} when Count =< Min -> 
                    Filter = true;
                _ -> 
                    Filter = false
            end
    end,
    case Filter of
        true -> 
            filter_goods(L, [LimGoods, Lv, Count]);
        false -> 
            [Info | filter_goods(L, [LimGoods, Lv, Count]) ]
    end.

%% 刷新物品
refresh_goods(0, _, List, _) -> {ok, List};
refresh_goods(Num, GoodsList, List, Rand1) ->
    Rand = util:rand(1, Rand1),
    case find_goods(GoodsList, Rand) of
        [] ->
            %% 重复再刷一次
            refresh_goods(Num, GoodsList, List, Rand1);
        Info ->
            NewGoodsList = lists:keydelete(Info#base_secret_shop.goods_id, 2, GoodsList),
            NewList = case lists:keyfind(Info#base_secret_shop.goods_id, 2, List) of
                          false ->
                              NewB = Info#base_secret_shop{goods_num = 1},
                              [NewB|List];
                          B ->
                              NewB = B#base_secret_shop{goods_num = (B#base_secret_shop.goods_num+1)},
                              lists:keyreplace(Info#base_secret_shop.goods_id, 2, List, NewB)
                      end,
            refresh_goods(Num-1, NewGoodsList, NewList, Rand1)
    end.

%% 查找匹配机率的值
find_goods(_, 0) -> [];
find_goods([Info|T], Rand) ->
    case Rand >= Info#base_secret_shop.ratio_start andalso Rand =< Info#base_secret_shop.ratio_end of
        true -> 
            Info;
        false -> 
            find_goods(T, Rand)
    end;
find_goods([], _) -> [].

%% 购买东西
pay(PlayerStatus, GoodsStatus, ShopInfo, ShopGoods, GoodsTypeInfo, Num) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 花费金钱
            Cost = ShopGoods#base_secret_shop.price * Num,
            if
                ShopGoods#base_secret_shop.price_type =:= 1 ->
                    _NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, gold),
                    %%消费返礼--神秘商店购买
                    NewPlayerStatus = lib_player:add_consumption(smgm, _NewPlayerStatus, Cost, Num);
                ShopGoods#base_secret_shop.price_type =:= 2 ->
                    NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, bgold);
                ShopGoods#base_secret_shop.price_type =:= 3 ->
                    NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin);
                true ->
                    NewPlayerStatus = PlayerStatus
            end,
            %% pay secret:神秘商店购买
            log:log_consume(pay_secret, gold, PlayerStatus, NewPlayerStatus, ShopGoods#base_secret_shop.goods_id, Num, "pay sectet"),
            %% 添加物品
            NewInfo = lib_goods_util:get_new_goods(GoodsTypeInfo),
            GoodsInfo = case ShopGoods#base_secret_shop.bind > 0 of
                            true -> 
                                NewInfo#goods{bind=2, trade=1};
                            false -> 
                                NewInfo
                        end,
            {ok, NewStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, Num, GoodsInfo),
            log:log_secret_shop(5, PlayerStatus#player_status.id, ShopGoods#base_secret_shop.goods_id, Num),
            %% 元宝消费活动触发
%%             lib_activity:trigger_activity(PlayerStatus#player_status.id, 15, Cost),
%%             lib_activity:trigger_activity(PlayerStatus#player_status.id, 19, Cost),
            %% 商店修改
            NewGoodsList = case ShopGoods#base_secret_shop.goods_num =< Num of
                                true -> 
                                    lists:keydelete(ShopGoods#base_secret_shop.goods_id, 2, ShopInfo#ets_secret_shop.goods_list);
                                false ->
                                    NewShopGoods = ShopGoods#base_secret_shop{goods_num = (ShopGoods#base_secret_shop.goods_num - Num)},
                                    lists:keyreplace(ShopGoods#base_secret_shop.goods_id, 2, ShopInfo#ets_secret_shop.goods_list, NewShopGoods)
                            end,
            NewLimGoods = refresh_lim_goods(ShopGoods, ShopInfo#ets_secret_shop.count, ShopInfo#ets_secret_shop.lim_goods),
            NewShopInfo = change_goods_list(ShopInfo, NewGoodsList, NewLimGoods),
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus1 = NewStatus#goods_status{dict = Dict},
            {ok, NewPlayerStatus, NewStatus1, NewShopInfo}
        end,
    lib_goods_util:transaction(F).

%% 更新限制物品列表
refresh_lim_goods(Info, Count, LimGoods) ->
    case Info#base_secret_shop.lim_min > 0 of
        false -> LimGoods;
        true ->
            Goods_id = Info#base_secret_shop.goods_id,
            Lim = Info#base_secret_shop.lim_min,
            case lists:keyfind(Goods_id, 1, LimGoods) of
                false -> 
                    [{Goods_id,Count+Lim} | LimGoods];
                _ -> 
                    lists:keyreplace(Goods_id, 1, LimGoods, {Goods_id,Count+Lim})
            end
    end.

%% 取商店记录
get_shop_db(RoleId) ->
    Sql = io_lib:format(?sql_select_secret, [RoleId]),
    db:get_row(Sql).

%% 添加商店记录
add_shop(RoleId, Count, GoodsList, LimGoods, FreeTime) ->
    Sql_del = io_lib:format(?sql_del_secret, [RoleId]),
    db:execute(Sql_del),
    NowTime = util:unixtime(),
    Num = 1,
    NewGoodsList = [{B#base_secret_shop.goods_id, B#base_secret_shop.goods_num} || B <- GoodsList],
    Sql = io_lib:format(?sql_insert_secret, [RoleId, Num, Count, util:term_to_string(NewGoodsList), util:term_to_string(LimGoods), NowTime, FreeTime]),
    db:execute(Sql),
    NewShopInfo = #ets_secret_shop{role_id=RoleId, num=Num, count=Count, goods_list=GoodsList, lim_goods=LimGoods, free_time=FreeTime, time=NowTime},
    mod_secret_shop:add_to_dict(NewShopInfo),
    NewShopInfo.

%% 更新商店记录
update_shop(ShopInfo, Num, Count, GoodsList) ->
    NowTime = util:unixtime(),
    NewGoodsList = [{B#base_secret_shop.goods_id,B#base_secret_shop.goods_num} || B <- GoodsList],
    Sql = io_lib:format(?sql_update_secret, [Num, Count, util:term_to_string(NewGoodsList), NowTime, ShopInfo#ets_secret_shop.free_time, ShopInfo#ets_secret_shop.role_id]),
    db:execute(Sql),
    NewShopInfo = ShopInfo#ets_secret_shop{num=Num, count=Count, goods_list=GoodsList, time=NowTime},
    mod_disperse:cast_to_unite(mod_secret_shop, add_to_dict, [NewShopInfo]),
    NewShopInfo.

%% 更改商店物品列表
change_goods_list(ShopInfo, GoodsList, LimGoods) ->
    NowTime = util:unixtime(),
    NewGoodsList = [{B#base_secret_shop.goods_id,B#base_secret_shop.goods_num} || B <- GoodsList],
    Sql = io_lib:format(?sql_update_secret2, [util:term_to_string(NewGoodsList), util:term_to_string(LimGoods), NowTime, ShopInfo#ets_secret_shop.role_id]),
    db:execute(Sql),
    NewShopInfo = ShopInfo#ets_secret_shop{goods_list=GoodsList, lim_goods=LimGoods, time=NowTime},
    mod_disperse:cast_to_unite(mod_secret_shop, add_to_dict, [NewShopInfo]),
    NewShopInfo.

%% 初始化 ETS
init(RoleId, Lv) ->
    case get_shop_db(RoleId) of
        [] -> 
            skip;
        Data -> 
            new(Data, Lv, RoleId)
    end,
    ok.

%% 构造ETS
new([Mrole_id, Mnum, Mcount, Mgoods_list, Mlim_goods, Mtime, FreeTime], Lv, RoleId) ->
    GoodsList1 = new_goods_list(lib_goods_util:to_term(Mgoods_list)),
    case GoodsList1 =/= [] of
        true ->
            Info = #ets_secret_shop{
                    role_id = Mrole_id,
                    num = Mnum,
                    count = Mcount,
                    goods_list = GoodsList1,
                    lim_goods = lib_goods_util:to_term(Mlim_goods),
                    time = Mtime,
                    free_time = FreeTime
              },
            mod_secret_shop:add_to_dict(Info);
        false ->
            GoodsList = data_secret_shop:get_goods(),
            %% 限制物品
            LimGoods = [{B#base_secret_shop.goods_id, B#base_secret_shop.lim_min} || B <- GoodsList, B#base_secret_shop.lim_min > 0],
            Count = 0,
            Free = 3,
            {ok, NewGoodsList, NewCount} = batch_refresh(1, [], Count, [GoodsList, LimGoods, Lv]),
            Info = add_shop(RoleId, NewCount, NewGoodsList, LimGoods, Free)
    end,
    Info.

new_goods_list([H|T]) ->
    case new_goods(H) of
        [] -> new_goods_list(T);
        B -> [B|new_goods_list(T)]
    end;
new_goods_list([]) -> [].

new_goods({Goods_id,Goods_num}) ->
    case data_secret_shop:get_goods(Goods_id) of
        [] -> [];
        B -> B#base_secret_shop{goods_num=Goods_num}
    end;
new_goods({base_secret_shop,Goods_id,Price,Bind,Notice,Ratio_Start,Ratio_End, Min_lv, Max_lv}) ->
    #base_secret_shop{goods_id=Goods_id, price=Price, bind=Bind, notice=Notice, ratio_start=Ratio_Start,ratio_end=Ratio_End, min_lv=Min_lv, max_lv=Max_lv, lim_min=0, goods_num=1};
new_goods({base_secret_shop,Goods_id,Price,Bind,Notice,Ratio_Start,Ratio_End,Min_lv, Max_lv,Lim_min}) ->
    #base_secret_shop{goods_id=Goods_id, price=Price, bind=Bind, notice=Notice, ratio_start=Ratio_Start,ratio_end=Ratio_End, min_lv=Min_lv, max_lv=Max_lv, lim_min=Lim_min, goods_num=1};
new_goods({base_secret_shop,Goods_id,Price,Bind,Notice,Ratio_Start,Ratio_End,Min_lv, Max_lv,Lim_min,Goods_num}) ->
    #base_secret_shop{goods_id=Goods_id, price=Price, bind=Bind, notice=Notice, ratio_start=Ratio_Start,ratio_end=Ratio_End, min_lv=Min_lv, max_lv=Max_lv, lim_min=Lim_min, goods_num=Goods_num};
new_goods(_) ->
    [].



