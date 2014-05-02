%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-2
%% Description: TODO:
%% --------------------------------------------------------
-module(timer_shop).
-export([init/0, handle/1, terminate/2]).
-include("common.hrl").
-include("shop.hrl").

%% -----------------------------------------------------------------
%% @desc     启动回调函数，用来初始化资源。
%% @param
%% @return  {ok, State}     : 启动正常
%%           {ignore, Reason}: 启动异常，本模块将被忽略不执行
%%           {stop, Reason}  : 启动异常，需要停止所有后台定时模块
%% -----------------------------------------------------------------
init() ->
    State = lib_shop:init_limit_shop({0,0,0}),
    {ok, State}.

%% -----------------------------------------------------------------
%% @desc     服务回调函数，用来执行业务操作。
%% @param    State          : 初始化或者上一次服务返回的状态
%% @return  {ok, NewState}  : 服务正常，返回新状态
%%           {ignore, Reason}: 服务异常，本模块以后将被忽略不执行，模块的terminate函数将被回调
%%           {stop, Reason}  : 服务异常，需要停止所有后台定时模块，所有模块的terminate函数将被回调
%% -----------------------------------------------------------------
handle(State) ->
    OpenDay = util:get_open_day(),
    MergeTime = lib_activity_merge:get_activity_time(),
    Now = util:unixtime(),
    MergeDay = util:get_diff_days(Now, MergeTime),
    if
        OpenDay =< ?OPEN_DAYS ->
            NewState = State;
	MergeTime =/= 0 andalso MergeDay =< ?MERGE_DAYS ->
	    NewState = State;
        true ->
            %% 不是开服前三天更新限时热卖
	    NewState = lib_shop:init_limit_shop({0,0,0})
    end,
    %case lib_shop:is_need_refresh(State) of
    %    true ->
    %        NewState = lib_shop:init_limit_shop({0,0,0});
    %  false ->
    %        NewState = lib_shop:init_limit_shop(State)
    %end,
    {ok, NewState}.

%% -----------------------------------------------------------------
%% @desc     停止回调函数，用来销毁资源。
%% @param    Reason        : 停止原因
%% @param    State         : 初始化或者上一次服务返回的状态
%% @return   ok
%% -----------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.




