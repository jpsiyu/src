%%------------------------------------------------------------------------------
%% @Module  : mod_dungeon_base
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.27
%% @Description: 副本基础服务
%%------------------------------------------------------------------------------

-module(mod_dungeon_base).
-export([handle_call/3, handle_info/2]).

-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").


%% --------------------------------- 内部函数 ----------------------------------

%% 检查进入副本
%% 这里的SceneId是数据库的里的场景id，不是唯一id
handle_call({check_enter, SceneResId, Id, NowSceneId}, _From, State) ->   
    case lists:keyfind(SceneResId, 4, State#dungeon_state.scene_list) of
        false ->%%没有这个副本场景
            {reply, {false, data_dungeon_text:get_dungeon_text(1)}, State};   
        DunScene ->
			%1.场景是否可以进入.
			IsEnter = 
	            case DunScene#dungeon_scene.enable of
					true ->
                        {true, State};
					false ->
						%1.场景还没激活检查怪物是否全部杀死了.
                        AllMonCount = mod_scene_agent:apply_call(NowSceneId, lib_scene, get_scene_mon_num_by_kind, [NowSceneId, self(), 0]),
						case AllMonCount of
							%1.没打过一只怪先去上一层入口，长度是0.
							0 ->
								State1 = lib_dungeon:enable_action([SceneResId], State, NowSceneId),
                                {true, State1};
							%3.还有两只以上的怪物.
							_Count ->
			                    false
						end
				end,

			%2.进入场景.
			case IsEnter of
                {true, NewState1} ->
					%1.爬塔副本进入场景.
                    R = NewState1#dungeon_state.tower_state,
                    case R#tower_state.esid of
                        [] -> ok;
                        _ -> mod_tower_dungeon:tower_next_level(self(), Id, DunScene#dungeon_scene.sid, NowSceneId)
                    end,

					%2.飞行副本进入场景.
					lib_fly_dungeon:enter_scene(self(), Id, DunScene#dungeon_scene.sid, NowSceneId, State),

                    {SceneId, NewState2} = 
						case DunScene#dungeon_scene.id =/= 0 of
	                        true -> {DunScene#dungeon_scene.id, NewState1};   %%场景已经加载过
	                        false ->
								%%创建副本场景.
	                            case State#dungeon_state.type of
									%1.创建宠物副本.
	                                ?DUNGEON_TYPE_PET -> 
										mod_pet_dungeon:create_scene(SceneResId, NewState1);
									
									%2.创建经验副本.
									?DUNGEON_TYPE_EXP -> 
										mod_exp_dungeon:create_scene(SceneResId, self(), NewState1);
									
									%3.创建铜币副本.
									?DUNGEON_TYPE_COIN -> 
										lib_coin_dungeon:create_scene(SceneResId, self(), NewState1);

									%4.创建爬塔副本.
									?DUNGEON_TYPE_TOWER ->
										%1.爬塔副本怪物是地图编辑器生成的.
										{_SceneId, NewState3} = lib_dungeon:create_scene(SceneResId, NewState1),
										
										%2.爬塔副本创建宝箱.
										mod_tower_dungeon:create_scene(SceneResId, self(), NewState3);
									
									%5.皇家守卫军塔防副本.
	                                ?DUNGEON_TYPE_KINGDOM_RUSH -> 
										lib_kingdom_rush_dungeon:create_scene(SceneResId, NewState1);

									%6.多人皇家守卫军塔防副本.
	                                ?DUNGEON_TYPE_MULTI_KING -> 
										lib_multi_king_dungeon:create_scene(SceneResId, NewState1);

									%7.连连看副本.
	                                ?DUNGEON_TYPE_LIAN -> 
										lib_lian_dungeon:create_scene(SceneResId, NewState1);

									%8.飞行副本.
	                                ?DUNGEON_TYPE_FLY -> 
										lib_fly_dungeon:create_scene(SceneResId, NewState1);
                                    
                                    %9.energy精力装备副本
                                    ?DUNGEON_TYPE_DNTK_EQUIP ->
                                        lib_dungeon:create_scene(SceneResId, NewState1);
									
									%10.创建普通的副本场景. 
	                                _ -> 
										lib_dungeon:create_scene(SceneResId, NewState1) 
	                            end
	                    end,
                    {reply, {true, SceneId}, NewState2};
                false ->
                    {reply, {false, DunScene#dungeon_scene.tip}, State}
            end
    end;

%% 加入副本服务
handle_call({join, PlayerId, PlayerPid, DungeonDataPid}, _From, State) ->
    case lists:keyfind(PlayerId, 2, State#dungeon_state.role_list) of
        false -> 
            NewRL = State#dungeon_state.role_list ++ [#dungeon_player{id = PlayerId, 
																	  pid = PlayerPid, 
																	  dungeon_data_pid = DungeonDataPid}],
            {reply, true, State#dungeon_state{role_list = NewRL}};
        _ -> {reply, true, State}
    end;

%% 下线5分钟内归队再进副本
handle_call({join_online, Id, Pid, DungeonDataPid}, _From, State) ->
    %clear(role, DunPid),  %% 清除上个副本服务进程
    case lists:keyfind(Id, 2, State#dungeon_state.role_list) of
        false -> 
            %% 清理塔防副本特殊技能标记
            NewRL = State#dungeon_state.role_list ++ [#dungeon_player{id = Id, 
                    pid = Pid,
                    dungeon_data_pid = DungeonDataPid}],
            MaxCombo = case is_record(State#dungeon_state.coin_dun, coin_dun) of
                true -> State#dungeon_state.coin_dun#coin_dun.max_combo;
                false -> 0
            end,
            %case MaxCombo > 49 of
            %    true -> {} %mod_coin_dungeon:combo_buff_online(Pid, MaxCombo);
            %    false -> {reply, {true, State#dungeon_state{role_list = NewRL}};
            %end,
            {reply, {true, MaxCombo}, State#dungeon_state{role_list = NewRL}};
        _ -> {reply, {true, 0}, State}
    end;

%% 获取副本时间
handle_call({get_dungeon_time, SceneId, _PlayerId, _DailyPid}, _From, State) ->
    case lists:keyfind(SceneId, 4, State#dungeon_state.scene_list) of
        false ->
            {reply, false, State};   %%没有这个副本场景
        DunScene ->
            DD = data_dungeon:get(DunScene#dungeon_scene.did),
            Ltime = DD#dungeon.time + State#dungeon_state.time - util:unixtime(),
            Count = 0, %mod_daily:get_count(DailyPid, PlayerId, DunScene#dungeon_scene.did),
            case Ltime > 0 of
                true ->
                    {reply, {true, Ltime, Count}, State};
                false ->
                    {reply, {true, 0, Count}, State}
            end
    end;

%% 获取该副本id（第一个场景的资源id）
handle_call('get_begin_sid', _From, State) ->
    {reply, State#dungeon_state.begin_sid, State};

%% 获取特殊场景时间
handle_call({get_scene_time, SceneResId}, _From, State) ->
    case lists:keyfind(SceneResId, 4, State#dungeon_state.scene_list) of
        false ->
            {reply, false, State};   %%没有这个副本场景
        DunScene ->
            case DunScene#dungeon_scene.begin_time == out of
                true -> {reply, false, State};
                false ->
                    case DunScene#dungeon_scene.begin_time == 0 of
                        false -> 
                            Ltime = 300 + DunScene#dungeon_scene.begin_time - util:unixtime(),
                            case Ltime > 0 of
                                true ->
                                    {reply, {true, Ltime}, State};
                                false ->
                                    {reply, {true, 0}, State}
                            end;
                        true -> {reply, {true, 0}, State}
                    end
            end
    end;

%% 获取怪物的击杀统计.
handle_call({get_kill_count, SceneId}, _From, State) ->	
	Return = lib_dungeon:check_kill_count(SceneId, State#dungeon_state.kill_npc),
	{reply, Return, State#dungeon_state{kill_npc_flag = 1}}.
    
%% 将指定玩家传出副本,不保留个人信息副本进程不让进入
handle_info({quit, PlayerId, FromCode}, State) ->
    case lists:keyfind(PlayerId, 2, State#dungeon_state.role_list) of
        false -> {noreply, State};
        _ ->
            case lib_player:get_player_info(PlayerId) of
                PlayerStatus when is_record(PlayerStatus, player_status)->
					lib_dungeon:quit_reward(State, PlayerStatus, FromCode);
				%% 不在线
                _Other -> 
					ok
            end,
            %% 清理塔防副本特殊技能标记
            %erase("extend_skill"),
            {noreply, State#dungeon_state{role_list = lists:keydelete(PlayerId, 2, State#dungeon_state.role_list)}}
    end;

%% 设置退出的类型.
handle_info({set_logout_type, LogoutType}, State) ->
	{noreply, State#dungeon_state{logout_type = LogoutType}};

%% 设置是否发送副本通关记录.
handle_info({send_record, Flag}, State) ->
    {noreply, State#dungeon_state{is_send_record= Flag}};

%% 将指定玩家传出副本,不保留个人信息副本进程不让进入
handle_info({clear_role, RoleId}, State) ->
    case lists:keyfind(RoleId, 2, State#dungeon_state.role_list) of
        false -> {noreply, State};
        _ ->
            {noreply, State#dungeon_state{role_list = lists:keydelete(RoleId, 2, State#dungeon_state.role_list)}}
    end;

%% 将指定玩家传出副本,保留个人信息的副本进程还让进入
handle_info({out, Rid}, State) ->
    case lists:keyfind(Rid, 2, State#dungeon_state.role_list) of
        false -> {noreply, State};
        _ ->
            case lib_player:get_online_info_global(Rid) of
                [] -> ok;   %% 不在线
                R -> lib_dungeon:send_out(R, State)
            end,
            {noreply, State}
    end;

%% 关闭副本服务进程
handle_info(team_clear, State) ->
    F = fun(RX) -> 
				mod_server:set_dungeon_pid(RX#dungeon_player.pid, 0), 
				lib_dungeon:send_out(RX#dungeon_player.id, State) 
		end,
    [F(R)|| R <- State#dungeon_state.role_list],
    [mod_scene_agent:apply_cast(DunScene#dungeon_scene.id, mod_scene, clear_scene, 
								[DunScene#dungeon_scene.id, self()])|| DunScene <- State#dungeon_state.scene_list, 
																	   DunScene#dungeon_scene.id =/= 0],
    %% 清除组队模块的副本id缓存
    lib_team:set_dungeon_pid(State#dungeon_state.team_pid, none),
    MsgLen = get(msglen),
    put(msglen, [2|MsgLen]),
    {stop, normal, State};

%% 关闭副本服务进程
handle_info(role_clear, State) ->
    case is_pid(State#dungeon_state.team_pid) of
        true -> %% 有组队
            case length(State#dungeon_state.role_list) > 0 of  %% 判断队伍是否没有人了
                true ->
					%1.副本的人是否存在.
                    S = lib_dungeon:is_in_dungeon(State#dungeon_state.role_list, out),
                    case S =:= out of
                        true ->
                            [mod_scene_agent:apply_cast(DunScene#dungeon_scene.id, mod_scene, clear_scene, 
							    [DunScene#dungeon_scene.id, self()])|| DunScene <- State#dungeon_state.scene_list, 
								 DunScene#dungeon_scene.id =/= 0],
                            lib_team:set_dungeon_pid(State#dungeon_state.team_pid, none),
                            MsgLen = get(msglen),
                            put(msglen, [3|MsgLen]),
                            {stop, normal, State};
                        false->
                            {noreply, State}
                    end;
                false ->
                    %% 清除组队模块的副本id缓存
                    [mod_scene_agent:apply_cast(DunScene#dungeon_scene.id, mod_scene, clear_scene, 
					    [DunScene#dungeon_scene.id, self()])|| DunScene <- State#dungeon_state.scene_list, 
						DunScene#dungeon_scene.id =/= 0],
                    lib_team:set_dungeon_pid(State#dungeon_state.team_pid, none),
                    MsgLen = get(msglen),
                    put(msglen, [4|MsgLen]),
                    {stop, normal, State}
            end;
        false ->
            [mod_scene_agent:apply_cast(DunScene#dungeon_scene.id, mod_scene, clear_scene, 
			    [DunScene#dungeon_scene.id, self()])|| DunScene <- State#dungeon_state.scene_list, 
				DunScene#dungeon_scene.id =/= 0],
            MsgLen = get(msglen),
            put(msglen, [5|MsgLen]),
            {stop, normal, State}
    end;

%% 关闭副本服务进程并且踢出所有人
handle_info(close_dungeon, State) ->
    case is_pid(State#dungeon_state.team_pid) of
        true -> %% 有组队
            case length(State#dungeon_state.role_list) > 0 of 
                true ->
                    F = fun(RX) -> 
				            case lib_player:get_player_info(RX#dungeon_player.id) of   
				                PlayerStatus when is_record(PlayerStatus, player_status)->
									lib_dungeon:quit_reward(State, PlayerStatus, cd1);
								%% 不在线
								_Other ->
									ok
				            end
						end,
                    [F(R)|| R <- State#dungeon_state.role_list],
                    %% 清除组队模块的副本id缓存
                    lib_team:set_dungeon_pid(State#dungeon_state.team_pid, none);
                false ->
                    %% 清除组队模块的副本id缓存
                    lib_team:set_dungeon_pid(State#dungeon_state.team_pid, none),
                    MsgLen = get(msglen),
                    put(msglen, [1|MsgLen])
            end;
        false -> 
            case length(State#dungeon_state.role_list) > 0 of 
                true ->
                    F = fun(RX) ->
				            case lib_player:get_player_info(RX#dungeon_player.id) of   
				                PlayerStatus when is_record(PlayerStatus, player_status)->
									lib_dungeon:quit_reward(State, PlayerStatus, cd2);
								%% 不在线
								_Other ->
									ok								
				            end
						end,
                    [F(R)|| R <- State#dungeon_state.role_list];
                false -> ok  
			end
    end,
	
	%1.装备副本关闭定时器.
	case State#dungeon_state.type of 
	    ?DUNGEON_TYPE_TOWER ->		
			TowerState = State#dungeon_state.tower_state,
			CloseTimer = TowerState#tower_state.close_timer,
			if 
				is_reference(CloseTimer) ->
					erlang:cancel_timer(CloseTimer);
				true ->
					skip
			end;
		_ ->
			skip
	end,	

    [catch mod_scene_agent:apply_cast(DunScene#dungeon_scene.id, mod_scene, clear_scene, 
	    [DunScene#dungeon_scene.id, self()])|| DunScene <- State#dungeon_state.scene_list, 
        DunScene#dungeon_scene.id =/= 0],
    {stop, normal, State};

%% 接收杀怪事件
handle_info({kill_npc, EventSceneId, NpcIdList, BossType, MonAutoId, IsSkip}, State) ->
    %% TODO 杀的怪是否有用
    case lists:keyfind(EventSceneId, 2, State#dungeon_state.scene_list) of
        false ->
			{noreply, State};    %% 没有这个场景id
        DunScene ->
			%1.杀死的怪物是BOSS.					
			case BossType of
				0 -> skip;
				_ ->
                    %1.名人堂触发处理固定怪物id.
                    case lists:member(30115, NpcIdList) of
                        true ->
                            %1.触发名人堂：副本突击，第一个击杀指定的副本BOSS.
                            MergeTime   = lib_activity_merge:get_activity_time(),
                            AllPlayerId = [Player#dungeon_player.id||Player <- State#dungeon_state.role_list],
                            [mod_fame:trigger_copy(MergeTime, 1, NpcId, AllPlayerId)||NpcId <- NpcIdList];
                        false ->
                            skip
                    end,

					%2.剧情副本玩家大于等于40级杀死BOSS不加一.
					[Player2|_PlayerList] = State#dungeon_state.role_list,					
                    case State#dungeon_state.type of
                        ?DUNGEON_TYPE_STORY ->

                            %2.剧情副本杀死BOSS总次数才加一.
                            mod_dungeon_data:increment_total_count(Player2#dungeon_player.dungeon_data_pid, 
                                Player2#dungeon_player.id, 
                                State#dungeon_state.begin_sid);
                        _ ->
					 		skip
					end
			end,
			
			%2.设置武魂值.
			WHPT = lib_dungeon:set_whpt(BossType, NpcIdList, State),
			
			%1.检测副本的杀怪完成情况.
            {NewDSRL, UpdateScene} = lib_dungeon:event_action(State#dungeon_state.scene_requirement_list, [], NpcIdList, []),
			%2.检测击杀怪物统计.
			{NewKillNpcList, _UpdateScene2} = lib_dungeon:event_action(State#dungeon_state.kill_npc, [], NpcIdList, []),
            EnableScene = lib_dungeon:get_enable(UpdateScene, [], NewDSRL),
            NewState = lib_dungeon:enable_action(EnableScene, 
									 State#dungeon_state{scene_requirement_list = NewDSRL, kill_npc = NewKillNpcList}, 
									 DunScene#dungeon_scene.sid),
			
			%3.击杀怪物统计发给客户端.
			case NewState#dungeon_state.kill_npc_flag of
				1 ->
					case lib_dungeon:check_kill_count(EventSceneId, NewState#dungeon_state.kill_npc) of
						{true, MonList} ->  
							{ok, BinData} = pt_610:write(61007, [1, MonList]),			
							lib_server_send:send_to_scene(EventSceneId, self(), BinData);
						 _ ->
							skip
					end;
				_ ->
					skip
			end,
            
            %4.计算武魂值和杀怪数+1.
            NewWHPT = 
                if WHPT > 0 ->
                        NewState#dungeon_state.whpt + WHPT;
                    true ->
                        NewState#dungeon_state.whpt
                end,
            
            NewKill = NewState#dungeon_state.kill_mon_count + 1,
            NewState1 = NewState#dungeon_state{kill_mon_count = NewKill, whpt = NewWHPT},

			%5.副本杀怪事件其他逻辑处理.
			NewState2 =
				case length(State#dungeon_state.role_list) >= 1 of
					true ->
						case State#dungeon_state.type of
							%1.铜币副本杀怪事件处理.
							?DUNGEON_TYPE_COIN ->					
		            			mod_coin_dungeon:kill_npc(NewState1, EventSceneId, DunScene#dungeon_scene.sid, NpcIdList);
							
							%2.宠物副本杀怪事件处理.
							?DUNGEON_TYPE_PET ->
								mod_pet_dungeon:kill_npc(NewState1, EventSceneId, DunScene#dungeon_scene.sid, NpcIdList);
							
							%3.经验副本杀怪事件处理.					
							?DUNGEON_TYPE_EXP ->
								mod_exp_dungeon:kill_npc(NewState1, EventSceneId, DunScene#dungeon_scene.sid, NpcIdList);
							
							%3.爬塔副本杀怪事件处理.
							?DUNGEON_TYPE_TOWER ->
								mod_tower_dungeon:kill_npc(NpcIdList, NewState1, DunScene#dungeon_scene.sid);
							
							%4.新手宠物副本杀怪事件处理.
							?DUNGEON_TYPE_NEWER_PET ->
								mod_newer_pet_dungeon:kill_npc(NpcIdList, NewState1);

							%4.皇家守卫军塔防副本杀怪事件处理.
							?DUNGEON_TYPE_KINGDOM_RUSH ->
								lib_kingdom_rush_dungeon:kill_npc(NpcIdList, IsSkip, NewState1);
							
							%5.多人皇家守卫军塔防副本杀怪事件处理.
							?DUNGEON_TYPE_MULTI_KING ->
								lib_multi_king_dungeon:kill_npc(NpcIdList, IsSkip, NewState1);
							
							%6.连连看副本杀怪事件处理.
							?DUNGEON_TYPE_LIAN ->
								lib_lian_dungeon:kill_npc(NpcIdList, MonAutoId, EventSceneId, NewState1);

							%7.活动副本杀怪事件处理.
							?DUNGEON_TYPE_ACTIVITY ->
								lib_activity_dungeon:kill_npc(NpcIdList, MonAutoId, EventSceneId, NewState1);

							%8.飞行副本杀怪事件处理.
							?DUNGEON_TYPE_FLY ->
								lib_fly_dungeon:kill_npc(NpcIdList, MonAutoId, EventSceneId, NewState1);
							
                            %8.energy副本杀怪事件处理.
                            ?DUNGEON_TYPE_DNTK_EQUIP ->
                                lib_equip_energy_dungeon:kill_npc(NpcIdList, MonAutoId, EventSceneId, NewState1);
                            
                            %9.封魔录副本杀怪事件处理.
                            ?DUNGEON_TYPE_STORY ->
                                if
                                    NewKill >= 11 ->
                                        lib_story_dungeon:kill_npc(NpcIdList, MonAutoId, EventSceneId, NewState1);
                                    true -> 
                                        NewState1
                                end;
                            _ ->
                                NewState1
                        end;
                    false ->
                        NewState1
                end,
            {noreply, NewState2}
    end;


%% %% 接收杀怪事件
%% handle_info({kill_npc, EventSceneId, NpcIdList, BossType, MonAutoId, IsSkip}, State) ->
%%     %% TODO 杀的怪是否有用
%%     case lists:keyfind(EventSceneId, 2, State#dungeon_state.scene_list) of
%%         false ->
%%             {noreply, State};    %% 没有这个场景id
%%         DunScene ->
%%             %1.杀死的怪物是BOSS.                  
%%             case BossType of
%%                 0 -> skip;
%%                 _ ->
%%                     %1.名人堂触发处理固定怪物id.
%%                     case lists:member(30115, NpcIdList) of
%%                         true ->
%%                             %1.触发名人堂：副本突击，第一个击杀指定的副本BOSS.
%%                             MergeTime   = lib_activity_merge:get_activity_time(),
%%                             AllPlayerId = [Player#dungeon_player.id||Player <- State#dungeon_state.role_list],
%%                             [mod_fame:trigger_copy(MergeTime, 1, NpcId, AllPlayerId)||NpcId <- NpcIdList];
%%                         false ->
%%                             skip
%%                     end,
%% 
%%                     %2.剧情副本玩家大于等于40级杀死BOSS不加一.
%%                     [Player2|_PlayerList] = State#dungeon_state.role_list,                  
%%                     case State#dungeon_state.type of
%%                         ?DUNGEON_TYPE_STORY ->
%% 
%%                             %2.剧情副本杀死BOSS总次数才加一.
%%                             mod_dungeon_data:increment_total_count(Player2#dungeon_player.dungeon_data_pid, 
%%                                 Player2#dungeon_player.id, 
%%                                 State#dungeon_state.begin_sid);
%%                         _ ->
%%                             skip
%%                     end
%%             end,
%%             
%%             %2.设置武魂值.
%%             WHPT = lib_dungeon:set_whpt(BossType, NpcIdList, State),
%%             
%%             %1.检测副本的杀怪完成情况.
%%             {NewDSRL, UpdateScene} = lib_dungeon:event_action(State#dungeon_state.scene_requirement_list, [], NpcIdList, []),
%%             %2.检测击杀怪物统计.
%%             {NewKillNpcList, _UpdateScene2} = lib_dungeon:event_action(State#dungeon_state.kill_npc, [], NpcIdList, []),
%%             EnableScene = lib_dungeon:get_enable(UpdateScene, [], NewDSRL),
%%             NewState = lib_dungeon:enable_action(EnableScene, 
%%                                      State#dungeon_state{scene_requirement_list = NewDSRL, kill_npc = NewKillNpcList}, 
%%                                      DunScene#dungeon_scene.sid),
%%             
%%             %3.击杀怪物统计发给客户端.
%%             case NewState#dungeon_state.kill_npc_flag of
%%                 1 ->
%%                     case lib_dungeon:check_kill_count(EventSceneId, NewState#dungeon_state.kill_npc) of
%%                         {true, MonList} ->  
%%                             {ok, BinData} = pt_610:write(61007, [1, MonList]),          
%%                             lib_server_send:send_to_scene(EventSceneId, self(), BinData);
%%                          _ ->
%%                             skip
%%                     end;
%%                 _ ->
%%                     skip
%%             end,
%% 
%%             %4.副本杀怪事件处理.
%%             NewState1 =
%%                 case length(State#dungeon_state.role_list) >= 1 of
%%                     true ->
%%                         case State#dungeon_state.type of
%%                             %1.铜币副本杀怪事件处理.
%%                             ?DUNGEON_TYPE_COIN ->                   
%%                                 mod_coin_dungeon:kill_npc(NewState, EventSceneId, 
%%                                                           DunScene#dungeon_scene.sid, 
%%                                                           NpcIdList);
%%                             
%%                             %2.宠物副本杀怪事件处理.
%%                             ?DUNGEON_TYPE_PET ->
%%                                 mod_pet_dungeon:kill_npc(NewState, EventSceneId, 
%%                                                              DunScene#dungeon_scene.sid, 
%%                                                              NpcIdList);
%%                             
%%                             %3.经验副本杀怪事件处理.                  
%%                             ?DUNGEON_TYPE_EXP ->
%%                                 mod_exp_dungeon:kill_npc(NewState, EventSceneId, 
%%                                                          DunScene#dungeon_scene.sid, 
%%                                                          NpcIdList);
%%                             
%%                             %3.爬塔副本杀怪事件处理.
%%                             ?DUNGEON_TYPE_TOWER ->
%%                                 mod_tower_dungeon:kill_npc(NpcIdList, NewState, DunScene#dungeon_scene.sid);
%%                             
%%                             %4.新手宠物副本杀怪事件处理.
%%                             ?DUNGEON_TYPE_NEWER_PET ->
%%                                 mod_newer_pet_dungeon:kill_npc(NpcIdList, NewState);
%% 
%%                             %4.皇家守卫军塔防副本杀怪事件处理.
%%                             ?DUNGEON_TYPE_KINGDOM_RUSH ->
%%                                 lib_kingdom_rush_dungeon:kill_npc(NpcIdList, IsSkip, NewState);
%%                             
%%                             %5.多人皇家守卫军塔防副本杀怪事件处理.
%%                             ?DUNGEON_TYPE_MULTI_KING ->
%%                                 lib_multi_king_dungeon:kill_npc(NpcIdList, IsSkip, NewState);
%%                             
%%                             %6.连连看副本杀怪事件处理.
%%                             ?DUNGEON_TYPE_LIAN ->
%%                                 lib_lian_dungeon:kill_npc(NpcIdList, MonAutoId, EventSceneId, NewState);
%% 
%%                             %7.活动副本杀怪事件处理.
%%                             ?DUNGEON_TYPE_ACTIVITY ->
%%                                 lib_activity_dungeon:kill_npc(NpcIdList, MonAutoId, EventSceneId, NewState);
%% 
%%                             %8.飞行副本杀怪事件处理.
%%                             ?DUNGEON_TYPE_FLY ->
%%                                 lib_fly_dungeon:kill_npc(NpcIdList, MonAutoId, EventSceneId, NewState);
%%                             
%%                             %8.energy副本杀怪事件处理.
%%                             ?DUNGEON_TYPE_DNTK_EQUIP ->
%%                                 lib_equip_energy_dungeon:kill_npc(NpcIdList, MonAutoId, EventSceneId, NewState);
%%                             _ ->
%%                                 NewState
%%                         end;
%%                     false ->
%%                         NewState
%%                 end,
%% 
%%             %5.计算武魂值.
%%             NewWHPT = 
%%                 if WHPT > 0 ->
%%                         NewState1#dungeon_state.whpt + WHPT;
%%                     true ->
%%                         NewState1#dungeon_state.whpt
%%                 end,
%%             
%%             NewKill = NewState1#dungeon_state.kill_mon_count + 1,
%%             NewState2 = NewState1#dungeon_state{kill_mon_count = NewKill, whpt = NewWHPT},
%%             
%%             NewState3 = case length(NewState2#dungeon_state.role_list) >= 1 of
%%                 true ->
%%                     case NewState2#dungeon_state.type of
%%                         ?DUNGEON_TYPE_STORY ->
%%                             if
%%                                 NewKill >= 11 ->
%%                                     [{PlayerId, _Pid, _DataPid}|_] = [{Role#dungeon_player.id, 
%%                                                                        Role#dungeon_player.pid, 
%%                                                                        Role#dungeon_player.dungeon_data_pid} || 
%%                                                                       Role <- NewState2#dungeon_state.role_list],
%%                                     case lib_player:get_player_info(PlayerId) of
%%                                         PlayerStatus when is_record(PlayerStatus, player_status)->
%%                                             lib_dungeon:send_dungeon_record(NewState2, PlayerStatus, 7),
%%                                             NewState2#dungeon_state{is_die = 2};
%%                                         %% 不在线
%%                                         _Other -> NewState2
%%                                     end;
%%                                 true -> NewState2
%%                             end;
%%                         _ -> NewState2
%%                     end;
%%                 _ -> NewState2
%%             end,
%%             {noreply, NewState3}
%%     end;


%% 测试用 -- 直接激活副本场景
handle_info({active, SceneId}, State) ->
    NewState = lib_dungeon:enable_action([SceneId], State, 0),
    {noreply, NewState}.







