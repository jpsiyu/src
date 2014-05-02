%%------------------------------------------------------------------------------
%% @Module  : sql_dungeon.hrl
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.6.12
%% @Description: 副本系统sql文件
%%------------------------------------------------------------------------------


%%--------------------------------爬塔霸主表------------------------------------

%% 查询爬塔霸主表.
-define(sql_select_tower_masters, <<"select sid, players, passtime, reward, tower_dun_id from tower_masters where sid =~p limit 1">>).

%% 查询所有爬塔霸主表.
-define(sql_select_all_tower_masters, <<"select sid, players, passtime, reward, tower_dun_id from tower_masters">>).

%% 插入爬塔霸主表.
-define(sql_insert_tower_masters, <<"insert into tower_masters (sid, players, passtime, tower_dun_id) values (~p, '~s', ~p, ~p)">>).

%% 代替爬塔霸主表.
-define(sql_replace_tower_masters, <<"replace into tower_masters (sid, players, passtime, reward, tower_dun_id) values (~p, '~s', ~p, '~s', ~p)">>).

%% 删除爬塔霸主表.
-define(sql_delete_tower_masters, <<"delete from tower_masters where sid = ~p">>).

%% 更新爬塔霸主表.
-define(sql_update_tower_masters, <<"update tower_masters set  reward = '[]'">>).


%%--------------------------------副本日志表------------------------------------

%% 查询副本日志表.
-define(sql_select_dungeon_log, <<"select log from dungeon_log where role_id =~p">>).

%% 代替副本日志表.
-define(sql_replace_dungeon_log, <<"replace into dungeon_log (role_id, log) values (~p, '~s')">>).

%% 更新副本日志表.
-define(sql_update_dungeon_log, <<"update dungeon_log set log='~s' where role_id=~p">>).

%% 查询全部副本日志.
-define(sql_dungeon_log_sel_all, <<"SELECT `role_id`, `dungeon_id`, 
	`total_count`, `record_level`, `pass_time`, `cooling_time`, `gift` FROM `dungeon_log` 
	WHERE role_id=~p">>).

%% 查询指定副本id副本日志.
-define(sql_dungeon_log_sel_type, <<"SELECT `role_id`, `dungeon_id`, 
	`total_count`, `record_level`, `pass_time`, `cooling_time`, `gift` FROM 
	`dungeon_log` WHERE `role_id` =~p AND `dungeon_id` =~p">>).

-define(sql_dungeon_log_sel_type2, <<"SELECT `dungeon_id`, `record_level`, 
	`pass_time` FROM `dungeon_log` WHERE `role_id` =~p AND `dungeon_id` =~p">>).

%% 增加全部副本日志.
-define(sql_dungeon_log_add, <<"INSERT INTO `dungeon_log` (`role_id`, `dungeon_id`, 
	`total_count`, `record_level`, `pass_time`, `cooling_time`, `gift`) VALUES (~p, ~p, ~p, ~p, ~p, ~p, ~p);">>).

%% 更新全部副本日志.
-define(sql_dungeon_log_upd_count, <<"UPDATE `dungeon_log` SET 
	`total_count` = ?, `record_level` = ?, `pass_time` = ?,	`cooling_time` = ? ,	`gift` = ?
	WHERE `role_id` =~p AND `dungeon_id` =~p">>).

%% 替换全部副本日志.
-define(sql_dungeon_log_upd, <<"REPLACE INTO `dungeon_log` (`role_id`, 
	`dungeon_id`, `total_count`, `record_level`, `pass_time`, `cooling_time`, `gift`) 
	VALUES (~p, ~p, ~p, ~p, ~p, ~p, ~p)">>).

%% 清空副本日志.
-define(sql_dungeon_log_clear,<<"truncate table `dungeon_log`">>).

%%------------------------------剧情副本挂机表----------------------------------

%% 查询剧情副本挂机表.
-define(sql_select_player_story_dungeon, <<"SELECT 
    `id`, `dungeon_id`, `begin_time`, `exp`, `wuhun`, `finish`, `auto_num` 
    FROM `player_story_dungeon` WHERE `id` =~p">>).

%% 替换剧情副本挂机表.
-define(sql_replace_player_story_dungeon, <<"REPLACE INTO 
	`player_story_dungeon` (`id`, `dungeon_id`, `begin_time`, `exp`, 
	`wuhun`, `finish`, `auto_num`) VALUES (~p, ~p, ~p, ~p, ~p, ~p, ~p)">>).

%%------------------------------剧情副本积分表----------------------------------

%% 获取第一章霸主.
-define(sql_select_player_story_dungeon1, <<"select player_story_score.id, 
    player_low.nickname, player_low.sex, player_low.career, score1, pass_time1 
	from player_story_score,player_low where player_story_score.id=player_low.id
    order by score1 desc, pass_time1 limit 5">>).

%% 获取第二章霸主.
-define(sql_select_player_story_dungeon2, <<"select player_story_score.id, 
    player_low.nickname, player_low.sex, player_low.career, score2, pass_time2 
	from player_story_score,player_low where player_story_score.id=player_low.id
    order by score2 desc, pass_time2 limit 5">>).

%% 获取第三章霸主.
-define(sql_select_player_story_dungeon3, <<"select player_story_score.id, 
    player_low.nickname, player_low.sex, player_low.career, score3, pass_time3 
	from player_story_score,player_low where player_story_score.id=player_low.id
    order by score3 desc, pass_time3 limit 5">>).

%% 获取第四章霸主.
-define(sql_select_player_story_dungeon4, <<"select player_story_score.id, 
    player_low.nickname, player_low.sex, player_low.career, score4, pass_time4 
	from player_story_score,player_low where player_story_score.id=player_low.id
    order by score4 desc, pass_time4 limit 5">>).

%% 获取第五章霸主.
-define(sql_select_player_story_dungeon5, <<"select player_story_score.id, 
    player_low.nickname, player_low.sex, player_low.career, score5, pass_time5 
	from player_story_score,player_low where player_story_score.id=player_low.id
    order by score5 desc, pass_time5 limit 5">>).

%% 获取第六章霸主.
-define(sql_select_player_story_dungeon6, <<"select player_story_score.id, 
    player_low.nickname, player_low.sex, player_low.career, score6, pass_time6 
    from player_story_score,player_low where player_story_score.id=player_low.id 
    order by score6 desc, pass_time6 limit 5">>).

%% 查询剧情副本总积分.
-define(sql_select_story_score, <<"SELECT `id`, `score1`, `pass_time1`, 
	`score2`, `pass_time2`, `score3`, `pass_time3`,
	`score4`, `pass_time4`, `score5`, `pass_time5`,
	`score6`, `pass_time6`  FROM 
	`player_story_score` WHERE id=~p">>).

%% 替换剧情副本总积分.
-define(sql_replace_story_score, <<"REPLACE INTO `player_story_score` (`id`, 
	`score1`, `pass_time1`, `score2`, `pass_time2`, 
	`score3`, `pass_time3`, `score4`, `pass_time4`, 
	`score5`, `pass_time5`, `score6`, `pass_time6`
	) VALUES (~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p)">>).

%%------------------------------剧情副本霸主表----------------------------------

%% 查询剧情副本霸主表.
-define(sql_select_story_masters, <<"select chapter, player_id, player_name, sex, career,
	score, passtime, record_list from story_masters where chapter =~p limit 1">>).

%% 查询所有剧情副本霸主表.
-define(sql_select_all_story_masters, <<"select chapter, player_id, 
	player_name, sex, career, score, passtime, record_list from story_masters">>).

%% 插入剧情副本霸主表.
-define(sql_insert_story_masters, <<"insert into story_masters (chapter, 
	player_id, player_name, score, passtime, record_list) values (~p, ~p, '~s', 
	~p, ~p, '~s')">>).

%% 代替剧情副本霸主表.
-define(sql_replace_story_masters, <<"replace into story_masters (chapter, 
	player_id, player_name, sex, career, score, passtime, record_list) values (~p, ~p, '~s', 
	~p, ~p, ~p, ~p, '~s')">>).

%% 删除剧情副本霸主表.
-define(sql_delete_story_masters, <<"delete from story_masters where chapter = ~p">>).

%% 查询玩家名字.
-define(sql_select_nickname, <<"select nickname from player_low where 
	id = ~p limit 1">>).

%%------------------------------塔防副本霸主表----------------------------------

%% 查询多人塔防副本
-define(sql_select_rank_multi_king_dungeon, <<"SELECT level, player_list, 
	time FROM rank_multi_king_dungeon order by level desc">>).

%% 插入多人塔防副本.
-define(sql_insert_rank_multi_king_dungeon, <<"REPLACE INTO 
	rank_multi_king_dungeon (level, player_list, time) 
	VALUES (~p,'~s',~p)">>).

%% 删除多人塔防副本.
-define(sql_delete_rank_multi_king_dungeon, <<"delete from 
	rank_multi_king_dungeon where level = ~p">>).


%%-----------------------------装备副本----------------------------------------
%% 查询玩家通关的装备副本日志.
-define(sql_select_equip_dungeon_log, 
        <<"SELECT `role_id`,`dungeon_id`, `sort_id`, `total_count`,`level`,`best_time`,`is_open`,`gift`,`time`, `player_name`, `career`, `sex`, `is_kill_boss` FROM `log_equip_energy_dun` WHERE role_id=~p">>).

%% 新增玩家通关的装备副本日志.
-define(sql_insert_equip_dungeon_log, 
        <<"INSERT INTO  `log_equip_energy_dun` (`role_id`,`dungeon_id`, `sort_id`, `total_count`,`level`,`best_time`,`is_open`,`gift`,`time`, `player_name`, `career`, `sex`, `is_kill_boss`) VALUES (~p,~p,~p,~p,~p,~p,~p,~p,~p, '~s',~p,~p,~p)">>).

%% 判断是否已经存在下一关
-define(sql_select_equip_dungeon_log_by_id, 
        <<"SELECT `role_id`,`dungeon_id` FROM `log_equip_energy_dun` WHERE role_id=~p AND dungeon_id=~p">>).

%% 更新装备副本日志
-define(sql_update_equip_log_by_id,
        <<"UPDATE log_equip_energy_dun SET level=~p, best_time=~p, total_count=~p, gift=~p, time=~p WHERE role_id=~p AND dungeon_id=~p">>).

%% 更新装备副本日志
-define(sql_update_equip_kill_boss,
        <<"UPDATE log_equip_energy_dun SET is_kill_boss=~p, time=~p WHERE role_id=~p AND dungeon_id=~p">>).

%% 更新装备副本日志
-define(sql_update_equip_playerinfo_by_id,
        <<"UPDATE log_equip_energy_dun SET player_name='~s', career=~p, sex=~p WHERE role_id=~p AND dungeon_id=~p">>).

%% 挑战失败添加次数
-define(sql_update_equip_log_fail_id,
        <<"UPDATE log_equip_energy_dun SET total_count=~p, time=~p WHERE role_id=~p AND dungeon_id=~p">>).

%% 每一个装备副本的霸主信息
-define(sql_select_equip_master, 
        <<"SELECT `dun_id`, `role_id`, `name`, `career`, `sex`, `pass_time` FROM `equip_master`">>).

%% 每一个装备副本的霸主信息通过主键获取
-define(sql_select_equip_master_by_dunid, 
        <<"SELECT `dungeon_id`, `role_id`, `best_time`, `player_name`, `career`, `sex` FROM `log_equip_energy_dun` WHERE dungeon_id = ~p AND best_time > 0 ORDER BY best_time LIMIT 1">>).

%% 插入和更新霸主信息
-define(sql_replace_equip_master,
        <<"REPLACE INTO equip_master (dun_id, role_id, name, career, sex, pass_time, time) VALUES (~p, ~p, '~s', ~p, ~p, ~p, ~p)">>).


%% 查询玩家名字,职业,性别.
-define(sql_select_equip_player_info, 
        <<"SELECT nickname, career, sex FROM player_low WHERE id = ~p limit 1">>).


