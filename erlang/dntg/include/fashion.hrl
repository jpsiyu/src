%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-8-10
%% Description: 时装形象转换 record
%% --------------------------------------------------------

-define(sql_change_select, <<"select `pos`, `pid`, `old_id`, `new_id`, `time`, `original`, `gid` from `fashion_change` where `pid` = ~p">>).
-define(sql_change_insert, <<"insert `fashion_change` set `pos`=~p, `pid`=~p, `old_id`=~p, `new_id`=~p, `time`=~p, `original`=~p, `gid`=~p">>).
-define(sql_change_insert2, <<"insert `fashion_change` set `pos`=~p, `pid`=~p, `new_id`=~p, `time`=~p, `original`=~p, `gid`=~p">>).
-define(sql_change_update, <<"update `fashion_change` set `time`=~p, `new_id`=~p, `gid`=~p where `pid`=~p and `pos`=~p">>).
-define(sql_change_delete, <<"delete from `fashion_change` where `pid`=~p and `pos`=~p and `gid` = ~p">>).
-define(sql_change_update2, <<"update `fashion_change` set `gid` = ~p where `pid` = ~p and `pos` = ~p and `original` = ~p">>).
-define(sql_change_update3, <<"update `fashion_change` set `new_id` = ~p, `time` = ~p where `gid` = ~p">>).
-define(sql_change_update4, <<"update `fashion_change` set `new_id` = ~p, `time` = ~p where `gid` = ~p and pos = 4">>).
-define(sql_update_fashion_goods, <<"update goods_low set gtype_id = ~p where gid = ~p">>).
-define(sql_update_fashion_goods2, <<"update goods_high set goods_id = ~p where gid = ~p">>).

%% 衣橱
-define(sql_wardrobe_select, <<"select id, pid, pos, goods_id, time, state from wardrobe where pid=~p">>).

%-define(FASHION_ONE, [106101,106102,106103,106074,106084,106094,106271,106272,106273,106311,106321,106331,106401,106501]).
%-define(FASHION_TWO,[106104,106105,106106,106019,106029,106039,106218,106228,106238,106304,106305,106306,106402,106502]).
%-define(FASHION_THREE, [106108,106109,106110,106012,106022,106032,106211,106221,106231,106308,106309,106310,106403,106503]).
%-define(FASHION_FOUR, [106111,106121,106131,106075,106085,106095,106274,106275,106276,106312,106322,106332,106404,106504]).
%-define(FASHION_FINE, []).
%-define(FASHION_SIX, []).

%% 形象转换
-record(ets_change, {
        pos = 0,        %% 转换位置,1:衣服 2:武器 3:饰品 4坐骑
        pid = 0,        %% 玩家id
        old_id = 0,     %% 旧形象id
        new_id = 0,     %% 新形象id
        time = 0,       %% 到期时间
        original = 0,   %% 原始物品类型id
        gid = 0         %% 原始物品id
    }).

%% 衣橱
%-record(ets_wardrobe, {
%      id = 0,         %% 编号
%        pid = 0,        %% 玩家的id
%        pos = 0,        %% 位置
%        goods_id = 0,   %% 类型ID
%        time = 0,       %% 到期时间
%        state = 0　　　 %% 状态, 1:未到期 2:到期 3:永久
%    }).

-record(ets_wardrobe, {
        id = 0,         %% 编号
        pid = 0,        %% 玩家id
        pos = 0,        %% 位置
        goods_id = 0,   %% 类型ID
        time = 0,       %% 到期时间
        state = 0       %% 1:未到期 2:到期 3:永久
    }).


