%%%------------------------------------
%%% @Module  : mod_scene
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.07.15
%%% @Description: 场景管理
%%%------------------------------------
-module(mod_scene).
-behaviour(gen_server).
-export([start_link/0, 
         copy_scene/2,          %% 加载场景动态信息（怪物）
         copy_scene/3,          %% 加载场景动态信息（怪物）
         copy_dungeon_scene/4,  %% 加载副本场景动态信息（怪物）
         clear_scene/2,         %% 清除场景动态信息（怪物）  
         load_scene/1,          %% 场景初始化，加载场景静态信息
         add_node_scene/1,      %% 本节点生成的场景
         get_node_scene/0,      %% 获取节点场景
         del_node_scene/1       %% 删除本节点场景
        ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("common.hrl").
-include("scene.hrl").
-include("dungeon.hrl").

-record(state, {auto_sid, scene_list}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 本节点生成的场景
add_node_scene(Sid) ->
    gen_server:cast(?MODULE, {add_node_scene, Sid}).

%% 删除本节点的场景
del_node_scene(Sid) ->
    gen_server:cast(?MODULE, {del_node_scene, Sid}).

%% 获取节点场景
get_node_scene() ->
    gen_server:call(?MODULE, get_node_scene).

%% 加载场景动态信息（怪物）
copy_scene(SceneId, CopyId) ->
    copy_scene(SceneId, CopyId, 0).

copy_scene(SceneId, CopyId, Lv) ->
    case data_scene:get(SceneId) of
        [] ->
            ok;
        S ->
            case S#ets_scene.type of            
                ?SCENE_TYPE_DUNGEON -> %% 副本场景怪物由副本进程创建
                    skip;
                ?SCENE_TYPE_TOWER -> %% 装备副本场景怪物由副本进程创建
                    skip;                    
                _ -> 
                    load_mon(S#ets_scene.mon, SceneId, CopyId, Lv, 0),
                    ok
            end
    end.
    
%% 加载副本场景动态信息（怪物）
%% @spec copy_dungeon_scene(SceneId, CopyId, Lv, DropNum) -> ok
%% DropNum = 1.2.3... 改场景的怪物掉落计算次数
%% @end
copy_dungeon_scene(SceneId, CopyId, Lv, DropNum) ->
    case data_scene:get(SceneId) of
        [] ->
            ok;
        S ->
            load_mon(S#ets_scene.mon, SceneId, CopyId, Lv, DropNum),
            ok
    end.
    
%% 清除场景动态信息（怪物）
clear_scene(SceneId, CopyId) ->
    mod_mon_agent:apply_cast(SceneId, lib_mon_agent, clear_scene_mon, [CopyId, 0]),
    mod_mon_agent:apply_cast(SceneId, lib_mon_agent, del_all_area, [CopyId]),
    %lib_mon:clear_scene_mon(SceneId, CopyId, 0),    %% 清除怪物
    %lib_mon:del_all_area(SceneId, CopyId),
    lib_scene:del_all_area(SceneId, CopyId),
    ok.

init([]) ->
    process_flag(trap_exit, true),
	F = fun(Id) ->
            mod_scene_mark:start_link(Id),
            load_scene(Id),
            timer:sleep(1000)
    end,
    spawn(fun()-> lists:map(F, data_scene:get_id_list()) end),
    %lists:map(fun load_scene/1, data_scene:get_id_list()),
    State = #state{auto_sid = 1000000, scene_list=[]},
    {ok, State}.

%% 获取节点场景
handle_call(get_node_scene, _From, State) ->
    {reply, State#state.scene_list, State};

handle_call(_Request, _From, State) ->
    {reply, State, State}.

%% 本节点生成的场景
handle_cast({add_node_scene, Sid}, State) ->
    List = State#state.scene_list ++ [Sid],
    {noreply, State#state{scene_list = List}};

%% 删除本节点的场景
handle_cast({del_node_scene, Sid}, State) ->
    List = State#state.scene_list -- [Sid],
    {noreply, State#state{scene_list = List}};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% 场景初始化，加载场景静态信息
load_scene(SceneId) ->
    S = data_scene:get(SceneId),
    ets:insert(?ETS_SCENE, S#ets_scene{mon=[], npc=[], mask=[], sid = SceneId}),
    mod_scene_mark:load_mask(SceneId),
    load_npc(S#ets_scene.npc, SceneId, S#ets_scene.name),
    load_mon_link(S#ets_scene.mon, SceneId, S#ets_scene.name),
    ok.

%% 加载NPC
load_npc([], _, _) ->
    ok;
load_npc([[NpcId, X, Y] | T], SceneId, SceneName) ->
    case data_npc:get(NpcId) of
        [] ->
            ok;
        N ->
            N1 = N#ets_npc{
                id = NpcId,
                x = X,
                y = Y,
                scene = SceneId,
                sname = SceneName
            },
            mod_scene_npc:insert(N1)
    end,
    load_npc(T, SceneId, SceneName).

%%% 加载怪物
load_mon([], _, _, _, _) ->
    ok;
load_mon([[MonId, X, Y, Type, Group] | T], SceneId, CopyId, Lv, DropNum) ->
    mod_mon_create:create_mon(MonId, SceneId, X, Y, Type, CopyId, 0, [{auto_lv, Lv},{group, Group},{drop_num, DropNum}]),
    load_mon(T, SceneId, CopyId, Lv, DropNum).

%% 加载怪物所在场景
load_mon_link([], _, _) -> ok;
load_mon_link([[MonId, X, Y | _] | T], SceneRes, Name) ->
    Data = data_mon:get(MonId),
    case Data =:= [] of
        true ->
            skip;
        false ->
            mod_scene_mon:insert(#ets_scene_mon{id = MonId, scene=SceneRes, 
						name = Name, lv = Data#ets_mon.lv, 
						mname= Data#ets_mon.name, 
						kind = Data#ets_mon.kind, 
						x = X, y = Y,
						out = Data#ets_mon.out})
    end,
    load_mon_link(T, SceneRes, Name).
