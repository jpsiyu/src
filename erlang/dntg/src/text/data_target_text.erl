%%%--------------------------------------
%%% @Module  : data_target_text
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.8
%%% @Description: 目标中文语言
%%%--------------------------------------

-module(data_target_text).
-export([get_msg/1]).

get_msg({DesignType, MsgType}) ->
	case {DesignType, MsgType} of
		{1, 1} ->
			%% 炫耀类：全服第一个获得此称号，则系统传闻：宇宙初开，先天无极！【玩家名】获得称号【称号名】
			<<"宇宙初开，先天无极！~p 获得称号 ~p">>;
		{1, 2} ->
			%% 炫耀类：取代前一个玩家获得此称号，则系统传闻：天地变色，众仙震惊！【玩家名】取代【玩家名】，获得称号【称号名】
			<<"天地变色，众仙震惊！~p 取代 ~p，获得称号 ~p">>;
		{2, 1} ->
			%% 特殊类：全服第一个获得此称号，则系统传闻：宇宙初开，先天无极！【玩家名】获得称号【称号名】
			<<"宇宙初开，先天无极！ ~p 获得称号 ~p">>;
		{2, 2} ->
			%% 特殊类：取代另一玩家获得此称号，则系统传闻：风云激荡，霞光满天！【玩家名】取代【玩家名】，获得称号【称号名】！
			<<"风云激荡，霞光满天！ ~p 取代 ~p，获得称号 ~p">>;
		{3, 1} ->
			%% 彩色类：当玩家获得此称号时，则系统提示：恭喜【玩家名】获得称号【称号名】
			<<"恭喜 ~p 获得称号 ~p">>;
		_ ->
			[]
	end.