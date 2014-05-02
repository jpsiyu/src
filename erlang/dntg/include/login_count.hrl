%% ---------------------------------------------------------
%% Author:  HHL
%% Email:   
%% Created: 2014-3-7
%% Description: 累积登录签到 连续登录 及 间隔登录（用于连续登录礼包及回归礼包
%% --------------------------------------------------------
-record(ets_login_counter, {
        id = 0,                         %% 玩家Id
        last_login_time = 0,            %% 最后登录时间
        last_logout_time = 0,           %% 上次退出时间
        continuous_days = 0,            %% 连续登录天数
        no_login_days = 0,              %% 未登录天数
        last_correct_time = 0,          %% 上次修正连续登录天数的对应午夜时间
        continuous_gift = [],           %% 连续登录礼包列表
        no_login_gift = [],             %% 回归登录礼包列表
        reset_time = 0,                 %% 重置连续登录天数的午夜时间
        is_charged = 0                  %% 是否充值过
        }).

%% ets
-define(ETS_LOGIN_COUNTER, ets_login_counter).          %% 连续登录及回归信息

%% sql
-define(sql_player_login_select, <<"select last_login_time, last_logout_time from player_login where id=~p">>).
-define(sql_continuous_select, <<"select continuous_days, no_login_days, last_correct_time, reset_time, continuous_gift, no_login_gift from continuous_login_gift where id=~p">>).
-define(sql_continuous_reset_time, <<"update continuous_login_gift set continuous_days=0,reset_time=~p where id=~p limit 1">>).
-define(sql_continuous_update_info,<<"update continuous_login_gift set continuous_days=~p,no_login_days=~p,last_correct_time=~p,continuous_gift='~s',no_login_gift='~s' where id=~p limit 1">>).
-define(sql_continuous_insert, <<"insert into `continuous_login_gift` set id=~p, continuous_days=~p, no_login_days=~p, last_correct_time=~p, continuous_gift='~p', no_login_gift='~p'">>).


%% ==========================================大闹天空=================================================================
%% dict 累积登录的进程字典的key值
-define(CUMULATIVE_LOGIN_KEY(Id), lists:concat(["cumulative_login", Id])).
-define(FAN_PAI_KEY(RoleId), lists:concat(["fan_pai_key_", RoleId])).

%% 累积签到
-record(cumulative_login, {
        role_id = 0,                    %% 玩家Id
        mouth = 0,                      %% 月份
        sign_count = 0,                 %% 累积签到次数
        used_sign_add_count = 0,        %%　已经使用的补签次数
        login_week_count = 0,           %% 周连续登录次数  
        sign_days = [],                 %% 签到的日期 [{day, is_sign}, {}]....
        gift_list = [],                 %% 累积签到物品领取列表[{sign_day, [{goods_id, num, is_vip, is_get}, {}, {}]}, {}]...
        drop_count = 0,                 %% 翻牌次数
        time = 0                        %% 数据库数据时间
    }).

%%　获取玩家累积登录信息
-define(sql_select_cumulative_login_by_id, 
        <<"select role_id, mouth, sign_count, used_sign_add_count, login_week_count, sign_days, gift_list, drop_count, time FROM log_cumulative_login WHERE role_id=~p">>).

%% 新增和更新玩家累积信息
-define(sql_replace_cumulative_login_info, 
        <<"REPLACE INTO  log_cumulative_login SET role_id=~p, mouth=~p, sign_count=~p, used_sign_add_count=~p, login_week_count=~p, sign_days='~s', gift_list='~s', drop_count=~p, time=~p">>).















