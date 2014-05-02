%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.8.28
%%% @Description: 黄金沙滩
%%%--------------------------------------

-define(SQL_HOTSPRING_GET_ALL, <<"SELECT * FROM rank_hotspring">>).
-define(SQL_HOTSPRING_UPDATE, <<"UPDATE rank_hotspring SET `score`=~p WHERE id=~p">>).
-define(SQL_HOTSPRING_DELETE, <<"DELETE FROM rank_hotspring WHERE id>0">>).
-define(SQL_HOTSPRING_INSERT, <<"REPLACE INTO rank_hotspring(id,nickname,sex,realm,career,score) VALUES(~p,'~s',~p,~p,~p,~p)">>).
-define(SQL_HOTSPRING_RK_SELECT, <<"SELECT id FROM rank_hotspring_charm WHERE id=~p">>).
-define(SQL_HOTSPRING_RK_INSERT, <<"INSERT INTO rank_hotspring_charm(id) VALUES(~p)">>).
-define(SQL_HOTSPRING_RK_UPDATE, <<"UPDATE rank_hotspring_charm SET charm=charm+~p WHERE id=~p">>).
-define(SQL_HOTSPRING_RK_UPDATE2, <<"UPDATE rank_hotspring_charm SET charm=0 WHERE charm<0">>).

-record(ets_hotspring, {
	id = 0,				%% 玩家id
	nickname = [],		%% 玩家昵称
	sex = 1,				%% 玩家性别
	realm = 1,			%% 玩家阵营
	career = 1,			%% 玩家职业
	score = 0,			%% 上午魅力值
	score2 = 0			%% 下午魅力值
}).
-record(ets_hotspring_interact, {
	id = 0,			%% 玩家id
	list1 = [],			%% 恶搞玩家列表
	list2	= []			%% 示好玩家列表
}).