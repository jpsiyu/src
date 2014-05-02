%% ---------------------------------------------------------
%% Author:  xyao 
%% Email:   jiexiaowen@gmail.com
%% Created: 2012-5-4
%% Description: 日 ,周,目标 ets
%% --------------------------------------------------------

-define(DAILY_KEY(Id), lists:concat(["mod_daily_", Id])). 

%% 每天记录
-record(ets_daily, {
        id            = {0, 0},  %% {角色id, 类型}
        count        = 0,          %% 数量
        refresh_time = 0          %% 最后修改时间
    }
).

%% 每日成就
-record(ets_target_day, {
        id = 0,         %% 玩家id
        finish_num = 0, %% 完成的事件
        event = [],     %% 事件内容[{事件标识, '物品/怪物/任务..id, 累计次数, 完成条件}]
        reward = [],    %% 领取奖励事件数
        time = 0        %% 领取时间
    }).

%% 周目标每日目标
-record(ets_target_week_task, {
        id = 0,                 %% 玩家id
        event_id = 0,           %% 当前事件
        fin_num = 0,            %% 完成数量
        fin_times = 0,          %% 今天完成目标次数
        fin_event_ids = [],     %% 今天已经完成的目标
        refresh_time = 0,       %% 刷新时间
        reward = 0              %% 是否已领取今天奖励
    }).

%% 周目标
-record(ets_target_week, {
        id = 0,         %% 玩家id
        score = 0,      %% 积分
        time = 0,       %% 领取时间
        reward = []     %% 领取的礼包id
    }).

%% 每天次数记录
-define(sql_daily_role_sel_all, <<"SELECT `role_id`, `type`, `count`, `refresh_time` FROM `daily_log` WHERE role_id=~p">>).
-define(sql_daily_role_sel_type, <<"SELECT `role_id`, `type`, `count`, `refresh_time` FROM `daily_log` WHERE `role_id` =~p AND `type` =~p">>).
-define(sql_daily_role_add, <<"INSERT INTO `daily_log` (`role_id`, `type`, `count`, `refresh_time`) VALUES (~p, ~p, ~p, ~p);">>).
-define(sql_daily_role_upd_count, <<"UPDATE `daily_log` SET `count` = ?, `refresh_time` = ? WHERE `role_id` =~p AND `type` =~p">>).
-define(sql_daily_role_upd, <<"REPLACE INTO `daily_log` (`role_id`, `type`, `count`, `refresh_time`) VALUES (~p, ~p, ~p, ~p)">>).
-define(sql_daily_clear,<<"truncate table `daily_log`">>).

%% 每天次数记录
-define(sql_daily_task_role_sel_all, <<"SELECT `role_id`, `type`, `count`, `refresh_time` FROM `daily_log_task` WHERE role_id=~p">>).
-define(sql_daily_task_role_sel_type, <<"SELECT `role_id`, `type`, `count`, `refresh_time` FROM `daily_log_task` WHERE `role_id` =~p AND `type` =~p">>).
-define(sql_daily_task_role_add, <<"INSERT INTO `daily_log_task` (`role_id`, `type`, `count`, `refresh_time`) VALUES (~p, ~p, ~p, ~p);">>).
-define(sql_daily_task_role_upd_count, <<"UPDATE `daily_log_task` SET `count` = ?, `refresh_time` = ? WHERE `role_id` =~p AND `type` =~p">>).
-define(sql_daily_task_role_upd, <<"REPLACE INTO `daily_log_task` (`role_id`, `type`, `count`, `refresh_time`) VALUES (~p, ~p, ~p, ~p)">>).
-define(sql_daily_task_clear,<<"truncate table `daily_log_task`">>).
