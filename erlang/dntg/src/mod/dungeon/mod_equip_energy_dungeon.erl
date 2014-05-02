-module(mod_equip_energy_dungeon).

%% ====================================================================
%% API functions
%% ====================================================================
-export([handle_info/2]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").


%% ====================================================================
%% Internal functions
%% ====================================================================
%% 物品抽取
handle_info({'extraction_goods', _DungeonId, Type}, State) ->
    EquipDunState = lib_equip_energy_dungeon:get_equip_energy_state(),
    ChouQuCount = EquipDunState#dntk_equip_dun_state.extract_count,
    Goods = EquipDunState#dntk_equip_dun_state.goods,
    DunId = EquipDunState#dntk_equip_dun_state.dun_id,
    Dun = data_dungeon:get(DunId),
    RGift = EquipDunState#dntk_equip_dun_state.all_goods,
    GoodsLen = length(Goods),
    [{PlayerId, PlayerPid}|_] = [{Role#dungeon_player.id, Role#dungeon_player.pid} || Role <- State#dungeon_state.role_list],
    if
        ChouQuCount > 0 andalso Type =:= 1 ->   %% 已经抽取单次过
            {ok, BinData} = pt_611:write(61173, [2, [], 0, 0]),
            lib_server_send:send_to_uid(PlayerId, BinData);
        
        Type =:= 2 andalso GoodsLen =:= 6 ->
            {ok, BinData} = pt_611:write(61173, [5, [], 0, 0]),
            lib_server_send:send_to_uid(PlayerId, BinData);
        
        ChouQuCount =:= 0 andalso Type =:= 1 andalso length(Goods) =:= 0 ->
            GoodList = lib_equip_energy_dungeon:get_rgift_goodid(RGift),
            GoodList1 = lib_equip_energy_dungeon:rotary_gift_rmove_rate(GoodList),
            {GoodsList, TotalCoin, TotalBGold} = lib_equip_energy_dungeon:goods_add_and_get_coin(GoodList1, [], 0, 0),
            lib_equip_energy_dungeon:save_equip_energy_state([{extract_count, ChouQuCount+1}, {goods, GoodList}]),
            spawn(lib_equip_energy_dungeon, send_pass_goods, [PlayerId, PlayerPid, GoodsList, TotalCoin, TotalBGold, Dun#dungeon.name, 2]),
            GoodBinList = lib_equip_energy_dungeon:rotary_gift_to_bin_list(GoodList),
            {ok, BinData} = pt_611:write(61173, [1, GoodBinList, TotalCoin, TotalBGold]),
            lib_server_send:send_to_uid(PlayerId, BinData);
        
        Type =:= 2 andalso  length(Goods) =< 1->
            Len = length(RGift--Goods),
            if
                Len =:= 5 ->
                    GoodList = RGift--Goods;
                true ->
                    if
                        ChouQuCount > 0 ->
                            [_A|GoodList] = RGift;
                        true ->
                            GoodList = RGift
                    end
            end,
            GoodList1 = lib_equip_energy_dungeon:rotary_gift_rmove_rate(GoodList),
            {GoodsList, TotalCoin, TotalBGold} = lib_equip_energy_dungeon:goods_add_and_get_coin(GoodList1, [], 0, 0),
            lib_equip_energy_dungeon:save_equip_energy_state([{goods, RGift}]),
            spawn(lib_equip_energy_dungeon, send_pass_goods, [PlayerId, PlayerPid, GoodsList, TotalCoin, TotalBGold, Dun#dungeon.name, 2]),
            GoodBinList = lib_equip_energy_dungeon:rotary_gift_to_bin_list(GoodList),
            {ok, BinData} = pt_611:write(61173, [1, GoodBinList, TotalCoin, TotalBGold]),
            lib_server_send:send_to_uid(PlayerId, BinData);
        true ->
            {ok, BinData} = pt_611:write(61173, [4, [], 0, 0]),
            lib_server_send:send_to_uid(PlayerId, BinData)
    end,
    {noreply, State};


%% %% 物品抽取
%% handle_info({'extraction_goods', _DungeonId, Type}, State) ->
%%     EquipDunState = lib_equip_energy_dungeon:get_equip_energy_state(),
%%     ChouQuCount = EquipDunState#dntk_equip_dun_state.extract_count,
%%     Goods = EquipDunState#dntk_equip_dun_state.goods,
%%     DunId = EquipDunState#dntk_equip_dun_state.dun_id,
%%     Dun = data_dungeon:get(DunId),
%%     EquipDunConfig = data_equip_gift:get_gift(DunId),
%%     RGift = EquipDunConfig#dntk_equip_dun_config.rotary_gift,
%%     GoodsLen = length(Goods),
%%     [{PlayerId, PlayerPid}|_] = [{Role#dungeon_player.id, Role#dungeon_player.pid} || Role <- State#dungeon_state.role_list],
%%     if
%%         ChouQuCount > 0 andalso Type =:= 1 ->   %% 已经抽取单次过
%%             {ok, BinData} = pt_611:write(61173, [2, [], 0]),
%%             lib_server_send:send_to_uid(PlayerId, BinData);
%%         
%%         Type =:= 2 andalso GoodsLen =:= 6 ->
%%             {ok, BinData} = pt_611:write(61173, [5, [], 0]),
%%             lib_server_send:send_to_uid(PlayerId, BinData);
%%         
%%         ChouQuCount =:= 0 andalso Type =:= 1 andalso length(Goods) =:= 0 ->
%%             GoodList = lib_equip_energy_dungeon:get_rgift_goodid(RGift, util:rand(1, 10000)),
%%             GoodList1 = lib_equip_energy_dungeon:rotary_gift_rmove_rate(GoodList),
%%             {GoodsList, TotalCoin, TotalBGold} = lib_equip_energy_dungeon:goods_add_and_get_coin(GoodList1, [], 0, 0),
%%             lib_equip_energy_dungeon:save_equip_energy_state([{extract_count, ChouQuCount+1}, {goods, GoodList}]),
%%             spawn(lib_equip_energy_dungeon, send_pass_goods, [PlayerId, PlayerPid, GoodsList, TotalCoin, TotalBGold, Dun#dungeon.name, 2]),
%%             GoodBinList = lib_equip_energy_dungeon:rotary_gift_to_bin_list(GoodList),
%%             {ok, BinData} = pt_611:write(61173, [1, GoodBinList, TotalCoin, TotalBGold]),
%%             lib_server_send:send_to_uid(PlayerId, BinData);
%%         
%%         Type =:= 2 andalso  length(Goods) =< 1->
%%             GoodList = RGift--Goods,
%%             GoodList1 = lib_equip_energy_dungeon:rotary_gift_rmove_rate(GoodList),
%%             {GoodsList, TotalCoin, TotalBGold} = lib_equip_energy_dungeon:goods_add_and_get_coin(GoodList1, [], 0, 0),
%%             lib_equip_energy_dungeon:save_equip_energy_state([{goods, RGift}]),
%%             spawn(lib_equip_energy_dungeon, send_pass_goods, [PlayerId, PlayerPid, GoodsList, TotalCoin, TotalBGold, Dun#dungeon.name, 2]),
%%             GoodBinList = lib_equip_energy_dungeon:rotary_gift_to_bin_list(GoodList),
%%             {ok, BinData} = pt_611:write(61173, [1, GoodBinList, TotalCoin, TotalBGold]),
%%             lib_server_send:send_to_uid(PlayerId, BinData);
%%         true ->
%%             {ok, BinData} = pt_611:write(61173, [4, [], 0, 0]),
%%             lib_server_send:send_to_uid(PlayerId, BinData)
%%     end,
%%     {noreply, State};

handle_info(_, State) ->
    util:errlog("~p ~p equip_energy_dungeon_error!~n", [?MODULE, ?LINE]),
    {noreply, State}.


