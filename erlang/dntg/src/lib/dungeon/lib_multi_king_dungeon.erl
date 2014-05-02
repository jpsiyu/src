%%------------------------------------------------------------------------------
%% @Module  : lib_multi_king_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.11.21
%% @Description: 多人皇家守卫军塔防副本逻辑
%%------------------------------------------------------------------------------


-module(lib_multi_king_dungeon).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-include("king_dun.hrl").
-include("sql_rank.hrl").


%% 公共函数：外部模块调用.
-export([
		 kill_npc/3,               %% 杀死怪物事件.
		 kill_princess/2,          %% 杀死公主.
		 create_scene/2,           %% 创建塔防副本场景.
		 create_mon/3,             %% 创建怪物.			 
		 set_level/2,              %% 设置波数.
		 get_level/1,              %% 获取波数.
		 get_score/1,              %% 获取积分和经验.
		 call_mon/1,               %% 提前召唤.
		 upgrade_building/2,       %% 升级建筑.
		 upgrade_skill/2,          %% 升级技能.
		 get_building/1,           %% 获取建筑信息..
		 get_king_state/0,         %% 得到塔防副本状态.
		 set_king_state/1,         %% 设置塔防副本状态.
		 save_king_state/1,        %% 保存塔防副本状态.
		 send_score/1,             %% 发送塔防副本积分和经验.
		 update_rank/2,            %% 更新塔防副本排行榜.
		 get_soldier_auto_id/2,    %% 得到士兵的自增ID.
		 log/4                     %% 写日志.
]).


%% --------------------------------- 公共函数 ----------------------------------


%% 杀怪事件.
kill_npc([KillMonId|_OtherIdList], _IsSkip, State) ->
	%1.公主死掉了杀死所有怪物.
	State1 = kill_princess(KillMonId, State),
																 
	%2.检测是否杀死一波怪物.
	State2 = kill_mon(KillMonId, State1),
	
    %3.是否获得一个新技能.
    %[catch get_special_skill(KillMonId, Role#dungeon_player.id)||Role <- State#dungeon_state.role_list],
    MemberList = [Role#dungeon_player.id||Role <- State#dungeon_state.role_list],
    catch get_special_skill(KillMonId, MemberList),
	
	State2.

%% 杀死公主.
kill_princess(KillMonId, State) ->
	PrincessId = data_multi_king_dun_config:get_config(princess_id),
	case KillMonId == PrincessId of
		false ->
			State2 = State,
			skip;
		true ->
			CopyId = self(),
			SceneId = State#dungeon_state.begin_sid,
			KingDunState = get_king_state(),	
			CreateMonTimer = KingDunState#king_dun_state.create_mon_timer,
			
			%1.停止刷怪定时器.
			if 
				is_reference(CreateMonTimer) ->
					erlang:cancel_timer(CreateMonTimer);
				true ->
					skip
			end,
			
			%2.停止下一波怪物攻击倒计时.
			NewKingDunState = KingDunState#king_dun_state{
								last_begin_time = 0
							  },
			set_king_state(NewKingDunState),
			CopyId!'king_dun_get_level',

			%3.杀死所有怪.
            lib_mon:clear_scene_mon(SceneId, CopyId, 1),
			
			%4.如果玩家死亡要复活.
			FunKingDunRevive = 
				fun(PlayerPid) ->
					gen_server:cast(PlayerPid, 'king_dun_revive')
				end,
			RoleList = State#dungeon_state.role_list,
    		[FunKingDunRevive(Role#dungeon_player.pid) || Role <- RoleList],
			
			State2 = State#dungeon_state{logout_type = ?DUN_EXIT_PRINCESS_DIE},
			
			%5.结束副本.
			CopyId!close_dungeon
	end,	
	State2.

%% 杀死敌对怪物.
kill_mon(_KillMonId, State) ->
	KingDunState = get_king_state(),
	EnemyMonList = KingDunState#king_dun_state.enemy_mon_list,
	
	%1.检测是否为敌对怪物.
    case lists:keyfind(_KillMonId, 3, EnemyMonList) of
		false ->
		    skip;
		EnemyMon ->
			NowLevel = EnemyMon#king_dun_enemy_mon.level,
			Count = EnemyMon#king_dun_enemy_mon.mon_count,
			KillCount = EnemyMon#king_dun_enemy_mon.kill_mon_count,
			%1.删除击杀列表.
			NewEnemyMonList = lists:keydelete(_KillMonId, 3, EnemyMonList),
			
			%2.检测怪物是否杀完了.
			case Count =< KillCount + 1 of
				true ->
					%1.记录完成的波数.
					FinishLevel1 = KingDunState#king_dun_state.finish_level,
					FinishTime1 = KingDunState#king_dun_state.finish_time,
					NowTime = util:unixtime(),
					BeginTime = State#dungeon_state.time,
					FinishTime2 = NowTime - BeginTime,
					
					if
						NowLevel > FinishLevel1 ->
							FinishTime3 = FinishTime2,
							FinishLevel2 = NowLevel;
						NowLevel =:= FinishLevel1 andalso FinishTime1 > FinishTime2 ->
							FinishTime3 = FinishTime2,
							FinishLevel2 = NowLevel;
						true ->
							FinishTime3 = FinishTime1,
							FinishLevel2 = FinishLevel1
						end,
					
					%2.奖励经验.
					MonExp = EnemyMon#king_dun_enemy_mon.exp,
					NewExp = KingDunState#king_dun_state.exp + MonExp,
					
					%3.奖励积分.
					MonScore = EnemyMon#king_dun_enemy_mon.score,
					NewScore = KingDunState#king_dun_state.score + MonScore,
					
					%4.保存副本状态.
					NewKingDunState = KingDunState#king_dun_state{
										exp = NewExp,
										score = NewScore,
										enemy_mon_list = NewEnemyMonList,
										finish_level = FinishLevel2,
										finish_time = FinishTime3
									  },
					set_king_state(NewKingDunState),
										
					%3.发放经验和恢复一半生命.
					FunReward = 
					    fun(PlayerId, PlayerPid) ->
							%1.每打完一波获得NPC祝福，回复50%血.	
							lib_player:add_hp(PlayerPid,0.5),
							%2.发经验.
							lib_player:update_player_info(
							    PlayerId,
								[{add_exp, erlang:round(MonExp)}]),
							%3.发送塔防副本通过20,30,40,50的传闻.
							send_notice(NowLevel, PlayerId),
							PlayerId
						end,
					RoleList = State#dungeon_state.role_list,
					PlayerIdList = [FunReward(Role#dungeon_player.id,Role#dungeon_player.pid)
									|| Role <- RoleList],
					mod_dungeon_agent:set_multi_king_master(PlayerIdList, FinishLevel2, FinishTime3);
					
				false ->
					%1.更新击杀怪物数量.
					NewEnemyMon = EnemyMon#king_dun_enemy_mon{
								      kill_mon_count = KillCount + 1
								  },

					%2.奖励积分.
					MonScore = EnemyMon#king_dun_enemy_mon.score,
					NewScore = KingDunState#king_dun_state.score + MonScore,
					
					%3.保存副本状态.
					NewEnemyMonList2 = NewEnemyMonList ++ [NewEnemyMon],
					NewKingDunState = KingDunState#king_dun_state{
										enemy_mon_list = NewEnemyMonList2,
										score = NewScore
									  },
					set_king_state(NewKingDunState)
			end,

			%3.更新积分和经验.
			send_score(State)
    end,
	State.

%% 创建塔防副本场景
create_scene(SceneId, State) ->
	CopyId = self(),
	RoleList = State#dungeon_state.role_list,
	%1.创建者的id..
	OwnerId = 
		case RoleList of
			[] ->
				0;
			_RoleList ->
				[Player|_RoleList2] = _RoleList,
				Player#dungeon_player.id
		end,
	
	%1.初始化塔防副本状态.
	NowTime = util:unixtime(),
	KingDunState = #king_dun_state{last_begin_time = NowTime, 
									score = 0,
									owner_id = OwnerId},
	put("king_dun_state", KingDunState),	
	
	%2.修改副本场景ID.
    ChangeSceneId =  
		fun(DunScene) ->
	        case DunScene#dungeon_scene.sid =:= SceneId of
	            true -> 
					DunScene#dungeon_scene{id = SceneId};
	            false -> 
					DunScene
	        end
    	end,
    NewSceneList =  
		[ChangeSceneId(DunScene)|| DunScene<-State#dungeon_state.scene_list],
				 	
	
	%3.创建公主.
	PrincessId = data_multi_king_dun_config:get_config(princess_id),
    lib_mon:async_create_mon(PrincessId, SceneId, 13, 26, 0, CopyId, 1, [{group, 1}]),
	
	%4.创建建筑物.
	CreateBuildingList = data_multi_king_dun_config:get_config(create_building_list),
	CreateData = [CreateBuildingList, SceneId],
	mod_scene_agent:apply_cast(SceneId, mod_mon_create, create_mon_king_dungeon, 
							   [[State#dungeon_state.type, ?CREATE_BUILDING, CopyId, CreateData]]),
	
	%4.保存副本等级.
    NewState = State#dungeon_state{scene_list =NewSceneList, level = 1},	
    {SceneId, NewState}.

%% 创建怪物.
create_mon(Type, CopyId, Data) ->
	case Type of
		%1.创建敌对怪物.
		?CREATE_ENEMY_MON ->
			[Level, SceneId, OwnerId] = Data,
			create_enemy_mon(Level, SceneId, CopyId, OwnerId);
		
		%2.创建建筑物.	
		?CREATE_BUILDING ->
			[BuildingList, SceneId] = Data,
			FunCreate = 
				fun({Position, BuildingId}) ->
					create_building(Position, BuildingId, SceneId, CopyId)
				end,
			[FunCreate(Building) || Building <- BuildingList];
		
		%3.升级建筑物.
		?UPGRADE_BUILDING ->
			[BuildingId, KillMonList, SceneId, Position] = Data,
			create_upgrade_building(BuildingId, KillMonList, SceneId, CopyId, Position);
		
		%4.升级技能.
		?UPGRADE_SKILL ->
			[MonIdList, SkillList] = Data,
			create_upgrade_skill(MonIdList, SkillList)
	end.

%% 创建敌对怪物.
create_enemy_mon(Level, SceneId, CopyId, OwnerId) ->
	KingDunData = data_multi_king_dun:get(Level),
	MonId = KingDunData#king_dun_data.mon_id,
	Count = KingDunData#king_dun_data.mon_count,
	DirList = KingDunData#king_dun_data.direction,
	%1.召唤怪物.
	CreatePidList = create_mon_direction(DirList, Count, MonId, SceneId, 
										 CopyId, OwnerId, []),
	CopyId!{'king_dun_set_create_pid', MonId, CreatePidList}.

%% 按照方向创建怪物.
create_mon_direction([], _Count, _MonId, _SceneId, _CopyId, _OwnerId, CreatePidList) ->
	CreatePidList;
create_mon_direction([_Dir|DirList], _Count, MonId, SceneId, CopyId, OwnerId, CreatePidList) ->
	%1.得到怪物的坐标.
	{Dir, Count} = _Dir,
	Position =
		case Dir of
			1 -> {ok, 40, 102};
			2 -> {ok, 86, 106};
			3 -> {ok, 84, 57};
			_ ->  skip
		end,
	
	%2.开线程创建怪物.
	NewCreatePidList =
	case Position of
		{ok, X, Y} ->
			CreatePid = spawn(fun() -> 
									  create_mon_count(Count, X, Y, MonId, 
													   SceneId, CopyId, OwnerId) 
							  end),
			CreatePidList ++ [CreatePid];
		_ ->
			CreatePidList
	end,
	create_mon_direction(DirList, Count, MonId, SceneId, CopyId, OwnerId, NewCreatePidList).

%% 按照数量创建怪物.
create_mon_count(0, _X, _Y, MonId, _SceneId, CopyId, _OwnerId) ->
	CopyId!{'king_dun_del_create_pid', MonId};
create_mon_count(Count, X, Y, MonId, SceneId, CopyId, OwnerId) ->
	timer:sleep(1000),
	AiMonList = data_multi_king_dun_config:get_config(ai_mon_list),
	mod_mon_create:create_mon(MonId, SceneId, X, Y, 1, CopyId, 1, 
								[{ai_mon, AiMonList},
	 							 {group, 2},
	 							 {owner_id, OwnerId}
								]),			
	create_mon_count(Count-1, X, Y, MonId, SceneId, CopyId, OwnerId).

%% 创建建筑.
create_building(Position, BuildingId, SceneId, CopyId) ->
	BuildingData = data_multi_king_dun_config:get_building_data(BuildingId),
	case BuildingData#king_dun_building.mid == 0 of
		true ->
			skip;
		false ->
			{X, Y} = data_multi_king_dun_config:get_building_position(Position),
			BuildingMonId = BuildingData#king_dun_building.mid,
			SoldierList = BuildingData#king_dun_building.soldier_list,
			PassiveBuildingList = data_multi_king_dun_config:get_config(passive_building_list),
			AttackType = 
				case lists:member(BuildingMonId, PassiveBuildingList) of
					true ->
						0;
					false ->
						1
				end,
			%1.创建建筑.
			BuildingAutoId = 
				mod_mon_create:create_mon(BuildingMonId, 
											   SceneId, 
											   X, 
											   Y, 
											   AttackType, 
											   CopyId, 
											   1, 
											  [{group, 1}]),
			%2.创建士兵.
			SoldierList1 = 
				case SoldierList == [] of
					true ->
						[];
					false ->
						SoldierLen = length(SoldierList),
						create_mon_soldier(SoldierList, [], SceneId, CopyId, Position, SoldierLen)
				end,
			
			BuildingData1 = BuildingData#king_dun_building{
								auto_id = BuildingAutoId,
								position = Position,
								soldier_list = SoldierList1
							},
			
			%3.保存建筑信息.
			CopyId!{'king_dun_set_building_info', BuildingData1}
	end.

%% 创建士兵.
create_mon_soldier([], NewSoldList, _SceneId, _CopyId, _Position, _SoldierLen) ->
	NewSoldList;
create_mon_soldier([Soldier|_SoldList], NewSoldList, SceneId, CopyId, Position, SoldierLen) ->
	SoldierId = Soldier#king_dun_soldier.mid,
	{X, Y} = data_multi_king_dun_config:get_soldier_position(Position, SoldierLen),
	AutoId = 
		mod_mon_create:create_mon(SoldierId, 
									   SceneId, 
									   X, 
									   Y, 
									   1, 
									   CopyId, 
									   1, 
									  [{group, 1}]),
	Soldier1 = Soldier#king_dun_soldier{auto_id = AutoId},
	NewSoldList1 = NewSoldList ++ [Soldier1],
	create_mon_soldier(_SoldList, NewSoldList1, SceneId, CopyId, Position, SoldierLen-1).

%% 创建升级后的建筑.
create_upgrade_building(BuildingId, KillMonList, SceneId, CopyId, Position) ->
	
	%1.杀死旧的建筑和士兵.
	FunKillMon = fun(MonId) ->
            lib_mon:clear_scene_mon_by_ids(SceneId, [], 1, [MonId])
		end,
	[FunKillMon(MonAutoId)||MonAutoId<-KillMonList],

	%2.生成新的建筑.	
	create_building(Position, BuildingId, SceneId, CopyId).

%% 升级怪物技能.
create_upgrade_skill(MonIdList, SkillList) ->
	%1.得到真实的技能.
	FunGetSkill = 
		fun({SkillId, SkillLevel}, GetList) ->
			{_SkillId, _Pro, _Score} = data_multi_king_dun_config:get_skill({SkillId, SkillLevel}),
			if
				_Pro == 0 ->
					GetList;
				is_integer(_SkillId) ->
					GetList++[{_SkillId, _Pro}];
				true ->
					GetList
			end
		end,
	SkillList1 = lists:foldl(FunGetSkill, [], SkillList),
	SkillList2 = [{skill, SkillList1}],
	
	%2.得到修改的属性.
	FunGetAtrrList = 
		fun({SkillId, SkillLevel}, GetList) ->
			{_AtrrType, _Level, _Score} = data_multi_king_dun_config:get_skill({SkillId, SkillLevel}),
			case is_atom(_AtrrType) of
				true -> 					
					GetList++[{_AtrrType, _Level}];
				false ->
					GetList
			end
		end,
	AtrrList = lists:foldl(FunGetAtrrList, [], SkillList),
	AtrrList2 = SkillList2 ++ AtrrList,
	
	%3.修改怪物属性.
	FunChangeMon = 
		fun(MonId) ->
			lib_mon:change_mon_attr(MonId, 235, AtrrList2)
		end,	
	[FunChangeMon(MonId)|| MonId<-MonIdList],
	ok.

%% 设置波数.
set_level(Status, Level) ->
	PlayerLevel = Status#player_status.lv,
	OpenLevelList = data_king_dun_config:get_config(open_level_list),
	DungeonPid = Status#player_status.copy_id,
	
	%1.判断设置的波数是否合法.
	IsGoodLevel = 
		case lists:member(Level, OpenLevelList) of 
        	true ->
				true;
			false ->
				false
		end,
	
	%2.判断玩家等级是否足够.
	IsGoodPlayerLevel =  
		if 
			(PlayerLevel >= 50) and (Level =< 1) ->
			   true;
			(PlayerLevel >= 54) and (Level =< 10) ->
			   true;
			(PlayerLevel >= 56) and (Level =< 20) ->
			   true;
			(PlayerLevel >= 58) and (Level =< 30) ->
			   true;
			(PlayerLevel >= 60) and (Level =< 40) ->
			   true;
			(PlayerLevel >= 65) and (Level =< 50) ->
			   true;
			true ->
				false
		end,

	%3.发送给玩家.
	if 
		IsGoodLevel and IsGoodPlayerLevel ->
		    case is_pid(DungeonPid) of
		        false -> false;
		        true -> DungeonPid ! {'king_dun_set_level', Level}
		    end;
		true ->
		    {ok, BinData} = pt_613:write(61300, [0]),
			lib_server_send:send_one(Status#player_status.socket, BinData)			
	end.

%% 获取波数.
get_level(DungeonPid) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> DungeonPid ! 'king_dun_get_level'
    end.

%% 获取积分和经验.
get_score(DungeonPid) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> DungeonPid ! 'king_dun_get_score'
    end.

%% 提前召唤.
call_mon(DungeonPid) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> DungeonPid ! 'king_dun_call_mon'
    end.

%% 升级建筑.
upgrade_building(DungeonPid, [PlayerId, PlayerName, MonAutoId, NextMonMid]) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> DungeonPid ! {'king_dun_upgrade_building', 
					[PlayerId, PlayerName, MonAutoId, NextMonMid]}
    end.

%% 升级技能.
upgrade_skill(DungeonPid, [PlayerId, PlayerName, MonAutoId, SkillId, SkillLevel]) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> DungeonPid ! {'king_dun_upgrade_skill', 
					[PlayerId, PlayerName, MonAutoId, SkillId, SkillLevel]}
    end.

%% 获取建筑信息.
get_building(DungeonPid) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> DungeonPid ! 'king_dun_get_building'
    end.

%% 得到塔防副本状态.
get_king_state() ->	
    case get("king_dun_state") of
        undefined ->
			NowTime = util:unixtime(),
			KingState = #king_dun_state{last_begin_time = NowTime},
			put("king_dun_state", KingState),
			get("king_dun_state");
        State -> 
			State
    end.

%% 设置塔防副本状态.
set_king_state(KingDunState) ->
	put("king_dun_state", KingDunState).

%% 保存塔防副本状态.
save_king_state([]) ->
	skip;
save_king_state([SaveData|SaveList]) ->
	{Type, Data} = SaveData, 
	KingDunState = get_king_state(),
	KingDunState2 = 
		case Type of
			%1.副本是否开始了.
			is_start ->
				KingDunState#king_dun_state{is_start = Data};
			
			%2.经验.
			exp ->
				KingDunState#king_dun_state{exp = Data};
			
			%3.增加经验.
			add_exp ->
				NewData = KingDunState#king_dun_state.exp + Data,
				KingDunState#king_dun_state{exp = NewData};

			%4.积分.
			score ->
				KingDunState#king_dun_state{score = Data};			
			
			%5.增加积分.
			add_score ->
				NewData = KingDunState#king_dun_state.score + Data,
				KingDunState#king_dun_state{score = NewData};

			%6.敌对怪物列表.
			enemy_mon_list ->
				KingDunState#king_dun_state{enemy_mon_list = Data};			

			%7.建筑列表.
			building_list ->
				KingDunState#king_dun_state{building_list = Data};
			
			%8.上一波开始时间.
			last_begin_time ->
				KingDunState#king_dun_state{last_begin_time = Data};
			
			%9.创建怪物定时器.
			create_mon_timer ->
				KingDunState#king_dun_state{create_mon_timer = Data};
			
			%10.创建者的id.
			owner_id ->
				KingDunState#king_dun_state{owner_id = Data};
			
			%11.已完成的最大波数.
			finish_level ->
				KingDunState#king_dun_state{finish_level = Data};
			
			%12.已完成的最大波数花费的时间.
			finish_time ->
				KingDunState#king_dun_state{finish_time = Data};
			
			%13.历史已完成的最大波数.
			max_level ->
				KingDunState#king_dun_state{max_level = Data};
			
			%14.创建怪物进程列表.
			create_pid_list ->
				KingDunState#king_dun_state{create_pid_list = Data};
			
			%15.增加创建怪物进程列表.
			add_create_pid ->
				NewData = KingDunState#king_dun_state.create_pid_list ++ Data,
				KingDunState#king_dun_state{create_pid_list = NewData};
			
			%16.删除创建怪物进程列表.
			del_create_pid ->
				OldData = KingDunState#king_dun_state.create_pid_list,
				NewData = lists:keydelete(Data, 1, OldData),
				KingDunState#king_dun_state{create_pid_list = NewData};
			
			%17.容错处理.
			_ ->
				KingDunState
		end,
	set_king_state(KingDunState2),
	save_king_state(SaveList).

%% 发送塔防副本积分和经验.
send_score(State) ->
	KingDunState = get_king_state(),
	Exp = KingDunState#king_dun_state.exp,
	Score = KingDunState#king_dun_state.score,
	
    {ok, BinData} = pt_613:write(61302, [Score, Exp]),
	RoleList = State#dungeon_state.role_list,
    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData) || Role <- RoleList].

%% 更新塔防副本排行榜.
update_rank(PlayerStatus, _State) ->
	Id = PlayerStatus#player_status.id, 
	NickName = PlayerStatus#player_status.nickname,
	KingDunState = get_king_state(),
	FinishLevel1 = KingDunState#king_dun_state.finish_level,
	FinishTime = KingDunState#king_dun_state.finish_time,

	Sql1 = io_lib:format(?sql_select_rank_king_dungeon,[Id]),
	Sql2 = io_lib:format(?sql_insert_rank_king_dungeon,
						 [Id, NickName, FinishLevel1, FinishTime]),
	case db:get_row(Sql1) of
		[] -> 
			catch db:execute(Sql2);
		[Level, Time] ->
			if 
				FinishLevel1 > Level ->
				   catch db:execute(Sql2);
				FinishLevel1 == Level andalso Time > FinishTime ->
				   catch db:execute(Sql2);
				true->
					skip
			end
	end.

%% 得到士兵的自增ID.
get_soldier_auto_id([], IdList) ->
	IdList;
get_soldier_auto_id([Soldier|_SoldierList], IdList) ->
	IdList1 = IdList ++ [Soldier#king_dun_soldier.auto_id],
	get_soldier_auto_id(_SoldierList, IdList1).	

%% 发送塔防副本通过20,30,40,50的传闻.
send_notice(Level, PlayerId) ->
    case Level =:= 10 of
	true -> lib_qixi:update_player_task(PlayerId, 10, 1);
	false -> []
    end,
	case lists:member(Level, [20, 30, 40, 50]) of
        true ->
			case lib_player:get_player_info(PlayerId) of
                PlayerStatus when is_record(PlayerStatus, player_status)-> 
					lib_chat:send_TV({all},0,2, ["tafang", 1,
									 PlayerStatus#player_status.id,
									 PlayerStatus#player_status.realm,
									 PlayerStatus#player_status.nickname, 
									 PlayerStatus#player_status.sex, 
									 PlayerStatus#player_status.career, 
									 PlayerStatus#player_status.image,
									 Level]);
                _Other -> 
					skip
            end;
		false ->
			skip
	end.

%% 获得特殊技能
get_special_skill(_Mid, []) -> ok;
get_special_skill(Mid, [Id]) -> 
    T = case get({"extend_skill", Id}) of
        undefined -> 0;
        Num -> Num
    end,
    case T >= 3 of
        true -> skip;
        false -> 
            SkillList = [502004,502005,502006,502007,502008,502009],
            SkillId = case lists:member(Mid, [36105,36110,36115,36120,36125,36130,36135,36140,36145,36150]) of 
                true -> lists:nth(util:rand(1, 6), SkillList);
                false -> 
                    case util:rand(1, 1000) < 30 of
                        true ->  lists:nth(util:rand(1, 6), SkillList);
                        false -> 0
                    end
            end,
            case SkillId == 0 of
                true -> 0;
                false ->
                    put({"extend_skill", Id}, T+1), 
                    {ok, BinData1} = pt_130:write(13034, [1, [{1,SkillId}]]),
                    lib_server_send:send_to_uid(Id, BinData1)
            end
    end;
get_special_skill(Mid, Ids) -> 
    N = util:rand(1, length(Ids)),
    Id = lists:nth(N, Ids),
    get_special_skill(Mid, [Id]).

%% 写日志.
log(DunState, PlayerId, PlayerLevel, CombatPower) ->
	BeginTime = DunState#dungeon_state.time,
	LogoutType = DunState#dungeon_state.logout_type,
	KingDunState = get_king_state(),
	FinishLevel = KingDunState#king_dun_state.finish_level,
	FinishTime = KingDunState#king_dun_state.finish_time,
	PlayerList = DunState#dungeon_state.role_list,
	MeberIdList = [Player#dungeon_player.id|| Player <- PlayerList],
	
	%得到日志建筑列表.
	BuildingList = KingDunState#king_dun_state.building_list,
    LogBuildingList = [{Building#king_dun_building.position, Building#king_dun_building.mid}
						  || Building <- BuildingList],

	%1.写日志.
	log:log_king_dungeon(PlayerId, 
						PlayerLevel, 
						2,
						FinishLevel, 
						FinishTime,
						MeberIdList, 
						BeginTime,
						LogoutType, 
						CombatPower,
						[],
						LogBuildingList),
	
	%2.经验材料召回活动.
	lib_off_line:add_off_line_count(PlayerId, 12, 1, FinishLevel),
	
	%3.关闭创建怪物进程.
	kill_create_processes(),
	ok.

%% 关闭创建怪物进程.
kill_create_processes() ->
	KingDunState = get_king_state(),
	CreatePidlist = KingDunState#king_dun_state.create_pid_list,
	FunKill = 
		fun(PidList) ->
		    [exit(Pid, kill) || Pid<-PidList]
		end,
	[FunKill(PidList) || {_MonId, PidList}<-CreatePidlist],
	save_king_state([{create_pid_list, []}]).