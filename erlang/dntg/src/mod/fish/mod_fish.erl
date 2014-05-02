%%%--------------------------------------
%%% @Module  : mod_fish
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.9.17
%%% @Description: 全民垂钓
%%%--------------------------------------

-module(mod_fish).
-behaviour(gen_server).
-include("common.hrl").
-export([
	start_link/1,
	get_data/0,
	set_time/1
]).
-export([
	init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3
]).
-record(state, {
	weekrange = [],		%% 活动周期，例如[1,3,5,7]，表示周一三五日都有活动
	timerange = [],		%% 活动开始结束时间，例如[{13, 0}, {14, 0}]，表示13点开始，至14点结束
	roomlist = []		%% 房间列表，格式如：[{id, num}]
}).

%% 开启服务进程
start_link([WeekRange, TimeRange]) ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [WeekRange, TimeRange], []).

%% 设置活动开始周期，开始及结束时间
set_time([WeekRange, TimeRange]) ->
	gen_server:call(misc:get_global_pid(?MODULE), {set_time, [WeekRange, TimeRange]}).

%% 获得活动时间，及房间数据
get_data() ->
	gen_server:call(misc:get_global_pid(?MODULE), {get_data}).


%%----------------- 下面为回调函数 -----------------%%
init([WeekRange, TimeRange]) ->
	process_flag(trap_exit, true),
    {ok, #state{weekrange = WeekRange, timerange = TimeRange}}.

handle_call({get_data}, _From, State) ->
     {reply, [State#state.weekrange, State#state.timerange, State#state.roomlist], State};

handle_call({set_time, [WeekRange, TimeRange]}, _From, State) ->
   {reply, ok, State#state{weekrange = WeekRange, timerange = TimeRange}};

handle_call(_Request, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
     {noreply, State}.

terminate(_Reason, _Status) ->
	io:format("mod_fish terminate!~n"),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.
