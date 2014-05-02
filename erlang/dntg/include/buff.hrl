%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-4
%% Description: buff, 温泉, 采矿 ets
%% --------------------------------------------------------
%%--------------------------BUFF宏定义----------------------------------------
-define(ETS_GAME_BUFF, ets_game_buff).                          %% 游戏世界buff
%%--------------------------BUFF宏定义----------------------------------------
%%服务器buff定义
-define(EXP_MON, 1).   %打怪经验
-define(EXP_WATER, 2). %一般温泉温泉经验
-define(EXP_VIP_WATER, 3). %vip温泉经验
-define(EXP_GUILD_BOSS, 5). %帮派boss篝火

%% 游戏世界buff
-record(ets_game_buff, {
    id = 0, %%id
    bufftype = 0, %% buff类型
    buffnum = 0,  %% 加倍类型
    start_time = 0, %%开始时间
    end_time = 0    %%结束时间
    }).

%% BUFF状态表
-record(ets_buff, {
        id=0,                       %% 编号
        pid=0,                      %% 角色ID
        type=0,                     %% BUFF类型，1 经验卡，2 BUFF符, 3烧酒
        goods_id=0,                 %% 物品类型ID
        attribute_id=0,             %% 属性类型ID
        value=0,                    %% 属性值 decimal(10,3)
        end_time=0,                 %% 结束时间戳
        scene = []                  %% 场景限制
    }).

%% VIP BUFF冻结&解冻状态表
-record(ets_vip_buff, {
        id = 0,                       %% 编号
		buff = #ets_buff{},		%% buff表
		rest_time = 0,			%% 剩余时间(秒)
		state = 0				%% 状态(0:未领取, 1:已解冻, 2:已冻结)
    }).

%%buff温泉
-record(ets_buff_watar, {
        id = 0,             %%ID
        type = 0,             %%温泉类型
        bufftype = 0,         %%buff类型
        buffnum = 0,          %%buff量/次
        buff_rand = 0,        %%buff范围
        opentime = [],        %%开启时间[{StartTime1,EndTime1},{StartTime2,EndTime2}]
        needbuff = 0,         %%需求buff类型
        born_scene = 0,       %%诞生场景
        born_x = 0,           %%诞生坐标-x
        born_y = 0,           %%诞生坐标-y
        born_npc = 0,         %%诞生NPC

        borntime = 0,         %%温泉诞生时间
        last_atime = 0,       %%温泉上次活动时间
        notice = 0,           %%是否公告
        notice_content = [],  %%公告内容
        pid = 0               %%进程ID
        }).

%% 采矿
-record(collector, {
        id,                     %% 角色Id
        mon_id = 0,             %% 矿点Id，0表示未采矿
        start_time = 0,         %% 开始采矿时间
        last_time = 0,          %% 上一次掉落时间
        fail_times = [],        %% 各矿物失败次数([{GoodsTypeId, FailTimes}, ...])
        bag_num = 35,           %% 采矿背包格子数，可扩展
        bag = [],               %% 采矿背包（[{GoodsTypeId, Num}, ...]）
        prof = 10               %% 采矿熟练度
    }).

%% 矿点
-record(lode, {
        id,                     %% 矿点Id
        mid,                    %% 怪物类型Id
        roles = [],             %% 玩家Id列表, [{PlayerId1, Pid1}, {PlayerId2, Pid2}, ...]
        created_mons = []       %% 由这个矿点中生成的怪物列表[{MonTypeId, MonIdList}, ...]
    }).
