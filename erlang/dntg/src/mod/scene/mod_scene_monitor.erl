%%------------------------------------------------------------------------------
%% @Module  : mod_scene_monitor
%% @Author  : jiexiaowen
%% @Email   : 13931430@qq.com
%% @Created : 2012.7.24
%% @Description: 场景监控
%%------------------------------------------------------------------------------
-module(mod_scene_monitor).
-behaviour(gen_server).
-export([start_link/1, init/1, monitor_area/0, 
		 handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-compile(export_all).

-include("scene.hrl").

start_link(SceneId) ->
    gen_server:start_link(?MODULE, [SceneId], []).

init([SceneId]) ->
	erlang:send_after(60000, self(), 'monitor'),
    {ok, SceneId}.

%% 默认匹配
handle_call(Event, _From, State) ->
    catch util:errlog("mod_scene_monitor:handle_call not match: ~p", [Event]),
    {reply, ok, State}.

%% 默认匹配
handle_cast(Event, State) ->
    catch util:errlog("mod_scene_monitor:handle_cast not match: ~p", [Event]),
    {noreply, State}.

%% 监控玩家是否离开
handle_info('monitor', State) ->
	%30秒检测一次.
	erlang:send_after(30000, self(), 'monitor'),

    %% 清除场景残余数据
    case data_scene:get(State) of
        [] ->
            skip;
        Scene ->
            case Scene#ets_scene.type =:= ?SCENE_TYPE_CLUSTERS of
                true ->
                    skip;
                false ->
                    %% 监控场景9宫格格数据
                    %monitor_scene_area(State), 

                    %% 怪物移动处理
                    handle(State),
                    clear_dirty_data(State)
            end
    end,

	{noreply, State};

%% 默认匹配
handle_info(Info, State) ->
    catch util:errlog("mod_scene_monitor:handle_info not match: ~p", [Info]),
    {noreply, State}.

%% 服务器停止.
terminate(_R, _State) ->
    ok.

code_change(_OldVsn, State, _Extra)->
    {ok, State}.

%% 处理怪物移动
handle(Id) ->
    Alist= get_aid_list(Id),
    Len = length(Alist),
    %% 移动数量
    Num = if
        Id =:= 450 ->
            30;
        Id =:= 451 ->
            30;
        Id =:= 240 ->
            20;
        true ->
            0
    end,
    case Len > Num of
        true ->
            Rand = util:rand(1, Len - Num),
            Alist1 = lists:sublist(Alist, Rand, Num),
            F = fun(Aid) -> 
                    timer:sleep(500),
                    Aid ! {'auto_move'}
            end,
            spawn(fun() -> lists:map(F, Alist1) end),
            ok;
            %[ Aid ! {'auto_move'} || Aid <- Alist1];
        false ->
            skip
    end.

%% 获取怪物
get_aid_list([]) ->
    [];
get_aid_list(Id) ->
    Key = "timer_mon_get_mon" ++ [Id],
    Alist = get(Key),
    case Alist =:= undefined of
        true ->
            case lib_mon:get_scene_mon(Id, [], #ets_mon.aid) of
                skip ->
                    [];
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
    Rand  = util:rand(1, Len),
    New = lists:nth(Rand, Olist),
    rand_the_list(lists:delete(New, Olist), List ++ [New], Len-1).

%% 清除场景所有怪物
clear_all_mon(Sid) ->
    Alist= lib_mon:get_scene_mon(Sid, [], #ets_mon.aid),
    [ mod_mon_active:stop(Aid)|| Aid <- Alist].

%% 获取场景怪物数据
get_mon_num(Sid) ->
    length(lib_mon:get_scene_mon(Sid, [], #ets_mon.id)).


%% 清除场景残余数据
%% 1小时一次
clear_dirty_data(Id) ->
    N = case get(clear_dirty_data) of
        undefined ->
            1;
        _N ->
            case  _N > 10000000 of
                true ->
                    1;
                false ->
                    _N
            end
    end,
    case N rem 72 =:= 0 of
        true ->
            mod_scene_agent:get_scene_pid(Id) ! 'monitor';
        false ->
            skip
    end,
    put(clear_dirty_data, N + 1).

%% 监控场景数据
monitor_scene_area(Id) ->
    N = case get(monitor_scene_area) of
        undefined ->
            1;
        _N ->
            case  _N > 10000000 of
                true ->
                    1;
                false ->
                    _N
            end
    end,
    case N rem 185 =:= 0 of
        true ->
            mod_scene_agent:apply_cast(Id, mod_scene_monitor, monitor_area, []),
            ok;
        false ->
            skip
    end,
    case N rem 182 =:= 0 of
        true ->
            mod_mon_agent:apply_cast(Id, mod_scene_monitor, monitor_area, []),
            ok;
        false ->
            skip
    end,
    put(monitor_scene_area, N + 1).

%% 监控9宫格数据
monitor_area() ->
    Data = get(),
    F = fun({Key, _}) ->
        case Key of
            {_, _, Cid} ->
                case is_pid(Cid) andalso misc:is_process_alive(Cid) =:= false of
                    true ->
                        erase(Key);
                    false ->
                        skip
                end;
            {_, Cid} ->
                case is_pid(Cid) andalso misc:is_process_alive(Cid) =:= false of
                    true ->
                        erase(Key);
                    false ->
                        skip
                end;
            _ ->
                skip
        end
    end,
    lists:foreach(F, Data).
