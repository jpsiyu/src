%%%------------------------------------
%%% @Module  : mod_wubianhai_mgr_new
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.7.7
%%% @Description: 大闹天宫(无边海)
%%%------------------------------------
-module(mod_wubianhai_mgr_new).

-behaviour(gen_fsm).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([at_start_link/0,mt_start_link/4,stop/0]).

%% gen_fsm callbacks
-export([init/1, state_name/2, state_name/3, handle_event/3,
	 handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).
-compile(export_all).

-record(state, {mod=0,                   %%模式 
				config_begin_hour=0,     %%
				config_begin_minute=0,
				config_end_hour=0,
				config_end_minute=0}).
-define(TIMEOUT_DEFAULT, 10).
-define(MOD_AT, 0). %%自动开启
-define(MOD_MT, 1). %%手动开启
%% ====================================================================
%% External functions
%% ====================================================================
%% 自动启动服务器
%% @param Config_Begin_Hour 起始时刻
%% @param Config_Begin_Minute 起始时刻
%% @param Config_End_Hour 终止时刻
%% @param Config_End_Minute 终止时刻
at_start_link() ->
    gen_fsm:start_link({global,?MODULE}, ?MODULE, [], []).

%% 手动启动服务器
%% @param Config_Begin_Hour 起始时刻
%% @param Config_Begin_Minute 起始时刻
%% @param Config_End_Hour 终止时刻
%% @param Config_End_Minute 终止时刻
mt_start_link(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute) ->
	gen_fsm:send_all_state_event({global,?MODULE}, {mt_start_link,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute}).

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
	[[Config_Begin_Hour,Config_Begin_Minute],[Config_End_Hour,Config_End_Minute]] = data_wubianhai_new:get_wubianhai_config(arena_time),
	%设置时间
	State = #state{mod=?MOD_AT,
		   config_begin_hour=Config_Begin_Hour,
		   config_begin_minute=Config_Begin_Minute,
		   config_end_hour=Config_End_Hour,
		   config_end_minute=Config_End_Minute},

	mod_wubianhai_new:set_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute),
	%清理上次竞技场数据
	
	%根据竞技场状态，进行处理
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60+Second,
	Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
	if
		NowTime=<Config_End-> %未结束
			{ok, no_open_init, State,?TIMEOUT_DEFAULT};
		true-> %已结束
			{ok, finished, State,?TIMEOUT_DEFAULT}
	end.

no_open_init(_Event, State) ->
	util:sleep(3000),
	{next_state, no_open, State,?TIMEOUT_DEFAULT}.

%% --------------------------------------------------------------------
%% Func: StateName/2
%% Returns: {next_state, NextStateName, NextStateData}          |
%%          {next_state, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}
%% --------------------------------------------------------------------
%% 竞技场未开启状态
no_open(_Event, State) ->
	%%防止世界等级榜未生成
    util:sleep(5000),
	%io:format("wubianhai_mgr no_open:~p~n", [time()]),
    %%服务器在活动时间重启时，防止南天门创建怪物时场景进程未启动
	mod_wubianhai_new:set_status(0),%设置未开启状态
    Scene_id = data_wubianhai_new:get_wubianhai_config(scene_id),
	%MonId = data_wubianhai_new:get_wubianhai_config(mon_id),
    %[MonId1, MonId2, MonId3, MonId4, MonId5, MonId6, MonId7] = MonId,
    %% 提前开好房间，生成怪物
    Level = mod_wubianhai_new:set_world_lv(),
	mod_scene_agent:get_scene_pid(Scene_id),
    spawn(fun() ->
                lib_mon:clear_scene_mon(Scene_id, 1, 0),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 2, 0),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 3, 0),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 4, 0),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 5, 0),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 6, 0),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 7, 0),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 8, 0),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 9, 0),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 10, 0),
                util:sleep(5 * 1000),
                mod_scene_agent:apply_cast(Scene_id, mod_scene, copy_scene, [Scene_id, 1, Level]),
                util:sleep(5 * 1000),
                mod_scene_agent:apply_cast(Scene_id, mod_scene, copy_scene, [Scene_id, 2, Level]),
                util:sleep(5 * 1000),
                mod_scene_agent:apply_cast(Scene_id, mod_scene, copy_scene, [Scene_id, 3, Level]),
                util:sleep(5 * 1000),
                mod_scene_agent:apply_cast(Scene_id, mod_scene, copy_scene, [Scene_id, 4, Level]),
                util:sleep(5 * 1000),
                mod_scene_agent:apply_cast(Scene_id, mod_scene, copy_scene, [Scene_id, 5, Level]),
                util:sleep(5 * 1000),
                mod_scene_agent:apply_cast(Scene_id, mod_scene, copy_scene, [Scene_id, 6, Level]),
                util:sleep(5 * 1000),
                mod_scene_agent:apply_cast(Scene_id, mod_scene, copy_scene, [Scene_id, 7, Level]),
                util:sleep(5 * 1000),
                mod_scene_agent:apply_cast(Scene_id, mod_scene, copy_scene, [Scene_id, 8, Level]),
                util:sleep(5 * 1000),
                mod_scene_agent:apply_cast(Scene_id, mod_scene, copy_scene, [Scene_id, 9, Level]),
                util:sleep(5 * 1000),
                mod_scene_agent:apply_cast(Scene_id, mod_scene, copy_scene, [Scene_id, 10, Level])
        end),
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
    Config_End_Hour = State#state.config_end_hour,
	Config_End_Minute = State#state.config_end_minute,
	NowTime = (Hour*60+Minute)*60+Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,%提前5分钟开始检测
    Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
	Gap = Config_Begin-NowTime,
    Gap1 = Config_End-NowTime,
	if
		0=<Gap->
			if
				5*60=<Gap->
					{next_state, opening, State,5*60*1000};
				true->
					{next_state, opening, State,Gap*1000}
			end;
        0=<Gap1->
            {next_state, opening, State,?TIMEOUT_DEFAULT};
		true->
			{next_state, finished, State,?TIMEOUT_DEFAULT}
	end.

%%竞技场开启状态
opening(_Event, State) ->
	%io:format("wubianhai_mgr opening:~p~n", [time()]),
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
	Config_End_Hour = State#state.config_end_hour,
	Config_End_Minute = State#state.config_end_minute,
	NowTime = (Hour*60+Minute)*60 + Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
	Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
	if
		NowTime<Config_Begin->{next_state, opening, State,?TIMEOUT_DEFAULT};%未开启
		Config_Begin=<NowTime andalso NowTime<Config_End->
			if
				Config_Begin=:=NowTime-> %广播所有玩家，竞技场开启。
					mod_wubianhai_new:open_arena(),
					{next_state, opening, State,10 * 1000};
				true->
					%% 任务信息
					%%获取所有玩家Id
					%GetAll = mod_wubianhai_new:get_all_player_id(),
					%IdList = lib_wubianhai_new:list_deal(GetAll, []),
					%% 开新进程，活动开始后服务器每5秒给客户端发送一次任务信息
					%spawn(fun() -> lib_wubianhai_new:refresh_task(IdList) end),
					%% 每分钟广播一次
					{_Hour, _Min, _Sec} = time(),
					case _Sec >= 55 of
						true -> mod_wubianhai_new:open_arena();
						false -> skip
					end,
					{next_state, opening, State,5 * 1000}
			end;
		Config_End=<NowTime->
			{next_state, finished, State,?TIMEOUT_DEFAULT}
	end.

%% 活动结束
finished(_Event, State) ->
	%io:format("wubianhai_mgr finished:~p~n", [time()]),
    %% 强制清怪(防止mod_wubianhai_new出错后不清怪)
    Scene_id = data_wubianhai_new:get_wubianhai_config(scene_id),
    spawn(fun() ->
                lib_mon:clear_scene_mon(Scene_id, 1, 1),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 2, 1),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 3, 1),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 4, 1),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 5, 1),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 6, 1),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 7, 1),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 8, 1),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 9, 1),
                util:sleep(5 * 1000),
                lib_mon:clear_scene_mon(Scene_id, 10, 1) end),
    mod_exit:insert_max_room(wubianhai, 0),
	%告诉所有玩家结束
	mod_wubianhai_new:end_arena(), 
	{next_state, clear, State,3*60*1000}.%3分钟后清场

%% 活动结束，清场
clear(_Event, State) ->
	%io:format("wubianhai_mgr clear:~p~n", [time()]),
	%告诉所有玩家结束
	mod_wubianhai_new:clear(), 
	%计算休眠时间
	{{_,_,_},{Hour,Minute,_}} = calendar:local_time(),
	[[Config_Begin_Hour,Config_Begin_Minute],[Config_End_Hour,Config_End_Minute]] = data_wubianhai_new:get_wubianhai_config(arena_time),
	NowTime = Hour*60+Minute,
	Config_Begin = Config_Begin_Hour*60 + Config_Begin_Minute-3,%提前3分钟开始检测
	%还原竞技场自动开启模式
	NewState = State#state{mod=?MOD_AT,
						   config_begin_hour=Config_Begin_Hour,
						   config_begin_minute=Config_Begin_Minute,
						   config_end_hour=Config_End_Hour,
						   config_end_minute=Config_End_Minute},
    mod_wubianhai_new:set_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute),
    if Config_Begin_Hour =:= 11 ->
           {next_state, no_open, NewState,(Config_Begin+24*60-20*60-NowTime)*60*1000};
       true ->
        {next_state, no_open, NewState,(Config_Begin-NowTime)*60*1000}
    end.%基本关闭当天的状态机

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
handle_event({mt_start_link,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute}, _StateName, _StateData) ->
	%设置时间
	State = #state{mod=?MOD_MT,
		   config_begin_hour=Config_Begin_Hour,
		   config_begin_minute=Config_Begin_Minute,
		   config_end_hour=Config_End_Hour,
		   config_end_minute=Config_End_Minute},
	mod_wubianhai_new:set_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute),
	%清理上次竞技场数据
	
	%根据竞技场状态，进行处理
	%{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	%NowTime = (Hour*60+Minute)*60+Second,
	%Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
    {next_state, no_open, State,?TIMEOUT_DEFAULT};
	%if
	%	NowTime=<Config_Begin-> %未开始
	%		{next_state, no_open, State,?TIMEOUT_DEFAULT};
	%	true-> %已结束
	%		{next_state, finished, State,?TIMEOUT_DEFAULT}
	%end;

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
init_set(Mod,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute)->
	%设置时间
	State = #state{mod=Mod,
		   config_begin_hour=Config_Begin_Hour,
		   config_begin_minute=Config_Begin_Minute,
		   config_end_hour=Config_End_Hour,
		   config_end_minute=Config_End_Minute},
	mod_wubianhai_new:set_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute),
	%清理上次竞技场数据
	
	%根据竞技场状态，进行处理
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60+Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
	if
		NowTime=<Config_Begin-> %未开始
			{ok, no_open, State,?TIMEOUT_DEFAULT};
		true-> %已结束
			{ok, finished, State,?TIMEOUT_DEFAULT}
	end.

