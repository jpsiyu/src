%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.6.2
%%% @Description: 名人堂
%%%--------------------------------------

-define(SQL_FAME_SELECT, <<"SELECT fame.player_id,fame.fame_id,pl.nickname,pl.realm,pl.career,pl.sex,
	fame.add_time,pl.image FROM rank_fame AS fame LEFT JOIN player_low AS pl ON fame.player_id=pl.id 
	WHERE fame.player_id>0">>).
%% 取出所有已经被达成的荣誉，可能一个荣誉有多个达成记录，所以加了GROUP BY
-define(SQL_FAME_FETCH_ALL_ID, <<"SELECT fame_id FROM rank_fame WHERE player_id>0 GROUP BY fame_id">>).
-define(SQL_FAME_INSERT, <<"REPLACE INTO rank_fame (fame_id, player_id, add_time) VALUES (~p, ~p, ~p)">>).
-define(SQL_FAME_DELETE, <<"DELETE FROM rank_fame WHERE player_id=~p AND fame_id=~p">>).
-define(SQL_FAME_DELETE2, <<"DELETE FROM rank_fame WHERE fame_id=~p">>).
-define(SQL_FAME_DELETE_ALL, <<"DELETE FROM rank_fame">>).
-define(SQL_FAME_MERGE_COST_COIN, <<"SELECT player_id FROM (SELECT SUM(cost_coin + cost_bcoin) AS total, player_id FROM log_consume_coin WHERE time>~p AND time<~p AND consume_type NOT IN(10,47,48,61,65,68,70,71) GROUP BY player_id ORDER BY total DESC) AS result LIMIT 1">>).
-define(SQL_FAME_VERSION, <<"SELECT fame_version FROM game_var WHERE id=1">>).
-define(SQL_FAME_VOTE_SELECT, <<"SELECT player_id, fame_id, vote FROM fame_vote">>).
-define(SQL_FAME_VOTE_SELECT2, <<"SELECT fame_id, player_id, vote FROM fame_vote">>).
-define(SQL_FAME_VOTE_SELECT3, <<"SELECT f.fame_id,f.player_id,f.vote,pl.nickname,pl.realm,pl.career,pl.sex 
	FROM fame_vote AS f LEFT JOIN player_low AS pl on f.player_id=pl.id">>).
-define(SQL_FAME_VOTE_UPDATE, <<"UPDATE fame_vote SET vote=vote+~p WHERE player_id=~p">>).
-define(SQL_FAME_GET_PLAYER, <<"SELECT id, nickname FROM player_low WHERE id IN(~s)">>).

%% 荣誉类型
-define(FAME_TYPE_COPY, 1).
-define(FAME_TYPE_GJPT, 2).
-define(FAME_TYPE_BEKILL, 3).
-define(FAME_TYPE_WEAPON_LEVEL, 4).
-define(FAME_TYPE_WEAR_SUIT, 5).
-define(FAME_TYPE_PET_GROW, 6).
-define(FAME_TYPE_VEIN, 7).
-define(FAME_TYPE_PLAYER_LEVEL, 8).
-define(FAME_TYPE_PLAYER_POWER, 9).
-define(FAME_TYPE_GERM_INLAY, 10).
-define(FAME_TYPE_GUILD_BUILD, 11).
-define(FAME_TYPE_FRIEND_NUM, 12).
-define(FAME_TYPE_ACHIEVE_SCORE, 13).

-define(ETS_FAME, ets_fame).

-record(base_fame, {
	id = 0,				%% 荣誉id
	type = 0,			%% 荣誉类型id
	merge = 0,			%% 合服标识，0为普通荣誉，1为合服荣誉
	name = [],			%% 荣誉名称
	desc = [],			%% 荣誉描述
	target_id = [],		%% 指定id
	num = 0,			%% 要求的次数或者个数
	award = [],			%% 奖励
	design_id = 0		%% 称号id
}).

%% 存在ets中的数据，为了方便检查某个荣誉是否已被达成
-record(ets_fame, {
	id = 0				%% 荣誉id
}).

