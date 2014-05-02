%% Author: Administrator
%% Created: 2013-1-3
%% Description: TODO: Add description to data_god
-module(data_god).

%%
%% Include files
%%
-include("predefine.hrl").

%%
%% Exported Functions
%%
-export([
	get/1,
	get_open_day/1		 
]).
-compile(export_all).
%%
%% API Functions
%%
get(Type)->
	case Type of
		% 第几届、开始日期(每个日期后7日内不能再有比赛)(每次测试的时候，要清本轮次数据)(两次时间间隔，至少7天以上)
		open_day -> [{1,2013,3,6},{2,2013,4,1},{3,2013,5,1}];
		% 开启时间点
%%		open_time-> [{14,1,15,1},{21,1,22,1}];
		%% TODO
		open_time-> [{21,1,22,1}];

		% 全服经验双倍开启时刻(时,24小时制)
		god_exp_time->12;
		% 循环时间（秒）
		loop_time->3*60*1000;
		% 海选赛最大参与轮次(每场)
		sea_max_loop->15;
		% 小组赛最大参与轮次(整个赛事)
		group_max_loop->15;
		% 复活赛最大参与轮次(整个赛事)
		relive_max_loop->15;
		% 总决赛最大参与轮次(整个赛事)
		sort_max_loop->10;
		% 总决赛单场循环次数
		sort_sigle_loop->10;
		% 玩家等级限制
		min_lv->50;
		% 玩家战力限制
		min_power->12000;
		% 玩家鄙视崇拜等级
		min_bs_lv->40;
		% 最大鄙视次数
		max_bs_num->10;
		% 鄙视一次获得的铜币
		bs_money->2000;
		% 总参与人口限制
		max_people_no->3500;
		% 安全准备区Id
		scene_id1-> [288,289,290];
		position1-> [[27,20],[19,33],[27,39],[36,32],[19,26],[37,22],[15,39]];
		% 战斗区域ID
		scene_id2-> [291,292,293,294,295,296];
		position2-> [[8,39],[33,16]]; 
		% 离开1v1的默认位置[场景类型ID, X坐标, Y坐标]
		leave_scene -> 
            {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
            [?MAIN_CITY_SCENE, MainCityX, MainCityY];
		% 死亡允许次数
		max_dead_num->3;
		% 海选赛、复活赛最大房间人口数
		max_room_num->60;
		% 小组赛最大小组赛人口数
		max_group_num->40;
		% 战斗被选上的CD时间(秒)
		last_out_war_time->30;
		% 海选赛、小组赛、复活赛、小组赛战斗时间（秒）
		war_time->4*60;
		% 总决赛入场准备时间（秒）
%% 		sort_prepare_time->5*60;
		sort_prepare_time->40;
		% 总决赛下注时间（秒）
%% 		sort_chip_time->6*60;
		sort_chip_time->40;
		% 总决赛退出战斗预留时间（秒）
%% 		sort_rest_war_out_time->1*60;
		sort_rest_war_out_time->30;
		% 小组赛轮空次数
		group_no_match_loop->2;
		% 信仰之心
		xinyangzhixin_id->523601;
		% 人气投票猜中礼包
		y_vote_relive_gift_id->535616;
		% 人气投票未猜中礼包
		n_vote_relive_gift_id->535617;
		
		_->no_match
	end.

%%
%% Local Functions
%%
%%获取各种赛事的最大允许参与次数
%% @param Mod 赛事
get_max_loop(Mod)->
	case Mod of
		1->
			data_god:get(sea_max_loop);
		2->
			data_god:get(group_max_loop);
		3->
			data_god:get(relive_max_loop);
		4->
			data_god:get(sort_max_loop);
		_->
			0
	end.

%%获取诸神经验时间
%%@param No 名次
get_god_exp_time(No)->
	if
		No=:=1->24;
		No=<3->12;
		No=<10->7;
		No=<20->4;
		No=<30->2;
		No=<50->1;
		true->0
	end.

%%海选赛按名次礼包
get_gift_sea(_No)->
	{535622,1}.
get_up_gift_sea()->
	{535620,1}.
%%小组赛按名次礼包
get_gift_group(No)->
	if
		No=:=1->{535623,1};
		No=<4->{535624,1};
		No=<10->{535625,1};
		No=<20->{535626,1};
		No=<30->{535627,1};
		No=<40->{535628,1};
		true->{535628,0}    
	end.
%%复活赛按名次礼包
get_gift_relive(_No)->
	{535607,1}.
%%总决赛按名次礼包
get_gift_sort1(No)->
	if
		No=:=1->{535629,1};
		No=:=2->{535630,1};
		No=:=3->{535631,1};
		No=<6->{535632,1};
		No=<10->{535633,1};
		No=<20->{535634,1};
		No=<30->{535635,1};
		No=<40->{535636,1};
		No=<50->{535637,1};
		true->{535637,0} 
	end.
%%总决赛按名次礼包
get_gift_sort2(No)->
	if
		No=:=1->{535614,1};
		true->{535614,0}   
	end.
%%总决赛按名次礼包
get_gift_sort3(No)->
	if
		No=:=1->{535615,1};
		true->{535615,0}   
	end.

	
%% 海选赛勋章
get_xunzhang_sea(Win_loop,Loop)->
	{523501,max(Win_loop*10 + (Loop-Win_loop)*5,1)}.
%% 小组赛勋章
get_xunzhang_group(Win_loop,Loop)->
	{523501,max(Win_loop*20 + (Loop-Win_loop)*10,1)}.
%% 复活赛勋章
get_xunzhang_relive(Win_loop,Loop)->
	{523501,max(Win_loop*20 + (Loop-Win_loop)*10,1)}.
%% 总决赛勋章
get_xunzhang_sort(Win_loop,Loop)->
	{523501,max(Win_loop*50 + (Loop-Win_loop)*20,1)}.
%% 获取信仰之心
get_belief(Win_loop,Loop)->
	Num = util:floor((Win_loop + (Loop-Win_loop)*0.2)),
	if
		Num>3->New_Num = 3;
		true->New_Num = Num
	end,
	{535618,max(New_Num,1)}.
%% 获取霸者之心
get_bazhe(Win_loop,Loop)->
	Num = util:floor((Win_loop + (Loop-Win_loop)*0.2)),
	if
		Num>3->New_Num = 3;
		true->New_Num = Num
	end,
	{523602,max(New_Num,1)}.

%%轮空积分：4*自己战力
%% @param Power 自己战力
%% @return 积分
get_loos_score(Power)->
	4*Power.

%%获胜方积分:自己战力+3*对方战力+自己剩余复活次数*自己战力
%% @param MyPower 自己战力
%% @param HisPower 对手战力
%% @param MyRestDeadNum 自己剩余复活次数
get_succ_score(MyPower,HisPower,MyRestDeadNum)->
	3*HisPower + MyRestDeadNum*MyPower.

%%失败方积分：自己战力 + 杀死对方的次数*对方战力
%% @param MyPower 自己战力
%% @param HisPower 对手战力
%% @param HisDeadNum 杀死对方次数
get_fail_score(MyPower,HisPower,HisDeadNum)->
	MyPower + HisPower*HisDeadNum.

%%获取安全区坐标点
get_position1()->
	PosList = data_god:get(position1),
	Pos = util:rand(1,length(PosList)),
	lists:nth(Pos, PosList).

%%是否可以兑换
%% @return true|false
can_change()->
	Open_day_list = data_god:get(open_day),
	{Year,Month,Day} = date(),
	Gap_days = calendar:date_to_gregorian_days(Year,Month,Day),
	can_change_sub(Open_day_list,Gap_days).
can_change_sub([],_Gap_days)->false;
can_change_sub([{_God_no,Year,Month,Day}|T],Gap_days)->
	Config_Gap_days = calendar:date_to_gregorian_days(Year,Month,Day),
	Gap = Gap_days-Config_Gap_days,
	if
		Gap>10->
			can_change_sub(T,Gap_days);
		Gap>=0->
			true;
		true->
			can_change_sub(T,Gap_days)
	end.

%%获得最近一次的届数
get_god_no(Open_day_list)->
	Sort_Open_day_list = lists:sort(fun({_God_no_a,Year_a,Month_a,Day_a},
										{_God_no_b,Year_b,Month_b,Day_b})-> 
		Gap_days_a = calendar:date_to_gregorian_days(Year_a,Month_a,Day_a),
		Gap_days_b = calendar:date_to_gregorian_days(Year_b,Month_b,Day_b),	
		if
			Gap_days_a=<Gap_days_b->true;
			true->false
		end
	end, Open_day_list),
	{Year,Month,Day} = date(),
	Gap_days = calendar:date_to_gregorian_days(Year,Month,Day),
	get_god_no_sub(Sort_Open_day_list,Gap_days,0).
get_god_no_sub([],_Gap_days,God_no)->God_no;
get_god_no_sub([{T_God_no,Year,Month,Day}|T],Now_Gap_days,God_no)->
	Gap_days = calendar:date_to_gregorian_days(Year,Month,Day),
	if
		Now_Gap_days<Gap_days->%%日期未到
			get_god_no_sub(T,Now_Gap_days,God_no);
		true->%%日期已到或已过期
			get_god_no_sub(T,Now_Gap_days,max(T_God_no,God_no))
	end.

%%获取当前状态及下状态
get_open_day(Open_day_list)->
	Sort_Open_day_list = lists:sort(fun({_God_no_a,Year_a,Month_a,Day_a},
										{_God_no_b,Year_b,Month_b,Day_b})-> 
		Gap_days_a = calendar:date_to_gregorian_days(Year_a,Month_a,Day_a),
		Gap_days_b = calendar:date_to_gregorian_days(Year_b,Month_b,Day_b),	
		if
			Gap_days_a=<Gap_days_b->true;
			true->false
		end
	end, Open_day_list),
	{Year,Month,Day} = date(),
	Gap_days = calendar:date_to_gregorian_days(Year,Month,Day),
	get_open_day_sub(Sort_Open_day_list,Gap_days+1).
get_open_day_sub([],_Now_Gap_days)->{error,no_match};
get_open_day_sub([{God_no,Year,Month,Day}|T],Now_Gap_days)->
	Gap_days = calendar:date_to_gregorian_days(Year,Month,Day),
	if
		Now_Gap_days=<Gap_days->%%日期未到
			get_open_day_sub(T,Now_Gap_days);
		true->%%日期已到或已过期
			Gap = Now_Gap_days-Gap_days,
			if
				Gap<4->
					{ok,{God_no,1,1}};
				Gap=:=4->
					{ok,{God_no,1,2}};
				Gap=:=5->
					{ok,{God_no,2,3}};
				Gap=:=6->
					{ok,{God_no,3,4}};
				Gap=:=7->
					{ok,{God_no,4,0}};
				true->
					get_open_day_sub(T,Now_Gap_days)
			end
	end.
