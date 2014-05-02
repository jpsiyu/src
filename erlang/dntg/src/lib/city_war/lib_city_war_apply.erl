%%%------------------------------------
%%% @Module  : lib_city_war_apply
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.18
%%% @Description: 城战报名逻辑处理
%%%------------------------------------

-module(lib_city_war_apply).
-export(
    [
        get_apply_info/1,
        aid_or_cancel/1,
        get_approval_info/1,
        approval_apply/1,
        get_seize_info/1,
        gm_apply/1
    ]
).
-include("unite.hrl").
-include("server.hrl").
-include("guild.hrl").
-include("city_war.hrl").

%% 报名信息
get_apply_info([UniteStatus, State]) ->
    NowDay = calendar:day_of_the_week(date()),
    UnixEndSeizeTime = util:unixdate() + (State#city_war_state.seize_days - NowDay) * 24 * 3600 + State#city_war_state.end_seize_hour * 3600 + State#city_war_state.end_seize_minute * 60,
    UnixEndApplyTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.apply_end_hour * 3600 + State#city_war_state.apply_end_minute * 60,
    case util:unixtime() < UnixEndSeizeTime of
        true ->
            get_seize_info([UniteStatus, State]);
        false ->
            case lists:member(NowDay, [State#city_war_state.seize_days, State#city_war_state.open_days]) of
                %% 失败，不是活动日
                false ->
                    Res = 2, 
                    Str = data_city_war_text:get_city_war_error_tips(0),
                    AidState = 1,
                    AidTarget = 0,
                    GuildInfoList = [],
                    Shield1 = 1,
                    Shield2 = 1,
                    Shield3 = 1,
                    Shield4 = 1,
                    Shield5 = 1;
                true ->
                    %io:format("UnixEndSeizeTime:~p~n", [util:seconds_to_localtime(UnixEndSeizeTime)]),
                    %io:format("UnixEndApplyTime:~p~n", [util:seconds_to_localtime(UnixEndApplyTime)]),
                    %% 0.不屏蔽 1.屏蔽抢夺按钮 2.屏蔽所有按钮
                    %% 是否屏蔽抢夺按钮
                    %% 0.不屏蔽 2.屏蔽
                    case util:unixtime() > UnixEndApplyTime of
                        %% 已过报名时间，屏蔽所有按钮
                        true ->
                            Shield1 = 1,
                            Shield2 = 1,
                            Shield3 = 1,
                            Shield4 = 1,
                            Shield5 = 1;
                        false ->
                            %% 是否为帮主或者副帮主
                            case lists:member(UniteStatus#unite_status.guild_position, [1, 2]) of
                                %% 普通成员
                                false ->
                                    %Shield1 = case lists:member(NowDay, [State#city_war_state.open_days]) of
                                    %    true -> 0;
                                    %    false -> 1
                                    %end,
                                    Shield1 = case util:unixtime() > UnixEndApplyTime of
                                        true -> 1;
                                        false -> 0
                                    end,
                                    Shield2 = 1,
                                    Shield3 = 1,
                                    Shield4 = case lists:member(NowDay, [State#city_war_state.open_days]) of
                                        true -> 0;
                                        false -> 1
                                    end,
                                    Shield5 = 1;
                                %% 帮主或者副帮主
                                true ->
                                    %% 进攻方
                                    case get(attacker) of
                                        AttEtsGuild0 when AttEtsGuild0#ets_guild.id =:= UniteStatus#unite_status.guild_id ->
                                            Shield1 = 1, 
                                            Shield2 = 0,
                                            %% 是否已过抢夺时间，屏蔽抢夺按钮
                                            Shield3 = case util:unixtime() > UnixEndSeizeTime of
                                                true -> 1;
                                                false -> 0
                                            end,
                                            Shield4 = 1,
                                            Shield5 = 1;
                                        _ ->
                                            %% 防守方
                                            case get(defender) of
                                                DefEtsGuild0 when DefEtsGuild0#ets_guild.id =:= UniteStatus#unite_status.guild_id ->
                                                    Shield1 = 1,
                                                    Shield2 = 1,
                                                    Shield3 = 1,
                                                    Shield4 = 1,
                                                    Shield5 = 0;
                                                %% 援助
                                                _ ->
                                                    %Shield1 = case lists:member(NowDay, [State#city_war_state.open_days]) of
                                                    %    true -> 0;
                                                    %    false -> 1
                                                    %end,
                                                    Shield1 = case util:unixtime() > UnixEndApplyTime of
                                                        true -> 1;
                                                        false -> 0
                                                    end,
                                                    Shield2 = 1,
                                                    Shield4 = case lists:member(NowDay, [State#city_war_state.open_days]) of
                                                        true -> 0;
                                                        false -> 1
                                                    end,
                                                    Shield5 = 1,
                                                    %% 是否已过抢夺时间，屏蔽抢夺按钮
                                                    Shield3 = case util:unixtime() > UnixEndSeizeTime of
                                                        true -> 1;
                                                        false -> 0
                                                    end
                                            end        
                                    end
                            end
                    end,
                    GuildId = UniteStatus#unite_status.guild_id,
                    %% AidState:援助按钮状态 1.援助 2.取消申请 3.撤兵
                    %% AidTarget:援助对象 0.未援助 1.进攻方 2.防守方
                    case get({apply, GuildId}) of
                        undefined -> 
                            case get({aid, GuildId}) of
                                undefined -> 
                                    AidTarget = 0,
                                    AidState = 1;
                                {_AidTarget, _TargetGuildId, _GuildInfo} -> 
                                    AidTarget = _AidTarget,
                                    AidState = 3
                            end;
                        {_AidTarget, _TargetGuildId, _GuildInfo} -> 
                            AidTarget = _AidTarget,
                            AidState = 2
                    end,
                    %% 进攻方信息
                    Attacker = case get(attacker) of
                        _AttGuildInfo when is_record(_AttGuildInfo, ets_guild) ->
                            AttackerId = _AttGuildInfo#ets_guild.id,
                            [{1, _AttGuildInfo#ets_guild.name, _AttGuildInfo#ets_guild.member_num, _AttGuildInfo#ets_guild.member_capacity, _AttGuildInfo#ets_guild.chief_name, _AttGuildInfo#ets_guild.level}];
                        _ -> 
                            AttackerId = 0,
                            []
                    end,
                    %% 防守方信息
                    Defender = case get(defender) of
                        _DefGuildInfo when is_record(_DefGuildInfo, ets_guild) ->
                            [{3, _DefGuildInfo#ets_guild.name, _DefGuildInfo#ets_guild.member_num, _DefGuildInfo#ets_guild.member_capacity, _DefGuildInfo#ets_guild.chief_name, _DefGuildInfo#ets_guild.level}];
                        _ -> 
                            []
                    end,
                    %% 进攻援助
                    AttAids = lib_city_war:att_aids(get(), [], AttackerId),
                    %% 防守援助
                    DefAids = lib_city_war:def_aids(get(), []),
                    _GuildInfoList = Attacker ++ AttAids ++ Defender ++ DefAids,
                    GuildInfoList = lists:reverse(lists:keysort(6, _GuildInfoList)),
                    %io:format("GuildInfoList:~p~n", [GuildInfoList]),
                    Res = 1,
                    Str = data_city_war_text:get_city_war_error_tips(2)
            end,
            %io:format("~p~n", [[Shield1, Shield2, Shield3, Shield4, Shield5]]),
            {ok, BinData} = pt_641:write(64103, [Res, Str, AidState, AidTarget, GuildInfoList, Shield1, Shield2, Shield3, Shield4, Shield5]),
            lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData)
    end.

%% 援助/取消申请/撤兵
aid_or_cancel([UniteStatus, AidTarget, State]) ->
    NowDay = calendar:day_of_the_week(date()),
    case lists:member(NowDay, [State#city_war_state.seize_days, State#city_war_state.open_days]) of
        %% 失败，不是活动日
        false ->
            Res = 2,
            Str = data_city_war_text:get_city_war_error_tips(0);
        true ->
            GuildId = UniteStatus#unite_status.guild_id,
            %% 进攻方和防守方不能进行援助操作
            CannotAid = case get(attacker) of
                _AttGuildInfo when _AttGuildInfo#ets_guild.id =:= GuildId -> 1;
                _ ->
                    case get(defender) of
                        _DefGuildInfo when _DefGuildInfo#ets_guild.id =:= GuildId -> 1;
                        _ -> 0
                    end
            end,
            case CannotAid of
                %% 失败，进攻方和防守方不能进行援助操作
                1 ->
                    Res = 3,
                    Str = data_city_war_text:get_city_war_error_tips(15);
                _ ->
                    %% AidState:援助按钮状态 1.援助 2.取消申请 3.撤兵
                    %% AlAidTarget:援助对象 0.未援助 1.进攻方 2.防守方
                    case get({apply, GuildId}) of
                        undefined -> 
                            case get({aid, GuildId}) of
                                undefined -> 
                                    AlAidTarget = 0,
                                    AidState = 1;
                                {_AidTarget, _TargetGuildId, _GuildInfo} -> 
                                    AlAidTarget = _AidTarget,
                                    AidState = 3
                            end;
                        {_AidTarget, _TargetGuildId, _GuildInfo} -> 
                            AlAidTarget = _AidTarget,
                            AidState = 2
                    end,
                    %io:format("AidState:~p~n", [AidState]),
                    UnixEndApplyTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.apply_end_hour * 3600 + State#city_war_state.apply_end_minute * 60,
                    %io:format("UnixEndApplyTime:~p~n", [util:seconds_to_localtime(UnixEndApplyTime)]),
                    case util:unixtime() > UnixEndApplyTime of
                        %% 活动已开始，不允许该操作
                        true ->
                            Res = 2,
                            Str = data_city_war_text:get_city_war_error_tips(3);
                        false ->
                            case AidState =/= 1 andalso AlAidTarget =/= AidTarget of
                                %% 失败，未申请对该对象进行援助
                                true ->
                                    Res = 2,
                                    Str = data_city_war_text:get_city_war_error_tips(4);
                                false ->
                                    case get(city_war_info) of
                                        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
                                            ok;
                                        _ ->
                                            CityWarInfo = #city_war_info{}
                                    end,
                                    %MaxAidNum = data_city_war:get_city_war_config(max_aid_num),
                                    MaxAidNum = 99999,
                                    %% AidState: 1.援助 2.取消申请 3.撤兵
                                    case AidState of
                                        1 -> 
                                            GuildInfo = lib_guild:get_guild(GuildId),
                                            case is_record(GuildInfo, ets_guild) of
                                                true -> 
                                                    %% 1.援助进攻方 2.援助防守方
                                                    case AidTarget of
                                                        1 -> 
                                                            case get(attacker) of
                                                                AttGuildInfo when is_record(AttGuildInfo, ets_guild) ->
                                                                    TargetGuildName = AttGuildInfo#ets_guild.name,
                                                                    TargetGuildId = AttGuildInfo#ets_guild.id,
                                                                    OverMaxAidNum = case CityWarInfo#city_war_info.att_aid_num >= MaxAidNum of
                                                                        true ->
                                                                            1;
                                                                        false ->
                                                                            %% %% 进攻方审批按钮闪烁
                                                                            {ok, BinData1} = pt_641:write(64118, [1]),
                                                                            lib_unite_send:send_to_uid(AttGuildInfo#ets_guild.chief_id, BinData1),
                                                                            lib_unite_send:send_to_uid(AttGuildInfo#ets_guild.deputy_chief1_id, BinData1),
                                                                            lib_unite_send:send_to_uid(AttGuildInfo#ets_guild.deputy_chief2_id, BinData1),
                                                                            0
                                                                    end;
                                                                _ ->
                                                                    OverMaxAidNum = 0,
                                                                    TargetGuildName = "",
                                                                    TargetGuildId = 0
                                                            end;
                                                        _ -> 
                                                            case get(defender) of
                                                                DefGuildInfo when is_record(DefGuildInfo, ets_guild) ->
                                                                    TargetGuildName = DefGuildInfo#ets_guild.name,
                                                                    TargetGuildId = DefGuildInfo#ets_guild.id,
                                                                    OverMaxAidNum = case CityWarInfo#city_war_info.def_aid_num >= MaxAidNum of
                                                                        true ->
                                                                            1;
                                                                        false ->
                                                                            %% 防守方审批按钮闪烁
                                                                            {ok, BinData2} = pt_641:write(64118, [2]),
                                                                            lib_unite_send:send_to_uid(DefGuildInfo#ets_guild.chief_id, BinData2),
                                                                            lib_unite_send:send_to_uid(DefGuildInfo#ets_guild.deputy_chief1_id, BinData2),
                                                                            lib_unite_send:send_to_uid(DefGuildInfo#ets_guild.deputy_chief2_id, BinData2),
                                                                            0
                                                                    end;
                                                                _ ->
                                                                    OverMaxAidNum = 0,
                                                                    TargetGuildName = "",
                                                                    TargetGuildId = 0
                                                            end
                                                    end,
                                                    case TargetGuildId of
                                                        %% 失败，没有进攻方
                                                        0 ->
                                                            Res = 2,
                                                            Str = data_city_war_text:get_city_war_error_tips(9);
                                                        %% 成功
                                                        _ ->
                                                            case OverMaxAidNum of
                                                                %% 失败，援助帮派数量已达5个
                                                                1 ->
                                                                    Res = 2,
                                                                    Str = data_city_war_text:get_city_war_error_tips(43);
                                                                _ ->
                                                                    put({apply, GuildId}, {AidTarget, TargetGuildId, GuildInfo}),
                                                                    Res = 1,
                                                                    Str = case AidTarget of
                                                                        1 ->
                                                                            io_lib:format(data_city_war_text:get_city_war_error_tips(33), [util:make_sure_list(TargetGuildName)]);
                                                                        _ ->
                                                                            io_lib:format(data_city_war_text:get_city_war_error_tips(34), [util:make_sure_list(TargetGuildName)])
                                                                    end
                                                            end
                                                    end;
                                                %% 失败，获取帮派信息失败
                                                false -> 
                                                    Res = 2,
                                                    Str = data_city_war_text:get_city_war_error_tips(5)
                                            end;
                                        2 -> 
                                            erase({apply, GuildId}),
                                            %% 取消闪烁
                                            cancel_shining(),
                                            Res = 1,
                                            Str = data_city_war_text:get_city_war_error_tips(2);
                                        _ -> 
                                            erase({aid, GuildId}),
                                            case AlAidTarget of
                                                1 ->
                                                    AttAidNum = CityWarInfo#city_war_info.att_aid_num,
                                                    NewAttAidNum = case AttAidNum > 0 of
                                                        true -> AttAidNum - 1;
                                                        false -> 0
                                                    end,
                                                    CityWarInfo2 = CityWarInfo#city_war_info{
                                                        att_aid_num = NewAttAidNum
                                                    };
                                                2 ->
                                                    DefAidNum = CityWarInfo#city_war_info.def_aid_num,
                                                    NewDefAidNum = case DefAidNum > 0 of
                                                        true -> DefAidNum - 1;
                                                        false -> 0
                                                    end,
                                                    CityWarInfo2 = CityWarInfo#city_war_info{
                                                        def_aid_num = NewDefAidNum
                                                    };
                                                _ ->
                                                    CityWarInfo2 = CityWarInfo
                                            end,
                                            put(city_war_info, CityWarInfo2),
                                            Res = 1,
                                            Str = data_city_war_text:get_city_war_error_tips(2)
                                    end
                            end
                    end
            end
    end,
    {ok, BinData} = pt_641:write(64104, [Res, Str]),
    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData),
    %% 刷新客户端
    case Res of
        1 ->
            get_apply_info([UniteStatus, State]);
        _ ->
            skip
    end.

%% 获取审批信息
get_approval_info([UniteStatus, Type, State]) ->
    NowDay = calendar:day_of_the_week(date()),
    case lists:member(NowDay, [State#city_war_state.seize_days, State#city_war_state.open_days]) of
        %% 失败，不是活动日
        false ->
            Res = 2,
            Str = data_city_war_text:get_city_war_error_tips(0),
            ApprovalInfoList = [],
            AidInfoList = [];
        true ->
            UnixBeginTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.config_begin_hour * 3600 + State#city_war_state.config_begin_minute * 60 - 60,
            %io:format("UnixBeginTime:~p~n", [util:seconds_to_localtime(UnixBeginTime)]),
            case util:unixtime() >= UnixBeginTime of
                %% 失败，审批时间已过
                true ->
                    Res = 2,
                    Str = data_city_war_text:get_city_war_error_tips(35),
                    ApprovalInfoList = [],
                    AidInfoList = [];
                false ->
                    GuildId = UniteStatus#unite_status.guild_id,
                    AidInfoList = get_aid_info_list(get(), [], GuildId),
                    %% Type: 1.进攻方审批 2.防守方审批
                    case Type of
                        1 ->
                            case get(attacker) of
                                GuildInfo when GuildInfo#ets_guild.id =:= GuildId ->
                                    Res = 1,
                                    Str = data_city_war_text:get_city_war_error_tips(2),
                                    ApprovalInfoList = lib_city_war:att_approval(get(), [], GuildId);
                                %% 失败，只有进攻方帮主或副帮主才能进行该操作
                                _ ->
                                    Res = 2,
                                    Str = data_city_war_text:get_city_war_error_tips(7),
                                    ApprovalInfoList = []
                            end;
                        _ ->
                            case get(defender) of
                                GuildInfo when GuildInfo#ets_guild.id =:= GuildId ->
                                    Res = 1,
                                    Str = data_city_war_text:get_city_war_error_tips(2),
                                    ApprovalInfoList = lib_city_war:def_approval(get(), [], GuildId);
                                %% 失败，只有防守方帮主或副帮主才能进行该操作
                                _ ->
                                    Res = 2,
                                    Str = data_city_war_text:get_city_war_error_tips(8),
                                    ApprovalInfoList = []
                            end
                    end
            end
    end,
    %io:format("64105 Reply:~p~n", [[Res, Str, ApprovalInfoList, AidInfoList]]),
    {ok, BinData} = pt_641:write(64105, [Res, Str, ApprovalInfoList, AidInfoList]),
    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData).

%% 审批申请信息
approval_apply([UniteStatus, ApplyGuildId, Answer, State]) ->
    NowDay = calendar:day_of_the_week(date()),
    case lists:member(NowDay, [State#city_war_state.seize_days, State#city_war_state.open_days]) of
        %% 失败，不是活动日
        false ->
            Type = 0,
            Res = 2,
            Str = data_city_war_text:get_city_war_error_tips(0);
        true ->
            UnixEndApplyTime = util:unixdate() + (State#city_war_state.open_days - NowDay) * 24 * 3600 + State#city_war_state.apply_end_hour * 3600 + State#city_war_state.apply_end_minute * 60,
            case util:unixtime() > UnixEndApplyTime of
                %% 失败，已过审批时间
                true ->
                    Type = 0,
                    Res = 2,
                    Str = data_city_war_text:get_city_war_error_tips(48);
                false ->
                    GuildId = UniteStatus#unite_status.guild_id,
                    case get(city_war_info) of
                        CityWarInfo when is_record(CityWarInfo, city_war_info) ->
                            ok;
                        _ ->
                            CityWarInfo = #city_war_info{}
                    end,
                    MaxAidNum = data_city_war:get_city_war_config(max_aid_num),
                    case get(attacker) of
                        %% 进攻方
                        AttGuildInfo when AttGuildInfo#ets_guild.id =:= GuildId ->
                            Type = 1,
                            case Answer of
                                3 ->
                                    %% 撤销
                                    case get({aid, ApplyGuildId}) of
                                        {1, GuildId, _ApplyGuildInfo} ->
                                            erase({aid, ApplyGuildId}),
                                            AttAidNum = CityWarInfo#city_war_info.att_aid_num,
                                            NewAttAidNum = case AttAidNum > 0 of
                                                true -> AttAidNum - 1;
                                                false -> 0
                                            end,
                                            CityWarInfo2 = CityWarInfo#city_war_info{
                                                att_aid_num = NewAttAidNum
                                            },
                                            put(city_war_info, CityWarInfo2),
                                            Title = data_city_war_text:get_city_war_text(25),
                                            Content = io_lib:format(data_city_war_text:get_city_war_text(26), [util:make_sure_list(AttGuildInfo#ets_guild.name)]),
                                            MailList = [_ApplyGuildInfo#ets_guild.chief_id, _ApplyGuildInfo#ets_guild.deputy_chief1_id, _ApplyGuildInfo#ets_guild.deputy_chief2_id],
                                            %% 邮件提示
                                            lib_mail:send_sys_mail_bg(MailList, Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                            Res = 1,
                                            Str = data_city_war_text:get_city_war_error_tips(45);
                                        _ ->
                                            %% 失败，该帮派不是援助帮派
                                            Res = 2,
                                            Str = data_city_war_text:get_city_war_error_tips(44)
                                    end;
                                _ ->
                                    case get({apply, ApplyGuildId}) of
                                        %% 成功，找到该帮派
                                        {1, GuildId, _ApplyGuildInfo} ->
                                            case Answer of
                                                %% 同意
                                                1 ->
                                                    OverMaxAidNum = case CityWarInfo#city_war_info.att_aid_num >= MaxAidNum of
                                                        true ->
                                                            Title = "",
                                                            Content = "",
                                                            CityWarInfo2 = CityWarInfo,
                                                            1;
                                                        false ->
                                                            erase({apply, ApplyGuildId}),
                                                            CityWarInfo2 = CityWarInfo#city_war_info{
                                                                att_aid_num = CityWarInfo#city_war_info.att_aid_num + 1
                                                            },
                                                            put({aid, ApplyGuildId}, {1, GuildId, _ApplyGuildInfo}),
                                                            update_applyer_pannel(_ApplyGuildInfo, State),
                                                            Title = data_city_war_text:get_city_war_text(1),
                                                            Content = io_lib:format(data_city_war_text:get_city_war_text(2), [util:make_sure_list(AttGuildInfo#ets_guild.name)]),
                                                            0
                                                    end;
                                                %% 拒绝
                                                2 ->
                                                    erase({apply, ApplyGuildId}),
                                                    OverMaxAidNum = 0,
                                                    CityWarInfo2 = CityWarInfo,
                                                    Title = data_city_war_text:get_city_war_text(1),
                                                    Content = io_lib:format(data_city_war_text:get_city_war_text(3), [util:make_sure_list(AttGuildInfo#ets_guild.name)])
                                            end,
                                            case OverMaxAidNum of
                                                %% 失败，援助帮派数量已达5个
                                                1 ->
                                                    Res = 2,
                                                    Str = data_city_war_text:get_city_war_error_tips(43);
                                                _ ->
                                                    put(city_war_info, CityWarInfo2),
                                                    %% 取消闪烁
                                                    cancel_shining(),
                                                    MailList = [_ApplyGuildInfo#ets_guild.chief_id, _ApplyGuildInfo#ets_guild.deputy_chief1_id, _ApplyGuildInfo#ets_guild.deputy_chief2_id],
                                                    %% 邮件提示
                                                    lib_mail:send_sys_mail_bg(MailList, Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                                    Res = 1,
                                                    Str = data_city_war_text:get_city_war_error_tips(2)
                                            end;
                                        _ ->
                                            %% 失败，该帮派没有申请进攻援助
                                            Res = 2,
                                            Str = data_city_war_text:get_city_war_error_tips(10)
                                    end
                            end;
                        _ ->
                            case get(defender) of
                                %% 防守方
                                DefGuildInfo when DefGuildInfo#ets_guild.id =:= GuildId ->
                                    Type = 2,
                                    case Answer of
                                        3 ->
                                            %% 撤销
                                            case get({aid, ApplyGuildId}) of
                                                {2, GuildId, _ApplyGuildInfo} ->
                                                    erase({aid, ApplyGuildId}),
                                                    DefAidNum = CityWarInfo#city_war_info.def_aid_num,
                                                    NewDefAidNum = case DefAidNum > 0 of
                                                        true -> DefAidNum - 1;
                                                        false -> 0
                                                    end,
                                                    CityWarInfo2 = CityWarInfo#city_war_info{
                                                        def_aid_num = NewDefAidNum
                                                    },
                                                    put(city_war_info, CityWarInfo2),
                                                    Title = data_city_war_text:get_city_war_text(25),
                                                    Content = io_lib:format(data_city_war_text:get_city_war_text(27), [util:make_sure_list(DefGuildInfo#ets_guild.name)]),
                                                    MailList = [_ApplyGuildInfo#ets_guild.chief_id, _ApplyGuildInfo#ets_guild.deputy_chief1_id, _ApplyGuildInfo#ets_guild.deputy_chief2_id],
                                                    %% 邮件提示
                                                    lib_mail:send_sys_mail_bg(MailList, Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                                    Res = 1,
                                                    Str = data_city_war_text:get_city_war_error_tips(45);
                                                _ ->
                                                    %% 失败，该帮派不是援助帮派
                                                    Res = 2,
                                                    Str = data_city_war_text:get_city_war_error_tips(44)
                                            end;
                                        _ ->
                                            case get({apply, ApplyGuildId}) of
                                                %% 成功，找到该帮派
                                                {2, GuildId, _ApplyGuildInfo} ->
                                                    case Answer of
                                                        %% 同意
                                                        1 ->
                                                            OverMaxAidNum = case CityWarInfo#city_war_info.def_aid_num >= MaxAidNum of
                                                                true ->
                                                                    Title = "",
                                                                    Content = "",
                                                                    CityWarInfo2 = CityWarInfo,
                                                                    1;
                                                                false ->
                                                                    erase({apply, ApplyGuildId}),
                                                                    CityWarInfo2 = CityWarInfo#city_war_info{
                                                                        def_aid_num = CityWarInfo#city_war_info.def_aid_num + 1
                                                                    },
                                                                    put({aid, ApplyGuildId}, {2, GuildId, _ApplyGuildInfo}),
                                                                    update_applyer_pannel(_ApplyGuildInfo, State),
                                                                    Title = data_city_war_text:get_city_war_text(1),
                                                                    Content = io_lib:format(data_city_war_text:get_city_war_text(4), [util:make_sure_list(DefGuildInfo#ets_guild.name)]),
                                                                    0
                                                            end;
                                                        %% 拒绝
                                                        2 ->
                                                            erase({apply, ApplyGuildId}),
                                                            OverMaxAidNum = 0,
                                                            CityWarInfo2 = CityWarInfo,
                                                            Title = data_city_war_text:get_city_war_text(1),
                                                            Content = io_lib:format(data_city_war_text:get_city_war_text(5), [util:make_sure_list(DefGuildInfo#ets_guild.name)])
                                                    end,
                                                    case OverMaxAidNum of
                                                        %% 失败，援助帮派数量已达5个
                                                        1 ->
                                                            Res = 2,
                                                            Str = data_city_war_text:get_city_war_error_tips(43);
                                                        _ ->
                                                            put(city_war_info, CityWarInfo2),
                                                            %% 取消闪烁
                                                            cancel_shining(),
                                                            MailList = [_ApplyGuildInfo#ets_guild.chief_id, _ApplyGuildInfo#ets_guild.deputy_chief1_id, _ApplyGuildInfo#ets_guild.deputy_chief2_id],
                                                            %% 邮件提示
                                                            lib_mail:send_sys_mail_bg(MailList, Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0),
                                                            Res = 1,
                                                            Str = data_city_war_text:get_city_war_error_tips(2)
                                                    end;
                                                %% 失败，该帮派没有申请防守援助
                                                _ ->
                                                    Res = 2,
                                                    Str = data_city_war_text:get_city_war_error_tips(11)
                                            end
                                    end;
                                %% 失败，只有进攻方或防守方的帮主或副帮主才能进行该操作
                                _ ->
                                    Type = 0,
                                    Res = 2,
                                    Str = data_city_war_text:get_city_war_error_tips(12)
                            end
                    end
            end
    end,
    {ok, BinData} = pt_641:write(64106, [Res, Str]),
    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData),
    %% 刷新客户端
    case Res of
        1 ->
            case Type > 0 of
                true ->
                    get_approval_info([UniteStatus, Type, State]);
                false ->
                    skip
            end;
        _ ->
            skip
    end.

%% 获取抢夺信息
get_seize_info([UniteStatus, State]) -> 
    NowDay = calendar:day_of_the_week(date()),
    UnixEndSeizeTime = util:unixdate() + (State#city_war_state.seize_days - NowDay) * 24 * 3600 + State#city_war_state.end_seize_hour * 3600 + State#city_war_state.end_seize_minute * 60,
    AllCoin = case catch lib_player:get_player_info(UniteStatus#unite_status.id, all_coin) of
        _AllCoin when is_integer(_AllCoin) -> _AllCoin;
        _ -> 0
    end,
    case lists:member(NowDay, [State#city_war_state.seize_days, State#city_war_state.open_days]) of
        %% 失败，不是活动日
        false ->
            skip;
        %Res = 2,
        %Str = data_city_war_text:get_city_war_error_tips(0), 
        %SeizeInfoList = [];
        true ->
            case util:unixtime() < UnixEndSeizeTime of
                false ->
                    skip;
                true ->
                    case get(pre_five) of
                        List when is_list(List) ->
                            Res = 1,
                            Str = data_city_war_text:get_city_war_error_tips(2),
                            SeizeInfoList = lib_city_war:get_seize_info(List, []);
                        %% 失败，操作失败
                        _ ->
                            Res = 2,
                            Str = data_city_war_text:get_city_war_error_tips(1),
                            SeizeInfoList = []
                    end,
                    %io:format("SeizeInfoList:~p~n", [SeizeInfoList]),
                    {ok, BinData} = pt_641:write(64107, [Res, Str, SeizeInfoList, AllCoin]),
                    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData)
            end
    end.

%% 取消闪烁
cancel_shining() ->
    %% 是否有进攻援助申请
    case has_apply(1) of
        true ->
            skip;
        false ->
            case get(attacker) of
                AttGuildInfo when is_record(AttGuildInfo, ets_guild) ->
                    %% 进攻方取消审批按钮闪烁
                    {ok, BinData1} = pt_641:write(64118, [0]),
                    lib_unite_send:send_to_uid(AttGuildInfo#ets_guild.chief_id, BinData1),
                    lib_unite_send:send_to_uid(AttGuildInfo#ets_guild.deputy_chief1_id, BinData1),
                    lib_unite_send:send_to_uid(AttGuildInfo#ets_guild.deputy_chief2_id, BinData1);
                _ ->
                    skip
            end
    end,
    %% 是否有防守援助申请
    case has_apply(2) of
        true ->
            skip;
        false ->
            case get(defender) of
                DefGuildInfo when is_record(DefGuildInfo, ets_guild) ->
                    %% 进攻方取消审批按钮闪烁
                    {ok, BinData2} = pt_641:write(64118, [0]),
                    lib_unite_send:send_to_uid(DefGuildInfo#ets_guild.chief_id, BinData2),
                    lib_unite_send:send_to_uid(DefGuildInfo#ets_guild.deputy_chief1_id, BinData2),
                    lib_unite_send:send_to_uid(DefGuildInfo#ets_guild.deputy_chief2_id, BinData2);
                _ ->
                    skip
            end
    end.

%% 是否有援助列表
%% Type:1.进攻援助 2.防守援助
has_apply(Type) ->
    All = get(),
    has_apply1(All, Type).

has_apply1([], _Type) -> false;
has_apply1([H | T], Type) ->
    case H of
        {{apply, _GuildId}, {Type, _, _}} ->
            true;
        _ ->
            has_apply1(T, Type)
    end.

%% 秘籍获得抢夺权限
gm_apply(GuildId) ->
    case get(pre_five) of
        PreFive when is_list(PreFive) ->
            GuildInfo = lib_guild:get_guild(GuildId),
            case is_record(GuildInfo, ets_guild) of
                true ->
                    put(pre_five, [{GuildId, 0, GuildInfo, 0} | PreFive]);
                false ->
                    skip
            end;
        _ ->
            skip
    end.

%% 更新申请者的面板
update_applyer_pannel(ApplyGuildInfo, State) ->
    case is_record(ApplyGuildInfo, ets_guild) of
        true ->
            Id1 = ApplyGuildInfo#ets_guild.chief_id,
            Id2 = ApplyGuildInfo#ets_guild.deputy_chief1_id,
            Id3 = ApplyGuildInfo#ets_guild.deputy_chief2_id,
            UniteStatus1 = lib_player_unite:get_unite_status_unite(Id1),
            UniteStatus2 = lib_player_unite:get_unite_status_unite(Id2),
            UniteStatus3 = lib_player_unite:get_unite_status_unite(Id3),
            UniteStatus = #unite_status{},
            case UniteStatus1 of
                UniteStatus -> skip;
                _ -> get_apply_info([UniteStatus1, State])
            end,
            case UniteStatus2 of
                UniteStatus -> skip;
                _ -> get_apply_info([UniteStatus2, State])
            end,
            case UniteStatus3 of
                UniteStatus -> skip;
                _ -> get_apply_info([UniteStatus3, State])
            end;
        false ->
            skip
    end.

get_aid_info_list([], L, _GuildId) -> L;
get_aid_info_list([H | T], L, GuildId) ->
    case H of
        {{aid, _AidGuildId}, {_Type, GuildId, GuildInfo}} ->
            Info = {GuildInfo#ets_guild.id, GuildInfo#ets_guild.name, GuildInfo#ets_guild.chief_name, GuildInfo#ets_guild.realm, GuildInfo#ets_guild.member_num, GuildInfo#ets_guild.member_capacity},
            get_aid_info_list(T, [Info | L], GuildId);
        _ ->
            get_aid_info_list(T, L, GuildId)
    end.
