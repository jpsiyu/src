%% Author: zengzhaoyuan
%% Created: 2012-5-22
%% Description: TODO: Add description to pp_arena_new
-module(pp_god).
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
	Min_lv = data_god:get(min_lv),
	Min_power = data_god:get(min_power),
	{Mod,Status,Config_end_time} = mod_god_state:get_mod_and_status(),
	if
		Cmd =:= 48501->
			lib_god:execute_48501(UniteStatus,Mod,Status,Config_end_time);
		Cmd =:= 48503->
			lib_god:execute_48503(UniteStatus);
		Cmd =:= 48514->
			lib_god:execute_48514(UniteStatus,Params);
		Cmd =:= 48516->
			lib_god:execute_48516(UniteStatus,Params);
		Cmd =:= 48517->
			lib_god:execute_48517(UniteStatus,Params);
		true->
			Lv = UniteStatus#unite_status.lv,
			case lib_player:get_player_info(UniteStatus#unite_status.id,combat_power) of
				Result when is_integer(Result)->
					Power = Result;
				_-> Power = 0
			end,
			if
				Min_lv>Lv-> %%等级不够
					{ok, BinData} = pt_485:write(48500, [2]),
    				lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				Cmd =:= 48512-> %%只过滤等级的协议
					lib_god:execute_48512(UniteStatus,Params);
				Min_power>Power-> %%战力不够
					{ok, BinData} = pt_485:write(48500, [3]),
    				lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				Cmd =:= 48511-> %%只过滤等级的协议
					lib_god:execute_48511(UniteStatus);
				Mod<1 orelse Mod>4->
					{ok, BinData} = pt_485:write(48500, [1]),
    				lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				Status/=1-> %%未开始或已结束
					{ok, BinData} = pt_485:write(48500, [1]),
    				lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				true->
					%%不改变状态，返回值为ok，改变状态，返回{ok, NewPlayerStatus}
					case Cmd of
						48502->lib_god:execute_48502(UniteStatus,Power);
						48506->lib_god:execute_48506(UniteStatus,Params,Mod);
						48515->lib_god:execute_48515(UniteStatus,Mod);
						_ -> ok
					end
			end
	end.

%%
%% Local Functions
%%

