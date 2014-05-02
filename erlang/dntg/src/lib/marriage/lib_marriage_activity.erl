%%%------------------------------------
%%% @Module  : lib_marriage_activity
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.10.8
%%% @Description: 结婚系统活动
%%%------------------------------------
-module(lib_marriage_activity).
-export([
        activity_award/1,
        activity_award2/1,
        item_wedding/3,
        item_cruise/3
    ]).
-include("server.hrl").
-include("marriage.hrl").

%% 婚宴活动奖励
activity_award(Info) ->
    BeginTime = data_marriage:get_marriage_config(activity_begin1),
    EndTime = data_marriage:get_marriage_config(activity_end1),
    NowTime = {date(), time()},
    %io:format("1~n"),
    case NowTime >= BeginTime andalso NowTime =< EndTime of
        true -> 
            %io:format("2~n"),
            [MaleId, FemaleId, Level] = Info,
            AwardId = case Level of
                1 -> 534059;
                2 -> 534060;
                _ -> 534061
            end,
            Title = data_marriage_text:get_marriage_text(13),
            Content = data_marriage_text:get_marriage_text(14),
            case db:get_row(io_lib:format(<<"select id from marriage_activity where player_id = ~p and type = 0 limit 1">>, [MaleId])) of
                [] ->
                    db:execute(io_lib:format(<<"insert into marriage_activity set player_id = ~p, type = 0">>, [MaleId])),
                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[MaleId], Title, Content, AwardId, 2, 0, 0, 1, 0, 0, 0, 0]);
                _ ->
                    skip
            end,
            case db:get_row(io_lib:format(<<"select id from marriage_activity where player_id = ~p and type = 0 limit 1">>, [FemaleId])) of
                [] ->
                    db:execute(io_lib:format(<<"insert into marriage_activity set player_id = ~p, type = 0">>, [FemaleId])),
                    
                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[FemaleId], Title, Content, AwardId, 2, 0, 0, 1, 0, 0, 0, 0]);
                _ ->
                    skip
            end;
        false ->
            %io:format("3~n"),
            skip
    end.

%% 巡游活动奖励
activity_award2(Info) ->
    BeginTime = data_marriage:get_marriage_config(activity_begin2),
    EndTime = data_marriage:get_marriage_config(activity_end2),
    NowTime = {date(), time()},
    %io:format("1~n"),
    case NowTime >= BeginTime andalso NowTime =< EndTime of
        true -> 
            %io:format("2~n"),
            [MaleId, FemaleId, Level] = Info,
            AwardId = case Level of
                1 -> 534059;
                2 -> 534060;
                _ -> 534061
            end,
            Title = data_marriage_text:get_marriage_text(39),
            Content = data_marriage_text:get_marriage_text(40),
            case db:get_row(io_lib:format(<<"select id from marriage_activity where player_id = ~p and type = 1 limit 1">>, [MaleId])) of
                [] ->
                    db:execute(io_lib:format(<<"insert into marriage_activity set player_id = ~p, type = 1">>, [MaleId])),
                    lib_mail:send_sys_mail_bg([MaleId], Title, Content, AwardId, 2, 0, 0, 1, 0, 0, 0, 0);
                _ ->
                    skip
            end,
            case db:get_row(io_lib:format(<<"select id from marriage_activity where player_id = ~p and type = 1 limit 1">>, [FemaleId])) of
                [] ->
                    db:execute(io_lib:format(<<"insert into marriage_activity set player_id = ~p, type = 1">>, [FemaleId])),
                    lib_mail:send_sys_mail_bg([FemaleId], Title, Content, AwardId, 2, 0, 0, 1, 0, 0, 0, 0);
                _ ->
                    skip
            end;
        false ->
            %io:format("3~n"),
            skip
    end.

%% 道具姻缘绳使用
%% 预约婚宴检测
item_wedding(Status, Level, Hour) ->
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
                            %% 必须已完成婚宴才能使用姻缘绳
                            case ParnerId =/= 0 andalso Status#player_status.marriage#status_marriage.wedding_time =/= 0 of
                                false ->
                                    NewStatus = Status,
                                    Res = 7;
                                true ->
                                    %% 姻缘绳数量不足
                                    ParnerStatus = case lib_player:get_player_info(ParnerId) of
                                        false -> #player_status{};
                                        _AnyStatus -> _AnyStatus
                                    end,
                                    GoodsTypeId = 602006,
                                    IsEnougth = case mod_other_call:get_goods_num(Status, GoodsTypeId, 0) > 0 of
                                        true -> 
                                            MaleEnough = true,
                                            FemaleEnough = false,
                                            true;
                                        false ->
                                            case mod_other_call:get_goods_num(ParnerStatus, GoodsTypeId, 0) > 0 of
                                                true ->
                                                    MaleEnough = false,
                                                    FemaleEnough = true,
                                                    true;
                                                false ->
                                                    MaleEnough = false,
                                                    FemaleEnough = false,
                                                    false
                                            end
                                    end,
                                    case IsEnougth of
                                        false ->
                                            NewStatus = Status,
                                            Res = 8;
                                        true ->
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
                                                    DisCut = case lib_marriage:is_in_activity3() of
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
                                                                            %% 扣除物品
                                                                            case MaleEnough of
                                                                                true ->
                                                                                    lib_player:update_player_info(Status#player_status.id, [{use_goods, {GoodsTypeId, 1}}]);
                                                                                false ->
                                                                                    skip
                                                                            end,
                                                                            case FemaleEnough of
                                                                                true ->
                                                                                    lib_player:update_player_info(ParnerId, [{use_goods, {GoodsTypeId, 1}}]);
                                                                                false ->
                                                                                    skip
                                                                            end,
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
                                                                                    item_wedding(Status#player_status.id, ParnerId, Level, Hour, Status#player_status.marriage#status_marriage.id, Status#player_status.marriage#status_marriage.register_time);
                                                                                _ ->
                                                                                    item_wedding(ParnerId, Status#player_status.id, Level, Hour, Status#player_status.marriage#status_marriage.id, Status#player_status.marriage#status_marriage.register_time)
                                                                            end,
                                                                            %% 邮件发结婚戒指
                                                                            Title = data_marriage_text:get_marriage_text(4),
                                                                            %% 获取相关信息
                                                                            [Realm1, NickName1, Sex1, Career1, Image1] = [Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image],
                                                                            FemaleId = ParnerId,
                                                                            [_NickName2, Sex2, _Lv2, Career2, Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2|_] = lib_player:get_player_low_data(FemaleId),
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

item_wedding(MaleId, FemaleId, Level, Hour, MarriageId, RegisterTime) ->
    WeddingTime = util:unixdate() + Hour * 3600,
    lib_player:update_player_info(MaleId, [{marriage_wedding, WeddingTime}]),
    lib_player:update_player_info(FemaleId, [{marriage_wedding, WeddingTime}]),
    WeddingCard = case Level of
        1 -> 10;
        2 -> 20;
        3 -> 30;
        _ -> 10
    end,
    db:execute(io_lib:format(<<"insert into marriage_item set marriage_id = ~p, male_id = ~p, female_id = ~p, register_time = ~p, wedding_time = ~p, wedding_type = ~p, wedding_card = ~p">>, [MarriageId, MaleId, FemaleId, RegisterTime, WeddingTime, Level, WeddingCard])),
    mod_marriage:wedding(MaleId, FemaleId, Level, WeddingTime).

%% 道具桃花书笺使用
%% 预约巡游检测
item_cruise(Status, Level, Hour) ->
    _WeddingMarriage = mod_marriage:get_wedding_info(Status#player_status.marriage#status_marriage.id),
    WeddingMarriage = case is_record(_WeddingMarriage, marriage) of
        true -> _WeddingMarriage;
        false -> #marriage{}
    end,
    %% 失败，协议离婚等待中
    case WeddingMarriage#marriage.mark_sure_time > 0 of
        true ->
            NewStatus = Status,
            Res = 9;
        false ->
            %% 7点后是豪华巡游专场
            case Level =/= 3 andalso Hour >= 19 of
                true ->
                    NewStatus = Status,
                    Res = 7;
                false ->
                    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
                    %% (必须男方进行预约)
                    case Status#player_status.sex =/= 0 of
                        false ->
                            NewStatus = Status,
                            Res = 4;
                        true ->
                            %% 必须已完成巡游才能使用桃花书笺
                            case ParnerId =/= 0 andalso Status#player_status.marriage#status_marriage.cruise_time =/= 0 of
                                false ->
                                    NewStatus = Status,
                                    Res = 5;
                                true ->
                                    %% 桃花书笺数量不足
                                    ParnerStatus = case lib_player:get_player_info(ParnerId) of
                                        false -> #player_status{};
                                        _AnyStatus -> _AnyStatus
                                    end,
                                    GoodsTypeId = 602007,
                                    IsEnougth = case mod_other_call:get_goods_num(Status, GoodsTypeId, 0) > 0 of
                                        true -> 
                                            MaleEnough = true,
                                            FemaleEnough = false,
                                            true;
                                        false ->
                                            case mod_other_call:get_goods_num(ParnerStatus, GoodsTypeId, 0) > 0 of
                                                true ->
                                                    MaleEnough = false,
                                                    FemaleEnough = true,
                                                    true;
                                                false ->
                                                    MaleEnough = false,
                                                    FemaleEnough = false,
                                                    false
                                            end
                                    end,
                                    case IsEnougth of
                                        false ->
                                            NewStatus = Status,
                                            Res = 6;
                                        true ->
                                            %% 预约的时间点与当前时间点需间隔5分钟
                                            case util:unixdate() + Hour * 3600 + 1800 - 5 * 60 >= util:unixtime() of
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
                                                    DisCut = case lib_marriage:is_in_activity3() of
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
                                                                    Res = 7;
                                                                false ->
                                                                    %% 失败，该时间段已有人预约
                                                                    CruiseTime = util:unixdate() + Hour * 3600 + 1800,
                                                                    case db:get_row(io_lib:format(<<"select id from marriage where cruise_time = ~p limit 1">>, [CruiseTime])) =:= [] andalso db:get_row(io_lib:format(<<"select id from marriage_item where cruise_time = ~p limit 1">>, [CruiseTime])) =:= [] of
                                                                        false ->
                                                                            NewStatus = Status,
                                                                            Res = 8;
                                                                        true ->
                                                                                    %% 预约成功
                                                                                    %% 扣除物品
                                                                                    case MaleEnough of
                                                                                        true ->
                                                                                            lib_player:update_player_info(Status#player_status.id, [{use_goods, {GoodsTypeId, 1}}]);
                                                                                        false ->
                                                                                            skip
                                                                                    end,
                                                                                    case FemaleEnough of
                                                                                        true ->
                                                                                            lib_player:update_player_info(ParnerId, [{use_goods, {GoodsTypeId, 1}}]);
                                                                                        false ->
                                                                                            skip
                                                                                    end,
                                                                                    NewStatus1 = lib_goods_util:cost_money(Status, NeedGold, gold),
                                                                                    %% 消费接口
                                                                                    lib_activity:add_consumption(marryxyou, Status, NeedGold),
                                                                                    log:log_consume(wedding, gold, Status, NewStatus1, "cruise cost"),
                                                                                    NewStatus = lib_goods_util:cost_money(NewStatus1, NeedCoin, coin),
                                                                                    case NewStatus1#player_status.coin =:= NewStatus#player_status.coin of
                                                                                        false ->
                                                                                            log:log_consume(wedding, coin, NewStatus1, NewStatus, "cruise cost");
                                                                                        true ->
                                                                                            skip
                                                                                    end,
                                                                                    case NewStatus1#player_status.bcoin =:= NewStatus#player_status.bcoin of
                                                                                        false ->
                                                                                            log:log_consume(wedding, bcoin, NewStatus1, NewStatus, "cruise cost");
                                                                                        true ->
                                                                                            skip
                                                                                    end,
                                                                                    case Status#player_status.sex of
                                                                                        1 ->
                                                                                            item_cruise(Status#player_status.id, ParnerId, Level, Hour, Status#player_status.marriage#status_marriage.id, Status#player_status.marriage#status_marriage.register_time);
                                                                                        _ ->
                                                                                            item_cruise(ParnerId, Status#player_status.id, Level, Hour, Status#player_status.marriage#status_marriage.id, Status#player_status.marriage#status_marriage.register_time)
                                                                                    end,
                                                                                    %% 邮件
                                                                                    Title = data_marriage_text:get_marriage_text(28),
                                                                                    %% 获取玩家信息
                                                                                    FemaleId = ParnerId,
                                                                                    [Realm1, NickName1, Sex1, Career1, Image1] = [Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image],
                                                                                    [_NickName2, Sex2, _Lv2, Career2, Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2|_] = case lib_player:get_player_low_data(FemaleId) of
                                                                                        [] -> [<<>>, 0, 0, 0, 0, 0, 0, 0, 0];
                                                                                        _AnyData1 -> _AnyData1
                                                                                    end,
                                                                                    NickName2 = binary_to_list(_NickName2),
                                                                                    _ParnarName = NickName2,
                                                                                    Content1 = io_lib:format(data_marriage_text:get_marriage_text(29), [Hour]),
                                                                                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.id, ParnerId], Title, Content1, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
                                                                                    lib_player:refresh_client(Status#player_status.id, 2),
                                                                                    case Level of
                                                                                        1 ->
                                                                                            lib_chat:send_TV({all}, 0, 2, [xunyou, 1, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour]);
                                                                                        2 ->
                                                                                            lib_chat:send_TV({all}, 0, 2, [xunyou, 1, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour]);
                                                                                        _ ->
                                                                                            lib_chat:send_TV({all}, 0, 2, [xunyou, 1, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour])
                                                                                    end,
                                                                                    %% 发送戒指
                                                                                    ThingId = case Level of
                                                                                        1 -> 107001;
                                                                                        2 -> 107002;
                                                                                        3 -> 107003;
                                                                                        _ -> 107001
                                                                                    end,
                                                                                    ThingNum = 1,
                                                                                    %% 邮件
                                                                                    Title3 = data_marriage_text:get_marriage_text(55),
                                                                                    Content3 = data_marriage_text:get_marriage_text(56),
                                                                                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.id, ParnerId], Title3, Content3, ThingId, 2, 0, 0, ThingNum, 0, 0, 0, 0]),
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

%% 预约巡游
item_cruise(MaleId, FemaleId, Level, Hour, MarriageId, RegisterTime) ->
    CruiseTime = util:unixdate() + Hour * 3600 + 1800,
    lib_player:update_player_info(MaleId, [{marriage_cruise_time, CruiseTime}]),
    lib_player:update_player_info(FemaleId, [{marriage_cruise_time, CruiseTime}]),
    db:execute(io_lib:format(<<"insert into marriage_item set marriage_id = ~p, male_id = ~p, female_id = ~p, register_time = ~p, cruise_time = ~p, cruise_type = ~p">>, [MarriageId, MaleId, FemaleId, RegisterTime, CruiseTime, Level])),
    mod_marriage:cruise([MaleId, FemaleId, Level, CruiseTime]).
