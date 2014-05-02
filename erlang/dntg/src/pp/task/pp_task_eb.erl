%%%--------------------------------------
%%% @Module  : pp_task_eb
%%% @Author  : zhenghehe
%%% @Created : 2010.09.24
%%% @Description:  皇榜任务模块
%%%--------------------------------------
-module(pp_task_eb).
-export([handle/3]).
-include("server.hrl").
-include("task.hrl").

%% 可接皇榜任务列表
handle(30400, PlayerStatus, _) ->
    Now = util:unixtime(),
	%% 上次刷新时间
	Ref_time = mod_daily:get_refresh_time(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 5000010),
	Eb_next_ref_time = Ref_time + ?EB_NEXT_REF_TIME,

	%% 判断是否更新客户端显示的皇榜任务列表
    if  
	    Now >= Ref_time +  ?EB_NEXT_REF_TIME->
			lib_task_eb:sys_refresh_task_eb(PlayerStatus),
            mod_daily:set_refresh_time(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 5000010), %%更新刷新时间
			NextRefTime = ?EB_NEXT_REF_TIME; %%下次刷新剩余时间(s)
		true ->
			NextRefTime = Eb_next_ref_time - Now
	end,
    _ActiveTaskEbs = lib_dict:get(active_task_eb),
    _TriggerTaskEbs = lib_dict:get(trigger_task_eb),
    _ActiveTaskEbs1 = _ActiveTaskEbs--_TriggerTaskEbs,
	Eb_num = length(_ActiveTaskEbs1),
	%% 修正:少于5个可接任务的情况
	_ActiveTaskEbs2 = 
	case Eb_num<5 of
		true ->
			lib_task_eb:refresh_add_task_eb(PlayerStatus, 5-length(_ActiveTaskEbs1)),
			ActiveTaskEbs2 = lib_dict:get(active_task_eb),
			_TriggerTaskEbs1 = lib_dict:get(trigger_task_eb),
			ActiveTaskEbs2--_TriggerTaskEbs1;
		false -> _ActiveTaskEbs1
	end,
	
    F = fun({TaskId, Color}) -> 
        Bin = lib_task:get_task_info(TaskId, PlayerStatus, active),
        <<TaskId:32, Color:8, Bin/binary>>  
        end,
    ActiveTaskEbs = lists:map(F, _ActiveTaskEbs2),
    TriggerTaskEbDaily = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 5000010),
    MaxinumTriggerDaily = data_task_eb:get_task_config(maxinum_trigger_daily, []),
    LeftTriggerDaily = MaxinumTriggerDaily-TriggerTaskEbDaily,
    {ok, BinData} = pt_304:write(30400, [ActiveTaskEbs, NextRefTime, LeftTriggerDaily]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
	{ok, PlayerStatus};

%% 皇榜刷新可接皇榜任务
handle(30402, PlayerStatus, [IsAuto]) ->
    [Result, NewStatus] = mod_task_eb:gold_refresh_task(PlayerStatus, IsAuto),
    {ok, BinData} = pt_304:write(30402, Result),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
    if
        Result =:= 1 ->
            handle(30400, NewStatus, []);
        true ->
            skip
    end,
    {ok, NewStatus};

%% 接取皇榜任务
handle(30403, PlayerStatus, [TaskId]) ->
    [Result, NewStatus] = mod_task_eb:trigger_task(PlayerStatus, TaskId),
    {ok, BinData} = pt_304:write(30403, Result),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
    if
        Result == 1 ->
            handle(30400, NewStatus, []);
        true ->
            skip
    end,
    {ok ,NewStatus};

%% 已接皇榜任务列表
handle(30404, PlayerStatus, []) ->
    _TriggerTaskEbs = lib_dict:get(trigger_task_eb),
    F = fun({TaskId, Color}) -> 
        <<TaskId:32, Color:8>>  
        end,
    TriggerTaskEbs = lists:map(F, _TriggerTaskEbs),
    {ok, BinData} = pt_304:write(30404, TriggerTaskEbs),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);

handle(_Cmd, _PlayerStatus, _Data) ->
    {error, bad_request}.

