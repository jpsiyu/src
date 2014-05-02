%%%------------------------------------
%%% @Module  : mod_wubianhai_new
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.7.6
%%% @Description: 大闹天宫(无边海)
%%%------------------------------------
-module(mod_wubianhai_new).
-behaviour(gen_server).
-include("wubianhai_new.hrl").
-include("server.hrl").
-include("common.hrl").
-include("unite.hrl").
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% gen_server callbacks
-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

%% ====================================================================
%% Server functions
%% ====================================================================
%%设置活动时间(该方法不可随便调用，会重置所有属性，很危险)
set_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_time,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute}).

%%设置状态
%%@param Arena_Status 活动状态 0还未开启 1开启中 2当天已结束
set_status(Arena_Status)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_status,Arena_Status}).

%%开启活动
open_arena()->
	gen_server:cast(misc:get_global_pid(?MODULE),{open_arena}).

%%生成世界等级
set_world_lv()->
	gen_server:call(misc:get_global_pid(?MODULE),{set_world_level}).

%% 检测活动当前时间状态
%% @return int 0未开始 1正在进行 2已经结束
get_arena_status() -> 
	gen_server:call(misc:get_global_pid(?MODULE),{get_arena_status}).

%% 与当前时间比，活动剩余时间
%% @return int 0为未开始或已结束，单位是秒
get_arena_remain_time() -> 
	gen_server:call(misc:get_global_pid(?MODULE),{get_arena_remain_time}).

%% 是否在房间内
is_in_arena(Id) -> 
	gen_server:call(misc:get_global_pid(?MODULE),{is_in_arena, Id}).

%%玩家查询房间列表
%%@param PlayerId 玩家ID
%%@param PlayerLv 玩家等级
%%@return {RoomLv,RoomId,RoomList}
room_list(PlayerId,PlayerLv) -> 
	gen_server:call(misc:get_global_pid(?MODULE),{room_list,PlayerId,PlayerLv}).

%%获取所有玩家Id
get_all_player_id() ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_all_player_id}).

%%获取玩家任务信息
get_task_list(Id) ->
	gen_server:cast(misc:get_global_pid(?MODULE),{get_task_list, Id}).

%%用户领奖
award(UniteStatus, TaskId) ->
	gen_server:cast(misc:get_global_pid(?MODULE),{award, UniteStatus, TaskId}).

%% 击杀其他玩家，获得物品
kill_others(Id, T1, T2, T3, T4, T5, T6, T7, K1, K2, K3) ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_by_others, Id, T1, T2, T3, T4, T5, T6, T7, K1, K2, K3}).

kill_mon(Id, MonId) ->
	gen_server:cast(misc:get_global_pid(?MODULE),{kill_mon, Id, MonId}).

%% 被人击杀，丢失物品
%% 返回{T1, T2, T3, T4, T5, T6, T7, TName1, TName2, TName3, TName4, TName5, TName6, TName7, K1, K2, K3, KillName1, KillName2, KillName3}
%% T1-T7:0或1
killed_by_others(KilledId) ->
	gen_server:call(misc:get_global_pid(?MODULE),{killed_by_others, KilledId}).

%% 返回世界等级
get_world_lv() ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_world_lv}).

%% 返回玩家当前任务已搜集到物品的数量
get_task_num(Id) ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_task_num, Id}).

%% 返回活动开始、结束时间
get_begin_end_time() ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_begin_end_time}).

%% 返回房间人数
get_room_num(RoomId) ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_room_num, RoomId}).

enter_arena(Id, PlayerLv, RoomId) ->
	gen_server:cast(misc:get_global_pid(?MODULE),{enter_arena, Id, PlayerLv, RoomId}).

quit_arena(Id) ->
	gen_server:cast(misc:get_global_pid(?MODULE),{quit_arena, Id}).

%%活动结束时处理逻辑
end_arena()->
	gen_server:cast(misc:get_global_pid(?MODULE),{end_arena}).

%%活动结束，清场
clear()->
	gen_server:cast(misc:get_global_pid(?MODULE),{clear}).

%%记录进入前的PK状态
insert_last_pk_status(PlayerId, PkValue)->
	gen_server:cast(misc:get_global_pid(?MODULE),{insert_last_pk_status, PlayerId, PkValue}).

%%获取进入前的PK状态
get_last_pk_status(PlayerId) ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_last_pk_status, PlayerId}).

cast_64003(UniteStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{cast_64003, UniteStatus}).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    [[Config_Begin_Hour,Config_Begin_Minute],[Config_End_Hour,Config_End_Minute]] = data_wubianhai_new:get_wubianhai_config(arena_time),
    {ok, #state{config_begin_hour=Config_Begin_Hour, config_begin_minute=Config_Begin_Minute, config_end_hour=Config_End_Hour, config_end_minute=Config_End_Minute}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({get_arena_status}, _From, State) ->
	Reply = State#state.arena_stauts,
	{reply, Reply, State};
	
handle_call({get_arena_remain_time}, _From, State) ->
	Reply = lib_wubianhai_new:get_arena_remain_time(State#state.config_begin_hour,State#state.config_begin_minute,State#state.config_end_hour,State#state.config_end_minute),
	{reply, Reply, State};

%% 是否在房间内
handle_call({is_in_arena, Id}, _From, State) ->
	Reply = case get({is_in_arena, Id}) of
		undefined -> false;
        RoomId -> RoomId
	end,
	{reply, Reply, State};

%%获取所有玩家Id
handle_call({get_all_player_id}, _From, State) ->
	Reply = get(),
	{reply, Reply, State};

%% 返回世界等级
handle_call({get_world_lv}, _From, State) ->
    Reply = case get(world_level) of
        undefined -> 
            data_wubianhai_new:get_wubianhai_config(apply_level);
        Lv -> Lv
    end,
	{reply, Reply, State};

%% 返回玩家当前任务已搜集到物品的数量
handle_call({get_task_num, Id}, _From, State) ->
    case get({player_task, Id}) of
        undefined ->
            Task1Num = 0,
            Task2Num = 0,
            Task3Num = 0,
            Task4Num = 0,
            Task5Num = 0,
            Task6Num = 0,
            Task7Num = 0,
            KillNum = 0;
        Arena when is_record(Arena,arena) ->
            Task1Num = case Arena#arena.task1#task.get_award of
                1 -> 0;
                _ -> Arena#arena.task1#task.now_num
            end,
            Task2Num = case Arena#arena.task2#task.get_award of
                1 -> 0;
                _ -> Arena#arena.task2#task.now_num
            end,
            Task3Num = case Arena#arena.task3#task.get_award of
                1 -> 0;
                _ -> Arena#arena.task3#task.now_num
            end,
            Task4Num = case Arena#arena.task4#task.get_award of
                1 -> 0;
                _ -> Arena#arena.task4#task.now_num
            end,
            Task5Num = case Arena#arena.task5#task.get_award of
                1 -> 0;
                _ -> Arena#arena.task5#task.now_num
            end,
            Task6Num = case Arena#arena.task6#task.get_award of
                1 -> 0;
                _ -> Arena#arena.task6#task.now_num
            end,
            Task7Num = case Arena#arena.task7#task.get_award of
                1 -> 0;
                _ -> Arena#arena.task7#task.now_num
            end,
            KillNum = Arena#arena.task7#task.now_kill;
        _ ->
            Task1Num = 0,
            Task2Num = 0,
            Task3Num = 0,
            Task4Num = 0,
            Task5Num = 0,
            Task6Num = 0,
            Task7Num = 0,
            KillNum = 0
    end,
	Reply = [Task1Num, Task2Num, Task3Num, Task4Num, Task5Num, Task6Num, Task7Num, KillNum],
	{reply, Reply, State};

%% 返回活动开始、结束时间
handle_call({get_begin_end_time}, _From, State) ->
	Reply = [State#state.config_begin_hour, State#state.config_begin_minute, State#state.config_end_hour, State#state.config_end_minute],
	{reply, Reply, State};

%% 返回房间人数
handle_call({get_room_num, RoomId}, _From, State) ->
    Reply = case get({all_room, RoomId}) of
        undefined -> 0;
        {Num, _MaxNum} -> Num
    end,
	{reply, Reply, State};

%% 被人击杀，丢失物品
%% 返回{R1, R2, R3, R4, R5, R6, R7, TName1, TName2, TName3, TName4, TName5, TName6, TName7, K1, K2, K3, KillName1, KillName2, KillName3}
%% R1-R7,K1-K3:0或1
handle_call({killed_by_others, KilledId}, _From, State) ->
    case get({player_task, KilledId}) of
        undefined ->
            PlayerLv = lib_player:get_player_info(KilledId, lv),
            {_Scene, _CopyId, _X, _Y} = lib_player:get_player_info(KilledId, position_info),
            Arena = lib_wubianhai_new:load_player_info(KilledId, PlayerLv, _CopyId),
            put({player_task, KilledId}, Arena);
        Arena -> skip
    end,
	T1 = Arena#arena.task1,
	T2 = Arena#arena.task2,
	T3 = Arena#arena.task3,
	T4 = Arena#arena.task4,
	T5 = Arena#arena.task5,
	T6 = Arena#arena.task6,
	T7 = Arena#arena.task7,
	TName1 = T1#task.task_name,
	TName2 = T2#task.task_name,
	TName3 = T3#task.task_name,
	TName4 = T4#task.task_name,
	TName5 = T5#task.task_name,
	TName6 = T6#task.task_name,
	TName7 = T7#task.task_name,
	KillName1 = T5#task.kill_name,
	KillName2 = T6#task.kill_name,
	KillName3 = T7#task.kill_name,
	case T1#task.get_award =:=1 andalso T2#task.get_award =:=1 andalso T3#task.get_award =:=1 andalso T4#task.get_award =:=1 of
		true -> 
			R1 = 0, R2 = 0, R3 = 0, R4 = 0,
			NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, 
			case T5#task.now_num > 0 andalso T5#task.get_award =:= 0 of
				true -> 
					R5 = 1,
					NewT50 = T5#task{now_num = T5#task.now_num - 1};
				false -> 
					R5 = 0,
					NewT50 = T5
			end,
			case T6#task.now_num > 0 andalso T6#task.get_award =:= 0 of
				true -> 
					R6 = 1,
					NewT60 = T6#task{now_num = T6#task.now_num - 1};
				false -> 
					R6 = 0,
					NewT60 = T6
			end,
			case T7#task.now_num > 0 andalso T7#task.get_award =:= 0 of
				true -> 
					R7 = 1,
					NewT70 = T7#task{now_num = T7#task.now_num - 1};
				false -> 
					R7 = 0,
					NewT70 = T7
			end,
			case T5#task.now_kill > 0 andalso T5#task.get_award =:= 0 of
				true -> 
					K1 = 1,
					NewT5 = NewT50#task{now_kill = T5#task.now_kill - 1};
				false -> 
					K1 = 0,
					NewT5 = NewT50
			end,
			case T6#task.now_kill > 0 andalso T6#task.get_award =:= 0 of
				true -> 
					K2 = 1,
					NewT6 = NewT60#task{now_kill = T6#task.now_kill - 1};
				false -> 
					K2 = 0,
					NewT6 = NewT60
			end,
			case T7#task.now_kill > 0 andalso T7#task.get_award =:= 0 of
				true -> 
					K3 = 1,
					NewT7 = NewT70#task{now_kill = T7#task.now_kill - 1};
				false -> 
					K3 = 0,
					NewT7 = NewT70
			end;
		false -> 
			R5 = 0, R6 = 0, R7 = 0,
			K1 = 0, K2 = 0, K3 = 0,
			NewT5 = T5, NewT6 = T6, NewT7 = T7, 
			case T1#task.now_num > 0 andalso T1#task.get_award =:= 0 of
				true -> 
					R1 = 1,
					NewT1 = T1#task{now_num = T1#task.now_num - 1};
				false -> 
					R1 = 0,
					NewT1 = T1
			end,
			case T2#task.now_num > 0 andalso T2#task.get_award =:= 0 of
				true -> 
					R2 = 1,
					NewT2 = T2#task{now_num = T2#task.now_num - 1};
				false -> 
					R2 = 0,
					NewT2 = T2
			end,
			case T3#task.now_num > 0 andalso T3#task.get_award =:= 0 of
				true -> 
					R3 = 1,
					NewT3 = T3#task{now_num = T3#task.now_num - 1};
				false -> 
					R3 = 0,
					NewT3 = T3
			end,
			case T4#task.now_num > 0 andalso T4#task.get_award =:= 0 of
				true -> 
					R4 = 1,
					NewT4 = T4#task{now_num = T4#task.now_num - 1};
				false -> 
					R4 = 0,
					NewT4 = T4
			end
	end,
	%% 更新
    put({player_task, KilledId}, Arena#arena{task1 = NewT1, task2 = NewT2, task3 = NewT3, task4 = NewT4, task5 = NewT5, task6 = NewT6, task7 = NewT7}),
    Reply = {R1, R2, R3, R4, R5, R6, R7, TName1, TName2, TName3, TName4, TName5, TName6, TName7, K1, K2, K3, KillName1, KillName2, KillName3},
	{reply, Reply, State};

%% 击杀其他玩家，获得物品
handle_call({get_by_others, Id, TNum1, TNum2, TNum3, TNum4, TNum5, TNum6, TNum7, KNum1, KNum2, KNum3}, _From, State) ->
	case get({player_task, Id}) of
        undefined ->
            PlayerLv = lib_player:get_player_info(Id, lv),
            {_Scene, _CopyId, _X, _Y} = lib_player:get_player_info(Id, position_info),
            Arena = lib_wubianhai_new:load_player_info(Id, PlayerLv, _CopyId),
            put({player_task, Id}, Arena);
        Arena -> skip
    end,
	T1 = Arena#arena.task1,
	T2 = Arena#arena.task2,
	T3 = Arena#arena.task3,
	T4 = Arena#arena.task4,
	T5 = Arena#arena.task5,
	T6 = Arena#arena.task6,
	T7 = Arena#arena.task7,
	TotalNum1 = T1#task.num,
	TotalNum2 = T2#task.num,
	TotalNum3 = T3#task.num,
	TotalNum4 = T4#task.num,
	TotalNum5 = T5#task.num,
	TotalNum6 = T6#task.num,
	TotalNum7 = T7#task.num,
	case T1#task.get_award =:=1 andalso T2#task.get_award =:=1 andalso T3#task.get_award =:=1 andalso T4#task.get_award =:=1 of
		true -> 
			NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, 
			NewTNum1 = 0, NewTNum2 = 0, NewTNum3 = 0, NewTNum4 = 0,
			% 物品判断
			case T5#task.now_num < TotalNum5 of
				true -> 
					NewTNum5 = TNum5,
					NewT50 = T5#task{now_num = T5#task.now_num + TNum5};
				false -> 
					NewTNum5 = 0,
					NewT50 = T5
			end,
			% 杀人判断
			case T5#task.now_kill < T5#task.kill_num of
				true -> 
					K1 = 1,
					NewT5 = NewT50#task{now_kill = T5#task.now_kill + KNum1};
				false -> 
					K1 = 0,
					NewT5 = NewT50
			end,
			% 物品判断
			case T6#task.now_num < TotalNum6 of
				true -> 
					NewTNum6 = TNum6,
					NewT60 = T6#task{now_num = T6#task.now_num + TNum6};
				false -> 
					NewTNum6 = 0,
					NewT60 = T6
			end,
			% 杀人判断
			case T6#task.now_kill < T6#task.kill_num of
				true -> 
					K2 = 1,
					NewT6 = NewT60#task{now_kill = T6#task.now_kill + KNum2};
				false -> 
					K2 = 0,
					NewT6 = NewT60
			end,
			% 物品判断
			case T7#task.now_num < TotalNum7 of
				true -> 
					NewTNum7 = TNum7,
					NewT70 = T7#task{now_num = T7#task.now_num + TNum7};
				false -> 
					NewTNum7 = 0,
					NewT70 = T7
			end,
			% 杀人判断
			case T7#task.now_kill < T7#task.kill_num of
				true -> 
					K3 = 1,
					NewT7 = NewT70#task{now_kill = T7#task.now_kill + KNum3};
				false -> 
					K3 = 0,
					NewT7 = NewT70
			end;
		false -> 
			NewT5 = T5, NewT6 = T6, NewT7 = T7, 
			K1 = 0, K2 = 0, K3 = 0,
			NewTNum5 = 0, NewTNum6 = 0, NewTNum7 = 0,
			case T1#task.now_num < TotalNum1 of
				true -> 
					NewTNum1 = TNum1,
					NewT1 = T1#task{now_num = T1#task.now_num + TNum1};
				false -> 
					NewTNum1 = 0,
					NewT1 = T1
			end,
			case T2#task.now_num < TotalNum2 of
				true -> 
					NewTNum2 = TNum2,
					NewT2 = T2#task{now_num = T2#task.now_num + TNum2};
				false -> 
					NewTNum2 = 0,
					NewT2 = T2
			end,
			case T3#task.now_num < TotalNum3 of
				true -> 
					NewTNum3 = TNum3,
					NewT3 = T3#task{now_num = T3#task.now_num + TNum3};
				false -> 
					NewTNum3 = 0,
					NewT3 = T3
			end,
			case T4#task.now_num < TotalNum4 of
				true -> 
					NewTNum4 = TNum4,
					NewT4 = T4#task{now_num = T4#task.now_num + TNum4};
				false -> 
					NewTNum4 = 0,
					NewT4 = T4
			end
	end,
	%% 更新
    put({player_task, Id}, Arena#arena{task1 = NewT1, task2 = NewT2, task3 = NewT3, task4 = NewT4, task5 = NewT5, task6 = NewT6, task7 = NewT7}),
	Reply = [NewTNum1, NewTNum2, NewTNum3, NewTNum4, NewTNum5, NewTNum6, NewTNum7, K1, K2, K3],
	{reply, Reply, State};

%% 生成世界等级
handle_call({set_world_level}, _From, State) ->
    Reply = case get(world_level) of
        undefined ->
            %% 世界等级
            WorldLv = lib_player:world_lv(1),
            put(world_level, WorldLv),
            WorldLv;
        AnyLv -> AnyLv
    end,
    {reply, Reply, State};

%%获取进入前的PK状态
handle_call({get_last_pk_status, PlayerId}, _From, State) ->
    Reply = case get({last_pk_status, PlayerId}) of
        undefined ->
            0;
        Any -> Any
    end,
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({set_time,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute}, _State) ->
    L = mod_chat_agent:match(all_ids_by_lv_gap, [35, 999]),
    spawn(fun()-> 
                lists:foreach(fun(Id) -> 
                            lib_player:update_player_info(Id, [{wubianhai_time, [Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute]}]),
                            lib_player_unite:update_unite_info(Id, [{wubianhai_time, [Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute]}]),
                            timer:sleep(100)
                    end, L)
        end),
	NewState = #state{config_begin_hour=Config_Begin_Hour,
					  config_begin_minute=Config_Begin_Minute,
					  config_end_hour=Config_End_Hour,
					  config_end_minute=Config_End_Minute},
	{noreply, NewState};

%%记录进入前的PK状态
handle_cast({insert_last_pk_status, PlayerId, PkValue}, State) ->
    put({last_pk_status, PlayerId}, PkValue),
	{noreply, State};

handle_cast({set_status,Arena_Status}, State) ->
	case Arena_Status of
		0->
			NewState = #state{config_begin_hour=State#state.config_begin_hour,
					  config_begin_minute=State#state.config_begin_minute,
					  config_end_hour=State#state.config_end_hour,
					  config_end_minute=State#state.config_end_minute};
		_->NewState = State#state{arena_stauts=Arena_Status}
	end,
	{noreply, NewState};

%% 活动开始，对满足等级的玩家进行广播处理
handle_cast({open_arena}, State) ->
	Apply_level = data_wubianhai_new:get_wubianhai_config(apply_level),
	Time = lib_wubianhai_new:get_arena_remain_time(State#state.config_begin_hour,State#state.config_begin_minute,State#state.config_end_hour,State#state.config_end_minute),
	{ok, BinData} = pt_640:write(64001, [1, Time]),
	lib_unite_send:send_to_all(Apply_level, 999, BinData),
    {noreply, State};

%% 杀怪，获得物品
handle_cast({kill_mon, Id, MonId}, State) ->
    case get({player_task, Id}) of
        undefined -> 
            PlayerLv = lib_player:get_player_info(Id, lv),
            {_Scene, _CopyId, _X, _Y} = lib_player:get_player_info(Id, position_info),
            Arena = lib_wubianhai_new:load_player_info(Id, PlayerLv, _CopyId),
            put({player_task, Id}, Arena);
        Arena -> skip
    end,
	T1 = Arena#arena.task1,
	T2 = Arena#arena.task2,
	T3 = Arena#arena.task3,
	T4 = Arena#arena.task4,
	T5 = Arena#arena.task5,
	T6 = Arena#arena.task6,
	T7 = Arena#arena.task7,
	RoomId = Arena#arena.room_id,
	Mon1 = T1#task.mon_id,
	Mon2 = T2#task.mon_id,
	Mon3 = T3#task.mon_id,
	Mon4 = T4#task.mon_id,
	Mon5 = T5#task.mon_id,
	Mon6 = T6#task.mon_id,
	Mon7 = T7#task.mon_id,
	TNum1 = T1#task.num,
	TNum2 = T2#task.num,
	TNum3 = T3#task.num,
	TNum4 = T4#task.num,
	TNum5 = T5#task.num,
	TNum6 = T6#task.num,
	TNum7 = T7#task.num,
	GetAward1 = T1#task.get_award,
	GetAward2 = T2#task.get_award,
	GetAward3 = T3#task.get_award,
	GetAward4 = T4#task.get_award,
	case MonId of
		Mon1 -> 
            MonName = T1#task.task_name,
			case GetAward1 =:= 1 andalso GetAward2 =:= 1 andalso GetAward3 =:= 1 andalso GetAward4 =:= 1 of
				false ->
					case T1#task.now_num < TNum1 of
						true ->
                            TaskAdd = 1,
							NewT1 = T1#task{now_num = T1#task.now_num + 1},
							NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7;
						false -> 
                            TaskAdd = 0,
                            NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
					end;
				true -> 
                    TaskAdd = 0,
                    NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
			end;
		Mon2 -> 
            MonName = T2#task.task_name,
			case GetAward1 =:= 1 andalso GetAward2 =:= 1 andalso GetAward3 =:= 1 andalso GetAward4 =:= 1 of
				false ->
					case T2#task.now_num < TNum2 of
						true ->
                            TaskAdd = 1,
							NewT2 = T2#task{now_num = T2#task.now_num + 1},
							NewT1 = T1, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7;
						false -> 
                            TaskAdd = 0,
                            NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
					end;
				true -> 
                    TaskAdd = 0,
                    NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
			end;
		Mon3 -> 
            MonName = T3#task.task_name,
			case GetAward1 =:= 1 andalso GetAward2 =:= 1 andalso GetAward3 =:= 1 andalso GetAward4 =:= 1 of
				false ->
					case T3#task.now_num < TNum3 of
						true ->
                            TaskAdd = 1,
							NewT3 = T3#task{now_num = T3#task.now_num + 1},
							NewT1 = T1, NewT2 = T2, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7;
						false -> 
                            TaskAdd = 0,
                            NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
					end;
				true -> 
                    TaskAdd = 0,
                    NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
			end;
		Mon4 -> 
            MonName = T4#task.task_name,
			case GetAward1 =:= 1 andalso GetAward2 =:= 1 andalso GetAward3 =:= 1 andalso GetAward4 =:= 1 of
				false ->
					case T4#task.now_num < TNum4 of
						true ->
                            TaskAdd = 1,
							NewT4 = T4#task{now_num = T4#task.now_num + 1},
							NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT5 = T5, NewT6 = T6, NewT7 = T7;
						false -> 
                            TaskAdd = 0,
                            NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
					end;
				true -> 
                    TaskAdd = 0,
                    NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
			end;
		Mon5 -> 
            MonName = T5#task.task_name,
			case GetAward1 =:= 1 andalso GetAward2 =:= 1 andalso GetAward3 =:= 1 andalso GetAward4 =:= 1 of
				true ->
					case T5#task.now_num < TNum5 of
						true ->
                            TaskAdd = 1,
							NewT5 = T5#task{now_num = T5#task.now_num + 1},
							NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT6 = T6, NewT7 = T7;
						false -> 
                            TaskAdd = 0,
                            NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
					end;
				false -> 
                    TaskAdd = 0,
                    NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
			end;
		Mon6 -> 
            MonName = T6#task.task_name,
			case GetAward1 =:= 1 andalso GetAward2 =:= 1 andalso GetAward3 =:= 1 andalso GetAward4 =:= 1 of
				true ->
					case T6#task.now_num < TNum6 of
						true ->
                            TaskAdd = 1,
							NewT6 = T6#task{now_num = T6#task.now_num + 1},
							NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT7 = T7;
						false -> 
                            TaskAdd = 0,
                            NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
					end;
				false -> 
                    TaskAdd = 0,
                    NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
			end;
		Mon7 -> 
            MonName = T7#task.task_name,
			case GetAward1 =:= 1 andalso GetAward2 =:= 1 andalso GetAward3 =:= 1 andalso GetAward4 =:= 1 of
				true ->
					case T7#task.now_num < TNum7 of
						true ->
                            TaskAdd = 1,
							NewT7 = T7#task{now_num = T7#task.now_num + 1},
							NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6;
						false -> 
                            TaskAdd = 0,
                            NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
					end;
			false -> 
                TaskAdd = 0,
                NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
			end;
		_ ->
            TaskAdd = 0,
            MonName = "",
			NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7
	end,
    case TaskAdd of
        1 ->
            %% 右下角提示 "XX + 1"
            Msg = lists:concat([MonName, " + 1"]),
            {ok, BinData1} = pt_110:write(11004, Msg),
            lib_unite_send:send_to_uid(Id, BinData1);
        _ -> 
            skip
    end,
	%% 更新Boss刷新时间
	case MonId =:= Mon7 of
        true -> 
            put({wubianhai_boss, RoomId}, util:unixtime()),
            BossRefreshTime = data_wubianhai_new:get_wubianhai_config(boss_refresh_time),
            SceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
            CopyId = RoomId,
            {ok, BinData2} = pt_640:write(64007, BossRefreshTime),
            %% 按场景ID和房间ID发送
            lib_unite_send:send_to_scene(SceneId, CopyId, BinData2);
        false -> skip
    end,
    %% 更新
    put({player_task, Id}, Arena#arena{task1 = NewT1, task2 = NewT2, task3 = NewT3, task4 = NewT4, task5 = NewT5, task6 = NewT6, task7 = NewT7}),
    {noreply, State};

%% 进入房间
handle_cast({enter_arena, Id, PlayerLv, RoomId}, State) ->
    %% 用于日志
    put({all_get_in, Id}, no),
    %% 维护房间内人数
    case get({all_room, RoomId}) of
        undefined -> 
            put({all_room, RoomId}, {1, 1});
            %MaxNum = 1;
        {Num, _MaxNum} -> 
            MaxNum = _MaxNum + 1,
            put({all_room, RoomId}, {Num+1, MaxNum})
    end,
    %% 维护房间在线信息
    put({is_in_arena, Id}, RoomId),
    %% 玩家获取任务
    case get({player_task, Id}) of
        undefined -> 
            case data_wubianhai_new:get_task_lv(PlayerLv) of
                3 ->
                    [Tid1, MonId1, Num1, AwardIdList1, Exp1, Lilian1, TaskName1, MonX1, MonY1] = data_wubianhai_new:get_wubianhai_config(task1_3),
                    [Tid2, MonId2, Num2, AwardIdList2, Exp2, Lilian2, TaskName2, MonX2, MonY2] = data_wubianhai_new:get_wubianhai_config(task2_3),
                    [Tid3, MonId3, Num3, AwardIdList3, Exp3, Lilian3, TaskName3, MonX3, MonY3] = data_wubianhai_new:get_wubianhai_config(task3_3),
                    [Tid4, MonId4, Num4, AwardIdList4, Exp4, Lilian4, TaskName4, MonX4, MonY4] = data_wubianhai_new:get_wubianhai_config(task4_3),
                    [Tid5, MonId5, Num5, AwardIdList5, Exp5, Lilian5, TaskName5, MonX5, MonY5] = data_wubianhai_new:get_wubianhai_config(task5_3),
                    [Tid6, MonId6, Num6, AwardIdList6, Exp6, Lilian6, TaskName6, MonX6, MonY6] = data_wubianhai_new:get_wubianhai_config(task6_3),
                    [Tid7, MonId7, Num7, AwardIdList7, Exp7, Lilian7, TaskName7, MonX7, MonY7] = data_wubianhai_new:get_wubianhai_config(task7_3);
                4 ->
                    [Tid1, MonId1, Num1, AwardIdList1, Exp1, Lilian1, TaskName1, MonX1, MonY1] = data_wubianhai_new:get_wubianhai_config(task1_4),
                    [Tid2, MonId2, Num2, AwardIdList2, Exp2, Lilian2, TaskName2, MonX2, MonY2] = data_wubianhai_new:get_wubianhai_config(task2_4),
                    [Tid3, MonId3, Num3, AwardIdList3, Exp3, Lilian3, TaskName3, MonX3, MonY3] = data_wubianhai_new:get_wubianhai_config(task3_4),
                    [Tid4, MonId4, Num4, AwardIdList4, Exp4, Lilian4, TaskName4, MonX4, MonY4] = data_wubianhai_new:get_wubianhai_config(task4_4),
                    [Tid5, MonId5, Num5, AwardIdList5, Exp5, Lilian5, TaskName5, MonX5, MonY5] = data_wubianhai_new:get_wubianhai_config(task5_4),
                    [Tid6, MonId6, Num6, AwardIdList6, Exp6, Lilian6, TaskName6, MonX6, MonY6] = data_wubianhai_new:get_wubianhai_config(task6_4),
                    [Tid7, MonId7, Num7, AwardIdList7, Exp7, Lilian7, TaskName7, MonX7, MonY7] = data_wubianhai_new:get_wubianhai_config(task7_4);
                5 ->
                    [Tid1, MonId1, Num1, AwardIdList1, Exp1, Lilian1, TaskName1, MonX1, MonY1] = data_wubianhai_new:get_wubianhai_config(task1_5),
                    [Tid2, MonId2, Num2, AwardIdList2, Exp2, Lilian2, TaskName2, MonX2, MonY2] = data_wubianhai_new:get_wubianhai_config(task2_5),
                    [Tid3, MonId3, Num3, AwardIdList3, Exp3, Lilian3, TaskName3, MonX3, MonY3] = data_wubianhai_new:get_wubianhai_config(task3_5),
                    [Tid4, MonId4, Num4, AwardIdList4, Exp4, Lilian4, TaskName4, MonX4, MonY4] = data_wubianhai_new:get_wubianhai_config(task4_5),
                    [Tid5, MonId5, Num5, AwardIdList5, Exp5, Lilian5, TaskName5, MonX5, MonY5] = data_wubianhai_new:get_wubianhai_config(task5_5),
                    [Tid6, MonId6, Num6, AwardIdList6, Exp6, Lilian6, TaskName6, MonX6, MonY6] = data_wubianhai_new:get_wubianhai_config(task6_5),
                    [Tid7, MonId7, Num7, AwardIdList7, Exp7, Lilian7, TaskName7, MonX7, MonY7] = data_wubianhai_new:get_wubianhai_config(task7_5);
                _ ->
                    [Tid1, MonId1, Num1, AwardIdList1, Exp1, Lilian1, TaskName1, MonX1, MonY1] = data_wubianhai_new:get_wubianhai_config(task1_5),
                    [Tid2, MonId2, Num2, AwardIdList2, Exp2, Lilian2, TaskName2, MonX2, MonY2] = data_wubianhai_new:get_wubianhai_config(task2_5),
                    [Tid3, MonId3, Num3, AwardIdList3, Exp3, Lilian3, TaskName3, MonX3, MonY3] = data_wubianhai_new:get_wubianhai_config(task3_5),
                    [Tid4, MonId4, Num4, AwardIdList4, Exp4, Lilian4, TaskName4, MonX4, MonY4] = data_wubianhai_new:get_wubianhai_config(task4_5),
                    [Tid5, MonId5, Num5, AwardIdList5, Exp5, Lilian5, TaskName5, MonX5, MonY5] = data_wubianhai_new:get_wubianhai_config(task5_5),
                    [Tid6, MonId6, Num6, AwardIdList6, Exp6, Lilian6, TaskName6, MonX6, MonY6] = data_wubianhai_new:get_wubianhai_config(task6_5),
                    [Tid7, MonId7, Num7, AwardIdList7, Exp7, Lilian7, TaskName7, MonX7, MonY7] = data_wubianhai_new:get_wubianhai_config(task7_5)
            end,
            %% 击杀玩家信息
            [{KillName1, KillNum1}, {KillName2, KillNum2}, {KillName3, KillNum3}] = data_wubianhai_new:get_wubianhai_config(kill_task),
            %% 从数据库读数据
            [Task1Num, Task2Num, Task3Num, Task4Num, Task5Num, Task6Num, Task7Num, KillNum] = lib_wubianhai_new:get_from_database(Id),
            case KillNum > KillNum1 of
                true -> NowKill1 = KillNum1;
                false -> NowKill1 = KillNum
            end,
            case KillNum > KillNum2 of
                true -> NowKill2 = KillNum2;
                false -> NowKill2 = KillNum
            end,
            case KillNum > KillNum3 of
                true -> NowKill3 = KillNum3;
                false -> NowKill3 = KillNum
            end,
            %% 触发任务
            T1 = #task{id=Id, tid=Tid1, mon_id=MonId1, num=Num1, now_num = Task1Num, award_id_list=AwardIdList1, exp=Exp1, lilian=Lilian1, task_name=TaskName1, mon_x = MonX1, mon_y = MonY1},
            T2 = #task{id=Id, tid=Tid2, mon_id=MonId2, num=Num2, now_num = Task2Num, award_id_list=AwardIdList2, exp=Exp2, lilian=Lilian2, task_name=TaskName2, mon_x = MonX2, mon_y = MonY2},
            T3 = #task{id=Id, tid=Tid3, mon_id=MonId3, num=Num3, now_num = Task3Num, award_id_list=AwardIdList3, exp=Exp3, lilian=Lilian3, task_name=TaskName3, mon_x = MonX3, mon_y = MonY3},
            T4 = #task{id=Id, tid=Tid4, mon_id=MonId4, num=Num4, now_num = Task4Num, award_id_list=AwardIdList4, exp=Exp4, lilian=Lilian4, task_name=TaskName4, mon_x = MonX4, mon_y = MonY4},
            T5 = #task{id=Id, tid=Tid5, mon_id=MonId5, num=Num5, now_num = Task5Num, award_id_list=AwardIdList5, exp=Exp5, lilian=Lilian5, task_name=TaskName5, kill_name = KillName1, kill_num = KillNum1, now_kill = NowKill1, mon_x = MonX5, mon_y = MonY5},
            T6 = #task{id=Id, tid=Tid6, mon_id=MonId6, num=Num6, now_num = Task6Num, award_id_list=AwardIdList6, exp=Exp6, lilian=Lilian6, task_name=TaskName6, kill_name = KillName2, kill_num = KillNum2, now_kill = NowKill2, mon_x = MonX6, mon_y = MonY6},
            _T7 = #task{id=Id, tid=Tid7, mon_id=MonId7, num=Num7, now_num = Task7Num, award_id_list=AwardIdList7, exp=Exp7, lilian=Lilian7, task_name=TaskName7, kill_name = KillName3, kill_num = KillNum3, now_kill = NowKill3, mon_x = MonX7, mon_y = MonY7},
            NewArena = #arena{
                id = Id, 
                player_lv = PlayerLv,
                room_id = RoomId,
                task1 = T1,
                task2 = T2,
                task3 = T3,
                task4 = T4,
                task5 = T5,
                task6 = T6},
            put({player_task, Id}, NewArena);
        _Arena -> skip 
            %MonId = data_wubianhai_new:get_wubianhai_config(mon_id),
            %[MonId1, MonId2, MonId3, MonId4, MonId5, MonId6, MonId7] = MonId
    end,
    {noreply, State};

%% 退出房间
handle_cast({quit_arena, Id}, State) ->
    %% 维护房间内人数
    case get({is_in_arena, Id}) of
        undefined -> skip;
        RoomId ->
            case get({all_room, RoomId}) of
                undefined -> skip;
                {Num, MaxNum} -> 
                    case Num =< 0 of
                        true -> put({all_room, RoomId}, {0, MaxNum});
                        false -> put({all_room, RoomId}, {Num-1, MaxNum})
                    end
            end
    end,
	erase({is_in_arena, Id}),
    {noreply, State};

%% 活动结束，进行广播
handle_cast({end_arena}, State) ->
	%% 把活动场景中的玩家传送出去
	GetAll = get(), 
	IdList = lib_wubianhai_new:list_deal(GetAll, []),
    spawn(fun() -> lib_wubianhai_new:send_end(IdList, 0) end),
    spawn(
        fun() ->
                log_deal(GetAll, 0, 0, 0, 0, 0, 0, 0)
        end),
    {noreply, State};

%% 活动结束后进行清场
handle_cast({clear}, _State) ->
    %% 结束，清数据
        {{_,_,_},{Hour,Minute,_}} = calendar:local_time(),
    [[Config_Begin_Hour,Config_Begin_Minute],[Config_End_Hour,Config_End_Minute]] = data_wubianhai_new:get_wubianhai_config(arena_time),
    case  Config_Begin_Hour =:= 19 of
        true ->
            Arena_status = 0,
            NewState = #state{arena_stauts=Arena_status, config_begin_hour=Config_Begin_Hour, config_begin_minute=Config_Begin_Minute, config_end_hour=Config_End_Hour, config_end_minute=Config_End_Minute},
            {noreply, NewState};
        _ ->       
            Arena_status = 2,
            %%[[Config_Begin_Hour,Config_Begin_Minute],[Config_End_Hour,Config_End_Minute]] = data_wubianhai_new:get_wubianhai_config(arena_time),
            NewState = #state{arena_stauts=Arena_status, config_begin_hour=Config_Begin_Hour, config_begin_minute=Config_Begin_Minute, config_end_hour=Config_End_Hour, config_end_minute=Config_End_Minute},
            %NewState = State#state{arena_stauts=Arena_status},
            erase(),
            {noreply, NewState}
    end;

handle_cast({cast_64003, UniteStatus}, State) ->
    Id = UniteStatus#unite_status.id,
    %% 获取玩家任务列表
    case get({player_task, Id}) of
        undefined ->
            PlayerLv = lib_player:get_player_info(Id, lv),
            {_Scene, _CopyId, _X, _Y} = lib_player:get_player_info(Id, position_info),
            Arena = lib_wubianhai_new:load_player_info(Id, PlayerLv, _CopyId),
            put({player_task, Id}, Arena);
        Arena -> skip
    end,
	T1 = Arena#arena.task1,
	T2 = Arena#arena.task2,
	T3 = Arena#arena.task3,
	T4 = Arena#arena.task4,
	T5 = Arena#arena.task5,
	T6 = Arena#arena.task6,
	T7 = Arena#arena.task7,
	case T1#task.get_award =:= 1 andalso T2#task.get_award =:= 1 andalso T3#task.get_award =:= 1 andalso T4#task.get_award =:= 1 of
		true -> 
			Tid5 = T5#task.tid,
			Tid6 = T6#task.tid,
			Tid7 = T7#task.tid,
			TaskName5 = T5#task.task_name,
			TaskName6 = T6#task.task_name,
			TaskName7 = T7#task.task_name,
			NowNum5 = T5#task.now_num,
			NowNum6 = T6#task.now_num,
			NowNum7 = T7#task.now_num,
			Num5 = T5#task.num,
			Num6 = T6#task.num,
			Num7 = T7#task.num,
			GetAward5 = T5#task.get_award,
			GetAward6 = T6#task.get_award,
			GetAward7 = T7#task.get_award,
			AwardIdList5 = T5#task.award_id_list,
			AwardIdList6 = T6#task.award_id_list,
			AwardIdList7 = T7#task.award_id_list,
			AwardString5 = list_deal_to_string(AwardIdList5),
			AwardString6 = list_deal_to_string(AwardIdList6),
			AwardString7 = list_deal_to_string(AwardIdList7),
			Exp5 = T5#task.exp,
			Exp6 = T6#task.exp,
			Exp7 = T7#task.exp,
			Lilian5 = T5#task.lilian,
			Lilian6 = T6#task.lilian,
			Lilian7 = T7#task.lilian,
			KillName5 = T5#task.kill_name,
			KillName6 = T6#task.kill_name,
			KillName7 = T7#task.kill_name,
			KillNum5 = T5#task.kill_num,
			KillNum6 = T6#task.kill_num,
			KillNum7 = T7#task.kill_num,
			NowKill5 = T5#task.now_kill,
			NowKill6 = T6#task.now_kill,
			NowKill7 = T7#task.now_kill,
			MonId5 = T5#task.mon_id,
			MonId6 = T6#task.mon_id,
			MonId7 = T7#task.mon_id,
			MonX5 = T5#task.mon_x,
			MonX6 = T6#task.mon_x,
			MonX7 = T7#task.mon_x,
			MonY5 = T5#task.mon_y,
			MonY6 = T6#task.mon_y,
			MonY7 = T7#task.mon_y,
			_Reply = [{Tid5, TaskName5, NowNum5, Num5, KillName5, NowKill5, KillNum5, GetAward5, AwardString5, Exp5, Lilian5, MonId5, MonX5, MonY5}, {Tid6, TaskName6, NowNum6, Num6, KillName6, NowKill6, KillNum6, GetAward6, AwardString6, Exp6, Lilian6, MonId6, MonX6, MonY6}, {Tid7, TaskName7, NowNum7, Num7, KillName7, NowKill7, KillNum7, GetAward7, AwardString7, Exp7, Lilian7, MonId7, MonX7, MonY7}],
            Reply = [{Tid5, TaskName5, NowNum5, Num5, KillName5, NowKill5, KillNum5, GetAward5, AwardString5, Exp5, Lilian5, MonId5, MonX5, MonY5}, {Tid6, TaskName6, NowNum6, Num6, KillName6, NowKill6, KillNum6, GetAward6, AwardString6, Exp6, Lilian6, MonId6, MonX6, MonY6}];
		false -> 
			Tid1 = T1#task.tid,
			Tid2 = T2#task.tid,
			Tid3 = T3#task.tid,
			Tid4 = T4#task.tid,
			TaskName1 = T1#task.task_name,
			TaskName2 = T2#task.task_name,
			TaskName3 = T3#task.task_name,
			TaskName4 = T4#task.task_name,
			NowNum1 = T1#task.now_num,
			NowNum2 = T2#task.now_num,
			NowNum3 = T3#task.now_num,
			NowNum4 = T4#task.now_num,
			Num1 = T1#task.num,
			Num2 = T2#task.num,
			Num3 = T3#task.num,
			Num4 = T4#task.num,
			GetAward1 = T1#task.get_award,
			GetAward2 = T2#task.get_award,
			GetAward3 = T3#task.get_award,
			GetAward4 = T4#task.get_award,
			AwardIdList1 = T1#task.award_id_list,
			AwardIdList2 = T2#task.award_id_list,
			AwardIdList3 = T3#task.award_id_list,
			AwardIdList4 = T4#task.award_id_list,
			AwardString1 = list_deal_to_string(AwardIdList1),
			AwardString2 = list_deal_to_string(AwardIdList2),
			AwardString3 = list_deal_to_string(AwardIdList3),
			AwardString4 = list_deal_to_string(AwardIdList4),
			Exp1 = T1#task.exp,
			Exp2 = T2#task.exp,
			Exp3 = T3#task.exp,
			Exp4 = T4#task.exp,
			Lilian1 = T1#task.lilian,
			Lilian2 = T2#task.lilian,
			Lilian3 = T3#task.lilian,
			Lilian4 = T4#task.lilian,
			KillName1 = T1#task.kill_name,
			KillName2 = T2#task.kill_name,
			KillName3 = T3#task.kill_name,
			KillName4 = T4#task.kill_name,
			KillNum1 = T1#task.kill_num,
			KillNum2 = T2#task.kill_num,
			KillNum3 = T3#task.kill_num,
			KillNum4 = T4#task.kill_num,
			NowKill1 = T1#task.now_kill,
			NowKill2 = T2#task.now_kill,
			NowKill3 = T3#task.now_kill,
			NowKill4 = T4#task.now_kill,
			MonId1 = T1#task.mon_id,
			MonId2 = T2#task.mon_id,
			MonId3 = T3#task.mon_id,
			MonId4 = T4#task.mon_id,
			MonX1 = T1#task.mon_x,
			MonX2 = T2#task.mon_x,
			MonX3 = T3#task.mon_x,
			MonX4 = T4#task.mon_x,
			MonY1 = T1#task.mon_y,
			MonY2 = T2#task.mon_y,
			MonY3 = T3#task.mon_y,
			MonY4 = T4#task.mon_y,
			Reply = [{Tid1, TaskName1, NowNum1, Num1, KillName1, NowKill1, KillNum1, GetAward1, AwardString1, Exp1, Lilian1, MonId1, MonX1, MonY1}, {Tid2, TaskName2, NowNum2, Num2, KillName2, NowKill2, KillNum2, GetAward2, AwardString2, Exp2, Lilian2, MonId2, MonX2, MonY2}, {Tid3, TaskName3, NowNum3, Num3, KillName3, NowKill3, KillNum3, GetAward3, AwardString3, Exp3, Lilian3, MonId3, MonX3, MonY3}, {Tid4, TaskName4, NowNum4, Num4, KillName4, NowKill4, KillNum4, GetAward4, AwardString4, Exp4, Lilian4, MonId4, MonX4, MonY4}]
	end,
    TaskList = Reply,
    %% 开始结束时间
    [BeginHour, BeginMin, EndHour, EndMin] = [State#state.config_begin_hour, State#state.config_begin_minute, State#state.config_end_hour, State#state.config_end_minute],
    %% 中间Boss剩余刷新时间
    %% BOSS上次死亡时间
    BossRefreshTime = data_wubianhai_new:get_wubianhai_config(boss_refresh_time),
    BossLastTime = case get({is_in_arena, Id}) of
        undefined -> 0;
        RoomId -> 
            case get({wubianhai_boss, RoomId}) of
                undefined -> 0;
                _BossTime -> _BossTime
            end
    end,
    Now = util:unixtime(),
    BossRestTime = case Now - BossLastTime > 0 andalso Now - BossLastTime < BossRefreshTime of
        true -> BossRefreshTime - (Now - BossLastTime);
        false -> 0
    end,
	%% 活动剩余时间
	RestTime = lib_wubianhai_new:get_arena_remain_time(BeginHour, BeginMin, EndHour, EndMin),
    %% 房间ID
    MyRoomId = case get({is_in_arena, Id}) of
		undefined -> 0;
        _MyRoomId -> _MyRoomId
	end,
    Award = data_wubianhai_new:get_wubianhai_config(award),
	Bin = pp_wubianhai:pack(TaskList, BossRestTime, RestTime, MyRoomId, Award),
	{ok, BinData} = pt_640:write(64003, Bin),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    {noreply, State};

%%任务领奖
handle_cast({award, UniteStatus, TaskId}, State) ->
    Id = UniteStatus#unite_status.id,
    case get({player_task, Id}) of
        undefined -> 
            PlayerLv = lib_player:get_player_info(Id, lv),
            {_Scene, _CopyId, _X, _Y} = lib_player:get_player_info(Id, position_info),
            Arena = lib_wubianhai_new:load_player_info(Id, PlayerLv, _CopyId),
            put({player_task, Id}, Arena);
        Arena -> skip
    end,
	T1 = Arena#arena.task1,
	T2 = Arena#arena.task2,
	T3 = Arena#arena.task3,
	T4 = Arena#arena.task4,
	T5 = Arena#arena.task5,
	T6 = Arena#arena.task6,
	T7 = Arena#arena.task7,
	Tid1 = T1#task.tid,
	Tid2 = T2#task.tid,
	Tid3 = T3#task.tid,
	Tid4 = T4#task.tid,
	Tid5 = T5#task.tid,
	Tid6 = T6#task.tid,
	Tid7 = T7#task.tid,
	T = case TaskId of
		Tid1 -> T1;
		Tid2 -> T2;
		Tid3 -> T3;
		Tid4 -> T4;
		Tid5 -> T5;
		Tid6 -> T6;
		Tid7 -> T7;
		_ -> error
	end,
	case T of
		error -> 
			TT = #task{},
			Reply = 3;%% 失败，未知任务
		Any ->
			case Any#task.num =< Any#task.now_num andalso Any#task.kill_num =< Any#task.now_kill of
				false -> 
                    TT = #task{},
					Reply = 3;%% 失败，任务未达成
				true ->
                    TT = T,
					case Any#task.get_award of
						1 -> 
							Reply = 2;%% 失败，已领取
						0 -> 
							%% 更新
                            case TaskId of
                                1 -> 
                                    NewT1 = T#task{get_award = 1},
                                    NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7;
                                2 -> 
                                    NewT2 = T#task{get_award = 1},
                                    NewT1 = T1, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7;
                                3 -> 
                                    NewT3 = T#task{get_award = 1},
                                    NewT1 = T1, NewT2 = T2, NewT4 = T4, NewT5 = T5, NewT6 = T6, NewT7 = T7;
                                4 -> 
                                    NewT4 = T#task{get_award = 1},
                                    NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT5 = T5, NewT6 = T6, NewT7 = T7;
                                5 -> 
                                    NewT5 = T#task{get_award = 1},
                                    NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT6 = T6, NewT7 = T7;
                                6 -> 
                                    NewT6 = T#task{get_award = 1},
                                    NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT7 = T7;
                                _ -> 
                                    NewT7 = T#task{get_award = 1},
                                    NewT1 = T1, NewT2 = T2, NewT3 = T3, NewT4 = T4, NewT5 = T5, NewT6 = T6
                            end,
                            put({player_task, Id}, Arena#arena{task1=NewT1, task2=NewT2, task3=NewT3, task4=NewT4, task5=NewT5, task6=NewT6, task7=NewT7}),
							AwardIdList = Any#task.award_id_list,
							Exp = Any#task.exp,
							Lilian = Any#task.lilian,
                            GoodsPid = lib_player:get_player_info(Id, goods_pid),
                            case GoodsPid of
                                false -> skip;
                                _ -> lib_player:send_wubianhai_award(GoodsPid, AwardIdList, T#task.tid, Id, Exp, Lilian)
                            end,
                            %% 日志，完成任务数量
                            AllTaskNum = case get({all_awards, TaskId}) of
                                undefined -> 1;
                                _AllTaskNum -> _AllTaskNum + 1
                            end,
                            %io:format("TaskId:~p, AllTaskNum:~p~n", [TaskId, AllTaskNum]),
                            put({all_awards, TaskId}, AllTaskNum),
							Reply = 1
					end
			end
	end,
    Reply2 = {Reply, TT#task.award_id_list},
    {Error, AwardList} = Reply2,
    %% 发送圣诞礼包
    case date() =< {2013, 2, 2} of
        true ->
            case Error of
                1 ->
                    Title = data_wubianhai_new:get_wubianhai_text(2),
                    Content =  data_wubianhai_new:get_wubianhai_text(3),
                    GoodsId = 534096,
                    GoodsNum = 1,
                    Id = UniteStatus#unite_status.id,
                    lib_mail:send_sys_mail_bg([Id], Title, Content, GoodsId, 2, 0, 0, GoodsNum, 0, 0, 0, 0);
                _ ->
                    skip
            end;
        false ->
            skip
    end,
    Bin = pp_wubianhai:pack1(Error, AwardList),
    {ok, BinData} = pt_640:write(64004, Bin),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	{noreply, State};

%%获取玩家任务信息
handle_cast({get_task_list, Id}, State) ->
    case get({player_task, Id}) of
        undefined ->
            PlayerLv = lib_player:get_player_info(Id, lv),
            {_Scene, _CopyId, _X, _Y} = lib_player:get_player_info(Id, position_info),
            Arena = lib_wubianhai_new:load_player_info(Id, PlayerLv, _CopyId),
            put({player_task, Id}, Arena);
        Arena -> skip
    end,
	T1 = Arena#arena.task1,
	T2 = Arena#arena.task2,
	T3 = Arena#arena.task3,
	T4 = Arena#arena.task4,
	T5 = Arena#arena.task5,
	T6 = Arena#arena.task6,
	T7 = Arena#arena.task7,
	case T1#task.get_award =:= 1 andalso T2#task.get_award =:= 1 andalso T3#task.get_award =:= 1 andalso T4#task.get_award =:= 1 of
		true -> 
			Tid5 = T5#task.tid,
			Tid6 = T6#task.tid,
			Tid7 = T7#task.tid,
			TaskName5 = T5#task.task_name,
			TaskName6 = T6#task.task_name,
			TaskName7 = T7#task.task_name,
			NowNum5 = T5#task.now_num,
			NowNum6 = T6#task.now_num,
			NowNum7 = T7#task.now_num,
			Num5 = T5#task.num,
			Num6 = T6#task.num,
			Num7 = T7#task.num,
			GetAward5 = T5#task.get_award,
			GetAward6 = T6#task.get_award,
			GetAward7 = T7#task.get_award,
			AwardIdList5 = T5#task.award_id_list,
			AwardIdList6 = T6#task.award_id_list,
			AwardIdList7 = T7#task.award_id_list,
			AwardString5 = list_deal_to_string(AwardIdList5),
			AwardString6 = list_deal_to_string(AwardIdList6),
			AwardString7 = list_deal_to_string(AwardIdList7),
			Exp5 = T5#task.exp,
			Exp6 = T6#task.exp,
			Exp7 = T7#task.exp,
			Lilian5 = T5#task.lilian,
			Lilian6 = T6#task.lilian,
			Lilian7 = T7#task.lilian,
			KillName5 = T5#task.kill_name,
			KillName6 = T6#task.kill_name,
			KillName7 = T7#task.kill_name,
			KillNum5 = T5#task.kill_num,
			KillNum6 = T6#task.kill_num,
			KillNum7 = T7#task.kill_num,
			NowKill5 = T5#task.now_kill,
			NowKill6 = T6#task.now_kill,
			NowKill7 = T7#task.now_kill,
			MonId5 = T5#task.mon_id,
			MonId6 = T6#task.mon_id,
			MonId7 = T7#task.mon_id,
			MonX5 = T5#task.mon_x,
			MonX6 = T6#task.mon_x,
			MonX7 = T7#task.mon_x,
			MonY5 = T5#task.mon_y,
			MonY6 = T6#task.mon_y,
			MonY7 = T7#task.mon_y,
			_Reply = [{Tid5, TaskName5, NowNum5, Num5, KillName5, NowKill5, KillNum5, GetAward5, AwardString5, Exp5, Lilian5, MonId5, MonX5, MonY5}, {Tid6, TaskName6, NowNum6, Num6, KillName6, NowKill6, KillNum6, GetAward6, AwardString6, Exp6, Lilian6, MonId6, MonX6, MonY6}, {Tid7, TaskName7, NowNum7, Num7, KillName7, NowKill7, KillNum7, GetAward7, AwardString7, Exp7, Lilian7, MonId7, MonX7, MonY7}],
            Reply = [{Tid5, TaskName5, NowNum5, Num5, KillName5, NowKill5, KillNum5, GetAward5, AwardString5, Exp5, Lilian5, MonId5, MonX5, MonY5}, {Tid6, TaskName6, NowNum6, Num6, KillName6, NowKill6, KillNum6, GetAward6, AwardString6, Exp6, Lilian6, MonId6, MonX6, MonY6}];
		false -> 
			Tid1 = T1#task.tid,
			Tid2 = T2#task.tid,
			Tid3 = T3#task.tid,
			Tid4 = T4#task.tid,
			TaskName1 = T1#task.task_name,
			TaskName2 = T2#task.task_name,
			TaskName3 = T3#task.task_name,
			TaskName4 = T4#task.task_name,
			NowNum1 = T1#task.now_num,
			NowNum2 = T2#task.now_num,
			NowNum3 = T3#task.now_num,
			NowNum4 = T4#task.now_num,
			Num1 = T1#task.num,
			Num2 = T2#task.num,
			Num3 = T3#task.num,
			Num4 = T4#task.num,
			GetAward1 = T1#task.get_award,
			GetAward2 = T2#task.get_award,
			GetAward3 = T3#task.get_award,
			GetAward4 = T4#task.get_award,
			AwardIdList1 = T1#task.award_id_list,
			AwardIdList2 = T2#task.award_id_list,
			AwardIdList3 = T3#task.award_id_list,
			AwardIdList4 = T4#task.award_id_list,
			AwardString1 = list_deal_to_string(AwardIdList1),
			AwardString2 = list_deal_to_string(AwardIdList2),
			AwardString3 = list_deal_to_string(AwardIdList3),
			AwardString4 = list_deal_to_string(AwardIdList4),
			Exp1 = T1#task.exp,
			Exp2 = T2#task.exp,
			Exp3 = T3#task.exp,
			Exp4 = T4#task.exp,
			Lilian1 = T1#task.lilian,
			Lilian2 = T2#task.lilian,
			Lilian3 = T3#task.lilian,
			Lilian4 = T4#task.lilian,
			KillName1 = T1#task.kill_name,
			KillName2 = T2#task.kill_name,
			KillName3 = T3#task.kill_name,
			KillName4 = T4#task.kill_name,
			KillNum1 = T1#task.kill_num,
			KillNum2 = T2#task.kill_num,
			KillNum3 = T3#task.kill_num,
			KillNum4 = T4#task.kill_num,
			NowKill1 = T1#task.now_kill,
			NowKill2 = T2#task.now_kill,
			NowKill3 = T3#task.now_kill,
			NowKill4 = T4#task.now_kill,
			MonId1 = T1#task.mon_id,
			MonId2 = T2#task.mon_id,
			MonId3 = T3#task.mon_id,
			MonId4 = T4#task.mon_id,
			MonX1 = T1#task.mon_x,
			MonX2 = T2#task.mon_x,
			MonX3 = T3#task.mon_x,
			MonX4 = T4#task.mon_x,
			MonY1 = T1#task.mon_y,
			MonY2 = T2#task.mon_y,
			MonY3 = T3#task.mon_y,
			MonY4 = T4#task.mon_y,
			Reply = [{Tid1, TaskName1, NowNum1, Num1, KillName1, NowKill1, KillNum1, GetAward1, AwardString1, Exp1, Lilian1, MonId1, MonX1, MonY1}, {Tid2, TaskName2, NowNum2, Num2, KillName2, NowKill2, KillNum2, GetAward2, AwardString2, Exp2, Lilian2, MonId2, MonX2, MonY2}, {Tid3, TaskName3, NowNum3, Num3, KillName3, NowKill3, KillNum3, GetAward3, AwardString3, Exp3, Lilian3, MonId3, MonX3, MonY3}, {Tid4, TaskName4, NowNum4, Num4, KillName4, NowKill4, KillNum4, GetAward4, AwardString4, Exp4, Lilian4, MonId4, MonX4, MonY4}]
	end,
    TaskList = Reply,
    Bin = lib_wubianhai_new:pack3(TaskList),
    {ok, BinData} = pt_640:write(64006, Bin),
    lib_server_send:send_to_uid(Id, BinData),
	{noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% 把[1,1,1]转为"1,3"
list_deal_to_string([]) -> "";
list_deal_to_string(L1) ->
	[H | _T] = L1,
	integer_to_list(H) ++ "," ++ integer_to_list(length(L1)).

%% 获取所有房间ID
copy_id_list([], L2) -> L2;
copy_id_list([H | T], L2) ->
	case H of
		{{copy_id, Id}, Id} -> copy_id_list(T, [Id | L2]);
		_ -> copy_id_list(T, L2)
	end.

create_mon(SceneId, CopyId, Level, MonId1, MonLocal1, MonId2, MonLocal2, MonId3, MonLocal3, MonId32, MonLocal32, MonId4, MonLocal4, MonId42, MonLocal42, MonId5, MonLocal5, MonId6, MonLocal6, MonId7, MonLocal7) ->
    MonLocalList1 = util:list_shuffle(MonLocal1),
    FunCreateMon1 = 
	    fun(_I, [{X,Y}|Tail]) ->
            mod_mon_create:create_mon_cast(MonId1, SceneId, X, Y, 1, CopyId, 0, [{auto_lv, Level}]),
            {ok, Tail}
     	end,
    util:for(1, length(MonLocalList1), FunCreateMon1, MonLocalList1),

 	MonLocalList2 = util:list_shuffle(MonLocal2),
    FunCreateMon2 = 
	    fun(_I, [{X,Y}|Tail]) ->
			mod_mon_create:create_mon_cast(MonId2, SceneId, X, Y, 1, CopyId, 0, [{auto_lv, Level}]),
            {ok, Tail}
     	end,
    util:for(1, length(MonLocalList2), FunCreateMon2, MonLocalList2),
    
 	MonLocalList3 = util:list_shuffle(MonLocal3),
    FunCreateMon3 = 
	    fun(_I, [{X,Y}|Tail]) ->
			mod_mon_create:create_mon_cast(MonId3, SceneId, X, Y, 1, CopyId, 0, [{auto_lv, Level}]),
            {ok, Tail}
     	end,
    util:for(1, length(MonLocalList3), FunCreateMon3, MonLocalList3),

    MonLocalList32 = util:list_shuffle(MonLocal32),
    FunCreateMon32 = 
	    fun(_I, [{X,Y}|Tail]) ->
			mod_mon_create:create_mon_cast(MonId32, SceneId, X, Y, 1, CopyId, 0, [{auto_lv, Level}]),
            {ok, Tail}
     	end,
    util:for(1, length(MonLocalList32), FunCreateMon32, MonLocalList32),
    
 	MonLocalList4 = util:list_shuffle(MonLocal4),
    FunCreateMon4 = 
	    fun(_I, [{X,Y}|Tail]) ->
			mod_mon_create:create_mon_cast(MonId4, SceneId, X, Y, 1, CopyId, 0, [{auto_lv, Level}]),
            {ok, Tail}
     	end,
    util:for(1, length(MonLocalList4), FunCreateMon4, MonLocalList4),

    MonLocalList42 = util:list_shuffle(MonLocal42),
    FunCreateMon42 = 
	    fun(_I, [{X,Y}|Tail]) ->
			mod_mon_create:create_mon_cast(MonId42, SceneId, X, Y, 1, CopyId, 0, [{auto_lv, Level}]),
            {ok, Tail}
     	end,
    util:for(1, length(MonLocalList42), FunCreateMon42, MonLocalList42),
    
 	MonLocalList5 = util:list_shuffle(MonLocal5),
    FunCreateMon5 = 
	    fun(_I, [{X,Y}|Tail]) ->
			mod_mon_create:create_mon_cast(MonId5, SceneId, X, Y, 1, CopyId, 0, [{auto_lv, Level}]),
            {ok, Tail}
     	end,
    util:for(1, length(MonLocalList5), FunCreateMon5, MonLocalList5),
    
 	MonLocalList6 = util:list_shuffle(MonLocal6),
    FunCreateMon6 = 
	    fun(_I, [{X,Y}|Tail]) ->
			mod_mon_create:create_mon_cast(MonId6, SceneId, X, Y, 1, CopyId, 0, [{auto_lv, Level}]),
            {ok, Tail}
     	end,
	util:for(1, length(MonLocalList6), FunCreateMon6, MonLocalList6),

    MonLocalList7 = util:list_shuffle(MonLocal7),
    FunCreateMon7 = 
	    fun(_I, [{X,Y}|Tail]) ->
			mod_mon_create:create_mon_cast(MonId7, SceneId, X, Y, 1, CopyId, 0, [{auto_lv, Level}]),
            {ok, Tail}
     	end,
	util:for(1, length(MonLocalList7), FunCreateMon7, MonLocalList7).

get_all_room([], L) -> L;
get_all_room([H | T], L) ->
    case H of
        {{all_room, RoomLv, RoomId}, Num} -> 
            case Num >= data_wubianhai_new:get_wubianhai_config(room_max_num) of
                true -> get_all_room(T, [{RoomLv, RoomId, data_wubianhai_new:get_wubianhai_config(room_max_num), data_wubianhai_new:get_wubianhai_config(room_max_num)} | L]);
                false -> get_all_room(T, [{RoomLv, RoomId, Num, data_wubianhai_new:get_wubianhai_config(room_max_num)} | L])
            end;
        _ -> get_all_room(T, L)
    end.

log_deal([], _Num, _TaskNum1, _TaskNum2, _TaskNum3, _TaskNum4, _TaskNum5, _TaskNum6) -> 
    case _Num of
        0 ->
            skip;
        _ ->
            db:execute(io_lib:format(<<"insert into log_wubianhai set open_time = ~p, join_num = ~p, task_num1 = ~p, task_num2 = ~p, task_num3 = ~p, task_num4 = ~p, task_num5 = ~p, task_num6 = ~p">>, [util:unixdate(), _Num, _TaskNum1, _TaskNum2, _TaskNum3, _TaskNum4, _TaskNum5, _TaskNum6]))
    end;
log_deal([H | T], AllOnlineNum, TaskNum1, TaskNum2, TaskNum3, TaskNum4, TaskNum5, TaskNum6) ->
    case H of
        %% 所有参与玩家
        {{all_get_in, PlayerId}, no} -> 
            NewTaskNum1 = TaskNum1,
            NewTaskNum2 = TaskNum2,
            NewTaskNum3 = TaskNum3,
            NewTaskNum4 = TaskNum4,
            NewTaskNum5 = TaskNum5,
            NewTaskNum6 = TaskNum6,
            NewAllOnlineNum = AllOnlineNum + 1,
            %% 春节召回活动
            lib_off_line:add_off_line_count(PlayerId, 14, 1, 0);
        {{all_awards, TaskId}, Num} ->
            case TaskId of
                1 -> 
                    NewTaskNum1 = Num,
                    NewTaskNum2 = TaskNum2,
                    NewTaskNum3 = TaskNum3,
                    NewTaskNum4 = TaskNum4,
                    NewTaskNum5 = TaskNum5,
                    NewTaskNum6 = TaskNum6;
                2 -> 
                    NewTaskNum1 = TaskNum1,
                    NewTaskNum2 = Num,
                    NewTaskNum3 = TaskNum3,
                    NewTaskNum4 = TaskNum4,
                    NewTaskNum5 = TaskNum5,
                    NewTaskNum6 = TaskNum6;
                3 -> 
                    NewTaskNum1 = TaskNum1,
                    NewTaskNum2 = TaskNum2,
                    NewTaskNum3 = Num,
                    NewTaskNum4 = TaskNum4,
                    NewTaskNum5 = TaskNum5,
                    NewTaskNum6 = TaskNum6;
                4 -> 
                    NewTaskNum1 = TaskNum1,
                    NewTaskNum2 = TaskNum2,
                    NewTaskNum3 = TaskNum3,
                    NewTaskNum4 = Num,
                    NewTaskNum5 = TaskNum5,
                    NewTaskNum6 = TaskNum6;
                5 -> 
                    NewTaskNum1 = TaskNum1,
                    NewTaskNum2 = TaskNum2,
                    NewTaskNum3 = TaskNum3,
                    NewTaskNum4 = TaskNum4,
                    NewTaskNum5 = Num,
                    NewTaskNum6 = TaskNum6;
                _ -> 
                    NewTaskNum1 = TaskNum1,
                    NewTaskNum2 = TaskNum2,
                    NewTaskNum3 = TaskNum3,
                    NewTaskNum4 = TaskNum4,
                    NewTaskNum5 = TaskNum5,
                    NewTaskNum6 = Num
            end,
            NewAllOnlineNum = AllOnlineNum;
        _ ->
            NewTaskNum1 = TaskNum1,
            NewTaskNum2 = TaskNum2,
            NewTaskNum3 = TaskNum3,
            NewTaskNum4 = TaskNum4,
            NewTaskNum5 = TaskNum5,
            NewTaskNum6 = TaskNum6,
            NewAllOnlineNum = AllOnlineNum
    end,
    timer:sleep(100),
    log_deal(T, NewAllOnlineNum, NewTaskNum1, NewTaskNum2, NewTaskNum3, NewTaskNum4, NewTaskNum5, NewTaskNum6).
