%%%---------------------------------------
%%% @Module  : data_secret_shop
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  神秘商店
%%%---------------------------------------
-module(data_secret_shop).
-compile(export_all).
-include("shop.hrl").


get_goods(112214) -> 
	#base_secret_shop{goods_id=112214,price_type=1,price=6,bind=2,notice=0,ratio_start=1,ratio_end=60,min_lv=60,max_lv=100,lim_min=0,goods_num=0};
get_goods(112303) -> 
	#base_secret_shop{goods_id=112303,price_type=1,price=10,bind=2,notice=0,ratio_start=61,ratio_end=1060,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(121301) -> 
	#base_secret_shop{goods_id=121301,price_type=3,price=5000,bind=2,notice=0,ratio_start=1061,ratio_end=1160,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(121302) -> 
	#base_secret_shop{goods_id=121302,price_type=2,price=5,bind=2,notice=0,ratio_start=1161,ratio_end=1260,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(121401) -> 
	#base_secret_shop{goods_id=121401,price_type=3,price=5000,bind=2,notice=0,ratio_start=1261,ratio_end=1360,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(121402) -> 
	#base_secret_shop{goods_id=121402,price_type=2,price=5,bind=2,notice=0,ratio_start=1361,ratio_end=1460,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(121701) -> 
	#base_secret_shop{goods_id=121701,price_type=3,price=7500,bind=2,notice=0,ratio_start=1461,ratio_end=1560,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(121702) -> 
	#base_secret_shop{goods_id=121702,price_type=2,price=8,bind=2,notice=0,ratio_start=1561,ratio_end=1660,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(122505) -> 
	#base_secret_shop{goods_id=122505,price_type=1,price=288,bind=2,notice=1,ratio_start=1661,ratio_end=1675,min_lv=50,max_lv=100,lim_min=25,goods_num=0};
get_goods(122506) -> 
	#base_secret_shop{goods_id=122506,price_type=1,price=688,bind=2,notice=1,ratio_start=1676,ratio_end=1680,min_lv=60,max_lv=100,lim_min=50,goods_num=0};
get_goods(205101) -> 
	#base_secret_shop{goods_id=205101,price_type=3,price=40000,bind=2,notice=0,ratio_start=1681,ratio_end=1730,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(206101) -> 
	#base_secret_shop{goods_id=206101,price_type=3,price=30000,bind=2,notice=0,ratio_start=1731,ratio_end=1780,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(211001) -> 
	#base_secret_shop{goods_id=211001,price_type=3,price=25000,bind=2,notice=0,ratio_start=1781,ratio_end=1830,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(212101) -> 
	#base_secret_shop{goods_id=212101,price_type=3,price=7500,bind=2,notice=0,ratio_start=1831,ratio_end=1905,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(212102) -> 
	#base_secret_shop{goods_id=212102,price_type=2,price=6,bind=2,notice=0,ratio_start=1906,ratio_end=1955,min_lv=50,max_lv=100,lim_min=0,goods_num=0};
get_goods(212103) -> 
	#base_secret_shop{goods_id=212103,price_type=1,price=9,bind=2,notice=0,ratio_start=1956,ratio_end=1970,min_lv=60,max_lv=100,lim_min=10,goods_num=0};
get_goods(212201) -> 
	#base_secret_shop{goods_id=212201,price_type=3,price=5000,bind=2,notice=0,ratio_start=1971,ratio_end=2045,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(212202) -> 
	#base_secret_shop{goods_id=212202,price_type=2,price=4,bind=2,notice=0,ratio_start=2046,ratio_end=2095,min_lv=50,max_lv=100,lim_min=0,goods_num=0};
get_goods(212203) -> 
	#base_secret_shop{goods_id=212203,price_type=1,price=6,bind=2,notice=0,ratio_start=2096,ratio_end=2110,min_lv=60,max_lv=100,lim_min=10,goods_num=0};
get_goods(212301) -> 
	#base_secret_shop{goods_id=212301,price_type=3,price=7500,bind=2,notice=0,ratio_start=2111,ratio_end=2185,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(212302) -> 
	#base_secret_shop{goods_id=212302,price_type=2,price=6,bind=2,notice=0,ratio_start=2186,ratio_end=2235,min_lv=50,max_lv=100,lim_min=0,goods_num=0};
get_goods(212303) -> 
	#base_secret_shop{goods_id=212303,price_type=1,price=9,bind=2,notice=0,ratio_start=2236,ratio_end=2250,min_lv=60,max_lv=100,lim_min=10,goods_num=0};
get_goods(212501) -> 
	#base_secret_shop{goods_id=212501,price_type=3,price=2500,bind=2,notice=0,ratio_start=2251,ratio_end=2325,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(212502) -> 
	#base_secret_shop{goods_id=212502,price_type=2,price=2,bind=2,notice=0,ratio_start=2326,ratio_end=2375,min_lv=50,max_lv=100,lim_min=0,goods_num=0};
get_goods(212503) -> 
	#base_secret_shop{goods_id=212503,price_type=1,price=3,bind=2,notice=0,ratio_start=2376,ratio_end=2390,min_lv=60,max_lv=100,lim_min=10,goods_num=0};
get_goods(212601) -> 
	#base_secret_shop{goods_id=212601,price_type=3,price=5000,bind=2,notice=0,ratio_start=2391,ratio_end=2465,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(212602) -> 
	#base_secret_shop{goods_id=212602,price_type=2,price=4,bind=2,notice=0,ratio_start=2466,ratio_end=2515,min_lv=50,max_lv=100,lim_min=0,goods_num=0};
get_goods(212603) -> 
	#base_secret_shop{goods_id=212603,price_type=1,price=6,bind=2,notice=0,ratio_start=2516,ratio_end=2530,min_lv=60,max_lv=100,lim_min=10,goods_num=0};
get_goods(212701) -> 
	#base_secret_shop{goods_id=212701,price_type=3,price=5000,bind=2,notice=0,ratio_start=2531,ratio_end=2605,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(212702) -> 
	#base_secret_shop{goods_id=212702,price_type=2,price=4,bind=2,notice=0,ratio_start=2606,ratio_end=2655,min_lv=50,max_lv=100,lim_min=0,goods_num=0};
get_goods(212703) -> 
	#base_secret_shop{goods_id=212703,price_type=1,price=6,bind=2,notice=0,ratio_start=2656,ratio_end=2670,min_lv=60,max_lv=100,lim_min=10,goods_num=0};
get_goods(212801) -> 
	#base_secret_shop{goods_id=212801,price_type=3,price=2500,bind=2,notice=0,ratio_start=2671,ratio_end=2745,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(212802) -> 
	#base_secret_shop{goods_id=212802,price_type=2,price=2,bind=2,notice=0,ratio_start=2746,ratio_end=2795,min_lv=50,max_lv=100,lim_min=0,goods_num=0};
get_goods(212803) -> 
	#base_secret_shop{goods_id=212803,price_type=1,price=3,bind=2,notice=0,ratio_start=2796,ratio_end=2810,min_lv=60,max_lv=100,lim_min=10,goods_num=0};
get_goods(212901) -> 
	#base_secret_shop{goods_id=212901,price_type=3,price=7500,bind=2,notice=0,ratio_start=2811,ratio_end=2885,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(222001) -> 
	#base_secret_shop{goods_id=222001,price_type=3,price=25000,bind=2,notice=0,ratio_start=2886,ratio_end=2935,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(222101) -> 
	#base_secret_shop{goods_id=222101,price_type=3,price=25000,bind=2,notice=0,ratio_start=2936,ratio_end=2985,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(231201) -> 
	#base_secret_shop{goods_id=231201,price_type=2,price=5,bind=2,notice=0,ratio_start=2986,ratio_end=3030,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(611201) -> 
	#base_secret_shop{goods_id=611201,price_type=3,price=2500,bind=2,notice=0,ratio_start=3031,ratio_end=3130,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(621016) -> 
	#base_secret_shop{goods_id=621016,price_type=1,price=988,bind=2,notice=1,ratio_start=3131,ratio_end=3140,min_lv=0,max_lv=100,lim_min=100,goods_num=0};
get_goods(621301) -> 
	#base_secret_shop{goods_id=621301,price_type=3,price=10000,bind=2,notice=0,ratio_start=3141,ratio_end=3390,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(621302) -> 
	#base_secret_shop{goods_id=621302,price_type=3,price=25000,bind=2,notice=0,ratio_start=3391,ratio_end=3440,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(623201) -> 
	#base_secret_shop{goods_id=623201,price_type=1,price=10,bind=2,notice=0,ratio_start=3441,ratio_end=3590,min_lv=0,max_lv=100,lim_min=1,goods_num=0};
get_goods(623202) -> 
	#base_secret_shop{goods_id=623202,price_type=1,price=20,bind=2,notice=0,ratio_start=3591,ratio_end=3690,min_lv=0,max_lv=100,lim_min=8,goods_num=0};
get_goods(623203) -> 
	#base_secret_shop{goods_id=623203,price_type=1,price=88,bind=2,notice=1,ratio_start=3691,ratio_end=3730,min_lv=0,max_lv=100,lim_min=20,goods_num=0};
get_goods(624201) -> 
	#base_secret_shop{goods_id=624201,price_type=1,price=50,bind=2,notice=1,ratio_start=3731,ratio_end=3760,min_lv=0,max_lv=100,lim_min=50,goods_num=0};
get_goods(624801) -> 
	#base_secret_shop{goods_id=624801,price_type=1,price=25,bind=2,notice=0,ratio_start=3761,ratio_end=3860,min_lv=0,max_lv=100,lim_min=0,goods_num=0};
get_goods(625001) -> 
	#base_secret_shop{goods_id=625001,price_type=1,price=50,bind=2,notice=1,ratio_start=3861,ratio_end=3940,min_lv=0,max_lv=100,lim_min=50,goods_num=0};
get_goods(_) ->
	[].

get_goods() ->
	AllIds = [112214,112303,121301,121302,121401,121402,121701,121702,122505,122506,205101,206101,211001,212101,212102,212103,212201,212202,212203,212301,212302,212303,212501,212502,212503,212601,212602,212603,212701,212702,212703,212801,212802,212803,212901,222001,222101,231201,611201,621016,621301,621302,623201,623202,623203,624201,624801,625001],
	[get_goods(Id) || Id <- AllIds].

get_max_ratio() ->
	3940.

