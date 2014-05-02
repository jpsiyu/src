%%% -------------------------------------------------------------------
%%% Author  : zengzhaoyuan
%%% Description :
%%%
%%% Created : 2012-5-22
%%% -------------------------------------------------------------------
-module(mod_factionwar_mgr).

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
				sign_up_time = 0,
				loop_time = 0,
				max_faction = 0,
				current_loop = 0,
				is_faction_war=0, %是否已进行帮战
				add_score_time = 0,
				call_buff_time = 0,
				factionwar_last_time=0}).
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
%% @param Sign_Up_Time 报名时间
%% @param Loop_Time 每轮耗时
%% @param Max_faction 每张图最大允许进入帮派数
mt_start_link(Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction) ->
	gen_fsm:send_all_state_event({global,?MODULE}, {mt_start_link,Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction}).

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
	[Config_Begin_Hour,Config_Begin_Minute] = data_factionwar:get_factionwar_config(time),
	Sign_up_time = data_factionwar:get_factionwar_config(sign_up_time),
	Loop_Time = data_factionwar:get_factionwar_config(loop_time),
	Max_faction = data_factionwar:get_factionwar_config(max_faction),
	%设置时间
	State = #state{mod=?MOD_AT,
		   config_begin_hour=Config_Begin_Hour,
		   config_begin_minute=Config_Begin_Minute,
  		   sign_up_time = Sign_up_time,				   
		   loop_time = Loop_Time,
		   max_faction = Max_faction,				   
		   current_loop = 0},
	mod_factionwar:set_time(Config_Begin_Hour,Config_Begin_Minute,Sign_up_time,Loop_Time,Max_faction),
	
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
	mod_factionwar:set_status(1),%设置未开启状态
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
	NowTime = (Hour*60+Minute)*60+Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,%提前3分钟开始检测
	Gap = Config_Begin-NowTime,
	if
		0=<Gap->
			mod_factionwar:set_status(1),%设置未开启状态
			if
				3*60=<Gap-> %%超过3分钟
					{next_state, opening, State,(Gap-3*60)*1000};
				true->
					{next_state, opening, State,?TIMEOUT_DEFAULT}
			end;
		true->
			mod_factionwar:set_status(4),%设置未开启状态
			{next_state, finished, State,?TIMEOUT_DEFAULT}
	end.

%% 帮战未开启状态
no_open(_Event, State) ->
	%根据时间状态，进行处理
	{{Year,Month,Day},{Hour,Minute,Second}} = calendar:local_time(),
	Day_of_the_week = calendar:day_of_the_week(Year,Month,Day),
	NowTime = (Hour*60+Minute)*60+Second,
	Open_day = data_factionwar:get_factionwar_config(open_day),
	case lists:member(Day_of_the_week, Open_day) of
		false->
			mod_factionwar:set_status(1),%设置未开启状态
			{next_state, no_open, State,(24*60*60-NowTime)*1000}; %睡眠当天
		true->
			Config_Begin = (State#state.config_begin_hour*60 + State#state.config_begin_minute)*60, %以报名时间为准
			if
				NowTime=<Config_Begin-> %未开始
					Config_Begin_Hour = State#state.config_begin_hour,
					Config_Begin_Minute = State#state.config_begin_minute,
					Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,%提前3分钟开始检测
					Gap = Config_Begin-NowTime,
					if
						0=<Gap->
							mod_factionwar:set_status(1),%设置未开启状态
							if
								3*60=<Gap-> %%超过3分钟
									{next_state, opening, State,(Gap-3*60)*1000};
								true->
									{next_state, opening, State,?TIMEOUT_DEFAULT}
							end;
						true->
							mod_factionwar:set_status(4),%设置未开启状态
							{next_state, finished, State,?TIMEOUT_DEFAULT}
					end;
				true-> %已结束
					mod_factionwar:set_status(4),%设置未开启状态
					{next_state, finished, State,?TIMEOUT_DEFAULT}
			end
	end.

%%帮战开启状态
opening(_Event, State) ->
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
	Sign_up_time = State#state.sign_up_time,
	NowTime = (Hour*60+Minute)*60 + Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,%%报名开始时刻
	Config_FactionWar_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute+Sign_up_time)*60,%%帮战开始时刻
	Loop_Time = State#state.loop_time, %每轮时间(如果不能整除，最后一轮会多出时间)
	Add_score_time = data_factionwar:get_factionwar_config(add_score_time),
	Call_buff_time = data_factionwar:get_factionwar_config(call_buff_time),
	if
		NowTime<Config_Begin->{next_state, opening, State,?TIMEOUT_DEFAULT};%未开启
		true->
			if
				Config_Begin=:=NowTime-> %广播所有玩家，帮战开始报名。
					mod_factionwar:sign_up_factionwar(),
					NewState = State#state{is_faction_war=0},
					{next_state, opening, NewState,Sign_up_time*60*1000};
				Config_FactionWar_Begin=:=NowTime-> %广播所有玩家，帮战开始。
					mod_factionwar:open_factionwar(NowTime),
					NewState = State#state{
					   current_loop=1,
					   is_faction_war=1,
					   add_score_time = NowTime,
					   call_buff_time = NowTime,
					   factionwar_last_time=NowTime
					},
					{next_state, opening, NewState,Sign_up_time*60*1000};
				State#state.is_faction_war=:=1 andalso ((NowTime-State#state.factionwar_last_time)=:=Loop_Time*60)-> %轮次转换
					case mod_factionwar:have_next_loop() of
						1->
							mod_factionwar:cancle_round_factionwar(NowTime),
							NewState = State#state{current_loop=State#state.current_loop+1,factionwar_last_time=NowTime},
							{next_state, opening, NewState,?TIMEOUT_DEFAULT};
						_->%无下一轮，直接走结束流程
							NewState = State#state{is_faction_war=0,factionwar_last_time=NowTime},
							{next_state, finished, NewState,?TIMEOUT_DEFAULT}
					end;
				State#state.is_faction_war=:=1 andalso ((NowTime-State#state.add_score_time)=:=Add_score_time*60)-> %定时加分
					mod_factionwar:add_score(),
					NewState = State#state{add_score_time=NowTime},
					{next_state, opening, NewState,?TIMEOUT_DEFAULT};
				State#state.is_faction_war=:=1 andalso ((NowTime-State#state.call_buff_time)=:=Call_buff_time*60)-> %定时召唤怪物
					%mod_factionwar:call_buff(),
					NewState = State#state{call_buff_time=NowTime},
					{next_state, opening, NewState,?TIMEOUT_DEFAULT};
				true->
					{next_state, opening, State,?TIMEOUT_DEFAULT}
			end
	end.

%% 帮战结束状态
finished(_Event, _State) ->
	[Config_Begin_Hour,Config_Begin_Minute] = data_factionwar:get_factionwar_config(time),
	Sign_up_time = data_factionwar:get_factionwar_config(sign_up_time),
	Max_faction = data_factionwar:get_factionwar_config(max_faction),
	Loop_Time = data_factionwar:get_factionwar_config(loop_time),
	%设置时间
	NewState = #state{mod=?MOD_AT,
					  config_begin_hour=Config_Begin_Hour,
					  config_begin_minute=Config_Begin_Minute,
			  		  sign_up_time = Sign_up_time,				   
					  max_faction=Max_faction,
					  loop_time = Loop_Time},
	
	%告诉所有玩家结束
	mod_factionwar:end_factionwar(Config_Begin_Hour,Config_Begin_Minute,Sign_up_time,Loop_Time,Max_faction), 
	
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
handle_event({mt_start_link,Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction}, _StateName, _StateData) ->
	%设置时间
	State = #state{mod=?MOD_MT,
				   config_begin_hour=Config_Begin_Hour,
				   config_begin_minute=Config_Begin_Minute,
				   sign_up_time = Sign_Up_Time,
				   loop_time = Loop_Time,
				   max_faction = Max_faction},
	mod_factionwar:set_time(Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction),
	
	%根据帮战状态，进行处理
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

	