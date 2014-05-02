%%%--------------------------------------
%%% @Module  : mod_achieve
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.9
%%% @Description: 成就服务
%%%--------------------------------------

-module(mod_achieve).
-behaviour(gen_server).
-include("server.hrl").
-export([
	start_link/1,
	online/1,
	offline/2,
	trigger_task/5,
	trigger_equip/5,
	trigger_role/5,
	trigger_trial/5,
	trigger_social/5,
	trigger_hidden/5,
	get_index_data/2,
	fetch_award_by_type/2,
	fetch_achieve_award/3,
	compare_data/3
]).
-export([
	init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3
]).

%% 玩家游戏线上线开启进程
start_link(RoleId) ->
	gen_server:start_link(?MODULE, [RoleId], []).

%% 上线操作
online(RoleId) ->
	lib_achieve_new:online(RoleId).

%% 下线操作
offline(Pid, RoleId) ->
    gen_server:cast(Pid, {offline, [RoleId]}).

%% 触发:任务成就
trigger_task(Pid, RoleId, TypeId, ActionId, ActionNum) ->
	gen_server:cast(Pid, {trigger_task, [RoleId, TypeId, ActionId, ActionNum]}).

%% 触发:神装成就
trigger_equip(Pid, RoleId, TypeId, ActionId, ActionNum) ->
	gen_server:cast(Pid, {trigger_equip, [RoleId, TypeId, ActionId, ActionNum]}).

%% 触发:角色成就
trigger_role(Pid, RoleId, TypeId, ActionId, ActionNum) ->
	gen_server:cast(Pid, {trigger_role, [RoleId, TypeId, ActionId, ActionNum]}).

%% 触发:试炼成就
trigger_trial(Pid, RoleId, TypeId, ActionId, ActionNum) ->
	gen_server:cast(Pid, {trigger_trial, [RoleId, TypeId, ActionId, ActionNum]}).

%% 触发:社会成就
trigger_social(Pid, RoleId, TypeId, ActionId, ActionNum) ->
	gen_server:cast(Pid, {trigger_social, [RoleId, TypeId, ActionId, ActionNum]}).

%% 触发:隐藏成就
trigger_hidden(Pid, RoleId, TypeId, ActionId, ActionNum) ->
	gen_server:cast(Pid, {trigger_hidden, [RoleId, TypeId, ActionId, ActionNum]}).

%% 获取成就面板数据
get_index_data(Pid, RoleId) ->
	gen_server:call(Pid, {get_index_data, [RoleId]}).

%% 获取大类成长等级奖励
fetch_award_by_type(PS, AchieveType) ->
	gen_server:call(PS#player_status.achieve, {fetch_award_by_type, [PS, AchieveType]}).

%% 领取成就奖励
fetch_achieve_award(Pid, RoleId, AchieveId) ->
	gen_server:call(Pid, {fetch_achieve_award, [RoleId, AchieveId]}).

%% 跟其他玩家对比成就数据
compare_data(Pid, RoleId, PlayerId) ->
	gen_server:call(Pid, {compare_data, [RoleId, PlayerId]}).


init([RoleId]) ->
    {ok, 	#status_achieve{id = RoleId}}.

handle_cast({Fun, Arg}, Status) ->
    apply(lib_achieve_new, Fun, Arg),
    {noreply, Status};

handle_cast(_R , Status) ->
    {noreply, Status}.

handle_call({Fun, Arg} , _FROM, Status) ->
    {reply, apply(lib_achieve_new, Fun, Arg), Status};

handle_call(_R , _FROM, Status) ->
    {reply, ok, Status}.

handle_info(_Reason, Status) ->
    {noreply, Status}.

terminate(_Reason, Status) ->
    {ok, Status}.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.
