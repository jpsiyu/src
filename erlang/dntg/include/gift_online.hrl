%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.2
%%% @Description: 在线倒计时奖励
%%%--------------------------------------

%% 特殊倒计时开始时间
-define(SP_ONLINE_START_AT, {{2098,12,29},{0,0,0}}). 
-define(SP_ONLINE_END_AT, {{2099,1,4},{0,0,0}}). 

%% 查询在线倒计时奖励数据
-define(SQL_ONLINE_AWARD_GET, <<"SELECT get_num, last_offline, need_time FROM `gift_online` WHERE id=~p">>).

%% 插入一条记录
-define(SQL_ONLINE_AWARD_INSERT, <<"INSERT INTO `gift_online`(id, get_num, last_offline, need_time) VALUES(~p, ~p, ~p, ~p)">>).

%% 更新记录
-define(SQL_ONLINE_AWARD_UPDATE, <<"UPDATE `gift_online` SET get_num=~p, last_offline=~p, need_time=~p WHERE id=~p">>).




%% ==========================================大闹天空：在线礼包领取=================================================================
%% dict 在线的进程字典的key值
-define(LOGIN_ONLINE_KEY(Id), lists:concat(["login_online_key", Id])).

%% 累积签到
-record(login_online_gift, {
        role_id = 0,                    %% 玩家Id
        count = 0,                      %% 领取次数
        gift_list = [],                 %% 领取列表[{id, {goods_id, num}, time, is_can_get}...]...
        online_time = 0,                %% 在线时间
        time = 0                        %% 数据库更新时间(登录时为最后一次登录时间)
    }).


-record(online_gift_goods, {
                            id = 0, 
                            lv = 0,
                            goods = [], %% [{Type, GoodsId, Num}],
                            time_span = 0,
                            is_get = 0
                            }).

% 查询玩家在线礼包的数据
-define(SQL_ONLINE_INFO, <<"SELECT role_id, count, gift_list, online_time, time FROM log_gift_online WHERE role_id=~p">>).

%% 插入一条记录
-define(SQL_ONLINE_INSERT, <<"INSERT INTO log_gift_online(role_id, count, gift_list, online_time, time) VALUES(~p, ~p, '~s', ~p, ~p)">>).

%% 更新记录
-define(SQL_ONLINE_UPDATE, <<"UPDATE log_gift_online SET count=~p, gift_list='~s', online_time=~p, time=~p WHERE role_id=~p">>).

%% 更新记录在线时间
-define(SQL_ONLINE_TIME_UPDATE, <<"UPDATE log_gift_online SET online_time=~p, time=~p WHERE role_id=~p">>).



