%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.6
%%% @Description: 捕蝴蝶活动配置
%%%--------------------------------------

%% 保存在mod_daily中的key
-define(BUTTERFLY_CACHE_SCORE, 1).						%% 本次活动获得的积分
-define(BUTTERFLY_CACHE_EXP, 2).						%% 本次活动获得的经验
-define(BUTTERFLY_CACHE_LLPT, 3).						%% 本次活动获得的历练声望
-define(BUTTERFLY_CACHE_SPEED_UP, 4).					%% 加速符数量
-define(BUTTERFLY_CACHE_SPEED_DOWN, 5).					%% 减速符数量
-define(BUTTERFLY_CACHE_DIZZY, 6).						%% 晕眩符数量
-define(BUTTERFLY_CACHE_DOUBLE, 7).						%% 双倍积分符数量
-define(BUTTERFLY_CACHE_SPEED_UP_TIME, 8).				%% 加速符buff剩余时间
-define(BUTTERFLY_CACHE_SPEED_DOWN_TIME, 9).			%% 减速符buff剩余时间
-define(BUTTERFLY_CACHE_DOUBLE_TIME, 10).				%% 双倍积分符buff剩余时间

%% 保存在buff中的key
-define(BUTTERFLY_BUFF_SPEED_UP_ID, 80).				%% 加速符在buff中的attribute id
-define(BUTTERFLY_BUFF_SPEED_DOWN_ID, 81).				%% 减速符在buff中的attribute id
-define(BUTTERFLY_BUFF_DOUBLE_ID, 82).					%% 双倍积分符在buff中的attribute id

%% 其他定义
-define(BUTTERFLY_BUFF_SPEED_TIME, 90).					%% 加/减速buff效果持续秒数
-define(BUTTERFLY_BUFF_DOUBLE_TIME, 60).				%% 双倍积分buff效果持续秒数
-define(BUTTERFLY_SPEED_UP_RATE, 1.5).					%% 加速倍数
-define(BUTTERFLY_SPEED_DOWN_RATE, 0.5).				%% 减速倍数
-define(BUTTERFLY_SPEED_UP_GOODS, 214704).				%% 加速符id
-define(BUTTERFLY_SPEED_DOWN_GOODS, 214703).			%% 减速符id
-define(BUTTERFLY_DOUBLE_SCORE_GOODS, 214702).			%% 双倍积分符id
-define(BUTTERFLY_WHITE_ID, 10010).						%% 白色蝴蝶ID
-define(BUTTERFLY_GREEN_ID, 10011).						%% 绿色蝴蝶ID
-define(BUTTERFLY_BLUE_ID, 10012).						%% 蓝色蝴蝶ID
-define(BUTTERFLY_PURPLE_ID, 10013).					%% 紫色蝴蝶ID
-define(BUTTERFLY_ORANGE_ID, 10014).					%% 橙色蝴蝶ID

-define(SQL_BUTTERFLY_SELECT, <<"SELECT * FROM butterfly WHERE id=~p">>).
-define(SQL_BUTTERFLY_INSERT, <<"INSERT INTO butterfly(id) VALUES(~p)">>).
-define(SQL_BUTTERFLY_UPDATE, <<"UPDATE butterfly SET score=~p,exp=~p,llpt=~p,get_stat='~s',step_award='~s',score_award=~p,daytime=~p WHERE id=~p">>).
