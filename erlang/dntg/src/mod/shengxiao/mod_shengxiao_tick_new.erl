%%%------------------------------------
%%% @Module  : timer_shengxiao_tick_new
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.5.30
%%% @Description: 生肖抽奖状态机
%%%------------------------------------

-module(mod_shengxiao_tick_new).
-behaviour(gen_fsm).
-include("shengxiao.hrl").
-export([start_link/0, init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4, stop/0]).
-export([init_date/2, broadcast/2, lottery/2, send_cw/2, broadcast2/2, activity_close/2, clean_up/2]).
% ----------------------------
%       STATE DEFINE
% ----------------------------
-record(state, {
	long = 0
}).

start_link() ->
%   catch util:errlog("~p start_link!! ~n", [?MODULE]),
    gen_fsm:start(?MODULE, [], []).

stop() ->
    gen_fsm:send_event(?MODULE, 'stop').

init(_) ->
    process_flag(trap_exit, true),
	%% 启动生肖大奖活动
	mod_shengxiao_new:start_link(),
	%% 活动开始,广播提示
	Time = lib_shengxiao_new:end_countdown(),
	%io:format("Time:~p~n", [Time]),
	{ok, BinData} = pt_630:write(63004, Time),
	lib_unite_send:send_to_all(35, 100, BinData),
    {ok, init_date, #state{}, 10}.

handle_event(_Event, _StateName, StateData) ->
    {next_state, _StateName, StateData, 10}.

handle_sync_event(_Event, _From, _StateName, StateData) ->
    {next_state, _StateName, StateData, 10}.

code_change(_OldVsn, _StateName, State, _Extra) ->
    {ok, _StateName, State}.

handle_info(shengxiao_stop, _StateName, State) ->
%    catch util:errlog("~p get stop sign!!!~n", [?MODULE]),
    {stop, normal, State};
    
handle_info(_Any, _StateName, State) ->
%    catch util:errlog("~p get unknow handle info:~p~n", [?MODULE, _Any]),
    {next_state, _StateName, State, 10}.

terminate(_Any, _StateName, _Opts) ->
%    catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

init_date(_R, State) ->
	%io:format("init:~p~n", [time()]),
	%% 活动开始,发送传闻
	lib_chat:send_TV({all},1,2, ["shengxiao", 2]),
    {next_state, broadcast, State, ?SHENGXIAO_BROAD * 1000}.

broadcast(_R, State) ->
	%io:format("broadcast:~p~n", [time()]),
	[Hour, Min] = ?SHENGXIAO_OPTION_TIME,
	LotteryTime = util:unixdate() + Hour * 60 * 60 + Min * 60 + ?SHENGXIAO_LONG,
	Now         = util:unixtime(),
	case Now < LotteryTime of
		true  -> 
			%% 广播提示
			Time = lib_shengxiao_new:end_countdown(),
			{ok, BinData} = pt_630:write(63004, Time),
			lib_unite_send:send_to_all(35, 100, BinData),
			{next_state, broadcast, State, ?SHENGXIAO_BROAD * 1000};
		false ->
			{next_state, lottery, State, 10}
	end.

%% 活动抽奖
lottery(_R, State) ->
	%io:format("lottery:~p~n", [time()]),
	lib_shengxiao_new:start_lottery(),
	{next_state, send_cw, State, ?SHENGXIAO_BROAD * 1000}.

send_cw(_R, State) ->
	%% 发送特等奖和一等奖获奖者传闻
	lib_shengxiao_new:send_all_te_cw(),
	{next_state, broadcast2, State, 10}.

broadcast2(_R, State) ->
	%io:format("broadcast2:~p~n", [time()]),
	[Hour, Min] = ?SHENGXIAO_OPTION_TIME,
	CloseTime   = util:unixdate() + Hour * 60 * 60 + Min * 60 + ?SHENGXIAO_LONG + ?SHENGXIAO_END,
	Now         = util:unixtime(),
	case Now < CloseTime of
		true  -> 
			%% 广播提示
			Time = lib_shengxiao_new:end_countdown(),
			{ok, BinData} = pt_630:write(63004, Time),
			lib_unite_send:send_to_all(35, 100, BinData),
			{next_state, broadcast2, State, ?SHENGXIAO_BROAD * 1000};
		false ->
			%% 活动结束广播提示
			{ok, BinData} = pt_630:write(63008, ""),
			lib_unite_send:send_to_all(35, 100, BinData),
			{next_state, activity_close, State, 10}
	end.

%% 活动关闭,发送可领奖的提示(仅针对未领奖用户)
activity_close(_R, State) ->
	%io:format("close:~p~n", [time()]),
	CloseTime   = util:unixdate() + 23 * 60 * 60 + 50 * 60,
	Now         = util:unixtime(),
	case Now < CloseTime of
		true  -> 
			%% 未领奖用户未领奖提示(客户端出现图标)
            {ok, BinData} = pt_630:write(63009, [1]),
			lib_shengxiao_new:send_award_tips(BinData),
			{next_state, activity_close, State, ?SHENGXIAO_BROAD * 1000};
		false ->
            %% 未领奖用户已发奖提示(客户端删除图标)
            {ok, BinData} = pt_630:write(63009, [0]),
			lib_shengxiao_new:send_award_tips(BinData),
			%% 清理当天活动信息
			{next_state, clean_up, State, 10}
	end.

%% 清理当天活动信息
clean_up(_R, State) ->
	%io:format("clean_up:~p~n", [time()]),
	%% 给未领奖的用户发送邮件
	lib_shengxiao_new:send_all_award(),
	%% 清除旧数据(上次抽奖信息)
    mod_shengxiao_new:clear_data(),
	%% 关闭活动
	mod_shengxiao_new:close(),
	{stop, normal, State}.
