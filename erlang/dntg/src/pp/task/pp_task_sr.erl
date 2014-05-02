%%%--------------------------------------
%%% @Module  : pp_task_sr
%%% @Author  : zhenghehe
%%% @Created : 2010.09.24
%%% @Description:  平乱任务模块
%%%--------------------------------------
-module(pp_task_sr).
-export([handle/3]).
-include("server.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-include("task.hrl").

%% 可接平乱任务
handle(30500, Status, _) ->
    lib_task_sr:refresh_task_sr_init(Status),
    case lib_server_dict:task_sr_active() of
        {_TaskId, _Color} ->
            gen_server:cast(Status#player_status.pid, {'set_data', [{task_sr_colour, _Color}]}),
            %%io:format("PL:~p~n",[[?MODULE,?LINE,_TaskId, _Color]]),
            TaskInfo = data_task:get(_TaskId, Status),
            case Status#player_status.lv >= TaskInfo#task.level + 10 of
                true ->
                    lib_server_dict:task_sr_active([]),
                    lib_task_sr:refresh_task_sr_init(Status);
                _ ->
                    skip
            end;
        _ ->
            skip
    end,            
    TriggerDaily = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000020),
    case lib_server_dict:task_sr_active() of
        {TaskId, Color} ->
            TaskBin = lib_task:get_task_sr_info(TaskId, Status, active, Color),
            {ok, BinData} = pt_305:write(30500, [TaskId, Color, TriggerDaily, TaskBin]),
            %%io:format("PL:~p~n",[[?MODULE,?LINE,TaskId, Color,TriggerDaily]]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData);
        _ ->
%%             {ok, BinData} = pt_305:write(30500, [0, 0, TriggerDaily, <<>>]),
%%             lib_server_send:send_to_sid(Status#player_status.sid, BinData)
            skip
    end;

%% 刷新平乱任务
handle(30501, Status, _) ->
    TaskSrActive = lib_server_dict:task_sr_active(),
    LastColor = case TaskSrActive  of
        {_LastTaskId, _LastColor} -> _LastColor;
        _ ->
            0
    end,
    [Result, Status2, _TaskId, _Color] = refresh(Status, 0),
    case Result =:= 1 andalso _Color =/= LastColor of
        true -> {ok, BinData} = pt_305:write(30501, 11);
        _ ->    {ok, BinData} = pt_305:write(30501, Result)
    end,
    lib_server_send:send_to_sid(Status2#player_status.sid, BinData),
    if
        Result =:= 1 ->
			lib_player:refresh_client(Status#player_status.id, 2),
            handle(30500, Status2, []);
        true ->
            skip
    end,
    {ok, Status2};


%% 刷新平乱任务到指定颜色为止
handle(30502, Status, [Color]) ->
    RefreshCount=case lib_server_dict:task_sr_rf_count() of
        {_Times,Count} ->
            Count;
        _ -> 0
     end,
    [Result, Status2, _TaskId, _Color,LastCount] = refresh_color(RefreshCount, Status, Color),
    %%io:format("PL:~p~n",[[?MODULE,?LINE,Result,RefreshCount,LastCount,LastCount-RefreshCount]]),
	{ok, BinData} = pt_305:write(30502, [Result,LastCount-RefreshCount]),
    lib_server_send:send_to_sid(Status2#player_status.sid, BinData),
	lib_player:refresh_client(Status2#player_status.id, 2),
    if
        Result =:= 1 ->
            handle(30500, Status2, []);
        true ->
            skip
    end,
    {ok, Status2};

%% 新手引导--刷成橙色平乱任务
handle(30504, Status, _) ->
    case Status#player_status.lv >= 40 of
        true ->
                [NewResult, NewStatus] = [0,Status];
        _ ->
            GoodsTypeId = data_task_sr:get_task_config(refresh_goods, []),
            Dict = lib_goods_dict:get_player_dict(Status),
            GoodsInfo = lib_goods_util:get_goods_by_type(Status#player_status.id, GoodsTypeId, ?GOODS_LOC_BAG, Dict),
            Go = Status#player_status.goods,
             [NewResult, NewStatus] = 
                if
                GoodsInfo /= [] ->
                    [GoodsId, GoodsPlayerId, GoodsLevel] = [GoodsInfo#goods.goods_id, GoodsInfo#goods.player_id, GoodsInfo#goods.level],
                    if   % 物品不归你所有
                        GoodsPlayerId /= Status#player_status.id ->
                            [3, Status];
                         % 你级别不够
                        Status#player_status.lv < GoodsLevel ->
                            [4, Status];
                        true ->
                            case gen_server:call(Go#status_goods.goods_pid, {'delete_one_norefresh', GoodsId, 1}) of
                                1 ->
                                    TriggerDaily = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000020),
                                    case  TriggerDaily <1  of
                                        true ->
                                             [Result, _TaskId, _Color] = refresh_orange(Status),
                                             if
                                                Result =:= 1 ->
                                                    handle(30500, Status, []);
                                                true ->
                                                    skip
                                            end,
                                             [Result, Status];
                                        false ->
                                            [6, Status]
                                    end;        
                                _GoodsModuleCode ->
                                    [2, Status]
                            end
                    end;
                true -> 
                    [2, Status]
            end
     end,
    {ok, BinData} = pt_305:write(30504, NewResult),
    lib_server_send:send_to_sid(NewStatus#player_status.sid, BinData),
    {ok, NewStatus};


%% 接取平乱任务
handle(30503, Status, [TaskId]) ->
    Level = Status#player_status.lv,
    MinTriggerLv = data_task_sr:get_task_config(min_trigger_lv, []),
    MaxinumTriggerDaily = data_task_sr:get_task_config(maxinum_trigger_daily, []),
    TriggerDaily = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000020),
    TaskSrActive = lib_server_dict:task_sr_active(),
    [Result] = 
    if
        Level < MinTriggerLv ->
            [2];
        TriggerDaily >= MaxinumTriggerDaily ->
            [3];
        TaskSrActive =:= [] ->
			%% 修正:没有可接任务时,给予刷新任务
			 SQL = io_lib:format("delete from task_sr_bag where player_id=~p", [Status#player_status.id]),
			 db:execute(SQL),
			 lib_task_sr:refresh_task_sr(Status, 0, Status#player_status.task_sr_colour),
             handle(30500, Status, []),
	         [0];
        true ->
            {_TaskId, Color} = TaskSrActive,
            if
                _TaskId /= TaskId ->
					handle(30500, Status, []),
                    [0];
                true ->
                    case lib_server_dict:task_sr_trigger() of
                        [] ->
                            lib_task_sr:task_sr_trigger(Status, TaskId, Color),
                            [1];
                        _ ->
                            [4]
                    end
            end
    end,
    %%io:format("PL:~p~n",[[?MODULE,?LINE,Result]]),
    if
        Result =:= 1 ->
	    lib_qixi:update_player_task(Status#player_status.id, 2),
            mod_daily:increment(Status#player_status.dailypid, Status#player_status.id, 5000020),
            TriggerDaily1 = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000020),
            lib_server_dict:task_sr_rf_count({TriggerDaily1,0}),
            SQL1 = io_lib:format("replace into task_sr_daily (role_id, daily_times, refresh_count) values (~p,~p,~p)", [Status#player_status.id, TriggerDaily1, 0]),      
            db:execute(SQL1),
            {ok, BinData} = pt_305:write(30503, [Result, TriggerDaily1]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData),

			%% 触发任务
			NewRS1 =
			case lib_task:trigger_special(TaskId, Status) of
					{true, NewRS} ->
						NewRS;
					false ->
						Status
			end,
            {ok, NewRS1};
        true ->
            TriggerDaily1 = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000020),
            {ok, BinData} = pt_305:write(30503, [Result, TriggerDaily1]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData)
    end;

handle(_Cmd, _PlayerStatus, _Data) ->
    {error, bad_request}.

%% 刷新颜色
%% @param Status 
%% @param ColorTarget 目标颜色
refresh(Status, ColorTarget) ->
    GoodsTypeId = data_task_sr:get_task_config(refresh_goods, []),
    Dict = lib_goods_dict:get_player_dict(Status),
    GoodsInfo = lib_goods_util:get_goods_by_type(Status#player_status.id, GoodsTypeId, ?GOODS_LOC_BAG, Dict),
    Go = Status#player_status.goods,
    if
        GoodsInfo /= [] ->
            [GoodsId, GoodsPlayerId, GoodsLevel] = [GoodsInfo#goods.goods_id, GoodsInfo#goods.player_id, GoodsInfo#goods.level],
            if   % 物品不归你所有
                GoodsPlayerId /= Status#player_status.id ->
                    [3, Status, 0, 0];
                 % 你级别不够
                Status#player_status.lv < GoodsLevel ->
                    [4, Status, 0, 0];
                true ->
                    case gen_server:call(Go#status_goods.goods_pid, {'delete_one_norefresh', GoodsId, 1}) of
                        1 ->
                            lib_task_sr:refresh_task_sr(Status, ColorTarget, Status#player_status.task_sr_colour),
                            case lib_server_dict:task_sr_active() of
                                {TaskId, Color} ->
                                    [1, Status, TaskId, Color];
                                _ ->
                                    [5, Status, 0, 0]
                            end;                        
                        _GoodsModuleCode ->
                            [0, Status, 0, 0]
                    end
            end;
        true -> 
            [6, Status, 0, 0]
%%             Cost = data_task_sr:get_refresh_cost(Status#player_status.lv),
%%             if
%%                 Status#player_status.coin + Status#player_status.bcoin < Cost ->
%%                     [2, Status, 0, 0];
%%                 true ->
%%                     NewStatus = lib_goods_util:cost_money(Status, Cost, coin),
%% 					log:log_consume(pl_refresh, coin, Status, NewStatus, "pl refresh"),                    
%%                     case lib_task_sr:refresh_task_sr(NewStatus, ColorTarget) of
%%                         true ->
%%                             case lib_server_dict:task_sr_active() of
%%                                 {TaskId, Color} ->
%%                                     [1, NewStatus, TaskId, Color];
%%                                 _ ->
%%                                     [5, NewStatus, 0, 0]
%%                             end;
%%                         _ ->
%%                             [5, NewStatus, 0, 0]
%%                     end
%%             end
    end.

%% 刷新到橙色
refresh_orange(Status) ->
    [Result, TaskId, Color] = 
	case lib_task_sr:refresh_task_sr(Status, 0, Status#player_status.task_sr_colour) of
        true ->
             case lib_server_dict:task_sr_active() of
                  {_TaskId, _Color} ->
                      [1, _TaskId, _Color];
                  _ ->
                      [5, 0, 0]
             end;
        _ ->
              [5, 0, 0]
	end,
    if
        Result /= 1 ->
            [Result, TaskId, Color];
        Color =:= 4 ->
            [Result, TaskId, Color];
        true ->
            refresh_orange(Status)
   end.

%% 刷新到指定颜色[ 未超过保底次数随机刷，超过保底次数直接指定颜色]
%% @param RefreshCount 已递归刷新次数
%% @param Status
%% @param ColorTarget 目标颜色
refresh_color(RefreshCount, Status, ColorTarget) ->
	RefreshLim = data_task_sr:get_refresh_lim(ColorTarget),
	[Result, Status2, TaskId, _Color] =
	case RefreshCount >= RefreshLim  andalso ColorTarget =:=4 of
		 true ->
			refresh(Status, ColorTarget);
		 false ->			
			 refresh(Status, 0)
	end,	 
    if
        Result /= 1 ->
            [Result, Status2, TaskId, _Color,RefreshCount+1];
        _Color >= ColorTarget ->
%% 			case ColorTarget =:= 4 of
%% 				true ->
%% 					CountLim = 
%% 					if 
%% 						Status#player_status.lv =<49 ->
%% 							util:rand(5,15);
%% 						Status#player_status.lv =<59 ->
%% 							util:rand(8,18);
%% 						true ->
%% 							util:rand(15,25)
%% 					end,					
%% 					%% 刷新到橙色,扣除少扣的道具或铜币
%% 					case CountLim-RefreshCount>0 of
%% 						true ->
%% 							GoodsTypeId = data_task_sr:get_task_config(refresh_goods, []),	
%% 							GoodNum =lib_goods_info:get_goods_num(Status2, GoodsTypeId, 0),							
%% 							RemainCount1 = CountLim-RefreshCount,
%% 							case  GoodNum>0 of
%% 								true ->									
%% 									case GoodNum>=RemainCount1 of
%% 										true ->
%% 											NeedGoods = RemainCount1,
%% 											NeedCoin = 0;
%% 										false ->
%% 											NeedGoods = GoodNum,
%% 											NeedCoin = RemainCount1-GoodNum
%% 									end;
%% 								false ->
%% 									NeedGoods = 0,
%% 									NeedCoin = RemainCount1
%% 							end,
%% 							%% 优先扣除平乱令
%% 							case NeedGoods>0 of
%% 								true ->									
%% 									Go = Status2#player_status.goods,						
%% 									gen_server:call(Go#status_goods.goods_pid,{'delete_one_norefresh', GoodsTypeId, NeedGoods});									
%% 								false ->
%% 									skip
%% 							end,
%% 							%% 平乱令不够,扣除铜币
%% 							case NeedCoin>0 of
%% 								true ->
%% 									NCoin = Status2#player_status.coin + Status2#player_status.bcoin,
%% 									Cost = data_task_sr:get_refresh_cost(Status2#player_status.lv),
%% 									case NCoin< NeedCoin*Cost of
%% 										true ->
%% 											NeedCost = NCoin;
%% 										false ->
%% 											NeedCost = NeedCoin*Cost
%% 									end,									
%% 									NewStatus = lib_goods_util:cost_money(Status2, NeedCost, coin),
%% 									log:log_consume(pl_refresh, coin, Status2, NewStatus, "pl refresh lim");			
%% 								false ->
%% 									NewStatus = Status2
%% 							end;							
%% 						false ->
%% 							NewStatus = Status2
%% 					end;
%% 				false ->
%% 					NewStatus = Status2
%% 			end,			
            [Result, Status2, TaskId, _Color,RefreshCount+1];
        true ->			
            refresh_color(RefreshCount+1, Status2, ColorTarget)
    end.
