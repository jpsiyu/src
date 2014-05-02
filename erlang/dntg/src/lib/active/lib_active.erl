%%%--------------------------------------
%%% @Module  : lib_active
%%% @Author  : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.7.4
%%% @Description: 活跃度
%%%--------------------------------------

-module(lib_active).
-include("server.hrl").
-include("active.hrl").
-export([
	online/1,
	reset_data/2,
	add_active/5,
	get_award_list/2,
	get_opt_list/1,
	reset_stat/3,
	handle_offline/2
]).

%% 重置活跃度数据
%% 返回：最新#active
reset_data(State, Today) ->
	case State#active.today < Today of
		true -> 
			db:execute(io_lib:format(?SQL_ACTIVE_UPDATE, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,'[]',Today,State#active.id])),
			State#active{
				today = Today,
				active = 0,
				award = [],
				opt = ?SET_ALL_ACTIVE_ID_0
			};
		_ ->
			State
	end.
	
%% 增加活跃度
add_active(State, Type, RequireScore, TriggerScore,VipType) ->
	%% 每次达到条件可增加的活跃度
	AddScore = data_active:get_active_by_opt(),
	NewTriggerScore = TriggerScore + AddScore,
	LimitUp = data_active:get_limit_up(),
	NewState = 
	case NewTriggerScore >= RequireScore of
		%% 达到触发的数量
		true ->
            %%VipType = lib_player:get_player_info(State#active.id,vip),
            Add1 = data_active:get_active_by_type(Type,VipType),
			[NewActive,NewAdd] = case State#active.active + AddScore > LimitUp of
				true -> [LimitUp,0];
				_ -> [State#active.active + AddScore,Add1]
			end,
			%% 活跃度次数，和活跃度入库
			Field = list_to_atom(lists:concat([active, Type])),
			db:execute(io_lib:format(?SQL_ACTIVE_UPDATE_ACTIVE2, [Field, Field, AddScore, NewActive, State#active.id])),
			
			%% 活跃度日志
			case lib_player:get_player_low_data(State#active.id) of
				[Nickname, _, Lv|_] ->
					log:log_active(State#active.id, Nickname, Lv, Type, NewActive);
				_ ->
					skip
			end,
            DailyPid = lib_player:get_player_info(State#active.id,dailypid),
            mod_daily:increment(DailyPid, State#active.id, 60000010),

			%% 通知客户端显示有新项触发
			{ok, Bin} = pt_314:write(31481, []),
			lib_server_send:send_to_uid(State#active.id, Bin),
            

		lib_qixi:update_player_task(State#active.id, 7, 10),

			%% 老玩家回归
			case NewActive =:= 100 of
				true ->
					lib_special_activity:add_old_buck_task(State#active.id, 5);
				_ ->
					skip
			end,
            db:execute(io_lib:format(?SQL_REPLACE_ROLE_ACTIVE, [State#active.id, State#active.allactive + NewAdd])),
			State#active{
				active = NewActive,
                allactive = State#active.allactive + NewAdd,
				opt = reset_stat(State#active.opt, Type, NewTriggerScore)
			};

		%% 计数的活跃度增加
		_ ->
			Field = list_to_atom(lists:concat([active, Type])),
			db:execute(io_lib:format(?SQL_ACTIVE_UPDATE_ACTIVE, [Field, Field, AddScore, State#active.id])),
			State#active{
				active = State#active.active,
				opt = reset_stat(State#active.opt, Type, NewTriggerScore)
			}
	end,
	NewState.

%% 获得奖励项列表数据
get_award_list(Lv, State) ->
	F = fun(PId) ->
		Step = data_active:get_step(Lv),
		GiftId = data_active:get_gift(Step, PId),
		case lists:member(PId, State#active.award) of
			true ->
				<<PId:8, 1:8, GiftId:32>>;
			_ ->
				<<PId:8, 0:8, GiftId:32>>
		end
	end,
	[F(Id) || Id <- data_active:get_award_ids()].

%% 获取操作项列表数据
get_opt_list(StatList) ->
	[_, Newlist, Active] = 
		lists:foldl(fun(Score, [OptNum, List, Active]) -> 
			LimitUp = data_active:require_opt_num(OptNum),
			GetCount = Score div 10,

			case GetCount >= LimitUp of
				true ->
					Active1 = Active + 1,
					GetCount1 = LimitUp;
				_ -> 
					Active1 = Active,
					GetCount1 = GetCount
			end,

			[OptNum + 1, [<<OptNum:16, GetCount1:16, LimitUp:16>> | List], Active1]
		end, [1, [], 0], StatList),
	[lists:reverse(Newlist), Active * data_active:get_active_by_opt()].

%% 更新统计的值
reset_stat(Stat, Type, Value) ->
	[_, List] = 
		lists:foldl(fun(Score, [Position, NewStat]) -> 
			case Position =:= Type of
				true ->
					[Position + 1, [Value | NewStat]];
				_ ->
					[Position + 1, [Score | NewStat]]
			end
		end, [1, []], Stat),
	lists:reverse(List).

%% 玩家登录时初始化
%% 返回：[当天0点时间戳, 当天活跃度, 当天所有活跃度项触发统计列表, 获得奖励统计列表]
online(RoleId) ->
	Today = util:unixdate(),
    AllActive =case db:get_row(io_lib:format(?SQL_GET_ROLE_ACTIVE, [RoleId])) of
        %% 第一次登录，插入初始记录
        [] ->
            %%db:execute(io_lib:format(?SQL_REPLACE_ROLE_ACTIVE, [RoleId, 0])),
            0;
        [_,AllActive1] ->
            AllActive1
    end,
	[TodayScore, TodayStat, TodayGetReward] = 
		case db:get_row(io_lib:format(?SQL_ACTIVE_GET_ROW, [RoleId])) of
			%% 第一次登录，插入初始记录
			[] ->
				db:execute(io_lib:format(?SQL_ACTIVE_INSERT, [RoleId, Today])),
				[0, ?SET_ALL_ACTIVE_ID_0, []];
			Row ->
				[_, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, Score, FieldStat, FieldToday] = Row,
				case FieldToday < Today of
					%% 如果今天第一次登录，则将数据初始化一次
					true ->
						db:execute(io_lib:format(?SQL_ACTIVE_RESET, [Today, RoleId])),
						[0, ?SET_ALL_ACTIVE_ID_0, []];
					_ ->
						[Score, [A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19], util:to_term(FieldStat)]
				end
		end,
	[Today, TodayScore, AllActive, TodayStat, TodayGetReward].

%% 离线处理
handle_offline(RoleId, Type) ->
	case lists:member(Type, data_active:get_opt_ids()) of
		true ->
			Field = lists:concat([active, Type]),
			case db:get_one(io_lib:format(?SQL_ACTIVE_GET_ROW2, [Field, RoleId])) of
				FieldValue when is_integer(FieldValue) ->
					Value = data_active:add_active_by_opt(),
					db:execute(io_lib:format(?SQL_ACTIVE_UPDATE_ACTIVE, [Field, Field, Value]));
				_ ->
					skip
			end;
		_ ->
			skip
	end.

