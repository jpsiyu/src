%%%-------------------------------------------------------------------
%%% @Module	: data_qixi
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 21 Aug 2012
%%% @Description: 
%%%-------------------------------------------------------------------
-module(data_qixi).
-compile(export_all).

get_start_day() ->
    %% util:unixtime({{2012, 10, 23},{0, 0, 0}}).
    get_start_day(9).

get_end_day() ->
    %% util:unixtime({{2012, 10, 26},{0, 0, 0}}).
    get_end_day(9).

get_start_day(Type) ->
    [Start, _End] = case data_activity_time:get_time_by_type(Type) of
			[] -> [util:unixdate()+1, util:unixdate()];
			Any -> Any
		    end,
    Start.

get_end_day(Type) ->
    [_Start, End] = case data_activity_time:get_time_by_type(Type) of
			[] -> [util:unixdate()+1, util:unixdate()];
			Any -> Any
		    end,
    End.

is_qixi_time() ->
    Now = util:unixtime(),
    Begin = get_start_day(),
    End = get_end_day(),
    Now >= Begin andalso Now =< End.

is_special_time(Type) ->
    case data_activity_time:get_time_by_type(Type) of
	[] -> false;
	[Begin,End] ->
	    Now = util:unixtime(),
	    Now >= Begin andalso Now =< End
    end.

get_gift_id() ->
    %% {{礼包顺序，礼包ID,判断条件}，mod_daily的类型, 礼包ID}
    L = data_qixi_config:get_gift_id_and_condition(),
    {GiftIdList, _} = lists:mapfoldl(fun(X, AccIn) ->
					     {DailyTypeInit, GiftNumInit} = AccIn,
					     {_, GiftId, _} = X,
					     {{X, DailyTypeInit+1, GiftId}, {DailyTypeInit+1, GiftNumInit+1}}
				     end, {7720, 0}, L),
    GiftIdList.

get_special_gift_list() ->
    [{1,534193,1,0},{2,534193,1,0},{3,534193,1,0},{4,534193,1,0},{5,534193,1,0},{6,534193,1,0},{7,534193,1,0},{8,534193,1,0},{9,534194,1,0},{10,534195,1,1},{11,534196,1,0},{12,534196,1,0},{13,534196,1,0},{14,534196,1,0},{15,534196,1,0}]. %{天数, GiftId, 数量, 是否按登录天数发}

get_special_gift_id(StartDay, LoginDays) ->
    GiftList = get_special_gift_list(),
    Now = util:unixtime(),
    DiffDays = util:get_diff_days(Now, StartDay),
    case lists:keyfind(DiffDays, 1, GiftList) of
	false -> false;
	{Day,GiftId,Num,Condition} ->
	    case Condition =:= 1 of
		true -> {Day,GiftId,Num*LoginDays,Condition};
		false -> {Day,GiftId,Num,Condition}
	    end
    end.
%% @param: Nth第N天应领礼包序号
get_special_gift_num_with_condition(Nth) ->
    case lists:keyfind(Nth, 1, get_special_gift_list()) of
	false -> 0;
	{_,_,Num,_} -> Num
    end.

get_init_special_gift_id_list(StartDay, LoginDays) ->
    GiftList = get_special_gift_list(),
    DiffDays = util:get_diff_days(util:unixtime(), StartDay),
    lists:map(fun({Day,GiftId,Num,Condition}) ->
		      case Condition =:= 1 of
			  true ->
			      if
				  DiffDays =:= Day -> {Day,GiftId,Num*LoginDays,Condition,1};
				  DiffDays < Day -> {Day,GiftId,Num*LoginDays,Condition,0};
				  true -> {Day,GiftId,Num*LoginDays,Condition,3}
			      end;
			  false ->
			      if
				  DiffDays =:= Day -> {Day,GiftId,Num,Condition,1};
				  DiffDays < Day -> {Day,GiftId,Num,Condition,0};
				  true -> {Day,GiftId,Num,Condition,3}
			      end
		      end
	      end, GiftList). %{天数, GiftId, 数量, 是否按登录天数发, 领取状态}

get_init_special_gift_id_list(StartDay, LoginDays, GiftList) ->
    DiffDays = util:get_diff_days(util:unixtime(), StartDay),
    lists:map(fun({Day,GiftId,Num,Condition,State}) ->
		      case State =:= 0 orelse State =:= 1 of 
			  true ->
			      case Condition =:= 1 of
				  true ->
				      if
					  DiffDays =:= Day -> {Day,GiftId,get_special_gift_num_with_condition(Day)*LoginDays,Condition,1};
					  DiffDays < Day -> {Day,GiftId,get_special_gift_num_with_condition(Day)*LoginDays,Condition,State};
					  true -> {Day,GiftId,get_special_gift_num_with_condition(Day)*LoginDays,Condition,3}
				      end;
				  false ->
				      if
					  DiffDays =:= Day -> {Day,GiftId,Num,Condition,1};
					  DiffDays < Day -> {Day,GiftId,Num,Condition,State};
					  true -> {Day,GiftId,Num,Condition,3}
				      end
			      end;
			  _ ->
			      {Day,GiftId,Num,Condition,State}
		      end
	      end, GiftList).
			      
		      
init_activity_task() ->
    L = data_qixi_config:get_task_config(),
    lists:map(fun({Type,_,_,_}) -> {Type, 0, 0} end, L).
		      

