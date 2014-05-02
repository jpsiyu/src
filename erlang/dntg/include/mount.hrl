%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-5-3
%% Description: 坐骑 ets
%% --------------------------------------------------------
%% 更新坐骑的状态
-define(SQL_UPDATE_STATUE, 
        <<"UPDATE `mount` SET `status`=~p  WHERE `id`=~p">>).

%%　删除坐骑
-define(SQL_MOUNT_DELETE, 
        <<"DELETE FROM `mount` WHERE `id`=~p">>).

%% 坐骑连表查询
-define(SQL_MOUNT_SELECT2, 
        <<"SELECT m.role_id,m.type_id,m.figure,m.stren,m.combat_power,m.level,m.star,m.quality,pl.nickname FROM mount AS m INNER JOIN player_low AS pl ON m.role_id=pl.id WHERE m.id=~p">>).

%% 查看玩家是否有坐骑记录
-define(SQL_MOUNT_ID_SELECT,
        <<"SELECT id FROM mount WHERE role_id=~p">>).

%% 坐骑强化
-define(SQL_MOUNT_STREN, 
        <<"UPDATE mount SET name='~s', figure=~p, stren=~p, stren_ratio=~p, bind=~p, trade= ~p, combat_power=~p, attribute='~s', att_per=~p WHERE id=~p ">>).

%%　坐骑飞行棋升星操作
-define(sql_upfly_ok, 
        <<"UPDATE mount SET attribute='~s', attribute2='~s', bind=~p, trade=~p, combat_power=~p, star_value=~p, star=~p, fly_id=~p WHERE id=~p">>).

-define(sql_upfly_fail, 
        <<"update `mount` set `star_value`=~p, `bind`=~p, `trade`=~p where id=~p">>).

%% 坐骑进阶操作
%% 坐骑进阶成功
-define(SQL_UPGRADE_OK, 
        <<"UPDATE mount SET attribute='~s', bind=~p, trade=~p, figure=~p, combat_power=~p, type_id=~p, level=~p, star=~p, star_value=~p WHERE id=~p">>).

%%　升星成功
-define(SQL_UPGRADE_STAR_OK, 
        <<"UPDATE mount SET attribute='~s', star = ~p, star_value = ~p,  bind=~p, `trade`=~p, combat_power=~p WHERE id=~p">>).
%% 升星失败
-define(SQL_UPGRADE_STAR_FAIL, 
        <<"UPDATE mount SET star_value = ~p, bind = ~p,  trade = ~p where id=~p">>).

%% 资质升级
-define(sql_quality_ok, 
        <<"UPDATE mount SET attribute='~s', attribute2='~s', bind=~p, trade=~p, combat_power=~p, quality_value=~p, point=~p, quality=~p WHERE id=~p">>).
-define(sql_quality_fail, 
        <<"UPDATE mount SET quality_value=~p, bind=~p, trade=~p WHERE id=~p">>).

%% 获取坐骑所有的幻化形象记录id
-define(SQL_MOUNT_FIFURE_BY_TIME,
        <<"SELECT type_id FROM upgrade_change WHERE mid=~p AND (time > ~p OR time=0)">>).

%% 新增坐骑的形象
-define(SQL_REPAIR, 
        <<"INSERT INTO upgrade_change SET mid=~p, pid=~p, state=3, type_id=~p">>).

-define(SQL_CHANGE_FIGURE, 
        <<"UPDATE mount SET figure = ~p WHERE id = ~p">>).

%% 删除过期的坐骑幻化形象
-define(SQL_DELETE_UPGRADE_CHANGE, 
        <<"DELETE FROM upgrade_change WHERE mid=~p and type_id=~p and time=~p and state=~p and pid=~p">>).

-define(SQL_UP_FIGURE_AND_POWER,
        <<"UPDATE mount SET figure=~p, combat_power=~p WHERE id=~p">>).

-define(sql_change_fly, 
        <<"UPDATE mount SET fly_id = ~p WHERE id = ~p">>).

-define(sql_fly, 
        <<"UPDATE mount SET status = ~p WHERE id = ~p">>).

%% 新增坐骑数据
-define(SQL_MOUNT_INSERT, 
        <<"INSERT INTO mount SET role_id = ~p, name = '~s', type_id = ~p, figure = ~p, stren = ~p, stren_ratio = ~p,  speed = ~p, 
          combat_power = ~p, status = ~p, attribute = '~s', bind = ~p, trade = ~p, att_per = ~p, quality_attr = '~s', lingxi_attr = '~s'">>).
%% 获取最新的坐骑id
-define(SQL_LAST_MOUNT_ID, <<"SELECT LAST_INSERT_ID()">>).

%% 获取坐骑数据
-define(SQL_MOUNT_SELECT, 
        <<"SELECT id, name, role_id, type_id, figure, speed, combat_power, status, bind, level, star, star_value,
           quality_lv, quality_attr, lingxi_num, lingxi_attr, lingxi_gx_id FROM mount WHERE role_id = ~p">>).

%% 获取玩家所有的幻化形象记录
-define(SQL_SELECT_MOUNT_CHANGE_BY_PID, 
        <<"SELECT id, mid, pid, type_id, time, state FROM upgrade_change WHERE pid=~p">>).

%% 资质替换
-define(SQL_UP_MOUNT_QUALITY,
		<<"UPDATE mount SET quality_attr='~s', quality_lv=~p WHERE id = ~p and role_id =~p">>).

%% 灵犀光效id切换
-define(SQL_UP_MOUNT_LINGXI_GX_ID,
        <<"UPDATE mount SET lingxi_gx_id=~p WHERE id = ~p and role_id =~p">>).

%% 灵犀丹使用
-define(SQL_UP_MOUNT_LINGXI_ATTR,
        <<"UPDATE mount SET attribute='~s', combat_power=~p, lingxi_num = ~p, lingxi_attr = '~s' WHERE id=~p">>).

-define(figure_list, [311002, 311004, 311501, 311502, 311503, 311504, 311505, 311506, 311507, 311508, 311509, 311510]).

%% 坐骑属性(内存数据)
-record(ets_mount, {
        id = 0,                         %% 坐骑ID
        name = <<>>,                    %% 坐骑名称
        role_id = 0,                    %% 角色ID
        type_id = 0,                    %% 坐骑类型ID
        figure = 0,                     %% 形像
        stren = 0,                      %% 强化
        stren_ratio = 0,                %% 强化失败次数
        speed = 0,                      %% 速度
        bind = 0,                       %% 绑定
        trade = 0,                      %% 是否交易，1为不可交易，0为可交易
        attribute = [],                 %% 属性值，[Hp, Att, Hit, Crit, Fire, Ice, Drug, att_per]
        attribute2 = [],                %% [mp, def, dodge, ten, hp_per]
        combat_power = 0,               %% 战斗力
        status = 0,                     %% 状态，0休息，1出战，2骑乘
        att_per = 0,                    %% 攻击百分比
        up_value = 0,                   %% 祝福值   
        level = 0,                      %% 阶数
        star = 0,                       %% 星数
        star_value = 0,                 %% 星数祝福值
        fly_id = 0,                     %% 飞行器id
        quality = 0,                    %% 品质
        point = 0,                      %% 品质点数
        quality_value = 0,              %% 资质祝福值
        quality_lv = 0,                 %% 资质额外加成等级
        quality_attr = [],              %% 资质培养属性
        lingxi_num = 0,                 %% 灵犀值
        lingxi_attr = [],               %% 灵犀丹额外增加的属性
        lingxi_gx_id = 0,               %% 灵犀光效id
        figure_attr = [],               %% 坐骑幻化形象所加的属性综合
        temp_quality_attr = []          %% 临时资质培养属性
    }).

%%　幻化数据
-record(upgrade_change, {
        mid=0,
        pid=0,
        type_id=0,
        time=0,
        state=0         %% 1:未到期 2:到期 3:永久
    }).


%% 强化加成表
-record(mount_stren,{
        level,              %% 强化等级
        percent,            %% 基础加成,百分比
        figure,             %% 形象id
        att,                %% 加攻击
        hit,                %% 加命中
        crit,               %% 加暴击
        att_per             %% 攻击百分比
    }).

%% 战斗基础属性
-record(mount_base, {
       type_id,             %% 类型id
       speed,               %% 速度加成,百分比
       hp,                  %% 气血
       resist               %% 全抗
    }).

%% %% 坐骑进阶
-record(mount_upgrade, {
        mount_id,           %% 坐骑id
        next_figure,        %% 下阶形象
        level,              %% 阶数 
        speed,              %% 速度
        attr = []           %% 属性列表[{}]
    }).



-record(mount_upgrade_limit, {
        level,               
        lv,                
        max_value           
    }).

-record(up_fly_star, {
        star,
        fly_figure,
        star_radio,
        coin,
        goods_id,
        num,
        hp,
        fire,
        ice,
        drug,
        att,
        att_per,
        max_value
    }).

-record(mount_up_quality, {
        quality,        % 0凡兽，1灵兽，2异兽，3玄兽，4仙兽，5神兽
        point,
        hp,
        def,
        hit,
        dodge,
        crit,
        ten,
        att,
        fire,
        ice,
        drug,
        stage_per,
        radio,
        goods_id,
        num,
        max_value
    }).

%% 幻化加属性
-record(attr_add, {
        figure,     %% 形象id
        hp,
        att,
        fire,
        ice,
        drug,
        time        %% 天数,0是永久
    }).

%% ==============================================New Mount=========================================
%%
%% ================================================================================================

%% 坐骑进阶星星配置：
-record(mount_upgrade_star, { 
        star_id = 0,            %% 星星等级
        level = 0,              %% 坐骑的阶数
        next_figure = 0,        %% 坐骑的下一阶形象
        lim_star = 0,           %% 最大星星数上限
        radio = 0,              %% 概率(这里的概率有什么问题没有？)
        lim_lucky = 0,          %% 祝福值上限
        coin = 0,               %% 升星操作需要铜币数量
        goods = [],             %% 升星需要消耗的道具[{进阶丹 数量}]
        attr = []               %% 升星增加的属性值 [{Type, Value}...]
}).


%% 坐骑幻化形象属性
-record(figure_attr_add, {
        figure_id = 0,          %% 幻化形象id
        attr = [],              %% 坐骑幻化后加的属性值,[{att, Value}, {hp, Value}, {resist, Value}]
        time = 0                %% 天数,  0:永久
    }).



%% 坐骑资质星级额外奖励属性
-record(mount_quality, {
        quality_lv = 0,         %% 0凡兽，1灵兽，2异兽，3玄兽，4仙兽，5神兽
        quality_lim_star = 0,   %% 资质总星数升级上限
        attr = [],              %% 资质达凡兽,灵兽,异兽,玄兽,仙兽,神兽到所增加的属性值,[{Type, Value}]
        quality_max_lv = 0      %% 资质总星数最大升级上限
        }).



%% 坐骑资质消耗和属性成长配置（这里只有两种）
-record(mount_quality_attr_cfg, {
        train_type = 0,         %% 资质培养类型
        goods = [],             %% 资质培养消耗的物品[{good_id, num}]
        coin = 0,               %% 消耗的铜币数量
        att_cfg = [],           %% [{att_grow,5},    {max_star, 100}, {max_attr, 500}, {radio, [{-2,100},{-1,100},{0,200},{1,400},{2,810}]}]
        hp_cfg = [],            %% [{hp_grow,5},     {max_star, 100}, {max_attr, 500}, {radio, [{-2,100},{-1,100},{0,200},{1,400},{2,810}]}]
        def_cfg = [],           %% [{def_grow,5},    {max_star, 100}, {max_attr, 500}, {radio, [{-2,100},{-1,100},{0,200},{1,400},{2,810}]}]
        resist_cfg = [],        %% [{resist_grow,5}, {max_star, 100}, {max_attr, 500}, {radio, [{-2,100},{-1,100},{0,200},{1,400},{2,810}]}]
        hit_cfg = [],           %% [{hit_grow,5},    {max_star, 100}, {max_attr, 500}, {radio, [{-2,100},{-1,100},{0,200},{1,400},{2,810}]}]
        dodge_cfg = [],         %% [{dodge_grow,5},  {max_star, 100}, {max_attr, 500}, {radio, [{-2,100},{-1,100},{0,200},{1,400},{2,810}]}]
        crit_cfg = [],          %% [{crit_grow,5},   {max_star, 100}, {max_attr, 500}, {radio, [{-2,100},{-1,100},{0,200},{1,400},{2,810}]}]
        ten_cfg = []            %% [{ten_grow,5},    {max_star, 100}, {max_attr, 500}, {radio, [{-2,100},{-1,100},{0,200},{1,400},{2,810}]}]
    }).


%% 坐骑灵犀丹配置
-record(mount_lingxi_good, {
        good_id = 0,            %% 灵犀丹id
        lingxi_num = 0,         %% 使用灵犀丹后灵犀值增加数值
        attr = []               %% [{Type, AddNum}] = [{属性类型, 增加的属性}]
    }).


%% 坐骑灵犀加成百分比
-record(mount_lingxi_lv, {
        lv = 0,                 %% 灵犀等级
        lingxi_p = 0,           %% 灵犀加成百分比 
        light_effect_list = [], %% 光效id列表
        lim_attr = [],          %% [type, lim_num}] = [{属性类型, 属性上限}]
        max_lv = 0              %%　灵犀最大等级
    }).



