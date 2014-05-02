%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-22
%% Description: 开宝箱 ets record
%% --------------------------------------------------------

%% 兑换装备列表
-define(CHANGE_LIST, [10201031, 10211031, 10221031, 10231031, 10241031, 10251031,
                      10202031, 10212031, 10222031, 10232031, 10242031, 10252031,
                      10203031, 10213031, 10223031, 10233031, 10243031, 10253031]).
%% 开服兑换时间
-define(CHANGE_DAYS, 7).  

%% 记录兑换件数
-define(sql_select_exchange, <<"select type_list, gift_list from equip_exchange where pid=~p">>).
-define(sql_insert_exchange, <<"insert into equip_exchange set pid=~p,type_list=~p, time=UNIX_TIMESTAMP()">>).
-define(sql_update_exchange, <<"update equip_exchange set type_list=~p, time=UNIX_TIMESTAMP() where pid=~p">>).
-define(sql_update_exchange2, <<"update equip_exchange set gift_list=~p where pid=~p">>).
-define(GIFT_LIST, [532451, 532452, 532453]).

%% ets表
-define(ETS_BOX_COUNTER, ets_box_counter).                      %% 宝箱全局计数
-define(ETS_BOX_PLAYER_COUNTER, ets_box_player_counter).        %% 宝箱单玩家计数

-define(SQL_BOX_COUNTER_SELECT,                 <<"select count,limit_goods from `box_counter` where box_id=~p ">>).
-define(SQL_BOX_COUNTER_SELECT_ALL,             <<"select box_id,count,limit_goods from `box_counter` ">>).
-define(SQL_BOX_COUNTER_INSERT,                 <<"insert into `box_counter` set box_id=~p, limit_goods='[]' ">>).
-define(SQL_BOX_COUNTER_UPDATE,                 <<"update `box_counter` set count=~p, limit_goods='~s' where box_id=~p  ">>).
-define(SQL_BOX_PLAYER_COUNTER_SELECT,          <<"select pid,box_id,count,guard,limit_goods from `box_player_counter` where pid=~p and box_id=~p ">>).
-define(SQL_BOX_PLAYER_COUNTER_SELECT_ALL,      <<"select pid,box_id,count,guard,limit_goods from `box_player_counter` ">>).
-define(SQL_BOX_PLAYER_COUNTER_INSERT,          <<"insert into `box_player_counter` set pid=~p, box_id=~p, limit_goods='[]' ">>).
-define(SQL_BOX_PLAYER_COUNTER_UPDATE,          <<"update `box_player_counter` set count=~p, guard=~p, limit_goods='~s' where pid=~p and box_id=~p  ">>).
-define(SQL_BOX_PLAYER_COUNTER_DELETE,          <<"delete from `box_player_counter` where pid=~p ">>).
-define(SQL_BOX_BAG_SELECT,                     <<"select goods_list from `box_bag` where pid = ~p  ">>).
-define(SQL_BOX_BAG_INSERT,                     <<"insert into `box_bag` set pid=~p, goods_list='[]' ">>).
-define(SQL_BOX_BAG_UPDATE,                     <<"update `box_bag` set goods_list='~s' where pid=~p ">>).
-define(SQL_BOX_BAG_DELETE,                     <<"delete from `box_bag` where pid=~p ">>).

%% 兑换记录
-record(ets_box_exchange,{
        pid = 0,            %% 玩家ID
        type_list = [],     %% 兑换装备ID列表
        gift_list = []     %% 已领取的礼包列表
    }).

%%宝箱配置
-record(ets_box, {
        id=0,                   %% 宝箱ID
        name = <<>>,            %% 宝箱名称
        price=0,                %% 开1次宝箱价格
        price2=0,               %% 开10次宝箱价格
        price3=0,               %% 开50次宝箱价格
        base_goods=[],          %% 保底物品
        guard_num=0,            %% 保护几率
        ratio=0,                %% 机率范围
        high_box=0,             %% 高级物品全服限制
        high_player=0,          %% 高级物品个人限制
        goods_list=[]           %% 物品列表
    }).

%%宝箱物品配置
-record(ets_box_goods, {
        id=0,                   %% 编号
        box_id=0,               %% 宝箱ID
        goods_id=0,             %% 物品ID
        type=0,                 %% 类型，0 普通物品，1 高级物品
        bind=0,                 %% 物品绑定状态，0 不绑定，2 已绑定
        notice=0,               %% 通告类型，0 普通，1 全服
        ratio=0,                %% 机率范围
        ratio_start=0,          %% 机率开始值
        ratio_end=0,            %% 机率结束值
        lim_box=0,              %% 全服限制，至少N小时才能掉一个
        lim_player=0,           %% 个人限制，至少N秒才能掉一个
        lim_num=0,              %% 次数限制，至少N次才能掉一个
        lim_career=0,           %% 职业限制
        goods_num = 1           %% 物品数量
    }).

%% 开宝箱全局计数
-record(ets_box_counter, {
        box_id=0,               %% 宝箱ID
        count=0,                %% 开箱计数
        limit_goods=[]          %% 限制物品，格式：[ { 物品ID, 限制时间 }, ... ]
    }).

%% 开宝箱单玩家计数
-record(ets_box_player_counter, {
        pid=0,                  %% 玩家ID
        box_id=0,               %% 宝箱ID
        count=0,                %% 开箱计数
        guard=0,                %% 是否已使用保护几率，0 未保护过，1 已保护过
        limit_goods=[]          %% 限制物品，格式：[ { 物品ID, 限制时间, 限制次数 }, ... ]
    }).

