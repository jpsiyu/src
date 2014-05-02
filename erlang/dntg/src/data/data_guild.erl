%%%---------------------------------------
%%% @Module  : data_guild
%%% @Author  : shebiao
%%% @Email   : shebiao@jieyou.com
%%% @Created : 2010-06-24
%%% @Description:  帮派配置
%%%---------------------------------------
-module(data_guild).
-include("guild.hrl").
-include("predefine.hrl").
-compile(export_all).

%% 帮派基本配置信息 
get_guild_config(Type, _Args) ->
    case Type of
        % 创建帮派最小等级
        create_level ->                    24;
        % 创建帮派所需铜币
        create_coin  ->                    50000;
        % 帮派建设卡
        contribution_card  ->              [41, 10];
        % 帮派令
        guild_token  ->                    [41, 11, 1];
        % 弹劾令
        impeach_chief_token ->             [41, 14];
        % 集结令
        gather_member_token ->             [41, 15];
        % 解散确认天数
        disband_confirm_day ->             3;
        % 加入时的默认职位
        default_position ->                5;
        % 捐1000铜币所得帮贡
        donate_money_ratio ->              10;
        % 捐1张建设卡所得帮贡
        donate_contribution_card_ratio ->  10;
        % 升级厢房1个元宝所得帮贡
        donate_house_gold_ratio ->         10;
        % 捐1张建设卡所得建设
        contribution_card_ratio ->         100;
        % 增加1个帮贡获得的日福利
        paid_donate_ration ->              10;
        % 解散确认过期天数
        disband_expired_day ->             3;
        % 创建帮派后免收建设费的天数
        contribution_free_day ->           3;
        % 降为0级后的解散延迟天数
        disband_lv0_delay_day  ->          3;
        % 帮派仓库每天最大存入次数
        depot_max_store_num  ->            3;
        % 帮派仓库取出物品消耗的帮贡
        depot_take_out_donation ->         10;
        % 帮派大厅进入间隔
        hall_enter_interval_time ->        600;
        % 最大申请人数
        apply_max_num ->                   30;
        % 厢房最高等级
        max_house_level ->                 5;
        % 帮主不在线被弹劾的天数
        impeach_chief_day ->               3;
        % 帮派事件保留天数
        guild_event_clean_day ->           3;
        % 创建帮派礼包
        create_bag ->                      411312;
        % 帮派改名元宝
        rename_gold ->                     100;
        % 帮主召唤间隔
        gather_member_interval ->          900
    end.

%% 职位说明
get_position_define(Position) ->
    PositionDefineInfo =
        [
	        {1, "帮主"},
	        {2, "副帮主"},
	        {3, "长老"},
	        {4, "堂主"},
	        {5, "帮众"}
        ],
    {value, {_, PositionDefine}}  = lists:keysearch(Position, 1, PositionDefineInfo),
    PositionDefine.

  
% 日福利{帮派等级,[帮主日福利,副帮主日福利,长老日福利,堂主日福利,帮主日福利]}
%% @
get_paid_daily(Level, Position) ->
    data_guild_auto:get_paid_daily(Level, Position).

% 级别信息{帮派等级, 成员数量上限, 帮派建设上限, 每日建设}
% 注意：最高级别为10级，为了程序方便10级消耗设置较大值。
%% @
get_level_info(Level) ->
    data_guild_auto:get_level_info(Level).


%% 获取帮派建筑相关信息 
%% @
get_build_info(New_Build_Level, BuildType, OptionType) ->
	case [BuildType, OptionType] of
		[1, _] ->
			%% 神炉_帮主
			get_furnace_info(New_Build_Level);
		[2, 0] ->
			%% 商城_查询升级帮派商城消耗
			get_mall_upgrade_cost(New_Build_Level);
		[2, 1] ->
			%% 商城_帮派商城每天消耗
			get_mall_daily_cost(New_Build_Level);
		[2, 2] ->
			%% 商城_商城兑换物品配置
			get_guild_mall_goods_list();
		[3, _] ->
			%% 仓库_帮主
			get_depot_info(New_Build_Level);
		[4, 0] ->
			%% 祭坛_帮派祭坛信息
			get_altar_info(New_Build_Level);
		[4, 1] ->
			%% 祭坛_帮派祭坛物品
			skip;
		[5, _] ->
			%% 厢房升级_帮派厢房最高等级_帮派厢房升级消耗元宝
			[get_guild_config(max_house_level, []), get_house_uprade_gold(New_Build_Level)];
		_ ->
			error
	end.

% 仓库信息{仓库等级, 仓库大小, 升级所需铜币, 升级所需帮派贡献}
% 注意：最高级别为10级，为了程序方便定义了11级，消耗设置较大值。
%% @
get_depot_info(Level) ->
    {_, _, _, _PositonLimit, Contribution, Coin, _Gold, Num, _, _, _, _, _} = data_guild_auto:get_build_base_info(4, Level),
    [Num, Coin, Contribution].

%% 帮派厢房升级消耗_元宝
%% @
get_house_uprade_gold(Level) ->
    {_, _, _, _PositonLimit, _, _, Gold, _, _, _, _, _, _} = data_guild_auto:get_build_base_info(6, Level),
    Gold.

%% 帮派祭坛信息{日常ID, 祭坛等级, 使用次数, 使用一次消耗的帮派贡献, 升级所需铜币, 升级所需帮派贡献}
%% 帮派祭坛 最高10级，为了程序方便定义了11级，消耗设置较大值。
%% @%% @%% @%% @
get_altar_info(Level) ->
	{_, _, _, _PositonLimit, Contribution, Coin, _Gold, Num, _, _, _, _, _} = data_guild_auto:get_build_base_info(5, Level),
	MaterialCost = data_guild_auto:get_altar_pray(Level),
	Daily_Type_ID = 4007801,
    [Daily_Type_ID, Level, Num, MaterialCost, Coin, Contribution].

%% 神炉信息{神炉等级, 神炉附加成功率, 升级所需铜币, 升级所需帮派贡献}
%% 注意：最高级别为10级，为了程序方便定义了11级，消耗设置较大值。
%% @%% @
get_furnace_info(Level)->
	{_, _, _, _PositonLimit, Contribution, Coin, _Gold, Num, _, _, _, _, _} = data_guild_auto:get_build_base_info(2, Level),
    [Num, Coin, Contribution].

%% 查询升级帮派商城消耗（[建设度消耗，资金消耗]）
get_mall_upgrade_cost(Level) ->
	{_, _, _, _PositonLimit, Contribution, Coin, _Gold, _Num, _, _, _, _, _} = data_guild_auto:get_build_base_info(3, Level),
    [Contribution, Coin].

%% 帮派商城每天消耗（[建设度消耗，资金消耗]）
%% @%% @%% @%% @
get_mall_daily_cost(MallLevel) ->
    case MallLevel < 6 of
        true -> [0, 0];
        false ->
            [ContributionCost, _FundsCost] = get_mall_upgrade_cost(MallLevel - 1),
            [round(ContributionCost * 0.05), 0] %[round(ContributionCost * 0.035), round(FundsCost * 0.035)]
    end.

%% 获取帮派祭坛宝箱
%% @
get_altar_goods() ->
	data_guild_auto:get_altar_goods().

%% 商城兑换物品配置
%% 物品类型Id，单位数量所需财富，财富类型，单位数量，各等级商城每人每天最多兑换数，DailyType，等级区间
%% @
get_guild_mall_goods_list() ->
	data_guild_auto:get_guild_mall_goods_list().

%% 远征目标_目标编号_目标最大级别_目标类型
%% @%% @%% @%% @
get_guild_achieve_info_data(Type, SearchType) ->
	TupleList =
        [
	        {10001 , 3, 1},
	        {10002 , 3, 1},
	        {10003 , 3, 1},
	        {10004 , 3, 1},
	        {10005 , 3, 1}
        ],
	F = fun(Element_1, Type_1, SearchType_1) ->
				if 
					erlang:element(SearchType_1, Element_1) == Type_1->
						true;
					true ->
						false
				end
	end,
	Result = lists:filter(fun(X) -> F(X, Type, SearchType) end, TupleList),
	Result.

%% 条件1数量 条件2数量 奖励帮派资金	 奖励帮派建设	 奖励完成帮众财富 奖励完成帮众贡献
%% @%% @%% @
get_guild_achieve_more_data(FullType)->
	if
		FullType =:= 100011  -> [6	,0	,100000	,10000	,0	,0];
		FullType =:= 100021  -> [10	,0	,100000	,10000	,0	,0];
		FullType =:= 100031  -> [10	,0	,100000	,10000	,0	,0];
		FullType =:= 100041  -> [10	,0	,100000	,10000	,0	,0];
		FullType =:= 100051  -> [10	,0	,100000	,10000	,0	,0]
	end.

%% 获取技能列表1
%% @%% @%% @
get_guild_skill_all() ->
	_TupleList =
        [
			{100011, 10001,	1,	1,	100,	1},
			{100012, 10001,	2,	4,	2000,	3},
			{100013, 10001,	3,	8,	15000,	5},
			{100014, 10001,	4,	10,	80000,	8},
			{100021, 10002,	1,	2,	500,	3},
			{100022, 10002,	2,	4,	10000,	5},
			{100023, 10002,	3,	6,	50000,	7},
			{100024, 10002,	4,	8,	80000,	10},
			{100031, 10003,	1,	3,	500,	5},
			{100032, 10003,	2,	5,	5000,	10},
			{100033, 10003,	3,	7,	30000,	15},
			{100034, 10003,	4,	9,	70000,	20},
			{100035, 10003,	5,	10,	150000,	25},
			{100041, 10004,	1,	2,	800,	3},
			{100042, 10004,	2,	4,	4000,	5},
			{100043, 10004,	3,	6,	50000,	8},
			{100044, 10004,	4,	8,	100000,	10},
			{100051, 10005,	1,	4,	10000,	5},
			{100052, 10005,	2,	8,	50000,	7},
			{100053, 10005,	3,	10,	120000,	10},
			{100061, 10006,	1,	2,	100,	3},
			{100062, 10006,	2,	4,	2000,	5},
			{100063, 10006,	3,	8,	15000,	7},
			{100064, 10006,	4,	10,	80000,	10},
			{100071, 10007,	1,	2,	100,	3},
			{100072, 10007,	2,	4,	2000,	5},
			{100073, 10007,	3,	8,	15000,	7},
			{100074, 10007,	4,	10,	80000,	10}
		].

%%	技能编号_技能等级_需求帮派等级_需求帮派贡献_加成比例
%% @%% @%% @
get_guild_skill_info(Condition, Search_Type) ->
	TupleList = get_guild_skill_all(),
	lists:keysearch(Condition, Search_Type, TupleList).

%%	获取帮派场景信息
%% @%% @%% @
get_guild_scene_info(Type) ->
	TupleList =
		[
		 	 {1, 105, 17, 19}			%% 宴会传送1
			,{2, 105, 17, 19}			%% 神兽传送1
			,{3, 105, 17, 19}			%% 宴会传送2
			,{0, 105, 17, 19}			%% 其他传送
		 ],
	{_, SceneId, X, Y} = lists:keyfind(Type, 1, TupleList),
	{SceneId, X, Y}.

get_guild_scene_out() ->
    {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
	{105, ?MAIN_CITY_SCENE, MainCityX, MainCityY}.

%%	获取帮派神兽相关信息
%% @
get_guild_godanimal_info(GA_Level) ->
	Galv = case GA_Level > ?GodAnimal_Level_Limit of
		true ->
			?GodAnimal_Level_Limit;
		false ->
			GA_Level
	end,
	data_guild_auto:get_guild_godanimal_info(Galv).


%% 获取帮宴刷怪坐标
get_party_point()->
	[ 
		{40,84},{34,82},{28,85},{25,90},
		{28,97},{34,100},{40,97},{42,91}
	].

%% 获取帮派仙宴物品与效果对应表
%% @return	增加气氛	限制个数	使用效果
get_party_good_ef(GoodTypeId) ->
	TupleList =
		[
			{412001, 10, 9999, 1}
			, {412002, 15, 9999, 2}
			, {412003, 50, 9999, 3}
			, {412004, 30, 6, 4}
			, {0, 20, 9999, 0} % 玩家进入帮宴增加的气氛
		],
	{_, MoodAdd, NumLimit, EfType} = lists:keyfind(GoodTypeId, 1, TupleList),
	{MoodAdd, NumLimit, EfType}.

%% 获取神兽类型ID
get_ga_mod_id(GAlevel)->
	TupleList =
		[
			{35, 10532, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {36, 10533, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {37, 10533, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {38, 10533, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {39, 10534, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {40, 10534, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {41, 10534, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {42, 10534, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {43, 10534, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {44, 10534, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {45, 10534, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {46, 10535, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {47, 10535, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {48, 10535, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {49, 10535, [342,442,101744,101844,601601,112231,112704,112201]}
			,  {50, 10535, [352,452,101754,101854,601601,112231,112704,112201]}
			,  {51, 10535, [352,452,101754,101854,601601,112231,112704,112201]}
			,  {52, 10535, [352,452,101754,101854,601601,112231,112704,112201]}
			,  {53, 10535, [352,452,101754,101854,601601,112231,112704,112201]}
			,  {54, 10535, [352,452,101754,101854,601601,112231,112704,112201]}
			,  {55, 10536, [352,452,101754,101854,601601,112231,112704,112201]}
			,  {56, 10536, [352,452,101754,101854,601601,112231,112704,112201]}
			,  {57, 10536, [352,452,101754,101854,601601,112231,112704,112201]}
			,  {58, 10536, [352,452,101754,101854,601601,112231,112704,112201]}
			,  {59, 10536, [352,452,101754,101854,601601,112231,112704,112201]}
			,  {60, 10536, [362,462,101764,101864,601602,112231,112705,112202]}
			,  {61, 10536, [362,462,101764,101864,601602,112231,112705,112202]}
			,  {62, 10536, [362,462,101764,101864,601602,112231,112705,112202]}
			,  {63, 10536, [362,462,101764,101864,601602,112231,112705,112202]}
			,  {64, 10536, [362,462,101764,101864,601602,112231,112705,112202]}
			,  {65, 10536, [362,462,101764,101864,601602,112231,112705,112202]}
		],
	{_, GAid, GiftList} = lists:keyfind(GAlevel, 1, TupleList),
	{GAid, GiftList}.


%% 获取帮派宴会消耗
%% @return	帮派财富 元宝 铜币
get_party_cost(ParytType) ->
%%	TupleList =
%%		[
%%			{1, 200, 0, 100000}
%%			, {2, 100, 88, 0}
%%			, {3, 0, 288, 0}
%%		],
	TupleList =
		[
			{1, 0, 0, 0}
			, {2, 0, 88, 0}
			, {3, 0, 288, 0}
		],
	{_, Fouds, Gold, Coins} = lists:keyfind(ParytType, 1, TupleList),
	{Fouds, Gold, Coins}.

%% 获取帮派宴会食物类型ID
%% @return	帮派财富 元宝 铜币
get_party_food_mid(ParytType) ->
	TupleList =
		[
			{1, 10050}
			, {2, 10051}
			, {3, 10052, 10053}
		],
	case lists:keyfind(ParytType, 1, TupleList) of
		{_, MonTypeId} ->			
			{MonTypeId};
		{_, MonTypeId1, MonTypeId2} ->
			{MonTypeId1, MonTypeId2};
		_ ->
			{0}
	end.

%% 获取升级宴会消耗
%% @return 元宝 
get_upgrade_party_cost(ParytType) ->
	case ParytType of
		2 -> 88;
		3 -> 188;
		_ -> 888
	end.

%% 帮派今日退帮需要限制的功能
get_guild_today_limit(Type) ->
	LimitSelf =
		[
%% 		 40016				%% 修改帮派公告
%% 		 , 40019			%% 捐献钱币
%% 		 , 40020			%% 捐献帮派建设卡
		  40023			%% 领取日福利
%% 		 , 40072			%% 捐献元宝
%% 		 , 40052			%% 使用弹劾令
%% 		 , 40053			%% 使用集结令
%% 		 , 40005			%% 审批加入
%% 		 , 40006			%% 邀请加入
%% 		 , 40008			%% 踢出帮派
%% 		 , 40009			%% 退出帮派
%% 		 , 40017			%% 职位设置
%% 		 , 40018			%% 帮主转让帮派
%% 		 , 40022			%% 辞去官职
%% 		 , 40025			%% 授予头衔
%% 		 , 40028			%% 帮派仓库存入物品
%% 		 , 40029			%% 帮派仓库取出物品
%% 		 , 40030			%% 帮派仓库删除物品
%% 		 , 40031			%% 新的帮派建筑升级
		 , 40035			%% 进入帮派场景
%% 		 , 40079			%% 帮派祭坛祈福1
%% 		 , 40080			%% 帮派神炉获取信息
%% 		 , 40092			%% 兑换帮派商城物品
%% 		 , 40082			%% 帮派目标领奖
%% 		 , 40094			%% 直接解散帮派
%% 		 , 40097			%% 帮主群发公告信息_弹窗_40000
		],
	LimitOther = 
		[
%% 		 40017			%% 职位设置
%% 		 , 40018			%% 帮主转让帮派
		],
	%% 获取限制
	case Type of
		0 -> %% 自己
			LimitSelf;
		1 -> %% 他人
			LimitOther;
		_ -> %% 错误的类型
			[]
	end.
	
get_qq_times_limit() ->
	[
		 40001				%% 创建帮派
		 , 40004			%% 申请加入
		 , 40005			%% 审批加入
		 , 40006			%% 邀请加入
		 , 40007			%% 邀请回应
		].

get_f_limit(FLevel) ->
	List = [100000, 200000, 300000, 400000, 500000, 600000, 700000, 800000, 900000, 1000000, 1100000, 1200000, 1300000, 1400000, 1500000],
	lists:nth(FLevel, List).

get_ga_pack_by_level(Galv) ->
	if
		Galv >= 35 andalso Galv < 50 ->
			[{101044, 1, 1},
			 {101049, 1, 1},
			 {101744, 1, 6},
			 {101844, 1, 6},
			 {101944, 1, 1},
			 {102044, 1, 1},
			 {102049, 1, 1},
			 {102944, 1, 1},
			 {103044, 1, 1},
			 {103049, 1, 1},
			 {103944, 1, 1},
			 {112231, 0, 400},
			 {112201, 0, 800},
			 {112704, 0, 400},
			 {601601, 0, 400}];
		Galv >= 50 andalso Galv < 60 ->
			[
			 {101054, 1, 1},
			 {101059, 1, 1},
			 {101754, 1, 6},
			 {101854, 1, 6},
			 {101954, 1, 1},
			 {102054, 1, 1},
			 {102059, 1, 1},
			 {102954, 1, 1},
			 {103054, 1, 1},
			 {103059, 1, 1},
			 {103954, 1, 1},
			 {112231, 0, 400},
			 {112201, 0, 600},
			 {112704, 0, 300},
			 {112202, 0, 200},
			 {112705, 0, 100},
			 {601601, 0, 400}
			];
		true ->
			[{101064, 1, 1},
			 {101069, 1, 1},
			 {101764, 1, 6},
			 {101864, 1, 6},
			 {101964, 1, 1},
			 {102064, 1, 1},
			 {102069, 1, 1},
			 {102964, 1, 1},
			 {103064, 1, 1},
			 {103069, 1, 1},
			 {103964, 1, 1},
			 {112231, 0, 400},
			 {112202, 0, 600},
			 {112705, 0, 300},
			 {112203, 0, 200},
			 {112706, 0, 100},
			 {601602, 0, 400}]
	end.

get_ga_pack_by_level_2(Galv) ->
	if
		Galv >= 35 andalso Galv < 50 ->
			[{101044, 1, 2},
			 {101049, 1, 2},
			 {101744, 1, 12},
			 {101844, 1, 12},
			 {101944, 1, 2},
			 {102044, 1, 2},
			 {102049, 1, 2},
			 {102944, 1, 2},
			 {103044, 1, 2},
			 {103049, 1, 2},
			 {103944, 1, 2},
			 {112231, 0, 700},
			 {112201, 0, 900},
			 {112704, 0, 600},
			 {601601, 0, 600}];
		Galv >= 50 andalso Galv < 60 ->
			[
			 {101054, 1, 2},
			 {101059, 1, 2},
			 {101754, 1, 12},
			 {101854, 1, 12},
			 {101954, 1, 2},
			 {102054, 1, 2},
			 {102059, 1, 2},
			 {102954, 1, 2},
			 {103054, 1, 2},
			 {103059, 1, 2},
			 {103954, 1, 2},
			 {112231, 0, 800},
			 {112201, 0, 600},
			 {112704, 0, 300},
			 {112202, 0, 400},
			 {112705, 0, 200},
			 {601601, 0, 600}
			];
		true ->
			[{101064, 1, 2},
			 {101069, 1, 2},
			 {101764, 1, 12},
			 {101864, 1, 12},
			 {101964, 1, 2},
			 {102064, 1, 2},
			 {102069, 1, 2},
			 {102964, 1, 2},
			 {103064, 1, 2},
			 {103069, 1, 2},
			 {103964, 1, 2},
			 {112231, 0, 800},
			 {112202, 0, 600},
			 {112705, 0, 300},
			 {112203, 0, 400},
			 {112706, 0, 200},
			 {601602, 0, 600}]
	end.
										
get_ga_chuanwen_list() ->
	[101044,101049,101744,101844,101944,102044,102049,102944,103044,103049,103944,112231,601601,101054,101059,101754,101854,101954,102054,102059,102954,103054,103059,103954,112231,112201,112704,112202,112705,601601,101064,101069,101764,101864,101964,102064,102069,102964,103064,103069,103964,112231,112706,601602].

get_yj_chuanwen_list() ->
	[601601,122504,112202,112705,112202,112706,112203].
