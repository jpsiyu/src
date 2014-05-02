%%%------------------------------------
%%% @Module  : mod_loverun_mgr
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.8.21
%%% @Description: 爱情长跑
%%%------------------------------------
-module(mod_loverun_mgr).
-behaviour(gen_fsm).
-export([at_start_link/0, mt_start_link/5, stop/0]).
-export([init/1, state_name/2, state_name/3, handle_event/3,
	 handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).
-compile(export_all).
-record(state, {
				config_begin_hour = 0,
				config_begin_minute = 0,
				config_end_hour = 0,
				config_end_minute = 0,
                apply_time = 0}).
-define(TIMEOUT_DEFAULT, 10).
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
mt_start_link(Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute, ApplyTime) ->
	gen_fsm:send_all_state_event({global,?MODULE}, {mt_start_link, Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute, ApplyTime}).

%% 关闭服务器时回调
stop() ->
    gen_fsm:send_event({global,?MODULE},stop).

init([]) ->
    [{Year1, Month1, Day1}, {Year2, Month2, Day2}] = data_loverun_time:get_loverun_time(activity_date),
    case date() >= {Year1, Month1, Day1} andalso date() =< {Year2, Month2, Day2} of
        false -> {ok, finished, #state{}, 60 * 60 * 1000};
        true ->
            ApplyTime = data_loverun:get_loverun_config(apply_time),
            [[{Config_Begin_Hour1, Config_Begin_Minute1}, {Config_End_Hour1, Config_End_Minute1}], [{Config_Begin_Hour2, Config_Begin_Minute2}, {Config_End_Hour2, Config_End_Minute2}]] = data_loverun_time:get_loverun_time(activity_time),
            %设置时间
            {NowHour, NowMin, NowSec} = time(),
            case (Config_End_Hour1 * 60 + Config_End_Minute1) - (NowHour * 60 + NowMin) =< 0 andalso (Config_End_Hour2 * 60 + Config_End_Minute2) - (NowHour * 60 + NowMin) > 0 of
                true ->
                    Config_Begin_Hour = Config_Begin_Hour2,
                    Config_Begin_Minute = Config_Begin_Minute2,
                    Config_End_Hour = Config_End_Hour2,
                    Config_End_Minute = Config_End_Minute2,
                    State = #state{
                        config_begin_hour = Config_Begin_Hour2,
                        config_begin_minute = Config_Begin_Minute2,
                        config_end_hour = Config_End_Hour2,
                        config_end_minute = Config_End_Minute2,
                        apply_time = ApplyTime};
                false -> 
                    Config_Begin_Hour = Config_Begin_Hour1,
                    Config_Begin_Minute = Config_Begin_Minute1,
                    Config_End_Hour = Config_End_Hour1,
                    Config_End_Minute = Config_End_Minute1,
                    State = #state{
                        config_begin_hour = Config_Begin_Hour1,
                        config_begin_minute = Config_Begin_Minute1,
                        config_end_hour = Config_End_Hour1,
                        config_end_minute = Config_End_Minute1,
                        apply_time = ApplyTime}
            end,
            
            mod_loverun:set_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, ApplyTime),
            NowTime = (NowHour*60+NowMin)*60+NowSec,
            Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
            %io:format("Config_End_Hour:~p, Config_End_Minute:~p~n", [Config_End_Hour, Config_End_Minute]),
            if NowTime=<Config_End-> %未结束
                    {ok, no_open, State, ?TIMEOUT_DEFAULT};
                true-> %已结束
                    {ok, finished, State, ?TIMEOUT_DEFAULT}
            end
    end.

%% 未开启状态
no_open(_Event, State) ->
	%io:format("mod_loverun_mgr no_open:~p~n", [time()]),
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
    Config_End_Hour = State#state.config_end_hour,
	Config_End_Minute = State#state.config_end_minute,
	NowTime = (Hour*60+Minute)*60+Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
    Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
	Gap = Config_Begin-NowTime,
    Gap1 = Config_End-NowTime,
	if
        0=<Gap->
            {next_state, before_deal, State,Gap*1000};
        0=<Gap1->
            {next_state, before_deal, State,?TIMEOUT_DEFAULT};
		true->
			{next_state, finished, State,?TIMEOUT_DEFAULT}
	end.

%%开启前处理
before_deal(_Event, State) ->
    %io:format("mod_loverun_mgr before_deal:~p~n", [time()]),
    %% 开始传闻
    lib_chat:send_TV({all},1,2, ["loveRunStart"]),
    mod_loverun:broadcast(),
    {next_state, opening, State,?TIMEOUT_DEFAULT}.

%%开启状态
opening(_Event, State) ->
	%io:format("mod_loverun_mgr opening:~p~n", [time()]),
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
				Config_Begin=:=NowTime-> %广播所有玩家，活动开启。
					mod_loverun:broadcast(),
					{next_state, opening, State, 10 * 1000};
				true->
					%% 每分钟广播一次
					{_Hour, _Min, _Sec} = time(),
					case _Sec >= 59 of
						true -> 
                            ApplyTime = State#state.apply_time,
                            mod_loverun:broadcast(),
                            %% 15分钟内发送离活动开始剩余时间
                            SceneId = data_loverun:get_loverun_config(scene_id),
                            case (_Hour * 60 + _Min) - (Config_Begin_Hour * 60 + Config_Begin_Minute) < ApplyTime - 1 of
                                true ->
                                    %io:format("_Min:~p, Config_Begin_Minute:~p~n", [_Min, Config_Begin_Minute]),
                                    RestTime = (Config_Begin_Hour * 60 + Config_Begin_Minute + ApplyTime - _Hour * 60 - _Min) * 60 - _Sec,
                                    {ok, BinData} = pt_343:write(34310, [RestTime]),
                                    lib_unite_send:send_to_scene(SceneId, 1, BinData);
                                false -> 
                                    case (_Hour * 60 + _Min) - (Config_Begin_Hour * 60 + Config_Begin_Minute) =:= ApplyTime - 1 of
                                        true ->
                                            {ok, BinData} = pt_343:write(34310, [0]),
                                            lib_unite_send:send_to_scene(SceneId, 1, BinData),
                                            lib_unite_send:send_to_scene(SceneId, 2, BinData),
                                            lib_unite_send:send_to_scene(SceneId, 3, BinData),
                                            lib_unite_send:send_to_scene(SceneId, 4, BinData),
                                            lib_unite_send:send_to_scene(SceneId, 5, BinData),
                                            lib_unite_send:send_to_scene(SceneId, 6, BinData),
                                            lib_unite_send:send_to_scene(SceneId, 7, BinData),
                                            lib_unite_send:send_to_scene(SceneId, 8, BinData),
                                            lib_unite_send:send_to_scene(SceneId, 9, BinData),
                                            lib_unite_send:send_to_scene(SceneId, 10, BinData);
                                        false ->
                                            skip
                                    end
                            end;
						false -> 
                            skip
					end,
					{next_state, opening, State, 1 * 1000}
			end;
		Config_End=<NowTime->
			{next_state, finished, State, ?TIMEOUT_DEFAULT}
	end.

%% 活动结束
finished(_Event, State) ->
	%io:format("mod_loverun_mgr finished:~p~n", [time()]),
    mod_loverun:clear(),
    %% 发送活动结束消息给客户端
    SceneId = data_loverun:get_loverun_config(scene_id),
    {ok, BinData} = pt_343:write(34300, [0]),
    lib_unite_send:send_to_scene(SceneId, 1, BinData),
    lib_unite_send:send_to_scene(SceneId, 2, BinData),
    lib_unite_send:send_to_scene(SceneId, 3, BinData),
    lib_unite_send:send_to_scene(SceneId, 4, BinData),
    lib_unite_send:send_to_scene(SceneId, 5, BinData),
    lib_unite_send:send_to_scene(SceneId, 6, BinData),
    lib_unite_send:send_to_scene(SceneId, 7, BinData),
    lib_unite_send:send_to_scene(SceneId, 8, BinData),
    lib_unite_send:send_to_scene(SceneId, 9, BinData),
    lib_unite_send:send_to_scene(SceneId, 10, BinData),
	{next_state, clear, State,1*60*1000}.%1分钟后结算

%% 活动结束，清场
clear(_Event, State) ->
	%io:format("mod_loverun_mgr clear:~p~n", [time()]),
    mod_loverun:account(),
    {ok, BinData} = pt_343:write(34300, [0]),
    lib_unite_send:send_to_all(34, 999, BinData),
	%计算休眠时间
    [{Year1, Month1, Day1}, {Year2, Month2, Day2}] = data_loverun_time:get_loverun_time(activity_date),
    case date() >= {Year1, Month1, Day1} andalso date() =< {Year2, Month2, Day2} of
        false -> {next_state, finished, #state{}, 60 * 1000};
        true ->
            {{_, _, _}, {Hour, Minute, _NowSec}} = calendar:local_time(),
            [[{Config_Begin_Hour1, Config_Begin_Minute1}, {Config_End_Hour1, Config_End_Minute1}], [{Config_Begin_Hour2, Config_Begin_Minute2}, {Config_End_Hour2, Config_End_Minute2}]] = data_loverun_time:get_loverun_time(activity_time),
            case (Config_End_Hour1 * 60 + Config_End_Minute1) - (Hour * 60 + Minute) =< 0 andalso (Config_End_Hour2 * 60 + Config_End_Minute2) - (Hour * 60 + Minute) > 0 of
                true ->
                    Config_Begin_Hour = Config_Begin_Hour2,
                    Config_Begin_Minute = Config_Begin_Minute2,
                    Config_End_Hour = Config_End_Hour2,
                    Config_End_Minute = Config_End_Minute2;
                false -> 
                    Config_Begin_Hour = Config_Begin_Hour1,
                    Config_Begin_Minute = Config_Begin_Minute1,
                    Config_End_Hour = Config_End_Hour1,
                    Config_End_Minute = Config_End_Minute1
            end,
            ApplyTime = data_loverun:get_loverun_config(apply_time),
            NewState = State#state{
                config_begin_hour = Config_Begin_Hour,
                config_begin_minute = Config_Begin_Minute,
                config_end_hour = Config_End_Hour,
                config_end_minute = Config_End_Minute,
                apply_time = ApplyTime},
            mod_loverun:set_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, ApplyTime),
            {next_state, no_open, NewState,?TIMEOUT_DEFAULT}
    end.

state_name(_Event, State) ->
    {next_state, state_name, State}.

state_name(_Event, _From, StateData) ->
    Reply = ok,
    {reply, Reply, state_name, StateData}.

handle_event({mt_start_link,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, ApplyTime}, _StateName, _StateData) ->
	%设置时间
	State = #state{
		   config_begin_hour=Config_Begin_Hour,
		   config_begin_minute=Config_Begin_Minute,
		   config_end_hour=Config_End_Hour,
		   config_end_minute=Config_End_Minute,
           apply_time = ApplyTime},
	mod_loverun:set_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, ApplyTime),
    {next_state, no_open, State,?TIMEOUT_DEFAULT};

handle_event(stop, _StateName, State) ->
    {stop, normal, State};

handle_event(_Event, StateName, StateData) ->
    {next_state, StateName, StateData}.

handle_sync_event(_Event, _From, StateName, StateData) ->
    Reply = ok,
    {reply, Reply, StateName, StateData}.

handle_info(_Info, StateName, StateData) ->
    {next_state, StateName, StateData}.

terminate(_Reason, _StateName, _StatData) ->
    ok.

code_change(_OldVsn, StateName, StateData, _Extra) ->
    {ok, StateName, StateData}.

init_set(Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute, ApplyTime)->
	%设置时间
	State = #state{
		   config_begin_hour = Config_Begin_Hour,
		   config_begin_minute = Config_Begin_Minute,
		   config_end_hour = Config_End_Hour,
		   config_end_minute = Config_End_Minute,
           apply_time = ApplyTime},
	mod_loverun:set_time(Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute, ApplyTime),
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60+Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
	if
		NowTime=<Config_Begin-> %未开始
			{ok, no_open, State,?TIMEOUT_DEFAULT};
		true-> %已结束
			{ok, finished, State,?TIMEOUT_DEFAULT}
	end.


