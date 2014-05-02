%%%-------------------------------------------------------------------
%%% @Module	: mod_qixi_call
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 25 Oct 2012
%%% @Description: mod_qixi_call
%%%-------------------------------------------------------------------
-module(mod_qixi_call).
-export([handle_call/3]).
-include("qixi.hrl").
handle_call({lookup_player_task, Id}, _From, Status) ->
    Reply = case get({player_task, Id}) of
		undefined ->
		    case mod_qixi:load_from_db(Id) of
			null ->
			    Activity = data_qixi:init_activity_task(),
			    put({player_task, Id}, Activity),
			    catch mod_qixi:save_to_db(Id, Activity),
			    Activity;
			A ->
			    put({player_task, Id}, A),
			    A
		    end;
		Activity -> Activity
	    end,
    {reply, Reply, Status};

handle_call({lookup_player_task_by_type, Id, Type}, _From, Status) ->
    Reply = case get({player_task, Id}) of
		undefined ->
		    0;
		Activity ->
		    case lists:keyfind(Type, 1, Activity) of
			false -> 0;
			{_, CurrentNum, _} -> CurrentNum
		    end
	    end,
    {reply, Reply, Status};


handle_call({check_get_by_type, Id, Type}, _From, Status) ->
    Reply = case get({player_task, Id}) of
		undefined -> 0;
		Activity ->
		    case lists:keyfind(Type, 1, Activity) of
			false -> 1;
			{_,_,IsGet} -> IsGet
		    end
	    end,
    {reply, Reply, Status};

handle_call({get_mlpt_player}, _From, Status) ->
    Reply = case get({mlpt_player}) of
		undefined ->
		    SQL = io_lib:format(<<"select `name`,`value` from `rank_daily_flower` where `sex` = 2 and `value` >= 999 order by `value` desc limit 10">>,[]),
		    case db:get_all(SQL) of
			[] -> null;
			Row ->
			    MlptList = lists:foldl(fun(X, AccIn) ->
							   Num = length(AccIn) + 1,
							   [Name,Value] = X,
							   [{Num, Value, pt:write_string(Name)} | AccIn]
						   end, [], Row),
			    put({mlpt_player}, MlptList),
			    MlptList
		    end;
		R -> R
	    end,
    {reply, Reply, Status};

handle_call(Event, _From, Status) ->
    util:errlog("mod_qixi:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.
