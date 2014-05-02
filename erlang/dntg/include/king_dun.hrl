%%------------------------------------------------------------------------------
%% @Module  : king_dun.hrl
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.11.20
%% @Description: 皇家守卫军塔防副本头文件
%%------------------------------------------------------------------------------


%% 定义在场景服务器的一些操作.
-define(CREATE_ENEMY_MON, 1). %1.创建敌对怪物.
-define(CREATE_BUILDING, 2).  %2.创建建筑物.
-define(UPGRADE_BUILDING, 3). %3.升级建筑物.
-define(UPGRADE_SKILL, 4).    %4.升级技能.


%% 塔防副本状态.
-record(king_dun_state,{
	is_start = false,    %% 副本是否开始了.
	exp = 0,             %% 获得的经验.
	score = 0,           %% 获得积分.	
	enemy_mon_list = [], %% 敌对怪物列表[怪物ID, 怪物数量，已经砍死的怪物数量，积分，经验].
	building_list = [],  %% 建筑列表[king_dun_building，king_dun_building].
	create_pid_list = [],%% 创建怪物进程列表[{怪物ID, 进程列表}].
	last_begin_time = 0, %% 上一波开始时间.
	create_mon_timer = 0,%% 创建怪物定时器.
	owner_id = 0,        %% 创建者的id.
	finish_level = 0,    %% 已完成的最大波数.
	finish_time = 0,     %% 已完成的最大波数花费的时间.
	max_level = 0        %% 历史已完成的最大波数.
}).

%% 塔防副本敌对怪物.
-record(king_dun_enemy_mon,{
	level = 0,          %% 波数.
	mon_id = 0,         %% 怪物id.
	mon_count = 0,      %% 怪物数量.
	kill_mon_count = 0, %% 已经杀死的怪物数量.
	exp = 0,            %% 获得经验.
	score = 0           %% 获得积分.
}).

%% 塔防副本配置.
-record(king_dun_data,{
	level = 0,          %% 波数.
	mon_id = 0,         %% 怪物id.
	mon_name = <<"">>,  %% 怪物名字
	mon_count = 0,      %% 怪物总数.
	time = 0,           %% 进攻时间.
	direction = [],     %% 进攻路径[{路线1，怪物数量},{2,count},{3,count}].
	exp = 0,            %% 获得经验.
	score = 0,          %% 获得积分.
	kill_mon = [],      %% 杀死的怪物波数.
	next_level = 0      %% 下一关.
}).

%% 塔防副本建筑.
-record(king_dun_building,{
	auto_id = 0,        %% 自增ID.
	mid = 0,            %% 怪物id.
	position = 0,       %% 坐标类型.
	skill_list = [],    %% 技能列表[{技能ID，等级}，{技能ID，等级}].
	soldier_list = []   %% 士兵列表.
}).

%% 塔防副本士兵.
-record(king_dun_soldier,{
	auto_id = 0,        %% 自增ID.
	mid = 0             %% 怪物id.
}).

