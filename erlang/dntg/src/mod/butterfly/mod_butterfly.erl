%%%--------------------------------------
%%% @Module  : mod_butterfly
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.18
%%% @Description: 蝴蝶谷
%%%--------------------------------------

-module(mod_butterfly).
-behaviour(gen_server).
-include("common.hrl").
-export([start_link/1, get_data/0, set_time/1, init_room/0, get_room/0, change_num/2, clean_room/0, stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {
	weekrange = [1,2,3,4,5,6,7],		%% 活动周期，例如[1,2,3,4,5,6,7]，表示周一至周日都有活动
	timerange = [{13, 0}, {14, 0}],		%% 活动开始结束时间，例如[{13, 0}, {14, 0}]，表示13点开始，至14点结束
	roomlist = []								%% 房间列表，格式如：[{id, num}]
}).

%% 开启蝴蝶谷服务进程
start_link([WeekRange, TimeRange]) ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [WeekRange, TimeRange], []).

%% 设置活动开始周期，开始及结束时间
set_time([WeekRange, TimeRange]) ->
	gen_server:call(misc:get_global_pid(?MODULE), {set_time, [WeekRange, TimeRange]}).

%% 获得活动时间，及房间数据
get_data() ->
	gen_server:call(misc:get_global_pid(?MODULE), {get_data}).

%% 初始化房间数量，默认先开一个，并为该房间配置怪物
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
clean_room() ->
	gen_server:cast(misc:get_global_pid(?MODULE), {clean_room}).

%% 停止服务
stop() ->
	gen_server:call(misc:get_global_pid(?MODULE), {stop}).


%%----------------- 下面为回调函数 -----------------%%
init([WeekRange, TimeRange]) ->
	process_flag(trap_exit, true),
    {ok, #state{weekrange = WeekRange, timerange = TimeRange}}.

handle_call({get_data}, _From, State) ->
     {reply, [State#state.weekrange, State#state.timerange, State#state.roomlist], State};

handle_call({set_time, [WeekRange, TimeRange]}, _From, State) ->
   {reply, ok, State#state{weekrange = WeekRange, timerange = TimeRange}};

handle_call({get_room}, _From, State) ->
	case lib_butterfly:check_time_from_timer(State#state.weekrange, State#state.timerange) of
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
			{reply, State#state.roomlist, State}
	end;

handle_call({stop}, _From, State) ->
    {stop, normal, State};

handle_call(_Request, _From, State) ->
	{reply, ok, State}.

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

handle_cast({init_room}, State) ->
	DefaultRoomId = 1,
	lib_butterfly:init_room_boss(DefaultRoomId),
    {noreply, State#state{roomlist = [{DefaultRoomId, 0}]}};

handle_cast({clean_room}, State) ->
	%% 清怪
	lists:map(fun({Id, _Num}) -> 
		lib_butterfly:remove_all_mon(Id)
	end, State#state.roomlist),

    {noreply, State#state{roomlist = []}};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
     {noreply, State}.

terminate(_Reason, _Status) ->
	io:format("mod_butterfly terminate!~n"),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

%% 对房间人数作上下限处理
private_check_num(Num) ->
	RoomLimit = data_butterfly:get_room_limit(),
	LastNum = 
		if
			Num < 0 -> 0;
			Num > RoomLimit -> RoomLimit;
			true -> Num
		end,
	LastNum.

%% 检查是否达到开新房间的限制
private_check_room(RoomList) ->
	RoomLimit = data_butterfly:get_room_limitup(),
	NumLimit = data_butterfly:get_create_room_limit(),
	
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
					%% 开新房间，同时也初始化怪物
					lib_butterfly:init_room_boss(Len),
					RoomList ++ [{Len, 0}];
				_ ->
					RoomList
			end
	end.
