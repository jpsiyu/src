%%------------------------------------------------------------------------------
%% @Module  : mod_lian_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.1.10
%% @Description: 连连看副本服务器
%%------------------------------------------------------------------------------


-module(mod_lian_dungeon).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-include("king_dun.hrl").
-include("lian_dungeon.hrl").
-export([handle_info/2]).


%% --------------------------------- 公共函数 ----------------------------------

%% 随机创建怪物.
handle_info({'lian_dun_random_mon', PossionList, SceneId}, State) ->
	lib_lian_dungeon:random_mon(SceneId, PossionList),
	{noreply, State};

%% 设置怪物信息.
handle_info({'lian_dun_set_mon_info', MonList, IsCalc}, State) ->
	%1.设置怪物信息.
	[lib_lian_dungeon:set_mon_info(LianMon)|| 
	   LianMon <- MonList, is_record(LianMon, lian_dun_mon)],
	
	%TODO 2.如果处于计算状态，随机创建一个怪物.
	lib_lian_dungeon:send_mon_list(State),

	%3.计算积分.
	case IsCalc of
		true ->
			CalcTime = data_lian_dungeon:get_config(calc_time),
			_Ref = erlang:send_after(CalcTime, self(), 'lian_dun_calc_score');
		false ->
			skip
	end,
	{noreply, State};

%% 计算积分.
handle_info('lian_dun_calc_score', State) ->
	lib_lian_dungeon:calc_score(State),
	{noreply, State};

%% 连连看副本开始刷怪.
handle_info('lian_init_create_mon', State) ->
	LianState = lib_lian_dungeon:get_lian_state(),
	IsStart = LianState#lian_dun_state.is_start, 
	
	NewState = 
		case IsStart of
			false ->
				lib_lian_dungeon:save_lian_state(is_start, true),
				SceneId = State#dungeon_state.begin_sid,
			    CopyId = self(),
				CreateData = [SceneId],
				mod_scene_agent:apply_cast(SceneId, lib_lian_dungeon, create_mon, 
										   [?INIT_CREATE_MON, CopyId, CreateData]),
			    State#dungeon_state{level = 1};
			_ ->
				State
		end,

	{noreply, NewState};

%% 连连看副本更新积分.
handle_info('lian_get_score', State) ->
	lib_lian_dungeon:send_score(State, 0, []),
	{noreply, State};

%% 连连看副本清怪.
handle_info('lian_clear_mon', State) ->
    [catch mod_scene_agent:apply_cast(DunScene#dungeon_scene.id, mod_scene, clear_scene, 
	    [DunScene#dungeon_scene.id, self()])|| DunScene <- State#dungeon_state.scene_list, 
        DunScene#dungeon_scene.id =/= 0],
	{noreply, State}.	

%% --------------------------------- 私有函数 ----------------------------------
