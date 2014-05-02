%%%---------------------------------------
%%% @Module  : data_mon_ai_hp
%%% @Description:  怪物AI
%%%---------------------------------------
-module(data_mon_ai_hp).
-compile(export_all).


get(30101,0.1)->
    [{ac_skill,[400005,1],0},{remove,1000,0}];

get(30103,0.1)->
    [{ac_skill,[400005,1],0},{remove,1000,0}];
get(_,_)->
[].
get(30101) ->
            [0.1];
get(30103) ->
            [0.1];
get(_)->
[].


