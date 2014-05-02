%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-10
%% Description: TODO:
%% --------------------------------------------------------
-module(timer_buy).
-compile(export_all).
-include("common.hrl").

-define(CLEAN_UP_TIME_SPAN, 1800).


%% -----------------------------------------------------------------
%% @desc     启动回调函数，用来初始化资源。
%% @param
%% @return  {ok, State}      : 启动正常
%%           {ignore, Reason}: 启动异常，本模块将被忽略不执行
%%           {stop, Reason}  : 启动异常，需要停止所有后台定时模块
%% -----------------------------------------------------------------
init() ->
    State = util:unixtime(),
    {ok, State}.

%% -----------------------------------------------------------------
%% @desc     服务回调函数，用来执行业务操作。
%% @param    State          : 初始化或者上一次服务返回的状态
%% @return  {ok, NewState}  : 服务正常，返回新状态
%%           {ignore, Reason}: 服务异常，本模块以后将被忽略不执行，模块的terminate函数将被回调
%%           {stop, Reason}  : 服务异常，需要停止所有后台定时模块，所有模块的terminate函数将被回调
%% -----------------------------------------------------------------
handle(State) ->
    case mod_disperse:node_id() of
        ?UNITE ->
            {ok, NewState} = handle_clean_up(State),
            {ok, NewState};
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

%% -----------------------------------------------------------------
%% 每半小时清一下过期的挂单
%% -----------------------------------------------------------------
handle_clean_up(State) ->
    NewState = util:unixtime(),
    if  (NewState - State) >= ?CLEAN_UP_TIME_SPAN ->
            mod_buy:cast_buy_clean(),
            {ok, NewState};
        true ->
            {ok, State}
    end.






