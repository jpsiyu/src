%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-31
%% Description: 活动礼包操作类
%% --------------------------------------------------------

-module(lib_gift).
-compile(export_all).
-include("def_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("gift.hrl").
-include("server.hrl").
-include("sql_goods.hrl").
-include("unite.hrl").

%% 查询领取礼包表所有记录出来，方便登录时需要判断的地方共用
get_all_record(PlayerId) ->
	Sql = io_lib:format(?SQL_GIFT_FETCH_ALL, [PlayerId]),
    db:get_all(Sql).

%% 获取已经获取的等级礼包列表
get_level_gift_list(PlayerId) ->
	GiftIds = lists:concat([?PET_LEVEL_GIFT_ID, ",", ?FRIENDID_GIFT_ID, ",", ?MOUNT_LEVEL_GIFT_ID, ",", 
					?MODULE_OPEN_MIND, ",", ?MODULE_OPEN_GUILD, ",", ?MODULE_OPEN_MARKET, ",", 
					?MODULE_OPEN_DAILY, ",", ?MODULE_OPEN_STREN, ",", ?MODULE_OPEN_STONE, ",", 
					?MODULE_OPEN_LIANLU, ",", ?MODULE_OPEN_GUILD, ",", ?MODULE_OPEN_MIND, ",", 
					?MODULE_OPEN_TAOBAO]),
	Sql =  io_lib:format(?SQL_GIFT_LIST_FETCH_MUTIL_ROW, [PlayerId, GiftIds]),
	case db:get_all(Sql) of
		[] ->
			[];
		List ->
			F = fun(GId) ->
				<<GId:32>>	
			end,
			[F(GiftId) || [_Id, GiftId, Status] <- List, Status=:=1]
	end.

%% 更新礼包为已经领取状态
update_to_received(PlayerId, GiftId) ->
    Sql = io_lib:format(?SQL_GIFT_LIST_UPDATE_TO_RECEIVED, [util:unixtime(), PlayerId, GiftId]),
    db:execute(Sql).

%% 首次触发即完成礼包领取
%% 将插入一条礼包记录，状态为已领取奖励
trigger_finish(PlayerId, GiftId) ->
	Now = util:unixtime(),
	Sql = io_lib:format(?SQL_GIFT_LIST_INSERT, [PlayerId, GiftId, Now, Now, 1, 1]),
    db:execute(Sql).

%% 触发达成礼包
%% 将插入一条礼包记录，状态为未领取奖励
trigger_fetch(PlayerId, GiftId) ->
	Now = util:unixtime(),
	Sql = io_lib:format(?SQL_GIFT_LIST_INSERT, [PlayerId, GiftId, Now, Now, 0, 0]),
    db:execute(Sql).

%% 是否达成礼包条件，但未领取
%% @return bool
is_fetch_gift(PlayerId, GiftId) ->
	Sql = io_lib:format(?SQL_GIFT_LIST_FETCH_ROW, [PlayerId, GiftId]),
	case db:get_row(Sql) of
		[] ->
			false;
		_ ->
			true
	end.

%% 通过礼包ID获得对应的物品ID
get_goods_id_by_id(GiftId) ->
	case data_gift:get(GiftId) of
		[] ->
			0;
		Gift when is_record(Gift, ets_gift) ->
			Gift#ets_gift.goods_id;
		true ->
			0
	end.

%% 礼包简单判断
%% @praram	GiftInfo	礼包数据#ets_gift
%% @return	{error, 错误码} | {ok}
%% 		错误码：	100 礼包数据不存在
%%						101 礼包状态为无效
%%						102 未到领取礼包时间
%%						103 已过了领取礼包时间
base_check_gift(GiftInfo) ->
	if
		is_record(GiftInfo, ets_gift) ->
			if
				GiftInfo#ets_gift.status =:= 0 ->
					 {error, ?ERROR_GIFT_101}; %% 礼包状态为无效
				true ->
					NowTime = util:unixtime(),
					if 
						(GiftInfo#ets_gift.start_time > 0) and (NowTime < GiftInfo#ets_gift.start_time) ->
							{error, ?ERROR_GIFT_102}; %% 未到领取礼包时间
						(GiftInfo#ets_gift.end_time > 0) and (NowTime > GiftInfo#ets_gift.end_time) ->
							{error, ?ERROR_GIFT_103}; %% 已过了领取礼包时间
						true ->
							{ok}
					end
			end;
		true ->
			{error, ?ERROR_GIFT_100} %% 礼包数据不存在
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
					[NewPS, NewGoodsStatus, _, GiveList, _, _] = lists:foldl(
						fun give_gift_item/2, 
						[PS, 	NewStatus, GiftInfo#ets_gift.bind, [], 0, []],
						GiftList
					),
					update_to_received(PS#player_status.id, GiftInfo#ets_gift.id)
			end,
			
			D = lib_goods_dict:handle_dict(NewGoodsStatus#goods_status.dict),
            NewGoodsStatus1 = NewGoodsStatus#goods_status{dict = D},

			%% 日志
            About = lists:concat([lists:concat([Id,":",Num,","]) || {Id, Num} <- get_log_about(GiveList)]),
            log:log_gift(NewPS#player_status.id, GoodsInfo#goods.id, GoodsInfo#goods.goods_id, GiftInfo#ets_gift.id, About),
            {ok, NewPS, NewGoodsStatus1, NewNum, GiveList}
        end,
    lib_goods_util:transaction(F).

%% [推荐使用] 在物品进程中调用领取礼包的方法
fetch_gift_in_good(PS, GS, GiftId) ->
		F = fun() ->
			ok = lib_goods_dict:start_dict(),

			GiftInfo = data_gift:get(GiftId),
			case base_check_gift(GiftInfo) of
				{ok} ->
					if
						%% 礼包放在背包
						GiftInfo#ets_gift.get_way =:= 1 ->
							{ok, NewPS} = private_gift_to_package(PS, GiftInfo),
							D = lib_goods_dict:handle_dict(NewPS#goods_status.dict),
           					NewPS1 = NewPS#goods_status{dict = D},
							{ok, NewPS1, GS};

						%% 直接领取礼包内物品
						true ->
							{ok, NewPS, NewGS} = private_gift_to_open_in_goods(PS, GS, GiftInfo),
							
							D = lib_goods_dict:handle_dict(NewGS#goods_status.dict),
           					NewGS1 = NewGS#goods_status{dict = D},

							{ok, NewPS, NewGS1}
					end;

				{error, ErrorCode} ->
					{error, ErrorCode}
			end
        end,
    lib_goods_util:transaction(F).

%% 获取礼包
%% @return	{error, 错误码} | {ok}
%% 		错误码：	
%%						100 礼包数据不存在
%%						101 礼包状态为无效
%%						102 未到领取礼包时间
%%						103 已过了领取礼包时间
%%						104 礼包物品不存在
%%						105 背包格子不足
%%						999 领取礼包失败
fetch_gift(PS, GiftId) ->
	GiftInfo = data_gift:get(GiftId),
	case base_check_gift(GiftInfo) of
		{ok} ->
			if
				%% 礼包放在背包
				GiftInfo#ets_gift.get_way =:= 1 ->
					{ok, NewPS} = private_gift_to_package(PS, GiftInfo),
					{ok, NewPS};

				%% 直接领取礼包内物品
				true ->
					{ok, NewPS} = private_gift_to_open(PS, GiftInfo),
					{ok, NewPS}
			end;

		{error, ErrorCode} ->
			{error, ErrorCode}
	end.

%% 将礼包放进背包，不打开礼包的东西
private_gift_to_package(PS, GiftInfo) ->
	GoodsId = GiftInfo#ets_gift.goods_id,
	G = PS#player_status.goods,
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'give_goods', [], GoodsId, 1}) of
		{ok, ok} ->
			{ok, PS};
		%% 物品错误
		{ok, {error, {_GoodsId, not_found}}} -> 
			{error, ?ERROR_GIFT_104};
		%% 格子数不足
		{ok, {error, {cell_num, not_enough}}} ->
			{error, ?ERROR_GIFT_105};
		_ ->
			{error, ?ERROR_GIFT_999}
	end.

%% 直接打开礼包获取里面的物品
private_gift_to_open(PS, GiftInfo) ->
	F = fun() ->
		G = PS#player_status.goods,
		{ok, GoodsStatus} = gen:call(G#status_goods.goods_pid, '$gen_call', {'get_goods_status'}),
		GiftList = private_rand_goods(GiftInfo),
		[NewPlayerStatus, _NewGoodsStatus, _, _GiveList, _, GoodsList] = lists:foldl(
			fun give_gift_item/2, 
			[PS, 	GoodsStatus, GiftInfo#ets_gift.bind, [], 0, []],
			GiftList
		),

		%% 发送玩家属性变化协议
		lib_player:send_attribute_change_notify(NewPlayerStatus, 2),

		%% 如果物品不为空，即批量添加到玩家背包
		case GoodsList =/= [] of
			true ->
				case	gen_server:call(G#status_goods.goods_pid, {'give_more', NewPlayerStatus, GoodsList}) of
					ok ->
						{ok, NewPlayerStatus};
					%% 物品类型不存在
					{fail, 2} ->
						{error, ?ERROR_GIFT_104};
					%% 背包格子不足
					{fail, 3} ->
						{error, ?ERROR_GIFT_105};
					%% 其他错误
					_ ->
						{error, ?ERROR_GIFT_999}
				end;
			_ ->
				{ok, NewPlayerStatus}
		end
	end,
	lib_goods_util:transaction(F).

%% 直接打开礼包获取里面的物品
private_gift_to_open_in_goods(PS, GS, GiftInfo) ->
	GiftList = private_rand_goods(GiftInfo),
	[NewPS, NewGS, _, _, _, _] = lists:foldl(
		fun give_gift_item/2, 
		[PS, 	GS, GiftInfo#ets_gift.bind, [], 0, []],
		GiftList
	),
	%% 发送玩家属性变化协议
	lib_player:send_attribute_change_notify(NewPS, 2),
	{ok, NewPS, NewGS}.

%% 打开普通礼包
private_open_gift(PlayerStatus, GoodsStatus, GiftInfo) ->
	F = fun() ->
		GiftList = private_rand_goods(GiftInfo),
		[NewPlayerStatus, NewGoodsStatus, _, GiveList, _, _] = lists:foldl(
			fun give_gift_item/2, 
			[PlayerStatus, 	GoodsStatus, GiftInfo#ets_gift.bind, [], 1, []],
			GiftList
		),
	    {ok, NewPlayerStatus, NewGoodsStatus, GiveList}
	end,
	lib_goods_util:transaction(F).

%% 处理礼包配置物品的随机类型
private_rand_goods(GiftInfo) ->
	if
		%% 物品随机（不包括装备）
		GiftInfo#ets_gift.gift_rand =:= 1 -> 
			[EquipList, GoodsList] = lists:foldl(fun private_collect_gift_item/2, [[],[]], GiftInfo#ets_gift.gifts),
			GoodsCount = length(GoodsList),
			GiftList = case util:rand(1, GoodsCount) of
				0 -> EquipList;
				Rand ->
					GoodsItem = lists:nth(Rand, GoodsList),
					[GoodsItem|EquipList]
			end;

		%% 为列表随机
	   	GiftInfo#ets_gift.gift_rand =:= 2 -> 
			TotalRatio = lib_goods_util:get_ratio_total(GiftInfo#ets_gift.gifts, 3),
           	Rand = util:rand(1, TotalRatio),
		   	case lib_goods_util:find_ratio(GiftInfo#ets_gift.gifts, 0, Rand, 3) of
				null -> GiftList =[];
                {list, GiftList, _} -> ok
            end;

		%% 固定物品
		true ->
    		GiftList = GiftInfo#ets_gift.gifts
    end,
	GiftList.

%% 打开vip礼包
private_open_vip_gift(PlayerStatus, GoodsStatus, GiftInfo) ->
	GoodsCount = length(GiftInfo#ets_gift.gifts),
	Rand = util:rand(1, GoodsCount),
	GoodsItem = lists:nth(Rand, GiftInfo#ets_gift.gifts),
	%% 礼包的发放
	[NewPlayerStatus, NewGoodsStatus, _, GiveList, _, _] = give_gift_item(GoodsItem, [PlayerStatus, GoodsStatus, GiftInfo#ets_gift.bind, [], 1, []]),
    {ok, NewPlayerStatus, NewGoodsStatus, GiveList}.

%% 具体处理礼包配置的各种属性奖励或物品奖励
%% IsFetchGoods	该项值只针对物品或者装备，对其他配的没影响。值0：会获取物品和装备  1：不会获取物品和装备  2：不会获取装备 
give_gift_item(Item, [PlayerStatus, GoodsStatus, Bind, GiveList, IsFetchGoods, GoodsList]) ->
	case Item of
		%加经验
		{exp, Exp1, Exp2} -> 
            Exp = util:rand(Exp1, Exp2),
            NewPlayerStatus = lib_player:add_exp(PlayerStatus, Exp, 0),
            [NewPlayerStatus, GoodsStatus, Bind, [{exp,Exp}|GiveList], IsFetchGoods, GoodsList];

		%元宝
		{gold, Gold1, Gold2} -> 
			Gold = util:rand(Gold1, Gold2),
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, Gold, gold),
            [NewPlayerStatus, GoodsStatus, Bind, [{gold,Gold}|GiveList], IsFetchGoods, GoodsList];

		%绑定元宝
		{silver, Silver1, Silver2} ->
            Silver = util:rand(Silver1, Silver2),
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, Silver, bgold),
            [NewPlayerStatus, GoodsStatus, Bind, [{silver,Silver}|GiveList], IsFetchGoods, GoodsList];

		 %铜钱
		{coin, Coin1, Coin2} ->
            Coin = util:rand(Coin1, Coin2),
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, Coin, coin),
            [NewPlayerStatus, GoodsStatus, Bind, [{coin,Coin}|GiveList], IsFetchGoods, GoodsList];

		%绑定铜钱
		{bcoin, Bcoin1, Bcoin2} ->
            Bcoin = util:rand(Bcoin1, Bcoin2),
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, Bcoin, coin),
            [NewPlayerStatus, GoodsStatus, Bind, [{coin,Bcoin}|GiveList], IsFetchGoods, GoodsList];

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
					 [PlayerStatus, NewStatus, Bind, [Item | GiveList], IsFetchGoods, GoodsList];
				IsFetchGoods =:= 2 ->
					{ok, NewStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo),
					[PlayerStatus, NewStatus, Bind, [Item | GiveList], IsFetchGoods, GoodsList];
				true ->
					NewStatus = GoodsStatus,
					[PlayerStatus, NewStatus, Bind, [Item|GiveList], IsFetchGoods, [Item|GoodsList]]
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
            [PlayerStatus, NewStatus, Bind, [{equip, TypeId, Prefix, 0}|GiveList], IsFetchGoods, [{equip, TypeId, Prefix, 0}|GoodsList]];

		%% 在线礼包
		{gift_online, GiftId} ->
			%%检查礼包
            G = PlayerStatus#player_status.goods,
            NewGiftId = lib_gift_check:check_online_gift_id(GiftId, G#status_goods.online_gift_time),
            if NewGiftId > 0 ->
                    NewPlayerStatus = PlayerStatus#player_status{goods=G#status_goods{online_gift = NewGiftId, online_gift_time = util:unixtime()}},
                    %%添加在线礼包
					lib_gift_util:add_online_gift(PlayerStatus#player_status.id, NewGiftId),
                    [NewPlayerStatus, GoodsStatus, Bind,  GiveList, IsFetchGoods, GoodsList];
                true ->
                    [PlayerStatus, GoodsStatus, Bind, GiveList, IsFetchGoods, GoodsList]
            end;

		%%礼包
        {gift, GiftId} ->
            lib_gift_util:add_gift(PlayerStatus#player_status.id, GiftId, 1),
            GiftList = [GiftId | GoodsStatus#goods_status.gift_list],
            NewStatus = GoodsStatus#goods_status{gift_list = GiftList},
            [PlayerStatus, NewStatus, Bind, GiveList, IsFetchGoods, GoodsList];
        _ ->
            [PlayerStatus, GoodsStatus, Bind, GiveList, IsFetchGoods, GoodsList]
    end.

send_gift_item_notice(PlayerStatus, GiftId, GoodsTypeId, GiftList) ->
	[Exp, Gold, Silver, Coin, Bcoin, GoodsList, _] = lists:foldl(fun get_gift_item_notice/2, [0,0,0,0,0,[], PlayerStatus#player_status.career], GiftList),
	%%在线礼包领取通知
	{ok, BinData} = pt_150:write(15081, [GiftId, GoodsTypeId, Exp, Gold, Silver, Coin, Bcoin, GoodsList]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	if  GiftId =:= 533101 orelse GiftId =:= 533104 -> %% 帮战城战礼盒
            case lists:keyfind(551001, 1, GoodsList) of %% 龙纹仙玉碎片
                false -> skip;
                _ -> 
					%%聊天窗口,到时加上
%% 					lib_chat:send_cw_gift(PlayerStatus, GiftId, 551001) 
					skip
            end;
		%% 远征岛帝王谷礼包
		GiftId =:= 533401 orelse GiftId =:= 533402 orelse GiftId =:= 533403 orelse GiftId =:= 533404 ->
            case lists:keyfind(112103, 1, GoodsList) of %%3级橙水晶
                false -> skip;
                _ -> 
					skip
%% 					lib_chat:send_cw_gift(PlayerStatus, GiftId, 112103)
            end,
            case lists:keyfind(112104, 1, GoodsList) of %%4级橙水晶
                false -> skip;
                _ -> 
					skip
%% 					lib_chat:send_cw_gift(PlayerStatus, GiftId, 112104)
            end;
        true -> skip
	end.

get_gift_item_notice(Item, [Exp1, Gold1, Silver1, Coin1, Bcoin1, GoodsList1, Career]) ->
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

%% NPC礼包领取 
receive_npc_gift(PlayerStatus, GoodsStatus, GiftInfo, _Card) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
%%             case GiftInfo#ets_gift.give_way =:= ?GIFT_GIVE_WAY_CARD of 
%%                 %领取方式, 新手卡激活
%%                 true -> 
%%                     lib_gift_util:add_gift_card(PlayerStatus#player_status.id, Card, 1);
%%                 %% 礼包物品类型ID - 媒体推广礼包
%%                 false when GiftInfo#ets_gift.goods_id =:= ?GIFT_GOODS_ID_MEDIA ->
%%                     [Card2] = lib_gift_util:get_base_gift_card(PlayerStatus#player_status.accname),
%%                     lib_gift_util:add_gift_card(PlayerStatus#player_status.id, Card2, 2);
%%                 false -> skip
%%             end,
            lib_gift_util:add_npc_gift(PlayerStatus#player_status.id, GiftInfo#ets_gift.id),
            {ok, NewPlayerStatus, NewGoodsStatus, GiveList} = private_open_gift(PlayerStatus, GoodsStatus, GiftInfo),
            GiftList = [GiftInfo#ets_gift.id | GoodsStatus#goods_status.gift_list],
            NewStatus = NewGoodsStatus#goods_status{gift_list = GiftList},
            %% 日志
            About = lists:concat([lists:concat([Id,":",Num,","]) || {Id, Num} <- get_log_about(GiveList)]),
            log:log_gift(PlayerStatus#player_status.id, 0, 0, GiftInfo#ets_gift.id, About),
            D = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus1 = NewStatus#goods_status{dict = D},
            {ok, NewPlayerStatus, NewStatus1, GiveList}
        end,
    lib_goods_util:transaction(F).

%% NPC物品兑换
exchange_goods(PlayerStatus, GoodsStatus, ExchangeInfo, ExchangeNum) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 计算兑换的物品
            [PlayerStatus1, GoodsStatus1, RawScore, DstScore, _] = lists:foldl(fun handle_raw_goods/2, [PlayerStatus, GoodsStatus, 0, 0, ExchangeNum], ExchangeInfo#ets_goods_exchange.raw_goods),
            %% 0为固定兑换，1为随机兑换
            case ExchangeInfo#ets_goods_exchange.method =:= 1 of
                true ->
                    TotalRatio = lib_goods_util:get_ratio_total(ExchangeInfo#ets_goods_exchange.dst_goods, 3),
                    Rand = util:rand(1, TotalRatio),
                    InfoList = lib_goods_util:find_ratio(ExchangeInfo#ets_goods_exchange.dst_goods, 0, Rand, 3);
                false ->
                    InfoList = ExchangeInfo#ets_goods_exchange.dst_goods
            end,
            %% 计算兑换的物品
            [PlayerStatus2, GoodsStatus2, GiveList, _, _] = lists:foldl(fun handle_dst_goods/2, [PlayerStatus1, GoodsStatus1, [], ExchangeInfo#ets_goods_exchange.bind, ExchangeNum], InfoList),
            case ExchangeInfo#ets_goods_exchange.limit_num > 0 andalso ExchangeInfo#ets_goods_exchange.limit_id > 0 of
                true ->
		    SingleKey = integer_to_list(PlayerStatus#player_status.id) ++ "_" ++ integer_to_list(ExchangeInfo#ets_goods_exchange.id),
		    SingleCount = case mod_daily_dict:get_special_info(SingleKey) of
				      undefined -> 0;
				      _SingleCount -> _SingleCount
				  end,
		    mod_daily_dict:set_special_info(SingleKey, SingleCount + ExchangeNum),
                    mod_daily:plus_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ExchangeInfo#ets_goods_exchange.limit_id, ExchangeNum),
                    RemainNum = ExchangeInfo#ets_goods_exchange.limit_num - mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ExchangeInfo#ets_goods_exchange.limit_id);
                false -> RemainNum = 0
            end,
            log:log_exchange(PlayerStatus#player_status.id, ExchangeInfo#ets_goods_exchange.raw_goods, GiveList, ExchangeInfo#ets_goods_exchange.id, ExchangeNum, RawScore, DstScore) ,
            D = lib_goods_dict:handle_dict(GoodsStatus2#goods_status.dict),
            GoodsStatus3 = GoodsStatus2#goods_status{dict = D},
            {ok, PlayerStatus2, GoodsStatus3, GiveList, RemainNum}
        end,
    lib_goods_util:transaction(F).

handle_raw_goods(Item, [PlayerStatus, GoodsStatus, RawScore, DstScore, ExchangeNum]) ->
    case Item of
        {coin, Coin} ->
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Coin * ExchangeNum, coin),
            log:log_consume(gift_exchange, coin, PlayerStatus, NewPlayerStatus, ["gift_exchange"]),
            [NewPlayerStatus, GoodsStatus, (PlayerStatus#player_status.coin+PlayerStatus#player_status.bcoin), (NewPlayerStatus#player_status.coin+NewPlayerStatus#player_status.bcoin), ExchangeNum];
        {bcoin, Bcoin} ->
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Bcoin * ExchangeNum, bcoin),
            log:log_consume(gift_exchange, bcoin, PlayerStatus, NewPlayerStatus, ["gift_exchange"]),
            [NewPlayerStatus, GoodsStatus, PlayerStatus#player_status.bcoin, NewPlayerStatus#player_status.bcoin, ExchangeNum];
        {gold, Gold} ->
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Gold * ExchangeNum, gold),
            log:log_consume(gift_exchange, gold, PlayerStatus, NewPlayerStatus, ["gift_exchange"]),
            [NewPlayerStatus, GoodsStatus, PlayerStatus#player_status.gold, NewPlayerStatus#player_status.gold, ExchangeNum];
        {silver, Silver} ->
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Silver * ExchangeNum, bgold),
            log:log_consume(gift_exchange, bgold, PlayerStatus, NewPlayerStatus, ["gift_exchange"]),
            [NewPlayerStatus, GoodsStatus, PlayerStatus#player_status.bgold, NewPlayerStatus#player_status.bgold, ExchangeNum];
         {arena, ArenaScore} ->
             case lib_player_server:use_arena_score(PlayerStatus, ArenaScore * ExchangeNum) of
                 {ok, {Totle,RestScore,NewPlayerStatus}} ->
                     score_exchange_result(NewPlayerStatus, GoodsStatus),
                     log:log_consume_point(arena_exchange, PlayerStatus#player_status.id, Totle, RestScore, ["arena_exchange"]),
                    [NewPlayerStatus, GoodsStatus, Totle, RestScore, ExchangeNum];
                 {error, _Reson} ->
                     [PlayerStatus, GoodsStatus, 0, 0, ExchangeNum]
             end;
         {battle, BattleScore} ->   %% 帮战
            case lib_player_server:use_factionwar_score(PlayerStatus, BattleScore*ExchangeNum) of
                {ok, {Totle,RestScore,NewPlayerStatus}} ->
                    score_exchange_result(NewPlayerStatus, GoodsStatus),
                    log:log_consume_point(battle_exchange, PlayerStatus#player_status.id, Totle, RestScore, ["battle_exchange"]),
                    [NewPlayerStatus, GoodsStatus, Totle, RestScore, ExchangeNum];
                {error, _Reson} ->
                    [PlayerStatus, GoodsStatus, 0, 0, ExchangeNum]
            end;
         {active, ActiveScore} ->   %% 活跃度消费
            case mod_active:cost(PlayerStatus#player_status.status_active, ActiveScore*ExchangeNum) of
                {ok, {Totle,RestScore}} ->
                    score_exchange_result(PlayerStatus, GoodsStatus),
                    log:log_consume_point(battle_exchange, PlayerStatus#player_status.id, Totle, RestScore, ["active_exchange"]),
                    [PlayerStatus, GoodsStatus, Totle, RestScore, ExchangeNum];
                {error, _Reson} ->
                    [PlayerStatus, GoodsStatus, 0, 0, ExchangeNum]
            end;
%%         {kfz, KFZScore} ->
%%             {ok, NewPlayerStatus} = lib_kfz_3v3:deduct_kfz_score(PlayerStatus, KFZScore * ExchangeNum),
%%             OldKfz_score = lib_kfz_3v3:get_real_kfz_score(PlayerStatus),
%%             NewKfz_score = lib_kfz_3v3:get_real_kfz_score(NewPlayerStatus),
%%             [NewPlayerStatus, GoodsStatus, OldKfz_score, NewKfz_score, ExchangeNum];
%%         {kfz_honour, KFZHonour} ->
%%             {ok, NewPlayerStatus} = lib_kfz_arena:deduct_kfz_honour(PlayerStatus, KFZHonour * ExchangeNum),
%%             [NewPlayerStatus, GoodsStatus, PlayerStatus#player_status.kfz_honour, NewPlayerStatus#player_status.kfz_honour, ExchangeNum];
%%         {master, MasterScore} ->
%%             UniteStatus = lib_player:get_unite_status(PlayerStatus#player_status.id),
%%             {ok, NewUniteStatus} = mod_disperse:call_to_unite(lib_master, deduct_master_score, [UniteStatus, MasterScore * ExchangeNum]),
%%             Master = NewUniteStatus#unite_status.master,
%%             [PlayerStatus, GoodsStatus, Master#status_master.master_score, Master#status_master.master_score, ExchangeNum];
        {llpt, Llpt} ->
            NewPlayerStatus = lib_player:minus_pt(llpt, PlayerStatus, Llpt * ExchangeNum),
            [NewPlayerStatus, GoodsStatus, PlayerStatus#player_status.llpt, NewPlayerStatus#player_status.llpt, ExchangeNum];
        {gjpt, Gjpt} ->
            NewPlayerStatus = lib_player:minus_pt(gjpt, PlayerStatus, Gjpt * ExchangeNum),
            [NewPlayerStatus, GoodsStatus, PlayerStatus#player_status.gjpt, NewPlayerStatus#player_status.gjpt, ExchangeNum];
        {fbpt, Fbpt} ->
            NewPlayerStatus = lib_player:minus_pt(fbpt, PlayerStatus, Fbpt * ExchangeNum),
            [NewPlayerStatus, GoodsStatus, PlayerStatus#player_status.fbpt, NewPlayerStatus#player_status.fbpt, ExchangeNum];
	{fbpt2, Fbpt2} ->
            NewPlayerStatus = lib_player:minus_pt(fbpt2, PlayerStatus, Fbpt2 * ExchangeNum),
            [NewPlayerStatus, GoodsStatus, PlayerStatus#player_status.fbpt2, NewPlayerStatus#player_status.fbpt2, ExchangeNum];
	{goods, GoodsTypeId, GoodsNum} ->
            GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, 
                                                           GoodsTypeId, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
            [NewStatus, _] = lists:foldl(fun lib_goods:delete_one/2, [GoodsStatus, GoodsNum * ExchangeNum], GoodsList),
            [PlayerStatus, NewStatus, RawScore, DstScore, ExchangeNum]
    end.

%% 兑换结果
score_exchange_result(NewPlayerStatus, GoodsStatus) ->
    C = NewPlayerStatus#player_status.chengjiu,
                    Vip = NewPlayerStatus#player_status.vip,
                    Gs = NewPlayerStatus#player_status.guild,
                    Pk = NewPlayerStatus#player_status.pk,
                    Go = NewPlayerStatus#player_status.goods,
                    Dict = GoodsStatus#goods_status.dict,
                    case  Dict =/= [] of
                        true ->
                            SuitList = lib_goods_util:get_suit_id_and_num(NewPlayerStatus#player_status.id, Dict);
                        false ->
                            SuitList = [{0,0}, {0,0}, {0,0}]
                    end,
					Arena = NewPlayerStatus#player_status.arena,
					Factionwar = NewPlayerStatus#player_status.factionwar,
                    case NewPlayerStatus#player_status.marriage#status_marriage.register_time of
                        0 -> 
                            ParnerId = 0,
                            ParnerName = "";
                        _ ->
                            ParnerId = NewPlayerStatus#player_status.marriage#status_marriage.parner_id,
                            ParnerName = NewPlayerStatus#player_status.marriage#status_marriage.parner_name
                    end,
                     {ok, BinData} = pt_130:write(13004, [
                    NewPlayerStatus#player_status.id,
                    NewPlayerStatus#player_status.hp,
                    NewPlayerStatus#player_status.hp_lim,
                    NewPlayerStatus#player_status.mp,
                    NewPlayerStatus#player_status.mp_lim,
                    NewPlayerStatus#player_status.sex,
                    NewPlayerStatus#player_status.lv,
                    NewPlayerStatus#player_status.career,
                    NewPlayerStatus#player_status.nickname,
                    NewPlayerStatus#player_status.att,
                    NewPlayerStatus#player_status.def,
                    NewPlayerStatus#player_status.hit,
                    NewPlayerStatus#player_status.dodge,
                    NewPlayerStatus#player_status.crit,
                    NewPlayerStatus#player_status.ten,
                    Gs#status_guild.guild_id,
                    Gs#status_guild.guild_name,
                    Gs#status_guild.guild_position,
                    NewPlayerStatus#player_status.realm,
                    0, %% 这个是灵力，已经没用
                    NewPlayerStatus#player_status.jobs,
                    Pk#status_pk.pk_value,
                    NewPlayerStatus#player_status.forza,
                    NewPlayerStatus#player_status.agile,
                    NewPlayerStatus#player_status.wit,
                    NewPlayerStatus#player_status.thew,
                    NewPlayerStatus#player_status.fire,
                    NewPlayerStatus#player_status.ice,
                    NewPlayerStatus#player_status.drug,
                    NewPlayerStatus#player_status.llpt,
                    NewPlayerStatus#player_status.xwpt,
                    NewPlayerStatus#player_status.fbpt,
                    NewPlayerStatus#player_status.fbpt2,
                    NewPlayerStatus#player_status.bppt,
                    NewPlayerStatus#player_status.gjpt,
                    Vip#status_vip.vip_type,
                    C#status_chengjiu.honour,
                    NewPlayerStatus#player_status.mlpt,
                    Go#status_goods.equip_current,
                    Go#status_goods.stren7_num,
                    Go#status_goods.suit_id,
                    NewPlayerStatus#player_status.combat_power,
                    Go#status_goods.fashion_weapon,
                    Go#status_goods.fashion_armor,
                    Go#status_goods.fashion_accessory,
                    Go#status_goods.hide_fashion_weapon,
                    Go#status_goods.hide_fashion_armor,
                    Go#status_goods.hide_fashion_accessory, 
                    SuitList,
					Arena#status_arena.arena_score_total - Arena#status_arena.arena_score_used,
					NewPlayerStatus#player_status.whpt,
					Factionwar#status_factionwar.war_score-Factionwar#status_factionwar.war_score_used,
                    ParnerId,
                    ParnerName,
                    Go#status_goods.fashion_head, Go#status_goods.fashion_tail, Go#status_goods.fashion_ring,
                    Go#status_goods.hide_head, Go#status_goods.hide_tail, Go#status_goods.hide_ring
                ]),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData).

handle_dst_goods(Item, [PlayerStatus, GoodsStatus, GiveList, Bind, ExchangeNum]) ->
    case Item of
        {coin, Coin} ->
            NewCoin = Coin * ExchangeNum,
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, NewCoin, coin),
            [NewPlayerStatus, GoodsStatus, [{coin, NewCoin}|GiveList], Bind, ExchangeNum];
        {bcoin, Bcoin} ->
            NewBcoin = Bcoin * ExchangeNum,
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, NewBcoin, coin),
            [NewPlayerStatus, GoodsStatus, [{coin, NewBcoin}|GiveList], Bind, ExchangeNum];
        {gold, Gold} ->
            NewGold = Gold * ExchangeNum,
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, NewGold, gold),
            [NewPlayerStatus, GoodsStatus, [{gold, NewGold}|GiveList], Bind, ExchangeNum];
        {silver, Silver} ->
            NewSilver = Silver * ExchangeNum,
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, NewSilver, bgold),
            [NewPlayerStatus, GoodsStatus, [{silver, NewSilver}|GiveList], Bind, ExchangeNum];
        {goods, GoodsTypeId, GoodsNum} ->
            GoodsTypeInfo = data_goods_type:get(GoodsTypeId),
            case is_record(GoodsTypeInfo, ets_goods_type) of
                false ->
                    GoodsInfo = #goods{};
                true ->
                    GoodsInfo = lib_goods_util:get_new_goods(GoodsTypeInfo)
            end,
            if Bind > 0 -> 
                   GoodsInfo1 = GoodsInfo#goods{bind=Bind, trade=1};
                true ->    
                    GoodsInfo1 = GoodsInfo
            end,
            NewGoodsNum = GoodsNum * ExchangeNum,
            {ok, NewStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, NewGoodsNum, GoodsInfo1),
            [PlayerStatus, NewStatus, [{goods, GoodsTypeId, NewGoodsNum}|GiveList], Bind, ExchangeNum];
        {equip, GoodsTypeId, Prefix, Stren} ->
            TypeId = case is_list(GoodsTypeId) of
                         true -> lists:nth(PlayerStatus#player_status.career, GoodsTypeId);
                         false -> GoodsTypeId
                     end,
            GoodsTypeInfo = data_goods_type:get(TypeId),
            case is_record(GoodsTypeInfo, ets_goods_type) of
                false ->
                    NewInfo = #goods{};
                true ->
                    NewInfo = lib_goods_util:get_new_goods(GoodsTypeInfo)
            end,
            GoodsInfo = NewInfo#goods{prefix=Prefix, stren=Stren},
            if Bind > 0 -> GoodsInfo1 = GoodsInfo#goods{bind=Bind, trade=1};
                true ->     GoodsInfo1 = GoodsInfo
            end,
            {ok, NewStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, ExchangeNum, GoodsInfo1, []),
            [PlayerStatus, NewStatus, [{goods, TypeId, ExchangeNum}|GiveList], Bind, ExchangeNum];
         _ -> [PlayerStatus, GoodsStatus, GiveList, Bind, ExchangeNum]
    end.

get_log_about(GiveList) ->
    [Exp, Gold, Silver, Coin, Bcoin, GoodsList, _] = lists:foldl(fun get_gift_item_notice/2, [0,0,0,0,0,[], 0], GiveList),
    [{exp,Exp},{coin,Coin},{bcoin,Bcoin},{gold,Gold},{silver,Silver} | GoodsList].

%% 将物品与装备放到各自的数组中
private_collect_gift_item(Item, [EquipList, GoodsList]) ->
	case Item of
		{goods, GoodsTypeId, GoodsNum} ->
			[EquipList, [{goods, GoodsTypeId, GoodsNum}|GoodsList]];
		{equip, GoodsTypeId, Prefix1, Prefix2} ->
			[[{equip, GoodsTypeId, Prefix1, Prefix2}|EquipList], GoodsList];
		_ ->
			[[Item|EquipList], GoodsList]
	end.
