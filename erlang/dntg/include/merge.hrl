%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.9.27
%%% @Description: 合服活动
%%%--------------------------------------

%% 表merge字段说明：
%% activity1 : 惊喜一：豪华礼包大回馈
%% activity2 : 
%% activity3 :
%% activity4 :
%% activity5 :
%% activity6 :
%% activity7 :
%% activity8 :
%% activity9 :
%% activity10 :


%% 首服充值活动涉及到的三个礼包
-define(MERGE_GIFT_1, 0).
-define(MERGE_GIFT_2, 0).
-define(MERGE_GIFT_3, 0).
-define(MERGE_GIFT_4, 0).
-define(MERGE_GIFT_5, 0).
-define(MERGE_GIFT_6, 0).

%% 合服活动：活动统计表
-define(sql_merge_stat_insert, <<"REPLACE INTO `merge` SET id=1, activity_time=~p,  
	activity1=~p, activity2=~p, activity3=~p, activity4=~p, activity5=~p, activity6=~p, 
	activity7=~p, activity8=~p, activity9=~p, activity10=~p">>).
-define(sql_merge_stat_select, <<"SELECT activity_time FROM `merge` WHERE id=1">>).
-define(sql_merge_stat_select1, <<"SELECT `~s` FROM `merge` WHERE id=1">>).
-define(sql_merge_stat_delete, <<"DELETE FROM `merge`">>).
-define(sql_merge_stat_update, <<"UPDATE `merge` SET `~s`=~p WHERE id=1">>).

%% 合服活动：累积充值礼包领取统计表
-define(sql_merge_recharge_gift_insert, <<"INSERT INTO `merge_recharge_gift`(id, gift_id, gift_status) VALUES(~p, ~p, ~p)">>).
-define(sql_merge_recharge_gift_select, <<"SELECT gift_id FROM `merge_recharge_gift` WHERE id=~p">>).
-define(sql_merge_recharge_gift_delete, <<"DELETE FROM `merge_recharge_gift`">>).

%% 合服活动：充值总额
-define(sql_merge_recharge_update, <<"UPDATE player_recharge SET `merge`=`merge` + ~p WHERE id=~p">>).
-define(sql_merge_recharge_update2, <<"UPDATE player_recharge SET `merge`=0 WHERE id>0">>).
-define(sql_merge_recharge_select, <<"SELECT `merge` FROM player_recharge WHERE id=~p">>).
