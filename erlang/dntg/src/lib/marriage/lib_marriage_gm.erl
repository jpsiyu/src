%%%------------------------------------
%%% @Module  : lib_marriage_gm
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.24
%%% @Description: 结婚系统秘籍
%%%------------------------------------
-module(lib_marriage_gm).
-compile(export_all).
-include("server.hrl").
-include("unite.hrl").
-include("marriage.hrl").
-include("scene.hrl").

%% 预约成功
wedding_check(Status, Level) ->
    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
    NeedGold = case Level of
        1 -> 0;
        2 -> 1314;
        3 -> 3344;
        _ -> 99999999
    end,
    NewStatus = lib_goods_util:cost_money(Status, NeedGold, gold),
    log:log_consume(wedding, gold, Status, NewStatus, "wedding cost"),
    WeddingTime = util:unixtime() + 60,
    lib_player:update_player_info(Status#player_status.id, [{marriage_wedding, WeddingTime}]),
    lib_player:update_player_info(ParnerId, [{marriage_wedding, WeddingTime}]),
    case Status#player_status.sex of
        1 ->
            wedding(Status#player_status.id, ParnerId, Level, WeddingTime);
        _ ->
            wedding(ParnerId, Status#player_status.id, Level, WeddingTime)
    end,
    %% 邮件发结婚戒指
    Title = data_marriage_text:get_marriage_text(4),
    _ParnarName = case lib_player:get_player_info(ParnerId, nickname) of
        false -> " ";
        _Any -> _Any
    end,
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
    [Realm1, NickName1, Sex1, Career1, Image1] = [Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image],
    FemaleId = ParnerId,
    [Realm2, NickName2, Sex2, Career2, Image2] = case lib_player:get_player_info(FemaleId, marriage_sendtv) of
        false -> [0, " ", 0, 0, 0];
        _Any2 -> _Any2
    end,
    {Hour, _Min, _Sec} = time(),
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
    lib_player:refresh_client(Status#player_status.id, 2),
    %% 活动
    lib_marriage_activity:activity_award([Status#player_status.id, ParnerId, Level]),
    NewStatus.

wedding(MaleId, FemaleId, Level, WeddingTime) ->
    WeddingCard = case Level of
        1 -> 10;
        2 -> 20;
        3 -> 30;
        _ -> 10
    end,
    lib_player:update_player_info(MaleId, [{marriage_wedding, WeddingTime}]),
    lib_player:update_player_info(FemaleId, [{marriage_wedding, WeddingTime}]),
    db:execute(io_lib:format(<<"update marriage set wedding_time = ~p, wedding_type = ~p, wedding_card = ~p where male_id = ~p and divorce_time = 0">>, [WeddingTime, Level, WeddingCard, MaleId])),
    mod_marriage:wedding(MaleId, FemaleId, Level, WeddingTime).

timer(StartTime) ->
    List = mod_marriage:get_all_wedding(),
    Time = util:unixtime() - StartTime,
    %io:format("Time:~p, List:~p, StartTime:~p~n", [Time, List, StartTime]),
    %io:format("cut:~p~n", [[Time, mod_marriage:get_marry_info(2641)]]),
    if 
        Time < 5 ->
            %% 清除气氛值
            mod_marriage:clear_mood(),
            mod_disperse:cast_to_unite(lib_marriage, send_email_notice, [List]);
        Time < 60 ->
            mod_disperse:cast_to_unite(lib_marriage, send_countdown, [List]);
        Time < 70 ->
            mod_disperse:cast_to_unite(lib_marriage, send_countdown2, [List, 0]);
        Time < 480 ->
            mod_disperse:cast_to_unite(lib_marriage, send_resttime, [List]);
        Time < 500 ->
            mod_disperse:cast_to_unite(lib_marriage, before_end, [List]);
        Time < 510 ->
            mod_disperse:cast_to_unite(lib_marriage, send_all_out, [List]);
        Time < 520 ->
            mod_disperse:cast_to_unite(lib_marriage, send_resttime2, [List, 0]);
        true -> 
            skip
    end,
    timer:sleep(10 * 1000),
    lib_marriage_gm:timer(StartTime).

%% 巡游
cruise_check(Status, Level, Time) ->
    NeedGold = case Level of
        1 -> 521;
        2 -> 999;
        _ -> 1314
    end,
    %% 预约成功
    NewStatus = lib_goods_util:cost_money(Status, NeedGold, gold),
    log:log_consume(early_parade, gold, Status, NewStatus, "cruise cost"),
    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
    case Status#player_status.sex of
        1 ->
            cruise(Status#player_status.id, ParnerId, Level, Time);
        _ ->
            cruise(ParnerId, Status#player_status.id, Level, Time)
    end,
    %% 邮件
    Title = data_marriage_text:get_marriage_text(28),
    _ParnarName = case lib_player:get_player_info(ParnerId, nickname) of
        false -> " ";
        _Any -> _Any
    end,
    {Hour, _Min, _Sec} = time(),
    Content1 = io_lib:format(data_marriage_text:get_marriage_text(29), [Hour]),
    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.id], Title, Content1, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
    lib_player:refresh_client(Status#player_status.id, 2),
    [Realm1, NickName1, Sex1, Career1, Image1] = [Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image],
    FemaleId = ParnerId,
    [Realm2, NickName2, Sex2, Career2, Image2] = case lib_player:get_player_info(FemaleId, marriage_sendtv) of
        false -> [0, " ", 0, 0, 0];
        _Any2 -> _Any2
    end,
    case Level of
        1 ->
            lib_chat:send_TV({all}, 0, 2, [xunyou, 1, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour]);
        2 ->
            lib_chat:send_TV({all}, 0, 2, [xunyou, 1, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour]);
        _ ->
            lib_chat:send_TV({all}, 0, 2, [xunyou, 1, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour])
    end,
    NewStatus.

%% 预约巡游
cruise(MaleId, FemaleId, Level, Time) ->
    CruiseTime = Time,
    lib_player:update_player_info(MaleId, [{marriage_cruise_time, CruiseTime}]),
    lib_player:update_player_info(FemaleId, [{marriage_cruise_time, CruiseTime}]),
    db:execute(io_lib:format(<<"update marriage set cruise_time = ~p, cruise_type = ~p where male_id = ~p and divorce_time = 0">>, [CruiseTime, Level, MaleId])),
    mod_marriage:cruise([MaleId, FemaleId, Level, CruiseTime]).

timer2(StartTime) ->
    List = mod_marriage:get_all_cruise(),
    Time = util:unixtime() - StartTime,
    %io:format("Time:~p, List:~p, StartTime:~p~n", [Time, List, StartTime]),
    %io:format("cut:~p~n", [[Time, mod_marriage:get_marry_info(2641)]]),
    %io:format("time:~p, List:~p~n", [time(), length(List)]),
    if 
        Time < 5 ->
            mod_disperse:cast_to_unite(lib_marriage_cruise, send_email_notice, [List]);
        Time < 70 ->
            mod_disperse:cast_to_unite(lib_marriage_cruise, send_countdown, [List]);
        Time < 80 ->
            mod_disperse:cast_to_unite(lib_marriage_cruise, send_countdown2, [List, 0]);
        Time < 1890 ->
            mod_disperse:cast_to_unite(lib_marriage_cruise, send_resttime, [List]);
        Time < 1900 ->
            mod_disperse:cast_to_unite(lib_marriage_cruise, send_resttime2, [List, 0]);
        true -> 
            skip
    end,
    timer:sleep(10 * 1000),
    lib_marriage_gm:timer2(StartTime).

%% 预约成功
item_wedding_check(Status, Level) ->
    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
    NeedGold = case Level of
        1 -> 0;
        2 -> 1314;
        3 -> 3344;
        _ -> 99999999
    end,
    NewStatus = lib_goods_util:cost_money(Status, NeedGold, gold),
    log:log_consume(wedding, gold, Status, NewStatus, "wedding cost"),
    WeddingTime = util:unixtime() + 60,
    lib_player:update_player_info(Status#player_status.id, [{marriage_wedding, WeddingTime}]),
    lib_player:update_player_info(ParnerId, [{marriage_wedding, WeddingTime}]),
    case Status#player_status.sex of
        1 ->
            item_wedding(Status#player_status.id, ParnerId, Level, WeddingTime, Status#player_status.marriage#status_marriage.id, Status#player_status.marriage#status_marriage.register_time);
        _ ->
            item_wedding(ParnerId, Status#player_status.id, Level, WeddingTime, Status#player_status.marriage#status_marriage.id, Status#player_status.marriage#status_marriage.register_time)
    end,
    %% 邮件发结婚戒指
    Title = data_marriage_text:get_marriage_text(4),
    _ParnarName = case lib_player:get_player_info(ParnerId, nickname) of
        false -> " ";
        _Any -> _Any
    end,
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
    [Realm1, NickName1, Sex1, Career1, Image1] = [Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image],
    FemaleId = ParnerId,
    [Realm2, NickName2, Sex2, Career2, Image2] = case lib_player:get_player_info(FemaleId, marriage_sendtv) of
        false -> [0, " ", 0, 0, 0];
        _Any2 -> _Any2
    end,
    {Hour, _Min, _Sec} = time(),
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
    lib_player:refresh_client(Status#player_status.id, 2),
    %% 活动
    lib_marriage_activity:activity_award([Status#player_status.id, ParnerId, Level]),
    NewStatus.

item_wedding(MaleId, FemaleId, Level, WeddingTime, MarriageId, RegisterTime) ->
    WeddingCard = case Level of
        1 -> 10;
        2 -> 20;
        3 -> 30;
        _ -> 10
    end,
    lib_player:update_player_info(MaleId, [{marriage_wedding, WeddingTime}]),
    lib_player:update_player_info(FemaleId, [{marriage_wedding, WeddingTime}]),
    db:execute(io_lib:format(<<"insert into marriage_item set marriage_id = ~p, male_id = ~p, female_id = ~p, register_time = ~p, wedding_time = ~p, wedding_type = ~p, wedding_card = ~p">>, [MarriageId, MaleId, FemaleId, RegisterTime, WeddingTime, Level, WeddingCard])),
    mod_marriage:wedding(MaleId, FemaleId, Level, WeddingTime).


%% 巡游
item_cruise_check(Status, Level, Time) ->
    NeedGold = case Level of
        1 -> 521;
        2 -> 999;
        _ -> 1314
    end,
    %% 预约成功
    NewStatus = lib_goods_util:cost_money(Status, NeedGold, gold),
    log:log_consume(early_parade, gold, Status, NewStatus, "cruise cost"),
    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
    case Status#player_status.sex of
        1 ->
            item_cruise(Status#player_status.id, ParnerId, Level, Time, Status#player_status.marriage#status_marriage.id, Status#player_status.marriage#status_marriage.register_time);
        _ ->
            item_cruise(ParnerId, Status#player_status.id, Level, Time, Status#player_status.marriage#status_marriage.id, Status#player_status.marriage#status_marriage.register_time)
    end,
    %% 邮件
    Title = data_marriage_text:get_marriage_text(28),
    _ParnarName = case lib_player:get_player_info(ParnerId, nickname) of
        false -> " ";
        _Any -> _Any
    end,
    {Hour, _Min, _Sec} = time(),
    Content1 = io_lib:format(data_marriage_text:get_marriage_text(29), [Hour]),
    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.id], Title, Content1, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
    lib_player:refresh_client(Status#player_status.id, 2),
    [Realm1, NickName1, Sex1, Career1, Image1] = [Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image],
    FemaleId = ParnerId,
    [Realm2, NickName2, Sex2, Career2, Image2] = case lib_player:get_player_info(FemaleId, marriage_sendtv) of
        false -> [0, " ", 0, 0, 0];
        _Any2 -> _Any2
    end,
    case Level of
        1 ->
            lib_chat:send_TV({all}, 0, 2, [xunyou, 1, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour]);
        2 ->
            lib_chat:send_TV({all}, 0, 2, [xunyou, 1, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour]);
        _ ->
            lib_chat:send_TV({all}, 0, 2, [xunyou, 1, Status#player_status.id, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Level, Hour])
    end,
    NewStatus.

%% 预约巡游
item_cruise(MaleId, FemaleId, Level, Time, MarriageId, RegisterTime) ->
    CruiseTime = Time,
    lib_player:update_player_info(MaleId, [{marriage_cruise_time, CruiseTime}]),
    lib_player:update_player_info(FemaleId, [{marriage_cruise_time, CruiseTime}]),
    db:execute(io_lib:format(<<"insert into marriage_item set marriage_id = ~p, male_id = ~p, female_id = ~p, register_time = ~p, cruise_time = ~p, cruise_type = ~p">>, [MarriageId, MaleId, FemaleId, RegisterTime, CruiseTime, Level])),
    mod_marriage:cruise([MaleId, FemaleId, Level, CruiseTime]).
