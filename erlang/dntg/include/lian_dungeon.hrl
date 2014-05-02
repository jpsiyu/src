%%------------------------------------------------------------------------------
%% @Module  : lian_dungeon.hrl
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.11.20
%% @Description: 连连看副本头文件
%%------------------------------------------------------------------------------


%% 定义在场景服务器的一些操作.
-define(INIT_CREATE_MON, 1).      %% 1.初始化创建怪物.
-define(RANDOM_CREATE_MON, 2).    %% 2.随机创建怪物.
-define(DELETE_MON, 3).           %% 3.删除建筑物.


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

%% 连连看副本状态.
-record(lian_dun_state,{
	is_start = false,        %% 副本是否开始了.
	exp = 0,                 %% 经验.
	score = 0,               %% 积分.
    combo = 0,               %% 连斩.
	begin_time = 0,          %% 开始的时间.
	extand_time = 0,         %% 增加的时间.
    close_dungeon_timer = 0, %% 关闭副本的定时器.
	send_tv = 0,             %% 发送传闻等级(1,2,3).
	delete_list1	= [],    %% 消除怪物自增ID列表.
	delete_list2	= [],    %% 消除怪物位置列表.
	a1 = #lian_dun_mon{},    %% A怪物1.
	a2 = #lian_dun_mon{},    %% A怪物2.
	a3 = #lian_dun_mon{},    %% A怪物3.
	b1 = #lian_dun_mon{},    %% B怪物1.
	b2 = #lian_dun_mon{},    %% B怪物2.
	b3 = #lian_dun_mon{},    %% B怪物3.
	c1 = #lian_dun_mon{},    %% C怪物1.
	c2 = #lian_dun_mon{},    %% C怪物2.
	c3 = #lian_dun_mon{}     %% C怪物3.
}).
