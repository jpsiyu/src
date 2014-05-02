%%=========================================================================
%% SQL定义
%%=========================================================================

%% -----------------------------------------------------------------
%% 角色信息表SQL
%% -----------------------------------------------------------------
-define(SQL_PLAYER_LOW_SELECT_INFO,              <<"select a.id, a.nickname, a.sex, a.career, a.lv, a.online_flag, a.image, coalesce(b.master_id, 0), coalesce(b.status, 0) from player_low a left join master_apprentice b on a.id=b.id where a.nickname = '~s'">>).
-define(SQL_PLAYER_LOGIN_SELECT_LOGIN,           <<"select last_login_time from player_login where id=~p">>).
-define(SQL_PLAYER_LOGIN_SELECT_LOGOUT,          <<"select last_logout_time from player_login where id=~p">>).

-define(SQL_PLAYER_STATE_SELECT_JOIN_TIME,       <<"select master_join_lasttime from player_state where id=~p">>).
-define(SQL_PLAYER_STATE_UPDATE_JOIN_TIME,       <<"update player_state set master_join_lasttime=~p where id=~p">>).

%% -----------------------------------------------------------------
%% 师傅信息表SQL
%% -----------------------------------------------------------------
-define(SQL_MASTER_SELECT_ALL,                   <<"select a.id, b.nickname,b.sex,b.career,b.realm,v.vip_type,b.lv,a.score,a.apprentice_num,a.apprentice_finish_num,a.status,a.register_time, a.create_time,a.report_num,b.online_flag,b.image from master a join player_low b join player_vip v on a.id = b.id and a.id=v.id">>).


-define(SQL_MASTER_INSERT,                       <<"insert into master(id,name,status,register_time,create_time) values(~p,'~s',~p,~p,~p)">>).

-define(SQL_MASTER_UPDATE_REGISTER,              <<"update master set status=~p,register_time=~p where id=~p">>).
-define(SQL_MASTER_UPDATE_STATUS,                <<"update master set status=~p where id=~p">>).
-define(SQL_MASTER_UPDATE_APPRENTICE_NUM,        <<"update master set apprentice_num=~p where id=~p">>).
-define(SQL_MASTER_UPDATE_JOIN,                  <<"update master set apprentice_num=~p,score=~p where id=~p">>).
-define(SQL_MASTER_UPDATE_FINISH,                <<"update master set score=~p, apprentice_finish_num=~p where id=~p">>).
-define(SQL_MASTER_UPDATE_REPORT,                <<"update master set report_num=~p, score=~p where id=~p">>).
-define(SQL_MASTER_UPDATE_REMOVE_APPRENTICE,     <<"update master set apprentice_num=~p where id=~p">>).
-define(SQL_MASTER_UPDATE_REMOVE_FINISH,         <<"update master set apprentice_num=~p, apprentice_finish_num=~p where id=~p">>).
-define(SQL_MASTER_UPDATE_SCORE,                 <<"update master set score=~p where id=~p">>).
-define(SQL_MASTER_UPDATE_AUTO_CANCEL_REGISTER,  <<"update master set status=0,register_time=0 where status=1 and register_time<=~p">>).

-define(SQL_MASTER_DELETE,                       <<"delete from master where id=~p">>).

%% -----------------------------------------------------------------
%% 师徒关系表SQL
%% -----------------------------------------------------------------
-define(SQL_MASTER_APPRENTICE_SELECT_ALL,        <<"select a.id, b.nickname,b.sex,b.career,b.lv,a.status,a.master_id,a.report_num,a.last_report_level,a.last_report_time,a.accumulate_report_level, a.apply_time,a.invite_time,a.join_time,b.online_flag,b.image from master_apprentice a join player_low b on a.id = b.id">>).

-define(SQL_MASTER_APPRENTICE_INSERT_APPLY,      <<"insert into master_apprentice(id,name,status,master_id,apply_time,last_report_level) values(~p,'~s',~p,~p,~p,~p)">>).
-define(SQL_MASTER_APPRENTICE_INSERT_INVITE,     <<"insert into master_apprentice(id,name,status,master_id,invite_time,last_report_level) values(~p,'~s',~p,~p,~p,~p)">>).

-define(SQL_MASTER_APPRENTICE_UPDATE_JOIN,       <<"update master_apprentice set status=~p, join_time=~p, last_report_level=~p, accumulate_report_level=0 where id=~p">>).
-define(SQL_MASTER_APPRENTICE_UPDATE_STATUS,     <<"update master_apprentice set status=~p where id=~p">>).
-define(SQL_MASTER_APPRENTICE_UPDATE_REPORT,     <<"update master_apprentice set report_num=~p, last_report_level=~p, last_report_time=~p, accumulate_report_level=~p where id=~p">>).

-define(SQL_MASTER_APPRENTICE_DELETE,            <<"delete from master_apprentice where id=~p">>).
-define(SQL_MASTER_APPRENTICE_DELETE_INVITE,     <<"delete from master_apprentice where id=~p and status=3">>).