%%%------------------------------------
%%% @Module  : mod_mon_agent
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2012.05.21
%%% @Description: 怪物管理
%%%------------------------------------
-module(mod_mon_agent). 
-behaviour(gen_server).
-export([
            start_link/1,
            start_mod_mon_agent/1,
            close_scene/1,
            apply_call/4,
            apply_cast/4
        ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("server.hrl").
-include("scene.hrl").

%% 通过场景调用函数 - call
apply_call(Sid, Module, Method, Args) ->
    case get_scene_mon_pid(Sid) of
        undefined ->
            skip;
        Pid ->
            case catch gen:call(Pid, '$gen_call', {'apply_call', Module, Method, Args}) of
                {ok, Res} ->
                    Res;
                _ ->
                    skip
            end
    end.

%% 通过场景调用函数 - cast
apply_cast(Sid, Module, Method, Args) ->
    case get_scene_mon_pid(Sid) of
        undefined ->
            skip;
        Pid ->
            gen_server:cast(Pid, {'apply_cast', Module, Method, Args})
    end.

%%关闭指定的场景
close_scene(Sid) ->
    gen_server:cast(misc:whereis_name(local, misc:mon_process_name(Sid)), {'close_scene'}).

start_link(Scene) ->
    gen_server:start_link(?MODULE, [Scene], []).

%% Num:场景个数
%% WorkerId:进行标示
%% Scene:场景相关内容
init([Scene]) ->
    process_flag(trap_exit, true),
    {ok, Scene}.

%% 统一模块+过程调用(cast)
handle_cast({'apply_cast', Module, Method, Args} , State) ->
    case catch apply(Module, Method, Args) of
         {'EXIT', Info} ->
             util:errlog("mod_mon_agent_apply_cast error: Module=~p, Method=~p, Reason=~p",[Module, Method, Info]),
             error;
         DataRet -> DataRet
    end,
    {noreply, State};

%% 关闭进程
handle_cast({'close_scene'} , State) ->
    {stop, normal, State};

%% 默认匹配
handle_cast(_Event, State) ->
    {noreply, State}.

%% 统一模块+过程调用(call)
handle_call({'apply_call', Module, Method, Args}, _From, State) ->
    Reply  = case catch apply(Module, Method, Args) of
         {'EXIT', Info} ->
             util:errlog("mod_mon_agent_apply_call error: Module=~p, Method=~p, Reason=~p",[Module, Method, Info]),
             error;
         DataRet -> DataRet
    end,
    {reply, Reply, State};

%% 默认匹配
handle_call(_Event, _From, State) ->
    {reply, ok, State}.

%% 默认匹配
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_R, State) ->
    misc:unregister(local, misc:mon_process_name(State)),
    {ok, State}.

code_change(_OldVsn, State, _Extra)->
    {ok, State}.

%% ================== 私有函数 =================

%% 启动场景模块
start_mod_mon_agent(Id) ->
    case start_link(Id) of
        {ok, NewMonPid} ->
            MonProcessName = misc:mon_process_name(Id),
            case misc:whereis_name(local, MonProcessName) of
                Pid when is_pid(Pid) ->
                    Pid;
                _ ->
                    misc:register(local, MonProcessName, NewMonPid),
                    NewMonPid
            end;
        R ->
            util:errlog("mod_mon_agent:id~p - ~p~n", [Id, R]),
            undefined
    end.

%% 动态加载某个场景 Lv : 场景等级
get_scene_mon_pid(Id) ->
    case get({get_scene_mon_pid, Id}) of
        undefined ->
            MonProcessName = misc:mon_process_name(Id),
            SceneMonPid = case misc:whereis_name(local, MonProcessName) of
                Pid when is_pid(Pid) ->
                    case misc:is_process_alive(Pid) of
                        true ->
                            MonProcessName = misc:mon_process_name(Id),
                            misc:whereis_name(local, MonProcessName);
                        false ->
                            misc:unregister(local, MonProcessName),
                            exit(Pid, kill),
                            start_mod_mon_agent(Id)
                    end;
                _ ->
                    start_mod_mon_agent(Id)
            end,
            case is_pid(SceneMonPid) of
                true ->
                    put({get_scene_mon_pid, Id}, SceneMonPid);
                false ->
                    skip
            end,
            SceneMonPid;
        SceneMonPid ->
            SceneMonPid
    end.
