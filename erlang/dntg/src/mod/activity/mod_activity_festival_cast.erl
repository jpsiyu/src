%%%------------------------------------
%%% @Module  : mod_activity_festival_cast
%%% @Author  : hekai
%%% @Created : 2012.11
%%% @Description: 节日活动
%%%------------------------------------
-module(mod_activity_festival_cast).
-export([handle_cast/2]).

%% 设置最后登录时间
handle_cast({set_pre_loginTime, Uid,Time}, State) ->	
	put(Uid,Time),	
    {noreply, State};

%% 发送元宵放花灯数据给玩家 
handle_cast({send_lamp_to_player, PlayerId}, State) ->	
	lib_activity_festival:send_lamp_to_player(PlayerId),	
    {noreply, State};

%% 发送元宵放花灯数据给玩家 
handle_cast({lamp_info, PlayerId, LampId}, State) ->	
	lib_activity_festival:lamp_info(PlayerId, LampId),	
    {noreply, State};

%% 花灯送祝福记录 
handle_cast({lamp_bewish_log, PlayerId, LampId}, State) ->	
	lib_activity_festival:lamp_bewish_log(PlayerId, LampId),	
    {noreply, State};

%% 燃放花灯 
handle_cast({fire_lamp, UniteStatus, Type}, State) ->	
	lib_activity_festival:fire_lamp(UniteStatus, Type),	
    {noreply, State};

%% 邀请好友为花灯送祝福
handle_cast({invite_wish_lamp, PlayerId, FriendName, LampId}, State) ->	
	lib_activity_festival:invite_wish_lamp(PlayerId, FriendName, LampId),	
    {noreply, State};

%% 为花灯送祝福 
handle_cast({wish_for_lamp, PlayerId, PlayerName, LampId}, State) ->	
	lib_activity_festival:wish_for_lamp(PlayerId, PlayerName, LampId),	
    {noreply, State};

%% 收获花灯   
handle_cast({gain_lamp, PlayerId, LampId}, State) ->	
	lib_activity_festival:gain_lamp(PlayerId, LampId),	
    {noreply, State};

%% 花灯数据初始化
handle_cast({activity_lamp_init}, State) ->	
	lib_activity_festival:activity_lamp_init(),	
    {noreply, State};

%% 花灯数据初始化
handle_cast({check_lamp_figuretime}, State) ->	
	lib_activity_festival:check_lamp_figuretime(),	
    {noreply, State};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_activity_festival:handle_cast not match: ~p~n", [Event]),
    {noreply, Status}.
