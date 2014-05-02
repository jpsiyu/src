%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-7
%% Description: TODO:
%% --------------------------------------------------------
-module(pp_sell).
-export([handle/3, stop_sell/1]).
-include("def_goods.hrl").
-include("goods.hrl").
-include("server.hrl").
-include("sell.hrl").
-include("common.hrl").

%% 发起交易
handle(18010, PlayerStatus, PlayerId) ->
    case start_sell(PlayerStatus, PlayerId) of
        {fail, Res} ->
            {ok, BinData} = pt_180:write(18010, [Res, PlayerId]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {ok, SellerPlayerStatus} ->
            %% 交易状态通知
            {ok, BinData1} = pt_180:write(18001, [PlayerStatus#player_status.id, 1, 
                                                  PlayerStatus#player_status.nickname, 
                                                  PlayerStatus#player_status.lv, 
                                                  PlayerStatus#player_status.combat_power,
                                                PlayerStatus#player_status.vip#status_vip.vip_type]),
            lib_server_send:send_to_sid(SellerPlayerStatus#player_status.sid, BinData1),
            {ok, BinData} = pt_180:write(18010, [1, PlayerId]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData)
    end;

%% 接受交易
handle(18011, PlayerStatus, PlayerId) ->
    case recv_sell(PlayerStatus, PlayerId) of
        {fail, Res} ->
            {ok, BinData} = pt_180:write(18011, [Res, PlayerId]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {ok, NewPlayerStatus, Player} ->
            %% 交易状态通知
            {ok, BinData1} = pt_180:write(18001, [NewPlayerStatus#player_status.id, 2, 
                                                  NewPlayerStatus#player_status.nickname, 
                                                  NewPlayerStatus#player_status.lv, 
                                                  NewPlayerStatus#player_status.combat_power,
                                              NewPlayerStatus#player_status.vip#status_vip.vip_type]),
%%             util:errlog("Sid = ~p~n", [Player#ets_online.sid]),
            lib_server_send:send_to_sid(Player#ets_online.sid, BinData1),
            {ok, BinData} = pt_180:write(18011, [1, PlayerId]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            {ok, NewPlayerStatus}
    end;

%% 添加或删除交易物品
handle(18012, PlayerStatus, [Action, GoodsId, GoodsTypeId, GoodsNum]) ->
     case lib_secondary_password:is_pass(PlayerStatus) of
         false -> skip;
         true -> 
%%  小号管理,到时加上             
%%             case lib_doubt_account:coin_transaction_captcha(PlayerStatus, GoodsId, GoodsTypeId, 0, 7) of
%%                 true -> skip;
%%                 false -> 
                    Dict = lib_goods_dict:get_player_dict(PlayerStatus),
                    case Action of
                        %% 添加
                        0 -> Result = add_sell_goods(PlayerStatus, GoodsId, GoodsNum, Dict);
                        %% 删除
                        1 -> Result = del_sell_goods(PlayerStatus, GoodsId, GoodsNum)
                    end,
                    case Result of
                        {fail, Res} ->
                            {ok, BinData} = pt_180:write(18012, [Res, 0, 0, 0, 0]),
                            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
                        {ok, NewPlayerStatus} ->
                            Sell = NewPlayerStatus#player_status.sell,
                            %% 查找玩家信息,是否在线
                            case lib_player:get_online_info_global(Sell#status_sell.sell_id) of
                                [] ->
                                    %% 停止交易
                                    stop_sell(PlayerStatus);
                                Player ->
                                    {ok, BinData1} = pt_180:write(18002, [NewPlayerStatus#player_status.id, Sell#status_sell.sell_list]),
                                    lib_server_send:send_to_sid(Player#ets_online.sid, BinData1),
                                    {ok, BinData} = pt_180:write(18012, [1, Action, GoodsId, GoodsTypeId, GoodsNum]),
                                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                    {ok, NewPlayerStatus}
                            end
                    end
%%             end
     end;

%% 锁定交易
handle(18013, PlayerStatus, lock) ->
    case lock_sell(PlayerStatus) of
        {fail, Res} ->
            {ok, BinData} = pt_180:write(18013, Res),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {ok, NewPlayerStatus} ->
            Sell = NewPlayerStatus#player_status.sell,
            case lib_player:get_online_info_global(Sell#status_sell.sell_id) of
                [] -> 
                    stop_sell(PlayerStatus);
                Player ->
                    {ok, BinData1} = pt_180:write(18001, [NewPlayerStatus#player_status.id, 3, 
                                                          NewPlayerStatus#player_status.nickname, 
                                                          NewPlayerStatus#player_status.lv, 
                                                          NewPlayerStatus#player_status.combat_power,
                                                        NewPlayerStatus#player_status.vip#status_vip.vip_type]),
                    lib_server_send:send_to_sid(Player#ets_online.sid, BinData1),
                    {ok, BinData} = pt_180:write(18013, 1),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                    {ok, NewPlayerStatus}
            end
    end;

%% 确认交易
handle(18014, PlayerStatus, confirm) ->
    case confirm_sell(PlayerStatus) of
        {fail, Res} ->
            {ok, BinData} = pt_180:write(18014, Res),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {ok, NewPlayerStatus, SellerPlayerStatus} ->
            Sell = NewPlayerStatus#player_status.sell,
            if  Sell#status_sell.sell_status =:= 5 ->
                    {ok, BinData1} = pt_180:write(18001, [NewPlayerStatus#player_status.id, 5, NewPlayerStatus#player_status.nickname, NewPlayerStatus#player_status.lv, NewPlayerStatus#player_status.combat_power,NewPlayerStatus#player_status.vip#status_vip.vip_type]),
                    lib_server_send:send_to_sid(SellerPlayerStatus#player_status.sid, BinData1),
                    lib_player:refresh_client(SellerPlayerStatus#player_status.id, 2),
                    {ok, BinData2} = pt_180:write(18001, [SellerPlayerStatus#player_status.id, 5, SellerPlayerStatus#player_status.nickname, SellerPlayerStatus#player_status.lv, SellerPlayerStatus#player_status.combat_power,NewPlayerStatus#player_status.vip#status_vip.vip_type]),
                    lib_server_send:send_to_sid(NewPlayerStatus#player_status.sid, BinData2),
                    lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
                    NewPlayerStatus2 = NewPlayerStatus#player_status{sell=Sell#status_sell{sell_status = 0}},
                    NewPlayerStatus2;
                true ->
                    {ok, BinData1} = pt_180:write(18001, [NewPlayerStatus#player_status.id, 4, NewPlayerStatus#player_status.nickname, NewPlayerStatus#player_status.lv, NewPlayerStatus#player_status.combat_power]),
                    lib_server_send:send_one(SellerPlayerStatus#player_status.socket, BinData1),
                    {ok, BinData2} = pt_180:write(18014, 1),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData2),
                    NewPlayerStatus2 = NewPlayerStatus
            end,
%%             lib_captcha:set_unpassed(NewPlayerStatus#player_status.id, 7), %% 重置验证
            {ok, NewPlayerStatus2}
    end;

%% 停止交易
handle(18015, PlayerStatus, stop) ->
    {ok, NewPlayerStatus} = stop_sell(PlayerStatus),
    {ok, BinData} = pt_180:write(18015, 1),
    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
    {ok, NewPlayerStatus};

%% 修改交易金钱
handle(18016, PlayerStatus, [Coin, Gold]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            %%  小号管理,到时加上
%%             case lib_doubt_account:coin_transaction_captcha(PlayerStatus, 0, 0, Coin, 7) of
%%                 true -> skip;
%%                 false -> 
                    case change_money(PlayerStatus, Coin, Gold) of
                        {fail, Res} ->
                            {ok, BinData} = pt_180:write(18016, [Res, 0, 0]),
                            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
                        {ok, NewPlayerStatus} ->
                            Sell = NewPlayerStatus#player_status.sell,
                            case lib_player:get_online_info_global(Sell#status_sell.sell_id) of
                                [] -> 
                                    stop_sell(PlayerStatus);
                                Player ->
                                    {ok, BinData1} = pt_180:write(18003, [NewPlayerStatus#player_status.id, Coin, Gold]),
                                    lib_server_send:send_to_sid(Player#ets_online.sid, BinData1),
                                    {ok, BinData} = pt_180:write(18016, [1, Coin, Gold]),
                                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                    {ok, NewPlayerStatus}
                            end
                    end
%%             end
    end;

%% 挂售物品
handle(18030, PlayerStatus, [GoodsId, Num, PriceType, Price, Time, Show]) ->
    Go = PlayerStatus#player_status.goods,
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'sell_up', PlayerStatus, GoodsId, Num, PriceType, Price, Time, Show}) of
                    {ok, [NewPlayerStatus, Res, SellInfo, GoodsInfo]} ->
                        {ok, BinData} = pt_180:write(18030, [Res, SellInfo]),
                        lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                        case Res =:= 1 of
                            true ->
                                lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
                                %% 传闻
                                case Show =:= 0 of
                                    true ->
                                        skip;
                                    false ->
                                        %lib_cw:send_sell_goods(PlayerStatus, Num, SellInfo, Price, PriceType)
                                        skip
                                end,
                                %% 通知公共线更新,
                                mod_disperse:call_to_unite(lib_sell, sell_up, [SellInfo, GoodsInfo]),
                                ok;
                            false -> skip
                        end,
                        {ok, NewPlayerStatus};
                    {'EXIT',_Reason} -> skip
            end
    end;

%% 取消挂售
handle(18031, PlayerStatus, Id) ->
    Go = PlayerStatus#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'sell_down', PlayerStatus, Id}) of
        {ok, [NewPlayerStatus, Res]} ->
            {ok, BinData} = pt_180:write(18031, [Res, Id]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            case Res =:= 1 of
                true -> lib_player:refresh_client(NewPlayerStatus#player_status.id, 2);
                false -> skip
            end,
            {ok, NewPlayerStatus};
        {'EXIT',_Reason} -> skip
    end;

%% 购买挂售物品
handle(18032, PlayerStatus, Id) ->
     case lib_secondary_password:is_pass(PlayerStatus) of
         false -> skip;
         true ->
                    Go = PlayerStatus#player_status.goods,
                    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'pay_sell', PlayerStatus, Id}) of
                        {ok, [NewPlayerStatus, Res]} ->
                            {ok, BinData} = pt_180:write(18032, [Res, Id]),
                            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                            case Res =:= 1 of
                                true ->
                                    lib_player:refresh_client(NewPlayerStatus#player_status.id, 2);
                                false -> skip
                            end,
                            {ok, NewPlayerStatus};
                        {'EXIT',_Reason} -> skip
                    end
     end;

%% 再次挂售
handle(18033, PlayerStatus, [Id, Flag]) ->
     case lib_secondary_password:is_pass(PlayerStatus) of
         false -> skip;
         true ->
            Go = PlayerStatus#player_status.goods,
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'resell', PlayerStatus, Id}) of
                {ok, [NewPlayerStatus, Res, SellInfo]} ->
                    {ok, BinData} = pt_180:write(18033, [Res, Id, Flag]),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                    case Res =:= 1 of
                        true ->
                            lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
                            mod_disperse:call_to_unite(lib_sell, sell_up, [SellInfo, #goods{}]);
                        false -> skip
                    end,
                    {ok, NewPlayerStatus};
                {'EXIT',_Reason} -> skip
            end
     end;

%% 求购物品
handle(18052, PlayerStatus, [GoodsTypeId, Num, Prefix, Stren, PriceType, Price, Time]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
%% 小号管理,到时加上 
%%             case lib_doubt_account:coin_transaction_captcha(PlayerStatus, 0, 0, 1000, 9) of  
%%                 true -> skip;
%%                 false -> 
                    case lib_buy:buy_up(PlayerStatus, [GoodsTypeId, Num, Prefix, Stren, PriceType, Price, Time]) of
                        {ok, NewPlayerStatus, NewWtbInfo} ->
                            {ok, BinData} = pt_180:write(18052, [1, NewWtbInfo]),
                            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                            mod_disperse:call_to_unite(ets, insert, [?ETS_BUY, NewWtbInfo]),
%%                             lib_captcha:set_unpassed(PlayerStatus#player_status.id, 9), %% 重置验证码
                            {ok, NewPlayerStatus};
                        {fail, Res} ->
                            {ok, BinData} = pt_180:write(18052, [Res, #ets_buy{}]),
                            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
                        _Error ->
                            {ok, BinData} = pt_180:write(18052, [0, #ets_buy{}]),
                            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData)
                    end
%%             end
    end;

%% 取消求购
handle(18053, PlayerStatus, Id) ->
    case lib_buy:buy_down(PlayerStatus, Id) of
        {ok, NewPlayerStatus} ->
            {ok, BinData} = pt_180:write(18053, [1, Id]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
            {ok, NewPlayerStatus};
        {fail, Res} ->
            {ok, BinData} = pt_180:write(18053, [Res, Id]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        _Error ->
            {ok, BinData} = pt_180:write(18053, [0, Id]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData)
    end;

%% 出售求购物品
handle(18054, PlayerStatus, [Id, GoodsId]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            Go = PlayerStatus#player_status.goods,
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'pay_buy', PlayerStatus, Id, GoodsId}) of
                {ok, [NewPlayerStatus, Res, Reload]} ->
                    case Reload =:= 1 of
                        true -> 
                            mod_disperse:call_to_unite(mod_buy, cast_buy_reload, [Id]);
                        false -> 
                            skip
                    end,
                    {ok, BinData} = pt_180:write(18054, [Res, Id]),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                    lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
                    {ok, NewPlayerStatus};
                {'EXIT',_Reason} -> skip
            end
    end;

handle(_Cmd, _Status, _Data) ->
    ?INFO("pp_box no match: ~p", [[_Cmd,_Data]]),
    {error, pp_sell_no_match}.

%% -------------------- private function ------------------------------------------------
%% 发起交易
start_sell(PlayerStatus, PlayerId) ->
    Sell = PlayerStatus#player_status.sell,
    if  %% 角色ID错误
        PlayerId =< 0 ->
            {fail, 2};
        PlayerStatus#player_status.id =:= PlayerId ->
            {fail, 2};
        %% 正在交易中
        Sell#status_sell.sell_status > 0 ->
            {fail, 3};
        true ->
            case lib_player:get_player_info(PlayerId) of
                %% 找不到玩家
                Seller when is_record(Seller, player_status) =:= true andalso Seller#player_status.id =:= 0 -> 
                    {fail, 4};
                SellerPlayerStatus when is_record(SellerPlayerStatus, player_status) =:= true andalso SellerPlayerStatus#player_status.sid =/= 0 ->
                    Sell2 = SellerPlayerStatus#player_status.sell,
                    if  %% 玩家正在交易中
                        Sell2#status_sell.sell_status > 0 ->
                            {fail, 5};
                        true ->
                            {ok, SellerPlayerStatus}
                    end;
                _ ->
                    {fail, 4}
            end
    end.

%% 接受交易
recv_sell(PlayerStatus, PlayerId) ->
    Sell = PlayerStatus#player_status.sell,
    if  %% 角色ID错误
        PlayerId =< 0 ->
            {fail, 2};
        PlayerStatus#player_status.id =:= PlayerId ->
            {fail, 2};
        %% 玩家正在交易中
        Sell#status_sell.sell_status > 0 ->
            {fail, 3};
        true ->
            case lib_player:get_online_info_global(PlayerId) of
                %% 找不到玩家
                [] -> {fail, 4};
                Player ->
                    case gen:call(Player#ets_online.pid, '$gen_call', {'recv_sell', PlayerStatus#player_status.id}) of
                        {ok, {fail, Res}} -> 
                            {fail, Res};
                        {ok, ok} ->
                            Go = PlayerStatus#player_status.goods,
                            gen_server:cast(Go#status_goods.goods_pid, {'recv_sell'}),
                            Sell = PlayerStatus#player_status.sell,
                            NewPlayerStatus = PlayerStatus#player_status{sell=Sell#status_sell{sell_id=PlayerId, sell_status=1}},
                            {ok, NewPlayerStatus, Player};
                        {'EXIT',_Reason} -> {fail, 0}
                    end
            end
    end.

%% 添加交易物品
add_sell_goods(PlayerStatus, GoodsId, GoodsNum, Dict) ->
    Sell = PlayerStatus#player_status.sell,
    if  %% 玩家不在交易状态
        Sell#status_sell.sell_status < 1 ->
            {fail, 2};
        %% 已锁定交易，不可添加物品
        Sell#status_sell.sell_status > 1 ->
            {fail, 3};
        %% 物品不存在
        GoodsId =< 0 ->
            {fail, 5};
        %% 只可交易六件物品
        length(Sell#status_sell.sell_list) >= 6 ->
            {fail, 11};
        true ->
            add_goods(PlayerStatus, GoodsId, GoodsNum, Dict)
    end.
add_goods(PlayerStatus, GoodsId, GoodsNum, Dict) ->
    Sell = PlayerStatus#player_status.sell,
    SellList = Sell#status_sell.sell_list,
    case lists:keyfind(GoodsId, 1, SellList) of
        %% 物品已经存在
        {GoodsId, _, _} -> {fail, 10};
        false ->
            GoodsInfo = lib_goods_util:get_goods(GoodsId, Dict),
            if  %% 物品不存在
                is_record(GoodsInfo, goods) =:= false ->
                    {fail, 5};
                %% 物品不属于交易者所有
                GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
                    {fail, 6};
                %% 物品不在背包
                GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
                    {fail, 7};
                %% 物品数量不正确
                GoodsNum < 1 orelse GoodsInfo#goods.num =/= GoodsNum ->
                    {fail, 8};
                %% 物品不可交易
                GoodsInfo#goods.bind =:= 2 orelse GoodsInfo#goods.trade =:= 1 ->
                    {fail, 9};
                true ->
                    NewSellList = SellList ++ [{GoodsId, GoodsInfo#goods.goods_id, GoodsNum}],
                    NewPlayerStatus = PlayerStatus#player_status{sell = Sell#status_sell{sell_list = NewSellList}},
                    {ok, NewPlayerStatus}
            end
    end.

%% 删除交易物品
del_sell_goods(PlayerStatus, GoodsId, GoodsNum) ->
    Sell = PlayerStatus#player_status.sell,
    if  %% 玩家不在交易状态
        Sell#status_sell.sell_status < 1 ->
            {fail, 2};
        %% 已锁定交易，不可删改物品
        Sell#status_sell.sell_status > 1 ->
            {fail, 3};
        %% 物品不存在
        GoodsId =< 0 ->
            {fail, 5};
        %% 物品数量不正确
        GoodsNum < 1 ->
            {fail, 8};
        true ->
            del_goods(PlayerStatus, GoodsId, GoodsNum)
    end.

del_goods(PlayerStatus, GoodsId, GoodsNum) ->
    Sell = PlayerStatus#player_status.sell,
    SellList = Sell#status_sell.sell_list,
    case lists:keyfind(GoodsId, 1, SellList) of
        %% 物品不存在
        false -> {fail, 5};
        {GoodsId, GoodsTypeId, Num} ->
            NewGoodsNum = Num - GoodsNum,
            if  %% 物品数量不正确
                NewGoodsNum < 0 ->
                    {fail, 8};
                true ->
                    case NewGoodsNum =:= 0 of
                        true ->  
                            NewSellList = lists:keydelete(GoodsId, 1, SellList);
                        false -> 
                            NewSellList = lists:keyreplace(GoodsId, 1, SellList, {GoodsId, GoodsTypeId, NewGoodsNum})
                    end,
                    NewPlayerStatus = PlayerStatus#player_status{sell = Sell#status_sell{sell_list=NewSellList}},
                    {ok, NewPlayerStatus}
            end
    end.

%% 锁定交易
lock_sell(PlayerStatus) ->
    Sell = PlayerStatus#player_status.sell,
    if  %% 玩家不在交易状态
        Sell#status_sell.sell_status < 1 ->
            {fail, 2};
        %% 已锁定交易
        Sell#status_sell.sell_status > 1 ->
            {fail, 3};
        true ->
            NewPlayerStatus = PlayerStatus#player_status{sell = Sell#status_sell{sell_status=3}},
            {ok, NewPlayerStatus}
    end.

%% 确认交易
confirm_sell(PlayerStatus) ->
    Sell = PlayerStatus#player_status.sell,
    if  %% 玩家不在交易状态
        Sell#status_sell.sell_status < 1 ->
            {fail, 2};
        %% 还没有锁定
        Sell#status_sell.sell_status =/= 3 ->
            {fail, 3};
        true ->
            case lib_player:get_player_info(Sell#status_sell.sell_id) of
                %% 找不到玩家
                [] -> {fail, 4};
                SellerPlayerStatus ->
                    Sell2 = SellerPlayerStatus#player_status.sell,
                    if  %% 对方还没有锁定
                        Sell2#status_sell.sell_status < 3 ->
                            {fail, 5};
                        %% 对方已确认
                        Sell2#status_sell.sell_status =:= 4 ->
                            NewPlayerStatus = PlayerStatus#player_status{sell = Sell#status_sell{sell_status = 4}},
                            finish_sell(NewPlayerStatus, SellerPlayerStatus);
                        true ->
                            NewPlayerStatus = PlayerStatus#player_status{sell = Sell#status_sell{sell_status = 4}},
                            {ok, NewPlayerStatus, SellerPlayerStatus}
                    end
            end
    end.

%% 修改交易金钱
change_money(PlayerStatus, Coin, Gold) ->
    Sell = PlayerStatus#player_status.sell,
    if  %% 玩家不在交易状态
        Sell#status_sell.sell_status < 1 ->
            {fail, 2};
        %% 已锁定交易，不可添加物品
        Sell#status_sell.sell_status > 1 ->
            {fail, 3};
        %% 玩家金钱不足
        PlayerStatus#player_status.coin < Coin ->
            {fail, 4};
        %% 不可交易元宝
        Gold > 0 ->
            {fail, 5};
        true ->
            SellList = Sell#status_sell.sell_list,
            case lists:keyfind(money, 1, SellList) of
                {money, _, _} ->
                    NewSellList = lists:keyreplace(money, 1, SellList, {money, Coin, Gold});
                false ->
                    NewSellList = [{money, Coin, Gold} | SellList]
            end,
            NewPlayerStatus = PlayerStatus#player_status{sell = Sell#status_sell{sell_list=NewSellList}},
            {ok, NewPlayerStatus}
    end.

%% 完成交易
finish_sell(PlayerStatus, SellerPlayerStatus) ->
    Go = PlayerStatus#player_status.goods,
    case catch (gen:call(Go#status_goods.goods_pid, '$gen_call', {'finish_sell_one', PlayerStatus, SellerPlayerStatus})) of
        {ok, {fail, Res}} -> 
            {fail, Res};
        {ok, {ok, NewPlayerStatus, NewSellerPlayerStatus}} -> 
            {ok, NewPlayerStatus, NewSellerPlayerStatus};
        {'EXIT',_Reason} -> 
            {fail, 0}
    end.

%% 中断交易
stop_sell(PlayerStatus) ->
    Sell = PlayerStatus#player_status.sell,
    Goods = PlayerStatus#player_status.goods,
    if  Sell#status_sell.sell_status > 0 ->
            if  Sell#status_sell.sell_id > 0 ->
                    case lib_player:get_online_info(Sell#status_sell.sell_id) of
                        [] -> 
                            skip;
                        Player ->
                            gen_server:cast(Player#ets_online.pid, {'stop_sell'})
                    end;
                true -> skip
            end,
            gen_server:cast(Goods#status_goods.goods_pid, {'stop_sell'}),
            NewPlayerStatus = PlayerStatus#player_status{sell=Sell#status_sell{sell_status=0, sell_id=0, sell_list=[]}},
            {ok, BinData} = pt_180:write(18001, [NewPlayerStatus#player_status.id, 0, NewPlayerStatus#player_status.nickname, 
                                                NewPlayerStatus#player_status.lv, NewPlayerStatus#player_status.combat_power, NewPlayerStatus#player_status.vip#status_vip.vip_type]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            {ok, NewPlayerStatus};
        true ->
            {ok, PlayerStatus}
    end.



