%% Author: Administrator
%% Created: 2012-10-25
%% Description: TODO: Add description to data_1v1
-module(data_kf_1v1).

%%
%% Include files
%%
-include("predefine.hrl").

%%
%% Exported Functions
%%
-export([
		 get_bd_1v1_config/1,
		 get_position1/0,
		 get_position3/0,
		 get_canshu_gap/2,
		 get_gift/1,
		 get_gift/2,
		 get_pt_lv/1,
		 get_pt/4,
		 get_score/8,
		 is_openday_yestoday/0
]).

%%
%% API Functions
%%
get_bd_1v1_config(Type)->
	case Type of
		% 开服天数
		min_open_server->1;
		% 开启房间人口上限
		room_max_num -> 80;
		% 开放日期(星期几)
		%open_day -> [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];
        open_day -> [];
		% 开启时间点
		open_time-> [[14,0],[21,0]];
		% 每个时间点开启的匹配场次
		loop->15;
		% 每场最多参与次数
		loop_max->15;
		% 每天最多参与次数
		loop_max_day ->30;
		% 至少参与轮次，才能获奖。
		min_loop->1; 
		% 每轮匹配时间(分钟)
		sign_up_time->1;
		% 每轮准备时间(秒)
		rest_time->1;
		% 每场次比赛耗时(分钟)
		loop_time->2;
		% 玩家等级限制
		min_lv->50;
		% 玩家战力限制
		min_power->7000;
		% 第一传闻最低战力
		cw_min_power->25000;
		% 出场时间限制(秒，超过时间，不再允许入场，判负)
		out_time-> 1;
		% 安全准备区Id
		scene_id1-> 250;
 		%position1-> [[61,51]];
		position1-> [[54,45],[69,60],[68,45],[53,60]];
		% 战斗区域ID
		scene_id2-> 251;
		position2-> [[8,42],[34,17]]; 
		position3-> [[8,42],[34,17]]; 
		% 离开1v1的默认位置[场景类型ID, X坐标, Y坐标]
		leave_scene ->
            {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
            [?MAIN_CITY_SCENE, MainCityX, MainCityY];
		% 勋章Id
		xunzhang_id -> 523501;
		% 积分上下限
		min_score->500;
		max_score->6000;
		
		_->void
	end.

%%判断昨天是不是活动日期
is_openday_yestoday()->
	{_Y,_M,D} = date(),
	Open_day = data_kf_1v1:get_bd_1v1_config(open_day),
	lists:member(D, Open_day).

%%获取参数最大差距 （低于45000）
%%@param Cishu 次数
get_canshu_gap(Max_combat_power,Cishu)when Max_combat_power=<45000->
	if 
		Cishu>=5->100000;
		Cishu>=4->60000;
		Cishu>=3->15000;
		Cishu>=2->10000;
		Cishu>=1->5000;
		true->3000
	end;
get_canshu_gap(_Max_combat_power,Cishu)->
	if 
		Cishu>=5->100000;
		Cishu>=4->60000;
		Cishu>=3->20000;
		Cishu>=2->12500;
		Cishu>=1->7500;
		true->5000
	end.

%%获取安全区坐标点
get_position1()->
	PosList = data_kf_1v1:get_bd_1v1_config(position1),
	Pos = util:rand(1,length(PosList)),
	lists:nth(Pos, PosList).

%%获取观战坐标点
get_position3()->
	PosList = data_kf_1v1:get_bd_1v1_config(position3),
	Pos = util:rand(1,length(PosList)),
	lists:nth(Pos, PosList).

%%
%% Local Functions
%%
%% 按名次获得礼包及礼包数量
get_gift(No)->
	if 
		No=:=1->[535524,1];
		No=<10->[535525,1];
		No=<50->[535526,1];
		No=<100->[535527,1];
		true->[535527,1]
	end.

%%获取勋章
get_gift(Loop,WinLoop)->
	Num = WinLoop * 15 + (Loop-WinLoop)*5,
	[523501,Num].

%%获取声望等级
%%@param Pt 声望
%%@return 等级
get_pt_lv(Pt)->
	if
		Pt>=119650->12;
		Pt>=95300->11;
		Pt>=74200->10;
		Pt>=56200->9;
		Pt>=41100->8;
		Pt>=28750->7;
		Pt>=18950->6;
		Pt>=11450->5;
		Pt>=6100->4;
		Pt>=2600->3;
		Pt>= 700->2;
		true->1
	end.

%%获取增加、扣除的声望
%%@param Win_Pt_lv 胜利方的声望等级
%%@param Loos_Pt_lv 失败方的声望等级
%%@return [Win_pt,Loos_pt] 胜利增加分、失败扣除分
get_pt(Win_Pt_lv,WinPt,Loos_Pt_lv,LoosPt)->
	_Win_pt = util:floor(Loos_Pt_lv*275/(Loos_Pt_lv+Win_Pt_lv*2)),
	_Loos_pt = util:floor(Loos_Pt_lv*3*(65+Loos_Pt_lv*1.5)/(Loos_Pt_lv+Win_Pt_lv*2)),
	if
		_Win_pt=<0->
			Win_pt = 1;
		true->
			Win_pt = _Win_pt
	end,
	if
		Loos_Pt_lv<6->
			Loos_pt = 0;
		true->
			if
				_Loos_pt<0->
					Loos_pt = 0;
				true->
					Loos_pt = _Loos_pt
			end
	end,
	_F_WinPt = WinPt + Win_pt,
    _F_LoosPt = LoosPt - Loos_pt,
	if
		_F_WinPt>1000->
			F_WinPt = 1000;
		_F_WinPt<0->
			F_WinPt = 0;
		true->
			F_WinPt = _F_WinPt
	end,
	if
		_F_LoosPt>1000->
			F_LoosPt = 1000;
		_F_LoosPt<0->
			F_LoosPt = 0;
		true->
			F_LoosPt = _F_LoosPt
	end,
	[F_WinPt,F_LoosPt].

%%获取增加、扣除的积分
%%@param Win_Pt_lv 胜利方的声望等级
%%@param Loos_Pt_lv 失败方的声望等级
%%@return [Win_pt,Loos_pt] 胜利增加分、失败扣除分
get_score(_Win_Pt_lv,WinScore,Win_power,Win_lv,_Loos_Pt_lv,LoosScore,Loos_power,Loos_lv)->
	_Win_score = util:floor((LoosScore*100/(LoosScore+WinScore*2) + Loos_lv*100/(Loos_lv+Win_lv*2) + Loos_power*100/(Loos_power+Win_power*2))*(1+(Win_power-12500)/50000+(Win_lv-55)/80)),
	_Loos_score = util:floor((LoosScore*(50+LoosScore/50)/(LoosScore+WinScore*2) + Loos_lv*(50+Loos_lv/5)/(Loos_lv+Win_lv*2) + Loos_power*(50+Loos_power/5000)/(Loos_power+Win_power*2))*(1+(Loos_power-15000)/80000+(Loos_lv-60)/100)),
	if
		_Win_score=<0->
			Win_score = 1;
		true->
			Win_score = _Win_score
	end,
	if
		_Loos_score<0->
			Loos_score = 0;
		true->
			Loos_score = _Loos_score
	end,

	_F_WinScore = WinScore + Win_score,
    _F_LoosScore = LoosScore - Loos_score,
	if
		_F_WinScore>6000->
			F_WinScore = 6000;
		_F_WinScore<500->
			F_WinScore = 500;
		true->
			F_WinScore = _F_WinScore
	end,
	if
		_F_LoosScore>6000->
			F_LoosScore = 6000;
		_F_LoosScore<500->
			F_LoosScore = 500;
		true->
			F_LoosScore = _F_LoosScore
	end,
	[F_WinScore,F_LoosScore].
