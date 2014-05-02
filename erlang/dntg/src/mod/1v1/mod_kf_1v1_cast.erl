%% Author: Administrator
%% Created: 2012-11-16
%% Description: TODO: Add description to mod_kf_1v1_cast
-module(mod_kf_1v1_cast).

%%
%% Include files
%%
-include("kf_1v1.hrl").
-include("server.hrl").
-include("unite.hrl").
%%
%% Exported Functions
%%
-export([handle_cast/2]).

%%
%% API Functions
%%
handle_cast({look_war,Node,Platform,Server_num,Id,Loop,A_Flat,A_Server_id,A_Id,B_Flat,B_Server_id,B_Id}, State) ->
	case dict:is_key([Platform,Server_num,Id], State#kf_1v1_state.player_dict) of
		false -> %%无玩家记录
			New_State = State,
			Result = 5;
		true->
			Player = dict:fetch([Platform,Server_num,Id], State#kf_1v1_state.player_dict),
			case is_pid(Player#bd_1v1_player.pk_pid) of
				false->
					case dict:is_key([Platform,Server_num,Id], State#kf_1v1_state.sign_up_dict) of
						false->
							Key = [Loop,A_Flat,A_Server_id,A_Id,B_Flat,B_Server_id,B_Id],
							case dict:is_key(Key, State#kf_1v1_state.room_dict) of
								false->%%无对应房间
									New_State = State,
									Result = 5;
								true->
									Room = dict:fetch(Key, State#kf_1v1_state.room_dict),
									if
										Room#bd_1v1_room.win_id/=0->%%比赛已结束
											New_State = State,
											Result = 2;
										true->
											Result = 1,
											Value = {Node,Id,Player#bd_1v1_player.copy_id},
											case dict:is_key(Key, State#kf_1v1_state.look_dict) of
												false->
													Look_List = [Value];
												true->
													Temp_Look_List = dict:fetch(Key, State#kf_1v1_state.look_dict),
													Flag = lists:member(Value, Temp_Look_List),
													case Flag of
														false->Look_List = Temp_Look_List ++ [Value];
														true->Look_List = Temp_Look_List
													end
											end,
											New_look_dict = dict:store(Key,Look_List,State#kf_1v1_state.look_dict),
											New_State = State#kf_1v1_state{
												look_dict = New_look_dict						   
											},
											%%传送进去
											Scene_Id = data_kf_1v1:get_bd_1v1_config(scene_id2),
											[X,Y] = data_kf_1v1:get_position3(),
											CopyId = integer_to_list(Loop) 
													 ++ "_" ++ A_Flat
													 ++ "_" ++ integer_to_list(A_Server_id) 
													 ++ "_" ++ integer_to_list(A_Id) 
													 ++ "_" ++ B_Flat
													 ++ "_" ++ integer_to_list(B_Server_id) 
											         ++ "_" ++ integer_to_list(B_Id),
											mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,
												   [Id,Scene_Id,CopyId,X,Y,[{visible,1}]])
									end
							end;
						true->%%已报名比赛
							New_State = State,
							Result = 4
					end;
				true->
					New_State = State,
					Result = 6
			end
	end,
	{ok, BinData} = pt_483:write(48313, [Result]),
	mod_clusters_center:apply_cast(Node,lib_unite_send,cluster_to_uid,[Id,BinData]),
	
	{noreply, New_State};
  
handle_cast({get_player_top_list,Node,Platform,Server_num,Id}, State) ->
	spawn(fun()-> 
		Player_dict = State#kf_1v1_state.player_dict,
		case dict:is_key([Platform,Server_num,Id], Player_dict) of
			false -> 
				MyLoop = 0,
				MyWin = 0,
				MyHp = 0,
				MyPt = 0,
				MyScore = 0;
			true->
				Player = dict:fetch([Platform,Server_num,Id], Player_dict),
				MyLoop = Player#bd_1v1_player.loop,
				MyPt = Player#bd_1v1_player.pt,
				MyScore = Player#bd_1v1_player.score,
				if
					MyLoop=<0 ->
						MyWin = 0,
						MyHp = 0;
					true->
						MyWin = Player#bd_1v1_player.win_loop,
						MyHp = Player#bd_1v1_player.hp*100 div MyLoop
				end
		end,
		{ok, BinData} = pt_483:write(48306, [MyLoop,MyWin,MyHp,MyPt,MyScore]),
		mod_clusters_center:apply_cast(Node,lib_unite_send,cluster_to_uid,[Id,BinData])   
	end),
	
	{noreply, State};

handle_cast({get_player_pk_list,Node,Platform,Server_num,Id}, State) ->
	spawn(fun()-> 
		Room_dict_List = dict:to_list(State#kf_1v1_state.room_dict),
		My_match_list = lib_kf_1v1:look_my_match(Room_dict_List,State#kf_1v1_state.player_dict,Platform,Server_num,Id,[]),
		Sort_My_match_list = lists:sort(fun({_,Loop_A,_,_,_,_,_,_,_,_,_},{_,Loop_B,_,_,_,_,_,_,_,_,_})-> 
			if
				Loop_A=<Loop_B ->true;
				true->false
			end
		end, My_match_list),
		{ok, BinData} = pt_483:write(48305, [Sort_My_match_list]),
		mod_clusters_center:apply_cast(Node,lib_unite_send,cluster_to_uid,[Id,BinData])  
	end),
	
	{noreply, State};

handle_cast({sign_up,Node,Platform,Server_num,Id}, State) ->
	case State#kf_1v1_state.bd_1v1_stauts of
		1->%%报名允许期
			case dict:is_key([Platform,Server_num,Id], State#kf_1v1_state.player_dict) of
				false->
					New_State = State,
					Reply = 4;
				true->
					Player = dict:fetch([Platform,Server_num,Id], State#kf_1v1_state.player_dict),
					case is_pid(Player#bd_1v1_player.pk_pid) of
						false->%%非比赛状态
%% 							case dict:is_key([Platform,Server_num,Id], State#kf_1v1_state.sign_up_dict) of
%% 								false->%%没报过名
%% 									New_sign_up_dict = dict:store([Platform,Server_num,Id], 0, State#kf_1v1_state.sign_up_dict),
%% 									New_State = State#kf_1v1_state{
%% 										sign_up_dict = New_sign_up_dict			   
%% 									},
%% 									Reply = 1;
%% 								true->%%报过名
%% 									New_State = State,
%% 									Reply = 1
%% 							end;
							Loop_max = data_kf_1v1:get_bd_1v1_config(loop_max),
							if
								Loop_max=<Player#bd_1v1_player.loop->%%本场次数已满
									New_State = State,
									Reply = 7;
								true->
									Loop_max_day = data_kf_1v1:get_bd_1v1_config(loop_max_day),
									if
										Loop_max_day=<Player#bd_1v1_player.loop+Player#bd_1v1_player.loop_day->%%当天次数已满
											New_State = State,
											Reply = 6;
										true->
											case dict:is_key([Platform,Server_num,Id], State#kf_1v1_state.sign_up_dict) of
												false->%%没报过名
													New_sign_up_dict = dict:store([Platform,Server_num,Id], 0, State#kf_1v1_state.sign_up_dict),
													New_State = State#kf_1v1_state{
														sign_up_dict = New_sign_up_dict			   
													},
													Reply = 1;
												true->%%报过名
													New_State = State,
													Reply = 1
											end
									end
							end;
						true->
							New_State = State,
							Reply = 5
					end
			end;
		_->
			New_State = State,
			Reply = 2
	end,
	{ok, BinData} = pt_483:write(48310, [Reply]),
	mod_clusters_center:apply_cast(Node,lib_unite_send,cluster_to_uid,[Id,BinData]),
	
    {noreply, New_State};

handle_cast({enter_prepare,UniteStatus,Platform,Server_num,Node,Pt_lv,Combat_power,Loop_day,Max_Combat_power}, State) ->
	if
		State#kf_1v1_state.bd_1v1_stauts=:=0 orelse State#kf_1v1_state.bd_1v1_stauts=:=4->%%防止跨服节点死掉的情况。
			mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_status,[State#kf_1v1_state.bd_1v1_stauts]),
			Reply = [4,0,State#kf_1v1_state.bd_1v1_stauts,0,0,0,0,0,0],
			New_State = State;
		true->
			%% [Result,Loop,State,RestTime,WholeRestTime,CurrentLoop]
			{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
			NowTime = (Hour*60+Minute)*60 + Second,
			_RestTime = State#kf_1v1_state.loop_end - NowTime, 
			if
				_RestTime>=0->RestTime = _RestTime;
				true-> RestTime = 0
			end,
			
			case dict:is_key([Platform,Server_num,UniteStatus#unite_status.id], State#kf_1v1_state.player_dict) of
				false-> % 无记录
					Result = 1,
					Scene_Id = data_kf_1v1:get_bd_1v1_config(scene_id1),
					Room_max_num = data_kf_1v1:get_bd_1v1_config(room_max_num),
					if
						State#kf_1v1_state.room_num<Room_max_num->
							New_room_no = State#kf_1v1_state.room_no,
							New_room_num = State#kf_1v1_state.room_num + 1;
						true-> %%满员了，新建房间
							New_room_no = State#kf_1v1_state.room_no + 1,
							New_room_num = 1
					end,
					CopyId = integer_to_list(New_room_no),
					[X,Y] = data_kf_1v1:get_position1(),
					%% 构建玩家记录
					Bd_1v1_player = #bd_1v1_player{
						platform = Platform,
						server_num = Server_num,										   
						node = Node,										   
						id = UniteStatus#unite_status.id, 			% 玩家Id
						name = UniteStatus#unite_status.name,		% 玩家名称
						country = UniteStatus#unite_status.realm, 	% 玩家国家
						sex = UniteStatus#unite_status.sex,			% 性别
						carrer = UniteStatus#unite_status.career,	% 职业
						image = UniteStatus#unite_status.image,		% 头像
						lv = UniteStatus#unite_status.lv, 			% 等级
						is_in = 1,								    % 入场状态
						combat_power = Combat_power,				% 玩家战力
						max_combat_power = max(Combat_power,Max_Combat_power),
						copy_id = CopyId,							% 准备区副本Id
						pt_lv = Pt_lv,
						loop_day = Loop_day
					},
					MyLoop = 0,
					IsSign = 0,
					New_player_dict = dict:store([Platform,Server_num,UniteStatus#unite_status.id], Bd_1v1_player, State#kf_1v1_state.player_dict),
					Cw_min_power = data_kf_1v1:get_bd_1v1_config(cw_min_power),
					if
						Cw_min_power=<Combat_power->
							case State#kf_1v1_state.no1 of
								[No1_Combat_powar,_No1_Platform,_No1_Server_num,_No1_Id,_No1_Name,_No1_Country]->
									if
										No1_Combat_powar<Combat_power->
											No1 = [Combat_power,Platform,Server_num,UniteStatus#unite_status.id,
																				   UniteStatus#unite_status.name,
																				   UniteStatus#unite_status.realm],
											{ok, BinData11} = pt_483:write(48311, [Platform,Server_num,UniteStatus#unite_status.id,
																				   UniteStatus#unite_status.name,
																				   UniteStatus#unite_status.realm]),
											PlayerDictList1 = dict:to_list(New_player_dict),
											lists:foreach(fun({_K,V})-> 
												case is_pid(V#bd_1v1_player.pk_pid) of
													false->
														mod_clusters_center:apply_cast(V#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[V#bd_1v1_player.id,BinData11]);				  
													true->void	
												end
											end, PlayerDictList1);
										true->
											No1 = State#kf_1v1_state.no1
									end;
								_->
									No1 = [Combat_power,Platform,Server_num,UniteStatus#unite_status.id, UniteStatus#unite_status.name,UniteStatus#unite_status.realm],
									{ok, BinData11} = pt_483:write(48311, [Platform,Server_num,UniteStatus#unite_status.id,
																		   UniteStatus#unite_status.name,
																		   UniteStatus#unite_status.realm]),
									PlayerDictList2 = dict:to_list(New_player_dict),
									lists:foreach(fun({_K,V})-> 
										case is_pid(V#bd_1v1_player.pk_pid) of
											false->
												mod_clusters_center:apply_cast(V#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[V#bd_1v1_player.id,BinData11]);				  
											true->void	
										end
									end, PlayerDictList2)
							end;
						true->
							No1 = State#kf_1v1_state.no1
					end,
					New_State = State#kf_1v1_state{
						player_dict = New_player_dict,
						room_no = New_room_no,
						room_num = New_room_num,
						no1 = No1
					};
				true->
					Bd_1v1_player = dict:fetch([Platform,Server_num,UniteStatus#unite_status.id], State#kf_1v1_state.player_dict),
					if
						Bd_1v1_player#bd_1v1_player.max_combat_power<Max_Combat_power->
							New_max_combat_power = Max_Combat_power;
						true->
							New_max_combat_power = Bd_1v1_player#bd_1v1_player.max_combat_power
					end,
					New_Bd_1v1_player = Bd_1v1_player#bd_1v1_player{
						is_in = 1,								% 入场状态
						combat_power = Combat_power,				% 玩家战力
						max_combat_power = max(Combat_power,New_max_combat_power)							
					},
					MyLoop = Bd_1v1_player#bd_1v1_player.loop,
					case dict:is_key([Platform,Server_num,UniteStatus#unite_status.id], State#kf_1v1_state.sign_up_dict) of
						false->IsSign = 0;
						true->IsSign = 1
					end,
					Bd_1v1_stauts = State#kf_1v1_state.bd_1v1_stauts,
					if
						Bd_1v1_stauts =:= 3 -> %战斗期间
							Out_time = data_kf_1v1:get_bd_1v1_config(out_time),
							Loop_time = 60*data_kf_1v1:get_bd_1v1_config(loop_time),
							if
								Loop_time - RestTime =< Out_time -> %% 属于允许进入状态(针对准备区掉线的)
									Result = 1,
									Room_dict_List = dict:to_list(State#kf_1v1_state.room_dict),
									case lib_kf_1v1:look_match(Room_dict_List,[Platform,Server_num,UniteStatus#unite_status.id]) of
										{error,_}->
											Scene_Id = data_kf_1v1:get_bd_1v1_config(scene_id1),
											CopyId = New_Bd_1v1_player#bd_1v1_player.copy_id,
											[X,Y] = data_kf_1v1:get_position1();
										{ok,{_Key,Bd_1v1_Room}}->
											Scene_Id = data_kf_1v1:get_bd_1v1_config(scene_id2),
											[[X1,Y1],[X2,Y2]] = data_kf_1v1:get_bd_1v1_config(position2),
											CopyId = integer_to_list(State#kf_1v1_state.current_loop) 
													 ++ "_" ++ Bd_1v1_Room#bd_1v1_room.player_a_platform
													 ++ "_" ++ integer_to_list(Bd_1v1_Room#bd_1v1_room.player_a_server_num) 
													 ++ "_" ++ integer_to_list(Bd_1v1_Room#bd_1v1_room.player_a_id) 
													 ++ "_" ++ Bd_1v1_Room#bd_1v1_room.player_b_platform
													 ++ "_" ++ integer_to_list(Bd_1v1_Room#bd_1v1_room.player_b_server_num) 
											         ++ "_" ++ integer_to_list(Bd_1v1_Room#bd_1v1_room.player_b_id),
											if
												UniteStatus#unite_status.id=:=Bd_1v1_Room#bd_1v1_room.player_a_id ->
													[X,Y] = [X1,Y1];
												true->
													[X,Y] = [X2,Y2]
											end
									end;
								true-> %已经不让进入战场了
									Result = 5,
									Scene_Id = data_kf_1v1:get_bd_1v1_config(scene_id1),
									CopyId = New_Bd_1v1_player#bd_1v1_player.copy_id,
									[X,Y] = data_kf_1v1:get_position1()
							end;
						true -> %非战斗期间
							Result = 1,
							Scene_Id = data_kf_1v1:get_bd_1v1_config(scene_id1),
							CopyId = New_Bd_1v1_player#bd_1v1_player.copy_id,
							[X,Y] = data_kf_1v1:get_position1()
					end,
					New_player_dict = dict:store([Platform,Server_num,UniteStatus#unite_status.id], New_Bd_1v1_player, State#kf_1v1_state.player_dict),
					Cw_min_power = data_kf_1v1:get_bd_1v1_config(cw_min_power),
					if
						Cw_min_power=<Combat_power->
							case State#kf_1v1_state.no1 of
								[No1_Combat_powar,_No1_Platform,_No1_Server_num,_No1_Id,_No1_Name,_No1_Country]->
									if
										No1_Combat_powar<Combat_power->
											No1 = [Combat_power,Platform,Server_num,UniteStatus#unite_status.id,
																				   UniteStatus#unite_status.name,
																				   UniteStatus#unite_status.realm],
											{ok, BinData11} = pt_483:write(48311, [Platform,Server_num,UniteStatus#unite_status.id,
																				   UniteStatus#unite_status.name,
																				   UniteStatus#unite_status.realm]),
											PlayerDictList1 = dict:to_list(New_player_dict),
											lists:foreach(fun({_K,V})-> 
												case is_pid(V#bd_1v1_player.pk_pid) of
													false->
														mod_clusters_center:apply_cast(V#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[V#bd_1v1_player.id,BinData11]);				  
													true->void	
												end
											end, PlayerDictList1);
										true->
											No1 = State#kf_1v1_state.no1
									end;
								_->
									No1 = [Combat_power,Platform,Server_num,UniteStatus#unite_status.id, UniteStatus#unite_status.name,UniteStatus#unite_status.realm],
									{ok, BinData11} = pt_483:write(48311, [Platform,Server_num,UniteStatus#unite_status.id,
																		   UniteStatus#unite_status.name,
																		   UniteStatus#unite_status.realm]),
									PlayerDictList2 = dict:to_list(New_player_dict),
									lists:foreach(fun({_K,V})-> 
										case is_pid(V#bd_1v1_player.pk_pid) of
											false->
												mod_clusters_center:apply_cast(V#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[V#bd_1v1_player.id,BinData11]);				  
											true->void	
										end
									end, PlayerDictList2)
							end;
						true->
							No1 = State#kf_1v1_state.no1
					end,
					New_State = State#kf_1v1_state{
						player_dict = New_player_dict,
						no1 = No1					
					}
			end,
			
			_WholeRestTime = State#kf_1v1_state.config_end - NowTime, 
			if
				_WholeRestTime>=0->WholeRestTime = _WholeRestTime;
				true-> WholeRestTime = 0
			end,
			Reply = [Result,State#kf_1v1_state.loop,State#kf_1v1_state.bd_1v1_stauts,RestTime,
					 WholeRestTime,State#kf_1v1_state.current_loop,MyLoop,IsSign,Loop_day],
			mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,
										   [UniteStatus#unite_status.id,Scene_Id,CopyId,X,Y,0])
	end,
	{ok, BinData} = pt_483:write(48302, Reply),
	mod_clusters_center:apply_cast(Node,lib_unite_send,cluster_to_uid,[UniteStatus#unite_status.id,BinData]),
	{noreply, New_State};

handle_cast({when_logout,Platform,Server_num,Id,Hp,Hp_lim,Combat_power,Type}, State) ->
	case dict:is_key([Platform,Server_num,Id], State#kf_1v1_state.player_dict) of
		false-> %无记录
			NewState = State;
		true->
			Player = dict:fetch([Platform,Server_num,Id], State#kf_1v1_state.player_dict),
			if
				Type=:=2->%%退出
					case State#kf_1v1_state.bd_1v1_stauts of
						4->%%丢出跨服场地
							Is_in = 0;
						_->
							Is_in = 1
					end;
				true->%%下线操作
					Is_in = 0
			end,
			case is_pid(Player#bd_1v1_player.pk_pid) of
				false->%%无战斗进程
					New_look_dict = remove_look(Player#bd_1v1_player.node,Id,Player#bd_1v1_player.copy_id,
												dict:to_list(State#kf_1v1_state.look_dict),dict:new()),
					if
						Type=:=2->%%退出
							case State#kf_1v1_state.bd_1v1_stauts of
								4->%%丢出跨服场地
									spawn(fun()->
										timer:sleep(3*1000),
										[SceneId,X,Y] = data_kf_1v1:get_bd_1v1_config(leave_scene),
										mod_clusters_center:apply_cast(Player#bd_1v1_player.node,
																	   lib_scene,player_change_scene_queue,
																	   [Id,SceneId,0,X,Y,0])
									end);
								_->
									spawn(fun()->
										timer:sleep(3*1000),
										Bd_1v1_Scene_id1 = data_kf_1v1:get_bd_1v1_config(scene_id1),
										[X,Y] = data_kf_1v1:get_position1(),
										mod_clusters_center:apply_cast(Player#bd_1v1_player.node,lib_scene,player_change_scene_queue,[Id,Bd_1v1_Scene_id1,Player#bd_1v1_player.copy_id,X,Y,0])		  
									end)
							end;
						true->
							void
					end,
					New_sign_up_dict = dict:erase([Platform,Server_num,Id], State#kf_1v1_state.sign_up_dict),
					New_Bd_1v1_player = Player#bd_1v1_player{is_in = Is_in},
					New_player_dict = dict:store([Platform,Server_num,Id], New_Bd_1v1_player, State#kf_1v1_state.player_dict),
					NewState = State#kf_1v1_state{
						player_dict = New_player_dict,
						look_dict = New_look_dict,
						sign_up_dict = New_sign_up_dict				
					};
				true->%%有战斗进程
					Bd_1v1_Scene_id2 = data_kf_1v1:get_bd_1v1_config(scene_id2),
					Room_dict_List = dict:to_list(State#kf_1v1_state.room_dict),
					case lib_kf_1v1:look_match(Room_dict_List,[Platform,Server_num,Id]) of
						{error,_}->
							NewState = State;
						{ok,{Key,Bd_1v1_Room}}->
							%%清空观战人员
							clear_look_player(Key,State#kf_1v1_state.look_dict),
							[_Temp_Current_loop,APlatform,AServer_num,AId,BPlatform,BServer_num,BId] = Key,
							Player#bd_1v1_player.pk_pid!{over},
							if
								APlatform=:=Platform andalso AServer_num=:=Server_num andalso AId=:=Id-> %%下线的是Aid
									B_Player = dict:fetch([BPlatform,BServer_num,BId], State#kf_1v1_state.player_dict),
									B_Player#bd_1v1_player.pk_pid!{over},
									{T_Combat_power,T_Hp,T_Hp_lim,_Scene_id} = lib_scene:get_scene_user_1v1(Bd_1v1_Scene_id2, 0, BId, BPlatform,BServer_num),
									[Win_pt,Loos_pt] = data_kf_1v1:get_pt(B_Player#bd_1v1_player.pt_lv,B_Player#bd_1v1_player.pt,Player#bd_1v1_player.pt_lv,Player#bd_1v1_player.pt),
									[Win_score,Loos_score] = data_kf_1v1:get_score(B_Player#bd_1v1_player.pt_lv,B_Player#bd_1v1_player.score,
																				   B_Player#bd_1v1_player.combat_power,B_Player#bd_1v1_player.lv,
																				   Player#bd_1v1_player.pt_lv,Player#bd_1v1_player.score,
																				   Player#bd_1v1_player.combat_power,Player#bd_1v1_player.lv),
									A_hp_rate = Hp * 100 div Hp_lim,
									B_hp_rate = T_Hp  * 100 div T_Hp_lim,
									case State#kf_1v1_state.bd_1v1_stauts of
										4->%%需结算
											Is_gift = 1;
										_->
											Is_gift = 0
									end,		
									New_Player = Player#bd_1v1_player{
										hp = Player#bd_1v1_player.hp + A_hp_rate,
										is_in = Is_in,
										pt = Loos_pt,
										score = Loos_score,
										pk_pid = none,
										is_gift = Is_gift
									},
									New_B_Player = B_Player#bd_1v1_player{
										win_loop = B_Player#bd_1v1_player.win_loop + 1,																  
										hp = B_Player#bd_1v1_player.hp + B_hp_rate,
										pt = Win_pt,
										score = Win_score,
										pk_pid = none,
										is_gift = Is_gift
									},
									New_player_dict1 = dict:store([Platform,Server_num,Id], New_Player, State#kf_1v1_state.player_dict),
									New_player_dict2 = dict:store([BPlatform,BServer_num,BId], New_B_Player, New_player_dict1),
									New_Bd_1v1_room = Bd_1v1_Room#bd_1v1_room{
										win_platform = BPlatform,
										win_server_num = BServer_num,																	  
										win_id = BId,																	  
										player_a_power = Combat_power, 	% 玩家战力
										player_a_hp = Hp, 				% 玩家当前血量(判断胜负时的赋值)
										player_a_maxHp = Hp_lim,		% 玩家最高血量(进行时，禁用一切改变属性操作)	
										player_b_power = T_Combat_power, 	% 玩家战力
										player_b_hp = T_Hp, 				% 玩家当前血量(判断胜负时的赋值)
										player_b_maxHp = T_Hp_lim 		% 玩家最高血量(进行时，禁用一切改变属性操作)									  
									},
									{ok, BinData} = pt_483:write(48308, [BPlatform,BServer_num,BId,
																		Platform,Server_num,Id,
																		New_Player#bd_1v1_player.name,
																		New_Player#bd_1v1_player.country,
																		New_Player#bd_1v1_player.sex,
																		New_Player#bd_1v1_player.carrer,
																		New_Player#bd_1v1_player.image,
																		New_Player#bd_1v1_player.lv,
																		Combat_power,
																		New_Bd_1v1_room#bd_1v1_room.player_a_num,
																		Hp,
																		Hp_lim,
																		BPlatform,BServer_num,BId,
																		New_B_Player#bd_1v1_player.name,
																		New_B_Player#bd_1v1_player.country,
																		New_B_Player#bd_1v1_player.sex,
																		New_B_Player#bd_1v1_player.carrer,
																		New_B_Player#bd_1v1_player.image,
																		New_B_Player#bd_1v1_player.lv,
																		T_Combat_power,
																		New_Bd_1v1_room#bd_1v1_room.player_b_num,
																		T_Hp,
																		T_Hp_lim,
																		Player#bd_1v1_player.pt,
																		New_Player#bd_1v1_player.pt,
																		Player#bd_1v1_player.score,
																		New_Player#bd_1v1_player.score,
																		B_Player#bd_1v1_player.pt,
																		New_B_Player#bd_1v1_player.pt,
																		B_Player#bd_1v1_player.score,
																		New_B_Player#bd_1v1_player.score,
																		New_Bd_1v1_room#bd_1v1_room.loop]);
								true-> %%下线的是Bid
									B_Player = dict:fetch([APlatform,AServer_num,AId], State#kf_1v1_state.player_dict),
									B_Player#bd_1v1_player.pk_pid!{over},
									{T_Combat_power,T_Hp,T_Hp_lim,_Scene_id} = lib_scene:get_scene_user_1v1(Bd_1v1_Scene_id2, 0, AId,APlatform,AServer_num),
									[Win_pt,Loos_pt] = data_kf_1v1:get_pt(B_Player#bd_1v1_player.pt_lv,B_Player#bd_1v1_player.pt,Player#bd_1v1_player.pt_lv,Player#bd_1v1_player.pt),
									[Win_score,Loos_score] = data_kf_1v1:get_score(B_Player#bd_1v1_player.pt_lv,B_Player#bd_1v1_player.score,
																				   B_Player#bd_1v1_player.combat_power,B_Player#bd_1v1_player.lv,
																				   Player#bd_1v1_player.pt_lv,Player#bd_1v1_player.score,
																				   Player#bd_1v1_player.combat_power,Player#bd_1v1_player.lv),
									A_hp_rate = Hp * 100 div Hp_lim,
									B_hp_rate = T_Hp  * 100 div T_Hp_lim,
									case State#kf_1v1_state.bd_1v1_stauts of
										4->%%需结算
											Is_gift = 1;
										_->
											Is_gift = 0
									end,
									New_Player = Player#bd_1v1_player{
										hp = Player#bd_1v1_player.hp + A_hp_rate,
										is_in = Is_in,
										pt = Loos_pt,
										score = Loos_score,
										pk_pid = none,
										is_gift = Is_gift
									},
									New_B_Player = B_Player#bd_1v1_player{
										win_loop = B_Player#bd_1v1_player.win_loop + 1,																  
										hp = B_Player#bd_1v1_player.hp + B_hp_rate,
										pt = Win_pt,
										score = Win_score,
										pk_pid = none,
										is_gift = Is_gift
									},
									New_player_dict1 = dict:store([Platform,Server_num,Id], New_Player, State#kf_1v1_state.player_dict),
									New_player_dict2 = dict:store([APlatform,AServer_num,AId], New_B_Player, New_player_dict1),
									New_Bd_1v1_room = Bd_1v1_Room#bd_1v1_room{
										win_platform = APlatform,
										win_server_num = AServer_num,																	  
										win_id = AId,	
										player_a_power = T_Combat_power, 	% 玩家战力
										player_a_hp = T_Hp, 				% 玩家当前血量(判断胜负时的赋值)
										player_a_maxHp = T_Hp_lim, 		% 玩家最高血量(进行时，禁用一切改变属性操作)																	  
										player_b_power = Combat_power, 	% 玩家战力
										player_b_hp = Hp, 				% 玩家当前血量(判断胜负时的赋值)
										player_b_maxHp = Hp_lim 		% 玩家最高血量(进行时，禁用一切改变属性操作)									  
									},
									{ok, BinData} = pt_483:write(48308, [APlatform,AServer_num,AId,
																		APlatform,AServer_num,AId,
																		New_B_Player#bd_1v1_player.name,
																		New_B_Player#bd_1v1_player.country,
																		New_B_Player#bd_1v1_player.sex,
																		New_B_Player#bd_1v1_player.carrer,
																		New_B_Player#bd_1v1_player.image,
																		New_B_Player#bd_1v1_player.lv,
																		T_Combat_power,
																		New_Bd_1v1_room#bd_1v1_room.player_a_num,
																		T_Hp,
																		T_Hp_lim,
																		Platform,Server_num,Id,
																		New_Player#bd_1v1_player.name,
																		New_Player#bd_1v1_player.country,
																		New_Player#bd_1v1_player.sex,
																		New_Player#bd_1v1_player.carrer,
																		New_Player#bd_1v1_player.image,
																		New_Player#bd_1v1_player.lv,
																		Combat_power,
																		New_Bd_1v1_room#bd_1v1_room.player_b_num,
																		Hp,
																		Hp_lim,
																		B_Player#bd_1v1_player.pt,
																		New_B_Player#bd_1v1_player.pt,
																		B_Player#bd_1v1_player.score,
																		New_B_Player#bd_1v1_player.score,
																		Player#bd_1v1_player.pt,
																		New_Player#bd_1v1_player.pt,
																		Player#bd_1v1_player.score,
																		New_Player#bd_1v1_player.score,
																		New_Bd_1v1_room#bd_1v1_room.loop])
							end,
							mod_clusters_center:apply_cast(New_Player#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[Id,BinData]),
							mod_clusters_center:apply_cast(New_B_Player#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[New_B_Player#bd_1v1_player.id,BinData]),
							New_room_dict = dict:store(Key, New_Bd_1v1_room, State#kf_1v1_state.room_dict),
							case State#kf_1v1_state.bd_1v1_stauts of
								4->%%丢出跨服场地
									spawn(fun()->
										timer:sleep(3*1000),
										[SceneId,X,Y] = data_kf_1v1:get_bd_1v1_config(leave_scene),
										mod_clusters_center:apply_cast(New_Player#bd_1v1_player.node,
																	   lib_scene,player_change_scene_queue,
																	   [New_Player#bd_1v1_player.id,SceneId,0,X,Y,0]),
										mod_clusters_center:apply_cast(New_B_Player#bd_1v1_player.node,
																	   lib_scene,player_change_scene_queue,
																	   [New_B_Player#bd_1v1_player.id,SceneId,0,X,Y,0])		  
									end);
								_->
									spawn(fun()->
										timer:sleep(3*1000),
										Bd_1v1_Scene_id1 = data_kf_1v1:get_bd_1v1_config(scene_id1),
										[X,Y] = data_kf_1v1:get_position1(),
										mod_clusters_center:apply_cast(New_Player#bd_1v1_player.node,lib_scene,player_change_scene_queue,[New_Player#bd_1v1_player.id,Bd_1v1_Scene_id1,New_Player#bd_1v1_player.copy_id,X,Y,0]),
										mod_clusters_center:apply_cast(New_B_Player#bd_1v1_player.node,lib_scene,player_change_scene_queue,[New_B_Player#bd_1v1_player.id,Bd_1v1_Scene_id1,New_B_Player#bd_1v1_player.copy_id,X,Y,0])		  
									end),
									{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
									NowTime = (Hour*60+Minute)*60 + Second,
									_RestTime = State#kf_1v1_state.loop_end - NowTime, 
									_WholeRestTime = State#kf_1v1_state.config_end - NowTime, 
									if
										_RestTime>=0->RestTime = _RestTime;
										true-> RestTime = 0
									end,
									if
										_WholeRestTime>=0->WholeRestTime = _WholeRestTime;
										true-> WholeRestTime = 0
									end,
									{ok, BinDataA2} = pt_483:write(48304, [State#kf_1v1_state.loop,State#kf_1v1_state.bd_1v1_stauts,RestTime,WholeRestTime,
																		   State#kf_1v1_state.current_loop,New_Player#bd_1v1_player.loop,0,New_Player#bd_1v1_player.loop_day]),
									{ok, BinDataB2} = pt_483:write(48304, [State#kf_1v1_state.loop,State#kf_1v1_state.bd_1v1_stauts,RestTime,WholeRestTime,
																		   State#kf_1v1_state.current_loop,New_B_Player#bd_1v1_player.loop,0,New_B_Player#bd_1v1_player.loop_day]),
									mod_clusters_center:apply_cast(New_Player#bd_1v1_player.node,lib_unite_send,cluster_to_uid, [New_Player#bd_1v1_player.id,BinDataA2]),
									mod_clusters_center:apply_cast(New_B_Player#bd_1v1_player.node,lib_unite_send,cluster_to_uid, [New_B_Player#bd_1v1_player.id,BinDataB2])
							end,
							NewState = State#kf_1v1_state{
								player_dict = New_player_dict2,
								room_dict = New_room_dict
							}
					end
			end
	end,
	
	{noreply, NewState};

handle_cast({when_kill,Platform,Server_num,Uid,UidPower,UidHp,UidHpLim,KilledPlatform,KilledServer_num,KilledUid,KilledUidPower,KilledUidHp,KilledUidHpLim}, State) ->
	case dict:is_key([Platform,Server_num,Uid], State#kf_1v1_state.player_dict) 
		andalso dict:is_key([KilledPlatform,KilledServer_num,KilledUid], State#kf_1v1_state.player_dict) of
		false-> %无记录
			NewState = State;
		true->
			A_Bd_1v1_player = dict:fetch([Platform,Server_num,Uid], State#kf_1v1_state.player_dict),
			B_Bd_1v1_player = dict:fetch([KilledPlatform,KilledServer_num,KilledUid], State#kf_1v1_state.player_dict),
			case is_pid(A_Bd_1v1_player#bd_1v1_player.pk_pid) 
				andalso is_pid(B_Bd_1v1_player#bd_1v1_player.pk_pid) of
				false->%%无战斗进程
					NewState = State;
				true->%%有战斗进程
					Room_dict_List = dict:to_list(State#kf_1v1_state.room_dict),
					case lib_kf_1v1:look_match_4_kill(Room_dict_List,[Platform,Server_num,Uid,KilledPlatform,KilledServer_num,KilledUid]) of
						{error,_}->
							NewState = State;
						{ok,{Key,Bd_1v1_Room}}->
							%%清空观战人员
							clear_look_player(Key,State#kf_1v1_state.look_dict),
							[_Temp_Current_loop,APlatform,AServer_num,AId,_BPlatform,_BServer_num,_BId] = Key,
							A_Bd_1v1_player#bd_1v1_player.pk_pid!{over},
							B_Bd_1v1_player#bd_1v1_player.pk_pid!{over},
							[Win_pt,Loos_pt] = data_kf_1v1:get_pt(A_Bd_1v1_player#bd_1v1_player.pt_lv,A_Bd_1v1_player#bd_1v1_player.pt,B_Bd_1v1_player#bd_1v1_player.pt_lv,B_Bd_1v1_player#bd_1v1_player.pt),
							[Win_score,Loos_score] = data_kf_1v1:get_score(A_Bd_1v1_player#bd_1v1_player.pt_lv,A_Bd_1v1_player#bd_1v1_player.score,
																		   A_Bd_1v1_player#bd_1v1_player.combat_power,A_Bd_1v1_player#bd_1v1_player.lv,
																		   B_Bd_1v1_player#bd_1v1_player.pt_lv,B_Bd_1v1_player#bd_1v1_player.score,
																		   B_Bd_1v1_player#bd_1v1_player.combat_power,B_Bd_1v1_player#bd_1v1_player.lv),
							A_hp_rate = UidHp * 100 div UidHpLim,
							B_hp_rate = KilledUidHp  * 100 div KilledUidHpLim,
							case State#kf_1v1_state.bd_1v1_stauts of
								4->%%需结算
									Is_gift = 1;
								_->
									Is_gift = 0
							end,
							New_A_Bd_1v1_player = A_Bd_1v1_player#bd_1v1_player{
								win_loop = A_Bd_1v1_player#bd_1v1_player.win_loop + 1,
								hp = A_Bd_1v1_player#bd_1v1_player.hp + A_hp_rate,
								pt = Win_pt,
								score = Win_score,
								pk_pid = none,
								is_gift = Is_gift
							},
							New_B_Bd_1v1_player = B_Bd_1v1_player#bd_1v1_player{
								hp = B_Bd_1v1_player#bd_1v1_player.hp + B_hp_rate,
								pt = Loos_pt,
								score = Loos_score,
								pk_pid = none,
								is_gift = Is_gift
							},
							New_player_dict1 = dict:store([Platform,Server_num,Uid], New_A_Bd_1v1_player, State#kf_1v1_state.player_dict),
							New_player_dict2 = dict:store([KilledPlatform,KilledServer_num,KilledUid], New_B_Bd_1v1_player,New_player_dict1),
							if
								APlatform=:=Platform andalso AServer_num=:=Server_num andalso AId=:=Uid-> %%胜利的是Aid
									New_Log_1v1_dict = lib_kf_1v1:log_kf_1v1(UidPower,A_Bd_1v1_player#bd_1v1_player.carrer,
																			 KilledUidPower,B_Bd_1v1_player#bd_1v1_player.carrer,
																			 State#kf_1v1_state.log_1v1_dict),
									New_Bd_1v1_room = Bd_1v1_Room#bd_1v1_room{
										win_platform = Platform,
										win_server_num = Server_num,																	  
										win_id = Uid,																  
										player_a_power = UidPower, 	% 玩家战力
										player_a_hp = UidHp, 				% 玩家当前血量(判断胜负时的赋值)
										player_a_maxHp = UidHpLim, 		% 玩家最高血量(进行时，禁用一切改变属性操作)																   
										player_b_power = KilledUidPower, 	% 玩家战力
										player_b_hp = KilledUidHp, 				% 玩家当前血量(判断胜负时的赋值)
										player_b_maxHp = KilledUidHpLim 		% 玩家最高血量(进行时，禁用一切改变属性操作)									  
									},
									{ok, BinData} = pt_483:write(48308, [Platform,Server_num,Uid,
																		 Platform,Server_num,Uid,
																		A_Bd_1v1_player#bd_1v1_player.name,
																		A_Bd_1v1_player#bd_1v1_player.country,
																		A_Bd_1v1_player#bd_1v1_player.sex,
																		A_Bd_1v1_player#bd_1v1_player.carrer,
																		A_Bd_1v1_player#bd_1v1_player.image,
																		A_Bd_1v1_player#bd_1v1_player.lv,
																		UidPower,
																		New_Bd_1v1_room#bd_1v1_room.player_a_num,
																		UidHp,
																		UidHpLim,
																		KilledPlatform,KilledServer_num,KilledUid,
																		B_Bd_1v1_player#bd_1v1_player.name,
																		B_Bd_1v1_player#bd_1v1_player.country,
																		B_Bd_1v1_player#bd_1v1_player.sex,
																		B_Bd_1v1_player#bd_1v1_player.carrer,
																		B_Bd_1v1_player#bd_1v1_player.image,
																		B_Bd_1v1_player#bd_1v1_player.lv,
																		KilledUidPower,
																		New_Bd_1v1_room#bd_1v1_room.player_b_num,
																		KilledUidHp,
																		KilledUidHpLim,
																		A_Bd_1v1_player#bd_1v1_player.pt,
																		New_A_Bd_1v1_player#bd_1v1_player.pt,
																		A_Bd_1v1_player#bd_1v1_player.score,
																		New_A_Bd_1v1_player#bd_1v1_player.score,
																		B_Bd_1v1_player#bd_1v1_player.pt,
																		New_B_Bd_1v1_player#bd_1v1_player.pt,
																		B_Bd_1v1_player#bd_1v1_player.score,
																		New_B_Bd_1v1_player#bd_1v1_player.score,
																		New_Bd_1v1_room#bd_1v1_room.loop]);
								true->%%胜利的是Bid
									New_Log_1v1_dict = lib_kf_1v1:log_kf_1v1(KilledUidPower,B_Bd_1v1_player#bd_1v1_player.carrer,
																			 UidPower,A_Bd_1v1_player#bd_1v1_player.carrer,
																			 State#kf_1v1_state.log_1v1_dict),
									New_Bd_1v1_room = Bd_1v1_Room#bd_1v1_room{
										win_platform = Platform,
										win_server_num = Server_num,																	  
										win_id = Uid,																	  
										player_a_power = KilledUidPower, 	% 玩家战力
										player_a_hp = KilledUidHp, 				% 玩家当前血量(判断胜负时的赋值)
										player_a_maxHp = KilledUidHpLim, 		% 玩家最高血量(进行时，禁用一切改变属性操作)									  
										player_b_power = UidPower, 	% 玩家战力
										player_b_hp = UidHp, 				% 玩家当前血量(判断胜负时的赋值)
										player_b_maxHp = UidHpLim 		% 玩家最高血量(进行时，禁用一切改变属性操作)																   
									},
									{ok, BinData} = pt_483:write(48308, [Platform,Server_num,Uid,
																		KilledPlatform,KilledServer_num,KilledUid,
																		B_Bd_1v1_player#bd_1v1_player.name,
																		B_Bd_1v1_player#bd_1v1_player.country,
																		B_Bd_1v1_player#bd_1v1_player.sex,
																		B_Bd_1v1_player#bd_1v1_player.carrer,
																		B_Bd_1v1_player#bd_1v1_player.image,
																		B_Bd_1v1_player#bd_1v1_player.lv,
																		KilledUidPower,
																		New_Bd_1v1_room#bd_1v1_room.player_a_num,
																		KilledUidHp,
																		KilledUidHpLim,
																		Platform,Server_num,Uid,
																		A_Bd_1v1_player#bd_1v1_player.name,
																		A_Bd_1v1_player#bd_1v1_player.country,
																		A_Bd_1v1_player#bd_1v1_player.sex,
																		A_Bd_1v1_player#bd_1v1_player.carrer,
																		A_Bd_1v1_player#bd_1v1_player.image,
																		A_Bd_1v1_player#bd_1v1_player.lv,
																		UidPower,
																		New_Bd_1v1_room#bd_1v1_room.player_b_num,
																		UidHp,
																		UidHpLim,
																		B_Bd_1v1_player#bd_1v1_player.pt,
																		New_B_Bd_1v1_player#bd_1v1_player.pt,
																		B_Bd_1v1_player#bd_1v1_player.score,
																		New_B_Bd_1v1_player#bd_1v1_player.score,
																		A_Bd_1v1_player#bd_1v1_player.pt,
																		New_A_Bd_1v1_player#bd_1v1_player.pt,
																		A_Bd_1v1_player#bd_1v1_player.score,
																		New_A_Bd_1v1_player#bd_1v1_player.score,
																		New_Bd_1v1_room#bd_1v1_room.loop])
							end,
							
							mod_clusters_center:apply_cast(New_A_Bd_1v1_player#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[Uid,BinData]),
							mod_clusters_center:apply_cast(New_B_Bd_1v1_player#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[KilledUid,BinData]),
							New_room_dict = dict:store(Key, New_Bd_1v1_room, State#kf_1v1_state.room_dict),
							case State#kf_1v1_state.bd_1v1_stauts of
								4->%%需结算
									spawn(fun()->
										timer:sleep(3*1000),
										[SceneId,X,Y] = data_kf_1v1:get_bd_1v1_config(leave_scene),
										mod_clusters_center:apply_cast(New_A_Bd_1v1_player#bd_1v1_player.node,
																	   lib_scene,player_change_scene_queue,
																	   [New_A_Bd_1v1_player#bd_1v1_player.id,SceneId,0,X,Y,0]),
										mod_clusters_center:apply_cast(New_B_Bd_1v1_player#bd_1v1_player.node,
																	   lib_scene,player_change_scene_queue,
																	   [New_B_Bd_1v1_player#bd_1v1_player.id,SceneId,0,X,Y,0])
									end);
								_->
									spawn(fun()->
										timer:sleep(3*1000),
										Bd_1v1_Scene_id1 = data_kf_1v1:get_bd_1v1_config(scene_id1),
										[X,Y] = data_kf_1v1:get_position1(),
										mod_clusters_center:apply_cast(New_A_Bd_1v1_player#bd_1v1_player.node,lib_scene,player_change_scene_queue,[Uid,Bd_1v1_Scene_id1,A_Bd_1v1_player#bd_1v1_player.copy_id,X,Y,0]),
										mod_clusters_center:apply_cast(New_B_Bd_1v1_player#bd_1v1_player.node,lib_scene,player_change_scene_queue,[KilledUid,Bd_1v1_Scene_id1,B_Bd_1v1_player#bd_1v1_player.copy_id,X,Y,0])
									end),
									
									{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
									NowTime = (Hour*60+Minute)*60 + Second,
									_RestTime = State#kf_1v1_state.loop_end - NowTime, 
									_WholeRestTime = State#kf_1v1_state.config_end - NowTime, 
									if
										_RestTime>=0->RestTime = _RestTime;
										true-> RestTime = 0
									end,
									if
										_WholeRestTime>=0->WholeRestTime = _WholeRestTime;
										true-> WholeRestTime = 0
									end,
									{ok, BinDataA2} = pt_483:write(48304, [State#kf_1v1_state.loop,State#kf_1v1_state.bd_1v1_stauts,RestTime,WholeRestTime,State#kf_1v1_state.current_loop,
																		  New_A_Bd_1v1_player#bd_1v1_player.loop,0,New_A_Bd_1v1_player#bd_1v1_player.loop_day]),
									{ok, BinDataB2} = pt_483:write(48304, [State#kf_1v1_state.loop,State#kf_1v1_state.bd_1v1_stauts,RestTime,WholeRestTime,State#kf_1v1_state.current_loop,
																		  New_B_Bd_1v1_player#bd_1v1_player.loop,0,New_B_Bd_1v1_player#bd_1v1_player.loop_day]),
									mod_clusters_center:apply_cast(New_A_Bd_1v1_player#bd_1v1_player.node,lib_unite_send,cluster_to_uid, [New_A_Bd_1v1_player#bd_1v1_player.id,BinDataA2]),
									mod_clusters_center:apply_cast(New_B_Bd_1v1_player#bd_1v1_player.node,lib_unite_send,cluster_to_uid, [New_B_Bd_1v1_player#bd_1v1_player.id,BinDataB2])
							end,
							NewState = State#kf_1v1_state{
								player_dict = New_player_dict2,
								log_1v1_dict = New_Log_1v1_dict,
								room_dict = New_room_dict
							}
					end
			end
	end,
	
	{noreply, NewState}; 

handle_cast({exit_prepare,Node,Platform,Server_num,Id}, State) ->
	case dict:is_key([Platform,Server_num,Id], State#kf_1v1_state.player_dict) of
		false-> 
			Result = 2,
			NewState = State;
		true->
			Room_dict_List = dict:to_list(State#kf_1v1_state.room_dict),
			case lib_kf_1v1:look_match(Room_dict_List,[Platform,Server_num,Id]) of
				{error,_}->%%没有匹配记录
					Bd_1v1_player = dict:fetch([Platform,Server_num,Id], State#kf_1v1_state.player_dict),
					New_sign_up_dict = dict:erase([Platform,Server_num,Id], State#kf_1v1_state.sign_up_dict),
					New_Bd_1v1_player = Bd_1v1_player#bd_1v1_player{is_in = 0},
					New_player_dict = dict:store([Platform,Server_num,Id], New_Bd_1v1_player, State#kf_1v1_state.player_dict),
					NewState = State#kf_1v1_state{
						player_dict = New_player_dict,
						sign_up_dict = New_sign_up_dict				
					},
					Result = 1,
					[SceneId,X,Y] = data_kf_1v1:get_bd_1v1_config(leave_scene),
					CopyId = 0,
					mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,[Id,SceneId,CopyId,X,Y,0]);
				{ok,{_Key,_Bd_1v1_Room}}->
					Result = 3,
					NewState = State
			end
	end,
	{ok, BinData} = pt_483:write(48303, [Result]),
	mod_clusters_center:apply_cast(Node,lib_unite_send,cluster_to_uid,[Id,BinData]),
	
	{noreply, NewState};

handle_cast({in_or_exit_prepare,Platform,Server_num,Id,IsIn,Combat_power}, State) ->
	case dict:is_key([Platform,Server_num,Id], State#kf_1v1_state.player_dict) of
		false-> NewState = State;
		true-> 
			Bd_1v1_player = dict:fetch([Platform,Server_num,Id], State#kf_1v1_state.player_dict),
			case IsIn of
				1-> %%进入战场，需要更新玩家战力
					New_sign_up_dict = State#kf_1v1_state.sign_up_dict,
					New_Bd_1v1_player = Bd_1v1_player#bd_1v1_player{
						is_in = IsIn,
						combat_power = Combat_power	
					};
				_->
					New_sign_up_dict = dict:erase([Platform,Server_num,Id], State#kf_1v1_state.sign_up_dict),
					New_Bd_1v1_player = Bd_1v1_player#bd_1v1_player{is_in = IsIn}
			end,
			New_player_dict = dict:store([Platform,Server_num,Id], New_Bd_1v1_player, State#kf_1v1_state.player_dict),
			NewState = State#kf_1v1_state{
				player_dict = New_player_dict,
				sign_up_dict = New_sign_up_dict				
			}
	end,
	{noreply, NewState};  

handle_cast({set_status,Bd_1v1_Status}, State) ->
	NewState = State#kf_1v1_state{bd_1v1_stauts=Bd_1v1_Status},
	{noreply, NewState};
 
handle_cast({open_bd_1v1,Loop,Loop_time,Sign_up_time}, _State) ->
	Bd_1v1_stauts = 1,
	Temp_NewState = #kf_1v1_state{
		bd_1v1_stauts=Bd_1v1_stauts,		 %% 0还未开启  1开启报名中 2开启准备中 3开启比赛中 4已结束
		loop = Loop,				 		 %% 总轮次
		loop_time = Loop_time,				 %% 轮次
		sign_up_time = Sign_up_time,           %% 报名时间（分）
		current_loop = 0		 			 %% 当前轮次
	},
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60 + Second,
	
	[SleepTime,T_NewState] = match(0,[],dict:new(),Temp_NewState),
	NewState = T_NewState#kf_1v1_state{
		loop_end=NowTime+(SleepTime div 1000)			 %% 本轮比赛结束时间(秒)							   
	},
	
	_RestTime = NewState#kf_1v1_state.loop_end - NowTime, 
	_WholeRestTime = NewState#kf_1v1_state.config_end - NowTime, 
	if
		_RestTime>=0->RestTime = _RestTime;
		true-> RestTime = 0
	end,
	if
		_WholeRestTime>=0->WholeRestTime = _WholeRestTime;
		true-> WholeRestTime = 0
	end,
	spawn(fun()-> 
		PlayerDictList = dict:to_list(NewState#kf_1v1_state.player_dict),
		lists:foreach(fun({_K,V})-> 
			{ok, BinData2} = pt_483:write(48304, [NewState#kf_1v1_state.loop,NewState#kf_1v1_state.bd_1v1_stauts,RestTime,WholeRestTime,NewState#kf_1v1_state.current_loop,V#bd_1v1_player.loop,0,V#bd_1v1_player.loop_day]),							  
			mod_clusters_center:apply_cast(V#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[V#bd_1v1_player.id,BinData2])				  
		end, PlayerDictList)
	end),
	
	{noreply, NewState};

handle_cast({sign_up_end}, State) ->
	Current_Loop = State#kf_1v1_state.current_loop + 1,
	if
		Current_Loop>=State#kf_1v1_state.loop->%%最后一轮
			mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_status,[4]),
			Bd_1v1_stauts = 4;
		true->
			mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_status,[1]),
			Bd_1v1_stauts = 1
	end,
	
	Temp_State = State#kf_1v1_state{
		current_loop = Current_Loop,								   
		bd_1v1_stauts=Bd_1v1_stauts,		 %% 0还未开启  1开启报名中 2开启准备中 3开启比赛中 4已结束
		sign_up_dict = dict:new()					 %%清空报名列表
	},
	
	%% 匹配名单
	Temp_Player_List = dict:to_list(State#kf_1v1_state.player_dict),
	%% 找出报名玩家
	Player_List = [Player||{_Key,Player}<-Temp_Player_List,
						   Player#bd_1v1_player.is_in=:=1,
						   dict:is_key([Player#bd_1v1_player.platform,
										 Player#bd_1v1_player.server_num,
										 Player#bd_1v1_player.id], 
									   State#kf_1v1_state.sign_up_dict)],
	Sort_Player_List = lists:sort(fun(A,B)-> 
		A_canshu = get_canshu(A,State#kf_1v1_state.sign_up_dict),
		B_canshu = get_canshu(B,State#kf_1v1_state.sign_up_dict),
		if
			A_canshu>=B_canshu->true;
			true->false
		end
	end,Player_List),
	
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60 + Second,
	
	[SleepTime,T_NewState] = match(0,Sort_Player_List,State#kf_1v1_state.sign_up_dict,Temp_State),
	NewState = T_NewState#kf_1v1_state{
		loop_end=NowTime+(SleepTime div 1000)			 %% 本轮比赛结束时间(秒)							   
	},
	
	_RestTime = NewState#kf_1v1_state.loop_end - NowTime, 
	_WholeRestTime = NewState#kf_1v1_state.config_end - NowTime, 
	if
		_RestTime>=0->RestTime = _RestTime;
		true-> RestTime = 0
	end,
	if
		_WholeRestTime>=0->WholeRestTime = _WholeRestTime;
		true-> WholeRestTime = 0
	end,
	PlayerDictList = dict:to_list(NewState#kf_1v1_state.player_dict),
	lists:foreach(fun({_K,V})-> 
		case is_pid(V#bd_1v1_player.pk_pid) of
			false->
				case dict:is_key([V#bd_1v1_player.platform,
								   V#bd_1v1_player.server_num,
								   V#bd_1v1_player.id], NewState#kf_1v1_state.sign_up_dict) of
					false->IsSign = 0;
					true->IsSign = 1
				end,
				{ok, BinData2} = pt_483:write(48304, [NewState#kf_1v1_state.loop,NewState#kf_1v1_state.bd_1v1_stauts,RestTime,WholeRestTime,NewState#kf_1v1_state.current_loop,V#bd_1v1_player.loop,IsSign,V#bd_1v1_player.loop_day]),
				mod_clusters_center:apply_cast(V#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[V#bd_1v1_player.id,BinData2]);				  
			true->void	
		end
	end, PlayerDictList),
	
	spawn(fun()-> 
		RoomDictList = dict:to_list(NewState#kf_1v1_state.room_dict),				  
		set_player_top_list(NewState#kf_1v1_state.player_dict,RoomDictList,Current_Loop)			  
	end),
	
	{noreply, NewState};

handle_cast({goin_war,Player,Element,Bd_1v1_room}, State) ->
	Key = [Bd_1v1_room#bd_1v1_room.loop,
		   Player#bd_1v1_player.platform,Player#bd_1v1_player.server_num,Player#bd_1v1_player.id,
		   Element#bd_1v1_player.platform,Element#bd_1v1_player.server_num,Element#bd_1v1_player.id],
	case dict:is_key(Key, State#kf_1v1_state.room_dict) of
		false->
			void;
		true->
			New_Bd_1v1_room = dict:fetch(Key, State#kf_1v1_state.room_dict),
			if
				New_Bd_1v1_room#bd_1v1_room.win_id/=0->%%已经分胜负
					void;
				true->
					%%拖人
					Bd_1v1_Scene_id2 = data_kf_1v1:get_bd_1v1_config(scene_id2),
					[[X1,Y1],[X2,Y2]] = data_kf_1v1:get_bd_1v1_config(position2),
					CopyId = integer_to_list(Bd_1v1_room#bd_1v1_room.loop) 
								 ++ "_" ++ Player#bd_1v1_player.platform
								 ++ "_" ++ integer_to_list(Player#bd_1v1_player.server_num) 
								 ++ "_" ++ integer_to_list(Player#bd_1v1_player.id) 
								 ++ "_" ++ Element#bd_1v1_player.platform
								 ++ "_" ++ integer_to_list(Element#bd_1v1_player.server_num) 
						         ++ "_" ++ integer_to_list(Element#bd_1v1_player.id),
					spawn(fun()-> 
						timer:sleep((State#kf_1v1_state.loop_time+1)*60*1000),				  
						mod_scene_agent:apply_cast(Bd_1v1_Scene_id2, mod_scene, clear_scene, [Bd_1v1_Scene_id2, CopyId])		  
					end),
					
					{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
					NowTime = (Hour*60+Minute)*60 + Second,
					_WholeRestTime = State#kf_1v1_state.config_end - NowTime, 
					if
						_WholeRestTime>=0->WholeRestTime = _WholeRestTime;
						true-> WholeRestTime = 0
					end,
					{ok, BinDataA3} = pt_483:write(48304, [State#kf_1v1_state.loop,3,State#kf_1v1_state.loop_time*60,WholeRestTime,State#kf_1v1_state.current_loop,Player#bd_1v1_player.loop,1,Player#bd_1v1_player.loop_day]),
					{ok, BinDataB3} = pt_483:write(48304, [State#kf_1v1_state.loop,3,State#kf_1v1_state.loop_time*60,WholeRestTime,State#kf_1v1_state.current_loop,Element#bd_1v1_player.loop,1,Element#bd_1v1_player.loop_day]),
					New_Player = dict:fetch([Player#bd_1v1_player.platform,Player#bd_1v1_player.server_num,Player#bd_1v1_player.id], State#kf_1v1_state.player_dict),
					New_Element = dict:fetch([Element#bd_1v1_player.platform,Element#bd_1v1_player.server_num,Element#bd_1v1_player.id], State#kf_1v1_state.player_dict),
					if
						New_Player#bd_1v1_player.is_in /= 1-> %%外面的，直接阻止进入
							{ok, BinData} = pt_483:write(48302, [4,0,0,0,0,0,0,0,0]),
							mod_clusters_center:apply_cast(Player#bd_1v1_player.node,lib_unite_send,cluster_to_uid, [Player#bd_1v1_player.id,BinData]);
						true->
							mod_clusters_center:apply_cast(Player#bd_1v1_player.node,lib_unite_send,cluster_to_uid, [Player#bd_1v1_player.id,BinDataA3]),
							mod_clusters_center:apply_cast(Player#bd_1v1_player.node,lib_scene,player_change_scene_queue,[Player#bd_1v1_player.id,Bd_1v1_Scene_id2,CopyId,X1,Y1,[{resume_hp_lim,ok}]])
							%mod_clusters_center:apply_cast(Player#bd_1v1_player.node,lib_player,update_player_info,[Player#bd_1v1_player.id,[{resume_hp_lim,ok}]])
					end,
					if
						New_Element#bd_1v1_player.is_in /= 1-> %%外面的，直接阻止进入
							{ok, BinData2} = pt_483:write(48302, [4,0,0,0,0,0,0,0,0]),
							mod_clusters_center:apply_cast(Element#bd_1v1_player.node,lib_unite_send,cluster_to_uid, [Element#bd_1v1_player.id,BinData2]);
						true->
							mod_clusters_center:apply_cast(Element#bd_1v1_player.node,lib_unite_send,cluster_to_uid, [Element#bd_1v1_player.id,BinDataB3]),
							mod_clusters_center:apply_cast(Element#bd_1v1_player.node,lib_scene,player_change_scene_queue,[Element#bd_1v1_player.id,Bd_1v1_Scene_id2,CopyId,X2,Y2,[{resume_hp_lim,ok}]])
							%mod_clusters_center:apply_cast(Element#bd_1v1_player.node,lib_player,update_player_info,[Element#bd_1v1_player.id,[{resume_hp_lim,ok}]])
					end
			end
	end,
	
	{noreply, State};

handle_cast({end_each_war,Player,Element,Bd_1v1_room}, State) ->
	Key = [Bd_1v1_room#bd_1v1_room.loop,
		   Player#bd_1v1_player.platform,Player#bd_1v1_player.server_num,Player#bd_1v1_player.id,
		   Element#bd_1v1_player.platform,Element#bd_1v1_player.server_num,Element#bd_1v1_player.id],
	case dict:is_key(Key, State#kf_1v1_state.room_dict) of
		false->
			NewState = State;
		true->
			New_Bd_1v1_room = dict:fetch(Key, State#kf_1v1_state.room_dict),
			if
				New_Bd_1v1_room#bd_1v1_room.win_id/=0->%%已经分胜负
					NewState = State;
				true->
					NewState = make_win(Bd_1v1_room,State),
					{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
					NowTime = (Hour*60+Minute)*60 + Second,
					_RestTime = NewState#kf_1v1_state.loop_end - NowTime, 
					_WholeRestTime = NewState#kf_1v1_state.config_end - NowTime, 
					if
						_RestTime>=0->RestTime = _RestTime;
						true-> RestTime = 0
					end,
					if
						_WholeRestTime>=0->WholeRestTime = _WholeRestTime;
						true-> WholeRestTime = 0
					end,
					{ok, BinDataA2} = pt_483:write(48304, [NewState#kf_1v1_state.loop,NewState#kf_1v1_state.bd_1v1_stauts,RestTime,WholeRestTime,NewState#kf_1v1_state.current_loop,Player#bd_1v1_player.loop,0,Player#bd_1v1_player.loop_day]),
					{ok, BinDataB2} = pt_483:write(48304, [NewState#kf_1v1_state.loop,NewState#kf_1v1_state.bd_1v1_stauts,RestTime,WholeRestTime,NewState#kf_1v1_state.current_loop,Element#bd_1v1_player.loop,0,Element#bd_1v1_player.loop_day]),
					mod_clusters_center:apply_cast(Player#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[Player#bd_1v1_player.id,BinDataA2]),
					mod_clusters_center:apply_cast(Element#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[Element#bd_1v1_player.id,BinDataB2])
			end
	end,
	
	{noreply, NewState};
	
handle_cast({end_bd_1v1}, State) ->
	%% 设置新状态
	Bd_1v1_stauts = 4,
	%%排序：胜率大、剩余平均血量的
	Player_dict_List = dict:to_list(State#kf_1v1_state.player_dict),
	NewState = State#kf_1v1_state{bd_1v1_stauts = Bd_1v1_stauts},
	
	%%处理
	spawn(fun()-> 
		spawn(fun()-> 
			%% 统一结算、发奖
		    lists:foreach(fun({_K,Player})-> 
				balance(Player),
				timer:sleep(50),
				spawn(fun()-> 
					%% 每一场结束时间调用，刷新排行榜
					%% List = [#bd_1v1_player, ...]
					mod_rank_cls:update_1v1_rank_user([Player])			  
				end)
			end, Player_dict_List),
			%%按名次发奖
			Sort_Player_dict_List = lib_kf_1v1:sort_player(Player_dict_List),
			send_gift_by_no(Sort_Player_dict_List,1),
			spawn(fun()-> 
				%% 活动结束后刷新排行榜
				timer:sleep(20 * 1000),
				mod_rank_cls:broadcast_kf_1v1_rank()
			end)
		end),

		spawn(fun()-> 
			lib_kf_1v1:update_log_kf_1v1(State#kf_1v1_state.log_1v1_dict)			  
		end),
		
		%%告知定时器结束
		mod_kf_1v1_mgr:go_finish(),
		
		timer:sleep(1000*60),
        %%处理场景
        mod_scene_init:clear_scene(data_kf_1v1:get_bd_1v1_config(scene_id1)),
        mod_scene_init:clear_scene(data_kf_1v1:get_bd_1v1_config(scene_id2))
	end),
	
	spawn(fun()-> 
		set_player_top_list(NewState#kf_1v1_state.player_dict,[],0)					  
	end),
	
	{noreply, NewState};

handle_cast(_Msg, State) ->
    {noreply, State}.

%%清空观战玩家
%% @param Key Look_dict的key,即room_id
clear_look_player(Key,Look_dict)->
	case dict:is_key(Key, Look_dict) of
		false->void;
		true->
			Scene_Id1 = data_kf_1v1:get_bd_1v1_config(scene_id1),
			Look_List = dict:fetch(Key, Look_dict),
			lists:foreach(fun({Node,Id,Copy_id})-> 
				[X,Y] = data_kf_1v1:get_position1(),
				mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,[Id,Scene_Id1,Copy_id,X,Y,0])
			end, Look_List)
	end.
%%清除观战名单
remove_look(_Node,_Id,_Copy_id,[],Look_dict)->Look_dict;
remove_look(Node,Id,Copy_id,[{K,List}|T],Look_dict)->
	New_List = lists:delete({Node,Id,Copy_id}, List),
	New_Look_dict = dict:store(K, New_List, Look_dict),
	remove_look(Node,Id,Copy_id,T,New_Look_dict).

%%按名次发奖
send_gift_by_no([],_Pos)->ok;
send_gift_by_no([{_K,Player}|T],Pos)->
	Min_loop = data_kf_1v1:get_bd_1v1_config(min_loop),	
	if
		Pos=<100 andalso Min_loop=<Player#bd_1v1_player.loop->
			[GiftId2,Num2] = data_kf_1v1:get_gift(Pos),	
			Title2 = io_lib:format(data_mail_log_text:get_mail_log_text(kf_1v1_title2),[Pos]),
			Content2 = io_lib:format(data_mail_log_text:get_mail_log_text(kf_1v1_content2),[Pos]),
			mod_clusters_center:apply_cast(Player#bd_1v1_player.node,lib_mail,send_sys_mail_bg_4_1v1,[[Player#bd_1v1_player.id], Title2, Content2, GiftId2, 2, 0, 0,Num2,0,0,0,0]),
			timer:sleep(50),
			send_gift_by_no(T,Pos+1);
		true->
			ok
	end.

%%设置前100名玩家给各服
set_player_top_list(Player_dict,RoomDictList,Current_Loop)->
	Player_dict_List = dict:to_list(Player_dict),
	Sort_Player_dict_List = lib_kf_1v1:sort_player(Player_dict_List),
	if
		length(Sort_Player_dict_List)>100->
			{F_Sort_Player_Dict_List,_} = lists:split(100, Sort_Player_dict_List);
		true->
			F_Sort_Player_Dict_List = Sort_Player_dict_List
	end,
	if
		length(Sort_Player_dict_List)>20->
			{F_Sort_Player_Dict_List_20,_} = lists:split(20, Sort_Player_dict_List);
		true->
			F_Sort_Player_Dict_List_20 = Sort_Player_dict_List
	end,
	%%符合战力高于2W的玩家
	Top20_Key = [K||{K,P}<-F_Sort_Player_Dict_List_20,P#bd_1v1_player.max_combat_power>=20000],
	Top_20_Look = get_top_20_look(Top20_Key,Player_dict,RoomDictList,Current_Loop,[]),
	TopList = lib_kf_1v1:get_top(F_Sort_Player_Dict_List,[]),
	mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_look_list,[Top_20_Look]),
	mod_clusters_center:apply_to_all_node(mod_kf_1v1_state,set_top_list,[TopList]),
	ok.
get_top_20_look([],_Player_dict,_RoomDictList,_Current_Loop,List)->List;
get_top_20_look(_Top20_Key,_Player_dict,[],_Current_Loop,List)->List;
get_top_20_look(Top20_Key,Player_dict,[{K,Room}|T],Current_Loop,List)->
	[Loop,A_Flat,A_Server_id,A_Id,B_Flat,B_Server_id,B_Id] = K,
	if
		Loop =:= Current_Loop -> %同一轮的
			if
				Room#bd_1v1_room.win_id=:=0->%%战斗未结束
					Flag1 = lists:member([A_Flat,A_Server_id,A_Id], Top20_Key),
					Flag2 = lists:member([B_Flat,B_Server_id,B_Id], Top20_Key),
					if
						Flag1 orelse Flag2 -> %%是它的战斗
							Player_A = dict:fetch([A_Flat,A_Server_id,A_Id], Player_dict),
							Player_B = dict:fetch([B_Flat,B_Server_id,B_Id], Player_dict),
							get_top_20_look(Top20_Key,Player_dict,T,Current_Loop,List++[{
								Current_Loop,
								
								Player_A#bd_1v1_player.platform,
								Player_A#bd_1v1_player.server_num,	
								Player_A#bd_1v1_player.id,
								Player_A#bd_1v1_player.name,
								Player_A#bd_1v1_player.country,
								Player_A#bd_1v1_player.sex,
								Player_A#bd_1v1_player.carrer,
								Player_A#bd_1v1_player.image,
								Player_A#bd_1v1_player.lv,
								Player_A#bd_1v1_player.max_combat_power,
								
								Player_B#bd_1v1_player.platform,
								Player_B#bd_1v1_player.server_num,	
								Player_B#bd_1v1_player.id,
								Player_B#bd_1v1_player.name,
								Player_B#bd_1v1_player.country,
								Player_B#bd_1v1_player.sex,
								Player_B#bd_1v1_player.carrer,
								Player_B#bd_1v1_player.image,
								Player_B#bd_1v1_player.lv,
								Player_B#bd_1v1_player.max_combat_power
							}]);
						true->
							get_top_20_look(Top20_Key,Player_dict,T,Current_Loop,List)
					end;
				true->
					get_top_20_look(Top20_Key,Player_dict,T,Current_Loop,List)
			end;
		true->
			get_top_20_look(Top20_Key,Player_dict,T,Current_Loop,List)
	end.

%%结算方法（针对单个国家）
%%@param Player 玩家记录
balance(Player)->
	%%发送结束协议
    {ok, BinData} = pt_483:write(48309, []),
	mod_clusters_center:apply_cast(Player#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[Player#bd_1v1_player.id,BinData]),
	%%入库
	mod_clusters_center:apply_cast(Player#bd_1v1_player.node,lib_player,
							update_player_info,[Player#bd_1v1_player.id,
							[{kf_1v1,[
								Player#bd_1v1_player.loop,
								Player#bd_1v1_player.win_loop,
								Player#bd_1v1_player.hp,
								Player#bd_1v1_player.pt,
								Player#bd_1v1_player.score]}]]),
	Min_loop = data_kf_1v1:get_bd_1v1_config(min_loop),	
	if
		Min_loop=<Player#bd_1v1_player.loop->
			Loop = Player#bd_1v1_player.loop,
			WinLoop = Player#bd_1v1_player.win_loop,
			%%发送邮件
			[GiftId,Num] = data_kf_1v1:get_gift(Loop,WinLoop),	
			Title = data_mail_log_text:get_mail_log_text(kf_1v1_title),
			Content = io_lib:format(data_mail_log_text:get_mail_log_text(kf_1v1_content),[Loop,WinLoop,Loop-WinLoop,Num]),
			mod_clusters_center:apply_cast(Player#bd_1v1_player.node,lib_mail,
										   send_sys_mail_bg_4_1v1,
										   [[Player#bd_1v1_player.id], 
											Title, Content, GiftId, 
											2, 0, 0,Num,0,0,0,0]);
		true->
			void
	end,
	%%没出来的传出去
	case Player#bd_1v1_player.is_gift of
		0->
			case Player#bd_1v1_player.is_in of
				0->
					void;
				_->%%当成在场子里的
					[SceneId,X,Y] = data_kf_1v1:get_bd_1v1_config(leave_scene),
					mod_clusters_center:apply_cast(Player#bd_1v1_player.node,
												   lib_scene,player_change_scene_queue,
												   [Player#bd_1v1_player.id,SceneId,0,X,Y,0])
			end;
		_->
			void
	end.

%%获取排序参数
%%@param A #bd_1v1_player
%%@param Sign_up_dict 报名字典
%%@return 排名参数
get_canshu(A,Sign_up_dict)->
	%%战斗力+等级*300+胜率*5000+等待时间*500+声望等级*1000+周积分*50					
	if
		A#bd_1v1_player.loop=<0->
			A_rate = 0;
		true->
			A_rate = A#bd_1v1_player.win_loop/A#bd_1v1_player.loop
	end,
	A_Cishu = dict:fetch([A#bd_1v1_player.platform,A#bd_1v1_player.server_num,A#bd_1v1_player.id],Sign_up_dict),
	if
		A#bd_1v1_player.max_combat_power=<40000->
			A_canshu = A#bd_1v1_player.max_combat_power + A#bd_1v1_player.lv*200 + A_rate*2000 + A_Cishu*500
					   + (A#bd_1v1_player.win_loop*2-A#bd_1v1_player.loop)*200;			
		true->
			A_canshu = A#bd_1v1_player.max_combat_power + A#bd_1v1_player.lv*200 + A_rate*1500 + A_Cishu*500
	end,
%% 			   + A_Cishu*500 + A#bd_1v1_player.pt_lv*2000 + A#bd_1v1_player.score*10,
	A_canshu.

%% 匹配对手
%% @param PlayerList 选手列表
%% @param State 状态
%% @return New_State
match(SleepTime,[],_Sign_up_dict,State)->
	Sign_up_time = State#kf_1v1_state.sign_up_time*60*1000,
	%%针对第一轮延长匹配时间（3分钟）
	if
		State#kf_1v1_state.current_loop=:=0->
			Add_Time = 2*60*1000;
		true->
			Add_Time = 0
	end,
	if
		Sign_up_time=<SleepTime->%%睡眠时间更长
			Rest_time = SleepTime + Add_Time;
		true->%%匹配最低时间更长
			Rest_time = Sign_up_time + Add_Time
	end,
	if
		State#kf_1v1_state.loop=<State#kf_1v1_state.current_loop->%%走结束流程
			Loop_time = State#kf_1v1_state.loop_time*60*1000 + 30*1000,
			spawn(fun()-> 
				timer:sleep(Rest_time+Loop_time),
				%通知服务结算
				mod_kf_1v1:end_bd_1v1()	
			end);
		true->
			spawn(fun()-> 
				timer:sleep(Rest_time),
				%通知服务再次匹配
				mod_kf_1v1:sign_up_end()	
			end)
	end,
	[Rest_time,State];
match(SleepTime,[Player],Sign_up_dict,State)-> %%处理封单情况,增加失败次数，丢入下一次匹配
	Cishu = dict:fetch([Player#bd_1v1_player.platform,
						Player#bd_1v1_player.server_num,
						Player#bd_1v1_player.id], Sign_up_dict),
	New_Sign_up_dict = dict:store([Player#bd_1v1_player.platform,
						Player#bd_1v1_player.server_num,
						Player#bd_1v1_player.id], Cishu+1, 
					   State#kf_1v1_state.sign_up_dict),
	New_State = State#kf_1v1_state{
		sign_up_dict = 	New_Sign_up_dict					   
	},
	{ok,DataBin} = pt_483:write(48300, [4]),
	mod_clusters_center:apply_cast(Player#bd_1v1_player.node,
								   lib_unite_send,cluster_to_uid,
								   [Player#bd_1v1_player.id,DataBin]),
	match(SleepTime,[],Sign_up_dict,New_State);
match(SleepTime,[Player|T],Sign_up_dict,State)->
	Cishu = dict:fetch([Player#bd_1v1_player.platform,
						Player#bd_1v1_player.server_num,
						Player#bd_1v1_player.id], Sign_up_dict),
	Player_canshu = get_canshu(Player,Sign_up_dict),
	Canshu_gap = data_kf_1v1:get_canshu_gap(Player#bd_1v1_player.max_combat_power,Cishu),
	
	List = get_random_list(Player_canshu,Canshu_gap,Sign_up_dict,T,[]),
	if
		length(List)=<0 ->%超过允许范围，匹配失败
			New_Sign_up_dict = dict:store([Player#bd_1v1_player.platform,
								Player#bd_1v1_player.server_num,
								Player#bd_1v1_player.id], Cishu+1, 
							   State#kf_1v1_state.sign_up_dict),
			New_State = State#kf_1v1_state{
				sign_up_dict = 	New_Sign_up_dict					   
			},
			{ok,DataBin} = pt_483:write(48300, [4]),
			mod_clusters_center:apply_cast(Player#bd_1v1_player.node,
										   lib_unite_send,cluster_to_uid,
										   [Player#bd_1v1_player.id,DataBin]),
			match(SleepTime,T,Sign_up_dict,New_State);
		true->
			N = util:rand(1,length(List)),
			Element = lists:nth(N, List),
			[A_Luck,B_Luck] = make_luck(),
			Bd_1v1_room = #bd_1v1_room{
				loop = State#kf_1v1_state.current_loop, 				% 轮次
				player_a_platform = Player#bd_1v1_player.platform,
				player_a_server_num = Player#bd_1v1_player.server_num,
				player_a_id = Player#bd_1v1_player.id, 		% 玩家Id
				player_a_power = Player#bd_1v1_player.combat_power,
				player_a_num = A_Luck, 		% 玩家幸运指数
				player_b_platform = Element#bd_1v1_player.platform,
				player_b_server_num = Element#bd_1v1_player.server_num,
				player_b_id = Element#bd_1v1_player.id, 		% 玩家Id
				player_b_power = Element#bd_1v1_player.combat_power,
				player_b_num = B_Luck 		% 玩家幸运指数		 
			},
			{ok,DataBin} = pt_483:write(48307, [Player#bd_1v1_player.platform,Player#bd_1v1_player.server_num,Player#bd_1v1_player.id,Player#bd_1v1_player.name,Player#bd_1v1_player.country,
												Player#bd_1v1_player.sex,Player#bd_1v1_player.carrer,Player#bd_1v1_player.image,
												Player#bd_1v1_player.lv,Player#bd_1v1_player.combat_power,A_Luck,
			  						            Element#bd_1v1_player.platform,Element#bd_1v1_player.server_num,Element#bd_1v1_player.id,Element#bd_1v1_player.name,Element#bd_1v1_player.country,
												Element#bd_1v1_player.sex,Element#bd_1v1_player.carrer,Element#bd_1v1_player.image,
												Element#bd_1v1_player.lv,Element#bd_1v1_player.combat_power,B_Luck]),
			mod_clusters_center:apply_cast(Player#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[Player#bd_1v1_player.id,DataBin]),
			mod_clusters_center:apply_cast(Element#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[Element#bd_1v1_player.id,DataBin]),
			%%开启战斗进程
			Pk_Pid = spawn(fun()-> 
				%%每次成功匹配后，睡眠100毫秒
				timer:sleep(SleepTime),
				make_pk(Player,Element,Bd_1v1_room,State)
			end),
			New_Player = Player#bd_1v1_player{
				loop = Player#bd_1v1_player.loop + 1,   %参与总次数
				pk_pid = Pk_Pid
			},
			New_Element = Element#bd_1v1_player{
				loop = Element#bd_1v1_player.loop + 1,   %参与总次数
				pk_pid = Pk_Pid
			},
			New_player_dict = dict:store([New_Player#bd_1v1_player.platform,New_Player#bd_1v1_player.server_num,
										  New_Player#bd_1v1_player.id], New_Player, State#kf_1v1_state.player_dict),
			New_Element_dict = dict:store([New_Element#bd_1v1_player.platform,New_Element#bd_1v1_player.server_num,
										   New_Element#bd_1v1_player.id], New_Element, New_player_dict),
			New_room_dict = dict:store([State#kf_1v1_state.current_loop,New_Player#bd_1v1_player.platform,New_Player#bd_1v1_player.server_num,Player#bd_1v1_player.id,
										New_Element#bd_1v1_player.platform,New_Element#bd_1v1_player.server_num,Element#bd_1v1_player.id], 
									   Bd_1v1_room, State#kf_1v1_state.room_dict),
			New_State = State#kf_1v1_state{
				player_dict = New_Element_dict,
				room_dict = New_room_dict
			},
			match(SleepTime+100,lists:delete(Element,T),Sign_up_dict,New_State)
	end.
%%获取随即20名玩家
get_random_list(_Player_canshu,_Canshu_gap,_Sign_up_dict,[],List)->List;
get_random_list(Player_canshu,Canshu_gap,Sign_up_dict,[Element|T],List)->
	if
		length(List)>=20->List;
		true->
			Element_canshu = get_canshu(Element,Sign_up_dict),
			if
				Canshu_gap < abs(Player_canshu-Element_canshu)->%超过允许范围，匹配失败
					List;
				true->
					get_random_list(Player_canshu,Canshu_gap,Sign_up_dict,T,List++[Element])
			end
	end.
%%战斗
make_pk(Player,Element,Bd_1v1_room,State)->
	mod_kf_1v1:goin_war(Player,Element,Bd_1v1_room),
	Loop_time = State#kf_1v1_state.loop_time*60,
	receive
		{over}-> %结束
			over
	after Loop_time*1000->
		%通知服务结算
		mod_kf_1v1:end_each_war(Player,Element,Bd_1v1_room)						
	end.

%% 获取两个幸运指数
make_luck()->
	A_Luck = util:rand(1,100),
	B_Luck = make_luck_sub(A_Luck),
	[A_Luck,B_Luck].
make_luck_sub(A_Luck)->
	B_Luck = util:rand(1,100),
	if
		A_Luck=:=B_Luck ->
			make_luck_sub(A_Luck);
		true->B_Luck
	end.

%% 处理到点仍然没有分出胜负的组合
%% @param NeedOut 最终结束的时候，不需要切场景，会统一清除
make_win(Bd_1v1_room,State)->
	Bd_1v1_Scene_id2 = data_kf_1v1:get_bd_1v1_config(scene_id2),
	Current_Loop = Bd_1v1_room#bd_1v1_room.loop,
	APlatform = Bd_1v1_room#bd_1v1_room.player_a_platform,
	AServer_num = Bd_1v1_room#bd_1v1_room.player_a_server_num,
	AId = Bd_1v1_room#bd_1v1_room.player_a_id,
	BPlatform = Bd_1v1_room#bd_1v1_room.player_b_platform,
	BServer_num = Bd_1v1_room#bd_1v1_room.player_b_server_num,
	BId = Bd_1v1_room#bd_1v1_room.player_b_id,
	A_Bd_1v1_player = dict:fetch([APlatform,AServer_num,AId], State#kf_1v1_state.player_dict),
	B_Bd_1v1_player = dict:fetch([BPlatform,BServer_num,BId], State#kf_1v1_state.player_dict),
	Bd_1v1_Scene_id2 = data_kf_1v1:get_bd_1v1_config(scene_id2),
	case lib_scene:get_scene_user_1v1(Bd_1v1_Scene_id2, 0, AId, APlatform,AServer_num) of
		{0,0,1,0}->
			A_flag = false,
			New_Bd_1v1_roomA = Bd_1v1_room;
		{Combat_power,Hp,Hp_lim,Scene_id}->
			if
				Scene_id =:= Bd_1v1_Scene_id2 -> % 在战场内
					A_flag = true,
					New_Bd_1v1_roomA = Bd_1v1_room#bd_1v1_room{
						player_a_power = Combat_power, 	% 玩家战力
						player_a_hp = Hp, 				% 玩家当前血量(判断胜负时的赋值)
						player_a_maxHp = Hp_lim 		% 玩家最高血量(进行时，禁用一切改变属性操作)									  
					};
				true->
					A_flag = false,
					New_Bd_1v1_roomA = Bd_1v1_room
			end;
		_-> %%不在线，不在场，直接判负
			A_flag = false,
			New_Bd_1v1_roomA = Bd_1v1_room
	end,
	case lib_scene:get_scene_user_1v1(Bd_1v1_Scene_id2, 0, BId, BPlatform,BServer_num) of
		{0,0,1,0}->
			B_flag = false,
			New_Bd_1v1_roomB = New_Bd_1v1_roomA;
		{Combat_powerB,HpB,Hp_limB,Scene_idB}->
			if
				Scene_idB =:= Bd_1v1_Scene_id2 -> % 在战场内
					B_flag = true,
					New_Bd_1v1_roomB = New_Bd_1v1_roomA#bd_1v1_room{
						player_b_power = Combat_powerB, 	% 玩家战力
						player_b_hp = HpB, 				% 玩家当前血量(判断胜负时的赋值)
						player_b_maxHp = Hp_limB 		% 玩家最高血量(进行时，禁用一切改变属性操作)									  
					};
				true->
					B_flag = false,
					New_Bd_1v1_roomB = New_Bd_1v1_roomA
			end;
		_-> %不在线，不在场，直接判负
			B_flag = false,
			New_Bd_1v1_roomB = New_Bd_1v1_roomA
	end,
	%% 规则：不在线、直接判负，血比率大的胜，战力低的胜，幸运大的胜
	A_hp_rate = New_Bd_1v1_roomB#bd_1v1_room.player_a_hp*100 div New_Bd_1v1_roomB#bd_1v1_room.player_a_maxHp,
	B_hp_rate = New_Bd_1v1_roomB#bd_1v1_room.player_b_hp*100 div New_Bd_1v1_roomB#bd_1v1_room.player_b_maxHp,
	if
		A_flag=:=false andalso B_flag=:=true->
			A_Win_flag = false;
		A_flag=:=true andalso B_flag=:=false->
			A_Win_flag = true;
		true->
			if
				A_hp_rate>B_hp_rate->
					A_Win_flag = true;
				A_hp_rate=:=B_hp_rate->
					A_power = New_Bd_1v1_roomB#bd_1v1_room.player_a_power,
					B_power = New_Bd_1v1_roomB#bd_1v1_room.player_b_power,
					if
						A_power > B_power ->
							A_Win_flag = true;
						A_power =:= B_power ->
							A_luky = New_Bd_1v1_roomB#bd_1v1_room.player_a_num,
							B_luky = New_Bd_1v1_roomB#bd_1v1_room.player_b_num,
							if
								A_luky > B_luky ->
									A_Win_flag = true;
								true->
									A_Win_flag = false
							end;
						A_power < B_power ->
							A_Win_flag = false
					end;
				A_hp_rate<B_hp_rate->
					A_Win_flag = false
			end
	end,
	%% 发送胜负协议
	case A_Win_flag of
		false-> %A输了
			[Win_pt,Loos_pt] = data_kf_1v1:get_pt(B_Bd_1v1_player#bd_1v1_player.pt_lv,B_Bd_1v1_player#bd_1v1_player.pt,A_Bd_1v1_player#bd_1v1_player.pt_lv,A_Bd_1v1_player#bd_1v1_player.pt),
			[Win_score,Loos_score] = data_kf_1v1:get_score(B_Bd_1v1_player#bd_1v1_player.pt_lv,B_Bd_1v1_player#bd_1v1_player.score,
														   B_Bd_1v1_player#bd_1v1_player.combat_power,B_Bd_1v1_player#bd_1v1_player.lv,
														   A_Bd_1v1_player#bd_1v1_player.pt_lv,A_Bd_1v1_player#bd_1v1_player.score,
														   A_Bd_1v1_player#bd_1v1_player.combat_power,A_Bd_1v1_player#bd_1v1_player.lv),
			case State#kf_1v1_state.bd_1v1_stauts of
				4->%%需结算
					Is_gift = 1;
				_->
					Is_gift = 0
			end,
			New_A_Bd_1v1_player = A_Bd_1v1_player#bd_1v1_player{
				hp = A_Bd_1v1_player#bd_1v1_player.hp + A_hp_rate,
				pt = Loos_pt,
				score = Loos_score,
				pk_pid = none,
				is_gift = Is_gift
			},
			New_B_Bd_1v1_player = B_Bd_1v1_player#bd_1v1_player{
				win_loop = B_Bd_1v1_player#bd_1v1_player.win_loop + 1,
				hp = B_Bd_1v1_player#bd_1v1_player.hp + B_hp_rate,
				pt = Win_pt,
				score = Win_score,
				pk_pid = none,
				is_gift = Is_gift
			},
			New_Bd_1v1_room = New_Bd_1v1_roomB#bd_1v1_room{
				win_platform = BPlatform,
				win_server_num = BServer_num,														   
				win_id = BId
			},
			New_Log_1v1_dict = lib_kf_1v1:log_kf_1v1(New_Bd_1v1_room#bd_1v1_room.player_b_power,
													 B_Bd_1v1_player#bd_1v1_player.carrer,
								 					 New_Bd_1v1_room#bd_1v1_room.player_a_power,
													 A_Bd_1v1_player#bd_1v1_player.carrer,
													 State#kf_1v1_state.log_1v1_dict),
			{ok, BinData} = pt_483:write(48308, [BPlatform,BServer_num,BId,
										APlatform,AServer_num,AId,
										A_Bd_1v1_player#bd_1v1_player.name,
										A_Bd_1v1_player#bd_1v1_player.country,
										A_Bd_1v1_player#bd_1v1_player.sex,
										A_Bd_1v1_player#bd_1v1_player.carrer,
										A_Bd_1v1_player#bd_1v1_player.image,
										A_Bd_1v1_player#bd_1v1_player.lv,
										New_Bd_1v1_room#bd_1v1_room.player_a_power,
										New_Bd_1v1_room#bd_1v1_room.player_a_num,
										New_Bd_1v1_room#bd_1v1_room.player_a_hp,
										New_Bd_1v1_room#bd_1v1_room.player_a_maxHp,
										BPlatform,BServer_num,BId,
										B_Bd_1v1_player#bd_1v1_player.name,
										B_Bd_1v1_player#bd_1v1_player.country,
										B_Bd_1v1_player#bd_1v1_player.sex,
										B_Bd_1v1_player#bd_1v1_player.carrer,
										B_Bd_1v1_player#bd_1v1_player.image,
										B_Bd_1v1_player#bd_1v1_player.lv,
										New_Bd_1v1_room#bd_1v1_room.player_b_power,
										New_Bd_1v1_room#bd_1v1_room.player_b_num,
										New_Bd_1v1_room#bd_1v1_room.player_b_hp,
										New_Bd_1v1_room#bd_1v1_room.player_b_maxHp,
									    A_Bd_1v1_player#bd_1v1_player.pt,
										New_A_Bd_1v1_player#bd_1v1_player.pt,
										A_Bd_1v1_player#bd_1v1_player.score,
										New_A_Bd_1v1_player#bd_1v1_player.score,
										B_Bd_1v1_player#bd_1v1_player.pt,
										New_B_Bd_1v1_player#bd_1v1_player.pt,
										B_Bd_1v1_player#bd_1v1_player.score,
										New_B_Bd_1v1_player#bd_1v1_player.score,
										New_Bd_1v1_room#bd_1v1_room.loop]);
		true-> %A赢了
			[Win_pt,Loos_pt] = data_kf_1v1:get_pt(A_Bd_1v1_player#bd_1v1_player.pt_lv,A_Bd_1v1_player#bd_1v1_player.pt,B_Bd_1v1_player#bd_1v1_player.pt_lv,B_Bd_1v1_player#bd_1v1_player.pt),
			[Win_score,Loos_score] = data_kf_1v1:get_score(A_Bd_1v1_player#bd_1v1_player.pt_lv,A_Bd_1v1_player#bd_1v1_player.score,
														   A_Bd_1v1_player#bd_1v1_player.combat_power,A_Bd_1v1_player#bd_1v1_player.lv,
														   B_Bd_1v1_player#bd_1v1_player.pt_lv,B_Bd_1v1_player#bd_1v1_player.score,
														   B_Bd_1v1_player#bd_1v1_player.combat_power,B_Bd_1v1_player#bd_1v1_player.lv),
			case State#kf_1v1_state.bd_1v1_stauts of
				4->%%需结算
					Is_gift = 1;
				_->
					Is_gift = 0
			end,
			New_A_Bd_1v1_player = A_Bd_1v1_player#bd_1v1_player{
				win_loop = A_Bd_1v1_player#bd_1v1_player.win_loop + 1,
				hp = A_Bd_1v1_player#bd_1v1_player.hp + A_hp_rate,
				pt = Win_pt,
				score = Win_score,
				pk_pid = none,
				is_gift = Is_gift
			},
			New_B_Bd_1v1_player = B_Bd_1v1_player#bd_1v1_player{
				hp = B_Bd_1v1_player#bd_1v1_player.hp + B_hp_rate,
				pt = Loos_pt,
				score = Loos_score,
				pk_pid = none,
				is_gift = Is_gift
			},
			New_Bd_1v1_room = New_Bd_1v1_roomB#bd_1v1_room{
				win_platform = APlatform,
				win_server_num = AServer_num,														   
				win_id = AId
			},
			New_Log_1v1_dict = lib_kf_1v1:log_kf_1v1(New_Bd_1v1_room#bd_1v1_room.player_a_power,
													 A_Bd_1v1_player#bd_1v1_player.carrer,
													 New_Bd_1v1_room#bd_1v1_room.player_b_power,
													 B_Bd_1v1_player#bd_1v1_player.carrer,
													 State#kf_1v1_state.log_1v1_dict),
			{ok, BinData} = pt_483:write(48308, [APlatform,AServer_num,AId,
										APlatform,AServer_num,AId,
										A_Bd_1v1_player#bd_1v1_player.name,
										A_Bd_1v1_player#bd_1v1_player.country,
										A_Bd_1v1_player#bd_1v1_player.sex,
										A_Bd_1v1_player#bd_1v1_player.carrer,
										A_Bd_1v1_player#bd_1v1_player.image,
										A_Bd_1v1_player#bd_1v1_player.lv,
										New_Bd_1v1_room#bd_1v1_room.player_a_power,
										New_Bd_1v1_room#bd_1v1_room.player_a_num,
										New_Bd_1v1_room#bd_1v1_room.player_a_hp,
										New_Bd_1v1_room#bd_1v1_room.player_a_maxHp,
										BPlatform,BServer_num,BId,
										B_Bd_1v1_player#bd_1v1_player.name,
										B_Bd_1v1_player#bd_1v1_player.country,
										B_Bd_1v1_player#bd_1v1_player.sex,
										B_Bd_1v1_player#bd_1v1_player.carrer,
										B_Bd_1v1_player#bd_1v1_player.image,
										B_Bd_1v1_player#bd_1v1_player.lv,
										New_Bd_1v1_room#bd_1v1_room.player_b_power,
										New_Bd_1v1_room#bd_1v1_room.player_b_num,
										New_Bd_1v1_room#bd_1v1_room.player_b_hp,
										New_Bd_1v1_room#bd_1v1_room.player_b_maxHp,
										A_Bd_1v1_player#bd_1v1_player.pt,
										New_A_Bd_1v1_player#bd_1v1_player.pt,
										A_Bd_1v1_player#bd_1v1_player.score,
										New_A_Bd_1v1_player#bd_1v1_player.score,
										B_Bd_1v1_player#bd_1v1_player.pt,
										New_B_Bd_1v1_player#bd_1v1_player.pt,
										B_Bd_1v1_player#bd_1v1_player.score,
										New_B_Bd_1v1_player#bd_1v1_player.score,
										New_Bd_1v1_room#bd_1v1_room.loop])
	end,
	New_player_dict1 = dict:store([APlatform,AServer_num,AId], New_A_Bd_1v1_player, State#kf_1v1_state.player_dict),
	New_player_dict2 = dict:store([BPlatform,BServer_num,BId], New_B_Bd_1v1_player, New_player_dict1),
	
	mod_clusters_center:apply_cast(A_Bd_1v1_player#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[AId,BinData]),
	mod_clusters_center:apply_cast(B_Bd_1v1_player#bd_1v1_player.node,lib_unite_send,cluster_to_uid,[BId,BinData]),
	New_room_dict = dict:store([Current_Loop,APlatform,AServer_num,AId,BPlatform,BServer_num,BId], New_Bd_1v1_room, State#kf_1v1_state.room_dict),
	%%清空观战人员
	clear_look_player([Current_Loop,APlatform,AServer_num,AId,BPlatform,BServer_num,BId],State#kf_1v1_state.look_dict),
	New_State = State#kf_1v1_state{
		player_dict = New_player_dict2,
		log_1v1_dict = New_Log_1v1_dict,
		room_dict = New_room_dict
	},
	case State#kf_1v1_state.bd_1v1_stauts of
		4->%%丢出跨服场地
			spawn(fun()->
				timer:sleep(3*1000),
				[SceneId,X,Y] = data_kf_1v1:get_bd_1v1_config(leave_scene),
				mod_clusters_center:apply_cast(New_A_Bd_1v1_player#bd_1v1_player.node,
											   lib_scene,player_change_scene_queue,
											   [New_A_Bd_1v1_player#bd_1v1_player.id,SceneId,0,X,Y,0]),
				mod_clusters_center:apply_cast(New_B_Bd_1v1_player#bd_1v1_player.node,
											   lib_scene,player_change_scene_queue,
											   [New_B_Bd_1v1_player#bd_1v1_player.id,SceneId,0,X,Y,0])
			end);
		_->%%丢人准备区
			Bd_1v1_Scene_id1 = data_kf_1v1:get_bd_1v1_config(scene_id1),
			[X1,Y1] = data_kf_1v1:get_position1(),
			[X2,Y2] = data_kf_1v1:get_position1(),
			spawn(fun()->
				timer:sleep(3*1000),
				mod_clusters_center:apply_cast(A_Bd_1v1_player#bd_1v1_player.node,lib_scene,player_change_scene_queue,[AId,Bd_1v1_Scene_id1,A_Bd_1v1_player#bd_1v1_player.copy_id,X1,Y1,0]),
				mod_clusters_center:apply_cast(B_Bd_1v1_player#bd_1v1_player.node,lib_scene,player_change_scene_queue,[BId,Bd_1v1_Scene_id1,B_Bd_1v1_player#bd_1v1_player.copy_id,X2,Y2,0])
			end),
			
			{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
			NowTime = (Hour*60+Minute)*60 + Second,
			_RestTime = New_State#kf_1v1_state.loop_end - NowTime, 
			_WholeRestTime = New_State#kf_1v1_state.config_end - NowTime, 
			if
				_RestTime>=0->RestTime = _RestTime;
				true-> RestTime = 0
			end,
			if
				_WholeRestTime>=0->WholeRestTime = _WholeRestTime;
				true-> WholeRestTime = 0
			end,
			{ok, BinDataA2} = pt_483:write(48304, [New_State#kf_1v1_state.loop,New_State#kf_1v1_state.bd_1v1_stauts,RestTime,WholeRestTime,New_State#kf_1v1_state.current_loop,A_Bd_1v1_player#bd_1v1_player.loop,0,A_Bd_1v1_player#bd_1v1_player.loop_day]),
			{ok, BinDataB2} = pt_483:write(48304, [New_State#kf_1v1_state.loop,New_State#kf_1v1_state.bd_1v1_stauts,RestTime,WholeRestTime,New_State#kf_1v1_state.current_loop,B_Bd_1v1_player#bd_1v1_player.loop,0,B_Bd_1v1_player#bd_1v1_player.loop_day]),
			mod_clusters_center:apply_cast(A_Bd_1v1_player#bd_1v1_player.node,lib_unite_send,cluster_to_uid, [AId,BinDataA2]),
			mod_clusters_center:apply_cast(B_Bd_1v1_player#bd_1v1_player.node,lib_unite_send,cluster_to_uid, [BId,BinDataB2])
	end,
	New_State.
