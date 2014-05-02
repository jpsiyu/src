%%%------------------------------------
%%% @Module  : mod_loverun
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.8.21
%%% @Description: 爱情长跑
%%%------------------------------------
-module(mod_loverun).
-behaviour(gen_server).
-include("scene.hrl").
-include("server.hrl").
-include("unite.hrl").
-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).
-record(state, {
				config_begin_hour = 0,
				config_begin_minute = 0,
				config_end_hour = 0,
				config_end_minute = 0,
                apply_time = 0}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

%% 设置开启时间
set_time(Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute, ApplyTime) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{set_time,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, ApplyTime}).

%% 广播
broadcast() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{broadcast}).

%% 返回活动开始结束时间
get_begin_end_time() ->
    gen_server:call(misc:get_global_pid(?MODULE), {get_begin_end_time}).

%% 玩家是否已参加了本场的活动
is_finish(PlayerId) ->
    gen_server:call(misc:get_global_pid(?MODULE), {is_finish, PlayerId}).

%% 玩家完成本场的活动
finish_activity(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{finish_activity, PlayerId}).

%% 添加伴侣ID
add_parner(MyId, ParnerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{add_parner, MyId, ParnerId}).

%% 获取伴侣ID(没有则返回0)
get_parner(MyId) ->
    gen_server:call(misc:get_global_pid(?MODULE), {get_parner, MyId}).

%% 开始长跑，计时
start_run(MyId, ParnerId, StartTime) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{start_run, MyId, ParnerId, StartTime}).

%% 中断长跑
stop_run(Status) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{stop_run, Status}).

%% 退出场景
logout(Status) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{logout, Status}).

%% 结束长跑，计算时间
finish_run(Arg1, Arg2, Type) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{finish_run, Arg1, Arg2, Type}).

%% 结算
account() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{account}).

%% 任务状态
task_state(PlayerId) ->
    gen_server:call(misc:get_global_pid(?MODULE),{task_state, PlayerId}).

%% 进入场景
goin_room(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{goin_room, PlayerId}).

%% 退出场景
out_room(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{out_room, PlayerId}).

%% 清场，把玩家传送出去
clear() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{clear}).

%% 得到所有完成长跑的玩家的信息
get_all_finish_data(Status) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{get_all_finish_data, Status}).

%% 获取报名时间
get_apply_time() ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_apply_time}).

%% 开始长跑协议处理
execute_34304(Status, MemberIdList, ParnerInfo) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{execute_34304, Status, MemberIdList, ParnerInfo}).

%% 提交任务协议处理
execute_34306(Status, MemberIdList, ParnerInfo) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{execute_34306, Status, MemberIdList, ParnerInfo}).

%% 防作弊
crossing_point(PlayerId, ParnerId, Point, LoverunData) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{crossing_point, PlayerId, ParnerId, Point, LoverunData}).


init([]) ->
     [{Year1, Month1, Day1}, {Year2, Month2, Day2}] = data_loverun_time:get_loverun_time(activity_date),
     case date() >= {Year1, Month1, Day1} andalso date() =< {Year2, Month2, Day2} of
         false -> State = #state{};
         true ->
             [[{Config_Begin_Hour1, Config_Begin_Minute1}, {Config_End_Hour1, Config_End_Minute1}], [{Config_Begin_Hour2, Config_Begin_Minute2}, {Config_End_Hour2, Config_End_Minute2}]] = data_loverun_time:get_loverun_time(activity_time),
             %设置时间
             {NowHour, NowMin, _NowSec} = time(),
             case (Config_End_Hour1 * 60 + Config_End_Minute1) - (NowHour * 60 + NowMin) =< 0 andalso (Config_End_Hour2 * 60 + Config_End_Minute2) - (NowHour * 60 + NowMin) > 0 of
                 true ->
                     State = #state{
                         config_begin_hour=Config_Begin_Hour2,
                         config_begin_minute=Config_Begin_Minute2,
                         config_end_hour=Config_End_Hour2,
                         config_end_minute=Config_End_Minute2};
                 false -> 
                     State = #state{
                         config_begin_hour=Config_Begin_Hour1,
                         config_begin_minute=Config_Begin_Minute1,
                         config_end_hour=Config_End_Hour1,
                         config_end_minute=Config_End_Minute1}
             end
     end,
    {ok, State}.

%% call
%% 返回活动开始结束时间
handle_call({get_begin_end_time}, _From, State) ->
    Reply = {State#state.config_begin_hour, State#state.config_begin_minute, State#state.config_end_hour, State#state.config_end_minute, State#state.apply_time},
	{reply, Reply, State};

%% 玩家是否已参加了本场的活动
handle_call({is_finish, PlayerId}, _From, State) ->
    Reply = case get({is_finish, PlayerId}) of
        undefined -> false;
        _ -> true
    end,
	{reply, Reply, State};

%% 获取伴侣ID(没有则返回0)
handle_call({get_parner, MyId}, _From, State) ->
    Reply = case get({parner, MyId}) of
        undefined -> 0;
        ParnerId -> ParnerId
    end,
	{reply, Reply, State};

%% 任务状态
%%    int:8	返回码
%%		1 = 未领取
%%		2 = 已领取未提交
%%		3 = 已提交
handle_call({task_state, PlayerId}, _From, State) ->
    case get({is_finish, PlayerId}) of
        undefined -> 
            case get({parner, PlayerId}) of
                undefined -> Reply = {ok, 1};
                _ -> Reply = {ok, 2}
            end;
        _ -> Reply = {ok, 3}
    end,
	{reply, Reply, State};

%% 获取报名时间
handle_call({get_apply_time}, _From, State) ->
    Reply = State#state.apply_time,
	{reply, Reply, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% cast
%% 设置开启时间
handle_cast({set_time, Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute, ApplyTime}, _State) ->
    erase(),
    L = mod_chat_agent:match(all_ids_by_lv_gap, [38, 999]),
    spawn(fun()-> 
                lists:foreach(fun(Id) -> 
                            lib_player:update_player_info(Id, [
                                    {loverun_data, [Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute, ApplyTime]},
                                    {loverun_state, 1}
                                ]),
                            lib_player_unite:update_unite_info(Id, [{loverun_data, [Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute, ApplyTime]}]),
                            timer:sleep(100)
                    end, L)
        end),
	NewState = #state{config_begin_hour = Config_Begin_Hour,
					  config_begin_minute = Config_Begin_Minute,
					  config_end_hour = Config_End_Hour,
					  config_end_minute = Config_End_Minute,
                      apply_time = ApplyTime},
	{noreply, NewState};

%% 广播
handle_cast({broadcast}, State) ->
    {Hour, Min, Sec} = time(),
    Time = (State#state.config_end_hour * 60 * 60 + State#state.config_end_minute * 60) - (Hour * 60 * 60 + Min * 60 + Sec),
    case Time > 0 of
        true ->
            {ok, BinData} = pt_343:write(34300, [Time]);
        false ->
            {ok, BinData} = pt_343:write(34300, [0])
    end,
    spawn(fun() ->
                lib_unite_send:send_to_all(38, 999, BinData)
        end),
	{noreply, State};

%% 玩家完成本场的活动
handle_cast({finish_activity, PlayerId}, State) ->
    put({is_finish, PlayerId}, util:unixtime()),
	{noreply, State};

%% 添加伴侣ID
handle_cast({add_parner, MyId, ParnerId}, State) ->
	put({parner, MyId}, ParnerId),
	{noreply, State};

%% 开始长跑，计时
handle_cast({start_run, MyId, ParnerId, StartTime}, State) ->
	put({start_run, MyId, ParnerId}, StartTime),
    lib_player:update_player_info(MyId, [
                                    {loverun_state, 2}
                                ]),
    lib_player:update_player_info(ParnerId, [
                                    {loverun_state, 2}
                                ]),
	{noreply, State};


%% 中断长跑
handle_cast({stop_run, Status}, State) ->
    PlayerId = Status#player_status.id,
    case get({parner, PlayerId}) of
        undefined -> skip;
        ParnerId ->
            MyId = PlayerId,
            lib_figure:change(MyId, {0, 0}),
            lib_figure:change(ParnerId, {0, 0}),
            {SceneId, CopyId} = {Status#player_status.scene, Status#player_status.copy_id},
            {X, Y} = data_loverun:get_loverun_config(scene_born),
            %% 传送自己
            lib_scene:player_change_scene_queue(PlayerId, SceneId, CopyId, X, Y, [{parner_id, 0}, {loverun_state, 1}]),
            %% 传送伴侣
            lib_scene:player_change_scene_queue(ParnerId, SceneId, CopyId, X, Y, [{parner_id, 0}, {loverun_state, 1}]),
            erase({start_run, PlayerId, ParnerId}),
            erase({start_run, ParnerId, PlayerId}),
            erase({parner, ParnerId}),
            erase({parner, MyId})
    end,
	{noreply, State};

%% （退出场景）中断长跑
handle_cast({logout, Status}, State) ->
    PlayerId = Status#player_status.id,
    case get({parner, PlayerId}) of
        undefined -> skip;
        ParnerId ->
            MyId = PlayerId,
            lib_figure:change(MyId, {0, 0}),
            lib_figure:change(ParnerId, {0, 0}),
            {SceneId, CopyId, _X, _Y} = {Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y},
            {X, Y} = data_loverun:get_loverun_config(scene_born),
            %% 传送自己
            lib_scene:player_change_scene_queue(PlayerId, SceneId, CopyId, X, Y, [{parner_id, 0}, {loverun_state, 1}]),
            %% 传送伴侣
            lib_scene:player_change_scene_queue(ParnerId, SceneId, CopyId, X, Y, [{parner_id, 0}, {loverun_state, 1}]),
            erase({start_run, PlayerId, ParnerId}),
            erase({start_run, ParnerId, PlayerId}),
            erase({parner, ParnerId}),
            erase({parner, MyId})
    end,
	{noreply, State};

%% 结束长跑，计算时间
handle_cast({finish_run, Arg1, Arg2, Type}, State) ->
    mod_finish_run(Arg1, Arg2, Type),
	{noreply, State};

%% 结算
handle_cast({account}, State) ->
    %% 按玩家总用时排序
    List = lists:keysort(3, list_deal(get(), [])),
    %io:format("List:~p~n", [List]),
    %% 发送奖励(邮件)
    spawn(fun() -> send_all_award(List, 1) end),
    FinishIdList = list_deal2(get(), []),
    Bin = pack(List),
    {ok, BinData} = pt_343:write(34308, Bin),
    %% 结算结果发送给全部已完成的玩家
    spawn(fun() -> send_to_all(FinishIdList, BinData, 0) end),
    erase(),
	{noreply, State};

%% 进入场景
handle_cast({goin_room, PlayerId}, State) ->
    put({is_in_room, PlayerId}, util:unixtime()),
	{noreply, State};

%% 退出场景
handle_cast({out_room, PlayerId}, State) ->
    erase({is_in_room, PlayerId}),
	{noreply, State};

%% 清场，把玩家传送出去
handle_cast({clear}, State) ->
    AllIdList = list_deal3(get(), []),
    %io:format("AllIdList:~p~n", [AllIdList]),
    spawn(fun() -> send_end(AllIdList, 0) end),
	{noreply, State};

%% 开始长跑协议处理
handle_cast({execute_34304, Status, MemberIdList, ParnerInfo}, State) ->
    %% 记录活动开始时间
    [BeginHour, BeginMin, EndHour, EndMin, ApplyTime] = Status#player_status.loverun_data,
    case lib_loverun:is_opening(BeginHour, BeginMin, EndHour, EndMin, ApplyTime) of
        true -> 
            %% 只能在场景里报名
            LoverunSceneId = data_loverun:get_loverun_config(scene_id),
            case Status#player_status.scene =:= LoverunSceneId of
                false -> Error = 0;
                true ->
                    %% 是否已组队
                    case is_pid(Status#player_status.pid_team) of
                        true -> 
                            %% 判断玩家本次是否已完成
                            IsFinishReply = case get({is_finish, Status#player_status.id}) of
                                undefined -> false;
                                _ -> true
                            end,
                            case IsFinishReply of
                                false -> 
                                    %% 判断是否一男一女或2个男或2个女
                                    %% 队伍人数只能为2人
                                    case length(MemberIdList) =:= 2 of
                                        true -> 
                                            NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
                                            [ParnerId] = NewMemberIdList,
                                            [_ParnerName, ParnerSex, ParnerScene, ParnerCopyId] = ParnerInfo,
                                            %% 伴侣的性别、场景、房间判断
                                            case ParnerSex =:= 0 orelse ParnerScene =/= data_loverun:get_loverun_config(scene_id) orelse ParnerCopyId =/= Status#player_status.copy_id of
                                                true -> Error = 3;
                                                false -> 
                                                    %% 是否为同性
                                                    case ParnerSex =:= Status#player_status.sex of
                                                        true -> 
                                                            case ParnerSex =:= 1 orelse ParnerSex =:= 2 of
                                                                true -> 
                                                                    %% 判断伴侣本次是否已完成
                                                                    ParnerIsFinishReply = case get({is_finish, ParnerId}) of
                                                                        undefined -> false;
                                                                        _ -> true
                                                                    end,
                                                                    case ParnerIsFinishReply of
                                                                        false ->
                                                                            %% 不能离NPC太远
                                                                            X = 60, Y = 25,
                                                                            case (Status#player_status.x - X) * (Status#player_status.x - X) + (Status#player_status.y - Y) * (Status#player_status.y - Y) > 36 of
                                                                                true -> Error = 0;
                                                                                false ->
                                                                                    %% 判断是否重复报名
                                                                                    case Status#player_status.parner_id of
                                                                                        0 -> 
                                                                                            %% 成功参加
                                                                                            %% 改变队长形象
                                                                                            case ParnerSex of
                                                                                                1 ->
                                                                                                    case Status#player_status.leader of
                                                                                                        1 -> lib_figure:change(Status#player_status.pid, {1111, 60 * 60 * 1000});
                                                                                                        _ -> lib_figure:change(ParnerId, {1111, 60 * 60 * 1000})
                                                                                                    end;
                                                                                                2 ->
                                                                                                    case Status#player_status.leader of
                                                                                                        1 -> lib_figure:change(Status#player_status.pid, {2222, 60 * 60 * 1000});
                                                                                                        _ -> lib_figure:change(ParnerId, {2222, 60 * 60 * 1000})
                                                                                                    end
                                                                                            end,
                                                                                            put({parner, Status#player_status.id}, ParnerId),
                                                                                            put({parner, ParnerId}, Status#player_status.id),
                                                                                            BeginXY = data_loverun:get_loverun_config(begin_xy),
                                                                                            Random = util:rand(1, length(BeginXY)),
                                                                                            {BeginX, BeginY} = lists:nth(Random, BeginXY),
                                                                                            lib_loverun:start_running(Status#player_status.id, ParnerId, ParnerScene, ParnerCopyId, BeginX, BeginY, Status),
                                                                                            {ok, BinData2} = pt_343:write(34304, [1]),
                                                                                            lib_server_send:send_to_uid(ParnerId, BinData2),

                                                                                            Error = 1;
                                                                                        _ ->
                                                                                            Error = 6
                                                                                    end
                                                                            end;
                                                                        _ -> Error = 4
                                                                    end;
                                                                false ->
                                                                    Error = 3
                                                            end;
                                                        false -> 
                                                            %% 判断伴侣本次是否已完成
                                                            ParnerIsFinishReply = case get({is_finish, ParnerId}) of
                                                                        undefined -> false;
                                                                        _ -> true
                                                                    end,
                                                            case ParnerIsFinishReply of
                                                                false ->
                                                                    %% 不能离NPC太远
                                                                    X = 60, Y = 25,
                                                                    case (Status#player_status.x - X) * (Status#player_status.x - X) + (Status#player_status.y - Y) * (Status#player_status.y - Y) > 36 of
                                                                        true -> Error = 0;
                                                                        false ->
                                                                            %% 判断是否重复报名
                                                                            case Status#player_status.parner_id of
                                                                                0 -> 
                                                                                    %% 成功参加
                                                                                    %% 改变男方形象
                                                                                    case Status#player_status.sex of
                                                                                        1 -> lib_figure:change(Status#player_status.pid, {1314, 60 * 60 * 1000});
                                                                                        _ -> lib_figure:change(ParnerId, {1314, 60 * 60 * 1000})
                                                                                    end,
                                                                                    put({parner, Status#player_status.id}, ParnerId),
                                                                                    put({parner, ParnerId}, Status#player_status.id),
                                                                                    BeginXY = data_loverun:get_loverun_config(begin_xy),
                                                                                    Random = util:rand(1, length(BeginXY)),
                                                                                    {BeginX, BeginY} = lists:nth(Random, BeginXY),
                                                                                    %% 队长报前面
                                                                                    case Status#player_status.leader of
                                                                                        1 ->
                                                                                            lib_loverun:start_running(Status#player_status.id, ParnerId, ParnerScene, ParnerCopyId, BeginX, BeginY, Status);
                                                                                        _ ->
                                                                                            lib_loverun:start_running(ParnerId, Status#player_status.id, ParnerScene, ParnerCopyId, BeginX, BeginY, Status)
                                                                                    end,
                                                                                    {ok, BinData2} = pt_343:write(34304, [1]),
                                                                                    lib_server_send:send_to_uid(ParnerId, BinData2),
                                                                                    Error = 1;
                                                                                _ ->
                                                                                    Error = 6
                                                                            end
                                                                    end;
                                                                _ -> Error = 4
                                                            end
                                                    end
                                            end;
                                        false -> Error = 3
                                    end;
                                _ -> Error = 4
                            end;
                        false -> Error = 3
                    end
            end;
        false -> Error = 2
    end,
    {ok, BinData} = pt_343:write(34304, [Error]),
    lib_server_send:send_to_uid(Status#player_status.id, BinData),
	{noreply, State};

%% 提交任务协议处理
handle_cast({execute_34306, Status, MemberIdList, ParnerInfo}, State) ->
    %% 记录活动开始时间
    [BeginHour, BeginMin, EndHour, EndMin, ApplyTime] = Status#player_status.loverun_data,
    %% 判断活动是否开启中
    case lib_loverun:is_submit_time(BeginHour, BeginMin, EndHour, EndMin, ApplyTime) =:= true of
        true ->
            case is_pid(Status#player_status.pid_team) of
                true -> 
                    %% 判断是否一男一女
                    %% 队伍人数只能为2人
                    case length(MemberIdList) =:= 2 of
                        false -> {ok, BinData} = pt_343:write(34306, [6]);
                        true -> 
                            NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
                            [ParnerId] = NewMemberIdList,
                            %% 判断是否为之前一起接任务的伴侣
                            case ParnerId =:= Status#player_status.parner_id of
                                false -> {ok, BinData} = pt_343:write(34306, [6]);
                                true -> 
                                    X = 174, Y = 273,
                                    case (Status#player_status.x - X) * (Status#player_status.x - X) + (Status#player_status.y - Y) * (Status#player_status.y - Y) > 36 of
                                        true ->
                                            {ok, BinData} = pt_343:write(34306, [0]);
                                        false ->
                                            %% 判断玩家本次是否已完成
                                            IsFinishReply = case get({is_finish, Status#player_status.id}) of
                                                undefined -> false;
                                                _ -> true
                                            end,
                                            case IsFinishReply of
                                                false -> 
                                                    CheatPoint = get({cheat_point, Status#player_status.id}),
                                                    %io:format("CheatPoint:~p~n", [CheatPoint]),
                                                    %% 防作弊
                                                    case is_list(CheatPoint) andalso length(CheatPoint) >= 4 of
                                                        false ->
                                                            {ok, BinData} = pt_343:write(34306, [7]);
                                                        true ->
                                                            % 完成任务
                                                            put({is_finish, Status#player_status.id}, util:unixtime()),
                                                            put({is_finish, ParnerId}, util:unixtime()),
                                                            %% 一男一女时，男ID在前，女ID在后
                                                            %% 两男或两女时，队长ID在前，队员ID在后
                                                            [_ParnerName, ParnerSex, _ParnerScene, _ParnerCopyId] = ParnerInfo,
                                                            MySex = Status#player_status.sex,
                                                            case ParnerSex =:= MySex of
                                                                true ->
                                                                    case Status#player_status.leader of
                                                                        1 ->
                                                                            mod_finish_run(Status, [ParnerId, _ParnerName, ParnerSex], 1);
                                                                        _ ->
                                                                            mod_finish_run([ParnerId, _ParnerName, ParnerSex], Status, 2)
                                                                    end;
                                                                false ->
                                                                    case MySex of
                                                                        1 ->
                                                                            mod_finish_run(Status, [ParnerId, _ParnerName, ParnerSex], 1);
                                                                        _ ->
                                                                            mod_finish_run([ParnerId, _ParnerName, ParnerSex], Status, 2)
                                                                    end
                                                            end,
                                                            {ok, BinData} = pt_343:write(34306, [1]),
                                                            lib_server_send:send_to_uid(ParnerId, BinData)
                                                    end;
                                                _ -> {ok, BinData} = pt_343:write(34306, [0])
                                            end
                                    end
                            end
                    end;
                false -> {ok, BinData} = pt_343:write(34306, [6])
            end;
        false -> 
            {ok, BinData} = pt_343:write(34306, [4])
    end,
    lib_server_send:send_to_uid(Status#player_status.id, BinData),
	{noreply, State};

%% 得到所有完成长跑的玩家的信息
handle_cast({get_all_finish_data, Status}, State) ->
    %% 只要10条
    List1 = lists:keysort(3, list_deal(get(), [])),
    List = lists:sublist(List1, 10),
    Bin = pack(List),
    {ok, BinData} = pt_343:write(34311, Bin),
    lib_unite_send:send_one(Status#unite_status.socket, BinData),
	{noreply, State};

%% 防作弊
handle_cast({crossing_point, PlayerId, ParnerId, Point, LoverunData}, State) ->
    case LoverunData of
        [BeginHour, BeginMin, EndHour, EndMin, ApplyTime] ->
            %% 判断活动是否开启中
            case lib_loverun:is_submit_time(BeginHour, BeginMin, EndHour, EndMin, ApplyTime) of
                true ->
                    case get({cheat_point, PlayerId}) of
                        undefined ->
                            put({cheat_point, PlayerId}, [Point]);
                        List when is_list(List) ->
                            List1 = lists:delete(Point, List),
                            List2 = [Point | List1],
                            put({cheat_point, PlayerId}, List2);
                        _ ->
                            put({cheat_point, PlayerId}, [Point])
                    end,
                    case get({cheat_point, ParnerId}) of
                        undefined ->
                            put({cheat_point, ParnerId}, [Point]);
                        List3 when is_list(List3) ->
                            List4 = lists:delete(Point, List3),
                            List5 = [Point | List4],
                            put({cheat_point, ParnerId}, List5);
                        _ ->
                            put({cheat_point, ParnerId}, [Point])
                    end;
                false ->
                    skip
            end;
        _ ->
            skip
    end,
	{noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% info
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

list_deal([], L) -> L;
list_deal([H | T], L) ->
    case H of
        {{total_time, MyId, ParnerId}, {TotalTime, MyName, MySex, ParnerName, ParnerSex, CopyId}} -> list_deal(T, [{MyId, ParnerId, TotalTime, MyName, MySex, ParnerName, ParnerSex, CopyId} | L]);
        _ -> list_deal(T, L)
    end.

list_deal2([], L) -> L;
list_deal2([H | T], L) ->
    case H of
        {{is_finish, PlayerId}, _TotalTime} -> list_deal2(T, [PlayerId | L]);
        _ -> list_deal2(T, L)
    end.

list_deal3([], L) -> L;
list_deal3([H | T], L) ->
    case H of
        {{is_in_room, PlayerId}, _Time} -> list_deal3(T, [PlayerId | L]);
        _ -> list_deal3(T, L)
    end.

pack(List) ->
	%% List1
    Fun1 = fun(Elem1) ->
            {Id1, Id2, _TotalTime, Name1, Sex1, Name2, Sex2, CopyId} = Elem1,
            TotalTime = _TotalTime div 1000,
            NickName1 = pt:write_string(Name1),
            NickName2 = pt:write_string(Name2),
            <<Id1:32, NickName1/binary, Sex1:8, Id2:32, NickName2/binary, Sex2:8, TotalTime:16, CopyId:8>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List]),
    Size1  = length(List),
    <<Size1:16, BinList1/binary>>.

%% 发送奖励(邮件)
send_all_award([], _N) -> skip;
send_all_award([H | T], N) ->
    case H of
        {Id1, Id2, _TotalTime, _Name1, _Sex1, _Name2, _Sex2, _CopyId} -> 
            Title = data_loverun:get_loverun_config(title1),
            Detail = data_loverun:get_loverun_config(content1),
            if 
                N =:= 1 -> 
                    %% 先判断用户是否在线
                    case lib_player:is_online_unite(Id1) of
                        true ->
                            case lib_player:get_player_info(Id1, sendTv_Message) of
                                [_PSId1, PSRealm1, PSNickname1, PSSex1, PSCareer1, PSImage1] ->
                                    SendTv1 = [Id1, PSRealm1, PSNickname1, PSSex1, PSCareer1, PSImage1],
                                    Nice1 = true;
                                _ -> 
                                    SendTv1 = 0,
                                    Nice1 = false
                            end;
                        false -> 
                            case lib_player:get_player_low_data(Id1) of
                                [PSNickname1, PSSex1, _Lv1, PSCareer1, PSRealm1, _GuildId1, _Mount_limit1, _HusongNpc1, _Image1| _] -> 
                                    PSImage1 = lib_player:get_player_normal_image(Id1),
                                    SendTv1 = [Id1, PSRealm1, binary_to_list(PSNickname1), PSSex1, PSCareer1, PSImage1],
                                    Nice1 = true;
                                _ -> 
                                    SendTv1 = 0,
                                    Nice1 = false
                            end
                    end,
                    case lib_player:is_online_unite(Id2) of
                        true ->
                            case lib_player:get_player_info(Id2, sendTv_Message) of
                                [_PSId2, PSRealm2, PSNickname2, PSSex2, PSCareer2, PSImage2] ->
                                    SendTv2 = [Id2, PSRealm2, PSNickname2, PSSex2, PSCareer2, PSImage2],
                                    Nice2 = true;
                                _ -> 
                                    SendTv2 = 0,
                                    Nice2 = false
                            end;
                        false -> 
                            case lib_player:get_player_low_data(Id2) of
                                [PSNickname2, PSSex2, _Lv2, PSCareer2, PSRealm2, _GuildId2, _Mount_limit2, _HusongNpc2, _Image2| _] -> 
                                    PSImage2 = lib_player:get_player_normal_image(Id2),
                                    SendTv2 = [Id2, PSRealm2, binary_to_list(PSNickname2), PSSex2, PSCareer2, PSImage2],
                                    Nice2 = true;
                                _ -> 
                                    SendTv2 = 0,
                                    Nice2 = false
                            end
                    end,
                    %% 发送传闻
                    case Nice1 =:= true andalso Nice2 =:= true of
                        true ->
                            List = ["loveRunNO1", 1] ++ SendTv1 ++ SendTv2,
                            lib_chat:send_TV({all}, 1, 2, List);
                        false -> skip
                    end,
                    GiftId = 534001,
                    lib_mail:send_sys_mail_bg([Id1, Id2], Title, Detail, GiftId, 2, 0, 0, 1, 0, 0, 0, 0);
                N >= 2 andalso N =< 10 ->
                    GiftId = 534002,
                    lib_mail:send_sys_mail_bg([Id1, Id2], Title, Detail, GiftId, 2, 0, 0, 1, 0, 0, 0, 0);
                N >= 11 andalso N =< 50 -> 
                    GiftId = 534003,
                    lib_mail:send_sys_mail_bg([Id1, Id2], Title, Detail, GiftId, 2, 0, 0, 1, 0, 0, 0, 0);
                N >= 51 andalso N =< 100 -> 
                    GiftId = 534004,
                    lib_mail:send_sys_mail_bg([Id1, Id2], Title, Detail, GiftId, 2, 0, 0, 1, 0, 0, 0, 0);
                true -> 
                    GiftId = 534005,
                    lib_mail:send_sys_mail_bg([Id1, Id2], Title, Detail, GiftId, 2, 0, 0, 1, 0, 0, 0, 0)
            end;
        _ -> skip
    end,
    send_all_award(T, N + 1).

%% 结算结果发送给全部已完成的玩家
send_to_all([], _Bin, _N) -> skip;
send_to_all([H | T], Bin, N) ->
    %% 分批发送结果
	case N rem 10 of
		0 -> 
			util:sleep(100);
		_ ->
			skip
	end,
    lib_server_send:send_to_uid(H, Bin),
    send_to_all(T, Bin, N + 1).

%% 把所有玩家传送出去
send_end([], _N) -> skip;
send_end([H | T], N) ->
    %% 分批把玩家传送出去
	case N rem 10 of
		0 -> 
			util:sleep(100);
		_ ->
			skip
	end,
    case misc:get_player_process(H) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'loverun_end', []});
        _ ->
            skip
    end,
	send_end(T, N + 1).

mod_finish_run(Arg1, Arg2, Type) ->
    case Type of
        1 ->
            Id1 = Arg1#player_status.id,
            [Name1, Sex1] = [Arg1#player_status.nickname, Arg1#player_status.sex],
            [Id2, Name2, Sex2] = Arg2,
            SceneId = Arg1#player_status.scene,
            CopyId = Arg1#player_status.copy_id;
        _ ->
            Id2 = Arg2#player_status.id,
            [Id1, Name1, Sex1] = Arg1,
            [Name2, Sex2] = [Arg2#player_status.nickname, Arg2#player_status.sex],
            SceneId = Arg2#player_status.scene,
            CopyId = Arg2#player_status.copy_id
    end,
    FinishTime = util:longunixtime(),
    %% 改变形象
    lib_figure:change(Id1, {0, 0}),
    lib_figure:change(Id2, {0, 0}),
    %% 记录总用时
    {_Hour, _Min, _Sec} = time(),
    CheatTime = 999000 + _Min * 60 + _Sec,
    case get({start_run, Id1, Id2}) of
        undefined ->
            case get({start_run, Id2, Id1}) of
                undefined -> 
                    %io:format("1~n"),
                    TotalTime = CheatTime;
                StartTime -> 
                    %io:format("2 Start:~p, Finish:~p~n", [StartTime, FinishTime]),
                    erase({start_run, Id2, Id1}),
                    TotalTime = FinishTime - StartTime
            end;
        StartTime -> 
            %io:format("3 Start:~p, Finish:~p~n", [StartTime, FinishTime]),
            erase({start_run, Id1, Id2}),
            TotalTime = FinishTime - StartTime
    end,
    TotalTime2 = case TotalTime > 0 of
        true -> 
            case TotalTime < 150000 of
                true -> CheatTime;
                false -> TotalTime
            end;
        false -> 
            CheatTime
    end,
    put({total_time, Id1, Id2}, {TotalTime2, Name1, Sex1, Name2, Sex2, CopyId}),
    %% 给房间内的玩家发信息(右边的时间)
    %io:format("TotalTime:~p~n", [TotalTime2]),
    List1 = lists:keysort(3, list_deal(get(), [])),
    List = lists:sublist(List1, 10),
    Bin = pack(List),
    {ok, BinData} = pt_343:write(34311, Bin),
    lib_unite_send:send_to_scene(SceneId, CopyId, BinData),
    %% 查找用户登录前记录的场景ID和坐标
    _LoverunSceneId = data_loverun:get_loverun_config(scene_id),
    PSX0 = 170,
    PSY0 = 265,
    Rand1 = util:rand(0, 7),
    Rand2 = util:rand(0, 10),
    PSX = PSX0 + Rand1,
    PSY = PSY0 + Rand2,
    %% 传送自己
    PlayerId = Id1,
    lib_scene:player_change_scene_queue(PlayerId, SceneId, CopyId, PSX, PSY, [{parner_id, 0}, {loverun_state, 3}]),
    %% 传送伴侣
    lib_scene:player_change_scene_queue(Id2, SceneId, CopyId, PSX, PSY, [{parner_id, 0}, {loverun_state, 3}]),
    %% 删除Parner
    erase({parner, Id2}),
    erase({parner, Id1}).
