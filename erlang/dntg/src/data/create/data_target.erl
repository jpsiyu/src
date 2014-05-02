%%%---------------------------------------
%%% @Module  : data_target
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  目标
%%%---------------------------------------
-module(data_target).
-compile(export_all).
-include("target.hrl").

%%分组个数
get_group_num() ->
	5.
%%所有分组及子目标
get_all() ->
	[{1, [101,102,103,104,105]}, {2, [201,202,203,204,205]}, {3, [301,302,303,304,305]}, {4, [401,402,403,404,405]}, {5, [501,502,503,504,505]}].

%%通过分组id获取子目标id列表
get_target_id_list(1) ->
    [101,102,103,104,105];
get_target_id_list(2) ->
    [201,202,203,204,205];
get_target_id_list(3) ->
    [301,302,303,304,305];
get_target_id_list(4) ->
    [401,402,403,404,405];
get_target_id_list(5) ->
    [501,502,503,504,505];
get_target_id_list(_) -> 
	[].		

get_by_id(101) -> 
	#game_target{step=1, target_id=101, gift_id=3041};
get_by_id(102) -> 
	#game_target{step=1, target_id=102, gift_id=3042};
get_by_id(103) -> 
	#game_target{step=1, target_id=103, gift_id=3043};
get_by_id(104) -> 
	#game_target{step=1, target_id=104, gift_id=3044};
get_by_id(105) -> 
	#game_target{step=1, target_id=105, gift_id=3045};
get_by_id(201) -> 
	#game_target{step=2, target_id=201, gift_id=3047};
get_by_id(202) -> 
	#game_target{step=2, target_id=202, gift_id=3048};
get_by_id(203) -> 
	#game_target{step=2, target_id=203, gift_id=3049};
get_by_id(204) -> 
	#game_target{step=2, target_id=204, gift_id=3050};
get_by_id(205) -> 
	#game_target{step=2, target_id=205, gift_id=3051};
get_by_id(301) -> 
	#game_target{step=3, target_id=301, gift_id=3052};
get_by_id(302) -> 
	#game_target{step=3, target_id=302, gift_id=3053};
get_by_id(303) -> 
	#game_target{step=3, target_id=303, gift_id=3054};
get_by_id(304) -> 
	#game_target{step=3, target_id=304, gift_id=3055};
get_by_id(305) -> 
	#game_target{step=3, target_id=305, gift_id=3056};
get_by_id(401) -> 
	#game_target{step=4, target_id=401, gift_id=3057};
get_by_id(402) -> 
	#game_target{step=4, target_id=402, gift_id=3058};
get_by_id(403) -> 
	#game_target{step=4, target_id=403, gift_id=3059};
get_by_id(404) -> 
	#game_target{step=4, target_id=404, gift_id=3060};
get_by_id(405) -> 
	#game_target{step=4, target_id=405, gift_id=3061};
get_by_id(501) -> 
	#game_target{step=5, target_id=501, gift_id=3062};
get_by_id(502) -> 
	#game_target{step=5, target_id=502, gift_id=3063};
get_by_id(503) -> 
	#game_target{step=5, target_id=503, gift_id=3064};
get_by_id(504) -> 
	#game_target{step=5, target_id=504, gift_id=3065};
get_by_id(505) -> 
	#game_target{step=5, target_id=505, gift_id=3066};
get_by_id(_) ->
	[].

