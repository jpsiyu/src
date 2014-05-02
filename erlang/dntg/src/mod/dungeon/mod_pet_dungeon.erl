%%------------------------------------------------------------------------------
%% @Module  : mod_pet_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.4.26
%% @Description: 宠物副本服务
%%------------------------------------------------------------------------------

-module(mod_pet_dungeon).
-include("common.hrl").
%-include("record.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").

-export([create_scene/2,              %% 创建宠物副本场景.
		 kill_npc/4,                  %% 杀死宠物副本里面的怪物.
		 mon_change_look/4,           %% 怪物变身.
		 get_mon_list/1,              %% 获取怪物列表.
		 get_appoint_dungeon_tips/1,  %% 获取情缘副本tips.
		 get_pet_dungeon_think/1,     %% 获取宠物副本想法.
		 get_pet_dungeon_count/1,     %% 获取宠物副本配置.
		 create_mon_list/5            %% %% 创建宠物怪物列表..
		]).

-export([handle_call/3, 
		 handle_cast/2, 
		 handle_info/2]).


%% 第二波宠物副本怪物.
-define(APPOINT_MON_LIST2, [{23317,23318},{23319,23320},{23321,23322},{23323,23324},
							{23325,23326},{23327,23328},{23329,23330},{23331,23332}]).

%% 第三波宠物副本怪物.
-define(APPOINT_MON_LIST3, [{23333,23334},{23335,23336},{23337,23338},{23339,23340},
							{23341,23342},{23343,23344},{23345,23346},{23347,23348}]).

%% 第一波正常怪物
-define(PET_MON_LIST1, [23301,23302,23303,23304,23305,23306,23307,23308,23309,23310,23311]).
%% 第一波狂暴怪物
-define(PET_MON_LIST11, [23312,23313,23314,23315,23316,23317,23318,23319,23320,23321,23322]).
%% 第二波正常怪物
-define(PET_MON_LIST2, [23327,23328,23329,23330,23331,23332,23333,23334,23335,23336,23337]).
%% 第二波狂暴怪物
-define(PET_MON_LIST21, [23338,23339,23340,23341,23342,23343,23344,23345,23346,23347,23348]).
%% 第三波正常怪物
-define(PET_MON_LIST3, [23349,23350,23351,23352,23353,23354,23355,23356,23357,23358,23359]).
%% 第三波狂暴怪物
-define(PET_MON_LIST31, [23360,23361,23362,23363,23364,23365,23366,23367,23368,23369,23370]).
%% 第三波BOSS怪物
-define(PET_BOSSMON_LIST, [23323,23324,23325,23326]).


%% --------------------------------- 公共函数 ----------------------------------

%% 创建宠物副本场景
create_scene(SceneId, State) ->
    %1.加载副本场景怪物信息.
	MonNameList = create_mon(SceneId, self(), State#dungeon_state.level, 1, ?PET_MON_LIST3),
	
    %2.更新副本场景的唯一id.
    ChangeSceneId = 
		fun(DunScene) ->
	        case DunScene#dungeon_scene.sid =:= SceneId of
	            true -> 
					DunScene#dungeon_scene{id = SceneId};
	            false -> 
					DunScene
	        end
	    end,
    NewState = State#dungeon_state{
				   scene_list = [ChangeSceneId(DunScene)||DunScene<-State#dungeon_state.scene_list], 
				   appoint_state = {1, 0},
				   appoint_mon_name_list = MonNameList,
				   think_count = 1
				   },    
	
    {SceneId, NewState}.

%% 杀怪事件.
kill_npc(State, _Scene, SceneResId, NpcIdList) ->
	%1.获取宠物副本数据.
    PLv = State#dungeon_state.level,
    {Level, KillMonNum} = State#dungeon_state.appoint_state,	 
	
    case KillMonNum + 1 >= 5 of
		%1.生成下一波怪物.
        true -> 
            case Level == 2 of
				%1.创建boss.
                true ->
					put("pet_think", []),
					%关闭想法定时器.
					erlang:cancel_timer(State#dungeon_state.think_timer),
					%erlang:cancel_timer(State#dungeon_state.random_timer),
					%erlang:cancel_timer(State#dungeon_state.turn_back_timer),					
					%通知客户端宠物副本关闭想法界面.
                    {ok, BinData} = pt_611:write(61103, []),
					[lib_player:rpc_cast_by_id(Role#dungeon_player.id, 
											   lib_server_send, 
											   send_to_uid, 
											   [Role#dungeon_player.id, BinData])
											  ||Role<-State#dungeon_state.role_list],
					%得到BOSS的ID.				
				    RoleList = State#dungeon_state.role_list,
					[RoleInfo|_RoleList]=RoleList,
				    PlayerLevel = 
						case lib_player:get_player_info(RoleInfo#dungeon_player.id) of
					        [] -> 1;
					        PlayerStatus ->
					            PlayerStatus#player_status.lv
					    end,
					BossId = data_pet_dungeon:get_boss_id(PlayerLevel),
					%召唤BOSS.
                    Args = [
                        {hp,     round(PLv*PLv*PLv*86*(PLv/40-(PLv-40)/120)/170)},
                        {hp_lim, round(PLv*PLv*PLv*86*(PLv/40-(PLv-40)/120)/170)},
                        {att, round(PLv*PLv*12/130)},
                        {exp, round(PLv*PLv*25)},
                        {lv,  PLv}
                    ],
                    lib_mon:async_create_mon(BossId, SceneResId, 16, 39, 0, self(), 1, Args),
					%2.告诉客户端生成BOSS怪.
				    {ok, BinData2} = pt_611:write(61104, 2),
				    lib_server_send:send_to_scene(SceneResId, self(), BinData2),	
                    State#dungeon_state{appoint_state = {Level + 1, 0}};
				%2.创建一波怪.
                false -> 
                    Mon = case Level of 
                        1 ->
                            ?PET_MON_LIST3; 
                        2 ->
                            ?PET_MON_LIST3;
                        _ ->
                            [] 
                    end,
					case Mon == [] of
						true ->
							State#dungeon_state{appoint_state = {Level, KillMonNum + 1}};
						false ->
							%创建怪物.
		                    MonNameList = create_mon(SceneResId, self(), State#dungeon_state.level, 2, Mon),
							%重新发送想法.
							erlang:cancel_timer(State#dungeon_state.think_timer),        
							self() ! 'pet_dungeon_next_think',
							%发送新想法.
		                    State#dungeon_state{appoint_state = {Level + 1, 0}, 
												appoint_mon_name_list = MonNameList,
												think_count = 1}
					end
            end;
		
		%2.修改ets表.
        false -> 
            [set_pet_dungeon(NpcId, self(), State#dungeon_state.think_timer)||NpcId <- NpcIdList],
            State#dungeon_state{appoint_state = {Level, KillMonNum + 1}}
    end.

%% 怪物变身.
mon_change_look(Scene, DungeonPid, MonId, ChangeFlag) ->
    case is_pid(DungeonPid) of
        true -> 
			gen_server:cast(DungeonPid, {'mon_change_look', Scene, MonId, ChangeFlag});
        false -> 
			ok
    end.

%% 获取怪物列表.
get_mon_list(DungeonPid) -> 
    case is_pid(DungeonPid) andalso misc:is_process_alive(DungeonPid) of
        true ->
            gen_server:call(DungeonPid, {get_mon_list});
        false ->
            []
    end.

%% 获取情缘副本tips
get_appoint_dungeon_tips(DungeonPid) -> 
    case is_pid(DungeonPid) of
        true ->
            gen_server:call(DungeonPid, {get_appoint_dungeon_tips});
        false ->
            []
    end.

%% 获取宠物副本想法信息
get_pet_dungeon_think(DungeonPid) -> 
    case is_pid(DungeonPid) of
        true ->
            DungeonPid ! 'get_pet_dungeon_think';
        false ->
            skip
    end.

%% 获取宠物副本配置信息
get_pet_dungeon_count(DungeonPid) -> 
    case is_pid(DungeonPid) of
        true ->
            gen_server:call(DungeonPid, {get_appoint_dungeon_tips});
        false ->
            []
    end.

%% --------------------------------- 内部函数 ----------------------------------

%% 获取情缘副本tips
handle_call({get_appoint_dungeon_tips}, _From, State) ->
    {reply, State#dungeon_state.appoint_mon_name_list, State};

%% 获取宠物副本想法信息
handle_call({get_pet_dungeon_think}, _From, State) ->
    {reply, State#dungeon_state.appoint_mon_name_list, State};
    
%% 获取宠物副本配置信息
handle_call({get_pet_dungeon_count}, _From, State) ->
    {reply, State#dungeon_state.appoint_mon_name_list, State};

%% 获取怪物列表.
handle_call({get_mon_list}, _From, State) ->
    PetDungeon = 
		case ets:lookup(?ETS_PET_DUNGEON, self()) of
			[] -> [];
			_PetDungeon -> _PetDungeon
		end,
    {reply, PetDungeon, State}.
            
%% 怪物变身.
handle_cast({'mon_change_look', Scene, MonId, ChangeFlag}, State) ->
	case mod_scene_agent:apply_call(Scene, lib_mon, lookup, [Scene, MonId]) of
        Mon when is_record(Mon, ets_mon) -> 
			{NewMonId, ChangeType} = 
				if 
					ChangeFlag == "change_look" ->					
						{data_pet_dungeon:get_change_look_id(Mon#ets_mon.mid), 1};
					ChangeFlag == "turn_back" ->					
						{Mon#ets_mon.mid, 2}
				end,
			lib_pet_dungeon:send_change_look(Mon#ets_mon.id, 
											 NewMonId, 
											 ChangeType, 
											 State);
		_Other ->
			skip
        end,			
    {noreply, State}.

%% 怪物随机变身.
handle_info('random_change_look', State) ->
	TurnTimer = erlang:send_after(20 * 1000, self(), 'turn_back'),
	
	%1.得到副本所有怪物.
    AllMon = lib_mon:get_scene_mon(State#dungeon_state.begin_sid, self(), all),
	
	%2.随机要变身的怪物资源.
	NewAllMon = util:list_shuffle(AllMon),
	
	%3.得到要变身怪物的个数.
	Length = length(NewAllMon),
	Count = 
		if 
			Length rem 2 =:= 0 ->
				length(NewAllMon) div 2;
			true ->
				length(NewAllMon) div 2 + 1
		end,
	 
	%4.查询怪物列表.
	FindPetDungeon = 
		case ets:lookup(?ETS_PET_DUNGEON, self()) of
			[] -> #ets_pet_dungeon{};
			[_FindPetDungeon] -> _FindPetDungeon
		end,

	case FindPetDungeon#ets_pet_dungeon.mon_list of
		[MonMid] ->	
			%5.删除悟空的想法的怪物.
			NewAllMon2 = lists:keydelete(MonMid, 10, AllMon),
			NewAllMon3 = util:list_shuffle(NewAllMon2),			
			%6.把怪物列表变身.
			change_look_list(NewAllMon3, NewAllMon, Count, 3, State);
		_ ->
			skip
	end,
		
    {noreply, State#dungeon_state{turn_back_timer = TurnTimer}};

%% 怪物变身还原.
handle_info('turn_back', State) ->
	RandomTimer = erlang:send_after(5 * 1000, self(), 'random_change_look'),
	%1.得到副本所有怪物.
	AllMon = lib_mon:get_scene_mon(State#dungeon_state.begin_sid, self(), all),
	%2.把怪物列表变身.
	change_look_list(AllMon, AllMon, length(AllMon), 4, State),
	
    {noreply, State#dungeon_state{random_timer = RandomTimer}};

%% 获取想法.
handle_info('get_pet_dungeon_think', State) ->
	ThinkCount1 = State#dungeon_state.think_count,
	case ThinkCount1 > 1 of
		%1.重新上线发送现在的想法给客户端.
		true ->
			case get("pet_think") of
				undefined-> 
					skip;
				[] -> 
					skip;
				_ThinkList ->
					RoleList = State#dungeon_state.role_list,
					[ThinkCount, ThinkTime, ThinkList] = _ThinkList,
				    {ok, BinData} = pt_611:write(61101, [ThinkCount, ThinkTime, ThinkList]),			
				    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData) || Role <- RoleList]				
			end;
		%2.如果是第一次请求就产生想法.
		false ->
            self() ! 'pet_dungeon_next_think'
			%暂时屏蔽随机变身.
            %DungeonPid ! 'random_change_look';
	end,
	{noreply, State};
	
%% 生成下一个想法.
handle_info('pet_dungeon_next_think', State) ->
	%1.下次产生的时间.
	ThinkCount = State#dungeon_state.think_count,
	ThinkTime = data_pet_dungeon:get_think_time(State#dungeon_state.level, ThinkCount),
	ThinkTimer = erlang:send_after(ThinkTime * 1000, self(), 'pet_dungeon_next_think'),	
	
	%1.场景还没激活检查怪物是否全部杀死了.
	NowSceneId = State#dungeon_state.begin_sid,
    AllMonCount = mod_scene_agent:apply_call(NowSceneId, 
											 lib_scene, 
											 get_scene_mon_num_by_kind, 
											 [NowSceneId, self(), 0]),
	case AllMonCount of
		0 ->
			erlang:cancel_timer(ThinkTimer),
			%1.容错处理全部怪杀完了要走下一波的流程.
			self()!{kill_npc, NowSceneId, [1], 0};
		_Count ->    
			FindPetDungeon = case ets:lookup(?ETS_PET_DUNGEON, self()) of
				[] -> #ets_pet_dungeon{};
				[_FindPetDungeon] -> _FindPetDungeon
			end,
		    
			MonListLen = length(FindPetDungeon#ets_pet_dungeon.total_mon_list),
			ThinkList = 
				if 
					MonListLen == 0 -> [{0, 0}];
					MonListLen >= 1 ->
						%1.产生想法.
						MonMidList1 = util:list_shuffle(FindPetDungeon#ets_pet_dungeon.total_mon_list),
						[MonMid1|_MonMidList] = MonMidList1,					
						%2.保存想法.
					    ets:insert(?ETS_PET_DUNGEON, FindPetDungeon#ets_pet_dungeon{mon_list = [MonMid1]}),				
						%3.得到怪物唯一ID.	
                        MonIdList1 = lib_mon:get_scene_mon_by_mids(State#dungeon_state.begin_sid, self(), [MonMid1], #ets_mon.id),
                        MonId1 = case MonIdList1 of
                            [BackMonId|_] when is_integer(BackMonId)-> BackMonId;
                            _Other -> 0
                        end,
						%4.得到水果资源ID.
						FruitId1 = data_pet_dungeon:get_fruit_id(MonMid1),
					    %想法 {怪物唯一ID，水果资源ID}.
						[{MonId1, FruitId1}];
					true -> [{0, 0}]
				end,
			
			%4.发给客户端.
		    RoleList = State#dungeon_state.role_list,
			put("pet_think", [ThinkCount, ThinkTime, ThinkList]),
		    {ok, BinData} = pt_611:write(61101, [ThinkCount, ThinkTime, ThinkList]),			
		    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData) || Role <- RoleList]
	end,
	{noreply, State#dungeon_state{think_count = ThinkCount+1, think_timer = ThinkTimer}}.

%% --------------------------------- 私有函数 ----------------------------------

%% 杀死怪物后更改ets表
set_pet_dungeon(MonId, DungeonPid, ThinkTimer) ->
	
	%1.查询怪物列表.
	FindPetDungeon = 
		case ets:lookup(?ETS_PET_DUNGEON, self()) of
			[] -> #ets_pet_dungeon{};
			[_FindPetDungeon] -> _FindPetDungeon
		end,
	
	%2.在全部怪物列表删除.
	case lists:member(MonId, FindPetDungeon#ets_pet_dungeon.total_mon_list) of
		false -> 
			skip;
		_ ->
			NewMonList = lists:delete(MonId, FindPetDungeon#ets_pet_dungeon.total_mon_list),
			ets:insert(?ETS_PET_DUNGEON, FindPetDungeon#ets_pet_dungeon{total_mon_list = NewMonList})
	end,
	
	%3.如果想法列表，重新生成想法.
    case lists:member(MonId, FindPetDungeon#ets_pet_dungeon.mon_list) of
        false ->
			skip;
        _ ->
			%关闭定时器.
			if 
				ThinkTimer =/= 0 ->	  
					erlang:cancel_timer(ThinkTimer);
				true ->
					skip
			end,
			DungeonPid ! 'pet_dungeon_next_think'
    end.

%% 创建怪物.
create_mon(SceneId, CopyId, Level, _Type, MonList) ->
    %1.怪物坐标
	%MonLocalList1 = [{23, 34},{11, 28},{14, 26},{13, 40},{18, 24},
	%				 {20, 33},{11, 35},{17, 41},{21, 26},{21, 40}],
    MonLocalList1 = [{21,41},{24,32},{17,26},{9,32},{12,42}],
    %2.怪物坐标随机化.
    %MonLocalList2 = util:list_shuffle(MonLocalList1),

	%3.保存想法.(怪物坐标只有10个，所以这里减少一个).
	%[_MonId1|NewMonList] = MonList, 
    MonList1 = lists:sublist(util:list_shuffle(MonList), 5),
    [MonId1, MonId2|_] = MonList1,
	MonList2 = [MonId1, MonId2],
    %%　io:format("MonList1 ~p~n", [[MonList1, MonList2]]),
    ets:insert(?ETS_PET_DUNGEON, #ets_pet_dungeon{dungeon_pid = CopyId, 
												  total_mon_list = MonList1,
												  mon_list = MonList2}),
	
    MonNameList = lists:sublist(util:list_shuffle(data_appointment_dungeon:get_name()), 8),
	%4.创建怪物.
	mod_scene_agent:apply_call(SceneId, mod_pet_dungeon, create_mon_list, 
							   [MonLocalList1, MonList1, SceneId, CopyId, Level]), 	
    MonNameList.

%% 创建宠物怪物列表.
create_mon_list(_, [], _, _, _) -> skip;
create_mon_list([], _, _, _, _) -> skip;
create_mon_list([{X1, Y1}|PT], [NewMonId|MonIdList], SceneId, CopyId, Level) ->
    Args = [
        {hp,     round(Level*Level*Level*13*(Level/40-(Level-40)/120)/170)},
        {hp_lim, round(Level*Level*Level*13*(Level/40-(Level-40)/120)/170)},
        {att, round(Level*Level*6/130)},
        {exp, round(Level*Level*5)},
        {lv,  Level}
    ],
    mod_mon_create:create_mon_cast(NewMonId, SceneId, X1, Y1, 0, CopyId, 1, Args),
    create_mon_list(PT, MonIdList, SceneId, CopyId, Level).

%% 把怪物列表变身.
change_look_list(_, _, 0, _ChangeType, _State) -> skip;
change_look_list(_, [], _Count, _ChangeType, _State) -> skip;
change_look_list([], _, _Count, _ChangeType, _State) -> skip;
change_look_list([Mon1|MonList1], [Mon2|MonList2], Count, ChangeType, State) ->
	lib_pet_dungeon:send_change_look(Mon1#ets_mon.id, Mon2#ets_mon.mid, ChangeType, State),
	if 
		Count >= 1 ->
    		change_look_list(MonList1, MonList2, Count-1, ChangeType, State);
		true ->
			change_look_list(MonList1, MonList2, 0, ChangeType, State)
	end.
