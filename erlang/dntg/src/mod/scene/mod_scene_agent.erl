%%%------------------------------------
%%% @Module  : mod_scene_agent
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.07.15
%%% @Description: 场景管理 
%%%------------------------------------
-module(mod_scene_agent). 
-behaviour(gen_server).
-export([
            start_link/1,
            get_scene_pid/1,
            send_to_scene/3,
            send_to_scene/2,
            send_to_area_scene/5,
            join/1,
            leave/1,
            move/4,
            update/2,
            start_mod_scene_agent/1,
            get_scene_num/1,
            send_scene_info_to_uid/5,
            close_scene/1,
            clear_scene/1,
            apply_call/4,
            apply_cast/4,
            do_battle/2,
            update_to_clusters/2,
            load_scene/1
        ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("mount.hrl").

%% 通过场景调用函数 - call
apply_call(Sid, Module, Method, Args) ->
    case get_scene_pid(Sid) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_call(?MODULE, apply_call, [Sid, Module, Method, Args]);
        Pid ->
            case catch gen:call(Pid, '$gen_call', {'apply_call', Module, Method, Args}) of
                {ok, Res} ->
                    Res;
                Reason ->
                    erase({get_scene_pid, Sid}),
                    util:errlog("ERROR mod_scene_agent apply_call/4 sid: ~p function: ~p Reason : ~p~n", [Sid, [Module, Method, Args], Reason]),
                    skip
            end
    end.

%% 通过场景调用函数 - cast
apply_cast(Sid, Module, Method, Args) ->
    case get_scene_pid(Sid) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, apply_cast, [Sid, Module, Method, Args]);
        Pid ->
            gen_server:cast(Pid, {'apply_cast', Module, Method, Args})
    end.

%% 给场景所有玩家发送信息
send_to_scene(Sid, CopyId, Bin) ->
    case get_scene_pid(Sid) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, send_to_scene, [Sid, CopyId, Bin]);
        Pid ->
            gen_server:cast(Pid, {'send_to_scene', CopyId, Bin})
    end.

%% 给场景所有玩家发送信息
send_to_scene(Sid, Bin) ->
    case get_scene_pid(Sid) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, send_to_scene, [Sid, Bin]);
        Pid ->
            gen_server:cast(Pid, {'send_to_scene', Bin})
    end.

%% 给场景九宫格玩家发送信息
send_to_area_scene(Sid, CopyId, X, Y, Bin) ->
    case get_scene_pid(Sid) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, send_to_area_scene, [Sid, CopyId, X, Y, Bin]);
        Pid ->
            gen_server:cast(Pid, {'send_to_area_scene', CopyId, X, Y, Bin})
    end.

%% 玩家加入场景
trans_join_data(PS) when is_record(PS, player_status)->
    Pet = PS#player_status.pet,
    Equip = PS#player_status.goods,
    Sit = PS#player_status.sit,
    Mount = PS#player_status.mount,
    Vip = PS#player_status.vip,
    PK = PS#player_status.pk,
    M = lib_mount:get_equip_mount(PS#player_status.id, Mount#status_mount.mount_dict),
    case M#ets_mount.status =:= 2 of
        true ->
            MountFigure = lib_mount2:get_new_figure(PS);
        false ->
            MountFigure = Mount#status_mount.mount_figure
    end,
    case data_scene:get(PS#player_status.scene) of
        [] ->
            Node    = none, 
            PkValue = PK#status_pk.pk_status;
        Scene ->
            case Scene#ets_scene.type of
                ?SCENE_TYPE_CLUSTERS -> %% 跨服场景
                    Node    = mod_disperse:get_clusters_node(), 
                    PkValue = PK#status_pk.pk_status;
                ?SCENE_TYPE_BOSS when PK#status_pk.pk_status /= 2, PK#status_pk.pk_status /= 3 -> %% boss场景pk模式容错
                    Node    = none, 
                    PkValue = 2;
                _ ->
                    Node    = none, 
                    PkValue = PK#status_pk.pk_status
            end
    end,

    SceneUserPet = #scene_user_pet{
        pet_figure = Pet#status_pet.pet_figure,                    
        pet_nimbus = Pet#status_pet.pet_nimbus,                    
        pet_name = Pet#status_pet.pet_name,                      
        pet_level = Pet#status_pet.pet_level,
        pet_quality = data_pet:get_quality(Pet#status_pet.pet_aptitude)
    },
    SceneUserSit = #scene_user_sit{
        sit_down = Sit#status_sit.sit_down,
        sit_role = Sit#status_sit.sit_role
    },
    Husong = PS#player_status.husong,
    Hs = #scene_user_husong{
        husong_lv = Husong#status_husong.husong_lv,
        husong_npc = Husong#status_husong.husong_npc,
        husong_pt = Husong#status_husong.husong_pt
    },
    Pk = #scene_user_pk{
        pk_status = PkValue,
        pk_value = PK#status_pk.pk_value
    },
    BA = make_battle_attr_record(PS),
    Peach = #scene_user_peach{
        peach_num = PS#player_status.peach_num					  
    },
    #ets_scene_user{
        id = PS#player_status.id,
        nickname = PS#player_status.nickname,
        sex = PS#player_status.sex,
        scene = PS#player_status.scene,
        copy_id = PS#player_status.copy_id,
        lv = PS#player_status.lv,
        guild_id = PS#player_status.guild#status_guild.guild_id,
        guild_name = PS#player_status.guild#status_guild.guild_name,
        guild_position = PS#player_status.guild#status_guild.guild_position,
        sid = PS#player_status.sid,
        pid = PS#player_status.pid,
        x = PS#player_status.x,
        y = PS#player_status.y,
        hp = PS#player_status.hp,
        hp_lim = PS#player_status.hp_lim,
        mp = PS#player_status.mp,
        mp_lim = PS#player_status.mp_lim,
        anger = PS#player_status.anger,
        anger_lim = PS#player_status.anger_lim,
        leader = PS#player_status.leader,
        pid_team = PS#player_status.pid_team,
        pet = SceneUserPet,
        sit = SceneUserSit,
        equip_current = Equip#status_goods.equip_current,
        fashion_weapon = Equip#status_goods.fashion_weapon,
        fashion_armor = Equip#status_goods.fashion_armor,
        fashion_accessory = Equip#status_goods.fashion_accessory,
        fashion_head = Equip#status_goods.fashion_head,
        fashion_tail = Equip#status_goods.fashion_tail,
        fashion_ring = Equip#status_goods.fashion_ring,
        hide_fashion_armor = Equip#status_goods.hide_fashion_armor,             % 是否隐藏衣服时装，1为隐藏
        hide_fashion_accessory = Equip#status_goods.hide_fashion_accessory,         % 是否隐藏饰品时装，1为隐藏
        hide_fashion_weapon = Equip#status_goods.hide_fashion_weapon,
        hide_head = Equip#status_goods.hide_head,                               % 是否隐藏头时装，1为隐藏
        hide_tail = Equip#status_goods.hide_tail,                               % 是否隐藏尾时装，1为隐藏
        hide_ring = Equip#status_goods.hide_ring,                               % 是否隐藏戒指时装，1为隐藏
        career = PS#player_status.career,
        realm = PS#player_status.realm,
        group = PS#player_status.group,
        design = PS#player_status.designation,
        fly_mount = Mount#status_mount.fly_mount,
        speed = PS#player_status.speed,
        mount_figure = MountFigure,
        vip_type = Vip#status_vip.vip_type,
        husong = Hs,
        factionwar_stone = PS#player_status.factionwar_stone,
        battle_attr = BA,
        pk = Pk,
        figure = PS#player_status.figure,
        suit_id = Equip#status_goods.suit_id,
        stren7_num = Equip#status_goods.stren7_num,
        parner_id = PS#player_status.parner_id,
        marriage_parner_id = PS#player_status.marriage#status_marriage.parner_id,
        marriage_register_time = PS#player_status.marriage#status_marriage.register_time,
        is_cruise = PS#player_status.marriage#status_marriage.is_cruise,
        peach = Peach,
        qiling = PS#player_status.qiling,
        guild_rela = PS#player_status.guild_rela,          %% 同盟帮派列表
        image = PS#player_status.image,
        fly = Mount#status_mount.fly,
        flyer = Mount#status_mount.flyer,
        visible = PS#player_status.visible,
        node = Node,
        platform = PS#player_status.platform,
        server_num = PS#player_status.server_num,
	    flyer_figure = PS#player_status.flyer_attr#status_flyer.figure,
	    flyer_sky_figure = PS#player_status.flyer_attr#status_flyer.sky_figure,
        kf_teamid = PS#player_status.kf_teamid,
        body_effect = Equip#status_goods.body_effect,
        feet_effect = Equip#status_goods.feet_effect
    }.

join(PS) ->
    EtsSceneUser = trans_join_data(PS),
    case get_scene_pid(EtsSceneUser#ets_scene_user.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [EtsSceneUser#ets_scene_user.scene, {'join', EtsSceneUser}]);
        Pid ->
            gen_server:cast(Pid, {'join', EtsSceneUser})
    end.

%% 12002加载场景
load_scene(PS) ->
    EtsSceneUser = trans_join_data(PS),
    case get_scene_pid(EtsSceneUser#ets_scene_user.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [EtsSceneUser#ets_scene_user.scene, {'load_scene', EtsSceneUser}]);
        Pid ->
            gen_server:cast(Pid, {'load_scene', EtsSceneUser})
    end.

do_battle(Scene, Data) ->
    case get_scene_pid(Scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, do_battle, [Scene, Data]);
        Pid ->
            gen_server:cast(Pid, {'update', Data})
    end.

%% 更新战斗属性信息
update(battle_attr, PS) when is_record(PS, player_status)->
    do_battle(PS#player_status.scene, {battle_attr, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
            PS#player_status.hp,
            PS#player_status.hp_lim,
            PS#player_status.mp,
            PS#player_status.mp_lim,
            PS#player_status.anger,
            make_battle_attr_record(PS)
        }
    );

%% 更新气血和内力
update(hp_mp, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene,{
                        'update',{hp_mp, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                            {
                                PS#player_status.hp,               
                                PS#player_status.mp                                   
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update',{hp_mp, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                        {
                            PS#player_status.hp,               
                            PS#player_status.mp                                   
                        }
                    }
                })
    end;

%% 组队信息
update(team, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene,{
                        'update',{team, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                            {
                                PS#player_status.leader,
                                PS#player_status.pid_team              
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update',{team, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                        {
                            PS#player_status.leader,
                            PS#player_status.pid_team              
                        }
                    }
                })
    end;

%% 战斗组队
update(group, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene,{
                        'update',{group, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                            {
                                PS#player_status.group              
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update',{group, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                        {
                            PS#player_status.group              
                        }
                    }
                })
    end;

%% 打坐双修
update(sit, PS) ->
    Sit = PS#player_status.sit,
    SceneUserSit = #scene_user_sit{ sit_down=Sit#status_sit.sit_down, sit_role=Sit#status_sit.sit_role},
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update',{sit, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                            {
                                SceneUserSit              
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update',{sit, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                        {
                            SceneUserSit              
                        }
                    }
                })
    end;

%% 使用物品
update(use_goods, PS) ->
    Vip = PS#player_status.vip,
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update',{use_goods, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                            {
                                Vip#status_vip.vip_type,
                                PS#player_status.hp,
                                PS#player_status.mp,
                                PS#player_status.hp_lim,
                                PS#player_status.mp_lim,
                                PS#player_status.sex             
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update',{use_goods, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                        {
                            Vip#status_vip.vip_type,
                            PS#player_status.hp,
                            PS#player_status.mp,
                            PS#player_status.hp_lim,
                            PS#player_status.mp_lim,
                            PS#player_status.sex             
                        }
                    }
                })
    end;


%% 装备
update(equip, PS) ->
    Goods = PS#player_status.goods,
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update',{equip, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                            {
                                Goods#status_goods.hide_fashion_armor,
                                Goods#status_goods.hide_fashion_accessory,
                                Goods#status_goods.equip_current,
                                Goods#status_goods.fashion_weapon,
                                Goods#status_goods.fashion_armor,
                                Goods#status_goods.fashion_accessory,
                                PS#player_status.hp,
                                PS#player_status.mp,
                                PS#player_status.hp_lim,
                                PS#player_status.mp_lim,
                                Goods#status_goods.suit_id, 
                                Goods#status_goods.stren7_num,
                                Goods#status_goods.hide_fashion_weapon,
                                Goods#status_goods.fashion_head,
                                Goods#status_goods.fashion_tail,
                                Goods#status_goods.fashion_ring,
                                Goods#status_goods.hide_head,
                                Goods#status_goods.hide_tail,
                                Goods#status_goods.hide_ring,
                                Goods#status_goods.body_effect,
                                Goods#status_goods.feet_effect
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update',{equip, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                        {
                            Goods#status_goods.hide_fashion_armor,
                            Goods#status_goods.hide_fashion_accessory,
                            Goods#status_goods.equip_current,
                            Goods#status_goods.fashion_weapon,
                            Goods#status_goods.fashion_armor,
                            Goods#status_goods.fashion_accessory,
                            PS#player_status.hp,
                            PS#player_status.mp,
                            PS#player_status.hp_lim,
                            PS#player_status.mp_lim,
                            Goods#status_goods.suit_id, 
                            Goods#status_goods.stren7_num,
                            Goods#status_goods.hide_fashion_weapon,
                            Goods#status_goods.fashion_head,
                            Goods#status_goods.fashion_tail,
                            Goods#status_goods.fashion_ring,
                            Goods#status_goods.hide_head,
                            Goods#status_goods.hide_tail,
                            Goods#status_goods.hide_ring,
                            Goods#status_goods.body_effect,
                            Goods#status_goods.feet_effect
                        }
                    }
                })
    end;

%% 坐骑
update(mount, PS) ->
    Mount = PS#player_status.mount,
    EtsMount = lib_mount:get_equip_mount(PS#player_status.id, Mount#status_mount.mount_dict),
    Figure = case EtsMount#ets_mount.status == 0 orelse EtsMount#ets_mount.status == 1 of
        true -> 0;
        false -> lib_mount2:get_new_figure(PS)
    end,
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update',{mount, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                            {
                                Figure,
                                Mount#status_mount.fly,
                                Mount#status_mount.flyer,
                                PS#player_status.hp,
                                PS#player_status.mp,
                                PS#player_status.hp_lim,
                                PS#player_status.mp_lim            
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update',{mount, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], 
                        {
                            Figure,
                            Mount#status_mount.fly,
                            Mount#status_mount.flyer,
                            PS#player_status.hp,
                            PS#player_status.mp,
                            PS#player_status.hp_lim,
                            PS#player_status.mp_lim            
                        }
                    }
                })
    end;

%% 护送
update(husong, PS) ->
    Hs = PS#player_status.husong,
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {husong, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                Hs#status_husong.husong_lv,
                                Hs#status_husong.husong_npc,
                                Hs#status_husong.husong_pt,
                                PS#player_status.hp,
                                PS#player_status.hp_lim,
                                PS#player_status.speed
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {husong, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            Hs#status_husong.husong_lv,
                            Hs#status_husong.husong_npc,
                            Hs#status_husong.husong_pt,
                            PS#player_status.hp,
                            PS#player_status.hp_lim,
                            PS#player_status.speed
                        }
                    }
                })
    end;

%% 宠物
update(pet, PS) ->
    Pet = PS#player_status.pet,
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {pet, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                Pet#status_pet.pet_figure,
                                Pet#status_pet.pet_nimbus,
                                Pet#status_pet.pet_name,
                                Pet#status_pet.pet_level,
                                data_pet:get_quality(Pet#status_pet.pet_aptitude)
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {pet, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            Pet#status_pet.pet_figure,
                            Pet#status_pet.pet_nimbus,
                            Pet#status_pet.pet_name,
                            Pet#status_pet.pet_level,
                            data_pet:get_quality(Pet#status_pet.pet_aptitude)
                        }
                    }
                })
    end;

%% Pk状态
update(pk, PS) ->
    PK = PS#player_status.pk,
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {pk, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PK#status_pk.pk_status,
                                PK#status_pk.pk_value
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {pk, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PK#status_pk.pk_status,
                            PK#status_pk.pk_value
                        }
                    }
                })
    end;

%% 飞行坐骑
update(fly_mount, PS) ->
    Mou = PS#player_status.mount,
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {fly_mount, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                Mou#status_mount.fly_mount
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {fly_mount, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            Mou#status_mount.fly_mount
                        }
                    }
                })
    end;

%% 飞行坐骑
update(flyer, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [PS#player_status.scene, {'update', {flyer, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], {PS#player_status.flyer_attr#status_flyer.figure, PS#player_status.flyer_attr#status_flyer.sky_figure, PS#player_status.speed}}}]);
        Pid ->
            gen_server:cast(Pid,{'update', {flyer, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],{PS#player_status.flyer_attr#status_flyer.figure, PS#player_status.flyer_attr#status_flyer.sky_figure, PS#player_status.speed}}})
    end;


%% 怒气值
update(anger, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {anger, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.anger,
                                PS#player_status.anger_lim
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {anger, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.anger,
                            PS#player_status.anger_lim
                        }
                    }
                })
    end;

%% 竞技场
update(arena, [Id,SceneId,Continues_Kill]) ->
    Key = [Id, config:get_platform(), config:get_server_num()],
    case get_scene_pid(SceneId) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    SceneId, {
                        'update', {arena, Key,
                            {
                                Continues_Kill
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {arena, Key,
                        {
                            Continues_Kill
                        }
                    }
                })
    end;

%% 蟠桃园
update(peach, [Id,SceneId,Peach_Num]) ->
    Key = [Id, config:get_platform(), config:get_server_num()],
    case get_scene_pid(SceneId) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    SceneId, {
                        'update', {peach, Key,
                            {
                                Peach_Num
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {peach, Key,
                        {
                            Peach_Num
                        }
                    }
                })
    end,
    %%更改玩家PS上蟠桃数
    lib_player:update_player_info(Id, [{peach_num,Peach_Num}]);

%% 形象
update(figure, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {figure, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.figure
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {figure, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.figure
                        }
                    }
                })
    end;

%% 器灵形象
update(qiling_figure, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {qiling_figure, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.qiling
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {qiling_figure, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.qiling
                        }
                    }
                })
    end;

%% 玩家头像
update(change_image, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {change_image, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.image
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {change_image, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.image
                        }
                    }
                })
    end;

%% 坐标
update(xy, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {xy, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.x,
                                PS#player_status.y
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {xy, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.x,
                            PS#player_status.y
                        }
                    }
                })
    end;

%% 速度
update(speed, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {speed, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.speed
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {speed, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.speed
                        }
                    }
                })
    end;

%% 帮派
update(guild, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {guild, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.guild#status_guild.guild_id,
                                PS#player_status.guild#status_guild.guild_name,
                                PS#player_status.guild#status_guild.guild_position
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {guild, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.guild#status_guild.guild_id,
                            PS#player_status.guild#status_guild.guild_name,
                            PS#player_status.guild#status_guild.guild_position
                        }
                    }
                })
    end;

%% 帮派联盟关系
update(guild_rela, [RoleId, Scene, FList, EList]) ->
    Key = [RoleId, config:get_platform(), config:get_server_num()],
    case get_scene_pid(Scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    Scene, {
                        'update', {guild_rela, Key,
                            {
                                FList,
                                EList
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {guild_rela, Key,
                        {
                            FList,
                            EList
                        }
                    }
                })
    end;

%% 南天门
update(wubianhai, PS) ->
    PK = PS#player_status.pk,
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {wubianhai, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PK#status_pk.pk_status,
                                PK#status_pk.pk_value,
                                PS#player_status.hp,
                                PS#player_status.hp_lim,
                                make_battle_attr_record(PS)
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {wubianhai, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PK#status_pk.pk_status,
                            PK#status_pk.pk_value,
                            PS#player_status.hp,
                            PS#player_status.hp_lim,
                            make_battle_attr_record(PS)
                        }
                    }
                })
    end;

%% 伴侣ID
update(parner_id, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {parner_id, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.parner_id
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {parner_id, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.parner_id
                        }
                    }
                })
    end;

%% 变性
update(changesex, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {changesex, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.sex
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {changesex, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.sex
                        }
                    }
                })
    end;

%% 帮派水晶
update(factionwar_stone, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {factionwar_stone, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.factionwar_stone
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {factionwar_stone, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.factionwar_stone
                        }
                    }
                })
    end;

%% 结婚伴侣
update(marriage_parner_id, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {marriage_parner_id, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.marriage#status_marriage.parner_id,
                                PS#player_status.marriage#status_marriage.register_time
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {marriage_parner_id, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.marriage#status_marriage.parner_id,
                            PS#player_status.marriage#status_marriage.register_time
                        }
                    }
                })
    end;


%% 是否在巡游状态
update(is_cruise, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {is_cruise, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.marriage#status_marriage.is_cruise
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {is_cruise, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.marriage#status_marriage.is_cruise
                        }
                    }
                })
    end;

%% 更新可见状态
update(visible, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [
                    PS#player_status.scene, {
                        'update', {visible, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                            {
                                PS#player_status.visible
                            }
                        }
                    }
                ]);
        Pid ->
            gen_server:cast(Pid,{
                    'update', {visible, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num],
                        {
                            PS#player_status.visible
                        }
                    }
                })
    end;

%% 默认匹配
update(_, _) ->
    ok.

update_to_clusters(Scene, Args) ->
    gen_server:cast(get_scene_pid(Scene), Args).


%% 玩家离开场景
leave(PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [PS#player_status.scene, {'leave', PS#player_status.copy_id, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], PS#player_status.x, PS#player_status.y}]);
        Pid ->
            gen_server:cast(Pid,{'leave', PS#player_status.copy_id, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], PS#player_status.x, PS#player_status.y})
    end.

%%移动
move(X, Y, F, PS) ->
    case get_scene_pid(PS#player_status.scene) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, update_to_clusters, [PS#player_status.scene, {'move', [PS#player_status.copy_id, X, Y, F, PS#player_status.x, PS#player_status.y, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], PS#player_status.mp]}]);
        Pid ->
            gen_server:cast(Pid,{'move', [PS#player_status.copy_id, X, Y, F, PS#player_status.x, PS#player_status.y, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num], PS#player_status.mp]})
    end.

%%获取指定场景人数
get_scene_num(Sid) ->
    case get_scene_pid(Sid) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_call(?MODULE, get_scene_num, [Sid]);
        Pid ->
            gen_server:call(Pid, {'scene_num'})
    end.

%%给指定用户发送场景信息
send_scene_info_to_uid(Key, Sid, CopyId, X, Y) ->
    case get_scene_pid(Sid) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, send_scene_info_to_uid, [Key, Sid, CopyId, X, Y]);
        Pid ->
            gen_server:cast(Pid, {'send_scene_info_to_uid', Key, CopyId, X, Y})
    end.

%%关闭指定的场景
close_scene(Sid) ->
    case get_scene_pid(Sid) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, close_scene, [Sid]),
            erase({get_scene_pid, Sid});
        Pid ->
            gen_server:cast(Pid, {'close_scene'}),
            erase({get_scene_pid, Sid})
    end.


%% 清理所有场景数据
clear_scene(Sid) ->
    case get_scene_pid(Sid) of
        undefined ->
            skip;
        clusters -> %% 发到跨服中心去
            mod_clusters_node:apply_cast(?MODULE, clear_scene, [Sid]);
            %erase({get_scene_pid, Sid});
        Pid ->
            gen_server:cast(Pid, {'clear_scene'})
            %erase({get_scene_pid, Sid})
    end.

start_link([Scene]) ->
    %gen_server:start_link(?MODULE, [?SCENE_AGENT_NUM, Scene], []);
    gen_server:start(?MODULE, [?SCENE_AGENT_NUM, Scene], []);
start_link([Num, Scene]) ->
    %gen_server:start_link(?MODULE, [Num, Scene], []).
    gen_server:start(?MODULE, [Num, Scene], []).

%% Num:场景个数
%% WorkerId:进行标示
%% Scene:场景相关内容
init([Num, Scene]) ->
    process_flag(trap_exit, true),
    SceneProcessName = misc:scene_process_name(Scene#ets_scene.id),
    set_process_pid(SceneProcessName),
    mod_mon_agent:start_mod_mon_agent(Scene#ets_scene.id),
    mod_scene:add_node_scene(Scene#ets_scene.id),
    mod_scene:copy_scene(Scene#ets_scene.id, 0),
    mod_scene_monitor:start_link(Scene#ets_scene.id),
    Sid = list_to_tuple(lists:map(
            fun(_)->
                    spawn_link(fun()->do_msg() end)
            end,lists:seq(1, Num))
    ),
    State= Scene#ets_scene{worker = Sid},
    %catch util:errlog("=============mod_scene_agent(~p) is creat at (~p) node============", [Scene#ets_scene.id, mod_disperse:node_id()]),
    {ok, State}.

handle_cast(R , State) ->
    case catch mod_scene_agent_cast:handle_cast(R, State) of
        {noreply, NewState} ->
            {noreply, NewState};
        {stop, Normal, NewState} ->
            {stop, Normal, NewState};
        Reason ->
            util:errlog("mod_scene_agent_cast error: ~p, Reason:=~p~n",[R, Reason]),
            {noreply, State}
    end.

handle_call(R, From, State) ->
    case catch mod_scene_agent_call:handle_call(R , From, State) of
        {reply, NewFrom, NewState} ->
            {reply, NewFrom, NewState};
        Reason ->
             util:errlog("mod_scene_agent_call error: ~p, Reason=~p~n",[R, Reason]),
             {reply, error, State}
    end.

handle_info(R, State) ->
    case catch mod_scene_agent_info:handle_info(R, State) of
        {noreply, NewState} ->
            {noreply, NewState};
        Reason ->
            util:errlog("mod_scene_agent_info error: ~p, Reason:=~p~n",[R, Reason]),
            {noreply, State}
    end.

terminate(R, State) ->
    mod_scene:del_node_scene(State#ets_scene.id),
    del_process_pid(misc:scene_process_name(State#ets_scene.id)),
    catch util:errlog("mod_scene_agent is terminate, id is ~p, res:~p", [State#ets_scene.id, R]),
    {ok, State}.

code_change(_OldVsn, State, _Extra)->
    {ok, State}.

%% ================== 私有函数 =================

%%启动场景模块 (加锁保证全局唯一)
start_mod_scene_agent(Id) ->
    SceneProcessName = misc:scene_process_name(Id),
    set_process_lock(SceneProcessName),
	ScenePid = start_scene(Id),
    del_process_lock(SceneProcessName),
	ScenePid.

%% 启动场景模块
start_scene(Id) ->
    case data_scene:get(Id) of
        [] ->
            undefined;
        Scene ->
            {ok, NewScenePid} = start_link([Scene]),
            NewScenePid
    end.

%% 动态加载某个场景 Lv : 场景等级
get_scene_pid(Id) ->
    case get({get_scene_pid, Id}) of
        undefined ->
            case data_scene:get(Id) of
                [] ->
                    undefined;
                Scene ->
                    IsCreate = case Scene#ets_scene.type of
                        ?SCENE_TYPE_CLUSTERS -> %% 跨服场景
                            case config:get_cls_type() of
                                1 ->
                                    true;
                                _ ->
                                    false
                            end;
                        _ ->
                            true
                    end,
                    case IsCreate of
                        true ->
                            SceneProcessName = misc:scene_process_name(Id),
                            ScenePid = case get_process_pid(SceneProcessName) of
                                Pid when is_pid(Pid) ->
                                    case misc:is_process_alive(Pid) of
                                        true ->
                                            Pid;
                                        false ->
                                            del_process_pid(SceneProcessName),
                                            exit(Pid, kill),
                                            mod_scene_init:start_new_scene(Id)
                                    end;
                                _ ->
                                    mod_scene_init:start_new_scene(Id)
                            end,
                            case is_pid(ScenePid) of
                                true ->
                                    put({get_scene_pid, Id}, ScenePid);
                                false ->
                                    undefined
                            end,
                            ScenePid;
                        false ->  %% 需要发送到跨服中心去
                            put({get_scene_pid, Id}, clusters),
                            clusters
                    end
            end;
        ScenePid ->
            ScenePid
    end.

%% 处理消息
do_msg() ->
    receive
        {apply, Module, Method, Args} ->
            apply(Module, Method, Args);
        _ ->
            do_msg()
    end.

%% 获取进程pid
get_process_pid(ProcessName) ->
    case config:get_cls_type() of
        1 ->
            %% 跨服中心启动
            misc:whereis_name(local, ProcessName);
        _ ->
            %% 跨服节点启动
            misc:whereis_name(global, ProcessName)
    end.

%% 获取进程pid
set_process_pid(ProcessName) ->
    case config:get_cls_type() of
        1 ->
            %% 跨服中心启动
            misc:register(local, ProcessName, self());
        _ ->
            %% 跨服节点启动
            misc:register(global, ProcessName, self())
    end.

del_process_pid(ProcessName) ->
    case config:get_cls_type() of
        1 ->
            %% 跨服中心启动
            misc:unregister(local, ProcessName);
        _ ->
            %% 跨服节点启动
            misc:unregister(global, ProcessName)
    end.

set_process_lock(ProcessName) ->
    case config:get_cls_type() of
        1 ->
            %% 跨服中心启动
            skip;
        _ ->
            %% 跨服节点启动
            global:set_lock({ProcessName, undefined})
    end.

del_process_lock(ProcessName) ->
    case config:get_cls_type() of
        1 ->
            %% 跨服中心启动
            skip;
        _ ->
            %% 跨服节点启动
            global:del_lock({ProcessName, undefined})
    end.

%% 转化为battle_attr{}
make_battle_attr_record(PS)-> 
    #battle_attr{
        att = PS#player_status.att,               
        def = PS#player_status.def,                                     
        att_area = PS#player_status.att_area,          
        hit = PS#player_status.hit,
        dodge = PS#player_status.dodge,
        crit = PS#player_status.crit,
        ten = PS#player_status.ten,
        fire = PS#player_status.fire,           
        ice = PS#player_status.ice,            
        drug = PS#player_status.drug,
        hurt_add_num = PS#player_status.hurt_add_num,
        hurt_del_num = PS#player_status.hurt_del_num,
        combat_power = PS#player_status.combat_power,
        skill         = PS#player_status.skill#status_skill.skill_list,
        medal_skill   = PS#player_status.skill#status_skill.medal_skill,
        battle_status = PS#player_status.battle_status,
        skill_cd      = PS#player_status.skill#status_skill.skill_cd    % skill_cd状态
    }.
