%%%--------------------------------------
%%% @Module  : data_recharge_award_tmp
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.24
%%% @Description: 春节充值送礼数据配置
%%%--------------------------------------
-module(data_recharge_award_tmp).
-compile(export_all).

%% 活动时间
get_recharge_award_time() -> [1360101600,1360511999].

%% 配置的礼包，格式：[需要的元宝，礼包id]
get_recharge_award_gift() ->
	[[1,534207],[888,534208],[2888,534209],[5888,534210],[8888,534211],[12888,534212]].

%% 开服天数要求
get_day() -> 5.

%% 可重复领取礼包配置(这块不需要修改)
get_recharge_award_regift() -> [20000000, 0, 20130128].
