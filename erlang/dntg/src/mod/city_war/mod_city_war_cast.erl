%%%------------------------------------
%%% @Module  : mod_city_war_cast
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.14
%%% @Description: 城战
%%%------------------------------------
-module(mod_city_war_cast).
-export([handle_cast/2]).
-include("guild.hrl").
-include("server.hrl").
-include("unite.hrl").
-include("city_war.hrl").


%==========================================================%
%========================== cast ==========================%
%==========================================================%
%% 设置活动相关时间
handle_cast({set_all_time, ConfigBeginHour, ConfigBeginMinute, ConfigEndHour, ConfigEndMinute, EndSeizeHour, EndSeizeMinute, ApplyEndHour, ApplyEndMinute, OpenDays, SeizeDays}, _State) ->
    NewState = #city_war_state{
        config_begin_hour = ConfigBeginHour,
        config_begin_minute = ConfigBeginMinute,
        config_end_hour = ConfigEndHour,
        config_end_minute = ConfigEndMinute,
        end_seize_hour = EndSeizeHour,
        end_seize_minute = EndSeizeMinute,
        apply_end_hour = ApplyEndHour,
        apply_end_minute = ApplyEndMinute,
        open_days = OpenDays,
        seize_days = SeizeDays
    },
    lib_city_war:init_win_info(),
	{noreply, NewState};

%% 未开启广播长安城主信息
handle_cast({no_open_broadcast}, State) ->
    ConfigEndHour = State#city_war_state.config_end_hour,
    ConfigEndMinute = State#city_war_state.config_end_minute,
    NowDay = calendar:day_of_the_week(date()),
    SeizeDay = State#city_war_state.seize_days,
    OpenDay = State#city_war_state.open_days,
    _SeizeDay2 = case SeizeDay >= NowDay of
        true -> SeizeDay;
        false -> SeizeDay + 7
    end,
    OpenDay2 = case OpenDay >= NowDay of
        true -> OpenDay;
        false -> OpenDay + 7
    end,
    UnixBeginTime = util:unixdate() + (SeizeDay - NowDay) * 24 * 3600,
    UnixEndTime = util:unixdate() + (OpenDay - NowDay) * 24 * 3600 + ConfigEndHour * 3600 + ConfigEndMinute * 60,
    NowTime = util:unixtime(),
    %io:format("State:~p~n", [State]),
    case NowTime > UnixBeginTime andalso NowTime < UnixEndTime of
        %% 不在活动时间内则广播城主信息
        false ->
            case OpenDay of
                0 ->
                    skip;
                _ ->
                    case get(winner_info) of
                        WinnerInfo when is_list(WinnerInfo) ->
                            ok;
                        _ ->
                            WinnerInfo = ""
                    end,
                    NowDay = calendar:day_of_the_week(date()),
                    UnixBeginTime2 = util:unixdate() + (OpenDay2 - NowDay) * 24 * 3600 + State#city_war_state.config_begin_hour * 3600 + State#city_war_state.config_begin_minute * 60,
                    %io:format("open_days:~p~n", [State#city_war_state.open_days]),
                    _RestTime = UnixBeginTime2 - util:unixtime(),
                    RestTime = case _RestTime > 0 of
                        true -> _RestTime;
                        false -> 0
                    end,
                    %io:format("64100:~p, RestTime:~p~n", [time(), RestTime]),
                    WinnerInfo2 = WinnerInfo ++ [RestTime],
                    %io:format("WinnerInfo2:~p~n", [WinnerInfo2]),
                    {ok, BinData} = pt_641:write(64100, WinnerInfo2),
                    MinLv = data_city_war:get_city_war_config(min_lv),
                    lib_unite_send:send_to_all(MinLv, 999, BinData)
            end;
        true ->
            skip
    end,
    {noreply, State};

%% 活动开始前的广播
handle_cast({before_broadcast}, State) ->
    %% 最低参与等级
    %io:format("64101:~p~n", [time()]),
    MinLv = data_city_war:get_city_war_config(min_lv),
    NowDay = calendar:day_of_the_week(date()),
    UnixBeginTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.config_begin_hour * 3600 + State#city_war_state.config_begin_minute * 60,
    UnixEndSeizeTime = util:unixdate() + (State#city_war_state.seize_days - NowDay) * 24 * 3600 + State#city_war_state.end_seize_hour * 3600 + State#city_war_state.end_seize_minute * 60,
    UnixEndApplyTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.apply_end_hour * 3600 + State#city_war_state.apply_end_minute * 60,
    {NowHour, NowMin, _NowSec} = time(),
    %% 写日志
    case NowDay =:= State#city_war_state.seize_days andalso {NowHour, NowMin} =:= {State#city_war_state.end_seize_hour, State#city_war_state.end_seize_minute} of
        true ->
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
            lib_city_war_battle:city_war_log(AttGuild, DefGuild, PreFive, dict:new(), dict:new(), 2);
        false ->
            skip
    end,
    _RestTime = UnixBeginTime - util:unixtime(),
    RestTime = case _RestTime > 0 of
        true -> 
            case _RestTime >= 30 * 60 of
                true -> 0;
                false -> _RestTime
            end;
        false -> 0
    end,
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
    case get(winner_info) of
        WinnerInfo when is_list(WinnerInfo) ->
            ok;
        _ ->
            WinnerInfo = ""
    end,
    %io:format("WinnerInfo:~p~n", [WinnerInfo]),
    %io:format("~p~n", [[RestTime, SeizeState, Time, WinnerInfo]]),
    {ok, BinData} = pt_641:write(64101, [RestTime, SeizeState, Time, WinnerInfo]),
    lib_unite_send:send_to_all(MinLv, 999, BinData),
    case RestTime =< 3 of
        true -> 
            case _RestTime >= 30 * 60 of
                true -> 
                    {noreply, State};
                false ->
                    handle_cast({after_broadcast}, State)
            end;
        false -> 
            {noreply, State}
    end;

%% 活动开始后的广播
handle_cast({after_broadcast}, State) ->
    %io:format("64102:~p~n", [time()]),
    %% 最低参与等级
    MinLv = data_city_war:get_city_war_config(min_lv),
    NowDay = calendar:day_of_the_week(date()),
    UnixEndTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.config_end_hour * 3600 + State#city_war_state.config_end_minute * 60,
    _RestTime = UnixEndTime - util:unixtime(),
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
            DefenderId = _DefGuildInfo#ets_guild.id,
            [{3, _DefGuildInfo#ets_guild.name, _DefGuildInfo#ets_guild.member_num, _DefGuildInfo#ets_guild.member_capacity}];
        _ -> 
            DefenderId = 0,
            []
    end,
    %%% 进攻援助
    %AttAids = lib_city_war:att_aids2(get(), [], AttackerId),
    %% 防守援助
    %DefAids = lib_city_war:def_aids2(get(), []),
    %GuildInfoList = Attacker ++ AttAids ++ Defender ++ DefAids,
    GuildInfoList = Attacker ++ Defender ++ lib_city_war:get_all_guild_info([AttackerId, DefenderId]),
    [PlayerName, PlayerSex, ParnerName] = case get(city_war_winner_info) of
        [_PlayerName, _PlayerSex, _ParnerName] ->
            [_PlayerName, _PlayerSex, _ParnerName];
        _ ->
            ["", 1, ""]
    end,
    %io:format("RestTime:~p~n", [RestTime]),
    {ok, BinData} = pt_641:write(64102, [RestTime, GuildInfoList, PlayerName, PlayerSex, ParnerName]),
    lib_unite_send:send_to_all(MinLv, 999, BinData),
	{noreply, State};

%% 报名信息
handle_cast({get_apply_info, UniteStatus}, State) ->
    lib_city_war_apply:get_apply_info([UniteStatus, State]),
    {noreply, State};

%% 援助/取消申请/撤兵
handle_cast({aid_or_cancel, UniteStatus, AidTarget}, State) ->
    lib_city_war_apply:aid_or_cancel([UniteStatus, AidTarget, State]),
    {noreply, State};

%% 获取审批信息
handle_cast({get_approval_info, UniteStatus, Type}, State) ->
    lib_city_war_apply:get_approval_info([UniteStatus, Type, State]),
    {noreply, State};

%% 审批申请信息
handle_cast({approval_apply, UniteStatus, ApplyGuildId, Answer}, State) ->
    lib_city_war_apply:approval_apply([UniteStatus, ApplyGuildId, Answer, State]),
    {noreply, State};

%% 获取抢夺信息
handle_cast({get_seize_info, UniteStatus}, State) ->
    lib_city_war_apply:get_seize_info([UniteStatus, State]),
    {noreply, State};

%% 进入活动
handle_cast({enter_war, UniteStatus}, State) ->
    lib_city_war_battle:enter_war([UniteStatus, State]),
    {noreply, State};

%% 下线处理
handle_cast({logout_deal, PlayerStatus}, State) ->
    lib_city_war_battle:logout_deal(PlayerStatus),
    {noreply, State};

%% 职业变换
handle_cast({change_career, PlayerStatus, Type}, State) ->
    lib_city_war_battle:change_career([PlayerStatus, Type, State]),
    {noreply, State};

%% 怪物初始化
handle_cast({init_mon}, State) ->
    lib_city_war_battle:init_mon(),
    {noreply, State};

%% 进攻方抢占复活点
handle_cast({seize_revive_place, Mon}, State) ->
    lib_city_war_battle:seize_revive_place(Mon),
    {noreply, State};

%% 城战面板1(定时更新，客户端也可以主动申请)
handle_cast({info_panel1, UniteStatus}, State) ->
    lib_city_war_battle:info_panel1(UniteStatus, State),
    {noreply, State};

%% 城战面板2(及时更新)
handle_cast({info_panel2, GuildId, PlayerId}, State) ->
    lib_city_war_battle:info_panel2(GuildId, PlayerId),
    {noreply, State};

%% 城战面板3(及时更新)
handle_cast({info_panel3, UniteStatus}, State) ->
    lib_city_war_battle:info_panel3(UniteStatus),
    {noreply, State};

%% 定时刷新怪物
handle_cast({refresh_mon}, State) ->
    lib_city_war_battle:refresh_mon(State),
    {noreply, State};

%% 定时广播
handle_cast({timing_broad}, State) ->
    lib_city_war_battle:timing_broad(State),
    {noreply, State};

%% 更新城门血量
handle_cast({update_door_blood, MonId, Hp, HpLim, Mid}, State) ->
    lib_city_war_battle:update_door_blood([MonId, Hp, HpLim, State, Mid]),
    {noreply, State};

%% 复活点内的攻城车数量减一
handle_cast({minus_revive_car, Mid, X, Y}, State) ->
    lib_city_war:minus_revive_car(Mid, X, Y),
    {noreply, State};

%% 复活点内炸弹数量减一
handle_cast({minus_revive_bomb, Mid, X, Y}, State) ->
    lib_city_war:minus_revive_bomb(Mid, X, Y),
    {noreply, State};

%% 攻城车总数减一
handle_cast({minus_a_car}, State) ->
    lib_city_war:minus_a_car(),
    {noreply, State};

%% 定时复活
handle_cast({timing_revive}, State) ->
    lib_city_war:timing_revive(State),
    {noreply, State};

%% 把全部人清出场
handle_cast({clear_all_out}, State) ->
    lib_city_war:clear_all_out(),
    {noreply, State};

%% 医仙、鬼巫数量减一
handle_cast({minus_a_career, PlayerStatus}, State) ->
    lib_city_war_battle:minus_a_career(PlayerStatus),
    {noreply, State};

%% 玩家加分
handle_cast({add_score, PlayerId, Score}, State) ->
    lib_city_war_battle:add_score(PlayerId, Score),
    {noreply, State};

%% 死亡处理
handle_cast({die_deal, PlayerId}, State) ->
    lib_city_war_battle:die_deal(PlayerId),
    {noreply, State};

%% 进攻方胜利
handle_cast({attacker_win}, State) ->
    lib_city_war_battle:attacker_win(),
    {noreply, State};

%% 结算
handle_cast({account}, State) ->
    %lib_city_war:account(),
    {noreply, State};

%% 弹出结算面板、发送奖励
handle_cast({end_deal, Type}, _State) ->
    lib_city_war:end_deal(Type),
    {noreply, #city_war_state{}};

%% 帮派加分
handle_cast({add_guild_score, GuildId, Score}, State) ->
    lib_city_war_battle:add_guild_score(GuildId, Score),
    {noreply, State};

%% 复活剩余时间
handle_cast({get_next_revive_time, UniteStatus}, State) ->
    lib_city_war_battle:get_next_revive_time(UniteStatus),
    {noreply, State};

%% 秘籍获得抢夺权限
handle_cast({gm_apply, GuildId}, State) ->
    lib_city_war_apply:gm_apply(GuildId),
    {noreply, State};

%% 图标0
handle_cast({picture0, UniteStatus}, State) ->
    lib_city_war:picture0([UniteStatus, State]),
    {noreply, State};

%% 图标1
handle_cast({picture1, UniteStatus}, State) ->
    lib_city_war:picture1([UniteStatus, State]),
    {noreply, State};

%% 图标2
handle_cast({picture2, UniteStatus}, State) ->
    lib_city_war:picture2([UniteStatus, State]),
    {noreply, State};

%% 攻防互换
handle_cast({reset_all}, State) ->
    lib_city_war:reset_all(),
    {noreply, State};

%% 删除复活列表
handle_cast({delete_revive_list, PlayerId}, State) ->
    lib_city_war:delete_revive_list(PlayerId),
    {noreply, State};

%% 获取雕像
handle_cast({get_statue, PlayerId}, State) ->
    lib_city_war:get_statue(PlayerId),
    {noreply, State};

%% 设置雕像
handle_cast({set_statue, PlayerStatus}, State) ->
    lib_city_war:set_statue(PlayerStatus),
    {noreply, State};

%% 设置雕像
handle_cast({reset_statue, PlayerStatus}, State) ->
    lib_city_war:reset_statue(PlayerStatus),
    {noreply, State};

%% 长安城主传闻
handle_cast({send_winner_tv, PlayerStatus}, State) ->
    lib_city_war:send_winner_tv(PlayerStatus),
    {noreply, State};

%% 获胜帮派
handle_cast({get_winner_guild, PlayerId}, State) ->
    lib_city_war:get_winner_guild(PlayerId),
    {noreply, State};

%% 箭塔总数减一
handle_cast({minus_a_tower}, State) ->
    lib_city_war:minus_a_tower(),
    {noreply, State};

%% 采集攻城车数量减一
handle_cast({minus_a_collect_car}, State) ->
    lib_city_war:minus_a_collect_car(),
    {noreply, State};

%% 增加抢夺时间
handle_cast({add_end_seize_time}, State) ->
    EndSeizeHour = State#city_war_state.end_seize_hour,
    EndSeizeMin = State#city_war_state.end_seize_minute,
    End = EndSeizeHour * 60 + EndSeizeMin + 1,
    NewEndSeizeHour = End div 60,
    NewEndSeizeMin = End - End div 60 * 60,
    NewState = State#city_war_state{
        end_seize_hour = NewEndSeizeHour,
        end_seize_minute = NewEndSeizeMin
    },
    {noreply, NewState};

%% 容错
handle_cast(_Msg, State) ->
    {noreply, State}.

