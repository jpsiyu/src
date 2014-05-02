%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-25
%% Description: 物品子类
%% --------------------------------------------------------
-module(pt_151).
-include("goods.hrl").
-export([read/2, write/2]).

%%
%% 客户端 -> 服务 端 ------------------------------------------
%%

%% 灵魂炼化
read(15100, <<GoodsId:32, StoneId:32>>) ->
    {ok, [GoodsId, StoneId]};

%% 使用替身娃娃完成任务
read(15102, <<TaskId:32>>) ->
    {ok, TaskId};

%% 送东西
read(15103, <<Type:8, SubType:8, PlayerId:32>>) ->
    {ok, [Type, SubType, PlayerId]};

%% 幸运转盘
read(15104, <<GoodsId:32>>) ->
    {ok, GoodsId};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%% 服务 端 -> 客户端 ------------------------------------------
%%

%% 灵魂炼化
write(15100, [Res, GoodsId, AttributeList, Bind, Trade]) ->
    F = fun({AttrId, AttrVal, Star}) ->
            Value = round(AttrVal),
            <<AttrId:16, Value:32, Star:8>>
        end,
    ListNum = length(AttributeList),
    ListBin = list_to_binary(lists:map(F, AttributeList)),
    {ok, pt:pack(15100, <<Res:16, GoodsId:32, Bind:8, Trade:8, ListNum:16, ListBin/binary>>)};

%% 使用替身娃娃完成任务
write(15102, [Res, TaskId]) ->
    {ok, pt:pack(15102, <<Res:16, TaskId:32>>)};

%% 使用替身娃娃完成任务
write(15103, [Res, Type, SubType, PlayerId]) ->
    {ok, pt:pack(15103, <<Res:16, Type:8, SubType:8, PlayerId:32>>)};

%% 幸运转盘
write(15104, [Res, Goods_id]) ->
    {ok, pt:pack(15104, <<Res:16, Goods_id:32>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.







