%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-27
%% Description: 商城 和神秘商店ets
%% --------------------------------------------------------

-define(ETS_LIMIT_SHOP, ets_limit_shop).        %% 限时购买
-define(POS_ONE, 1).                            %% 热卖1
-define(POS_TWO, 2).                            %% 热卖2
-define(POS_THREE, 3).                          %% 热卖3
-define(OPEN_DAYS, 3).                          %% 开服天数
-define(MERGE_DAYS, 1).				%% 合服天数
-define(THREE_HOUR, 10800).                     %% 3 小时

-define(sql_insert_secret, <<"insert into `secret_shop` set `role_id`=~p, `num`=~p, `count`=~p, `goods_list`='~s', lim_goods='~s', `time`=~p, `free_time`=~p">>).
-define(sql_update_secret, <<"update `secret_shop` set `num`=~p, `count`=~p, `goods_list`='~s', `time`=~p, `free_time`=~p  where `role_id`=~p">>).
-define(sql_update_secret2, <<"update `secret_shop` set `goods_list`='~s', lim_goods='~s', `time`=~p where `role_id`=~p">>).
-define(sql_select_secret, <<"select `role_id`,`num`,`count`,`goods_list`,`lim_goods`,`time`, `free_time` from `secret_shop` where `role_id`=~p">>).
-define(sql_del_secret, <<"delete from secret_shop where role_id = ~p">>).

%% 热买记录
-define(sql_select_limit, <<"select `pos1`, `pos2`, `pos3` from `limit_record` where `pid` = ~p">>).

%%商店表
-record(ets_shop, {
        id,             %% 编号
        shop_type=0,    %% 商店类型，1为商城，2为武器店，3为防具店，5为杂货店
        shop_subtype=0, %% 商店子类型，如商城的子类：1 新品上市，9 限时热卖
        goods_id=0,     %% 物品类型ID
        goods_num=0,    %% 物品出售数量，只对限时热卖有效
        new_price=0     %% 新价
    }).

%% 限时热卖
-record(ets_limit_shop, {
        id,                 %% 编号
        shop_id = 0,        %% 商店格子位置
        mark_name = [],     %% 配置的备注名字
        goods_id = 0,       %% 出售道具的ID
        goods_name = [],    %% 根据上面道具ID读取道具的名字
        goods_num = 0,      %% 每天出售的道具数量上限
        price_type = 0,     %% 价格类型：1元宝、2绑定元宝
        old_price = 0,      %% 参考价格
        new_price = 0,      %% 出售的最终价格
        price_list = [],    %% 配置商店道具价格是否会随便库存数量发生变化
                            %% 如果存在该配置，则道具出售价格按该配置结算；否则按出售新价结算
        list_id = 0,        %% 物品列表id
        refresh = 0,        %% 优惠商店是否在晚上0点重置每日出售数量 1:是
        limit_id = 0,       %% 限购id
        limit_num = 0,      %% 限购数量
        unlimited = 0,      %% 0:未配置, 1:配置后，道具出售数量减少到5时，则不再减少
        time_begin = 0,     %% 新服开始
        time_end = 0,       %% 新服结束
        activity_begin = 0, %% 活动开始
        activity_end = 0,   %% 活动结束
	  merge_begin = 0,  %% 合服开始
	  merge_end = 0	    %% 合服结束
    }).

%% 神秘商店配置
-record(base_secret_shop, {
        goods_id = 0,           %% 物品类型ID
        price_type = 0,         %% 价格类型, 1元宝, 2绑定元宝, 3铜币
        price = 0,              %% 物品价格
        bind = 0,               %% 绑定状态，2已绑定
        notice = 0,             %% 公告类型，1全服公告
        min_lv = 0,             %% 最小等级
        max_lv = 0,             %% 最大等级
        ratio_start=0,          %% 机率开始值
        ratio_end=0,            %% 机率结束值
        lim_min = 0,            %% 最少刷新次数限制
        goods_num = 0          %% 物品数量,
    }).

%% 财神商店配置
-record(base_dungeon_shop, {
        goods_id = 0,           %% 物品类型ID
        price_type = 0,         %% 价格类型, 1元宝, 2绑定元宝, 3铜币
        price = 0,              %% 物品价格
        bind = 0,               %% 绑定状态，2已绑定
		buy_scene = 0,          %% 购买场景限制
        limit_num = 0,          %% 购买数量限制
        order = 0               %% 排序
    }).

%% 神秘商店ETS
-record(ets_secret_shop, {
        role_id = 0,            %% 玩家id
        count = 0,              %% 刷新次数
        num = 0,                %% 单次刷新数
        goods_list = [],        %% 物品列表
        lim_goods = [],         %% 限制物品列表：[{物品ID,限制数},...]
        free_time = 3,          %% 免费刷新次数
        time = 0                %% 更新时间
     }).

-record(state, {notice, dict}).


