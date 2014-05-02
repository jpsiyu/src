%%------------------------------------------------------------------------------
%% @Module  : lib_fly_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2013.3.7
%% @Description: 飞行副本逻辑
%%------------------------------------------------------------------------------


-module(lib_fly_dungeon).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-include("fly_dungeon.hrl").
-include("sql_rank.hrl").


%% 公共函数：外部模块调用.
-export([
		 kill_npc/4,       %% 杀死怪物事件.
		 enter_scene/5,    %% 切换场景.
		 create_scene/2,   %% 创建副本场景.
		 create_mon/3,     %% 创建怪物.
		 get_level/2,      %% 获取副本难度.
		 get_score/1,      %% 得到积分.
		 get_star/1,       %% 得到星星.
		 get_yin_yang/1,   %% 得到阴阳BOSS值.
		 check_add_score/2,%% 检测增加积分.
		 get_fly_state/0,  %% 得到副本状态.
		 set_fly_state/1,  %% 设置副本状态.
		 save_fly_state/1, %% 保存副本状态.
		 get_time/2,       %% 得到计时.
		 show_time/3,      %% 显示时间.
		 stop_time/2,      %% 停止时间.
		 log/4,            %% 写日志.
		 update_rank/2     %% 更新排行榜.
]).


%% --------------------------------- 公共函数 ----------------------------------


%% 杀怪事件.
kill_npc([KillMonId|_OtherIdList], _MonAutoId, SceneId, State) ->
	%1.检测增加积分.
	%check_add_score(KillMonId, State),
	
	%2.检测增加时间.
	add_time(KillMonId, State),
	
	%3.检测第三层小怪击杀数量.
	check_3_mon(KillMonId, SceneId),
	State.

%% 切换场景.
enter_scene(DungeonPid, Uid, SceneId, NowSceneId, State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_FLY ->
			DungeonPid ! {'fly_dun_enter_scene', Uid, SceneId, NowSceneId};
        _ -> 
			ok
    end.

%% 创建塔防副本场景
create_scene(SceneId, State) ->
	CopyId = self(),

	%1.修改副本场景ID.
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

	%2.创建怪物.
	FlyDunState = get_fly_state(),
	DunLevel = FlyDunState#fly_dun_state.level,
	CreateData = [SceneId, DunLevel],
	mod_scene_agent:apply_cast(SceneId, mod_mon_create, create_mon_fly_dungeon, 
							   [[?CREATE_ENEMY_MON, CopyId, CreateData]]),
	
	%3.得到场景的激活条件
	RequirementList = data_fly_dun_config:get_requirement(DunLevel),
	
	%4.保存副本等级.
    NewState = State#dungeon_state{scene_requirement_list = RequirementList,
								   scene_list = NewSceneList, 
								   level = DunLevel},
    {SceneId, NewState}.

%% 创建怪物.
create_mon(Type, CopyId, Data) ->
	case Type of
		%1.创建敌对怪物.
		?CREATE_ENEMY_MON ->
			[SceneId, Level] = Data,
			MonList = data_fly_dun_config:get_mon(SceneId, Level),
			create_enemy_mon(MonList, SceneId, CopyId);
		
		%2.创建第三层BOSS小怪.
		?CREATE_3_MON ->
			%1.杀掉BOSS.
			[SceneId, X, Y, BossId] = Data,
            lib_mon:clear_scene_mon_by_mids(SceneId, [], 1, [BossId]),
			
			%2.创建小怪.
			MonId = data_fly_dun_config:get_3_mon_id(BossId),
			MonList = [{MonId,X,Y},{MonId,X-1,Y},{MonId,X,Y-1},{MonId,X+1,Y},{MonId,X,Y+1}],
			create_enemy_mon2(MonList, SceneId, CopyId);
		
		%3.容错处理.
		_ ->
			skip
	end.

%% 创建敌对怪物.
create_enemy_mon([], _SceneId, _CopyId) ->
	skip;
create_enemy_mon([{MonId, X, Y} | MonList], SceneId, CopyId) ->	
    mod_mon_create:create_mon(MonId, SceneId, X, Y, 1, CopyId, 1, []),
	create_enemy_mon(MonList, SceneId, CopyId).

%% 创建敌对怪物.
create_enemy_mon2([], _SceneId, _CopyId) ->
	skip;
create_enemy_mon2([{MonId, X, Y} | MonList], SceneId, CopyId) ->	
	mod_mon_create:create_mon(MonId, SceneId, X, Y, 1, CopyId, 1, [{auto_att, 1}]),
	create_enemy_mon2(MonList, SceneId, CopyId).

%% 获取副本难度.
get_level(PlayerId, DungeonDataPid) ->
	DunLevel = gen_server:call(DungeonDataPid , {'fly_dun_get_level', PlayerId}),
	save_fly_state([{level, DunLevel}]).

%% 得到积分.
get_score(PlayerId) ->
	FlyDunState = get_fly_state(),
	{ok, BinData} = pt_610:write(61070, [0, FlyDunState#fly_dun_state.score]),
	lib_server_send:send_to_uid(PlayerId, BinData).

%% 得到星星.
get_star(PlayerId) ->
	FlyDunState = get_fly_state(),
	{ok, BinData} = pt_610:write(61071, [0, FlyDunState#fly_dun_state.star]),
	lib_server_send:send_to_uid(PlayerId, BinData).

%% 得到阴阳BOSS值.
get_yin_yang(PlayerId) ->
	FlyDunState = get_fly_state(),
	{ok, BinData} = pt_610:write(61074, [FlyDunState#fly_dun_state.yin_value,
										 FlyDunState#fly_dun_state.yang_value]),
	lib_server_send:send_to_uid(PlayerId, BinData).

%% 检测积分.
check_add_score(MonId, State) ->
	Score = data_fly_dun_config:get_mon_score(MonId),
	case Score of
		undefined ->
			skip;
		_ ->
			%1.增加积分.
			RoleList = State#dungeon_state.role_list,
			[add_score(Role#dungeon_player.id, 
					   Role#dungeon_player.pid, Score) || Role <- RoleList]
	end.

%% 检测时间.
add_time(MonId, State) ->
	FlyDunState = get_fly_state(),
	AddTime = data_fly_dun_config:get_mon_time(MonId),
	Resualt = 
	case AddTime of
		undefined ->
			skip;
		
		_ ->
			NewExtandTime1 = FlyDunState#fly_dun_state.extand_time + AddTime,
			EndTime = FlyDunState#fly_dun_state.end_time,
			BeginTime = FlyDunState#fly_dun_state.begin_time,
			BeginCountTime1 = EndTime + NewExtandTime1 - util:unixtime(),
			TotalTime1 = EndTime + NewExtandTime1 - BeginTime, 
			
			case BeginCountTime1 > 0 of
				true ->					
					{BeginCountTime1, NewExtandTime1, TotalTime1};
				false ->
					skip
			end
	end,
	case Resualt of
		{BeginCountTime, NewExtandTime, TotalTime} ->
			%1.关闭上一层的定时器.
			CloseTimer = FlyDunState#fly_dun_state.close_timer,
			if 
				is_reference(CloseTimer) ->
					erlang:cancel_timer(CloseTimer);
				true ->
					skip
			end,

			%2.重新设置定时器.
			CloseTimer2 = erlang:send_after((BeginCountTime + 5)*1000, 
											self(), 
											dungeon_time_end),
			
			%3.保存数据.
			save_fly_state([{extand_time, NewExtandTime}, 
							{close_timer, CloseTimer2}]),
			
			%4.发送给玩家.
		    {ok, BinData} = pt_610:write(61073, [AddTime, BeginCountTime, TotalTime, 2]),
			RoleList = State#dungeon_state.role_list,
		    [lib_server_send:send_to_uid(Role#dungeon_player.id, 
										 BinData) || Role <- RoleList];
		_->
			skip
	end.

%% 增加积分.
add_score(PlayerId, PlayerPid, Score) ->
	%1.计算总积分.
	save_fly_state([{add_score, Score}]),
	FlyDunState = get_fly_state(),
	TotalScore = FlyDunState#fly_dun_state.score, 

	%2.发给玩家副本积分.
	if Score > 0 ->
			gen_server:cast(PlayerPid, {'set_data', [{add_fbpt2, Score}]});
	    true ->
			skip
	end,

	{ok, BinData} = pt_610:write(61070, [Score, TotalScore]),
	lib_server_send:send_to_uid(PlayerId, BinData).

%% 检测第三层小怪击杀数量.
check_3_mon(KillMonId, SceneId) ->
	CopyId = self(),
	FlyDunState = get_fly_state(),
	BossId = FlyDunState#fly_dun_state.boss_3_id,
	
	%1.检测小怪数量.
	NowCount = 
		case BossId of
			0 ->
				0;
			_BossId ->
				MonCount = FlyDunState#fly_dun_state.mon_3_count,
				MonId = data_fly_dun_config:get_3_mon_id(BossId),
				case MonId == KillMonId of
					true ->
						case MonCount == 4 of
							true ->
								5;
							false ->
								1
						end;
					false ->
						0
				end
		end,

	%2.创建怪物.
	case NowCount of
		5 ->
			%%创建BOSS.
			BossHP = FlyDunState#fly_dun_state.boss_3_hp,
			X = FlyDunState#fly_dun_state.boss_3_x,
			Y = FlyDunState#fly_dun_state.boss_3_y,
            lib_mon:sync_create_mon(BossId, SceneId, X, Y, 1, CopyId, 1, [{hp, BossHP}]),

			save_fly_state([{mon_3_count, 0},
							{boss_3_hp, 0},
							{boss_3_id, 0}]);
		1 ->
			save_fly_state([{add_mon_3_count, 1}]);
		_ ->
			skip
	end.

%% 得到副本状态.
get_fly_state() ->	
    case get("fly_dun_state") of
        undefined ->
			FlyDunState = #fly_dun_state{},
			put("fly_dun_state", FlyDunState),
			get("fly_dun_state");
        State -> 
			State
    end.

%% 设置副本状态.
set_fly_state(FlyDunState) ->
	put("fly_dun_state", FlyDunState).

%% 保存副本状态.
save_fly_state([]) ->
	skip;
save_fly_state([SaveData|SaveList]) ->
	{Type, Data} = SaveData, 
	FlyDunState = get_fly_state(),
	FlyDunState2 = 
		case Type of
			%1.是否开始.
			is_start ->
				FlyDunState#fly_dun_state{is_start = Data};
			
			%2.积分.
			score ->
				FlyDunState#fly_dun_state{score = Data};
			
			%3.星星.
			star ->
				FlyDunState#fly_dun_state{star = Data};
			
			%4.难度.
			level ->
                MinData = min(12, Data),
				FlyDunState#fly_dun_state{level = MinData};
			
			%4.难度.
			add_level ->
				NewData = FlyDunState#fly_dun_state.level + Data,
				case NewData >= 12 of
					true -> NewData2 = 12;
					false -> NewData2 = NewData
				end,
				FlyDunState#fly_dun_state{level = NewData2};
			
			%5.增加积分.
			add_score ->
				NewData = FlyDunState#fly_dun_state.score + Data,
				FlyDunState#fly_dun_state{score = NewData};
			
			%6.星星.
			add_star ->
				NewData = FlyDunState#fly_dun_state.star + Data,
				FlyDunState#fly_dun_state{star = NewData};
			
			%7.已经进过的场景.
			enter_id_list ->
				NewData = FlyDunState#fly_dun_state.enter_id_list ++ [Data],
				FlyDunState#fly_dun_state{enter_id_list = NewData};
			
			%8.完成的场景.
			finish_id_list ->
				NewData = FlyDunState#fly_dun_state.finish_id_list ++ [Data],
				FlyDunState#fly_dun_state{finish_id_list = NewData};
			
			%9.开始的时间.
			begin_time ->
				FlyDunState#fly_dun_state{begin_time = Data};
			
			%10.结束时间.
			end_time ->
				FlyDunState#fly_dun_state{end_time = Data};
			
			%11.增加时间.
			extand_time ->
				FlyDunState#fly_dun_state{extand_time = Data};
			
			%12.关闭副本定时器.
			close_timer ->
				FlyDunState#fly_dun_state{close_timer = Data};
			
			%13.阴BOSS值.
			yin_value ->
				FlyDunState#fly_dun_state{yin_value = Data};
			
			%14.阳BOSS值.
			yang_value ->
				FlyDunState#fly_dun_state{yang_value = Data};
			
			%15.第三层BOSS的血量.
			boss_3_hp ->
				FlyDunState#fly_dun_state{boss_3_hp = Data};
			
			%16.第三层BOSS的ID.
			boss_3_id ->
				FlyDunState#fly_dun_state{boss_3_id = Data};
			
			%17.第三层BOSS的X坐标.
			boss_3_x ->
				FlyDunState#fly_dun_state{boss_3_x = Data};
			
			%18.第三层BOSS的Y坐标.
			boss_3_y ->
				FlyDunState#fly_dun_state{boss_3_y = Data};			

			%19.第三层小怪数量.
			mon_3_count ->
				FlyDunState#fly_dun_state{mon_3_count = Data};
			
			%20.第三层小怪数量.
			add_mon_3_count ->
				NewData = FlyDunState#fly_dun_state.mon_3_count + Data,
				FlyDunState#fly_dun_state{mon_3_count = NewData};
			
			%21.容错处理.
			_ ->
				FlyDunState
		end,
	set_fly_state(FlyDunState2),
	save_fly_state(SaveList).

%% 得到计时.
get_time(PlayerId, SceneId) ->
	FlyDunState = get_fly_state(),
	EndTime = FlyDunState#fly_dun_state.end_time,
	BeginTime = FlyDunState#fly_dun_state.begin_time,
	ExtandTime = FlyDunState#fly_dun_state.extand_time,
	TotalTime = EndTime + ExtandTime - BeginTime,
	BeginCountTime = EndTime + ExtandTime - util:unixtime(),

	Result = 
    case lists:member(SceneId, FlyDunState#fly_dun_state.enter_id_list) of
        true ->
			case lists:member(SceneId, FlyDunState#fly_dun_state.finish_id_list) of
				true ->
					[BeginCountTime, TotalTime, 1];
				false ->
					[BeginCountTime, TotalTime, 2]
			end;
        false ->
			skip
	end,

	%2.发送结果给客户端.
	case Result of
		[Time, TotalTime2, IsStart] ->
			{ok, BinData} = pt_610:write(61073, [0, Time, TotalTime2, IsStart]),
			lib_server_send:send_to_uid(PlayerId, BinData);
		_ ->
			skip
	end.

%% 显示计时.
show_time(PlayerId, SceneId, _NowSceneId) ->
	FlyDunState = get_fly_state(),
	EndTime = FlyDunState#fly_dun_state.end_time,
	BeginTime = FlyDunState#fly_dun_state.begin_time,
	ExtandTime = FlyDunState#fly_dun_state.extand_time,
	TotalTime = EndTime + ExtandTime - BeginTime,
	BeginCountTime = EndTime + ExtandTime - util:unixtime(),

	Result = 
    case lists:member(SceneId, FlyDunState#fly_dun_state.enter_id_list) of
        true ->
			case lists:member(SceneId, FlyDunState#fly_dun_state.finish_id_list) of
				true ->
					[BeginCountTime, TotalTime, 1];
				false ->
					[BeginCountTime, TotalTime, 2]
			end;
        false ->
			%1.关闭上一层的定时器.
			CloseTimer = FlyDunState#fly_dun_state.close_timer,
			if 
				is_reference(CloseTimer) ->
					erlang:cancel_timer(CloseTimer);
				true ->
					skip
			end,

			%2.重新设置定时器.
			CountTime = data_fly_dun_config:get_scene_time(SceneId),
			CloseTimer2 = erlang:send_after((CountTime + 5)*1000, 
											self(), 
											dungeon_time_end),
			
			%3.保存数据.
			NowTime = util:unixtime(),
			save_fly_state([{enter_id_list, SceneId},
							{end_time, NowTime+CountTime},
							{begin_time, NowTime}, 
							{extand_time, 0}, 
							{close_timer, CloseTimer2}]),
			[CountTime, CountTime, 2]
	end,

	%2.发送结果给客户端.
	case Result of
		[Time, TotalTime2, IsStart] ->
			{ok, BinData} = pt_610:write(61073, [0, Time, TotalTime2, IsStart]),
			lib_server_send:send_to_uid(PlayerId, BinData);
		_ ->
			skip
	end.

%% 停止时间.
stop_time(SceneId, State) ->
	FlyDunState = get_fly_state(),	
	EndTime = FlyDunState#fly_dun_state.end_time,
	BeginTime = FlyDunState#fly_dun_state.begin_time,
	ExtandTime = FlyDunState#fly_dun_state.extand_time,
	TotalTime = EndTime + ExtandTime - BeginTime,	
	BeginCountTime = EndTime  + ExtandTime - util:unixtime(),

    case lists:member(SceneId, FlyDunState#fly_dun_state.enter_id_list) of
        true ->			
			case lists:member(SceneId, FlyDunState#fly_dun_state.finish_id_list) of
				true ->
					skip;
				
				false ->
					%1.关闭上一层的定时器.
					CloseTimer = FlyDunState#fly_dun_state.close_timer,
					if 
						is_reference(CloseTimer) ->
							erlang:cancel_timer(CloseTimer);
						true ->
							skip
					end,
					
					%2.保存数据.
					save_fly_state([{finish_id_list, SceneId},
									{extand_time, 0}, 
									{close_timer, 0}]),
					
					%3.更新显示计时.
					{ok, BinData} = pt_610:write(61073, [0, BeginCountTime, TotalTime, 1]),
					RoleList = State#dungeon_state.role_list,
					[lib_server_send:send_to_uid(Role#dungeon_player.id, 
												 BinData) || Role <- RoleList],
				
				    %4.发送增加星星.
				    send_star(BeginCountTime, SceneId, State)
			end;
        false ->
			skip
	end.

%% 发送增加星星.
send_star(TotalTime, SceneId, State)->
	RoleList = State#dungeon_state.role_list,
	StartTime = data_fly_dun_config:get_star_time(SceneId),
	
	case TotalTime >= StartTime of
		true ->			
			%1.增加星星.
			save_fly_state([{add_star, 1}]),
			
			%2.如果是最后一层要判断是否增加难度.
			FlyDunState = get_fly_state(),			
			NewStar = FlyDunState#fly_dun_state.star,
			case NewStar of
				5 ->
					save_fly_state([{add_level, 1}]);
				_ ->
					skip
			end,
			
			%3.更新显示计时.
			{ok, BinData} = pt_610:write(61071, [1, NewStar]),
			[lib_server_send:send_to_uid(Role#dungeon_player.id, BinData)||Role<-RoleList];	
		
		false ->
			skip
	end,
	
	%2.发送最后结算.
	case SceneId of
		227 ->
			FlyDunState2 = get_fly_state(),
			Level = FlyDunState2#fly_dun_state.level,
			NewStar2 = FlyDunState2#fly_dun_state.star,

			IsNextLevel = 
				case NewStar2 of
					5 ->
					save_fly_state([{star, 1}]),
					1;
					_ ->
						0
				end,

			{ok, BinData2} = pt_610:write(61070, [IsNextLevel, Level]),
			[lib_server_send:send_to_uid(Role#dungeon_player.id, BinData2)||Role<-RoleList];
		
		_ ->
			skip
	end.

%% 写日志.
log(DunState, PlayerId, PlayerLevel, CombatPower) ->
	BeginTime = DunState#dungeon_state.time,
	LogoutType = DunState#dungeon_state.logout_type,
	
	FlyDunState = get_fly_state(),
	Score = FlyDunState#fly_dun_state.score,
	Level = FlyDunState#fly_dun_state.level,
	Star = FlyDunState#fly_dun_state.star,	
	
	%1.写日志.
	log:log_fly_dungeon(PlayerId, PlayerLevel, BeginTime, LogoutType, CombatPower,
						Score, Level, Star).

%% 更新排行榜.
update_rank(PlayerStatus, State) ->
	Id = PlayerStatus#player_status.id, 
	NickName = PlayerStatus#player_status.nickname,
	
	FlyDunState = get_fly_state(),
	Level = FlyDunState#fly_dun_state.level,
	Star = FlyDunState#fly_dun_state.star,
	
	TotalTime = util:unixtime() - State#dungeon_state.time,

	Sql1 = io_lib:format(?sql_select_rank_fly_dungeon,[Id]),
	Sql2 = io_lib:format(?sql_insert_rank_fly_dungeon,
						 [Id, NickName, Level, Star, TotalTime]),
	case db:get_row(Sql1) of
		[] -> 
			catch db:execute(Sql2);
		[Level2, Star2, Time2] ->
			if 
				Level > Level2 ->
				   catch db:execute(Sql2);
				Level == Level2 andalso Star > Star2 ->
				   catch db:execute(Sql2);
				Level == Level2 andalso Star == Star2 andalso Time2 > TotalTime ->
				   catch db:execute(Sql2);
				true->
					skip
			end
	end.