%%%------------------------------------
%%% @Module  : mod_guild_dun
%%% @Author  : hekai
%%% @Description: 
%%%------------------------------------

-module(mod_guild_dun).
-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).
-include("guild_dun.hrl").


%% 预约帮派活动
booking_dun(GuildId, BookingTime) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {booking_dun, GuildId, BookingTime}).

%% 重置帮派活动时间
reset_time(GuildId, BookingTime) ->	
	gen_server:cast(misc:get_global_pid(?MODULE), {reset_time, GuildId, BookingTime}).

%% 副本是否正在开启
dun_is_open(PlayerId, GuildId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {dun_is_open, PlayerId, GuildId}).

%% 进入副本
enter_dun(PlayerId, Lv, NickName, GuildId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {enter_dun, PlayerId, Lv, NickName, GuildId}).

%% 退出副本
exit_dun(PlayerId, GuildId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {exit_dun, PlayerId, GuildId}).

%% 自动传送
auto_transfer(GuildId, Dun, StartTime, EndTime) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {auto_transfer, GuildId, Dun, StartTime, EndTime}).

%% 副本结束,清除帮派记录
stop_guild_dun(GuildId) -> 
	gen_server:cast(misc:get_global_pid(?MODULE), {stop_guild_dun, GuildId}).

%% 初始化关卡1-陷阱区域
init_dun_1(GuildId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {init_dun_1, GuildId}).

%% 关卡1尸体列表 
dun_1_die_list(GuildId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {dun_1_die_list, GuildId}).

%% 关卡1跳跃判断是否陷阱
jump_grid(PlayerId, PlayerName, Lv, GuildId, X, Y) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {jump_grid, PlayerId, PlayerName, Lv, GuildId, X, Y}).

%% 关卡1跳跃提交完成
finish_all_jump(PlayerId, GuildId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {finish_all_jump, PlayerId, GuildId}).

%% 关卡1复活
back_to_life(PlayerId, GuildId)->
	gen_server:cast(misc:get_global_pid(?MODULE), {back_to_life, PlayerId, GuildId}).

%% 重启处理
restart_init(BookingList) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {restart_init, BookingList}).
%% 关卡二提交完成
dun2_finish_escape(PlayerId, GuildId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {dun2_finish_escape, PlayerId, GuildId}).

%% 关卡二死亡处理
dun2_die_handle(NewStatus) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {dun2_die_handle, NewStatus}).

%% 关卡二召唤怪物
init_mon(GuildId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {init_mon, GuildId}).

%% 关卡3怪物列表 
dun_3_animal(PlayerId, GuildId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {dun_3_animal,PlayerId, GuildId}).

%% 关卡3是否结束 
dun_3_is_end(GuildId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {dun_3_is_end, GuildId}).

%% 关卡3传送去答题
transfer_to_answer_question(GuildId) ->
	gen_server:call(misc:get_global_pid(?MODULE), {transfer_to_answer_question, GuildId}).

%% 关卡三答题
answer_question(Answer,PlayerId,GuildId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {answer_question, Answer,PlayerId,GuildId}).

%% 奖励结算
award_dun(GuildId, Dun) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {award_dun, GuildId, Dun}).

%% 关卡面板信息
dun_panel(Dun, GuildId, PlayerId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {dun_panel, Dun, GuildId, PlayerId}).

%% 设置正在进行的关卡
set_beginning_dun(Dun, GuildId, StartTime, EndTime) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {set_beginning_dun, Dun, GuildId, StartTime, EndTime}).
	
%% 提示倒计时
countdown_msg(DunScene, GuildId, Countdown) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {countdown_msg, DunScene, GuildId, Countdown}).

start_link() ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%% 初始化
init([]) ->	
	spawn(fun() ->		
		timer:sleep(2*1000),
		BookingList = lib_guild_dun:init(),
		mod_guild_dun:restart_init(BookingList),
%%		io:format("---BookingList--~p~n", [BookingList]),
		F = fun([GuildId, BeginTime]) ->
				mod_guild_dun_mgr:start_link(GuildId, BeginTime)
		end,
		lists:foreach(F, BookingList)
	end
	),	
	State = #guild_dun_state{},
	{ok, State}.


%% 关卡3是否结束
handle_call({dun_3_is_end, GuildId}, _From, State) ->
	Reply = lib_guild_dun:dun_3_is_end(GuildId, State),
    {reply, Reply, State};

%% 关卡3传送去答题
handle_call({transfer_to_answer_question, GuildId}, _From, State) ->
	[IsEnd,	NewState] = lib_guild_dun:transfer_to_answer_question(GuildId, State),
    {reply, IsEnd, NewState};


%% 默认匹配
handle_call(Event, _From, State) ->
    catch util:errlog("mod_guild_dun:handle_call not match: ~p~n", [Event]),
    {reply, ok, State}.


%% 预约帮派活动
handle_cast({booking_dun, GuildId, BookingTime}, State)->
	GuildDun = #guild_dun{
			guild_id = 	GuildId,
			start_time = BookingTime
		},	
	NewAllGuildDun = dict:store(GuildId, GuildDun, State#guild_dun_state.guild_dun),
	NewGuildDunState = State#guild_dun_state{
        guild_dun = NewAllGuildDun
	},
	mod_guild_dun_mgr:start_link(GuildId, BookingTime),
	{noreply, NewGuildDunState};


%% 重置帮派活动时间
handle_cast({reset_time, GuildId, BookingTime}, State)->
	GuildDun = #guild_dun{
			guild_id = 	GuildId,
			start_time = BookingTime
		},	
	NewAllGuildDun = dict:store(GuildId, GuildDun, State#guild_dun_state.guild_dun),
	NewGuildDunState = State#guild_dun_state{
        guild_dun = NewAllGuildDun
	},	
	mod_guild_dun_mgr:reset_time(GuildId, BookingTime),
	{noreply, NewGuildDunState};


%% 初始化关卡1-陷阱区域
handle_cast({init_dun_1, GuildId}, State)->
	NewState = lib_guild_dun:init_dun_1(GuildId, State),
	{noreply, NewState};

%% 关卡1尸体列表
handle_cast({dun_1_die_list, GuildId}, State)->
	lib_guild_dun:dun_1_die_list(GuildId, State),
	{noreply, State};

%% 关卡1跳跃判断是否陷阱
handle_cast({jump_grid, PlayerId, PlayerName, Lv, GuildId, X, Y}, State)->
	NewState = lib_guild_dun:jump_grid(PlayerId, PlayerName, Lv, GuildId, X, Y, State),
	{noreply, NewState};

%% 关卡一提交完成 
handle_cast({finish_all_jump, PlayerId, GuildId}, State)->
	NewState = lib_guild_dun:finish_all_jump(PlayerId, GuildId, State),
	{noreply, NewState};

%% 关卡一复活
handle_cast({back_to_life, PlayerId, GuildId}, State)->
	NewState = lib_guild_dun:back_to_life(PlayerId, GuildId, State),
	{noreply, NewState};
%% 重启处理
handle_cast({restart_init, BookingList}, State)->
	NewState = lib_guild_dun:restart_init(BookingList, State),
	{noreply, NewState};

%% 关卡二提交完成
handle_cast({dun2_finish_escape, PlayerId, GuildId}, State)->
	NewState = lib_guild_dun:dun2_finish_escape(PlayerId, GuildId, State),
	{noreply, NewState};

%% 关卡二死亡处理
handle_cast({dun2_die_handle, NewStatus}, State)->
	NewState = lib_guild_dun:dun2_die_handle(NewStatus, State),
	{noreply, NewState};

%% 关卡二召唤怪物
handle_cast({init_mon, GuildId}, State)->
	lib_guild_dun:init_mon(GuildId),
	{noreply, State};

%% 进入副本
handle_cast({enter_dun, PlayerId, Lv, NickName, GuildId}, State)->
	NewState = lib_guild_dun:enter_dun(PlayerId, Lv, NickName, GuildId, State),
	{noreply, NewState};

%% 退出副本
handle_cast({exit_dun, PlayerId, GuildId}, State)->
	NewState = lib_guild_dun:exit_dun(PlayerId, GuildId, State),
	{noreply, NewState};

%% 自动传送
handle_cast({auto_transfer, GuildId, Dun, StartTime, EndTime}, State)->
	NewState = lib_guild_dun:auto_transfer(GuildId, State, Dun, StartTime, EndTime),
	{noreply, NewState};

%% 结束副本
handle_cast({stop_guild_dun, GuildId}, State)->
	NewState = lib_guild_dun:stop_guild_dun(GuildId, State),
	{noreply, NewState};

%% 奖励结算
handle_cast({award_dun, GuildId, Dun}, State)->
	lib_guild_dun:award_dun(GuildId, State, Dun),
	{noreply, State};

%% 关卡三怪物列表
handle_cast({dun_3_animal, PlayerId, GuildId}, State)->
	lib_guild_dun:dun_3_animal(PlayerId, GuildId, State),
	{noreply, State};

%% 关卡三答题
handle_cast({answer_question, Answer,PlayerId,GuildId}, State)->
	NewState = lib_guild_dun:answer_question(Answer,PlayerId,GuildId,State),
	{noreply, NewState};

%% 关卡面板信息
handle_cast({dun_panel, Dun, GuildId, PlayerId}, State)->
	lib_guild_dun:dun_panel(Dun, GuildId, State, PlayerId),
	{noreply, State};

%% 设置正在进行的关卡
handle_cast({set_beginning_dun, Dun, GuildId, StartTime, EndTime}, State)->
	NewState = lib_guild_dun:set_beginning_dun(Dun, GuildId, StartTime, EndTime, State),
	{noreply, NewState};

%% 倒计时
handle_cast({countdown_msg, DunScene, GuildId, Countdown}, State)->
	lib_guild_dun:countdown_msg(DunScene, GuildId, Countdown, State),
	{noreply, State};

%% 副本是否正在开启
handle_cast({dun_is_open, PlayerId, GuildId}, State) ->
	lib_guild_dun:dun_is_open(PlayerId, GuildId, State),
    {noreply, State};

%% 默认匹配
handle_cast(Event, State) ->
    catch util:errlog("mod_guild_dun:handle_cast not match: ~p~n", [Event]),
    {noreply, State}.

%% handle_info信息处理
%% 默认匹配
handle_info(Info, State) ->
    catch util:errlog("mod_guild_dun:handle_info not match: ~p~n", [Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra)->
    {ok, State}.
