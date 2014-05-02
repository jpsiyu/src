%%%------------------------------------
%%% @Author : huangwenjie
%%% @Email  : 1015099316@qq.com
%%% @Create : 2014.2.19
%%% @Description: 宝石系统
%%%-------------------------------------

-define(EQUIP_POS,         [1,2,3,4,5,6,7,8,9,10,11,12]).
-define(GEM_POS,           [1,2,3,4,5,6]).
-define(MAXLEVEL,          10).
%% 宝石栏信息
-record(gemstone, {
    id = 0,             %% 编号 equip_pos*100+gem_pos
    equip_pos = 0,      %% 装备栏位置
    gem_pos = 0,        %% 宝石栏位置
    type = 0,           %% 属性类型
    state = 0,          %% 状态 0.未激活 1.可激活 2.可升级
    level = 0,          %% 等级
    exp = 0             %% 经验
    }).

%% ################################ 配置表 ####################################
-record(gemstone_active,{
    equip_pos = 0,      %% 装备位置
    gem_pos = 0,        %% 宝石栏位置
    type = 0,           %% 宝石栏属性
    cost = 0,           %% 激活花费
    equip_min = 0       %% 装备等级要求
    }).

-record(gemstone_attr, {
        type = 0,       %% 宝石栏属性
        level = 0,      %% 栏位等级
        exp_limit = 0,  %% 升级所需经验
        attr = 0  %% 升级增加属性 Value
        }).

-record(gemstone_upgrade, {
        goods_type_id = 0,      %% 物品类型Id
        add_exp = []          %% 增加的经验[{Type, Exp}]
        }).





