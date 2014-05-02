%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-1-29
%% Description: 170宝箱信息
%% --------------------------------------------------------
-module(pt_170).
-export([read/2, write/2]).
-include("record.hrl").
-include("box.hrl").

%%
%% 客户端 -> 服务端 ----------------------------
%%

%% 开宝箱
read(17000, <<BoxId:32, BoxNum:16>>) ->
    {ok, [BoxId, BoxNum]};

%% 宝箱包裹列表
read(17001, _R) ->
    {ok, list};

%% 获取宝箱包裹里的物品信息
read(17002, <<GoodsTypeId:32>>) ->
    {ok, GoodsTypeId};

%% 取宝箱物品
read(17003, <<GoodsTypeId:32>>) ->
    {ok, GoodsTypeId};

%% 取宝箱全部物品
read(17004, _R) ->
    {ok, get_all};

%% 取宝箱初始信息
read(17005, _R) ->
    {ok, init};

%% 取宝箱播报列表
read(17007, _R) ->
    {ok, notice};

%% 淘宝兑换
%%石头物品id, 如果是背包兑换则是物品id
%%兑换的装备id
%%兑换数量
%% 位置 0:淘宝   1:背包
read(17010, <<StoneId:32, EquipId:32, Pos:8>>) ->
    {ok, [StoneId, EquipId, Pos]};

%% 取宝箱兑换表
read(17011, _R) ->
    {ok, exchange};

%% 取宝箱礼包
read(17012, <<GiftId:32>>) ->
    {ok, [GiftId]};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ----------------------------
%%

%% 开宝箱
write(17000, [Res, BoxId, Gold, GoodsId, GoodsList]) ->
    ListNum = length(GoodsList),
    F = fun({GoodsTypeId, GoodsNum, Bind}) ->
            <<GoodsTypeId:32, GoodsNum:16, Bind:8>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(17000, <<Res:16, BoxId:32, Gold:32, GoodsId:32, ListNum:16, ListBin/binary>>)};

%% 宝箱包裹列表
write(17001, GoodsList) ->
    ListNum = length(GoodsList),
    F = fun({GoodsTypeId, GoodsNum, Bind}) ->
            <<GoodsTypeId:32, GoodsNum:16, Bind:8>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(17001, <<ListNum:16, ListBin/binary>>)};

%% 获取宝箱包裹里的物品信息
write(17002, [Res, GoodsTypeId, Prefix, Stren, AttributeList, Bind]) ->
    ListNum = length(AttributeList),
    F = fun({AttributeType, AttributeId, AttributeVal, Star}) ->
            Value = round(AttributeVal),
            <<AttributeType:16, AttributeId:16, Value:32, Star:16>>
        end,
    ListBin = list_to_binary(lists:map(F, AttributeList)),
    {ok, pt:pack(17002, <<Res:16, GoodsTypeId:32, Prefix:16, Stren:16, ListNum:16, ListBin/binary, Bind:16>>)};

%% 取宝箱物品
write(17003, [Res, GoodsTypeId]) ->
    {ok, pt:pack(17003, <<Res:16, GoodsTypeId:32>>)};

%% 取宝箱全部物品
write(17004, Res) ->
    {ok, pt:pack(17004, <<Res:16>>)};

%% 取宝箱初始信息
write(17005, BoxList) ->
    ListNum = length(BoxList),
    F = fun(Id) ->
            BoxInfo = data_box:get_box(Id),
            Price = BoxInfo#ets_box.price, 
            Price2 = BoxInfo#ets_box.price2,
            Price3 = BoxInfo#ets_box.price3,
            Name = BoxInfo#ets_box.name,
            Len = byte_size(Name),
            <<Id:32, Price:16, Price2:16, Price3:16, Len:16, Name/binary>>
        end,
    ListBin = list_to_binary(lists:map(F, BoxList)),
    {ok, pt:pack(17005, <<ListNum:16, ListBin/binary>>)};

%% 全服通告
write(17006, [PlayerId, BoxId, Realm, PlayerName, GoodsList]) ->
    Nick = list_to_binary(PlayerName),
    Len = byte_size(Nick),
    ListNum = length(GoodsList),
    F = fun({GoodsTypeId, GoodsNum, _}) ->
            <<GoodsTypeId:32, GoodsNum:16>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(17006, <<PlayerId:32, BoxId:32, Len:16, Nick/binary, ListNum:16, ListBin/binary, Realm:8>>)};

%% 取通告表
write(17007, NoticeList) ->
    ListNum = length(NoticeList),
    F = fun({PlayerId, PlayerName, Realm, BoxId, GoodsTypeId, GoodsNum}) ->
            Nick = list_to_binary(PlayerName),
            Len = byte_size(Nick),
            %io:format("list: ~p~n",[[GoodsTypeId, GoodsNum]]),
            <<PlayerId:32, Realm:8, BoxId:32, GoodsTypeId:32, GoodsNum:16, Len:16, Nick/binary>>
        end,
    ListBin = list_to_binary(lists:map(F, NoticeList)),
    {ok, pt:pack(17007, <<ListNum:16, ListBin/binary>>)};

%% 兑换
write(17010, [Res, EquipId, Bind, GiftId]) ->
    {ok, pt:pack(17010, <<Res:16, EquipId:32, Bind:8, GiftId:32>>)};

write(17011, [Num, GiftId, TypeList]) ->
    ListNum = length(TypeList),
    F = fun(GoodsTypeId) ->
            <<GoodsTypeId:32>>
    end,
    ListBin = list_to_binary(lists:map(F, TypeList)),
    {ok, pt:pack(17011, <<Num:8, GiftId:32, ListNum:16, ListBin/binary>>)};

write(17012, [Res, GiftId]) ->
    {ok, pt:pack(17012, <<Res:16, GiftId:32>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.






