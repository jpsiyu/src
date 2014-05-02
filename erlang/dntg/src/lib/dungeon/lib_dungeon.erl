%%------------------------------------------------------------------------------
%% @Module  : lib_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.26
%% @Description: 副本逻辑
%%------------------------------------------------------------------------------

-module(lib_dungeon).
-include("sql_dungeon.hrl").
-include("buff.hrl").

%% 公共函数：外部模块调用.
-export([
		get_dungeon_remain_num/3,       %% 获取副本剩余次数.
	    get_dungeon_all_remain_num/3,   %% 获取所有副本剩余次数.
		get_dungeon_name/1,             %% 获取副本名称.		 
        get_dungeon_time/2,             %% 获取副本时间.
        get_outside_scene/1,            %% 获取玩家所在副本的外场景.
        get_scene_time/2,               %% 获取特殊场景时间.
        get_kill_count/2,               %% 获取怪物的击杀统计.
		get_total_count/2,              %% 获取副本总次数.
		get_newer_task/1,               %% 获取进入副本完成的新手任务.
		trans/1,                        %% 获取副本模块的数据.
		minus_dungeon_count/3,          %% 副本剩余次数减一.        
		check_enter/2,                  %% 进入副本.
        join/5,				            %% 主动加入新的角色.
        quit/3,                         %% 角色主动清除.
        set_logout_type/2,              %% 设置退出的类型.
		send_record/2,					%% 设置是否发送副本通关记录.
        clear_id/2,                     %% 清除副本进程.
        clear/2,                        %% 清除副本进程.
        out/2,                          %% 将玩家传出副本.
		clear_role/2,                   %% 将指定玩家传出副本.
        kill_npc/6,                     %% 杀怪事件.
        kill_npc/5,                     %% 杀怪事件.
		add_total_count/3,              %% 增加副本总次数.
		get_dungeon_type/1,             %% 得到副本的类型.
		check_team_condition/2,         %% 检测队伍进入条件.
		check_enter_time/1,	            %% 检测副本进入时间.
        player_die/1,                   %% 玩家在副本中死亡处理（玩家进程调用）
        player_die/2                    %% 玩家在副本中死亡处理（副本进程调用）
    ]).
	
%% 内部函数：副本服务本身调用.
-export([		 
		set_whpt/3,                     %% 设置武魂值.
        get_dungeon_id/1,               %% 获取用场景资源获取副本id. 
		get_dungeon_data/4,             %% 组织副本的基础数据.		
		get_enable/3,                   %% 检查场景激活条件.
		create_scene/2,                 %% 创建副本场景.
		send_out/2,                     %% 传送出副本.
		enable_action/3,                %% 激活副本场景.
		event_action/4,                 %% 检测副本的杀怪完成情况.
		is_in_dungeon/2,                %% 副本的人是否存在.
		send_dungeon_record/3,          %% 发送副本通关结算.
        check_kill_count/2,             %% 检测怪物的击杀统计.
		add_dungeon_record/4,           %% 增加副本通关新纪录.
		quit_reward/3                   %% 退出结算.
%%      tower_next_level/3,             %% 锁妖塔进入下一层.
%%      tower_reward/2,                 %% 锁妖塔每层结算.
%%      total_tower_reward/3,           %% 锁妖塔累计结算.
%%      total_tower_reward_offline/1,   %% 锁妖塔累计结算（下线）.
%%      get_appoint_dungeon_tips/1      %% 获取情缘副本tips.
    ]).

-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
%%-include("record.hrl").
%%-include("appointment.hrl").
%%-include("tower.hrl").

%% -record(ts, {esid = [], csid = [], btime = 0, etime = 0, extand_time = 0, rewarder = [], exreward = 1}).


%% --------------------------------- 公共函数 ----------------------------------

%% 获取副本剩余次数.
get_dungeon_remain_num(PlayerId, DailyPid, DungeonId) ->
    case data_dungeon:get(DungeonId) of
        [] -> 
			{DungeonId, 0, 0};
        Dun ->
            Count = mod_daily:get_count(DailyPid, PlayerId, DungeonId),
            case Count >= Dun#dungeon.count of
                true -> 
					{DungeonId, Dun#dungeon.count, Dun#dungeon.count};
                false -> 
					{DungeonId, Count, Dun#dungeon.count}
            end
    end.

%% 获取所有副本剩余次数.
get_dungeon_all_remain_num(DungeonDataPid, PlayerId, DailyPid) ->

	%1.定义获取所有副本次数的函数.
	Fun = 
		fun(DungeonId) ->
			case data_dungeon:get(DungeonId) of
			    [] -> 
					{DungeonId, 0, 0, 0, 0};
			    Dun ->
					{CoolTime, Score, PassTime} = 
						mod_dungeon_data:get_cooling_time(DungeonDataPid, PlayerId, DungeonId),					
			        Count = mod_daily:get_count(DailyPid, PlayerId, DungeonId),
			        case Count >= Dun#dungeon.count of
			            true -> 
							{DungeonId, 
							 Dun#dungeon.count, 
							 Dun#dungeon.count, 
							 CoolTime, Score, 
							 PassTime};
			            false -> 
							{DungeonId, 
							 Count, 
							 Dun#dungeon.count, 
							 CoolTime, 
							 Score, 
							 PassTime}
			        end
			end
		end,
	%2.执行函数.
	[Fun(DungeonId) || DungeonId <- data_dungeon:get_ids()].

%% 获取副本名称.
get_dungeon_name(DungeonId) ->
    case data_dungeon:get(DungeonId) of
        [] -> <<>>;
        Dun -> Dun#dungeon.name
    end.

%% 获取副本时间
get_dungeon_time(SceneId, PS) ->
    case is_pid(PS#player_status.copy_id) of
        true ->
            gen_server:call(PS#player_status.copy_id, {get_dungeon_time, 
													   SceneId, 
													   PS#player_status.id,
													   PS#player_status.dailypid});
        false ->
            false
    end.

%% 获取玩家所在副本的外场景
get_outside_scene(SceneId) ->
    case get_dungeon_id(SceneId) of
        0 -> false;  %% 不在副本场景
        DungeonId ->  %% 将传送出副本
            DungeonData = data_dungeon:get(DungeonId),
            DungeonData#dungeon.out
    end.

%% 获取副本特殊场景时间
get_scene_time(DungeonPid, SceneResId) ->
    case is_pid(DungeonPid) of
        true ->
            gen_server:call(DungeonPid, {get_scene_time, SceneResId});
        false ->
            false
    end.
    
%% 获取怪物的击杀统计.
get_kill_count(DungeonPid, SceneId) ->
    case is_pid(DungeonPid) of
        true ->
            gen_server:call(DungeonPid, {get_kill_count, SceneId});
        false ->
            false
    end.    

%% 获取副本总次数.
%% RequestPlayerId 请求者ID.
%% PlayerId 请求对象的ID.
get_total_count(DungeonDataPid, PlayerId) ->
	
	%1.定义获取总次数函数.
	FunTotalCount = 
		fun(DungeonId) ->
			TotalCount = mod_dungeon_data:get_total_count(DungeonDataPid,
												PlayerId,
												DungeonId), 
			{DungeonId, TotalCount}
		end,
	CountList = [FunTotalCount(DungeonId) || DungeonId <- data_dungeon:get_ids()],

	{ok, BinData} = pt_610:write(61008, [PlayerId, CountList]),
	lib_server_send:send_to_uid(PlayerId, BinData).

%% 获取进入副本完成的新手任务.
get_newer_task(SceneId) ->
    case SceneId of
        %500 -> {ok, 101270};
        %561 -> {ok, 101730};
        %562 -> {ok, 100441};
        %563 -> {ok, 100950};							
        %564 -> {ok, 102220};
        %565 -> {ok, 102330};
        %566 -> {ok, 101331};
        %567 -> {ok, 101570};
        %568 -> {ok, 101820};							
        %570 -> {ok, 102131};
        %630 -> {ok, 101973};
        %650 -> {ok, 101683};
        %900 -> {ok, 101520};							
        _ ->
            false
    end.

%% 获取副本模块的数据.
%% @return scene 玩家场景ID.
trans(Status) ->
   {ok, Status#player_status.scene}.

%% 副本剩余次数减一.
minus_dungeon_count(PlayerId, DailyPid, DungeonId) ->
    Count = mod_daily:get_count(DailyPid, PlayerId, DungeonId),
    case Count >= 1 of
        true -> 
			mod_daily:set_count(DailyPid, PlayerId, DungeonId, Count-1),
			ok;
        false -> 
			false
    end.

%% 进入副本
check_enter(SceneResId, Status) ->
    gen_server:call(Status#player_status.copy_id, {check_enter, 
												   SceneResId, 
												   Status#player_status.id, 
												   Status#player_status.scene}).

%% 主动加入新的角色
join(DungeonPid, PlayerId, PlayerPid, DungeonDataPid, PlayerCopyId) ->
	%1.清除之前的副本数据.
    clear(role, PlayerCopyId),
    %2.加入新的副本.
    case is_pid(DungeonPid) of
        false -> false;
        true -> gen_server:call(DungeonPid, {join, PlayerId, PlayerPid, DungeonDataPid})
    end.

%% 角色主动清除
quit(DungeonPid, Rid, FromCode) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> 
            %mod_tower_dungeon:total_tower_reward(DungeonPid, Rid, quit),
            DungeonPid ! {quit, Rid, FromCode}
    end.

%% 设置退出的类型.
set_logout_type(DungeonPid, LogoutType) ->
    case is_pid(DungeonPid) of
        false -> 
			false;
        true -> 
            DungeonPid ! {set_logout_type, LogoutType}
    end.

%% 设置是否发送副本通关记录.
send_record(DungeonPid, Flag) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> 
            DungeonPid ! {send_record, Flag}
    end.

%% 清除副本进程
clear_id(Type, Id) when is_integer(Id) andalso Id > 0->
    case lib_player:get_player_info(Id) of
        PlayerStatus when is_pid(PlayerStatus#player_status.copy_id) -> 
			clear(Type, PlayerStatus#player_status.copy_id);
	    _ -> false
    end.
clear(Type, DungeonPid) when is_pid(DungeonPid) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> 
            case Type of
                team -> DungeonPid ! team_clear;
                role -> DungeonPid ! role_clear
            end,
            true
    end;
clear(_Type, _Id) -> false.

%% 将玩家传出副本
out(DungeonPid, Rid) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> DungeonPid ! {out, Rid}
    end.

%% 将指定玩家传出副本.
clear_role(DungeonPid, RoleId) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> DungeonPid ! {clear_role, RoleId}
    end.

%% 杀怪事件
%% IsSkip : 1能跳层， 0 不能跳层
kill_npc(Scene, CopyId, NpcIdList, BossType, MonAutoId, IsSkip) ->
    case lib_scene:is_dungeon_scene(Scene) of
        false -> ok; %% 不处理非副本的打怪事件
        true ->
            CopyId ! {kill_npc, Scene, NpcIdList, BossType, MonAutoId, IsSkip}
    end.

%% 杀怪事件
%% IsSkip : 1能跳层， 0 不能跳层
kill_npc(PS, NpcIdList, BossType, MonAutoId, IsSkip) ->
    case lib_scene:is_dungeon_scene(PS#player_status.scene) of
        false -> ok; %% 不处理非副本的打怪事件
        true ->
            case is_pid(PS#player_status.copy_id) of
                false -> ok; %% TODO 异常暂时不处理
                true ->
					PS#player_status.copy_id ! {kill_npc, PS#player_status.scene, NpcIdList, BossType, MonAutoId, IsSkip}
            end
    end.



%% --------------------------------- 内部函数 ----------------------------------

%% 设置武魂值
set_whpt(BossType, [NpcId|_], State) ->
	%1.计算武魂值.
	WHPT = case BossType of
		0 -> 
			0;
		_ ->
			case State#dungeon_state.type of
				?DUNGEON_TYPE_STORY ->
					data_story_dun_config:get_whpt(NpcId);
				_ ->
					0
			end
	end,

	%2.增加武魂值.
	FunAddWHPT = 
	fun(PlayerPid) ->		
		if WHPT > 0 ->
				gen_server:cast(PlayerPid, {'set_data', [{add_whpt, WHPT}]});
		    true ->
				skip
		end
	end,
	[FunAddWHPT(X#dungeon_player.pid)|| X<-State#dungeon_state.role_list],

	%3.返回武魂值.
	WHPT.

%% 用场景资源获取副本id
get_dungeon_id(SceneResId) ->
    F = fun(Did, P) ->
        DD = data_dungeon:get(Did),
        case lists:keyfind(SceneResId, 1, DD#dungeon.scene) of
            false -> P;
            _ -> Did
        end
    end,
    lists:foldl(F, 0, data_dungeon:get_ids()).

%% 组织副本的基础数据
get_dungeon_data([], DSR, KillNpc, DunScene) ->
    {DSR, KillNpc, DunScene};
get_dungeon_data(DidList, DSR, KillNpc, DunScene) ->
    [Did | NewDidList] = DidList,
    D = data_dungeon:get(Did),
    S = [#dungeon_scene{id=0, did=Did, sid=Sid, enable=Enable, tip=Msg} || {Sid, Enable, Msg} <- D#dungeon.scene],
    get_dungeon_data(NewDidList, DSR ++ D#dungeon.requirement, KillNpc ++ D#dungeon.kill_npc, DunScene ++ S).

%% 检查场景激活条件
get_enable([], Result, _) ->
    Result;
get_enable([SceneId | T ], Result, SceneRequirementList) ->
    case length([0 || [EnableSceneResId, Fin | _ ] <- SceneRequirementList, 
	    EnableSceneResId =:= SceneId, Fin =:= false]) =:= 0 of
        false -> get_enable(T, Result, SceneRequirementList);
        true -> get_enable(T, [SceneId | Result], SceneRequirementList)
    end.

%% 创建副本场景
create_scene(SceneId, State) ->
	%1.加载副本场景怪物信息.
    mod_scene_agent:apply_call(SceneId, mod_scene, copy_dungeon_scene, [SceneId, self(), 0, State#dungeon_state.tower_state#tower_state.ratio]), 
    %2.更新副本场景的唯一id.
    F = fun(DunScene) ->
        case DunScene#dungeon_scene.sid =:= SceneId of
            true -> DunScene#dungeon_scene{id = SceneId};
            false -> DunScene
        end
    end,
    NewState = State#dungeon_state{scene_list = [F(X)|| X <- State#dungeon_state.scene_list]},    
    {SceneId, NewState}.

%% 传送出副本.
send_out(PlayerId, DungeonState) when is_integer(PlayerId)->
    case lib_player:get_player_info(PlayerId) of
        false -> 
			offline;   %% 不在线
        PlayerStatus -> 
			send_out(PlayerStatus, DungeonState)
    end;
%% 传送出副本.
send_out(PS, DungeonState) when is_record(PS, player_status) ->
    case get_dungeon_id(PS#player_status.scene) of    
		%%1.不在副本场景.
        0 -> 
			scene_not_exist;
        %%2.将传送出副本.
        _Did -> 
			[SceneId, X, Y] = DungeonState#dungeon_state.out_scene,
            case is_pid(PS#player_status.pid) of
                true ->	
                    if
                        %% 这里根据玩家的退出类型来做判断，玩家是否再来一次
                        DungeonState#dungeon_state.logout_type =:= ?DUN_EXIT_CLICK_BUTTON_TRY_AGAIN ->
                            lib_scene:leave_scene(PS),
                            gen_server:cast(PS#player_status.pid, {'DR_SENT_OUT_TRY_AGAIN', SceneId, X, Y, PS#player_status.scene});
                        true ->
        					%%3.离开场景.
                            lib_scene:leave_scene(PS),
                            %% Player1 = Player2#player_status{copy_id = 0, scene = Id, x = X, y = Y},
                            %% gen_server:cast(R#ets_online.pid, {'SET_SYN_PLAYER', Player1}),	
        					gen_server:cast(PS#player_status.pid, {'DR_SENT_OUT', SceneId, X, Y, PS#player_status.scene}),							
        					%%4.发送切换到新场景消息给玩家.
                            {ok, BinData} = pt_120:write(12005, [SceneId, X, Y, lib_scene:get_scene_name(SceneId), SceneId]),
                            lib_server_send:send_to_sid(PS#player_status.sid, BinData)
                    end;
                false ->
                    skip
            end
    end;

%% send_out(PS, DungeonState) when is_record(PS, player_status) ->
%%     case get_dungeon_id(PS#player_status.scene) of    
%%         %%1.不在副本场景.
%%         0 -> 
%%             scene_not_exist;
%%         %%2.将传送出副本.
%%         _Did -> 
%%             
%%             %DD = data_dungeon:get(Did),
%%             %2.剧情副本增加副本次数.
%%             %IsStoryDungeon = 
%%             %   case data_dungeon:get(Did) of
%%             %        [] -> 0;
%%             %        Dun ->
%%             %            Dun#dungeon.type
%%             %    end,
%%             [SceneId, X, Y] = DungeonState#dungeon_state.out_scene,
%%                 %case IsStoryDungeon =:= ?DUNGEON_TYPE_STORY of
%%             %       true -> DungeonState#dungeon_state.out_scene;
%%             %       false -> DD#dungeon.out
%%             %   end,
%%             case is_pid(PS#player_status.pid) of
%%                 true ->                     
%%                     %% 1.退出帮派大厅.
%%                     %%  [Id, Sid] = case Sid0 =:= 600 of
%%                     %%                  true ->
%%                     %%                  %% 是否帮派场景.
%%                     %%                      case lib_guild:check_enter(Player2) of
%%                     %%                          {true, Sid1} ->
%%                     %%                              [Sid1, 600];
%%                     %%                          {false, _} ->
%%                     %%                              [Sid0, Sid0]
%%                     %%                      end;
%%                     %%                  false ->
%%                     %%                      [Sid0, Sid0]
%%                     %%              end,                            
%%                     %% 2.退出塔防奖励.
%%                     %% Td = Player2#player_status.td,
%%                     %% case is_pid(Td#status_td.td_pid) andalso Td#status_td.td_pid /= 0 of
%%                     %%      true ->
%%                     %%          lib_td_battle:td_logout(Td#status_td.td_pid, Player2#player_status.id);
%%                     %%      _ ->
%%                     %%          ok
%%                     %% end,
%%                             %%3.离开场景.
%%                             lib_scene:leave_scene(PS),
%%                             %% Player1 = Player2#player_status{copy_id = 0, scene = Id, x = X, y = Y},
%%                             %% gen_server:cast(R#ets_online.pid, {'SET_SYN_PLAYER', Player1}),  
%%                             gen_server:cast(PS#player_status.pid, {'DR_SENT_OUT', SceneId, X, Y, PS#player_status.scene}),                          
%%                             %%4.发送切换到新场景消息给玩家.
%%                             {ok, BinData} = pt_120:write(12005, [SceneId, X, Y, lib_scene:get_scene_name(SceneId), SceneId]),
%%                             lib_server_send:send_to_sid(PS#player_status.sid, BinData);
%%                 false ->
%%                     skip
%%             end
%%     end;
%% 容错

send_out(_R, _DungeonState) ->
    ok.

%% 激活副本场景
enable_action([], State, _) ->
    State;
%% 激活副本场景
enable_action([SceneId | T], State, Sid) ->
    case lists:keyfind(SceneId, 4, State#dungeon_state.scene_list) of
        false -> enable_action(T, State, Sid);%%这里属于异常
        DunScene -> %% TODO 广播场景以激活
            NewDSL = lists:keyreplace(SceneId, 4, State#dungeon_state.scene_list, DunScene#dungeon_scene{enable = true}),
            %S = lib_scene:get_data(SceneId),
            %lib_conn:pack_cast(dungeon, self(), 10010 , [list_to_binary(["场景【", S#scene.name, "】已激活！"])]),         

            %1.如果是锁妖塔副本.
            TowerState = State#dungeon_state.tower_state,
            case lists:keyfind(Sid, 1, TowerState#tower_state.esid) of
                false -> 
					ok;
                {_, BTime} ->
					RewardTime = util:unixtime() - BTime,
					mod_tower_dungeon:tower_reward(self(), Sid, RewardTime) 
            end,
			
			%2.飞行副本处理.
			case State#dungeon_state.type of
				?DUNGEON_TYPE_FLY ->
					lib_fly_dungeon:stop_time(Sid, State);
				_ ->
					skip
			end,	

            enable_action(T, State#dungeon_state{scene_list = NewDSL}, Sid)
    end.

%% 检测副本的杀怪完成情况.
event_action([], Req, _, Result) ->
    {Req, Result};
%% 检测副本的杀怪完成情况.
event_action([[EnableSceneResId, false, kill_npc, NpcId, Num, NowNum] | T ], Req, Param, Result)->
    NpcList = Param,
    case length([X||X <- NpcList, NpcId =:= X]) of
        0 -> event_action(T, [[EnableSceneResId, false, kill_npc, NpcId, Num, NowNum] | Req], Param, Result);
        FightNum ->
            case NowNum + FightNum >= Num of
                true ->
                    %mod_dungeon:tower_reward(self(), EnableSceneResId),
                    event_action(T, [[EnableSceneResId, true, kill_npc, NpcId, Num, Num] | Req], 
								 Param, lists:umerge(Result, [EnableSceneResId]));
                false -> 
					event_action(T, [[EnableSceneResId, false, kill_npc, NpcId, Num, NowNum + FightNum] | Req], 
								 Param, lists:umerge(Result, [EnableSceneResId]))
            end
    end;

%% 丢弃异常和已完成的.
event_action([_ | T], Req, Param, Result) ->
    event_action(T, Req, Param, Result).

%%副本的人是否存在
is_in_dungeon(_, ok)->
    ok;
is_in_dungeon([], S)->
    S;
is_in_dungeon([RX | T], _S) ->
    case is_pid(RX#dungeon_player.pid) of
        true ->
            is_in_dungeon(T, ok);
        false ->
            is_in_dungeon(T, out)
    end.

%% 发送副本通关结算.
%% Type: 退出类型 1|2|3|4|5|6|cd1|cd2
send_dungeon_record(DungeonState, PlayerStatus, Type) ->
	PlayerId = PlayerStatus#player_status.id,
	PlayerPid = PlayerStatus#player_status.pid,
	PlayerLevel = PlayerStatus#player_status.lv,
    PlayerName   = PlayerStatus#player_status.nickname,
    PlayerSex    = PlayerStatus#player_status.sex,
    PlayerCareer = PlayerStatus#player_status.career,
	DungeonId = DungeonState#dungeon_state.begin_sid,
	KillMon = DungeonState#dungeon_state.kill_mon_count,
	DungeonDataPid = PlayerStatus#player_status.pid_dungeon_data,
	WHPT = DungeonState#dungeon_state.whpt,
	BeginTime = DungeonState#dungeon_state.time,
	LogoutType = DungeonState#dungeon_state.logout_type,
	CombatPower = PlayerStatus#player_status.combat_power,
	
	%%副本日志.
    case DungeonState#dungeon_state.type of
		%1.宠物副本.
        ?DUNGEON_TYPE_PET -> 
			lib_off_line:add_off_line_count(PlayerId, 5, 1, 0),
			log:log_pet_dungeon(PlayerId, PlayerLevel, 
								BeginTime, LogoutType, CombatPower);
		
		%2.创建经验副本.
		?DUNGEON_TYPE_EXP -> 
			lib_off_line:add_off_line_count(PlayerId, 4, 1, 0),
            case lib_buff:match_two(PlayerStatus#player_status.player_buff, 1, []) of
			%case buff_dict:match_two(PlayerId, 1) of
				[Buff] ->
					log:log_exp_dungeon(PlayerId, 
										PlayerLevel, 
										1, 
										Buff#ets_buff.goods_id, 
										BeginTime, 
										LogoutType, 
										CombatPower);
				_ ->
					log:log_exp_dungeon(PlayerId, 
										PlayerLevel, 
										0, 
										0, 
										BeginTime, 
										LogoutType, 
										CombatPower)
			end;
		%3.铜币副本.
		?DUNGEON_TYPE_COIN -> skip; 
		%4.爬塔副本.
		?DUNGEON_TYPE_TOWER -> skip;
		%5.单人塔防副本.
		?DUNGEON_TYPE_KINGDOM_RUSH -> 
			lib_kingdom_rush_dungeon:log(DungeonState,
										 PlayerId,
										 PlayerLevel,
										 CombatPower);		
		%6.多人塔防副本.
		?DUNGEON_TYPE_MULTI_KING -> 
			lib_multi_king_dungeon:log(DungeonState,
										 PlayerId,
										 PlayerLevel,
										 CombatPower);
		
		%7.连连看副本.
		?DUNGEON_TYPE_LIAN -> 
			lib_lian_dungeon:reward_mail(DungeonState,
										 PlayerId,
										 PlayerPid,
										 PlayerLevel,
										 CombatPower);

		%6.飞行塔防副本.
		?DUNGEON_TYPE_FLY -> 
			lib_fly_dungeon:log(DungeonState,
								PlayerId,
								PlayerLevel,
								CombatPower);
		
	    _ -> skip 
	end,

	%1.铜币副本计算.
    TotalCoin = 
		case DungeonState#dungeon_state.coin_dun of		
			[] ->
				0;		
			CoinDun ->				
				%% 铜币副本日志
				log:log_coin_dungeon(PlayerId,
									 PlayerLevel, 
									 CoinDun#coin_dun.coin, 
									 CoinDun#coin_dun.bcoin,
									 BeginTime, 
									 LogoutType, 
									 CombatPower),
				CoinDun#coin_dun.coin
		end,

	%2.爬塔副本计算.
    Now = util:unixtime(),
    TowerState =  DungeonState#dungeon_state.tower_state,
    {Layer, TotalExp, TotalTime} = case TowerState#tower_state.esid of
        [] ->  {1, 0, Now - BeginTime}; %% @return
        [{_, LastBeginTime}|_] -> 
            _AddTimeSign = case Type of
                1 -> 10000; %% 退队
                2 -> 20000; %% 客户端判断超时退出
                3 -> 30000; %% 剧情本接口退出
                4 -> 40000; %% 61000客户端主动退出(普通副本)
                5 -> 50000; %% 28005客户端主动退出(九重天副本)
                6 -> 60000; %% 退队（队伍信息异常）
                cd1  ->  70000; %% 服务器判断超时退出(有队伍)
                cd2  ->  80000; %% 服务器判断超时退出(无队伍)
                _    ->  90000  %% 其他情况
            end,
            case lib_tower_dungeon:reward(PlayerId, PlayerLevel, DungeonId, 
				DungeonDataPid, 1, Now - LastBeginTime, 
				TowerState#tower_state.ratio, LogoutType, CombatPower) of
                false ->				
                    {1, 0, Now - BeginTime}; %% @return
                {_AfterExRExp, _AfterExRLlpt, _AfterCutItems, _AfterCutHonour, 
                    _AfterCutKingHonour, _ExRewardSign, _ActiveBox, _TowerName, 
                    _Level, _TotalTime} ->
                    %gen_server:cast(PlayerPid, {'tower_reward', _AfterExRExp, _AfterExRLlpt,
                    %				_AfterCutItems, _AfterCutHonour, _AfterCutKingHonour, 
                    %				_Level, _TotalTime, _TowerName}),
                    {_Level, _AfterExRExp, _TotalTime} %% @return
            end
    end,
	
	%3.计算通关级别(没有杀死BOSS通关等级为0).
	{NowLevel, TotalTime2} = 
		case WHPT > 0 of
			true ->
				gen_server:cast(PlayerPid, 'count_base_attribute'),
				{data_story_dun_config:get_record_level(DungeonId, TotalTime, KillMon), TotalTime};
			false -> {0, 0}
		end,
	
	%% 增加副本通关新纪录.
	IsNewRecord = add_dungeon_record2(PlayerId, PlayerName, PlayerSex, PlayerCareer, DungeonId, NowLevel, TotalTime2, DungeonDataPid),	
	case DungeonState#dungeon_state.is_send_record of
		true ->
            if
                DungeonState#dungeon_state.type =:= ?DUNGEON_TYPE_STORY andalso DungeonState#dungeon_state.is_die =:= 1 ->
                    skip;
                true -> 
                    {ok, BinData} = pt_610:write(61006, [DungeonId,    %% 副本类型. 
        												 NowLevel,     %% 通关等级.
        												 IsNewRecord,  %% 是否通关新纪录.
        												 TotalTime,    %% 通关时间.
        												 Layer,        %% 通关层数.
        												 KillMon,      %% 杀怪数量.
        												 TotalExp,     %% 获得经验.
        												 TotalCoin,    %% 获得铜币.
        												 WHPT]),       %% 获得武魂值.
        			lib_player:rpc_cast_by_id(PlayerId, lib_server_send, send_to_uid, [PlayerId, BinData])
            end;
		false ->
			skip
	end,
	ok.

%% 检测怪物的击杀统计.
check_kill_count(SceneId, KillNpcList) ->
	%1.定义查找击杀怪物数量函数.
	FunFindMon = 
		fun(Requirement) ->
			%%[影响场景, 是否完成, kill, npcId, 需要数量, 现在数量]
			[SceneId1, _FinishFlag, kill_npc, MonId, TotalCount, NowCount] = Requirement,
			if 
				SceneId =:= SceneId1 ->
					MonData = data_mon:get(MonId),
					case MonData =:= [] of
					    true ->
					        [];
					    false ->
							[[MonId, MonData#ets_mon.icon, TotalCount, NowCount]]
					end;					
				true ->
					[]
			end
		end,
	
	%2.检查副本条件是否有要击杀的怪物.
	MonList = lists:flatmap(FunFindMon, KillNpcList),
	
	%3.判断是否有击杀的怪物.
	Return = 
		if 
			length(MonList) =:= 0 ->
				flase;
			true ->
				{true, MonList}
		end,
	
	Return.

%% 增加副本总次数.
add_total_count(PlayerId, DungeonId, DungeonDataPid) ->
	
	%1.插入纪录.
	Sql = io_lib:format(?sql_select_dungeon_log, [PlayerId]),
	
	%获取副本日志.
	NewLog =
		case mod_dungeon_data:get_dungeon_log(DungeonDataPid) of
			[] -> 
				case db:get_row(Sql) of		
					%1.玩家没有副本日志记录.
			        [] ->	        
						DunLog = [{DungeonId, 1, 5}],				
						NewDunLog1 = util:term_to_string(DunLog),				
						Sql2 = io_lib:format(?sql_replace_dungeon_log, [PlayerId, NewDunLog1]),
						db:execute(Sql2),
						mod_dungeon_data:set_dungeon_log(DungeonDataPid, NewDunLog1),
						DunLog;
						
					%2.玩家有副本日志记录.
			        [DunLog] ->				
						NewDunLog2 = util:to_term(DunLog),
						case lists:keyfind(DungeonId, 1, NewDunLog2) of
							%1.玩家有副本Id对应的日志记录.
							{Dungeon, TotalCount, NewRecord}->
								NewDunLog21 = lists:keyreplace(Dungeon, 1, NewDunLog2, {Dungeon, TotalCount+1, NewRecord}),
								NewDunLog22 = util:term_to_string(NewDunLog21),
								Sql3 = io_lib:format(?sql_update_dungeon_log, [NewDunLog22, PlayerId]),
								db:execute(Sql3),
								mod_dungeon_data:set_dungeon_log(DungeonDataPid, NewDunLog22),
								NewDunLog2;
			
							%2.玩家没有有副本Id对应的日志记录.
							_ ->
								NewDunLog3 = NewDunLog2 ++ [{DungeonId, 1, 5}],
								NewDunLog31 = util:term_to_string(NewDunLog3),
								Sql4 = io_lib:format(?sql_update_dungeon_log, [NewDunLog31, PlayerId]),
								db:execute(Sql4),
								mod_dungeon_data:set_dungeon_log(DungeonDataPid, NewDunLog31),
								NewDunLog3
						end
				 end;
			[DunLog2] ->
				NewDunLog2 = util:string_to_term(DunLog2),
				case lists:keyfind(DungeonId, 1, NewDunLog2) of
					%1.玩家有副本Id对应的日志记录.
					{Dungeon, TotalCount, NewRecord}->
						NewDunLog21 = lists:keyreplace(Dungeon, 1, NewDunLog2, {Dungeon, TotalCount+1, NewRecord}),
						NewDunLog22 = util:term_to_string(NewDunLog21),
						Sql3 = io_lib:format(?sql_update_dungeon_log, [NewDunLog22, PlayerId]),
						db:execute(Sql3),
						mod_dungeon_data:set_dungeon_log(DungeonDataPid, NewDunLog22),
						NewDunLog2;
	
					%2.玩家没有有副本Id对应的日志记录.
					_ ->
						NewDunLog3 = NewDunLog2 ++ [{DungeonId, 1, 5}],
						NewDunLog31 = util:term_to_string(NewDunLog3),
						Sql4 = io_lib:format(?sql_update_dungeon_log, [NewDunLog31, PlayerId]),
						db:execute(Sql4),
						mod_dungeon_data:set_dungeon_log(DungeonDataPid, NewDunLog31),
						NewDunLog3
				end;
			_Other ->
				DunLog41 = [{DungeonId, 1, 5}],
				DunLog41
		end,

	{ok, BinData} = pt_610:write(61008, [PlayerId, NewLog]),
	lib_server_send:send_to_uid(PlayerId, BinData).

%% 增加副本通关新纪录.
add_dungeon_record(PlayerId, DungeonId, NowLevel, DungeonDataPid) ->
	
	%1.插入纪录.
	Sql = io_lib:format(?sql_select_dungeon_log, [PlayerId]),
	
	IsNewRecord = 
		case mod_dungeon_data:get_dungeon_log(DungeonDataPid) of
			[] ->		
				case db:get_row(Sql) of		
					%1.玩家没有副本日志记录.
			        [] ->	        
						DunLog = [{DungeonId, 1, NowLevel}],				
						NewDunLog1 = util:term_to_string(DunLog),				
						Sql2 = io_lib:format(?sql_replace_dungeon_log, [PlayerId, NewDunLog1]),
						db:execute(Sql2),
						mod_dungeon_data:set_dungeon_log(DungeonDataPid, NewDunLog1),
						1;
						
					%2.玩家有副本日志记录.
			        [DunLog] ->
						NewDunLog2 = util:to_term(DunLog),
						case lists:keyfind(DungeonId, 1, NewDunLog2) of
							%1.玩家有副本Id对应的日志记录.
							{Dungeon, TotalCount, OldLevel}->
								if 
									OldLevel > NowLevel ->
										NewDunLog21 = lists:keyreplace(Dungeon, 1, NewDunLog2, {Dungeon, TotalCount, NowLevel}),
										NewDunLog22 = util:term_to_string(NewDunLog21),
										Sql3 = io_lib:format(?sql_update_dungeon_log, [NewDunLog22, PlayerId]),
										db:execute(Sql3),
										mod_dungeon_data:set_dungeon_log(DungeonDataPid, NewDunLog22),
										1;
									true ->
										0
								end;
			
							%2.玩家没有有副本Id对应的日志记录.
							_ ->
								NewDunLog3 = NewDunLog2 ++ [{DungeonId, 1, NowLevel}],
								NewDunLog31 = util:term_to_string(NewDunLog3),
								Sql4 = io_lib:format(?sql_update_dungeon_log, [NewDunLog31, PlayerId]),
								db:execute(Sql4),
								mod_dungeon_data:set_dungeon_log(DungeonDataPid, NewDunLog31),
								1
						end
				end;
		[DunLog2] ->
				NewDunLog2 = util:string_to_term(DunLog2),
				case lists:keyfind(DungeonId, 1, NewDunLog2) of
					%1.玩家有副本Id对应的日志记录.
					{Dungeon, TotalCount, OldLevel}->
						if 
							OldLevel > NowLevel ->
								NewDunLog21 = lists:keyreplace(Dungeon, 1, NewDunLog2, {Dungeon, TotalCount, NowLevel}),
								NewDunLog22 = util:term_to_string(NewDunLog21),
								Sql3 = io_lib:format(?sql_update_dungeon_log, [NewDunLog22, PlayerId]),
								db:execute(Sql3),
								mod_dungeon_data:set_dungeon_log(DungeonDataPid, NewDunLog22),
								1;
							true ->
								0
						end;
	
					%2.玩家没有有副本Id对应的日志记录.
					_ ->
						NewDunLog3 = NewDunLog2 ++ [{DungeonId, 1, NowLevel}],
						NewDunLog31 = util:term_to_string(NewDunLog3),
						Sql4 = io_lib:format(?sql_update_dungeon_log, [NewDunLog31, PlayerId]),
						db:execute(Sql4),
						mod_dungeon_data:set_dungeon_log(DungeonDataPid, NewDunLog31),
						1
				end
		end,
	
	IsNewRecord.

%% 增加副本通关新纪录.
add_dungeon_record2(PlayerId, PlayerName, PlayerSex, PlayerCareer, DungeonId, NowLevel, TotalTime, DungeonDataPid) ->
	IsNewRecord = 
		case mod_dungeon_data:get_record_level(DungeonDataPid, PlayerId, DungeonId) of
			{ok, OldLevel, PassTime} ->
				if 
					OldLevel < NowLevel ->
						mod_dungeon_data:set_record_level(DungeonDataPid, PlayerId, DungeonId, NowLevel, TotalTime),
						1;
					OldLevel =:= NowLevel andalso PassTime > TotalTime->
						mod_dungeon_data:set_record_level(DungeonDataPid, PlayerId, DungeonId, NowLevel, TotalTime),
						1;					
					true ->
						0
				end;
			_Other ->
				1
		end,
	%1.判断自己是否可以成为霸主.
	mod_dungeon_data:save_story_total_score(DungeonDataPid, PlayerId, PlayerName, PlayerSex, PlayerCareer, DungeonId),
	IsNewRecord.

%% 退出结算.
quit_reward(DungeonState, PlayerStatus, Type) ->
	%1.关闭锁妖塔界面.
    case DungeonState#dungeon_state.begin_sid == 300  orelse DungeonState#dungeon_state.begin_sid == 340 of
        true ->
			lib_server_send:send_to_uid(PlayerStatus#player_status.id, 
										pt:pack(28008, <<>>));
        false ->
        	ok
	end,
		
    %2.发送通关记录
    if
        %% 装备副本超时和主动退出的特殊处理
        DungeonState#dungeon_state.type =:= ?DUNGEON_TYPE_DNTK_EQUIP ->
            lib_equip_energy_dungeon:send_equip_fail_result(DungeonState, PlayerStatus, Type); 
        %% 封魔录屏蔽在通关成功出场景弹结算界面
        DungeonState#dungeon_state.type =:= ?DUNGEON_TYPE_STORY andalso DungeonState#dungeon_state.is_die =:= 2 ->
            skip;
        true ->
            send_dungeon_record(DungeonState, PlayerStatus, Type)
    end,
    
    case DungeonState#dungeon_state.type of
		%1.铜币副本发放奖励
		?DUNGEON_TYPE_COIN ->
            lib_coin_dungeon:reward(PlayerStatus, DungeonState);
		
		%2.塔防副本更新排行榜.
		?DUNGEON_TYPE_KINGDOM_RUSH ->
			lib_kingdom_rush_dungeon:update_rank(PlayerStatus, DungeonState);
		
		%3.飞行副本更新排行榜.
		?DUNGEON_TYPE_FLY ->
			lib_fly_dungeon:update_rank(PlayerStatus, DungeonState);
        
        _ -> 
			skip
    end,
    mod_server:set_dungeon_pid(PlayerStatus#player_status.pid, 0),
    send_out(PlayerStatus, DungeonState),	
	ok.



%% 得到副本的类型.
get_dungeon_type(SceneId) ->
	DungeonData = data_dungeon:get(SceneId),
	case DungeonData of
		DungeonData when is_record(DungeonData, dungeon) ->
			DungeonData#dungeon.type;
		_ -> 
			-1
	end.

%% 检测队伍成员进入条件.
check_condition([], _) -> true;
check_condition([H|T], LeaderScene) -> 
	case lib_player:get_player_info(H, dungeon) of        
        {ok, SceneId} -> 
            if 
                SceneId =/= LeaderScene ->
                    {false, data_dungeon_text:get_tower_text(18)};
                true -> 
					check_condition(T, LeaderScene)
            end;
		_ -> check_condition(T, LeaderScene)
    end.

%% 检测队伍进入条件.
check_team_condition(Status, SceneId) ->
	Dun = data_dungeon:get(SceneId),	

	if
        Dun =:= [] ->
            {true, msg};
		%1.队长进去检测条件.
        Status#player_status.leader == 1 ->			
            case lib_team:get_mb_num(Status#player_status.pid_team) =< 3 of
                false -> {false, data_dungeon_text:get_tower_text(11)};
                true -> 
                    MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),
                    NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
                    case check_condition(NewMemberIdList, Status#player_status.scene) of
                        {false, Reason1} -> {false, Reason1};
                        true ->
                            FunCheckCount = fun(PlayerId) ->
                                    if PlayerId =:= Status#player_status.id ->										   
                                            mod_daily:get_count(Status#player_status.dailypid,
                                                Status#player_status.id,
                                                SceneId) >= Dun#dungeon.count;
                                        true ->
                                            case lib_player:get_player_info(PlayerId, dailypid) of
                                                false -> false;
                                                DailyPid ->
                                                    mod_daily:get_count(DailyPid, PlayerId, 
                                                        SceneId) >= Dun#dungeon.count
                                            end
                                    end
                            end,
                            MCL = [FunCheckCount(MbId) || MbId <- NewMemberIdList],
                            case lists:member(true, MCL) of
                                true ->
                                    {false, data_dungeon_text:get_tower_text(38)};
                                false ->
                                    {true, msg}
                            end
                    end
      		end;

		%2.队员检测.
		true ->
			%1.检测人数是否已满.
	        case lib_scene:check_dungeon_requirement(Status, Dun#dungeon.condition) of
	            {false, Reason2} -> 
					{false, Reason2};
	            {true} ->
					{true, msg}
			end
    end.

%% 检测副本进入时间.
check_enter_time(DungeonId) ->
	case data_dungeon:get(DungeonId) of
		[] ->
			true;
		Dun ->
			case Dun#dungeon.enter_time of
				[]->
					true;
				[BeginDate,EndDate]->
					NowTime = util:unixtime(),
					if
						BeginDate=<NowTime andalso NowTime=<EndDate->
							true;
						true->
							false
					end
			end	
	end.

%% 玩家在副本死亡触发事件(在玩家进程调用)
player_die(#player_status{copy_id=CopyId, scene=Scene} = PS) when is_pid(CopyId) -> 
    case lib_scene:get_res_type(Scene) of
        ?SCENE_TYPE_DUNGEON  -> 
            CopyId ! {'player_die', PS};
        ?SCENE_TYPE_TOWER ->
            CopyId ! {'player_die', PS};
        _ ->
            skip
    end;
player_die(_) -> skip.

%% %% 玩家在副本死亡触发事件(在玩家进程调用)
%% player_die(#player_status{id = PlayerId, copy_id=CopyId, scene=Scene}) when is_pid(CopyId) -> 
%%     case lib_scene:get_res_type(Scene) of
%%         ?SCENE_TYPE_DUNGEON  -> CopyId ! {'player_die', PlayerId};
%%         _ -> skip
%%     end;
%% player_die(_) -> skip.

%% 玩家在副本死亡触发事件(在副本进程调用)
player_die(DungeonState, PS) -> 
    #dungeon_state{begin_sid = DunId, is_send_record = IsSendRecord, kill_mon_count = KillMon, time = BeginTime} = DungeonState,
    DungeonType = lib_dungeon:get_dungeon_type(DunId),
    case DungeonType of
        ?DUNGEON_TYPE_STORY ->
            %% 发送通过失败通知
            case IsSendRecord of
                true ->
                    TotalTime = util:unixtime() - BeginTime,
                    {ok, BinData} = pt_610:write(61006, [DunId,    %% 副本类型. 
                            10,     %% 通关等级.(10代表通关失败)
                            0,      %% 是否通关新纪录.
                            TotalTime,    %% 通关时间.
                            0,          %% 通关层数.
                            KillMon,    %% 杀怪数量.
                            0,          %% 获得经验.
                            0,          %% 获得铜币.  
                            0]),        %% 获得武魂值.
                    lib_server_send:send_to_uid(PS#player_status.id, BinData);
                false -> skip
            end,
            %% 退出副本
            %CopyId = self(),
            %send_record(CopyId, false),
            %quit(CopyId, PlayerId, 3),
            %clear(role, CopyId),
            ok;
        ?DUNGEON_TYPE_DNTK_EQUIP ->
            lib_equip_energy_dungeon:send_equip_fail_result(DungeonState, PS, 0); %% 超时和主动退出
        _ ->
            skip
    end.

%% %% 玩家在副本死亡触发事件(在副本进程调用)
%% player_die(#dungeon_state{begin_sid = DunId, is_send_record = IsSendRecord, kill_mon_count = KillMon, time = BeginTime}, PlayerId) -> 
%%     DungeonType = lib_dungeon:get_dungeon_type(DunId),
%%     case DungeonType of
%%         ?DUNGEON_TYPE_STORY ->
%%             %% 发送通过失败通知
%%             case IsSendRecord of
%%                 true ->
%%                     TotalTime = util:unixtime() - BeginTime,
%%                     {ok, BinData} = pt_610:write(61006, [DunId,    %% 副本类型. 
%%                             10,     %% 通关等级.(10代表通关失败)
%%                             0,      %% 是否通关新纪录.
%%                             TotalTime,    %% 通关时间.
%%                             0,          %% 通关层数.
%%                             KillMon,    %% 杀怪数量.
%%                             0,          %% 获得经验.
%%                             0,          %% 获得铜币.  
%%                             0]),        %% 获得武魂值.
%%                     lib_server_send:send_to_uid(PlayerId, BinData);
%%                 false -> skip
%%             end,
%%             %% 退出副本
%%             %CopyId = self(),
%%             %send_record(CopyId, false),
%%             %quit(CopyId, PlayerId, 3),
%%             %clear(role, CopyId),
%%             ok;
%%         ?DUNGEON_TYPE_DNTK_EQUIP ->
%%             lib_equip_energy_dungeon:send_equip_fail_result(DungeonState, PlayerStatus, Type); %% 超时和主动退出
%% %%             %% 发送通过失败通知
%% %%             case IsSendRecord of
%% %%                 true ->
%% %%                     TotalTime = util:unixtime() - BeginTime,
%% %%                     {ok, BinData} = pt_610:write(61006, [DunId,    %% 副本类型. 
%% %%                             10,     %% 通关等级.(10代表通关失败)
%% %%                             0,      %% 是否通关新纪录.
%% %%                             TotalTime,    %% 通关时间.
%% %%                             0,          %% 通关层数.
%% %%                             KillMon,    %% 杀怪数量.
%% %%                             0,          %% 获得经验.
%% %%                             0,          %% 获得铜币.  
%% %%                             0]),        %% 获得武魂值.
%% %%                     lib_server_send:send_to_uid(PlayerId, BinData);
%% %%                 false -> skip
%% %%             end,
%% %%             %% 退出副本
%% %%             %CopyId = self(),
%% %%             %send_record(CopyId, false),
%% %%             %quit(CopyId, PlayerId, 3),
%% %%             %clear(role, CopyId),
%% %%             ok;
%%         _ ->
%%             skip
%%     end.

