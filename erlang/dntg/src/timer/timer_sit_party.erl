%%%-------------------------------------------------------------------
%%% @Module	: timer_sit_party
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 13 Mar 2013
%%% @Description: 
%%%-------------------------------------------------------------------
-module(timer_sit_party).
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
    case data_sit:is_party_time() of
	false -> NewState = 0;
	true ->
	    [BeginTS, EndTS] = data_sit:get_open_unixtime(),
	    case util:unixtime() of
		%% 未到活动时间
		NowTS when NowTS < BeginTS ->
		    NewState = 0;
		%% 活动时间内活动未开启
		NowTS when (NowTS >= BeginTS andalso NowTS < EndTS andalso State =:= 0) ->
		    lib_sit:party_send_all(1),
		    NewState = 1;
		%% 活动时间内活动已开启
		NowTS when (NowTS > BeginTS andalso NowTS < EndTS andalso State =:= 1) ->
		    NewState = 1;
		%% 活动结束且活动正在开启
		NowTS when (NowTS >= EndTS andalso State =:= 1) ->
		    lib_sit:party_send_all(0),
		    NewState = 0;
		%% 活动结束活动未开启
		NowTS when (NowTS > EndTS andalso State =:= 0) ->
		    NewState = 0;
		_ ->
		    NewState = 0
	    end
    end,
    {ok, NewState}.

%% mod_timer终止回调
terminate(Reason, State) ->
    ?DEBUG("================Terminated..., Reason=[~w], Statee = [~w]", [Reason, State]),
    ok.

