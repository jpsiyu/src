%% --------------------------------------------------------
%% @Module:           |timer_husong
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-07
%% @Description:      |财神降临定时器 每天晚上八点执行 八点半终止 12点重置 每周重置
%% --------------------------------------------------------
-module(timer_husong).

%% External exports
-export([waiting/2, wait_start/2, wait_refresh/2]).

%% gen_fsm callbacks
-export([start_link/0, init/1,  handle_event/3, handle_sync_event/4, handle_info/3, terminate/3]).

%% 自定义状态
-record(state, {start_at  = 0							%% 启动时间
			   , week_start = 0							%% 每周的周头
			   , week_end = 0							%% 每周的周末
			   }).					


-define(TIME_LAST,    30 * 60 * 1000).					%% 持续时间(单位1/1000秒)
-define(TIME_DAILY,   20 * 60 * 60 * 1000).				%% 财神降临开始时间(单位1/1000秒)
-define(TIME_DAY_ALL, 24 * 60 * 60 * 1000).				%% 一整天的时间(单位1/1000秒)

%% 启动服务器
start_link() ->
    % 启动进程{服务名称，回调模块名称，初始参数，列表选项}。 
    % 使用初始参数回调init()方法。
    gen_fsm:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    NowTime = util:unixtime(),
	NowZero = util:unixdate(),
	{WeekStart, WeekEnd} = util:get_week_time(),
    Status = #state{start_at = NowTime
			   , week_start = WeekStart
			   , week_end = WeekEnd},
	case (NowTime - NowZero) * 1000 > ?TIME_DAILY of
		true -> 	%% 已经超过8:00 今天不开始
			TimeLeft = ?TIME_DAY_ALL - (NowTime - NowZero) * 1000,
%% 			io:format("TimeLeft 1 : ~p~n", [TimeLeft]),
			{ok, wait_refresh, Status, TimeLeft};
		false ->	%% 未到8:00 今天可以开始财神降临
			TimeLeft = ?TIME_DAILY - (NowTime - NowZero) * 1000,
%% 			io:format("TimeLeft 2 : ~p~n", [TimeLeft]),
			{ok, wait_start, Status, TimeLeft}
	end.


%% --------------------------------------------------------------------
%% 财神降临										 		 	 ------8:00
%% --------------------------------------------------------------------
wait_start(timeout, Status) ->
%% 	io:format("2123"),
	%% 广播开始财神降临
	F = fun() -> lib_husong:guoyun_notify() end,
    catch spawn(F),
    {next_state, waiting, Status, ?TIME_LAST}.

%% --------------------------------------------------------------------
%% 财神降临结束										 		 ------8:30
%% --------------------------------------------------------------------
waiting(timeout, Status) ->
	NowTime = util:unixtime(),
	NowZero = util:unixdate(),
	TimeLeft = ?TIME_DAY_ALL - (NowTime - NowZero) * 1000,
	{next_state, wait_refresh, Status, TimeLeft}.

%% --------------------------------------------------------------------
%% 等待今天结束(处理每日需要刷新的数据和每周需要刷新的数据)   ----------12:00
%% --------------------------------------------------------------------
wait_refresh(timeout, Status) ->
    {next_state, wait_start, Status, ?TIME_DAILY}.

%% --------------------------------------------------------------------
%% 异步事件
%% --------------------------------------------------------------------
handle_event(_Event, StateName, Status) ->
    {next_state, StateName, Status}.

%% --------------------------------------------------------------------
%% 同步事件
%% --------------------------------------------------------------------
%% 记录个人周积分
handle_sync_event({save_scores, [_PlayerId, _Scores]}, _From, StateName, Status) ->
    Reply = ok,
    {reply, Reply, StateName, Status};
%% 读取个人周积分
handle_sync_event({get_scores, [_PlayerId]}, _From, StateName, Status) ->
    Reply = ok,
    {reply, Reply, StateName, Status};
%% 开启财神降临
handle_sync_event({gocsjl}, _From, _StateName, Status) ->
%% 	io:format("2123"),
    Reply = ok,
    {reply, Reply, wait_start, Status, 0};
handle_sync_event(_Event, _From, StateName, Status) ->
    Reply = ok,
    {reply, Reply, StateName, Status}.

%% --------------------------------------------------------------------
%% 直接进程间消息:不使用
%% --------------------------------------------------------------------
handle_info(_Info, StateName, Status) ->
%% 	io:format("21232222"),
    {next_state, StateName, Status}.

%% --------------------------------------------------------------------
%% 进程终止
%% --------------------------------------------------------------------
terminate(_Reason, _StateName, _Status) ->
    ok.
