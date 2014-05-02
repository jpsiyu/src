%% Author: zengzhaoyuan
%% Created: 2012-5-22
%% Description: TODO: Add description to pp_arena_new
-module(pp_arena_new).
-include("unite.hrl").
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([handle/3]).

%%
%% API Functions
%%
handle(Cmd, UniteStatus,_Params)->
	case Cmd of
		48001->lib_arena_new:execute_48001(UniteStatus);
		48003->lib_arena_new:execute_48003(UniteStatus);
		48004->
			SceneId = data_arena_new:get_arena_config(scene_id),
			if
				SceneId =:= UniteStatus#unite_status.scene->%限制场景
					lib_arena_new:execute_48004(UniteStatus#unite_status.id);
				true->
					ok
			end;
		48009->lib_arena_new:execute_48009(UniteStatus);
		_ -> ok
	end.



%%
%% Local Functions
%%

