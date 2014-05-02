%%%-----------------------------------
%%% @Module  : lib_scene
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.05.08
%%% @Description: 场景信息
%%%-----------------------------------
-module(lib_scene).
-export([
		    change_scene/6,
            change_scene_queue/6,
            player_change_scene_queue/6,
			change_scene_4_revive/6,
            change_speed/9,
            leave_scene/1,
            enter_scene/1,
            del_all_area/2,
            send_scene_info_to_uid/5,
            revive_to_scene/2,
            get_data/1,
            is_blocked/3,
            can_be_moved/3,
            is_safe/3,
            is_safe_scene/1,
            is_active_scene/1,
            is_clusters_scene/1,
            check_enter/2,
            check_dungeon_requirement/2,
            enter_normal_scene/3,
            enter_dungeon_scene/3,           %% 进入副本场景.
			check_dungeon_physical/3,        %% 检查进入副本的体力值是否满足条件.			
            check_and_enter_dungeon_scene/3, %% 检查进入副本条件.
            get_scene_user/1,
            get_scene_user/2,
            get_scene_user_field/3,
            get_scene_mon/2,
            get_scene_mon_num/2,
            get_scene_mon_num_by_kind/3,
            is_dungeon_scene/1,			
			is_transferable/1,  			 %% 是否可以传送.
            refresh_npc_ico/1,
            get_res_type/1,
            get_scene_pkstatus/1,
            get_scene_name/1,
            get_scene_user_by_id/2,
			player_change_scene/6,
			scene_check_enter/2,
            save_scene_user_by_id/1,
            get_born_xy/1,
            repair_xy/4,
            is_broadcast_scene/1,
            change_scene_handler/3,
            get_scene_user_1v1/5, %% 获取1v1必要的信息
            get_main_city_x_y/0
        ]).
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-include("predefine.hrl").

%% 检测玩家能否进入一个场景
%%@param Id 玩家ID
%%@param SceneId 目标场景ID
%%@return {error,Reason}|{true,{SceneId, SceneX, SceneY, SceneName, SceneId, PlayerStatus}}
scene_check_enter(Id,SceneId) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:call(Pid, {scene_check_enter,SceneId});
        _ ->
            {error,no_pid}
    end.

%% 游戏内更改玩家场景信息
%%@param Id 玩家ID
%%@param SceneId 目标场景ID
%%@param CopyId 房间号ID 为0时，普通房间，非0值切换房间。值相同，在同一个房间。
%%@param X 目标场景出生点X
%%@param Y 目标场景出生点Y
%%@param Need_Out 是否需要特殊处理场景   true|false（不需要）
player_change_scene(Id,SceneId,CopyId,X,Y,Need_Out) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {change_scene, SceneId, CopyId, X, Y,Need_Out});
        _ ->
            void
    end.

%%切换场景方法
%%@param PlayerStatus 玩家当前状态
%%@param SceneId 目标场景ID
%%@param CopyId 房间号ID
%%@param X 目标坐标X
%%@param Y 目标坐标Y
%%@param Need_Out 是否需要特殊处理场景   true|false（不需要）
%%@return 新玩家状态
change_scene(PlayerStatus,T_SceneId,T_CopyId,T_X,T_Y,Need_Out)->
	%% %%判断是否在某些特定的场景里(竞技场、帮战)，从哪来，回哪去
	Scene_id_list = [106,223,440,250,251,252,288,289,290,291,292,293,294,295,296],
	Ps_scene_id = PlayerStatus#player_status.scene,
	Flag = lists:member(PlayerStatus#player_status.scene, Scene_id_list),
	% 通知离开场景
    lib_scene:leave_scene(PlayerStatus),
	%% 是否需要特殊处理场景
	God_Flag = (lists:member(Ps_scene_id, data_god:get(scene_id1)) 
			andalso lists:member(T_SceneId, data_god:get(scene_id2)))
		  orelse (lists:member(Ps_scene_id, data_god:get(scene_id2)) 
			andalso lists:member(T_SceneId, data_god:get(scene_id1)))
		  orelse (lists:member(Ps_scene_id, data_god:get(scene_id1)) 
			andalso lists:member(T_SceneId, data_god:get(scene_id1))),
	if
		God_Flag=:=true-> %%诸神场景
			SceneId = T_SceneId,CopyId = T_CopyId,X = T_X,Y = T_Y;
		(PlayerStatus#player_status.scene=:=250 andalso T_SceneId=:= 251)
		  orelse (PlayerStatus#player_status.scene=:=251 andalso T_SceneId=:= 250)
		  orelse PlayerStatus#player_status.scene=:=250 andalso T_SceneId=:= 250-> %%1v1场景
			SceneId = T_SceneId,CopyId = T_CopyId,X = T_X,Y = T_Y;
		true->
			Kf3v3Ids = data_kf_3v3:get_config(scene_pk_ids),
			Kf3v3TSceneIdInBool = lists:member(T_SceneId, Kf3v3Ids),
			Kf3v3SceneIdInBool = lists:member(PlayerStatus#player_status.scene, Kf3v3Ids),
			if 
				%% 3v3场景
				(PlayerStatus#player_status.scene =:= 252 andalso Kf3v3TSceneIdInBool =:= true)
				  orelse (Kf3v3SceneIdInBool =:= true andalso T_SceneId =:= 252)
				  orelse PlayerStatus#player_status.scene =:= 252 andalso T_SceneId=:= 252 ->
					SceneId = T_SceneId,CopyId = T_CopyId,X = T_X,Y = T_Y;
				true ->
					case Need_Out of
						false->
							SceneId = T_SceneId,CopyId = T_CopyId,X = T_X,Y = T_Y;
						true->
							case Flag of
								false-> SceneId = T_SceneId,CopyId = T_CopyId,X = T_X,Y = T_Y;
								true->
									SceneId = PlayerStatus#player_status.scene_old,
									CopyId = PlayerStatus#player_status.copy_id_old,
									X = PlayerStatus#player_status.x_old,
									Y = PlayerStatus#player_status.y_old
							end
					end
			end
	end,

	%%加载场景
	S = lib_scene:get_data(SceneId),
	{ok, Bin} = pt_120:write(12005, [
			SceneId,
			X,
			Y,
			S#ets_scene.name,
			S#ets_scene.id
	]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, Bin),
	if
		%%普通场景切换，才记录历史场景,
		PlayerStatus#player_status.copy_id=:=0 andalso Flag=:=false ->
			NewPlayerStatus = PlayerStatus#player_status{
				scene=SceneId,copy_id=CopyId,x=X, y=Y,
				scene_old=PlayerStatus#player_status.scene,
				copy_id_old=PlayerStatus#player_status.copy_id,
				x_old=PlayerStatus#player_status.x,
				y_old=PlayerStatus#player_status.y
			};
		true->
			NewPlayerStatus = PlayerStatus#player_status{
				scene=SceneId,copy_id=CopyId,x=X, y=Y
			}
	end,
    NewPlayerStatus1 = lib_scene:change_scene_handler(NewPlayerStatus, NewPlayerStatus#player_status.scene, PlayerStatus#player_status.scene),
    %% 死亡时被传送则自动复活
    case NewPlayerStatus1#player_status.hp =< 0 of
        true ->
            NewPlayerStatus2 = NewPlayerStatus1#player_status{
                hp = 100
            },
            lib_player:send_attribute_change_notify(NewPlayerStatus2, 1);
        false ->
            NewPlayerStatus2  = NewPlayerStatus1
    end,
	NewPlayerStatus2.

%%切换场景方法--复活专用
%%@param PlayerStatus 玩家当前状态
%%@param SceneId 目标场景ID
%%@param CopyId 房间号ID
%%@param X 目标坐标X
%%@param Y 目标坐标Y
%%@param Revive_type (1原地 2回城)
%%@return 新玩家状态
change_scene_4_revive(PlayerStatus,SceneId,CopyId,X,Y,Revive_type)->
	%%判断是否要离开场景
	case Revive_type of
		1-> %通知周边玩家他站起来了
			{ok,DataBin_12003} = pt_120:write(12003, PlayerStatus),
			lib_server_send:send_to_area_scene(SceneId, CopyId, X, Y, DataBin_12003);
		_->
			% 通知离开场景
    		lib_scene:leave_scene(PlayerStatus)
	end,
	%%加载场景
	S = lib_scene:get_data(SceneId),
	{ok, Bin} = pt_120:write(12083, [
			Revive_type,									 
			SceneId,
			X,
			Y,
			S#ets_scene.name,
			PlayerStatus#player_status.hp,
			PlayerStatus#player_status.mp,
			PlayerStatus#player_status.gold,
			PlayerStatus#player_status.bgold,
			PlayerStatus#player_status.att_protected
		]
	),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, Bin),
	NewPlayerStatus = PlayerStatus#player_status{scene=SceneId,copy_id=CopyId,x=X, y=Y},
	NewPlayerStatus.

%% 游戏内更改玩家场景信息(公共线调用)
%%@param Id 玩家ID
%%@param SceneId 目标场景ID
%%@param CopyId 房间号ID 为0时，普通房间，非0值切换房间。值相同，在同一个房间。
%%@param X 目标场景出生点X
%%@param Y 目标场景出生点Y
%%@param Value lists() 用于在换场景后的数据处理,换线后会执行mod_server_cast:set_data_sub(Value, Status)
%%             | 0     不做处理
player_change_scene_queue(Id,SceneId,CopyId,X,Y,Value) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            catch gen_server:cast(Pid, {'change_scene_sign', [SceneId, CopyId, X, Y, Value]});
        _ ->
            void
    end.

%%排队-切换场景方法
%%@param PlayerStatus 玩家当前状态
%%@param SceneId 目标场景ID
%%@param CopyId 房间号ID
%%@param X 目标坐标X
%%@param Y 目标坐标Y
%%@param Value 自定义结构,用于在换场景后的数据处理
%%@return  
change_scene_queue(PlayerStatus, SceneId, CopyId, X, Y, Value) -> 
    catch gen_server:cast(PlayerStatus#player_status.pid, {'change_scene_sign', [SceneId, CopyId, X, Y, Value]}).

%%改变速度
change_speed(Id, PlayerId, Platform, Scene, CopyId, X, Y, Speed, State)->
    {ok, BinData} = pt_120:write(12082, [State, Id, PlayerId, Platform, Speed]),
    lib_server_send:send_to_area_scene(Scene, CopyId, X, Y, BinData).

%%离开当前场景
%%Sid:场景id
%%player_status记录
leave_scene(Status) ->
    mod_scene_agent:leave(Status).

%%进入当前场景
%%player_status记录
enter_scene(Status) ->
    mod_scene_agent:join(Status).

%%给用户发送场景信息 - 12002内容
send_scene_info_to_uid(Key, Sid, CopyId, X, Y) ->
    mod_scene_agent:send_scene_info_to_uid(Key, Sid, CopyId, X, Y).

%% 删除怪物9宫格
del_all_area(SceneId, CopyId) ->
    mod_scene_agent:apply_cast(SceneId, lib_scene_agent, del_all_area, [CopyId]).

%% 复活进入场景
%% status复活前的状态，status1复活后的状态
revive_to_scene(Status1, Status2) ->
    %%告诉原来场景玩家你已经离开
    leave_scene(Status1),
    %%告诉复活点的玩家你进入场景进
    enter_scene(Status2),
    send_scene_info_to_uid([Status2#player_status.id, Status2#player_status.platform, Status2#player_status.server_num], Status2#player_status.scene, 
						   Status2#player_status.copy_id, Status2#player_status.x, 
						   Status2#player_status.y).

%% 获取场景信息，唯一id，区分是不是副本
get_data(Id) -> %data_scene:get(Id).
    case ets:lookup(?ETS_SCENE, Id) of
        []  -> 
            data_scene:get(Id);
        [S] -> 
            S
    end.


%% 进入场景条件检查
check_enter(Status, Id) ->
    %% 巡游中不允许传送
    case lib_marriage:marry_state(Status#player_status.marriage) of
        8 -> {false, data_scene_text:get_sys_msg(35)};
        _ ->
            %% 监狱中不能传送
            case Status#player_status.scene =:= 998 of
                true -> {false, data_scene_text:get_sys_msg(32)};
                false ->
                    %1.得到玩家当前场景数据.
                    PlayerScene = 
                    case get_data(Status#player_status.scene) of
                        [] ->
                            #ets_scene{};
                        SceneData ->
                            SceneData
                    end,
                    %2.判断场景是否可以传送.
                    case get_data(Id) of
                        [] ->
                            {false, data_scene_text:get_sys_msg(1)};
                        Scene ->
                            %% BOSS场景只能阵营模式或帮派模式进入
                            case Scene#ets_scene.type =:= ?SCENE_TYPE_BOSS andalso Status#player_status.pk#status_pk.pk_status =/= 2 andalso Status#player_status.pk#status_pk.pk_status =/= 3 of
                                true ->
                                    {false, data_scene_text:get_sys_msg(8)};
                                false ->
                                    case check_requirement(Status, Scene#ets_scene.requirement) of
                                        {false, Reason} -> 
                                            {false, Reason};
                                        {true} ->
                                            case Scene#ets_scene.type of
                                                %1.普通场景.
                                                ?SCENE_TYPE_NORMAL -> 
                                                    enter_normal_scene(Id, Scene, Status);

                                                %2.野外场景.
                                                ?SCENE_TYPE_OUTSIDE -> 
                                                    enter_normal_scene(Id, Scene, Status);

                                                %3.副本场景.
                                                ?SCENE_TYPE_DUNGEON ->
                                                    NowTime = util:unixtime(),
                                                    LastTime = 
                                                    case get({dungeon, Status#player_status.id}) of
                                                        undefined -> 
                                                            NowTime-6;
                                                        LastTime1 ->
                                                            LastTime1
                                                    end,
                                                    LastTime2 = NowTime - LastTime,

                                                   % {CoolTime, _Score, _PassTime} = mod_dungeon_data:get_cooling_time(
                                                   %     Status#player_status.pid_dungeon_data,																 
                                                   %     Status#player_status.id,
                                                   %     Id),
													
                                                    %{CheckTeamCondition, CheckTeamText} = lib_dungeon:check_team_condition(Status, Id), 

                                                    if PlayerScene#ets_scene.type =:= ?SCENE_TYPE_GUILD orelse
                                                        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_ARENA orelse
                                                        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_BOSS orelse
                                                        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_ACTIVE ->								
                                                            {false, data_scene_text:get_sys_msg(28)};
                                                        true ->
                                                            %护送美女
                                                            HS = Status#player_status.husong,
                                                            IsChangeSceneSign = Status#player_status.change_scene_sign,
                                                            IsFlyMount = Status#player_status.mount#status_mount.fly_mount,
                                                            IsAutoStory = mod_dungeon_data:is_auto_story(
                                                                Status#player_status.pid_dungeon_data,																 
                                                                Status#player_status.id,
                                                                Id),
                                                            EnterTime = lib_dungeon:check_enter_time(Id),

                                                            if
																%1.检测进去副本时间限制.
																EnterTime == false ->
																	{false, data_dungeon_text:get_dungeon_text(7)};

																%1.检测队伍进去副本条件.
																%CheckTeamCondition == false ->
																%	{false, CheckTeamText};
																
                                                                %1.护送美女状态.					
                                                                HS#status_husong.husong=/=0 ->
                                                                    {false, data_dungeon_text:get_tower_text(1)};

                                                                %2.换线中.					
                                                                IsChangeSceneSign=/=0 ->
                                                                    {false, data_dungeon_text:get_tower_text(35)};

                                                                %3.在飞行坐骑上不能进入把副本.					
                                                                IsFlyMount=/=0 ->
                                                                    {false, data_dungeon_text:get_dungeon_text(5)};														

                                                                %4.副本操作太快.
                                                                LastTime2 =< 5 ->
                                                                    {false, data_dungeon_text:get_dungeon_text(3)};

                                                                %5.冷却时间没过.
                                                                %CoolTime > 0 ->
                                                                %    {false, data_dungeon_text:get_dungeon_text(4)};

                                                                %6.是否在挂机中.
                                                                IsAutoStory ->
                                                                    {false, data_dungeon_text:get_dungeon_text(6)};														

                                                                %7.非护送美女状态.
                                                                true->
                                                                    %put({dungeon, Status#player_status.id}, NowTime),
                                                                    check_and_enter_dungeon_scene(Id, Scene, Status)
                                                            end
                                                    end;

                                                %4.竞技场（依赖地图编辑器限制判断入场条件，等级、PK模式）.
                                                ?SCENE_TYPE_ARENA->
                                                    if 
                                                        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_NORMAL 
															orelse PlayerScene#ets_scene.type =:= ?SCENE_TYPE_OUTSIDE ->
															check_enter_arena(Id, Scene, Status);
                                                        true ->
															{false, data_scene_text:get_sys_msg(33)}
                                                    end;
												
												%% 跨服
												?SCENE_TYPE_CLUSTERS ->
													Kf3v3InScene = lists:member(Scene#ets_scene.id, data_kf_3v3:get_config(scene_pk_ids)),
													GodInScene = lists:member(Scene#ets_scene.id, data_god:get(scene_id1)),
													if 
                                                        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_NORMAL 
															orelse PlayerScene#ets_scene.type =:= ?SCENE_TYPE_OUTSIDE
															orelse Scene#ets_scene.id=:=251 
														  	orelse GodInScene =:= true
															orelse Kf3v3InScene =:= true ->
															check_enter_arena(Id, Scene, Status);
                                                        true ->
															{false, data_scene_text:get_sys_msg(33)}
                                                    end;

                                                %5.锁妖塔场景.
                                                ?SCENE_TYPE_TOWER -> 
                                                    %mod_dungeon:tower_next_level(Status#player_status.pid_dungeon, Id),
                                                    if PlayerScene#ets_scene.type =:= ?SCENE_TYPE_GUILD orelse
                                                        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_ARENA orelse
                                                        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_BOSS orelse
                                                        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_ACTIVE ->								
                                                            {false, data_scene_text:get_sys_msg(28)};
                                                        true ->
                                                            %护送美女
                                                            HS2 = Status#player_status.husong,
                                                            IsChangeSceneSign = Status#player_status.change_scene_sign,
                                                            IsFlyMount = Status#player_status.mount#status_mount.fly_mount,

                                                            if	
                                                                %1.护送美女状态.					
                                                                HS2#status_husong.husong=/=0 ->
                                                                    {false, data_dungeon_text:get_tower_text(1)};

                                                                %2.换线中.					
                                                                IsChangeSceneSign=/=0 ->
                                                                    {false, data_dungeon_text:get_tower_text(35)};

                                                                %3.在飞行坐骑上不能进入把副本.
                                                                IsFlyMount=/=0 ->
                                                                    {false, data_dungeon_text:get_dungeon_text(5)};														

                                                                %4.非护送美女状态.
                                                                true->
                                                                    check_and_enter_dungeon_scene(Id, Scene, Status)
                                                            end
                                                    end;

                                                _ ->
                                                    enter_normal_scene(Id, Scene, Status)
                                            end
                                    end
                            end
                    end
            end
    end.

%%竞技场进入检测
check_enter_arena(Id, Scene, Status)->
	%护送美女
	HS = Status#player_status.husong,
	if	
		%2.非护送美女状态.
		HS#status_husong.husong=:=0->
			{true, Id, Scene#ets_scene.x, Scene#ets_scene.y, 
			 Scene#ets_scene.name, Scene#ets_scene.id, Status};
		%3.护送美女状态.
		true->
			{false, data_scene_text:get_sys_msg(1)}
	end.

%% 逐个检查进入需求
check_requirement(_, []) ->
    {true};
check_requirement(Status, [{K, V} | T]) ->
    case K of
        lv -> %% 等级需求
            case Status#player_status.lv < V of
                true ->
                    Msg = data_scene_text:get_sys_msg(2)++integer_to_list(V)++data_scene_text:get_sys_msg(3),
                    {false, list_to_binary(Msg)};
                false ->
                    check_requirement(Status, T)
            end;
        item -> %% 物品需求
            case V > 0 of
                true ->
                    case lib_goods_util:get_task_goods_num(Status#player_status.id, V) > 0 of
                        false ->
                            Msg = [data_scene_text:get_sys_msg(4), 
								   data_goods_type:get_name(V) , 
								   data_scene_text:get_sys_msg(5)],
                            {false, list_to_binary(Msg)};
                        true ->
                            check_requirement(Status, T)
                    end;
                false ->
                    check_requirement(Status, T)
            end;
        team -> %% 组队需求
            case V of
                0 ->
                    check_requirement(Status, T);
                1 ->
                    case is_pid(Status#player_status.pid_team) of
                        true ->
                            check_requirement(Status, T);
                        false ->
                            {false, data_scene_text:get_sys_msg(6)}
                    end;
				2 ->
					case is_pid(Status#player_status.pid_team) of
                        true ->
                            {false, data_scene_text:get_sys_msg(31)};
                        false ->
							check_requirement(Status, T)
                    end
            end;
        pkstate -> %% PK状态
            case V =:= 0 of
                true ->
                    check_requirement(Status, T);
                false ->
                    PK = Status#player_status.pk,
                    case PK#status_pk.pk_status =:= V of
                        true ->
                            check_requirement(Status, T);
                        false ->
                            Msg = case V of
                                1 ->
                                    data_scene_text:get_sys_msg(7);
                                2 ->
                                    data_scene_text:get_sys_msg(8);
                                3 ->
                                    data_scene_text:get_sys_msg(9);
                                4 ->
                                    data_scene_text:get_sys_msg(10);
                                _ ->
                                    data_scene_text:get_sys_msg(11)
                            end,
                            {false, Msg}
                    end
            end;
        _ ->
            check_requirement(Status, T)
    end.

%% 检查副本进入
check_dungeon_requirement(_, []) ->
    {true};
check_dungeon_requirement(Status, [{K, V} | T]) ->
    case K of
        lv_down -> %% 等级需求
            case is_pid(Status#player_status.pid_team) andalso misc:is_process_alive(Status#player_status.pid_team) of
                true ->
                    case lib_team:check_level(Status#player_status.pid_team, V, 
										   Status#player_status.id, 
										   Status#player_status.lv) of
                        true ->
                            check_dungeon_requirement(Status, T);
                        false ->
                            Msg = data_scene_text:get_sys_msg(12)++integer_to_list(V)++data_scene_text:get_sys_msg(3),
                            {false, list_to_binary(Msg)}
                    end;
                false ->
                    case Status#player_status.lv < V of
                        true ->
                            Msg = data_scene_text:get_sys_msg(2)++integer_to_list(V)++data_scene_text:get_sys_msg(3),
                            {false, list_to_binary(Msg)};
                        false ->
                            check_dungeon_requirement(Status, T)
                    end
            end;
        lv_up -> %% 等级需求
            case Status#player_status.lv > V of
                true ->
                    Msg = data_scene_text:get_sys_msg(13)++integer_to_list(V)++data_scene_text:get_sys_msg(3),
                    {false, list_to_binary(Msg)};
                false ->
                    check_dungeon_requirement(Status, T)
            end;
        start_time -> %% 时间限制
            S1 = calendar:time_to_seconds(V),
            {_, Time} = erlang:localtime(),
            S2 = calendar:time_to_seconds(Time),
            case S1 > S2 of
                true ->
                    %Msg = "该场景尚未到时间开启，请稍后！",
                    Msg = data_scene_text:get_sys_msg(14),
                    {false, list_to_binary(Msg)};
                false ->
                    check_dungeon_requirement(Status, T)
            end;
        end_time -> %% 时间限制
            S1 = calendar:time_to_seconds(V),
            {_, Time} = erlang:localtime(),
            S2 = calendar:time_to_seconds(Time),
            case S1 < S2 of
                true ->
                    %Msg = "该场景时间已过，请明天再来吧！",
                    Msg = data_scene_text:get_sys_msg(14),
                    {false, list_to_binary(Msg)};
                false ->
                    check_dungeon_requirement(Status, T)
            end;
        limit_time ->
            [T1, T2] = V,
            S1 = calendar:time_to_seconds(T1),
            S2 = calendar:time_to_seconds(T2),
            {_, Time} = erlang:localtime(),
            S3 = calendar:time_to_seconds(Time),
            case S1 < S3 andalso S3 < S2 of
                true ->
                    check_dungeon_requirement(Status, lists:keydelete(limit_time, 1, T));
                false ->
                    case lists:keyfind(limit_time, 1, T) of
                        false -> 
                            %Msg = "该场景尚未到时间开启，请稍后！",
                            Msg = data_scene_text:get_sys_msg(14),
                            {false, list_to_binary(Msg)};
                        _ ->
                            check_dungeon_requirement(Status, T)
                    end
            end;
        people -> %% 限制组队人数
            case is_pid(Status#player_status.pid_team) andalso misc:is_process_alive(Status#player_status.pid_team) of
                true ->
                    case lib_team:get_mb_num(Status#player_status.pid_team) >= V of
                        true ->
                            check_dungeon_requirement(Status, T);
                        false ->
                            Msg = data_scene_text:get_sys_msg(15)++integer_to_list(V)++data_scene_text:get_sys_msg(16),
                            {false, list_to_binary(Msg)}
                    end;
                false ->
                    check_dungeon_requirement(Status, T)
            end;
        less -> %% 大少等于多少人数
            %% 判断人数: 1:单人;>1:多人.
            case V of
                1 ->
                    check_dungeon_requirement(Status, T);
                _ ->
                    case is_pid(Status#player_status.pid_team) andalso misc:is_process_alive(Status#player_status.pid_team) of
                        true ->
                            case lib_team:get_mb_num(Status#player_status.pid_team) =< V of
                                true ->
                                    check_dungeon_requirement(Status, T);
                                false ->
                                    Msg = data_scene_text:get_sys_msg(17)++integer_to_list(V)++data_scene_text:get_sys_msg(18),
                                    {false, list_to_binary(Msg)}
                            end;
                        false ->
                            check_dungeon_requirement(Status, T)
                    end
            end;
        _ ->
            check_dungeon_requirement(Status, T)
    end.

%% 删除进入场景道具
del_scene_item(_, []) ->
    true;
del_scene_item(Status, [{K, V} | T]) ->
%%     Go = Status#player_status.goods,
    case K of
        item -> %% 物品需求
            case V > 0 of
                true ->
                    gen_server:call(Status#player_status.goods#status_goods.goods_pid, {'delete_more', V, 1});
                false ->
                    true
            end;
        _ ->
            del_scene_item(Status, T)
    end.

%%进入普通场景
enter_normal_scene(SceneId, Scene, Status) ->
    case [{X, Y} || [Id, _Name, X, Y] <- Scene#ets_scene.elem, Id =:= Status#player_status.scene] of
        [] -> 
			{false, data_scene_text:get_sys_msg(19)};
        [{X, Y}] ->
			%护送美女
			HS2 = Status#player_status.husong,
			PlayerX = Status#player_status.x,
			PlayerY = Status#player_status.y,

			%1.护送美女状态是否在传送点附近.
			IsCanEnter = 
	            if                					
	                HS2#status_husong.husong=/=0 ->
						case get_data(Status#player_status.scene) of
			                [] ->
			                    false;   %% 不可以传送.
			                Scene2 ->
							    case [{X1, Y1} || [Id1, _Name1, X1, Y1] 
									 <- Scene2#ets_scene.elem, Id1 =:= Scene#ets_scene.id] of
							        [] ->
										false;   %% 不可以传送.
									[{X1, Y1}] ->
							            case PlayerX < X1+8 andalso PlayerX > X1-8 
											andalso PlayerY < Y1+8 andalso PlayerY > Y1-8 of
							                true ->
												true;   %% 可以传送.
							                false -> 
												false   %% 不可以传送.
			            				end
								end
						end;
					true ->
						true %% 可以传送.
				end,
			case IsCanEnter of
				true ->
					{true, SceneId, X, Y, Scene#ets_scene.name, Scene#ets_scene.id, Status};
				false ->
					{false, data_scene_text:get_sys_msg(34)}
			end
    end.

%% 进入副本场景
%% EnterType -> 
%               0: 从未进过,副本次数会+1
%               1: 已经进过,副本次数不变
enter_dungeon_scene(Scene, Status, EnterType) ->    
    case catch lib_dungeon:check_enter(Scene#ets_scene.id, Status) of
        {false, Msg} ->
            {false, Msg};
        {true, Id} ->
            case get_data(Status#player_status.scene) of
                []  -> {false, data_scene_text:get_sys_msg(19)};
                S ->
					%% 触发活跃度
					case Scene#ets_scene.id of
						650 ->
							mod_active:trigger(Status#player_status.status_active, 8, 0, Status#player_status.vip#status_vip.vip_type),
							%% 触发计数器
							lib_special_activity:add_old_buck_task(Status#player_status.id, 3);
						630 ->
							mod_active:trigger(Status#player_status.status_active, 6, 0, Status#player_status.vip#status_vip.vip_type);
						233 ->
							mod_active:trigger(Status#player_status.status_active, 7, 0, Status#player_status.vip#status_vip.vip_type);
						_ ->
							skip
					end,
                    case Scene#ets_scene.id >= 340 andalso Scene#ets_scene.id =< 379 of
                        true ->
                            mod_active:trigger(Status#player_status.status_active, 12, 0, Status#player_status.vip#status_vip.vip_type);
                        _ ->
                            skip
                    end,
                    case Scene#ets_scene.id >= 562 andalso Scene#ets_scene.id =< 577 of
                        true ->
                            mod_active:trigger(Status#player_status.status_active, 15, 0, Status#player_status.vip#status_vip.vip_type);
                        _ ->
                            skip
                    end,
                    
                    %1.进入副本完成一些新手任务.
                    case lib_dungeon:get_newer_task(Scene#ets_scene.id) of
                        {ok, TaskId} ->  
                            lib_task:finish_dun_task(Status#player_status.id, TaskId);
                        _ ->
                            skip
                    end,

					%2.增加经验副本记录.
                    case Scene#ets_scene.id == 630 of 
						true ->
							lib_task_cumulate:finish_task(Status#player_status.id, 1);
							%lib_jy:add_log(Status#player_status.id);
						false -> skip 
					end,
			
                    case EnterType of
                        0 ->
							%0.剧情副本进入就扣次数.
							IsStoryDungeon = 
 								case data_dungeon:get(Scene#ets_scene.id) of
 							        [] -> 0;
 							        Dun ->
 							            Dun#dungeon.type
 						        end,
							%1.剧情副本不在这里扣进入副本次数和体力值.
							case IsStoryDungeon == 1 of
								true ->
									skip;
								_ ->
		                            %.扣除进入副本所需道具.
		                            del_scene_item(Status, Scene#ets_scene.requirement),
									
									%.副本次数加一.
                                    mod_daily:increment(Status#player_status.dailypid, Status#player_status.id, Scene#ets_scene.id),
								

									%.增加进入副本总次数.
									mod_dungeon_data:increment_total_count(Status#player_status.pid_dungeon_data,																 
																Status#player_status.id,
																Scene#ets_scene.id),							
    								
									%5.装备副本增加活跃度.
									case Scene#ets_scene.id of 
								        300 ->  
		                                    case Status#player_status.pk#status_pk.pk_status of
												0 -> skip;
												4 -> skip;
												_ ->
		                                            lib_player:change_pk_status_cast(Status#player_status.id, 4)
		                                    end;
											%%mod_active:trigger(Status#player_status.status_active, 12, 0, Status#player_status.vip#status_vip.vip_type);
										_ ->
											skip
									end
							end,
                            ok;
                        1 -> skip 
                    end,

					%设置玩家最近副本ID,断线重连进入副本使用.
					mod_dungeon_agent:set_dungeon_record_scene_id(
					  Status#player_status.id, 
					  Scene#ets_scene.id),

					%因为有些副本把传送点当做退出副本，所以进去副本写死出生点.
					case lists:member(Scene#ets_scene.id,?DUNGEON_SCENE_BORN) of 
		            	true -> 												
							{true, Id, Scene#ets_scene.x, Scene#ets_scene.y, 
							 Scene#ets_scene.name, Scene#ets_scene.id, Status};
						false ->
							case [{X, Y} || [Id0, _Name, X, Y] <- Scene#ets_scene.elem, Id0 =:= S#ets_scene.id] of
							    [] -> {true, Id, Scene#ets_scene.x, Scene#ets_scene.y, 
										Scene#ets_scene.name, Scene#ets_scene.id, Status};
							    [{X, Y}] -> {true, Id, X, Y, Scene#ets_scene.name, Scene#ets_scene.id, Status}
							end
					end    				
            end;
        _ -> {false, data_scene_text:get_sys_msg(19)}
    end.


%% @spec check_dungeon_physical(SceneId, Status) -> true | {false, ErrorMsg}
%% change by xieyunfei
%% 这个接口已经把需要扣除体力值的场景置空了，目前全部满足体力值
%% 检查进入副本的体力值是否满足条件.
%% @end
check_dungeon_physical(SceneId, Status, Dun) ->
    %case lists:member(SceneId,?DUNGEON_SCENE_PHYSICAL) of 
    %    true ->
            %1.得到副本体力值ID.
            Physical = lib_physical:get_scene_cost(SceneId),
            %2.检测体力值.
            case is_pid(Status#player_status.pid_team) 
                andalso misc:is_process_alive(Status#player_status.pid_team) of
                %1.已经创建组队的.
                true ->
                    case lib_team:check_dungeon_physical(
                            Status#player_status.pid_team, 
                            Physical, 
                            Status#player_status.id, 
                            Status#player_status.physical) of
                        true ->
                            true;
                        false ->
                            %%队友体力不足，不能创建副本.
                            Msg = data_scene_text:get_sys_msg(27),
                            {false, list_to_binary(Msg)}
                    end;

                %1.还没有创建组队的只检测自己.
                false ->			
                    case lib_physical:is_enough_physical(Status, Physical) of
                        true ->
                            true;
                        false ->
                            %%体力不足
                            case Dun#dungeon.type of
                                %% 装备副本
                                ?DUNGEON_TYPE_DNTK_EQUIP -> 
                                    IsKillBoss = mod_dungeon_data:get_equip_energy_is_gift(Status#player_status.pid_dungeon_data, 
                                                                                            Status#player_status.id, Dun#dungeon.id),
                                    %% io:format("~p ~p Dun#dungeon.id:~p, IsKissBoss:~p~n",[?MODULE, ?LINE, Dun#dungeon.id, IsKillBoss]),
                                    case IsKillBoss of
                                        0 -> true ;
                                        _ -> {false, data_scene_text:get_sys_msg(26)}
                                    end;
                                %% 封魔录副本
                                ?DUNGEON_TYPE_STORY -> 
                                    case mod_dungeon_data:get_total_count(
                                            Status#player_status.pid_dungeon_data, 
                                            Status#player_status.id, 
                                            SceneId) of
                                        TotalCount when is_integer(TotalCount), TotalCount > 0 -> %% 要扣取体力值
                                            {false, data_scene_text:get_sys_msg(26)};
                                        _ -> true
                                    end;
                                _ ->
                                    {false, data_scene_text:get_sys_msg(26)}
                            end         
                    end
    %        end;
    %    _ -> 
    %        true
    end.



%% 检查进入副本条件
check_and_enter_dungeon_scene(Id, Scene, Status) -> 
    case is_pid(Status#player_status.copy_id) 
		andalso misc:is_process_alive(Status#player_status.copy_id) of
        true ->
            enter_dungeon_scene(Scene, Status, 1); %% 已经有副本服务进程
        false -> %% 还没有副本服务进程
            %%检查副本次数
            case data_dungeon:get(Scene#ets_scene.id) of
                [] -> {false, data_scene_text:get_sys_msg(20)};
                Dun -> %% 普通场景进入副本
                    case check_dungeon_requirement(Status, Dun#dungeon.condition) of
                        {false, Reason} -> {false, Reason};
                        {true} ->
							%检查进入副本的体力值是否满足条件.
							case check_dungeon_physical(Id, Status, Dun) of
								{false, Reason} -> {false, Reason};
                                true ->
                                    CostPhyStatus = if
                                        %% 铜钱副本扣取体力值
                                        Scene#ets_scene.id == 650 -> 
                                            Physical = lib_physical:get_scene_cost(Id),
                                            {ok, TmpCostPhyStatus} = lib_physical:cost_physical(Status, Physical),
                                            TmpCostPhyStatus;
                                        %% 装备副本扣取体力值
                                        Dun#dungeon.type =:= ?DUNGEON_TYPE_DNTK_EQUIP ->
                                            IsKillBoss = mod_dungeon_data:get_equip_energy_is_gift(Status#player_status.pid_dungeon_data, 
                                                Status#player_status.id, Dun#dungeon.id),
                                            case IsKillBoss > 0 of
                                                true -> 
                                                    Physical = lib_physical:get_scene_cost(Id),
                                                    {ok, TmpCostPhyStatus} = lib_physical:cost_physical(Status, Physical),
                                                    TmpCostPhyStatus;
                                                false -> 
                                                    Status
                                            end;
                                        %% 封魔录扣体力
                                        Dun#dungeon.type =:= ?DUNGEON_TYPE_STORY ->
                                            case mod_dungeon_data:get_total_count(
                                                    Status#player_status.pid_dungeon_data, 
                                                    Status#player_status.id, 
                                                    Scene#ets_scene.id) of
                                                TotalCount when is_integer(TotalCount), TotalCount > 0 -> %% 扣取体力值
                                                    CostPhysical = lib_physical:get_scene_cost(Id),
                                                    {ok, TmpCostPhyStatus} = lib_physical:cost_physical(Status, CostPhysical),
                                                    TmpCostPhyStatus;
                                                _ -> Status
                                            end;
                                        true -> Status
                                    end,
                                    Count = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, Scene#ets_scene.id),
                                    case Count >= Dun#dungeon.count andalso 
                                        Dun#dungeon.count /= 0      andalso 
                                        Dun#dungeon.type /= ?DUNGEON_TYPE_DNTK_EQUIP of
                                        true ->
                                            {false, data_scene_text:get_sys_msg(21)};
                                        false ->
                                            NowTime = util:unixtime(), 
                                            put({dungeon, CostPhyStatus#player_status.id}, NowTime),
                                            case is_pid(CostPhyStatus#player_status.pid_team) 
                                                andalso misc:is_process_alive(CostPhyStatus#player_status.pid_team) of
                                                %1.没有队伍，角色进程创建副本服务器
                                                false ->
                                                    Pid2 = mod_dungeon:start(0, 
                                                        self(), 
                                                        Scene#ets_scene.id, 
                                                        [{CostPhyStatus#player_status.id, 
                                                                CostPhyStatus#player_status.pid,
                                                                CostPhyStatus#player_status.pid_dungeon_data}], 
                                                        CostPhyStatus#player_status.lv,
                                                        CostPhyStatus#player_status.scene,
                                                        CostPhyStatus#player_status.x,
                                                        CostPhyStatus#player_status.y),


                                                    %5.增加经验副本记录.
                                                    case Scene#ets_scene.id == 630 of 
                                                        true ->
                                                            lib_task_cumulate:finish_task(CostPhyStatus#player_status.id, 1);
                                                        %lib_jy:add_log(Status#player_status.id);
                                                        false -> skip 
                                                    end,															
                                                    enter_dungeon_scene(Scene, CostPhyStatus#player_status{copy_id = Pid2}, 0);
                                                %2.有队伍，由队伍进程创建副本服务器
                                                true ->
                                                    case is_dungeon_single(Dun#dungeon.condition) of
                                                        true ->
                                                            Pid2 = mod_dungeon:start(0, 
                                                                                     self(), 
                                                                                     Scene#ets_scene.id, 
                                                                                     [{CostPhyStatus#player_status.id, 
                                                                                       CostPhyStatus#player_status.pid,
                                                                                       CostPhyStatus#player_status.pid_dungeon_data}], 
                                                                                     CostPhyStatus#player_status.lv,
                                                                                     CostPhyStatus#player_status.scene,
                                                                                     CostPhyStatus#player_status.x,
                                                                                     CostPhyStatus#player_status.y),
                                                            
                                                            
                                                            %5.增加经验副本记录.
                                                            case Scene#ets_scene.id == 630 of 
                                                                true ->
                                                                    lib_task_cumulate:finish_task(CostPhyStatus#player_status.id, 1);
                                                                %lib_jy:add_log(Status#player_status.id);
                                                                false -> skip 
                                                            end,                                                            
                                                            enter_dungeon_scene(Scene, CostPhyStatus#player_status{copy_id = Pid2}, 0);
                                                        false ->
                                                            {DPid3, Flag} = lib_team:create_dungeon(
                                                                              Status#player_status.pid_team, 
                                                                              self(), 
                                                                              Scene#ets_scene.id, 
                                                                              Scene#ets_scene.name, 
                                                                              Status#player_status.lv,
                                                                              [Id, 
                                                                               Status#player_status.id,
                                                                               Status#player_status.dailypid,
                                                                               Status#player_status.pid,
                                                                               Status#player_status.pid_dungeon_data,
                                                                               Status#player_status.copy_id, 
                                                                               Status#player_status.scene,
                                                                               Status#player_status.x,
                                                                               Status#player_status.y]),
                                                            case Flag of
                                                                %% 队长在创建副本时已经加1了.
                                                                isleader ->															
                                                                    enter_dungeon_scene(Scene, Status#player_status{copy_id = DPid3}, 1);
                                                                noleader ->
                                                                    enter_dungeon_scene(Scene, Status#player_status{copy_id = DPid3}, 0);
                                                                mb_in_other_dungeon ->
                                                                    {false, data_scene_text:get_sys_msg(22)};
                                                                not_the_same_dungeon ->
                                                                    {false, data_scene_text:get_sys_msg(23)};
                                                                _ ->
                                                                    {false, data_scene_text:get_sys_msg(24)}
                                                            end
                                                    end
                                            end
                                    end
                            end        
                    end
            end
    end.

%%获得当前场景用户
%%Q:场景ID
%%CopyId:副本id
get_scene_user(Q) ->
    mod_scene_agent:apply_call(Q, lib_scene_agent, get_scene_user, []).

%%获得当前场景用户
%%Q:场景ID
%%CopyId:副本id
get_scene_user(Q, CopyId) ->
    mod_scene_agent:apply_call(Q, lib_scene_agent, get_scene_user, [CopyId]).

%%获得当前场景用户字段
%%Q:场景ID
%%CopyId:副本id
%%Type:字段类型
%%return:[Pid1, Pid2]
get_scene_user_field(Q, CopyId, Type) ->
    mod_scene_agent:apply_call(Q, lib_scene_agent, get_scene_user_field, [Type, CopyId]).


%%获得当前场景用户字段
%% @spec get_scene_user_1v1(Q, CopyId, Id, Platform, ServerNum) -> {玩家战斗力,玩家血量,玩家血量上限,玩家场景}
%%Q:场景ID
%%CopyId:副本id
%%Id 玩家id
%%Platform 平台名称
%%ServerNum 服数 
%% @end
get_scene_user_1v1(Q, CopyId, Id, Platform, ServerNum) ->
    case mod_scene_agent:apply_call(Q, lib_scene_agent, get_user_1v1, [CopyId, Id, Platform, ServerNum]) of
		{Combat_power,Hp, Hp_lim, Scene}->
			{Combat_power,Hp, Hp_lim, Scene};
		_R->
			{0,0,1,0}
	end.

%%获得当前场景信息
%%Q:场景ID
%%CopyId:副本id
get_scene_mon(Q, CopyId) ->
    mod_mon_agent:apply_call(Q, lib_mon_agent, get_scene_mon, [CopyId, all]).

%%获得当前场景怪物数量
%%Q:场景ID
%%CopyId:副本id
get_scene_mon_num(Q, CopyId) ->
    mod_mon_agent:apply_call(Q, lib_mon_agent, get_scene_mon_num, [CopyId]).

%%获得当前场景某种类型怪物数量
%%Q:场景ID
%%CopyId:副本id
get_scene_mon_num_by_kind(Q, CopyId, Kind) ->
    mod_mon_agent:apply_call(Q, lib_mon_agent, get_scene_mon_num_by_kind, [CopyId, Kind]).

%% 是否为副本场景，唯一id，会检查是否存在这个场景
is_dungeon_scene(Id) ->
    case data_scene:get(Id) of
        [] -> false;
        S -> S#ets_scene.type =:= ?SCENE_TYPE_DUNGEON orelse 
			 S#ets_scene.type =:= ?SCENE_TYPE_TOWER
    end.

%% %% 判断副本是不是多人副本
%% is_dungeon_single(Type)->
%%     if
%%         Type =:= ?DUNGEON_TYPE_NORMAL orelse    %% 普通副本.
%%         Type =:= ?DUNGEON_TYPE_STORY orelse     %% 剧情副本.
%%         Type =:= ?DUNGEON_TYPE_COIN orelse     %% 铜币副本.
%%         Type =:= ?DUNGEON_TYPE_PET orelse      %% 宠物副本.
%%         Type =:= ?DUNGEON_TYPE_EXP orelse       %% 经验副本.
%%         Type =:= ?DUNGEON_TYPE_NEWER_PET orelse  %% 新手宠物副本.
%%         Type =:= ?DUNGEON_TYPE_DNTK_EQUIP ->       %% 大闹天空装备副本
%%             true;
%%         true -> false
%%     end.

%% 获取进入副本的限制人数：1:单人(默认单人); 2:>1:多人
is_dungeon_single([])-> true;
is_dungeon_single([{K, V} | Condition])->
    case K of
        less -> 
            if
                V =:= 1 -> true;
                true -> false
            end;
        _ ->
            is_dungeon_single(Condition)
    end.


%% 是否可以传送.
is_transferable(SceneId) ->
    case data_scene:get(SceneId) of
        [] -> false;
        SceneData ->
			case SceneData#ets_scene.type of
				%1.普通场景.
				?SCENE_TYPE_NORMAL -> true;	
				
				%2.野外场景.
				?SCENE_TYPE_OUTSIDE -> true;
				
				%3.安全场景.
				?SCENE_TYPE_SAFE -> true;
				
				%4.Boss场景.
				?SCENE_TYPE_BOSS -> true;
				
				%5.其他场景都不可以传送.
			 	_ -> false
			end
    end.

%% 判断在场景SID的[X,Y]坐标是否有障碍物
%% return:ture有障碍物,false无障碍物
is_blocked(Sid, X, Y) ->
    mod_scene_mark:get_scene_poses({Sid, X, Y}).

%% 判断在场景SID的[X,Y]坐标是否在安全区
is_safe(Sid, X, Y) ->
    case data_scene:get(Sid) of
        [] ->
            false;% 非安全区
        Scene ->
            case mod_scene_mark:get_scene_safe_poses({Sid, X, Y}) of
                true -> true; % 安全区
                false ->  
                    %安全场景
                    case Scene#ets_scene.type =:= ?SCENE_TYPE_SAFE orelse Scene#ets_scene.type =:= ?SCENE_TYPE_ACTIVE of
                        true ->
                            true;
                        _ ->
                            false % 非安全区
                    end
            end
    end.

%% 判断是否安全场景
is_safe_scene(Sid) -> 
    case data_scene:get(Sid) of
        [] ->
            false;% 非安全区
        Scene -> 
            %安全场景
            case Scene#ets_scene.type =:= ?SCENE_TYPE_SAFE orelse Scene#ets_scene.type =:= ?SCENE_TYPE_ACTIVE of
                true ->
                    true;
                _ ->
                    false % 非安全区
            end
    end.

%% 判断是否为活动场景
is_active_scene(Sid) -> 
    case data_scene:get(Sid) of
        [] ->
            false;% 非活动场景
        Scene -> 
            %活动场景场景
            case Scene#ets_scene.type =:= ?SCENE_TYPE_ACTIVE of
                true ->
                    true;
                _ ->
                    false % 非活动场景
            end
    end.

%% 是否跨服场景
is_clusters_scene(Sid) -> 
    case data_scene:get(Sid) of
        [] ->
            false;% 非跨服场景
        Scene -> 
            %跨服场景
            case Scene#ets_scene.type =:= ?SCENE_TYPE_CLUSTERS of
                true ->
                    true;
                _ ->
                    false % 非跨服场景
            end
    end.

%% 刷新npc任务状态
refresh_npc_ico(Rid) when is_integer(Rid)->
    case lib_player:get_player_info(Rid) of
        Status when is_record(Status, player_status)->
            lib_scene:refresh_npc_ico(Status);
        R ->
            util:errlog("ps is error:~p~n", [R]),
            ok
    end;
        
refresh_npc_ico(Status) -> 
    NpcList = lib_npc:get_scene_npc(Status#player_status.scene),
    F = 
    fun(Npc) ->
            Id = Npc#ets_npc.id,
            S = 
            if
                Id == ?HB_NPC_ID ->
                    TriggerTaskEbNum = lib_task_eb:get_trigger_task_eb_num(),
                    TriggerTaskEbDaily = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000010),
                    MaxinumTriggerDaily = data_task_eb:get_task_config(maxinum_trigger_daily, []),
                    MaxinumTriggerEverytime = data_task_eb:get_task_config(maxinum_trigger_everytime, []),
                    MinTriggerLv = data_task_eb:get_task_config(min_trigger_lv, []),
                    if
                        TriggerTaskEbDaily < MaxinumTriggerDaily andalso TriggerTaskEbNum < MaxinumTriggerEverytime andalso Status#player_status.lv >= MinTriggerLv ->
                            1;
                        true ->
                            0
                    end;
                true ->
                    lib_task:get_npc_state(Id, Status)
            end,
            [Id, S]
    end,
    L = lists:map(F, NpcList),
    {ok, BinData} = pt_120:write(12020, [L]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData).


%% 用id获取场景的资源场景类型
get_res_type(SceneId) ->
    case data_scene:get(SceneId) of
        []  -> 0;
        S -> S#ets_scene.type
    end.

%% 获取场景名称
get_scene_name(SceneId) ->
    case data_scene:get(SceneId) of
        []  -> 
            <<>>;
        S -> 
            S#ets_scene.name
    end.

%% 检查场景pk状态
get_scene_pkstatus(SceneId) ->
    case  data_scene:get(SceneId) of
        [] ->
            5;
        Scene ->
            Rq = Scene#ets_scene.requirement,
            case lists:keysearch(pkstate, 1, Rq) of
                false ->
                    0;
                {value, {_,PkState}} ->
                    PkState
            end
   end.

%% 获取当前场景指定id用户信息
get_scene_user_by_id(Scene, Key) ->
    mod_scene_agent:apply_call(Scene, lib_scene_agent, get_user, [Key]).

%% 保存当前场景指定id用户信息
save_scene_user_by_id(SceneUser) ->
    mod_scene_agent:apply_cast(SceneUser#ets_scene_user.scene, lib_scene_agent, put_user, [SceneUser]).

%% 获取当前场景出生点
get_born_xy(Sid) ->
   case data_scene:get(Sid) of
        [] ->
            [0, 0];
        Scene ->
            [Scene#ets_scene.x, Scene#ets_scene.y]
    end.

%% 修复坐标
repair_xy(Lv, Scene, X, Y) ->
    case is_blocked(Scene, X, Y) of
        true ->
            [_X, _Y] = get_born_xy(Scene),
            [Scene, _X, _Y];
        false ->
            case data_scene:get(Scene) of
                [] ->
                    case Lv > 35 of
                        true ->
                            [_X, _Y] = get_born_xy(102),
                            [102, _X, _Y];
                        false ->
                            [_X, _Y] = get_born_xy(100),
                            [100, _X, _Y]
                    end;
                Data ->
                    if
                        X =< 0 orelse Data#ets_scene.width div 60 =< X ->
                            [_X, _Y] = get_born_xy(Scene),
                            [Scene, _X, _Y];
                        Y =< 0 orelse Data#ets_scene.height div 30 =< Y ->
                            [_X, _Y] = get_born_xy(Scene),
                            [Scene, _X, _Y];
                        true ->
                            [Scene, X, Y]
                    end
            end
    end.

%% 是否需要场景广播
is_broadcast_scene(Id) ->
    case data_scene:get(Id) of
        [] ->
            false;
        Scene ->
            lists:member(Scene#ets_scene.type, ?ALLBRO) orelse lists:member(Scene#ets_scene.id, ?ALLBRO_ID)
            orelse lists:member(Scene#ets_scene.id, data_god:get(scene_id2)) 
            orelse lists:member(Scene#ets_scene.id, data_kf_3v3:get_config(scene_pk_ids))
    end.

%% 是否可以移动到(X,Y)坐标
%% Sid 场景id
%% Retrue: true 有异常，不能移动 | false 没异常，可以移动
can_be_moved(Sid, X, Y) -> 
    case is_blocked(Sid, X, Y) of %% 是否障碍物
        true -> true;
        false -> 
            case data_scene:get(Sid) of
                [] -> true;
                Data -> 
                    X =< 0 orelse Y =< 0 orelse Data#ets_scene.width div 60 =< X orelse Data#ets_scene.height div 30 =< Y %% 是否场景外
            end
    end.

%% 离开场景需要处理的操作
change_scene_handler(Status, EnterSceneId, LevelSceneId) ->
   BuffStatus = lib_skill_buff:specail_scene_buff(Status, EnterSceneId, LevelSceneId), %% buff处理
   if
       LevelSceneId == 106 ->
          %% 清理帮派晶石等 
          lib_factionwar:del_stone(BuffStatus, 2);
      true -> 
          BuffStatus
  end.

%% 获取主城随机出生地 -> {X, Y}
get_main_city_x_y() -> 
    Len = length(?MAIN_CITY_RAND_XY),
    lists:nth(util:rand(1, Len), ?MAIN_CITY_RAND_XY).
