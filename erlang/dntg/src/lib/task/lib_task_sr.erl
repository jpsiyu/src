%%%-----------------------------------
%%% @Module  : lib_task_sr
%%% @Author  : zhenghehe
%%% @Created : 2010.05.05
%%% @Description: 平乱任务
%%%-----------------------------------
-module(lib_task_sr).
-compile(export_all).
-include("server.hrl").
-include("task.hrl").

online(Status) ->
    gen_server:cast(Status#player_status.pid, {'apply_cast', lib_task_sr, online_on_pid, [Status]}).

online_on_pid(Status) ->
    lib_server_dict:task_sr_trigger([]),
    lib_server_dict:task_sr_active([]),
    lib_server_dict:task_sr_rf_count([]),
    load_active_task(Status),
    load_trigger_task(Status),
    load_rf_count(Status),
    ok.

%% 已接平乱任务
trigger_task(Status) ->
   SQL = io_lib:format("select task_id,color from task_sr_bag where player_id=~p and type = ~p limit 1", [Status#player_status.id, ?TASK_SR_TRIGGER]),
   db:get_row(SQL).

%% 加载已接平乱任务 
load_trigger_task(Status) ->
    TriggerTaskSr = trigger_task(Status),
    if
        TriggerTaskSr /= [] ->
            [TaskId, Color] = TriggerTaskSr,
            lib_server_dict:task_sr_trigger({TaskId, Color});
        true ->
            skip
    end.

%%　加载可接平乱任务(先判断是否有已接任务，有则加载，否则正常加载可接平乱任务)
load_active_task(Status) ->
    TriggerTaskSr = trigger_task(Status),
	if  TriggerTaskSr /= [] ->
            [_TaskId, _Color] = TriggerTaskSr,
			%%　修复掉线引起的平乱任务与30000一般任务数据不同步，接取任务失败
			IS_trigger_30000 =lib_task:get_one_trigger(Status#player_status.tid , _TaskId),
            case IS_trigger_30000 of
				false ->
					SQL = io_lib:format("delete from task_sr_bag where player_id=~p and task_id=~p", [Status#player_status.id, _TaskId]),
				    db:execute(SQL),
					TaskSr = [];
				_ -> TaskSr = TriggerTaskSr
			end;			
		true ->
			 SQL = io_lib:format("select task_id,color from task_sr_bag where player_id=~p and type = ~p limit 1", [Status#player_status.id, ?TASK_SR_ACTIVE]),
             TaskSr = db:get_row(SQL)
	end,
    if
        TaskSr /= [] ->
            [TaskId, Color] = TaskSr,
            lib_server_dict:task_sr_active({TaskId, Color});
        true ->
            skip
    end.

%% 加载刷新次数
load_rf_count(Status) ->
    SQL = io_lib:format("select daily_times,refresh_count from task_sr_daily where role_id=~p limit 1", [Status#player_status.id]),
    TaskSr = db:get_row(SQL),
    if
        TaskSr /= [] ->
            [Times, Count] = TaskSr,
            lib_server_dict:task_sr_rf_count({Times, Count});
        true ->
            skip
    end.

offline(_PS) ->
    ok.

%% 初始化可接平乱任务
refresh_task_sr_init(Status) ->
    MinTriggerLv = data_task_sr:get_task_config(min_trigger_lv, []),
    case Status#player_status.lv < MinTriggerLv of
        false ->
            case lib_server_dict:task_sr_active() of
                [] ->
                    Color = data_task_sr:refresh_task_sr_init_color(Status#player_status.lv),
                    %%TaskSrActives = data_task_sr_lv:get_ids(Status#player_status.lv),
                    TaskSrActives = data_task_sr:get_ids(Status#player_status.lv),
                    case lists:keysearch(Color, 1, TaskSrActives) of
                        {value, {_, Tasks}} ->
                            Num = length(Tasks),
                            case Num > 0 of
                                true ->
                                    TriggerDaily = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000020),
                                    %%Rand = util:rand(1, Num),								
                                    TaskId = lists:nth(TriggerDaily+1, Tasks),
                                    lib_server_dict:task_sr_active({TaskId, Color}),
                                    gen_server:cast(Status#player_status.pid, {'set_data', [{task_sr_colour, Color}]}),
                                    SQL = io_lib:format("replace into task_sr_bag (player_id, task_id, color, type) values (~p,~p,~p,~p)", [Status#player_status.id, TaskId, Color, ?TASK_SR_ACTIVE]),
                                    db:execute(SQL),
                                    ok;
                                false ->
                                    refresh_task_sr_init(Status)
                            end;
                        false ->
                            util:errlog("refresh_task_sr_init error ~p", [Color])
                    end;
                _ ->
                    skip
            end;
        true ->
            skip
    end.


%% 刷新平乱任务
%% @param ColorTarget 目标颜色  0 随机刷出颜色  其它直接指定颜色
%% @return boolean
refresh_task_sr(Status, ColorTarget, ColourBf) ->
	case ColorTarget =/=0 of
		true ->
		    Color = ColorTarget;
		false ->
			Color = data_task_sr:refresh_task_sr_color(Status#player_status.lv, ColourBf)
	end,
    %%TaskSrActives = data_task_sr_lv:get_ids(Status#player_status.lv),
    TaskSrActives = data_task_sr:get_ids(Status#player_status.lv),
    case lists:keysearch(Color, 1, TaskSrActives) of
        {value, {_, Tasks}} ->
            Num = length(Tasks),
            case Num > 0 of
                true ->
                    TriggerDaily = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000020),
                    %%Rand = util:rand(1, Num),
                    [NewTimes,NewCount] = case lib_server_dict:task_sr_rf_count() of
                        {Times,Count} ->
                            case TriggerDaily =:= Times of
                                true ->
                                    case Count >= 10 of
                                        true ->
                                            NewColor = 4,
                                            [Times+1,Count+1];
                                        _ ->
                                            NewColor = Color,
                                            [Times,Count+1]
                                    end;
                                _ ->
                                    NewColor = Color,
                                    [TriggerDaily,1]
                            end;
                        _ -> 
                            NewColor = Color,
                            [TriggerDaily,1]
                    end,    
                    TaskId = lists:nth(TriggerDaily+1, Tasks),
                    lib_server_dict:task_sr_active({TaskId, NewColor}),
                    gen_server:cast(Status#player_status.pid, {'set_data', [{task_sr_colour, NewColor}]}),
                    SQL = io_lib:format("replace into task_sr_bag (player_id, task_id, color, type) values (~p,~p,~p,~p)", [Status#player_status.id, TaskId, Color, ?TASK_SR_ACTIVE]),		
                    db:execute(SQL),
                    lib_server_dict:task_sr_rf_count({NewTimes,NewCount}),
                    SQL1 = io_lib:format("replace into task_sr_daily (role_id, daily_times, refresh_count) values (~p,~p,~p)", [Status#player_status.id, NewTimes, NewCount]),      
                    db:execute(SQL1),
                    true;
                false ->
                    false
            end;
        _ ->
            false
    end.

%% 添加已接任务
task_sr_trigger(Status, TaskId, Color) ->
    lib_server_dict:task_sr_trigger({TaskId, Color}),
	SQL1 = io_lib:format("select count(*) from task_sr_bag where player_id=~p and type=~p", [Status#player_status.id, ?TASK_SR_TRIGGER]),
	Count = db:get_one(SQL1),
	case Count>0 of
		true ->
			SQL2 = io_lib:format("delete from task_sr_bag where player_id=~p", [Status#player_status.id]),
			SQL3 = io_lib:format("replace into task_sr_bag (player_id, task_id, color, type) values (~p,~p,~p,~p)", [Status#player_status.id, TaskId, Color, ?TASK_SR_TRIGGER]),
			db:execute(SQL2),
			db:execute(SQL3);
		false -> 
			SQL4 = io_lib:format("update  task_sr_bag  set type = ~p where player_id =~p and task_id = ~p and color = ~p", [?TASK_SR_TRIGGER, Status#player_status.id, TaskId, Color]),
		    db:execute(SQL4)
	end.


finish_task(TaskId, ParamList, PS) ->
    RewardRatio = data_task_sr:get_task_sr_award(PS#player_status.task_sr_colour),
    lib_player:rpc_cast_by_id(PS#player_status.id, lib_task_sr, finish_task_on_pid, [PS, TaskId]),
	mod_daily:increment(PS#player_status.dailypid, PS#player_status.id, 3700102),
    TriggerDaily = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 5000020),
    case TriggerDaily =:= 10 orelse  TriggerDaily =:= 20 of
        true ->
            GiftList = data_task_sr:get_task_config(task_sr_gift,TriggerDaily),
            [{GoodsID,GoodsNum}] = GiftList,
            Go = PS#player_status.goods,
            {ok, BinData} = pt_305:write(30505, [TriggerDaily,GoodsID]),
            lib_server_send:send_to_sid(PS#player_status.sid, BinData),
            case gen_server:call(Go#status_goods.goods_pid, {'cell_num'}) < length(GiftList) of
                true ->
                    %% 空位不足发到邮件
                    [Title, Content] = data_task_text:task_er_award_email(TriggerDaily),
                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PS#player_status.id], Title, Content, GoodsID, 2, 0, 0, GoodsNum, 0, 0, 0, 0]);
                false ->                    
                    ErrorCode = gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', PS, GiftList}),
                    case ErrorCode of
                        ok ->               
                            GiveList = [{goods, GoodsID, GoodsNum}],
                            lib_gift_new:send_goods_notice_msg(PS, GiveList);
                        _ -> skip
                    end      
            end;
        _ ->
            skip
    end,

	mod_task:normal_finish(TaskId, ParamList, PS,RewardRatio).
	

finish_task_on_pid(Status, TaskId) ->
    lib_server_dict:task_sr_trigger([]),
    SQL = io_lib:format("delete from task_sr_bag where player_id=~p and task_id=~p", [Status#player_status.id, TaskId]),
    db:execute(SQL),
    FirstColour = data_task_sr:refresh_task_sr_init_color(Status#player_status.lv),
    gen_server:cast(Status#player_status.pid, {'set_data', [{task_sr_colour, FirstColour}]}),
    refresh_task_sr(Status, 0, FirstColour),
    pp_task_sr:handle(30500, Status, []),	
    ok.

cancel_task(Status, TaskId) ->
    lib_player:rpc_cast_by_id(Status#player_status.id, lib_task_sr, cancel_task_on_pid, [Status, TaskId]).

cancel_task_on_pid(Status, TaskId) ->
    lib_server_dict:task_sr_trigger([]),
    SQL = io_lib:format("delete from task_sr_bag where player_id=~p and task_id=~p", [Status#player_status.id, TaskId]),
    db:execute(SQL),
    pp_task_sr:handle(30500, Status, []),
    ok.
