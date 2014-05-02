%%%------------------------------------
%%% @Module  : mod_guild_dun_mgr
%%% @Author  : hekai
%%% @Description: 
%%%------------------------------------

-module(mod_guild_dun_mgr).
-behaviour(gen_fsm).
-export([start_link/2, reset_time/2]).
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).
-compile(export_all).
-include("guild_dun.hrl").
-record(state, {
		guild_id =0,  %% 帮派Id
		start_time=0, %% 副本开始时刻
		end_time=0,   %% 副本结束时刻
		dun1_start_time=0, %% 关卡1开始时间
		dun2_start_time=0, %% 关卡2开始时间
		dun3_start_time=0, %% 关卡3开始时间
		pass_dun=[{1,0}] %% 是否通关副本关卡 0否|1是
%%		pass_dun=[{1,0},{2,0},{3,0}] %% 是否通关副本关卡 0否|1是
	}).
%%-define(BEFORE_CHECK_TIME, 5*60*1000).
-define(BEFORE_CHECK_TIME, 1*1000).
-define(TIMEOUT_DEFAULT, 100).


%% 重置活动时间
reset_time(GuildId, BeginTime) ->
	FsmName = ?GUILD_DUN++integer_to_list(GuildId), 
	case misc:whereis_name(global,FsmName) of
		Pid when is_pid(Pid) ->
			gen_fsm:send_all_state_event({global, FsmName}, stop);
%%			gen_fsm:sync_send_all_state_event(Pid, stop);
		_ ->
			skip
	end,
	gen_fsm:start_link({global,FsmName}, ?MODULE, [GuildId, BeginTime], []).

start_link(GuildId, BeginTime) ->
	FsmName = ?GUILD_DUN++integer_to_list(GuildId), 
	gen_fsm:start_link({global,FsmName}, ?MODULE, [GuildId, BeginTime], []).

init([GuildId, BeginTime])->
	NowTime = util:unixtime(),
	State = #state{
		guild_id = GuildId,
		start_time = BeginTime
	},
%%	io:format("---dun--init--~p~n", [(BeginTime-NowTime)*1000-?BEFORE_CHECK_TIME]),
    {ok, no_begin, State, (BeginTime-NowTime)*1000-?BEFORE_CHECK_TIME}.

%% 未开启前状态
no_begin(_Event, State) ->
	NowTime = util:unixtime(),	
	case  State#state.start_time -NowTime >?BEFORE_CHECK_TIME of
		true -> 
			{next_state, no_begin, State, ?TIMEOUT_DEFAULT};
		false ->
			case State#state.start_time -NowTime=<0 of
				true ->					
					{next_state, beginning, State, ?TIMEOUT_DEFAULT};
				false ->
					%% 提前5分钟,提示玩家进入
					lib_guild_dun:remind_msg(State#state.guild_id, State#state.start_time, 1),
					{next_state, no_begin, State, (State#state.start_time -NowTime)*1000}
			end		
	end.

%% 开启状态
beginning(_Event, State) ->	
	NowTime = util:unixtime(),					
	%% 过滤出未通关的副本关卡,随机进入一个
	F1 = fun({_,Flag}) -> Flag=:=0 end,
	NotPass = lists:filter(F1, State#state.pass_dun),
	RandOne = util:list_rand(NotPass),
%%	io:format("---RandOne---~p~n", [RandOne]),
	case RandOne=/=null	of
		true ->
			{No, _} = RandOne,
			GoState = list_to_atom("dun_"++integer_to_list(No)), 
			CountdownAtom = list_to_atom("dun"++integer_to_list(No)++"_countdown"),
			Countdown = data_guild_dun:get_dun_config(CountdownAtom),					
			case No of
				1 -> NewState = State#state{dun1_start_time=NowTime+Countdown};
				2 -> NewState = State#state{dun2_start_time=NowTime+Countdown};
				3 -> NewState = State#state{dun3_start_time=NowTime+Countdown}
			end,					
			{next_state, GoState, NewState, 100};
		false ->
			lib_guild_dun:remind_msg(State#state.guild_id, State#state.start_time, 3),
			mod_guild_dun:stop_guild_dun(State#state.guild_id),	
			{stop, normal, State}
	end.

%% 副本关卡1
%% @dec 如果不是第一个随机关卡,需要自动传送到副本出生点 
dun_1(_Event, State)->
%%	io:format("--dun_1---~n"),
	NowTime = util:unixtime(),
	Dun1Loop = data_guild_dun:get_dun_config(dun1_loop),
	Dun1StartTime = State#state.dun1_start_time,
	% 倒计时
	Countdown = data_guild_dun:get_dun_config(dun1_countdown),
	Dun1Scene = data_guild_dun:get_dun_config(dun1_scene),	
	case NowTime-Dun1StartTime>=Dun1Loop of
		true -> 
			% 通知结束，发放奖励
			mod_guild_dun:award_dun(State#state.guild_id, 1),
			PassList = State#state.pass_dun,
			PassList2 = lists:keydelete(1, 1, PassList),
		    PassList3 = PassList2 ++ [{1,1}],
			NewState = State#state{pass_dun=PassList3},
			{next_state, beginning, NewState, 100};
		false ->
%%			io:format("---dun_panel--~p,~p~n", [NowTime-Dun1StartTime, Countdown]),
			case NowTime-Dun1StartTime>=0 of
			true ->				
				mod_guild_dun:dun_panel(1, State#state.guild_id, 0),	
				{next_state, dun_1, State, Dun1Loop*1000};
			false ->
				case private_is_first_dun(State, 1) of
					true -> 
						% (Dun1Loop+5)*1000 加上5秒的倒计时才正式开始计算时间
						mod_guild_dun:set_beginning_dun(1, State#state.guild_id, NowTime+Countdown, NowTime+Countdown+Dun1Loop),
						mod_guild_dun:init_dun_1(State#state.guild_id),
						%% 活动开始,提示玩家进入
%%						io:format("--remind_msg1----~n"),
						lib_guild_dun:remind_msg(State#state.guild_id, State#state.start_time, 2),
						%% 关卡开始倒计时
						%%mod_guild_dun:countdown_msg(Dun1Scene, State#state.guild_id, Countdown),	
						{next_state, dun_1, State, (1+Countdown)*1000};
					false ->
						% 不是第一个随机关卡，自动传送			
						mod_guild_dun:init_dun_1(State#state.guild_id),
						mod_guild_dun:auto_transfer(State#state.guild_id, 1, NowTime+Countdown, NowTime+Countdown+Dun1Loop),	
						mod_guild_dun:dun_panel(1, State#state.guild_id, 0),
						%% 关卡开始倒计时
						mod_guild_dun:countdown_msg(Dun1Scene, State#state.guild_id, Countdown),
						{next_state, dun_1, State, Countdown*1000}
				end
			end			
	end.

%% 副本关卡2
dun_2(_Event, State)->
	NowTime = util:unixtime(),
	Dun2Loop = data_guild_dun:get_dun_config(dun2_loop),
	Dun2StartTime = State#state.dun2_start_time,
	% 倒计时
	Countdown = data_guild_dun:get_dun_config(dun2_countdown),
	Dun2Scene = data_guild_dun:get_dun_config(dun2_scene),
	case NowTime-Dun2StartTime>=Dun2Loop of
		true -> 
			% 通知结束，发放奖励
			mod_guild_dun:award_dun(State#state.guild_id, 2),
			PassList = State#state.pass_dun,
			PassList2 = lists:keydelete(2, 1, PassList),
		    PassList3 = PassList2 ++ [{2,1}],
			NewState = State#state{pass_dun=PassList3},
			{next_state, beginning, NewState, 100};
		false ->
			case NowTime-Dun2StartTime>=0 of
				true ->
					mod_guild_dun:init_mon(State#state.guild_id),
					{next_state, dun_2, State, Dun2Loop*1000};
				false ->
					case private_is_first_dun(State, 1) of
						true -> 
							% (Dun1Loop+5)*1000 加上5秒的倒计时才正式开始计算时间
							mod_guild_dun:set_beginning_dun(2, State#state.guild_id, NowTime+Countdown, NowTime+Countdown+Dun2Loop),
							%% 活动开始,提示玩家进入
%%							io:format("--remind_msg1----~n"),
							lib_guild_dun:remind_msg(State#state.guild_id, State#state.start_time, 2),
							%% 关卡开始倒计时
							mod_guild_dun:countdown_msg(Dun2Scene, State#state.guild_id, Countdown),	
							{next_state, dun_2, State, Countdown*1000};
						false ->
							% 不是第一个随机关卡，自动传送			
							mod_guild_dun:auto_transfer(State#state.guild_id, 1, NowTime+Countdown, NowTime+Countdown+Dun2Loop),	
							mod_guild_dun:dun_panel(1, State#state.guild_id, 0),
							%% 关卡开始倒计时
							mod_guild_dun:countdown_msg(Dun2Scene, State#state.guild_id, Countdown),
							{next_state, dun_2, State, Countdown*1000}
					end
			end			
	end.

%% 副本关卡3
dun_3(_Event, State)->
	NowTime = util:unixtime(),
	Dun3StartTime = State#state.dun3_start_time,
	Countdown = data_guild_dun:get_dun_config(dun3_countdown),
	PerLoop = data_guild_dun:get_dun_config(dun3_per_loop),
    MinLoop = data_guild_dun:get_dun_config(dun3_min_loop),
	Dun3Scene = data_guild_dun:get_dun_config(dun3_scene),
	case mod_guild_dun:dun_3_is_end(State#state.guild_id) andalso NowTime>Dun3StartTime+MinLoop of
		false ->					
			case NowTime<Dun3StartTime of
				true -> 	
				case private_is_first_dun(State, 1) of
				true ->
					mod_guild_dun:set_beginning_dun(3, State#state.guild_id, NowTime+Countdown, NowTime+Countdown+PerLoop),
					%% 活动开始,提示玩家进入
%%					io:format("--remind_msg3----~n"),
					lib_guild_dun:remind_msg(State#state.guild_id, State#state.start_time, 2),
					%% 关卡开始倒计时
					mod_guild_dun:countdown_msg(Dun3Scene, State#state.guild_id, Countdown),
					{next_state, dun_3, State, Countdown*1000};
				false ->
%%					io:format("--not_first_dun-3--~n"),
					% 不是第一个随机关卡，自动传送
					mod_guild_dun:auto_transfer(State#state.guild_id, 1, NowTime+Countdown, NowTime+Countdown+PerLoop),
					% 刷新面板
					mod_guild_dun:dun_panel(3, State#state.guild_id, 0),
					%% 关卡开始倒计时
					mod_guild_dun:countdown_msg(Dun3Scene, State#state.guild_id, Countdown),
					{next_state, dun_3, State, Countdown*1000}
				end;
				false ->
					IsEnd = mod_guild_dun:transfer_to_answer_question(State#state.guild_id),	
					case IsEnd=:=1 andalso NowTime>Dun3StartTime+MinLoop of
						true -> 
							% 通知结束，发放奖励
							PassList = State#state.pass_dun,
							PassList2 = lists:keydelete(3, 1, PassList),
							PassList3 = PassList2 ++ [{3,1}],
							NewState = State#state{pass_dun=PassList3},
							mod_guild_dun:award_dun(State#state.guild_id, 3),
							{next_state, beginning, NewState, 100};
						false -> {next_state, dun_3, State, PerLoop*1000} 
					end
			end;
		true ->
			% 通知结束，发放奖励
			mod_guild_dun:award_dun(State#state.guild_id, 3),
			{next_state, beginning, State, 100}
	end.


handle_event(stop, _StateName, State) ->
    {stop, normal, State};
handle_event(_Event, StateName, State) ->
    {next_state, StateName, State}.

%% 关闭
handle_sync_event(stop, _From, _StateName, State) ->
    {stop, normal, State};
%% 错误
handle_sync_event(_Event, _From, StateName, State) ->
    {reply, ok, StateName, State, 0}.

%%中断服务
handle_info(stop, _StateName, State) ->
    {stop, normal, State};
handle_info(_Info, StateName, State) ->
    {next_state, StateName, State}.

terminate(_Reason, _StateName, State) ->
	terminate_handle(State),
    ok.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.

%% 结束处理
terminate_handle(_State) ->
	skip.

%% 是否第一个随机副本关卡
%% @Num 副本数量
%% @return true是|false否
private_is_first_dun(State, Num) ->
	F1 = fun({_,Flag}) -> Flag=:=0 end,
	NotPass = lists:filter(F1, State#state.pass_dun),
	case length(NotPass)=:=Num of
		true -> true;
		false -> false 
	end.

