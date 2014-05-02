%%%------------------------------------
%%% @Module  : mod_activity_festival
%%% @Author  : hekai
%%% @Created : 2012.11
%%% @Description: 节日活动
%%%------------------------------------
-module(mod_activity_festival).
-behaviour(gen_server).
-export([start/0, stop/0]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

start() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

set_pre_loginTime(Uid,Time) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {set_pre_loginTime, Uid,Time}).

get_pre_loginTime(Uid) ->
	gen_server:call(misc:get_global_pid(?MODULE), {get_pre_loginTime, Uid}).

%% 发送元宵放花灯数据给玩家 
send_lamp_to_player(PlayerId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {send_lamp_to_player, PlayerId}).

%% 花灯详细信息 
lamp_info(PlayerId, LampId) -> 
	gen_server:cast(misc:get_global_pid(?MODULE), {lamp_info, PlayerId, LampId}).

%% 花灯送祝福记录 
lamp_bewish_log(PlayerId, LampId) -> 
	gen_server:cast(misc:get_global_pid(?MODULE), {lamp_bewish_log, PlayerId, LampId}).

%% 燃放花灯 
fire_lamp(UniteStatus, Type) -> 
	gen_server:cast(misc:get_global_pid(?MODULE), {fire_lamp, UniteStatus, Type}).

%% 邀请好友为花灯送祝福
invite_wish_lamp(PlayerId, FriendName, LampId) ->
  gen_server:cast(misc:get_global_pid(?MODULE), {invite_wish_lamp, PlayerId, FriendName, LampId}).

%% 为花灯送祝福 
wish_for_lamp(PlayerId, PlayerName, LampId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {wish_for_lamp, PlayerId, PlayerName, LampId}).

%% 收获花灯  
gain_lamp(PlayerId, LampId) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {gain_lamp, PlayerId, LampId}).

%% 花灯数据初始化
activity_lamp_init() ->
	gen_server:cast(misc:get_global_pid(?MODULE), {activity_lamp_init}).

%% 检测花灯形象有效期并结算
check_lamp_figuretime() ->
	gen_server:cast(misc:get_global_pid(?MODULE), {check_lamp_figuretime}).

init([]) ->
	process_flag(trap_exit, true),
	lib_activity_festival:data_init(),	
	{ok, []}.

handle_call(Request, From, State) ->
    mod_activity_festival_call:handle_call(Request, From, State).

handle_cast(Msg, State) ->
     mod_activity_festival_cast:handle_cast(Msg, State).

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
