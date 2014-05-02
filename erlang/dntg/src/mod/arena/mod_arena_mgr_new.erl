%%% -------------------------------------------------------------------
%%% Author  : zengzhaoyuan
%%% Description :
%%%
%%% Created : 2012-5-22
%%% -------------------------------------------------------------------
-module(mod_arena_mgr_new).

-behaviour(gen_fsm).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([at_start_link/0,mt_start_link/5,stop/0]).

%% gen_fsm callbacks
-export([init/1, state_name/2, state_name/3, handle_event/3,
	 handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).
-compile(export_all).

-record(state, {mod=0,                   %%模式 
				config_begin_hour=0,     %%
				config_begin_minute=0,
				config_end_hour=0,
				config_end_minute=0,
				boss_time = [],
				add_anger_time = 0,
				boss_turn = 0}).
-define(TIMEOUT_DEFAULT, 10).
-define(MOD_AT, 0). %%自动开启
-define(MOD_MT, 1). %%手动开启
%% ====================================================================
%% External functions
%% ====================================================================
%% 自动启动服务器
at_start_link() ->
    gen_fsm:start_link({global,?MODULE}, ?MODULE, [], []).

%% 手动启动服务器
%% @param Config_Begin_Hour 起始时刻
%% @param Config_Begin_Minute 起始时刻
%% @param Config_End_Hour 终止时刻
%% @param Config_End_Minute 终止时刻
%% @param Boss_Time 创建boss的时间间隔
mt_start_link(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, Boss_Time) ->
	gen_fsm:send_all_state_event({global,?MODULE}, {mt_start_link,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, Boss_Time}).

%% 关闭服务器时回调
stop() ->
    gen_fsm:send_event({global,?MODULE},stop).

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
	[[Config_Begin_Hour,Config_Begin_Minute],[Config_End_Hour,Config_End_Minute]] = data_arena_new:get_arena_config(arena_time),
	Boss_time = data_arena_new:get_arena_config(boss_time),
	%设置时间
	State = #state{mod=?MOD_AT,
		   config_begin_hour=Config_Begin_Hour,
		   config_begin_minute=Config_Begin_Minute,
		   config_end_hour=Config_End_Hour,
		   config_end_minute=Config_End_Minute,
		   boss_time = Boss_time},
	mod_arena_new:set_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute,Boss_time),
	
	%根据时间状态，进行处理
	{ok, no_open, State,?TIMEOUT_DEFAULT}.

%% --------------------------------------------------------------------
%% Func: StateName/2
%% Returns: {next_state, NextStateName, NextStateData}          |
%%          {next_state, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}
%% --------------------------------------------------------------------
%% 竞技场未开启状态(提供给秘籍使用)
no_open_without_check_date(_Event, State) ->
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
	NowTime = (Hour*60+Minute)*60+Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,%提前3分钟开始检测
	Gap = Config_Begin-NowTime,
	if
		0=<Gap->
			mod_arena_new:set_status(0),%设置未开启状态
			if
				3*60=<Gap-> %%超过3分钟
					{next_state, opening, State,(Gap-3*60)*1000};
				true->
					{next_state, opening, State,?TIMEOUT_DEFAULT}
			end;
		true->
			mod_arena_new:set_status(2),%设置未开启状态
			{next_state, finished, State,?TIMEOUT_DEFAULT}
	end.

%% 竞技场未开启状态
no_open(_Event, State) ->
	%根据时间状态，进行处理
	{{Year,Month,Day},{Hour,Minute,Second}} = calendar:local_time(),
	Day_of_the_week = calendar:day_of_the_week(Year,Month,Day),
	NowTime = (Hour*60+Minute)*60+Second,
	Open_day = data_arena_new:get_arena_config(open_day),
	case lists:member(Day_of_the_week, Open_day) of
		false->
			mod_arena_new:set_status(0),%设置未开启状态
			{next_state, no_open, State,(24*60*60-NowTime)*1000}; %睡眠当天
		true->
			Config_Begin_Hour = State#state.config_begin_hour,
			Config_Begin_Minute = State#state.config_begin_minute,
			Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,%提前3分钟开始检测
			Gap = Config_Begin-NowTime,
			if
				0=<Gap->
					mod_arena_new:set_status(0),%设置未开启状态
					if
						3*60=<Gap-> %%超过3分钟
							{next_state, opening, State,(Gap-3*60)*1000};
						true->
							{next_state, opening, State,?TIMEOUT_DEFAULT}
					end;
				true->
					mod_arena_new:set_status(2),%设置未开启状态
					{next_state, finished, State,?TIMEOUT_DEFAULT}
			end
	end.

%%竞技场开启状态
opening(_Event, State) ->
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
	Config_End_Hour = State#state.config_end_hour,
	Config_End_Minute = State#state.config_end_minute,
	AngerInterval = data_arena_new:get_arena_config(anger_interval),
	%% 创建boss的时间
	Boss_turn = State#state.boss_turn,
	case Boss_turn >= 3 of 
		true ->
			Boss_Create_Time = 0;
		false ->
			Boss_time = State#state.boss_time,
			{Boss_Hour,Boss_Minute} = lists:nth(Boss_turn+1, Boss_time),
			Boss_Create_Time = (Boss_Hour*60+Boss_Minute)*60
	end,
	NowTime = (Hour*60+Minute)*60 + Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
	Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
	if
		NowTime<Config_Begin->{next_state, opening, State,?TIMEOUT_DEFAULT};%未开启
		Config_Begin=<NowTime andalso NowTime<Config_End->
			if
				Config_Begin=:=NowTime-> %广播所有玩家，竞技场开启。
					mod_arena_new:open_arena(),
					NewState = State#state{add_anger_time = NowTime},
					{next_state, opening, NewState,60*1000};
				%(NowTime-State#state.box_last_minutes) =:= (Box_interval*60+3)-> %箱子刷新
				Boss_Create_Time =:= NowTime ->
					mod_arena_new:call_boss(Boss_turn+1),%%召唤boss
					NewState = State#state{boss_turn = Boss_turn + 1},
					{next_state, opening, NewState,1000};
				% 定时给玩家加怒气
				(NowTime - State#state.add_anger_time) =:= (AngerInterval*60+3) ->
					mod_arena_new:add_anger_timer(),
					NewState = State#state{add_anger_time = NowTime},
					{next_state, opening, NewState, ?TIMEOUT_DEFAULT};
				true->
					{next_state, opening, State,?TIMEOUT_DEFAULT}
			end;
		Config_End=<NowTime->
			NewState = State,
			{next_state, finished, NewState,?TIMEOUT_DEFAULT}
	end.

%% 竞技场结束状态
finished(_Event, _State) ->
	[[Config_Begin_Hour,Config_Begin_Minute],[Config_End_Hour,Config_End_Minute]] = data_arena_new:get_arena_config(arena_time),
	%设置时间
	NewState = #state{mod=?MOD_AT,
		   config_begin_hour=Config_Begin_Hour,
		   config_begin_minute=Config_Begin_Minute,
		   config_end_hour=Config_End_Hour,
		   config_end_minute=Config_End_Minute},
	
	%告诉所有玩家结束
	mod_arena_new:end_arena(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute), 
	
	%根据时间状态，进行处理
	{_,{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60+Second,
	{next_state, no_open, NewState,(24*60*60-NowTime)*1000}.%睡眠当天
	
state_name(_Event, State) ->
    {next_state, state_name, State}.

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
handle_event({mt_start_link,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, Boss_Time}, _StateName, _StateData) ->
	%设置时间
	State = #state{mod=?MOD_MT,
		   config_begin_hour=Config_Begin_Hour,
		   config_begin_minute=Config_Begin_Minute,
		   config_end_hour=Config_End_Hour,
		   config_end_minute=Config_End_Minute,
		   boss_time = [{Config_Begin_Hour,Config_Begin_Minute+Boss_Time},{Config_Begin_Hour,Config_Begin_Minute+Boss_Time*2},{Config_Begin_Hour,Config_Begin_Minute+Boss_Time*3}]},
	mod_arena_new:set_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, State#state.boss_time),
	
	Apply_level = data_arena_new:get_arena_config(apply_level),
	L = mod_chat_agent:match(all_ids_by_lv_gap, [Apply_level, 999]),
	War_end_time = util:unixdate() + (Config_End_Hour*60 + Config_End_Minute)*60 - 2,
	spawn(fun()-> 
		lists:foreach(fun(Id)->
			lib_arena_new:update_enter_time(Id,War_end_time),							  
			timer:sleep(100)					  
		end, L)
	end),
	
	%根据竞技场状态，进行处理
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60+Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
	if
		NowTime=<Config_Begin-> %未开始
			{next_state, no_open_without_check_date, State,?TIMEOUT_DEFAULT};
		true-> %已结束
			{next_state, finished, State,?TIMEOUT_DEFAULT}
	end;

handle_event(stop, _StateName, State) ->
    {stop, normal, State};

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

