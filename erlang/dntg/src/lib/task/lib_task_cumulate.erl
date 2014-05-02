%%%------------------------------------
%%% @Module  : li_task_cumulate
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.7.31
%%% @Description: 功能累积(离线经验累积)
%%%------------------------------------
-module(lib_task_cumulate).
-include("task.hrl").
-include("server.hrl").
-compile(export_all).

%% 用户登录时初始化数据
server_login(PlayerStatus) -> 
    TaskIdList = data_task_cumulate:get_task_cumulate_data(task_id_list),
    check_task_list(TaskIdList, PlayerStatus).

%% 用户退出时回写数据库
server_logout(_PlayerStatus) -> 
    skip.
%%    TaskIdList = data_task_cumulate:get_task_cumulate_data(task_id_list),
%%    rewrite_task(TaskIdList, PlayerStatus).

%% 用户完成任务处理
finish_task(RoleId, TaskId) ->
    case TaskId > length(data_task_cumulate:get_task_cumulate_data(task_id_list)) of
        false ->
            case mod_task_cumulate:lookup_task(RoleId, TaskId) of
                %% 内存无记录
                undefined ->
                    skip;
                %% 内存有记录
                TaskCumulate when is_record(TaskCumulate, task_cumulate) -> 
                    %% 判断今天是否已完成任务
                    case TaskCumulate#task_cumulate.last_finish_time =:= util:unixdate() of
                        true -> skip;
                        false ->
                            %% 修改内存
                            mod_task_cumulate:insert_task(TaskCumulate#task_cumulate{last_finish_time=util:unixdate()}),
                            %% 插入数据库
                            SQL1 = io_lib:format(?SQL_SELECT_TASK_HIS, [RoleId, TaskId]),
                            case db:get_row(SQL1) of
                                %% 数据库无记录
                                [] ->   %%无记录，新插入
                                    SQL2 = io_lib:format(?SQL_INSECT_UPDATE_TASK_HIS, [RoleId, TaskId, TaskCumulate#task_cumulate.offline_day, util:unixdate(), TaskCumulate#task_cumulate.cucm_exp, TaskCumulate#task_cumulate.offline_day, util:unixdate(), TaskCumulate#task_cumulate.cucm_exp]),
                                    db:execute(SQL2);
                                [_OfflineDay, _LastFinishTime, _CucmExp] ->  %% 有记录，更新数据
                                    SQL2 = io_lib:format(?SQL_UPDATE_TASK_HIS, [TaskCumulate#task_cumulate.offline_day, util:unixdate(), TaskCumulate#task_cumulate.cucm_exp, RoleId, TaskId]),
                                    db:execute(SQL2);
                                Any -> 
                                    catch util:errlog("Error!!lib_task_cumulate:finish_task: ~p !! ~n", [Any])
                            end
                    end;
                Any -> catch util:errlog("Error!!lib_task_cumulate:finish_task: ~p !! ~n", [Any])
            end;
        true ->
            skip
    end.

%% 用户领取离线累积经验
%% 返回经验值: int
cumulate_exp(RoleId, TaskId) ->
    case TaskId > length(data_task_cumulate:get_task_cumulate_data(task_id_list)) of
        false ->
            %% 获得多少经验
            case mod_task_cumulate:lookup_task(RoleId, TaskId) of
                %% 内存无记录
                undefined ->
                    [0, 0];
                %% 内存有记录
                TaskCumulate when is_record(TaskCumulate, task_cumulate) -> 
                    %% 是否有可领取的离线经验(先从内存判断，防止被刷)
                    case TaskCumulate#task_cumulate.offline_day > 0 andalso TaskCumulate#task_cumulate.cucm_exp > 0 of
                        true ->
                            [TaskCumulate#task_cumulate.cucm_exp, TaskCumulate#task_cumulate.offline_day];
                        false -> 
                            [0, 0]
                    end;
                Any -> 
                    catch util:errlog("Error!!lib_task_cumulate:award_cumulate_exp: ~p !! ~n", [Any]),
                    [0, 0]
            end;
        true ->
            [0, 0]
    end.

%% 用户领取离线累积经验
%% 返回经验值: int
award_cumulate_exp(RoleId, TaskId) ->
    case TaskId > length(data_task_cumulate:get_task_cumulate_data(task_id_list)) of
        false ->
            %% 获得多少经验
            case mod_task_cumulate:lookup_task(RoleId, TaskId) of
                %% 内存无记录
                undefined ->
                    0;
                %% 内存有记录
                TaskCumulate when is_record(TaskCumulate, task_cumulate) -> 
                    %% 是否有可领取的离线经验(先从内存判断，防止被刷)
                    case TaskCumulate#task_cumulate.offline_day > 0 andalso TaskCumulate#task_cumulate.cucm_exp > 0 of
                        true ->
                            LastFinishTime = case TaskCumulate#task_cumulate.last_finish_time > util:unixdate() - 86400 of
                                true -> TaskCumulate#task_cumulate.last_finish_time;
                                false -> util:unixdate() - 86400
                            end,
                            %% 修改内存
                            mod_task_cumulate:insert_task(TaskCumulate#task_cumulate{offline_day=0,last_finish_time=LastFinishTime,cucm_exp=0}),
                            SQL1 = io_lib:format(?SQL_SELECT_TASK_HIS, [RoleId, TaskId]),
                            case db:get_row(SQL1) of
                                %% 数据库无记录
                                [] ->   %%无记录，新插入
                                    SQL2 = io_lib:format(?SQL_INSECT_UPDATE_TASK_HIS, [RoleId, TaskId, 0, LastFinishTime, 0, 0, LastFinishTime, 0]),
                                    db:execute(SQL2);
                                [_OfflineDay, _LastFinishTime, _CucmExp] ->  %% 有记录，更新数据
                                    SQL2 = io_lib:format(?SQL_UPDATE_TASK_HIS, [0, LastFinishTime, 0, RoleId, TaskId]),
                                    db:execute(SQL2);
                                Any -> 
                                    catch util:errlog("Error!!lib_task_cumulate:award_cumulate_exp: ~p !! ~n", [Any])
                            end,
                            TaskCumulate#task_cumulate.cucm_exp;
                        false -> 
                            0
                    end;
                Any -> 
                    catch util:errlog("Error!!lib_task_cumulate:award_cumulate_exp: ~p !! ~n", [Any]),
                    0
            end;
        true ->
            0
    end.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%==================================功能函数===============================%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 用户登录时初始化数据
check_task_list([], _PlayerStatus) -> skip;
check_task_list([H | T], PlayerStatus) ->
    Id = PlayerStatus#player_status.id,
    TaskNameList = data_task_cumulate:get_task_cumulate_data(task_name_list),
    case H =< length(TaskNameList) of
        true -> TaskName = lists:nth(H, TaskNameList);
        false -> TaskName = data_task_cumulate:get_task_cumulate_data(other_task_name)
    end,
    case mod_task_cumulate:lookup_task(Id, H) of
        %% 内存无记录
        undefined ->
            SQL1 = io_lib:format(?SQL_SELECT_TASK_HIS, [Id, H]),
            case db:get_row(SQL1) of
                %% 数据库无记录
                [] -> 
                    SQL2 = io_lib:format(?SQL_INSECT_UPDATE_TASK_HIS, [Id, H, 0, util:unixdate() - 86400, 0, 0, util:unixdate() - 86400, 0]),
                    db:execute(SQL2),
                    mod_task_cumulate:insert_task(#task_cumulate{id={Id,H}, role_id=Id, task_id=H, task_name=TaskName, last_finish_time=util:unixdate() - 86400});
                [OfflineDay, _LastFinishTime, CucmExp] ->
                    LastFinishTime = case _LastFinishTime > util:unixdate() - 86400 of
                        true -> _LastFinishTime;
                        false -> util:unixdate() - 86400
                    end,
                    %% 更新离线天数
                    NowDate = util:unixdate(),
                    Day = (NowDate - _LastFinishTime - 86400) div 86400,
                    case Day =< 0 of
                        true -> NewOfflineDay0 = OfflineDay;
                        false -> NewOfflineDay0 = Day + OfflineDay
                    end,
                    %% 最大累计天数
                    MaxCumulateDayList = data_task_cumulate:get_task_cumulate_data(max_cumulate_day),
                    %% 防止数组超出
                    CumulateDay = case H > length(MaxCumulateDayList) of
                        true -> length(MaxCumulateDayList);
                        false -> H
                    end,
                    MaxCumulateDay = lists:nth(CumulateDay, MaxCumulateDayList),
                    NewOfflineDay = case NewOfflineDay0 > MaxCumulateDay of
                        true -> MaxCumulateDay;
                        false -> 
                            case NewOfflineDay0 =< 0 of
                                true -> 0;
                                false -> NewOfflineDay0
                            end
                    end,
                    %% 更新离线经验
                    AddExp = case H of
                        1 -> (PlayerStatus#player_status.lv * PlayerStatus#player_status.lv * 1305) * (NewOfflineDay - OfflineDay);
                        2 -> (data_task_cumulate:get_hb_exp(PlayerStatus#player_status.lv)) * (NewOfflineDay - OfflineDay);
                        3 -> (data_task_cumulate:get_pl_exp(PlayerStatus#player_status.lv)) * (NewOfflineDay - OfflineDay);
                        4 -> (data_task_cumulate:get_zy_exp(PlayerStatus#player_status.lv)) * (NewOfflineDay - OfflineDay);
                        _ -> 0
                    end,
                    _NewCucmExp = CucmExp + AddExp,
                    NewCucmExp = case _NewCucmExp > 0 of
                        true -> _NewCucmExp;
                        false -> 0
                    end,
                    %% 写入内存
                    mod_task_cumulate:insert_task(#task_cumulate{id={Id,H}, role_id=Id, task_id=H, task_name=TaskName, offline_day=NewOfflineDay, last_finish_time=LastFinishTime, cucm_exp=NewCucmExp}),
                    %% 回写数据库
                    SQL2 = io_lib:format(?SQL_UPDATE_TASK_HIS, [NewOfflineDay, LastFinishTime, NewCucmExp, Id, H]),
                    db:execute(SQL2);
                Any -> catch util:errlog("Error!!lib_task_cumulate:check_task_list: ~p !! ~n", [Any])
            end;
        %% 内存有记录
        TaskCumulate when is_record(TaskCumulate, task_cumulate) -> 
            %% 是否有累积经验可领取
            case TaskCumulate#task_cumulate.last_finish_time >= util:unixdate() - 86400 of
                true -> skip;
                false ->
                    LastFinishTime = case TaskCumulate#task_cumulate.last_finish_time > util:unixdate() - 86400 of
                        true -> TaskCumulate#task_cumulate.last_finish_time;
                        false -> util:unixdate() - 86400
                    end,
                    SQL1 = io_lib:format(?SQL_SELECT_TASK_HIS, [Id, H]),
                    case db:get_row(SQL1) of
                        %% 数据库无记录
                        [] -> 
                            SQL2 = io_lib:format(?SQL_INSECT_UPDATE_TASK_HIS, [Id, H, 0, LastFinishTime, 0, 0, LastFinishTime, 0]),
                            db:execute(SQL2),
                            mod_task_cumulate:insert_task(#task_cumulate{id={Id,H}, role_id=Id, task_id=H, task_name=TaskName, last_finish_time=LastFinishTime});
                        [OfflineDay, _LastFinishTime, CucmExp] ->
                            %% 更新离线天数
                            NowDate = util:unixdate(),
                            Day = (NowDate - _LastFinishTime - 86400) div 86400,
                            case Day =< 0 of
                                true -> NewOfflineDay0 = OfflineDay;
                                false -> NewOfflineDay0 = Day + OfflineDay
                            end,
                            %% 最大累计天数
                            MaxCumulateDayList = data_task_cumulate:get_task_cumulate_data(max_cumulate_day),
                            %% 防止数组超出
                            CumulateDay = case H > length(MaxCumulateDayList) of
                                true -> length(MaxCumulateDayList);
                                false -> H
                            end,
                            MaxCumulateDay = lists:nth(CumulateDay, MaxCumulateDayList),
                            NewOfflineDay = case NewOfflineDay0 > MaxCumulateDay of
                                true -> MaxCumulateDay;
                                false -> 
                                    case NewOfflineDay0 =< 0 of
                                        true -> 0;
                                        false -> NewOfflineDay0
                                    end
                            end,
                            %% 更新离线经验
                            AddExp = case H of
                                1 -> (PlayerStatus#player_status.lv * PlayerStatus#player_status.lv * 1305) * (NewOfflineDay - OfflineDay);
                                2 -> (data_task_cumulate:get_hb_exp(PlayerStatus#player_status.lv)) * (NewOfflineDay - OfflineDay);
                                3 -> (data_task_cumulate:get_pl_exp(PlayerStatus#player_status.lv)) * (NewOfflineDay - OfflineDay);
                                4 -> (data_task_cumulate:get_zy_exp(PlayerStatus#player_status.lv)) * (NewOfflineDay - OfflineDay);
                                _ -> 0
                            end,
                            _NewCucmExp = CucmExp + AddExp,
                            NewCucmExp = case _NewCucmExp > 0 of
                                true -> _NewCucmExp;
                                false -> 0
                            end,
                            %% 写入内存
                            mod_task_cumulate:insert_task(#task_cumulate{id={Id,H}, role_id=Id, task_id=H, task_name=TaskName, offline_day=NewOfflineDay, last_finish_time=LastFinishTime, cucm_exp=NewCucmExp}),
                            %% 回写数据库
                            SQL2 = io_lib:format(?SQL_UPDATE_TASK_HIS, [NewOfflineDay, LastFinishTime, NewCucmExp, Id, H]),
                            db:execute(SQL2);
                        Any -> 
                            catch util:errlog("Error!!lib_task_cumulate:check_task_list: ~p !! ~n", [Any])
                    end
            end;
        Any -> 
            catch util:errlog("Error!!lib_task_cumulate:check_task_list: ~p !! ~n", [Any])
    end,
    check_task_list(T, PlayerStatus).

%% 用户退出时回写数据库
%%rewrite_task([], _PlayerStatus) -> skip;
%%rewrite_task([H | T], PlayerStatus) ->
%%    Id = PlayerStatus#player_status.id,
%%    case mod_task_cumulate:lookup_task(Id, H) of
%%        %% 内存无记录
%%        undefined ->
%%            skip;
%%        %% 内存有记录
%%        TaskCumulate when is_record(TaskCumulate, task_cumulate) -> 
%%            SQL1 = io_lib:format(?SQL_SELECT_TASK_HIS, [Id, H]),
%%            case db:get_row(SQL1) of
%%                %% 数据库无记录
%%                [] ->   %%无记录，新插入
%%                    SQL2 = io_lib:format(?SQL_INSECT_UPDATE_TASK_HIS, [Id, H, TaskCumulate#task_cumulate.offline_day, TaskCumulate#task_cumulate.last_finish_time, TaskCumulate#task_cumulate.cucm_exp, TaskCumulate#task_cumulate.offline_day, TaskCumulate#task_cumulate.last_finish_time, TaskCumulate#task_cumulate.cucm_exp]),
%%                    db:execute(SQL2);
%%                [_OfflineDay, _LastFinishTime, _CucmExp] ->  %% 有记录，更新数据
%%                    SQL2 = io_lib:format(?SQL_UPDATE_TASK_HIS, [TaskCumulate#task_cumulate.offline_day, TaskCumulate#task_cumulate.last_finish_time, TaskCumulate#task_cumulate.cucm_exp, Id, H]),
%%                    db:execute(SQL2);
%%                Any -> catch util:errlog("Error!!lib_task_cumulate:rewrite_task: ~p !! ~n", [Any])
%%            end;
%%        Any -> catch util:errlog("Error!!lib_task_cumulate:rewrite_task: ~p !! ~n", [Any])
%%    end,
%%    rewrite_task(T, PlayerStatus).


%% Type: 
%%   1000-1004:功能累计  （1.经验本 2.皇榜 3.平乱 4.诛妖）
%%   999:离线经验
%% Count: 数量
%% Exp: 总经验
%% Money: 0.免费 1.元宝 2.绑定元宝 3.铜币 4.绑定铜币
exp_log(PlayerId, Type, Time, PlayerLv, Count, Exp, MoneyType) ->
    MoneyType2 = case MoneyType of
        gold -> 1;
        bgold -> 2;
        coin -> 3;
        bcoin -> 4;
        _ -> 0
    end,
    spawn(fun() ->
                db:execute(io_lib:format(<<"insert into log_exp set player_id = ~p, type = ~p, time = ~p, player_lv = ~p, count = ~p, exp = ~p, money_type = ~p">>, [PlayerId, Type, Time, PlayerLv, Count, Exp, MoneyType2]))
        end).
