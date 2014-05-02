%%%------------------------------------
%%% @Module  : mod_fcm_call
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.28
%%% @Description: handle_call
%%%------------------------------------
-module(mod_fcm_call).
-export([handle_call/3]).

%% 根据玩家Id，返回{LastLoginTime, OnLineTime, TempOffLineTime}
handle_call({get_by_id, Id}, _From, Status) ->
	Reply = get({fcm, Id}),
    {reply, Reply, Status};

%% 全部fcm，返回List
handle_call(get_all, _From, Status) ->
	Reply = get_all_deal(get(), []),
    {reply, Reply, Status};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_fcm_call:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.

get_all_deal([], L2) -> L2;
get_all_deal([{H1, H2} | T], L2) -> 
	case H1 of
		{fcm, _Id} ->
			get_all_deal(T, [{H1, H2} | L2]);
		_ ->
			get_all_deal(T, L2)
	end.
