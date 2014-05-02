%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.2
%%% @Description: 目标
%%%--------------------------------------

-define(GAME_TARGET_ALLID(RoleId), lists:concat(["mod_target_allid_", RoleId])).
-define(GAME_TARGET(RoleId, TargetId), lists:concat(["mod_target_", RoleId, "_", TargetId])).
-define(sql_target_fetch_all, <<"SELECT role_id, target_id, status FROM role_target WHERE role_id=~p">>).
-define(sql_target_insert, <<"REPLACE INTO role_target SET role_id=~p, target_id=~p, status=~p">>).

-record(game_target, {
	step = 0,		%% 第几个阶段
	target_id = 0,	%% 目标ID
	gift_id = 0		%% 礼包ID
}).
-record(role_target, {
	id = {0,0},		%%{角色id, 目标id}
	status = 1		%%状态，1完成，2领取奖励
}).