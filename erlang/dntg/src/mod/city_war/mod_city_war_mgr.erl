%%%------------------------------------
%%% @Module  : mod_city_war_mgr
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.13
%%% @Description: 城战
%%%------------------------------------
-module(mod_city_war_mgr).
-behaviour(gen_fsm).
-export(
    [
        at_start_link/0,
        mt_start_link/8,
        stop/0
    ]
).
-export(
    [
        init/1, 
        state_name/2, 
        state_name/3, 
        handle_event/3,
        handle_sync_event/4, 
        handle_info/3, 
        terminate/3, 
        code_change/4
    ]
).
-compile(export_all).
-record(state, 
    {
        config_begin_hour = 0,
        config_begin_minute = 0,
        config_end_hour = 0,
        config_end_minute = 0,
        open_days = 0,
        seize_days = 0
    }
).

at_start_link() ->
    gen_fsm:start_link({global, ?MODULE}, ?MODULE, [], []).

%% 手动启动服务器
mt_start_link(ConfigBeginHour, ConfigBeginMinute, ConfigEndHour, ConfigEndMinute, EndSeizeHour, EndSeizeMinute, ApplyEndHour, ApplyEndMinute) ->
	gen_fsm:send_all_state_event({global, ?MODULE}, {mt_start_link, ConfigBeginHour, ConfigBeginMinute, ConfigEndHour, ConfigEndMinute, EndSeizeHour, EndSeizeMinute, ApplyEndHour, ApplyEndMinute}).

%% 关闭服务器时回调
stop() ->
    gen_fsm:send_event({global, ?MODULE}, stop).

init([]) ->
    spawn(fun() ->
                lib_city_war:min_cycle()
        end),
    [[ConfigBeginHour, ConfigBeginMinute], [ConfigEndHour, ConfigEndMinute]] = data_city_war:get_city_war_config(begin_end_time),
    [EndSeizeHour, EndSeizeMinute] = data_city_war:get_city_war_config(end_seize_time),
    [ApplyEndHour, ApplyEndMinute] = data_city_war:get_city_war_config(apply_end_time),
	%% 获取开启的时间
    OpenDays = data_city_war:get_city_war_config(open_days),
    SeizeDays = data_city_war:get_city_war_config(seize_days),
    mod_city_war:set_all_time([ConfigBeginHour, ConfigBeginMinute, ConfigEndHour, ConfigEndMinute, EndSeizeHour, EndSeizeMinute, ApplyEndHour, ApplyEndMinute, OpenDays, SeizeDays]),
    State = #state{},
    {ok, judge, State, 10}.

%% 流程判定
judge(_Event, _State) ->
%%    io:format("judge:~p~n", [time()]),
    %% 获取开启与结束时间
	[[ConfigBeginHour, ConfigBeginMinute], [ConfigEndHour, ConfigEndMinute]] = data_city_war:get_city_war_config(begin_end_time),
    [EndSeizeHour, EndSeizeMinute] = data_city_war:get_city_war_config(end_seize_time),
    [ApplyEndHour, ApplyEndMinute] = data_city_war:get_city_war_config(apply_end_time),
	%% 获取开启的时间
    OpenDays = data_city_war:get_city_war_config(open_days),
    SeizeDays = data_city_war:get_city_war_config(seize_days),
    %设置时间
	NewState = #state{
        config_begin_hour=ConfigBeginHour,
        config_begin_minute=ConfigBeginMinute,
        config_end_hour=ConfigEndHour,
        config_end_minute=ConfigEndMinute,
        open_days = OpenDays,
        seize_days = SeizeDays
    },
    NowDay = calendar:day_of_the_week(date()),
    %% 设置时间
    mod_city_war:set_all_time([ConfigBeginHour, ConfigBeginMinute, ConfigEndHour, ConfigEndMinute, EndSeizeHour, EndSeizeMinute, ApplyEndHour, ApplyEndMinute, OpenDays, SeizeDays]),
    %% 判断是否开启时间内
    case NowDay of
        %% 活动日，开始活动
        SeizeDays ->
            UnixSeizeTime = util:unixdate() + (SeizeDays - NowDay) * 24 * 3600 + EndSeizeHour * 3600 + EndSeizeMinute * 60,
            case util:unixtime() > UnixSeizeTime of
                %% 已过抢夺时间
                true ->
                    ConRes = mod_city_war:continue_city_war(),
                    case ConRes of
                        %% 获取信息成功，继续攻城战流程
                        1 ->
                            {_Hour, _Min, _Sec} = time(),
                            _SleepTime = 70 - _Sec,
                            SleepTime = case _SleepTime > 60 of
                                true -> _SleepTime - 60;
                                false -> _SleepTime
                            end,
                            {next_state, broadcast, NewState, SleepTime * 1000};
                        %% 失败，睡眠
                        _ ->
                            {next_state, sleep, NewState, 10}
                    end;
                %% 开始攻城战流程
                false ->
                    {next_state, start, NewState, 10}
            end;
        %% 非活动日，睡眠
        _ ->
            case NowDay of
                OpenDays ->
                    UnixEndTime = util:unixdate() + (OpenDays - NowDay) * 24 * 3600 + ConfigEndHour * 3600 + ConfigEndMinute * 60,
                    case util:unixtime() > UnixEndTime of
                        %% 已过活动时间
                        true ->
                            {next_state, sleep, NewState, 10};
                        false ->
                            ConRes = mod_city_war:continue_city_war(),
                            case ConRes of
                                %% 获取信息成功，继续攻城战流程
                                1 ->
                                    {_Hour, _Min, _Sec} = time(),
                                    _SleepTime = 70 - _Sec,
                                    SleepTime = case _SleepTime > 60 of
                                        true -> _SleepTime - 60;
                                        false -> _SleepTime
                                    end,
                                    {next_state, broadcast, NewState, SleepTime * 1000};
                                %% 失败，睡眠
                                _ ->
                                    {next_state, sleep, NewState, 10}
                            end
                    end;
                _ ->
                    {next_state, sleep, NewState, 10}
            end
    end.

%% 睡眠
sleep(_Event, State) ->
%%    io:format("sleep:~p~n", [time()]),
    %% 是否改开帮派战
    OpenDays = data_city_war:get_city_war_config(open_days),
    NowDay = calendar:day_of_the_week(date()),
    case NowDay of
        OpenDays ->
            UnixBeginTime = util:unixdate() + (State#state.open_days - NowDay) * 24 * 3600 + State#state.config_begin_hour * 3600 + State#state.config_begin_minute * 60,
            case util:unixtime() >= UnixBeginTime of
                true ->
                    skip;
                false ->
                    %io:format("factionwar:~p~n", [time()]),
                    spawn(fun() -> 
                                Title = data_city_war_text:get_city_war_text(28),
                                Content = data_city_war_text:get_city_war_text(29),
                                LevelLimit = data_city_war:get_city_war_config(min_lv),
                                lib_mail:send_sys_mail_to_all(Title, Content, 0, 0, 0, 0, 0, 0, 0, LevelLimit, 0)
                        end),
                    catch mod_factionwar_mgr:mt_start_link(20, 15, 15, 30, 125)
            end;
        _ ->
            skip
    end,
    SleepTime = (util:unixdate() + 24 * 60 * 60 - util:unixtime() + 12 * 60) * 1000,
    %SleepTime = 10 * 1000,
    {next_state, judge, State, SleepTime}.

%% 开始活动
start(_Event, State) ->
%%    io:format("start:~p~n", [time()]),
    ConfigEndHour = State#state.config_end_hour,
    ConfigEndMinute = State#state.config_end_minute,
    NowDay = calendar:day_of_the_week(date()),
    UnixEndTime = util:unixdate() + (State#state.open_days - NowDay) * 24 * 3600 + ConfigEndHour * 3600 + ConfigEndMinute * 60,
    %io:format("UnixEndTime:~p~n", [util:seconds_to_localtime(UnixEndTime)]),
    case util:unixtime() =< UnixEndTime of
        %% 活动未结束，初始化后进入广播
        true ->
            {next_state, init_all, State, 10};
        %% 活动已结束，进入休眠
        false ->
            {next_state, sleep, State, 10}
    end.

%% 数据初始化
init_all(_Event, State) ->
%%    io:format("init_all:~p~n", [time()]),
    mod_city_war:clear_all_out(),
    Res = mod_city_war:init_all(),
    {_Hour, _Min, _Sec} = time(),
    _SleepTime = 70 - _Sec,
    SleepTime = case _SleepTime > 60 of
        true -> _SleepTime - 60;
        false -> _SleepTime
    end,
    case Res of
        %% 初始化成功，开始广播
        1 -> {next_state, broadcast, State, SleepTime * 1000};
        %% 初始化失败，进入睡眠
        _ -> 
            {next_state, sleep, State, SleepTime * 1000}
    end.

%% 广播，每分钟广播一次
broadcast(_Event, State) ->
    ConfigBeginHour = State#state.config_begin_hour,
    ConfigBeginMinute = State#state.config_begin_minute,
    ConfigEndHour = State#state.config_end_hour,
    ConfigEndMinute = State#state.config_end_minute,
    NowDay = calendar:day_of_the_week(date()),
    UnixBeginTime = util:unixdate() + (State#state.open_days - NowDay) * 24 * 3600 + ConfigBeginHour * 3600 + ConfigBeginMinute * 60,
    UnixEndTime = util:unixdate() + (State#state.open_days - NowDay) * 24 * 3600 + ConfigEndHour * 3600 + ConfigEndMinute * 60,
    %io:format("UnixBeginTime:~p~n", [util:seconds_to_localtime(UnixBeginTime)]),
    %io:format("UnixEndTime:~p~n", [util:seconds_to_localtime(UnixEndTime)]),
    %EndTime = util:seconds_to_localtime(UnixTime),
    {_Hour, _Min, _Sec} = time(),
    case util:unixtime() < UnixEndTime of
        %% 活动未结束，进入广播
        true ->
            case util:unixtime() =< UnixBeginTime of
                %% 活动未开始
                true ->
%%                    io:format("broadcast1:~p~n", [time()]),
                    mod_city_war:before_broadcast(),
                    %% 开始前1分钟初始化怪物
                    Time1 = ConfigBeginHour* 60 + ConfigBeginMinute - 1,
                    THour = Time1 div 60,
                    TMin = Time1 - Time1 div 60 * 60,
                    case {_Hour, _Min} =:= {THour, TMin} andalso NowDay =:= State#state.open_days of
                        true ->
                            mod_city_war:init_mon();
                        false ->
                            skip
                    end,
                    Time2 = ConfigBeginHour* 60 + ConfigBeginMinute - 20,
                    THour2 = Time2 div 60,
                    TMin2 = Time2 - Time2 div 60 * 60,
                    case {_Hour, _Min} =:= {THour2, TMin2} andalso NowDay =:= State#state.open_days of
                        true ->
                            ok;
                        false ->
                            skip
                    end;
                %% 活动已开始
                false ->
%%                    io:format("broadcast2:~p~n", [time()]),
                    mod_city_war:after_broadcast()
            end,
            _SleepTime = 70 - _Sec,
            SleepTime = case _SleepTime > 60 of
                true -> _SleepTime - 60;
                false -> _SleepTime
            end,
            {next_state, broadcast, State, SleepTime * 1000};
        %% 活动已结束，进入休眠
        false ->
            %% 清算操作
            mod_city_war:clear_all_out(),
            mod_city_war:account(),
            mod_city_war:end_deal(1),
            {next_state, sleep, State, 10}
    end.

state_name(_Event, State) ->
    {next_state, state_name, State}.

state_name(_Event, _From, StateData) ->
    Reply = ok,
    {reply, Reply, state_name, StateData}.

%% 手动开启
handle_event({mt_start_link, ConfigBeginHour, ConfigBeginMinute, ConfigEndHour, ConfigEndMinute, EndSeizeHour, EndSeizeMinute, ApplyEndHour, ApplyEndMinute}, _StateName, _StateData) ->
    %% 设置时间
    NowDay = calendar:day_of_the_week(date()),
    %设置时间
	State = #state{
        config_begin_hour = ConfigBeginHour,
        config_begin_minute = ConfigBeginMinute,
        config_end_hour = ConfigEndHour,
        config_end_minute = ConfigEndMinute,
        open_days = NowDay,
        seize_days = NowDay
    },
    mod_city_war:set_all_time([ConfigBeginHour, ConfigBeginMinute, ConfigEndHour, ConfigEndMinute, EndSeizeHour, EndSeizeMinute, ApplyEndHour, ApplyEndMinute, NowDay, NowDay]),
    {next_state, start, State, 10};

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
