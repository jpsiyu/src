%%%------------------------------------
%%% @Module  : mod_fcm
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.28
%%% @Description: 用进程字典存储防沉迷信息
%%%------------------------------------

-module(mod_fcm).
-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% 根据玩家Id，返回{LastLoginTime, OnLineTime, OffLineTime, State}
get_by_id(Id) ->
	gen_server:call(?MODULE, {get_by_id, Id}).

get_all() ->
	gen_server:call(?MODULE, get_all).

%% 插入操作
insert(Id, LastLoginTime, OnLineTime, OffLineTime, State, Write, Name, IdCardNo) -> 
	gen_server:cast(?MODULE, {insert, Id, LastLoginTime, OnLineTime, OffLineTime, State, Write, Name, IdCardNo}).

%% 根据用户Id删除
delete(Id) ->
	gen_server:cast(?MODULE, {delete, Id}).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    {ok, 0}.

%% handle_call信息处理
handle_call(Event, From, Status) ->
    mod_fcm_call:handle_call(Event, From, Status).

%% handle_cast信息处理
handle_cast(Event, Status) ->
    mod_fcm_cast:handle_cast(Event, Status).

%% handle_info信息处理
handle_info(Info, Status) ->
    mod_fcm_info:handle_info(Info, Status).

terminate(_Reason, _Status) ->
    %catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.




