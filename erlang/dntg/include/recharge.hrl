%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.6.15
%%% @Description: 充值相关
%%%--------------------------------------

-define(PAY_EXPIRE_TIME, 150).     %% 超时秒数
-define(PAY_TOTAL_RECHARGE(RoleId), lists:concat(["recharge_total_gold_", RoleId])).

%% 充值后更新总充值金额
-define(sql_recharge_update_total, <<"UPDATE player_recharge SET total=~p WHERE id=~p">>).
%% 查询总充值金额
-define(sql_recharge_get_total, <<"SELECT `total` FROM player_recharge WHERE id=~p">>).
%% 取出充值待处理的记录
-define(sql_pay_fetch_all, <<"SELECT `id`, `player_id`, `ctime` FROM `charge` WHERE `status`=0">>).
%% 更新充值待处理的记录的状态为已处理
-define(sql_pay_update_recharge, <<"UPDATE `charge` SET `status`=1 WHERE id=~p AND `status`=0">>).
%% 取出指定玩家所有待处理的充值记录
-define(sql_pay_fetch_all_of_user, <<"SELECT `id`, `type`, `gold`, `ctime`, `pay_no` FROM `charge` WHERE `player_id`=~p AND `status`=0 ORDER BY `id`">>).
%% 取出充值任务期间玩家的充值总额
-define(sql_pay_task_get_gold, <<"SELECT SUM(gold) FROM charge WHERE player_id=~p AND ctime BETWEEN ~p AND ~p">>).
%% 取出充值元宝道具使用总额
-define(sql_gold_goods_total, <<"SELECT SUM(gold) FROM log_gold_goods WHERE id=~p AND time BETWEEN ~p AND ~p">>).

