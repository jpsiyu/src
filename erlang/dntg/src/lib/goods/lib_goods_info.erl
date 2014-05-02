%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-8-3
%% Description: 物品信息
%% --------------------------------------------------------
-module(lib_goods_info).
-compile(export_all).
-include("goods.hrl").
-include("server.hrl").
-include("def_goods.hrl").

%% 计算物品战斗力
get_goods_power(GoodsInfo, PlayerCareer) ->
    if
        is_record(GoodsInfo, goods) =:= true ->
            Attribute = data_goods:get_goods_attribute(GoodsInfo),
            data_goods:count_goods_power(GoodsInfo, Attribute, PlayerCareer);
        true ->
            0
    end.

%% 获取背包同类物品数量
%% GoodsTypeId:物品类型ID
%% 在物品进程时需要传GoodsStatus, 游戏线传0,公共线不给用
get_goods_num(PlayerStatus, GoodsTypeId, GoodsStatus) ->
    Goods = PlayerStatus#player_status.goods,
    case Goods#status_goods.goods_pid =:= self() andalso GoodsStatus =/= 0 of
        true ->
           GoodsList = lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id, GoodsTypeId, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict);
       false ->
           case gen:call(Goods#status_goods.goods_pid, '$gen_call', {'get_dict'}) of
               {ok, Dict} ->
                    GoodsList = lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id, GoodsTypeId, ?GOODS_LOC_BAG, Dict);
                {'EXIT', _R} ->
                    GoodsList = []
            end
    end,
    get_goods_num(GoodsList, 0).

%% 物品数量
get_goods_num([], N) ->
    N;
get_goods_num([GoodsInfo|H], N) ->
    if
        is_record(GoodsInfo, goods) =:= true ->
            get_goods_num(H, N + GoodsInfo#goods.num);
        true ->
            get_goods_num(H, N)
    end.


