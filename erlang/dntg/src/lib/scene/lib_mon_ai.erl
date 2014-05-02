%%%-----------------------------------
%%% @Module  : lib_mon_ai
%%% @Author  : zzm
%%% @Created : 2012.07.17
%%% @Description: 怪物Ai
%%%-----------------------------------

-module(lib_mon_ai).
-compile(export_all).
-include("scene.hrl").
-include("skill.hrl").
-include("dungeon.hrl").

%% 炼狱副本跳波怪物
skip_mon(State, NowTime) -> 
    Minfo = State#mon_act.minfo,
    if
        State#mon_act.create_time > 0 andalso NowTime - State#mon_act.create_time < 61000 andalso Minfo#ets_mon.skip > 0 andalso State#mon_act.begin_atted_time == 0 -> 
            {ok, BinData} = pt_120:write(12097, [3, 0, 11, Minfo#ets_mon.skip]),
            lib_server_send:send_to_scene(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, BinData),
            State#mon_act{begin_atted_time = NowTime};
        true -> State
    end.


%% 出生后效果
%% MonAct: 怪物进程的进程状态
born(ActState, StataName) -> 
    Minfo = ActState#mon_act.minfo,
    case data_mon_ai_born:get(Minfo#ets_mon.mid) of
        [] -> {ActState, StataName};
        EffList -> do_eff_list(EffList, ActState, 0, StataName)
    end. 

%% 死亡效果
die(ActState, StateName) ->
    Minfo = ActState#mon_act.minfo, 
    case data_mon_ai_die:get(Minfo#ets_mon.mid) of
        [] -> {ActState, StateName};
        EffList ->  do_eff_list(EffList, ActState, 0, StateName)
    end.

%% hp变化效果
hp_change(Hp1, Hp2, ActState, StateName) ->
    Minfo = ActState#mon_act.minfo,
    case data_mon_ai_hp:get(Minfo#ets_mon.mid) of
        [] -> {ActState, StateName};
        HpList -> 
            HpLim = Minfo#ets_mon.hp_lim,
            HpR1 = Hp1/HpLim,
            HpR2 = Hp2/HpLim,
            case hp_event_help(HpList, HpR1, HpR2) of
                false -> {ActState, StateName};
                {true, V} -> 
                    case data_mon_ai_hp:get(Minfo#ets_mon.mid, V) of
                        [] -> {ActState, StateName};
                        EffList -> do_eff_list(EffList, ActState, util:longunixtime(), StateName)
                    end
            end
    end.

%% 状态改变效果
state_change(ActState, StateName) -> 
    case ActState#mon_act.eref == [] of
        false -> {ActState, StateName};
        true -> 
            Minfo = ActState#mon_act.minfo,
            case data_mon_ai_state:get(Minfo#ets_mon.mid) of
                [] -> {ActState, StateName};
                EffList -> do_eff_list(EffList, ActState, util:longunixtime(), StateName)
            end
    end. 

%% 状态回复变化
resume(ActState) -> 
    cancle_timer(ActState#mon_act.eref),
    Minfo = ActState#mon_act.minfo,
    case data_mon_ai_resume:get(Minfo#ets_mon.mid) of
        [] -> {ActState#mon_act{eref = []}, sleep};
        EffList -> do_eff_list(EffList, ActState#mon_act{eref = []}, 0, none)
    end.

%% 走完特殊效果
walk_end(ActState, StateName) -> 
    Minfo = ActState#mon_act.minfo,
    case data_mon_ai_walk_end:get(Minfo#ets_mon.mid, Minfo#ets_mon.path_no) of
        [] -> {ActState, StateName};
        EffList -> 
            do_eff_list(EffList, ActState, 0, StateName)
    end.

%% 判断血量变化
hp_event_help([], _HpR1, _HpR2) -> false;
hp_event_help([V|T], HpR1, HpR2) ->
    if
        HpR1 > V andalso HpR2 =< V -> {true, V};
        true -> hp_event_help(T, HpR1, HpR2)
    end.

%% 怪物说话
send_mon_talk(Msg, Mid, Minfo) ->
    case Mid == 0 of
        true -> %% 自己说话 
            {ok, BinData} = pt_121:write(12103, [Minfo#ets_mon.id, Msg]),
            lib_server_send:send_to_scene(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, BinData);
        false -> 
            case lib_mon:get_scene_mon_by_mids(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, [Mid], [#ets_mon.id]) of
                [] -> skip;
                [ReturnMid|_]-> 
                    {ok, BinData} = pt_121:write(12103, [ReturnMid, Msg]),
                    lib_server_send:send_to_scene(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, BinData)
            end
    end.

%% 取消事件定时器
cancle_timer(ERef) ->
    case ERef =:= [] of
        true -> skip;
        false ->
            erlang:cancel_timer(ERef)
    end.

%% 发送事件定时器
send_after(Time, Pid, Msg, ERef) -> 
    cancle_timer(ERef),
    erlang:send_after(Time, Pid, Msg).

%% 直线寻路 %% lib_mon_effect:dest_path(73, 124, 74, 107, 220).
dest_path(OldX, OldY, DestX, DestY, Scene) ->
    A = case DestX - OldX == 0 of
        true -> 0;
        false -> (DestY - OldY) / (DestX - OldX)
    end,
    B = DestY - A * DestX,
    DisX = abs(DestX - OldX),
    DisY = abs(DestY - OldY),
    Ref = if
        DisX > DisY -> x;
        true -> y
    end,
    Fx = fun(I, Result) -> 
            X = case OldX < DestX of
                true -> OldX + I;
                false -> OldX - I
            end,
            Y = trunc(A*X + B),
            {ok, [{Scene, X, Y}|Result]}
    end,
    Fy = fun(I, Result) -> 
             Y = case OldY < DestY of
                true -> OldY + I;
                false -> OldY - I
            end,
            X = case A == 0 of
                true -> OldX;
                false -> trunc((Y - B)/A)
            end,
            {ok, [{Scene, X, Y}|Result]}
    end,
    case Ref of
        x -> {ok, Path} = util:for(1, DisX, Fx, []), 
            lists:reverse(Path);
        y -> {ok, Path} = util:for(1, DisY, Fy, []), 
            lists:reverse(Path)
    end.

do_eff_list([], ActState, _Now, StateName) -> {ActState, StateName};
do_eff_list([{Type, Args, Time}|EffList], ActState, Now, StateName) -> 
    Minfo = ActState#mon_act.minfo,
    %% 先判断条件类型
    {LastEffList, LastMinfo, LastStateName} = 
    case Type of
        is_signed -> %% 判断是否有该值
            [Value, N] = Args,
            {_SignedHandleEffList, LeftEffList} = lists:split(N, EffList),
            NewEffList = case lists:member({signed, Value}, Minfo#ets_mon.event) of
                false -> LeftEffList;
                true ->  EffList
            end,
            {NewEffList, Minfo, StateName};

        rand -> %% 随机执行后面的语句
            [PercentageList, NList] = Args,
            NewEffList = handle_rand_list(PercentageList, NList, EffList),
            {NewEffList, Minfo, StateName};

        get  -> %% 获取某怪物ai，然后执行
            [AIType, Mid, OtherArgs] = Args,
            NewEffList = case AIType of
                1 -> data_mon_ai_born:get(Mid);
                2 -> data_mon_ai_die:get(Mid);
                3 -> data_mon_ai_state:get(Mid);
                4 -> data_mon_ai_hp:get(Mid, OtherArgs);
                5 -> data_mon_ai_walk_end:get(Mid, OtherArgs);
                6 -> data_mon_ai_resume:get(Mid);
                _ -> catch util:errlog("mon_ai error:Mid=~p, Type=~p, Args=~p~n", [Mid, get, Args])
            end,
            {NewEffList, Minfo, StateName};

        eff_other_mon -> %% 影响同场景的怪物
            [Mids, N] = Args,
            {OtherMonEfflist, LeftEffList} = lists:split(N, EffList), 
            case lib_mon:get_scene_mon_by_mids(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, Mids, #ets_mon.aid) of
                [] -> ok;
                EffectML ->
                    [Aid ! {'special_event', OtherMonEfflist} || Aid <- EffectML]
            end,
            {LeftEffList, Minfo, StateName};
        msg ->  %% 怪物头上冒泡泡说话
            [Mid, Msg] = Args,
            send_mon_talk(Msg, Mid, Minfo), 
            {EffList, Minfo, StateName};

        cw -> %% 发送传闻
            [_CWType, _Msg] = Args,
            {EffList, Minfo, StateName};

        create_mon -> %% 创建怪物
            [Mid, Xmin, Xmax, Ymin, Ymax, IsActive, OtherArgs] = Args,
            X = if
                Xmin < Xmax                     -> Minfo#ets_mon.x + util:rand(Xmin, Xmax); %% 在Xmin-Xmax直接随机偏移
                Xmin == Xmax andalso Xmin == 0  -> Minfo#ets_mon.x;                         %% 当Xmin=Xmax=0，直接取父辈值
                Xmin == Xmax                    -> Xmin;                                    %% 当Xmin=Xmax/=0，直接取Xmin值
                Xmin > Xmax                     -> Minfo#ets_mon.x + Xmin                   %% 取固定偏移值
            end,
            Y = if
                Ymin < Ymax                     -> Minfo#ets_mon.y + util:rand(Ymin, Ymax); %% 同X的取值规则
                Ymin == Ymax andalso Ymin == 0  -> Minfo#ets_mon.y;
                Ymin == Ymax                    -> Ymin;
                Ymin > Ymax                     -> Minfo#ets_mon.y + Ymin
            end,
            Xzero = case X > 0 of true -> X; false -> 0 end,
            Yzero = case Y > 0 of true -> Y; false -> 0 end,
            catch lib_mon:async_create_mon(Mid, Minfo#ets_mon.scene, Xzero, Yzero, IsActive, Minfo#ets_mon.copy_id, 1, OtherArgs),
            {EffList, Minfo, StateName};

        remove -> %% 多少秒后移除怪物
            DieTime = Args,
            erlang:send_after(DieTime, Minfo#ets_mon.aid, remove),
            {EffList, Minfo, StateName};

        die -> %% 多少秒后杀死怪物
            DieTime = Args,
            erlang:send_after(DieTime, Minfo#ets_mon.aid, 'die'),
            {EffList, Minfo, StateName};

        skill -> %% 更新怪物技能列表
            SkillList = Args,
            {EffList, Minfo#ets_mon{skill = SkillList}, StateName};

        ac_skill -> %% 释放技能
            [SkillId, SkillLv] = Args,
            case data_skill:get(SkillId, SkillLv) of
                [] -> skip;
                SkillData -> 

                    AttInfo = case ActState#mon_act.att of
                        [] -> [];
                        [Key, _Pid, AttType] -> [Key, AttType]
                    end,
                    if
                        %% 对自身释放辅助技能
                        SkillData#player_skill.type == 3 -> 
                            mod_scene_agent:apply_cast(Minfo#ets_mon.scene, lib_battle, mon_assist_skill, [Minfo, AttInfo, SkillId, SkillLv]);
                        true -> 
                            mod_scene_agent:apply_cast(Minfo#ets_mon.scene, lib_battle, mon_active_skill, [Minfo, AttInfo, SkillId, SkillLv])
                    end,
                    %% 如果是竞技场boss要改变奖励归属
                    BossList = data_arena_new:get_arena_config(boss_id),
                    case lists:member(Minfo#ets_mon.mid, BossList) of 
                        true ->
                            lib_arena_new:change_boss_award(Minfo#ets_mon.copy_id, Minfo#ets_mon.mid);
                        false ->
                            skip 
                    end
            end,
            {EffList, Minfo, StateName};

        clear_scene_mon -> %% 清理场景中特定资源id的怪物
            Mids = Args,
            lib_mon:clear_scene_mon_by_mids(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, 1, Mids),
            {EffList, Minfo, StateName};

        kind -> %% 改变kind
            Value = Args,
            {EffList, Minfo#ets_mon{kind = Value}, StateName};

        group -> %% 改变group
            Value = Args,
            {EffList, Minfo#ets_mon{group = Value}, StateName};

        change_icon -> %% 更改自身形象
            Icon = Args,
            {ok, BinData} = pt_120:write(12098, [Minfo#ets_mon.id, Icon]),
            lib_server_send:send_to_area_scene(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y, BinData),
            {EffList, Minfo#ets_mon{icon = Icon}, StateName};

        cbuff -> %% 清理身上一个buff
            SkillId = Args,
            NewBS = lib_skill_buff:clear_buff(Minfo#ets_mon.battle_status, SkillId, []),
            {EffList, Minfo#ets_mon{battle_status = NewBS}, StateName};

        del_hp -> %% 对自己减血
            [Count, SpaceTime, HurtValue] = Args,
            case is_float(HurtValue) of
                true -> 
                    Int = 0,
                    Float = HurtValue;
                false -> 
                    Int = HurtValue,
                    Float = 0
            end,
            spawn(fun() ->  mod_battle:last_red_hp(Minfo#ets_mon.aid, [Count, SpaceTime, Int, Float]) end ), %% 自身扣血
            {EffList, Minfo, StateName};

        hurt_mon -> %% 使周围特定的怪物受到伤害 
            [Mids, HurtValue, Area] = Args,
            MonList = lib_mon:get_area_mon_id_aid_mid(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y, Area, Minfo#ets_mon.group),
            [Aid ! {last_change_hp, 0, HurtValue} || [_Id, Aid, Mid] <- MonList, lists:member(Mid, Mids)],
            {EffList, Minfo, StateName};

        signed -> %% 标记
            Value = Args,
            NewEvent = [{signed, Value}|lists:keydelete(signed, 1, Minfo#ets_mon.event)],
            {EffList, Minfo#ets_mon{event = NewEvent}, StateName};

        nochange -> %% 不作任何改变
            {EffList, Minfo, StateName};

        state -> %% 状态转变
            NewStateName = Args,
            {EffList, Minfo, NewStateName};

        walk -> %% 走到目标位置
            [X, Y, PathNo] = Args,
            Path = dest_path(Minfo#ets_mon.x, Minfo#ets_mon.y, X, Y, Minfo#ets_mon.scene),
            {EffList, Minfo#ets_mon{path = Path, path_no = PathNo}, walk};

        path -> %% 设定怪物路径 
            [Path, PathNo] = Args, %% 格式为[{scene_id, x, y}, ....]
            {EffList, Minfo#ets_mon{path = Path, path_no = PathNo}, walk};

        auto_att -> %% 找怪|玩家攻击
            self() ! {'FIND_PLAYER_FOR_BATTLE', 0},
            {EffList, Minfo, StateName};

        pet_change_icon -> %% 宠物副本专属AI
            [SkillId, SkillLv] = Args,
            case mod_pet_dungeon:get_mon_list(Minfo#ets_mon.copy_id) of
                [] -> {EffList, Minfo, StateName};
                [PetDungeon|_] -> 
                    case lists:member(Minfo#ets_mon.mid, PetDungeon#ets_pet_dungeon.mon_list) of
                        true ->
                            {EffList, Minfo, StateName};
                        false ->
                            %1.怪物变身.
                            mod_pet_dungeon:mon_change_look(
                                Minfo#ets_mon.scene, Minfo#ets_mon.copy_id,
                                Minfo#ets_mon.id, "change_look"),

                            %2.修改攻击力. 
                            mod_scene_agent:apply_cast(Minfo#ets_mon.scene, lib_battle, mon_assist_skill, [Minfo, Minfo, SkillId, SkillLv]),

                            %% 播放闹钟动画
                            {ok, BinData} = pt_120:write(12097, [1, Minfo#ets_mon.id, 1, 0]),
                            lib_server_send:send_to_area_scene(
                                Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, 
                                Minfo#ets_mon.x, Minfo#ets_mon.y, BinData),

                            %% 修改为旗子怪物                                    
                            NewMinfo = Minfo#ets_mon{kind = 2},
                            {EffList, NewMinfo, StateName}
                    end
            end;

        pet_resume_icon -> %% 宠物副本专属AI
            mod_pet_dungeon:mon_change_look(
                Minfo#ets_mon.scene, Minfo#ets_mon.copy_id,
                Minfo#ets_mon.id, "turn_back"),
            {EffList, Minfo, StateName};

        _ -> {EffList, Minfo, StateName}

    end,
    LastState  = ActState#mon_act{minfo = LastMinfo},
    case Time of
        0     -> do_eff_list(LastEffList, LastState, Now, LastStateName);
        cycle ->
            case data_mon_ai_cycle:get(LastMinfo#ets_mon.mid) of
                [] -> {LastState, LastStateName};
                CycleEffList -> do_eff_list(CycleEffList, LastState, Now, LastStateName)
            end;
        _     -> 
            ERef = send_after(Time, LastMinfo#ets_mon.aid, {'special_event', LastEffList}, LastState#mon_act.eref),
            {LastState#mon_act{eref = ERef}, LastStateName}
    end.

%% 寻找可追踪/攻击的玩家
get_player_for_att(SceneId, CopyId, X, Y, Area, Group) ->
    mod_scene_agent:apply_call(SceneId, lib_scene_agent, get_scene_user_for_battle, [CopyId, X, Y, Area, Group]).

%% 获取随机列表
handle_rand_list(PercentageList, NList, EffList) -> 
    Max   = lists:sum(PercentageList),
    RandR = util:rand(1, Max),
    handle_rand_list_helper(PercentageList, NList, RandR, 0, 0, EffList).
handle_rand_list_helper([], _, _, _, _, _) -> [];
handle_rand_list_helper([Percent|TPercentageList], [N|TNList], RandR, LastPerCentPoint, LastN, EffList) -> 
    case RandR =< Percent + LastPerCentPoint of
        true  -> 
            {_, LeftEffList} = lists:split(LastN, EffList),
            {RandList, _} = lists:split(N, LeftEffList),
            RandList;
        false -> handle_rand_list_helper(TPercentageList, TNList, RandR, Percent + LastPerCentPoint, LastN + N, EffList)
    end.

%% 影响玩家
eff_player({Type, Value}, Minfo) ->
    case Type of
        marry_exp -> 
            case mod_scene_agent:apply_call(Minfo#ets_mon.scene, lib_scene_agent, get_scene_user_pid_area, [Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y, Value]) of
                UserPidList when is_list(UserPidList) -> 
                    [Pid ! 'marriage_exp' || Pid <- UserPidList];
                _ -> ok
            end,
            Minfo;
        mars_kf_exp -> 
            case mod_scene_agent:apply_call(Minfo#ets_mon.scene, lib_scene_agent, get_scene_user_pid_area, [Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y, Value]) of
                UserPidList when is_list(UserPidList) -> 
                    [Pid ! 'mars_kf_exp' || Pid <- UserPidList];
                _ -> ok
            end,
            Minfo;
        _ -> Minfo
    end.
