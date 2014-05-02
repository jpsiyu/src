%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-1-29
%% Description: 宝箱检查
%% --------------------------------------------------------
-module(lib_box_check).
-compile(export_all).
-include("def_goods.hrl").
-include("goods.hrl").
-include("box.hrl").
-include("server.hrl").
-include("common.hrl").

%% 检查开宝箱
check_box_open(PlayerStatus, BoxId, BoxNum, GoodsStatus) ->
    BoxInfo = data_box:get_box(BoxId),
    Sell = PlayerStatus#player_status.sell,
    if  %% 宝箱ID错误
        is_record(BoxInfo, ets_box) =:= false ->
            {fail, 2};
        %% 宝箱数量错误
        BoxNum =< 0 orelse BoxId =< 0 ->
            {fail, 3};
        true ->
            BoxBag = lib_box:get_box_bag(PlayerStatus),
            if  %% 宝箱包裹格子不足
                length(BoxBag) >= 1000 ->
                    {fail, 5};
                true ->
                    GoodsTypeId = lib_box:get_open_box_goods(BoxId, BoxNum),
                    GoodsInfo = case GoodsTypeId > 0 of
                                    true -> 
                                        lib_goods_util:get_goods_by_type(PlayerStatus#player_status.id, GoodsTypeId, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict);
                                    false -> 
                                        []
                                end,
                    case is_record(GoodsInfo, goods) andalso GoodsInfo#goods.num > 0 of
                        true ->
                            Cost = 0,
                            case Sell#status_sell.sell_status =/= 0 of
                                %% 正在交易中
                                true -> 
                                    {fail, 7};
                                false -> 
                                    {ok, BoxInfo, BoxBag, Cost, GoodsInfo, GoodsTypeId, 2}
                            end;
                        false ->
                            Cost = case BoxNum of
                                        50 -> BoxInfo#ets_box.price3;
                                        10 -> BoxInfo#ets_box.price2;
                                        1 -> BoxInfo#ets_box.price;
                                        _ -> BoxInfo#ets_box.price * BoxNum
                                    end,
                            case PlayerStatus#player_status.gold < Cost of
                                true -> {fail, 4};
                                false -> {ok, BoxInfo, BoxBag, Cost, GoodsInfo, 0, 0}
                            end
                    end
            end
    end.

%% 宝箱兑换
check_box_exchange(PlayerStatus, StoneId, EquipId, Pos, GoodsStatus) ->
   if
       Pos =:= 0 -> % 淘宝
            check_box_bag(PlayerStatus, StoneId, EquipId, GoodsStatus);
        true ->
            check_bag_exchange(PlayerStatus, StoneId, EquipId, GoodsStatus)
    end.

check_box_bag(PlayerStatus, StoneId, EquipId, GoodsStatus) ->
    Sell = PlayerStatus#player_status.sell,
    L = lists:member(EquipId, ?CHANGE_LIST),
    N = lib_box:get_box_goods_num(PlayerStatus, StoneId),
    T = util:check_open_day(?CHANGE_DAYS),
    if
        %% 物品类型不正确
        StoneId =/= 112104 ->
            {fail, 4};
        %% 物品类型不正确
        L =/= true ->
            {fail, 4};
        %% 背包格子不足
        length(GoodsStatus#goods_status.null_cells) =< 0 ->
            {fail, 3};
        %%　物品不存在
        N =< 0 ->
            {fail, 2};
        %% 兑换时间已过
        T =/= true ->
            {fail, 5};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 6};
        true ->
            case data_goods_type:get(EquipId) of
                [] ->
                    {fail, 2};
                GoodsTypeInfo ->
                    {ok, StoneId, GoodsTypeInfo}
            end
    end.

check_bag_exchange(PlayerStatus, StoneId, EquipId, GoodsStatus) ->
    Sell = PlayerStatus#player_status.sell,
    StoneInfo = lib_goods_util:get_goods(StoneId, GoodsStatus#goods_status.dict),
    L = lists:member(EquipId, ?CHANGE_LIST),
    T = util:check_open_day(?CHANGE_DAYS),
    if  %% 物品不存在
        is_record(StoneInfo, goods) =:= false ->
            {fail, 2};
        StoneInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        StoneInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 7};
        %% 物品位置不正确
        StoneInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 8};
        %% 兑换时间已过
        T =/= true ->
            {fail, 5};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 6};
        %% 背包格子不足
        length(GoodsStatus#goods_status.null_cells) =< 0 ->
            {fail, 3};
        %% 物品类型不正确
        StoneInfo#goods.goods_id =/= 112104 ->
            {fail, 4};
        %% 物品类型不正确
        L =/= true ->
            {fail, 4};
        true ->
            case data_goods_type:get(EquipId) of
                [] ->
                    {fail, 2};
                GoodsTypeInfo ->
                    {ok, StoneInfo, GoodsTypeInfo}
            end
    end.

check_get_gift(PlayerStatus, GiftId) ->
    %% 礼包id不对
    case lists:member(GiftId, ?GIFT_LIST) of
        false ->
            {fail, 2};
        true ->
            Dict = PlayerStatus#player_status.exchange_dict,
            case dict:is_key(PlayerStatus#player_status.id, Dict) of
                true ->
                    [Exchange] = dict:fetch(PlayerStatus#player_status.id, Dict),
                    case lists:member(GiftId, Exchange#ets_box_exchange.gift_list) of
                        true ->
                            %% 已经领取过
                            {fail, 3};
                        false ->
                            if length(Exchange#ets_box_exchange.type_list) < 2 ->
                                    %% 兑换数量不够
                                    {fail, 4};
                                true ->
                                    {ok, GiftId}
                            end
                    end;
                false ->
                    {fail, 4}
            end
    end.

        
