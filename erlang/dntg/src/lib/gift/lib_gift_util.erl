%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-31
%% Description: 活动礼包工具类
%% --------------------------------------------------------
-module(lib_gift_util).
-compile(export_all).
-include("def_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("gift.hrl").
-include("server.hrl").
-include("sql_goods.hrl").

get_gift_cell(GiftInfo, GiftNum) ->
	if GiftInfo#ets_gift.gift_rand =:= 1 -> %随机
		   GiftNum;
	   GiftInfo#ets_gift.gift_rand =:= 2 -> %列表随机
		   {list, List, _} = lists:nth(1, GiftInfo#ets_gift.gifts),
		   if
			   length(GiftInfo#ets_gift.gifts) > 0 ->
				   Sum = lists:foldl(fun get_gifts_cell/2, 0, List),
				   Sum * GiftNum;
			   true ->
				   GiftNum
		   end;
	   true ->
		   Sum = lists:foldl(fun get_gifts_cell/2, 0, GiftInfo#ets_gift.gifts),
		   Sum * GiftNum
	end.
get_gifts_cell(Item, Sum) ->
	case Item of
		{goods, _, _} ->
			Sum + 1;
		{equip, _, _} ->
			Sum + 1;
		_ ->
			Sum
	end.

add_online_gift(PlayerId, GiftId) ->
	case get_gift_queue(PlayerId, GiftId) of
		[] ->
			add_gift(PlayerId, GiftId, 0);
		_ ->
			mod_give(PlayerId, GiftId, util:unixtime(), 0)
	end.

get_gift_queue(PlayerId, GiftId) ->
    Sql = io_lib:format(?SQL_GIFT_QUEUE_SELECT, [PlayerId, GiftId]),
    db:get_row(Sql).

add_gift(PlayerId, GiftId, Status) ->
    Sql = io_lib:format(?SQL_GIFT_QUEUE_INSERT, [PlayerId, GiftId, util:unixtime(), Status]),
    db:execute(Sql).

mod_give(PlayerId, GiftId, GiveTime, Status) ->
    Sql = io_lib:format(?SQL_GIFT_QUEUE_UPDATE_GIVE, [GiveTime, Status, PlayerId, GiftId]),
    db:execute(Sql).

add_npc_gift(PlayerId, GiftId) ->
    NowTime = util:unixtime(),
    Sql = io_lib:format(?SQL_GIFT_QUEUE_INSERT_FULL, [PlayerId, GiftId, NowTime, 1, NowTime, 1]),
    db:execute(Sql).

add_gift_card(PlayerId, Card, Type) ->
    Sql = io_lib:format(?SQL_GIFT_CARD_INSERT, [PlayerId, Card, Type, util:unixtime()]),
    db:execute(Sql).

get_base_gift_card(Accname) ->
    Sql = io_lib:format(?SQL_GIFT_CARD_BASE_SELECT, [Accname]),
    db:get_row(Sql).

get_gift_card(Card) ->
    Sql = io_lib:format(?SQL_GIFT_CARD_SELECT, [Card]),
    db:get_row(Sql).

get_charge(PlayerId) ->
    Sql = io_lib:format(?SQL_CHARGE_SELECT, [PlayerId]),
    db:get_row(Sql).

%% 检查是否充值
check_charge(PlayerId) ->
    case get_charge(PlayerId) of
        [Id] when Id > 0 -> true;
        _ -> false
    end.
