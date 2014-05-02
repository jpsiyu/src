%%%------------------------------------
%%% @Module  : wubianhai_new
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.7.6
%%% @Description: 大闹天宫(无边海)
%%%------------------------------------

%% 记录玩家数据
-define(SQL_INSERT_PLAYER_WUBIANHAI, <<"insert into `player_wubianhai` (`id`,`task1_num`,`task2_num`,`task3_num`,`task4_num`,`task5_num`,`task6_num`,`task7_num`,`kill_num`) values (~p,~p,~p,~p,~p,~p,~p,~p,~p)">>).
%% 获取player_wubianhai所需数据
-define(SQL_PLAYER_WUBIANHAI_DATA, <<"select `task1_num`,`task2_num`,`task3_num`,`task4_num`,`task5_num`,`task6_num`,`task7_num`,`kill_num` from player_wubianhai where id=~p limit 1">>).
%% 更新玩家数据
-define(SQL_WUBIANHAI_DPDATE_WUBIANHAI, <<"update player_wubianhai set `task1_num`=~p,`task2_num`=~p,`task3_num`=~p,`task4_num`=~p,`task5_num`=~p,`task6_num`=~p,`task7_num`=~p,`kill_num`=~p where `id`=~p">>).

%% 各级别房间
-record(arena_room, {
	room_lv=0, %房间类型
    id=0, 	%房间ID
	num=0	%当前房间人口数
}).

%% 玩家第一次查看竞技场房间请求时的等级
-record(arena_player_lv, {
    id=0, 	%玩家ID
	lv=0	%当时等级
}).

-record(task, {
				id=0,  %玩家Id
				tid=0, %任务Id
				mon_id=0, %任务怪物Id
				num=0, %需要数量
				now_num=0, %现在数量
				award_id_list = [], %奖励物品ID
				exp=0, 	%奖励经验
				lilian=0,	%奖励历练
				task_name="",	%任务名称
				get_award=0,	%1 已领取奖励 2 未领取
				kill_name="",	%击杀玩家
				kill_num=0,		%需要击杀的玩家数量
				now_kill=0,		%现在击杀的玩家数量
				mon_x=0,		%怪物自动寻路坐标X
				mon_y=0			%怪物自动寻路坐标Y
}).

%% 玩家第一次查看竞技场房间请求时的等级
-record(arena, {
    id=0, 	%玩家ID
	pid = none, %玩家公共线进程ID
	nickname=0, %玩家昵称
	contry = 0, %玩家国家
	sex = 0,	%性别
	career = 0,	%职业
	image = 0,	%头像
	player_lv = 0, %玩家等级
	room_lv=0, %房间类型
	room_id=0, %房间ID
	task1=#task{}, %任务
	task2=#task{},
	task3=#task{},
	task4=#task{},
	task5=#task{},
	task6=#task{},
	task7=#task{}
}).

%%被杀玩家
-record(killed,{
	uid=0, %被杀玩家ID
	time=0 %被杀时间(时分秒之和)			
}).

-record(state, {
				arena_stauts=0,  %活动状态 0还未开启 1开启中 2当天已结束
				config_begin_hour=0,
				config_begin_minute=0,
				config_end_hour=0,
				config_end_minute=0,
				arena_player_lv_dict = dict:new(), %%Key:玩家ID--Value:当时玩家等级
				arena_room_1_max_id=0, 	%35-45级场自增长ID
				arena_room_2_max_id=0,	%45-55级场自增长ID
				arena_room_3_max_id=0,	%55-65级场自增长ID
				arena_room_4_max_id=0,	%65级及以上场自增长ID
				arena_room_1_dict = dict:new(),
				arena_room_2_dict = dict:new(),
				arena_room_3_dict = dict:new(),
				arena_room_4_dict = dict:new(),
				arena_1_dict = dict:new(),
				arena_2_dict = dict:new(),
				arena_3_dict = dict:new(),
				arena_4_dict = dict:new()
}).
