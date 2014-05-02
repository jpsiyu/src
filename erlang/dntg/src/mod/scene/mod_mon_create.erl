%%%------------------------------------
%%% @Module  : mod_mon_create
%%% @Author  : zzm
%%% @Created : 2014.03.14
%%% @Description: 生成所有怪物进程
%%%------------------------------------
-module(mod_mon_create).
-behaviour(gen_server).
-export([
        start_link/0, 
        create_mon/8,
        create_mon_cast/8
    ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("scene.hrl").
-include("dungeon.hrl").
-record(state, {auto_id}).

%% @spec create_mon(MonId, Scene, X, Y, Type, CopyId, BroadCast, Arg) -> MonAutoId
%% 同步生成怪物
%% @param MonId 怪物资源ID
%% @param Scene 场景ID
%% @param X 坐标
%% @param X 坐标
%% @param Type 怪物战斗类型（0被动，1主动）
%% @param CopyId 房间号ID 为0时，普通房间，非0值切换房间。值相同，在同一个房间。
%% @param BroadCast:生成的时候是否广播(0:不广播; 1:广播)
%% @param Arg:可变参数列表[Tuple1, Tuple2...]
%%             Tuple1 = tuple(), {auto_lv, V} | {group, V} | {cruise_info, V} | 
%%                               {owner_id, OwnerId} | {mon_name, MonName} |  {color, MonColor} | {skip, V} | 
%%                               {crack, V}
%%@return MonAutoId 怪物自增ID，每个怪物唯一
%% @end
create_mon(MonId, Scene, X, Y, Type, CopyId, BroadCast, Arg) -> 
    gen_server:call(?MODULE, {create, [MonId, Scene, X, Y, Type, CopyId, BroadCast, Arg]}).

%% @spec create_mon(MonId, Scene, X, Y, Type, CopyId, BroadCast, Arg) -> ok.
%% 异步创建怪物
%% @end
create_mon_cast(MonId, Scene, X, Y, Type, CopyId, BroadCast, Arg) -> 
    gen_server:cast(?MODULE, {create, [MonId, Scene, X, Y, Type, CopyId, BroadCast, Arg]}),
    ok.

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    State = #state{auto_id = 1},
    {ok, State}.

%% 生成怪物(带可变参数)
%%@param MonId 怪物资源ID
%%@param Scene 场景ID
%%@param X 坐标
%%@param X 坐标
%%@param Type 怪物战斗类型（0被动，1主动）
%%@param CopyId 房间号ID 为0时，普通房间，非0值切换房间。值相同，在同一个房间。
%%@param BroadCast:生成的时候是否广播(0:不广播; 1:广播)
%%@param Arg:可变参数列表[Tuple1, Tuple2...]
%%            Tuple1 = tuple(), {auto_lv, V} | {group, V} | {cruise_info, V} | 
%%                              {owner_id, OwnerId} | {mon_name, MonName} |  {color, MonColor} | {skip, V} | 
%%                              {crack, V}
%%@return MonAutoId 怪物自增ID，每个怪物唯一
handle_call({create, [MonId, Scene, X, Y, Type, Sid, BroadCast, Arg]} , _FROM, State) ->
    mod_mon_active:start([State#state.auto_id, MonId, Scene, X, Y, Type, Sid, BroadCast, Arg]),
    NewState = State#state{auto_id = State#state.auto_id + 1},
    {reply, State#state.auto_id, NewState};

handle_call(_R , _FROM, State) ->
    {reply, ok, State}.

%% 创建怪物
handle_cast({create, [MonId, Scene, X, Y, Type, Sid, BroadCast, Arg]}, State) ->
    mod_mon_active:start([State#state.auto_id, MonId, Scene, X, Y, Type, Sid, BroadCast, Arg]),
    NewState = State#state{auto_id = State#state.auto_id + 1},
    {noreply, NewState};

handle_cast(_R , State) ->
    {noreply, State}.

handle_info({'EXIT', _From, normal}, State)->
    {noreply, State};
handle_info({'EXIT', From, Reason}, State)->
    %% 怪物活动进程报错
    util:errlog("mod_mon_create receive mod_mon_active(pid=~p) error info. reason: ~p~n", [From, Reason]),
    {noreply, State};

handle_info(_Reason, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra)->
    {ok, State}.
