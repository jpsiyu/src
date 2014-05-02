%%%--------------------------------------
%%% @Module  : timer_unite_butterfly
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.6
%%% @Description: 蝴蝶谷
%%%--------------------------------------

-module(timer_unite_butterfly).
-include("common.hrl").
-behaviour(gen_fsm).
-export([start_link/0, waiting/2, working/2, set_time/2]).
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).

%% 自定义状态
-record(state, {
	weekrange = [1, 2, 3, 4, 5, 6, 7],		%% 活动周期
	timerange = [{13, 0}, {14, 0}],			%% 活动时间
	create_boss = 0,								%% 是否生成过boss，在活动开始后由定时器生成首只boss，后面的生成放在boss被击杀时处理
	remove_boss = 0							%% 是否清除过boss，在活动开始前需要先清除boss
}).

start_link() ->
    gen_fsm:start_link({global, ?MODULE}, ?MODULE, [], []).

%% 重置活动时间
set_time(WeekRange, TimeRange) ->
	gen_fsm:send_all_state_event({global, ?MODULE}, {set_time, WeekRange, TimeRange}).

init([]) ->
	%% 初始化活动的举行周期及时间
	WeekRange = data_butterfly:require_activity_week(),
	TimeRange = data_butterfly:require_activity_time(),
	State = #state{weekrange = WeekRange, timerange = TimeRange},
	NextTime = private_next_time(WeekRange, TimeRange),
%% 	io:format("butterfly timer init, NextTime =~p~n", [NextTime]),

	 %% 开启蝴蝶谷服务进程
	mod_butterfly:start_link([WeekRange, TimeRange]),

	{ok, working, State, NextTime * 1000}.

%% 休眠时间
waiting(timeout, State) ->
	NextTime = private_next_time(State#state.weekrange, State#state.timerange),
%% 	io:format("Butterfly waiting, NextTime = ~p~n", [NextTime]),
	{next_state, working, State, NextTime * 1000}.

%% 发广播逻辑
working(_Event, State) ->
	[CreateBoss, RemoveBoss] = lib_butterfly:broadcast(State#state.weekrange, State#state.timerange, State#state.create_boss, State#state.remove_boss),
	{next_state, waiting, State#state{create_boss = CreateBoss, remove_boss = RemoveBoss}, 0}.

%% --------------------------------------------------------------------
%% 异步事件
%% --------------------------------------------------------------------
handle_event({set_time, WeekRange, TimeRange}, _StateName, _State) ->
	%% 关闭蝴蝶谷服务进程
%% 	mod_butterfly:stop(),
%% 	timer:sleep(1000),
	%% 开启蝴蝶谷服务进程
%% 	mod_butterfly:start_link([WeekRange, TimeRange]),
	mod_butterfly:set_time([WeekRange, TimeRange]),
%% 	io:format("set time, time = ~p~n", [util:unixtime()]),
	NewState = #state{weekrange = WeekRange, timerange = TimeRange},
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
private_next_time(WeekRange, TimeRange) ->
	lib_butterfly:timer_get_next_time(WeekRange, TimeRange).
