%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-19
%% Description: 物品掉落ets
%% --------------------------------------------------------

-define(ETS_DROP, ets_goods_drop).                              %% 物品掉落表
-define(ETS_MON_GOODS_COUNTER, ets_mon_goods_counter).          %% 怪物掉落物品计数器
-define(ETS_DROP_FACTOR, ets_drop_factor).                      %% 物品掉落系数

%% 物品掉落规则表
-record(ets_base_goods_drop, {
        mon_id=0,               %% 怪物编号
        boss=0,                 %% 是否BOSS
        stable_goods=[],        %% 固定掉落物品包
        rand_num=[],            %% 随机掉落数
        rand_goods=[],          %% 随机掉落物品包列表
        task=0,                 %% 是否有任务物品，0为无，1为有
        task_goods=[],          %% 任务物品类型列表
        interval_num=0,         %% 间隔掉落的特定数
        interval_time=0,        %% 间隔掉落时间，0为无
        interval_goods=[],      %% 间隔掉落物品包
        special_num=0,          %% 特定杀怪数，0为无
        special_goods=[],       %% 特定杀怪数掉落物品包
        limit_start=0,          %% 限制开始时间，0为无
        limit_end=0,            %% 限制结束时间，0为无
        limit_goods=[],         %% 限制物品列表
        counter_goods=[]        %% 有计数器的物品
    }).

%% 掉落规则
-record(ets_drop_rule, {
        mon_id=0,               %% 怪物编号
        boss=0,                 %% 是否BOSS
        task=0,                 %% 是否有任务物品，0为无，1为有
        broad=0,                %% 掉落物品是否广播场景，0不广播，1广播
        drop_list=[],           %% 掉落列表
        drop_rule=[],           %% 掉落规则
        counter_goods=[]        %% 需计数的物品列表
    }).

%% 掉落规则
-record(ets_drop_goods, {
        id=0,                   %% 编号
        %mon_id=0,               %% 怪物Id
        type=0,                 %% 类型，0 随机掉落，1 固定掉落，2 任务物品
        list_id=0,              %% 列表ID
        goods_id=0,             %% 物品ID
        ratio=0,                %% 机率
        num=0,                  %% 最大数量
        stren=0,                %% 最大强化数
        prefix=0,               %% 最大前缀数
        bind=0,                 %% 绑定状态
        notice=0,               %% 是否公告，1公告，0不公告
        factor=0,               %% 是否使用系数，0不使用，1使用
        hour_start=0,           %% 时间段限制，0为无
        hour_end=0,             %% 时间段限制，0为无
        time_start=0,           %% 日期限制，0为无
        time_end=0,             %% 日期限制，0为无
        replace_list = [],      %% 职业替换列表，[昆仑,逍遥,唐门]
        reduce = 0,             %% 是否衰减 0:否  1:是
        power_bind = 0,         %% 战力绑定, 战力小于战力绑定设置的数值时, 怪物掉落的道具均为绑定
        recharge_bind = 0,      %% 未首充绑定0:否  1:是
        vip_bind = 0,           %% 非VIP绑定0:否  1:是
        guild_bind = 0          %% 帮派等级绑定0:否  大于0:是
    }).

%% 物品掉落表
-record(ets_drop, {
        id=0,             %% 编号
        player_id=0,      %% 角色ID
        team_id=0,        %% 组队ID
 		copy_id=0,        %% 副本ID
        scene=0,          %% 场景ID
        drop_goods=[],    %% 掉落物品[[物品类型ID,物品类型,物品数量,物品品质]...]
        goods_id=0,       %% 掉落物品 - 物品类型ID
        gid=0,            %% 玩家掉落物品ID
        num=0,            %% 最大数量
        stren=0,          %% 最大强化数
        prefix=0,         %% 最大前缀数
        bind=0,           %% 绑定状态
        notice=0,         %% 是否公告，1公告，0不公告
        broad = 0,        %% 是否广播场景，0不广播，1广播
%        goods_item=[],    %% 掉落物品
        expire_time=0,    %% 过期时间
        mon_id = 0,       %% 怪物类型ID
        mon_name = <<>>,  %% BOSS怪物名字
        x = 0, 
        y = 0
    }).

%% 怪物掉落计数表
-record(ets_drop_counter, {
        mon_id=0,         %% 怪物编号
        drop_num=0,       %% 掉落数
        drop_time=0,      %% 完成掉落数时间
        mon_num=0,        %% 杀怪数
        mon_time=0        %% 完成杀怪数时间
    }).

%% 怪物物品掉落系数
-record(ets_drop_factor, {
        id=0,                   %% 编号
        drop_factor=1.00,       %% 掉落系数粗调
        drop_factor_list=[],    %% 掉落系数细调
        time=0                  %% 更新时间
    }).

%% 怪物掉落物品计数表
-record(ets_mon_goods_counter, {
        goods_id=0,         %% 物品类型ID
        goods_num=0,        %% 物品限制数
        drop_num=0,         %% 物品掉落数
        time=0              %% 时间
    }).

