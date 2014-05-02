%%%--------------------------------------
%%% @Module  :  guild_dun
%%% @Author  :  hekai
%%% @Description: 
%%%---------------------------------------

-define(GUILD_DUN, "guild_dun_").
-define(SOUL_STATUS, 7).
-define(SELECT_DATA_FOR_INIT, <<"select guild_id,openning_time from guild_dun where openning_time>~p">>).
-define(SELECT_BOOKING_COUNT, <<"select ifnull(count(*),0) from guild_dun where openning_time between ~p and ~p limit 1">>).
-define(INSERT_INTO_GUILD_DUN, <<"insert into guild_dun(guild_id,player_id,player_name,booking_time,openning_time) values(~p,~p,'~s',~p,~p)">>).

-record(guild_dun_state, {
		guild_dun = dict:new() %% 帮派活动记录
	}).

%%关卡1-尖刺陷阱
-record(sys_guild_dun1, {
		trap_area= [],      % 陷阱区域
		die_log = []        % 死亡记录,用于展示尸体 [{PlayerId,Name,X,Y},{..}]
	}).

%%关卡3-死亡测试
-record(sys_guild_dun3, {
		animal = [],      % 怪物列表 [[怪物,颜色],[..]]
		question = [],    % 当前题目 [题目类型,颜色,动物]
		answer = 0,       % 答案
		is_answer =0,     % 是否答题 0|否,1|是
		max_player_id =0, % 已答题最大玩家Id
		start_time = 0,   % 当前题目开始时间
		end_time = 0      % 当前题目结束时间
	}).

%%帮派活动记录
-record(guild_dun, {
		guild_id =0,					% 帮派id
		beginning_dun=0,				% 正在进行的副本关卡
		start_time=0,					% 当前关卡开始时间
		end_time=0,						% 当前关卡结束时间
		active_num =0,					% 当前关卡参与人数	
		die_num=0,						% 当前关卡死亡人数
		dun1 = #sys_guild_dun1{},       % 关卡1-尖刺陷阱 
		dun3 = #sys_guild_dun3{},       % 关卡3-死亡测试 
		player_guild_dun = dict:new()   % 玩家记录(key:玩家id,value:玩家记录)	
	}).

%%玩家记录-关卡1
-record(player_dun_1, {
	is_pass =0,				% 0未通过|1通过
    start_time=0,           % 玩家开始时间
	end_time=0,             % 玩家结束时间
	trap_num=0,             % 踩陷阱次数
	x = 0,                  % 当前x坐标
	y =0                    % 当前y坐标
	}).

%%玩家记录-关卡2
-record(player_dun_2, {
	is_pass =0,				% 0未通过|1通过
    start_time=0,           % 玩家开始时间
	end_time=0              % 玩家结束时间
	}).

%%玩家记录-关卡3
-record(player_dun_3, {
	is_pass =0,				% 0未通过|1通过
    start_time=0,           % 玩家开始时间
	end_time=0,             % 玩家结束时间
	correct_num =0          % 答对题数
	}).

%%玩家记录
-record(player_guild_dun, {
	id=0, 					% 玩家ID
	nickname=0, 			% 玩家昵称
	contry = 0, 			% 玩家国家
	sex = 0,				% 性别
	career = 0,				% 职业
	image = 0,				% 头像
	lv = 0, 				% 玩家等级
	pk_status = 0,			% pk状态
	in_dun =0,              % 是否在副本 0不在|1在
	player_dun_1 = #player_dun_1{}, %%玩家记录-关卡1
	player_dun_2 = #player_dun_2{}, %%玩家记录-关卡2
	player_dun_3 = #player_dun_3{}  %%玩家记录-关卡3
	}).

