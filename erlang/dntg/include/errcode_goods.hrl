%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-14
%% Description: 物品错误信息
%% --------------------------------------------------------

%%%--------------------------------------
%%% 基本错误码 0 - 99
%%%--------------------------------------
-define(ERRCODE_FAIL,           0).     %% 失败
-define(ERRCODE_OK,             1).     %% 成功

%%%--------------------------------------
%%% 物品错误码 1500 - 1599
%%%--------------------------------------
-define(ERRCODE15_FAIL,                     1500).      %% 物品操作失败
-define(ERRCODE15_NO_GOODS,                 1501).      %% 物品不存在
-define(ERRCODE15_NO_PLAYER,                1502).      %% 玩家不在线
-define(ERRCODE15_NO_MONEY,                 1503).      %% 金额不足
-define(ERRCODE15_NO_CELL,                  1504).      %% 格子不足
-define(ERRCODE15_NPC_FAR,                  1505).      %% 离NPC太远
-define(ERRCODE15_IN_SELL,                  1506).      %% 正在交易中
-define(ERRCODE15_PRICE_ERR,                1507).      %% 物品价格错误
-define(ERRCODE15_PALYER_ERR,               1508).      %% 物品所有者错误
-define(ERRCODE15_LOCATION_ERR,             1509).      %% 物品位置错误
-define(ERRCODE15_NOT_SELL,                 1510).      %% 物品不可出售
-define(ERRCODE15_NUM_ERR,                  1511).      %% 物品数量错误
-define(ERRCODE15_CELL_MAX,                 1512).      %% 格子数已达上限
-define(ERRCODE15_TYPE_ERR,                 1513).      %% 物品类型错误
-define(ERRCODE15_ATTRITION_ZERO,           1514).      %% 装备耐久为0
-define(ERRCODE15_REQUIRE_ERR,              1515).      %% 条件不符
-define(ERRCODE15_ATTRITION_FULL,           1516).      %% 无磨损
-define(ERRCODE15_NO_GOODS_TYPE,            1517).      %% 物品类型不存在
-define(ERRCODE15_IN_CD,                    1518).      %% 冷却时间
-define(ERRCODE15_LV_ERR,                   1519).      %% 物品等级限制
-define(ERRCODE15_PLAYER_DIE,               1520).      %% 人物已死亡
-define(ERRCODE15_NOT_TRHOW,                1521).      %% 物品不可销毁
-define(ERRCODE15_NO_DROP,                  1522).      %% 掉落包已经消失
-define(ERRCODE15_NO_DROP_PER,              1523).      %% 无权拣取
-define(ERRCODE15_TIME_NOT_START,           1524).      %% 时间还未到
-define(ERRCODE15_TIME_END,                 1525).      %% 时间已经结束
-define(ERRCODE15_GIFT_UNACTIVE,            1526).      %% 礼包未生效
-define(ERRCODE15_NO_RULE,                  1527).      %% 规则不存在
-define(ERRCODE15_RULE_UNACTIVE,            1528).      %% 规则未生效
-define(ERRCODE15_SHOP_TIME_LIMIT,          1529).      %% 限时物品一天只能购买一次
-define(ERRCODE15_GOODS_NUM_ZERO,           1530).      %% 物品已经卖完
-define(ERRCODE15_CAREER_ERR,               1531).      %% 职业不符
-define(ERRCODE15_JOB_ERR,                  1532).      %% 爵位不符
-define(ERRCODE15_XWPT_ERR,                 1533).      %% 修为声望限制
-define(ERRCODE15_GIFT_GOT,                 1534).      %% 礼包已领取
-define(ERRCODE15_NUM_LIMIT,                1535).      %% 次数已达上限
-define(ERRCODE15_VIP_TYPE_ERR,             1536).      %% VIP状态已存在
-define(ERRCODE15_NO_REALM,                 1537).      %% 还没有选国家
-define(ERRCODE15_MAP_ERR,                  1538).      %% 本场景无法回城
-define(ERRCODE15_STORAGE_MAX,              1539).      %% 仓库格子已达上限
-define(ERRCODE15_STORAGE_NO_CELL,          1540).      %% 仓库空间不足
-define(ERRCODE15_SCENE_WRONG,              1541).      %% 本场景无法使用
-define(ERRCODE15_SCENE_XY_WRONG,           1542).      %% 使用坐标错误
-define(ERRCODE15_YUNBIAO_ING,              1543).      %% 运镖中无法使用
-define(ERRCODE15_WINE_TOP,                 1544).      %% 每天只能使用6瓶酒
-define(ERRCODE15_HONOUR_ERR,               1545).      %% 跨服声望不足
-define(ERRCODE15_PRACTICE,                 1547).      %% 离线修炼中无法使用回城卷
-define(ERRCODE15_EXCHANGE_ARENA_ERR,       1548).      %% 英雄岛开战期间不可兑换
-define(ERRCODE15_EXCHANGE_BATTLE_ERR,      1549).      %% 帮派战斗期间不可兑换
-define(ERRCODE15_INTEAM_ERR,               1550).      %% 组队状态无法使用密卷，请脱离队伍在使用
-define(ERRCODE15_TASK_ERR,                 1551).      %% 您没有相应的任务，不能直接使用
-define(ERRCODE15_FASHION_NONE,             1552).      %% 您未穿戴任何时装，不能使用时装变换卷
-define(ERRCODE15_FASHION_ERR,              1553).      %% 您穿戴的时装和变换卷类型相同，不能变换
-define(ERRCODE15_NPC_NONE,                 1554).      %% NPC不存在
-define(ERRCODE15_NPC_TYPE_ERR,             1555).      %% NPC类型错误
-define(ERRCODE15_HP_MP_FULL,               1556).      %% 使用量超出上限，无法使用
-define(ERRCODE15_USE_ARENA_ERR,            1557).      %% 英雄岛开战期间不可使用
-define(ERRCODE15_USE_BATTLE_ERR,           1558).      %% 帮派战斗期间不可使用
-define(ERRCODE15_SIEGE_PAY_ERR,            1559).      %% 非武陵城占有帮派的帮众无法购买
-define(ERRCODE15_NUM_OVER,                 1560).      %% 次数超出每天上限
-define(ERRCODE15_NUM_OVER_ERR,             1561).      %% 兑换数量不正确
-define(ERRCODE15_SKILL_FAIL,               1562).      %% 技能学习失败
-define(ERRCODE15_FW_TEA,                   1563).      %% 组队状态才能使用柴火
-define(ERRCODE15_FW_FAR,                   1564).      %% 离火堆太远无法使用
-define(ERRCODE15_FW_LOW,                   1565).      %% 低级柴火无法覆盖高级柴火
-define(ERRCODE15_NO_FASHION,               1566).      %% 身上没有穿戴时装
-define(ERRCODE15_NO_FASHION_TIME,          1567).      %% 时装没有时间限制
-define(ERRCODE15_NO_FIGURE,                1568).      %% 没有变身不能使用还原丹
-define(ERRCODE15_SEX_ERR,                  1569).      %% 性别限制
-define(ERRCODE15_HAS_MARRIED,              1570).      %% 已婚，不能变性
-define(SCROLL_TR_NOSCENE,                  1571).      %% 传送场景不存在
-define(SCROLL_TR_NOLEVEL,                  1572).      %% 等级不足，无法传送
-define(SCROLL_TR_NODR,                     1573).      %% 本场景无法使用传送卷
-define(ERRCODE15_ANQI_EXIST,               1574).      %% 已经学习过暗器
-define(ERRCODE15_NO_BASE_ANQI,             1575).      %% 没有暗器配置
-define(ERRCODE15_EXCHANGE_KFZ_ERR,         1576).      %% 跨服战斗期间不可兑换
-define(ERRCODE15_ATTRITION_ERR,            1577).      %% 装备不可磨损，不用修复
-define(ERRCODE15_FASHION_EXPIRE,           1578).      %% 装备已经过期，不可穿戴
-define(ERRCODE15_SCENE_POS,                1579).      %% 使用地图坐标不正确
-define(ERRCODE15_NOT_EVENT,                1580).      %% 无触发事件
-define(ERRCODE15_NOTHING,                  1581).      %% 物品使用后什么都没有
-define(ERRCODE15_CANNOT_REPLACE_MID,		1582).      %% 当前BUFF不能替换中级BUFF
-define(ERRCODE15_CANNOT_REPLACE_BIG,		1583).      %% 当前BUFF不能替换高级BUFF
-define(ERRCODE15_NO_GUILD,		            1584).      %% 没有帮派
-define(ERRCODE15_NUM_SINGLE_LIMIT,         1585).		%% 单个物品次数已达上限
-define(ERRCODE15_NUM_SINGLE_OVER,          1586).		%% 单个物品兑换数量超过每天上限
-define(ERRCODE15_HAVE_CHANGE,              1587).      %% 已经有幻化形象
-define(ERRCODE15_MAND,                     1588).      %% 跨服不能修理
-define(ERRCODE15_DISTANCE,                 1589).
