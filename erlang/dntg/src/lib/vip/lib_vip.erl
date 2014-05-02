%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-1-5
%% Description: vip操作类
%% --------------------------------------------------------
-module(lib_vip).
-compile(export_all).
-include("common.hrl").
-include("goods.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("errcode_goods.hrl").
-include("unite.hrl").
-include("buff.hrl").
-include("guild.hrl").
-include("shop.hrl").

-define(Vip_Flay_Type, 1005).
-define(SCENE, [{100, 30, 60},
                {160, 27, 41},
                {180, 65, 44},
                {200, 34, 54},
                {220, 38, 63},
                {240, 26, 47},
                {260, 26, 58},
                {280, 28, 49}]).

-define(SQL_UPDATE_VIP, <<"update player_vip set vip_type=~p, vip_time=~p where id=~p">>).
-define(SQL_UPDATE_VIP3, <<"update player_vip set vip_type=0, vip_time=0 where id=~p">>).
-define(SQL_UPDATE_VIP2, "update player_vip set vip_bag_flag = '~s' where id = ~p").

%% @增加vip时间（以天为单位）
%% VipType：会员类型（0非会员、1黄金会员、2白金会员、3紫金会员、4体验会员)、sec：会员时间（秒）
%% @Return
%% 1你已经是会员、{ok, PlayerStatus}成功
add_vip(PlayerStatus, VipType, Sec) ->
    Now = util:unixtime(),
    Vip = PlayerStatus#player_status.vip,
    %不能覆盖
    case (VipType < Vip#status_vip.vip_type andalso Vip#status_vip.vip_type < 4) orelse (VipType =:= 4 andalso Vip#status_vip.vip_type > 0) of
        %% VIP状态已存在
        true ->
            case (VipType >= 0  andalso Vip#status_vip.vip_type >= 0) of
                true ->
                    case Vip#status_vip.vip_end_time =< Now of
                        true ->
                            EndTime = Now + Sec;
                        _ ->
                            EndTime = Vip#status_vip.vip_end_time + Sec
                    end,
                    NewPlayerStatus = PlayerStatus#player_status{vip = Vip#status_vip{vip_end_time = EndTime}},
                    Sql1 = io_lib:format(?SQL_UPDATE_VIP, [Vip#status_vip.vip_type, EndTime, NewPlayerStatus#player_status.id]),
                    db:execute(Sql1),
                    NewPlayerStatus1 = send_vip_bag(NewPlayerStatus, VipType, Sec),
                    pp_vip:handle(45062, NewPlayerStatus1, []),
                    V = NewPlayerStatus1#player_status.vip,
                    LeftTime = V#status_vip.vip_end_time - Now,
                    {ok, BinData} = pt_450:write(45003, [LeftTime]),
                    lib_server_send:send_one(NewPlayerStatus1#player_status.socket, BinData),
                    pp_vip:handle(45007, NewPlayerStatus1, 0),
                    pp_vip:handle(45016, NewPlayerStatus1, no),
                    {ok, NewPlayerStatus1};                 
                false ->
                    {fail, 1536}
            end;            
        false ->
            case Vip#status_vip.vip_end_time =< Now of
                true ->
                    EndTime = Now + Sec;
                _ ->
                    EndTime = Vip#status_vip.vip_end_time + Sec
            end,
            NewPlayerStatus = PlayerStatus#player_status{vip = Vip#status_vip{vip_type = VipType, vip_end_time = EndTime}},
            %% Vip等级同步到公共线
            lib_player:update_unite_info(NewPlayerStatus#player_status.unite_pid, [{vip, VipType}]),
            %play_low表插入数据
            Sql1 = io_lib:format(?SQL_UPDATE_VIP, [VipType, EndTime, PlayerStatus#player_status.id]),
            db:execute(Sql1),
            %%add by xieyunfei vip改变改动时候重新计算体力值
            lib_physical:vip_change(PlayerStatus,VipType),
            %lib_player:send_attribute_change_notify(NewPlayerStatus, 2),
%%          %VIP广播
            {ok, Bin} = pt_122:write(12203, [PlayerStatus#player_status.id, PlayerStatus#player_status.platform, PlayerStatus#player_status.server_num, VipType]),
            lib_server_send:send_to_scene(PlayerStatus#player_status.scene, PlayerStatus#player_status.copy_id, Bin),
%%             %世界传闻 格式:"vip" + viptype + id + name + sex + career + image + realm
            lib_chat:send_TV({all},0,1, ["vip",
                                 VipType,
                                 PlayerStatus#player_status.id, 
                                 PlayerStatus#player_status.nickname, 
                                 PlayerStatus#player_status.sex, 
                                 PlayerStatus#player_status.career, 
                                 PlayerStatus#player_status.image, 
                                 PlayerStatus#player_status.realm]),
            mod_disperse:cast_to_unite(lib_guild, change_vip, [PlayerStatus#player_status.id, VipType]),
            %%新服vip礼包奖励
            NewPlayerStatus1 = send_vip_bag(NewPlayerStatus, VipType, Sec),
            pp_vip:handle(45062, NewPlayerStatus1, []),
            V = NewPlayerStatus1#player_status.vip,
            LeftTime = V#status_vip.vip_end_time - Now,
            {ok, BinData} = pt_450:write(45003, [LeftTime]),
            lib_server_send:send_one(NewPlayerStatus1#player_status.socket, BinData),
            pp_vip:handle(45007, NewPlayerStatus1, 0),
            %% 是否可领取开服7天礼包
            pp_vip:handle(45014, NewPlayerStatus1, no),
            pp_vip:handle(45016, NewPlayerStatus1, no),
            {ok, NewPlayerStatus1}
    end.


%VIP检测过期
check_vip(PlayerStatus) ->
    Vip = PlayerStatus#player_status.vip,
    case Vip#status_vip.vip_type > 0 of
        true ->
            Now = util:unixtime(),
            case Vip#status_vip.vip_end_time > Now of
                true ->
                    PlayerStatus;
                _ ->    %%过期
                    {ok,NewPlayerStatus} = clear_vip_info(PlayerStatus),
					%% 如果在VIP挂机场景中则踢出
					out_room(PlayerStatus),
					%% Vip等级同步到公共线
					lib_player:update_unite_info(NewPlayerStatus#player_status.unite_pid, [{vip, 0}]),
                    lib_player:send_attribute_change_notify(NewPlayerStatus, 0),
                    %场景广播
                    {ok, BinData} = pt_122:write(12202, [NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.platform, NewPlayerStatus#player_status.server_num]),
                    lib_server_send:send_to_area_scene(NewPlayerStatus#player_status.scene, 
                                                       NewPlayerStatus#player_status.copy_id, 
                                                       NewPlayerStatus#player_status.x, 
                                                       NewPlayerStatus#player_status.y, BinData),
                    Name = data_sell_text:vip_name(Vip#status_vip.vip_type),
                    [Title, C] = data_sell_text:vip_text(1),
                    Content = io_lib:format(C, [Name]),
                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[NewPlayerStatus#player_status.id], Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
                    %% 更新帮派成员信息
                    case mod_disperse:call_to_unite(lib_guild_base, get_guild_member_by_player_id, [PlayerStatus#player_status.id]) of
                        Any when is_record(Any, ets_guild_member) ->
                            mod_disperse:cast_to_unite(lib_guild_base, update_guild_member, [Any#ets_guild_member{vip = 0}]);
                        _Other -> 
                            skip
                    end,
                    NewPlayerStatus
            end;
        _ ->
            PlayerStatus
    end.

get_scene_by_mon(MonId) ->
    case lib_mon:get_mon_by_mid(MonId) of
        [] ->
            0;
        MonData ->
            [MonData#ets_scene_mon.scene, MonData#ets_scene_mon.x, MonData#ets_scene_mon.y]
    end.

%任务传送-指定怪
vip_task_transport(mon, PlayerStatus, MonId) ->
    LeftTime = check_fly_times(PlayerStatus),
    Res = get_scene_by_mon(MonId),
    Vip = PlayerStatus#player_status.vip,
    case Res =:= 0 of
        true ->
            {ok, PlayerStatus, 2, 0};
        _ ->
            [SceneId, X, Y] = get_aim_xy(Res),
            %等级是否足够
            case check_scene_require_lv(SceneId, PlayerStatus) of
                false ->
                    {ok, PlayerStatus, 5, 0};
                _ ->
                    %%判断，如果是BOSS场景，只能传送到场景入口
                    case lib_scene:get_data(SceneId) of
                        _S when is_record(_S, ets_scene) ->
                            SceneType = _S#ets_scene.type;
                        _ ->
                            SceneType = 0
                    end,
                    case SceneType =:= ?SCENE_TYPE_BOSS of
                        true -> 
                            Pk = PlayerStatus#player_status.pk,
                            case Pk#status_pk.pk_status =/= 2 andalso Pk#status_pk.pk_status =/= 3 of
                                true ->
                                    {ok, PlayerStatus, 6, 0};
                                false ->
                                    vip_task_transport(scene, PlayerStatus, SceneId)
                            end;
                        false ->
                            case lib_scene:is_dungeon_scene(SceneId) of
                                true ->
                                    {ok, PlayerStatus, 2, 0};
                                _ ->
                                    case Vip#status_vip.vip_type >= 0 andalso LeftTime >= 0 of
                                        %会员传送
                                        true ->
                                            Flag1 = is_forbidden_fly_to_scene_type(SceneId),
                                            Flag2 = is_forbidden_fly_from_scene_type(PlayerStatus#player_status.scene),
                                            Flag3 = is_forbidden_fly_scene_id(PlayerStatus#player_status.scene),
                                            case Flag1 =:= true orelse Flag2 =:= true orelse Flag3 =:= true of
                                                false ->
                                                    lib_scene:leave_scene(PlayerStatus),
                                                    %pp_scene:handle(12004, PlayerStatus, s),
                                                    NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
                                                    case lib_scene:get_data(SceneId) of
                                                        S when is_record(S, ets_scene) ->
                                                            SceneName = S#ets_scene.name;
                                                        _ ->
                                                            SceneName = <<>>
                                                    end,
                                                    {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, 
                                                            NewPlayerStatus#player_status.x, 
                                                            NewPlayerStatus#player_status.y, 
                                                            SceneName, NewPlayerStatus#player_status.scene]),
                                                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                                    mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ?Vip_Flay_Type),
                                                    {ok, NewPlayerStatus, 0, LeftTime-1};
                                                true ->
                                                    {ok, PlayerStatus, 2, 0}
                                            end;
                                        %使用小飞鞋
                                        false ->
                                            Flag1 = is_forbidden_fly_to_scene_type(SceneId),
                                            Flag2 = is_forbidden_fly_from_scene_type(PlayerStatus#player_status.scene),
                                            Flag3 = is_forbidden_fly_scene_id(PlayerStatus#player_status.scene),
                                            case Flag1 =:= true orelse Flag2 =:= true orelse Flag3 =:= true of
                                                false ->
                                                    Res_goods = use_shoes(PlayerStatus),
                                                    case Res_goods of
                                                        1 ->
                                                            lib_scene:leave_scene(PlayerStatus),
                                                            %pp_scene:handle(12004, PlayerStatus, s),
                                                            NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
                                                            case lib_scene:get_data(SceneId) of
                                                                S when is_record(S, ets_scene) ->
                                                                    SceneName = S#ets_scene.name;
                                                                _ ->
                                                                    SceneName = <<>>
                                                            end,
                                                            {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, 
                                                                    NewPlayerStatus#player_status.x, 
                                                                    NewPlayerStatus#player_status.y, 
                                                                    SceneName, NewPlayerStatus#player_status.scene]),
                                                            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                                            {ok, NewPlayerStatus, 0, 0};
                                                        _ ->
                                                            {ok, PlayerStatus, 3, 0}
                                                    end;
                                                _ ->
                                                    {ok, PlayerStatus, 2, 0}
                                            end
                                    end
                            end
                    end
            end
    end;


%任务传送-指定npc
vip_task_transport(npc, PlayerStatus, NpcId) ->
    LeftTime = check_fly_times(PlayerStatus),
    Res = lib_npc:get_scene_by_npc_id(NpcId),
    Vip = PlayerStatus#player_status.vip,
    case Res of
        [] ->
            {ok, PlayerStatus, 2, 0};
        _R ->
            [Scene, X1, Y1, _] = Res,
            [SceneId, X, Y] = get_aim_xy([Scene, X1, Y1]),
            case check_scene_require_lv(SceneId, PlayerStatus) of
                false ->
                    {ok, PlayerStatus, 5, 0};
                _ ->
                    case Vip#status_vip.vip_type>=0 andalso LeftTime >= 0 of
                        %会员传送
                        true ->
                            Flag1 = is_forbidden_fly_to_scene_type(SceneId),
                            Flag2 = is_forbidden_fly_from_scene_type(PlayerStatus#player_status.scene),
							Flag3 = is_forbidden_fly_scene_id(PlayerStatus#player_status.scene),
							case Flag1 =:= true orelse Flag2 =:= true orelse Flag3 =:= true of
                                false ->
                                    lib_scene:leave_scene(PlayerStatus),
                                    %pp_scene:handle(12004, PlayerStatus, s),
                                    NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
                                    case lib_scene:get_data(SceneId) of
                                        S when is_record(S, ets_scene) ->
                                            SceneName = S#ets_scene.name;
                                        _ ->
                                            SceneName = <<>>
                                    end,
                                    {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, 
                                                                         NewPlayerStatus#player_status.x, 
                                                                         NewPlayerStatus#player_status.y, 
                                                                         SceneName, NewPlayerStatus#player_status.scene]),
                                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                    %记录飞行次数
                                    mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ?Vip_Flay_Type),
                                    {ok, NewPlayerStatus, 0, LeftTime-1};
                                true ->
                                    {ok, PlayerStatus, 2, 0}
                            end;
                        %使用小飞鞋
                        false ->
                            Flag1 = is_forbidden_fly_to_scene_type(SceneId),
                            Flag2 = is_forbidden_fly_from_scene_type(PlayerStatus#player_status.scene),
                            Flag3 = is_forbidden_fly_scene_id(PlayerStatus#player_status.scene),
                            case Flag1 =:= true orelse Flag2 =:= true orelse Flag3 =:= true of
                                false ->
                                    Res_goods = use_shoes(PlayerStatus),
                                    case Res_goods of
                                        1 ->
                                            lib_scene:leave_scene(PlayerStatus),
                                            %pp_scene:handle(12004, PlayerStatus, s),
                                            NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
                                            case lib_scene:get_data(SceneId) of
                                                S when is_record(S, ets_scene) ->
                                                    SceneName = S#ets_scene.name;
                                                _ ->
                                                    SceneName = <<>>
                                            end,
                                            {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, 
                                                    NewPlayerStatus#player_status.x, 
                                                    NewPlayerStatus#player_status.y, 
                                                    SceneName, NewPlayerStatus#player_status.scene]),
                                            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                            {ok, NewPlayerStatus, 0, 0};
                                        _ ->
                                            {ok, PlayerStatus, 3, 0}
                                    end;
                                _ ->
                                    {ok, PlayerStatus, 2, 0}
                            end
                    end
            end
    end;

%场景传送-小飞鞋
vip_task_transport(scene, PlayerStatus, _SceneId) ->
    SceneId = boss_scene_deal(_SceneId),
    LeftTime = check_fly_times(PlayerStatus),
    MScene = ets:lookup(?ETS_SCENE, SceneId),
    Vip = PlayerStatus#player_status.vip,
    case MScene of
        [] ->
            {ok, PlayerStatus, 2, 0};
        _ ->
            [Scene] = MScene,
            Res = [Scene#ets_scene.id,Scene#ets_scene.x,Scene#ets_scene.y],
            {_, {_, Lv}} = lists:keysearch(lv, 1, Scene#ets_scene.requirement),
            case Res of
                [] ->
                    {ok, PlayerStatus, 2, 0};
                R ->
                    [SceneId, X, Y] = get_aim_xy(R),
                    %等级不足
                    case PlayerStatus#player_status.lv >= Lv of
                        true ->
                            case Vip#status_vip.vip_type >= 0 andalso LeftTime >= 0 of
                                %会员传送
                                true ->
                                    Flag1 = is_forbidden_fly_to_scene_type(SceneId),
                                    Flag2 = is_forbidden_fly_from_scene_type(PlayerStatus#player_status.scene),
									Flag3 = is_forbidden_fly_scene_id(PlayerStatus#player_status.scene),
									case Flag1 =:= true orelse Flag2 =:= true orelse Flag3 =:= true of
                                        false ->
                                            lib_scene:leave_scene(PlayerStatus),
                                            %pp_scene:handle(12004, PlayerStatus, s),
                                            NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
                                            case lib_scene:get_data(SceneId) of
                                                S when is_record(S, ets_scene) ->
                                                    SceneName = S#ets_scene.name;
                                                _ ->
                                                    SceneName = <<>>
                                            end,
                                            {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, 
                                                                                 NewPlayerStatus#player_status.x, 
                                                                                 NewPlayerStatus#player_status.y, 
                                                                                 SceneName, NewPlayerStatus#player_status.scene]),
                                            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                            %记录飞行次数
                                            mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ?Vip_Flay_Type),
                                            {ok, NewPlayerStatus, 0, LeftTime-1};
                                        true ->
                                            {ok, PlayerStatus, 2, 0}
                                    end;
                                %使用小飞鞋
                                false ->
                                    Flag1 = is_forbidden_fly_to_scene_type(SceneId),
                                    Flag2 = is_forbidden_fly_from_scene_type(PlayerStatus#player_status.scene),
                                    Flag3 = is_forbidden_fly_scene_id(PlayerStatus#player_status.scene),
                                    case Flag1 =:= true orelse Flag2 =:= true orelse Flag3 =:= true of
                                        false ->
                                            Res_goods = use_shoes(PlayerStatus),
                                            case Res_goods of
                                                1 ->
                                                    lib_scene:leave_scene(PlayerStatus),
                                                    %pp_scene:handle(12004, PlayerStatus, s),
                                                    NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
                                                    case lib_scene:get_data(SceneId) of
                                                        S when is_record(S, ets_scene) ->
                                                            SceneName = S#ets_scene.name;
                                                        _ ->
                                                            SceneName = <<>>
                                                    end,
                                                    {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, 
                                                            NewPlayerStatus#player_status.x, 
                                                            NewPlayerStatus#player_status.y, 
                                                            SceneName, NewPlayerStatus#player_status.scene]),
                                                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                                    {ok, NewPlayerStatus, 0, 0};
                                                _ ->
                                                    {ok, PlayerStatus, 3, 0}
                                            end;
                                        _ ->
                                            {ok, PlayerStatus, 2, 0}
                                    end
                            end;
                        false ->
                            %返回等级不足.
                            {ok, PlayerStatus, 5, 0}
                    end
            end
    end.


%特定场景传送,暂时保留
vip_scene_transport(PlayerStatus, SceneId) ->
    SceneList = ?SCENE,
    case lists:keysearch(SceneId, 1, SceneList) of
        false ->
            {ok, PlayerStatus, 1};
        Res ->
            {value, {_, X, Y}} = Res,
            lib_scene:leave_scene(PlayerStatus),
            %pp_scene:handle(12004, PlayerStatus, s),
            NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
            SceneName = case data_scene:get_data(SceneId) of
                S when is_record(S, ets_scene) ->
                    S#ets_scene.name;
                _ ->
                    <<>>
            end,
            {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, 
                                                 NewPlayerStatus#player_status.x, 
                                                 NewPlayerStatus#player_status.y, 
                                                 SceneName, NewPlayerStatus#player_status.scene]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            {ok, NewPlayerStatus, 0}
    end.


%------------------内部函数-------------------------------%
%清空Vip信息
clear_vip_info(PlayerStatus) ->
    Vip = PlayerStatus#player_status.vip,
    NewPlayerStatus = PlayerStatus#player_status{vip=Vip#status_vip{vip_type = 0, vip_end_time = 0}},
    Sql1 = io_lib:format(?SQL_UPDATE_VIP3, [PlayerStatus#player_status.id]),
    db:execute(Sql1),
    {ok, NewPlayerStatus}.


%获取传送坐标
get_aim_xy([Scene, X, Y]) ->
    R1 = lib_scene:is_blocked(Scene,X,Y+3),
    R2 = lib_scene:is_blocked(Scene,X,Y-3),
    R3 = lib_scene:is_blocked(Scene,X+3,Y),
    R4 = lib_scene:is_blocked(Scene,X-3,Y),

    R5 = lib_scene:is_blocked(Scene,X+3,Y+3),
    R6 = lib_scene:is_blocked(Scene,X-3,Y-3),
    R7 = lib_scene:is_blocked(Scene,X+3,Y-3),
    R8 = lib_scene:is_blocked(Scene,X-3,Y+3),
    if
         R1 =:= false ->
            [Scene, X, Y+3];
         R2 =:= false ->
            [Scene, X, Y-3];
         R3 =:= false ->
            [Scene, X+3, Y];
         R4 =:= false ->
            [Scene, X-3, Y];
         R5 =:= false ->
            [Scene, X+3, Y+3];
         R6 =:= false ->
            [Scene, X-3, Y-3];
         R7 =:= false ->
            [Scene, X+3, Y-3];
         R8 =:= false ->
            [Scene, X-3, Y+3];
        true ->
            [Scene, X, Y]
    end.

%检测vip飞行次数
check_fly_times(_PlayerStatus) ->
%%     Vip = PlayerStatus#player_status.vip,
%%     case Vip#status_vip.vip_type of
%%         0 ->
%%             0;
%%         1 ->
%%             Htimes = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ?Vip_Flay_Type),
%%             15 - Htimes;
%%         2 ->
%%             Htimes = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ?Vip_Flay_Type),
%%             30 - Htimes;
%%         3 ->
%%             101;
%%         4 ->
%%             Htimes = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ?Vip_Flay_Type),
%%             15 - Htimes
%%     end,
    100.

use_shoes(PlayerStatus) ->
    Go = PlayerStatus#player_status.goods,
    %% 先扣绑定的
    case gen_server:call(Go#status_goods.goods_pid, {'delete_more', 611202, 1}) of
        1 ->
            1;
        _ ->
            case gen_server:call(Go#status_goods.goods_pid, {'delete_more', 611201, 1}) of 
                1 ->
                    1;
                _ ->
                    0
            end
    end.

%传入VIP圣地： [994,16,68] 1非VIP 2本地图无法传送，3运镖中无法传送， 0成功,
%% enter_vip_map(PlayerStatus) ->
%%     Flag = lib_scene:is_dungeon_scene(PlayerStatus#player_status.scene),
%%     Vip = PlayerStatus#player_status.vip,
%%     case Vip#status_vip.vip_type > 0 of
%%         true ->
%%             %本地图禁止传送
%%             case lists:member(PlayerStatus#player_status.scene, ?FORBIMAP) =:= false andalso Flag =:= false of
%%                 true ->
%%                     %通知别人离开场景
%%                     lib_scene:leave_scene(PlayerStatus),
%%                     NewPlayerStatus = PlayerStatus#player_status{scene=994, x=33, y=47},
%%                     %更新客户端信息
%%                     SceneId = NewPlayerStatus#player_status.scene,
%%                     SceneName = case lib_scene:get_data(SceneId) of
%%                                     [] ->
%%                                         <<>>;
%%                                     S ->
%%                                         S#ets_scene.name
%%                                 end,
%%                     {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, SceneName, NewPlayerStatus#player_status.scene]),
%%                     lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData);
%%                 false ->
%%                     {2, PlayerStatus}
%%             end;
%%         false ->
%%             {1, PlayerStatus}
%%     end.

%% out_vip_map(PlayerStatus) ->
%%     lib_scene:leave_scene(PlayerStatus),
%%     NewPlayerStatus = PlayerStatus#player_status{scene=220, x=29, y=42},
%%     SceneId = NewPlayerStatus#player_status.scene,
%%     SceneName = case lib_scene:get_data(SceneId) of
%%                     [] ->
%%                         <<>>;
%%                     S ->
%%                         S#ets_scene.name
%%                 end,
%%     {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, SceneName, NewPlayerStatus#player_status.scene]),
%%     lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
%%     {ok, NewPlayerStatus}.

check_scene_require_lv(SceneId, P) ->
    case ets:lookup(?ETS_SCENE, SceneId) of
        [] ->
            false;
        [Scene] ->
           case lists:keysearch(lv, 1, Scene#ets_scene.requirement) of
                {_, {_, Lv}} ->
%%                     case P#player_status.lv >= Lv andalso P#player_status.realm > 0 of
                    case P#player_status.lv >= Lv of
                        true ->
                            true;
                        _ ->
                            false
                    end;
                _ ->
                    false
            end;
        _ ->
            false
    end.

%场景传送-传送卷
scroll_transport(PlayerStatus, GoodsID) ->
    SceneId = goods2scene(GoodsID),
    case ets:lookup(?ETS_SCENE, SceneId) of
        [Scene] ->
            Res = [Scene#ets_scene.id,Scene#ets_scene.x,Scene#ets_scene.y],
            {_, {_, Lv}} = lists:keysearch(lv, 1, Scene#ets_scene.requirement),
            case Res of
                [SceneId, X, Y] ->
                    %等级不足
                    case PlayerStatus#player_status.lv >= Lv of
                        true ->
                            case lib_scene:is_dungeon_scene(PlayerStatus#player_status.scene) of
                                false ->
                                    case lists:member(PlayerStatus#player_status.scene, ?FORBIMAP) of
                                        false ->
                                            lib_scene:leave_scene(PlayerStatus),
                                            %pp_scene:handle(12004, PlayerStatus, s),
                                            NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
                                            case lib_scene:get_data(SceneId) of
                                                S when is_record(S, ets_scene) ->
                                                    SceneName = S#ets_scene.name;
                                                _ ->
                                                    SceneName = <<>>
                                            end,
                                            {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, 
                                                                                 NewPlayerStatus#player_status.x,
                                                                                 NewPlayerStatus#player_status.y, 
                                                                                 SceneName, NewPlayerStatus#player_status.scene]),
                                            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                            {ok, NewPlayerStatus};
                                        _ ->
                                            %本场景无法使用传送卷
                                            {fail, ?SCROLL_TR_NODR}
                                    end;
                                _ ->
                                    %副本中无法使用传送卷
                                    {fail, ?SCROLL_TR_NODR}
                            end;
                        _ ->
                            %等级不足
                            {fail, ?SCROLL_TR_NOLEVEL}
                     end;
                _ ->
                 %场景不存在
                 {fail, ?SCROLL_TR_NOSCENE}
            end;
         _ ->
             %场景不存在
             {fail, ?SCROLL_TR_NOSCENE}
     end.

goods2scene(GoodsId) ->
    case GoodsId of
        611005 -> 240;
        611006 -> 260;
        611007 -> 280;
        611008 -> 300;
        611009 -> 320;
        _ ->      0
    end.

change_vip(_Socket, _VipType, ID) ->
%%     {ok, BinData} = pt_450:write(45005, [VipType]),
%%     lib_server_send:send_one(Socket, BinData),
    SQL = io_lib:format(?SQL_UPDATE_VIP3, [ID]),
    db:execute(SQL).

% -------------------------
%  温泉累积
% -------------------------
%% check_water_time(_PlayerStatus) ->
%%     NowData = util:unixdate(),
%%     Water = _PlayerStatus#player_status.water,
%%     case Water#status_water.water_date =:= NowData of
%%         true ->
%%             _PlayerStatus;
%%         _ ->
%%             Time = case NowData - Water#status_water.water_date > 2*3600 of
%%                 true ->
%%                     60 + 60;
%%                 _ ->
%%                     60 + Water#status_water.water_time
%%             end,
%%             PlayerStatus = _PlayerStatus#player_status{water=Water#status_water{water_date = NowData, water_time = Time}},
%%             Water1 = PlayerStatus#player_status.water,
%%             Sql = io_lib:format("update `player_state` set water_time = ~p, water_date = ~p  where `id` = ~p", [Water1#status_water.water_time, Water1#status_water.water_date, PlayerStatus#player_status.id]),
%%             db:execute(Sql),
%%             PlayerStatus
%%     end.

killer_transport(PlayerStatus, SceneId, X, Y) ->
    LeftTime = check_fly_times(PlayerStatus),
    Vip = PlayerStatus#player_status.vip,
    case check_scene_require_lv(SceneId, PlayerStatus) of
        false ->
            {ok, PlayerStatus, 5, 0};
        _ ->
            %%判断，如果是BOSS场景，只能传送到场景入口
            case lib_scene:get_data(SceneId) of
                _S when is_record(_S, ets_scene) ->
                    SceneType = _S#ets_scene.type;
                _ ->
                    SceneType = 0                
            end,
            case SceneType =:= ?SCENE_TYPE_BOSS of
                true -> 
                    Pk = PlayerStatus#player_status.pk,
                    case Pk#status_pk.pk_status =/= 2 andalso Pk#status_pk.pk_status =/= 3 of
                        true ->
                            {ok, PlayerStatus, 6, 0};
                        false ->
                            vip_task_transport(scene, PlayerStatus, SceneId)
                    end;
                false ->
                    case lib_scene:is_dungeon_scene(SceneId) of
                        true ->
                            {ok, PlayerStatus, 2, 0};
                        _ ->
                            case Vip#status_vip.vip_type >= 0 andalso LeftTime >= 0 of
                                %会员传送
                                true ->
                                    Flag1 = is_forbidden_fly_to_scene_type(SceneId),
                                    Flag2 = is_forbidden_fly_from_scene_type(PlayerStatus#player_status.scene),
                                    Flag3 = is_forbidden_fly_scene_id(PlayerStatus#player_status.scene),
                                    case Flag1 =:= true orelse Flag2 =:= true orelse Flag3 =:= true of
                                        false ->
                                            lib_scene:leave_scene(PlayerStatus),
                                            %pp_scene:handle(12004, PlayerStatus, s),
                                            NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
                                            case lib_scene:get_data(SceneId) of
                                                S when is_record(S, ets_scene) ->
                                                    SceneName = S#ets_scene.name;
                                                _ ->
                                                    SceneName = <<>>
                                            end,
                                            {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, SceneName, NewPlayerStatus#player_status.scene]),
                                            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                            mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ?Vip_Flay_Type),
                                            {ok, NewPlayerStatus, 0, LeftTime-1};
                                        true ->
                                            {ok, PlayerStatus, 2, 0}
                                    end;
                                %使用小飞鞋
                                false ->
                                    Flag1 = is_forbidden_fly_to_scene_type(SceneId),
                                    Flag2 = is_forbidden_fly_from_scene_type(PlayerStatus#player_status.scene),
                                    Flag3 = is_forbidden_fly_scene_id(PlayerStatus#player_status.scene),
                                    case Flag1 =:= true orelse Flag2 =:= true orelse Flag3 =:= true of
                                        false ->
                                            Res_goods = use_shoes(PlayerStatus),
                                            case Res_goods of
                                                1 ->
                                                    lib_scene:leave_scene(PlayerStatus),
                                                    %pp_scene:handle(12004, PlayerStatus, s),
                                                    NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
                                                    case lib_scene:get_data(SceneId) of
                                                        S when is_record(S, ets_scene) ->
                                                            SceneName = S#ets_scene.name;
                                                        [] ->
                                                            SceneName = <<>>
                                                    end,
                                                    {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, 
                                                            NewPlayerStatus#player_status.x, 
                                                            NewPlayerStatus#player_status.y, 
                                                            SceneName, NewPlayerStatus#player_status.scene]),
                                                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                                    {ok, NewPlayerStatus, 0, 0};
                                                _ ->
                                                    {ok, PlayerStatus, 3, 0}
                                            end;
                                        _ ->
                                            {ok, PlayerStatus, 2, 0}
                                    end
                            end
                    end
            end
    end.

send_vip_bag(PlayerStatus, VipType, VipDays) ->
    RoleId = PlayerStatus#player_status.id,
    %case VipDays >= 180*24*3600 of
	case VipDays >= 7*24*3600 of
        true ->
            case save_vip_bag_flag(PlayerStatus, VipType) of
                {true , NewState} ->
                    [Content, GoodsID, GoodsNum, Title] = case VipType of
                        1 ->
                            [_Title, _Content] = data_sell_text:vip_text(2),
                            _GoodsID = 532502 ,
                            _GoodsNum = 1,
                            [_Content, _GoodsID, _GoodsNum, _Title];
                        2 ->
                            [_Title, _Content] = data_sell_text:vip_text(3),
                            _GoodsID = 532503 ,
                            _GoodsNum = 1,
                            [_Content, _GoodsID, _GoodsNum, _Title];
                        3 ->
                            [_Title, _Content] = data_sell_text:vip_text(4),
                            _GoodsID = 532504 ,
                            _GoodsNum = 1,
                            [_Content, _GoodsID, _GoodsNum, _Title];
                        4 ->
                            [_Title, _Content] = data_sell_text:vip_text(2),
                            _GoodsID = 532502 ,
                            _GoodsNum = 1,
                            [_Content, _GoodsID, _GoodsNum, _Title]
                    end,
                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[RoleId], Title, Content, GoodsID, 2, 0, 0, GoodsNum, 0, 0, 0, 0]),
                    NewState;
               _ ->
                   PlayerStatus
            end;
        _ ->
            PlayerStatus
     end.

save_vip_bag_flag(State, VipType) ->
    Vip = State#player_status.vip,
    case is_list(Vip#status_vip.vip_bag_flag) of
        true ->
            case lists:member(VipType, Vip#status_vip.vip_bag_flag) of
                false ->
                    NewState = State#player_status{vip=Vip#status_vip{vip_bag_flag = Vip#status_vip.vip_bag_flag ++ [VipType]}},
                    V = NewState#player_status.vip,
                    Sql = io_lib:format(?SQL_UPDATE_VIP2, 
                        [binary_to_list(list_to_binary(io_lib:format("~w", [V#status_vip.vip_bag_flag]))), NewState#player_status.id]),
                    db:execute(Sql),
                    {true , NewState};
                _ ->
                    false
            end;
        false ->
            false
    end.


% ----------------------
%  vip权利扩展
% -----------------------

% -------------------------------------------------
% 错误码：1领取成功 2你不是vip无法领取 3你今天已经领取 4背包空间不足
% -------------------------------------------------
get_vip_reward(PlayerStatus, Type) ->
    DailyType = case Type of
        %绑定元宝
        1 ->
            1301;
        %绑定铜钱
        2 ->
            1302;
        %物品
        3 ->
            1303;
        %buff
        _ ->
            1304
    end,
    case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, DailyType) =:= 0 of
        true ->
            case Type of
                %绑定元宝
                1 ->
                    draw_gold(PlayerStatus);
                %绑定铜钱
                2 ->
                    draw_coin(PlayerStatus);
                %物品
                3 ->
                    draw_goods(PlayerStatus);
                %buff
                _ ->
                    draw_buff(PlayerStatus)
           end;
        _ ->
            {3, PlayerStatus}
    end.

%领取绑定元宝 1301
draw_gold(_PlayerState) ->
    Vip = _PlayerState#player_status.vip,
    case Vip#status_vip.vip_type > 0 of
        true ->
            Amount = date_bingold(Vip#status_vip.vip_type),
            NewPlayerStatus = lib_goods_util:add_money(_PlayerState, Amount, bgold),
			log:log_produce(vip, bgold, _PlayerState, NewPlayerStatus, "vip bgold"),
%%             lib_practice:replace_money(NewPlayerStatus),
            mod_daily:set_count(_PlayerState#player_status.dailypid, _PlayerState#player_status.id, 1301, 1),
            lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
            send_reward_msg(_PlayerState#player_status.sid, 1, Amount, 0),
            {1, NewPlayerStatus};
        _ ->
            {2, _PlayerState}
    end.

%领取绑定铜币 1302
draw_coin(_PlayerState) ->
    Vip = _PlayerState#player_status.vip,
    case Vip#status_vip.vip_type > 0 of
        true ->
            Amount = date_bincoin(Vip#status_vip.vip_type),
            NewPlayerStatus = lib_goods_util:add_money(_PlayerState, Amount, coin),
			log:log_produce(vip, coin, _PlayerState, NewPlayerStatus, "vip coin"),
%%             lib_practice:replace_money(NewPlayerStatus),
            mod_daily:set_count(_PlayerState#player_status.dailypid, _PlayerState#player_status.id, 1302, 1),
            lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
            send_reward_msg(_PlayerState#player_status.sid, 2, Amount, 0),
            {1, NewPlayerStatus};
        _ ->
            {2, _PlayerState}
    end.

%领取物品 1303
draw_goods(_PlayerState) ->
    Vip = _PlayerState#player_status.vip,
    Go = _PlayerState#player_status.goods,
    case Vip#status_vip.vip_type > 0 of
        true ->
            GiveList = date_goods(Vip#status_vip.vip_type),
%%             LilianNum = data_vip_new:get_daily_lilian(Vip#status_vip.growth_lv) + 1,
%%             ExpNum = data_vip_new:get_daily_exp(Vip#status_vip.growth_lv) + 1,
            %% GiveList = [{221203, LilianNum}, {221003, ExpNum}],
            [{LilianId, LilianNum}, {ExpId, ExpNum}] = GiveList,
            case gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', _PlayerState, GiveList}, 3000) of
                ok ->
                    log:log_goods(vip, 1, LilianId, LilianNum, _PlayerState#player_status.id),
                    log:log_goods(vip, 1, ExpId, ExpNum, _PlayerState#player_status.id),
                    mod_daily:set_count(_PlayerState#player_status.dailypid, _PlayerState#player_status.id, 1303, 1),
                    send_reward_msg(_PlayerState#player_status.sid, 3, 0, GiveList),
                    {1, _PlayerState};
                _ ->   
                    Title = data_vip_text:get_vip_text(11),
                    Content = data_vip_text:get_vip_text(12),
                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[_PlayerState#player_status.id], Title, Content, LilianId, 2, 0, 0, LilianNum, 0, 0, 0, 0]),
                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[_PlayerState#player_status.id], Title, Content, ExpId, 2, 0, 0, ExpNum, 0, 0, 0, 0]),
                    {4, _PlayerState}
            end;
        _ ->
            {2, _PlayerState}
    end.

%领取buff 1304
draw_buff(_PlayerState) ->
    Vip = _PlayerState#player_status.vip,
    case Vip#status_vip.vip_type > 0 of
        true ->
            BuffType = date_attr(Vip#status_vip.vip_type),
            gen_server:cast(_PlayerState#player_status.pid, {'vipbuff', BuffType}),
            mod_daily:set_count(_PlayerState#player_status.dailypid, _PlayerState#player_status.id, 1304, 1),
            send_reward_msg(_PlayerState#player_status.sid, 4, 0, 0),
            {1, _PlayerState};
        _ ->
            {2, _PlayerState}
    end.

% -----------------------
%  vip扩展权利配置
% -----------------------
%%每天上线即可领取绑定元宝--1301
date_bingold(Type) ->
    case Type of
        1 ->
            10;
        2 ->
            20;
        3 ->
            30;
        4 ->
            10;
        _ ->
            0
    end.

%%每天上线即可领取绑定铜币--1302
date_bincoin(Type) ->
    case Type of
        1 ->
            3000;
        2 ->
            6000;
        3 ->
            10000;
        4 ->
            3000;
        _ ->
            0
    end.

%%每天上线即可领取道具------1303
%%历练在前，经验物品在后
date_goods(Type) ->
    case Type of
%%        1 ->
%%            [{532505, 1}];
%%        2 ->
%%            [{532506, 1}];
%%        3 ->
%%            [{532507, 1}];
%%        4 ->
%%            [{532505, 1}];
        1 ->
            [{111041, 1}, {205101, 1}];
        2 ->
            [{111041, 2}, {205101, 1}];
        3 ->
            [{111041, 3}, {205101, 1}];
        _ ->
            [{111041, 1}, {205101, 1}]
    end.

%%每天上线即可领取全属性----1304
date_attr(Type) ->
    case Type of
        1 ->
            214501;
        2 ->
            214502;
        3 ->
            214503;
        4 ->
            214501;
        _ ->
            0
    end.

%%属性时间
attr_time(Type) ->
    case Type of
        1 ->
            1 * 60 * 60;
        2 ->
            2 * 60 * 60;
        3 -> 
            3 * 60 * 60;
        4 ->
            1 * 60 * 60;
        _ ->
            0
    end.

data_water_time(Type) ->
    case Type of
        1 ->
            6;
        2 ->
            7;
        3 ->
            8;
        4 ->
            6;
        _ ->
            5
    end.

%发送领取奖励提示
send_reward_msg(Sid, Type, Num, GoodsId) ->
    Msg = case Type of
        1 ->
            Text1 = data_sell_text:vip_text(5),
            io_lib:format(Text1, [Num]);
        2 ->
            Text1 = data_sell_text:vip_text(6),
            io_lib:format(Text1, [Num]);
        3 ->
            case GoodsId of
                [{532505, 1}] ->
                    data_sell_text:vip_text(7);
                [{532506, 1}] ->
                    data_sell_text:vip_text(8);
                [{532507, 1}] ->
                    data_sell_text:vip_text(9);
                _ ->
                    ""
            end;
        4 ->
            Text1 = data_sell_text:vip_text(5),
            io_lib:format(Text1, [Num]);
        _ ->
            data_sell_text:vip_text(10)
    end,
    case Num > 0 andalso Msg =/= "" of
        true ->
            lib_chat:send_sys_msg_one(Sid, Msg);
        false ->
            skip
    end,
    ok.

%% 购买vip升级卡(卡为绑定)
%% VipType：会员类型（0非会员、1黄金会员、2白金会员、3紫金会员)、Days：会员时间（天）
%%update_vip(PlayerStatus) ->
%%	Vip = PlayerStatus#player_status.vip,
%%	VipType = Vip#status_vip.vip_type,
%%	case VipType of
%%		1 -> 
%%			Gold = PlayerStatus#player_status.gold,
%%			CostGold = 300,
%%			case Gold >= CostGold of
%%				false -> {2, PlayerStatus};
%%				true ->
%%					%% 扣元宝
%%					lib_goods_util:cost_money(PlayerStatus, CostGold, gold),
%%					PlayerStatus1 = PlayerStatus#player_status{gold = Gold - CostGold},
%%					lib_player:send_attribute_change_notify(PlayerStatus1, 2),
%%					%% 发物品
%%
%%					{1, PlayerStatus1}
%%			end;
%%		2 -> 
%%			Gold = PlayerStatus#player_status.gold,
%%			CostGold = 500,
%%			case Gold >= CostGold of
%%				false -> {2, PlayerStatus};
%%				true ->
%%					%% 扣元宝
%%					lib_goods_util:cost_money(PlayerStatus, CostGold, gold),
%%					PlayerStatus1 = PlayerStatus#player_status{gold = Gold - CostGold},
%%					lib_player:send_attribute_change_notify(PlayerStatus1, 2),
%%					%% 发物品
%%
%%					{1, PlayerStatus1}
%%			end;
%%		_ -> {0, PlayerStatus}
%%	end.

%% 祝福冻结
freeze(PlayerStatus) ->
	%% 先判断是否已领取祝福
	case mod_vip:lookup_pid(PlayerStatus#player_status.id) of
		undefined ->
			{0, PlayerStatus};
		EtsVipBuff ->
			Buff = EtsVipBuff#ets_vip_buff.buff,
			%% 修改剩余时间和冻结状态
			Now = util:unixtime(),
			CrossTime = Buff#ets_buff.end_time - Now,
			mod_vip:insert_buff(EtsVipBuff#ets_vip_buff{rest_time = CrossTime, state = 2}),
			%% 删除buff，使之过期
			buff_dict:insert_buff(Buff#ets_buff{end_time = Now}),
			%% 发送过期buff
			lib_player:send_buff_notice(PlayerStatus, [Buff#ets_buff{end_time = Now}]),
			{_Error, _NewPlayerStatus} = lib_player:del_player_buff(PlayerStatus, Buff#ets_buff.id),
            mod_scene_agent:update(battle_attr, _NewPlayerStatus),
            PlayerBuff = _NewPlayerStatus#player_status.player_buff,
            NewPlayerBuff = lib_buff:del_buff_by_id(PlayerBuff, Buff#ets_buff.id, PlayerBuff),
			NewPlayerStatus = _NewPlayerStatus#player_status{
                player_buff = NewPlayerBuff
            },
			{1, NewPlayerStatus}
	end.

%% 祝福解冻
unfreeze(PlayerStatus) ->
	%% 先判断是否已领取祝福
	case mod_vip:lookup_pid(PlayerStatus#player_status.id) of
		undefined ->
			{0, PlayerStatus};
		EtsVipBuff ->
			RestTime = EtsVipBuff#ets_vip_buff.rest_time,
			Now = util:unixtime(),
			EndTime = Now + RestTime,
			%% 增加buff
			Vip = PlayerStatus#player_status.vip,
			BuffType = date_attr(Vip#status_vip.vip_type),
			case data_goods_effect:get_val(BuffType, buff) of
        		[] ->
        			{0, PlayerStatus};
    		    {Type, AttributeId, Value, _Time, SceneLimit} ->
					%% 解冻重新计算buff时间
                    NewBuffInfo = case lib_buff:match_three(PlayerStatus#player_status.player_buff, Type, AttributeId, []) of
     		      	%NewBuffInfo = case lib_player:get_player_buff(PlayerStatus#player_status.id, Type, AttributeId) of
        		 	 	[] -> lib_player:add_player_buff(PlayerStatus#player_status.id, Type, BuffType, AttributeId, Value, EndTime, SceneLimit);
        		  		[BuffInfo] -> lib_player:mod_buff(BuffInfo, BuffType, Value, EndTime, SceneLimit)
          		 	end,
					%% 修改解冻状态
					NewBuffInfo1 = NewBuffInfo#ets_buff{id = EtsVipBuff#ets_vip_buff.buff#ets_buff.id},
					mod_vip:insert_buff(EtsVipBuff#ets_vip_buff{buff = NewBuffInfo1, state = 1}),
					buff_dict:insert_buff(NewBuffInfo1),
          		  	lib_player:send_buff_notice(PlayerStatus, [NewBuffInfo1]),
            		BuffAttribute = lib_player:get_buff_attribute(PlayerStatus#player_status.id, PlayerStatus#player_status.scene),
            		_NewPlayerStatus = lib_player:count_player_attribute(PlayerStatus#player_status{buff_attribute = BuffAttribute}),
                    NewPlayerStatus = _NewPlayerStatus#player_status{
                        player_buff = [NewBuffInfo1 | _NewPlayerStatus#player_status.player_buff]
                    },
                    mod_scene_agent:update(battle_attr, NewPlayerStatus),
            		lib_player:send_attribute_change_notify(NewPlayerStatus, 0),
                    case RestTime > 0 of
                        true -> {RestTime, NewPlayerStatus};
                        false -> {0, NewPlayerStatus}
                    end
			end
	end.

%% 进入VIP挂机场景
goin_room(PlayerStatus) ->
	Vip = PlayerStatus#player_status.vip,
	VipType = Vip#status_vip.vip_type,
	case VipType > 0 of
		true -> 
			mod_exit:insert_last_xy(PlayerStatus#player_status.id, PlayerStatus#player_status.scene, PlayerStatus#player_status.x, PlayerStatus#player_status.y),
            %% 低级、中级和高级挂机场景
            case PlayerStatus#player_status.lv >= 60 of
                true-> 
                    case PlayerStatus#player_status.lv >= 70 of
                        true ->
                            SceneId = data_vip_new:get_config(scene_id3),
                            XY = data_vip_new:get_config(xy3),
                            {X, Y} = lists:nth(data_vip_new:get_place_from_lv3(PlayerStatus#player_status.lv), XY);
                        false ->
                            SceneId = data_vip_new:get_config(scene_id2),
                            XY = data_vip_new:get_config(xy2),
                            {X, Y} = lists:nth(data_vip_new:get_place_from_lv2(PlayerStatus#player_status.lv), XY)
                    end;
                false ->
                    SceneId = data_vip_new:get_config(scene_id),
                    XY = data_vip_new:get_config(xy),
                    {X, Y} = lists:nth(data_vip_new:get_place_from_lv(PlayerStatus#player_status.lv), XY)
            end,
			lib_scene:change_scene_queue(PlayerStatus,SceneId,0,X,Y,0),
			1;
		false -> 0
	end.

%% 退出VIP挂机场景
out_room(PlayerStatus) ->
    %% 低级和中级挂机场景
	VIPSceneId1 = data_vip_new:get_config(scene_id),
    VIPSceneId2 = data_vip_new:get_config(scene_id2),
    VIPSceneId3 = data_vip_new:get_config(scene_id3),
	case VIPSceneId1 =:= PlayerStatus#player_status.scene orelse VIPSceneId2 =:= PlayerStatus#player_status.scene orelse VIPSceneId3 =:= PlayerStatus#player_status.scene of
		true ->
%%			%% 判断是否有用户之前场景、坐标的信息
%%			%% 没有则进入默认出口
%%			case mod_exit:lookup_last_xy(PlayerStatus#player_status.id) of
%%                [_SceneId, _X, _Y] -> 
%%                    %%判断，如果不是普通场景和野外场景，则返回长安主城
%%                    case lib_scene:get_data(_SceneId) of
%%                        [] ->
%%                            SceneType = 8;
%%                        _S ->
%%                            SceneType = _S#ets_scene.type
%%                    end,
%%                    case SceneType =:= ?SCENE_TYPE_NORMAL orelse SceneType =:= ?SCENE_TYPE_OUTSIDE of
%%                        true ->
%%                            [SceneId, X, Y] = [_SceneId, _X, _Y];
%%                        false ->
%%                            [SceneId, X, Y] = data_vip_new:get_config(leave)
%%                    end;
%%				_ -> 
%%					[SceneId,X,Y] = data_vip_new:get_config(leave)
%%			end,
            [SceneId,X,Y] = data_vip_new:get_config(leave),
			lib_scene:change_scene_queue(PlayerStatus,SceneId,0,X,Y,0);
		false -> skip
	end,
	1.

%% 退出时踢出VIP挂机场景
login_out(_PlayerStatus) ->
    data_vip_new:get_config(leave).
%%	case mod_exit:lookup_last_xy(PlayerStatus#player_status.id) of
%%		[SceneId, X, Y] -> 
%%            %%判断，如果不是普通场景和野外场景，则返回长安主城
%%            case lib_scene:get_data(SceneId) of
%%                [] ->
%%                    SceneType = 8;
%%                _S ->
%%                    SceneType = _S#ets_scene.type
%%            end,
%%            SceneId = data_vip_new:get_config(scene_id),
%%            SceneId2 = data_vip_new:get_config(scene_id2),
%%            case SceneType =:= ?SCENE_TYPE_NORMAL orelse SceneType =:= ?SCENE_TYPE_OUTSIDE andalso PlayerStatus#player_status.scene =/= SceneId andalso PlayerStatus#player_status.scene =/= SceneId2 of
%%                true ->
%%                    [SceneId, X, Y];
%%                false -> data_vip_new:get_config(leave)
%%            end;
%%		_ -> 
%%			data_vip_new:get_config(leave)
%%	end.

%% 登录时踢出VIP挂机场景
%%@param PlayerStatus 玩家状态
%%@return NewPlayerStatus
login_in_vip(PlayerStates) ->
	VIPSceneId = data_vip_new:get_config(scene_id),
    VIPSceneId2 = data_vip_new:get_config(scene_id2),
    VIPSceneId3 = data_vip_new:get_config(scene_id3),
%%	case mod_exit:lookup_last_xy(PlayerStates#player_status.id) of
%%		[_SceneId, _X, _Y] -> 
%%            %%判断，如果不是普通场景和野外场景，则返回长安主城
%%            case lib_scene:get_data(_SceneId) of
%%                [] ->
%%                    SceneType = 8;
%%                _S ->
%%                    SceneType = _S#ets_scene.type
%%            end,
%%            case SceneType =:= ?SCENE_TYPE_NORMAL orelse SceneType =:= ?SCENE_TYPE_OUTSIDE andalso PlayerStates#player_status.scene =/= VIPSceneId andalso PlayerStates#player_status.scene =/= VIPSceneId2 of
%%                true ->
%%                    [SceneId, X, Y] = [_SceneId, _X, _Y];
%%                false -> 
%%                    [SceneId, X, Y] = data_vip_new:get_config(leave)
%%            end;
%%		_ -> [SceneId, X, Y] = data_vip_new:get_config(leave)
%%	end,
    [SceneId, X, Y] = data_vip_new:get_config(leave),
	if
		PlayerStates#player_status.scene =:= VIPSceneId orelse PlayerStates#player_status.scene =:= VIPSceneId2 orelse PlayerStates#player_status.scene =:= VIPSceneId3 ->
			NewPlayerStates = PlayerStates#player_status{
														 scene = SceneId,                          % 场景id
													     copy_id = 0,                        % 副本id 
													     y = X,
													     x = Y
														 },
			NewPlayerStates;
		true-> PlayerStates
	end.

%% 禁止飞去的场景类型
is_forbidden_fly_to_scene_type(SceneId) ->
	case lib_scene:is_transferable(SceneId) of
		true -> false;
		false -> true
	end.

%% 禁止使用小飞鞋的场景类型
is_forbidden_fly_from_scene_type(SceneId) ->
    List = data_vip_new:get_config(forbidden_fly_scene_type),
    %获取要传送地图场景数据.
    PresentScene = case data_scene:get(SceneId) of
        [] -> 
            #ets_scene{};
        SceneData ->
            SceneData
    end,
    lists:member(PresentScene#ets_scene.type, List).

%% 禁飞的场景ID
is_forbidden_fly_scene_id(SceneId) ->
	List = data_vip_new:get_config(forbidden_fly_scene_id),
	lists:member(SceneId, List).

send_week_vip_gift(PlayerStatus) ->
    %% 开服前七天发送
    case util:check_open_day(7) of
        true ->
            %% 判断今天是否已领取
            case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 10007) =:= 0 of
                true ->
                    Vip = PlayerStatus#player_status.vip,
                    case Vip#status_vip.vip_type >= 1 andalso Vip#status_vip.vip_end_time - util:unixtime() >= 30 * 60 of
                        true -> 
                            GiftId = lists:nth(Vip#status_vip.vip_type, data_vip_new:get_config(week_vip_gift)),
                            Title = lists:nth(Vip#status_vip.vip_type, data_vip_text:get_vip_text(0)),
                            Detail = lists:nth(Vip#status_vip.vip_type, data_vip_text:get_vip_text(1)),
                            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PlayerStatus#player_status.id], Title, Detail, GiftId, 2, 0, 0, 1, 0, 0, 0, 0]),
                            mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 10007);
                        false -> skip
                    end;
                false -> skip
            end;
        false ->
            skip
    end.

%% BOSS场景特殊处理
boss_scene_deal(_SceneId) ->
    case _SceneId of
        403 -> 407;
        408 -> 407;
        409 -> 407;
        404 -> 400;
        405 -> 400;
        406 -> 400;
        402 -> 412;
        410 -> 412;
        411 -> 412;
        413 -> 414;
        _ -> _SceneId
    end.

%% VIP升级(成为VIP、续费)
new_up_vip(PlayerStatus, Type, NeedGold) ->
    Vip = PlayerStatus#player_status.vip,
    _NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, NeedGold, gold),
    %% 日志
    GoodsId = case Type of
        1 -> 631001;
        2 -> 631101;
        _ -> 631201
    end,
    log:log_consume(pay_vip_upgrade, gold, PlayerStatus, _NewPlayerStatus, GoodsId, 1, ["pay_vip_upgrade"]),
    Sec = data_vip_new:get_vip_time(Type),
    EndTime = case Vip#status_vip.vip_end_time >= util:unixtime() of
        true ->
            Vip#status_vip.vip_end_time + Sec;
        false ->
            util:unixtime() + Sec
    end,
    NewPlayerStatus = _NewPlayerStatus#player_status{
        vip = Vip#status_vip{
            vip_type = Type, 
            vip_end_time = EndTime
        }
    },
    %% Vip等级同步到公共线
    lib_player:update_unite_info(NewPlayerStatus#player_status.unite_pid, [{vip, Type}]),
    %play_low表插入数据
    Sql1 = io_lib:format(?SQL_UPDATE_VIP, [Type, EndTime, PlayerStatus#player_status.id]),
    db:execute(Sql1),
	%%add by xieyunfei vip改变改动时候重新计算体力值
	lib_physical:vip_change(PlayerStatus,Type),
    %lib_player:send_attribute_change_notify(NewPlayerStatus, 2),
    %VIP广播
    {ok, Bin} = pt_122:write(12203, [PlayerStatus#player_status.id, PlayerStatus#player_status.platform, PlayerStatus#player_status.server_num, Type]),
    lib_server_send:send_to_scene(PlayerStatus#player_status.scene, PlayerStatus#player_status.copy_id, Bin),
    %世界传闻 格式:"vip" + viptype + id + name + sex + career + image + realm
    lib_chat:send_TV({all},0,1, ["vip",
            Type,
            PlayerStatus#player_status.id, 
            PlayerStatus#player_status.nickname, 
            PlayerStatus#player_status.sex, 
            PlayerStatus#player_status.career, 
            PlayerStatus#player_status.image, 
            PlayerStatus#player_status.realm]),
    mod_disperse:cast_to_unite(lib_guild, change_vip, [PlayerStatus#player_status.id, Type]),
    %%新服vip礼包奖励
    NewPlayerStatus1 = send_vip_bag(NewPlayerStatus, Type, Sec),
    V = NewPlayerStatus1#player_status.vip,
    LeftTime = V#status_vip.vip_end_time - util:unixtime(),
    {ok, BinData} = pt_450:write(45003, [LeftTime]),
    lib_server_send:send_one(NewPlayerStatus1#player_status.socket, BinData),
    pp_vip:handle(45007, NewPlayerStatus1, 0),
    %% 是否可领取开服7天礼包
    pp_vip:handle(45014, NewPlayerStatus1, no),
    NewPlayerStatus1.

%% 公共线调用
%% 输入角色名，获得角色Id,
get_role_id(PlayerInfo) when is_list(PlayerInfo) ->
	case mod_chat_agent:match(match_name, [util:make_sure_list(PlayerInfo)]) of
        [] ->
            case lib_player:get_role_id_by_name(PlayerInfo) of
                null ->
                    0;
                PlayerId ->
                    PlayerId
            end;
        [Player] ->
            Player#ets_unite.id
    end.

combine_list([], [], L) -> lists:reverse(L);
combine_list([H1 | T1], [H2 | T2], L) ->
    combine_list(T1, T2, [{H1, H2} | L]).

%% VIP摇奖随机取得
rand_award(GoodsList) ->
    AllPro = count_all_pro(GoodsList, 0),
    %io:format("GoodsList:~p~n", [GoodsList]),
    %io:format("AllPro:~p~n", [AllPro]),
    RandNum = util:rand(1, AllPro),
    %io:format("RandNum:~p~n", [RandNum]),
    {GoodsId, GoodsNum, GoodsPro, Type} = get_rand_num(GoodsList, RandNum),
    %io:format("GoodsId:~p~n", [GoodsId]),
    {GoodsId, GoodsNum, GoodsPro, Type}.

count_all_pro([], Count) -> Count;
count_all_pro([H | T], Count) ->
    case H of
        {_GoodsId, _GoodsNum, GoodsPro, _Type} ->
            count_all_pro(T, Count + GoodsPro);
        _ ->
            count_all_pro(T, Count)
    end.

get_rand_num([], _RandNum) -> {0, 0};
get_rand_num([H | T], RandNum) ->
    case H of
        {GoodsId, GoodsNum, GoodsPro, Type} ->
            case GoodsPro >= RandNum of
                true -> 
                    {GoodsId, GoodsNum, GoodsPro, Type};
                false -> 
                    get_rand_num(T, RandNum - GoodsPro)
            end;
        _ ->
            get_rand_num(T, RandNum)
    end.

%% 是否有抢价物品
check_limit_shop(_PlayerStatus, _Type, [], NeedGold) -> NeedGold;
check_limit_shop(PlayerStatus, Type, [H | T], NeedGold) ->
    case is_record(H, ets_limit_shop) of
        true ->
            case Type of
                1 -> 
                    case lists:member(H#ets_limit_shop.goods_id, [631001]) of
                        true ->
                            ShopInfo = H,
                            Num = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ShopInfo#ets_limit_shop.limit_id),
                            {LimitNum, BuyType} = lib_shop:get_limit_pay_record_and_type(PlayerStatus#player_status.id, ShopInfo#ets_limit_shop.shop_id),
                            if  %% 超过限购数量
                                ShopInfo#ets_limit_shop.time_end > 0 andalso BuyType =:= 0 andalso LimitNum =/= 0 andalso ShopInfo#ets_limit_shop.list_id =/= LimitNum + 1 ->
                                    NeedGold;
                                %% 每天只可以购买一次
                                Num >= ShopInfo#ets_limit_shop.limit_num andalso ShopInfo#ets_limit_shop.time_end =< 0 andalso ShopInfo#ets_limit_shop.merge_end =< 0 ->
                                    NeedGold;
                                true ->
                                    case PlayerStatus#player_status.gold >= H#ets_limit_shop.new_price of
                                        true ->
                                            lib_shop:update_limit_shop_counter(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, H);
                                        false ->
                                            skip
                                    end,
                                    H#ets_limit_shop.new_price
                            end;
                        false ->
                            check_limit_shop(PlayerStatus, Type, T, NeedGold)
                    end;
                2 -> 
                    case lists:member(H#ets_limit_shop.goods_id, [631101, 631102]) of
                        true ->
                            ShopInfo = H,
                            Num = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ShopInfo#ets_limit_shop.limit_id),
                            {LimitNum, BuyType} = lib_shop:get_limit_pay_record_and_type(PlayerStatus#player_status.id, ShopInfo#ets_limit_shop.shop_id),
                            if  %% 超过限购数量
                                ShopInfo#ets_limit_shop.time_end > 0 andalso BuyType =:= 0 andalso LimitNum =/= 0 andalso ShopInfo#ets_limit_shop.list_id =/= LimitNum + 1 ->
                                    NeedGold;
                                %% 每天只可以购买一次
                                Num >= ShopInfo#ets_limit_shop.limit_num andalso ShopInfo#ets_limit_shop.time_end =< 0 andalso ShopInfo#ets_limit_shop.merge_end =< 0 ->
                                    NeedGold;
                                true ->
                                    case PlayerStatus#player_status.gold >= H#ets_limit_shop.new_price of
                                        true ->
                                            lib_shop:update_limit_shop_counter(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, H);
                                        false ->
                                            skip
                                    end,
                                    H#ets_limit_shop.new_price
                            end;
                        false ->
                            check_limit_shop(PlayerStatus, Type, T, NeedGold)
                    end;
                _ -> 
                    case lists:member(H#ets_limit_shop.goods_id, [631201, 631202]) of
                        true ->
                            ShopInfo = H,
                            Num = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ShopInfo#ets_limit_shop.limit_id),
                            {LimitNum, BuyType} = lib_shop:get_limit_pay_record_and_type(PlayerStatus#player_status.id, ShopInfo#ets_limit_shop.shop_id),
                            if  %% 超过限购数量
                                ShopInfo#ets_limit_shop.time_end > 0 andalso BuyType =:= 0 andalso LimitNum =/= 0 andalso ShopInfo#ets_limit_shop.list_id =/= LimitNum + 1 ->
                                    NeedGold;
                                %% 每天只可以购买一次
                                Num >= ShopInfo#ets_limit_shop.limit_num andalso ShopInfo#ets_limit_shop.time_end =< 0 andalso ShopInfo#ets_limit_shop.merge_end =< 0 ->
                                    NeedGold;
                                true ->
                                    case PlayerStatus#player_status.gold >= H#ets_limit_shop.new_price of
                                        true ->
                                            lib_shop:update_limit_shop_counter(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, H);
                                        false ->
                                            skip
                                    end,
                                    H#ets_limit_shop.new_price
                            end;
                        false ->
                            check_limit_shop(PlayerStatus, Type, T, NeedGold)
                    end
            end;
        false ->
            check_limit_shop(PlayerStatus, Type, T, NeedGold)
    end.

%% 随机奖励列表
get_rand_award_list(PlayerStatus) ->
    %% 原始数据列表
    GreenAwardList = data_vip_new:get_green_list(),
    BlueAwardList = data_vip_new:get_blue_list(),
    PurpleAwardList = data_vip_new:get_purple_list(),
    OrangeAwardList = data_vip_new:get_orange_list(),
    %% 等级筛选后的列表
    GreenAwardList2 = get_award_list_diff_lv(GreenAwardList, PlayerStatus#player_status.lv, [], 1),
    BlueAwardList2 = get_award_list_diff_lv(BlueAwardList, PlayerStatus#player_status.lv, [], 2),
    PurpleAwardList2 = get_award_list_diff_lv(PurpleAwardList, PlayerStatus#player_status.lv, [], 3),
    OrangeAwardList2 = get_award_list_diff_lv(OrangeAwardList, PlayerStatus#player_status.lv, [], 4),
    %% 从列表中随机取出数个数量
    GreenAwardList3 = get_rand_award_list(3, GreenAwardList2, []),
    BlueAwardList3 = get_rand_award_list(4, BlueAwardList2, []),
    PurpleAwardList3 = get_rand_award_list(10, PurpleAwardList2, []),
    OrangeAwardList3 = get_rand_award_list(1, OrangeAwardList2, []),
    %List = GreenAwardList3 ++ BlueAwardList3 ++ PurpleAwardList3 ++ OrangeAwardList3,
    %List.
    List1 = rand_combine(GreenAwardList3, BlueAwardList3, []),
    List2 = rand_combine(List1, PurpleAwardList3, []),
    List3 = rand_combine(List2, OrangeAwardList3, []),
    List3.

get_award_list_diff_lv([], _PlayerLv, L, _Type) -> L;
get_award_list_diff_lv([H | T], PlayerLv, L, Type) ->
    case H of
        {GoodsId, GoodsNum, MinLv, MaxLv, GoodsPro} ->
            case PlayerLv >= MinLv andalso PlayerLv =< MaxLv of
                true ->
                    get_award_list_diff_lv(T, PlayerLv, [{GoodsId, GoodsNum, GoodsPro, Type} | L], Type);
                false ->
                    get_award_list_diff_lv(T, PlayerLv, L, Type)
            end;
        _ ->
            get_award_list_diff_lv(T, PlayerLv, L, Type)
    end.

get_rand_award_list(0, _List, L) -> L;
get_rand_award_list(_N, [], L) -> L;
get_rand_award_list(N, List, L) -> 
    Len = length(List),
    Rand = util:rand(1, Len),
    Chosen = lists:nth(Rand, List),
    NewList = lists:delete(Chosen, List),
    NewL = [Chosen | L],
    get_rand_award_list(N - 1, NewList, NewL).

rand_combine([], L2, L) -> 
    NewL = L ++ L2,
    NewL;
rand_combine(L1, [], L) ->
    NewL = L ++ L1,
    NewL;
rand_combine([H1 | T1], [H2 | T2], L) ->
    NewL = L ++ [H1, H2],
    rand_combine(T1, T2, NewL).

all_need_gold(NeedGold, MaxNum, AllGold) when NeedGold > MaxNum -> AllGold;
all_need_gold(NeedGold, MaxNum, AllGold) ->
    all_need_gold(NeedGold + 1, MaxNum, AllGold + NeedGold).

get_rand_awards([], _NeedCell, L) -> L;
get_rand_awards(_AllList, 0, L) -> L;
get_rand_awards(AllList, NeedCell, L) ->
    Info = rand_award(AllList),
    get_rand_awards(lists:delete(Info, AllList), NeedCell - 1, [Info | L]).

trans_send_list([], L) -> L;
trans_send_list([H | T], L) -> 
    case H of
        {GoodsId, GoodsNum, _GoodsPro, _Type} ->
            trans_send_list(T, [{GoodsId, GoodsNum} | L]);
        _ ->
            trans_send_list(T, L)
    end.

trans_goods_id_list([], L) -> L;
trans_goods_id_list([H | T], L) ->
    case H of
        {GoodsId, _GoodsNum, _GoodsPro, _Type} ->
            trans_goods_id_list(T, [{GoodsId, _GoodsNum} | L]);
        _ ->
            trans_goods_id_list(T, L)
    end.
