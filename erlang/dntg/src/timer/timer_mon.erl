%% ---------------------------------------------------------
%% Author:  xyao
%% Email:   jiexiaowen@gmail.com
%% Created: 2012-4-26
%% Description: TODO: 场景移动
%% --------------------------------------------------------
-module(timer_mon).
-compile(export_all).
-include("scene.hrl").

%% -----------------------------------------------------------------
%% @desc     启动回调函数，用来初始化资源。
%% @param
%% @return  {ok, State}      : 启动正常
%%           {ignore, Reason}: 启动异常，本模块将被忽略不执行
%%           {stop, Reason}  : 启动异常，需要停止所有后台定时模块
%% -----------------------------------------------------------------
init() ->
    {ok, ?MODULE}.

%% -----------------------------------------------------------------
%% @desc     服务回调函数，用来执行业务操作。
%% @param    State          : 初始化或者上一次服务返回的状态
%% @return  {ok, NewState}  : 服务正常，返回新状态
%%           {ignore, Reason}: 服务异常，本模块以后将被忽略不执行，模块的terminate函数将被回调
%%           {stop, Reason}  : 服务异常，需要停止所有后台定时模块，所有模块的terminate函数将被回调
%% -----------------------------------------------------------------
handle(State) ->
    List = mod_scene:get_node_scene(), 
    case List =:= [] of
        true ->
            skip;
        false ->
            F = fun(Id) ->
                    Alist= get_aid_list(Id),
                    Len = length(Alist),
                    %% 移动数量
                    case Id =:= 450 of
                        true ->
                            Num = 60;
                        false ->
                            Num = 10
                    end,
                    case Len > Num of
                        true ->
                            Rand = util:rand(1, Len - Num),
                            Alist1 = lists:sublist(Alist, Rand, Num),
                            [ Aid ! {'auto_move'} || Aid <- Alist1];
                        false ->
                             skip
                    end
            end,
            [F(Id) || Id <- List]
    end,
    {ok, State}.

%% -----------------------------------------------------------------
%% @desc     停止回调函数，用来销毁资源。
%% @param    Reason        : 停止原因
%% @param    State         : 初始化或者上一次服务返回的状态
%% @return   ok
%% -----------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% 获取怪物
get_aid_list([]) ->
    [];
get_aid_list(Id) ->
    Key = "timer_mon_get_mon" ++ [Id],
    Alist = get(Key),
    case Alist =:= undefined of
        true ->
            case lib_mon:get_scene_mon(Id, [], #ets_mon.aid) of
                [] ->
                    [];
                Alist1 ->
                    Alist2 = rand_the_list(Alist1, [], length(Alist1)),
                    put(Key, Alist2),
                    Alist2
            end;
        false ->
            Alist
    end.

rand_the_list([] , List, _) ->
    List;
rand_the_list(Olist , List, Len) ->
    Rand = util:rand(1, Len),
    New = lists:nth(Rand, Olist),
    rand_the_list(lists:delete(New, Olist), List ++ [New], Len-1).

clear_all_mon(Sid) ->
    Alist= lib_mon:get_scene_mon(Sid, [], #ets_mon.aid),
    [ mod_mon_active:stop(Aid)|| Aid <- Alist].

get_mon_num(Sid) ->
    length(lib_mon:get_scene_mon(Sid, [], #ets_mon.aid)).
