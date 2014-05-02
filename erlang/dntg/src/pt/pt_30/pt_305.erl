%%%-----------------------------------
%%% @Module  : pt_305
%%% @Author  : zhenghehe
%%% @Created : 2010.06.17
%%% @Description: 30 任务信息
%%%-----------------------------------
-module(pt_305).
-include("record.hrl").
-include("task.hrl").
-export([read/2, write/2]).

%% 可接平乱任务
read(30500, _) ->
    {ok, done};

%% 涮新平乱任务
read(30501, _) ->
    {ok, done};

%% 刷新平乱任务到指定为止
read(30502, <<Color:8>>) ->
	{ok, [Color]};

%% 接受任务
read(30503, <<TaskId:32>>) ->
    {ok, [TaskId]};

%% 新手引导：第一次刷成橙色任务
read(30504, _) ->
    {ok, done};

read(_Cmd, _R) ->
    {error, no_match}.

%% 平乱任务信息
write(30500, [TaskId, Color, TriggerDaily, TaskBin]) ->
    {ok, pt:pack(30500, <<TaskId:32, Color:8, TriggerDaily:16, TaskBin/binary>>)};

%% 涮新平乱任务
write(30501, Result) ->
    {ok, pt:pack(30501, <<Result:16>>)};

%% 刷新平乱任务到橙色为止
write(30502, [Result, Count]) ->
    {ok, pt:pack(30502, <<Result:16,Count:16>>)};

%% 接受任务
write(30503, [Result, TriggerDaily]) ->
    {ok, pt:pack(30503, <<Result:16, TriggerDaily:16>>)};

%% 完成平乱任务第10环和第20环的通知
write(30505, [TriggerDaily,GoodsID]) ->
    {ok, pt:pack(30505, <<TriggerDaily:16, GoodsID:32>>)};
  
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
