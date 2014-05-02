%%%------------------------------------
%%% @Module  : lib_marriage_cruise
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.10.15
%%% @Description: 结婚系统-巡游
%%%------------------------------------
-module(lib_marriage_cruise).  
-export([
        cruise_check/1,
        send_email_notice/1,
        send_countdown/1,
        send_countdown2/2,
        send_resttime/1,
        send_resttime_for_one/2,
        send_resttime2/2,
        cruise_start/1,
        rest_num/1,
        buy_num/1,
        cruise_card/1,
        cruise_candies/1,
        send_to_car/1
    ]).
-include("server.hrl").
-include("marriage.hrl").
-include("chat.hrl").
-include("scene.hrl").
-include("unite.hrl").

%% 预约巡游检测
cruise_check([Status, Level, Hour]) ->
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
                            %% 必须已举办婚宴才能进行巡游预约
                            case ParnerId =/= 0 andalso Status#player_status.marriage#status_marriage.wedding_time =/= 0 of
                                false ->
                                    NewStatus = Status,
                                    Res = 5;
                                true ->
                                    %% 是否已巡游
                                    case db:get_row(io_lib:format(<<"select cruise_time from marriage where male_id = ~p or female_id = ~p and divorce_time = 0 order by id desc limit 1">>, [Status#player_status.id, Status#player_status.id])) of
                                        [] ->
                                            NewStatus = Status,
                                            Res = 5;
                                        %% 已预约或完成巡游
                                        [CruiseTime] when CruiseTime =/= 0 ->
                                            NewStatus = Status,
                                            Res = 6;
                                        _ ->
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
                                                                                    cruise(Status#player_status.id, ParnerId, Level, Hour);
                                                                                _ ->
                                                                                    cruise(ParnerId, Status#player_status.id, Level, Hour)
                                                                            end,
                                                                            %% 邮件
                                                                            Title = data_marriage_text:get_marriage_text(28),
                                                                            %% 获取玩家信息
                                                                            FemaleId = ParnerId,
                                                                            [Realm1, NickName1, Sex1, Career1, Image1] = [Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image],
                                                                            [_NickName2, Sex2, _Lv2, Career2, Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2| _] = case lib_player:get_player_low_data(FemaleId) of
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
cruise(MaleId, FemaleId, Level, Hour) ->
    CruiseTime = util:unixdate() + Hour * 3600 + 1800,
    lib_player:update_player_info(MaleId, [{marriage_cruise_time, CruiseTime}]),
    lib_player:update_player_info(FemaleId, [{marriage_cruise_time, CruiseTime}]),
    db:execute(io_lib:format(<<"update marriage set cruise_time = ~p, cruise_type = ~p where male_id = ~p and divorce_time = 0">>, [CruiseTime, Level, MaleId])),
    mod_marriage:cruise([MaleId, FemaleId, Level, CruiseTime]).

%% 给双方发邮件提醒
send_email_notice([]) -> skip;
send_email_notice([H | T]) ->
    case H of
        Marriage when is_record(Marriage, marriage) ->
            _MaleId = Marriage#marriage.male_id,
            _FemaleId = Marriage#marriage.female_id,
            Scale = Marriage#marriage.cruise_type,
            [NickName1, Sex1, _Lv1, Career1, _Realm1, _GuildId1, _Mount_limit1, _HusongNpc1, Image1|_] = lib_player:get_player_low_data(_MaleId),
            [NickName2, Sex2, _Lv2, Career2, _Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2|_] = lib_player:get_player_low_data(_FemaleId),
            MaleMarriage = mod_marriage:get_marry_info(_MaleId),
            FemaleMarriage = mod_marriage:get_marry_info(_FemaleId),

            NewMarriage = Marriage#marriage{male_name = NickName1, female_name = NickName2, male_sex = Sex1, female_sex = Sex2, male_career = Career1, female_career = Career2, male_image = Image1, female_image = Image2},

            NewMaleMarriage = MaleMarriage#marriage{male_name = NickName1, female_name = NickName2, male_sex = Sex1, female_sex = Sex2, male_career = Career1, female_career = Career2, male_image = Image1, female_image = Image2},

            NewFemaleMarriage = FemaleMarriage#marriage{male_name = NickName1, female_name = NickName2, male_sex = Sex1, female_sex = Sex2, male_career = Career1, female_career = Career2, male_image = Image1, female_image = Image2},
            mod_marriage:update_marriage_info(NewMarriage),
            mod_marriage:update_marriage_player(NewMaleMarriage, 1),
            mod_marriage:update_marriage_player(NewFemaleMarriage, 2),
            Title = data_marriage_text:get_marriage_text(30),
            Content = data_marriage_text:get_marriage_text(31),
            lib_mail:send_sys_mail_bg([_MaleId, _FemaleId], Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0),
            lib_chat:send_TV({all}, 1, 2, [xunyou, 2, _MaleId, _Realm1, binary_to_list(NickName1), Sex1, Career1, Image1, _FemaleId, _Realm2, binary_to_list(NickName2), Sex2, Career2, Image2, Scale]),
            case Scale of
                3 ->
                    MarriageText = case Scale of
                        1 -> data_marriage_text:get_marriage_text(34);
                        2 -> data_marriage_text:get_marriage_text(35);
                        _ -> data_marriage_text:get_marriage_text(36)
                    end,
                    Content2 = io_lib:format(data_marriage_text:get_marriage_text(32), [binary_to_list(NickName1), binary_to_list(NickName2), MarriageText]),
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
            end,
            %% 巡游立即围观：排除传送
            %% 35分钟后停止该服务
            spawn(fun() ->
                        send_line(0)
                end);
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
            _CruiseTime = H#marriage.cruise_time,
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
            Scale = H#marriage.cruise_type,
            CountdownTime = _CruiseTime - util:unixtime(),
            CountdownTime1 = case CountdownTime > 0 of
                true -> CountdownTime;
                false -> 0
            end,
%%            io:format("CountdownTime1:~p~n", [CountdownTime1]),
            [Num1, Num2] = mod_marriage:get_today_num2(H#marriage.register_time, H#marriage.cruise_time),
            {ok, BinData} = pt_271:write(27116, [_Id, CountdownTime1, MaleId, FemaleId, MaleName, FemaleName, MaleCareer, FemaleCareer, MaleSex, FemaleSex, MaleImage, FemaleImage, Scale, Num1, Num2]),
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
            _CruiseTime = H#marriage.cruise_time,
            MaleId = H#marriage.male_id,
            FemaleId = H#marriage.female_id,
            Scale = H#marriage.cruise_type,
            [NickName1, Sex1, _Lv1, Career1, Realm1, _GuildId1, _Mount_limit1, _HusongNpc1, Image1|_] = lib_player:get_player_low_data(MaleId),
            [NickName2, Sex2, _Lv2, Career2, Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2|_] = lib_player:get_player_low_data(FemaleId),
            CountdownTime1 = Begin,
            lib_chat:send_TV({all}, 1, 2, [xunyou, 3, MaleId, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Scale, 102, 163, 222]),
            [Num1, Num2] = mod_marriage:get_today_num2(H#marriage.register_time, H#marriage.cruise_time),
            {ok, BinData} = pt_271:write(27116, [_Id, CountdownTime1, MaleId, Realm1, NickName1, NickName2, Career1, Career2, Sex1, Sex2, Image1, Image2, Scale, Num1, Num2]),
            lib_unite_send:send_to_all(30, 999, BinData),
            case Scale of
                3 ->
                    MarriageText = case Scale of
                        1 -> data_marriage_text:get_marriage_text(34);
                        2 -> data_marriage_text:get_marriage_text(35);
                        _ -> data_marriage_text:get_marriage_text(36)
                    end,
                    Content2 = io_lib:format(data_marriage_text:get_marriage_text(33), [binary_to_list(NickName1), binary_to_list(NickName2), MarriageText]),
                    mod_chat_bugle_call:put_element(#call{
                            id = H#marriage.male_id, %% 角色ID
                            nickname = NickName1,    %% 角色名
                            realm = Realm1,          %% 阵营
                            sex = Sex1,              %% 性别
                            color = 1,               %% 颜色
                            content = Content2,      %% 内容
                            gm = 0,                  %% GM
                            vip = 0,                 %% VIP
                            work = Career1,          %% 职业
                            type = 8,                %% 喇叭类型  1飞天号角 2冲天号角 3生日号角 4新婚号角
                            image = Image1,          %% 头像ID
                            channel = 0,             %% 发送频道 0世界 1场景 2阵营 3帮派 4队伍
                            ringfashion=lib_chat:get_fashionRing(H#marriage.male_id) %%戒指时装
                        });
                _ -> 
                    skip
            end;            
        _ ->
            skip
    end,
    send_countdown2(T, Begin). 

%% 巡游剩余时间
send_resttime([]) -> skip;
send_resttime([H | T]) ->
    case is_record(H, marriage) of
        true ->
            _Id = H#marriage.id,
            _CruiseTime = H#marriage.cruise_time,
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
            Scale = H#marriage.cruise_type,
            CountdownTime = _CruiseTime + 30 * 60 - util:unixtime(),
            CountdownTime1 = case CountdownTime > 0 of
                true -> CountdownTime;
                false -> 0
            end,
            [Num1, Num2] = mod_marriage:get_today_num2(H#marriage.register_time, H#marriage.cruise_time),
%%            io:format("CountdownTime1:~p~n", [CountdownTime1]),
            {ok, BinData} = pt_271:write(27117, [_Id, CountdownTime1, MaleId, FemaleId, MaleName, FemaleName, MaleCareer, FemaleCareer, MaleSex, FemaleSex, MaleImage, FemaleImage, Scale, Num1, Num2]),
            lib_unite_send:send_to_all(30, 999, BinData);
        _ ->
            skip
    end,
    send_resttime(T).

%% 巡游剩余时间
send_resttime_for_one([], _UniteStatus) -> skip;
send_resttime_for_one([H | T], UniteStatus) ->
    case is_record(H, marriage) of
        true ->
            _Id = H#marriage.id,
            _CruiseTime = H#marriage.cruise_time,
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
            Scale = H#marriage.cruise_type,
            CountdownTime = _CruiseTime + 30 * 60 - util:unixtime(),
            CountdownTime1 = case CountdownTime > 0 of
                true -> CountdownTime;
                false -> 0
            end,
            [Num1, Num2] = mod_marriage:get_today_num2(H#marriage.register_time, H#marriage.cruise_time),
%%            io:format("CountdownTime1:~p~n", [CountdownTime1]),
            {ok, BinData} = pt_271:write(27117, [_Id, CountdownTime1, MaleId, FemaleId, MaleName, FemaleName, MaleCareer, FemaleCareer, MaleSex, FemaleSex, MaleImage, FemaleImage, Scale, Num1, Num2]),
            lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData);
        _ ->
            skip
    end,
    send_resttime_for_one(T, UniteStatus).

%% 巡游结束
send_resttime2([], _End) -> skip;
send_resttime2([H | T], End) ->
    case is_record(H, marriage) of
        true ->
            _Id = H#marriage.id,
            _CruiseTime = H#marriage.cruise_time,
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
            Scale = H#marriage.cruise_type,
            CountdownTime1 = End,
            [Num1, Num2] = mod_marriage:get_today_num2(H#marriage.register_time, H#marriage.cruise_time),
            {ok, BinData} = pt_271:write(27117, [_Id, CountdownTime1, MaleId, FemaleId, MaleName, FemaleName, MaleCareer, FemaleCareer, MaleSex, FemaleSex, MaleImage, FemaleImage, Scale, Num1, Num2]),
            lib_unite_send:send_to_all(30, 999, BinData);
        _ ->
            skip
    end,
    send_resttime2(T, End).

%% 开始巡游
cruise_start(Status) ->
    %% 获取伴侣信息
    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
    ParnerStatus = case lib_player:get_player_info(ParnerId) of
        false -> 
            NotOnline = 1,
            #player_status{};
        _Status -> 
            NotOnline = 0,
            _Status
    end,
    case NotOnline of
        1 ->
            Res = 9;
        _ ->
            %% 得到伴侣结婚信息
            case Status#player_status.sex of
                1 ->
                    FemaleMarriage = ParnerStatus#player_status.marriage,
                    MaleMarriage = Status#player_status.marriage,
                    MaleId = Status#player_status.id,
                    FemaleId = ParnerId;
                _ ->
                    MaleMarriage = ParnerStatus#player_status.marriage,
                    FemaleMarriage = Status#player_status.marriage,
                    FemaleId = Status#player_status.id,
                    MaleId = ParnerId
            end,
            %io:format("State:~p~n", [lib_marriage:marry_state(MaleMarriage)]),
            case lib_marriage:marry_state(MaleMarriage) =:= 12 andalso lib_marriage:marry_state(FemaleMarriage) =:= 12 of
                %% 未预约巡游
                false ->
                    Res = 4;
                true ->
                    Marriage2 = mod_marriage:get_marry_info(FemaleId),
                    NowTime = util:unixtime(),
                    case NowTime < Marriage2#marriage.cruise_time of
                        %% 巡游未开始
                        true -> 
                            Res = 8;
                        false ->
                            case lib_player:is_transferable(Status) of
                                %% 不可传送
                                false -> 
                                    Res = 10;
                                true ->
                                    case lib_player:is_transferable(ParnerStatus) of
                                        %% 伴侣不可传送
                                        false ->
                                            Res = 11;
                                        true ->
                                            case NowTime > Marriage2#marriage.cruise_time + 30 * 60 of
                                                %% 已过巡游时间
                                                true ->
                                                    Res = 5;
                                                %% 成功
                                                false ->
                                                    %% 清除气氛值
                                                    mod_marriage:clear_mood2(),
                                                    Marriage1 = mod_marriage:get_marry_info(MaleId),
                                                    Marriage = mod_marriage:get_wedding_info(Marriage1#marriage.id),
                                                    mod_marriage:update_marriage_info(Marriage#marriage{cruise_state = 2}),
                                                    mod_marriage:update_marriage_player(Marriage1#marriage{cruise_state = 2}, 1),
                                                    mod_marriage:update_marriage_player(Marriage2#marriage{cruise_state = 2}, 2),
                                                    %% 15分钟后自动结束巡游
                                                    {_Hour, Min, Sec} = time(),
                                                    SleepTime = case Min >= 45 of
                                                        true -> 
                                                            AnyTime = 60 * 60 - Min * 60 - Sec,
                                                            case AnyTime > 0 of
                                                                true -> AnyTime;
                                                                false -> 0
                                                            end;
                                                        false -> 15 * 60
                                                    end,
                                                    lib_player:update_player_info(MaleId, [{marriage_cruise, 1}]),
                                                    lib_player:update_player_info(FemaleId, [{marriage_cruise, 1}]),
                                                    %% 生成怪物
                                                    MonId = case Marriage#marriage.cruise_type of
                                                        1 -> 43406;
                                                        2 -> 43407;
                                                        _ -> 43408
                                                    end,
                                                    X = 162,
                                                    Y = 223,
                                                    MonAutoId = lib_mon:sync_create_mon(MonId, 102, X, Y, 0, 0, 1, []),
                                                    mod_marriage:set_mon_id(MonAutoId),
                                                    %% 切换PK状态
                                                    lib_player:update_player_info(MaleId, [{force_change_pk_status, 0}]),
                                                    lib_player:update_player_info(FemaleId, [{force_change_pk_status, 0}]),
                                                    %% 把玩家传送到婚车
                                                    lib_scene:player_change_scene(MaleId, 102, 0, X, Y, false),
                                                    lib_scene:player_change_scene(FemaleId, 102, 0, X, Y, false),
                                                    %% 结束定时器
                                                    spawn(fun() ->
                                                                timer:sleep(SleepTime * 1000),
                                                                %io:format("sleep over~n"),
                                                                %% 关闭小图标
                                                                List = mod_marriage:get_all_cruise(),
                                                                mod_disperse:cast_to_unite(lib_marriage_cruise, send_resttime2, [List, 0]),
                                                                %% 修改各种状态
                                                                NewMarriage = mod_marriage:get_wedding_info(Marriage1#marriage.id),
                                                                NewMarriage1 = mod_marriage:get_marry_info(MaleId),
                                                                NewMarriage2 = mod_marriage:get_marry_info(FemaleId),
                                                                mod_marriage:update_marriage_info(NewMarriage#marriage{cruise_state = 3}),
                                                                mod_marriage:update_marriage_player(NewMarriage1#marriage{cruise_state = 3}, 1),
                                                                mod_marriage:update_marriage_player(NewMarriage2#marriage{cruise_state = 3}, 2),
                                                                mod_marriage:check_mood2([MaleId, FemaleId]),
                                                                lib_player:update_player_info(MaleId, [{marriage_cruise, 0}]),
                                                                lib_player:update_player_info(FemaleId, [{marriage_cruise, 0}]),
                                                                lib_mon:clear_scene_mon_by_mids(102, 0, 1, [43406,43407,43408])
                                                        end),
                                                    %% 每分钟广播坐标
                                                    spawn(fun() ->
                                                                %%                                                                                io:format("BeginMin:~p~n", [Min]),
                                                                send_to_world(MaleId, FemaleId, Min, Marriage1#marriage.cruise_type)
                                                        end),
                                                    Res = 1
                                            end
                                    end
                            end
                    end
            end
    end,
    %io:format("Res:~p~n", [Res]),
    Res.

%% 剩余数量
%% Type: 1.表白图册 2.喜糖礼盒
rest_num([Status, Type]) ->
    case mod_marriage:get_marry_info(Status#player_status.id) of
        Marriage when is_record(Marriage, marriage) ->
            case Type of
                1 ->
                    Res = Marriage#marriage.cruise_card;
                _ ->
                    Res = Marriage#marriage.cruise_candies
            end;
        _ ->
            Res = 0
    end,
    Res.

%% 购买
%% Type: 1.表白图册 2.喜糖礼盒
buy_num([Status, Type, Num]) ->
    case mod_marriage:get_marry_info(Status#player_status.id) of
        Marriage when is_record(Marriage, marriage) ->
            case Type of
                1 ->
                    Gold = 30 * Num,
                    case Status#player_status.gold >= Gold of
                        %% 元宝不足
                        false ->
                            TotalNum = 0,
                            NewStatus = Status,
                            Res = 2;
                        true ->
                            case Marriage#marriage.cruise_time of
                                %% 不存在该巡游
                                0 ->
                                    TotalNum = 0,
                                    NewStatus = Status,
                                    Res = 3;
                                _ ->
                                    NewStatus = lib_goods_util:cost_money(Status, Gold, gold),
                                    log:log_consume(parade_pay, gold, Status, NewStatus, "cruise cost"),
                                    CardNum = Marriage#marriage.cruise_card,
                                    mod_marriage:update_marriage_player(Marriage#marriage{cruise_card = CardNum + Num}, Status#player_status.sex),
                                    lib_player:refresh_client(Status#player_status.id, 2),
                                    TotalNum = CardNum + Num,
                                    Res = 1
                            end
                    end;
                _ ->
                    Gold = 20 * Num,
                    case Status#player_status.gold >= Gold of
                        %% 元宝不足
                        false ->
                            TotalNum = 0,
                            NewStatus = Status,
                            Res = 2;
                        true ->
                            case lib_marriage:marry_state(Status#player_status.marriage) of
                                %% 正在举办婚宴
                                7 ->
                                    NewStatus = lib_goods_util:cost_money(Status, Gold, gold),
                                    log:log_consume(parade_pay, gold, Status, NewStatus, "wedding cost"),
                                    CandiesNum = Marriage#marriage.wedding_candies,
                                    mod_marriage:update_marriage_player(Marriage#marriage{wedding_candies = CandiesNum + Num}, Status#player_status.sex),
                                    lib_player:refresh_client(Status#player_status.id, 2),
                                    TotalNum = CandiesNum + Num,
                                    Res = 1;
                                %% 正在巡游
                                8 ->
                                    NewStatus = lib_goods_util:cost_money(Status, Gold, gold),
                                    log:log_consume(parade_pay, gold, Status, NewStatus, "cruise cost"),
                                    CandiesNum = Marriage#marriage.cruise_candies,
                                    mod_marriage:update_marriage_player(Marriage#marriage{cruise_candies = CandiesNum + Num}, Status#player_status.sex),
                                    lib_player:refresh_client(Status#player_status.id, 2),
                                    TotalNum = CandiesNum + Num,
                                    Res = 1;
                                %% 不存在该巡游
                                _ ->
                                    TotalNum = 0,
                                    NewStatus = Status,
                                    Res = 3
                            end
                    end
            end;
        %% 不存在该巡游
        _ ->
            TotalNum = 0,
            NewStatus = Status,
            Res = 3
    end,
    {Res, NewStatus, TotalNum}.

%% 爱的宣言
cruise_card([Status, Content]) ->
    case mod_marriage:get_marry_info(Status#player_status.id) of
        Marriage when is_record(Marriage, marriage) ->
            case Marriage#marriage.cruise_card =< 0 of
                %% 表白图册剩余数量为0
                true ->
                    CardNum = Marriage#marriage.cruise_card,
                    Res = 2;
                false ->
                    %% 超过长度限制
                    case util:check_length(Content, 255) of
                        false -> 
                            CardNum = Marriage#marriage.cruise_card,
                            Res = 4;
                        true ->
                            %% 内容含有非法字段
                            case util:check_keyword(Content) of
                                true ->
                                    CardNum = Marriage#marriage.cruise_card,
                                    Res = 3;
                                false ->
                                    %% 是否在巡游时间内
                                    NowTime = util:unixtime(),
                                    case NowTime > Marriage#marriage.cruise_time andalso NowTime =< Marriage#marriage.cruise_time + 1800 of
                                        true ->
                                            mod_marriage:add_mood2([50, Status#player_status.nickname, Status#player_status.scene, Status#player_status.copy_id, 1]),
                                            Goods = Status#player_status.goods,
                                            Ring = case Goods#status_goods.hide_ring =:= 0 of
                                                true ->
                                                    [FashionRing, _Stren6] = Goods#status_goods.fashion_ring,
                                                    FashionRing;
                                                false ->
                                                    [FashionRing, _Stren6] = [0, 0],
                                                    FashionRing
                                            end,	
                                            Call = #call{
                                                id = Status#player_status.id, %% 角色ID
                                                nickname = Status#player_status.nickname, %% 角色名
                                                realm = Status#player_status.realm, %% 阵营
                                                sex = Status#player_status.sex, %% 性别
                                                color = 1, %% 颜色
                                                content = Content, %% 内容
                                                gm = 0, %% GM
                                                vip = Status#player_status.vip#status_vip.vip_type, %% VIP
                                                work = Status#player_status.career, %% 职业
                                                type = 9, %% 喇叭类型  1飞天号角 2冲天号角 3生日号角 4新婚号角
                                                image = Status#player_status.image, %% 头像ID 
                                                channel = 0, %% 发送频道 0世界 1场景 2阵营 3帮派 4队伍
                                                ringfashion = Ring %%戒指时装
                                            },
                                            mod_disperse:cast_to_unite(mod_chat_bugle_call, put_element, [Call]),
                                            CardNum = Marriage#marriage.cruise_card - 1,
                                            mod_marriage:update_marriage_player(Marriage#marriage{cruise_card = CardNum}, Status#player_status.sex),
                                            Res = 1;
                                        false ->
                                            CardNum = Marriage#marriage.cruise_card,
                                            Res = 0
                                    end
                            end
                    end
            end;
        _ ->
            CardNum = 0,
            Res = 0
    end,
    {Res, CardNum}.

%% 发送喜糖
cruise_candies(Status) ->
    case mod_marriage:get_marry_info(Status#player_status.id) of
        Marriage when is_record(Marriage, marriage) ->
            case Marriage#marriage.cruise_candies =< 0 of
                %% 喜糖剩余数量为0
                true ->
                    CandiesNum = 0,
                    Res = 2;
                false ->
                    %% 是否在巡游时间内
                    NowTime = util:unixtime(),
                    case NowTime > Marriage#marriage.cruise_time andalso NowTime =< Marriage#marriage.cruise_time + 1800 of
                        true ->
                            mod_marriage:add_mood2([10, Status#player_status.nickname, Status#player_status.scene, Status#player_status.copy_id, 2]),
                            CandiesNum = Marriage#marriage.cruise_candies - 1,
                            mod_marriage:update_marriage_player(Marriage#marriage{cruise_candies = CandiesNum}, Status#player_status.sex),
                            MonId = mod_marriage:get_mon_id(),
                            Mon = mod_scene_agent:apply_call(102, lib_mon, lookup, [102, MonId]),
                            [X, Y] = case is_record(Mon, ets_mon) of
                                false ->
                                    [Status#player_status.x, Status#player_status.y];
                                true ->
                                    [Mon#ets_mon.x, Mon#ets_mon.y]
                            end,
                            lib_marriage:candies_drop(Status, X, Y),
                            Res= 1;
                        false ->
                            CandiesNum = 0,
                            Res = 0
                    end
            end;
        _ ->
            CandiesNum = 0,
            Res = 0
    end,
    {Res, CandiesNum}.

%% 广播婚车坐标
send_to_world(Id1, Id2, BeginMin, Scale) ->
    [NickName1, Sex1, _Lv1, Career1, Realm1, _GuildId1, _Mount_limit1, _HusongNpc1, Image1| _] = lib_player:get_player_low_data(Id1),
    [NickName2, Sex2, _Lv2, Career2, Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2| _] = lib_player:get_player_low_data(Id2),
    MonId = mod_marriage:get_mon_id(),
    Mon = mod_scene_agent:apply_call(102, lib_mon, lookup, [102, MonId]),
    [X, Y] = case is_record(Mon, ets_mon) of
        false ->
            [163, 222];
        true ->
            [Mon#ets_mon.x, Mon#ets_mon.y]
    end,
%%    io:format("X:~p, Y:~p~n", [X, Y]),
    lib_chat:send_TV({all}, 0, 2, [xunyou, 3, Id1, Realm1, NickName1, Sex1, Career1, Image1, Id2, Realm2, NickName2, Sex2, Career2, Image2, Scale, 102, X, Y]),
    timer:sleep(60 * 1000),
    %% 是否已结束
    {_Hour, Min, _Sec} = time(),
%%    io:format("send_to_world:~p~n", [Min - BeginMin]),
    case Min - BeginMin >= 15 orelse Min =< 1 of
        true ->
            skip;
        false ->
            send_to_world(Id1, Id2, BeginMin, Scale)
    end.

%% 传送到婚车
send_to_car(Status) ->
    case lib_marriage:marry_state(Status#player_status.marriage) of
        %% 新郎新娘不能传送
        %8 ->
        99 ->
            Res = 3;
        _ ->
            %获取要传送地图场景数据.
            PresentScene = case data_scene:get(Status#player_status.scene) of
                [] -> 
                    #ets_scene{};
                SceneData ->
                    SceneData
            end,
            %% 只能在野外和普通场景传送
            case PresentScene#ets_scene.type =:= ?SCENE_TYPE_NORMAL orelse PresentScene#ets_scene.type =:= ?SCENE_TYPE_OUTSIDE of
                true ->
                    mod_marriage:add_send_line([Status]),
                    Res = 1;
                %% 该场景不允许传送至婚车
                false ->
                    Res = 2
            end
    end,
    Res.

%% 排队处理传送
send_line(Time) ->
    timer:sleep(5 * 1000),
    {X, Y, List} = mod_marriage:get_send_line(),
    %io:format("List:~p~n", [List]),
    send_all(X, Y, List),
    %io:format("Time:~p~n", [Time]),
    case Time > 35 * 60 of
        true ->
            skip;
        false ->
            send_line(Time + 5)
    end.

send_all(_X, _Y, []) -> skip;
send_all(X, Y, [H | T]) ->
    lib_scene:player_change_scene(H, 102, 0, X, Y, false),
    send_all(X, Y, T).
