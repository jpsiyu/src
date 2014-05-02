%%%--------------------------------------
%%% @Module  : pp_shake_money
%%% @Author  : HHL
%%% @Email   : HHL
%%% @Created : 2014.3.7
%%% @Description:  摇钱树
%%%--------------------------------------

-module(pp_shake_money).
-compile(export_all).
-include("server.hrl").
-include("common.hrl").


%% 大闹天空：获取玩家摇钱信息
handle(63101, Status, _) ->
    case Status#player_status.lv >= 30 of
        true ->
            List = mod_shake_money:get_info(),
            {ok, BinData} = pt_631:write(63101, [List]),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        false -> skip
    end;

%% 大闹天空：获取玩家摇钱信息
handle(63108, Status, _) ->
    case Status#player_status.lv >= 30 of
        true ->
            List = mod_shake_money:get_rank_info(),
            %% io:format("~p ~p List:~p~n", [?MODULE,?LINE,List]),
            {ok, BinData} = pt_631:write(63108, [List]),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        false -> skip
    end;


%% 大闹天空：当前次数消耗获得情况 
handle(63102, Status, _) ->
    case Status#player_status.lv >= 30 of
        true ->
            NowTime = util:unixtime(),
            VipType = Status#player_status.vip#status_vip.vip_type,
            VipLevel = Status#player_status.vip#status_vip.growth_lv,
            NormalCount = data_money_config:get_free_times(0),
            FreeCount = data_money_config:get_free_times(VipType),
            GoldCount = data_money_config:get_config(gold_shake_time),
            ToTalCount = FreeCount + GoldCount,
            NowShake = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 8889) + 1,
            if
                NowShake =< FreeCount ->
                    BaseCoefficient = data_money_config:get_free_base_jishu(NowShake),
                    FreeCoin = lib_shake_money:get_coin_num(Status#player_status.lv, BaseCoefficient),
                    FreeCoinAdd = lib_shake_money:get_coin_num_vip_add(VipType, FreeCoin),
                    VipAddTime = FreeCount - NormalCount,
                    ShakeMoneyTime = Status#player_status.shake_money_time,
                    if
                        NowTime < ShakeMoneyTime -> CdTime = ShakeMoneyTime - NowTime;
                        true -> CdTime = 0
                    end,
                    if
                        CdTime =:= 0 -> CoolGold = 0;
                        true -> CoolGold = data_money_config:get_free_gold(NowShake-1)
                    end,
                    LessShake = FreeCount-NowShake+1,
                    List = [0, FreeCoin, FreeCoinAdd, VipType, VipLevel, LessShake, FreeCount, VipAddTime, 0, CdTime, CoolGold],
                    {ok, BinData} = pt_631:write(63102, List);

                NowShake =< ToTalCount ->
                    [BaseCoefficient, Gold] = data_money_config:get(Status#player_status.lv, NowShake - FreeCount),
                    GoldCoin = lib_shake_money:get_coin_num(Status#player_status.lv, BaseCoefficient),
                    GoldCoinAdd = lib_shake_money:get_coin_num_vip_add(VipType, GoldCoin),
                    LessShake = ToTalCount-NowShake+1,
                    List = [1, GoldCoin, GoldCoinAdd, VipType, VipLevel, LessShake, GoldCount, 0, Gold, 0, 0],
                    {ok, BinData} = pt_631:write(63102, List);
                true ->
                    List = [1, 0, 0, VipType, VipLevel, 0, GoldCount, 0, 0, 0, 0],
                    {ok, BinData} = pt_631:write(63102, List)
            end,
            lib_server_send:send_one(Status#player_status.socket, BinData);
        false -> skip
    end;

%% 摇钱消耗信息
handle(63103, Status, [Type]) ->
    case Status#player_status.lv >= 30 of
        true ->
            NowShake = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 8889) + 1,
            TotalShake = data_shake_money:get_max(Status#player_status.lv),
            VipAddPec = case Status#player_status.vip#status_vip.vip_type of
                1 -> 0.03;
                2 -> 0.06;
                3 -> 0.10;
                _ -> 0
            end,
            case NowShake > TotalShake of
                true -> 
                    {ok, BinData} = pt_631:write(63103, [0, 0, 0]);
                false ->
                    case Type of
                        0 -> 
                            [Coin, _Type, Cost] = data_shake_money:get_detail(Status#player_status.lv, NowShake),
                            NewCoin = round(Coin * (1 + VipAddPec)),
                            {ok, BinData} = pt_631:write(63103, [Cost, 0, NewCoin]);
                        1 -> 
                            [_Coin1, _Type1, Cost1] = data_shake_money:get_detail(Status#player_status.lv, NowShake),
                            [_Coin2, _Type2, Cost2] = data_shake_money:get_detail(Status#player_status.lv, NowShake + 1),
                            [_Coin3, _Type3, Cost3] = data_shake_money:get_detail(Status#player_status.lv, NowShake + 2),
                            [_Coin4, _Type4, Cost4] = data_shake_money:get_detail(Status#player_status.lv, NowShake + 3),
                            [_Coin5, _Type5, Cost5] = data_shake_money:get_detail(Status#player_status.lv, NowShake + 4),
                            [_Coin6, _Type6, Cost6] = data_shake_money:get_detail(Status#player_status.lv, NowShake + 5),
                            [_Coin7, _Type7, Cost7] = data_shake_money:get_detail(Status#player_status.lv, NowShake + 6),
                            [_Coin8, _Type8, Cost8] = data_shake_money:get_detail(Status#player_status.lv, NowShake + 7),
                            [_Coin9, _Type9, Cost9] = data_shake_money:get_detail(Status#player_status.lv, NowShake + 8),
                            [_Coin10, _Type10, Cost10] = data_shake_money:get_detail(Status#player_status.lv, NowShake + 9),
                            Cost = Cost1 + Cost2+ Cost3 + Cost4 + Cost5 + Cost6 + Cost7 + Cost8 + Cost9 + Cost10,
                            Coin = _Coin1 + _Coin2 + _Coin3 + _Coin4 + _Coin5 + _Coin6 + _Coin7 + _Coin8 + _Coin9 + _Coin10,
                            NewCoin = round(Coin * (1 + VipAddPec)),
                            {ok, BinData} = pt_631:write(63103, [Cost, 0, NewCoin]);
                        _ -> 
                            {ok, BinData} = pt_631:write(63103, [0, 0, 0])
                    end
            end,
            lib_server_send:send_one(Status#player_status.socket, BinData);
        false -> skip
    end;



%% 大闹天空：摇钱
handle(63104, Status, [NeedGold]) ->
    case Status#player_status.lv >= 30 of
        false -> 
            {ok, BinData} = pt_631:write(63104, [5, 0, 0, 0]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            {ok, Status};
        true ->
            mod_active:trigger(Status#player_status.status_active, 17, 0, Status#player_status.vip#status_vip.vip_type), 
            NowTime = util:unixtime(),
            VipType = Status#player_status.vip#status_vip.vip_type,
            FreeCount = data_money_config:get_free_times(VipType),
            GoldCount = data_money_config:get_config(gold_shake_time),
            ToTalCount = FreeCount + GoldCount,
            NowShake = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 8889) + 1,
            if
                NowShake =< FreeCount -> 
                    ShakeMoneyTime = Status#player_status.shake_money_time,
                    if
                        NowTime < ShakeMoneyTime -> 
                            {ok, BinData} = pt_631:write(63104, [4, 0, 0, 0]),
                            lib_server_send:send_one(Status#player_status.socket, BinData),
                            {ok, Status};
                        true ->
                            BaseCoefficient = data_money_config:get_free_base_jishu(NowShake),
                            FreeCoin = lib_shake_money:get_coin_num(Status#player_status.lv, BaseCoefficient),
                            VipFreeCoinAdd  = lib_shake_money:get_coin_num_vip_add(VipType, FreeCoin),
                            Mutil = data_money_config:get_coin_mutil_rate(1, NowShake),
                            TotalCoin = (FreeCoin+VipFreeCoinAdd)*Mutil,
                            
                            if
                                TotalCoin < 0 ->
                                    {ok, BinData} = pt_631:write(63104, [0, 0, 0, 0]),
                                    lib_server_send:send_one(Status#player_status.socket, BinData),
                                    {ok, Status};
                                true ->
                                   shake_money_op(Status, NowShake, TotalCoin, 0, Mutil)
                            end
                    end;
                NowShake =< ToTalCount -> 
                    [BaseCoefficient, Gold] = data_money_config:get(Status#player_status.lv, NowShake - FreeCount),
                    GoldCoin = lib_shake_money:get_coin_num(Status#player_status.lv, BaseCoefficient),
                    VipGoldCoinAdd = lib_shake_money:get_coin_num_vip_add(VipType, GoldCoin),
                    Mutil = data_money_config:get_coin_mutil_rate(2, NowShake),
                    TotalCoin = (GoldCoin + VipGoldCoinAdd)*Mutil,
                    if
                        Gold < 0 orelse GoldCoin < 0 ->
                            {ok, BinData} = pt_631:write(63104, [2, 0, 0, 0]),
                            lib_server_send:send_one(Status#player_status.socket, BinData),
                            {ok, Status};
                        NeedGold =/= Gold ->
                            {ok, Status};
                        true ->
                            if
                                Status#player_status.bgold + Status#player_status.gold < Gold ->
                                    {ok, BinData} = pt_631:write(63104, [2, 0, 0, 0]),
                                    lib_server_send:send_one(Status#player_status.socket, BinData),
                                    {ok, Status};
                                true ->
                                    shake_money_op(Status, NowShake, TotalCoin, Gold, Mutil)
                            end
                    end;
                true ->
                   NewStatus2 = Status,
                   {ok, BinData} = pt_631:write(63104, [3, 0, 0, 0]),
                   lib_server_send:send_one(Status#player_status.socket, BinData),
                   {ok, NewStatus2}
            end
    end;
    
       

%% 当前级别物品
handle(63105, Status, _) ->
    case Status#player_status.lv >= 30 of
        false -> Status;
        true ->
            List = lib_shake_money:money_list_format(Status#player_status.id, Status#player_status.dailypid),
            {ok, BinData} = pt_631:write(63105, [List]),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end;



handle(63106, Status, [Type]) ->
    case Status#player_status.lv >= 30 of
        false -> Status;
        true ->
            %% ResultList = lib_shake_money:get_shake_money_info(Status),
            ResultList = lib_shake_money:money_list_format(Status#player_status.id, Status#player_status.dailypid),
            NowShakeCount = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 8889),
            case is_integer(Type) andalso lists:member(Type, [8885, 8886, 8887, 8888]) of
                true ->
                    IsGet = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, Type),
                    if
                        IsGet =/= 0 ->
                            {ok, BinData} = pt_631:write(63106, [2, 0, 0, 0]),  %% 已领
                            lib_server_send:send_one(Status#player_status.socket, BinData);
                        true ->
                            case lists:keyfind(Type, 1, ResultList) of
                                {Type, GoodId, IsCanGet, NeedShakeCount, Num} ->
                                    if
                                        IsCanGet =:= 2 ->
                                            {ok, BinData} = pt_631:write(63106, [2, 0, 0, 0]),  %% 已领
                                            lib_server_send:send_one(Status#player_status.socket, BinData);
                                        NowShakeCount < NeedShakeCount ->
                                            {ok, BinData} = pt_631:write(63106, [3, 0, 0, 0]),  %% 未到达领取条件
                                            lib_server_send:send_one(Status#player_status.socket, BinData);
                                        IsCanGet =:= 1 andalso NowShakeCount >= NeedShakeCount ->
                                            lib_shake_money:send_coin_ka(Status, ResultList, Type, GoodId, NeedShakeCount, Num),
                                            handle(63105, Status, [1]);
                                        true ->
                                            {ok, BinData} = pt_631:write(63106, [0, 0, 0, 0]),  %% 领取失败
                                            lib_server_send:send_one(Status#player_status.socket, BinData)
                                    end
                            end
                    end;
                _ ->
                    lib_shake_money:send_coin_ka_auto(Status, ResultList, Type),
                    handle(63105, Status, [1])
            end
    end;

%%　大闹天空： 时间冷却
handle(63107, Status, _) ->
    case Status#player_status.lv >= 30 of
        false -> 
            Status;
        true ->
            VipType = Status#player_status.vip#status_vip.vip_type,
            FreeCount = data_money_config:get_free_times(VipType),
            NowShake = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 8889) + 1,
            CoolGold = data_money_config:get_free_gold(NowShake-1),
            case VipType > 0 of
                true ->
                    case NowShake > FreeCount of
                        true -> Status;
                        false ->
                            {ok, BinData} = pt_631:write(63107, [2, 0]),
                            lib_server_send:send_one(Status#player_status.socket, BinData),
                            NewStatus1 = Status#player_status{shake_money_time = 0},
                            handle(63102, NewStatus1, []),
                            {ok, NewStatus1}
                    end;
                false -> 
                    case NowShake > FreeCount of
                        true -> Status;
                        false ->
                            case CoolGold =< 0 of
                                true -> Status;
                                false ->
                                    case Status#player_status.bgold < CoolGold of
                                        true ->
                                            Gold1 = Status#player_status.bgold + Status#player_status.gold,
                                            if
                                                Gold1 < CoolGold ->
                                                    {ok, BinData} = pt_631:write(63107, [3, 0]),
                                                    lib_server_send:send_one(Status#player_status.socket, BinData),
                                                    {ok, Status};
                                                true ->
                                                    NewStatus1 = lib_goods_util:cost_money(Status, CoolGold, silver_and_gold),
                                                    log:log_consume(tree, gold, Status, NewStatus1, "shake money silver_and_gold"),
                                                    lib_player:refresh_client(Status#player_status.id, 2),                
                                                    {ok, BinData} = pt_631:write(63107, [1, CoolGold]),
                                                    lib_server_send:send_one(Status#player_status.socket, BinData),
                                                    NewStatus2 = NewStatus1#player_status{shake_money_time = 0},
                                                    handle(63102, NewStatus2, []),
                                                    {ok, NewStatus2}
                                            end;
                                        false ->
                                            NewStatus1 = lib_goods_util:cost_money(Status, CoolGold, bgold),
                                            log:log_consume(tree, bgold, Status, NewStatus1, "shake money"),
                                            lib_player:refresh_client(Status#player_status.id, 2),                
                                            {ok, BinData} = pt_631:write(63107, [1, CoolGold]),
                                            lib_server_send:send_one(Status#player_status.socket, BinData),
                                            NewStatus2 = NewStatus1#player_status{shake_money_time = 0},
                                            handle(63102, NewStatus2, []),
                                            {ok, NewStatus2}
                                    end
                            end
                    end
            end
    end;

                      


handle(_Cmd, _LogicStatus, _Data) ->
    ?DEBUG("pp_shake_money no match", []),
    {error, "pp_shake_money no match"}.




%%　大闹天空：
%% Mutil:暴击类型（1：不暴击；2或者4：暴击）
shake_money_op(Status, NowShake, TotalCoin1, Gold, Mutil)->
    TotalCoin = TotalCoin1 + data_money_config:get_rand_num(),
    mod_daily:set_count(Status#player_status.dailypid, Status#player_status.id, 8889, NowShake),
    %% 运势任务（3700007：铜钱天降）
    lib_fortune:fortune_daily(Status#player_status.id, 3700007, 1),
    if
        Status#player_status.bgold < Gold ->
            NewStatus1 = lib_goods_util:cost_money(Status, Gold, silver_and_gold),
            log:log_consume(tree, gold, Status, NewStatus1, "shake_money_silver_and_gold");
        true ->
            NewStatus1 = lib_goods_util:cost_money(Status, Gold, bgold),
            log:log_consume(tree, bgold, Status, NewStatus1, "shake_money_bgold")
    end,
    
    NewStatus2 = lib_player:add_money(NewStatus1, TotalCoin, coin),
    log:log_produce(tree, coin, Status, NewStatus2, "shake money"),
    %%　插入摇钱记录
    mod_shake_money:insert_info(Status#player_status.nickname, TotalCoin, Mutil),
    mod_shake_money:money_rank_add(Status#player_status.id, Status#player_status.nickname, TotalCoin),
    pp_login_gift:handle(31204, Status, no),
    lib_player:refresh_client(Status#player_status.id, 2),
                                    
    {ok, BinData} = pt_631:write(63104, [1, TotalCoin, Gold, Mutil]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    NextShakeMoneyTime = util:unixtime() + data_money_config:get_normal_timespan(NowShake),
    NewStatus3 = NewStatus2#player_status{shake_money_time =  NextShakeMoneyTime},
    if
        NowShake =:= 24 ->
            handle(63106, NewStatus3, [auto_mail]),
            handle(63105, NewStatus3, [1]);
        NowShake > 5 andalso  NowShake < 23 ->
            handle(63105, NewStatus3, [1]);
        true ->
            skip
    end,   
    handle(63102, NewStatus3, []),      
    handle(63101, NewStatus3, []),
    handle(63108, NewStatus3, []),
    {ok, NewStatus3}.
    




