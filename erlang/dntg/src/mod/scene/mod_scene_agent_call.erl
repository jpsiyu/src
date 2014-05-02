%%%------------------------------------
%%% @Module  : mod_scene_agent_call
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2012.05.18
%%% @Description: 场景管理call处理
%%%------------------------------------
-module(mod_scene_agent_call).
-export([handle_call/3]).
-include("scene.hrl").
-include("common.hrl").

%%显示本场景人员
handle_call({'scene_num'} , _FROM, State) ->
    Num = length(lib_scene_agent:get_scene_user()),
    {reply, Num, State};

%% 统一模块+过程调用(call)
handle_call({'apply_call', Module, Method, Args}, _From, State) ->
    {reply, apply(Module, Method, Args), State};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_server:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.
