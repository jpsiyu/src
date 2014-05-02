%%%------------------------------------
%%% @Module  : mod_city_war_call
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.14
%%% @Description: 城战
%%%------------------------------------
-module(mod_city_war_call).
-export([handle_call/3]).
-include("guild.hrl").
-include("server.hrl").
-include("city_war.hrl").

get_apply([], List) -> List;
get_apply([H | T], List) ->
    case H of
        {{apply, GuildId}, {AidTarget, _, _}} ->
            get_apply(T, [{GuildId, AidTarget} | List]);
        _ ->
            get_apply(T, List)
    end.

get_aid([], List) -> List;
get_aid([H | T], List) ->
    case H of
        {{aid, GuildId}, {AidTarget, _, _}} ->
            get_aid(T, [{GuildId, AidTarget} | List]);
        _ ->
            get_aid(T, List)
    end.

%==========================================================%
%========================== call ==========================%
%==========================================================%
%% 测试使用
handle_call({test}, _From, State) ->
    %Reply = case get(city_war_info) of
    %    CityWarInfo when is_record(CityWarInfo, city_war_info) ->
    %        {CityWarInfo#city_war_info.att_aid_num, CityWarInfo#city_war_info.def_aid_num};
    %    _ ->
    %        error
    %end,
    _Apply = get_apply(get(), []),
    _Aid = get_aid(get(), []),
    %Reply = [Apply, Aid],
    Reply = {State#city_war_state.end_seize_hour, State#city_war_state.end_seize_minute},
    {reply, Reply, State};

%% 数据初始化
%% Reply返回
%% 1.初始化成功
%% 0.初始化失败
handle_call({init_all}, _From, State) ->
    %% 清数据
    Statue1000 = get({statue, 1000}),
    WinGuild = get(win_guild),
    erase(),
    put({statue, 1000}, Statue1000),
    put(win_guild, WinGuild),
    Scene_id = data_city_war:get_city_war_config(scene_id),
    lib_mon:clear_scene_mon(Scene_id, 0, 1),
    %% 先找到上次帮战获胜的帮派
    %BorderTime = data_city_war:get_border_time(),
    case catch db:get_row(<<"select lcw.winner_guild_id from log_city_war as lcw, guild as g where g.id = lcw.winner_guild_id order by lcw.win_time desc limit 1">>) of
        %% 找到上次获胜的帮派，记录帮派ID，作为防守方
        [FactionId] ->
            DbRes = 1;
        _ ->
            case catch db:get_row(<<"select faction_id from factionwar where last_is_win = 1 order by faction_war_last_time desc limit 1">>) of
                %% 找不到上次获胜的帮派
                [] -> 
                    BorderTime = 0,
                    catch util:errlog("city war start error: cannot find last win guild! : ~p", [BorderTime]),
                    FactionId = 0,
                    DbRes = 0;
                %% 找到上次帮战获胜的帮派，记录帮派ID，作为防守方
                [FactionId] ->
                    DbRes = 1;
                %% 其他错误
                _OtherError -> 
                    catch util:errlog("city war start error: ~p", [_OtherError]),
                    FactionId = 0,
                    DbRes = 0
            end
    end,
    case DbRes of
        0 -> 
            Reply = 0;
        _ ->
            GuildInfo = lib_guild:get_guild(FactionId),
            case is_record(GuildInfo, ets_guild) of
                %% 获取帮派信息成功
                true ->
                    case catch db:get_all(<<"select id from guild">>) of
                        %% 无法找到帮派信息
                        [] -> 
                            catch util:errlog("city war start error:no guild id! : ~p", [util:unixtime()]),
                            Reply = 0;
                        _List when is_list(_List) ->
                            %% 获取前5帮派信息
                            List = lib_city_war:get_all_list_convert(_List, []),
                            NewList = lib_city_war:get_pre_six(List, []),
                            %% 1服测试用
                            %NewList = [{1880, 1000, 0}, {27, 1000, 0}, {2032, 1000, 0}, {55, 1000, 0}, {1875, 1000, 0}, {2048, 1000, 0}],
                            NewList2 = lib_city_war:get_pre_six_detail(NewList, []),
                            %% 去掉防守方(防守方不能当进攻方，不能抢夺进攻权)
                            NewList3 = lists:keydelete(FactionId, 1, NewList2),
                            NewList4 = lists:sublist(NewList3, 5),
                            %io:format("NewList4:~p~n", [NewList4]),
                            NewList8 = case NewList4 of
                                [] ->
                                    NewList5 = lib_city_war:get_pre_six2(List, []),
                                    NewList6 = lib_city_war:get_pre_six_detail(NewList5, []),
                                    NewList7 = lists:keydelete(FactionId, 1, NewList6),
                                    lists:sublist(NewList7, 5);
                                _ ->
                                    NewList4
                            end,
                            %io:format("NewList8:~p~n", [NewList8]),
                            %io:format("pre_five:~p~n", [NewList]),
                            %% 默认积分第一的帮派为进攻方
                            case length(NewList8) >= 1 of
                                true ->
                                    [{_H_Id, _H_Score, H_GuildInfo, _H_DonateCoin} | _T_NewList8] = NewList8,
                                    put(attacker, H_GuildInfo);
                                false ->
                                    skip
                            end,
                            put(pre_five, NewList8),
                            put(defender, GuildInfo),
                            %% 长安城主及配偶信息
                            PlayerId = GuildInfo#ets_guild.chief_id,
                            [PlayerName, PlayerSex, ParnerName] = case db:get_row(io_lib:format(<<"select nickname, sex from player_low where id = ~p limit 1">>, [PlayerId])) of
                                [_PlayerName, _PlayerSex] ->
                                    case _PlayerSex of
                                        1 ->
                                            case db:get_row(io_lib:format(<<"select nickname from marriage as m, player_low as pl where m.male_id = ~p and m.divorce = 0 and m.female_id = pl.id limit 1">>, [PlayerId])) of
                                                [_ParnerName] -> 
                                                    [_PlayerName, _PlayerSex, _ParnerName];
                                                _ ->
                                                    [_PlayerName, _PlayerSex, ""]
                                            end;
                                        _ ->
                                            case db:get_row(io_lib:format(<<"select nickname from marriage as m, player_low as pl where m.female_id = ~p and m.divorce = 0 and m.male_id = pl.id limit 1">>, [PlayerId])) of
                                                [_ParnerName] -> 
                                                    [_PlayerName, _PlayerSex, _ParnerName];
                                                _ ->
                                                    [_PlayerName, _PlayerSex, ""]
                                            end
                                    end;
                                _ ->
                                    ["", 1, ""]
                            end,
                            put(city_war_winner_info, [PlayerName, PlayerSex, ParnerName]),
                            %% 初始化复活点
                            AttackerRevivePlace = data_city_war:get_city_war_config(get_attacker_born),
                            DefenderRevivePlace = data_city_war:get_city_war_config(get_defender_born),
                            put(city_war_info, #city_war_info{
                                    attacker_revive_place = AttackerRevivePlace,
                                    defender_revive_place = DefenderRevivePlace
                                }),
                            Reply = 1;
                        _ErrorInfo ->
                            catch util:errlog("city war start error:cannot read all guild id! : ~p", [_ErrorInfo]),
                            Reply = 0
                    end;
                %% 获取帮派信息失败
                false -> 
                    catch util:errlog("city war start error: cannot get guild info! : ~p", [GuildInfo]),
                    Reply = 0
            end
    end,
    lib_city_war:init_win_info(),
	{reply, Reply, State};

%% 继续攻城战(周六重启时)
%% Reply返回
%% 1.初始化成功
%% 0.初始化失败
handle_call({continue_city_war}, _From, State) ->
    %% 清数据
    Statue1000 = get({statue, 1000}),
    WinGuild = get(win_guild),
    erase(),
    put({statue, 1000}, Statue1000),
    put(win_guild, WinGuild),
    Scene_id = data_city_war:get_city_war_config(scene_id),
    lib_mon:clear_scene_mon(Scene_id, 0, 1),
    NowDate = util:unixdate() - 24 * 3600,
    case db:get_row(io_lib:format(<<"select attacker_id, defender_id from log_city_war_info1 where begin_time > ~p order by begin_time desc limit 1">>, [NowDate])) of
        %% 找到进攻方、防守方信息
        [AttackerId, DefenderId] ->
            AttGuildInfo = lib_guild:get_guild(AttackerId),
            DefGuildInfo = lib_guild:get_guild(DefenderId),
            case is_record(AttGuildInfo, ets_guild) andalso is_record(DefGuildInfo, ets_guild) of
                %% 找到进攻帮派、防守帮派信息
                true ->
                    put(attacker, AttGuildInfo),
                    put(defender, DefGuildInfo),
                    %% 长安城主及配偶信息
                    PlayerId = DefGuildInfo#ets_guild.chief_id,
                    [PlayerName, PlayerSex, ParnerName] = case db:get_row(io_lib:format(<<"select nickname, sex from player_low where id = ~p limit 1">>, [PlayerId])) of
                        [_PlayerName, _PlayerSex] ->
                            case _PlayerSex of
                                1 ->
                                    case db:get_row(io_lib:format(<<"select nickname from marriage as m, player_low as pl where m.male_id = ~p and m.divorce = 0 and m.female_id = pl.id limit 1">>, [PlayerId])) of
                                        [_ParnerName] -> 
                                            [_PlayerName, _PlayerSex, _ParnerName];
                                        _ ->
                                            [_PlayerName, _PlayerSex, ""]
                                    end;
                                _ ->
                                    case db:get_row(io_lib:format(<<"select nickname from marriage as m, player_low as pl where m.female_id = ~p and m.divorce = 0 and m.male_id = pl.id limit 1">>, [PlayerId])) of
                                        [_ParnerName] -> 
                                            [_PlayerName, _PlayerSex, _ParnerName];
                                        _ ->
                                            [_PlayerName, _PlayerSex, ""]
                                    end
                            end;
                        _ ->
                            ["", 1, ""]
                    end,
                    put(city_war_winner_info, [PlayerName, PlayerSex, ParnerName]),
                    %% 初始化复活点
                    AttackerRevivePlace = data_city_war:get_city_war_config(get_attacker_born),
                    DefenderRevivePlace = data_city_war:get_city_war_config(get_defender_born),
                    put(city_war_info, #city_war_info{
                            attacker_revive_place = AttackerRevivePlace,
                            defender_revive_place = DefenderRevivePlace
                        }),
                    Reply = 1;
                %% 失败，找不到帮派信息
                false ->
                    catch util:errlog("continue city war error: cannot get guild info! : ~p", [[AttGuildInfo, DefGuildInfo]]),
                    Reply = 0
            end;
        %% 失败，找不到进攻方、防守方信息
        _ErrorLog ->
            catch util:errlog("continue city war error: cannot get city war info! : ~p", [_ErrorLog]),
            Reply = 0
    end,
    lib_city_war:init_win_info(),
	{reply, Reply, State};

%% 捐献铜币
handle_call({donate_coin, PlayerStatus, Num}, _From, State) ->
    NowDay = calendar:day_of_the_week(date()),
    case lists:member(NowDay, [State#city_war_state.seize_days, State#city_war_state.open_days]) of
        %% 失败，不是活动日
        false ->
            Reply = {ok, [PlayerStatus, 2, data_city_war_text:get_city_war_error_tips(0)]};
        true ->
            GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
            case get(defender) of
                %% 失败，防守方不能抢夺进攻权
                DefGuildInfo when DefGuildInfo#ets_guild.id =:= GuildId ->
                    Res = 2,
                    Str = data_city_war_text:get_city_war_error_tips(14),
                    NewPlayerStatus = PlayerStatus;
                _ ->
                    case get(pre_five) of
                        List when is_list(List) ->
                            case lists:keymember(GuildId, 1, List) of
                                true ->
                                    %AllCoin = PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin,
                                    AllCoin = PlayerStatus#player_status.coin,
                                    case AllCoin >= Num of
                                        true ->
                                            case get({apply, GuildId}) =/= undefined orelse get({aid, GuildId}) =/= undefined of
                                                %% 失败，已申请援助的帮派不能抢夺进攻权
                                                true -> 
                                                    Res = 2,
                                                    Str = data_city_war_text:get_city_war_error_tips(17),
                                                    NewPlayerStatus = PlayerStatus;
                                                %% 成功
                                                false ->
                                                    UnixEndSeizeTime = util:unixdate() + (State#city_war_state.seize_days - NowDay) * 24 * 3600 + State#city_war_state.end_seize_hour * 3600 + State#city_war_state.end_seize_minute * 60,
                                                    NowTime = util:unixtime(),
                                                    case NowTime > UnixEndSeizeTime of
                                                        %% 失败，已过抢夺时间
                                                        true -> 
                                                            Res = 2,
                                                            Str = data_city_war_text:get_city_war_error_tips(47),
                                                            NewPlayerStatus = PlayerStatus;
                                                        false -> 
                                                            %% 最后一分钟捐献，则自动增加一分钟捐献时间
                                                            case NowTime > UnixEndSeizeTime - 60 of
                                                                true ->
                                                                    mod_city_war:add_end_seize_time();
                                                                false ->
                                                                    skip
                                                            end,
                                                            Res = 1,
                                                            Str = data_city_war_text:get_city_war_error_tips(2),
                                                            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Num, rcoin),
                                                            log:log_consume(city_war_donate, coin, PlayerStatus, NewPlayerStatus, "city war donate"),
                                                            NewList = lib_city_war:add_coin(List, [], GuildId, Num),
                                                            %io:format("NewList:~p~n", [NewList]),
                                                            put(pre_five, NewList),
                                                            %% 重新判定进攻方
                                                            [H | _T] = NewList,
                                                            case H of
                                                                {_H_Id, _H_Score, H_GuildInfo, _H_DonateCoin} ->
                                                                    put(attacker, H_GuildInfo);
                                                                _ ->
                                                                    skip
                                                            end
                                                    end
                                            end;
                                        %% 失败，非绑定铜币不足
                                        false ->
                                            Res = 2,
                                            Str = data_city_war_text:get_city_war_error_tips(16),
                                            NewPlayerStatus = PlayerStatus
                                    end;
                                %% 失败，只有帮派周积分前5名的帮派能才进行抢夺
                                false ->
                                    Res = 2,
                                    Str = data_city_war_text:get_city_war_error_tips(13),
                                    NewPlayerStatus = PlayerStatus
                            end;
                        %% 失败，操作失败
                        _ ->
                            Res = 2,
                            Str = data_city_war_text:get_city_war_error_tips(1),
                            NewPlayerStatus = PlayerStatus
                    end
            end,
            Reply = {ok, [NewPlayerStatus, Res, Str]}
    end,
    {reply, Reply, State};

%% 获取复活地点
%% Type：1.进攻方 2.防守方
handle_call({get_revive_place, Type}, _From, State) ->
    Reply = case get(city_war_info) of
        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
            case Type of
                1 ->
                    CityWarInfo#city_war_info.attacker_revive_place;
                _ ->
                    CityWarInfo#city_war_info.defender_revive_place
            end;
        _ ->
            case Type of
                1 ->
                    data_city_war:get_city_war_config(get_attacker_born);
                _ ->
                    lists:sublist(data_city_war:get_city_war_config(get_defender_born), 2)
            end
    end,
    {reply, Reply, State};

%% 是否为进攻方或者防守方
handle_call({is_att_def, GuildId}, _From, State) ->
    Reply = lib_city_war:is_att_def([GuildId, State]),
    {reply, Reply, State};

%% 容错
handle_call(_Request, _From, State) ->
    Reply = {ok, ok},
    {reply, Reply, State}.
