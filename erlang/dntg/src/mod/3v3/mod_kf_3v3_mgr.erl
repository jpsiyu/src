%%%--------------------------------------
%%% @Module : mod_kf_3v3_mgr
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3控制进程，控制活动开始，结束
%%%--------------------------------------

-module(mod_kf_3v3_mgr).
-behaviour(gen_fsm).
-include("kf_3v3.hrl").
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).
-compile(export_all).

-define(MOD_AT, 0).			%% 自动开启
-define(MOD_MT, 1).			%% 手动开启
-define(TIMEOUT_DEFAULT, 10).
-record(state, {
	mod = ?MOD_AT,			%% 模式，0自动，1手动
	open_time = [],			%% 开启时间列表，如[[14, 0], [21, 0]]
	pk_time = 0,			%% 每场战斗耗时（秒）
	start_time = 0,			%% 开始时间戳
	end_time = 0,			%% 结束时间戳
	loop = 0				%% 当前活动是当天的第几场，一般有2场
}).

%% 自动启动服务器
at_start_link() ->
    gen_fsm:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 手动启动服务器
%% @param Hour			开始小时
%% @param Minute		开始分钟
%% @param Second		开始秒
%% @param ActivityTime	活动时间(秒)
%% @param PkTime 		每场战斗时间(秒)
mt_start_link(Hour, Minute, Second, ActivityTime, PkTime) ->
	gen_fsm:send_all_state_event(?MODULE, {mt_start_link, Hour, Minute, Second, ActivityTime, PkTime}).

%% 关闭服务器时回调
stop() ->
    gen_fsm:send_event(?MODULE,stop).

%% 活动未开启状态
no_open(_Event, State) ->
	{{_Year, _Month, Day}, {Hour, Minute, Second}} = calendar:local_time(),
	NowTime = (Hour * 60 + Minute) * 60 + Second,

	case lists:member(Day, data_kf_3v3:get_config(open_day)) of
		%% 今天没有活动
		false ->
			%% 设置未开启状态
			mod_kf_3v3:set_status(?KF_3V3_STATUS_NO_START),
			mod_clusters_center:apply_to_all_node(mod_kf_3v3_state, set_status, [?KF_3V3_STATUS_NO_START]),
			%% 休眠到当天24点再次检测
			{next_state, no_open, State, (86400 - NowTime) * 1000};

		_ ->
			%% 开始及结束时间，是相对于0点的当天时间，并非时间戳
			case private_get_next_time(NowTime, State#state.open_time) of
				%% 当天没有可开启的时间点了
				[0, 0, _] ->
					mod_kf_3v3:set_status(?KF_3V3_STATUS_STOP),
					mod_clusters_center:apply_to_all_node(mod_kf_3v3_state, set_status, [?KF_3V3_STATUS_STOP]),
					{next_state, no_open, State, (86400 - NowTime) * 1000};

				%% 当天有活动，正在举行或者未到时间
				[StartTime, EndTime, Loop] ->
					NewState = State#state{
						start_time = StartTime,
						end_time = EndTime,
						loop = Loop
					},

					%% 隔多久活动开始
					Gap = case NowTime =< StartTime of
						true -> StartTime - NowTime;
						_ -> 0
					end,

					%% 先设置活动为未开启状态
					mod_kf_3v3:set_status(?KF_3V3_STATUS_NO_START),
					mod_clusters_center:apply_to_all_node(mod_kf_3v3_state, set_status, [?KF_3V3_STATUS_NO_START]),

					%% 休眠Gap秒后，自动开启
					{next_state, opening, NewState, Gap * 1000}
			end
	end.

%% 活动开启状态
opening(_Event, State) ->
	NowTime = lib_kf_3v3:get_second_of_day(),
	StartTime = State#state.start_time,
	EndTime = State#state.end_time,
	case StartTime > NowTime of
		%% 没有到活动时间
		true ->
			{next_state, opening, State, (StartTime - NowTime) * 1000};
		_ ->
			%% 正式开启活动
			mod_kf_3v3:open_3v3(State#state.loop, StartTime, EndTime, State#state.pk_time),
			mod_clusters_center:apply_to_all_node(mod_kf_3v3_state, set_status, [?KF_3V3_STATUS_ACTION]),

			%% 休眠到结束时间后，结束活动
			LastTime = EndTime - NowTime,
			{next_state, finished, State, LastTime * 1000}
	end.

%% 活动结束状态
finished(_Event, _State) ->
	%% 发送活动结束状态到游戏节点
	mod_clusters_center:apply_to_all_node(mod_kf_3v3_state, set_status, [?KF_3V3_STATUS_STOP]),

	%% 通知本跨服节点活动结束通知
%% 	mod_kf_3v3:end_3v3(),
	mod_kf_3v3:stop_3v3(),

	NewState = private_init_stat(),
	{next_state, no_open, NewState, ?TIMEOUT_DEFAULT}.

%% 竞技场未开启状态(提供给秘籍使用)
%% 设置活动开始时间时，必须最少比当前时间晚一分钟
no_open_without_check_date(_Event, State) ->
	NowTime = lib_kf_3v3:get_second_of_day(),
	Gap = State#state.start_time - NowTime,
	if
		Gap >= 0 ->
			%% 设置未开启状态
			mod_kf_3v3:set_status(?KF_3V3_STATUS_NO_START),
			mod_clusters_center:apply_to_all_node(mod_kf_3v3_state, set_status, [?KF_3V3_STATUS_NO_START]),
			{next_state, opening, State, Gap * 1000};

		true ->
			%% 设置未开启状态
			mod_kf_3v3:set_status(?KF_3V3_STATUS_STOP),
			mod_clusters_center:apply_to_all_node(mod_kf_3v3_state, set_status, [?KF_3V3_STATUS_STOP]),
			{next_state, finished, State, ?TIMEOUT_DEFAULT}
	end.

init([]) ->
	State = private_init_stat(),
	{ok, no_open, State, ?TIMEOUT_DEFAULT}.

handle_event({mt_start_link, Hour, Minute, Second, ActivityTime, PkTime}, _StateName, _State) ->
	StartTime = (Hour * 60 + Minute) * 60 + Second,
	EndTime = StartTime + ActivityTime,
	NewState = #state{
		mod = ?MOD_MT,
		pk_time = PkTime,
		start_time = StartTime,
		end_time = EndTime
	},

	%% 根据竞技场状态，进行处理
	NowTime = lib_kf_3v3:get_second_of_day(),
	if
		%% 未开始
		NowTime =< NewState#state.start_time ->
			{next_state, no_open_without_check_date, NewState, ?TIMEOUT_DEFAULT};

		%% 已结束
		true ->
			{next_state, finished, NewState, ?TIMEOUT_DEFAULT}
	end;

handle_event(stop, _StateName, State) ->
    {stop, normal, State};

handle_event(_Event, StateName, StateData) ->
    {next_state, StateName, StateData}.

handle_sync_event(_Event, _From, StateName, StateData) ->
    Reply = ok,
    {reply, Reply, StateName, StateData}.

handle_info(_Info, StateName, StateData) ->
    {next_state, StateName, StateData}.

terminate(_Reason, _StateName, _StatData) ->
    ok.

code_change(_OldVsn, StateName, StateData, _Extra) ->
    {ok, StateName, StateData}.

%% 初始化状态数据
private_init_stat() ->
	#state{
		open_time = data_kf_3v3:get_config(open_time),
		pk_time = data_kf_3v3:get_config(pk_time)
	}.

%% @param NowTime	当天时间秒数
%% @param TimeList	配置时间，[[时, 分], ...]
%% @return [StartTime, EndTime]	如果StartTime和EndTime的值都为0，表示今天已经没有活动
private_get_next_time(NowTime, TimeList) ->
	NewTimeList = 
	lists:map(fun([Hour, Minute]) -> 
		Start = (Hour * 60 + Minute) * 60,
		End = Start + data_kf_3v3:get_config(activity_time),
		[Start, End]
	end, TimeList),
	private_get_next_time_sub(NewTimeList, [0, 0, 1], NowTime).

private_get_next_time_sub([], [TargetStart, TargetEnd, TargetLoop], _NowTime) ->
	[TargetStart, TargetEnd, TargetLoop];
private_get_next_time_sub([[Start, End] | Tail], [TargetStart, TargetEnd, TargetLoop], NowTime) ->
	case NowTime =< Start of
		%% 如果当前时间小于开始时间，则该开始与结束时间就是目标数据
		true ->
			private_get_next_time_sub([], [Start, End, TargetLoop], NowTime);
		_ ->
			case NowTime > Start andalso NowTime < End of
				true ->
					private_get_next_time_sub([], [Start, End, TargetLoop + 1], NowTime);
				_ ->
					private_get_next_time_sub(Tail, [TargetStart, TargetEnd, TargetLoop + 1], NowTime)
			end
	end.
