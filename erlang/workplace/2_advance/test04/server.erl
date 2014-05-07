-module(server).
-behaviour(gen_server).

-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
		 code_change/3, terminate/2]).


%%% client API
start_link([]) ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).


%%% gen_server API
init([]) ->
	{ok, []}.

handle_cast({print, Msg}, S) ->
	io:format("server got msg: ~p~n", [Msg]),
	{noreply, S};
handle_cast(_Request, S) ->
	{noreply, S}.

handle_call(_E, _From, State) ->
	{noreply, State}.

handle_info(_Info, S) ->
	{noreply, S}.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

terminate(_Reason, _State) ->
	ok.
