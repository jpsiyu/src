%% Author: zengzhaoyuan
%% Created: 2012-7-5
%% Description: TODO: Add description to factionwar
-record(factionwar,{       %帮派记录
	faction_id = 0,		   %帮派ID
	faction_name = <<"">>, %帮派名字
	faction_realm = 0,     %帮派阵营
	faction_level = 0,     %帮派等级
	score = 0,			   %帮派积分
	war_score = 0,		   %帮战战分
	is_capture_jgb=0,  	   %是否占领金箍棒 1占领 0没有占领
	war_id = 0,    		   %战场ID
	born_pos = 0,		   %出生点
	member_ids = []		   %进入过战场的帮众ID列表
}).

-record(member,{            %参赛帮众
	id = 0,					%帮众角色ID
	name = "",				%帮众昵称
	realm = 0, %阵营
	sex = 0, %性别
	carrer = 0, %职业
	image = 0, %头像
	lv = 0,    %玩家等级
	faction_id = 0,			%帮派ID
	faction_name = "",
	is_in_war = 0,       	%是否在战场中
	war_id = 0,				%战场ID
	war_score = 0,		    %个人帮战战分
	kill_num = 0, 			%个人杀人数
	killed_num = 0,         %单轮被杀次数
	anger = 0,				%怒气值
	pk_status = 2			%pk状态值
}).

-record(factionwar_db,{%帮战历史记录            
  faction_id=0, 				%帮派ID',
  faction_name = "",			%帮派名字
  faction_chief_id = 0,         %帮主ID
  faction_realm = 0,			%帮派阵营
  faction_score=0,				%帮派积分',
  faction_last_score=0,			%上次帮战积分',
  faction_war_score=0,			%帮派战分',
  faction_war_week_score=0,		%帮派周站分',
  faction_war_last_score=0,		%帮战上次战分',
  faction_war_add_num=0,		%帮战次数',
  faction_war_last_time=0,		%上次帮战时间',
  win_num=0,					%获胜次数(每轮胜利叠加次数)',
  final_win_num=0, 				%最终夺冠次数
  last_is_win = 0				%最后一次帮战是否胜利
}).
