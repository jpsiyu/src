%%%-------------------------------------------------------------------
%%% @Module	: timer_turntable
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	:  7 Jun 2012
%%% @Description: 寻找唐僧广播开始和结束
%%%-------------------------------------------------------------------
-module(timer_turntable).
-include("common.hrl").
-include("record.hrl").
-export(
    [
        init/0,         %% 初始化回调
        handle/1,       %% 处理状态变更回调
        terminate/2     %% 中止回调
    ]).

%% 用于mod_timer初始化状态时回调
%% @return {ok, State} | {ignore, Reason} | {stop, Reason}
init() ->
    %% ok,
    {ok, 0}.

%% mod_timer中gen_fsm状态机状态变更时调用，用以执行所需操作
%% @param   State           : 原状态
%% @return  {ok, NewState}  : 新状态
%%          {ignore, Reason}: 异常
%%          {stop, Reason}  : 异常
handle(State) ->
    case lists:member(util:get_day_of_week(), data_turntable:get_start_day()) of
	true ->
	    {BeginTS, EndTS} = data_turntable:get_activity_unixtime(),
	    case util:unixtime() of
		%% 未到活动时间
		NowTS when NowTS < BeginTS ->
		    NewState = 0;
		%% 活动时间内活动未开启
		NowTS when (NowTS >= BeginTS andalso NowTS < EndTS andalso State =:= 0) ->
		    mod_turntable:start_link(),
		    mod_turntable:broadcast_begin(),
		    lib_chat:send_TV({all},1,2, ["findTS",1]),
		    NewState = 1;
		%% 活动时间内活动已开启
		NowTS when (NowTS > BeginTS andalso NowTS < EndTS andalso State =:= 1) ->
		    mod_turntable:broadcast_begin(),
		    mod_turntable:ontime_write_db(),
		    NewState = 1;
		%% 活动结束且活动正在开启
		NowTS when (NowTS >= EndTS andalso State =:= 1) ->
		    mod_turntable:broadcast_end(),
		    NewState = 0;
		%% 活动结束活动未开启
		NowTS when (NowTS > EndTS andalso State =:= 0) ->
		    NewState = 0;
		_ ->
		    NewState = 0
	    end;
	false ->
	    NewState = 0
    end,
    {ok, NewState}.

%% mod_timer终止回调
terminate(Reason, State) ->
    ?DEBUG("================Terminated..., Reason=[~w], Statee = [~w]", [Reason, State]),
    ok.
