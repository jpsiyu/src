%%%--------------------------------------
%%% @Module : mod_kf_3v3_state
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3游戏节点辅助进程
%%%--------------------------------------

-module(mod_kf_3v3_state).
-behaviour(gen_server).
-export([
	start_link/0,		 
	set_status/1,
	get_status/0
%% 	get_top_list/0,
%% 	set_top_list/1
]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
	status = 0		%% 0还未开启,1开启报名中,4已结束
%% 	top_list = []		%% 前N名玩家排行数据
}).

%% 设置活动状态
set_status(Status)->
	gen_server:cast(misc:get_global_pid(?MODULE), {set_status, Status}).

%% 获取活动状态
get_status() ->
	gen_server:call(misc:get_global_pid(?MODULE), {get_status}).

%% 设置前N名玩家数据
%% set_top_list(TopList) ->
%% 	gen_server:cast(misc:get_global_pid(?MODULE), {set_top_list, TopList}).

%% 获取前N名玩家数据
%% get_top_list()->
%% 	gen_server:call(misc:get_global_pid(?MODULE), {get_top_list}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, #state{}}.

%% handle_call({get_top_list}, _From, State) ->
%%     {reply, State#state.top_list, State};

handle_call({get_status}, _From, State) ->
    {reply, State#state.status, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({set_status, Status}, State) ->
	OpenDay = util:get_open_day(),
	NeedDay = data_kf_3v3:get_config(min_open_server),
	NewState = 
	if
		%% 开服天数足够
		OpenDay >= NeedDay ->
			State#state{status = Status};
		true ->
			State#state{status = 0}
	end,
	{ok, BinData} = pt_484:write(48401, Status),
	lib_unite_send:send_to_all(data_kf_3v3:get_config(min_lv), 100, BinData),

	{noreply, NewState};

%% handle_cast({set_top_list, TopList}, State) ->
%%     {noreply, State#state{top_list = TopList}};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
