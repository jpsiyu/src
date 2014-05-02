%%%--------------------------------------
%%% @Module  : mod_target
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.5
%%% @Description: 游戏目标服务
%%%--------------------------------------

-module(mod_target).
-behaviour(gen_server).
-include("server.hrl").
-export([online/1, offline/2, get_all/2, trigger/4, fetch_gift_award/3, fetch_level_award/3, check_level_award/3, trigger_on_manager/3]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% 上线操作，开启一个玩家进程
online(RoleId) ->
	gen_server:start_link(?MODULE, [RoleId], []).

%% 下线操作
offline(Pid, RoleId) ->
    gen_server:cast(Pid, {offline, [RoleId]}).

%% 获取所有完成的目标数据
get_all(Pid, RoleId) ->
	gen_server:call(Pid, {get_all, [RoleId]}).

%% 触发目标
trigger(Pid, RoleId, TargetId, TargetData) ->
	case is_pid(Pid) of
		true ->
    			gen_server:cast(Pid, {trigger, [RoleId, TargetId, TargetData]});
		_ ->
			lib_target:trigger_offline(RoleId, TargetId)
	end.

%% 管理后台调用触发达成目标
trigger_on_manager(RoleId, TargetId, TargetData) ->
	case misc:get_player_process(RoleId) of
		Pid when is_pid(Pid) ->
			case lib_player:get_player_info(RoleId, status_target) of
				StatusTarget when is_pid(StatusTarget) ->
					gen_server:cast(StatusTarget, {trigger, [RoleId, TargetId, TargetData]});
			    	_ ->
					lib_target:trigger_offline(RoleId, TargetId)
			end;
		_ ->
			lib_target:trigger_offline(RoleId, TargetId)
	end.

%% 领取礼包
fetch_gift_award(Pid, PS, TargetId) ->
	gen_server:call(Pid, {fetch_gift_award, [PS, TargetId]}).

%% 领取指定等级礼包奖励
fetch_level_award(Pid, PS, GiftId) ->
	gen_server:call(Pid, {fetch_level_award, [PS, GiftId]}).

%% 检查达到指定等级后弹出来的小窗奖励是否可以领取
check_level_award(Pid, PS, GiftId) ->
	gen_server:call(Pid, {check_level_award, [PS, GiftId]}).

init([RoleId]) ->
	lib_target:online(RoleId),
	{ok, #status_target{id = RoleId}}.

%% cast数据调用
handle_cast({Fun, Arg}, Status) ->
    apply(lib_target, Fun, Arg),
    {noreply, Status};

handle_cast(_R , Status) ->
    {noreply, Status}.

%% call数据调用
handle_call({Fun, Arg} , _FROM, Status) ->
    {reply, apply(lib_target, Fun, Arg), Status};

handle_call(_R , _FROM, Status) ->
    {reply, ok, Status}.

handle_info(_Reason, Status) ->
    {noreply, Status}.

terminate(_Reason, Status) ->
    {ok, Status}.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.
