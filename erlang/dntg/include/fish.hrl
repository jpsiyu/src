%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.9.17
%%% @Description: 全民垂钓
%%%--------------------------------------

-define(SQL_FISH_SELECT, <<"SELECT * FROM fish WHERE id=~p">>).
-define(SQL_FISH_INSERT, <<"INSERT INTO fish(id) VALUES(~p)">>).
-define(SQL_FISH_UPDATE, <<"UPDATE fish SET score=~p,exp=~p,llpt=~p,steal_num=~p,fish_stat='~s',step_award='~s',score_award=~p,daytime=~p WHERE id=~p">>).

%% 10041	%七彩锦鲤
%% 10042	%黄金鱼
%% 10043	%紫玉鱼
%% 10044	%蓝纹鱼
%% 10045	%绿鳞鱼
%% 10046	%小银鱼

-define(FISH_ID_1, 10041).	%% 积分最大的鱼
-define(FISH_ID_2, 10042).
-define(FISH_ID_3, 10043).
-define(FISH_ID_4, 10044).
-define(FISH_ID_5, 10045).
-define(FISH_ID_6, 10046).
