%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.9
%%% @Description: 成就
%%%--------------------------------------

-define(ACHIEVE_TYPE_TASK, 1).			%% 任务成就
-define(ACHIEVE_TYPE_EQUIP, 2).			%% 神装成就
-define(ACHIEVE_TYPE_ROLE, 4).			%% 角色成就
-define(ACHIEVE_TYPE_TRIAL, 5).			%% 试炼成就
-define(ACHIEVE_TYPE_SOCIAL, 6).		%% 社会成就
-define(ACHIEVE_TYPE_HIDDEN, 7).		%% 隐藏成就

-define(GAME_ACHIEVE_ALLID(RoleId), lists:concat(["mod_achieve_allid_", RoleId])).
-define(GAME_ACHIEVE(RoleId, AchieveId), lists:concat(["mod_achieve_", RoleId, "_", AchieveId])).
-define(GAME_ACHIEVE_STAT(RoleId), lists:concat(["mod_achieve_stat_", RoleId])).
-define(GAME_ACHIEVE_SCORE(RoleId), lists:concat(["mod_achieve_score_", RoleId])).

-define(sql_achieve_fetch_all, <<"SELECT role_id, achieve_id, count, time, get_award FROM role_achieve WHERE role_id=~p">>).
-define(sql_achieve_stat_fetch_all, <<"SELECT role_id, achieve_type, cur_level, max_level, score FROM role_achieve_stat WHERE role_id=~p">>).
-define(sql_achieve_insert, <<"REPLACE INTO role_achieve SET role_id=~p, achieve_id=~p, `count`=~p, `time`=~p, get_award=~p">>).
-define(sql_achieve_update, <<"UPDATE role_achieve SET `count`=~p, `time`=~p, get_award=~p WHERE role_id=~p AND achieve_id=~p">>).
-define(sql_achieve_stat_insert, <<"REPLACE INTO role_achieve_stat SET role_id=~p, achieve_type=~p, cur_level=~p, max_level=~p, score=~p">>).
-define(sql_achieve_fetch_score, <<"SELECT cjpt FROM `player_pt` WHERE id=~p LIMIT 1">>).
-define(sql_achieve_get_row, <<"SELECT `count`, time, get_award FROM role_achieve WHERE role_id=~p AND achieve_id=~p">>).

%% 成就配置记录
-record(base_achieve, {
        id = 0,             		%% 成就ID
        type = 0,           	%% 类型
        type_id = 0,        	%% 类型ID，如物品ID，任务ID...
        type_list = 0,      	%% 类型ID列表，如物品ID列表，任务ID列表...
        lim_num = 0,      %% 限制数量
        is_count = 0,       %% 是否要统计
        name_id = 0,      	%% 称号
        score = 0,           	%% 成就点数
		sort_type = 0,		%% 排序类型
		sort_id	= 0			%% 排序等级
    }).

%% 玩家成就记录
-record(role_achieve, {
	id = {0,0},					%% {角色id, 成就id}
	count = 0,				%% 统计数量
	time = 0,					%% 完成时间
	getaward = 0			%% 是否获得奖励
}).

%% 玩家成就统计记录
-record(role_achieve_stat, {
	id = {0,0},					%% {角色id, 大类ID}
	curlevel = 1,			%% 已领取奖励等级
	maxlevel = 0,			%% 已达到等级
	score = 0					%% 大类总成就点数
}).
