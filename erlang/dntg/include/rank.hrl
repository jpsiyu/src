%%%--------------------------------------
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.5.31
%%% @Description :  排行榜
%%%--------------------------------------

%% 本服排行榜分类
-define(RK_FAME, 1000).							%% 名人堂
-define(RK_PERSON_FIGHT, 1001).					%% 个人排行-战斗力榜
-define(RK_PERSON_LV, 1002).					%% 个人排行-等级榜
-define(RK_PERSON_WEALTH, 1003).				%% 个人排行-财富榜
-define(RK_PERSON_ACHIEVE, 1004).				%% 个人排行-成就榜
-define(RK_PERSON_REPUTATION, 1005).			%% 个人排行-仙府声望榜
-define(RK_PERSON_VEIN, 1006).					%% 个人排行-经脉榜
-define(RK_PERSON_HUANHUA, 1007).				%% 个人排行-宠物幻化榜
-define(RK_PERSON_CLOTHES, 1008).				%% 个人排行-着穿度
-define(RK_PET_FIGHT, 2001).					%% 宠物排行-战斗力榜
-define(RK_PET_GROW, 2002).						%% 宠物排行-成长榜
-define(RK_PET_LEVEL, 2003).					%% 宠物排行-等级榜
-define(RK_EQUIP_WEAPON, 3001).					%% 装备排行-武器榜
-define(RK_EQUIP_DEFENG, 3002).					%% 装备排行-防具榜
-define(RK_EQUIP_SHIPIN, 3003).					%% 装备排行-饰品榜
-define(RK_GUILD_LV, 4001).						%% 帮派排行-帮会榜
-define(RK_ARENA_DAY, 5001).					%% 竞技排行-每日上榜
-define(RK_ARENA_WEEK, 5002).					%% 竞技排行-每周上榜
-define(RK_ARENA_KILL, 5003).					%% 竞技排行-每周击杀榜
-define(RK_COPY_COIN, 6001).					%% 副本排行-铜钱副本
-define(RK_COPY_NINE, 6002).					%% 副本排行-九重天单人霸主
-define(RK_COPY_NINE2, 6003).					%% 副本排行-九重天多人霸主
-define(RK_COPY_TOWER, 6004).					%% 副本排行-塔防副本
-define(RK_CHARM_DAY_HUHUA, 7001).				%% 魅力排行-每日护花榜
-define(RK_CHARM_DAY_FLOWER, 7002).		        %% 魅力排行-每日鲜花榜
-define(RK_CHARM_HUHUA, 7003).					%% 魅力排行-护花榜
-define(RK_CHARM_FLOWER, 7004).					%% 魅力排行-鲜花榜
-define(RK_CHARM_HOTSPRING, 7005).				%% 魅力排行-沙滩魅力榜
-define(RK_KF_FLOWER_DAILY_MAN_L, 7011).		%% 跨服魅力排行榜本地数据
-define(RK_KF_FLOWER_DAILY_WOMEN_L, 7012).		%% 跨服魅力排行榜本地数据
-define(RK_KF_FLOWER_COUNT_MAN_L, 7013).		%% 跨服魅力排行榜本地数据
-define(RK_KF_FLOWER_COUNT_WOMEN_L, 7014).		%% 跨服魅力排行榜本地数据
-define(RK_FAME_COIN, 8001).					%% 限时名人堂排行-铜币榜
-define(RK_FAME_TAOBAO, 8002).		        	%% 限时名人堂排行-淘宝榜
-define(RK_FAME_EXP, 8003).						%% 限时名人堂排行-经验榜
-define(RK_FAME_PT, 8004).						%% 限时名人堂排行-历练榜
-define(RK_MOUNT_FIGHT, 9001).					%% 坐骑排行-战力榜
-define(RK_FLYER_POWER, 9002).					%% 飞行器战力

%% 定时器要刷新的排行榜编号，按功能优先级排序，从头到尾刷新，中间间隔N秒
-define(RK_TIMER_REFRESH_IDS, [
	7001,7002,1003,
	1000,1001,1002,1004,1005,1006,
	2001,2002,2003,3001,
	5001,5002,5003,
	6001,6002,6003,
	8001,8002,8003,8004,
	1007,1008,3002,3003,4001,6004,7003,7004,7005,9001,9002
]).

%% 各大分类对应的子榜id列表
-define(RK_TYPE_ROLE_LIST, [?RK_FAME, ?RK_PERSON_FIGHT, ?RK_PERSON_LV, ?RK_PERSON_WEALTH, 
	?RK_PERSON_ACHIEVE, ?RK_PERSON_REPUTATION, ?RK_PERSON_VEIN, ?RK_PERSON_HUANHUA, ?RK_PERSON_CLOTHES]).
-define(RK_TYPE_PET_LIST, [?RK_PET_FIGHT, ?RK_PET_GROW, ?RK_PET_LEVEL]).
-define(RK_TYPE_EQUIP_LIST, [?RK_EQUIP_WEAPON, ?RK_EQUIP_DEFENG, ?RK_EQUIP_SHIPIN]).
-define(RK_TYPE_GUILD_LIST, [?RK_GUILD_LV]).
-define(RK_TYPE_ARENA_LIST, [?RK_ARENA_DAY, ?RK_ARENA_WEEK, ?RK_ARENA_KILL]).
-define(RK_TYPE_COPY_LIST, [?RK_COPY_COIN, ?RK_COPY_NINE, ?RK_COPY_TOWER]).
-define(RK_TYPE_CHARM_LIST, [?RK_CHARM_DAY_HUHUA, ?RK_CHARM_DAY_FLOWER, ?RK_CHARM_HUHUA,
	?RK_CHARM_FLOWER, ?RK_CHARM_HOTSPRING]).
-define(RK_TYPE_MOUNT_LIST, [?RK_MOUNT_FIGHT, ?RK_FLYER_POWER]).
%% 可查看装备信息的角色排行榜
-define(ROLE_RANK_INFO_LIST, [
	?RK_FAME, ?RK_PERSON_FIGHT, ?RK_PERSON_LV, ?RK_PERSON_WEALTH, ?RK_PERSON_ACHIEVE, ?RK_PERSON_REPUTATION, 
	?RK_PERSON_VEIN, ?RK_PET_FIGHT, ?RK_PET_GROW, ?RK_PET_LEVEL, ?RK_FAME_COIN, ?RK_FAME_TAOBAO, ?RK_FAME_EXP,
	?RK_FAME_PT, ?RK_PERSON_HUANHUA, ?RK_PERSON_CLOTHES
]).
%% 排行榜名次限制
-define(NUM_LIMIT,  50).
%% 装备榜中武器，防具，饰品的分类
-define(RK_EQUIP_SUBTYPE, [10, 20, 21, 22, 23, 24, 25, 30, 32, 33]).
%% 装备榜中武器分类
-define(RK_EQUIP_WEAPON_SUBTYPE, [10]).
%% 装备榜中武器分类
-define(RK_EQUIP_DEFEND_SUBTYPE, [20, 21, 22, 23, 24, 25]).
%% 装备榜中饰品分类
-define(RK_EQUIP_SHIPIN_SUBTYPE, [30, 32, 33]).
%% 装备类型列表（数字含义见数据库——1武器，2防具，3饰品）
-define(EQUIP_RANK_TYPE_LIST, [1, 2, 3]).
-define(ETS_ROLE_RANK_INFO, ets_role_rank_info).
%% 战斗力排行第一玩家登录或切换场景发送传闻时间间隔
-define(RK_FIGHT_RANK_CW_TIME, 10800).
-define(EQUIP, 10).						%% 装备类型（base_goods.type）
-define(SPEC_ROLE_NUM, 50).			%% 需要展示装备信息的TOP角色数
%% 崇拜鄙视数据
-record(ets_role_rank_info, {
        role_id = 0,        			%% 角色Id
        popularity = [],    			%% 崇拜及鄙视信息
        stren7_num = 0,     			%% 全身强七以上装备信息
        equip_list = null,  			%% 身上装备Id列表，null表示未加载数据
        show_names = null   			%% 显示的称号列表，null表示未加载数据
    }).

%% 本服排行榜ets
-define(ETS_RANK, ets_rank).
-record(ets_rank, {
	type_id,					%% 排行类型ID
	rank_list					%% 排行信息列表
}).

%% 游戏节点中保存的跨服1v1，3v3排行缓存数据
-define(RK_KF_1V1_CACHE_RANK, ets_kf_1v1_cache_rank).
-record(ets_kf_1v1_cache_rank, {
	type_id = 0,				%% 排行类型ID
	update = 0,					%% 数据更新时间
	rank_list					%% 排行信息列表
}).

%% 游戏节点中保存的跨服排行缓存数据
-define(RK_KF_CACHE_RANK, ets_kf_cache_rank).
-record(ets_kf_cache_rank, {
	type_id = 0,				%% 排行类型ID
	update = 0,					%% 数据更新时间
	rank_list					%% 排行信息列表
}).

%% 本服模块用到的排行数据，区别于本服一般排行数据
-define(MODULE_RANK, ets_module_rank).
-record(ets_module_rank, {
	type_id = 0,				%% 排行类型ID，从下面的MODULE_RANK_n中获了以
	update = 0,					%% 数据更新时间
	rank_list = [],				%% 排行数据列表
	top_10 = []                 %% [斗战封神活动] 前10个人形象，格式为[{[Platform, ServerId, Id], Image}]
}).
-define(MODULE_RANK_1, 10).		%% 本地3v3周榜
-define(MODULE_RANK_2, 11).		%% 斗战封神活动


%% mod_rank 状态结构
-record(rank_state, {
	world_level = {0, 0}	%% 世界等级				
}).
