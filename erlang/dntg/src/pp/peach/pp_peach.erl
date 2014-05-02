%% Author: zengzhaoyuan
%% Created: 2012-5-22
%% Description: TODO: Add description to pp_arena_new
-module(pp_peach).
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
handle(Cmd, UniteStatus,Params)->
	Apply_level = data_peach:get_peach_config(apply_level),
	SceneId = data_peach:get_peach_config(scene_id),
	Peach_status = mod_peach:get_status(),
	if
		Cmd =:= 48110->
			lib_peach:execute_48110(UniteStatus);
		(Cmd/=48101 andalso Cmd/=48105) andalso Peach_status /= 1-> %非进行中
%% 			{ok, BinData} = pt_481:write(48000, [1]),
%%     		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
			ok;
		(Cmd/=48101 andalso Cmd/=48105) andalso UniteStatus#unite_status.lv<Apply_level-> %等级检测
			{ok, BinData} = pt_481:write(48100, [2]),
    		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		true->
			%%不改变状态，返回值为ok，改变状态，返回{ok, NewPlayerStatus}
			case Cmd of
				48101->lib_peach:execute_48101(UniteStatus);
				48102->lib_peach:execute_48102(UniteStatus);
				48103->lib_peach:execute_48103(UniteStatus,Params);
				48104->
					if
						SceneId =:= UniteStatus#unite_status.scene->%限制场景
							lib_peach:execute_48104(UniteStatus#unite_status.id);
						true->
							ok
					end;
				48105->lib_peach:execute_48105(UniteStatus);
				48109->
					if
						SceneId =:= UniteStatus#unite_status.scene->%限制场景
							lib_peach:execute_48109(UniteStatus);
						true->
							ok
					end;
				_ -> ok
			end
	end.


%%
%% Local Functions
%%

