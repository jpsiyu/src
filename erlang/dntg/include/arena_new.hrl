%% Author: zengzhaoyuan
%% Created: 2012-5-21
%% Description: TODO: Add description to arena_new

%% 账户注册时更库
-define(sql_insert_player_arena_one, <<"insert into `player_arena` (`id`,arena_room_lv,arena_room_id,
										arena_score_total,arena_score_week,arena_score_day,
										arena_kill_week,arena_kill_day,arena_killed_total,
									    arena_max_continuous_kill_week,arena_max_continuous_kill_day,
										arena_join_total,arena_last_time) 
										values (~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,1,~p)">>).
%% 获取player_arena所需数据
-define(sql_player_arena_data, <<"select `id`,arena_room_lv,arena_room_id,`arena_score_total`,
								  arena_score_used,`arena_score_week`,`arena_score_day`,`arena_kill_week`,
								  `arena_kill_day`,arena_killed_total,`arena_max_continuous_kill_week`,
								  `arena_max_continuous_kill_day`,arena_join_total,`arena_last_time` 
								  from player_arena where id=~p limit 1">>).
%% 更新同一周记录
-define(sql_arena_update_same_week,<<"update player_arena 
									  set arena_room_lv=~p,arena_room_id=~p,
									  arena_score_total=arena_score_total+~p,
									  arena_score_week=arena_score_week+~p,
									  arena_score_day=~p,arena_kill_week=arena_kill_week+~p,
									  arena_kill_day=~p,arena_killed_total=arena_killed_total+~p,
									  arena_max_continuous_kill_week=~p,arena_max_continuous_kill_day=~p,
									  arena_join_total=arena_join_total+1,arena_last_time=~p where id=~p">>).
%% 更新非同一周记录
-define(sql_arena_update_unsame_week,<<"update player_arena set arena_room_lv=~p,arena_room_id=~p,
										arena_score_total=arena_score_total+~p,arena_score_week=~p,
										arena_score_day=~p,arena_kill_week=~p,arena_kill_day=~p,
										arena_killed_total=arena_killed_total+~p,
										arena_max_continuous_kill_week=~p,arena_max_continuous_kill_day=~p,
										arena_join_total=arena_join_total+1,arena_last_time=~p where id=~p">>).

%% 竞技场各级别房间
-record(arena_room, {
	room_lv=0,                 %房间类型
    id=0, 	                   %房间ID
	num=0,	                   %当前房间人口数
	green_score = 0,           %天庭阵营积分
	red_score = 0,	           %鬼域阵营积分
	green_num = 0,             %天庭人数
	red_num = 0,		       %鬼域人数
	green_numen_kill=0,		   %天庭阵营击杀守护神个数
	red_numen_kill=0,	       %鬼域阵营击杀守护神个数
	green_boss_kill = 0,	   %天庭阵营击杀boss个数
	red_boss_kill = 0,		   %鬼域阵营击杀boss数量
	killed_boss_turn = 0,	   %已杀boss轮数
	next_boss_time = {0,0},    %boss的刷新时间,这是killed_boss_turn+1的boss的生成时间，也就是下一个要被杀的boss时间
	boss_is_alive = 0,		   %boss 是否存活
	boss_award = 0		   	   %boss 的奖励归谁
}).

%% 玩家第一次查看竞技场房间请求时的等级
-record(arena_player_lv, {
    id=0, 	%玩家ID
	lv=0	%当时等级
}).

%% 玩家第一次查看竞技场房间请求时的等级
-record(arena, {
    id=0, 	                       %玩家ID
	pid = none,                    %玩家公共线进程ID
	nickname=0,                    %玩家昵称
	contry = 0,                    %玩家国家
	sex = 0,	                   %性别
	career = 0,	                   %职业
	image = 0,                     %头像
	player_lv = 0,                 %玩家等级
	room_lv=0,                     %房间类型
	room_id=0,                     %房间ID
	realm=0,                       %玩家所属阵营：1.天庭 2.鬼域
	score=0,                       %个人积分
	anger=0,                       %个人怒气
	continuous_kill = 0,           %本次连斩数
	last_kill_time = 0,            %最后一次杀敌时间
	max_continuous_kill = 0,       %最高连斩数
	killed = dict:new(),           %所杀人列表 #killed{}
	kill_num = 0,              	   %杀人数	
	killed_num = 0,                %被杀数
	kill_numen_num = 0,            %击杀守护神数
    kill_boss_num = 0,             %击杀boss数量
    assist_num = 0,                %助攻数量
    kill_score = 0,                %杀人积分
    kill_numen_score = 0,          %击杀守护神积分,阵营击杀守护神对个人加分也在这里
    kill_boss_score = 0,           %击杀boss积分,阵营击杀boss对个人加分也在这里
    assist_score = 0,              %助攻加分
    kill_continuous_score = 0,	   %击杀连斩加成
	pk_status = 2,                 %进入竞技场之前的PK状态
    is_leave = 0                   %是否离开竞技场

}).

%%被杀玩家
-record(killed,{
	uid=0, %被杀玩家ID
	time=0 %被杀时间(时分秒之和)			
}).
