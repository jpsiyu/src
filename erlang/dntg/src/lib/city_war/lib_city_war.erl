%%%------------------------------------
%%% @Module  : lib_city_war
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.13
%%% @Description: 城战
%%%------------------------------------

-module(lib_city_war).
-export(
    [
        get_all_list_convert/2,
        get_pre_six/2,
        get_pre_six2/2,
        get_pre_six_detail/2,
        att_aids/3,
        def_aids/2,
        att_aids2/3,
        def_aids2/2,
        att_approval/3,
        def_approval/3,
        get_seize_info/2,
        add_coin/4,
        quit_war/1,
        near_revive_place/3,
        mon_die/2,
        init_att_info/1,
        init_def_info/1,
        get_revive_xy/1,
        logout_deal/1,
        login_out/1,
        create_bomb/1,
        minus_revive_bomb/3,
        create_car1/1,
        create_car2/1,
        minus_revive_car/3,
        minus_a_car/0,
        kill_deal/3,
        killed_by_mon/1,
        timing_revive/1,
        clear_all_out/0,
        account/0,
        end_deal/1,
        get_closest_xy/4,
        logout_re_status/1,
        picture0/1,
        picture1/1,
        picture2/1,
        reset_all/0,
        delete_revive_list/1,
        is_city_war_win/1,
        get_statue/1,
        set_statue/1,
        reset_statue/1,
        update_statue/0,
        init_win_info/0,
        min_cycle/0,
        send_winner_tv/1,
        delete_win_guild/1,
        get_winner_guild/1,
        change_career_check/1,
        minus_a_tower/0,
        assist_kill_mon/1,
        get_all_guild_info/1,
        is_att_def/1,
        minus_a_collect_car/0,
        get_city_war_win_num/0,
        add_city_war_buff/1,
        del_city_war_buff/1
    ]
).
-include("guild.hrl").
-include("scene.hrl").
-include("server.hrl").
-include("unite.hrl").
-include("city_war.hrl").
-include("buff.hrl").

%% db:get_all()获取的数据：[[1], [2]] => [1, 2]
get_all_list_convert([], L) -> L;
get_all_list_convert([[H] | T], L) ->
    get_all_list_convert(T, [H | L]).

%% 传入所有帮派ID的List: [Id1, Id2, Id3]
%% 返回帮战周积分前6名的帮派ID的List: [{Id1, Score1, DonateCoin1}, {Id2, Score2, DonateCoin2}, {Id3, Score3, DonateCoin3}]
get_pre_six([], L) -> 
    L1 = lists:keysort(2, L),
    L2 = lists:reverse(L1),
    lists:sublist(L2, 6);
get_pre_six([H | T], L) ->
    case catch mod_factionwar:get_faction_war_week_score(H) of
        {ok, [FactionWarWeekScore, FactionWarLastTime]} ->
            %io:format("FactionWarWeekScore:~p~n", [FactionWarWeekScore]),
            BorderTime = data_city_war:get_border_time2(),
            %% 是否参加了本周的帮战
            case FactionWarLastTime > BorderTime of
                true -> get_pre_six(T, [{H, FactionWarWeekScore, 0} | L]);
                false -> get_pre_six(T, L)
            end;
        _ ->
            get_pre_six(T, L)
    end.

%% 只根据周积分选帮派，不判断时间
get_pre_six2([], L) -> 
    L1 = lists:keysort(2, L),
    L2 = lists:reverse(L1),
    lists:sublist(L2, 6);
get_pre_six2([H | T], L) ->
    case catch mod_factionwar:get_faction_war_week_score(H) of
        {ok, [FactionWarWeekScore, _FactionWarLastTime]} ->
            get_pre_six2(T, [{H, FactionWarWeekScore, 0} | L]);
        _ ->
            get_pre_six2(T, L)
    end.

%% 获取帮派信息，[{Id, Score, DonateCoin}] => [{Id, Score, GuildInfo, DonateCoin}]
get_pre_six_detail([], L) -> lists:reverse(L);
get_pre_six_detail([H | T], L) ->
    case H of
        {Id, Score, DonateCoin} ->
            GuildInfo = lib_guild:get_guild(Id),
            case is_record(GuildInfo, ets_guild) of
                true -> get_pre_six_detail(T, [{Id, Score, GuildInfo, DonateCoin} | L]);
                false -> get_pre_six_detail(T, L)
            end;
        _ -> get_pre_six_detail(T, L)
    end.

%% 获得进攻援助方信息
att_aids([], L, _AttackerId) -> L;
att_aids([H | T], L, AttackerId) ->
    case H of
        {{aid, _GuildId}, {1, AttackerId, GuildInfo}} ->
            Info = {2, GuildInfo#ets_guild.name, GuildInfo#ets_guild.member_num, GuildInfo#ets_guild.member_capacity, GuildInfo#ets_guild.chief_name, GuildInfo#ets_guild.level},
            att_aids(T, [Info | L], AttackerId);
        _ ->
            att_aids(T, L, AttackerId)
    end.

%% 获得防守援助方信息
def_aids([], L) -> L;
def_aids([H | T], L) -> 
    case H of
        {{aid, _GuildId}, {2, _TargetGuildId, GuildInfo}} ->
            Info = {4, GuildInfo#ets_guild.name, GuildInfo#ets_guild.member_num, GuildInfo#ets_guild.member_capacity, GuildInfo#ets_guild.chief_name, GuildInfo#ets_guild.level},
            def_aids(T, [Info | L]);
        _ ->
            def_aids(T, L)
    end.

%% 获得进攻援助方信息
att_aids2([], L, _AttackerId) -> L;
att_aids2([H | T], L, AttackerId) ->
    case H of
        {{aid, _GuildId}, {1, AttackerId, GuildInfo}} ->
            Info = {2, GuildInfo#ets_guild.name, GuildInfo#ets_guild.member_num, GuildInfo#ets_guild.member_capacity},
            att_aids2(T, [Info | L], AttackerId);
        _ ->
            att_aids2(T, L, AttackerId)
    end.

%% 获得防守援助方信息
def_aids2([], L) -> L;
def_aids2([H | T], L) -> 
    case H of
        {{aid, _GuildId}, {2, _TargetGuildId, GuildInfo}} ->
            Info = {4, GuildInfo#ets_guild.name, GuildInfo#ets_guild.member_num, GuildInfo#ets_guild.member_capacity},
            def_aids2(T, [Info | L]);
        _ ->
            def_aids2(T, L)
    end.

%% 获得进攻方审批信息
att_approval([], L, _AttGuildId) -> L;
att_approval([H | T], L, AttGuildId) -> 
    case H of
        {{apply, _GuildId}, {1, AttGuildId, GuildInfo}} ->
            Info = {GuildInfo#ets_guild.id, GuildInfo#ets_guild.name, GuildInfo#ets_guild.chief_name, GuildInfo#ets_guild.realm, GuildInfo#ets_guild.member_num, GuildInfo#ets_guild.member_capacity},
            att_approval(T, [Info | L], AttGuildId);
        _ ->
            att_approval(T, L, AttGuildId)
    end.

%% 获得防守方审批信息
def_approval([], L, _DefGuildId) -> L;
def_approval([H | T], L, DefGuildId) -> 
    case H of
        {{apply, _GuildId}, {2, DefGuildId, GuildInfo}} ->
            Info = {GuildInfo#ets_guild.id, GuildInfo#ets_guild.name, GuildInfo#ets_guild.chief_name, GuildInfo#ets_guild.realm, GuildInfo#ets_guild.member_num, GuildInfo#ets_guild.member_capacity},
            def_approval(T, [Info | L], DefGuildId);
        _ ->
            def_approval(T, L, DefGuildId)
    end.

%% 获取抢夺信息
get_seize_info([], L) -> lists:reverse(L);
get_seize_info([H | T], L) ->
    case H of
        {_Id, _Score, GuildInfo, DonateCoin} ->
            Info = {GuildInfo#ets_guild.name, GuildInfo#ets_guild.chief_name, GuildInfo#ets_guild.realm, GuildInfo#ets_guild.member_num, GuildInfo#ets_guild.member_capacity, DonateCoin},
            get_seize_info(T, [Info | L]);
        _ ->
            get_seize_info(T, L)
    end.

%% 捐献铜币
add_coin([], L, _GuildId, _Num) -> 
    L1 = lists:keysort(2, L),
    L2 = lists:keysort(4, L1),
    lists:reverse(L2);
add_coin([H | T], L, GuildId, Num) ->
    case H of
        {Id, Score, GuildInfo, DonateCoin} ->
            case Id =:= GuildId of
                true -> add_coin(T, [{Id, Score, GuildInfo, (DonateCoin + Num)} | L], GuildId, Num);
                false -> add_coin(T, [{Id, Score, GuildInfo, DonateCoin} | L], GuildId, Num)
            end;
        _ ->
            add_coin(T, L, GuildId, Num)
    end.

%% 退出活动
quit_war(PlayerId) ->
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    %% 查找用户登录前记录的场景ID和坐标
	case mod_exit:lookup_last_xy(PlayerId) of
		[_SceneId, _X, _Y] -> 
			case _SceneId of
				CityWarSceneId -> 
                    [SceneId, X, Y] = data_city_war:get_city_war_config(leave_scene);
				_ -> 
                    %%判断，如果不是普通场景和野外场景，则返回长安主城
                    case data_scene:get(_SceneId) of
                        _S when is_record(_S, ets_scene) ->
                            SceneType = _S#ets_scene.type;
                        _ ->
                            SceneType = 8
                    end,
                    case SceneType =:= ?SCENE_TYPE_NORMAL orelse SceneType =:= ?SCENE_TYPE_OUTSIDE of
                        true ->
                            [SceneId, X, Y] = [_SceneId, _X, _Y];
                        false -> 
                            [SceneId, X, Y] = data_city_war:get_city_war_config(leave_scene)
                    end
			end;
		_ -> 
            [SceneId, X, Y] = data_city_war:get_city_war_config(leave_scene)
	end,
    lib_scene:player_change_scene_queue(PlayerId, SceneId, 0, X, Y, [{group, 0}, {factionwar_stone, 0}, {city_war_logout, no}]),
    lib_player:update_player_info(PlayerId, [{del_city_war_buff, no}]),
    case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
            skip;
        _ ->
            del_sql_data(PlayerId)
    end,
    lib_player_unite:update_unite_info(PlayerId, [{group, 0}]).

del_sql_data(PlayerId) ->
    case db:get_all(io_lib:format(<<"select id from buff where pid = ~p and attribute_id = 69">>, [PlayerId])) of
        [] ->
            skip;
        List when is_list(List) ->
            del_all_sql(List);
        _ ->
            skip
    end,
    db:execute(io_lib:format(<<"delete from buff where pid = ~p and attribute_id = 69">>, [PlayerId])).

del_all_sql([]) -> skip;
del_all_sql([H | T]) ->
    case H of
        [Id] ->
            buff_dict:delete_id(Id);
        _ ->
            skip
    end,
    del_all_sql(T).

%% 是否在复活点附近
near_revive_place([], _X, _Y) -> false;
near_revive_place([H | T], X, Y) ->
    case H of
        [X1, Y1] ->
            case (X1 - X) * (X1 - X) + (Y1 - Y) * (Y1 - Y) =< 25 of
                true -> true;
                false -> near_revive_place(T, X, Y)
            end;
        _ ->
            near_revive_place(T, X, Y)
    end.

%% 怪物死亡处理
mon_die(Mon, _PS) ->
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    case Mon#ets_mon.scene of
        %% 是否在城战场景
        CityWarSceneId ->
            %% 可打复活旗
            %Mon1 = data_city_war:get_city_war_config(mon1),
            %% 没占领复活旗
            %Mon2 = data_city_war:get_city_war_config(mon3),
            CenterMon1 = data_city_war:get_city_war_config(center_mon_id1),
            CenterMon2 = data_city_war:get_city_war_config(center_mon_id2),
            CenterMon3 = data_city_war:get_city_war_config(center_mon_id3),
            DoorMon1 = data_city_war:get_city_war_config(door_mon_id1),
            DoorMon2 = data_city_war:get_city_war_config(door_mon_id2),
            DoorMon3 = data_city_war:get_city_war_config(door_mon_id3),
            TowerMon1 = data_city_war:get_city_war_config(tower_mon_id1),
            TowerMon2 = data_city_war:get_city_war_config(tower_mon_id2),
            TowerMon3 = data_city_war:get_city_war_config(tower_mon_id3),
            MonList = [CenterMon1, CenterMon2, CenterMon3, DoorMon1, DoorMon1 + 1, DoorMon1 + 2, DoorMon1 + 3, DoorMon1 + 4, DoorMon2, DoorMon2 + 1, DoorMon2 + 2, DoorMon2 + 3, DoorMon2 + 4, DoorMon3, DoorMon3 + 1, DoorMon3 + 2, DoorMon3 + 3, DoorMon3 + 4, TowerMon1, TowerMon2, TowerMon3],
            case lists:member(Mon#ets_mon.mid, MonList) of
                true -> 
                    %% 击破城门加20积分
                    case lists:member(Mon#ets_mon.mid, [DoorMon1, DoorMon1 + 1, DoorMon1 + 2, DoorMon1 + 3, DoorMon1 + 4, DoorMon2, DoorMon2 + 1, DoorMon2 + 2, DoorMon2 + 3, DoorMon2 + 4, DoorMon3, DoorMon3 + 1, DoorMon3 + 2, DoorMon3 + 3, DoorMon3 + 4]) of
                        true ->
                            mod_city_war:add_score(_PS#player_status.id, 20);
                        false ->
                            skip
                    end,
                    %% 击破最后一个城门，生成龙珠
                    case lists:member(Mon#ets_mon.mid, [DoorMon1, DoorMon2, DoorMon3]) of
                        true ->
                            spawn(fun() ->
                                        create_center_mon()
                                end);
                        false ->
                            skip
                    end,
                    %% 箭塔总数减一
                    %% 击破箭塔加20积分
                    case lists:member(Mon#ets_mon.mid, [TowerMon1, TowerMon2, TowerMon3]) of
                        true ->
                            case Mon#ets_mon.group =/= _PS#player_status.group of
                                true ->
                                    mod_city_war:add_score(_PS#player_status.id, 20),
                                    mod_city_war:minus_a_tower();
                                false ->
                                    skip
                            end;
                        false ->
                            skip
                    end,
                    %% 龙珠被打死，清场
                    case lists:member(Mon#ets_mon.mid, [CenterMon1, CenterMon2, CenterMon3]) of
                        true ->
                            mod_city_war:add_score(_PS#player_status.id, 20),
                            {ok, BinData} = pt_641:write(64123, [1]),
                            lib_server_send:send_to_scene(CityWarSceneId, 0, BinData),
                            mod_city_war:attacker_win();
                        false ->
                            skip
                    end;
                %% 不是指定怪物
                _ ->
                    skip
            end;
        _ ->
            skip
    end.

%% 进攻方信息
init_att_info(DictInfo) ->
    case get(attacker) of
        GuildInfo when is_record(GuildInfo, ets_guild) ->
            DictInfo2 = dict:store(GuildInfo#ets_guild.id, {0, 0, GuildInfo}, DictInfo),
            get_att_aid_guild(DictInfo2, GuildInfo#ets_guild.id, get());
        _ ->
            DictInfo
    end.

get_att_aid_guild(DictInfo, _GuildId, []) -> DictInfo;
get_att_aid_guild(DictInfo, GuildId, [H | T]) ->
    case H of
        {{aid, AidGuildId}, {1, GuildId, GuildInfo}} ->
            DictInfo2 = dict:store(AidGuildId, {0, 0, GuildInfo}, DictInfo),
            get_att_aid_guild(DictInfo2, GuildId, T);
        _ ->
            get_att_aid_guild(DictInfo, GuildId, T)
    end.

%% 防守方信息
init_def_info(DictInfo) ->
    case get(defender) of
        GuildInfo when is_record(GuildInfo, ets_guild) ->
            DictInfo2 = dict:store(GuildInfo#ets_guild.id, {0, 0, GuildInfo}, DictInfo),
            get_def_aid_guild(DictInfo2, GuildInfo#ets_guild.id, get());
        _ ->
            DictInfo
    end.

get_def_aid_guild(DictInfo, _GuildId, []) -> DictInfo;
get_def_aid_guild(DictInfo, GuildId, [H | T]) ->
    case H of
        {{aid, AidGuildId}, {2, GuildId, GuildInfo}} ->
            DictInfo2 = dict:store(AidGuildId, {0, 0, GuildInfo}, DictInfo),
            get_def_aid_guild(DictInfo2, GuildId, T);
        _ ->
            get_def_aid_guild(DictInfo, GuildId, T)
    end.

%% 获取复活点坐标
get_revive_xy(Status) ->
%%    ReviveList = case Status#player_status.group of
%%        %% 进攻方
%%        1 -> 
%%            case catch mod_city_war:get_revive_place(1) of
%%                _ReviveList when is_list(_ReviveList) ->
%%                    _ReviveList;
%%                _ ->
%%                    data_city_war:get_city_war_config(get_attacker_born)
%%            end;
%%        %% 防守方
%%        _ ->
%%            case catch mod_city_war:get_revive_place(2) of
%%                _ReviveList when is_list(_ReviveList) ->
%%                    _ReviveList;
%%                _ ->
%%                    lists:sublist(data_city_war:get_city_war_config(get_defender_born), 2)
%%            end
%%    end,
    ReviveList = Status#player_status.city_war_revive_place,
    [_RevX, _RevY] = get_closest_xy(Status#player_status.x, Status#player_status.y, ReviveList, [999, 999]),
    data_city_war:get_repair_xy(_RevX, _RevY).

%% 找到最近的复活点
get_closest_xy(_MyX, _MyY, [], [TempX, TempY]) -> [TempX, TempY];
get_closest_xy(MyX, MyY, [H | T], [TempX, TempY]) ->
    case H of
        [X1, Y1] ->
            case (MyX - X1) * (MyX - X1) + (MyY - Y1) * (MyY - Y1) < (MyX - TempX) * (MyX - TempX) + (MyY - TempY) * (MyY - TempY) of
                true -> 
                    get_closest_xy(MyX, MyY, T, [X1, Y1]);
                false ->
                    get_closest_xy(MyX, MyY, T, [TempX, TempY])
            end;
        _ ->
            get_closest_xy(MyX, MyY, T, [TempX, TempY])
    end.

%% 下线处理
logout_deal(PlayerStatus) ->
    mod_city_war:logout_deal(PlayerStatus),
    data_city_war:get_city_war_config(leave_scene),
    del_city_war_buff(PlayerStatus).

%% 登录处理
login_out(PlayerStatus) ->
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    case PlayerStatus#player_status.scene of
        CityWarSceneId ->
            mod_city_war:logout_deal(PlayerStatus),
            [LeaveScene, LeaveX, LeaveY] = data_city_war:get_city_war_config(leave_scene),
            PlayerStatus#player_status{
                scene = LeaveScene,
                x = LeaveX,
                y = LeaveY
            };
        _ ->
            PlayerStatus
    end.

%% 车房生成炸弹
create_bomb(CityWarInfo) ->
    AttackerRevivePlace = CityWarInfo#city_war_info.attacker_revive_place,
    CreatePlace = data_city_war:get_city_war_config(bomb_place),
    CityWarInfo2 = create_bomb_by_place(AttackerRevivePlace, CreatePlace, 1, CityWarInfo),
    CityWarInfo2.

%% 生成炸弹
create_bomb_by_place(_AttackerRevivePlace, [], _N, CityWarInfo) -> CityWarInfo;
create_bomb_by_place(AttackerRevivePlace, [H | T], N, CityWarInfo) ->
    %% 是否已占领车房
    case lists:member(H, AttackerRevivePlace) of
        true ->
            case H of
                [_X, _Y] ->
                    Bomb = case N of
                        1 ->
                            CityWarInfo#city_war_info.bomb_list1;
                        _ ->
                            CityWarInfo#city_war_info.bomb_list2
                    end,
                    BombNum = length(Bomb),
                    AllBomb = case N of
                        1 ->
                            data_city_war:get_city_war_config(get_all_bomb_list1);
                        _ ->
                            data_city_war:get_city_war_config(get_all_bomb_list2)
                    end,
                    AllBombNum = length(AllBomb),
                    %% 超过每个复活点最大数量
                    case BombNum >= AllBombNum of
                        true ->
                            CityWarInfo2 = CityWarInfo;
                        false ->
                            Rest = AllBomb -- Bomb,
                            [[NewX, NewY] | _T] = Rest,
                            BombTypeId = data_city_war:get_city_war_config(bomb_id1),
                            CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                            CopyId = 0,
                            Type = 0,  %% 0.被动 1.主动
                            BroadCast = 1,
                            Group1 = 2,
                            %% 生成采集炸弹
                            lib_mon:async_create_mon(BombTypeId, CityWarSceneId, NewX, NewY, Type, CopyId, BroadCast, [{group, Group1}]),
                            CityWarInfo2 = case N of
                                1 ->
                                    CityWarInfo#city_war_info{
                                        bomb_list1 = [[NewX, NewY] | Bomb]
                                    };
                                _ ->
                                    CityWarInfo#city_war_info{
                                        bomb_list2 = [[NewX, NewY] | Bomb]
                                    }
                            end
                    end;
                _ ->
                    CityWarInfo2 = CityWarInfo
            end;
        %% 未占领该车房
        false ->
            CityWarInfo2 = CityWarInfo
    end,
    create_bomb_by_place(AttackerRevivePlace, T, N + 1, CityWarInfo2).

%% 复活点内的炸弹数量减一
minus_revive_bomb(_Mid, X, Y) -> 
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            
            NewBomb1 = CityWarInfo#city_war_info.bomb_list1 -- [[X, Y]],
            NewBomb2 = CityWarInfo#city_war_info.bomb_list2 -- [[X, Y]],
            CityWarInfo2 = CityWarInfo#city_war_info{
                bomb_list1 = NewBomb1,
                bomb_list2 = NewBomb2
            },
            put(city_war_info, CityWarInfo2);
        _ ->
            skip
    end.

%% 复活点生成攻城车
create_car1(CityWarInfo) ->
    AttackerRevivePlace = CityWarInfo#city_war_info.attacker_revive_place,
    [Loc1, Loc2] = data_city_war:get_city_war_config(car_place1),
    case lists:member(Loc1, AttackerRevivePlace) of
        true -> 
            N = 2,
            CreatePlace1 = Loc1;
        false -> 
            N = 1,
            CreatePlace1 = Loc2
    end,
    NewCityWarInfo = create_car1_by_place(CreatePlace1, N, CityWarInfo),
    put(city_war_info, NewCityWarInfo).

%% 复活点生成弩车
create_car2(CityWarInfo) ->
    AttackerRevivePlace = CityWarInfo#city_war_info.attacker_revive_place,
    [Loc1, Loc2] = data_city_war:get_city_war_config(car_place2),
    case lists:member(Loc1, AttackerRevivePlace) of
        true ->
            N = 2,
            CreatePlace2 = Loc1;
        false -> 
            N = 1,
            CreatePlace2 = Loc2
    end,
    NewCityWarInfo = create_car2_by_place(CreatePlace2, N, CityWarInfo),
    put(city_war_info, NewCityWarInfo).

%% 生成攻城车
create_car1_by_place(CreatePlace, N, CityWarInfo) ->
    case CreatePlace of
        [_X, _Y] ->
            TotalCarNum = CityWarInfo#city_war_info.total_car_num,
            MaxTotalCarNum = data_city_war:get_city_war_config(get_max_total_car_num),
            %io:format("TotalCarNum:~p, MaxTotalCarNum:~p~n", [TotalCarNum, MaxTotalCarNum]),
            %% 超过场上最多存在攻城车数量
            case TotalCarNum >= MaxTotalCarNum of
                true ->
                    CityWarInfo2 = CityWarInfo;
                false ->
                    Car = case N of
                        1 -> CityWarInfo#city_war_info.car1_list1;
                        _ -> CityWarInfo#city_war_info.car1_list2
                    end,
                    CarNum = length(Car),
                    %io:format("N:~p, CarNum:~p, TotalCarNum:~p~n", [N, CarNum, TotalCarNum]),
                    AllCar = case N of
                        1 -> data_city_war:get_city_war_config(get_all_car1_list1);
                        _ -> data_city_war:get_city_war_config(get_all_car1_list2)
                    end,
                    AllCarNum = length(AllCar),
                    %io:format("Car:~p, AllCar:~p~n", [Car, AllCar]),
                    %% 超过每个复活点最大数量
                    case CarNum >= AllCarNum of
                        true ->
                            CityWarInfo2 = CityWarInfo;
                        false ->
                            Rest = AllCar -- Car,
                            [[NewX, NewY] | _T] = Rest,
                            CarTypeId1 = data_city_war:get_city_war_config(car_id1),
                            CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                            CopyId = 0,
                            Type = 0,  %% 0.被动 1.主动
                            BroadCast = 1,
                            Group1 = 2,
                            %% 生成采集攻城车
                            lib_mon:async_create_mon(CarTypeId1, CityWarSceneId, NewX, NewY, Type, CopyId, BroadCast, [{group, Group1}]),
                            CollectCarNum = CityWarInfo#city_war_info.collect_car_num,
                            CityWarInfo2 = case N of
                                1 -> 
                                    CityWarInfo#city_war_info{
                                        car1_list1 = [[NewX, NewY] | Car],
                                        total_car_num = TotalCarNum + 1,
                                        collect_car_num = CollectCarNum + 1
                                    };
                                _ -> 
                                    CityWarInfo#city_war_info{
                                        car1_list2 = [[NewX, NewY] |Car],
                                        total_car_num = TotalCarNum + 1,
                                        collect_car_num = CollectCarNum + 1
                                    }
                            end
                    end
            end;
        _ ->
            CityWarInfo2 = CityWarInfo
    end,
    CityWarInfo2.

%% 生成弩车
create_car2_by_place(CreatePlace, N, CityWarInfo) ->
    case CreatePlace of
        [_X, _Y] ->
            TotalCarNum = CityWarInfo#city_war_info.total_car_num,
            MaxTotalCarNum = data_city_war:get_city_war_config(get_max_total_car_num),
            %% 超过场上最多存在攻城车数量
            case TotalCarNum >= MaxTotalCarNum of
                true ->
                    CityWarInfo2 = CityWarInfo;
                false ->
                    Car = case N of
                        1 -> CityWarInfo#city_war_info.car2_list1;
                        _ -> CityWarInfo#city_war_info.car2_list2
                    end,
                    CarNum = length(Car),
                    AllCar = case N of
                        1 -> data_city_war:get_city_war_config(get_all_car2_list1);
                        _ -> data_city_war:get_city_war_config(get_all_car2_list2)
                    end,
                    AllCarNum = length(AllCar),
                    %% 超过每个复活点最大数量
                    case CarNum >= AllCarNum of
                        true ->
                            CityWarInfo2 = CityWarInfo;
                        false ->
                            Rest = AllCar -- Car,
                            [[NewX, NewY] | _T] = Rest,
                            CarTypeId2 = data_city_war:get_city_war_config(car_id2),
                            CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                            CopyId = 0,
                            Type = 0,  %% 0.被动 1.主动
                            BroadCast = 1,
                            Group1 = 2,
                            %% 生成采集弩车
                            lib_mon:async_create_mon(CarTypeId2, CityWarSceneId, NewX, NewY, Type, CopyId, BroadCast, [{group, Group1}]),
                            CollectCarNum = CityWarInfo#city_war_info.collect_car_num,
                            CityWarInfo2 = case N of
                                1 -> 
                                    CityWarInfo#city_war_info{
                                        car2_list1 = [[NewX, NewY] | Car],
                                        total_car_num = TotalCarNum + 1,
                                        collect_car_num = CollectCarNum + 1
                                    };
                                _ -> 
                                    CityWarInfo#city_war_info{
                                        car2_list2 = [[NewX, NewY] | Car],
                                        total_car_num = TotalCarNum + 1,
                                        collect_car_num = CollectCarNum + 1
                                    }
                            end
                    end
            end;
        _ ->
            CityWarInfo2 = CityWarInfo
    end,
    CityWarInfo2.

%% 复活点内的攻城车数量减一
minus_revive_car(_Mid, X, Y) -> 
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            %io:format("XY:~p, car1list1:~p~n", [[X, Y], CityWarInfo#city_war_info.car1_list1]),
            NewCar1List1 = CityWarInfo#city_war_info.car1_list1 -- [[X, Y]],
            NewCar1List2 = CityWarInfo#city_war_info.car1_list2 -- [[X, Y]],
            NewCar2List1 = CityWarInfo#city_war_info.car2_list1 -- [[X, Y]],
            NewCar2List2 = CityWarInfo#city_war_info.car2_list2 -- [[X, Y]],
            CityWarInfo2 = CityWarInfo#city_war_info{
                car1_list1 = NewCar1List1,
                car1_list2 = NewCar1List2,
                car2_list1 = NewCar2List1,
                car2_list2 = NewCar2List2
            },
            put(city_war_info, CityWarInfo2);
        _ ->
            skip
    end.

%%get_revive_place([], _X, _Y, _N) -> 0;
%%get_revive_place([H | T], X, Y, N) -> 
%%    case H of
%%        [RevX, RevY] ->
%%            case (RevX - X) * (RevX - X) + (RevY - Y) * (RevY - Y) =< 49 of
%%                true ->
%%                    N;
%%                false ->
%%                    get_revive_place(T, X, Y, N + 1)
%%            end;
%%        _ ->
%%            get_revive_place(T, X, Y, N + 1)
%%    end.

%% 攻城车总数减一
minus_a_car() ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            TotalCarNum = CityWarInfo#city_war_info.total_car_num,
            NewTotalCarNum = case TotalCarNum > 0 of
                true -> TotalCarNum - 1;
                false -> 0
            end,
            CityWarInfo2 = CityWarInfo#city_war_info{
                total_car_num = NewTotalCarNum
            },
            put(city_war_info, CityWarInfo2);
        _ ->
            skip
    end.

%% 杀戮处理
%% PlayerStatus  杀人者
%% KilledStatus  被杀者
%% HitList: 攻击列表 [{玩家Key，攻击时间(ms)}]
kill_deal(PlayerStatus, KilledStatus, HitList) ->
    %% 加入死亡列表
    %mod_city_war:die_deal(KilledStatus#player_status.id),
    %% 计算得分
    %% 个人积分
    mod_city_war:add_score(PlayerStatus#player_status.id, 5),
    mod_city_war:add_score(KilledStatus#player_status.id, 1),
    %% 助攻积分
    add_help_score(HitList, PlayerStatus#player_status.id),
    %% 帮派积分
    mod_city_war:add_guild_score(PlayerStatus#player_status.guild#status_guild.guild_id, 5),
    mod_city_war:add_guild_score(KilledStatus#player_status.guild#status_guild.guild_id, 1),
    %% 是否为攻城车
    case lists:member(KilledStatus#player_status.factionwar_stone, [11, 12]) of
        true ->
            %% 攻城车总数量减一
            %mod_city_war:minus_a_car();
            skip;
        false ->
            skip
    end,
    %% 是否为医仙、鬼巫
    case lists:member(KilledStatus#player_status.factionwar_stone, [15, 16]) of
        true ->
            %% 医仙、鬼巫数量减一
            mod_city_war:minus_a_career(KilledStatus);
        false ->
            skip
    end,
    NewStone = 0,
    lib_player:update_player_info(KilledStatus#player_status.id, [{factionwar_stone, NewStone}]).
    %% 是否不为攻城车
    %case lists:member(KilledStatus#player_status.factionwar_stone, [11, 12]) of
    %    true ->
    %        skip;
        %% 变为灵魂状态
    %    false ->
    %        mod_city_war:die_deal([KilledStatus#player_status.id, KilledStatus#player_status.guild#status_guild.guild_id]),
    %        lib_player:update_player_info(KilledStatus#player_status.id, [{factionwar_stone, NewStone}])
    %end.

%% 被怪物杀死
killed_by_mon(KilledStatus) ->
    %% 加入死亡列表
    %mod_city_war:die_deal(KilledStatus#player_status.id),
    %% 计算得分
    %% 个人积分
    mod_city_war:add_score(KilledStatus#player_status.id, 1),
    %% 帮派积分
    mod_city_war:add_guild_score(KilledStatus#player_status.guild#status_guild.guild_id, 1),
    %% 是否为攻城车
    case lists:member(KilledStatus#player_status.factionwar_stone, [11, 12]) of
        true ->
            %% 攻城车总数量减一
            %mod_city_war:minus_a_car();
            skip;
        false ->
            skip
    end,
    %% 是否为医仙、鬼巫
    case lists:member(KilledStatus#player_status.factionwar_stone, [15, 16]) of
        true ->
            %% 医仙、鬼巫数量减一
            mod_city_war:minus_a_career(KilledStatus);
        false ->
            skip
    end,
    NewStone = 0,
    lib_player:update_player_info(KilledStatus#player_status.id, [{factionwar_stone, NewStone}]).
%%    %% 是否不为攻城车
%%    case lists:member(KilledStatus#player_status.factionwar_stone, [11, 12]) of
%%        true ->
%%            skip;
%%        %% 变为灵魂状态
%%        false ->
%%            mod_city_war:die_deal([KilledStatus#player_status.id, KilledStatus#player_status.guild#status_guild.guild_id]),
%%            lib_player:update_player_info(KilledStatus#player_status.id, [{force_change_pk_status, 7}])
%%    end,
%%    lib_player:update_player_info(KilledStatus#player_status.id, [{factionwar_stone, NewStone}]).

%% 定时复活
timing_revive(State) ->
    Days = [State#city_war_state.open_days],
    NowDay = calendar:day_of_the_week(date()),
    case lists:member(NowDay, Days) of
        true ->
            ConfigBeginTime = {State#city_war_state.config_begin_hour, State#city_war_state.config_begin_minute, 0},
            ConfigEndTime = {State#city_war_state.config_end_hour, State#city_war_state.config_end_minute, 0},
            %% 是否在活动时间内
            case time() >= ConfigBeginTime andalso time() =< ConfigEndTime of
                true -> 
                    {_Hour, _Min, _Sec} = time(),
                    %% 20秒定时复活
                    case _Sec div 10 rem 2 of
                        0 ->
                            case get(city_war_info) of
                                CityWarInfo when is_record(CityWarInfo, city_war_info) ->
                                    DieList = CityWarInfo#city_war_info.die_list,
                                    spawn(fun() ->
                                                revive(DieList)
                                        end),
                                    CityWarInfo2 = CityWarInfo#city_war_info{
                                        next_revive_time = util:unixtime() + 20
                                    },
                                    put(city_war_info, CityWarInfo2);
                                _ ->
                                    skip
                            end;
                        _ ->
                            skip
                    end;
                false ->
                    skip
            end;
        false ->
            skip
    end.

revive([]) -> skip;
revive([H | T]) ->
    case is_integer(H) of
        true ->
            lib_player:update_player_info(H, [{force_change_pk_status, 99}]);
        false ->
            skip
    end,
    revive(T).

%%revive1(_RevivePlace, [], CityWarInfo, _Type) -> CityWarInfo;
%%revive1(RevivePlace, [H | T], CityWarInfo, Type) ->
%%    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
%%    {Scene, _CopyId2, X, Y} = case lib_player:get_player_info(H, position_info) of
%%        {_Scene, _CopyId, _X, _Y} -> {_Scene, _CopyId, _X, _Y};
%%        _ -> {0, 0, 0, 0}
%%    end,
%%    CityWarInfo2 = case Scene of
%%        CityWarSceneId ->
%%            revive2(RevivePlace, H, X, Y, CityWarInfo, Type);
%%        _ ->
%%            CityWarInfo
%%    end,
%%    revive1(RevivePlace, T, CityWarInfo2, Type).
%%
%%revive2([], _PlayerId, _X, _Y, CityWarInfo, _Type) -> CityWarInfo;
%%revive2([H | T], PlayerId, X, Y, CityWarInfo, Type) ->
%%    %io:format("1~n"),
%%    case H of
%%        [_RevX, _RevY] ->
%%            %io:format("2:~p~n", [(RevX - X) * (RevX - X) + (RevY - Y) * (RevY - Y)]),
%%            [RevX, RevY] = data_city_war:get_repair_xy(_RevX, _RevY),
%%            %io:format("RevX:~p, RevY:~p~n", [RevX, RevY]),
%%            case (RevX - X) * (RevX - X) + (RevY - Y) * (RevY - Y) =< 49 of
%%                %% 复活
%%                true ->
%%                    lib_player:update_player_info(PlayerId, [{force_change_pk_status, 99}]),
%%                    AttackerDieList = CityWarInfo#city_war_info.attacker_die_list,
%%                    DefenderDieList = CityWarInfo#city_war_info.defender_die_list,
%%                    %NewAttackerDieList = case Type of
%%                    %    1 -> lists:delete(PlayerId, AttackerDieList);
%%                    %    _ -> AttackerDieList
%%                    %end,
%%                    NewAttackerDieList = AttackerDieList,
%%                    %NewDefenderDieList = case Type of
%%                    %    1 -> DefenderDieList;
%%                    %    _ -> lists:delete(PlayerId, DefenderDieList)
%%                    %end,
%%                    NewDefenderDieList = DefenderDieList,
%%                    %io:format("NewAttackerDieList:~p~n", [NewAttackerDieList]),
%%                    CityWarInfo2 = CityWarInfo#city_war_info{
%%                        attacker_die_list = NewAttackerDieList,
%%                        defender_die_list = NewDefenderDieList
%%                    },
%%                    CityWarInfo2;
%%                %% 距离太远
%%                false ->
%%                    revive2(T, PlayerId, X, Y, CityWarInfo, Type)
%%            end;
%%        _ ->
%%            revive2(T, PlayerId, X, Y, CityWarInfo, Type)
%%    end.

%% 把全部人清出场
clear_all_out() ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            PlayerInfo = CityWarInfo#city_war_info.player_info,
            PlayerList = dict:to_list(PlayerInfo),
            spawn(fun() ->
                        timer:sleep(8 * 1000),
                        send_all_out(PlayerList)
                end);
        _ ->
            skip
    end.

send_all_out([]) -> skip;
send_all_out([H | T]) ->
    case H of
        {PlayerId, _} ->
            lib_player:update_player_info(PlayerId, [{group, 0}, {factionwar_stone, 0}, {city_war_clear_out, no}, {force_change_pk_status, 0}]),
            lib_player_unite:update_unite_info(PlayerId, [{group, 0}]);
        _ ->
            skip
    end,
    send_all_out(T).

%% 结算
account() ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            Count = CityWarInfo#city_war_info.count,
            PlayerInfo = CityWarInfo#city_war_info.player_info,
            PlayerList = dict:to_list(PlayerInfo),
            %% 给所有玩家加分
            all_add_score(PlayerList, Count);
        _ ->
            skip
    end.

%% 给所有玩家加分
all_add_score([], _Count) -> skip;
all_add_score([H | T], Count) ->
    case H of
        {PlayerId, {State, _Score}} ->
            AddScore = case Count of
                2 ->
                    case State of
                        1 -> 200;
                        _ -> 100
                    end;
                _ ->
                    case State of
                        1 -> 100;
                        _ -> 200
                    end
            end,
            lib_player:update_player_info(PlayerId, [{city_war_account_add, AddScore}]);
        _ ->
            skip
    end,
    all_add_score(T, Count).

%% 弹出结算面板、发送奖励
end_deal(Type) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            spawn(fun() ->
                        end_city_war_log()
                end),
            %WarNum = CityWarInfo#city_war_info.count,
            %% 打了2场，则攻守互换
            %case WarNum of
            %    2 ->
            %        DefenderInfo = CityWarInfo#city_war_info.attacker_info,
            %        AttackerInfo = CityWarInfo#city_war_info.defender_info;
            %    _ ->
            %        AttackerInfo = CityWarInfo#city_war_info.attacker_info,
            %        DefenderInfo = CityWarInfo#city_war_info.defender_info
            %end,
            AttackerInfo = CityWarInfo#city_war_info.attacker_info,
            DefenderInfo = CityWarInfo#city_war_info.defender_info,
            AttackerList = dict:to_list(AttackerInfo),
            DefenderList = dict:to_list(DefenderInfo),
            GuildList1 = guild_list_deal(AttackerList, []),
            GuildList2 = guild_list_deal(DefenderList, []),
            PlayerInfo = CityWarInfo#city_war_info.player_info,
            PlayerList = dict:to_list(PlayerInfo),
            [PlayerList1, PlayerList2] = player_list_deal(PlayerList, [], []),
            %% 通过判断龙珠是否已被破坏判断胜利方
            %CityWarSceneId = data_city_war:get_city_war_config(scene_id),
            %EtsMon = mod_scene_agent:apply_call(CityWarSceneId, lib_mon, lookup, [CityWarSceneId, CityWarInfo#city_war_info.center_mon_id]),
            %CenterMon = case EtsMon of
            %    %% call失败，默认防守方胜利
            %    skip -> #ets_mon{hp = 1};
            %    _ -> EtsMon
            %end,
            %WinnerInfo = case is_record(CenterMon, ets_mon) =:= true andalso CenterMon#ets_mon.hp > 0 of
            WinnerInfo = case Type =:= 1 of
                %% 守住龙珠，防守方赢
                true ->
                    case get(defender) of
                        GuildInfo when is_record(GuildInfo, ets_guild) ->
                            GuildInfo;
                        _ ->
                            void
                    end;
                %% 打完龙珠，进攻方赢
                false -> 
                    case get(attacker) of
                        GuildInfo when is_record(GuildInfo, ets_guild) ->
                            GuildInfo;
                        _ ->
                            void
                    end
            end,
%%            WinnerInfo = case WarNum of
%%                2 ->
%%                    case get(attacker) of
%%                        GuildInfo when is_record(GuildInfo, ets_guild) ->
%%                            GuildInfo;
%%                        _ ->
%%                            void
%%                    end;
%%                1 ->
%%                    case get(defender) of
%%                        GuildInfo when is_record(GuildInfo, ets_guild) ->
%%                            GuildInfo;
%%                        _ ->
%%                            void
%%                    end;
%%                _ ->
%%                    case ThreeOver of
%%                        %% 3场打完龙珠，进攻方赢
%%                        true -> 
%%                            case get(attacker) of
%%                                GuildInfo when is_record(GuildInfo, ets_guild) ->
%%                                    GuildInfo;
%%                                _ ->
%%                                    void
%%                            end;
%%                        %% 守住龙珠，防守方赢
%%                        false ->
%%                            case get(defender) of
%%                                GuildInfo when is_record(GuildInfo, ets_guild) ->
%%                                    GuildInfo;
%%                                _ ->
%%                                    void
%%                            end
%%                    end
%%            end,
%%            Winner = case WarNum of
%%                2 -> 1;
%%                1 -> 2;
%%                _ ->
%%                    case ThreeOver of
%%                        %% 3场打完龙珠，进攻方赢
%%                        true -> 1;
%%                        %% 守住龙珠，防守方赢
%%                        false -> 2
%%                    end
%%            end,
            %Winner = case is_record(CenterMon, ets_mon) =:= true andalso CenterMon#ets_mon.hp > 0 of
            Winner = case Type =:= 1 of
                %% 守住龙珠，防守方赢
                true -> 2;
                %% 打完龙珠，进攻方赢
                false -> 1
            end,
            %% 给所有玩家发送奖励
            send_player_award(PlayerList, Winner),
            %% 修改所有玩家PS
            LAllPlayerId = mod_chat_agent:match(all_ids_by_lv_gap, [0, 999]),
            spawn(fun()-> 
                        %% 等15秒结算时间
                        timer:sleep(15 * 1000),
                        lists:foreach(fun(EachPlayerId) -> 
                                    lib_player:update_player_info(EachPlayerId, [{is_city_war_win, no}]),
                                    timer:sleep(300)
                            end, LAllPlayerId)
                end),
            %% 给长安城主发送奖励
            %case is_record(CenterMon, ets_mon) =:= true andalso CenterMon#ets_mon.hp > 0 of
            case Type =:= 1 of
                %% 守住龙珠，防守方赢
                true ->
                    case get(defender) of
                        DefenderGuildInfo when is_record(DefenderGuildInfo, ets_guild) ->
                            %% 获取最新信息
                            NewGuildInfo = lib_guild:get_guild(DefenderGuildInfo#ets_guild.id),
                            case is_record(NewGuildInfo, ets_guild) of
                                true ->
                                    CityOwnerId = NewGuildInfo#ets_guild.chief_id,
                                    CityOwnerId2 = NewGuildInfo#ets_guild.deputy_chief1_id,
                                    CityOwnerId3 = NewGuildInfo#ets_guild.deputy_chief2_id;
                                false ->
                                    CityOwnerId = error,
                                    CityOwnerId2 = error,
                                    CityOwnerId3 = error
                            end;
                        _ ->
                            CityOwnerId = error,
                            CityOwnerId2 = error,
                            CityOwnerId3 = error
                    end;
                %% 打完龙珠，进攻方赢
                false ->
                    case get(attacker) of
                        AttackerGuildInfo when is_record(AttackerGuildInfo, ets_guild) ->
                            %% 获取最新信息
                            NewGuildInfo = lib_guild:get_guild(AttackerGuildInfo#ets_guild.id),
                            case is_record(NewGuildInfo, ets_guild) of
                                true ->
                                    CityOwnerId = NewGuildInfo#ets_guild.chief_id,
                                    CityOwnerId2 = NewGuildInfo#ets_guild.deputy_chief1_id,
                                    CityOwnerId3 = NewGuildInfo#ets_guild.deputy_chief2_id;
                                false ->
                                    CityOwnerId = error,
                                    CityOwnerId2 = error,
                                    CityOwnerId3 = error
                            end;
                        _ ->
                            %AllScore = 0,
                            CityOwnerId = error,
                            CityOwnerId2 = error,
                            CityOwnerId3 = error
                    end
            end,
%%            case WarNum of
%%                2 ->
%%                    case get(attacker) of
%%                        AttackerGuildInfo when is_record(AttackerGuildInfo, ets_guild) ->
%%                            %AllScore = get_all_score(AttackerList, 0),
%%                            %io:format("Name:~p~n", [AttackerGuildInfo#ets_guild.id]),
%%                            CityOwnerId = AttackerGuildInfo#ets_guild.chief_id;
%%                        _ ->
%%                            %AllScore = 0,
%%                            CityOwnerId = error
%%                    end;
%%                1 ->
%%                    case get(defender) of
%%                        DefenderGuildInfo when is_record(DefenderGuildInfo, ets_guild) ->
%%                            %AllScore = get_all_score(DefenderList, 0),
%%                            %io:format("Name:~p~n", [DefenderGuildInfo#ets_guild.id]),
%%                            CityOwnerId = DefenderGuildInfo#ets_guild.chief_id;
%%                        _ ->
%%                            %AllScore = 0,
%%                            CityOwnerId = error
%%                    end;
%%                _ ->
%%                    case ThreeOver of
%%                        %% 3场打完龙珠，进攻方赢
%%                        true ->
%%                            case get(attacker) of
%%                                AttackerGuildInfo when is_record(AttackerGuildInfo, ets_guild) ->
%%                                    %AllScore = get_all_score(AttackerList, 0),
%%                                    %io:format("Name:~p~n", [AttackerGuildInfo#ets_guild.id]),
%%                                    CityOwnerId = AttackerGuildInfo#ets_guild.chief_id;
%%                                _ ->
%%                                    %AllScore = 0,
%%                                    CityOwnerId = error
%%                            end;
%%                        %% 守住龙珠，防守方赢
%%                        false ->
%%                            case get(defender) of
%%                                DefenderGuildInfo when is_record(DefenderGuildInfo, ets_guild) ->
%%                                    %AllScore = get_all_score(DefenderList, 0),
%%                                    %io:format("Name:~p~n", [DefenderGuildInfo#ets_guild.id]),
%%                                    CityOwnerId = DefenderGuildInfo#ets_guild.chief_id;
%%                                _ ->
%%                                    %AllScore = 0,
%%                                    CityOwnerId = error
%%                            end
%%                    end
%%            end,
            %% 通过邮件发送奖励
            case is_integer(CityOwnerId) of
                true ->
                    %% 帮主奖励
                    Title = data_city_war_text:get_city_war_text(9),
                    Content = data_city_war_text:get_city_war_text(10),
                    Coin = 100 * 10000,
                    lib_mail:send_sys_mail_bg([CityOwnerId], Title, Content, 0, 0, 0, 0, 0, 0, Coin, 0, 0),
                    %% 副帮主奖励
                    Title2 = data_city_war_text:get_city_war_text(23),
                    Content2 = data_city_war_text:get_city_war_text(24),
                    Coin2 = 20 * 10000,
                    lib_mail:send_sys_mail_bg([CityOwnerId2, CityOwnerId3], Title2, Content2, 0, 0, 0, 0, 0, 0, Coin2, 0, 0),
                    %% 移除称号
                    lib_designation:remove_design_by_id(201504),
                    lib_designation:remove_design_by_id(201505),
                    %% 长安城主称号
                    lib_designation:bind_design_in_server(CityOwnerId, 201501, "", 1),
                    %% 配偶称号
                    case db:get_row(io_lib:format(<<"select pl.id, pl.sex from player_low as pl, marriage as m where (m.male_id = ~p and m.female_id = pl.id and m.divorce = 0 and m.register_time > 0) or (m.female_id = ~p and m.male_id = pl.id and m.divorce = 0 and m.register_time > 0) limit 1">>, [CityOwnerId, CityOwnerId])) of
                        [ParnerId, ParnerSex] ->
                            case ParnerSex of
                                %% 长安亲王
                                1 ->
                                    lib_designation:bind_design_in_server(ParnerId, 201505, "", 1);
                                %% 长安夫人
                                _ ->
                                    lib_designation:bind_design_in_server(ParnerId, 201504, "", 1)
                            end;
                        _ ->
                            skip
                    end;
                false ->
                    skip
            end,
            case is_record(WinnerInfo, ets_guild) of
                true -> 
                    db:execute(io_lib:format(<<"insert into log_city_war set winner_guild_id = ~p, win_time = ~p">>, [WinnerInfo#ets_guild.id, util:unixtime()]));
                false -> 
                    skip
            end,
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
            %io:format("GuildList1:~p, Winner:~p~n", [GuildList1, Winner]),
            {ok, BinData} = pt_641:write(64116, [GuildList1, PlayerList1, GuildList2, PlayerList2, Winner, AttackerName, DefenderName]),
            %% 清数据
            erase(),
            %% 给所有玩家发送结算面板
            spawn(fun() ->
                        timer:sleep(20 * 1000),
                        send_to_all(PlayerList, BinData)
                end),
            %% 触发更新雕像
            update_statue(),
            %% 更新胜利方数据
            init_win_info();
        _ ->
            skip
    end.

guild_list_deal([], L) -> L;
guild_list_deal([H | T], L) ->
    case H of
        {_GuildId, {_OnlineNum, Score, EtsGuild}} ->
            guild_list_deal(T, [{EtsGuild#ets_guild.name, Score} | L]);
        _ ->
            guild_list_deal(T, L)
    end.

player_list_deal([], L1, L2) -> [L1, L2];
player_list_deal([H | T], L1, L2) ->
    case H of
        {PlayerId, {State, Score}} ->
            PlayerName = case get({player_info, PlayerId}) of
                _PlayerName when is_list(_PlayerName) ->
                    _PlayerName;
                _ ->
                    "notfound"
            end,
            case State of
                %% 进攻方
                1 ->
                    player_list_deal(T, [{PlayerName, Score} | L1], L2);
                _ ->
                    player_list_deal(T, L1, [{PlayerName, Score} | L2])
            end;
        _ ->
            player_list_deal(T, L1, L2)
    end.

send_to_all([], _BinData) -> skip;
send_to_all([H | T], BinData) ->
    case H of
        {PlayerId, _} ->
            lib_unite_send:send_to_uid(PlayerId, BinData);
        _ ->
            skip
    end,
    send_to_all(T, BinData).

%% 结算，玩家发送奖励
send_player_award([], _Winner) -> skip;
send_player_award([H | T], Winner) ->
    case H of
        {PlayerId, {State, Score}} ->
            MinScore = data_city_war:get_city_war_config(min_score),
            case State of
                %% 胜利方
                Winner ->
                    case Score >= MinScore of
                        true ->
                            case get({player_state, PlayerId}) of
                                1 ->
                                    Title0 = data_city_war_text:get_city_war_text(11),
                                    Content0 = data_city_war_text:get_city_war_text(12),
                                    GoodsId0 = 532254,
                                    GoodsNum0 = 1;
                                _ ->
                                    Title0 = data_city_war_text:get_city_war_text(17),
                                    Content0 = data_city_war_text:get_city_war_text(19),
                                    GoodsId0 = 532257,
                                    GoodsNum0 = 1
                            end,
                            %% 发送邮件奖励(胜利、失败结算)
                            lib_mail:send_sys_mail_bg([PlayerId], Title0, Content0, GoodsId0, 2, 0, 0, GoodsNum0, 0, 0, 0, 0);
                        %% 无法领取攻城战奖励
                        false ->
                            Title0 = data_city_war_text:get_city_war_text(15),
                            Content0 = io_lib:format(data_city_war_text:get_city_war_text(16), [MinScore]),
                            lib_mail:send_sys_mail_bg([PlayerId], Title0, Content0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                    end,
                    case misc:get_player_process(PlayerId) of
                        %% 玩家在线
                        Pid when is_pid(Pid) ->
                            AttrKeyValueList = [{city_war_award, Score}],
                            gen_server:cast(Pid, {'set_data', AttrKeyValueList});
                        %% 玩家不在线
                        _ ->
                            %db:execute(io_lib:format(<<"insert into player_city_war set player_id = ~p, last_add_time = ~p, score = ~p ON DUPLICATE KEY UPDATE last_add_time = ~p, score = score + ~p">>, [PlayerId, util:unixtime(), 200, util:unixtime(), 200])),
                            WarScore = Score,
                            db:execute(io_lib:format(<<"insert into player_factionwar set id = ~p, war_score = ~p, war_last_time = ~p ON DUPLICATE KEY UPDATE war_score = war_score + ~p">>, [PlayerId, WarScore, util:unixtime(), WarScore])),
                            GoodsId = 221003,
                            PlayerLv = case lib_player:get_player_info(PlayerId, lv) of
                                _PlayerLv when is_integer(_PlayerLv) ->
                                    _PlayerLv;
                                _ ->
                                    40
                            end,
                            AllExp = PlayerLv * PlayerLv * 600,
                            GoodsNum = AllExp div 50000,
                            Title = data_city_war_text:get_city_war_text(6),
                            Content = data_city_war_text:get_city_war_text(7),
                            lib_mail:send_sys_mail_bg([PlayerId], Title, Content, GoodsId, 2, 0, 0, GoodsNum, 0, 0, 0, 0)
                    end;
                %% 失败方
                _ ->
                    case Score >= MinScore of
                        true ->
                            case get({player_state, PlayerId}) of
                                1 ->
                                    Title0 = data_city_war_text:get_city_war_text(13),
                                    Content0 = data_city_war_text:get_city_war_text(14),
                                    GoodsId0 = 532255,
                                    GoodsNum0 = 1;
                                _ ->
                                    Title0 = data_city_war_text:get_city_war_text(18),
                                    Content0 = data_city_war_text:get_city_war_text(20),
                                    GoodsId0 = 532257,
                                    GoodsNum0 = 1
                            end,
                            %% 发送邮件奖励(胜利、失败结算)
                            lib_mail:send_sys_mail_bg([PlayerId], Title0, Content0, GoodsId0, 2, 0, 0, GoodsNum0, 0, 0, 0, 0);
                        false ->
                            Title0 = data_city_war_text:get_city_war_text(15),
                            Content0 = io_lib:format(data_city_war_text:get_city_war_text(16), [MinScore]),
                            lib_mail:send_sys_mail_bg([PlayerId], Title0, Content0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                    end,
                    case misc:get_player_process(PlayerId) of
                        %% 玩家在线
                        Pid when is_pid(Pid) ->
                            AttrKeyValueList = [{city_war_award, Score}],
                            gen_server:cast(Pid, {'set_data', AttrKeyValueList});
                        %% 玩家不在线
                        _ ->
                            %db:execute(io_lib:format(<<"insert into player_city_war set player_id = ~p, last_add_time = ~p, score = ~p ON DUPLICATE KEY UPDATE last_add_time = ~p, score = score + ~p">>, [PlayerId, util:unixtime(), 100, util:unixtime(), 100])),
                            WarScore = Score,
                            db:execute(io_lib:format(<<"insert into player_factionwar set id = ~p, war_score = ~p, war_last_time = ~p ON DUPLICATE KEY UPDATE war_score = war_score + ~p">>, [PlayerId, WarScore, util:unixtime(), WarScore])),
                            GoodsId = 221003,
                            PlayerLv = case lib_player:get_player_info(PlayerId, lv) of
                                _PlayerLv when is_integer(_PlayerLv) ->
                                    _PlayerLv;
                                _ ->
                                    40
                            end,
                            AllExp = PlayerLv * PlayerLv * 300,
                            GoodsNum = AllExp div 50000,
                            Title = data_city_war_text:get_city_war_text(6),
                            Content = data_city_war_text:get_city_war_text(8),
                            lib_mail:send_sys_mail_bg([PlayerId], Title, Content, GoodsId, 2, 0, 0, GoodsNum, 0, 0, 0, 0)
                    end
            end;
        _ ->
            skip
    end,
    send_player_award(T, Winner).

%% 统计所有帮派的积分
%%get_all_score([], AllScore) -> AllScore;
%%get_all_score([H | T], AllScore) ->
%%    case H of
%%        {_GuildId, {_OnlineNum, Score, _EtsGuild}} ->
%%            get_all_score(T, AllScore + Score);
%%        _ ->
%%            get_all_score(T, AllScore)
%%    end.

%% 助攻积分
add_help_score([], _KillId) -> ok;
add_help_score([H | T], KillId) ->
    case H of
        {[PlayerId, _, _], _Time} ->
            case PlayerId =/= KillId of
                true ->
                    mod_city_war:add_score(PlayerId, 1);
                false ->
                    skip
            end;
        _ ->
            skip
    end,
    add_help_score(T, KillId).

logout_re_status(Status) ->
    Status2 = case Status#player_status.factionwar_stone of
        0 -> Status;
        _ -> Status#player_status{
                factionwar_stone = 0
            }
    end,
    Pk = Status#player_status.pk,
    Status3 = case Pk#status_pk.pk_status of
        7 -> 
            Status2#player_status{
                pk = Pk#status_pk{
                    pk_status = 0
                }
            };
        _ -> 
            Status2
    end,
    mod_scene_agent:update(pk, Status3),
    %通知场景的玩家
    {ok, BinData} = pt_120:write(12084, [Status3#player_status.id, Status3#player_status.platform, Status3#player_status.server_num, Status3#player_status.pk#status_pk.pk_status, Pk#status_pk.pk_value]),
    lib_server_send:send_to_scene(Status3#player_status.scene, Status3#player_status.copy_id, BinData),
    Status3.

%% 图标0
picture0([UniteStatus, State]) ->
    NowDay = calendar:day_of_the_week(date()),
    UnixBeginTime = util:unixdate() + (State#city_war_state.seize_days - NowDay) * 24 * 3600 + State#city_war_state.config_begin_hour * 3600 + State#city_war_state.config_begin_minute * 60,
    UnixEndTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.config_end_hour * 3600 + State#city_war_state.config_end_minute * 60,
    case util:unixtime() >= UnixBeginTime andalso util:unixtime() =< UnixEndTime of
        false -> 
            case get(winner_info) of
                WinnerInfo when is_list(WinnerInfo) ->
                    ok;
                _ ->
                    WinnerInfo = ""
            end,
            NowDay = calendar:day_of_the_week(date()),
            UnixBeginTime2 = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.config_begin_hour * 3600 + State#city_war_state.config_begin_minute * 60,
            %io:format("open_days:~p~n", [State#city_war_state.open_days]),
            _RestTime = UnixBeginTime2 - util:unixtime(),
            RestTime = case _RestTime > 0 of
                true -> _RestTime;
                false -> 0
            end,
            WinnerInfo2 = WinnerInfo ++ [RestTime],
            %io:format("WinnerInfo2:~p~n", [WinnerInfo2]),
            {ok, BinData} = pt_641:write(64100, WinnerInfo2),
            lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData);
        true -> 
            skip
    end.

%% 图标1
picture1([UniteStatus, State]) ->
    %% 最低参与等级
    MinLv = data_city_war:get_city_war_config(min_lv),
    case UniteStatus#unite_status.lv < MinLv of
        true ->
            skip;
        false ->
            %% 是否为活动日
            case lists:member(calendar:day_of_the_week(date()), [State#city_war_state.seize_days, State#city_war_state.open_days]) of
                false ->
                    skip;
                true ->
                    NowDay = calendar:day_of_the_week(date()),
                    UnixBeginTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.config_begin_hour * 3600 + State#city_war_state.config_begin_minute * 60,
                    UnixEndSeizeTime = util:unixdate() + (State#city_war_state.seize_days - NowDay) * 24 * 3600 + State#city_war_state.end_seize_hour * 3600 + State#city_war_state.end_seize_minute * 60,
                    UnixEndApplyTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.apply_end_hour * 3600 + State#city_war_state.apply_end_minute * 60,
                    RestTime = UnixBeginTime - util:unixtime(),
                    case util:unixtime() < UnixEndSeizeTime of
                        true -> 
                            _Time = UnixEndSeizeTime - util:unixtime(),
                            Time = case _Time > 0 of
                                true -> _Time;
                                false -> 0
                            end,
                            SeizeState = 1;
                        false -> 
                            _Time = UnixEndApplyTime - util:unixtime(),
                            Time = case _Time > 0 of
                                true -> _Time;
                                false -> 0
                            end,
                            SeizeState = 2
                    end,
                    case RestTime > 0 of
                        true -> 
                            case RestTime >= 30 * 60 of
                                true -> 
                                    {ok, BinData} = pt_641:write(64101, [0, 1, 0]);
                                false -> 
                                    {ok, BinData} = pt_641:write(64101, [RestTime, SeizeState, Time])
                            end,
                            lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData);
                        false -> 
                            skip
                    end
            end
    end.

%% 图标2
picture2([UniteStatus, State]) ->
    %% 最低参与等级
    MinLv = data_city_war:get_city_war_config(min_lv),
    case UniteStatus#unite_status.lv < MinLv of
        true ->
            skip;
        false ->
            %% 是否为活动日
            case lists:member(calendar:day_of_the_week(date()), [State#city_war_state.open_days]) of
                false ->
                    skip;
                true ->
                    NowDay = calendar:day_of_the_week(date()),
                    UnixBeginTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.config_begin_hour * 3600 + State#city_war_state.config_begin_minute * 60,
                    UnixEndTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.config_end_hour * 3600 + State#city_war_state.config_end_minute * 60,
                    case util:unixtime() >= UnixBeginTime andalso util:unixtime() =< UnixEndTime of
                        false ->
                            skip;
                        true ->
                            {Hour, Min, Sec} = time(),
                            _RestTime = (State#city_war_state.config_end_hour * 60 * 60 + State#city_war_state.config_end_minute * 60) - (Hour * 60 * 60 + Min * 60 + Sec),
                            RestTime = case _RestTime > 0 of
                                true -> _RestTime;
                                false -> 0
                            end,
                            %% 进攻方信息
                            Attacker = case get(attacker) of
                                _AttGuildInfo when is_record(_AttGuildInfo, ets_guild) ->
                                    AttackerId = _AttGuildInfo#ets_guild.id,
                                    [{1, _AttGuildInfo#ets_guild.name, _AttGuildInfo#ets_guild.member_num, _AttGuildInfo#ets_guild.member_capacity}];
                                _ -> 
                                    AttackerId = 0,
                                    []
                            end,
                            %% 防守方信息
                            Defender = case get(defender) of
                                _DefGuildInfo when is_record(_DefGuildInfo, ets_guild) ->
                                    [{3, _DefGuildInfo#ets_guild.name, _DefGuildInfo#ets_guild.member_num, _DefGuildInfo#ets_guild.member_capacity}];
                                _ -> 
                                    []
                            end,
                            %% 进攻援助
                            AttAids = lib_city_war:att_aids2(get(), [], AttackerId),
                            %% 防守援助
                            DefAids = lib_city_war:def_aids2(get(), []),
                            GuildInfoList = Attacker ++ AttAids ++ Defender ++ DefAids,
                            [PlayerName, PlayerSex, ParnerName] = case get(city_war_winner_info) of
                                [_PlayerName, _PlayerSex, _ParnerName] ->
                                    [_PlayerName, _PlayerSex, _ParnerName];
                                _ ->
                                    ["", 1, ""]
                            end,
                            %io:format("RestTime:~p~n", [RestTime]),
                            {ok, BinData} = pt_641:write(64102, [RestTime, GuildInfoList, PlayerName, PlayerSex, ParnerName]),
                            lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData)
                    end
            end
    end.

%% 攻防互换
reset_all() ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            CityWarInfo2 = CityWarInfo,
            %% 清怪
            Scene_id = data_city_war:get_city_war_config(scene_id),
            lib_mon:clear_scene_mon(Scene_id, 0, 1),
            AttackerRevivePlace = data_city_war:get_city_war_config(get_attacker_born),
            DefenderRevivePlace = data_city_war:get_city_war_config(get_defender_born),
            %% 清怪
            lib_mon:clear_scene_mon(Scene_id, 0, 0),
            %% 生成怪物
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
            %% 生成复活旗子
            lib_mon:async_create_mon(Mon4, CityWarSceneId, 16, 179, Type, CopyId, 1, [{group, Group1}]),
            lib_mon:async_create_mon(Mon4, CityWarSceneId, 97,  79, Type, CopyId, 1, [{group, Group1}]),
            lib_mon:async_create_mon(Mon2, CityWarSceneId, 56, 136, Type, CopyId, 1, [{group, Group1}]),
            CenterMon = if
                WorldLv < 50 -> data_city_war:get_city_war_config(center_mon_id1);
                WorldLv =< 65 -> data_city_war:get_city_war_config(center_mon_id2);
                true -> data_city_war:get_city_war_config(center_mon_id3)
            end,
            lib_mon:async_create_mon(CenterMon, CityWarSceneId, 158, 16, Type, CopyId, 1, [{group, Group2}]),
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
            lib_mon:async_create_mon(DefMonId, CityWarSceneId, 97, 86, Type, CopyId, 1, [{group, Group2}]),
            MonInfo = CityWarInfo2#city_war_info.monster_info,
            DoorMonList = data_city_war:get_city_war_config(door_mon_place),
            NewMonInfo = lib_city_war_battle:create_door(MonInfo, DoorMonList, 1, WorldLv),
            %% 写入内存
            CityWarInfo3 = CityWarInfo2#city_war_info{
                monster_info = NewMonInfo,
                %revive_mon_id = [MonId1, MonId2, MonId3],
                %center_mon_id = CenterMonId,
                attacker_revive_place = AttackerRevivePlace,
                defender_revive_place = DefenderRevivePlace,
                attacker_doctor_num = 0,
                attacker_ghost_num = 0,
                defender_doctor_num = 0,
                defender_ghost_num = 0,
                bomb_list1 = [],
                bomb_list2 = [],
                car1_list1 = [],
                car1_list2 = [],
                car2_list1 = [],
                car2_list2 = [],
                total_car_num = 0,
                total_tower_num = length(TowerXY)
            },
            put(city_war_info, CityWarInfo3),
            PlayerInfo = CityWarInfo3#city_war_info.player_info,
            PlayerList = dict:to_list(PlayerInfo),
            spawn(fun() ->
                        reset_all_player(PlayerList)
                end);
        _ ->
            skip
    end.

%% 重置所有玩家
reset_all_player([]) -> skip;
reset_all_player([H | T]) ->
    case H of
        {PlayerId, _} ->
            lib_player:update_player_info(PlayerId, [{reset_city_war, no}, {factionwar_stone, 0}]),
            timer:sleep(100);
        _ ->
            skip
    end,
    reset_all_player(T).

%% 删除复活列表
delete_revive_list(PlayerId) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            DieList = lists:delete(PlayerId, CityWarInfo#city_war_info.die_list),
            CityWarInfo2 = CityWarInfo#city_war_info{
                die_list = DieList
            },
            put(city_war_info, CityWarInfo2);
        _ ->
            skip
    end.

%% 是否攻城战胜利帮派
is_city_war_win(GuildId) ->
    case db:get_row(<<"select winner_guild_id from log_city_war order by win_time desc limit 1">>) of
        [GuildId] ->
            1;
        _ ->
            0
    end.

%% 获取雕像
get_statue(PlayerId) ->
    case get({statue, 1000}) of
        List when is_list(List) ->
            ok;
        _ ->
            List = []
    end,
    %io:format("List:~p~n", [List]),
    {ok, BinData} = pt_641:write(64121, [List]),
    lib_server_send:send_to_uid(PlayerId, BinData).

%% 设置雕像
set_statue(PlayerStatus) ->
    List = [[1000, lib_player_server:get_player_statue(PlayerStatus)]],
    put({statue, 1000}, List).

reset_statue(PlayerStatus) ->
    List = [[1000, lib_player_server:get_player_statue(PlayerStatus)]],
    case get({statue, 1000}) of
        List2 when is_list(List2) ->
            skip;
        _ ->
            put({statue, 1000}, List)
    end.

%% 触发更新雕像
update_statue() ->
    case db:get_row(<<"select g.chief_id from guild as g, log_city_war as lcw where g.id = lcw.winner_guild_id order by lcw.win_time desc limit 1">>) of
        [PlayerId] when is_integer(PlayerId) ->
            lib_player:update_player_info(PlayerId, [{update_statue, no}]);
        _ ->
            skip
    end.

%% 初始化胜利方信息
%% [帮派名称， 长安城主姓名， 长安城主姓别， 城主夫人姓名]
init_win_info() ->
    List = case db:get_row(<<"select pl.id, pl.sex, pl.nickname, g.name from guild as g, log_city_war as lcw, player_low as pl where g.id = lcw.winner_guild_id and pl.id = g.chief_id order by lcw.win_time desc limit 1">>) of
        [PlayerId, PlayerSex, PlayerName, GuildName] when is_integer(PlayerId) ->
            put(win_guild, util:make_sure_list(GuildName)),
            case PlayerSex of
                1 ->
                    case db:get_row(io_lib:format(<<"select pl.nickname from player_low as pl, marriage as m where m.male_id = ~p and m.female_id = pl.id and m.divorce = 0 and m.register_time > 0 limit 1">>, [PlayerId])) of
                        [ParnerName] ->
                            ok;
                        _ ->
                            ParnerName = ""
                    end;
                _ ->
                    case db:get_row(io_lib:format(<<"select pl.nickname from player_low as pl, marriage as m where m.female_id = ~p and m.male_id = pl.id and m.divorce = 0 and m.register_time > 0 limit 1">>, [PlayerId])) of
                        [ParnerName] ->
                            ok;
                        _ ->
                            ParnerName = ""
                    end
            end,
            [GuildName, PlayerName, PlayerSex, ParnerName];
        _ ->
            ["", "", 1, ""]
    end,
    put(winner_info, List).

%% 每分钟循环
min_cycle() ->
    mod_city_war:no_open_broadcast(),
    timer:sleep(60 * 1000),
    min_cycle().

%% 长安城主传闻
send_winner_tv(PlayerStatus) ->
    case get({statue, 1000}) of
        List when is_list(List) ->
            case List of
                [_Type, [_Id, _Lv, _Realm, _Career, _Sex, _Weapon, _Cloth, _WLight, _CLight, _ShiZhuang, _SuitId, _Vip, Nick]] when PlayerStatus#player_status.nickname =:= Nick ->
                    case get(last_send_time) of
                        LastSendTime when is_integer(LastSendTime) ->
                            case util:unixtime() - LastSendTime >= 60 * 60 of
                                true ->
                                    lib_chat:send_TV({all}, 1, 2, ["castellanLine", 1, PlayerStatus#player_status.id, PlayerStatus#player_status.career, PlayerStatus#player_status.nickname, PlayerStatus#player_status.sex, PlayerStatus#player_status.career, PlayerStatus#player_status.image]),
                                    put(last_send_time, util:unixtime());
                                false ->
                                    skip
                            end;
                        _ ->
                            put(last_send_time, util:unixtime())
                    end;
                _ ->
                    skip
            end;
        _ ->
            skip
    end.

delete_win_guild(GuildId) ->
    db:execute(io_lib:format(<<"delete from log_city_war where winner_guild_id = ~p">>, [GuildId])).

%% 获胜帮派
get_winner_guild(PlayerId) ->
    case get(win_guild) of
        WinnerGuildName when is_list(WinnerGuildName) ->
            ok;
        _ ->
            WinnerGuildName = ""
    end,
    {ok, BinData} = pt_641:write(64122, [WinnerGuildName]),
    lib_server_send:send_to_uid(PlayerId, BinData).

change_career_check([PlayerStatus, Type]) ->
    {NowStone, PkStatus} = {PlayerStatus#player_status.factionwar_stone, PlayerStatus#player_status.pk#status_pk.pk_status},
    case NowStone of
        0 ->
            case PkStatus of
                %% 失败，死亡不能进行职业变换
                7 ->
                    Str = data_city_war_text:get_city_war_error_tips(36),
                    {ok, BinData} = pt_641:write(64110, [2, Str]),
                    mod_disperse:cast_to_unite(lib_unite_send, send_to_uid, [PlayerStatus#player_status.id, BinData]);
                _ ->
                    mod_city_war:change_career([PlayerStatus, Type])
            end;
        %% 失败，已变换职业
        _ ->
            Str = data_city_war_text:get_city_war_error_tips(28),
            {ok, BinData} = pt_641:write(64110, [2, Str]),
            mod_disperse:cast_to_unite(lib_unite_send, send_to_uid, [PlayerStatus#player_status.id, BinData])
    end.

%% 箭塔总数减一
minus_a_tower() ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            TotalTowerNum = CityWarInfo#city_war_info.total_tower_num,
            NewTotalTowerNum = case TotalTowerNum > 0 of
                true -> TotalTowerNum - 1;
                false -> 0
            end,
            CityWarInfo2 = CityWarInfo#city_war_info{
                total_tower_num = NewTotalTowerNum
            },
            put(city_war_info, CityWarInfo2);
        _ ->
            skip
    end.

%% 采集攻城车数量减一
minus_a_collect_car() ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            CollectCarNum = CityWarInfo#city_war_info.collect_car_num,
            NewCollectCarNum = case CollectCarNum > 0 of
                true -> CollectCarNum - 1;
                false -> 0
            end,
            CityWarInfo2 = CityWarInfo#city_war_info{
                collect_car_num = NewCollectCarNum
            },
            put(city_war_info, CityWarInfo2);
        _ ->
            skip
    end.

%% 杀怪助攻
assist_kill_mon([PlayerIdList, MonId]) ->
    CenterMon1 = data_city_war:get_city_war_config(center_mon_id1),
            CenterMon2 = data_city_war:get_city_war_config(center_mon_id2),
            CenterMon3 = data_city_war:get_city_war_config(center_mon_id3),
            DoorMon1 = data_city_war:get_city_war_config(door_mon_id1),
            DoorMon2 = data_city_war:get_city_war_config(door_mon_id2),
            DoorMon3 = data_city_war:get_city_war_config(door_mon_id3),
            TowerMon1 = data_city_war:get_city_war_config(tower_mon_id1),
            TowerMon2 = data_city_war:get_city_war_config(tower_mon_id2),
            TowerMon3 = data_city_war:get_city_war_config(tower_mon_id3),
            MonList = [CenterMon1, CenterMon2, CenterMon3, DoorMon1, DoorMon1 + 1, DoorMon1 + 2, DoorMon1 + 3, DoorMon1 + 4, DoorMon2, DoorMon2 + 1, DoorMon2 + 2, DoorMon2 + 3, DoorMon2 + 4, DoorMon3, DoorMon3 + 1, DoorMon3 + 2, DoorMon3 + 3, DoorMon3 + 4, TowerMon1, TowerMon2, TowerMon3],
    case lists:member(MonId, MonList) of
        true ->
            all_player_add_score(PlayerIdList, 5);
        false ->
            skip
    end.

all_player_add_score([], _Score) -> skip;
all_player_add_score([H | T], Score) ->
    case H of
        PlayerId when is_integer(PlayerId) ->
            mod_city_war:add_score(PlayerId, Score);
        _ ->
            skip
    end,
    all_player_add_score(T, Score).

%% 获得进攻、防守、援助方信息
get_all_guild_info(GuildList) ->
    case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            AttackerInfo = dict:to_list(CityWarInfo#city_war_info.attacker_info),
            DefenderInfo = dict:to_list(CityWarInfo#city_war_info.defender_info),
            AttackerInfo2 = to_att_list(AttackerInfo, [], GuildList),
            DefenderInfo2 = to_def_list(DefenderInfo, [], GuildList),
            AttackerInfo2 ++ DefenderInfo2;
        _ ->
            []
    end.

to_att_list([], List, _GuildList) -> List;
to_att_list([H | T], List, GuildList) ->
    case H of
        {GuildId, {_OnlineNum, _Score, EtsGuild}} ->
            case lists:member(GuildId, GuildList) of
                true ->
                    to_att_list(T, List, GuildList);
                false ->
                    to_att_list(T, [{2, EtsGuild#ets_guild.name, EtsGuild#ets_guild.member_num, EtsGuild#ets_guild.member_capacity} | List], GuildList)
            end;
        _ ->
            to_att_list(T, List, GuildList)
    end.

to_def_list([], List, _GuildList) -> List;
to_def_list([H | T], List, GuildList) ->
    case H of
        {GuildId, {_OnlineNum, _Score, EtsGuild}} ->
            case lists:member(GuildId, GuildList) of
                true ->
                    to_def_list(T, List, GuildList);
                false ->
                    to_def_list(T, [{4, EtsGuild#ets_guild.name, EtsGuild#ets_guild.member_num, EtsGuild#ets_guild.member_capacity} | List], GuildList)
            end;
        _ ->
            to_def_list(T, List, GuildList)
    end.

%% 攻城战结束日志
end_city_war_log() ->
    case db:get_row(<<"select max(id) from log_city_war_info1">>) of
        [MaxId] ->
            db:execute(io_lib:format(<<"update log_city_war_info1 set end_time = ~p where id = ~p">>, [util:unixtime(), MaxId]));
        _ ->
            skip
    end.

%% 是否为进攻方或者防守方
is_att_def([GuildId, State]) ->
    NowDay = calendar:day_of_the_week(date()),
    SeizeDay = State#city_war_state.seize_days,
    OpenDay = State#city_war_state.open_days,
    ConfigEndHour = State#city_war_state.config_end_hour,
    ConfigEndMinute = State#city_war_state.config_end_minute,
    %% 是否在活动日内
    case lists:member(NowDay, [SeizeDay, OpenDay]) of
        true ->
            %% 是否已结束活动
            case NowDay =:= OpenDay andalso time() > {ConfigEndHour, ConfigEndMinute, 0} of
                true ->
                    false;
                false ->
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
                    %% 是否为进攻方或防守方
                    case lists:member(GuildId, [AttGuild#ets_guild.id, DefGuild#ets_guild.id]) of
                        true ->
                            true;
                        false ->
                            false
                    end
            end;
        false ->
            false
    end.

%% 攻城战连续获胜次数
get_city_war_win_num() ->
    case db:get_all(<<"select winner_guild_id from log_city_war order by win_time desc">>) of
        [] ->
            0;
        List when is_list(List) ->
            [H | _T] = List,
            count_win_num(List, H, 0);
        _ ->
            0
    end.

count_win_num([], _GuildId, Num) -> Num;
count_win_num([H | T], GuildId, Num) -> 
    case H of
        GuildId ->
            count_win_num(T, GuildId, Num + 1);
        _ ->
            Num
    end.

add_city_war_buff(Status) ->
    CountNum = Status#player_status.city_war_win_num,
    BuffType = case CountNum of
        0 -> 0;
        1 -> 0;
        2 -> 214103;
        3 -> 214104;
        4 -> 214105;
        5 -> 214106;
        _ -> 214107
    end,
    %io:format("CountNum:~p~n", [CountNum]),
    case data_goods_effect:get_val(BuffType, buff) of
        [] ->
            {noreply, Status};
        {Type, AttributeId, Value, Time, SceneLimit} ->
            Now = util:unixtime(),
            %% 判断是否已经有该Buff
            case lib_buff:match_two2(Status#player_status.player_buff, AttributeId, []) of
            %case buff_dict:match_two2(Status#player_status.id, AttributeId) of
                [] -> 
                    NewBuffInfo = lib_player:add_player_buff(Status#player_status.id, Type, BuffType, AttributeId, Value, Now+Time, SceneLimit),
                    %% 修改解冻状态
                    buff_dict:insert_buff(NewBuffInfo),
                    lib_player:send_buff_notice(Status, [NewBuffInfo]),
                    BuffAttribute = lib_player:get_buff_attribute(Status#player_status.id, Status#player_status.scene),
                    NewPlayerStatus = lib_player:count_player_attribute(Status#player_status{buff_attribute = BuffAttribute}),
                    lib_player:send_attribute_change_notify(NewPlayerStatus, 0),
                    {noreply, NewPlayerStatus};
                _ -> 
                    {noreply, Status}
            end
    end.

del_city_war_buff(Status) ->
    CountNum = Status#player_status.city_war_win_num,
    BuffType = case CountNum of
        0 -> 0;
        1 -> 0;
        2 -> 214103;
        3 -> 214104;
        4 -> 214105;
        5 -> 214106;
        _ -> 214107
    end,
    case data_goods_effect:get_val(BuffType, buff) of
        [] ->
            {noreply, Status};
        {_Type, AttributeId, _Value, _Time, _SceneLimit} ->
            Now = util:unixtime(),
            %% 判断是否已经有该Buff
            case lib_buff:match_two2(Status#player_status.player_buff, AttributeId, []) of
            %case buff_dict:match_two2(Status#player_status.id, AttributeId) of
                [] -> 
                    {noreply, Status};
                [Buff] -> 
                    lib_player:del_buff(Buff#ets_buff.id),
                    buff_dict:delete_id(Buff#ets_buff.id),
                    NewBuff = Buff#ets_buff{end_time = Now},
                    lib_player:send_buff_notice(Status, [NewBuff]),
                    BuffAttribute = lib_player:get_buff_attribute(Status#player_status.id, Status#player_status.scene),
                    NewPlayerStatus = lib_player:count_player_attribute(Status#player_status{buff_attribute = BuffAttribute}),
                    lib_player:send_attribute_change_notify(NewPlayerStatus, 0),
                    {noreply, NewPlayerStatus};
                _Any ->
                    catch util:errlog("mod_server_cast:del_wubianhai_buff error: ~p~n", [_Any]),
                    {noreply, Status}
            end
    end.

create_center_mon() ->
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    CopyId = 0,
    Type = 0,  %% 0.被动 1.主动
    Group2 = 2,
    WorldLv = case catch lib_player:world_lv(0) of
        _WorldLv when is_integer(_WorldLv) ->
            _WorldLv;
        _ ->
            40
    end,
    CenterMon = if
        WorldLv < 50 -> data_city_war:get_city_war_config(center_mon_id1);
        WorldLv =< 65 -> data_city_war:get_city_war_config(center_mon_id2);
        true -> data_city_war:get_city_war_config(center_mon_id3)
    end,
    lib_mon:async_create_mon(CenterMon, CityWarSceneId, 158, 16, Type, CopyId, 1, [{group, Group2}]).
