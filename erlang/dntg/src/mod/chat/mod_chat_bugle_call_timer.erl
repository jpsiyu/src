%%% -------------------------------------------------------------------
%%% Author  :zengzhaoyuan
%%% Description :
%%%
%%% Created : 2012-6-12
%%% -------------------------------------------------------------------
-module(mod_chat_bugle_call_timer).

-behaviour(gen_fsm).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([start_link/0]).

%% gen_fsm callbacks
-export([init/1, execute/2, state_name/3, set_time/1, handle_event/3,
	 handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).

-define(TIMEOUT_DEFAULT, 5*1000). %5秒一刷
-record(state, {}).
%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
    gen_fsm:start_link({global,?MODULE}, ?MODULE, [], []).


%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok, StateName, StateData}          |
%%          {ok, StateName, StateData, Timeout} |
%%          ignore                              |
%%          {stop, StopReason}
%% --------------------------------------------------------------------
init([]) ->
    {ok, execute, #state{},?TIMEOUT_DEFAULT}.

%% --------------------------------------------------------------------
%% Func: StateName/2
%% Returns: {next_state, NextStateName, NextStateData}          |
%%          {next_state, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}
%% --------------------------------------------------------------------
execute(_Event, StateData) ->
	mod_chat_bugle_call:execute_send_one(),
	{next_state, execute, StateData,?TIMEOUT_DEFAULT}.

%% 重置时间
set_time(TimeOut) ->
	%% io:format("-------TimeOut-----~p~n",[TimeOut]),
	gen_fsm:send_all_state_event({global, ?MODULE}, {set_time, TimeOut}).

%% --------------------------------------------------------------------
%% Func: StateName/3
%% Returns: {next_state, NextStateName, NextStateData}            |
%%          {next_state, NextStateName, NextStateData, Timeout}   |
%%          {reply, Reply, NextStateName, NextStateData}          |
%%          {reply, Reply, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}                          |
%%          {stop, Reason, Reply, NewStateData}
%% --------------------------------------------------------------------
state_name(_Event, _From, StateData) ->
    Reply = ok,
    {reply, Reply, state_name, StateData}.

%% --------------------------------------------------------------------
%% Func: handle_event/3
%% Returns: {next_state, NextStateName, NextStateData}          |
%%          {next_state, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}
%% --------------------------------------------------------------------
handle_event({set_time, TimeOut}, _StateName, StateData) ->
	{next_state, execute, StateData, TimeOut};

handle_event(_Event, StateName, StateData) ->
    {next_state, StateName, StateData}.

%% --------------------------------------------------------------------
%% Func: handle_sync_event/4
%% Returns: {next_state, NextStateName, NextStateData}            |
%%          {next_state, NextStateName, NextStateData, Timeout}   |
%%          {reply, Reply, NextStateName, NextStateData}          |
%%          {reply, Reply, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}                          |
%%          {stop, Reason, Reply, NewStateData}
%% --------------------------------------------------------------------
handle_sync_event(_Event, _From, StateName, StateData) ->
    Reply = ok,
    {reply, Reply, StateName, StateData}.

%% --------------------------------------------------------------------
%% Func: handle_info/3
%% Returns: {next_state, NextStateName, NextStateData}          |
%%          {next_state, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}
%% --------------------------------------------------------------------
handle_info(_Info, StateName, StateData) ->
    {next_state, StateName, StateData}.

%% --------------------------------------------------------------------
%% Func: terminate/3
%% Purpose: Shutdown the fsm
%% Returns: any
%% --------------------------------------------------------------------
terminate(_Reason, _StateName, _StatData) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/4
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState, NewStateData}
%% --------------------------------------------------------------------
code_change(_OldVsn, StateName, StateData, _Extra) ->
    {ok, StateName, StateData}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

