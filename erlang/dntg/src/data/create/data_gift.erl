%%%---------------------------------------
%%% @Module  : data_gift
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  礼包
%%%---------------------------------------
-module(data_gift).
-compile(export_all).
-include("gift.hrl").


get(1001) ->
	#ets_gift{ 
		id=1001, 
		name = <<"1级成长礼包">>,
		goods_id=531001, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,50,50},{coin,1000,1000},{goods,201101,10},{goods,202101,10},{goods,531003,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(1003) ->
	#ets_gift{ 
		id=1003, 
		name = <<"10级成长礼包">>,
		goods_id=531001, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,10,10},{goods,205101,1},{goods,206101,1},{goods,222001,1},{goods,211001,1},{goods,501202,1},{goods,612501,1},{coin,10000,10000},{goods,111041,1},{goods,531002,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(1005) ->
	#ets_gift{ 
		id=1005, 
		name = <<"20级成长礼包">>,
		goods_id=531002, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,15,15},{goods,205101,2},{goods,206101,2},{goods,222001,1},{goods,211001,2},{goods,501202,2},{goods,612501,2},{coin,15000,15000},{goods,111041,2},{goods,531003,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(1007) ->
	#ets_gift{ 
		id=1007, 
		name = <<"30级成长礼包">>,
		goods_id=531003, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,20,20},{goods,205101,3},{goods,206101,3},{goods,222001,1},{goods,211001,3},{goods,501202,3},{goods,612501,3},{coin,20000,20000},{goods,111041,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(1009) ->
	#ets_gift{ 
		id=1009, 
		name = <<"40级成长礼包">>,
		goods_id=531009, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,50,50},{coin,30000,30000},{goods,601501,3},{goods,624801,5},{goods,201501,100},{goods,202501,100},{goods,501202,10},{goods,501202,4},{goods,612501,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(1011) ->
	#ets_gift{ 
		id=1011, 
		name = <<"50级成长礼包">>,
		goods_id=531011, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,60,60},{coin,40000,40000},{goods,205201,2},{goods,206201,2},{goods,624201,1},{goods,202601,100},{goods,201601,100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(1013) ->
	#ets_gift{ 
		id=1013, 
		name = <<"60级成长礼包">>,
		goods_id=531013, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,100,100},{coin,50000,50000},{goods,205301,1},{goods,206301,1},{goods,624201,2},{goods,201701,100},{goods,202701,100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(2004) ->
	#ets_gift{ 
		id=2004, 
		name = <<"日常在线礼包一">>,
		goods_id=531201, 
		get_way=2, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(2005) ->
	#ets_gift{ 
		id=2005, 
		name = <<"日常在线礼包二">>,
		goods_id=531201, 
		get_way=2, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(2006) ->
	#ets_gift{ 
		id=2006, 
		name = <<"日常在线礼包三">>,
		goods_id=531201, 
		get_way=2, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(2007) ->
	#ets_gift{ 
		id=2007, 
		name = <<"日常在线礼包四">>,
		goods_id=531201, 
		get_way=2, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(2008) ->
	#ets_gift{ 
		id=2008, 
		name = <<"日常在线礼包五">>,
		goods_id=531201, 
		get_way=2, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(2009) ->
	#ets_gift{ 
		id=2009, 
		name = <<"日常在线礼包六">>,
		goods_id=531201, 
		get_way=2, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(2010) ->
	#ets_gift{ 
		id=2010, 
		name = <<"日常在线礼包七">>,
		goods_id=531201, 
		get_way=2, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3011) ->
	#ets_gift{ 
		id=3011, 
		name = <<"远征目标新礼包1">>,
		goods_id=531616, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,10,10},{goods,621301,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3012) ->
	#ets_gift{ 
		id=3012, 
		name = <<"远征目标新礼包2">>,
		goods_id=531617, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,10,10},{goods,211001,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3013) ->
	#ets_gift{ 
		id=3013, 
		name = <<"远征目标新礼包3">>,
		goods_id=531618, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,10,10},{goods,611601,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3014) ->
	#ets_gift{ 
		id=3014, 
		name = <<"远征目标新礼包4">>,
		goods_id=531619, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,10,10},{goods,611002,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3015) ->
	#ets_gift{ 
		id=3015, 
		name = <<"远征目标新礼包5">>,
		goods_id=531620, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,10,10},{goods,611201,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3016) ->
	#ets_gift{ 
		id=3016, 
		name = <<"远征目标新礼包6">>,
		goods_id=531621, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,20,20},{goods,112302,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3017) ->
	#ets_gift{ 
		id=3017, 
		name = <<"远征目标新礼包7">>,
		goods_id=531622, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,20,20},{goods,111021,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3018) ->
	#ets_gift{ 
		id=3018, 
		name = <<"远征目标新礼包8">>,
		goods_id=531623, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,20,20},{goods,624203,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3019) ->
	#ets_gift{ 
		id=3019, 
		name = <<"远征目标新礼包9">>,
		goods_id=531624, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,20,20},{goods,601501,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3020) ->
	#ets_gift{ 
		id=3020, 
		name = <<"远征目标新礼包10">>,
		goods_id=531625, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,20,20},{goods,212901,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3021) ->
	#ets_gift{ 
		id=3021, 
		name = <<"远征目标新礼包11">>,
		goods_id=531626, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,20,20},{goods,611201,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3022) ->
	#ets_gift{ 
		id=3022, 
		name = <<"远征目标新礼包12">>,
		goods_id=531627, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,30,30},{goods,624801,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3023) ->
	#ets_gift{ 
		id=3023, 
		name = <<"远征目标新礼包13">>,
		goods_id=531628, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,30,30},{goods,111022,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3024) ->
	#ets_gift{ 
		id=3024, 
		name = <<"远征目标新礼包14">>,
		goods_id=531629, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,30,30},{goods,111411,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3025) ->
	#ets_gift{ 
		id=3025, 
		name = <<"远征目标新礼包15">>,
		goods_id=531630, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,30,30},{goods,601501,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3026) ->
	#ets_gift{ 
		id=3026, 
		name = <<"远征目标新礼包16">>,
		goods_id=531631, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,30,30},{goods,111421,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3027) ->
	#ets_gift{ 
		id=3027, 
		name = <<"远征目标新礼包17">>,
		goods_id=531632, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,40,40},{goods,624801,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3028) ->
	#ets_gift{ 
		id=3028, 
		name = <<"远征目标新礼包18">>,
		goods_id=531633, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,40,40},{goods,624203,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3029) ->
	#ets_gift{ 
		id=3029, 
		name = <<"远征目标新礼包19">>,
		goods_id=531634, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,40,40},{goods,111401,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3030) ->
	#ets_gift{ 
		id=3030, 
		name = <<"远征目标新礼包20">>,
		goods_id=531635, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,40,40},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3031) ->
	#ets_gift{ 
		id=3031, 
		name = <<"远征目标新礼包21">>,
		goods_id=531636, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,50,50},{goods,624801,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3032) ->
	#ets_gift{ 
		id=3032, 
		name = <<"远征目标新礼包22">>,
		goods_id=531637, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,50,50},{goods,624201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3033) ->
	#ets_gift{ 
		id=3033, 
		name = <<"远征目标新礼包23">>,
		goods_id=531638, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,50,50},{goods,601501,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3034) ->
	#ets_gift{ 
		id=3034, 
		name = <<"远征目标新礼包24">>,
		goods_id=531639, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,50,50},{goods,205301,1},{goods,206301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3035) ->
	#ets_gift{ 
		id=3035, 
		name = <<"远征目标新礼包25">>,
		goods_id=531640, 
		get_way=2, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3041) ->
	#ets_gift{ 
		id=3041, 
		name = <<"西游目标1">>,
		goods_id=531641, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,100,100},{goods,121001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3042) ->
	#ets_gift{ 
		id=3042, 
		name = <<"西游目标2">>,
		goods_id=531642, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,100,100},{goods,221501,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3043) ->
	#ets_gift{ 
		id=3043, 
		name = <<"西游目标3">>,
		goods_id=531643, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,100,100},{goods,611601,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3044) ->
	#ets_gift{ 
		id=3044, 
		name = <<"西游目标4">>,
		goods_id=531644, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,100,100},{goods,231201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3045) ->
	#ets_gift{ 
		id=3045, 
		name = <<"西游目标5">>,
		goods_id=531645, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,100,100},{goods,111041,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3047) ->
	#ets_gift{ 
		id=3047, 
		name = <<"西游目标7">>,
		goods_id=531647, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,100,100},{goods,623001,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3048) ->
	#ets_gift{ 
		id=3048, 
		name = <<"西游目标8">>,
		goods_id=531648, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,100,100},{goods,111041,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3049) ->
	#ets_gift{ 
		id=3049, 
		name = <<"西游目标9">>,
		goods_id=531649, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,100,100},{goods,611601,19}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3050) ->
	#ets_gift{ 
		id=3050, 
		name = <<"西游目标10">>,
		goods_id=531650, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,100,100},{goods,111041,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3051) ->
	#ets_gift{ 
		id=3051, 
		name = <<"西游目标11">>,
		goods_id=531651, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,30000,30000},{goods,111041,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3052) ->
	#ets_gift{ 
		id=3052, 
		name = <<"西游目标12">>,
		goods_id=531652, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,30000,30000},{goods,621302,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3053) ->
	#ets_gift{ 
		id=3053, 
		name = <<"西游目标13">>,
		goods_id=531653, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,30000,30000},{goods,111041,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3054) ->
	#ets_gift{ 
		id=3054, 
		name = <<"西游目标14">>,
		goods_id=531654, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,30000,30000},{goods,112301,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3055) ->
	#ets_gift{ 
		id=3055, 
		name = <<"西游目标15">>,
		goods_id=531655, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,30000,30000},{goods,221501,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3056) ->
	#ets_gift{ 
		id=3056, 
		name = <<"西游目标16">>,
		goods_id=531656, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,111481,2},{goods,111491,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3057) ->
	#ets_gift{ 
		id=3057, 
		name = <<"西游目标17">>,
		goods_id=531657, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,40000,40000},{goods,623001,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3058) ->
	#ets_gift{ 
		id=3058, 
		name = <<"西游目标18">>,
		goods_id=531658, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,40000,40000},{goods,311101,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3059) ->
	#ets_gift{ 
		id=3059, 
		name = <<"西游目标19">>,
		goods_id=531659, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,40000,40000},{goods,111041,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3060) ->
	#ets_gift{ 
		id=3060, 
		name = <<"西游目标20">>,
		goods_id=531660, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,40000,40000},{goods,231201,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3061) ->
	#ets_gift{ 
		id=3061, 
		name = <<"西游目标21">>,
		goods_id=531661, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,40000,40000},{goods,624201,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3062) ->
	#ets_gift{ 
		id=3062, 
		name = <<"西游目标22">>,
		goods_id=531662, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,50000,50000},{goods,211003,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3063) ->
	#ets_gift{ 
		id=3063, 
		name = <<"西游目标23">>,
		goods_id=531663, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,50000,50000},{goods,112301,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3064) ->
	#ets_gift{ 
		id=3064, 
		name = <<"西游目标24">>,
		goods_id=531664, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,50000,50000},{goods,111041,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3065) ->
	#ets_gift{ 
		id=3065, 
		name = <<"西游目标25">>,
		goods_id=531665, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,50000,50000},{goods,601601,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3066) ->
	#ets_gift{ 
		id=3066, 
		name = <<"西游目标26">>,
		goods_id=531666, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,50000,50000},{goods,231201,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3067) ->
	#ets_gift{ 
		id=3067, 
		name = <<"西游目标27">>,
		goods_id=531667, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,30,30},{goods,231201,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3068) ->
	#ets_gift{ 
		id=3068, 
		name = <<"西游目标28">>,
		goods_id=531668, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,30,30},{goods,624202,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3069) ->
	#ets_gift{ 
		id=3069, 
		name = <<"西游目标29">>,
		goods_id=531669, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,30,30},{goods,112704,2},{goods,601701,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(3070) ->
	#ets_gift{ 
		id=3070, 
		name = <<"西游目标30">>,
		goods_id=531670, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,30,30},{goods,205301,1},{goods,206301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531001) ->
	#ets_gift{ 
		id=531001, 
		name = <<"10级成长礼包 (531001)">>,
		goods_id=531001, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,10,10},{goods,205101,1},{goods,206101,1},{goods,222001,1},{goods,211001,1},{goods,501202,1},{goods,612501,1},{coin,10000,10000},{goods,111041,1},{goods,531002,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531021) ->
	#ets_gift{ 
		id=531021, 
		name = <<"35级礼包 (531021)">>,
		goods_id=531021, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,25,25},{goods,205101,4},{goods,206101,4},{goods,222001,1},{goods,671001,2},{goods,111501,2},{goods,621301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531022) ->
	#ets_gift{ 
		id=531022, 
		name = <<"40级礼包 (531022)">>,
		goods_id=531022, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,30,30},{goods,205101,5},{goods,206101,5},{goods,612802,1},{goods,671001,3},{goods,111501,2},{goods,621301,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531023) ->
	#ets_gift{ 
		id=531023, 
		name = <<"45级礼包 (531023)">>,
		goods_id=531023, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,35,35},{goods,205101,6},{goods,206101,6},{goods,612802,2},{goods,671001,4},{goods,111501,2},{goods,621301,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531024) ->
	#ets_gift{ 
		id=531024, 
		name = <<"50级礼包 (531024)">>,
		goods_id=531024, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,40,40},{goods,205101,7},{goods,206101,7},{goods,612802,3},{goods,671001,5},{goods,111501,3},{goods,621301,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531025) ->
	#ets_gift{ 
		id=531025, 
		name = <<"55级礼包 (531025)">>,
		goods_id=531025, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,45,45},{goods,205101,8},{goods,206101,8},{goods,612802,4},{goods,671001,6},{goods,111501,4},{goods,621301,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531026) ->
	#ets_gift{ 
		id=531026, 
		name = <<"60级礼包 (531026)">>,
		goods_id=531026, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,50,50},{goods,205101,9},{goods,206101,9},{goods,612802,5},{goods,671001,7},{goods,111501,5},{goods,621301,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531101) ->
	#ets_gift{ 
		id=531101, 
		name = <<"新手在线礼包1 (531101)">>,
		goods_id=531101, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,612501,2},{coin,500,500}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531102) ->
	#ets_gift{ 
		id=531102, 
		name = <<"新手在线礼包2 (531102)">>,
		goods_id=531102, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,671001,2},{goods,221101,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531103) ->
	#ets_gift{ 
		id=531103, 
		name = <<"新手在线礼包3 (531103)">>,
		goods_id=531103, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,621301,1},{goods,221101,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531104) ->
	#ets_gift{ 
		id=531104, 
		name = <<"新手在线礼包4 (531104)">>,
		goods_id=531104, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,211001,1},{goods,221101,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531105) ->
	#ets_gift{ 
		id=531105, 
		name = <<"新手在线礼包5 (531105)">>,
		goods_id=531105, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,111041,1},{goods,221101,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531106) ->
	#ets_gift{ 
		id=531106, 
		name = <<"新手在线礼包6 (531106)">>,
		goods_id=531106, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,205101,1},{goods,221101,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531302) ->
	#ets_gift{ 
		id=531302, 
		name = <<"出师礼包（徒弟）">>,
		goods_id=531501, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531303) ->
	#ets_gift{ 
		id=531303, 
		name = <<"出师礼包（师傅）">>,
		goods_id=531502, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531304) ->
	#ets_gift{ 
		id=531304, 
		name = <<"20级师徒奖励礼包">>,
		goods_id=531503, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531305) ->
	#ets_gift{ 
		id=531305, 
		name = <<"30级师徒奖励礼包">>,
		goods_id=531504, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531306) ->
	#ets_gift{ 
		id=531306, 
		name = <<"拜师礼包">>,
		goods_id=531505, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531310) ->
	#ets_gift{ 
		id=531310, 
		name = <<"听天由命礼包">>,
		goods_id=531801, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,621301,3},{goods,221001,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531331) ->
	#ets_gift{ 
		id=531331, 
		name = <<"平乱任务阶段礼包1">>,
		goods_id=531331, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,501202,5},{coin,8000,8000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531332) ->
	#ets_gift{ 
		id=531332, 
		name = <<"平乱任务阶段礼包2">>,
		goods_id=531332, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,501202,10},{coin,15000,15000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531401) ->
	#ets_gift{ 
		id=531401, 
		name = <<"1级宝石礼盒 (531401)">>,
		goods_id=531401, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,111401,1}],10},{list,[{goods,111411,1}],14},{list,[{goods,111421,1}],12},{list,[{goods,111431,1}],6},{list,[{goods,111441,1}],15},{list,[{goods,111451,1}],15},{list,[{goods,111461,1}],13},{list,[{goods,111471,1}],15}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531402) ->
	#ets_gift{ 
		id=531402, 
		name = <<"2级宝石礼盒 (531402)">>,
		goods_id=531402, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,111402,1}],10},{list,[{goods,111412,1}],14},{list,[{goods,111422,1}],12},{list,[{goods,111432,1}],6},{list,[{goods,111442,1}],15},{list,[{goods,111452,1}],15},{list,[{goods,111462,1}],13},{list,[{goods,111472,1}],15}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531403) ->
	#ets_gift{ 
		id=531403, 
		name = <<"3级宝石礼盒 (531403)">>,
		goods_id=531403, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,111403,1}],10},{list,[{goods,111413,1}],14},{list,[{goods,111423,1}],12},{list,[{goods,111433,1}],6},{list,[{goods,111443,1}],15},{list,[{goods,111453,1}],15},{list,[{goods,111463,1}],13},{list,[{goods,111473,1}],15}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531421) ->
	#ets_gift{ 
		id=531421, 
		name = <<"1-3级宝石箱">>,
		goods_id=531421, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,111401,1}],10},{list,[{goods,111411,1}],12},{list,[{goods,111421,1}],12},{list,[{goods,111431,1}],14},{list,[{goods,111441,1}],13},{list,[{goods,111451,1}],13},{list,[{goods,111461,1}],12},{list,[{goods,111471,1}],14},{list,[{goods,111402,1}],10},{list,[{goods,111412,1}],12},{list,[{goods,111422,1}],12},{list,[{goods,111432,1}],14},{list,[{goods,111442,1}],13},{list,[{goods,111452,1}],13},{list,[{goods,111462,1}],12},{list,[{goods,111472,1}],14},{list,[{goods,111403,1}],7},{list,[{goods,111413,1}],9},{list,[{goods,111423,1}],9},{list,[{goods,111433,1}],11},{list,[{goods,111443,1}],10},{list,[{goods,111453,1}],10},{list,[{goods,111463,1}],9},{list,[{goods,111473,1}],11}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531422) ->
	#ets_gift{ 
		id=531422, 
		name = <<"2-4级宝石箱">>,
		goods_id=531422, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,111402,1}],60},{list,[{goods,111412,1}],84},{list,[{goods,111422,1}],72},{list,[{goods,111432,1}],0},{list,[{goods,111442,1}],90},{list,[{goods,111452,1}],90},{list,[{goods,111462,1}],78},{list,[{goods,111472,1}],90},{list,[{goods,111403,1}],60},{list,[{goods,111413,1}],84},{list,[{goods,111423,1}],72},{list,[{goods,111433,1}],0},{list,[{goods,111443,1}],90},{list,[{goods,111453,1}],90},{list,[{goods,111463,1}],78},{list,[{goods,111473,1}],90},{list,[{goods,111404,1}],12},{list,[{goods,111414,1}],17},{list,[{goods,111424,1}],14},{list,[{goods,111434,1}],0},{list,[{goods,111444,1}],18},{list,[{goods,111454,1}],18},{list,[{goods,111464,1}],16},{list,[{goods,111474,1}],18}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531423) ->
	#ets_gift{ 
		id=531423, 
		name = <<"宝石据守礼盒 (531423)">>,
		goods_id=531423, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,531403,1}],[{list,[{goods,111423,1}],10},{list,[{goods,111443,1}],30},{list,[{goods,111473,1}],30},{list,[{goods,111413,1}],30}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531601) ->
	#ets_gift{ 
		id=531601, 
		name = <<"新手宠物礼包 (531601)">>,
		goods_id=531601, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,10,10},{coin,500,500},{goods,621301,1},{goods,201101,10},{goods,202101,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531602) ->
	#ets_gift{ 
		id=531602, 
		name = <<"新手坐骑礼包 (531602)">>,
		goods_id=531602, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,311001,1},{silver,5,5},{coin,500,500},{goods,201101,10},{goods,202101,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531603) ->
	#ets_gift{ 
		id=531603, 
		name = <<"新手好友礼包 (531603)">>,
		goods_id=531603, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611601,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531604) ->
	#ets_gift{ 
		id=531604, 
		name = <<"新手元神礼包 (531604)">>,
		goods_id=531604, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,5,5},{coin,500,500},{goods,221501,1},{goods,221201,1},{goods,112201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531605) ->
	#ets_gift{ 
		id=531605, 
		name = <<"新手帮派礼包 (531605)">>,
		goods_id=531605, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,5,5},{coin,500,500},{goods,201101,10},{goods,202101,10},{goods,112201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531606) ->
	#ets_gift{ 
		id=531606, 
		name = <<"新手市场礼包 (531606)">>,
		goods_id=531606, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,5,5},{coin,500,500},{goods,201101,10},{goods,202101,10},{goods,112704,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531607) ->
	#ets_gift{ 
		id=531607, 
		name = <<"新手日常礼包 (531607)">>,
		goods_id=531607, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,5,5},{coin,500,500},{goods,201101,10},{goods,202101,10},{goods,601701,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531608) ->
	#ets_gift{ 
		id=531608, 
		name = <<"新手铸造礼包 (531608)">>,
		goods_id=531608, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,5,5},{coin,500,500},{goods,201101,10},{goods,202101,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531609) ->
	#ets_gift{ 
		id=531609, 
		name = <<"新手宝石礼包 (531609)">>,
		goods_id=531609, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,5,5},{coin,500,500},{goods,112201,1},{goods,201101,10},{goods,202101,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531610) ->
	#ets_gift{ 
		id=531610, 
		name = <<"新手炼炉礼包 (531610)">>,
		goods_id=531610, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,5,5},{coin,500,500},{goods,112704,1},{goods,201101,10},{goods,202101,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531611) ->
	#ets_gift{ 
		id=531611, 
		name = <<"新手淘宝礼包 (531611)">>,
		goods_id=531611, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,5,5},{coin,500,500},{goods,112201,1},{goods,201101,10},{goods,202101,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531701) ->
	#ets_gift{ 
		id=531701, 
		name = <<"红包 (531701)">>,
		goods_id=531701, 
		get_way=1, 
		gift_rand=1, 
		gifts=[{goods,221001,1},{goods,221001,1},{coin,1800,4000},{goods,205101,1},{goods,206101,1},{goods,212201,1},{goods,212301,1},{goods,212401,1},{goods,621301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531702) ->
	#ets_gift{ 
		id=531702, 
		name = <<"藏宝图礼包1(531702)">>,
		goods_id=531702, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,613703,1}],50},{list,[{goods,613708,1}],50},{list,[{goods,613709,1}],50},{list,[{goods,613714,1}],50},{list,[{goods,613715,1}],50},{list,[{goods,613716,1}],50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531703) ->
	#ets_gift{ 
		id=531703, 
		name = <<"藏宝图礼包2(531703)">>,
		goods_id=531703, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,613701,1}],50},{list,[{goods,613704,1}],50},{list,[{goods,613705,1}],50},{list,[{goods,613706,1}],50},{list,[{goods,613707,1}],50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531704) ->
	#ets_gift{ 
		id=531704, 
		name = <<"藏宝图礼包3(531704)">>,
		goods_id=531704, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,613702,1}],50},{list,[{goods,613710,1}],50},{list,[{goods,613711,1}],50},{list,[{goods,613712,1}],50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531711) ->
	#ets_gift{ 
		id=531711, 
		name = <<"40+活跃度10">>,
		goods_id=531711, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,2000,2000},{goods,621301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531712) ->
	#ets_gift{ 
		id=531712, 
		name = <<"40+活跃度20">>,
		goods_id=531712, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,3000,3000},{goods,671001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531713) ->
	#ets_gift{ 
		id=531713, 
		name = <<"40+活跃度30">>,
		goods_id=531713, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,4000,4000},{goods,211001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531714) ->
	#ets_gift{ 
		id=531714, 
		name = <<"40+活跃度50">>,
		goods_id=531714, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,6000,6000},{goods,501202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531715) ->
	#ets_gift{ 
		id=531715, 
		name = <<"40+活跃度70">>,
		goods_id=531715, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,8000,8000},{goods,612501,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531716) ->
	#ets_gift{ 
		id=531716, 
		name = <<"40+活跃度100">>,
		goods_id=531716, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,10000,10000},{goods,205101,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531717) ->
	#ets_gift{ 
		id=531717, 
		name = <<"40+活跃度礼包110">>,
		goods_id=531717, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,12000,12000},{goods,111041,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531718) ->
	#ets_gift{ 
		id=531718, 
		name = <<"40+活跃度礼包120">>,
		goods_id=531718, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,14000,14000},{goods,612802,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531721) ->
	#ets_gift{ 
		id=531721, 
		name = <<"50+活跃度10">>,
		goods_id=531721, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,2000,2000},{goods,621301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531722) ->
	#ets_gift{ 
		id=531722, 
		name = <<"50+活跃度20">>,
		goods_id=531722, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,3000,3000},{goods,671001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531723) ->
	#ets_gift{ 
		id=531723, 
		name = <<"50+活跃度30">>,
		goods_id=531723, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,4000,4000},{goods,211001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531724) ->
	#ets_gift{ 
		id=531724, 
		name = <<"50+活跃度50">>,
		goods_id=531724, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,6000,6000},{goods,501202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531725) ->
	#ets_gift{ 
		id=531725, 
		name = <<"50+活跃度70">>,
		goods_id=531725, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,8000,8000},{goods,612501,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531726) ->
	#ets_gift{ 
		id=531726, 
		name = <<"50+活跃度100">>,
		goods_id=531726, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,10000,10000},{goods,205101,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531727) ->
	#ets_gift{ 
		id=531727, 
		name = <<"50+活跃度礼包110">>,
		goods_id=531727, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,12000,12000},{goods,111041,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531728) ->
	#ets_gift{ 
		id=531728, 
		name = <<"50+活跃度礼包120">>,
		goods_id=531728, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,14000,14000},{goods,612802,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531731) ->
	#ets_gift{ 
		id=531731, 
		name = <<"60+活跃度10">>,
		goods_id=531731, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,2000,2000},{goods,621301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531732) ->
	#ets_gift{ 
		id=531732, 
		name = <<"60+活跃度20">>,
		goods_id=531732, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,3000,3000},{goods,671001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531733) ->
	#ets_gift{ 
		id=531733, 
		name = <<"60+活跃度30">>,
		goods_id=531733, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,4000,4000},{goods,211001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531734) ->
	#ets_gift{ 
		id=531734, 
		name = <<"60+活跃度50">>,
		goods_id=531734, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,6000,6000},{goods,501202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531735) ->
	#ets_gift{ 
		id=531735, 
		name = <<"60+活跃度70">>,
		goods_id=531735, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,8000,8000},{goods,612501,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531736) ->
	#ets_gift{ 
		id=531736, 
		name = <<"60+活跃度100">>,
		goods_id=531736, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,10000,10000},{goods,205101,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531737) ->
	#ets_gift{ 
		id=531737, 
		name = <<"60+活跃度礼包110">>,
		goods_id=531737, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,12000,12000},{goods,111041,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531738) ->
	#ets_gift{ 
		id=531738, 
		name = <<"60+活跃度礼包120">>,
		goods_id=531738, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{coin,14000,14000},{goods,612802,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531802) ->
	#ets_gift{ 
		id=531802, 
		name = <<"测试礼包1">>,
		goods_id=531802, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,532012,1},{equip,101833,0,0},{equip,101733,0,0},{coin,168888,168888},{goods,624202,10},{goods,624801,10},{goods,612802,5},{goods,112301,5},{goods,211003,5},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531803) ->
	#ets_gift{ 
		id=531803, 
		name = <<"测试礼包2">>,
		goods_id=531803, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,532011,1},{coin,88888,88888},{goods,231201,10},{goods,112201,10},{goods,601501,5},{goods,205201,2},{goods,206201,2},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531804) ->
	#ets_gift{ 
		id=531804, 
		name = <<"测试礼包3">>,
		goods_id=531804, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121007,1},{coin,88888,88888},{goods,111024,3},{goods,112704,3},{goods,601701,3},{goods,205201,3},{goods,206201,3},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531805) ->
	#ets_gift{ 
		id=531805, 
		name = <<"测试礼包4">>,
		goods_id=531805, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611703,1},{coin,188888,188888},{goods,621101,1},{goods,112301,18},{goods,231201,10},{goods,205301,2},{goods,206301,2},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531806) ->
	#ets_gift{ 
		id=531806, 
		name = <<"测试礼包5">>,
		goods_id=531806, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611905,1},{coin,188888,188888},{goods,621101,2},{goods,112301,38},{goods,231212,10},{goods,205301,3},{goods,206301,3},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531807) ->
	#ets_gift{ 
		id=531807, 
		name = <<"测试礼包6">>,
		goods_id=531807, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311002,1},{coin,288888,288888},{goods,621101,3},{goods,112301,58},{goods,231213,50},{goods,205301,5},{goods,206301,5},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531811) ->
	#ets_gift{ 
		id=531811, 
		name = <<"剧情本礼包1">>,
		goods_id=531811, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531812) ->
	#ets_gift{ 
		id=531812, 
		name = <<"剧情本礼包2">>,
		goods_id=531812, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,231201,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531813) ->
	#ets_gift{ 
		id=531813, 
		name = <<"剧情本礼包3">>,
		goods_id=531813, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,10},{goods,601601,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531814) ->
	#ets_gift{ 
		id=531814, 
		name = <<"剧情本礼包4">>,
		goods_id=531814, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,15}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531815) ->
	#ets_gift{ 
		id=531815, 
		name = <<"剧情本礼包5">>,
		goods_id=531815, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,20},{goods,112704,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531816) ->
	#ets_gift{ 
		id=531816, 
		name = <<"剧情本礼包6">>,
		goods_id=531816, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,30},{goods,601601,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531817) ->
	#ets_gift{ 
		id=531817, 
		name = <<"剧情本礼包7">>,
		goods_id=531817, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,25}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531818) ->
	#ets_gift{ 
		id=531818, 
		name = <<"剧情本礼包8">>,
		goods_id=531818, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,40}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531819) ->
	#ets_gift{ 
		id=531819, 
		name = <<"剧情本礼包9">>,
		goods_id=531819, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,50},{goods,601601,16}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531820) ->
	#ets_gift{ 
		id=531820, 
		name = <<"剧情本礼包10">>,
		goods_id=531820, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,60},{goods,112201,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531821) ->
	#ets_gift{ 
		id=531821, 
		name = <<"剧情本礼包11">>,
		goods_id=531821, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,70},{goods,112704,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531822) ->
	#ets_gift{ 
		id=531822, 
		name = <<"剧情本礼包12">>,
		goods_id=531822, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,80},{goods,601701,10},{goods,601602,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531823) ->
	#ets_gift{ 
		id=531823, 
		name = <<"封魔录序章霸主礼包">>,
		goods_id=531823, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,5000,5000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531824) ->
	#ets_gift{ 
		id=531824, 
		name = <<"封魔录第一章霸主礼包">>,
		goods_id=531824, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,10000,10000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531825) ->
	#ets_gift{ 
		id=531825, 
		name = <<"封魔录第二章霸主礼包">>,
		goods_id=531825, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,15000,15000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531826) ->
	#ets_gift{ 
		id=531826, 
		name = <<"封魔录第三章霸主礼包">>,
		goods_id=531826, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,20000,20000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531827) ->
	#ets_gift{ 
		id=531827, 
		name = <<"剧情本礼包13">>,
		goods_id=531827, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,60},{goods,112201,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531828) ->
	#ets_gift{ 
		id=531828, 
		name = <<"剧情本礼包14">>,
		goods_id=531828, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,70},{goods,112704,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531829) ->
	#ets_gift{ 
		id=531829, 
		name = <<"剧情本礼包15">>,
		goods_id=531829, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,80},{goods,601701,10},{goods,601602,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531830) ->
	#ets_gift{ 
		id=531830, 
		name = <<"封魔录第四章霸主礼包">>,
		goods_id=531830, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,25000,25000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531831) ->
	#ets_gift{ 
		id=531831, 
		name = <<"封魔录第五章霸主礼包">>,
		goods_id=531831, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,30000,30000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531832) ->
	#ets_gift{ 
		id=531832, 
		name = <<"剧情本礼包16">>,
		goods_id=531832, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,60},{goods,112201,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531833) ->
	#ets_gift{ 
		id=531833, 
		name = <<"剧情本礼包17">>,
		goods_id=531833, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,70},{goods,112704,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531834) ->
	#ets_gift{ 
		id=531834, 
		name = <<"剧情本礼包18">>,
		goods_id=531834, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221501,80},{goods,601701,10},{goods,601602,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(531901) ->
	#ets_gift{ 
		id=531901, 
		name = <<"新手卡礼包">>,
		goods_id=531901, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,30,30},{coin,30000,30000},{goods,222001,1},{goods,205101,1},{goods,206101,1},{goods,612802,1},{goods,211001,5},{goods,612501,10},{goods,111041,10},{goods,624801,10},{goods,621301,10},{goods,501202,10},{goods,671001,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532001) ->
	#ets_gift{ 
		id=532001, 
		name = <<"首充礼包">>,
		goods_id=532001, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112104,1},{goods,532012,1},{equip,101833,0,0},{equip,101733,0,0},{coin,168888,168888},{goods,624202,10},{goods,624801,10},{goods,612802,5},{goods,111024,1},{goods,211003,5},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532011) ->
	#ets_gift{ 
		id=532011, 
		name = <<"国宝时装礼盒 (532011)">>,
		goods_id=532011, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{equip,[106107,106307,106207],0,0}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532012) ->
	#ets_gift{ 
		id=532012, 
		name = <<"烤翅时装礼盒 (532012)">>,
		goods_id=532012, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{equip,[106704,106904,106804],0,0}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532013) ->
	#ets_gift{ 
		id=532013, 
		name = <<"灵犀蝶翼礼盒 (532013)">>,
		goods_id=532013, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{equip,[106211,106221,106231],0,0}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532014) ->
	#ets_gift{ 
		id=532014, 
		name = <<"朝华夕秀礼盒 (532014)">>,
		goods_id=532014, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{equip,[106015,106025,106035],0,0}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532015) ->
	#ets_gift{ 
		id=532015, 
		name = <<"XX礼盒 (532015)">>,
		goods_id=532013, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{equip,[106211,106221,106231],0,0}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532016) ->
	#ets_gift{ 
		id=532016, 
		name = <<"XX礼盒 (532016)">>,
		goods_id=532013, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{equip,[106211,106221,106231],0,0}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532017) ->
	#ets_gift{ 
		id=532017, 
		name = <<"XX礼盒 (532017)">>,
		goods_id=532013, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{equip,[106211,106221,106231],0,0}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532018) ->
	#ets_gift{ 
		id=532018, 
		name = <<"妙法莲华大礼包">>,
		goods_id=532018, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611929,1},{goods,614009,1},{goods,621101,1},{goods,205201,3},{goods,206201,3},{coin,188888,188888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532021) ->
	#ets_gift{ 
		id=532021, 
		name = <<"880元宝礼包 (532021)">>,
		goods_id=532021, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,532011,1},{goods,121003,1},{coin,88888,88888},{goods,231201,10},{goods,112201,10},{goods,601501,5},{goods,205201,2},{goods,206201,2},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532022) ->
	#ets_gift{ 
		id=532022, 
		name = <<"2880元宝礼包 (532022)">>,
		goods_id=532022, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611703,1},{goods,121004,1},{coin,88888,88888},{goods,111024,3},{goods,112704,3},{goods,601701,3},{goods,205201,3},{goods,206201,3},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532023) ->
	#ets_gift{ 
		id=532023, 
		name = <<"5888元宝礼包">>,
		goods_id=532023, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611905,1},{goods,121005,1},{coin,188888,188888},{goods,621101,1},{goods,112301,18},{goods,231201,10},{goods,205301,2},{goods,206301,2},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532024) ->
	#ets_gift{ 
		id=532024, 
		name = <<"8888元宝礼包">>,
		goods_id=532024, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611714,1},{goods,121006,1},{coin,188888,188888},{goods,621101,2},{goods,112301,38},{goods,231212,10},{goods,205301,3},{goods,206301,3},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532025) ->
	#ets_gift{ 
		id=532025, 
		name = <<"18888元宝礼包">>,
		goods_id=532025, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611913,1},{goods,311501,1},{coin,288888,288888},{goods,621101,3},{goods,112301,58},{goods,231213,10},{goods,205301,5},{goods,206301,5},{goods,621302,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532101) ->
	#ets_gift{ 
		id=532101, 
		name = <<"补偿礼包 (532101)">>,
		goods_id=532101, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,30,30},{coin,25000,25000},{goods,211001,1},{goods,205101,1},{goods,206101,1},{goods,112302,3},{goods,111021,1},{goods,621301,5},{goods,611201,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532201) ->
	#ets_gift{ 
		id=532201, 
		name = <<"超级神兽礼包（30级） (532201)">>,
		goods_id=532201, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,101044,1}],10},{list,[{goods,101049,1}],10},{list,[{goods,101744,1}],60},{list,[{goods,101844,1}],60},{list,[{goods,101944,1}],10},{list,[{goods,102044,1}],10},{list,[{goods,102049,1}],10},{list,[{goods,102944,1}],10},{list,[{goods,103044,1}],10},{list,[{goods,103049,1}],10},{list,[{goods,103944,1}],10},{list,[{goods,112231,1}],210},{list,[{goods,112201,1}],800},{list,[{goods,112704,1}],400},{list,[{goods,601701,1}],200},{list,[{goods,601601,1}],400}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532202) ->
	#ets_gift{ 
		id=532202, 
		name = <<"高级神兽礼包（30级） (532202)">>,
		goods_id=532202, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,101044,1}],10},{list,[{goods,101049,1}],10},{list,[{goods,101744,1}],60},{list,[{goods,101844,1}],60},{list,[{goods,101944,1}],10},{list,[{goods,102044,1}],10},{list,[{goods,102049,1}],10},{list,[{goods,102944,1}],10},{list,[{goods,103044,1}],10},{list,[{goods,103049,1}],10},{list,[{goods,103944,1}],10},{list,[{goods,112231,1}],210},{list,[{goods,112201,1}],1000},{list,[{goods,112704,1}],500},{list,[{goods,601701,1}],250},{list,[{goods,601601,1}],500}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532203) ->
	#ets_gift{ 
		id=532203, 
		name = <<"超级神兽礼包（40级） (532203)">>,
		goods_id=532203, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,101044,1}],10},{list,[{goods,101049,1}],10},{list,[{goods,101744,1}],60},{list,[{goods,101844,1}],60},{list,[{goods,101944,1}],10},{list,[{goods,102044,1}],10},{list,[{goods,102049,1}],10},{list,[{goods,102944,1}],10},{list,[{goods,103044,1}],10},{list,[{goods,103049,1}],10},{list,[{goods,103944,1}],10},{list,[{goods,112231,1}],210},{list,[{goods,112201,1}],800},{list,[{goods,112704,1}],400},{list,[{goods,601701,1}],200},{list,[{goods,601601,1}],400}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532204) ->
	#ets_gift{ 
		id=532204, 
		name = <<"高级神兽礼包（40级） (532204)">>,
		goods_id=532204, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,101044,1}],10},{list,[{goods,101049,1}],10},{list,[{goods,101744,1}],60},{list,[{goods,101844,1}],60},{list,[{goods,101944,1}],10},{list,[{goods,102044,1}],10},{list,[{goods,102049,1}],10},{list,[{goods,102944,1}],10},{list,[{goods,103044,1}],10},{list,[{goods,103049,1}],10},{list,[{goods,103944,1}],10},{list,[{goods,112231,1}],210},{list,[{goods,112201,1}],1000},{list,[{goods,112704,1}],500},{list,[{goods,601701,1}],250},{list,[{goods,601601,1}],500}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532205) ->
	#ets_gift{ 
		id=532205, 
		name = <<"超级神兽礼包（50级） (532205)">>,
		goods_id=532205, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,101054,1}],10},{list,[{goods,101059,1}],10},{list,[{goods,101754,1}],60},{list,[{goods,101854,1}],60},{list,[{goods,101954,1}],10},{list,[{goods,102054,1}],10},{list,[{goods,102059,1}],10},{list,[{goods,102954,1}],10},{list,[{goods,103054,1}],10},{list,[{goods,103059,1}],10},{list,[{goods,103954,1}],10},{list,[{goods,112231,1}],210},{list,[{goods,112201,1}],800},{list,[{goods,112704,1}],400},{list,[{goods,601701,1}],200},{list,[{goods,601601,1}],400}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532206) ->
	#ets_gift{ 
		id=532206, 
		name = <<"高级神兽礼包（50级） (532206)">>,
		goods_id=532206, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,101054,1}],10},{list,[{goods,101059,1}],10},{list,[{goods,101754,1}],60},{list,[{goods,101854,1}],60},{list,[{goods,101954,1}],10},{list,[{goods,102054,1}],10},{list,[{goods,102059,1}],10},{list,[{goods,102954,1}],10},{list,[{goods,103054,1}],10},{list,[{goods,103059,1}],10},{list,[{goods,103954,1}],10},{list,[{goods,112231,1}],210},{list,[{goods,112201,1}],1000},{list,[{goods,112704,1}],500},{list,[{goods,601701,1}],250},{list,[{goods,601601,1}],500}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532207) ->
	#ets_gift{ 
		id=532207, 
		name = <<"超级神兽礼包（60级） (532207)">>,
		goods_id=532207, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,101064,1}],10},{list,[{goods,101069,1}],10},{list,[{goods,101764,1}],60},{list,[{goods,101864,1}],60},{list,[{goods,101964,1}],10},{list,[{goods,102064,1}],10},{list,[{goods,102069,1}],10},{list,[{goods,102964,1}],10},{list,[{goods,103064,1}],10},{list,[{goods,103069,1}],10},{list,[{goods,103964,1}],10},{list,[{goods,112231,1}],210},{list,[{goods,112202,1}],800},{list,[{goods,112705,1}],400},{list,[{goods,601701,1}],200},{list,[{goods,601602,1}],400}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532208) ->
	#ets_gift{ 
		id=532208, 
		name = <<"高级神兽礼包（60级） (532208)">>,
		goods_id=532208, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,101064,1}],10},{list,[{goods,101069,1}],10},{list,[{goods,101764,1}],60},{list,[{goods,101864,1}],60},{list,[{goods,101964,1}],10},{list,[{goods,102064,1}],10},{list,[{goods,102069,1}],10},{list,[{goods,102964,1}],10},{list,[{goods,103064,1}],10},{list,[{goods,103069,1}],10},{list,[{goods,103964,1}],10},{list,[{goods,112231,1}],210},{list,[{goods,112202,1}],1000},{list,[{goods,112705,1}],500},{list,[{goods,601701,1}],250},{list,[{goods,601602,1}],500}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532209) ->
	#ets_gift{ 
		id=532209, 
		name = <<"40级材料礼包 (532209)">>,
		goods_id=532209, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112201,1}],800},{list,[{goods,112202,1}],0},{list,[{goods,112203,1}],0},{list,[{goods,112704,1}],100},{list,[{goods,112705,1}],0},{list,[{goods,112706,1}],0},{list,[{goods,601701,1}],100}],
		bind=0,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532210) ->
	#ets_gift{ 
		id=532210, 
		name = <<"50级材料礼包 (532210)">>,
		goods_id=532210, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112201,1}],625},{list,[{goods,112202,1}],110},{list,[{goods,112203,1}],0},{list,[{goods,112704,1}],100},{list,[{goods,112705,1}],15},{list,[{goods,112706,1}],0},{list,[{goods,601701,1}],150}],
		bind=0,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532211) ->
	#ets_gift{ 
		id=532211, 
		name = <<"60级材料礼包 (532211)">>,
		goods_id=532211, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112201,1}],428},{list,[{goods,112202,1}],150},{list,[{goods,112203,1}],50},{list,[{goods,112704,1}],100},{list,[{goods,112705,1}],20},{list,[{goods,112706,1}],2},{list,[{goods,601701,1}],250}],
		bind=0,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532213) ->
	#ets_gift{ 
		id=532213, 
		name = <<"40级九重天礼包 (532213)">>,
		goods_id=532213, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112201,1}],800},{list,[{goods,112202,1}],0},{list,[{goods,112203,1}],0},{list,[{goods,112704,1}],100},{list,[{goods,112705,1}],0},{list,[{goods,112706,1}],0},{list,[{goods,601701,1}],100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532214) ->
	#ets_gift{ 
		id=532214, 
		name = <<"50级九重天礼包 (532214)">>,
		goods_id=532214, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112201,1}],625},{list,[{goods,112202,1}],110},{list,[{goods,112203,1}],0},{list,[{goods,112704,1}],100},{list,[{goods,112705,1}],15},{list,[{goods,112706,1}],0},{list,[{goods,601701,1}],150}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532215) ->
	#ets_gift{ 
		id=532215, 
		name = <<"60级九重天礼包 (532215)">>,
		goods_id=532215, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112201,1}],428},{list,[{goods,112202,1}],150},{list,[{goods,112203,1}],50},{list,[{goods,112704,1}],100},{list,[{goods,112705,1}],20},{list,[{goods,112706,1}],2},{list,[{goods,601701,1}],250}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532217) ->
	#ets_gift{ 
		id=532217, 
		name = <<"初级神兽礼包">>,
		goods_id=532217, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112231,1}],50},{list,[{goods,112201,1}],800},{list,[{goods,112704,1}],400},{list,[{goods,601701,1}],200},{list,[{goods,601601,1}],100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[112231, 112203, 112706, 601601],
		status=1
	};
get(532218) ->
	#ets_gift{ 
		id=532218, 
		name = <<"中级神兽礼包">>,
		goods_id=532218, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112231,1}],50},{list,[{goods,112201,1}],600},{list,[{goods,112704,1}],300},{list,[{goods,112202,1}],200},{list,[{goods,112705,1}],100},{list,[{goods,601701,1}],200},{list,[{goods,601601,1}],100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[112231, 112203, 112706, 601601],
		status=1
	};
get(532219) ->
	#ets_gift{ 
		id=532219, 
		name = <<"高级神兽礼包">>,
		goods_id=532219, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112231,1}],50},{list,[{goods,112203,1}],600},{list,[{goods,112706,1}],300},{list,[{goods,112202,1}],200},{list,[{goods,112705,1}],100},{list,[{goods,601701,1}],200},{list,[{goods,601601,1}],100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[112231, 112203, 112706, 601601],
		status=1
	};
get(532220) ->
	#ets_gift{ 
		id=532220, 
		name = <<"帮战礼包(532220)">>,
		goods_id=532220, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,2},{goods,624203,5},{goods,624802,2},{goods,412103,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532221) ->
	#ets_gift{ 
		id=532221, 
		name = <<"试炼礼包·白 (532221)">>,
		goods_id=532221, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,621301,1}],10},{list,[{goods,112301,1}],20},{list,[{goods,112302,1}],15},{list,[{goods,112301,1}],0},{list,[{goods,205101,1}],10},{list,[{goods,206101,1}],10},{list,[{goods,205201,1}],0},{list,[{goods,206201,1}],0},{list,[{goods,221101,1}],10},{list,[{goods,221001,1}],10},{list,[{goods,221102,1}],0},{list,[{goods,221002,1}],0}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532222) ->
	#ets_gift{ 
		id=532222, 
		name = <<"试炼礼包·绿 (532222)">>,
		goods_id=532222, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,621301,1}],10},{list,[{goods,112301,1}],20},{list,[{goods,112302,1}],15},{list,[{goods,112301,1}],0},{list,[{goods,205101,1}],10},{list,[{goods,206101,1}],10},{list,[{goods,205201,1}],0},{list,[{goods,206201,1}],0},{list,[{goods,221101,1}],10},{list,[{goods,221001,1}],10},{list,[{goods,221102,1}],0},{list,[{goods,221002,1}],0}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532223) ->
	#ets_gift{ 
		id=532223, 
		name = <<"试炼礼包·蓝 (532223)">>,
		goods_id=532223, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,621301,1}],10},{list,[{goods,112301,1}],15},{list,[{goods,112302,1}],20},{list,[{goods,112301,1}],0},{list,[{goods,205101,1}],10},{list,[{goods,206101,1}],10},{list,[{goods,205201,1}],0},{list,[{goods,206201,1}],0},{list,[{goods,221101,1}],10},{list,[{goods,221001,1}],10},{list,[{goods,221102,1}],10},{list,[{goods,221002,1}],10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532224) ->
	#ets_gift{ 
		id=532224, 
		name = <<"试炼礼包·紫 (532224)">>,
		goods_id=532224, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,621301,1}],10},{list,[{goods,112301,1}],10},{list,[{goods,112302,1}],20},{list,[{goods,112301,1}],10},{list,[{goods,205101,1}],10},{list,[{goods,206101,1}],10},{list,[{goods,205201,1}],10},{list,[{goods,206201,1}],10},{list,[{goods,221101,1}],10},{list,[{goods,221001,1}],10},{list,[{goods,221102,1}],10},{list,[{goods,221002,1}],10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532225) ->
	#ets_gift{ 
		id=532225, 
		name = <<"试炼礼包·橙 (532225)">>,
		goods_id=532225, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,621301,1}],10},{list,[{goods,112301,1}],10},{list,[{goods,112302,1}],15},{list,[{goods,112301,1}],15},{list,[{goods,205101,1}],10},{list,[{goods,206101,1}],10},{list,[{goods,205201,1}],10},{list,[{goods,206201,1}],10},{list,[{goods,221101,1}],10},{list,[{goods,221001,1}],10},{list,[{goods,221102,1}],10},{list,[{goods,221002,1}],10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532231) ->
	#ets_gift{ 
		id=532231, 
		name = <<"仙宴福袋 (532231)">>,
		goods_id=532231, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221202,1},{goods,412001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532232) ->
	#ets_gift{ 
		id=532232, 
		name = <<"筹办福袋（蟠桃仙宴） (532232)">>,
		goods_id=532232, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,205101,1},{goods,206101,1},{goods,111021,1},{goods,412001,3},{goods,412002,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532233) ->
	#ets_gift{ 
		id=532233, 
		name = <<"筹办福袋（人参果宴） (532233)">>,
		goods_id=532233, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,205201,1},{goods,206201,1},{goods,111023,1},{goods,412001,4},{goods,412002,2},{goods,412004,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532234) ->
	#ets_gift{ 
		id=532234, 
		name = <<"筹办福袋（瑶池酒宴） (532234)">>,
		goods_id=532234, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,205301,1},{goods,206301,1},{goods,111025,1},{goods,412001,5},{goods,412002,3},{goods,412004,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532236) ->
	#ets_gift{ 
		id=532236, 
		name = <<"蟠桃 (532236)">>,
		goods_id=532236, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{exp,2500,2500},{coin,200,500}],[{list,[{goods,411301,1}],70},{list,[{coin,1,1}],30}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532237) ->
	#ets_gift{ 
		id=532237, 
		name = <<"人参果 (532237)">>,
		goods_id=532237, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{exp,5000,5000},{coin,300,500}],[{list,[{goods,411301,2}],70},{list,[{coin,1,1}],30}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532238) ->
	#ets_gift{ 
		id=532238, 
		name = <<"瑶池仙酿 (532238)">>,
		goods_id=532238, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{exp,7500,7500},{coin,400,500}],[{list,[{goods,411301,3}],70},{list,[{coin,1,1}],30}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532250) ->
	#ets_gift{ 
		id=532250, 
		name = <<"紫水晶礼盒 (532250)">>,
		goods_id=532250, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112104,1}],1},{list,[{goods,112201,1}],90},{list,[{goods,112704,1}],40},{list,[{goods,601701,1}],10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[112104, 112105, 601701, 523505, 621101, 523502, 523503, 523504, 112104, 121005, 121006, 112231, 111030, 112104, 112105],
		status=1
	};
get(532251) ->
	#ets_gift{ 
		id=532251, 
		name = <<"橙水晶礼盒 (532251)">>,
		goods_id=532251, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112105,1}],1},{list,[{goods,112201,1}],180},{list,[{goods,112202,1}],60},{list,[{goods,112704,1}],30},{list,[{goods,112705,1}],10},{list,[{goods,601701,1}],10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[112104, 112105, 601701, 523505, 621101, 523502, 523503, 523504, 112104, 121005, 121006, 112231, 111030, 112104, 112105],
		status=1
	};
get(532252) ->
	#ets_gift{ 
		id=532252, 
		name = <<"帮派福利袋">>,
		goods_id=532252, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,111041,1}],50},{list,[{goods,501202,1}],50},{list,[{goods,501202,1}],50},{list,[{goods,612501,1}],50},{list,[{goods,221101,1}],50},{list,[{goods,221102,1}],50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532253) ->
	#ets_gift{ 
		id=532253, 
		name = <<"帮派福利袋">>,
		goods_id=532253, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{coin,5000,20000}],50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532254) ->
	#ets_gift{ 
		id=532254, 
		name = <<"攻城战胜利礼包 (532254)">>,
		goods_id=532254, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,531403,1},{goods,112214,10},{goods,112301,10},{goods,205201,1},{goods,206201,1},{goods,412104,12},{coin,100000,100000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532255) ->
	#ets_gift{ 
		id=532255, 
		name = <<"攻城战参与礼包 (532255)">>,
		goods_id=532255, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,531402,1},{goods,112214,5},{goods,112301,5},{goods,205101,1},{goods,206101,1},{goods,412104,8},{coin,50000,50000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532256) ->
	#ets_gift{ 
		id=532256, 
		name = <<"攻城战援助胜利礼包">>,
		goods_id=532256, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,531402,2},{goods,112214,6},{goods,112301,6},{goods,205201,1},{goods,206201,1},{coin,80000,80000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532257) ->
	#ets_gift{ 
		id=532257, 
		name = <<"攻城战援助参与礼包">>,
		goods_id=532257, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,531401,3},{goods,112214,3},{goods,112301,3},{goods,205101,1},{goods,206101,1},{goods,412104,4},{coin,40000,40000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532258) ->
	#ets_gift{ 
		id=532258, 
		name = <<"攻城战礼包3">>,
		goods_id=532258, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532259) ->
	#ets_gift{ 
		id=532259, 
		name = <<"攻城战礼包4">>,
		goods_id=532259, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532260) ->
	#ets_gift{ 
		id=532260, 
		name = <<"攻城战礼包5">>,
		goods_id=532260, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532261) ->
	#ets_gift{ 
		id=532261, 
		name = <<"攻城战礼包6">>,
		goods_id=532261, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532303) ->
	#ets_gift{ 
		id=532303, 
		name = <<"金风玉露时装">>,
		goods_id=532303, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{equip,[106014,106024,106034],0,0}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532304) ->
	#ets_gift{ 
		id=532304, 
		name = <<"七巧喜鹊挂饰">>,
		goods_id=532304, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{equip,[106213,106223,106233],0,0}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532305) ->
	#ets_gift{ 
		id=532305, 
		name = <<"XX礼盒">>,
		goods_id=532305, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,10000,10000},{goods,201101,1}],[{list,[{goods,624802,1}],50},{list,[{goods,624803,1}],30},{list,[{goods,624804,1}],20}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532306) ->
	#ets_gift{ 
		id=532306, 
		name = <<"XX礼盒">>,
		goods_id=532306, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532307) ->
	#ets_gift{ 
		id=532307, 
		name = <<"XX礼盒">>,
		goods_id=532307, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532401) ->
	#ets_gift{ 
		id=532401, 
		name = <<"元神榜第1名奖励礼包 (532401)">>,
		goods_id=532401, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,150000,150000},{goods,231201,50},{goods,221501,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532402) ->
	#ets_gift{ 
		id=532402, 
		name = <<"元神榜第2名奖励礼包 (532402)">>,
		goods_id=532402, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,100000,100000},{goods,231201,40},{goods,221501,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532403) ->
	#ets_gift{ 
		id=532403, 
		name = <<"元神榜第3名奖励礼包 (532403)">>,
		goods_id=532403, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,80000,80000},{goods,231201,30},{goods,221501,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532404) ->
	#ets_gift{ 
		id=532404, 
		name = <<"元神榜第4-6名奖励礼包 (532404)">>,
		goods_id=532404, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,50000,50000},{goods,231201,20},{goods,221501,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532405) ->
	#ets_gift{ 
		id=532405, 
		name = <<"元神榜第7-10名奖励礼包 (532405)">>,
		goods_id=532405, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,25000,25000},{goods,231201,10},{goods,221501,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532406) ->
	#ets_gift{ 
		id=532406, 
		name = <<"宠物等级榜第1名奖励礼包 (532406)">>,
		goods_id=532406, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,621302,50},{goods,212902,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532407) ->
	#ets_gift{ 
		id=532407, 
		name = <<"宠物等级榜第2名奖励礼包 (532407)">>,
		goods_id=532407, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,621302,40},{goods,212902,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532408) ->
	#ets_gift{ 
		id=532408, 
		name = <<"宠物等级榜第3名奖励礼包 (532408)">>,
		goods_id=532408, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,621302,30},{goods,212902,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532409) ->
	#ets_gift{ 
		id=532409, 
		name = <<"宠物等级榜第4-6名奖励礼包 (532409)">>,
		goods_id=532409, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,621302,20},{goods,212902,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532410) ->
	#ets_gift{ 
		id=532410, 
		name = <<"宠物等级榜第7-10名奖励礼包 (532410)">>,
		goods_id=532410, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,621302,10},{goods,212902,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532411) ->
	#ets_gift{ 
		id=532411, 
		name = <<"宠物战力榜第1名奖励礼包 (532411)">>,
		goods_id=532411, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,623202,20},{goods,623201,60}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532412) ->
	#ets_gift{ 
		id=532412, 
		name = <<"宠物战力榜第2名奖励礼包 (532412)">>,
		goods_id=532412, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,623202,15},{goods,623201,45}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532413) ->
	#ets_gift{ 
		id=532413, 
		name = <<"宠物战力榜第3名奖励礼包 (532413)">>,
		goods_id=532413, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,623202,10},{goods,623201,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532414) ->
	#ets_gift{ 
		id=532414, 
		name = <<"宠物战力榜第4-6名奖励礼包 (532414)">>,
		goods_id=532414, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,623202,5},{goods,623201,15}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532415) ->
	#ets_gift{ 
		id=532415, 
		name = <<"宠物战力榜第7-10名奖励礼包 (532415)">>,
		goods_id=532415, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,623202,2},{goods,623201,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532416) ->
	#ets_gift{ 
		id=532416, 
		name = <<"竞技场积分第1名奖励礼包 (532416)">>,
		goods_id=532416, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111403,1},{goods,121302,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532417) ->
	#ets_gift{ 
		id=532417, 
		name = <<"竞技场积分第2名奖励礼包 (532417)">>,
		goods_id=532417, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111402,3},{goods,121302,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532418) ->
	#ets_gift{ 
		id=532418, 
		name = <<"竞技场积分第3名奖励礼包 (532418)">>,
		goods_id=532418, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111402,2},{goods,121302,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532421) ->
	#ets_gift{ 
		id=532421, 
		name = <<"帮派战积分第1名奖励礼包 (532421)">>,
		goods_id=532421, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111423,1},{goods,121302,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532422) ->
	#ets_gift{ 
		id=532422, 
		name = <<"帮派战积分第2名奖励礼包 (532422)">>,
		goods_id=532422, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111422,3},{goods,121302,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532423) ->
	#ets_gift{ 
		id=532423, 
		name = <<"帮派战积分第3名奖励礼包 (532423)">>,
		goods_id=532423, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111422,2},{goods,121302,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532426) ->
	#ets_gift{ 
		id=532426, 
		name = <<"九重天霸主榜第21层奖励礼包 (532426)">>,
		goods_id=532426, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111413,1},{goods,121302,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532427) ->
	#ets_gift{ 
		id=532427, 
		name = <<"九重天霸主榜第16层奖励礼包 (532427)">>,
		goods_id=532427, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111412,3},{goods,121302,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532428) ->
	#ets_gift{ 
		id=532428, 
		name = <<"九重天霸主榜第10层奖励礼包 (532428)">>,
		goods_id=532428, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111412,2},{goods,121302,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532429) ->
	#ets_gift{ 
		id=532429, 
		name = <<"九重天霸主榜第5层奖励礼包 (532429)">>,
		goods_id=532429, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111412,1},{goods,121302,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532431) ->
	#ets_gift{ 
		id=532431, 
		name = <<"成就榜第1名奖励礼包 (532431)">>,
		goods_id=532431, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,50000,50000},{goods,111027,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532432) ->
	#ets_gift{ 
		id=532432, 
		name = <<"成就榜第2名奖励礼包 (532432)">>,
		goods_id=532432, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,50000,50000},{goods,111026,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532433) ->
	#ets_gift{ 
		id=532433, 
		name = <<"成就榜第3名奖励礼包 (532433)">>,
		goods_id=532433, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,50000,50000},{goods,111025,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532436) ->
	#ets_gift{ 
		id=532436, 
		name = <<"帮主礼包（532436）">>,
		goods_id=532436, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,231212,3},{goods,111023,5},{goods,205201,1},{goods,206201,1},{goods,621302,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532437) ->
	#ets_gift{ 
		id=532437, 
		name = <<"帮派成员礼包（532437）">>,
		goods_id=532437, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,231212,2},{goods,111022,2},{goods,205201,1},{goods,206201,1},{goods,621302,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532441) ->
	#ets_gift{ 
		id=532441, 
		name = <<"开服签到礼包（第一天）">>,
		goods_id=532441, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,20000,20000},{goods,111041,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532442) ->
	#ets_gift{ 
		id=532442, 
		name = <<"开服签到礼包（第二天）">>,
		goods_id=532442, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,40000,40000},{goods,631301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532443) ->
	#ets_gift{ 
		id=532443, 
		name = <<"开服签到礼包（第三天）">>,
		goods_id=532443, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,60000,60000},{goods,624201,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532444) ->
	#ets_gift{ 
		id=532444, 
		name = <<"开服签到礼包（第四天）">>,
		goods_id=532444, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,80000,80000},{goods,231201,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532445) ->
	#ets_gift{ 
		id=532445, 
		name = <<"开服签到礼包（第五天）">>,
		goods_id=532445, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,100000,100000},{goods,111041,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532446) ->
	#ets_gift{ 
		id=532446, 
		name = <<"开服签到礼包（第六天）">>,
		goods_id=532446, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,120000,120000},{goods,112104,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532447) ->
	#ets_gift{ 
		id=532447, 
		name = <<"开服签到礼包（第七天）">>,
		goods_id=532447, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,150000,150000},{goods,631301,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532451) ->
	#ets_gift{ 
		id=532451, 
		name = <<"紫水晶兑换套装礼包（2件）">>,
		goods_id=532451, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,250,250},{goods,121004,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532452) ->
	#ets_gift{ 
		id=532452, 
		name = <<"紫水晶兑换套装礼包（4件）">>,
		goods_id=532452, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,500,500},{goods,121004,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532453) ->
	#ets_gift{ 
		id=532453, 
		name = <<"紫水晶兑换套装礼包（6件）">>,
		goods_id=532453, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{silver,1000,1000},{goods,121004,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532461) ->
	#ets_gift{ 
		id=532461, 
		name = <<"开服签到礼包（第一天）充值">>,
		goods_id=532461, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,20000,20000},{goods,111041,2},{goods,111041,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532462) ->
	#ets_gift{ 
		id=532462, 
		name = <<"开服签到礼包（第二天）充值">>,
		goods_id=532462, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,40000,40000},{goods,631301,1},{goods,111041,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532463) ->
	#ets_gift{ 
		id=532463, 
		name = <<"开服签到礼包（第三天）充值">>,
		goods_id=532463, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,60000,60000},{goods,624201,3},{goods,111041,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532464) ->
	#ets_gift{ 
		id=532464, 
		name = <<"开服签到礼包（第四天）充值">>,
		goods_id=532464, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,80000,80000},{goods,231201,2},{goods,111041,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532465) ->
	#ets_gift{ 
		id=532465, 
		name = <<"开服签到礼包（第五天）充值">>,
		goods_id=532465, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,100000,100000},{goods,111041,10},{goods,111041,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532466) ->
	#ets_gift{ 
		id=532466, 
		name = <<"开服签到礼包（第六天）充值">>,
		goods_id=532466, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,120000,120000},{goods,112104,1},{goods,111041,12}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532467) ->
	#ets_gift{ 
		id=532467, 
		name = <<"开服签到礼包（第七天）充值">>,
		goods_id=532467, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,150000,150000},{goods,631301,2},{goods,111041,15}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532501) ->
	#ets_gift{ 
		id=532501, 
		name = <<"会员礼包">>,
		goods_id=532501, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,111002,3},{goods,111012,3},{goods,621302,10},{goods,624201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532502) ->
	#ets_gift{ 
		id=532502, 
		name = <<"黄金VIP会员礼包 (532502)">>,
		goods_id=532502, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611602,1},{goods,624801,2},{goods,624201,2},{goods,621302,10},{goods,111041,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532503) ->
	#ets_gift{ 
		id=532503, 
		name = <<"白金VIP会员礼包 (532503)">>,
		goods_id=532503, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611602,2},{goods,624801,4},{goods,624201,4},{goods,621302,10},{goods,111041,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532504) ->
	#ets_gift{ 
		id=532504, 
		name = <<"钻石VIP会员礼包 (532504)">>,
		goods_id=532504, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611603,1},{goods,624801,6},{goods,624201,6},{goods,621302,10},{goods,111041,15}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532505) ->
	#ets_gift{ 
		id=532505, 
		name = <<"黄金VIP礼包 (532505)">>,
		goods_id=532505, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221001,1},{goods,221201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532506) ->
	#ets_gift{ 
		id=532506, 
		name = <<"白金VIP礼包 (532506)">>,
		goods_id=532506, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221002,1},{goods,221202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532507) ->
	#ets_gift{ 
		id=532507, 
		name = <<"钻石VIP礼包 (532507)">>,
		goods_id=532507, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221003,1},{goods,221203,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532508) ->
	#ets_gift{ 
		id=532508, 
		name = <<"黄金VIP开服周礼包 (532508)">>,
		goods_id=532508, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,1},{coin,10000,10000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532509) ->
	#ets_gift{ 
		id=532509, 
		name = <<"白金VIP开服周礼包  (532509)">>,
		goods_id=532509, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,1},{coin,10000,10000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532510) ->
	#ets_gift{ 
		id=532510, 
		name = <<"钻石VIP开服周礼包 (532510)">>,
		goods_id=532510, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,1},{coin,10000,10000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532511) ->
	#ets_gift{ 
		id=532511, 
		name = <<"1级VIP周礼包">>,
		goods_id=532511, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,100000,100000},{goods,111041,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532512) ->
	#ets_gift{ 
		id=532512, 
		name = <<"2级VIP周礼包">>,
		goods_id=532512, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,150000,150000},{goods,111041,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532513) ->
	#ets_gift{ 
		id=532513, 
		name = <<"3级VIP周礼包">>,
		goods_id=532513, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,200000,200000},{goods,111041,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532514) ->
	#ets_gift{ 
		id=532514, 
		name = <<"4级VIP周礼包">>,
		goods_id=532514, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,4},{goods,121002,4},{goods,501204,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532515) ->
	#ets_gift{ 
		id=532515, 
		name = <<"5级VIP周礼包">>,
		goods_id=532515, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,5},{goods,121002,5},{goods,501204,25}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532516) ->
	#ets_gift{ 
		id=532516, 
		name = <<"6级VIP周礼包">>,
		goods_id=532516, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,6},{goods,121002,6},{goods,501204,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532517) ->
	#ets_gift{ 
		id=532517, 
		name = <<"7级VIP周礼包">>,
		goods_id=532517, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,7},{goods,121002,7},{goods,501204,35}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532518) ->
	#ets_gift{ 
		id=532518, 
		name = <<"8级VIP周礼包">>,
		goods_id=532518, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,8},{goods,121002,8},{goods,501204,40}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532519) ->
	#ets_gift{ 
		id=532519, 
		name = <<"9级VIP周礼包">>,
		goods_id=532519, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,9},{goods,121002,9},{goods,501204,45}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(532520) ->
	#ets_gift{ 
		id=532520, 
		name = <<"10级VIP周礼包">>,
		goods_id=532520, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,10},{goods,121002,10},{goods,501204,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533001) ->
	#ets_gift{ 
		id=533001, 
		name = <<"媒体卡1 (533001)">>,
		goods_id=533001, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,221101,5},{goods,205101,2},{goods,206101,1},{goods,211001,2},{goods,611601,3},{goods,621301,3},{goods,111041,5},{goods,612501,1},{goods,501202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533002) ->
	#ets_gift{ 
		id=533002, 
		name = <<"媒体卡2 (533002)">>,
		goods_id=533002, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,2},{goods,206101,1},{goods,611201,5},{goods,211001,2},{goods,611601,3},{goods,621301,3},{goods,111021,5},{goods,121001,5},{goods,624802,1},{goods,212901,2},{goods,121301,1},{goods,212301,1},{goods,212201,1},{goods,501202,1},{goods,501202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533003) ->
	#ets_gift{ 
		id=533003, 
		name = <<"媒体卡3 (533003)">>,
		goods_id=533003, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,2},{goods,206101,1},{goods,611201,5},{goods,211001,2},{goods,611601,3},{goods,621301,3},{goods,111021,5},{goods,121001,5},{goods,624802,1},{goods,624203,2},{goods,601501,1},{goods,212201,3},{goods,212101,1},{goods,501202,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533004) ->
	#ets_gift{ 
		id=533004, 
		name = <<"媒体卡4 (533004)">>,
		goods_id=533004, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,2},{goods,206101,1},{goods,611201,5},{goods,211001,2},{goods,611601,3},{goods,621301,3},{goods,111021,5},{goods,121001,5},{goods,624802,1},{goods,624203,2},{goods,212101,1},{goods,212301,2},{goods,501202,4},{goods,612501,1},{goods,121401,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533005) ->
	#ets_gift{ 
		id=533005, 
		name = <<"91wan媒体卡 (533005)">>,
		goods_id=533005, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,2},{goods,206101,1},{goods,611201,5},{goods,211001,2},{goods,611601,3},{goods,621301,3},{goods,624203,2},{goods,624802,1},{goods,212301,2},{goods,111021,5},{goods,121001,5},{goods,612501,1},{goods,501202,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533006) ->
	#ets_gift{ 
		id=533006, 
		name = <<"91wan特殊媒体卡 (533006)">>,
		goods_id=533006, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,221101,5},{goods,212201,2},{goods,212101,2},{goods,211001,2},{goods,212901,2},{goods,621301,3},{goods,112302,5},{goods,111021,5},{goods,121301,1},{goods,121401,1},{goods,611201,3},{goods,501202,3},{goods,501202,3},{goods,612501,1},{goods,205101,1},{goods,206101,1},{goods,611601,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533007) ->
	#ets_gift{ 
		id=533007, 
		name = <<"公民特权卡 (533007)">>,
		goods_id=533007, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,221101,1},{goods,205101,1},{goods,206101,1},{goods,611201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533008) ->
	#ets_gift{ 
		id=533008, 
		name = <<"贵族特权卡 (533008)">>,
		goods_id=533008, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611201,4},{goods,621301,1},{goods,624203,2},{goods,624802,1},{goods,111021,2},{goods,121001,2},{goods,501202,2},{goods,611601,3},{goods,501202,1},{goods,112302,2},{goods,211001,1},{goods,212301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533009) ->
	#ets_gift{ 
		id=533009, 
		name = <<"皇室特权卡 (533009)">>,
		goods_id=533009, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611201,3},{goods,621301,3},{goods,624203,1},{goods,624802,2},{goods,501202,2},{goods,212101,2},{goods,212201,2},{goods,212901,2},{goods,612501,2},{goods,121401,1},{goods,601501,1},{goods,121301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533010) ->
	#ets_gift{ 
		id=533010, 
		name = <<"幸运卡礼包 (533010)">>,
		goods_id=533010, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,221101,2},{goods,205101,1},{goods,206101,1},{goods,611201,6},{goods,624203,2},{goods,624802,1},{goods,111021,1},{goods,121001,1},{goods,501202,1},{goods,611601,1},{goods,112302,1},{goods,211001,1},{goods,212301,1},{goods,212901,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533011) ->
	#ets_gift{ 
		id=533011, 
		name = <<"360论坛祝福活动礼包 (533011)">>,
		goods_id=533011, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,20000,20000},{goods,111021,3},{goods,611201,10},{goods,501202,10},{goods,621301,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533012) ->
	#ets_gift{ 
		id=533012, 
		name = <<"媒体卡5 (533012)">>,
		goods_id=533012, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,2},{goods,206101,1},{goods,611201,5},{goods,211001,2},{goods,611601,3},{goods,621301,2},{goods,111021,5},{goods,121001,5},{goods,624802,2},{goods,212901,2},{goods,121301,1},{goods,212301,1},{goods,212201,1},{goods,501202,3},{goods,501202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533013) ->
	#ets_gift{ 
		id=533013, 
		name = <<"媒体卡6 (533013)">>,
		goods_id=533013, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,2},{goods,206101,1},{goods,611201,6},{goods,211001,2},{goods,611601,3},{goods,621301,5},{goods,111021,3},{goods,121001,3},{goods,624802,1},{goods,624203,2},{goods,601501,1},{goods,212201,3},{goods,212101,1},{goods,501202,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533014) ->
	#ets_gift{ 
		id=533014, 
		name = <<"媒体卡7 (533014)">>,
		goods_id=533014, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,5},{goods,205101,2},{goods,206101,1},{goods,611201,5},{goods,211001,2},{goods,611601,3},{goods,621301,3},{goods,111021,5},{goods,121001,5},{goods,624802,1},{goods,624203,2},{goods,212101,1},{goods,212301,2},{goods,501202,3},{goods,612501,1},{goods,121401,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533015) ->
	#ets_gift{ 
		id=533015, 
		name = <<"媒体卡8 (533015)">>,
		goods_id=533015, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,2},{goods,206101,1},{goods,611201,5},{goods,501202,2},{goods,211001,2},{goods,611601,5},{goods,621301,3},{goods,111021,5},{goods,121001,5},{goods,624802,1},{goods,212901,2},{goods,212101,1},{goods,212201,3},{goods,501202,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533016) ->
	#ets_gift{ 
		id=533016, 
		name = <<"通用媒体卡 (533016)">>,
		goods_id=533016, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,2},{goods,221101,5},{goods,206101,1},{goods,611201,5},{goods,501202,1},{goods,211001,1},{goods,611601,2},{goods,621301,4},{goods,111021,1},{goods,111022,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533017) ->
	#ets_gift{ 
		id=533017, 
		name = <<"正式版通用媒体卡 (533017)">>,
		goods_id=533017, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,1},{goods,206101,1},{goods,611201,3},{goods,211001,1},{goods,611601,3},{goods,621301,5},{goods,624203,2},{goods,624802,1},{goods,212301,2},{goods,111021,5},{goods,121001,1},{goods,612501,1},{goods,501202,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533018) ->
	#ets_gift{ 
		id=533018, 
		name = <<"200元宝礼包 (533018)">>,
		goods_id=533018, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,5},{goods,221101,3},{goods,205101,2},{goods,206101,1},{goods,611201,5},{goods,211001,1},{goods,611601,3},{goods,624203,2},{goods,624802,1},{goods,212301,5},{goods,111021,5},{goods,121001,1},{goods,612501,3},{goods,501202,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533019) ->
	#ets_gift{ 
		id=533019, 
		name = <<"醉西游媒体卡 (533019)">>,
		goods_id=533019, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611201,10},{goods,221101,10},{goods,112302,5},{goods,621301,5},{goods,611601,2},{goods,111021,2},{goods,111022,2},{goods,206101,1},{goods,211001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533020) ->
	#ets_gift{ 
		id=533020, 
		name = <<"签名礼包">>,
		goods_id=533020, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,20000,20000},{goods,111021,3},{goods,611201,10},{goods,611301,10},{goods,621301,10},{goods,205101,1},{goods,206101,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533021) ->
	#ets_gift{ 
		id=533021, 
		name = <<"幸运签名礼包">>,
		goods_id=533021, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,50000,50000},{goods,111022,5},{goods,112301,2},{goods,205101,1},{goods,206101,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533022) ->
	#ets_gift{ 
		id=533022, 
		name = <<"祝福礼包">>,
		goods_id=533022, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,20000,20000},{goods,111021,3},{goods,611201,10},{goods,611301,10},{goods,621301,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533023) ->
	#ets_gift{ 
		id=533023, 
		name = <<"祝福大礼包">>,
		goods_id=533023, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,50000,50000},{goods,111022,5},{goods,112301,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533024) ->
	#ets_gift{ 
		id=533024, 
		name = <<"勇往直前包">>,
		goods_id=533024, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,221103,3},{goods,112301,10},{goods,205201,3},{goods,206201,2},{goods,501202,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533025) ->
	#ets_gift{ 
		id=533025, 
		name = <<"經驗領先包">>,
		goods_id=533025, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,221103,3},{goods,211002,3},{goods,231201,10},{goods,501202,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533026) ->
	#ets_gift{ 
		id=533026, 
		name = <<"寵物加速包">>,
		goods_id=533026, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,212902,3},{goods,621302,10},{goods,624802,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533027) ->
	#ets_gift{ 
		id=533027, 
		name = <<"幸運強化包">>,
		goods_id=533027, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,111023,10},{goods,121002,3},{goods,624203,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533028) ->
	#ets_gift{ 
		id=533028, 
		name = <<"戰力大增包">>,
		goods_id=533028, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,221103,3},{goods,111023,5},{goods,112301,5},{goods,212902,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533029) ->
	#ets_gift{ 
		id=533029, 
		name = <<"裝備進化包">>,
		goods_id=533029, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112201,3},{goods,205201,2},{goods,206201,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533030) ->
	#ets_gift{ 
		id=533030, 
		name = <<"屬性洗煉包">>,
		goods_id=533030, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112704,1},{goods,112301,5},{goods,601501,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533031) ->
	#ets_gift{ 
		id=533031, 
		name = <<"FB按讚包">>,
		goods_id=533031, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,121002,3},{goods,611201,5},{goods,111021,15}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533032) ->
	#ets_gift{ 
		id=533032, 
		name = <<"VIP尊享礼包">>,
		goods_id=533032, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,121001,3},{goods,221101,20},{goods,112302,7},{goods,111023,3},{goods,611301,3},{goods,611601,10},{goods,612501,5},{goods,501202,5},{goods,205101,2},{goods,211001,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533033) ->
	#ets_gift{ 
		id=533033, 
		name = <<"生日祝福礼包">>,
		goods_id=533033, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,121001,5},{goods,221101,15},{goods,112302,10},{goods,111023,3},{goods,611301,3},{goods,611601,10},{goods,612501,3},{goods,501202,5},{goods,624203,2},{goods,211001,2},{goods,624802,2},{goods,212301,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533034) ->
	#ets_gift{ 
		id=533034, 
		name = <<"嬉遊玩樂包">>,
		goods_id=533034, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,221103,5},{goods,631401,1},{goods,112301,5},{goods,221501,40}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533035) ->
	#ets_gift{ 
		id=533035, 
		name = <<"VIP大礼包">>,
		goods_id=533035, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112301,5},{goods,221101,10},{goods,212902,1},{goods,231201,10},{goods,611301,3},{goods,211001,3},{goods,231212,5},{goods,621301,5},{goods,111021,10},{goods,111022,10},{goods,121001,5},{goods,624802,3},{goods,624203,3},{goods,601501,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533036) ->
	#ets_gift{ 
		id=533036, 
		name = <<"玩家体验礼包">>,
		goods_id=533036, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,623201,1},{goods,624202,1},{goods,624801,1},{goods,601501,2},{goods,112301,2},{goods,111025,1},{goods,121003,1},{goods,112201,2},{goods,112704,1},{goods,611602,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533037) ->
	#ets_gift{ 
		id=533037, 
		name = <<"4399生日祝福礼包">>,
		goods_id=533037, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,205301,5},{goods,211003,5},{goods,611602,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533038) ->
	#ets_gift{ 
		id=533038, 
		name = <<"4399完善资料礼包">>,
		goods_id=533038, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{coin,88888,88888},{goods,112301,10},{goods,601501,10},{goods,111025,5},{goods,611602,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533039) ->
	#ets_gift{ 
		id=533039, 
		name = <<"91wan参与奖">>,
		goods_id=533039, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,2},{goods,112301,2},{goods,611201,3},{goods,121301,1},{goods,621301,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533040) ->
	#ets_gift{ 
		id=533040, 
		name = <<"91wan优秀奖">>,
		goods_id=533040, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,3},{goods,112302,3},{goods,611201,5},{goods,121301,1},{goods,621301,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533041) ->
	#ets_gift{ 
		id=533041, 
		name = <<"VIP尊享礼包(通用)">>,
		goods_id=533041, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121001,3},{goods,221101,20},{goods,112302,7},{goods,111023,3},{goods,611301,3},{goods,611601,10},{goods,612501,5},{goods,501202,5},{goods,205101,2},{goods,211001,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533042) ->
	#ets_gift{ 
		id=533042, 
		name = <<"生日祝福礼包（通用）">>,
		goods_id=533042, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121001,5},{goods,221101,15},{goods,112302,10},{goods,111023,3},{goods,611301,3},{goods,611601,10},{goods,612501,3},{goods,501202,5},{goods,624203,2},{goods,211001,2},{goods,624802,2},{goods,212301,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533043) ->
	#ets_gift{ 
		id=533043, 
		name = <<"4399生日祝福礼包(02)">>,
		goods_id=533043, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,205301,5},{goods,211003,5},{goods,611602,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533044) ->
	#ets_gift{ 
		id=533044, 
		name = <<"4399完善资料礼包(02)">>,
		goods_id=533044, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,88888,88888},{goods,112301,10},{goods,601501,10},{goods,111025,5},{goods,611601,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533045) ->
	#ets_gift{ 
		id=533045, 
		name = <<"小小強化包">>,
		goods_id=533045, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221103,1},{goods,611201,5},{goods,111021,10},{goods,211001,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533046) ->
	#ets_gift{ 
		id=533046, 
		name = <<"成長體驗包">>,
		goods_id=533046, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221103,2},{goods,205201,1},{goods,231201,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533047) ->
	#ets_gift{ 
		id=533047, 
		name = <<"寶石提升包">>,
		goods_id=533047, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221103,5},{goods,205201,2},{goods,531401,7},{goods,231201,10},{goods,122601,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533048) ->
	#ets_gift{ 
		id=533048, 
		name = <<"至尊消耗大礼包">>,
		goods_id=533048, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,205201,1},{goods,206201,1},{goods,211002,1},{goods,212902,1},{coin,18888,18888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533049) ->
	#ets_gift{ 
		id=533049, 
		name = <<"至尊成长大礼包">>,
		goods_id=533049, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,121003,1},{goods,111023,1},{goods,601501,1},{goods,112301,1},{coin,18888,18888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533050) ->
	#ets_gift{ 
		id=533050, 
		name = <<"新功能体验礼包">>,
		goods_id=533050, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,523001,1},{coin,10000,10000},{goods,611601,9},{goods,521001,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533051) ->
	#ets_gift{ 
		id=533051, 
		name = <<"vip白银体验礼包">>,
		goods_id=533051, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,631301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533052) ->
	#ets_gift{ 
		id=533052, 
		name = <<"vip黄金体验礼包">>,
		goods_id=533052, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,631401,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533053) ->
	#ets_gift{ 
		id=533053, 
		name = <<"vip钻石体验礼包">>,
		goods_id=533053, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,631202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533054) ->
	#ets_gift{ 
		id=533054, 
		name = <<"神秘紫色仙宠礼包">>,
		goods_id=533054, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,621007,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533055) ->
	#ets_gift{ 
		id=533055, 
		name = <<"百花齐放礼包">>,
		goods_id=533055, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611606,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533056) ->
	#ets_gift{ 
		id=533056, 
		name = <<"醉西游快乐礼包">>,
		goods_id=533056, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611201,10},{goods,221101,10},{goods,112302,5},{goods,621301,5},{goods,611301,2},{goods,611601,3},{goods,111021,2},{goods,111022,2},{goods,206101,1},{goods,211001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533057) ->
	#ets_gift{ 
		id=533057, 
		name = <<"醉西游真情回馈礼包">>,
		goods_id=533057, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611201,3},{goods,221101,5},{goods,112302,5},{goods,621301,3},{goods,611301,2},{goods,611601,2},{goods,111021,5},{goods,206101,1},{goods,205101,1},{goods,211001,2},{goods,212201,2},{goods,212101,2},{goods,212901,1},{goods,121301,1},{goods,121401,3},{goods,501202,3},{goods,501202,1},{goods,612501,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533058) ->
	#ets_gift{ 
		id=533058, 
		name = <<"500一包">>,
		goods_id=533058, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,500,500}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533059) ->
	#ets_gift{ 
		id=533059, 
		name = <<"至尊消耗大礼包">>,
		goods_id=533059, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,205201,1},{goods,206201,1},{goods,621301,5},{goods,523001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533060) ->
	#ets_gift{ 
		id=533060, 
		name = <<"至尊成长大礼包">>,
		goods_id=533060, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,121003,1},{goods,111023,1},{goods,601501,1},{goods,112301,1},{goods,311201,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533061) ->
	#ets_gift{ 
		id=533061, 
		name = <<"新功能体验礼包">>,
		goods_id=533061, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,601401,2},{goods,602101,2},{goods,311201,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533062) ->
	#ets_gift{ 
		id=533062, 
		name = <<"vip白银体验礼包">>,
		goods_id=533062, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,631301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533063) ->
	#ets_gift{ 
		id=533063, 
		name = <<"vip黄金体验礼包">>,
		goods_id=533063, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,631401,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533064) ->
	#ets_gift{ 
		id=533064, 
		name = <<"vip钻石体验礼包">>,
		goods_id=533064, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,631202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533065) ->
	#ets_gift{ 
		id=533065, 
		name = <<"神秘紫色仙宠礼包">>,
		goods_id=533065, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,621007,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533066) ->
	#ets_gift{ 
		id=533066, 
		name = <<"百花齐放礼包">>,
		goods_id=533066, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611606,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533067) ->
	#ets_gift{ 
		id=533067, 
		name = <<"VIP体验礼包">>,
		goods_id=533067, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,221102,3},{goods,611603,1},{goods,111024,3},{goods,112301,3},{goods,222101,10},{goods,222001,10},{goods,611302,5},{goods,501202,5},{goods,612501,5},{goods,501202,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533068) ->
	#ets_gift{ 
		id=533068, 
		name = <<"VIP认证礼包">>,
		goods_id=533068, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,221102,3},{goods,534062,1},{goods,534070,1},{goods,222101,3},{goods,222001,3},{goods,611302,3},{goods,501202,5},{goods,612501,5},{goods,501202,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533069) ->
	#ets_gift{ 
		id=533069, 
		name = <<"100元超值礼包">>,
		goods_id=533069, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,121006,1},{goods,311101,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533070) ->
	#ets_gift{ 
		id=533070, 
		name = <<"188元超值礼包">>,
		goods_id=533070, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112104,1},{goods,522005,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533071) ->
	#ets_gift{ 
		id=533071, 
		name = <<"388元超值礼包">>,
		goods_id=533071, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112105,1},{goods,601602,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533072) ->
	#ets_gift{ 
		id=533072, 
		name = <<"588元超值礼包">>,
		goods_id=533072, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,231202,3},{goods,602111,10},{goods,625001,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533073) ->
	#ets_gift{ 
		id=533073, 
		name = <<"888元超值礼包">>,
		goods_id=533073, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,621613,1},{goods,622113,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533074) ->
	#ets_gift{ 
		id=533074, 
		name = <<"1888超值礼包">>,
		goods_id=533074, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,121010,1},{goods,621017,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533075) ->
	#ets_gift{ 
		id=533075, 
		name = <<"5888元超值礼包">>,
		goods_id=533075, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,111031,5},{goods,621614,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533076) ->
	#ets_gift{ 
		id=533076, 
		name = <<"一周好運包">>,
		goods_id=533076, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,631001,1},{goods,121003,3},{goods,205201,3},{goods,111024,3},{goods,221103,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533077) ->
	#ets_gift{ 
		id=533077, 
		name = <<"醉西游人气礼包">>,
		goods_id=533077, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,111023,1},{goods,121003,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1},{goods,621302,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533078) ->
	#ets_gift{ 
		id=533078, 
		name = <<"50元礼包">>,
		goods_id=533078, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,602031,1},{goods,111023,1},{goods,121003,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1},{goods,611602,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533079) ->
	#ets_gift{ 
		id=533079, 
		name = <<"100元礼包">>,
		goods_id=533079, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,602031,1},{goods,111024,1},{goods,121004,1},{goods,624202,4},{goods,624801,4},{goods,205201,2},{goods,206201,2},{goods,611602,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533080) ->
	#ets_gift{ 
		id=533080, 
		name = <<"200元礼包">>,
		goods_id=533080, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,602031,1},{goods,111025,1},{goods,121005,1},{goods,624202,6},{goods,624801,6},{goods,205201,3},{goods,206201,3},{goods,611603,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533081) ->
	#ets_gift{ 
		id=533081, 
		name = <<"300元礼包">>,
		goods_id=533081, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,602031,1},{goods,111026,1},{goods,121006,1},{goods,624202,8},{goods,624801,8},{goods,205201,4},{goods,206201,4},{goods,611603,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533082) ->
	#ets_gift{ 
		id=533082, 
		name = <<"500元礼包">>,
		goods_id=533082, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,602031,1},{goods,111027,1},{goods,121007,1},{goods,624202,10},{goods,624801,10},{goods,205201,5},{goods,206201,5},{goods,611603,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533101) ->
	#ets_gift{ 
		id=533101, 
		name = <<"手机礼包 (533101)">>,
		goods_id=533101, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,222001,2},{goods,612802,2},{goods,211001,3},{goods,111021,2},{goods,111022,2},{goods,111023,2},{goods,111024,2},{goods,611201,5},{goods,205101,2},{goods,206101,2},{goods,112301,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533102) ->
	#ets_gift{ 
		id=533102, 
		name = <<"邮箱礼包 (533102)">>,
		goods_id=533102, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,222001,2},{goods,621301,2},{goods,206101,2},{goods,111021,1},{goods,111022,1},{goods,111023,1},{goods,111024,1},{goods,611201,5},{goods,211001,2},{goods,112301,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533103) ->
	#ets_gift{ 
		id=533103, 
		name = <<"手机和邮箱礼包 (533103)">>,
		goods_id=533103, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,222001,2},{goods,211001,5},{goods,612802,2},{goods,111021,2},{goods,111022,2},{goods,111023,2},{goods,111024,2},{goods,611201,4},{goods,501202,5},{goods,601501,1},{goods,205101,2},{goods,206101,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533104) ->
	#ets_gift{ 
		id=533104, 
		name = <<"西游回馈礼包 (533104)">>,
		goods_id=533104, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,222001,2},{goods,211001,5},{goods,612802,2},{goods,111021,2},{goods,111022,2},{goods,111023,2},{goods,111024,2},{goods,611201,4},{goods,501202,5},{goods,601501,1},{goods,205101,2},{goods,206101,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533105) ->
	#ets_gift{ 
		id=533105, 
		name = <<"金秋迷你礼包">>,
		goods_id=533105, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221101,1},{goods,205101,1},{goods,206101,1},{goods,611201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533106) ->
	#ets_gift{ 
		id=533106, 
		name = <<"金秋小型礼包">>,
		goods_id=533106, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611201,2},{goods,611301,2},{goods,621301,1},{goods,624203,2},{goods,624802,1},{goods,111021,2},{goods,121001,2},{goods,501202,2},{goods,611601,3},{goods,501202,1},{goods,112302,2},{goods,211001,1},{goods,212301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533107) ->
	#ets_gift{ 
		id=533107, 
		name = <<"金秋中型礼包">>,
		goods_id=533107, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,1},{goods,206101,1},{goods,611201,3},{goods,611301,1},{goods,211001,1},{goods,611601,3},{goods,621301,5},{goods,624203,2},{goods,624802,1},{goods,212301,2},{goods,111021,5},{goods,121001,1},{goods,612501,1},{goods,501202,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533108) ->
	#ets_gift{ 
		id=533108, 
		name = <<"金秋大型礼包">>,
		goods_id=533108, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,2},{goods,206101,1},{goods,611201,5},{goods,611301,2},{goods,211001,2},{goods,611601,3},{goods,621301,2},{goods,111021,5},{goods,121001,5},{goods,624802,2},{goods,212901,2},{goods,121301,1},{goods,212301,1},{goods,212201,1},{goods,501202,1},{goods,501202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533109) ->
	#ets_gift{ 
		id=533109, 
		name = <<"金秋超级礼包">>,
		goods_id=533109, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,2},{goods,206101,1},{goods,611201,5},{goods,611301,2},{goods,211001,2},{goods,611601,3},{goods,621301,3},{goods,111021,5},{goods,121001,5},{goods,624802,1},{goods,624203,2},{goods,212101,1},{goods,212301,2},{goods,501202,2},{goods,612501,1},{goods,121401,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533110) ->
	#ets_gift{ 
		id=533110, 
		name = <<"至尊VIP礼包 (533110)">>,
		goods_id=533110, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611602,1},{goods,631001,1},{goods,231201,4},{goods,112301,10},{goods,601501,4},{goods,111021,10},{goods,121001,2},{goods,611301,2},{goods,531401,2},{goods,205101,5},{goods,206101,5},{goods,624203,5},{goods,624802,5},{goods,222002,1},{goods,411101,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533111) ->
	#ets_gift{ 
		id=533111, 
		name = <<"百服庆典首充礼包 (533111)">>,
		goods_id=533111, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,111026,1},{goods,602031,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533112) ->
	#ets_gift{ 
		id=533112, 
		name = <<"特殊推广礼包">>,
		goods_id=533112, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,221101,10},{goods,112301,5},{goods,601501,5},{goods,611301,3},{goods,121003,1},{goods,111023,1},{goods,211001,2},{goods,205101,2},{goods,206101,2},{goods,621301,10},{goods,624202,5},{goods,624801,5},{goods,222001,2},{goods,612802,2},{goods,612501,3},{goods,501202,5},{goods,231201,2},{goods,311101,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533113) ->
	#ets_gift{ 
		id=533113, 
		name = <<"多玩百服礼包">>,
		goods_id=533113, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,111027,1},{goods,602031,1},{goods,205201,1},{goods,206201,1},{goods,624202,5},{goods,624801,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533114) ->
	#ets_gift{ 
		id=533114, 
		name = <<"至尊成长大礼包">>,
		goods_id=533114, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,121003,3},{goods,111023,6},{goods,112301,6},{goods,612802,3},{goods,211002,3},{goods,621302,3},{goods,212902,3},{goods,624203,5},{goods,624802,5},{goods,205101,2},{goods,206101,2},{coin,18888,18888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533115) ->
	#ets_gift{ 
		id=533115, 
		name = <<"飞行大礼包">>,
		goods_id=533115, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,691101,10},{goods,311101,10},{goods,311201,10},{goods,211002,3},{goods,621302,3},{goods,212902,3},{goods,621302,2},{goods,212902,2},{coin,28888,28888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533116) ->
	#ets_gift{ 
		id=533116, 
		name = <<"时装大礼包">>,
		goods_id=533116, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611705,1},{goods,205101,2},{goods,206101,2},{goods,621302,3},{goods,212902,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533117) ->
	#ets_gift{ 
		id=533117, 
		name = <<"豆蛙牛仔宠物大礼包">>,
		goods_id=533117, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,621501,1},{goods,205101,2},{goods,206101,2},{goods,621302,3},{goods,212902,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533901) ->
	#ets_gift{ 
		id=533901, 
		name = <<"贵族特权卡">>,
		goods_id=533901, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,611201,4},{goods,621301,1},{goods,624203,2},{goods,624802,1},{goods,111021,2},{goods,121001,2},{goods,501202,2},{goods,611601,3},{goods,501202,1},{goods,112302,2},{goods,211001,1},{goods,212301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533902) ->
	#ets_gift{ 
		id=533902, 
		name = <<"通用媒体卡">>,
		goods_id=533902, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,2},{goods,221101,5},{goods,206101,1},{goods,611201,5},{goods,501202,1},{goods,211001,1},{goods,611601,2},{goods,621301,4},{goods,111021,1},{goods,111022,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(533903) ->
	#ets_gift{ 
		id=533903, 
		name = <<"正式版通用媒体卡">>,
		goods_id=533903, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112302,3},{goods,221101,3},{goods,205101,1},{goods,206101,1},{goods,611201,3},{goods,211001,1},{goods,611601,3},{goods,621301,5},{goods,624203,2},{goods,624802,1},{goods,212301,2},{goods,111021,5},{goods,121001,1},{goods,612501,1},{goods,501202,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534000) ->
	#ets_gift{ 
		id=534000, 
		name = <<"春暖花开连续登陆礼包">>,
		goods_id=534000, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,531403,1},{goods,111025,1},{goods,112301,5},{goods,601501,5},{goods,621301,5},{silver,25,25}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534001) ->
	#ets_gift{ 
		id=534001, 
		name = <<"爱情长跑第1名">>,
		goods_id=534001, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611603,1},{goods,111021,5},{goods,522001,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534002) ->
	#ets_gift{ 
		id=534002, 
		name = <<"爱情长跑第2-10名">>,
		goods_id=534002, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611602,1},{goods,111021,4},{goods,522001,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534003) ->
	#ets_gift{ 
		id=534003, 
		name = <<"爱情长跑第11-50名">>,
		goods_id=534003, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611601,9},{goods,111021,3},{goods,522001,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534004) ->
	#ets_gift{ 
		id=534004, 
		name = <<"爱情长跑第51-100名">>,
		goods_id=534004, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611601,9},{goods,111021,2},{goods,522001,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534005) ->
	#ets_gift{ 
		id=534005, 
		name = <<"爱情长跑参与奖">>,
		goods_id=534005, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611601,9},{goods,111021,1},{goods,522001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534006) ->
	#ets_gift{ 
		id=534006, 
		name = <<"XXX">>,
		goods_id=534006, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534007) ->
	#ets_gift{ 
		id=534007, 
		name = <<"七夕神秘礼盒">>,
		goods_id=534007, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601501,5},{goods,111002,5},{goods,111012,5},{goods,211002,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534008) ->
	#ets_gift{ 
		id=534008, 
		name = <<"七夕宝贝礼盒">>,
		goods_id=534008, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611903,1},{goods,611701,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534009) ->
	#ets_gift{ 
		id=534009, 
		name = <<"答题第1名">>,
		goods_id=534009, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601501,10},{goods,531403,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534010) ->
	#ets_gift{ 
		id=534010, 
		name = <<"答题第2名">>,
		goods_id=534010, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601501,5},{goods,531402,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534011) ->
	#ets_gift{ 
		id=534011, 
		name = <<"答题第3名">>,
		goods_id=534011, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601501,3},{goods,531402,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534012) ->
	#ets_gift{ 
		id=534012, 
		name = <<"答题第4-6名">>,
		goods_id=534012, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601501,2},{goods,531401,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534013) ->
	#ets_gift{ 
		id=534013, 
		name = <<"答题第7-10名">>,
		goods_id=534013, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601501,1},{goods,531401,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534014) ->
	#ets_gift{ 
		id=534014, 
		name = <<"铜币榜第1名">>,
		goods_id=534014, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,30},{goods,221215,20},{goods,111021,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534015) ->
	#ets_gift{ 
		id=534015, 
		name = <<"铜币榜第2-10名">>,
		goods_id=534015, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,20},{goods,221215,10},{goods,111021,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534016) ->
	#ets_gift{ 
		id=534016, 
		name = <<"铜币榜第11-50名">>,
		goods_id=534016, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,10},{goods,221215,5},{goods,111021,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534017) ->
	#ets_gift{ 
		id=534017, 
		name = <<"铜币榜第51-100名">>,
		goods_id=534017, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,5},{goods,221215,2},{goods,111021,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534018) ->
	#ets_gift{ 
		id=534018, 
		name = <<"淘宝榜第1名">>,
		goods_id=534018, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,30},{goods,221215,20},{goods,111021,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534019) ->
	#ets_gift{ 
		id=534019, 
		name = <<"淘宝榜第2-10名">>,
		goods_id=534019, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,20},{goods,221215,10},{goods,111021,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534020) ->
	#ets_gift{ 
		id=534020, 
		name = <<"淘宝榜第11-50名">>,
		goods_id=534020, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,10},{goods,221215,5},{goods,111021,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534021) ->
	#ets_gift{ 
		id=534021, 
		name = <<"淘宝榜第51-100名">>,
		goods_id=534021, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,5},{goods,221215,2},{goods,111021,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534022) ->
	#ets_gift{ 
		id=534022, 
		name = <<"经验榜第1名">>,
		goods_id=534022, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,30},{goods,221215,20},{goods,111021,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534023) ->
	#ets_gift{ 
		id=534023, 
		name = <<"经验榜第2-10名">>,
		goods_id=534023, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,20},{goods,221215,10},{goods,111021,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534024) ->
	#ets_gift{ 
		id=534024, 
		name = <<"经验榜第11-50名">>,
		goods_id=534024, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,10},{goods,221215,5},{goods,111021,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534025) ->
	#ets_gift{ 
		id=534025, 
		name = <<"经验榜第51-100名">>,
		goods_id=534025, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,5},{goods,221215,2},{goods,111021,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534026) ->
	#ets_gift{ 
		id=534026, 
		name = <<"历练榜第1名">>,
		goods_id=534026, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,30},{goods,221215,20},{goods,111021,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534027) ->
	#ets_gift{ 
		id=534027, 
		name = <<"历练榜第2-10名">>,
		goods_id=534027, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,20},{goods,221215,10},{goods,111021,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534028) ->
	#ets_gift{ 
		id=534028, 
		name = <<"历练榜第11-50名">>,
		goods_id=534028, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,10},{goods,221215,5},{goods,111021,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534029) ->
	#ets_gift{ 
		id=534029, 
		name = <<"历练榜第51-100名">>,
		goods_id=534029, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221203,5},{goods,221215,2},{goods,111021,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534030) ->
	#ets_gift{ 
		id=534030, 
		name = <<"洗炼回馈迷你礼包">>,
		goods_id=534030, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534031) ->
	#ets_gift{ 
		id=534031, 
		name = <<"洗炼回馈小型礼包">>,
		goods_id=534031, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112301,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534032) ->
	#ets_gift{ 
		id=534032, 
		name = <<"洗炼回馈中型礼包">>,
		goods_id=534032, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112301,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534033) ->
	#ets_gift{ 
		id=534033, 
		name = <<"洗炼回馈大型礼包">>,
		goods_id=534033, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112301,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534034) ->
	#ets_gift{ 
		id=534034, 
		name = <<"洗炼回馈巨型礼包">>,
		goods_id=534034, 
		get_way=2, 
		gift_rand=0, 
		gifts=[{goods,112301,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534035) ->
	#ets_gift{ 
		id=534035, 
		name = <<"消费回馈迷你礼包">>,
		goods_id=534035, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601601,1},{goods,121002,1},{goods,531402,1},{goods,613501,2},{coin,8888,8888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534036) ->
	#ets_gift{ 
		id=534036, 
		name = <<"消费回馈小型礼包">>,
		goods_id=534036, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601601,2},{goods,121003,1},{goods,531402,1},{goods,613501,5},{coin,18888,18888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534037) ->
	#ets_gift{ 
		id=534037, 
		name = <<"消费回馈中型礼包">>,
		goods_id=534037, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601601,3},{goods,121004,1},{goods,531403,1},{goods,613501,20},{coin,68888,68888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534038) ->
	#ets_gift{ 
		id=534038, 
		name = <<"消费回馈大型礼包">>,
		goods_id=534038, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601601,5},{goods,121005,1},{goods,531403,1},{goods,613501,30},{coin,188888,188888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534039) ->
	#ets_gift{ 
		id=534039, 
		name = <<"消费回馈巨型礼包">>,
		goods_id=534039, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601601,10},{goods,621101,2},{goods,611606,1},{goods,613501,50},{coin,288888,288888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534040) ->
	#ets_gift{ 
		id=534040, 
		name = <<"金秋礼盒">>,
		goods_id=534040, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,624801,1}],120},{list,[{goods,624202,1}],240},{list,[{goods,623201,1}],240},{list,[{goods,623202,1}],100},{list,[{goods,623203,1}],75},{list,[{goods,625001,1}],40}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534041) ->
	#ets_gift{ 
		id=534041, 
		name = <<"金秋大礼盒">>,
		goods_id=534041, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,534040,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534042) ->
	#ets_gift{ 
		id=534042, 
		name = <<"金秋豪华礼盒">>,
		goods_id=534042, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,534040,100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534043) ->
	#ets_gift{ 
		id=534043, 
		name = <<"腊月迷你礼包">>,
		goods_id=534043, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,1},{goods,602031,1},{goods,111025,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534044) ->
	#ets_gift{ 
		id=534044, 
		name = <<"腊月小型礼包">>,
		goods_id=534044, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,2},{goods,602031,1},{goods,111026,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534045) ->
	#ets_gift{ 
		id=534045, 
		name = <<"腊月中型礼包">>,
		goods_id=534045, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,3},{goods,602031,1},{goods,111027,1},{goods,624202,3},{goods,624801,3},{goods,205201,2},{goods,206201,2},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534046) ->
	#ets_gift{ 
		id=534046, 
		name = <<"腊月大型礼包">>,
		goods_id=534046, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,4},{goods,311506,1},{goods,602031,1},{goods,121005,1},{goods,624202,4},{goods,624801,4},{goods,205201,2},{goods,206201,2},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534047) ->
	#ets_gift{ 
		id=534047, 
		name = <<"腊月巨型礼包">>,
		goods_id=534047, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,5},{goods,311506,1},{goods,602031,1},{goods,121006,1},{goods,624202,5},{goods,624801,5},{goods,205201,3},{goods,206201,3},{goods,611609,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534048) ->
	#ets_gift{ 
		id=534048, 
		name = <<"元宵重复礼包">>,
		goods_id=534048, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,221002,3},{goods,221202,3},{goods,221102,3}],[{list,[{goods,112104,1}],90},{list,[{goods,112105,1}],60},{list,[{goods,111030,1}],20},{list,[{goods,623003,1}],150},{list,[{goods,623002,1}],200},{list,[{goods,623001,1}],250},{list,[{goods,212103,1}],150},{list,[{goods,212303,1}],200}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[112104, 112105, 111030],
		status=1
	};
get(534049) ->
	#ets_gift{ 
		id=534049, 
		name = <<"愚人节登陆礼包">>,
		goods_id=534049, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,612802,1},{goods,112201,1},{goods,112301,1},{goods,601501,1},{goods,621301,1},{silver,5,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534050) ->
	#ets_gift{ 
		id=534050, 
		name = <<"愚人节高级登陆礼包">>,
		goods_id=534050, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,612802,1},{goods,112202,1},{goods,112301,1},{goods,601501,1},{goods,621302,1},{silver,5,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534051) ->
	#ets_gift{ 
		id=534051, 
		name = <<"迷你三月感恩礼包">>,
		goods_id=534051, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121005,1},{goods,522001,5},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534052) ->
	#ets_gift{ 
		id=534052, 
		name = <<"魅力第一名礼包">>,
		goods_id=534052, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611701,1},{goods,611903,1},{goods,611606,1},{goods,221203,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534053) ->
	#ets_gift{ 
		id=534053, 
		name = <<"魅力第二名礼包">>,
		goods_id=534053, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611605,3},{goods,221203,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534054) ->
	#ets_gift{ 
		id=534054, 
		name = <<"魅力第三名礼包">>,
		goods_id=534054, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611605,2},{goods,221203,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534055) ->
	#ets_gift{ 
		id=534055, 
		name = <<"魅力第四至十名礼包">>,
		goods_id=534055, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611605,1},{goods,221203,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534056) ->
	#ets_gift{ 
		id=534056, 
		name = <<"活跃度回馈礼包">>,
		goods_id=534056, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,1},{goods,531401,1},{goods,206101,1},{goods,205101,1},{goods,621301,1},{coin,11111,11111}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534057) ->
	#ets_gift{ 
		id=534057, 
		name = <<"金秋硕果礼包（100）">>,
		goods_id=534057, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221006,3},{goods,521305,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534058) ->
	#ets_gift{ 
		id=534058, 
		name = <<"金秋硕果礼包（120）">>,
		goods_id=534058, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,221006,5},{goods,521305,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534059) ->
	#ets_gift{ 
		id=534059, 
		name = <<"普通婚宴礼包">>,
		goods_id=534059, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611601,9},{goods,205201,1},{goods,206201,1},{goods,621302,1},{coin,8888,8888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534060) ->
	#ets_gift{ 
		id=534060, 
		name = <<"热闹婚宴礼包">>,
		goods_id=534060, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611602,1},{goods,205201,1},{goods,206201,1},{goods,621302,3},{coin,16888,16888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534061) ->
	#ets_gift{ 
		id=534061, 
		name = <<"豪华婚宴礼包">>,
		goods_id=534061, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,602006,1},{goods,611603,1},{goods,205201,1},{goods,206201,1},{goods,621302,5},{coin,51888,51888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534062) ->
	#ets_gift{ 
		id=534062, 
		name = <<"强者崛起礼包">>,
		goods_id=534062, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121006,1},{goods,111026,1},{goods,531403,1},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534063) ->
	#ets_gift{ 
		id=534063, 
		name = <<"九重天霸主榜第22层奖励礼包">>,
		goods_id=534063, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534064) ->
	#ets_gift{ 
		id=534064, 
		name = <<"九重天霸主榜第24层奖励礼包">>,
		goods_id=534064, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534065) ->
	#ets_gift{ 
		id=534065, 
		name = <<"九重天霸主榜第26层奖励礼包">>,
		goods_id=534065, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534066) ->
	#ets_gift{ 
		id=534066, 
		name = <<"九重天霸主榜第28层奖励礼包">>,
		goods_id=534066, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534067) ->
	#ets_gift{ 
		id=534067, 
		name = <<"九重天霸主榜第30层奖励礼包">>,
		goods_id=534067, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534068) ->
	#ets_gift{ 
		id=534068, 
		name = <<"鲜花大礼盒">>,
		goods_id=534068, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611603,1},{goods,611603,1},{goods,611603,1},{goods,611603,1},{goods,611603,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534069) ->
	#ets_gift{ 
		id=534069, 
		name = <<"更新建议反馈礼包">>,
		goods_id=534069, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111025,1},{goods,121005,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1},{goods,621302,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534070) ->
	#ets_gift{ 
		id=534070, 
		name = <<"宠物技能礼包">>,
		goods_id=534070, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,623203,3},{goods,625001,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534071) ->
	#ets_gift{ 
		id=534071, 
		name = <<"幸福鲜花礼包">>,
		goods_id=534071, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611603,1},{goods,611603,1},{goods,611603,1},{goods,611603,1},{goods,611603,1},{goods,602031,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534072) ->
	#ets_gift{ 
		id=534072, 
		name = <<"腊月充值礼包">>,
		goods_id=534072, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,531422,1},{goods,111025,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534073) ->
	#ets_gift{ 
		id=534073, 
		name = <<"福到登陆礼包">>,
		goods_id=534073, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613601,1},{goods,112201,1},{goods,112301,1},{goods,601501,1},{goods,111021,1},{goods,531401,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534074) ->
	#ets_gift{ 
		id=534074, 
		name = <<"福到高级登陆礼包">>,
		goods_id=534074, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613601,1},{goods,112202,1},{goods,112301,1},{goods,601501,1},{goods,111021,1},{goods,531401,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534075) ->
	#ets_gift{ 
		id=534075, 
		name = <<"宠物幻化大礼包">>,
		goods_id=534075, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,621411,1},{goods,522007,1},{goods,602006,1},{goods,205201,1},{goods,206201,1},{coin,88888,88888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534076) ->
	#ets_gift{ 
		id=534076, 
		name = <<"愚人节充值礼包">>,
		goods_id=534076, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,522001,5},{goods,111026,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534077) ->
	#ets_gift{ 
		id=534077, 
		name = <<"回归大礼包">>,
		goods_id=534077, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112104,1},{goods,111025,2},{goods,121005,1},{goods,122505,1},{goods,112201,20},{goods,112301,10},{coin,500000,500000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534078) ->
	#ets_gift{ 
		id=534078, 
		name = <<"高级回归大礼包">>,
		goods_id=534078, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112105,1},{goods,111026,2},{goods,121006,1},{goods,122506,1},{goods,112202,10},{goods,112301,10},{coin,1000000,1000000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534079) ->
	#ets_gift{ 
		id=534079, 
		name = <<"幸福回归首充礼包">>,
		goods_id=534079, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,602031,1},{goods,602006,1},{goods,602007,1},{goods,111026,1},{goods,121006,1},{goods,205201,1},{goods,206201,3},{goods,621302,1},{goods,611603,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534080) ->
	#ets_gift{ 
		id=534080, 
		name = <<"业火红莲时装大礼包">>,
		goods_id=534080, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611809,1},{goods,613909,1},{goods,231202,1},{goods,205201,2},{goods,206201,2},{coin,128888,128888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534081) ->
	#ets_gift{ 
		id=534081, 
		name = <<"九天集字礼包">>,
		goods_id=534081, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,113530,1}],200},{list,[{goods,522001,1}],150},{list,[{goods,624203,1}],400},{list,[{goods,624802,1}],200},{list,[{goods,624202,1}],200},{list,[{goods,624801,1}],100},{list,[{goods,624201,1}],100},{list,[{goods,624803,1}],50}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534082) ->
	#ets_gift{ 
		id=534082, 
		name = <<"紫水晶大礼盒">>,
		goods_id=534082, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112104,1},{goods,112202,2},{goods,112705,2},{goods,205201,3},{goods,206201,3},{coin,99999,99999}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534083) ->
	#ets_gift{ 
		id=534083, 
		name = <<"橙水晶大礼盒">>,
		goods_id=534083, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112105,1},{goods,112203,1},{goods,112706,1},{goods,205201,3},{goods,206201,3},{coin,99999,99999}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534084) ->
	#ets_gift{ 
		id=534084, 
		name = <<"元宵迷你礼包">>,
		goods_id=534084, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,231202,1},{goods,602031,1},{goods,111025,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534085) ->
	#ets_gift{ 
		id=534085, 
		name = <<"元宵小型礼包">>,
		goods_id=534085, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611726,1},{goods,602031,2},{goods,111026,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534086) ->
	#ets_gift{ 
		id=534086, 
		name = <<"元宵中型礼包">>,
		goods_id=534086, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611924,1},{goods,602031,3},{goods,111027,1},{goods,624202,3},{goods,624801,3},{goods,205201,2},{goods,206201,2},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534087) ->
	#ets_gift{ 
		id=534087, 
		name = <<"元宵大型礼包">>,
		goods_id=534087, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613904,1},{goods,621101,1},{goods,121005,1},{goods,624202,4},{goods,624801,4},{goods,205201,2},{goods,206201,2},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534088) ->
	#ets_gift{ 
		id=534088, 
		name = <<"元宵巨型礼包">>,
		goods_id=534088, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,621415,1},{goods,621101,2},{goods,121006,1},{goods,624202,5},{goods,624801,5},{goods,205201,3},{goods,206201,3},{goods,611609,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534089) ->
	#ets_gift{ 
		id=534089, 
		name = <<"元宵超级礼包">>,
		goods_id=534089, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,30},{goods,621101,3},{goods,121007,1},{goods,624202,6},{goods,624801,6},{goods,205201,3},{goods,206201,3},{goods,611606,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534090) ->
	#ets_gift{ 
		id=534090, 
		name = <<"元神飞升礼包">>,
		goods_id=534090, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,231213,5},{goods,231202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534091) ->
	#ets_gift{ 
		id=534091, 
		name = <<"涅槃重生礼包">>,
		goods_id=534091, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,531403,1}],[{list,[{goods,111025,1}],80},{list,[{goods,111026,1}],40},{list,[{goods,121005,1}],10},{list,[{goods,121006,1}],5},{list,[{goods,112231,1}],30},{list,[{goods,112104,1}],20}]],
		bind=2,
		start_time=1360425601, 
		end_time=1404047984,
		tv_goods_id=[112104, 112105, 601701, 523505, 621101, 523502, 523503, 523504, 112104, 121005, 121006, 112231, 111030, 112104, 112105],
		status=1
	};
get(534092) ->
	#ets_gift{ 
		id=534092, 
		name = <<"时限礼包预留2">>,
		goods_id=534092, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,10,100},{goods,201101,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534093) ->
	#ets_gift{ 
		id=534093, 
		name = <<"时限礼包预留3">>,
		goods_id=534093, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,10,100},{goods,201101,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534094) ->
	#ets_gift{ 
		id=534094, 
		name = <<"无损符礼包">>,
		goods_id=534094, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,122505,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534095) ->
	#ets_gift{ 
		id=534095, 
		name = <<"新服宠物礼盒">>,
		goods_id=534095, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,221002,1},{goods,221202,1},{goods,221102,1}],[{list,[{goods,621411,1}],10},{list,[{goods,621408,1}],10},{list,[{goods,621407,1}],10},{list,[{goods,112201,1}],200},{list,[{goods,624203,1}],200},{list,[{goods,624802,1}],200}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534096) ->
	#ets_gift{ 
		id=534096, 
		name = <<"南天门激情礼包">>,
		goods_id=534096, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,112201,1}],100},{list,[{goods,112704,1}],20},{list,[{goods,624203,1}],100},{list,[{goods,624802,1}],100},{list,[{goods,523026,1}],100},{list,[{goods,523025,1}],100}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534097) ->
	#ets_gift{ 
		id=534097, 
		name = <<"圣诞惊喜礼包">>,
		goods_id=534097, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,531403,1}],150},{list,[{goods,111027,1}],150},{list,[{goods,311101,10}],200},{list,[{goods,601501,10}],200},{list,[{goods,611918,1}],15},{list,[{goods,611719,1}],10},{list,[{goods,621410,1}],5}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534098) ->
	#ets_gift{ 
		id=534098, 
		name = <<"圣诞雪花礼包">>,
		goods_id=534098, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611609,1},{goods,522008,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534099) ->
	#ets_gift{ 
		id=534099, 
		name = <<"圣诞挂饰礼包">>,
		goods_id=534099, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611918,1},{goods,522008,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534100) ->
	#ets_gift{ 
		id=534100, 
		name = <<"傲雪凌霜时装大礼包">>,
		goods_id=534100, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611731,1},{goods,613811,1},{goods,531403,1},{goods,206201,1},{goods,205201,1},{coin,88888,88888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534101) ->
	#ets_gift{ 
		id=534101, 
		name = <<"圣诞宠物礼包">>,
		goods_id=534101, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,621410,1},{goods,522008,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534102) ->
	#ets_gift{ 
		id=534102, 
		name = <<"小型迎春缤纷礼包">>,
		goods_id=534102, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611607,9},{goods,602031,1},{goods,121005,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534103) ->
	#ets_gift{ 
		id=534103, 
		name = <<"中型迎春缤纷礼包">>,
		goods_id=534103, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611608,1},{goods,602006,1},{goods,121005,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534104) ->
	#ets_gift{ 
		id=534104, 
		name = <<"大型迎春缤纷礼包">>,
		goods_id=534104, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611609,1},{goods,602007,1},{goods,121005,1},{goods,624202,3},{goods,624801,3},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534105) ->
	#ets_gift{ 
		id=534105, 
		name = <<"初级妖窟礼包">>,
		goods_id=534105, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,231202,1}],5},{list,[{goods,602031,1}],5},{list,[{goods,111024,1}],160},{list,[{goods,112201,1}],200},{list,[{goods,112704,1}],40},{list,[{goods,112231,1}],10},{list,[{goods,601601,1}],20},{list,[{goods,205201,1}],200}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534106) ->
	#ets_gift{ 
		id=534106, 
		name = <<"中级妖窟礼包">>,
		goods_id=534106, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,231202,1}],5},{list,[{goods,602031,1}],5},{list,[{goods,111025,1}],200},{list,[{goods,112202,1}],200},{list,[{goods,112704,1}],80},{list,[{goods,112705,1}],20},{list,[{goods,112231,1}],10},{list,[{goods,601601,1}],40},{list,[{goods,205201,1}],200}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534107) ->
	#ets_gift{ 
		id=534107, 
		name = <<"高级妖窟礼包">>,
		goods_id=534107, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,231202,1}],5},{list,[{goods,602031,1}],5},{list,[{goods,111026,1}],240},{list,[{goods,112203,1}],200},{list,[{goods,112705,1}],60},{list,[{goods,112706,1}],15},{list,[{goods,112231,1}],10},{list,[{goods,601601,1}],60},{list,[{goods,205201,1}],200}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534108) ->
	#ets_gift{ 
		id=534108, 
		name = <<"圣诞惊大喜礼包">>,
		goods_id=534108, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,534097,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534109) ->
	#ets_gift{ 
		id=534109, 
		name = <<"蟠桃会第1名">>,
		goods_id=534109, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,531403,1},{goods,522010,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534110) ->
	#ets_gift{ 
		id=534110, 
		name = <<"蟠桃会第2名">>,
		goods_id=534110, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,531402,2},{goods,522010,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534111) ->
	#ets_gift{ 
		id=534111, 
		name = <<"蟠桃会第3名">>,
		goods_id=534111, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,531402,1},{goods,522010,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534112) ->
	#ets_gift{ 
		id=534112, 
		name = <<"蟠桃会第4-6名">>,
		goods_id=534112, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,531401,2},{goods,522010,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534113) ->
	#ets_gift{ 
		id=534113, 
		name = <<"蟠桃会第7-10名">>,
		goods_id=534113, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,531401,1},{goods,522010,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534114) ->
	#ets_gift{ 
		id=534114, 
		name = <<"新年幸运礼包">>,
		goods_id=534114, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613601,5},{goods,624801,1},{goods,624202,1},{goods,206201,1},{goods,205201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534115) ->
	#ets_gift{ 
		id=534115, 
		name = <<"20000绑定铜币">>,
		goods_id=534115, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,20000,20000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534116) ->
	#ets_gift{ 
		id=534116, 
		name = <<"40000绑定铜币">>,
		goods_id=534116, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,40000,40000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534117) ->
	#ets_gift{ 
		id=534117, 
		name = <<"80000绑定铜币">>,
		goods_id=534117, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,80000,80000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534118) ->
	#ets_gift{ 
		id=534118, 
		name = <<"160000绑定铜币">>,
		goods_id=534118, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,160000,160000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534119) ->
	#ets_gift{ 
		id=534119, 
		name = <<"320000绑定铜币">>,
		goods_id=534119, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,320000,320000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534120) ->
	#ets_gift{ 
		id=534120, 
		name = <<"640000绑定铜币">>,
		goods_id=534120, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{coin,640000,640000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534121) ->
	#ets_gift{ 
		id=534121, 
		name = <<"1000积分礼包">>,
		goods_id=534121, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,112201,1},{goods,112704,1},{goods,221216,28},{goods,611607,3}],[{list,[{goods,601601,1}],10},{list,[{goods,112231,1}],5},{list,[{goods,205101,1}],15},{list,[{goods,206101,1}],15},{list,[{goods,112301,1}],25},{list,[{goods,112214,1}],10},{list,[{goods,601501,1}],20}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534122) ->
	#ets_gift{ 
		id=534122, 
		name = <<"1500积分礼包">>,
		goods_id=534122, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,112201,2},{goods,112704,1},{goods,221216,38},{goods,611607,6}],[{list,[{goods,601601,1}],10},{list,[{goods,112231,1}],5},{list,[{goods,205101,1}],15},{list,[{goods,206101,1}],15},{list,[{goods,112301,1}],25},{list,[{goods,112214,1}],10},{list,[{goods,601501,1}],20}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534123) ->
	#ets_gift{ 
		id=534123, 
		name = <<"2000积分礼包">>,
		goods_id=534123, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,112201,4},{goods,112704,2},{goods,221216,48},{goods,611607,9}],[{list,[{goods,601601,1}],10},{list,[{goods,112231,1}],5},{list,[{goods,205101,1}],15},{list,[{goods,206101,1}],15},{list,[{goods,112301,2}],25},{list,[{goods,112214,1}],10},{list,[{goods,601501,1}],20}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534124) ->
	#ets_gift{ 
		id=534124, 
		name = <<"3000积分礼包">>,
		goods_id=534124, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,112201,6},{goods,112704,3},{goods,221216,68},{goods,611607,15}],[{list,[{goods,601601,1}],10},{list,[{goods,112231,1}],5},{list,[{goods,205201,1}],15},{list,[{goods,206201,1}],15},{list,[{goods,112301,2}],25},{list,[{goods,112214,1}],10},{list,[{goods,601501,1}],20}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534125) ->
	#ets_gift{ 
		id=534125, 
		name = <<"4000积分礼包">>,
		goods_id=534125, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,112201,8},{goods,112704,4},{goods,221216,78},{goods,611607,24}],[{list,[{goods,601601,1}],10},{list,[{goods,112231,1}],5},{list,[{goods,205201,1}],15},{list,[{goods,206201,1}],15},{list,[{goods,112301,3}],25},{list,[{goods,112214,1}],10},{list,[{goods,601501,1}],20}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534126) ->
	#ets_gift{ 
		id=534126, 
		name = <<"5000积分礼包">>,
		goods_id=534126, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,112201,10},{goods,112704,6},{goods,221216,98},{goods,611607,39}],[{list,[{goods,601601,1}],10},{list,[{goods,112231,1}],5},{list,[{goods,205201,1}],15},{list,[{goods,206201,1}],15},{list,[{goods,112301,4}],25},{list,[{goods,112214,1}],10},{list,[{goods,601501,1}],20}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534127) ->
	#ets_gift{ 
		id=534127, 
		name = <<"欢喜迷你礼包">>,
		goods_id=534127, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112104,1},{goods,111025,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534128) ->
	#ets_gift{ 
		id=534128, 
		name = <<"欢喜小型礼包">>,
		goods_id=534128, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112105,1},{goods,602031,1},{goods,111026,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534129) ->
	#ets_gift{ 
		id=534129, 
		name = <<"金蛇至尊礼包">>,
		goods_id=534129, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,221002,3},{goods,221202,3},{goods,221102,3}],[{list,[{goods,112104,1}],100},{list,[{goods,112105,1}],40},{list,[{goods,111030,1}],30},{list,[{goods,311101,30}],280},{list,[{goods,601501,40}],270},{list,[{goods,691101,50}],280}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[112104, 112105, 601701, 523505, 621101, 523502, 523503, 523504, 112104, 121005, 121006, 112231, 111030, 112104, 112105],
		status=1
	};
get(534130) ->
	#ets_gift{ 
		id=534130, 
		name = <<"欢喜中型礼包">>,
		goods_id=534130, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611724,1},{goods,602031,2},{goods,111026,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534131) ->
	#ets_gift{ 
		id=534131, 
		name = <<"欢喜大型礼包">>,
		goods_id=534131, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611922,1},{goods,602031,3},{goods,111027,1},{goods,624202,3},{goods,624801,3},{goods,205201,2},{goods,206201,2},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534132) ->
	#ets_gift{ 
		id=534132, 
		name = <<"欢喜巨型礼包">>,
		goods_id=534132, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,621413,1},{goods,621101,1},{goods,111028,1},{goods,624202,4},{goods,624801,4},{goods,205201,2},{goods,206201,2},{goods,611609,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534133) ->
	#ets_gift{ 
		id=534133, 
		name = <<"欢喜超级礼包">>,
		goods_id=534133, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311507,1},{goods,621101,2},{goods,111029,1},{goods,624202,5},{goods,624801,5},{goods,205201,3},{goods,206201,3},{goods,611609,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534134) ->
	#ets_gift{ 
		id=534134, 
		name = <<"欢喜顶级礼包">>,
		goods_id=534134, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,30},{goods,621101,3},{goods,111030,1},{goods,624202,10},{goods,624801,10},{goods,205201,3},{goods,206201,3},{goods,611606,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534135) ->
	#ets_gift{ 
		id=534135, 
		name = <<"迎春登陆礼包">>,
		goods_id=534135, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,612802,1},{goods,112201,1},{goods,112301,1},{goods,601501,1},{goods,621301,1},{silver,5,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534136) ->
	#ets_gift{ 
		id=534136, 
		name = <<"迎春高级登陆礼包">>,
		goods_id=534136, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,612802,1},{goods,112202,1},{goods,112301,1},{goods,601501,1},{goods,621302,1},{silver,5,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534137) ->
	#ets_gift{ 
		id=534137, 
		name = <<"迎春连续登陆礼包">>,
		goods_id=534137, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,531403,1},{goods,111025,1},{goods,112301,5},{goods,601501,5},{goods,621301,5},{silver,25,25}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534138) ->
	#ets_gift{ 
		id=534138, 
		name = <<"宠物进阶礼包">>,
		goods_id=534138, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,624801,10},{goods,624202,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534139) ->
	#ets_gift{ 
		id=534139, 
		name = <<"元神飞升大礼包">>,
		goods_id=534139, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,231213,30},{goods,231202,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534140) ->
	#ets_gift{ 
		id=534140, 
		name = <<"九重天材料找回礼包（单人5层）">>,
		goods_id=534140, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,1},{goods,601701,1},{goods,112301,10},{goods,112302,3},{goods,612501,2},{goods,501202,2},{goods,501202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534141) ->
	#ets_gift{ 
		id=534141, 
		name = <<"九重天材料找回礼包（单人10层）">>,
		goods_id=534141, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,2},{goods,112704,1},{goods,601701,1},{goods,112301,19},{goods,112302,6},{goods,612501,3},{goods,501202,4},{goods,501202,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534142) ->
	#ets_gift{ 
		id=534142, 
		name = <<"九重天材料找回礼包（单人15层）">>,
		goods_id=534142, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,5},{goods,112704,3},{goods,601701,1},{goods,112301,28},{goods,112302,9},{goods,612501,5},{goods,501202,6},{goods,501202,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534143) ->
	#ets_gift{ 
		id=534143, 
		name = <<"九重天材料找回礼包（单人20层）">>,
		goods_id=534143, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,7},{goods,112704,4},{goods,601701,1},{goods,112301,37},{goods,112302,12},{goods,612501,7},{goods,501202,8},{goods,501202,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534144) ->
	#ets_gift{ 
		id=534144, 
		name = <<"九重天材料找回礼包（单人22层）">>,
		goods_id=534144, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,10},{goods,112704,6},{goods,601701,1},{goods,112301,40},{goods,112302,14},{goods,612501,8},{goods,501202,10},{goods,501202,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534145) ->
	#ets_gift{ 
		id=534145, 
		name = <<"九重天材料找回礼包（单人24层）">>,
		goods_id=534145, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,13},{goods,112704,8},{goods,601701,1},{goods,112301,43},{goods,112302,16},{goods,612501,9},{goods,501202,11},{goods,501202,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534146) ->
	#ets_gift{ 
		id=534146, 
		name = <<"九重天材料找回礼包（单人26层）">>,
		goods_id=534146, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,16},{goods,112704,10},{goods,601701,1},{goods,112301,46},{goods,112302,18},{goods,612501,10},{goods,501202,12},{goods,501202,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534147) ->
	#ets_gift{ 
		id=534147, 
		name = <<"九重天材料找回礼包（单人28层）">>,
		goods_id=534147, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,19},{goods,112704,12},{goods,601701,1},{goods,112301,48},{goods,112302,20},{goods,612501,11},{goods,501202,13},{goods,501202,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534148) ->
	#ets_gift{ 
		id=534148, 
		name = <<"九重天材料找回礼包（单人30层）">>,
		goods_id=534148, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,22},{goods,112704,14},{goods,601701,1},{goods,112301,51},{goods,112302,22},{goods,612501,12},{goods,501202,14},{goods,501202,7}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534149) ->
	#ets_gift{ 
		id=534149, 
		name = <<"九重天材料找回礼包（多人5层）">>,
		goods_id=534149, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,3},{goods,601701,1},{goods,112301,10},{goods,112302,3},{goods,612501,2},{goods,501202,2},{goods,501202,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534150) ->
	#ets_gift{ 
		id=534150, 
		name = <<"九重天材料找回礼包（多人10层）">>,
		goods_id=534150, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,5},{goods,112704,1},{goods,601701,1},{goods,112301,19},{goods,112302,6},{goods,612501,3},{goods,501202,4},{goods,501202,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534151) ->
	#ets_gift{ 
		id=534151, 
		name = <<"九重天材料找回礼包（多人15层）">>,
		goods_id=534151, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,8},{goods,112704,3},{goods,601701,1},{goods,112301,28},{goods,112302,9},{goods,612501,5},{goods,501202,6},{goods,501202,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534152) ->
	#ets_gift{ 
		id=534152, 
		name = <<"九重天材料找回礼包（多人20层）">>,
		goods_id=534152, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,11},{goods,112704,4},{goods,601701,1},{goods,112301,37},{goods,112302,12},{goods,612501,7},{goods,501202,8},{goods,501202,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534153) ->
	#ets_gift{ 
		id=534153, 
		name = <<"九重天材料找回礼包（多人22层）">>,
		goods_id=534153, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,14},{goods,112704,6},{goods,601701,1},{goods,112301,40},{goods,112302,14},{goods,612501,8},{goods,501202,10},{goods,501202,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534154) ->
	#ets_gift{ 
		id=534154, 
		name = <<"九重天材料找回礼包（多人24层）">>,
		goods_id=534154, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,17},{goods,112704,8},{goods,601701,1},{goods,112301,43},{goods,112302,16},{goods,612501,9},{goods,501202,11},{goods,501202,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534155) ->
	#ets_gift{ 
		id=534155, 
		name = <<"九重天材料找回礼包（多人26层）">>,
		goods_id=534155, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,20},{goods,112704,10},{goods,601701,1},{goods,112301,46},{goods,112302,18},{goods,612501,10},{goods,501202,12},{goods,501202,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534156) ->
	#ets_gift{ 
		id=534156, 
		name = <<"九重天材料找回礼包（多人28层）">>,
		goods_id=534156, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,23},{goods,112704,12},{goods,601701,1},{goods,112301,48},{goods,112302,20},{goods,612501,11},{goods,501202,13},{goods,501202,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534157) ->
	#ets_gift{ 
		id=534157, 
		name = <<"九重天材料找回礼包（多人30层）">>,
		goods_id=534157, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,25},{goods,112704,14},{goods,601701,1},{goods,112301,51},{goods,112302,22},{goods,612501,12},{goods,501202,14},{goods,501202,7}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534158) ->
	#ets_gift{ 
		id=534158, 
		name = <<"炼狱材料找回礼包（单人5层）">>,
		goods_id=534158, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,1},{goods,602101,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534159) ->
	#ets_gift{ 
		id=534159, 
		name = <<"炼狱材料找回礼包（单人10层）">>,
		goods_id=534159, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,2},{goods,602101,3},{goods,534168,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534160) ->
	#ets_gift{ 
		id=534160, 
		name = <<"炼狱材料找回礼包（单人15层）">>,
		goods_id=534160, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,3},{goods,602101,4},{goods,534168,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534161) ->
	#ets_gift{ 
		id=534161, 
		name = <<"炼狱材料找回礼包（单人20层）">>,
		goods_id=534161, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,4},{goods,602101,6},{goods,534168,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534162) ->
	#ets_gift{ 
		id=534162, 
		name = <<"炼狱材料找回礼包（单人25层）">>,
		goods_id=534162, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,5},{goods,602101,8},{goods,534168,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534163) ->
	#ets_gift{ 
		id=534163, 
		name = <<"炼狱材料找回礼包（单人30层）">>,
		goods_id=534163, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,6},{goods,602101,11},{goods,534168,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534164) ->
	#ets_gift{ 
		id=534164, 
		name = <<"炼狱材料找回礼包（单人35层）">>,
		goods_id=534164, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,7},{goods,602101,13},{goods,534168,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534165) ->
	#ets_gift{ 
		id=534165, 
		name = <<"炼狱材料找回礼包（单人40层）">>,
		goods_id=534165, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,8},{goods,602101,16},{goods,534168,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534166) ->
	#ets_gift{ 
		id=534166, 
		name = <<"炼狱材料找回礼包（单人45层）">>,
		goods_id=534166, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,9},{goods,602101,19},{goods,534168,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534167) ->
	#ets_gift{ 
		id=534167, 
		name = <<"炼狱材料找回礼包（单人50层）">>,
		goods_id=534167, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,10},{goods,602101,23},{goods,534168,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534168) ->
	#ets_gift{ 
		id=534168, 
		name = <<"单人炼狱随机礼包">>,
		goods_id=534168, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112201,1}],500},{list,[{goods,112704,1}],50},{list,[{goods,602111,1}],10},{list,[{goods,601601,1}],20},{list,[{goods,311201,1}],80},{list,[{goods,311101,1}],100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534169) ->
	#ets_gift{ 
		id=534169, 
		name = <<"炼狱材料找回礼包（多人5层）">>,
		goods_id=534169, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,1},{goods,602101,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534170) ->
	#ets_gift{ 
		id=534170, 
		name = <<"炼狱材料找回礼包（多人10层）">>,
		goods_id=534170, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,2},{goods,602101,4},{goods,534168,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534171) ->
	#ets_gift{ 
		id=534171, 
		name = <<"炼狱材料找回礼包（多人15层）">>,
		goods_id=534171, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,3},{goods,602101,5},{goods,534168,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534172) ->
	#ets_gift{ 
		id=534172, 
		name = <<"炼狱材料找回礼包（多人20层）">>,
		goods_id=534172, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,4},{goods,602101,7},{goods,534168,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534173) ->
	#ets_gift{ 
		id=534173, 
		name = <<"炼狱材料找回礼包（多人25层）">>,
		goods_id=534173, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,5},{goods,602101,9},{goods,534168,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534174) ->
	#ets_gift{ 
		id=534174, 
		name = <<"炼狱材料找回礼包（多人30层）">>,
		goods_id=534174, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,6},{goods,602101,12},{goods,534168,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534175) ->
	#ets_gift{ 
		id=534175, 
		name = <<"炼狱材料找回礼包（多人35层）">>,
		goods_id=534175, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,7},{goods,602101,14},{goods,534168,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534176) ->
	#ets_gift{ 
		id=534176, 
		name = <<"炼狱材料找回礼包（多人40层）">>,
		goods_id=534176, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,8},{goods,602101,17},{goods,534168,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534177) ->
	#ets_gift{ 
		id=534177, 
		name = <<"炼狱材料找回礼包（多人45层）">>,
		goods_id=534177, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,9},{goods,602101,20},{goods,534168,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534178) ->
	#ets_gift{ 
		id=534178, 
		name = <<"炼狱材料找回礼包（多人50层）">>,
		goods_id=534178, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,10},{goods,602101,24},{goods,534168,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534179) ->
	#ets_gift{ 
		id=534179, 
		name = <<"多人炼狱随机礼包">>,
		goods_id=534179, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,112201,1}],250},{list,[{goods,112704,1}],50},{list,[{goods,602111,1}],10},{list,[{goods,601601,1}],20},{list,[{goods,311201,1}],80},{list,[{goods,311101,1}],100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534180) ->
	#ets_gift{ 
		id=534180, 
		name = <<"累计榜第一名礼包">>,
		goods_id=534180, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,107003,1},{goods,611612,1},{goods,221203,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534181) ->
	#ets_gift{ 
		id=534181, 
		name = <<"累计榜第二至十名礼包">>,
		goods_id=534181, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,107002,1},{goods,611612,1},{goods,221203,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534182) ->
	#ets_gift{ 
		id=534182, 
		name = <<"累计榜第十一至五十名礼包">>,
		goods_id=534182, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,107001,1},{goods,611611,3},{goods,221203,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534183) ->
	#ets_gift{ 
		id=534183, 
		name = <<"累计榜第五十至一百名礼包">>,
		goods_id=534183, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611611,1},{goods,221203,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534184) ->
	#ets_gift{ 
		id=534184, 
		name = <<"幸运藏宝图礼包">>,
		goods_id=534184, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,613721,1}],50},{list,[{goods,613720,1}],50},{list,[{goods,613719,1}],50},{list,[{goods,613718,1}],50},{list,[{goods,613717,1}],50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[611609],
		status=1
	};
get(534185) ->
	#ets_gift{ 
		id=534185, 
		name = <<"感恩回馈礼盒">>,
		goods_id=534185, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,691101,3}],400},{list,[{goods,311101,2}],450},{list,[{goods,112304,1}],500},{list,[{goods,531421,1}],300},{list,[{goods,531422,1}],100},{list,[{goods,611605,1}],100},{list,[{goods,611606,1}],15},{list,[{goods,107001,1}],90}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[611606, 107001, 531422],
		status=1
	};
get(534186) ->
	#ets_gift{ 
		id=534186, 
		name = <<"日清榜第一名礼包">>,
		goods_id=534186, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611701,2},{goods,611903,2},{goods,611612,1},{goods,221203,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534187) ->
	#ets_gift{ 
		id=534187, 
		name = <<"日清榜第二至十名礼包">>,
		goods_id=534187, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611701,1},{goods,611903,1},{goods,611612,1},{goods,221203,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534188) ->
	#ets_gift{ 
		id=534188, 
		name = <<"日清榜第十一至五十名礼包">>,
		goods_id=534188, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611611,3},{goods,221203,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534189) ->
	#ets_gift{ 
		id=534189, 
		name = <<"日清榜第五十至一百名礼包">>,
		goods_id=534189, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611611,1},{goods,221203,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534190) ->
	#ets_gift{ 
		id=534190, 
		name = <<"南天门初级找回礼包">>,
		goods_id=534190, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,4},{goods,112704,1},{goods,532209,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534191) ->
	#ets_gift{ 
		id=534191, 
		name = <<"南天门中级找回礼包">>,
		goods_id=534191, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112201,4},{goods,112202,1},{goods,112704,1},{goods,532210,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534192) ->
	#ets_gift{ 
		id=534192, 
		name = <<"南天门高级找回礼包">>,
		goods_id=534192, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112202,5},{goods,112705,1},{goods,532211,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534193) ->
	#ets_gift{ 
		id=534193, 
		name = <<"新年登陆礼包">>,
		goods_id=534193, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,522012,1},{goods,522011,5},{goods,624203,1},{goods,624802,1},{goods,112301,1},{goods,601501,1},{goods,111021,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534194) ->
	#ets_gift{ 
		id=534194, 
		name = <<"情人节大礼包">>,
		goods_id=534194, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611608,1},{goods,522011,5},{goods,624203,1},{goods,624802,1},{goods,112301,1},{goods,601501,1},{goods,111021,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534195) ->
	#ets_gift{ 
		id=534195, 
		name = <<"新年累计登陆礼包">>,
		goods_id=534195, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,522011,10},{goods,521407,1},{goods,521406,1},{goods,624203,1},{goods,624802,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534196) ->
	#ets_gift{ 
		id=534196, 
		name = <<"新年回归礼包">>,
		goods_id=534196, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111025,1},{goods,112301,5},{goods,112214,5},{goods,621301,5},{silver,50,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534197) ->
	#ets_gift{ 
		id=534197, 
		name = <<"拜年利是">>,
		goods_id=534197, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,111021,1}],25},{list,[{goods,111022,1}],75},{list,[{goods,111023,1}],100},{list,[{goods,111024,1}],100},{list,[{goods,111025,1}],75},{list,[{goods,111026,1}],25}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534198) ->
	#ets_gift{ 
		id=534198, 
		name = <<"新春红包">>,
		goods_id=534198, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121005,1},{goods,602031,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534199) ->
	#ets_gift{ 
		id=534199, 
		name = <<"新春大红包">>,
		goods_id=534199, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121006,1},{goods,602031,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534200) ->
	#ets_gift{ 
		id=534200, 
		name = <<"蝴蝶与鱼找回礼包">>,
		goods_id=534200, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,522001,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534201) ->
	#ets_gift{ 
		id=534201, 
		name = <<"拜年惊喜礼包">>,
		goods_id=534201, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,20,20},{coin,5000,5000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534202) ->
	#ets_gift{ 
		id=534202, 
		name = <<"拜年压岁礼包">>,
		goods_id=534202, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,111021,1}],100},{list,[{goods,111022,1}],20},{list,[{goods,111023,1}],100},{list,[{goods,111024,1}],100},{list,[{goods,111025,1}],100},{list,[{goods,111026,1}],100}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534203) ->
	#ets_gift{ 
		id=534203, 
		name = <<"火眼金睛随机礼包">>,
		goods_id=534203, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,601601,1}],100},{list,[{goods,112231,1}],20},{list,[{goods,205101,1}],150},{list,[{goods,206101,1}],150},{list,[{goods,112301,1}],280},{list,[{goods,112214,1}],100},{list,[{goods,601501,1}],200}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534204) ->
	#ets_gift{ 
		id=534204, 
		name = <<"小型春节活动礼包">>,
		goods_id=534204, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,231202,1}],5},{list,[{goods,602031,1}],5},{list,[{goods,111024,1}],160},{list,[{goods,112201,1}],200},{list,[{goods,112704,1}],40},{list,[{goods,112231,1}],10},{list,[{goods,601601,1}],20},{list,[{goods,205201,1}],200}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534205) ->
	#ets_gift{ 
		id=534205, 
		name = <<"中型春节活动礼包">>,
		goods_id=534205, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,231202,1}],5},{list,[{goods,602031,1}],5},{list,[{goods,111025,1}],200},{list,[{goods,112202,1}],200},{list,[{goods,112704,1}],80},{list,[{goods,112705,1}],20},{list,[{goods,112231,1}],10},{list,[{goods,601601,1}],40},{list,[{goods,205201,1}],200}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534206) ->
	#ets_gift{ 
		id=534206, 
		name = <<"大型春节活动礼包">>,
		goods_id=534206, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,231202,1}],5},{list,[{goods,602031,1}],5},{list,[{goods,111026,1}],240},{list,[{goods,112203,1}],200},{list,[{goods,112705,1}],60},{list,[{goods,112706,1}],15},{list,[{goods,112231,1}],10},{list,[{goods,601601,1}],60},{list,[{goods,205201,1}],200}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534207) ->
	#ets_gift{ 
		id=534207, 
		name = <<"花开迷你礼包">>,
		goods_id=534207, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613813,1},{goods,522001,5},{goods,111025,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534208) ->
	#ets_gift{ 
		id=534208, 
		name = <<"花开小型礼包">>,
		goods_id=534208, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,614010,1},{goods,522001,10},{goods,111026,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534209) ->
	#ets_gift{ 
		id=534209, 
		name = <<"花开中型礼包">>,
		goods_id=534209, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611930,1},{goods,522001,20},{goods,111027,1},{goods,624202,3},{goods,624801,3},{goods,205201,2},{goods,206201,2},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534210) ->
	#ets_gift{ 
		id=534210, 
		name = <<"花开大型礼包">>,
		goods_id=534210, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611732,1},{goods,535543,5},{goods,621101,1},{goods,121005,1},{goods,624202,4},{goods,624801,4},{goods,205201,2},{goods,206201,2},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534211) ->
	#ets_gift{ 
		id=534211, 
		name = <<"花开巨型礼包">>,
		goods_id=534211, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613910,1},{goods,535543,10},{goods,621101,1},{goods,121006,1},{goods,624202,5},{goods,624801,5},{goods,205201,3},{goods,206201,3},{goods,611609,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534212) ->
	#ets_gift{ 
		id=534212, 
		name = <<"花开超级礼包">>,
		goods_id=534212, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611810,1},{goods,535543,20},{goods,621101,1},{goods,121007,1},{goods,624202,6},{goods,624801,6},{goods,205201,3},{goods,206201,3},{goods,611606,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534213) ->
	#ets_gift{ 
		id=534213, 
		name = <<"春风迷你礼包">>,
		goods_id=534213, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112104,1},{goods,231202,1},{goods,602031,1},{goods,111025,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534214) ->
	#ets_gift{ 
		id=534214, 
		name = <<"春风小型礼包">>,
		goods_id=534214, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,112105,1},{goods,231202,2},{goods,602031,2},{goods,111026,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534215) ->
	#ets_gift{ 
		id=534215, 
		name = <<"春风中型礼包">>,
		goods_id=534215, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111424,1},{goods,231202,3},{goods,602031,3},{goods,111027,1},{goods,624202,3},{goods,624801,3},{goods,205201,2},{goods,206201,2},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534216) ->
	#ets_gift{ 
		id=534216, 
		name = <<"春风大型礼包">>,
		goods_id=534216, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611916,1},{goods,621101,1},{goods,602031,4},{goods,111028,1},{goods,624202,4},{goods,624801,4},{goods,205201,2},{goods,206201,2},{goods,611609,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534217) ->
	#ets_gift{ 
		id=534217, 
		name = <<"春风巨型礼包">>,
		goods_id=534217, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611722,1},{goods,621101,2},{goods,602031,5},{goods,111029,1},{goods,624202,5},{goods,624801,5},{goods,205201,3},{goods,206201,3},{goods,611606,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534218) ->
	#ets_gift{ 
		id=534218, 
		name = <<"春风超级礼包">>,
		goods_id=534218, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311503,1},{goods,621101,3},{goods,602031,6},{goods,111030,1},{goods,624202,6},{goods,624801,6},{goods,205201,3},{goods,206201,3},{goods,611612,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534219) ->
	#ets_gift{ 
		id=534219, 
		name = <<"火眼金睛小礼包">>,
		goods_id=534219, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,601601,1}],100},{list,[{goods,112231,1}],20},{list,[{goods,205101,1}],150},{list,[{goods,206101,1}],150},{list,[{goods,112214,1}],100},{list,[{goods,601501,1}],200},{list,[{goods,112201,1}],260},{list,[{goods,112704,1}],20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534220) ->
	#ets_gift{ 
		id=534220, 
		name = <<"火眼金睛礼包">>,
		goods_id=534220, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,601601,1}],100},{list,[{goods,112231,1}],20},{list,[{goods,205101,1}],150},{list,[{goods,206101,1}],150},{list,[{goods,112214,1}],100},{list,[{goods,601501,1}],200},{list,[{goods,112202,1}],260},{list,[{goods,112705,1}],20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534221) ->
	#ets_gift{ 
		id=534221, 
		name = <<"火眼金睛大礼包">>,
		goods_id=534221, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,601601,1}],100},{list,[{goods,112231,1}],20},{list,[{goods,205101,1}],150},{list,[{goods,206101,1}],150},{list,[{goods,112214,1}],100},{list,[{goods,601501,1}],200},{list,[{goods,112203,1}],260},{list,[{goods,112706,1}],20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534222) ->
	#ets_gift{ 
		id=534222, 
		name = <<"宝石强袭礼盒">>,
		goods_id=534222, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,531403,1}],[{list,[{goods,111403,1}],20},{list,[{goods,111453,1}],40},{list,[{goods,111463,1}],40}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534223) ->
	#ets_gift{ 
		id=534223, 
		name = <<"低级元宵花灯礼包">>,
		goods_id=534223, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121002,1},{goods,531401,1},{goods,624202,1},{goods,624801,1},{goods,205101,1},{goods,206101,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534224) ->
	#ets_gift{ 
		id=534224, 
		name = <<"中级元宵花灯礼包">>,
		goods_id=534224, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121003,1},{goods,531402,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534225) ->
	#ets_gift{ 
		id=534225, 
		name = <<"高级元宵花灯礼包">>,
		goods_id=534225, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121004,1},{goods,531403,1},{goods,624202,3},{goods,624801,3},{goods,205301,1},{goods,206301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534226) ->
	#ets_gift{ 
		id=534226, 
		name = <<"元宵花灯祝福礼包">>,
		goods_id=534226, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,602031,1}],10},{list,[{goods,111022,1}],100},{list,[{goods,111023,1}],80},{list,[{goods,111024,1}],60},{list,[{goods,112231,1}],5},{list,[{goods,601601,1}],40},{list,[{goods,205101,1}],100},{list,[{goods,206101,1}],100},{list,[{goods,621301,1}],200},{list,[{goods,621302,1}],150}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[601601, 112231],
		status=1
	};
get(534227) ->
	#ets_gift{ 
		id=534227, 
		name = <<"元宵花灯祝福礼包">>,
		goods_id=534227, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,602031,1}],10},{list,[{goods,111022,1}],100},{list,[{goods,111023,1}],80},{list,[{goods,111024,1}],60},{list,[{goods,112231,1}],5},{list,[{goods,601601,1}],40},{list,[{goods,205101,1}],100},{list,[{goods,206101,1}],100},{list,[{goods,621301,1}],200},{list,[{goods,621302,1}],150}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[601601, 112231],
		status=1
	};
get(534228) ->
	#ets_gift{ 
		id=534228, 
		name = <<"元宵花灯祝福礼包">>,
		goods_id=534228, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,602031,1}],10},{list,[{goods,111022,1}],100},{list,[{goods,111023,1}],80},{list,[{goods,111024,1}],60},{list,[{goods,112231,1}],5},{list,[{goods,601601,1}],40},{list,[{goods,205101,1}],100},{list,[{goods,206101,1}],100},{list,[{goods,621301,1}],200},{list,[{goods,621302,1}],150}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[601601, 112231],
		status=1
	};
get(534229) ->
	#ets_gift{ 
		id=534229, 
		name = <<"吉祥如意幸运礼包">>,
		goods_id=534229, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,671002,1},{goods,112214,1},{goods,601501,1}],[{list,[{goods,611725,1}],10},{list,[{goods,671002,2}],330},{list,[{goods,112214,2}],330},{list,[{goods,601501,2}],330}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[611725],
		status=1
	};
get(534230) ->
	#ets_gift{ 
		id=534230, 
		name = <<"节节高升幸运礼包">>,
		goods_id=534230, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,671002,1},{goods,112214,1},{goods,601501,1}],[{list,[{goods,611923,1}],10},{list,[{goods,671002,4}],330},{list,[{goods,112214,4}],330},{list,[{goods,601501,4}],330}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[611923],
		status=1
	};
get(534231) ->
	#ets_gift{ 
		id=534231, 
		name = <<"招财猫足迹幸运礼包">>,
		goods_id=534231, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,671002,1},{goods,112214,1},{goods,601501,1}],[{list,[{goods,613901,1}],10},{list,[{goods,671002,6}],330},{list,[{goods,112214,6}],330},{list,[{goods,601501,6}],330}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[613901],
		status=1
	};
get(534232) ->
	#ets_gift{ 
		id=534232, 
		name = <<"中型三月感恩礼包">>,
		goods_id=534232, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121005,2},{goods,522001,10},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534233) ->
	#ets_gift{ 
		id=534233, 
		name = <<"大型三月感恩礼包">>,
		goods_id=534233, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121005,3},{goods,522001,15},{goods,624202,3},{goods,624801,3},{goods,205201,1},{goods,206201,1},{goods,611609,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534234) ->
	#ets_gift{ 
		id=534234, 
		name = <<"迎春大型礼包">>,
		goods_id=534234, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,611804,1},{goods,231202,3},{goods,602031,3},{goods,111027,1},{goods,624202,3},{goods,624801,3},{goods,205201,2},{goods,206201,2},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534235) ->
	#ets_gift{ 
		id=534235, 
		name = <<"迎春巨型礼包">>,
		goods_id=534235, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311509,1},{goods,621101,1},{goods,602031,4},{goods,111028,1},{goods,624202,4},{goods,624801,4},{goods,205201,2},{goods,206201,2},{goods,611609,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534236) ->
	#ets_gift{ 
		id=534236, 
		name = <<"迎春超级礼包">>,
		goods_id=534236, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111424,3},{goods,535543,20},{goods,621101,2},{goods,602031,5},{goods,111029,1},{goods,624202,5},{goods,624801,5},{goods,205201,3},{goods,206201,3},{goods,611609,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534237) ->
	#ets_gift{ 
		id=534237, 
		name = <<"迎春顶级礼包">>,
		goods_id=534237, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111404,3},{goods,535543,30},{goods,621101,3},{goods,602031,6},{goods,111030,1},{goods,624202,10},{goods,624801,10},{goods,205201,3},{goods,206201,3},{goods,611606,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534238) ->
	#ets_gift{ 
		id=534238, 
		name = <<"迎春重复礼包">>,
		goods_id=534238, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,221002,3},{goods,221202,3},{goods,221102,3}],[{list,[{goods,112104,1}],90},{list,[{goods,112105,1}],60},{list,[{goods,111030,1}],20},{list,[{goods,523026,1}],250},{list,[{goods,523025,1}],250},{list,[{goods,212103,1}],150},{list,[{goods,212303,1}],200}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[112104, 112105, 111030],
		status=1
	};
get(534239) ->
	#ets_gift{ 
		id=534239, 
		name = <<"花灯礼包">>,
		goods_id=534239, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,522013,1},{goods,522014,1},{goods,522015,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534240) ->
	#ets_gift{ 
		id=534240, 
		name = <<"喜迎春礼包">>,
		goods_id=534240, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,534242,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534241) ->
	#ets_gift{ 
		id=534241, 
		name = <<"喜迎春大礼包">>,
		goods_id=534241, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,534242,100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534242) ->
	#ets_gift{ 
		id=534242, 
		name = <<"喜迎春礼盒">>,
		goods_id=534242, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,311101,3}],450},{list,[{goods,691101,5}],500},{list,[{goods,112304,1}],400},{list,[{goods,601601,1}],100},{list,[{goods,601602,1}],40},{list,[{goods,111030,1}],10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[601602, 111030],
		status=1
	};
get(534243) ->
	#ets_gift{ 
		id=534243, 
		name = <<"迷你三月感恩礼包">>,
		goods_id=534243, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121005,1},{goods,602031,1},{goods,522013,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534244) ->
	#ets_gift{ 
		id=534244, 
		name = <<"中型三月感恩礼包">>,
		goods_id=534244, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121005,2},{goods,602031,2},{goods,522014,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534245) ->
	#ets_gift{ 
		id=534245, 
		name = <<"大型三月感恩礼包">>,
		goods_id=534245, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,121005,3},{goods,602031,3},{goods,522015,1},{goods,624202,3},{goods,624801,3},{goods,205201,1},{goods,206201,1},{goods,611609,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534246) ->
	#ets_gift{ 
		id=534246, 
		name = <<"拯救唐小僧礼包">>,
		goods_id=534246, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,523034,1}],[{list,[{goods,601601,1}],100},{list,[{goods,112231,1}],20},{list,[{goods,205101,1}],150},{list,[{goods,206101,1}],150},{list,[{goods,112214,1}],100},{list,[{goods,601501,1}],200},{list,[{goods,112202,1}],260},{list,[{goods,112705,1}],20}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534247) ->
	#ets_gift{ 
		id=534247, 
		name = <<"葫芦娃礼包">>,
		goods_id=534247, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,523027,1}],20},{list,[{goods,523028,1}],20},{list,[{goods,523029,1}],20},{list,[{goods,523030,1}],20},{list,[{goods,523031,1}],20},{list,[{goods,523032,1}],20},{list,[{goods,523033,1}],20},{list,[{goods,523036,1}],10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534248) ->
	#ets_gift{ 
		id=534248, 
		name = <<"女神大礼包">>,
		goods_id=534248, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{goods,611605,1}],[{list,[{goods,531421,1}],500},{list,[{goods,531403,1}],500},{list,[{goods,531422,1}],300},{list,[{goods,602006,1}],100},{list,[{goods,602007,1}],100},{list,[{goods,602031,1}],100}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[531403, 531422, 602006, 602007, 602031],
		status=1
	};
get(534249) ->
	#ets_gift{ 
		id=534249, 
		name = <<"斗战潜力第一礼包">>,
		goods_id=534249, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111030,1},{goods,602031,3},{goods,624202,15},{goods,624801,15},{goods,205201,3},{goods,206201,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534250) ->
	#ets_gift{ 
		id=534250, 
		name = <<"斗战潜力第二礼包">>,
		goods_id=534250, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111029,1},{goods,602031,2},{goods,624202,10},{goods,624801,10},{goods,205201,2},{goods,206201,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534251) ->
	#ets_gift{ 
		id=534251, 
		name = <<"斗战潜力第三礼包">>,
		goods_id=534251, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111028,1},{goods,602031,1},{goods,624202,5},{goods,624801,5},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534252) ->
	#ets_gift{ 
		id=534252, 
		name = <<"礼包252">>,
		goods_id=534252, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534253) ->
	#ets_gift{ 
		id=534253, 
		name = <<"斗战封神强者礼包">>,
		goods_id=534253, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,108100,1},{goods,531403,5},{goods,621101,1},{goods,611612,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534254) ->
	#ets_gift{ 
		id=534254, 
		name = <<"斗战封神荣耀礼包">>,
		goods_id=534254, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,108101,1},{goods,531403,10},{goods,621101,2},{goods,611612,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534255) ->
	#ets_gift{ 
		id=534255, 
		name = <<"斗战封神至尊礼包">>,
		goods_id=534255, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,108102,1},{goods,531403,15},{goods,621101,3},{goods,611612,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534256) ->
	#ets_gift{ 
		id=534256, 
		name = <<"礼包256">>,
		goods_id=534256, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534257) ->
	#ets_gift{ 
		id=534257, 
		name = <<"礼包257">>,
		goods_id=534257, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534258) ->
	#ets_gift{ 
		id=534258, 
		name = <<"变身派对礼包">>,
		goods_id=534258, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,523012,1}],75},{list,[{goods,523013,1}],25},{list,[{goods,523001,1}],25},{list,[{goods,523003,1}],75},{list,[{goods,523026,1}],75},{list,[{goods,523025,1}],25},{list,[{goods,523014,1}],75},{list,[{goods,523020,1}],25},{list,[{goods,523034,1}],75},{list,[{goods,523035,1}],25}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534259) ->
	#ets_gift{ 
		id=534259, 
		name = <<"感恩三月豪华大礼包">>,
		goods_id=534259, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111028,1},{goods,602007,1},{goods,602006,1},{goods,231202,1},{goods,624202,3},{goods,624801,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534260) ->
	#ets_gift{ 
		id=534260, 
		name = <<"奶嘴小熊宠物幻化大礼包">>,
		goods_id=534260, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,621416,1},{goods,621101,1},{goods,205301,3},{goods,206301,3},{goods,624202,5},{goods,624801,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534261) ->
	#ets_gift{ 
		id=534261, 
		name = <<"彩虹物语礼盒">>,
		goods_id=534261, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,113001,1}],20},{list,[{goods,113002,1}],20},{list,[{goods,113003,1}],20},{list,[{goods,113004,1}],20},{list,[{goods,113005,1}],20},{list,[{goods,113006,1}],20},{list,[{goods,113007,1}],20},{list,[{goods,113008,1}],20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534262) ->
	#ets_gift{ 
		id=534262, 
		name = <<"蝶舞星离礼盒">>,
		goods_id=534262, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,113021,1}],20},{list,[{goods,113022,1}],20},{list,[{goods,113023,1}],20},{list,[{goods,113024,1}],20},{list,[{goods,113025,1}],20},{list,[{goods,113026,1}],20},{list,[{goods,113027,1}],20},{list,[{goods,113028,1}],20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534263) ->
	#ets_gift{ 
		id=534263, 
		name = <<"元魂珠派对惊喜礼包">>,
		goods_id=534263, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,523012,1}],75},{list,[{goods,523013,1}],25},{list,[{goods,523001,1}],25},{list,[{goods,523003,1}],75},{list,[{goods,523026,1}],75},{list,[{goods,523025,1}],25},{list,[{goods,523014,1}],75},{list,[{goods,523020,1}],25},{list,[{goods,523034,1}],75},{list,[{goods,523035,1}],25}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534264) ->
	#ets_gift{ 
		id=534264, 
		name = <<"封测踩楼限量礼包">>,
		goods_id=534264, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{gold,888,888},{coin,100000,100000},{goods,112302,6},{goods,205101,2},{goods,206101,1},{goods,611201,10},{goods,611301,3},{goods,211001,2},{goods,611601,5},{goods,621301,3},{goods,111021,5},{goods,121001,5},{goods,624802,2},{goods,624203,2},{goods,601501,2},{goods,212201,3},{goods,212101,1},{goods,612501,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534265) ->
	#ets_gift{ 
		id=534265, 
		name = <<"封测踩楼幸运礼包">>,
		goods_id=534265, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{gold,688,688},{coin,68888,68888},{goods,611201,8},{goods,611301,2},{goods,621301,3},{goods,624203,2},{goods,624802,2},{goods,111021,2},{goods,121001,2},{goods,612501,5},{goods,611601,5},{goods,501202,3},{goods,112302,6},{goods,211001,1},{goods,212301,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534266) ->
	#ets_gift{ 
		id=534266, 
		name = <<"七夕签名惊喜大礼包">>,
		goods_id=534266, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{goods,205101,1},{goods,206101,1},{goods,611603,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[601602, 111030, 231202],
		status=1
	};
get(534267) ->
	#ets_gift{ 
		id=534267, 
		name = <<"媒体特权豪华礼包">>,
		goods_id=534267, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{gold,588,588},{coin,300000,300000},{goods,112302,5},{goods,205101,2},{goods,206101,1},{goods,611201,10},{goods,611301,5},{goods,211001,2},{goods,611601,5},{goods,621301,3},{goods,111021,5},{goods,121001,5},{goods,624802,1},{goods,212901,2},{goods,212101,1},{goods,212201,3},{goods,501202,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534268) ->
	#ets_gift{ 
		id=534268, 
		name = <<"礼包268">>,
		goods_id=534268, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,3000,3000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534269) ->
	#ets_gift{ 
		id=534269, 
		name = <<"礼包269">>,
		goods_id=534269, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534270) ->
	#ets_gift{ 
		id=534270, 
		name = <<"礼包270">>,
		goods_id=534270, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534271) ->
	#ets_gift{ 
		id=534271, 
		name = <<"礼包271">>,
		goods_id=534271, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534272) ->
	#ets_gift{ 
		id=534272, 
		name = <<"礼包272">>,
		goods_id=534272, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534273) ->
	#ets_gift{ 
		id=534273, 
		name = <<"礼包273">>,
		goods_id=534273, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534274) ->
	#ets_gift{ 
		id=534274, 
		name = <<"礼包274">>,
		goods_id=534274, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534275) ->
	#ets_gift{ 
		id=534275, 
		name = <<"礼包275">>,
		goods_id=534275, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534276) ->
	#ets_gift{ 
		id=534276, 
		name = <<"礼包276">>,
		goods_id=534276, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534277) ->
	#ets_gift{ 
		id=534277, 
		name = <<"礼包277">>,
		goods_id=534277, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534278) ->
	#ets_gift{ 
		id=534278, 
		name = <<"礼包278">>,
		goods_id=534278, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534279) ->
	#ets_gift{ 
		id=534279, 
		name = <<"礼包279">>,
		goods_id=534279, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534280) ->
	#ets_gift{ 
		id=534280, 
		name = <<"礼包280">>,
		goods_id=534280, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534281) ->
	#ets_gift{ 
		id=534281, 
		name = <<"礼包281">>,
		goods_id=534281, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534282) ->
	#ets_gift{ 
		id=534282, 
		name = <<"礼包282">>,
		goods_id=534282, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534283) ->
	#ets_gift{ 
		id=534283, 
		name = <<"礼包283">>,
		goods_id=534283, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534284) ->
	#ets_gift{ 
		id=534284, 
		name = <<"礼包284">>,
		goods_id=534284, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534285) ->
	#ets_gift{ 
		id=534285, 
		name = <<"礼包285">>,
		goods_id=534285, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534286) ->
	#ets_gift{ 
		id=534286, 
		name = <<"礼包286">>,
		goods_id=534286, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(534287) ->
	#ets_gift{ 
		id=534287, 
		name = <<"礼包287">>,
		goods_id=534287, 
		get_way=1, 
		gift_rand=0, 
		gifts=[],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535101) ->
	#ets_gift{ 
		id=535101, 
		name = <<"优惠礼包">>,
		goods_id=535101, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601501,5},{goods,111002,5},{goods,111012,5},{goods,211002,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535102) ->
	#ets_gift{ 
		id=535102, 
		name = <<"优惠礼包">>,
		goods_id=535102, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601501,5},{goods,624201,1},{goods,212903,1},{goods,211002,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535103) ->
	#ets_gift{ 
		id=535103, 
		name = <<"优惠大礼包 (535103)">>,
		goods_id=535103, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601501,5},{goods,624201,2},{goods,222001,2},{goods,222101,2},{goods,205201,1},{goods,206201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535111) ->
	#ets_gift{ 
		id=535111, 
		name = <<"高级回赠礼包">>,
		goods_id=535111, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,611601,1}],50},{list,[{goods,221001,1}],50},{list,[{goods,221201,1}],50},{list,[{goods,205101,1}],50},{list,[{goods,206101,1}],50},{list,[{goods,112201,1}],25},{list,[{goods,112704,1}],25}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535112) ->
	#ets_gift{ 
		id=535112, 
		name = <<"特级回赠礼包">>,
		goods_id=535112, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,611601,2}],50},{list,[{goods,221002,2}],50},{list,[{goods,221202,2}],50},{list,[{goods,205201,1}],50},{list,[{goods,206201,1}],50},{list,[{goods,112202,1}],25},{list,[{goods,112705,1}],25}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535113) ->
	#ets_gift{ 
		id=535113, 
		name = <<"超级回赠礼包">>,
		goods_id=535113, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,611601,3}],50},{list,[{goods,221003,3}],50},{list,[{goods,221203,3}],50},{list,[{goods,205301,1}],50},{list,[{goods,206301,1}],50},{list,[{goods,112203,1}],25},{list,[{goods,112706,1}],25}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535201) ->
	#ets_gift{ 
		id=535201, 
		name = <<"迷你充值礼包">>,
		goods_id=535201, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613601,5},{goods,602031,1},{goods,111025,1},{goods,624202,1},{goods,624801,1},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535202) ->
	#ets_gift{ 
		id=535202, 
		name = <<"小型充值礼包">>,
		goods_id=535202, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613601,10},{goods,602031,1},{goods,111026,1},{goods,624202,2},{goods,624801,2},{goods,205201,1},{goods,206201,1},{goods,611607,9}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535203) ->
	#ets_gift{ 
		id=535203, 
		name = <<"中型充值礼包">>,
		goods_id=535203, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613601,15},{goods,602031,1},{goods,111027,1},{goods,624202,3},{goods,624801,3},{goods,205201,2},{goods,206201,2},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535204) ->
	#ets_gift{ 
		id=535204, 
		name = <<"大型充值礼包">>,
		goods_id=535204, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613601,20},{goods,112104,1},{goods,621101,1},{goods,121005,1},{goods,624202,4},{goods,624801,4},{goods,205201,2},{goods,206201,2},{goods,611608,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535205) ->
	#ets_gift{ 
		id=535205, 
		name = <<"巨型充值礼包">>,
		goods_id=535205, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613601,25},{goods,112104,2},{goods,621101,2},{goods,121006,1},{goods,624202,5},{goods,624801,5},{goods,205201,3},{goods,206201,3},{goods,611609,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535206) ->
	#ets_gift{ 
		id=535206, 
		name = <<"超级充值礼包">>,
		goods_id=535206, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,613601,30},{goods,112104,3},{goods,621101,3},{goods,121007,1},{goods,624202,10},{goods,624801,10},{goods,205201,3},{goods,206201,3},{goods,611606,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535207) ->
	#ets_gift{ 
		id=535207, 
		name = <<"全服感恩回馈大礼包">>,
		goods_id=535207, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,3},{goods,121001,1},{goods,205201,1},{goods,206201,1},{goods,112301,1},{goods,601501,1},{goods,211001,1},{goods,621301,3}, {silver,88, 88},{coin,51888,51888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535208) ->
	#ets_gift{ 
		id=535208, 
		name = <<"合服战力比拼第1名礼包">>,
		goods_id=535208, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,1688, 1688}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535209) ->
	#ets_gift{ 
		id=535209, 
		name = <<"合服战力比拼第2-5名礼包">>,
		goods_id=535209, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,888, 888}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535210) ->
	#ets_gift{ 
		id=535210, 
		name = <<"合服战力比拼第6-10名礼包">>,
		goods_id=535210, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,488, 488}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535211) ->
	#ets_gift{ 
		id=535211, 
		name = <<"合服宠物比拼第1名礼包">>,
		goods_id=535211, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,624202,28},{goods,624801,28}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535212) ->
	#ets_gift{ 
		id=535212, 
		name = <<"合服宠物比拼第2-5名礼包">>,
		goods_id=535212, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,624202,18},{goods,624801,18}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535213) ->
	#ets_gift{ 
		id=535213, 
		name = <<"合服宠物比拼第6-10名礼包">>,
		goods_id=535213, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,624202,8},{goods,624801,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535214) ->
	#ets_gift{ 
		id=535214, 
		name = <<"合服竞技赛第1名礼包">>,
		goods_id=535214, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111403,1},{goods,121302,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535215) ->
	#ets_gift{ 
		id=535215, 
		name = <<"合服竞技赛第2-5名礼包">>,
		goods_id=535215, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111402,3},{goods,121302,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535216) ->
	#ets_gift{ 
		id=535216, 
		name = <<"合服竞技赛第6-10名礼包">>,
		goods_id=535216, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111402,2},{goods,121302,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535217) ->
	#ets_gift{ 
		id=535217, 
		name = <<"合服帮战第1名帮主礼包">>,
		goods_id=535217, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,231212,3},{goods,111023,3},{goods,205201,1},{goods,206201,1},{goods,621302,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535218) ->
	#ets_gift{ 
		id=535218, 
		name = <<"合服帮战积分第1名帮众礼包">>,
		goods_id=535218, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,2},{goods,205201,1},{goods,206201,1},{goods,621302,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535219) ->
	#ets_gift{ 
		id=535219, 
		name = <<"合服帮战积分第2-5名礼包">>,
		goods_id=535219, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111022,2},{goods,205201,1},{goods,206201,1},{goods,621302,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535220) ->
	#ets_gift{ 
		id=535220, 
		name = <<"合服帮战积分第6-10名礼包">>,
		goods_id=535220, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,2},{goods,205201,1},{goods,206201,1},{goods,621302,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535221) ->
	#ets_gift{ 
		id=535221, 
		name = <<"合服名人堂补偿礼包">>,
		goods_id=535221, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,2},{goods,205201,1},{goods,206201,1},{goods,621302,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535501) ->
	#ets_gift{ 
		id=535501, 
		name = <<"外围赛晋级礼包">>,
		goods_id=535501, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535502) ->
	#ets_gift{ 
		id=535502, 
		name = <<"外围赛鼓励礼包">>,
		goods_id=535502, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111023,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535503) ->
	#ets_gift{ 
		id=535503, 
		name = <<"小组赛晋级礼包">>,
		goods_id=535503, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111024,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535504) ->
	#ets_gift{ 
		id=535504, 
		name = <<"小组赛鼓励礼包">>,
		goods_id=535504, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111024,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535505) ->
	#ets_gift{ 
		id=535505, 
		name = <<"天榜冠军礼包">>,
		goods_id=535505, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111022,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535506) ->
	#ets_gift{ 
		id=535506, 
		name = <<"天榜亚军礼包">>,
		goods_id=535506, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111022,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535507) ->
	#ets_gift{ 
		id=535507, 
		name = <<"天榜3、4名礼包">>,
		goods_id=535507, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111022,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535508) ->
	#ets_gift{ 
		id=535508, 
		name = <<"天榜5-8名礼包">>,
		goods_id=535508, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111022,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535509) ->
	#ets_gift{ 
		id=535509, 
		name = <<"天榜9-16名礼包">>,
		goods_id=535509, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111022,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535510) ->
	#ets_gift{ 
		id=535510, 
		name = <<"天榜17-32名礼包">>,
		goods_id=535510, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111022,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535511) ->
	#ets_gift{ 
		id=535511, 
		name = <<"地榜冠军礼包">>,
		goods_id=535511, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535512) ->
	#ets_gift{ 
		id=535512, 
		name = <<"地榜亚军礼包">>,
		goods_id=535512, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,8}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535513) ->
	#ets_gift{ 
		id=535513, 
		name = <<"地榜3、4名礼包">>,
		goods_id=535513, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,6}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535514) ->
	#ets_gift{ 
		id=535514, 
		name = <<"地榜5-8名礼包">>,
		goods_id=535514, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,4}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535515) ->
	#ets_gift{ 
		id=535515, 
		name = <<"地榜9-16名礼包">>,
		goods_id=535515, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535516) ->
	#ets_gift{ 
		id=535516, 
		name = <<"地榜17-32名礼包">>,
		goods_id=535516, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,111021,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535517) ->
	#ets_gift{ 
		id=535517, 
		name = <<"1V1竞技冠军礼包">>,
		goods_id=535517, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,5},{goods,311201,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535518) ->
	#ets_gift{ 
		id=535518, 
		name = <<"1V1竞技亚军礼包">>,
		goods_id=535518, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,3},{goods,311201,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535519) ->
	#ets_gift{ 
		id=535519, 
		name = <<"1V1竞技3、4名礼包">>,
		goods_id=535519, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,2},{goods,311201,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535520) ->
	#ets_gift{ 
		id=535520, 
		name = <<"1V1竞技5-32名礼包">>,
		goods_id=535520, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,601401,1},{goods,311201,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535521) ->
	#ets_gift{ 
		id=535521, 
		name = <<"1V1竞技参与奖">>,
		goods_id=535521, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535522) ->
	#ets_gift{ 
		id=535522, 
		name = <<"1V1竞技参与奖">>,
		goods_id=535522, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535523) ->
	#ets_gift{ 
		id=535523, 
		name = <<"1V1竞技参与奖">>,
		goods_id=535523, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535524) ->
	#ets_gift{ 
		id=535524, 
		name = <<"1V1日积分第1名奖励">>,
		goods_id=535524, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,602101,5},{goods,311201,10},{goods,523501,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535525) ->
	#ets_gift{ 
		id=535525, 
		name = <<"1V1日积分第2-10名奖励">>,
		goods_id=535525, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,602101,3},{goods,311201,5},{goods,523501,15}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535526) ->
	#ets_gift{ 
		id=535526, 
		name = <<"1V1日积分第11-50名奖励">>,
		goods_id=535526, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,602101,2},{goods,311201,3},{goods,523501,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535527) ->
	#ets_gift{ 
		id=535527, 
		name = <<"1V1日积分第51-100名奖励">>,
		goods_id=535527, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,602101,1},{goods,311201,2},{goods,523501,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535528) ->
	#ets_gift{ 
		id=535528, 
		name = <<"预留">>,
		goods_id=535528, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311201,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535529) ->
	#ets_gift{ 
		id=535529, 
		name = <<"预留">>,
		goods_id=535529, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311201,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535530) ->
	#ets_gift{ 
		id=535530, 
		name = <<"1V1周积分第1名奖励">>,
		goods_id=535530, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,10},{goods,523501,100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535531) ->
	#ets_gift{ 
		id=535531, 
		name = <<"1V1周积分第2-4名奖励">>,
		goods_id=535531, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,6},{goods,523501,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535532) ->
	#ets_gift{ 
		id=535532, 
		name = <<"1V1周积分第5-10名奖励">>,
		goods_id=535532, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,5},{goods,523501,40}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535533) ->
	#ets_gift{ 
		id=535533, 
		name = <<"1V1周积分第11-20名奖励">>,
		goods_id=535533, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,4},{goods,523501,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535534) ->
	#ets_gift{ 
		id=535534, 
		name = <<"1V1周积分第21-50名奖励">>,
		goods_id=535534, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,3},{goods,523501,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535535) ->
	#ets_gift{ 
		id=535535, 
		name = <<"1V1周积分第51-100名奖励">>,
		goods_id=535535, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,2},{goods,523501,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535536) ->
	#ets_gift{ 
		id=535536, 
		name = <<"1V1周排行达标奖">>,
		goods_id=535536, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535542) ->
	#ets_gift{ 
		id=535542, 
		name = <<"1V1竞技参与礼包">>,
		goods_id=535542, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311101,1},{goods,311201,2},{goods,523501,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535543) ->
	#ets_gift{ 
		id=535543, 
		name = <<"斗神宝箱">>,
		goods_id=535543, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,523502,1}],300},{list,[{goods,523503,1}],300},{list,[{goods,523504,1}],300},{list,[{goods,612102,1}],200},{list,[{goods,621101,1}],50},{list,[{goods,311201,1}],900},{list,[{goods,205301,1}],1000},{list,[{goods,206301,1}],1000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[112104, 112105, 601701, 523505, 621101, 523502, 523503, 523504, 112104, 121005, 121006, 112231, 111030, 112104, 112105],
		status=1
	};
get(535550) ->
	#ets_gift{ 
		id=535550, 
		name = <<"3V3周积分第1名奖励">>,
		goods_id=535550, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,10},{goods,523501,100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535551) ->
	#ets_gift{ 
		id=535551, 
		name = <<"3V3周积分第2-4名奖励">>,
		goods_id=535551, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,6},{goods,523501,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535552) ->
	#ets_gift{ 
		id=535552, 
		name = <<"3V3周积分第5-10名奖励">>,
		goods_id=535552, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,5},{goods,523501,40}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535553) ->
	#ets_gift{ 
		id=535553, 
		name = <<"3V3周积分第11-20名奖励">>,
		goods_id=535553, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,4},{goods,523501,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535554) ->
	#ets_gift{ 
		id=535554, 
		name = <<"3V3周积分第21-50名奖励">>,
		goods_id=535554, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,3},{goods,523501,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535555) ->
	#ets_gift{ 
		id=535555, 
		name = <<"3V3周积分第51-100名奖励">>,
		goods_id=535555, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,2},{goods,523501,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535556) ->
	#ets_gift{ 
		id=535556, 
		name = <<"3V3达标奖励">>,
		goods_id=535556, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535570) ->
	#ets_gift{ 
		id=535570, 
		name = <<"3V3积分榜第1名奖励">>,
		goods_id=535570, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,2},{goods,523501,200}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535571) ->
	#ets_gift{ 
		id=535571, 
		name = <<"3V3积分榜第2-10名奖励">>,
		goods_id=535571, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,1},{goods,523501,100}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535572) ->
	#ets_gift{ 
		id=535572, 
		name = <<"3V3积分榜第11-50名奖励">>,
		goods_id=535572, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535543,1},{goods,523501,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535573) ->
	#ets_gift{ 
		id=535573, 
		name = <<"3V3积分榜第51-100名奖励">>,
		goods_id=535573, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523501,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535574) ->
	#ets_gift{ 
		id=535574, 
		name = <<"3V3积分榜100名以外奖励">>,
		goods_id=535574, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523501,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535601) ->
	#ets_gift{ 
		id=535601, 
		name = <<"海选参与礼包">>,
		goods_id=535601, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,3},{goods,523501,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535602) ->
	#ets_gift{ 
		id=535602, 
		name = <<"小组第1名礼包">>,
		goods_id=535602, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,108},{goods,523501,100},{goods,112214,30},{goods,601501,15},{silver,200,200},{coin,100000,100000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535603) ->
	#ets_gift{ 
		id=535603, 
		name = <<"小组第2-4名礼包">>,
		goods_id=535603, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,84},{goods,523501,80},{goods,112214,20},{goods,601501,10},{silver,120,120},{coin,60000,60000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535604) ->
	#ets_gift{ 
		id=535604, 
		name = <<"小组第5-10名礼包">>,
		goods_id=535604, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,60},{goods,523501,60},{goods,112214,15},{goods,601501,5},{silver,60,60},{coin,30000,30000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535605) ->
	#ets_gift{ 
		id=535605, 
		name = <<"小组第11-20名礼包">>,
		goods_id=535605, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,48},{goods,523501,50},{goods,112214,10},{coin,20000,20000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535606) ->
	#ets_gift{ 
		id=535606, 
		name = <<"小组第21-40名礼包">>,
		goods_id=535606, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,36},{goods,523501,40},{goods,112214,5},{coin,10000,10000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535607) ->
	#ets_gift{ 
		id=535607, 
		name = <<"复活赛参与礼包">>,
		goods_id=535607, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523501,30}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535608) ->
	#ets_gift{ 
		id=535608, 
		name = <<"排位赛第1名礼包">>,
		goods_id=535608, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,228},{goods,523501,500},{goods,611730,1},{goods,108024,1},{goods,108054,1},{goods,108084,1},{goods,112214,100},{goods,601501,50},{silver,1000,1000},{coin,500000,500000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535609) ->
	#ets_gift{ 
		id=535609, 
		name = <<"排位赛第2-3名礼包">>,
		goods_id=535609, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,192},{goods,523501,450},{goods,108023,1},{goods,108053,1},{goods,108083,1},{goods,112214,80},{goods,601501,40},{silver,600,600},{coin,300000,300000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535610) ->
	#ets_gift{ 
		id=535610, 
		name = <<"排位赛第4-10名礼包">>,
		goods_id=535610, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,168},{goods,523501,400},{goods,108022,1},{goods,108052,1},{goods,108082,1},{goods,112214,70},{goods,601501,35},{silver,400,400},{coin,200000,200000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535611) ->
	#ets_gift{ 
		id=535611, 
		name = <<"排位赛第11-20名礼包">>,
		goods_id=535611, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,144},{goods,523501,300},{goods,112214,60},{goods,601501,30},{silver,320,320},{coin,160000,160000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535612) ->
	#ets_gift{ 
		id=535612, 
		name = <<"排位赛第21-30名礼包">>,
		goods_id=535612, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,132},{goods,523501,250},{goods,112214,50},{goods,601501,25},{silver,280,280},{coin,140000,140000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535613) ->
	#ets_gift{ 
		id=535613, 
		name = <<"排位赛第31-50名礼包">>,
		goods_id=535613, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,120},{goods,523501,200},{goods,112214,40},{goods,601501,20},{silver,240,240},{coin,120000,120000}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535614) ->
	#ets_gift{ 
		id=535614, 
		name = <<"惊天战神礼包">>,
		goods_id=535614, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535619,10},{goods,523501,300}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535615) ->
	#ets_gift{ 
		id=535615, 
		name = <<"信仰之神礼包">>,
		goods_id=535615, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,535619,10},{goods,523501,300}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535616) ->
	#ets_gift{ 
		id=535616, 
		name = <<"竞猜神算礼包">>,
		goods_id=535616, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,5000,5000}],[{list,[{goods,112214,2}],10},{list,[{goods,112301,2}],40},{list,[{goods,601501,2}],10},{list,[{goods,523501,2}],40}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535617) ->
	#ets_gift{ 
		id=535617, 
		name = <<"竞猜参与礼包">>,
		goods_id=535617, 
		get_way=1, 
		gift_rand=4, 
		gifts=[[{coin,1000,1000}],[{list,[{goods,112214,1}],10},{list,[{goods,112301,1}],40},{list,[{goods,601501,1}],10},{list,[{goods,523501,1}],40}]],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535618) ->
	#ets_gift{ 
		id=535618, 
		name = <<"制胜礼包">>,
		goods_id=535618, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523601,1},{goods,523602,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535619) ->
	#ets_gift{ 
		id=535619, 
		name = <<"诸天争霸宝箱">>,
		goods_id=535619, 
		get_way=1, 
		gift_rand=2, 
		gifts=[{list,[{goods,523505,1}],50},{list,[{goods,523506,1}],50},{list,[{goods,523507,1}],50},{list,[{goods,523508,1}],50},{list,[{goods,523509,1}],50},{list,[{goods,523510,1}],50},{list,[{goods,612102,1}],100},{list,[{goods,621101,1}],50},{list,[{goods,311201,1}],150},{list,[{goods,205301,1}],200},{list,[{goods,206301,1}],200}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[523505, 523506, 523507, 523508, 523509, 523510, 612102, 621101],
		status=1
	};
get(535620) ->
	#ets_gift{ 
		id=535620, 
		name = <<"海选晋级奖">>,
		goods_id=535620, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,24},{goods,535619,1},{goods,523501,120}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535621) ->
	#ets_gift{ 
		id=535621, 
		name = <<"海选鼓励奖">>,
		goods_id=535621, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,12},{goods,523501,80}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535622) ->
	#ets_gift{ 
		id=535622, 
		name = <<"海选参与奖">>,
		goods_id=535622, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523501,15}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535623) ->
	#ets_gift{ 
		id=535623, 
		name = <<"小组第1名">>,
		goods_id=535623, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,132},{goods,535619,10},{goods,523501,300},{goods,602101,50},{goods,601401,50},{goods,611611,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535624) ->
	#ets_gift{ 
		id=535624, 
		name = <<"小组第2-4名">>,
		goods_id=535624, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,108},{goods,535619,8},{goods,523501,260},{goods,602101,30},{goods,601401,30},{goods,611611,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535625) ->
	#ets_gift{ 
		id=535625, 
		name = <<"小组第5-10名">>,
		goods_id=535625, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,84},{goods,535619,6},{goods,523501,220},{goods,602101,20},{goods,601401,20}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535626) ->
	#ets_gift{ 
		id=535626, 
		name = <<"小组第11-20名">>,
		goods_id=535626, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,60},{goods,535619,4},{goods,523501,180},{goods,602101,10},{goods,601401,10}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535627) ->
	#ets_gift{ 
		id=535627, 
		name = <<"小组第21-30名">>,
		goods_id=535627, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,48},{goods,535619,3},{goods,523501,160},{goods,602101,5}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535628) ->
	#ets_gift{ 
		id=535628, 
		name = <<"小组第31-40名">>,
		goods_id=535628, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,36},{goods,535619,2}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535629) ->
	#ets_gift{ 
		id=535629, 
		name = <<"全国总冠军">>,
		goods_id=535629, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311510,1},{goods,611730,1},{goods,611928,1},{goods,611612,1},{goods,523602,300},{goods,535619,50},{goods,523501,1000},{goods,602101,200},{goods,601401,200}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535630) ->
	#ets_gift{ 
		id=535630, 
		name = <<"全国第二名">>,
		goods_id=535630, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311510,1},{goods,611928,1},{goods,611612,1},{goods,523602,276},{goods,535619,40},{goods,523501,840},{goods,602101,150},{goods,601401,150}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535631) ->
	#ets_gift{ 
		id=535631, 
		name = <<"全国第三名">>,
		goods_id=535631, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,311510,1},{goods,611612,1},{goods,523602,252},{goods,535619,32},{goods,523501,700},{goods,602101,120},{goods,601401,120}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535632) ->
	#ets_gift{ 
		id=535632, 
		name = <<"全国第4-6名">>,
		goods_id=535632, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,228},{goods,535619,25},{goods,523501,580},{goods,602101,100},{goods,601401,100},{goods,611611,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535633) ->
	#ets_gift{ 
		id=535633, 
		name = <<"全国第7-10名">>,
		goods_id=535633, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,204},{goods,535619,20},{goods,523501,520},{goods,602101,80},{goods,601401,80},{goods,611611,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535634) ->
	#ets_gift{ 
		id=535634, 
		name = <<"全国第11-20名">>,
		goods_id=535634, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,180},{goods,535619,16},{goods,523501,440},{goods,602101,70},{goods,601401,70},{goods,611611,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535635) ->
	#ets_gift{ 
		id=535635, 
		name = <<"全国第21-30名">>,
		goods_id=535635, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,168},{goods,535619,14},{goods,523501,390},{goods,602101,60},{goods,601401,60}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535636) ->
	#ets_gift{ 
		id=535636, 
		name = <<"全国第31-40名">>,
		goods_id=535636, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,156},{goods,535619,12},{goods,523501,350},{goods,602101,50}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535637) ->
	#ets_gift{ 
		id=535637, 
		name = <<"全国第41-50名">>,
		goods_id=535637, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{goods,523602,144},{goods,535619,10},{goods,523501,320}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535638) ->
	#ets_gift{ 
		id=535638, 
		name = <<"20级成长礼包 (531002)">>,
		goods_id=531002, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,15,15},{goods,205101,2},{goods,206101,2},{goods,222001,1},{goods,211001,2},{goods,501202,2},{goods,612501,2},{coin,15000,15000},{goods,111041,2},{goods,531003,1}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(535639) ->
	#ets_gift{ 
		id=535639, 
		name = <<"30级成长礼包 (531003)">>,
		goods_id=531003, 
		get_way=1, 
		gift_rand=0, 
		gifts=[{silver,20,20},{goods,205101,3},{goods,206101,3},{goods,222001,1},{goods,211001,3},{goods,501202,3},{goods,612501,3},{coin,20000,20000},{goods,111041,3}],
		bind=2,
		start_time=0, 
		end_time=0,
		tv_goods_id=[],
		status=1
	};
get(_Id) ->
    [].

get_by_type(531001) -> data_gift:get(531001);
get_by_type(531002) -> data_gift:get(535638);
get_by_type(531003) -> data_gift:get(535639);
get_by_type(531009) -> data_gift:get(1009);
get_by_type(531011) -> data_gift:get(1011);
get_by_type(531013) -> data_gift:get(1013);
get_by_type(531201) -> data_gift:get(2010);
get_by_type(531616) -> data_gift:get(3011);
get_by_type(531617) -> data_gift:get(3012);
get_by_type(531618) -> data_gift:get(3013);
get_by_type(531619) -> data_gift:get(3014);
get_by_type(531620) -> data_gift:get(3015);
get_by_type(531621) -> data_gift:get(3016);
get_by_type(531622) -> data_gift:get(3017);
get_by_type(531623) -> data_gift:get(3018);
get_by_type(531624) -> data_gift:get(3019);
get_by_type(531625) -> data_gift:get(3020);
get_by_type(531626) -> data_gift:get(3021);
get_by_type(531627) -> data_gift:get(3022);
get_by_type(531628) -> data_gift:get(3023);
get_by_type(531629) -> data_gift:get(3024);
get_by_type(531630) -> data_gift:get(3025);
get_by_type(531631) -> data_gift:get(3026);
get_by_type(531632) -> data_gift:get(3027);
get_by_type(531633) -> data_gift:get(3028);
get_by_type(531634) -> data_gift:get(3029);
get_by_type(531635) -> data_gift:get(3030);
get_by_type(531636) -> data_gift:get(3031);
get_by_type(531637) -> data_gift:get(3032);
get_by_type(531638) -> data_gift:get(3033);
get_by_type(531639) -> data_gift:get(3034);
get_by_type(531640) -> data_gift:get(3035);
get_by_type(531641) -> data_gift:get(3041);
get_by_type(531642) -> data_gift:get(3042);
get_by_type(531643) -> data_gift:get(3043);
get_by_type(531644) -> data_gift:get(3044);
get_by_type(531645) -> data_gift:get(3045);
get_by_type(531647) -> data_gift:get(3047);
get_by_type(531648) -> data_gift:get(3048);
get_by_type(531649) -> data_gift:get(3049);
get_by_type(531650) -> data_gift:get(3050);
get_by_type(531651) -> data_gift:get(3051);
get_by_type(531652) -> data_gift:get(3052);
get_by_type(531653) -> data_gift:get(3053);
get_by_type(531654) -> data_gift:get(3054);
get_by_type(531655) -> data_gift:get(3055);
get_by_type(531656) -> data_gift:get(3056);
get_by_type(531657) -> data_gift:get(3057);
get_by_type(531658) -> data_gift:get(3058);
get_by_type(531659) -> data_gift:get(3059);
get_by_type(531660) -> data_gift:get(3060);
get_by_type(531661) -> data_gift:get(3061);
get_by_type(531662) -> data_gift:get(3062);
get_by_type(531663) -> data_gift:get(3063);
get_by_type(531664) -> data_gift:get(3064);
get_by_type(531665) -> data_gift:get(3065);
get_by_type(531666) -> data_gift:get(3066);
get_by_type(531667) -> data_gift:get(3067);
get_by_type(531668) -> data_gift:get(3068);
get_by_type(531669) -> data_gift:get(3069);
get_by_type(531670) -> data_gift:get(3070);
get_by_type(531021) -> data_gift:get(531021);
get_by_type(531022) -> data_gift:get(531022);
get_by_type(531023) -> data_gift:get(531023);
get_by_type(531024) -> data_gift:get(531024);
get_by_type(531025) -> data_gift:get(531025);
get_by_type(531026) -> data_gift:get(531026);
get_by_type(531101) -> data_gift:get(531101);
get_by_type(531102) -> data_gift:get(531102);
get_by_type(531103) -> data_gift:get(531103);
get_by_type(531104) -> data_gift:get(531104);
get_by_type(531105) -> data_gift:get(531105);
get_by_type(531106) -> data_gift:get(531106);
get_by_type(531501) -> data_gift:get(531302);
get_by_type(531502) -> data_gift:get(531303);
get_by_type(531503) -> data_gift:get(531304);
get_by_type(531504) -> data_gift:get(531305);
get_by_type(531505) -> data_gift:get(531306);
get_by_type(531801) -> data_gift:get(531310);
get_by_type(531331) -> data_gift:get(531331);
get_by_type(531332) -> data_gift:get(531332);
get_by_type(531401) -> data_gift:get(531401);
get_by_type(531402) -> data_gift:get(531402);
get_by_type(531403) -> data_gift:get(531403);
get_by_type(531421) -> data_gift:get(531421);
get_by_type(531422) -> data_gift:get(531422);
get_by_type(531423) -> data_gift:get(531423);
get_by_type(531601) -> data_gift:get(531601);
get_by_type(531602) -> data_gift:get(531602);
get_by_type(531603) -> data_gift:get(531603);
get_by_type(531604) -> data_gift:get(531604);
get_by_type(531605) -> data_gift:get(531605);
get_by_type(531606) -> data_gift:get(531606);
get_by_type(531607) -> data_gift:get(531607);
get_by_type(531608) -> data_gift:get(531608);
get_by_type(531609) -> data_gift:get(531609);
get_by_type(531610) -> data_gift:get(531610);
get_by_type(531611) -> data_gift:get(531611);
get_by_type(531701) -> data_gift:get(531701);
get_by_type(531702) -> data_gift:get(531702);
get_by_type(531703) -> data_gift:get(531703);
get_by_type(531704) -> data_gift:get(531704);
get_by_type(531711) -> data_gift:get(531711);
get_by_type(531712) -> data_gift:get(531712);
get_by_type(531713) -> data_gift:get(531713);
get_by_type(531714) -> data_gift:get(531714);
get_by_type(531715) -> data_gift:get(531715);
get_by_type(531716) -> data_gift:get(531716);
get_by_type(531717) -> data_gift:get(531717);
get_by_type(531718) -> data_gift:get(531718);
get_by_type(531721) -> data_gift:get(531721);
get_by_type(531722) -> data_gift:get(531722);
get_by_type(531723) -> data_gift:get(531723);
get_by_type(531724) -> data_gift:get(531724);
get_by_type(531725) -> data_gift:get(531725);
get_by_type(531726) -> data_gift:get(531726);
get_by_type(531727) -> data_gift:get(531727);
get_by_type(531728) -> data_gift:get(531728);
get_by_type(531731) -> data_gift:get(531731);
get_by_type(531732) -> data_gift:get(531732);
get_by_type(531733) -> data_gift:get(531733);
get_by_type(531734) -> data_gift:get(531734);
get_by_type(531735) -> data_gift:get(531735);
get_by_type(531736) -> data_gift:get(531736);
get_by_type(531737) -> data_gift:get(531737);
get_by_type(531738) -> data_gift:get(531738);
get_by_type(531802) -> data_gift:get(531802);
get_by_type(531803) -> data_gift:get(531803);
get_by_type(531804) -> data_gift:get(531804);
get_by_type(531805) -> data_gift:get(531805);
get_by_type(531806) -> data_gift:get(531806);
get_by_type(531807) -> data_gift:get(531807);
get_by_type(531811) -> data_gift:get(531811);
get_by_type(531812) -> data_gift:get(531812);
get_by_type(531813) -> data_gift:get(531813);
get_by_type(531814) -> data_gift:get(531814);
get_by_type(531815) -> data_gift:get(531815);
get_by_type(531816) -> data_gift:get(531816);
get_by_type(531817) -> data_gift:get(531817);
get_by_type(531818) -> data_gift:get(531818);
get_by_type(531819) -> data_gift:get(531819);
get_by_type(531820) -> data_gift:get(531820);
get_by_type(531821) -> data_gift:get(531821);
get_by_type(531822) -> data_gift:get(531822);
get_by_type(531823) -> data_gift:get(531823);
get_by_type(531824) -> data_gift:get(531824);
get_by_type(531825) -> data_gift:get(531825);
get_by_type(531826) -> data_gift:get(531826);
get_by_type(531827) -> data_gift:get(531827);
get_by_type(531828) -> data_gift:get(531828);
get_by_type(531829) -> data_gift:get(531829);
get_by_type(531830) -> data_gift:get(531830);
get_by_type(531831) -> data_gift:get(531831);
get_by_type(531832) -> data_gift:get(531832);
get_by_type(531833) -> data_gift:get(531833);
get_by_type(531834) -> data_gift:get(531834);
get_by_type(531901) -> data_gift:get(531901);
get_by_type(532001) -> data_gift:get(532001);
get_by_type(532011) -> data_gift:get(532011);
get_by_type(532012) -> data_gift:get(532012);
get_by_type(532013) -> data_gift:get(532017);
get_by_type(532014) -> data_gift:get(532014);
get_by_type(532018) -> data_gift:get(532018);
get_by_type(532021) -> data_gift:get(532021);
get_by_type(532022) -> data_gift:get(532022);
get_by_type(532023) -> data_gift:get(532023);
get_by_type(532024) -> data_gift:get(532024);
get_by_type(532025) -> data_gift:get(532025);
get_by_type(532101) -> data_gift:get(532101);
get_by_type(532201) -> data_gift:get(532201);
get_by_type(532202) -> data_gift:get(532202);
get_by_type(532203) -> data_gift:get(532203);
get_by_type(532204) -> data_gift:get(532204);
get_by_type(532205) -> data_gift:get(532205);
get_by_type(532206) -> data_gift:get(532206);
get_by_type(532207) -> data_gift:get(532207);
get_by_type(532208) -> data_gift:get(532208);
get_by_type(532209) -> data_gift:get(532209);
get_by_type(532210) -> data_gift:get(532210);
get_by_type(532211) -> data_gift:get(532211);
get_by_type(532213) -> data_gift:get(532213);
get_by_type(532214) -> data_gift:get(532214);
get_by_type(532215) -> data_gift:get(532215);
get_by_type(532217) -> data_gift:get(532217);
get_by_type(532218) -> data_gift:get(532218);
get_by_type(532219) -> data_gift:get(532219);
get_by_type(532220) -> data_gift:get(532220);
get_by_type(532221) -> data_gift:get(532221);
get_by_type(532222) -> data_gift:get(532222);
get_by_type(532223) -> data_gift:get(532223);
get_by_type(532224) -> data_gift:get(532224);
get_by_type(532225) -> data_gift:get(532225);
get_by_type(532231) -> data_gift:get(532231);
get_by_type(532232) -> data_gift:get(532232);
get_by_type(532233) -> data_gift:get(532233);
get_by_type(532234) -> data_gift:get(532234);
get_by_type(532236) -> data_gift:get(532236);
get_by_type(532237) -> data_gift:get(532237);
get_by_type(532238) -> data_gift:get(532238);
get_by_type(532250) -> data_gift:get(532250);
get_by_type(532251) -> data_gift:get(532251);
get_by_type(532252) -> data_gift:get(532252);
get_by_type(532253) -> data_gift:get(532253);
get_by_type(532254) -> data_gift:get(532254);
get_by_type(532255) -> data_gift:get(532255);
get_by_type(532256) -> data_gift:get(532256);
get_by_type(532257) -> data_gift:get(532257);
get_by_type(532258) -> data_gift:get(532258);
get_by_type(532259) -> data_gift:get(532259);
get_by_type(532260) -> data_gift:get(532260);
get_by_type(532261) -> data_gift:get(532261);
get_by_type(532303) -> data_gift:get(532303);
get_by_type(532304) -> data_gift:get(532304);
get_by_type(532305) -> data_gift:get(532305);
get_by_type(532306) -> data_gift:get(532306);
get_by_type(532307) -> data_gift:get(532307);
get_by_type(532401) -> data_gift:get(532401);
get_by_type(532402) -> data_gift:get(532402);
get_by_type(532403) -> data_gift:get(532403);
get_by_type(532404) -> data_gift:get(532404);
get_by_type(532405) -> data_gift:get(532405);
get_by_type(532406) -> data_gift:get(532406);
get_by_type(532407) -> data_gift:get(532407);
get_by_type(532408) -> data_gift:get(532408);
get_by_type(532409) -> data_gift:get(532409);
get_by_type(532410) -> data_gift:get(532410);
get_by_type(532411) -> data_gift:get(532411);
get_by_type(532412) -> data_gift:get(532412);
get_by_type(532413) -> data_gift:get(532413);
get_by_type(532414) -> data_gift:get(532414);
get_by_type(532415) -> data_gift:get(532415);
get_by_type(532416) -> data_gift:get(532416);
get_by_type(532417) -> data_gift:get(532417);
get_by_type(532418) -> data_gift:get(532418);
get_by_type(532421) -> data_gift:get(532421);
get_by_type(532422) -> data_gift:get(532422);
get_by_type(532423) -> data_gift:get(532423);
get_by_type(532426) -> data_gift:get(532426);
get_by_type(532427) -> data_gift:get(532427);
get_by_type(532428) -> data_gift:get(532428);
get_by_type(532429) -> data_gift:get(532429);
get_by_type(532431) -> data_gift:get(532431);
get_by_type(532432) -> data_gift:get(532432);
get_by_type(532433) -> data_gift:get(532433);
get_by_type(532436) -> data_gift:get(532436);
get_by_type(532437) -> data_gift:get(532437);
get_by_type(532441) -> data_gift:get(532441);
get_by_type(532442) -> data_gift:get(532442);
get_by_type(532443) -> data_gift:get(532443);
get_by_type(532444) -> data_gift:get(532444);
get_by_type(532445) -> data_gift:get(532445);
get_by_type(532446) -> data_gift:get(532446);
get_by_type(532447) -> data_gift:get(532447);
get_by_type(532451) -> data_gift:get(532451);
get_by_type(532452) -> data_gift:get(532452);
get_by_type(532453) -> data_gift:get(532453);
get_by_type(532461) -> data_gift:get(532461);
get_by_type(532462) -> data_gift:get(532462);
get_by_type(532463) -> data_gift:get(532463);
get_by_type(532464) -> data_gift:get(532464);
get_by_type(532465) -> data_gift:get(532465);
get_by_type(532466) -> data_gift:get(532466);
get_by_type(532467) -> data_gift:get(532467);
get_by_type(532501) -> data_gift:get(532501);
get_by_type(532502) -> data_gift:get(532502);
get_by_type(532503) -> data_gift:get(532503);
get_by_type(532504) -> data_gift:get(532504);
get_by_type(532505) -> data_gift:get(532505);
get_by_type(532506) -> data_gift:get(532506);
get_by_type(532507) -> data_gift:get(532507);
get_by_type(532508) -> data_gift:get(532508);
get_by_type(532509) -> data_gift:get(532509);
get_by_type(532510) -> data_gift:get(532510);
get_by_type(532511) -> data_gift:get(532511);
get_by_type(532512) -> data_gift:get(532512);
get_by_type(532513) -> data_gift:get(532513);
get_by_type(532514) -> data_gift:get(532514);
get_by_type(532515) -> data_gift:get(532515);
get_by_type(532516) -> data_gift:get(532516);
get_by_type(532517) -> data_gift:get(532517);
get_by_type(532518) -> data_gift:get(532518);
get_by_type(532519) -> data_gift:get(532519);
get_by_type(532520) -> data_gift:get(532520);
get_by_type(533001) -> data_gift:get(533001);
get_by_type(533002) -> data_gift:get(533002);
get_by_type(533003) -> data_gift:get(533003);
get_by_type(533004) -> data_gift:get(533004);
get_by_type(533005) -> data_gift:get(533005);
get_by_type(533006) -> data_gift:get(533006);
get_by_type(533007) -> data_gift:get(533007);
get_by_type(533008) -> data_gift:get(533008);
get_by_type(533009) -> data_gift:get(533009);
get_by_type(533010) -> data_gift:get(533010);
get_by_type(533011) -> data_gift:get(533011);
get_by_type(533012) -> data_gift:get(533012);
get_by_type(533013) -> data_gift:get(533013);
get_by_type(533014) -> data_gift:get(533014);
get_by_type(533015) -> data_gift:get(533015);
get_by_type(533016) -> data_gift:get(533016);
get_by_type(533017) -> data_gift:get(533017);
get_by_type(533018) -> data_gift:get(533018);
get_by_type(533019) -> data_gift:get(533019);
get_by_type(533020) -> data_gift:get(533020);
get_by_type(533021) -> data_gift:get(533021);
get_by_type(533022) -> data_gift:get(533022);
get_by_type(533023) -> data_gift:get(533023);
get_by_type(533024) -> data_gift:get(533024);
get_by_type(533025) -> data_gift:get(533025);
get_by_type(533026) -> data_gift:get(533026);
get_by_type(533027) -> data_gift:get(533027);
get_by_type(533028) -> data_gift:get(533028);
get_by_type(533029) -> data_gift:get(533029);
get_by_type(533030) -> data_gift:get(533030);
get_by_type(533031) -> data_gift:get(533031);
get_by_type(533032) -> data_gift:get(533032);
get_by_type(533033) -> data_gift:get(533033);
get_by_type(533034) -> data_gift:get(533034);
get_by_type(533035) -> data_gift:get(533035);
get_by_type(533036) -> data_gift:get(533036);
get_by_type(533037) -> data_gift:get(533037);
get_by_type(533038) -> data_gift:get(533038);
get_by_type(533039) -> data_gift:get(533039);
get_by_type(533040) -> data_gift:get(533040);
get_by_type(533041) -> data_gift:get(533041);
get_by_type(533042) -> data_gift:get(533042);
get_by_type(533043) -> data_gift:get(533043);
get_by_type(533044) -> data_gift:get(533044);
get_by_type(533045) -> data_gift:get(533045);
get_by_type(533046) -> data_gift:get(533046);
get_by_type(533047) -> data_gift:get(533047);
get_by_type(533048) -> data_gift:get(533048);
get_by_type(533049) -> data_gift:get(533049);
get_by_type(533050) -> data_gift:get(533050);
get_by_type(533051) -> data_gift:get(533051);
get_by_type(533052) -> data_gift:get(533052);
get_by_type(533053) -> data_gift:get(533053);
get_by_type(533054) -> data_gift:get(533054);
get_by_type(533055) -> data_gift:get(533055);
get_by_type(533056) -> data_gift:get(533056);
get_by_type(533057) -> data_gift:get(533057);
get_by_type(533058) -> data_gift:get(533058);
get_by_type(533059) -> data_gift:get(533059);
get_by_type(533060) -> data_gift:get(533060);
get_by_type(533061) -> data_gift:get(533061);
get_by_type(533062) -> data_gift:get(533062);
get_by_type(533063) -> data_gift:get(533063);
get_by_type(533064) -> data_gift:get(533064);
get_by_type(533065) -> data_gift:get(533065);
get_by_type(533066) -> data_gift:get(533066);
get_by_type(533067) -> data_gift:get(533067);
get_by_type(533068) -> data_gift:get(533068);
get_by_type(533069) -> data_gift:get(533069);
get_by_type(533070) -> data_gift:get(533070);
get_by_type(533071) -> data_gift:get(533071);
get_by_type(533072) -> data_gift:get(533072);
get_by_type(533073) -> data_gift:get(533073);
get_by_type(533074) -> data_gift:get(533074);
get_by_type(533075) -> data_gift:get(533075);
get_by_type(533076) -> data_gift:get(533076);
get_by_type(533077) -> data_gift:get(533077);
get_by_type(533078) -> data_gift:get(533078);
get_by_type(533079) -> data_gift:get(533079);
get_by_type(533080) -> data_gift:get(533080);
get_by_type(533081) -> data_gift:get(533081);
get_by_type(533082) -> data_gift:get(533082);
get_by_type(533101) -> data_gift:get(533101);
get_by_type(533102) -> data_gift:get(533102);
get_by_type(533103) -> data_gift:get(533103);
get_by_type(533104) -> data_gift:get(533104);
get_by_type(533105) -> data_gift:get(533105);
get_by_type(533106) -> data_gift:get(533106);
get_by_type(533107) -> data_gift:get(533107);
get_by_type(533108) -> data_gift:get(533108);
get_by_type(533109) -> data_gift:get(533109);
get_by_type(533110) -> data_gift:get(533110);
get_by_type(533111) -> data_gift:get(533111);
get_by_type(533112) -> data_gift:get(533112);
get_by_type(533113) -> data_gift:get(533113);
get_by_type(533114) -> data_gift:get(533114);
get_by_type(533115) -> data_gift:get(533115);
get_by_type(533116) -> data_gift:get(533116);
get_by_type(533117) -> data_gift:get(533117);
get_by_type(533901) -> data_gift:get(533901);
get_by_type(533902) -> data_gift:get(533902);
get_by_type(533903) -> data_gift:get(533903);
get_by_type(534000) -> data_gift:get(534000);
get_by_type(534001) -> data_gift:get(534001);
get_by_type(534002) -> data_gift:get(534002);
get_by_type(534003) -> data_gift:get(534003);
get_by_type(534004) -> data_gift:get(534004);
get_by_type(534005) -> data_gift:get(534005);
get_by_type(534006) -> data_gift:get(534006);
get_by_type(534007) -> data_gift:get(534007);
get_by_type(534008) -> data_gift:get(534008);
get_by_type(534009) -> data_gift:get(534009);
get_by_type(534010) -> data_gift:get(534010);
get_by_type(534011) -> data_gift:get(534011);
get_by_type(534012) -> data_gift:get(534012);
get_by_type(534013) -> data_gift:get(534013);
get_by_type(534014) -> data_gift:get(534014);
get_by_type(534015) -> data_gift:get(534015);
get_by_type(534016) -> data_gift:get(534016);
get_by_type(534017) -> data_gift:get(534017);
get_by_type(534018) -> data_gift:get(534018);
get_by_type(534019) -> data_gift:get(534019);
get_by_type(534020) -> data_gift:get(534020);
get_by_type(534021) -> data_gift:get(534021);
get_by_type(534022) -> data_gift:get(534022);
get_by_type(534023) -> data_gift:get(534023);
get_by_type(534024) -> data_gift:get(534024);
get_by_type(534025) -> data_gift:get(534025);
get_by_type(534026) -> data_gift:get(534026);
get_by_type(534027) -> data_gift:get(534027);
get_by_type(534028) -> data_gift:get(534028);
get_by_type(534029) -> data_gift:get(534029);
get_by_type(534030) -> data_gift:get(534030);
get_by_type(534031) -> data_gift:get(534031);
get_by_type(534032) -> data_gift:get(534032);
get_by_type(534033) -> data_gift:get(534033);
get_by_type(534034) -> data_gift:get(534034);
get_by_type(534035) -> data_gift:get(534035);
get_by_type(534036) -> data_gift:get(534036);
get_by_type(534037) -> data_gift:get(534037);
get_by_type(534038) -> data_gift:get(534038);
get_by_type(534039) -> data_gift:get(534039);
get_by_type(534040) -> data_gift:get(534040);
get_by_type(534041) -> data_gift:get(534041);
get_by_type(534042) -> data_gift:get(534042);
get_by_type(534043) -> data_gift:get(534043);
get_by_type(534044) -> data_gift:get(534044);
get_by_type(534045) -> data_gift:get(534045);
get_by_type(534046) -> data_gift:get(534046);
get_by_type(534047) -> data_gift:get(534047);
get_by_type(534048) -> data_gift:get(534048);
get_by_type(534049) -> data_gift:get(534049);
get_by_type(534050) -> data_gift:get(534050);
get_by_type(534051) -> data_gift:get(534051);
get_by_type(534052) -> data_gift:get(534052);
get_by_type(534053) -> data_gift:get(534053);
get_by_type(534054) -> data_gift:get(534054);
get_by_type(534055) -> data_gift:get(534055);
get_by_type(534056) -> data_gift:get(534056);
get_by_type(534057) -> data_gift:get(534057);
get_by_type(534058) -> data_gift:get(534058);
get_by_type(534059) -> data_gift:get(534059);
get_by_type(534060) -> data_gift:get(534060);
get_by_type(534061) -> data_gift:get(534061);
get_by_type(534062) -> data_gift:get(534062);
get_by_type(534063) -> data_gift:get(534063);
get_by_type(534064) -> data_gift:get(534064);
get_by_type(534065) -> data_gift:get(534065);
get_by_type(534066) -> data_gift:get(534066);
get_by_type(534067) -> data_gift:get(534067);
get_by_type(534068) -> data_gift:get(534068);
get_by_type(534069) -> data_gift:get(534069);
get_by_type(534070) -> data_gift:get(534070);
get_by_type(534071) -> data_gift:get(534071);
get_by_type(534072) -> data_gift:get(534072);
get_by_type(534073) -> data_gift:get(534073);
get_by_type(534074) -> data_gift:get(534074);
get_by_type(534075) -> data_gift:get(534075);
get_by_type(534076) -> data_gift:get(534076);
get_by_type(534077) -> data_gift:get(534077);
get_by_type(534078) -> data_gift:get(534078);
get_by_type(534079) -> data_gift:get(534079);
get_by_type(534080) -> data_gift:get(534080);
get_by_type(534081) -> data_gift:get(534081);
get_by_type(534082) -> data_gift:get(534082);
get_by_type(534083) -> data_gift:get(534083);
get_by_type(534084) -> data_gift:get(534084);
get_by_type(534085) -> data_gift:get(534085);
get_by_type(534086) -> data_gift:get(534086);
get_by_type(534087) -> data_gift:get(534087);
get_by_type(534088) -> data_gift:get(534088);
get_by_type(534089) -> data_gift:get(534089);
get_by_type(534090) -> data_gift:get(534090);
get_by_type(534091) -> data_gift:get(534091);
get_by_type(534092) -> data_gift:get(534092);
get_by_type(534093) -> data_gift:get(534093);
get_by_type(534094) -> data_gift:get(534094);
get_by_type(534095) -> data_gift:get(534095);
get_by_type(534096) -> data_gift:get(534096);
get_by_type(534097) -> data_gift:get(534097);
get_by_type(534098) -> data_gift:get(534098);
get_by_type(534099) -> data_gift:get(534099);
get_by_type(534100) -> data_gift:get(534100);
get_by_type(534101) -> data_gift:get(534101);
get_by_type(534102) -> data_gift:get(534102);
get_by_type(534103) -> data_gift:get(534103);
get_by_type(534104) -> data_gift:get(534104);
get_by_type(534105) -> data_gift:get(534105);
get_by_type(534106) -> data_gift:get(534106);
get_by_type(534107) -> data_gift:get(534107);
get_by_type(534108) -> data_gift:get(534108);
get_by_type(534109) -> data_gift:get(534109);
get_by_type(534110) -> data_gift:get(534110);
get_by_type(534111) -> data_gift:get(534111);
get_by_type(534112) -> data_gift:get(534112);
get_by_type(534113) -> data_gift:get(534113);
get_by_type(534114) -> data_gift:get(534114);
get_by_type(534115) -> data_gift:get(534115);
get_by_type(534116) -> data_gift:get(534116);
get_by_type(534117) -> data_gift:get(534117);
get_by_type(534118) -> data_gift:get(534118);
get_by_type(534119) -> data_gift:get(534119);
get_by_type(534120) -> data_gift:get(534120);
get_by_type(534121) -> data_gift:get(534121);
get_by_type(534122) -> data_gift:get(534122);
get_by_type(534123) -> data_gift:get(534123);
get_by_type(534124) -> data_gift:get(534124);
get_by_type(534125) -> data_gift:get(534125);
get_by_type(534126) -> data_gift:get(534126);
get_by_type(534127) -> data_gift:get(534127);
get_by_type(534128) -> data_gift:get(534128);
get_by_type(534129) -> data_gift:get(534129);
get_by_type(534130) -> data_gift:get(534130);
get_by_type(534131) -> data_gift:get(534131);
get_by_type(534132) -> data_gift:get(534132);
get_by_type(534133) -> data_gift:get(534133);
get_by_type(534134) -> data_gift:get(534134);
get_by_type(534135) -> data_gift:get(534135);
get_by_type(534136) -> data_gift:get(534136);
get_by_type(534137) -> data_gift:get(534137);
get_by_type(534138) -> data_gift:get(534138);
get_by_type(534139) -> data_gift:get(534139);
get_by_type(534140) -> data_gift:get(534140);
get_by_type(534141) -> data_gift:get(534141);
get_by_type(534142) -> data_gift:get(534142);
get_by_type(534143) -> data_gift:get(534143);
get_by_type(534144) -> data_gift:get(534144);
get_by_type(534145) -> data_gift:get(534145);
get_by_type(534146) -> data_gift:get(534146);
get_by_type(534147) -> data_gift:get(534147);
get_by_type(534148) -> data_gift:get(534148);
get_by_type(534149) -> data_gift:get(534149);
get_by_type(534150) -> data_gift:get(534150);
get_by_type(534151) -> data_gift:get(534151);
get_by_type(534152) -> data_gift:get(534152);
get_by_type(534153) -> data_gift:get(534153);
get_by_type(534154) -> data_gift:get(534154);
get_by_type(534155) -> data_gift:get(534155);
get_by_type(534156) -> data_gift:get(534156);
get_by_type(534157) -> data_gift:get(534157);
get_by_type(534158) -> data_gift:get(534158);
get_by_type(534159) -> data_gift:get(534159);
get_by_type(534160) -> data_gift:get(534160);
get_by_type(534161) -> data_gift:get(534161);
get_by_type(534162) -> data_gift:get(534162);
get_by_type(534163) -> data_gift:get(534163);
get_by_type(534164) -> data_gift:get(534164);
get_by_type(534165) -> data_gift:get(534165);
get_by_type(534166) -> data_gift:get(534166);
get_by_type(534167) -> data_gift:get(534167);
get_by_type(534168) -> data_gift:get(534168);
get_by_type(534169) -> data_gift:get(534169);
get_by_type(534170) -> data_gift:get(534170);
get_by_type(534171) -> data_gift:get(534171);
get_by_type(534172) -> data_gift:get(534172);
get_by_type(534173) -> data_gift:get(534173);
get_by_type(534174) -> data_gift:get(534174);
get_by_type(534175) -> data_gift:get(534175);
get_by_type(534176) -> data_gift:get(534176);
get_by_type(534177) -> data_gift:get(534177);
get_by_type(534178) -> data_gift:get(534178);
get_by_type(534179) -> data_gift:get(534179);
get_by_type(534180) -> data_gift:get(534180);
get_by_type(534181) -> data_gift:get(534181);
get_by_type(534182) -> data_gift:get(534182);
get_by_type(534183) -> data_gift:get(534183);
get_by_type(534184) -> data_gift:get(534184);
get_by_type(534185) -> data_gift:get(534185);
get_by_type(534186) -> data_gift:get(534186);
get_by_type(534187) -> data_gift:get(534187);
get_by_type(534188) -> data_gift:get(534188);
get_by_type(534189) -> data_gift:get(534189);
get_by_type(534190) -> data_gift:get(534190);
get_by_type(534191) -> data_gift:get(534191);
get_by_type(534192) -> data_gift:get(534192);
get_by_type(534193) -> data_gift:get(534193);
get_by_type(534194) -> data_gift:get(534194);
get_by_type(534195) -> data_gift:get(534195);
get_by_type(534196) -> data_gift:get(534196);
get_by_type(534197) -> data_gift:get(534197);
get_by_type(534198) -> data_gift:get(534198);
get_by_type(534199) -> data_gift:get(534199);
get_by_type(534200) -> data_gift:get(534200);
get_by_type(534201) -> data_gift:get(534201);
get_by_type(534202) -> data_gift:get(534202);
get_by_type(534203) -> data_gift:get(534203);
get_by_type(534204) -> data_gift:get(534204);
get_by_type(534205) -> data_gift:get(534205);
get_by_type(534206) -> data_gift:get(534206);
get_by_type(534207) -> data_gift:get(534207);
get_by_type(534208) -> data_gift:get(534208);
get_by_type(534209) -> data_gift:get(534209);
get_by_type(534210) -> data_gift:get(534210);
get_by_type(534211) -> data_gift:get(534211);
get_by_type(534212) -> data_gift:get(534212);
get_by_type(534213) -> data_gift:get(534213);
get_by_type(534214) -> data_gift:get(534214);
get_by_type(534215) -> data_gift:get(534215);
get_by_type(534216) -> data_gift:get(534216);
get_by_type(534217) -> data_gift:get(534217);
get_by_type(534218) -> data_gift:get(534218);
get_by_type(534219) -> data_gift:get(534219);
get_by_type(534220) -> data_gift:get(534220);
get_by_type(534221) -> data_gift:get(534221);
get_by_type(534222) -> data_gift:get(534222);
get_by_type(534223) -> data_gift:get(534223);
get_by_type(534224) -> data_gift:get(534224);
get_by_type(534225) -> data_gift:get(534225);
get_by_type(534226) -> data_gift:get(534226);
get_by_type(534227) -> data_gift:get(534227);
get_by_type(534228) -> data_gift:get(534228);
get_by_type(534229) -> data_gift:get(534229);
get_by_type(534230) -> data_gift:get(534230);
get_by_type(534231) -> data_gift:get(534231);
get_by_type(534232) -> data_gift:get(534232);
get_by_type(534233) -> data_gift:get(534233);
get_by_type(534234) -> data_gift:get(534234);
get_by_type(534235) -> data_gift:get(534235);
get_by_type(534236) -> data_gift:get(534236);
get_by_type(534237) -> data_gift:get(534237);
get_by_type(534238) -> data_gift:get(534238);
get_by_type(534239) -> data_gift:get(534239);
get_by_type(534240) -> data_gift:get(534240);
get_by_type(534241) -> data_gift:get(534241);
get_by_type(534242) -> data_gift:get(534242);
get_by_type(534243) -> data_gift:get(534243);
get_by_type(534244) -> data_gift:get(534244);
get_by_type(534245) -> data_gift:get(534245);
get_by_type(534246) -> data_gift:get(534246);
get_by_type(534247) -> data_gift:get(534247);
get_by_type(534248) -> data_gift:get(534248);
get_by_type(534249) -> data_gift:get(534249);
get_by_type(534250) -> data_gift:get(534250);
get_by_type(534251) -> data_gift:get(534251);
get_by_type(534252) -> data_gift:get(534252);
get_by_type(534253) -> data_gift:get(534253);
get_by_type(534254) -> data_gift:get(534254);
get_by_type(534255) -> data_gift:get(534255);
get_by_type(534256) -> data_gift:get(534256);
get_by_type(534257) -> data_gift:get(534257);
get_by_type(534258) -> data_gift:get(534258);
get_by_type(534259) -> data_gift:get(534259);
get_by_type(534260) -> data_gift:get(534260);
get_by_type(534261) -> data_gift:get(534261);
get_by_type(534262) -> data_gift:get(534262);
get_by_type(534263) -> data_gift:get(534263);
get_by_type(534264) -> data_gift:get(534264);
get_by_type(534265) -> data_gift:get(534265);
get_by_type(534266) -> data_gift:get(534266);
get_by_type(534267) -> data_gift:get(534267);
get_by_type(534268) -> data_gift:get(534268);
get_by_type(534269) -> data_gift:get(534269);
get_by_type(534270) -> data_gift:get(534270);
get_by_type(534271) -> data_gift:get(534271);
get_by_type(534272) -> data_gift:get(534272);
get_by_type(534273) -> data_gift:get(534273);
get_by_type(534274) -> data_gift:get(534274);
get_by_type(534275) -> data_gift:get(534275);
get_by_type(534276) -> data_gift:get(534276);
get_by_type(534277) -> data_gift:get(534277);
get_by_type(534278) -> data_gift:get(534278);
get_by_type(534279) -> data_gift:get(534279);
get_by_type(534280) -> data_gift:get(534280);
get_by_type(534281) -> data_gift:get(534281);
get_by_type(534282) -> data_gift:get(534282);
get_by_type(534283) -> data_gift:get(534283);
get_by_type(534284) -> data_gift:get(534284);
get_by_type(534285) -> data_gift:get(534285);
get_by_type(534286) -> data_gift:get(534286);
get_by_type(534287) -> data_gift:get(534287);
get_by_type(535101) -> data_gift:get(535101);
get_by_type(535102) -> data_gift:get(535102);
get_by_type(535103) -> data_gift:get(535103);
get_by_type(535111) -> data_gift:get(535111);
get_by_type(535112) -> data_gift:get(535112);
get_by_type(535113) -> data_gift:get(535113);
get_by_type(535201) -> data_gift:get(535201);
get_by_type(535202) -> data_gift:get(535202);
get_by_type(535203) -> data_gift:get(535203);
get_by_type(535204) -> data_gift:get(535204);
get_by_type(535205) -> data_gift:get(535205);
get_by_type(535206) -> data_gift:get(535206);
get_by_type(535207) -> data_gift:get(535207);
get_by_type(535208) -> data_gift:get(535208);
get_by_type(535209) -> data_gift:get(535209);
get_by_type(535210) -> data_gift:get(535210);
get_by_type(535211) -> data_gift:get(535211);
get_by_type(535212) -> data_gift:get(535212);
get_by_type(535213) -> data_gift:get(535213);
get_by_type(535214) -> data_gift:get(535214);
get_by_type(535215) -> data_gift:get(535215);
get_by_type(535216) -> data_gift:get(535216);
get_by_type(535217) -> data_gift:get(535217);
get_by_type(535218) -> data_gift:get(535218);
get_by_type(535219) -> data_gift:get(535219);
get_by_type(535220) -> data_gift:get(535220);
get_by_type(535221) -> data_gift:get(535221);
get_by_type(535501) -> data_gift:get(535501);
get_by_type(535502) -> data_gift:get(535502);
get_by_type(535503) -> data_gift:get(535503);
get_by_type(535504) -> data_gift:get(535504);
get_by_type(535505) -> data_gift:get(535505);
get_by_type(535506) -> data_gift:get(535506);
get_by_type(535507) -> data_gift:get(535507);
get_by_type(535508) -> data_gift:get(535508);
get_by_type(535509) -> data_gift:get(535509);
get_by_type(535510) -> data_gift:get(535510);
get_by_type(535511) -> data_gift:get(535511);
get_by_type(535512) -> data_gift:get(535512);
get_by_type(535513) -> data_gift:get(535513);
get_by_type(535514) -> data_gift:get(535514);
get_by_type(535515) -> data_gift:get(535515);
get_by_type(535516) -> data_gift:get(535516);
get_by_type(535517) -> data_gift:get(535517);
get_by_type(535518) -> data_gift:get(535518);
get_by_type(535519) -> data_gift:get(535519);
get_by_type(535520) -> data_gift:get(535520);
get_by_type(535521) -> data_gift:get(535521);
get_by_type(535522) -> data_gift:get(535522);
get_by_type(535523) -> data_gift:get(535523);
get_by_type(535524) -> data_gift:get(535524);
get_by_type(535525) -> data_gift:get(535525);
get_by_type(535526) -> data_gift:get(535526);
get_by_type(535527) -> data_gift:get(535527);
get_by_type(535528) -> data_gift:get(535528);
get_by_type(535529) -> data_gift:get(535529);
get_by_type(535530) -> data_gift:get(535530);
get_by_type(535531) -> data_gift:get(535531);
get_by_type(535532) -> data_gift:get(535532);
get_by_type(535533) -> data_gift:get(535533);
get_by_type(535534) -> data_gift:get(535534);
get_by_type(535535) -> data_gift:get(535535);
get_by_type(535536) -> data_gift:get(535536);
get_by_type(535542) -> data_gift:get(535542);
get_by_type(535543) -> data_gift:get(535543);
get_by_type(535550) -> data_gift:get(535550);
get_by_type(535551) -> data_gift:get(535551);
get_by_type(535552) -> data_gift:get(535552);
get_by_type(535553) -> data_gift:get(535553);
get_by_type(535554) -> data_gift:get(535554);
get_by_type(535555) -> data_gift:get(535555);
get_by_type(535556) -> data_gift:get(535556);
get_by_type(535570) -> data_gift:get(535570);
get_by_type(535571) -> data_gift:get(535571);
get_by_type(535572) -> data_gift:get(535572);
get_by_type(535573) -> data_gift:get(535573);
get_by_type(535574) -> data_gift:get(535574);
get_by_type(535601) -> data_gift:get(535601);
get_by_type(535602) -> data_gift:get(535602);
get_by_type(535603) -> data_gift:get(535603);
get_by_type(535604) -> data_gift:get(535604);
get_by_type(535605) -> data_gift:get(535605);
get_by_type(535606) -> data_gift:get(535606);
get_by_type(535607) -> data_gift:get(535607);
get_by_type(535608) -> data_gift:get(535608);
get_by_type(535609) -> data_gift:get(535609);
get_by_type(535610) -> data_gift:get(535610);
get_by_type(535611) -> data_gift:get(535611);
get_by_type(535612) -> data_gift:get(535612);
get_by_type(535613) -> data_gift:get(535613);
get_by_type(535614) -> data_gift:get(535614);
get_by_type(535615) -> data_gift:get(535615);
get_by_type(535616) -> data_gift:get(535616);
get_by_type(535617) -> data_gift:get(535617);
get_by_type(535618) -> data_gift:get(535618);
get_by_type(535619) -> data_gift:get(535619);
get_by_type(535620) -> data_gift:get(535620);
get_by_type(535621) -> data_gift:get(535621);
get_by_type(535622) -> data_gift:get(535622);
get_by_type(535623) -> data_gift:get(535623);
get_by_type(535624) -> data_gift:get(535624);
get_by_type(535625) -> data_gift:get(535625);
get_by_type(535626) -> data_gift:get(535626);
get_by_type(535627) -> data_gift:get(535627);
get_by_type(535628) -> data_gift:get(535628);
get_by_type(535629) -> data_gift:get(535629);
get_by_type(535630) -> data_gift:get(535630);
get_by_type(535631) -> data_gift:get(535631);
get_by_type(535632) -> data_gift:get(535632);
get_by_type(535633) -> data_gift:get(535633);
get_by_type(535634) -> data_gift:get(535634);
get_by_type(535635) -> data_gift:get(535635);
get_by_type(535636) -> data_gift:get(535636);
get_by_type(535637) -> data_gift:get(535637);
get_by_type(_Id) -> 
	null.

get_by_register() ->
	[].

