%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.6.25
%%% @Description: 运营活动
%%%--------------------------------------

-define(ACTIVITY_TYPE_1,	1).                 %% 收藏游戏奖励
-define(ACTIVITY_TYPE_2,	2).                 %% 每日活跃度
-define(ACTIVITY_TYPE_3,	3).                 %% 等级向前冲

%% 下面为完成时的统计，例如完成时就不出现在界面
-define(ACTIVITY_FINISH_TARGET, 100).			%% 领取完所有目标奖励
-define(ACTIVITY_FINISH_LEVEL_FORWARD, 101).    %% 领取完所有升级向前冲奖励
-define(ACTIVITY_FINISH_RECHARGE_GIFT, 102).    %% 领取完首服充值礼包
-define(ACTIVITY_FINISH_CHARM_RANK, 103).		%% 中秋国庆活动鲜花榜和护花榜
-define(ACTIVITY_FINISH_MERGE, 104).			%% 合服图标
-define(ACTIVITY_FINISH_LOGIN, 105).			%% 登录器
-define(ACTIVITY_FINISH_MERGE_RECHARGE, 106).	%% 合服充值礼包图标
-define(ACTIVITY_FINISH_SEVEN_DAY, 107).		%% 开服七天登录图标
-define(ACTIVITY_FINISH_BACK_ACTIVITY, 108).	%% 幸福回归图标
-define(ACTIVITY_FINISH_RECHARGE_AWARD, 109).	%% 充值送礼礼包
-define(ACTIVITY_RECHARGE_5_DAYS, 110).			%% 5天充值送礼礼包
-define(ACTIVITY_RECHARGE_FESTIVAL_1, 111).		%% 节日充值活动:类型1图标(相关315节日活动协议)
-define(ACTIVITY_KF_POWER_RANK, 112).			%% 斗战封神活动
-define(ACTIVITY_100_SERVERS, 113).				%% 100服活动
-define(ACTIVITY_RECHARGE_RE, 115).				%% 115充值送礼活动可重复计数礼包计数
-define(ACTIVITY_FINISH_RECHARGE_AWARD_TMP, 116).	%% 临时，春节版, 充值送礼礼包
-define(ACTIVITY_FINISH_ALL_ID, [100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 113, 116]).

%% 首服充值活动涉及到的礼包
-define(ACTIVITY_RECHARGE_GIFT_1, 532001).
-define(ACTIVITY_RECHARGE_GIFT_2, 532021).
-define(ACTIVITY_RECHARGE_GIFT_3, 532022).
-define(ACTIVITY_RECHARGE_GIFT_4, 532023).
-define(ACTIVITY_RECHARGE_GIFT_5, 532024).
-define(ACTIVITY_RECHARGE_GIFT_6, 532025).

%% 这条sql插入的content为数字，如果需要字符串，再写一条sql
-define(sql_activity_update, <<"REPLACE INTO `activity_stat`(`id`, `type`, `content`) VALUES(~p, ~p, ~p)">>).
-define(sql_activity_update2, <<"REPLACE INTO `activity_stat`(`id`, `type`, `content`) VALUES(~p, ~p, '~s')">>).
-define(sql_activity_update3, <<"UPDATE `activity_stat` SET `content`='~s' WHERE `id`=~p AND `type`=~p">>).
-define(sql_activity_fetch_row, <<"SELECT `content` FROM `activity_stat` WHERE `id`=~p AND `type`=~p LIMIT	1">>).
-define(sql_activity_fetch_all, <<"SELECT `type`, `content` FROM `activity_stat` WHERE `id`=~p AND `type` IN(~s)">>).
-define(sql_activity_fetch_all2, <<"SELECT `type`, `content` FROM `activity_stat` WHERE `id`=~p">>).
-define(sql_activity_sevenday_fetch, <<"SELECT signup_num, gift_list, last_time FROM activity_sevenday_signup WHERE id=~p">>).
-define(sql_activity_sevenday_update, <<"UPDATE activity_sevenday_signup SET gift_list='~s' WHERE id=~p">>).
-define(sql_activity_sevenday_update2, <<"UPDATE activity_sevenday_signup SET last_time=~p, signup_num=signup_num+1 WHERE id=~p">>).
-define(sql_activity_sevenday_insert, <<"REPLACE INTO activity_sevenday_signup SET id=~p,signup_num=~p,gift_list='[]',last_time=~p">>).

%% 老玩家回归活动sql
-define(sql_player_last_login_time,<<"select logout_time from player_login  where id=~p limit 1">>).
-define(sql_activity_back_add,<<"insert into activity_back(`role_id`, `type`, `state`,`trigger_time`) values(~p, ~p, ~p, ~p)">>).
-define(sql_activity_back_update,<<"update  activity_back set state=~p where role_id=~p and type=~p">>).
-define(sql_activity_back_state,<<"select state from activity_back  where role_id=~p and type=~p and (trigger_time between ~p and ~p) limit 1" >>).
-define(sql_old_buck_all,	<<"select a.id from player_low a left join player_login b on a.id=b.id where a.lv >= ~p and b.logout_time <= ~p">>).

%% 充值送礼活动
%% type的取值：
%% 		109充值送礼
%%		110开服5天充值活动(相关协议号13490, 13491)
%%		115充值送礼活动可重复计数礼包计数
-define(sql_activity_data_insert, <<"REPLACE INTO activity_data SET id=~p,type=~p,data='~s',addtime=~p">>).
-define(sql_activity_data_get, <<"SELECT data,addtime FROM activity_data WHERE id=~p AND type=~p">>).
-define(sql_activity_data_update, <<"UPDATE activity_data SET data='~s',addtime=~p WHERE id=~p AND type=~p">>).

%% 节日充值活动1
-define(sql_festival_data_replace, <<"REPLACE INTO fastival_recharge SET uid=~p, tag=~p, stamp=~p">>).
-define(sql_festival_data_select_1, <<"SELECT tag, stamp FROM fastival_recharge WHERE uid=~p">>).
-define(sql_festival_data_delete, <<"delete from fastival_recharge where uid=~p, tag=~p, stamp=~p">>).
-record(festivial_card, {
		id,               %% 贺卡Id
		is_read = 1,      %% 读取状态
		sender_id,        %% 发送角色Id
		sender_name = [], %% 发送角色昵称
		animation_id,     %% 动画Id
		gift_id,          %% 礼物Id
		wish_msg = [],    %% 祝福内容
		send_time = 0     %% 接受时间
	}).

%% 消费返元宝活动
-define(sql_consume_returngold_select_1, <<"select id, expenditure, the_day, status, fetch_time from activity_consume_returngold where uid=~p order by the_day desc">>).
-define(sql_consume_returngold_select_2, <<"select id from activity_consume_returngold where (the_day between ~p and ~p) and uid=~p limit 1">>).
-define(sql_consume_returngold_select_3, <<"select expenditure, status from activity_consume_returngold where id=~p limit 1">>).
-define(sql_consume_returngold_select_4, <<"select uid, expenditure, the_day, status, fetch_time from activity_consume_returngold where uid=~p order by the_day desc">>).
-define(sql_consume_returngold_insert, <<"insert into activity_consume_returngold(`uid`, `expenditure`, `the_day`) values(~p,~p,~p)">>).
-define(sql_consume_returngold_update_1, <<"update  activity_consume_returngold set expenditure=expenditure+~p where id=~p">>).
-define(sql_consume_returngold_update_2, <<"update  activity_consume_returngold set status=~p where id=~p">>).
-define(sql_consume_returngold_update_3, <<"update  activity_consume_returngold set status=2, fetch_time =~p where id=~p">>).
-define(sql_consume_returngold_delete, <<"delete  from activity_consume_returngold  where uid=~p">>).
-define(sql_log_consume_returngold_insert, <<"insert into log_activity_consume_returngold(`uid`, `expenditure`, `the_day`, `status`, `fetch_time`, `delete_time`) values(~p,~p,~p,~p,~p,~p)">>).
-record(consume_returngold, {
		id,				%% Id		
		expenditure,    %% 消费额
		the_day,        %% 当天零点unix时间戳
		status=0,       %% 领取状态	0不可领取 1可领取 2已领取 
		fetch_time =0   %% 领取时间
	}).

%% 元宵放花灯活动                                                              %%time>当前时间-24小时                                
-define(sql_festival_lamp_select_1, <<"select * from activity_festivial_lamp where time>~p and fetch_status=1">>).
-define(sql_festival_lamp_select_2, <<"select * from activity_festivial_lamp where time<~p and fetch_status=1">>).
-define(sql_festival_lamp_select_3, <<"select id from activity_festivial_lamp where role_id=~p order by id desc limit 1">>).
-define(sql_festival_lamp_select_4, <<"select fetch_status, time, bewish_num from activity_festivial_lamp where id=~p limit 1">>).
-define(sql_festival_lamp_select_5, <<"select * from activity_festivial_lamp where time<~p and fetch_status=~p">>).
-define(sql_festival_lamp_select_6, <<"select * from activity_festivial_lamp where fetch_status=~p">>).
-define(sql_festival_lamp_insert, <<"insert into activity_festivial_lamp(role_id, role_name, x, y, type, time) values(~p, '~s', ~p, ~p, ~p, ~p)">>).
-define(sql_festival_lamp_update_1, <<"update  activity_festivial_lamp set bewish_num=~p where id=~p">>).
-define(sql_festival_lamp_update_2, <<"update  activity_festivial_lamp set fetch_status=~p,is_sys_fetch=~p where id=~p">>).
-record(festivial_lamp, {
		id,               %% 花灯Id
		role_id,          %% 玩家Id
		role_name = [],   %% 玩家名     
        x=0,              %% x坐标
		y=0,              %% y坐标
		type=1,            %% 花灯类型 1低级花灯 2中级花灯 3高级花灯
		fire_time,         %% 燃放时间
		bewish_num=0,      %% 收到的祝福数
	    fetch_status = 1,  %% 收获状态 1未收获 2已收获 3条件不足
		is_sys_fetch = 0,  %% 是否系统收获 0未收获 1系统 2玩家
		wisher_list = []   %% 好友祝福记录
	}).
