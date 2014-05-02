%%%-----------------------------------
%%% @Module  : pt_306
%%% @Author  : zhenghehe
%%% @Created : 2010.06.17
%%% @Description: 30 任务信息
%%%-----------------------------------
-module(pt_306).
-include("record.hrl").
-include("task.hrl").
-export([read/2, write/2]).
-compile(export_all).

%% 使用元宝快速完成任务
read(30600, <<TaskId:32>>) ->
    {ok, [TaskId]};

read(_Cmd, _R) ->
    {error, no_match}.

%% 使用元宝快速完成任务
write(30600, [Res]) ->
    {ok, pt:pack(30600, <<Res:16>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.