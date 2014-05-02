%%------------------------------------------------------------------------------
%% @Module  : sql_anti_brush.hrl
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.10.22
%% @Description: 防刷积分sql文件
%%------------------------------------------------------------------------------


%%------------------------------玩家防刷积分表----------------------------------

%% 查询玩家防刷积分.
-define(sql_select_anti_brush, <<"SELECT `id`, `score1`, `time1`, `score2`,
	`time2`, `score3`, `time3`, `score4`, `time4` FROM 
	`player_anti_brush` WHERE id=~p">>).

%% 替换玩家防刷积分.
-define(sql_replace_anti_brush, <<"REPLACE INTO `player_anti_brush` (`id`, 
	`score1`, `time1`, `score2`, `time2`, `score3`, `time3`, `score4`, 
	`time4`, `guild_score`) VALUES (~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p)">>).

%%-----------------------------帮派当天防刷总积分表---------------------------------

%% 查询帮派当天防刷总积分.
-define(sql_select_guild_anti_brush, <<"SELECT `total_score`, `count` FROM 
	`guild_anti_brush` WHERE guild_id=~p">>).

%% 替换帮派当天防刷总积分.
-define(sql_replace_guild_anti_brush, <<"REPLACE INTO `guild_anti_brush` 
	(`guild_id`, `total_score`, `count`) VALUES (~p, ~p, ~p)">>).

%% 每天清除帮派当天防刷总积分.
-define(sql_clear_guild_anti_brush,<<"truncate table `guild_anti_brush`">>).