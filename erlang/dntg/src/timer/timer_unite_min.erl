%%%-----------------------------------
%%% @Module  : timer_unite_min
%%% @Author  : xhg
%%% @Email   : xuhuguang@jieyou.com
%%% @Created : 2011.10.31
%%% @Description: 后台定时服务框架，每分钟执行一次
%%%-----------------------------------
-module(timer_unite_min).
-include("common.hrl").

-behaviour(gen_fsm).
-export([
        start_link/0
        ,stop/0
    ]
).
-export([init/1, waiting/2, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).

%%=========================================================================
%% 一些定义
%% TODO: 在回调模块列表中增加新模块。
%%=========================================================================

% 回调模块列表
%-define(MODLE_LIST, [timer_turntable, timer_buff, timer_marriage, timer_festival_lamp, timer_vip, timer_sit_party]).
-define(MODLE_LIST, [timer_buff, timer_marriage, timer_festival_lamp, timer_vip, timer_sit_party]).
% 休眠间隔
-define(TIMEOUT, 60*1000).

%%=========================================================================
%% 接口函数
%%=========================================================================

%% 启动服务器
start_link() ->
    ?INFO("Starting [~w]...", [?MODULE]),
    % 启动进程{服务名称，回调模块名称，初始参数，列表选项}。
    % 使用初始参数回调init()方法。
    gen_fsm:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 关闭服务器时回调
stop() ->
    ?INFO("Stoping [~w]...", [?MODULE]),
    ok.

%%=========================================================================
%% 回调函数
%%=========================================================================

init([]) ->
    case do_init(?MODLE_LIST, [], []) of
         {ok, NewModuleList, NewStateList} ->
             {_H, _M, Sec} = erlang:time(),
             if Sec > 0 andalso Sec >= ?TIMEOUT ->
                    Timeout = Sec * 1000 - ?TIMEOUT;
                Sec > 0 andalso Sec < ?TIMEOUT ->
                    Timeout = ?TIMEOUT - Sec * 1000;
                true ->
                    Timeout = 0
             end,
             {ok, waiting, {NewModuleList, NewStateList}, Timeout}; 
          {stop, Reason} ->
             {stop, Reason}
    end.

waiting(timeout, State) ->
    {ModuleList, StateList} = State,
    case do_handle(ModuleList, StateList, [], [], [],[]) of
         {ok, NewModuleList, NewStateList} ->
             {next_state, waiting, {NewModuleList, NewStateList}, ?TIMEOUT};
         {stop, Reason, IgnoreModuleList, _IgnoreStateList} ->
             {TerminateModuleList, TerminateStateList} = filter_module(IgnoreModuleList, ModuleList, StateList),
             do_terminate(TerminateModuleList, TerminateStateList, Reason),
             {stop, Reason};
         Err ->
            util:errlog("timer_unite_min waiting: ~p~n", [Err]),
            {next_state, waiting, {ModuleList, StateList}, ?TIMEOUT}
    end.

handle_event(stop, _StateName, State) ->
    {stop, normal, State}.

handle_sync_event(_Any, _From, StateName, State) ->
    {reply, {error, unhandled}, StateName, State}.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.

handle_info(_Any, StateName, State) ->
    {next_state, StateName, State}.

terminate(_Any, _StateName, _Opts) ->
    ok.


%%=========================================================================
%% 内部函数
%%=========================================================================

do_init([], NewModuleList, NewStateList) ->
    {ok, NewModuleList, NewStateList};
do_init(ModuleList, NewModuleList, NewStateList) ->
    [Module|ModuleLeft] = ModuleList,
    case Module:init() of
        {ok, NewSate} ->
            % 保留该模块，收集该模块状态
            do_init(ModuleLeft, NewModuleList++[Module], NewStateList++[NewSate]);
        {ignore, Reason} ->
            util:errlog("do_init: module is ignored, module name=[~w], reason=[~w]", [Module, Reason]),
            % 删除该模块，不收集该模块状态
            do_init(ModuleLeft, NewModuleList, NewStateList);
        {stop, Reason} ->
            util:errlog("do_init: module is stopped, module name=[~w], reason=[~w]", [Module, Reason]),
            % 初始化失败
            {stop, Reason}
    end.


do_handle([], [], NewModuleList, NewStateList, _IgnoreModuleList, _IgnoreStateList) ->
    {ok, NewModuleList, NewStateList};
do_handle(ModuleList, StateList, NewModuleList, NewStateList, IgnoreModuleList, IgnoreStateList) ->
    [Module|ModuleLeft] = ModuleList,
    [State|StateLeft]   = StateList,
    case catch Module:handle(State) of
        {ok, NewState} ->
            % 保留该模块，收集该模块状态
            do_handle(ModuleLeft, StateLeft, NewModuleList++[Module], NewStateList++[NewState], IgnoreModuleList, IgnoreStateList);
        {ignore, Reason} ->
            util:errlog("do_handle: module is ignored, module name=[~w], reason=[~w]", [Module, Reason]),
            % 回调该模块的terminate方法
            Module:terminate(Reason, State),
            % 删除该模块，不收集该模块状态，加入忽略列表
            do_handle(ModuleLeft, StateLeft, NewModuleList, NewStateList, IgnoreModuleList++[Module], IgnoreStateList++[State]);
        {stop, Reason} ->
            util:errlog("do_handle: module is stopped, module name=[~w], reason=[~w]", [Module, Reason]),
            % 处理失败
            {stop, Reason, IgnoreModuleList, IgnoreStateList};
        Err ->
            util:errlog("timer_unite_min do_handle: ~p~n", [Err]),
            do_handle(ModuleLeft, StateLeft, NewModuleList++[Module], NewStateList++[State], IgnoreModuleList, IgnoreStateList)
    end.


do_terminate([], [], _Reason) ->
    ok;
do_terminate(ModuleList, StateList, Reason) ->
    [Module|ModuleLeft] = ModuleList,
    [State|StateLeft]   = StateList,
    Module:terminate(Reason, State),
    do_terminate(ModuleLeft, StateLeft, Reason).

filter_module([], ModuleList, StateList) ->
    {ModuleList, StateList};
filter_module(IgnoreModuleList, ModuleList, StateList) ->
    [Module|ModuleLeft] = IgnoreModuleList,
    Index = get_elem_index(ModuleList, Module, 0),
    State = lists:nth(Index, StateList),
    filter_module(ModuleLeft, lists:delete(Module, ModuleList),lists:delete(State, StateList)).

get_elem_index([], _Elem, _Index) ->
    0;
get_elem_index(List, Elem, Index) ->
    [E|ListLeft] = List,
    if  E =:= Elem ->
            Index+1;
        true ->
            get_elem_index(ListLeft, Elem, Index+1)
    end.
