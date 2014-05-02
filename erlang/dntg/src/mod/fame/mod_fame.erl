%%%--------------------------------------
%%% @Module  : mod_fame
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.12
%%% @Description: 名人堂服务
%%%--------------------------------------

-module(mod_fame).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% 触发：普通单人荣誉
%% MergeTime : 合服时间，如果大于0表示已经合服，原有名人堂接口不用再触发，会走合服名人堂触发接口
trigger(MergeTime, RoleId, FameType, ActionId, ActionValue) ->
	case MergeTime > 0 of
		%% 合服后触发
		true ->
%% 			case lib_fame_merge:get_fame_version() of
%% 				%% 合服了，但旧名人堂数据被清了，需要重新触发
%% 				1 ->
%% 					gen_server:cast(misc:get_global_pid(?MODULE), {trigger, [RoleId, FameType, ActionId, ActionValue]});
%% 				_ ->
%% 					skip
%% 			end,

			%% 合服了，触发新的名人堂
			gen_server:cast(misc:get_global_pid(?MODULE), {merge_trigger, [RoleId, FameType, ActionId, ActionValue]});

		%% 非合服触发普通名人堂
		_ ->
			gen_server:cast(misc:get_global_pid(?MODULE), {trigger, [RoleId, FameType, ActionId, ActionValue]})
	end.

%% 触发：第一个击杀指定副本BOSS
%% 这类荣誉比较特殊，由多人组队击杀boss从而达成，多个玩家可同时达成荣誉
%% MergeTime : 合服时间，如果大于0表示已经合服，原有名人堂接口不用再触发，会走合服名人堂触发接口
trigger_copy(MergeTime, Type, BossId, PlayerList) ->
	case MergeTime > 0 of
		%% 合服后触发
		true ->
%% 			case lib_fame_merge:get_fame_version() of
%% 				%% 合服了，但旧名人堂数据被清了，需要重新触发
%% 				1 ->
%% 					gen_server:cast(misc:get_global_pid(?MODULE), {trigger_copy, [Type, BossId, PlayerList]});
%% 				_ ->
%% 					skip
%% 			end,
			%% 合服了，触发新的名人堂
			gen_server:cast(misc:get_global_pid(?MODULE), {merge_trigger_copy, [Type, PlayerList]});

		%% 非合服触发普通名人堂
		_ ->
			gen_server:cast(misc:get_global_pid(?MODULE), {trigger_copy, [Type, BossId, PlayerList]})
	end.

%% 取消触发
remove_trigger(FameId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {remove_trigger, [FameId]}).

%% 重载数据
reload_data() ->
	gen_server:cast(misc:get_global_pid(?MODULE), {reload_data, []}).

start_link() ->
    gen_server:start_link({global,?MODULE}, ?MODULE, [], []).

init([]) ->
	%% 将数据表中的荣誉插入ets表
	lib_fame:server_start(),
    {ok, ?MODULE}.

handle_cast({Fun, Arg}, Status) ->
    apply(lib_fame, Fun, Arg),
    {noreply, Status};

handle_cast(_R , Status) ->
    {noreply, Status}.

handle_call({Fun, Arg} , _FROM, Status) ->
    {reply, apply(lib_fame, Fun, Arg), Status};

handle_call(_R , _FROM, Status) ->
    {reply, ok, Status}.

handle_info(_Reason, Status) ->
    {noreply, Status}.

terminate(_Reason, Status) ->
    {ok, Status}.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.
