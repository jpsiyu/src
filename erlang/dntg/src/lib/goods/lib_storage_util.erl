%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-29
%% Description: 仓库物品操作
%% --------------------------------------------------------
-module(lib_storage_util).
-compile(export_all).
-include("common.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("server.hrl").
-include("errcode_goods.hrl").


%%检查物品存入仓库
check_movein_storage(PlayerStatus, NpcId, GoodsId, GoodsNum, GoodsStatus) ->
    Sell = PlayerStatus#player_status.sell,
	case lib_goods_check:check_npc(PlayerStatus, NpcId, move) of
		false ->
			{fail, ?ERRCODE15_NPC_FAR};
		true ->
			GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
			if  %% 物品不存在
                is_record(GoodsInfo, goods) =:= false ->
                    {fail, ?ERRCODE15_NO_GOODS};
                %% 物品不属于你所有
                GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
                    {fail, ?ERRCODE15_PALYER_ERR};
                %% 物品不在背包
                GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
                    {fail, ?ERRCODE15_LOCATION_ERR};
                %% 物品数量不正确
                GoodsNum < 1 orelse GoodsInfo#goods.num < GoodsNum ->
                    {fail, ?ERRCODE15_NUM_ERR};
                %% 正在交易中
                Sell#status_sell.sell_status =/= 0  ->
                    {fail, ?ERRCODE15_IN_SELL};
				true ->
					case data_goods_type:get(GoodsInfo#goods.goods_id) of
                        %% 物品类型不存在
                        [] ->
                            {fail, ?ERRCODE15_NO_GOODS_TYPE};
						GoodsTypeInfo ->
							TotalNum = get_storage_count(GoodsInfo#goods.player_id, 0),
							TypeNum = get_storage_type_count(GoodsInfo#goods.player_id, 0, 
															GoodsInfo#goods.goods_id, GoodsInfo#goods.bind),
							%% 还要多少格子数
							CellNum = get_null_storage_num(TypeNum, GoodsNum, GoodsTypeInfo#ets_goods_type.max_overlap),
							if	%%仓库不够
								PlayerStatus#player_status.storage_num < (TotalNum + CellNum) ->
									{fail, ?ERRCODE15_STORAGE_NO_CELL};
								true ->
									{ok, GoodsInfo, GoodsTypeInfo}
							end
					end
			end
	end.

%%检查从仓库取出物品
check_moveout_storage(PlayerStatus, GoodsStatus, NpcId, GoodsId, GoodsNum) ->
    Sell = PlayerStatus#player_status.sell,
	case lib_goods_check:check_npc(PlayerStatus, NpcId, move) of
		false ->
			{fail, ?ERRCODE15_NPC_FAR};
		true ->
			GoodsInfo = lib_goods_util:get_goods_by_id(GoodsId),
			if  %% 物品不存在
                is_record(GoodsInfo, goods) =:= false ->
                    {fail, ?ERRCODE15_NO_GOODS};
                %% 物品不属于你所有
                GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
                    {fail, ?ERRCODE15_PALYER_ERR};
                %% 物品不在仓库
                GoodsInfo#goods.location =/= ?GOODS_LOC_STORAGE ->
                    {fail, ?ERRCODE15_LOCATION_ERR};
                %% 物品数量不正确
                GoodsNum < 1 orelse GoodsInfo#goods.num < GoodsNum ->
                    {fail, ?ERRCODE15_NUM_ERR};
                %% 正在交易中
                Sell#status_sell.sell_status =/= 0  ->
                    {fail, ?ERRCODE15_IN_SELL};
				true ->
					case data_goods_type:get(GoodsInfo#goods.goods_id) of
                        %% 物品类型不存在
                        [] ->
                            {fail, ?ERRCODE15_NO_GOODS_TYPE};
                        GoodsTypeInfo ->
                            TypeList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsInfo#goods.goods_id, 
                                                                          GoodsInfo#goods.bind, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
                            GoodsTypeList = lib_goods_util:sort(TypeList, cell),
							%% 还要多少格子数
                            CellNum = get_null_cell_num(GoodsTypeList, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsNum),
                            if  %% 背包格子不足
                                length(GoodsStatus#goods_status.null_cells) < CellNum orelse GoodsStatus#goods_status.null_cells =:= [] ->
                                    {fail, ?ERRCODE15_NO_CELL};
                                true ->
                                    {ok, GoodsInfo, GoodsTypeInfo, GoodsTypeList}
                            end
                    end
            end
    end.

%% 物品存入仓库
movein_storage(GoodsStatus, GoodsInfo, GoodsNum, Location, GoodsTypeInfo) ->
	F = fun() ->
			ok = lib_goods_dict:start_dict(),
			case GoodsTypeInfo#ets_goods_type.max_overlap > 1 of
				true -> %可叠加
					GoodsTypeList = get_storage_type_list(GoodsInfo, GoodsTypeInfo#ets_goods_type.max_overlap),
					[GoodsNum2,_] = lists:foldl(fun update_overlap_storage/2, [GoodsNum, GoodsTypeInfo#ets_goods_type.max_overlap], GoodsTypeList),
					case GoodsNum2 > 0 of
						%%超出最大叠加数 GoodsNum2
						true when GoodsNum >= GoodsInfo#goods.num ->
							 NewGoodsStatus = change_storage_into(GoodsInfo, Location, 0, GoodsNum2, GoodsStatus);
                       	true ->
							%修改物品属性,数量少了GoodsNum
                           	[_, GoodsStatus1] = lib_goods:change_goods_num(GoodsInfo, (GoodsInfo#goods.num - GoodsNum), GoodsStatus),
                           	NewGoodsInfo1 = GoodsInfo#goods{location=Location, cell=0, num=GoodsNum2},
                           	[_, NewGoodsStatus] = lib_goods:add_goods(NewGoodsInfo1, GoodsStatus1);
                       	false when GoodsNum >= GoodsInfo#goods.num ->
							%%没有超出,删除原来物品
                       	 	NewGoodsStatus = lib_goods:delete_goods2(GoodsInfo, GoodsStatus);
                       	false ->
                            [_, NewGoodsStatus] = lib_goods:change_goods_num(GoodsInfo, (GoodsInfo#goods.num - GoodsNum), GoodsStatus)
                   	end,
					case GoodsNum >= GoodsInfo#goods.num of
						%%全部移完,计算新的空格子数
                        true ->
                            NullCells = lists:sort([GoodsInfo#goods.cell|NewGoodsStatus#goods_status.null_cells]),
                            NewStatus = NewGoodsStatus#goods_status{null_cells=NullCells};
                        false ->
                            NewStatus = NewGoodsStatus
                    end;
				%% 不可叠加
                false ->
                    NewStatus1 = change_storage_into(GoodsInfo, Location, 0, GoodsInfo#goods.num, GoodsStatus),
                    NullCells = lists:sort([GoodsInfo#goods.cell|GoodsStatus#goods_status.null_cells]),
                    NewStatus = NewStatus1#goods_status{null_cells=NullCells}
            end,
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
            {ok, NewStatus2}
        end,
    lib_goods_util:transaction(F).

%%从仓库取出物品
moveout_storage(GoodsStatus, GoodsInfo, GoodsNum, Location, GoodsTypeInfo, GoodsTypeList) ->
	F = fun() ->
			ok = lib_goods_dict:start_dict(),
			%%帮派仓库取出来
			if GoodsInfo#goods.guild_id > 0  -> 
				   [PlayerId, GuildId, Num] = get_storage_goods_info(GoodsInfo#goods.id),
				   if  PlayerId =/= GoodsInfo#goods.player_id orelse GuildId =/= GoodsInfo#goods.guild_id orelse Num < GoodsInfo#goods.num ->
                            util:errlog("get_storage_goods_info, fail PlayerId=~p, GuildId=~p, Num=~p", [PlayerId, GuildId, Num]);
                   		true -> 
							skip
                    end,
					%%帮派取出来的物品已绑定,不可交易
				   NewGoodsInfo = GoodsInfo#goods{player_id=GoodsStatus#goods_status.player_id, guild_id=0, bind=2, trade=1};
			   true ->
				   NewGoodsInfo = GoodsInfo
			end,
			[NewCell|NullCells] = GoodsStatus#goods_status.null_cells,
            case GoodsTypeInfo#ets_goods_type.max_overlap > 1 of
                %% 可叠加
                true ->
                    [GoodsNum2,_, GoodsStatus1] = lists:foldl(fun lib_goods:update_overlap_goods/2, [GoodsNum, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsStatus], GoodsTypeList),
                    case GoodsNum2 > 0 of
                        true when GoodsNum >= NewGoodsInfo#goods.num ->
                            NewGoodsStatus = change_storage_out(NewGoodsInfo, Location, NewCell, GoodsNum2, GoodsStatus1),
                            NullCells2 = NullCells;
                        true ->
                            [_, NewGoodsStatus1] = lib_goods:change_goods_num(NewGoodsInfo, (NewGoodsInfo#goods.num - GoodsNum), GoodsStatus1),
                            NewGoodsInfo1 = NewGoodsInfo#goods{num=GoodsNum2, cell=NewCell, location=Location},
                            [_, NewGoodsStatus] = lib_goods:add_goods(NewGoodsInfo1, NewGoodsStatus1),
                            NullCells2 = NullCells;
                         false when GoodsNum >= NewGoodsInfo#goods.num ->
                            NewGoodsStatus = lib_goods:delete_goods2(NewGoodsInfo, GoodsStatus1),
                            NullCells2 = GoodsStatus1#goods_status.null_cells;
                        false ->
                            [_, NewGoodsStatus] = lib_goods:change_goods_num(NewGoodsInfo, (NewGoodsInfo#goods.num - GoodsNum), GoodsStatus1),
                            NullCells2 = GoodsStatus1#goods_status.null_cells
                    end;
                %% 不可叠加
                false ->
                    NewGoodsStatus = change_storage_out(NewGoodsInfo, Location, NewCell, NewGoodsInfo#goods.num, GoodsStatus),
                    NullCells2 = NullCells
            end,
            NewStatus = NewGoodsStatus#goods_status{null_cells = NullCells2},
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus1 = NewStatus#goods_status{dict = Dict},
            {ok, NewStatus1}
        end,
    lib_goods_util:transaction(F).

%% --------------------------- private ------------------------------------------------
get_storage_goods_info(GoodsId) ->
    Sql = io_lib:format(?SQL_STORAGE_LIST_BY_GID, [GoodsId]),
    case db:get_row(Sql) of
        [] -> [0, 0, 0];
        [PlayerId, GuildId, Num] -> [PlayerId, GuildId, Num]
    end.

%% 移进仓库
change_storage_into(GoodsInfo, Location, Cell, Num, GoodsStatus) ->
	NewGoodsInfo = change_storage(GoodsInfo, Location, Cell, Num),
	Dict = lib_goods_dict:append_dict({del, goods, NewGoodsInfo#goods.id}, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    NewStatus.

change_storage_out(GoodsInfo, Location, Cell, Num, GoodsStatus) ->
	NewGoodsInfo = change_storage(GoodsInfo, Location, Cell, Num),
	Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    NewStatus.

%% 移出、移进仓库
change_storage(GoodsInfo, Location, Cell, Num) ->
	Sql1 = io_lib:format(?SQL_GOODS_UPDATE_PLAYER1, [GoodsInfo#goods.player_id, GoodsInfo#goods.id]),
    db:execute(Sql1),
    Sql2 = io_lib:format(?SQL_GOODS_UPDATE_GUILD2, [GoodsInfo#goods.player_id, GoodsInfo#goods.bind, GoodsInfo#goods.trade, GoodsInfo#goods.id]),
    db:execute(Sql2),
    Sql3 = io_lib:format(?SQL_GOODS_UPDATE_GUILD3, [GoodsInfo#goods.player_id, GoodsInfo#goods.guild_id, Location, Cell, Num, GoodsInfo#goods.id]),
    db:execute(Sql3),
    GoodsInfo#goods{location=Location, cell=Cell, num=Num}.
	

%% 更新原有的可叠加物品	
update_overlap_storage([GoodsId, _Cell, GoodsNum], [Num, MaxOverlap]) ->
	case Num > 0 of
		true when GoodsNum < MaxOverlap ->
			case GoodsNum + Num > MaxOverlap of
				%总数超出可叠加数
				true ->
					OldNum = MaxOverlap,
					NewNum = Num + GoodsNum - MaxOverlap;
				false ->
					OldNum = Num + GoodsNum,
					NewNum = 0
			end,
			change_storage_num(GoodsId, OldNum);
		true ->
			NewNum = Num;
		false ->
			NewNum = 0
	end,
	[NewNum, MaxOverlap].

%%更改物品数量
change_storage_num(GoodsId, Num) ->
	Sql = io_lib:format(?SQL_GOODS_UPDATE_NUM, [Num, GoodsId]),
	db:execute(Sql).
				
get_val(Sql) ->
	Num = db:get_one(Sql),
	case is_integer(Num) of
		true ->
			Num;
		false ->
			0
	end.
	
%% 仓库数
get_storage_count(PlayerId, GuildId) ->
	case GuildId > 0 of
		true ->
			%帮派
			Sql = io_lib:format(?SQL_STORAGE_COUNT1, [GuildId]);
		false ->
			Sql = io_lib:format(?SQL_STORAGE_COUNT2, [PlayerId, ?GOODS_LOC_STORAGE])
	end,
	get_val(Sql).

%% 物品类型数量
get_storage_type_count(PlayerId, GuildId, GoodsTypeId, Bind) ->
	case GuildId > 0 of
		true ->
			%帮派
			Sql = io_lib:format(?SQL_STORAGE_TYPE_COUNT1, [GuildId, GoodsTypeId]);
		false ->
			Sql = io_lib:format(?SQL_STORAGE_TYPE_COUNT2, [PlayerId, ?GOODS_LOC_STORAGE, GoodsTypeId, Bind])
	end,
	get_val(Sql).

%% 检查物品还需要多少格子数
get_null_cell_num(GoodsList, MaxNum, GoodsNum) ->
    case MaxNum > 1 of
        true ->
            TotalNum = lists:foldl(fun(X, Sum) -> X#goods.num + Sum end, 0, GoodsList),
            CellNum = util:ceil( (TotalNum+GoodsNum)/ MaxNum ),
            (CellNum - length(GoodsList));
        false ->
            GoodsNum
    end.

get_null_storage_num(TypeNum, GoodsNum, MaxNum) ->
	case MaxNum > 1 of
		true ->
			OldCellNum = util:ceil(TypeNum/MaxNum), %向上取整 
			NewCellNum = util:ceil((TypeNum + GoodsNum)/MaxNum),
			(NewCellNum - OldCellNum);
		false ->
			GoodsNum
	end.

%% 取仓库物品类型表
get_storage_type_list(GoodsInfo, MaxNum) ->
	case GoodsInfo#goods.guild_id > 0 of
		true ->	%帮派
			Sql = io_lib:format(?SQL_STORAGE_LIST_BY_GUILD, [GoodsInfo#goods.guild_id, GoodsInfo#goods.goods_id, MaxNum]);
		false ->
			Sql = io_lib:format(?SQL_STORAGE_LIST_BY_TYPE, [GoodsInfo#goods.player_id, ?GOODS_LOC_STORAGE, GoodsInfo#goods.goods_id, GoodsInfo#goods.bind, MaxNum])
	end,
	GoodsList = lib_goods_util:get_list(Sql),
	sort_storage(GoodsList).

sort_storage(GoodsList) ->
    F = fun([_, C1, _], [_, C2, _]) -> C1 < C2 end,
    lists:sort(F, GoodsList).

%% 仓库扩展
extend_storage(PlayerStatus, CellNum) ->
    NewCellNum = PlayerStatus#player_status.storage_num + CellNum,
    Sql = io_lib:format(?SQL_PLAYER_UPDATE_STORAGE_NUM, [NewCellNum, PlayerStatus#player_status.id]),
    db:execute(Sql),
    PlayerStatus#player_status{storage_num = NewCellNum}.




