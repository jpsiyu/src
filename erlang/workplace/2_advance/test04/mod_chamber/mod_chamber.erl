-module(mod_chamber).
-behaviour(gen_server).
-include("chamber.hrl").

-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
		 code_change/3, terminate/2]).


%%% client API
start_link([]) ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%% gen_server API
init([]) ->
	ets:new(?ETS_CHAMBER, [set, public, named_table, {keypos, #chamber.wedding_id}]),
	{ok, []}.

handle_cast(Event, Status) ->
	mod_chamber_cast:handle_cast(Event, Status).

handle_call(Event, From, Status) ->
	mod_chamber_call:handle_call(Event, From, Status).

handle_info(_Info, S) ->
	{noreply, S}.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

terminate(_Reason, _State) ->
	ok.
