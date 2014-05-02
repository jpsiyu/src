%%%---------------------------------------
%%% @Module  : data_limit_shop
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  限制抢购数据自动生成
%%%---------------------------------------
-module(data_limit_shop).
-export([get_by_shop_id/1,get_all_data/0]).
-include("shop.hrl").

get_by_shop_id(ShopId) ->
	L = get_all_data(),
	lists:filter(fun(X) -> get_target_record(X, ShopId) end, L).

get_target_record(Record, ShopId) -> 
	if 
		is_record(Record, ets_limit_shop) andalso Record#ets_limit_shop.shop_id =:= ShopId ->
			true;
		true ->
			false
	end.

get_all_data() ->
    [
		#ets_limit_shop{id=11,shop_id=1,mark_name= <<"开服抢购1">>,goods_id=631201,goods_num=100,goods_name=[],price_type=1,old_price=1988,new_price=988,price_list=[],list_id=1,refresh=0,limit_id=1500,limit_num=1,unlimited=1,time_begin=1,time_end=3,merge_begin=0,merge_end=0,activity_begin=1398304077,activity_end=1399513678},
		#ets_limit_shop{id=13,shop_id=1,mark_name= <<"开服抢购1">>,goods_id=121007,goods_num=100,goods_name=[],price_type=1,old_price=1280,new_price=588,price_list=[],list_id=3,refresh=0,limit_id=1500,limit_num=1,unlimited=1,time_begin=1,time_end=3,merge_begin=0,merge_end=0,activity_begin=0,activity_end=0},
		#ets_limit_shop{id=21,shop_id=2,mark_name= <<"开服抢购2">>,goods_id=621000,goods_num=100,goods_name=[],price_type=1,old_price=888,new_price=588,price_list=[],list_id=1,refresh=0,limit_id=1501,limit_num=1,unlimited=1,time_begin=1,time_end=3,merge_begin=0,merge_end=0,activity_begin=1398304050,activity_end=1399513652},
		#ets_limit_shop{id=33,shop_id=3,mark_name= <<"开服抢购3">>,goods_id=611603,goods_num=100,goods_name=[],price_type=1,old_price=999,new_price=688,price_list=[],list_id=2,refresh=0,limit_id=1502,limit_num=1,unlimited=1,time_begin=1,time_end=3,merge_begin=0,merge_end=0,activity_begin=1398304152,activity_end=1399513753},
		#ets_limit_shop{id=102,shop_id=1,mark_name= <<"限购1区">>,goods_id=205101,goods_num=100,goods_name=[],price_type=1,old_price=16,new_price=4,price_list=[],list_id=0,refresh=1,limit_id=1500,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=0,activity_end=0},
		#ets_limit_shop{id=103,shop_id=1,mark_name= <<"限购1区">>,goods_id=206101,goods_num=100,goods_name=[],price_type=1,old_price=12,new_price=6,price_list=[],list_id=0,refresh=1,limit_id=1500,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=0,activity_end=0},
		#ets_limit_shop{id=104,shop_id=1,mark_name= <<"限购1区">>,goods_id=205101,goods_num=200,goods_name=[],price_type=1,old_price=16,new_price=2,price_list=[],list_id=0,refresh=1,limit_id=1500,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=0,activity_end=0},
		#ets_limit_shop{id=105,shop_id=1,mark_name= <<"限购1区">>,goods_id=206101,goods_num=200,goods_name=[],price_type=1,old_price=12,new_price=3,price_list=[],list_id=0,refresh=1,limit_id=1500,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=1395998574,activity_end=1395998575},
		#ets_limit_shop{id=108,shop_id=1,mark_name= <<"限购1区">>,goods_id=222001,goods_num=100,goods_name=[],price_type=1,old_price=10,new_price=5,price_list=[],list_id=0,refresh=1,limit_id=1500,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=1398497196,activity_end=1399447598},
		#ets_limit_shop{id=109,shop_id=1,mark_name= <<"限购1区">>,goods_id=222101,goods_num=100,goods_name=[],price_type=1,old_price=10,new_price=5,price_list=[],list_id=0,refresh=1,limit_id=1500,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=0,activity_end=0},
		#ets_limit_shop{id=110,shop_id=1,mark_name= <<"限购1区">>,goods_id=222001,goods_num=100,goods_name=[],price_type=1,old_price=10,new_price=3,price_list=[],list_id=0,refresh=1,limit_id=1500,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=0,activity_end=0},
		#ets_limit_shop{id=111,shop_id=1,mark_name= <<"限购1区">>,goods_id=222101,goods_num=100,goods_name=[],price_type=1,old_price=10,new_price=3,price_list=[],list_id=0,refresh=1,limit_id=1500,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=0,activity_end=0},
		#ets_limit_shop{id=201,shop_id=2,mark_name= <<"限购2区">>,goods_id=621302,goods_num=200,goods_name=[],price_type=1,old_price=10,new_price=5,price_list=[],list_id=0,refresh=1,limit_id=1501,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=0,activity_end=0},
		#ets_limit_shop{id=202,shop_id=2,mark_name= <<"限购2区">>,goods_id=621302,goods_num=100,goods_name=[],price_type=1,old_price=10,new_price=3,price_list=[],list_id=0,refresh=1,limit_id=1501,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=1398497232,activity_end=1400059359},
		#ets_limit_shop{id=203,shop_id=2,mark_name= <<"限购2区">>,goods_id=212902,goods_num=100,goods_name=[],price_type=1,old_price=10,new_price=5,price_list=[],list_id=0,refresh=1,limit_id=1501,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=0,activity_end=0},
		#ets_limit_shop{id=204,shop_id=2,mark_name= <<"限购2区">>,goods_id=212902,goods_num=200,goods_name=[],price_type=1,old_price=10,new_price=3,price_list=[],list_id=0,refresh=1,limit_id=1501,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=0,activity_end=0},
		#ets_limit_shop{id=209,shop_id=2,mark_name= <<"限购2区">>,goods_id=624801,goods_num=300,goods_name=[],price_type=1,old_price=25,new_price=5,price_list=[],list_id=0,refresh=1,limit_id=1501,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=0,activity_end=0},
		#ets_limit_shop{id=301,shop_id=3,mark_name= <<"限购3区">>,goods_id=111041,goods_num=100,goods_name=[],price_type=1,old_price=5,new_price=1,price_list=[],list_id=0,refresh=1,limit_id=1502,limit_num=1,unlimited=0,time_begin=0,time_end=0,merge_begin=0,merge_end=0,activity_begin=1398497271,activity_end=1400138872}
	].
