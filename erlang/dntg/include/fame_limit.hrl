%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.9.7
%%% @Description: 限时名人堂（活动）
%%%--------------------------------------

-define(FAME_LIMIT_RANK_COIN, 8001).
-define(FAME_LIMIT_RANK_TAOBAO, 8002).
-define(FAME_LIMIT_RANK_EXP, 8003).
-define(FAME_LIMIT_RANK_PT, 8004).
-define(SQL_FAME_LIMIT_UPDATE, <<"UPDATE fame_limit SET value1=~p, value3=~p, value4=~p, level=~p, power=~p WHERE role_id=~p">>).
-define(SQL_FAME_LIMIT_UPDATE2, <<"UPDATE fame_limit SET `~s`=~p, level=~p, power =~p WHERE role_id=~p">>).
-define(SQL_FAME_LIMIT_SELECT, <<"SELECT `value1`,`value2`,`value3`,`value4`,`level`,`power` FROM fame_limit WHERE `role_id`=~p">>).
-define(SQL_FAME_LIMIT_INSERT, <<"INSERT INTO fame_limit(role_id) VALUES(~p)">>).
-define(SQL_FAME_LIMIT_DELETE, <<"DELETE FROM fame_limit">>).
-define(SQL_FAME_MASTER_REPLACE, <<"REPLACE INTO fame_limit_statue SET `type`=~p, data='~s'">>).
-define(SQL_FAME_MASTER_SELECT, <<"SELECT * FROM fame_limit_statue">>).
-define(SQL_FAME_MASTER_DELETE, <<"DELETE FROM fame_limit_statue">>).

-define(FAME_LIMIT_COIN_DOWN, 50000).   %% 铜币下限，超过下限才会刷新排行榜，否则只累积
-define(FAME_LIMIT_EXP_DOWN, 500000).   %% 经验下限，超过下限才会刷新排行榜，否则只累积
-define(SCENE_CHANG_AN, 102).
-define(FAME_LIMIT_EXP_SPACE, 300).	    %% 经验处理时间
-define(FAME_LIMIT_PT_SPACE, 300).		%% 历练处理时间

%% 查询铜钱榜
-define(SQL_FAME_RANK_COIN, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, fl.level, fl.power, fl.value1 
	FROM fame_limit AS fl LEFT JOIN player_low AS pl ON fl.role_id=pl.id 
	WHERE fl.value1>0 ORDER BY fl.value1 DESC LIMIT ~p">>).

%% 查询淘宝榜
-define(SQL_FAME_RANK_TAOBAO, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, fl.level, fl.power, fl.value2 
	FROM fame_limit AS fl LEFT JOIN player_low AS pl ON fl.role_id=pl.id 
	WHERE fl.value2>0 ORDER BY fl.value2 DESC LIMIT ~p">>).

%% 查询经验榜
-define(SQL_FAME_RANK_EXP, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, fl.level, fl.power, fl.value3 
	FROM fame_limit AS fl LEFT JOIN player_low AS pl ON fl.role_id=pl.id 
	WHERE fl.value3>0 ORDER BY fl.value3 DESC LIMIT ~p">>).

%% 查询历练榜
-define(SQL_FAME_RANK_PT, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, fl.level, fl.power, fl.value4 
	FROM fame_limit AS fl LEFT JOIN player_low AS pl ON fl.role_id=pl.id 
	WHERE fl.value4>0 ORDER BY fl.value4 DESC LIMIT ~p">>).

%% 限时名人堂（活动）排行榜
-define(ETS_FAME_LIMIT_RANK, ets_fame_limit_rank).
%% 限时名人堂（活动）
-record(ets_fame_limit_rank, {
	type_id,					%% 排行类型ID
	rank_list					%% 排行信息列表
}).

%% 雕像ets表名
-define(ETS_FAME_LIMIT_STATUE, ets_fame_limit_statue).
%% 雕像数据
-record(ets_fame_limit_statue, {
	type,			%% 类型（8001，8002，8003，8004）
	data			%% 雕像数据的数据
}).
