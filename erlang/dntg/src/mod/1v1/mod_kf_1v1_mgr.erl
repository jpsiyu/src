%%% -------------------------------------------------------------------
%%% Author  : zengzhaoyuan
%%% Description :
%%%
%%% Created : 2012-5-22
%%% -------------------------------------------------------------------
-module(mod_kf_1v1_mgr).

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

-record(state, {mod=0,                   %% 模式 
				open_time = [],			 %% 开启时间列表
				loop = 0,				 %% 总轮次
				current_loop = 0,		 %% 当前轮次
				sign_up_time = 1,		 %% 报名时间
				rest_time = 1,			 %% 准备时间
				loop_time = 1,			 %% 每场耗时
				config_begin_hour=0,	 %% 开始时间
				config_begin_minute=0}). %% 开始时间 
-define(TIMEOUT_DEFAULT, 10).
-define(MOD_AT, 0). %%自动开启
-define(MOD_MT, 1). %%手动开启
%% ====================================================================
%% External functions
%% ====================================================================
%% 自动启动服务器
at_start_link() ->
    gen_fsm:start_link({local,?MODULE}, ?MODULE, [], []).

%% 手动启动服务器
%% @param Config_Begin_Hour 起始时刻
%% @param Config_Begin_Minute 起始时刻
%% @param Loop 轮次
%% @param Sign_up_time 报名时间
%% @param Rest_time 准备时间
%% @param Loop_time 消耗时间
mt_start_link(Config_Begin_Hour,Config_Begin_Minute,Loop,Sign_up_time,Loop_time) ->
	gen_fsm:send_all_state_event(?MODULE, {mt_start_link,Config_Begin_Hour,Config_Begin_Minute,Loop,Sign_up_time,Loop_time}).

%%走结束流程
go_finish() ->
	gen_fsm:send_all_state_event(?MODULE, go_finish).

%% 关闭服务器时回调
stop() ->
    gen_fsm:send_event(?MODULE,stop).

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
	%% 读取配置
	Open_time = data_kf_1v1:get_bd_1v1_config(open_time),
	Loop = data_kf_1v1:get_bd_1v1_config(loop),
	Sign_up_time = data_kf_1v1:get_bd_1v1_config(sign_up_time),
	Rest_time = data_kf_1v1:get_bd_1v1_config(rest_time),
	Loop_time = data_kf_1v1:get_bd_1v1_config(loop_time),
	
	%设置时间
	State = #state{mod=?MOD_AT,
		open_time = Open_time,			 %% 开启时间列表
		loop = Loop,				 	 %% 总轮次
		sign_up_time = Sign_up_time,	 %% 报名时间
		rest_time = Rest_time,			 %% 准备时间
		loop_time = Loop_time
	},
	
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
			mod_kf_1v1:set_status(0),%设置未开启状态
			mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_status,[0]),
			if
				3*60=<Gap-> %%超过3分钟
					{next_state, opening, State,(Gap-3*60)*1000};
				true->
					{next_state, opening, State,?TIMEOUT_DEFAULT}
			end;
		true->
			mod_kf_1v1:set_status(4),%设置未开启状态
			mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_status,[4]),
			{next_state, finished, State,?TIMEOUT_DEFAULT}
	end.

%% 竞技场未开启状态
no_open(_Event, State) ->
	%根据时间状态，进行处理
	{{_Year,_Month,Day},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60+Second,
	Open_day = data_kf_1v1:get_bd_1v1_config(open_day),
	case lists:member(Day, Open_day) of
		false->
			mod_kf_1v1:set_status(0),%设置未开启状态
			mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_status,[0]),
			{next_state, no_open, State,(24*60*60-NowTime)*1000}; %睡眠当天
		true->
			case get_next_1v1_time([Hour,Minute],State#state.open_time) of
				{ok,[Config_Begin_Hour,Config_Begin_Minute]}->%有开启时间点
					New_State = State#state{
						current_loop = 0,													
						config_begin_hour = Config_Begin_Hour,
						config_begin_minute = Config_Begin_Minute						
					},
					Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,%提前3分钟开始检测
					Gap = Config_Begin-NowTime,
					if
						0=<Gap->
							mod_kf_1v1:set_status(0),%设置未开启状态
							mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_status,[0]),
							if
								3*60=<Gap-> %%超过3分钟
									{next_state, opening, New_State,(Gap-3*60)*1000};
								true->
									{next_state, opening, New_State,?TIMEOUT_DEFAULT}
							end;
						true->
							mod_kf_1v1:set_status(4),%设置未开启状态
							mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_status,[4]),
							{next_state, finished, State,?TIMEOUT_DEFAULT}
					end;
				{error,_}-> %%当天没有可开启的时间点了
					mod_kf_1v1:set_status(4),%设置未开启状态
					mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_status,[4]),
					{next_state, no_open, State,(24*60*60-NowTime)*1000} %睡眠当天
			end
	end.

%%竞技场开启状态
opening(_Event, State) ->
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
	Loop = State#state.loop,
	Sign_up_time = State#state.sign_up_time,
	Loop_time = State#state.loop_time,
	NowTime = (Hour*60+Minute)*60 + Second,
	%% 计算起止时间（秒）
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
	if
		NowTime<Config_Begin->{next_state, opening, State,?TIMEOUT_DEFAULT};%未开启
		true->%活动时间内
			if
				Config_Begin=:=NowTime-> %广播所有玩家，竞技场开启。
					mod_kf_1v1:open_bd_1v1(Loop,Loop_time,Sign_up_time),
					mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_status,[1]),
					{next_state, opening, State,1000};
				true->
					{next_state, opening, State,?TIMEOUT_DEFAULT}
			end
	end.

%% 竞技场结束状态
finished(_Event, _State) ->
	%% 读取配置
	Open_time = data_kf_1v1:get_bd_1v1_config(open_time),
	Loop = data_kf_1v1:get_bd_1v1_config(loop),
	Sign_up_time = data_kf_1v1:get_bd_1v1_config(sign_up_time),
	Rest_time = data_kf_1v1:get_bd_1v1_config(rest_time),
	Loop_time = data_kf_1v1:get_bd_1v1_config(loop_time),
	mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_status,[4]),
	
	%设置时间
	New_State = #state{mod=?MOD_AT,
		open_time = Open_time,			 %% 开启时间列表
		loop = Loop,				 %% 总轮次
		sign_up_time = Sign_up_time,		 %% 报名时间
		rest_time = Rest_time,			 %% 准备时间
		loop_time = Loop_time
	},
	
	{next_state, no_open, New_State,?TIMEOUT_DEFAULT}.
	
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
handle_event({mt_start_link,Config_Begin_Hour,Config_Begin_Minute,Loop,Sign_up_time,Loop_time}, _StateName, _StateData) ->
	%设置时间
	New_State = #state{mod=?MOD_MT,
		loop = Loop,				 %% 总轮次
		sign_up_time = Sign_up_time,		 %% 报名时间
		loop_time = Loop_time,
		config_begin_hour=Config_Begin_Hour,
		config_begin_minute=Config_Begin_Minute
	},
	
	%根据竞技场状态，进行处理
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60+Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
	if
		NowTime=<Config_Begin-> %未开始
			{next_state, no_open_without_check_date, New_State,?TIMEOUT_DEFAULT};
		true-> %已结束
			{next_state, finished, New_State,?TIMEOUT_DEFAULT}
	end;

handle_event(go_finish, _StateName, State) ->
    {next_state, finished, State,?TIMEOUT_DEFAULT};

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
%% 获取下一场比赛时间
%% @param Now_Hour 当前时间_小时
%% @param Now_Minute 当前时间_分钟
%% @param Open_time_List 配置的可开启时刻
%% @return {ok,[A_hour,A_minute]}|{error,none}
get_next_1v1_time([Now_Hour,Now_Minute],Open_time_List)->
	%% 按时间升序排列
	Sort_Open_time_List = lists:sort(fun([A_hour,A_minute],[B_hour,B_minute])-> 
		if
			A_hour < B_hour -> true;
			A_hour =:= B_hour -> 
				if
					A_minute=<B_minute -> true;
					A_minute>B_minute -> false
				end;
			A_hour > B_hour -> false
		end
	end, Open_time_List),
	get_next_1v1_time_sub(Sort_Open_time_List,[Now_Hour,Now_Minute]).
get_next_1v1_time_sub([],[_Now_Hour,_Now_Minute])->{error,none};
get_next_1v1_time_sub([[A_hour,A_minute]|T],[Now_Hour,Now_Minute])->
	if
		A_hour<Now_Hour->get_next_1v1_time_sub(T,[Now_Hour,Now_Minute]);
		A_hour =:= Now_Hour -> 
			if
				A_minute=<Now_Minute -> get_next_1v1_time_sub(T,[Now_Hour,Now_Minute]);
				A_minute>Now_Minute -> {ok,[A_hour,A_minute]}
			end;
		A_hour > Now_Hour -> 
			{ok,[A_hour,A_minute]}
	end.
