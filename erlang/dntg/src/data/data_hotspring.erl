%%%--------------------------------------
%%% @Module  : data_hotspring
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.9
%%% @Description: 温泉
%%%--------------------------------------

-module(data_hotspring).
-compile(export_all).

%% 活动时间
get_activity_time() ->
	%%{时，分}
	[{{12, 0}, {13, 0}}, {{18, 0}, {19, 0}}].

%% 玩家进入等级要求
get_require_lv() -> 30.

%% 房间人数上限
get_room_limit() -> 500.

%% 人数达到多少开下一个房间
get_create_room_limit() -> 400.

%% 房间上限，目前为10个房间
get_room_limitup() -> 10.

%% 互动交互CD秒数
get_interact_cd() -> 10.

%% 取得场景id
get_sceneid(pm) -> 232;
get_sceneid(am) -> 231;
get_sceneid(_) -> 0.

%% 取得进入场景坐标
get_enter_xy() ->
	List = [{47, 57}, {54, 72}, {68, 54}, {55, 34}, {75, 38}],
	util:list_rand(List).

%% 离开温泉后出现的坐标
get_outer_scene() ->
	%%{SceneId, X, Y}
	%{102, 113, 124}.
	{102, 103, 122}.

%% 获取最短结算收益时间间隔(秒)
get_min_count_time() -> 60.

%% 每次互动获得经验
get_interact_exp(LV) -> 	LV * LV * 18.

%% 每分钟获得经验
get_exp(LV) -> LV * LV * 3.

%% 根据等级获取可获得的基础历练经验
%% param LV	玩家等级
get_llpt(LV, VipType) ->
	Num = (100 - math:pow((10 - LV * 0.1), 2)) * 3.6,
	if
		VipType =:= 1 -> Rate = 0.2;
		VipType =:= 2 -> Rate = 0.2;
		VipType =:= 3 -> Rate = 0.2;
		true -> Rate = 0
	end,
	trunc(Num * (1 + Rate)).

%% 获取互动次数
get_interact_num(VIP) ->
	case VIP > 0 of
		true ->	[8, 8];
		_ -> [5, 5]
	end.
