%% --------------------------------------------------------
%% @Module:           |timer_clear_mon
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-00-00
%% @Description:      |定时清除 指定ID的怪物 本进程 5分钟执行一次
%% --------------------------------------------------------
-module(timer_clear_mon).
-behaviour(gen_fsm).
-export([insert_mon/3	 	 					%% 添加一个需要定时清除的怪物
		, remove_mon/1	 	 					%% 从定时清除列表中移除一个怪物
		, waiting/2]).
-export([start_link/0, init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).
-include("common.hrl").

-define(CLEAR_TIME, 3 * 60 * 1000). 	 	 					%% 5分钟执行一次

%% 启动进程
start_link() ->
    gen_fsm:start_link({global,?MODULE}, ?MODULE, [], []).

%% @Status 一个Key 为怪物唯一ID Value 为制定清除的时间 的字典 
init([])->
    {ok, waiting, [], ?CLEAR_TIME}.

%% 插入一个怪物
%% @param MonId 怪物的唯一ID(不是类型ID)
%% @param ClearAfter 指定清除怪物的时间(单位 秒)
insert_mon(MonId, SceneId, ClearAfter) ->
	case misc:whereis_name(global, timer_clear_mon) of
		Pid when is_pid(Pid) ->
			gen_fsm:send_all_state_event(Pid, {insert_mon, MonId, SceneId, ClearAfter});
		_r ->
			skip
	end.

%% 从列表移除一个怪物
%% @param MonId 怪物的唯一ID(不是类型ID)
%% @param ClearAfter 指定清除怪物的时间
remove_mon(MonId) ->
	case misc:whereis_name(global, timer_clear_mon) of
		Pid when is_pid(Pid) ->
			gen_fsm:send_all_state_event(Pid, {remove_mon, MonId});
		_ ->
			skip
	end.

waiting(timeout, Status) ->
	NowTime = util:unixtime(),
	case catch do_handle(Status, Status, NowTime) of
         {ok, NewStatus} ->
            {next_state, waiting, NewStatus, ?CLEAR_TIME};
         {stop, Reason} ->
            {stop, Reason};
         _Err ->
            {next_state, waiting, Status, ?CLEAR_TIME}
    end.

%% --------------------------------------------------------------------------
%% 
%% --------------------------------------------------------------------------
handle_event({insert_mon, MonId, SceneId, ClearAfter}, StateName, Status) ->
	NowTime  = util:unixtime(),
	KillTime = ClearAfter + NowTime,
	NewStatus = [{MonId, KillTime, SceneId}] ++ Status,
    {next_state, StateName, NewStatus, 0};
handle_event({remove_mon, MonId}, StateName, Status) ->
	NewStatus = lists:keydelete(MonId, 1, Status),
    {next_state, StateName, NewStatus, 0};
handle_event(_Event, StateName, Status) ->
    {next_state, StateName, Status, 0}.

%% 插入怪物
handle_sync_event({insert_mon, MonId, SceneId, ClearAfter}, _From, StateName, Status) ->
	NowTime  = util:unixtime(),
	KillTime = ClearAfter + NowTime,
	NewStatus = [{MonId, KillTime, SceneId}] ++ Status,
    {reply, ok, StateName, NewStatus, 0};
%% 移除怪物
handle_sync_event({remove_mon, MonId}, _From, StateName, Status) ->
	NewStatus = lists:keydelete(MonId, 1, Status),
    {reply, ok, StateName, NewStatus, 0};

%% 错误
handle_sync_event(_Event, _From, StateName, Status) ->
    {reply, ok, StateName, Status}.


%%中断服务
handle_info(stop, _StateName, Status) ->
    {stop, normal, Status};
handle_info(_Info, StateName, Status) ->
    {next_state, StateName, Status}.

terminate(_Reason, _StateName, _Status) ->
    ok.

code_change(_OldVsn, StateName, Status, _Extra) ->
    {ok, StateName, Status}.

%% 处理清除怪物事件
do_handle([], StatusBack, _NowTime) ->
    {ok, StatusBack};
do_handle(StatusDo, StatusBack, NowTime) ->
	[{MonId, KillTime, SceneId}|StatusDoNext] = StatusDo,
	case NowTime >= KillTime of
		true ->
			%% 清除怪物
			lib_mon:clear_scene_mon_by_ids(SceneId, [], 1, [MonId]),
			StatusBackNext = lists:keydelete(MonId, 1, StatusBack),
			do_handle(StatusDoNext, StatusBackNext, NowTime);
		false ->
			do_handle(StatusDoNext, StatusBack, NowTime)
	end.

	






