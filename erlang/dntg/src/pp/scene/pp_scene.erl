%%%--------------------------------------
%%% @Module  : pp_scene
%%% @Author  : zhenghehe
%%% @Created : 2010.12.23
%%% @Description:  场景
%%%--------------------------------------
-module(pp_scene).
-export([
            handle/3,
            check_move/1,
            check_fly/1,
            get_scene_info/2,
            init_all_scene/0
        ]).
-include("server.hrl").
-include("scene.hrl").
-include("task.hrl").
-include("sql_fly.hrl").
-include("skill.hrl").

%%移动信息
handle(12001, Status, [_X, _Y, Fly]) ->
   % LoverunScene = data_loverun:get_loverun_config(scene_id),
   % case Status#player_status.scene of
   %     LoverunScene ->
   %         case Status#player_status.parner_id of
   %             0 ->
   %                 skip;
   %             _ ->
   %                 lib_loverun:cheat_handle(Status)
   %         end;
   %     _ ->
   %         skip
   % end,
    if
        Fly == 1 orelse Fly == 2 ->
            if
                Status#player_status.lv =< 30 -> 
                    X = _X,
                    Y = _Y;
                abs(Status#player_status.x - _X) > 16 orelse abs(Status#player_status.y - _Y) > 16 ->
                    X = Status#player_status.x,
                    Y = Status#player_status.y;
                true ->
                    X = _X,
                    Y = _Y
            end,
            mod_scene_agent:move(X, Y, Fly, Status),
            NewStatus = Status#player_status{x = X, y = Y, unmove_time = 0},
            {ok, NewStatus};
        true ->
            if
                abs(Status#player_status.x - _X) > 4 orelse abs(Status#player_status.y - _Y) > 4 ->
                    X = Status#player_status.x,
                    Y = Status#player_status.y;
                true ->
                    X = _X,
                    Y = _Y
            end,
            mod_scene_agent:move(X, Y, Fly, Status),
            {ok, Status#player_status{x = X, y = Y, unmove_time = 0}}
    end;


%%加载场景
handle(12002, Status, _) -> 
    mod_scene_agent:load_scene(Status),
    %% 更新公共线的场景
    lib_player:update_unite_info(Status#player_status.unite_pid, [{scene, Status#player_status.scene}, {copy_id, Status#player_status.copy_id}]),
    %% 告诉队友我在哪里
    lib_team:send_to_team_where_I_am(Status, lib_scene:get_scene_name(Status#player_status.scene)), 
    %% 检查BUFF列表
    %{ok, Status1} = lib_player:check_player_buff(Status),
	case Status#player_status.scene of
		233 ->
           lib_task:event(Status#player_status.tid, enter_scene, {Status#player_status.scene}, Status#player_status.id);
		_ -> skip
	end,
    {ok, Status};
    

%%离开场景
handle(12004, Status, _) ->
    lib_scene:leave_scene(Status);

%%切换场景
handle(12005, Status, Id) ->
    case Id == Status#player_status.scene of
        true ->
            [Id1, X, Y, Sid, Name] = case lib_scene:get_data(Status#player_status.scene) of
                [] ->
                    case Status#player_status.lv >= 20 of
                        true ->
                            [102, 103 , 122, 102, <<"长安">>];
                        _ ->
                            [100, 22 , 28, 100, <<"花果山">>]
                    end;
                S ->
                    [Id, Status#player_status.x, Status#player_status.y, S#ets_scene.id, S#ets_scene.name]
            end,
            {ok, BinData} = pt_120:write(12005, [Id1, X, Y, Name, Sid]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            {ok, Status#player_status{scene = Id1, x = X, y = Y}};
        false ->
			case lists:member(Id, ?FORBID_ENTER_SCENE_LIST) of 
            	true ->
					{ok, BinData} = pt_120:write(12005, [0, 0, 0, data_scene_text:get_sys_text(36), 0]),
                    lib_server_send:send_one(Status#player_status.socket, BinData);
				false ->
		            case lib_scene:check_enter(Status, Id) of
		                {false, Msg} ->
		                    {ok, BinData} = pt_120:write(12005, [0, 0, 0, Msg, 0]),
		                    lib_server_send:send_one(Status#player_status.socket, BinData);
		                {true, Id1, X, Y, Name, Sid, Status1} ->
		                    %% 不允许在和平状态下进入BOSS场景
		                    %% 0和平 1全体 2国家 3帮派 4队伍 5善恶 6阵营(竞技场等特殊场景) 7幽灵(和平状态)
		                    %获取要传送地图场景数据.
		                    PresentScene = 
		                    case data_scene:get(Id) of
		                        [] -> 
		                            #ets_scene{};
		                        SceneData ->
		                            SceneData
		                    end,
		                    case PresentScene#ets_scene.type =:= ?SCENE_TYPE_BOSS andalso Status#player_status.pk#status_pk.pk_status =:= 0 of
		                        true -> 
		                            %和平模式下不允许进入Boss场景
		                            Msg = data_scene_text:get_sys_msg(30),
		                            {ok, BinData} = pt_120:write(12005, [0, 0, 0, Msg, 0]),
		                            lib_server_send:send_one(Status#player_status.socket, BinData);
		                        false ->
		                            %% 场景特殊buff
		                            Status2 = lib_scene:change_scene_handler(Status1, Id1, Status#player_status.scene),
		                            %%告诉原来场景玩家你已经离开
		                            lib_scene:leave_scene(Status),
		                            {ok, BinData} = pt_120:write(12005, [Id1, X, Y, Name, Sid]),
		                            lib_server_send:send_one(Status2#player_status.socket, BinData),
                                    Status3 = Status2#player_status{scene = Id1, x = X, y = Y},
		                            {ok, Status3}
		                    end
		            end
			end
    end;


%% 请求刷新npc状态
handle(12020, Status, []) -> 
    lib_scene:refresh_npc_ico(Status),
    ok;

%% 获取场景相邻关系数据
handle(12080, Status, []) ->
    BL = data_scene:get_border(),
    {ok, BinData} = pt_120:write(12080, [BL]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%%获取场景怪物
handle(12095, Status, Q) ->   
    WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
    case Q of 
        %% 决战南天门怪物由程序生成，特殊处理
        WubianhaiSceneId ->
            BinData = lib_wubianhai_new:get_mon_list(), 
            lib_server_send:send_one(Status#player_status.socket, BinData);
        _ ->
            AllMon = mod_scene_mon:match(Q),
            {ok, BinData} = pt_120:write(12095, [Q, AllMon]),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end,
    ok;

%% 取消变身
handle(12099, Status, []) -> 
    NewBS = lib_skill_buff:clear_buff(Status#player_status.battle_status, [400008, 400009, 400010, 400011, 400012, 400013], []), %% 清理一些buff
    NewStatus = lib_figure:change(Status#player_status{battle_status = NewBS}, {0, 0, 0}),
    %mod_scene_agent:update(figure, NewStatus),
    mod_scene_agent:update(battle_attr, NewStatus),
    {ok, NewStatus};

%% 动作表情
handle(12100, PlayerStatus, [FaceId]) ->
    NowTime = util:unixtime(),
    LastTime = get_face_time(),
    case NowTime - LastTime >= 4 of
        true ->
            put_face_time(NowTime),
            RoleId = PlayerStatus#player_status.id,
            RoleName = PlayerStatus#player_status.nickname,
            Scene = PlayerStatus#player_status.scene,
            X = PlayerStatus#player_status.x,
            Y = PlayerStatus#player_status.y,
            {ok, BinData} = pt_121:write(12100, [FaceId, RoleId, PlayerStatus#player_status.platform, PlayerStatus#player_status.server_num, RoleName]),
            lib_server_send:send_to_area_scene(Scene, PlayerStatus#player_status.copy_id, X, Y, BinData),
            case lib_task:in_trigger(PlayerStatus#player_status.tid, 100100) of
                true ->
                    lib_task:event(PlayerStatus#player_status.tid, big_face, {FaceId}, PlayerStatus#player_status.id);
                false ->
                    skip
            end,
            ok;
        false ->
            skip
    end;

%% 获取飞行坐骑剩余时间
handle(12106, Status, Type) -> 
    case Type of
        0 -> 
%%             case lib_server_dict:fly_prop() of
%%                 [] ->
%%                     skip;
%%                 {FlyStatus, GoodsTypeId, FlyMountId, FlyMountSpeed, Permanent, TriggerTime, LeftTime, LastGoodsTypeId} ->
%%                     if
%%                         FlyStatus == 1 ->
%%                             NewFlyStatus = 0,
%%                             lib_server_dict:fly_prop({NewFlyStatus, GoodsTypeId, FlyMountId, FlyMountSpeed, Permanent, 0, LeftTime-util:unixtime()+TriggerTime, LastGoodsTypeId});
%%                         true ->
%%                             skip
%%                     end
%%             end,
%%             lib_fly_mount:cancel_task2(Status);
            skip;
        1 -> 
            TaskList = lib_task:get_trigger(Status#player_status.tid),
            Result = [{lists:member(X#role_task.task_id, ?FLY_TASK),X#role_task.trigger_time}||X<-TaskList],
            case lists:keyfind(true, 1, Result) of
                false -> 
                    case lib_server_dict:fly_prop() of
                        [] ->
                            {ok, BinData0} = pt_121:write(12106, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status#player_status.speed, 0, 0, 0]),
                            lib_server_send:send_to_sid(Status#player_status.sid, BinData0),
                            ok;
                        {FlyStatus, GoodsTypeId, FlyMountId, FlyMountSpeed, Permanent, TriggerTime, LeftTime, LastGoodsTypeId} ->
                            if
                                FlyStatus == 1 ->
                                    case Permanent ==1 of
                                        true ->
                                            {ok, BinData} = pt_121:write(12106, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status#player_status.speed, FlyMountId, 1, LeftTime]),
                                            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
                                            ok;
                                        false ->
                                            case LeftTime > 0 of
                                                true ->
                                                    {ok, BinData} = pt_121:write(12106, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status#player_status.speed, FlyMountId, 1, LeftTime]),
                                                    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
                                                    lib_server_dict:fly_prop({FlyStatus, GoodsTypeId, FlyMountId, FlyMountSpeed, Permanent, util:unixtime(), LeftTime-util:unixtime()+TriggerTime, LastGoodsTypeId}),
                                                    ok; 
                                                false ->
                                                    [NewFlyStatus, NewGoodsTypeId, NewFlyMountId, NewFlyMountSpeed, NewPermanent, NewLeftTime, NewLastGoodsTypeId] = 
                                                    case LastGoodsTypeId > 0 of
                                                        true ->
                                                            LastGoodsTypeInfo = data_fly_mount:get(LastGoodsTypeId),
                                                            if 
                                                                LastGoodsTypeInfo =:= [] ->
                                                                    [0, 0, 0, 0, 0, 0, 0];
                                                                true ->
                                                                    {LastFlyMountId, LastLeftTime} = LastGoodsTypeInfo,
                                                                    LastPermanent = 
                                                                    case LastLeftTime > 0 of
                                                                        true ->
                                                                            0;
                                                                        false ->
                                                                            1
                                                                    end,
                                                                    [1, LastGoodsTypeId, LastFlyMountId, ?FLY_MOUNT_SPEED, LastPermanent, LastLeftTime, 0]
                                                            end;
                                                        false ->
                                                            [0, 0, 0, 0, 0, 0, 0]
                                                    end,
                                                    lib_server_dict:fly_prop({NewFlyStatus, NewGoodsTypeId, NewFlyMountId, NewFlyMountSpeed, NewPermanent, 0, NewLeftTime, NewLastGoodsTypeId}),
                                                    Sql = io_lib:format(?FLY_INSERT, [Status#player_status.id, NewFlyStatus, NewGoodsTypeId, NewFlyMountId, NewFlyMountSpeed, NewPermanent, NewLeftTime, NewLastGoodsTypeId]),
                                                    db:execute(Sql),
                                                    IsFly = 
                                                    if
                                                        NewFlyMountId>0 ->
                                                            1;
                                                        true ->
                                                            0
                                                    end,
                                                    {ok, BinData0} = pt_121:write(12106, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status#player_status.speed, NewFlyMountId, IsFly, NewLeftTime]),
                                                    lib_server_send:send_to_sid(Status#player_status.sid, BinData0),
                                                    if
                                                        NewFlyMountId == 0 ->
                                                            {ok, BinData} = pt_130:write(13201, [3]),
                                                            lib_server_send:send_to_sid(Status#player_status.sid, BinData);
                                                        true ->
                                                            skip
                                                    end,
                                                    ok
                                            end
                                    end;
                                true ->
                                    {ok, BinData0} = pt_121:write(12106, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status#player_status.speed, FlyMountId, 0, LeftTime]),
                                    lib_server_send:send_to_sid(Status#player_status.sid, BinData0),
                                    ok
                            end
                    end;
                {true, TriggerTime} -> 
                    LeftTime = TriggerTime + 180 - util:unixtime(),
                    case LeftTime =< 0 of
                        true -> 
                            lib_fly_mount:cancel_task2(Status);
                        false -> 
                            Mou = Status#player_status.mount,
                            {ok, BinData} = pt_121:write(12106, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status#player_status.speed, Mou#status_mount.fly_mount, 1, LeftTime]),
                            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
                            ok
                    end
            end
    end;

%% 加载所有场景的npc, elem, monster列表信息
handle(12300, Status, load_all_scene) ->
    AllScene = ets:tab2list(ets_load_all_scene),
    case AllScene of
        [] ->
            init_all_scene(),
            [LoadAllScene] = ets:tab2list(ets_load_all_scene);
        _ ->
            [LoadAllScene] = AllScene
    end,
    {ok, BinData} = pt_123:write(12300, LoadAllScene#load_all_scene_info.data),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    ok;
                                 
handle(_Cmd, _Status, _Data) ->
    {error, "pp_scene no match"}.

get_face_time() ->
    case get("SEND_FACE_TIME") of
        undefined -> 0;
        Time -> Time
    end.

put_face_time(Time) ->
    put("SEND_FACE_TIME", Time).

get_scene_info([], InfoList) ->
    InfoList;
get_scene_info([SceneId|T], InfoList) ->
    case ets:lookup(?ETS_SCENE, SceneId) of
        [Scene] when is_integer(SceneId)->
            %%当前元素信息
            SceneElem = Scene#ets_scene.elem,
            %%当前npc信息
            SceneNpc = lib_npc:get_scene_npc(SceneId),
            get_scene_info(T, InfoList++[{SceneId, Scene#ets_scene.name, SceneElem, SceneNpc}]);
        [] ->
            get_scene_info(T, InfoList)
    end.

%%检查走路
check_move(Status) ->
    {List, Count} = case get("check_move") of
        undefined->
            {[], 0};
        _List ->
            _List
    end,
    case List of
        [Sid, _, _,_] ->
            case Sid =:= Status#player_status.scene of
                true ->
                    case Count < 15 of
                        true ->
                            put("check_move", {List, Count+1});
                        false ->
                            T2 = util:longunixtime(),
                            X2 = Status#player_status.x,
                            Y2 = Status#player_status.y,
                            %% 判断心跳包是否有跳动 8 秒内
                            case pp_login:check_heart_time(T2, 12000) of
                                true ->
                                    %%告诉玩家登陆失败
                                    {ok, BinData} = pt_590:write(59004, 4),
                                    lib_server_send:send_one(Status#player_status.socket, BinData), 
                                    mod_login:logout(Status#player_status.pid);
                                false ->
                                    put("check_move", {[], 0}),
                                    [_, X1, Y1, T1] = List,
                                    case T2 =:= T1 of
                                        true ->
                                            skip;
                                        false ->
                                            Dx = abs(X1 -X2) * 60,
                                            Dy = abs(Y1 -Y2) * 30,
                                            Dis = trunc(math:sqrt(Dx * Dx +  Dy * Dy)),
                                            Speed = trunc(Dis / (T2 - T1) * 1000),
                                            case 320 < Speed of
                                                true ->
                                                    {ok, TICKET} = application:get_env(ticket),
                                                    case  TICKET == "SDFSDESF123DFSDF" of
                                                        true ->
                                                            skip;
                                                        false ->
                                                            %%告诉玩家登陆失败
                                                            {ok, BinData} = pt_590:write(59004, 4),
                                                            lib_server_send:send_one(Status#player_status.socket, BinData), 
                                                            mod_login:logout(Status#player_status.pid)
                                                    end;
                                                false ->
                                                    skip
                                            end    
                                    end
                            end
                    end;
                false ->
                    put("check_move", {[Status#player_status.scene, Status#player_status.x, Status#player_status.y, util:longunixtime()], 1})
            end;
        _ ->
            put("check_move", {[Status#player_status.scene, Status#player_status.x, Status#player_status.y, util:longunixtime()], 1})
    end.

%% 检查轻功
check_fly(Skill) ->
    Time1 = case get("check_fly") of
        undefined->
            0;
        _Time1 ->
            _Time1
    end,
    Time2 = util:unixtime(),
    put("check_fly", Time2),
    %减少CD的技能
    Flag = case lists:keysearch(32, 1, Skill) of
        {value, {_, Speed}} ->
            Speed;
        _ ->
            0
    end,

    CD = 25 - Flag,
    Time2 - Time1 < CD.

%% 初始化所有场景的信息
init_all_scene() ->
    F = fun(_SceneId) ->
            S = data_scene:get(_SceneId),
            S#ets_scene.type =/= ?SCENE_TYPE_DUNGEON andalso 
            S#ets_scene.type =/= ?SCENE_TYPE_GUILD andalso 
            S#ets_scene.type =/= ?SCENE_TYPE_ARENA andalso 
            S#ets_scene.type =/= ?SCENE_TYPE_TOWER                                                                                                                                                                                                                               
        end,
    SceneIds = lists:filter(F, data_scene:get_id_list()),
    SceneInfoList = get_scene_info(SceneIds, []),
    Fun = fun({SceneId, SceneName, Elem, Npc}) ->
            Data1 = <<SceneId:32>>,
            Data2 = pt:write_string(SceneName),
            Data3 = pt_120:pack_elem_list(Elem),
            Data4 = pt_120:pack_npc_list(Npc),
            << Data1/binary, Data2/binary, Data3/binary, Data4/binary>>
          end,
    PackSceneList = lists:map(Fun, SceneInfoList),
    PackSceneListLen = length(PackSceneList),
    PackSceneListBin = list_to_binary(PackSceneList),
    BinData = <<PackSceneListLen:16, PackSceneListBin/binary>>,
    ets:insert(ets_load_all_scene, #load_all_scene_info{data = BinData}),
    ok.
