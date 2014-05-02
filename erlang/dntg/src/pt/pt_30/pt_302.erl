%%%-----------------------------------
%%% @Module  : pt_302
%%% @Author  : zhenghehe
%%% @Created : 2010.06.17
%%% @Description: 30 任务信息
%%%-----------------------------------
-module(pt_302).
-include("record.hrl").
-include("task.hrl").
-export([read/2, write/2]).
%% 取任务完成数
read(30201, _R) ->
    {ok, task_num};

%% 获取任务累积列表
read(30202, _R) ->
    {ok, task_cumulate};

%% 领取任务累积经验
read(30203, <<Task_id:32, Type:8>>) ->
    {ok, [Task_id, Type]};

read(_Cmd, _R) ->
    {error, no_match}.

%% 完成任务某环节
write(30200, [TaskId, TipList]) ->
    TipBin = pt_300:pack_task_tip_list(TipList),
    {ok, pt:pack(30200, <<TaskId:32, TipBin/binary>>)};

%% 取任务完成数
write(30201, TaskList) ->
    ListNum = length(TaskList),
    F = fun({TaskId, SuccNum}) ->
            <<TaskId:32, SuccNum:16>>
        end,
    ListBin = list_to_binary(lists:map(F, TaskList)),
    {ok, pt:pack(30201, <<ListNum:16, ListBin/binary>>)};

%% 取经验累积任务列表
write(30202, [TaskList, Lv]) ->
    ListNum = length(TaskList),
    F = fun(T) ->
            Task_id = T#task_cumulate.task_id,
            TaskName = pt:write_string(T#task_cumulate.task_name),
            Day = T#task_cumulate.offline_day,
            Ratio = 100,
            Exp = T#task_cumulate.cucm_exp,
            Gold = round(Exp div 2000 div Lv),
            <<Task_id:32, Ratio:16, TaskName/binary, Day:8, Exp:32, Gold:16>>
        end,
    ListBin = list_to_binary(lists:map(F, TaskList)),
    {ok, pt:pack(30202, <<ListNum:16, ListBin/binary>>)};

%% 领取任务累积经验
write(30203, [Res, Task_id]) ->
    {ok, pt:pack(30203, <<Res:16, Task_id:32>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
