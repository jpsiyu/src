%%%------------------------------------
%%% @Module  : mod_scene_agent_cast
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2012.05.18
%%% @Description: 场景管理cast处理
%%%------------------------------------
-module(mod_scene_agent_cast).
-export([handle_cast/2]).
-include("scene.hrl").
-include("common.hrl").

%% 移动
handle_cast({'move', [CopyId, X, Y, F, X2, Y2, Key, Mp]} , State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            Id = SceneUser#ets_scene_user.id,
            mod_mon_active:mon_ai(State#ets_scene.id, CopyId, X, Y, [SceneUser#ets_scene_user.id, SceneUser#ets_scene_user.platform, SceneUser#ets_scene_user.server_num], SceneUser#ets_scene_user.pid),
            {ok, BinData} = pt_120:write(12001, [X, Y, F, Id, SceneUser#ets_scene_user.platform, SceneUser#ets_scene_user.server_num]),

            case lib_scene:is_broadcast_scene(State#ets_scene.id) of
                true ->
                    lib_scene_agent:send_to_local_scene(SceneUser#ets_scene_user.copy_id, BinData);
                false ->
                    % 移除
                    {ok, BinData1} = pt_120:write(12004, [Id, SceneUser#ets_scene_user.platform, SceneUser#ets_scene_user.server_num]),
                    % 有玩家进入
                    {ok, BinData2} = pt_120:write(12003, SceneUser),

                    %% 九宫格编号改变使下一九宫格的怪物主动攻击玩家
                    %XY1 = lib_scene_calc:get_xy(X, Y),
                    %XY2 = lib_scene_calc:get_xy(X2, Y2),
                    %Fun = fun() -> 
                    %        case mod_mon_agent:apply_call(State#ets_scene.id, lib_mon_agent, get_all_area_mon, [[XY2], CopyId]) of
                    %            MonList when is_list(MonList)-> [Mon#ets_mon.aid ! {'ai', [SceneUser#ets_scene_user.id, SceneUser#ets_scene_user.platform, SceneUser#ets_scene_user.server_num], SceneUser#ets_scene_user.pid, 2, 0}|| Mon <- MonList];
                    %            _ -> skip
                    %        end
                    %end,
                    %if
                    %    XY1 /= XY2 -> spawn(Fun);
                    %    true       -> skip
                    %end,

                    lib_scene_calc:move_broadcast(State#ets_scene.id, CopyId, X, Y, X2, Y2, BinData, BinData1, BinData2, [SceneUser#ets_scene_user.node, SceneUser#ets_scene_user.sid])
            end,

            %% 速度buff检查
            BA = SceneUser#ets_scene_user.battle_attr,
            BS = BA#battle_attr.battle_status,
            case BS /= [] of
                true-> 
                    NewBS = mod_battle:check_speed_buff_broadcast(SceneUser#ets_scene_user.id, SceneUser#ets_scene_user.platform, SceneUser#ets_scene_user.server_num, SceneUser#ets_scene_user.scene, SceneUser#ets_scene_user.copy_id, SceneUser#ets_scene_user.x, SceneUser#ets_scene_user.y, SceneUser#ets_scene_user.speed, BS, util:longunixtime(), 2),
                    NewBA = BA#battle_attr{battle_status = NewBS},
                    NewSceneUser = SceneUser#ets_scene_user{battle_attr = NewBA};
                false -> 
                    NewSceneUser = SceneUser
            end,
            NewSceneUser1 = lib_battle:interrupt_collect(NewSceneUser), %% 打断采集
            lib_scene_agent:put_user(NewSceneUser1#ets_scene_user{x=X, y=Y, mp = Mp}),
            {noreply, State}
    end;

%% 玩家加入场景
handle_cast({'join', SceneUser} , State) ->
    %%通知所有玩家你进入了
    {ok, BinData} = pt_120:write(12003, SceneUser),
    case lib_scene:is_broadcast_scene(State#ets_scene.id) of
        true ->
            lib_scene_agent:send_to_local_scene(SceneUser#ets_scene_user.copy_id, BinData);
        false ->
            lib_scene_agent:send_to_local_area_scene(SceneUser#ets_scene_user.copy_id, SceneUser#ets_scene_user.x, SceneUser#ets_scene_user.y, BinData)
    end,
    lib_scene_agent:put_user(SceneUser),
    {noreply, State};

%% 更战斗属性信息
handle_cast({'update', {battle_attr, Key, Hp, HpLim, Mp, MpLim, Anger, BA}} , State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{
                    hp = Hp,
                    hp_lim = HpLim,
                    mp = Mp,
                    mp_lim = MpLim,
                    anger  = Anger,
                    battle_attr=BA
                }),
            {noreply, State}
    end;

%% 更新气血和内力
handle_cast({'update', {hp_mp, Key, {Hp, Mp}}} , State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{hp=Hp, mp=Mp}),
            {noreply, State}
    end;

%% 组队信息
handle_cast({'update', {team, Key, {Leader, PidTeam}}} , State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{leader=Leader, pid_team=PidTeam}),
            {noreply, State}
    end;

%% 战斗组队
handle_cast({'update', {group, Key, {Group}}} , State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{group=Group}),
            {noreply, State}
    end;

%% 打坐双修
handle_cast({'update', {sit, Key, {SceneUserSit}}} , State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{sit=SceneUserSit}),
            {noreply, State}
    end;

%% 使用物品
handle_cast({'update', {use_goods, Key, {VipType, Hp, Mp, HpLim, MpLim, Sex}}} , State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{vip_type=VipType, hp=Hp, mp=Mp, hp_lim=HpLim, mp_lim=MpLim, sex=Sex}),
            {noreply, State}
    end;

%% 装备
handle_cast({'update', {equip, Key, {HideArmor, HideAcce, CurrentEquip,
                FashionWeapon, FashionArmor, FashionAcc, Hp, Mp, HpLim, MpLim,
                SuitId, StrenNum, HideWeapon, FashionHead, FashionTail,
                FashionRing, HideHead, HideTail, HideRing, Body, Feet}}} , State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            case HideArmor =:= 0 of
                true ->
                    ArmorId = FashionArmor;
                false ->
                    ArmorId = [0, 0]
            end,
            case HideAcce =:= 0 of
                true ->
                    AcceId = FashionAcc;
                false ->
                    AcceId = [0, 0]
            end,
            case HideWeapon =:= 0 of
                true ->
                    WeaponId = FashionWeapon;
                false ->
                    WeaponId = [0, 0]
            end,

            case HideHead =:= 0 of
                true ->
                    HeadId = FashionHead;
                false ->
                    HeadId = [0, 0]
            end,
            case HideTail =:= 0 of
                true ->
                    TailId = FashionTail;
                false ->
                    TailId = [0, 0]
            end,
            case HideRing =:= 0 of
                true ->
                    RingId = FashionRing;
                false ->
                    RingId = [0, 0]
            end,
            lib_scene_agent:put_user(SceneUser#ets_scene_user{equip_current=CurrentEquip,
                    fashion_weapon=WeaponId,fashion_armor=ArmorId,
                    fashion_accessory=AcceId, hp=Hp, mp=Mp, hp_lim=HpLim,
                    mp_lim=MpLim, suit_id=SuitId, stren7_num=StrenNum,
                    fashion_head=HeadId, fashion_tail=TailId,
                    fashion_ring=RingId, body_effect=Body, feet_effect=Feet}),
            {noreply, State}
    end;

%% 坐骑
handle_cast({'update', {mount, Key, {Figure, Fly, Flyer,Hp, Mp, HpLim, MpLim}}} , State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{mount_figure=Figure, fly=Fly, flyer=Flyer, hp=Hp, mp=Mp, hp_lim=HpLim, mp_lim=MpLim}),
            {noreply, State}
    end;

%% 护送 
handle_cast({'update', {husong, Key, {HusongLv, HusongNpc, HusongPt, HpNow, HpLim, Speed}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{husong = #scene_user_husong{husong_lv = HusongLv,husong_npc = HusongNpc, husong_pt = HusongPt}, hp = HpNow,  hp_lim = HpLim, speed = Speed}),
            {noreply, State}
    end;

%% 宠物
handle_cast({'update', {pet, Key, {PetFigure, PetNimbus, PetName, PetLevel, PetQuality}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{pet = #scene_user_pet{
                    pet_figure = PetFigure,                    
                    pet_nimbus = PetNimbus,                    
                    pet_name = PetName,                      
                    pet_level = PetLevel,
                    pet_quality = data_pet:get_quality(PetQuality)}}),
            {noreply, State}
    end;

%% pk状态
handle_cast({'update', {pk, Key, {PKStatus, PKValue}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{pk = #scene_user_pk{
                    pk_status = PKStatus,                    
                    pk_value = PKValue}}),
            {noreply, State}
    end;

%% 飞行坐骑
handle_cast({'update', {fly_mount, Key, {FlyMountId}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{fly_mount = FlyMountId}),
            {noreply, State}
    end;

%% 飞行器
handle_cast({'update', {flyer, Key, {FlyerFigure, FlyerSkyFigure, FlyingSpeed}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{flyer_figure = FlyerFigure, flyer_sky_figure = FlyerSkyFigure, speed = FlyingSpeed}),
            {noreply, State}
    end;
%% 怒气值
handle_cast({'update', {anger, Key, {Anger, AngerLim}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{anger = Anger, anger_lim = AngerLim}),
            {noreply, State}
    end;

%% 竞技场
handle_cast({'update', {arena, Key, {Continues_Kill}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{
				arena = #scene_user_arena{
					continues_kill=Continues_Kill					  
				}															  
			}),
            {noreply, State}
    end;

%% 蟠桃园
handle_cast({'update', {peach, Key, {Peach_Num}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            Id = SceneUser#ets_scene_user.id,
            lib_scene_agent:put_user(SceneUser#ets_scene_user{
				peach = #scene_user_peach{
					peach_num=Peach_Num					  
				}															  
			}),
			{ok,Bin} = pt_481:write(48108, [Id,Peach_Num]),
			mod_disperse:call_to_unite(lib_unite_send,send_to_scene, 
									   [SceneUser#ets_scene_user.scene,
										SceneUser#ets_scene_user.copy_id,
										Bin]),
            {noreply, State}
    end;

%% 形象
handle_cast({'update', {figure, Key, {Figure}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{figure = Figure}),
            {noreply, State}
    end;

%% 器灵形象
handle_cast({'update', {qiling_figure, Key, {QiLing}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{qiling = QiLing}),
            {noreply, State}
    end;

%% 玩家头像
handle_cast({'update', {change_image, Key, {ImageId}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{image = ImageId}),
            {noreply, State}
    end;

%% 坐标
handle_cast({'update', {xy, Key, {X, Y}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{x = X, y = Y}),
            {noreply, State}
    end;

%% 速度
handle_cast({'update', {speed, Key, {Speed}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{speed = Speed}),
            {noreply, State}
    end;

%% 帮派
handle_cast({'update', {guild, Key, {GuildId, GuildName, GuildPosition}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{guild_id = GuildId, guild_name = GuildName, guild_position = GuildPosition}),
            {noreply, State}
    end;

%% 帮派关系
handle_cast({'update', {guild_rela, Key, {FList, EList}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{guild_rela = {FList, EList}}),
            {noreply, State}
    end;

%% 南天门
handle_cast({'update', {wubianhai, Key, {PkStatus, PkValue, Hp, HpLim, BA}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{pk = #scene_user_pk{pk_status = PkStatus, pk_value = PkValue}, hp = Hp, hp_lim = HpLim, battle_attr = BA}),
            {noreply, State}
    end;

%% 伴侣ID
handle_cast({'update', {parner_id, Key, {ParnerId}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{parner_id = ParnerId}),
            {noreply, State}
    end;

%% 变性
handle_cast({'update', {changesex, Key, {Sex}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{sex = Sex}),
            {noreply, State}
    end;

%% 帮派水晶
handle_cast({'update', {factionwar_stone, Key, {StoneId}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{factionwar_stone = StoneId}),
            {noreply, State}
    end;

%% 结婚伴侣
handle_cast({'update', {marriage_parner_id, Key, {ParnerId, RegisterTime}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{marriage_parner_id = ParnerId, marriage_register_time = RegisterTime}),
            {noreply, State}
    end;

%% 是否在巡游状态
handle_cast({'update', {is_cruise, Key, {IsCruise}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{is_cruise = IsCruise}),
            {noreply, State}
    end;

%% 是否可见
handle_cast({'update', {visible, Key, {Visible}}}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            lib_scene_agent:put_user(SceneUser#ets_scene_user{visible = Visible}),
            {noreply, State}
    end;

%% 玩家离开场景
handle_cast({'leave', CopyId, Key, X, Y} , State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        SceneUser ->
            Id = SceneUser#ets_scene_user.id,
            {ok, BinData} = pt_120:write(12004, [Id, SceneUser#ets_scene_user.platform, SceneUser#ets_scene_user.server_num]),
            case lib_scene:is_broadcast_scene(State#ets_scene.id) of
                true ->
                    lib_scene_agent:send_to_local_scene(CopyId, BinData);
                false ->
                    lib_scene_agent:send_to_local_area_scene(CopyId, X, Y, BinData)
            end,
            lib_scene_agent:del_user(Key),
            {noreply, State}
    end;

%% 给场景所有玩家发送信息
handle_cast({'send_to_scene', CopyId, Bin} , State) ->
    lib_scene_agent:send_to_local_scene(CopyId, Bin),
    {noreply, State};

%% 给场景所有玩家发送信息
handle_cast({'send_to_scene', Bin} , State) ->
    lib_scene_agent:send_to_local_scene(Bin),
    {noreply, State};

%% 给场景九宫格玩家发送信息
handle_cast({'send_to_area_scene', CopyId, X, Y, Bin} , State) ->
    lib_scene_agent:send_to_local_area_scene(CopyId, X, Y, Bin),
    {noreply, State};

%% 加载场景
handle_cast({'load_scene', SceneUser} , State) ->
    %%通知所有玩家你进入了
    handle_cast({'join', SceneUser} , State),
    handle_cast({'send_scene_info_to_uid', [SceneUser#ets_scene_user.id, SceneUser#ets_scene_user.platform, SceneUser#ets_scene_user.server_num], SceneUser#ets_scene_user.copy_id, SceneUser#ets_scene_user.x, SceneUser#ets_scene_user.y}, State),
    {noreply, State};

%% 把场景信息发送给玩家
handle_cast({'send_scene_info_to_uid', Key, CopyId, X, Y}, State) ->
    case lib_scene_agent:get_user(Key) of
        [] ->
            {noreply, State};
        User ->
            case lib_scene:is_broadcast_scene(State#ets_scene.id) of
                true ->
                    SceneUser = lib_scene_agent:get_scene_user(CopyId),
                    SceneMon = lib_scene:get_scene_mon(State#ets_scene.id, CopyId);
                false ->
                    SceneUser = lib_scene_calc:get_broadcast_user(CopyId, X, Y),
                    SceneMon = lib_scene_calc:get_broadcast_mon(State#ets_scene.id, CopyId, X, Y)
            end,

            %%当前元素信息
            %SceneElem = State#ets_scene.elem,
            %%当前npc信息
            %SceneNpc = lib_npc:get_scene_npc(State#ets_scene.id),
            %{ok, BinData} = pt_120:write(12002, {SceneUser, SceneMon, SceneElem, SceneNpc}),
			{ok, BinData} = pt_120:write(12002, {SceneUser, SceneMon}),
            lib_server_send:send_to_sid(User#ets_scene_user.node, User#ets_scene_user.sid, BinData),
            {noreply, State}
    end;

%% 关闭场景
handle_cast({'close_scene'} , State) ->
    catch lib_mon:clear_scene_mon(State#ets_scene.id, [], 0),
    {stop, normal, State};

%% 清理场景
handle_cast({'clear_scene'} , State) ->
    catch lib_mon:clear_scene_mon(State#ets_scene.id, [], 0),
    lib_scene_agent:clear_all_process_dict(),
    {noreply, State};

%% 统一模块+过程调用(cast)
handle_cast({'apply_cast', Module, Method, Args} , State) ->
    apply(Module, Method, Args),
    {noreply, State};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_server_cast:handle_cast not match: ~p", [Event]),
    {noreply, Status}.


    
