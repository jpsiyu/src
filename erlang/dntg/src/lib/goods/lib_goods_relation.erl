%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-10-10
%% Description: 物品相关
%% --------------------------------------------------------
-module(lib_goods_relation).
-compile(export_all).
-include("server.hrl").
-include("goods.hrl").
-include("sql_goods.hrl").
-include("def_goods.hrl").

merge_goods_default(GoodsStatus, PlayerStatus) ->
    GoodsList = lib_goods_util:get_goods_list(GoodsStatus#goods_status.player_id, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
    %% 按物品类型ID排序
    GoodsList1 = lib_goods_util:sort(GoodsList, bind_id),
    ok = lib_goods_dict:start_dict(),
    [Num, _, NewStatus] = lists:foldl(fun lib_goods:clean_bag/2, [1, {}, GoodsStatus], GoodsList1),
    if
        Num > PlayerStatus#player_status.cell_num ->
            Num1 = PlayerStatus#player_status.cell_num;
        true ->
            Num1 = Num
    end,
    NullCells = lists:seq(Num1, PlayerStatus#player_status.cell_num),
    NewGoodsStatus = NewStatus#goods_status{null_cells = NullCells},
    Dict = lib_goods_dict:handle_dict(NewGoodsStatus#goods_status.dict),
    NewGoodsStatus2 = NewGoodsStatus#goods_status{dict = Dict},
    List1 = lib_goods_util:get_list_by_type(20, NewGoodsStatus2#goods_status.dict),
    List2 = lib_goods_util:get_list_by_type(21, NewGoodsStatus2#goods_status.dict),
    List3 = lib_goods_util:get_list_by_type(22, NewGoodsStatus2#goods_status.dict),
    List4 = lib_goods_util:get_list_by_type(50, NewGoodsStatus2#goods_status.dict),
    List5 = lib_goods_util:get_list_by_type(11, NewGoodsStatus2#goods_status.dict),
    List6 = lib_goods_util:get_list_by_type(12, NewGoodsStatus2#goods_status.dict),
    List7 = lib_goods_util:get_list_by_type(60, NewGoodsStatus2#goods_status.dict),
    List8 = lib_goods_util:get_list_by_type(61, NewGoodsStatus2#goods_status.dict),
    %F = fun() ->
        ok = lib_goods_dict:start_dict(),
        NewStatus1 = goods_merge(List1++List2++List3++List4++List5++List6++List7++List8, NewGoodsStatus2),
        D = lib_goods_dict:handle_dict(NewStatus1#goods_status.dict), 
        NewStatus2 = NewStatus1#goods_status{dict = D},
        {ok, NewStatus2}.
    %end,
    %lib_goods_util:transaction(F).

goods_merge([], NewStatus) ->
    NewStatus;
goods_merge([GoodsInfo|T], GoodsStatus) ->
    [NewStatus, _List] = merge(GoodsInfo, T, GoodsStatus, []),
    goods_merge(T, NewStatus).

merge(GoodsInfo, [], NewStatus, L) ->
    [NewStatus, [GoodsInfo|L]];
merge(GoodsInfo, [GoodsInfo2|H], GoodsStatus, L) ->
    GoodsTypeInfo = data_goods_type:get(GoodsInfo#goods.goods_id),
    case GoodsInfo#goods.goods_id =:= GoodsInfo2#goods.goods_id andalso GoodsInfo#goods.num + GoodsInfo2#goods.num =< GoodsTypeInfo#ets_goods_type.max_overlap of
        false ->
            merge(GoodsInfo, H, GoodsStatus, [GoodsInfo2|L]);   %% 
        true ->     %% 合并
            if
                GoodsInfo#goods.bind > 0 ->
                    {ok, NewStatus1} = lib_goods:delete_goods_list(GoodsStatus, [{GoodsInfo2, GoodsInfo2#goods.num}]),
                    Num = GoodsInfo#goods.num + GoodsInfo2#goods.num,
                    [NewGoodsInfo, NewStatus2] = change_goods_num(GoodsInfo, Num, NewStatus1),
                    merge(NewGoodsInfo, H, NewStatus2, L);
                true ->
                    {ok, NewStatus1} = lib_goods:delete_goods_list(GoodsStatus, [{GoodsInfo, GoodsInfo#goods.num}]),
                    Num = GoodsInfo#goods.num + GoodsInfo2#goods.num,
                    [NewGoodsInfo, NewStatus2] = change_goods_num(GoodsInfo2, Num, NewStatus1),
                    merge(NewGoodsInfo, H, NewStatus2, L)
            end
    end.
                    
change_goods_num(GoodsInfo, Num, GoodsStatus) ->
    Sql = io_lib:format(<<"update goods_high set num = ~p where gid = ~p">>, [Num, GoodsInfo#goods.id]),
    db:execute(Sql),
    NewGoodsInfo = GoodsInfo#goods{num = Num},
    Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    [NewGoodsInfo, NewStatus].

check_goods_merge(GoodsId1, GoodsId2, PlayerStatus, GoodsStatus) ->
    GoodsInfo1 = lib_goods_util:get_goods(GoodsId1, GoodsStatus#goods_status.dict),
    GoodsInfo2 = lib_goods_util:get_goods(GoodsId2, GoodsStatus#goods_status.dict),
    if
        is_record(GoodsInfo1, goods) =:= false orelse is_record(GoodsInfo2, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo1#goods.player_id =/= GoodsStatus#goods_status.player_id orelse GoodsInfo2#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品不在背包
        GoodsInfo1#goods.location =/= ?GOODS_LOC_BAG orelse GoodsInfo2#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品数量不正确
        GoodsInfo1#goods.num < 1 orelse GoodsInfo2#goods.num < 1 ->
            {fail, 6};
        %% 正在交易中
        GoodsStatus#goods_status.sell_status =/= 0  ->
            {fail, 7};
        GoodsInfo1#goods.goods_id =/= GoodsInfo2#goods.goods_id ->
            {fail, 5};
        true ->
            GoodsTypeInfo = data_goods_type:get(GoodsInfo1#goods.goods_id),
            if
                GoodsInfo1#goods.num + GoodsInfo2#goods.num > GoodsTypeInfo#ets_goods_type.max_overlap ->
                    {fail, 8};
                true ->
                    {ok, GoodsInfo1, GoodsInfo2}
            end
    end.

goods_merge_move(GoodsInfo1, GoodsInfo2, GoodsStatus) ->
    F = fun() ->
        ok = lib_goods_dict:start_dict(),
        if
            GoodsInfo1#goods.bind > 0 ->
                {ok, NewStatus1} = lib_goods:delete_goods_list(GoodsStatus, [{GoodsInfo2, GoodsInfo2#goods.num}]),
                Num = GoodsInfo1#goods.num + GoodsInfo2#goods.num,
                [NewGoodsInfo, NewStatus2] = change_goods_num(GoodsInfo1, Num, NewStatus1);
            true ->
                {ok, NewStatus1} = lib_goods:delete_goods_list(GoodsStatus, [{GoodsInfo1, GoodsInfo1#goods.num}]),
                Num = GoodsInfo1#goods.num + GoodsInfo2#goods.num,
                [NewGoodsInfo, NewStatus2] = change_goods_num(GoodsInfo2, Num, NewStatus1)
        end,
        D = lib_goods_dict:handle_dict(NewStatus2#goods_status.dict), 
        NewStatus3 = NewStatus2#goods_status{dict = D},
        {ok, NewGoodsInfo, NewStatus3}
    end,
    lib_goods_util:transaction(F).














