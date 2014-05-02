%% --------------------------------------------------------
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-03-22
%% @Description:      |仙侣奇缘
%% --------------------------------------------------------
%%% 仙侣奇缘被邀请次数	2700
%%% 仙侣奇缘邀请次数  	2701
%%% vip 仙侣刷新次数		2702
%%---------------------------------仙侣奇缘ETS宏定义----------------------------------
-define(ETS_APPOINTMENT_GAME, ets_appointment_game).                        %% 仙侣奇缘
-define(ETS_APPOINTMENT_CONFIG, ets_appointment_config).                    %% 仙侣奇缘设置
-define(ETS_APPOINTMENT_SUBJECT, ets_appointment_subject).                  %% 仙侣奇缘题目
-define(ETS_APPOINTMENT_SPECIAL_SUBJECT, ets_appointment_special_subject).  %% 仙侣奇缘特殊题目
%%---------------------------------仙侣奇缘ETS宏定义----------------------------------

%% 红娘位置
-define(APP_X, 75).
-define(APP_Y, 170).

%% 心形中央
-define(APP_EXP_X, 80).
-define(APP_EXP_Y, 170).

-define(REFRESH_TIME, 3*60).												%%- 刷新伴侣时间
-define(APP_GAME_OPT_TIME, 10).												%%- 游戏操作间隔
-define(APP_GAME_TIME, 3*60).												%%- 游戏时间
-define(ADD_EXP_TIME, 5*60).												%%- 约会时间
-define(EXP_INTERVAL_TIME, 5).												%%- 经验增加间隔
-define(ANSWER_TIME, 60).	
-define(CLEAR_FLOWER_TIME, 10 * 60).										%%- 清除鲜花时间(如果没有正常清除的话)

%% 仙侣奇缘(事件)
%% step => 0:初始状态 1:已经邀请了(未送礼) 2:送礼后 3:小游戏中 4:约会中 5:评价对方中 8:已完成未交任务
%% gamestate => 0:初始状态
-record(rc_xlqy, {
				begin_time = 0,                                                     %% 仙侣奇缘开始时间
				last_exp_time = 0,                                                  %% 仙侣奇缘上次加经验的时间
				step = 0,                                                          %% 仙侣奇缘状态
			    gamestate = 0
}).

%% 仙侣奇缘(个人)
%% type => 0:初始状态 1:任务方 2:非任务方  
-record(rc_xlqy_self, {
					   type = 0,   	 													   %% type => 0:初始状态 1:任务方 2:非任务方			
					   rand_ids = [],                                                      %% 系统分配的伴侣
					   recommend_partner = [],                                             %% 红颜知己([id， 名字， 选择次数])
					   mark = []                                                           %% 7个与之约会的伴侣次数统计
}).


%% 仙侣奇缘配置
%% 仙侣情缘进行到的步骤 
%% 0:初始状态 1:是否进行游戏选择中 2:游戏抽奖中 3:种花游戏中 4:约会中 5评价对方中
%% 有效值为 0,1,2,3 为 0 正常 1 有虫 2 枯萎 3 两种都有
-record(ets_appointment_config, {
								 id = 0,                                                             %% 玩家id
								 last_partner_id = 0,                                                %% 上次的伴侣
								 now_partner_id = 0,                                                 %% 现在的伴侣
								 refresh_time = 0,                                                   %% 上次刷新时间
								 state = 0,                                                          %% 约会状态(4：邀请方,5：被邀请方)
								 step = 0,                                                      	 %% 仙侣情缘进行到的步骤
								 begin_time = 0,                                                     %% 仙侣奇缘约会开始时间
								 last_exp_time = 0,                                                  %% 仙侣奇缘上次加经验的时间
								 gift_type = 0,                                                 	 %% 礼物类型 物品ID
								 rand_ids = [],                                                      %% 系统分配的伴侣
								 recommend_partner = [],                                             %% 红颜知己([id， 名字， 选择次数])
								 mark = []                                                           %% 7个与之约会的伴侣次数统计
								}).

-record(ets_appointment_game, {
								 id = 0,                                                             %% 玩家id
								 flower_id = 0,                                                   	 %% 鲜花id
								 start_time = 0,                                                     %% 种花开始时间
								 opt_type = 0,                                                       %% 操作类型(0 没有 1浇水 2除虫)
								 opt_time = 0,                                                       %% 上次操作时间
								 opt_time_helper = 0,                                                %% 被邀请玩家上次操作时间
								 prize_type = 0,                                                     %% 抽中的奖励类型
								 score = 0,                                                 	 	 %% 积分
								 bloom_num = 0,                                                  	 %% 开花数量
								 double_num = 0,                                                  	 %% 并蒂花数量
								 flower_status = 0                                                  %% 4位int表示 花朵 1,2,3,4的状态 默认值为 0 0 0 0 
								}).

%% -----------------------------------------------------------------
%% 仙侣情缘SQL
%% -----------------------------------------------------------------
-define(SQL_APPOINTMENT_CONFIG_SELECT_ONE,					"select player_id, last_partner_id, now_partner_id, refresh_time, state, step, begin_time, last_exp_time, gift_type, rand_ids, recommend_partner, mark from appointment_config where player_id=~p limit 1").
-define(SQL_APPOINTMENT_CONFIG_UPDATE_ONE,        			"insert into appointment_config set player_id=~p, last_partner_id=~p, now_partner_id=~p, refresh_time=~p, state=~p, step=~p, begin_time=~p, last_exp_time=~p, gift_type=~p, rand_ids='~s', recommend_partner='~s', mark='~s' ON DUPLICATE KEY UPDATE last_partner_id=~p, now_partner_id=~p, refresh_time=~p, state=~p, step=~p, begin_time=~p, last_exp_time=~p, gift_type=~p, rand_ids='~s', recommend_partner='~s', mark='~s'").
-define(SQL_APPOINTMENT_CONFIG_DELETE_ONE,        			"delete from appointment_config where player_id=~p").

-define(SQL_APPOINTMENT_GAME_SELECT_ONE,					"select player_id, flower_id, start_time, opt_type, opt_time, opt_time_helper, prize_type, score, bloom_num, double_num, flower_status from appointment_game where player_id=~p limit 1").
-define(SQL_APPOINTMENT_GAME_UPDATE_ONE,        			"insert into appointment_game set player_id=~p, flower_id=~p, start_time=~p, opt_type=~p, opt_time=~p, opt_time_helper=~p, prize_type=~p, score=~p, bloom_num=~p, double_num=~p, flower_status=~p ON DUPLICATE KEY UPDATE flower_id=~p, start_time=~p, opt_type=~p, opt_time=~p, opt_time_helper=~p, prize_type=~p, score=~p, bloom_num=~p, double_num=~p, flower_status=~p ").
-define(SQL_APPOINTMENT_GAME_DELETE_ONE,        			"delete from appointment_game where player_id=~p").
-define(SQL_APPOINTMENT_GAME_DELETE_ALL,               		"truncate table appointment_game").

-define(SQL_XLQY_BASE_SELECT_ONE,							"select type, last_partner_id, rand_ids, recommend_partner, mark from xlqy_base where player_id=~p limit 1").
-define(SQL_XLQY_BASE_UPDATE_ONE,        					"insert into xlqy_base set player_id=~p, last_partner_id=~p, rand_ids='~s', recommend_partner='~s', mark='~s' ON DUPLICATE KEY UPDATE last_partner_id=~p, rand_ids='~s', recommend_partner='~s', mark='~s'").
-define(SQL_XLQY_BASE_DELETE_ONE,        					"delete from xlqy_base where player_id=~p").
%% -----------------------------------------------------------------
%% OLD
%% -----------------------------------------------------------------

%% %% -define(SQL_APPOINTMENT_CONFIG_SELECT_ONE,							"select player_id,last_partner_id,now_partner_id,refresh_time,state,step,begin_time,last_exp_time,gift_type,prize_type,score,rand_ids,recommend_partner,mark from appointment_config where player_id=~p limit 1").
%% %% -define(SQL_APPOINTMENT_CONFIG_UPDATE_ONE,        					"insert into appointment_config set player_id=~p,last_partner_id=~p,now_partner_id=~p,refresh_time=~p, state=~p,step=~p, begin_time=~p, last_exp_time=~p,gift_type=~p,prize_type=~p,score=~p,  rand_ids='~s',recommend_partner='~s', mark='~s' ON DUPLICATE KEY UPDATE last_partner_id=~p,now_partner_id=~p,refresh_time=~p, state=~p,step=~p, begin_time=~p, last_exp_time=~p,gift_type=~p,prize_type=~p,score=~p,rand_ids='~s',recommend_partner='~s',mark='~s'").
%% %% -define(SQL_APPOINTMENT_CONFIG_DELETE_ONE,        					"delete from appointment_config where player_id=~p").
%% 
%% %% 仙侣奇缘
%% -record(ets_appointment, {
%% id = 0,                                                             %% 玩家id
%% now_partner_id = 0,                                                 %% 现在的伴侣
%% begin_time = 0,                                                     %% 仙侣奇缘开始时间
%% last_exp_time = 0,                                                  %% 仙侣奇缘上次加经验的时间
%% state = 0,                                                          %% 仙侣奇缘状态
%% continute = 0                                                       %% 连续答对题数
%% }).
%% 
%% %% 仙侣奇缘题目
%% -record(ets_appointment_subject, {
%% id = 0,
%% comment = <<>>,
%% option1 = <<>>,
%% option2 = <<>>,
%% option3 = <<>>,
%% option4 = <<>>
%% }).
%% 
%% %% 仙侣奇缘题目
%% -record(ets_appointment_special_subject, {
%% id = 0,
%% answer = 1,
%% comment = <<>>,
%% option1 = <<>>,
%% option2 = <<>>,
%% option3 = <<>>,
%% option4 = <<>>
%% }).