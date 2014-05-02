%%%--------------------------------------
%%% @Module  : timer_rank_cls
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.11.15
%%% @Description: 跨服排行榜定时器，目前只负责发周奖励及删除数据
%%%--------------------------------------

-module(timer_rank_cls).
-behaviour(gen_fsm).
-export([
	start_link/0,
	waiting/2,
	working/2,
	re_working/0
]).
-export([
	init/1,
	handle_event/3,
	handle_sync_event/4,
	handle_info/3, 
	terminate/3,
	code_change/4
]).

start_link() ->
    gen_fsm:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
	{ok, working, [], 60 * 1000}.

%% 休眠时间
waiting(_Event, State) ->
	{next_state, working, State, 0}.

%% 处理业务
working(_Event, State) ->
	case lib_rank_cls:working() of
		{waiting, WaitingTime} ->
			{next_state, waiting, State, WaitingTime * 1000};
		_ ->
			{next_state, waiting, State, 120 * 1000}
	end.

%% 重新触发定时器工作
re_working() ->
	gen_fsm:send_all_state_event(?MODULE, {re_working}).

%% --------------------------------------------------------------------
%% 异步事件
%% --------------------------------------------------------------------
handle_event({re_working}, _StateName, State) ->
    {next_state, working, State, 2000};

handle_event(_Event, StateName, State) ->
    {next_state, StateName, State}.

%% --------------------------------------------------------------------
%% 同步事件
%% --------------------------------------------------------------------
handle_sync_event(_Event, _From, StateName, State) ->
    {reply, ok, StateName, State}.

handle_info(_Info, StateName, State) ->
    {next_state, StateName, State}.

terminate(_Reason, _StateName, _State) ->
    ok.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.
