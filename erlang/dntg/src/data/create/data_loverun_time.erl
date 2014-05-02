%%%---------------------------------------
%%%--------------------------------------
%%% @Module  : data_loverun_time
%%% @Author  : guoxi
%%% @Created : 2012.7.24
%%% @Description: 爱情长跑
%%%--------------------------------------
-module(data_loverun_time).
-compile(export_all).

get_loverun_time(Type) ->
	case Type of
		activity_date -> [{2013, 03, 21}, {2013, 03, 28}];
% [开始时间，结束时间]
		activity_time -> [[{15, 0}, {15, 30}], [{22, 00}, {22, 30}]];
		_ -> skip
    end.

