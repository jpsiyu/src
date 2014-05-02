%%%-----------------------------------
%%% @Module  : data_chat_forbid_text
%%% @Author  : hekai
%%% @Created : 2012.10.23
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_chat_forbid_text).
-compile(export_all).

get_forbid_type(Type) ->
	if
		Type=:=1 ->
			"被gm或指导员禁言!禁言时长为~p分钟";
		Type=:=2 ->
			"违反规则,40级下与非好友私聊次数超过30条!禁言时长为~p分钟";
		Type=:=3 ->
			"违反规则,40级下私聊好友超过20个!禁言时长为~p分钟";
		Type=:=4 ->
			"被举报超过10次!禁言时长为~p分钟";
		Type=:=5 ->
			"违反规则,42级下世界发言次数超过限制!禁言时长为~p分钟"	
	end.

get_release_type(Type) ->
	if
		Type=:=1 ->
			"gm或指导员手动解除禁言!";
		Type=:=2 ->
			"自动解除禁言!"		
	end.

is_admin_forbid(Type) ->
	if
		Type=:=1 ->
			"gm或新手指导员";
		true ->
			"Auto"
	end.

