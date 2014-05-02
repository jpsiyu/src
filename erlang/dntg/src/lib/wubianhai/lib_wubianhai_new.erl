%%%------------------------------------
%%% @Module  : lib_wubianhai_new
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.7.7
%%% @Description: 大闹天宫(无边海)
%%%------------------------------------
-module(lib_wubianhai_new).
-include("server.hrl").
-include("unite.hrl").
-include("common.hrl").
-include("wubianhai_new.hrl").
-include("scene.hrl").
-include("team.hrl").
-include("buff.hrl").
%%
%% Include files
%%

%%
%% Exported Functions
%%
-compile(export_all).
%%
%% API Functions

%% 手动启动服务器(慎用本方法，如果是竞技场中途使用，当前竞技场记录将作废)
%% @param Config_Begin_Hour 起始时刻
%% @param Config_Begin_Minute 起始时刻
%% @param Config_End_Hour 终止时刻
%% @param Config_End_Minute 终止时刻
%% @return ok|_
execute_64099(_Uid,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute)->
	%%重置竞技场
	mod_wubianhai_mgr_new:mt_start_link(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute),
%% 	{ok, BinData} = pt_110:write(11004, lists:concat(["Arena Time Reset: ",
%% 													   Config_Begin_Hour, ":",Config_Begin_Minute,"--",
%% 													   Config_End_Hour, ":",Config_End_Minute])),
%% 	lib_unite_send:send_to_uid(Uid, BinData),
	ok.

%% 64002协议处理结果。
%% 进入 退出战场
%% Res: 1进入  2退出
execute_64002(PlayerStatus, Res, RoomId)->
	case Res of
		1 ->
            ApplyLevel = data_wubianhai_new:get_wubianhai_config(apply_level),
			case PlayerStatus#player_status.lv >= ApplyLevel of
				true ->
					login(PlayerStatus, RoomId);
				false -> [2, "", PlayerStatus]
			end;
		_ -> logout(PlayerStatus)
	end.

%% 64003协议处理结果。
%% 任务信息(玩家进入场景后客户端请求)
execute_64003(UniteStatus)->
    mod_wubianhai_new:cast_64003(UniteStatus).

%% 64004协议处理结果。
%% 领取奖励
execute_64004(UniteStatus, TaskId, SceneId)->
	mod_wubianhai_new:award(UniteStatus, TaskId),
	refresh_task(SceneId, UniteStatus#unite_status.id).

%% 64009协议处理结果。
%% 队伍进入南天门
execute_64009(PlayerStatus, RoomId)->
    ApplyLevel = data_wubianhai_new:get_wubianhai_config(apply_level),
    case PlayerStatus#player_status.lv >= ApplyLevel of
        true ->
            team_login(PlayerStatus, RoomId);
        false ->
            [2, "", PlayerStatus]
    end.

%% 64011协议处理结果。
%% 获取南天门房间信息
execute_64011(PlayerStatus) ->
    mod_wubianhai_new:room_list(PlayerStatus#player_status.id, PlayerStatus#player_status.lv).

%% 玩家进入战场，分配房间。
login(PlayerStatus, RoomId) ->
    %% 在飞行坐骑上不能进入
    case PlayerStatus#player_status.mount#status_mount.fly_mount =/= 0 of
        true -> 
            _PK_NewStatus1 = PlayerStatus,
            Result2 = 5;
        false ->
            SceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
            case lib_scene:check_enter(PlayerStatus,SceneId) of
                {false,_Code}->
                    _PK_NewStatus1 = PlayerStatus,
                    Result2 = 5;   %% 失败，不允许切换场景
                {true,_,_,_,_,_,_}->
                    Pk = PlayerStatus#player_status.pk,
                    PidTeam = PlayerStatus#player_status.pid_team,
                    %%@param Type 0和平 1全体 2国家 3帮派 4队伍 5善恶 6阵营(竞技场等特殊场景)
                    %% 是否在组队状态
                    case is_pid(PidTeam) of
                        true ->
                            case Pk#status_pk.pk_status of
                                4 -> 
                                    PK_Result = ok,
                                    _PK_NewStatus1 = PlayerStatus;
                                _ -> {PK_Result, _PK_ErrorCode, _PK_NewType, _PK_LTime, _PK_NewStatus1} = lib_player:change_pkstatus(PlayerStatus,4) %%切换队伍
                            end;
                        false ->
                            case Pk#status_pk.pk_status of
                                1 -> 
                                    PK_Result = ok,
                                    _PK_NewStatus1 = PlayerStatus;
                                _ -> {PK_Result, _PK_ErrorCode, _PK_NewType, _PK_LTime, _PK_NewStatus1} = lib_player:change_pkstatus(PlayerStatus,1) %%切换全体
                            end
                    end,
                    case PK_Result of
                        error->
                            Result2 = 4;%% 失败，切换战斗模式失败
                        ok->
                            %% 是否组队模式
                            case is_pid(PidTeam) of
                                true ->
                                    MemberIdList = lib_team:get_mb_ids(PlayerStatus#player_status.pid_team),
                                    NewMemberIdList = lists:delete(PlayerStatus#player_status.id, MemberIdList),
                                    %% 判断是否有队员在南天门中
                                    case no_teamer_in(NewMemberIdList) of
                                        true ->
                                            %% 组队模式下只有队长能进入
                                            case PlayerStatus#player_status.leader of
                                                1 ->
                                                    %% 南天门最多3人组队进入
                                                    case length(MemberIdList) > ?WUBIANHAI_MEMBER_MAX of
                                                        false ->
                                                            %% 进入前记录用户当前场景和坐标
                                                            [LastSceneId, LastX, LastY] = [PlayerStatus#player_status.scene, PlayerStatus#player_status.x, PlayerStatus#player_status.y],
                                                            mod_exit:insert_last_xy(PlayerStatus#player_status.id, LastSceneId, LastX, LastY),
                                                            %% 南天门内添加三职业Buff
                                                            %% 队伍人数、是否为三职业
                                                            %% 判断是否三职业
                                                            gen_server:cast(PlayerStatus#player_status.pid, {'wubianhai_is_three_career'}),
                                                            Result2 = 1,%%成功进入
                                                            Scene_born = data_wubianhai_new:get_wubianhai_config(scene_born),
                                                            RoomPlayerNum = mod_wubianhai_new:get_room_num(RoomId),
                                                            [X,Y] = lists:nth(RoomPlayerNum rem 2 + 1, Scene_born),
                                                            CopyId = RoomId,
                                                            lib_scene:change_scene_queue(PlayerStatus, SceneId, CopyId, X, Y, 0),
                                                            call_all_teamer(NewMemberIdList, RoomId),
                                                            %% 维护场景内用户ID
                                                            mod_wubianhai_new:enter_arena(PlayerStatus#player_status.id, PlayerStatus#player_status.lv, RoomId),
                                                            %% 记录PK状态
                                                            mod_wubianhai_new:insert_last_pk_status(PlayerStatus#player_status.id, PlayerStatus#player_status.pk#status_pk.pk_status);
                                                        true -> 
                                                            Result2 = 10%% 失败，队伍人数超过3人
                                                    end;
                                                _ -> 
                                                    Result2 = 3%% 失败，只有队长才能点击进入
                                            end;
                                        %% 已有队员在里面
                                        _RoomId2 -> 
                                            %% 判断是否进入队伍所在的场景中
                                            case _RoomId2 =:= RoomId of
                                                true ->
                                                    %% 南天门最多3人组队进入
                                                    case length(MemberIdList) > ?WUBIANHAI_MEMBER_MAX of
                                                        false ->
                                                            %% 进入前记录用户当前场景和坐标
                                                            [LastSceneId, LastX, LastY] = [PlayerStatus#player_status.scene, PlayerStatus#player_status.x, PlayerStatus#player_status.y],
                                                            mod_exit:insert_last_xy(PlayerStatus#player_status.id, LastSceneId, LastX, LastY),
                                                            Result2 = 1,%%成功进入
                                                            Scene_born = data_wubianhai_new:get_wubianhai_config(scene_born),
                                                            RoomPlayerNum = mod_wubianhai_new:get_room_num(RoomId),
                                                            [X,Y] = lists:nth(RoomPlayerNum rem 2 + 1, Scene_born),
                                                            CopyId = RoomId,
                                                            lib_scene:change_scene_queue(PlayerStatus, SceneId, CopyId, X, Y, 0),
                                                            %% 维护场景内用户ID
                                                            mod_wubianhai_new:enter_arena(PlayerStatus#player_status.id, PlayerStatus#player_status.lv, RoomId),
                                                            %% 记录PK状态
                                                            mod_wubianhai_new:insert_last_pk_status(PlayerStatus#player_status.id, PlayerStatus#player_status.pk#status_pk.pk_status);
                                                        true ->
                                                            Result2 = 10%% 失败，队伍人数超过3人
                                                    end;
                                                false ->
                                                    Result2 = 11%% 失败，队伍不在该房间
                                            end
                                    end;
                                false -> 
                                    %% 进入前记录用户当前场景和坐标
                                    [LastSceneId, LastX, LastY] = [PlayerStatus#player_status.scene, PlayerStatus#player_status.x, PlayerStatus#player_status.y],
                                    mod_exit:insert_last_xy(PlayerStatus#player_status.id, LastSceneId, LastX, LastY),
                                    Result2 = 1,%%成功进入
                                    Scene_born = data_wubianhai_new:get_wubianhai_config(scene_born),
                                    RoomPlayerNum = mod_wubianhai_new:get_room_num(RoomId),
                                    [X,Y] = lists:nth(RoomPlayerNum rem 2 + 1, Scene_born),
                                    CopyId = RoomId,
                                    lib_scene:change_scene_queue(PlayerStatus, SceneId, CopyId, X, Y, 0),
                                    %% 维护场景内用户ID
                                    mod_wubianhai_new:enter_arena(PlayerStatus#player_status.id, PlayerStatus#player_status.lv, RoomId),
                                    %% 记录PK状态
                                    mod_wubianhai_new:insert_last_pk_status(PlayerStatus#player_status.id, PlayerStatus#player_status.pk#status_pk.pk_status)
                            end
                    end
            end
    end,
	[Result2, "", _PK_NewStatus1].

%% 通知所有队员进入
call_all_teamer([], _RoomId2) -> skip;
call_all_teamer([H | T], RoomId2) ->
    %% 不通知在场景中的玩家
    case mod_wubianhai_new:is_in_arena(H) of
        false -> 
            {ok, BinData} = pt_640:write(64009, [1, RoomId2]),
            lib_server_send:send_to_uid(H, BinData);
        _ -> skip
    end,
    call_all_teamer(T, RoomId2).

%% 判读是否有队员在南天门内
no_teamer_in([]) -> true;
no_teamer_in([H | T]) ->
    case mod_wubianhai_new:is_in_arena(H) of
        false -> no_teamer_in(T);
        RoomId -> RoomId
    end.

%% 队伍进入南天门
%% 64009
team_login(PlayerStatus, RoomId) ->
    
	SceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
	case lib_scene:check_enter(PlayerStatus,SceneId) of
		{false,_Code}->
            _PK_NewStatus1 = PlayerStatus,
			Result2 = 5;%% 失败，不允许切换场景
        {true,_,_,_,_,_,_}->
			Pk = PlayerStatus#player_status.pk,
			PidTeam = PlayerStatus#player_status.pid_team,
			%%@param Type 0和平 1全体 2国家 3帮派 4队伍 5善恶 6阵营(竞技场等特殊场景)
			%% 是否在组队状态
			case is_pid(PidTeam) of
				true ->
					case Pk#status_pk.pk_status of
						4 -> 
                            PK_Result = ok,
                            _PK_NewStatus1 = PlayerStatus;
						_ -> {PK_Result, _PK_ErrorCode, _PK_NewType, _PK_LTime, _PK_NewStatus1} = lib_player:change_pkstatus(PlayerStatus,4) %%切换队伍
					end;
				false ->
					case Pk#status_pk.pk_status of
						1 -> 
                            PK_Result = ok,
                            _PK_NewStatus1 = PlayerStatus;
						_ -> {PK_Result, _PK_ErrorCode, _PK_NewType, _PK_LTime, _PK_NewStatus1} = lib_player:change_pkstatus(PlayerStatus,1) %%切换全体
					end
			end,
			case PK_Result of
				error->
					Result2 = 4;%% 失败，切换战斗模式失败
				ok->
                    %% 进入前记录用户当前场景和坐标
                    [LastSceneId, LastX, LastY] = [PlayerStatus#player_status.scene, PlayerStatus#player_status.x, PlayerStatus#player_status.y],
                    mod_exit:insert_last_xy(PlayerStatus#player_status.id, LastSceneId, LastX, LastY),
                    %% 南天门内添加三职业Buff
                    %% 队伍人数、是否为三职业
                    %% 判断是否三职业
					gen_server:cast(PlayerStatus#player_status.pid, {'wubianhai_is_three_career'}),
					Result2 = 1,%% 成功进入
                    Scene_born = data_wubianhai_new:get_wubianhai_config(scene_born),
                    RoomPlayerNum = mod_wubianhai_new:get_room_num(RoomId),
                    [X,Y] = lists:nth(RoomPlayerNum rem 2 + 1, Scene_born),
					CopyId = RoomId, 
                    lib_scene:change_scene_queue(PlayerStatus,SceneId,CopyId,X,Y,0),
					%% 维护场景内用户ID
					mod_wubianhai_new:enter_arena(PlayerStatus#player_status.id, PlayerStatus#player_status.lv, RoomId),
                    %% 记录PK状态
                    mod_wubianhai_new:insert_last_pk_status(PlayerStatus#player_status.id, PlayerStatus#player_status.pk#status_pk.pk_status)
			end
	end,
	[Result2, "", _PK_NewStatus1].

%% 发送3次，玩家在20秒内加载成功都可接收到
login_send(Id, Lv) ->
	spawn(fun() -> 
				login_send2(Id, Lv),
				util:sleep(10 * 1000),
				login_send2(Id, Lv),
				util:sleep(10 * 1000),
				login_send2(Id, Lv) end).

%% 玩家登录判断是否在活动时间内，是则发送01协议
login_send2(Id, Lv) ->
	Apply_level = data_wubianhai_new:get_wubianhai_config(apply_level),
	case Lv >= Apply_level of
		true ->
			case mod_wubianhai_new:get_arena_remain_time() of
				0 -> skip;
				Time -> 
					{ok, BinData} = pt_640:write(64001, [1, Time]),
					lib_unite_send:send_to_one(Id, BinData)
			end;
		false -> skip
	end.

%% 玩家退出战场。
logout(PlayerStatus)->
    %% 删除南天门组队Buff
    case is_pid(PlayerStatus#player_status.pid_team) of
        true -> 
			gen_server:cast(PlayerStatus#player_status.pid, {'del_wubianhai_team_buff'});
        false -> skip
    end,
	%{noreply, PlayerStatus} = server_cast_del_buff(_PlayerStatus),
	Id = PlayerStatus#player_status.id,
	WbhSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
	%% 清除场景内的用户ID
	mod_wubianhai_new:quit_arena(PlayerStatus#player_status.id),
	%% 查找用户登录前记录的场景ID和坐标
	case mod_exit:lookup_last_xy(Id) of
		[_SceneId, _X, _Y] -> 
			case _SceneId of
				WbhSceneId -> [SceneId,X,Y] = data_wubianhai_new:get_wubianhai_config(leave_scene);
				_ -> 
                    %%判断，如果不是普通场景和野外场景，则返回长安主城
                    case lib_scene:get_data(_SceneId) of
                        _S when is_record(_S, ets_scene) ->
                            SceneType = _S#ets_scene.type;
                        _ ->
                            SceneType = 8
                    end,
                    case SceneType =:= ?SCENE_TYPE_NORMAL orelse SceneType =:= ?SCENE_TYPE_OUTSIDE of
                        true ->
                            [SceneId,X,Y] = [_SceneId, _X, _Y];
                        false -> 
                            [SceneId,X,Y] = data_wubianhai_new:get_wubianhai_config(leave_scene)
                    end
			end;
		_ -> [SceneId,X,Y] = data_wubianhai_new:get_wubianhai_config(leave_scene)
	end,
    lib_scene:change_scene_queue(PlayerStatus,SceneId,0,X,Y,0),
    %% 修改PK状态
    Pk = PlayerStatus#player_status.pk,
    Type = mod_wubianhai_new:get_last_pk_status(PlayerStatus#player_status.id),
    NewStatus = PlayerStatus#player_status{pk=Pk#status_pk{pk_status=Type}},
    {ok, BinData} = pt_120:write(12084, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, Type, Pk#status_pk.pk_value]),
    lib_server_send:send_one(NewStatus#player_status.socket, BinData),
	%{PK_Result, _PK_ErrorCode, _PK_NewType, _PK_LTime, _PK_NewStatus1} = lib_player:change_pk_status(Id,2), %%切换国家
	%case PK_Result of
	%	error->Result=4;
	%	ok->Result=0
	%end,
    Result=0,
	%% 更新数据库
	[Task1Num, Task2Num, Task3Num, Task4Num, Task5Num, Task6Num, Task7Num, KillNum] = mod_wubianhai_new:get_task_num(Id),
	update_database(Id, Task1Num, Task2Num, Task3Num, Task4Num, Task5Num, Task6Num, Task7Num, KillNum),
	[Result, "", NewStatus].

%% 与当前时间比，活动剩余时间
%% @return int 0为未开始或已结束，单位是秒
get_arena_remain_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute)->
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60+Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
	Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
	if
		NowTime<Config_Begin->0;
		Config_Begin=<NowTime andalso NowTime<Config_End->Config_End-NowTime;
		Config_End=<NowTime->0
	end.

%%用户退出游戏时踢出大闹天宫
login_out_wubianhai(PS)->
    %case is_pid(PS#player_status.pid_team) of
    %    true -> 
    %        TeamState = gen_server:call(PS#player_status.pid_team, 'get_team_state'),
    %        del_wubianhai_buff(TeamState);
    %    false -> skip
    %end,
    Id = PS#player_status.id,
	%% 清除场景内的用户ID
	mod_wubianhai_new:quit_arena(Id),
	%% 更新数据库
	[Task1Num, Task2Num, Task3Num, Task4Num, Task5Num, Task6Num, Task7Num, KillNum] = mod_wubianhai_new:get_task_num(Id),
	update_database(Id, Task1Num, Task2Num, Task3Num, Task4Num, Task5Num, Task6Num, Task7Num, KillNum),
	%% 查找用户登录前记录的场景ID和坐标
	WbhSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
	case mod_exit:lookup_last_xy(Id) of
		[_SceneId, _X, _Y] -> 
			case _SceneId of
				WbhSceneId -> [SceneId,X,Y] = data_wubianhai_new:get_wubianhai_config(leave_scene);
				_ -> 
                    %%判断，如果不是普通场景和野外场景，则返回长安主城
                    case lib_scene:get_data(_SceneId) of
                        _S when is_record(_S, ets_scene) ->
                            SceneType = _S#ets_scene.type;
                        _ ->
                            SceneType = 8
                    end,
                    case SceneType =:= ?SCENE_TYPE_NORMAL orelse SceneType =:= ?SCENE_TYPE_OUTSIDE of
                        true ->
                            [SceneId,X,Y] = [_SceneId, _X, _Y];
                        false -> 
                            [SceneId,X,Y] = data_wubianhai_new:get_wubianhai_config(leave_scene)
                    end
			end;
		_ -> [SceneId,X,Y] = data_wubianhai_new:get_wubianhai_config(leave_scene)
	end,
	[SceneId, X, Y].

%%用户登录游戏时踢出大闹天宫
%%@param PlayerStatus 玩家状态
%%@return NewPlayerStatus
login_in_wubianhai(_PlayerStates) ->
	%% 玩家登录时判断是否为活动时间，如是直接发送01协议
%	[Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute] = mod_wubianhai_new:get_begin_end_time(),
%	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
%	Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
%	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
%	NowTime = (Hour*60+Minute)*60 + Second,
%	case Config_Begin=<NowTime andalso NowTime<Config_End of
%		true -> 
%			Time = get_arena_remain_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute),
%			{ok, BinData} = pt_640:write(64001, [1, Time]),
%			mod_disperse:call_to_unite(lib_unite_send, send_to_one, [PlayerStates#player_status.id, BinData]);
%		false -> skip
%	end,
    %% 删除南天门Buff
    {noreply, PlayerStates} = server_cast_del_buff(_PlayerStates),
	%% 清除场景内的用户ID
	mod_wubianhai_new:quit_arena(PlayerStates#player_status.id),
	WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
	%% 查找用户登录前记录的场景ID和坐标
	case mod_exit:lookup_last_xy(PlayerStates#player_status.id) of
		[_SceneId, _X, _Y] -> 
			case _SceneId of
				WubianhaiSceneId -> [SceneId,X,Y] = data_wubianhai_new:get_wubianhai_config(leave_scene);
				_ -> [SceneId,X,Y] = [_SceneId, _X, _Y]
			end;
		_ -> [SceneId,X,Y] = data_wubianhai_new:get_wubianhai_config(leave_scene)
	end,
    % 南天门活动时间
    case catch mod_wubianhai_new:get_begin_end_time() of
        [Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute] -> ok;
        _Reason -> [Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute] = [0, 0, 0, 0]
    end,
	%% 如果玩家在场景内则踢出
	if
		PlayerStates#player_status.scene =:= WubianhaiSceneId->
			NewPlayerStates = PlayerStates#player_status{
														 scene = SceneId,                          % 场景id
													     copy_id = 0,                        % 副本id 
													     y = X,
													     x = Y,
                                                         wubianhai_time = [Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute]
														 },
			Pk = NewPlayerStates#player_status.pk,
			if
				Pk#status_pk.pk_status=:=4 orelse Pk#status_pk.pk_status=:=1 -> %%队伍模式
					NewPk = Pk#status_pk{pk_status=2}, %给切回国家模式
					NewPlayerStates#player_status{pk=NewPk};
				true->NewPlayerStates
			end;
        true->PlayerStates#player_status{wubianhai_time = [Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute]}
	end.

%% 刷新任务信息
refresh_task(SceneId, Id) ->
    DataSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
    case SceneId =:= DataSceneId of
        true -> 
            mod_wubianhai_new:get_task_list(Id);
        false -> skip
    end.

%% 对所有活动玩家发送活动结束信息
send_end([], _N) -> ok;
send_end([H | T], N) ->
    %% 分批把玩家传送出去
	case N rem 10 of
		0 -> 
			util:sleep(100);
		_ ->
			skip
	end,
    case misc:get_player_process(H) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'wubianhai_end', []});
        _ ->
            skip
    end,
	send_end(T, N + 1).

task_list_deal([], L2) -> L2;
task_list_deal([H | T], L2) ->
	case H of
		[TaskId, 2, _Finish, _Mid, MonName, Num, NowNum, _SId, _SName, [_X, _Y]] -> task_list_deal(T, [{TaskId, MonName, NowNum, Num} | L2]);
		_ -> task_list_deal(T, L2)
	end.

%% 玩家杀怪累计物品
kill_mon(Status, MonId) ->
    %io:format("MonId:~p~n", [MonId]),
    SceneId = Status#player_status.scene, 
    PlayerId = Status#player_status.id,
	DataSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
	case SceneId =:= DataSceneId of
		true ->
			MonIdList = data_wubianhai_new:get_wubianhai_config(mon_id),
			case lists:member(MonId, MonIdList) of
				true -> 
                    % 判断是否组队模式
                    case is_pid(Status#player_status.pid_team) of
                        true ->
                            MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),
                            NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
                            team_kill_mon(NewMemberIdList, MonId),
                            %% 组队击杀Boss传闻
                            case MonId =:= 42007 of
                                true ->
                                    InWubianhaiList = in_wubianhai_list(NewMemberIdList, []),
                                    %io:format("InWubianhaiList:~p~n", [InWubianhaiList]),
                                    Length = case length(InWubianhaiList) >= 0 of
                                        true -> length(InWubianhaiList) + 1;
                                        false -> 1
                                    end,
                                    send_tv_to_all(InWubianhaiList, Status#player_status.scene, Status#player_status.copy_id, ["nanTMKillBoss", 1, Length, Status#player_status.id, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image]),
                                    BossRefreshTime = data_wubianhai_new:get_wubianhai_config(boss_refresh_time),
                                    [{BossX, BossY}] = data_wubianhai_new:get_wubianhai_config(mon71),
                                    spawn(fun() -> 
                                                util:sleep(BossRefreshTime * 1000),
                                                lib_chat:send_TV({scene, Status#player_status.scene, Status#player_status.copy_id}, 0, 2, ["nanTMRefleshBoss", Status#player_status.scene, BossX, BossY])
                                        end);
                                false -> skip
                            end;
                        false ->
                            %% 单人击杀Boss传闻
                            case MonId =:= 42007 of
                                true -> lib_chat:send_TV({scene, Status#player_status.scene, Status#player_status.copy_id}, 0, 2, ["nanTMKillBoss", 1, 1, Status#player_status.id, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image]),
                                    BossRefreshTime = data_wubianhai_new:get_wubianhai_config(boss_refresh_time),
                                    [{BossX, BossY}] = data_wubianhai_new:get_wubianhai_config(mon71),
                                    spawn(fun() -> 
                                                util:sleep(BossRefreshTime * 1000),
                                                lib_chat:send_TV({scene, Status#player_status.scene, Status#player_status.copy_id}, 0, 2, ["nanTMRefleshBoss", Status#player_status.scene, BossX, BossY])
                                        end);
                                false -> skip
                            end
                    end,
                    mod_wubianhai_new:kill_mon(PlayerId, MonId),
					refresh_task(SceneId, PlayerId);
				false -> skip
			end;
		false -> skip
	end.

%% 组队模式杀怪累计物品
team_kill_mon([], _MonId) -> skip;
team_kill_mon([H | T], MonId) ->
    case mod_wubianhai_new:is_in_arena(H) of
        false -> skip;
        _Any ->
            case misc:get_player_process(H) of
                Pid when is_pid(Pid) ->
                    gen_server:cast(Pid, {'wubianhai_team_kill_mon', MonId});
                _ ->
                    skip
            end
    end,
    team_kill_mon(T, MonId).

%% 玩家死亡处理
%% 杀人与被杀玩家均要通知
kill_player(Player, Killed) ->
	PlayerId = Player#player_status.id,
	PlayerName = Player#player_status.nickname,
	PlayerScene= Player#player_status.scene,
	KilledId = Killed#player_status.id,
	KilledName = Killed#player_status.nickname,
	KilledScene= Killed#player_status.scene,
	{T1, T2, T3, T4, T5, T6, T7, TName1, TName2, TName3, TName4, TName5, TName6, _TName7, K1, K2, K3, KillName1, KillName2, KillName3} = mod_wubianhai_new:killed_by_others(KilledId),
	[NewT1, NewT2, NewT3, NewT4, NewT5, NewT6, NewT7, NewK1, NewK2, NewK3] = mod_wubianhai_new:kill_others(PlayerId, T1, T2, T3, T4, T5, T6, T7, 1, 1, 1),
	%% 给杀人者返回的信息
	case NewT1 of
		1 -> L1 = [{T1, TName1}];
		_ -> L1 = []
	end,
	case NewT2 of
		1 -> L2 = [{T2, TName2} | L1];
		_ -> L2 = L1
	end,
	case NewT3 of
		1 -> L3 = [{T3, TName3} | L2];
		_ -> L3 = L2
	end,
	case NewT4 of
		1 -> L4 = [{T4, TName4} | L3];
		_ -> L4 = L3
	end,
	case NewT5 of
		1 -> L5 = [{T5, TName5} | L4];
		_ -> L5 = L4
	end,
	case NewT6 of
		1 -> L6 = [{T6, TName6} | L5];
		_ -> L6 = L5
	end,
	case NewT7 of
		%1 -> L7 = [{T7, TName7} | L6];
        1 -> L7 = L6;
		_ -> L7 = L6
	end,
	case NewK1 of
		1 -> L8 = [{NewK1, KillName1} | L7];
		_ -> L8 = L7
	end,
	case NewK2 of
		1 -> L9 = [{NewK2, KillName2} | L8];
		_ -> L9 = L8
	end,
	case NewK3 of
		1 -> L10 = [{NewK3, KillName3} | L9];
		_ -> L10 = L9
	end,

	%% 给被杀者返回的信息
	case T1 of
		1 -> L11 = [{T1, TName1}];
		_ -> L11 = []
	end,
	case T2 of
		1 -> L12 = [{T2, TName2} | L11];
		_ -> L12 = L11
	end,
	case T3 of
		1 -> L13 = [{T3, TName3} | L12];
		_ -> L13 = L12
	end,
	case T4 of
		1 -> L14 = [{T4, TName4} | L13];
		_ -> L14 = L13
	end,
	case T5 of
		1 -> L15 = [{T5, TName5} | L14];
		_ -> L15 = L14
	end,
	case T6 of
		1 -> L16 = [{T6, TName6} | L15];
		_ -> L16 = L15
	end,
	case T7 of
		%1 -> L17 = [{T7, TName7} | L16];
        1 -> L17 = L16;
		_ -> L17 = L16
	end,
	case K1 of
		1 -> L18 = [{K1, KillName1} | L17];
		_ -> L18 = L17
	end,
	case K2 of
		1 -> L19 = [{K2, KillName2} | L18];
		_ -> L19 = L18
	end,
	case K3 of
		1 -> L20 = [{K3, KillName3} | L19];
		_ -> L20 = L19
	end,
	%% 杀人与被杀，根据任务不同，显示也会不同
	Bin1 = pack1(PlayerName, L20),
	Bin2 = pack2(KilledName, L10),
	{ok, BinData1} = pt_640:write(64005, Bin1),
	{ok, BinData2} = pt_640:write(64005, Bin2),
	lib_server_send:send_to_uid(KilledId, BinData1),
	lib_server_send:send_to_uid(PlayerId, BinData2),
	refresh_task(PlayerScene, PlayerId),
	refresh_task(KilledScene, KilledId).

pack1(PlayerName, List) ->
	PlayerName1 = list_to_binary(PlayerName),
	PL = byte_size(PlayerName1),
    Fun1 = fun(Elem1) ->
				{T, TName} = Elem1,
				TName1 = list_to_binary(TName),
				TL     = byte_size(TName1),
				<<TL:16, TName1/binary, T:8>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List]),
    Size1  = length(List),
    <<2:8, PL:16, PlayerName1/binary, Size1:16, BinList1/binary>>.

pack2(KilledName, List) ->
	KilledName1 = list_to_binary(KilledName),
	KL = byte_size(KilledName1),
    Fun1 = fun(Elem1) ->
				{T, TName} = Elem1,
				TName1 = list_to_binary(TName),
				TL     = byte_size(TName1),
				<<TL:16, TName1/binary, T:8>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List]),
    Size1  = length(List),
    <<1:8, KL:16, KilledName1/binary, Size1:16, BinList1/binary>>.

pack3(List1) ->
	%% List1
    Fun1 = fun(Elem1) ->
				{Id1, Wupin, CNum, ANum, KillName, NowKill, KillNum, GetAward, AwardWupin, Exp, Lilian, MonId, MonX, MonY} = Elem1,
				Wupin1 = list_to_binary(Wupin),
				WL     = byte_size(Wupin1),
				KillName1 = list_to_binary(KillName),
				KL        = byte_size(KillName1),
				AwardWupin1 = list_to_binary(AwardWupin),
				WL1     = byte_size(AwardWupin1),
				<<Id1:32, WL:16, Wupin1/binary, CNum:16, ANum:16, KL:16, KillName1/binary, NowKill:16, KillNum:16, GetAward:8, WL1:16, AwardWupin1/binary, Exp:32, Lilian:32, MonId:32, MonX:16, MonY:16>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List1]),
    Size1  = length(List1),
    <<Size1:16, BinList1/binary>>.

pack(List1, BossRefresh, RestTime, List2) ->
	%% List1
    Fun1 = fun(Elem1) ->
				{Id1, Wupin, CNum, ANum, KillName, NowKill, KillNum, GetAward, AwardWupin, Exp, Lilian, MonId, MonX, MonY} = Elem1,
				Wupin1 = list_to_binary(Wupin),
				WL     = byte_size(Wupin1),
				KillName1 = list_to_binary(KillName),
				KL        = byte_size(KillName1),
				AwardWupin1 = list_to_binary(AwardWupin),
				WL1     = byte_size(AwardWupin1),
				<<Id1:32, WL:16, Wupin1/binary, CNum:16, ANum:16, KL:16, KillName1/binary, NowKill:16, KillNum:16, GetAward:8, WL1:16, AwardWupin1/binary, Exp:32, Lilian:32, MonId:32, MonX:16, MonY:16>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List1]),
    Size1  = length(List1),
	%% List2
	Fun2 = fun(Elem2) ->
				<<Elem2:32>>
    end,
    BinList2 = list_to_binary([Fun2(X) || X <- List2]),
    Size2  = length(List2),
    <<Size1:16, BinList1/binary, BossRefresh:32, RestTime:32, Size2:16, BinList2/binary>>.

%% 把[{{is_in_arena, Id}, _}]转换为[Id]
list_deal([], L2) -> L2;
list_deal([H | T], L2) -> 
	case H of
		{{is_in_arena, Id}, _} -> list_deal(T, [Id | L2]);
		_ -> list_deal(T, L2)
	end.

%% 把[{Id, Value}]转换为[Id]
deal_to_id([], L2) -> L2;
deal_to_id([{Id, _} | T], L2) -> deal_to_id(T, [Id | L2]).

%% 更新数据库
update_database(PlayerId, Task1Num, Task2Num, Task3Num, Task4Num, Task5Num, Task6Num, Task7Num, KillNum) ->
	SQL1  = io_lib:format(?SQL_PLAYER_WUBIANHAI_DATA, [PlayerId]),
	case db:get_row(SQL1) of
		[] -> 
			SQL2 = io_lib:format(?SQL_INSERT_PLAYER_WUBIANHAI, [PlayerId, Task1Num, Task2Num, Task3Num, Task4Num, Task5Num, Task6Num, Task7Num, KillNum]),
			db:execute(SQL2);
		_ -> 
			SQL2 = io_lib:format(?SQL_WUBIANHAI_DPDATE_WUBIANHAI, [Task1Num, Task2Num, Task3Num, Task4Num, Task5Num, Task6Num, Task7Num, KillNum, PlayerId]),
			db:execute(SQL2)
	end.

get_from_database(PlayerId) ->
	SQL1  = io_lib:format(?SQL_PLAYER_WUBIANHAI_DATA, [PlayerId]),
	case db:get_row(SQL1) of
		[] -> [0,0,0,0,0,0,0,0];
		Any -> Any
	end.

%% 判断活动是否正在进行
is_opening(Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute) ->
	%[Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute] = mod_wubianhai_new:get_begin_end_time(),
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
	Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60 + Second,
	case Config_Begin=<NowTime andalso NowTime<Config_End of
		true -> true;
		false -> false
	end.

%% 发送奖励物品
send_award(_GoodsPid, [], _Tid, _PlayerId) -> ok;
send_award(GoodsPid, [H | T], Tid, PlayerId) -> 
	case Tid of
		1 -> gen:call(GoodsPid, '$gen_call', {'give_more_bind', [], [{H, 1}]});
        2 -> gen:call(GoodsPid, '$gen_call', {'give_more_bind', [], [{H, 1}]});
        3 -> gen:call(GoodsPid, '$gen_call', {'give_more_bind', [], [{H, 1}]});
        4 -> gen:call(GoodsPid, '$gen_call', {'give_more_bind', [], [{H, 1}]});
        5 -> gen:call(GoodsPid, '$gen_call', {'give_more', [], [{H, 1}]});
        _ -> gen:call(GoodsPid, '$gen_call', {'give_more', [], [{H, 1}]})
	end,
	log:log_goods(wb_sea, Tid, H, 1, PlayerId),
	send_award(GoodsPid, T, Tid, PlayerId).

%% 发送队伍击杀boss传闻
send_tv_to_all([], SceneId, CopyId, List) ->
    %io:format("List:~p~n", [List]),
    lib_chat:send_TV({scene, SceneId, CopyId}, 0, 2, List);
send_tv_to_all([H | T], SceneId, CopyId, List) ->
    List2 = lib_player:get_player_info(H, sendTv_Message),
	case List2 of
		false -> NewList = List;
		_ -> NewList = List ++ List2
	end,
    send_tv_to_all(T, SceneId, CopyId, NewList).

%% 三职业进入南天门有Buff加成
add_wubianhai_buff(Team) when is_record(Team, team) ->
    MemberIdList = [Mb#mb.id || Mb <- Team#team.member],
    %% 判断队伍人数
    case length(MemberIdList) =:= ?WUBIANHAI_MEMBER_MAX of
        true -> 
            %% 判断是否三职业
            case lib_team:is_three_career(Team) of
                true -> 
                    add_buff(MemberIdList);
                false -> skip
            end;
        false -> skip
    end;
add_wubianhai_buff(_Any) -> skip.

%% 给队员加Buff
add_buff([]) -> skip;
add_buff([H | T]) ->
    %% 给玩家发送加Buff提示
    %{ok, BinData} = pt_640:write(64010, 1),
    %lib_server_send:send_to_uid(H, BinData),
    case misc:get_player_process(H) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'add_wubianhai_buff'});
        _ ->
            skip
    end,
    add_buff(T).

%% 去除南天门内的三职业Buff加成
del_wubianhai_buff(Team) when is_record(Team, team) ->
    MemberIdList = [Mb#mb.id || Mb <- Team#team.member],
    del_buff(MemberIdList);
del_wubianhai_buff(_Any) -> skip.

%% 删除队员的Buff
del_buff([]) -> skip;
del_buff([H | T]) ->
    case misc:get_player_process(H) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'del_wubianhai_buff'});
        _ ->
            skip
    end,
    del_buff(T).


%%%%%%%% 玩家进程调用的函数 %%%%%%%%%
server_cast_add_buff(Status) ->
    BuffType = 214101,
    case data_goods_effect:get_val(BuffType, buff) of
        [] ->
            {noreply, Status};
        {Type, AttributeId, Value, Time, SceneLimit} ->
            Now = util:unixtime(),
            %% 判断是否已经有该Buff
            case lib_buff:match_two2(Status#player_status.player_buff, AttributeId, []) of
            %case buff_dict:match_two2(Status#player_status.id, AttributeId) of
                [] -> 
                    NewBuffInfo = lib_player:add_player_buff(Status#player_status.id, Type, BuffType, AttributeId, Value, Now+Time, SceneLimit),
                    %% 修改解冻状态
                    buff_dict:insert_buff(NewBuffInfo),
                    lib_player:send_buff_notice(Status, [NewBuffInfo]),
                    BuffAttribute = lib_player:get_buff_attribute(Status#player_status.id, Status#player_status.scene),
                    NewPlayerStatus = lib_player:count_player_attribute(Status#player_status{buff_attribute = BuffAttribute}),
                    lib_player:send_attribute_change_notify(NewPlayerStatus, 0),
                    {noreply, NewPlayerStatus};
                _ -> 
                    {noreply, Status}
            end
    end.

server_cast_del_buff(Status) ->
    BuffType = 214101,
    case data_goods_effect:get_val(BuffType, buff) of
        [] ->
            {noreply, Status};
        {_Type, AttributeId, _Value, _Time, _SceneLimit} ->
            Now = util:unixtime(),
            %% 判断是否已经有该Buff
            case lib_buff:match_two2(Status#player_status.player_buff, AttributeId, []) of
            %case buff_dict:match_two2(Status#player_status.id, AttributeId) of
                [] -> 
                    {noreply, Status};
                [Buff] -> 
                    lib_player:del_buff(Buff#ets_buff.id),
                    buff_dict:delete_id(Buff#ets_buff.id),
                    NewBuff = Buff#ets_buff{end_time = Now},
                    lib_player:send_buff_notice(Status, [NewBuff]),
                    BuffAttribute = lib_player:get_buff_attribute(Status#player_status.id, Status#player_status.scene),
                    NewPlayerStatus = lib_player:count_player_attribute(Status#player_status{buff_attribute = BuffAttribute}),
                    lib_player:send_attribute_change_notify(NewPlayerStatus, 0),
                    {noreply, NewPlayerStatus};
                _Any ->
                    catch util:errlog("mod_server_cast:del_wubianhai_buff error: ~p~n", [_Any]),
                    {noreply, Status}
            end
    end.

in_wubianhai_list([], L) -> L;
in_wubianhai_list([H | T], L) -> 
    case mod_wubianhai_new:is_in_arena(H) of
        false -> in_wubianhai_list(T, L);
        _ -> in_wubianhai_list(T, [H | L])
    end.

load_player_info(Id, PlayerLv, RoomId) ->
    case data_wubianhai_new:get_task_lv(PlayerLv) of
        1 ->
            [Tid1, MonId1, Num1, AwardIdList1, Exp1, Lilian1, TaskName1, MonX1, MonY1] = data_wubianhai_new:get_wubianhai_config(task1_1),
            [Tid2, MonId2, Num2, AwardIdList2, Exp2, Lilian2, TaskName2, MonX2, MonY2] = data_wubianhai_new:get_wubianhai_config(task2_1),
            [Tid3, MonId3, Num3, AwardIdList3, Exp3, Lilian3, TaskName3, MonX3, MonY3] = data_wubianhai_new:get_wubianhai_config(task3_1),
            [Tid4, MonId4, Num4, AwardIdList4, Exp4, Lilian4, TaskName4, MonX4, MonY4] = data_wubianhai_new:get_wubianhai_config(task4_1),
            [Tid5, MonId5, Num5, AwardIdList5, Exp5, Lilian5, TaskName5, MonX5, MonY5] = data_wubianhai_new:get_wubianhai_config(task5_1),
            [Tid6, MonId6, Num6, AwardIdList6, Exp6, Lilian6, TaskName6, MonX6, MonY6] = data_wubianhai_new:get_wubianhai_config(task6_1),
            [Tid7, MonId7, Num7, AwardIdList7, Exp7, Lilian7, TaskName7, MonX7, MonY7] = data_wubianhai_new:get_wubianhai_config(task7_1);
        2 ->
            [Tid1, MonId1, Num1, AwardIdList1, Exp1, Lilian1, TaskName1, MonX1, MonY1] = data_wubianhai_new:get_wubianhai_config(task1_2),
            [Tid2, MonId2, Num2, AwardIdList2, Exp2, Lilian2, TaskName2, MonX2, MonY2] = data_wubianhai_new:get_wubianhai_config(task2_2),
            [Tid3, MonId3, Num3, AwardIdList3, Exp3, Lilian3, TaskName3, MonX3, MonY3] = data_wubianhai_new:get_wubianhai_config(task3_2),
            [Tid4, MonId4, Num4, AwardIdList4, Exp4, Lilian4, TaskName4, MonX4, MonY4] = data_wubianhai_new:get_wubianhai_config(task4_2),
            [Tid5, MonId5, Num5, AwardIdList5, Exp5, Lilian5, TaskName5, MonX5, MonY5] = data_wubianhai_new:get_wubianhai_config(task5_2),
            [Tid6, MonId6, Num6, AwardIdList6, Exp6, Lilian6, TaskName6, MonX6, MonY6] = data_wubianhai_new:get_wubianhai_config(task6_2),
            [Tid7, MonId7, Num7, AwardIdList7, Exp7, Lilian7, TaskName7, MonX7, MonY7] = data_wubianhai_new:get_wubianhai_config(task7_2);
        3 ->
            [Tid1, MonId1, Num1, AwardIdList1, Exp1, Lilian1, TaskName1, MonX1, MonY1] = data_wubianhai_new:get_wubianhai_config(task1_3),
            [Tid2, MonId2, Num2, AwardIdList2, Exp2, Lilian2, TaskName2, MonX2, MonY2] = data_wubianhai_new:get_wubianhai_config(task2_3),
            [Tid3, MonId3, Num3, AwardIdList3, Exp3, Lilian3, TaskName3, MonX3, MonY3] = data_wubianhai_new:get_wubianhai_config(task3_3),
            [Tid4, MonId4, Num4, AwardIdList4, Exp4, Lilian4, TaskName4, MonX4, MonY4] = data_wubianhai_new:get_wubianhai_config(task4_3),
            [Tid5, MonId5, Num5, AwardIdList5, Exp5, Lilian5, TaskName5, MonX5, MonY5] = data_wubianhai_new:get_wubianhai_config(task5_3),
            [Tid6, MonId6, Num6, AwardIdList6, Exp6, Lilian6, TaskName6, MonX6, MonY6] = data_wubianhai_new:get_wubianhai_config(task6_3),
            [Tid7, MonId7, Num7, AwardIdList7, Exp7, Lilian7, TaskName7, MonX7, MonY7] = data_wubianhai_new:get_wubianhai_config(task7_3);
        _ ->
            [Tid1, MonId1, Num1, AwardIdList1, Exp1, Lilian1, TaskName1, MonX1, MonY1] = data_wubianhai_new:get_wubianhai_config(task1_4),
            [Tid2, MonId2, Num2, AwardIdList2, Exp2, Lilian2, TaskName2, MonX2, MonY2] = data_wubianhai_new:get_wubianhai_config(task2_4),
            [Tid3, MonId3, Num3, AwardIdList3, Exp3, Lilian3, TaskName3, MonX3, MonY3] = data_wubianhai_new:get_wubianhai_config(task3_4),
            [Tid4, MonId4, Num4, AwardIdList4, Exp4, Lilian4, TaskName4, MonX4, MonY4] = data_wubianhai_new:get_wubianhai_config(task4_4),
            [Tid5, MonId5, Num5, AwardIdList5, Exp5, Lilian5, TaskName5, MonX5, MonY5] = data_wubianhai_new:get_wubianhai_config(task5_4),
            [Tid6, MonId6, Num6, AwardIdList6, Exp6, Lilian6, TaskName6, MonX6, MonY6] = data_wubianhai_new:get_wubianhai_config(task6_4),
            [Tid7, MonId7, Num7, AwardIdList7, Exp7, Lilian7, TaskName7, MonX7, MonY7] = data_wubianhai_new:get_wubianhai_config(task7_4)
    end,
    %% 击杀玩家信息
    [{KillName1, KillNum1}, {KillName2, KillNum2}, {KillName3, KillNum3}] = data_wubianhai_new:get_wubianhai_config(kill_task),
    %% 从数据库读数据
    [Task1Num, Task2Num, Task3Num, Task4Num, Task5Num, Task6Num, Task7Num, KillNum] = lib_wubianhai_new:get_from_database(Id),
    case KillNum > KillNum1 of
        true -> NowKill1 = KillNum1;
        false -> NowKill1 = KillNum
    end,
    case KillNum > KillNum2 of
        true -> NowKill2 = KillNum2;
        false -> NowKill2 = KillNum
    end,
    case KillNum > KillNum3 of
        true -> NowKill3 = KillNum3;
        false -> NowKill3 = KillNum
    end,
    %% 触发任务
    T1 = #task{id=Id, tid=Tid1, mon_id=MonId1, num=Num1, now_num = Task1Num, award_id_list=AwardIdList1, exp=Exp1, lilian=Lilian1, task_name=TaskName1, mon_x = MonX1, mon_y = MonY1},
    T2 = #task{id=Id, tid=Tid2, mon_id=MonId2, num=Num2, now_num = Task2Num, award_id_list=AwardIdList2, exp=Exp2, lilian=Lilian2, task_name=TaskName2, mon_x = MonX2, mon_y = MonY2},
    T3 = #task{id=Id, tid=Tid3, mon_id=MonId3, num=Num3, now_num = Task3Num, award_id_list=AwardIdList3, exp=Exp3, lilian=Lilian3, task_name=TaskName3, mon_x = MonX3, mon_y = MonY3},
    T4 = #task{id=Id, tid=Tid4, mon_id=MonId4, num=Num4, now_num = Task4Num, award_id_list=AwardIdList4, exp=Exp4, lilian=Lilian4, task_name=TaskName4, mon_x = MonX4, mon_y = MonY4},
    T5 = #task{id=Id, tid=Tid5, mon_id=MonId5, num=Num5, now_num = Task5Num, award_id_list=AwardIdList5, exp=Exp5, lilian=Lilian5, task_name=TaskName5, kill_name = KillName1, kill_num = KillNum1, now_kill = NowKill1, mon_x = MonX5, mon_y = MonY5},
    T6 = #task{id=Id, tid=Tid6, mon_id=MonId6, num=Num6, now_num = Task6Num, award_id_list=AwardIdList6, exp=Exp6, lilian=Lilian6, task_name=TaskName6, kill_name = KillName2, kill_num = KillNum2, now_kill = NowKill2, mon_x = MonX6, mon_y = MonY6},
    _T7 = #task{id=Id, tid=Tid7, mon_id=MonId7, num=Num7, now_num = Task7Num, award_id_list=AwardIdList7, exp=Exp7, lilian=Lilian7, task_name=TaskName7, kill_name = KillName3, kill_num = KillNum3, now_kill = NowKill3, mon_x = MonX7, mon_y = MonY7},
    NewArena = #arena{
        id = Id, 
        player_lv = PlayerLv,
        room_id = RoomId,
        task1 = T1,
        task2 = T2,
        task3 = T3,
        task4 = T4,
        task5 = T5,
        task6 = T6},
    put({player_task, Id}, NewArena),
    NewArena.

get_mon_list() ->
    Mon1 = data_mon:get(42001),
    Mon2 = data_mon:get(42002),
    Mon3 = data_mon:get(42003),
    Mon4 = data_mon:get(42004),
    Mon5 = data_mon:get(42005),
    Mon6 = data_mon:get(42006),
    Mon7 = data_mon:get(42007),
    Lv = case catch mod_wubianhai_new:get_world_lv() of
        _Lv when is_integer(_Lv) ->
            _Lv;
        _ ->
            data_wubianhai_new:get_wubianhai_config(apply_level)
    end,
    MonList = 
    [
        {Mon1#ets_mon.mid, Mon1#ets_mon.name, Mon1#ets_mon.kind, 11, 46, 40, 0}, 
        {Mon2#ets_mon.mid, Mon2#ets_mon.name, Mon2#ets_mon.kind, 48, 22, 40, 0}, 
        {Mon3#ets_mon.mid, Mon3#ets_mon.name, Mon3#ets_mon.kind, 18, 54, Lv, 0}, 
        {Mon4#ets_mon.mid, Mon4#ets_mon.name, Mon4#ets_mon.kind, 5, 29, Lv, 0}, 
        {Mon5#ets_mon.mid, Mon5#ets_mon.name, Mon5#ets_mon.kind, 37, 44, Lv, 0}, 
        {Mon6#ets_mon.mid, Mon6#ets_mon.name, Mon6#ets_mon.kind, 12, 17, Lv, 0}, 
        {Mon7#ets_mon.mid, Mon7#ets_mon.name, Mon7#ets_mon.kind, 23, 26, Lv, 0}
    ],
    WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
    Data = pack_allmon_list(MonList),
    pt:pack(12095, <<WubianhaiSceneId:32, Data/binary>>).

pack_allmon_list([]) ->
    <<0:16, <<>>/binary>>;
pack_allmon_list(MonList) ->
    Rlen = length(MonList),
    F = fun(MonInfo) ->
            {Mid, Name, Kind, X, Y, Level, Out} = MonInfo,
            %Name = pt:write_string(_Name),
            NameLen = byte_size(Name),
            <<Mid:32, NameLen:16, Name/binary, Kind:8, X:16, Y:16, Level:16, Out:8>>
    end,
    RB = list_to_binary([F(D) || D <- MonList]),
    <<Rlen:16, RB/binary>>.
