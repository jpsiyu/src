%%------------------------------------------------------------------------------
%% @Module  : lib_boss
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.6.20
%% @Description: BOSS系统数据定义
%%------------------------------------------------------------------------------

-define(UPDATE_TIMES, 60*1000). %定时器检测周期
%-define(UPDATE_TIMES, 5*1000). %定时器检测周期


%% BOSS系统状态
-record(boss_state, {
    monitems = [],  %% BOSS怪物配置
    active_time=0   %%
}).

%% BOSS怪物配置
-record(monitem, {
    %--------------怪物数据-----------------%
    id=0,                     %% 数据库ID
    boss_id=0,                %% 怪物类型ID
    boss_rate=0,              %%
    refresh_type=0,           %% 刷新类型【0定时长刷新，1定时间点刷新】
    refresh_times=0,          %% 刷新时长
    refresh_times_point_6=[], %% 刷新时间点
    refresh_times_point_3=[], %% 刷新时间点
    refresh_place=[],         %% 刷新地点
    refresh_num=1,            %% 刷新数量
    notice=0,                 %% 是否公告
    living_time=0,            %% 出生后存活时间
    active=0,                 %% 是否主动攻击敌人
    starttime=0,              %% 怪物开始刷新日期
    endtime=0,                %% 怪物结束刷新日期
    %-----------服务器处理数据--------------%
    mon_id=0,                 %% 怪物Id
    mon_type=0,               %% 怪物类型【0默认怪物，1委托销毁怪物】
    mon_born_time=0,          %% 出生时间
    mon_die_time=0,           %% 死亡时间
    mon_check_time=0          %% 上次定时器扫描时间
}).

%% BOSS怪物表
-record(ets_boss, {
    id = 0,                       %% 数据库ID
    boss_id = 0,                  %% 怪物类型ID
    boss_rate = [],               %% 刷新概率
    refresh_type = 0,             %% 刷新类型【0定时长刷新，1定时间点刷新】
    refresh_times = 0,            %% 刷新时长
    refresh_times_point_6 = [],   %% 刷新时间点[6小时]
    refresh_times_point_3 = [],   %% 刷新时间点[3小时]
    refresh_place = [],           %% 刷新地点
    refresh_num = 0,              %% 刷新数量
    notice = 0,                   %% 是否公告
    living_time = 0,              %% 出生后存活时间
    active = 0,                   %% 是否主动攻击敌人
    starttime = 0,                %% 怪物开始刷新日期
    endtime = 0,                  %% 怪物结束刷新日期
    mon_id = 0,                   %% 怪物Id
    mon_type = 0,                 %% 怪物类型【0默认怪物，1委托销毁怪物】
    mon_born_time = 0,            %% 出生时间
    mon_die_time = 0,             %% 死亡时间
    mon_check_time = 0            %% 上次定时器扫描时间
}).

