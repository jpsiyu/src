%% Author: Administrator
%% Created: 2012-9-8
%% Description: TODO: 蟠桃会配置
-module(data_peach).

%%
%% Include files
%%
-include("predefine.hrl").

%%
%% Exported Functions
%%
-export([]).
-compile(export_all).

%%
%% API Functions
%%
%% 基础数据配置
get_peach_config(Type)->
	case Type of
		% 开放日期(星期几)
		open_day -> [1,2,3,4,5,6,7];
		% 帮战报名起始时刻(周2\4\6)
		time->[16,0];
		% 每轮耗时(分钟)
		loop_time->30;
		% 蟠桃会场景类型ID
        scene_id -> 440;
		% 进入出生点
		scene_born -> [30,30];
		% 离开竞技场的默认位置[场景类型ID, X坐标, Y坐标]
		leave_scene -> 
            {MainX, MainY} = lib_scene:get_main_city_x_y(),
            [?MAIN_CITY_SCENE, MainX, MainY];
		% 限制玩家等级
		apply_level -> 30;
		% 房间最大人口数
        room_max_num -> 130;
		% 另开启新房间人口条件(平均每房间人数)
		room_new_num -> 120;
		% 采集怪
		mon_id->42022;
		mon_score->1;
		% 奖励物品ID 
		gift_id1->531411;
		gift_id2->112224;
		% 击杀蟠桃侍卫
		mon_sw_id->42023;
		kill_sw_rate->30;
		kill_sw_score->1;
		% 采集限制
		cj_peach_max->100;
		
		_->void
	end.

%%蟠桃园NPC类型ID列表
get_npc_type_id()->
	[42022,42023].

%% 进入蟠桃园所扣除蟠桃(针对逃跑)
get_enter_plus_peach(Peach_num)->
	if
		60=<Peach_num->round(Peach_num*0.1);
		51=<Peach_num->1;
		true->0
	end.

%% 获取被杀后的蟠桃数
%% @param Peach_num 现有蟠桃数
%% @return int 需要扣除的蟠桃数
get_robbed_num_when_killed(Peach_num)->
	if
		200=<Peach_num->20;
		190=<Peach_num->19;
		180=<Peach_num->18;
		170=<Peach_num->17;
		160=<Peach_num->16;
		150=<Peach_num->15;
		140=<Peach_num->14;
		130=<Peach_num->13;
		120=<Peach_num->12;
		110=<Peach_num->11;
		100=<Peach_num->10;
		90=<Peach_num->9;
		80=<Peach_num->8;
		70=<Peach_num->7;
		60=<Peach_num->6;
		50=<Peach_num->5;
		40=<Peach_num->4;
		30=<Peach_num->3;
		20=<Peach_num->2;
		12=<Peach_num->1;
		true->0
	end.

%% 按排名获取排名系数
get_paiming_ratio(Paiming)->
	if
		1000<Paiming->0;
		300<Paiming->45;
		200<Paiming->50;
		150<Paiming->55;
		100<Paiming->60;
		60<Paiming->65;
		30<Paiming->70;
		10<Paiming->75;
		1<Paiming->80;
		1=:=Paiming->88;
		true->0
	end.
%%按积分获取积分系数
get_jifen_ratio(Jifen)->
	if
		100<Jifen->88;
		90<Jifen->80;
		80<Jifen->75;
		70<Jifen->70;
		60<Jifen->65;
		50<Jifen->60;
		40<Jifen->55;
		30<Jifen->50;
		20<Jifen->45;
		10<Jifen->40;
		true->0
	end.

%%获取翻拍概率
%% @param Peach_num 被抢桃子数
%% @return 获取发生的概率
get_rate_by_card(Peach_num)->
	if
		41=<Peach_num->
			Rate_List = [{100,1},{50,10},{30,30},{15,80},{10,100}];
		31=<Peach_num->
			Rate_List = [{100,1},{50,20},{30,100},{15,80},{10,10}];
		21=<Peach_num->
			Rate_List = [{100,30},{50,100},{30,80},{15,10},{10,10}];
		10=<Peach_num->
			Rate_List = [{100,100},{50,80},{30,30},{15,10},{10,10}];
		true->
			Rate_List = [{100,100},{50,80},{30,30},{15,10},{10,10}]
	end,
	Rate = util:rand(1,100),
	R_List = [V||{V,R}<-Rate_List,Rate=<R],
	Rate2 = util:rand(1,length(R_List)),
	lists:nth(Rate2, R_List).

%%积分兑换物品奖励
%% @param Score 蟠桃园所获得蟠桃分
%% @return [Goods_A_Num,Goods_B_Num]
get_GoodsList(Score)->
	Loop = 100000,
	if
		Score=<0->[0,0];
		true->
			if
				Score<Loop->[0,Score];
				true->[Score div Loop,Score rem Loop]
			end
	end.

%%
%% Local Functions
%%

