%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.9
%%% @Description: 聊天
%%%--------------------------------------

-record(call, {
	id=0, 			%角色ID
	nickname,		%角色名
	realm,			%阵营
	sex,			%性别
	color,			%颜色
	content,		%内容
	gm,				%GM
	vip,			%VIP
	work,			%职业
	type,			%喇叭类型  0飞天号角 1冲天号角 2生日号角 3新婚号角 4帮宴传音
	image,			%头像ID  
	channel = 0,    %发送频道 0世界 1场景 2阵营 3帮派 4队伍
	channel_id = 0, %Id 如场景Id、帮派Id,世界发0
	ringfashion     %戒指时装 
}).

-define(HORN_TALK_LV,30).  %% 发喇叭级别
-define(TALK_LIMIT_TIME,180).     %%禁言时
-define(TALK_LIMIT_TIME_0,5*60).  %%禁言5分钟
-define(TALK_LIMIT_TIME_1,10*60). %%禁言10分钟
-define(TALK_LIMIT_TIME_2,30*60). %%禁言30分钟
-define(TALK_LIMIT_TIME_3,60*60). %%禁言1个小时
-define(TALK_LIMIT_TIME_4,2*60*60). %%禁言2小时
-define(TALK_LIMIT_TIME_5,6*60*60). %%禁言6小时
-define(TALK_LIMIT_TIME_6,24*60*60). %%禁言24小时
-define(TALK_LIMIT_TIME_7,3*24*60*60). %%禁言3天
-define(TALK_LIMIT_TIME_8,7*24*60*60). %%禁言一周
-define(ALLOW_INFORM_NUM, 10). %% 最多被举报次数
-define(ALLOW_CHAT_NUM_1, 20). %% 40级下,每天最多私聊玩家数
-define(ALLOW_CHAT_NUM_2, 30). %% 40级下,给非好友最多私聊次数
-define(CHAT_RULE_5_REJECT, [[43], [43,229,165,189,229,143,139]]). %% 聊天规则5,排除字符["+","+加好友"]

-define(SQL_UPDATE_TALK_LIM,<<"update player_login set talk_lim=~p, talk_lim_type=~p, talk_lim_time=~p where id=~p">>).
-define(SQL_UPDATE_LIM_RIGHT,<<"update player_login set talk_lim_right=~p where id=~p">>).
-define(SQL_SELECT_TALK_LIM,<<"select talk_lim,talk_lim_time, talk_lim_right from player_login where id =~p">>).
-define(SQL_LOG_FORBID_CHAT,<<"insert into log_ban set type=3, object='~s', description='~s', time=~p, admin='~s'">>).
-define(SQL_LOG_RELEAS_CHAT,<<"insert into log_ban set type=4, object='~s', description='~s', time=~p, admin='~s'">>).
