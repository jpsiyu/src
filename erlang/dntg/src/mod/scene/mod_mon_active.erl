%%%------------------------------------
%%% @Module  : mod_mon_active
%%% @Author  : zzm
%%% @Created : 2014.03.14
%%% @Description: 怪物活动状态
%%%------------------------------------
-module(mod_mon_active).
-behaviour(gen_fsm).
-export([
        start/1,
        stop/1,
        stop_broadcast/1,
        sleep/2, 
        trace/2,
        trace_td/2,
        trace_ready/2,
        att_ready/2,
        revive/2,
        back/2,
        auto_move/2,
        walk/2,
        walk_td/2,
        walk_rand/2,
        check/2,
        mon_ai/6,
        calc_hatred_list/3,
        insert_for_ai/5,
        is_attack/4,
        team_sort_klist/1,
        send_event_after/3,
        broadcast/2,
        trace_info_back/3,
        att_info_back/2,
        die/1,
        make_mon_drop/6
    ]).
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-include("guild.hrl").
-include("appointment.hrl").
-include("buff.hrl").
-include("skill.hrl").
-include("battle.hrl").

-define(RETIME, 10000). %回血时间
-define(MOVE_TIME, 20000). %自动移动时间
-define(SCAN, 8).   %怪物扫描距离


%%开启一个怪物活动进程
%%每个怪物一个进程
start(M)->
    gen_fsm:start_link(?MODULE, M, []).

%% 初始化
%% 塔防副本特殊icon处理
%king_dun_handle(M) when ((M#ets_mon.mid < 35018 andalso M#ets_mon.mid > 35009) orelse (M#ets_mon.mid < 35006 andalso M#ets_mon.mid > 35001) orelse M#ets_mon.mid == 36000) andalso M#ets_mon.x > 22 -> 
%    M#ets_mon{icon = M#ets_mon.icon+200};
%king_dun_handle(M) when ((M#ets_mon.mid < 36018 andalso M#ets_mon.mid > 36009) orelse (M#ets_mon.mid < 36006 andalso M#ets_mon.mid > 36001) orelse M#ets_mon.mid == 37000) andalso M#ets_mon.x > 22 -> 
%    M#ets_mon{icon = M#ets_mon.icon+200};
%king_dun_handle(M) -> M.

%Gid为阵营Id
init([Id, MonId, Scene, X, Y, Type, CopyId, BroadCast, Arg])->
    case data_mon:get(MonId) of
        [] -> 
            {stop, normal};
        M ->
            Mon = M#ets_mon{
                id = Id,
                scene = Scene,
                copy_id = CopyId,
                x = X,
                y = Y,
                d_x = X,
                d_y = Y,
                type = Type,
                aid = self()
            },

            %% 设置属性
            {Mon1, BaseStateName} = set_mon(Arg, Mon, null),

            %% 主动怪
            case Mon1#ets_mon.type == 1 andalso Mon1#ets_mon.is_fight_back == 1 andalso Mon1#ets_mon.is_be_atted == 1 of
                true -> lib_mon:put_ai(Mon1#ets_mon.aid, Scene, CopyId, X, Y);
                false -> skip
            end,

            %% 是否要记录出生时间(ms)
            CreateTime = case Mon1#ets_mon.skip > 0 of
                true -> util:longunixtime();
                false -> 0
            end,

            %% 出生效果
            {NewState, StateName} = lib_mon_ai:born(#mon_act{minfo = Mon1, create_time = CreateTime}, BaseStateName),
            lib_mon:insert(NewState#mon_act.minfo),

            %% 是否需要在生成的时候广播
            case BroadCast of
                1 -> 
                    {ok, BinData} = pt_120:write(12007, Mon1),
                    broadcast(Mon1, BinData);
                _ ->
                    skip
            end,

            if
                Mon1#ets_mon.ai_type == 1 ->  
                    send_event_after([], 100, repeat),
                    {ok, walk_td, NewState};
                StateName /= null -> 
                    send_event_after([], 1000, repeat),
                    {ok, StateName, NewState};
                true-> 
                    send_event_after([], 100, repeat),
                    {ok, sleep, NewState}
            end
    end.

stop(Aid) ->
    Aid ! clear.

stop_broadcast(Aid) ->
    Aid ! clear_broadcast.

die(Aid) ->
    Aid ! 'die'.

%% 追踪信息返回
trace_info_back(MonAid, AttType, AttInfo) -> 
    MonAid ! {"trace_info_back", AttType, AttInfo}.

%% 战斗信息返回
att_info_back(MonAid, Result) -> 
    MonAid ! {"att_info_back", Result}.

handle_event(_Event, StateName, Status) ->
    {next_state, StateName, Status}.

handle_sync_event({'klist'}, _From, StateName, Status) ->
    {reply, [{Pid, Val, Id} || {Pid, Val, [Id|_], _} <- Status#mon_act.klist], StateName, Status};

handle_sync_event(_Event, _From, StateName, Status) ->
    {reply, ok, StateName, Status}.


%% 更新怪物属性
handle_info({'change_attr', AttrList}, StateName, State) ->
    Minfo = State#mon_act.minfo,
    {NewMinfo, NewStateName} = 
    case catch set_mon(AttrList, Minfo, StateName) of
        {M, StateName1} when is_record(M, ets_mon) -> {M, StateName1};
        _                                          -> {Minfo, StateName}
    end,
    case NewMinfo#ets_mon.hp /= Minfo#ets_mon.hp of %% 血量改变，广播
        true -> 
            {ok, BinData} = pt_120:write(12081, [NewMinfo#ets_mon.id, NewMinfo#ets_mon.hp]),
            broadcast(NewMinfo, BinData);
        false -> 
            skip
    end,
    lib_mon:insert(NewMinfo),
    if
        NewMinfo#ets_mon.hp =< 0 -> handle_info('die', StateName, State#mon_act{minfo = NewMinfo});
        NewStateName /= StateName -> 
            Ref1 = send_event_after(State#mon_act.ref, 100, repeat),
            {next_state, NewStateName, State#mon_act{minfo = NewMinfo, ref = Ref1}};
        true -> 
            {next_state, StateName, State#mon_act{minfo = NewMinfo}} 
    end;

%% 处理怪物的AI定时事件
handle_info({'special_event', Events}, StateName, State) -> 
    {NewState, NewStateName} = lib_mon_ai:do_eff_list(Events, State, util:longunixtime(), StateName),
    lib_mon:insert(NewState#mon_act.minfo),
    Ref1 = case NewStateName /= StateName of
        true -> send_event_after(State#mon_act.ref, 10, repeat);
        false -> NewState#mon_act.ref
    end,
    {next_state, NewStateName, NewState#mon_act{ref = Ref1}};

%% 怪物在复活状态，都不处理其他信息 
handle_info(Info, revive, State) ->
    case Info == clear orelse Info == clear_broadcast orelse Info == 'die' orelse Info == remove of
        true ->
            handle_info(Info, null, State);
        false -> 
            {next_state, revive, State}
    end;

%% 怪物主动攻击
%% Type: 1怪物, 2玩家
handle_info({'ai', Key, Pid, Type, Group}, sleep, State) ->
    case Group == 0 orelse Group /= State#mon_act.minfo#ets_mon.group of
        true ->
            Ref1 = send_event_after(State#mon_act.ref, 100, repeat),
            {next_state, trace, State#mon_act{ref = Ref1, att = [Key, Pid, Type]}};
        false ->
            {next_state, sleep, State}
    end;

%% 采集怪 
handle_info({'collect_info', CollectorKey, CollectorPid, Type}, StateName, State) -> 
    Minfo = State#mon_act.minfo,
    Clist = State#mon_act.clist,
    Ref   = State#mon_act.ref,
    Now   = util:unixtime(),
    case Minfo#ets_mon.hp > 0 andalso (Minfo#ets_mon.kind == 1 orelse Minfo#ets_mon.kind == 7 orelse Minfo#ets_mon.mid == 40421  orelse Minfo#ets_mon.mid == 40461 orelse Minfo#ets_mon.mid == 40471) of %% 怪物类型为1或炮塔适用时间规则
        false -> {next_state, StateName, State};
        true -> 
            case Type of
                1 -> %% 开启采集
                    NewClist = [{CollectorKey, CollectorPid, Now} | lists:keydelete(CollectorKey, 1, Clist)],
                    {next_state, StateName, State#mon_act{clist = NewClist}};
                2 -> %% 结束采集
                    case lists:keyfind(CollectorKey, 1, Clist) of
                        false -> 
                            {next_state, StateName, State};
                        {_, _, Time} -> 
                            NewCollectTime = Minfo#ets_mon.collect_time,
                            case Now - Time >= NewCollectTime - 1 of
                                true -> %% 采集成功
                                    %% 掉落处理
                                    %% 掉落怪只处理最后一名采集者的掉落
                                    OwnerId = Minfo#ets_mon.owner_id,
                                    if 
                                        OwnerId > 0 -> %% 如果怪物有所属，则掉落直接归所属者 
                                            case lib_player:get_player_info(OwnerId, pid) of
                                                false -> 
                                                    LastKlist  =  [{CollectorPid, 0, CollectorKey, 0}],
                                                    KillerKey  =  CollectorKey,
                                                    KillerPid  =  CollectorPid,
                                                    BeAtterPid =  CollectorPid;
                                                OwnerPid -> 
                                                    LastKlist  =  [{OwnerPid, 0, [OwnerId,0,0], 0}],
                                                    KillerKey  =  [OwnerId,0,0],
                                                    KillerPid  =  OwnerPid,
                                                    BeAtterPid =  OwnerPid
                                            end;
                                        true -> 
                                            %% 掉落怪只处理最后一名采集者的掉落
                                            LastKlist  =  [{CollectorPid, 0, CollectorKey, 0}],
                                            KillerKey  =  CollectorKey,
                                            KillerPid  =  CollectorPid,
                                            BeAtterPid =  CollectorPid
                                    end,
                                    mon_drop(Minfo, LastKlist, {KillerKey, KillerPid}, BeAtterPid),

                                    %% 采集完毕处理
                                    if
                                        Minfo#ets_mon.kind == 7    orelse 
                                        Minfo#ets_mon.mid == 10547 orelse 
                                        Minfo#ets_mon.mid == 40421 orelse 
                                        Minfo#ets_mon.mid == 40461 orelse 
                                        Minfo#ets_mon.mid == 40471 -> %% 帮派神石可以无限采集
                                            {next_state, StateName, State#mon_act{clist = lists:keydelete(CollectorKey, 1, Clist)}};
                                        Minfo#ets_mon.collect_times + 1 >= Minfo#ets_mon.collect_count ->
                                            %% 怪物消失  
                                            {ok, BinData} = pt_120:write(12006, [Minfo#ets_mon.id]),
                                            broadcast(Minfo, BinData),
                                            NewMinfo = Minfo#ets_mon{hp = 0, collect_times = 0},
                                            lib_mon:insert(NewMinfo),
                                            {NewState, _} = lib_mon_ai:die(State#mon_act{minfo = NewMinfo}, StateName),
                                            Ref1 = send_event_after(Ref, 10, repeat),
                                            {next_state, revive, NewState#mon_act{ref = Ref1}};
                                        true -> 
                                            %% 怪物采集次数-1 
                                            NewMinfo = Minfo#ets_mon{collect_times = Minfo#ets_mon.collect_times + 1},
                                            lib_mon:insert(NewMinfo),
                                            {next_state, StateName, State#mon_act{minfo = NewMinfo}}
                                    end;
                                false -> 
                                    {next_state, StateName, State}
                            end
                    end
            end
    end;

%% 停止采集怪 
%% Key = [Id, Platform, ServerNum]
handle_info({'stop_collect', Key}, StateName, State) -> 
    NewClist = lists:keydelete(Key, 1, State#mon_act.clist),
    {next_state, StateName, State#mon_act{clist = NewClist}};


%%记录战斗结果
handle_info({'battle_info', BattleReturn}, StateName, State) -> 
    Minfo = State#mon_act.minfo,
    Ref = State#mon_act.ref,
    case Minfo#ets_mon.hp > 0 of
        true ->
            case set_state_after_battle(BattleReturn, State, StateName) of
                {'EXIT', R} ->
                    util:errlog("=====MON_DIE=====:~p", [R]),
                    Ref1 = send_event_after(Ref, 10, repeat),
                    {next_state, revive, State#mon_act{ref = Ref1}};
                Rs ->
                    Rs
            end;
        false ->
            Ref1 = send_event_after(Ref, 10, repeat),
            {next_state, revive, State#mon_act{ref = Ref1}}
    end;

%% 清除进程
handle_info(clear, _StateName, State) ->
    NewState = cancle_special_event(State), %% 停止怪物特殊事件
    Minfo = NewState#mon_act.minfo,
    lib_mon:delete(Minfo),
    case Minfo#ets_mon.boss == 3 of %% 世界boss死亡后清理整个场景的ai
        true -> lib_mon:del_ai(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id);
        false -> skip
    end,
    {stop, normal, NewState};

%% 清除进程
handle_info(clear_broadcast, _StateName, State) ->
    NewState = cancle_special_event(State), %% 停止怪物特殊事件
    Minfo = NewState#mon_act.minfo,
    lib_mon:delete(Minfo),
    case Minfo#ets_mon.boss == 3 of %% 世界boss死亡后清理整个场景的ai
        true -> lib_mon:del_ai(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id);
        false -> skip
    end,
    {ok, BinData} = pt_120:write(12006, [Minfo#ets_mon.id]),
    broadcast(Minfo, BinData),
    {stop, normal, NewState};

%% 减HP
handle_info({last_change_hp, Int, Float}, StateName, State) ->
    Minfo = State#mon_act.minfo,
    %% 先判断是否已经死亡
    case Minfo#ets_mon.hp > 0 andalso Minfo#ets_mon.kind /= 7 andalso Minfo#ets_mon.kind /= 11 andalso Minfo#ets_mon.kind /= 10 of
        true ->
            HpMin = max(1, round(Minfo#ets_mon.hp + Minfo#ets_mon.hp_lim * Float + Int)), %% 保证有最小值1
            HpMax = min(Minfo#ets_mon.hp_lim, HpMin),
            case HpMax < 0 of
                true ->
                    Minfo1 = Minfo#ets_mon{hp = 1}; %% 不致死
                false ->
                    Minfo1 = Minfo#ets_mon{hp = HpMax}       
            end,

            %% 城战城门更新血量
            %CityWarSceneId = data_city_war:get_city_war_config(scene_id),
            %if 
            %    Minfo1#ets_mon.scene == CityWarSceneId -> 
            %        mod_city_war:update_door_blood([Minfo1#ets_mon.id, Minfo1#ets_mon.hp, Minfo1#ets_mon.hp_lim, Minfo1#ets_mon.mid]);
            %    true -> skip
            %end,

            %% 触发血量AI
            {NewState, NewStateName} = lib_mon_ai:hp_change(Minfo#ets_mon.hp, Minfo1#ets_mon.hp, State#mon_act{minfo = Minfo1}, StateName),
            NewMinfo = NewState#mon_act.minfo,
            lib_mon:insert(NewMinfo),
            %%  广播给附近玩家
            {ok, BinData} = pt_120:write(12081, [NewMinfo#ets_mon.id, NewMinfo#ets_mon.hp]),
            broadcast(NewMinfo, BinData),
            case StateName /= NewStateName of
                true -> 
                    Ref1 = send_event_after(State#mon_act.ref, 10, repeat),
                    {next_state, StateName, NewState#mon_act{ref = Ref1}};
                false -> 
                    {next_state, StateName, NewState}
            end;
        false ->
            {next_state, StateName, State}
    end;

%% 怪物超时
handle_info('die', StateName, State) ->
    Minfo = State#mon_act.minfo,
    lib_mon_ai:die(State, StateName),
    %% 怪物消失
    {ok, BinData} = pt_120:write(12006, [Minfo#ets_mon.id]),
    broadcast(Minfo, BinData),
    lib_mon:insert(Minfo#ets_mon{hp=0}),
    lib_dungeon:kill_npc(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, [Minfo#ets_mon.mid], Minfo#ets_mon.boss, Minfo#ets_mon.id, 0),
    Ref1 = send_event_after(State#mon_act.ref, 10, repeat),
    {next_state, revive, State#mon_act{ref = Ref1}};

%% 随机移动
handle_info({'auto_move'}, sleep, State) ->
    Minfo = State#mon_act.minfo,
    case Minfo#ets_mon.kind == 2 orelse Minfo#ets_mon.kind == 7 of
        true  -> {next_state, sleep, State};
        false -> auto_move(State#mon_act.minfo, State)
    end;

%% 直接清除怪物, 不重生, 不执行lib_mon_ai:die
handle_info(remove, _StateName, State) ->
    Minfo = State#mon_act.minfo,
    % 怪物消失
    {ok, BinData} = pt_120:write(12006, [Minfo#ets_mon.id]),
    broadcast(Minfo, BinData),
    lib_dungeon:kill_npc(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, [Minfo#ets_mon.mid], Minfo#ets_mon.boss, Minfo#ets_mon.id, 0),
    handle_info(clear, null, State#mon_act{att=[], minfo=Minfo, klist=[], clist = [], ref=[], eref=[]});

%% 指示怪物攻击某目标
%% Id:   怪物/玩家唯一id
%% Pid:  怪物/玩家进程id
%% Sign: 1怪物; 2玩家
handle_info({'ATTACK_ONE', [Key, Pid, Sign]}, _StateName, State) ->
    Ref = send_event_after(State#mon_act.ref, 100, repeat),
    {next_state, trace, State#mon_act{att = [Key, Pid, Sign], ref = Ref}};

%% 指示怪物攻击某目标一次(用于模拟战斗 -- 人控制怪物攻击一次)
%% Key:   怪物/玩家唯一key
%% Type:  被攻击者类型 1是怪物 2是人
handle_info({'ATTACK_ONCE', Type, Key, SkillId}, _StateName, State) ->
    Minfo = State#mon_act.minfo,
    {next_state, _, NewState} = trace(repeat, State#mon_act{minfo = Minfo#ets_mon{skill=[{SkillId,100}]}, att=[Key, 0, Type]}),
    NewMinfo = NewState#mon_act.minfo,
    {next_state, sleep, NewState#mon_act{att = [], minfo = NewMinfo#ets_mon{skill=[]}}};

%% 指示怪物寻找可攻击对象攻击
handle_info({'FIND_PLAYER_FOR_BATTLE', AttTarget}, StateName, State) -> 
    #ets_mon{scene = Scene, mid = Mid} = Minfo = State#mon_act.minfo,
    if
        Scene == 234 orelse Scene == 235 ->
            case lib_mon:get_area_mon_id_aid_mid(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y, Minfo#ets_mon.trace_area, Minfo#ets_mon.group) of
                [[MId, MAid, _MMid]|_] ->
                    Ref = send_event_after(State#mon_act.ref, 1000, repeat),
                    {next_state, trace, State#mon_act{att = [MId, MAid, 1], ref = Ref}};
                _ -> {next_state, StateName, State}
            end;
        Mid > 10606 andalso Mid < 10611 -> %% 帮派战 助手 
            %% 找特定的怪物攻击(金角大王)
            case lib_mon:get_scene_mon_by_mids(Scene, Minfo#ets_mon.copy_id, [10604], all) of
                [DefMon|_] -> 
                    Ref = send_event_after(State#mon_act.ref, 1000, repeat),
                    {next_state, trace, State#mon_act{att = [DefMon#ets_mon.id, DefMon#ets_mon.aid, 1], ref = Ref}};
                _ -> {next_state, StateName, State}
            end;
        true -> 
            case AttTarget of
                [_Key, _Pid, _Sign] -> 
                    {NewState, StateName2} = lib_mon_ai:state_change(State, trace),
                    Ref = case StateName /= StateName2 of
                        true  -> send_event_after(NewState#mon_act.ref, 100, repeat);
                        false -> NewState#mon_act.ref
                    end,
                    {next_state, StateName2, NewState#mon_act{att = AttTarget, ref = Ref}};
                _ -> 
                    case lib_mon_ai:get_player_for_att(Scene, Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y, Minfo#ets_mon.trace_area + 2, Minfo#ets_mon.group) of
                        skip -> {next_state, StateName, State};
                        [] ->   {next_state, StateName, State};
                        [Player | _] ->
                            {NewState, StateName2} = lib_mon_ai:state_change(State, trace),
                            case NewState#mon_act.minfo == Minfo of
                                true -> skip;
                                false -> lib_mon:insert(NewState#mon_act.minfo)
                            end,
                            Ref = case StateName /= StateName2 of
                                true  -> send_event_after(NewState#mon_act.ref, 100, repeat);
                                false -> NewState#mon_act.ref
                            end,
                            {next_state, StateName2, NewState#mon_act{att = [[Player#ets_scene_user.id, Player#ets_scene_user.platform, Player#ets_scene_user.server_num], Player#ets_scene_user.pid, 2], ref = Ref}}
                    end
            end
    end;

%% 处理由场景返回的战斗信息
handle_info({"att_info_back", Result}, StateName, State) when StateName /= walk_rand, StateName /= walk ->
    #mon_act{minfo = Minfo, ref = Ref, ready_ref=ReadyRef} = State,
    cancel_timer(ReadyRef),
    AttSpeed = case Minfo#ets_mon.att_speed =:= 0 of
        true ->
            1000;
        false->
            Minfo#ets_mon.att_speed
    end,
    {NewStateName, NewState} = case Result of
        %% 施放完主动技能
        {true, {Hp, BattleStatus, X, Y, SkillCdList}} ->
            MinfoBattle = Minfo#ets_mon{
                hp = Hp,
                x  = X,
                y  = Y,
                battle_status = BattleStatus,
                skill_cd = SkillCdList
            },
            lib_mon:insert(MinfoBattle),
            Ref1 = send_event_after(Ref, AttSpeed*2, repeat),
            {trace, State#mon_act{minfo = MinfoBattle, ref = Ref1}};
        %% 施放完辅助技能
        {true, SkillCdList} when is_list(SkillCdList)->
            MinfoBattle = Minfo#ets_mon{
                skill_cd = SkillCdList
            },
            lib_mon:insert(MinfoBattle),
            Ref1 = send_event_after(Ref, AttSpeed*2, repeat),
            {trace, State#mon_act{minfo = MinfoBattle, ref = Ref1}};
        %% 施放技能不成功
        {false, _ErrCode} ->
            Ref1 = send_event_after(Ref, 2000, repeat),
            {trace, State#mon_act{ref = Ref1}};
        %% 其他错误
        Error ->
            util:errlog("=====MON_DIE_FOR_TRACE==id:~p =skill:~p =error:=~p", [Minfo#ets_mon.mid, Minfo#ets_mon.skill, Error]),
            Ref1 = send_event_after(Ref, 10, repeat),
            {back, State#mon_act{ref = Ref1}}
    end,
    NewStateName1 = if
        StateName == walk orelse StateName == check orelse StateName == walk_td orelse StateName == walk_rand -> StateName;
        true -> NewStateName
    end,
    StateName1 = after_trace_state(Minfo#ets_mon.ai_type, NewStateName1),
    {next_state, StateName1, NewState};

%% 处理由场景返回怪物追踪目标信息
handle_info({"trace_info_back", _AttType, Result}, _StateName, State) ->
    #mon_act{minfo=Minfo, ref=Ref, ready_ref=ReadyRef} = State,
    cancel_timer(ReadyRef),
    {NewStateName, NewState} = case Result of
        false -> %% 找不到目标，原地静止3.5秒，此3.5秒期间有玩家攻击就会反击
            Ref1 = send_event_after(Ref, 3500, repeat),
            {back, State#mon_act{att = [], ref = Ref1}};
        {true, X, Y, _Hp, Atter} -> %% 目标找到
            %% 技能处理
            {SkillId, SkillLv, SkillType, SkillArea} = mon_use_skill(Minfo),

            case SkillType of
                3 -> %% 辅助技能直接释放
                    mod_scene_agent:apply_cast(Minfo#ets_mon.scene, lib_battle, mon_assist_skill, [Minfo, Atter, SkillId, SkillLv]),
                    ReadyRef1 = send_event_after([], 5000, timeout),
                    {att_ready, State#mon_act{ready_ref=ReadyRef1}};
                2 -> %% 被动技能不能释放
                    util:errlog("mod_mon_active ERROR: msg='att_target_info' skill_type error, mid = ~p, skill_id = ~p~n", [Minfo#ets_mon.mid, SkillId]),
                    Ref1 = send_event_after(Ref, 1000, repeat),
                    {trace, State#mon_act{ref = Ref1}};
                _ -> %% 攻击技能
                    %% 判断是否可以攻击
                    case is_attack(Minfo, X, Y, SkillArea) of
                        attack -> % 可以进行攻击了
                            mod_scene_agent:apply_cast(Minfo#ets_mon.scene, lib_battle, mon_active_skill, [Minfo, Atter, SkillId, SkillLv]),
                            ReadyRef1 = send_event_after([], 5000, timeout),
                            {att_ready, State#mon_act{ready_ref=ReadyRef1}};
                        trace -> % 还不能进行攻击就追踪他
                            case trace_line(Minfo#ets_mon.x, Minfo#ets_mon.y, X, Y, Minfo#ets_mon.att_area) of
                                {X1, Y1} ->
                                    case handle_battle_status(Minfo) of
                                        {ok, Minfo1, AfterCountSpeed} ->
                                            case move(X1, Y1, State#mon_act{minfo = Minfo1}, AfterCountSpeed) of
                                                {true, AfterMoveMinfo, NextTime} -> %% 可移动
                                                    Ref1 = send_event_after(Ref, NextTime, repeat),
                                                    {trace, State#mon_act{minfo = AfterMoveMinfo, ref = Ref1}};
                                                block -> %% 被障碍物挡住不能追踪了
                                                    %% 直接传送到目标位置
                                                    Minfo2 = Minfo1#ets_mon{x=X, y=Y},
                                                    lib_mon:insert(Minfo2),
                                                    Ref1 = send_event_after(Ref, 1000, repeat),
                                                    {trace, State#mon_act{minfo = Minfo2, ref = Ref1}};
                                                false -> %% 不可移动
                                                    Ref1 = send_event_after(Ref, 3500, repeat),
                                                    {back, State#mon_act{minfo = Minfo1, ref = Ref1}}
                                            end;
                                        {false, Minfo2} -> 
                                            Ref1 = send_event_after(Ref, 1000, repeat),
                                            {trace, State#mon_act{minfo = Minfo2, ref = Ref1}}
                                    end; 
                                true ->
                                    Ref1 = send_event_after(Ref, 3500, repeat),
                                    {trace, State#mon_act{att = [], ref = Ref1}}
                            end;
                        back -> %停止追踪
                            case handle_battle_status(Minfo) of
                                {ok, Minfo1, _AfterCountSpeed} ->
                                    Ref1 = send_event_after(Ref, 500, repeat),
                                    {back, State#mon_act{att = [], minfo = Minfo1, ref = Ref1}};
                                {false, Minfo2} ->
                                    Ref1 = send_event_after(Ref, 1000, repeat),
                                    {trace, State#mon_act{minfo = Minfo2, ref = Ref1}}
                            end; 
                        die -> %死亡
                            Ref1 = send_event_after(Ref, 100, repeat),
                            {revive, State#mon_act{att = [], ref = Ref1}}
                    end
            end
    end,
    StateName1 = after_trace_state(Minfo#ets_mon.ai_type, NewStateName),
    {next_state, StateName1, NewState};

%% 辅助技能buff回写
handle_info({'BATTLE_STATUS', BattleStatus}, StateName, Status) -> 
    Minfo    = Status#mon_act.minfo,
    NewMinfo = Minfo#ets_mon{battle_status = BattleStatus},
    lib_mon:insert(NewMinfo),
    {next_state, StateName, Status#mon_act{minfo = Minfo}};

handle_info(_Info, StateName, Status) ->
    {next_state, StateName, Status}.

terminate(normal, _StateName, _Status) ->
    cancle_special_event(_Status),
    ok;
terminate(Reason, _StateName, _Status) ->
    cancle_special_event(_Status),
    util:errlog("mod_mon_active is terminate:~p~n", [Reason]),
    ok.

code_change(_OldVsn, StateName, Status, _Extra) ->
    {ok, StateName, Status}.

%% =========处理怪物所有状态=========

%%静止状态并回血
sleep(_R, State) ->
    Minfo = State#mon_act.minfo,
    Ref = State#mon_act.ref,
    %%判断是否死亡
    case Minfo#ets_mon.hp > 0 of
        true ->
            case lists:member(Minfo#ets_mon.scene, [234,235]) of %% 塔防怪物处理
                true ->
                    case lib_mon:get_area_mon_id_aid_mid(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y, Minfo#ets_mon.trace_area, Minfo#ets_mon.group) of
                        [[MId, MAid, _MMid]|_] ->
                            Ref1 = send_event_after(Ref, 1000, repeat),
                            {next_state, trace, State#mon_act{att = [MId, MAid, 1], klist = [], clist = [], ref = Ref1}};
                        _ ->
                            Ref1 = send_event_after(Ref, 3500, repeat), 
                            {next_state, sleep, State#mon_act{att = [], klist = [], clist = [], ref = Ref1}}
                    end;
                false -> 
                    case Minfo#ets_mon.kind == 0 of
                        true -> %% 怪物
                            [Type, Minfo1]  = auto_revert(Minfo),
                            %% 状态处理
                            NewKlist = case Minfo#ets_mon.boss == 4 of %% 帮派boss不清理伤害列表
                                true -> State#mon_act.klist;
                                false -> []
                            end,
                            case Type == 1 of
                                true -> %% 自动回复血量
                                    Ref1 = send_event_after(Ref, ?RETIME, repeat),
                                    {next_state, sleep, State#mon_act{att = [], minfo = Minfo1, klist = NewKlist, ref = Ref1}};
                                false -> 
                                    {next_state, sleep, State#mon_act{att = [], minfo = Minfo, klist = NewKlist}}
                            end;
                        false -> %%采集物品，或者旗子
                            {next_state, sleep, State#mon_act{att = [], minfo = Minfo, ref = Ref}}
                    end
            end;
        false ->
            Ref1 = send_event_after(Ref, 10, repeat),
            {next_state, revive, State#mon_act{att = [], minfo = Minfo, ref = Ref1}}
    end.

%% 塔防trace
trace_td(_R, State) ->  
    Minfo = State#mon_act.minfo,
    Ref = State#mon_act.ref,
    case get_td_mon_att_object(Minfo, State) of
        true -> 
            trace(repeat, State);
        false -> 
            Ref1 = send_event_after(Ref, 1000, repeat),
            {next_state, walk_td, State#mon_act{ref = Ref1}};
        NewState -> 
            trace(repeat, NewState)
    end.

%% 等待场景返回怪物追踪目标信息
trace_ready(timeout, State) -> 
    Ref1 = send_event_after(State#mon_act.ref, 1000, repeat),
    {next_state, back, State#mon_act{ref = Ref1}};
trace_ready(_, State) -> 
    {next_state, trace_ready, State}.

%% 等待场景返回怪物攻击结果
att_ready(timeout, State) -> 
    Ref1 = send_event_after(State#mon_act.ref, 1000, repeat),
    {next_state, back, State#mon_act{ref = Ref1}};
att_ready(_, State) -> 
    {next_state, att_ready, State}.

%% 跟踪目标
trace(_R, State) when State#mon_act.att /= [] ->
    [Key, _Pid, AttType] = State#mon_act.att,
    Minfo = State#mon_act.minfo,
    case AttType == 2 of
        true -> 
            mod_scene_agent:apply_cast(Minfo#ets_mon.scene, lib_scene_agent, get_att_target_info_by_id, [[Minfo#ets_mon.aid, Key, AttType, Minfo#ets_mon.group]]);
        false -> 
            mod_mon_agent:apply_cast(Minfo#ets_mon.scene, lib_mon_agent, get_att_target_info_by_id, [[Minfo#ets_mon.aid, Key, AttType, Minfo#ets_mon.group]]) 
    end,
    ReadyRef = send_event_after(State#mon_act.ready_ref, 15000, timeout),
    {next_state, trace_ready, State#mon_act{ready_ref=ReadyRef}};

trace(_R, State) ->
    Minfo  = State#mon_act.minfo,
    StateName = after_trace_state(Minfo#ets_mon.ai_type, back),
    Ref1 = send_event_after(State#mon_act.ref, 10, repeat),
    {next_state, StateName, State#mon_act{ref = Ref1}}.

%% 不能跟踪后转换的状态
%% after_trace_state(怪物AI类型, 转换前状态) -> 转换后状态
%% 怪物AI类型 = 1(塔防)
after_trace_state(1, sleep)  -> walk_td;
after_trace_state(1, back)   -> walk_td;
after_trace_state(1, revive) -> revive;
after_trace_state(1, trace)  -> trace_td;
after_trace_state(_, SN)     -> SN.


%%返回默认出生点
back(_R, State) ->
    [Minfo, Ref] = [State#mon_act.minfo, State#mon_act.ref],
    case Minfo#ets_mon.hp =< 0 of
        true ->
            State1 = cancle_special_event(State), 
            Ref1 = send_event_after(Ref, 100, repeat),
            {next_state, revive, State1#mon_act{att = [], ref = Ref1, eref = []}};
        false -> 
            case Minfo#ets_mon.x == Minfo#ets_mon.d_x andalso Minfo#ets_mon.y == Minfo#ets_mon.d_y of
                false -> 
                    Status1 = Minfo#ets_mon{
                        x = Minfo#ets_mon.d_x,
                        y = Minfo#ets_mon.d_y
                    },
                    mon_move(Minfo#ets_mon.x, Minfo#ets_mon.y, Status1),
                    State1 = cancle_special_event(State#mon_act{minfo = Status1}), 
                    lib_mon:insert(State1#mon_act.minfo),
                    NewState = State1;
                true -> 
                    State1 = cancle_special_event(State),
                    lib_mon:insert(State1#mon_act.minfo),
                    NewState = State1
            end,
            Ref1 = send_event_after(Ref, 100, repeat),
            {next_state, sleep, NewState#mon_act{att = [], ref = Ref1, eref = []}}
    end.

%%复活
revive(start, State) ->
    Minfo = State#mon_act.minfo,
    if
        Minfo#ets_mon.retime == 0 -> %% 不重生关闭怪物进程
            handle_info(clear, null, State#mon_act{att=[], minfo=Minfo, klist=[], clist = [], ref=[], eref=[]});
        true ->
            if
                Minfo#ets_mon.collect_count > 0 andalso Minfo#ets_mon.collect_times+1 == Minfo#ets_mon.collect_count andalso Minfo#ets_mon.kind == 0 -> 
                    handle_info(clear, null, State#mon_act{att=[], minfo=Minfo, klist=[], clist = [], ref=[], eref=[]});
                true -> 
                    NewCollectTimes = if
                        Minfo#ets_mon.collect_count > 0 andalso Minfo#ets_mon.kind == 0 -> Minfo#ets_mon.collect_times + 1;
                        true -> 0
                    end,
                    Status1 = Minfo#ets_mon{
                        hp = Minfo#ets_mon.hp_lim,
                        mp = Minfo#ets_mon.mp_lim,
                        x = Minfo#ets_mon.d_x,
                        y = Minfo#ets_mon.d_y,
                        collect_times = NewCollectTimes
                    },
                    %%通知客户端我已经重生了
                    {ok, BinData} = pt_120:write(12007, Status1),
                    broadcast(Status1, BinData),

                    lib_mon:insert(Status1),
                    %% 塔防怪物重新要重新寻找攻击目标
                    case lists:member(Status1#ets_mon.scene, [234,235]) of
                        true ->
                            case lib_mon:get_area_mon_id_aid_mid(Status1#ets_mon.scene, Status1#ets_mon.copy_id, Status1#ets_mon.x, Status1#ets_mon.y, Status1#ets_mon.trace_area, Status1#ets_mon.group) of
                                [] -> 
                                    {next_state, sleep, State#mon_act{att = [], minfo = Status1, klist = [], clist = [], ref = []}};
                                [[MId, MAid, _MMid]|_] ->
                                    Ref = send_event_after(State#mon_act.ref, 1000, repeat),
                                    {next_state, trace, State#mon_act{att = [MId, MAid, 1], minfo = Status1, klist = [], clist = [], ref = Ref}}
                            end;
                        false -> 
                            {next_state, sleep, State#mon_act{att = [], minfo = Status1, klist = [], clist = [], ref = []}}
                    end
            end
    end;

revive(_R, State) ->
    Minfo = State#mon_act.minfo,
    Ref = State#mon_act.ref,
    if
        Minfo#ets_mon.mid >= 35006 andalso Minfo#ets_mon.mid =< 35009 -> %% 等待消息再复活 
            {next_state, revive, State#mon_act{att=[],klist=[],ref=[]}};
        Minfo#ets_mon.mid >= 36006 andalso Minfo#ets_mon.mid =< 36009 -> %% 等待消息再复活 
            {next_state, revive, State#mon_act{att=[],klist=[],ref=[]}};
        Minfo#ets_mon.retime == 0 ->
            handle_info(clear, null, State#mon_act{att=[],klist=[],ref=[]});
        true ->
            send_event_after(Ref, Minfo#ets_mon.retime, start),
            {next_state, revive, State#mon_act{att=[],klist=[],ref=[]}}
    end.

%% 塔防怪物状态
walk_td(_R, State) -> 
    Minfo = State#mon_act.minfo,
    Ref = State#mon_act.ref,
    [X, Y, _AttList] = Minfo#ets_mon.ai_option,
    case abs(X - Minfo#ets_mon.x) > Minfo#ets_mon.att_area orelse abs(Y - Minfo#ets_mon.y) > Minfo#ets_mon.att_area of %% 走到目的地
        false -> 
            Ref1 = send_event_after(Ref, 2500, repeat),
            {next_state, trace_td, State#mon_act{ref = Ref1}};
        true -> 
            [New_x, New_y] = get_next_step(Minfo#ets_mon.x, Minfo#ets_mon.y, Minfo#ets_mon.att_area, Minfo#ets_mon.scene, X, Y),
            case handle_battle_status(Minfo) of
                {ok, Minfo2, NewSpeed} ->
                    NewMinfo2 = Minfo2#ets_mon{d_x = New_x, d_y = New_y},
                    case move(New_x, New_y, State#mon_act{minfo = NewMinfo2}, NewSpeed) of
                        {true, AfterMoveMinfo, NextTime} -> %% 可移动
                            case New_x < 36 andalso New_y < 51 of
                                true -> 
                                    Ref1 = send_event_after(Ref, NextTime, repeat),
                                    {next_state, trace_td, State#mon_act{minfo = AfterMoveMinfo, ref = Ref1}};
                                false -> 
                                    Ref1 = send_event_after(Ref, NextTime, repeat),
                                    {next_state, walk_td, State#mon_act{minfo = AfterMoveMinfo, ref = Ref1}}
                            end;
                        _ -> %% 不可移动
                            Ref1 = send_event_after(Ref, 1000, repeat),
                            NewState = State#mon_act{minfo = NewMinfo2, ref = Ref1},
                            {next_state, walk_td, NewState}
                    end;
                {false, Minfo4} ->
                    Ref1 = send_event_after(Ref, 3500, repeat),
                    {next_state, walk_td, State#mon_act{minfo = Minfo4, ref = Ref1}}
            end
    end.

%% 始:帮派镖车及迎亲巡游相关状态-----------------------------------------------
%% 走路
walk(_R, State) -> 
    Minfo = State#mon_act.minfo,
    Ref = State#mon_act.ref,
    case Minfo#ets_mon.path of
        [] ->
            %% 行走完路径，查看走完路径的walk_end_ai
            {NewState, NewStateName} = lib_mon_ai:walk_end(State, revive),
            case NewStateName == revive of
                true -> 
                    % 怪物消失
                    {ok, BinData} = pt_120:write(12006, [Minfo#ets_mon.id]),
                    broadcast(Minfo, BinData),
                    Ref1 = send_event_after(Ref, 10, repeat), 
                    {next_state, revive, State#mon_act{ref = Ref1}};
                false -> 
                    %% 被walk_end_ai更改状态了，转入新状态
                    Ref1 = send_event_after(Ref, 10, repeat),
                    {next_state, NewStateName, NewState#mon_act{ref = Ref1}}
            end;
        [{SceneId, NewX, NewY}|RemainPath] ->
            X = Minfo#ets_mon.x,
            Y = Minfo#ets_mon.y,
            if
                (Minfo#ets_mon.mid == 43406 orelse Minfo#ets_mon.mid == 43407 orelse Minfo#ets_mon.mid ==  43408) andalso ({X, Y} == {160,180} orelse {X, Y} == {129,127} orelse {X, Y} == {84,101}) andalso _R /= "go" ->
                    Ref1 = send_event_after(Ref, 60*1000, "go"), 
                    {next_state, walk, State#mon_act{ref = Ref1}};
                true -> 
                    case SceneId =/= Minfo#ets_mon.scene of
                        true -> 
                            %% 切换怪物场景
                            NewMinfo = Minfo#ets_mon{scene = SceneId, x = NewX, y = NewY},
                            lib_mon:guild_biao_enter_scene(Minfo, NewMinfo),
                            % 有怪物进入
                            {ok, BinData2} = pt_120:write(12007, NewMinfo),
                            broadcast(NewMinfo, BinData2),
                            % 怪物消失
                            {ok, BinData} = pt_120:write(12006, [Minfo#ets_mon.id]),
                            broadcast(Minfo, BinData),
                            Ref1 = send_event_after(Ref, 10, repeat),
                            {next_state, walk, State#mon_act{minfo=NewMinfo#ets_mon{path = RemainPath}, ref=Ref1}};
                        false -> %% 继续走
                            case handle_battle_status(Minfo) of
                                {ok, Minfo1, AfterCountSpeed} ->
                                    case move(NewX, NewY, State#mon_act{minfo = Minfo1}, AfterCountSpeed) of
                                        {true, AfterMoveMinfo, NextTime} -> %% 可移动
                                            Ref1 = send_event_after(Ref, NextTime, repeat),
                                            {next_state, walk, State#mon_act{minfo = AfterMoveMinfo#ets_mon{path = RemainPath, d_x=NewX, d_y=NewY}, ref = Ref1}};
                                        _ -> %% 不可移动
                                            Ref1 = send_event_after(Ref, 3500, repeat),
                                            {next_state, walk, State#mon_act{minfo = Minfo1, ref = Ref1}}
                                    end;
                                {false, Minfo2} ->
                                    Ref1 = send_event_after(Ref, 1000, repeat),
                                    {next_state, walk, State#mon_act{minfo = Minfo2, ref = Ref1}}
                            end
                    end
            end
    end.

%% 检查怪物是否可继续移动
check(_R, #mon_act{minfo=Minfo, ref=Ref} = State) ->
    Minfo = State#mon_act.minfo,
    Ref   = State#mon_act.ref,
    if
        Minfo#ets_mon.mid == 98102 orelse Minfo#ets_mon.mid == 98103 orelse Minfo#ets_mon.mid == 98104 orelse Minfo#ets_mon.mid == 37158 ->
            %% 拯救唐小僧中封印水晶
            case mod_scene_agent:apply_call(Minfo#ets_mon.scene, lib_scene_agent, get_scene_user_id_pid_area, [Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y, Minfo#ets_mon.att_area]) of
                [] -> 
                    Minfo1 = Minfo#ets_mon{hp=Minfo#ets_mon.hp_lim},
                    case Minfo1#ets_mon.hp /= Minfo#ets_mon.hp of
                        true -> 
                            {ok, BinData} = pt_120:write(12081, [Minfo1#ets_mon.id, Minfo1#ets_mon.hp]),
                            broadcast(Minfo1, BinData);
                        false -> skip
                    end,
                    NewState = cancle_special_event(State#mon_act{minfo = Minfo1});
                _ -> 
                    {NewState, _} = lib_mon_ai:state_change(State, check)
            end,
            lib_mon:insert(NewState#mon_act.minfo),
            Ref1 = send_event_after(Ref, 5000, repeat),
            {next_state, check, NewState#mon_act{ref = Ref1}};
        true ->
            {next_state, sleep, State}
    end.

%% 随机移动状态
walk_rand(_R, State) ->
    Minfo = State#mon_act.minfo,
    Rand = util:rand(1, 8),
    if
        Rand == 1 ->
            X = Minfo#ets_mon.x + 2,
            Y = Minfo#ets_mon.y;
        Rand == 2 ->
            X = Minfo#ets_mon.x,
            Y = Minfo#ets_mon.y+2;
        Rand == 3 ->
            X = abs(Minfo#ets_mon.x - 2),
            Y = Minfo#ets_mon.y;
        Rand == 4 ->
            X = Minfo#ets_mon.x,
            Y = abs(Minfo#ets_mon.y - 2);
        Rand == 5 ->
            X = abs(Minfo#ets_mon.x - 2),
            Y = Minfo#ets_mon.y + 2;
        Rand == 6 ->
            X = abs(Minfo#ets_mon.x - 2),
            Y = abs(Minfo#ets_mon.y - 2);
        Rand == 7 ->
            X = Minfo#ets_mon.x + 2,
            Y = Minfo#ets_mon.y + 2;
        true ->
            X = Minfo#ets_mon.x + 2,
            Y = abs(Minfo#ets_mon.y - 2)
    end,
    case move(X, Y, State, Minfo#ets_mon.speed) of
        {true, NewMinfo, Time} -> 
            Ref = send_event_after([], Time, repeat),
            {next_state, walk_rand, State#mon_act{minfo=NewMinfo, ref=Ref}};
        _ -> 
            Ref = send_event_after([], 3000, repeat),
            {next_state, walk_rand, State#mon_act{ref=Ref}}
    end.

%% 判断距离是否可以发动攻击了
is_attack(Status, X, Y, SkillAttArea) ->
    D_x = abs(Status#ets_mon.x - X),
    D_y = abs(Status#ets_mon.y - Y),
    Att_area = case  SkillAttArea == 0 of
        true  -> Status#ets_mon.att_area;
        false -> SkillAttArea
    end,
    case Status#ets_mon.hp > 0  of
        true ->
            case Att_area>= D_x of
                true ->
                    case Att_area>= D_y of
                        true  -> attack;
                        false -> trace_area(Status, X, Y)
                    end;
                false -> trace_area(Status, X, Y)
            end;
        false -> die
    end.

%% 追踪区域
trace_area(Status, X, Y) ->
    Trace_area = Status#ets_mon.trace_area,
    D_x = abs(Status#ets_mon.d_x - X),
    D_y = abs(Status#ets_mon.d_y - Y),
    %不在追踪范围内了停止追踪
    case  Trace_area+2 >= D_x of
        true ->
            case Trace_area+2 >= D_y of
                true ->
                    trace;
                false ->
                    back
            end;
        false ->
            back
    end.

%%先进入曼哈顿距离遇到障碍物再转向A*
%%每次移动2格
%%X1,Y1 原位置
%%X2,Y2 目标位置
trace_line(X1, Y1, X2, Y2, AttArea) ->
    MoveArea = 2,
    %%先判断方向
    if 
        %目标在正下方
        X2 == X1 andalso Y2 - Y1 > 0 ->
            Y = Y2 - Y1,
            if 
                Y =< MoveArea ->
                    {X1, Y2-AttArea};
                true ->
                    {X1, Y1+MoveArea}
            end;

        %目标在正上方
        X2 == X1 andalso Y2 - Y1 < 0 ->
            Y = abs(Y2 - Y1),
            if 
                Y =< MoveArea ->
                    {X1, Y2+AttArea};
                true ->
                    {X1, Y1-MoveArea}
            end;

        %目标在正左方
        X2 - X1 < 0 andalso Y2 == Y1 ->
            X = abs(X2 - X1),
            if 
                X =< MoveArea ->
                    {X2+AttArea, Y1};
                true ->
                    {X1-MoveArea, Y1}
            end; 

        %目标在正右方
        X2 - X1 > 0 andalso Y2 == Y1 ->
            X = X2 - X1,
            if 
                X =< MoveArea ->
                    {X2-AttArea, Y1};
                true ->
                    {X1+MoveArea, Y1}
            end; 

        %目标在左上方
        X2 - X1 < 0 andalso Y2 - Y1 < 0 ->
            Y = abs(Y2 - Y1),
            X = abs(X2 - X1),
            if 
                Y =< MoveArea ->
                    if 
                        X =< MoveArea -> {X2+AttArea, Y2+AttArea};
                        true -> {X1-MoveArea, Y2+AttArea}
                    end;
                true ->
                    if
                        X =< MoveArea -> {X2+AttArea, Y1-MoveArea};
                        true -> {X1-MoveArea, Y1-MoveArea}
                    end
            end;

        %目标在左下方
        X2 - X1 < 0 andalso Y2 - Y1 > 0 ->
            Y = Y2 - Y1,
            X = abs(X2 - X1),
            if 
                Y =< MoveArea ->
                    if
                        X =< MoveArea -> {X2+AttArea, Y2-AttArea};
                        true -> {X1-MoveArea, Y2-AttArea}
                    end;
                true ->
                    if
                        X =< MoveArea -> {X2+AttArea, Y1+MoveArea};
                        true -> {X1-MoveArea, Y1+MoveArea}
                    end
            end;

        %目标在右上方
        X2 - X1 > 0 andalso Y2 - Y1 < 0 ->
            Y = abs(Y2 - Y1),
            X = X2 - X1,
            if 
                Y =< MoveArea ->
                    if
                        X =< MoveArea -> {X2-AttArea, Y2+AttArea};
                        true -> {X1+MoveArea, Y2+AttArea}
                    end;
                true ->
                    if
                        X =< MoveArea -> {X2-AttArea, Y1-MoveArea};
                        true -> {X1+MoveArea, Y1-MoveArea}
                    end
            end;

        %目标在右下方
        X2 - X1 > 0 andalso Y2 - Y1 > 0 ->
            Y = Y2 - Y1,
            X = X2 - X1,
            if 
                Y =< MoveArea ->
                    if
                        X =< MoveArea -> {X2-AttArea, Y2-AttArea};
                        true -> {X1+MoveArea, Y2-AttArea}
                    end;
                true ->
                    if
                        X =< MoveArea -> {X2-AttArea, Y1+MoveArea};
                        true -> {X1+MoveArea, Y1+MoveArea}
                    end
            end;

        true ->
            true
    end.

% A星算法自动寻路
get_next_step(X, Y, AttArea, Sid, A_x, A_y) ->
    case [X, Y] =:= [A_x, A_y] of
        true ->
            [X, Y];
        _ ->
            case trace_line(X, Y, A_x, A_y, AttArea) of
                true ->
                    a_star(X, Y, Sid, AttArea, A_x, A_y);
                {N_x, N_y} ->
                    case lib_scene:is_blocked(Sid, N_x, N_y) of
                        false ->
                            [N_x, N_y];
                        _ ->
                            a_star(X, Y, Sid, AttArea, A_x, A_y)
                    end
            end
    end.

%% A*算法
a_star(X, Y, Sid, _, A_x, A_y) ->
    List = [[X+1, Y],
        [X, Y+1],
        [X-1, Y],
        [X, Y-1],
        [X+1, Y+1],
        [X-1, Y+1],
        [X+1, Y-1],
        [X-1, Y+1]], %% 周围8格子
    F = fun(P, _P0) ->
            [X2, Y2] = P,
            case lib_scene:is_blocked(Sid, X2, Y2) of
                false ->
                    %非障碍点
                    [X1, Y1] = _P0,
                    [X2, Y2] = P,
                    Dis1 = abs(X1 - A_x)*abs(X1 - A_x) + abs(Y1 - A_y)*abs(Y1 - A_y),
                    Dis2 = abs(X2 - A_x)*abs(X2 - A_x) + abs(Y2 - A_y)*abs(Y2 - A_y),
                    case (Dis2 =< Dis1 orelse [X, Y] =:= _P0) of
                        true ->
                            {P, P};
                        _ ->
                            {P, _P0}
                    end;
                _ ->
                    {P, _P0}
            end
    end,
    %障碍点筛选
    P0 = [X, Y],
    {_, P1} = lists:mapfoldl(F, P0, List),
    P1.

%%怪物移动 
move(X, Y, State, Speed) ->
    Minfo= State#mon_act.minfo,
    Path = Minfo#ets_mon.path,
    IsBlocked = case Minfo#ets_mon.path of
        [] -> 
            %没有预设路径要判断是否障碍物 -> true | false
            lib_scene:is_blocked(Minfo#ets_mon.scene, X, Y);
        _  -> false % 无障碍物
    end,
    case IsBlocked orelse Minfo#ets_mon.mid == 43406 orelse Minfo#ets_mon.mid == 43407 orelse Minfo#ets_mon.mid == 43408 of
        true  -> block; 
        false -> 
            if
                Speed == 0 -> false;
                true -> 
                    Dis = case Path of
                        [] -> 
                            abs(X - Minfo#ets_mon.x)*60 + abs(Y - Minfo#ets_mon.y)* 30; %% 运算更快
                        _  -> 
                            util:ceil(math:sqrt(math:pow((X - Minfo#ets_mon.x)*60, 2) + math:pow((Y - Minfo#ets_mon.y)* 30, 2))) %% 走路更加圆滑
                    end,
                    Status1 = Minfo#ets_mon{
                        x = X,
                        y = Y
                    },
                    mon_move(Minfo#ets_mon.x, Minfo#ets_mon.y, Status1),
                    lib_mon:insert(Status1), %% 同步怪物状态
                    Time = case Dis == 0 of
                        true -> 10;
                        false -> round(Dis * 1000 / Speed)
                    end,
                    {true, Status1, Time}
            end
    end.

%%随机移动
auto_move(Minfo, State) ->
    case Minfo#ets_mon.kind =:= 10 of
        true ->
            OutDic = 3,
            Dic = 3;
        false ->
            OutDic = 0,
            Dic = 1 
    end,
    case abs(Minfo#ets_mon.x - Minfo#ets_mon.d_x) > OutDic orelse abs(Minfo#ets_mon.y - Minfo#ets_mon.d_y) > OutDic of
        false ->
            Rand = util:rand(1, 8),
            if
                Rand == 1 ->
                    X = Minfo#ets_mon.x + Dic,
                    Y = Minfo#ets_mon.y;
                Rand == 2 ->
                    X = Minfo#ets_mon.x,
                    Y = Minfo#ets_mon.y+Dic;
                Rand == 3 ->
                    X = abs(Minfo#ets_mon.x - Dic),
                    Y = Minfo#ets_mon.y;
                Rand == 4 ->
                    X = Minfo#ets_mon.x,
                    Y = abs(Minfo#ets_mon.y - Dic);
                Rand == 5 ->
                    X = abs(Minfo#ets_mon.x - Dic),
                    Y = Minfo#ets_mon.y + Dic;
                Rand == 6 ->
                    X = abs(Minfo#ets_mon.x - Dic),
                    Y = abs(Minfo#ets_mon.y - Dic);
                Rand == 7 ->
                    X = Minfo#ets_mon.x + Dic,
                    Y = Minfo#ets_mon.y + Dic;
                true ->
                    X = Minfo#ets_mon.x + Dic,
                    Y = abs(Minfo#ets_mon.y - Dic)
            end;
        true ->
            X = Minfo#ets_mon.d_x,
            Y = Minfo#ets_mon.d_y
    end,
    %判断是否障碍物
    case lib_scene:is_blocked(Minfo#ets_mon.scene, X, Y) of
        true ->
            Ref = send_event_after([], ?MOVE_TIME, repeat),
            {next_state, sleep, State#mon_act{att=[], minfo=Minfo, ref=Ref}};
        false ->
            case trace_area(Minfo, X, Y) of
                trace ->
                    Status1 = Minfo#ets_mon{
                        x = X,
                        y = Y
                    },
                    mon_move(Minfo#ets_mon.x, Minfo#ets_mon.y, Status1),
                    lib_mon:insert(Status1),
                    Ref = send_event_after([], ?MOVE_TIME + ?MOVE_TIME * (Status1#ets_mon.id rem 10), repeat),
                    {next_state, sleep, State#mon_act{att=[], minfo=Status1, ref=Ref}};
                _ ->
                    Ref = send_event_after([], 1000, repeat),
                    {next_state, sleep, State#mon_act{att=[], minfo=Minfo, ref=Ref}}
            end
    end.

%% 自动回复血和蓝
auto_revert(Minfo) ->
    case Minfo#ets_mon.hp_num =:= 0 orelse Minfo#ets_mon.hp >= Minfo#ets_mon.hp_lim of
        true ->
            [0, Minfo];
        false ->
            %%判断是否超过气血上限
            CurHp = Minfo#ets_mon.hp + Minfo#ets_mon.hp_num,
            if
                CurHp < Minfo#ets_mon.hp_lim ->
                    Status1 =  Minfo#ets_mon{
                        hp = CurHp
                    };
                true ->
                    Status1 =  Minfo#ets_mon{
                        hp = Minfo#ets_mon.hp_lim
                    }
            end,

            %%判断是否超过内力上限
            CurMp = Status1#ets_mon.mp + Status1#ets_mon.mp_num,
            if
                CurMp >= Status1#ets_mon.mp_lim ->
                    Status2 =  Status1#ets_mon{
                        mp = CurMp
                    };
                true ->
                    Status2 =  Status1#ets_mon{
                        mp = Status1#ets_mon.mp_lim
                    }
            end,
            %%  广播给附近玩家
            {ok, BinData} = pt_120:write(12081, [Status2#ets_mon.id, Status2#ets_mon.hp]),
            broadcast(Status2, BinData),
            lib_mon:insert(Status2),
            [1, Status2]
    end.

%%处理状态
handle_battle_status(Minfo) ->
    case Minfo#ets_mon.battle_status /= [] of
        true->
            %% 加减速
            MonBaseSpeed = Minfo#ets_mon.speed,
            Time = util:longunixtime(),
            {NewBattleStatus, Speed, Sign} = mod_battle:check_speed_buff(MonBaseSpeed, Minfo#ets_mon.battle_status, Time),

            %% 是否需要广播速度
            case Sign == 0 of
                true -> skip;
                false -> lib_scene:change_speed(Minfo#ets_mon.id, "", 0, Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y, Speed, 1)
            end,
            %% 是否是定身
            case Speed > 5 of
                true -> 
                    {NewBattleStatus2, Yun} = mod_battle:check_special_state(yun, NewBattleStatus, Time),
                    {NewBattleStatus3, Bind}= mod_battle:check_special_state(bind, NewBattleStatus2, Time),
                    case Yun > 0 orelse Bind > 0 of
                        false -> {ok, Minfo#ets_mon{battle_status = NewBattleStatus3}, Speed};
                        true  -> {false, Minfo#ets_mon{battle_status = NewBattleStatus3}}
                    end;
                false -> 
                    {false, Minfo#ets_mon{battle_status = NewBattleStatus}}
            end; 
        false -> {ok, Minfo, Minfo#ets_mon.speed}
    end.

%% 加入仇恨列表
add_hatred_list(Klist, Pid, Val, Key, PidTeam)->
    case lists:keyfind(Key, 3, Klist) of
        false ->
            [{Pid, Val, Key, PidTeam}|Klist];
        {_, Val0, _, _} ->
            Klist1 = lists:keydelete(Key, 3, Klist),
            [{Pid, Val0+Val, Key, PidTeam}|Klist1]
    end.

%%计算仇恨列表
calc_hatred_list([], Pid, _Val) ->
    Pid;
calc_hatred_list([{Pid0, Val0, _, _} | T], Pid, Val)->
    if
        Val0 > Val ->
            calc_hatred_list(T, Pid0, Val0);
        true ->
            calc_hatred_list(T, Pid, Val)
    end.

%% 按队伍调整伤害列表(同一队里面只有队伍里面伤害最大的人存在于伤害列表中)
team_sort_klist({_, _, _, _}=List) -> List;
team_sort_klist(List) -> 
    team_sort_klist(List, []).

team_sort_klist([], List) -> lists:keysort(2, List);
team_sort_klist([{Pid, Val, Key, PidTeam}|T], List) ->
    case is_pid(PidTeam) of
        true -> 
            case lists:keyfind(PidTeam, 4, List) of
                false -> team_sort_klist(T, [{Pid, Val, Key, PidTeam}|List]);
                {Pid0, Val0, Key0, _} -> 
                    case Val0 > Val of
                        true ->  
                            List1 = lists:keyreplace(Pid0, 1, List, {Pid0, Val0+Val, Key0, PidTeam});
                        false -> 
                            List1 = lists:keyreplace(Pid0, 1, List, {Pid,  Val0+Val, Key,  PidTeam})
                    end,
                    team_sort_klist(T, List1)
            end;
        false -> 
            team_sort_klist(T, [{Pid, Val, Key, PidTeam}|List])
    end.

%% 提取仇恨列表中的id
%klist_to_ids([], PlayerIds) ->
%    PlayerIds;
%klist_to_ids([{_, _, [Id|_], _} | T], PlayerIds)->
%    klist_to_ids(T, [Id|PlayerIds]);
%klist_to_ids([_|T], PlayerIds) -> klist_to_ids(T, PlayerIds).

%%发送定时器
send_event_after(Ref, Time, State) ->
    cancel_timer(Ref),
    gen_fsm:send_event_after(Time, State).

%% 取消定时器
cancel_timer(Ref) when is_reference(Ref) -> gen_fsm:cancel_timer(Ref);
cancel_timer(_) -> ok.

%%怪物移动
%%Q:情景
mon_move(X, Y, S) ->
    mon_walk_ai(S#ets_mon.scene, S#ets_mon.copy_id, S#ets_mon.x, S#ets_mon.y, S#ets_mon.id, S#ets_mon.aid, S#ets_mon.group),
    % 告诉玩家有怪物移动
    {ok, BinData}  = pt_120:write(12008, [S#ets_mon.x, S#ets_mon.y, S#ets_mon.id]),
    % 告诉玩家有怪物被移除
    {ok, BinData1} = pt_120:write(12006, [S#ets_mon.id]),
    % 告诉玩家有怪物进入
    {ok, BinData2} = pt_120:write(12007, S),
    case lib_scene:is_broadcast_scene(S#ets_mon.scene) of
        true ->
            lib_server_send:send_to_scene(S#ets_mon.scene, S#ets_mon.copy_id, BinData);
        false ->
            mod_scene_agent:apply_cast(S#ets_mon.scene, lib_scene_calc, move_broadcast, [S#ets_mon.scene, S#ets_mon.copy_id, S#ets_mon.x, S#ets_mon.y, X, Y, BinData, BinData1, BinData2, []])
    end.

%% 怪物使用技能 -> {SkillId, SkillLv, SkillData#player_skill.type, SkillData#player_skill.att_area}
mon_use_skill(Minfo) ->
    %% 是否已经有需要释放的技能
    case Minfo#ets_mon.now_skill of
        {SkillId, SkillLv, SkillType, SkillArea} when SkillId /= 0 -> {SkillId, SkillLv, SkillType, SkillArea};
        _ -> 
            %% 随机一个 
            case Minfo#ets_mon.skill of
                [] -> {?MON_BASE_SKILL_ID, ?MON_BASE_SKILL_LV, 1, 0};
                SkillList -> 
                    Sum = mon_use_skill_sum(SkillList, 0),
                    Pos = util:rand(1, Sum),
                    case mon_use_skill_helper(SkillList, Pos, 0) of
                        false      -> {?MON_BASE_SKILL_ID, ?MON_BASE_SKILL_LV, 1, 0};
                        SkillTuple -> SkillTuple
                    end
            end
    end.

%% 根据技能列表权值随机到一个，且获取技能信息
mon_use_skill_helper([], _Pos, _PercentSum) -> false;
mon_use_skill_helper([{SkillId, SkillLv, Percentage} | SkillList], Pos, PercentSum) -> 
    case Pos =< Percentage+PercentSum of
        true  ->
            case data_skill:get(SkillId, SkillLv) of
                [] -> false;
                SkillData -> 
                    {SkillId, SkillLv, SkillData#player_skill.type, SkillData#player_skill.data#skill_lv_data.distance}
            end;
        false -> mon_use_skill_helper(SkillList, Pos, PercentSum+Percentage)
    end.

%% 计算总权值
mon_use_skill_sum([], Sum) -> Sum;
mon_use_skill_sum([{_, _, Percentage} | SkillList], Sum) -> mon_use_skill_sum(SkillList, Sum + Percentage).

%% 生成属性
create_attr(M, Lv) ->
    IsArenaMon = lists:member(M#ets_mon.mid, data_arena_new:get_npc_type_id()),
    if
        %% 创建南天门怪物
        M#ets_mon.scene =:= 420 andalso Lv /= 0 ->
            M#ets_mon{
                att    = round(M#ets_mon.att*Lv*Lv/175),
                def    = round(M#ets_mon.def*Lv*Lv/175),
                fire   = round(M#ets_mon.fire*Lv*Lv/175),
                ice    = round(M#ets_mon.ice*Lv*Lv/175),
                drug   = round(M#ets_mon.drug*Lv*Lv/175),
                lv     = Lv,
                hp     = round(M#ets_mon.hp*Lv*Lv*Lv*(Lv/40-(Lv-40)/150)/150),
                hp_lim = round(M#ets_mon.hp_lim*Lv*Lv*Lv*(Lv/40-(Lv-40)/150)/150),
                exp    = round(M#ets_mon.exp*Lv*Lv/100),
                llpt   = round(M#ets_mon.llpt*Lv/100),
                hit    = round(M#ets_mon.hit*Lv*Lv/100),
                dodge  = round(M#ets_mon.dodge*Lv*Lv/100),
                crit   = round(M#ets_mon.crit*Lv*Lv/100),
                ten    = round(M#ets_mon.ten*Lv*Lv/100)
            };
        %% 竞技场守护神攻击和血量
        IsArenaMon =:= true andalso Lv =/= 0 ->
            [Att, Hp] = data_arena_new:get_hpatt_by_world_lv(M, Lv),
            M#ets_mon{
                att = Att,
                hp = Hp,
                hp_lim = Hp
            };
        M#ets_mon.auto =:= 1 andalso Lv /= 0 ->
            M#ets_mon{
                att    = round(M#ets_mon.att*Lv*Lv/100),
                def    = round(M#ets_mon.def*Lv*Lv/100),
                fire   = round(M#ets_mon.fire*Lv*Lv/100),
                ice    = round(M#ets_mon.ice*Lv*Lv/100),
                drug   = round(M#ets_mon.drug*Lv*Lv/100),
                lv     = Lv,
                hp     = round(M#ets_mon.hp*Lv*Lv*Lv*(Lv/40-(Lv-40)/150)/100),
                hp_lim = round(M#ets_mon.hp_lim*Lv*Lv*Lv*(Lv/40-(Lv-40)/150)/100),
                exp    = round(M#ets_mon.exp*Lv*Lv/100),
                llpt   = round(M#ets_mon.llpt*Lv/100),
                hit    = round(M#ets_mon.hit*Lv*Lv/100),
                dodge  = round(M#ets_mon.dodge*Lv*Lv/100),
                crit   = round(M#ets_mon.crit*Lv*Lv/100),
                ten    = round(M#ets_mon.ten*Lv*Lv/100)
            };
        true -> %% 正常怪
            M
    end.

%%取消事件
cancle_special_event(State) ->
    {LastState, _} = lib_mon_ai:resume(State),
    LastState.



%% ===========人工智能=============
insert_for_ai(Aid, SceneId, CopyId, X, Y) ->
    X1 = case X - ?SCAN >= 0 of
        true ->
            X - ?SCAN;
        false ->
            0
    end,
    Y1 = case Y - ?SCAN >= 0 of
        true ->
            Y - ?SCAN;
        false ->
            0
    end,
    loop_post_x(X1, X + ?SCAN, Y1, Y + ?SCAN, Aid, SceneId, CopyId).

loop_post_x(M, M, Y, Y1, Aid, SceneId, CopyId) ->
    loop_post_y(M, Y, Y1, Aid, SceneId, CopyId);
loop_post_x(X, M, Y, Y1, Aid, SceneId, CopyId) ->
    loop_post_y(X, Y, Y1, Aid, SceneId, CopyId),
    loop_post_x(X+1, M, Y, Y1, Aid, SceneId, CopyId).

loop_post_y(X, M, M, Aid, SceneId, CopyId) ->
    inert_post_aid(Aid, SceneId, CopyId, X, M);
loop_post_y(X, Y, M, Aid, SceneId, CopyId) ->
    inert_post_aid(Aid, SceneId, CopyId, X, Y),
    loop_post_y(X, Y+1, M, Aid, SceneId, CopyId).

inert_post_aid(Aid, SceneId, CopyId, X, Y) ->
    lib_mon_agent:put_ai(SceneId, CopyId, X, Y, Aid).

%% 玩家走路ai触发
mon_ai(Scene, CopyId, X, Y, Key, Pid) ->
    case CopyId =/= 0 orelse lists:member(Scene, [400, 401, 402, 403, 404, 405, 406, 410, 411, 412, 413, 109]) of 
        true -> 
            List = lib_mon:get_ai(Scene, CopyId, X, Y),
            [Aid ! {'ai', Key, Pid, 2, 0}  || Aid <- List]; %% 数字2表示是玩家走路
        false ->
            skip
    end.

%% 怪物走路ai触发(必须得有分组属性)
mon_walk_ai(Scene, CopyId, X, Y, Id, Pid, Group) ->
    case lists:member(Scene, [234,235]) andalso Group /= 0 of 
        true ->
            List = case lib_mon:get_ai(Scene, CopyId, X, Y) of
                skip -> [];
                Other -> Other
            end,
            [Aid ! {'ai', Id, Pid, 1, Group}  || Aid <- List]; %% 数字1表示是怪物走路
        false ->
            skip
    end.

%% 直接走怪物掉落
make_mon_drop(Id, Platform, ServerNum, Pid, SceneId, MonId) ->
    case lib_mon:lookup(SceneId, MonId) of
        [] -> skip;
        Minfo -> mon_drop(Minfo, [], {[Id, Platform, ServerNum], Pid}, Id)
    end.

%% @spec
%% 怪物掉落
%% @end
mon_drop(Mon, Klist, {Key1, Att1}, Att2) ->
    %% 异界入侵任务
    % [PlayerId, _PlatForm, _ServerNum] = Key1,
    % mod_invade:kill_a_mon([PlayerId, Mon#ets_mon.mid, Mon#ets_mon.scene, Klist, Mon#ets_mon.hp_lim, Mon#ets_mon.x, Mon#ets_mon.y]),

    case lib_scene:is_clusters_scene(Mon#ets_mon.scene) of
        true -> 
            lib_mon_die:execute_any_fun_clusters(Mon, Klist, {Key1, Att1}); %% 跨服场景中
        false -> 
            gen_server:cast(Att1, {'drop', [{Mon#ets_mon.id, Mon#ets_mon.mid, Mon#ets_mon.scene, 
                            Mon#ets_mon.copy_id, Mon#ets_mon.x, Mon#ets_mon.y,
                            Mon#ets_mon.exp, Mon#ets_mon.lv, Mon#ets_mon.drop_num, Mon#ets_mon.group, Mon#ets_mon.skip}, Klist, Att1, Att2]})
    end.

%% 获取塔防类型怪物的攻击对象
get_td_mon_att_object(Minfo, State) ->
    IsFind = if
        Minfo#ets_mon.x < 17 andalso Minfo#ets_mon.y < 32 -> true;
        true ->
            case State#mon_act.att of
                [_, _, _] -> false;
                [] -> true
            end
    end,
    case IsFind of
        false -> State;
        true -> 
            [_X, _Y, AttList] = Minfo#ets_mon.ai_option,
            AttType = case State#mon_act.att of
                [] -> 0;
                [_, _, AT] -> AT
            end,
            SceneMon = case lib_mon:get_area_mon_id_aid_mid(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y, Minfo#ets_mon.trace_area, Minfo#ets_mon.group) of
                Other when is_list(Other) -> Other;
                _ -> []
            end,
            {AList, AType} = get_td_mon_for_battle(AttList, SceneMon, Minfo, AttType),
            ALen = length(AList),
            if
                ALen == 0 andalso AType == 2 -> true; %% 让其继续攻击玩家
                ALen == 0 -> false;
                ALen == 1 ->
                    case AType of
                        1 -> %% 怪物
                            [[AttId, AttPid]] = AList,
                            State#mon_act{att = [AttId, AttPid, 1]};
                        2 -> %% 玩家
                            [[AttId, AttPid]] = AList,
                            State#mon_act{att = [AttId, AttPid, 2]}
                    end;
                true -> 
                    Att = lists:nth(util:rand(1, ALen), AList), %% 随机一个攻击者
                    case AType of
                        1 -> %% 怪物
                            [AttId, AttPid] = Att,
                            State#mon_act{att = [AttId, AttPid, 1]};
                        2 -> %% 玩家
                            [AttId, AttPid] = Att,
                            State#mon_act{att = [AttId, AttPid, 2]}
                    end
            end
    end.

%% 获取场景内可攻击的怪物
%% Mid 需攻击的怪物id
%% SceneMon 可被攻击到的怪物列表
%% MInfo  塔防怪物
get_td_mon_for_battle([], _SceneMon, _Minfo, _AttType) -> {[], 0};
get_td_mon_for_battle([Mid|T], SceneMon, Minfo, AttType) when Mid == 0 ->
    case AttType == 2 of
        true -> {[], 2};
        false ->
            case mod_scene_agent:apply_call(Minfo#ets_mon.scene, lib_scene_agent, get_scene_user_id_pid_area, [Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y,  Minfo#ets_mon.trace_area]) of
                skip -> get_td_mon_for_battle(T, SceneMon, Minfo, AttType);
                [] ->   get_td_mon_for_battle(T, SceneMon, Minfo, AttType);
                PlayerIdPidList -> {PlayerIdPidList, 2}
            end
    end;
get_td_mon_for_battle([Mid|T], SceneMon, Minfo, AttType) -> 
    PrecList = [[Id0, Pid0]||[Id0, Pid0, Mid0]<-SceneMon, Mid0 == Mid],
    case PrecList of
        [] -> get_td_mon_for_battle(T, SceneMon, Minfo, AttType);
        _  -> {PrecList, 1}
    end.

%% 设置#ets_mon{}中的属性值和进程状态值
set_mon([], M, StateName) -> {M, StateName};
set_mon([H|T], M, StateName) -> 
    LastM = case H of
        {auto_lv, Lv}               -> create_attr(M, Lv);
        {group, Group}              -> M#ets_mon{group = Group};
        {owner_id, OwnerId}         -> M#ets_mon{owner_id = OwnerId};
        {mon_name, MonName}         -> case MonName == [] of true -> M; false -> M#ets_mon{name = MonName} end;
        {color, MonColor}           -> M#ets_mon{color = MonColor};
        {ai_mon, AiOption}          -> M#ets_mon{ai_type = 1, ai_option = AiOption};
        {drop_num, DropNum}         -> M#ets_mon{drop_num = DropNum};
        {auto_att, AttTarget}       -> self() ! {'FIND_PLAYER_FOR_BATTLE', AttTarget}, M;
        {change_player_id, Value}   -> M#ets_mon{change_player_id = Value};
        %% 跳层属性
        {skip, Value}               -> M#ets_mon{skip = Value};
        {hp, Value} when is_float(Value)->  M#ets_mon{hp = trunc(M#ets_mon.hp_lim * Value)};
        {hp, Value}                 -> M#ets_mon{hp = Value};
        {collect_count, Value}      -> M#ets_mon{collect_count = Value};
        %% 技能[{技能id, 技能等级, 概率}...]
        {skill, Skill} when is_list(Skill) -> M#ets_mon{skill = Skill};
        {change_name, Name}         -> %% 怪物名字
            NewM = M#ets_mon{name = Name},
            {ok, BinData} = pt_120:write(12007, NewM),
            broadcast(NewM, BinData),
            NewM;
        {skill_owner, SkillOwner}   -> M#ets_mon{skill_owner = SkillOwner};
        {att, Att}                  -> M#ets_mon{att = Att};
        {walk, EndX, EndY}          -> 
            Path = lib_mon_ai:dest_path(M#ets_mon.x, M#ets_mon.y, EndX, EndY, M#ets_mon.scene),
            M#ets_mon{path = Path};
        {exp_dun, Level}            -> lib_exp_dungeon:create_mon_attr(M, Level);
        {change_exp, ExpR}          -> M#ets_mon{exp = round(M#ets_mon.exp*ExpR)};
        %% 改变形象 
        {change_icon, Icon}         -> 
            {ok, BinData} = pt_120:write(12098, [M#ets_mon.id, Icon]),
            lib_server_send:send_to_area_scene(M#ets_mon.scene, M#ets_mon.copy_id, M#ets_mon.x, M#ets_mon.y, BinData),
            M#ets_mon{icon = Icon};
        {lv, Lv}                    -> M#ets_mon{lv = Lv};
        {hp_lim, Value}             -> M#ets_mon{hp_lim = Value};
        {def, Value} 				-> M#ets_mon{def = Value};				%% 防御
        {hit, Value} 				-> M#ets_mon{hit = Value};				%% 命中
        {dodge, Value} 				-> M#ets_mon{dodge = Value};			%% 躲避
        {crit, Value} 				-> M#ets_mon{crit = Value};				%% 暴击
        {ten, Value}    			-> M#ets_mon{ten = Value};	    		%% 坚韧
        {fire, Value}    			-> M#ets_mon{fire = Value};	    		%% 坚韧
        {ice, Value}    			-> M#ets_mon{ice = Value};	    		%% 坚韧
        {drug, Value}    			-> M#ets_mon{drug = Value};	    		%% 坚韧
        {speed, Value} 				-> M#ets_mon{speed = Value};			%% 移动速度
        {type, Value} 				-> M#ets_mon{type = Value};				%% 怪物战斗类型（0被动，1主动）
        {att_type, Value} 			-> M#ets_mon{att_type = Value};			%% 0近战，1远程
        {trace_area, Value}			-> M#ets_mon{trace_area = Value};		%% 追踪范围
        {is_be_atted, Value}        -> M#ets_mon{is_be_atted = Value};		%% 是否能被攻击(0:不可以, 1:可以)
        {exp, Value}                -> M#ets_mon{exp = Value};		        %% 经验值
        {shunyi, X, Y} 				-> %% 瞬移
            {ok, BinData} = pt_120:write(12035, [X, Y, M#ets_mon.id]),
            lib_server_send:send_to_scene(M#ets_mon.scene, M#ets_mon.copy_id, BinData),
            % lib_server_send:send_to_area_scene(M#ets_mon.scene, M#ets_mon.copy_id, M#ets_mon.x, M#ets_mon.y, BinData),
            M#ets_mon{x = X, y = Y};
        _                           -> M
    end,
    NewStateName = case H of
        {state, State} -> State;
        _ -> StateName
    end,
    set_mon(T, LastM, NewStateName).

%% 怪物信息广播
broadcast(Minfo, BinData) -> 
    case lib_scene:is_broadcast_scene(Minfo#ets_mon.scene) of
        true ->
            lib_server_send:send_to_scene(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, BinData);
        false ->
            lib_server_send:send_to_area_scene(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, Minfo#ets_mon.x, Minfo#ets_mon.y, BinData)
    end.


%% 怪物死亡后的处理
execute_any_fun_after_mon_die(BattleReturn, State) -> 
    #battle_return{atter = Atter} = BattleReturn, %% 战斗返回信息
    #battle_return_atter{id = NewAttId, platform = Platform, server_num = ServerNum, pid = NewAttPid} = Atter,%% 导致怪物死亡的攻击者信息
    #mon_act{minfo = Minfo, klist = Klist, last_att_player_id = LastAtterId} = State, %% 怪物状态
    #ets_mon{owner_id = OwnerId, boss = Boss} = Minfo, %% 怪物信息
    if
        OwnerId > 0 andalso Boss > 0 -> %% 如果怪物有所属，则掉落直接归所属者
            case lib_player:get_player_info(OwnerId, pid) of
                false -> skip;
                OwnerPid -> 
                    mon_drop(Minfo, [{OwnerPid, 0, [OwnerId,0,0], 0}], {[OwnerId,0,0], OwnerPid}, OwnerPid)
            end;
        LastAtterId > 0 andalso Boss > 0 -> 
            case lib_player:get_player_info(LastAtterId, pid) of
                false -> skip;
                LastAtterPid ->
                    mon_drop(Minfo, Klist, {[LastAtterId,0,0], LastAtterPid}, LastAtterPid)
            end;
        true -> 
            mon_drop(Minfo, Klist, {[NewAttId,Platform,ServerNum], NewAttPid}, NewAttId)
    end,
    lib_dungeon:kill_npc(Minfo#ets_mon.scene, Minfo#ets_mon.copy_id, [Minfo#ets_mon.mid], Minfo#ets_mon.boss, Minfo#ets_mon.id, 0),

    ok.

%% 怪物被攻击
set_state_after_battle(BattleReturn, State, StateName) -> 
    #battle_return{
        hp = Hp,
        hurt = Hurt,
        x = X,
        y = Y,
        battle_status = BattleStates,
        hate  = Hate,
        atter = Atter,
        sign  = Sign, %% 1：怪物， 2：人
        is_calc_hurt = IsCalcHurt
    } = BattleReturn,
    #battle_return_atter{id = NewAttId, platform = Platform, server_num = ServerNum, pid = NewAttPid, pid_team = PidTeam} = Atter,
    #mon_act{minfo = Minfo, ref = Ref, klist = Klist} = State,

    if 
        Hp =< 0 -> 
            NewMinfo = Minfo#ets_mon{hp = 0},
            {NewState, _} = lib_mon_ai:die(State#mon_act{minfo = NewMinfo}, StateName),
            lib_mon:insert(NewMinfo),
            execute_any_fun_after_mon_die(BattleReturn, NewState),
            Ref1 = send_event_after(Ref, 100, repeat),
            {next_state, revive, NewState#mon_act{ref = Ref1}};
        true -> 
            %% 人和怪的Key不一样 
            NewAttKey = case Sign of
                1 -> NewAttId;
                _ -> [NewAttId, Platform, ServerNum]
            end,

            %% 如果攻击者是人，就加入伤害列表里面
            Klist1 = case Sign of
                1 -> Klist;
                2 -> add_hatred_list(Klist, NewAttPid, Hurt, NewAttKey, PidTeam)
            end,
            Minfo1 = Minfo#ets_mon{
                hp = Hp,
                x = X,
                y = Y,
                battle_status = BattleStates
            },

            %% 第一个攻击怪物的人
            FirstAtter = case State#mon_act.first_att of
                [] -> 
                    % 触发第一次被攻击事件
                    [NewAttKey, NewAttPid, Sign];
                _  -> State#mon_act.first_att
            end,

            State1 = State#mon_act{minfo = Minfo1, klist = Klist1, first_att = FirstAtter},
            %% 血量ai
            {State2, StateName2} = lib_mon_ai:hp_change(Minfo#ets_mon.hp, Minfo1#ets_mon.hp, State1, trace),
            %% 状态改变ai
            {State3, StateName3} = lib_mon_ai:state_change(State2, StateName2),

            lib_mon:insert(State3#mon_act.minfo),
            if
                Minfo1#ets_mon.kind == 7 -> 
                    execute_any_fun_after_mon_die(BattleReturn, State1),
                    {next_state, StateName, State3};
                Minfo1#ets_mon.is_fight_back == 1 -> %% 是否反击
                    State4 = if
                        %% 不算伤害则不攻击目标(暂定字段)
                        IsCalcHurt == 0 -> 
                            State3; 
                        % 如果没攻击对象转移攻击对象
                        State1#mon_act.att == [] -> 
                            State3#mon_act{att = [NewAttKey, NewAttPid, Sign]};
                        %% 有仇恨值，转移攻击目标
                        Hate > 0 -> 
                            State3#mon_act{att = [NewAttKey, NewAttPid, Sign]};
                        %% 维持原样
                        true -> 
                            State3
                    end,
                    if
                        %% 不算伤害，不改变状态
                        IsCalcHurt == 0 -> 
                            {next_state, StateName, State4};
                        %% 状态被更改了，使用新状态
                        StateName3 /= trace ->
                            Ref1 = send_event_after(Ref, 100, repeat), 
                            {next_state, StateName3, State4#mon_act{ref = Ref1}};

                        %% 状态没有被改变，一般处理，转入trace
                        StateName /= trace       andalso 
                        StateName /= trace_td    andalso 
                        StateName /= trace_ready andalso 
                        StateName /= att_ready   ->  
                            %% 400毫秒反应时间
                            Ref1 = send_event_after(Ref, 400, repeat), 
                            {next_state, trace, State4#mon_act{ref = Ref1}};

                        %% 其余怪物，保持现状
                        true -> 
                            {next_state, StateName, State4}
                    end;

                %% 其余不反击的怪物，保持现状
                true -> 
                    {next_state, StateName, State3}
            end
    end.
