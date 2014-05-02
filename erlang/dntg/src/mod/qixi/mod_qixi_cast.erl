%%%-------------------------------------------------------------------
%%% @Module	: mod_qixi_cast
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 25 Oct 2012
%%% @Description: 
%%%-------------------------------------------------------------------
-module(mod_qixi_cast).
-export([handle_cast/2]).
-include("qixi.hrl").
handle_cast({insert_player_task, Id, Activity}, Status) ->
    put({player_task, Id}, Activity),
    {noreply, Status};

handle_cast({update_player_task, Id, Type, Num}, Status) ->
    %% Activity = [{类型,当前次数,是否已领}...]
    Activity = case get({player_task, Id}) of
		   undefined ->
		       case mod_qixi:load_from_db(Id) of
			   null -> data_qixi:init_activity_task();
			   A -> A
		       end;
		   A -> A
	       end,
    Val = lists:map(fun({TaskType, CurrentNum, IsGet}) ->
			    case Type =:= TaskType of
				true -> {TaskType, CurrentNum + Num, IsGet};
				false -> {TaskType, CurrentNum, IsGet}
			    end
		    end, Activity),
    catch mod_qixi:save_to_db(Id, Val),
    put({player_task, Id}, Val),
    Data = lib_qixi:pack_list(Val),
    case lib_player:get_player_info(Id, dailypid) of
	false -> [];
	DailyPid ->
	    TaskNum = lib_qixi:filter_task_award_num(Data),
	    mod_daily:set_count(DailyPid, Id, 7710, TaskNum),
	    TotalNum = TaskNum + mod_daily:get_count(DailyPid, Id, 7711),
	    {ok, Bin27708} = pt_277:write(27708, [TotalNum]),
	    lib_server_send:send_to_uid(Id, Bin27708)
    end,
    {ok, Bin27700} = pt_277:write(27700, [Data]),
    lib_server_send:send_to_uid(Id, Bin27700),
    {noreply, Status};

handle_cast({update_player_task_batch, Id, TypeList, Num}, Status) ->
    Activity = case get({player_task, Id}) of
		   undefined ->
		       case mod_qixi:load_from_db(Id) of
			   null -> data_qixi:init_activity_task();
			   A -> A
		       end;
		   A -> A
	       end,
    Val =  lists:map(fun({TaskType, CurrentNum, IsGet}) ->
			     case lists:member(TaskType, TypeList) of
				 true -> {TaskType, CurrentNum + Num, IsGet};
				 false -> {TaskType, CurrentNum, IsGet}
			     end
		     end, Activity),
    catch mod_qixi:save_to_db(Id, Val),
    put({player_task, Id}, Val),
    Data = lib_qixi:pack_list(Val),
    case lib_player:get_player_info(Id, dailypid) of
	false -> [];
	DailyPid ->
	    TaskNum = lib_qixi:filter_task_award_num(Data),
	    mod_daily:set_count(DailyPid, Id, 7710, TaskNum),
	    TotalNum = TaskNum + mod_daily:get_count(DailyPid, Id, 7711),
	    {ok, Bin27708} = pt_277:write(27708, [TotalNum]),
	    lib_server_send:send_to_uid(Id, Bin27708)
    end,
    {ok, Bin27700} = pt_277:write(27700, [Data]),
    lib_server_send:send_to_uid(Id, Bin27700),
    {noreply, Status};

handle_cast({update_player_task_from_login, Id, Type, Num}, Status) ->
    Activity = case get({player_task, Id}) of
		   undefined ->
		       case mod_qixi:load_from_db(Id) of
			   null -> data_qixi:init_activity_task();
			   A -> A
		       end;
		   A -> A
	       end,
    Val = case lists:keyfind(Type, 1, Activity) of
	       false -> Activity;
	       {Type, CurrentNum, IsGet} -> lists:keyreplace(Type, 1, Activity, {Type, CurrentNum + Num, IsGet})
	   end,
    put({player_task, Id}, Val),
    Data = lib_qixi:pack_list(Val),
    {ok, Bin27700} = pt_277:write(27700, [Data]),
    lib_server_send:send_to_uid(Id, Bin27700),
    {noreply, Status};



handle_cast({update_get_by_type, Id, Type, DailyPid}, Status) ->
    A = case get({player_task, Id}) of
	    undefined ->
		skip;
	    _Activity ->
		case lists:keyfind(Type, 1, _Activity) of
		    false -> skip;
		    {Type, CurrentNum, IsGet} ->
			case IsGet =:= 1 of
			    false -> lists:keyreplace(Type, 1, _Activity, {Type, CurrentNum, 1});
			    true -> skip
			end
		end
	end,
    case A of
	skip -> skip;
	Activity ->
	    put({player_task, Id}, Activity),
	    catch mod_qixi:save_to_db(Id, Activity),
	    mod_daily:decrement(DailyPid, Id, 7710),
	    TotalNum = case mod_daily:get_count(DailyPid, Id, 7710) of
			   Count1 when Count1 < 0 -> mod_daily:get_count(DailyPid, Id, 7711);
			   Count2 -> Count2 + mod_daily:get_count(DailyPid, Id, 7711)
		       end,
	    {ok, Bin} = pt_277:write(27708, [TotalNum]),
	    lib_server_send:send_to_uid(Id, Bin)
    end,
    {noreply, Status};

handle_cast({reset_player_task}, Status) ->
    erase(),
    db:execute(io_lib:format(<<"truncate table qixi_activity">>,[])),
    case util:unixdate() > data_qixi:get_end_day() of
	true ->
	    case data_qixi:is_special_time(12) of 
		false -> db:execute(io_lib:format(<<"truncate table login_continuation">>,[]));
		true -> []
	    end;
	false -> []
    end,
    {noreply, Status};
handle_cast({on_time_refresh}, Status) ->
    case lib_rank_helper:get_flower_rank_name_and_value(2, 999, 10) of
	[] -> null;
	Row ->
    %% SQL = io_lib:format(<<"select `name`,`value` from `rank_daily_flower` where `sex` = 2 and `value` >= 999 order by `value` desc limit 10">>,[]),
    %% case db:get_all(SQL) of
    %% 	[] -> null;
    %% 	Row ->
	    MlptList = lists:foldl(fun(X, AccIn) ->
					   Num = length(AccIn) + 1,
					   [Name,Value] = X,
					   [{Num, Value, pt:write_string(Name)} | AccIn]
				   end, [], Row),
	    put({mlpt_player}, MlptList)
    end,
    {noreply, Status};
handle_cast(Msg, Status) ->
    util:errlog("mod_qixi:handle_cast not match: ~p", [Msg]),
    {noreply, Status}.
