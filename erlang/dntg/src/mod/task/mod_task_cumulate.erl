%%%------------------------------------
%%% @Module  : mod_task_cumulate
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.7.31
%%% @Description: 功能累积(离线经验累积)
%%%------------------------------------


-module(mod_task_cumulate).
-behaviour(gen_server).
-include("task.hrl").
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% 插入操作
insert_task(TaskCumulate) -> 
	gen_server:cast(misc:get_global_pid(?MODULE), {insert_task, TaskCumulate}).

%% 查询操作
lookup_task(RoleId, TaskId) -> 
	gen_server:call(misc:get_global_pid(?MODULE), {lookup_task, RoleId, TaskId}).

%% 根据玩家ID查询
lookup_all_task(RoleId) ->
    gen_server:call(misc:get_global_pid(?MODULE), {lookup_all_task, RoleId}).

start_link() ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    {ok, 0}.

%% call
handle_call({lookup_task, RoleId, TaskId}, _From, State) ->
    Rep = get({task_cumulate, {RoleId, TaskId}}),
	{reply, Rep, State};

handle_call({lookup_all_task, RoleId}, _From, State) ->
    Rep = list_deal1(get(), [], RoleId),
	{reply, Rep, State};

handle_call(Event, _From, Status) ->
    catch util:errlog("mod_task_cumulate:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.

%% cast
handle_cast({insert_task, TaskCumulate}, Status) ->
	put({task_cumulate, TaskCumulate#task_cumulate.id}, TaskCumulate),
	{noreply, Status};

handle_cast(Msg, Status) ->
    catch util:errlog("mod_task_cumulate:handle_cast not match: ~p", [Msg]),
    {noreply, Status}.

%% info
handle_info(Info, Status) ->
    catch util:errlog("mod_task_cumulate:handle_info not match: ~p", [Info]),
    {noreply, Status}.

%% terminate
terminate(_Reason, _Status) ->
    %catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

%% code_change
code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

%% 根据玩家ID返回
list_deal1([], L2, _PlayerId) -> L2;
list_deal1([H | T], L2, PlayerId) ->
    case H of
        {{task_cumulate, {RoleId, _TaskId}}, TaskCumulate} -> 
            case RoleId =:= PlayerId andalso TaskCumulate#task_cumulate.cucm_exp > 0 andalso TaskCumulate#task_cumulate.offline_day > 0 of
                true -> list_deal1(T, [TaskCumulate | L2], PlayerId);
                false -> list_deal1(T, L2, PlayerId)
            end;
        _ -> list_deal1(T, L2, PlayerId)
    end.


