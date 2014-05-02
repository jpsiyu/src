%%%---------------------------------------
%%%--------------------------------------
%%% @Module  : data_recharge_award
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.24
%%% @Description: 充值送礼数据配置
%%%--------------------------------------
-module(data_recharge_award).
-compile(export_all).

get_recharge_award_time() ->
	[1364227200,1364745599].
get_recharge_award_gift() ->
	[[88,534207],[888,534208],[2888,534209],[5888,534210],[8888,534211],[12888,534212]].
get_day() ->
		0.
get_recharge_award_regift() ->
		[88888888888888888,534048,20130311].
get_single_recharge_award_time() ->
	[1362002400,1362067199].
get_single_recharge_award_gift() ->
	[{1000,534207},{3000,534208},{5000,534209},{10000,534210},{20000,534211}].
get_single_day() ->
		0.

