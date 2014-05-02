%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-5-21
%% Description: 神秘商店
%% --------------------------------------------------------
-module(pt_152).
-include("shop.hrl").
-export([read/2, write/2]).

%% 查询神秘商店
read(15200, _) ->
    {ok, secret_shop};

%% 刷新神秘商店
read(15201, <<GoodsId:32, Num:16, Type:8>>) ->
    {ok, [Type, GoodsId, Num]};

%% 购买神秘商店物品
read(15202, <<GoodsId:32, Num:16>>) ->
    {ok, [GoodsId, Num]};

%% 神秘商店公告列表
read(15203, _) ->
    {ok, secret_notice};

read(_Cmd, _R) ->
    {error, no_match}.

%% 获取神秘商店信息
write(15200, [Num, GoodsList, Time, Free]) ->
    ListNum = length(GoodsList),
    F = fun(Shop) ->
            GoodsTypeId = Shop#base_secret_shop.goods_id,
            Price = Shop#base_secret_shop.price,
            Bind = Shop#base_secret_shop.bind,
            Notice = Shop#base_secret_shop.notice,
            GoodsNum = Shop#base_secret_shop.goods_num,
            PriceType =  Shop#base_secret_shop.price_type,
            <<GoodsTypeId:32, Price:32, Bind:8, Notice:8, GoodsNum:16, PriceType:8>>
    end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(15200, <<Num:16, ListNum:16, ListBin/binary, Time:32, Free:8>>)};

%% 刷新神秘商店
write(15201, [Res, GoodsList, Num, FreeTime, RefreshTime]) ->
    ListNum = length(GoodsList),
    F = fun(Shop) ->
            GoodsTypeId = Shop#base_secret_shop.goods_id,
            Price = Shop#base_secret_shop.price,
            Bind = Shop#base_secret_shop.bind,
            Notice = Shop#base_secret_shop.notice,
            GoodsNum = Shop#base_secret_shop.goods_num,
            PriceType =  Shop#base_secret_shop.price_type,
            <<GoodsTypeId:32, Price:32, Bind:8, Notice:8, GoodsNum:16, PriceType:8>>
    end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(15201, <<Res:16, Num:16, ListNum:16, ListBin/binary, FreeTime:8, RefreshTime:32>>)};

%% 购买神秘商店物品
write(15202, [Res, Num, GoodsList]) ->
    ListNum = length(GoodsList),
    F = fun(Shop) ->
            GoodsTypeId = Shop#base_secret_shop.goods_id,
            Price = Shop#base_secret_shop.price,
            Bind = Shop#base_secret_shop.bind,
            Notice = Shop#base_secret_shop.notice,
            GoodsNum = Shop#base_secret_shop.goods_num,
            PriceType =  Shop#base_secret_shop.price_type,
            <<GoodsTypeId:32, Price:32, Bind:8, Notice:8, GoodsNum:16, PriceType:8>>
    end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(15202, <<Res:16, Num:16, ListNum:16, ListBin/binary>>)};

%% 神秘商店公告列表
write(15203, NoticeList) ->
    ListNum = length(NoticeList),
    F = fun([Nickname,GoodsTypeId,Realm]) ->
            NameBin = pt:write_string(Nickname),
            <<NameBin/binary, GoodsTypeId:32, Realm:8>>
    end,
    ListBin = list_to_binary(lists:map(F, NoticeList)),
    {ok, pt:pack(15203, <<ListNum:16, ListBin/binary>>)};

%% 神秘商店公告播报
write(15204, [Nickname,GoodsTypeId,Realm]) ->
    NameBin = pt:write_string(Nickname),
    {ok, pt:pack(15204, <<NameBin/binary, GoodsTypeId:32, Realm:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.




