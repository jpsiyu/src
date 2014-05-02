%%%--------------------------------------
%%% @Module  : mod_active_cast
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.11.21
%%% @Description :  活跃度
%%%--------------------------------------

-module(mod_active_cast).
-include("server.hrl").
-include("active.hrl").
-export([handle_cast/2]).

handle_cast({check_finish, Type, Num}, State) ->
	case lists:member(Type, data_active:get_opt_ids()) of
		true ->
			Today = util:unixdate(),
			NewState = lib_active:reset_data(State, Today),
			AddScore = data_active:get_active_by_opt(),
			RequireScore = data_active:require_opt_num(Type) * AddScore,
			LimitUp = data_active:get_limit_up(),
			TriggerScore = Num * AddScore,

			OldScore = lists:nth(Type, State#active.opt),
			case OldScore >= RequireScore of
				true ->
					{noreply, State};
				_ ->
					case TriggerScore >= RequireScore of
						true ->
                            VipType = lib_player:get_player_info(State#active.id,vip),
                            Add1 = data_active:get_active_by_type(Type,VipType),
							[NewActive,NewAdd] = case State#active.active + AddScore >= LimitUp of
								true -> [LimitUp,0];
								_ -> [State#active.active + AddScore,Add1]
							end,

							%% 活跃度次数，和活跃度入库
							Field = list_to_atom(lists:concat([active, Type])),
							db:execute(io_lib:format(?SQL_ACTIVE_UPDATE_ACTIVE4, [Field, RequireScore, State#active.id])),

                            
                            db:execute(io_lib:format(?SQL_REPLACE_ROLE_ACTIVE, [NewState#active.id, NewState#active.allactive + NewAdd])),
                            DailyPid = lib_player:get_player_info(State#active.id,dailypid),
                            mod_daily:increment(DailyPid, State#active.id, 60000010),
							%% 通知客户端显示有新项触发
							{ok, Bin} = pt_314:write(31481, []),
							lib_server_send:send_to_uid(State#active.id, Bin),
                            


							%% 活跃度日志
							case lib_player:get_player_low_data(State#active.id) of
								[Nickname, _, Lv|_] ->
									log:log_active(State#active.id, Nickname, Lv, Type, NewActive);
								_ ->
									skip
							end,

							lib_qixi:update_player_task(State#active.id, 7, 10),

							NewState2 = NewState#active{
								active = NewActive,
                                allactive = NewState#active.allactive + NewAdd,
								opt = lib_active:reset_stat(State#active.opt, Type, RequireScore)	   
							},
							{noreply, NewState2};
						_ ->
							{noreply, State}
					end
			end;
		_ ->
			{noreply, State}
	end;

handle_cast({trigger, Type, TargetId, VipType}, State) ->
	case lists:member(Type, data_active:get_opt_ids()) of
		true ->
			Today = util:unixdate(),
			NewState = lib_active:reset_data(State, Today),
			RequireScore = data_active:require_opt_num(Type) * data_active:get_active_by_opt(),
			TriggerScore = lists:nth(Type, NewState#active.opt),
			case TriggerScore < RequireScore of
				%% 还未达到触发条件
				true ->
					case data_active:in_target_list(Type) of
						%% 不用指定TargetId
						[] ->
							{noreply, lib_active:add_active(NewState, Type, RequireScore, TriggerScore, VipType)};
						TargetList ->
							case lists:member(TargetId, TargetList) of
								true ->
									{noreply, lib_active:add_active(NewState, Type, RequireScore, TriggerScore, VipType)};
								_ ->
									{noreply, NewState}
							end
					end;
				_ ->
					{noreply, NewState}
			end;
		_ ->
			{noreply, State}
	end;

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_active_cast:handle_cast not match: ~p", [Event]),
    {noreply, Status}.
