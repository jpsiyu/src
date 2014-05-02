%%%--------------------------------------
%%% @Module  : pp_task_zyl
%%% @Author  : hekai
%%% @Created : 2012.07.31
%%% @Description:  诛妖令模块
%%%--------------------------------------
-module(pp_task_zyl).
-export([handle/3]).
-include("server.hrl").
-include("goods.hrl").
-include("def_goods.hrl").

%% 发布列表
handle(30700, Status, _) ->
	MinTriggerLv = data_task_zyl:get_task_config(min_trigger_lv, []),
	MaxinumTriggerDaily = data_task_zyl:get_task_config(maxinum_trigger_daily, []),
    TriggerDaily = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000040), 
	LeftPubDaily = MaxinumTriggerDaily - TriggerDaily,
	Level = Status#player_status.lv,
	Lv = Level div 10,
	Color = [1,2,3,4],		
	%% 诛妖令奖励
	Zyl_Reward =
    case Level >= MinTriggerLv of
		true -> [[Type,data_task_zyl:get_zyl_coin(Lv, Type),data_task_zyl:get_zyl_exp(Lv, Type)] ||Type <-Color];
		false -> [[Type, 0, 0] ||Type <-Color]
	end,	
	%% 获取当前拥有诛妖帖数量、已发布、领取数量
	Zyl_num = lib_task_zyl:get_num(Status),
    {ok, BinData} = pt_307:write(30700, [Zyl_Reward, Zyl_num, LeftPubDaily]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);	

%% 诛妖榜列表
handle(30701, Status, _) ->
	MinTriggerLv = data_task_zyl:get_task_config(min_trigger_lv, []),
	MaxinumTriggerDaily = data_task_zyl:get_task_config(maxinum_trigger_daily, []),
    TriggerDaily = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000090), 
	LeftPubDaily = MaxinumTriggerDaily - TriggerDaily,
	Level = Status#player_status.lv,
	Lv = Level div 10,
	Color = [1,2,3,4], 	
	%% 诛妖榜现有数量
    Zyl_has_num = 
    case Level >= MinTriggerLv of
		true -> [[Type1, lib_task_zyl:get_zyl_now(Type1), data_task_zyl:get_zyl_coin(Lv, Type1),data_task_zyl:get_zyl_exp(Lv, Type1)] ||Type1 <-Color];
		false -> [[Type1, lib_task_zyl:get_zyl_now(Type1), 0, 0] ||Type1 <-Color]
	end,	 
	%% 今日领取诛妖令数量
	Zyl_get_num = [[Type2, lib_task_zyl:get_daily(Status,Type2)] ||Type2 <-Color],
    {ok, BinData} = pt_307:write(30701, [Zyl_has_num, Zyl_get_num, LeftPubDaily]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);	

%% 发布诛妖令
handle(30702, Status, [Type]) when Type > 0 ->
	Level = Status#player_status.lv,
    MinTriggerLv = data_task_zyl:get_task_config(min_trigger_lv, []),
    MaxinumTriggerDaily = data_task_zyl:get_task_config(maxinum_trigger_daily, []),
    TriggerDaily = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000040), 
    My_color = lib_task_zyl:dict_get(zyl_my_color),
    NumSum = length(My_color),
	_Date_time = util:unixdate(),
    _Now_time = util:unixtime(),
	[Result,PS] =
	if
		Level < MinTriggerLv ->
			[5, Status];
%%         (Now_time < Date_time + 1*60*60)  orelse  (Now_time > Date_time + 23*60*60) ->
%% 			[4, Status];
        TriggerDaily >= MaxinumTriggerDaily ->
			[3, Status];
        NumSum >= 1 ->
            [9, Status];
		true ->
            GoodsTypeId = data_task_zyl:get_task_config("zyl_id_"++integer_to_list(Type), []),
			Dict = lib_goods_dict:get_player_dict(Status),
            GoodsInfo = lib_goods_util:get_goods_by_type(Status#player_status.id, GoodsTypeId, ?GOODS_LOC_BAG, Dict),
			case GoodsInfo /=[] of
				true ->
					  Go = Status#player_status.goods,
                      ResultCost = if Type =:= 1 ->
                             gen_server:call(Go#status_goods.goods_pid, {'delete_more', GoodsInfo#goods.goods_id, 1});
                         Type =:= 2 ->
                             gen_server:call(Go#status_goods.goods_pid, {'delete_more', GoodsInfo#goods.goods_id, 3});
                         Type =:= 3 ->
                             gen_server:call(Go#status_goods.goods_pid, {'delete_more', GoodsInfo#goods.goods_id, 7});
                         true ->
                             gen_server:call(Go#status_goods.goods_pid, {'delete_more', GoodsInfo#goods.goods_id, 10})
                      end,
                      case ResultCost of
		  			  %%case gen_server:call(Go#status_goods.goods_pid, {'delete_more', GoodsInfo#goods.goods_id, 1}) of
                        1 ->
                            lib_task_zyl:publish_zyl(Status, Type),													    
							[1, Status];
                        2 -> [2, Status];
						3 -> [6, Status];
						4 -> [8, Status];
						6 -> [2, Status];                            
						7 -> [7, Status];
						_ -> [0, Status]
           			  end;
				false ->
					 [2, Status]
		    end
	end,    
   	{ok, BinData} = pt_307:write(30702, Result),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    {ok, PS};


%% 领取诛妖令
handle(30703, Status, [Type]) ->
	Level = Status#player_status.lv,	
    MinTriggerLv = data_task_zyl:get_task_config(min_trigger_lv, []),
    MaxinumTriggerDaily = data_task_zyl:get_task_config(maxinum_trigger_daily, []),
    TriggerDaily = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000090), 
	My_color = lib_task_zyl:dict_get(zyl_my_color),
	Is_exist = lists:member(Type, My_color),
	Zyl_now = lib_task_zyl:get_zyl_now(Type),
	_Date_time = util:unixdate(),
    _Now_time = util:unixtime(),
	[Result,PS] =
	if
		Level < MinTriggerLv ->
			[5, Status];
%%         (Now_time < Date_time + 1*60*60)  orelse (Now_time > Date_time + 23*60*60) ->
%% 			[4, Status];
		TriggerDaily >= MaxinumTriggerDaily ->
			[3, Status];
		Zyl_now =<0 -> %%判断是否有该品质诛妖贴可领取
			[7, Status];        
        Is_exist =:= true ->
			[2, Status];
		true ->						
			%% 触发任务
			TaskZyl = data_task_zyl_lv:get_ids(Level),
			[Msg, Tid] =
			case  TaskZyl /= [] of
				true ->
					%% 是否可接
					[TaskId] =[Id||[Color, Id] <-TaskZyl,Color =:= Type],
                    [1, TaskId];                    
				%	case lib_task:in_active(Status#player_status.tid, TaskId) of
				%		true -> [1, TaskId];
				%		false -> 
                %            io:format("zyt 11 ~p~n", [TaskId]),
                %            [0, 0]
				%	end;
				false -> [6, 0]
			end,
			case Msg =:= 1 of
				true -> 
					%% Publish_Role_id为0时,系统自动转品质
					Publish_Role_id = lib_task_zyl:get_zyl(Status, Type, Tid),					
					case Publish_Role_id=/=null of
						true ->
							[ResultCode, Status2] = 
							case lib_task:trigger_special(Tid, Status) of
								{true, NewRS} ->
									[1,NewRS];
								false ->
									[0,Status]
							end;
						false ->
							handle(30701, Status, []),
							ResultCode =7, Status2=Status
					end,
					%% 诛妖令被领取奖励、通知
					case ResultCode=:=1 andalso Publish_Role_id =/=0 of
						true ->								
							Player_lv = lib_task_zyl:get_palyer_lv(Publish_Role_id),
							Lv = Player_lv div 10,
							Bcoin = data_task_zyl:get_zyl_coin(Lv, Type),
							Exp =data_task_zyl:get_zyl_exp(Lv, Type),
							case lib_player:is_online_global(Publish_Role_id)  of
								true ->
									%%Pub_PS = lib_player:get_player_info(Publish_Role_id),
									%% 在线用户诛妖贴被领取奖励
									lib_task_zyl:online_reward(Bcoin, Exp, Publish_Role_id),
									%% 更新用户诛妖帖被领数量缓存
									lib_player:rpc_cast_by_id(Publish_Role_id, lib_task_zyl, update_bget, [Type]),
									{ok, Bindata} = pt_307:write(30704, [Bcoin, Exp]),
									%% 发送被领取通知
									lib_server_send:send_to_uid(Publish_Role_id, Bindata);
								false ->
									%% 离线用户诛妖贴被领取奖励 
									lib_task_zyl:outline_reward(Bcoin, Exp, Publish_Role_id)
							end;
						false -> skip
            		 end;
				false -> ResultCode=Msg, Status2=Status
			end,			
           [ResultCode,Status2]
	end,
	{ok, BinData} = pt_307:write(30703, Result),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    {ok, PS}.
			



	


	
