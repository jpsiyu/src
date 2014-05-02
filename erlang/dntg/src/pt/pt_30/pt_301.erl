%%%-----------------------------------
%%% @Module  : pt_301
%%% @Author  : zhenghehe
%%% @Created : 2010.06.17
%%% @Description: 30 任务信息
%%%-----------------------------------
-module(pt_301).
-include("record.hrl").
-include("task.hrl").
-export([read/2, write/2]).

read(30100, _Data) ->
    {ok, []};

read(30105, <<Len:16>>) when Len =< 0 ->
    {ok, []};

read(30105, <<Len:16, Bin/binary>>) ->
    L = unpack_task_proxy(Bin, Len, []),
    {ok, [L]};

%% 获取任务的所有次数的奖励
read(30110, <<TaskId:32>>) ->
    {ok, [TaskId]};

read(30115, <<Len:16>>) when Len =< 0 ->
    {ok, []};
read(30115, <<Len:16, Bin/binary>>) ->
    L = unpack_task_proxy_finish(Bin, Len, []),
    {ok, [L]};

read(_Cmd, _R) ->
    {error, no_match}.

%% 获取任务物品列表
write(30100, [TaskList, ActionList]) ->
    TLen = length(TaskList),
    TBin = pack_task_proxy(task, TaskList, <<>>),
    ALen = length(ActionList),
    ABin = pack_task_proxy(action, ActionList, <<>>),
    {ok, pt:pack(30100, <<TLen:16, TBin/binary, ALen:16, ABin/binary>>)};

%% 开始委托任务
write(30105, [Code, Msg]) ->
    {ok, notice1(30105, [Code, Msg])};

%% 获取任务的不同次数的奖励
write(30110, [TaskId, List]) ->
    Len = length(List),
    Bin = list_to_binary([
        <<Exp:32, Spt:32>>
        || {Exp, Spt} <- List
    ]),
    {ok, pt:pack(30110, <<TaskId:32, Len:16, Bin/binary>>)};

%% 立即完成
write(30115, [Code, Msg]) ->
    {ok, notice1(30115, [Code, Msg])};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

%% 任务委托 ==============================================
pack_task_proxy(task, [], Bin) -> Bin;

pack_task_proxy(task, [[TaskId, Lev, Type, Name, Sec, Gold, Limit, Exp, Llpt, Xwpt, Cumulate]|T], Bin) ->
    LN = byte_size(Name),
    pack_task_proxy(task, T, <<Bin/binary, TaskId:32, Lev:16, Type:16, LN:16, Name/binary, Sec:32, Gold:32, Limit:16, Exp:32, Llpt:32, Xwpt:32, Cumulate:16>>);

pack_task_proxy(action, [], Bin) -> Bin;

pack_task_proxy(action, [[TaskId, Name, Number, Sec, Gold, Exp, Llpt, Xwpt]|T], Bin) ->
    LN = byte_size(Name),
    pack_task_proxy(action, T, <<Bin/binary, TaskId:32, LN:16, Name/binary, Number:16, Sec:32, Gold:32, Exp:32, Llpt:32, Xwpt:32>>).

unpack_task_proxy(<<>>, _, R) -> R;

unpack_task_proxy(_, 0, R) -> R;

unpack_task_proxy(<<TaskId:32, Num:16, Bin/binary>>, N, R) ->
    case Num =< 0 of
        true->
            Num1 = 1;
        false ->
            Num1 = Num
    end,
    unpack_task_proxy(Bin, N - 1, [[TaskId, Num1] | R]).

unpack_task_proxy_finish(<<>>, _, R) -> R;

unpack_task_proxy_finish(_, 0, R) -> R;

unpack_task_proxy_finish(<<TaskId:32, Bin/binary>>, N, R) ->
    unpack_task_proxy_finish(Bin, N - 1, [TaskId | R]).

notice1(Cmd, [Code, Msg]) ->
    ML = byte_size(Msg),
    Data = <<Code:8, ML:16, Msg/binary>>,
    pt:pack(Cmd, Data).