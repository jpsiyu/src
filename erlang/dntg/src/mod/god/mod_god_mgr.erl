%%% -------------------------------------------------------------------
%%% Author  : zengzhaoyuan
%%% Description :
%%%
%%% Created : 2012-5-22
%%% -------------------------------------------------------------------
-module(mod_god_mgr).

-behaviour(gen_fsm).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([at_start_link/0,stop/0]).

%% gen_fsm callbacks
-export([init/1, state_name/2, state_name/3, handle_event/3,
	 handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).
-compile(export_all).

-record(state, {
	mod=0,                   	%% 模式 
	status = 0,				 	%% 状态：0无赛事、1海选赛、2小组赛、3复活赛/人气赛、4总决赛
	next_status = 0,			%% 下一个状态
	god_no = 0,					%% 第几届
	open_day = [],			 	%% 开启日期
	open_time = [],			 	%% 开启时间列表
	config_begin_hour = 0,		%% 活动开启时间-小时
	config_begin_minute = 0,	%% 活动开启时间-分钟
	config_end_hour = 0,		%% 活动结束时间-小时
	config_end_minute = 0		%% 活动结束时间-分钟
}). 
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
%% @param Mod 开启模式
%% @param Next_Mod 开启模式 (注意此值的填法，填跟Next_Mod值一样了，不会结算，不一样才结算)
%% @param Open_time 起始时刻
mt_start_link(Mod,Next_Mod,God_no,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute) ->
	gen_fsm:send_all_state_event(?MODULE, {mt_start_link,Mod,Next_Mod,God_no,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute}).

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
	Open_day = data_god:get(open_day),
	God_no = data_god:get_god_no(Open_day),
	Open_time = data_god:get(open_time),
	
	State = #state{
		mod=?MOD_AT,          
		status = 0,		
		god_no = God_no,	
		open_day = Open_day,	
		open_time = Open_time
	},
	%%让服务加载一次数据
	mod_god:load_god(God_no,0),
	
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
	%根据时间状态，进行处理
	{Hour,Minute,Second} = time(),
	NowTime = (Hour*60+Minute)*60+Second,
	Status = State#state.status,
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
	Config_End_Hour = State#state.config_end_hour,
	Config_End_Minute = State#state.config_end_minute,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,%提前3分钟开始检测
	Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
	Gap = Config_Begin-NowTime,
	if
		0=<Gap->
			mod_god:set_mod_and_status(State#state.god_no,Status,0,Config_End),
			mod_clusters_center:apply_to_all_node(mod_god_state,set_mod_and_status,[Status,0,Config_End]),
			if
				3*60=<Gap-> %%超过3分钟
					{next_state, opening, State,(Gap-3*60)*1000};
				true->
					{next_state, opening, State,?TIMEOUT_DEFAULT}
			end;
		true->
			mod_god:set_mod_and_status(State#state.god_no,Status,2,Config_End),
			mod_clusters_center:apply_to_all_node(mod_god_state,set_mod_and_status,[Status,2,Config_End]),
			{next_state, finished, State,?TIMEOUT_DEFAULT}
	end.

%% 竞技场未开启状态
no_open(_Event, State) ->
	%根据时间状态，进行处理
	{Hour,Minute,Second} = time(),
	NowTime = (Hour*60+Minute)*60+Second,
	Open_day_list = State#state.open_day,
	case data_god:get_open_day(Open_day_list) of
		{ok,{God_no,Status,Next_Status}}->%%有合理时间配置
			Open_time_list = State#state.open_time,
			case lib_god:get_next_time(Open_time_list,Hour,Minute) of
				{ok,[Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute]}->%有开启时间点
					New_State = State#state{
						god_no = God_no,											
						status = Status,
						next_status = Next_Status,		
						config_begin_hour = Config_Begin_Hour,
						config_begin_minute = Config_Begin_Minute,
						config_end_hour = Config_End_Hour,		
						config_end_minute = Config_End_Minute						
					},
					Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,%提前3分钟开始检测
					Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
					Gap = Config_Begin-NowTime,
					if
						0=<Gap->
							mod_god:set_mod_and_status(God_no,Status,0,Config_End),
							mod_clusters_center:apply_to_all_node(mod_god_state,set_mod_and_status,[Status,0,Config_End]),
							if
								Hour=<7 andalso Status=:=4-> %%复活赛复活名单结算
									mod_god:vote_relive_list();
								true->
									void
							end,
							if
								3*60=<Gap-> %%超过3分钟
									{next_state, opening, New_State,(Gap-3*60)*1000};
								true->
									{next_state, opening, New_State,?TIMEOUT_DEFAULT}
							end;
						true->
							mod_god:set_mod_and_status(God_no,Status,2,Config_End),
							mod_clusters_center:apply_to_all_node(mod_god_state,set_mod_and_status,[Status,2,Config_End]),
							{next_state, finished, State,?TIMEOUT_DEFAULT}
					end;
				_->
					mod_god:set_mod_and_status(God_no,Status,2,0),
					mod_clusters_center:apply_to_all_node(mod_god_state,set_mod_and_status,[Status,2,0]),
					{next_state, no_open, State,(24*60*60-NowTime)*1000} %睡眠当天
			end;
		_->%%无合理时间配置，睡眠当天
			God_no = data_god:get_god_no(data_god:get(open_day)),
			mod_god:set_mod_and_status(God_no,0,0,0),
			mod_clusters_center:apply_to_all_node(mod_god_state,set_mod_and_status,[God_no,0,0]),
			{next_state, no_open, State,(24*60*60-NowTime)*1000} %睡眠当天
	end.
	
%%竞技场开启状态
opening(_Event, State) ->
	{Hour,Minute,Second} = time(),
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
	Config_End_Hour = State#state.config_end_hour,
	Config_End_Minute = State#state.config_end_minute,
	Status = State#state.status,
	Next_status = State#state.next_status,
	NowTime = (Hour*60+Minute)*60 + Second,
	%% 计算起止时间（秒）
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
	Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
	if
		NowTime<Config_Begin->
			mod_god:set_mod_and_status(State#state.god_no,Status,0,Config_End),
			mod_clusters_center:apply_to_all_node(mod_god_state,set_mod_and_status,[Status,0,Config_End]),
			{next_state, opening, State,?TIMEOUT_DEFAULT};%未开启
		NowTime=:=Config_Begin->
			mod_god:open(Status,Next_status,State#state.god_no,State#state.open_time,Config_End),
			mod_clusters_center:apply_to_all_node(mod_god_state,set_mod_and_status,[Status,1,Config_End]),
			{next_state, opening, State,1000};%未开启
		NowTime=:=Config_End->
			mod_clusters_center:apply_to_all_node(mod_god_state,set_mod_and_status,[Status,2,Config_End]),		
			mod_god:close(),
			{next_state, finished, State,1000};%已结束
		true->
			{next_state, opening, State,?TIMEOUT_DEFAULT}
	end.

%% 竞技场结束状态
finished(_Event, _State) ->
	%% 读取配置
	Open_day = data_god:get(open_day),
	God_no = data_god:get_god_no(Open_day),
	Open_time = data_god:get(open_time),
	
	State = #state{
		mod=?MOD_AT,          
		status = 0,		
		god_no = God_no,	
		open_day = Open_day,	
		open_time = Open_time
	},
	
	%根据时间状态，进行处理
	{next_state, no_open, State,?TIMEOUT_DEFAULT}.
	
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
handle_event({mt_start_link,Status,Next_Status,God_no,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute}, _StateName, _StateData) ->
	%设置时间
	New_State = #state{
		status = Status,
		next_status = Next_Status,	
		god_no = God_no,
		open_time = [{Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute}],	
		config_begin_hour = Config_Begin_Hour,
		config_begin_minute = Config_Begin_Minute,
		config_end_hour = Config_End_Hour,		
		config_end_minute = Config_End_Minute						
	},
	
	%根据竞技场状态，进行处理
	{Hour,Minute,Second} = time(),
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

