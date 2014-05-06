-module(money_rank).
-compile(export_all).

-define(RANK, money_rank).

-record(money_log, {id, name, total_coin, time}).

%% insert a record into money_rank proc dict
%% create a new one if the proc dict undefine
%% expend new record into record list if proc dict existed
insert(Id, Name, Coin) ->
	List = get(?RANK),
	case List of
		%% empty proc dict
		undefined ->
			NewList = [#money_log{id = Id, name = Name, total_coin = Coin, time = calendar:local_time()}],
			put(?RANK, NewList);
		List ->
			%% if id existed
			case lists:keyfind(Id, 2, List) of
				false ->
					NewList = [#money_log{id = Id, name = Name, total_coin = Coin, time = calendar:local_time()}] ++ List,
					put(?RANK, NewList);
				Record ->
					%% update total_coin	
					TotalCoin = Record#money_log.total_coin + Coin,
					NewRecord = Record#money_log{total_coin = TotalCoin, time = calendar:local_time()},
					NewList = lists:keyreplace(Id, 2, List, NewRecord),
					put(?RANK, NewList)
			end
	end.

return_top() ->
	List = get(?RANK),
	case List of
		undefined ->
			[];
		List ->
			%% if dict existed more than one day, clear	
			[One | _T] = List, 
			{Day, _} = One#money_log.time,
			case if_day_pass(Day) of
				true ->
					erase(?RANK),
					[];
				false ->
					SortList = lists:sort(fun(A, B) ->
							if
								A#money_log.total_coin > B#money_log.total_coin ->
									true;
								A#money_log.total_coin =:= B#money_log.total_coin ->
								 	if 
										A#money_log.time < B#money_log.time ->
										 	true;
										true ->
											false
									end;
								true ->
									false
							end
					end, List),
				ListTop5 = lists:sublist(SortList, 1, 5),
				ListTop5
			end
	end.

if_day_pass(Day) ->
	{Now, _} = calendar:local_time(),
	case calendar:date_to_gregorian_days(Now) - calendar:date_to_gregorian_days(Day) of
		0 ->
			false;
		_ ->
			true
	end.
