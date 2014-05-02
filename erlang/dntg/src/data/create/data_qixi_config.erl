%%%---------------------------------------
%% @Module  : data_qixi_config
%% @Description: 节日活动配置
%%------------------------------------------------------------------------------
-module(data_qixi_config).
-compile(export_all).


%% 判断方法 1.30<Lv<50   2.50<Lv   3.每日充值		
		get_gift_id_and_condition() ->
		[	
			{1,534049,1},{2,534050,2},{3,534076,3}
		].

%% 奖励类型 1：连续登录 2天使宝贝		
		get_qixi_award_open() ->
		[	
			{1,0},{3,1},{4,1}
		].

%% 邮件配置 1：连续登录 2天使宝贝
		get_qixi_mail_config() ->
		[	
			{1,"连续登陆奖励到","亲爱的玩家，感谢您对醉西游的支持，为奖励您本次活动中连续登陆5天，特送上大礼一份，请您查收哦！",534000}
		].

 %% [{任务类型，任务次数，礼包ID，礼包数量},...]
		get_task_config() ->
		[	
			{11,30,531401,1},{12,80,531402,1},{13,150,531421,1},{14,250,531421,2},{15,400,531421,3}
		].
