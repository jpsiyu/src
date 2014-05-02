%%%------------------------------------
%%% @Module  : timer_pet
%%% @Author  : zhenghehe
%%% @Created : 2011.05.13
%%% @Description: 宠物后台定时服务
%%%------------------------------------
-module(timer_pet).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").

%%=========================================================================
%% 一些定义
%% TODO: 定义模块状态。
%%=========================================================================

%% 自定义状态
-record(state, {last_handle_expired_log_time = 0}).

%% 处理间隔
-define(TIME_INTERVAL_HANDLE_LOG_REGISTER,     12*60).

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
    NowTime = util:unixtime(),
    State = #state{last_handle_expired_log_time    = NowTime},
    {ok, State}.

%% -----------------------------------------------------------------
%% @desc     服务回调函数，用来执行业务操作。
%% @param    State          : 初始化或者上一次服务返回的状态
%% @return  {ok, NewState}  : 服务正常，返回新状态
%%           {ignore, Reason}: 服务异常，本模块以后将被忽略不执行，模块的terminate函数将被回调
%%           {stop, Reason}  : 服务异常，需要停止所有后台定时模块，所有模块的terminate函数将被回调
%% -----------------------------------------------------------------
handle(State) ->
    % 分线一才会进行
    case mod_disperse:node_id() of
        10 ->
            NewState1 = handle_expired_log(State),
            {ok, NewState1};
        _ ->
            {ok, State}
    end.

%% -----------------------------------------------------------------
%% @desc     停止回调函数，用来销毁资源。
%% @param    Reason        : 停止原因
%% @param    State         : 初始化或者上一次服务返回的状态
%% @return   ok
%% -----------------------------------------------------------------
terminate(Reason, State) ->
    ?DEBUG("================Terming..., Reason=[~w], Statee = [~w]", [Reason, State]),
    ok.

%%=========================================================================
%% 业务处理
%% TODO: 实现业务处理。
%%=========================================================================

%% -----------------------------------------------------------------
%% 处理过期解散申请
%% -----------------------------------------------------------------
handle_expired_log(State) ->
    LastHandleTime = State#state.last_handle_expired_log_time,
    NowTime        = util:unixtime(),
    DiffTime       = NowTime - LastHandleTime,
    {{_Year, _Month, _Day}, {Hour, _Min, _Sec}} = calendar:local_time(),
    if  ((DiffTime >= ?TIME_INTERVAL_HANDLE_LOG_REGISTER) and (Hour >= 4) and (Hour =< 6)) ->
            ?DEBUG("handle_expired_log: State=[~w]", [State]),
            mod_pet:send_delete_log(),
            State#state{last_handle_expired_log_time = NowTime};
        true ->
            State
    end.