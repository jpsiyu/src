%%------------------------------------------------------------------------------
%% @Module  : mod_activity_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2013.3.5
%% @Description: 活动副本服务
%%------------------------------------------------------------------------------


-module(mod_activity_dungeon).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-export([handle_info/2]).


%% --------------------------------- 公共函数 ----------------------------------

%% 得到积分.
handle_info({'activity_dun_get_score', PlayerId}, State) ->
	lib_activity_dungeon:get_score(PlayerId),
	{noreply, State}.
