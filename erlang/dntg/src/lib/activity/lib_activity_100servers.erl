%%%--------------------------------------
%%% @Module  : lib_activity_100servers
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2013.3.12
%%% @Description: 平台100服活动
%%%--------------------------------------

-module(lib_activity_100servers).
-include("server.hrl").
-include("activity.hrl").
-compile(export_all).
-define(HUNDRED_CONF_TYPE, 1).
-define(HUNDRED_CACHE_KEY, lib_activity_100servers).

%% 获取配置
get_conf() ->
	case mod_daily_dict:get_special_info(?HUNDRED_CACHE_KEY) of
		[Gold, GiftId, StartTime, EndTime] ->
			[Gold, GiftId, StartTime, EndTime];
		_ ->
			Sql = <<"SELECT content FROM activity_conf WHERE type=~p">>,
			case db:get_one(io_lib:format(Sql, [?HUNDRED_CONF_TYPE])) of
				null -> 
					[];
				Content ->
					util:bitstring_to_term(Content)
			end
	end.

%% 开启活动
start_activity(Gold, GiftId, StartTime, EndTime) ->
	NowTime = util:unixtime(),
	case NowTime >= EndTime of
		true ->
			ok;
		_ ->
			Value = [Gold, GiftId, StartTime, EndTime],

			%% 入库
			Content = util:term_to_string(Value),
			Sql = <<"REPLACE INTO activity_conf SET type=~p, content='~s'">>,
			db:execute(io_lib:format(Sql, [?HUNDRED_CONF_TYPE, Content])),

			%% 保存到缓存中
			mod_daily_dict:set_special_info(?HUNDRED_CACHE_KEY, Value),

			%% 如果是在活动期间内，则发协议出现图标
			case NowTime >= StartTime andalso NowTime =< EndTime of
				true ->
					{ok, Bin} = pt_314:write(31480, [?ACTIVITY_100_SERVERS, 0, 1]),
					lib_server_send:send_to_all(Bin),
					ok;
				_ ->
					ok
			end
	end.

%% 打开面板需要的数据
get_data(PS) ->
	case get_conf() of
		[Gold, GiftId, StartTime, EndTime] ->
			Total1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, StartTime, EndTime),
			Total2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, StartTime, EndTime),
			FetchStatus = case lib_gift_new:get_gift_fetch_status(PS#player_status.id, GiftId) of
				1 -> 1;
				_ -> 0
			end,
			{ok, Bin} = pt_310:write(31020, [Gold, Total1 + Total2, EndTime, GiftId, FetchStatus]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		_ ->
			skip
	end.

%% 领取奖励
fetch_award(PS) ->
	case get_conf() of
		[Gold, GiftId, StartTime, EndTime] ->
			NowTime = util:unixtime(),
			case NowTime >= StartTime andalso NowTime =< EndTime of
				true ->
					Total1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, StartTime, EndTime),
					Total2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, StartTime, EndTime),
					case Total1 + Total2 >= Gold of
						true ->
							case lib_gift_new:get_gift_fetch_status(PS#player_status.id, GiftId) of
								1 -> 
									%% 已经领取奖励
									{error, 5};
								_ -> 
									G = PS#player_status.goods,
									case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
										{ok, [ok, NewPS]} ->
											lib_gift_new:trigger_finish(PS#player_status.id, GiftId),
											lib_activity:finish_activity(NewPS, ?ACTIVITY_100_SERVERS),
											{ok, GiftId};
										{ok, [error, ErrorCode]} ->
											{error, ErrorCode};
										_ ->
											{error, 999}
									end
							end;
						_ ->
							%% 充值不足
							{error, 4}
					end;
				_ ->
					%% 不在活动期间内
					{error, 3}
			end;
		_ ->
			%% 活动没配置
			{error, 2}
	end.

