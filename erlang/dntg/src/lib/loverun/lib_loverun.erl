%%%------------------------------------
%%% @Module  : lib_loverun
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.8.21
%%% @Description: 爱情长跑
%%%------------------------------------
-module(lib_loverun).
-compile(export_all).
-include("server.hrl").
-include("scene.hrl").
-include("predefine.hrl").

%% 获取开始结束时间
get_start_time() ->
    ApplyTime = data_loverun:get_loverun_config(apply_time),
    [[{Config_Begin_Hour1, Config_Begin_Minute1}, {Config_End_Hour1, Config_End_Minute1}], [{Config_Begin_Hour2, Config_Begin_Minute2}, {Config_End_Hour2, Config_End_Minute2}]] = data_loverun_time:get_loverun_time(activity_time),
    %设置时间
    {NowHour, NowMin, _NowSec} = time(),
    case (Config_End_Hour1 * 60 + Config_End_Minute1) - (NowHour * 60 + NowMin) =< 0 andalso (Config_End_Hour2 * 60 + Config_End_Minute2) - (NowHour * 60 + NowMin) > 0 of
        true ->
            Config_Begin_Hour = Config_Begin_Hour2,
            Config_Begin_Minute = Config_Begin_Minute2,
            Config_End_Hour = Config_End_Hour2,
            Config_End_Minute = Config_End_Minute2;
        false -> 
            Config_Begin_Hour = Config_Begin_Hour1,
            Config_Begin_Minute = Config_Begin_Minute1,
            Config_End_Hour = Config_End_Hour1,
            Config_End_Minute = Config_End_Minute1
    end,
    {Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute, ApplyTime}.

%% 判断活动是否正在开启
is_opening(BeginHour, BeginMin, EndHour, EndMin, _ApplyTime) ->
    {Hour, Min, _Sec} = time(),
    NowTime = Hour * 60 + Min,
    case NowTime >= BeginHour * 60 + BeginMin andalso NowTime < EndHour * 60 + EndMin of
        true -> true;
        false -> false
    end.

%% 判断是否在报名时间内
is_apply_time(BeginHour, BeginMin, _EndHour, _EndMin, ApplyTime) ->
    {Hour, Min, _Sec} = time(),
    NowTime = Hour * 60 + Min,
    case NowTime >= BeginHour * 60 + BeginMin andalso NowTime < BeginHour * 60 + BeginMin + ApplyTime of
        true -> true;
        false -> false
    end.

%% 判断是否在提交任务时间内
is_submit_time(BeginHour, BeginMin, EndHour, EndMin, ApplyTime) ->
    {Hour, Min, _Sec} = time(),
    NowTime = Hour * 60 + Min,
    case NowTime >= BeginHour * 60 + BeginMin + ApplyTime andalso NowTime < EndHour * 60 + EndMin of
        true -> true;
        false -> false
    end.

%% 进入场景
login(Status, RoomId) ->
    SceneId = data_loverun:get_loverun_config(scene_id),
    case lib_player:is_transferable(Status) of
        false -> 
            {6, Status};
        true ->
            %% 该场景不允许上坐骑
            M = Status#player_status.mount,
            case M#status_mount.mount_figure > 0 of
                true -> {7, Status};
                false ->
%%                    %% 进入场景只能为和平模式
%%                    Pk = Status#player_status.pk,
%%                    Now = util:unixtime(),
%%                    Type = 0,
%%                    NewStatus = Status#player_status{pk=Pk#status_pk{pk_status=Type, pk_status_change_time=Now}},
%%                    %通知场景的玩家
%%                    {ok, BinData} = pt_120:write(12084, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, Type, Pk#status_pk.pk_value]),
%%                    lib_server_send:send_to_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, BinData),
                    %% 进入前自动离队
                    case is_pid(Status#player_status.pid_team) of
                        true ->
                            pp_team:handle(24005, Status, no);
                        false -> skip
                    end,
                    %% 记录场景坐标
                    NewStatus = Status,
                    mod_loverun:goin_room(NewStatus#player_status.id),
                    mod_exit:insert_last_xy(NewStatus#player_status.id, NewStatus#player_status.scene, NewStatus#player_status.x, NewStatus#player_status.y),
                    {X, Y} = data_loverun:get_loverun_config(scene_born),
                    CopyId = RoomId,
                    lib_scene:change_scene_queue(NewStatus, SceneId, CopyId, X, Y, 0),
                    {1, NewStatus}
            end
    end.

%% 退出场景
logout(Status) ->
    %io:format("out~n"),
    LoverunSceneId = data_loverun:get_loverun_config(scene_id),
    PlayerId = Status#player_status.id,
    case Status#player_status.scene =:= LoverunSceneId of
        false -> 5;
        true -> 
            mod_loverun:out_room(Status#player_status.id),
            mod_loverun:logout(Status),
            %% 查找用户登录前记录的场景ID和坐标
            %% 传送自己
            case mod_exit:lookup_last_xy(PlayerId) of
                [_SceneId1, _X1, _Y1] -> 
                    case _SceneId1 of
                        LoverunSceneId -> [SceneId1,X1,Y1] = data_loverun:get_loverun_config(leave_scene2);
                        _ -> 
                            %%判断，如果不是普通场景和野外场景，则返回长安主城
                            SceneType1 = lib_scene:get_res_type(_SceneId1),
                            case SceneType1 =:= ?SCENE_TYPE_NORMAL orelse SceneType1 =:= ?SCENE_TYPE_OUTSIDE of
                                true ->
                                    [SceneId1,X1,Y1] = [_SceneId1, _X1, _Y1];
                                false -> 
                                    [SceneId1,X1,Y1] = data_loverun:get_loverun_config(leave_scene2)
                            end
                    end;
                _ -> [SceneId1,X1,Y1] = data_loverun:get_loverun_config(leave_scene2)
            end,
            lib_scene:player_change_scene_queue(PlayerId, SceneId1, 0, X1, Y1, [{parner_id, 0}, {loverun_state, 1}]),
            1
    end.

%% 开始长跑，把2个人都送到起跑点
start_running(MyId, ParnerId, Scene, CopyId, BeginX, BeginY, State) ->
    lib_scene:player_change_scene_queue(MyId, Scene, CopyId, BeginX, BeginY, [{loverun_state, 2}, {parner_id, ParnerId}]),
    lib_scene:player_change_scene_queue(ParnerId, Scene, CopyId, BeginX, BeginY, [{loverun_state, 2}, {parner_id, MyId}]),
    %% 记录活动开始时间
    [BeginHour, BeginMin, _EndHour, _EndMin, ApplyTime] = State#player_status.loverun_data,
    StartTime = ((BeginHour * 60 + BeginMin + ApplyTime) * 60 + util:unixdate()) * 1000,
    put({start_run, MyId, ParnerId}, StartTime).

%% 登录退出爱情长跑场景
login_out(Status) -> 
    mod_loverun:logout(Status),
    case catch mod_loverun:get_begin_end_time() of
        {BeginHour, BeginMin, EndHour, EndMin, ApplyTime} -> 
            ok;
        _Reason -> 
            {BeginHour, BeginMin, EndHour, EndMin, ApplyTime} = get_start_time()
    end,
    LoverunId = data_loverun:get_loverun_config(scene_id),
    LoverunState = case catch mod_loverun:task_state(Status#player_status.id) of
        {ok, _State} -> _State;
        _ -> 1
    end,
    case Status#player_status.scene =:= LoverunId of
        true -> 
            {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
            Status#player_status{
                scene = ?MAIN_CITY_SCENE, 
                x = MainCityX, 
                y = MainCityY, 
                loverun_data = [BeginHour, BeginMin, EndHour, EndMin, ApplyTime],
                loverun_state = LoverunState
            };
        false -> 
            Status#player_status{
                loverun_data = [BeginHour, BeginMin, EndHour, EndMin, ApplyTime],
                loverun_state = LoverunState
            }
    end.

%% 报名等待中定时获得经验
get_exp(PlayerId, PlayerLv) ->
    case get({last_get_exp, PlayerId}) of
        %% 无记录
        undefined -> 
            put({last_get_exp, PlayerId}, util:unixtime()),
            0;
        LastTime -> 
            %% 是否已过10秒
            case util:unixtime() - LastTime >= 10 of
                true -> 
                    put({last_get_exp, PlayerId}, util:unixtime()),
                    PlayerLv * PlayerLv * 0.5;
                false -> 
                    0
            end
    end.

%% 防作弊处理
cheat_handle(PlayerStatus) ->
    PlayerId = PlayerStatus#player_status.id,
    ParnerId = PlayerStatus#player_status.parner_id,
    X = PlayerStatus#player_status.x,
    Y = PlayerStatus#player_status.y,
    LoverunData = PlayerStatus#player_status.loverun_data,
    {X1, Y1} = {94, 121},
    {X2, Y2} = {166, 167},
    {X3, Y3} = {24, 213},
    {X4, Y4} = {97, 295},
    case near_cheat_point(X, Y, X1, Y1) of
        true ->
            mod_loverun:crossing_point(PlayerId, ParnerId, 1, LoverunData);
        false ->
            case near_cheat_point(X, Y, X2, Y2) of
                true ->
                    mod_loverun:crossing_point(PlayerId, ParnerId, 2, LoverunData);
                false ->
                    case near_cheat_point(X, Y, X3, Y3) of
                        true ->
                            mod_loverun:crossing_point(PlayerId, ParnerId, 3, LoverunData);
                        false ->
                            case near_cheat_point(X, Y, X4, Y4) of
                                true ->
                                    mod_loverun:crossing_point(PlayerId, ParnerId, 4, LoverunData);
                                false ->
                                    skip
                            end
                    end
            end
    end.

near_cheat_point(X, Y, X1, Y1) ->
    ((X - X1) * (X - X1) + (Y - Y1) * (Y - Y1)) =< 400.
