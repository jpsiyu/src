%%%--------------------------------------
%%% @Module  : timer_unite_pay
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.12.29
%%% @Description: 订单处理
%%%--------------------------------------

-module(timer_unite_pay).
-behaviour(gen_fsm).
-export([start_link/0, waiting/2, working/2]).
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).
%% 隔一分钟扫描订单
-define(SCAN_ORDER_TIME, 60).

start_link() ->
    gen_fsm:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
	State = [],
	{ok, waiting, State, 0}.

%% 休眠状态
waiting(_Event, State) ->
	{next_state, working, State, ?SCAN_ORDER_TIME * 1000}.

%% 工作状态
working(_Event, State) ->
	spawn(fun() ->
		%% 处理所有订单
		private_handle_all_orders()
	end),

	{next_state, waiting, State, 0}.

handle_event(_Event, StateName, State) ->
    {next_state, StateName, State}.

handle_sync_event(_Event, _From, StateName, State) ->
    Reply = ok,
    {reply, Reply, StateName, State}.

handle_info(_Info, StateName, State) ->
    {next_state, StateName, State}.

terminate(_Reason, _StateName, _State) ->
    ok.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.

%% 扫描所有订单
private_handle_all_orders() ->
	case lib_recharge:get_recharge() of
        [] ->
			skip;
		List when is_list(List) -> 
			F = fun([_, RoleId, _], RoleList) ->
				case lists:member(RoleId, RoleList) of
					true ->
						RoleList;
					_ ->
						[RoleId | RoleList]
				end
			end,
			NewRoleList = lists:foldl(F, [], List),
			[private_handle_player_order(ActionRoleId) || ActionRoleId <- NewRoleList];
        _ -> 
			skip
    end.

%% 处理每个玩家订单
%% 玩家在线：发到该玩家进程，让玩家再从充值表拿出来处理
private_handle_player_order(RoleId) ->
	case misc:get_player_process(RoleId) of
		Pid when is_pid(Pid) ->
			{ok, BinData} = pt_130:write(13050, 1),
			lib_unite_send:send_to_uid(RoleId, BinData);
		_ -> 
			skip
    end.
