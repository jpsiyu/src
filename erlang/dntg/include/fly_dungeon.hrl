%%------------------------------------------------------------------------------
%% @Module  : fly_dungeon.hrl
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2013.3.8
%% @Description: 飞行副本头文件
%%------------------------------------------------------------------------------


%% 定义在场景服务器的一些操作.
-define(CREATE_ENEMY_MON, 1). %1.创建敌对怪物.
-define(CREATE_3_MON, 2).     %2.创建第三层BOSS小怪.
-define(UPGRADE_BUILDING, 3). %3.升级建筑物.
-define(UPGRADE_SKILL, 4).    %4.升级技能.


-define(LIAN_MON_A, 1).           %% 1.A怪物.
-define(LIAN_MON_B, 2).           %% 2.A怪物.
-define(LIAN_MON_C, 3).           %% 3.A怪物.
-define(LIAN_MON_DEL_ALL, 4).     %% 4.消除全部.
-define(LIAN_MON_DEL_ROW, 5).     %% 5.删除一行怪物.
-define(LIAN_MON_DEL_COLUMN, 6).  %% 6.删除一列怪物.
-define(LIAN_MON_DEL_CROSS, 7).   %% 7.删除十字怪物.
-define(LIAN_MON_ADD_TIME, 8).    %% 8.增加时间.
-define(LIAN_MON_ADD_SCORE, 9).   %% 9.增加积分.


%% 怪物信息.
-record(lian_dun_mon,{
	auto_id = 0,        %% 自增ID.
	type = 0,           %% 怪物类型.
	position = 0        %% 位置.
}).

%% 飞行副本状态.
-record(fly_dun_state,{
	is_start = false,        %% 是否开始.
	score = 0,               %% 积分.
	star = 1,                %% 星星.
	level = 1,               %% 难度.
	enter_id_list = [],      %% 进过的场景.
	finish_id_list = [],     %% 通关的场景.
	begin_time = 0,          %% 开始时间.
	end_time = 0,            %% 结束时间.
	extand_time = 0,         %% 增加时间.
	close_timer = 0,         %% 关闭副本定时器.
	yin_value = 0,           %% 阴BOSS值.
	yang_value = 0,          %% 阳BOSS值.
	boss_3_hp = 0,           %% 第三层BOSS的血量.
	boss_3_id = 0,           %% 第三层BOSS的ID.
	boss_3_x = 0,            %% 第三层BOSS的X坐标.
	boss_3_y = 0,            %% 第三层BOSS的Y坐标.
	mon_3_count = 0          %% 第三层小怪数量.
}).
