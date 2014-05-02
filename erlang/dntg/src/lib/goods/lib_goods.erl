%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-14
%% Description: 物品信息
%% --------------------------------------------------------
-module(lib_goods).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("server.hrl").
-include("drop.hrl").

add_stren7_num(GoodsInfo, Stren7_num) ->
    case GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP andalso lists:member(GoodsInfo#goods.cell, ?EQUIP_SHINE_LIMIT) of
        true ->
            [A,B,C,D,E,F,G,H,I,J,K,L|_] = [ [X] || X <- integer_to_list(Stren7_num)],
            Stren = case GoodsInfo#goods.stren >= ?EQUIP_SHINE_STREN of
                        true -> GoodsInfo#goods.stren - 4;
                        false -> 1
                    end,
            case GoodsInfo#goods.cell of
                1 -> list_to_integer(lists:concat([Stren,B,C,D,E,F,G,H,I,J,K,L]));
                2 -> list_to_integer(lists:concat([A,Stren,C,D,E,F,G,H,I,J,K,L]));
                3 -> list_to_integer(lists:concat([A,B,Stren,D,E,F,G,H,I,J,K,L]));
                4 -> list_to_integer(lists:concat([A,B,C,Stren,E,F,G,H,I,J,K,L]));
                5 -> list_to_integer(lists:concat([A,B,C,D,Stren,F,G,H,I,J,K,L]));
                6 -> list_to_integer(lists:concat([A,B,C,D,E,Stren,G,H,I,J,K,L]));
                7 -> list_to_integer(lists:concat([A,B,C,D,E,F,Stren,H,I,J,K,L]));
                8 ->list_to_integer(lists:concat([A,B,C,D,E,F,G,Stren,I,J,K,L]));
                9 ->list_to_integer(lists:concat([A,B,C,D,E,F,G,H,Stren,J,K,L]));
                10 ->list_to_integer(lists:concat([A,B,C,D,E,F,G,H,I,Stren,K,L]));
                11 ->list_to_integer(lists:concat([A,B,C,D,E,F,G,H,I,J,Stren,L]));
                12 ->list_to_integer(lists:concat([A,B,C,D,E,F,G,H,I,J,K,Stren]));
                _ -> Stren7_num
            end;
        false -> Stren7_num
    end.

minus_stren7_num(GoodsInfo, Stren7_num) ->
    case GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP andalso lists:member(GoodsInfo#goods.cell, ?EQUIP_SHINE_LIMIT) of
        true ->
            [A,B,C,D,E,F,G,H,I,J,K,L|_] = [ [X] || X <- integer_to_list(Stren7_num)],
            case GoodsInfo#goods.cell of
                1 -> list_to_integer(lists:concat([1,B,C,D,E,F,G,H,I,J,K,L]));
                2 -> list_to_integer(lists:concat([A,1,C,D,E,F,G,H,I,J,K,L]));
                3 -> list_to_integer(lists:concat([A,B,1,D,E,F,G,H,I,J,K,L]));
                4 -> list_to_integer(lists:concat([A,B,C,1,E,F,G,H,I,J,K,L]));
                5 -> list_to_integer(lists:concat([A,B,C,D,1,F,G,H,I,J,K,L]));
                6 -> list_to_integer(lists:concat([A,B,C,D,E,1,G,H,I,J,K,L]));
                7 -> list_to_integer(lists:concat([A,B,C,D,E,F,1,H,I,J,K,L]));
                8 -> list_to_integer(lists:concat([A,B,C,D,E,F,G,1,I,J,K,L]));
                9 -> list_to_integer(lists:concat([A,B,C,D,E,F,G,H,1,J,K,L]));
                10 -> list_to_integer(lists:concat([A,B,C,D,E,F,G,H,I,1,K,L]));
                11 -> list_to_integer(lists:concat([A,B,C,D,E,F,G,H,I,J,1,L]));
                12 -> list_to_integer(lists:concat([A,B,C,D,E,F,G,H,I,J,K,1]));
                _ -> Stren7_num
            end;
        false -> Stren7_num
    end.

get_min_stren7_num(Stren7_num) ->
    [_,B,C,D,E,F,G|_] = [ list_to_integer([X]) || X <- integer_to_list(Stren7_num)],
    case lists:min([B,C,D,E,F,G]) of
        N when N > 1 -> N + 4;
        N -> N
    end.

get_min_stren7_num2(Stren7_num) ->
    [A,B,C,D,E,F,G,H,I,J,K,L|_] = [ list_to_integer([X]) || X <- integer_to_list(Stren7_num)],
    case lists:min([A,B,C,D,E,F,G,H,I,J,K,L]) of
        N when N > 1 -> N + 4;
        N -> N
    end.

is_cache(Location) ->
	lists:member(Location, ?GOODS_LOC_CACHE).

%%装备物品
equip_goods(PlayerStatus, GoodsStatus, GoodsInfo, Location, Cell) ->
    Sell = PlayerStatus#player_status.sell,
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            OldGoodsInfo = lib_goods_util:get_goods_by_cell(PlayerStatus#player_status.id, Location, Cell, GoodsStatus#goods_status.dict),
            G = PlayerStatus#player_status.goods,
            case is_record(OldGoodsInfo, goods) of
                %% 存在已装备的物品，则替换
                true ->
                    NullCells = GoodsStatus#goods_status.null_cells,
                    case OldGoodsInfo#goods.use_num > G#status_goods.equip_attrit of
                        true -> 
							UseNum = OldGoodsInfo#goods.use_num - G#status_goods.equip_attrit;
                        false -> 
							UseNum = 0
                    end,
                    [NewOldGoodsInfo, NewStatus1] = change_goods_cell_and_use(OldGoodsInfo, GoodsInfo#goods.location, GoodsInfo#goods.cell, UseNum, GoodsStatus),
                    [NewGoodsInfo, NewStatus2] = change_goods_cell(GoodsInfo, Location, Cell, NewStatus1),
                    EquipSuit = lib_goods_util:change_equip_suit(GoodsStatus#goods_status.equip_suit, OldGoodsInfo#goods.suit_id, GoodsInfo#goods.suit_id);
				%% 不存在
                false ->
                    NewOldGoodsInfo = OldGoodsInfo,
                    [NewGoodsInfo, NewStatus1] = change_goods_cell(GoodsInfo, Location, Cell, GoodsStatus),
                    NullCells = case GoodsInfo#goods.location =:= ?GOODS_LOC_BAG of
                                    true -> 
										lists:sort([GoodsInfo#goods.cell | NewStatus1#goods_status.null_cells]);
                                    false -> 
										NewStatus1#goods_status.null_cells
                                end,
                    EquipSuit = lib_goods_util:add_equip_suit(NewStatus1#goods_status.equip_suit, GoodsInfo#goods.suit_id),
                    NewStatus2 = NewStatus1
            end,
            [CurrentEquip, _] = lib_goods_util:get_current_equip_by_info(NewGoodsInfo, [NewStatus2#goods_status.equip_current, on]),
            SuitId = lib_goods_util:get_full_suit(EquipSuit),
            Stren7_num = add_stren7_num(NewGoodsInfo, NewStatus2#goods_status.stren7_num),
            NewStatus = NewStatus2#goods_status{null_cells = NullCells, equip_suit = EquipSuit,suit_id = SuitId, 
												  stren7_num = Stren7_num, equip_current = CurrentEquip},
            case NewGoodsInfo#goods.bind =:= 1 orelse NewGoodsInfo#goods.subtype =:= 60 orelse NewGoodsInfo#goods.subtype =:= 61 orelse NewGoodsInfo#goods.subtype =:= 62 orelse NewGoodsInfo#goods.subtype =:= 63 orelse NewGoodsInfo#goods.subtype =:= 64 orelse NewGoodsInfo#goods.subtype =:= 65 of
                true -> 
					NewGoodsInfo2 = bind_goods(NewGoodsInfo);
                false -> 
					NewGoodsInfo2 = NewGoodsInfo
            end,
            
            case lists:keyfind(GoodsInfo#goods.id, 1, Sell#status_sell.sell_list) of
                false -> 
                    SellList = Sell#status_sell.sell_list;
                _ ->  
                    SellList = lists:keydelete(GoodsInfo#goods.id, 1, Sell#status_sell.sell_list)
            end,
            Fashion = [GoodsInfo#goods.goods_id,GoodsInfo#goods.stren],
            G = PlayerStatus#player_status.goods,
            NewPlayerStatus = case GoodsInfo#goods.subtype of
                                  ?GOODS_FASHION_WEAPON ->
                                      FashionId = lib_fashion_change:get_change_before(PlayerStatus#player_status.change_dict, 2, GoodsInfo#goods.id),
                                      if
                                          FashionId =:= 0 ->
                                              PlayerStatus#player_status{goods=G#status_goods{fashion_weapon = Fashion}, sell=Sell#status_sell{sell_list = SellList}};
                                          true ->
                                              PlayerStatus#player_status{goods=G#status_goods{fashion_weapon = [FashionId, GoodsInfo#goods.stren]}, sell=Sell#status_sell{sell_list = SellList}}
                                      end;
                                  ?GOODS_FASHION_ARMOR -> 
                                      FashionId = lib_fashion_change:get_change_before(PlayerStatus#player_status.change_dict, 1, GoodsInfo#goods.id),
                                      if
                                          FashionId =:= 0 ->
									          PlayerStatus#player_status{goods=G#status_goods{fashion_armor = Fashion}, sell=Sell#status_sell{sell_list = SellList}};
                                          true ->
                                              PlayerStatus#player_status{goods=G#status_goods{fashion_armor = [FashionId, GoodsInfo#goods.id]}, sell=Sell#status_sell{sell_list = SellList}}
                                      end;
                                  ?GOODS_FASHION_ACCESSORY ->
                                      FashionId = lib_fashion_change:get_change_before(PlayerStatus#player_status.change_dict, 3, GoodsInfo#goods.id),
                                      if
                                          FashionId =:= 0 ->
									        PlayerStatus#player_status{goods=G#status_goods{fashion_accessory = Fashion}, sell=Sell#status_sell{sell_list = SellList}};
                                          true ->
                                            PlayerStatus#player_status{goods=G#status_goods{fashion_accessory = [FashionId, GoodsInfo#goods.stren]}, sell=Sell#status_sell{sell_list = SellList}}
                                    end;
                                ?GOODS_FASHION_HEAD ->
                                      FashionId = lib_fashion_change:get_change_before(PlayerStatus#player_status.change_dict, 4, GoodsInfo#goods.id),
                                      if
                                          FashionId =:= 0 ->
									        PlayerStatus#player_status{goods=G#status_goods{fashion_head = Fashion}, sell=Sell#status_sell{sell_list = SellList}};
                                          true ->
                                            PlayerStatus#player_status{goods=G#status_goods{fashion_head = [FashionId, GoodsInfo#goods.stren]}, sell=Sell#status_sell{sell_list = SellList}}
                                    end;
                                ?GOODS_FASHION_TAIL ->
                                      FashionId = lib_fashion_change:get_change_before(PlayerStatus#player_status.change_dict, 5, GoodsInfo#goods.id),
                                      if
                                          FashionId =:= 0 ->
									        PlayerStatus#player_status{goods=G#status_goods{fashion_tail = Fashion}, sell=Sell#status_sell{sell_list = SellList}};
                                          true ->
                                            PlayerStatus#player_status{goods=G#status_goods{fashion_tail = [FashionId, GoodsInfo#goods.stren]}, sell=Sell#status_sell{sell_list = SellList}}
                                    end;
                                ?GOODS_FASHION_RING ->
                                      FashionId = lib_fashion_change:get_change_before(PlayerStatus#player_status.change_dict, 6, GoodsInfo#goods.id),
                                      if
                                          FashionId =:= 0 ->
									        PlayerStatus#player_status{goods=G#status_goods{fashion_ring = Fashion}, sell=Sell#status_sell{sell_list = SellList}};
                                          true ->
                                            PlayerStatus#player_status{goods=G#status_goods{fashion_ring = [FashionId, GoodsInfo#goods.stren]}, sell=Sell#status_sell{sell_list = SellList}}
                                    end;
                                  _ -> 
									  PlayerStatus#player_status{sell=Sell#status_sell{sell_list = SellList}}
                              end,
            L1 = lists:member(GoodsInfo#goods.goods_id, ?ARMOR),
            L2 = lists:member(GoodsInfo#goods.goods_id, ?WEAPON),
            L3 = lists:member(GoodsInfo#goods.goods_id, ?ACCESSORY),
            L4 = lists:member(GoodsInfo#goods.goods_id, ?HEAD),
            L5 = lists:member(GoodsInfo#goods.goods_id, ?TAIL),
            L6 = lists:member(GoodsInfo#goods.goods_id, ?RING),
            if
                L1 =:= true ->
                    NewPS = lib_fashion_change2:update_wardrobe(NewPlayerStatus, 1, 0, GoodsInfo#goods.goods_id),
                    lib_fashion_change2:get_wear_degree(NewPS);
                L2 =:= true ->
                    NewPS = lib_fashion_change2:update_wardrobe(NewPlayerStatus, 2, 0, GoodsInfo#goods.goods_id),
                    lib_fashion_change2:get_wear_degree(NewPS);
                L3 =:= true ->
                    NewPS = lib_fashion_change2:update_wardrobe(NewPlayerStatus, 3, 0, GoodsInfo#goods.goods_id),
                    lib_fashion_change2:get_wear_degree(NewPS);
                L4 =:= true ->
                    NewPS = lib_fashion_change2:update_wardrobe(NewPlayerStatus, 5, 0, GoodsInfo#goods.goods_id),
                    lib_fashion_change2:get_wear_degree(NewPS);
                L5 =:= true ->
                    NewPS = lib_fashion_change2:update_wardrobe(NewPlayerStatus, 6, 0, GoodsInfo#goods.goods_id),
                    lib_fashion_change2:get_wear_degree(NewPS);
                L6 =:= true ->
                    NewPS = lib_fashion_change2:update_wardrobe(NewPlayerStatus, 7, 0, GoodsInfo#goods.goods_id),
                    lib_fashion_change2:get_wear_degree(NewPS);
                true ->
                    NewPS = NewPlayerStatus
            end,
            
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            Dict2 = lib_goods_dict:add_dict_goods(NewGoodsInfo2, Dict),
            NewStatus3 = NewStatus#goods_status{dict = Dict2},
            {ok, NewPS, NewStatus3, NewOldGoodsInfo}
        end,
    case lib_goods_util:transaction(F) of
        {ok, NewPlayerStatus, NewStatus, NewOldGoodsInfo} ->
            %% 人物属性重新计算
            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus),
            %% 大闹目标(202)
            catch mod_target:trigger(
                NewPlayerStatus#player_status.status_target, 
                NewPlayerStatus#player_status.id, 
                202, 
                length(lib_goods_util:get_equip_list(NewPlayerStatus#player_status.id, NewStatus#goods_status.dict))
            ),
            {ok, NewPlayerStatus2, NewStatus, NewOldGoodsInfo};
        Error ->
            util:errlog("equip_goods error: ~p~n", [Error])
    end.

%%卸下装备
unequip_goods(PlayerStatus, GoodsStatus, GoodsInfo) ->
	F = fun() ->
				ok = lib_goods_dict:start_dict(),
				Location = ?GOODS_LOC_BAG,
				[Cell|NullCells] = GoodsStatus#goods_status.null_cells,
                G = PlayerStatus#player_status.goods,
				case GoodsInfo#goods.use_num > G#status_goods.equip_attrit of
					true ->
						UseNum = GoodsInfo#goods.use_num - G#status_goods.equip_attrit;
					false ->
						UseNum = 0
				end,
				%% 修改物品背包位置和使用次数
				[NewGoodsInfo, NewStatus1] = change_goods_cell_and_use(GoodsInfo, Location, Cell, UseNum, GoodsStatus),
				%删除套装
				EquipSuit = lib_goods_util:del_equip_suit(GoodsStatus#goods_status.equip_suit, GoodsInfo#goods.suit_id),
				%套装ID
				SuitId = lib_goods_util:get_full_suit(EquipSuit),
				%强化+7数
				Stren7_num = minus_stren7_num(GoodsInfo, GoodsStatus#goods_status.stren7_num),
				%当前装备
				[CurrentEquip, _] = lib_goods_util:get_current_equip_by_info(NewGoodsInfo, [GoodsStatus#goods_status.equip_current, off]),
				%物品新属性
				NewStatus = NewStatus1#goods_status{null_cells = NullCells, equip_suit = EquipSuit, suit_id = SuitId, 
									stren7_num = Stren7_num, equip_current = CurrentEquip},
				PlayerStatus1 = case GoodsInfo#goods.subtype of
                                  	?GOODS_FASHION_WEAPON -> 
									  	PlayerStatus#player_status{goods=G#status_goods{fashion_weapon = [0,0]}};
                                  	?GOODS_FASHION_ARMOR -> 
									  	PlayerStatus#player_status{goods=G#status_goods{fashion_armor = [0,0]}};
                                  	?GOODS_FASHION_ACCESSORY -> 
									  	PlayerStatus#player_status{goods=G#status_goods{fashion_accessory = [0,0]}};
                                    ?GOODS_FASHION_HEAD ->
                                        PlayerStatus#player_status{goods=G#status_goods{fashion_head = [0,0]}};
                                    ?GOODS_FASHION_TAIL ->
                                        PlayerStatus#player_status{goods=G#status_goods{fashion_tail = [0,0]}};
                                    ?GOODS_FASHION_RING ->
                                        PlayerStatus#player_status{goods=G#status_goods{fashion_ring = [0,0]}};
                                    
                                 	 _ -> PlayerStatus
                              	end,
            	Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                NewStatus2 = NewStatus#goods_status{dict = Dict},
            	{ok, PlayerStatus1, NewStatus2, NewGoodsInfo}
        end,
	case lib_goods_util:transaction(F) of
		{ok, PlayerStatus2, NewStatus, NewGoodsInfo2} ->
			%% 人物属性重新计算,写数据库
            {ok, NewPlayerStatus3} = lib_goods_util:count_role_equip_attribute(PlayerStatus2, NewStatus),
            {ok, NewPlayerStatus3, NewStatus, NewGoodsInfo2};
        Error ->
            util:errlog("unequip_goods error:~p", [Error])
    end.

%% 修理装备
mend_goods(PlayerStatus, GoodsStatus, GoodsInfo) ->
	UseNum = data_goods:count_goods_use_num(GoodsInfo#goods.equip_type, GoodsInfo#goods.attrition),
    [_, NewGoodsStatus1] = change_goods_use(GoodsInfo, UseNum, GoodsStatus),
	NewGoodsInfo = GoodsInfo#goods{use_num = UseNum},
	%扣费
	Cost = data_goods:count_mend_cost(GoodsInfo),
	NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
    NewDict = lib_goods_dict:add_dict_goods(NewGoodsInfo, NewGoodsStatus1#goods_status.dict),
    NewStatus1 = NewGoodsStatus1#goods_status{dict = NewDict},
	% 写消费日志 Equip:装备, Mend:修理
	About = lists:concat(["Equip",GoodsInfo#goods.goods_id," Mend ",GoodsInfo#goods.attrition]),
	log:log_consume(goods_mend, coin, PlayerStatus, NewPlayerStatus, About),
	case GoodsInfo#goods.use_num =< 0 of
		%身上装备位置磨损为0
		true when GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
			% 人物属性重新计算
			EquipSuit = lib_goods_util:add_equip_suit(GoodsStatus#goods_status.equip_suit, NewGoodsInfo#goods.suit_id),
			NewStatus = NewStatus1#goods_status{equip_suit = EquipSuit},
            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus),
            {ok, NewPlayerStatus2, NewStatus, Cost};
        _ ->
            {ok, NewPlayerStatus, NewStatus1, Cost}
     end.
	
%% 修理装备列表
mend_goods_list(PlayerStatus, GoodsStatus, GoodsList) ->
	F = fun() ->
				ok = lib_goods_dict:start_dict(),
				{Cost, HasZero, EquipSuit, NewStatus2} = handle_mend_list(GoodsList, {0, 0, GoodsStatus#goods_status.equip_suit, GoodsStatus}),
				%扣费
				NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
				%写日志 mend_all:全部修理
				About = lists:concat(["mend_all"]),
				log:log_consume(goods_mend, coin, PlayerStatus, NewPlayerStatus, About),
				Dict = lib_goods_dict:handle_dict(NewStatus2#goods_status.dict),
                NewStatus = NewStatus2#goods_status{dict = Dict},
				{ok, NewPlayerStatus, Cost, HasZero, EquipSuit, NewStatus}
		end,
	case lib_goods_util:transaction(F) of
		{ok, NewPlayerStatus, Cost, HasZero, EquipSuit, NewStatus} ->
			case HasZero =:= 1 of
				true ->
					%之前磨损为0
					NewStatus1 = NewStatus#goods_status{equip_suit = EquipSuit},
					%人物属性计算
					{ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus),
					{ok, NewPlayerStatus2, NewStatus1, Cost};
				false ->
					{ok, NewPlayerStatus, NewStatus, Cost}
			end;
		Error ->
			util:errlog("mend_goods_list lib_goods_util:transaction(F) error:~p", [Error])
    end.

handle_mend_list([], {Cost, HasZero, EquipSuit, GoodsStatus}) ->
    {Cost, HasZero, EquipSuit, GoodsStatus};
handle_mend_list([GoodsInfo|H], {Cost, HasZero, EquipSuit, GoodsStatus}) ->
    UseNum = data_goods:count_goods_use_num(GoodsInfo#goods.equip_type, GoodsInfo#goods.attrition),
	[_, NewStatus1] = change_goods_use(GoodsInfo, UseNum, GoodsStatus),
	NewCost = Cost + data_goods:count_mend_cost(GoodsInfo),
	case GoodsInfo#goods.use_num =< 0 andalso GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP of
		true ->
            NewEquipSuit = lib_goods_util:add_equip_suit(EquipSuit, GoodsInfo#goods.suit_id),
            NewHasZero = 1;
        false ->
            NewEquipSuit = EquipSuit,
            NewHasZero = HasZero
	end,
    handle_mend_list(H, {NewCost, NewHasZero, NewEquipSuit, NewStatus1}).
				
%% 背包拖动物品	
drag_goods(GoodsStatus, GoodsInfo, OldCell, NewCell) ->
	GoodsInfo2 = lib_goods_util:get_goods_by_cell(GoodsStatus#goods_status.player_id, ?GOODS_LOC_BAG, NewCell, GoodsStatus#goods_status.dict),
	GoodsTypeInfo = data_goods_type:get(GoodsInfo#goods.goods_id),
	% 最大叠加数
    Max = GoodsTypeInfo#ets_goods_type.max_overlap,
	F = fun() ->
				ok = lib_goods_dict:start_dict(),
				case is_record(GoodsInfo2, goods) of
					%%新位置没有物品
					false ->
						[NewGoodsInfo2, NewStatus1] = change_goods_cell(GoodsInfo, ?GOODS_LOC_BAG, NewCell, GoodsStatus),	%%修改物品位置
						NullCells = lists:delete(NewCell, NewStatus1#goods_status.null_cells),		%删除空格
						NewNullCells = lists:sort([OldCell|NullCells]), %%新的空格数
						NewStatus = NewStatus1#goods_status{null_cells = NewNullCells},
						Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                        NewStatus2 = NewStatus#goods_status{dict = Dict},
						{ok, NewStatus2, [#goods{}, NewGoodsInfo2]};
					%%新位置有相同类型物品
					true when Max > 1 andalso GoodsInfo2#goods.goods_id =:= GoodsInfo#goods.goods_id
					  andalso GoodsInfo2#goods.bind =:= GoodsInfo#goods.bind 
					  andalso GoodsInfo2#goods.expire_time =:= GoodsInfo#goods.expire_time ->
						[GoodsNum2,_, GoodsStatus1] = update_overlap_goods(GoodsInfo2, [GoodsInfo#goods.num, Max, GoodsStatus]),	%%更新物品数量
						case GoodsNum2 > 0 of
							true -> %合不完,还有剩下的,更新两物品的属性
								[NewGoodsInfo1, NewGoodsStatus] = change_goods_num(GoodsInfo, GoodsNum2, GoodsStatus1),
								NewGoodsInfo2 = GoodsInfo2#goods{num = (GoodsInfo2#goods.num + GoodsInfo#goods.num - GoodsNum2)},
								Dict = lib_goods_dict:handle_dict(NewGoodsStatus#goods_status.dict),
                                NewGoodsStatus2 = NewGoodsStatus#goods_status{dict=Dict},
								{ok, NewGoodsStatus2, [NewGoodsInfo1, NewGoodsInfo2]};
							false -> %拖完
								NewGoodsStatus = delete_goods2(GoodsInfo, GoodsStatus), %删除原来物品
								NullCells = lists:sort([GoodsInfo#goods.cell|NewGoodsStatus#goods_status.null_cells]),
								NewStatus = NewGoodsStatus#goods_status{null_cells = NullCells},
								NewGoodsInfo2 = GoodsInfo2#goods{num = (GoodsInfo2#goods.num + GoodsInfo#goods.num)},
								Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                                NewGoodsStatus2 = NewStatus#goods_status{dict=Dict},
								{ok, NewGoodsStatus2, [#goods{id = GoodsInfo#goods.id}, NewGoodsInfo2]}
						end;
					%%新位置有物品
					true ->
						%调换位置
						[NewGoodsInfo2, NewStatus1] = change_goods_cell(GoodsInfo, ?GOODS_LOC_BAG, NewCell, GoodsStatus),
						[NewGoodsInfo1, NewStatus2] = change_goods_cell(GoodsInfo2, ?GOODS_LOC_BAG, OldCell, NewStatus1),
						Dict = lib_goods_dict:handle_dict(NewStatus2#goods_status.dict),
                        NewStatus3 = NewStatus2#goods_status{dict = Dict},
						{ok, NewStatus3, [NewGoodsInfo1, NewGoodsInfo2]}
				end
		end,
	lib_goods_util:transaction(F).
	
%% 整理背包
clean_bag(GoodsInfo, [Num, OldGoodsInfo, GoodsStatus]) ->
     %io:format("Num = ~p, cell=~p~n", [Num, GoodsInfo#goods.cell]),
    case is_record(OldGoodsInfo, goods) of
        %% 与上一格子物品类型相同
        true when GoodsInfo#goods.goods_id =:= OldGoodsInfo#goods.goods_id
                    andalso GoodsInfo#goods.bind =:= OldGoodsInfo#goods.bind
                    andalso GoodsInfo#goods.expire_time =:= OldGoodsInfo#goods.expire_time ->
            GoodsTypeInfo = data_goods_type:get(GoodsInfo#goods.goods_id),
            case GoodsTypeInfo#ets_goods_type.max_overlap > 1 of
                %% 可叠加
                true ->
                    [NewGoodsNum, _, NewGoodsStatus] = update_overlap_goods(OldGoodsInfo, [GoodsInfo#goods.num, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsStatus]),
                    case NewGoodsNum > 0 of
                        %% 还有剩余
                        true ->
                            [NewGoodsInfo, NewStatus] = case GoodsInfo#goods.cell =/= Num orelse GoodsInfo#goods.num =/= NewGoodsNum of
                                                true -> 
                                                    change_goods_cell_and_num(GoodsInfo, ?GOODS_LOC_BAG, Num, NewGoodsNum, NewGoodsStatus);
                                                false -> 
                                                    [GoodsInfo, NewGoodsStatus]
                                           end,
                            [Num+1, NewGoodsInfo, NewStatus];
                        %% 没有剩余
                        false ->
                            NewStatus = delete_goods2(GoodsInfo, NewGoodsStatus),
                            NewGoodsNum1 = OldGoodsInfo#goods.num + GoodsInfo#goods.num,
                            NewOldGoodsInfo = OldGoodsInfo#goods{num = NewGoodsNum1},
                            [Num, NewOldGoodsInfo, NewStatus]
                    end;
                %% 不可叠加
                false ->
                    [NewGoodsInfo, NewStatus] = case GoodsInfo#goods.cell =/= Num of
                                        true -> 
                                            change_goods_cell(GoodsInfo, ?GOODS_LOC_BAG, Num, GoodsStatus);
                                        false -> 
                                            [GoodsInfo, GoodsStatus]
                                   end,
                    [Num+1, NewGoodsInfo, NewStatus]
            end;
        %% 与上一格子类型不同
        true ->
            [NewGoodsInfo, NewStatus] = case GoodsInfo#goods.cell =/= Num of
                                true -> 
                                    change_goods_cell(GoodsInfo, ?GOODS_LOC_BAG, Num, GoodsStatus);
                                false -> 
                                    [GoodsInfo, GoodsStatus]
                           end,
            [Num+1, NewGoodsInfo, NewStatus];
        false ->
            [NewGoodsInfo, NewStatus] = case GoodsInfo#goods.cell =/= Num of
                                true -> 
                                    change_goods_cell(GoodsInfo, ?GOODS_LOC_BAG, Num, GoodsStatus);
                                false -> 
                                    [GoodsInfo, GoodsStatus]
                           end,
            [Num+1, NewGoodsInfo, NewStatus]
    end.

%% 拣取地上掉落包的物品
drop_choose(PlayerStatus, Status, GoodsTypeInfo, DropId) ->
    case mod_drop:get_drop(DropId) of
        {} ->
            {fail, 2};
        DropInfo ->
            mod_drop:delete_drop(DropId),
            %% 添加物品
            NewInfo = lib_goods_util:get_new_goods(GoodsTypeInfo),
            F = fun() ->
                    ok = lib_goods_dict:start_dict(),
                    case DropInfo#ets_drop.goods_id of
                        ?GOODS_ID_COIN -> %% 铜钱
                            NewGoodsInfo = NewInfo,
                            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, DropInfo#ets_drop.num, coin),
                            log:log_produce(goods_drop, coin, PlayerStatus, NewPlayerStatus, ""),
                            NewStatus = Status;
                        _ when DropInfo#ets_drop.gid > 0 ->
                            NewPlayerStatus = PlayerStatus,
                            [Cell|NullCells] = Status#goods_status.null_cells,
                            GoodsInfo = lib_goods_util:get_goods(DropInfo#ets_drop.gid, Status#goods_status.dict),
                            NewGoodsInfo = lib_goods_util:change_goods_player(GoodsInfo, Status#goods_status.player_id, ?GOODS_LOC_BAG, Cell),
                            NewStatus = Status#goods_status{null_cells = NullCells};
                        _ when GoodsTypeInfo#ets_goods_type.max_overlap =< 1 ->
                            NewPlayerStatus = PlayerStatus,
                            [Cell|NullCells] = Status#goods_status.null_cells,
                            Bind = case DropInfo#ets_drop.bind > 0 of 
                                       true -> 
                                           2; 
                                       false -> 
                                           GoodsTypeInfo#ets_goods_type.bind 
                                   end,
                            Trade = case Bind > 0 of 
                                        true -> 
                                            1; 
                                        false -> 
                                            GoodsTypeInfo#ets_goods_type.trade 
                                    end,
                            Info = NewInfo#goods{player_id = Status#goods_status.player_id, num=1, 
                                   prefix = DropInfo#ets_drop.prefix, stren = DropInfo#ets_drop.stren, 
                                   bind=Bind, trade=Trade, cell=Cell, location=?GOODS_LOC_BAG},
                            [NewGoodsInfo, NewStatus1] = add_goods(Info, Status),
                            NewStatus = NewStatus1#goods_status{null_cells = NullCells};
                        _ when GoodsTypeInfo#ets_goods_type.max_overlap > 1 ->
                            NewPlayerStatus = PlayerStatus,
                            Bind = case DropInfo#ets_drop.bind > 0 of 
                                       true -> 
                                           2; 
                                       false -> 
                                           GoodsTypeInfo#ets_goods_type.bind 
                                   end,
                            Trade = case Bind > 0 of 
                                        true -> 
                                            1; 
                                        false -> 
                                            GoodsTypeInfo#ets_goods_type.trade 
                                    end,
                            NewGoodsInfo = NewInfo#goods{player_id = Status#goods_status.player_id, 
                                                         num = DropInfo#ets_drop.num, bind=Bind, trade=Trade},
                            {ok, NewStatus} = add_goods_base(Status, GoodsTypeInfo, DropInfo#ets_drop.num, NewGoodsInfo)
                    end,
                    if  DropInfo#ets_drop.mon_id > 0 orelse DropInfo#ets_drop.goods_id == 602001 ->
                            if  %% 紫色以下装备忽略
                                NewGoodsInfo#goods.type =:= ?GOODS_TYPE_EQUIP andalso NewGoodsInfo#goods.color < 3 -> skip;
                                %% 血药忽略
                                NewGoodsInfo#goods.type =:= ?GOODS_TYPE_DRUG andalso NewGoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_HP -> skip;
                                %% 蓝药忽略
                                NewGoodsInfo#goods.type =:= ?GOODS_TYPE_DRUG andalso NewGoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_MP -> skip;
                                %% 红包忽略
                                NewGoodsInfo#goods.goods_id =:= 531701 -> skip;
                                %% 英雄帖忽略
                                NewGoodsInfo#goods.type =:= ?GOODS_TYPE_COMPOSE andalso NewGoodsInfo#goods.subtype =:= 10 -> skip;
                                %% 行镖令忽略
                                %NewGoodsInfo#goods.type =:= ?GOODS_TYPE_OBJECT andalso NewGoodsInfo#goods.subtype =:= 25 -> skip;
                                %% 1级二锅头,2级二锅头忽略
                                NewGoodsInfo#goods.goods_id =:= 214001 orelse NewGoodsInfo#goods.goods_id =:= 214002 -> skip;
                                %% 1级木材堆,2级木材堆忽略
                                NewGoodsInfo#goods.goods_id =:= 673001 orelse NewGoodsInfo#goods.goods_id =:= 673002 -> skip;
                                true ->
                                    log:log_goods(mon_drop, DropInfo#ets_drop.mon_id, NewGoodsInfo#goods.goods_id, NewGoodsInfo#goods.num, NewGoodsInfo#goods.player_id)
                            end;
                        true -> 
                            %% 特殊场景的掉落记录
                            %% VIP副本
                            VipDunScene = data_vip_dun:get_vip_dun_config(scene_id),
                            %% 结婚场景
                            MarScene = data_marriage:get_marriage_config(scene_id),
                            SpeScene = [VipDunScene, MarScene],
                            case lists:member(DropInfo#ets_drop.scene, SpeScene) of
                                true ->
                                    log:log_goods(mon_drop, DropInfo#ets_drop.mon_id, NewGoodsInfo#goods.goods_id, NewGoodsInfo#goods.num, NewGoodsInfo#goods.player_id);
                                false ->
                                    skip
                            end
                    end,
                    Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                    NewStatus2 = NewStatus#goods_status{dict = Dict},
                    {ok, NewPlayerStatus, NewStatus2, NewGoodsInfo}
                end,
            lib_goods_util:transaction(F)
    end.

%% 拆分物品
split(GoodsStatus, GoodsInfo, GoodsNum) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            NewNum = GoodsInfo#goods.num - GoodsNum,
            [_, NewGoodsStatus] = change_goods_num(GoodsInfo, NewNum, GoodsStatus),
            [Cell|NullCells] = NewGoodsStatus#goods_status.null_cells,
            NewInfo = GoodsInfo#goods{id = 0, cell = Cell, num = GoodsNum},
            [NewGoodsInfo, NewStatus1] = add_goods(NewInfo, NewGoodsStatus),
            NewStatus = NewStatus1#goods_status{null_cells = NullCells},
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
            {ok, NewStatus2, NewGoodsInfo}
        end,
    lib_goods_util:transaction(F).

%% 使用替身娃娃完成任务
finish_task(GoodsStatus, GoodsList, GoodsTypeId, GoodsNum, TaskId) ->
    case lib_task:auto_finish(TaskId, GoodsStatus#goods_status.player_id) of
        true -> 
            [NewStatus, _] = lists:foldl(fun delete_one/2, [GoodsStatus, GoodsNum], GoodsList),
            log:log_goods_use(GoodsStatus#goods_status.player_id, GoodsTypeId, GoodsNum),
            {ok, NewStatus};
        %% 完成任务失败
        false -> 
            {fail, 5}
    end.

%% 送东西
send_gift(PlayerStatus, GoodsTypeInfo, Coin, Gold, PlayerId) ->
    F = fun() ->
            %% 花费铜钱
            case Gold > 0 of
                true ->
                    NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Gold, gold),
                    % Fortune:刷运势
                    log:log_consume(send_gift, gold, PlayerStatus, NewPlayerStatus, "Fortune");
                false ->
                    NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Coin, rcoin),
                    log:log_consume(send_gift, coin, PlayerStatus, NewPlayerStatus, "Fortune")
            end,
            [Title, Con] = data_sell_text:mail_text(send),
            Content = io_lib:format(Con, [PlayerStatus#player_status.nickname, binary_to_list(GoodsTypeInfo#ets_goods_type.goods_name)]),
            {ok, MailInfo} = lib_mail:send_sys_mail(PlayerId, Title, Content, GoodsTypeInfo#ets_goods_type.goods_id, 1, 2, 0, 0, 1, 0, 0, 0, 0),
            {ok, NewPlayerStatus, [MailInfo]}
        end,
    lib_goods_util:transaction(F).

%%物品存入邮件附件
movein_mail(GoodsStatus, GoodsInfo, GoodsNum, PlayerId, MailInfo, PlayerInfo) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            case GoodsNum >= GoodsInfo#goods.num of
                %% 全部
                true ->
                    [NewGoodsInfo, NewStatus1] = change_goods_player(GoodsInfo, PlayerId, ?GOODS_LOC_MAIL, 0, GoodsStatus),
                    NullCells = lists:sort([GoodsInfo#goods.cell|NewStatus1#goods_status.null_cells]),
                    NewStatus = NewStatus1#goods_status{null_cells = NullCells};
                %% 部分
                false ->
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    [_, NewGoodsStatus] = change_goods_num(GoodsInfo, NewNum, GoodsStatus),
                    NewInfo = GoodsInfo#goods{id=0, player_id=PlayerId, location=?GOODS_LOC_MAIL, cell=0, num=GoodsNum},
                    [NewGoodsInfo, NewStatus1] = add_goods(NewInfo, NewGoodsStatus),
                    NewStatus = NewStatus1
            end,
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
            {ok, MailAttribute} = mod_disperse:call_to_unite(lib_mail, handle_mail_send, [MailInfo, PlayerInfo, NewGoodsInfo#goods.id]),
            {ok, NewStatus2, NewGoodsInfo, MailAttribute}
        end,
    lib_goods_util:transaction(F).

%%取邮件附件
moveout_mail(GoodsStatus, GoodsInfo, MailId) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
            [_, NewGoodsStatus] = change_goods_cell(GoodsInfo, ?GOODS_LOC_BAG, Cell, GoodsStatus),
            lib_mail:delete_attachment_on_db(MailId),
            NewStatus = NewGoodsStatus#goods_status{null_cells=NullCells},
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
            {ok, NewStatus2}
        end,
    lib_goods_util:transaction(F).

%% 购买VIP绑定卡
pay_vip_upgrade(PlayerStatus, GoodsTypeInfo, GoodsStatus) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 花费铜钱
            Cost = GoodsTypeInfo#ets_goods_type.price,
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, gold), 
            Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
            case Info#goods.bind > 0 of
                true ->
                    Bind = Info#goods.bind,
                    Trade = 1;
                false ->
                    Bind = 1,
                    Trade = 1
            end,
            [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
            NewGoodsStatus = GoodsStatus#goods_status{null_cells = NullCells},
            GoodsInfo = Info#goods{player_id = PlayerStatus#player_status.id, location = ?GOODS_LOC_BAG, cell=Cell, num=1, bind=Bind, trade=Trade},
            %% 添加物品
            [NewGoodsInfo, NewGoodsStatus1] = add_goods(GoodsInfo, NewGoodsStatus),
            log:log_consume(pay_vip_upgrade, gold, PlayerStatus, NewPlayerStatus, NewGoodsInfo#goods.goods_id, 1, ["pay_vip_upgrade"]),
            Dict = lib_goods_dict:handle_dict(NewGoodsStatus1#goods_status.dict),
            NewGoodsStatus2 = NewGoodsStatus1#goods_status{dict = Dict},
            {ok, NewPlayerStatus, NewGoodsStatus2, NewGoodsInfo}
    end,
    lib_goods_util:transaction(F).

%% 扩展背包
expand_bag(PlayerStatus, GoodsStatus, Type, Num, Gold) ->
    F = fun() ->
        case Type of
            1 ->
                NewPlayerStatus1 = lib_goods_util:cost_money(PlayerStatus, Gold, gold),
                NewPlayerStatus = lib_goods_util:extend_bag(NewPlayerStatus1, Num),
                NullCells = lists:seq((PlayerStatus#player_status.cell_num+1), NewPlayerStatus#player_status.cell_num),
                NewNullCells = GoodsStatus#goods_status.null_cells ++ NullCells,
                NewGoodsStatus = GoodsStatus#goods_status{null_cells = NewNullCells},
                log:log_consume(extend_bag, gold, PlayerStatus, NewPlayerStatus, ["extend_bag"]),
                {ok, NewPlayerStatus, NewGoodsStatus};
            2 ->
                NewPlayerStatus1 = lib_goods_util:cost_money(PlayerStatus, Gold, gold),
                NewPlayerStatus = lib_storage_util:extend_storage(NewPlayerStatus1, Num),
                log:log_consume(extend_bag, gold, PlayerStatus, NewPlayerStatus, ["extend_storage"]),
                {ok, NewPlayerStatus, GoodsStatus};
            _ ->
                {ok, PlayerStatus, GoodsStatus}
        end
    end,
    lib_goods_util:transaction(F).
              
%% 赠送物品
give_goods({info, GoodsInfo}, GoodsStatus) ->
    case data_goods_type:get(GoodsInfo#goods.goods_id) of
        %% 物品不存在
        [] -> 
            throw({error, {GoodsInfo#goods.goods_id, not_found}});
        GoodsTypeInfo ->
            GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsInfo#goods.goods_id, 
                                                           GoodsInfo#goods.bind, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
            CellNum = lib_storage_util:get_null_cell_num(GoodsList, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsInfo#goods.num),
            case length(GoodsStatus#goods_status.null_cells) < CellNum of
                %% 背包格子不足
                true -> 
                    throw({error, {cell_num, not_enough}});
                false -> 
                    add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsInfo#goods.num, GoodsInfo, GoodsList)
            end
    end;
give_goods({GoodsTypeId, GoodsNum}, GoodsStatus) -> 
    case data_goods_type:get(GoodsTypeId) of
        %% 物品不存在
        [] -> 
            throw({error, {GoodsTypeId, not_found}});
        GoodsTypeInfo ->
            GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, GoodsTypeInfo#ets_goods_type.bind,
                                                            ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
            CellNum = lib_storage_util:get_null_cell_num(GoodsList, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsNum),
            case length(GoodsStatus#goods_status.null_cells) < CellNum of
                %% 背包格子不足
                true -> 
                    throw({error, {cell_num, not_enough}});
                false ->
                    GoodsInfo = lib_goods_util:get_new_goods(GoodsTypeInfo),
                    add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo, GoodsList)
            end
    end;
give_goods({goods, GoodsTypeId, GoodsNum}, GoodsStatus) ->
    case data_goods_type:get(GoodsTypeId) of
        %% 物品不存在
        [] -> 
            throw({error, {GoodsTypeId, not_found}});
        GoodsTypeInfo ->
            GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, GoodsTypeInfo#ets_goods_type.bind, 
                                                           ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
            CellNum = lib_storage_util:get_null_cell_num(GoodsList, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsNum),
            case length(GoodsStatus#goods_status.null_cells) < CellNum of
                %% 背包格子不足
                true -> 
                    throw({error, {cell_num, not_enough}});
                false ->
                    GoodsInfo = lib_goods_util:get_new_goods(GoodsTypeInfo),
                    add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo, GoodsList)
            end
    end;
give_goods({goods, GoodsTypeId, GoodsNum, Bind}, GoodsStatus) ->
    case data_goods_type:get(GoodsTypeId) of
        %% 物品不存在
        [] -> 
            throw({error, {GoodsTypeId, not_found}});
        GoodsTypeInfo ->
            GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, Bind, 
                                                           ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
            CellNum = lib_storage_util:get_null_cell_num(GoodsList, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsNum),
            case length(GoodsStatus#goods_status.null_cells) < CellNum of
                %% 背包格子不足
                true -> 
                    throw({error, {cell_num, not_enough}});
                false ->
                    Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
                    GoodsInfo = case Bind > 0 of 
                                    true -> 
                                        Info#goods{bind=Bind, trade=1}; 
                                    false -> 
                                        Info 
                                end,
                    add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo, GoodsList)
            end
    end;
give_goods({goods, GoodsTypeId, GoodsNum, Prefix, Stren, Bind}, GoodsStatus) ->
    case data_goods_type:get(GoodsTypeId) of
        %% 物品不存在
        [] -> 
            throw({error, {GoodsTypeId, not_found}});
        TypeInfo ->
            GoodsTypeInfo = if Bind > 0 -> TypeInfo#ets_goods_type{bind=Bind, trade=1};
                                true -> TypeInfo
                            end,
            GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, 
                                                           GoodsTypeInfo#ets_goods_type.bind, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
            CellNum = lib_storage_util:get_null_cell_num(GoodsList, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsNum),
            case length(GoodsStatus#goods_status.null_cells) < CellNum of
                %% 背包格子不足
                true -> throw({error, {cell_num, not_enough}});
                false ->
                    Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
%% 婚戒,以后补上                     
                    GoodsInfo = case Info#goods.type =:= ?GOODS_TYPE_EQUIP andalso Info#goods.subtype =:= 70 of
                                    true ->
                                        %Note = none,%lib_couple:get_ring_owner(GoodsStatus#goods_status.player_id),
                                        Info#goods{prefix = Prefix, stren = Stren};
                                    false -> Info#goods{prefix = Prefix, stren = Stren}
                                end,
                    add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo, GoodsList)
            end
    end;
give_goods({equip, GoodsTypeId, Prefix, Stren}, GoodsStatus) ->
    case data_goods_type:get(GoodsTypeId) of
        %% 物品不存在
        [] -> 
            throw({error, {GoodsTypeId, not_found}});
        GoodsTypeInfo ->
            case length(GoodsStatus#goods_status.null_cells) =:= 0 of
                %% 背包格子不足
                true -> throw({error, {cell_num, not_enough}});
                false ->
                    NewInfo = lib_goods_util:get_new_goods(GoodsTypeInfo),
                    GoodsInfo = NewInfo#goods{prefix=Prefix, stren=Stren},
                    add_goods_base(GoodsStatus, GoodsTypeInfo, 1, GoodsInfo, [])
            end
    end.

add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo) ->
    case GoodsTypeInfo#ets_goods_type.max_overlap > 1 of
        true ->
            List = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeInfo#ets_goods_type.goods_id, 
                                                      GoodsInfo#goods.bind, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
            GoodsList = lib_goods_util:sort(List, cell);
        false ->
            GoodsList = []
    end,
    add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo, GoodsList).

add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo, GoodsList) -> 
    %% 插入物品记录
    case GoodsTypeInfo#ets_goods_type.max_overlap > 1 of
        true ->
            %% io:format("~p ~p die_jia!~n", [?MODULE, ?LINE]),
            %% io:format("~p ~p GoodsNum:~p~n", [?MODULE, ?LINE, GoodsNum]),
            %% 更新原有的可叠加物品
            [GoodsNum2,_, NewGoodsStatus] = lists:foldl(fun update_overlap_goods/2, [GoodsNum, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsStatus], GoodsList),
            %% 添加新的可叠加物品
            [NewGoodsStatus2,_,_,_] = lib_goods_util:deeploop(fun add_overlap_goods/2, GoodsNum2, 
						[NewGoodsStatus, GoodsInfo, ?GOODS_LOC_BAG, GoodsTypeInfo#ets_goods_type.max_overlap]);
        false ->
            %% io:format("~p ~p bu_die_jia!~n", [?MODULE, ?LINE]),
            %% 添加新的不可叠加物品
            AllNums = lists:seq(1, GoodsNum),
            [NewGoodsStatus2,_,_] = lists:foldl(fun add_nonlap_goods/2, [GoodsStatus, GoodsInfo, ?GOODS_LOC_BAG], AllNums)
    end,
    {ok, NewGoodsStatus2}.

%% 添加新的可叠加物品
add_overlap_goods(Num, [GoodsStatus, GoodsInfo, Location, MaxOverlap]) ->
    case Num > MaxOverlap of
        true ->
            NewNum = Num - MaxOverlap,
            OldNum = MaxOverlap;
        false ->
            NewNum = 0,
            OldNum = Num
    end,
    case OldNum > 0 of
        true when length(GoodsStatus#goods_status.null_cells) > 0 ->
            [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
            NewGoodsStatus1 = GoodsStatus#goods_status{null_cells = NullCells},
            NewGoodsInfo = GoodsInfo#goods{player_id=GoodsStatus#goods_status.player_id, location=Location, cell=Cell, num=OldNum},
            [_, NewGoodsStatus] = add_goods(NewGoodsInfo, NewGoodsStatus1);
         _ ->
             NewGoodsStatus = GoodsStatus
    end,
    [NewNum, [NewGoodsStatus, GoodsInfo, Location, MaxOverlap]].

%% 添加新的不可叠加物品
add_nonlap_goods(_, [GoodsStatus, GoodsInfo, Location]) ->
    case length(GoodsStatus#goods_status.null_cells) > 0 of
        true ->
            [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
            NewGoodsStatus1 = GoodsStatus#goods_status{null_cells = NullCells},
            NewGoodsInfo3 = GoodsInfo#goods{player_id = GoodsStatus#goods_status.player_id, location = Location, cell = Cell, num = 1},
            [_, NewGoodsStatus] = add_goods(NewGoodsInfo3, NewGoodsStatus1);
        false ->
            NewGoodsStatus = GoodsStatus
    end,
    [NewGoodsStatus, GoodsInfo, Location].

%%更新原有的可叠加物品
update_overlap_goods(GoodsInfo, [Num, Max, GoodsStatus]) ->
    %% io:format("~p ~p Num:~p~n", [?MODULE, ?LINE, Num]),
	case Num > 0 of
		true when GoodsInfo#goods.num =/= Max andalso Max > 0 ->
			case Num + GoodsInfo#goods.num > Max of
				true -> %%超出最大数量
					NewNum = Num + GoodsInfo#goods.num - Max,
					OldNum = Max;
				false ->
					OldNum = Num + GoodsInfo#goods.num,
					NewNum = 0
			end,
			[_, NewGoodsStatus] = change_goods_num(GoodsInfo, OldNum, GoodsStatus);
		true ->
            NewGoodsStatus  = GoodsStatus,
			NewNum = Num;	
		false ->
            NewGoodsStatus  = GoodsStatus,
			NewNum = 0
	end,
	[NewNum, Max, NewGoodsStatus].	

%% 添加新物品信息
add_goods(GoodsInfo, GoodsStatus) ->
	GoodsId = lib_goods_util:add_goods(GoodsInfo),
	NewGoodsInfo = GoodsInfo#goods{id = GoodsId},
	case is_cache (NewGoodsInfo#goods.location) of
		true ->
			Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
            NewStatus = GoodsStatus#goods_status{dict = Dict};
		false ->
			NewStatus = GoodsStatus
	end,
	[NewGoodsInfo, NewStatus].

%% 删除物品
delete_goods(GoodsInfo, GoodsStatus) ->
    NewStatus = delete_goods2(GoodsInfo, GoodsStatus),
    if  GoodsInfo#goods.location =:= ?GOODS_LOC_BAG ->
            NullCells = lists:sort([GoodsInfo#goods.cell|NewStatus#goods_status.null_cells]),
            NewStatus#goods_status{null_cells=NullCells};
        true -> NewStatus
    end.
delete_goods2(GoodsInfo, GoodsStatus) ->
	lib_goods_util:delete_goods(GoodsInfo#goods.id),
	case is_cache(GoodsInfo#goods.location) of
		true ->
			Dict = lib_goods_dict:append_dict({del, goods, GoodsInfo#goods.id}, GoodsStatus#goods_status.dict),
            NewStatus = GoodsStatus#goods_status{dict = Dict};
		false ->
            Dict = lib_goods_dict:append_dict({del, goods, GoodsInfo#goods.id}, GoodsStatus#goods_status.dict),
			NewStatus = GoodsStatus#goods_status{dict = Dict}
	end,
    NewStatus.

%% 删除多个物品
%% @spec delete_more(Status, GoodsList, GoodsNum) -> {ok, NewStatus}
delete_more(Status, GoodsList, GoodsNum) ->
    GoodsList1 = lib_goods_util:sort(GoodsList, bind),
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            [NewStatus, _] = lists:foldl(fun delete_one/2, [Status, GoodsNum], GoodsList1),
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
            {ok, NewStatus2}
        end,
    lib_goods_util:transaction(F).

delete_one(GoodsInfo, [GoodsStatus, GoodsNum]) ->
    if GoodsNum > 0 andalso GoodsInfo#goods.id > 0 ->
            case GoodsInfo#goods.num > GoodsNum of
                %% 部分
                true ->
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    [_NewGoodsInfo, NewStatus] = change_goods_num(GoodsInfo, NewNum, GoodsStatus),
                    [NewStatus, 0];
                %% 全部
                false ->
                    NewNum = GoodsNum - GoodsInfo#goods.num,
                    NewStatus = delete_goods(GoodsInfo, GoodsStatus),
                    [NewStatus, NewNum]
            end;
        true ->
            [GoodsStatus, GoodsNum]
    end.

delete_one(GoodsStatus, GoodsInfo, GoodsNum) ->
    case GoodsInfo#goods.num > GoodsNum of
        %% 部分
        true when GoodsNum > 0 ->
            NewNum = GoodsInfo#goods.num - GoodsNum,
            [_NewGoodsInfo, NewGoodsStatus] = change_goods_num(GoodsInfo, NewNum, GoodsStatus),
            {ok, NewGoodsStatus, 0};
        %% 全部
        _ ->
            NewNum = case GoodsNum > GoodsInfo#goods.num of
                         true -> 
                             GoodsNum - GoodsInfo#goods.num;
                         false -> 
                             0
                     end,
            NewStatus = delete_goods(GoodsInfo, GoodsStatus),
            {ok, NewStatus, NewNum}
    end.

%% 删除物品列表
%% @spec delete_goods_list(GoodsStatus, GoodsList) -> {ok, NewStatus} | Error
delete_goods_list(GoodsStatus, GoodsList) ->
    F = fun({GoodsInfo, GoodsNum}, Status1) ->
                [Status2, _] = delete_one(GoodsInfo, [Status1, GoodsNum]),
                Status2
        end,
    NewStatus = lists:foldl(F, GoodsStatus, GoodsList),
    {ok, NewStatus}.

%% 更改物品格子位置和使用数量
change_goods_cell_and_use(GoodsInfo, Location, Cell, UseNum, GoodsStatus) ->
	NewGoodsInfo = lib_goods_util:change_goods_cell_and_use(GoodsInfo, Location, Cell, UseNum),
    case is_cache(Location) of
        true -> 
			Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
            NewStatus = GoodsStatus#goods_status{dict = Dict};
        false ->
            case is_cache(GoodsInfo#goods.location) of
                true -> 
					Dict = lib_goods_dict:append_dict({del, goods, NewGoodsInfo#goods.id},GoodsStatus#goods_status.dict),
                    NewStatus = GoodsStatus#goods_status{dict = Dict};
                false -> 
					NewStatus = GoodsStatus
            end
    end,
    [NewGoodsInfo, NewStatus].

%%更改物品数量
change_goods_num(GoodsInfo, Num, GoodsStatus) ->
	NewGoodsInfo = lib_goods_util:change_goods_num(GoodsInfo, Num),
	case is_cache(NewGoodsInfo#goods.location) of
		true ->
			Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
            NewStatus = GoodsStatus#goods_status{dict = Dict};
		false ->
            case dict:is_key(GoodsInfo#goods.id, GoodsStatus#goods_status.dict) of
                true ->
                    Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
                    NewStatus = GoodsStatus#goods_status{dict = Dict};
                false ->
			        NewStatus = GoodsStatus
            end
	end,
	[NewGoodsInfo, NewStatus].

%% 更改物品格子位置
change_goods_cell(GoodsInfo, Location, Cell, GoodsStatus) ->
    NewGoodsInfo = lib_goods_util:change_goods_cell(GoodsInfo, Location, Cell),
    case is_cache(Location) of
        true -> 
            Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
            NewStatus = GoodsStatus#goods_status{dict = Dict};
        false ->
            case is_cache(GoodsInfo#goods.location) of
                true -> 
                    Dict = lib_goods_dict:append_dict({del, goods, NewGoodsInfo#goods.id},GoodsStatus#goods_status.dict),
                    NewStatus = GoodsStatus#goods_status{dict = Dict};
                false -> 
                    NewStatus = GoodsStatus
            end
    end,
    [NewGoodsInfo, NewStatus].

%% 更改物品使用耐久度
change_goods_use(GoodsInfo, UseNum, GoodsStatus) ->
	NewGoodsInfo = lib_goods_util:change_goods_use(GoodsInfo, UseNum),
	case is_cache(NewGoodsInfo#goods.location) of
		true ->
			Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
            NewStatus = GoodsStatus#goods_status{dict = Dict};
		false ->
			NewStatus = GoodsStatus
	end,
	[NewGoodsInfo, NewStatus].

%% 更改物品格子位置和数量
change_goods_cell_and_num(GoodsInfo, Location, Cell, Num, GoodsStatus) ->
    NewGoodsInfo = lib_goods_util:change_goods_cell_and_num(GoodsInfo, Location, Cell, Num),
    case is_cache(Location) of
        true -> 
            Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
            NewStatus = GoodsStatus#goods_status{dict = Dict};
        false ->
            case is_cache(GoodsInfo#goods.location) of
                true -> 
                    Dict = lib_goods_dict:append_dict({del, goods, NewGoodsInfo#goods.id},GoodsStatus#goods_status.dict),
                    NewStatus = GoodsStatus#goods_status{dict = Dict};
                false -> 
                    NewStatus = GoodsStatus
            end
    end,
    [NewGoodsInfo,NewStatus].

change_goods_player(GoodsInfo, PlayerId, Location, Cell, GoodsStatus) ->
    NewGoodsInfo = lib_goods_util:change_goods_player(GoodsInfo, PlayerId, Location, Cell),
    case is_cache(Location) of
        true ->
            Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
            NewStatus = GoodsStatus#goods_status{dict = Dict};
        false ->
            case is_cache(GoodsInfo#goods.location) of
                true ->
                    Dict = lib_goods_dict:append_dict({del, goods, NewGoodsInfo#goods.id},GoodsStatus#goods_status.dict),
                    NewStatus = GoodsStatus#goods_status{dict = Dict};
                false ->
                    NewStatus = GoodsStatus
            end
    end,
    [NewGoodsInfo,NewStatus].      

change_fashion_type(GoodsInfo, GoodsTypeId, Bind, Trade, GoodsStatus) ->
    NewGoodsInfo = lib_goods_util:change_fashion_type(GoodsInfo, GoodsTypeId, Bind, Trade),
    case is_cache(NewGoodsInfo#goods.location) of
        true -> 
            Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
            NewStatus = GoodsStatus#goods_status{dict = Dict};
        false -> 
            NewStatus = GoodsStatus
    end,
    [NewGoodsInfo, NewStatus].

%% 绑定物品
bind_goods(GoodsInfo) ->
	Sql = io_lib:format(?SQL_GOODS_UPDATE_BIND, [GoodsInfo#goods.id]),
	db:execute(Sql),
	GoodsInfo#goods{bind = 2, trade = 1}.

%% 删除一类物品
%% @spec delete_type_goods(GoodsTypeId, GoodsStatus) -> {ok, NewStatus} | Error
delete_type_goods(GoodsTypeId, GoodsStatus) ->
    GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
    TotalNum = lib_goods_util:get_goods_totalnum(GoodsList),
    delete_more(GoodsStatus, GoodsList, TotalNum).


%% 删除一类物品的指定数量
%% @spec delete_type_list_goods({GoodsTypeId,GoodsNum}, GoodsStatus) -> {ok, NewStatus} | Error
delete_type_list_goods({GoodsTypeId,GoodsNum}, GoodsStatus) ->
    GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
    TotalNum = lib_goods_util:get_goods_totalnum(GoodsList),
    case TotalNum >= GoodsNum of
        true ->
            delete_more(GoodsStatus, GoodsList, GoodsNum);
        false ->  
            not_enough
    end.



%% 扩展帮派仓库
extend_guild(PlayerStatus, GoodsStatus, GoldNum, GoodsNum, GoodsTypeList) ->
    GoodsList = lib_goods_util:sort(GoodsTypeList, cell),
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, GoldNum, gold),
            %% 日志
            log:log_consume(goods_extend_guild, gold, PlayerStatus, NewPlayerStatus, ""),
            [NewStatus, _] = lists:foldl(fun delete_one/2, [GoodsStatus, GoodsNum], GoodsList),
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
            {ok, NewPlayerStatus, NewStatus2}
        end,
    lib_goods_util:transaction(F).

%% 装备磨损
attrit_equip([], UseNum, AttritionList, ZeroEquipList, GoodsStatus) ->
    [UseNum, AttritionList, ZeroEquipList, GoodsStatus];
attrit_equip([GoodsInfo|H], UseNum, AttritionList, ZeroEquipList, GoodsStatus) ->
    case GoodsInfo#goods.attrition > 0 andalso GoodsInfo#goods.use_num > 0 of
        %% 耐久度降为0
        true when GoodsInfo#goods.use_num =< UseNum ->
            NewGoodsInfo = GoodsInfo#goods{use_num = 0},
            Dict = lib_goods_dict:add_dict_goods(NewGoodsInfo, GoodsStatus#goods_status.dict),
            NewStatus = GoodsStatus#goods_status{dict = Dict},
            attrit_equip(H, UseNum, [NewGoodsInfo|AttritionList], [NewGoodsInfo|ZeroEquipList], NewStatus);
        true ->
            NewUseNum = GoodsInfo#goods.use_num - UseNum,
            NewGoodsInfo = GoodsInfo#goods{use_num = NewUseNum},
            Dict = lib_goods_dict:add_dict_goods(NewGoodsInfo, GoodsStatus#goods_status.dict),
            NewStatus = GoodsStatus#goods_status{dict = Dict},
            attrit_equip(H, UseNum, [NewGoodsInfo|AttritionList], ZeroEquipList, NewStatus);
        false ->
            attrit_equip(H, UseNum, AttritionList, ZeroEquipList, GoodsStatus)
    end.

