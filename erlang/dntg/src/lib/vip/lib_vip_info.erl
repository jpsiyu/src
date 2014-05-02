%%%------------------------------------
%%% @Module  : lib_vip_info
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.12.12
%%% @Description: VIP新版
%%%------------------------------------
-module(lib_vip_info).
-export([
        login_cul/1,
        add_growth_exp/2,
        get_growth_lv/1,
        get_next_week_day/0
    ]).
-include("server.hrl"). 

%% 
login_cul([Id, Dailypid, VipGrowthExp, VipTime, Vip, OldWeekNum, LoginNum, VipGetAward]) ->
    %% 是否今天第一次登录
    case mod_daily:get_count(Dailypid, Id, 12001) of
        %% 第一次登录
        0 ->
            %% 增加或减少VIP成长经验
            %% 判断VIP是否已过期
            case VipTime >= util:unixtime() andalso Vip > 0 of
                %% 未过期
                true ->
                    case Vip of
                        3 -> 
                            mod_daily:increment(Dailypid, Id, 12001),
                            AddPoint = data_vip_new:add_growth_exp(VipGrowthExp);
                        _ ->
                            AddPoint = 0
                    end,
                    _NewVipGrowthExp = VipGrowthExp + AddPoint;
                %% 已过期
                false ->
                    mod_daily:increment(Dailypid, Id, 12001),
                    MinusPoint = data_vip_new:minus_growth_exp(VipGrowthExp),
                    _NewVipGrowthExp = VipGrowthExp - MinusPoint
            end,
            %% 本周登录天数加1
            {_Year, NowWeekNum} = calendar:iso_week_number(),
            %% 是否同一周
            NewLoginNum = case OldWeekNum =:= NowWeekNum of
                %% 同一周，登录天数加1
                true ->
                    _NewLoginNum = LoginNum + 1,
                    %io:format("_NewLoginNum:~p~n", [_NewLoginNum]),
                    db:execute(io_lib:format(<<"update vip_info set login_num = ~p where id = ~p">>, [_NewLoginNum, Id])),
                    NewVipGetAward = VipGetAward,
                    _NewLoginNum;
                %% 不同周，登录天数清空为1，设置玩家未领取周礼包
                false ->
                    %io:format("1~n"),
                    NewVipGetAward = 0,
                    db:execute(io_lib:format(<<"update vip_info set weeknum = ~p, login_num = 1, get_award = 0 where id = ~p">>, [NowWeekNum, Id])),
                    1
            end;
        %% 不是第一次登录
        _ ->
            NewLoginNum = LoginNum,
            NewVipGetAward = VipGetAward,
            _NewVipGrowthExp = VipGrowthExp
    end,
    %% 防0溢出
    NewVipGrowthExp = case _NewVipGrowthExp > 0 of
        true -> _NewVipGrowthExp;
        false -> 0
    end,
    %io:format("NewVipGrowthExp:~p~n", [NewVipGrowthExp]),
    %% 更新数据库
    db:execute(io_lib:format(<<"update vip_info set growth_exp = ~p where id = ~p">>, [NewVipGrowthExp, Id])),
    [NewVipGrowthExp, NewLoginNum, NewVipGetAward].

%% 增加成长经验
add_growth_exp(PlayerId, AddValue) when is_integer(PlayerId) ->
    lib_player:update_player_info(PlayerId, [{add_growth_exp, AddValue}]),
    ok;
%% 增加成长经验
add_growth_exp(Status, AddValue) when is_record(Status, player_status) ->
    StatusVip = Status#player_status.vip,
    case StatusVip#status_vip.vip_type of
        3 ->
            GrowthExp = StatusVip#status_vip.growth_exp,
            NewValue = GrowthExp + AddValue,
            Lv = data_vip_new:get_growth_lv(GrowthExp),
            NewLv = data_vip_new:get_growth_lv(NewValue),
            NewStatusVip = case NewLv > Lv of
                true ->
                    db:execute(io_lib:format(<<"update vip_info set get_award = 0 where id = ~p">>, [Status#player_status.id])),
                    StatusVip#status_vip{
                        growth_exp = NewValue,
                        growth_lv = NewLv,
                        get_award = 0
                    };
                false ->
                    StatusVip#status_vip{
                        growth_exp = NewValue,
                        growth_lv = NewLv
                    }
            end,
            NextExp = data_vip_new:get_next_exp(NewValue),
            _RestTime = Status#player_status.vip#status_vip.vip_end_time - util:unixtime(),
            RestTime = case _RestTime > 0 of
                true -> _RestTime;
                false -> 0
            end,
            DailyAdd = data_vip_new:add_growth_exp(GrowthExp),
            {ok, BinData} = pt_450:write(45016, [NewValue, NextExp, NewLv, RestTime, DailyAdd]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            %% 更新数据库
            db:execute(io_lib:format(<<"update vip_info set growth_exp = ~p where id = ~p">>, [NewValue, Status#player_status.id])),
            NewStatus = Status#player_status{vip = NewStatusVip},
            %% 是否移除世界等级图标
            case NewLv =/= StatusVip#status_vip.growth_lv of
                true -> 
                    lib_rank_helper:world_remove_buff(NewStatus);
                false ->
                    skip
            end,
            NewStatus;
        _ ->
            Status
    end.

%% 获取玩家VIP成长等级
get_growth_lv(PlayerId) ->
    case lib_player:get_player_info(PlayerId, vip_growth_lv) of
        GrowthLv when is_integer(GrowthLv) ->
            GrowthLv;
        _ ->
            0
    end.

%% 获取下周一的日期
get_next_week_day() ->
    WeekDay = calendar:day_of_the_week(date()),
    Day = 8 - WeekDay,
    UnixTime = util:unixdate() + Day * 24 * 60 * 60,
    {{NextYear, NextMonth, NextDay}, _} = util:seconds_to_localtime(UnixTime),
    lists:concat([NextYear, "-", NextMonth, "-", NextDay]).

