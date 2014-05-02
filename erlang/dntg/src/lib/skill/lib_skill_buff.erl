%%%-----------------------------------
%%% @Module  : lib_skill_buff
%%% @Author  : zzm
%%% @Created : 2014.04.29
%%% @Description: 技能Buff
%%%-----------------------------------
-module(lib_skill_buff).
-compile(export_all).
-include("predefine.hrl").
-include("server.hrl").
-include("skill.hrl").
            
%% 游戏线增加buff
add_buff([], Status, _) -> Status;
add_buff([{SkillId, Lv}|T], Status, NowTime) -> 
    case data_skill:get(SkillId, Lv) of
        [] -> add_buff(T, Status, NowTime);
        SkillR -> 
            SkillLvR = SkillR#player_skill.data,
            NewStatus = mod_battle:calc_assist_status_effect(Status, SkillLvR#skill_lv_data.data, NowTime, SkillId, Lv),
            add_buff(T, NewStatus, NowTime)
    end.

%% 清除某个buff
clear_buff([], _SkillId, Buff) -> Buff;
clear_buff([H|TB], Skill, Buff) when is_list(Skill) -> 
    {K, SkillId, _, SkillLv, Stack, Int, Float, _Time} = H,
    case lists:member(SkillId, Skill) of 
        true ->  clear_buff(TB, Skill, [{K, SkillId, {K, SkillId}, SkillLv, Stack, Int, Float, 0}|Buff]);
        false -> clear_buff(TB, Skill, [H|Buff])
    end;
clear_buff([{_, SkillId, _, _, _, _, _, _}|TB], SkillId, Buff) ->  clear_buff(TB, SkillId, Buff);
clear_buff([H|TB], SkillId, Buff) -> clear_buff(TB, SkillId, [H|Buff]).

%% 清理额外技能buff
clear_ex_buff([], _SkillId, Buff) -> Buff;
clear_ex_buff([H | TB], Skill, Buff) when is_list(Skill) -> 
    {_K, SkillId, _, _SkillLv, _Stack, _V} = H,
    case lists:member(SkillId, Skill) of 
        true ->  clear_ex_buff(TB, Skill, Buff);
        false -> clear_ex_buff(TB, Skill, [H|Buff])
    end;
clear_ex_buff([{_, SkillId, _, _, _, _} | TB], SkillId, Buff) ->  clear_ex_buff(TB, SkillId, Buff);
clear_ex_buff([H | TB], SkillId, Buff) -> clear_ex_buff(TB, SkillId, [H | Buff]).

reduce_stack(Buff, SkillId, SkillLv, ReduceNum) -> 
    case data_skill:get(SkillId, SkillLv) of
        [] -> Buff;
        Skill -> 
            Effect = Skill#player_skill.data#skill_lv_data.data,
            reduce_stack(Buff, SkillId, ReduceNum, Effect, [])
    end.
%% 减少叠加数
reduce_stack([], _, _, _, Buff) -> Buff;
reduce_stack([{K, ReduceSkillId, _, SkillLv, _Stack, Int, Float, _Time}|T], ReduceSkillId, ReduceNum, ReduceSkillData, Buff) ->
    NewBuff = %if 
       % Stack > ReduceNum ->
       %     NewV = case lists:keyfind(K, 1, ReduceSkillData) of
       %         false -> V;
       %         {_, [_P, V0, _LastTime]} -> 
       %             [P, V1] = V,
       %             V2 = (V1*1000 - V0*ReduceNum*1000)/1000,
       %             [P, V2];
       %         {_, [V0, _LastTime]} -> 
       %             (V*1000 - V0*ReduceNum*1000)/1000;
       %         _ -> V
       %     end,
       %     [{K, ReduceSkillId, {K, ReduceSkillId}, SkillLv, Stack - ReduceNum, NewV, Time}|Buff];
       % true -> 
            [{K, ReduceSkillId, {K, ReduceSkillId}, SkillLv, 1, Int, Float, 0}|Buff],
    %end,
    reduce_stack(T, ReduceSkillId, ReduceNum, ReduceSkillData, NewBuff);
reduce_stack([H|T], ReduceSkillId, ReduceNum, ReduceSkillData, Buff) -> 
    reduce_stack(T, ReduceSkillId, ReduceNum, ReduceSkillData, [H|Buff]).

%% 添加/清理特殊的场景技能buff
%% Status 玩家 #player_status{}
%% EnterSid 要进入的场景id
%% LeaveSid 要离开的场景id
specail_scene_buff(Status, EnterSid, LeaveSid) ->
    %% 进入场景
    Status1 = if
        Status#player_status.lv < 40 andalso (EnterSid == 630 orelse EnterSid == 233) -> 
            add_buff([{400020, 1}], Status, util:longunixtime());
        EnterSid == 234 orelse EnterSid == 235 -> 
            NewStatus = Status#player_status{group = 1},
            add_buff([{901049, 1}], NewStatus, util:longunixtime());
        EnterSid == 701 -> 
            {ok, BinData0} = pt_130:write(13034, [1, [{1, 506001}]]),
            lib_server_send:send_one(Status#player_status.socket, BinData0),
            Status;
        EnterSid == 702 -> 
            {ok, BinData0} = pt_130:write(13034, [1, [{1, 506002}, {1, 506003}]]),
            lib_server_send:send_one(Status#player_status.socket, BinData0),
            Status;
        %EnterSid == 251 -> %% 1vs1地图
            %Status#player_status{visible = 1};
            %add_buff([{400007, 1}], Status, util:longunixtime());
        true -> 
            Status
    end,
	Kf3v3InScene = lists:member(LeaveSid, data_kf_3v3:get_config(scene_pk_ids)),

    %% 离开的场景
    Status2 = if
        LeaveSid == 650 orelse LeaveSid == 630 orelse LeaveSid == 233 -> 
            NewBS = clear_buff(Status1#player_status.battle_status, [900002], []),
            Status1#player_status{battle_status = NewBS};
        LeaveSid == 223 -> %% 竞技场退出
            NewBS = clear_buff(Status1#player_status.battle_status, [400021, 400026, 400008, 400009, 400010, 400011, 400012, 400013, 400018, 400059, 400060, 400061, 400062, 400063, 400064, 400065, 400066], []),
            NewPS = lib_figure:change(Status1#player_status{battle_status = NewBS}, {0, 0}),
            %{ok, BinData} = pt_120:write(12099, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, 0, 0]),
            %lib_server_send:send_one(Status#player_status.socket, BinData),
            NewPS;
         LeaveSid == 106 -> %% 帮战退出
            NewBS = clear_buff(Status1#player_status.battle_status, [400067, 400068, 400069, 400070, 400071, 400072, 400073, 400074, 400075, 400076, 400077, 400078, 400079, 400080, 400081, 400082, 400084], []),
            NewPS = lib_figure:change(Status1#player_status{battle_status = NewBS}, {0, 0}),
            %{ok, BinData} = pt_120:write(12099, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, 0, 0]),
            %lib_server_send:send_one(Status#player_status.socket, BinData),
            NewPS;
        LeaveSid == 434 -> 
            {ok, BinData} = pt_130:write(13034, [2, [{1, 500005}, {1, 500006}]]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            Status1;
        LeaveSid == 234 -> 
            {ok, BinData} = pt_130:write(13034, [2, [{1, 501001}, {1, 501002}, {1, 501003},{1, 501004}, {1, 501005}, {1, 501006},{1, 501007}, {1, 501008}, {1, 501009}]]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            NewBS = clear_buff(Status1#player_status.battle_status, 901049, []),
            NewStatus1 = Status1#player_status{group = 0, battle_status = NewBS},
            mod_scene_agent:update(group, NewStatus1),
            NewStatus1;
        LeaveSid == 235 -> 
            {ok, BinData} = pt_130:write(13034, [2, [{1, 502001}, {1, 502002}, {1, 502003},{1, 502004}, {1, 502005}, {1, 502006},{1, 502007}, {1, 502008}, {1, 502009}, {1, 903003}, {1, 903004},{1, 903006}, {1, 903007},{1, 903009}, {1, 903010}]]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            NewBS = clear_buff(Status1#player_status.battle_status, [901049,903001,903002,903003,903005,903006,903007,903008], []),
            NewStatus1 = Status1#player_status{group = 0, battle_status = NewBS},
            mod_scene_agent:update(group, NewStatus1),
            NewStatus1;
        LeaveSid == 251 -> %% 跨服竞技场
            NewPS = lib_figure:change(Status1, {0, 0}),
            NewPS#player_status{visible = 0};
		Kf3v3InScene == true -> %% 3v3跨服竞技场
            NewPS = lib_figure:change(Status1, {0, 0}),
            NewPS;
        %LeaveSid == 109 andalso EnterSid /= 109 -> %% 攻城战
        %    NewPS = lib_city_war_battle:del_battle_status(Status1, 1),
        %    NewPS;
        LeaveSid == 701 andalso EnterSid /= 701 -> 
            {ok, BinData} = pt_130:write(13034, [2, [{1, 506001}]]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            Status1;
        LeaveSid == 702 andalso EnterSid /= 702 -> 
            {ok, BinData} = pt_130:write(13034, [2, [{1, 506002}, {1, 506003}]]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            Status1;
        true -> 
            Status1
    end,
    mod_scene_agent:update(battle_attr, Status2),
    Status2.


%% 打包buff发送给客户端显示
pack_buff([], _NowTime, Buff) -> 
    L = length(Buff),
    Data = list_to_binary(Buff),
    <<L:16, Data/binary>>;
pack_buff([{K, SkillId, _, SkillLv, Stack, Int, Float, T}|TB], NowTime, Buff) ->
    if
        K == change orelse SkillId == 901049 -> pack_buff(TB, NowTime, Buff);
        true -> 
            LeftTime =  T - NowTime,
            case LeftTime > 0 of
                true -> 
                    Type = get_buff_no(K), 
                    %% 未定义编号过滤，不显示buff
                    case Type of
                        0 -> pack_buff(TB, NowTime, Buff);
                        _ -> 
                            Float1 = round(Float * 1000),
                            NewBuff = [<<Type:16, SkillId:32, SkillLv:8, Stack:8, Int:32, Float1:32, T:64>>|Buff],
                            pack_buff(TB, NowTime, NewBuff)
                    end;
                false -> pack_buff(TB, NowTime, Buff)
            end
    end;
pack_buff([_|TB], NowTime, Buff) -> pack_buff(TB, NowTime, Buff).


%% 清除负面效果
clear_native_buff([], NewBS, Num) -> {NewBS, Num};
clear_native_buff([{State, SkillId, _, SkillLv, Stack, Int, Float, LastTime}|T], NewBS, Num) ->
    case lists:member(State, [yun, cm, speed, change]) of 
        true -> 
            case State of
                speed when Int > 0 orelse Float > 0 -> 
                    clear_native_buff(T, [{State, SkillId, {State, SkillId}, SkillLv, Stack, Int, Float, LastTime}|NewBS], Num);
                _ ->  
                    clear_native_buff(T, [{State, SkillId, {State, SkillId}, SkillLv, Stack, Int, Float, 0}|NewBS], Num+1)
            end;
        false ->  clear_native_buff(T, [{State, SkillId, {State, SkillId}, SkillLv, Stack, Int, Float, LastTime}|NewBS], Num)
    end.


%% 铜钱副本上线获取连斩buff
coin_dun_combo_skill_online(Status, MaxCombo) -> 
    SkillLv = if 
        MaxCombo >= 150 -> 5;
        MaxCombo >= 100 -> 4;
        MaxCombo >= 80  -> 3;
        MaxCombo >= 40  -> 2;
        MaxCombo >= 20  -> 1;
        true -> 0
    end,
    if 
        SkillLv == 0 -> Status;
        true -> add_buff([{?COIN_DUN_COMBO_SKILL_ID, SkillLv}], Status, util:longunixtime())
    end.

%% 获取buff编号
get_buff_no(TypeAtom) ->
    case TypeAtom of
        att     -> 1; %% 攻击
        def     -> 2; %% 防御
        hit     -> 3; %% 命中
        dodge   -> 4; %% 躲避
        crit    -> 5; %% 暴击
        ten     -> 6; %% 坚韧
        fire_def-> 7; %% 火抗
        ice_def -> 8; %% 冰抗
        drug_def-> 9; %% 毒抗
        speed   -> 10; %% 速度
        hurt    -> 11; %% 攻击伤害固定值
        hurt_del-> 12; %% 防御伤害固定值
        ftsh    -> 13; %% 反弹伤害
        shield  -> 14; %% 法盾
        fear    -> 15; %% 恐惧
        yun     -> 16; %% 眩晕
        cm      -> 17; %% 沉默
        hp      -> 18; %% 按血上限改变血量
        immune_effect   -> 19; %% 免疫特效
        immune_hurt     -> 20; %% 免疫伤害
        pressure_point  -> 21; %% 点穴
        parry           -> 22; %% 格挡（招架）
        suck_blood      -> 23; %% 吸血
        add_blood       -> 24; %% 根据血上限改变血量
        add_blood_ac_att-> 25; %% 根据攻击力改变血量
        drug            -> 26; %% 中毒
        blood           -> 27; %% 流血
        change          -> 28; %% 变身
        _ -> 0
    end.

%% 判断buff是否有满足F函数的条件
is_condition_fullfilled(_F, []) -> true;
is_condition_fullfilled(F, [H]) -> F(H);
is_condition_fullfilled(F, [H|T]) ->
   case F(H) of
       true  -> true;
       false -> is_condition_fullfilled(F, T)
   end.
