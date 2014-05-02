%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-9-7
%% Description: 武器注灵
%% --------------------------------------------------------

-define(sql_reiki_select, <<"select level, qi_level, att, times, attribute from add_reiki where gid = ~p">>).
-define(sql_reiki_update, <<"update add_reiki set level=~p, att='~s', times =~p where gid = ~p">>).
-define(sql_reiki_insert, <<"insert into add_reiki set level=~p, qi_level=~p,
    att='~s', times=~p, attribute='~s', gid = ~p">>).

%%注灵最高等级
-record(reiki_level, {
        id,         %% 物品ID后两位
        level       %% 注灵等级上限
    }).

%% 消耗规则
-record(reiki_cost, {
        type,       %% 装备类型
        level,      %% 注灵等级 
        value,      %% 增加属性,格式{type, value}
        llpt,       %% 消耗历练声望
        times,      %% 幸运值
        radio       %% 成功率
    }).

%% 用元宝提升器灵规则
-record(reiki_up, {
        level,      %% 器灵等级
        need_level, %% 需求注灵等级
        gold,       %% 元宝
        forza,	    %% 力量
        agile,	    %% 身法
        wit,	    %% 灵力
        thew	    %% 体质
    }).

