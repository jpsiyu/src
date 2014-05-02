%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-7
%% Description: 挂售市场ets
%% --------------------------------------------------------

-define(ETS_SELL, ets_sell).                    %% 挂售市场
-define(ETS_BUY, ets_buy).                      %% 求购列表
-define(ETS_SELL_GOODS, ets_sell_goods).        %% 挂售市场物品表

-define(sql_sell_update, <<"update `sell_list` set `end_time`=~p, `is_expire`=0, `expire_time`=0 where id=~p ">>).
-define(sql_sell_update2, <<"update `sell_list` set `is_expire`=1, `expire_time`=~p where id=~p ">>).

-define(sql_buy_delete, <<"delete from `buy_list` where `id`=~p ">>).
-define(sql_buy_update, <<"update `buy_list` set `num`=~p where `id`=~p ">>).
-define(sql_buy_select, <<"select `id`,`class1`,`class2`,`pid`,`goods_id`,`goods_name`,`num`,`type`,`subtype`,`lv`,`lv_num`,`color`,`career`,`prefix`,`stren`,`price_type`,`price`,`time`,`end_time` from `buy_list` where `id`=~p ">>).
-define(sql_buy_select2, <<"select `id`,`class1`,`class2`,`pid`,`goods_id`,`goods_name`,`num`,`type`,`subtype`,`lv`,`lv_num`,`color`,`career`,`prefix`,`stren`,`price_type`,`price`,`time`,`end_time` from `buy_list` ">>).

%% 挂售列表
-record(ets_sell, {
        id = 0,                     %% 编号
        class1 = 0,                 %% 挂售分类 - 大类
        class2 = 0,                 %% 挂售分类 - 小类
        gid = 0,                    %% 物品ID
        pid = 0,                    %% 角色ID
        nickname = <<>>,
        accname = <<>>,
        goods_id = 0,               %% 物品类型ID
        goods_name = <<>>,          %% 物品名称
        num = 0,                    %% 数量
        type = 0,                   %% 物品类型
        subtype = 0,                %% 物品子类型
        lv = 0,                     %% 物品等级
        lv_num = 0,                 %% 等级分段
        color = 0,                  %% 颜色
        career = 0,                 %% 职业
        price_type = 0,             %% 价格类型
        price = 0,                  %% 价格
        time = 0,                   %% 时长，单位：小时
        end_time = 0,               %% 结束时间
        is_expire = 0,              %% 是否过期，1是
        expire_time = 0             %% 过期结束时间
    }).

%% 挂售分类表
-record(ets_sell_class, {
       min_type,                    %% 小分类ID
       name,                        %% 分类名称
       max_type,                    %% 所属大类
       career,                      %% 职业
       sex,                         %% 性别 0:无， 1:男， 2:女
       type_list                    %% 道具类型[{10,10},{10,20},{10,21}]
    }).

%% 求购列表
-record(ets_buy, {
        id = 0,                     %% 编号
        class1 = 0,                 %% 求购分类 - 大类
        class2 = 0,                 %% 求购分类 - 小类
        pid = 0,                    %% 角色ID
        goods_id = 0,               %% 物品类型ID
        goods_name = <<>>,          %% 物品名称
        num = 0,                    %% 数量
        type = 0,                   %% 物品类型
        subtype = 0,                %% 物品子类型
        lv = 0,                     %% 物品等级
        lv_num = 0,                 %% 等级分段
        color = 0,                  %% 颜色
        career = 0,                 %% 职业
        prefix = 0,                 %% 前缀
        stren = 0,                  %% 强化
        price_type = 0,             %% 价格类型
        price = 0,                  %% 价格
        time = 0,                   %% 时长，单位：小时
        end_time = 0                %% 结束时间
    }).

%%交易市场状态
-record(sell_status, {
        totals = 0,         % 总记录数
        caches = []         % 无条件查询的前12条记录
    }).

