%% ---------------------------------------------------------
%% Author:  zhenghehe
%% Created: 2012-02-07
%% Description: 离线相关 record
%% --------------------------------------------------------
%离线修炼托管
-record(practice_outline, {
    id = 0,
    role_id = 0,
    practice_time = 0,
    time = 0
    }).

%烧酒离线托管
-record(wine_outline, {
    id = 0,                 %% 玩家ID
    last_wine_time = 0,     %% 上次喝酒零点时间戳
    exp_days = 0            %% 可领取经验天数
    }).
    


%离线修炼
-record(practice, {
    role_id         = 0     %% 角色id
    ,time           = 0     %% 修炼总时长
    ,quick_time     = 0     %% 加速时间【加速之后时间先减去每次加速时间】
    ,begin_time     = 0     %% 开始修炼时间
    ,end_time       = 0     %% 预计结束时间
    ,status         = 0     %% 状态，0=已完成，1=修炼中
    ,is_gold        = 0     %% 是否金币修炼
    ,level          = 0     %% 开始修炼时的角色的等级
    ,pause_time     = 0     %% 暂停修炼时间
}).

-define(PRACTICE_SCENE_IN, 999). %修炼场景ID

-define(PRACTICE_SCENE_OUT_HAN, 220).%传出场景ID->s汉国
-define(PRACTICE_SCENE_OUT_QIN, 220).%传出场景ID->s秦国
-define(PRACTICE_SCENE_OUT_CHU, 220).%传出场景ID->s楚国

-define(DAILY_TYPE_PRAC, 1000).%修炼daily_log表类型

-define(TICK_COST, 5).           %每次传入需要收费元宝