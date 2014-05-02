%%%---------------------------------------------
%%% @Module  : test_dict
%%% @Author  : xyao
%%% @Created : 2011.12.24
%%% @Description: 进程字典性能测试
%%%---------------------------------------------
-module(test_dict).
-compile(export_all).
-include("scene.hrl").
-define(NUM, 1000).   %% 数据量
-define(TIME, 2000).  %% 循环次数

-define(ETS_SCENE_USER(Id), list_to_atom(lists:concat([ets_scene_user_, Id]))). %% 场景

start() ->
    ets:new(?ETS_SCENE_USER(0), [{keypos,#ets_scene_user.id}, named_table, public, set]),
    C1 = timer:tc(?MODULE, create_ets, [?NUM]),
    io:format("create_ets:~p ets data,time:~p~n", [?NUM, C1]),
    C2 = timer:tc(?MODULE, create_dict, [?NUM]),
    io:format("create_dict:~p ets data,time:~p~n", [?NUM, C2]),
    D = dict:new(),
    C3 = timer:tc(?MODULE, create_dict2, [?NUM, D]),
    io:format("create_dict2:~p ets data,time:~p~n", [?NUM, C3]),

    D1 = timer:tc(?MODULE, get_ets, [?NUM]),
    io:format("get_ets:~p ets data,time:~p~n", [?NUM, D1]),
    D2 = timer:tc(?MODULE, get_dict, [?NUM]),
    io:format("get_dict:~p ets data,time:~p~n", [?NUM, D2]),
    List = ets:tab2list(?ETS_SCENE_USER(0)),
    D3 = timer:tc(?MODULE, get_list, [?NUM, List]),
    io:format("getlist:~p ets data,time:~p~n", [?NUM, D3]),
    DD = get(key),
    D4 = timer:tc(?MODULE, get_dict2, [?NUM, DD]),
    io:format("get_dict2:~p ets data,time:~p~n", [?NUM, D4]),

    T1 = timer:tc(?MODULE, loop, [test_ets, ?TIME]),
    io:format("test_ets:~p ets data,loop ~p,time:~p~n", [?NUM, ?TIME, T1]),
    T2 = timer:tc(?MODULE, loop, [test_ets2, ?TIME]),
    io:format("test_ets2:~p ets data,loop ~p,time:~p~n", [?NUM, ?TIME, T2]),
    T3 = timer:tc(?MODULE, loop, [test_dict, ?TIME]),
    io:format("test_dict:~p ets data,loop ~p,time:~p~n", [?NUM, ?TIME, T3]),
    ok.

create_ets(0) ->
    ok;
create_ets(N) ->
    Data = #ets_scene_user{id = N},
    ets:insert(?ETS_SCENE_USER(0), Data),
    create_ets(N-1).

create_dict(0) ->
    ok;
create_dict(N) ->
    Data = #ets_scene_user{id = N},
    put({x, N}, Data),
    create_dict(N-1).

create_dict2(0, D) ->
    put(key, D),
    ok;
create_dict2(N, D) ->
    Data = #ets_scene_user{id = N},
    create_dict2(N-1, dict:store({x, N}, Data, D)).

get_ets(0) ->
    ok;
get_ets(N) ->
    ets:lookup(?ETS_SCENE_USER(0), N),
    get_ets(N-1).

get_dict(0) ->
    ok;
get_dict(N) ->
    _F = get({x, N}),
    get_dict(N-1).

get_list(0, _) ->
    ok;
get_list(N, List) ->
    lists:keyfind(N, #ets_scene_user.id, List),
    get_list(N-1, List).

get_dict2(0, _) ->
    ok;
get_dict2(N, D) ->
    _F = dict:fetch({x, N}, D),
    get_dict2(N-1, D).

test_ets() ->
    Q = 0,
    X2 = 0,
    Y2 = 0,
    AllUser = ets:match(?ETS_SCENE_USER(Q), #ets_scene_user{id = '$1',x = '$2', y='$3', _='_'}),
    F = fun([_Id, X, Y]) ->
        case lib_scene_calc:is_area_scene(X, Y, X2, Y2) of
            true ->
                ok;
            false ->
                skip
        end
    end,
    [F([Id, X, Y]) || [Id, X, Y] <- AllUser].

test_ets2() ->
    Q = 0,
    CopyId = 0,
    X2 = 0,
    Y2 = 0,
    AllUser =   ets:tab2list(?ETS_SCENE_USER(Q)),
    F = fun([_Id, X, Y]) ->
        case lib_scene_calc:is_area_scene(X, Y, X2, Y2) of
            true ->
                ok;
            false ->
                skip
        end
    end,
    [F([User#ets_scene_user.id, User#ets_scene_user.x, User#ets_scene_user.y]) || User <- AllUser, User#ets_scene_user.copy_id =:= CopyId].

test_dict() ->
    CopyId = 0,
    X2 = 0,
    Y2 = 0,
    AllUser = get(),
    F = fun([_Id, X, Y]) ->
        case lib_scene_calc:is_area_scene(X, Y, X2, Y2) of
            true ->
                ok;
            false ->
                skip
        end
    end,
    [F([User#ets_scene_user.id, User#ets_scene_user.x, User#ets_scene_user.y]) || {_, User} <- AllUser, User#ets_scene_user.copy_id =:= CopyId].


loop(_, 0) ->
    ok;
loop(F, N) ->
    apply(?MODULE, F, []),
    loop(F, N-1).


