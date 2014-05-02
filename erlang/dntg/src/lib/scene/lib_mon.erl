%%%-----------------------------------
%%% @Module  : lib_mon
%%% @Author  : zzm
%%% @mail    : ming_up@163.com
%%% @Created : 2010.05.08
%%% @Description: 怪物
%%%-----------------------------------
-module(lib_mon).
-include("scene.hrl").
-include("server.hrl").

%% 对外接口
-export([
        sync_create_mon/8,              %% 同步创建怪物
        async_create_mon/8,             %% 异步创建怪物
        get_scene_mon/3,                %% 获取场景内所有怪物属性
        get_scene_mon_by_ids/3,         %% 根据怪物id获取属性
        get_scene_mon_by_mids/4,        %% 根据怪物资源id获取属性
        clear_scene_mon/3,              %% 清理场景所有怪物
        clear_scene_mon_by_ids/4,       %% 根据怪物id清理怪物
        clear_scene_mon_by_mids/4,      %% 根据怪物资源id清理怪物
        klist/1,                        %% 获取怪物klist
        change_mon_attr/3               %% 更改怪物属性
    ]).

%% 对场景怪物模块内部接口
-export(
    [
        get_name_by_mon_id/1,
        remove_mon/1,
        remove_mon/2,
        lookup/2,
        insert/1,
        insert/2,
        delete/1,
        delete/2,
        get_mon_by_id/1,
        get_area_mon_id_aid_mid/6,
        get_mon_for_battle/6,
        get_line_mon_for_battle/10,
        get_all_area_mon/3,
        get_ai/4,
        put_ai/5,
        del_ai/2,
        del_all_area/2
    ]
).

%% 同步创建怪物
%% @spec sync_create_mon(MonId, Scene, X, Y, Type, CopyId, BroadCast, Args) -> MonAutoId
%% @param MonId 怪物资源ID
%% @param Scene 场景ID
%% @param X 坐标
%% @param X 坐标
%% @param Type       怪物战斗类型（0被动，1主动）
%% @param CopyId     房间号ID 为0时，普通房间，非0值切换房间。值相同，在同一个房间。
%% @param BroadCast  是否出生时广播（0不广播，1广播）
%% @param Args       其余动态创建属性
%%                   = list() = [Tuple1, Tuple2...]
%%            Tuple1 = tuple(), {auto_lv, V} | {group, V} | {cruise_info, V} | 
%%                              {owner_id, OwnerId} | {mon_name, MonName} |  {color, MonColor} | {skip, V} | 
%%                              {crack, V}
%% @return MonAutoId 怪物自增ID，每个怪物唯一
%% @end
sync_create_mon(MonId, Scene, X, Y, Type, CopyId, BroadCast, Args) -> 
    case mod_scene_agent:apply_call(Scene, mod_mon_create, create_mon, [MonId, Scene, X, Y, Type, CopyId, BroadCast, Args]) of
		Id when is_integer(Id) -> Id;
		_Retrun -> 0
	end.

%% 异步创建怪物
%% @spec async_create_mon(MonId, Scene, X, Y, Type, CopyId, BroadCast, Args) -> ok.
%% @end
async_create_mon(MonId, Scene, X, Y, Type, CopyId, BroadCast, Args) ->
    mod_scene_agent:apply_cast(Scene, mod_mon_create, create_mon_cast, [MonId, Scene, X, Y, Type, CopyId, BroadCast, Args]).

%% @spec get_scene_mon(SceneId, CopyId, ResultForm) -> MonForm
%% 按格式返回怪物属性
%% SceneId    = int()              场景id
%% CopyId     = [] | int() | pid() 房间id
%% ResultForm = list()|int()       [#ets_mon.xx1, #ets_mon.xx2...] | all | #ets_mon.xx1 属性组装列表或者单项属性
%% @end
get_scene_mon(SceneId, CopyId, ResultForm) -> 
    mod_scene_agent:apply_call(SceneId, mod_mon_agent, apply_call, [SceneId, lib_mon_agent, get_scene_mon, [CopyId, ResultForm]]).

%% @spec get_scene_mon_by_ids(SceneId, Ids, ResultForm) -> MonForm
%% 按格式返回怪物属性
%% SceneId    = int()              场景id
%% Ids        = list()        怪物唯一Id列表
%% ResultForm = list()|int()  [#ets_mon.xx1, #ets_mon.xx2...] | all | #ets_mon.xx1 属性组装列表或者单项属性
%% @end
get_scene_mon_by_ids(SceneId, Ids, ResultForm) -> 
    mod_scene_agent:apply_call(SceneId, mod_mon_agent, apply_call, [SceneId, lib_mon_agent, get_scene_mon_by_ids, [Ids, ResultForm]]).


%% @spec get_scene_mon_by_mids(SceneId, CopyId, Mids, ResultForm) -> MonForm
%% 按格式返回怪物属性
%% SceneId    = int()              场景id
%% CopyId     = [] | int() | pid() 房间id
%% Mids       = list()             怪物类型id
%% ResultForm = list()|int()       [#ets_mon.xx1, #ets_mon.xx2...] | all | #ets_mon.xx1 属性组装列表或者单项属性
%% @end
get_scene_mon_by_mids(SceneId, CopyId, Mids, ResultForm) -> 
    mod_scene_agent:apply_call(SceneId, mod_mon_agent, apply_call, [SceneId, lib_mon_agent, get_scene_mon_by_mids, [CopyId, Mids, ResultForm]]).


%% @spec clear_scene_mon_by_mids(SceneId, CopyId, BroadCast)-> ok.
%% 清除全场景的怪物
%% @param SceneId    = int()                 场景ID
%% @param CopyId     = int() | pid()         房间id,不分房间清理时置为 []
%% @param BroadCast  = 0 | 1                 是否需要在清除的时候广播(0不广播，1广播)
%% @end
clear_scene_mon(SceneId, CopyId, BroadCast) ->
    mod_scene_agent:apply_cast(SceneId, mod_mon_agent, apply_cast, [SceneId, lib_mon_agent, clear_scene_mon, [CopyId, BroadCast]]),
    %mod_mon_agent:apply_cast(SceneId, lib_mon_agent, clear_scene_mon, [CopyId, BroadCast]),
    ok.

%% @spec clear_scene_mon_by_ids(SceneId, CopyId, BroadCast, Ids)-> ok.
%% 清除id怪物
%% @param SceneId    = int()                 场景ID
%% @param CopyId     = int() | pid()         房间id,不分房间清理时置为 []
%% @param BroadCast  = 0 | 1                 是否需要在清除的时候广播(0不广播，1广播)
%% @param Ids        = list()                怪物唯一Id列表 #ets_mon.id
%% @end
clear_scene_mon_by_ids(SceneId, _CopyId, BroadCast, Ids)->
    mod_scene_agent:apply_cast(SceneId, mod_mon_agent, apply_cast, [SceneId, lib_mon_agent, clear_scene_mon_by_ids, [BroadCast, Ids]]),
    ok.

%% @spec clear_scene_mon_by_mids(SceneId, CopyId, BroadCast, Mids)-> ok.
%% 清除场景相同mid的怪物
%% @param SceneId    = int()                 场景ID
%% @param CopyId     = int() | pid()         房间id,不分房间清理时置为 []
%% @param BroadCast  = 0 | 1                 是否需要在清除的时候广播(0不广播，1广播)
%% @param Mids       = list()                怪物资源Id列表 #ets_mon.mid
%% @end
clear_scene_mon_by_mids(SceneId, CopyId, BroadCast, Mids)->
    mod_scene_agent:apply_cast(SceneId, mod_mon_agent, apply_cast, [SceneId, lib_mon_agent, clear_scene_mon_by_mids, [CopyId, BroadCast, Mids]]),
    ok.

%% 获取mon名称用mon数据库id
get_name_by_mon_id(MonId)->
    case data_mon:get(MonId) of
        [] -> <<"">>;
        Mon -> Mon#ets_mon.name
    end.
%% 获取怪物伤害列表
klist(Aid) ->
    gen_fsm:sync_send_all_state_event(Aid, {'klist'}).

%% 改变怪物属性
%% Id: 怪物唯一id
%% AttrList: list() = [Tuple ...], %% 怪物属性
%%           Tuple = {group, Value} | {hp, Value}
change_mon_attr(Id, Scene, AttrList) ->
    mod_scene_agent:apply_cast(Scene, mod_mon_agent, apply_cast, [Scene, lib_mon_agent, change_mon_attr, [Id, AttrList]]).


%% 清除怪物
remove_mon(#ets_mon{id = MonId, aid = MonPid} = Mon) -> 
    case is_pid(MonPid) andalso misc:is_process_alive(MonPid) of
        true ->
            mod_mon_active:stop(MonPid);
        false ->
            delete(Mon)
    end,
    {ok, BinData} = pt_120:write(12006, [MonId]),
    lib_server_send:send_to_scene(Mon#ets_mon.scene, Mon#ets_mon.copy_id, BinData),
    ok.

remove_mon(Scene, MonId) ->
    case lib_mon:lookup(Scene, MonId) of
        [] -> 
            ok;
        Mon ->
            remove_mon(Mon)
    end.

%% 查找指定怪物信息
lookup(Scene, Id) ->
    mod_mon_agent:apply_call(Scene, lib_mon_agent, get_mon, [Id]).

%% 修改或者插入数据
insert(Mon) ->
    mod_mon_agent:apply_cast(Mon#ets_mon.scene, lib_mon_agent, put_mon, [Mon]).
insert(Scene, Mon) ->
    mod_mon_agent:apply_cast(Scene, lib_mon_agent, put_mon, [Mon]).

delete(Mon) ->
    mod_mon_agent:apply_cast(Mon#ets_mon.scene, lib_mon_agent, del_mon, [Mon#ets_mon.id]).
delete(Scene, Id) ->
    mod_mon_agent:apply_cast(Scene, lib_mon_agent, del_mon, [Id]).

get_mon_by_id(MonId) ->
    case mod_scene_mon:lookup(MonId) of
        [] ->
            [];
        MonData ->
            MonData
    end.

get_mon_for_battle(Q, CopyId, X, Y, Area, Group) ->
    mod_mon_agent:apply_call(Q, lib_mon_agent, get_mon_for_battle, [CopyId, X, Y, Area, Group]).

get_line_mon_for_battle(Q, CopyId, OX, OY, X, Y, Area, K, B, Group) ->
    mod_mon_agent:apply_call(Q, lib_mon_agent, get_line_mon_for_battle, [CopyId, OX, OY, X, Y, Area, K, B, Group]).

get_all_area_mon(Q, Area, CopyId) ->
    mod_mon_agent:apply_call(Q, lib_mon_agent, get_all_area_mon, [Area, CopyId]).

get_area_mon_id_aid_mid(Q, CopyId, X, Y, Area, Group) ->
    mod_mon_agent:apply_call(Q, lib_mon_agent, get_area_mon_id_aid_mid, [CopyId, X, Y, Area, Group]).

%% 获取怪物ai
get_ai(SceneId, CopyId, X, Y) ->
    mod_mon_agent:apply_call(SceneId, lib_mon_agent, get_ai, [SceneId, CopyId, X, Y]).

%% 写入怪物ai
put_ai(Aid, SceneId, CopyId, X, Y) ->
    mod_mon_agent:apply_cast(SceneId, mod_mon_active, insert_for_ai, [Aid, SceneId, CopyId, X, Y]).

%% 删除怪物ai
del_ai(SceneId, CopyId) ->
    mod_mon_agent:apply_cast(SceneId, lib_mon_agent, del_ai, [SceneId, CopyId]).

%% 删除怪物9宫格
del_all_area(SceneId, CopyId) ->
    mod_mon_agent:apply_cast(SceneId, lib_mon_agent, del_all_area, [CopyId]).
