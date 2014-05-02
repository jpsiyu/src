%%%---------------------------------------
%%% @Module  : data_pet_figure
%%% @Author  : faiy
%%% @Created : 2014-04-29 16:16:28
%%% @Description:  宠物幻化
%%%---------------------------------------
-module(data_pet_figure).
-export([get/1]).
-include("pet.hrl").

%%通过id获取记录
get(621401) -> 
	#base_goods_figure{id=621401,figure_id=1,type=62,subtype=14,last_time=0,figure_attr=[{1,250},{2,0},{3,0},{4,25},{5,0},{6,0},{7,0},{8,0},{9,25},{10,25},{11,25}],activate_value=68};

get(621500) -> 
	#base_goods_figure{id=621500,figure_id=100,type=62,subtype=14,last_time=0,figure_attr=[{1,300},{2,0},{3,5},{4,30},{5,15},{6,0},{7,0},{8,0},{9,30},{10,30},{11,30}],activate_value=148};

get(_) ->
	[].

