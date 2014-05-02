%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-27
%% Description: 商店,商城协议
%% --------------------------------------------------------
-module(pt_153).
-include("shop.hrl").
-include("goods.hrl").
-export([read/2, write/2]).

%% 
%% 客户端 ->服务器
%%
%% 取商店物品列表
%% ShopType:商店NPC编号，1为商城
%% ShopSubtype:商店子类型，全部则为0
read(15300, <<ShopType:32, ShopSubtype:16>>) ->
    {ok, [ShopType, ShopSubtype]};

%% 取兑换商店物品列表
read(15301, <<NpcId:32>>) ->
    {ok, NpcId};

%% 获取限时热买商品列表
read(15305, _) ->
    {ok, []};

%%购买物品
read(15310, <<GoodsTypeId:32, GoodsNum:16, ShopType:32, ShopSubtype:16, PayMoneyType:8>>) ->
    {ok, [GoodsTypeId, GoodsNum, ShopType, ShopSubtype, PayMoneyType]};

%%出售物品
read(15311, <<ShopType:32, Num:16, Bin/binary>>) ->
    {_, GoodsList} = pt:read_id_num_list(Bin, [], Num),
    {ok, [ShopType, GoodsList]};

%% 查询连续登录商店
read(15312, _) ->
    {ok, []};

%% 购买限购商品
read(15315, <<Pos:8, GoodsTypeId:32, GoodsNum:16>>) ->
    {ok, [Pos, GoodsTypeId, GoodsNum]};

read(_Cmd, _R) ->
    {error, no_match}.

%% 
%% 服务器 ->客户端
%% 
%%取商店物品列表
write(15300, [ShopType, ShopSubtype, ShopList]) ->
    ListNum = length(ShopList),
    F = fun(ShopInfo) ->
            GoodsId = ShopInfo#ets_shop.goods_id,
            NewPrice = ShopInfo#ets_shop.new_price,
            Subtype = ShopInfo#ets_shop.shop_subtype,
            GoodsNum = ShopInfo#ets_shop.goods_num,
            <<GoodsId:32, NewPrice:32, Subtype:16, GoodsNum:32>>
        end,
     ListBin = list_to_binary(lists:map(F, ShopList)),
    {ok, pt:pack(15300, <<ShopType:32, ShopSubtype:16, ListNum:16, ListBin/binary>>)};

%% 取兑换商店物品列表
write(15301, [NpcId, RemainNum, ExchangeList]) ->
    ListNum = length(ExchangeList),
    F = fun(Info) ->
            Id = Info#ets_goods_exchange.id,
            Type = Info#ets_goods_exchange.type,
            Bind = Info#ets_goods_exchange.bind,
            Honour = Info#ets_goods_exchange.honour,
            KingHonour = Info#ets_goods_exchange.king_honour,
            [Item1|_] = Info#ets_goods_exchange.raw_goods,
            [Item2|_] = Info#ets_goods_exchange.dst_goods,
            case Item1 of
                {arena, Num} -> ok;
                {battle, Num} -> ok;
                {master, Num} -> ok;
                {coin, Num} -> ok;
                {llpt, Num} -> ok;
                _ -> Num = 0
            end,
            case Item2 of
                {goods, TypeId, _} -> Prefix = 0;
                {equip, TypeId, Prefix, _} -> ok;
                _ -> TypeId = 0, Prefix = 0
            end,
            <<Id:32, Type:8, Num:32, TypeId:32, Prefix:16, Bind:16, Honour:32, KingHonour:32>>
        end,
    ListBin = list_to_binary(lists:map(F, ExchangeList)),
    {ok, pt:pack(15301, <<NpcId:32, RemainNum:16, ListNum:16, ListBin/binary>>)};

%% 获取限时热买商品列表
write(15305, [ShopList, NowTime]) ->
    Len = length(ShopList),
    F = fun(ShopInfo) ->
                Id = ShopInfo#ets_limit_shop.id,
                ShopId = ShopInfo#ets_limit_shop.shop_id,
                GoodsId = ShopInfo#ets_limit_shop.goods_id,
                GoodsNum = ShopInfo#ets_limit_shop.goods_num,
                PriceType = ShopInfo#ets_limit_shop.price_type,
                OldPrice = ShopInfo#ets_limit_shop.old_price,
                NewPrice = ShopInfo#ets_limit_shop.new_price,
                TimeEnd = ShopInfo#ets_limit_shop.time_end,
                ActiEnd = ShopInfo#ets_limit_shop.activity_end,
		LimitNum = ShopInfo#ets_limit_shop.limit_num,
                Change = case ShopInfo#ets_limit_shop.price_list of
                             [] ->
                                 0;
                             _R ->
                                 1
                         end,
            <<ShopId:8, GoodsId:32, GoodsNum:16, PriceType:8, OldPrice:32, NewPrice:32, TimeEnd:32, ActiEnd:32, Change:8, Id:32, LimitNum:16>>
        end,
    ListBin = list_to_binary(lists:map(F, ShopList)),
    {ok,pt:pack(15305, <<NowTime:32, Len:16, ListBin/binary>>)};

%%购买物品
write(15310, [Res, GoodsTypeId, GoodsNum, ShopType, NewBcoin, NewCoin, NewSilver, NewGold, NewPoint, GoodsList]) ->
    ListNum = length(GoodsList),
    F = fun(GoodsInfo) ->
            GoodsId = GoodsInfo#goods.id,
            TypeId = GoodsInfo#goods.goods_id,
            Cell = GoodsInfo#goods.cell,
            Num = GoodsInfo#goods.num,
            Bind = GoodsInfo#goods.bind,
            Trade = GoodsInfo#goods.trade,
            Sell = GoodsInfo#goods.sell,
            Isdrop = GoodsInfo#goods.isdrop,
            Stren = GoodsInfo#goods.stren,
            Attrition = data_goods:count_goods_attrition(GoodsInfo#goods.equip_type, GoodsInfo#goods.attrition, GoodsInfo#goods.use_num),
            <<GoodsId:32, TypeId:32, Cell:16, Num:16, Attrition:16, Bind:8, Trade:8, Sell:8, Isdrop:8, Stren:16>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(15310, <<Res:16, GoodsTypeId:32, GoodsNum:16, ShopType:32, NewBcoin:32, NewCoin:32, NewSilver:32, NewGold:32, NewPoint:32, ListNum:16, ListBin/binary>>)};

%%出售物品
write(15311, Res) ->
    {ok, pt:pack(15311, <<Res:16>>)};

%% 查询连续登录商店
write(15312, [ShopType, ShopSubtype, GoodsList]) ->
    ShopGoodsNum = length(GoodsList),
    F = fun(EtsShop) ->
            GoodsTypeId = EtsShop#ets_shop.goods_id,
            NewPrice = EtsShop#ets_shop.new_price,
            SubType = EtsShop#ets_shop.shop_subtype,
            GoodsNum = EtsShop#ets_shop.goods_num,
            <<GoodsTypeId:32, NewPrice:32, SubType:16, GoodsNum:32>>
    end,
    ShopBinInfo = list_to_binary( [F(Goods) || Goods <- GoodsList] ),
    {ok, pt:pack(15312, <<ShopType:32, ShopSubtype:16, ShopGoodsNum:16, ShopBinInfo/binary>>)};

%%购买热卖物品
write(15315, [Res, GoodsTypeId, GoodsNum, NewBcoin, NewCoin, NewSilver, NewGold, NewPoint, GoodsList]) ->
    ListNum = length(GoodsList),
    F = fun(GoodsInfo) ->
            GoodsId = GoodsInfo#goods.id,
            TypeId = GoodsInfo#goods.goods_id,
            Cell = GoodsInfo#goods.cell,
            Num = GoodsInfo#goods.num,
            Bind = GoodsInfo#goods.bind,
            Trade = GoodsInfo#goods.trade,
            Sell = GoodsInfo#goods.sell,
            Isdrop = GoodsInfo#goods.isdrop,
            Stren = GoodsInfo#goods.stren,
            Attrition = data_goods:count_goods_attrition(GoodsInfo#goods.equip_type, GoodsInfo#goods.attrition, GoodsInfo#goods.use_num),
            <<GoodsId:32, TypeId:32, Cell:16, Num:16, Attrition:16, Bind:8, Trade:8, Sell:8, Isdrop:8, Stren:16>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(15315, <<Res:16, GoodsTypeId:32, GoodsNum:16, NewBcoin:32, NewCoin:32, NewSilver:32, NewGold:32, NewPoint:32, ListNum:16, ListBin/binary>>)};


write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.




