
%%%---------------------------------------
%%% @Module  : data_forge
%%% @Author  : xhg
%%% @Email   : xuhuguang@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_forge).
-export([get/1]).
-include("goods.hrl").

get(11071) ->
	#ets_forge{id=11071,type=1,sub_type=107,raw_goods = [{121001,3}],goods_id=121002,bind=0,ratio=100,coin=1000,notice=0};
get(11072) ->
	#ets_forge{id=11072,type=1,sub_type=107,raw_goods = [{121002,3}],goods_id=121003,bind=0,ratio=100,coin=1000,notice=0};
get(11073) ->
	#ets_forge{id=11073,type=1,sub_type=107,raw_goods = [{121003,2}],goods_id=121004,bind=0,ratio=100,coin=1000,notice=0};
get(11074) ->
	#ets_forge{id=11074,type=1,sub_type=107,raw_goods = [{121004,2}],goods_id=121005,bind=0,ratio=100,coin=1000,notice=0};
get(11075) ->
	#ets_forge{id=11075,type=1,sub_type=107,raw_goods = [{121005,2}],goods_id=121006,bind=0,ratio=100,coin=1000,notice=1};
get(11076) ->
	#ets_forge{id=11076,type=1,sub_type=107,raw_goods = [{121006,2}],goods_id=121007,bind=0,ratio=100,coin=1000,notice=1};
get(11077) ->
	#ets_forge{id=11077,type=1,sub_type=107,raw_goods = [{121007,2}],goods_id=121008,bind=0,ratio=100,coin=1000,notice=1};
get(44011) ->
	#ets_forge{id=44011,type=4,sub_type=401,raw_goods = [{111481,3}],goods_id=111482,bind=0,ratio=100,coin=1000,notice=0};
get(44012) ->
	#ets_forge{id=44012,type=4,sub_type=401,raw_goods = [{111482,3}],goods_id=111483,bind=0,ratio=100,coin=1000,notice=0};
get(44013) ->
	#ets_forge{id=44013,type=4,sub_type=401,raw_goods = [{111491,3}],goods_id=111492,bind=0,ratio=100,coin=1000,notice=0};
get(44014) ->
	#ets_forge{id=44014,type=4,sub_type=401,raw_goods = [{111492,3}],goods_id=111493,bind=0,ratio=100,coin=1000,notice=0};
get(44015) ->
	#ets_forge{id=44015,type=4,sub_type=401,raw_goods = [{111501,3}],goods_id=111502,bind=0,ratio=100,coin=1000,notice=0};
get(44016) ->
	#ets_forge{id=44016,type=4,sub_type=401,raw_goods = [{111502,3}],goods_id=111503,bind=0,ratio=100,coin=1000,notice=0};
get(_) ->
    [].
