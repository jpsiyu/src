%%%------------------------------------
%%% @Module  : lib_marriage_task
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.10.6
%%% @Description: 结婚系统-任务
%%%------------------------------------
-module(lib_marriage_task).
-export([
        get_task/1,
        finish_task/1,
        get_task_thing/1,
        handle_task_thing/1,
        giveup_task/1
    ]).
-include("server.hrl").
-include("marriage.hrl").

%% 接任务
get_task(Status) ->
    %% 必须男女组队接受考验
    case is_pid(Status#player_status.pid_team) of
        false ->
            Task = 0,
            Res = 2;
        true ->
            %% 只否2人组队
            MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),
            case length(MemberIdList) =:= 2 of
                false ->
                    Task = 0,
                    Res = 2;
                true -> 
                    NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
                    [ParnerId] = NewMemberIdList,
                    %% 必须男方为队长进行预约
                    case Status#player_status.leader =:= 1 andalso Status#player_status.sex =:= 1 of
                        false ->
                            Task = 0,
                            Res = 3;
                        true ->
                            %% 必须男女组队
                            [_ParnerName, ParnerSex, _ParnerScene, _ParnerCopyId] = case lib_player:get_player_info(ParnerId, loverun) of
                                false -> ["", 0, 0, 0];
                                Any -> Any
                            end,
                            case ParnerSex =:= Status#player_status.sex of
                                true ->
                                    Task = 0,
                                    Res = 2;
                                false ->
                                    %% 男女双方必须在红娘范围内
                                    {_Scene, _CopyId, ParnerX, ParnerY} = 
                                    case lib_player:get_player_info(ParnerId, position_info) of
                                        false -> {0, 0, 0, 0};
                                        Any2 -> Any2
                                    end,
                                    case lib_marriage:is_near_matchmaker(ParnerX, ParnerY) =:= true andalso lib_marriage:is_near_matchmaker(Status#player_status.x, Status#player_status.y) =:= true of
                                        false ->
                                            Task = 0,
                                            Res = 5;
                                        true ->
                                            %% 40级以上才能接受任务
                                            ParnerLv = case lib_player:get_player_info(ParnerId, lv) of
                                                false -> 0;
                                                _Lv -> _Lv
                                            end,
                                            case ParnerLv >= 40 andalso Status#player_status.lv >= 40 of
                                                false ->
                                                    Task = 0,
                                                    Res = 8;
                                                true ->
                                                    %% 亲密度不足
                                                    case lib_relationship:find_intimacy(Status#player_status.id, ParnerId) >= 998 of
                                                        false ->
                                                            Task = 0,
                                                            Res = 4;
                                                        true ->
                                                            case Status#player_status.marriage#status_marriage.register_time of
                                                                0 ->
                                                                    %% 得到女方结婚信息
                                                                    FemaleMarriage = case lib_player:get_player_info(ParnerId, marriage) of
                                                                        false -> #status_marriage{};
                                                                        _FemaleMarriage -> _FemaleMarriage
                                                                    end,
                                                                    MaleMarriage = Status#player_status.marriage,
                                                                    case FemaleMarriage#status_marriage.id =:= MaleMarriage#status_marriage.id of
                                                                        true ->
                                                                            %% 不能重复申请
                                                                            %io:format("~p~n", [[lib_marriage:marry_state(Status#player_status.marriage), lib_marriage:marry_state(FemaleMarriage)]]),
                                                                            case lib_marriage:marry_state(Status#player_status.marriage) =:= 1 andalso lib_marriage:marry_state(FemaleMarriage) =:= 1 of
                                                                                false ->
                                                                                    Task = 0,
                                                                                    Res = 9;
                                                                                true ->
                                                                                    case Status#player_status.marriage#status_marriage.parner_id of
                                                                                        ParnerId ->
                                                                                            %% 成功申请结婚，领取任务
                                                                                            MaleId = Status#player_status.id,
                                                                                            FemaleId = ParnerId,
                                                                                            _MyTask = mod_marriage:get_marriage_task_player(MaleId),
                                                                                            MyTask = case is_record(_MyTask, marriage_task) of
                                                                                                true -> _MyTask;
                                                                                                false -> #marriage_task{}
                                                                                            end,
                                                                                            QingMi = lib_relationship:find_intimacy(Status#player_status.id, ParnerId),
                                                                                            AppBegin = case date() > {2012, 10, 10} of
                                                                                                true -> lib_relationship:find_xlqy_count(MaleId, FemaleId);
                                                                                                false -> 0
                                                                                            end,
                                                                                            if
                                                                                                %% 直接完成任务
                                                                                                QingMi >= 29999 ->
                                                                                                    Task = 0,
                                                                                                    TaskType = 3,
                                                                                                    TaskFlag = 1,
                                                                                                    FinishTask = 1,
                                                                                                    NewTask = MyTask#marriage_task{
                                                                                                        task_type = TaskType,
                                                                                                        finish_task = FinishTask
                                                                                                    };
%%                                                                                                %% 情比金坚任务
%%                                                                                                QingMi >= 9999 ->
%%                                                                                                    Task = 2,
%%                                                                                                    TaskType = 2,
%%                                                                                                    TaskFlag = 2,
%%                                                                                                    FinishTask = 0,
%%                                                                                                    NewTask = MyTask#marriage_task{
%%                                                                                                        task_flag = TaskFlag,
%%                                                                                                        task_type = TaskType
%%                                                                                                    },
%%                                                                                                    XY1 = [{145, 157}, {174, 81}, {74, 91}],
%%                                                                                                    XY2 = [{58, 190}, {121, 139}, {35, 214}],
%%                                                                                                    %XY1 = [{114, 135}],
%%                                                                                                    %XY2 = [{114, 135}],
%%                                                                                                    Rand = util:rand(1, length(XY1)),
%%                                                                                                    {X1, Y1} = lists:nth(Rand, XY1),
%%                                                                                                    {X2, Y2} = lists:nth(Rand, XY2),
%%                                                                                                    lib_scene:player_change_scene(MaleId, 102, 0, X1, Y1, false),
%%                                                                                                    lib_scene:player_change_scene(FemaleId, 102, 0, X2, Y2, false),
%%                                                                                                    mod_marriage:set_npc(NewTask),
%%                                                                                                    spawn(fun() -> 
%%                                                                                                                timer:sleep(30 * 60 * 1000),
%%                                                                                                                end_3000_task(NewTask) 
%%                                                                                                        end
%%                                                                                                    );
                                                                                                %% 11次情缘任务
                                                                                                QingMi >= 9999 ->
                                                                                                    Task = 2,
                                                                                                    TaskType = 2,
                                                                                                    TaskFlag = 1,
                                                                                                    FinishTask = 0,
                                                                                                    NewTask = MyTask#marriage_task{
                                                                                                        app_begin = AppBegin,
                                                                                                        task_type = TaskType
                                                                                                    };
                                                                                                %% 22次情缘任务
                                                                                                true ->
                                                                                                    Task = 1,
                                                                                                    TaskType = 1,
                                                                                                    TaskFlag = 1,
                                                                                                    FinishTask = 0,
                                                                                                    NewTask = MyTask#marriage_task{
                                                                                                        app_begin = AppBegin,
                                                                                                        task_type = TaskType
                                                                                                    }
                                                                                            end,
                                                                                            db:execute(io_lib:format(<<"insert into marriage_task set id = ~p, app_begin = ~p, task_flag = ~p, task_type = ~p, finish_task = ~p ON DUPLICATE KEY UPDATE app_begin = ~p, task_flag = ~p, task_type = ~p, finish_task = ~p">>, [MaleMarriage#status_marriage.id, AppBegin, TaskFlag, TaskType, FinishTask, AppBegin, TaskFlag, TaskType, FinishTask])),
                                                                                            mod_marriage:set_marriage_task(NewTask),
                                                                                            lib_player:update_player_info(MaleId, [{marriage_task, NewTask}]),
                                                                                            lib_player:update_player_info(FemaleId, [{marriage_task, NewTask}]),
                                                                                            %% 后台日志（任务日志）
                                                                                            spawn(fun() ->
                                                                                                        db:execute(io_lib:format(<<"insert into log_marriage1 set type = 2, active_id = ~p, passive_id = ~p, time = ~p, intimacy = ~p, task_type = ~p, qingyuan_num = ~p">>, [Status#player_status.id, ParnerId, util:unixtime(), QingMi, TaskType, AppBegin]))
                                                                                                end),
                                                                                            Res = 1;
                                                                                        %% 未申请结婚
                                                                                        _ ->
                                                                                            Task = 0,
                                                                                            Res = 10
                                                                                    end
                                                                            end;
                                                                        %% 需要跟申请登记的伴侣一起接受考验
                                                                        false ->
                                                                            Task = 0,
                                                                            Res = 7
                                                                    end;
                                                                %% 男方已结婚
                                                                _Ress ->
                                                                    Task = 0,
                                                                    Res = 6
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end,
    {Res, Task}.

%% 交任务
finish_task(Status) ->
    Marriage = Status#player_status.marriage,
    case lib_marriage:marry_state(Marriage) =:= 2 orelse lib_marriage:marry_state(Marriage) =:= 3 of
        false -> 
            %% 不存在任务
            Res = 2;
        true ->
            Task = Marriage#status_marriage.task,
            ParnerId = Marriage#status_marriage.parner_id,
            Num = lib_relationship:find_xlqy_count(Status#player_status.id, ParnerId),
            case Task#marriage_task.finish_task of
                %% 已完成任务
                1 ->
                    Res = 0;
                _ ->
                    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
                    ParnerStatus = case lib_player:get_player_info(ParnerId) of
                        false -> #player_status{};
                        _ParnerStatus -> _ParnerStatus
                    end,
                    ParnerTask = ParnerStatus#player_status.marriage#status_marriage.task,
                    case (Task#marriage_task.task_type =:= 2 andalso Task#marriage_task.task_flag =:= 4 andalso ParnerTask#marriage_task.task_flag =:= 4) orelse (Task#marriage_task.task_type =:= 2 andalso Num >= 11) orelse (Task#marriage_task.task_type =:= 1 andalso Num >= 22) of
                        %% 未完成任务
                        false ->
                            Res = 3;
                        true ->
                            ParnerMarriage = ParnerStatus#player_status.marriage,
                            NewTask = Task#marriage_task{task_flag = 5, finish_task = 1},
                            mod_marriage:set_marriage_task(NewTask),
                            lib_player:update_player_info(Status#player_status.id, [{marriage_task, NewTask}]),
                            lib_player:update_player_info(ParnerId, [{marriage, ParnerMarriage#status_marriage{task = NewTask}}]),
                            db:execute(io_lib:format(<<"update marriage_task set task_flag = 5, finish_task = 1 where id = ~p">>, [Marriage#status_marriage.id])),
                            Res = 1
                    end
            end
    end,
    Res.

%% 领取情比金坚任务定情信物
get_task_thing(Status) ->
    TaskFlag =  Status#player_status.marriage#status_marriage.task#marriage_task.task_flag,
    case TaskFlag of
        2 ->
            %% 清风 明月 牛郎 织女
            [{_NPC1, _X1, _Y1}, {_NPC2, _X2, _Y2}, {_NPC3, _X3, _Y3}, {_NPC4, _X4, _Y4}] = case mod_marriage:get_npc(Status#player_status.id) of
                [] -> [{0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}];
                _Any1 -> _Any1
            end,
            case Status#player_status.sex of
                1 ->
                    case (Status#player_status.x - _X1) * (Status#player_status.x - _X1) + (Status#player_status.y - _Y1) * (Status#player_status.y - _Y1) >= 100 of
                        %% 离NPC太远
                        true -> 
                            Res = 2;
                        false ->
                            Marriage = Status#player_status.marriage,
                            Task = Marriage#status_marriage.task,
                            NewTask = Task#marriage_task{task_flag = 3},
                            lib_player:update_player_info(Status#player_status.id, [{marriage_task, NewTask}]),
                            mod_marriage:set_marriage_task(NewTask),
                            db:execute(io_lib:format(<<"update marriage_task set task_flag = 3 where id = ~p">>, [Marriage#status_marriage.id])),
                            Res = 1
                    end;
                _ ->
                    case (Status#player_status.x - _X3) * (Status#player_status.x - _X3) + (Status#player_status.y - _Y3) * (Status#player_status.y - _Y3) >= 100 of
                        %% 离NPC太远
                        true -> 
                            Res = 2;
                        false ->
                            Marriage = Status#player_status.marriage,
                            Task = Marriage#status_marriage.task,
                            NewTask = Task#marriage_task{task_flag = 3},
                            lib_player:update_player_info(Status#player_status.id, [{marriage_task, NewTask}]),
                            mod_marriage:set_marriage_task(NewTask),
                            db:execute(io_lib:format(<<"update marriage_task set task_flag = 3 where id = ~p">>, [Marriage#status_marriage.id])),
                            Res = 1
                    end
            end;
        1 ->
            Res = 0;
        _ ->
            Res = 3
    end,
    Res.

%% 上交情比金坚任务定情信物
handle_task_thing(Status) ->
        TaskFlag =  Status#player_status.marriage#status_marriage.task#marriage_task.task_flag,
    case TaskFlag of
        3 ->
            %% 清风 明月 牛郎 织女
            [{_NPC1, _X1, _Y1}, {_NPC2, _X2, _Y2}, {_NPC3, _X3, _Y3}, {_NPC4, _X4, _Y4}] = case mod_marriage:get_npc(Status#player_status.id) of
                [] -> [{0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}];
                _Any1 -> _Any1
            end,
            case Status#player_status.sex of
                1 ->
                    case (Status#player_status.x - _X2) * (Status#player_status.x - _X2) + (Status#player_status.y - _Y2) * (Status#player_status.y - _Y2) >= 100 of
                        %% 离NPC太远
                        true -> 
                            Res = 2;
                        false ->
                            Marriage = Status#player_status.marriage,
                            Task = Marriage#status_marriage.task,
                            NewTask = Task#marriage_task{task_flag = 4},
                            lib_player:update_player_info(Status#player_status.id, [{marriage_task, NewTask}]),
                            mod_marriage:set_marriage_task(NewTask),
                            db:execute(io_lib:format(<<"update marriage_task set task_flag = 4 where id = ~p">>, [Marriage#status_marriage.id])),
                            Res = 1
                    end;
                _ ->
                    case (Status#player_status.x - _X4) * (Status#player_status.x - _X4) + (Status#player_status.y - _Y4) * (Status#player_status.y - _Y4) >= 100 of
                        %% 离NPC太远
                        true -> 
                            Res = 2;
                        false ->
                            Marriage = Status#player_status.marriage,
                            Task = Marriage#status_marriage.task,
                            NewTask = Task#marriage_task{task_flag = 4},
                            lib_player:update_player_info(Status#player_status.id, [{marriage_task, NewTask}]),
                            mod_marriage:set_marriage_task(NewTask),
                            db:execute(io_lib:format(<<"update marriage_task set task_flag = 4 where id = ~p">>, [Marriage#status_marriage.id])),
                            Res = 1
                    end
            end;
        %% 已提交
        4 ->
            Res = 4;
        5 ->
            Res = 4;
        %% 未领取定情信物
        _ ->
            Res = 3
    end,
    Res.

%% 30分钟后停止任务
%%end_3000_task(Task) ->
%%    OldTask = mod_marriage:get_marriage_task(Task#marriage_task.id),
%%    _Task = case is_record(OldTask, marriage_task) of
%%        true -> OldTask;
%%        false -> #marriage_task{}
%%    end,
%%    case _Task#marriage_task.finish_task of
%%        1 -> skip;
%%        _ ->
%%            case _Task#marriage_task.id of
%%                0 -> skip;
%%                _ ->
%%                    NewTask = _Task#marriage_task{
%%                        task_flag = 1,  %是否已完成情比金坚任务 1.没有该任务，2.未领取定情信物，3.已领取定情信物，4.已上交定情信物，未完成任务
%%                        task_type = 0  %任务类型 1.998 2.3000 3.6000
%%                    },
%%                    mod_marriage:set_marriage_task(NewTask),
%%                    MaleId = NewTask#marriage_task.male_id,
%%                    FemaleId = NewTask#marriage_task.female_id,
%%                    lib_player:update_player_info(MaleId, [{marriage_task, NewTask}]),
%%                    lib_player:update_player_info(FemaleId, [{marriage_task, NewTask}]),
%%                    {ok, BinData} = pt_271:write(27108, [1]),
%%                    lib_server_send:send_to_uid(MaleId, BinData),
%%                    lib_server_send:send_to_uid(FemaleId, BinData)
%%            end
%%    end.

%% 放弃任务
giveup_task(Status) ->
    case mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5600) >= 1 of
        %% 每天只能放弃一次任务
        true ->
            Res = 3;
        false ->
            Marriage = Status#player_status.marriage,
            case lib_marriage:marry_state(Marriage) =:= 1 orelse lib_marriage:marry_state(Marriage) =:= 2 orelse lib_marriage:marry_state(Marriage) =:= 3 orelse lib_marriage:marry_state(Marriage) =:= 4 of
                false -> 
                    %% 不存在任务
                    Res = 2;
                true ->
                    ParnerId = Marriage#status_marriage.parner_id,
                    %% 放弃任务，放弃整个流程，可以重新选伴侣
                    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
                    MarriageId = Status#player_status.marriage#status_marriage.id,
                    db:execute(io_lib:format(<<"delete from marriage_task where id = ~p">>, [MarriageId])),
                    db:execute(io_lib:format(<<"delete from marriage where id = ~p">>, [MarriageId])),
                    ParnerMarriage = mod_marriage:get_marry_info(ParnerId),
                    case is_record(ParnerMarriage, marriage) of
                        true ->
                            mod_marriage:delete_info(ParnerMarriage);
                        false ->
                            skip
                    end,
                    lib_player:update_player_info(ParnerId, [{marriage, #status_marriage{}}]),
                    lib_player:update_player_info(Status#player_status.id, [{marriage, #status_marriage{}}]),
                    mod_daily:increment(Status#player_status.dailypid, Status#player_status.id, 5600),
                    Res = 1
            end
    end,
    Res.
