%%%--------------------------------------
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.11.16
%%% @Description :  跨服排行榜
%%%--------------------------------------

%% 跨服1v1排行榜周榜
-define(RK_CLS_WEEK, 101).
%% 跨服3v3排行榜周榜
-define(RK_CLS_MVP, 102).

%% 跨服排行榜
-define(RK_KF_PLAYER_POWER, 1001).
-define(RK_KF_PLAYER_LEVEL, 1002).
-define(RK_KF_PLAYER_WEALTH, 1003).
-define(RK_KF_PLAYER_ACHIEVE, 1004).
-define(RK_KF_PLAYER_MERIDIAN, 1005).
-define(RK_KF_PLAYER_GJPT, 1006).
-define(RK_KF_PLAYER_WEAR, 1007).
-define(RK_KF_PLAYER_HUANHUA, 1008).
-define(RK_KF_PET_POWER, 2001).
-define(RK_KF_PET_GROW, 2002).
-define(RK_KF_PET_LEVEL, 2003).
-define(RK_KF_EQUIP_WEAPON, 3001).
-define(RK_KF_EQUIP_DEFENG, 3002).
-define(RK_KF_EQUIP_SHIPIN, 3003).
-define(RK_KF_MOUNT_POWER, 4001).
-define(RK_KF_FLOWER_DAILY_MAN, 7001).
-define(RK_KF_FLOWER_DAILY_WOMEN, 7002).
-define(RK_KF_FLOWER_COUNT_MAN, 7003).
-define(RK_KF_FLOWER_COUNT_WOMEN, 7004).

-define(RK_CLS_LIMIT,  100).
-define(RK_KF_LIMIT, 200).
-define(RK_KF_ETS_1V1_RANK, kf_ets_1v1_rank).
-define(RK_KF_ETS_RANK, kf_ets_rank).
-define(RK_KF_FLOWER_RANK, kf_ets_flower_rank).
-define(RK_KF_SP_LIST, kf_ets_sp_list).
-record(kf_ets_1v1_rank, {
	type_id,
	rank_list = []
}).

-record(kf_ets_sp_list, {
	type,			 %% 特殊数据类型
	sp_lists = []   %% 特殊数据内容
}).

-record(kf_ets_flower_rank, {
	m_key,			 %% 此KEY是{类型, 平台ID}组成
	node_lists = [], %% 本平台的node列表
	rank_list = []
}).

-record(kf_ets_rank, {
	type_id,
	rank_list = []
}).

%% 跨服战力排行榜活动
-define(RK_ETS_POWER_ACTIVITY, ets_rank_power_activity).
-record(kfrank_power_activity, {
	platform, %% 平台标识
	top_10 = [], %% 前10形象, 格式: [{[Platform, ServerId, Id], Image}, ...]
	rank_list = [] %% 排行数据, 格式: [[Platform, ServerId, Id, NickName, Realm, Career, Sex, Lv, Power], ...]
}).


-define(RK_CLS_GET_WEEK, <<"SELECT platform,server_num,id,node,name,country,carrer,sex,loop_week,
	win_loop_week,score_week,pt,lv FROM rank_kf_1v1 ORDER BY score_week DESC, last_time DESC LIMIT ~p">>).
-define(RK_CLS_KF1V1_TRUNCATE, <<"TRUNCATE TABLE rank_kf_1v1">>).
-define(RK_CLS_KF1V1_DABIAO, <<"SELECT node, id, score_week FROM rank_kf_1v1 
	ORDER BY score_week DESC, last_time DESC LIMIT ~p, ~p">>).
-define(RK_CLS_GET_ROW, <<"SELECT pt FROM rank_kf_1v1 WHERE platform='~s' AND server_num=~p AND id=~p">>).
-define(RK_CLS_INSERT, <<"REPLACE INTO rank_kf_1v1 SET platform='~s',server_num=~p,id=~p,`node`='~s',
	name='~s',country=~p,sex=~p,carrer=~p,image=~p,lv=~p,
	`loop`=~p,win_loop=~p,hp=~p,pt=~p,score=~p,
	loop_week=~p,win_loop_week=~p,hp_week=~p,score_week=~p,
	loop_day=~p,win_loop_day=~p,hp_day=~p,score_day=~p,last_time=~p">>).
-define(RK_CLS_UPDATE, <<"UPDATE rank_kf_1v1 SET 
	name='~s',country=~p,sex=~p,carrer=~p,image=~p,lv=~p,
	`loop`=`loop`+~p,win_loop=win_loop+~p,hp=hp+~p,pt=pt+~p,score=score+~p,
	loop_week=loop_week+~p,win_loop_week=win_loop_week+~p,hp_week=hp_week+~p,score_week=score_week+~p,
	loop_day=loop_day+~p,win_loop_day=win_loop_day+~p,hp_day=hp_day+~p,score_day=score_day+~p,last_time=~p
	WHERE platform='~s' AND server_num=~p AND id=~p">>).

-define(RK_CLS_KF3V3_MVP, <<"SELECT platform,server_num,id,node,name,country,carrer,sex,lv,
	pt,win,lose,mvp FROM rank_kf_3v3 ORDER BY mvp DESC LIMIT ~p">>).
-define(RK_CLS_KF3V3_GET_ROW, <<"SELECT pt FROM rank_kf_3v3 WHERE platform='~s' AND server_num=~p AND id=~p">>).
-define(RK_CLS_KF3V3_INSERT, <<"REPLACE INTO rank_kf_3v3 SET platform='~s',server_num=~p,id=~p,`node`='~s',
	name='~s',country=~p,sex=~p,carrer=~p,image=~p,lv=~p,pt=~p,score=~p,mvp=~p,win=~p,lose=~p,last_time=~p">>).
-define(RK_CLS_KF3V3_UPDATE, <<"UPDATE rank_kf_3v3 SET name='~s',country=~p,sex=~p,carrer=~p,image=~p,lv=~p,
	pt=~p,score=score+~p,mvp=mvp+~p,win=win+~p,lose=lose+~p,last_time=~p 
	WHERE platform='~s' AND server_num=~p AND id=~p">>).
-define(RK_CLS_KF3V3_TRUNCATE, <<"TRUNCATE TABLE rank_kf_3v3">>).
-define(RK_CLS_KF3V3_DABIAO, <<"SELECT node, id, mvp FROM rank_kf_3v3 
	ORDER BY mvp DESC LIMIT ~p, ~p">>).


-define(SQL_RK_KF_PLAYER_GET, <<"SELECT id,platform,server_num,nickname,realm,career,sex,value FROM rank_kf_player
	WHERE type=~p ORDER BY value DESC LIMIT ~p">>).
-define(SQL_RK_KF_PLAYER_INSERT, <<"REPLACE INTO rank_kf_player SET id=~p,platform='~s',server_num=~p,
	type=~p,nickname='~s',realm=~p,career=~p,sex=~p,value=~p,time=~p">>).

-define(SQL_RK_KF_PET_GET, <<"SELECT petid,platform,server_num,petname,role_id,nickname,realm,career,sex,value
	FROM rank_kf_pet WHERE type=~p ORDER BY value DESC LIMIT ~p">>).
-define(SQL_RK_KF_PET_INSERT, <<"REPLACE INTO rank_kf_pet SET platform='~s',server_num=~p,
	petid=~p,type=~p,role_id=~p,nickname='~s',petname='~s',realm=~p,career=~p,sex=~p,value=~p,time=~p">>).

-define(SQL_RK_KF_EQUIP_GET, <<"SELECT role_id,platform,server_num,goods_id,gtype_id,nickname,color,career,equip_subtype,score
	FROM rank_kf_equip WHERE type = ~p ORDER BY score DESC LIMIT ~p">>).
-define(SQL_RK_KF_EQUIP_INSERT, <<"REPLACE INTO rank_kf_equip SET platform='~s',server_num=~p,goods_id=~p,
	type=~p,role_id=~p,nickname='~s',gtype_id=~p,equip_subtype=~p,color=~p,career=~p,score=~p,time=~p">>).

-define(SQL_RK_1V1_OUT100_COUNT, <<"SELECT COUNT(*) FROM rank_kf_1v1 WHERE score_week>=~p">>).
-define(SQL_RK_1V1_OUT100_GET, <<"SELECT node, id FROM rank_kf_1v1 WHERE score_week>=~p LIMIT ~p, ~p">>).

