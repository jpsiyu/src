%%%------------------------------------
%%% @Module  : lib_marriage_other
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.10.24
%%% @Description: 结婚系统-离婚
%%%------------------------------------
-module(lib_marriage_other).
-export([
        check_agree_divorce/1,
        ensure_agree_divorce/1,
        force_divorce/1,
        force_divorce_state/1,
        single_divorce/1,
        cancel_force_divorce/1,
        get_mark_info/1,
        get_mark_award/2,
        add_dun_num/1,
        add_skill_num/1
    ]).
-include("server.hrl").
-include("marriage.hrl").

%% 预约协议离婚
check_agree_divorce(Status) ->
    _Marriage = mod_marriage:get_wedding_info(Status#player_status.marriage#status_marriage.id),
    Marriage = case is_record(_Marriage, marriage) of
        true -> _Marriage;
        false -> #marriage{}
    end,
    %% 未结婚
    NoMarriage = Marriage#marriage.register_time =:= 0,
    %% 已申请强制离婚
    ApplyDivorce = Marriage#marriage.apply_divorce_time =/= 0,
    %% 已预约或正在举办婚宴
    InWedding = lib_marriage:marry_state(Status#player_status.marriage) =:= 6 orelse lib_marriage:marry_state(Status#player_status.marriage) =:= 7,
    %% 已预约或正在举办巡游
    InCruise = lib_marriage:marry_state(Status#player_status.marriage) =:= 12 orelse lib_marriage:marry_state(Status#player_status.marriage) =:= 8,
    %% 必须伴侣在线
    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
    NotOnline = case misc:get_player_process(ParnerId) of
        Pid when is_pid(Pid) ->
            false;
        _ ->
            true
    end,
    %% 离婚协议等待生效中
    MarkSure = Marriage#marriage.mark_sure_time =/= 0,
    if
        %% 未结婚
        NoMarriage ->
            Res = 0,
            Str = data_marriage_text:get_error_text(1);
        %% 已申请强制离婚
        ApplyDivorce ->
            Res = 0,
            Str = data_marriage_text:get_error_text(2);
        %% 已预约或正在举办婚宴
        InWedding ->
            Res = 0,
            Str = data_marriage_text:get_error_text(3);
        %% 已预约或正在举办巡游
        InCruise ->
            Res = 0,
            Str = data_marriage_text:get_error_text(4);
        %% 伴侣不在线
        NotOnline ->
            Res = 0,
            Str = data_marriage_text:get_error_text(5);
        %% 离婚协议等待生效中
        MarkSure ->
            Res = 0,
            Str = data_marriage_text:get_error_text(11);
        %% 成功
        true ->
            Res = 1,
            Str = ""
    end,
    {Res, Str}.

%% 确认协议离婚
ensure_agree_divorce([Status, Ans]) ->
    mod_marriage:set_divorce_response([Status#player_status.id, Ans]),
    ParnerResponse = mod_marriage:get_divorce_response(Status#player_status.marriage#status_marriage.parner_id),
    %io:format("ParnerResponse:~p~n", [ParnerResponse]),
    case ParnerResponse of
        %% 伴侣未响应
        undefined ->
            Res = 2,
            Str = "";
        %% 伴侣拒绝
        2 ->
            mod_marriage:clear_divorce_response(Status#player_status.id),
            mod_marriage:clear_divorce_response(Status#player_status.marriage#status_marriage.parner_id),
            Res = 0,
            Str = data_marriage_text:get_error_text(7);
        1 ->
            case Ans of
                1 ->
                    _Marriage = mod_marriage:get_wedding_info(Status#player_status.marriage#status_marriage.id),
                    Marriage = case is_record(_Marriage, marriage) of
                        true -> _Marriage;
                        false -> #marriage{}
                    end,
                    mod_marriage:clear_divorce_response(Status#player_status.id),
                    mod_marriage:clear_divorce_response(Status#player_status.marriage#status_marriage.parner_id),
                    db:execute(io_lib:format(<<"update marriage set divorce = 3, mark_sure_time = ~p where id = ~p">>, [util:unixtime(), Status#player_status.marriage#status_marriage.id])),
                    %% 更新结婚信息
                    NewMarriage = Marriage#marriage{
                        mark_sure_time = util:unixtime()
                    },
                    mod_marriage:update_marriage_info(NewMarriage),
                    %divorce(Status),
                    %% 后台日志（协议离婚日志）
                    spawn(fun() ->
                                db:execute(io_lib:format(<<"insert into log_marriage1 set type = 5, active_id = ~p, passive_id = ~p, time = ~p">>, [Marriage#marriage.male_id, Marriage#marriage.female_id, util:unixtime()]))
                        end),
                    %% 邮件通知
                    Title1 = data_marriage_text:get_marriage_text(53),
                    {{_Year, _Mon, _Day}, {_Hour, _Min, _Sec}} = util:seconds_to_localtime(util:unixtime() + 3 * 24 * 3600),
                    Content1 = io_lib:format(data_marriage_text:get_marriage_text(54), [_Year, _Mon, _Day, _Hour, _Min, _Sec]),
                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.id, Status#player_status.marriage#status_marriage.parner_id], Title1, Content1, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
                    Res = 1,
                    Str = data_marriage_text:get_error_text(12);
                %% 自己拒绝
                2 ->
                    mod_marriage:clear_divorce_response(Status#player_status.id),
                    mod_marriage:clear_divorce_response(Status#player_status.marriage#status_marriage.parner_id),
                    Res = 0,
                    Str = data_marriage_text:get_error_text(7)
            end
    end,
    {Res, Str}.

%% 强制离婚
force_divorce(Status) ->
    case force_divorce_state(Status) of
        1 ->
            _Marriage = mod_marriage:get_wedding_info(Status#player_status.marriage#status_marriage.id),
            Marriage = case is_record(_Marriage, marriage) of
                true -> _Marriage;
                false -> #marriage{}
            end,
            %% 未结婚
            NoMarriage = Marriage#marriage.register_time =:= 0,
            %% 已预约或正在举办婚宴
            InWedding = lib_marriage:marry_state(Status#player_status.marriage) =:= 6 orelse lib_marriage:marry_state(Status#player_status.marriage) =:= 7,
            %% 已预约或正在举办巡游
            InCruise = lib_marriage:marry_state(Status#player_status.marriage) =:= 12 orelse lib_marriage:marry_state(Status#player_status.marriage) =:= 8,
            NeedMoney = 99,
            NotEnoughMoney = Status#player_status.gold < NeedMoney,
            %% 离婚协议等待生效中
            MarkSure = Marriage#marriage.mark_sure_time =/= 0,
            if 
                %% 未结婚
                NoMarriage ->
                    NewStatus = Status,
                    Res = 0,
                    Str = data_marriage_text:get_error_text(1);
                %% 已预约或正在举办婚宴
                InWedding ->
                    NewStatus = Status,
                    Res = 0,
                    Str = data_marriage_text:get_error_text(3);
                %% 已预约或正在举办巡游
                InCruise ->
                    NewStatus = Status,
                    Res = 0,
                    Str = data_marriage_text:get_error_text(4);
                NotEnoughMoney ->
                    NewStatus = Status,
                    Res = 0,
                    Str = data_marriage_text:get_error_text(6);
                %% 离婚协议等待生效中
                MarkSure ->
                    NewStatus = Status,
                    Res = 0,
                    Str = data_marriage_text:get_error_text(11);
                %% 申请成功
                true ->
                    NewStatus = lib_goods_util:cost_money(Status, NeedMoney, gold),
                    log:log_consume(divorce, gold, Status, NewStatus, "divorce"),
                    lib_player:refresh_client(Status#player_status.id, 2),
                    divorce(Status),
                    %% 邮件通知
                    Title1 = data_marriage_text:get_marriage_text(46),
                    Content1 = data_marriage_text:get_marriage_text(47),
                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.id], Title1, Content1, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
                    Title2 = data_marriage_text:get_marriage_text(48),
                    Content2 = data_marriage_text:get_marriage_text(49),
                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.marriage#status_marriage.parner_id], Title2, Content2, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
                    %% 后台日志（强制离婚日志）
                    spawn(fun() ->
                                db:execute(io_lib:format(<<"insert into log_marriage1 set type = 6, active_id = ~p, passive_id = ~p, time = ~p">>, [Marriage#marriage.male_id, Marriage#marriage.female_id, util:unixtime()]))
                        end),
                    Res = 1,
                    Str = data_marriage_text:get_error_text(9)
%%                    case Status#player_status.sex of
%%                        1 ->
%%                            db:execute(io_lib:format(<<"update marriage set divorce = 11, apply_divorce_time = ~p where id = ~p">>, [util:unixtime(), Status#player_status.marriage#status_marriage.id]));
%%                        _ ->
%%                            db:execute(io_lib:format(<<"update marriage set divorce = 12, apply_divorce_time = ~p where id = ~p">>, [util:unixtime(), Status#player_status.marriage#status_marriage.id]))
%%                    end,
%%                    %% 更新结婚信息
%%                    NewMarriage = Marriage#marriage{
%%                        apply_divorce_time = util:unixtime(),
%%                        apply_sex = Status#player_status.sex
%%                    },
%%                    mod_marriage:update_marriage_info(NewMarriage),
%%                    NewStatus = lib_goods_util:cost_money(Status, NeedMoney, gold),
%%                    log:log_consume(divorce, gold, Status, NewStatus, "divorce"),
%%                    lib_player:refresh_client(Status#player_status.id, 2),
%%                    Res = 1,
%%                    Str = data_marriage_text:get_error_text(8)
            end;
        %% 申请强制离婚需要3天审核时间
        2 ->
            NewStatus = Status,
            Res = 0,
            Str = data_marriage_text:get_error_text(21);
        3 ->
            divorce(Status),
            NewStatus = Status,
            Res = 1,
            Str = data_marriage_text:get_error_text(9)
    end,
    {Res, Str, NewStatus}.

%% 协议离婚状态
force_divorce_state(Status) ->
    _Marriage = mod_marriage:get_wedding_info(Status#player_status.marriage#status_marriage.id),
    Marriage = case is_record(_Marriage, marriage) of
        true -> _Marriage;
        false -> #marriage{}
    end,
    Res = case Marriage#marriage.mark_sure_time of
        %% 未申请
        0 ->
            1;
        Time ->
            case util:unixtime() >= Time + 3 * 24 * 60 * 60 of
                %% 已满足条件
                true ->
                    3;
                %% 已申请
                false ->
                    2
            end
    end,
    Res.

%% 单人离婚
single_divorce(Status) ->
    %% 未结婚
    NoMarriage = Status#player_status.marriage#status_marriage.register_time =:= 0,
    %% 必须伴侣7天内未上线
    NotOnline = case db:get_row(io_lib:format(<<"select last_logout_time from player_login where id = ~p limit 1">>, [Status#player_status.marriage#status_marriage.parner_id])) of
        [] ->
            true;
        [LastLoginTime] ->
            util:unixtime() < LastLoginTime + 7 * 24 * 60 *60
    end,
    %io:format("NotOnline:~p~n", [NotOnline]),
    if
        NoMarriage ->
            Res = 0,
            Str = data_marriage_text:get_error_text(1);
        NotOnline ->
            Res = 0,
            Str = data_marriage_text:get_error_text(31);
        true ->
            divorce(Status),
            %% 邮件通知
            Title1 = data_marriage_text:get_marriage_text(50),
            Content1 = data_marriage_text:get_marriage_text(51),
            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.id], Title1, Content1, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            Title2 = data_marriage_text:get_marriage_text(48),
            Content2 = data_marriage_text:get_marriage_text(52),
            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.marriage#status_marriage.parner_id], Title2, Content2, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            %% 后台日志（单人离婚日志）
            spawn(fun() ->
                        db:execute(io_lib:format(<<"insert into log_marriage1 set type = 7, active_id = ~p, passive_id = ~p, time = ~p">>, [Status#player_status.id, Status#player_status.marriage#status_marriage.parner_id, util:unixtime()]))
                end),
            Res = 1,
            Str = data_marriage_text:get_error_text(9)
    end,
    {Res, Str}.

%% 离婚处理
divorce(Status) ->
    Id = Status#player_status.marriage#status_marriage.id,
    PlayerId = Status#player_status.id,
    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
    db:execute(io_lib:format(<<"update marriage set divorce = 1, divorce_time = ~p where id = ~p">>, [util:unixtime(), Id])),
    db:execute(io_lib:format(<<"delete from marriage_mark where id = ~p">>, [PlayerId])),
    db:execute(io_lib:format(<<"delete from marriage_mark where id = ~p">>, [ParnerId])),
    db:execute(io_lib:format(<<"delete from marriage_task where id = ~p">>, [Id])),
    %% 删除好友
    lib_relationship:delete_rela_for_divorce(Status#player_status.pid, PlayerId, ParnerId),
    lib_player:update_player_info(PlayerId, [{marriage, #status_marriage{divorce = 1, divorce_state = 1}}]),
    lib_player:update_player_info(ParnerId, [{marriage, #status_marriage{divorce = 1, divorce_state = 1}}]),
    mod_marriage:clear_marriage([Id, PlayerId, ParnerId]),
    %% 离婚取消称号
    case Status#player_status.sex of
        1 ->
            lib_designation:remove_design_in_server(PlayerId, 201801),
            lib_designation:remove_design_in_server(ParnerId, 201802);
        _ ->
            lib_designation:remove_design_in_server(ParnerId, 201801),
            lib_designation:remove_design_in_server(PlayerId, 201802)
    end.

%% 取消协议离婚
cancel_force_divorce(Status) ->
    case force_divorce_state(Status) of
        1 ->
            Res = 0,
            Str = data_marriage_text:get_error_text(41);
        _ ->
            _Marriage = mod_marriage:get_wedding_info(Status#player_status.marriage#status_marriage.id),
            Marriage = case is_record(_Marriage, marriage) of
                true -> _Marriage;
                false -> #marriage{}
            end,
            db:execute(io_lib:format(<<"update marriage set divorce = 0, mark_sure_time = 0 where id = ~p">>, [Status#player_status.marriage#status_marriage.id])),
            NewMarriage = Marriage#marriage{
                mark_sure_time = 0
            },
            mod_marriage:update_marriage_info(NewMarriage),
            Res = 1,
            Str = data_marriage_text:get_error_text(10)
    end,
    {Res, Str}.

%% 获得结婚纪念日信息
get_mark_info(Status) ->
    MyId = Status#player_status.id,
    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
    case Status#player_status.marriage#status_marriage.register_time of
        %% 未结婚
        0 ->
            Res = 1,
            Str = "",
            %% 夫妻情缘任务
            RelaNum = 0,
            NameStr11 = data_marriage_text:get_error_text(60),
            ContentStr11 = data_marriage_text:get_error_text(63),
            Array1 = {1, 9, RelaNum, 611601, NameStr11, ContentStr11, 9, 1},
            %% 夫妻等级
            MinLv = 0,
            NameStr22 = data_marriage_text:get_error_text(66),
            ContentStr22 = data_marriage_text:get_error_text(69),
            Array2 = {2, 55, MinLv, 611601, NameStr22, ContentStr22, 9, 1},
            %% 夫妻多人副本
            NameStr33 = data_marriage_text:get_error_text(72),
            ContentStr33 = data_marriage_text:get_error_text(75),
            Array3 = {3, 9, 0, 611601, NameStr33, ContentStr33, 9, 1},
            %% 夫妻技能
            NameStr44 = data_marriage_text:get_error_text(78),
            ContentStr44 = data_marriage_text:get_error_text(81),
            Array4 = {4, 22, 0, 611601, NameStr44, ContentStr44, 9, 1},
            %% 夫妻恩爱秀
            NameStr55 = data_marriage_text:get_error_text(84),
            ContentStr55 = data_marriage_text:get_error_text(87),
            Array5 = {5, 1, 0, 611601, NameStr55, ContentStr55, 9, 1},
            %% 结婚纪念日
            NowDay = 0,
            NameStr66 = data_marriage_text:get_error_text(90),
            ContentStr66 = data_marriage_text:get_error_text(95),
            Array6 = {6, 7, NowDay, 602031, NameStr66, ContentStr66, 1, 1},
            Array = [Array1, Array2, Array3, Array4, Array5, Array6],
            ArrayPro1 = 0,
            ArrayPro2 = 0,
            ArrayPro3 = 0,
            ArrayPro4 = 0,
            ArrayPro5 = 0;
        _ ->
            case db:get_row(io_lib:format(<<"select award_a, award_b, award_c, award_d, award_e, award_day, dun_num, skill_num from marriage_mark where id = ~p limit 1">>, [Status#player_status.id])) of
                %% 获取信息失败，初始化数据
                [] ->
                    db:execute(io_lib:format(<<"insert into marriage_mark set id = ~p">>, [Status#player_status.id])),
                    %% 夫妻情缘任务
                    RelaNum = lib_relationship:find_xlqy_count(MyId, ParnerId),
                    NameStr11 = data_marriage_text:get_error_text(60),
                    ContentStr11 = data_marriage_text:get_error_text(63),
                    Array1 = {1, 9, RelaNum, 611601, NameStr11, ContentStr11, 9, 1},
                    %% 夫妻等级
                    MyLv = Status#player_status.lv,
                    [_NickName, _Sex, ParnerLv, _Career, _Realm, _GuildId, _Mount_limit, _HusongNpc, _Image|_] = lib_player:get_player_low_data(ParnerId),
                    MinLv = case MyLv > ParnerLv of
                        true -> ParnerLv;
                        false -> MyLv
                    end,
                    NameStr22 = data_marriage_text:get_error_text(66),
                    ContentStr22 = data_marriage_text:get_error_text(69),
                    Array2 = {2, 55, MinLv, 611601, NameStr22, ContentStr22, 9, 1},
                    %% 夫妻多人副本
                    NameStr33 = data_marriage_text:get_error_text(72),
                    ContentStr33 = data_marriage_text:get_error_text(75),
                    Array3 = {3, 9, 0, 611601, NameStr33, ContentStr33, 9, 1},
                    %% 夫妻技能
                    NameStr44 = data_marriage_text:get_error_text(78),
                    ContentStr44 = data_marriage_text:get_error_text(81),
                    Array4 = {4, 22, 0, 611601, NameStr44, ContentStr44, 9, 1},
                    %% 夫妻恩爱秀
                    NameStr55 = data_marriage_text:get_error_text(84),
                    ContentStr55 = data_marriage_text:get_error_text(87),
                    Array5 = {5, 1, 1, 611601, NameStr55, ContentStr55, 9, 1},
                    %% 结婚纪念日
                    RegisterTime = Status#player_status.marriage#status_marriage.register_time,
                    NowDay = (util:unixtime() - RegisterTime) div (24 * 60 * 60),
                    NameStr66 = data_marriage_text:get_error_text(90),
                    ContentStr66 = data_marriage_text:get_error_text(95),
                    Array6 = {6, 7, NowDay, 602031, NameStr66, ContentStr66, 1, 1},
                    Res = 1,
                    Str = "",
                    Array = [Array1, Array2, Array3, Array4, Array5, Array6],
                    ArrayPro1 = 0,
                    ArrayPro2 = 0,
                    ArrayPro3 = 0,
                    ArrayPro4 = 0,
                    ArrayPro5 = 0;
                %% 成功
                [AwardA, AwardB, AwardC, AwardD, AwardE, AwardDay, DunNum, SkillNum] ->
                    %% 夫妻情缘任务
                    RelaNum = lib_relationship:find_xlqy_count(MyId, ParnerId),
                    Array1 = case AwardA of
                        0 ->
                            ArrayPro1 = 0,
                            NameStr11 = data_marriage_text:get_error_text(60),
                            ContentStr11 = data_marriage_text:get_error_text(63),
                            {1, 9, RelaNum, 611601, NameStr11, ContentStr11, 9, 1};
                        1 ->
                            ArrayPro1 = 1,
                            NameStr11 = data_marriage_text:get_error_text(61),
                            ContentStr11 = data_marriage_text:get_error_text(64),
                            {1, 22, RelaNum, 611602, NameStr11, ContentStr11, 1, 1};
                        2 ->
                            ArrayPro1 = 2,
                            NameStr11 = data_marriage_text:get_error_text(62),
                            ContentStr11 = data_marriage_text:get_error_text(65),
                            {1, 99, RelaNum, 611603, NameStr11, ContentStr11, 1, 1};
                        %% 不可领
                        _ ->
                            ArrayPro1 = 3,
                            NameStr11 = data_marriage_text:get_error_text(62),
                            ContentStr11 = data_marriage_text:get_error_text(65),
                            {1, 99, RelaNum, 611603, NameStr11, ContentStr11, 1, 0}
                    end,
                    %% 夫妻等级
                    MyLv = Status#player_status.lv,
                    [_NickName, _Sex, ParnerLv, _Career, _Realm, _GuildId, _Mount_limit, _HusongNpc, _Image|_] = lib_player:get_player_low_data(ParnerId),
                    MinLv = case MyLv > ParnerLv of
                        true -> ParnerLv;
                        false -> MyLv
                    end,
                    Array2 = case AwardB of
                        0 ->
                            ArrayPro2 = 0,
                            NameStr22 = data_marriage_text:get_error_text(66),
                            ContentStr22 = data_marriage_text:get_error_text(69),
                            {2, 55, MinLv, 611601, NameStr22, ContentStr22, 9, 1};
                        1 ->
                            ArrayPro2 = 1,
                            NameStr22 = data_marriage_text:get_error_text(67),
                            ContentStr22 = data_marriage_text:get_error_text(70),
                            {2, 60, MinLv, 611602, NameStr22, ContentStr22, 1, 1};
                        2 ->
                            ArrayPro2 = 2,
                            NameStr22 = data_marriage_text:get_error_text(68),
                            ContentStr22 = data_marriage_text:get_error_text(71),
                            {2, 65, MinLv, 611603, NameStr22, ContentStr22, 1, 1};
                        %% 不可领
                        _ ->
                            ArrayPro2 = 3,
                            NameStr22 = data_marriage_text:get_error_text(68),
                            ContentStr22 = data_marriage_text:get_error_text(71),
                            {2, 65, MinLv, 611603, NameStr22, ContentStr22, 1, 0}
                    end,
                    %% 夫妻多人副本
                    Array3 = case AwardC of
                        0 ->
                            ArrayPro3 = 0,
                            NameStr33 = data_marriage_text:get_error_text(72),
                            ContentStr33 = data_marriage_text:get_error_text(75),
                            {3, 9, DunNum, 611601, NameStr33, ContentStr33, 9, 1};
                        1 ->
                            ArrayPro3 = 1,
                            NameStr33 = data_marriage_text:get_error_text(73),
                            ContentStr33 = data_marriage_text:get_error_text(76),
                            {3, 22, DunNum, 611602, NameStr33, ContentStr33, 1, 1};
                        2 ->
                            ArrayPro3 = 2,
                            NameStr33 = data_marriage_text:get_error_text(74),
                            ContentStr33 = data_marriage_text:get_error_text(77),
                            {3, 99, DunNum, 611603, NameStr33, ContentStr33, 1, 1};
                        %% 不可领
                        _ ->
                            ArrayPro3 = 3,
                            NameStr33 = data_marriage_text:get_error_text(74),
                            ContentStr33 = data_marriage_text:get_error_text(77),
                            {3, 99, DunNum, 611603, NameStr33, ContentStr33, 1, 0}
                    end,
                    %% 夫妻技能
                    Array4 = case AwardD of
                        0 ->
                            ArrayPro4 = 0,
                            NameStr44 = data_marriage_text:get_error_text(78),
                            ContentStr44 = data_marriage_text:get_error_text(81),
                            {4, 99, SkillNum, 611601, NameStr44, ContentStr44, 9, 1};
                        1 ->
                            ArrayPro4 = 1,
                            NameStr44 = data_marriage_text:get_error_text(79),
                            ContentStr44 = data_marriage_text:get_error_text(82),
                            {4, 222, SkillNum, 611602, NameStr44, ContentStr44, 1, 1};
                        2 ->
                            ArrayPro4 = 2,
                            NameStr44 = data_marriage_text:get_error_text(80),
                            ContentStr44 = data_marriage_text:get_error_text(83),
                            {4, 999, SkillNum, 611603, NameStr44, ContentStr44, 1, 1};
                        %% 不可领
                        _ ->
                            ArrayPro4 = 3,
                            NameStr44 = data_marriage_text:get_error_text(80),
                            ContentStr44 = data_marriage_text:get_error_text(83),
                            {4, 999, SkillNum, 611603, NameStr44, ContentStr44, 1, 0}
                    end,
                    %% 夫妻恩爱秀
                    Array5 = case AwardE of
                        0 ->
                            ArrayPro5 = 0,
                            FinTaskE = case Status#player_status.marriage#status_marriage.register_time of
                                0 -> 0;
                                _ -> 1
                            end,
                            NameStr55 = data_marriage_text:get_error_text(84),
                            ContentStr55 = data_marriage_text:get_error_text(87),
                            {5, 1, FinTaskE, 611601, NameStr55, ContentStr55, 9, 1};
                        1 ->
                            ArrayPro5 = 1,
                            FinTaskE = case Status#player_status.marriage#status_marriage.wedding_time of
                                0 -> 0;
                                _ -> 1
                            end,
                            NameStr55 = data_marriage_text:get_error_text(85),
                            ContentStr55 = data_marriage_text:get_error_text(88),
                            {5, 1, FinTaskE, 611602, NameStr55, ContentStr55, 1, 1};
                        2 ->
                            ArrayPro5 = 2,
                            FinTaskE = case Status#player_status.marriage#status_marriage.cruise_time of
                                0 -> 0;
                                _ -> 1
                            end,
                            NameStr55 = data_marriage_text:get_error_text(86),
                            ContentStr55 = data_marriage_text:get_error_text(89),
                            {5, 1, FinTaskE, 611603, NameStr55, ContentStr55, 1, 1};
                        _ ->
                            ArrayPro5 = 3,
                            FinTaskE = case Status#player_status.marriage#status_marriage.cruise_time of
                                0 -> 0;
                                _ -> 1
                            end,
                            NameStr55 = data_marriage_text:get_error_text(86),
                            ContentStr55 = data_marriage_text:get_error_text(89),
                            {5, 1, FinTaskE, 611603, NameStr55, ContentStr55, 1, 0}
                    end,
                    %% 结婚纪念日
                    RegisterTime = Status#player_status.marriage#status_marriage.register_time,
                    NowDay = (util:unixtime() - RegisterTime) div (24 * 60 * 60),
                    Array6 = case AwardDay of
                        0 ->
                            NameStr66 = data_marriage_text:get_error_text(90),
                            ContentStr66 = data_marriage_text:get_error_text(95),
                            {6, 7, NowDay, 602031, NameStr66, ContentStr66, 1, 1};
                        1 ->
                            NameStr66 = data_marriage_text:get_error_text(91),
                            ContentStr66 = data_marriage_text:get_error_text(96),
                            {6, 15, NowDay, 602031, NameStr66, ContentStr66, 1, 1};
                        2 ->
                            NameStr66 = data_marriage_text:get_error_text(92),
                            ContentStr66 = data_marriage_text:get_error_text(97),
                            {6, 30, NowDay, 602031, NameStr66, ContentStr66, 1, 1};
                        3 ->
                            NameStr66 = data_marriage_text:get_error_text(93),
                            ContentStr66 = data_marriage_text:get_error_text(98),
                            {6, 60, NowDay, 602031, NameStr66, ContentStr66, 1, 1};
                        4 ->
                            NameStr66 = data_marriage_text:get_error_text(94),
                            ContentStr66 = data_marriage_text:get_error_text(99),
                            {6, 90, NowDay, 602031, NameStr66, ContentStr66, 1, 1};
                        5 ->
                            NameStr66 = data_marriage_text:get_error_text(101),
                            ContentStr66 = data_marriage_text:get_error_text(105),
                            {6, 120, NowDay, 602031, NameStr66, ContentStr66, 1, 1};
                        6 ->
                            NameStr66 = data_marriage_text:get_error_text(102),
                            ContentStr66 = data_marriage_text:get_error_text(106),
                            {6, 150, NowDay, 602031, NameStr66, ContentStr66, 1, 1};
                        7 ->
                            NameStr66 = data_marriage_text:get_error_text(103),
                            ContentStr66 = data_marriage_text:get_error_text(107),
                            {6, 180, NowDay, 602031, NameStr66, ContentStr66, 1, 1};
                        8 ->
                            NameStr66 = data_marriage_text:get_error_text(104),
                            ContentStr66 = data_marriage_text:get_error_text(108),
                            {6, 210, NowDay, 602031, NameStr66, ContentStr66, 1, 1};
                        _ ->
                            NameStr66 = data_marriage_text:get_error_text(104),
                            ContentStr66 = data_marriage_text:get_error_text(108),
                            {6, 210, NowDay, 602031, NameStr66, ContentStr66, 1, 0}
                    end,
                    Res = 1,
                    Str = "",
                    Array = [Array1, Array2, Array3, Array4, Array5, Array6]
            end
    end,
    {Res, Str, Array, 15, (ArrayPro1 + ArrayPro2 + ArrayPro3 + ArrayPro4 + ArrayPro5)}.

%% 领取奖励
get_mark_award(Status, TaskId) ->
    case Status#player_status.marriage#status_marriage.register_time of
        %% 未结婚
        0 ->
            Res = 0,
            Str = data_marriage_text:get_error_text(50);
        _ ->
            case db:get_row(io_lib:format(<<"select award_a, award_b, award_c, award_d, award_e, award_day, dun_num, skill_num from marriage_mark where id = ~p limit 1">>, [Status#player_status.id])) of
                %% 获取信息失败
                [] ->
                    Res = 0,
                    Str = data_marriage_text:get_error_text(52);
                %% 成功
                [AwardA, AwardB, AwardC, AwardD, AwardE, AwardDay, DunNum, SkillNum] ->
                    MyId = Status#player_status.id,
                    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
                    RelaNum = lib_relationship:find_xlqy_count(MyId, ParnerId),
                    case TaskId of
                        1 ->
                            %% 夫妻情缘任务
                            Array = case AwardA of
                                0 ->
                                    AwardNum = 9,
                                    {1, 9, RelaNum, 611601};
                                1 ->
                                    AwardNum = 1,
                                    {1, 22, RelaNum, 611602};
                                2 ->
                                    AwardNum = 1,
                                    {1, 99, RelaNum, 611603};
                                _ ->
                                    AwardNum = 1,
                                    {0, 0, 0, 0}
                            end;
                        2 ->
                            %% 夫妻等级
                            MyLv = Status#player_status.lv,
                            [_NickName, _Sex, ParnerLv, _Career, _Realm, _GuildId, _Mount_limit, _HusongNpc, _Image| _] = lib_player:get_player_low_data(ParnerId),
                            MinLv = case MyLv > ParnerLv of
                                true -> ParnerLv;
                                false -> MyLv
                            end,
                            Array = case AwardB of
                                0 ->
                                    AwardNum = 9,
                                    {2, 55, MinLv, 611601};
                                1 ->
                                    AwardNum = 1,
                                    {2, 60, MinLv, 611602};
                                2 ->
                                    AwardNum = 1,
                                    {2, 65, MinLv, 611603};
                                _ ->
                                    AwardNum = 1,
                                    {0, 0, 0, 0}
                            end;
                        3 ->
                            %% 夫妻多人副本
                            Array = case AwardC of
                                0 ->
                                    AwardNum = 9,
                                    {3, 9, DunNum, 611601};
                                1 ->
                                    AwardNum = 1,
                                    {3, 22, DunNum, 611602};
                                2 ->
                                    AwardNum = 1,
                                    {3, 99, DunNum, 611603};
                                _ ->
                                    AwardNum = 1,
                                    {0, 0, 0, 0}
                            end;
                        4 ->
                            %% 夫妻技能
                            Array = case AwardD of
                                0 ->
                                    AwardNum = 9,
                                    {4, 99, SkillNum, 611601};
                                1 ->
                                    AwardNum = 1,
                                    {4, 222, SkillNum, 611602};
                                2 ->
                                    AwardNum = 1,
                                    {4, 999, SkillNum, 611603};
                                _ ->
                                    AwardNum = 1,
                                    {0, 0, 0, 0}
                            end;
                        5 ->
                            %% 夫妻恩爱秀
                            Array = case AwardE of
                                0 ->
                                    FinTaskE = case Status#player_status.marriage#status_marriage.register_time of
                                        0 -> 0;
                                        _ -> 1
                                    end,
                                    AwardNum = 9,
                                    {5, 1, FinTaskE, 611601};
                                1 ->
                                    FinTaskE = case Status#player_status.marriage#status_marriage.wedding_time of
                                        0 -> 0;
                                        _ -> 1
                                    end,
                                    AwardNum = 1,
                                    {5, 1, FinTaskE, 611602};
                                2 ->
                                    FinTaskE = case Status#player_status.marriage#status_marriage.cruise_time of
                                        0 -> 0;
                                        _ -> 1
                                    end,
                                    AwardNum = 1,
                                    {5, 1, FinTaskE, 611603};
                                _ ->
                                    AwardNum = 1,
                                    {0, 0, 0, 0}
                            end;
                        6 ->
                            %% 结婚纪念日
                            RegisterTime = Status#player_status.marriage#status_marriage.register_time,
                            NowDay = (util:unixtime() - RegisterTime) div (24 * 60 * 60),
                            Array = case AwardDay of
                                0 ->
                                    AwardNum = 1,
                                    {6, 7, NowDay, 602031};
                                1 ->
                                    AwardNum = 1,
                                    {6, 15, NowDay, 602031};
                                2 ->
                                    AwardNum = 1,
                                    {6, 30, NowDay, 602031};
                                3 ->
                                    AwardNum = 1,
                                    {6, 60, NowDay, 602031};
                                4 ->
                                    AwardNum = 1,
                                    {6, 90, NowDay, 602031};
                                5 ->
                                    AwardNum = 1,
                                    {6, 120, NowDay, 602031};
                                6 ->
                                    AwardNum = 1,
                                    {6, 150, NowDay, 602031};
                                7 ->
                                    AwardNum = 1,
                                    {6, 180, NowDay, 602031};
                                8 ->
                                    AwardNum = 1,
                                    {6, 210, NowDay, 602031};
                                _ ->
                                    AwardNum = 1,
                                    {0, 0, 0, 0}
                            end
                    end,
                    GoodsPid = Status#player_status.goods#status_goods.goods_pid,
                    %{ok, CellNum} = gen:call(GoodsPid, '$gen_call', {'cell_num'}),
                    CellNum = gen_server:call(GoodsPid, {'cell_num'}),
                    case CellNum =< 0 of
                        %% 背包容量不足
                        true ->
                            Res = 0,
                            Str = data_marriage_text:get_error_text(53);
                        false ->
                            {Type, TotalNumber, NowNumber, AwardId} = Array,
                            case Type of
                                0 ->
                                    Res = 0,
                                    Str = data_marriage_text:get_error_text(55);
                                _ ->
                                    case NowNumber >= TotalNumber of
                                        %% 任务未完成
                                        false ->
                                            Res = 0,
                                            Str = data_marriage_text:get_error_text(54);
                                        true ->
                                            %% 领取日志
                                            spawn(fun() ->
                                                        db:execute(io_lib:format(<<"insert into log_marriage3 set player_id = ~p, task_id = ~p, total_num = ~p, now_num = ~p, award_id = ~p, award_num = ~p, get_time = ~p">>, [Status#player_status.id, Type, TotalNumber, NowNumber, AwardId, AwardNum, util:unixtime()]))
                                                end),
                                            gen:call(GoodsPid, '$gen_call', {'give_more_bind', [], [{AwardId, AwardNum}]}),
                                            case Type of
                                                1 ->
                                                    %% 后台日志（情缘任务日志）
                                                    spawn(fun() ->
                                                                db:execute(io_lib:format(<<"insert into log_marriage1 set type = 4, active_id = ~p, passive_id = ~p, time = ~p, qingyuan_num = ~p">>, [Status#player_status.id, ParnerId, util:unixtime(), RelaNum]))
                                                        end),
                                                    db:execute(io_lib:format(<<"update marriage_mark set award_a = award_a + 1 where id = ~p">>, [Status#player_status.id])),
                                                    NewAwardA = AwardA + 1,
                                                    NewAwardB = AwardB,
                                                    NewAwardC = AwardC,
                                                    NewAwardD = AwardD,
                                                    NewAwardE = AwardE,
                                                    Give = true;
                                                2 ->
                                                    db:execute(io_lib:format(<<"update marriage_mark set award_b = award_b + 1 where id = ~p">>, [Status#player_status.id])),
                                                    NewAwardB = AwardB + 1,
                                                    NewAwardA = AwardA,
                                                    NewAwardC = AwardC,
                                                    NewAwardD = AwardD,
                                                    NewAwardE = AwardE,
                                                    Give = true;
                                                3 ->
                                                    db:execute(io_lib:format(<<"update marriage_mark set award_c = award_c + 1 where id = ~p">>, [Status#player_status.id])),
                                                    NewAwardC = AwardC + 1,
                                                    NewAwardA = AwardA,
                                                    NewAwardB = AwardB,
                                                    NewAwardD = AwardD,
                                                    NewAwardE = AwardE,
                                                    Give = true;
                                                4 ->
                                                    db:execute(io_lib:format(<<"update marriage_mark set award_d = award_d + 1 where id = ~p">>, [Status#player_status.id])),
                                                    NewAwardD = AwardD + 1,
                                                    NewAwardA = AwardA,
                                                    NewAwardB = AwardB,
                                                    NewAwardC = AwardC,
                                                    NewAwardE = AwardE,
                                                    Give = true;
                                                5 ->
                                                    db:execute(io_lib:format(<<"update marriage_mark set award_e = award_e + 1 where id = ~p">>, [Status#player_status.id])),
                                                    NewAwardE = AwardE + 1,
                                                    NewAwardA = AwardA,
                                                    NewAwardB = AwardB,
                                                    NewAwardC = AwardC,
                                                    NewAwardD = AwardD,
                                                    Give = true;
                                                6 ->
                                                    db:execute(io_lib:format(<<"update marriage_mark set award_day = award_day + 1 where id = ~p">>, [Status#player_status.id])),
                                                    NewAwardA = AwardA,
                                                    NewAwardB = AwardB,
                                                    NewAwardC = AwardC,
                                                    NewAwardD = AwardD,
                                                    NewAwardE = AwardE,
                                                    Give = false
                                            end,
                                            %% 发送神仙眷恋称号
                                            AllAwardNum = NewAwardA + NewAwardB + NewAwardC + NewAwardD + NewAwardE,
                                            case AllAwardNum of
                                                15 ->
                                                    case Give of
                                                        true ->
                                                            lib_designation:bind_design_in_server(Status#player_status.id, 201621, "", 0);
                                                        false ->
                                                            skip
                                                    end;
                                                _ ->
                                                    skip
                                            end,
                                            Res = 1,
                                            Str = ""
                                    end
                            end
                    end
            end
    end,
    {Res, Str}.

%% 增加夫妻副本次数
add_dun_num([List, Num]) ->
    case length(List) of
        1 -> 
            [Id1, Id2, Id3] = [0, 0, 0];
        2 -> 
            [Id1, Id2] = List,
            Id3 = 0;
        3 -> 
            [Id1, Id2, Id3] = List;
        _ ->
            List1 = lists:sublist(List, 3),
            [Id1, Id2, Id3] = List1
    end,
    spawn(fun() -> add_dun_num1(Id1, Id2, Id3, Num) end).

add_dun_num1(Id1, Id2, Id3, Num) ->
    _Marriage1 = mod_marriage:get_marry_info(Id1),
    _Marriage2 = mod_marriage:get_marry_info(Id2),
    _Marriage3 = mod_marriage:get_marry_info(Id3),
    Marriage1 = case is_record(_Marriage1, marriage) of
        true -> _Marriage1;
        false -> #marriage{}
    end,
    Marriage2 = case is_record(_Marriage2, marriage) of
        true -> _Marriage2;
        false -> #marriage{}
    end,
    Marriage3 = case is_record(_Marriage3, marriage) of
        true -> _Marriage3;
        false -> #marriage{}
    end,
    %% 判断三人中是否有夫妻
    case Marriage1#marriage.id =:= Marriage2#marriage.id andalso Marriage1#marriage.id =/= 0 of
        false ->
            case Marriage1#marriage.id =:= Marriage3#marriage.id andalso Marriage1#marriage.id =/= 0 of
                false ->
                    case Marriage2#marriage.id =:= Marriage3#marriage.id andalso Marriage2#marriage.id =/= 0 of
                        false ->
                            IdA = Id2,
                            IdB = Id3,
                            MarriageId = 0;
                        true ->
                            IdA = Id2,
                            IdB = Id3,
                            MarriageId = Marriage2#marriage.id
                    end;
                true ->
                    IdA = Id1,
                    IdB = Id3,
                    MarriageId = Marriage1#marriage.id
            end;
        true ->
            IdA = Id1,
            IdB = Id2,
            MarriageId = Marriage1#marriage.id
    end,
    case MarriageId =/= 0 andalso IdA =/= IdB of
        %% 无夫妻
        false -> skip;
        true ->
            F = fun() ->
                    DunNum1 = case db:get_row(io_lib:format(<<"select dun_num from marriage_mark where id = ~p limit 1">>, [IdA])) of
                        [_DunNum1] ->
                            _DunNum1 + Num;
                        _ ->
                            Num
                    end,
                    DunNum2 = case db:get_row(io_lib:format(<<"select dun_num from marriage_mark where id = ~p limit 1">>, [IdB])) of
                        [_DunNum2] ->
                            _DunNum2 + Num;
                        _ ->
                            Num
                    end,
                    DunNum = util:ceil((DunNum1 + DunNum2) / 2),
                    db:execute(io_lib:format(<<"insert into marriage_mark set id = ~p, dun_num = ~p ON DUPLICATE KEY UPDATE dun_num = ~p">>, [IdA, DunNum, DunNum])),
                    db:execute(io_lib:format(<<"insert into marriage_mark set id = ~p, dun_num = ~p ON DUPLICATE KEY UPDATE dun_num = ~p">>, [IdB, DunNum, DunNum]))
            end,
            db:transaction(F)
    end.

%% 增加夫妻共同使用技能次数
add_skill_num(Status) ->
    spawn(fun() -> 
                add_skill_num1(Status)
        end).

add_skill_num1(Status) ->
    case Status#player_status.marriage#status_marriage.register_time of
        %% 未结婚
        0 ->
            skip;
        _ ->
            IdA = Status#player_status.id,
            IdB = Status#player_status.marriage#status_marriage.parner_id,
            F = fun() ->
                    SkillNum1 = case db:get_row(io_lib:format(<<"select skill_num from marriage_mark where id = ~p limit 1">>, [IdA])) of
                        [_SkillNum1] ->
                            _SkillNum1 + 1;
                        _ ->
                            1
                    end,
                    SkillNum2 = case db:get_row(io_lib:format(<<"select skill_num from marriage_mark where id = ~p limit 1">>, [IdB])) of
                        [_SkillNum2] ->
                            _SkillNum2 + 1;
                        _ ->
                            1
                    end,
                    SkillNum = util:ceil((SkillNum1 + SkillNum2) / 2),
                    db:execute(io_lib:format(<<"insert into marriage_mark set id = ~p, skill_num = ~p ON DUPLICATE KEY UPDATE skill_num = ~p">>, [IdA, SkillNum, SkillNum])),
                    db:execute(io_lib:format(<<"insert into marriage_mark set id = ~p, skill_num = ~p ON DUPLICATE KEY UPDATE skill_num = ~p">>, [IdB, SkillNum, SkillNum]))
            end,
            db:transaction(F)
    end.
