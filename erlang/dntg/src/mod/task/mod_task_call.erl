%%%------------------------------------
%%% @Module  : mod_mail_call
%%% @Author  : zhenghehe
%%% @Created : 2012.02.04
%%% @Description: 任务call处理
%%%------------------------------------
-module(mod_task_call).
-export([handle_call/3]).

%% 执行函数
handle_call({Module, Arg}, _FROM, State) ->
    {reply, apply(mod_task, Module, Arg), State};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_task:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.