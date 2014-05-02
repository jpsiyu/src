%%%--------------------------------------
%%% @Module  : timer_unite_fish
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.9.17
%%% @Description: 全民垂钓
%%%--------------------------------------

-module(timer_unite_fish).
-include("common.hrl").
-behaviour(gen_fsm).
-export([
	start_link/0,
	waiting/2,
	working/2,
	closing/2,
	set_time/2
]).
-export([
	init/1,
	handle_event/3,
	handle_sync_event/4,
	handle_info/3, 
	terminate/3,
	code_change/4
]).

%% 自定义状态
-record(state, {
	weekrange = [],		%% 活动周期
	timerange = []		%% 活动时间
}).

start_link() ->
    gen_fsm:start_link({global, ?MODULE}, ?MODULE, [], []).

%% 重置活动时间
set_time(WeekRange, TimeRange) ->
	gen_fsm:send_all_state_event({global, ?MODULE}, {set_time, WeekRange, TimeRange}).

%% 活动尚未开启状态
closing(_Event, State) -> 
	%% 初始化钓鱼活动环境
	lib_fish:init_env(),
	{next_state, working, State, 2000}.

%% 发广播逻辑
working(_Event, State) ->
	lib_fish:broadcast(State#state.weekrange, State#state.timerange),
	{next_state, waiting, State, 0}.

%% 休眠时间
waiting(timeout, State) ->
	NextTime = private_next_time(State#state.weekrange, State#state.timerange),
	{next_state, working, State, NextTime * 1000}.

init([]) ->
	%% 初始化活动的举行周期及时间
	WeekRange = data_fish:require_activity_week(),
	TimeRange = data_fish:require_activity_time(),
	State = #state{weekrange = WeekRange, timerange = TimeRange},

	%% 开启钓鱼服务进程
	mod_fish:start_link([WeekRange, TimeRange]),

	%% 2秒后去closing状态
	{ok, closing, State, 2 * 1000}.

%% --------------------------------------------------------------------
%% 异步事件
%% --------------------------------------------------------------------
handle_event({set_time, WeekRange, TimeRange}, _StateName, _State) ->
	%% 开启垂钓服务进程
	mod_fish:set_time([WeekRange, TimeRange]),
	NewState = #state{weekrange = WeekRange, timerange = TimeRange},
    {next_state, closing, NewState, 2000};

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
private_next_time(WeekRange, TimeRange) ->
	lib_fish:timer_get_next_time(WeekRange, TimeRange).
