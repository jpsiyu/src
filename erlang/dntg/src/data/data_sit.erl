%%%-------------------------------------------------------------------
%%% @Module	: data_sit
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 12 Mar 2013
%%% @Description: 
%%%-------------------------------------------------------------------
-module(data_sit).
-compile(export_all).

get_open_time() ->
    {{21, 0, 0}, {21, 15, 0}}.

get_open_unixtime() ->
    TodayTS = util:unixdate(),
    {{BeginH, BeginM, BeginS}, {EndH, EndM, EndS}} = get_open_time(),
    BeginTS = TodayTS + BeginH * 3600 + BeginM * 60 + BeginS,
    EndTS = TodayTS + EndH * 3600 + EndM * 60 + EndS,
    [BeginTS, EndTS].

is_party_time() ->
    case data_activity_time:get_time_by_type(14) of
	[] -> false;
	[Begin,End] ->
	    Now = util:unixtime(),
	    case Now >= Begin andalso Now =< End of
		true ->
		    [B, E] = get_open_unixtime(),
		    Now >= B andalso Now =< E;
		false -> false
	    end
    end.


get_remain_party_time() ->
    case is_party_time() of
	false -> 0;
	true ->
	    [_,End] = get_open_unixtime(),
	    RemainTime = End - util:unixtime(),
	    case RemainTime < 0 of
		true -> 0;
		false -> RemainTime
	    end
    end.
    
is_pair(FigureA, FigureB) ->
    PairList = [
		{523012,523013},{523013,523012},
		{523034,523035},{523035,523034},
		{523025,523026},{523026,523025},
		{523001,523003},{523003,523001},
		{523020,523014},{523014,523020}
	       ],
    lists:member({FigureA, FigureB}, PairList).

can_get_party_addition(FigureA, FigureB, SceneId, X, Y) ->
    case is_party_time() of
	false -> false;
	true ->
	    case SceneId =:= 102 of
		true ->
		    case lib_scene:is_safe(SceneId, X, Y) of
			true -> is_pair(FigureA, FigureB);
			false -> false
		    end;
		false -> false
	    end
    end.
		    
