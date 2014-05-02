%%%------------------------------------
%%% @Module  : mod_revive
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.11.09
%%% @Description: 世界BOSS复活规则
%%%------------------------------------


-module(mod_revive).
-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([
		set_role/2, 
		get_role/1,
        set_last_die_time/1
	]).
-compile(export_all).
-include("server.hrl").
-include("common.hrl").

%% 插入操作
set_role(PlayerId, Dict) -> 
	gen_server:cast(misc:get_global_pid(?MODULE), {set_role, PlayerId, Dict}).

%% 查询操作
get_role(PlayerId) -> 
	gen_server:call(misc:get_global_pid(?MODULE), {get_role, PlayerId}).

%% 记录最近死亡时间
set_last_die_time(Status) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {set_last_die_time, Status}).

start_link() ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    {ok, dict:new()}.

%% 查询操作
handle_call({get_role, PlayerId}, _From, State) ->
    case dict:find(PlayerId, State) of
        {ok, Dict} ->
            Reply = Dict,
            NewState = State;
        _ ->
            Reply = dict:new(),
            NewState = dict:store(PlayerId, Reply, State)
    end,
    {reply, Reply, NewState};

handle_call(Event, _From, Status) ->
    catch util:errlog("mod_revive:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.

%% 插入操作
handle_cast({set_role, PlayerId, Dict}, State) ->
    NewState = dict:store(PlayerId, Dict, State),
	{noreply, NewState};

%% 记录最近死亡时间
handle_cast({set_last_die_time, Status}, State) ->
    case dict:find(Status#player_status.id, State) of
        {ok, Dict} ->
            case dict:find(Status#player_status.scene, Dict) of
                {ok, Info} ->
                    {LastTime, Num, _LastDieTime} = Info;
                _ ->
                    LastTime = util:unixtime(),
                    Num = 0
            end;
        _ ->
            LastTime = util:unixtime(),
            Num = 0,
            Dict = dict:new()
    end,
    NewDict  = dict:store(Status#player_status.scene, {LastTime, Num, util:unixtime()}, Dict),
    NewState = dict:store(Status#player_status.id, NewDict, State),
    %% 冷却时间和清除时间
    _Time = util:unixtime() - LastTime,
    Time = if 
        _Time > 60 -> 0;
        true -> 60
    end,
    MiddleTime = if
        Num >= 30 -> 12;
        Num >= 15 -> 8;
        Num >= 5 -> 5;
        true -> 0
    end,
    %io:format("Num:~p, Time:~p, MiddleTime:~p~n", [Num, Time, MiddleTime]),
    case MiddleTime > 0 andalso Time > 0 of
        false -> 
            skip;
        true ->
            {ok, BinData} = pt_200:write(20011, [MiddleTime, Time]),
            lib_unite_send:send_to_uid(Status#player_status.id, BinData)
    end,
	{noreply, NewState};

handle_cast(Msg, State) ->
    catch util:errlog("mod_revive:handle_cast not match: ~p", [Msg]),
    {noreply, State}.

handle_info(Info, State) ->
    catch util:errlog("mod_revive:handle_info not match: ~p", [Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    %catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, State, _Extra)->
    {ok, State}.



