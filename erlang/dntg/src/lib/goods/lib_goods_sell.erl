%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-7
%% Description: 物品交易类
%% --------------------------------------------------------
-module(lib_goods_sell).
-compile(export_all).
-include("common.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("server.hrl").
-include("sell.hrl").

%% 挂售物品上架
sell_up(PlayerStatus, GoodsStatus, SellInfo, GoodsInfo, Cost, Show) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            case GoodsInfo#goods.id =:= 0 of
                %% 金钱
                true ->
                    %% SellUp:挂售, Price:价格, Time:时长
                    About = lists:concat(["SellUp:",SellInfo#ets_sell.num," ",binary_to_list(SellInfo#ets_sell.goods_name)," Price：",SellInfo#ets_sell.price," Time：",SellInfo#ets_sell.time]),
                    PlayerStatus1 = case PlayerStatus#player_status.bcoin < Cost of
                                        false -> 
                                            PlayerStatus#player_status{bcoin = (PlayerStatus#player_status.bcoin - Cost)};
                                        true ->  
                                            PlayerStatus#player_status{bcoin = 0, coin= (PlayerStatus#player_status.bcoin + PlayerStatus#player_status.coin - Cost)}
                                    end,
                    log:log_consume(sell_fee, coin, PlayerStatus, PlayerStatus1, About),
                    About1 = lists:concat(["SellUp[",binary_to_list(SellInfo#ets_sell.goods_name),"]"]),
                    case SellInfo#ets_sell.price_type =:= 0 of
                        true ->  
                            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus1, SellInfo#ets_sell.num, gold),
                            log:log_consume(sell_up, gold, PlayerStatus1, NewPlayerStatus, About1);
                        false -> 
%%                             NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus1, SellInfo#ets_sell.num, rcoin),
							NewPlayerStatus = lib_goods_util:cost_sell_money(PlayerStatus1, SellInfo#ets_sell.num, rcoin),
                            log:log_consume(sell_up, rcoin, PlayerStatus1, NewPlayerStatus, About1)
                    end,
                    NewSellInfo = add_sell(SellInfo),
                    case Show > 0 andalso SellInfo#ets_sell.price_type =/= 0 of
                        true ->
                            lib_chat:send_TV({all},0,2, ["sellGood", 
													0,
                                                    NewSellInfo#ets_sell.num,
													NewPlayerStatus#player_status.id,
                                                    0,
                                                    0,
                                                    0,
                                                    NewSellInfo#ets_sell.price,
                                                    NewSellInfo#ets_sell.id]);
                        false ->
                            skip
                    end,
                    case Show > 0 andalso SellInfo#ets_sell.price_type =:= 0 of
                        true ->
                            lib_chat:send_TV({all},0,2, ["sellGood", 
													1,
                                                    NewSellInfo#ets_sell.num,
													NewPlayerStatus#player_status.id,
                                                    0,
                                                    0,
                                                    0,
                                                    SellInfo#ets_sell.price,
                                                    NewSellInfo#ets_sell.id]);
                        false ->
                            skip
                    end,
                    NewStatus = GoodsStatus;
                %% 物品
                false ->
                    NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
                    About = lists:concat(["SellUp ",SellInfo#ets_sell.gid," ",binary_to_list(SellInfo#ets_sell.goods_name)," x",SellInfo#ets_sell.num," Price：",SellInfo#ets_sell.price," Time：",SellInfo#ets_sell.time]),
                    log:log_consume(sell_fee, coin, PlayerStatus, NewPlayerStatus, About),
                    [_, NewGoodsStatus] = lib_goods:change_goods_cell(GoodsInfo, ?GOODS_LOC_SELL, 0, GoodsStatus),
                    NewSellInfo = add_sell(SellInfo),
                    case Show > 0 of
                        true ->
                            case SellInfo#ets_sell.price_type =:= 0 of
                                true ->
                                    lib_chat:send_TV({all},0,2, ["sellGood", 
													3,
                                                    SellInfo#ets_sell.num,
													NewPlayerStatus#player_status.id,
                                                    SellInfo#ets_sell.gid,
                                                    SellInfo#ets_sell.goods_id,
                                                    SellInfo#ets_sell.num,
                                                    SellInfo#ets_sell.price,
                                                    NewSellInfo#ets_sell.id]);
                                false ->
                                    lib_chat:send_TV({all},0,2, ["sellGood", 
													2,
                                                    SellInfo#ets_sell.num,
													NewPlayerStatus#player_status.id,
                                                    SellInfo#ets_sell.gid,
                                                    SellInfo#ets_sell.goods_id,
                                                    SellInfo#ets_sell.num,
                                                    SellInfo#ets_sell.price,
                                                    NewSellInfo#ets_sell.id])
                            end;
                        false ->
                            skip
                    end,
                    NullCells = [GoodsInfo#goods.cell | NewGoodsStatus#goods_status.null_cells],
                    NewStatus = NewGoodsStatus#goods_status{null_cells=NullCells}
            end,
            log:log_sell(1, NewSellInfo, 0, 0),
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
            {ok, NewPlayerStatus, NewStatus2, NewSellInfo}
        end,
    lib_goods_util:transaction(F).

%% 挂售物品下架
sell_down(PlayerStatus, GoodsStatus, SellInfo, GoodsInfo) ->
    F = fun() ->
            Id = SellInfo#ets_sell.id,
            Sql = io_lib:format(?SQL_SELL_SELECT_ID2, [Id]),
            case db:get_one(Sql) of
                Id when is_number(Id) andalso Id > 0 ->
                    ok = lib_goods_dict:start_dict(),
                    del_sell(SellInfo#ets_sell.id),
                    case SellInfo#ets_sell.gid =:= 0 of
                        %% 金钱
                        true ->
                            %% Sell_down:取消挂售
                            About = lists:concat(["Sell_down[",binary_to_list(SellInfo#ets_sell.goods_name),"]"]),
                            case SellInfo#ets_sell.price_type =:= 0 of
                                true ->
                                    NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, SellInfo#ets_sell.num, gold),
                                    log:log_produce(sell_cancel, gold, PlayerStatus, NewPlayerStatus, About);
                                false ->
                                    NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, SellInfo#ets_sell.num, coin),
                                    log:log_produce(sell_cancel, coin, PlayerStatus, NewPlayerStatus, About)
                            end,
                            NewStatus = GoodsStatus;
                        %% 物品
                        false ->
                            [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
                            [_, NewGoodsStatus] = lib_goods:change_goods_cell(GoodsInfo, ?GOODS_LOC_BAG, Cell, GoodsStatus),
                            NewStatus = NewGoodsStatus#goods_status{null_cells=NullCells},
                            NewPlayerStatus = PlayerStatus
                    end,
                    log:log_sell(2, SellInfo, 0, 0),
                    Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                    NewStatus2 = NewStatus#goods_status{dict = Dict},
                    {ok, NewPlayerStatus, NewStatus2};
                _ ->
                    {fail, 0}
            end
        end,
    lib_goods_util:transaction(F).

%% 购买挂售物品
pay_sell(PlayerStatus, GoodsStatus, SellInfo, GoodsInfo) ->
    F = fun() ->
            Id = SellInfo#ets_sell.id,
            Sql = io_lib:format(?SQL_SELL_SELECT_ID2, [Id]),
            case db:get_one(Sql) of
                Id when is_number(Id) andalso Id > 0 ->
                    ok = lib_goods_dict:start_dict(),
                    del_sell(Id),
                    %% Pay_sell:购买挂售物品
                    About1 = io_lib:format("Pay_sell[~s]", [SellInfo#ets_sell.goods_name]),
                    case SellInfo#ets_sell.price_type =:= 0 of
                        true ->
%%                             NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, SellInfo#ets_sell.price, rcoin),
							NewPlayerStatus = lib_goods_util:cost_sell_money(PlayerStatus, SellInfo#ets_sell.price, rcoin),
                            log:log_consume(sell_pay, coin, PlayerStatus, NewPlayerStatus, SellInfo#ets_sell.goods_id, SellInfo#ets_sell.num, About1),
                            [T, C] = data_sell_text:mail_text(coin),
                            Title = io_lib:format(T, [SellInfo#ets_sell.goods_name]),
                            Content = io_lib:format(C, [SellInfo#ets_sell.goods_name, SellInfo#ets_sell.price]),
                            Coin = SellInfo#ets_sell.price,
                            Gold = 0;
                        false ->
                            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, SellInfo#ets_sell.price, gold),
                            log:log_consume(sell_pay, gold, PlayerStatus, NewPlayerStatus,  SellInfo#ets_sell.goods_id, SellInfo#ets_sell.num, About1),
                            [T, C] = data_sell_text:mail_text(gold),
                            Title = io_lib:format(T, [SellInfo#ets_sell.goods_name]),
                            Content = io_lib:format(C, [SellInfo#ets_sell.goods_name, SellInfo#ets_sell.price]),
                            Coin = 0,
                            Gold = SellInfo#ets_sell.price
                    end,
                    case SellInfo#ets_sell.gid =:= 0 of
                        %% 金钱
                        true ->
                            About2 = io_lib:format("Pay_sell[~s]", [SellInfo#ets_sell.goods_name]),
                            case SellInfo#ets_sell.price_type =:= 0 of
                                true ->
                                    NewPlayerStatus2 = lib_goods_util:add_money(NewPlayerStatus, SellInfo#ets_sell.num, gold),
                                    log:log_produce(sell_pay, gold, NewPlayerStatus, NewPlayerStatus2, About2);
                                false ->
                                    NewPlayerStatus2 = lib_goods_util:add_money(NewPlayerStatus, SellInfo#ets_sell.num, coin),
                                    log:log_produce(sell_pay, coin, NewPlayerStatus, NewPlayerStatus2, About2)
                            end,
                            NewStatus = GoodsStatus;
                        %% 物品
                        false ->
                            [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
                            lib_goods:change_goods_player(GoodsInfo, NewPlayerStatus#player_status.id, ?GOODS_LOC_BAG, Cell, GoodsStatus),
                            NewStatus = GoodsStatus#goods_status{null_cells=NullCells},
                            NewPlayerStatus2 = NewPlayerStatus
                    end,
                    lib_mail:send_sys_mail_server([SellInfo#ets_sell.pid], Title, Content, 0, 0, 0, 0, 0, 0, Coin, 0, Gold),
                    log:log_sell(4, SellInfo, PlayerStatus#player_status.id, 0),
                    Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                    NewStatus2 = NewStatus#goods_status{dict = Dict},
                    {ok, NewPlayerStatus2, NewStatus2};
                _ ->
                    {fail, 0}
            end
        end,
    lib_goods_util:transaction(F).

%% 再次挂售
resell(PlayerStatus, SellInfo, Cost) ->
    F = fun() ->
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
            %% Resell:再次挂售, Time:时长, Price:价格
            About = lists:concat(["Resell",SellInfo#ets_sell.gid," ",binary_to_list(SellInfo#ets_sell.goods_name)," x",SellInfo#ets_sell.num," Price：",SellInfo#ets_sell.price," Time：",SellInfo#ets_sell.time]),
            log:log_consume(sell_fee, coin, PlayerStatus, NewPlayerStatus, About),
            NewSellInfo = lib_sell:resell(SellInfo),
            log:log_sell(5, NewSellInfo, 0, 0),
            {ok, NewPlayerStatus, NewSellInfo}
        end,
    lib_goods_util:transaction(F).

%% 完成交易
finish_sell(PlayerStatus, GoodsStatus, SellerPlayerStatus, SellerGoodsStatus) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 删除物品
            P_sell = PlayerStatus#player_status.sell,
            S_sell = SellerPlayerStatus#player_status.sell,
            {ok, {NewPlayerStatus, NewGoodsStatus}} = lib_goods_check:list_handle(fun del_sell_item/2, {PlayerStatus, GoodsStatus}, P_sell#status_sell.sell_list),
            {ok, {NewSellerPlayerStatus, NewSellerGoodsStatus}} = lib_goods_check:list_handle(fun del_sell_item/2, {SellerPlayerStatus, SellerGoodsStatus}, S_sell#status_sell.sell_list),
            NullCells1 = lists:sort(NewGoodsStatus#goods_status.null_cells),
            NewGoodsStatus1 = NewGoodsStatus#goods_status{null_cells=NullCells1},
            NullCells2 = lists:sort(NewSellerGoodsStatus#goods_status.null_cells),
            NewSellerGoodsStatus1 = NewSellerGoodsStatus#goods_status{null_cells=NullCells2},
            %% 添加物品
            NewSell = NewSellerPlayerStatus#player_status.sell,
            NewPlaySell = NewPlayerStatus#player_status.sell,
            {ok, {NewPlayerStatus2, NewGoodsStatus2, NewSellerGoodsStatus2}} = lib_goods_check:list_handle(fun add_sell_item/2, {NewPlayerStatus, NewGoodsStatus1, NewSellerGoodsStatus1}, NewSell#status_sell.sell_list),
            {ok, {NewSellerPlayerStatus2, NewSellerGoodsStatus3, NewGoodsStatus3}} = lib_goods_check:list_handle(fun add_sell_item/2, {NewSellerPlayerStatus, NewSellerGoodsStatus2, NewGoodsStatus2}, NewPlaySell#status_sell.sell_list),
            Sell1 = NewPlayerStatus2#player_status.sell,
            Sell2 = NewSellerPlayerStatus2#player_status.sell,
            NewPlayerStatus3 = NewPlayerStatus2#player_status{sell=Sell1#status_sell{sell_status=0, sell_id=0, sell_list=[]}},
            NewSellerPlayerStatus3 = NewSellerPlayerStatus2#player_status{sell=Sell2#status_sell{sell_status=5, sell_id=0, sell_list=[]}},
            NewGoodsStatus4 = NewGoodsStatus3#goods_status{sell_status=0},
            NewSellerGoodsStatus4 = NewSellerGoodsStatus3#goods_status{sell_status=0},
            %% 日志
            PlayerId1 = PlayerStatus#player_status.id,
            PlayerId2 = SellerPlayerStatus#player_status.id,
            Seller = SellerPlayerStatus#player_status.sell,
            Coin1 = (PlayerStatus#player_status.coin - NewPlayerStatus#player_status.coin),
            Coin2 = (SellerPlayerStatus#player_status.coin - NewSellerPlayerStatus#player_status.coin),
            About1 = lists:concat([lists:concat([GoodsId,":",GoodsTypeId,":",GoodsNum,","]) || {GoodsId,GoodsTypeId,GoodsNum} <- P_sell#status_sell.sell_list, GoodsId =/= money]),
            About2 = lists:concat([lists:concat([GoodsId,":",GoodsTypeId,":",GoodsNum,","]) || {GoodsId,GoodsTypeId,GoodsNum} <- Seller#status_sell.sell_list, GoodsId =/= money]),
            case PlayerStatus#player_status.id =:= P_sell#status_sell.sell_id of
                true ->  log:log_trade(PlayerId1, PlayerId2, Coin1, Coin2, About1, About2);
                false -> log:log_trade(PlayerId2, PlayerId1, Coin2, Coin1, About2, About1)
            end,
            {ok, NewPlayerStatus3, NewGoodsStatus4, NewSellerPlayerStatus3, NewSellerGoodsStatus4}
        end,
    lib_goods_util:transaction(F).
    

%% 删除交易列表
del_sell_item(Item, {PlayerStatus, GoodsStatus}) ->
    case Item of
        {money, Coin, _Gold} ->
%%             NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Coin, rcoin),
			NewPlayerStatus = lib_goods_util:cost_sell_money(PlayerStatus, Coin, rcoin),
            log:log_consume(del_sell_list, coin, PlayerStatus, NewPlayerStatus, ["del_sell_list"]),
            {ok, {NewPlayerStatus, GoodsStatus}};
        {GoodsId, _, _} ->
            GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
            NullCells = [GoodsInfo#goods.cell | GoodsStatus#goods_status.null_cells],
            NewGoodsStatus = GoodsStatus#goods_status{null_cells=NullCells},
            {ok, {PlayerStatus, NewGoodsStatus}}
    end.

%% 添加交易物品
add_sell_item(Item, {PlayerStatus, GoodsStatus, SellStatus}) ->
    case Item of
        {money, Coin, _Gold} ->
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, Coin, coin),
            {ok, {NewPlayerStatus, GoodsStatus, SellStatus}};
        {GoodsId, _, _} ->
            GoodsInfo = lib_goods_util:get_goods(GoodsId, SellStatus#goods_status.dict),
            Dict = dict:erase(GoodsId, SellStatus#goods_status.dict),
          %% 删除
            NewSellStatus = SellStatus#goods_status{dict = Dict},

            [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
            lib_goods:change_goods_player(GoodsInfo, PlayerStatus#player_status.id, ?GOODS_LOC_BAG, Cell, GoodsStatus),
            NewGoodsStatus = GoodsStatus#goods_status{null_cells=NullCells},
             %% 添加dict
            Dict2 = lib_goods_init:init_goods_online(PlayerStatus#player_status.id, NewGoodsStatus#goods_status.dict),
            NewGoodsStatus2 = NewGoodsStatus#goods_status{dict = Dict2},
            {ok, {PlayerStatus, NewGoodsStatus2, NewSellStatus}};
        _ ->
            ok
    end.

%% 加物品
add_sell(SellInfo) ->
    Id = lib_goods_util:add_sell(SellInfo),
    NewSellInfo = SellInfo#ets_sell{id = Id},
    NewSellInfo.

%% 删除物品
del_sell(Id) ->
    lib_goods_util:del_sell(Id),
    ok.

%% 挂售物品过期
sell_expire(SellList) ->
    F = fun() ->
            L = lists:foldl(fun sell_expire_item/2, [], SellList),
            {ok, L}
        end,
    lib_goods_util:transaction(F).

%% 处理挂售过期商品
sell_expire_item(SellInfo, MailList) ->
    Id = SellInfo#ets_sell.id,
    Sql = io_lib:format(<<"select id from `sell_list` where id=~p ">>, [Id]),
    case db:get_one(Sql) of
        Id when is_number(Id) andalso Id > 0 ->
            del_sell(Id),
            [T, C] = data_sell_text:mail_text(sell),
            Title = io_lib:format(T, [SellInfo#ets_sell.goods_name]),
            Content = io_lib:format(C, [SellInfo#ets_sell.goods_name]),
            case SellInfo#ets_sell.gid =:= 0 of
                true ->
                    case SellInfo#ets_sell.price_type =:= 0 of
                        true ->  
                            {ok, MailInfo} = lib_mail:send_sys_mail(SellInfo#ets_sell.pid, Title, Content, 0, 0, 0, SellInfo#ets_sell.num);
                        false -> 
                            {ok, MailInfo} = lib_mail:send_sys_mail(SellInfo#ets_sell.pid, Title, Content, 0, 0, SellInfo#ets_sell.num, 0)
                    end,
                    [MailId|_] = MailInfo,
                    log:log_sell(3, SellInfo, 0, MailId),
                    [MailInfo|MailList];
                false ->
                    Sql2 = io_lib:format(?SQL_GOODS_UPDATE_CELL, [?GOODS_LOC_MAIL, 0, SellInfo#ets_sell.gid]),
                    db:execute(Sql2),
                    {ok, MailInfo} = lib_mail:send_sys_mail(SellInfo#ets_sell.pid, Title, Content, SellInfo#ets_sell.gid, SellInfo#ets_sell.num, 0, 0),
                    [MailId|_] = MailInfo,
                    log:log_sell(3, SellInfo, 0, MailId),
                    [MailInfo|MailList]
            end;
        _ -> MailList
    end.





