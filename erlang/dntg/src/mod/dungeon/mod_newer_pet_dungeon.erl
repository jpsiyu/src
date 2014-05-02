%%------------------------------------------------------------------------------
%% @Module  : mod_newer_pet_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.8.29
%% @Description: 新手宠物副本服务
%%------------------------------------------------------------------------------

-module(mod_newer_pet_dungeon).

-export([
		 kill_npc/2          %% 杀死怪物事件.
]).

-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").


%% --------------------------------- 公共函数 ----------------------------------

%% 杀怪事件.
kill_npc([KillMonId|_OtherIdList], State) ->
	
	SceneId = State#dungeon_state.begin_sid,
	CopyId = self(),
	
	case KillMonId of
		%.天兵BOSS击杀时间忽略.
		91023 -> 
			skip;
		_Other ->	
			%1.获取场景怪物数量.
		    AllMonCount = mod_scene_agent:apply_call(SceneId, 
													 lib_scene, 
													 get_scene_mon_num_by_kind, 
													 [SceneId, CopyId, 0]),			
			
			%2.新手宠物副本击杀完所有小怪后再刷新出天兵BOSS.
			case AllMonCount of
				1 ->
                    lib_mon:async_create_mon(91023, SceneId, 16, 39, 0, CopyId, 1, []);
				_Count ->
		            false
			end
	end,
	State.
	

