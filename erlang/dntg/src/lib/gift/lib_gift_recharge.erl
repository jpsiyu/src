%%%--------------------------------------
%%% @Module  : lib_gift_recharge
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.3
%%% @Description: 新服充值礼包
%%%--------------------------------------

-module(lib_gift_recharge).
-compile(export_all).
-include("server.hrl").
-include("gift.hrl").

%% [限时回馈礼包] 打开面板请求需要的数据
get_data(PS) ->
	%% 总充值元宝数
	TotalRecharge = lib_recharge:get_total(PS#player_status.id),
	%% 活动剩余秒数
	LeftTime = util:get_open_time() + 7 * 86400 - util:unixtime(),
	LeftTime2 = case LeftTime > 0 of
		true -> LeftTime;
		_ -> 0
	end,

	%% 获取礼包的领取情况
	GiftIds = data_gift_config:get_recharge_giftids(),
	Sql =  io_lib:format(?SQL_GIFT_LIST_FETCH_MUTIL_ROW, [PS#player_status.id, GiftIds]),
	L = case db:get_all(Sql) of
		[] ->
			F = fun(Id) ->
				<<Id:32, 0:8>>
			end,
			[F(GiftId) || GiftId <- data_gift_config:get_recharge_giftids_list()];
		List ->
			NewList = [GiftId || [_, GiftId, Status] <- List, Status =:=1],
			
			F2 = fun(GtId, GtList) ->
				case lists:member(GtId, GtList) of
					true ->
						<<GtId:32, 1:8>>;
					_ ->
						<<GtId:32, 0:8>>
				end
			end,
			[F2(GId, NewList) || GId <- data_gift_config:get_recharge_giftids_list()]
	end,
	[TotalRecharge, LeftTime2, L].

%% [限时回馈礼包] 领取礼包
fetch_gift(PS, GiftId) ->
	case lib_gift_new:get_gift_fetch_status(PS#player_status.id, GiftId) of
		-1 ->
			[Result] = lists:filter(fun(Item) -> 
				[_, ReGiftId] = Item,
				if 
					ReGiftId =:= GiftId -> true;
					true -> false
				end
			end, data_gift_config:get_recharge_data()),
			case Result of
				[] ->
					{error, ?ERROR_GIFT_999};
				[Recharge, _] ->
					TotalRecharge = lib_recharge:get_total(PS#player_status.id),
					case TotalRecharge < Recharge of
						%% 充值元宝数不足
						true ->
							{error, 3};
						_ ->
							G = PS#player_status.goods,
							case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
								{ok, [ok, NewPS]} ->
									lib_gift_new:trigger_finish(PS#player_status.id, GiftId),
									{ok, NewPS};
								{ok, [error, ErrorCode]} ->
									{error, ErrorCode}
							end
					end;
				_ ->
					{error, ?ERROR_GIFT_999}
			end;

		%% 已经领取了礼包
		_ ->
			{error, 2}
	end.
