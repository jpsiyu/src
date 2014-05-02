%%%--------------------------------------
%%% @Module  : timer_unite_hotspring
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.6
%%% @Description: 黄金沙滩
%%%--------------------------------------

-module(timer_unite_hotspring).
-include("common.hrl").
-behaviour(gen_fsm).
-export([start_link/0, waiting/2, working/2, set_time/1]).
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).

%% 自定义状态
-record(state, {
	timerange = []			%% 默认活动时间
}).

start_link() ->
    gen_fsm:start_link({global, ?MODULE}, ?MODULE, [], []).

%% 重置活动时间
set_time(TimeRange) ->
	gen_fsm:send_all_state_event({global, ?MODULE}, {set_time, TimeRange}).

init([]) ->
	%% 初始化活动的举行周期及时间
	TimeRange = data_hotspring:get_activity_time(),

	%% 开启沙滩服务进程
	mod_hotspring:start_link(TimeRange),

	NextTime = private_next_time(TimeRange),
	{ok, working, #state{timerange = TimeRange}, NextTime * 1000}.

%% 休眠时间
waiting(timeout, State) ->
	NextTime = private_next_time(State#state.timerange),
	{next_state, working, State, NextTime * 1000}.

%% 发广播逻辑
working(_Event, State) ->
	lib_hotspring:broadcast(State#state.timerange),
	{next_state, waiting, State, 0}.

%% --------------------------------------------------------------------
%% 异步事件
%% --------------------------------------------------------------------
handle_event({set_time, TimeRange}, _StateName, _State) ->
	mod_hotspring:set_time(TimeRange),
	NewState = #state{timerange = TimeRange},
    {next_state, working, NewState, 2000};

handle_event(_Event, StateName, State) ->
    {next_state, StateName, State}.

%% --------------------------------------------------------------------
%% 同步事件
%% --------------------------------------------------------------------
handle_sync_event(_Event, _From, StateName, State) ->
    Reply = ok,
    {reply, Reply, StateName, State}.

handle_info(_Info, StateName, State) ->
    {next_state, StateName, State}.

terminate(_Reason, _StateName, _State) ->
    ok.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.

%% 获得下次需要处理倒计时秒数，供定时器状态机使用
private_next_time(TimeRange) ->
	lib_hotspring:timer_get_next_time(TimeRange).
