%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2012-11-13
%%% -------------------------------------------------------------------
-module(mod_kf_1v1_state).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([
	start_link/0,		 
	set_status/1,
	get_status/0,
	set_look_list/1,
	get_look_list/0,
	send_48301/1,
	get_top_list/0,
	set_top_list/1
]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
	bd_1v1_stauts=0,  		 	%% 0还未开启  1开启报名中 2开启准备中 3开启比赛中 4已结束
	top_list = [],               %% 是否已广播全服。   0没有、1广播了
	look_list = []			    %% 观战列表			
}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%% ====================================================================
%% Server functions
%% ====================================================================
%%设置状态
%%@param Bd_1v1_Status 1v1状态 0还未开启  1开启报名中 2开启准备中 3开启比赛中 4已结束
set_status(Bd_1v1_Status)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_status,Bd_1v1_Status}).

set_top_list(TopList)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_top_list,TopList}).

get_top_list()->
	gen_server:call(misc:get_global_pid(?MODULE),{get_top_list}).

set_look_list(LookList)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_look_list,LookList}).

get_look_list()->
	gen_server:call(misc:get_global_pid(?MODULE),{get_look_list}).

%%推送48301
send_48301(Bd_1v1_Status)->
	gen_server:cast(misc:get_global_pid(?MODULE),{send_48301,Bd_1v1_Status}).

%%获取状态
%% @return int 本服1v1状态 0还未开启  1开启中 2当天已结束
get_status()->
	gen_server:call(misc:get_global_pid(?MODULE),{get_status}).
%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({get_look_list}, _From, State) ->
    Reply = State#state.look_list,
    {reply, Reply, State};
  
handle_call({get_top_list}, _From, State) ->
    Reply = State#state.top_list,
    {reply, Reply, State};

handle_call({get_status}, _From, State) ->
    Reply = State#state.bd_1v1_stauts,
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({set_status,Bd_1v1_Status}, State) ->
	Min_open_server = data_kf_1v1:get_bd_1v1_config(min_open_server),
	Open_server = util:get_open_day(),
	if
		Min_open_server=<Open_server-> %%开服天数足够
			NewState = State#state{bd_1v1_stauts=Bd_1v1_Status},
			{ok, BinData} = pt_483:write(48301, [Bd_1v1_Status]),
			Apply_level = data_kf_1v1:get_bd_1v1_config(min_lv),
			lib_unite_send:send_to_all(Apply_level, 999,BinData);
		true->
			NewState = State#state{bd_1v1_stauts=0}
	end,
    {noreply, NewState};

handle_cast({set_top_list,TopList}, State) ->
	NewState = State#state{top_list=TopList},
    {noreply, NewState};

handle_cast({set_look_list,LookList}, State) ->
	NewState = State#state{look_list=LookList},
	{ok, BinData} = pt_483:write(48312, [LookList]),
	Apply_level = data_kf_1v1:get_bd_1v1_config(min_lv),
	lib_unite_send:send_to_all(Apply_level, 999,BinData),
    {noreply, NewState};  

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

