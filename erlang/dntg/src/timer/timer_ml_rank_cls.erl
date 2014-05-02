%%%--------------------------------------
%%% @Module  : timer_ml_rank_cls
%%% @Author  : 
%%% @Email   : 
%%% @Created : 
%%% @Description: 跨服鲜花榜定时服务
%%%--------------------------------------

-module(timer_ml_rank_cls).
-behaviour(gen_fsm).
-include("rank_cls.hrl").
-export([
	start_link/0,
	new_circle/2,
	prize_end/2,
	working/2,
	re_start/0,
	re_working/0,
	send_prize/0
]).
-export([
	init/1,
	handle_event/3,
	handle_sync_event/4,
	handle_info/3, 
	terminate/3,
	code_change/4
]).
-define(DELAY0, 60).															%% 通用延迟基数延迟
-define(DELAY2, 2 * 60).														%% 同步数据延迟
-define(DELAY, 15 * 60).														%% 延迟发奖时间(秒)
-define(ADAY, 24 * 60 * 60).													%% 一天的时间(秒)
-define(ASK_TIME, 60 * 60).														%% 每次请求间隔(秒)



%% -define(DELAY0, 1).															%% 通用延迟基数延迟
%% -define(DELAY2, 15).														%% 同步数据延迟
%% -define(DELAY, 15).														%% 延迟发奖时间(秒)
%% -define(ADAY, 3 * 60).													%% 一天的时间(秒)
%% -define(ASK_TIME, 30).														%% 每次请求间隔(秒)

-record(status, {ask_times = 0		 	 										%% 今日请求次数
				, send_times = 0		 	 									%% 今日主动发送次数
				, daily_gift_time = 0	 	 									%% 日榜发奖时间
				, count_gift_time = 0	 	 									%% 累计榜发奖时间
			   }).

start_link() ->
    gen_fsm:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 启动进入休眠时间
init([]) ->
	{ok, new_circle, [], 1000}.

%% 每天的0点15分启动此方法下一轮循环(每次发完奖励后调用)
new_circle(_Event, _State) ->
	%% 获取配置的日榜活动时间和累计榜活动时间
	[{_, DailyStartAt, DailyEndAt}, {_, CountStartAt, CountEndAt}] = data_kf_flower_rank:get_base_info(),
	%% 获取当前和当日时间
	NowTime = util:unixtime(),
	NowZero = util:unixdate(),
	%% 计算新的一天的初始化数据
	DGT = case NowTime > DailyStartAt andalso NowTime < DailyEndAt of
		true ->
			NowZero + ?ADAY;
		false ->
			0
	end,
	%% 计算累计榜时间是否要清零
	CGT = case NowTime > CountStartAt andalso NowTime < CountEndAt of
		true ->
			CountEndAt;
		false ->
			0
	end,
	SleepTime = case NowTime >= NowZero andalso NowTime < NowZero + ?ASK_TIME of
					true ->
						?ASK_TIME - (NowTime - NowZero);
					false ->
						0
				end,
	NewState = #status{
							ask_times = 0		 	 										%% 今日请求次数
							, send_times = 0
							, daily_gift_time = DGT	 	 									%% 日榜发奖时间
							, count_gift_time = CGT	 	 									%% 累计榜发奖时间
							},
	%% 如果不再活动时间内则进入休眠循环(每小时醒来一次,检测是否有新的活动时间配置)
	case DGT =:= 0 andalso CGT =:= 0 of
		true ->  %% 不在活动时间,进入休眠进程
			{next_state, new_circle, NewState, ?ASK_TIME * 1000};
		false -> %% 在活动时间,请求一次数据更新
			spawn(fun() ->
						  %% 服务启动后延迟请求所有数据并发送数据给所有服务器更新
						  timer:sleep(1 * ?DELAY0 * 1000),
						  get_servers_info(),
						  timer:sleep(3 * ?DELAY0 * 1000),
						  send_servers_info()
				  end),
			{next_state, working, NewState, SleepTime * 1000}
	end.
	

%% 主要业务流程
working(_Event, State) ->
	NowTime = util:unixtime(),
	NowZero = util:unixdate(),
	TimeAsk = State#status.ask_times * ?ASK_TIME + NowZero - ?DELAY2,
	%% 每日请求次数上限, 根据日长度(发奖周期长度)和请求间隔得出
	TimeLimit = ?ADAY div ?ASK_TIME,
	%% 判断是否请求数据
	AskTimesNext = case NowTime >= TimeAsk andalso State#status.ask_times < TimeLimit of
		true -> %% 向单服节点请求数据
			get_servers_info(),
			spawn(fun() ->
						  timer:sleep(?DELAY2 * 1000),
						  send_servers_info()
				  end),
			State#status.ask_times + 1;
		false -> %% 时间未到
			State#status.ask_times
	end,
	NewState = State#status{
							ask_times = AskTimesNext		 	
							},
	%% 判断是否进入发奖流程 本次睡眠时间 
	{NextSt, SleepTime} = case NowTime > State#status.daily_gift_time  of
					true ->
						send_servers_info(),
						{prize_end, ?DELAY};
					false ->
						%% 10分钟醒来一次
						{working, 10 * 60}
				end,
%% 	io:format("000000 ~p ~p", [SleepTime, AskTimesNext]),
	{next_state, NextSt, NewState, SleepTime * 1000}.

%% 发奖判断流程
prize_end(_Event, State) ->
	NowTime = util:unixtime(),
	%% 日榜奖励发放判断
	case NowTime >= State#status.daily_gift_time andalso State#status.daily_gift_time =/= 0 of
		true ->
			send_daily_prize();
		false ->
			skip
	end,
	%% 累计榜奖励发放判断
	case NowTime >= State#status.count_gift_time andalso State#status.count_gift_time =/= 0 of
		true ->
			send_count_prize();
		false ->
			case State#status.count_gift_time =:= 0 of
				true ->
					clear_count();
				false ->
					skip
			end
	end,
	%% 判断是否要清除累计榜当日数据

	%% 发送奖励完毕后延迟重新向所有服务器请求数据
	spawn(fun() ->
				  %% 服务启动后延迟请求所有数据并发送数据给所有服务器更新
				  timer:sleep(5 * ?DELAY0 * 1000),
				  get_servers_info(),
				  timer:sleep(3 * ?DELAY0 * 1000),
				  send_servers_info()
		  end),
	{next_state, new_circle, State, 0}.

%% 重新触发定时器工作
re_working() ->
	gen_fsm:send_all_state_event(?MODULE, {re_working}).

%% 重新触发定时器开始
re_start() ->
	gen_fsm:send_all_state_event(?MODULE, {re_start}).

%% 重新触发定时器开始
send_prize() ->
	gen_fsm:send_all_state_event(?MODULE, {send_prize}).

%% --------------------------------------------------------------------
%% 异步事件
%% --------------------------------------------------------------------
handle_event({re_working}, _StateName, State) ->
    {next_state, working, State, 2000};

handle_event({re_start}, _StateName, State) ->
    {next_state, new_circle, State, 2000};

handle_event({send_prize}, _StateName, State) ->
    {next_state, prize_end, State, 2000};

handle_event(_Event, StateName, State) ->
    {next_state, StateName, State}.

%% --------------------------------------------------------------------
%% 同步事件
%% --------------------------------------------------------------------
handle_sync_event(_Event, _From, StateName, State) ->
    {reply, ok, StateName, State}.

handle_info(_Info, StateName, State) ->
    {next_state, StateName, State}.

terminate(_Reason, _StateName, _State) ->
    ok.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.

%% --------------------------------------------------------------------
%% 私有函数
%% --------------------------------------------------------------------
%% 发送日奖励
send_daily_prize() ->
%% 	io:format("0 1~n"),
	%% 清空榜单
	lib_activity_festival:kf_flower_zx_gift(daily).

%% 发送累计奖励
send_count_prize() ->
%% 	io:format("1 2~n"),
	%% 清空榜单
	lib_activity_festival:kf_flower_zx_gift(count).

%% 请求每个服务器的鲜花榜信息
get_servers_info()->
	%% 0点到1点之间不请求新的数据
	NowTime = util:unixtime(),
	NowZero = util:unixdate(),
	case NowTime > NowZero andalso NowTime < NowZero + ?ASK_TIME of
		true ->
			skip;
		_ ->
			lib_activity_festival:kf_flower_zx_ask()
	end.

%% 同步数据到所有节点
send_servers_info()->
%% 	io:format("33 ~n"),
	lib_activity_festival:kf_flower_zx_send_all().

%% 非活动时间,每日清空累计榜
clear_count() ->
%% 	io:format("44 ~n"),
	ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {?RK_KF_FLOWER_COUNT_MAN, _ = '_'}, _ = '_'}),
	ets:match_delete(?RK_KF_FLOWER_RANK, #kf_ets_flower_rank{m_key = {?RK_KF_FLOWER_COUNT_WOMEN, _ = '_'}, _ = '_'}),
	lib_activity_festival:kf_flower_local_clear().
