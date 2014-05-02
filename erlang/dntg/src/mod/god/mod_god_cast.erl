%% Author: Administrator
%% Created: 2013-1-7
%% Description: TODO: Add description to mod_god_cast
-module(mod_god_cast).

%%
%% Include files
%%
-include("god.hrl").
%%
%% Exported Functions
%%
-export([handle_cast/2]).

%%
%% API Functions
%%

handle_cast({open,Mod,Next_mod,God_no,Open_time,Config_end}, _State) ->
	%%把本次活动记录加载进来
	God_dict = lib_god:load_god(God_no),
	if
		Mod =:= 1-> %%清除上一届的一些数据
			%%删除上一届人气投票记录
			mod_clusters_center:apply_to_all_node(lib_god,delete_vote_relive,[]);
		true->
			void
	end,
	if
		Mod =:= 2-> %%小组赛
			{New_God_dict,God_room_dict} = make_group_room(dict:to_list(God_dict),God_dict,dict:new());
		true->
			{New_God_dict,God_room_dict} = {God_dict,dict:new()}
	end,
	mod_clusters_center:apply_to_all_node(mod_god_state,set_god_and_room_dict,[New_God_dict,God_room_dict]),
	
	New_State = #god_state{
		mod = Mod,		
		last_mod = 0,
		next_mod = Next_mod,				   
		status = 1,				 	
		god_no = God_no,
		last_god_no = 0,
		config_end = Config_end,
		open_time = Open_time,					
		god_dict = New_God_dict,
		god_room_dict = God_room_dict										   
	},
	if
		Mod =:= 4-> %%总决赛,需要匹配
			spawn(fun()-> 
				Sort_prepare_time = data_god:get(sort_prepare_time),
				timer:sleep(Sort_prepare_time*1000),
				mod_god:sort_match()
			end);
		true->
			void
	end,
    {noreply, New_State};

handle_cast({bs,Flat,Server_id,Id,God_no,Type}, State)->
	case dict:is_key(God_no, State#god_state.god_top50_dict) of
		false->
			New_State = State;
		true->
			Top50_list = dict:fetch(God_no, State#god_state.god_top50_dict),
			case lib_god:member(Top50_list,Flat,Server_id,Id,God_no) of
				{ok,G}->%%是成员
					%%更改记录、领取铜币
					T_Top50_list = lists:delete(G, Top50_list),
					case Type of
						1->
							Praise = G#god.praise + 1,
							Despise = G#god.despise;
						_->
							Praise = G#god.praise,
							Despise = G#god.despise + 1
					end,
					New_G = G#god{
						praise = Praise,
						despise = Despise
					},
					lib_god:update_god_bs(Flat,Server_id,Id,God_no,Praise,Despise),
					New_Top50_list = T_Top50_list ++ [New_G],
					New_God_top50_dict = dict:store(God_no, New_Top50_list, State#god_state.god_top50_dict),
					New_State = State#god_state{
						god_top50_dict = New_God_top50_dict
					};
				_->%%不是成员
					New_State = State
			end
	end,
	
	{noreply, New_State};

handle_cast({set_god_top50,Node}, State)->  
	%%推送至各服
	mod_clusters_center:apply_cast(Node,mod_god_state,set_god_top50,[State#god_state.god_top50_dict]),
	{noreply, State};	

handle_cast({load_god_top50}, State)->
	%%加载历届前50名
	God_top50_dict = lib_god:load_god_top50(),
    New_State = State#god_state{
		god_top50_dict = God_top50_dict			
	},
	{noreply, New_State};

handle_cast({load_god,God_no,Mod}, State)-> 
	%%把本次活动记录加载进来
	God_dict = lib_god:load_god(God_no),
	if
		Mod =:= 2-> %%小组赛
			{New_God_dict,God_room_dict} = make_group_room(dict:to_list(God_dict),God_dict,dict:new());
		true->
			{New_God_dict,God_room_dict} = {God_dict,dict:new()}
	end,
	mod_clusters_center:apply_to_all_node(mod_god_state,set_god_and_room_dict,[New_God_dict,God_room_dict]),
	New_State = State#god_state{
		god_dict = New_God_dict,
		god_room_dict = God_room_dict										   
	},
	
	{noreply, New_State};

handle_cast({vote_relive_list}, State)->
	%%把本次活动记录加载进来
	God_dict = lib_god:load_god(State#god_state.god_no),
	lib_god:update_god_is_relive_balace(State#god_state.god_no),
	God_dict_list = dict:to_list(God_dict),
	God_list = [G||{_K,G}<-God_dict_list,G#god.group_relive_is_up=:=0,G#god.is_relive_balace=:=0],
	%%排序：积分高、战力高、等级高
	Sort_God_score_list = lists:sort(fun(G_a,G_b)-> 
		if
			G_a#god.relive_score>G_b#god.relive_score->true;
			G_a#god.relive_score=:=G_b#god.relive_score->
				if
					G_a#god.high_power>G_b#god.high_power->true;
					G_a#god.high_power=:=G_b#god.high_power->
						if
							G_a#god.lv>=G_b#god.lv->true;
							true->false
						end;
					G_a#god.high_power<G_b#god.high_power->false
				end;
			G_a#god.relive_score<G_b#god.relive_score->false
		end
	end, God_list),
	%%排序：票数高、战力高、等级高
	Sort_God_vote_list = lists:sort(fun(G_a,G_b)-> 
		if
			G_a#god.relive_vote>G_b#god.relive_vote->true;
			G_a#god.relive_vote=:=G_b#god.relive_vote->
				if
					G_a#god.high_power>G_b#god.high_power->true;
					G_a#god.high_power=:=G_b#god.high_power->
						if
							G_a#god.lv>=G_b#god.lv->true;
							true->false
						end;
					G_a#god.high_power<G_b#god.high_power->false
				end;
			G_a#god.relive_vote<G_b#god.relive_vote->false
		end
	end, God_list),
	
	if
		length(Sort_God_vote_list)>3->
			{Top3,_Other_list3} = lists:split(3, Sort_God_vote_list);
		true->
			Top3 = Sort_God_vote_list
	end,
	
	if
		length(Sort_God_score_list)>=15->
			{Temp_Top15,_Other_list15} = lists:split(15, Sort_God_score_list);
		true->
			Temp_Top15 = Sort_God_score_list
	end,
	Element_size = lib_god:lists_elements(Top3,Temp_Top15,15),
	
	spawn(fun()-> 
		%%结算出名单
		if
			State#god_state.god_no=:=0 andalso State#god_state.last_god_no/=0->
				God_no = State#god_state.last_god_no;
			true->
				God_no = State#god_state.god_no
		end,
		vote_relive_list_sub(Sort_God_score_list,Top3,God_no,Element_size,1),
		%%发传闻
		vote_relive_TV(Top3,1)
	end),
	
	%%对投票的人员发放奖励
	mod_clusters_center:apply_to_all_node(mod_god_state,vote_relive_balance,[Top3]),
	
	{noreply, State};

handle_cast({vote_relive,Flat,Server_id,Id}, State)->  
	%%更新数据库
	lib_god:update_vote_relive(Flat,Server_id,Id,State#god_state.god_no),
	case dict:is_key({Flat,Server_id,Id}, State#god_state.god_dict) of
		false->
			New_State = State;
		true->
			God = dict:fetch({Flat,Server_id,Id}, State#god_state.god_dict),
			New_God = God#god{
				relive_vote = God#god.relive_vote + 1				  
			},
			New_State = State#god_state{
				god_dict = dict:store({Flat,Server_id,Id}, New_God, State#god_state.god_dict)							
			}
	end,
	
	{noreply, New_State};

handle_cast({goin_war,God_pk_key,G_a,G_b}, State) ->
	case dict:is_key(God_pk_key, State#god_state.god_pk_dict) of
		false->
			New_State = State;
		true->
			God_pk = dict:fetch(God_pk_key, State#god_state.god_pk_dict),
			if
				God_pk#god_pk.id_win/=0->
					New_State = State;
				true->
					%%切换场景
					Scene_id2 = util:list_rand(data_god:get(scene_id2)),
					[[X1,Y1],[X2,Y2]] = data_god:get(position2),
					CopyId = G_a#god.flat ++ "_" ++ integer_to_list(G_a#god.server_id) ++ "_" ++ integer_to_list(G_a#god.id)
					  		 ++ "_" ++ G_b#god.flat ++ "_" ++ integer_to_list(G_b#god.server_id) ++ "_" ++ integer_to_list(G_b#god.id),
					mod_clusters_center:apply_cast(G_a#god.node,lib_scene,player_change_scene_queue,
												   [G_a#god.id,Scene_id2,CopyId,X1,Y1,[{resume_hp_lim,ok}]]),
					mod_clusters_center:apply_cast(G_b#god.node,lib_scene,player_change_scene_queue,
												   [G_b#god.id,Scene_id2,CopyId,X2,Y2,[{resume_hp_lim,ok}]]),
					New_G_a = G_a#god{
						scene_id2 = Scene_id2			  
					},
					New_G_b = G_b#god{
						scene_id2 = Scene_id2			  
					},
					Temp_god_dict = dict:store({G_a#god.flat,G_a#god.server_id,G_a#god.id}, New_G_a, State#god_state.god_dict),
					New_god_dict = dict:store({G_b#god.flat,G_b#god.server_id,G_b#god.id}, New_G_b, Temp_god_dict),
					New_State = State#god_state{
						god_dict = New_god_dict							 
					}
			end
	end,
	
	{noreply, New_State};

%% 海选赛，随便进入。
%% DB有记录的即可进入小组赛，有记录没晋升的可进入复活赛，晋升了才能进入总决赛。
%% 进入房间算法：
%%   海选赛、复活赛
%%     第一次进入房间、打比赛完毕后进入房间、退出诸神大赛场景再次进入，都走一样的算法。
%%     进人数最少的那个房间，没有或者人满了就新建房间。系统匹配是全场景匹配，无视房间。
%%   小组赛
%%     固定16个房间，玩家选择一个房间后即固定房间。
%%   总决赛
%%     只有一个房间
%% @param From war|out
handle_cast({goin,From,Node,Flat,Server_id,Id,Name,Country,Sex,Carrer,Image,Lv,
				  Combat_power,Hightest_combat_power}, State) ->
	Status = State#god_state.status,
	God_no = State#god_state.god_no,
	if
		Status =:= 1-> %%开启中
			Mod = State#god_state.mod,
			if
				Mod=:=1 -> %%海选赛
					{Result,New_State} = goin_sub_sea(From,Node,Flat,Server_id,Id,God_no,Name,Country,Sex,Carrer,
													  Image,Lv,Combat_power,Hightest_combat_power,State),
					{ok, BinData} = pt_485:write(48502, [Result]);
				Mod=:=2 -> %% 小组赛
					{Result,New_State} = goin_sub_group(From,Node,Flat,Server_id,Id,Name,Lv,Combat_power,
														Hightest_combat_power,State),
					{ok, BinData} = pt_485:write(48502, [Result]);
				Mod=:=3 -> %% 复活赛
					{Result,New_State} = goin_sub_relive(From,Node,Flat,Server_id,Id,Name,Lv,Combat_power,
														 Hightest_combat_power,State),
					{ok, BinData} = pt_485:write(48502, [Result]);
				Mod=:=4 -> %% 总决赛
					{Result,New_State} = goin_sub_sort(From,Node,Flat,Server_id,Id,Name,Lv,Combat_power,
													   Hightest_combat_power,State),
					{ok, BinData} = pt_485:write(48502, [Result]);
				true->
					{ok, BinData} = pt_485:write(48500, [1]),
					case dict:is_key({Flat,Server_id,Id}, State#god_state.god_dict) of
						false->
							New_State = State;
						true->
							God = dict:fetch({Flat,Server_id,Id}, State#god_state.god_dict),
							New_God = God#god{
								is_in = 0				  
							},
							New_State = State#god_state{
								god_dict = dict:store({Flat,Server_id,Id},New_God,State#god_state.god_dict)					
							}
					end
			end;
		true->
			case From of
				war-> %%从战场回来，需要丢回长安
					[Scene_id,X,Y] = data_god:get(leave_scene),
					mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,[Id,Scene_id,0,X,Y,0]);
				_-> %%从其他地方回来，不做处理
					void
			end,
			{ok, BinData} = pt_485:write(48500, [1]),
			case dict:is_key({Flat,Server_id,Id}, State#god_state.god_dict) of
				false->
					New_State = State;
				true->
					God = dict:fetch({Flat,Server_id,Id}, State#god_state.god_dict),
					New_God = God#god{
						is_in = 0				  
					},
					New_State = State#god_state{
						god_dict = dict:store({Flat,Server_id,Id},New_God,State#god_state.god_dict)					
					}
			end
	end,
	mod_clusters_center:apply_cast(Node,lib_unite_send,cluster_to_uid,[Id,BinData]),
    {noreply, New_State};

handle_cast({goout,Node,Flat,Server_id,Id}, State) ->
	%%退出都退到长安，防止又被系统选上。
	[Scene_id_leave,X,Y] = data_god:get(leave_scene),
	case look_pk_no_end(Flat,Server_id,Id,dict:to_list(State#god_state.god_pk_dict)) of
		{ok,{K,V}}-> %%有比赛，退出的人失败
			%%新构建PK记录、God记录、room记录、切换场景
			{Flat_a,Server_id_a,Id_a,Flat_b,Server_id_b,Id_b,_Current_loop} = K,
			God_a = dict:fetch({Flat_a,Server_id_a,Id_a}, State#god_state.god_dict),
			God_b = dict:fetch({Flat_b,Server_id_b,Id_b}, State#god_state.god_dict),
			if
				Flat=:=Flat_a andalso Server_id=:=Server_id_a andalso Id=:=Id_a-> %%是A退出
					Is_win_a = 0,
					Is_win_b = 1,
					%%战斗记录结束掉
					New_V = V#god_pk{
						flat_win = Flat_b,							
						server_id_win = Server_id_b,              		
						id_win = Id_b			 
					},
					Score_a_1 = data_god:get_fail_score(God_a#god.power,God_b#god.power,get_dead_num(Flat_b,Server_id_b,Id_b,New_V)),
					Score_b_1 = data_god:get_succ_score(God_b#god.power,God_a#god.power,get_rest_dead_num(Flat_b,Server_id_b,Id_b,New_V)),
					%%添加胜利次数
					Temp_God_b = add_loop(God_b,State#god_state.mod,1,0),
					%%添加积分
					God_score_a = add_score(God_a,State#god_state.mod,Score_a_1),
					God_score_b = add_score(Temp_God_b,State#god_state.mod,Score_b_1),
					%%修改在场状态
					New_God_a = God_score_a#god{
						last_out_war_time = util:unixtime(),												
						is_in = 0					  
					},
					New_God_b = God_score_b#god{
						last_out_war_time = util:unixtime()												
					},
					spawn(fun()-> 
						timer:sleep(3*1000),
						mod_god:goin(war,God_b#god.node,God_b#god.flat,God_b#god.server_id,God_b#god.id,God_b#god.name,
									 God_b#god.country,God_b#god.sex,God_b#god.carrer,God_b#god.image,God_b#god.lv,
									 God_b#god.power,God_b#god.high_power)
					end);
				true-> %%是B退出
					Is_win_a = 1,
					Is_win_b = 0,
					%%战斗记录结束掉
					New_V = V#god_pk{
						flat_win = Flat_a,							
						server_id_win = Server_id_a,              		
						id_win = Id_a			 
					},
					Score_a_1 = data_god:get_succ_score(God_a#god.power,God_b#god.power,get_rest_dead_num(Flat_a,Server_id_a,Id_a,New_V)),
					Score_b_1 = data_god:get_fail_score(God_b#god.power,God_a#god.power,get_dead_num(Flat_a,Server_id_a,Id_a,New_V)),
					%%添加胜利次数
					Temp_God_a = add_loop(God_a,State#god_state.mod,1,0),
					%%添加积分
					God_score_a = add_score(Temp_God_a,State#god_state.mod,Score_a_1),
					God_score_b = add_score(God_b,State#god_state.mod,Score_b_1),
					%%修改在场状态
					New_God_a = God_score_a#god{
						last_out_war_time = util:unixtime()												
					},
					New_God_b = God_score_b#god{
						last_out_war_time = util:unixtime(),												
						is_in = 0					  
					},
					spawn(fun()-> 
						timer:sleep(3*1000),
						mod_god:goin(war,God_a#god.node,God_a#god.flat,God_a#god.server_id,God_a#god.id,God_a#god.name,
									 God_a#god.country,God_a#god.sex,God_a#god.carrer,God_a#god.image,God_a#god.lv,
									 God_a#god.power,God_a#god.high_power)
					end)
			end,
			
			Temp_God_dict = dict:store({Flat_a,Server_id_a,Id_a}, New_God_a, State#god_state.god_dict),
			New_God_dict = dict:store({Flat_b,Server_id_b,Id_b}, New_God_b, Temp_God_dict),
			Temp_State1 = remove_room(Flat_a,Server_id_a,Id_a,State),
			Temp_State = remove_room(Flat_b,Server_id_b,Id_b,Temp_State1),
			%%协议处理
			{Win_Loop_a,Loop_a,Score_a} = get_loop_score(New_God_a,State#god_state.mod),
			{Win_Loop_b,Loop_b,Score_b} = get_loop_score(New_God_b,State#god_state.mod),
			{ok,BinData_09_a} = pt_485:write(48509, [Score_a,Win_Loop_a,Loop_a,Score_b,Win_Loop_b,Loop_b,0,Is_win_a]),
			{ok,BinData_09_b} = pt_485:write(48509, [Score_b,Win_Loop_b,Loop_b,Score_a,Win_Loop_a,Loop_a,0,Is_win_b]),
			mod_clusters_center:apply_cast(God_a#god.node,lib_unite_send,cluster_to_uid,[God_a#god.id,BinData_09_a]),
			mod_clusters_center:apply_cast(God_b#god.node,lib_unite_send,cluster_to_uid,[God_b#god.id,BinData_09_b]),
			mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene,[Id,Scene_id_leave,0,X,Y,true]),
			
			New_State = Temp_State#god_state{
				god_dict = New_God_dict,													 
				god_pk_dict = dict:store(K, New_V, Temp_State#god_state.god_pk_dict)							 
			};
		_-> %%没找到合理的比赛，直接踢出
			%%切换场景
			mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene,
								   [Id,Scene_id_leave,0,X,Y,true]),
			case dict:is_key({Flat,Server_id,Id}, State#god_state.god_dict) of
				false->
					New_State = State;
				true->
					God = dict:fetch({Flat,Server_id,Id}, State#god_state.god_dict),
					New_God = God#god{
						is_in = 0			  
					},
					Temp_State = remove_room(Flat,Server_id,Id,State),
					New_State = Temp_State#god_state{
						god_dict = dict:store({Flat,Server_id,Id}, New_God, State#god_state.god_dict)							
					}
			end
	end,

	{ok, BinData} = pt_485:write(48503, [1]),
	mod_clusters_center:apply_cast(Node,lib_unite_send,cluster_to_uid,[Id,BinData]),
	
    {noreply, New_State};  

handle_cast({select_enemy,Node,Plat,Server_id,Id,B_Plat,B_Server_id,B_Id}, State) ->
	%%能选择玩家，肯定已经过了进入准备区的种种过滤
	if
		State#god_state.status=:=1 ->
			%%必须在同一房间内没有对手的玩家，且双方次数都未满，本场历史上未交手过
			case dict:is_key({Plat,Server_id,Id}, State#god_state.god_dict)
				andalso dict:is_key({B_Plat,B_Server_id,B_Id}, State#god_state.god_dict) of
				false->
					Result = 4,
					New_State = State;
				true->
					God_a = dict:fetch({Plat,Server_id,Id}, State#god_state.god_dict),
					God_b = dict:fetch({B_Plat,B_Server_id,B_Id}, State#god_state.god_dict),
					Time_gap = util:unixtime() - God_b#god.last_out_war_time,
					Last_out_war_time = data_god:get(last_out_war_time),
					Check_max_loop_a = is_max_loop(State#god_state.mod,God_a),
					Check_max_loop_b = is_max_loop(State#god_state.mod,God_b),
					if
						State#god_state.status/=1->
							Result = 6,
							New_State = State;
						Time_gap=<Last_out_war_time->
							Result = 7,
							New_State = State;
						God_a#god.is_in /=1->
							Result = 2,
							New_State = State;
						God_b#god.is_in /=1->
							Result = 3,
							New_State = State;
						Check_max_loop_a=:=true->
							Result = 8,
							New_State = State;
						Check_max_loop_b=:=true->
							Result = 9,
							New_State = State;
						true-> 
							%%都没有对手，判断是否是同一个房间。
							case God_a#god.scene_id1=:=God_b#god.scene_id1 andalso God_a#god.room_no=:=God_b#god.room_no of
								false-> %%不在一个房间里
									Result = 4,
									New_State = State;
								true->
									%%判断是否有历史战斗记录
									Flag_a = dict:is_key({Plat,Server_id,Id,B_Plat,B_Server_id,B_Id,0},State#god_state.god_pk_dict),
									Flag_b = dict:is_key({B_Plat,B_Server_id,B_Id,Plat,Server_id,Id,0},State#god_state.god_pk_dict),
									case Flag_a orelse Flag_b of
										false-> %%不存在，开启一场战斗
											Result = 1,
											New_State = make_pk(God_a,God_b,State);
										true-> %%存在历史PK记录
											Result = 5,
											New_State = State
									end
							end
					end
			end;
		true->
			Result = 6,
			New_State = State
	end,
	
	{ok, BinData_06_a} = pt_485:write(48506, [Result]),
	mod_clusters_center:apply_cast(Node,lib_unite_send,cluster_to_uid,[Id,BinData_06_a]),
	
    {noreply, New_State};

handle_cast({system_select,Node,Plat,Server_id,Id}, State) ->
	{T_Hour,T_Minute,T_Second} = time(),
	T_Time = (T_Hour*60+T_Minute)*60 + T_Second,
	if
		State#god_state.config_end - T_Time >= 58*60-> %%小于比赛前两分钟
			Result = 5,
			New_State = State;
		State#god_state.status=:=1 ->
			case dict:is_key({Plat,Server_id,Id}, State#god_state.god_dict) of
				false->
					Result = 2,
					New_State = State;
				true->
					God_a = dict:fetch({Plat,Server_id,Id}, State#god_state.god_dict),
					Check_max_loop_a = is_max_loop(State#god_state.mod,God_a),
					if
						State#god_state.status/=1->
							Result = 4,
							New_State = State;
						God_a#god.is_in /=1->
							Result = 2,
							New_State = State;
						Check_max_loop_a=:=true->
							Result = 6,
							New_State = State;
						true->
							%%找一个没有PK的人进入战斗
							case get_free_god(God_a,State) of
								{ok,God_b}->%%找到对手
									Result = 1,
									New_State = make_pk(God_a,God_b,State);
								_-> %%未找到系统匹配对手
									if
										State#god_state.mod =:= 2 -> %%小组赛,要计算轮空胜利
											System_select_loss = God_a#god.system_select_loss,
											Group_no_match_loop = data_god:get(group_no_match_loop),
											if
												System_select_loss+1>=Group_no_match_loop-> 
													Result = 1,
													Score = data_god:get_loos_score(God_a#god.power),
													%%轮空次数已到，直接判一次胜利
													New_God_a = God_a#god{
														group_win_loop = God_a#god.group_win_loop + 1,					
														group_loop = God_a#god.group_loop + 1,						
														group_score = God_a#god.group_score + Score,%%4倍自己战力															  
														system_select_loss = 0				  
													},
													{ok,BinData_09} = pt_485:write(48509, [New_God_a#god.group_score,
																						New_God_a#god.group_win_loop,
																						New_God_a#god.group_loop,
																						0,0,0,1,1]),
													mod_clusters_center:apply_cast(God_a#god.node,lib_unite_send,cluster_to_uid,[Id,BinData_09]);
												true->
													Result = 3,
													New_God_a = God_a#god{
														system_select_loss = God_a#god.system_select_loss + 1				  
													}
											end,
											New_God_dict = dict:store({Plat,Server_id,Id}, New_God_a, State#god_state.god_dict),
											New_State = State#god_state{
												god_dict = New_God_dict
											};
										true->
											Result = 3,
											New_State = State
									end
							end
					end
			end;
		true->
			Result = 4,
			New_State = State
	end,

	{ok,BinData_15} = pt_485:write(48515, [Result]),
	mod_clusters_center:apply_cast(Node,lib_unite_send,cluster_to_uid,[Id,BinData_15]),
	
    {noreply, New_State};

handle_cast({sort_match}, State) ->
	if
		State#god_state.status/=1->
			New_State = State;
		true->
			New_State = sort_match(State)		
	end,
	
	{noreply, New_State};

handle_cast({pk_list,Node,Plat,Server_id,Id}, State) ->
	case dict:is_key({Plat,Server_id,Id}, State#god_state.god_dict) of
		false->void;
		true->pk_list(Node,Plat,Server_id,Id,State)
	end,
	
	{noreply, State};

handle_cast({set_mod_and_status,Node}, State) ->
	mod_clusters_center:apply_cast(Node,mod_god_state,set_mod_and_status,
										  [State#god_state.mod,
										   State#god_state.status,
										   State#god_state.config_end]),
	
	{noreply, State};

handle_cast({set_mod_and_status,God_no,Mod,Status,Config_End}, State) ->
	New_State = State#god_state{
		god_no = God_no,
		last_god_no = State#god_state.god_no,								
		mod = Mod,	
		last_mod = State#god_state.mod,			 				
		status = Status,								
		config_end = Config_End							
	},
	
	{noreply, New_State};

handle_cast({set_god_and_room_dict,Node}, State) ->
	mod_clusters_center:apply_cast(Node,mod_god_state,set_god_and_room_dict,[State#god_state.god_dict,State#god_state.god_room_dict]),
	{noreply, State};  

handle_cast({when_kill,Plat,Server_id,Id,Plat_killed,Server_id_killed,Id_killed}, State) ->
	if
		State#god_state.mod=:=4->
			Current_loop = State#god_state.sort_current_loop;
		true->
			Current_loop = 0
	end,
	Flag_a = dict:is_key({Plat,Server_id,Id,Plat_killed,Server_id_killed,Id_killed,Current_loop},State#god_state.god_pk_dict),
	Flag_b = dict:is_key({Plat_killed,Server_id_killed,Id_killed,Plat,Server_id,Id,Current_loop},State#god_state.god_pk_dict),
	case Flag_a orelse Flag_b of
		false-> %%无战斗记录，直接跳过
			New_State = State;
		true->
			Max_dead_num = data_god:get(max_dead_num),
			case Flag_a of
				false-> %%杀人的是B
					God_pk_key = {Plat_killed,Server_id_killed,Id_killed,Plat,Server_id,Id,Current_loop},
					God_pk = dict:fetch(God_pk_key,State#god_state.god_pk_dict),
					God_a = dict:fetch({Plat_killed,Server_id_killed,Id_killed}, State#god_state.god_dict),
					God_b = dict:fetch({Plat,Server_id,Id}, State#god_state.god_dict),
					if
						God_pk#god_pk.id_win/=0->%%已经判胜负了
							New_State = State;
						Max_dead_num=<God_pk#god_pk.dead_num_a+1->%%超出允许死亡次数，判胜负
							New_God_pk = God_pk#god_pk{
								dead_num_a = God_pk#god_pk.dead_num_a+1					   
							},
							Tmep_State = State#god_state{
								god_pk_dict = dict:store(God_pk_key, New_God_pk, State#god_state.god_pk_dict) 							 
							},
							New_State = make_win(New_God_pk,God_a,God_b,Tmep_State,false);
						true->%%死亡次数+1
							New_God_pk = God_pk#god_pk{
								dead_num_a = God_pk#god_pk.dead_num_a+1
							},
							%%协议处理
							Dead_num_a = New_God_pk#god_pk.dead_num_a,
							Dead_num_b = New_God_pk#god_pk.dead_num_b,
							{Win_Loop_a,Loop_a,_Score_a} = get_loop_score(God_a,State#god_state.mod),
							{Win_Loop_b,Loop_b,_Score_b} = get_loop_score(God_b,State#god_state.mod),
							{ok,BinData_08_a} = pt_485:write(48508, [Max_dead_num,Dead_num_a,Dead_num_b,Win_Loop_a,Loop_a]),
							{ok,BinData_08_b} = pt_485:write(48508, [Max_dead_num,Dead_num_b,Dead_num_a,Win_Loop_b,Loop_b]),
							mod_clusters_center:apply_cast(God_a#god.node,lib_unite_send,cluster_to_uid,[God_a#god.id,BinData_08_a]),
							mod_clusters_center:apply_cast(God_b#god.node,lib_unite_send,cluster_to_uid,[God_b#god.id,BinData_08_b]),
							New_State = State#god_state{
								god_pk_dict = dict:store(God_pk_key, New_God_pk, State#god_state.god_pk_dict)
							}
					end;
				true-> %% 杀人的是A
					God_pk_key = {Plat,Server_id,Id,Plat_killed,Server_id_killed,Id_killed,Current_loop},
					God_pk = dict:fetch(God_pk_key,State#god_state.god_pk_dict),
					God_a = dict:fetch({Plat,Server_id,Id}, State#god_state.god_dict),
					God_b = dict:fetch({Plat_killed,Server_id_killed,Id_killed}, State#god_state.god_dict),
					if
						God_pk#god_pk.id_win/=0->%%已经判胜负了
							New_State = State;
						Max_dead_num=<God_pk#god_pk.dead_num_b+1->%%超出允许死亡次数，判胜负
							New_God_pk = God_pk#god_pk{
								dead_num_b = God_pk#god_pk.dead_num_b+1					   
							},
							Tmep_State = State#god_state{
								god_pk_dict = dict:store(God_pk_key, New_God_pk, State#god_state.god_pk_dict) 							 
							},
							New_State = make_win(New_God_pk,God_a,God_b,Tmep_State,true);
						true->%%死亡次数+1
							New_God_pk = God_pk#god_pk{
								dead_num_b = God_pk#god_pk.dead_num_b+1
							},
							%%协议处理
							Dead_num_a = New_God_pk#god_pk.dead_num_a,
							Dead_num_b = New_God_pk#god_pk.dead_num_b,
							{Win_Loop_a,Loop_a,_Score_a} = get_loop_score(God_a,State#god_state.mod),
							{Win_Loop_b,Loop_b,_Score_b} = get_loop_score(God_b,State#god_state.mod),
							{ok,BinData_08_a} = pt_485:write(48508, [Max_dead_num,Dead_num_a,Dead_num_b,Win_Loop_a,Loop_a]),
							{ok,BinData_08_b} = pt_485:write(48508, [Max_dead_num,Dead_num_b,Dead_num_a,Win_Loop_b,Loop_b]),
							mod_clusters_center:apply_cast(God_a#god.node,lib_unite_send,cluster_to_uid,[God_a#god.id,BinData_08_a]),
							mod_clusters_center:apply_cast(God_b#god.node,lib_unite_send,cluster_to_uid,[God_b#god.id,BinData_08_b]),
							New_State = State#god_state{
								god_pk_dict = dict:store(God_pk_key, New_God_pk, State#god_state.god_pk_dict)
							}
					end
			end
	end,
	
    {noreply, New_State};

handle_cast({end_pk,Plat,Server_id,Id,Plat_b,Server_id_b,Id_b,Current_loop}, State) ->
	case dict:is_key({Plat,Server_id,Id,Plat_b,Server_id_b,Id_b,Current_loop}, State#god_state.god_pk_dict) of
		false->%%无对应PK记录
			New_State = State;
		true->
			God_pk = dict:fetch({Plat,Server_id,Id,Plat_b,Server_id_b,Id_b,Current_loop}, State#god_state.god_pk_dict),
			if
				God_pk#god_pk.id_win/=0->%%已分出胜负
					New_State = State;
				true->%%未分出胜负
					%%场中复活次数多的玩家获胜，如果复活次数一样多，则剩余血量（百分比）多的获胜，如果剩余血量百分比一样多，则战斗力
					God_pk = dict:fetch({Plat,Server_id,Id,Plat_b,Server_id_b,Id_b,Current_loop},State#god_state.god_pk_dict),
					God_a = dict:fetch({Plat,Server_id,Id}, State#god_state.god_dict),
					God_b = dict:fetch({Plat_b,Server_id_b,Id_b}, State#god_state.god_dict),
					%%分出胜负
					if
						God_pk#god_pk.dead_num_a<God_pk#god_pk.dead_num_b->%%A胜
							Is_win_a = true;
						God_pk#god_pk.dead_num_a=:=God_pk#god_pk.dead_num_b->
							Scene_id2 = God_a#god.scene_id2,
							{Combat_power_a,Hp_a,Hp_lim_a,_Scene_id} = lib_scene:get_scene_user_1v1(Scene_id2,0,Id,Plat,Server_id),
							{Combat_power_b,Hp_b,Hp_lim_b,_Scene_id1} = lib_scene:get_scene_user_1v1(Scene_id2,0,Id_b,Plat_b,Server_id_b),
							Hp_rate_a = Hp_a/Hp_lim_a,
							Hp_rate_b = Hp_b/Hp_lim_b,
							if
								Hp_rate_a<Hp_rate_b->%%血比率高的胜
									Is_win_a = false;
								Hp_rate_a=:=Hp_rate_b->
									if
										Combat_power_a=<Combat_power_b->%%战力高的胜
											Is_win_a = false;
										true->
											Is_win_a = true
									end;
								true->
									Is_win_a = true
							end;
						true->%%B胜利
							Is_win_a = false
					end,

					New_State = make_win(God_pk,God_a,God_b,State,Is_win_a)
			end
	end,
	
    {noreply, New_State};

handle_cast({close}, State) ->
	New_State = State#god_state{
		status = 2						
	},
	spawn(fun()-> 
		War_time = data_god:get(war_time),
		timer:sleep((War_time+60)*1000),
		mod_god:balance(State#god_state.mod,State#god_state.next_mod)
	end),
			   
    {noreply, New_State};

handle_cast({balance,Mod,Next_mod}, State) ->
	%%按赛事模式结算
	God_dict_list = dict:to_list(State#god_state.god_dict),
	spawn(fun()->
		%%把人丢出去
		lists:foreach(fun({_K,G})-> 
			if
				G#god.is_in /= 0->
					mod_clusters_center:apply_cast(G#god.node,lib_god,goout,[G#god.id]);
				true->void
			end
		end, God_dict_list),
		mod_clusters_center:apply_to_all_node(mod_god_state,top_list_all,[Mod,State#god_state.god_room_dict,State#god_state.god_dict])
	end),
	spawn(fun()-> 
		case Mod of
			1-> %% 海选赛结算
				balance_sea(God_dict_list,State#god_state.god_no,State#god_state.open_time,Mod,Next_mod);
			2-> %% 小组赛结算
				balance_group(Mod,Next_mod,State);
			3-> %% 复活赛结算
				balance_relive(State#god_state.god_dict,Mod,Next_mod,State#god_state.open_time);
			4-> %% 总决赛结算
				balance_sort(God_dict_list,State#god_state.open_time,Mod,Next_mod);
			_->
				void
		end,
		timer:sleep(30*1000),
		%%重新加载数据
		mod_god:load_god(State#god_state.god_no,State#god_state.mod),
		%%加载历届前50名
		mod_god:load_god_top50()		  
	end),
	
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%%
%% Local Functions
%%
%%按投票名次发传闻
vote_relive_TV([],_Pos)->void;
vote_relive_TV([God|T],Pos)->
	if
		Pos=:=1->
			mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [renqipk,
																      1,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id
																     ]]]);
		Pos=:=2->
			mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [renqipk,
																      2,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id
																     ]]]);
		Pos=:=3->
			mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [renqipk,
																      3,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id
																     ]]]);
		true->
			void
	end,
	vote_relive_TV(T,Pos+1).
	
%%通知复活赛、人气PK赛晋级
vote_relive_list_sub([],_Top2,_God_no,_Element_size,_Pos)->ok;
vote_relive_list_sub([G|T],Top2,God_no,Element_size,Pos)->
	%%是否是投票中的名单，是否在指定名次之前
	Flag = lists:member(G, Top2),
	case Flag of
		false->
			if
				Pos=<Element_size->
					lib_god:update_group_relive_is_up(G#god.flat,G#god.server_id,G#god.id,God_no,G#god.node,1),
					Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_relive3),[]),
					Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_relive3),[Pos]);
				true->
					Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_relive4),[]),
					Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_relive4),[Pos])
			end;
		true->
			lib_god:update_group_relive_is_up(G#god.flat,G#god.server_id,G#god.id,God_no,G#god.node,1),
			Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_relive5),[]),
			Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_relive5),[Pos])
	end,
	mod_clusters_center:apply_cast(G#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[G#god.id], Title, Content, 0, 2, 0, 0,0,0,0,0,0]),
	
	timer:sleep(80),
	vote_relive_list_sub(T,Top2,God_no,Element_size,Pos+1).

%%对阵表
pk_list(Node,Plat,Server_id,Id,State)->
	God_pk_dict_list = dict:to_list(State#god_state.god_pk_dict),
	Temp_Pk_list = pk_list_sub(God_pk_dict_list,Plat,Server_id,Id,State,[]),
	Sort_Temp_Pk_list = lists:sort(fun({_Flat1,_Server_id1,_Id1,_Name1,_Country1,
				  						 _Sex1,_Carrer1,_Image1,_Lv1,
										 _Power1,_Is_win1,_Score_a1,Pk_time1},
									   {_Flat2,_Server_id2,_Id2,_Name2,_Country2,
				  						 _Sex2,_Carrer2,_Image2,_Lv2,
										 _Power2,_Is_win2,_Score_a2,Pk_time2})-> 
		if
			Pk_time1=<Pk_time2->true;
			true->false
		end
	end,Temp_Pk_list),
	Pk_list = [{Flat1,Server_id1,Id1,Name1,Country1,
				 Sex1,Carrer1,Image1,Lv1,
				 Power1,Is_win1,Score_a1}||
			   {Flat1,Server_id1,Id1,Name1,Country1,
				 Sex1,Carrer1,Image1,Lv1,
				 Power1,Is_win1,Score_a1,_Pk_time1}<-Sort_Temp_Pk_list],
	{ok,BinData_11} = pt_485:write(48511, [Pk_list]),
    mod_clusters_center:apply_cast(Node,lib_unite_send,cluster_to_uid,[Id,BinData_11]),
	ok.
pk_list_sub([],_Plat,_Server_id,_Id,_State,Pk_list)->Pk_list;
pk_list_sub([{{Plat_a,Server_id_a,Id_a,Plat_b,Server_id_b,Id_b,_Loop},V}|T],Plat,Server_id,Id,State,Pk_list)->	
	if
		Plat_a=:=Plat andalso Server_id_a=:=Server_id andalso Id_a=:=Id->
			Score_a = V#god_pk.score_a,
			God_b = dict:fetch({Plat_b,Server_id_b,Id_b}, State#god_state.god_dict),
			if
				V#god_pk.id_win=:=0->
					Is_win = 3;
				Plat_a=:=V#god_pk.flat_win andalso Server_id_a=:=V#god_pk.server_id_win andalso Id_a=:=V#god_pk.id_win->
					Is_win = 1;
				true->
					Is_win = 2
			end,
			pk_list_sub(T,Plat,Server_id,Id,State,Pk_list++[{God_b#god.flat,God_b#god.server_id,God_b#god.id,
										 God_b#god.name,God_b#god.country,
				  						 God_b#god.sex,God_b#god.carrer,
										 God_b#god.image,God_b#god.lv,
										 God_b#god.power,Is_win,Score_a,V#god_pk.pk_time}]);
		Plat_b=:=Plat andalso Server_id_b=:=Server_id andalso Id_b=:=Id->
			Score = V#god_pk.score_b,
			God = dict:fetch({Plat_a,Server_id_a,Id_a}, State#god_state.god_dict),
			if
				V#god_pk.id_win=:=0->
					Is_win = 3;
				Plat_b=:=V#god_pk.flat_win andalso Server_id_b=:=V#god_pk.server_id_win andalso Id_b=:=V#god_pk.id_win->
					Is_win = 1;
				true->
					Is_win = 2
			end,
			pk_list_sub(T,Plat,Server_id,Id,State,Pk_list++[{God#god.flat,God#god.server_id,God#god.id,
										 God#god.name,God#god.country,
				  						 God#god.sex,God#god.carrer,
										 God#god.image,God#god.lv,
										 God#god.power,Is_win,Score,V#god_pk.pk_time}]);
		true->
			pk_list_sub(T,Plat,Server_id,Id,State,Pk_list)
	end.

%%排位赛每轮传闻
sort_loop_tv([],_Pos,_Sort_current_loop,_God_dict,_God_pk_dict_list)->void;
sort_loop_tv([God|T],Pos,Sort_current_loop,God_dict,God_pk_dict_list)->
	if
		Pos=:=1->
			%%找对手
			look_sort_enemy(God_pk_dict_list,Pos,God,Sort_current_loop,God_dict);
		true->
			void
	end,
	sort_loop_tv(T,Pos+1,Sort_current_loop,God_dict,God_pk_dict_list).
look_sort_enemy([],Pos,God,_Sort_current_loop,_God_dict)->
	if
		Pos=:=1->
			mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [finalfight2,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id
																     ]]]);
		true->
			void
	end;
look_sort_enemy([{{Flat1,Server_id1,Id1,Flat2,Server_id2,Id2,Loop},God_pk}|T],Pos,God,Sort_current_loop,God_dict)->
	if
		((Flat1=:=God#god.flat andalso Server_id1=:=God#god.server_id andalso Id1=:=God#god.id)
		  orelse (Flat2=:=God#god.flat andalso Server_id2=:=God#god.server_id andalso Id2=:=God#god.id))
		  andalso Loop=:=Sort_current_loop-> %%能找到对手
			if
				Pos=:=1->
					if
						God_pk#god_pk.flat_win=:=God#god.flat 
						  andalso God_pk#god_pk.server_id_win=:=God#god.server_id 
						  andalso God_pk#god_pk.id_win=:=God#god.id->%%赢的
							%%找出对手
							if
								Flat1=:=God#god.flat andalso Server_id1=:=God#god.server_id andalso Id1=:=God#god.id->
									God_b = dict:fetch({Flat2,Server_id2,Id2}, God_dict);
								true->
									God_b = dict:fetch({Flat1,Server_id1,Id1}, God_dict)
							end,
							mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [finalfight,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id,
																	  God_b#god.id,
																	  God_b#god.country,
																	  God_b#god.name,
																	  God_b#god.sex,
																	  God_b#god.carrer,
																	  God_b#god.image,
																	  God_b#god.flat,
																	  God_b#god.server_id
																     ]]]);
						true->
							mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [finalfight2,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id
																     ]]])
					end;
				true->
					void
			end;
		true->
			look_sort_enemy(T,Pos,God,Sort_current_loop,God_dict)
	end.
	
%%总决赛系统匹配
sort_match(State)->
	Sort_current_loop = State#god_state.sort_current_loop,
	New_Sort_current_loop = Sort_current_loop + 1,
	Sort_sigle_loop = data_god:get(sort_sigle_loop),
	%% 5分钟入场，5分钟后匹配出名单，6分钟下注，4分钟打架，1分钟时间来退出准备区。
	%% 找出总决赛人员名单
	God_dict_list = dict:to_list(State#god_state.god_dict),
	%% 有资格且人在准备区
	God_list = [G||{_K,G}<-God_dict_list,G#god.group_relive_is_up=:=1,G#god.is_in=:=1],
	%% 排序
	Sort_God_list = lists:sort(fun(G_a,G_b)-> 
		if
			G_a#god.sort_win_loop>G_b#god.sort_win_loop->true;
			G_a#god.sort_win_loop=:=G_b#god.sort_win_loop->
				if
					G_a#god.sort_score>G_b#god.sort_score->true;
					G_a#god.sort_score=:=G_b#god.sort_score->
						if
							G_a#god.high_power>G_b#god.high_power->true;
							G_a#god.high_power=:=G_b#god.high_power->
								if
									G_a#god.lv>=G_b#god.lv->true;
									true->false
								end;
							G_a#god.high_power<G_b#god.high_power->false
						end;
					G_a#god.sort_score<G_b#god.sort_score->false
				end;
			G_a#god.sort_win_loop<G_b#god.sort_win_loop->false
		end								   
	end,God_list),
	New_State = State#god_state{
		sort_current_loop = New_Sort_current_loop		
	},
	if
		Sort_sigle_loop=<Sort_current_loop-> %%超出次数
			%%发送传闻
			mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,[lib_chat,send_TV,[{all},1,1,[waitnextfight]]]),
			New_State;
		true->
			%%发送传闻
			spawn(fun()-> 
				if
					Sort_current_loop>0->
						sort_loop_tv(Sort_God_list,1,Sort_current_loop,
								State#god_state.god_dict,
								dict:to_list(State#god_state.god_pk_dict));
					true->
						void
				end
			end),
			%% 匹配对手
			sort_match_sub(New_State,Sort_God_list)	
	end.
sort_match_sub(State,[])->
	%%匹配完毕		
	spawn(fun()-> 
		Sort_chip_time = data_god:get(sort_chip_time),
		War_time = data_god:get(war_time),	
		Sort_rest_war_out_time = data_god:get(sort_rest_war_out_time),	
		timer:sleep((Sort_chip_time+War_time+Sort_rest_war_out_time)*1000),
		mod_god:sort_match()		
	end),
	State;
sort_match_sub(State,[G_a])->
	Sort_current_loop = State#god_state.sort_current_loop,
	%%轮空
	God_pk = #god_pk{
		flat_win = G_a#god.flat,							
		server_id_win = G_a#god.server_id,              		
		id_win = G_a#god.id,	
		
		loop = Sort_current_loop,	
						 
		flat_a = G_a#god.flat,								
		server_id_a = G_a#god.server_id,	             			
		id_a = G_a#god.id		 
	},
	Score = data_god:get_loos_score(G_a#god.power),
	New_G_a = G_a#god{
		sort_score = G_a#god.sort_score + Score,					  
		sort_win_loop = G_a#god.sort_win_loop + 1,				  
		sort_loop = G_a#god.sort_loop + 1				  
	},
	New_God_dict = dict:store({G_a#god.flat,G_a#god.server_id,G_a#god.id}, New_G_a,State#god_state.god_dict),
	New_God_pk_dict = dict:store({G_a#god.flat,G_a#god.server_id,G_a#god.id,"","",0,Sort_current_loop}, 
								 God_pk, State#god_state.god_pk_dict),		
	{ok,BinData_09} = pt_485:write(48509, [New_G_a#god.sort_score,
										   New_G_a#god.sort_win_loop,
										   New_G_a#god.sort_loop,
										   0,0,0,1,1]),
    mod_clusters_center:apply_cast(G_a#god.node,lib_unite_send,cluster_to_uid,[G_a#god.id,BinData_09]),
	New_State = State#god_state{
		god_dict = New_God_dict,
		god_pk_dict = New_God_pk_dict						
	},
	sort_match_sub(New_State,[]);
sort_match_sub(State,[G_a,G_b|T])->
	Sort_current_loop = State#god_state.sort_current_loop,
	%%能找到对手
	God_pk = #god_pk{
		flat_a = G_a#god.flat,								
		server_id_a = G_a#god.server_id,	             			
		id_a = G_a#god.id,	
		
		loop = Sort_current_loop,	
		
		flat_b = G_b#god.flat,									
		server_id_b = G_b#god.server_id,	              			
		id_b = G_b#god.id		 
	},
	New_G_a = G_a#god{
		is_in = 2,
		sort_loop = G_a#god.sort_loop + 1				  
	},
	New_G_b = G_b#god{
		is_in = 2,
		sort_loop = G_b#god.sort_loop + 1				  
	},
	Temp_God_dict = dict:store({G_a#god.flat,G_a#god.server_id,G_a#god.id}, New_G_a, State#god_state.god_dict),
	New_God_dict = dict:store({G_b#god.flat,G_b#god.server_id,G_b#god.id}, New_G_b, Temp_God_dict),
	New_God_pk_dict = dict:store({G_a#god.flat,G_a#god.server_id,G_a#god.id,G_b#god.flat,G_b#god.server_id,G_b#god.id,Sort_current_loop}, 
								 God_pk, State#god_state.god_pk_dict),		
	%%构造协议
	{ok, BinData_a} = pt_485:write(48507, [G_b#god.flat,G_b#god.server_id,G_b#god.id,
										 G_b#god.name,G_b#god.country,
				  						 G_b#god.sex,G_b#god.carrer,
										 G_b#god.image,G_b#god.lv,
										 G_b#god.power]),
	{ok, BinData_b} = pt_485:write(48507, [G_a#god.flat,G_a#god.server_id,G_a#god.id,
										 G_a#god.name,G_a#god.country,
				  						 G_a#god.sex,G_a#god.carrer,
										 G_a#god.image,G_a#god.lv,
										 G_a#god.power]),
	mod_clusters_center:apply_cast(G_a#god.node,lib_unite_send,cluster_to_uid,[G_a#god.id,BinData_a]),
	mod_clusters_center:apply_cast(G_b#god.node,lib_unite_send,cluster_to_uid,[G_b#god.id,BinData_b]),
	Max_dead_num = data_god:get(max_dead_num),
	{Win_Loop_a,Loop_a,_Score_a} = get_loop_score(New_G_a,State#god_state.mod),
	{Win_Loop_b,Loop_b,_Score_b} = get_loop_score(New_G_b,State#god_state.mod),
	{ok, BinData_08_a} = pt_485:write(48508, [Max_dead_num,0,0,Win_Loop_a,Loop_a]),
	{ok, BinData_08_b} = pt_485:write(48508, [Max_dead_num,0,0,Win_Loop_b,Loop_b]),
	mod_clusters_center:apply_cast(G_a#god.node,lib_unite_send,cluster_to_uid,[G_a#god.id,BinData_08_a]),
	mod_clusters_center:apply_cast(G_b#god.node,lib_unite_send,cluster_to_uid,[G_b#god.id,BinData_08_b]),
	%%到点结束战斗
	Sort_chip_time = data_god:get(sort_chip_time),
	spawn(fun()-> 
		War_time = data_god:get(war_time),
		%%下注时间+战斗时间
		timer:sleep((Sort_chip_time+War_time)*1000),
		mod_god:end_pk(G_a#god.flat,G_a#god.server_id,G_a#god.id,G_b#god.flat,G_b#god.server_id,G_b#god.id,Sort_current_loop)
	end),
	%%丢入战场
	spawn(fun()-> 
		timer:sleep(Sort_chip_time*1000),								  
		%%切换场景
		mod_god:goin_war({G_a#god.flat,G_a#god.server_id,G_a#god.id,G_b#god.flat,G_b#god.server_id,G_b#god.id,Sort_current_loop},G_a,G_b)
	end),
	New_State = State#god_state{
		god_dict = New_God_dict,
		god_pk_dict = New_God_pk_dict						
	},
	sort_match_sub(New_State,T).

%% 总决赛结算
balance_sort(God_dict_list,Open_time,Mod,Next_mod)->
	God_list = [G||{_K,G}<-God_dict_list,G#god.group_relive_is_up=:=1],
	
	%%全部记录先入库一次
	lists:foreach(fun(G)-> 
		lib_god:update_god_sort(G#god.flat,G#god.server_id,G#god.id,G#god.god_no,G#god.node,
								 G#god.sort_win_loop,G#god.sort_loop,G#god.sort_score)				  
	end, God_list),
	%%如果是最后一场比赛，需要给小组赛分配小组名单
	case lib_god:is_end(Open_time,Mod,Next_mod) of
		false-> %%没有结束，每人发一封提示邮件
			lists:foreach(fun(G)-> 
				Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sort2),[]),
				Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_sort2),[]),
				mod_clusters_center:apply_cast(G#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[G#god.id], Title, Content, 0, 2, 0, 0,0,0,0,0,0]),
				timer:sleep(80)				  
			end, God_list);
		true-> %%已经结束
			%% 排序
			Sort_God_list = lists:sort(fun(G_a,G_b)-> 
				if
					G_a#god.sort_win_loop>G_b#god.sort_win_loop->true;
					G_a#god.sort_win_loop=:=G_b#god.sort_win_loop->
						if
							G_a#god.sort_score>G_b#god.sort_score->true;
							G_a#god.sort_score=:=G_b#god.sort_score->
								if
									G_a#god.high_power>G_b#god.high_power->true;
									G_a#god.high_power=:=G_b#god.high_power->
										if
											G_a#god.lv>=G_b#god.lv->true;
											true->false
										end;
									G_a#god.high_power<G_b#god.high_power->false
								end;
							G_a#god.sort_score<G_b#god.sort_score->false
						end;
					G_a#god.sort_win_loop<G_b#god.sort_win_loop->false
				end										   
			end,God_list),
			%% 总积分排序
			Sort_God_score_list = lists:sort(fun(G_a,G_b)-> 
				Score_a = G_a#god.sea_score + max(G_a#god.group_score,G_a#god.relive_score) + G_a#god.sort_score,
				Score_b = G_b#god.sea_score + max(G_b#god.group_score,G_b#god.relive_score) + G_b#god.sort_score,
				if
					Score_a>Score_b->true;
					Score_a=:=Score_b->
						if
							G_a#god.high_power>G_b#god.high_power->true;
							G_a#god.high_power=:=G_b#god.high_power->
								if
									G_a#god.lv>=G_b#god.lv->true;
									true->false
								end;
							G_a#god.high_power<G_b#god.high_power->false
						end;
					Score_a<Score_b->false
				end										   
			end,God_list),
			%%人气排序：票数高、战力高、等级高
			Sort_God_vote_list = lists:sort(fun(G_a,G_b)-> 
				if
					G_a#god.relive_vote>G_b#god.relive_vote->true;
					G_a#god.relive_vote=:=G_b#god.relive_vote->
						if
							G_a#god.high_power>G_b#god.high_power->true;
							G_a#god.high_power=:=G_b#god.high_power->
								if
									G_a#god.lv>=G_b#god.lv->true;
									true->false
								end;
							G_a#god.high_power<G_b#god.high_power->false
						end;
					G_a#god.relive_vote<G_b#god.relive_vote->false
				end
			end, God_list),
			%% 颁奖
			balance_sort_sub(Sort_God_list,Sort_God_vote_list,1),
			balance_sort_sub2(Sort_God_score_list,1),
			balance_sort_sub3(Sort_God_vote_list,1),
			%%按照排名设置经验全服buff
			set_god_exp(Sort_God_list,1,dict:new())
	end.
set_god_exp([],_Pos,Flat_dict)->
	Flat_dict_list = dict:to_list(Flat_dict),
	lists:foreach(fun({_Key,{God,TPos}})-> 
		mod_clusters_center:apply_cast(God#god.node, mod_god_state,set_god_exp, [God,TPos])				  			  
	end, Flat_dict_list);
set_god_exp([God|T],Pos,Flat_dict)->
	Key = {God#god.flat,God#god.server_id},
	case dict:is_key(Key, Flat_dict) of
		false->
			New_Flat_dict = dict:store(Key, {God,Pos}, Flat_dict);
		true->
			{_Temp_god,Temp_Pos} = dict:fetch(Key, Flat_dict),
			if
				Pos=<Temp_Pos->
					New_Flat_dict = dict:store(Key, {God,Pos}, Flat_dict);
				true->
					New_Flat_dict = Flat_dict
			end
	end,
	set_god_exp(T,Pos+1,New_Flat_dict).
	
balance_sort_sub3([],_Pos)->ok;
balance_sort_sub3([God|T],Pos)->
	if
		Pos=:=1->
			mod_clusters_center:apply_cast(God#god.node, lib_designation,bind_design_in_server, [God#god.id, 201640,"",1]);
		true->
			void
	end,
	{Gift_id3,Gift_num3} = data_god:get_gift_sort3(Pos),
	Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sort_4),[]),
	Temp_sort_score = God#god.sort_score div 1000,
	Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_sort3),[God#god.sort_loop,God#god.sort_win_loop,Temp_sort_score,Pos]),
	if
		Gift_num3=<0->void;
		true->
			mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title, Content, Gift_id3, 2, 0, 0,Gift_num3,0,0,0,0])
	end,
	timer:sleep(80),
	balance_sort_sub3(T,Pos+1).
balance_sort_sub2([],_Pos)->ok;
balance_sort_sub2([God|T],Pos)->
	if
		Pos=:=1->
			mod_clusters_center:apply_cast(God#god.node, lib_designation,bind_design_in_server, [God#god.id, 201639,"",1]);
		true->
			void
	end,
	{Gift_id2,Gift_num2} = data_god:get_gift_sort2(Pos),
	Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sort_3),[]),
	Temp_sort_score = God#god.sort_score div 1000,
	Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_sort22),[God#god.sort_loop,God#god.sort_win_loop,Temp_sort_score,Pos]),
	if
		Gift_num2=<0->void;
		true->
			mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title, Content, Gift_id2, 2, 0, 0,Gift_num2,0,0,0,0])
	end,
	timer:sleep(80),
	balance_sort_sub2(T,Pos+1).
balance_sort_sub([],_Sort_God_vote_list,_Pos)->ok;
balance_sort_sub([God|T],Sort_God_vote_list,Pos)->
	%%发送传闻、称号
	if
		Pos=:=1->
			mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [zhutianrank,
																      1,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id
																     ]]]),
			mod_clusters_center:apply_cast(God#god.node, lib_designation,bind_design_in_server, [God#god.id, 201636,"",1]);
		Pos=:=2->
			mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [zhutianrank,
																      2,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id
																     ]]]),
			mod_clusters_center:apply_cast(God#god.node, lib_designation,bind_design_in_server, [God#god.id, 201637,"",1]);
		Pos=:=3->
			mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [zhutianrank,
																      3,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id
																     ]]]),
			mod_clusters_center:apply_cast(God#god.node, lib_designation,bind_design_in_server, [God#god.id, 201638,"",1]);
		Pos=<8->
			mod_clusters_center:apply_cast(God#god.node, lib_designation,bind_design_in_server, [God#god.id, 201641,"",1]);
		Pos=<18->
			mod_clusters_center:apply_cast(God#god.node, lib_designation,bind_design_in_server, [God#god.id, 201642,"",1]);
		true->
			void
	end,
	People_no = get_people_no(Sort_God_vote_list,God#god.flat,God#god.server_id,God#god.id,1),
	Score = God#god.sea_score + max(God#god.group_score,God#god.relive_score) + God#god.sort_score,
	
	{ok, BinData} = pt_485:write(48513, [God#god.god_no,God#god.sea_win_loop,God#god.sea_loop,God#god.group_win_loop,
			  God#god.group_loop,God#god.sort_win_loop,God#god.sort_loop,Pos,People_no,Score]),
	mod_clusters_center:apply_cast(God#god.node,lib_unite_send,cluster_to_uid,[God#god.id,BinData]),
	
	{Xunzhang_id,Xunzhang_num} = data_god:get_xunzhang_sort(God#god.sort_win_loop,God#god.sort_loop),
	Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sort_2),[]),
	Temp_sort_score = God#god.sort_score div 1000,
	Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_sort),[God#god.sort_loop,God#god.sort_win_loop,Temp_sort_score,Pos]),
	mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title, Content, Xunzhang_id, 2, 0, 0,Xunzhang_num,0,0,0,0]),
	timer:sleep(80),
	%%发放礼包
	{Gift_id1,Gift_num1} = data_god:get_gift_sort1(Pos),
	if
		Gift_num1=<0->void;
		true->
			Title_mingci = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sort_1),[]),
			mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title_mingci, Content, Gift_id1, 2, 0, 0,Gift_num1,0,0,0,0])
	end,
	timer:sleep(80),
	balance_sort_sub(T,Sort_God_vote_list,Pos+1).
get_people_no([],_Flat,_Server_id,_Id,_Pos)->0;
get_people_no([G|T],Flat,Server_id,Id,Pos)->
	if
		Flat=:=G#god.flat andalso Server_id=:=G#god.server_id andalso Id=:=G#god.id->
			Pos;
		true->
			get_people_no(T,Flat,Server_id,Id,Pos+1)
	end.

%% 复活赛结算
balance_relive(God_dict,Mod,Next_mod,Open_time)->
	Temp_God_dict_list = dict:to_list(God_dict),
	God_list = [G||{_K,G}<-Temp_God_dict_list,G#god.group_relive_is_up=:=0],
	%%全部记录先入库一次,并发提示邮件
	lists:foreach(fun(G)-> 
		lib_god:update_god_relive(G#god.flat,G#god.server_id,G#god.id,G#god.god_no,G#god.node,
								 G#god.relive_win_loop,G#god.relive_loop,G#god.relive_score)
	end, God_list),
	%%如果是最后一场比赛，需要给小组赛分配小组名单
	case lib_god:is_end(Open_time,Mod,Next_mod) of
		false-> %%没有结束，每人发一封提示邮件
			lists:foreach(fun(G)-> 
				Title1 = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_relive2),[]),
				Content1 = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_relive2),[]),
				mod_clusters_center:apply_cast(G#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[G#god.id], Title1, Content1, 0, 2, 0, 0,0,0,0,0,0]),
				timer:sleep(80)	  
			end, God_list);
		true-> %%已经结束
			%%排序：积分高、战力高、等级高
			Sort_God_sea_list = lists:sort(fun(G_a,G_b)-> 
				if
					G_a#god.relive_score>G_b#god.relive_score->true;
					G_a#god.relive_score=:=G_b#god.relive_score->
						if
							G_a#god.high_power>G_b#god.high_power->true;
							G_a#god.high_power=:=G_b#god.high_power->
								if
									G_a#god.lv>=G_b#god.lv->true;
									true->false
								end;
							G_a#god.high_power<G_b#god.high_power->false
						end;
					G_a#god.relive_score<G_b#god.relive_score->false
				end
			end, God_list),
			balance_relive_sub(Sort_God_sea_list,1)
	end.
balance_relive_sub([],_Pos)->ok;
balance_relive_sub([God|T],Pos)->
	%%发送传闻
	if
		Pos=:=1->
			mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [relivefight,
																      1,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id
																     ]]]);
		Pos=:=2->
			mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [relivefight,
																      2,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id
																     ]]]);
		Pos=:=3->
			mod_clusters_center:apply_to_all_node(mod_disperse,cast_to_unite,
												  [lib_chat,send_TV,[{all},1,1,
																	 [relivefight,
																      3,
																      God#god.id,
																	  God#god.country,
																	  God#god.name,
																	  God#god.sex,
																	  God#god.carrer,
																	  God#god.image,
																	  God#god.flat,
																	  God#god.server_id
																     ]]]);
		true->
			void
	end,
	
	Title1 = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_relive2),[]),
	Content1 = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_relive2),[]),
	mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title1, Content1, 0, 2, 0, 0,0,0,0,0,0]),
	timer:sleep(80),

	{Xunzhang_id,Xunzhang_num} = data_god:get_xunzhang_relive(God#god.relive_win_loop,God#god.relive_loop),
	Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_relive_3),[]),
	Temp_relive_score = God#god.relive_score div 1000,
	Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_relive),[God#god.relive_loop,God#god.relive_win_loop,Temp_relive_score,Pos]),
	mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title, Content, Xunzhang_id, 2, 0, 0,Xunzhang_num,0,0,0,0]),
	timer:sleep(80),
	%%发放礼包
	{Gift_id1,Gift_num1} = data_god:get_gift_relive(Pos),
	if
		Gift_num1=<0->void;
		true->
			Title_canyu = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_relive_2),[]),
			mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title_canyu, Content, Gift_id1, 2, 0, 0,Gift_num1,0,0,0,0])
	end,
	timer:sleep(80),
	%%霸者之心
	Title_bazhe = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_relive_1),[]),
	{Bazhe_id,Bazhe_num} = data_god:get_bazhe(God#god.group_win_loop,God#god.group_loop),
	mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title_bazhe, Content, Bazhe_id, 2, 0, 0,Bazhe_num,0,0,0,0]),
	timer:sleep(80),
	balance_relive_sub(T,Pos+1).	

%% 小组赛结算
balance_group(Mod,Next_mod,State)->
	God_dict_list = dict:to_list(State#god_state.god_dict),
	Open_time = State#god_state.open_time,
	
	%%全部记录先入库一次
	lists:foreach(fun({_K,G})-> 
		lib_god:update_god_group(G#god.flat,G#god.server_id,G#god.id,G#god.god_no,G#god.node,
								 G#god.group_win_loop,G#god.group_loop,G#god.group_score)				  
	end, God_dict_list),
	%%如果是最后一场比赛，需要给小组赛分配小组名单
	case lib_god:is_end(Open_time,Mod,Next_mod) of
		false-> %%没有结束，每人发一封提示邮件
			lists:foreach(fun({_K,G})-> 
				Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_group2),[]),
				Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_group2),[]),
				mod_clusters_center:apply_cast(G#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[G#god.id], Title, Content, 0, 2, 0, 0,0,0,0,0,0]),
				timer:sleep(80)				  
			end, God_dict_list);
		true-> %%已经结束，选拔选手
			%%按照每组选拔对手
			God_room_dict_list = dict:to_list(State#god_state.god_room_dict),
			lists:foreach(fun({_K,R})-> 
				%% 排序每个房间人员							  
				Player_list = R#god_room.player_list,
				Sort_player_list = lists:sort(fun({Flat_a,Server_id_a,Id_a},{Flat_b,Server_id_b,Id_b})-> 
					G_a = dict:fetch({Flat_a,Server_id_a,Id_a}, State#god_state.god_dict),
					G_b = dict:fetch({Flat_b,Server_id_b,Id_b}, State#god_state.god_dict),
					if
						G_a#god.group_score>G_b#god.group_score->true;
						G_a#god.group_score=:=G_b#god.group_score->
							if
								G_a#god.group_loop>G_b#god.group_loop->false;
								G_a#god.group_loop=:=G_b#god.group_loop->
									if
										G_a#god.high_power>G_b#god.high_power->true;
										G_a#god.high_power=:=G_b#god.high_power->
											if
												G_a#god.lv>=G_b#god.lv->true;
												true->false
											end;
										G_a#god.high_power<G_b#god.high_power->false
									end;
								G_a#god.group_loop<G_b#god.group_loop->true
							end;
						G_a#god.group_score<G_b#god.group_score->false
					end
				end, Player_list),
				balance_group_sub(State,Sort_player_list,1)				 
			end, God_room_dict_list)
	end.
balance_group_sub(_State,[],_Pos)->ok;
balance_group_sub(State,[{Flat,Server_id,Id}|T],Pos)->
	God = dict:fetch({Flat,Server_id,Id}, State#god_state.god_dict),
	if
		State#god_state.god_no=:=0 andalso State#god_state.last_god_no/=0->
			God_no = State#god_state.last_god_no;
		true->
			God_no = State#god_state.god_no
	end,
	%%每个房间抓前两名
	if
		Pos=<2->
			Result = 1,
			%%更新数据库资格
			lib_god:update_group_relive_is_up(Flat,Server_id,Id,God_no,God#god.node,1),
			Mail_title_promote = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_group3),[]),
			Mail_content_promote = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_group3),[Pos]);
		true->
			Result = 2,
			Mail_title_promote = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_group4),[]),
			Mail_content_promote = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_group4),[Pos])
	end,
	{ok, BinData} = pt_485:write(48510, [1,Result,God#god.group_win_loop,God#god.group_loop,God#god.group_score]),
	mod_clusters_center:apply_cast(God#god.node,lib_unite_send,cluster_to_uid,[God#god.id,BinData]),
	%%晋级邮件
	mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,
				[[God#god.id], Mail_title_promote, Mail_content_promote, 0, 0, 0, 0,0,0,0,0,0]),
	timer:sleep(80),
	%%勋章
	{Xunzhang_id,Xunzhang_num} = data_god:get_xunzhang_group(God#god.group_win_loop,God#god.group_loop),
	{Belief_id,Belief_num} = data_god:get_belief(God#god.group_win_loop,God#god.group_loop),
	Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_group_3),[]),
	Temp_group_score = God#god.group_score div 1000,
	Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_group),[God#god.group_loop,God#god.group_win_loop,Temp_group_score,Pos]),
	mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title, Content, Xunzhang_id, 2, 0, 0,Xunzhang_num,0,0,0,0]),
	timer:sleep(80),
	%%信仰之心
	Title_belief = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_group_1),[]),
	mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title_belief, Content, Belief_id, 2, 0, 0,Belief_num,0,0,0,0]),
	timer:sleep(80),
	%%发放礼包
	{Gift_id,Gift_num} = data_god:get_gift_group(Pos),
	if
		Gift_num=<0->void;
		true->
			Title_paiming = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_group_2),[]),
			mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title_paiming, Content, Gift_id, 2, 0, 0,Gift_num,0,0,0,0])
	end,
	timer:sleep(80),
	balance_group_sub(State,T,Pos+1).

%% 海选赛结算
balance_sea(God_dict_list,God_no,Open_time,Mod,Next_mod)->
	%%获取本场实际参与玩家
	God_sea_list = [V||{_K,V}<-God_dict_list,V#god.is_db=:=0],
	%%排序：积分高、战力高、等级高
	Sort_God_sea_list = lists:sort(fun(G_a,G_b)-> 
		if
			G_a#god.sea_score>G_b#god.sea_score->true;
			G_a#god.sea_score=:=G_b#god.sea_score->
				if
					G_a#god.high_power>G_b#god.high_power->true;
					G_a#god.high_power=:=G_b#god.high_power->
						if
							G_a#god.lv>=G_b#god.lv->true;
							true->false
						end;
					G_a#god.high_power<G_b#god.high_power->false
				end;
			G_a#god.sea_score<G_b#god.sea_score->false
		end
	end, God_sea_list),
	%%找出需要入库的名单，即晋级小组赛玩家。前80名，通知晋级，发邮件，入库；后80名，通知失败，发邮件。
	balance_sea_sub(1,Sort_God_sea_list),
	%%发奖：勋章、信仰之心、参与礼包
	lists:foreach(fun({_K,God})-> 
		if
			God#god.is_db=:=1->%%针对已有小组赛资格的人
				%%勋章
				{Xunzhang_id,_Xunzhang_num} = data_god:get_xunzhang_sea(God#god.sea_win_loop,God#god.sea_loop),
				Xunzhang_num = 150,
				{Belief_id,_Belief_num} = data_god:get_belief(God#god.sea_win_loop,God#god.sea_loop),
				Belief_num = 3,
				Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sea_3),[]),
				Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_sea2),[]),
				mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title, Content, Xunzhang_id, 2, 0, 0,Xunzhang_num,0,0,0,0]),
				timer:sleep(80),
				%%信仰之心
				Title_belief = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sea_1),[]),
				mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title_belief, Content, Belief_id, 2, 0, 0,Belief_num,0,0,0,0]),
				timer:sleep(80),
				%%发放礼包
				{Gift_id,Gift_num} = data_god:get_gift_sea(9999999),
				if
					Gift_num=<0->void;
					true->
						Title_canyu = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sea_2),[]),
						mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title_canyu, Content, Gift_id, 2, 0, 0,Gift_num,0,0,0,0])
				end,
				timer:sleep(80);
			true->void
		end
	end, God_dict_list),
	%%如果是最后一场比赛，需要给小组赛分配小组名单
	case lib_god:is_end(Open_time,Mod,Next_mod) of
		false->void;
		true->
			God_dict = lib_god:load_god(God_no),
			God_dict_list1 = dict:to_list(God_dict),
			Sort_God_dict_list = lists:sort(fun({_K_a,G_a},{_K_b,G_b})-> 
				if
					G_a#god.sea_score>G_b#god.sea_score->true;
					G_a#god.sea_score=:=G_b#god.sea_score->
						if
							G_a#god.high_power>G_b#god.high_power->true;
							G_a#god.high_power=:=G_b#god.high_power->
								if
									G_a#god.high_power>=G_b#god.high_power->true;
									true->false
								end;
							G_a#god.high_power<G_b#god.high_power->false
						end;
					G_a#god.sea_score<G_b#god.sea_score->false
				end										
			end,God_dict_list1),
			God_dict_list1_len = length(God_dict_list1),
			Max_group_num = data_god:get(max_group_num),
			if
				God_dict_list1_len rem Max_group_num =:= 0->
					Max_Room_no = God_dict_list1_len div Max_group_num;
				true->
					Max_Room_no = (God_dict_list1_len div Max_group_num) + 1
			end,
			update_group_room_no(Sort_God_dict_list,Max_Room_no,1)
	end.
update_group_room_no([],_Max_Room_no,_Room_no)->ok;
update_group_room_no([{_K,G}|T],Max_Room_no,Room_no)->
	if
		Room_no>=Max_Room_no->
			lib_god:update_group_room_no(G#god.flat,G#god.server_id,G#god.id,G#god.god_no,G#god.node,Max_Room_no),
			update_group_room_no(T,Max_Room_no,1);
		true->
			lib_god:update_group_room_no(G#god.flat,G#god.server_id,G#god.id,G#god.god_no,G#god.node,Room_no),
			update_group_room_no(T,Max_Room_no,Room_no+1)
	end.
	
balance_sea_sub(_Pos,[])->ok;
balance_sea_sub(Pos,[God|T])->
	if
		Pos=<80->%%前80名，晋级,入库
			Result = 1,
			Mail_title_promote = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sea3),[]),
			Mail_content_promote = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_sea3),[Pos]),
			{JJiId,JJiNum} = data_god:get_up_gift_sea(),
			lib_god:insert_god(God#god.flat,God#god.server_id,God#god.id,God#god.god_no,God#god.node,
							   God#god.name,God#god.country,God#god.sex,God#god.carrer,God#god.image,
							   God#god.lv,God#god.power,God#god.high_power,
							   God#god.sea_win_loop,God#god.sea_loop,God#god.sea_score);
		true->
			Result = 2,
			{JJiId,JJiNum} = {0,0},
			Mail_title_promote = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sea4),[]),
			Mail_content_promote = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_sea4),[Pos])
	end,
	{ok, BinData} = pt_485:write(48510, [1,Result,God#god.sea_win_loop,God#god.sea_loop,God#god.sea_score]),
	mod_clusters_center:apply_cast(God#god.node,lib_unite_send,cluster_to_uid,[God#god.id,BinData]),
	%%晋级邮件
	mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,
				[[God#god.id], Mail_title_promote, Mail_content_promote, JJiId, 2, 0, 0,JJiNum,0,0,0,0]),
	timer:sleep(80),
	%%勋章
	{Xunzhang_id,Xunzhang_num} = data_god:get_xunzhang_sea(God#god.sea_win_loop,God#god.sea_loop),
	{Belief_id,Belief_num} = data_god:get_belief(God#god.sea_win_loop,God#god.sea_loop),
	Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sea_3),[]),
	Temp_sea_score = God#god.sea_score div 1000,
	Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_sea),[God#god.sea_loop,God#god.sea_win_loop,Temp_sea_score,Pos]),
	mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title, Content, Xunzhang_id, 2, 0, 0,Xunzhang_num,0,0,0,0]),
	timer:sleep(80),
	%%信仰之心
	Title_belief = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sea_1),[]),
	mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title_belief, Content, Belief_id, 2, 0, 0,Belief_num,0,0,0,0]),
	timer:sleep(80),
	%%发放礼包
	{Gift_id,Gift_num} = data_god:get_gift_sea(Pos),
	if
		Gift_num=<0->void;
		true->
			Title_canyu = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sea_2),[]),
			mod_clusters_center:apply_cast(God#god.node,lib_mail,send_sys_mail_bg_4_1v1,[[God#god.id], Title_canyu, Content, Gift_id, 2, 0, 0,Gift_num,0,0,0,0])
	end,
	timer:sleep(80),
	balance_sea_sub(Pos+1,T).

%%判断胜负
%% @param God_pk #god_pk
%% @param God_a #god_pk中的A
%% @param God_b #god_pk中的B
%% @param State #god_state
%% @param Is_win_a A是否赢了 true|false
make_win(God_pk,God_a,God_b,State,Is_win_a)->
	if
		State#god_state.mod=:=0 andalso State#god_state.last_mod/=0->
			Mod = State#god_state.last_mod;
		true->
			Mod = State#god_state.mod
	end,
	case Is_win_a of
		false-> %%A输了
			Win_flag_a = 0,
			Win_flag_b = 1,
			%%判胜负
			New_God_pk = God_pk#god_pk{
				flat_win = God_b#god.flat,							
				server_id_win = God_b#god.server_id,              			
				id_win = God_b#god.id
			},
			%%算积分
			Score_a_1 = data_god:get_fail_score(God_a#god.power,God_b#god.power,get_dead_num(God_b#god.flat,God_b#god.server_id,God_b#god.id,New_God_pk)),
			Score_b_1 = data_god:get_succ_score(God_b#god.power,God_a#god.power,get_rest_dead_num(God_b#god.flat,God_b#god.server_id,God_b#god.id,New_God_pk)),
			%%添加胜利次数
			Temp_God_b = add_loop(God_b,Mod,1,0),
			%%添加积分
			God_score_a = add_score(God_a,Mod,Score_a_1),
			God_score_b = add_score(Temp_God_b,Mod,Score_b_1);
		true-> %%A赢了
			Win_flag_a = 1,
			Win_flag_b = 0,
			%%判胜负
			New_God_pk = God_pk#god_pk{
				flat_win = God_a#god.flat,							
				server_id_win = God_a#god.server_id,              			
				id_win = God_a#god.id
			},
			%%算积分
			Score_a_1 = data_god:get_succ_score(God_a#god.power,God_b#god.power,get_rest_dead_num(God_a#god.flat,God_a#god.server_id,God_a#god.id,New_God_pk)),
			Score_b_1 = data_god:get_fail_score(God_b#god.power,God_a#god.power,get_dead_num(God_a#god.flat,God_a#god.server_id,God_a#god.id,New_God_pk)),
			%%添加胜利次数
			Temp_God_a = add_loop(God_a,Mod,1,0),
			%%添加积分
			God_score_a = add_score(Temp_God_a,Mod,Score_a_1),
			God_score_b = add_score(God_b,Mod,Score_b_1)
	end,
	
	New_God_a = God_score_a#god{
		last_out_war_time = util:unixtime()											
	},
	New_God_b = God_score_b#god{
		last_out_war_time = util:unixtime()												
	},
	Temp_God_dict = dict:store({God_a#god.flat,God_a#god.server_id,God_a#god.id}, New_God_a, State#god_state.god_dict),
	New_God_dict = dict:store({God_b#god.flat,God_b#god.server_id,God_b#god.id}, New_God_b, Temp_God_dict),
	%%协议处理
	Dead_num_a = New_God_pk#god_pk.dead_num_a,
	Dead_num_b = New_God_pk#god_pk.dead_num_b,
	Max_dead_num = data_god:get(max_dead_num),
	{Win_Loop_a,Loop_a,Score_a} = get_loop_score(New_God_a,Mod),
	{Win_Loop_b,Loop_b,Score_b} = get_loop_score(New_God_b,Mod),
	{ok,BinData_08_a} = pt_485:write(48508, [Max_dead_num,Dead_num_a,Dead_num_b,Win_Loop_a,Loop_a]),
	{ok,BinData_08_b} = pt_485:write(48508, [Max_dead_num,Dead_num_b,Dead_num_a,Win_Loop_b,Loop_b]),
	mod_clusters_center:apply_cast(God_a#god.node,lib_unite_send,cluster_to_uid,[God_a#god.id,BinData_08_a]),
	mod_clusters_center:apply_cast(God_b#god.node,lib_unite_send,cluster_to_uid,[God_b#god.id,BinData_08_b]),
	
	{ok,BinData_09_a} = pt_485:write(48509, [Score_a,Win_Loop_a,Loop_a,Score_b,Win_Loop_b,Loop_b,0,Win_flag_a]),
	{ok,BinData_09_b} = pt_485:write(48509, [Score_b,Win_Loop_b,Loop_b,Score_a,Win_Loop_a,Loop_a,0,Win_flag_b]),
	mod_clusters_center:apply_cast(God_a#god.node,lib_unite_send,cluster_to_uid,[God_a#god.id,BinData_09_a]),
	mod_clusters_center:apply_cast(God_b#god.node,lib_unite_send,cluster_to_uid,[God_b#god.id,BinData_09_b]),
	
	%%把人丢回安全区或者外面
	spawn(fun()-> 
		timer:sleep(5*1000),
		mod_god:goin(war,God_a#god.node,God_a#god.flat,God_a#god.server_id,God_a#god.id,God_a#god.name,
					 God_a#god.country,God_a#god.sex,God_a#god.carrer,God_a#god.image,God_a#god.lv,
					 God_a#god.power,God_a#god.high_power),
		mod_god:goin(war,God_b#god.node,God_b#god.flat,God_b#god.server_id,God_b#god.id,God_b#god.name,
					 God_b#god.country,God_b#god.sex,God_b#god.carrer,God_b#god.image,God_b#god.lv,
					 God_b#god.power,God_b#god.high_power)
	end),
	New_State = State#god_state{
		god_dict = New_God_dict,
		god_pk_dict = dict:store({God_a#god.flat,God_a#god.server_id,God_a#god.id,
								  God_b#god.flat,God_b#god.server_id,God_b#god.id,
								  New_God_pk#god_pk.loop}, 
								 New_God_pk, State#god_state.god_pk_dict)
	},
	New_State.

%%获取自己剩余的死亡次数
get_rest_dead_num(Flat,Server_id,Id,God_pk)->
	Max_dead_num = data_god:get(max_dead_num),
	if
		Flat=:=God_pk#god_pk.flat_a andalso Server_id=:=God_pk#god_pk.server_id_a andalso Id=:=God_pk#god_pk.id_a->
			Rest_dead_num = Max_dead_num-God_pk#god_pk.dead_num_a;
		true->
			Rest_dead_num = Max_dead_num-God_pk#god_pk.dead_num_b
	end,
	if
		Rest_dead_num <0->0;
		true->Rest_dead_num
	end.

%%获取自己的死亡次数
get_dead_num(Flat,Server_id,Id,God_pk)->
	if
		Flat=:=God_pk#god_pk.flat_a andalso Server_id=:=God_pk#god_pk.server_id_a andalso Id=:=God_pk#god_pk.id_a->
			God_pk#god_pk.dead_num_a;
		true->
			God_pk#god_pk.dead_num_b
	end.

%%寻找属于他且正在进行的战斗
look_pk_no_end(_Plat,_Server_id,_Id,[])->{error,no_match};
look_pk_no_end(Plat,Server_id,Id,[{K={Flat_a,Server_id_a,Id_a,Flat_b,Server_id_b,Id_b,_Loop},V}|T])->
	if
		((Plat=:=Flat_a andalso Server_id=:=Server_id_a andalso Id=:=Id_a)
		  orelse (Plat=:=Flat_b andalso Server_id=:=Server_id_b andalso Id=:=Id_b))
		  andalso V#god_pk.id_win=:=0->
			{ok,{K,V}};
		true->
			look_pk_no_end(Plat,Server_id,Id,T)
	end.

%%开启一个战斗
%% @param God_a 玩家A
%% @param God_b 玩家B
%% @param State 状态
%% @return New_State 新状态
make_pk(God_a,God_b,State)->
	Plat = God_a#god.flat,
	Server_id = God_a#god.server_id,
	Id = God_a#god.id,
	B_Plat = God_b#god.flat,
	B_Server_id = God_b#god.server_id,
	B_Id = God_b#god.id,
	Temp_God_a = add_loop(God_a,State#god_state.mod,0,1),
	Temp_God_b = add_loop(God_b,State#god_state.mod,0,1),
	New_God_a = Temp_God_a#god{
		is_in = 2					  
	},
	New_God_b = Temp_God_b#god{
		is_in = 2					  
	},
	
	Temp_God_dict = dict:store({Plat,Server_id,Id}, New_God_a, State#god_state.god_dict),
	New_God_dict = dict:store({B_Plat,B_Server_id,B_Id}, New_God_b, Temp_God_dict),
	God_pk = #god_pk{
		flat_a = Plat,								
		server_id_a = Server_id,              			
		id_a = Id,
		
		flat_b = B_Plat,								
		server_id_b = B_Server_id,              			
		id_b = B_Id	
	},
	New_God_pk_dict = dict:store({Plat,Server_id,Id,B_Plat,B_Server_id,B_Id,0}, 
								 God_pk, State#god_state.god_pk_dict),
	%%构造协议
	{ok, BinData_a} = pt_485:write(48507, [God_b#god.flat,God_b#god.server_id,God_b#god.id,
										 God_b#god.name,God_b#god.country,
				  						 God_b#god.sex,God_b#god.carrer,
										 God_b#god.image,God_b#god.lv,
										 God_b#god.power]),
	{ok, BinData_b} = pt_485:write(48507, [God_a#god.flat,God_a#god.server_id,God_a#god.id,
										 God_a#god.name,God_a#god.country,
				  						 God_a#god.sex,God_a#god.carrer,
										 God_a#god.image,God_a#god.lv,
										 God_a#god.power]),
	mod_clusters_center:apply_cast(God_a#god.node,lib_unite_send,cluster_to_uid,[God_a#god.id,BinData_a]),
	mod_clusters_center:apply_cast(God_b#god.node,lib_unite_send,cluster_to_uid,[God_b#god.id,BinData_b]),
	
	Max_dead_num = data_god:get(max_dead_num),
	{Win_Loop_a,Loop_a,_Score_a} = get_loop_score(New_God_a,State#god_state.mod),
	{Win_Loop_b,Loop_b,_Score_b} = get_loop_score(New_God_b,State#god_state.mod),
	{ok, BinData_08_a} = pt_485:write(48508, [Max_dead_num,0,0,Win_Loop_a,Loop_a]),
	{ok, BinData_08_b} = pt_485:write(48508, [Max_dead_num,0,0,Win_Loop_b,Loop_b]),
	mod_clusters_center:apply_cast(God_a#god.node,lib_unite_send,cluster_to_uid,[God_a#god.id,BinData_08_a]),
	mod_clusters_center:apply_cast(God_b#god.node,lib_unite_send,cluster_to_uid,[God_b#god.id,BinData_08_b]),
	
	%%到点结束战斗
	spawn(fun()-> 
		War_time = data_god:get(war_time),
		timer:sleep(War_time*1000),
		mod_god:end_pk(Plat,Server_id,Id,B_Plat,B_Server_id,B_Id,0)
	end),
	
	%%丢入战场
	spawn(fun()-> 
		timer:sleep(5*1000),								  
		%%切换场景
		mod_god:goin_war({New_God_a#god.flat,
						  New_God_a#god.server_id,
						  New_God_a#god.id,
						  New_God_b#god.flat,
						  New_God_b#god.server_id,
						  New_God_b#god.id,0},New_God_a,New_God_b)
	end),
	%%从房间人员列表里剔除
	State_a = remove_room(Plat,Server_id,Id,State),
	State_b = remove_room(B_Plat,B_Server_id,B_Id,State_a),
	New_State = State_b#god_state{
		god_dict = New_God_dict,
		god_pk_dict = New_God_pk_dict						
	},
	New_State.

%%获取一个空闲玩家
%% @param God_a #god{}
%% @param State #god_state{}
%% @return {ok,#god{}} | {error,no_match}
get_free_god(God_a,State)->
	Mod = State#god_state.mod,
	Now_time = util:unixtime(),
	if 
		Mod =:= 1 orelse Mod=:=3-> 
			Match_god_list = get_match_god_list_sea(Mod,Now_time,God_a,State#god_state.god_pk_dict,
													dict:to_list(State#god_state.god_dict),[]);
		Mod =:= 2-> %%必须要同一房间
			Room_no = God_a#god.room_no,
			Scene_id1 = lists:nth(1, (data_god:get(scene_id1))),
			God_room = dict:fetch({Scene_id1,Room_no}, State#god_state.god_room_dict),
			%%找出符合条件的玩家
			Match_god_list = get_match_god_list_group(Mod,Now_time,God_a,State#god_state.god_pk_dict,
													State#god_state.god_dict,God_room#god_room.player_list,[]);
		true->Match_god_list = []
	end,
	get_free_god_sub(God_a,Match_god_list).
get_free_god_sub(God_a,Match_god_list)->
	%%按战力排序
	Sort_Match_god_list = lists:sort(fun(G1,G2)-> 
		Power1 = max(G1#god.power,G1#god.high_power),
		Power2 = max(G2#god.power,G2#god.high_power),
		if
			Power1>Power2->true;
			Power1=:=Power2->
				if
					G1#god.lv>=G2#god.lv->true;
					true->false
				end;
			Power1<Power2->false
		end
	end,Match_god_list),
	%%查找自己的位置
	case get_Sort_Match_god_list_pos(Sort_Match_god_list,God_a,1) of
		0->{error,no_match};
		Pos->
			if
				Pos-10<1->
					Start = 1;
				true->
					Start = Pos - 10
			end,
			%%截取符合条件的名单段，并移除本人
			T_Sub_Sort_Match_god_list = lists:sublist(Sort_Match_god_list, Start, 20),
			Sub_Sort_Match_god_list = lists:delete(God_a, T_Sub_Sort_Match_god_list),
			if
				length(Sub_Sort_Match_god_list)>0->
					{ok,util:list_rand(Sub_Sort_Match_god_list)};
				true->
					{error,no_match}
			end
	end.
get_Sort_Match_god_list_pos([],_God_a,_Pos)->0;
get_Sort_Match_god_list_pos([V|T],God_a,Pos)->
	if
		God_a#god.flat=:=V#god.flat 
		  andalso God_a#god.server_id=:=V#god.server_id 
		  andalso God_a#god.id=:=V#god.id->%%本人
			Pos;
		true->
			get_Sort_Match_god_list_pos(T,God_a,Pos+1)
	end.
%%海选、复活随机名单条件
get_match_god_list_sea(_Mod,_Now_time,_God_a,_God_pk_dict,[],Match_god_list)->Match_god_list;
get_match_god_list_sea(Mod,Now_time,God_a,God_pk_dict,[{_K,V}|T],Match_god_list)->
	Time_gap = Now_time - V#god.last_out_war_time,
	Last_out_war_time = data_god:get(last_out_war_time),
	Check_max_loop_v = is_max_loop(Mod,V),
	if
		God_a#god.flat=:=V#god.flat 
		  andalso God_a#god.server_id=:=V#god.server_id 
		  andalso God_a#god.id=:=V#god.id->%%本人
			get_match_god_list_sea(Mod,Now_time,God_a,God_pk_dict,T,Match_god_list++[V]);
		Time_gap>Last_out_war_time andalso V#god.is_in =:= 1 andalso Check_max_loop_v=:=false->%%CD已过且在准备区且次数未满
			%%判断是否有历史战斗记录
			Flag_a = dict:is_key({God_a#god.flat,God_a#god.server_id,God_a#god.id,
								  V#god.flat,V#god.server_id,V#god.id,0},God_pk_dict),
			Flag_b = dict:is_key({V#god.flat,V#god.server_id,V#god.id,
								  God_a#god.flat,God_a#god.server_id,God_a#god.id,0},God_pk_dict),
			case Flag_a orelse Flag_b of
				false->get_match_god_list_sea(Mod,Now_time,God_a,God_pk_dict,T,Match_god_list++[V]);
				true->get_match_god_list_sea(Mod,Now_time,God_a,God_pk_dict,T,Match_god_list)	
			end;
		true->
			get_match_god_list_sea(Mod,Now_time,God_a,God_pk_dict,T,Match_god_list)	
	end.
%%小组赛随机名单条件
get_match_god_list_group(_Mod,_Now_time,_God_a,_God_pk_dict,_God_dict,[],Match_god_list)->Match_god_list;
get_match_god_list_group(Mod,Now_time,God_a,God_pk_dict,God_dict,[{Flat,Server_id,Id}|T],Match_god_list)->
	V = dict:fetch({Flat,Server_id,Id}, God_dict),
	Time_gap = Now_time - V#god.last_out_war_time,
	Last_out_war_time = data_god:get(last_out_war_time),
	Check_max_loop_v = is_max_loop(Mod,V),
	if
		God_a#god.flat=:=V#god.flat 
		  andalso God_a#god.server_id=:=V#god.server_id
		  andalso God_a#god.id=:=V#god.id->
		  	get_match_god_list_group(Mod,Now_time,God_a,God_pk_dict,God_dict,T,Match_god_list++[V]);
		Time_gap>Last_out_war_time andalso V#god.is_in =:= 1 andalso Check_max_loop_v=:=false->
			%%判断是否有历史战斗记录
			Flag_a = dict:is_key({God_a#god.flat,God_a#god.server_id,God_a#god.id,
								  V#god.flat,V#god.server_id,V#god.id,0},God_pk_dict),
			Flag_b = dict:is_key({V#god.flat,V#god.server_id,V#god.id,
								  God_a#god.flat,God_a#god.server_id,God_a#god.id,0},God_pk_dict),
			case Flag_a orelse Flag_b of
				false->get_match_god_list_group(Mod,Now_time,God_a,God_pk_dict,God_dict,T,Match_god_list++[V]);
				true->get_match_god_list_group(Mod,Now_time,God_a,God_pk_dict,God_dict,T,Match_god_list)
			end;
		true->
			get_match_god_list_group(Mod,Now_time,God_a,God_pk_dict,God_dict,T,Match_god_list)
	end.
	
%%从房间人员列表中剔除
%% @return New_State
remove_room(Plat,Server_id,Id,State)->
	if
		State#god_state.mod=:=1 orelse State#god_state.mod=:=3->%%海选赛、复活赛需要这样
			God_room_dict_list = dict:to_list(State#god_state.god_room_dict),
			case remove_room_sub(Plat,Server_id,Id,God_room_dict_list) of
				{ok,{SceneId,Room_no}}->
					God_room = dict:fetch({SceneId,Room_no}, State#god_state.god_room_dict),
					New_God_room = God_room#god_room{
						player_list = lists:delete({Plat,Server_id,Id}, God_room#god_room.player_list)								 
					},
					New_State = State#god_state{
						god_room_dict = dict:store({SceneId,Room_no}, New_God_room, State#god_state.god_room_dict)							
					},
					New_State;
				_->
					State
			end;
		true->
			State
	end.
remove_room_sub(_Plat,_Server_id,_Id,[])->{error,0};
remove_room_sub(Plat,Server_id,Id,[{{SceneId,Room_no},V}|T])->
	Player_list = V#god_room.player_list,
	Flag = lists:member({Plat,Server_id,Id}, Player_list),
	case Flag of
		false->
			remove_room_sub(Plat,Server_id,Id,T);
		true->
			{ok,{SceneId,Room_no}}
	end.

%%参赛次数添加一次
%% @param God #god{}
%% @param Mod 赛事
%% @return {胜利的次数,参与的次数,对应积分}
get_loop_score(God,Mod)->
	case Mod of
		1->
			{God#god.sea_win_loop,God#god.sea_loop,God#god.sea_score};
		2->
			{God#god.group_win_loop,God#god.group_loop,God#god.group_score};
		3->
			{God#god.relive_win_loop,God#god.relive_loop,God#god.relive_score};
		4->
			{God#god.sort_win_loop,God#god.sort_loop,God#god.sort_score};
		_->
			{0,0,0}
	end.

%%参赛次数添加一次
%% @param God #god{}
%% @param Mod 赛事
%% @param Add_win_loop 添加胜利的次数
%% @param Add_loop 添加的次数
%% @return #god{}
add_loop(God,Mod,Add_win_loop,Add_loop)->
	case Mod of
		1->
			God#god{
				sea_win_loop=God#god.sea_win_loop+Add_win_loop,
				sea_loop=God#god.sea_loop+Add_loop
			};
		2->
			God#god{
				group_win_loop=God#god.group_win_loop+Add_win_loop,					
				group_loop=God#god.group_loop+Add_loop
			};
		3->
			God#god{
				relive_win_loop=God#god.relive_win_loop+Add_win_loop,
				relive_loop=God#god.relive_loop+Add_loop
			};
		4->
			God#god{
				sort_win_loop=God#god.sort_win_loop+Add_win_loop,
				sort_loop=God#god.sort_loop+Add_loop
			};
		_->
			God
	end.

%%添加积分
add_score(God,Mod,AddScore)->
	case Mod of
		1->
			God#god{
				sea_score=God#god.sea_score+AddScore
			};
		2->
			God#god{
				group_score=God#god.group_score+AddScore
			};
		3->
			God#god{
				relive_score=God#god.relive_score+AddScore
			};
		4->
			God#god{
				sort_score=God#god.sort_score+AddScore
			};
		_->
			God
	end.

%%总决赛专用
goin_sub_sort(From,Node,Plat,Server_id,Id,Name,Lv,Combat_power,Hightest_combat_power,State)->
	%% 1.构造或取出玩家记录
	case dict:is_key({Plat,Server_id,Id}, State#god_state.god_dict) of
		false-> %%无玩家记录
			Result = 5,
			New_State = State;
		true-> %%有玩家记录
			God = dict:fetch({Plat,Server_id,Id}, State#god_state.god_dict),
			if
				God#god.group_relive_is_up /= 1-> %%晋级了方有资格
					Result = 5,
					New_God = God#god{
						is_in = 0			  
					};
				true->
					Sort_max_loop = data_god:get(sort_max_loop),
					if
						Sort_max_loop=<God#god.sort_loop->%%超出允许参与次数
							Result = 6,
							New_God = God#god{
								is_in = 0			  
							};
						true->
							Result = 1,
							New_God = God#god{
								node = Node,									  
								name = Name,										   
								lv = Lv,									
								power = Combat_power,							
								high_power = max(Combat_power,Hightest_combat_power),					
								is_in = 1,
								last_out_war_time = util:unixtime()			  
							}
					end
			end,
			New_State = State#god_state{
				god_dict = dict:store({Plat,Server_id,Id}, New_God, State#god_state.god_dict)
			}
	end,
	if
		Result =:= 1->
			%%切换场景
			Scene_id1 = lists:nth(1, (data_god:get(scene_id1))),
			[X1,Y1] = data_god:get_position1(),
			mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,
										   [Id,Scene_id1,0,X1,Y1,0]);
		true->
			case From of
				war-> %%从战场回来，需要丢回长安
					[Scene_id,X,Y] = data_god:get(leave_scene),
					mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,
										   [Id,Scene_id,0,X,Y,0]);
				_-> %%从其他地方回来，不做处理
					void
			end
	end,
	{Result,New_State}.

%%复活赛专用
goin_sub_relive(From,Node,Plat,Server_id,Id,Name,Lv,Combat_power,Hightest_combat_power,State)->
	%% 1.构造或取出玩家记录
	case dict:is_key({Plat,Server_id,Id}, State#god_state.god_dict) of
		false-> %%无DB记录无资格
			Result = 3,
			New_God = #god{};
		true-> %%有记录
			God = dict:fetch({Plat,Server_id,Id}, State#god_state.god_dict),
			if
				God#god.group_relive_is_up =:= 1-> %%已经晋级无资格
					Result = 4,
					New_God = God#god{
						is_in = 0			  
					};
				true-> %%还未晋级
					Relive_max_loop = data_god:get(relive_max_loop),
					if
						Relive_max_loop=<God#god.relive_loop->%%超出允许参与次数
							Result = 6,
							New_God = God#god{
								is_in = 0			  
							};
						true->
							Result = 1,
							New_God = God#god{
								node = Node,											  
								name = Name,										   
								lv = Lv,									
								power = Combat_power,							
								high_power = max(Combat_power,Hightest_combat_power),					
								is_in = 1,
								last_out_war_time = util:unixtime()									   
							}
					end
			end
	end,
	if
		Result =:= 1->%%成功
			%% 2.找出人口最少的房间,并把人丢进对应房间
			case look_min_room(State#god_state.god_room_dict) of
				{ok,{{Temp_Scene_id,Match_Room_no},Match_God_room}}-> %%进指定房间
					Scene_id1 = Temp_Scene_id,
					CopyId = Match_Room_no,
					New_God_room = Match_God_room#god_room{
						player_list = Match_God_room#god_room.player_list ++ [{Plat,Server_id,Id}]
					},
					F_New_God = New_God#god{
						room_no = Match_Room_no						
					},
					New_State = State#god_state{
						god_dict = dict:store({Plat,Server_id,Id}, F_New_God, State#god_state.god_dict),												
						god_room_dict = dict:store({Scene_id1,Match_Room_no}, New_God_room, State#god_state.god_room_dict)						
					};
				_->%%新建房间
					Scene_id1 = lists:nth(1, (data_god:get(scene_id1))),
					New_max_room_no = State#god_state.max_room_no + 1,
					CopyId = New_max_room_no,
					New_God_room = #god_room{
						scene_id = Scene_id1, 											 
						id = New_max_room_no,
						player_list = [{Plat,Server_id,Id}]					
					},
					F_New_God = New_God#god{
						room_no = New_max_room_no						
					},
					New_State = State#god_state{
						max_room_no = New_max_room_no,	
						god_dict = dict:store({Plat,Server_id,Id}, F_New_God, State#god_state.god_dict),									
						god_room_dict = dict:store({Scene_id1,New_max_room_no}, New_God_room, State#god_state.god_room_dict)						
					}
			end,
			%%切换场景
			[X,Y] = data_god:get_position1(),
			mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,
										   [Id,Scene_id1,CopyId,X,Y,0]);
		true-> %%不成功
			case From of
				war-> %%从战场回来，需要丢回长安
					[Scene_id,X,Y] = data_god:get(leave_scene),
					mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,
										   [Id,Scene_id,0,X,Y,0]);
				_-> %%从其他地方回来，不做处理
					void
			end,
			New_State = State
	end,
	{Result,New_State}.

%%小组赛专用
goin_sub_group(From,Node,Plat,Server_id,Id,Name,Lv,Combat_power,Hightest_combat_power,State)->
	%% 1.构造或取出玩家记录
	case dict:is_key({Plat,Server_id,Id}, State#god_state.god_dict) of
		false-> %%无记录，不可以参赛
			Result = 7,
			Room_no = 0,
			New_State = State;
		true-> 
			God = dict:fetch({Plat,Server_id,Id}, State#god_state.god_dict),
			Group_max_loop = data_god:get(group_max_loop),
			if
				Group_max_loop =<God#god.group_loop->%%超出允许参与次数
					Result = 6,
					Room_no = 0,
					New_God = God#god{
						is_in = 0			  
					};
				true->
					Result = 1,
					Room_no = God#god.room_no,
					New_God = God#god{
						node = Node,													  
						name = Name,									  
						lv = Lv,									
						power = Combat_power,							
						high_power = max(Combat_power,Hightest_combat_power),					
						is_in = 1,
						last_out_war_time = util:unixtime()										   
					}		
			end,
			New_State = State#god_state{
				god_dict = dict:store({Plat,Server_id,Id}, New_God, State#god_state.god_dict)
			}
	end,
	if
		Result =:= 1->
			%%切换场景
			Scene_id1 = lists:nth(1, (data_god:get(scene_id1))),
			[X,Y] = data_god:get_position1(),
			mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,
										   [Id,Scene_id1,Room_no,X,Y,0]);
		true->
			case From of
				war-> %%从战场回来，需要丢回长安
					[Scene_id,X,Y] = data_god:get(leave_scene),
					mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,
										   [Id,Scene_id,0,X,Y,0]);
				_-> %%从其他地方回来，不做处理
					void
			end
	end,
	{Result,New_State}.

%%海选赛专用
goin_sub_sea(From,Node,Plat,Server_id,Id,God_no,Name,Country,Sex,Carrer,
			 Image,Lv,Combat_power,Hightest_combat_power,State)->
	%% 1.构造或取出玩家记录
	case dict:is_key({Plat,Server_id,Id}, State#god_state.god_dict) of
		false-> %%无记录，可以参赛
			Result = 1,
			New_God = #god{
				flat = Plat,							
				server_id = Server_id,         
				id = Id,									
				god_no = God_no,     
				name = Name,							
				country = Country,						
				sex = Sex,								
				carrer = Carrer,							
				image = Image,							
				lv = Lv,									
				power = Combat_power,							
				high_power = max(Combat_power,Hightest_combat_power),	
				node = Node,		
				is_in = 1,										   
				is_db = 0,
				last_out_war_time = util:unixtime()								
			};
		true-> %%有记录
			God = dict:fetch({Plat,Server_id,Id}, State#god_state.god_dict),
			if
				God#god.is_db =:= 1-> %% 已入库记录，已经晋级
					Result = 2,
					New_God = God#god{
						is_in = 0				  
					};
				true-> %%本场比赛记录
					Sea_max_loop = data_god:get(sea_max_loop),
					if
						Sea_max_loop=<God#god.sea_loop->%%超出允许参与次数
							Result = 6,
							New_God = God#god{
								is_in = 0				  
							};
						true->
							Result = 1,
							New_God = God#god{
								node = Node,
								name = Name,										   
								lv = Lv,									
								power = Combat_power,							
								high_power = max(Combat_power,Hightest_combat_power),				
								is_in = 1,
								last_out_war_time = util:unixtime()									   
							}
					end
			end
	end,
	if
		Result =:= 1->%%成功
			%% 2.找出人口最少的房间,并把人丢进对应房间
			case look_min_room(State#god_state.god_room_dict) of
				{ok,{{Temp_Scene_id1,Match_Room_no},Match_God_room}}-> %%进指定房间
					Scene_id1 = Temp_Scene_id1,
					CopyId = Match_Room_no,
					New_God_room = Match_God_room#god_room{
						player_list = Match_God_room#god_room.player_list ++ [{Plat,Server_id,Id}]
					},
					F_New_God = New_God#god{
						room_no = Match_Room_no						
					},
					New_State = State#god_state{
						god_dict = dict:store({Plat,Server_id,Id}, F_New_God, State#god_state.god_dict),
						god_room_dict = dict:store({Scene_id1,Match_Room_no}, New_God_room, State#god_state.god_room_dict)						
					};
				_->%%新建房间
					Scene_id1 = util:list_rand(data_god:get(scene_id1)),
					New_max_room_no = State#god_state.max_room_no + 1,
					CopyId = New_max_room_no,
					New_God_room = #god_room{
						scene_id = Scene_id1,										 
						id = New_max_room_no,
						player_list = [{Plat,Server_id,Id}]					
					},
					F_New_God = New_God#god{
						room_no = New_max_room_no						
					},
					New_State = State#god_state{
						max_room_no = New_max_room_no,										
						god_dict = dict:store({Plat,Server_id,Id}, F_New_God, State#god_state.god_dict),
						god_room_dict = dict:store({Scene_id1,New_max_room_no}, New_God_room, State#god_state.god_room_dict)						
					}
			end,
			%%切换场景
			[X,Y] = data_god:get_position1(),
			mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,
										   [Id,Scene_id1,CopyId,X,Y,0]);
		true-> %%不成功
			case From of
				war-> %%从战场回来，需要丢回长安
					[Scene_id,X,Y] = data_god:get(leave_scene),
					mod_clusters_center:apply_cast(Node,lib_scene,player_change_scene_queue,
										   [Id,Scene_id,0,X,Y,0]);
				_-> %%从其他地方回来，不做处理
					void
			end,
			New_State = State
	end,
	{Result,New_State}.
	
%%只提供给海选赛、复活赛，小组赛、总决赛有固定房间。
look_min_room(God_room_dict)->
	God_room_dict_list = dict:to_list(God_room_dict),
	Sort_God_room_dict_list = lists:sort(fun({_K_a,God_room_a},{_K_b,God_room_b})-> 
		Num_a = length(God_room_a#god_room.player_list),
		Num_b = length(God_room_b#god_room.player_list),
		if
			Num_a=<Num_b->true;
			true->false
		end
	end,God_room_dict_list),
	if
		length(Sort_God_room_dict_list)=<0-> %%无记录
			{error,no_match};
		true-> %%有记录
			{_K,God_room} = lists:nth(1, Sort_God_room_dict_list),
			Min_num = length(God_room#god_room.player_list),
			Max_room_num = data_god:get(max_room_num),
			if
				Min_num >= Max_room_num-> %%最小房间已满员
					{error,no_match};
				true-> %%有未满员房间
					%%合适列表，随机一个合适房间
					Match_list = look_min_room_sub(Sort_God_room_dict_list,Min_num,[]),
					N = util:rand(1,length(Match_list)),
					{ok,lists:nth(N, Match_list)}
			end
	end.
look_min_room_sub([],_Min_num,ResultList)->ResultList;
look_min_room_sub([{_K,God_room}|T],Min_num,ResultList)->
	Num = length(God_room#god_room.player_list),
	if
		Num =:= Min_num ->
			look_min_room_sub(T,Min_num,ResultList ++ [{_K,God_room}]);
		true->
			ResultList
	end.

%%检测是否已经到最大参与场次了
is_max_loop(Mod,God)->
	Max_loop = data_god:get_max_loop(Mod),
	case Mod of
		1->
			God#god.sea_loop>=Max_loop;
		2->
			God#god.group_loop>=Max_loop;
		3->
			God#god.relive_loop>=Max_loop;
		4->
			God#god.sort_loop>=Max_loop;
		_->
			true
	end.

%%生成小组赛房间
%%@param God_room_dict
%%@return New_God_room_dict
make_group_room([],God_dict,God_room_dict)->{God_dict,God_room_dict};
make_group_room([{K,V}|T],God_dict,God_room_dict)->
	Scene_id1 = lists:nth(1,data_god:get(scene_id1)),
	New_V = V#god{
		room_no = V#god.group_room_no
	},
	Room_no = V#god.group_room_no,
	case dict:is_key({Scene_id1,Room_no}, God_room_dict) of
		false->
			New_god_room = #god_room{
				scene_id = Scene_id1,									 
				id = Room_no,
				player_list = [{V#god.flat,V#god.server_id,V#god.id}]						 
			};
		true->
			God_room = dict:fetch({Scene_id1,Room_no}, God_room_dict),
			New_god_room = God_room#god_room{
				player_list = God_room#god_room.player_list ++ [{V#god.flat,V#god.server_id,V#god.id}]							 
			}
	end,
	make_group_room(T,
					dict:store(K, New_V, God_dict),
					dict:store({Scene_id1,Room_no}, New_god_room, God_room_dict)).
