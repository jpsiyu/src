%%%--------------------------------------
%%% @Module  : lib_activity
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.6.25
%%% @Description: 运营活动 
%%%--------------------------------------

-module(lib_activity).
-include("activity.hrl").
-include("recharge.hrl").
-include("gift.hrl").
-include("server.hrl").
-export([
	collect_game_award/1,
	is_get_collect_award/1,
	get_level_forward_data/1,
	fetch_level_forward_award/1,
	get_finish_stat/2,
	finish_activity/2,
	get_recharge_activity_data/1,
	fetch_recharge_activity_gift/2,
	send_first_charge_cw/2,
	is_recharge_valid_time/0,
	get_seven_day_login_data/1,
	get_seven_day_login_gift/2,
	is_pay_task_time/0,
	pay_task_do_recharge/1,
	fetch_active_gift/2,
	get_activity_show_stat/2,
	get_common_award/2,
	finish_pay_task/2,
	fetch_first_recharge_weapon/3,
	seven_day_signup/1,
	get_back_activity_stat/2,
	get_back_activity_award/1,
	process_activity_login/1,
	back_activity_charge_award/2,
	is_show_icon/2,
	get_recharge_award_data/1,
	get_recharge_award_data_tmp/1,
	fetch_recharge_award_gift/2,
	fetch_recharge_award_gift_tmp/2,
	get_kf5_gift_num/1,
	get_one_kf5_gigt/2,
	get_one_kf5_gigt_db/3,
	consume_returngold_login/1,
	fetch_consume_returngold_data/1,
	gain_consume_returngold/2,
	add_consumption/3,
	add_consumption2/3,
	adjuest_expenditure_for_houtai/3,
	adjuest_expenditure/3,
	count_31490/1
]).

%% 获得各种活动图标出现的标识
get_activity_show_stat(PS, Type) ->
	Key = lists:concat([lib_activity_show_stat_, Type]),
	case mod_daily:get_special_info(PS#player_status.dailypid, Key) of
		undefined ->
			List = db:get_all(io_lib:format(?sql_activity_fetch_all2, [PS#player_status.id])),
			mod_daily:set_special_info(PS#player_status.dailypid, Key, List),
			private_get_stat_by_type(List, Type);
		Data ->
			private_get_stat_by_type(Data, Type)
	end.

%% 是否显示图标
%% 返回：[1不出现图标0出现, 出现等级（可返回0）]
is_show_icon(_PS, Type) ->
	NowTime = util:unixtime(),
	if
		%% 充值送礼活动图标
		Type =:= 109 -> 
			[Start, End] = data_recharge_award:get_recharge_award_time(),
			OpenDay = util:get_open_day(),
			case OpenDay >= data_recharge_award:get_day() andalso Start =< NowTime andalso NowTime < End of
				true -> [0, 0];
				_ -> [1, 0]
			end;

		%% 临时，春节版，充值送礼活动图标
%% 		Type =:= 116 -> 
%% 			[Start, End] = data_recharge_award_tmp:get_recharge_award_time(),
%% 			OpenDay = util:get_open_day(),
%% 			case OpenDay >= data_recharge_award_tmp:get_day() andalso Start =< NowTime andalso NowTime < End of
%% 				true -> [0, 0];
%% 				_ -> [1, 0]
%% 			end;

		true ->
			[1, 0]
	end.

%% [充值送礼] 打开面板
get_recharge_award_data(PS) ->
	NowTime = util:unixtime(),
	[Start, End] = data_recharge_award:get_recharge_award_time(),
	[TrueStart, TrueEnd] = 
	case NowTime > End orelse NowTime < Start of
		true ->
			[0, 0];
		_ ->
			%% 暂时先忽略合服情况
			ActionDay = util:get_open_day(),
			ActionTime = util:get_open_time(),
			NeedDay = data_recharge_award:get_day(),
			private_get_recharge_award_time(ActionDay, ActionTime, NeedDay, Start, End)

%%			case PS#player_status.mergetime of
%%				0 ->
%%					ActionDay = util:get_open_day(),
%%					ActionTime = util:get_open_time(),
%%					NeedDay = data_recharge_award:get_day(),
%%					private_get_recharge_award_time(ActionDay, ActionTime, NeedDay, Start, End);
%%				_ ->
%%					ActionDay = lib_activity_merge:get_merge_day(),
%%					ActionTime = PS#player_status.mergetime,
%%					NeedDay = data_merge:get_recharge_day(),
%%					private_get_recharge_award_time(ActionDay, ActionTime, NeedDay, Start, End)
%%			end
	end,

	case [TrueStart, TrueEnd] of
		[0, 0] ->
			[0, [], 0, 0, 0, 0, 0];
		_ ->
			GiftList = case db:get_row(io_lib:format(?sql_activity_data_get, [PS#player_status.id, ?ACTIVITY_FINISH_RECHARGE_AWARD])) of
				[DataField, AddTime] ->
					case AddTime < TrueStart of
						true ->
							db:execute(io_lib:format(?sql_activity_data_update, ['[]', NowTime, PS#player_status.id, ?ACTIVITY_FINISH_RECHARGE_AWARD])),
							[];
						_ ->
							Data = util:to_term(DataField),
							Data
					end;
				_ ->
					db:execute(io_lib:format(?sql_activity_data_insert, [PS#player_status.id, ?ACTIVITY_FINISH_RECHARGE_AWARD, '[]', NowTime])),
					[]
			end,

			Recharge1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, TrueStart, TrueEnd),
			Recharge2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, TrueStart, TrueEnd),
			Recharge = Recharge1 + Recharge2,

			ConfigList = lists:sort(fun([Gold1, _], [Gold2, _]) -> 
				Gold2 > Gold1
			end, data_recharge_award:get_recharge_award_gift()),
			List = 
			lists:map(fun([NeedGold, GiftId]) -> 
				case lists:member(GiftId, GiftList) of
					true ->
						<<GiftId:32, 1:8, NeedGold:32>>;
					_ ->
						<<GiftId:32, 0:8, NeedGold:32>>
				end
			end, ConfigList),
			LeftTime = case TrueEnd - NowTime < 0 of
				true -> 0;
				_ -> TrueEnd - NowTime
			end, 
			[ReYbLimit,ReGiftId,ReSignTime] = data_recharge_award:get_recharge_award_regift(),
%% 			[ReYbLimit,ReGiftId,ReSignTime] = get_recharge_award_regift(),
			ReNumNow = Recharge div ReYbLimit,
			ReYbNeed = ReYbLimit - Recharge rem ReYbLimit,
			TrueReNum = case db:get_row(io_lib:format(?sql_activity_data_get, [PS#player_status.id, ?ACTIVITY_RECHARGE_RE])) of
				[DataRe, _AddTimeRe] ->
					DataL = util:to_term(DataRe),
					case DataL of
						[Num, ActTime] ->
							case ActTime =:= ReSignTime of
								true ->
									case Num >= ReNumNow of
										true ->
											ReNumNow;
										false ->
											Num
									end;
								false ->
									0
							end;
						_ ->
							0
					end;
				_ ->
					0
			end,
			[Recharge, List, LeftTime, ReGiftId, ReNumNow, TrueReNum, ReYbNeed]
	end.

%% 临时，春节版 [充值送礼] 打开面板
get_recharge_award_data_tmp(PS) ->
	NowTime = util:unixtime(),
	[Start, End] = data_recharge_award_tmp:get_recharge_award_time(),
	[TrueStart, TrueEnd] = 
	case NowTime > End orelse NowTime < Start of
		true ->
			[0, 0];
		_ ->
			case PS#player_status.mergetime of
				0 ->
					ActionDay = util:get_open_day(),
					ActionTime = util:get_open_time(),
					NeedDay = data_recharge_award_tmp:get_day(),
					private_get_recharge_award_time(ActionDay, ActionTime, NeedDay, Start, End);
				_ ->
					ActionDay = lib_activity_merge:get_merge_day(),
					ActionTime = PS#player_status.mergetime,
					NeedDay = data_merge:get_recharge_day(),
					private_get_recharge_award_time(ActionDay, ActionTime, NeedDay, Start, End)
			end
	end,

	case [TrueStart, TrueEnd] of
		[0, 0] ->
			[0, [], 0, 0, 0, 0, 0];
		_ ->
			GiftList = case db:get_row(io_lib:format(?sql_activity_data_get, [PS#player_status.id, ?ACTIVITY_FINISH_RECHARGE_AWARD_TMP])) of
				[DataField, AddTime] ->
					case AddTime < TrueStart of
						true ->
							db:execute(io_lib:format(?sql_activity_data_update, ['[]', NowTime, PS#player_status.id, ?ACTIVITY_FINISH_RECHARGE_AWARD_TMP])),
							[];
						_ ->
							Data = util:to_term(DataField),
							Data
					end;
				_ ->
					db:execute(io_lib:format(?sql_activity_data_insert, [PS#player_status.id, ?ACTIVITY_FINISH_RECHARGE_AWARD_TMP, '[]', NowTime])),
					[]
			end,

			Recharge1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, TrueStart, TrueEnd),
			Recharge2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, TrueStart, TrueEnd),
			Recharge = Recharge1 + Recharge2,

			ConfigList = lists:sort(fun([Gold1, _], [Gold2, _]) -> 
				Gold2 > Gold1
			end, data_recharge_award_tmp:get_recharge_award_gift()),
			List = 
			lists:map(fun([NeedGold, GiftId]) -> 
				case lists:member(GiftId, GiftList) of
					true ->
						<<GiftId:32, 1:8, NeedGold:32>>;
					_ ->
						<<GiftId:32, 0:8, NeedGold:32>>
				end
			end, ConfigList),
			LeftTime = case TrueEnd - NowTime < 0 of
				true -> 0;
				_ -> TrueEnd - NowTime
			end,
			[ReYbLimit,ReGiftId,ReSignTime] = data_recharge_award_tmp:get_recharge_award_regift(),
			ReNumNow = Recharge div ReYbLimit,
			ReYbNeed = ReYbLimit - Recharge rem ReYbLimit,
			TrueReNum = case db:get_row(io_lib:format(?sql_activity_data_get, [PS#player_status.id, ?ACTIVITY_RECHARGE_RE])) of
				[DataRe, _AddTimeRe] ->
					DataL = util:to_term(DataRe),
					case DataL of
						[Num, ActTime] ->
							case ActTime =:= ReSignTime of
								true ->
									case Num >= ReNumNow of
										true ->
											ReNumNow;
										false ->
											Num
									end;
								false ->
									0
							end;
						_ ->
							0
					end;
				_ ->
					0
			end,
			[Recharge, List, LeftTime, ReGiftId, ReNumNow, TrueReNum, ReYbNeed]
	end.

%% 领取充值送礼奖励礼包
fetch_recharge_award_gift(PS, GiftId) ->
	[Start, End] = data_recharge_award:get_recharge_award_time(),
	NowTime = util:unixtime(),
	[TrueStart, TrueEnd] = 
	case NowTime > End orelse NowTime < Start of
		true ->
			[0, 0];
		_ ->
			%% 暂时忽略合服情况
			ActionDay = util:get_open_day(),
			ActionTime = util:get_open_time(),
			NeedDay = data_recharge_award:get_day(),
			private_get_recharge_award_time(ActionDay, ActionTime, NeedDay, Start, End)

%%			case PS#player_status.mergetime of
%%				0 ->
%%					ActionDay = util:get_open_day(),
%%					ActionTime = util:get_open_time(),
%%					NeedDay = data_recharge_award:get_day(),
%%					private_get_recharge_award_time(ActionDay, ActionTime, NeedDay, Start, End);
%%				_ ->
%%					ActionDay = lib_activity_merge:get_merge_day(),
%%					ActionTime = PS#player_status.mergetime,
%%					NeedDay = data_merge:get_recharge_day(),
%%					private_get_recharge_award_time(ActionDay, ActionTime, NeedDay, Start, End)
%%			end
	end,
	case [TrueStart, TrueEnd] of
		[0, 0] ->
			{error, 999};
		_ -> 
			G = PS#player_status.goods,
			[ReYbLimit, ReGiftId, ReSignTime] = data_recharge_award:get_recharge_award_regift(),
%% 			[ReYbLimit, ReGiftId, ReSignTime] = get_recharge_award_regift(),
			case ReGiftId =:= GiftId of
				true ->
					%% 领取的是可重复的奖励
					%% 获取本阶段的领取数量
					TrueReNum = case db:get_row(io_lib:format(?sql_activity_data_get, [PS#player_status.id, ?ACTIVITY_RECHARGE_RE])) of
						[DataField, _AddTimeRe] ->
							DataL = util:to_term(DataField),
							case DataL of
								[Num, ActTime] ->
									case ActTime =:= ReSignTime of
										true ->
											Num;
										false ->
											0
									end;
								_ ->
									0
							end;
						[] ->
							0;
						_ ->
							error
					end,
					case TrueReNum =:= error of
						true ->
							{error, 999};
						false ->
							%% 计算充值数额
							Recharge1Re = lib_recharge_ds:get_pay_task_total(PS#player_status.id, TrueStart, TrueEnd),
							Recharge2Re = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, TrueStart, TrueEnd),
							RechargeRe = Recharge1Re + Recharge2Re,
							%% 计算可以领取的数量
							ReNumNow = RechargeRe div ReYbLimit,
%% 							io:format("TrueReNum ReNumNow ~p ~p ~n", [TrueReNum, ReNumNow]),
							case TrueReNum >= ReNumNow of
								true -> %% 领取完成
									{error, 2};
								false ->%% 还可以领取
									case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
										{ok, [ok, NewPS]} ->
											ReInfo = util:term_to_string([TrueReNum + 1, ReSignTime]),
											db:execute(io_lib:format(?sql_activity_data_insert, [PS#player_status.id, ?ACTIVITY_RECHARGE_RE, ReInfo, NowTime])),
%% 											db:execute(io_lib:format(?sql_activity_data_insert, [ReInfo, NowTime, PS#player_status.id, ?ACTIVITY_RECHARGE_RE])),
											{ok, NewPS};
										{ok, [error, ErrorCode]} ->
											{error, ErrorCode};
										_ ->
											{error, 999}
									end
							end
					end;
				_ ->
					case db:get_row(io_lib:format(?sql_activity_data_get, [PS#player_status.id, ?ACTIVITY_FINISH_RECHARGE_AWARD])) of
						[Data, AddTime] ->
							case AddTime < TrueStart of
								true ->
									{error, 103};
								_ ->
									Recharge1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, TrueStart, TrueEnd),
									Recharge2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, TrueStart, TrueEnd),
									Recharge = Recharge1 + Recharge2,
		
									GiftList = util:to_term(Data),
									Result = lists:filter(fun([_, NeedGiftId]) -> 
										NeedGiftId =:= GiftId andalso lists:member(GiftId, GiftList) =:= false
									end, data_recharge_award:get_recharge_award_gift()),
		
									case Result of
										[[NeedGold, GiftId]] ->
											case Recharge >= NeedGold of
												true ->
													case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
														{ok, [ok, NewPS]} ->
															NewGiftList2 = util:term_to_string([GiftId | GiftList]),
															db:execute(io_lib:format(?sql_activity_data_update, [NewGiftList2, NowTime, PS#player_status.id, ?ACTIVITY_FINISH_RECHARGE_AWARD])),
															{ok, NewPS};
														{ok, [error, ErrorCode]} ->
															{error, ErrorCode};
														_ ->
															{error, 999}
													end;
												_ ->
													{error, 3}
											end;
										_ ->
											{error, 2}
									end
							end;
						_ ->
							{error, 999}
					end
			end
	end.

%% 临时，春节版，领取充值送礼奖励礼包
fetch_recharge_award_gift_tmp(PS, GiftId) ->
	[Start, End] = data_recharge_award_tmp:get_recharge_award_time(),
	NowTime = util:unixtime(),
	[TrueStart, TrueEnd] = 
	case NowTime > End orelse NowTime < Start of
		true ->
			[0, 0];
		_ ->
			case PS#player_status.mergetime of
				0 ->
					ActionDay = util:get_open_day(),
					ActionTime = util:get_open_time(),
					NeedDay = data_recharge_award_tmp:get_day(),
					private_get_recharge_award_time(ActionDay, ActionTime, NeedDay, Start, End);
				_ ->
					ActionDay = lib_activity_merge:get_merge_day(),
					ActionTime = PS#player_status.mergetime,
					NeedDay = data_merge:get_recharge_day(),
					private_get_recharge_award_time(ActionDay, ActionTime, NeedDay, Start, End)
			end
	end,
	case [TrueStart, TrueEnd] of
		[0, 0] ->
			{error, 999};
		_ -> 
			G = PS#player_status.goods,
			[ReYbLimit, ReGiftId, ReSignTime] = data_recharge_award_tmp:get_recharge_award_regift(),
			case ReGiftId =:= GiftId of
				true ->
					%% 领取的是可重复的奖励
					%% 获取本阶段的领取数量
					TrueReNum = case db:get_row(io_lib:format(?sql_activity_data_get, [PS#player_status.id, ?ACTIVITY_RECHARGE_RE])) of
						[DataField, _AddTimeRe] ->
							DataL = util:to_term(DataField),
							case DataL of
								[Num, ActTime] ->
									case ActTime =:= ReSignTime of
										true ->
											Num;
										false ->
											0
									end;
								_ ->
									0
							end;
						[] ->
							0;
						_ ->
							error
					end,
					case TrueReNum =:= error of
						true ->
							{error, 999};
						false ->
							%% 计算充值数额
							Recharge1Re = lib_recharge_ds:get_pay_task_total(PS#player_status.id, TrueStart, TrueEnd),
							Recharge2Re = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, TrueStart, TrueEnd),
							RechargeRe = Recharge1Re + Recharge2Re,
							%% 计算可以领取的数量
							ReNumNow = RechargeRe div ReYbLimit,
							case TrueReNum >= ReNumNow of
								true -> %% 领取完成
									{error, 2};
								false ->%% 还可以领取
									case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
										{ok, [ok, NewPS]} ->
											ReInfo = util:term_to_string([TrueReNum + 1, ReSignTime]),
											db:execute(io_lib:format(?sql_activity_data_insert, [PS#player_status.id, ?ACTIVITY_RECHARGE_RE, ReInfo, NowTime])),
%% 											db:execute(io_lib:format(?sql_activity_data_insert, [ReInfo, NowTime, PS#player_status.id, ?ACTIVITY_RECHARGE_RE])),
											{ok, NewPS};
										{ok, [error, ErrorCode]} ->
											{error, ErrorCode};
										_ ->
											{error, 999}
									end
							end
					end;
				_ ->
					case db:get_row(io_lib:format(?sql_activity_data_get, [PS#player_status.id, ?ACTIVITY_FINISH_RECHARGE_AWARD_TMP])) of
						[Data, AddTime] ->
							case AddTime < TrueStart of
								true ->
									{error, 103};
								_ ->
									Recharge1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, TrueStart, TrueEnd),
									Recharge2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, TrueStart, TrueEnd),
									Recharge = Recharge1 + Recharge2,
		
									GiftList = util:to_term(Data),
									Result = lists:filter(fun([_, NeedGiftId]) -> 
										NeedGiftId =:= GiftId andalso lists:member(GiftId, GiftList) =:= false
									end, data_recharge_award_tmp:get_recharge_award_gift()),
		
									case Result of
										[[NeedGold, GiftId]] ->
											case Recharge >= NeedGold of
												true ->
													case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
														{ok, [ok, NewPS]} ->
															NewGiftList2 = util:term_to_string([GiftId | GiftList]),
															db:execute(io_lib:format(?sql_activity_data_update, [NewGiftList2, NowTime, PS#player_status.id, ?ACTIVITY_FINISH_RECHARGE_AWARD_TMP])),
															{ok, NewPS};
														{ok, [error, ErrorCode]} ->
															{error, ErrorCode};
														_ ->
															{error, 999}
													end;
												_ ->
													{error, 3}
											end;
										_ ->
											{error, 2}
									end
							end;
						_ ->
							{error, 999}
					end
			end
	end.
	
%% 收藏游戏送奖励
collect_game_award(PS) ->
	case db:get_one(io_lib:format(?sql_activity_fetch_row, [PS#player_status.id, ?ACTIVITY_TYPE_1])) of
		null ->
			NewPS = private_send_collect_award(PS),
			{ok, NewPS};

		FieldValue ->
			TmpCount = binary_to_list(FieldValue),
			Count = list_to_integer(TmpCount),
			case is_integer(Count) andalso Count =:= 1 of
				true ->
					{error, 2};
				_ ->
					NewPS = private_send_collect_award(PS),
					{ok, NewPS}
			end
	end.

%% 请求是否获取过收藏游戏的奖励
is_get_collect_award(RoleId) ->
	Sql = io_lib:format(?sql_activity_fetch_row, [RoleId, ?ACTIVITY_TYPE_1]),
	case db:get_one(Sql) of
		null ->
			0;
		FieldValue ->
			TmpCount = binary_to_list(FieldValue),
			Count = list_to_integer(TmpCount),
			case is_integer(Count) andalso Count =:= 1 of
				true ->
					1;
				_ -> 
					0
			end
	end.

%% [升级向前冲] 打开面板需要的数值
get_level_forward_data(PS) ->
	case PS#player_status.activity#status_activity.level_forward of
		%% 如果没有保存在玩家进程数据中，需要从DB中获取
		undefined ->
			case db:get_one(io_lib:format(?sql_activity_fetch_row, [PS#player_status.id, ?ACTIVITY_TYPE_3])) of
				%% 如果不存在数据，插入一条新数据
				null ->
					db:execute(io_lib:format(?sql_activity_update2, [PS#player_status.id, ?ACTIVITY_TYPE_3, "[0]"])),
					Activity = PS#player_status.activity,
					NewActivity = Activity#status_activity{level_forward = [0]},
					NewPS = PS#player_status{activity = NewActivity},
					[NewPS, private_format_level_forward([])];

				%% 数据库有值
				Content ->
					List = util:to_term(Content),
					Activity = PS#player_status.activity,
					NewActivity = Activity#status_activity{level_forward = List},
					NewPS = PS#player_status{activity = NewActivity},
					[NewPS, private_format_level_forward(List)]
			end;
		_ ->
			[PS, private_format_level_forward(PS#player_status.activity#status_activity.level_forward)]
	end.

%% [升级向前冲] 领取奖励
fetch_level_forward_award(PS) ->
	OldGetList = PS#player_status.activity#status_activity.level_forward,
	
	case OldGetList of
		AlreadyGetList when is_list(AlreadyGetList) ->
			F = fun([Level, GiftId], GetList) ->
				case PS#player_status.lv >= Level andalso lists:member(Level, AlreadyGetList) =:= false of
					true ->
						[{Level, GiftId} | GetList];
					_ ->
						GetList
				end
			end,

			CanGetList = lists:foldl(F, [], data_activity:get_award()),
			case length(CanGetList) > 0 of
				true ->
					{GetLevel, GetGiftId} = lists:nth(1, CanGetList),
					[LastLevel, _] = lists:nth(1, data_activity:get_award()),

					%% 送礼包
					G = PS#player_status.goods,
					case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GetGiftId}) of
						{ok, [ok, NewPS]} ->
							%% 设置领取奖励
							NewPS2 = private_level_forward_fetch_award(NewPS, GetLevel),

							%% 如果是最后一个奖励，则设置活动图标不需要再出现
							case GetLevel =:= LastLevel of
								true ->
									finish_activity(NewPS2, ?ACTIVITY_FINISH_LEVEL_FORWARD);
								_ ->
									skip
							end,
							{ok, NewPS2, GetLevel};
						{ok, [error, ErrorCode]} ->
							{error, ErrorCode};
						_ ->
							{error, 999}
					end;
				_ ->
					{error, 2}
			end;
		_ ->
			{error, 2}
	end.

%% [首服充值活动] 是否开服5天内
is_recharge_valid_time() ->
	util:check_open_day(data_activity:get_common_daynum()).

%% [首服充值活动] 打开面板
get_recharge_activity_data(PS) ->
	%% 充值总额
	Recharge = lib_recharge:get_total(PS#player_status.id),
	%% 礼包列表
	GiftStatus1 = case lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_1) of
		1 -> 1;
		_ -> 0
	end,
	GiftStatus2 = case lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_2) of
		1 -> 1;
		_ -> 0
	end,
	GiftStatus3 = case lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_3) of
		1 -> 1;
		_ -> 0
	end,
	GiftStatus4 = case lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_4) of
		1 -> 1;
		_ -> 0
	end,
	GiftStatus5 = case lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_5) of
		1 -> 1;
		_ -> 0
	end,
	GiftStatus6 = case lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_6) of
		1 -> 1;
		_ -> 0
	end,
	Recharge1 = data_activity:get_recharge_from_gift(532001),
	Recharge2 = data_activity:get_recharge_from_gift(532021),
	Recharge3 = data_activity:get_recharge_from_gift(532022),
	Recharge4 = data_activity:get_recharge_from_gift(532023),
	Recharge5 = data_activity:get_recharge_from_gift(532024),
	Recharge6 = data_activity:get_recharge_from_gift(532025),
	List = [
		<<?ACTIVITY_RECHARGE_GIFT_1:32, GiftStatus1:8, Recharge1:32>>,
		<<?ACTIVITY_RECHARGE_GIFT_2:32, GiftStatus2:8, Recharge2:32>>,
		<<?ACTIVITY_RECHARGE_GIFT_3:32, GiftStatus3:8, Recharge3:32>>,
		<<?ACTIVITY_RECHARGE_GIFT_4:32, GiftStatus4:8, Recharge4:32>>,
		<<?ACTIVITY_RECHARGE_GIFT_5:32, GiftStatus5:8, Recharge5:32>>,
		<<?ACTIVITY_RECHARGE_GIFT_6:32, GiftStatus6:8, Recharge6:32>>
	],

	%% 剩余时间
	OpenTime = util:unixdate(util:get_open_time()),
	SpecialTime = util:unixdate(util:unixtime(data_activity:get_special_day())),
	NowTime = util:unixtime(),
	LeftTime = case OpenTime < SpecialTime of
		true ->
			SpecialTime + data_activity:get_special_daynum() * 86400 - NowTime;
		_ ->
			OpenTime + data_activity:get_common_daynum() * 86400 - NowTime
	end,
	LeftTime2 = case LeftTime < 0 of
		true -> 0;
		_ -> LeftTime
	end,
	[Recharge, List, LeftTime2].

%%  [首服充值活动] 领取礼包
fetch_recharge_activity_gift(PS, GiftId) ->
	%% 判断礼包参数是否正确
	GiftList = [?ACTIVITY_RECHARGE_GIFT_1, ?ACTIVITY_RECHARGE_GIFT_2, ?ACTIVITY_RECHARGE_GIFT_3, ?ACTIVITY_RECHARGE_GIFT_4, ?ACTIVITY_RECHARGE_GIFT_5, ?ACTIVITY_RECHARGE_GIFT_6],
	case lists:member(GiftId, GiftList) of
		true ->
			case GiftId =:= ?ACTIVITY_RECHARGE_GIFT_1 of
				%% 领取首充礼包，只要充值过没领取过就可以领取，没其他条件
				true ->
					private_fetch_recharge_activity_gift(PS, GiftId);

				%% 其他礼包有额外的时间限制
				_ ->
					%% 剩余时间
					SpecialTime = util:unixdate(util:unixtime(data_activity:get_special_day())),
					OpenTime = util:unixdate(util:get_open_time()), 
					NowTime = util:unixtime(),

					case NowTime < SpecialTime of
						true ->
							{error, 102};
						_ ->
							case OpenTime >= SpecialTime of
								true ->
									%% 如果是开服5天内才可以领取
									case is_recharge_valid_time() of
										true ->
											private_fetch_recharge_activity_gift(PS, GiftId);
										_ ->
											{error, 103}
									end;
								_ ->
									case (NowTime >= SpecialTime) andalso (NowTime =< SpecialTime + data_activity:get_special_daynum() * 86400) of
										true ->
											private_fetch_recharge_activity_gift(PS, GiftId);
										_ ->
											{error, 103}
									end
							end
					end
			end;
		_ ->
			{error, 999}
	end.

%% 获取活动奖励领取统计
get_finish_stat(PS, Type) ->
	case lists:member(Type, ?ACTIVITY_FINISH_ALL_ID) of
		true ->
			case get_activity_show_stat(PS, Type) of
				null ->
					[0, private_get_finish_level(data_activity:get_finish_stat(), Type)];
				FieldValue ->
					TmpCount = binary_to_list(FieldValue),
					Count = list_to_integer(TmpCount),
					case is_integer(Count) andalso Count =:= 1 of
						true ->
							[1, private_get_finish_level(data_activity:get_finish_stat(), Type)];
						_ ->
							[0, private_get_finish_level(data_activity:get_finish_stat(), Type)]
					end
			end;
		_ ->
			skip
	end.

%% 完成某项活动
finish_activity(PS, Type) ->
	case lists:member(Type, ?ACTIVITY_FINISH_ALL_ID) of
		true ->
			Sql = io_lib:format(?sql_activity_update, [PS#player_status.id, Type, 1]),
			db:execute(Sql);
		_ ->
			skip
	end,
	ok.

%% 首次充值传闻
send_first_charge_cw(PS, WeaponId) ->
	case data_gift:get(?FIRST_RECHARGE_GIFT_ID) of
		[] ->
			skip;
		Gift when is_record(Gift, ets_gift) ->
			case Gift#ets_gift.goods_id > 0 of
				true ->
					lib_chat:send_TV({all},0, 1, [
						"firstChong",
						PS#player_status.id,
						PS#player_status.nickname,
						PS#player_status.sex, 
						PS#player_status.career,
						0,
						PS#player_status.realm,
						Gift#ets_gift.goods_id,
                        WeaponId
					]);
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%% [开服7天内每天登录奖励] 打开面板
get_seven_day_login_data(PS) ->
	case db:get_row(io_lib:format(?sql_activity_sevenday_fetch, [PS#player_status.id])) of
		[Signup, GiftListField, _LastTime] ->
			GiftList = util:to_term(GiftListField),
			lists:map(fun(Day) -> 
				[GiftId1, GiftId2] = data_activity:get_seven_day_login_gift(Day),
				case Signup >= Day of
					true ->
						case lists:member(GiftId1, GiftList) or lists:member(GiftId2, GiftList) of
							true ->
								<<Day:32, 2:8>>;
							_ ->
								<<Day:32, 1:8>>
						end;
					_ ->
						<<Day:32, 0:8>>
				end
			end, [1,2,3,4,5,6,7]);
		_ ->
			lists:map(fun(Day) -> <<Day:32, 0:8>> end, [1,2,3,4,5,6,7])
	end.

%% [开服7天内每天登录奖励] 领取奖励
get_seven_day_login_gift(PS, Day) ->
    VipType = PS#player_status.vip#status_vip.vip_type,
	case db:get_row(io_lib:format(?sql_activity_sevenday_fetch, [PS#player_status.id])) of
		[Signup, GiftListField, _LastTime] ->
			%% 传进来的天数大于签到天数，且在7天内
			case Day >= 1 andalso Day < 8 andalso Signup >= Day of
				true ->
					%% 已经领取的礼包列表
					GiftList = util:to_term(GiftListField),
					[GiftId1, GiftId2] = data_activity:get_seven_day_login_gift(Day),
					case lists:member(GiftId1, GiftList) or lists:member(GiftId2, GiftList) of
						%% 已经领取了奖励
					    true ->
							{error, 2};
						_ ->
							GiftId = case VipType > 0 of
								false -> GiftId1;
								_ -> GiftId2
							end,
							case GiftId > 0 of
						        true ->
					   	        	G = PS#player_status.goods,
							        case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
								        {ok, [ok, NewPS]} ->
											GiftList2 = [GiftId | GiftList],
											GiftList3 = util:term_to_string(GiftList2),
											db:execute(io_lib:format(?sql_activity_sevenday_update, [GiftList3, PS#player_status.id])),
									        case length(GiftList2) >= 7 of
												true ->
													finish_activity(NewPS, ?ACTIVITY_FINISH_SEVEN_DAY);
												_ ->
													skip
											end,
											{ok, NewPS, GiftId};
								        {ok, [error, ErrorCode]} ->
											{error, ErrorCode};
								    	_ ->
											{error, 999}
									end;
						        _ ->
									{error, 100}
						end
					end;
				_ ->
					{error, 999}
			end;
		_ ->
			{error, 999}
	end.

%% 开服七天签到礼包拿到处理
seven_day_signup(RoleId) ->
	case db:get_row(io_lib:format(?sql_activity_sevenday_fetch, [RoleId])) of
		[Signup, _GiftListField, LastTime] ->
			%% 签到七次后，就不再处理
			case Signup > 7 of
				true ->
					skip;
				_ ->
					DayTime = util:unixdate(),
					case DayTime > LastTime of
						true ->
							db:execute(io_lib:format(?sql_activity_sevenday_update2, [DayTime, RoleId]));
						_ ->
							skip
					end
			end;
		_ ->
			db:execute(io_lib:format(?sql_activity_sevenday_insert, [RoleId, 1, util:unixdate()]))
	end.

%% 充值任务：是否充值任务时间内
%% 返回 : bool
is_pay_task_time() ->
	NowTime = util:unixtime(),
	TimeConfig = data_activity_time:get_time_by_type(10),
	case TimeConfig of
		[Begin, End] -> skip;
		[] -> 
			Begin= util:unixtime({{2015, 10, 30}, {6, 0, 0}}),
			End = util:unixtime({{2016, 10, 30}, {6, 0, 0}})
	end,
	NowTime >= Begin andalso NowTime =< End andalso util:get_open_day() > 5.

%% 充值任务：处理充值触发任务完成逻辑
%% 查询充值额按开服10天分开, 少于10天用于新服,充值额从接取任务时间算起
%% 大于等于10天,充值额从活动开始时间算起
pay_task_do_recharge(PS) ->
	NowTime = util:unixtime(),
	TimeConfig = data_activity_time:get_time_by_type(10),	
	case TimeConfig of
		[PayTaskStart, PayTaskEnd] -> skip;
		[] -> 
			PayTaskStart= util:unixtime({{2015, 10, 30}, {6, 0, 0}}),
			PayTaskEnd = util:unixtime({{2016, 10, 30}, {6, 0, 0}})
	end,
	OpenDay = util:get_open_day(),
	Pay_task_id = 200120,
	case NowTime >= PayTaskStart andalso NowTime =< PayTaskEnd andalso util:get_open_day() > 5 of
		true ->
			TriggerTime = lib_task:get_trigger_time(PS#player_status.tid, Pay_task_id),
			case TriggerTime =/= false andalso TriggerTime =/=0 of
				true -> %%　查询接取任务到现在的充值					    
					case OpenDay>=10 of
						true ->
							PayTaskTotal1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, PayTaskStart, PayTaskEnd),
							PayTaskTotal2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, PayTaskStart, PayTaskEnd);
						false ->
							PayTaskTotal1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, TriggerTime, NowTime),
							PayTaskTotal2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, TriggerTime, NowTime)
					end,
					PayTaskTotal = PayTaskTotal1 + PayTaskTotal2,
					lib_task:event(PS#player_status.tid, pay_task, {PayTaskTotal}, PS#player_status.id);
				false -> skip
			end;
		_ ->
			skip
	end.

%% 普通充值任务，触发任务完成逻辑
finish_pay_task(PS, _PayTotal) ->
	CrystalTask1= 200290,
	CrystalTask2= 200450,
	if
		PS#player_status.lv >= 59 ->
			case lib_task:in_trigger(PS#player_status.tid, CrystalTask1) of
				true -> private_finish_payTask(PS, CrystalTask1, _PayTotal);
				false ->
					case lib_task:in_trigger(PS#player_status.tid, CrystalTask2) of
						true -> private_finish_payTask(PS, CrystalTask2, _PayTotal);
						false -> lib_task:event(PS#player_status.tid, pay_task_2, {1}, PS#player_status.id)
					end
			end;
		PS#player_status.lv >= 50 ->
			case lib_task:in_trigger(PS#player_status.tid, CrystalTask1) of
				true -> private_finish_payTask(PS, CrystalTask1, _PayTotal);
				false -> lib_task:event(PS#player_status.tid, pay_task_2, {1}, PS#player_status.id)
			end;
		PS#player_status.lv >= 20 ->
			lib_task:event(PS#player_status.tid, pay_task_2, {1}, PS#player_status.id);
		true ->
			skip
	end.

%% [中秋国庆活动] 领取活跃度礼包
%% Type : 类型，1活跃度80，2活跃度100，3活跃度120
fetch_active_gift(PS, Type) ->
	case lists:member(Type, [1, 2, 3]) of
		true ->
			NowTime = util:unixtime(),
			%% 活动时间戳
			[Start, End] = data_activity:get_active_time(),
			%% 判断是否在活动期间
			case NowTime >= Start andalso NowTime =< End of
				true ->
					[[_, RequireActive, CacheKey]] = lists:filter(fun([TmpType, _, _]) -> 
						TmpType =:= Type
					end, data_activity:get_active_conf()),
					
					%% 判断是否已经领取了礼包
					Status = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, CacheKey),
					case Status == 0 of
						true ->
							%% 当前活跃度
							Active = mod_active:get_my_active(PS#player_status.status_active),
							case Active >= RequireActive of
								true ->
									%% 礼包id
									GiftId = data_activity:get_active_gift(),

									G = PS#player_status.goods,
									case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
										{ok, [ok, NewPS]} ->
											%% 更新为已经领取了礼包
											mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, CacheKey, 1),
											
											{ok, NewPS, GiftId};
										{ok, [error, ErrorCode]} ->
											{error, ErrorCode}
									end;
								_ ->
									{error, 3}
							end;
						_ ->
							{error, 2}
					end;
				_ ->
					{error, 999}
			end;
		_ ->
			{error, 999}
	end.

%% [通用] 领取奖励
get_common_award(PS, In) ->
	if
		%% 登录器
		In == 105 ->
			case db:get_one(io_lib:format(?sql_activity_fetch_row, [PS#player_status.id, 105])) of
				null ->
					NewPS = private_send_login_award(PS),
					{ok, NewPS};

				FieldValue ->
					TmpCount = binary_to_list(FieldValue),
					Count = list_to_integer(TmpCount),
					case is_integer(Count) andalso Count =:= 1 of
						true ->
							{error, 3};
						_ ->
							NewPS = private_send_login_award(PS),
							{ok, NewPS}
					end
			end;

		true ->
			{error, 2}
	end.
	

%% 获取玩家回归活动完成状态
get_back_activity_stat(PS, Type) -> 
	NowTime = util:unixtime(),
	[Start, End] = data_activity:back_activity_time(Type), 
	[NeedLv, _NeddLfTime, _NeddOpday] = data_activity:back_activity_config(Type),
	%% private_del_back_activity_gift(PS#player_status.id, Type),
	Back_State = db:get_one(io_lib:format(?sql_activity_back_state, [PS#player_status.id, Type, Start, End])),
	case NowTime>=Start andalso NowTime=<End of
		true ->
			case  Back_State of
				null -> [1, NeedLv]; %% 不满足条件
				0 -> [0, NeedLv];	 %% 满足条件
				1 -> [2, NeedLv]	 %% 已经领取
			end;
		false -> [1, NeedLv]
	end.

%% 领取幸福回归奖励
get_back_activity_award(PS) ->
	NowTime = util:unixtime(),
	Type = 1,
	[Stat, _]= get_back_activity_stat(PS, Type),
	case Stat of
		0 ->
%%			LastLoginTime = db:get_one(io_lib:format(?sql_player_last_login_time, [PS#player_status.id])), 
			LastLoginTime = mod_activity_login:get_pre_loginTime(PS#player_status.id), 
			case LastLoginTime =/= null of
				true -> LfTime =  NowTime - LastLoginTime;
				false -> LfTime = 0
			end,
			N = LfTime div (24*60*60),
			Lv = PS#player_status.lv,
			AwardExp = util:floor((N-1.26)*(Lv*Lv*Lv*180+Lv*Lv*1020)*0.6),
			case AwardExp> 0 of
				true ->
					NewPS = lib_player:add_exp(PS, AwardExp),
					SQL = io_lib:format(?sql_activity_back_update, [1, PS#player_status.id, Type]),
					db:execute(SQL),
					[1, NewPS];
				false ->
					[3, PS]
			end;
		1 -> [3, PS];
		2 -> [2, PS]
	end.

%% [幸福回归] -- 回归首充奖励
back_activity_charge_award(PS, Amount) ->
	Type = 3,
	NowTime = util:unixtime(),
	[NeedGold,Ratio] = data_activity:back_charge_award_config(),	
	[Stat, _]= get_back_activity_stat(PS, Type),
	[Start, End] = data_activity:back_activity_time(Type),
	case NowTime>=Start andalso NowTime=<End andalso Stat =:=0 of
		true -> 
			SQL = io_lib:format(?sql_activity_back_update, [1, PS#player_status.id, Type]),
			db:execute(SQL),
			case Amount>= NeedGold of
				true ->
					{Title, Content, GiftId, _} = data_activity_text:back_activity(Type),
					AwardGold = util:floor(Amount*Ratio/100),
					%%回归首充奖励
					mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PS#player_status.id], Title, Content, GiftId, 2, 0, 0,1,0,0,0,AwardGold]);
				false -> skip
			end;
		false -> skip
	end.

%% 运营活动登录处理
%% 如登录后符合条件发送奖励邮件
process_activity_login(PS) ->
	spawn(fun() ->
            timer:sleep(0 * 1000),            
			%%1--幸福回归礼包
			private_back_activity(PS)
    end),
	process_activity_login2(PS).

process_activity_login2(PS) ->
	case self() =:= PS#player_status.pid of
		true -> consume_returngold_login(PS);
		false ->
			gen_server:cast(PS#player_status.pid, {'apply_cast', lib_activity, consume_returngold_login, [PS]})
	end.
	
%% 登录加载消费返元宝数据
consume_returngold_login(PS) ->
	NowTime = util:unixtime(),
	[{Expenditure1, GiftId1},{Expenditure2, GiftId2}] = data_consume_returngold:get_return_config(),
	SList1 = db:get_all(io_lib:format(?sql_consume_returngold_select_1, [PS#player_status.id])),
	[_, EndTime] = data_consume_returngold:get_time(),
	case NowTime>EndTime of
		true ->
		%% 过期删除数据,发送补发邮件
		case length(SList1)>0 of
			true ->
				F3 = fun([_Id, Expenditure, _Theday, Status, _Fetchtime]) ->
				case  Status<2 andalso (Expenditure>=Expenditure1 orelse Expenditure>=Expenditure2) of
				true ->
					%% 计算返还元宝
					case Expenditure2>Expenditure1 of
						true -> 
						if Expenditure>=Expenditure2 ->
							Goodsid = GiftId2;				 
							true ->
							Goodsid = GiftId1
						end;
						false ->
							Goodsid = GiftId1
						end,
						Title = data_activity_text:get_player_consume_returngold_title(),
						Content = data_activity_text:get_player_consume_returngold_content(),
						mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PS#player_status.id], Title, Content, Goodsid, 2, 0, 0,1,0,0,0,0]);
				false -> skip
				end				
			end,
			lists:foreach(F3, SList1),
			%% 写删除日志
			SList3 = db:get_all(io_lib:format(?sql_consume_returngold_select_4, [PS#player_status.id])),	
			F4 = fun(ConsumeData) ->
					db:execute(io_lib:format(?sql_log_consume_returngold_insert, ConsumeData++[util:unixtime()]))	
			end,
			lists:foreach(F4, SList3),
			%% 删除数据
			db:execute(io_lib:format(?sql_consume_returngold_delete, [PS#player_status.id]));
			false -> skip
		end;
		false -> 
			%% 检查修改满足条件记录的状态
			F1 = fun([Id, Expenditure, Theday, Status, Fetchtime]) ->
					AllowFetchTime = data_consume_returngold:get_fetch_time(),
					case NowTime>AllowFetchTime andalso Status<1 andalso (Expenditure>=Expenditure1 orelse Expenditure>=Expenditure2) of
						true ->
						db:execute(io_lib:format(?sql_consume_returngold_update_2, [1, Id])),	
						[Id, Expenditure, Theday, 1, Fetchtime];
						false -> [Id, Expenditure, Theday, Status, Fetchtime]
				end
			end,			
			SList2 = lists:map(F1, SList1),	
			F2 = fun(PerList) ->					
					list_to_tuple([consume_returngold|PerList])
			end,
			TupleList = lists:map(F2, SList2),
			Key = list_to_atom("consume_returngold_"++integer_to_list(PS#player_status.id)),
			put(Key, TupleList)
	end.		
		
%% 获取消费返元宝数据
fetch_consume_returngold_data(PS) ->
	Key = list_to_atom("consume_returngold_"++integer_to_list(PS#player_status.id)),
	TupleList = 
	case get(Key) of
		undefined -> [];
		Other -> Other
	end,
	[{Expenditure1, _GiftId1},{Expenditure2,_GiftId2}]  =  data_consume_returngold:get_return_config(),
	F = fun(Crg) ->
		Expenditure3 = lists:max([Expenditure1, Expenditure2]),
		Expenditure4 = lists:min([Expenditure1, Expenditure2]),
		if Crg#consume_returngold.expenditure >= Expenditure3 -> 
			[Crg#consume_returngold.id,1,Crg#consume_returngold.status,Crg#consume_returngold.the_day,
				Crg#consume_returngold.fetch_time, Crg#consume_returngold.expenditure];
		   Crg#consume_returngold.expenditure >= Expenditure4 -> 
			[Crg#consume_returngold.id,0,Crg#consume_returngold.status,Crg#consume_returngold.the_day,
				Crg#consume_returngold.fetch_time, Crg#consume_returngold.expenditure];
		   true -> []
		end
	end,	
	{Satisfying, _NotSatisfying} = lists:partition(fun(X)-> X=/=[] end, lists:map(F, TupleList)),
	Satisfying.

%% 领取消费返还元宝
gain_consume_returngold(Id, PS) ->
	Go = PS#player_status.goods,
	NowTime = util:unixtime(),
	AllowFetchTime = data_consume_returngold:get_fetch_time(),
	Key = list_to_atom("consume_returngold_"++integer_to_list(PS#player_status.id)),
	TupleList = case get(Key) of
		undefined -> [];
		Other -> Other
	end,
	GainData = db:get_row(io_lib:format(?sql_consume_returngold_select_3, [Id])),
	if NowTime>AllowFetchTime ->	
	case length(GainData)>0 of
	true ->
		[Expenditure, Status] = GainData,
		[{Expenditure1,GiftId1},{Expenditure2,GiftId2}] = data_consume_returngold:get_return_config(),
		if 
			Status=:=1 -> 
			case Expenditure>=Expenditure1 orelse Expenditure>=Expenditure2 of
				true ->
					%% 计算返还元宝
					case Expenditure2>Expenditure1 of
					true -> 
						if Expenditure>=Expenditure2 ->
							Goodsid = GiftId2;				 
						true ->
							Goodsid = GiftId1
                        end;
					false ->
							Goodsid = GiftId1
					end,					
					%% 领取物品
					GiveList = [{Goodsid, 1}],
					case gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', [], GiveList}) of
						ok ->
							lib_gift_new:send_goods_notice_msg(PS, [{goods, Goodsid, 1}]),	
							%% 更改领取状态
							db:execute(io_lib:format(?sql_consume_returngold_update_3, [NowTime,Id])),
							TupleData = lists:keyfind(Id, 2, TupleList),
							case TupleData=/=false of
								true ->
									TupleList2 = lists:keydelete(Id, 2, TupleList),					 
									TupleList3 = TupleList2 ++ [TupleData#consume_returngold{status=2,fetch_time=NowTime}],
									put(Key, TupleList3);
								false -> skip
							end,							
							{ok, 0};	
						{fail, 2} ->	%% 物品不存在
							{error, 6};
						{fail, 3} ->    %% 背包空间不足
							{error, 7};
						_Error ->       %% 未知错误
							{error, 8}
					end;
				false ->
					{error, 3}		 %% 消费额度不够
			end;
			Status=:=0 -> {error, 2}; %% 暂不可领取
			Status=:=2 -> {error, 1}; %% 已经领取
			true -> {error, 4} %% 失败
		end;
	false -> {error, 4} %% 该红包不存在				
	end;
	true -> {error, 5} %% 还未到领取时间				
	end.

%% 消费返元宝接口 [注意:新版神秘商店刷新、购买记录到了petjn(宠物技能)]
%% @param taobao(淘宝),shangcheng(商城),petcz(宠物成长),petqn(宠物潜能),petjn(神秘刷新+神秘购买),cmsd(财迷商店),marryxyan(结婚喜宴),marryxyou(结婚巡游),vipup(VIP升级)
%% @param Eqout 消费额度
add_consumption(Type,PS,Eqout) when is_record(PS,player_status) ->
	case self() =:= PS#player_status.pid of
		true -> add_consumption2(Type,PS,Eqout);
		false ->
			gen_server:cast(PS#player_status.pid, {'apply_cast', lib_activity, add_consumption2, [Type, PS, Eqout]})
	end.

add_consumption2(Type,PS,Eqout) when is_integer(Eqout) ->
	NowTime = util:unixtime(),
	OpenDay = util:get_open_day(),
	[NeedOpenday, StartTime, EndTime|_] = data_consume_returngold:all_data(),
	IsOpening = (OpenDay>=NeedOpenday andalso  NowTime>=StartTime andalso NowTime<EndTime-3*86400),

	PlayerId = PS#player_status.id,
	ZeroTime = util:unixdate(),
	NextZeroTime = ZeroTime + 24*60*60,
	Key = list_to_atom("consume_returngold_"++integer_to_list(PlayerId)),
	TupleList = case get(Key) of
		undefined -> [];
		Other -> Other
	end,	
	%% 是否在活动时间内,且该消费类型为开启状态
	case IsOpening andalso data_consume_returngold:consume_is_open(Type)of
		true -> 
			Sql1 = io_lib:format(?sql_consume_returngold_select_2, [ZeroTime, NextZeroTime, PlayerId]),
			PacketId = db:get_one(Sql1),
			case PacketId=:=null of
				true -> 
					%% 今日未消费
					Sql2 = io_lib:format(?sql_consume_returngold_insert, [PlayerId, Eqout, ZeroTime]),
					db:execute(Sql2),
					PacketId2 = db:get_one(Sql1),
					TupleList2 = lists:keydelete(PacketId2, 2, TupleList),					
					TupleList3 = TupleList2 ++ [#consume_returngold{id =PacketId2, expenditure=Eqout,the_day=ZeroTime}],
					put(Key, TupleList3);
				false ->
					%% 今日已消费
					GainData = db:get_row(io_lib:format(?sql_consume_returngold_select_3, [PacketId])),
					[Expenditure, _Status] = GainData,
					Sql3 = io_lib:format(<<"update  activity_consume_returngold set expenditure=~p where id=~p">>, [Expenditure+Eqout, PacketId]),
					db:execute(Sql3),
					TupleData = lists:keyfind(PacketId, 2, TupleList),	
					case TupleData of
						false -> skip;
						TupleData ->
							TupleList2 = lists:keydelete(PacketId, 2, TupleList),					 
							TupleList3 = TupleList2 ++ [TupleData#consume_returngold{expenditure=Eqout+TupleData#consume_returngold.expenditure}],
							put(Key, TupleList3)
					end					
			end,
			pp_activity_daily:handle(31493, PS, []);
		false -> skip			
	end.

adjuest_expenditure_for_houtai(PlayerId, Expenditure, Time) ->	
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
			gen_server:cast(Pid, {'adjuest_expenditure_for_houtai', [Expenditure, Time]}),
			ok;
        _ ->
			SQL = io_lib:format(<<"update  activity_consume_returngold set expenditure=~p where uid=~p and the_day=~p">>, [Expenditure, PlayerId, Time]),
			db:execute(SQL),
			ok
    end.

adjuest_expenditure(PlayerId, Expenditure, Time) ->
	SQL = io_lib:format(<<"update  activity_consume_returngold set expenditure=~p where uid=~p and the_day=~p">>, [Expenditure, PlayerId, Time]),
	db:execute(SQL).

%% 领取首充礼包的一件武器，放到背包中
fetch_first_recharge_weapon(PS, GiftId, G) ->
    GoodsTypeId = private_get_first_recharge_weapon(PS#player_status.career, PS#player_status.sex),

	%% 首充礼包，要附送一件武器
	case GiftId =:= ?ACTIVITY_RECHARGE_GIFT_1 of
		true ->
            {ok, CellNum} = gen:call(G#status_goods.goods_pid, '$gen_call', {'cell_num'}),
			GiftInfo = data_gift:get(GiftId),
			%% 判断格式是否足够
			case CellNum < lib_gift_new:get_gift_length(GiftInfo) + 1 of
				true ->
					{error, 105};
				_ ->
                     GoodsList = [{goods, GoodsTypeId, 1, 0, 3, 2}],
                     gen_server:call(G#status_goods.goods_pid, {'give_more', PS, GoodsList}),
                     {ok, GoodsTypeId}
			end;
		_ ->
			{ok, GoodsTypeId}
	end.

private_back_activity(PS) ->
	TypeList = [1,2,3],
	NowTime = util:unixtime(),
	OpenTime = util:get_open_day(),
	LastLoginTime = db:get_one(io_lib:format(?sql_player_last_login_time, [PS#player_status.id])),
%%	LastLoginTime = mod_activity_festival:get_pre_loginTime(PS#player_status.id),		
	case LastLoginTime =/= null of
		true -> LfTime =  NowTime - LastLoginTime;
		false -> LfTime = 0
	end,
	F = fun(Type) ->
		[Start, End] = data_activity:back_activity_time(Type),
		[NeedLv, NeddLfTime, NeddOpday] = data_activity:back_activity_config(Type),
		case NowTime>=Start andalso NowTime=<End andalso PS#player_status.lv>=NeedLv
				andalso OpenTime>=NeddOpday andalso LfTime>=NeddLfTime of
			true ->
				Back_State = db:get_one(io_lib:format(?sql_activity_back_state, [PS#player_status.id, Type, Start, End])),
				case Back_State of
					null -> 
						Sql = io_lib:format(?sql_activity_back_add, [PS#player_status.id, Type, 0, NowTime]),
						db:execute(Sql),
					    Is_send_gift = 1;
					Other -> 
						case Other of
							0 -> Is_send_gift = 1;
							_ -> Is_send_gift = 0
						end
				end,				
				case Is_send_gift=:=1 andalso Type=:=2 of
					true -> private_fetch_back_activity_gift(PS);
					false -> skip
				end;
			false -> skip
		end,
		private_del_back_activity_gift(PS#player_status.id, Type)
	end,
	lists:map(F, TypeList).

private_del_back_activity_gift(Id, Type) ->
	OpenTime = util:get_open_day(),
	case OpenTime<7 of
		true ->			
			Sql = io_lib:format(<<"delete from  activity_back where role_id=~p and state=0 and type=~p">>, [Id, Type]),
			db:execute(Sql);
		false -> skip
	end.

%% [幸福回归] -- 回归大礼奖励
private_fetch_back_activity_gift(PS) ->
	Type = 2,
%%	[Stat, _]= get_back_activity_stat(PS, Type),
	case PS#player_status.lv>=45 of
		true -> 
			{Title, Content, Gift1, Gift2} = data_activity_text:back_activity(Type),
			case PS#player_status.lv>=60 of
				true -> GiftId = Gift2;
				false -> GiftId = Gift1
			end,
			%%幸福回归礼包
			mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PS#player_status.id], Title, Content, GiftId, 2, 0, 0,1,0,0,0,0]), 
			SQL = io_lib:format(?sql_activity_back_update, [1, PS#player_status.id, Type]),
			db:execute(SQL);
		false -> skip
	end.

private_fetch_recharge_activity_gift(PS, GiftId) ->
	%% 判断礼包是否已经领取过
	Result = lib_gift_new:get_gift_fetch_status(PS#player_status.id, GiftId),
	case Result of
		%% 已经领取了奖励
		1 ->
			{error, 2};
		_ ->
			%% 判断充值元宝数是否足够
			Recharge = lib_recharge:get_total(PS#player_status.id),
			case Recharge >= data_activity:get_recharge_from_gift(GiftId) of
				true ->
					G = PS#player_status.goods,

					case fetch_first_recharge_weapon(PS, GiftId, G) of
						{ok, WeaponId} ->
							case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
								{ok, [ok, NewPS]} ->
									%% 领取首充礼包时发传闻
									if
										GiftId =:= ?ACTIVITY_RECHARGE_GIFT_1 ->
											lib_gift_new:update_to_received(PS#player_status.id, GiftId),
											send_first_charge_cw(PS, WeaponId);
										GiftId =:= ?ACTIVITY_RECHARGE_GIFT_2 ->
											lib_gift_new:trigger_finish(PS#player_status.id, GiftId);
										GiftId =:= ?ACTIVITY_RECHARGE_GIFT_3 ->
											lib_gift_new:trigger_finish(PS#player_status.id, GiftId);
										GiftId =:= ?ACTIVITY_RECHARGE_GIFT_4 ->
											lib_gift_new:trigger_finish(PS#player_status.id, GiftId);
										GiftId =:= ?ACTIVITY_RECHARGE_GIFT_5 ->
											lib_gift_new:trigger_finish(PS#player_status.id, GiftId);
										GiftId =:= ?ACTIVITY_RECHARGE_GIFT_6 ->
											lib_gift_new:trigger_finish(PS#player_status.id, GiftId);
										true ->
											skip
									end,

									%% 礼包都领取后，更新这个活动结束
									Fetch1 = lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_1) == 1,
									Fetch2 = lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_2) == 1,
									Fetch3 = lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_3) == 1,
									Fetch4 = lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_4) == 1,
									Fetch5 = lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_5) == 1,
									Fetch6 = lib_gift_new:get_gift_fetch_status(PS#player_status.id, ?ACTIVITY_RECHARGE_GIFT_6) == 1,
									if
										Fetch1 andalso Fetch2 andalso Fetch3 andalso Fetch4 andalso Fetch5 andalso Fetch6 ->
											 finish_activity(PS, ?ACTIVITY_FINISH_RECHARGE_GIFT);
										true ->
											skip
									end,

									%% 刷新任务中的首充任务为完成状态
									NewPS3 = case GiftId =:= ?ACTIVITY_RECHARGE_GIFT_1 of
										true ->
											case pp_task:handle(30004, NewPS, [200140, {}]) of
												{ok, NewPS2} ->
													NewPS2;
												_ ->
													NewPS
											end;
										_ ->
											NewPS
									end,
									{ok, NewPS3};
								{ok, [error, ErrorCode]} ->
									{error, ErrorCode}
							end;
						{error, WeaponErr} ->
							{error, WeaponErr}
					end;
				_ ->
					{error, 3}
			end
	end.

%% 取得首充礼包赠送的武器
private_get_first_recharge_weapon(1, 1) -> 101023;
private_get_first_recharge_weapon(1, 2) -> 101028;
private_get_first_recharge_weapon(2, 1) -> 102023;
private_get_first_recharge_weapon(2, 2) -> 102028;
private_get_first_recharge_weapon(3, 1) -> 103023;
private_get_first_recharge_weapon(3, 2) -> 103028.

%% 获取充值送礼包活动开始与结束时间
%% ActionDay : 	开服或合服天数
%% ActionTime : 开服或合服时间
%% NeedDay : 	需要间隔天数
%% ActivityDay : 活动配置的天数
%% Start : 		活动配置的开始时间
%% End : 		活动配置的结束时间
private_get_recharge_award_time(ActionDay, ActionTime, NeedDay, Start, End) ->
	case ActionDay > NeedDay of
		true ->
			TmpStart = util:unixdate(ActionTime) + NeedDay * 86400,
			case TmpStart > Start andalso TmpStart < End of
				true ->
					[TmpStart, End];
				_ ->
					[Start, End]
			end;
		_ ->
			[0, 0]
	end.

private_get_finish_level([], _Type) ->
	0;
private_get_finish_level([{TypeId, Level} | T], Type) ->
	case Type =:= TypeId of
		true ->
			Level;
		_ ->
			private_get_finish_level(T, Type)
	end.

%% [等级向前冲] 格式化数据列表
private_format_level_forward(GetList) ->
	F = fun(P) ->
		[Level, _] = P,
		case lists:member(Level, GetList) of
			true ->
				<<Level:8, 1:8, 0:32>>;
			_ ->
				<<Level:8, 0:8, 0:32>>
		end
	end,
	[F(Param) || Param <- data_activity:get_award()].

%% [等级向前冲] 设置领取了奖励
private_level_forward_fetch_award(PS, Level) ->
	NewPS = case PS#player_status.activity#status_activity.level_forward of
		undefined ->
			Activity = PS#player_status.activity,
			NewActivity = Activity#status_activity{level_forward = [Level]},
			PS#player_status{activity = NewActivity};
		_ ->
			List = [Level | PS#player_status.activity#status_activity.level_forward],
			Activity = PS#player_status.activity,
			NewActivity = Activity#status_activity{level_forward = List},
			PS#player_status{activity = NewActivity}
	end,
	%% 更新数据库
	Update = util:term_to_string(NewPS#player_status.activity#status_activity.level_forward),
	db:execute(io_lib:format(?sql_activity_update3, [Update, PS#player_status.id, ?ACTIVITY_TYPE_3])),
	NewPS.

%% 发送收藏游戏奖励
private_send_collect_award(PS) ->
	db:execute(io_lib:format(?sql_activity_update, [PS#player_status.id, ?ACTIVITY_TYPE_1, 1])),
	NewPS = lib_player:add_money(PS, 50, bgold),
	%% 写货币日志
	log:log_produce(collect_game, bgold, PS, NewPS, ""),
	NewPS.

%% 发送登录器登录奖励
private_send_login_award(PS) ->
%% 	db:execute(io_lib:format(?sql_activity_update, [PS#player_status.id, ?ACTIVITY_TYPE_1, 1])),
	db:execute(io_lib:format(?sql_activity_update, [PS#player_status.id, 105, 1])),
	NewPS = lib_player:add_money(PS, 50, bgold),
	%% 写货币日志
	log:log_produce(login, bgold, PS, NewPS, ""),
	NewPS.

private_get_stat_by_type([], _Type) ->
	null;
private_get_stat_by_type([[FieldType, FieldContent] | Tail], Type) ->
	case FieldType =:= Type of
		true -> FieldContent;
		false ->
			private_get_stat_by_type(Tail, Type)
	end.

private_finish_payTask(PS, TaskId, PayTotal) ->
	NowTime = util:unixtime(),
	TriggerTime = lib_task:get_trigger_time(PS#player_status.tid, TaskId),
	case TriggerTime =/= false andalso TriggerTime =/=0 of
		true ->
			PayTaskTotal1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, TriggerTime, NowTime),
			PayTaskTotal2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, TriggerTime, NowTime),
			PayTaskTotal = PayTaskTotal1 + PayTaskTotal2,
			lib_task:event(PS#player_status.tid, pay_task_2, {PayTaskTotal}, PS#player_status.id);
		false ->
			case PayTotal > 0 of
				true -> lib_task:event(PS#player_status.tid, pay_task_2, {1}, PS#player_status.id);
				false -> skip
			end
	end.

count_31490(PS) ->
	OpenDay = util:get_open_day(),
	case OpenDay > 5 of
		true ->
			skip;
		_ ->
			{ok, Bin} = pt_314:write(31492, [1]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin)
	end.

%% 开服5天内充值活动
get_kf5_gift_num(PS) ->
	case db:get_row(io_lib:format(?sql_activity_data_get, [PS#player_status.id, ?ACTIVITY_RECHARGE_5_DAYS])) of
		[DataField, _AddTime] ->
			Data = util:to_term(DataField),
			case Data of
				[Num] ->
					Num;
				_ ->
					0
			end;
		_ ->
			NowTime = util:unixtime(),
			db:execute(io_lib:format(?sql_activity_data_insert, [PS#player_status.id, ?ACTIVITY_RECHARGE_5_DAYS, '[]', NowTime])),
			0
	end.

%% 开服5天内充值活动领取礼包
get_one_kf5_gigt(PS, TotalNum) ->
	NowTime = util:unixtime(),
	case db:transaction(fun() ->get_one_kf5_gigt_db(PS#player_status.id, TotalNum, NowTime) end) of
		1 ->
    		1;
		2 ->
			2;
		_Recharge ->
			0
	end.

%% 领取礼包事务
get_one_kf5_gigt_db(PlayerId, TotalNum, NowTime) ->
	case db:get_row(io_lib:format(?sql_activity_data_get, [PlayerId, ?ACTIVITY_RECHARGE_5_DAYS])) of
		[DataField, _AddTime] ->
			Data = util:to_term(DataField),
			case Data of
				[Num] ->
					NowNum = TotalNum - Num,
					case NowNum >= 0 of
						true ->
							NewNum = util:term_to_string([Num + 1]),
							db:execute(io_lib:format(?sql_activity_data_insert, [PlayerId, ?ACTIVITY_RECHARGE_5_DAYS, NewNum, NowTime])),
							1;
						_ ->
							2
					end;
				[] ->
					NowNum = TotalNum - 0,
					case NowNum >= 0 of
						true ->
							NewNum = util:term_to_string([0 + 1]),
							db:execute(io_lib:format(?sql_activity_data_insert, [PlayerId, ?ACTIVITY_RECHARGE_5_DAYS, NewNum, NowTime])),
							1;
						_ ->
							2
					end;
				_ ->
					2
			end;
		_ ->
			2
	end.

