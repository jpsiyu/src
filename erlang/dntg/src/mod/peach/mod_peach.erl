%%% -------------------------------------------------------------------
%%% Author  : zengzhaoyuan
%%% Description :
%%%
%%% Created : 2012-5-22
%%% -------------------------------------------------------------------
-module(mod_peach).
-behaviour(gen_server).
-include("peach.hrl").
-include("server.hrl").
-include("unite.hrl").
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([set_time/3,
		 set_status/1,
		 get_status/0,
		 get_peach/1,
		 room_list/0,
		 score_list/1,
		 enter_room/2,
		 open_peach/0,
		 end_peach/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

-record(state, {
				peach_stauts=0,  					% 蟠桃园状态 0还未开启  1开启中 2当天已结束
				config_begin_hour=0,
				config_begin_minute=0,
				loop_time=0,
				peach_room_max_id=0, 				% 蟠桃园房间自增长ID
				peach_room_dict = dict:new(), 		% 房间字典表 (Key:房间Id，Value:房间记录)
				peach_dict = dict:new()     		% 玩家记录 (Key:玩家Id， Value:玩家记录)
}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

%% ====================================================================
%% Server functions
%% ====================================================================
%%设置蟠桃园时间(不方法不可随便调用，会重置所有属性，很危险)
set_time(Config_Begin_Hour,Config_Begin_Minute,Loop_time)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_time,Config_Begin_Hour,Config_Begin_Minute,Loop_time}).

%%设置状态
%%@param Peach_Status 蟠桃园状态 0还未开启  1开启中 2当天已结束
set_status(Peach_Status)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_status,Peach_Status}).

%%获取状态
%% @return int 蟠桃园状态 0还未开启  1开启中 2当天已结束
get_status()->
	gen_server:call(misc:get_global_pid(?MODULE),{get_status}).

%%获取玩家所处副本排名第一的Uid
%% @param Uid 玩家Uid
%% @return 排名第一的玩家Id（返回0,查不到玩家）
get_no1_uid(Uid)->
	gen_server:call(misc:get_global_pid(?MODULE),{get_no1_uid,Uid}).

%%获取玩家蟠桃园记录
%% @param Uid 玩家Uid
%% @return {ok,#peach}|{error,Reson}
get_peach(Uid)->
	gen_server:call(misc:get_global_pid(?MODULE),{get_peach,Uid}).

%% 设置玩家积分
%%@param Type 原子值,player|npc
%%@param Uid 谁杀的玩家ID
%%@param KilledTypeId 被杀类型ID(player时，取玩家ID值，npc时，取其类型ID)
set_score(Type,Uid,KilledUidOrNPCTypeId)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_score,Type,Uid,KilledUidOrNPCTypeId}).

%% 获取房间列表
%% @return [{RoomId,Num}]  {房间Id,房间人口}
room_list()->
	gen_server:call(misc:get_global_pid(?MODULE),{room_list}).

%% 查看积分榜
%% @param Uid 玩家Id
%% @return [Score,Anger,Top5List]
score_list(Uid)->
	gen_server:cast(misc:get_global_pid(?MODULE),{score_list,Uid}).

%% 进入房间
%% @param UniteStatus #unite_status
%% @param RoomId 房间ID
%% @return [Result,Rest_time] 
enter_room(UniteStatus,RoomId)->
	gen_server:call(misc:get_global_pid(?MODULE),{enter_room,UniteStatus,RoomId}).

%%开启蟠桃园
open_peach()->
	gen_server:cast(misc:get_global_pid(?MODULE),{open_peach}).

%%蟠桃园结束时处理逻辑
end_peach(Config_Begin_Hour,Config_Begin_Minute,Loop_time)->
	gen_server:cast(misc:get_global_pid(?MODULE),{end_peach,Config_Begin_Hour,Config_Begin_Minute,Loop_time}).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_call({get_status}, _From, State) ->
    Reply = State#state.peach_stauts,
    {reply, Reply, State};

handle_call({get_no1_uid,Uid}, _From, State) ->
	case dict:is_key(Uid, State#state.peach_dict) of
		false->Reply = 0; %%没玩家对应记录
		true->
			Peach = dict:fetch(Uid, State#state.peach_dict),
			case Peach#peach.room_id of
				0->Reply = 0;
				_->
					Peach_List = dict:to_list(State#state.peach_dict),
					Same_Copy_Peach_List = [P||{_K,P}<-Peach_List,
											   P#peach.room_id=:=Peach#peach.room_id],
					Sort_List = lists:sort(fun(A,B)->
						A_Score = A#peach.acquisition + A#peach.plunder - A#peach.robbed,
						B_Score = B#peach.acquisition + B#peach.plunder - B#peach.robbed,
						if
							B_Score =< A_Score -> true;
							true -> false
						end
					end, Same_Copy_Peach_List),
					if
						0<length(Sort_List)->
							No1_Peach = lists:nth(1, Sort_List),
							Reply = No1_Peach#peach.id;
						true->Reply = 0
					end
			end
	end,
    {reply, Reply, State};

handle_call({get_peach,Uid}, _From, State) ->
	case dict:is_key(Uid, State#state.peach_dict) of
		false->Reply = {error,no_record};
		true->
			Peach = dict:fetch(Uid, State#state.peach_dict),
			Reply = {ok,Peach}
	end,
    {reply, Reply, State};

handle_call({room_list}, _From, State) ->
	Scene_id = data_peach:get_peach_config(scene_id),
	Mon_id = data_peach:get_peach_config(mon_id),
	Peach_room_max_id = State#state.peach_room_max_id,
	Peach_room_dict_List = dict:to_list(State#state.peach_room_dict),
	case Peach_room_dict_List of
		[]-> %%没有房间
			New_Peach_room_max_id = Peach_room_max_id+1,
            lib_mon:clear_scene_mon_by_mids(Scene_id, New_Peach_room_max_id, 1, [Mon_id]),
    		mod_scene_agent:apply_call(Scene_id, mod_scene, copy_dungeon_scene, [Scene_id, New_Peach_room_max_id, 0, 0]),
			Peach_room = #peach_room{
				id=New_Peach_room_max_id, 		%房间ID
				num = 0 	%房间人口			
			},
			New_Peach_room_dict = dict:store(New_Peach_room_max_id, Peach_room, State#state.peach_room_dict),
			New_State = State#state{
				peach_room_max_id=New_Peach_room_max_id,
				peach_room_dict=New_Peach_room_dict
			};
		_-> %%有房间
			Sum_room = length(Peach_room_dict_List),
			Sum_peach = sum_peach(Peach_room_dict_List,0),
			Room_new_num = data_peach:get_peach_config(room_new_num),
			if
				Room_new_num =< Sum_peach/Sum_room -> %%超出新建房间标准
					New_Peach_room_max_id = Peach_room_max_id+1,
                    lib_mon:clear_scene_mon_by_mids(Scene_id, New_Peach_room_max_id, 1, [Mon_id]),
    				mod_scene_agent:apply_call(Scene_id, mod_scene, copy_dungeon_scene, [Scene_id, New_Peach_room_max_id, 0, 0]),
					Peach_room = #peach_room{
						id=New_Peach_room_max_id, 		%房间ID
						num = 0 	%房间人口			
					},
					New_Peach_room_dict = dict:store(New_Peach_room_max_id, Peach_room, State#state.peach_room_dict),
					New_State = State#state{
						peach_room_max_id=New_Peach_room_max_id,
						peach_room_dict=New_Peach_room_dict
					};
				true-> %未超出新建房间要求
					New_State = State
			end
	end,
	New_Peach_room_dict_List = dict:to_list(New_State#state.peach_room_dict),
	Temp_RoomList = [{V#peach_room.id,V#peach_room.num}||{_K,V}<-New_Peach_room_dict_List],
	RoomList = lists:sort(fun({A_id,_A_num},{B_id,_B_num})-> 
		if
			A_id=<B_id->true;
			true->false
		end
	end, Temp_RoomList),
	
    {reply, RoomList, New_State};  

handle_call({enter_room,UniteStatus,RoomId}, _From, State) ->
	if
		RoomId =:=0 orelse State#state.peach_room_max_id<RoomId -> %不合法房间号
			Result = 3,Rest_time = 0,
			New_State = State,
			Reply = [Result,Rest_time];
		true-> %合法房间号
			Peach_room_dict = State#state.peach_room_dict,
			case dict:is_key(RoomId, Peach_room_dict) of
				false-> % 不存在房间号
					Result = 3,Rest_time = 0,
					New_State = State,
					Reply = [Result,Rest_time];
				true-> %合法房间号
					Peach_room = dict:fetch(RoomId, Peach_room_dict),
					Room_max_num = data_peach:get_peach_config(room_max_num),
					if
						Room_max_num=<Peach_room#peach_room.num-> %%满员房间
							Result = 4,Rest_time = 0,
							New_State = State,
							Reply = [Result,Rest_time];
						true-> %% 房间未满员
							case lib_player:get_player_info(UniteStatus#unite_status.id, pk) of
								false-> Pk_status = 2;
								Pk -> Pk_status = Pk#status_pk.pk_status
							end,
							case dict:is_key(UniteStatus#unite_status.id, State#state.peach_dict) of
								false-> %%无对应玩家记录
									New_Peach_room = Peach_room#peach_room{
										num=Peach_room#peach_room.num+1
									},
									New_Peach = #peach{
										id=UniteStatus#unite_status.id, 					% 玩家ID
										nickname=UniteStatus#unite_status.name, 			% 玩家昵称
										contry = UniteStatus#unite_status.realm, 			% 玩家国家
										sex = UniteStatus#unite_status.sex,					% 性别
										career = UniteStatus#unite_status.career,			% 职业
										image = UniteStatus#unite_status.image,				% 头像
										lv = UniteStatus#unite_status.lv, 					% 玩家等级
										pk_status = Pk_status,								% pk状态
										room_id=RoomId, 									% 房间ID
										acquisition = 0,  									% 蟠桃采集数
										plunder = 0,										% 蟠桃掠夺数
										robbed = 0   
									},
									New_Peach_room_dict = dict:store(RoomId, New_Peach_room, Peach_room_dict),
									New_Peach_dict = dict:store(UniteStatus#unite_status.id, New_Peach, State#state.peach_dict);
								true-> %%有对应玩家记录
									Peach = dict:fetch(UniteStatus#unite_status.id, State#state.peach_dict),
									Peach_num = Peach#peach.acquisition+Peach#peach.plunder-Peach#peach.robbed,
									Enter_plus_peach = data_peach:get_enter_plus_peach(Peach_num),
									New_Peach = Peach#peach{
										acquisition = Peach#peach.acquisition - Enter_plus_peach,					
										pk_status = Pk_status,
										room_id = RoomId	% 更改房间号				
									},
									if
										Peach#peach.room_id =:= RoomId -> % 同一房间
											New_Peach_room_dict = Peach_room_dict;
										true-> % 与上次房间不同房间
											case dict:is_key(Peach#peach.room_id, State#state.peach_room_dict) of
												false-> %% 没有历史房间
													New_Peach_room_dict = Peach_room_dict;
												true-> %% 有历史房间
													Temp_Peach_room = dict:fetch(Peach#peach.room_id, State#state.peach_room_dict),
													if
														(Temp_Peach_room#peach_room.num - 1) < 0 -> New_Temp_Peach_room_Num = 0;
														true->New_Temp_Peach_room_Num = (Temp_Peach_room#peach_room.num - 1)
													end,
													New_Temp_Peach_room = Temp_Peach_room#peach_room{
														num = New_Temp_Peach_room_Num
													},
													New_Peach_room_dict1 = dict:store(Peach#peach.room_id, New_Temp_Peach_room, Peach_room_dict),
													New_Peach_room = Peach_room#peach_room{
														num=Peach_room#peach_room.num+1 
													},
													New_Peach_room_dict = dict:store(RoomId, New_Peach_room, New_Peach_room_dict1)
											end
									end,
									New_Peach_dict = dict:store(UniteStatus#unite_status.id, New_Peach, State#state.peach_dict)
							end,
							New_State = State#state{
								peach_room_dict = New_Peach_room_dict,
								peach_dict = New_Peach_dict					
							},
							%%剩余时间
							{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
							NowTime = (Hour*60+Minute)*60+Second,
							Config_End = (State#state.config_begin_hour*60 + 
											State#state.config_begin_minute +
											State#state.loop_time)*60,
							if
								Config_End-NowTime<0->Rest_time = 0;
								true->Rest_time = Config_End-NowTime
							end,
							%%更新场景蟠桃数
							Scene_id = data_peach:get_peach_config(scene_id),
							My_Peach_Num = New_Peach#peach.acquisition+New_Peach#peach.plunder-New_Peach#peach.robbed,
							mod_scene_agent:update(peach, [New_Peach#peach.id,Scene_id,My_Peach_Num]),
							Reply = [1,Rest_time]
					end
			end
	end,
	
    {reply, Reply, New_State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({set_time,Config_Begin_Hour,Config_Begin_Minute,Loop_time}, State) ->
	NewState = set_time_sub(Config_Begin_Hour,Config_Begin_Minute,Loop_time,State),
	{noreply, NewState};

handle_cast({score_list,PlayerId},State) ->
	case dict:is_key(PlayerId, State#state.peach_dict) of
		false-> % 无玩家记录
			Score=0,Anger=0,Top5List=[],Acquisition=0,Plunder=0,Robbed=0;
		true-> % 有玩家记录
			Peach = dict:fetch(PlayerId, State#state.peach_dict),
			Room_id = Peach#peach.room_id,
			Peach_List = dict:to_list(State#state.peach_dict),
			SameRoom_Peach_List = [V||{_K,V}<-Peach_List,V#peach.room_id=:=Room_id],
			Sort_SameRoom_Peach_List = lists:sort(fun(A,B)-> 
				A_Score = A#peach.acquisition + A#peach.plunder - A#peach.robbed,
				B_Score = B#peach.acquisition + B#peach.plunder - B#peach.robbed,
				if
					B_Score =< A_Score -> true;
					true -> false
				end
			end, SameRoom_Peach_List),
			if
				5<length(Sort_SameRoom_Peach_List) ->
					{_Sort_SameRoom_Peach_List,_} = lists:split(5, Sort_SameRoom_Peach_List);
				true->
					_Sort_SameRoom_Peach_List = Sort_SameRoom_Peach_List
			end,
			Score=Peach#peach.acquisition + Peach#peach.plunder - Peach#peach.robbed,
			Acquisition=Peach#peach.acquisition,
			Plunder=Peach#peach.plunder,
			Robbed=Peach#peach.robbed,
			Anger=0,
			Top5List = [{R#peach.nickname,
						 R#peach.acquisition + R#peach.plunder - R#peach.robbed,
						 R#peach.id}||R<-Sort_SameRoom_Peach_List]
	end,
	{ok, BinData} = pt_481:write(48104, [Score,Anger,Top5List,Acquisition,Plunder,Robbed]),
	lib_unite_send:send_to_uid(PlayerId, BinData),
    {noreply, State};

handle_cast({set_status,Peach_Status}, State) ->
	case Peach_Status of
		0->
			NewState = State#state{
					  config_begin_hour=State#state.config_begin_hour,
					  config_begin_minute=State#state.config_begin_minute,
					  loop_time=State#state.loop_time,
					  peach_stauts=Peach_Status
			};
		_->NewState = State#state{peach_stauts=Peach_Status}
	end,
	{noreply, NewState};

handle_cast({set_score,Type,Uid,KilledUidOrNPCTypeId}, State) ->
	if
		State#state.peach_stauts=:=1->
			Scene_id = data_peach:get_peach_config(scene_id),
			case Type of
				player-> %掠夺
					case dict:is_key(Uid, State#state.peach_dict) 
						andalso dict:is_key(KilledUidOrNPCTypeId, State#state.peach_dict) of
						false-> %有一方无记录，作废
							NewState = State;
						true-> % 均有记录
							Uid_Peach = dict:fetch(Uid, State#state.peach_dict),
							Killed_Peach = dict:fetch(KilledUidOrNPCTypeId, State#state.peach_dict),
							Killed_Peach_Num = Killed_Peach#peach.acquisition+Killed_Peach#peach.plunder-Killed_Peach#peach.robbed,
							Robbed_num = data_peach:get_robbed_num_when_killed(Killed_Peach_Num),
							New_Uid_Peach = Uid_Peach#peach{ %掠夺
								plunder = Uid_Peach#peach.plunder + Robbed_num 
							},
							New_Killed_Peach = Killed_Peach#peach{ %被掠夺
								robbed = Killed_Peach#peach.robbed + util:floor(Robbed_num*1.3)								  
							},
							% 当前蟠桃数 (获得蟠桃传闻)
							My_Peach_Num = New_Uid_Peach#peach.acquisition+New_Uid_Peach#peach.plunder-New_Uid_Peach#peach.robbed,
							if
								50=<My_Peach_Num andalso (My_Peach_Num rem 10 =:= 0)-> %20以上，每10个传闻一次
									%%发送传闻
									lib_chat:send_TV({scene,Scene_id,Uid_Peach#peach.room_id},1,2,
													 [getpantao,
													  My_Peach_Num,
													  New_Uid_Peach#peach.id,
													  New_Uid_Peach#peach.contry,
													  New_Uid_Peach#peach.nickname,
													  New_Uid_Peach#peach.sex,
													  New_Uid_Peach#peach.career,
													  New_Uid_Peach#peach.image]);
								true->void
							end,
							% 击杀掠夺70以上蟠桃传闻
%% 							if
%% 								70=<Killed_Peach_Num->
%% 									%%发送传闻
%% 									lib_chat:send_TV({scene,Scene_id,Uid_Peach#peach.room_id},1,2,
%% 													 [robpantao,
%% 													  Robbed_num,
%% 													  New_Uid_Peach#peach.id,
%% 													  New_Uid_Peach#peach.contry,
%% 													  New_Uid_Peach#peach.nickname,
%% 													  New_Uid_Peach#peach.sex,
%% 													  New_Uid_Peach#peach.career,
%% 													  New_Uid_Peach#peach.image,
%% 													  New_Killed_Peach#peach.id,
%% 													  New_Killed_Peach#peach.contry,
%% 													  New_Killed_Peach#peach.nickname,
%% 													  New_Killed_Peach#peach.sex,
%% 													  New_Killed_Peach#peach.career,
%% 													  New_Killed_Peach#peach.image]);
%% 								true->void
%% 							end,
							if
								0<Robbed_num->
									%%更新场景蟠桃数
									mod_scene_agent:update(peach, [Uid,Scene_id,My_Peach_Num]),
									mod_scene_agent:update(peach, [KilledUidOrNPCTypeId,Scene_id,Killed_Peach_Num-Robbed_num]);
								true->void
							end,
							New_Peach_dict1 = dict:store(Uid, New_Uid_Peach, State#state.peach_dict),
							New_Peach_dict = dict:store(KilledUidOrNPCTypeId, New_Killed_Peach, New_Peach_dict1),
							NewState = State#state{
								peach_dict = New_Peach_dict				   
							}
					end;
				npc-> %采集
					case dict:is_key(Uid, State#state.peach_dict) of
						false-> %无记录，作废
							NewState = State;
						true-> % 有记录
							Uid_Peach = dict:fetch(Uid, State#state.peach_dict),
							Mon_id = data_peach:get_peach_config(mon_id),
							Mon_sw_id = data_peach:get_peach_config(mon_sw_id),
							case KilledUidOrNPCTypeId of
								Mon_id->% 采集怪
									Uid_Peach_Num = Uid_Peach#peach.acquisition+Uid_Peach#peach.plunder-Uid_Peach#peach.robbed,
									Cj_peach_max = data_peach:get_peach_config(cj_peach_max),
									if
										Uid_Peach_Num<Cj_peach_max->
											Acquisition = data_peach:get_peach_config(mon_score);
										true->
											Acquisition = 0
									end;
								Mon_sw_id-> % 蟠桃侍卫
									Kill_sw_rate = data_peach:get_peach_config(kill_sw_rate),
									Kill_sw_score = data_peach:get_peach_config(kill_sw_score),
									SW_Rate = util:rand(1, 100),
									if
										SW_Rate =< Kill_sw_rate ->
											Acquisition = Kill_sw_score;
										true->
											Acquisition = 0
									end;
								_->
									Acquisition = 0
							end,
							New_Uid_Peach = Uid_Peach#peach{ %采集
								acquisition = Uid_Peach#peach.acquisition + Acquisition
							},
							% 当前蟠桃数 (获得蟠桃传闻)
							My_Peach_Num = New_Uid_Peach#peach.acquisition+New_Uid_Peach#peach.plunder-New_Uid_Peach#peach.robbed,
							if
								0<Acquisition andalso 20=<My_Peach_Num 
								  andalso (My_Peach_Num rem 10 =:= 0)-> %20以上，每10个传闻一次
									%%发送传闻
									lib_chat:send_TV({scene,Scene_id,Uid_Peach#peach.room_id},1,2,
													 [getpantao,
													  My_Peach_Num,
													  New_Uid_Peach#peach.id,
													  New_Uid_Peach#peach.contry,
													  New_Uid_Peach#peach.nickname,
													  New_Uid_Peach#peach.sex,
													  New_Uid_Peach#peach.career,
													  New_Uid_Peach#peach.image]);
								true->void
							end,
							%%更新场景蟠桃数
							mod_scene_agent:update(peach, [Uid,Scene_id,My_Peach_Num]),
							New_Peach_dict = dict:store(Uid, New_Uid_Peach, State#state.peach_dict),
							NewState = State#state{
								peach_dict = New_Peach_dict				   
							}
					end;
				_->NewState = State
			end;
		true->
			NewState = State
	end,
	
	{noreply, NewState};

handle_cast({open_peach}, State) ->
	Peach_stauts = 1,
	NewState = #state{peach_stauts=Peach_stauts,
					  config_begin_hour= State#state.config_begin_hour,
					  config_begin_minute= State#state.config_begin_minute,
					  loop_time = State#state.loop_time},
	{ok, BinData} = pt_481:write(48101, [Peach_stauts]),
	Apply_level = data_peach:get_peach_config(apply_level),
	lib_unite_send:send_to_all(Apply_level, 999, BinData),
    {noreply, NewState};

handle_cast({end_peach,Config_Begin_Hour,Config_Begin_Minute,Loop_time}, State) ->
	%%发送结束协议
    {ok, BinData} = pt_481:write(48106, []),
	lib_unite_send:send_to_all(BinData),
	
	%% 设置新状态
	Peach_stauts = 2,
	Temp_State = State#state{peach_stauts = Peach_stauts},
	
	%% 发奖(针对所有)
	spawn(fun()-> 
		% 清理所有蟠桃园怪物
		spawn(fun()-> 
			Scene_id = data_peach:get_peach_config(scene_id),
            lib_mon:clear_scene_mon(Scene_id,[],1)	
		end),
		Now_Time = util:unixtime(),
		Peach_List = dict:to_list(Temp_State#state.peach_dict),
		%% 按最终蟠桃数排序
		Sort_Peach_List = lists:sort(fun({_K1,A},{_K2,B})-> 
			A_Score = A#peach.acquisition + A#peach.plunder - A#peach.robbed,
			B_Score = B#peach.acquisition + B#peach.plunder - B#peach.robbed,
			if
				B_Score =< A_Score -> true;
				true -> false
			end
		end, Peach_List),
		if
			110<length(Sort_Peach_List)->
				{Top_110_Peach_List,_} = lists:split(110, Sort_Peach_List);
			true->
				Top_110_Peach_List = Sort_Peach_List
		end,
		%%元旦礼包
		spawn(fun()-> 
			Top_id_List = [V#peach.id||{_K,V}<-Sort_Peach_List],
			data_top_gift:send_gift(1,Top_id_List)
		end),
		Multiple_all_data = mod_multiple:get_all_data(),
		Multiple = lib_multiple:get_multiple_by_type(7,Multiple_all_data),
		F_Top_110_Peach_List = [{V#peach.nickname,Multiple*(V#peach.acquisition + V#peach.plunder - V#peach.robbed)}||
								{_K,V}<-Top_110_Peach_List],
		%% 发奖(针对个人)
		lists:foreach(fun({_K,V})-> 
			spawn(fun()-> 
				Score = Multiple*(V#peach.acquisition + V#peach.plunder - V#peach.robbed),
				Paiming = get_Paiming(V#peach.id,Sort_Peach_List,0),
				Paiming_Ratio = data_peach:get_paiming_ratio(Paiming),
				Jifen_Ratio = data_peach:get_jifen_ratio(Score),
				Add_exp = V#peach.lv * V#peach.lv * (Paiming_Ratio+Jifen_Ratio),
				[Goods_A_Num,Goods_B_Num] = data_peach:get_GoodsList(Score),
				if
					10=<Score -> %%10个以上，才能计算蟠桃数
						Card_rate = data_peach:get_rate_by_card(Score),
						case util:floor((V#peach.robbed*Card_rate)/100) of
							0->Peach_Card_good_num =1;
							_Peach_Card_good_num -> Peach_Card_good_num = _Peach_Card_good_num
						end;
					true-> %%没有任何蟠桃数
						Card_rate = 0,
						Peach_Card_good_num = 0
				end,
				lib_player:update_player_info(V#peach.id, [{peach,[Score,
																   V#peach.acquisition,
																   V#peach.plunder,
													 			   V#peach.robbed,
																   Now_Time,
																   Peach_Card_good_num]},
														   	{add_exp,Add_exp},
														    {peach_num,0}]),
				{ok, BinData_48107} = pt_481:write(48107, [Score,V#peach.acquisition,V#peach.plunder,
													 V#peach.robbed,Goods_A_Num,Goods_B_Num,
													 F_Top_110_Peach_List,Card_rate,Add_exp]),
    			lib_unite_send:send_to_uid(V#peach.id, BinData_48107),
				Gift_Id1 = data_peach:get_peach_config(gift_id1),
				Gift_Id2 = data_peach:get_peach_config(gift_id2),
				%%发送邮件
				Title = data_mail_log_text:get_mail_log_text(peach_title),
				Content = io_lib:format(data_mail_log_text:get_mail_log_text(peach_content),[Score,Goods_B_Num]),
				if
                    0<Goods_A_Num->
						lib_mail:send_sys_mail_bg([V#peach.id], Title, Content, Gift_Id1, 2, 0, 0,Goods_A_Num,0,0,0,0),
						timer:sleep(10);
					true->void
				end,
				if
					0<Goods_B_Num->
                        %% 春节召回活动
                        lib_off_line:add_off_line_count(V#peach.id, 15, 1, Goods_B_Num),
						lib_mail:send_sys_mail_bg([V#peach.id], Title, Content, Gift_Id2, 2, 0, 0,Goods_B_Num,0,0,0,0);
					true->void
				end,
				timer:sleep(50)
			end)				  
		end, Peach_List),
		if
			0<length(Top_110_Peach_List)->
				{First_uid,_} = lists:nth(1, Top_110_Peach_List),
				%蟠桃会获得蟠桃数量第一的玩家绑定称号：
	        	lib_designation:bind_design_in_server(First_uid, 201407, "", 0);
			true->void
		end
	end),
	
	NewState = set_time_sub(Config_Begin_Hour,Config_Begin_Minute,Loop_time,Temp_State),	
	{noreply, NewState};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% 获取排名
get_Paiming(_Id,[],_)->0;%没找到
get_Paiming(Id,[{Id_K,_V}|T],Paiming)->
	if
		Id=:=Id_K->Paiming+1;
		true->
			get_Paiming(Id,T,Paiming+1)
	end.

%%统计所有参与人口(中途掉线算还在房间里)
sum_peach(Peach_room_dict_List,Sum_num)->
	case Peach_room_dict_List of
		[]->Sum_num;
		[{_K,V}|T]->
			sum_peach(T,Sum_num+V#peach_room.num)
	end.

%%设置时间子方法
set_time_sub(Config_Begin_Hour,Config_Begin_Minute,Loop_time,State)->
	NewState = State#state{config_begin_hour=Config_Begin_Hour,
					  config_begin_minute=Config_Begin_Minute,
					  loop_time=Loop_time},
	NewState.
