%%%------------------------------------
%%% @Module  : lib_off_line
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2013.02.01
%%% @Description: 经验材料召回活动
%%%------------------------------------
-module(lib_off_line).
-export(
    [
        login_init/1,
        add_off_line_count/4,
        minus_off_line_count/1,
        update_list/1,
        get_off_line_award/4,
        activity_time/0,
		get_dungeon_exp/1,
        off_line_deal/4
    ]
).
-include("server.hrl").

%% 登录初始化
login_init([PlayerId, PlayerLv, Offline_time, StatusVip]) ->
    BeginTime = data_off_line:get_off_line_config(begin_time),
    EndTime = data_off_line:get_off_line_config(end_time),
    LastShowTime = data_off_line:get_off_line_config(last_show_time),
    case date() >= BeginTime andalso date() =< LastShowTime of
        true ->
            NowDate = util:unixdate(),
            EndUnixTime = case NowDate > util:unixtime({EndTime, {0, 0, 0}}) of
                true -> util:unixtime({EndTime, {0, 0, 0}}) + 24 * 3600;
                false -> NowDate
            end,
            RegTime = case db:get_row(io_lib:format(<<"select reg_time from player_login where id = ~p limit 1">>, [PlayerId])) of
                [_RegTime] -> _RegTime;
                _ -> 0
            end,
            BeginUnixTime = case RegTime > util:unixtime({BeginTime, {0, 0, 0}}) of
                true -> RegTime;
                false -> util:unixtime({BeginTime, {0, 0, 0}})
            end,
            %% 离线天数
            _OffLineDay = (EndUnixTime - BeginUnixTime) div (24 * 3600),
            OffLineDay = case _OffLineDay >= 0 of
                true -> _OffLineDay;
                false -> 0
            end,
            %%    1.皇榜任务
            %%    2.平乱任务
            %%    3.诛妖任务
            %%    4.经验副本
            %%    5.宠物副本
            %%    6.冬日温泉
            %%    7.蝴蝶谷/钓鱼
            %%    8.离线挂机
            %% {类型, 累计次数, 累计经验}
            Num1 = data_off_line:get_off_line_num([OffLineDay, 1]),
            Task1 = {1, Num1, data_off_line:get_off_line_exp([Num1, PlayerLv, 1, StatusVip])},
            Num2 = data_off_line:get_off_line_num([OffLineDay, 2]),
            Task2 = {2, Num2, data_off_line:get_off_line_exp([Num2, PlayerLv, 2, StatusVip])},
            Num3 = data_off_line:get_off_line_num([OffLineDay, 3]),
            Task3 = {3, Num3, data_off_line:get_off_line_exp([Num3, PlayerLv, 3, StatusVip])},
            Num4 = data_off_line:get_off_line_num([OffLineDay, 4]),
            Task4 = {4, Num4, data_off_line:get_off_line_exp([Num4, PlayerLv, 4, StatusVip])},
            Num5 = data_off_line:get_off_line_num([OffLineDay, 5]),
            Task5 = {5, Num5, data_off_line:get_off_line_exp([Num5, PlayerLv, 5, StatusVip])},
            Num6 = data_off_line:get_off_line_num([OffLineDay, 6]),
            Task6 = {6, Num6, data_off_line:get_off_line_exp([Num6, PlayerLv, 6, StatusVip])},
            Num7 = data_off_line:get_off_line_num([OffLineDay, 7]),
            Task7 = {7, Num7, data_off_line:get_off_line_exp([Num7, PlayerLv, 7, StatusVip])},
            Num8 = Offline_time,
            Task8 = {8, Num8, data_off_line:get_off_line_exp([Num8, PlayerLv, 8, StatusVip])},
            %%    9.单人九重天
            %%    10.多人九重天
            %%    11.单人炼狱副本
            %%    12.多人炼狱副本
            %%    13.蝴蝶谷/钓鱼
            %%    14.南天门
            %%    15.蟠桃会
            %%    16.跨服3v3
            %% {类型, 累计次数, 将获得材料礼包数, 回归后首次挑战成绩, 获得的对应礼包ID}
            Task9 = {9, data_off_line:get_off_line_num([OffLineDay, 9]), data_off_line:get_off_line_num([OffLineDay, 9]), 0, 0},
            Task10 = {10, data_off_line:get_off_line_num([OffLineDay, 10]), data_off_line:get_off_line_num([OffLineDay, 10]), 0, 0},
            Task11 = {11, data_off_line:get_off_line_num([OffLineDay, 11]), data_off_line:get_off_line_num([OffLineDay, 11]), 0, 0},
            Task12 = {12, data_off_line:get_off_line_num([OffLineDay, 12]), data_off_line:get_off_line_num([OffLineDay, 12]), 0, 0},
            Task13 = {13, data_off_line:get_off_line_num([OffLineDay, 13]), data_off_line:get_off_line_num([OffLineDay, 13]), 0, 0},
            Task14 = {14, data_off_line:get_off_line_num([OffLineDay, 14]), data_off_line:get_off_line_num([OffLineDay, 14]), 0, 0},
            Task15 = {15, data_off_line:get_off_line_num([OffLineDay, 15]), 0, 0, 0},
            Task16 = {16, data_off_line:get_off_line_num([OffLineDay, 16]), 0, 0, 0},
            TaskList = [Task1, Task2, Task3, Task4, Task5, Task6, Task7, Task8, Task9, Task10, Task11, Task12, Task13, Task14, Task15, Task16],
            TaskList2 = read_from_db(TaskList, PlayerId, PlayerLv, StatusVip, BeginUnixTime, EndUnixTime, RegTime),
            TaskList2;
        false ->
            []
    end.

%% 从数据库取数据
read_from_db(TaskList, PlayerId, PlayerLv, StatusVip, BeginUnixTime, EndUnixTime, RegTime) ->
    case db:get_all(io_lib:format(<<"select type_id, sum(cul_num), last_level from log_off_line_award where player_id = ~p and last_time > ~p and last_time < ~p group by type_id, last_level">>, [PlayerId, BeginUnixTime, EndUnixTime])) of
        [] ->
            TaskList;
        DbList when is_list(DbList) ->
            %io:format("DbList:~p~n", [DbList]),
            TaskList2 = update_list(TaskList, DbList, PlayerId, PlayerLv, StatusVip, RegTime),
            TaskList2;
        _ ->
            TaskList
    end.

update_list(TaskList, [], _PlayerId, _PlayerLv, _StatusVip, _RegTime) -> TaskList;
update_list(TaskList, [H | T], PlayerId, PlayerLv, StatusVip, RegTime) ->
   case H of
       [TypeId, CulNum, LastLevel] ->
           case TypeId < 9 of
               true ->
                   case TypeId of
                       8 ->
                           TaskList2 = TaskList;
                       _ ->
                           TaskList2 = update_list2(TaskList, PlayerId, PlayerLv, TypeId, CulNum, StatusVip, RegTime)
                   end;
               false ->
                   TaskList2 = update_list3(TaskList, TypeId, CulNum, LastLevel, PlayerLv, RegTime)
           end;
       _ ->
           TaskList2 = TaskList
   end,
   update_list(TaskList2, T, PlayerId, PlayerLv, StatusVip, RegTime).

%% {类型, 累计次数, 累计经验}
update_list2(TaskList, PlayerId, PlayerLv, TypeId, CulNum, StatusVip, RegTime) ->
    case lists:keyfind(TypeId, 1, TaskList) of
        false -> TaskList;
        Element ->
            BeginTime = data_off_line:get_off_line_config(begin_time),
            EndTime = data_off_line:get_off_line_config(end_time),
            _BeginUnixTime = util:unixtime({BeginTime, {0, 0, 0}}),
            BeginUnixTime = case _BeginUnixTime > RegTime of
                true -> _BeginUnixTime;
                false -> RegTime
            end,
            EndUnixTime = case util:unixdate() > util:unixtime({EndTime, {0, 0, 0}}) of
                true -> util:unixtime({EndTime, {0, 0, 0}}) + 24 * 3600;
                false -> util:unixdate()
            end,
            %% 计算天数
            TotalDay = (EndUnixTime - BeginUnixTime) div (24 * 3600),
            %% 总次数
            TotalNum = data_off_line:get_off_line_num([TotalDay, TypeId]),
            DailyType = data_off_line:get_off_line_config(daily_type) + TypeId,
            DailyNum = mod_daily_dict:get_count(PlayerId, DailyType),
            %io:format("~p~n", [{TotalNum, CulNum, DailyNum}]),
            _LeavingNum = TotalNum - CulNum + DailyNum,
            LeavingNum = case _LeavingNum > 0 of
                true -> _LeavingNum;
                false -> 0
            end,
            %% 计算总经验
            TotalExp = data_off_line:get_off_line_exp([LeavingNum, PlayerLv, TypeId, StatusVip]),
            TaskList2 = lists:delete(Element, TaskList),
            [{TypeId, LeavingNum, TotalExp} | TaskList2]
    end.

%% {类型, 累计次数, 将获得材料礼包数, 回归后首次挑战成绩, 获得的对应礼包ID}
update_list3(TaskList, TypeId, CulNum, LastLevel, PlayerLv, RegTime) ->
    case lists:keyfind(TypeId, 1, TaskList) of
        false -> TaskList;
        Element ->
            BeginTime = data_off_line:get_off_line_config(begin_time),
            EndTime = data_off_line:get_off_line_config(end_time),
            _BeginUnixTime = util:unixtime({BeginTime, {0, 0, 0}}),
            BeginUnixTime = case _BeginUnixTime > RegTime of
                true -> _BeginUnixTime;
                false -> RegTime
            end,
            EndUnixTime = case util:unixdate() > util:unixtime({EndTime, {0, 0, 0}}) of
                true -> util:unixtime({EndTime, {0, 0, 0}}) + 24 * 3600;
                false -> util:unixdate()
            end,
            %% 计算天数
            TotalDay = (EndUnixTime - BeginUnixTime) div (24 * 3600),
            %% 总次数
            TotalNum = data_off_line:get_off_line_num([TotalDay, TypeId]),
            %% 累计次数
            _LeavingNum = TotalNum - CulNum,
            LeavingNum = case _LeavingNum > 0 of
                true -> _LeavingNum;
                false -> 0
            end,
            AwardNum = case TypeId of
                15 -> LastLevel * LeavingNum;
                16 -> (LastLevel * LeavingNum) div 2;
                _ -> 1 * LeavingNum
            end,
            TaskList2 = lists:delete(Element, TaskList),
            GoodsId = data_off_line:get_off_line_award(TypeId, LastLevel, PlayerLv),
            [{TypeId, LeavingNum, AwardNum, LastLevel, GoodsId} | TaskList2]
    end.

%% 给外部用的接口
add_off_line_count(PlayerId, TypeId, Num, NowLevel) ->
    BeginTime = data_off_line:get_off_line_config(begin_time),
    EndTime = data_off_line:get_off_line_config(end_time),
    LastShowTime = data_off_line:get_off_line_config(last_show_time),
    Date = date(),
    NowTime = util:unixtime(),
    NowDate = util:unixdate(),
    spawn(fun() ->
                case db:get_row(io_lib:format(<<"select * from log_off_line_award where player_id = ~p and type_id = ~p and last_time > ~p limit 1">>, [PlayerId, TypeId, NowDate])) of
                    [] ->
                        db:execute(io_lib:format(<<"insert into log_off_line_award set player_id = ~p, type_id = ~p, cul_num = ~p, last_time = ~p, last_level = ~p">>, [PlayerId, TypeId, Num, NowTime, NowLevel]));
                    _ ->
                        db:execute(io_lib:format(<<"update log_off_line_award set cul_num = cul_num + ~p, last_time = ~p, last_level = ~p where player_id = ~p and type_id = ~p and last_time > ~p">>, [Num, NowTime, NowLevel, PlayerId, TypeId, NowDate]))
                end,
                case Date >= BeginTime andalso Date =< LastShowTime of
                    true ->
                        case Date >= BeginTime andalso Date =< EndTime of
                            true ->
                                DailyType = data_off_line:get_off_line_config(daily_type) + TypeId,
                                mod_daily_dict:plus_count(PlayerId, DailyType, Num),
                                update_db(Num, NowLevel, PlayerId, TypeId);
                            false ->
                                update_db(0, NowLevel, PlayerId, TypeId)
                        end;
                    false ->
                        skip
                end
        end).

update_db(Num, NowLevel, PlayerId, TypeId) ->
    %% 9-16自动领奖
    case TypeId >= 9 of
        true ->
            %% 判断玩家是否在线
            case misc:get_player_process(PlayerId) of
                PlayerPid when is_pid(PlayerPid) ->
                    lib_player:update_player_info(PlayerId, [{minus_off_line_count, {TypeId, Num, NowLevel}}]);
                _ ->
                    mod_disperse:rpc_cast_by_id(10, lib_off_line, off_line_deal, [PlayerId, TypeId, Num, NowLevel])
                    %off_line_deal(PlayerId, TypeId, Num, NowLevel)
            end;
        false ->
            skip
    end.

%% 减少数量（领取离线经验）
minus_off_line_count([PlayerId, Type, Num, Level]) ->
    lib_player:update_player_info(PlayerId, [{minus_off_line_count, {Type, Num, Level}}]).

%% 更新列表
update_list([OffLineAward, TypeId, Num, NowLevel, PlayerLv, PlayerId, StatusVip]) ->
    case lists:keyfind(TypeId, 1, OffLineAward) of
        false -> 
            OffLineAward;
        Element ->
            %io:format("Element:~p~n", [Element]),
            case Element of
                {TypeId, CulNum, _CulExp} ->
                    case Num > 0 of
                        true ->
                            NowTime = util:unixtime(),
                            EndTime = util:unixtime({data_off_line:get_off_line_config(end_time), {0, 0, 0}}),
                            FinTime = case NowTime > EndTime + 24 * 3600 of
                                true ->
                                    EndTime;
                                false ->
                                    util:unixdate() - 24 * 3600
                            end,
                            db:execute(io_lib:format(<<"insert into log_off_line_award set player_id = ~p, type_id = ~p, cul_num = ~p, last_time = ~p, last_level = ~p">>, [PlayerId, TypeId, Num, FinTime, NowLevel]));
                        false ->
                            skip
                    end,
                    _CulNum2 = CulNum - Num,
                    CulNum2 = case _CulNum2 > 0 of
                        true -> _CulNum2;
                        false -> 0
                    end,
                    CulExp2 = data_off_line:get_off_line_exp([CulNum2, PlayerLv, TypeId, StatusVip]),
                    OffLineAward2 = lists:delete(Element, OffLineAward),
                    [{TypeId, CulNum2, CulExp2} | OffLineAward2];
                {TypeId, CulNum, _CulAwardNum, _Level, _GoodsId} ->
                    Level = NowLevel,
                    NewNum = case TypeId of
                        15 -> Level * CulNum;
                        16 -> (Level * CulNum) div 2;
                        _ -> CulNum
                    end,
                    NeedGoodsId = data_off_line:get_off_line_award(TypeId, Level, PlayerLv),
                    %io:format("PlayerId:~p, NeedGoodsId:~p, NewNum:~p~n", [PlayerId, NeedGoodsId, NewNum]),
                    case NeedGoodsId of
                        0 ->
                            skip;
                        %% 发邮件
                        _ ->
                            Title = case TypeId of
                                9 -> data_off_line:get_off_line_text(1);
                                10 -> data_off_line:get_off_line_text(2);
                                11 -> data_off_line:get_off_line_text(3);
                                12 -> data_off_line:get_off_line_text(4);
                                13 -> data_off_line:get_off_line_text(9);
                                14 -> data_off_line:get_off_line_text(10);
                                15 -> data_off_line:get_off_line_text(11);
                                16 -> data_off_line:get_off_line_text(12)
                            end,
                            Content = case TypeId of
                                9 -> io_lib:format(data_off_line:get_off_line_text(5), [CulNum, Level, NewNum]);
                                10 -> io_lib:format(data_off_line:get_off_line_text(6), [CulNum, Level, NewNum]);
                                11 -> io_lib:format(data_off_line:get_off_line_text(7), [CulNum, Level, NewNum]);
                                12 -> io_lib:format(data_off_line:get_off_line_text(8), [CulNum, Level, NewNum]);
                                13 -> io_lib:format(data_off_line:get_off_line_text(13), [CulNum, NewNum]);
                                14 -> io_lib:format(data_off_line:get_off_line_text(14), [CulNum, NewNum]);
                                15 -> io_lib:format(data_off_line:get_off_line_text(15), [CulNum, NewNum]);
                                16 -> io_lib:format(data_off_line:get_off_line_text(16), [CulNum, NewNum])
                            end,
                            case NewNum of
                                0 ->
                                    skip;
                                _ ->
                                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PlayerId], Title, Content, NeedGoodsId, 2, 0, 0, NewNum, 0, 0, 0, 0]),
                                    NowTime = util:unixtime(),
                                    EndTime = util:unixtime({data_off_line:get_off_line_config(end_time), {0, 0, 0}}),
                                    FinTime = case NowTime > EndTime + 24 * 3600 of
                                        true ->
                                            EndTime;
                                        false ->
                                            util:unixdate() - 24 * 3600
                                    end,
                                    db:execute(io_lib:format(<<"insert into log_off_line_award set player_id = ~p, type_id = ~p, cul_num = ~p, last_time = ~p, last_level = ~p">>, [PlayerId, TypeId, CulNum, FinTime, NowLevel]))
                            end
                    end,
                    OffLineAward2 = lists:delete(Element, OffLineAward),
                    [{TypeId, 0, 0, NowLevel, NeedGoodsId} | OffLineAward2];
                _ ->
                    OffLineAward
            end
    end.

%% 领奖
get_off_line_award(PlayerStatus, TypeId, Num, CostType) -> 
    OffLineAward = PlayerStatus#player_status.off_line_award,
    case lists:keyfind(TypeId, 1, OffLineAward) of
        %% 失败，没有该类型任务!
        false ->
            Res = 2,
            Str = data_off_line_text:get_off_line_error_text(1),
            NewPlayerStatus = PlayerStatus;
        Element ->
            case Element of
                {TypeId, CulNum, _CulExp} ->
                    case CulNum >= Num of
                        true ->
                            case CostType of
                                %% 免费领取
                                1 ->
                                    Res = 1,
                                    _GetExp = data_off_line:get_off_line_exp([Num, PlayerStatus#player_status.lv, TypeId, PlayerStatus#player_status.vip]),
                                    GetExp = case _GetExp > 0 of
                                        true -> _GetExp;
                                        false -> 0
                                    end,
                                    %io:format("GetExp:~p~n", [GetExp]),
                                    CulExp2 = round(GetExp * 0.6),
                                    Str = io_lib:format(data_off_line_text:get_off_line_error_text(3), [CulExp2]),
                                    _NewPlayerStatus = lib_player:add_exp(PlayerStatus, CulExp2),
                                    NewOffLineAward = update_list([OffLineAward, TypeId, Num, 0, PlayerStatus#player_status.lv, PlayerStatus#player_status.id, PlayerStatus#player_status.vip]),
                                    case TypeId of
                                        %% 清空离线时间
                                        8 ->
                                            %%清空对应时间
                                            Time = PlayerStatus#player_status.offline_time,
                                            NowTime = util:unixtime(),
                                            _OffLineTime = Time - Num,
                                            OffLineTime = case _OffLineTime > 0 of
                                                true -> _OffLineTime;
                                                false -> 0
                                            end,
                                            _NewPlayerStatus2 = _NewPlayerStatus#player_status{offline_time=OffLineTime,last_logout_time=NowTime},
                                            lib_player:update_player_login_offline_time(_NewPlayerStatus2#player_status.id, OffLineTime, NowTime);
                                        _ ->
                                            %case db:get_row(io_lib:format(<<"select cul_num from off_line_award where player_id = ~p and type_id = ~p limit 1">>, [PlayerStatus#player_status.id, TypeId])) of
                                            %    [] ->
                                            %        db:execute(io_lib:format(<<"insert into off_line_award set player_id = ~p, type_id = ~p, cul_num = ~p, last_time = ~p">>, [PlayerStatus#player_status.id, TypeId, Num, util:unixtime()]));
                                            %    [DBCulNum] ->
                                            %        io:format("DBCulNum:~p, Num:~p~n", [DBCulNum, Num]),
                                            %        TolCulNum = DBCulNum + Num,
                                            %        db:execute(io_lib:format(<<"update off_line_award set cul_num = ~p, last_time = ~p where player_id = ~p and type_id = ~p">>, [TolCulNum, util:unixtime(), PlayerStatus#player_status.id, TypeId]))
                                            %end,
                                            _NewPlayerStatus2 = _NewPlayerStatus
                                    end,
                                    NewPlayerStatus = _NewPlayerStatus2#player_status{
                                        off_line_award = NewOffLineAward
                                    };
                                %% 物品领取
                                _ ->
                                    GoodsTypeId = data_off_line:get_off_line_config(goods_type_id),
                                    BackNum = mod_other_call:get_goods_num(PlayerStatus, GoodsTypeId, 0),
                                    PerNum = data_off_line:get_per_goods_num(TypeId),
                                    NeedNum = PerNum * Num,
                                    case BackNum >= NeedNum of
                                        true ->
                                            %% 物品消耗日志
                                            lib_player:update_player_info(PlayerStatus#player_status.id, [{use_goods, {GoodsTypeId, NeedNum}}]),
                                            log:log_goods_use(PlayerStatus#player_status.id, GoodsTypeId, NeedNum),
                                            Res = 1,
                                            _GetExp = data_off_line:get_off_line_exp([Num, PlayerStatus#player_status.lv, TypeId, PlayerStatus#player_status.vip]),
                                            GetExp = case _GetExp > 0 of
                                                true -> _GetExp;
                                                false -> 0
                                            end,
                                            Str = io_lib:format(data_off_line_text:get_off_line_error_text(4), [NeedNum, GetExp]),
                                            _NewPlayerStatus = lib_player:add_exp(PlayerStatus, GetExp),
                                            NewOffLineAward = update_list([OffLineAward, TypeId, Num, 0, PlayerStatus#player_status.lv, PlayerStatus#player_status.id, PlayerStatus#player_status.vip]),
                                            case TypeId of
                                                %% 清空离线时间
                                                8 ->
                                                    %%清空对应时间
                                                    Time = PlayerStatus#player_status.offline_time,
                                                    NowTime = util:unixtime(),
                                                    _OffLineTime = Time - Num,
                                                    OffLineTime = case _OffLineTime > 0 of
                                                        true -> _OffLineTime;
                                                        false -> 0
                                                    end,
                                                    _NewPlayerStatus2 = _NewPlayerStatus#player_status{offline_time=OffLineTime,last_logout_time=NowTime},
                                                    lib_player:update_player_login_offline_time(_NewPlayerStatus2#player_status.id, OffLineTime, NowTime);
                                                _ ->
                                                    %case db:get_row(io_lib:format(<<"select cul_num from off_line_award where player_id = ~p and type_id = ~p limit 1">>, [PlayerStatus#player_status.id, TypeId])) of
                                                    %    [] ->
                                                    %        db:execute(io_lib:format(<<"insert into off_line_award set player_id = ~p, type_id = ~p, cul_num = ~p, last_time = ~p">>, [PlayerStatus#player_status.id, TypeId, Num, util:unixtime()]));
                                                    %    [DBCulNum] ->
                                                    %        TolCulNum = DBCulNum + Num,
                                                    %        db:execute(io_lib:format(<<"update off_line_award set cul_num = ~p, last_time = ~p where player_id = ~p and type_id = ~p">>, [TolCulNum, util:unixtime(), PlayerStatus#player_status.id, TypeId]))
                                                    %end,
                                                    _NewPlayerStatus2 = _NewPlayerStatus
                                            end,
                                            NewPlayerStatus = _NewPlayerStatus2#player_status{
                                                off_line_award = NewOffLineAward
                                            };
                                        %% 失败，如意令数量不足!
                                        false ->
                                            Res = 2,
                                            Str = data_off_line_text:get_off_line_error_text(5),
                                            NewPlayerStatus = PlayerStatus
                                    end
                            end;
                        %% 失败，超出最大兑换值!
                        false ->
                            Res = 2,
                            Str = data_off_line_text:get_off_line_error_text(2),
                            NewPlayerStatus = PlayerStatus
                    end;
                %% 失败，没有该类型任务!
                _ ->
                    Res = 2,
                    Str = data_off_line_text:get_off_line_error_text(1),
                    NewPlayerStatus = PlayerStatus
            end
    end,
    {Res, Str, NewPlayerStatus}.

%% 是否为活动时间
activity_time() ->
    BeginTime = data_off_line:get_off_line_config(begin_time),
    EndTime = data_off_line:get_off_line_config(end_time),
	NowTime = date(),
    (NowTime >= BeginTime andalso NowTime =< EndTime).

%% 得到副本的活动经验.
get_dungeon_exp(PlayerStatus) ->
	SceneId = PlayerStatus#player_status.scene,
	case lists:member(SceneId, [233, 630]) of
		true ->
			case activity_time() of
				true ->
					1.2;
				_ ->
					1
			end;
		_ ->
			1
	end.

%% 玩家不在线，自动发材料召回
off_line_deal(PlayerId, TypeId, Num, NowLevel) ->
    [_NickName, _Sex, Lv, _Career, _Realm, _GuildId, _Mount_limit, _HusongNpc, _Image|_] = lib_player:get_player_low_data(PlayerId),
    StatusVip = #status_vip{},
    Offline_time = 0,
    OffLineAward = login_init([PlayerId, Lv, Offline_time, StatusVip]),
    update_list([OffLineAward, TypeId, Num, NowLevel, Lv, PlayerId, StatusVip]).
