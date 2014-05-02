%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-13
%% Description: 物品装备定义
%% --------------------------------------------------------

-define(GOODS_LOC_GROUND,    0).     %% 地上
-define(GOODS_LOC_EQUIP,     1).     %% 装备位置
-define(GOODS_LOC_MOUNT,     2).     %% 坐骑装备位置
-define(GOODS_LOC_SELL,      3).     %% 交易市场
-define(GOODS_LOC_BAG,       4).     %% 背包位置
-define(GOODS_LOC_STORAGE,   5).     %% 仓库位置
-define(GOODS_LOC_GUILD,     6).     %% 帮派仓库位置
-define(GOODS_LOC_MAIL,      7).     %% 邮件附件位置
-define(GOODS_LOC_FASHION,   8).     %% 时装衣橱
-define(GOODS_LOC_CACHE,     [0,1,2,4,8]).    %% 需缓存的位置

-define(GOODS_BAG_MAX_NUM,          168).   %% 背包最大数
-define(GOODS_BAG_EXTEND_NUM,       25).    %% 背包扩展数
-define(GOODS_BAG_EXTEND_GOLD,      1000).  %% 背包扩展所需金币
-define(GOODS_STORAGE_MAX_NUM,      180).   %% 仓库最大数
-define(GOODS_STORAGE_EXTEND_NUM,   15).    %% 仓库扩展数
-define(GOODS_STORAGE_EXTEND_GOLD,  100).   %% 仓库扩展所需金币
-define(GOODS_GUILD_MAX_LEVEL,      10).    %% 帮派仓库最大等级
-define(GOODS_GUILD_EXTEND_MATERIAL,411001).%% 帮派建设卡类型ID
-define(GOODS_SELF_SELL_LIMIT,      30).    %% 挂售上限

-define(GOODS_TYPE_EQUIP,   10).    %% 类型 - 装备类
-define(GOODS_TYPE_STONE,   11).    %% 类型 - 宝石类
-define(GOODS_TYPE_RUNE,    12).    %% 类型 - 护符类
-define(GOODS_TYPE_SKILL,   13).    %% 类型 - 技能类
-define(GOODS_TYPE_DRUG,    20).    %% 类型 - 药品类
-define(GOODS_TYPE_BUFF,    21).    %% 类型 - BUFF状态类
-define(GOODS_TYPE_GAIN,    22).    %% 类型 - 增益类
-define(GOODS_TYPE_MERIDIAN,23).    %% 类型 - 经脉类
-define(GOODS_TYPE_MOUNT,   31).    %% 类型 - 坐骑类
-define(GOODS_TYPE_GUILD,   41).    %% 类型 - 帮派类
-define(GOODS_TYPE_TASK,    50).    %% 类型 - 任务类
-define(GOODS_TYPE_ACTIVICE,52).    %% 类型 - 活动类
-define(GOODS_TYPE_GIFT,    53).    %% 类型 - 礼包类
-define(GOODS_TYPE_ITEM,    60).    %% 类型 - 道具类
-define(GOODS_TYPE_OBJECT,  61).    %% 类型 - 特殊类
-define(GOODS_TYPE_PET,     62).    %% 类型 - 宠物类
-define(GOODS_TYPE_VIP,     63).    %% 类型 - VIP类
-define(GOODS_TYPE_PRODUCE, 64).    %% 类型 - 生产类
-define(GOODS_TYPE_CALL,    65).    %% 类型 - 召唤类
-define(GOODS_TYPE_COMPOSE, 67).    %% 类型 - 合成类
-define(GOODS_TYPE_ANQI,    68).    %% 类型 - 暗器类
-define(GOODS_TYPE_FLY,     69).    %% 类型 - 飞行类

-define(GOODS_SUBTYPE_EXP,          10).    %% 子类型 - 经验卡
-define(GOODS_SUBTYPE_COIN,         11).    %% 子类型 - 铜钱卡
-define(GOODS_SUBTYPE_LLPT,         12).    %% 子类型 - 历练声望卡
-define(GOODS_SUBTYPE_XWPT,         13).    %% 子类型 - 修为声望卡
-define(GOODS_SUBTYPE_WHPT,         15).    %% 武魂丹
-define(GOODS_SUBTYPE_TP,           10).    %% 子类型 - 主城回城卷

-define(GOODS_SUBTYPE_FASHION,      60).    %% 子类型 - 衣服时装
-define(GOODS_SUBTYPE_ARMOR_CHA,    17).    %% 子类型 - 衣服形象转换
-define(GOODS_SUBTYPE_WEAPON_CHA,   18).    %% 子类型 - 武器形象转换
-define(GOODS_SUBTYPE_ACCE_CHA,     19).    %% 子类型 - 饰品形象转换
-define(GOODS_SUBTYPE_HEAD_CHA,     38).    %% 子类型 - 头饰形象转换
-define(GOODS_SUBTYPE_TAIL_CHA,     39).    %% 子类型 - 尾饰形象转换
-define(GOODS_SUBTYPE_RING_CHA,     40).    %% 子类型 - 戒指形象转换

-define(GOODS_SUBTYPE_MOUTN_FIGURE, 15).    %% 子类型 - 坐骑变身
-define(GOODS_SUBTYPE_CHENGHAO, 21).    	%% 子类型 - 产生称号

-define(GOODS_SUBTYPE_RECHARGE,     1).     %% 加元宝
-define(GOODS_SUBTYPE_HP,           1).     %% 子类型 - 气血
-define(GOODS_SUBTYPE_MP,           2).     %% 子类型 - 内力
-define(GOODS_SUBTYPE_HP_BAG,       5).     %% 子类型 - 气血包
-define(GOODS_SUBTYPE_MP_BAG,       6).     %% 子类型 - 内力包
-define(GOODS_SUBTYPE_GIFT_GROW,    10).    %% 子类型 - 成长礼包
-define(GOODS_SUBTYPE_GIFT_ONLINE,  12).    %% 子类型 - 在线礼包
-define(GOODS_SUBTYPE_GIFT_GOAL,    16).    %% 子类型 - 目标礼包
-define(GOODS_SUBTYPE_GIFT_VIP,     17).    %% 子类型 - 红包
-define(GOODS_SUBTYPE_SKILL,        10).    %% 子类型 - 技能书
-define(GOODS_SUBTYPE_WEDDING_RING, 70).    %% 子类型 - 结婚介指
-define(GOODS_SUBTYPE_PHYSICAL,     27).    %% 子类型 - 体力值
-define(GOODS_SUBTYPE_GOLD,         28).    %% 子类型 - 名罪金牌
-define(GOODS_SUBTYPE_BCOIN,        26).    %% 子类型 - 绑定铜钱
-define(GOODS_SUBTYPE_GUARD_RUNE,   25).    %% 子类型 - 保护符
-define(GOODS_SUBTYPE_MOUNT_CARD,   10).    %% 子类型 - 坐骑卡
-define(GOODS_SUBTYPE_MAP, 37).             %% 子类型 - 藏宝图
-define(GOODS_SUBTYPE_BAG_EXD,      20).    %% 子类型 - 背包扩展
-define(GOODS_SUBTYPE_STORAGE_EXD,  21).    %% 子类型 - 仓库扩展
-define(GOODS_SUBTYPE_TOWER,        23).    %% 子类型 - 爬塔

-define(GOODS_VIPTYPE_WEEK,         10).    %% vip周卡
-define(GOODS_VIPTYPE_MON,          11).    %% vip月卡
-define(GOODS_VIPTYPE_HYEAR,        12).    %% vip半年卡
-define(GOODS_VIPTYPE_1DAY,         13).    %% vip一天
-define(GOODS_VIPTYPE_3DAY,         14).    %% vip三天
-define(GOODS_VIPTYPE_EXPERIENCE,   16).    %% vip体验卡
-define(GOODS_VIPTYPE_GROWTH,   20).        %% vip成长丹

-define(GOODS_SUBTYPE_MON_CALL,     11).    %% 召唤令牌-帮派
-define(GOODS_SUBTYPE_ANQI,         10).    %% 子类型 - 暗器
-define(GOODS_SUBTYPE_ANQI_MASTERY, 11).    %% 子类型 - 暗器熟练丹
-define(GOODS_SUBTYPE_ANQI_SKILL,   13).    %% 子类型 - 暗器技能书
-define(GOODS_SUBTYPE_PK,           14).    %% 罪恶值

-define(GOODS_VIP_COUNTER_TYPE,     4501).  %% VIP红包每天计数器类型
-define(GOODS_NOVIP_GIFT_LIMIT,     5).     %% VIP红包非VIP会员每天开启次数
-define(GOODS_VIP_GIFT_LIMIT,       10).    %% VIP红包VIP会员每天开启次数

-define(GOODS_EQUIPTYPE_WEAPON,      1).     %% 装备类型 - 武器类
-define(GOODS_EQUIPTYPE_ARMOR1,      2).     %% 装备类型 - 防具类1
-define(GOODS_EQUIPTYPE_ARMOR2,      3).     %% 装备类型 - 防具类2
-define(GOODS_EQUIPTYPE_RING,        4).     %% 装备类型 - 戒指
-define(GOODS_EQUIPTYPE_NECKLACE,    5).     %% 装备类型 - 项链
-define(GOODS_EQUIPTYPE_CLOTH,       6).     %% 装备类型 - 衣服类
-define(GOODS_EQUIPTYPE_AMULET,      7).     %% 装备类型 - 护符类
-define(GOODS_EQUIPTYPE_MOUNT,       8).     %% 装备类型 - 坐骑装备类
-define(GOODS_EQUIPTYPE_FASHION,     9).     %% 装备类型 - 时装类


-define(GOODS_FASHION_WEAPON,       61).    %% 时装类型 - 武器类
-define(GOODS_FASHION_ARMOR,        60).    %% 时装类型 - 衣服类
-define(GOODS_FASHION_ACCESSORY,    62).    %% 时装类型 - 饰品类
-define(GOODS_FASHION_HEAD,         63).    %% 时装类型 - 头类
-define(GOODS_FASHION_TAIL,         64).    %% 时装类型 - 尾类
-define(GOODS_FASHION_RING,         65).    %% 时装类型 - 戒指类

-define(GOODS_ID_STREN_BASE_RUNE,       121001).    %% 强化幸运符
-define(GOODS_ID_STREN_SEVEN_RUNE,      121007).    %% 七色幸运符
-define(GOODS_ID_STREN_EIGHT_RUNE,      121008).    %% 八色幸运符
-define(GOODS_ID_STREN_NINE_RUNE,       121009).    %% 九色幸运符
-define(GOODS_ID_STREN_RUNE7,           121002).    %% 优秀的幸运符
-define(GOODS_ID_STREN_RUNE8,           121003).    %% 精良的幸运符
-define(GOODS_ID_STREN_RUNE9,           121004).    %% 完美的幸运符
-define(GOODS_ID_STREN_ARMOR_GUARD9,    122019).    %% 九色百炼保护符
-define(GOODS_ID_STREN_ARMOR_GUARD10,   122020).    %% 十色百炼保护符
-define(GOODS_ID_STREN_WEAPON_GUARD9,   122009).    %% 九色流星保护符
-define(GOODS_ID_STREN_WEAPON_GUARD10,  122010).    %% 十色流星保护符
-define(GOODS_ID_FASHION_STREN_REWARD,  531315).    %% 时装7级强化补偿礼包
-define(GOODS_ID_STREN_SEVEN_REWARD,    531307).    %% 7级强化补偿礼包
-define(GOODS_ID_STREN_EIGHT_REWARD,    531308).    %% 8级强化补偿礼包
-define(GOODS_ID_STREN_NINE_REWARD,     531309).    %% 9级强化补偿礼包
-define(GOODS_ID_STREN_SEVEN_REWARD2,   531305).    %% 非綁定的7级强化补偿礼包
-define(GOODS_ID_STREN_EIGHT_REWARD2,   531306).    %% 非綁定的8级强化补偿礼包
-define(GOODS_ID_COIN,                  611101).    %% 铜钱
-define(GOODS_ID_MOUNT_GROW,            312002).    %% 坐骑成长灵丹

-define(GOODS_ATTRIBUTE_TYPE_ADDITION,      1).     %% 属性类型：洗炼属性
-define(GOODS_ATTRIBUTE_TYPE_STREN,         2).     %% 属性类型：强化属性
-define(GOODS_ATTRIBUTE_TYPE_STREN_REWARD,  3).     %% 属性类型：强化奖励属性
-define(GOODS_ATTRIBUTE_TYPE_INLAY,         4).     %% 属性类型：镶嵌属性
-define(GOODS_ATTRIBUTE_TYPE_PREFIX,        5).     %% 属性类型：前缀属性
-define(GOODS_ATTRIBUTE_REIKI,              6).     %% 属性类型：注灵属性

-define(GOODS_PRICE_TYPE_COIN,      1).     %% 价格类型 - 铜钱
-define(GOODS_PRICE_TYPE_SILVER,    2).     %% 价格类型 - 银两
-define(GOODS_PRICE_TYPE_GOLD,      3).     %% 价格类型 - 金币
-define(GOODS_PRICE_TYPE_BCOIN,     4).     %% 价格类型 - 绑定的铜钱

-define(GOODS_CD_TIME_DRUG,         15).    %% 药品类冷却时间，单位：秒
-define(GOODS_CD_TIME_DRUG_BAG,     10).    %% 药品包类冷却时间，单位：秒
-define(GOODS_CD_TIME_DRUG_BAG2,    12).    %% 新药品包类冷却时间，单位：秒
-define(GOODS_REPLY_TIME_DRUG,      3).     %% 药品类回复间隔时间，单位：秒
-define(GOODS_DROP_EXPIRE_TIME,     50).    %% 掉落物品存活时间，单位：秒

-define(SHOP_TYPE_GOLD,             1).     %% 商店类型 - 商城
-define(SHOP_TYPE_VIP_DRUG,         10229). %% 商店类型 - VIP药店
-define(SHOP_TYPE_VIP_STORAGE,      10230). %% 商店类型 - VIP仓库
-define(SHOP_TYPE_FORGE,            99301). %% 商店类型 - 炼化NPC
-define(SHOP_TYPE_ARENA,            30055). %% 商店类型 - 竞技场兑换NPC
-define(SHOP_TYPE_BATTLE,           30058). %% 商店类型 - 战功兑换NPC
-define(SHOP_TYPE_HOUNOR,           30064). %% 商店类型 - 荣誉兑换NPC
-define(SHOP_TYPE_SIEGE_SHOP,       30075). %% 商店类型 - 城战商店NPC
-define(SHOP_TYPE_SIEGE_SHOP2,      30073). %% 商店类型 - 城战商店NPC
-define(SHOP_TYPE_KING_HOUNOR,      30069). %% 商店类型 - 帝王谷兑换NPC

-define(SHOP_SUBTYPE_COMMON,        2).     %% 商城子类型 - 绑定元宝和元宝都能买(成长变强)
-define(SHOP_SUBTYPE_COMMON2,        3).     %% 商城子类型 - 绑定元宝和元宝都能买(日常消耗) 
-define(SHOP_SUBTYPE_POINT,         19).    %% 商城子类型 - 积分区
-define(SHOP_SUBTYPE_GOLD_BIND,     20).    %% 商城子类型 - 绑定元宝区


-define(GIFT_GET_WAY_BAG,           bag).               %% 礼包领取方式 - 直接发到背包
-define(GIFT_GET_WAY_NPC,           npc).               %% 礼包领取方式 - NPC领取
-define(GIFT_GET_WAY_CLIENT,        client).            %% 礼包领取方式 - 客户端领取
-define(GIFT_GIVE_WAY_REGISTER,     user_register).     %% 礼包发放方式 - 玩家注册
-define(GIFT_GIVE_WAY_ONLINE,       user_online).       %% 礼包发放方式 - 玩家在线
-define(GIFT_GIVE_WAY_ASSIGN,       user_assign).       %% 礼包发放方式 - 指定玩家
-define(GIFT_GIVE_WAY_ALL,          user_all).          %% 礼包发放方式 - 所有玩家
-define(GIFT_GIVE_WAY_CARD,         card_active).       %% 礼包发放方式 - 新手卡激活
-define(GIFT_ID_FIRST_ONLINE_NEW,   1991).              %% 礼包ID - 第一个新手在线礼包
-define(GIFT_ID_FIRST_ONLINE_DAY,   2004).              %% 礼包ID - 第一个日常在线礼包
-define(GIFT_GOODS_ID_ONLINE_NEW,   531101).            %% 礼包物品类型ID - 新手在线礼包
-define(GIFT_GOODS_ID_ONLINE_DAY,   531201).            %% 礼包物品类型ID - 日常在线礼包
-define(GIFT_GOODS_ID_GOAL,         531601).            %% 礼包物品类型ID - 远征目标礼包
-define(GIFT_GOODS_ID_CHARGE,       532001).            %% 礼包物品类型ID - 首充礼包
-define(GIFT_GOODS_ID_MEMBER,       532501).            %% 礼包物品类型ID - 会员礼包
-define(GIFT_GOODS_ID_MEDIA,        533007).            %% 礼包物品类型ID - 媒体推广礼包
-define(GIFT_OFFLINE_DELAY,         300).               %% 在线礼包最大下线延迟时间，秒

-define(REPLY_SCENE_LIMIT,          [5]).        %% 血包不可回复的场景类型
-define(EQUIP_SHINE_LIMIT,          [1,2,3,4,5,6,7,8,9,10,11,12]).      %% 全身发光涉及到的装备的格子位置
-define(EQUIP_SHINE_STREN,          7).                             %% 全身发光涉及到的装备的强化数下限

