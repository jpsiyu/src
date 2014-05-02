%% Author: zengzhaoyuan
%% Created: 2012-5-22
%% Description: TODO: Add description to pp_arena_new
-module(pp_kf_1v1).
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
	case mod_disperse:get_clusters_node() of
		none->ok;
		_->%%跨服节点正常运行着
			Apply_level = data_kf_1v1:get_bd_1v1_config(min_lv),
			Bd_1v1_status = mod_kf_1v1_state:get_status(),
			if
				Cmd =:= 48315->
					lib_kf_1v1:execute_48315(UniteStatus);
				Cmd =:= 48302->
					if
						Bd_1v1_status =:= 0 orelse Bd_1v1_status =:= 4->
							{ok, BinData} = pt_483:write(48300, [1]),
		    				lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
						true->
							if
								UniteStatus#unite_status.lv<Apply_level->
									{ok, BinData} = pt_483:write(48300, [2]),
		    						lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
								true->
									lib_kf_1v1:execute_48302(UniteStatus)
							end
					end;
				(Cmd/=48301 andalso Cmd/=48303 andalso Cmd/=48305 andalso Cmd/=48306 andalso Cmd/=48314) 
				  andalso (Bd_1v1_status =:= 0 orelse Bd_1v1_status =:= 4)-> %非进行中
					{ok, BinData} = pt_483:write(48300, [1]),
		    		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				(Cmd/=48301 andalso Cmd/=48303 andalso Cmd/=48305 andalso Cmd/=48306 andalso Cmd/=48314) 
				  andalso UniteStatus#unite_status.lv<Apply_level-> %等级检测
					{ok, BinData} = pt_483:write(48300, [2]),
		    		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				true->
					%%不改变状态，返回值为ok，改变状态，返回{ok, NewPlayerStatus}
					case Cmd of
						48301->lib_kf_1v1:execute_48301(UniteStatus);
						48303->lib_kf_1v1:execute_48303(UniteStatus);
						48305->lib_kf_1v1:execute_48305(UniteStatus);
						48306->lib_kf_1v1:execute_48306(UniteStatus);
		 				48310->
							Scene_id1 = data_kf_1v1:get_bd_1v1_config(scene_id1),
							if
								UniteStatus#unite_status.scene =:= Scene_id1->
									lib_kf_1v1:execute_48310(UniteStatus);
								true->
									ok
							end;
						48312->lib_kf_1v1:execute_48312(UniteStatus);
						48313->lib_kf_1v1:execute_48313(UniteStatus,Params);
						48314->lib_kf_1v1:execute_48314(UniteStatus);
						_ -> ok
					end
			end	
	end.

%%
%% Local Functions
%%

