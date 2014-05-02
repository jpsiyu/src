%%%--------------------------------------
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.8.14
%%% @Description : 排行榜活动相关
%%%--------------------------------------

%% 查询“个人排行-等级榜”
-define(SQL_RKACT_PERSON_LV, <<"SELECT pl.id FROM player_low AS pl 
	INNER JOIN player_high AS ph ON pl.id=ph.id ORDER BY pl.lv DESC, ph.exp DESC LIMIT 10">>).
%% 查询“个人排行-战力榜”
-define(SQL_RKACT_PERSON_POWER, <<"SELECT id FROM rank_combat_power ORDER BY combat_power DESC LIMIT 10">>).
%% 查询“个人排行-元神榜”
-define(SQL_RKACT_PERSON_MERIDIAN, <<"SELECT uid FROM(
	SELECT uid, (ghpmp+gdef+gdoom+gjook+gtenacity+gsudatt+gatt+gfiredef+gicedef+gdrugdef) AS totallevel FROM meridian
) AS result ORDER BY result.totallevel DESC LIMIT 10">>).
%% 查询“个人排行-成就榜”
-define(SQL_RKACT_PERSON_ACHIEVE, <<"SELECT id FROM player_pt ORDER BY cjpt DESC LIMIT 3">>).
%% 查询“宠物排行-等级榜”
-define(SQL_RKACT_PET_LEVEL, <<"SELECT player_id FROM pet ORDER BY level DESC, upgrade_exp DESC LIMIT 10">>).
%% 查询“宠物排行-战斗力榜”
-define(SQL_RKACT_PET_FIGHT, <<"SELECT player_id FROM pet ORDER BY combat_power DESC LIMIT 10">>).
%% 竞技场胜利的玩家统计
-define(SQL_RKACT_ACTIVITY_INSERT, <<"INSERT INTO activity_fight(`type`, `content`) VALUES(~p, '~s')">>).
-define(SQL_RKACT_ACTIVITY_COUNT, <<"SELECT COUNT(id) FROM activity_fight WHERE `type`=~p">>).
-define(SQL_RKACT_ACTIVITY_SELECT, <<"SELECT id, content FROM activity_fight WHERE `type`=~p LIMIT 3">>).
-define(SQL_RKACT_HANDLE_INSERT, <<"REPLACE INTO activity_seven_stat(id) VALUES(1)">>).
-define(SQL_RKACT_HANDLE_UPDATE, <<"UPDATE activity_seven_stat SET ~s=1">>).
-define(SQL_RKACT_HANDLE_SELECT, <<"SELECT * FROM activity_seven_stat WHERE id=1">>).
