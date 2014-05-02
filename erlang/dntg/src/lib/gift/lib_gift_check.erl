%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-31
%% Description: 活动礼包检查类
%% --------------------------------------------------------
-module(lib_gift_check).
-compile(export_all).
-include("def_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("gift.hrl").
-include("server.hrl").
-include("guild.hrl").
-include("unite.hrl").

ckeck_use_gift(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum) ->
    GiftInfo = data_gift:get_by_type(GoodsInfo#goods.goods_id),
    Count = mod_daily:get_count(PlayerStatus#player_status.dailypid, GoodsStatus#goods_status.player_id, ?GOODS_VIP_COUNTER_TYPE),
    Vip = PlayerStatus#player_status.vip,
    MaxCount = case Vip#status_vip.vip_type of
                    1 -> 10;
                    2 -> 12;
                    3 -> 15;
                    _ -> 5
                end,
    if  %% 礼包不存在
        is_record(GiftInfo, ets_gift) =:= false ->
            {fail, ?ERRCODE15_NO_GOODS};
        %% 次数已达上限
        GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_GIFT_VIP andalso (Count + GoodsNum) > MaxCount ->
            {fail, ?ERRCODE15_NUM_LIMIT};
        true ->
            CellNum = lib_gift_util:get_gift_cell(GiftInfo, GoodsNum),
            if 
                %%格子不足
                CellNum > length(GoodsStatus#goods_status.null_cells) ->
                    {fail, ?ERRCODE15_NO_CELL};
                true ->
                    {ok, GoodsInfo, GiftInfo}
            end
    end.

check_online_gift_id(GiftId, OldUnixTime) ->
    GiftInfo = data_gift:get(GiftId),
    case is_record(GiftInfo, ets_gift) of
        true when GiftInfo#ets_gift.goods_id =:= ?GIFT_GOODS_ID_ONLINE_DAY -> %日常在线礼包
            {NowData, _NowTime} = calendar:local_time(),
            {OldDate, _OldTime} = calendar:now_to_local_time(util:unixtime_to_now(OldUnixTime)),
            if NowData =/= OldDate ->
                   ?GIFT_ID_FIRST_ONLINE_DAY;
               true ->
                   GiftId
            end;
        true ->
            GiftId;
        false -> 0
    end.

check_online_gift(PlayerStatus, GoodsStatus, GiftId) ->
    %%NowTime = util:unixtime(),
    GiftInfo = data_gift:get(GiftId),
    G = PlayerStatus#player_status.goods,
    if  %% 礼包不存在
        is_record(GiftInfo, ets_gift) =:= false ->
            {fail, ?ERRCODE15_NO_GOODS};
        %% 礼包类型不正确
        GiftInfo#ets_gift.goods_id =/= ?GIFT_GOODS_ID_ONLINE_NEW andalso GiftInfo#ets_gift.goods_id =/= ?GIFT_GOODS_ID_ONLINE_DAY ->
            {fail, ?ERRCODE15_TYPE_ERR};
        %% 礼包类型不正确
        GiftInfo#ets_gift.get_way =/= ?GIFT_GET_WAY_CLIENT ->
            {fail, ?ERRCODE15_TYPE_ERR};
        %% 礼包类型不正确
        G#status_goods.online_gift =/= GiftId ->
            {fail, ?ERRCODE15_TYPE_ERR};
        %% 领取时间还未到
%%         ( G#status_goods.online_gift_time + GiftInfo#ets_gift.get_delay) > NowTime ->
%%             {fail, ?ERRCODE15_TIME_NOT_START};
        true ->
            CellNum = lib_gift_util:get_gift_cell(GiftInfo, 1),
            if %% 格子不足
                CellNum > length(GoodsStatus#goods_status.null_cells) ->
                    {fail, ?ERRCODE15_NO_CELL};
                true ->
                    {ok, GiftInfo}
            end
    end.

check_npc_gift(PlayerStatus, GoodsStatus, GiftId, Card) ->
%%     case check_gift_npc(PlayerStatus, NpcId) of
%%         false -> {fail, ?ERRCODE15_NPC_FAR};
%%         true ->
            NowTime = util:unixtime(),
            GiftInfo = data_gift:get(GiftId),
            if  %% 礼包不存在
                is_record(GiftInfo, ets_gift) =:= false ->
                    {fail, ?ERRCODE15_NO_GOODS};
                %% 礼包未生效
                GiftInfo#ets_gift.status =:= 0 ->
                    {fail, ?ERRCODE15_GIFT_UNACTIVE};
                %% 领取时间还未到
                GiftInfo#ets_gift.start_time > 0 andalso GiftInfo#ets_gift.start_time > NowTime ->
                    {fail, ?ERRCODE15_TIME_NOT_START};
                %% 时间已经结束
                GiftInfo#ets_gift.end_time > 0 andalso GiftInfo#ets_gift.end_time =< NowTime ->
                    {fail, ?ERRCODE15_TIME_END};
                true ->
                    GoodsTypeInfo = data_goods_type:get(GiftInfo#ets_gift.goods_id),
                    if  %%礼包物品类型不存在
                        is_record(GoodsTypeInfo, ets_goods_type) =:= false ->
                            {fail, ?ERRCODE15_NO_GOODS};
                        %% 礼包未生效
                        PlayerStatus#player_status.lv < GoodsTypeInfo#ets_goods_type.level ->
                            {fail, ?ERRCODE15_LV_ERR};
                        true ->
                            case check_npc_gift2(PlayerStatus, GiftInfo, Card, GoodsTypeInfo, GoodsStatus) of
                                %% 条件不符
                                false -> {fail, ?ERRCODE15_REQUIRE_ERR};
                                %% 已领取过
                                ok -> {fail, ?ERRCODE15_GIFT_GOT};
                                true ->
                                    CellNum = lib_gift_util:get_gift_cell(GiftInfo, 1),
                                    if  %% 格子不足
                                        CellNum > length(GoodsStatus#goods_status.null_cells) ->
                                            {fail, ?ERRCODE15_NO_CELL};
                                        true ->
                                            {ok, GiftInfo}
                                    end
                            end
                    end
            end.
%%     end.

%% check_gift_npc(PlayerStatus, NpcId) ->
%%     case NpcId > 0 of
%%         true -> lib_npc:is_near_npc(NpcId, PlayerStatus#player_status.scene, PlayerStatus#player_status.x, PlayerStatus#player_status.y);
%%         false -> true
%%     end.

check_npc_gift2(PlayerStatus, GiftInfo, _Card, GoodsTypeInfo, _GoodsStatus) ->
    GoodsTypeInfo = data_goods_type:get(GiftInfo#ets_gift.goods_id),
    if
        %% 礼包领取方式不正确
        GiftInfo#ets_gift.get_way =/= ?GIFT_GET_WAY_NPC andalso GiftInfo#ets_gift.get_way =/= ?GIFT_GET_WAY_CLIENT ->
            false;
        %% 礼包类型不正确
%%         GiftInfo#ets_gift.give_way =/= ?GIFT_GIVE_WAY_ASSIGN andalso GiftInfo#ets_gift.give_way =/= ?GIFT_GIVE_WAY_ALL
%%              andalso GiftInfo#ets_gift.give_way =/= ?GIFT_GIVE_WAY_CARD ->
%%             false;
        %% 首充礼包
        GiftInfo#ets_gift.goods_id =:= ?GIFT_GOODS_ID_CHARGE ->
            case lib_gift_util:check_charge(PlayerStatus#player_status.id) of
                false -> false;
                true -> check_gift_queue(PlayerStatus#player_status.id, GiftInfo#ets_gift.id)
            end;
        %% 会员礼包
        GiftInfo#ets_gift.goods_id =:= ?GIFT_GOODS_ID_MEMBER ->
            Vip = PlayerStatus#player_status.vip,
            case Vip#status_vip.vip_type > 0 of
                true ->
%%                     case check_gift_queue(PlayerStatus#player_status.id, GiftInfo#ets_gift.id) of
%%                         true -> util:check_open_day(3);
%%                         ok -> ok
%%                     end;
                    ok;
                false -> false
            end;
        %% 新手卡激活
%%         GiftInfo#ets_gift.give_way =:= ?GIFT_GIVE_WAY_CARD ->
%%             case binary:match(list_to_binary(Card), <<"'">>) of
%%                 nomatch ->
%%                     case check_gift_card(PlayerStatus#player_status.accname, Card) of
%%                         false -> false;
%%                         true -> check_gift_queue(PlayerStatus#player_status.id, GiftInfo#ets_gift.id)
%%                     end;
%%                 _ -> false
%%             end;
        %% 媒体推广礼包
        GiftInfo#ets_gift.goods_id =:= ?GIFT_GOODS_ID_MEDIA ->
            case lib_gift_util:get_base_gift_card(PlayerStatus#player_status.accname) of
                [] -> false;
                [Card2] ->
                    case lib_gift_util:get_gift_card(Card2) of
                        [] -> check_gift_queue(PlayerStatus#player_status.id, GiftInfo#ets_gift.id);
                        _ -> false
                    end
            end;
        %% 指定玩家
%%         GiftInfo#ets_gift.give_way =:= ?GIFT_GIVE_WAY_ASSIGN ->
%%             case lists:member(PlayerStatus#player_status.id, GiftInfo#ets_gift.give_obj) of
%%                 false -> false;
%%                 true -> check_gift_queue(PlayerStatus#player_status.id, GiftInfo#ets_gift.id)
%%             end;
        %% 所有玩家
        true ->
            check_gift_queue(PlayerStatus#player_status.id, GiftInfo#ets_gift.id)
    end.

check_gift_queue(PlayerId, GiftId) ->
    case lib_gift_util:get_gift_queue(PlayerId, GiftId) of
        [] -> true;
        _ -> ok
    end.

%% 判断新手卡是否正确
check_gift_card(AccName, Card) ->
	{CardKey, ServerIds} = config:get_card(),
    HexList = case ServerIds of
		List when is_list(List) -> [string:to_upper(util:md5(lists:concat([AccName, SId, CardKey]))) || SId <- ServerIds];
		_ -> []
	end,
    lists:member(string:to_upper(Card), HexList).

check_exchange_raw_goods([], _, _, _) -> true;
check_exchange_raw_goods([Item|RawGoods], PlayerStatus, Num, GoodsStatus) ->
    Res = case Item of
              {coin, Coin} -> (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) >= (Coin * Num);
              {bcoin, Bcoin} -> PlayerStatus#player_status.bcoin >= (Bcoin * Num);
              {gold, Gold} -> PlayerStatus#player_status.gold >= (Gold * Num);
              {silver, Silver} -> PlayerStatus#player_status.bgold >= (Silver * Num);
              {gjpt, Gjpt} -> PlayerStatus#player_status.gjpt >= (Gjpt * Num);
              {active,Active} -> mod_active:get_my_allactive(PlayerStatus#player_status.status_active) >= (Active * Num);
	      {fbpt, Fbpt} -> PlayerStatus#player_status.fbpt >= (Fbpt * Num);
	      {fbpt2, Fbpt} -> PlayerStatus#player_status.fbpt2 >= (Fbpt * Num);
	      {llpt, Llpt} -> PlayerStatus#player_status.llpt >= (Llpt * Num);
              {arena, ArenaScore} -> 
	             Arena = PlayerStatus#player_status.arena,
	             Totle = Arena#status_arena.arena_score_total - Arena#status_arena.arena_score_used,
                  Totle >= (ArenaScore * Num);
               {battle, BattleScore} -> 
                   War = PlayerStatus#player_status.factionwar,
		  War#status_factionwar.war_score - War#status_factionwar.war_score_used>= (BattleScore * Num);
%%               {kfz, KFZScore} -> lib_kfz_3v3:get_real_kfz_score(PlayerStatus) >= (KFZScore * Num);
%%               {kfz_honour, KFZHonour} -> PlayerStatus#player_status.kfz_honour >= (KFZHonour * Num);
%%               {master, MasterScore} -> PlayerStatus#player_status.master_score >= (MasterScore * Num);
              {goods, GoodsTypeId, GoodsNum} ->
                  GoodsTypeList = lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id, GoodsTypeId, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
                  TotalNum = lib_goods_util:get_goods_totalnum(GoodsTypeList),
                  TotalNum >= (GoodsNum * Num);
              _ -> false
          end,
    case Res of
        true -> check_exchange_raw_goods(RawGoods, PlayerStatus, Num, GoodsStatus);
        false -> false
    end.

%% 检查领取物品
check_recv_gift(PlayerStatus, GoodsStatus, GiftId, Card) ->
    NowTime = util:unixtime(),
    GiftInfo = lib_activity_gift:get_one(GiftId),
    if  %% 礼包不存在
        is_record(GiftInfo, ets_gift2) =:= false ->
            {fail, 2};
        %% 礼包未生效
        GiftInfo#ets_gift2.status =:= 0 ->
            {fail, 3};
        %% 活动时间还未开始
        GiftInfo#ets_gift2.time_start > 0 andalso GiftInfo#ets_gift2.time_start > NowTime ->
            {fail, 4};
        %% 活动时间已经结束
        GiftInfo#ets_gift2.time_end > 0 andalso GiftInfo#ets_gift2.time_end =< NowTime ->
            {fail, 5};
        %% 等级限制
        PlayerStatus#player_status.lv < GiftInfo#ets_gift2.lv ->
            {fail, 6};
        true ->
            case lib_activity_gift:check(PlayerStatus#player_status.id, GiftId, Card) of
                %% 条件不符
                false -> 
                    {fail, 7};
                %% 已领取过
                ok -> 
                    {fail, 8};
                true ->
                    %% 格子不足
                    case length(GoodsStatus#goods_status.null_cells) >= length(GiftInfo#ets_gift2.goods_list)  of
                        false -> 
                            {fail, 9};
                        true -> 
                            {ok, GiftInfo}
                    end
            end
    end.
