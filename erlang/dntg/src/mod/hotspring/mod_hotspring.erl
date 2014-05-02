%%%--------------------------------------
%%% @Module  : mod_hotspring
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.31
%%% @Description: 黄金沙滩
%%%--------------------------------------

-module(mod_hotspring).
-behaviour(gen_server).
-include("common.hrl").
-include("hotspring.hrl").
-export([
	start_link/1,
	set_time/1,
	get_data/1,
	init_room/0,
	get_room/0,
	change_num/2,
	clean_room/1,
	pull_out_of/1,
	stop/0,
	offline/4,
	put_rank_top_10/1,
	get_rank_top_10/0,
	update_interact_playerlist/3
]).
-export([
	init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3
]).
-record(state, {
	timerange = [],				%% 默认活动时间
	roomlist = []					%% 房间列表，格式如：[{id, num}]
}).

%% 开启沙滩服务进程
start_link(TimeRange) ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [TimeRange], []).

%% 设置活动时间范围
set_time(TimeRange) ->
	gen_server:call(misc:get_global_pid(?MODULE), {set_time, TimeRange}).

%% 获得活动时间，及房间数据，恶搞数据，示好数据
get_data(RoleId) ->
	gen_server:call(misc:get_global_pid(?MODULE), {get_data, RoleId}).

%% 初始化房间数量，默认先开一个
init_room() ->
	gen_server:cast(misc:get_global_pid(?MODULE), {init_room}).

%% 获取房间列表
get_room() ->
	gen_server:call(misc:get_global_pid(?MODULE), {get_room}).

%% 房间加减人；有可能会触发生成新房间
change_num(RoomId, Num) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {change_num, RoomId, Num}).

%% 清除房间
%% 在活动结束时清除掉，虽然在活动开始时有初始化，不过可以更保险
clean_room(TimeType) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {clean_room, TimeType}).

%% 将人从场景中拉出
pull_out_of(SceneId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {pull_out_of, SceneId}).

%% 保存前10排行数据
put_rank_top_10(Data) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {put_rank_top_10, Data}).

%% 获取前10排行数据
get_rank_top_10() ->
	gen_server:call(misc:get_global_pid(?MODULE), {get_rank_top_10}).

%% 更新玩家交互数据
update_interact_playerlist(RoleId, List1, List2) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {update_interact_playerlist, RoleId, List1, List2}).

%% 玩家下线
offline(RoleId, CopyId, List1, List2) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {offline, RoleId, CopyId, List1, List2}).

stop() ->
	gen_server:call(misc:get_global_pid(?MODULE), {stop}).



%%----------------- 下面为回调函数 -----------------%%
init([TimeRange]) ->
	process_flag(trap_exit, true),
    {ok, #state{timerange = TimeRange}}.

handle_call({get_room}, _From, State) ->
	case lib_hotspring:is_validate_time(State#state.timerange) of
		true ->
			case State#state.roomlist =:= [] of
				%% 如果在活动时间内，且房间为空，则新建一个
				true ->
					NewState = State#state{roomlist = [{1, 0}]},
					{reply, NewState#state.roomlist, NewState};
				_ ->
					{reply, State#state.roomlist, State}
			end;
		_ ->
			{reply, [], State}
	end;

handle_call({get_data, RoleId}, _From, State) ->
	[List1, List2] = 
		case RoleId =:= 0 of
			true ->
				[[], []];
			_ ->
				case ets:lookup(ets_hotspring_interact, RoleId) of
					[Rd] when is_record(Rd, ets_hotspring_interact) ->
						[Rd#ets_hotspring_interact.list1, Rd#ets_hotspring_interact.list2];
					_ ->
						[[], []]
				end
		end,
     {reply, [State#state.timerange, State#state.roomlist, List1, List2], State};

handle_call({set_time, TimeRange}, _From, State) ->
   {reply, ok, State#state{timerange = TimeRange}};

handle_call({stop}, _From, State) ->
    {stop, normal, State};

%% 获取前10排行数据
handle_call({get_rank_top_10}, _From, State) ->
	Data = case get(ets_hotspring_top_10) of
		undefined -> [];
		List -> List
	end,
	 {reply, Data, State};

handle_call(_Request, _From, State) ->
	{reply, ok, State}.

handle_cast({init_room}, State) ->
    {noreply, State#state{roomlist = [{1, 0}]}};

handle_cast({clean_room, TimeType}, State) ->
	%% 清理场景
	SceneId = lib_hotspring:get_sceneid(State#state.timerange),
	[mod_scene_agent:apply_cast(SceneId, mod_scene, clear_scene, [SceneId, RoomId]) || {RoomId, _} <- State#state.roomlist],
	
	%% 清掉玩家互动的玩家列表
	case TimeType =:= pm of
		true -> ets:delete_all_objects(ets_hotspring_interact);
		_ -> skip
	end,
	{noreply, State#state{roomlist = []}};

%% 房间加减人, AddNum可为负数
handle_cast({change_num, RoomId, AddNum}, State) ->
	case State#state.roomlist =:= [] andalso AddNum < 0 of
		%% 如果房间为空，且要减人，则不需要处理
		true ->
			{noreply, State};
		_ ->
			NewList = lists:map(fun({Id, Num}) -> 
				case Id =:= RoomId of
					true ->
						{Id, private_check_num(Num + AddNum)};
					_ ->
						{Id, Num}
				end
			end, State#state.roomlist),

			NewList2 = private_check_room(NewList),
		    {noreply, State#state{roomlist = NewList2}}
	end;

%% 将人从场景中拉出
handle_cast({pull_out_of, SceneId}, State) ->
	F = fun(RoomId) ->
		%% 从聊天中取出玩家pid列表，再一批批cast到玩家进程退出
		UsersPids = lib_scene:get_scene_user_field(SceneId, RoomId, pid),
		spawn(fun() -> private_send_pid(UsersPids) end)
	end,
	%% 循环所有房间
	[F(Id) || {Id, _} <- State#state.roomlist],
	{noreply, State};

%% 保存前10排行数据
handle_cast({put_rank_top_10, Data}, State) ->
	put(ets_hotspring_top_10, Data),	
	{noreply, State};

%% 更新玩家交互数据
handle_cast({update_interact_playerlist, RoleId, List1, List2}, State) ->
	ets:insert(ets_hotspring_interact, #ets_hotspring_interact{id = RoleId, list1 = List1, list2 = List2}),
	{noreply, State};

%% 玩家下线
handle_cast({offline, RoleId, RoomId, List1, List2}, State) ->
	AddNum = -1,
	NewState = case State#state.roomlist =:= [] andalso AddNum < 0 of
		%% 如果房间为空，且要减人，则不需要处理
		true ->
			State;
		_ ->
			NewList = lists:map(fun({Id, Num}) -> 
				case Id =:= RoomId of
					true ->
						{Id, private_check_num(Num + AddNum)};
					_ ->
						{Id, Num}
				end
			end, State#state.roomlist),

			NewList2 = private_check_room(NewList),
			State#state{roomlist = NewList2}
	end,
	ets:insert(ets_hotspring_interact, #ets_hotspring_interact{id = RoleId, list1 = List1, list2 = List2}),
	{noreply, NewState};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
     {noreply, State}.

terminate(_Reason, _Status) ->
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

%% 对房间人数作上下限处理
private_check_num(Num) ->
	RoomLimit = data_hotspring:get_room_limit(),
	LastNum = 
	if
		Num < 0 -> 0;
		Num > RoomLimit -> RoomLimit;
		true -> Num
	end,
	LastNum.

%% 检查是否达到开新房间的限制
private_check_room(RoomList) ->
	RoomLimit = data_hotspring:get_room_limitup(),
	NumLimit = data_hotspring:get_create_room_limit(),

	%% 判断开房数量是否已经达到上限
	case length(RoomList) >= RoomLimit of
		true ->
			RoomList;
		_ ->
			Bool = lists:all(fun({_Id, Num}) ->
				case Num >= NumLimit of
					true -> true;
					_ -> false
				end
			end, RoomList),
			case Bool of
				true ->
					Len = length(RoomList) + 1,
					RoomList ++ [{Len, 0}];
				_ ->
					RoomList
			end
	end.

private_send_pid(UserPids) ->
	lists:foldl(fun(Pid, Num) -> 
		case Num rem 20 of
			0 ->
				timer:sleep(100);
			_ ->
				skip
		end,
		case is_pid(Pid) of
			true ->
				gen_server:cast(Pid, {leave_scene, hotspring, []});
			_ ->
				skip
		end,
		Num + 1
	end, 0, UserPids).
