%% --------------------------------------------------------
%% @Module:           |
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-03-22
%% @Description:      |运势任务
%% --------------------------------------------------------

-define(FORTUNE_DAILY_ID,   3700001).		%% 运势日常ID
-define(FORTUNE_REFRESH_TASK,    30 * 60).   	%% 运势刷新间隔，秒
-define(FORTUNE_REFRESH_COLOR,   30).   	%% 运势刷新间隔，秒
-define(FORTUNE_HELP,      300).     		%% 求助刷新间隔，秒


%% 玩家运势信息 
-record(rc_fortune, {
        role_id = 0,                %% 角色ID
		role_color = 0,             %% 角色运势
        task_color = 0,             %% 任务颜色
        refresh_left = 5,           %% 可帮人刷新颜色次数
		refresh_color_time = 0,     %% 帮人刷新颜色时间
        brefresh_num = 0,           %% 被刷新颜色次数
        task_id = 0,                %% 任务ID
        count = 0,                  %% 任务统计数
        refresh_task = 0,           %% 刷新的任务
        refresh_time = 0,           %% 下次刷新时间
		call_help_time = 0,         %% 请求帮助时间
        status = 0                  %% 任务完成状态，0未接取，1已接取，2已完成，3已交任务
    }).

%% 玩家运势任务颜色刷新日志
-record(rc_fortune_log, {
        role_id = 0,                %% 所属觉得
        refresh_role = 0,           %% 帮助刷新的玩家的ID
        refresh_fortune = 0,        %% 帮助刷新的玩家的运势
        task_id = 0,                %% 任务ID
        color = 0,                  %% 任务颜色
        rdate = 0                   %% 刷新时间
    }).

