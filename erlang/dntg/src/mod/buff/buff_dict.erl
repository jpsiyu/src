%%%------------------------------------
%%% @Module  : buff_dict
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.27
%%% @Description: 用进程字典存储玩家BUFF(游戏线中)
%%%------------------------------------

-module(buff_dict).
-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% 全部buff，返回List
get_all() ->
	gen_server:call(misc:get_global_pid(?MODULE), get_all).

%% 根据主键Id删除
delete_id(Id) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {delete_id, Id}).

%% 插入操作
insert_buff(EtsBuff) -> 
	gen_server:cast(misc:get_global_pid(?MODULE), {insert_buff, EtsBuff}).

%% 匹配操作(1个参数)
match_one(Pid) ->
	gen_server:call(misc:get_global_pid(?MODULE), {match_one, Pid}).

%% 匹配操作(2个参数)
match_two(Pid, Type) ->
	gen_server:call(misc:get_global_pid(?MODULE), {match_two, Pid, Type}).

%% 匹配操作(2个参数)
match_two2(Pid, AttributeId) ->
	gen_server:call(misc:get_global_pid(?MODULE), {match_two2, Pid, AttributeId}).

%% 匹配操作(3个参数)
match_three(Pid, Type, AttributeId) ->
	gen_server:call(misc:get_global_pid(?MODULE), {match_three, Pid, Type, AttributeId}).

%% 查询操作
lookup_id(Id) -> 
	gen_server:call(misc:get_global_pid(?MODULE), {lookup_id, Id}).

%% 根据用户Id删除
match_delete(Pid) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {match_delete, Pid}).

start_link() ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    {ok, 0}.

%% handle_call信息处理
handle_call(Event, From, Status) ->
    buff_dict_call:handle_call(Event, From, Status).

%% handle_cast信息处理
handle_cast(Event, Status) ->
    buff_dict_cast:handle_cast(Event, Status).

%% handle_info信息处理
handle_info(Info, Status) ->
    buff_dict_info:handle_info(Info, Status).

terminate(_Reason, _Status) ->
    %catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.



