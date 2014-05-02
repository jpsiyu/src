%%%------------------------------------------------
%%% File    : record.hrl
%%% Author  : xyao
%%% Created : 2011-12-13
%%% Description: 物品相关信息
%%%------------------------------------------------

-define(MAX_STREN, 12).                                         %% 最高强化数
-define(STREN_TYPE, [1,2,3,4,5,6,7,8,13,14,15]).                %% 强化属性类型id
-define(ORANGE_ID, [20065, 20165, 20265, 20075, 20175, 20275]). %% 橙色装备套装ID
-define(ARMOR, [106107, 106307, 106207, 106011, 106021, 106031, 106012, 106022, 106032]).   %% 时装
-define(ACCESSORY, [106704, 106904, 106804, 106211, 106221, 106231]).                   %% 翅膀
-define(WEAPON, [106108, 106109, 106110]).      % 武器
-define(HEAD, [106308, 106309, 106310]).        % 头
-define(TAIL, [106403]).
-define(RING, [106503]).

%%玩家物品记录
-record(goods, {
        id=0,           %% 物品Id
        player_id=0,    %% 角色Id
        guild_id=0,     %% 帮派Id，只有存入帮派仓库才会有值
        goods_id=0,     %% 物品类型Id，对应ets_goods_type.goods_id
        type=0,         %% 物品类型
        subtype=0,      %% 物品子类型
        equip_type=0,   %% 装备类型：0无，1武器，2防具套1，3防具套2，4戒指，
                        %%           5项链，6衣服，7护符，8坐骑，9时装 
        price_type=0,   %% 价格类型：1 铜钱, 2 绑定元宝，3 元宝，4 绑定铜钱
        price=0,        %% 购买价格
        sell_price=0,   %% 出售价格
        bind=0,         %% 绑定状态，0为不可绑定，1为可绑定还未绑定，2为可绑定已绑定
        trade=0,        %% 交易状态，0为可交易，1为不可交易
        sell=0,         %% 出售状态，0为可出售，1为不可出售
        isdrop=0,       %% 丢弃状态，0为可丢弃，1为不可丢弃
        level=0,        %% 物品等级
        vitality = 0,   %% 体力
        spirit = 0,     %% 灵力
        hp = 0,         %% 血量
        mp = 0,         %% 内力
        forza=0,        %% 力量
        agile=0,        %% 敏捷
        wit=0,          %% 智力
        att=0,          %% 攻击
        def=0,          %% 防御
        hit = 0,        %% 命中
        dodge = 0,      %% 躲避
        crit = 0,       %% 暴击
        ten = 0,        %% 坚韧
        speed=0,        %% 速度
        attrition=0,    %% 耐久度上限，当前耐久度由lib_goods:get_goods_attrition(UseNum)算得
        use_num=0,      %% 可使用次数，由lib_goods:get_goods_use_num(Attrition)算得
        suit_id=0,      %% 套装ID，0为无
        skill_id=0,     %% 技能ID，0为无
        stren=0,        %% 强化等级
        stren_add = [], %% 强化加成[1气血 2 内力  3 攻击  4 防御  5 命中   6 躲避  7 暴击   8 坚韧  9 抗性] 
        stren_ratio=0,  %% 强化附加成功率
        hole=0,         %% 镶孔数
        hole1_goods=0,  %% 孔1所镶物品ID
        hole2_goods=0,  %% 孔2所镶物品ID
        hole3_goods=0,  %% 孔3所镶物品ID
        location=0,     %% 物品所在位置，1 装备一，2 装备二，3 装备三, 4 背包，5 仓库
        cell=0,         %% 物品所在格子位置
        num=0,          %% 物品数量
        color=0,        %% 物品颜色，0 白色，1 绿色，2 蓝色，3 紫色，4 橙色
        expire_time=0,  %% 有效期，0为无
        addition_1 = [],  %% 第一洗炼位附加属性列表[{type, star, value, color, min, max}]
        addition_2 = [],  %% 第二洗炼位附加属性列表[{type, star, value, color, min, max}]
        addition_3 = [],  %% 第三洗炼位附加属性列表[{type, star, value, color, min, max}]
        min_star = 0,   %% 下版本去掉
        wash_time = 0,  %% 下版本去掉
        prefix=0,       %% 品质前缀
        first_prefix=0, %% 进阶前缀(0物品配置默认颜色,1紫1阶,2紫2阶,3紫3阶,4橙1阶,5橙2阶,6橙3阶) 
        ice=0,          %% 冰
        fire=0,         %% 火
        drug=0,         %% 毒
        reiki_level=0,  %% 注灵等级
        qi_level=0,     %% 器灵等级
        reiki_value=[], %% 注灵属性值[type, value]
        reiki_list=[],  %% [力量, 身法, 灵力, 体质]
        reiki_times=0,  %% 注灵幸运值
        note = <<>>     %% 标识
    }).

%%玩家物品属性表
-record(goods_attribute, {
        id,             %% 编号
        player_id,      %% 角色Id
        gid,            %% 物品Id
        attribute_type, %% 属性类型，1 附加，2 强化，3 品质，4 镶嵌
        attribute_id,   %% 属性类型Id
        value_type,     %% 属性值类型，0为数值，1为百分比
        hp,             %% 气血
        mp,             %% 内力
        att,            %% 攻击
        def,            %% 防御
        hit,            %% 命中
        dodge,          %% 躲避
        crit,           %% 暴击
        ten             %% 坚韧
    }).

%% 物品兑换规则
-record(ets_goods_exchange, {
        id=0,             %% 编号
        npc=0,            %% NPC编号
        type=0,           %% 兑换类型，0 物品兑换，1 竞技积分兑换
        method=0,         %% 兑换方式，0为固定兑换，1为随机兑换
        raw_goods=[],     %% 原物品列表
        dst_goods=[],     %% 兑换物品列表
        bind=0,           %% 兑换物品的绑定状态
        max_overlap=0,    %% 兑换物品的最大叠加数
        honour=0,         %% 荣誉需求
        king_honour=0,    %% 帝王谷荣誉需求
	  single_limit_num=0,		   %%单个物品每天限制兑换数
        limit_num=0,      %% 每天限制兑换数
        limit_id=0,       %% 每天限制兑换数的ID
        start_time=0,     %% 开始时间
        end_time=0,       %% 结束时间
        status=0          %% 状态，0为未生效，1为生效
    }).

%%物品类型记录
-record(ets_goods_type, {
        goods_id,           %% 物品类型Id
        goods_name,         %% 物品名称
        type,               %% 物品类型, 1 装备类， 2 增益类，3 任务类 4 坐骑类
        subtype,            %% 物品子类型，
                            %% 装备子类型：1 武器，2 衣服，3 头盗，4 手套，5 鞋子，6 项链，7 戒指
                            %% 增益子类型：1 药品，2 经验
                            %% 坐骑子类型：1 一人坐骑 2 二人坐骑 3 三人坐骑
        equip_type=0,       %% 装备类型：0无，1武器，2防具套1，3防具套2，4戒指，
                            %%           5项链，6衣服，7护符，8坐骑，9时装 
        price_type=1,       %% 价格类型：1 铜钱, 2 银两，3 金币，4 绑定的铜钱
        price=0,            %% 购买价格
        sell_price=0,       %% 出售价格
        bind=0,             %% 是否绑定，0为不可绑定，1为可绑定还未绑定，2为可绑定已绑定
        trade=0,            %% 是否交易，1为不可交易，0为可交易
        sell=0,             %% 是否出售，1为不可出售，0为可出售
        isdrop=0,           %% 是否丢弃，1为不可丢弃，0为可丢弃
        level=0,            %% 等级限制
        career=0,           %% 职业限制，0为不限
        sex=0,              %% 性别限制，0为不限，1为男，2为女
        vitality = 0,       %% 体力
        spirit = 0,         %% 灵力
        hp = 0,             %% 基础属性 - 血量
        mp = 0,             %% 基础属性 - 内力
        forza=0,            %% 基础属性 - 力量
        wit=0,              %% 基础属性 - 智力
        agile=0,            %% 基础属性 - 敏捷
        att=0,              %% 基础属性 - 攻击
        def=0,              %% 基础属性 - 防御
        hit = 0,            %% 基础属性 - 命中
        dodge = 0,          %% 基础属性 - 躲避
        crit = 0,           %% 基础属性 - 暴击
        ten = 0,            %% 基础属性 - 坚韧
        speed=0,            %% 基础属性 - 速度
        attrition=0,        %% 耐久度，0为永不磨损
        suit_id=0,          %% 套装ID，0为无
        skill_id=0,         %% 技能ID，0为无
        is_stren = 0,       %% 是否可强化(0：不可强化，1：可强化)
        is_quality = 0,     %% 是否可提品质(0：不可提，1：可提)
        max_overlap=0,      %% 可叠加数，0为不可叠加
        color,              %% 物品颜色，0 白色，1 绿色，2 蓝色，3 紫色，4 橙色
        expire_time=0,      %% 有效期，0为无
        addition=[],        %% 附加属性列表，[{属性类型ID, 属性值}, ...]
        reply_num=0,        %% 气血和内力的单次回复量
        scene_limit=[],     %% 场景限制
        prefix = 0,         %% 品质前缀
        fist_prefix = 0,    %% 进阶前缀 (0物品配置默认颜色,1紫1阶,2紫2阶,3紫3阶,4橙1阶,5橙2阶,6橙3阶）
        ice=0,              %% 冰
        fire=0,             %% 火
        drug=0,             %% 毒
        search = 0          %% 是否可搜索，0不可搜，1可搜
    }).

%%===================================== 装备 ==============================
%%装备品质升级规则表
-record(ets_goods_quality_upgrade, {
        id,             %% 编号
        type,           %% 前缀类型: 1：进阶前缀(一元...)， 2：品质前缀(优秀...)
        equip_type,     %% 装备类型：0无，1武器，2防具套1，3防具套2，4戒指，
                        %%           5项链，6衣服，7护符，8坐骑，9时装 
        prefix,         %% 装备品质前缀
        stone_id,       %% 需求材料id
        stone_num,      %% 材料数量
        coin,           %% 消耗铜钱数
        less_level      %% 进阶最低等级
    }).

%%装备分解规则表
-record(ets_goods_resolve, {
        id,             %% 编号
        color,          %% 装备颜色, 1绿色, 2蓝色 , 3紫色
        stren,          %% 装备强化数
        stone_id,       %% 获得洗炼石ID
        stone_ratio,    %% 洗炼石概率
        lucky_id,       %% 获得幸运符id
        lucky_ratio,    %% 幸运符概率
        reserve_id,     %% 保留物品id
        reserve_ratio,  %% 保留物品概率
        coin            %% 消耗铜钱数
    }).

%%装备强化规则表
-record(ets_goods_strengthen, {
        id,             %% 编号
        type,           %% 装备类型：0无，1武器，2防具套1，3防具套2，4戒指，
                        %%           5项链，6衣服，7护符，8坐骑，9时装 
        strengthen,     %% 装备强化等级
        sratio,         %% 服务端成功率
        cratio,         %% 客户端成功率
        lucky_id = [],  %% 可使用幸运符id
        protect_id,     %% 可使用保护符id
        fail_level,     %% 失败掉到强化加几
        stone_id,       %% 强化需要的材料ID
        stone_num,      %% 强化材料数量
        addition,       %% 对基础属性加成        (所有基础属性都加，每个都是百分比)
        coin,           %% 消耗铜钱数
        is_upgrade = 0, %% 是否升级装备
        fail_num   = 0  %% 最大失败次数
    }).

%%强化奖励规则表
-record(ets_stren_reward,{
        id,             %% 编号
        type,           %% 1为武器、2为头盔、3为衣服、4为裤子、5为鞋子、6为腰带、7为手套、8为护符、9为戒指、10为项链、
                        %% 11为衣服时装、12为武器时装、13为饰品时装。
        stren,          %% 强化等级       1为当前强化等级是+1，以此类推
        level,          %% 装备等级  1为1-19级装备，2为20-29级装备，3为30-39级装备，以此类推
        reward_type1,   %% 1为攻击加成百分比，2为暴击，3为气血，4为全抗性
        value1,         %% 强化奖励数值1
        reward_type2,   %% 1为攻击加成百分比，2为暴击，3为气血，4为全抗性
        value2          %% 强化奖励数值2 
    }).                       
                                  
%% 强化幸运符规则
-record(ets_stren_lucky, {
        lucky_id,       %% 幸运符ID 
        ratio,          %% 增加成功率
        level           %% 需要强化多少级才可使用                     
    }).

%% 强化保护符规则表
-record(base_goods_stren_guard, {
        goods_id,       %% 强化石物品类型Id，对应ets_goods_type.goods_id
        stren,          %% 装备强化等级
        equip_type      %% 装备类型限制
    }).

%% 幸运值规则
-record(ets_lucky_value, {
        level,          %% 强化等级 
        fail_num,       %% 失败次数
        show            %% 是否显示
    }).

%%装备精炼规则表(紫色->橙色)
-record(ets_weapon_compose, {
        id,             %% 编号
        goods_id,       %% 紫装物品类型Id，对应ets_goods_type.goods_id
        stone_id,       %% 宝石物品类型Id，对应ets_goods_type.goods_id
        stone_num,      %% 宝石物品数量
        stuff_id,       %% 材料物品类型Id，对应ets_goods_type.goods_id
        stuff_num,      %% 材料物品数量
        new_id,         %% 橙装物品类型Id，对应ets_goods_type.goods_id
        coin            %% 消耗铜钱数
    }).

%% 装备升级规则表
-record(ets_equip_upgrade, {
        goods_id,       %% 物品类型Id，对应ets_goods_type.goods_id
        trip_id,        %% 碎片id
        trip_num,       %% 碎片数量
        stone_id,       %% 石头id
        stone_num,      %% 石头数量
        iron_id,        %% 铁id
        iron_num,       %% 铁数量
        protect_id,     %% 保护符id 0时表示没有损失
        new_id,         %% 进阶后物品id对应ets_goods_type.goods_id
        coin,           %% 费用
        less_stren = 0  %% 升级所需的最小强化数
    }).

%%附加属性洗炼规则
-record(ets_wash_rule, {
        level,          %% 洗炼位置
        coin,           %% 费用
        num             %% 最多属性条数                   
    }).

% %% 洗练属性强度, 确定星数
% -record(ets_wash_strength, {
%         level,          %% 装备等级
%         star_list=[],   %% 星数概率列表 [{属性强度为几颗星,概率},{属性强度为几颗星,概率}]
%         min_star,       %% 下限星数
%         max_star        %% 上限星数
%     }).

% %% 确定属性颜色规则
% -record(ets_wash_color, {
%         level,          %% 装备等级
%         star,           %% 星数
%         color           %% 颜色
%     }).                                                 

% %% 升星规则
% -record(ets_wash_star, {
%         level,          %% 装备等级                        
%         star,           %% 当前下限星数
%         is_upstar,      %% 下限是否可升级到此星级 1可升，0不可升                   
%         num             %% 升级到下一星需要刷新的次数，0为不论刷新多少次都不会再升星
%     }).                                                 

%% 确定洗练属性类型
-record(ets_wash_attribute_type, {
        type,           %% 装备类型　1为武器、2为头盔、3为衣服、4为裤子、5为鞋子、6为腰带、7为手套、8为护符、
                        %% 9为戒指、10为项链、11为衣服时装、12为武器时装、13为饰品时装 
        type_list=[]    %% 属性类型     [{类型，概率}]1为攻击，2为防御，3为气血，4为内力，5为命中，6为躲避，7为暴击，8为坚韧，9为火抗性、10为冰抗性、11为毒抗性                     
    }).  

%% 洗炼星数
-record(ets_wash_star, {
        level = 0,      %% 洗炼位置
        star_list = []  %% 星数列表
    }).

%% 洗炼值大小
-record(ets_wash_value, {
        level = 0,       %% 洗炼位置
        type = 0,       %% 属性类型
        star = 0,       %% 星数
        value = 0       %% 洗炼值
    }).

%% 洗炼值范围
-record(ets_wash_value_rang, {
        level = 0,          %% 洗炼位置
        type = 0,           %% 类型
        rang = []           %% 范围[min, max]
    }).


%% 洗炼颜色
-record(ets_wash_color, {
        level = 0,      %% 洗炼位置
        star = 0,       %% 星数
        color = 0       %% 颜色
    }).


% %% 洗练属性数值                                
% -record(ets_wash_type_value, {
%         type,           %% 属性类型 1为攻击，2为防御，3为气血，4为内力，5为命中，6为躲避，7为暴击，8为坚韧，9为火抗性、10为冰抗性、11为毒抗性
%         star,           %% 星数
%         min,            %% 最小值
%         max             %% 最大值
%     }).


% %% 锁定·颜色控制
% -record(ets_wash_lock_color, {
%         lock_num,       %% 锁定数量
%         color,          %% 属性颜色
%         min_refresh     %% 最小刷新次数
%     }).

% %% 锁定·数量控制
% -record(ets_wash_lock_num, {
%         same_type,      %% 同类型属性的条数
%         min_refresh     %% 最小刷新次数
%     }).

%%装备套装归属表
-record(suit_belong, {
        suit_id,        %% 套装ID
        level,          %% 套装等级
        series,         %% 套装系列, 1非人民币玩家,2人民币玩家
        max             %% 套装总件数
    }).                                         

%% 套装属性表
-record(suit_attribute, {
        suit_id,        %% 套装ID
        name = [],      %% 套装名字
        suit_num,       %% 套装件数
        value_type = [] %% 属性值[{type, value}]
    }).

%% 装备继承规则
-record(ets_inherit, {
        level,          %% 装备等级0代表1-9级，1代表10-19级，依次类推
        inherit_id,     %% 继承符id
        num,            %% 继承符数量
        coin            %% 消耗铜币
    }).

%% 时装强化规则
-record(fashion_stren, {
        level,          %% 强化等级    
        addition,       %% 属性加成
        figure,         %% 形象
        att,            %% 攻击
        hit,            %% 命中
        crite,          %% 暴击
        percent=[]   %% 百分比
    }).

%%===================================== 装备  end ==============================
%%物品效果表
-record(ets_goods_effect, {
        goods_id=0,         %% 物品类型ID
        exp=0,              %% 经验
        coin=0,             %% 铜钱
        bcoin=0,            %% 绑定铜钱
        llpt=0,             %% 历练声望
        xwpt=0,             %% 修为声望
        whpt=0,             %% 武魂声望
        arena=0,            %% 竞技积分
        battle_score=0,     %% 帮派战功
        honour=0,           %% 荣誉
        bag_num=0,          %% 格子数
        time=0,             %% 时长
        fashion=[],         %% 时装转换
        buf_type=0,         %% BUFF类型
        buf_attr=0,         %% BUFF属性ID
        buf_val=0,          %% BUFF属性值
        buf_time=0,         %% BUFF时长
        buf_scene = []      %% BUFF场景限制
    }).

%%---------------------------- 宝石  -----------------------------
%%宝石合成规则表
-record(ets_goods_compose, {
        id,             %% 编号
        goods_id,       %% 宝石物品类型Id，对应ets_goods_type.goods_id
        goods_num,      %% 宝石数量
        ratio,          %% 合成成功率
        new_id,         %% 合成新的宝石
        coin            %% 消耗铜钱数
    }).

%%宝石镶嵌规则表
-record(ets_goods_inlay, {
        id,             %% 编号
        goods_id,       %% 宝石物品类型Id，对应ets_goods_type.goods_id
        coin,           %% 消耗铜钱数
        equip_types     %% 可以镶嵌的装备类型
    }).

%%---------------------------- 宝石 end  -----------------------------
%% 炼炉配方
-record(ets_forge, {
        id=0,               %% 编号
        type=0,             %% 分类：对应下面的分类
        sub_type=0,         %% 子分类
        raw_goods=[],       %% 材料物品列表
        goods_id=0,         %% 炼化物品
        bind=0,             %% 绑定状态
        ratio=0,            %% 成功率
        coin=0,             %% 费用
        notice=0            %% 是否要发传闻 1:要, 0:不要
    }).

%% 炼炉类型
-record(ets_forge_type, {
        type,               %% 用于设置炼炉标签的名字
        sub_type            %% 用于设置炼炉标签下面子标签的名字
    }).   
%%---------------------------- 炼炉end   -----------------------------
%% 物品状态表
-record(goods_status, {
        player_id = 0,                  % 用户ID
        null_cells = [],                % 背包空格子位置
        equip_current = [0,0,0,0,0,0],  % 当前装备类型ID - [武器, 衣服, 坐骑, 武器强化数, 衣服强化数, 时装]
        equip_suit = [],                % 当前身上套装列表 - [{套装ID，套装数量}，...]
        suit_id = 0,                    % 当前装备全套的套装ID
        stren7_num = 0,                 % 当前身上装备加7以上的装备数量
        hp_cd = 0,                      % 使用气血药的冷却时间
        mp_cd = 0,                      % 使用内力药的冷却时间
        sell_status = 0,                % 点对点交易状态，1 交易中
        self_sell = [],                 % 自身挂售在交易市场的记录ID
        gift_list = [],                 % 已领取礼包列表
        dict                            % 物品dict
    }).

%% 活动配置
-record(base_activity, {
        id = 0,                     %% 活动编号
        name = <<>>,                %% 活动名称
        unit_num = 0,               %% 单位数量
        lim_day_num = 0,            %% 每天上限，0为不限
        lim_total_num = 0,          %% 总上限，0为不限
        goods_list = [],            %% 奖励物品列表，[{物品ID,物品数量}...]
        bind = 0,                   %% 奖励物品绑定状态
        send_type = 0,              %% 奖励发放方式，0实时发放，1活动结束后发放
        stime = 0,                  %% 活动开始时间
        etime = 0,                  %% 活动结束时间
        rtime = 0,                  %% 领取结束时间
        goods_time = 0              %% 物品过期时间
    }).

%% 玩家血包配置
-record(base_hp_bag, {
        type = 0,               %% 血包类型，1 气血，2 内力，3 回满血包，4 回满蓝包，5 普通血包，6 普通蓝包，7 帮派血包，8 帮派蓝包
        reply_span = 0,         %% 回复间隔时间，单位：秒
        scene_lim = [],         %% 限制的场景
        scene_allow = []        %% 允许的场景
    }).

%% 玩家血包ETS
-record(ets_hp_bag, {
        id = {0,0},             %% 编号 ｛玩家ID,类型｝
        role_id = 0,            %% 玩家id
        type = 0,               %% 血包类型，1 气血，2 内力，3 回满血包，4 回满蓝包，5 普通血包，6 普通蓝包，7 帮派血包，8 帮派蓝包
        bag_num = 0,            %% 血包储量
        reply_num = 0,          %% 血包单次回复量
        goods_id = 0,           %% 血包物品类型ID
        time = 0                %% 更新时间
     }).

%% 寻找唐僧配置
-record(base_turntable, {
	  id = 0,                 %% 编号
	  goods_id = 0,           %% 物品类型ID
	  precious = 0,           %% 是否为珍贵道具
	  ratio = 0,              %% 机率
	  ratio_start=0,          %% 机率开始值
	  ratio_end=0             %% 机率结束值
    }).

%% 临时背包
-record(temp_bag, {
        id,
        pid,
        goods_id,
        prefix,
        bind,
        stren,
        pos,
        num
    }).

%% 跨服功章升级
-record(kf_token, {
        career = 0,         %% 职业
        token_id = 0,       %% 当前ID
        next_id = 0,        %% 下级ID
        pt = 0,             %% 需要声望
        num = 0,            %% 功勋数量
        days = 0            %% 时限天数
    }).
