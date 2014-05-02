%%------------------------------------------------------------------------------
%%% @Module  : data_lian_dungeon
%%% @Author  : liangjianxiong
%%% @Email   : ljianxiong@qq.com
%%% @Created : 2012.1.10
%%% @Description: 连连看副本配置
%%------------------------------------------------------------------------------


-module(data_lian_dungeon).
-include("lian_dungeon.hrl").


%% 公共函数：外部模块调用.
-export([
		 get_config/1,              %% 得到副本基本配置.
         get_mon/1,                 %% 得到怪物ID.
         get_mon_position/1,        %% 得到怪物坐标.
         get_row/1,                 %% 得到行位置.
         get_column/1,              %% 得到列位置.
		 get_gift/1                 %% 得到礼包.
]).

%% 得到副本基本配置.
get_config(Type)->
	case Type of
		%1.怪物刷新几率.
		mon_rate -> [{1,2850},{2,2850},{3,2850},{4,130},{5,450},{6,450},{7,250},{8,70},{9,100}];
		
		%1.怪物刷新几率.
		mon_rate2 -> [{1,4275},{2,4275},{3,4275},{4,130},{5,450},{6,450},{7,250},{8,70},{9,100}];
		
		%2.该怪物是战斗类型，被动攻击，不会移动，杀死后获得20积分.
		add_score -> 20;
		
		%3.消除后获得额外20秒副本时间.
		extan_time -> 20;
		
		%4.结算时间.
		calc_time -> 600;
		
		%5.随机创建怪物时间.
		random_mon_time -> 600;
		
		%4.没有定义.
		_ -> undefined
	end.

%% 得到怪物ID.
get_mon(Type)->
	case Type of
		1 -> 98300; %% 普通怪物.
		2 -> 98301; %% 普通怪物.
		3 -> 98302; %% 普通怪物.
		4 -> 98303; %% 消除九宫内的怪物.
		5 -> 98304; %% 消除一行的怪物.
		6 -> 98305; %% 消除一列的怪物.
		7 -> 98306; %% 消除十字的怪物.		
		8 -> 98307; %% 消除后获得额外20秒副本时间.
		9 -> 98308; %% 该怪物是战斗类型，被动攻击，不会移动，杀死后获得50积分.
		_ -> 1
	end.	

%% 得到怪物坐标.
get_mon_position(Position) ->
	case Position of
		1 -> {16, 34};
		2 -> {20, 34};
		3 -> {24, 34};
		4 -> {16, 39};
		5 -> {20, 39};
		6 -> {24, 39};
		7 -> {16, 44};
		8 -> {20, 44};
		9 -> {24, 44};
		_ -> {0, 0}
	end.

%% 得到行位置.
get_row(Type)->
	case Type of
		1 -> [1,2,3];
		2 -> [1,2,3];
		3 -> [1,2,3];
		4 -> [4,5,6];
		5 -> [4,5,6];
		6 -> [4,5,6];
		7 -> [7,8,9];
		8 -> [7,8,9];
		9 -> [7,8,9];
		_ -> [0,0,0]
	end.

%% 得到列位置.
get_column(Type)->
	case Type of
		1 -> [1,4,7];
		2 -> [2,5,8];
		3 -> [3,6,9];
		4 -> [1,4,7];
		5 -> [2,5,8];
		6 -> [3,6,9];
		7 -> [1,4,7];
		8 -> [2,5,8];
		9 -> [3,6,9];
		_ -> [0,0,0]
	end.

%% 得到礼包.
get_gift(Score)->
	if 
		Score >= 5000 -> 
			{534126, 1};
		Score >= 4000 -> 
			{534125, 1};
		Score >= 3000 ->
			{534124, 1};
		Score >= 2000 ->
			{534123, 1};
		Score >= 1500 ->
			{534122, 1};
		Score >= 1000 ->
			{534121, 1};
		true -> 
			{0, 0}
    end.