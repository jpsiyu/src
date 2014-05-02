%%%---------------------------------------
%%% @Module  : data_task_zyl_lv
%%% @Author  : hekai
%%% @Created : 2012.07.31
%%% @Description:  诛妖令任务-颜色对应任务id
%%%---------------------------------------

-module(data_task_zyl_lv).
-export([get_ids/1]).

get_ids(Level) ->
	private_get_task(util:floor(Level/10)*10).

private_get_task(30) ->
	[[1,800010],[2,800020],[3,800030],[4,800040]];

private_get_task(40) ->
	[[1,800050],[2,800060],[3,800070],[4,800080]];

private_get_task(50) ->
	[[1,800090],[2,800100],[3,800110],[4,800120]];

private_get_task(60) ->
	[[1,800130],[2,800140],[3,800150],[4,800160]];

private_get_task(70) ->
	[[1,800170],[2,800180],[3,800190],[4,800200]];

private_get_task(80) ->
	[[1,800210],[2,800220],[3,800230],[4,800240]];

private_get_task(_) ->
	[].

