%%%--------------------------------------
%%% @Module  : lib_recharge_ds
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.30
%%% @Description: 充值处理数据源相关
%%%--------------------------------------

-module(lib_recharge_ds).
-include("recharge.hrl").
-include("gift.hrl").
-compile(export_all).

%% 获取充值总额
get_total(RoleId) ->
	CacheKey = ?PAY_TOTAL_RECHARGE(RoleId),
	case mod_daily_dict:get_special_info(CacheKey) of
		undefined ->
			Recharge = case db:get_one(io_lib:format(?sql_recharge_get_total, [RoleId])) of
				null -> 0;
				M -> M
			end,
			mod_daily_dict:set_special_info(CacheKey, Recharge),
			Recharge;
		Money ->
			Money
	end.

%% 活动：充值任务活动，获得充值总额 
get_pay_task_total(RoleId, Start, End) ->
	case db:get_one(io_lib:format(?sql_pay_task_get_gold, [RoleId, Start, End])) of
		Total when is_integer(Total) -> 
			Total;
		_ -> 
			0
	end.

%% 获得使用元宝道具获得元宝总额
get_gold_goods_total(RoleId, Start, End) ->
	case db:get_one(io_lib:format(?sql_gold_goods_total, [RoleId, Start, End])) of
		Total when is_integer(Total) -> 
			Total;
		_ -> 
			0
	end.

%% 更新总充值统计数
update_total_recharge(RoleId, TotalRecharge) ->
	db:execute(
		io_lib:format(?sql_recharge_update_total, [TotalRecharge, RoleId])  
	),
	CacheKey = ?PAY_TOTAL_RECHARGE(RoleId),
	mod_daily_dict:set_special_info(CacheKey, TotalRecharge).

%% 取出所有未处理的充值记录
get_all_recharge() ->
	db:get_all(?sql_pay_fetch_all).

%% 首充礼包相关处理
first_recharge_gift(RoleId) ->
	lib_gift_new:trigger_fetch(RoleId, ?FIRST_RECHARGE_GIFT_ID).

%% 将充值记录标识为已经完成处理
finish_recharge(Id) ->
	db:execute(
		io_lib:format(?sql_pay_update_recharge, [Id])  
	).

%% 取出玩家所有充值待处理记录
get_my_all_recharge(RoleId) ->
	db:get_all(
		io_lib:format(?sql_pay_fetch_all_of_user, [RoleId])  
	).
