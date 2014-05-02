%%%-----------------------------------
%%% @Module  : lib_skill
%%% @Author  : zzm
%%% @Created : 2013.12.2
%%% @Description: 技能
%%%-----------------------------------
-module(lib_skill).
-include("common.hrl").
-include("server.hrl").
-include("skill.hrl").
-include("sql_skill.hrl").
-include("scene.hrl").
-export(
    [
        online/2,							%% 玩家登录加载技能数据
        add_ex_skill/2,
        add_pet_skill/2,
        del_pet_skill/2,
        del_all_pet_skill/1,
        get_all_skill/2,
        upgrade_skill/4,
        use_skill_book/3,
        get_skill_add_attr/2,
        update_skill_sql_by_id/3,
        update_skill_attribute_for_ps/1,
        tranc_skill_attr/2,
        special_skill/1,
        special_skill/2,
        goods_skill/2,
        interrupt_combo_skill/1
    ]
).

-define(ORIGINAL_ANGER, 12).

%% 获得默认技能id
get_default_skill(Career) ->
    case Career of
        1 -> ?WARRIOR_BASE_SKILL_ID;
        2 -> ?MAGE_MON_BASE_SKILL_ID;
        3 -> ?ASSASIN_BASE_SKILL_ID;
        _ -> ?MON_BASE_SKILL_ID
    end.

%% 重新计算技能属性
%% 返回 : #player_status
update_skill_attribute_for_ps(PS) ->
    Sk = PS#player_status.skill,
    % SkillList = Sk#status_skill.skill_list ++ Sk#status_skill.medal_skill,
    SkillList = Sk#status_skill.skill_list,
    Data = [data_skill:get(SkillId, SkillLv)|| {SkillId, SkillLv} <- SkillList],
    {BattleStatus, SkillAttribute, AngerLim} = tranc_skill_attr(Data, {PS#player_status.battle_status, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], ?ORIGINAL_ANGER}),
    PS#player_status{
        anger_lim = AngerLim, 
        skill = Sk#status_skill{skill_attribute = SkillAttribute}, 
        battle_status = BattleStatus
    }.


%% 玩家登录加载技能数据
online(Id, Career) ->
    Skill = get_all_skill(Id, Career),
    {BattleStatus, SkillAttribute, AngerLim} = get_skill_add_attr(Skill, []),
    {Skill, BattleStatus, SkillAttribute, AngerLim}.

%% 获取所有技能
get_all_skill(Id, Career) ->
    SkillList = db:get_all(io_lib:format(?sql_get_all_skill, [Id])),
    case SkillList of
        [] ->
            SkillId = get_default_skill(Career),
            case data_skill:get(SkillId, 1) of
                [] -> [];
                _Skill -> 
                    db:execute(io_lib:format(?sql_insert_skill, [Id, SkillId, 1])),
                    [{SkillId, 1}]
            end;
        _ ->
            [begin 
                        case data_skill:get(SkillId, SkillLv) of
                            [] -> {1, 0};
                            _Skill -> {SkillId, SkillLv}
                        end
                end || [SkillId, SkillLv] <- SkillList]
    end.

%% 获取被动技能加成值
get_skill_add_attr(SkillList, BattleStatus) ->
    Data = [data_skill:get(SkillId, SkillLv) || {SkillId, SkillLv} <- SkillList],
    tranc_skill_attr(Data, {BattleStatus, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], ?ORIGINAL_ANGER}).

%% 宠物技能相关
%% 增加
%% SkillList = list() = [{SkillId, SkillLv}, ...]
add_pet_skill(Status, SkillList) -> 
    NewExBattleStatus = add_ex_skill(SkillList, Status#player_status.ex_battle_status),
    NewStatus = Status#player_status{ex_battle_status = NewExBattleStatus},
    mod_scene_agent:update(battle_attr, NewStatus),
    NewStatus.

%% 删除
del_pet_skill(Status, SkillId) -> 
    NewExBattleStatus = lib_skill_buff:clear_ex_buff(Status#player_status.ex_battle_status, SkillId, []),
    NewStatus = Status#player_status{ex_battle_status = NewExBattleStatus},
    mod_scene_agent:update(battle_attr, NewStatus),
    NewStatus.

%% 全删除
del_all_pet_skill(Status) -> 
    NewStatus = Status#player_status{ex_battle_status =[]},
    mod_scene_agent:update(battle_attr, NewStatus),
    NewStatus.

%% 额外技能(宠物等)
%% SL:[{SkillId, SkillLv}, ...]
add_ex_skill([], ExBattleStatus) -> ExBattleStatus;
add_ex_skill([{SkillId, SkillLv} | SL], ExBattleStatus) ->
    NewExBS = case data_skill:get(SkillId, SkillLv) of
        [] -> ExBattleStatus;
        Skill -> 
            [_, _ | SkillData] = Skill#player_skill.data,
            pack_ex_skill_battle_status(SkillData, ExBattleStatus, SkillId, SkillLv)
    end,
    add_ex_skill(SL, NewExBS).

pack_ex_skill_battle_status([], ExBS, _SkillId, _SkillLv) -> ExBS;
pack_ex_skill_battle_status([{K, V} | SkillData], ExBattleStatus, SkillId, SkillLv) -> 
    NewExBS = case lists:keyfind({K, SkillId}, 3, ExBattleStatus) of
        false -> [{K, SkillId, {K, SkillId}, SkillLv, 0, V} | ExBattleStatus];
        _ ->     [{K, SkillId, {K, SkillId}, SkillLv, 0, V} | lists:keydelete({K, SkillId}, 3, ExBattleStatus)]
    end,
    pack_ex_skill_battle_status(SkillData, NewExBS, SkillId, SkillLv).

%% 改变指定技能数据库记录
update_skill_sql_by_id(Id, SkillId, Lv) ->
    case Lv == 1 of
        true  -> db:execute(io_lib:format(?sql_insert_skill, [Id, SkillId, Lv]));
        false -> db:execute(io_lib:format(?sql_update_skill_lv, [Lv, Id, SkillId]))
    end.

%% 转化技能属性
tranc_skill_attr([], Attr) -> Attr;
tranc_skill_attr([#player_skill{type = Type} = Skill | T], Attr) when Type == 2 -> %% 只选取被动技能
    {BS, SkillAttr, AngerLim} = Attr,
    LvData = Skill#player_skill.data#skill_lv_data.data,
    NewKang = lib_skill_buff:clear_buff(BS, Skill#player_skill.skill_id, []),
    tranc_skill_attr(T, tranc_skill_attr_buff(LvData, {NewKang, SkillAttr, AngerLim}));
tranc_skill_attr([_Skill|T], Attr) -> %% 容错
    tranc_skill_attr(T, Attr).

tranc_skill_attr_buff([], Attr) ->
    Attr;
tranc_skill_attr_buff([{K, D} | T], Attr) ->
    {BS, [Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug, Hp, Mp, HurtAdd, HurtDel], AngerLim} = Attr,
    Int = case D of 
        %% 被动技能有特殊格式限制，如不符合此格式，过滤掉
        [_PerMil, _AffectedParties, _Int, _Float, _LastTime, _EffectId] -> _Int;
        _ -> 0
    end,
    Attr1 = case K of
        %% 攻击
        att ->
            {BS, [Att+Int, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug, Hp, Mp, HurtAdd, HurtDel], AngerLim};
        %% 防御
        def ->
            {BS, [Att, Def+Int, Hit, Dodge, Crit, Ten, Fire, Ice, Drug, Hp, Mp, HurtAdd, HurtDel], AngerLim};
        %% 命中
        hit ->
            {BS, [Att, Def, Hit+Int, Dodge, Crit, Ten, Fire, Ice, Drug, Hp, Mp, HurtAdd, HurtDel], AngerLim};
        %% 闪避
        dodge ->
            {BS, [Att, Def, Hit, Dodge+Int, Crit, Ten, Fire, Ice, Drug, Hp, Mp, HurtAdd, HurtDel], AngerLim};
        %% 暴击
        crit ->
            {BS, [Att, Def, Hit, Dodge, Crit+Int, Ten, Fire, Ice, Drug, Hp, Mp, HurtAdd, HurtDel], AngerLim};
        %% 坚韧
        ten ->
            {BS, [Att, Def, Hit, Dodge, Crit, Ten+Int, Fire, Ice, Drug, Hp, Mp, HurtAdd, HurtDel], AngerLim};
        %% 火抗
        fire_def ->
            {BS, [Att, Def, Hit, Dodge, Crit, Ten, Fire+Int, Ice, Drug, Hp, Mp, HurtAdd, HurtDel], AngerLim};
        %% 冰抗
        ice_def ->
            {BS, [Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice+Int, Drug, Hp, Mp, HurtAdd, HurtDel], AngerLim};
        %% 毒抗
        drug_def -> 
            {BS, [Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug+Int, Hp, Mp, HurtAdd, HurtDel], AngerLim};
        %% 气血上限
        hp -> 
            {BS, [Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug, Hp+Int, Mp, HurtAdd, HurtDel], AngerLim};
        %% 法力上限
        mp ->
            {BS, [Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug, Hp, Mp+Int, HurtAdd, HurtDel], AngerLim};
        %% 怒气
        anger ->
            {BS, [Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug, Hp, Mp, HurtAdd, HurtDel], AngerLim+Int};
        %% 伤害加深值
        hurt_add_num -> 
            {BS, [Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug, Hp, Mp, HurtAdd+Int, HurtDel], AngerLim};
        %% 伤害减少值
        hurt_del_num -> 
            {BS, [Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug, Hp, Mp, HurtAdd, HurtDel+Int], AngerLim};
        _ ->
            Attr
    end,
    tranc_skill_attr_buff(T, Attr1).


%% 使用技能书
use_skill_book(Status, SkillId, GoodsId) ->
    Sk = Status#player_status.skill,
    case lists:keyfind(SkillId, 1, Sk#status_skill.skill_list) of
        false -> %% 还没学习过
            upgrade_skill(Status, SkillId, 1, GoodsId);
        _ -> %% 已经学习了
            {ok, BinData} = pt_210:write(21001, [0, data_skill_text:get_skill_text(1), SkillId]),
            lib_server_send:send_to_uid(Status#player_status.id, BinData),
            Status
    end.


%% 升级技能
%% Book技能书 1使用技能书，0不使用
upgrade_skill(Status, SkillId, _Book, _GoodsId) ->
    case lists:member(SkillId, data_skill:get_ids(Status#player_status.career)) of
        true ->
            Sk = Status#player_status.skill,
            [Data, Lv0, Type] = 
            case lists:keyfind(SkillId, 1, Sk#status_skill.skill_list) of
                false -> %% 还没学习过
                    [data_skill:get(SkillId, 1), 1, 0];
                {_, Lv} -> %% 学习了，升级
                    [data_skill:get(SkillId, Lv), Lv+1, 1]
            end,
            case Data =:= 0 of
                true ->
                    {ok, BinData} = pt_210:write(21001, [0, data_skill_text:get_skill_text(2), SkillId]),
                    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
                    Status;
                false ->
                    case Data of
                        [] ->
                            {ok, BinData} = pt_210:write(21001, [0, data_skill_text:get_skill_text(3), SkillId]),
                            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
                            Status;
                        _ ->
                            %[{condition, Condition} | _T] = Data#player_skill.data
                            Condition = Data#player_skill.data#skill_lv_data.learn_condition,
                            case check_upgrade(Status, Condition, [0, 0]) of
                                {true, [Coin, Llpt]} ->
                                    %% 扣除历练声望
                                    Status0 = case Llpt > 0 of
                                        true ->
                                            lib_player:minus_pt(llpt, Status, Llpt);
                                        false ->
                                            Status
                                    end,
                                    %扣除铜币
                                    Status1 = lib_goods_util:cost_money(Status0, Coin, coin),
                                    %% 统计日志
                                    log:log_consume(skill, coin, Status0, Status1, ""),
                                    case Type =:= 0 of
                                        true -> db:execute(io_lib:format(?sql_insert_skill, [Status1#player_status.id, SkillId, Lv0]));
                                        false -> db:execute(io_lib:format(?sql_update_skill_lv, [Lv0, Status1#player_status.id, SkillId]))
                                    end,
                                    %% 更新技能列表
                                    Sk2 = Status1#player_status.skill,
                                    SkillList = lists:keydelete(SkillId, 1, Sk2#status_skill.skill_list),
                                    Status2 = Status1#player_status{skill = Sk2#status_skill{skill_list=[{SkillId, Lv0}|SkillList]}},
                                    %% 被动技能属性加成
                                    case Data#player_skill.type =:= 2 of
                                        true ->
                                            NewStatus = update_skill_attribute_for_ps(Status2);
                                        false ->
                                            NewStatus = Status2
                                    end,
                                    %% 人物属性计算
                                    NewStatus1 = lib_player:count_player_attribute(NewStatus),
                                    {ok, BinData} = pt_210:write(21001, [1, <<>>, SkillId]),
                                    lib_server_send:send_to_sid(NewStatus#player_status.sid, BinData),
                                    mod_scene_agent:update(battle_attr, NewStatus1),
                                    mod_scene_agent:update(anger, NewStatus1),
                                    lib_player:send_attribute_change_notify(NewStatus1, 1),
                                    %%  完成任务
                                    lib_task:event(NewStatus1#player_status.tid, learn_skill, {SkillId}, NewStatus1#player_status.id),
                                    NewStatus1;
                                {false, Msg} ->
                                    {ok, BinData} = pt_210:write(21001, [0, Msg, SkillId]),
                                    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
                                    Status
                            end
                    end
            end;
        false ->
            {ok, BinData} = pt_210:write(21001, [0, data_skill_text:get_skill_text(6), SkillId]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
            Status
    end.

%% 逐个检查进入需求
check_upgrade(_, [], List) ->
    {true, List};
check_upgrade(Status, [{K, V} | T], [Coin, Llpt]) ->
    case K of
        lv -> %% 等级需求
            case Status#player_status.lv < V of
                true ->
                    Format = data_skill_text:get_skill_text(7),
                    Msg = io_lib:format(Format, [V]),
                    {false, Msg};
                false ->
                    check_upgrade(Status, T, [Coin, Llpt])
            end;
        coin -> %% 铜币需求
            case Status#player_status.coin+Status#player_status.bcoin < V of
                true ->
                    Format = data_skill_text:get_skill_text(8),
                    Msg = io_lib:format(Format, [V]),
                    {false, Msg};
                false ->
                    check_upgrade(Status, T, [Coin+V, Llpt])
            end;
        % llpt -> %% 历练声望
        %     case Status#player_status.llpt < V of
        %         true ->
        %             Format = data_skill_text:get_skill_text(10),
        %             Msg = io_lib:format(Format, [V]),
        %             {false, Msg};
        %         false ->
        %             check_upgrade(Status, T, [Coin, Llpt+V])
        %     end;
        _ ->
            check_upgrade(Status, T, [Coin, Llpt])
    end;
check_upgrade(Status, [{_, Id, Lv} | T], C) ->
    %%技能需求
    Sk = Status#player_status.skill,
    case Id > 0 andalso Lv > 0 of
        true ->
            case lists:keyfind(Id, 1, Sk#status_skill.skill_list) of
                false ->
                    %Skill = data_skill:get(Id, 0),
                    Msg = data_skill_text:get_skill_text(11),
                    %Msg = io_lib:format(Format, [binary_to_list(Skill#player_skill.name)]),
                    {false, Msg};
                {_, Lv0} ->
                    if
                        Lv0 >= Lv ->
                            check_upgrade(Status, T, C);
                        true ->
                            %Skill = data_skill:get(Id, 0),
                            Msg = data_skill_text:get_skill_text(11),
                            %Msg = io_lib:format(Format, [binary_to_list(Skill#player_skill.name), integer_to_list(Lv)]),
                            {false, Msg}
                    end
            end;
        false ->
            check_upgrade(Status, T, C)
    end.

%% 特殊技能验证
special_skill(Sid) ->
    if 
        Sid >= 400000 -> {Sid, 1};
        true -> false
    end.

%% 特殊技能验证
special_skill(Status, Sid) ->
    #player_status{id = PlayerId, scene = Scene, copy_id = CopyId, figure = Figure, factionwar_stone = FStone} = Status,
    if
        (Sid == 400023 orelse Sid == 400024 orelse Sid == 400025 orelse Sid == 500004) andalso Scene == 990 -> 1; %% 爱情长跑
        (Sid == 400006 orelse Sid == 400007) andalso Scene == 106 -> {true, Sid}; %% 帮派战技能
        Sid == 400001 andalso Scene == 120 -> {true, Sid}; %% 竞技场单体技能
        (Sid == 400014 orelse Sid == 400015 orelse Sid == 400016 orelse Sid == 400073 orelse Sid == 400074 orelse Sid == 400075) andalso Figure == 400010 -> {true, Sid}; %% 沙僧技能
        (Sid == 400018 orelse Sid == 400076) andalso Figure == 400008 -> {true, Sid}; %% 悟空技能
        (Sid == 400065 orelse Sid == 400083) andalso Figure == 400059 -> {true, Sid}; %% 牛魔王技能
        (Sid == 400066 orelse Sid == 400084) andalso Figure == 400062 -> {true, Sid}; %% 猪八戒技能
        Sid == 400017 andalso Scene == 223 -> %% 竞技场变身技能
            {true, lib_figure:mon_skill(0)};
        Sid == 500001 andalso Scene == 106 andalso FStone /= 0 -> {true, Sid}; %% 帮派战运石头技能
        Sid == 500005 andalso Scene == 434 -> 
            Key = lists:concat(["marriage_skill", Sid]),
            case get(Key) of
                undefined -> put(Key, 1);
                Num -> 
                    case Num + 1 >= 3 of
                        true -> 
                            erase(Key),
                            {X, Y} = lists:nth(util:rand(1, 3), [{26,22}, {20,28}, {23,26}]),
                            gen_server:cast(self(), {'change_scene', [Scene, CopyId, X, Y, 0]});
                        false -> put(Key, Num+1)
                    end
            end,
            {true, Sid}; %% 洞房技能
        (Sid == 500006 orelse Sid == 500007) andalso Scene == 434 -> {true, Sid};
        %% 炼狱副本召唤技能
        Sid == 501001 andalso Scene == 234 -> 
            %% 清理上一次技能召唤出来的怪物
            lib_mon:clear_scene_mon_mids(Scene, CopyId, 1, [35001]),
            {true, Sid};
        Sid == 502001 andalso Scene == 235 -> 
            %% 清理上一次技能召唤出来的怪物
            lib_mon:clear_scene_mon_mids(Scene, CopyId, 1, [36001]),
            {true, Sid};
        %% 炼狱副本固定技能（火雨/雷电）
        ((Sid == 501002 orelse Sid == 501003) andalso Scene == 234) orelse ((Sid == 502002 orelse Sid == 502003) andalso Scene == 235) -> {true, Sid};
        %% 炼狱副本特殊增删技能
        ((Sid >= 501004 andalso Sid =< 501009) andalso Scene == 234) orelse ((Sid >= 502004 andalso Sid =< 502009) andalso Scene == 235) -> 
            CopyId ! {'del_kingdom_skill', 1, PlayerId},
            {ok, BinData} = pt_130:write(13034, [2, [{1,Sid}]]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            if 
                Sid == 501004 -> 
                    case catch lib_mon:get_scene_mon_by_mids(Scene, CopyId, [35000], #ets_mon.aid) of
                        [Aid|_] -> Aid ! {last_back_hp, 20000};
                        _ -> skip
                    end,
                    false;
                Sid == 502004 -> 
                    case catch lib_mon:get_scene_mon_by_mids(Scene, CopyId, [36999], #ets_mon.aid) of
                        [Aid|_] -> Aid ! {last_back_hp, 40000};
                        _ -> skip
                    end,
                    false;
                true -> 
                    {true, Sid}
            end;
        %% 炼狱副本特殊变身技能
        Sid >= 903001 andalso Sid =< 903010 andalso Scene == 235 -> {true, Sid};
        %% 城战技能
        %(Sid > 504000 andalso Sid < 504009) orelse (Sid > 904000 andalso Sid < 904007) ->
            %lib_city_war_battle:skill(Status, Sid);
        %% vip副本技能
        Sid == 505001 -> 
            mod_vip_dun:minus_skill(PlayerId, 1),
            {true, Sid};
        Sid == 505002 ->
            mod_vip_dun:minus_skill(PlayerId, 2),
            {true, Sid};
        (Sid == 506001 orelse Sid == 506002 orelse Sid == 506003) andalso (Scene == 701 orelse Scene == 702) -> {true, Sid};
        true -> false
    end.

%% @spec goods_skill(Status, GoodsTypeIdList) -> NewStatus
%% 装备技能生效
%% Status 玩家 #player_status{}
%% GoodsTypeIdList 物品类型id列表
%% @end
goods_skill(Status, GoodsTypeIdList) -> 
    GoodsSkillList = goods_skill_helper(GoodsTypeIdList, []),
    Skill      = Status#player_status.skill,
    NewSkill   = Skill#status_skill{medal_skill = GoodsSkillList},
    NewStatus  = Status#player_status{skill = NewSkill},
    NewStatus1 = update_skill_attribute_for_ps(NewStatus),
    NewStatus2 = lib_player:count_player_attribute(NewStatus1),
    mod_scene_agent:update(battle_attr, NewStatus2),
    NewStatus2.

goods_skill_helper([], GoodsSkillList) -> GoodsSkillList;
goods_skill_helper([GoodsTypeId|T], GoodsSkillList) -> 
    case data_goods_skill:get(GoodsTypeId) of
        [] -> goods_skill_helper(T, GoodsSkillList);
        SkillList -> goods_skill_helper(T, SkillList ++ GoodsSkillList)
    end.

%% 中断多段技能（玩家被杀死等情况）
interrupt_combo_skill(#player_status{skill = Skill} = PS) -> 
    case is_reference(Skill#status_skill.combo_skill_ref) of
        true  -> erlang:cancel_timer(Skill#status_skill.combo_skill_ref);
        false -> skip
    end,
    NewSkill = Skill#status_skill{combo_skill_ref = none},
    PS#player_status{skill = NewSkill}.
