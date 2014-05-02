%%%------------------------------------
%%% @Module  : mod_activity_festival_call
%%% @Author  : hekai
%%% @Created : 2012.11
%%% @Description: 节日活动
%%%------------------------------------
-module(mod_activity_festival_call).
-export([handle_call/3]).

%% 获取最后登录时间
handle_call({get_pre_loginTime, Uid}, _From, State) ->
	NowTime = util:unixtime(),
	Time = get(Uid),
	Reply = 
	case  Time=:= undefined of
		true ->
			put(Uid,NowTime),	
			NowTime;
		false -> Time
	end,
	{reply, Reply, State};

%% 燃放花灯
handle_call({fire_lamp, UniteStatus, Type}, _From, State) ->
	Reply = lib_activity_festival:fire_lamp(UniteStatus, Type), 	 
	{reply, Reply, State};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_activity_festival:handle_call not match: ~p~n", [Event]),
    {reply, ok, Status}.
