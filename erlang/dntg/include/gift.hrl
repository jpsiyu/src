%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.3
%%% @Description: 礼包头文件
%%%--------------------------------------

%% 活动礼包
-define(ETS_GIFT, ets_gift2).
%% 礼包缓存key
-define(GIFT_CACHE_KEY(RoleId, GiftId), lists:concat(["fetch_gift_", RoleId, "_", GiftId])).

-define(FIRST_RECHARGE_GIFT_ID, 532001). 	%% 首充礼包ID
-define(NEWER_CARD_GIFT_ID, 531901). 		%% 新手卡礼包ID
-define(PET_LEVEL_GIFT_ID, 531601).				%% 新手宠物礼包ID
-define(MOUNT_LEVEL_GIFT_ID, 531602).		%% 新手坐骑礼包ID
-define(FRIENDID_GIFT_ID, 531603).					%% 好友礼包ID
-define(MODULE_OPEN_TAOBAO, 531611). 	%% 新手淘宝礼包
-define(MODULE_OPEN_LIANLU, 531610). 		%% 新手炼炉礼包 
-define(MODULE_OPEN_STONE, 531609). 		%% 新手宝石礼包 
-define(MODULE_OPEN_STREN, 531608). 		%% 新手铸造礼包
-define(MODULE_OPEN_DAILY, 531607). 		%% 新手日常礼包
-define(MODULE_OPEN_MARKET, 531606). 	%% 新手市场礼包 
-define(MODULE_OPEN_GUILD, 531605). 		%% 新手帮派礼包
-define(MODULE_OPEN_MIND, 531604). 		%% 新手元神礼包
-define(LEVEL_10_GIFT_ID, 1003).						%% 10级成长礼包ID
-define(MOBILE_GIFT_ID, 1000000). 					%% 手机绑定礼包（暂定）
-define(OTHER_GIFT_ID, 1000001).					%% 其他礼包（暂定）

-define(ERROR_GIFT_100, 100).							%% 礼包数据不存在
-define(ERROR_GIFT_101, 101).							%% 礼包状态为无效
-define(ERROR_GIFT_102, 102).							%% 未到领取礼包时间
-define(ERROR_GIFT_103, 103).							%% 已过了领取礼包时间
-define(ERROR_GIFT_104, 104).							%% 物品不存在
-define(ERROR_GIFT_105, 105).							%% 背包格子不足
-define(ERROR_GIFT_999, 999).							%% 领取礼包失败

%% 插入一条记录到礼包表gift_list
-define(SQL_GIFT_LIST_INSERT, <<"REPLACE INTO `gift_list` SET player_id=~p, gift_id=~p, give_time=~p, get_time=~p, get_num=~p, status=~p">>).
%% 更新为已经领取礼包
-define(SQL_GIFT_LIST_UPDATE_TO_RECEIVED, <<"UPDATE `gift_list` SET get_num=get_num+1, get_time=~p, status=1 WHERE player_id=~p AND gift_id=~p">>).
%% 查询一条记录：通过玩家ID和礼包ID
-define(SQL_GIFT_LIST_FETCH_ROW, <<"SELECT player_id, gift_id, status FROM `gift_list` WHERE player_id=~p AND gift_id=~p LIMIT 1">>).
%% 查询几条记录：通过玩家ID和礼包ID
-define(SQL_GIFT_LIST_FETCH_MUTIL_ROW, <<"SELECT player_id, gift_id, status FROM `gift_list` WHERE player_id=~p AND gift_id IN(~s)">>).
%% 查询玩家所有礼包记录
-define(SQL_GIFT_FETCH_ALL, <<"SELECT gift_id, give_time, get_num, get_time, offline_time, status FROM `gift_list` WHERE player_id=~p">>).
%% 查询在线倒计时礼包数据
-define(SQL_GIFT_FETCH_ONLINE, <<"SELECT gift_id, give_time, get_num, get_time, offline_time, status FROM `gift_list` WHERE player_id=~p">>).

%%礼包配置表
-record(ets_gift, {
	id,					%% 礼包ID
	name,				%% 礼包名称
	goods_id,			%% 物品类型ID
	get_way,			%% 领取方式，1放到背包，2直接领取
	gift_rand,			%% 礼包随机物品个数，0为固定，1为随机，2为列表随机
	gifts,				%% 礼包内容
	bind,				%% 绑定状态，0非绑，1使用后绑定，2绑定
	start_time,			%% 有效开始时间
	end_time,			%% 有效结束时间
	tv_goods_id = [],	%% 需要传闻的物品id。打开礼包时如果开到这些物品，会发传闻
	status				%% 状态，1有效，0无效
}).

%%活动礼包配置表
-record(ets_gift2, {
	id = 0,                 		%% 活动礼包ID
	name = <<>>,   		%% 活动礼包名称
	url = <<>>,        		%% 活动跳转URL
	bind=0,               	%% 绑定状态
	lv=0,                   		%% 等级需求
	coin=0,                	%% 铜钱
	bcoin=0,              	%% 绑定铜钱
	gold=0,                	%% 元宝
	bgold=0,              	%% 绑定元宝
	goods_list = [],     	%% 礼包内容
	is_show = 1,          	%% 是否显示礼包内容
	time_start=0,         	%% 活动开始时间
	time_end=0,          	%% 活动结束时间
	status=0             		%% 状态
}).