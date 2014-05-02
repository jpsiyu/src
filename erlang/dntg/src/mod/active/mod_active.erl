%%%--------------------------------------
%%% @Module  : mod_active
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.11.20
%%% @Description: 活跃度
%%%--------------------------------------

-module(mod_active).
-behaviour(gen_server).
-include("server.hrl").
-include("active.hrl").
-export([
	online/1,
	get_my_active/1,
    get_my_allactive/1,
	get_info/2,
	fetch_award/2,
	trigger/4,
    cost/2,
	check_finish/3
]).
-export([
	init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3
]).

%% 上线操作，开启一个玩家进程
online(RoleId) ->
	{ok, Pid} = gen_server:start_link(?MODULE, [RoleId], []),
	Pid.

%% 获取玩家当天的活跃度
get_my_active(Pid) ->
	gen_server:call(Pid, {get_my_active}).

%% 获取玩家全部的活跃度
get_my_allactive(Pid) ->
    gen_server:call(Pid, {get_my_allactive}).

%% 打开活跃度面板需要的数据
get_info(Pid, PS) ->
	gen_server:call(Pid, {get_info, PS}).

%% 打开活跃度面板需要的数据
fetch_award(Pid, PS) ->
	gen_server:call(Pid, {fetch_award, PS}).

%% 打开活跃度面板需要的数据
check_finish(Pid, Type, Num) ->
	gen_server:cast(Pid, {check_finish, Type, Num}).

%% 触发活跃度
trigger(Pid, Type, TargetId, VipType) ->
	gen_server:cast(Pid, {trigger, Type, TargetId, VipType}).

%%消费活跃度
cost(Pid,ActiveCount) ->
  gen_server:call(Pid, {cost,ActiveCount}).


    


init([RoleId]) ->
	[Today, Active, AllActive, Opt, Award] = lib_active:online(RoleId),
	State = #active{
		id = RoleId,
		today = Today,
		active = Active,
        allactive = AllActive,
		opt = Opt,
		award = Award
	},
	{ok, State}.

handle_cast(Msg, State) ->
    mod_active_cast:handle_cast(Msg, State).

handle_call(Request, FROM, Status) ->
    mod_active_call:handle_call(Request, FROM, Status).

handle_info(_Reason, Status) ->
    {noreply, Status}.

terminate(_Reason, Status) ->
    {ok, Status}.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.
