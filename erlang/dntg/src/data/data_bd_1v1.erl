%% Author: Administrator
%% Created: 2012-10-25
%% Description: TODO: Add description to data_1v1
-module(data_bd_1v1).

%%
%% Include files
%%
-include("predefine.hrl").

%%
%% Exported Functions
%%
-export([get_bd_1v1_config/1,
		 get_position1/0,
		 get_gift/1]).

%%
%% API Functions
%%
get_bd_1v1_config(Type)->
	case Type of
		% 开服天数
		min_open_server->1;
		% 开启房间人口上限
		room_max_num -> 100;
		% 开放日期(星期几)
		open_day -> [7,8,9,10,11];
		% 开启时间点
		open_time-> [[14,0],[21,0]];
		% 每个时间点开启场次
		loop->10;
		% 至少参与轮次，才能获奖。
		min_loop->1; 
		% 每轮报名时间（分钟）
		sign_up_time->1;
		% 每轮准备时间（分钟）
		rest_time->1;
		% 每场次比赛耗时（分钟）
		loop_time->1;
		% 玩家等级限制
		min_lv->45;
		% 玩家战力限制
		min_power->4000;
		% 出场时间限制（秒，超过时间，不再允许入场，判负）
		out_time-> 1;
		% 安全准备区Id
		scene_id1-> 250;
		position1-> [[82,36],[83,72],[39,73],[40,36]];
		% 战斗区域ID
		scene_id2-> 251;
		position2-> [[8,42],[34,17]]; 
		% 离开1v1的默认位置[场景类型ID, X坐标, Y坐标]
        leave_scene -> 
            {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
            [?MAIN_CITY_SCENE, MainCityX, MainCityY];
		
		_->void
	end.

%%获取安全区坐标点
get_position1()->
	PosList = data_bd_1v1:get_bd_1v1_config(position1),
	Pos = util:rand(1,length(PosList)),
	lists:nth(Pos, PosList).

%%
%% Local Functions
%%
%% 按名次获得礼包及礼包数量
get_gift(No)->
	if 
		No>32->[535523,1];
		No>16->[535520,1];
		No>8->[535520,1];
		No>4->[535520,1];
		No>2->[535519,1];
		No=:=2->[535518,1];
		No=:=1->[535517,1];
		true->[535523,1]
	end.
