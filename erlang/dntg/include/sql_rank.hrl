%%%--------------------------------------
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.5.31
%%% @Description : 排行榜
%%%--------------------------------------

%% “个人排行-战斗力榜”
-define(SQL_RK_PERSON_FIGHT_COUNT, <<"SELECT count(id) FROM rank_combat_power WHERE id>0">>).
-define(SQL_RK_PERSON_FIGHT_DELETE, <<"DELETE FROM rank_combat_power ORDER BY `time` ASC LIMIT ~p">>).
-define(SQL_RK_PERSON_FIGHT, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, cp.combat_power, pv.vip_type
	FROM rank_combat_power AS cp LEFT JOIN player_low AS pl ON cp.id=pl.id LEFT JOIN guild_member AS g ON g.id=cp.id 
	LEFT JOIN player_vip AS pv ON cp.id=pv.id 
	WHERE combat_power>0 ORDER BY cp.combat_power DESC, cp.time ASC LIMIT ~p">>).
-define(SQL_RK_PERSON_FIGHT_UPDATE, <<"REPLACE INTO rank_combat_power (id,combat_power,time) VALUES(~p,~p,~p)">>).

%% 查询“个人排行-等级榜”
-define(SQL_RK_PERSON_LV, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, pl.lv, pv.vip_type, ph.exp 
	FROM player_low AS pl LEFT JOIN guild_member AS g ON g.id = pl.id LEFT JOIN player_vip AS pv ON pl.id = pv.id LEFT JOIN player_high AS ph ON pl.id=ph.id 
	ORDER BY pl.lv DESC, ph.exp DESC LIMIT ~p">>).

%% 查询“个人排行-财富”
-define(SQL_RK_PERSON_WEALTH, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, ph.coin, pv.vip_type 
	FROM player_low AS pl LEFT JOIN guild_member AS g ON g.id = pl.id LEFT JOIN player_vip AS pv ON pl.id = pv.id LEFT JOIN player_high AS ph ON pl.id=ph.id 
	WHERE ph.coin>0 ORDER BY ph.coin DESC LIMIT ~p">>).

%% 查询“个人排行-成就榜”
-define(SQL_RK_PERSON_ACHIEVE, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, pt.cjpt, pv.vip_type
	FROM player_low AS pl LEFT JOIN guild_member AS g ON g.id = pl.id LEFT JOIN player_vip AS pv ON pl.id = pv.id LEFT JOIN player_pt AS pt ON pl.id=pt.id 
	WHERE pt.cjpt>0 ORDER BY pt.cjpt DESC LIMIT ~p">>).

%% 查询“个人排行-仙府声望榜”
-define(SQL_RK_PERSON_REPUTATION, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, pt.gjpt, pv.vip_type  
	FROM player_low AS pl LEFT JOIN guild_member AS g ON g.id = pl.id LEFT JOIN player_vip AS pv ON pl.id = pv.id LEFT JOIN player_pt AS pt ON pl.id=pt.id 
	WHERE pt.gjpt>0 ORDER BY pt.gjpt DESC LIMIT ~p">>).

%% 查询“个人排行-元神榜”
-define(SQL_RK_PERSON_VEIN, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, result.totallevel, pv.vip_type 
	FROM ( SELECT uid, (ghpmp+gdef+gdoom+gjook+gtenacity+gsudatt+gatt+gfiredef+gicedef+gdrugdef) AS totallevel FROM meridian) as result 
	LEFT JOIN player_low AS pl ON result.uid=pl.id LEFT JOIN guild_member AS g ON result.uid=g.id 
    LEFT JOIN player_vip AS pv ON result.uid=pv.id 
	WHERE result.totallevel > 0 ORDER BY result.totallevel DESC LIMIT ~p">>).

%% 查询“个人排行-宠物幻化榜”
-define(SQL_RK_PERSON_HUANHUA, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, pet.value, pv.vip_type
	FROM player_low AS pl LEFT JOIN guild_member AS g ON g.id = pl.id LEFT JOIN player_vip AS pv ON pl.id = pv.id LEFT JOIN pet_figure_change_value AS pet ON pl.id=pet.player_id 
	WHERE pet.value>0 ORDER BY pet.value DESC LIMIT ~p">>).

%% 查询“个人排行-着装度”
-define(SQL_RK_PERSON_CLOTHES, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, pl.wear_degree, pv.vip_type
	FROM player_low AS pl LEFT JOIN guild_member AS g ON g.id = pl.id LEFT JOIN player_vip AS pv ON pl.id = pv.id 
	WHERE pl.wear_degree>0 ORDER BY pl.wear_degree DESC LIMIT ~p">>).

%% 查询“宠物排行-战斗力榜”
-define(SQL_RK_PET_FIGHT, <<"SELECT pet.player_id, pet.name, pet.id, pl.nickname, pl.realm, pet.combat_power 
	FROM pet INNER JOIN player_low AS pl ON pet.player_id=pl.id 
	WHERE pet.combat_power > 0 ORDER BY pet.combat_power DESC, pet.level DESC LIMIT ~p">>).

%% 查询“宠物排行-成长榜”
-define(SQL_RK_PET_GROW, <<"SELECT pet.player_id, pet.name, pet.id, pl.nickname, pl.realm, pet.growth 
	FROM pet INNER JOIN player_low AS pl ON pet.player_id=pl.id 
	WHERE pet.growth>0 ORDER BY pet.growth DESC, pet.level DESC LIMIT ~p">>).

%% 查询“宠物排行-等级榜”
-define(SQL_RK_PET_LEVEL, <<"SELECT pet.player_id, pet.name, pet.id, pl.nickname, pl.realm, pet.level
	FROM pet INNER JOIN player_low AS pl ON pet.player_id=pl.id 
	ORDER BY pet.level DESC, pet.upgrade_exp DESC LIMIT ~p">>).

%% 查询“坐骑排行-战斗力榜”
-define(SQL_RK_MOUNT_FIGHT, <<"SELECT pl.id,pl.nickname,pl.career,pl.realm,m.id,m.type_id,m.combat_power 
	FROM mount AS m INNER JOIN player_low AS pl ON m.role_id=pl.id 
	WHERE m.status>0 AND m.combat_power > 0 ORDER BY m.combat_power DESC LIMIT ~p">>).

%% 查询“装备排行-*”
-define(SQL_RK_EQUIP, <<"SELECT role_id, gtype_id, id, role_name, score, color, career, equip_subtype
	FROM rank_equip WHERE score>0 AND equip_type = ~p ORDER BY score DESC, timestamp ASC LIMIT ~p">>).
-define(SQL_RK_COUNT_EQUIP, <<"SELECT COUNT(id) FROM rank_equip WHERE equip_type = ~p">>).
-define(SQL_RK_DELETE_EQUIP_ORVERDUE, <<"DELETE FROM rank_equip WHERE equip_type = ~p ORDER BY score ASC, timestamp DESC LIMIT ~p">>).
-define(SQL_RK_EQUIP_INSERT, <<"REPLACE INTO rank_equip (id, timestamp, gtype_id, equip_type, equip_subtype, role_id, role_name, color, career, score) values (~p,~p,~p,~p,~p,~p,'~s',~p,~p,~p)">>).
-define(SQL_RK_EQUIP_UPDATE, <<"UPDATE rank_equip SET timestamp=~p, score=~p WHERE id=~p">>).
-define(SQL_RK_EQUIP_UPDATE2, <<"UPDATE rank_equip SET id=~p,gtype_id=~p,equip_type=~p,equip_subtype=~p,color=~p,
	career=~p, timestamp=~p, score=~p WHERE role_id=~p AND equip_subtype=~p">>).
-define(SQL_RK_EQUIP_DELETE, <<"DELETE FROM rank_equip WHERE id=~p">>).

%% 查询“帮派排行-帮会榜”
-define(SQL_RK_GUILD_LV, <<"SELECT id, name, realm, member_num, level FROM guild ORDER BY level DESC, member_num DESC LIMIT ~p">>).

%% 查询“副本排行-铜钱副本”
-define(sql_select_rank_coin_dungeon, <<"SELECT total_coin FROM rank_coin_dungeon WHERE role_id=~p">>).
-define(sql_insert_rank_coin_dungeon, <<"REPLACE INTO rank_coin_dungeon (role_id, role_name, max_combo, coin, total_coin) VALUES (~p,'~s',~p,~p,~p)">>).
-define(SQL_RK_COPY_COIN, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, rcd.max_combo, rcd.coin, rcd.total_coin   
	FROM rank_coin_dungeon AS rcd INNER JOIN player_low AS pl ON rcd.role_id=pl.id  
	ORDER BY rcd.total_coin DESC, rcd.coin DESC LIMIT ~p">>).
-define(SQL_RK_COPY_TOWER, <<"SELECT t.finish_level, t.time, pl.id, pl.nickname, pl.career, pl.realm, pl.sex 
	FROM rank_king_dungeon AS t INNER JOIN player_low AS pl ON t.role_id=pl.id 
	ORDER BY t.finish_level DESC, t.time LIMIT ~p">>).

%% 查询“副本排行-塔防副本”
-define(sql_select_rank_king_dungeon, <<"SELECT finish_level, time FROM 
	rank_king_dungeon WHERE role_id=~p">>).
-define(sql_insert_rank_king_dungeon, <<"REPLACE INTO rank_king_dungeon 
	(role_id, role_name, finish_level, time) VALUES (~p,'~s',~p,~p)">>).

%% 查询“副本排行-飞行副本”
-define(sql_select_rank_fly_dungeon, <<"SELECT level, star, time FROM 
	rank_fly_dungeon WHERE role_id=~p">>).
-define(sql_insert_rank_fly_dungeon, <<"REPLACE INTO rank_fly_dungeon 
	(role_id, role_name, level, star, time) VALUES (~p,'~s',~p,~p,~p)">>).

%% 查询“魅力排行-护花榜”
-define(SQL_RK_CHARM_HUHUA, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, pt.mlpt, pl.image
	FROM player_pt AS pt LEFT JOIN player_low AS pl ON pt.id=pl.id LEFT JOIN guild_member AS g ON g.id = pt.id  
	WHERE pt.mlpt>0 AND pl.sex=1 ORDER BY pt.mlpt DESC LIMIT ~p">>).

%% 查询“魅力排行-鲜花榜”
-define(SQL_RK_CHARM_FLOWER, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, pt.mlpt, pl.image
	FROM player_pt AS pt LEFT JOIN player_low AS pl ON pt.id=pl.id LEFT JOIN guild_member AS g ON g.id = pt.id  
	WHERE pt.mlpt>0 AND pl.sex=2 ORDER BY pt.mlpt DESC LIMIT ~p">>).

%% 查询“魅力排行-沙滩魅力榜”
-define(SQL_RK_CHARM_HOTSPRING, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, hc.charm, pl.image
	FROM rank_hotspring_charm AS hc LEFT JOIN player_low AS pl ON hc.id=pl.id LEFT JOIN guild_member AS g ON g.id = hc.id  
	WHERE hc.charm>0 ORDER BY hc.charm DESC LIMIT ~p">>).

%% 处理每日护花/鲜花
-define(SQL_RK_DAILY_FLOWER_FETCH, <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, f.value, pl.image
	FROM rank_daily_flower AS f LEFT JOIN player_low AS pl ON f.id=pl.id LEFT JOIN guild_member as g ON f.id=g.id 
	WHERE pl.sex=~p ORDER BY f.value DESC LIMIT ~p">>).
-define(SQL_RK_DAILY_FLOWER_FETCH_ROW, <<"SELECT id, value FROM rank_daily_flower WHERE id=~p">>).
-define(SQL_RK_DAILY_FLOWER_INSERT, <<"INSERT INTO rank_daily_flower(id,name,sex,career,realm,value,time) VALUES(~p,'~s',~p,~p,~p,~p,~p)">>).
-define(SQL_RK_DAILY_FLOWER_UPDATE, <<"UPDATE rank_daily_flower SET value=~p, time=~p WHERE id=~p">>).
-define(SQL_RK_DELETE_ALL_DAILY_FLOWER, <<"DELETE FROM rank_daily_flower WHERE sex=~p">>).
-define(SQL_RK_DAILY_FLOWER_DELETE_ALL, <<"DELETE FROM rank_daily_flower_copy WHERE sex=~p">>).
-define(SQL_RK_DAILY_FLOWER_COPY, <<"REPLACE INTO rank_daily_flower_copy SELECT * FROM rank_daily_flower WHERE sex=~p">>).

%% 竞技每日上榜
-define(SQL_RK_ARENA_DAY, <<"SELECT pl.id, pl.nickname, pl.career, pl.realm, pl.sex, ra.killnum, ra.score 
	FROM player_low AS pl INNER JOIN rank_arena AS ra ON pl.id=ra.id 
	WHERE ra.score>0 ORDER BY ra.score DESC, ra.killnum DESC LIMIT ~p">>).
-define(SQL_RK_ARENA_DAY_DELETE, <<"DELETE FROM rank_arena WHERE id>0">>).
-define(SQL_RK_ARENA_DAY_INSERT, <<"INSERT INTO rank_arena(id, killnum, score) SELECT id, arena_kill_day, arena_score_day 
	FROM player_arena WHERE arena_last_time>~p AND arena_room_lv=1">>).

%% 竞技每周上榜
-define(SQL_RK_ARENA_WEEK, <<"SELECT pl.id, pl.nickname, pl.career, pl.realm, pl.sex, pa.arena_kill_week, pa.arena_score_week  
	FROM player_low AS pl INNER JOIN player_arena AS pa ON pl.id=pa.id 
	WHERE pa.arena_last_time >=~p AND pa.arena_last_time <~p AND pa.arena_score_week>0
	ORDER BY pa.arena_score_week DESC, pa.arena_kill_week DESC LIMIT ~p">>).
%% 竞技每周击杀榜
-define(SQL_RK_ARENA_WEEK_KILL, <<"SELECT pl.id, pl.nickname, pl.career, pl.realm, g.guild_name, pa.arena_max_continuous_kill_week 
	FROM player_low AS pl INNER JOIN player_arena AS pa ON pl.id=pa.id INNER JOIN guild_member AS g ON pl.id=g.id
	WHERE pa.arena_last_time >=~p AND pa.arena_last_time <~p AND pa.arena_max_continuous_kill_week>0
	ORDER BY pa.arena_max_continuous_kill_week DESC LIMIT ~p">>).

-define(SQL_RK_FETCH_POPULARITY, <<" SELECT popularity FROM rank_role_popularity WHERE role_id=~p LIMIT 1">>).
-define(SQL_RK_FETCH_ALL_POPULARITY, <<" SELECT role_id, popularity FROM rank_role_popularity WHERE role_id > 0">>).
-define(sql_insert_rank_role_popularity, <<"REPLACE INTO rank_role_popularity (role_id, popularity) VALUES (~p, '[]')">>).
-define(sql_update_rank_role_popularity, <<"replace into rank_role_popularity (role_id, popularity) values (~p, '~s')">>).
-define(sql_select_role_info, <<"select id,nickname,sex,career,realm,lv from player_low where id=~p limit 1">>).

%% 飞行器
-define(SQL_RK_FILYER_GET, <<"SELECT pl.id, pl.nickname, pl.career, pl.realm, pl.sex, f.nth, f.name, f.combat_power, f.quality
	FROM flyer AS f INNER JOIN player_low AS pl ON f.player_id=pl.id WHERE pl.lv>59 ORDER BY f.combat_power DESC LIMIT ~p">>).

%% 快照
-define(SQL_RK_SNAPSHOT_INSERT, <<"INSERT INTO rank_snapshot SET type=~p,content='~s',addtime=~p">>).
-define(SQL_RK_CHANGE_SEX, <<"UPDATE rank_daily_flower SET sex=~p WHERE id=~p">>).

%% 定时器刷新表
-define(SQL_RK_TIMER_GET, <<"SELECT id, lasttime FROM rank_timer_refresh">>).
-define(SQL_RK_TIMER_INSERT, <<"REPLACE INTO rank_timer_refresh(id, lasttime) VALUES (~p, ~p)">>).

-define(SQL_RK_GET_WEAR_DEGREE, <<"SELECT wear_degree FROM player_low WHERE id=~p">>).
