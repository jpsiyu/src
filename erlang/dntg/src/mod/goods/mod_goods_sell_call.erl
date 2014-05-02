%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-7
%% Description: 物品市场操作
%% --------------------------------------------------------
-module(mod_goods_sell_call).
-export([handle_call/3]).
-include("goods.hrl").
-include("common.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("errcode_goods.hrl").
-include("server.hrl").
-include("sell.hrl").
-include("shop.hrl").

% 挂售物品上架
handle_call({'sell_up', PlayerStatus, GoodsId, Num, PriceType, Price, Time, Show}, _From, GoodsStatus) ->
    case check_sell_up(PlayerStatus, GoodsId, Num, PriceType, Price, Time, GoodsStatus, Show) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, #ets_sell{}, #goods{}], GoodsStatus};
        {ok, SellInfo, GoodsInfo, Cost} ->
            case lib_goods_sell:sell_up(PlayerStatus, GoodsStatus, SellInfo, GoodsInfo, Cost, Show) of
                {ok, NewPlayerStatus, NewStatus, NewSellInfo} ->
                    {reply, [NewPlayerStatus, 1, NewSellInfo, GoodsInfo], NewStatus};
                Error ->
                    util:errlog("mod_goods_sell sell_up:~p", [Error]),
                    {reply, [PlayerStatus, 0, #ets_sell{}, #goods{}], GoodsStatus}
            end
    end;

% 再次挂售
handle_call({'resell', PlayerStatus, Id}, _From, GoodsStatus) ->
    case check_resell(PlayerStatus, Id) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, #ets_sell{}], GoodsStatus};
        {ok, SellInfo, Cost} ->
            case lib_goods_sell:resell(PlayerStatus, SellInfo, Cost) of
                {ok, NewPlayerStatus, NewSellInfo} ->
                    {reply, [NewPlayerStatus, 1, NewSellInfo], GoodsStatus};
                Error ->
                    util:errlog("mod_goods_sell resell:~p", [Error]),
                    {reply, [PlayerStatus, 0, #ets_sell{}], GoodsStatus}
            end
    end;

%% 挂售物品下架
handle_call({'sell_down', PlayerStatus, Id}, _From, GoodsStatus) ->
    case check_sell_down(GoodsStatus, Id) of
        {fail, Res1} ->
            {reply, [PlayerStatus, Res1], GoodsStatus};
        {ok, SellInfo, GoodsInfo} ->
            case mod_disperse:call_to_unite(mod_sell, call_sell_down, [Id]) of
                {badrpc, _} ->
                    {reply, [PlayerStatus, 0], GoodsStatus};
                {fail, Res2} ->
                    {reply, [PlayerStatus, Res2], GoodsStatus};
                ok ->
                    case lib_goods_sell:sell_down(PlayerStatus, GoodsStatus, SellInfo, GoodsInfo) of
                        {fail, Res3} ->
                            {reply, [PlayerStatus, Res3], GoodsStatus};
                        {ok, NewPlayerStatus, NewStatus} ->
                            {reply, [NewPlayerStatus, 1], NewStatus};
                        _Error ->
                            mod_disperse:call_to_unite(mod_sell, cast_sell_reload, [Id]),
                            {reply, [PlayerStatus, 0], GoodsStatus}
                    end
            end
    end;
    
%% 购买挂售物品
handle_call({'pay_sell', PlayerStatus, Id}, _From, GoodsStatus) ->
    case check_pay_sell(PlayerStatus, GoodsStatus, Id) of
        {fail, Res1} ->
            {reply, [PlayerStatus, Res1], GoodsStatus};
        {ok, SellInfo, GoodsInfo} ->
            case mod_disperse:call_to_unite(mod_sell, call_sell_down, [Id]) of
                {badrpc, _} ->
                    {reply, [PlayerStatus, 0], GoodsStatus};
                {fail, Res2} ->
                    {reply, [PlayerStatus, Res2], GoodsStatus};
                ok ->
                    case lib_goods_sell:pay_sell(PlayerStatus, GoodsStatus, SellInfo, GoodsInfo) of
                        {fail, Res3} ->
                            {reply, [PlayerStatus, Res3], GoodsStatus};
                        {ok, NewPlayerStatus, NewStatus} ->
                            {reply, [NewPlayerStatus, 1], NewStatus};
                        _Error ->
                            mod_disperse:call_to_unite(mod_sell, cast_sell_reload, [Id]),
                            {reply, [PlayerStatus, 0], GoodsStatus}
                    end
            end
    end;

%% 出售求购物品
handle_call({'pay_buy', PlayerStatus, Id, GoodsId}, _From, GoodsStatus) ->
    case check_pay_buy(PlayerStatus, Id, GoodsId) of
        {fail, Res1} ->
            {reply, [PlayerStatus, Res1, 0], GoodsStatus};
        {ok, WtbInfo, GoodsInfo} ->
            case mod_disperse:call_to_unite(mod_buy, call_buy_down, [Id]) of
                {badrpc, _} ->
                    {reply, [PlayerStatus, 0], GoodsStatus};
                {fail, Res2} ->
                    {reply, [PlayerStatus, Res2], GoodsStatus};
                ok ->
                    case lib_goods_sell:pay_buy(PlayerStatus, GoodsStatus, WtbInfo, GoodsInfo) of
                        {fail, Res3} ->
                            {reply, [PlayerStatus, Res3, 1], GoodsStatus};
                        {ok, NewPlayerStatus, NewStatus, MailInfo} ->
                            Title = data_sell_text:mail_sys(),
                            mod_disperse:call_to_unite(mod_mail, update_mail_info, [WtbInfo#ets_buy.pid, [MailInfo], Title]),
                            {reply, [NewPlayerStatus, 1, 1], NewStatus};
                        Error ->
                            util:errlog("mod_goods_sell pay_buy:~p", [Error]),
                            {reply, [PlayerStatus, 0, 0], GoodsStatus}
                    end
            end
    end;

%% 完成交易 第一步
handle_call({'finish_sell_one', PlayerStatus, SellerPlayerStatus}, _From, GoodsStatus) ->
    case check_finish_sell(PlayerStatus, SellerPlayerStatus, GoodsStatus) of
        {fail, Res} ->
            {reply, {fail, Res}, GoodsStatus};
        ok ->
            case catch(gen:call(SellerPlayerStatus#player_status.pid, '$gen_call', {'finish_sell', PlayerStatus, GoodsStatus})) of
                {ok, {ok, NewPlayerStatus, NewGoodsStatus, NewSellerPlayerStatus}} ->
                    {reply, {ok, NewPlayerStatus, NewSellerPlayerStatus}, NewGoodsStatus};
                {ok, {fail, Res}} ->
                    {reply, {fail, Res}, GoodsStatus};
                Error ->
                    util:errlog("mod_goods_sell finish_sell_one:~p", [Error]),
                    {reply, {fail, 0}, GoodsStatus}
            end
    end;

%% 完成交易 第二步
handle_call({'finish_sell_two', PlayerStatus, SellerPlayerStatus, SellerGoodsStatus}, _From, GoodsStatus) ->
    case check_finish_sell(PlayerStatus, SellerPlayerStatus, GoodsStatus) of
        {fail, Res} ->
            {reply, {fail, Res}, GoodsStatus};
        ok ->
            case lib_goods_sell:finish_sell(PlayerStatus, GoodsStatus, SellerPlayerStatus, SellerGoodsStatus) of
                {ok, NewPlayerStatus, NewGoodsStatus, NewSellerPlayerStatus, NewSellerGoodsStatus} ->
                    {reply, {ok, NewPlayerStatus, NewSellerPlayerStatus, NewSellerGoodsStatus}, NewGoodsStatus};
                Error ->
                    util:errlog("mod_goods_sell finish_sell_two:~p", [Error]),
                    {reply, {fail, 0}, GoodsStatus}
            end
    end;

%%购买物品
handle_call({'pay', PlayerStatus, GoodsTypeId, GoodsNum, ShopType, ShopSubtype, PayMoneyType}, _From, GoodsStatus) ->
    %% 检查
    case lib_goods_check:check_pay(PlayerStatus, GoodsStatus, GoodsTypeId, GoodsNum, ShopType, ShopSubtype, PayMoneyType) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, []], GoodsStatus};
        {ok, GoodsTypeInfo, GoodsList, ShopInfo, Cost} ->
            case lib_shop:pay_goods(PlayerStatus, GoodsStatus, GoodsTypeInfo, GoodsList, GoodsNum, ShopInfo, Cost, PayMoneyType) of
                {ok, NewPlayerStatus, NewStatus} ->
                    NewGoodsList = lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id, GoodsTypeId, 
                                                      GoodsTypeInfo#ets_goods_type.bind, ?GOODS_LOC_BAG, NewStatus#goods_status.dict),
                    {reply, [NewPlayerStatus, ?ERRCODE_OK, NewGoodsList], NewStatus};
                Error ->
                    util:errlog("mod_goods pay:~p", [Error]),
                    {reply, [PlayerStatus, ?ERRCODE15_FAIL, []], GoodsStatus}
            end
    end;

%%购买限时物品
handle_call({'pay_limit', PlayerStatus, Pos, GoodsId, GoodsNum}, _From, GoodsStatus) ->
    %% 检查
    case lib_goods_check:check_limit_pay(PlayerStatus, GoodsStatus, Pos, GoodsId, GoodsNum) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, 0, []], GoodsStatus};
        {ok, GoodsTypeInfo, GoodsList, ShopInfo} ->
            case lib_shop:pay_limit_goods(PlayerStatus, GoodsStatus, GoodsTypeInfo, GoodsList, GoodsNum, ShopInfo) of
                {ok, NewPlayerStatus, NewStatus} ->
                    NewGoodsList = lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id, ShopInfo#ets_limit_shop.goods_id, GoodsTypeInfo#ets_goods_type.bind, 
                                                                      ?GOODS_LOC_BAG, NewStatus#goods_status.dict),
					%% 运势任务(3700005:限时抢购)
					lib_fortune:fortune_daily(NewPlayerStatus#player_status.id, 3700005, 1),
                    {reply, [NewPlayerStatus, ?ERRCODE_OK, ShopInfo#ets_limit_shop.goods_id, NewGoodsList], NewStatus};
                Error ->
                    util:errlog("mod_goods pay_limit:~p", [Error]),
                    {reply, [PlayerStatus, ?ERRCODE15_FAIL, []], GoodsStatus}
            end
    end;

%% 出售物品
handle_call({'sell', PlayerStatus, ShopType, GoodsList}, _From, GoodsStatus) ->
    %% 检查
    case lib_goods_check:check_sell(PlayerStatus, ShopType, GoodsList, GoodsStatus) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res], GoodsStatus};
        {ok, NewCoin, NewBcoin, NewGoodsList} ->
            %% 出售
            case lib_shop:sell_goods(PlayerStatus, GoodsStatus, NewCoin, NewBcoin, NewGoodsList) of
                {ok, NewPlayerStatus, NewStatus} ->
                    {reply, [NewPlayerStatus, ?ERRCODE_OK], NewStatus};
                Error ->
                    util:errlog("mod_goods sell:~p", [Error]),
                    {reply, [PlayerStatus, ?ERRCODE15_FAIL], GoodsStatus}
            end
    end;

%%------------------- 神秘商店  ---------------------------------------------------------
%% 刷新神秘商店
handle_call({'refresh_secret', PlayerStatus, Type, GoodsId, Num}, _From, GoodsStatus) ->
    case lib_goods_check:check_refresh_secret(PlayerStatus, GoodsStatus, Type, GoodsId, Num) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, #ets_secret_shop{}], GoodsStatus};
        {ok, ShopInfo, GoodsInfo} ->
            case lib_secret_shop:refresh(PlayerStatus, GoodsStatus, ShopInfo, GoodsInfo, Type, Num) of
                {ok, NewPlayerStatus, NewStatus, NewShopInfo} ->
                    {reply, [NewPlayerStatus, 1, NewShopInfo], NewStatus};
                Error ->
                    ?INFO("mod_goods refresh_secret:~p", [Error]),
                    {reply, [PlayerStatus, 10, []], GoodsStatus}
            end
    end;

%% 购买神秘商店物品
handle_call({'pay_secret', PlayerStatus, GoodsId, Num}, _From, GoodsStatus) ->
    case lib_goods_check:check_pay_secret(PlayerStatus, GoodsStatus, GoodsId, Num) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, 0, []], GoodsStatus};
        {ok, ShopInfo, ShopGoods, GoodsTypeInfo} ->
            case lib_secret_shop:pay(PlayerStatus, GoodsStatus, ShopInfo, ShopGoods, GoodsTypeInfo, Num) of
                {ok, NewPlayerStatus, NewStatus, NewShopInfo} ->
                    lib_player:refresh_client(PlayerStatus#player_status.id, 2),
                    case ShopGoods#base_secret_shop.notice =:= 1 of
                        true -> 
                            mod_disperse:cast_to_unite(mod_secret_shop, cast_notice_add, [[NewPlayerStatus#player_status.nickname, ShopGoods#base_secret_shop.goods_id, NewPlayerStatus#player_status.realm]]),
                            {ok, BinData} = pt_152:write(15204, [NewPlayerStatus#player_status.nickname, ShopGoods#base_secret_shop.goods_id, NewPlayerStatus#player_status.realm]),
                            %% 传闻
                            lib_chat:send_TV({all},0,2, ["shenmiShop", 
												   1, 
												   NewPlayerStatus#player_status.id, 
												   NewPlayerStatus#player_status.realm, 
												   NewPlayerStatus#player_status.nickname, 
												   NewPlayerStatus#player_status.sex, 
												   NewPlayerStatus#player_status.career, 
												   NewPlayerStatus#player_status.image, 
												   GoodsTypeInfo#ets_goods_type.goods_id]),
                            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData);
                        false -> 
                            skip
                    end,
                    {reply, [NewPlayerStatus, 1, NewShopInfo#ets_secret_shop.num, NewShopInfo#ets_secret_shop.goods_list], NewStatus};
                Error ->
                    ?INFO("mod_goods pay_secret:~p", [Error]),
                    {reply, [PlayerStatus, 10, 0, []], GoodsStatus}
            end
    end;

handle_call(_Cmd, _From, GoodsStatus) ->
    {noreply, GoodsStatus}.
%% --------------------------- private fun ------------------------------------------------------------- 
check_sell_up(PlayerStatus, GoodsId, Num, PriceType, Price, Time, GoodsStatus, Show) ->
    SellMaxNum = case mod_disperse:call_to_unite(lib_buy, self_list_count, [PlayerStatus#player_status.id]) of
                    %% 公共线错误
                    {badrpc,_Reason} -> 0;
                    %% 求购物品数量已达上限
                    MaxNum when is_number(MaxNum) -> MaxNum;
                    _ -> 0
                end,
    %% 挂售价钱
    Cost1 = data_goods:count_sell_cost(GoodsId, PriceType, Price, Time),
    %% 发传闻收10000铜币
    Cost = case Show =:= 0 of
               true ->
                   Cost1;
               false ->
                   Cost1 + 10000
           end,
    case GoodsId =:= 0 of
        %% 金钱
        true ->
            case PlayerStatus#player_status.bcoin < Cost of
                    false -> Coin = PlayerStatus#player_status.coin;
                    true -> Coin = (PlayerStatus#player_status.bcoin + PlayerStatus#player_status.coin - Cost)
            end,
            Sell = PlayerStatus#player_status.sell,
            if  %% 保管费不足
                Coin < 0 ->
                    {fail, 2};
                %% 正在交易中
                Sell#status_sell.sell_status =/= 0 ->
                    {fail, 9};
                %% 已达上限
                SellMaxNum >= ?GOODS_SELF_SELL_LIMIT ->
                    {fail, 10};
                %% 金钱不足
                PriceType =:= 0 andalso PlayerStatus#player_status.gold < Num ->
                    {fail, 3};
                PriceType =:= 1 andalso Coin < Num  ->
                    {fail, 3};
                %% 参数错误
                Num < 1 orelse Num > 99999999 ->
                    {fail, 8};
                %% 参数错误
                (PriceType =/= 0 andalso PriceType =/= 1) orelse Price < 1 orelse Price > 99999999 ->
                    {fail, 8};
                %% 参数错误
                Time =/= 6 andalso Time =/= 12 andalso Time =/= 24 ->
                    {fail, 8};
                true ->
                    {GoodsName, SellClass} = case PriceType of
                                    0 -> 
                                        {data_sell_text:goods_name(0), data_sell:get_sell_class(1, 1, 0, 0)};
                                    1 -> 
                                        {data_sell_text:goods_name(1), data_sell:get_sell_class(2, 2, 0, 0)}
                                end,
                    EndTime = util:unixtime() + Time*3600,
                    %% id: 1元宝，2铜币
                    TypeId = case PriceType of
                        0 -> 611103;
                        1 -> 611104
                    end,
                    {Class1, Class2} = {SellClass#ets_sell_class.max_type, SellClass#ets_sell_class.min_type},
                    SellInfo = #ets_sell{class1=Class1, class2=Class2, pid=PlayerStatus#player_status.id, goods_id=TypeId,goods_name = GoodsName, num=Num, price_type=PriceType, price=Price, time=Time, end_time=EndTime},
                    {ok, SellInfo, #goods{}, Cost}
            end;
        %% 物品
        false ->
            NowTime = util:unixtime(),
            GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
            Sell = PlayerStatus#player_status.sell,
            if
                %% 保管费不足
                (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Cost ->
                    {fail, 2};
                %% 正在交易中
                Sell#status_sell.sell_status =/= 0 ->
                    {fail, 9};
                %% 已达上限
                SellMaxNum >= ?GOODS_SELF_SELL_LIMIT ->
                    {fail, 10};
                %% 物品不存在
                is_record(GoodsInfo, goods) =:= false ->
                    {fail, 4};
                %% 物品不属于你所有
                GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
                    {fail, 5};
                %% 物品不在背包
                GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
                    {fail, 6};
                %% 物品不可出售
                GoodsInfo#goods.bind =:= 2 orelse GoodsInfo#goods.trade =:= 1 ->
                    {fail, 7};
                %% 参数错误
                Num < 1 orelse GoodsInfo#goods.num =/= Num ->
                    {fail, 8};
                %% 参数错误
                (PriceType =/= 0 andalso PriceType =/= 1) orelse Price < 1 orelse Price > 99999999 ->
                    {fail, 8};
                %% 参数错误
                Time =/= 6 andalso Time =/= 12 andalso Time =/= 24 ->
                    {fail, 8};
                %% 物品已过期
                GoodsInfo#goods.expire_time > 0 andalso GoodsInfo#goods.expire_time =< NowTime ->
                    {fail, 11};
                true ->
                    Lv_num = data_goods:get_level(GoodsInfo#goods.level),
                    EndTime = util:unixtime() + Time*3600,
                    GoodsTypeInfo = data_goods_type:get(GoodsInfo#goods.goods_id),
                    SellClass = data_sell:get_sell_class(GoodsTypeInfo#ets_goods_type.type, GoodsTypeInfo#ets_goods_type.subtype, GoodsTypeInfo#ets_goods_type.career, GoodsTypeInfo#ets_goods_type.sex),
                    {Class1, Class2} = {SellClass#ets_sell_class.max_type, SellClass#ets_sell_class.min_type},
                    SellInfo = #ets_sell{class1=Class1, class2=Class2, gid=GoodsId, pid=PlayerStatus#player_status.id, 
                                            goods_id=GoodsInfo#goods.goods_id, goods_name = GoodsTypeInfo#ets_goods_type.goods_name, 
                                            num=Num, type=GoodsInfo#goods.type, subtype=GoodsInfo#goods.subtype, lv=GoodsInfo#goods.level, 
                                            lv_num=Lv_num, color=GoodsInfo#goods.color, career=GoodsTypeInfo#ets_goods_type.career, 
                                            price_type=PriceType, price=Price, time=Time, end_time=EndTime},
                    {ok, SellInfo, GoodsInfo, Cost}
            end
    end.

check_resell(PlayerStatus, Id) ->
    case mod_disperse:call_to_unite(lib_sell, get_sell, [Id]) of
        %% 物品不在架上
        [] -> {fail, 2};
        [SellInfo] ->
            NowTime = util:unixtime(),
            if  is_record(SellInfo, ets_sell) =:= false ->
                    {fail, 2};
                %% 交易物品还未过期
                SellInfo#ets_sell.is_expire =/= 1 ->
                    {fail, 3};
                %% 交易物品已过期
                SellInfo#ets_sell.is_expire =:= 1 andalso (SellInfo#ets_sell.expire_time - NowTime) < 600 ->
                    {fail, 7};
                %% 物品不属于你所有
                SellInfo#ets_sell.pid =/= PlayerStatus#player_status.id ->
                    {fail, 4};
                true ->
                    Cost = data_goods:count_sell_cost(SellInfo#ets_sell.gid, SellInfo#ets_sell.price_type, SellInfo#ets_sell.price, SellInfo#ets_sell.time),
                    Sell = PlayerStatus#player_status.sell,
                    if  %% 保管费不足
                        (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Cost ->
                            {fail, 5};
                        %% 正在交易中
                        Sell#status_sell.sell_status =/= 0 ->
                            {fail, 6};
                        true ->
                            {ok, SellInfo, Cost}
                    end
            end;
         _ -> {fail, 0}
    end.

check_sell_down(GoodsStatus, Id) ->
    case mod_disperse:call_to_unite(lib_sell, get_sell, [Id]) of
        %% 物品不在架上
        [] -> {fail, 2};
        [SellInfo] ->
            if  is_record(SellInfo, ets_sell) =:= false ->
                    {fail, 2};
                %% 物品不属于你所有
                SellInfo#ets_sell.pid =/= GoodsStatus#goods_status.player_id ->
                    {fail, 3};
                %% 背包格子不足
                SellInfo#ets_sell.gid > 0 andalso length(GoodsStatus#goods_status.null_cells) =:= 0 ->
                    {fail, 4};
                true ->
                    case SellInfo#ets_sell.gid > 0 of
                        true ->
                            case lib_goods_util:get_goods_info(SellInfo#ets_sell.gid, GoodsStatus#goods_status.dict) of
                                %% 交易物品不存在
                                [] -> {fail, 5};
                                GoodsInfo when is_record(GoodsInfo, goods) =:= false ->
                                    {fail, 5};
                                %% 物品位置不正确
                                GoodsInfo when GoodsInfo#goods.location =/= ?GOODS_LOC_SELL -> 
                                    {fail, 6};
                                %% 物品不属于你所有
                                GoodsInfo when GoodsInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
                                    {fail, 3};
                                GoodsInfo ->
                                    {ok, SellInfo, GoodsInfo}
                            end;
                        false -> {ok, SellInfo, []}
                    end
            end;
         _ -> {fail, 0}
    end.

check_pay_sell(PlayerStatus, GoodsStatus, Id) ->
    case  mod_disperse:call_to_unite(lib_sell, get_sell, [Id]) of
        [] -> {fail, 2};
        [SellInfo] ->
            if  is_record(SellInfo, ets_sell) =:= false ->
                    {fail, 2};
                %% 金钱不足
                SellInfo#ets_sell.price_type =:= 0 andalso PlayerStatus#player_status.coin < SellInfo#ets_sell.price ->
                    {fail, 3};
                %% 金钱不足
                SellInfo#ets_sell.price_type =:= 1 andalso PlayerStatus#player_status.gold < SellInfo#ets_sell.price ->
                    {fail, 3};
                %% 背包格子不足
                SellInfo#ets_sell.gid > 0 andalso length(GoodsStatus#goods_status.null_cells) =:= 0 ->
                    {fail, 4};
                %% 交易物品已过期
                SellInfo#ets_sell.is_expire =:= 1 ->
                    {fail, 7};
                true ->
                    case SellInfo#ets_sell.gid > 0 of
                        true ->
                            NowTime = util:unixtime(),
                            case lib_goods_util:get_goods_info(SellInfo#ets_sell.gid, GoodsStatus#goods_status.dict) of
                                %% 交易物品不存在
                                [] -> {fail, 5};
                                GoodsInfo when is_record(GoodsInfo, goods) =:= false ->
                                    {fail, 5};
                                %% 物品位置不正确
                                GoodsInfo when GoodsInfo#goods.location =/= ?GOODS_LOC_SELL ->
                                    {fail, 6};
                                %% 物品已过期
                                GoodsInfo when GoodsInfo#goods.expire_time > 0 andalso GoodsInfo#goods.expire_time =< NowTime ->
                                    {fail, 7};
                                GoodsInfo ->
                                    {ok, SellInfo, GoodsInfo}
                            end;
                        false -> {ok, SellInfo, []}
                    end
            end;
        _ -> {fail, 0}
    end.

%% 求购检查
check_pay_buy(PlayerStatus, Id, GoodsId) ->
    case  mod_disperse:call_to_unite(ets, lookup, [?ETS_BUY, Id]) of
        %% 没有找到该记录
        [] -> {fail, 2};
        [WtbInfo] when is_record(WtbInfo, ets_buy) ->
            NowTime = util:unixtime(),
            GoodsInfo = lib_goods_util:get_goods(GoodsId),
            Sell = PlayerStatus#player_status.sell,
            if
                %% 物品不存在
                is_record(GoodsInfo, goods) =:= false ->
                    {fail, 3};
                %% 物品不属于你所有
                GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
                    {fail, 4};
                %% 物品位置不正确
                GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
                    {fail, 5};
                %% 物品条件不符
                GoodsInfo#goods.goods_id =/= WtbInfo#ets_buy.goods_id ->
                    {fail, 6};
                %% 物品条件不符
                GoodsInfo#goods.stren < WtbInfo#ets_buy.stren ->
                    {fail, 6};
                %% 物品条件不符
                GoodsInfo#goods.prefix < WtbInfo#ets_buy.prefix ->
                    {fail, 6};
                %% 物品条件不符
                GoodsInfo#goods.num < 1 ->
                    {fail, 6};
                %% 求购物品数量已满
                WtbInfo#ets_buy.num < 1 ->
                    {fail, 7};
                %% 正在交易中
                Sell#status_sell.sell_status =/= 0 ->
                    {fail, 8};
                %% 物品已过期
                GoodsInfo#goods.expire_time > 0 andalso GoodsInfo#goods.expire_time =< NowTime ->
                    {fail, 9};
                %% 物品不可出售
                GoodsInfo#goods.bind > 0 orelse GoodsInfo#goods.trade > 0 orelse GoodsInfo#goods.sell > 0 ->
                    {fail, 10};
                true ->
                    {ok, WtbInfo, GoodsInfo}
            end;
        _ -> {fail, 0}
    end.

%% 检查完成交易
check_finish_sell(PlayerStatus, SellerPlayerStatus, GoodsStatus) ->
    Sell = PlayerStatus#player_status.sell,
    if  %% 玩家还没有确认
        Sell#status_sell.sell_status =/= 4 ->
            {fail, 6};
        true ->
            Sell = PlayerStatus#player_status.sell,
            Sell2 = SellerPlayerStatus#player_status.sell,
            case lib_goods_check:list_handle(fun check_sell_goods/2, [PlayerStatus, GoodsStatus], Sell#status_sell.sell_list) of
                {fail, Res} -> {fail, Res};
                {ok, _} ->
                    CellNum1 = get_sell_goods_cell(Sell#status_sell.sell_list),
                    CellNum2 = get_sell_goods_cell(Sell2#status_sell.sell_list),
                    if  %% 背包格子不足
                        length(GoodsStatus#goods_status.null_cells) + CellNum1 < CellNum2 ->
                            {fail, 13};
                        true ->
                            ok
                    end
            end
    end.
check_sell_goods(Item, [PlayerStatus, GoodsStatus]) ->
    case Item of
        {money, Coin, Gold} ->
            if  %% 金钱不足
                PlayerStatus#player_status.coin < Coin orelse PlayerStatus#player_status.gold < Gold ->
                    {fail, 7};
                true -> 
                    {ok, [PlayerStatus, GoodsStatus]}
            end;
        {GoodsId, _, GoodsNum} ->
            GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
            if
                %% 物品不存在
                is_record(GoodsInfo, goods) =:= false ->
                    {fail, 8};
                %% 物品不属于该玩家所有
                GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
                    {fail, 9};
                %% 物品不在背包
                GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
                    {fail, 10};
                %% 物品数量不正确
                GoodsNum < 1 orelse GoodsInfo#goods.num =/= GoodsNum ->
                    {fail, 11};
                %% 物品不可交易
                GoodsInfo#goods.bind =:= 2 orelse GoodsInfo#goods.trade =:= 1 ->
                    {fail, 12};
                true ->
                    {ok, [PlayerStatus, GoodsStatus]}
            end
    end.
get_sell_goods_cell(SellList) ->
    List = lists:keydelete(money, 1, SellList),
    length(List).





