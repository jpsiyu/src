%%%--------------------------------------
%%% @Module  : data_butterfly
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.6
%%% @Description: 捕蝴蝶活动
%%%--------------------------------------

-module(data_butterfly).
-include("butterfly.hrl").
-compile(export_all).

%% 进入场景要求的玩家等级
require_level() -> 40.

%% 房间人数上限
get_room_limit() -> 100.

%% 人数达到多少开下一个房间
get_create_room_limit() -> 95.

%% 房间上限，目前为10个房间
get_room_limitup() -> 10.

%% 获得积分上限
get_score_limitup() -> 1000.

%% 队员人员上限
get_member_num() -> 3.

%% 三职业有1.5倍积分
get_tree_career_rate() -> 1.5.

%% 活动时间：周二、四、六
require_activity_week() -> [2, 4, 6].

%% 活动时间：13:00 ~ 14:00
require_activity_time() -> [{13, 0}, {14, 0}].

%% 定时器在活动期广播时间间隔
timer_refresh_time() -> 60.

%% 获取boss刷新时间
get_refresh_boss_time(?BUTTERFLY_ORANGE_ID) -> 600;
get_refresh_boss_time(?BUTTERFLY_PURPLE_ID) -> 300;
get_refresh_boss_time(_) -> 600.

%% 取得场景id
get_sceneid() -> 450.

%% 获得场景坐标，从列表中随机获取一个坐标
%% {SceneId, X, Y}
get_scene() ->
	List = [{450, 17, 60}, {450, 36, 56}, {450, 52, 54}, {450, 42, 26}, {450, 21, 27}, {450, 8, 48}, {450, 21, 37}, {450, 34, 45}, {450, 44, 52}],
	util:list_rand(List).

%% 离开蝴蝶谷后出现的坐标
%%{SceneId, X, Y}
get_outer_scene() ->
	%{102, 113, 124}.
	{102, 103, 122}.

%% 获取boss刷出来的坐标
get_refresh_boss_position(?BUTTERFLY_ORANGE_ID) ->
	[{4, 43}, {13, 57}, {6, 24}, {18, 7}, {18, 24}, {26, 22}, {25, 42}, {40, 25}, {51, 18}, {56, 45}, {43, 50}, {35, 48}, {29, 59}, {27, 42}, {55, 62}, {31, 42}];
get_refresh_boss_position(?BUTTERFLY_PURPLE_ID) ->
	[{27,59}, {29,61}, {38,65}, {44,71}, {48,72}, {52,65}, {49,57}, {58,56}, {53,51}, {47,48}, {39,49}, {34,47}, 
	 {22,44}, {15,42}, {7,41}, {5,30}, {8,21}, {16,17}, {23,21}, {29,22}, {33,34}, {39,32}, {45,26}, {36,25}, 
	 {30,27}, {25,24}, {19,27}, {17,40}, {17,40}, {31,43}, {39,46}, {40,60}, {50,50}, {31,57}, {24,56}, {20,61}];
get_refresh_boss_position(_) -> [].

%% 初始时boss的出现数量
get_refresh_boss_num(?BUTTERFLY_ORANGE_ID) -> 2;
get_refresh_boss_num(?BUTTERFLY_PURPLE_ID) -> 8;
get_refresh_boss_num(_) -> 0.

%% 获得橙色蝴蝶刷新坐标
get_boss_position(MonId) ->
	List = get_refresh_boss_position(MonId),
	util:list_rand(List).

%% 获得怪物ID列表
get_mon_ids() ->
	[10010, 10011, 10012, 10013, 10014].

%% 蝴蝶所属积分
get_butterfly_score(10010) -> 2;
get_butterfly_score(10011) -> 5;
get_butterfly_score(10012) -> 10;
get_butterfly_score(10013) -> 25;
get_butterfly_score(10014) -> 100;
get_butterfly_score(_) -> 0.

%% 怪物id对应索引
get_butterfly_index(10010) -> 1;
get_butterfly_index(10011) -> 2;
get_butterfly_index(10012) -> 3;
get_butterfly_index(10013) -> 4;
get_butterfly_index(10014) -> 5.

%% 计算经验
get_exp(LV, Score) ->
	round(LV * LV * Score * 0.75).

%% 计算历练声望
get_llpt(LV, Score) ->
	round((100 - math:pow((10 - LV * 0.1), 2)) *  0.05 * Score).

%% 阶段奖励需要的蝴蝶的数量
%% 格式：{[橙色蝴蝶的数量, 紫色蝴蝶的数量, ...], 第几等奖}
get_step_award_data() ->
	[
		{[2, 6, 20, 30, 50], 1},
        {[1, 3, 15, 25, 40], 2},
        {[0, 1, 10, 20, 30], 3},
        {[0, 0, 5, 15, 20], 4}
	].

%% 第几等奖对应的物品及数量
%% 格式：[物品id, 物品数量]
get_step_award(1) -> [522001, 4];
get_step_award(2) -> [522001, 3];
get_step_award(3) -> [522001, 2];
get_step_award(4) -> [522001, 1];
get_step_award(_) -> [].

%% 获取蝴蝶掉落的概率
%% MonId : 蝴蝶怪物id
%% ItemType : 道具类型，1加速符，2减速符，3双倍积分符
%% 返回 : 概率百分比
get_item_rate(10010, 1) -> 3;	
get_item_rate(10010, 2) -> 3;
get_item_rate(10010, 3) -> 3;
get_item_rate(10011, 1) -> 8;
get_item_rate(10011, 2) -> 8;
get_item_rate(10011, 3) -> 5;
get_item_rate(10012, 1) -> 15;
get_item_rate(10012, 2) -> 15;
get_item_rate(10012, 3) -> 10;
get_item_rate(10013, 1) -> 30;
get_item_rate(10013, 2) -> 30;
get_item_rate(10013, 3) -> 15;
get_item_rate(10014, 1) -> 50;
get_item_rate(10014, 2) -> 50;
get_item_rate(10014, 3) -> 50;
get_item_rate(_, _) -> 0.

%% 获得满积分抽奖概率配置
%% [{概率范围最低值, 概率范围最高值, 抽奖数字}]
get_max_score_award_rate() ->
	[{1, 5, 6}, {6, 15, 5}, {16, 30, 4}, {31, 45, 3}, {46, 70, 2}, {31, 100, 1}].

%% 获得最高分数翻牌奖励
%% [物品id, 数量, 绑定(1是，0否)]
get_max_score_award(1) -> [522001, 1, 2]; 
get_max_score_award(2) -> [522001, 2, 2];
get_max_score_award(3) -> [522001, 3, 2];
get_max_score_award(4) -> [522001, 1, 0];
get_max_score_award(5) -> [522001, 2, 0];
get_max_score_award(6) -> [522001, 3, 0];
get_max_score_award(_) -> false.

%% 白绿蓝色蝴蝶的生成坐标
%% {怪物id, X坐标，Y坐标}
get_mon_position() ->
	[{10011,  45,  43},
	{10011,  18,  28},
	{10012,  27,  19},
	{10010,  45,  63},
	{10011,  9,  16},
	{10010,  5,  18},
	{10010,  58,  28},
	{10011,  20,  37},
	{10012,  53,  32},
	{10012,  47,  56},
	{10011,  45,  72},
	{10011,  49,  32},
	{10010,  41,  43},
	{10010,  9,  22},
	{10010,  46,  51},
	{10011,  7,  31},
	{10010,  16,  36},
	{10010,  21,  30},
	{10011,  56,  58},
	{10011,  13,  40},
	{10010,  24,  21},
	{10011,  7,  48},
	{10012,  49,  79},
	{10011,  14,  12},
	{10010,  15,  27},
	{10010,  12,  15},
	{10010,  51,  27},
	{10010,  42,  71},
	{10011,  42,  17},
	{10010,  39,  26},
	{10011,  35,  16},
	{10012,  15,  59},
	{10010,  30,  16},
	{10010,  4,  48},
	{10010,  26,  56},
	{10010,  36,  49},
	{10010,  25,  67},
	{10010,  54,  50},
	{10012,  37,  19},
	{10010,  51,  73},
	{10010,  55,  20},
	{10010,  5,  28},
	{10010,  41,  56},
	{10012,  33,  50},
	{10010,  45,  20},
	{10011,  27,  47},
	{10010,  25,  13},
	{10011,  6,  41},
	{10011,  32,  31},
	{10010,  9,  44},
	{10010,  54,  39},
	{10011,  50,  18},
	{10011,  38,  34},
	{10010,  9,  63},
	{10012,  17,  13},
	{10010,  13,  62},
	{10010,  56,  68},
	{10011,  51,  43},
	{10011,  10,  49},
	{10012,  24,  32},
	{10010,  16,  9},
	{10010,  28,  35},
	{10012,  6,  24},
	{10011,  35,  41},
	{10011,  21,  14},
	{10011,  30,  62},
	{10012,  41,  63},
	{10010,  11,  28},
	{10011,  49,  68},
	{10012,  48,  43},
	{10010,  21,  8},
	{10012,  58,  52},
	{10010,  6,  68},
	{10010,  9,  36},
	{10010,  16,  18},
	{10010,  51,  60},
	{10010,  4,  60},
	{10012,  11,  57},
	{10011,  58,  46},
	{10011,  25,  27},
	{10010,  44,  31},
	{10012,  47,  25},
	{10011,  23,  66},
	{10011,  50,  51},
	{10010,  31,  45},
	{10012,  38,  40},
	{10011,  13,  32},
	{10010,  47,  39},
	{10010,  33,  58},
	{10011,  37,  55},
	{10010,  35,  24},
	{10010,  29,  26},
	{10010,  18,  55},
	{10012,  61,  27},
	{10010,  34,  35},
	{10010,  59,  61},
	{10010,  19,  22},
	{10010,  13,  51},
	{10010,  4,  37},
	{10011,  32,  22},
	{10011,  28,  40},
	{10012,  22,  42},
	{10011,  40,  50},
	{10011,  16,  51},
	{10010,  16,  69},
	{10010,  22,  48},
	{10012,  34,  65},
	{10011,  22,  20},
	{10010,  19,  64},
	{10010,  25,  40},
	{10010,  16,  44},
	{10011,  34,  71},
	{10011,  60,  20},
	{10010,  39,  17},
	{10011,  30,  51},
	{10010,  61,  50},
	{10012,  36,  29},
	{10010,  37,  64},
	{10011,  22,  58},
	{10011,  7,  56}].