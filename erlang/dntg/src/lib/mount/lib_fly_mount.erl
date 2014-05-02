%%%--------------------------------------
%%% @Module  : lib_fly_mount
%%% @Author  : zhenghehe
%%% @Created : 2010.08.18
%%% @Description: 飞行坐骑
%%%-------------------------------------

-module(lib_fly_mount).
-export([trigger_task/2,finish_task/2,online/1,cancel_task/2,cancel_task2/1, can_fly/1, online_on_pid/1, send_fly_mount_notify/9, offline/1, use_goods/2, get_fly_mount/1]).

-include("common.hrl").
-include("server.hrl").
-include("task.hrl").
-include("sql_fly.hrl").
-include("goods.hrl").


%% 触发飞行坐骑任务
trigger_task(TD, PS) ->
    Mou = PS#player_status.mount,
    case lists:member(TD#task.id, ?FLY_TASK) of
        true -> 
            PS1 = lib_player:count_player_speed(PS#player_status{mount=Mou#status_mount{fly_mount = get_fly_mount(TD#task.id), fly_mount_speed = ?FLY_MOUNT_SPEED}}),
            Mou1 = PS1#player_status.mount,
            send_fly_mount_notify(PS1#player_status.id, PS1#player_status.platform, PS1#player_status.server_num, PS1#player_status.speed, Mou1#status_mount.fly_mount, PS1#player_status.scene, PS1#player_status.copy_id, 1, 180),
            mod_scene_agent:update(fly_mount, PS1),
            Sit = PS1#player_status.sit,
            PS2 = 
            if
                Sit#status_sit.sit_down == 1 ->
                    lib_sit:sit_up(PS1);
                Sit#status_sit.sit_down == 2 ->
                    case lib_player:get_player_info(Sit#status_sit.sit_role, nickname) of
                        false ->
                            PS1;
                        PlayerName ->
                            lib_sit:shuangxiu_interrupt(PS1, Sit#status_sit.sit_role, PlayerName)
                    end;
                true ->
                    PS1
            end,
            Mount = PS2#player_status.mount,
            PS3 = 
            if
                Mount#status_mount.mount_figure /= 0 ->
                    case lib_mount:get_off(PS2, Mount#status_mount.mount, Mount#status_mount.mount_dict) of
                        {fail, Res} ->
                            {ok, BinData} = pt_160:write(16003, [Res, Mount#status_mount.mount]),
                            lib_server_send:send_one(PS2#player_status.socket, BinData),
                            PS2;
                        {ok, NewPlayerStatus} ->
                            {ok, BinData} = pt_160:write(16003, [1, Mount#status_mount.mount]),
                            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                            lib_player:send_attribute_change_notify(NewPlayerStatus, 3),
                            Mou2 = NewPlayerStatus#player_status.mount,
                            {ok, BinData1} = pt_120:write(12010, [NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.platform, NewPlayerStatus#player_status.server_num, NewPlayerStatus#player_status.speed, Mou2#status_mount.mount_figure]),
                            lib_server_send:send_to_area_scene(NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.copy_id, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, BinData1),
                            NewPlayerStatus
                    end;
                true ->
                    PS2
            end,
            lib_player:refresh_client(PS3),
            PS3;
        false -> PS
    end.

%% 完成飞行坐骑任务
finish_task(TD, PS) -> 
    Mou = PS#player_status.mount,
    case Mou#status_mount.fly_mount == get_fly_mount(TD#task.id) of
        true ->
            case mod_task:normal_finish(TD#task.id, [], PS) of
                {true, PS1} ->
                    M = PS1#player_status.mount,
                    PS2 = lib_player:count_player_speed(PS1#player_status{mount=M#status_mount{fly_mount = 0, fly_mount_speed = 0}}),
                    M2 = PS2#player_status.mount,
                    send_fly_mount_notify(PS2#player_status.id, PS2#player_status.platform, PS2#player_status.server_num, PS2#player_status.speed, M2#status_mount.fly_mount, PS2#player_status.scene, PS2#player_status.copy_id, 0, 0),
                    mod_scene_agent:update(fly_mount, PS2),
                    lib_player:refresh_client(PS2),
                    {true, PS2};
                _Other -> _Other
            end; 
        false -> mod_task:normal_finish(TD#task.id, [], PS)
    end.

%% 放弃任务
cancel_task(PS, TaskId) ->
    Mou = PS#player_status.mount,
    case Mou#status_mount.fly_mount == get_fly_mount(TaskId) of
        true ->
            PS1 = lib_player:count_player_speed(PS#player_status{mount=Mou#status_mount{fly_mount = 0, fly_mount_speed = 0}}),
            M2 = PS1#player_status.mount,
            send_fly_mount_notify(PS1#player_status.id, PS1#player_status.platform, PS1#player_status.server_num, PS1#player_status.speed, M2#status_mount.fly_mount, PS1#player_status.scene, PS1#player_status.copy_id, 0, 0),
            mod_scene_agent:update(fly_mount, PS1),
            lib_player:refresh_client(PS1),
            PS1;
        false -> PS
    end.

%% 放弃任务
cancel_task2(PS) ->
    TaskList = lib_task:get_trigger(PS#player_status.tid),
    Result = [{lists:member(X#role_task.task_id, ?FLY_TASK),X#role_task.task_id,X#role_task.trigger_time}||X<-TaskList],
    case lists:keyfind(true, 1, Result) of
        false -> 
            ok;
        {true, TaskId, TriggerTime} -> 
            LeftTime = TriggerTime + 180 - util:unixtime(),
            case LeftTime =< 0 of
                true -> 
                    PS1 = cancel_task(PS, TaskId),
                    {ok, PS1};
                false -> 
                    skip
            end
    end.
    
%%上线初始
online(PS) ->
    gen_server:cast(PS#player_status.pid, {'apply_cast', lib_fly_mount, online_on_pid, [PS]}),
    TaskList = lib_task:get_trigger(PS#player_status.tid),
    Result = [{lists:member(X#role_task.task_id, ?FLY_TASK), X#role_task.task_id, X#role_task.trigger_time}||X<-TaskList],
    Mou = PS#player_status.mount,
    case lists:keyfind(true,1,Result) of
        false -> PS;
        {true, TaskId, TriggerTime} ->
            LeftTime = TriggerTime + 180 - util:unixtime(),
            case LeftTime =< 0 of
                true -> PS;
                false -> 
                    PS1 = PS#player_status{ mount = Mou#status_mount{fly_mount = get_fly_mount(TaskId),  fly_mount_speed = ?FLY_MOUNT_SPEED}},
                    lib_player:count_player_speed(PS1)
            end
    end.

%% 下线保存
offline(PS) ->
    case lib_server_dict:fly_prop() of
        [] ->
            ok;
        {FlyStatus, GoodsTypeId, FlyMountId, FlyMountSpeed, Permanent, TriggerTime, LeftTime, LastGoodsTypeId} ->
            NewLeftTime = 
            if
                FlyStatus == 1 ->
                    LeftTime-util:unixtime()+TriggerTime;
                true ->
                    LeftTime
            end,
            Sql = io_lib:format(?FLY_INSERT, [PS#player_status.id, FlyStatus, GoodsTypeId, FlyMountId, FlyMountSpeed, Permanent, NewLeftTime, LastGoodsTypeId]),
            db:execute(Sql),
            ok
    end.

online_on_pid(PS) ->
    Sql = io_lib:format(?FLY_SELECT_ONE, [PS#player_status.id]),
    case db:get_row(Sql) of
        [] ->
            lib_server_dict:fly_prop([]);
        [_PlayerId, FlyStatus, GoodsTypeId, FlyMountId, FlyMountSpeed, Permanent, FlyTime, LastGoodsTypeId] ->
            TriggerTime = 
            if
                FlyStatus == 1 ->
                    util:unixtime();
                true ->
                    0
            end,
            lib_server_dict:fly_prop({FlyStatus, GoodsTypeId, FlyMountId, FlyMountSpeed, Permanent, TriggerTime, FlyTime, LastGoodsTypeId})
    end,
    ok.

send_fly_mount_notify(Id, Platform, SerNum, Speed, FlyMountId, Scene, CopyId, Permanent, LeftTime) ->
    {ok, BinData} = pt_121:write(12106, [Id, Platform, SerNum, Speed, FlyMountId, Permanent, LeftTime]),
    lib_server_send:send_to_scene(Scene, CopyId, BinData).

can_fly(PS) ->
    IsDungeon = lib_scene:is_dungeon_scene(PS#player_status.scene),
    IsGuildBattleScene = data_arean_new:get_arena_config(scene_id),
    %% 帮战地图,副本，温泉或竞技场
    case IsGuildBattleScene orelse IsDungeon orelse PS#player_status.scene =:=231 orelse PS#player_status.scene=:=223 of
        true ->
            false;
        false ->
            true
    end.

use_goods(Status, [GoodsInfo]) ->
    Go = Status#player_status.goods,
    [Result, Status2] = 
    if  % 该物品不存在
        GoodsInfo =:= []  -> [2, Status];
        true ->
            [GoodsId, GoodsPlayerId, GoodsTypeId, GoodsLevel]  =
            [GoodsInfo#goods.id, GoodsInfo#goods.player_id, GoodsInfo#goods.goods_id, GoodsInfo#goods.level],
            if   % 物品不归你所有
                 GoodsPlayerId /= Status#player_status.id -> [3, Status];
                 true ->
                     GoodsTypeInfo = data_fly_mount:get(GoodsTypeId),
                     if % 该物品类型信息不存在
                        GoodsTypeInfo =:= [] ->
                            [0, Status];
                        true ->
                            {LeftTime, FlyMountId} = GoodsTypeInfo,
                            Permanent = 
                            case LeftTime > 0 of
                                true ->
                                    0;
                                false ->
                                    1
                            end,
                            if  % 你级别不够
                                Status#player_status.lv < GoodsLevel -> [4, Status];
                                true ->
                                    case gen_server:call(Go#status_goods.goods_pid, {'delete_one', GoodsId, 1}) of
                                        1 ->
                                            [LastFlyStatus, LastGoodsTypeId] = 
                                            case lib_server_dict:fly_prop() of
                                                [] ->
                                                    [0, 0];
                                                {OldFlyStatus, OldGoodsTypeId, _, _, _, _, _, _} ->
                                                    OldGoodsTypeInfo = data_fly_mount:get(OldGoodsTypeId),
                                                    if 
                                                        OldGoodsTypeInfo =:= [] ->
                                                            [0, 0];
                                                        true ->
                                                            {_, OldLeftTime} = OldGoodsTypeInfo,
                                                            OldPermanent = 
                                                            case OldLeftTime > 0 of
                                                                true ->
                                                                    0;
                                                                false ->
                                                                    1
                                                            end,
                                                            case OldPermanent == 1 andalso Permanent == 0 of
                                                                true ->
                                                                    [OldFlyStatus, OldGoodsTypeId];
                                                                false ->
                                                                    [OldFlyStatus, 0]
                                                            end
                                                    end
                                            end,
                                            lib_server_dict:fly_prop({LastFlyStatus, GoodsTypeId, FlyMountId, ?FLY_MOUNT_SPEED, Permanent, 0, LeftTime, LastGoodsTypeId}),
                                            Sql = io_lib:format(?FLY_INSERT, [Status#player_status.id, LastFlyStatus, GoodsTypeId, FlyMountId, ?FLY_MOUNT_SPEED, Permanent, LeftTime, LastGoodsTypeId]),
                                            db:execute(Sql),
                                            Mou = Status#player_status.mount,
                                            if
                                                Mou#status_mount.fly_mount > 0 ->
                                                    Status1 = lib_player:count_player_speed(Status#player_status{mount=Mou#status_mount{fly_mount = FlyMountId, fly_mount_speed = ?FLY_MOUNT_SPEED}}),
                                                    Mou1 = Status1#player_status.mount,
                                                    send_fly_mount_notify(Status1#player_status.id, Status1#player_status.platform, Status1#player_status.server_num, Status1#player_status.speed, Mou1#status_mount.fly_mount, Status1#player_status.scene, Status1#player_status.copy_id, 1, LeftTime),
                                                    [1, Status1];
                                                true ->
                                                    [1, Status]
                                            end;
                                        _GoodsModuleCode ->
                                            [0, Status]
                                    end
                            end
                    end
            end
    end,
    {ok, BinData} = pt_132:write(13202, [Result]),
    lib_server_send:send_to_sid(Status2#player_status.sid, BinData),
    {ok, Status2}.

get_fly_mount(TaskId) ->
    if
        TaskId == 100481 ->
            311106;
		TaskId == 101310 -> 
			311103;
        true ->
            311107
    end.
