%%%--------------------------------------
%%% @Module  : data_gift_config
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.6.30
%%% @Description: 礼包相关数值配置
%%%--------------------------------------

-module(data_gift_config).
-compile(export_all).

%% 用于生成通用礼包的key
get_common_gift_key() -> "8c3ba42d65fed2cfdd300d6a9ec6fd20".

%% [在线倒计时礼包] 总共有多少个倒计时奖励
max_online_num() -> 6.

%% [在线倒计时礼包] 获取每个阶段配置
get_online_data(1) ->
	%% [礼包ID, 倒计时秒数]
	[531101, 1 * 60];
get_online_data(2) ->
	[531102, 5 * 60];
get_online_data(3) ->
	[531103, 15 * 60];
get_online_data(4) ->
	[531104, 30 * 60];
get_online_data(5) ->
	[531105, 60 * 60];
get_online_data(6) ->
	[531106, 120 * 60];
get_online_data(_Step) ->
	[0, 0].

%% [新服首充礼包] 获取礼包配置
get_recharge_data() ->
	%% [充值元宝数， 礼包ID]
	[[1, 532001], [500, 532021], [2000, 532022], [5000, 532023], [10000, 532024], [20000, 532025], [50000, 532026], [100000, 532027]].
%% [新服首充礼包] 礼包ID串，方便用于数据库查询
get_recharge_giftids() ->
	"532001, 532021, 532022, 532023, 532024, 532025, 532026, 532027".
%% [新服首充礼包] 礼包ID列表
get_recharge_giftids_list() ->
	[532001, 532021, 532022, 532023, 532024, 532025, 532026, 532027].

%% 通用礼包规则，礼包种类
%% 格式：[礼包类型, 礼包id]
get_common_rule_gift() ->
	[
		[1, 533048],
		[2, 533049],
		[3, 533051],
		[4, 533052],
		[5, 533053],
		[6, 533054],
		[7, 533055],
		[8, 533050],
		[9, 533059],
		[10, 533060],
		[11, 533062],
		[12, 533063],
		[13, 533064],
		[14, 533065],
		[15, 533066],
		[16, 533061]
	].

%% [新年倒计时礼包] 获取每个阶段配置
%% @return [礼包ID, 倒计时秒数] 应该是5分钟一个
get_newyear_data(Step) ->
	case Step < 10 of
		true ->
			[534114, 5*60];
		false ->
			case Step > 10 of
				true ->
					[0, 0];
				_ ->
					[534115, 5*60]
			end
	end.


get_config(Type)->
    case Type of
        max_count -> 12;
        lv_qj -> [20, 110];
        _ -> undefined
    end.


