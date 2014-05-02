-define(SEPARATOR_STRING, "【】").

%%=========================================================================
%% SQL定义
%%=========================================================================

%% -----------------------------------------------------------------
%% 角色表SQL
%% -----------------------------------------------------------------
%-define(SQL_PLAYER_UPDATE_QUIT_GUILD,             "update player_low set guild_quit_lasttime=~p where id=~p").
-define(SQL_PLAYER_SELECT_GUILD_INFO1,            "select a.nickname, a.realm, coalesce(b.guild_id, 0), coalesce(b.guild_name,\"\"), coalesce(b.position,0) from player_low a left join guild_member b on a.id=b.id where a.id = ~p").
-define(SQL_PLAYER_SELECT_GUILD_INFO2_BY_NAME,    "select a.id, a.nickname, a.realm, a.career, a.sex, a.image, a.lv, coalesce(b.guild_id, 0), coalesce(b.guild_name,\"\"),coalesce(b.position,0) from player_low a left join guild_member b on a.id=b.id where a.nickname = '~s'").
-define(SQL_PLAYER_SELECT_GUILD_INFO2_BY_ID,      "select a.id, a.nickname, a.realm, a.career, a.sex, a.image, a.lv, coalesce(b.guild_id, 0), coalesce(b.guild_name,\"\"),coalesce(b.position,0) from player_low a left join guild_member b on a.id=b.id where a.id = ~p").

%% -define(SQL_PLAYER_UPDATE_BIND_COIN,              "update player_high set bcoin=~p where id=~p").
%% -define(SQL_PLAYER_UPDATE_COIN_BOTH,              "update player_high set coin=~p,bcoin=~p where id=~p").
%% -define(SQL_PLAYER_UPDATE_GOLD,                   "update player_high set gold=~p where id=~p").

-define(SQL_PLAYER_SELECT_QUIT_GIULD_NUM,         "select guild_quit_num,guild_quit_lasttime from player_state where id=~p").
-define(SQL_PLAYER_UPDATE_QUIT_GIULD_NUM,         "update player_state set guild_quit_num=~p,guild_quit_lasttime=~p where id=~p").

-define(SQL_PLAYER_LOGIN_SELECT_LAST_LOGIN_TIME,  "select last_login_time from player_login where id=~p").
%% -----------------------------------------------------------------
%% 帮派表SQL
%% -----------------------------------------------------------------
-define(SQL_GUILD_INSERT,                         "insert into guild(name,announce,initiator_id,initiator_name,chief_id,chief_name,realm,create_time,contribution_get_nexttime,level,create_type, member_num, depot_level, mall_level, altar_level, furnace_level, apply_setting, auto_passconfig) "
                                                  "values('~s','~s',~p,'~s',~p,'~s',~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,'~s')").
%% 系统启动时调用
-define(SQL_GUILD_SELECT_IDS,                     "select id from guild order by id asc").

%% 系统启动时调用
-define(SQL_GUILD_SELECT_ALL,                     "select id,name,tenet,announce,initiator_id,initiator_name,chief_id,chief_name,realm,level,reputation,funds,contribution,contribution_get_nexttime,leve_1_last,base_left,qq,create_time,disband_flag,disband_confirm_time,disband_deadline_time,depot_level,hall_level,create_type,house_level,mall_level,mall_contri,altar_level,furnace_level,member_num,c_rename,furnace_growth,mall_growth,depot_growth,altar_growth from guild").

%% 系统启动时调用
-define(SQL_GUILD_SELECT_110,                     "select id,name,tenet,announce,initiator_id,initiator_name,chief_id,chief_name,realm,level,reputation,funds,contribution,contribution_get_nexttime,leve_1_last,base_left,qq,create_time,disband_flag,disband_confirm_time,disband_deadline_time,depot_level,hall_level,create_type,house_level,mall_level,mall_contri,altar_level,furnace_level,member_num,c_rename,furnace_growth,mall_growth,depot_growth,altar_growth,apply_setting,auto_passconfig from guild where id = ~p").

%% 未调用
-define(SQL_GUILD_SELECT_ONE,                     "select id,name,tenet,announce,initiator_id,initiator_name,chief_id,chief_name,realm,level,reputation,funds,contribution,contribution_get_nexttime,leve_1_last,base_left,qq,create_time,disband_flag,disband_confirm_time,disband_deadline_time,depot_level,hall_level,create_type,house_level,mall_level,mall_contri,altar_level,furnace_level,member_num,c_rename,furnace_growth,mall_growth,depot_growth,altar_growth from guild where id = ~p").

%% 创建帮派的时候
-define(SQL_GUILD_SELECT_CREATE,                  "select id,name,tenet,announce,initiator_id,initiator_name,chief_id,chief_name,realm,level,reputation,funds,contribution,contribution_get_nexttime,leve_1_last,base_left,qq,create_time,disband_flag,disband_confirm_time,disband_deadline_time,depot_level,hall_level,create_type,house_level,mall_level,mall_contri,altar_level,furnace_level,member_num,c_rename,furnace_growth,mall_growth,depot_growth,altar_growth,apply_setting,auto_passconfig from guild where name = '~s'").

%% 获取帮派名字
-define(SQL_GET_GUILD_LV,           			  "select level from guild where id = ~p").

-define(SQL_GUILD_UPDATE_DISBAND_INFO,            "update guild set disband_flag=~p, disband_confirm_time=~p where id = ~p").
-define(SQL_GUILD_UPDATE_TENET,                   "update guild set tenet='~s' where id=~p").
-define(SQL_GUILD_UPDATE_ANNOUNCE,                "update guild set announce='~s' where id=~p").
-define(SQL_GUILD_UPDATE_CHANGE_CHIEF,            "update guild set chief_id=~p, chief_name='~s' where id=~p").
-define(SQL_GUILD_UPDATE_ADD_FUNDS,               "update guild set funds=funds+~p where id=~p").
-define(SQL_GUILD_UPDATE_REDUCE_FUNDS,            "update guild set funds=funds-~p where id=~p").
-define(SQL_GUILD_UPDATE_FUNDS,                   "update guild set funds=~p where id=~p").
-define(SQL_GUILD_UPDATE_CONTRIBUTION,            "update guild set contribution=~p where id=~p").
-define(SQL_GUILD_UPDATE_GRADE,                   "update guild set level=~p, contribution=~p, disband_deadline_time=0 where id=~p").
-define(SQL_GUILD_UPDATE_GRADE_BZ,                "update guild set level=~p, funds=~p, contribution=~p, disband_deadline_time=0 where id=~p").
-define(SQL_GUILD_UPDATE_EXPIRED_DISBAND,         "update guild set disband_flag=0, disband_confirm_time=0 where disband_flag=1 and disband_confirm_time < ~p").
-define(SQL_GUILD_UPDATE_DISBAND_DEADLINE,        "update guild set disband_deadline_time=~p where id=~p").
-define(SQL_GUILD_UPDATE_INIT,                    "update guild set contribution=~p, contribution_get_nexttime=~p, level=~p, mall_level=~p, mall_contri=~p, funds=~p, disband_deadline_time=~p where id=~p").

-define(SQL_GUILD_UPDATE_UPGRADE_HALL,            "update guild set hall_level=~p, contribution=~p, funds=~p where id=~p").
-define(SQL_GUILD_UPDATE_UPGRADE_HOUSE,           "update guild set house_level=~p where id=~p").
-define(SQL_GUILD_UPDATE_MEMBER_NUM,              "update guild set member_num=~p where id=~p").
-define(SQL_GUILD_UPDATE_RENAME,                  "update guild set name='~s',c_rename=0 where id=~p").
-define(SQL_GUILD_UPDATE_RENAME_CHIEF,            "update guild set chief_name='~s' where cheif_id=~p").
-define(SQL_GUILD_UPDATE_RENAME_INITIATOR,        "update guild set initiator_name='~s' where initiator_id=~p").
-define(SQL_GUILD_UPDATE_MERGE,                   "update guild set member_num=~p where id=~p").

-define(SQL_GUILD_DELETE,                         "delete from guild where id = ~p").
-define(SQL_GUILD_UPDATE_FUNDS_CONTRIBUTION,      "update guild set funds=~p, contribution=~p where id = ~p").

-define(SQL_GUILD_SELECT_ALL_MEMBER_ID,           "select id,position from guild_member where guild_id=~p").
-define(SQL_GUILD_SELECT_MASTERID,                "select id from guild_member where guild_id=~p and position=1").


-define(SQL_GUILD_UPDATE_UPGRADE_FURNACE,         "update guild set furnace_level=~p, furnace_growth=~p where id=~p").
-define(SQL_GUILD_UPDATE_UPGRADE_MALL,            "update guild set mall_level=~p, mall_growth=~p where id=~p").
-define(SQL_GUILD_UPDATE_UPGRADE_DEPOT,           "update guild set depot_level=~p, depot_growth=~p where id=~p").
-define(SQL_GUILD_UPDATE_UPGRADE_ALTAR,           "update guild set altar_level=~p, altar_growth=~p where id=~p").

-define(SQL_GUILD_UPDATE_APPLYSETTING,            "update guild set apply_setting=~p, auto_passconfig = '~s' where id=~p").


%% -----------------------------------------------------------------
%% 帮派申请表SQL
%% -----------------------------------------------------------------
-define(SQL_GUILD_APPLY_INSERT,                   "insert into guild_apply(player_id,guild_id,create_time) values(~p,~p,~p)").

-define(SQL_GUILD_APPLY_SELECT_GUILD,              "select a.id, a.guild_id, a.player_id, a.create_time, b.nickname, b.sex, b.lv, b.career from guild_apply a join player_low b on a.player_id = b.id where a.guild_id = ~p").
-define(SQL_GUILD_APPLY_SELECT_BY_2,               "select a.id, a.guild_id, a.player_id, a.create_time, b.nickname, b.sex, b.lv, b.career from guild_apply a join player_low b on a.player_id = b.id where a.player_id=~p and a.guild_id = ~p").

-define(SQL_GUILD_APPLY_DELETE,                   "delete from guild_apply where guild_id = ~p").
-define(SQL_GUILD_APPLY_DELETE_PLAYER,            "delete from guild_apply where player_id = ~p").
-define(SQL_GUILD_APPLY_DELETE_ONE,               "delete from guild_apply where player_id = ~p and guild_id = ~p").
-define(SQL_GUILD_APPLY_DELETE_ALL,               "delete from guild_apply where player_id = ~p").

%% -----------------------------------------------------------------
%% 帮派邀请表SQL
%% -----------------------------------------------------------------
-define(SQL_GUILD_INVITE_INSERT,                  "insert into guild_invite(player_id,guild_id,create_time) values(~p,~p,~p)").

-define(SQL_GUILD_INVITE_SELECT_ALL,              "select id, player_id, guild_id, create_time from guild_invite where guild_id = ~p").
-define(SQL_GUILD_INVITE_SELECT_NEW,              "select id, player_id, guild_id, create_time from guild_invite where player_id = ~p and guild_id=~p").

-define(SQL_GUILD_INVITE_DELETE,                  "delete from guild_invite where guild_id = ~p").
-define(SQL_GUILD_INVITE_DELETE_ONE,              "delete from guild_invite where player_id = ~p and guild_id = ~p").
-define(SQL_GUILD_INVITE_DELETE_ALL,              "delete from guild_invite where player_id = ~p").

%% -----------------------------------------------------------------
%% 帮派成员表SQL
%% -----------------------------------------------------------------
-define(SQL_PLAYER_LOW_UPDATE_GUILD_ID,			  "update player_low set guild_id=~p where `id`=~p").
-define(SQL_GUILD_MEMBER_INSERT,                  "insert into guild_member(id,name,guild_id,guild_name,position,create_time) "
                                                  "values(~p, '~s',~p,'~s',~p,~p)").
-define(SQL_GUILD_MEMBER_UPDATE1,     	  			"update guild_member set "
												    "donate_total = ~p,"
													"donate_total_coin = ~p,"
													"donate_total_card = ~p,"
													"donate_lasttime = ~p,"
													"donate_total_lastday = ~p,"
													"donate_total_lastweek = ~p,"
													"paid_get_lasttime = ~p,"
													"depot_store_lasttime = ~p,"
													"depot_store_num = ~p,"
													"donate = ~p,"
													"paid_add = ~p,"
	   												"material=~p where id=~p ").

-define(SQL_GUILD_MEMBER_UPDATE0,     	  			"update guild_member set "
	   												"guild_id = ~p,"
													"guild_name = '~s',"
												    "donate_total = ~p,"
													"donate_total_coin = ~p,"
													"donate_total_card = ~p,"
													"donate_lasttime = ~p,"
													"donate_total_lastday = ~p,"
													"donate_total_lastweek = ~p,"
													"position = ~p,"
	   												"donate = ~p,"
	   												"material=~p,"
	   												"furnace_back=~p," 
	   												"furnace_daily_back = ~p where id=~p ").


%% 系统启动和创建帮派的时候
-define(SQL_GUILD_MEMBER_SELECT_ALL,              "select a.id,a.name,a.guild_id,a.guild_name,a.donate_total,a.donate_total_card,a.donate_total_coin,a.donate_lasttime,a.donate_total_lastday,a.donate_total_lastweek,a.paid_get_lasttime,a.create_time,a.title,a.remark,a.honor,a.depot_store_lasttime,a.depot_store_num,a.position,a.version,a.donate,a.paid_add,b.sex, b.lv, b.career, b.image, a.material, a.furnace_back, a.furnace_daily_back from guild_member a join player_low b on a.id = b.id where a.guild_id = ~p").

%% 新成员加入帮派
-define(SQL_GUILD_MEMBER_SELECT_NEW,              "select a.id,a.name,a.guild_id,a.guild_name,a.donate_total,a.donate_total_card,a.donate_total_coin,a.donate_lasttime,a.donate_total_lastday,a.donate_total_lastweek,a.paid_get_lasttime,a.create_time,a.title,a.remark,a.honor,a.depot_store_lasttime,a.depot_store_num,a.position,a.version,a.donate,a.paid_add,b.sex, b.lv, b.career, b.image, a.material, a.furnace_back, a.furnace_daily_back from guild_member a join player_low b on a.id = b.id where a.id=~p").

%% 成员登陆
-define(SQL_GUILD_MEMBER_SELECT_LOGIN,            "select guild_id, guild_name, position from guild_member where id=~p").

%% 成员登陆 获取player_low登陆所需数据
-define(SQL_PLAYER_GUILD_ID_SELECT,				  "select guild_id from player_low where id=~p").

%% 未使用
-define(SQL_GUILD_MEMBER_SELECT_POSITION,         "select position from guild_member where id=~p").

-define(SQL_GUILD_MEMBER_UPDATE_DONATE_INFO,      "update guild_member set donate=~p,donate_total=~p,donate_total_card=~p,donate_total_coin=~p,donate_lasttime=~p,donate_total_lastweek=~p,donate_total_lastday=~p,paid_add=~p where id = ~p").
-define(SQL_GUILD_MEMBER_UPDATE_PAID,             "update guild_member set paid_get_lasttime=~p, paid_add=~p where id=~p").
-define(SQL_GUILD_MEMBER_UPDATE_TITLE,            "update guild_member set title='~s' where id=~p").
-define(SQL_GUILD_MEMBER_UPDATE_REMARK,           "update guild_member set remark='~s' where id=~p").
-define(SQL_GUILD_MEMBER_UPDATE_DEPOT_STORE_INTO, "update guild_member set depot_store_lasttime=~p, depot_store_num=~p where id=~p").
-define(SQL_GUILD_MEMBER_UPDATE_DEPOT_TAKE_OUT,   "update guild_member set donate=~p where id=~p").
-define(SQL_GUILD_MEMBER_UPDATE_POSITION,         "update guild_member set position=~p, version=~p where id=~p and version=~p").
-define(SQL_GUILD_MEMBER_UPDATE_POSITION1,        "update guild_member set position=~p, version=~p where id=~p").
-define(SQL_GUILD_MEMBER_UPDATE_RENAME_GUILD,     "update guild_member set guild_name='~s' where guild_id=~p").
-define(SQL_GUILD_MEMBER_UPDATE_RENAME,           "update guild_member set name='~s' where id=~p").
-define(SQL_GUILD_MEMBER_UPDATE_MERGE,            "update guild_member set guild_id=~p, guild_name='~s', position=~p where guild_id=~p").
-define(SQL_GUILD_MEMBER_MATERIAL,                "update guild_member set material=~p where id=~p").
-define(SQL_GUILD_MEMBER_DELETE,                  "delete from guild_member where guild_id = ~p").
-define(SQL_GUILD_MEMBER_DELETE_ONE,              "delete from guild_member where id=~p and guild_id = ~p").

-define(SQL_PLAYER_UPDATE_MERGE,            	  "update player_low set guild_id=~p where guild_id=~p").

%% -----------------------------------------------------------------
%% 帮派事件表SQL - 查询已优化(缓存+时间间隔)
%% -----------------------------------------------------------------
-define(SQL_GUILD_EVENT_SELECT,                   "select event_time,event_type,event_param from guild_event where guild_id=~p order by event_time desc limit 200").
-define(SQL_GUILD_EVENT_SELECT_BY_TYPE,           "select event_time,event_type,event_param from guild_event where guild_id=~p and menu_type=~p order by event_time desc limit 200").
-define(SQL_GUILD_EVENT_INSERT,                   "insert into guild_event(guild_id,event_time,menu_type,event_type,event_param) "
                                                  "values(~p,~p,~p,~p,'~s')").
-define(SQL_GUILD_EVENT_DELETE,                   "delete from guild_event where guild_id=~p").
-define(SQL_GUILD_EVENT_DELET_CLEAN,              "delete from guild_event where event_time<=~p").

-define(SQL_GUILD_AWARD_DELETE,                   "delete from guild_award where guild_id=~p").
-define(SQL_GUILD_AWARD_ALLOC_DELETE,             "delete from guild_award_alloc where guild_id=~p").

%% -----------------------------------------------------------------
%% 帮派通讯录SQL 会优先缓存操作
%% -----------------------------------------------------------------
-define(SQL_GUILD_CONTACT_BOOK_INSERTORUPDATE,     "insert into guild_contact_book set uid=~p, gid=~p, playername='~s', city='~s', qq='~s', phone='~s', birthday=~p, hidetype=~p, playerlv=~p ON DUPLICATE KEY UPDATE gid=~p, playername='~s', city='~s', qq='~s', phone='~s', birthday=~p, hidetype=~p, playerlv=~p").
-define(SQL_GUILD_CONTACT_BOOK_SELECT,             "select uid, gid, playername, city, qq, phone, birthday, hidetype, playerlv from guild_contact_book where gid = ~p order by uid").
-define(SQL_GUILD_CONTACT_BOOK_DELETE_ONE,         "delete from guild_contact_book where gid=~p").

%% -----------------------------------------------------------------
%% 帮派成就SQL 会优先缓存操作
%% -----------------------------------------------------------------
-define(SQL_GUILD_ACHIEVE_INSERTORUPDATE,     		"insert into guild_achieved set id=~p, guild_id=~p, achieved_type=~p, achieve_time=~p, is_achieved=~p, get_prize=~p, condition1_num=~p, condition2_num=~p, achieved_level=~p ON DUPLICATE KEY UPDATE guild_id=~p, achieved_type=~p, achieve_time=~p, is_achieved=~p, get_prize=~p, condition1_num=~p, condition2_num=~p, achieved_level=~p").
-define(SQL_GUILD_ACHIEVE_SELECT,             		"select guild_id, achieved_type, achieve_time, is_achieved, get_prize, condition1_num, condition2_num, achieved_level from guild_achieved where guild_id = ~p order by achieved_type").
-define(SQL_GUILD_ACHIEVE_DELETE_ONE,             	"delete from guild_achieved where guild_id=~p").

%% -----------------------------------------------------------------
%% 帮派神兽SQL 会优先缓存操作
%% -----------------------------------------------------------------
-define(SQL_GUILD_GODANIMAL_INSERTORUPDATE,     	"insert into guild_godanimal set guild_id=~p, animal_level=~p, animal_exp=~p ON DUPLICATE KEY UPDATE animal_level=~p, animal_exp=~p").
-define(SQL_GUILD_GODANIMAL_SELECT_ALL,             "select guild_id, animal_level, animal_exp from guild_godanimal").
-define(SQL_GUILD_GODANIMAL_SELECT_ONE,             "select guild_id, animal_level, animal_exp from guild_godanimal where guild_id = ~p").
-define(SQL_GUILD_GODANIMAL_DELETE_ONE,             "delete from guild_godanimal where guild_id=~p").

-define(SQL_GUILD_GA_LOG_INSERTORUPDATE,     		"insert into guild_godanimal_log set guild_id=~p, event='~s' ON DUPLICATE KEY UPDATE event='~s'").
-define(SQL_GUILD_GA_LOG_SELECT_ONE,             	"select event from guild_godanimal_log where guild_id = ~p").

-define(SQL_GUILD_GA_BATTLE,             			"insert into log_ga_battle set guild_id=~p, galevel=~p, type=~p, id1=~p, id2=~p, id3=~p ").

%% 神兽阶段
-define(SQL_GUILD_GA_STAGE_REPLACE,     			"replace into guild_godanimal_stage(guild_id, stage, stage_exp) values(~p, ~p, ~p)").
-define(SQL_GUILD_GA_STAGE_SELECT_ONE,              "select guild_id, stage, stage_exp from guild_godanimal_stage where guild_id = ~p").
-define(SQL_GUILD_GA_STAGE_DELETE_ONE,              "delete from guild_godanimal_stage where guild_id=~p").

%% 神兽技能
-define(SQL_GUILD_GA_SKILL_REPLACE, 				"replace into guild_skill_passive(uid, s_0, s_1, s_2, s_3, s_4, s_5, s_6, s_7, s_8, s_9, ptype, plevel, cdtime) values(~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p)").
-define(SQL_GUILD_GA_SKILL_SELECT_ONE,              "select uid, s_0, s_1, s_2, s_3, s_4, s_5, s_6, s_7, s_8, s_9, ptype, plevel, cdtime from guild_skill_passive where uid = ~p").
-define(SQL_GUILD_GA_SKILL_DELETE_ONE,              "delete from guild_skill_passive where uid=~p").
-define(SQL_LOG_GUILD_GA_SKILL_INSERT,"insert into log_guild_skill_passive(player_id,guild_id,time,pre_score,use_score,skill_type,skill_level) values(~p,~p,~p,~p,~p,~p,~p)"). 

%% -----------------------------------------------------------------
%% 运势任务SQL 会优先缓存操作
%% -----------------------------------------------------------------
-define(SQL_GUILD_FORTUNE_INSERTORUPDATE,     		"insert into fortune set id = ~p, role_color = ~p, task_color = ~p,refresh_left = ~p, refresh_color_time = ~p, brefresh_num = ~p, task_id = ~p,count = ~p,  refresh_task = ~p,  refresh_time = ~p, call_help_time = ~p, status = ~p ON DUPLICATE KEY UPDATE role_color = ~p, task_color = ~p,refresh_left = ~p, refresh_color_time = ~p, brefresh_num = ~p, task_id = ~p,count = ~p,  refresh_task = ~p,  refresh_time = ~p, call_help_time = ~p, status = ~p").
-define(SQL_GUILD_FORTUNE_SELECT_ONE,             	"select id, role_color, task_color, refresh_left, refresh_color_time, brefresh_num, task_id ,count,  refresh_task,  refresh_time, call_help_time, status from fortune where id = ~p").
-define(SQL_GUILD_FORTUNE_DELETE_ALL,               "truncate table fortune").



%% -----------------------------------------------------------------
%% 一些每日处理需要用到的SQL
%% -----------------------------------------------------------------

-define(SQL_GUILD_DAILY_1,                    	  "update guild set contribution=~p, contribution_daily=~p, contribution_threshold=~p, level=~p, leve_1_last=~p, base_left=~p, member_capacity=~p where id=~p").


%% -----------------------------------------------------------------
%% 帮派仙宴SQL
%% -----------------------------------------------------------------
-define(SQL_GUILD_PARTY_START, "replace into  guild_party_log(guild_id, guild_name, sponsor_id, sponsor_name, sponsor_image, sponsor_sex, sponsor_voc, party_type, booking_time) values(~p, '~s', ~p, '~s', ~p, ~p, ~p, ~p, ~p)").

-define(SQL_GUILD_PARTY_START_NOCLEAR, "insert into  guild_party_log_noclear(guild_id, guild_name, sponsor_id, sponsor_name, sponsor_image, sponsor_sex, sponsor_voc, party_type, booking_time) values(~p, '~s', ~p, '~s', ~p, ~p, ~p, ~p, ~p)").

-define(SQL_GUILD_PARTY_BOOKING, "select * from guild_party_log").

-define(SQL_GUILD_PARTY_DELETE, "delete from guild_party_log where guild_id = ~p").

%% -----------------------------------------------------------------
%% 帮派相关日志
%% -----------------------------------------------------------------
-define(SQL_GUILD_UPGRADE_LOG, "SELECT level FROM log_guild_upgrade WHERE guild_id=~p").

%% -----------------------------------------------------------------
%% 帮派非正常关系表
%% -----------------------------------------------------------------

-define(SQL_GUILD_RELA_REPLACE, "replace into guild_rela(guild_id, friend_list, enemy_list) values (~p, '~s', '~s') ").
-define(SQL_GUILD_RELA_SELECT, "SELECT guild_id, friend_list, enemy_list FROM guild_rela WHERE guild_id=~p").







%% ------------------------------------------------------------- E N D -------------------------------------------------------