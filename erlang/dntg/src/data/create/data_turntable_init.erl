
%%%---------------------------------------
%%% @Module  : data_turntable_init
%%% @Author  : xhg
%%% @Email   : xuhuguang@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_turntable_init).
-export([get_goods_list/0]).
-include("goods.hrl").

get_goods_list() ->
    [
	#base_turntable{ id = 1, precious = 1, goods_id = 888888, ratio = 2, ratio_start = 1, ratio_end = 2 },
	#base_turntable{ id = 2, precious = 1, goods_id = 777777, ratio = 10, ratio_start = 3, ratio_end = 12 },
	#base_turntable{ id = 3, precious = 1, goods_id = 666666, ratio = 25, ratio_start = 13, ratio_end = 37 },
	#base_turntable{ id = 4, precious = 0, goods_id = 555555, ratio = 8511, ratio_start = 38, ratio_end = 8548 },
	#base_turntable{ id = 5, precious = 0, goods_id = 112302, ratio = 1000, ratio_start = 8549, ratio_end = 9548 },
	#base_turntable{ id = 6, precious = 1, goods_id = 112303, ratio = 200, ratio_start = 9549, ratio_end = 9748 },
	#base_turntable{ id = 7, precious = 0, goods_id = 624801, ratio = 250, ratio_start = 9749, ratio_end = 9998 },
	#base_turntable{ id = 8, precious = 1, goods_id = 624201, ratio = 2, ratio_start = 9999, ratio_end = 10000 }
    ].
