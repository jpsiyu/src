%%%-----------------------------------
%%% @Module  : mod_task_proxy
%%% @Author  : zhenghehe
%%% @Created : 2010.10.13
%%% @Description: 委托任务
%%%-----------------------------------
-module(mod_task_proxy).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include("server.hrl").
-include("task.hrl").
%% 开放接口 ==================================================
%% 角色上线
online(Tid, RoleId) ->
    ets:match_delete(?ETS_ROLE_TASK_AUTO, #role_task_auto{role_id = RoleId, _ = '_'}),
    to_ets(db:get_all(io_lib:format(<<"SELECT `role_id`, `task_id`, `type`, `name`, `number`, `gold`, `trigger_time`, `finish_time`, `exp`, `llpt`, `xwpt` FROM `task_auto` WHERE role_id=~p">>, [RoleId])), Tid).

%% 角色下线
offline(RoleId) -> ets:match_delete(?ETS_ROLE_TASK_AUTO, #role_task_auto{role_id = RoleId, _ = '_'}).

refresh_list(PS) ->
    %% 从可接任务中获取
    F =
    fun(X_RT) ->
        %% 可以做多少次
        Count = get_task_daily_count(X_RT#task.condition),
        %% 做了多少次
        Cur = lib_task:get_today_count(X_RT#task.id, PS),
        {Gold, Sec} = {X_RT#task.proxy_gold, X_RT#task.proxy_time},%get_spend_info(X_RT#task.type, X_RT#task.level),
        %%经验累积
        %Ratio = lib_task_cumulate:get_ratio(X_RT) - 1,
        [X_RT#task.id, X_RT#task.level, X_RT#task.type, X_RT#task.name, Sec, Gold, Count - Cur, X_RT#task.exp, X_RT#task.llpt, X_RT#task.xwpt, 0]
    end,
    L1 = [F(RT) || RT <- get_task_list(PS),
        PS#player_status.lv >= RT#task.level,
        RT#task.proxy =:= 1,
        in_proxy(RT#task.role_id, RT#task.id) =:= false
    ],
    L2 = refresh_action_list(get_action_list(PS#player_status.id), util:unixtime(), []),
    %%?DEBUG("委托任务列表 ~p ~p", [L1, L2]),
    {ok, BinData} = pt_301:write(30100, [L1, L2]),
    lib_server_send:send_to_uid(PS#player_status.id, BinData).

%% 委托任务数据组织
refresh_action_list([], _Now, R) -> R;

refresh_action_list([RTA|T], Now, R) ->
    Sec =
    case RTA#role_task_auto.finish_time - Now < 0 of
        true -> 0;
        false -> RTA#role_task_auto.finish_time - Now
    end,
    refresh_action_list(T, Now,
        [
            [RTA#role_task_auto.task_id, RTA#role_task_auto.name, RTA#role_task_auto.number, Sec, RTA#role_task_auto.gold, RTA#role_task_auto.exp, RTA#role_task_auto.llpt, RTA#role_task_auto.xwpt]
            | R
        ]
    ).

%% 查看任务是否委托中
in_proxy(RoleId, TaskId)->
    case ets:lookup(?ETS_ROLE_TASK_AUTO, {RoleId, TaskId}) of
        [] -> false;
        [_] -> true
    end.

%% 获取委托任务的信息
get(RoleId, TaskId) ->
    case ets:lookup(?ETS_ROLE_TASK_AUTO, {RoleId, TaskId}) of
        [] -> false;
        [RTA] -> RTA
    end.

%% 获取正在代理的任务
get_action_list(RoleId) ->
    ets:match_object(?ETS_ROLE_TASK_AUTO,
        #role_task_auto{
            role_id = RoleId
            ,_ = '_'
        }
    ).

%% 获取可委托的任务列表
get_task_list(PS) ->
    TriggerBag = lib_task:get_trigger(PS#player_status.tid),
    L = lists:map(
        fun(RT) ->
                lib_task:get_data(RT#role_task.task_id, PS)
        end,
        TriggerBag
    ),
    case lib_task:get_active_proxy(PS) of
        [] ->
            L ++ lib_task:get_active(PS#player_status.tid);
        D ->
            L2 = lists:map(
                fun(Tid) ->
                    lib_task:get_data(Tid, PS)
                end,
                D
            ),
            L++L2
    end.

%% 尝试开始工作
action(_RS, [])  ->
    Msg = data_task_text:get_task_proxy_action(1),
    {false, Msg};

action(RS, List) ->
    case action_check(RS, List, [], 0) of
        {false, Msg} -> {false, Msg};
        {true, NewRS, RTAList, Gold} ->
            Sql = after_action(RTAList, []),
            F = fun() ->
                [db:execute(S) || S <-Sql],
                ok
            end,
            case db:transaction(F) =:= ok of
                true -> %% sql执行成功
                    %扣钱
                    NewRS1 = lib_goods_util:cost_money(NewRS, Gold, gold),
                    %统计
                    log:log_consume(task_proxy, gold, NewRS, NewRS1, "task proxy"),
                    %% 元宝消费活动触发
                    %lib_activity:trigger_activity(NewRS#player_status.id, 4, Gold),
                    lib_task:refresh_active(NewRS1), %% 刷新缓存
                    %%lib_role:event(NewRS, util:all_to_binary([<<"失去了">>, Gold, <<"元宝">>])),
                    %lib_player:refresh_client(NewRS#player_status.id, 2),     %% 刷新客户端
                    %{ok, BinData} = pt_30:write(30006, []),
                    %lib_send:send_one(NewRS#player_status.socket, BinData),
                    lib_scene:refresh_npc_ico(NewRS1),   %% 通知场景npc图标更新
                    {true, NewRS1};
                false ->
                    Msg = data_task_text:get_task_proxy_action(2),
                    {false, Msg}
            end
    end.

action_check(RS, [], Result, TotalGold) ->
    {true, RS, Result, TotalGold};

action_check(RS, [[TaskId, Num0] | T ], Result, TotalGold) ->
    case lib_task:get_data(TaskId, RS) of
        null -> 
            Msg = data_task_text:get_task_proxy_action_check(1),
            {false, Msg};
        RT ->
            case Num0 > 0 of
                false ->
                    Msg = data_task_text:get_task_proxy_action_check(1),
                    {false, Msg};
                true ->
                    case in_proxy(RS#player_status.id, TaskId) of
                        true ->
                            Msg = data_task_text:get_task_proxy_action_check(2),
                            {false, Msg};
                        false ->
                            case RT#task.type < 2 of
                                true ->
                                    Msg = data_task_text:get_task_proxy_action_check(3),
                                    {false, Msg};
                                false ->
                                    DC = lib_task:get_today_count(RT#task.id, RS),
                                    Count = get_task_daily_count(RT#task.condition),
                                    case DC < Count of
                                        true ->
                                            IsLimit = false;
                                        false ->
                                            IsLimit = true
                                    end,
                                    case IsLimit of
                                        true ->
                                            Format = data_task_text:get_task_proxy_action_check(4),
                                            Msg = io_lib:format(Format, [RT#task.name]),
                                            {false,Msg};
                                        false ->
                                            case Count - DC < Num0 of
                                                true ->
                                                    Num = Count - DC;
                                                false ->
                                                    Num = Num0
                                            end,
                                            {Gold, Sec} = {RT#task.proxy_gold, RT#task.proxy_time},%get_spend_info(RT#task.type, RT#task.level),
                                            case RS#player_status.gold >= TotalGold + Gold * Num of
                                                false ->
                                                    Msg = data_task_text:get_task_proxy_action_check(5),
                                                    {false, Msg};
                                                true ->
                                                    %扣钱
                                                    %NewRS = lib_goods_util:cost_money(RS, Gold * Num, gold),
                                                    %统计
                                                    %log:log_consume(task_proxy, gold, RS, NewRS, ""),
                                                    NewRS = RS,
                                                    
                                                    Now = util:unixtime(),
                                                    %% 经验累积
                                                    %Ratio = lib_task_cumulate:get_ratio(RT) - 1,
                                                    {Exp, Llpt, Xwpt} = {RT#task.exp*Num, RT#task.llpt*Num, RT#task.xwpt*Num},
                                                    %lib_task_cumulate:finish(RT, Now),
%%                                                     lib_achieve:trigger_task(RS#player_status.id, RT#task.type, RT#task.id, Num),
%%                                                     %% 运势触发
%%                                                     case RT#task.type of
%%                                                         %% 英雄帖任务
%%                                                         9 ->  lib_fortune:rpc_trigger_task(RS#player_status.id, 1, RT#task.id, Num);
%%                                                         %% 公告任务
%%                                                         11 -> lib_fortune:rpc_trigger_task(RS#player_status.id, 2, RT#task.id, Num);
%%                                                         _ -> skip
%%                                                     end,
                                                    action_check(NewRS, T,
                                                        [
                                                            #role_task_auto{
                                                                id = {RS#player_status.id, RT#task.id}
                                                                ,role_id = RS#player_status.id
                                                                ,task_id = RT#task.id
                                                                ,type = RT#task.type
                                                                ,tid = RS#player_status.tid
                                                                ,name = RT#task.name
                                                                ,number = Num
                                                                ,gold = Gold * Num    %% 需要元宝
                                                                ,trigger_time = Now
                                                                ,finish_time = Now + Sec * Num
                                                                ,exp = round(Exp + RT#task.exp)
                                                                ,llpt = round(Llpt + RT#task.llpt)
                                                                ,xwpt = round(Xwpt + RT#task.xwpt)
                                                            }
                                                        | Result],
                                                        TotalGold + Gold * Num
                                                    )
                                            end
                                    end
                            end
                    end
            end
    end.

after_action([], Sql) -> Sql;

after_action([RTA | T], Sql) ->
    %% 如在可接任务中就清除该任务
    case lib_task:in_trigger(RTA#role_task_auto.tid, RTA#role_task_auto.task_id) of
        false -> ok;
        true ->
            lib_task:del_trigger(RTA#role_task_auto.tid, RTA#role_task_auto.role_id, RTA#role_task_auto.task_id)
    end,
    %% 数据缓存
    ets:insert(?ETS_ROLE_TASK_AUTO, RTA),
    %% 数据持久化
    Sql1 = Sql ++ [io_lib:format(<<"INSERT INTO `task_auto` (`role_id`, `task_id`, `type`, `name`, `number`, `gold`, `trigger_time`, `finish_time`, `exp`, `llpt`, `xwpt`)
        VALUES (~p, ~p, ~p, '~s', ~p, ~p, ~p, ~p, ~p, ~p, ~p)">>, [
        RTA#role_task_auto.role_id
        ,RTA#role_task_auto.task_id
        ,RTA#role_task_auto.type
        ,RTA#role_task_auto.name
        ,RTA#role_task_auto.number
        ,RTA#role_task_auto.gold
        ,RTA#role_task_auto.trigger_time
        ,RTA#role_task_auto.finish_time
        ,RTA#role_task_auto.exp
        ,RTA#role_task_auto.llpt
        ,RTA#role_task_auto.xwpt
    ])],
   
    F = fun(I) ->
        lib_task:put_task_log_list(RTA#role_task_auto.tid, #role_task_log{role_id=RTA#role_task_auto.role_id, task_id=RTA#role_task_auto.task_id, type = RTA#role_task_auto.type, trigger_time = RTA#role_task_auto.trigger_time, finish_time = RTA#role_task_auto.finish_time + I}),
        %% 数据库写
        add_sql(RTA#role_task_auto.role_id, RTA#role_task_auto.task_id, RTA#role_task_auto.type, RTA#role_task_auto.trigger_time, RTA#role_task_auto.finish_time + I)
    end,
    Sql2 = Sql1 ++ for(1, RTA#role_task_auto.number, F, []),
    after_action(T, Sql2).

%% 添加完成日志
add_sql(Rid, Tid, Type, TriggerTime, FinishTime) when Type > 1 ->
    lists:concat(["insert into `task_log_clear`(`role_id`, `task_id`, `type`, `trigger_time`, `finish_time`) values(",Rid,",",Tid,",",Type,",",TriggerTime,",",FinishTime,")"]);
add_sql(Rid, Tid, Type, TriggerTime, FinishTime) ->
    lists:concat(["insert into `task_log`(`role_id`, `task_id`, `type`, `trigger_time`, `finish_time`) values(",Rid,",",Tid,",",Type,",",TriggerTime,",",FinishTime,")"]).

%% for循环
for(Max, Max, F, L) ->
    L++[F(Max)];
for(I, Max, F, L)   ->
    for(I+1, Max, F, L++[F(I)]).

%% 委托任务奖励
award(RS, TaskId) ->
    case get(RS#player_status.id, TaskId) of
        false -> false;
        RTA ->
            case is_finish(RTA) of
                false -> false;
                true ->
                    RS2 = lib_player:add_exp(RS, RTA#role_task_auto.exp, 0),
                    RS3 = lib_player:add_pt(llpt, RS2, RTA#role_task_auto.llpt),
                    RS4 = lib_player:add_pt(xwpt, RS3, RTA#role_task_auto.xwpt),
                    ets:delete(?ETS_ROLE_TASK_AUTO, RTA#role_task_auto.id),
                    db:execute(io_lib:format(<<"DELETE FROM `task_auto` WHERE `role_id` =~p AND `task_id` =~p">>, [RTA#role_task_auto.role_id, RTA#role_task_auto.task_id])),
                    lib_task:refresh_active(RS4),   %% 刷新任务缓存
                    lib_player:refresh_client(RS4),   %% 刷新客户端
                    refresh_list(RS4),
                    {ok, RS4}
            end
    end.

%% 私有方法 ===========================================================

is_finish(RTA) ->
    RTA#role_task_auto.finish_time =< util:unixtime().

%% 将委托的任务转换成record
to_ets([], _) -> ok;

to_ets([[RoleId, TaskId, Type, Name, Number, Gold, TriggerTime, FinishTime, Exp, Llpt, Xwpt] | T], Tid) ->
    ets:insert(?ETS_ROLE_TASK_AUTO,
        #role_task_auto{
            id = {RoleId, TaskId}
            ,role_id = RoleId
            ,task_id = TaskId
            ,type = Type
            ,tid = Tid
            ,name = Name
            ,number = Number
            ,gold = Gold
            ,trigger_time = TriggerTime
            ,finish_time = FinishTime
            ,exp = Exp
            ,llpt = Llpt
            ,xwpt = Xwpt
        }
    ),
    to_ets(T, Tid).

%% 获取每天可完成次数
get_task_daily_count([]) ->
    1;
get_task_daily_count([{daily_limit, Num} | _]) ->
    Num;
get_task_daily_count([_A | T]) ->
    get_task_daily_count(T).


%% 立即完成委托任务
once_finish(_NewRS, [])  ->
    Msg = data_task_text:get_task_proxy_action(1),
    {false, Msg};

once_finish(NewRS, List) ->
    case once_finish_check(List, NewRS, [], 0) of
        {false, Msg} -> {false, Msg};
        {true, RTAList, Gold} ->
            Sql = after_finish_action(RTAList, []),
            F = fun() ->
                [db:execute(S) || S <-Sql],
                ok
            end,
            case db:transaction(F) =:= ok of
                true -> %% sql执行成功
                    %扣钱
                    NewRS1 = lib_goods_util:cost_money(NewRS, Gold, gold),
                    %统计
                    log:log_consume(task_proxy_finish, gold, NewRS, NewRS1, "finish task quickly"),
                    {true, NewRS1};
                false ->
                    Msg = data_task_text:get_task_proxy_action(2),
                    {false, Msg}
            end
    end.

once_finish_check([], _, Res, Gold) ->
    {true, Res, Gold};
once_finish_check([TaskId | T], RS, Res, Gold) ->
    case ets:lookup(?ETS_ROLE_TASK_AUTO, {RS#player_status.id, TaskId}) of
        [] ->
            Msg = data_task_text:get_once_finish_check(1),
            {false, Msg};
        [RTA] -> 
            Gold1 = Gold + RTA#role_task_auto.gold,
            case RS#player_status.gold < Gold1 of
                true ->
                    Msg = data_task_text:get_once_finish_check(2),
                    {false, Msg};
                false -> 
                    once_finish_check(T, RS, Res++[RTA], Gold1)
            end
    end.

after_finish_action([], Sql) -> Sql;

after_finish_action([RTA | T], Sql) ->
    %% 数据缓存
    ets:insert(?ETS_ROLE_TASK_AUTO, RTA#role_task_auto{finish_time = 0}),
    %% 数据持久化
    Sql1 = Sql ++ [io_lib:format(<<"update `task_auto` set `finish_time` = 0 where role_id = ~p and task_id = ~p">>, [
                                RTA#role_task_auto.role_id
                                ,RTA#role_task_auto.task_id
                            ])],
    after_finish_action(T, Sql1).
