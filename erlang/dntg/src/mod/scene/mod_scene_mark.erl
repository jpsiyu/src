%%%------------------------------------
%%% @Module  : mod_scene_mark
%%% @Author  : xyao
%%% @email   : jiexiaowen@gmail.com
%%% @Created : 2011.06.14
%%% @Description: 场景mark管理
%%%------------------------------------
-module(mod_scene_mark).
-behaviour(gen_server).
-export([
        start_link/1,
        get_mark_pid/1,
        load_mask/1,
        get_scene_poses/1,
        get_scene_safe_poses/1,
        get_scene_water_poses/1
    ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {scene_poses, scene_safe_poses, scene_water_poses}).

start_link(SceneId) ->
    gen_server:start(?MODULE, [SceneId], []).
    %gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 加载mask
load_mask(SceneId) ->
    case get_mark_pid(SceneId) of
        undefined ->
            false;
        Pid ->
            gen_server:cast(Pid, {load_mask, SceneId})
    end.

get_scene_poses(Key) ->
    {SceneId, _, _} = Key,
    case get_mark_pid(SceneId) of
        undefined ->
            false;
        Pid ->
            case catch gen:call(Pid, '$gen_call', {get_scene_poses, Key}, 2000) of
                {ok, Bool} -> Bool;
                _ -> false
            end
    end.

get_scene_safe_poses(Key) ->
    {SceneId, _, _} = Key,
    case get_mark_pid(SceneId) of
        undefined ->
            false;
        Pid ->
            case catch gen:call(Pid, '$gen_call', {get_scene_safe_poses, Key}, 2000) of
                {ok, Bool} -> Bool;
                _ -> false
            end
    end.

get_scene_water_poses(Key) ->
    {SceneId, _, _} = Key,
    case get_mark_pid(SceneId) of
        undefined ->
            false;
        Pid ->
            case catch gen:call(Pid, '$gen_call', {get_scene_water_poses, Key}, 2000) of
                {ok, Bool} -> Bool;
                _ -> false
            end
    end.

init([SceneId]) ->
    State = #state{
        scene_poses = dict:new(),
        scene_safe_poses = dict:new(),
        scene_water_poses = dict:new()
    },
    MarkProcessName = misc:mark_process_name(SceneId),
    misc:register(local, MarkProcessName, self()),
    {ok, State}.

%handle_call({load_mask, SceneId}, _From, State) ->
%    State1 = case data_mask:get(SceneId) of
%        "" -> State;
%        Mask1 -> load_mask(Mask1, 0, 0, SceneId, State)
%    end,
%    {reply, ok, State1};

handle_call({get_scene_poses, Key}, _From, State) ->
    {reply, dict:is_key(Key, State#state.scene_poses), State};

handle_call({get_scene_safe_poses, Key}, _From, State) ->
    {reply, dict:is_key(Key, State#state.scene_safe_poses), State};

handle_call({get_scene_water_poses, Key}, _From, State) ->
    {reply, dict:is_key(Key, State#state.scene_water_poses), State};

handle_call(_Request, _From, State) ->
    {reply, State, State}.

handle_cast({load_mask, SceneId}, State) ->
    State1 = case data_mask:get(SceneId) of
        "" -> State;
        Mask1 -> load_mask(Mask1, 0, 0, SceneId, State)
    end,
    {noreply, State1};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% 从地图的mask中构建ETS坐标表，表中存放的是可移动的坐标
%% load_mask(Mask,0,0)，参数1表示地图的mask列表，参数2和3为当前产生的X,Y坐标
load_mask([], _, _, _, State) ->
    State;
load_mask([H|T], X, Y, SceneId, State) ->
    case H of
        10 -> % 等于\n
            load_mask(T, 0, Y+1, SceneId, State);
        13 -> % 等于\r
            load_mask(T, X, Y, SceneId, State);
        44 -> % 等于,(客户端用不处理)
            load_mask(T, X, Y, SceneId, State);
        48 -> % 0 %% 可行走没有处理的
            load_mask(T, X+1, Y, SceneId, State);
        49 -> % 1 %% 不能行走
            D1 = dict:store({SceneId, X, Y}, 0, State#state.scene_poses),
            load_mask(T, X+1, Y, SceneId, State#state{scene_poses = D1});
        50 -> % 2 %% 透明区
            load_mask(T, X+1, Y, SceneId, State);
        53 -> % 5 %% 安全区
            D1 = dict:store({SceneId, X, Y}, 0, State#state.scene_safe_poses),
            load_mask(T, X+1, Y, SceneId, State#state{scene_safe_poses = D1});
        54 -> % 6 %% 安全区的透明区域
            D1 = dict:store({SceneId, X, Y}, 0, State#state.scene_safe_poses),
            load_mask(T, X+1, Y, SceneId, State#state{scene_safe_poses = D1});
        55 -> % 7 %%　温泉
            D1 = dict:store({SceneId, X, Y}, 0, State#state.scene_water_poses),
            load_mask(T, X+1, Y, SceneId, State#state{scene_water_poses = D1});
        56 -> % 8 %%  水面表（ｖｉｐ温泉专用）
            D1 = dict:store({SceneId, X, Y}, 0, State#state.scene_water_poses),
            load_mask(T, X+1, Y, SceneId, State#state{scene_water_poses = D1});
        58 -> % 等于:(客户端用不处理)
            load_mask(T, X, Y, SceneId, State);
        _ ->
            load_mask(T, X+1, Y, SceneId, State) 
    end.

get_mark_pid(Id) ->
    case get({get_mark_pid, Id}) of
        undefined ->
            MarkProcessName = misc:mark_process_name(Id),
            MarkPid =  misc:whereis_name(local, MarkProcessName),
            case is_pid(MarkPid) of
                true ->
                    put({get_mark_pid, Id}, MarkPid),
                    MarkPid;
                false ->
                    undefined
            end;
        MarkPid ->
            MarkPid
    end.

