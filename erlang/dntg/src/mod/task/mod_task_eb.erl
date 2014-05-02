%%%------------------------------------
%%% @Module  : mod_task_eb
%%% @Author  : zhenghehe
%%% @Created : 2010.06.13
%%% @Description: 皇榜任务
%%%------------------------------------
-module(mod_task_eb).
-behaviour(gen_server).
-export([start/0, stop/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).
-include("server.hrl").
-include("def_goods.hrl").
-include("goods.hrl").
-define(GOLD_REFRESH_COST, 10).

start() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

init([]) ->
	{ok, []}.


%% 使用揭榜令刷新
jbl_refresh(Status) ->
    GoodsTypeId = data_task_eb:get_task_config(refresh_goods, []),
   	Dict = lib_goods_dict:get_player_dict(Status),
   	GoodsInfo = lib_goods_util:get_goods_by_type(Status#player_status.id, GoodsTypeId, ?GOODS_LOC_BAG, Dict),
   	Go = Status#player_status.goods,
	case GoodsInfo /= [] of
		true ->
			[GoodsId, GoodsPlayerId, GoodsLevel] = [GoodsInfo#goods.goods_id, GoodsInfo#goods.player_id, GoodsInfo#goods.level],
           	if   % 物品不归你所有
               	GoodsPlayerId /= Status#player_status.id ->
                   	[3, Status];
                 % 你级别不够
                Status#player_status.lv < GoodsLevel ->
                    [4, Status];
                true ->
                   	case gen_server:call(Go#status_goods.goods_pid, {'delete_more', GoodsId, 1}) of
                        1 ->
                            ok = lib_task_eb:gold_refresh_task_eb(Status),  
                          	[1, Status];
                       	_GoodsModuleCode ->
                            [5, Status]
                    end
           	 end;
		false ->
			[5, Status]
	end.


%% 立即刷新皇榜任务
gold_refresh_task(Status, IsAuto) ->
	case IsAuto of
		0 ->%% 使用揭榜令刷新
            jbl_refresh(Status);			
		1 ->%% 揭榜令不足,自动元宝刷新
            GoodsTypeId = data_task_eb:get_task_config(refresh_goods, []),
            Num =  lib_goods_info:get_goods_num(Status, GoodsTypeId, 0),
            case Num <1 of
                true ->
                    Cost = ?GOLD_REFRESH_COST,
                    if
                        Status#player_status.gold < Cost ->
                            [2, Status];
                        true ->
                            NewStatus = lib_goods_util:cost_money(Status, Cost, gold),
		                    log:log_consume(hb_refresh, gold, Status, NewStatus, "hb refresh"),
                            lib_player:refresh_client(NewStatus#player_status.id, 2),
                            ok = lib_task_eb:gold_refresh_task_eb(NewStatus),
                            [1, NewStatus]
                    end;
                false ->
                    jbl_refresh(Status)
            end;
		_ ->
			[0, Status]
	end.
     
%% 接受皇榜任务
trigger_task(Status, TaskId) ->
    TriggerTaskEbNum = lib_task_eb:get_trigger_task_eb_num(),
    [PlayerId, Level] = [Status#player_status.id, Status#player_status.lv],
    TriggerTaskEbDaily = mod_daily:get_count(Status#player_status.dailypid, PlayerId, 5000010),
    InActive = lib_dict:find(active_task_eb, TaskId),
    MinTriggerLv = data_task_eb:get_task_config(min_trigger_lv, []),
    MaxinumTriggerDaily = data_task_eb:get_task_config(maxinum_trigger_daily, []),
    MaxinumTriggerEverytime = data_task_eb:get_task_config(maxinum_trigger_everytime, []),
    if
        %% 玩家等级不足
        Level < MinTriggerLv ->
            [2, Status];
        %% 每天最多可接受20个
        TriggerTaskEbDaily >= MaxinumTriggerDaily ->
            [3, Status];
        %% 每次最多可接受2个皇榜任务
        TriggerTaskEbNum >= MaxinumTriggerEverytime ->
            [4, Status];
        %% 接取的任务不在可接任务列表上
        InActive /= true ->
            [0, Status];
        true ->
			%% 触发任务
			NewStatus =
			case lib_task:trigger_special(TaskId, Status) of
					{true, NewRS} ->					
						lib_task_eb:trigger_task(Status, TaskId),
						lib_qixi:update_player_task(PlayerId, 3),
						mod_daily:increment(Status#player_status.dailypid, PlayerId, 5000010),
						pp_task_eb:handle(30404, NewRS, []),
						NewRS;
					false ->
						Status
			end,
            [1, NewStatus]
    end.

handle_call({set_active_task_eb, [PlayId,ActiveTaskEbs]}, _From, State) ->
	lib_dict:start("active_task_eb_" ++ integer_to_list(PlayId), 1),
	Key = "active_task_eb_" ++ integer_to_list(PlayId),
	lib_dict:erase(Key),
	if 
		length(ActiveTaskEbs) >0 ->
			lists:foreach(fun({TaskId,Color}) -> lib_dict:update(Key, {TaskId,Color}) end, ActiveTaskEbs);
		true -> skip
    end,
	{reply, ok, State};

handle_call({get_active_task_eb, [PlayId]}, _From, State) ->  
	Key = "active_task_eb_" ++ integer_to_list(PlayId),
	Reply = lib_dict:get(Key),
	{reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
    
