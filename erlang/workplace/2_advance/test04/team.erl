-module(team).
-compile(export_all).
-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
		 code_change/3, terminate/2]).
-export([create/2]).

-record(team_state, {team_id, leader_id, member_id_list, date}).
-record(state, {team_number}).

%%% client API
start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

create(LeaderId, MemberIdList) ->
	gen_server:cast(?MODULE, {create, {LeaderId, MemberIdList}}).

get_team_info() ->
	Info = gen_server:call(?MODULE, get_team_info),
	io:format("~p~n", [Info]).

%%% gen_server API
init([]) ->
	{ok, #state{team_number = 0}}.

handle_cast({create, {LeaderId, MemberIdList}}, State) ->
	Team = #team_state{team_id = State#state.team_number + 1, 
		leader_id = LeaderId, 
		member_id_list = MemberIdList, 
		date = calendar:local_time()},
	put(Team#team_state.team_id, Team),
	{noreply, State};
handle_cast(_Request, S) ->
	{noreply, S}.

handle_call(get_team_info, _From, State) ->
	TeamInfo = get(),
	{reply, TeamInfo, State};
handle_call(_E, _From, State) ->
	{noreply, State}.

handle_info(_Info, S) ->
	{noreply, S}.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

terminate(_Reason, _State) ->
	ok.


