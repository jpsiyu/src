%%%------------------------------------
%%% @Module  : timer_fcm
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.28
%%% @Description: 定时发送防沉迷通知(1分钟)
%%%------------------------------------
-module(timer_fcm).
-export([init/0, handle/1, terminate/2]).
-include("common.hrl").
-define(DEFINE_FCM_ZERO_EXP_TIME,          3*60*60). % 收益置0时间

%%=========================================================================
%% 一些定义
%% TODO: 定义模块状态。
%%=========================================================================

%%=========================================================================
%% 回调接口
%% TODO: 实现回调接口。
%%=========================================================================

%% -----------------------------------------------------------------
%% @desc     启动回调函数，用来初始化资源。
%% @param
%% @return  {ok, State}     : 启动正常
%%           {ignore, Reason}: 启动异常，本模块将被忽略不执行
%%           {stop, Reason}  : 启动异常，需要停止所有后台定时模块
%% -----------------------------------------------------------------
init() ->
    {ok, ?MODULE}.

%% -----------------------------------------------------------------
%% @desc     服务回调函数，用来执行业务操作。
%% @param    State          : 初始化或者上一次服务返回的状态
%% @return  {ok, NewState}  : 服务正常，返回新状态
%%           {ignore, Reason}: 服务异常，本模块以后将被忽略不执行，模块的terminate函数将被回调
%%           {stop, Reason}  : 服务异常，需要停止所有后台定时模块，所有模块的terminate函数将被回调
%% -----------------------------------------------------------------
handle(State) ->
    refresh_fcm(),
    {ok, State}.

%% -----------------------------------------------------------------
%% @desc     停止回调函数，用来销毁资源。
%% @param    Reason        : 停止原因
%% @param    State         : 初始化或者上一次服务返回的状态
%% @return   ok
%% -----------------------------------------------------------------
terminate(Reason, State) ->
    ?DEBUG("================Terming..., Reason=[~w], Statee = [~w]", [Reason, State]),
    ok.

%%=========================================================================
%% 业务处理
%% TODO: 实现业务处理。
%%=========================================================================

%% -----------------------------------------------------------------
%% 每1分钟检查一次
%% -----------------------------------------------------------------
refresh_fcm() ->
	Now = util:unixtime(),
	refresh(mod_fcm:get_all(), Now).

refresh([], _NowTime) -> skip;
refresh([Info | _T], NowTime) ->
	{{fcm, Id}, {_LastLoginTime, _OnlineTime, _OffLineTime, _State}} = Info,
	%io:format("NowTime:~p, _LastLoginTime:~p, _OnlineTime:~p~n", [NowTime, _LastLoginTime, _OnlineTime]),
	OnlineTime = NowTime - _LastLoginTime + _OnlineTime,
	%% 可能会出现负数情况，当服务器时间比最近登录时间小时
	case OnlineTime > 0 of
		true -> OnlineTime1 = OnlineTime;
		false -> OnlineTime1 = 0
	end,
	case _OffLineTime > 0 of
		true -> _OffLineTime1 = _OffLineTime;
		false -> _OffLineTime1 = 0
	end,
	case lib_fcm:calc_fcm_state(OnlineTime1) of
		%% 1小时
		0 ->
			mod_fcm:insert(Id, NowTime, OnlineTime1, _OffLineTime1, _State),
			FcmTime1 = 60 * 60,
			case OnlineTime1 > FcmTime1 andalso OnlineTime1 - (OnlineTime1 div FcmTime1) * FcmTime1 > 0 andalso OnlineTime1 - (OnlineTime1 div FcmTime1) * FcmTime1 < 60 of
				true ->
						%io:format("2min~n"),
					{ok, BinData} = pt_420:write(42003, [_State, 0, OnlineTime1]),
					%io:format("0, OnlineTime:~p~n", [OnlineTime1]),
					lib_server_send:send_to_uid(Id, BinData);
				false -> skip
			end,
			%% 还有5分钟时发一次提示
			case ?DEFINE_FCM_ZERO_EXP_TIME - OnlineTime1 < 6 * 60 andalso ?DEFINE_FCM_ZERO_EXP_TIME - OnlineTime1 > 5 * 60 of
				false -> skip;
				true -> 
					{ok, BinData2} = pt_420:write(42003, [_State, 0, OnlineTime1]),
					%io:format("0-2, OnlineTime:~p~n", [OnlineTime1]),
					lib_server_send:send_to_uid(Id, BinData2)
			end;
		%% 15分钟
		2 ->
			mod_fcm:insert(Id, NowTime, OnlineTime1, _OffLineTime1, _State),
			FcmTime2 = 15 * 60,
			case OnlineTime1 > FcmTime2 andalso OnlineTime1 - (OnlineTime1 div FcmTime2) * FcmTime2 > 0 andalso OnlineTime1 - (OnlineTime1 div FcmTime2) * FcmTime2 < 60 of
				true ->
						%io:format("1min~n"),
					{ok, BinData} = pt_420:write(42003, [_State, 2, OnlineTime1]),
					%io:format("2, OnlineTime:~p~n", [OnlineTime1]),
					lib_server_send:send_to_uid(Id, BinData);
				false -> skip
			end;
		_ -> skip
	end.
