%%%--------------------------------------
%%% @Module  : lib_gift_new
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.3
%%% @Description: 礼包相关代码（新版）
%%%--------------------------------------

-module(lib_gift_new).
-include("def_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("gift.hrl").
-include("server.hrl").
-include("sql_goods.hrl").
-include("unite.hrl").
-export([
	base_check_gift/1,			%% 礼包简单判断
	update_to_received/2,		%% 更新礼包为领取状态（修改表并加缓存）
	set_gift_fetch_status/3,	%% 设置礼包领取状态（只加缓存）
	use_gift/5,					%% 在背包中打开礼包，goods进程会调用该方法
	fetch_gift_in_good/3,		%% 在物品进程中调用领取礼包的方法
	get_gift_length/1,			%% 取得礼包需要的格子数
	get_gift_fetch_status/2,	%% 获取礼包领取状态
	send_goods_notice_msg/2,	%% 右下角显示获得具体什么物品
	trigger_fetch/2,			%% 触发达成礼包，但状态为未领取
	trigger_finish/2,			%% 触发达成礼包，状态为已经领取
	get_goodsid_by_giftid/1		%% 通过礼包ID获得物品ID
]).

%% 礼包简单判断
%% @praram	GiftInfo	礼包数据#ets_gift
%% @return	{error, 错误码} | {ok}
%% 		错误码：	100 礼包数据不存在
%%				101 礼包状态为无效
%%				102 未到领取礼包时间
%%				103 已过了领取礼包时间
base_check_gift(GiftInfo) ->
	case is_record(GiftInfo, ets_gift) of
		true ->
			case GiftInfo#ets_gift.status =:= 0 of
				true ->
					%% 礼包状态为无效
					 {error, ?ERROR_GIFT_101};
				_ ->
					NowTime = util:unixtime(),
					if 
						%% 未到领取礼包时间
						(GiftInfo#ets_gift.start_time > 0) and (NowTime < GiftInfo#ets_gift.start_time) ->
							{error, ?ERROR_GIFT_102}; 
						%% 已过了领取礼包时间
						(GiftInfo#ets_gift.end_time > 0) and (NowTime > GiftInfo#ets_gift.end_time) ->
							{error, ?ERROR_GIFT_103}; 
						true ->
							{ok}
					end
			end;
		_ ->
			%% 礼包数据不存在
			{error, ?ERROR_GIFT_100}
	end.

%% 更新礼包为领取状态（修改表并加缓存）
update_to_received(PlayerId, GiftId) ->
    Sql = io_lib:format(?SQL_GIFT_LIST_UPDATE_TO_RECEIVED, [util:unixtime(), PlayerId, GiftId]),
    db:execute(Sql),
    set_gift_fetch_status(PlayerId, GiftId, 1).

%% [推荐使用] 在物品进程中调用领取礼包的方法
%% 调用代码如：gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) 
fetch_gift_in_good(PS, GS, GiftId) ->
	%% 获得礼包配置
	GiftInfo = data_gift:get(GiftId),

	%% 对礼包数据作最基本的检查
	case base_check_gift(GiftInfo) of
		{ok} ->
			if
				%% 礼包放在背包
				GiftInfo#ets_gift.get_way =:= 1 ->
					case private_gift_to_package(GS, GiftInfo) of
						{ok, NewGS} ->
							{ok, PS, NewGS};
						{error, ErrorCode} ->
						    {error, ErrorCode}
					end;
				%% 直接领取礼包内物品
				true ->
					case length(GS#goods_status.null_cells) >= get_gift_length(GiftInfo) of
						true ->
							{ok, NewPS, NewGS} = private_gift_to_open_in_goods(PS, GS, GiftInfo),
							{ok, NewPS, NewGS};
						_ ->
							%% 格子数不足
							{error, 105}
					end
			end;
		{error, ErrorCode} ->
			{error, ErrorCode}
	end.

%% [游戏线] 在背包中打开礼包，goods进程会调用该方法
%% 在该方法里面，不能再去调用goods进程的方法
%% 
%% PS					#player_status
%% GS					#status_goods
%% GoodsInfo	物品数据
%% GiftInfo			#ets_gift
%% GoodsNum	使用的物品数量
use_gift(PS, GS, GoodsInfo, GiftInfo, GoodsNum) ->
	NowTime = util:unixtime(),

	%% 判断礼包是否已经过期
	case GiftInfo#ets_gift.start_time > 0 andalso NowTime < GiftInfo#ets_gift.start_time of
		true ->
			{error, time_not_reach};
		_ ->
			case GiftInfo#ets_gift.end_time > 0 andalso GiftInfo#ets_gift.end_time < NowTime of
				true ->
					{error, time_overdue};
				_ ->
					NullLen = length(GS#goods_status.null_cells),
					GoodsLen = get_gift_length(GiftInfo),
					case NullLen >= GoodsLen of
						true ->
							F = fun() ->
								ok = lib_goods_dict:start_dict(),
								%% 先删除本礼包
								[NewStatus, _] = lib_goods:delete_one(GoodsInfo,[GS, GoodsNum]),
								NewNum = GoodsInfo#goods.num - GoodsNum,
								NewGiftInfo = GiftInfo#ets_gift{bind = GoodsInfo#goods.bind},
				
								%% 是否是VIP礼包
								case GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_GIFT_VIP of
									true ->
										{ok, NewPS, NewGoodsStatus, GiveList} = private_open_vip_gift(PS, NewStatus, NewGiftInfo),
										mod_daily:increment(PS#player_status.dailypid, PS#player_status.id, ?GOODS_VIP_COUNTER_TYPE);
									false ->
										GiftList = private_rand_goods(GiftInfo),
										[_, NewPS, NewGoodsStatus, _, GiveList, _, _] = lists:foldl(
											fun private_give_gift_item/2, 
											[GiftInfo, PS, NewStatus, GiftInfo#ets_gift.bind, [], 0, []],
											GiftList
										),
										update_to_received(PS#player_status.id, GiftInfo#ets_gift.id)
								end,
				
								D = lib_goods_dict:handle_dict(NewGoodsStatus#goods_status.dict),
								NewGoodsStatus1 = NewGoodsStatus#goods_status{dict = D},
				
								%% 发送获得物品信息给客户端显示在右下角
								send_goods_notice_msg(PS, GiveList),
								
								%% 写开礼包日志
								About = lists:concat([lists:concat([Id,":",Num,","]) || {Id, Num} <- private_get_log_about(GiveList)]),
								log:log_gift(PS#player_status.id, 0, GiftInfo#ets_gift.goods_id, GiftInfo#ets_gift.id, About),
				
								{ok, NewPS, NewGoodsStatus1, NewNum, GiveList}
							end,
							case lib_goods_util:transaction(F) of
								{ok, LastNewPS, LastNewGoodsStatus1, LastNewNum, LastGiveList} ->
									%% 如果开到珍贵物品，则发传闻
									private_get_valuable_send_tv(LastNewPS, GiftInfo, LastGiveList),
									{ok, LastNewPS, LastNewGoodsStatus1, LastNewNum, LastGiveList};
								Err ->
									{error, Err}
							end;
						_ ->
							{error, not_enough}
					end
			end
	end.

%% 得取礼包物品的长度(包括道具和装备)
get_gift_length(GiftInfo) ->
    case GiftInfo#ets_gift.gift_rand of
        %% 如果是随机物品礼包，例如红包，只会发一个物品
        1 -> 1;
		%% 固定物品 + 物品随机（物品不包括装备）
		3 -> 
			case GiftInfo#ets_gift.gifts of
				[FixList, _RankList] ->
					[FixEquipList, FixEquipList] = lists:foldl(fun private_collect_gift_goods_item/2, [[],[]], FixList),
	        		length(FixEquipList) + length(FixEquipList) + 1;
				_ ->
					1
			end;
		%% 固定物品 + 列表随机
		4 -> 
			case GiftInfo#ets_gift.gifts of
				[FixList, _RankList] ->
					[FixEquipList, FixGoodsList] = lists:foldl(fun private_collect_gift_goods_item/2, [[],[]], FixList),
	        		length(FixEquipList) + length(FixGoodsList) + 1;
				_ ->
					1
			end;
        _ ->
	        [EquipList, GoodsList] = lists:foldl(fun private_collect_gift_goods_item/2, [[],[]], GiftInfo#ets_gift.gifts),
	        length(EquipList) + length(GoodsList)
    end.

%% 获取礼包领取状态
%% 返回：-1未领取（未插入记录），0未领取（已经插入记录），1已经领取
get_gift_fetch_status(RoleId, GiftId) ->
	CacheKey = ?GIFT_CACHE_KEY(RoleId, GiftId),
	Result = mod_daily_dict:get_special_info(CacheKey),
	case Result of
		undefined ->
			Sql = io_lib:format(?SQL_GIFT_LIST_FETCH_ROW, [RoleId, GiftId]),
			case db:get_row(Sql) of
				[] ->
					mod_daily_dict:set_special_info(CacheKey, -1),
					-1;
				[_, _, Status] ->
					%% Status 0为未领取，1为领取
					mod_daily_dict:set_special_info(CacheKey, Status),
					Status
			end;
		Data ->
			Data
	end.

%% 设置礼包领取状态
set_gift_fetch_status(RoleId, GiftId, Status) ->
	mod_daily_dict:set_special_info(?GIFT_CACHE_KEY(RoleId, GiftId), Status).

%% 触发达成礼包，状态为未领取奖励
trigger_fetch(RoleId, GiftId) ->
	Now = util:unixtime(),
	Sql = io_lib:format(?SQL_GIFT_LIST_INSERT, [RoleId, GiftId, Now, Now, 0, 0]),
	db:execute(Sql),
	mod_daily_dict:set_special_info(?GIFT_CACHE_KEY(RoleId, GiftId), 0).

%% 触发达成礼包，状态为已经领取
trigger_finish(RoleId, GiftId) ->
	Now = util:unixtime(),
	Sql = io_lib:format(?SQL_GIFT_LIST_INSERT, [RoleId, GiftId, Now, Now, 1, 1]),
	db:execute(Sql),
	mod_daily_dict:set_special_info(?GIFT_CACHE_KEY(RoleId, GiftId), 1).

%% 发送获得物品信息给客户端显示在右下角
send_goods_notice_msg(PS, GiveList) ->
	F = fun(Item, Data) ->
		case Item of
			{goods, GoodsTypeId, GoodsNum} ->
				[<<GoodsTypeId:32, GoodsNum:32>> | Data];
			{equip, GoodsTypeId, _, _} ->
				[<<GoodsTypeId:32, 1:32>> | Data];
			_ ->
				Data
		end
	end,
	NewList = lists:foldl(F, [], GiveList),
	case length(NewList) > 0 of
		true ->
			{ok, BinData} = pt_110:write(11060, NewList),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		_ ->
			skip
	end.

%% 通过礼包id获得物品id
get_goodsid_by_giftid(GiftId) ->
	case data_gift:get(GiftId) of
		[] -> 0;
		Gift -> Gift#ets_gift.goods_id
	end.

%% 打开vip礼包
private_open_vip_gift(PlayerStatus, GoodsStatus, GiftInfo) ->
	GoodsCount = length(GiftInfo#ets_gift.gifts),
	Rand = util:rand(1, GoodsCount),
	GoodsItem = lists:nth(Rand, GiftInfo#ets_gift.gifts),
	%% 礼包的发放
	[_, NewPlayerStatus, NewGoodsStatus, _, GiveList, _, _] = private_give_gift_item(GoodsItem, [GiftInfo, PlayerStatus, GoodsStatus, GiftInfo#ets_gift.bind, [], 0, []]),
    {ok, NewPlayerStatus, NewGoodsStatus, GiveList}.

%% 具体处理礼包配置的各种属性奖励或物品奖励
%% IsFetchGoods	该项值只针对物品或者装备，对其他配的没影响。值0：会获取物品和装备  1：不会获取物品和装备  2：不会获取装备 
private_give_gift_item(Item, [_GiftInfo, PlayerStatus, GoodsStatus, Bind, GiveList, IsFetchGoods, GoodsList]) ->
	case Item of
		%加经验
		{exp, Exp1, Exp2} -> 
            Exp = util:rand(Exp1, Exp2),
            NewPlayerStatus = lib_player:add_exp(PlayerStatus, Exp, 0),
            [_GiftInfo, NewPlayerStatus, GoodsStatus, Bind, [{exp,Exp}|GiveList], IsFetchGoods, GoodsList];

		%元宝
		{gold, Gold1, Gold2} -> 
			Gold = util:rand(Gold1, Gold2),
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, Gold, gold),
			%% 写货币日志
			log:log_produce(gift, gold, PlayerStatus, NewPlayerStatus, lists:concat(["GiftId=", _GiftInfo#ets_gift.id, ", Money=", Gold])),
            [_GiftInfo, NewPlayerStatus, GoodsStatus, Bind, [{gold,Gold}|GiveList], IsFetchGoods, GoodsList];

		%绑定元宝
		{silver, Silver1, Silver2} ->
            Silver = util:rand(Silver1, Silver2),
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, Silver, bgold),
			%% 写货币日志
			log:log_produce(gift, bgold, PlayerStatus, NewPlayerStatus, lists:concat(["GiftId=", _GiftInfo#ets_gift.id, ", Money=", Silver])),
            [_GiftInfo, NewPlayerStatus, GoodsStatus, Bind, [{silver,Silver}|GiveList], IsFetchGoods, GoodsList];

		 %铜钱
		{coin, Coin1, Coin2} ->
            Coin = util:rand(Coin1, Coin2),
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, Coin, coin),
			%% 写货币日志
			log:log_produce(gift, coin, PlayerStatus, NewPlayerStatus, lists:concat(["GiftId=", _GiftInfo#ets_gift.id, ", Money=", Coin])),
            [_GiftInfo, NewPlayerStatus, GoodsStatus, Bind, [{coin,Coin}|GiveList], IsFetchGoods, GoodsList];

		%绑定铜钱
		{bcoin, Bcoin1, Bcoin2} ->
            Bcoin = util:rand(Bcoin1, Bcoin2),
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, Bcoin, coin),
			%% 写货币日志
			log:log_produce(gift, coin, PlayerStatus, NewPlayerStatus, lists:concat(["GiftId=", _GiftInfo#ets_gift.id, ", Money=", Bcoin])),
            [_GiftInfo, NewPlayerStatus, GoodsStatus, Bind, [{coin,Bcoin}|GiveList], IsFetchGoods, GoodsList];

		%物品
		{goods, GoodsTypeId, GoodsNum} ->
            GoodsTypeInfo = data_goods_type:get(GoodsTypeId),
            NewInfo = lib_goods_util:get_new_goods(GoodsTypeInfo),
            case Bind > 0 of
				%%已绑定不可交易
                true -> GoodsInfo = NewInfo#goods{bind=2, trade=1};
                false -> GoodsInfo = NewInfo
            end,
			if
				IsFetchGoods =:= 0 ->
					 {ok, NewStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo),
					 [_GiftInfo, PlayerStatus, NewStatus, Bind, [Item | GiveList], IsFetchGoods, GoodsList];
				IsFetchGoods =:= 2 ->
					{ok, NewStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo),
					[_GiftInfo, PlayerStatus, NewStatus, Bind, [Item | GiveList], IsFetchGoods, GoodsList];
				true ->
					NewStatus = GoodsStatus,
					[_GiftInfo, PlayerStatus, NewStatus, Bind, [Item|GiveList], IsFetchGoods, [Item|GoodsList]]
			end;

		%装备
		{equip, GoodsTypeId, Prefix1, Prefix2} ->
            TypeId = case is_list(GoodsTypeId) of
                 true -> lists:nth(PlayerStatus#player_status.career, GoodsTypeId);
                 false -> GoodsTypeId
             end,
            GoodsTypeInfo = data_goods_type:get(TypeId),
            NewInfo = lib_goods_util:get_new_goods(GoodsTypeInfo),
            Prefix = case Prefix1 =:= 0 andalso Prefix2 > 0 of
                 true -> data_goods:rand_prefix(Prefix2);
                 false -> util:rand(Prefix1, Prefix2)
             end,

            case Bind > 0 of
				%%已绑定不可交易
                true -> GoodsInfo = NewInfo#goods{bind=2, trade=1, prefix=Prefix};
                false -> GoodsInfo = NewInfo#goods{prefix=Prefix}
            end,
			if
				IsFetchGoods =:= 0 ->
					{ok, NewStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, 1, GoodsInfo, []);
				true ->
					NewStatus = GoodsStatus
			end,
            [_GiftInfo, PlayerStatus, NewStatus, Bind, [{equip, TypeId, Prefix, 0}|GiveList], IsFetchGoods, [{equip, TypeId, Prefix, 0}|GoodsList]];

		%%礼包
        {gift, GiftId} ->
            lib_gift_util:add_gift(PlayerStatus#player_status.id, GiftId, 1),
            GiftList = [GiftId | GoodsStatus#goods_status.gift_list],
            NewStatus = GoodsStatus#goods_status{gift_list = GiftList},
            [PlayerStatus, NewStatus, Bind, GiveList, IsFetchGoods, GoodsList];
        _ ->
            [_GiftInfo, PlayerStatus, GoodsStatus, Bind, GiveList, IsFetchGoods, GoodsList]
    end.

%% 将礼包放进背包，不打开礼包的东西
private_gift_to_package(GS, GiftInfo) ->
	GoodsTypeId = GiftInfo#ets_gift.goods_id,
	F = fun() ->
		ok = lib_goods_dict:start_dict(),
		{ok, NewGS} = lib_goods:give_goods({GoodsTypeId, 1}, GS),
		Dict = lib_goods_dict:handle_dict(NewGS#goods_status.dict),
        	NewGS2 = NewGS#goods_status{dict = Dict},
        	{ok, NewGS2}
	end,
	case lib_goods_util:transaction(F) of
		{ok, GoodsStatus} ->
			{ok, GoodsStatus};
		%% 物品类型不存在
		{db_error, {error, {_Type, not_found}}} ->
			{error, ?ERROR_GIFT_104};
		%% 背包格子不足
		{db_error, {error, {cell_num, not_enough}}} ->
			{error, ?ERROR_GIFT_105};
		_ ->
			{error, ?ERROR_GIFT_999}
	end.

%% 直接打开礼包获取里面的物品
private_gift_to_open_in_goods(PS, GS, GiftInfo) ->
	F = fun() ->
		GiftList = private_rand_goods(GiftInfo),
		[_, NewPS, NewGS, _, GiveList, _, _] = lists:foldl(
			fun private_give_gift_item/2, 
			[GiftInfo, PS, GS, GiftInfo#ets_gift.bind, [], 0, []],
			GiftList
		),

		%% 写开礼包日志
		About = lists:concat([lists:concat([Id,":",Num,","]) || {Id, Num} <- private_get_log_about(GiveList)]),
		log:log_gift(PS#player_status.id, 0, GiftInfo#ets_gift.goods_id, GiftInfo#ets_gift.id, About),

		%% 发送获得物品信息给客户端显示在右下角
		send_goods_notice_msg(PS, GiveList),

		{ok, NewPS, NewGS}
	end,
	lib_goods_util:transaction(F).

private_get_log_about(GiveList) ->
    [Exp, Gold, Silver, Coin, Bcoin, GoodsList, _] = lists:foldl(fun private_get_gift_item_notice/2, [0,0,0,0,0,[], 0], GiveList),
    [{exp,Exp}, {coin,Coin}, {bcoin,Bcoin}, {gold,Gold}, {silver,Silver} | GoodsList].

private_get_gift_item_notice(Item, [Exp1, Gold1, Silver1, Coin1, Bcoin1, GoodsList1, Career]) ->
    case Item of
        {exp, Exp2} -> 
			[Exp2, Gold1, Silver1, Coin1, Bcoin1, GoodsList1, Career];
        {gold, Gold2} -> 
			[Exp1, Gold2, Silver1, Coin1, Bcoin1, GoodsList1, Career];
        {silver, Silver2} -> 
			[Exp1, Gold1, Silver2, Coin1, Bcoin1, GoodsList1, Career];
        {coin, Coin2} -> 
			[Exp1, Gold1, Silver1, Coin2, Bcoin1, GoodsList1, Career];
        {bcoin, Bcoin2} -> 
			[Exp1, Gold1, Silver1, Coin1, Bcoin2, GoodsList1, Career];
        {goods, GoodsTypeId2, GoodsNum2} -> 
			[Exp1, Gold1, Silver1, Coin1, Bcoin1, [{GoodsTypeId2, GoodsNum2}|GoodsList1], Career];
        {equip, TypeIdList, _, _} when is_list(TypeIdList) ->
            GoodsTypeId2 = lists:nth(Career, TypeIdList),
            [Exp1, Gold1, Silver1, Coin1, Bcoin1, [{GoodsTypeId2, 1}|GoodsList1], Career];
        {equip, GoodsTypeId2, _, _} -> 
			[Exp1, Gold1, Silver1, Coin1, Bcoin1, [{GoodsTypeId2, 1}|GoodsList1], Career];
        _ -> 
			[Exp1, Gold1, Silver1, Coin1, Bcoin1, GoodsList1, Career]
    end.

%% 处理礼包配置物品的随机类型
private_rand_goods(GiftInfo) ->
	if
		%% 物品随机（物品不包括装备）
		%% 找出礼包中有多少是物品，然后在这么多物品中，随机取出一个物品，再加上其他非物品的东西
		GiftInfo#ets_gift.gift_rand =:= 1 -> 
			[EquipList, GoodsList] = lists:foldl(fun private_collect_gift_item/2, [[],[]], GiftInfo#ets_gift.gifts),
			GoodsCount = length(GoodsList),
			GiftList = case util:rand(1, GoodsCount) of
				0 -> EquipList;
				Rand ->
					GoodsItem = lists:nth(Rand, GoodsList),
					[GoodsItem|EquipList]
			end;

		%% 列表随机，随机其中一种物品
	   	GiftInfo#ets_gift.gift_rand =:= 2 -> 
			TotalRatio = lib_goods_util:get_ratio_total(GiftInfo#ets_gift.gifts, 3),
           	Rand = util:rand(1, TotalRatio),
		   	case lib_goods_util:find_ratio(GiftInfo#ets_gift.gifts, 0, Rand, 3) of
				null -> GiftList = [];
                {list, GiftList, _} -> ok
            end;

		%% 固定物品 + 物品随机（物品不包括装备）
		GiftInfo#ets_gift.gift_rand =:= 3 -> 
			case GiftInfo#ets_gift.gifts of
				[FixList, RankList] ->
					TotalRatio = lib_goods_util:get_ratio_total(RankList, 3),
		           	Rand = util:rand(1, TotalRatio),
				   	case lib_goods_util:find_ratio(RankList, 0, Rand, 3) of
						null -> GiftList = FixList;
		                {list, TmpGiftList, _} -> GiftList = FixList ++ TmpGiftList
		            end;
				_ ->
					GiftList = []
			end;

		%% 固定物品 + 列表随机
		GiftInfo#ets_gift.gift_rand =:= 4 -> 
			case GiftInfo#ets_gift.gifts of
				[FixList, RankList] ->
					TotalRatio = lib_goods_util:get_ratio_total(RankList, 3),
		           	Rand = util:rand(1, TotalRatio),
				   	case lib_goods_util:find_ratio(RankList, 0, Rand, 3) of
						null -> GiftList = FixList;
		                {list, TmpGiftList, _} -> 
							GiftList = FixList ++ TmpGiftList
		            end;
				_ ->
					GiftList = []
			end;

		%% 固定物品
		true ->
    		GiftList = GiftInfo#ets_gift.gifts
    end,
	GiftList.

%% 将物品与装备放到各自的数组中
private_collect_gift_item(Item, [EquipList, GoodsList]) ->
	case Item of
		{goods, GoodsTypeId, GoodsNum} ->
			[EquipList, [{goods, GoodsTypeId, GoodsNum} | GoodsList]];
		{equip, GoodsTypeId, Prefix1, Prefix2} ->
			[[{equip, GoodsTypeId, Prefix1, Prefix2} | EquipList], GoodsList];
		_ ->
			[[Item|EquipList], GoodsList]
	end.

%% 将物品与装备放到各自的数组中
private_collect_gift_goods_item(Item, [EquipList, GoodsList]) ->
	case Item of
		{goods, GoodsTypeId, GoodsNum} ->
			[EquipList, [{goods, GoodsTypeId, GoodsNum} | GoodsList]];
		{equip, GoodsTypeId, Prefix1, Prefix2} ->
			[[{equip, GoodsTypeId, Prefix1, Prefix2}|EquipList], GoodsList];
		_ ->
			[EquipList, GoodsList]
	end.

%% 如果礼包开到珍贵物品（紫水晶橙水晶和玄冰石）则发传闻
private_get_valuable_send_tv(PS, Gift, GiveList) ->
	TvGoodIds = Gift#ets_gift.tv_goods_id,
	lists:foreach(fun(Item) -> 
		case Item of
			{goods, GoodsTypeId, _GoodsNum} ->
				case lists:member(GoodsTypeId, TvGoodIds) of
					true ->
						lib_chat:send_TV({all}, 0, 2, [
							"openRareItem", PS#player_status.id, PS#player_status.realm, PS#player_status.nickname,
							PS#player_status.sex, PS#player_status.career, 0, Gift#ets_gift.id, GoodsTypeId
						]);
					_ ->
						skip
				end;
			_ ->
				skip
		end
	end, GiveList).
