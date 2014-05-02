%%%---------------------------------------
%%% @Module  : data_task_eb_lv
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:28
%%% @Description:  黄榜任务-颜色对应任务id
%%%---------------------------------------
-module(data_task_eb_lv).
-export([get_ids/1]).

get_ids(Level) ->
	private_get_task(util:floor(Level/10)*10).

private_get_task(_) ->
	[].

