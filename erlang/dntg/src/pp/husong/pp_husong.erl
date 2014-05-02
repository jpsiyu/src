%%%--------------------------------------
%%% @Module  : pp_husong
%%% @Author  : zhenghehe
%%% @Created : 2010.12.08
%%% @Description: 护送模块
%%%--------------------------------------
-module(pp_husong).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("def_goods.hrl").
-include("goods.hrl").
-include("task.hrl").

%% 刷新护送NPC颜色  
handle(46000, PlayerStatus, [Type, TaskId]) ->
    Hs = PlayerStatus#player_status.husong,
    Vip = PlayerStatus#player_status.vip,
    case (Hs#status_husong.husong == 1) orelse (Type == 1 andalso Vip#status_vip.vip_type == 0)of
        false ->
            HusongColor = Hs#status_husong.husong_npc,
            [Result, Status2, C2] = 
            if
                HusongColor == 5 -> [5, PlayerStatus, 0];
                true ->
                    case Type of
                        0 -> %% 物品普通刷新
                            GoodsTypeId = data_yunbiao:get_yunbiao_config(refresh_goods, []),
                            GoodsNum = mod_other_call:get_goods_num(PlayerStatus, GoodsTypeId, 0),
                            if
                                GoodsNum =< 0 -> [2, PlayerStatus, 0]; %% 数量不足
                                true -> 
                                    Go = PlayerStatus#player_status.goods,
                                    case gen_server:call(Go#status_goods.goods_pid, {'delete_more', GoodsTypeId, 1}) of
                                        1 ->
                                            log:log_throw(beauty_refresh, PlayerStatus#player_status.id, 0, GoodsTypeId, 1, 0, 0),
                                            C = case lists:member(TaskId, ?XS_HUSONG_TASK) of
                                                true ->
                                                    5;
                                                false ->
                                                    data_yunbiao:refresh_husong_npc(HusongColor, PlayerStatus#player_status.lv)
                                            end,
                                            NewStatus = PlayerStatus#player_status{husong=Hs#status_husong{husong_npc = C}},
                                            lib_husong:set_husong_npc(NewStatus#player_status.id, C),
                                            [1, NewStatus, C];
                                        _ -> [0, PlayerStatus, 0]
                                    end
                            end;
                        _ -> %% 物品一键到最高级
							case HusongColor >= Type of
								true ->
									[0, PlayerStatus, 0];
								false ->
                                    refresh_to_color(PlayerStatus)
							end
                    end
            end,
            {ok, BinData} = pt_460:write(46000, [Result, C2]),
            lib_server_send:send_to_sid(Status2#player_status.sid, BinData),
            {ok, husong, Status2};
        true ->
            ok
    end;

%% 释放护送技能
handle(46001, PlayerStatus, [SkillId]) ->
    HS = PlayerStatus#player_status.husong,
    [Trigger0, Trigger1, Trigger2] = HS#status_husong.hs_skill_trigger,
    MaxinumSkillTrigger = data_yunbiao:get_yunbiao_config(maxinum_skill_trigger, []),
    CanTrigger = 
    case SkillId of
        0 ->
            Trigger0 < MaxinumSkillTrigger;
        1 ->
            Trigger1 < MaxinumSkillTrigger;
        2 ->
            Trigger2 < MaxinumSkillTrigger;
        _ ->
            false
    end,
    case CanTrigger of
        true ->
            NowTime = util:unixtime(),
            [_, Val, Time] = data_yunbiao:get_skill(SkillId),
            NewHsBuff = [[SkillId,Val,NowTime,Time]|HS#status_husong.hs_buff],
            HS1 = HS#status_husong{ hs_buff=NewHsBuff },
            PS1 = PlayerStatus#player_status{ husong=HS1 },
            Add = lib_husong:count_player_speed(lib_player:count_player_attribute(PS1)),
            Speed = PS1#player_status.speed,
            PS2 = PS1#player_status{ speed=Speed+Add },
            lib_player:send_attribute_change_notify(PS2, 1),
            {ok, BinData1} = pt_120:write(12082, [2, PS2#player_status.id, PS2#player_status.platform, PS2#player_status.server_num, PS2#player_status.speed]),
            lib_server_send:send_to_area_scene(PS2#player_status.scene, PS2#player_status.x, PS2#player_status.y, BinData1),
            {ok, BinData} = pt_460:write(46001, [1]),
            lib_server_send:send_to_sid(PS2#player_status.sid, BinData),
            {ok, PS2};
        false ->
            {ok, BinData} = pt_460:write(46001, [0]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
    end;

%% 护送技能同步
handle(46002, PlayerStatus, _) ->
    PS1 = lib_husong:skill_timeout_process(PlayerStatus),
    Add = lib_husong:count_player_speed(lib_player:count_player_attribute(PS1)),
    Speed = PS1#player_status.speed,
    PS2 = PS1#player_status{ speed=Speed+Add },
    lib_player:send_attribute_change_notify(PS2, 1),
    {ok, BinData1} = pt_120:write(12082, [2, PS2#player_status.id, PS2#player_status.platform, PS2#player_status.server_num, PS2#player_status.speed]),
    lib_server_send:send_to_area_scene(PS2#player_status.scene, PS2#player_status.x, PS2#player_status.y, BinData1),
    {ok, PS2};

%% 被劫镖求救信号
handle(46003, PlayerStatus, _) ->
    {ok, BinData} = 
    case lib_husong:send_help(PlayerStatus) of
        true -> pt_460:write(46003, [1]); %%发送信号成功   
        no_guild    -> pt_460:write(46003, [2]);    %%无帮派
        false       -> pt_460:write(46003, [0])     %%发送失败
    end,
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);

%% 接收求救信号传送
handle(46004, PlayerStatus, [SceneId, X, Y]) ->
	case PlayerStatus#player_status.copy_id =:= 0 of
		false ->
			{ok, BinData0} = pt_120:write(12005, [0, 0, 0, data_yunbiao_text:get_transport(2), 0]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData0),
			ok;
		true ->
            %% 沙滩和监狱不能传送
			case PlayerStatus#player_status.scene =:= 231 orelse PlayerStatus#player_status.scene =:= 998 of
				true ->
					{ok, BinData0} = pt_120:write(12005, [0, 0, 0, data_yunbiao_text:get_transport(2), 0]),
            		lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData0),
					ok;
				false ->
					lib_husong:transport(PlayerStatus, [SceneId, X, Y])
			end
	end;
    
%% 触发护送奖励
handle(46005, PlayerStatus, [_Mul]) ->
    Daily_Times = mod_daily_dict:get_count(PlayerStatus#player_status.id, 5000031),
	case Daily_Times >= 4 of
		false ->
			mod_daily_dict:increment(PlayerStatus#player_status.id, 5000031),
		    {Exp, Coin, BCoin, Is_bigreward} = lib_husong:trigger_reward(PlayerStatus),
		    HS = PlayerStatus#player_status.husong,
		    Hs1 = HS#status_husong{husong=0, husong_start_at=0, husong_lv = 0, husong_pt=0,hs_buff=[],hs_skill_trigger=[0,0,0],husong_npc=1},
			NewPlayerStatus = PlayerStatus#player_status{husong = Hs1},
		    put("husong_reward", {Exp, Coin, BCoin}),
			put("husong_is_bigreward", Is_bigreward),
		    case Is_bigreward of
				0 -> 
					{ok, BinData} = pt_460:write(46005, [Exp, Coin, BCoin]);
				1 -> 
					{ok, BinData} = pt_460:write(46005, [Exp div 2, Coin div 2, BCoin div 2])
			end,
		    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
			{ok, NewPlayerStatus};
		true ->
			ok
	end;

%% 获得护送奖励
handle(46006, PlayerStatus, _) ->
    Daily_Times = mod_daily_dict:get_count(PlayerStatus#player_status.id, 5000032),
	case Daily_Times >= 4 of
		false ->
			mod_daily_dict:increment(PlayerStatus#player_status.id, 5000032),
		    NewPs1 = case get("husong_reward") of
		        undefined ->
		            {ok, BinData} = pt_460:write(46006, [0]),
		            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
					PlayerStatus;
		        {Exp,Coin,Bcoin} ->
					case get("husong_is_bigreward") of
						1 -> %% 选择到大奖
							{ok, BinData} = pt_460:write(46006, [2]),
				            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
							case lib_npc:get_scene_by_npc_id(30001) of
								[SceneId, X, Y, _] ->
									lib_chat:send_TV({all}, 0, 2
										,[huSongDoubleExp
											,PlayerStatus#player_status.id
											,PlayerStatus#player_status.realm
											,PlayerStatus#player_status.nickname
											,PlayerStatus#player_status.sex
											,PlayerStatus#player_status.career 
											,PlayerStatus#player_status.image
											,SceneId
											,X
											,Y+3
										]);
								[] -> skip
							end;							
						_->%% 选择到普通奖
							{ok, BinData} = pt_460:write(46006, [1]),
				            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
					end,		            
		            %NewStatus1 = lib_player:add_bcoin(PlayerStatus, Bcoin),
		            NewStatus2 = lib_player:add_coin(PlayerStatus, Coin+Bcoin),
		            NewStatus3 = lib_player:add_exp(NewStatus2, Exp),					
					lib_player:refresh_client(NewStatus3#player_status.id, 1), %% 更新背包					
					Txt = data_yunbiao_text:get_intercept(19),
					case Coin > 0 of
						true ->
							log:log_produce(task, coin, PlayerStatus, NewStatus3, Txt);
						false ->
							log:log_produce(task, bcoin, PlayerStatus, NewStatus3, Txt)
					end,		            
		            erase("husong_reward"),
					erase("husong_is_bigreward"),
		            NewStatus3
		    end,
			HS = NewPs1#player_status.husong,
		    Hs1 = HS#status_husong{husong=0, husong_start_at=0, husong_lv = 0, husong_pt=0,hs_buff=[],hs_skill_trigger=[0,0,0], husong_npc=1},
			NewPlayerStatus = NewPs1#player_status{husong = Hs1},
			{ok, NewPlayerStatus};
		true ->
			ok
	end;
    
%% 查询护送奖励信息
handle(46007, PlayerStatus, _) ->
    {_, Hp, Rewards,_,_} = data_yunbiao:get_husong_phase_config(PlayerStatus#player_status.lv),
    {ok, BinData} = pt_460:write(46007, [Hp, Rewards]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
    ok;

%% 护送美女任务剩余时间
handle(46008, PlayerStatus, _) ->
    case lib_task:get_task_bag_id_list_kind(PlayerStatus#player_status.tid, 4) of
        [R|_] -> 
            LelfTime = util:unixtime() - R#role_task.trigger_time,
            case LelfTime =< ?HS_TIME_OUT of
                true ->
                    {ok, BinData} = pt_460:write(46008, [?HS_TIME_OUT - LelfTime]),
                    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
                false -> 
                    pp_task:handle(30005, PlayerStatus, [R#role_task.task_id])
            end;
        [] ->
            {ok, BinData} = pt_460:write(46008, [0]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
    end;

%% 获取双倍护送剩余时间
handle(46010, PlayerStatus, []) -> 
    case lib_husong:is_double(online) of
        true -> 
            Time = lib_husong:guoyun_left_time(),
            {ok, BinData} = pt_460:write(46010, [Time]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
        false ->
            {ok, BinData} = pt_460:write(46010, [0]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
    end;

%% 获取初始NPC颜色
handle(46011, PlayerStatus, []) -> 
    HS = PlayerStatus#player_status.husong,
    case lib_husong:get_husong_ref(PlayerStatus#player_status.id) of
        1 ->
			case data_yunbiao:is_probability_100_day() of
				true -> C = 5;
				false -> C = lib_husong:get_husong_npc(PlayerStatus#player_status.id)
			end,
            PlayerStatus1 = PlayerStatus#player_status{husong=HS#status_husong{husong_npc = C}},
            {ok, BinData} = pt_460:write(46011, [C]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
            {ok, PlayerStatus1};
        0 ->
            C = data_yunbiao:receive_husong_npc(),
            lib_husong:set_husong_ref(PlayerStatus#player_status.id, 1),
            lib_husong:set_husong_npc(PlayerStatus#player_status.id, C),
            PlayerStatus1 = PlayerStatus#player_status{husong=HS#status_husong{husong_npc = C}},
            {ok, BinData} = pt_460:write(46011, [C]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
            {ok, PlayerStatus1};
		_ ->
			ok
    end;

%% 错误处理
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_husong no match", []),
    {error, "pp_husong no match"}.

%% 刷新到指定颜色
refresh_to_color(#player_status{lv=Lv, husong=Hs} = PlayerStatus) -> 
   NeedGoodsNum = if
       Lv =< 39 -> 10;
       Lv =< 54 -> 15;
       Lv =< 66 -> 20;
       Lv =< 78 -> 20;
       true     -> 20
   end,
   GoodsTypeId = data_yunbiao:get_yunbiao_config(refresh_goods, []),
   GoodsNum = mod_other_call:get_goods_num(PlayerStatus, GoodsTypeId, 0),
   if
       GoodsNum < NeedGoodsNum -> [2, PlayerStatus, 0]; %% 数量不足
       true -> 
           Go = PlayerStatus#player_status.goods,
           case gen_server:call(Go#status_goods.goods_pid, {'delete_more', GoodsTypeId, 1}) of
               1 ->
                   log:log_throw(beauty_refresh, PlayerStatus#player_status.id, 0, GoodsTypeId, 1, 0, 0),
                   C = 5,
                   NewStatus = PlayerStatus#player_status{husong=Hs#status_husong{husong_npc = C}},
                   lib_husong:set_husong_npc(NewStatus#player_status.id, C),
                   [1, NewStatus, C];
               _ -> [0, PlayerStatus, 0]
           end
   end.
