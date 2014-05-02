%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-23
%% Description: 活动礼包
%% --------------------------------------------------------
-module(lib_activity_gift).
-compile(export_all).
-include("gift.hrl").
-include("sql_goods.hrl").
-include("goods.hrl").
-include("server.hrl").

%% 检查卡号是否符合条件
check(PlayerId, GiftId, Card) ->
    case binary:match(list_to_binary(Card), <<"'">>) of
        nomatch ->
            case get_card(Card, GiftId) of
                [Status] when Status =:= 0 -> 
                    case get_gift_queue(PlayerId, GiftId) of
                        [] -> 
                            true;
                        _ -> 
                            ok
                    end;
                _ -> 
                    false
            end;
        _ -> 
            false
    end.

%% 领取活动礼包
receive_gift(PlayerStatus, GoodsStatus, GiftInfo, Card) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            mod_card(PlayerStatus#player_status.id, Card),
            add_gift_queue(PlayerStatus#player_status.id, GiftInfo#ets_gift2.id),
            %% 增加属性
            {ok, PlayerStatus1} = give_attr(PlayerStatus, GiftInfo),
            [NewPlayerStatus, GoodsStatus1, _, GiveList] = lists:foldl(fun give_gift_item/2, [PlayerStatus1, GoodsStatus, GiftInfo#ets_gift2.bind, []], GiftInfo#ets_gift2.goods_list),
            GiftList = [GiftInfo#ets_gift2.id | GoodsStatus1#goods_status.gift_list],
            NewGoodsStatus = GoodsStatus1#goods_status{ gift_list = GiftList },
            %% 日志
            About = lists:concat([lists:concat([Id,":",Num,","]) || {Id, Num} <- 
                [{coin,GiftInfo#ets_gift2.coin},{bcoin,GiftInfo#ets_gift2.bcoin},{gold,GiftInfo#ets_gift2.gold},{bgold,GiftInfo#ets_gift2.bgold} | GiveList]]),
            log:log_gift(PlayerStatus#player_status.id, 0, 0, GiftInfo#ets_gift2.id, About),
            Dict = lib_goods_dict:handle_dict(),
            NewStatus1 = NewGoodsStatus#goods_status{dict = Dict},
            {ok, NewPlayerStatus, NewStatus1, GiveList}
        end,
    lib_goods_util:transaction(F).

%% 增加属性
give_attr(PlayerStatus, GiftInfo) ->
    NewPlayerStatus = PlayerStatus#player_status{ 
                            coin = (PlayerStatus#player_status.coin + GiftInfo#ets_gift2.coin), 
                            bcoin = (PlayerStatus#player_status.bcoin + GiftInfo#ets_gift2.bcoin), 
                            gold = (PlayerStatus#player_status.gold + GiftInfo#ets_gift2.gold), 
                            bgold = (PlayerStatus#player_status.bgold + GiftInfo#ets_gift2.bgold)
                        },
    Sql = io_lib:format(?SQL_PLAYER_UPDATE_MONEY, [NewPlayerStatus#player_status.coin, NewPlayerStatus#player_status.bgold, 
                                                   NewPlayerStatus#player_status.gold, NewPlayerStatus#player_status.bcoin, 
                                                   NewPlayerStatus#player_status.point, NewPlayerStatus#player_status.id]),
    db:execute(Sql),
    {ok, NewPlayerStatus}.

%% 礼包类型
give_gift_item(Item, [PlayerStatus, GoodsStatus, Bind, GiveList]) ->
    case Item of
        %% 物品
        {goods, GoodsTypeId, GoodsNum} ->
            GoodsTypeInfo = data_goods_type:get(GoodsTypeId),
            NewInfo = lib_goods_util:get_new_goods(GoodsTypeInfo),
            case Bind > 0 of
                true -> 
                    GoodsInfo = NewInfo#goods{bind=2, trade=1};
                false -> 
                    GoodsInfo = NewInfo
            end,
            {ok, NewStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo),
            [PlayerStatus, NewStatus, Bind, [{GoodsTypeId, GoodsNum}|GiveList]];
        %% 装备
        {equip, GoodsTypeId, Prefix, Stren} ->
            TypeId = case is_list(GoodsTypeId) of
                         true -> 
                             lists:nth(PlayerStatus#player_status.career, GoodsTypeId);
                         false -> 
                             GoodsTypeId
                     end,
            GoodsTypeInfo = data_goods_type:get(TypeId),
            NewInfo = lib_goods_util:get_new_goods(GoodsTypeInfo),
            %GoodsInfo = NewInfo#goods{ bind=2, trade=1, prefix=Prefix, stren=Stren },
            case Bind > 0 of
                true -> 
                    GoodsInfo = NewInfo#goods{bind=2, trade=1, prefix=Prefix, stren=Stren};
                false -> 
                    GoodsInfo = NewInfo#goods{prefix=Prefix, stren=Stren}
            end,
            {ok, NewStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, 1, GoodsInfo, []),
            [PlayerStatus, NewStatus, Bind, [{TypeId, 1}|GiveList]];
        _ ->
            [PlayerStatus, GoodsStatus, Bind, GiveList]
    end.

%% 发送领取礼包物品信息
send_gift_item_notice(PlayerStatus, GiftInfo, GiveList) ->
    {ok, BinData} = pt_15:write(15081, [GiftInfo#ets_gift2.id, 0, 0, GiftInfo#ets_gift2.gold, GiftInfo#ets_gift2.bgold, GiftInfo#ets_gift2.coin, GiftInfo#ets_gift2.bcoin, GiveList]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData).

%% 取一个礼包信息
get_one(Id) ->
    case ets:lookup(?ETS_GIFT, Id) of
        [] ->
            [];
        [Info] ->
            Info
    end.

%% 取所有礼包信息
get_all() ->
    ets:tab2list(?ETS_GIFT).

%% 初始化活动礼包
init() ->
    ets:delete_all_objects(?ETS_GIFT),
    F = fun([Mid, Mname, Murl, Mbind, Mlv, Mcoin, Mbcoin, Mgold, Msilver, Mgoods_list, Mis_show, Mtime_start, Mtime_end, Mstatus]) ->
                Info = #ets_gift2{
                            id = Mid,
                            name = Mname,
                            url = Murl,
                            bind = Mbind,
                            lv = Mlv,
                            coin = Mcoin,
                            bcoin = Mbcoin,
                            gold = Mgold,
                            bgold = Msilver,
                            goods_list = lib_goods_util:to_term(Mgoods_list),
                            is_show = Mis_show,
                            time_start = Mtime_start,
                            time_end = Mtime_end,
                            status = Mstatus
                      },
                ets:insert(?ETS_GIFT, Info)
         end,
    case db:get_all(?SQL_GIFT2_SELECT) of
        [] -> 
            skip;
        List when is_list(List) ->
            lists:foreach(F, List);
        _ -> 
            skip
    end,
    ok.

%% 取激活码状态
get_card(Card, GiftId) ->
    Sql = io_lib:format(?SQL_GIFT2_CARD_SELECT, [Card, GiftId]),
    db:get_row(Sql).

%% 更新激活码状态
mod_card(PlayerId, Card) ->
    Sql = io_lib:format(?SQL_GIFT2_CARD_UPDATE, [PlayerId, Card]),
    db:execute(Sql).

%% 取领取记录信息
get_gift_queue(PlayerId, GiftId) ->
    Sql = io_lib:format(?SQL_GIFT_QUEUE_SELECT, [PlayerId, GiftId]),
    db:get_row(Sql).

add_gift_queue(PlayerId, GiftId) ->
    NowTime = util:unixtime(),
    Sql = io_lib:format(?SQL_GIFT_QUEUE_INSERT_FULL, [PlayerId, GiftId, NowTime, 1, NowTime, 1]),
    db:execute(Sql).






