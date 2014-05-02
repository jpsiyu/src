%%%-----------------------------------
%%% @Module  : lib_task_eb
%%% @Author  : zhenghehe
%%% @Created : 2010.05.05
%%% @Description: 皇榜任务
%%%-----------------------------------
-module(lib_task_eb).
-compile(export_all).
-include("server.hrl").
-include("common.hrl").
-include("task.hrl").

online(Status) ->
    gen_server:call(Status#player_status.pid, {'apply_call', lib_task_eb, online_on_pid, [Status]}).

online_on_pid(Status) ->
    lib_dict:start(trigger_task_eb, 1),
    lib_dict:start(active_task_eb, 1),
    load_trigger_task(Status),
    MinTriggerLv = data_task_eb:get_task_config(min_trigger_lv, []),
    if
        Status#player_status.lv >= MinTriggerLv ->
            %%sys_refresh_task_eb(Status);
	    load_active_task(Status);
        true ->
            skip
    end,
    ok.

%% 加载上次下线前可接皇榜任务列表或刷新任务列表
load_active_task(Status) ->
	Now = util:unixtime(),
	%% 上次刷新时间
	Ref_time = mod_daily:get_refresh_time(Status#player_status.dailypid, Status#player_status.id, 5000010),	
	if 
		Now >= Ref_time +  ?EB_NEXT_REF_TIME-> 
        	%% SQL = io_lib:format("delete from task_eb_active_bag where player_id=~p", [Status#player_status.id]),
			%% db:execute(SQL),
			sys_refresh_task_eb(Status);
		true ->
	    	%% SQL = io_lib:format("select task_id,color from task_eb_active_bag where player_id=~p", [Status#player_status.id]),
        	%% ActiveTaskEbs = db:get_all(SQL),
			ActiveTaskEbs = get_active_task_eb(Status#player_status.id),
			%% io:format("-----ActiveTaskEbsz--length-----[~p,~p]~n",[ActiveTaskEbs,length(ActiveTaskEbs)]),
			if 
				length(ActiveTaskEbs) > 0 ->
					lib_dict:erase(active_task_eb),
					lists:foreach(fun({TaskId,Color}) -> lib_dict:update(active_task_eb, {TaskId,Color}) end, ActiveTaskEbs);
				true ->
					sys_refresh_task_eb(Status)
			end
	end.


%% 加载已接皇榜任务
load_trigger_task(Status) ->
    SQL = io_lib:format("select task_id,color from task_eb_bag where player_id=~p", [Status#player_status.id]),
    TriggerTaskEbs = db:get_all(SQL),
    F = fun([TaskId,Color]) ->
            case lib_task:in_trigger(Status#player_status.tid, TaskId) of
                true ->
                    lib_dict:update(trigger_task_eb, {TaskId,Color});
                false ->
                    db:execute(io_lib:format("delete from task_eb_bag where player_id=~p and task_id = ~p", [Status#player_status.id, TaskId]))
            end
                
        end,
    lists:foreach(F, TriggerTaskEbs).

%% 下线保存数据
offline(Status) ->
	db:execute(io_lib:format("delete from task_eb_active_bag where player_id=~p", [Status#player_status.id])),
    ActiveTaskEbs = lib_dict:get(active_task_eb),
    F = fun({TaskId,Color}) ->
            SQL = io_lib:format("replace into task_eb_active_bag(player_id,task_id,color) values(~p,~p,~p)", [Status#player_status.id, TaskId, Color]),
			%%io:format("----TaskId-Color----[~p,~p]~n",[TaskId,Color]),
			db:execute(SQL)
		 end,
	lists:foreach(F, ActiveTaskEbs),
    ok.
  
get_trigger_task_eb_num() ->
    TriggerTaskEb = lib_dict:get(trigger_task_eb),
    length(TriggerTaskEb).

%% 刷新可接任务列表
sys_refresh_task_eb(Status) ->
    CanTriggers = data_task_eb_lv:get_ids(Status#player_status.lv),
    TriggerTaskEb = lib_dict:get(trigger_task_eb),
    CanTriggers1 = filter_trigger_task(CanTriggers, TriggerTaskEb),
    SysRefreshTaskNum = data_task_eb:get_task_config(sys_refresh_task_num, []),
    RefreshTasks = refresh_task_eb_helper(CanTriggers1, SysRefreshTaskNum, [], sys, 0, Status#player_status.lv),
    lib_dict:erase(active_task_eb),
    lists:foreach(fun(Item) -> lib_dict:update(active_task_eb, Item) end, RefreshTasks),
    ok.

filter_trigger_task(Tasks, []) ->
    Tasks;
filter_trigger_task(Tasks, [H|T]) ->
    {TaskId, _Color} = H,
    NewTasks = filter_trigger_task_helper(Tasks, TaskId, []),
    filter_trigger_task(NewTasks, T).
filter_trigger_task_helper([], _TaskId, NewTasks) ->
    lists:reverse(NewTasks);
filter_trigger_task_helper([H|T], TaskId, NewTasks) ->
    {Color, Tasks} = H,
    TempTasks = lists:delete(TaskId, Tasks),
    filter_trigger_task_helper(T, TaskId, [{Color, TempTasks}|NewTasks]).

need_to_re_lottery(Color, RefreshTasks, Type, Lv) ->
    if 
        Type =:= finish ->
            false;
        true ->
            [MaxinumCfg0, MaxinumCfg1, MaxinumCfg2, MaxinumCfg3, MaxinumCfg4] = sys_refresh_lottery_maxinum(),
            case Type of
                sys ->
                    sys_refresh_lottery_maxinum();
                gold ->
                    gold_refresh_lottery_maxinum(Lv)
            end,
            [Color0, Color1, Color2, Color3, Color4] = 
            case Color of
                0 ->
                    [1, 0, 0, 0, 0];
                1 ->
                    [0, 1, 0, 0, 0];
                2 ->
                    [0, 0, 1, 0, 0];
                3 ->
                    [0, 0, 0, 1, 0];
                4 ->
                    [0, 0, 0, 0, 1]
            end,
            [MaxinumRef0, MaxinumRef1, MaxinumRef2, MaxinumRef3, MaxinumRef4] = cacl_refresh_task_color(RefreshTasks, [Color0, Color1, Color2, Color3, Color4]),
            MaxinumRef0>MaxinumCfg0 orelse MaxinumRef1>MaxinumCfg1 orelse MaxinumRef2>MaxinumCfg2 orelse MaxinumRef3>MaxinumCfg3 orelse MaxinumRef4>MaxinumCfg4
    end.

cacl_refresh_task_color([], [MaxinumRef0, MaxinumRef1, MaxinumRef2, MaxinumRef3, MaxinumRef4]) ->
    [MaxinumRef0, MaxinumRef1, MaxinumRef2, MaxinumRef3, MaxinumRef4];
cacl_refresh_task_color([H|T], [MaxinumRef0, MaxinumRef1, MaxinumRef2, MaxinumRef3, MaxinumRef4]) ->
    {_, Color} = H,
    [NewMaxinumRef0, NewMaxinumRef1, NewMaxinumRef2, NewMaxinumRef3, NewMaxinumRef4] = 
    case Color of
        0 ->
            [MaxinumRef0+1, MaxinumRef1, MaxinumRef2, MaxinumRef3, MaxinumRef4];
        1 ->
            [MaxinumRef0, MaxinumRef1+1, MaxinumRef2, MaxinumRef3, MaxinumRef4];
        2 ->
            [MaxinumRef0, MaxinumRef1, MaxinumRef2+1, MaxinumRef3, MaxinumRef4];
        3 ->
            [MaxinumRef0, MaxinumRef1, MaxinumRef2, MaxinumRef3+1, MaxinumRef4];
        4 ->
            [MaxinumRef0, MaxinumRef1, MaxinumRef2, MaxinumRef3, MaxinumRef4+1]
    end,
    cacl_refresh_task_color(T, [NewMaxinumRef0, NewMaxinumRef1, NewMaxinumRef2, NewMaxinumRef3, NewMaxinumRef4]).

refresh_task_eb_helper([], _RefreshTaskNum, RefreshTasks, _Type, _, _Lv) ->
    RefreshTasks;
refresh_task_eb_helper(_, _RefreshTaskNum, RefreshTasks, _, _RefreshTaskNum, _Lv) ->
    RefreshTasks;
refresh_task_eb_helper(CanTriggers, RefreshTaskNum, RefreshTasks, Type, Time, Lv) ->
    Color = refresh_lottery_color(Type, Lv),
    case need_to_re_lottery(Color, RefreshTasks, Type, Lv) of
        false ->
            case lists:keysearch(Color, 1, CanTriggers) of
                {value, {_Color, _Tasks}} ->
                    Num = length(_Tasks),
                    case Num > 0 of
                        true ->
                            Rand = util:rand(1, Num),
                            TaskId = lists:nth(Rand, _Tasks),
                            _NewTasks = lists:delete(TaskId, _Tasks),
                            _CanTriggers = lists:delete(Color, CanTriggers),
                            NewRefreshTasks = [{TaskId, _Color}|RefreshTasks],
                            case (length(NewRefreshTasks) >= RefreshTaskNum) of
                                true ->
                                    NewRefreshTasks;
                                false ->
                                    refresh_task_eb_helper([{_Color, _NewTasks}|_CanTriggers], RefreshTaskNum, NewRefreshTasks, Type, Time+1, Lv)
                            end;
                        false ->
                            refresh_task_eb_helper(CanTriggers, RefreshTaskNum, RefreshTasks, Type, Time+1, Lv) 
                    end;
                false ->
                    refresh_task_eb_helper(CanTriggers, RefreshTaskNum, RefreshTasks, Type, Time+1, Lv) 
            end;
        true ->
            refresh_task_eb_helper(CanTriggers, RefreshTaskNum, RefreshTasks, Type, Time+1, Lv) 
    end.

refresh_lottery_color(Type, Lv) ->
    case Type of
        sys ->
            sys_refresh_lottery_color();
        finish ->
            finish_refresh_lottery_color();
		gold ->
			gold_refresh_lottery_color(Lv)
        %%60 ->
        %%    gold_refresh_lottery_color(60);
        %%30 ->
        %%    gold_refresh_lottery_color(30);
        %%10 ->
        %%    gold_refresh_lottery_color(10)
    end.
sys_refresh_lottery_color() ->
    SysRefreshConfig = data_task_eb:get_sys_refresh_config(),
    Sum = lists:foldl(fun([_, Probability, _], Acc0)-> Probability+Acc0 end, 0, SysRefreshConfig),
    Rand = util:rand(1, Sum),
    sys_refresh_lottery_color_helper(Rand, SysRefreshConfig, 0).

sys_refresh_lottery_color_helper(_Rand, [], _Acc) ->
    4;
sys_refresh_lottery_color_helper(Rand, [H|T], Acc) ->
    [Color, Probability, _] = H,
    if
        Rand =< Acc+Probability ->
            Color;
        true ->
            sys_refresh_lottery_color_helper(Rand, T, Probability+Acc)
    end.

sys_refresh_lottery_maxinum() ->
    SysRefreshConfig = data_task_eb:get_sys_refresh_config(),
    lists:map(fun([_, _, Maxinum]) -> Maxinum end, SysRefreshConfig).

finish_refresh_lottery_color() ->
    FinishRefreshConfig = data_task_eb:get_finish_refresh_config(),
    Sum = lists:foldl(fun([_, Probability], Acc0)-> Probability+Acc0 end, 0, FinishRefreshConfig),
    Rand = util:rand(1, Sum),
    finish_refresh_lottery_color_helper(Rand, FinishRefreshConfig, 0).

finish_refresh_lottery_color_helper(_Rand, [], _Acc) ->
    4;
finish_refresh_lottery_color_helper(Rand, [H|T], Acc) ->
    [Color, Probability] = H,
    if
        Rand =< Acc+Probability ->
            Color;
        true ->
            finish_refresh_lottery_color_helper(Rand, T, Probability+Acc)
    end.

finish_refresh_task_eb(Status, TaskId) ->
    lib_dict:erase(trigger_task_eb, TaskId),
    CanTriggers = data_task_eb_lv:get_ids(Status#player_status.lv),
    TriggerTaskEb = lib_dict:get(trigger_task_eb),
    CanTriggers1 = filter_trigger_task(CanTriggers, TriggerTaskEb),
	RefreshTask = refresh_task_eb_helper(CanTriggers1, 1, [], finish, 0, Status#player_status.lv),
	mod_daily:increment(Status#player_status.dailypid, Status#player_status.id, 3700101),
    lib_dict:erase(active_task_eb, TaskId),
	case RefreshTask=/=[] andalso length(RefreshTask)=:=1 of
		true -> [RefreshTask2] = RefreshTask,
			    lib_dict:update(active_task_eb, RefreshTask2);
		false -> skip
	end.

refresh_add_task_eb(Status, Num) ->
    CanTriggers = data_task_eb_lv:get_ids(Status#player_status.lv),
    TriggerTaskEb = lib_dict:get(trigger_task_eb),
    CanTriggers1 = filter_trigger_task(CanTriggers, TriggerTaskEb),
    RefreshTasks = refresh_task_eb_helper(CanTriggers1, Num, [], sys, 0, Status#player_status.lv),
	lists:foreach(fun(Item) -> lib_dict:update(active_task_eb, Item) end, RefreshTasks).

gold_refresh_task_eb(Status) ->
    CanTriggers = data_task_eb_lv:get_ids(Status#player_status.lv),
    TriggerTaskEb = lib_dict:get(trigger_task_eb),
    CanTriggers1 = filter_trigger_task(CanTriggers, TriggerTaskEb),
    SysRefreshTaskNum = data_task_eb:get_task_config(sys_refresh_task_num, []),
    %% GoldProbability = data_task_eb:gold_refresh_lottery_color2(),
	%% io:format("-----GoldProbability-----~p~n", [GoldProbability]),
    RefreshTasks = refresh_task_eb_helper(CanTriggers1, SysRefreshTaskNum, [], gold, 0, Status#player_status.lv),
    lib_dict:erase(active_task_eb),
    lists:foreach(fun(Item) -> lib_dict:update(active_task_eb, Item) end, RefreshTasks),
    ok.

%%gold_refresh_lottery_color(GoldProbability) ->
%%    GoldRefreshConfig = data_task_eb:get_gold_refresh_config(),
%%    {value, {_, GoldRefreshConfig2}} = lists:keysearch(GoldProbability, 1, GoldRefreshConfig),
%%    Sum = lists:foldl(fun([_, Probability, _], Acc0)-> Probability+Acc0 end, 0, GoldRefreshConfig2),
%%    Rand = util:rand(1, Sum),
%%    gold_refresh_lottery_color_helper(Rand, GoldRefreshConfig2, 0).

%%gold_refresh_lottery_color_helper(_Rand, [], _Acc) ->
%%    4;
%%gold_refresh_lottery_color_helper(Rand, [H|T], Acc) ->
%%    [Color, Probability, _] = H,
%%    if
%%        Rand =< Acc+Probability ->
%%            Color;
%%        true ->
%%            gold_refresh_lottery_color_helper(Rand, T, Probability+Acc)
%%    end.

gold_refresh_lottery_color(Lv) ->
    GoldRefreshConfig = data_task_eb:get_gold_refresh_config(Lv),
    Sum = lists:foldl(fun([_, Probability,_], Acc0)-> Probability+Acc0 end, 0, GoldRefreshConfig),
    Rand = util:rand(1, Sum),
    gold_refresh_lottery_color_helper(Rand, GoldRefreshConfig, 0).

gold_refresh_lottery_color_helper(_Rand, [], _Acc) ->
    4;
gold_refresh_lottery_color_helper(Rand, [H|T], Acc) ->
    [Color, Probability, _] = H,
    if
        Rand =< Acc+Probability ->
            Color;
        true ->
            gold_refresh_lottery_color_helper(Rand, T, Probability+Acc)
    end.

gold_refresh_lottery_maxinum(Lv) ->
    GoldRefreshConfig = data_task_eb:get_gold_refresh_config(Lv),
	lists:map(fun([_, _, Maxinum]) -> Maxinum end, GoldRefreshConfig).

finish_task(TaskId, ParamList, PS) ->
    lib_player:rpc_cast_by_id(PS#player_status.id, lib_task_eb, finish_task_on_pid, [PS, TaskId]),	
	mod_task:normal_finish(TaskId, ParamList, PS).
	

finish_task_on_pid(Status, TaskId) ->
    lib_task_eb:finish_refresh_task_eb(Status, TaskId),
    pp_task_eb:handle(30400, Status, []),
    SQL = io_lib:format("delete from task_eb_bag where player_id=~p and task_id=~p", [Status#player_status.id, TaskId]),
    db:execute(SQL),	
    ok.

cancel_task(Status, TaskId) ->
    lib_player:rpc_cast_by_id(Status#player_status.id, lib_task_eb, cancel_task_on_pid, [Status, TaskId]).

cancel_task_on_pid(Status, TaskId) ->
    lib_dict:erase(trigger_task_eb, TaskId),
    SQL = io_lib:format("delete from task_eb_bag where player_id=~p and task_id=~p", [Status#player_status.id, TaskId]),
    db:execute(SQL),
    pp_task_eb:handle(30400, Status, []),
    ok.

trigger_task(Status, TaskId) ->
    {_TaskId, _Color} = lib_dict:get(active_task_eb, TaskId),
    lib_dict:update(trigger_task_eb, {_TaskId, _Color}),
    SQL = io_lib:format("replace into task_eb_bag(player_id,task_id,color) values(~p,~p,~p)", [Status#player_status.id, _TaskId, _Color]),
    db:execute(SQL),
    ok.

get_next_ref_time() ->
    {{_Year, _Month, _Day}, {_Hour, Min, Sec}} = calendar:local_time(),
    if 
	 Min >= 0 andalso Min < 30 ->
	    (30-Min-1)*60+(60-Sec-1);
     Min >= 30 andalso Min =< 59 ->
	    (60-Min-1)*60+(60-Sec-1)
    end.

%% 保存下线前可接皇榜任务到进程字典
set_active_task_eb(PlayId,ActiveTaskEbs) ->
	gen_server:call(misc:get_global_pid(mod_task_eb), {set_active_task_eb, [PlayId,ActiveTaskEbs]}).

%% 上次下线前可接皇榜任务
get_active_task_eb(PlayId) ->
	gen_server:call(misc:get_global_pid(mod_task_eb), {get_active_task_eb, [PlayId]}).	

