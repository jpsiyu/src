%%%-----------------------------------
%%% @Module  : pt_301
%%% @Author  : zhenghehe
%%% @Created : 2010.06.17
%%% @Description: 30 任务信息
%%%-----------------------------------
-module(pt_303).
-include("record.hrl").
-include("task.hrl").
-export([read/2, write/2]).
%% 显示景阳经验累积值
read(30301, _R) ->
    {ok, done};

%% 获取景阳经验累积值
read(30302, <<Ftype:8, Type:8>>) ->
    {ok, [Ftype, Type]};

%% 跟NPC打招呼，发大表情 
read(30303, <<FaceId:32>>) ->
    {ok, [FaceId]};

%% 完成击败NPC分身任务
read(30304, <<NpcId:32>>) ->
    {ok, [NpcId]};

%% 指定场景使用物品
read(30305, <<GoodsId:32, Num:16>>) ->
    {ok, [GoodsId, Num]};

read(_Cmd, _R) ->
    {error, no_match}.

%% 显示景阳经验累积值
write(30301, [[Exp,  GoldNum, Goodsid, GoodsNum], [Days, ExpFire, GoldNumFire, GoodsidFire, GoodsNumFire]]) ->
    {ok, pt:pack(30301, <<Exp:32,  GoldNum:32, Goodsid:32, GoodsNum:32,
                          Days:8, ExpFire:32, GoldNumFire:32, GoodsidFire:32, GoodsNumFire:32>>)};

%% 获取景阳经验累积值
write(30302, [Type, S]) ->
    {ok, pt:pack(30302, <<Type:8, S:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.