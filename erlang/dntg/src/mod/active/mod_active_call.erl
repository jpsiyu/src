%%%--------------------------------------
%%% @Module  : mod_active_call
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.11.21
%%% @Description :  活跃度
%%%--------------------------------------

-module(mod_active_call).
-include("server.hrl").
-include("active.hrl").
-export([handle_call/3]).

handle_call({get_my_active}, _FROM, State) ->
	Today = util:unixdate(),
	NewState = lib_active:reset_data(State, Today),
    {reply, NewState#active.active, NewState};

handle_call({get_my_allactive}, _FROM, State) ->
    Today = util:unixdate(),
    NewState = lib_active:reset_data(State, Today),
    {reply, NewState#active.allactive, NewState};

handle_call({fetch_award, PS}, _FROM, State) ->
    Today = util:unixdate(),

	Result = 
	case State#active.today >= Today of
		true ->
			F = fun(Id, GetList) ->
				NeedActive = data_active:get_award_score_by_id(Id),
				case lists:member(Id, State#active.award) =:= false andalso State#active.active >= NeedActive of
					true ->
						GetList ++ [Id];
					_ ->
						GetList
				end
			end,
			GetAwardList = lists:foldl(F, [], data_active:get_award_ids()),

			case length(GetAwardList) > 0 of
				true ->
					TargetId = lists:nth(1, GetAwardList),
					Step = data_active:get_step(PS#player_status.lv),
					GiftId = data_active:get_gift(Step, TargetId),
					[_, Exp] = data_active:get_award_config(TargetId, PS#player_status.lv),
					_LastGiftIds = data_active:get_last_gift_ids(),

					case GiftId > 0 of
						true ->
							G = PS#player_status.goods,
							case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
								{ok, [ok, NewPS2]} ->
									%% 增加经验
									NewPS3 = lib_player:add_exp(NewPS2, Exp, 0),

									%% 奖励入库
									UpdateStat = State#active.award ++ [TargetId],
									UpdateStat2 = util:term_to_string(UpdateStat),
									db:execute(io_lib:format(?SQL_ACTIVE_UPDATE_ACTIVE3, [UpdateStat2, PS#player_status.id])),

									%% 最后一个礼包需要发传闻
                                    %case lists:member(GiftId, LastGiftIds) of
                                    case  State#active.active >= 60 of
										true ->
											%% 运势任务(3700008:活跃分子)
											lib_fortune:fortune_daily(PS#player_status.id, 3700008, 1),

											lib_chat:send_TV(
												{all}, 0, 2,
												["huoyuedu", PS#player_status.id, PS#player_status.realm, 
												 PS#player_status.nickname, PS#player_status.sex, PS#player_status.career, 0]
											);
										_ -> 
										    skip
									end,

									NewState = State#active{
										award = UpdateStat
									},

									{ok, NewPS3, [TargetId], NewState};
								{ok, [error, ErrorCode]} ->
									{error, ErrorCode, State};
								_ ->
									{error, 999, State}
							end;
						_ ->
							{error, 3, State}
					end;
				_ ->
					{error, 2, State}
			end;
		_ ->
			{error, 2, lib_active:reset_data(State, Today)}
	end,
	[ReturnData, SaveState] = 
	case Result of
		{error, Error, LastState} ->
			[{error, Error}, LastState];
		{ok, NewPS, Data, LastState} ->
			[{ok, NewPS, Data}, LastState]
	end,
    {reply, ReturnData, SaveState};

handle_call({get_info, PS}, _FROM, State) ->
	Today = util:unixdate(),
	NewState = lib_active:reset_data(State, Today),

	%% 修复活跃度错误
	[OptList, TrueActive] = lib_active:get_opt_list(NewState#active.opt),
	%% 修复错误
	NewState2 = 
	case NewState#active.active < TrueActive of
		true ->
			db:execute(
				io_lib:format(?SQL_ACTIVE_UPDATE_ACTIVE5, [TrueActive, NewState#active.id]) 
			),
			NewState#active{
				active = TrueActive
			};
		_ ->
			NewState
	end,
	Result = [
		NewState2#active.allactive,
		data_active:get_limit_up(),
	 	OptList,
		lib_active:get_award_list(PS#player_status.lv, NewState2)
	],
    {reply, Result, NewState2};

%%消费活跃度
handle_call({cost, ActiveCount}, _FROM, State) ->
    if ActiveCount < 0 ->
           Res = {error,2},
           NewState = State;
        ActiveCount > State#active.allactive ->
            Res = {error,3},
            NewState = State;
        true -> 
            NewState=State#active{
                allactive = State#active.allactive - ActiveCount
            },
            Res = {ok,{State#active.allactive,NewState#active.allactive}},
            db:execute(io_lib:format(?SQL_REPLACE_ROLE_ACTIVE, [NewState#active.id, NewState#active.allactive]))
    end,
    {reply,Res,NewState};
            

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_active_call:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.
