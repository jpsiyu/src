%%%------------------------------------
%%% @Module  : lib_marriage
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.24
%%% @Description: 结婚系统
%%%------------------------------------
-module(lib_marriage).
-export([
        is_near_matchmaker/2,
        propose_check/1,
        register_check/1,
        marry/2,
        wedding_check/3,
        wedding/4,
        edit_send/3,
        send/3,
        marriage_guest/3,
        send_email_notice/1,
        send_countdown/1,
        send_countdown2/2,
        send_resttime/1,
        send_resttime2/2,
        enter_wedding/2,
        meet/1,
        finish_meet/1,
        ceremony/1,
        quit_wedding/1,
        changesex/1,
        send_money/4,
        leave_wedding/1,
        login_out/1,
        before_end/1,
        send_all_out/1,
        register_marry/1,
        check_marry_state/1,
        marry_state/1,
        in_3000_task/1,
        task_rela/1,
        login_init_marriage/1,
        login_init_task/1,
        buy_card/2,
        ask_card/1,
        wedding_candies/1,
        candies_drop/3,
        is_in_activity3/0,
        near_by_point/2,
        get_parner_id/1,
        get_divorce_state/1
    ]).
-include("server.hrl").
-include("unite.hrl").
-include("marriage.hrl").
-include("scene.hrl").
-include("appointment.hrl").
-include("guild.hrl").
-include("def_goods.hrl").
-include("drop.hrl").
-include("chat.hrl").
-include("predefine.hrl").

%% 是否在红娘附近
is_near_matchmaker(X, Y) ->
    case (X - 170) * (X - 170) + (Y - 211) * (Y - 211) =< 225 of
        true -> true;
        false -> false
    end.

%% 男方求婚检测
propose_check([Status, Content]) ->
    %% 是否组队状态
    case is_pid(Status#player_status.pid_team) of
        false ->
            NewStatus = Status,
            Res = 2;
        true ->
            %% 只否2人组队
            MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),
            case length(MemberIdList) =:= 2 of
                false ->
                    NewStatus = Status,
                    Res = 2;
                true -> 
                    NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
                    [ParnerId] = NewMemberIdList,
                    %% 必须男方为队长进行求婚
                    case Status#player_status.leader =:= 1 andalso Status#player_status.sex =:= 1 of
                        false ->
                            NewStatus = Status,
                            Res = 3;
                        true ->
                            %% 获取女方信息
                            ParnerStatus = case lib_player:get_player_info(ParnerId) of
                                false -> #player_status{};
                                _Status -> _Status
                            end,
                            %% 必须男女组队
                            ParnerSex = ParnerStatus#player_status.sex,
                            case ParnerSex =:= 2 andalso ParnerId =:= Status#player_status.marriage#status_marriage.parner_id of
                                false ->
                                    NewStatus = Status,
                                    Res = 2;
                                true ->
                                    %% 男女双方必须在红娘范围内
                                    {ParnerX, ParnerY} = {ParnerStatus#player_status.x, ParnerStatus#player_status.y},
                                    case is_near_matchmaker(ParnerX, ParnerY) =:= true andalso is_near_matchmaker(Status#player_status.x, Status#player_status.y) =:= true of
                                        false ->
                                            NewStatus = Status,
                                            Res = 6;
                                        true ->
                                            %% 双方亲密度是否满足
                                            case lib_relationship:find_intimacy(Status#player_status.id, ParnerId) >= 0 of
                                                false ->
                                                    NewStatus = Status,
                                                    Res = 4;
                                                true ->
                                                    %% 男方是否有足够非绑定铜币
                                                    _Coin = 201314,
                                                    DisCut = case is_in_activity3() of
                                                        true -> 0.8;
                                                        false -> 1
                                                    end,
                                                    Coin = round(_Coin * DisCut),
                                                    case Status#player_status.coin >= Coin of
                                                        false -> 
                                                            NewStatus = Status,
                                                            Res = 5;
                                                        true -> 
                                                            %% 男方是否已结婚
                                                            case Status#player_status.marriage#status_marriage.register_time of
                                                                0 ->
                                                                    %% 女方是否已结婚
                                                                    case ParnerStatus#player_status.marriage#status_marriage.register_time of
                                                                        0 ->
                                                                            ParnerLv = ParnerStatus#player_status.lv,
                                                                            %% 40级以上才能结婚
                                                                            case ParnerLv >= 40 andalso Status#player_status.lv >= 40 of
                                                                                false ->
                                                                                    NewStatus = Status,
                                                                                    Res = 9;
                                                                                true ->
                                                                                    %% 得到女方结婚信息
                                                                                    FemaleMarriage = ParnerStatus#player_status.marriage,
                                                                                    MaleMarriage = Status#player_status.marriage,
                                                                                    case marry_state(MaleMarriage) =:= 4 andalso marry_state(FemaleMarriage) =:= 4 of
                                                                                        false ->
                                                                                            NewStatus = Status,
                                                                                            Res = 10;
                                                                                        true ->
                                                                                            %% 求婚成功
                                                                                            NewStatus = Status,
                                                                                            mod_marriage:set_propose([Status#player_status.id, ParnerId]),
                                                                                            %% 通知女方男方求婚
                                                                                            {ok, BinData} = pt_271:write(27111, [Status#player_status.nickname, Content]),
                                                                                            lib_server_send:send_to_uid(ParnerId, BinData),
                                                                                            Res = 1
                                                                                    end
                                                                            end;
                                                                        _ ->
                                                                            NewStatus = Status,
                                                                            Res = 8
                                                                    end;
                                                                _ ->
                                                                    NewStatus = Status,
                                                                    Res = 7
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end,
    {Res, NewStatus}.

%% 女方回应求婚
%% 申请登记检测
%% 女方的Status
register_check(Status) ->
    %% 是否组队状态
    case is_pid(Status#player_status.pid_team) of
        false ->
            NewStatus = Status,
            Res = 2;
        true ->
            %% 只否2人组队
            MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),
            case length(MemberIdList) =:= 2 of
                false ->
                    NewStatus = Status,
                    Res = 2;
                true -> 
                    NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
                    [ParnerId] = NewMemberIdList,
                    %% 必须男方为队长进行预约
                    case Status#player_status.leader =/= 1 andalso Status#player_status.sex =:= 2 of
                        false ->
                            NewStatus = Status,
                            Res = 3;
                        true ->
                            %% 获取男方信息
                            ParnerStatus = case lib_player:get_player_info(ParnerId) of
                                false -> #player_status{};
                                _Status -> _Status
                            end,
                            %% 必须男女组队
                            ParnerSex = ParnerStatus#player_status.sex,
                            case ParnerSex =:= 1 andalso ParnerId =:= Status#player_status.marriage#status_marriage.parner_id of
                                false ->
                                    NewStatus = Status,
                                    Res = 2;
                                true ->
                                    %% 男女双方必须在红娘范围内
                                    {ParnerX, ParnerY} = {ParnerStatus#player_status.x, ParnerStatus#player_status.y},
                                    case is_near_matchmaker(ParnerX, ParnerY) =:= true andalso is_near_matchmaker(Status#player_status.x, Status#player_status.y) =:= true of
                                        false ->
                                            NewStatus = Status,
                                            Res = 6;
                                        true ->
                                            %% 双方亲密度是否满足
                                            QinMi = lib_relationship:find_intimacy(Status#player_status.id, ParnerId),
                                            case QinMi >= 0 of
                                                false ->
                                                    NewStatus = Status,
                                                    Res = 4;
                                                true ->
                                                    %% 男方是否有足够非绑定铜币
                                                    _Coin = 201314,
                                                    DisCut = case is_in_activity3() of
                                                        true -> 0.8;
                                                        false -> 1
                                                    end,
                                                    Coin = round(_Coin * DisCut),
                                                    case ParnerStatus#player_status.coin >= Coin of
                                                        false -> 
                                                            NewStatus = Status,
                                                            Res = 5;
                                                        true -> 
                                                            %% 男方是否已结婚
                                                            case ParnerStatus#player_status.marriage#status_marriage.register_time of
                                                                0 ->
                                                                    %% 女方是否已结婚
                                                                    case Status#player_status.marriage#status_marriage.register_time of
                                                                        0 ->
                                                                            ParnerLv = ParnerStatus#player_status.lv,
                                                                            %% 40级以上才能结婚
                                                                            case ParnerLv >= 40 andalso Status#player_status.lv >= 40 of
                                                                                false ->
                                                                                    NewStatus = Status,
                                                                                    Res = 9;
                                                                                true ->
                                                                                    %% 得到男方结婚信息
                                                                                    FemaleMarriage = ParnerStatus#player_status.marriage,
                                                                                    MaleMarriage = Status#player_status.marriage,
                                                                                    case marry_state(MaleMarriage) =:= 4 andalso marry_state(FemaleMarriage) =:= 4 of
                                                                                        false ->
                                                                                            NewStatus = Status,
                                                                                            Res = 10;
                                                                                        true ->
                                                                                            %% 男方是否求婚
                                                                                            case mod_marriage:get_propose([ParnerId, Status#player_status.id]) of
                                                                                                false ->
                                                                                                    NewStatus = Status,
                                                                                                    Res = 11;
                                                                                                true ->
                                                                                                    %% 后台日志（登记日志）
                                                                                                    spawn(fun() ->
                                                                                                                db:execute(io_lib:format(<<"insert into log_marriage1 set type = 3, active_id = ~p, passive_id = ~p, time = ~p, intimacy = ~p, cost_coin = ~p">>, [ParnerStatus#player_status.id, Status#player_status.id, util:unixtime(), QinMi, Coin]))
                                                                                                        end),
                                                                                                    %% 结婚成功
                                                                                                    lib_player:update_player_info(ParnerId, [{marriage_cost, Coin}]),
                                                                                                    marry(ParnerId, Status#player_status.id),
                                                                                                    %% 结婚发称号
                                                                                                    [_NickName, _Sex, _Lv, _Career, _Realm, _GuildId, _Mount_limit, _HusongNpc, _Image| _] = lib_player:get_player_low_data(ParnerId),
                                                                                                    lib_designation:bind_design_in_server(Status#player_status.id, 201802, binary_to_list(_NickName), 0),
                                                                                                    lib_designation:bind_design_in_server(ParnerId, 201801, Status#player_status.nickname, 0),
                                                                                                    NewStatus = Status#player_status
                                                                                                    {
                                                                                                        marriage = Status#player_status.marriage#status_marriage
                                                                                                        {
                                                                                                            divorce = 0,
                                                                                                            divorce_state = 0
                                                                                                        }
                                                                                                    },
                                                                                                    Res = 1
                                                                                            end
                                                                                    end
                                                                            end;
                                                                        _ ->
                                                                            NewStatus = Status,
                                                                            Res = 8
                                                                    end;
                                                                _ ->
                                                                    NewStatus = Status,
                                                                    Res = 7
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end,
    {Res, NewStatus}.

marry(MaleId, FemaleId) ->
    db:execute(io_lib:format(<<"update marriage set register_time = ~p where male_id = ~p and divorce_time = 0">>, [util:unixtime(), MaleId])),
    mod_marriage:marry(MaleId, FemaleId),
    lib_player:update_player_info(MaleId, [{marriage_marry, util:unixtime()}]),
    lib_player:update_player_info(FemaleId, [{marriage_marry, util:unixtime()}]).

%% 预约婚宴检测
wedding_check(Status, Level, Hour) ->
    _WeddingMarriage = mod_marriage:get_wedding_info(Status#player_status.marriage#status_marriage.id),
    WeddingMarriage = case is_record(_WeddingMarriage, marriage) of
        true -> _WeddingMarriage;
        false -> #marriage{}
    end,
    %% 失败，协议离婚等待中
    case WeddingMarriage#marriage.mark_sure_time > 0 of
        true ->
            NewStatus = Status,
            Res = 11;
        false ->
            %% 7点后是豪华婚礼专场
            case Level =/= 3 andalso Hour >= 19 of
                true ->
                    NewStatus = Status,
                    Res = 9;
                false ->
                    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
                    %% (必须男方进行预约)
                    case Status#player_status.sex =/= 0 of
                        false ->
                            NewStatus = Status,
                            Res = 5;
                        true ->
                            %% 必须已登记才能进行拜堂预约
                            case ParnerId =/= 0 andalso Status#player_status.marriage#status_marriage.register_time =/= 0 of
                                false ->
                                    NewStatus = Status,
                                    Res = 7;
                                true ->
                                    %% 是否已完成拜堂
                                    case db:get_row(io_lib:format(<<"select wedding_time from marriage where male_id = ~p or female_id = ~p and divorce_time = 0 order by id desc limit 1">>, [Status#player_status.id, Status#player_status.id])) of
                                        [] ->
                                            NewStatus = Status,
                                            Res = 7;
                                        [WeddingTime] when WeddingTime =/= 0 ->
                                            NewStatus = Status,
                                            Res = 8;
                                        _ ->
                                            %% 预约的时间点与当前时间点需间隔15分钟
                                            case util:unixdate() + Hour * 3600 - 15 * 60 >= util:unixtime() of
                                                false ->
                                                    NewStatus = Status,
                                                    Res = 2;
                                                true ->
                                                    _NeedGold = case Level of
                                                        1 -> 0;
                                                        2 -> 1314;
                                                        3 -> 3344;
                                                        _ -> 0
                                                    end,
                                                    _NeedCoin = case Level of
                                                        1 -> 299999;
                                                        _ -> 0
                                                    end,
                                                    DisCut = case is_in_activity3() of
                                                        true -> 0.8;
                                                        false -> 1
                                                    end,
                                                    NeedGold = round(_NeedGold * DisCut),
                                                    NeedCoin = round(_NeedCoin * DisCut),
                                                    case Status#player_status.gold >= NeedGold andalso Status#player_status.coin + Status#player_status.bcoin >= NeedCoin of
                                                        false ->
                                                            NewStatus = Status,
                                                            Res = 3;
                                                        true ->
                                                            %% 19、20、21点为豪华婚礼专用时间
                                                            case Level =/= 3 andalso Hour >= 19 of
                                                                true ->
                                                                    NewStatus = Status,
                                                                    Res = 9;
                                                                false ->
                                                                    %% 失败，该时间段已有人预约
                                                                    WeddingTime = util:unixdate() + Hour * 3600,
                                                                    case db:get_row(io_lib:format(<<"select id from marriage where wedding_time = ~p limit 1">>, [WeddingTime])) =:= [] andalso db:get_row(io_lib:format(<<"select id from marriage_item where wedding_time = ~p limit 1">>, [WeddingTime])) =:= [] of
                                                                        false ->
                                                                            NewStatus = Status,
                                                                            Res = 10;
                                                                        true ->
                                                                            %% 预约成功
                                                                            NewStatus1 = lib_goods_util:cost_money(Status, NeedGold, gold),
                                                                            %% 消费接口
                                                                            lib_activity:add_consumption(marryxyan, Status, NeedGold),
                                                                            log:log_consume(wedding, gold, Status, NewStatus1, "wedding cost"),
                                                                            NewStatus = lib_goods_util:cost_money(NewStatus1, NeedCoin, coin),
                                                                            case NewStatus1#player_status.coin =:= NewStatus#player_status.coin of
                                                                                false ->
                                                                                    log:log_consume(wedding, coin, NewStatus1, NewStatus, "wedding cost");
                                                                                true ->
                                                                                    skip
                                                                            end,
                                                                            case NewStatus1#player_status.bcoin =:= NewStatus#player_status.bcoin of
                                                                                false ->
                                                                                    log:log_consume(wedding, bcoin, NewStatus1, NewStatus, "wedding cost");
                                                                                true ->
                                                                                    skip
                                                                            end,
                                                                            case Status#player_status.sex of
                                                                                1 ->
                                                                                    wedding(Status#player_status.id, ParnerId, Level, Hour);
                                                                                _ ->
                                                                                    wedding(ParnerId, Status#player_status.id, Level, Hour)
                                                                            end,
                                                                            %% 邮件发结婚戒指
                                                                            Title = data_marriage_text:get_marriage_text(4),
                                                                            %% 获取相关信息
                                                                            [Realm1, NickName1, Sex1, Career1, Image1] = [Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image],
                                                                            FemaleId = ParnerId,
                                                                            [_NickName2, Sex2, _Lv2, Career2, Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2| _] = lib_player:get_player_low_data(FemaleId),
                                                                            NickName2 = binary_to_list(_NickName2),
                                                                            _ParnarName = NickName2,
                                                                            Content1 = lists:concat([data_marriage_text:get_marriage_text(5), _ParnarName, data_marriage_text:get_marriage_text(6), Level, data_marriage_text:get_marriage_text(7)]),
                                                                            Content2 = lists:concat([data_marriage_text:get_marriage_text(5), Status#player_status.nickname, data_marriage_text:get_marriage_text(6), Level, data_marriage_text:get_marriage_text(7)]),
                                                                            ThingId = case Level of
                                                                                1 -> 107001;
                                                                                2 -> 107002;
                                                                                3 -> 107003;
                                                                                _ -> 107001
                                                                            end,
                                                                            ThingNum = 1,
                                                                            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.id], Title, Content1, ThingId, 2, 0, 0, ThingNum, 0, 0, 0, 0]),
                                                                            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[ParnerId], Title, Content2, ThingId, 2, 0, 0, ThingNum, 0, 0, 0, 0]),
                                                                            lib_player:refresh_client(Status#player_status.id, 2),
                                                                            case Level of
                                                                                1 ->
                                                                                    lib_chat:send_TV({all}, 0, 2, [marry, 3, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour]);
                                                                                2 ->
                                                                                    spawn(fun() -> 
                                                                                                lib_chat:send_TV({all}, 0, 2, [marry, 3, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour]),
                                                                                                timer:sleep(3 * 60 * 1000),
                                                                                                lib_chat:send_TV({all}, 0, 2, [marry, 3, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour])
                                                                                        end);
                                                                                _ ->
                                                                                    spawn(fun() -> 
                                                                                                lib_chat:send_TV({all}, 0, 2, [marry, 3, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour]),
                                                                                                timer:sleep(3 * 60 * 1000),
                                                                                                lib_chat:send_TV({all}, 0, 2, [marry, 3, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour]),
                                                                                                timer:sleep(3 * 60 * 1000),
                                                                                                lib_chat:send_TV({all}, 0, 2, [marry, 3, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour])
                                                                                        end)
                                                                            end,
                                                                            %% 活动
                                                                            lib_marriage_activity:activity_award([Status#player_status.id, ParnerId, Level]),
                                                                            Res = 1
                                                                    end
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end,
    %io:format("Res:~p~n", [Res]),
    {Res, NewStatus}.

wedding(MaleId, FemaleId, Level, Hour) ->
    WeddingTime = util:unixdate() + Hour * 3600,
    lib_player:update_player_info(MaleId, [{marriage_wedding, WeddingTime}]),
    lib_player:update_player_info(FemaleId, [{marriage_wedding, WeddingTime}]),
    WeddingCard = case Level of
        1 -> 10;
        2 -> 20;
        3 -> 30;
        _ -> 10
    end,
    db:execute(io_lib:format(<<"update marriage set wedding_time = ~p, wedding_type = ~p, wedding_card = ~p where male_id = ~p and divorce_time = 0">>, [WeddingTime, Level, WeddingCard, MaleId])),
    mod_marriage:wedding(MaleId, FemaleId, Level, WeddingTime).

%% 编辑喜帖并发送
edit_send(Content, Status, List) ->
    case util:check_length(Content, 255) of
        false -> 
            Res = 3;
        true ->
            case lib_mail:check_content(Content) =/= true of
                true ->
                    Res = 2;
                _ ->
                    put(edit_content, Content),
                    Res = send(Content, Status, List)
            end
    end,
    Res.

%% 发送喜帖检测
send(Content, Status, List) ->
    Marriage = mod_marriage:get_marry_info(Status#player_status.id),
    _Id = Marriage#marriage.id,
    _ParnerId = case Marriage#marriage.male_id =:= Status#player_status.id of
        true -> Marriage#marriage.female_id;
        false -> Marriage#marriage.male_id
    end,
    _WeddingTime = Marriage#marriage.wedding_time,
    _WeddingType = Marriage#marriage.wedding_type,
    _WeddingCard = Marriage#marriage.wedding_card,
    GuestList = mod_marriage:get_my_guest(_Id, Status#player_status.id),
    %io:format("_Id:~p, List:~p, GuestList:~p~n", [_Id, List, GuestList]),
    %% 失败，找不到婚宴
    case _Id of
        0 ->
            Res = 0;
        _ ->
            %% 超过可邀请人数上限
            %io:format("_WeddingCard:~p~n", [_WeddingCard]),
            case length(List) > _WeddingCard - length(GuestList) of
                true ->
                    Res = 5;
                false ->
                    %% 只能在婚宴开始前发送喜帖
                    case _WeddingTime + 30 * 60 > util:unixtime() of
                        false ->
                            Res = 6;
                        true ->
                            [NickName2, _Sex2, _Lv2, _Career2, _Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, _Image2| _] = lib_player:get_player_low_data(_ParnerId),
                            _ParnarName = util:make_sure_list(NickName2),
                            WeddingHour = (_WeddingTime - util:unixdate()) div 3600,
                            Title = data_marriage_text:get_marriage_text(0),
                            case _WeddingType of
                                1 ->
                                    Content1 = lists:concat([data_marriage_text:get_marriage_text(1), Status#player_status.nickname, data_marriage_text:get_marriage_text(12), _ParnarName, data_marriage_text:get_marriage_text(2), WeddingHour, data_marriage_text:get_marriage_text(3)]);
                                _ ->
                                    Content1 = Content
                            end,
                            ThingId = 521001,
                            ThingNum = case _WeddingType of
                                1 -> 2;
                                2 -> 3;
                                3 -> 5;
                                _ -> 2
                            end,
                            List1 = list_deal(List, []),
                            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [List1, Title, Content1, ThingId, 2, 0, 0, ThingNum, 0, 0, 0, 0]),
                            marriage_guest(_Id, List1, Status#player_status.id),
                            Res = 1
                    end
            end
    end,
    Res.

marriage_guest(_MarriageId, [], _InviteId) -> ok;
marriage_guest(MarriageId, [H | T], InviteId) ->
    db:execute(io_lib:format(<<"insert into marriage_guest set marriage_id = ~p, guest_id = ~p, invite_id = ~p">>, [MarriageId, H, InviteId])),
    mod_marriage:insert_guest(MarriageId, H, InviteId),
    marriage_guest(MarriageId, T, InviteId).

%% 给双方发邮件提醒
send_email_notice([]) -> skip;
send_email_notice([H | T]) ->
    case H of
        Marriage when is_record(Marriage, marriage) ->
            _MaleId = Marriage#marriage.male_id,
            _FemaleId = Marriage#marriage.female_id,
            Scale = Marriage#marriage.wedding_type,
            [NickName1, Sex1, _Lv1, Career1, _Realm1, _GuildId1, _Mount_limit1, _HusongNpc1, Image1| _] = lib_player:get_player_low_data(_MaleId),
            [NickName2, Sex2, _Lv2, Career2, _Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2| _] = lib_player:get_player_low_data(_FemaleId),
            MaleMarriage = mod_marriage:get_marry_info(_MaleId),
            FemaleMarriage = mod_marriage:get_marry_info(_FemaleId),

            NewMarriage = Marriage#marriage{male_name = NickName1, female_name = NickName2, male_sex = Sex1, female_sex = Sex2, male_career = Career1, female_career = Career2, male_image = Image1, female_image = Image2},

            NewMaleMarriage = MaleMarriage#marriage{male_name = NickName1, female_name = NickName2, male_sex = Sex1, female_sex = Sex2, male_career = Career1, female_career = Career2, male_image = Image1, female_image = Image2},

            NewFemaleMarriage = FemaleMarriage#marriage{male_name = NickName1, female_name = NickName2, male_sex = Sex1, female_sex = Sex2, male_career = Career1, female_career = Career2, male_image = Image1, female_image = Image2},
            mod_marriage:update_marriage_info(NewMarriage),
            mod_marriage:update_marriage_player(NewMaleMarriage, 1),
            mod_marriage:update_marriage_player(NewFemaleMarriage, 2),
            Title = data_marriage_text:get_marriage_text(10),
            Content = data_marriage_text:get_marriage_text(11),
            lib_mail:send_sys_mail_bg([_MaleId, _FemaleId], Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0),
            lib_chat:send_TV({all}, 1, 2, [marry, 2, _MaleId, _Realm1, binary_to_list(NickName1), Sex1, Career1, Image1, _FemaleId, _Realm2, binary_to_list(NickName2), Sex2, Career2, Image2, Scale]),
            case Scale of
                3 ->
                    MarriageText = case Scale of
                        1 -> data_marriage_text:get_marriage_text(21);
                        2 -> data_marriage_text:get_marriage_text(22);
                        _ -> data_marriage_text:get_marriage_text(23)
                    end,
                    Content2 = lists:concat([binary_to_list(NickName1), data_marriage_text:get_marriage_text(12), binary_to_list(NickName2), data_marriage_text:get_marriage_text(20), MarriageText, data_marriage_text:get_marriage_text(24)]),
                    mod_chat_bugle_call:put_element(#call{
                            id = Marriage#marriage.male_id, 	%% 角色ID
                            nickname = NickName1,	            %% 角色名
                            realm = _Realm1,	                %% 阵营
                            sex = Sex1,		                    %% 性别
                            color = 1,					     	%% 颜色
                            content = Content2,					%% 内容
                            gm = 0,			                    %% GM
                            vip = 0,	                     	%% VIP
                            work = Career1,	                    %% 职业
                            type = 8,							%% 喇叭类型  1飞天号角 2冲天号角 3生日号角 4新婚号角
                            image = Image1,                 	%% 头像ID 
                            channel = 0,                        %% 发送频道 0世界 1场景 2阵营 3帮派 4队伍
                            ringfashion=lib_chat:get_fashionRing(Marriage#marriage.male_id) %%戒指时装
                        });
                _ ->
                    skip
            end;
        _ ->
            skip
    end,
    send_email_notice(T).

%% 开始倒计时
send_countdown([]) -> skip;
send_countdown([H | T]) ->
    case is_record(H, marriage) of
        true->
            _Id = H#marriage.id,
            _WeddingTime = H#marriage.wedding_time,
            MaleId = H#marriage.male_id,
            FemaleId = H#marriage.female_id,
            MaleName = H#marriage.male_name,
            FemaleName = H#marriage.female_name,
            MaleCareer = H#marriage.male_career,
            FemaleCareer = H#marriage.female_career,
            MaleSex = H#marriage.male_sex,
            FemaleSex = H#marriage.female_sex,
            MaleImage = H#marriage.male_image,
            FemaleImage = H#marriage.female_image,
            Scale = H#marriage.wedding_type,
            CountdownTime = _WeddingTime - util:unixtime(),
            CountdownTime1 = case CountdownTime > 0 of
                true -> CountdownTime;
                false -> 0
            end,
            [Num1, Num2] = mod_marriage:get_today_num(H#marriage.register_time, H#marriage.wedding_time),
            {ok, BinData} = pt_271:write(27135, [_Id, CountdownTime1, MaleId, FemaleId, MaleName, FemaleName, MaleCareer, FemaleCareer, MaleSex, FemaleSex, MaleImage, FemaleImage, Scale, Num1, Num2]),
            lib_unite_send:send_to_all(30, 999, BinData);
        _ ->
            skip
    end,
    send_countdown(T). 

%% 开始
send_countdown2([], _Begin) -> skip;
send_countdown2([H | T], Begin) ->
    case is_record(H, marriage) of
        true->
            _Id = H#marriage.id,
            _WeddingTime = H#marriage.wedding_time,
            MaleId = H#marriage.male_id,
            FemaleId = H#marriage.female_id,
            Scale = H#marriage.wedding_type,
            [NickName1, Sex1, _Lv1, Career1, Realm1, _GuildId1, _Mount_limit1, _HusongNpc1, Image1|_] = lib_player:get_player_low_data(MaleId),
            [NickName2, Sex2, _Lv2, Career2, Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2|_] = lib_player:get_player_low_data(FemaleId),
            CountdownTime1 = Begin,
            lib_chat:send_TV({all}, 1, 2, [marry, 1, MaleId, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Scale]),
            [Num1, Num2] = mod_marriage:get_today_num(H#marriage.register_time, H#marriage.wedding_time),
            {ok, BinData} = pt_271:write(27135, [_Id, CountdownTime1, MaleId, Realm1, NickName1, NickName2, Career1, Career2, Sex1, Sex2, Image1, Image2, Scale, Num1, Num2]),
            lib_unite_send:send_to_all(30, 999, BinData),
            case Scale of
                3 ->
                    MarriageText = case Scale of
                        1 -> data_marriage_text:get_marriage_text(21);
                        2 -> data_marriage_text:get_marriage_text(22);
                        _ -> data_marriage_text:get_marriage_text(23)
                    end,
                    Content2 = lists:concat([binary_to_list(NickName1), data_marriage_text:get_marriage_text(12), binary_to_list(NickName2), data_marriage_text:get_marriage_text(20), MarriageText, data_marriage_text:get_marriage_text(25)]),
                    mod_chat_bugle_call:put_element(#call{
                            id = H#marriage.male_id, 	%% 角色ID
                            nickname = NickName1,	            %% 角色名
                            realm = Realm1,	                %% 阵营
                            sex = Sex1,		                    %% 性别
                            color = 1,					     	%% 颜色
                            content = Content2,					%% 内容
                            gm = 0,			                    %% GM
                            vip = 0,	                     	%% VIP
                            work = Career1,	                    %% 职业
                            type = 8,							%% 喇叭类型  1飞天号角 2冲天号角 3生日号角 4新婚号角
                            image = Image1,                 	%% 头像ID 
                            channel = 0,                        %% 发送频道 0世界 1场景 2阵营 3帮派 4队伍
                            ringfashion=lib_chat:get_fashionRing(H#marriage.male_id) %%戒指时装
                        });
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    send_countdown2(T, Begin). 

%% 婚宴剩余时间
send_resttime([]) -> skip;
send_resttime([H | T]) ->
    case is_record(H, marriage) of
        true ->
            _Id = H#marriage.id,
            _WeddingTime = H#marriage.wedding_time,
            MaleId = H#marriage.male_id,
            FemaleId = H#marriage.female_id,
            MaleName = H#marriage.male_name,
            FemaleName = H#marriage.female_name,
            MaleCareer = H#marriage.male_career,
            FemaleCareer = H#marriage.female_career,
            MaleSex = H#marriage.male_sex,
            FemaleSex = H#marriage.female_sex,
            MaleImage = H#marriage.male_image,
            FemaleImage = H#marriage.female_image,
            Scale = H#marriage.wedding_type,
            CountdownTime = _WeddingTime + 30 * 60 - util:unixtime(),
            CountdownTime1 = case CountdownTime > 0 of
                true -> CountdownTime;
                false -> 0
            end,
            [Num1, Num2] = mod_marriage:get_today_num(H#marriage.register_time, H#marriage.wedding_time),
            {ok, BinData} = pt_271:write(27136, [_Id, CountdownTime1, MaleId, FemaleId, MaleName, FemaleName, MaleCareer, FemaleCareer, MaleSex, FemaleSex, MaleImage, FemaleImage, Scale, Num1, Num2]),
            lib_unite_send:send_to_all(30, 999, BinData);
        _ ->
            skip
    end,
    send_resttime(T).

%% 婚宴结束
send_resttime2([], _End) -> skip;
send_resttime2([H | T], End) ->
    case is_record(H, marriage) of
        true ->
            _Id = H#marriage.id,
            _WeddingTime = H#marriage.wedding_time,
            MaleId = H#marriage.male_id,
            FemaleId = H#marriage.female_id,
            MaleName = H#marriage.male_name,
            FemaleName = H#marriage.female_name,
            MaleCareer = H#marriage.male_career,
            FemaleCareer = H#marriage.female_career,
            MaleSex = H#marriage.male_sex,
            FemaleSex = H#marriage.female_sex,
            MaleImage = H#marriage.male_image,
            FemaleImage = H#marriage.female_image,
            Scale = H#marriage.wedding_type,
            CountdownTime1 = End,
            [Num1, Num2] = mod_marriage:get_today_num(H#marriage.register_time, H#marriage.wedding_time),
            {ok, BinData} = pt_271:write(27136, [_Id, CountdownTime1, MaleId, FemaleId, MaleName, FemaleName, MaleCareer, FemaleCareer, MaleSex, FemaleSex, MaleImage, FemaleImage, Scale, Num1, Num2]),
            lib_unite_send:send_to_all(30, 999, BinData);
        _ ->
            skip
    end,
    send_resttime2(T, End).

%% 进入婚礼场景
enter_wedding(Status, WeddingId) ->
    %% 在飞行坐骑上不能进入
    case Status#player_status.mount#status_mount.mount_figure > 0 of
        true ->
            NewStatus = Status,
            MaleId = 0,
            FeMaleId = 0,
            Res = 5;
        false ->
            %% 不能传送的情况
            case lib_player:is_transferable(Status) of
                false ->
                    NewStatus = Status,
                    MaleId = 0,
                    FeMaleId = 0,
                    Res = 0;
                true ->
                    case mod_marriage:get_wedding_info(WeddingId) of
                        %% 不存在该婚礼
                        Marriage when is_record(Marriage, marriage) ->
                            MaleId = Marriage#marriage.male_id,
                            FeMaleId = Marriage#marriage.female_id, 
                            WeddingTime = Marriage#marriage.wedding_time,
                            State = Marriage#marriage.state,
                            case util:unixtime() >= WeddingTime andalso util:unixtime() =< WeddingTime + 30 * 60 of
                                %% 不在婚礼时间内
                                false ->
                                    NewStatus = Status,
                                    Res = 3;
                                true ->
                                    %% 新郎新娘进入
                                    case Status#player_status.id =:= MaleId orelse Status#player_status.id =:= FeMaleId of
                                        true ->
                                            %% 状态控制
                                            ParnerId = case Status#player_status.sex of
                                                1 -> FeMaleId;
                                                _ -> MaleId
                                            end,
                                            {ParnerScene, _ParnerCopyId, _ParnerX, _ParnerY} = case lib_player:get_player_info(ParnerId, position_info) of
                                                false -> {0, 0, 0, 0};
                                                _AnyPos -> _AnyPos
                                            end,
                                            WeddingScene = data_marriage:get_marriage_config(scene_id),
                                            case ParnerScene =:= WeddingScene of
                                                %% 伴侣不在线
                                                false -> 
                                                    %io:format("in1~n"),
                                                    case Status#player_status.sex of
                                                        %% 女的不在线
                                                        1 -> 
                                                            ErrState = case State of
                                                                2 -> 52;
                                                                62 -> 52;
                                                                3 -> 53;
                                                                63 -> 53;
                                                                _ -> 0
                                                            end;
                                                        %% 男的不在线
                                                        _ -> 
                                                            ErrState = case State of
                                                                2 -> 62;
                                                                52 -> 62;
                                                                3 -> 63;
                                                                53 -> 53;
                                                                _ -> 0
                                                            end
                                                    end;
                                                true ->
                                                    %io:format("in2~n"),
                                                    case State of
                                                        52 -> ErrState = 2;
                                                        62 -> ErrState = 2;
                                                        53 -> ErrState = 3;
                                                        63 -> ErrState = 3;
                                                        _ -> ErrState = 0
                                                    end
                                            end,
                                            %io:format("ErrState:~p~n", [ErrState]),
                                            case ErrState of
                                                0 -> skip;
                                                _ ->
                                                    NewMarriage = Marriage#marriage{state = ErrState},
                                                    mod_marriage:update_marriage_info(NewMarriage),
                                                    {ok, BinData2} = pt_271:write(27138, [ErrState]),
                                                    mod_disperse:cast_to_unite(lib_unite_send, send_to_scene, [WeddingScene, 0, BinData2])
                                            end,
                                            %% 记录进入前场景坐标
                                            mod_exit:insert_last_xy(Status#player_status.id, Status#player_status.scene, Status#player_status.x, Status#player_status.y),
                                            SceneId = data_marriage:get_marriage_config(scene_id),
                                            %CopyId = WeddingId,
                                            CopyId = 0,
                                            BeforeState = [1, 2, 52,62],
                                            case lists:member(State, BeforeState) of
                                                true ->
                                                    X = 77,
                                                    Y = 87;
                                                false ->
                                                    RandXY = [{52, 58}, {51, 63}, {59, 54}, {54, 47}, {48, 51}, {59, 63}, {52, 55}],
                                                    Len = length(RandXY),
                                                    Rand = util:rand(1, Len),
                                                    {X, Y} = lists:nth(Rand, RandXY)
                                            end,
                                            lib_scene:player_change_scene(Status#player_status.id, SceneId, CopyId, X, Y, false),
                                            mod_marriage:enter_wedding(WeddingId, Status#player_status.id),
                                            case Status#player_status.mount#status_mount.mount > 0 of
                                                true ->
                                                    case lib_mount:player_get_off_mount(Status) of
                                                        {false, _}->
                                                            NewStatus = Status;
                                                        {ok, mount, NewPlayerStatus} ->
                                                            NewStatus = NewPlayerStatus;
                                                        _ ->
                                                            NewStatus = Status
                                                    end;                                            
                                                false ->
                                                    NewStatus = Status
                                            end,
                                            Res = 1;
                                        false ->
                                            %% 宾客进入
                                            case mod_marriage:get_wedding_guest(WeddingId, Status#player_status.id, MaleId, FeMaleId) of
                                                yes ->
                                                    %% 记录进入前场景坐标
                                                    mod_exit:insert_last_xy(Status#player_status.id, Status#player_status.scene, Status#player_status.x, Status#player_status.y),
                                                    SceneId = data_marriage:get_marriage_config(scene_id),
                                                    %CopyId = WeddingId,
                                                    CopyId = 0,
                                                    BeforeState = [1, 2, 52,62],
                                                    case lists:member(State, BeforeState) of
                                                        true ->
                                                            RandXY = [{71, 88}, {74, 93}, {81, 99}, {91, 99}, {87, 99}, {80, 81}],
                                                            Len = length(RandXY),
                                                            Rand = util:rand(1, Len),
                                                            {X, Y} = lists:nth(Rand, RandXY);
                                                        false ->
                                                            RandXY = [{52, 58}, {51, 63}, {59, 54}, {54, 47}, {48, 51}, {59, 63}, {52, 55}],
                                                            Len = length(RandXY),
                                                            Rand = util:rand(1, Len),
                                                            {X, Y} = lists:nth(Rand, RandXY)
                                                    end,
                                                    lib_scene:player_change_scene(Status#player_status.id, SceneId, CopyId, X, Y, false),
                                                    mod_marriage:enter_wedding(WeddingId, Status#player_status.id),
                                                    case Status#player_status.mount#status_mount.mount > 0 of
                                                        true ->
                                                            case lib_mount:player_get_off_mount(Status) of
                                                                {false, _}->
                                                                    NewStatus = Status;
                                                                {ok, mount, NewPlayerStatus} ->
                                                                    NewStatus = NewPlayerStatus;
                                                                _ ->
                                                                    NewStatus = Status
                                                            end;   
                                                        false ->
                                                            NewStatus = Status
                                                    end,
                                                    Res = 1;
                                                %% 只有邀请宾客才能进入婚礼现场
                                                _ ->
                                                    NewStatus = Status,
                                                    Res = 2
                                            end
                                    end
                            end;
                        _ -> 
                            NewStatus = Status,
                            MaleId = 0,
                            FeMaleId = 0,
                            Res = 4
                    end
            end
    end,
    case MaleId of
        0 ->
            Bin = pack_list(Res, []);
        _ ->
            [NickName1, Sex1, _Lv1, Career1, _Realm1, _GuildId1, _Mount_limit1, _HusongNpc1, Image1|_] = lib_player:get_player_low_data(MaleId),
            [NickName2, Sex2, _Lv2, Career2, _Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2|_] = lib_player:get_player_low_data(FeMaleId),
            Bin = pack_list(Res, [{MaleId, NickName1, Career1, Sex1, Image1}, {FeMaleId, NickName2, Career2, Sex2, Image2}])
    end,
    %io:format("Res:~p~n", [Res]),
    {Bin, NewStatus}.

%% 迎接新娘
meet(Status) ->
    case mod_marriage:get_wedding_info(Status#player_status.marriage#status_marriage.id) of
        Marriage when is_record(Marriage, marriage) ->
            MaleId = Marriage#marriage.male_id,
            FeMaleId = Marriage#marriage.female_id,
            WeddingTime = Marriage#marriage.wedding_time,
            State = Marriage#marriage.state,
            ParnerId = case MaleId =:= Status#player_status.id of
                true -> FeMaleId;
                false -> MaleId
            end,
            %% 不在婚礼时间内
            case util:unixtime() >= WeddingTime andalso util:unixtime() =< WeddingTime + 30 * 60 of
                false ->
                    Res = 3;
                true ->
                    %% 是否男方
                    case Status#player_status.sex of
                        1 ->
                            %% 新娘未进入场景
                            {_Scene, _CopyId, _X, _Y} = case lib_player:get_player_info(ParnerId, position_info) of
                                false -> {0, 0, 0, 0};
                                _Any -> _Any
                            end,
                            WeddingScene = data_marriage:get_marriage_config(scene_id),
                            case _Scene =:= WeddingScene of
                                false ->
                                    Res = 2;
                                true ->
                                    case State =< 2 of
                                        true ->
                                            mod_marriage:meeting(Marriage),
                                            {ok, BinData} = pt_271:write(27138, [2]),
                                            mod_disperse:cast_to_unite(lib_unite_send, send_to_scene, [WeddingScene, 0, BinData]),
                                            lib_scene:player_change_scene(ParnerId, Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y, false),
                                            Res = 1;
                                        false ->
                                            Res = 4
                                    end
                            end;
                        _ ->
                            Res = 0
                    end
            end;
        _ ->
            Res = 0
    end,
    Res.

%% 完成迎接新娘
finish_meet(Status) ->
    case mod_marriage:get_wedding_info(Status#player_status.marriage#status_marriage.id) of
        Marriage when is_record(Marriage, marriage) ->
            MaleId = Marriage#marriage.male_id,
            FeMaleId = Marriage#marriage.female_id,
            WeddingTime = Marriage#marriage.wedding_time,
            State = Marriage#marriage.state,
            ParnerId = case MaleId =:= Status#player_status.id of
                true -> FeMaleId;
                false -> MaleId
            end,
            %% 不在迎接时间内
            case util:unixtime() >= WeddingTime andalso util:unixtime() =< WeddingTime + 30 * 60 of
                false ->
                    Res = 5;
                true ->
                    %% 是否男方
                    case Status#player_status.sex of
                        1 ->
                            %% 新娘未进入场景
                            {_Scene, _CopyId, _X, _Y} = case lib_player:get_player_info(ParnerId, position_info) of
                                false -> {0, 0, 0, 0};
                                _Any -> _Any
                            end,
                            WeddingScene = data_marriage:get_marriage_config(scene_id),
                            case _Scene =:= WeddingScene of
                                false ->
                                    Res = 3;
                                true ->
                                    case State of
                                        2 ->
                                            NewMarriage = Marriage#marriage{state = 3},
                                            mod_marriage:update_marriage_info(NewMarriage),
                                            {ok, BinData} = pt_271:write(27138, [3]),
                                            mod_disperse:cast_to_unite(lib_unite_send, send_to_scene, [WeddingScene, 0, BinData]),
                                            Res = 1;
                                        1 ->
                                            Res = 0;
                                        _ ->
                                            Res = 2
                                    end
                            end;
                        _ ->
                            Res = 4
                    end
            end;
        _ ->
            Res = 0
    end,
    Res.

%% 开始拜堂
ceremony(Status) ->
    case mod_marriage:get_wedding_info(Status#player_status.marriage#status_marriage.id) of
        Marriage when is_record(Marriage, marriage) ->
            MaleId = Marriage#marriage.male_id,
            FemaleId = Marriage#marriage.female_id,
            WeddingTime = Marriage#marriage.wedding_time,
            State = Marriage#marriage.state,
            %% 不在婚礼时间内
            case util:unixtime() >= WeddingTime andalso util:unixtime() =< WeddingTime + 30 * 60 of
                false ->
                    Res = 4;
                true ->
                    %% 只有新郎才能确定拜堂
                    case Status#player_status.id =:= MaleId of
                        false ->
                            Res = 3;
                        true ->
                            %% 新娘不在场景内
                            {_Scene, _CopyId, _X, _Y} = case lib_player:get_player_info(FemaleId, position_info) of
                                false -> {0, 0, 0, 0};
                                _Any -> _Any
                            end,
                            WeddingScene = data_marriage:get_marriage_config(scene_id),
                            case _Scene =:= WeddingScene of
                                false ->
                                    Res = 2;
                                true ->
                                    case State of
                                        4 ->
                                            Res = 7;
                                        _ ->
                                            NewMarriage = Marriage#marriage{state = 4},
                                            mod_marriage:update_marriage_info(NewMarriage),
                                            {ok, BinData} = pt_271:write(27138, [4]),
                                            mod_disperse:cast_to_unite(lib_unite_send, send_to_scene, [WeddingScene, 0, BinData]),
                                            spawn(fun() ->
                                                        timer:sleep(8 * 1000),
                                                        begin_ceremony(Status#player_status.marriage#status_marriage.id)
                                                end),
                                            Res = 1
                                    end
                            end
                    end
            end;
        _ ->
            Res = 0
    end,
    Res.

begin_ceremony(WeddingId) ->
    case mod_marriage:get_wedding_info(WeddingId) of
        Marriage when is_record(Marriage, marriage) ->
            NewMarriage = Marriage#marriage{state = 5},
            mod_marriage:update_marriage_info(NewMarriage),
            {ok, BinData} = pt_271:write(27138, [5]),
            WeddingScene = data_marriage:get_marriage_config(scene_id),
            mod_disperse:cast_to_unite(lib_unite_send, send_to_scene, [WeddingScene, 0, BinData]);
        _ ->
            skip
    end.


%% 退出场景
quit_wedding(Status) ->
    leave_wedding(Status),
    %% 查找用户登录前记录的场景ID和坐标
	[SceneId, X, Y] = case mod_exit:lookup_last_xy(Status#player_status.id) of
        [_SceneId, _X, _Y] -> 
            %%判断，如果不是普通场景和野外场景，则返回长安主城
            case lib_scene:get_data(_SceneId) of
                _S when is_record(_S, ets_scene) ->
                    SceneType = _S#ets_scene.type;
                _ ->
                    SceneType = 8
            end,
            case SceneType =:= ?SCENE_TYPE_NORMAL orelse SceneType =:= ?SCENE_TYPE_OUTSIDE of
                true ->
                    [_SceneId, _X, _Y];
                false -> 
                    {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
                    [?MAIN_CITY_SCENE, MainCityX, MainCityY]
            end;
        _ -> 
            {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
            [?MAIN_CITY_SCENE, MainCityX, MainCityY]
    end,
    lib_scene:player_change_scene(Status#player_status.id, SceneId, 0, X, Y, false).

%% 变性
changesex(Status) ->
    %% 元宝不足
    Gold = 255,
    case Status#player_status.gold < Gold of
        true ->
            NewId = 0,
            NewStatus = Status,
            Res = 4;
        false ->
            %% 已结婚玩家不可变性
            case Status#player_status.marriage#status_marriage.register_time =:= 0 of
                false ->
                    NewId = 0,
                    NewStatus = Status,
                    Res = 3;
                true ->
                    %% 领取了结婚申请任务的玩家不可变性
                    case Status#player_status.marriage#status_marriage.parner_id =:= 0 of
                        false ->
                            NewId = 0,
                            NewStatus = Status,
                            Res = 2;
                        true ->
                            %% 仙侣情缘任务中不可变性
                            R = mod_disperse:call_to_unite(lib_appointment, get_appointment_config, [Status#player_status.id]),
                            if
                                is_record(R, ets_appointment_config) andalso R#ets_appointment_config.now_partner_id =/= 0 ->
                                    NewId = 0,
                                    NewStatus = Status,
                                    Res = 5;
                                true ->
                                    %% 组队中不可变性
                                    case is_pid(Status#player_status.pid_team) of
                                        true -> 
                                            NewId = 0,
                                            NewStatus = Status,
                                            Res = 6;
                                        false ->
                                            %% 修改武器
                                            case mod_other_call:equip_change_sex(Status) of
                                                {ok, NewId} -> 
                                                    %% 变性成功
                                                    NewStatus1 = lib_goods_util:cost_money(Status, Gold, gold),
                                                    NowSex = NewStatus1#player_status.sex,
                                                    ChangeSex = case NowSex of
                                                        1 -> 2;
                                                        _ -> 1
                                                    end,
                                                    %% 公共线性别
                                                    lib_player_unite:update_unite_info(Status#player_status.id, [{sex, ChangeSex}]),
                                                    NewGoods = NewStatus1#player_status.goods,
                                                    [_Weapon | OtherEquip] = NewGoods#status_goods.equip_current,
                                                    NewEquip = [NewId | OtherEquip],
                                                    NewStatus2 = NewStatus1#player_status{sex = ChangeSex, goods = NewGoods#status_goods{equip_current = NewEquip}},
                                                    log:log_consume(change_sex, gold, Status, NewStatus2, "change sex"),
                                                    lib_player:refresh_client(Status#player_status.id, 2),
                                                    %% 清情缘次数
                                                    if
                                                        is_record(R, ets_appointment_config) ->
                                                                R1 = R#ets_appointment_config{
                                                                last_partner_id = 0,
                                                                rand_ids = [],
                                                                recommend_partner = [],
                                                                mark = []
                                                            },
                                                            mod_disperse:cast_to_unite(lib_appointment, update_appointment_config, [R1, 0]);
                                                        true ->
                                                            skip
                                                    end,
                                                    %% 修改人物属性
                                                    db:execute(io_lib:format(<<"update player_low set sex = ~p where id = ~p">>, [ChangeSex, Status#player_status.id])),
                                                    {ok, BinData} = pt_120:write(12003, NewStatus2),
                                                    lib_server_send:send_to_area_scene(NewStatus2#player_status.scene, NewStatus2#player_status.copy_id, NewStatus2#player_status.x, NewStatus2#player_status.y, BinData),
                                                    mod_scene_agent:update(changesex, NewStatus2),
                                                    NewGo = NewStatus2#player_status.goods,
                                                    Mount = NewStatus2#player_status.mount,
                                                    {ok, BinData1} = pt_120:write(12012, [NewStatus2#player_status.id, NewStatus2#player_status.platform, NewStatus2#player_status.server_num, 
                                                            NewGo#status_goods.equip_current, 
                                                            NewGo#status_goods.stren7_num, 
                                                            NewGo#status_goods.suit_id, 
                                                            NewStatus2#player_status.hp, 
                                                            NewStatus2#player_status.hp_lim, 
                                                            NewGo#status_goods.fashion_weapon,
                                                            NewGo#status_goods.fashion_armor, 
                                                            NewGo#status_goods.fashion_accessory, 
                                                            NewGo#status_goods.hide_fashion_weapon, 
                                                            NewGo#status_goods.hide_fashion_armor, 
                                                            NewGo#status_goods.hide_fashion_accessory, 
                                                            Mount#status_mount.mount_figure,
                                                            NewGo#status_goods.hide_head,
                                                            NewGo#status_goods.hide_tail,
                                                            NewGo#status_goods.hide_ring,
                                                            NewGo#status_goods.fashion_head,
                                                            NewGo#status_goods.fashion_tail,
                                                            NewGo#status_goods.fashion_ring]),
                                                    lib_server_send:send_to_area_scene(NewStatus2#player_status.scene, 
                                                        NewStatus2#player_status.copy_id,
                                                        NewStatus2#player_status.x, 
                                                        NewStatus2#player_status.y, BinData1),
                                                    ChangeTo = case Status#player_status.sex of
                                                        1 -> 2;
                                                        _ -> 1
                                                    end,
                                                    %% 传闻
                                                    lib_chat:send_TV({all}, 0, 2, [changeSex, ChangeTo, Status#player_status.id, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image]),
                                                    %% 排行榜
                                                    mod_disperse:cast_to_unite(mod_rank, change_sex, [NewStatus2#player_status.id, NewStatus2#player_status.sex]),
                                                    %% 修改好友信息
                                                    mod_disperse:cast_to_unite(lib_relationship, update_user_rela_info, [NewStatus2#player_status.id, NewStatus2#player_status.lv, NewStatus2#player_status.vip#status_vip.vip_type, NewStatus2#player_status.nickname, NewStatus2#player_status.sex, NewStatus2#player_status.realm, NewStatus2#player_status.career, 1, NewStatus2#player_status.scene, NewStatus2#player_status.last_login_time, NewStatus2#player_status.image, NewStatus2#player_status.longitude, NewStatus2#player_status.latiude]),
                                                    %% 修改帮派成员信息
                                                    case Status#player_status.guild#status_guild.guild_id of
                                                        %% 未加入帮派
                                                        0 ->
                                                            skip;
                                                        _ ->
                                                            case catch mod_disperse:call_to_unite(lib_guild_base, get_guild_member_by_player_id, [Status#player_status.id]) of
                                                                %% 成功
                                                                GuildMemberInfo when is_record(GuildMemberInfo, ets_guild_member) ->
                                                                    NewGuildMemberInfo = GuildMemberInfo#ets_guild_member{
                                                                        sex = ChangeSex
                                                                    },
                                                                    mod_disperse:cast_to_unite(lib_guild_base, update_guild_member, [NewGuildMemberInfo]);
                                                                %% 获取帮派成员信息失败
                                                                _OtherError ->
                                                                    skip
                                                            end
                                                    end,
                                                    Res = 1,
                                                    NewStatus = NewStatus2;
                                                _ ->
                                                    NewId = 0,
                                                    Res = 7,
                                                    NewStatus = Status
                                            end
                                    end
                            end
                    end
            end
    end,
    {Res, NewStatus, NewId}.

list_deal([], L) -> L;
list_deal([{H} | T], L) ->
    list_deal(T, [H | L]).

pack_list(Res, List) ->
    %% List1
    Fun1 = fun(Elem1) ->
            {Id, NickName, Career, Sex, Image} = Elem1,
            NickName1 = NickName,
            LenNickName = byte_size(NickName1),
            <<Id:32, LenNickName:16, NickName1/binary, Career:8, Sex:8, Image:32>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List]),
    Size1  = length(List),
    <<Res:8, Size1:16, BinList1/binary>>.

%% 赠送贺礼
send_money(Status, WeddingId, Type, To) ->
    case Type of
        1 ->
            MonType = coin,
            Money = 10000;
        2 ->
            MonType = coin,
            Money = 20000;
        3 ->
            MonType = coin,
            Money = 50000;
        4 ->
            MonType = gold,
            Money = 27;
        5 ->
            MonType = gold,
            Money = 199;
        6 ->
            MonType = gold,
            Money = 999;
        _ ->
            MonType = gold,
            Money = 99999999
    end,
    case MonType of
        coin ->
            case Status#player_status.coin < Money of
                %% 铜币不足
                true -> 
                    NewStatus = Status,
                    Res = 2;
                false ->
                    Marriage = mod_marriage:get_wedding_info(WeddingId),
                    case is_record(Marriage, marriage) of
                        false ->
                            NewStatus = Status,
                            Res = 0;
                        true ->
                            case To of
                                1 ->
                                    NewStatus = lib_goods_util:cost_money(Status, Money, rcoin),
                                    log:log_consume(wedding_bless, coin, Status, NewStatus, "wedding bless"),
                                    MaleCoin = Marriage#marriage.male_coin,
                                    NewMarriage = Marriage#marriage{male_coin = MaleCoin + Money},
                                    mod_marriage:update_marriage_info(NewMarriage),
                                    Title = data_marriage_text:get_marriage_text(15),
                                    Content = lists:concat([data_marriage_text:get_marriage_text(16), Status#player_status.nickname, data_marriage_text:get_marriage_text(17), Money, data_marriage_text:get_marriage_text(18)]),
                                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Marriage#marriage.male_id], Title, Content, 0, 0, 0, 0, 0, 0, Money, 0, 0]),
                                    {ok, BinData} = pt_271:write(27143, [NewMarriage#marriage.male_coin, NewMarriage#marriage.male_gold, NewMarriage#marriage.female_coin, NewMarriage#marriage.female_gold, Status#player_status.nickname, Money, 0, To]);
                                _ ->
                                    NewStatus = lib_goods_util:cost_money(Status, Money, rcoin),
                                    log:log_consume(wedding_bless, coin, Status, NewStatus, "wedding bless"),
                                    FemaleCoin = Marriage#marriage.female_coin,
                                    NewMarriage = Marriage#marriage{female_coin = FemaleCoin + Money},
                                    mod_marriage:update_marriage_info(NewMarriage),
                                    Title = data_marriage_text:get_marriage_text(15),
                                    Content = lists:concat([data_marriage_text:get_marriage_text(16), Status#player_status.nickname, data_marriage_text:get_marriage_text(17), Money, data_marriage_text:get_marriage_text(18)]),
                                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Marriage#marriage.female_id], Title, Content, 0, 0, 0, 0, 0, 0, Money, 0, 0]),
                                    {ok, BinData} = pt_271:write(27143, [NewMarriage#marriage.male_coin, NewMarriage#marriage.male_gold, NewMarriage#marriage.female_coin, NewMarriage#marriage.female_gold, Status#player_status.nickname, Money, 0, To])
                            end,
                            WeddingSceneId = data_marriage:get_marriage_config(scene_id),
                            mod_disperse:cast_to_unite(lib_unite_send, send_to_scene, [WeddingSceneId, 0, BinData]),
                            case Status#player_status.scene =:= WeddingSceneId of
                                false ->
                                    mod_disperse:cast_to_unite(lib_unite_send, send_to_uid, [Status#player_status.id, BinData]);
                                true ->
                                    skip
                            end,
                            lib_player:refresh_client(Status#player_status.id, 2),
                            Res = 1
                    end
            end;
        _ ->
            case Status#player_status.gold < Money of
                %% 元宝不足
                true ->
                    NewStatus = Status,
                    Res = 3;
                false ->
                    Marriage = mod_marriage:get_wedding_info(WeddingId),
                    case is_record(Marriage, marriage) of
                        false ->
                            NewStatus = Status,
                            Res = 0;
                        true ->
                            Flower = case Money of
                                27 -> 9;
                                199 -> 99;
                                _ -> 999
                            end,
                            case To of
                                1 ->
                                    NewStatus = lib_goods_util:cost_money(Status, Money, gold),
                                    log:log_consume(wedding_bless, gold, Status, NewStatus, "wedding bless"),
                                    MaleGold = Marriage#marriage.male_gold,
                                    NewMarriage = Marriage#marriage{male_gold = MaleGold + Flower},
                                    mod_marriage:update_marriage_info(NewMarriage),
                                    Title = data_marriage_text:get_marriage_text(15),
                                    Content = lists:concat([data_marriage_text:get_marriage_text(16), Status#player_status.nickname, data_marriage_text:get_marriage_text(17), Flower, data_marriage_text:get_marriage_text(19)]),
                                    case Flower of
                                        9 ->
                                            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Marriage#marriage.male_id], Title, Content, 611601, 2, 0, 0, 9, 0, 0, 0, 0]);
                                        99 ->
                                            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Marriage#marriage.male_id], Title, Content, 611602, 2, 0, 0, 1, 0, 0, 0, 0]);
                                        _ ->
                                            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Marriage#marriage.male_id], Title, Content, 611603, 2, 0, 0, 1, 0, 0, 0, 0])
                                    end,
                                    {ok, BinData} = pt_271:write(27143, [NewMarriage#marriage.male_coin, NewMarriage#marriage.male_gold, NewMarriage#marriage.female_coin, NewMarriage#marriage.female_gold, Status#player_status.nickname, 0, Flower, To]);
                                _ ->
                                    NewStatus = lib_goods_util:cost_money(Status, Money, gold),
                                    log:log_consume(wedding_bless, gold, Status, NewStatus, "wedding bless"),
                                    FemaleGold = Marriage#marriage.female_gold,
                                    NewMarriage = Marriage#marriage{female_gold = FemaleGold + Flower},
                                    mod_marriage:update_marriage_info(NewMarriage),
                                    Title = data_marriage_text:get_marriage_text(15),
                                    Content = lists:concat([data_marriage_text:get_marriage_text(16), Status#player_status.nickname, data_marriage_text:get_marriage_text(17), Flower, data_marriage_text:get_marriage_text(19)]),
                                    case Flower of
                                        9 ->
                                            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Marriage#marriage.female_id], Title, Content, 611601, 2, 0, 0, 9, 0, 0, 0, 0]);
                                        99 ->
                                            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Marriage#marriage.female_id], Title, Content, 611602, 2, 0, 0, 1, 0, 0, 0, 0]);
                                        _ ->
                                            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Marriage#marriage.female_id], Title, Content, 611603, 2, 0, 0, 1, 0, 0, 0, 0])
                                    end,
                                    {ok, BinData} = pt_271:write(27143, [NewMarriage#marriage.male_coin, NewMarriage#marriage.male_gold, NewMarriage#marriage.female_coin, NewMarriage#marriage.female_gold, Status#player_status.nickname, 0, Flower, To])
                            end,
                            WeddingSceneId = data_marriage:get_marriage_config(scene_id),
                            mod_disperse:cast_to_unite(lib_unite_send, send_to_scene, [WeddingSceneId, 0, BinData]),
                            case Status#player_status.scene =:= WeddingSceneId of
                                false ->
                                    mod_disperse:cast_to_unite(lib_unite_send, send_to_uid, [Status#player_status.id, BinData]);
                                true ->
                                    skip
                            end,
                            lib_player:refresh_client(Status#player_status.id, 2),
                            Res = 1
                    end
            end
    end,
    {Res, NewStatus}.

%% 离开结婚场景
leave_wedding(Status) ->
    %% 是否在结婚场景
    mod_marriage:quit_wedding(Status#player_status.id),
    WeddingScene = data_marriage:get_marriage_config(scene_id),
    case Status#player_status.scene of
        WeddingScene ->
            %% 是否是婚礼新人
            Marriage = mod_marriage:get_wedding_info(Status#player_status.marriage#status_marriage.id),
            case is_record(Marriage, marriage) of
                true ->
                    %% 判断从哪种状态进入哪种状态
                    LeaveState = case Marriage#marriage.state of
                        2 ->
                            case Status#player_status.sex of
                                1 -> 62;
                                2 -> 52;
                                _ -> 0
                            end;
                        3 ->
                            case Status#player_status.sex of
                                1 -> 63;
                                2 -> 53;
                                _ -> 0
                            end;
                        _ -> 0
                    end,
                    %io:format("LeaveState:~p~n", [LeaveState]),
                    case LeaveState of
                        0 -> 
                            skip;
                        _ ->
                            NewMarriage = Marriage#marriage{state = LeaveState},
                            mod_marriage:update_marriage_info(NewMarriage),
                            {ok, BinData2} = pt_271:write(27138, [LeaveState]),
                            mod_disperse:cast_to_unite(lib_unite_send, send_to_scene, [WeddingScene, 0, BinData2])
                    end;
                false -> 
                    skip
            end;
        _ -> 
            skip
    end.

%% 登录退出
login_out(Status) ->
    MarriageId = data_marriage:get_marriage_config(scene_id),
    case Status#player_status.scene =:= MarriageId of
        true -> 
            {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
            Status#player_status{scene = ?MAIN_CITY_SCENE, x = MainCityX, y = MainCityY};
        false -> Status
    end.

%% 结束前5分钟处理
before_end([]) -> skip;
before_end([H | T]) ->
    case H of
        Marriage when is_record(Marriage, marriage) ->
            Id = Marriage#marriage.id,
            MaleId = Marriage#marriage.male_id,
            FemaleId = Marriage#marriage.female_id,
            State = Marriage#marriage.state,
            SceneId = data_marriage:get_marriage_config(scene_id),
            case State of 
                4 -> 
                    %io:format("before1~n"),
                    skip;
                5 ->
                    skip;
                _ ->
                    case mod_marriage:is_in_wedding(Id, MaleId) of 
                        true ->
                            case mod_marriage:is_in_wedding(Id, FemaleId) of
                                %% 自动拜堂
                                true ->
                                    %io:format("before2~n"),
                                    lib_scene:player_change_scene(MaleId, SceneId, 0, 40, 45, false),
                                    lib_scene:player_change_scene(FemaleId, SceneId, 0, 41, 43, false),
                                    NewMarriage = Marriage#marriage{state = 4},
                                    mod_marriage:update_marriage_info(NewMarriage),
                                    {ok, BinData} = pt_271:write(27138, [4]),
                                    lib_unite_send:send_to_scene(SceneId, 0, BinData),
                                    spawn(fun() ->
                                                timer:sleep(8 * 1000),
                                                begin_ceremony(Id)
                                        end);
                                %% 新娘逃婚
                                false ->
                                    %io:format("before3~n"),
                                    NewMarriage = Marriage#marriage{state = 53},
                                    mod_marriage:update_marriage_info(NewMarriage),
                                    {ok, BinData} = pt_271:write(27138, [53]),
                                    lib_unite_send:send_to_scene(SceneId, 0, BinData)
                            end;
                        %% 新郎逃婚
                        false ->
                            %io:format("before4~n"),
                            NewMarriage = Marriage#marriage{state = 63},
                            mod_marriage:update_marriage_info(NewMarriage),
                            {ok, BinData} = pt_271:write(27138, [63]),
                            lib_unite_send:send_to_scene(SceneId, 0, BinData)
                    end
            end;
        _ ->
            skip
    end,
    before_end(T).

%% 全部传送走
send_all_out([]) -> skip;
send_all_out([H | T]) ->
    case H of
        Marriage when is_record(Marriage, marriage) ->
            Id = Marriage#marriage.id,
            AllId = mod_marriage:all_in_wedding(Id),
            %% 检测气氛值
            mod_marriage:check_mood([Marriage#marriage.male_id, Marriage#marriage.female_id]),
            send_out(AllId);
        _ ->
            skip
    end,
    send_all_out(T).

send_out([]) -> skip;
send_out([H | T]) ->
    mod_marriage:quit_wedding(H),
    {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
    lib_scene:player_change_scene(H, ?MAIN_CITY_SCENE, 0, MainCityX, MainCityY, false),
    send_out(T).

%%has_wedding([], _Hour) -> false;
%%has_wedding([H | T], Hour) ->
%%    WeddingTime = util:unixdate() + Hour * 3600,
%%    case H#marriage.wedding_time =:= WeddingTime of
%%        true -> true;
%%        false -> has_wedding(T, Hour)
%%    end.

%% 返回结婚状态
%% 0.未申请结婚
%% 1.已申请结婚，未接受任务
%% 2.正在做情缘任务
%% 3.正在做情比金坚任务
%% 4.已满足登记条件
%% 5.已完成登记，未举办婚宴
%% 6.已预约婚宴
%% 7.正在举办婚宴
%% 8.正在巡游
%% 9.已完成婚宴，未巡游
%% 10.已完成巡游，未办婚宴
%% 11.已完成婚宴，已巡游
%% 12.已预约巡游
marry_state(StatusMarriage) when is_record(StatusMarriage, status_marriage) ->
    Task = StatusMarriage#status_marriage.task,
    _Marriage = mod_marriage:get_wedding_info(StatusMarriage#status_marriage.id),
    Marriage = case is_record(_Marriage, marriage) of
        true -> _Marriage;
        false -> #marriage{}
    end,
    case StatusMarriage#status_marriage.id of
        %% 未申请结婚
        0 -> 0;
        %% 已申请结婚
        _ ->
            case Marriage#marriage.register_time of
                %% 未登记
                0 -> 
                    case Task#marriage_task.finish_task of
                        0 -> 
                            case Task#marriage_task.task_type of
                                %% 已申请结婚，未接受任务
                                0 -> 1;
                                %% 正在做情缘任务
                                1 -> 2;
                                %% 正在做情比金坚任务
                                _ -> 3
                            end;
                        %% 已满足登记条件
                        _ -> 4
                    end;
                %% 已登记
                _ -> 
                    NowTime = util:unixtime(),
                    case Marriage#marriage.cruise_time of
                        %% 未巡游
                        0 -> 
                            case Marriage#marriage.wedding_time of
                                %% 未举办婚宴
                                0 -> 5;
                                _WeddingTime ->
                                    case NowTime < _WeddingTime of
                                        %% 已预约婚宴
                                        true -> 6;
                                        false ->
                                            %% 正在举办婚宴
                                            case NowTime >= _WeddingTime andalso NowTime =< _WeddingTime + 30 * 60 of
                                                true -> 7;
                                                %% 已完成婚宴，未巡游
                                                false -> 9
                                            end
                                    end
                            end;
                        %% 已巡游
                        _CruiseTime ->
                            case NowTime < Marriage#marriage.wedding_time + 30 * 60 of 
                                %% 是否用道具预约喜宴
                                true ->
                                    case NowTime < Marriage#marriage.wedding_time of
                                        true -> 
                                            %% 喜宴和巡游一起预约
                                            case NowTime > _CruiseTime + 30 * 60 of
                                                %% 已预约婚宴(巡游已结束)
                                                true -> 6;
                                                false ->
                                                    case NowTime < _CruiseTime of
                                                        %% 已预约巡游
                                                        true -> 12;
                                                        %% 正在巡游
                                                        false -> 
                                                            case Marriage#marriage.cruise_state of
                                                                %% 已巡游
                                                                3 -> 11;
                                                                %% 正在巡游
                                                                2 -> 8;
                                                                %% 已预约巡游
                                                                _ -> 12
                                                            end
                                                    end
                                            end;
                                        %% 正在举办婚宴
                                        false -> 7
                                    end;
                                %% 巡游
                                false ->
                                    case NowTime > _CruiseTime of
                                        %% 已预约巡游
                                        false -> 
                                            12;
                                        true ->
                                            case NowTime =< _CruiseTime + 30 * 60 of
                                                %% 已完成婚宴，已巡游
                                                false -> 11;
                                                true ->
                                                    case Marriage#marriage.cruise_state of
                                                        %% 已巡游
                                                        3 -> 11;
                                                        %% 正在巡游
                                                        2 -> 8;
                                                        %% 已预约巡游
                                                        _ -> 12
                                                    end
                                            end
                                    end
                            end
                    end
                    
            end
    end.

%% 申请结婚(998做情缘任务，3000做情比金坚任务，6000可以直接登记)
register_marry(Status) ->
    %% 必须男女组队申请
    case is_pid(Status#player_status.pid_team) of
        false ->
            Res = 2;
        true ->
            %% 只否2人组队
            MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),
            case length(MemberIdList) =:= 2 of
                false ->
                    Res = 2;
                true -> 
                    NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
                    [ParnerId] = NewMemberIdList,
                    %% 必须男方为队长进行申请
                    case Status#player_status.leader =:= 1 andalso Status#player_status.sex =:= 1 of
                        false ->
                            Res = 3;
                        true ->
                            %% 获取女方信息
                            ParnerStatus = case lib_player:get_player_info(ParnerId) of
                                false -> #player_status{};
                                _Status -> _Status
                            end,
                            %% 必须男女组队
                            ParnerSex = ParnerStatus#player_status.sex,
                            case ParnerSex =:= Status#player_status.sex of
                                true ->
                                    Res = 2;
                                false ->
                                    %% 男女双方必须在红娘范围内
                                    {ParnerX, ParnerY} = {ParnerStatus#player_status.x, ParnerStatus#player_status.y},
                                    case is_near_matchmaker(ParnerX, ParnerY) =:= true andalso is_near_matchmaker(Status#player_status.x, Status#player_status.y) =:= true of
                                        false ->
                                            Res = 5;
                                        true ->
                                            %% 40级以上才能申请结婚
                                            ParnerLv = ParnerStatus#player_status.lv,
                                            case ParnerLv >= 40 andalso Status#player_status.lv >= 40 of
                                                false ->
                                                    Res = 8;
                                                true ->
                                                    %% 亲密度不足
                                                    QinMi = lib_relationship:find_intimacy(Status#player_status.id, ParnerId),
                                                    case QinMi >= 998 of
                                                        false ->
                                                            Res = 4;
                                                        true ->
                                                            case Status#player_status.marriage#status_marriage.parner_id of
                                                                0 ->
                                                                    %% 得到女方结婚信息
                                                                    FemaleMarriage = ParnerStatus#player_status.marriage,
                                                                    MaleMarriage = Status#player_status.marriage,
                                                                    case FemaleMarriage#status_marriage.id =:= MaleMarriage#status_marriage.id of
                                                                        true ->
                                                                            %% 不能重复申请
                                                                            case marry_state(Status#player_status.marriage) =:= 0 andalso marry_state(FemaleMarriage) =:= 0 of
                                                                                false ->
                                                                                    Res = 9;
                                                                                true ->
                                                                                    %% 后台日志（申请日志）
                                                                                    spawn(fun() ->
                                                                                                db:execute(io_lib:format(<<"insert into log_marriage1 set type = 1, active_id = ~p, passive_id = ~p, time = ~p, intimacy = ~p">>, [Status#player_status.id, ParnerId, util:unixtime(), QinMi]))
                                                                                        end),
                                                                                    %% 成功申请结婚
                                                                                    MaleId = Status#player_status.id,
                                                                                    MaleName = Status#player_status.nickname,
                                                                                    FemaleId = ParnerId,
                                                                                    FemaleName = ParnerStatus#player_status.nickname,
                                                                                    MyTask = mod_marriage:apply_marry([MaleId, FemaleId]),
                                                                                    case is_record(MyTask, marriage_task) of
                                                                                        true ->
                                                                                            lib_player:update_player_info(MaleId, [{marriage, MaleMarriage#status_marriage{id = MyTask#marriage_task.id, parner_id = FemaleId, parner_name = FemaleName, task = MyTask}}]),
                                                                                            lib_player:update_player_info(FemaleId, [{marriage, FemaleMarriage#status_marriage{id = MyTask#marriage_task.id, parner_id = MaleId, parner_name = MaleName, task = MyTask}}]),
                                                                                            Res = 1;
                                                                                        false ->
                                                                                            case MyTask of
                                                                                                nomale ->
                                                                                                    Res = 6;
                                                                                                nofemale ->
                                                                                                    Res = 7;
                                                                                                _ ->
                                                                                                    Res = 0
                                                                                            end
                                                                                    end
                                                                            end;
                                                                        %% 女方已结婚
                                                                        false ->
                                                                            Res = 7
                                                                    end;
                                                                %% 男方已结婚
                                                                _ ->
                                                                    Res = 6
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end,
    Res.

%% 查看结婚进度
check_marry_state(Status) ->
    Marriage = Status#player_status.marriage,
    MarriageState = marry_state(Marriage),
    Task = Marriage#status_marriage.task,
    ParnerId = Marriage#status_marriage.parner_id,
    AppNow = lib_relationship:find_xlqy_count(Status#player_status.id, ParnerId),
    AppNeed = case MarriageState of
        2 -> 22;
        _ -> 11
    end,
    {MarriageState, AppNow, AppNeed, Task#marriage_task.task_flag}.

in_3000_task(Status) ->
    case marry_state(Status#player_status.marriage) =:= 3 andalso Status#player_status.marriage#status_marriage.task#marriage_task.task_flag =/= 4 of
        true -> true;
        false -> false
    end.

%% 任务
task_rela(Status) ->
    %% 必须男女组队申请
    case is_pid(Status#player_status.pid_team) of
        false ->
            Rela = 0,
            Res = 2;
        true ->
            %% 只否2人组队
            MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),
            case length(MemberIdList) =:= 2 of
                false ->
                    Rela = 0,
                    Res = 2;
                true -> 
                    NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
                    [ParnerId] = NewMemberIdList,
                    Rela = lib_relationship:find_intimacy(Status#player_status.id, ParnerId),
                    Res = 1
            end
    end,
    {Res, Rela}.

login_init_marriage(Info) ->
    [PlayerId, PlayerSex] = Info,
    case PlayerSex of
        1 ->
            case db:get_row(io_lib:format(<<"select id, male_id, female_id, register_time, wedding_time, wedding_type, wedding_card from marriage where male_id = ~p and divorce_time = 0 order by id desc limit 1">>, [PlayerId])) of
                [] -> 
                    %% 是否已离婚
                    case db:get_row(io_lib:format(<<"select id from marriage where male_id = ~p and divorce = 1 order by id desc limit 1">>, [PlayerId])) of
                        [] ->
                            #marriage{};
                        _ ->
                            #marriage{
                                divorce = 1
                            }
                    end;
                [Id, MaleId, FemaleId, RegisterTime, WeddingTime, WeddingType, WeddingCard] ->
                    Marriage1 = #marriage{
                        id = Id,
                        male_id = MaleId,
                        female_id = FemaleId,
                        register_time = RegisterTime,
                        wedding_time = WeddingTime,
                        wedding_type = WeddingType,
                        wedding_card = WeddingCard
                    },
                    Marriage1#marriage{
                        wedding_card = WeddingCard div 2
                    }
            end;
        _ ->
            case db:get_row(io_lib:format(<<"select id, male_id, female_id, register_time, wedding_time, wedding_type, wedding_card from marriage where female_id = ~p and divorce_time = 0 order by id desc limit 1">>, [PlayerId])) of
                [] -> 
                    %% 是否已离婚
                    case db:get_row(io_lib:format(<<"select id from marriage where female_id = ~p and divorce = 1 order by id desc limit 1">>, [PlayerId])) of
                        [] ->
                            #marriage{};
                        _ ->
                            #marriage{
                                divorce = 1
                            }
                    end;
                [Id, MaleId, FemaleId, RegisterTime, WeddingTime, WeddingType, WeddingCard] ->
                    Marriage1 = #marriage{
                        id = Id,
                        male_id = MaleId,
                        female_id = FemaleId,
                        register_time = RegisterTime,
                        wedding_time = WeddingTime,
                        wedding_type = WeddingType,
                        wedding_card = WeddingCard
                    },
                    Marriage1#marriage{
                        wedding_card = WeddingCard div 2
                    }
            end
    end.

login_init_task(Info) ->
    [Id, MaleId, FemaleId] = Info,
    case db:get_row(io_lib:format(<<"select app_begin, task_flag, task_type, finish_task from marriage_task where id = ~p order by id desc limit 1">>, [Id])) of
        [] -> #marriage_task{};
        [AppBegin, TaskFlag, TaskType, FinishTask] ->
            NewTaskType = case TaskType of
                2 -> 0;
                _AnyType -> _AnyType
            end,
            NewTaskFlag = case TaskFlag of
                5 -> 5;
                _ -> 1
            end,
%%            NewTaskType = TaskType,
%%            NewTaskFlag = TaskFlag,
            #marriage_task{
                id = Id,
                male_id = MaleId,
                female_id = FemaleId,
                app_begin = AppBegin,
                task_flag = NewTaskFlag,
                task_type = NewTaskType,
                finish_task = FinishTask
            }
    end.

%% 购买喜帖
buy_card(Status, Num) ->
    %% 没有婚宴
    case mod_marriage:get_marry_info(Status#player_status.id) of
        Marriage when is_record(Marriage, marriage) ->
            case Marriage#marriage.wedding_time + 30 * 60 > util:unixtime() of
                %% 婚宴已结束
                false ->
                    Res = 2,
                    NewStatus = Status;
                true ->
                    PerMoney = case Marriage#marriage.wedding_type of
                        1 -> 5;
                        2 -> 8;
                        _ -> 15
                    end,
                    TotalMoney = PerMoney * Num,
                    %% 玩家元宝不足
                    case Status#player_status.gold < TotalMoney of
                        true ->
                            Res = 3,
                            NewStatus = Status;
                        false ->
                            NewStatus = lib_goods_util:cost_money(Status, TotalMoney, gold),
                            log:log_consume(pay_invitation, gold, Status, NewStatus, "buy wedding card"),
                            NewCard1 = Marriage#marriage.wedding_card + Num,
                            %io:format("NewCard:~p~n", [NewCard]),
                            mod_marriage:update_marriage_player(Marriage#marriage{wedding_card = NewCard1}, Status#player_status.sex),
                            MarriageInfo = mod_marriage:get_wedding_info(Marriage#marriage.id),
                            NewCard2 = MarriageInfo#marriage.wedding_card + Num,
                            mod_marriage:update_marriage_info(MarriageInfo#marriage{wedding_card = NewCard2}),
                            db:execute(io_lib:format(<<"update marriage set wedding_card = ~p where id = ~p">>, [NewCard2, Marriage#marriage.id])),
                            db:execute(io_lib:format(<<"update marriage_item set wedding_card = ~p where marriage_id = ~p">>, [NewCard2, Marriage#marriage.id])),
                            Res = 1
                    end
            end;
        _ ->
            Res = 0,
            NewStatus = Status
    end,
    {Res, NewStatus}.

%% 索要喜帖
ask_card(Info) ->
    [Status, WeddingId] = Info,
    case mod_marriage:is_guest(WeddingId, Status#player_status.id) of
        true ->
            Res = 3;
        false ->
            case mod_marriage:get_wedding_info(WeddingId) of
                Marriage when is_record(Marriage, marriage) ->
                    case misc:get_player_process(Marriage#marriage.male_id) of
                        Pid when is_pid(Pid) ->
                            Marriage2 = mod_marriage:get_marry_info(Marriage#marriage.male_id),
                            MaxGuest = Marriage2#marriage.wedding_card,
                            List = mod_marriage:get_all_guest(Marriage2#marriage.id, Marriage#marriage.male_id),
                            RestGuest = MaxGuest - length(List),
                            RestGuest2 = case RestGuest > 0 of
                                true -> RestGuest;
                                false -> 0
                            end,
                            {ok, BinData} = pt_271:write(27153, [Status#player_status.id, Status#player_status.nickname, Status#player_status.career, Status#player_status.sex, Status#player_status.image, Status#player_status.realm, RestGuest2]),
                            lib_server_send:send_to_uid(Marriage#marriage.male_id, BinData),
                            Res = 1;
                        _ ->
                            Res = 2
                    end;
                _ ->
                    Res = 0
            end
    end,
    Res.

wedding_candies(Info) ->
    [Status, Type] = Info,
    case Type of
        %% 查询剩余数量
        1 ->
            case mod_marriage:get_marry_info(Status#player_status.id) of
                Marriage when is_record(Marriage, marriage) ->
                    Res = 1,
                    Num = Marriage#marriage.wedding_candies;
                _ ->
                    Res = 0,
                    Num = 0
            end; 
        %% 发送喜糖
        2 ->
            case mod_marriage:get_marry_info(Status#player_status.id) of
                Marriage when is_record(Marriage, marriage) ->
                    OldNum = Marriage#marriage.wedding_candies,
                    case OldNum > 0 of
                        %% 喜糖剩余数量为0
                        false ->
                            Res = 2,
                            Num = 0;
                        true ->
                            Res = 1,
                            Num = Marriage#marriage.wedding_candies - 1,
                            NewMarriage = Marriage#marriage{wedding_candies = Num},
                            mod_marriage:update_marriage_player(NewMarriage, Status#player_status.sex),
                            candies_drop(Status, Status#player_status.x, Status#player_status.y)
                    end;
                _ ->
                    Res = 0,
                    Num = 0
            end; 
        _ ->
            Res = 0,
            Num = 0
    end,
    {Res, Num}.

candies_drop(Player, _X, _Y) ->
    Rand1 = util:rand(1, 10),
    Rand2 = util:rand(10, 20),
    Rand3 = util:rand(20, 30),
    Rand4 = util:rand(30, 40),
    Rand5 = util:rand(40, 50),
    Rand6 = util:rand(50, 60),
    X1 = _X + Rand1 - 5,
    Y1 = _Y + Rand2 - 15,
    X2 = _X + Rand3 - 25,
    Y2 = _Y + Rand4 - 35,
    X3 = _X + Rand5 - 45,
    Y3 = _Y + Rand6 - 55,
    PlayerId = 0,
    _Platform = "",
    Platform = pt:write_string(_Platform),
    SerNum = 0,
    GoodsTypeId = 602001,
    GoodsNum = 1,
    ExpireTime = util:unixtime() + ?GOODS_DROP_EXPIRE_TIME,
    DropId1 = mod_drop:get_drop_id(),
    GoodsDrop1 = #ets_drop{ id = DropId1,
                            player_id = PlayerId,
                            scene = Player#player_status.scene,
                            goods_id = GoodsTypeId,
                            num = GoodsNum,
                            broad = 1,
                            expire_time = ExpireTime,
                            x = Player#player_status.x,
                            y = Player#player_status.y
                         },
    DropId2 = mod_drop:get_drop_id(),
    GoodsDrop2 = #ets_drop{ id = DropId2,
                            player_id = PlayerId,
                            scene = Player#player_status.scene,
                            goods_id = GoodsTypeId,
                            num = GoodsNum,
                            broad = 1,
                            expire_time = ExpireTime,
                            x = Player#player_status.x,
                            y = Player#player_status.y
                         },
    DropId3 = mod_drop:get_drop_id(),
    GoodsDrop3 = #ets_drop{ id = DropId3,
                            player_id = PlayerId,
                            scene = Player#player_status.scene,
                            goods_id = GoodsTypeId,
                            num = GoodsNum,
                            broad = 1,
                            expire_time = ExpireTime,
                            x = Player#player_status.x,
                            y = Player#player_status.y
                         },
    mod_drop:add_drop(GoodsDrop1),
    mod_drop:add_drop(GoodsDrop2),
    mod_drop:add_drop(GoodsDrop3),
    DropBin1 = [<<DropId1:32, GoodsTypeId:32, GoodsNum:32, PlayerId:32, Platform/binary, SerNum:16>>],
    DropBin2 = [<<DropId2:32, GoodsTypeId:32, GoodsNum:32, PlayerId:32, Platform/binary, SerNum:16>>],
    DropBin3 = [<<DropId3:32, GoodsTypeId:32, GoodsNum:32, PlayerId:32, Platform/binary, SerNum:16>>],
    {ok, BinData1} = pt_120:write(12017, [0, ?GOODS_DROP_EXPIRE_TIME, Player#player_status.scene, DropBin1, X1, Y1]),
    lib_server_send:send_to_scene(Player#player_status.scene, Player#player_status.copy_id, BinData1),
    {ok, BinData2} = pt_120:write(12017, [0, ?GOODS_DROP_EXPIRE_TIME, Player#player_status.scene, DropBin2, X2, Y2]),
    lib_server_send:send_to_scene(Player#player_status.scene, Player#player_status.copy_id, BinData2),
    {ok, BinData3} = pt_120:write(12017, [0, ?GOODS_DROP_EXPIRE_TIME, Player#player_status.scene, DropBin3, X3, Y3]),
    lib_server_send:send_to_scene(Player#player_status.scene, Player#player_status.copy_id, BinData3).

%% 是否在活动时间三
is_in_activity3() ->
    EightBegin = data_marriage:get_marriage_config(activity_begin3),
    EightEnd = data_marriage:get_marriage_config(activity_end3),
    {date(), time()} >= EightBegin andalso {date(), time()} =< EightEnd.

near_by_point(X, Y) ->
    case (X - 17) * (X - 17) + (Y - 17) * (Y - 17) =< 16 of
        true -> true;
        false -> false
    end.

get_parner_id(PlayerId) ->
    case lib_player:get_player_info(PlayerId, marriage_parner_id) of
        ParnerId when is_integer(ParnerId) ->
            ParnerId;
        _ ->
            0
    end.

%% 离婚状态
get_divorce_state([Marriage, Id, _Sex]) ->
    case db:get_row(io_lib:format(<<"select register_time, divorce_time from marriage where male_id = ~p or female_id = ~p order by id desc limit 1">>, [Id, Id])) of
        [_RegisterTime, _DivorceTime] ->
            case _RegisterTime =:= 0 of
                true ->
                    case db:get_row(io_lib:format(<<"select count(*) from marriage where male_id = ~p or female_id = ~p">>, [Id, Id])) of
                        [_CountNum] when _CountNum >= 2 ->
                            1;
                        _ ->
                            0
                    end;
                false ->
                    case _DivorceTime =:= 0 of
                        true -> 
                            0;
                        false ->
                            1
                    end
            end;
        _ ->
            Marriage#marriage.divorce
    end.
