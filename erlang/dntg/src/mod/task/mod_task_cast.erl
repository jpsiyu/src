%%%------------------------------------
%%% @Module  : mod_mail_cast
%%% @Author  : zhenghehe
%%% @Created : 2012.02.01
%%% @Description: 任务cast处理
%%%------------------------------------
-module(mod_task_cast).
-export([handle_cast/2]).
%%停止任务进程
handle_cast(stop, State) ->
    {stop, normal, State};

%% 执行函数
handle_cast({Module, Arg}, State) ->
    apply(mod_task, Module, Arg),
    {noreply, State};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_task:handle_cast not match: ~p", [Event]),
    {noreply, Status}.