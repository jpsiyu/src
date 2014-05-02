%%%--------------------------------------
%%% @Module  : lib_switch
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.6.24
%%% @Description: 功能开关
%%%--------------------------------------

-module(lib_switch).
-export([
	get_switch/1		%% 获取模块开关
]).

%% 获取功能的开关配置
%% 返回：true功能开，false功能关
get_switch(ModuleName) ->
	SwitchConfig = [
		{physical, true},					%% 体力系统 
		{target, true}, 					%% 西游目标
		{designation, true},			    %% 称号系统
		{fame, true},						%% 名人堂
		{active, true},						%% 活跃度
		{butterfly, true},					%% 蝴蝶活动
		{famelimit, true},					%% 限时名人堂（活动）
		{fish, true}						%% 全民垂钓
	],
	private_get_switch(ModuleName, SwitchConfig).

%% 从配置中获取配置的模块开关参数
private_get_switch(_ModuleName, []) ->
	true;
private_get_switch(ModuleName, [{ConfModule, ConfSwitch} | T]) ->
	case ModuleName =:= ConfModule of
		true ->
			case ConfSwitch =:= false of
				true ->
					false;
				_ ->
					true
			end;
		_ ->
			private_get_switch(ModuleName, T)
	end.
