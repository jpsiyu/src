%%%------------------------------------
%%% @Module  : mod_dets
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2013.09.22
%%% @Description: dets模块封装
%%%------------------------------------
-module(mod_dets).
-behaviour(gen_server).
-export([
	start_link/0,
	stop/0,
	lookup/2,
	insert/2,
	delete/2,
	delete_all_objects/1,
	match_delete/2,
	update_counter/3
]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("server.hrl").

%% dets表初始化(表名称都要dets_开头)
-define(DETSLIST, [
	%% {表名, 主键, 表类型}
	{?DETS_PLAYER_STATUS, #player_status.id, set}
]).

start_link() ->
	F = fun(D) ->
		gen_server:start_link(?MODULE, [D], [])
	end,
	[ F(D) ||  D <- ?DETSLIST].

init([{Tab, Key, Type}]) ->
	process_flag(trap_exit, true),
	register_modele(Tab, self()),
	dets_open(Tab, Key, Type),
	{ok, Tab}.

stop() ->
	F = fun(Modele) ->
		gen_server:cast(get_pid(Modele), stop)
	end,
	[ F(Modele) ||  {Modele, _, _} <- ?DETSLIST].

insert(Tab, Data) ->
	gen_server:cast(get_pid(Tab), {insert, Tab, Data}).

delete(Tab, Key) ->
	gen_server:cast(get_pid(Tab), {delete, Tab, Key}).

delete_all_objects(Tab) ->
	gen_server:cast(get_pid(Tab), {delete_all_objects, Tab}).

match_delete(Tab, Pattern) ->
	gen_server:cast(get_pid(Tab), {match_delete, Tab, Pattern}).	

update_counter(Tab, Key, Increment) ->
	gen_server:cast(get_pid(Tab), {update_counter, Tab, Key, Increment}).

%% 查询
%% 返回 : [] | [Record, ...]
lookup(Tab, Key) ->
	gen_server:call(get_pid(Tab), {lookup, Tab, Key}).

%% stop
handle_cast(stop, Status) ->
	{stop, normal, Status};

handle_cast({insert, Tab, Data}, Status) ->
	case catch dets:insert(Tab, Data) of
		{'EXIT', R} ->
			util:errlog("mod_dets:~p", [R]);
		_ ->
			skip
	end,    
	{noreply, Status};

handle_cast({delete, Tab, Key}, Status) ->
	catch dets:delete(Tab, Key),
	{noreply, Status};

handle_cast({delete_all_objects, Tab}, Status) ->
	catch dets:delete_all_objects(Tab),
	{noreply, Status};

handle_cast({match_delete, Tab, Pattern}, Status) ->
	catch dets:match_delete(Tab, Pattern),
	{noreply, Status};

handle_cast({update_counter, Tab, Key, Increment}, Status) ->
	catch dets:update_counter(Tab, Key, Increment),
	{noreply, Status};

%% cast数据调用
handle_cast({Fun, Arg}, Status) ->
	apply(dets, Fun, Arg),
	{noreply, Status};

handle_cast(_R , Status) ->
	{noreply, Status}.

handle_call({lookup, Tab, Key} , _FROM, Status) ->
	Data = case catch dets:lookup(Tab, Key) of
		{'EXIT', R} ->
			util:errlog("mod_dets:~p", [R]),
			[];
		_Data ->
			_Data
	end,
	{reply, Data, Status};

handle_call(_R , _FROM, Status) ->
	{reply, ok, Status}.

handle_info(_Reason, Status) ->
	{noreply, Status}.

terminate(_Reason, Status) ->
	dets_close(Status),
	{ok, Status}.

code_change(_OldVsn, Status, _Extra)->
	{ok, Status}.

%% 创建或者打开dets
%% Tab表名，key主键（数字 | #xxx.id）, type：表类型(set, bag, duplicate_bag)
dets_open(Tab, Key, Type) ->
	Args = [{file, Tab}, {keypos, Key}, {type, Type}],
	case dets:open_file(Tab, Args) of
		{ok, _} ->
			true;
		Reason ->
			dets_close(Tab),
			util:errlog("Cannot open file: ~p, reason: ~p", [Tab, Reason]),
			false
	end.

dets_close(Tab) ->
	catch dets:close(Tab),
	ok.

get_pid(Tab) ->
	misc:get_global_pid(misc:dets_process_name(Tab)).

register_modele(Modele, Pid) ->
	DetsProcessName = misc:dets_process_name(Modele),
	misc:register(global, DetsProcessName, Pid),
	ok.
