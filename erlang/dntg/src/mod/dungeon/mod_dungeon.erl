%%%-----------------------------------
%%% @Module  : mod_dungeon
%%% @Author  : zhenghehe
%%% @Created : 2010.07.05
%%% @Description: 副本
%%%-----------------------------------

-module(mod_dungeon).
-behaviour(gen_server).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-include("tower.hrl").
-include("predefine.hrl").

-export([
		 start/8,                %% 创建副本进程，由mod_scene调用.
		 start_tower/6,          %% 创建锁妖塔副本.
		 start_multi_dungeon/5,  %% 创建多人副本进程.
         start_tower_by_level/7  %% 创建跳层锁妖塔副本. 
		 ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% --------------------------------- 公共函数 ----------------------------------

%% 创建副本进程，由mod_scene调用
start(TeamPid, From, DunId, RoleList, Level, SceneId, X, Y) ->
    {ok, Pid} = gen_server:start(?MODULE, [DunId, TeamPid, RoleList, Level, SceneId, X, Y, [[], [], 0, [], 1, 0], 0], []),
    [lib_dungeon:clear_id(role, Id) || {Id, _} <- RoleList],
    [mod_server:set_dungeon_pid(Rpid, Pid) || {_Rid, Rpid, _DunDataPid} <- RoleList, Rpid =/= From],
    Pid.

%% 创建锁妖塔副本进程，由mod_team调用.
start_tower(TeamPid, From, DunId, RoleList, Level, TowerState) ->
    {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
    {ok, Pid} = gen_server:start(?MODULE, [DunId, TeamPid, RoleList, Level, ?MAIN_CITY_SCENE, MainCityX, MainCityY, TowerState, 0], []),
    [lib_dungeon:clear_id(role, Id) || {Id, _} <- RoleList],
    [mod_server:set_dungeon_pid(Rpid, Pid) || {_Rid, Rpid, _DunDataPid} <- RoleList, Rpid =/= From],    
    Pid.

%% 创建多人副本进程，由mod_team调用.
start_multi_dungeon(TeamPid, From, DunId, RoleList, Level) ->
    {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
    {ok, Pid} = gen_server:start(?MODULE, [DunId, TeamPid, RoleList, Level, ?MAIN_CITY_SCENE, MainCityX, MainCityY, [[], [], 0, [], 1, 0], 0], []),
    [lib_dungeon:clear_id(role, Id) || {Id, _} <- RoleList],
    [mod_server:set_dungeon_pid(Rpid, Pid) || {_Rid, Rpid, _DunDataPid} <- RoleList, Rpid =/= From],    
    Pid.

%% 创建锁妖塔副本进程，由mod_team调用.
start_tower_by_level(TeamPid, From, DunId, RoleList, Level, TowerState, ActiveSceneId) ->
    {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
    {ok, Pid} = gen_server:start(?MODULE, [DunId, TeamPid, RoleList, Level, ?MAIN_CITY_SCENE, MainCityX, MainCityY, TowerState, ActiveSceneId], []),
    [lib_dungeon:clear_id(role, Id) || {Id, _} <- RoleList],
    [mod_server:set_dungeon_pid(Rpid, Pid) || {_Rid, Rpid, _DunDataPid} <- RoleList, Rpid =/= From],    
    Pid.

%% --------------------------------- 内部函数 ----------------------------------

init([DunId, TeamPid, RoleList, Level, SceneId, X, Y, TowerState, ActiveSceneId]) ->
    put(msglen, []),
	%1.设置副本关闭的时间.
    DungeonData = data_dungeon:get(DunId),
	%1.玩家列表.
    NewRoleList = [#dungeon_player{id=Rid, pid=Rpid, dungeon_data_pid = DunDataPid} 
				  	|| {Rid, Rpid, DunDataPid} <- RoleList],
	
	%2.增加进入副本总次数.
	FunAddIncrement = 
		fun(PlayerId, DungeonDataPid) ->
			case DungeonData#dungeon.type of
				?DUNGEON_TYPE_STORY ->
					skip;
				_ ->					
					mod_dungeon_data:increment_total_count(DungeonDataPid, PlayerId, DunId)
			end
		end,
	[FunAddIncrement(PlayerId, DungeonDataPid) || {PlayerId, _PlayerPid, DungeonDataPid} <- RoleList],
	
	%2.获取副本数据.
    {SceneRequirementList, KillNpc, SceneList} = lib_dungeon:get_dungeon_data([DunId], [], [], []),
    [EnterSid, ComSid, BeginTime, Rewarder, ExReward, Ratio] = TowerState,
	
    TowerTimer1 = 0,
%	TowerTimer1 = case DungeonData#dungeon.type of 
%		?DUNGEON_TYPE_TOWER ->
%			TowerInfo = data_tower:get(DunId),		
%			TowerTimer = erlang:send_after(TowerInfo#tower.time*1000, self(), close_dungeon),			
%			TowerTimer;
%		_ ->
%			0
%	end,
	
	CloseTime = DungeonData#dungeon.time+10,
    ColseTimer = erlang:send_after(CloseTime*1000, self(), dungeon_time_end),	
	
	%6.新版钱多多.
    ConDun = 
		case DungeonData#dungeon.type of 
	        ?DUNGEON_TYPE_COIN -> 
                %util:cancel_timer(ColseTimer),
				#coin_dun{mon_level = 1,
						  boss_level = 1, 
                          begin_time = util:unixtime()
                      };
			
			?DUNGEON_TYPE_LIAN ->
				lib_lian_dungeon:save_lian_state(close_dungeon_timer, ColseTimer),
				lib_lian_dungeon:save_lian_state(begin_time, util:unixtime()),
				[];
			?DUNGEON_TYPE_FLY ->
				lib_fly_dungeon:save_fly_state([{esid, DunId},
												{begin_time, util:unixtime()}]),
				[FlyRole|_] = RoleList,
				{FlyPlayerId, _FlyPlayerPid, FlyDungeonDataPid} = FlyRole,
				lib_fly_dungeon:get_level(FlyPlayerId, FlyDungeonDataPid),
				[];
            ?DUNGEON_TYPE_DNTK_EQUIP ->
                Scene = data_scene:get(DunId),
                {EquipKillNpc, NpcCount} = lib_equip_energy_dungeon:caculate_npc(Scene#ets_scene.mon),
                lib_equip_energy_dungeon:save_equip_energy_state([ {energy_dun_pid, self()},
                                                                   {dun_id, DunId},
                                                                   {npc_list, EquipKillNpc},
                                                                   {npc_count, NpcCount},
                                                                   {start_time, util:unixtime()},
                                                                   {end_time, util:unixtime() + DungeonData#dungeon.time+10}]),
                [];
	        _ ->
				[]
	    end,

	%7.设置副本状态.
    State = #dungeon_state{
        begin_sid = DunId,
        team_pid = TeamPid,
        time = util:unixtime(),
        role_list = NewRoleList,
        scene_requirement_list = SceneRequirementList,
        kill_npc = KillNpc,
		kill_npc_flag = 0,
        scene_list = SceneList,
        level = Level,
        tower_state = #tower_state{esid = EnterSid, 
								   csid = ComSid, 
								   btime = BeginTime, 
								   rewarder = Rewarder, 
								   exreward = ExReward,
								   close_timer = TowerTimer1,
                                   ratio = Ratio},
        active_scene = ActiveSceneId,
        coin_dun = ConDun,
        out_scene = [SceneId, X, Y],
		type = DungeonData#dungeon.type,
        close_timer = ColseTimer
    },
	
	%8.表示要跳层
    State2 = case ActiveSceneId /= 0 of 
        true -> lib_dungeon:enable_action([ActiveSceneId], State, 0);
        false -> State
    end,
    
    %9.设置副本记录.
    CloseTime2 = 
		case DungeonData#dungeon.type of 
	        ?DUNGEON_TYPE_COIN ->  
				CloseTime+330;
			?DUNGEON_TYPE_LIAN ->
				CloseTime+1800;
	        _ ->
				CloseTime
	    end,
    SetDunRecord = 
		fun(PlayerId) ->
			DunRecoed = #dungeon_record{
				player_id = PlayerId, 
				dungeon_pid = self(),
				scene_id = DunId,
				end_time = util:unixtime() + CloseTime2
			},    
			mod_dungeon_agent:set_dungeon_record(DunRecoed)
		end,
	[SetDunRecord(PlayerId) || {PlayerId, _PlayerPid, _DunDataPid} <- RoleList],

    %% 对连连看副本的一个定时处理
    case DunId == 230 of
        true -> erlang:send_after(10000, self(), 'lian_init_create_mon');
        false -> skip
    end,
    {ok, State2}.


%% ---------------------------- handle_call处理服务 ----------------------------


%% ------------------------------- 副本基础服务 --------------------------------
%% 检查进入副本
%% 这里的SceneId是数据库的里的场景id，不是唯一id
handle_call({check_enter, SceneResId, _Id, _NowScene}, _From, State) ->
	mod_dungeon_base:handle_call({check_enter, SceneResId, _Id, _NowScene}, _From, State);

%% 加入副本服务
handle_call({join, PlayerId, PlayerPid, DungeonDataPid}, _From, State) ->
	mod_dungeon_base:handle_call({join, PlayerId, PlayerPid, DungeonDataPid}, _From, State);

%% 下线5分钟内归队再进副本
handle_call({join_online, Id, Pid, DungeonDataPid}, _From, State) ->
	mod_dungeon_base:handle_call({join_online, Id, Pid, DungeonDataPid}, _From, State);

%% 获取副本时间
handle_call({get_dungeon_time, SceneId, PlayerId, DailyPid}, _From, State) ->
	mod_dungeon_base:handle_call({get_dungeon_time, SceneId, PlayerId, DailyPid}, _From, State);

%% 获取该副本id（第一个场景的资源id）
handle_call('get_begin_sid', _From, State) ->
	mod_dungeon_base:handle_call('get_begin_sid', _From, State);

%% 获取特殊场景时间
handle_call({get_scene_time, SceneId}, _From, State) ->
	mod_dungeon_base:handle_call({get_scene_time, SceneId}, _From, State);

%% 获取怪物的击杀统计.
handle_call({get_kill_count, SceneId}, _From, State) ->
	mod_dungeon_base:handle_call({get_kill_count, SceneId}, _From, State);
	
%% --------------------------------- 宠物副本 ----------------------------------

%% 获取情缘副本tips
handle_call({get_appoint_dungeon_tips}, _From, State) ->
	mod_pet_dungeon:handle_call({get_appoint_dungeon_tips}, _From, State);
	
%% 获取怪物列表.
handle_call({get_mon_list}, _From, State) ->
	mod_pet_dungeon:handle_call({get_mon_list}, _From, State);

%% --------------------------------- 经验副本 ----------------------------------


%% --------------------------------- 爬塔副本 ----------------------------------

%% 锁妖塔累计奖励(下线)(锁妖塔)
handle_call({'total_tower_reward_offline', Status}, _From, State) ->
	mod_tower_dungeon:handle_call({'total_tower_reward_offline', Status}, _From, State);

handle_call(_Request, _From, State) ->
    {noreply, State}.


%% ---------------------------- handle_cast处理服务 ----------------------------


%% --------------------------------- 铜币副本 ----------------------------------

%% 获取新版钱多多副本副本信息
handle_cast({'coin_dungeon_state', Uid}, State) ->
	mod_coin_dungeon:handle_cast({'coin_dungeon_state', Uid}, State);

%% 拾取金币.
%handle_cast({'pick_coin', Uid, PlayerPid, MonId}, State) ->
%	mod_coin_dungeon:handle_cast({'pick_coin', Uid, PlayerPid, MonId}, State);	

%% --------------------------------- 宠物副本 ----------------------------------

%% 怪物变身.
handle_cast({'mon_change_look', Scene, MonId, ChangeFlag}, State) ->
	mod_pet_dungeon:handle_cast({'mon_change_look', Scene, MonId, ChangeFlag}, State);

%% --------------------------------- 爬塔副本 ----------------------------------

%% 获取这一层的奖励(锁妖塔)
handle_cast({'now_level_reward', Uid}, State) ->
	mod_tower_dungeon:handle_cast({'now_level_reward', Uid}, State);


%% 获取新一层的剩余时间(锁妖塔)
handle_cast({'tower_left_time', Uid, DailyPid}, State) ->
	mod_tower_dungeon:handle_cast({'tower_left_time', Uid, DailyPid}, State);

%% 不正常退出，只用于副本管理服务.
handle_cast('close_dungeon', State) ->
    {stop, {kill, State#dungeon_state.scene_list, State#dungeon_state.role_list}, State};

handle_cast(_Msg, State) ->
    {noreply, State}.


%% ---------------------------- handle_info处理服务 ----------------------------


%% ------------------------------- 副本基础服务 --------------------------------

%% 将指定玩家传出副本,不保留个人信息副本进程不让进入
handle_info({quit, PlayerId, FromCode}, State) ->
	mod_dungeon_base:handle_info({quit, PlayerId, FromCode}, State);

%% 设置退出的类型.
handle_info({set_logout_type, LogoutType}, State) ->
	mod_dungeon_base:handle_info({set_logout_type, LogoutType}, State);

%% 副本时间结束.
handle_info(dungeon_time_end, State) -> 
	State1 = State#dungeon_state{logout_type = ?DUN_EXIT_NO_TIME},
	mod_dungeon_base:handle_info(close_dungeon, State1);

%% 设置是否发送副本通关记录.
handle_info({send_record, Flag}, State) ->
	mod_dungeon_base:handle_info({send_record, Flag}, State);

%% 将指定玩家传出副本,不保留个人信息副本进程不让进入
handle_info({clear_role, RoleId}, State) ->
	mod_dungeon_base:handle_info({clear_role, RoleId}, State);

%% 将指定玩家传出副本,保留个人信息的副本进程还让进入
handle_info({out, Rid}, State) ->
	mod_dungeon_base:handle_info({out, Rid}, State);

%% 关闭副本服务进程
handle_info(team_clear, State) ->
	mod_dungeon_base:handle_info(team_clear, State);

%% 关闭副本服务进程
handle_info(role_clear, State) ->
	mod_dungeon_base:handle_info(role_clear, State);

%% 关闭副本服务进程并且踢出所有人
handle_info(close_dungeon, State) ->
	mod_dungeon_base:handle_info(close_dungeon, State);

%% 接收杀怪事件
handle_info({kill_npc, EventSceneId, NpcIdList, BossType, MonAutoId, IsSkip}, State) ->
	case length(State#dungeon_state.role_list) >= 1 of
		true ->
			mod_dungeon_base:handle_info({kill_npc, EventSceneId, NpcIdList, BossType, MonAutoId, IsSkip}, State);
		false ->
			case State#dungeon_state.type of
				?DUNGEON_TYPE_KINGDOM_RUSH ->
					[KillMonId|_OtherIdList] = NpcIdList,
					lib_kingdom_rush_dungeon:kill_princess(KillMonId, State);
				?DUNGEON_TYPE_MULTI_KING ->
					[KillMonId|_OtherIdList] = NpcIdList,
					lib_kingdom_rush_dungeon:kill_princess(KillMonId, State);				
				_Other ->
					skip
			end,
			{noreply, State}
	end;

%% 测试用 -- 直接激活副本场景
handle_info({active, SceneId}, State) ->
	mod_dungeon_base:handle_info({active, SceneId}, State);

%% --------------------------------- 铜币副本 ----------------------------------

%% 刷新一批金币(新版钱多多)
handle_info({'coin_create', PlayerId, PlayerPid}, State) ->
	mod_coin_dungeon:handle_info({'coin_create', PlayerId, PlayerPid}, State);

%% 生成下一波怪物(新版钱多多)
handle_info('coin_dungeon_next_level', State) ->
	mod_coin_dungeon:handle_info('coin_dungeon_next_level', State);

%% 刷新怪物.
handle_info('create_boss', State) ->
	mod_coin_dungeon:handle_info('create_boss', State);
	
%% --------------------------------- 宠物副本 ----------------------------------

%% 怪物随机变身.
handle_info('random_change_look', State) ->
	mod_pet_dungeon:handle_info('random_change_look', State); 

%% 怪物变身还原.
handle_info('turn_back', State) ->
	mod_pet_dungeon:handle_info('turn_back', State);

%% 获取想法.
handle_info('get_pet_dungeon_think', State) ->
	mod_pet_dungeon:handle_info('get_pet_dungeon_think', State);

%% 生成下一个想法.
handle_info('pet_dungeon_next_think', State) ->
	mod_pet_dungeon:handle_info('pet_dungeon_next_think', State);

%% --------------------------------- 爬塔副本 ----------------------------------

%% 锁妖塔每层开始(锁妖塔)
handle_info({'tower_next_level', Id, SceneId, NowSceneId}, State) ->
	mod_tower_dungeon:handle_info({'tower_next_level', Id, SceneId, NowSceneId}, State);

%% 锁妖塔每层奖励结算(锁妖塔)
handle_info({'tower_reward', SceneId, RewardTime}, State) ->
	mod_tower_dungeon:handle_info({'tower_reward', SceneId, RewardTime}, State);

%% 锁妖塔累计奖励(锁妖塔)
handle_info({'total_tower_reward', Uid}, State) ->
	mod_tower_dungeon:handle_info({'total_tower_reward', Uid}, State);

%% 超时全部离开
handle_info('CLOSE_TOWER_DUNGEON', State) ->
	mod_tower_dungeon:handle_info('CLOSE_TOWER_DUNGEON', State);

%% ---------------------------- 皇家守卫军塔防副本 -----------------------------

%% 创建怪物.
handle_info('king_dun_create_mon', State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info('king_dun_create_mon', State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info('king_dun_create_mon', State);
		_ ->
			{noreply, State}
	end;

%% 设置波数.
handle_info({'king_dun_set_level', Level}, State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info({'king_dun_set_level', Level}, State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info({'king_dun_set_level', Level}, State);
		_ ->
			{noreply, State}
	end;

%% 获取波数.
handle_info('king_dun_get_level', State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info('king_dun_get_level', State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info('king_dun_get_level', State);
		_ ->
			{noreply, State}
	end;

%% 获取积分和经验.
handle_info('king_dun_get_score', State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info('king_dun_get_score', State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info('king_dun_get_score', State);
		_ ->
			{noreply, State}
	end;

%% 提前召唤.
handle_info('king_dun_call_mon', State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info('king_dun_call_mon', State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info('king_dun_call_mon', State);
		_ ->
			{noreply, State}
	end;

%% 升级建筑.
handle_info({'king_dun_upgrade_building', Data}, State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info({'king_dun_upgrade_building', Data}, State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info({'king_dun_upgrade_building', Data}, State);
		_ ->
			{noreply, State}
	end;

%% 升级技能.
handle_info({'king_dun_upgrade_skill', Data}, State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info({'king_dun_upgrade_skill', Data}, State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info({'king_dun_upgrade_skill', Data}, State);
		_ ->
			{noreply, State}
	end;

%% 获取建筑信息.
handle_info('king_dun_get_building', State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info('king_dun_get_building', State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info('king_dun_get_building', State);
		_ ->
			{noreply, State}
	end;

%% 设置建筑信息.
handle_info({'king_dun_set_building_info', BuildingData}, State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info({'king_dun_set_building_info', BuildingData}, State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info({'king_dun_set_building_info', BuildingData}, State);
		_ ->
			{noreply, State}
	end;

%% 设置创建怪物进程.
handle_info({'king_dun_set_create_pid', MonId, CreatePidList}, State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info({'king_dun_set_create_pid', MonId, CreatePidList}, State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info({'king_dun_set_create_pid', MonId, CreatePidList}, State);
		_ ->
			{noreply, State}
	end;

%% 删除创建怪物进程.
handle_info({'king_dun_del_create_pid', MonId}, State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info({'king_dun_del_create_pid', MonId}, State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info({'king_dun_del_create_pid', MonId}, State);
		_ ->
			{noreply, State}
	end;
	
%% 删除技能计数器
handle_info({'del_kingdom_skill', Reduce, Id}, State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info({'del_kingdom_skill', Reduce, Id}, State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info({'del_kingdom_skill', Reduce, Id}, State);
		_ ->
			{noreply, State}
	end;

%% 增加积分秘籍.
handle_info({'king_dun_add_score', Score}, State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info({'king_dun_add_score', Score}, State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info({'king_dun_add_score', Score}, State);
		_ ->
			{noreply, State}
	end;

%% 加载历史已完成的最大波数.
handle_info('king_dun_load_max_level', State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			mod_kingdom_rush_dungeon:handle_info('king_dun_load_max_level', State);
		?DUNGEON_TYPE_MULTI_KING ->
			mod_multi_king_dungeon:handle_info('king_dun_load_max_level', State);
		_ ->
			{noreply, State}
	end;

%% ---------------------------- 连连看副本 -----------------------------

%% 随机创建怪物.
handle_info({'lian_dun_random_mon', PossionList, SceneId}, State) ->
	mod_lian_dungeon:handle_info({'lian_dun_random_mon', PossionList, SceneId}, State);

%% 设置怪物信息.
handle_info({'lian_dun_set_mon_info', MonList, IsCalc}, State) ->
	mod_lian_dungeon:handle_info({'lian_dun_set_mon_info', MonList, IsCalc}, State);

%% 计算积分.
handle_info('lian_dun_calc_score', State) ->
	mod_lian_dungeon:handle_info('lian_dun_calc_score', State);	

%% 连连看副本开始刷怪.
handle_info('lian_init_create_mon', State) ->
	mod_lian_dungeon:handle_info('lian_init_create_mon', State);

%% 连连看副本更新积分.
handle_info('lian_get_score', State) ->
	mod_lian_dungeon:handle_info('lian_get_score', State);

%% 连连看副本清怪.
handle_info('lian_clear_mon', State) ->
	mod_lian_dungeon:handle_info('lian_clear_mon', State);

%% ---------------------------- 活动副本 -----------------------------

%% 得到积分.
handle_info({'activity_dun_get_score', PlayerId}, State) ->
	mod_activity_dungeon:handle_info({'activity_dun_get_score', PlayerId}, State);

%% ---------------------------- 飞行副本 -----------------------------

%% 得到积分.
handle_info({'fly_dun_get_score', PlayerId}, State) ->
	mod_fly_dungeon:handle_info({'fly_dun_get_score', PlayerId}, State);

%% 得到星星.
handle_info({'fly_dun_get_star', PlayerId}, State) ->
	mod_fly_dungeon:handle_info({'fly_dun_get_star', PlayerId}, State);

%% 得到计时.
handle_info({'fly_dun_get_time', PlayerId, SceneId}, State) ->
	mod_fly_dungeon:handle_info({'fly_dun_get_time', PlayerId, SceneId}, State);

%% 得到阴阳BOSS值.
handle_info({'fly_dun_get_yin_yang', PlayerId}, State) ->
	mod_fly_dungeon:handle_info({'fly_dun_get_yin_yang', PlayerId}, State);

%% 设置阴BOSS值.
handle_info({'fly_dun_set_yin', Value}, State) ->
	mod_fly_dungeon:handle_info({'fly_dun_set_yin', Value}, State);

%% 设置阳BOSS值.
handle_info({'fly_dun_set_yang', Value}, State) ->
	mod_fly_dungeon:handle_info({'fly_dun_set_yang', Value}, State);

%% 切换场景.
handle_info({'fly_dun_enter_scene', PlayerId, SceneId, NowSceneId}, State) ->
	mod_fly_dungeon:handle_info({'fly_dun_enter_scene', PlayerId, SceneId, NowSceneId}, State);

%% 杀死BOSS.
handle_info({'fly_dun_kill_boss', HP, MonId, SceneId, X, Y}, State) ->
	mod_fly_dungeon:handle_info({'fly_dun_kill_boss', HP, MonId, SceneId, X, Y}, State);


%%　大闹天空－装备副本
%% 发送通关失败数据
handle_info({'extraction_goods', DungeonId, Type}, State) ->
    mod_equip_energy_dungeon:handle_info({'extraction_goods', DungeonId, Type}, State);

%% 封魔录副本
handle_info({'player_die', PS}, State) -> 
     lib_dungeon:player_die(State, PS),
     {noreply, State#dungeon_state{is_die = 1}};

%% handle_info({'player_die', PlayerId}, State) -> 
%%      lib_dungeon:player_die(State, PlayerId),
%%      {noreply, State};
	
handle_info(_Info, State) ->
    {noreply, State}.
    
terminate(normal, State) ->
    MsgLen = get(msglen),
    case length(State#dungeon_state.role_list) > 0 andalso length(MsgLen) > 0 of
        true -> %% 处理没有踢出玩家但是进程被关闭了的信息
            catch util:errlog("mod_dungon terminate error(Reason: normal) MsgLen= ~p,~n Time ~p,~n State ~p~n", [MsgLen, util:unixtime()-State#dungeon_state.time, State]);
        false -> skip
    end,
    TowerState = State#dungeon_state.tower_state,
	LogoutType = State#dungeon_state.logout_type,
    case TowerState#tower_state.esid of
        [] -> skip;
        [{_, LastBeginTime}|_] -> 
            LastLayerTime = util:unixtime() - LastBeginTime,
            [catch lib_tower_dungeon:reward(Id, 0, State#dungeon_state.begin_sid, 
				self(), 0, LastLayerTime, TowerState#tower_state.ratio, 
				LogoutType, 0)||Id <- TowerState#tower_state.max_ids],
            case is_reference(TowerState#tower_state.close_timer) of
                true -> erlang:cancel_timer(TowerState#tower_state.close_timer);
                false -> skip
            end
    end,
    case is_reference(State#dungeon_state.close_timer) of
        true -> erlang:cancel_timer(State#dungeon_state.close_timer);
        false -> skip
    end,
	ok;
terminate(_Reason, State) ->
    catch util:errlog("mod_dungon terminate error Reason: ~p~n State: ~p~n", [_Reason, State]),
   TowerState = State#dungeon_state.tower_state,
   LogoutType = State#dungeon_state.logout_type,
    case TowerState#tower_state.esid of
        [] -> skip;
        [{_, LastBeginTime}|_] -> 
            LastLayerTime = util:unixtime() - LastBeginTime,
            [catch lib_tower_dungeon:reward(Id, 0, State#dungeon_state.begin_sid, 
				self(), 0, LastLayerTime, TowerState#tower_state.ratio,
				LogoutType, 0)||Id <- TowerState#tower_state.max_ids],
            case is_reference(TowerState#tower_state.close_timer) of
                true -> erlang:cancel_timer(TowerState#tower_state.close_timer);
                false -> skip
            end
    end,
    case is_reference(State#dungeon_state.close_timer) of
        true -> erlang:cancel_timer(State#dungeon_state.close_timer);
        false -> skip
    end,
    [mod_scene_agent:apply_cast(
								DunScene#dungeon_scene.id, 
								mod_scene, 
								clear_scene, 
								[DunScene#dungeon_scene.id, self()])|| 
	    DunScene <- State#dungeon_state.scene_list, 
		DunScene#dungeon_scene.id =/= 0],
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
