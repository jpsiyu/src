%% ---------------------------------------------------------
%% Author:  HHL
%% Email:   
%% Created: 2014-3-7
%% Description: 登录奖励
%% --------------------------------------------------------
-module(lib_login_gift).
-export([
        calc_days_while_login/1,
        calc_days_while_logout/1,
        query_all_gift_info/1,
        get_continuous_login_gift/3,
        get_continuous_login_gift/4,
        notice_get_gift/2,
        reset_login_days/1,
        change_charge_status/1,
        %% 累积登录和翻牌
        get_cumulative_login_info/3,
        online/1,
        reload/1,
        cumulative_logout/1,
        sign_days_op/5,
        get_total_drop_count/1,
        get_sign_goods/5,
        get_drop_award/1,
        chack_is_vip/2,
        get_drop_goods/1,
        tt/1
        ]
       ).
-include("gift.hrl").
-include("server.hrl").
-include("common.hrl").
-include("goods.hrl").
-include("login_count.hrl").


%%% ====================================================================
%%%                     连续登录奖励 及 回归礼包
%%% ====================================================================

%% 是否曾经充值过 -> 0 | 1
is_charged(PlayerStatus) ->
    PlayerId = PlayerStatus#player_status.id,
    case get("PlayerLoginGift") of
        undefined ->
            Sql = io_lib:format(<<"select gold from charge where player_id = ~p limit 1">>, [PlayerId]),
            case db:get_one(Sql) of
                null ->
                    put("PlayerLoginGift", 0),
                    0;
                _Other -> 
                    put("PlayerLoginGift", 1),
                    1
            end;
        ChargedStatus ->
            ChargedStatus
    end.

%% 登录时处理
calc_days_while_login(PlayerStatus) ->
    Record = get_login_days_info(PlayerStatus),
    correct_continuous_days(PlayerStatus, Record).

%% 登出时处理
calc_days_while_logout(PlayerStatus) ->
    RoleId = PlayerStatus#player_status.id,
    Record = get_login_days_info(PlayerStatus),
    correct_continuous_days(PlayerStatus, Record),
    ets:delete(?ETS_LOGIN_COUNTER, RoleId).

%% 查询奖励详情（查询时修正） -> {ok,ContinuousDays,NoLoginDays,IsCharged,ContinuousGiftInfo,NoLoginGiftInfo}
query_all_gift_info(PlayerStatus) ->
    Record = get_login_days_info(PlayerStatus),
    NewRecord = correct_continuous_days(PlayerStatus, Record),
    ContinuousDays = NewRecord#ets_login_counter.continuous_days,
    NoLoginDays = NewRecord#ets_login_counter.no_login_days,
    ContinuousGiftInfo = NewRecord#ets_login_counter.continuous_gift,
    NoLoginGiftInfo = NewRecord#ets_login_counter.no_login_gift,
    IsCharged = NewRecord#ets_login_counter.is_charged,
    {ok, ContinuousDays, NoLoginDays, IsCharged, ContinuousGiftInfo, NoLoginGiftInfo}.

%% 计算连续登录天数 -> EtsLoginCounter : record()
correct_continuous_days(PlayerStatus, EtsLoginCounter) ->
    NowTime = util:unixtime(),
    RoleId = PlayerStatus#player_status.id,
    Vip =PlayerStatus#player_status.vip,
    VipType = Vip#status_vip.vip_type,
    {TodayMight, _NextMight} = util:get_midnight_seconds(NowTime),
    LastLoginTime = EtsLoginCounter#ets_login_counter.last_login_time,
    LastLogoutTime = EtsLoginCounter#ets_login_counter.last_logout_time,
    OldContinuousDays = EtsLoginCounter#ets_login_counter.continuous_days,
    LastCorrectTime = EtsLoginCounter#ets_login_counter.last_correct_time,
    ContinuousGift = EtsLoginCounter#ets_login_counter.continuous_gift,
    NoLoginGift = EtsLoginCounter#ets_login_counter.no_login_gift,
    IsCharged = EtsLoginCounter#ets_login_counter.is_charged,
    case calc_days_info(VipType, OldContinuousDays, TodayMight, LastLoginTime, LastLogoutTime, LastCorrectTime) of
        ok ->   %% 今天处理过，不处理
            EtsLoginCounter;
        {IsBreak, RealNoLoginDays, NoLoginDays, NewContinuousDays} ->
            %.计算帮派防刷平均积分.
            Pid = PlayerStatus#player_status.pid,
            gen_server:cast(Pid, 'set_guild_anti_brush_score'),                     
            %% 在排行榜检查战斗力是否更新（直接用连续登录每天最多只处理一次的方法，不用另外处理）
%%              到时加上            
            NeedAddGiftList = make_continuous_gift_list(IsCharged, IsBreak, OldContinuousDays, NewContinuousDays),
            NewContinuousGift =
            lists:foldl(
                fun(X, OldGiftList) ->      %% X = {IsCharge, Days, Times}
                        get_new_gift_list(X, OldGiftList, [])
                end, ContinuousGift, NeedAddGiftList),
            NewNoLoginGift =
            case query_no_login_gift(NoLoginDays) of
                [] -> NoLoginGift;
                _ ->  get_new_gift_list({0, NoLoginDays, 1}, NoLoginGift, [])    %% 未登录礼物不计充值与否
            end,
            case (catch update_days_info_on_db(RoleId, NewContinuousDays, RealNoLoginDays, NowTime, NewContinuousGift, NewNoLoginGift) ) of
                {'EXIT', _} ->      %% 数据库未更新成功，再尝试一次
                    update_days_info_on_db(RoleId, NewContinuousDays, RealNoLoginDays, NowTime, NewContinuousGift, NewNoLoginGift);
                _ ->
                    ok
            end,
            Record = EtsLoginCounter#ets_login_counter{
                continuous_days = NewContinuousDays,
                no_login_days = RealNoLoginDays,
                last_correct_time = NowTime,
                continuous_gift = NewContinuousGift,
                no_login_gift = NewNoLoginGift
            },
            %% UC连续登录奖励
            lib_uc:switch(login_daily_send_gold, [RoleId, NewContinuousDays]),
            ets:insert(?ETS_LOGIN_COUNTER, Record),
            Record
    end.

%% 更新连续登录数据
update_days_info_on_db(RoleId, ContinuousDays, NoLoginDays, LastCorrectTime, ContinuousGift, NoLoginGift) ->
    ContinuousGiftInfo = util:term_to_string(ContinuousGift),
    NoLoginGiftInfo = util:term_to_string(NoLoginGift),
    Sql = io_lib:format(?sql_continuous_update_info, [ContinuousDays, NoLoginDays, LastCorrectTime, ContinuousGiftInfo, NoLoginGiftInfo, RoleId]),
    db:execute(Sql).

%% 计算此前未登录天数以及连续登录天数，并返回相关信息 -> {RealNoLoginDays, NoLoginDays, ContinuousDays}
calc_days_info(VipType, OldContinuousDays, TodayMight, LastLoginTime, LastLogoutTime, LastCorrectTime) ->
    case TodayMight > LastCorrectTime of
        %1.今天已经修正过数据.
        false ->    
            ok;
        true ->
            T1 = get_days(TodayMight, LastLoginTime),
            T2 = get_days(TodayMight, LastCorrectTime),
            case LastLogoutTime =:= 0 of
                false -> 
                    T3 = get_days(TodayMight, LastLogoutTime);
                true -> 
                    T3 = T1
            end,
            Temp1 = T3 - T1 - 1,
            %1.真实未登录天数.
            RealNoLoginDays =   
                case Temp1 =< 0 of
                    true -> 0;
                    false ->
                        case Temp1 > 127 of
                            true -> 127;
                            false -> Temp1
                        end
                end,
            ContinuousDays =
                if
                    %1.登录确保数据写成功，此类情况为今天首次登录
                    T1 - T2 < 0 ->      
                        %1.计回归礼包的未登录天数
                        NoLoginDays =   
                        if
                            RealNoLoginDays >= 30 -> 30;
                            RealNoLoginDays >= 15 -> 15;
                            RealNoLoginDays >= 7 -> 7;
                            true -> 0
                        end,
                        if
                            RealNoLoginDays =< 0 ->
                                IsBreak = false;
                            true ->
                                IsBreak =
                                case VipType of
                                    1 ->    %% 黄金Vip（月卡类型）
                                        (RealNoLoginDays > 2);
                                    2 ->    %% 白金Vip（季卡类型）
                                        (RealNoLoginDays > 3);
                                    3 ->    %% 钻石Vip（半年卡类型）
                                        (RealNoLoginDays > 5);
                                    _ ->    %% 非Vip等
                                        true
                                end
                        end,
                        case IsBreak of
                            true -> 1;
                            false -> OldContinuousDays + 1
                        end;
                    true ->
                        NoLoginDays = 0,    %% 回归礼包信息已经在登录时处理过，此处不计
                        IsBreak = false,
                        OldContinuousDays + T2  %% 检查中间经过了哪些天数，是否可以获得某些礼包
                end,
%%          %1.连续登录改为累计登录.          
%%          ContinuousDays = OldContinuousDays + 1,
            NewContinuousDays =
                if
                    ContinuousDays > 60 ->
                        X = (ContinuousDays rem 60),
                        case X =:= 0 of
                            true -> 60;
                            false -> X
                        end;
                    true -> ContinuousDays
                end,
            {IsBreak, RealNoLoginDays, NoLoginDays, NewContinuousDays}
    end.

get_days(TodayMight, Time) ->
    case Time >= TodayMight of
        true -> 0;
        false ->
            X = TodayMight - Time,
            case (X rem ?ONE_DAY_SECONDS ) =:= 0 of
                true -> 
                    X div ?ONE_DAY_SECONDS;
                false -> 
                    X div ?ONE_DAY_SECONDS + 1
            end
    end.

get_login_days_info(PlayerStatus) ->
    RoleId = PlayerStatus#player_status.id,
    case ets:lookup(?ETS_LOGIN_COUNTER, RoleId) of
        [Result] ->
            Result;
        _ ->    %% 在此情况下，某些信息还需要通过计算得到
            [LastLoginTime, LastLogoutTime, ContinuousDays, NoLoginDays, LastCorrectTime, ResetTime, ContinuousGift, NoLoginGift] = get_login_days_info_from_db(RoleId),
            case is_integer(ContinuousDays) of
                true ->
                    ContinuousGiftInfo = lib_goods_util:to_term(ContinuousGift),
                    NoLoginGiftInfo = lib_goods_util:to_term(NoLoginGift),
                    Record =
                    #ets_login_counter{
                        id = RoleId,
                        last_login_time = LastLoginTime,
                        last_logout_time = LastLogoutTime,
                        continuous_days = ContinuousDays,
                        no_login_days = NoLoginDays,
                        last_correct_time = LastCorrectTime,
                        reset_time =  ResetTime,
                        continuous_gift = ContinuousGiftInfo,
                        no_login_gift = NoLoginGiftInfo,
                        is_charged = is_charged(PlayerStatus)     %% 是否充值
                    };
                false ->    %% 未有连续登录表数据
                    init_login_days_info_on_db(RoleId),
                    Record =
                    #ets_login_counter{
                        id = RoleId,
                        last_login_time = LastLoginTime,
                        last_logout_time = LastLogoutTime,
                        continuous_days = 0,
                        no_login_days = 0,
                        last_correct_time = 0,
                        reset_time = 0,
                        continuous_gift = [],
                        no_login_gift = [],
                        is_charged = is_charged(PlayerStatus)
                    }
            end,
            ets:insert(?ETS_LOGIN_COUNTER, Record),
            Record
    end.

init_login_days_info_on_db(RoleId) ->
    Sql = io_lib:format(?sql_continuous_insert, [RoleId, 0, 0, 0, [], []]),
    db:execute(Sql).

get_login_days_info_from_db(RoleId) ->
    PlayerSql = io_lib:format(?sql_player_login_select, [RoleId]),
    [LastLoginTime, LastLogoutTime] = db:get_row(PlayerSql),
    ConSql = io_lib:format(?sql_continuous_select, [RoleId]),
    Info = db:get_row(ConSql),
    case Info =:= [] of
        true ->
            [ContinuousDays, NoLoginDays, LastCorrectTime, ResetTime, ContinuousGift, NoLoginGift] = [[],0,0,0,0,0];
        false ->
            [ContinuousDays, NoLoginDays, LastCorrectTime, ResetTime, ContinuousGift, NoLoginGift] = Info
    end,
    [LastLoginTime, LastLogoutTime, ContinuousDays, NoLoginDays, LastCorrectTime, ResetTime, ContinuousGift, NoLoginGift].
%% 查询连续登录礼物信息 -> [{IsCharged, Days, Times}, ...]
make_continuous_gift_list(IsCharged, IsBreak, OldDays, NewDays) ->
    DayList =
    case IsBreak of
        true ->     %% 中断过，从1天开始到NewDays
            case NewDays < 1 of
                true -> [];
                false -> lists:seq(1, NewDays)
            end;
        false ->
            case OldDays < NewDays of
                false -> %% 到60天后又进入下一个循环（不考虑出现连续在线超过一个周期60天的情况）
                    %% 从OldDays到60天，再由1天到NewDays
                    L1 =
                    case OldDays < 60 of
                        false -> [];
                        true -> lists:seq(OldDays, 60)
                    end,
                    L2 =
                    case NewDays < 1 of
                        true -> [];
                        false -> lists:seq(1, NewDays)
                    end,
                    L1 ++ L2;
                true ->
                    %% 从OldDays到NewDays
                    lists:seq(OldDays + 1, NewDays)
            end
    end,
    make_continuous_gift_list(DayList, IsCharged).

make_continuous_gift_list(DayList, IsCharged) ->
    lists:foldl(
        fun(Day, AccList) ->
                case query_continuous_login_gift(IsCharged, Day) of
                    [] -> AccList;
                    _ -> [{IsCharged, Day, 1} | AccList]
                end
        end, [], DayList).

%% 根据连续登录天数及充值类型查询礼物列表
query_continuous_login_gift(IsCharged, ContinuousDays) ->
    case IsCharged of
        0 ->
            if
                ContinuousDays =:= 1 -> [{goods, 112301, 2}];       %% 绿洗
                ContinuousDays =:= 2 -> [{goods, 112302, 1}];       %% 蓝洗
                ContinuousDays =:= 3 -> [{goods, 211001, 1}];       %% 小经验符
                ContinuousDays =:= 5 -> [{goods, 205101, 1}];       %% 小血包
                ContinuousDays =:= 7 -> [{goods, 112303, 1}];       %% 紫洗
                ContinuousDays =:= 10 -> [{goods, 624801, 1}];      %% 修行卷
                ContinuousDays =:= 15 -> [{goods, 601501, 1}];      %% 洗炼锁
                ContinuousDays =:= 20 -> [{goods, 121001, 1}];      %% 1级幸运符
                ContinuousDays =:= 25 -> [{goods, 624203, 3}];      %% 初级宠物成长丹
                ContinuousDays =:= 30 -> [{goods, 624801, 1}];      %% 修行卷
                ContinuousDays =:= 35 -> [{goods, 624203, 6}];      %% 初级宠物成长丹
                ContinuousDays =:= 40 -> [{goods, 531402, 1}];      %% 2级宝石
                ContinuousDays =:= 45 -> [{goods, 121002, 1}];      %% 2级幸运符
                ContinuousDays =:= 50 -> [{goods, 624201, 1}];      %% 成长丹
                ContinuousDays =:= 55 -> [{goods, 531403, 1}];      %% 3级宝石
                ContinuousDays =:= 60 -> [{goods, 624201, 1}];      %% 成长丹
                true -> []
            end;
        _ ->
            if
                ContinuousDays =:= 1 -> [{goods, 112301, 4}];       %% 绿洗
                ContinuousDays =:= 2 -> [{goods, 112302, 2}];       %% 蓝洗
                ContinuousDays =:= 3 -> [{goods, 211002, 1}];       %% 中经验符
                ContinuousDays =:= 5 -> [{goods, 205201, 1}];       %% 中血包
                ContinuousDays =:= 7 -> [{goods, 112303, 1}];       %% 紫洗
                ContinuousDays =:= 10 -> [{goods, 624801, 2}];      %% 修行卷
                ContinuousDays =:= 15 -> [{goods, 601501, 2}];      %% 洗炼锁
                ContinuousDays =:= 20 -> [{goods, 121001, 2}];      %% 1级幸运符
                ContinuousDays =:= 25 -> [{goods, 624203, 6}];      %% 初级宠物成长丹
                ContinuousDays =:= 30 -> [{goods, 624801, 2}];      %% 修行卷
                ContinuousDays =:= 35 -> [{goods, 624203, 9}];      %% 初级宠物成长丹
                ContinuousDays =:= 40 -> [{goods, 531402, 1}];      %% 2级宝石
                ContinuousDays =:= 45 -> [{goods, 121002, 2}];      %% 2级幸运符
                ContinuousDays =:= 50 -> [{goods, 624201, 1}];      %% 成长丹
                ContinuousDays =:= 55 -> [{goods, 531403, 1}];      %% 3级宝石
                ContinuousDays =:= 60 -> [{goods, 624201, 1}];      %% 成长丹
                true -> []
            end
    end.

%% 根据回归天数查询礼物列表
query_no_login_gift(NoLoginDays) ->
    %% 墨谷英雄帖 绿 - 橙： 671001 - 671004
    %% 二锅头 1 - 4级：214001 - 214004
    %% 木材堆 1 - 4级：673001 - 673004
    %% 蓬莱清酒：672001
    if
        NoLoginDays =:= 7 ->
            [{goods, 533301, 1}];
        NoLoginDays =:= 15 ->
            [{goods, 533302, 1}];
        NoLoginDays =:= 30 ->
            [{goods, 533303, 1}];
        true -> []
    end.

%% 领取奖励（根据请求的天数及类型领取对应的物品） -> {ok, NewPlayerStatus, GiveList} | {error, ErrorCode}
%% Type : 0 -> 连续登录未充值类型 1 -> 连续登录已充值类型 2 -> 回归礼包类型
get_continuous_login_gift(PlayerStatus, Days, Type) ->
    case check_level_while_get_gift(PlayerStatus, Type) of
        false ->
            {error, 4};
        true ->
            Record = get_login_days_info(PlayerStatus),
            GiftInfo =
            case Type of
                2 ->
                    ChargedType = 0,
                    Record#ets_login_counter.no_login_gift;     %% 回归礼包类型
                1 ->
                    ChargedType = 1,
                    Record#ets_login_counter.continuous_gift;   %% 连续登录类型（已充值）
                _ ->
                    ChargedType = 0,
                    Record#ets_login_counter.continuous_gift    %% 连续登录类型（未充值）
            end,
            case check_get_gift(GiftInfo, Days, ChargedType) of
                false ->    %% 无对应天数记录（未达到条件，或者奖励已经领取）
                    {error, 3};
                {ChargedType, Days, Times} ->    %% 天数及对应达成次数
                    case Type of
                        2 ->    %% 回归礼包类型
                            NewNoLoginGift = lists:delete({ChargedType, Days, Times}, GiftInfo),
                            NewRecord = Record#ets_login_counter{no_login_gift = NewNoLoginGift},
                            GiftList = query_no_login_gift(Days);
                        _ ->    %% 连续登录类型
                            NewContinuousGift = lists:delete({ChargedType, Days, Times}, GiftInfo),
                            NewRecord = Record#ets_login_counter{continuous_gift = NewContinuousGift},
                            GiftList = query_continuous_login_gift(ChargedType, Days)
                    end,
                    NewGiftList = times_gift_list(GiftList, Times),
                    Go = PlayerStatus#player_status.goods,
                    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'get_continuous_login_gift', PlayerStatus, NewGiftList, NewRecord}, 3000) of
                        {ok, {ok, NewPlayerStatus, GiveList}} ->    %% 领取成功
                            ets:insert(?ETS_LOGIN_COUNTER, NewRecord),
                            {ok, NewPlayerStatus, GiveList};
                        {ok, {error, 2}} ->     %% 背包空间不足
                            {error, 2};
                        _ ->    %% 领取不成功
                            {error, 0}
                    end;
                _ ->    %% 数据错误
                    {error, 0}
            end
    end.

get_continuous_login_gift(PlayerStatus, GoodsStatus, GiftList, NewEtsLoginCounter) ->
    GoodsList = lists:filter(
        fun(Give) ->
                Type = erlang:element(1, Give),
                not lists:member(Type, [bcoin, coin, silver, gold])
        end, GiftList),
    NeedCellNum = length(GoodsList),
    NullCellNum = length(GoodsStatus#goods_status.null_cells),
    case NeedCellNum > NullCellNum of
        true ->
            {fail, 2};
        false ->
            F = fun() ->
                    ok = lib_goods_dict:start_dict(),
                    %% 给予的物品均为绑定
                    Bind = 2,
                    [NewPlayerStatus, NewGoodsStatus, _, GiveList, _, _GoodsList] = 
                        lists:foldl(fun lib_gift:give_gift_item/2, 
                                    [PlayerStatus, GoodsStatus, Bind, [], 0, []], GiftList),
                    update_days_info_on_db(
                        NewEtsLoginCounter#ets_login_counter.id,
                        NewEtsLoginCounter#ets_login_counter.continuous_days,
                        NewEtsLoginCounter#ets_login_counter.no_login_days,
                        NewEtsLoginCounter#ets_login_counter.last_correct_time,
                        NewEtsLoginCounter#ets_login_counter.continuous_gift,
                        NewEtsLoginCounter#ets_login_counter.no_login_gift
                    ),
                    About = lists:concat([lists:concat([Id,":",Num,","]) || {Id, Num} <- lib_gift:get_log_about(GiveList)]),
                    log:log_gift(PlayerStatus#player_status.id, 0, 0, 0, About),
                    D = lib_goods_dict:handle_dict(GoodsStatus#goods_status.dict),
                    NewGoodsStatus1 = NewGoodsStatus#goods_status{dict = D},
                    {ok, NewPlayerStatus, NewGoodsStatus1, GiveList}
            end,
            lib_goods_util:transaction(F)
    end.

%% 根据达成次数计算新的礼物列表 -> NewGiftList
times_gift_list(OldGiftList, Times) ->
    lists:foldl(
        fun(GiftInfo, OldList) ->
                NewGiftInfo = times_gift(GiftInfo, Times),
                [NewGiftInfo | OldList]
        end,
        [],
        OldGiftList).

times_gift(GiftInfo, Times) ->
    case GiftInfo of
        {goods, GoodsTypeId, GoodsNum} ->
            {goods, GoodsTypeId, GoodsNum * Times};
        {bcoin, Min, Max} ->
            {bcoin, Min * Times, Max * Times};
        _ -> GiftInfo
    end.

%% get_new_gift_list({IsCharged, MatchDays, AddTimes}, OldGiftInfoList, []) -> NewGiftInfoList
get_new_gift_list({IsCharged, MatchDays, AddTimes}, [], AccList) ->
    lists:reverse( [{IsCharged, MatchDays, AddTimes} | AccList] );
get_new_gift_list({IsCharged, MatchDays, AddTimes}, OldRest, AccList) ->
    [{OldIsCharged, Days, Times} | Rest] = OldRest,
    if
        MatchDays =:= Days ->
            if
                IsCharged =:= OldIsCharged ->
                    lists:reverse( [{IsCharged, MatchDays, Times + AddTimes} | AccList] ) ++ Rest;
                IsCharged > OldIsCharged ->
                    get_new_gift_list({IsCharged,MatchDays,AddTimes}, Rest, [{OldIsCharged,Days,Times} | AccList]);
                true ->
                    lists:reverse( [{IsCharged,MatchDays,AddTimes} | AccList] ) ++ OldRest
            end;
        MatchDays > Days ->
            get_new_gift_list({IsCharged, MatchDays, AddTimes}, Rest, [{OldIsCharged, Days, Times} | AccList]);
        true ->
            lists:reverse( [{IsCharged, MatchDays, AddTimes} | AccList]) ++ OldRest
    end;
get_new_gift_list(_, OldGiftInfoList, _) ->
    OldGiftInfoList.

%% 从礼物列表中查找有无对应的信息 -> false | GiftInfo
%% check_get_gift(GiftInfoList, MatchDays, ChargedType)
check_get_gift([], _, _) ->
    false;
check_get_gift([GiftInfo | RestInfo], MatchDays, ChargedType) ->
    case check_type_info(GiftInfo, MatchDays, ChargedType) of
        true -> 
            GiftInfo;
        false ->
            check_get_gift(RestInfo, MatchDays, ChargedType)
    end.

check_type_info({IsCharged, Days, _Times}, MatchDays, ChargedType) ->
    MatchDays =:= Days andalso IsCharged =:= ChargedType.

%% 通知角色获得物品
notice_get_gift(PlayerStatus, GiveList) ->
    [ [GetExp, GetGold, GetSilver, GetCoin, GetBCoin], GetGoodsList] =
    lists:foldl(
        fun (Gift, [[Exp, Gold, Silver, Coin, BCoin], GoodsList] ) ->
                case Gift of
                    {exp, AddExp} ->
                        [ [Exp + AddExp, Gold, Silver, Coin, BCoin], GoodsList];
                    {gold, AddGold} ->
                        [ [Exp, Gold + AddGold, Silver, Coin, BCoin], GoodsList];
                    {silver, AddSilver} ->
                        [ [Exp, Gold, Silver + AddSilver, Coin, BCoin], GoodsList];
                    {coin, AddCoin} ->
                        [ [Exp, Gold, Silver, Coin + AddCoin, BCoin], GoodsList];
                    {bcoin, AddBCoin} ->
                        [ [Exp, Gold, Silver, Coin, BCoin + AddBCoin], GoodsList];
                    {goods, GoodsTypeId, GoodsNum} ->
                        [ [Exp, Gold, Silver, Coin, BCoin], [{GoodsTypeId, GoodsNum} | GoodsList] ];
                    _ ->
                        [ [Exp, Gold, Silver, Coin, BCoin], GoodsList]
                end
        end,
        [[0, 0, 0, 0, 0], []],      %% 列表1:[exp,gold,silver,coin,bcoin], 列表2:[{GoodsTypeId,GoodsNum}, ...]
        GiveList
    ),
    {ok, BinData} = pt_150:write(15081, [0, 0, GetExp, GetGold, GetSilver, GetCoin, GetBCoin, GetGoodsList]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData).

%% 重置连续登录天数 -> {result, Result}
reset_login_days(PlayerStatus) ->
    RoleId = PlayerStatus#player_status.id,
    Record = get_login_days_info(PlayerStatus),
    NowTime = util:unixtime(),
    {TodayMight, _NextMight} = util:get_midnight_seconds(NowTime),
    OldResetTime = Record#ets_login_counter.reset_time,
    case OldResetTime >= TodayMight of
        true ->     %% 重置过
            {result, 2};
        false ->
            NewRecord1 = correct_continuous_days(PlayerStatus, Record),
            Sql = io_lib:format(?sql_continuous_reset_time, [NowTime, RoleId]),
            case (catch db:execute(Sql) ) of
                {'EXIT', _} ->
                    {result, 0};
                _ ->
                    NewRecord =
                    NewRecord1#ets_login_counter{
                        continuous_days = 0,
                        reset_time = NowTime
                    },
%%                     io:format("bbb NewRecord=~p~n", [NewRecord]),
                    ets:insert(?ETS_LOGIN_COUNTER, NewRecord),
                    {result, 1}
            end
    end.

%% 检查领取时的等级
check_level_while_get_gift(PlayerStatus, Type) ->
    if
        Type =:= 2 ->   %% 回归礼包
            PlayerStatus#player_status.lv >= 45;
        true ->   %% 连续登录（0和1）
            PlayerStatus#player_status.lv >= 20
    end.

%% 修改充值状态，玩家充值时调用（玩家进程处理）
change_charge_status(PlayerStatus) ->
    case ets:lookup(?ETS_LOGIN_COUNTER, PlayerStatus#player_status.id) of
        [EtsLoginCounter] ->
            case EtsLoginCounter#ets_login_counter.is_charged =:= 0 of
                true ->     %% 需要改变状态
                    NewRecord = EtsLoginCounter#ets_login_counter{is_charged = 1},
                    ets:insert(?ETS_LOGIN_COUNTER, NewRecord),
                    {ok, BinData} = pt_310:write(31203, 1),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
                false ->
                    skip
            end;
        _ ->
            skip
    end.





%%======================================================================================================
%%　 获取累积登录信息
get_cumulative_login_info(RoleId, DailyPid, VipType)->
    TotalSignAddCount = data_cumulative_login:sign_add_count(VipType),
    UsedDropCount = mod_daily:get_count(DailyPid, RoleId, 7751),
    CumulativeInfo = chack_is_vip(RoleId, VipType),
    TotalDropCount = CumulativeInfo#cumulative_login.drop_count,
    DropCountLess = TotalDropCount - UsedDropCount, 
    SignCount = CumulativeInfo#cumulative_login.sign_count,
    UsedSignAddCount = CumulativeInfo#cumulative_login.used_sign_add_count,
    LoginWeekCount = CumulativeInfo#cumulative_login.login_week_count,
    Mouth = CumulativeInfo#cumulative_login.mouth,
    SignDaysList = CumulativeInfo#cumulative_login.sign_days,
    SignGiftList = CumulativeInfo#cumulative_login.gift_list, 
    LessSignAddCount = case TotalSignAddCount - UsedSignAddCount > 0 of
                           true -> TotalSignAddCount - UsedSignAddCount;
                           _ -> 0
                       end,
    [SignCount, LessSignAddCount, LoginWeekCount, DropCountLess, Mouth, SignDaysList, SignGiftList].
        

%%  签到
sign_days_op(RoleId, VipType, Type, OrderDay, Count) ->
    {_Y, _M, Day} = erlang:date(),
    TotalSignAddCount = data_cumulative_login:sign_add_count(VipType),
    
    CumulativeInfo = online(RoleId),
    SignCount = CumulativeInfo#cumulative_login.sign_count,
    UsedSignAddCount = CumulativeInfo#cumulative_login.used_sign_add_count,
    LessSignAddCount = TotalSignAddCount - UsedSignAddCount,
    SignDaysList = CumulativeInfo#cumulative_login.sign_days,
    SignGiftList = CumulativeInfo#cumulative_login.gift_list,
    IsTodaySign = lists:keyfind(Day, 1, SignDaysList),
    if
        VipType =< 0 andalso (Type =:= 2 orelse Type =:= 3) -> %% 不是vip，不能补签
            {ok, Bin} = pt_312:write(31206, [4]),
            {fail, Bin};
        
        SignCount < 0 andalso (Type =:= 2 orelse Type =:= 3) andalso Day =:= 1 -> %% 每月第一天不给补签操作
            {ok, Bin} = pt_312:write(31206, [6]),  
            {fail, Bin};
        IsTodaySign =/= false andalso Type =:= 1-> %% 今天已经签到
            {ok, Bin} = pt_312:write(31206, [7]), 
            {fail, Bin};
        OrderDay =:= Day andalso Type =:= 2 -> %% 今天不需要补签操作
            {ok, Bin} = pt_312:write(31206, [6]),
            {fail, Bin};
        SignCount =:= Day -> %% 签到天数等于当天的天数：说明签满了，每天都签到了
            {ok, Bin} = pt_312:write(31206, [5]),
            {fail, Bin};
        LessSignAddCount =< 0 andalso (Type =:= 2 orelse Type =:= 3) -> %% 补签次数为零
            {ok, Bin} = pt_312:write(31206, [8]), 
            {fail, Bin};
        Day < OrderDay andalso Type =:= 2 -> %% 补签时间大于今天，不能操作哦！！！
            {ok, Bin} = pt_312:write(31206, [9]), 
            {fail, Bin};
        SignCount < Day andalso Type =:= 1 andalso OrderDay =:= Day->   %% 今天可以签到
            NewSignDaysList = SignDaysList ++ [{Day, 1}],
            NewSignCount = SignCount + Count,
            NewSignGiftList = change_gift_state_get(SignGiftList, NewSignCount, VipType, 1),
            NewCumulativeInfo = update_cumulative_login_info(RoleId, CumulativeInfo, NewSignCount, 
                                                             UsedSignAddCount, NewSignDaysList, NewSignGiftList),
            put(?CUMULATIVE_LOGIN_KEY(RoleId), NewCumulativeInfo),
            pt_312:write(31206, [1]); 
        SignCount < Day andalso Type =:= 2 andalso OrderDay =/= Day ->  %% 可以补签（单次）
            NewSignCount = SignCount + Count,
            NewUsedSignAddCount = UsedSignAddCount + Count,
            NewSignDaysList = SignDaysList ++ [{OrderDay, 1}],
            NewSignGiftList = change_gift_state_get(SignGiftList, NewSignCount, VipType, 1),
            NewCumulativeInfo = update_cumulative_login_info(RoleId, CumulativeInfo, NewSignCount, 
                                                             NewUsedSignAddCount, NewSignDaysList, NewSignGiftList),
            put(?CUMULATIVE_LOGIN_KEY(RoleId), NewCumulativeInfo),
            pt_312:write(31206, [2]); 
        SignCount < Day andalso Type =:= 3 andalso OrderDay =/= Day ->  %% 可以补签多次
            {NewSignDaysList, UsedCount} = sign_days_add(SignDaysList, Count, Day),
            NewUsedSignAddCount =  UsedSignAddCount + UsedCount,
            NewSignCount = SignCount + UsedCount,
            NewSignGiftList = change_gift_state_get(SignGiftList, NewSignCount, VipType, 1),
            NewCumulativeInfo = update_cumulative_login_info(RoleId, CumulativeInfo, NewSignCount, 
                                                             NewUsedSignAddCount, NewSignDaysList, NewSignGiftList),
            put(?CUMULATIVE_LOGIN_KEY(RoleId), NewCumulativeInfo),
            pt_312:write(31206, [3]); 
        true -> 
            {ok, Bin} = pt_312:write(31206, [0]),
            {fail, Bin}
            
    end.
       

%%  签到领取物品
get_sign_goods(RoleId, GoodsPid, SignCount, GoodId, Type) ->
    CumulativeInfo = online(RoleId),
    SignGiftList = CumulativeInfo#cumulative_login.gift_list,
    CellNum = gen_server:call(GoodsPid, {'cell_num'}),
    case CellNum =< 0 of
        true -> [6, []];
        false ->
            case lists:keyfind(SignCount, 1, SignGiftList) of
                false -> [3, []];
                {SignCount, GoodList} ->
                     case lists:keyfind(GoodId, 1, GoodList) of
                        false -> [3, []];
                        {GoodId, Num, IsVip, IsGet} ->
                            case IsVip =:= Type of  %% 匹配是否是vip的物品()
                                false -> [3, []];
                                true ->
                                    if
                                        IsGet =:= 2 -> [4, []];
                                        IsGet =:= 0 -> [5, []];
                                        IsGet =/= 1 -> [3, []];
                                        true -> 
                                            case gen_server:call(GoodsPid, {'give_more_bind', [], [{GoodId, Num}]}) of
                                                ok -> 
                                                    NewGood = {GoodId, Num, IsVip, 2},
                                                    NewGoodList = lists:keyreplace(GoodId, 1, GoodList, NewGood),
                                                    NewSignGiftList = lists:keyreplace(SignCount, 1, SignGiftList, {SignCount, NewGoodList}),
                                                    NewCumulativeInfo = CumulativeInfo#cumulative_login{gift_list = NewSignGiftList},
                                                    put(?CUMULATIVE_LOGIN_KEY(RoleId), NewCumulativeInfo),
                                                    [1, [{SignCount, NewGoodList}]];
                                                _ ->
                                                   [0,[]]
                                            end
                                    end
                            end
                     end
            end
    end.


%% 获取翻牌的次数
get_total_drop_count(RoleId)->
    CumulativeInfo = online(RoleId),
    CumulativeInfo#cumulative_login.drop_count.


%% 获取翻牌奖励
get_drop_award(PS) ->
    RoleId = PS#player_status.id,
    DailyPid = PS#player_status.dailypid,
    GoodsPid = PS#player_status.goods#status_goods.goods_pid,
    FlipCount = get_total_drop_count(RoleId),
    CellNum = gen_server:call(PS#player_status.goods#status_goods.goods_pid, {'cell_num'}),
    case CellNum =< 0 of
        true -> {fail, 3};
        false ->
            case mod_daily:get_count(DailyPid, RoleId, 7751) >= FlipCount of
                true -> {fail, 2};    %%翻牌次數已滿
                false -> 
                    %% 发送奖励
                    %%　{_,_,GoodsList} = get_drop_goods(PS#player_status.lv),
                    GoodsList = case get(?FAN_PAI_KEY(RoleId)) of
                                    undefined -> data_cumulative_login:get_config(define_goods_list);
                                    GoodsList1 -> 
                                        GoodsList1
                                end,
                    %% GoodsList = get_drop_goods(PS#player_status.lv),
                    TotalRatio = lib_goods_util:get_ratio_total(GoodsList, 2),
                    Rand = util:rand(1, TotalRatio),
                    {{GoodsTypeId, Num}, _Ratio} = case lib_goods_util:find_ratio(GoodsList, 0, Rand, 2) of
                                                  null -> data_cumulative_login:get_config(define_goods);
                                                  GoodInfo -> GoodInfo
                                              end,
                    %% io:format("~p ~p {GoodsTypeId, Num}:~p, GoodsList:~p~n", [?MODULE, ?LINE, [{GoodsTypeId, Num}], GoodsList]),
                    case gen_server:call(GoodsPid, {'give_more_bind', PS, [{GoodsTypeId, Num}]}) of
                        ok -> 
                            mod_daily:increment(DailyPid, RoleId, 7751), 
%%                             case lists:member(GoodsTypeId, [601601,112231,122504]) of
%%                                 true ->
%%                                     lib_chat:send_TV({all}, 0, 2, ["fanpai", RoleId, PS#player_status.realm, PS#player_status.nickname, PS#player_status.sex, PS#player_status.career, PS#player_status.image,GoodsTypeId]);
%%                                 false -> []
%%                             end,
                            {ok, GoodsTypeId, Num};
                        _ -> {fail, 0}
                    end
            end
    end.  


online(RoleId)->
    case get(?CUMULATIVE_LOGIN_KEY(RoleId)) of
        undefined ->
            %% io:format("~p ~p undefined~n", [?MODULE, ?LINE]),
            reload(RoleId);
        Record ->
            case util:diff_day(Record#cumulative_login.time) > 0 of
                true -> 
                    reload(RoleId);
                false ->
                    Record
            end
    end.

%%　累积登录信息重载
reload(RoleId) ->
    NowTime = util:unixtime(),
    SeSQL = io_lib:format(?sql_select_cumulative_login_by_id, [RoleId]),
    CumulativeLoginInfo = db:get_all(SeSQL),
    {_Y, M, _D} = erlang:date(),
    case CumulativeLoginInfo of 
        [] ->
            LoginWeekCount = 1, %%默认登录一次
            DropCount = data_cumulative_login:get_drop_count(LoginWeekCount),   %%  翻牌次数
            SignGiftList = data_cumulative_login:get_sign_gift(),               %%  初始化签到物品 
            SSignGiftList = util:term_to_string(SignGiftList),                  
            ReSQL = io_lib:format(?sql_replace_cumulative_login_info, 
                                  [RoleId, M, 0, 0, LoginWeekCount, "[]", SSignGiftList, DropCount, NowTime]),
            db:execute(ReSQL),
            Value = #cumulative_login{role_id = RoleId,  mouth = M, gift_list = SignGiftList, login_week_count = LoginWeekCount, drop_count = DropCount},
            put(?CUMULATIVE_LOGIN_KEY(RoleId), Value),
            Value;
        _ ->
            [[Id, M1, SignCount, UsedSignAddCount, LoginWeekCount, SignDays, GiftList, _DropCount, Time]] = CumulativeLoginInfo,
            NewSignDays = util:bitstring_to_term(SignDays),
            NewGiftList = util:bitstring_to_term(GiftList),
            NewLoginWeekCount = data_cumulative_login:get_login_week_count(Time, LoginWeekCount),
            NewDropCount = data_cumulative_login:get_drop_count(LoginWeekCount),
            if
                M1 =/= M -> %% 换月
                    SignGiftList = data_cumulative_login:get_sign_gift(),       %%  初始化签到物品 
                    SSignGiftList = util:term_to_string(SignGiftList),
                    ReSQL = io_lib:format(?sql_replace_cumulative_login_info, 
                                          [RoleId, M, 0, 0, NewLoginWeekCount, "[]", SSignGiftList, NewDropCount, NowTime]),
                    db:execute(ReSQL),
                    Value = #cumulative_login{role_id = Id,  mouth = M, login_week_count = NewLoginWeekCount, 
                                              gift_list = SignGiftList, drop_count = NewDropCount, time = NowTime},
                    put(?CUMULATIVE_LOGIN_KEY(RoleId), Value),
                    Value;
                NewLoginWeekCount =/= LoginWeekCount -> %% 
                    ReSQL = io_lib:format(?sql_replace_cumulative_login_info, 
                                          [RoleId, M, SignCount, UsedSignAddCount, NewLoginWeekCount, 
                                           util:term_to_string(NewSignDays), util:term_to_string(NewGiftList), NewDropCount, NowTime]),
                    db:execute(ReSQL),
                    Value = #cumulative_login{role_id = Id, mouth = M,  
                                              sign_count = SignCount, 
                                              used_sign_add_count = UsedSignAddCount, 
                                              login_week_count = NewLoginWeekCount, 
                                              sign_days = NewSignDays, 
                                              gift_list = NewGiftList,
                                              drop_count = NewDropCount,
                                              time = NowTime},
                    put(?CUMULATIVE_LOGIN_KEY(RoleId), Value),
                    Value;
                true ->
                    Value = #cumulative_login{role_id = Id,  mouth = M,  
                                              sign_count = SignCount, 
                                              used_sign_add_count = UsedSignAddCount,
                                              login_week_count = NewLoginWeekCount, 
                                              sign_days = NewSignDays, 
                                              gift_list = NewGiftList, 
                                              drop_count = NewDropCount,
                                              time = Time},
                    put(?CUMULATIVE_LOGIN_KEY(RoleId), Value),
                    Value
            end
            
    end.

%% 登出
cumulative_logout(PS)->
    RoleId = PS#player_status.id,
    NowTime = util:unixtime(),
    CumulativeInfo = online(RoleId),
    SignCount = CumulativeInfo#cumulative_login.sign_count,
    M =  CumulativeInfo#cumulative_login.mouth,
    DropCount = CumulativeInfo#cumulative_login.drop_count,
    LoginWeekCount = CumulativeInfo#cumulative_login.login_week_count,
    SignDaysList = CumulativeInfo#cumulative_login.sign_days,
    SignGiftList = CumulativeInfo#cumulative_login.gift_list,
    UsedSignAddCount = CumulativeInfo#cumulative_login.used_sign_add_count,
    SSignDaysList = util:term_to_string(SignDaysList),
    SSignGiftList = util:term_to_string(SignGiftList),
    ReSQL = io_lib:format(?sql_replace_cumulative_login_info, 
                          [RoleId, M, SignCount, UsedSignAddCount, LoginWeekCount, SSignDaysList, SSignGiftList, DropCount, NowTime]),
    db:execute(ReSQL),
    erase(?CUMULATIVE_LOGIN_KEY(RoleId)).


%% 更新数据库和内存
update_cumulative_login_info(RoleId, CumulativeInfo, SignCount, UsedSignAddCount, SignDaysList, SignGiftList) ->
    NowTime = util:unixtime(),
    M =  CumulativeInfo#cumulative_login.mouth,
    DropCount = CumulativeInfo#cumulative_login.drop_count,
    LoginWeekCount = CumulativeInfo#cumulative_login.login_week_count,
    SSignDaysList = util:term_to_string(SignDaysList),
    SSignGiftList = util:term_to_string(SignGiftList),
    ReSQL = io_lib:format(?sql_replace_cumulative_login_info, 
                          [RoleId, M, SignCount, UsedSignAddCount, LoginWeekCount, SSignDaysList, SSignGiftList, DropCount, NowTime]),
    db:execute(ReSQL),
    CumulativeInfo#cumulative_login{sign_count = SignCount, used_sign_add_count = UsedSignAddCount, 
                                    sign_days = SignDaysList, gift_list = SignGiftList, time = NowTime}.
            


%%　给成为vip的时候调用(更新签到物品的领取状态)
chack_is_vip(RoleId, VipType) ->
    CumulativeInfo = online(RoleId),
    SignCount = CumulativeInfo#cumulative_login.sign_count,
    SignDaysList = CumulativeInfo#cumulative_login.sign_days,
    SignGiftList = CumulativeInfo#cumulative_login.gift_list,
    UsedSignAddCount = CumulativeInfo#cumulative_login.used_sign_add_count,
    NewSignGiftList = change_gift_state_get(SignGiftList, SignCount, VipType, 1),
    if
        SignGiftList =:= NewSignGiftList ->
            NewCumulativeInfo = CumulativeInfo;
        true ->
            NewCumulativeInfo = update_cumulative_login_info(RoleId, CumulativeInfo, SignCount, UsedSignAddCount, SignDaysList, NewSignGiftList)
    end,
    put(?CUMULATIVE_LOGIN_KEY(RoleId), NewCumulativeInfo),
    NewCumulativeInfo.


%%　根据等级获取翻牌物品
get_drop_goods(Lv) ->
     case Lv < 25 of
        true -> [];
        false -> 
            List = data_fan_pai:get_goods_by_lv(Lv),
            rand_goods_list(List)
    end.
%% get_drop_goods(Lv) ->
%%     case Lv < 25 of
%%         true -> [];
%%         false -> 
%%             L = data_cumulative_login:get_drop_goods_list(),
%%             case lists:filter(fun({Begin,End,_}) -> (Begin =< Lv) andalso (Lv =< End) end, L) of
%%                 [] -> [];
%%                 Any -> hd(Any)
%%             end
%%     end.


%% 一键补签次数（从第一天寻找没有签到的日期，添加进去，到count为止）
sign_days_add(SignDaysList, Count, Day) ->
    MouthDays = data_cumulative_login:get_mouth_days(),
    Fun = fun(D, [TempSignDaysList, TempCount]) ->
                  if
                      D >= Day ->  %% 大于等于今天的就不让他补签了
                          [TempSignDaysList, TempCount];
                      true ->
                          if
                              TempCount =:= Count ->
                                 [TempSignDaysList, TempCount];
                              true ->
                                 SignDay = {D, 1},
                                 case lists:member(SignDay, SignDaysList) of
                                    true ->
                                       [TempSignDaysList, TempCount];
                                    false ->
                                        [[SignDay|TempSignDaysList], TempCount+1]
                                 end
                          end
                  end
          end,        
    [NewSignDaysList, UsedCount] = lists:foldl(Fun, [SignDaysList, 0], MouthDays),
    {NewSignDaysList, UsedCount}.

    

%% Type 0|1|2
change_gift_state_get(SignGiftList, SignCount, VipType, GetType) ->
    List = data_cumulative_login:get_sign_good_days(SignCount),
    change_gift_state(List, SignGiftList, VipType, GetType).

change_gift_state([], SignGiftList, _VipType, _GetType) ->
    SignGiftList;
change_gift_state([SignCount|T], SignGiftList, VipType, GetType) ->                                                                
    case lists:keyfind(SignCount, 1, SignGiftList) of
        false ->
            change_gift_state(T, SignGiftList, VipType, GetType);
        {SignCount, GoodsList} ->
            if
                VipType > 0 ->
                    NewGoodsList = lists:map(fun({GoodId, Num, IsVip, _IsGet}) ->
                                                 case _IsGet of
                                                        2 -> {GoodId, Num, IsVip, _IsGet};
                                                        _ -> {GoodId, Num, IsVip, GetType}
                                                 end
                                             end, GoodsList),
                    NewSignCountTuple = {SignCount, NewGoodsList},
                    NewSignGiftList = lists:keyreplace(SignCount, 1, SignGiftList, NewSignCountTuple),
                    change_gift_state(T, NewSignGiftList, VipType, GetType);
                true -> 
                    Fun = fun(GoodsInfo, [NoVipGood, VipGood]) ->
                                {_GoodId, _Num, IsVip, _IsGet} = GoodsInfo,
                                case IsVip of
                                    0 -> 
                                        NewNoVipGood=[GoodsInfo|NoVipGood],
                                        [NewNoVipGood, VipGood];
                                    1 -> 
                                        NewVipGood = [GoodsInfo|VipGood],
                                        [NoVipGood, NewVipGood];
                                    _ ->
                                        [NoVipGood, VipGood]
                                end
                           end,
                    [NoVipGoodList, VipGoodList] = lists:foldl(Fun, [[], []], GoodsList),
                    %% 将不可领取的非vip物品变成可以领取的
                    NewNoVipGoodsList = lists:map(fun({GoodId, Num, IsVip, _IsGet}) ->
                                                     case _IsGet of
                                                        2 -> {GoodId, Num, IsVip, _IsGet};
                                                        _ -> {GoodId, Num, IsVip, GetType}
                                                     end
                                                  end, NoVipGoodList),
                    %% 将可领取的vip物品变成不可以领取的              
                    NewVipGoodsList = lists:map(fun({GoodId, Num, IsVip, _IsGet}) ->
                                                     case _IsGet of
                                                        1 -> {GoodId, Num, IsVip, 0};
                                                        2 -> {GoodId, Num, IsVip, _IsGet};
                                                        _ -> {GoodId, Num, IsVip, 0}
                                                     end
                                                  end, VipGoodList),
                    NewGoodsList = NewNoVipGoodsList ++ NewVipGoodsList,
                    NewSignCountTuple = {SignCount, NewGoodsList},
                    NewSignGiftList = lists:keyreplace(SignCount, 1, SignGiftList, NewSignCountTuple),
                    change_gift_state(T, NewSignGiftList, VipType, GetType)
            end
    end.
    

%% 随机取物品
rand_goods_list(GoodsList)->
    if
        GoodsList =:= [] ->
            %% util:errlog("~p ~p equip_gift_config_error!~n", [?MODULE, ?LINE]),
            data_cumulative_login:get_config(define_goods_list);
        true ->
            rand_goods_list(GoodsList, [], 0, 0)
    end.

rand_goods_list(_GoodsList, TempGoodsList, 9, _LoopCount)->
    TempGoodsList;
rand_goods_list(_GoodsList, TempGoodsList, _Count, 20)->
    case length(TempGoodsList) of
        9 ->
            TempGoodsList;
        _ ->
            List = data_cumulative_login:get_config(define_goods_list),
            %% 默认的转盘数据
            util:errlog("~p ~p get_define_list:~p~n", [?MODULE, ?LINE, List]),
            List
    end;
rand_goods_list(GoodsList, TempGoodsList, Count, LoopCount)->
    TotalRatio = lib_goods_util:get_ratio_total(GoodsList, 2),
    Rand = util:rand(1, TotalRatio),
    case lib_goods_util:find_ratio(GoodsList, 0, Rand, 2) of
        null -> 
            rand_goods_list(GoodsList, TempGoodsList, Count, LoopCount+1);
        GoodsInfo -> 
            NewTempGoodsList = [GoodsInfo | TempGoodsList],
            {GoodInfo, _Rate} = GoodsInfo,
            NewGoodsList = lists:keydelete(GoodInfo, 1, GoodsList),
            rand_goods_list(NewGoodsList, NewTempGoodsList, Count + 1, LoopCount+1)
    end.

    
tt(RoleId)->
    {_Y, M, _D} = erlang:date(), 
    NowTime = util:unixtime(),
    LoginWeekCount = 1, %%默认登录一次
    DropCount = data_cumulative_login:get_drop_count(LoginWeekCount),   %%  翻牌次数
    SignGiftList = data_cumulative_login:get_sign_gift(),               %%  初始化签到物品 
    SSignGiftList = util:term_to_string(SignGiftList),                  
    ReSQL = io_lib:format(?sql_replace_cumulative_login_info, 
                           [RoleId, M, 0, 0, LoginWeekCount, "[]", SSignGiftList, DropCount, NowTime]),
    db:execute(ReSQL),
    Value = #cumulative_login{role_id = RoleId,  mouth = M, gift_list = SignGiftList, login_week_count = LoginWeekCount, drop_count = DropCount},
    put(?CUMULATIVE_LOGIN_KEY(RoleId), Value),
    Value.
    
