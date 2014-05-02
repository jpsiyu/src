%%%------------------------------------
%%% @Module  : timer_quiz
%%% @Author  : 答题启动
%%% @Email   : huangcha
%%% @Created : 2011.11.26
%%% @Description: 答题定时服务
%%%------------------------------------
-module(timer_quiz).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include("quiz.hrl").
%%=========================================================================
%% 一些定义
%% TODO: 定义模块状态。
%%=========================================================================

%%=========================================================================
%% 回调接口
%% TODO: 实现回调接口。
%%=========================================================================

%% -----------------------------------------------------------------
%% @desc     启动回调函数，用来初始化资源。
%% @param
%% @return  {ok, State}     : 启动正常
%%           {ignore, Reason}: 启动异常，本模块将被忽略不执行
%%           {stop, Reason}  : 启动异常，需要停止所有后台定时模块
%% -----------------------------------------------------------------
init() ->
    {ok, ?MODULE}.

%% -----------------------------------------------------------------
%% @desc     服务回调函数，用来执行业务操作。
%% @param    State          : 初始化或者上一次服务返回的状态
%% @return  {ok, NewState}  : 服务正常，返回新状态
%%           {ignore, Reason}: 服务异常，本模块以后将被忽略不执行，模块的terminate函数将被回调
%%           {stop, Reason}  : 服务异常，需要停止所有后台定时模块，所有模块的terminate函数将被回调
%% -----------------------------------------------------------------
handle(State) ->
    %杀死旧的进程
    List = ets:tab2list(quiz_process),
    F = fun(Record) ->
        Pid = Record#quiz_process.pid,
        exit(Pid, kill)
    end,
    catch lists:foreach(F, List),
    ets:delete_all_objects(quiz_process),
    %生成新的进程
    mod_quiz_timer:start_link(),
    {ok, State}.

%% -----------------------------------------------------------------
%% @desc     停止回调函数，用来销毁资源。
%% @param    Reason        : 停止原因
%% @param    State         : 初始化或者上一次服务返回的状态
%% @return   ok
%% -----------------------------------------------------------------
terminate(Reason, State) ->
    ?DEBUG("================Terming..., Reason=[~w], Statee = [~w]", [Reason, State]),
    ok.