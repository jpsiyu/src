%%%------------------------------------
%%% @Module  : lib_city_war_battle
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.18
%%% @Description: 城战战斗逻辑处理
%%%------------------------------------

-module(lib_city_war_battle).
-export(
    [
        enter_war/1,
        logout_deal/1,
        init_mon/0,
        change_career/1,
        seize_revive_place/1,
        info_panel1/2,
        info_panel2/2,
        info_panel3/1,
        refresh_mon/1,
        timing_broad/1,
        update_door_blood/1,
        add_battle_status/3,
        del_battle_status/2,
        skill/2,
        clear_skill/1,
        minus_a_career/1,
        add_score/2,
        die_deal/1,
        attacker_win/0,
        create_mon_city_war/1,
        add_guild_score/2,
        get_next_revive_time/1,
        create_door/4,
        city_war_log/6
    ]
).
-include("unite.hrl").
-include("guild.hrl").
-include("city_war.hrl").
-include("scene.hrl").
-include("server.hrl").

%% 进入活动
enter_war([UniteStatus, State]) ->
    PlayerId = UniteStatus#unite_status.id,
    GuildId = UniteStatus#unite_status.guild_id,
    NowDay = calendar:day_of_the_week(date()),
    case lists:member(NowDay, [State#city_war_state.open_days]) of
        %% 失败，不是活动日
        false ->
            Reply = [2, data_city_war_text:get_city_war_error_tips(0)];
        true ->
            ConfigBeginHour = State#city_war_state.config_begin_hour,
            ConfigBeginMinute = State#city_war_state.config_begin_minute,
            ConfigEndHour = State#city_war_state.config_end_hour,
            ConfigEndMinute = State#city_war_state.config_end_minute,
            UnixBeginTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + ConfigBeginHour * 3600 + ConfigBeginMinute * 60,
            UnixEndTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + ConfigEndHour * 3600 + ConfigEndMinute * 60,
            %io:format("UnixBeginTime:~p~n", [util:seconds_to_localtime(UnixBeginTime)]),
            %io:format("UnixEndTime:~p~n", [util:seconds_to_localtime(UnixEndTime)]),
            case util:unixtime() >= UnixBeginTime andalso util:unixtime() =< UnixEndTime of
                %% 失败，不在活动时间内
                false ->
                    Reply = [2, data_city_war_text:get_city_war_error_tips(20)];
                true ->
                    case get(city_war_info) of
                        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
                            case dict:find(GuildId, CityWarInfo#city_war_info.attacker_info) of
                                error ->
                                    case dict:find(GuildId, CityWarInfo#city_war_info.defender_info) of
                                        %% 失败，所在帮派未参加攻城战
                                        error ->
                                            Position = 0,
                                            GuildInfo = error;
                                        %% 防守方
                                        {ok, _GuildInfo} ->
                                            Position = 2,
                                            GuildInfo = _GuildInfo
                                    end;
                                %% 进攻方
                                {ok, _GuildInfo} ->
                                    Position = 1,
                                    GuildInfo = _GuildInfo
                            end,
                            case Position of
                                %% 失败，所在帮派未参加攻城战
                                0 -> 
                                    Reply = [2, data_city_war_text:get_city_war_error_tips(21)];
                                _ ->
                                    %% 玩家状态 1.参与方 0.援助方
                                    PlayerState = case get(attacker) of
                                        AttGuildInfo when AttGuildInfo#ets_guild.id =:= GuildId ->
                                            1;
                                        _ ->
                                            case get(defender) of
                                                DefGuildInfo when DefGuildInfo#ets_guild.id =:= GuildId ->
                                                    1;
                                                _ ->
                                                    0
                                            end
                                    end,
                                    put({player_state, PlayerId}, PlayerState),
                                    case Position of
                                        1 ->
                                            MaxOnlineNum = data_city_war:get_city_war_config(max_attacker_online_num),
                                            NowOnlineNum = CityWarInfo#city_war_info.attacker_online_num;
                                        _ ->
                                            MaxOnlineNum = data_city_war:get_city_war_config(max_defender_online_num),
                                            NowOnlineNum = CityWarInfo#city_war_info.defender_online_num
                                    end,
                                    %io:format("NowOnlineNum:~p~n", [NowOnlineNum]),
                                    case NowOnlineNum >= MaxOnlineNum of
                                        true ->
                                            %% 失败，已超过活动最大参与人数
                                            ErrStr = case Position of
                                                1 -> io_lib:format(data_city_war_text:get_city_war_error_tips(23), [data_city_war_text:get_city_war_text(21)]);
                                                _ -> io_lib:format(data_city_war_text:get_city_war_error_tips(23), [data_city_war_text:get_city_war_text(22)])
                                            end,
                                            Reply = [2, ErrStr];
                                        false ->
                                            %% 是否已经有在线记录
                                            %io:format("get:~p~n", [get({is_in_room, UniteStatus#unite_status.id})]),
                                            case get({is_in_room, UniteStatus#unite_status.id}) of
                                                undefined ->
                                                    %% 记录帮派在线人数
                                                    {OnlineNum, _GuildScore, _EtsGuild} = GuildInfo,
                                                    %io:format("OnlineNum:~p~n", [OnlineNum]),
                                                    GuildInfo2 = {OnlineNum + 1, _GuildScore, _EtsGuild},
                                                    CityWarInfo2 = case Position of
                                                        %% 进攻方
                                                        1 ->
                                                            AttackerInfo = CityWarInfo#city_war_info.attacker_info,
                                                            CityWarInfo#city_war_info{
                                                                attacker_info = dict:store(GuildId, GuildInfo2, AttackerInfo),
                                                                attacker_online_num = NowOnlineNum + 1
                                                            };
                                                        %% 防守方
                                                        _ ->
                                                            DefenderInfo = CityWarInfo#city_war_info.defender_info,
                                                            CityWarInfo#city_war_info{
                                                                defender_info = dict:store(GuildId, GuildInfo2, DefenderInfo),
                                                                defender_online_num = NowOnlineNum + 1
                                                            }
                                                    end;
                                                _ ->
                                                    CityWarInfo2 = CityWarInfo
                                            end,
                                            %% 记录玩家姓名
                                            put({player_info, UniteStatus#unite_status.id}, UniteStatus#unite_status.name),
                                            %% 记录玩家在房间内
                                            put({is_in_room, UniteStatus#unite_status.id}, ok),
                                            %% 记录玩家战场信息
                                            PlayerInfo = CityWarInfo2#city_war_info.player_info,
                                            PlayerInfo2 = case dict:find(PlayerId, PlayerInfo) of
                                                error ->
                                                    case CityWarInfo2#city_war_info.count of
                                                        %% 攻防已互换
                                                        2 ->
                                                            case Position of
                                                                1 ->
                                                                    dict:store(PlayerId, {2, 0}, PlayerInfo);
                                                                _ ->
                                                                    dict:store(PlayerId, {1, 0}, PlayerInfo)
                                                            end;
                                                        _ ->
                                                            dict:store(PlayerId, {Position, 0}, PlayerInfo)
                                                    end;
                                                _ ->
                                                    PlayerInfo
                                            end,
                                            CityWarInfo3 = case Position of
                                                %% 进攻方
                                                1 ->
                                                    lib_player:update_player_info(UniteStatus#unite_status.id, [{set_city_war_revive_place, CityWarInfo2#city_war_info.attacker_revive_place}]),
                                                    CityWarInfo2#city_war_info{
                                                        player_info = PlayerInfo2
                                                    };
                                                %% 防守方
                                                _ ->
                                                    lib_player:update_player_info(UniteStatus#unite_status.id, [{set_city_war_revive_place, CityWarInfo2#city_war_info.defender_revive_place}]),
                                                    CityWarInfo2#city_war_info{
                                                        player_info = PlayerInfo2
                                                    }
                                            end,
                                            put(city_war_info, CityWarInfo3),
                                            Reply = [1, data_city_war_text:get_city_war_error_tips(22)],
                                            %% 传送到相应位置
                                            CityWarXY = case Position of
                                                %% 进攻方
                                                1 ->
                                                    %% 设置分组
                                                    %% 进攻方增加攻城战属性buff
                                                    lib_player:update_player_info(UniteStatus#unite_status.id, [{group, 1}, {add_city_war_buff, no}]),
                                                    lib_player_unite:update_unite_info(UniteStatus#unite_status.id, [{group, 1}]),
                                                    data_city_war:get_city_war_config(get_attacker_born);
                                                %% 防守方
                                                _ ->
                                                    %% 设置分组
                                                    lib_player:update_player_info(UniteStatus#unite_status.id, [{group, 2}]),
                                                    lib_player_unite:update_unite_info(UniteStatus#unite_status.id, [{group, 2}]),
                                                    [[74, 122], [74, 122]]
                                                    %data_city_war:get_city_war_config(get_defender_born)
                                            end,
                                            LenPos = length(CityWarXY),
                                            PosNum = util:rand(1, LenPos),
                                            [_X, _Y] = lists:nth(PosNum, CityWarXY),
                                            [X, Y] = data_city_war:get_repair_xy(_X, _Y),
                                            CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                                            lib_scene:player_change_scene_queue(PlayerId, CityWarSceneId, 0, X, Y, 0)
                                    end
                            end;
                        %% 失败，操作失败
                        _ ->
                            Reply = [2, data_city_war_text:get_city_war_error_tips(1)]
                    end
            end
    end,
    {ok, BinData} = pt_641:write(64109, Reply),
    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData).

%% 下线处理
logout_deal(PlayerStatus) ->
    GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            %% 切换PK状态
            lib_player:update_player_info(PlayerStatus#player_status.id, [{force_change_pk_status, 1}]),
            
            case dict:find(GuildId, CityWarInfo#city_war_info.attacker_info) of
                error ->
                    case dict:find(GuildId, CityWarInfo#city_war_info.defender_info) of
                        %% 失败，所在帮派未参加攻城战
                        error ->
                            Position = 0,
                            GuildInfo = error;
                        %% 防守方
                        {ok, _GuildInfo} ->
                            Position = 2,
                            GuildInfo = _GuildInfo
                    end;
                %% 进攻方
                {ok, _GuildInfo} ->
                    Position = 1,
                    GuildInfo = _GuildInfo
            end,
            case Position of
                %% 失败，所在帮派未参加攻城战
                0 -> 
                    skip;
                _ ->
                    %% 清除房间内玩家在线信息
                    erase({is_in_room, PlayerStatus#player_status.id}),
                    %% 帮派在线人数减一
                    {OnlineNum, _GuildScore, _EtsGuild} = GuildInfo,
                    NowOnlineNum = case Position of
                        1 ->
                            CityWarInfo#city_war_info.attacker_online_num;
                        _ ->
                            CityWarInfo#city_war_info.defender_online_num
                    end,
                    NewGuildOnlineNum = case OnlineNum >= 1 of
                        true -> OnlineNum - 1;
                        false -> 0
                    end,
                    %% 总在线人数减一
                    NewAllOnlineNum = case NowOnlineNum >= 1 of
                        true -> NowOnlineNum - 1;
                        false -> 0
                    end,
                    GuildInfo2 = {NewGuildOnlineNum, _GuildScore, _EtsGuild},
                    %% 是否为攻城车
                    TotalCarNum = CityWarInfo#city_war_info.total_car_num,
                    NewTotalCarNum = case lists:member(PlayerStatus#player_status.factionwar_stone, [11, 12]) of
                        true ->
                             case TotalCarNum > 0 of
                                 true -> TotalCarNum - 1;
                                 false -> 0
                             end;
                        false ->
                            TotalCarNum
                    end,
                    %% 是否为鬼巫
                    case lists:member(PlayerStatus#player_status.factionwar_stone, [15, 16]) of
                        true ->
                            mod_city_war:minus_a_career(PlayerStatus);
                        false ->
                            skip
                    end,
                    CityWarInfo2 = case Position of
                        %% 进攻方
                        1 ->
                            AttackerInfo = CityWarInfo#city_war_info.attacker_info,
                            CityWarInfo#city_war_info{
                                attacker_info = dict:store(GuildId, GuildInfo2, AttackerInfo),
                                attacker_online_num = NewAllOnlineNum,
                                total_car_num = NewTotalCarNum
                            };
                        %% 防守方
                        _ ->
                            DefenderInfo = CityWarInfo#city_war_info.defender_info,
                            CityWarInfo#city_war_info{
                                defender_info = dict:store(GuildId, GuildInfo2, DefenderInfo),
                                defender_online_num = NewAllOnlineNum,
                                total_car_num = NewTotalCarNum
                            }
                    end,
                    put(city_war_info, CityWarInfo2)
            end;
        _ ->
            skip
    end.

%% 初始化怪物
init_mon() ->
    %% 可打复活旗
    %Mon1 = data_city_war:get_city_war_config(mon1),
    %% 不可打复活旗(蓝 防守)
    Mon2 = data_city_war:get_city_war_config(mon2),
    %% 没占领复活旗
    %Mon3 = data_city_war:get_city_war_config(mon3),
    %% 不可打复活旗(红 进攻)
    Mon4 = data_city_war:get_city_war_config(mon4),
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    CopyId = 0,
    Type = 0,  %% 0.被动 1.主动
    WorldLv = case catch lib_player:world_lv(1) of
        _WorldLv when is_integer(_WorldLv) ->
            _WorldLv;
        _ ->
            40
    end,
    Group1 = 1,
    Group2 = 2,
    %% 清怪
    lib_mon:clear_scene_mon(CityWarSceneId, CopyId, 0),
    %% 生成复活旗子
    lib_mon:async_create_mon(Mon4, CityWarSceneId, 16, 179, Type, CopyId, 1, [{group, Group1}]),
    lib_mon:async_create_mon(Mon4, CityWarSceneId, 56, 136, Type, CopyId, 1, [{group, Group1}]),
    lib_mon:async_create_mon(Mon2, CityWarSceneId, 97,  79, Type, CopyId, 1, [{group, Group2}]),
    %% 生成10个箭塔
    TowerMonId = if
        WorldLv < 50 -> data_city_war:get_city_war_config(tower_mon_id1);
        WorldLv =< 65 -> data_city_war:get_city_war_config(tower_mon_id2);
        true -> data_city_war:get_city_war_config(tower_mon_id3)
    end,
    TowerXY = data_city_war:get_city_war_config(tower_xy),
    mod_scene_agent:apply_cast(CityWarSceneId, lib_city_war_battle, create_mon_city_war, [[CityWarSceneId, TowerMonId, TowerXY]]),
    SpecialMonId1 = data_city_war:get_city_war_config(special_mon_id1),
    SpecialXY1 = data_city_war:get_city_war_config(special_xy1),
    mod_scene_agent:apply_cast(CityWarSceneId, lib_city_war_battle, create_mon_city_war, [[CityWarSceneId, SpecialMonId1, SpecialXY1]]),
    SpecialMonId2 = data_city_war:get_city_war_config(special_mon_id2),
    SpecialXY2 = data_city_war:get_city_war_config(special_xy2),
    mod_scene_agent:apply_cast(CityWarSceneId, lib_city_war_battle, create_mon_city_war, [[CityWarSceneId, SpecialMonId2, SpecialXY2]]),
    %% 生成守护神
    DefMonId = data_city_war:get_city_war_config(def_mon_id),
    lib_mon:async_create_mon(DefMonId, CityWarSceneId, 97, 86, 1, CopyId, 1, [{group, Group2}]),
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            %% 保存进攻、防守方信息
            NewAttackerInfo = lib_city_war:init_att_info(dict:new()),
            NewDefenderInfo = lib_city_war:init_def_info(dict:new()),
            MonInfo = CityWarInfo#city_war_info.monster_info,
            DoorMonList = data_city_war:get_city_war_config(door_mon_place),
            NewMonInfo = create_door(MonInfo, DoorMonList, 1, WorldLv),
            CityWarInfo2 = CityWarInfo#city_war_info{
                attacker_info = NewAttackerInfo,
                defender_info = NewDefenderInfo,
                monster_info = NewMonInfo,
                %revive_mon_id = [MonId1, MonId2, MonId3],
                %center_mon_id = CenterMonId,
                total_tower_num = length(TowerXY)
            },
            %io:format("MonId1:~p, MonId2:~p, MonId3:~p~n", [MonId1, MonId2, MonId3]),
            put(city_war_info, CityWarInfo2),
            %% 日志
            AttGuild = case get(attacker) of
                _AttGuild when is_record(_AttGuild, ets_guild) ->
                    _AttGuild;
                _ ->
                    #ets_guild{}
            end,
            DefGuild = case get(defender) of
                _DefGuild when is_record(_DefGuild, ets_guild) ->
                    _DefGuild;
                _ ->
                    #ets_guild{}
            end,
            PreFive = case get(pre_five) of
                _PreFive when is_list(_PreFive) ->
                    _PreFive;
                _ ->
                    []
            end,
            spawn(fun() ->
                        city_war_log(AttGuild, DefGuild, PreFive, NewAttackerInfo, NewDefenderInfo, 1)
                end);
        _OtherError ->
            catch util:errlog("city war init mon error: cannot find city_war_info! : ~p", [_OtherError])
    end,
    ok.

%% 职业变换
change_career([PlayerStatus, Type, _State]) ->
    PlayerId = PlayerStatus#player_status.id,
    GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
    X = PlayerStatus#player_status.x,
    Y = PlayerStatus#player_status.y,
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            case dict:find(GuildId, CityWarInfo#city_war_info.attacker_info) of
                error ->
                    case dict:find(GuildId, CityWarInfo#city_war_info.defender_info) of
                        %% 失败，所在帮派未参加攻城战
                        error ->
                            Position = 0;
                        %% 防守方
                        {ok, _GuildInfo} ->
                            Position = 2
                    end;
                %% 进攻方
                {ok, _GuildInfo} ->
                    Position = 1
            end,
            case Position of
                %% 进攻方
                1 ->
                    %% 判断是否在复活点附近
                    RevivePlace = CityWarInfo#city_war_info.attacker_revive_place,
                    %io:format("RevivePlace:~p~n", [RevivePlace]),
                    case lib_city_war:near_revive_place(RevivePlace, X, Y) of
                        %% 失败，需要在复活点附近才能变换职业
                        false -> 
                            Reply = [2, data_city_war_text:get_city_war_error_tips(30)];
                        true ->
                            case Type of
                                %% 医仙
                                1 ->
                                    AttackerDoctorNum = CityWarInfo#city_war_info.attacker_doctor_num,
                                    MaxNum = data_city_war:get_city_war_config(max_other_career_num),
                                    case AttackerDoctorNum >= MaxNum of
                                        %% 失败，当前场景中的医仙已经达到上限
                                        true ->
                                            Reply = [2, data_city_war_text:get_city_war_error_tips(25)];
                                        %% 成功
                                        false ->
                                            CityWarInfo2 = CityWarInfo#city_war_info{
                                                attacker_doctor_num = AttackerDoctorNum + 1
                                            },
                                            put(city_war_info, CityWarInfo2),
                                            %% 玩家变身
                                            lib_player:update_player_info(PlayerId, [{factionwar_stone, 15}]),
                                            Reply = [1, data_city_war_text:get_city_war_error_tips(2)]
                                    end;
                                %% 鬼巫
                                2 ->
                                    AttackerGhostNum = CityWarInfo#city_war_info.attacker_ghost_num,
                                    MaxNum = data_city_war:get_city_war_config(max_other_career_num),
                                    case AttackerGhostNum >= MaxNum of
                                        %% 失败，当前场景中的鬼巫已经达到上限
                                        true ->
                                            Reply = [2, data_city_war_text:get_city_war_error_tips(26)];
                                        %% 成功
                                        false ->
                                            CityWarInfo2 = CityWarInfo#city_war_info{
                                                attacker_ghost_num = AttackerGhostNum + 1
                                            },
                                            put(city_war_info, CityWarInfo2),
                                            %% 玩家变身
                                            lib_player:update_player_info(PlayerId, [{factionwar_stone, 16}]),
                                            Reply = [1, data_city_war_text:get_city_war_error_tips(2)]
                                    end;
                                %% 失败，无法变换该职业
                                _ ->
                                    Reply = [2, data_city_war_text:get_city_war_error_tips(31)]
                            end
                    end;
                %% 防守方
                2 ->
                    %% 判断是否在复活点附近
                    RevivePlace = CityWarInfo#city_war_info.defender_revive_place,
                    case lib_city_war:near_revive_place(RevivePlace, X, Y) of
                        %% 失败，需要在复活点附近才能变换职业
                        false -> 
                            Reply = [2, data_city_war_text:get_city_war_error_tips(30)];
                        true ->
                            case Type of
                                %% 医仙
                                1 ->
                                    DefenderDoctorNum = CityWarInfo#city_war_info.defender_doctor_num,
                                    MaxNum = data_city_war:get_city_war_config(max_other_career_num),
                                    case DefenderDoctorNum >= MaxNum of
                                        %% 失败，当前场景中的医仙已经达到上限
                                        true ->
                                            Reply = [2, data_city_war_text:get_city_war_error_tips(25)];
                                        %% 成功
                                        false ->
                                            CityWarInfo2 = CityWarInfo#city_war_info{
                                                defender_doctor_num = DefenderDoctorNum + 1
                                            },
                                            put(city_war_info, CityWarInfo2),
                                            %% 玩家变身
                                            lib_player:update_player_info(PlayerId, [{factionwar_stone, 15}]),
                                            Reply = [1, data_city_war_text:get_city_war_error_tips(2)]
                                    end;
                                %% 鬼巫
                                2 ->
                                    DefenderGhostNum = CityWarInfo#city_war_info.defender_ghost_num,
                                    MaxNum = data_city_war:get_city_war_config(max_other_career_num),
                                    case DefenderGhostNum >= MaxNum of
                                        %% 失败，当前场景中的鬼巫已经达到上限
                                        true ->
                                            Reply = [2, data_city_war_text:get_city_war_error_tips(26)];
                                        %% 成功
                                        false ->
                                            CityWarInfo2 = CityWarInfo#city_war_info{
                                                defender_ghost_num = DefenderGhostNum + 1
                                            },
                                            put(city_war_info, CityWarInfo2),
                                            %% 玩家变身
                                            lib_player:update_player_info(PlayerId, [{factionwar_stone, 16}]),
                                            Reply = [1, data_city_war_text:get_city_war_error_tips(2)]
                                    end;
                                %% 失败，无法变换该职业
                                _ ->
                                    Reply = [2, data_city_war_text:get_city_war_error_tips(31)]
                            end
                    end;
                %% 失败，所在帮派未参加攻城战
                _ ->
                    Reply = [2, data_city_war_text:get_city_war_error_tips(21)]
            end,
            %% 成功转换职业，更新
            case Reply of
                [1, _] ->
                    PlayerInfo = CityWarInfo#city_war_info.player_info,
                    PlayerList = dict:to_list(PlayerInfo),
                    update_all_panel2(PlayerList);
                _ ->
                    skip
            end;
        %% 失败，操作失败
        _ ->
            Reply = [2, data_city_war_text:get_city_war_error_tips(1)]
    end,
    {ok, BinData} = pt_641:write(64110, Reply),
    lib_unite_send:send_to_uid(PlayerStatus#player_status.id, BinData).

%% 进攻方抢占复活点
seize_revive_place(Mon) ->
    Mid = Mon#ets_mon.id,
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            case lists:member(Mid, CityWarInfo#city_war_info.revive_mon_id) of
                true ->
                    %io:format("Mid:~p, List;~p~n", [Mid, CityWarInfo#city_war_info.revive_mon_id]),
                    Nth = get_nth(Mid, CityWarInfo#city_war_info.revive_mon_id, 1),
                    CanRobBorn = data_city_war:get_city_war_config(can_rob_born),
                    Len = length(CanRobBorn),
                    %io:format("Nth:~p~n", [Nth]),
                    case Nth >= 1 andalso Nth =< Len of
                        true ->
                            %% 删除防守方复活点，增加进攻方复活点
                            RobBorn = lists:nth(Nth, CanRobBorn),
                            AttackerRevivePlace = CityWarInfo#city_war_info.attacker_revive_place,
                            DefenderRevivePlace = CityWarInfo#city_war_info.defender_revive_place,
                            NewAttackerRevivePlace = [RobBorn | AttackerRevivePlace],
                            NewDefenderRevivePlace = lists:delete(RobBorn, DefenderRevivePlace),
                            CityWarInfo2 = CityWarInfo#city_war_info{
                                attacker_revive_place = NewAttackerRevivePlace,
                                defender_revive_place = NewDefenderRevivePlace
                            },
                            spawn(fun() ->
                                        send_all_revive_place(CityWarInfo2)
                                end),
                            put(city_war_info, CityWarInfo2),
                            %% 生成不可打复活旗子(红 进攻方)
                            CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                            Mon4 = data_city_war:get_city_war_config(mon4),
                            Type = 0,  %% 0.被动 1.主动
                            CopyId = 0,
                            BroadCast = 1,
                            Group1 = 1,
                            lib_mon:async_create_mon(Mon4, CityWarSceneId, Mon#ets_mon.x, Mon#ets_mon.y, Type, CopyId, BroadCast, [{group, Group1}]);
                        false ->
                            skip
                    end;
                _ ->
                    skip
            end;
        _ ->
            skip
    end.

get_nth(_Mid, [], _N) -> 0;
get_nth(Mid, [H | T], N) ->
    case Mid of
        H -> N;
        _ -> get_nth(Mid, T, N + 1)
    end.

%% 城战面板1(定时更新，客户端也可以主动申请)
info_panel1(UniteStatus, State) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            ConfigBeginTime = {State#city_war_state.config_begin_hour, State#city_war_state.config_begin_minute, 0},
            ConfigEndTime = {State#city_war_state.config_end_hour, State#city_war_state.config_end_minute, 0},
            %% 是否在活动时间内
            case time() > ConfigBeginTime andalso time() < ConfigEndTime of
                %% 广播活动面板
                true -> 
                    MonInfoList = dict:to_list(CityWarInfo#city_war_info.monster_info),
                    AttackerInfoList = dict:to_list(CityWarInfo#city_war_info.attacker_info),
                    DefenderInfoList = dict:to_list(CityWarInfo#city_war_info.defender_info),
                    DealMonInfoList = deal_mon_info_list(MonInfoList, []),
                    DealAttackerInfoList = deal_guild_info_list(AttackerInfoList, []),
                    DealDefenderInfoList = deal_guild_info_list(DefenderInfoList, []),
                    %io:format("DealMonInfoList:~p~n", [DealMonInfoList]),
                    {ok, BinData} = pt_641:write(64111, [DealMonInfoList, DealAttackerInfoList, DealDefenderInfoList]),
                    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData);
                %% 不在活动时间内
                false ->
                    skip
            end;
        _ ->
            skip
    end.

%% 城战面板2(及时更新)
info_panel2(GuildId, PlayerId) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            case dict:find(GuildId, CityWarInfo#city_war_info.attacker_info) of
                error ->
                    case dict:find(GuildId, CityWarInfo#city_war_info.defender_info) of
                        %% 失败，所在帮派未参加攻城战
                        error ->
                            Position = 0;
                        %% 防守方
                        {ok, _GuildInfo} ->
                            Position = 2
                    end;
                %% 进攻方
                {ok, _GuildInfo} ->
                    Position = 1
            end,
            %% 医仙、鬼巫数量
            case Position of
                0 ->
                    MaxNum = 0,
                    DoctorNowNum = 0,
                    GhostNowNum = 0;
                %% 进攻方
                1 ->
                    MaxNum = data_city_war:get_city_war_config(max_other_career_num),
                    DoctorNowNum = CityWarInfo#city_war_info.attacker_doctor_num,
                    GhostNowNum = CityWarInfo#city_war_info.attacker_ghost_num;
                %% 防守方
                _ ->
                    MaxNum = data_city_war:get_city_war_config(max_other_career_num),
                    DoctorNowNum = CityWarInfo#city_war_info.defender_doctor_num,
                    GhostNowNum = CityWarInfo#city_war_info.defender_ghost_num
            end,
            case MaxNum of
                0 ->
                    skip;
                _ ->
                    {ok, BinData} = pt_641:write(64112, [DoctorNowNum, MaxNum, GhostNowNum, MaxNum]),
                    lib_unite_send:send_to_uid(PlayerId, BinData)
            end;
        _ ->
            skip
    end.

%% 城战面板3(及时更新)
info_panel3(UniteStatus) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            %% 玩家积分
            case dict:find(UniteStatus#unite_status.id, CityWarInfo#city_war_info.player_info) of
                {ok, {_KillNum, Score}} ->
                    ok;
                _ ->
                    Score = 0
            end,
            {ok, BinData} = pt_641:write(64114, [Score]),
            lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData);
        _ ->
            skip
    end.

%% 定时刷新怪物
refresh_mon(State) ->
    Days = [State#city_war_state.open_days],
    NowDay = calendar:day_of_the_week(date()),
    case lists:member(NowDay, Days) of
        true ->
            case get(city_war_info) of
                CityWarInfo when is_record(CityWarInfo, city_war_info) ->
                    ConfigBeginTime = {State#city_war_state.config_begin_hour, State#city_war_state.config_begin_minute, 0},
                    ConfigEndTime = {State#city_war_state.config_end_hour, State#city_war_state.config_end_minute, 0},
                    %% 是否在活动时间内
                    case time() > ConfigBeginTime andalso time() < ConfigEndTime of
                        true -> 
                            %% 车房出炸弹
                            CityWarInfo2 = lib_city_war:create_bomb(CityWarInfo),
                            %% 30秒出一个
                            {_Hour, _Min, _Sec} = time(),
                            case (_Sec div 10) rem 3 of
                                0 ->
                                    %% 复活点出攻城车
                                    lib_city_war:create_car1(CityWarInfo2);
                                1 ->
                                    %% 复活点出弩车
                                    lib_city_war:create_car2(CityWarInfo2);
                                2 ->
                                    put(city_war_info, CityWarInfo2);
                                %Msg = lists:concat([CityWarInfo2#city_war_info.total_car_num, ",", CityWarInfo2#city_war_info.car1_num1, ",", CityWarInfo2#city_war_info.car1_num2, ",", CityWarInfo2#city_war_info.car2_num1, ",", CityWarInfo2#city_war_info.car2_num2]),
                                %{ok, BinData1} = pt_110:write(11004, Msg),
                                %lib_unite_send:send_to_scene(109, BinData1);
                                _ ->
                                    put(city_war_info, CityWarInfo2)
                            end;
                        %% 不在活动时间内
                        false ->
                            skip
                    end;
                _ ->
                    skip
            end;
        false ->
            skip
    end.

%% 生成城门怪
create_door(MonInfo, [], _Id, _WorldLv) -> 
    MonInfo;
create_door(MonInfo, [H | T], Id, WorldLv) ->
    case H of
        [X, Y] ->
            DoorMonId = if
                WorldLv < 50 -> data_city_war:get_city_war_config(door_mon_id1) + Id - 1;
                WorldLv =< 65 -> data_city_war:get_city_war_config(door_mon_id2) + Id - 1;
                true -> data_city_war:get_city_war_config(door_mon_id3) + Id - 1
            end,
            CityWarSceneId = data_city_war:get_city_war_config(scene_id),
            CopyId = 0,
            Type = 0,  %% 0.被动 1.主动
            Group2 = 2,
            %% 生成城门怪
            MonId = lib_mon:sync_create_mon(DoorMonId, CityWarSceneId, X, Y, Type, CopyId, 1, [{group, Group2}]),
            NewMonInfo = dict:store(Id, {MonId, 100}, MonInfo),
            create_door(NewMonInfo, T, Id + 1, WorldLv);
        _ ->
            create_door(MonInfo, T, Id, WorldLv)
    end.

%% 定时广播(10秒)
timing_broad(State) ->
    Days = [State#city_war_state.open_days],
    NowDay = calendar:day_of_the_week(date()),
    case lists:member(NowDay, Days) of
        true ->
            case get(city_war_info) of
                CityWarInfo when is_record(CityWarInfo, city_war_info) ->
                    ConfigBeginTime = {State#city_war_state.config_begin_hour, State#city_war_state.config_begin_minute, 0},
                    ConfigEndTime = {State#city_war_state.config_end_hour, State#city_war_state.config_end_minute, 0},
                    %% 是否在活动时间内
                    case time() > ConfigBeginTime andalso time() < ConfigEndTime of
                        %% 广播活动面板
                        true -> 
                            MonInfoList = dict:to_list(CityWarInfo#city_war_info.monster_info),
                            AttackerInfoList = dict:to_list(CityWarInfo#city_war_info.attacker_info),
                            DefenderInfoList = dict:to_list(CityWarInfo#city_war_info.defender_info),
                            DealMonInfoList = deal_mon_info_list(MonInfoList, []),
                            DealAttackerInfoList = deal_guild_info_list(AttackerInfoList, []),
                            DealDefenderInfoList = deal_guild_info_list(DefenderInfoList, []),
                            %io:format("DealMonInfoList:~p~n", [DealMonInfoList]),
                            NowTowerNum = CityWarInfo#city_war_info.total_tower_num,
                            TotalTowerNum = length(data_city_war:get_city_war_config(tower_xy)),
                            NowCarNum = CityWarInfo#city_war_info.total_car_num,
                            TotalCarNum = data_city_war:get_city_war_config(get_max_total_car_num),
                            {ok, BinData} = pt_641:write(64111, [DealMonInfoList, DealAttackerInfoList, DealDefenderInfoList, NowTowerNum, TotalTowerNum, NowCarNum, TotalCarNum]),
                            CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                            lib_unite_send:send_to_scene(CityWarSceneId, 0, BinData);
                        %% 不在活动时间内
                        false ->
                            skip
                    end;
                _ ->
                    skip
            end;
        false ->
            skip
    end.

deal_mon_info_list([], L) -> L;
deal_mon_info_list([H | T], L) ->
    case H of
        {Type, {_MonId, Blood}} ->
            deal_mon_info_list(T, [{Type, Blood} | L]);
        _ ->
            deal_mon_info_list(T, L)
    end.

deal_guild_info_list([], L) -> L;
deal_guild_info_list([H | T], L) ->
    case H of
        {_GuildId, {OnlineNum, Score, EtsGuild}} ->
            deal_guild_info_list(T, [{EtsGuild#ets_guild.name, OnlineNum, Score} | L]);
        _ ->
            deal_guild_info_list(T, L)
    end.

%% 更新城门血量
update_door_blood([MonId, Hp, HpLim, State, Mid]) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            MonInfoList = dict:to_list(CityWarInfo#city_war_info.monster_info),
            %io:format("1:~p, 2:~p~n", [all_door_exists(MonInfoList), is_door(MonInfoList, MonId)]),
            %case all_door_exists(MonInfoList) andalso is_door(MonInfoList, MonId) andalso Hp =:= 0 of
            _ = all_door_exists(MonInfoList),
            DoorMon1 = data_city_war:get_city_war_config(door_mon_id1),
            DoorMon2 = data_city_war:get_city_war_config(door_mon_id2),
            DoorMon3 = data_city_war:get_city_war_config(door_mon_id3),
            case get({attacker_mon}) =:= undefined andalso lists:member(Mid, [DoorMon1, DoorMon1 + 1, DoorMon1 + 2, DoorMon1 + 3, DoorMon1 + 4, DoorMon2, DoorMon2 + 1, DoorMon2 + 2, DoorMon2 + 3, DoorMon2 + 4, DoorMon3, DoorMon3 + 1, DoorMon3 + 2, DoorMon3 + 3, DoorMon3 + 4]) andalso Hp =< 0 of
                true ->
                    put({attacker_mon}, ok),
                    %% 生成守护神
                    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                    CopyId = 0,
                    Type = 1,  %% 0.被动 1.主动
                    Group1 = 1,
                    AttMonId = data_city_war:get_city_war_config(att_mon_id),
                    lib_mon:async_create_mon(AttMonId, CityWarSceneId, 56, 143, Type, CopyId, 1, [{group, Group1}]),
                    CarTypeId2 = data_city_war:get_city_war_config(car_id2),
                    lib_mon:clear_scene_mon_by_mids(CityWarSceneId, CopyId, 1, [CarTypeId2]),
                    TotalCarNum = CityWarInfo#city_war_info.total_car_num,
                    CollectCarNum = CityWarInfo#city_war_info.collect_car_num,
                    NewTotalCarNum = case TotalCarNum >= CollectCarNum of
                        true -> TotalCarNum - CollectCarNum;
                        false -> 0
                    end,
                    _CityWarInfo2 = CityWarInfo#city_war_info{
                        total_car_num = NewTotalCarNum,
                        collect_car_num = 0
                    };
                false ->
                    _CityWarInfo2 = CityWarInfo
            end,
            NewMonInfo = update_blood(MonInfoList, [], MonId, Hp, HpLim),
            CityWarInfo2 = _CityWarInfo2#city_war_info{
                monster_info = NewMonInfo
            },
            put(city_war_info, CityWarInfo2),
            %% 有城门死亡时及时更新怪物血量
            case Hp =< 0 andalso is_door(MonInfoList, MonId) of
                true ->
                    AttackerReviveList = CityWarInfo2#city_war_info.attacker_revive_place,
                    [_H | AutoReviveList] = data_city_war:get_city_war_config(bomb_place),
                    NewAttackerReviveList = (AttackerReviveList -- AutoReviveList) ++ AutoReviveList,
                    CityWarInfo3 = CityWarInfo2#city_war_info{
                        attacker_revive_place = NewAttackerReviveList
                    },
                    case length(NewAttackerReviveList) =/= length(AttackerReviveList) of
                        true -> 
                            spawn(fun() ->
                                        send_all_revive_place(CityWarInfo3)
                                end);
                        false ->
                            skip
                    end,
                    put(city_war_info, CityWarInfo3),
                    timing_broad(State);
                false ->
                    skip
            end;
        _ ->
            skip
    end.

update_blood([], L, _MonId, _Hp, _HpLim) -> dict:from_list(L);
update_blood([H | T], L, MonId, Hp, HpLim) ->
    case H of
        {Type, {MonId, _Blood}} ->
            Blood = round(Hp / HpLim * 100),
            NewL = [{Type, {MonId, Blood}} | L] ++ T,
            dict:from_list(NewL);
        _ ->
            update_blood(T, [H | L], MonId, Hp, HpLim)
    end.

all_door_exists([]) -> true;
all_door_exists([H | T]) ->
    case H of
        {_Type, {_MonId, Blood}} ->
            case Blood of
                0 ->
                    false;
                _ ->
                    all_door_exists(T)
            end;
        _ ->
            all_door_exists(T)
    end.

is_door([], _MonId) -> false;
is_door([H | T], MonId) ->
    case H of
        {_Type, {MonId, _Blood}} ->
            true;
        _ ->
            is_door(T, MonId)
    end.

%% 采集了怪物
%% MonId 怪物唯一id
%% Type 15医仙, 16鬼巫
add_battle_status(#player_status{id = Id, socket = Socket, scene = Scene, copy_id = CopyId, x = X, y = Y, realm = _Realm, nickname = NickName, sex = _Sex, career = _Career, factionwar_stone = FactionwarStone, city_war_win_num = CityWarWinNum} = Status, #ets_mon{id = MonId, mid = Mid, x=MonX, y=MonY} = _Mon, Type) -> 
    case FactionwarStone == 0 of
        true -> 
            Stone = if 
                Mid == 40419 -> 14; %% 运送炸弹
                Mid == 40421 orelse Mid == 40461 orelse Mid == 40471 -> 13; %% 炮塔
                Mid == 40431 -> 11; %% 冲车
                Mid == 40432 -> 12; %% 弩车
                Type == 15   -> 15; %% 医仙
                Type == 16   -> 16; %% 鬼巫
                true -> FactionwarStone
            end,
            %% 复活点内的攻城车数量减一
            case lists:member(Mid, [40431, 40432]) of
                true ->
                    mod_city_war:minus_revive_car(Mid, MonX, MonY);
                false ->
                    skip
            end,
            %% 复活点内的采集炸弹数量减一
            case lists:member(Mid, [40419]) of
                true ->
                    mod_city_war:minus_revive_bomb(Mid, MonX, MonY);
                false ->
                    skip
            end,
            NewStatus = Status#player_status{factionwar_stone = Stone},
            %% 不同状态的技能
            case special_skill(Stone) of
                [] -> skip;
                SkillList -> 
                    {ok, BinData1} = pt_130:write(13034, [1, SkillList]),
                    lib_server_send:send_one(Socket, BinData1)
            end,
            mod_scene_agent:update(factionwar_stone, NewStatus),
            {ok, BinData} = pt_121:write(12107, [Id, Stone]),
            lib_server_send:send_to_area_scene(Scene, CopyId, X, Y, BinData),
            %% 是否需要传送
            if 
                Stone == 11 orelse Stone == 12 -> 
                    mod_city_war:minus_a_collect_car(),
                    WorldLv = lib_player:get_world_lv_from_unite(),
                    AttrRatio = if
                        CityWarWinNum > 7 -> 1.6;
                        CityWarWinNum < 2 -> 1;
                        true -> (CityWarWinNum - 1) * 0.12 + 1
                    end,
                    AttrList = if
                        WorldLv < 51 -> [trunc(433000*AttrRatio), trunc(433000*AttrRatio), 0, trunc(4770*AttrRatio), 0, 0, 0, 0, 0, 99999, 99999];
                        WorldLv < 66 -> [trunc(650000*AttrRatio), trunc(650000*AttrRatio), 0, trunc(7160*AttrRatio), 0, 0, 0, 0, 0, 99999, 99999];
                        true         -> [trunc(866000*AttrRatio), trunc(866000*AttrRatio), 0, trunc(9555*AttrRatio), 0, 0, 0, 0, 0, 99999, 99999]
                    end,
                    NewStatus1 = lib_player:count_player_attribute(NewStatus#player_status{factionwar_option=[{attr, AttrList}]}),
                    mod_scene_agent:update(battle_attr, NewStatus1),
                    lib_player:send_attribute_change_notify(NewStatus1, 0),
                    {ok, BinData11} = pt_120:write(12009, [NewStatus1#player_status.id, NewStatus1#player_status.platform, NewStatus1#player_status.server_num, NewStatus1#player_status.hp, NewStatus1#player_status.hp_lim]),
                    lib_server_send:send_to_area_scene(NewStatus1#player_status.scene, NewStatus1#player_status.copy_id, NewStatus1#player_status.x, NewStatus1#player_status.y, BinData11),
                    NewStatus1;
                Stone == 13 -> 
                    {T_X, T_Y} = if
                        MonX < 23   -> {23, 141};
                        MonX < 36   -> {30, 149};
                        MonX < 50   -> {50, 167};
                        MonX < 61   -> {56, 176};
                        MonX < 74   -> {74, 78};
                        MonX < 90   -> {80, 89};
                        MonX < 103  -> {103, 108};
                        MonX < 115  -> {110, 116};
                        MonX < 128  -> {128, 45};
                        MonX < 140  -> {135, 53};
                        true        -> {23, 141}
                    end,
                    lib_mon:change_mon_attr(MonId, NewStatus#player_status.scene, [{change_name, list_to_binary([NickName, <<"的炮塔">>])}, {owner_id,Id}]),
                    NewStatus1 = NewStatus#player_status{visible=1},
                    mod_scene_agent:update(visible, NewStatus1),
                    {ok, BinDataV} = pt_121:write(12108, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, 1]),
                    lib_server_send:send_to_area_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, BinDataV),
                    %% 广播移动
                    mod_scene_agent:move(T_X, T_Y, 3, NewStatus1),
                    NewStatus1#player_status{x=T_X, y=T_Y, unmove_time=util:longunixtime()+1500, factionwar_option=[{mid, MonId, X, Y}]};
                    %lib_scene:change_scene(NewStatus#player_status{visible=1},Scene,CopyId,T_X,T_Y,false);
                true -> 
                    NewStatus
            end;
        false ->
            del_battle_status(Status, 1)
    end.

%% 放下炸弹
%% Type 保留字段（暂无作用）
del_battle_status(#player_status{id = Id, socket = Socket, scene = Scene, copy_id = CopyId, x = X, y = Y, factionwar_stone = Stone, group = Group, factionwar_option = FactionwarOption} = Status, Type) -> 
    if
        Stone == 0 -> Status;
        Stone > 10 andalso Stone < 21 ->  %% 城战
            NewStatus = Status#player_status{factionwar_stone = 0, factionwar_option=[]},
            mod_scene_agent:update(factionwar_stone, NewStatus),
            {ok, BinData} = pt_121:write(12107, [Id, 0]),
            lib_server_send:send_to_area_scene(Scene, CopyId, X, Y, BinData),
            if
                Stone == 14 andalso Type == 3 -> %% 创建炸弹怪物
                    WorldLv = lib_player:get_world_lv_from_unite(),
                    BombMonId = if
                        WorldLv < 51 -> 40460;
                        WorldLv < 66 -> 40420;
                        true         -> 40470
                    end,
                    lib_mon:async_create_mon(BombMonId, Scene, X, Y, 0, CopyId, 1, [{group, Group},{owner_id,Id}]);
                true -> skip
            end,
            case special_skill(Stone) of
                [] -> skip;
                SkillList -> 
                    {ok, BinData1} = pt_130:write(13034, [2, SkillList]),
                    lib_server_send:send_one(Socket, BinData1)
            end,
            %% 下来攻城车后，数量减一
            case Stone == 11 orelse Stone == 12 of
                true -> mod_city_war:minus_a_car();
                false -> skip
            end,
            NewStatus1 = NewStatus#player_status{visible=0},
            mod_scene_agent:update(visible, NewStatus1),
            {ok, BinDataV} = pt_121:write(12108, [NewStatus1#player_status.id, NewStatus1#player_status.platform, NewStatus1#player_status.server_num, 0]),
            lib_server_send:send_to_area_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, BinDataV),
            if
                Stone == 11 orelse Stone == 12 -> 
                    NewStatus2 = lib_player:count_player_attribute(NewStatus1#player_status{factionwar_option=[]}),
                    mod_scene_agent:update(battle_attr, NewStatus2),
                    lib_player:send_attribute_change_notify(NewStatus2, 0),
                    {ok, BinData11} = pt_120:write(12009, [NewStatus1#player_status.id, NewStatus1#player_status.platform, NewStatus1#player_status.server_num, NewStatus2#player_status.hp, NewStatus2#player_status.hp_lim]),
                    lib_server_send:send_to_area_scene(NewStatus1#player_status.scene, NewStatus1#player_status.copy_id, NewStatus1#player_status.x, NewStatus1#player_status.y, BinData11),
                    NewStatus2;
                Stone == 13 -> 
                    case lists:keyfind(mid, 1, FactionwarOption) of
                        false -> NewStatus1;
                        {_, MId, OldX, OldY} ->
                            %% 更改该怪物属性
                            lib_mon:change_mon_attr(MId, NewStatus1#player_status.scene, [{change_name, <<"炮塔">>}, {owner_id,0}]),
                            %% 回到没变成炮塔前的位置 
                            mod_scene_agent:move(OldX, OldY, 3, NewStatus1),
                            NewStatus1#player_status{x=OldX, y=OldY, unmove_time=util:longunixtime()+2000}
                    end;
                true ->  NewStatus1
            end;
        true -> Status
    end.

%% 各特殊状态的特殊技能
special_skill(BattleStatus) -> 
    case BattleStatus of
        16 -> %% 鬼巫
            [{1, 504005}, {1, 504006}, {1, 504007}, {1, 504008}];
        15 -> %% 医仙
            [{1, 504002}, {1, 504003}, {1, 504004}];  %%{1, 504001}
        14 ->  %% 运送炸弹
            [];
        13 ->  %% 炮塔
            [{1, 904001}, {1, 904002}];
        12 -> %% 弩车
            [{1, 904005}, {1, 904006}];
        11  -> %% 冲车
            [{1, 904003}, {1, 904004}];
        _ -> []
    end.

%% 施放特殊技能
skill(Status, Sid) -> 
    if
        Status#player_status.factionwar_stone == 16 andalso (Sid == 504005 orelse Sid == 504006 orelse Sid == 504007 orelse Sid == 504008)-> {true, Sid};
        Status#player_status.factionwar_stone == 15 andalso (Sid == 504001 orelse Sid == 504002 orelse Sid == 504003 orelse Sid == 504004)-> {true, Sid};
        Status#player_status.factionwar_stone == 13 andalso Sid == 904001 -> {true, Sid};
        Status#player_status.factionwar_stone == 12 andalso Sid == 904005 -> {true, Sid};
        Status#player_status.factionwar_stone == 11 andalso Sid == 904003 -> {true, Sid};
        Status#player_status.factionwar_stone == 13 andalso Sid == 904002 ->
            {ok, BinData} = pt_130:write(13034, [2, special_skill(13)]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            NewStatus = del_battle_status(Status, 1),
            {false, NewStatus};
        Status#player_status.factionwar_stone == 12 andalso Sid == 904006 ->
            {ok, BinData} = pt_130:write(13034, [2, special_skill(12)]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            NewStatus = del_battle_status(Status, 1),
             {false, NewStatus};
        Status#player_status.factionwar_stone == 11 andalso Sid == 904004 -> 
            {ok, BinData} = pt_130:write(13034, [2, special_skill(11)]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            NewStatus = del_battle_status(Status, 1),
            {false, NewStatus};
        true -> 
            %util:errlog("Error lib_city_war_battle/skill2 if_cause, arg ~p~n", [[Status#player_status.factionwar_stone, Sid]]),
            false
    end.

%% 清理所有城战技能
clear_skill(Status) -> 
    SkillList = [{1, 504005}, {1, 504006}, {1, 504007}, {1, 504008}, {1, 504001}, {1, 504002}, {1, 504003}, {1, 504004}, {1, 904001}, {1, 904002}, {1, 904003}, {1, 904004}, {1, 904005}, {1, 904006}],
    {ok, BinData} = pt_130:write(13034, [2, SkillList]),
    lib_server_send:send_one(Status#player_status.socket, BinData).

%% 医仙、鬼巫数量减一
minus_a_career(PlayerStatus) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            case PlayerStatus#player_status.group of
                %% 进攻方
                1 ->
                    case PlayerStatus#player_status.factionwar_stone of
                        %% 医仙
                        15 ->
                            AttackerDoctorNum = CityWarInfo#city_war_info.attacker_doctor_num,
                            NewAttackerDoctorNum = case AttackerDoctorNum > 0 of
                                true -> AttackerDoctorNum - 1;
                                false -> 0
                            end,
                            NewAttackerGhostNum = CityWarInfo#city_war_info.attacker_ghost_num;
                        %% 鬼巫
                        16 ->
                            AttackerGhostNum = CityWarInfo#city_war_info.attacker_ghost_num,
                            NewAttackerGhostNum = case AttackerGhostNum > 0 of
                                true -> AttackerGhostNum - 1;
                                false -> 0
                            end,
                            NewAttackerDoctorNum = CityWarInfo#city_war_info.attacker_doctor_num;
                        _ ->
                            NewAttackerDoctorNum = CityWarInfo#city_war_info.attacker_doctor_num,
                            NewAttackerGhostNum = CityWarInfo#city_war_info.attacker_ghost_num
                    end,
                    CityWarInfo2 = CityWarInfo#city_war_info{
                        attacker_doctor_num = NewAttackerDoctorNum,
                        attacker_ghost_num = NewAttackerGhostNum
                    },
                    put(city_war_info, CityWarInfo2);
                %% 防守方
                _ ->
                    case PlayerStatus#player_status.factionwar_stone of
                        %% 医仙
                        15 ->
                            DefenderDoctorNum = CityWarInfo#city_war_info.defender_doctor_num,
                            NewDefenderDoctorNum = case DefenderDoctorNum > 0 of
                                true -> DefenderDoctorNum - 1;
                                false -> 0
                            end,
                            NewDefenderGhostNum = CityWarInfo#city_war_info.defender_ghost_num;
                        %% 鬼巫
                        16 ->
                            DefenderGhostNum = CityWarInfo#city_war_info.defender_ghost_num,
                            NewDefenderGhostNum = case DefenderGhostNum > 0 of
                                true -> DefenderGhostNum - 1;
                                false -> 0
                            end,
                            NewDefenderDoctorNum = CityWarInfo#city_war_info.defender_doctor_num;
                        _ ->
                            NewDefenderDoctorNum = CityWarInfo#city_war_info.defender_doctor_num,
                            NewDefenderGhostNum = CityWarInfo#city_war_info.defender_ghost_num
                    end,
                    CityWarInfo2 = CityWarInfo#city_war_info{
                        defender_doctor_num = NewDefenderDoctorNum,
                        defender_ghost_num = NewDefenderGhostNum
                    },
                    put(city_war_info, CityWarInfo2)
            end,
            %% 成功转换职业，更新
            PlayerInfo = CityWarInfo#city_war_info.player_info,
            PlayerList = dict:to_list(PlayerInfo),
            spawn(fun() ->
                       update_all_panel2(PlayerList)
               end);
        _ ->
            skip
    end.

%% 玩家加积分
add_score(PlayerId, Score) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            PlayerInfo = CityWarInfo#city_war_info.player_info,
            case dict:find(PlayerId, PlayerInfo) of
                {ok, {KillNum, NowScore}} ->
                    NewScore = NowScore + Score;
                _ ->
                    KillNum = 0,
                    NewScore = Score
            end,
            NewPlayerInfo = dict:store(PlayerId, {KillNum, NewScore}, PlayerInfo),
            CityWarInfo2 = CityWarInfo#city_war_info{
                player_info = NewPlayerInfo
            },
            put(city_war_info, CityWarInfo2),
            %% 及时更新玩家积分
            {ok, BinData} = pt_641:write(64114, [NewScore]),
            lib_unite_send:send_to_uid(PlayerId, BinData),
            %% 通知玩家加积分了
            {ok, BinData2} = pt_641:write(64124, [Score]),
            lib_unite_send:send_to_uid(PlayerId, BinData2);
        _ ->
            skip
    end.

update_all_panel2([]) -> skip;
update_all_panel2([H | T]) ->
    case H of
        {PlayerId, _} ->
            lib_player:update_player_info(PlayerId, [{update_city_war_panel2, no}]);
        _ ->
            skip
    end,
    update_all_panel2(T).

%% 死亡处理
die_deal(PlayerId) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            %io:format("PlayerId:~p, GuildId:~p~n", [PlayerId, GuildId]),
            DieList = CityWarInfo#city_war_info.die_list,
            %NewDieList = case lists:member(PlayerId, DieList) of
            %    true -> DieList;
            %    false -> [PlayerId | DieList]
            %end,
            NewDieList = [PlayerId | DieList],
            CityWarInfo2 = CityWarInfo#city_war_info{
                die_list = NewDieList
            },
            put(city_war_info, CityWarInfo2);
        _ ->
            skip
    end.

%% 进攻方胜利
attacker_win() ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            WarNum = CityWarInfo#city_war_info.count,
            case WarNum of
                3 -> 
                    Over = true;
                _ ->
                    Over = true
                    %Over = false
            end,
            AttackerInfo = CityWarInfo#city_war_info.attacker_info,
            DefenderInfo = CityWarInfo#city_war_info.defender_info,
            CityWarInfo2 = CityWarInfo#city_war_info{
                attacker_info = DefenderInfo,
                defender_info = AttackerInfo,
                count = WarNum + 1
            },
            put(city_war_info, CityWarInfo2),
            case Over of
                %% 打完3场，退出
                true ->
                    mod_city_war:clear_all_out(),
                    mod_city_war:account(),
                    mod_city_war:end_deal(2);
                %% 未打完，攻守互换
                false ->
                    Scene_id = data_city_war:get_city_war_config(scene_id),
                    AttackerName = case get(attacker) of
                        AttackerInfo10 when is_record(AttackerInfo10, ets_guild) ->
                            AttackerInfo10#ets_guild.name;
                        _ -> "notfound"
                    end,
                    DefenderName = case get(defender) of
                        DefenderInfo10 when is_record(DefenderInfo10, ets_guild) ->
                            DefenderInfo10#ets_guild.name;
                        _ -> "notfound"
                    end,
                    spawn(fun() ->
                                case WarNum of
                                    1 ->
                                        {ok, BinData} = pt_641:write(64119, [5, DefenderName, AttackerName]);
                                    _ -> 
                                        {ok, BinData} = pt_641:write(64119, [5, AttackerName, DefenderName])
                                end,
                                lib_unite_send:send_to_all(Scene_id, BinData),
                                timer:sleep(5 * 1000),
                                mod_city_war:reset_all()
                        end)
            end;
        _ ->
            skip
    end.

%% 创建怪物
create_mon_city_war([SceneId, MonId1, MonLocal1]) ->
    Group = 2,
    FunCreateMon1 = 
	    fun(_I, [[X,Y] | Tail]) ->
                mod_mon_create:create_mon(MonId1, SceneId, X, Y, 1, 0, 1, [{group, Group}]),
            {ok, Tail}
     	end,
    util:for(1, length(MonLocal1), FunCreateMon1, MonLocal1).

%% 帮派加分
add_guild_score(GuildId, Score) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            AttackerInfo = CityWarInfo#city_war_info.attacker_info,
            DefenderInfo = CityWarInfo#city_war_info.defender_info,
            NewAttackerInfo = case dict:find(GuildId, AttackerInfo) of
                {ok, {OnlineNum1, AllScore1, EtsGuild1}} ->
                    dict:store(GuildId, {OnlineNum1, AllScore1 + Score, EtsGuild1}, AttackerInfo);
                _ ->
                    AttackerInfo
            end,
            NewDefenderInfo = case dict:find(GuildId, DefenderInfo) of
                {ok, {OnlineNum2, AllScore2, EtsGuild2}} ->
                    dict:store(GuildId, {OnlineNum2, AllScore2 + Score, EtsGuild2}, DefenderInfo);
                _ ->
                    DefenderInfo
            end,
            CityWarInfo2 = CityWarInfo#city_war_info{
                attacker_info = NewAttackerInfo,
                defender_info = NewDefenderInfo
            },
            put(city_war_info, CityWarInfo2);
        _ ->
            skip
    end.

%% 复活剩余时间
get_next_revive_time(UniteStatus) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            NowTime = util:unixtime(),
            _RestTime = case NowTime =< CityWarInfo#city_war_info.next_revive_time of
                true -> CityWarInfo#city_war_info.next_revive_time - NowTime;
                false -> 0
            end,
            RestTime = case _RestTime > 20 of
                true -> 20;
                false -> _RestTime
            end,
            %io:format("RestTime:~p~n", [RestTime]),
            {ok, BinData} = pt_641:write(64117, [RestTime]),
            lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData);
        _ ->
            skip
    end.

%% 通知所有玩家复活点改变
send_all_revive_place(CityWarInfo) ->
    PlayerList = dict:to_list(CityWarInfo#city_war_info.player_info),
    AttackerReviveList = CityWarInfo#city_war_info.attacker_revive_place,
    DefenderReviveList = CityWarInfo#city_war_info.defender_revive_place,
    case CityWarInfo#city_war_info.count of
        2 -> 
            send_all_revive_place2(PlayerList, DefenderReviveList, AttackerReviveList);
        _ ->
            send_all_revive_place2(PlayerList, AttackerReviveList, DefenderReviveList)
    end.

send_all_revive_place2([], _ReviveList1, _ReviveList2) -> skip;
send_all_revive_place2([H | T], ReviveList1, ReviveList2) ->
    case H of
        {PlayerId, {State, _Score}} ->
            case State of
                1 -> 
                    lib_player:update_player_info(PlayerId, [{set_city_war_revive_place, ReviveList1}]);
                _ ->
                    lib_player:update_player_info(PlayerId, [{set_city_war_revive_place, ReviveList2}])
            end;
        _ ->
            skip
    end,
    timer:sleep(100),
    send_all_revive_place2(T, ReviveList1, ReviveList2).

%% 攻城战日志
city_war_log(AttGuild, DefGuild, PreFive, AttackerInfo, DefenderInfo, Type) ->
    case Type of
        1 ->
            skip;
        _ ->
            db:execute(io_lib:format(<<"insert into log_city_war_info1 set attacker_id = ~p, defender_id = ~p, begin_time = ~p">>, [AttGuild#ets_guild.id, DefGuild#ets_guild.id, util:unixtime()]))
    end,
    case db:get_row("select max(id) from log_city_war_info1 limit 1") of
        [MaxId] ->
            ok;
        _ ->
            MaxId = 1
    end,
    case Type of
        1 ->
            AttackerInfo2 = dict:to_list(AttackerInfo),
            DefenderInfo2 = dict:to_list(DefenderInfo),
            city_war_log2(MaxId, AttackerInfo2, AttGuild#ets_guild.id, 1),
            city_war_log2(MaxId, DefenderInfo2, DefGuild#ets_guild.id, 2);
        _ ->
            city_war_log3(MaxId, PreFive)
    end.

city_war_log2(_LogId, [], _TargetGuildId, _Type) -> skip;
city_war_log2(LogId, [H | T], TargetGuildId, Type) ->
    case H of
        {GuildId, {_OnlineNum, _Score, _EtsGuild}} when GuildId =/= TargetGuildId ->
            db:execute(io_lib:format(<<"insert into log_city_war_info2 set war_id = ~p, guild_id = ~p, type = ~p">>, [LogId, GuildId, Type]));
        _ ->
            skip
    end,
    city_war_log2(LogId, T, TargetGuildId, Type).

city_war_log3(_LogId, []) -> skip;
city_war_log3(LogId, [H | T]) ->
    case H of
        {_Id, _Score, EtsGuild, DonateCoin} ->
            db:execute(io_lib:format(<<"insert into log_city_war_info3 set war_id = ~p, guild_id = ~p, money = ~p">>, [LogId, EtsGuild#ets_guild.id, DonateCoin]));
        _ ->
            skip
    end,
    city_war_log3(LogId, T).
