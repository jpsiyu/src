%%%------------------------------------------------
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.5.30
%%% Description: 生肖 record定义
%%%------------------------------------------------

%% 参与用户的信息
-record(shengxiao_member, {
		role_id
		,role_pid
		,name= ""		%% 角色名
		,realm=0		%% 阵营
        ,bet_time=0     %% 投注时间
		,option1=0		%% 选择的生肖1
		,option2=0		%% 选择的生肖2
		,option3=0		%% 选择的生肖3
		,option4=0		%% 选择的生肖4
		,local1=0		%% 生肖1位置
		,local2=0		%% 生肖2位置
		,local3=0		%% 生肖3位置
		,local4=0		%% 生肖4位置
		,award=0		%% 中奖级别(0=特等奖,1=一等奖,2=二等奖,3=三等奖,4=参与奖)
		,is_drow=0		%% 是否已领取奖励(0=未领取,1=已领取)
		,gold=0			%% 奖励元宝
		,bgold=0		%% 奖励绑定元宝
		,bcopper=0		%% 奖励绑定铜币
		,experience=0	%% 奖励经验
		}).

-define(LV_LIMITED, 35).					%% 参与等级限制
-define(SHENGXIAO_ACTIVITY_DAY, [1,3,5,7]).		%% 一周开放时间(星期)
-define(SHENGXIAO_OPTION_TIME, [21,30]).		%% 活动开始时间[时,分]
-define(SHENGXIAO_LONG,  30 * 60).			%% 活动时长(秒)
-define(SHENGXIAO_END,  30 * 60).			%% 活动结束后显示多久(秒)
-define(END_OPEN, 0).						%% 结束后过多久公布开奖(秒)
-define(SHENGXIAO_BROAD, 60).				%%广播间隔时间(秒)
-define(SHENGXIAO_LIST, ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]).			%% 生肖列表

%% 奖池奖品
-define(SHENGXIAO_GOLD, 100).				%% 奖池元宝
-define(SHENGXIAO_BGOLD, 600).				%% 奖池绑定元宝
-define(SHENGXIAO_BCOPPER, 240 * 10000).	%% 奖池绑定铜币
-define(SHENGXIAO_EXP, 2000 * 10000).		%% 奖池经验数量

%% 获奖比例
-define(TENG_PERCENT, 0.5).					%% 特等奖比例
-define(YI_PERCENT, 0.5).					%% 一等奖比例

%% 固定奖励
-define(ER_BGOLD, 20).						%% 二等奖绑定元宝
-define(ER_BCOPPER, 50000).					%% 二等奖绑定铜币
-define(ER_EXP, 100000).						%% 二等奖经验数量
-define(SAN_BGOLD, 0).						%% 三等奖绑定元宝
-define(SAN_BCOPPER, 30000).				%% 三等奖绑定铜币
-define(SAN_EXP, 40000).					%% 三等奖经验数量
-define(CANYU_BCOPPER, 10000).				%% 参与奖绑定铜币
-define(CANYU_EXP, 40000).					%% 参与奖经验数量



