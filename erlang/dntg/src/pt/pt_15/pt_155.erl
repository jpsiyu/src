%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-9-25
%% Description: 临时背包
%% --------------------------------------------------------
-module(pt_155).
-compile(export_all).
-export([write/2, read/2]).
-include("goods.hrl").

%% 取临时背包物品列表
read(15500, _R) ->
    {ok, temp_list};

%% 取单个
read(15501, <<Id:32>>) ->
    {ok, Id};

%% 取全部
read(15502, _R) ->
    {ok, all};

read(15503, <<Type:8, GoodsId1:32, GoodsId2:32>>) ->
    {ok, [Type, GoodsId1, GoodsId2]};

%% 功勋续期
read(15504, <<GoodsId:32, Days:16>>) ->
    {ok, [GoodsId, Days]};

%% 功勋升级
read(15505, <<GoodsId:32>>) ->
    {ok, GoodsId};

%% 使用物品背包武器变性
read(15506, <<GoodsId:32, EquipId:32>>) ->
    {ok, [GoodsId, EquipId]};

%% 更换身上和脚上的光效 Pos:1 身上, 2 脚上  Stren:对应强化数的光效
read(15507, <<Pos:8, Stren:16>>) ->
    {ok, [Pos, Stren]};

%% 替换
%% 默认匹配
read(_Cmd, _Bin) ->
    {error, nomatch}.


write(15500, [Res, List]) ->
    Len = length(List),
    F = fun(Temp) ->
            Id = Temp#temp_bag.id,
            GoodsTypeId = Temp#temp_bag.goods_id,
            Num = Temp#temp_bag.num,
            Bind = Temp#temp_bag.bind,
            Prefix = Temp#temp_bag.prefix,
            Stren = Temp#temp_bag.stren,
            <<Id:32, GoodsTypeId:32, Num:16, Bind:8, Prefix:8, Stren:8>>
    end,
    ListBin = list_to_binary(lists:map(F, List)), 
    {ok, pt:pack(15500, <<Res:16, Len:16, ListBin/binary>>)};

write(15501, [Res]) ->
    {ok, pt:pack(15501, <<Res:16>>)};

write(15502, [Res]) ->
    {ok, pt:pack(15502, <<Res:16>>)};

write(15503, [Res]) ->
    {ok, pt:pack(15503, <<Res:16>>)};

write(15504, [Res, Time]) ->
    {ok, pt:pack(15504, <<Res:16, Time:32>>)};

write(15505, [Res, GoodsTypeId]) ->
    {ok, pt:pack(15505, <<Res:16, GoodsTypeId:32>>)};

write(15506, [Res, GoodsTypeId]) ->
    {ok, pt:pack(15506, <<Res:16, GoodsTypeId:32>>)};

write(15507, Res) ->
    {ok, pt:pack(15507, <<Res:16>>)};
write(_Cmd, _Bin) ->
    {ok, pt:pack(0, <<>>)}.

