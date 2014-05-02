%%%-------------------------------------------------------------------
%%% @Module	: qixi
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 21 Aug 2012
%%% @Description: 七夕活动
%%%-------------------------------------------------------------------
-module(mod_qixi).
-compile(export_all).
-include("qixi.hrl").
%% @return:所有任务的完成情况表，#est_qixi_activity{}
lookup_player_task(Id) ->
    gen_server:call(misc:get_global_pid(?MODULE), {lookup_player_task, Id}).
%% @return:某个任务的完成次数
lookup_player_task_by_type(Id, Type) ->
    gen_server:call(misc:get_global_pid(?MODULE), {lookup_player_task_by_type, Id, Type}).
%% Activity:#est_qixi_activity{}
insert_player_task(Id, Activity) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {insert_player_task, Id, Activity}).
%% 更新任务完成情况
update_player_task(Id, Type, Num) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {update_player_task, Id, Type, Num}).
%% 更新任务完成情况
update_player_task_batch(Id, TypeList, Num) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {update_player_task_batch, Id, TypeList, Num}).
%% 玩家登录时更新任务完成情况
update_player_task_from_login(Id, Type, Num) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {update_player_task_from_login, Id, Type, Num}).
%% 清空所有玩家完成情况
reset_player_task() ->
    gen_server:cast(misc:get_global_pid(?MODULE), {reset_player_task}).
%% 检查是否领取奖励
check_get_by_type(Id, Type) ->
    gen_server:call(misc:get_global_pid(?MODULE), {check_get_by_type, Id, Type}).
%% 更新领取奖励状态
update_get_by_type(Id, Type, DailyPid) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {update_get_by_type, Id, Type, DailyPid}).
on_time_refresh() ->
    gen_server:cast(misc:get_global_pid(?MODULE), {on_time_refresh}).
get_mlpt_player() ->
    gen_server:call(misc:get_global_pid(?MODULE), {get_mlpt_player}).   
%% ------------------------------------------------------------------------------
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).
init([]) ->
    process_flag(trap_exit, true),
    spawn(fun() -> on_timer() end),
    {ok, 0}.
%% ----------------------------------------------------------------------------------
%% call
handle_call(Req, From, Status) ->
    case catch mod_qixi_call:handle_call(Req, From, Status) of
	{reply, Reply, NewStatus} ->
	    {reply, Reply, NewStatus};	    
	Reason ->
	    util:errlog("mod_qixi_call error: Req:~p, Reason:~p~n",[Req, Reason]),
	    {reply, error, Status}
    end.
%% ----------------------------------------------------------------------------------------
%% cast
handle_cast(Req, Status) ->
    case catch mod_qixi_cast:handle_cast(Req, Status) of
	{noreply, NewStatus} ->
	    {noreply, NewStatus};
	Reason ->
	    util:errlog("mod_qixi_cast error: Req:~p, Reason:~p~n",[Req, Reason]),
	    {noreply, Status}
    end.
%% info
handle_info(Info, Status) ->
    util:errlog("mod_qixi:handle_info not match: ~p", [Info]),
    {noreply, Status}.

terminate(_Reason, _Status) ->
    %%catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.
%% ----------------------db--------------------------
load_from_db(Id) ->
    SQL = io_lib:format(<<"select * from qixi_activity where player_id = ~p">>,[Id]),
    case db:get_row(SQL) of
	[] -> null;
	Row ->
	    [_PlayerId, Activity] = Row,
	    lib_goods_util:to_term(Activity)
    end.
	    
save_to_db(Id, Activity) ->
    SQL = io_lib:format(<<"insert into qixi_activity set player_id=~p, task_get='~s' ON DUPLICATE KEY UPDATE task_get='~s'">>,[Id, util:term_to_string(Activity), util:term_to_string(Activity)]),
    db:execute(SQL).

on_timer() ->
    case data_qixi:is_qixi_time() of
	true ->
	    on_time_refresh();
	false ->
	    []
    end,
    timer:sleep(60000),
    on_timer().


