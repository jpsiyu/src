%%------------------------------------------------------------------------------
%% @Module  : mod_fly_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2013.3.7
%% @Description: 飞行副本服务
%%------------------------------------------------------------------------------


-module(mod_fly_dungeon).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-include("fly_dungeon.hrl").
-include("tower.hrl").


-export([handle_info/2]).


%% --------------------------------- 公共函数 ----------------------------------

%% 得到积分.
handle_info({'fly_dun_get_score', _PlayerId}, State) ->	
	%lib_fly_dungeon:get_score(PlayerId),
	{noreply, State};

%% 得到星星.
handle_info({'fly_dun_get_star', PlayerId}, State) ->
	lib_fly_dungeon:get_star(PlayerId),
	{noreply, State};

%% 得到计时.
handle_info({'fly_dun_get_time', PlayerId, SceneId}, State) ->
	lib_fly_dungeon:get_time(PlayerId, SceneId),
	{noreply, State};

%% 得到阴阳BOSS值.
handle_info({'fly_dun_get_yin_yang', PlayerId}, State) ->
	lib_fly_dungeon:get_yin_yang(PlayerId),
	{noreply, State};

%% 设置阴BOSS值.
handle_info({'fly_dun_set_yin', Value}, State) ->
	%1.设置.
	lib_fly_dungeon:save_fly_state([{yin_value, Value}]),
	
	%2.通知玩家.
	FlyDunState = lib_fly_dungeon:get_fly_state(),
	{ok, BinData} = pt_610:write(61074, [FlyDunState#fly_dun_state.yin_value,
										 FlyDunState#fly_dun_state.yang_value]),
	RoleList = State#dungeon_state.role_list,
    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData)||Role <- RoleList],	
	{noreply, State};

%% 设置阳BOSS值.
handle_info({'fly_dun_set_yang', Value}, State) ->
	%1.设置.
	lib_fly_dungeon:save_fly_state([{yang_value, Value}]),
	
	%2.通知玩家.
	FlyDunState = lib_fly_dungeon:get_fly_state(),
	{ok, BinData} = pt_610:write(61074, [FlyDunState#fly_dun_state.yin_value,
										 FlyDunState#fly_dun_state.yang_value]),
	RoleList = State#dungeon_state.role_list,
    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData)||Role <- RoleList],
	{noreply, State};

%% 切换场景.
handle_info({'fly_dun_enter_scene', PlayerId, SceneId, NowSceneId}, State) ->
	lib_fly_dungeon:show_time(PlayerId, SceneId, NowSceneId),
	{noreply, State};

%% 杀死BOSS.
handle_info({'fly_dun_kill_boss', HP, MonId, SceneId, X, Y}, State) ->
	%1.设置.
	lib_fly_dungeon:save_fly_state([{boss_3_hp, HP},
									{boss_3_id, MonId},
									{boss_3_x, X},
									{boss_3_y, Y}]),
	
	%2.创建小怪.
	CopyId = self(),
	CreateData = [SceneId, X, Y, MonId],
	mod_scene_agent:apply_cast(SceneId, lib_fly_dungeon, create_mon,
							   [?CREATE_3_MON, CopyId, CreateData]),
	{noreply, State}.
