-define(sql_insert_player_Bd_1v1_one, <<"insert into `player_kf_1v1` (id,
																	  `loop`,
																	  win_loop,
																	  hp,
																	  pt,
																	  score,
																	  loop_week,
																	  win_loop_week,
																	  hp_week,
																	  score_week,
																	  loop_day,
																	  win_loop_day,
																	  hp_day,
																	  score_day,
																	  last_time) 
										values(~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p)">>).

-define(sql_Bd_1v1_update_unsame_week, <<"update `player_kf_1v1` set `loop` = `loop` + ~p,
																	  win_loop = win_loop + ~p,
																	  hp = hp + ~p,
																	  pt = pt + ~p,
																	  score = score + ~p,
																	  loop_week = ~p,
																	  win_loop_week = ~p,
																	  hp_week = ~p,
																	  score_week = ~p,
																	  loop_day = ~p,
																	  win_loop_day = ~p,
																	  hp_day = ~p,
																	  score_day = ~p,
																	  last_time = ~p
										where id=~p">>).

-define(sql_Bd_1v1_update_same_week, <<"update `player_kf_1v1` set `loop` = `loop` + ~p,
																	  win_loop = win_loop + ~p,
																	  hp = hp + ~p,
																	  pt = pt + ~p,
																	  score = score + ~p,
																	  loop_week = loop_week + ~p,
																	  win_loop_week = win_loop_week + ~p,
																	  hp_week = hp_week + ~p,
																	  score_week = score_week + ~p,
																	  loop_day = ~p,
																	  win_loop_day = ~p,
																	  hp_day = ~p,
																	  score_day = ~p,
																	  last_time = ~p
										where id=~p">>).

-define(sql_Bd_1v1_update_same_day, <<"update `player_kf_1v1` set `loop` = `loop` + ~p,
																	  win_loop = win_loop + ~p,
																	  hp = hp + ~p,
																	  pt = pt + ~p,
																	  score = score + ~p,
																	  loop_week = loop_week + ~p,
																	  win_loop_week = win_loop_week + ~p,
																	  hp_week = hp_week + ~p,
																	  score_week = score_week + ~p,
																	  loop_day = loop_day+~p,
																	  win_loop_day = win_loop_day+~p,
																	  hp_day = hp_day+~p,
																	  score_day = score_day+~p,
																	  last_time = ~p
										where id=~p">>).

-record(kf_1v1_state, {
	bd_1v1_stauts=0,  		 	%% 0还未开启  1开启报名中 2开启准备中 3开启比赛中 4已结束（2、3状态已取消）
	loop = 0,				 	%% 总轮次
	loop_time = 0,				%% 每轮耗时（分）
	sign_up_time = 0,           %% 报名时间（分）
	current_loop = 0,		 	%% 当前轮次
	config_end=0,	 		 	%% 本场比赛结束时间(秒)
	loop_end=0,				  	%% 本轮比赛结束时间(秒)
	player_dict = dict:new(), 	%% 玩家字典(key:玩家Id  value：#bd_1v1_player)
	room_dict = dict:new(),		%% 玩家房间字典(key:[场次,AId,BId] vale:[#bd_1v1_room])
	room_no = 1,				%% 房间号，每满指定人数，房间号+1
	room_num = 0,				%% 房间人数，人数不足指定数时，+1
	sign_up_dict = dict:new(),  %% 报名队列（key：[平台,服务,玩家Id] value:匹配失败次数）
	log_1v1_dict = dict:new(),  %% 1v1日志
	look_dict = dict:new(),  	%% 观战列表 key:[场次,AId,BId] value:[{Node,Id,copy_id}]
	no1 = []					%% 战力第一的信息[Combat_powar,Platform,Server_num,Id,Name,Country]
}).

-record(bd_1v1_player, { %% 玩家基础数据
	platform = "",
	server_num = 0,
	node = none,  %玩家所在节点
	id = 0, 	% 玩家Id
	name = "",	% 玩家名称
	country = 0, %玩家国家
	sex = 0,	%性别
	carrer = 0,	%职业
	image = 0,	%头像
	lv = 0,		%等级
	is_in = 0,	%是否在1v1地图里 (0不在 1在)
	loop_day = 0, %当天已参与次数
	loop = 0,   %参与总次数
	win_loop = 0, %胜利次数
	hp = 0,        %平均血量
	combat_power = 0,	   %玩家战力
	max_combat_power = 0,  %玩家最高战力
	copy_id = 0,   %准备区副本Id
	pt_lv = 1,  %声望等级
	pt = 0,		%声望
	score = 1000,   %积分
	pk_pid = none,	%战斗进程
	is_gift = 0		%是否已发奖（0没有 1发了）
}).	

-record(bd_1v1_room, { %%1v1对阵信息
	loop = 0, 				% 轮次
	win_platform = "",
	win_server_num = 0,
	win_id = 0, 			% 是否已分出胜负  
	
	player_a_platform = "",
	player_a_server_num = 0,
	player_a_id = 0, 		% 玩家Id
	player_a_power = 0, 	% 玩家战力
	player_a_hp = 0, 		% 玩家当前血量(判断胜负时的赋值)
	player_a_maxHp = 1, 	% 玩家最高血量(进行时，禁用一切改变属性操作)
	player_a_num = 0, 		% 玩家幸运指数

	player_b_platform = "",
	player_b_server_num = 0,
	player_b_id = 0, 		% 玩家Id
	player_b_power = 0, 	% 玩家战力
	player_b_hp = 0, 		% 玩家当前血量(判断胜负时的赋值)
	player_b_maxHp = 1, 	% 玩家最高血量(进行时，禁用一切改变属性操作)
	player_b_num = 0 		% 玩家幸运指数
}).					 