-record(god, {
	flat = "",								%%平台
	server_id = 0,              			%%服务号
	id = 0,									%%玩家ID
	god_no = 0,           					%%活动第几届
	node = none,							%%节点值
	name = "",								%%昵称
	country = 0,							%%国家
	sex = 0,								%%性别
	carrer = 0,								%%职业
	image = 0,								%%头像
	lv = 0,									%%等级
	power = 0,								%%最高战力
	high_power = 0,							%%历史最高战力
	sea_win_loop = 0,						%%海选胜利场次
	sea_loop = 0,							%%海选参与场次
	sea_score = 0,							%%海选赛积分
	group_room_no = 0,						%%小组赛组号
	group_win_loop = 0,						%%小组赛胜利场次
	group_loop = 0,							%%小组赛参与场次
	group_score = 0,						%%小组赛积分
	group_vote = 0,							%%小组赛票数
	group_relive_is_up = 0,					%%小组赛、复活赛是否晋升
	relive_win_loop = 0,					%%复活赛获胜场次
	relive_loop = 0,						%%复活赛参与次数
	relive_score = 0,						%%复活赛积分
	relive_vote = 0,						%%复活赛票数
	sort_win_loop = 0,						%%总决赛获胜场次
	sort_loop = 0,							%%总决赛参与场次
	sort_score = 0,							%%总决赛积分
	sort_vote = 0,							%%总决赛票数
	create_time = 0,						%%生成记录时间
	praise = 0,								%%崇拜
	despise = 0,							%%鄙视
	is_relive_balace = 0,					%%复活赛是否已结算
	is_in = 0,								%%是否在准备区(0场外 1准备区 2比赛中)					   
	is_db = 1,								%%是否入库(0未入库 1已入库,给海选赛用)
	room_no = 0,							%%房间号
	system_select_loss = 0,					%%系统匹配轮空次数
	scene_id1 = 0,							%%玩家准备场景1
	scene_id2 = 0,							%%玩家战斗场景2
	last_out_war_time = 0					%%玩家退出战斗时间							
}).	

-record(god_room, {
	scene_id = 0,				   
	id = 0, 								%%房间号
	player_list = []						%%房间所在人员([{flat,server_id,id}])
}).	

-record(god_pk, {
	flat_win = "",							%%赢家平台	
	server_id_win = "",              		%%赢家服务器	
	id_win = 0,			 					%%赢家ID
	
	loop = 0,								%%系统轮次，供总决赛用			 
	
	flat_a = "",								
	server_id_a = "",              			
	id_a = 0,
	dead_num_a = 0,							%%已死亡次数
	score_a = 0,
	
	flat_b = "",								
	server_id_b = "",              			
	id_b = 0,	
	dead_num_b = 0,							%%已死亡次数
	score_b = 0,
	
	pk_time = util:unixtime()				%%pk建立时间(用来排序个人对阵表)
}).				   

-record(god_state, {
	mod = 0,				 				%% 状态：0无赛事、1海选赛、2小组赛、3复活赛/人气赛、4总决赛
	last_mod = 0,							%% 上一个状态
	next_mod = 0,							%% 下一个状态
	status = 0,								%% 开启状态: 0 未开启 1 进行中 2 已结束
	god_no = 0,								%% 第几届活动
	last_god_no = 0,						%% 上一个届(主要是给秘籍用)
	config_end = 0,
	open_day = 0,
	open_time = 0,
	sort_current_loop = 0,					%% 总决赛当前轮次
	max_room_no = 0,						%% 当前最大房间号
	god_dict = dict:new(),					%% 诸神记录（key:{flat,server_id,id} value:#god{}）
	god_room_dict = dict:new(),				%% 房间字典 (key:{Scene_id1,房间号} value:#god_room{})
	god_pk_dict = dict:new(),				%% 战斗字典 (key:{flat,server_id,id,flat,server_id,id,Loop} value:#god_pk{})
	god_top50_dict = dict:new()			%% 历届前50名单(key:god_no value:[God])
}).			

