%%%------------------------------------
%%% @Module  : mod_exit
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.7.17
%%% @Description: 用进程字典存储玩家进入副本前的场景和坐标
%%%------------------------------------


-module(mod_exit).
-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% 记录用户上次的场景与坐标
insert_last_xy(Id, SceneId, X, Y) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {insert_last_xy, Id, SceneId, X, Y}).

%% 获取用户上次的场景与坐标
lookup_last_xy(Id) ->
	gen_server:call(misc:get_global_pid(?MODULE), {lookup_last_xy, Id}).

%% 好友回赠防止重复回赠
insert_bless_gift(Id, Lv, Id2) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {insert_bless_gift, Id, Lv, Id2}).
insert_send_gift(Id, Lv, Id2) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {insert_send_gift, Id, Lv, Id2}).
%% 好友回赠防止重复回赠
lookup_bless_gift(Id, Lv, Id2) ->
    gen_server:call(misc:get_global_pid(?MODULE), {lookup_bless_gift, Id, Lv, Id2}).
lookup_send_gift(Id, Lv, Id2) ->
    gen_server:call(misc:get_global_pid(?MODULE), {lookup_send_gift, Id, Lv, Id2}).
%% 记录某活动曾经开启的最大房间数量
insert_max_room(Type, MaxRoom) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {insert_max_room, Type, MaxRoom}).

%% 记录某活动曾经开启的最大房间数量
lookup_max_room(Type) ->
    gen_server:call(misc:get_global_pid(?MODULE), {lookup_max_room, Type}).

start_link() ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    {ok, 0}.

handle_call({lookup_last_xy, Id}, _From, State) ->
    Rep = get({last_xy, Id}),
	{reply, Rep, State};

handle_call({lookup_bless_gift, Id, Lv, Id2}, _From, State) ->
    Rep = get({bless_gift, Id, Lv, Id2}),
	{reply, Rep, State};

handle_call({lookup_send_gift, Id, Lv, Id2}, _From, State) ->
    Rep = get({send_gift, Id, Lv, Id2}),
    {reply, Rep, State};

handle_call({lookup_max_room, Type}, _From, State) ->
    Rep = case get({max_room, Type}) of
        undefined -> 
            put({max_room, Type}, 0),
            0;
        Num ->
            Num
    end,
	{reply, Rep, State};

handle_call(Event, _From, Status) ->
    catch util:errlog("mod_exit:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.


handle_cast({insert_last_xy, Id, SceneId, X, Y}, Status) ->
	put({last_xy, Id}, [SceneId, X, Y]),
	{noreply, Status};

handle_cast({insert_bless_gift, Id, Lv, Id2}, Status) ->
	put({bless_gift, Id, Lv, Id2}, 1),
	{noreply, Status};

handle_cast({insert_send_gift, Id, Lv, Id2}, Status) ->
    put({send_gift, Id, Lv, Id2}, 1),
    {noreply, Status};

handle_cast({insert_max_room, Type, MaxRoom}, Status) ->
	put({max_room, Type}, MaxRoom),
	{noreply, Status};

handle_cast(Msg, Status) ->
    catch util:errlog("mod_exit:handle_cast not match: ~p", [Msg]),
    {noreply, Status}.

handle_info(Info, Status) ->
    catch util:errlog("mod_exit:handle_info not match: ~p", [Info]),
    {noreply, Status}.

terminate(_Reason, _Status) ->
    %catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.




