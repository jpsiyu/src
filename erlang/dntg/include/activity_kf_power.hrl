%%%--------------------------------------
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2013.3.12
%%% @Description :  斗战封神活动
%%%--------------------------------------

%% 配在管理后台 > 活动时间配置，中的活动类型
-define(ACTIVITY_TIME_TYPE, 13).

-define(KF_POWER_RANK_INSERT, <<"REPLACE INTO activity_power_rank_list SET platform='~s',server_num=~p,id=~p,nickname='~s',
	realm=~p,career=~p,sex=~p,lv=~p,power=~p">>).
-define(KF_POWER_RANK_GET, <<"SELECT * FROM activity_power_rank_list">>).

-define(KF_POWER_IMAGE_INSERT, <<"REPLACE INTO activity_power_rank_image SET platform='~s',server_num=~p,id=~p,content='~s'">>).
-define(KF_POWER_IMAGE_GET, <<"SELECT platform, server_num, id, content FROM activity_power_rank_image">>).

-define(KF_POWER_AWARD_GET, <<"SELECT get_award FROM activity_power_rank_award WHERE id=~p">>).
-define(KF_POWER_AWARD_GET2, <<"SELECT p.id, p.combat_power FROM rank_combat_power p LEFT JOIN 
	player_low pl ON p.id=pl.id WHERE pl.lv>=~p AND p.combat_power>=~p">>).
-define(KF_POWER_AWARD_GET3, <<"SELECT p.id, p.combat_power FROM rank_combat_power p LEFT JOIN 
		player_low pl ON p.id=pl.id WHERE pl.lv>=~p AND p.combat_power>=~p AND p.combat_power<~p 
		ORDER BY p.combat_power DESC LIMIT ~p">>).
-define(KF_POWER_AWARD_INSERT, <<"REPLACE INTO activity_power_rank_award SET id=~p, get_award='~s'">>).




