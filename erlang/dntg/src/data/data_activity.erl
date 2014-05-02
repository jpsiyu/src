%%%--------------------------------------
%%% @Module  : data_activity
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.24
%%% @Description: 运营活动相关
%%%--------------------------------------

-module(data_activity).
-include("activity.hrl").
-compile(export_all).


%% 幸福回归活动:活动时间
back_activity_time(1) ->
	[
		util:unixtime({{2012, 11, 17}, {0, 0, 0}}),
		util:unixtime({{2012, 11, 22}, {23, 59, 59}})
	];
back_activity_time(2) ->
	[
		util:unixtime({{2012, 11, 17}, {0, 0, 0}}),
		util:unixtime({{2012, 11, 22}, {23, 59, 59}})
	];
back_activity_time(3) ->
	[
		util:unixtime({{2012, 11, 17}, {0, 0, 0}}),
		util:unixtime({{2012, 11, 22}, {23, 59, 59}})
	].

%% 幸福回归活动配置
%% @ruturn 需要等级 连续离线时间  需要开服时间
back_activity_config(1) ->
	[45, 7*24*60*60, 1];
%%	[45, 10, 1];
back_activity_config(2) ->
	[45, 7*24*60*60, 1];
%%	[45, 10, 1];
back_activity_config(3) ->
	[0, 7*24*60*60, 0].
%%	[0, 10, 0].

%% 幸福回归：回归首充回礼奖励配置
%% @return 需要的充值元宝 | 充值返利系数
back_charge_award_config() -> 
	[1000, 5].

%% 活跃度活动时间
get_active_time() ->
	[
		util:unixtime({{2013, 3, 18}, {0, 0, 0}}),
		util:unixtime({{2013, 3, 20}, {23, 59, 59}})
	].

%% 达人榜活动时间
%% 返回：[开始时间戳, 结束时间戳]
get_fame_limit_time() ->
	[
 		util:unixtime({{2013, 1, 23}, {0, 0, 0}}),
		util:unixtime({{2013, 1, 28}, {23, 59, 59}})
	].

%% 鲜花魅力榜活动时间 ,活动会送西游第一美和西游第一帅称号
get_charm_time() ->
	[
 		util:unixtime({{2013, 3, 14}, {0, 0, 0}}),
		util:unixtime({{2013, 3, 20}, {23, 59, 59}})
	].

%% 获取奖励
%% 格式为：[等级, 礼包id]
get_award() ->
	[
        %% [65, 531027],
		[60, 531026],
		[55, 531025],
		[50, 531024],
		[45, 531023],
		[40, 531022],
		[35, 531021]
	].

%% 获取活动出现的图标等级
get_finish_stat() ->
	[
		{?ACTIVITY_FINISH_TARGET, 15},
	 	{?ACTIVITY_FINISH_LEVEL_FORWARD, 1},
		{?ACTIVITY_FINISH_RECHARGE_GIFT, 10}
	 ].

%% [首服充值活动] 通过礼包id取到对应需要充值的元宝数
get_recharge_from_gift(532001) -> 10;
get_recharge_from_gift(532021) -> 880;
get_recharge_from_gift(532022) -> 2880;
get_recharge_from_gift(532023) -> 5880;
get_recharge_from_gift(532024) -> 9880;
get_recharge_from_gift(532025) -> 19880;
get_recharge_from_gift(_) -> 1000000000.

%% 开服七天内每天登录获得礼包
%get_seven_day_login_gift(1) -> [532441, 532461];
%get_seven_day_login_gift(2) -> [532442, 532462];
%get_seven_day_login_gift(3) -> [532443, 532463];
%get_seven_day_login_gift(4) -> [532444, 532464];
%get_seven_day_login_gift(5) -> [532445, 532465];
%get_seven_day_login_gift(6) -> [532446, 532466];
%get_seven_day_login_gift(7) -> [532447, 532467];
%get_seven_day_login_gift(_) -> [0, 0].

%% 封测礼包相同
get_seven_day_login_gift(1) -> [532461, 532461];
get_seven_day_login_gift(2) -> [532462, 532462];
get_seven_day_login_gift(3) -> [532463, 532463];
get_seven_day_login_gift(4) -> [532464, 532464];
get_seven_day_login_gift(5) -> [532465, 532465];
get_seven_day_login_gift(6) -> [532466, 532466];
get_seven_day_login_gift(7) -> [532467, 532467];
get_seven_day_login_gift(_) -> [0, 0].
get_seven_day_login_gift_all() -> "532461,532462,532463,532464,532465,532466,532467".

%% 首服充值活动特殊处理开始时间
%% 老服在9月3号开始又会开放活动
get_special_day() ->
 	{{2012, 9, 3}, {0, 0, 0}}.
%% 老服是7天活动
get_special_daynum() ->
	7.
%% 新服是5天活动
get_common_daynum() ->
	5.

%% ---------- 中秋国庆活动 ---------- %%
%% 获取活跃度礼包id
get_active_gift() -> 534056.
%% 获取配置，格式：[[类型, 需要的活跃度, mod_daily缓存key], ...]
get_active_conf() -> [[1, 100, 7060], [2, 120, 7061], [3, 140, 7062]].
%% 魅力榜礼包 
get_charm_gift(1) -> 534052;
get_charm_gift(2) -> 534053;
get_charm_gift(3) -> 534054;
get_charm_gift(4) -> 534055.

%% --------- 元宵放花灯活动 --------- %%
%% 花灯常量配置
get_activity_lamp_config(Type) ->
	case Type of
		opentime -> [
					 util:unixtime({{2013, 1, 15}, {0, 0, 0}}),
			  		 util:unixtime({{2018, 2, 26}, {23, 59, 59}})
				    ];
		figurekeep -> 3*60*60;
		sendwish_max -> 15;
		goods_id_1 -> 522013;
		goods_id_2 -> 522014;
		goods_id_3 -> 522015;
		default_secne -> 102;
		wish_cd_time -> 3*60;
		_Other -> 0
	end.

%% 花灯系列奖励 [燃放经验,前往祝福经验,祝福值上限,收获花灯获得的物品]
get_activity_lamp_award(1) ->
	[50000, {10000,534226}, 15, 534223];
get_activity_lamp_award(2) ->
	[100000, {30000,534227}, 30, 534224];
get_activity_lamp_award(3) ->
	[200000, {50000,534228}, 45, 534225];
get_activity_lamp_award(_) ->
	[].

%% 前往祝福花灯获得随机物品 [物品Id, 概率]
get_activity_lamp_wish() ->
	[
	[43523, 25],
	[43524, 45],
	[43525, 30]
	].

%% 跨服战力活动
get_kf_power_config(Type) ->
	case Type of
		level -> 50;			%% 入跨服榜要求等级数
		power -> 15000;			%% 入跨服榜要求的战力值
		award_power -> 25000;	%% 发奖励最少需要的战力
		rank_num -> 100;		%% 排行榜记录限制数
		cache_time -> 300;		%% 排行数据在游戏线中缓存时间(秒)
		%% TODO
		%%cache_time -> 3;	%% 排行数据在游戏线中缓存时间(秒)
		%% 跨服榜奖励, 格式: {编号, 要求战力, 礼包id}
		power_gift -> [{25000, 534253}, {35000, 534254}, {45000, 534255}];
		top_3_power -> 15000;	%% 本服前三要求战力
		top_3_gift -> [{1, 534249}, {2, 534250}, {3, 534251}];
		_ -> undefined
	end.

