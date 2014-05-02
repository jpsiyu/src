
%%%---------------------------------------
%%% @Module  : data_shop
%%% @Author  : xhg
%%% @Email   : xuhuguang@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_shop).
-export([get_by_goods/3, get_subtype/1, get_by_type/2, get_shop_list/1, get_shop_list/2]).
-include("shop.hrl").

get_shop_list(ShopType) ->
    lists:merge([ get_shop_list(ShopType, ShopSubtype) || ShopSubtype <- get_subtype(ShopType), ShopSubtype =/= 9, ShopSubtype =/= 10, ShopSubtype =/= 11, ShopSubtype =/= 12, ShopSubtype =/= 13, ShopSubtype =/= 14, ShopSubtype =/= 20, ShopSubtype < 50 orelse ShopSubtype > 65 ]).

get_shop_list(ShopType, ShopSubtype) ->
    case get_by_type(ShopType, ShopSubtype) of
        [Id, GoodsList] ->
            handle_item(GoodsList, Id, ShopType, ShopSubtype, util:unixtime());
%            [ #ets_shop{ id=Id, shop_type=ShopType, shop_subtype=ShopSubtype, goods_id=GoodsTypeId, goods_num=GoodsNum, new_price=NewPrice }
%                                || {GoodsTypeId, NewPrice, GoodsNum} <- GoodsList];
        [] -> []
    end.

handle_item([], _Id, _ShopType, _ShopSubtype, _NowTime) -> [];
handle_item([H|T], Id, ShopType, ShopSubtype, NowTime) ->
    case H of
        {GoodsTypeId, NewPrice, GoodsNum} ->
            [ #ets_shop{ id=Id, shop_type=ShopType, shop_subtype=ShopSubtype, goods_id=GoodsTypeId, goods_num=GoodsNum, new_price=NewPrice } | handle_item(T, Id, ShopType, ShopSubtype, NowTime) ];
        {GoodsTypeId, NewPrice, GoodsNum, StartTime, EndTime} when NowTime >= StartTime andalso NowTime =< EndTime ->
            [ #ets_shop{ id=Id, shop_type=ShopType, shop_subtype=ShopSubtype, goods_id=GoodsTypeId, goods_num=GoodsNum, new_price=NewPrice } | handle_item(T, Id, ShopType, ShopSubtype, NowTime) ];
        {GoodsTypeId, NewPrice, GoodsNum, _StartTime, _EndTime, LimitDay} when LimitDay > 0 ->
            case util:check_open_day(LimitDay) of
                true ->
                    [ #ets_shop{ id=Id, shop_type=ShopType, shop_subtype=ShopSubtype, goods_id=GoodsTypeId, goods_num=GoodsNum, new_price=NewPrice } | handle_item(T, Id, ShopType, ShopSubtype, NowTime) ];
                false ->
                    handle_item(T, Id, ShopType, ShopSubtype, NowTime)
            end;
        _ -> 
            handle_item(T, Id, ShopType, ShopSubtype, NowTime)
     end.

get_by_goods(ShopType, ShopSubtype, GoodsTypeId) ->
    case get_by_type(ShopType, ShopSubtype) of
        [Id, GoodsList] ->
            NowTime = util:unixtime(),
            case lists:keyfind(GoodsTypeId, 1, GoodsList) of
                {GoodsTypeId, NewPrice, GoodsNum} ->
                    #ets_shop{ id=Id, shop_type=ShopType, shop_subtype=ShopSubtype, goods_id=GoodsTypeId, goods_num=GoodsNum, new_price=NewPrice };
                {GoodsTypeId, NewPrice, GoodsNum, StartTime, EndTime} when NowTime >= StartTime andalso NowTime =< EndTime ->
                    #ets_shop{ id=Id, shop_type=ShopType, shop_subtype=ShopSubtype, goods_id=GoodsTypeId, goods_num=GoodsNum, new_price=NewPrice };
                {GoodsTypeId, NewPrice, GoodsNum, _StartTime, _EndTime, LimitDay} when LimitDay > 0 ->
                    case util:check_open_day(LimitDay) of
                        true ->
                            #ets_shop{ id=Id, shop_type=ShopType, shop_subtype=ShopSubtype, goods_id=GoodsTypeId, goods_num=GoodsNum, new_price=NewPrice };
                        false ->
                            []
                    end;
                _ -> []
            end;
        [] -> []
    end.

get_subtype(1) ->
    [0,1,2,3,4,5,6,19,20];
get_subtype(10203) ->
    [0];
get_subtype(10204) ->
    [0];
get_subtype(10229) ->
    [0];
get_subtype(_Type) ->
    [].

get_by_type(1, 0) ->
    [1, [] ];
get_by_type(1, 1) ->
    [2, [{631001,98,0},{631101,388,0},{631201,1988,0}] ];
get_by_type(1, 2) ->
    [3, [{111041,6,0},{624201,5,0},{624801,4,0},{111481,4,0},{111491,4,0},{111501,4,0},{231201,10,0},{112301,8,0},{121001,16,0}] ];
get_by_type(1, 3) ->
    [4, [{211001,4,0},{621301,4,0},{222001,10,0},{222101,10,0},{221101,1,0},{221102,5,0},{221103,10,0},{611601,1,0},{611602,99,0},{611603,999,0},{411101,88,0},{501202,2,0},{612501,2,0},{671001,1,0},{411401,280,0},{612805,88,0}] ];
get_by_type(1, 4) ->
    [5, [{211001,10,0},{211002,28,0},{211003,54,0}] ];
get_by_type(1, 5) ->
    [6, [{621018,188,0},{621302,10,0},{212902,20,0},{212903,36,0},{621303,20,0},{311101,10,0}] ];
get_by_type(1, 6) ->
    [66, [] ];
get_by_type(1, 19) ->
    [84, [] ];
get_by_type(1, 20) ->
    [7, [{205101,3,0},{205201,10,0},{205301,20,0},{205401,40,0},{206101,2,0},{206201,5,0},{206301,10,0},{206401,20,0},{111042,15,0},{111043,45,0},{111044,105,0},{231212,20,0},{231213,40,0},{231214,80,0},{231215,160,0},{624202,10,0},{624203,20,0},{624204,40,0},{624205,80,0},{624206,160,0},{624207,320,0},{624208,640,0},{624802,8,0},{624803,16,0},{624804,32,0},{624805,64,0},{624806,128,0},{624807,256,0},{624808,512,0},{111482,15,0},{111483,45,0},{111492,15,0},{111493,45,0},{111502,15,0},{111503,45,0},{121002,48,0},{121003,144,0},{121004,288,0},{121005,576,0},{121006,1152,0},{121007,2304,0},{121008,4608,0}] ];
get_by_type(10203, 0) ->
    [109, [{611002,1000,0},{611005,1000,0},{611006,1000,0}] ];
get_by_type(10204, 0) ->
    [110, [{205101,5000,0},{205201,18000,0},{205301,40000,0},{205401,100000,0},{206101,2500,0},{206201,9000,0},{206301,20000,0},{206401,50000,0}] ];
get_by_type(10229, 0) ->
    [111, [{205101,5000,0},{205201,18000,0},{205301,40000,0},{205401,100000,0},{206101,2500,0},{206201,9000,0},{206301,20000,0},{206401,50000,0}] ];
get_by_type(_ShopType, _ShopSubtype) ->
    [].
