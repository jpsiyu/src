%%%-----------------------------------
%%% @Module  : pt_304
%%% @Author  : zhenghehe
%%% @Created : 2010.06.17
%%% @Description: 30 任务信息
%%%-----------------------------------
-module(pt_304).
-include("record.hrl").
-include("task.hrl").
-export([read/2, write/2]).

%% 可接皇榜任务列表
read(30400, _) ->
    {ok, done};

%% %% 已接皇榜任务列表
%% read(30401, _) ->
%%     {ok ,done};

%% 元宝涮新可接任务列表
read(30402, <<IsAuto:8>>) ->
	{ok, [IsAuto]};

%% 接取任务
read(30403, <<TaskId:32>>) ->
    {ok, [TaskId]};
    
%% 已接皇榜任务列表
read(30404, _) ->
    {ok, []};
    
read(_Cmd, _R) ->
    {error, no_match}.

%% 可接皇榜任务列表
write(30400, [ActiveTaskEbs, NextRefTime, LeftTriggerDaily]) when is_list(ActiveTaskEbs) ->
    Len = length(ActiveTaskEbs),
    Bin = list_to_binary(ActiveTaskEbs),
    Data = <<Len:16, Bin/binary, NextRefTime:32, LeftTriggerDaily:16>>,
    {ok, pt:pack(30400, Data)};

%% %% 已接皇榜任务列表
%% write(30401, TriggerTaskEbs) when is_list(TriggerTaskEbs)->
%%     Bin = lists:map(fun({TaskId, Color}) -> <<TaskId:32, Color:8>> end, TriggerTaskEbs),
%%     Data = list_to_binary(Bin),
%%     {ok, pt:pack(30401, Data)};

%% 元宝涮新可接任务列表
write(30402, Result) ->
    {ok, pt:pack(30402, <<Result:16>>)};

%% 接取任务
write(30403, Result) ->
    {ok, pt:pack(30403, <<Result:16>>)};

%% 已接皇榜任务列表
write(30404, TriggerTaskEbs) ->
    Len = length(TriggerTaskEbs),
    Bin = list_to_binary(TriggerTaskEbs),
    Data = <<Len:16, Bin/binary>>,
    {ok, pt:pack(30404, Data)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
