%%------------------------------------------------------------------------------
%% @Module  : mod_multi_king_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.11.21
%% @Description: 多人皇家守卫军塔防副本服务器
%%------------------------------------------------------------------------------


-module(mod_multi_king_dungeon).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-include("king_dun.hrl").
-export([handle_info/2]).


%% --------------------------------- 公共函数 ----------------------------------


%% 创建怪物.
handle_info('king_dun_create_mon', State) ->	
	CopyId = self(),
	SceneId = State#dungeon_state.begin_sid,
	Level = State#dungeon_state.level,
	Level2 = Level + 1,
	KingDunData1 = data_multi_king_dun:get(Level),
	KingDunData2 = data_multi_king_dun:get(Level2),
	MonName = KingDunData1#king_dun_data.mon_name,
	KingDunState = lib_multi_king_dungeon:get_king_state(),
	
	{Level3, Time, CreateMonTimer} = 
		case KingDunData2#king_dun_data.level == 0 of
			true ->
				%已经把怪刷完了.
				{Level, 0, 0};
			false ->								
				Time2 = KingDunData2#king_dun_data.time,				
				CreateMonTimer1 = erlang:send_after(Time2 * 1000, self(), 'king_dun_create_mon'),
				{Level2, Time2, CreateMonTimer1}
		end,
	
	EnemyMonList = KingDunState#king_dun_state.enemy_mon_list,
	OwnerId = KingDunState#king_dun_state.owner_id,
	MonCount = KingDunData1#king_dun_data.mon_count,	
	
	%1.计算提前召唤奖励积分.

	EnemyMon = #king_dun_enemy_mon{
			   		level = Level,
					mon_id = KingDunData1#king_dun_data.mon_id,
					mon_count = MonCount,
					exp = KingDunData1#king_dun_data.exp,
					score = KingDunData1#king_dun_data.score								
				},
	NewEnemyMonList = EnemyMonList ++ [EnemyMon],

	%1.保存塔防副本状态.
	NowTime = util:unixtime(),				
	KingDunState2 = KingDunState#king_dun_state{
						enemy_mon_list = NewEnemyMonList,
						last_begin_time = NowTime,
						create_mon_timer = CreateMonTimer
					},
	lib_multi_king_dungeon:set_king_state(KingDunState2),
	
	%1.召唤怪物.
	CreateData = [Level, SceneId, OwnerId],
    mod_scene_agent:apply_cast(SceneId, lib_multi_king_dungeon, create_mon, [?CREATE_ENEMY_MON, CopyId, CreateData]),
	
	%2.通知客户端.
    {ok, BinData} = pt_613:write(61301, [Level, MonName, Time, Time]),
	RoleList = State#dungeon_state.role_list,
    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData) || Role <- RoleList],
	
	{noreply, State#dungeon_state{level = Level3}};

%% 设置波数.
handle_info({'king_dun_set_level', Level}, State) ->	
	RoleList = State#dungeon_state.role_list,
	
	%1.判断副本是否开始了.
	KingDunState = lib_multi_king_dungeon:get_king_state(),
	{Result, Level2} = 
		case KingDunState#king_dun_state.is_start of
			true ->
				{0, State#dungeon_state.level};
			false ->				
				NowTime = util:unixtime(),
				CopyId = self(),
				KingDunData = data_multi_king_dun:get(Level),
				MonName = KingDunData#king_dun_data.mon_name,
				Time = KingDunData#king_dun_data.time,				
				
				%1.发送波数信息给客户端.
				{ok, BinData} = pt_613:write(61301, [Level, MonName, Time, Time]),
			    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData) || Role <- RoleList],	
				
				%1.开启刷怪定时器.				
				CreateMonTimer = erlang:send_after(Time * 1000, CopyId, 'king_dun_create_mon'),
				
				%2.保存副本数据.
				KingDunState2 = KingDunState#king_dun_state{
									is_start = true, 
									last_begin_time = NowTime,
									create_mon_timer = CreateMonTimer},
				lib_multi_king_dungeon:set_king_state(KingDunState2),
				{1, Level}
		end,

	%2.把结果发给客户端.
    {ok, BinData2} = pt_613:write(61300, [Result]),	
    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData2) || Role <- RoleList],
	
	{noreply, State#dungeon_state{level = Level2}};

%% 获取波数.
handle_info('king_dun_get_level', State) ->
	%1.获取数据.
	Level = State#dungeon_state.level,
	KingDunData = data_multi_king_dun:get(Level),
	
	MonName =
		case Level == 1 of
			true ->
				KingDunData#king_dun_data.mon_name;
			false ->
				%1.名字为当前波的名字，时间为下一波的时间.
				KingDunData2 = data_multi_king_dun:get(Level-1),
				KingDunData2#king_dun_data.mon_name
		end,
	
	%2.获取时间.
	Time1 = KingDunData#king_dun_data.time,
	KindDunState = lib_multi_king_dungeon:get_king_state(),
	NowTime = util:unixtime(),
	Time2 = KindDunState#king_dun_state.last_begin_time + Time1 - NowTime,	
	
	%3.发送给客户端.
    {ok, BinData} = pt_613:write(61301, [Level, MonName, Time2, Time1]),
	RoleList = State#dungeon_state.role_list,
    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData) || Role <- RoleList],
	
	{noreply, State};

%% 获取积分和经验.
handle_info('king_dun_get_score', State) ->
	lib_multi_king_dungeon:send_score(State),
	{noreply, State};

%% 提前召唤.
handle_info('king_dun_call_mon', State) ->	
	Level = State#dungeon_state.level,
	KingDunData = data_multi_king_dun:get(Level),			

	Result =
		case KingDunData#king_dun_data.level == 0 of
			true ->
				0;
			false ->
				KingDunState = lib_multi_king_dungeon:get_king_state(),
				CreateMonTimer = KingDunState#king_dun_state.create_mon_timer,
				%1.召唤怪物.
				if 
					is_reference(CreateMonTimer) ->
						erlang:cancel_timer(CreateMonTimer);
					true ->
						skip
				end,
				self()! 'king_dun_create_mon',
				1
		end,
	
	%2.返回返回提前召唤的结果.
	{ok, BinData} = pt_613:write(61303, [Result]),
	RoleList = State#dungeon_state.role_list,
    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData) || Role <- RoleList],
	
	%3.记住提前召唤怪物的波数.
	{noreply, State};

%% 升级建筑.
handle_info({'king_dun_upgrade_building', Data}, State) ->
	[PlayerId, PlayerName, MonAutoId, NextMonMid] = Data,
	CopyId = self(),
	SceneId = State#dungeon_state.begin_sid,	
	KingDunState = lib_multi_king_dungeon:get_king_state(),
	BuildingList = KingDunState#king_dun_state.building_list,
	Score = KingDunState#king_dun_state.score,
	Score1 = data_multi_king_dun_config:get_building_score(NextMonMid),
	Score2 = Score - Score1,
	case data_mon:get(NextMonMid) of
		[] -> BuildingName = <<"建筑">>;
		Mon -> BuildingName = Mon#ets_mon.name
	end,
	
	%1.判断条件是否满足.
	Result = 
		case KingDunState#king_dun_state.is_start == true of
			false ->
				0;
			true ->
				%1.建筑是否存在.
				case lists:keyfind(MonAutoId, 2, BuildingList) of
					false ->
						0;
					BuildingData ->
						%2.判断升级后的建筑ID是否正确.
						BuildingMid = BuildingData#king_dun_building.mid,
						LastMid = data_multi_king_dun_config:get_building_last_level(NextMonMid),
						case BuildingMid == LastMid of
							false ->
								0;
							true ->
								%3.判断积分是否足够.								
								case Score >= Score1 of
									false ->
										0;
									true ->
										1
								end								
						end
				end
		end,

	%2.升级建筑.
	case Result of
		0 ->
			skip;
		1 ->
			%1.得到建筑和士兵的自增ID.
			BuildingData2 =  lists:keyfind(MonAutoId, 2, BuildingList),
			SoldierList = BuildingData2#king_dun_building.soldier_list,
			SoldierAutoIdList = lib_multi_king_dungeon:get_soldier_auto_id(SoldierList, []),
			KillMonList = [MonAutoId] ++ SoldierAutoIdList,
			Position = BuildingData2#king_dun_building.position,

			%2.删除旧的建筑，保存新的积分.
			BuildingList2 = lists:keydelete(MonAutoId, 2, BuildingList),
			KingDunState2 = KingDunState#king_dun_state{
								building_list = BuildingList2,
								score = Score2
							},
			lib_multi_king_dungeon:set_king_state(KingDunState2),
			lib_multi_king_dungeon:send_score(State),

			%3.发送升级建筑到场景服务器.
			CreateData = [NextMonMid, KillMonList, SceneId, Position],
            mod_scene_agent:apply_cast(SceneId, lib_multi_king_dungeon, create_mon, [?UPGRADE_BUILDING, CopyId, CreateData]),

			%4.通知所有玩家.
		    {ok, BinData1} = pt_613:write(61307, [PlayerName, NextMonMid, BuildingName, Score1]),
			RoleList = State#dungeon_state.role_list,
		    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData1) || Role <- RoleList]			
	end,

	%3.发送结果.
    {ok, BinData2} = pt_613:write(61304, [Result]),
    lib_server_send:send_to_uid(PlayerId, BinData2),	
	{noreply, State};

%% 升级技能.
handle_info({'king_dun_upgrade_skill', Data}, State) ->
	[PlayerId, PlayerName, MonAutoId, SkillId, SkillLevel] = Data,
	CopyId = self(),
	SceneId = State#dungeon_state.begin_sid,
	KingDunState = lib_multi_king_dungeon:get_king_state(),
	BuildingList = KingDunState#king_dun_state.building_list,
	Score = KingDunState#king_dun_state.score,
	{_SkillId, _Pro, Score1} = data_multi_king_dun_config:get_skill({SkillId, SkillLevel}),
	Score2 = Score - Score1,
	SkillName = data_multi_king_dun_config:get_skill_name(SkillId),
	
	%1.判断条件是否满足.
	Result = 
		case KingDunState#king_dun_state.is_start == true of
			false ->
				0;
			true ->
				%1.建筑是否存在.
				case lists:keyfind(MonAutoId, 2, BuildingList) of
					false ->
						0;
					BuildingData ->
						%2.判断技能ID是否正确.
						SkillList = BuildingData#king_dun_building.skill_list,						
						case lists:keyfind(SkillId, 1, SkillList) of
							false ->
								0;
							{_SkillId1, SkillLevel1} ->
								%3.判断技能等级是否正确.
								case SkillLevel1+1 == SkillLevel of
									false ->
										0;
									true ->
										%4.判断积分是否足够.								
										case Score >= Score1 of
											false ->
												0;
											true ->
												1
										end
								end
						end
				end
		end,	

	%2.升级建筑.
	case Result of
		0 ->
			skip;
		1 ->
			%1.修改技能的ID.
			BuildingData2 =  lists:keyfind(MonAutoId, 2, BuildingList),
			SkillList1 = BuildingData2#king_dun_building.skill_list,
			{SkillId2, SkillLevel2} =  lists:keyfind(SkillId, 1, SkillList1),
			SkillList2 = lists:keyreplace(SkillId, 1, SkillList1, {SkillId2, SkillLevel2 + 1}),			
			BuildingList2 = lists:keyreplace(MonAutoId, 2, BuildingList, 
								BuildingData2#king_dun_building{skill_list = SkillList2}),				

			%2.保存服务器状态.
			KingDunState2 = KingDunState#king_dun_state{
								building_list = BuildingList2,
								score = Score2
							},
			lib_multi_king_dungeon:set_king_state(KingDunState2),
			lib_multi_king_dungeon:send_score(State),
			
			%3.得到升级技能怪物的ID.
			SoldierList = BuildingData2#king_dun_building.soldier_list,
			MonIdList = 
				case SoldierList == [] of
					%1.没有士兵就升级建筑.
					true ->
						[BuildingData2#king_dun_building.auto_id];
					%2.升级士兵.
					false ->			
						lib_multi_king_dungeon:get_soldier_auto_id(SoldierList, [])
				end,

			%3.发送升级技能到场景服务器.
			CreateData = [MonIdList, SkillList2],
            mod_scene_agent:apply_cast(SceneId, lib_multi_king_dungeon, create_mon, [?UPGRADE_SKILL, CopyId, CreateData]),

			%4.通知所有玩家.
		    {ok, BinData1} = pt_613:write(61308, [PlayerName, MonAutoId, 
								SkillId, SkillName, SkillLevel, Score1]),
			RoleList = State#dungeon_state.role_list,
		    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData1) || Role <- RoleList]
	end,
	
	%3.发送结果.
    {ok, BinData2} = pt_613:write(61305, [Result, MonAutoId, SkillId]),
    lib_server_send:send_to_uid(PlayerId, BinData2),	
	{noreply, State};

%% 获取建筑信息.
handle_info('king_dun_get_building', State) ->	
	KingDunState = lib_multi_king_dungeon:get_king_state(),
	case KingDunState#king_dun_state.is_start == true of
		false ->
			skip;
		true ->
			BuildingList = KingDunState#king_dun_state.building_list,
			%io:format("BuildingList=~p~n", [BuildingList]),
		    {ok, BinData} = pt_613:write(61306, [BuildingList]),
			RoleList = State#dungeon_state.role_list,
		    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData) || Role <- RoleList]
	end,	
	{noreply, State};

%% 设置建筑信息.
handle_info({'king_dun_set_building_info', BuildingData}, State) ->
	%1.得到数据.
	KingDunState = lib_multi_king_dungeon:get_king_state(),
	BuildingList = KingDunState#king_dun_state.building_list ++ [BuildingData],
				
	%2.保存副本数据.
	KingDunState2 = KingDunState#king_dun_state{building_list = BuildingList},
	lib_multi_king_dungeon:set_king_state(KingDunState2),		
	{noreply, State};

%% 设置创建怪物进程.
handle_info({'king_dun_set_create_pid', MonId, CreatePidList}, State) ->
	lib_kingdom_rush_dungeon:save_king_state([{add_create_pid, [{MonId, CreatePidList}]}]),
	{noreply, State};

%% 删除创建怪物进程.
handle_info({'king_dun_del_create_pid', MonId}, State) ->
	lib_kingdom_rush_dungeon:save_king_state([{del_create_pid, MonId}]),
	{noreply, State};

%% 删除额外的特殊技能
handle_info({'del_kingdom_skill', Reduce, Id}, State) ->
    case get({"extend_skill", Id}) of
        undefined -> skip;
        Num -> 
            case Num - Reduce > 0 of
                true ->  put({"extend_skill", Id}, Num - Reduce);
                false -> put({"extend_skill", Id}, 0)
            end
    end,
	{noreply, State};

%% 增加积分秘籍.
handle_info({'king_dun_add_score', Score}, State) ->
	%1.检验积分.
	Score1 = 
		case Score > 0 of
			true ->
				Score;
			false ->
				0
		end,
	%2.保存积分.
	KingDunState = lib_multi_king_dungeon:get_king_state(),
	Score2 = KingDunState#king_dun_state.score,
	KingDunState2 = KingDunState#king_dun_state{
						score = Score1 + Score2
					},
	lib_multi_king_dungeon:set_king_state(KingDunState2),
	%3.发送客户端.
	lib_multi_king_dungeon:send_score(State),
	{noreply, State};

%% 加载历史已完成的最大波数.
handle_info('king_dun_load_max_level', State) ->
	{noreply, State}.


%% --------------------------------- 私有函数 ----------------------------------
