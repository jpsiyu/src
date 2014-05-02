%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.4
%%% @Description: 每日活跃度
%%%--------------------------------------

-record(active, {
	id = 0,			%% 玩家id
	today = 0,		%% 当天0点时间戳
	active = 0,		%% 当前活跃度
    allactive = 0,  %% 总的活跃度
	opt = [],		%% [第一项内容次数, ...第十四项内容次数]
	award = []		%% 领取奖励统计，[1,2,...8]
}).

-define(SQL_ACTIVE_GET_ROW, <<"SELECT * FROM role_active WHERE id=~p">>).
-define(SQL_ACTIVE_GET_ROW2, <<"SELECT ~s FROM role_active WHERE id=~p">>).
-define(SQL_ACTIVE_INSERT, <<"INSERT INTO role_active(id, `today`) VALUES(~p, ~p)">>).
-define(SQL_ACTIVE_RESET, <<"UPDATE role_active SET active1=0,active2=0,active3=0,active4=0,active5=0,
	active6=0,active7=0,active8=0,active9=0,active10=0,active11=0,active12=0,active13=0,active14=0,
    active15=0,active16=0,active17=0,active18=0,active19=0,
	score=0,stat='[]',today=~p WHERE id=~p">>).
-define(SQL_ACTIVE_UPDATE, <<"UPDATE role_active SET active1=~p,active2=~p,active3=~p,active4=~p,active5=~p,
	active6=~p,active7=~p,active8=~p,active9=~p,active10=~p,active11=~p,active12=~p,active13=~p,active14=~p,
    active15=~p,active16=~p,active17=~p,active18=~p,active19=~p,
	score=~p,stat='~s',today=~p WHERE id=~p">>).

-define(SQL_ACTIVE_UPDATE_ACTIVE, <<"UPDATE role_active SET `~s`=`~s`+~p WHERE id=~p">>).
-define(SQL_ACTIVE_UPDATE_ACTIVE2, <<"UPDATE role_active SET `~s`=`~s`+~p, score=~p WHERE id=~p">>).
-define(SQL_ACTIVE_UPDATE_ACTIVE3, <<"UPDATE role_active SET `stat`='~s' WHERE id=~p">>).
-define(SQL_ACTIVE_UPDATE_ACTIVE4, <<"UPDATE role_active SET `~s`=~p WHERE id=~p">>).
-define(SQL_ACTIVE_UPDATE_ACTIVE5, <<"UPDATE role_active SET `score`=~p WHERE id=~p">>).

-define(SQL_GET_ROLE_ACTIVE, <<"SELECT * FROM `role_allactive` WHERE role_id=~p">>).
-define(SQL_REPLACE_ROLE_ACTIVE,<<"REPLACE INTO role_allactive(role_id, active_count) values(~p,~p)">>).
-define(SET_ALL_ACTIVE_ID_0,[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]).
