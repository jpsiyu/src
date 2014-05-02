%%%------------------------------------
%%% @Module     : mod_online
%%% @Author     : huangyongxing
%%% @Email      : huangyongxing@yeah.net
%%% @Created    : 2010.10.28
%%% @Description: 在线人数统计服务
%%%------------------------------------
-module(mod_online).
-behaviour(gen_fsm).
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3, code_change/4, terminate/3]).
-export(
    [
        start_link/0,
        log_online/0,
        stop_log/0,
        handle/2
    ]).
-include("common.hrl").
-include("record.hrl").

-define(LOG_INTERVAL,   10000).                 %% 统计时间间隔1分钟
-define(MAX_TURN,       6).                     %% 统计多少轮写一次数据库

-record(state, {
        pid = null,
        num = 1,
        turn = 0
    }).

%%%------------------------------------
%%%             接口函数
%%%------------------------------------

%% 启动服务
start_link() ->
    gen_fsm:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 统计在线人数
log_online() ->
    gen_fsm:send_event(?MODULE, 'log_online').

%% 停止统计
stop_log() ->
    gen_fsm:send_event(?MODULE, 'stop_log').

loop_server() ->
    receive
        'log_online' ->
            catch lib_online:log_online(0),
            loop_server();
        {'log_online', Turn} ->
            catch lib_online:log_online(Turn),
            loop_server();
        _ ->
            loop_server()
    end.

%%%------------------------------------
%%%             回调函数
%%%------------------------------------

init(_) ->
    process_flag(trap_exit, true),
    Pid   = spawn(fun loop_server/0),
    StateData = #state{pid = Pid, num = 1},
    {ok, handle, StateData, ?LOG_INTERVAL}.

handle(timeout, StateData) ->
    Pid  = StateData#state.pid,
    Turn = StateData#state.turn,
    case is_process_alive(Pid) of
        true ->
            NewPid = Pid;
        false ->
            NewPid = spawn(fun loop_server/0)
    end,
    NewTurn = case Turn >= ?MAX_TURN of
        true  -> 0;
        false -> Turn + 1
    end,
    NewPid ! {'log_online', NewTurn},
    NewStateData = StateData#state{pid = NewPid, turn = NewTurn},
    {next_state, handle, NewStateData, ?LOG_INTERVAL};

%% 开始统计
handle('log_online', StateData) ->
    Pid = StateData#state.pid,
    case is_process_alive(Pid) of
        true ->
            NewPid = Pid;
        false ->
            NewPid = spawn(fun loop_server/0)
    end,
    NewPid ! 'log_online',
    NewStateData = #state{pid = NewPid, num = 1},
    {next_state, handle, NewStateData, ?LOG_INTERVAL};

%% 停止统计
handle(_, StateData) ->
    {next_state, handle, StateData}.

handle_event(_Event, _StateName, StateData) ->
    {next_state, handle, StateData}.

handle_sync_event(_Event, _From, _StateName, StateData) ->
    {next_state, handle, StateData}.

code_change(_OldVsn, _StateName, State, _Extra) ->
    {ok, handle, State}.

handle_info(_Any, _StateName, State) ->
    {next_state, handle, State}.

terminate(_Any, _StateName, _Opts) ->
    ok.
