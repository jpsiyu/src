%%%-----------------------------------
%%% @Module  : lib_mon_agent
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2012.05.17
%%% @Description: 怪物场景管理器
%%%-----------------------------------
-module(lib_mon_agent).

%% 对外接口
-export([
        get_scene_mon/2,                  %% 获取场景内所有怪物属性
        get_scene_mon_by_ids/2,           %% 根据怪物id获取属性
        get_scene_mon_by_mids/3,          %% 根据怪物资源id获取属性
        clear_scene_mon/2,                %% 清理场景所有怪物
        die_scene_mon_by_ids/1,           %% 根据怪物ids死亡怪物，不清除怪物进程
        clear_scene_mon_by_ids/2,         %% 根据怪物id清理怪物
        clear_scene_mon_by_mids/3,        %% 根据怪物资源id清理怪物
        change_mon_attr/2                 %% 更改怪物属性
    ]).

%% 对场景怪物模块内部接口
-export([
            get_scene_mon/0,              %% 获取场景所有怪物
            get_scene_mon/1,              %% 获取场景的所有怪物
            get_scene_mon_num/1,          %% 获取场景的所有怪物数量
            get_scene_mon_num_by_kind/2,  %% 获得当前场景某种类型怪物数量
			get_mon/1,                    %% 获取怪物（根据怪物id）
            get_area_mon_id_aid_mid/5,    %% 获取场景所有怪物id,进程id,资源id
            get_mon_for_battle/5,         %% 获取战斗所需信息
            get_line_mon_for_battle/9,    %% 获取直线的怪物信息
            get_area/2,                   %% 获取格子怪物id
            get_all_area/2,               %% 获取九宫格子怪物id
            get_area_mon/2,               %% 获取格子怪物信息
            get_all_area_mon/2,           %% 获取九宫格子怪物信息
            get_ai/4,                     %% 获取怪物ai
			put_mon/1,                    %% 保存怪物数据                 
            put_ai/5,                     %% 写入怪物ai
			save_to_area/4,               %% 添加在九宫格         
			del_mon/1,                    %% 保存怪物数据			
            del_ai/2,                     %% 删除怪物ai
			del_to_area/4,                %% 删除在九宫格
            del_all_area/1,               %% 删除9宫格数据
            get_att_target_info_by_id/1   %% 怪物追踪目标时获取目标信息
        ]).

-include("scene.hrl").

%% @spec get_scene_mon() -> MonList
%% 获取场景的所有怪物
%% MonList = list() = [#ets_mon{}...]
%% @end
get_scene_mon() ->
    AllMon = get(),
    [ Mon || {Key, Mon} <- AllMon, is_integer(Key)].

%% @spec get_scene_mon(CopyId) -> MonList
%% 获取场景某个房间内的所有怪物
%% CopyId  = int() | pid() 房间号
%% MonList = list()        [#ets_mon{}...] 怪物记录列表
%% @end
get_scene_mon(CopyId) ->
    AllMon = get_id(CopyId),
    get_scene_mon_helper(AllMon, CopyId, []).

%% @spec get_scene_mon(CopyId, ResultForm) -> MonForm
%% 按格式返回怪物属性
%% CopyId     = [] | int() | pid() 房间id
%% ResultForm = list()|int()       [#ets_mon.xx1, #ets_mon.xx2...] | [all]
%% @end
get_scene_mon(CopyId, ResultForm) -> 
    AllMon = case CopyId of
        [] -> get_scene_mon();
        _  -> get_scene_mon(CopyId)
    end,
    [returnform(Mon, ResultForm)||Mon<-AllMon].

%% @spec get_scene_mon_by_ids(Ids, ResultForm) -> MonForm
%% 按格式返回怪物属性
%% Ids        = list()        怪物唯一Id列表
%% ResultForm = list()|int()  [#ets_mon.xx1, #ets_mon.xx2...] | all | #ets_mon.xx1 属性组装列表或者单项属性
%% @end
get_scene_mon_by_ids(Ids, ResultForm) -> 
    AllMon = [ get_mon(Id) || Id <- Ids ],
    [returnform(Mon, ResultForm) || Mon <- AllMon].

%% @spec get_scene_mon_by_mids(CopyId, Mids, ResultForm) -> MonForm
%% 按格式返回怪物属性
%% CopyId     = [] | int() | pid() 房间id
%% Mids       = list()             怪物类型id
%% ResultForm = list()|int()       [#ets_mon.xx1, #ets_mon.xx2...] | all | #ets_mon.xx1 属性组装列表或者单项属性
%% @end
get_scene_mon_by_mids(CopyId, Mids, ResultForm) -> 
    AllMon = case CopyId of
        [] -> get_scene_mon();
        _  -> get_scene_mon(CopyId)
    end,
    [returnform(Mon, ResultForm) || Mon <- AllMon, lists:member(Mon#ets_mon.mid, Mids)].

%% @spec returnform(Mon, ResultForm) -> MonForm
%% 返回时格式化
%% Mon        = #ets_mon{}      怪物record
%% ResultForm = list() | int()  [#ets_mon.xx1, #ets_mon.xx2...] | all | #ets_mon.xx1 属性组装列表或者单项属性
%% @end
returnform(Mon, ResultForm) when is_list(ResultForm)-> 
    F = fun(Num) -> 
            case Num of
                all -> Mon;
                _   -> element(Num, Mon)
            end
    end,
    [F(Num) || Num <- ResultForm, is_integer(Num)];
returnform(Mon, ResultForm) -> 
    case ResultForm of
        all -> Mon;
        _   -> element(ResultForm, Mon)
    end.

%% @spec clear_scene_mon(CopyId, BroadCast) -> ok.
%% 清理创建怪物
%% CopyId    = int() | pid() | []   房间号，不分房间为[]
%% BroadCast = 1 | 0                是否广播(1是，0否)
%% @end
clear_scene_mon(CopyId, BroadCast) -> 
    AllAid = get_scene_mon(CopyId, #ets_mon.aid),
    io:format("TEST:lib_mon_agent:clear_scene_mon/2 ~p~n", [AllAid]),
    case BroadCast of
        1 -> [mod_mon_active:stop_broadcast(Aid) || Aid <- AllAid];
        _ -> [mod_mon_active:stop(Aid)           || Aid <- AllAid]
    end,
    ok.

%% @spec die_scene_mon_by_ids(Ids) -> ok.
%% 按怪物唯一id死亡创建怪物，不清除怪物进程
%% Ids       = list()               怪物唯一id列表 #ets_mon.id
%% @end
die_scene_mon_by_ids(Ids) -> 
    AllAid = get_scene_mon_by_ids(Ids, #ets_mon.aid),
    %io:format("TEST:lib_mon_agent:die_scene_mon_by_ids/1 ~p~n", [AllAid]),
    [mod_mon_active:die(Aid)|| Aid <- AllAid],
    ok.

%% @spec clear_scene_mon_by_ids(BroadCast, Ids) -> ok.
%% 按怪物唯一id清理创建怪物
%% BroadCast = 1 | 0                是否广播(1是，0否)
%% Ids       = list()               怪物唯一id列表 #ets_mon.id
%% @end
clear_scene_mon_by_ids(BroadCast, Ids) -> 
    AllAid = get_scene_mon_by_ids(Ids, #ets_mon.aid),
    %io:format("TEST:lib_mon_agent:clear_scene_mon_by_ids/2 ~p~n", [AllAid]),
    case BroadCast of
        1 -> [mod_mon_active:stop_broadcast(Aid) || Aid <- AllAid];
        _ -> [mod_mon_active:stop(Aid)           || Aid <- AllAid]
    end,
    ok.

%% @spec clear_scene_mon_by_mids(CopyId, BroadCast, Mids) -> ok.
%% 按怪物类型id清理创建怪物
%% CopyId    = int() | pid() | []   房间号，不分房间位置[]
%% BroadCast = 1 | 0                是否广播(1是，0否)
%% Mids      = list()               怪物资源id列表 #ets_mon.mid
%% @end
clear_scene_mon_by_mids(CopyId, BroadCast, Mids) -> 
    AllAid = get_scene_mon_by_mids(CopyId, Mids, #ets_mon.aid),
    %io:format("TEST:lib_mon_agent:clear_scene_mon_by_mids/3 ~p~n", [AllAid]),
    case BroadCast of
        1 -> [mod_mon_active:stop_broadcast(Aid) || Aid <- AllAid];
        _ -> [mod_mon_active:stop(Aid)           || Aid <- AllAid]
    end,
    ok.

%% @spec change_mon_attr(Id, AtrrList) -> ok.
%% 改变怪物属性
%% Id: 怪物唯一id
%% AtrrList: 怪物属性 [Tuple ...]
%%           Tuple = {group, Value} | {hp, Value} | {hp_lim, V} | {def, V}
%%                   | {skill, SkillList}, SkillList = [{技能id, 概率}...] 
%%                   | {att_area, V}
%% @end
change_mon_attr(Id, AtrrList) ->
    case get_mon(Id) of
        []  -> skip;
        Mon -> Mon#ets_mon.aid ! {'change_attr', AtrrList}
    end,
    ok.


%% 获取场景的所有怪物数量（按房间）
get_scene_mon_num(CopyId) ->
    length(get_id(CopyId)).

get_scene_mon_num_by_kind(CopyId, Kind)->
    AllMon = get_scene_mon(CopyId),
    length([0||Mon <- AllMon, Mon#ets_mon.kind == Kind]).

get_scene_mon_helper([], _, Data) ->
    Data;
get_scene_mon_helper([Id | T], CopyId, Data) ->
    case get(Id) of
         undefined ->
             del_id(CopyId, Id),
             get_scene_mon_helper(T, CopyId, Data);
         Mon ->
             get_scene_mon_helper(T, CopyId, [Mon | Data])
     end. 

%% 获取怪物数据
get_mon(Id) ->
     case get(Id) of
         undefined ->
             [];
         Mon ->
             Mon
     end.

%% 获取场景区域内所有怪物id,进程id,资源id
get_area_mon_id_aid_mid(CopyId, X, Y, Area, Group) ->
    AllArea = lib_scene_calc:get_the_area(X, Y),
    AllMon = get_all_area_mon(AllArea, CopyId),
    X1 = X + Area,
    X2 = X - Area,
    Y1 = Y + Area,
    Y2 = Y - Area,
    [ [Mon#ets_mon.id, Mon#ets_mon.aid, Mon#ets_mon.mid] || Mon <- AllMon, Mon#ets_mon.x >= X2 andalso Mon#ets_mon.x =< X1, Mon#ets_mon.y >= Y2 andalso Mon#ets_mon.y =< Y1 , Mon#ets_mon.hp > 0, Mon#ets_mon.is_be_atted == 1, Mon#ets_mon.group /= Group].

%% 获取战斗所需信息
get_mon_for_battle(CopyId, X, Y, Area, Group) ->
    AllArea = lib_scene_calc:get_the_area(X, Y),
    AllMon = get_all_area_mon(AllArea, CopyId),
    X1 = X + Area,
    X2 = X - Area,
    Y1 = Y + Area,
    Y2 = Y - Area,
    [ Mon || Mon <- AllMon, Mon#ets_mon.x >= X2 andalso Mon#ets_mon.x =< X1, Mon#ets_mon.y >= Y2 andalso Mon#ets_mon.y =< Y1 , Mon#ets_mon.hp > 0, Mon#ets_mon.is_be_atted == 1, (Mon#ets_mon.group /= Group orelse Group == 0)]. %% 40306:70级boss召唤的火坑

get_line_mon_for_battle(CopyId, OX, OY, X, Y, Area, K, B, Group) -> 
    AllArea = lib_scene_calc:get_the_area(X, Y),
    AllMon = get_all_area_mon(AllArea, CopyId),
    X1 = X + Area,
    X2 = X - Area,
    Y1 = Y + Area,
    Y2 = Y - Area,
    F = fun(UX, UY) ->
            TrueOrFalse1 = if
                OX == X -> UX == X orelse UX == X-1 orelse UX == X+1;
                true -> (round( UX * K + B) == UY 
                        orelse round(UX * K + B + 1) == UY
                        orelse round(UX * K + B - 1) == UY)
            end,
            TrueOrFalse2 = if
                OX > X andalso OY < Y -> UX >= X  andalso UX =< X1 andalso UY >= Y2 andalso UY =< Y;  %% 第一象限
                OX < X andalso OY < Y -> UX >= X2 andalso UX =< X  andalso UY >= Y2 andalso UY =< Y;  %% 第二象限
                OX < X andalso OY > Y -> UX >= X2 andalso UX =< X  andalso UY >= Y  andalso UY =< Y1; %% 第三象限
                OX > X andalso OY > Y -> UX >= X  andalso UX =< X1 andalso UY >= Y  andalso UY =< Y1; %% 第四象限
                OX == X andalso OY > Y -> UY >= Y andalso UY =< Y1;
                OX == X andalso OY < Y -> UY =< Y andalso UY >= Y2;
                OY == Y andalso OX > X -> UX >= X andalso UX =< X1;
                OY == Y andalso OX < X -> UX =< X andalso UX >= X2;
                true -> false
            end,
            TrueOrFalse1 andalso TrueOrFalse2
    end,
    [ Mon || Mon <- AllMon, Mon#ets_mon.hp > 0, Mon#ets_mon.is_be_atted == 1, (Mon#ets_mon.group /= Group orelse Group == 0), F(Mon#ets_mon.x, Mon#ets_mon.y)].

%% 获取格子怪物id
get_area(XY, CopyId) ->
    case get(?TABLE_AREA(XY, CopyId)) of
        undefined ->
            [];
        D ->
            dict:fetch_keys(D)
    end.

%% 获取g宫格子怪物id
get_all_area(Area, CopyId) ->
    lists:foldl(
        fun(A, L) -> 
                get_area(A, CopyId) ++ L 
        end, 
    [], Area).

%% 获取格子怪物信息
get_area_mon(XY, CopyId) ->
    AllMon = get_area(XY, CopyId),
    get_scene_mon_helper(AllMon, CopyId, []).

%% 获取九宫格子怪物信息
get_all_area_mon(Area, CopyId) ->
    List = lists:foldl(
        fun(A, L) -> 
                get_area(A, CopyId) ++ L 
        end, 
    [], Area),
    get_scene_mon_helper(List, CopyId, []).

%% 获取怪物ai
get_ai(SceneId, CopyId, X, Y) ->
    case get({SceneId, CopyId}) of
        undefined ->
            [];
        D ->
            case dict:find({X, Y}, D) of
                {ok, V} ->
                    V;
                _ ->
                    []
            end
    end.

%% 保存怪物数据
put_mon(Mon) ->
    case get(Mon#ets_mon.id) of
        undefined ->
            save_id(Mon#ets_mon.copy_id, Mon#ets_mon.id),
            save_to_area(Mon#ets_mon.copy_id, Mon#ets_mon.x, Mon#ets_mon.y, Mon#ets_mon.id);
        _Mon ->
            XY1 = lib_scene_calc:get_xy(Mon#ets_mon.x, Mon#ets_mon.y),
            XY2 = lib_scene_calc:get_xy(_Mon#ets_mon.x, _Mon#ets_mon.y),
            if 
                XY1 =:= XY2 ->
                    skip;
                true ->
                    del_to_area(_Mon#ets_mon.copy_id, XY2, _Mon#ets_mon.id),
                    save_to_area(Mon#ets_mon.copy_id, XY1, Mon#ets_mon.id)
            end
    end,
    put(Mon#ets_mon.id, Mon).

%% 写入怪物ai
put_ai(SceneId, CopyId, X, Y, Aid) ->
    D1 = case get({SceneId, CopyId}) of
        undefined ->
            _D = dict:new(),
            put({SceneId, CopyId}, _D),
            _D;
        D ->
            D
    end,
    case dict:find({X, Y}, D1) of
        {ok, V} ->
            put({SceneId, CopyId}, dict:store({X, Y}, V ++ [Aid], D1));
        _ ->
            put({SceneId, CopyId}, dict:store({X, Y}, [Aid], D1))
    end.

%% 添加在九宫格
save_to_area(CopyId, XY, Id) ->
    case get(?TABLE_AREA(XY, CopyId)) of
        undefined ->
            D1 = dict:new(),
            put(?TABLE_AREA(XY, CopyId), dict:store(Id, 0, D1));
        D2 ->
            put(?TABLE_AREA(XY, CopyId), dict:store(Id, 0, D2))
    end.

save_to_area(CopyId, X, Y, Id) ->
    XY = lib_scene_calc:get_xy(X, Y),
    case get(?TABLE_AREA(XY, CopyId)) of
        undefined ->
            D1 = dict:new(),
            put(?TABLE_AREA(XY, CopyId), dict:store(Id, 0, D1));
        D2 ->
            put(?TABLE_AREA(XY, CopyId), dict:store(Id, 0, D2))
    end.

%% 删除怪物数据
del_mon(Id) ->
    case get(Id) of
        undefined ->
            [];
        Mon ->
            del_id(Mon#ets_mon.copy_id, Id),
            del_to_area(Mon#ets_mon.copy_id, Mon#ets_mon.x, Mon#ets_mon.y, Id),
            mod_scene_agent:apply_cast(Mon#ets_mon.scene, erlang, erase, [["1MOD_BATTLE_STATE", Id]]),
            erase(Id)
    end.

%% 删除怪物ai
del_ai(SceneId, CopyId) ->
    erase({SceneId, CopyId}).

del_to_area(CopyId, XY, Id) ->
    case get(?TABLE_AREA(XY, CopyId)) of
        undefined ->
            skip;
        D ->
            put(?TABLE_AREA(XY, CopyId), dict:erase(Id, D))
    end.

del_to_area(CopyId, X, Y, Id) ->
    XY = lib_scene_calc:get_xy(X, Y),
    case get(?TABLE_AREA(XY, CopyId)) of
        undefined ->
            skip;
        D ->
            put(?TABLE_AREA(XY, CopyId), dict:erase(Id, D))
    end.

%% 删除9宫格数据
del_all_area(CopyId) ->
    Data = get(),
    F = fun({Key, _}) ->
        case Key of
            {_, _, Cid} when Cid =:= CopyId ->
                erase(Key);
            {_, Cid} when Cid =:= CopyId ->
                erase(Key);
            _ ->
                skip
        end
    end,
    lists:foreach(F, Data).

%% 保存id
save_id(CopyId, Id) ->
    case get({id, CopyId}) of
        undefined ->
            D1 = dict:new(),
            put({id, CopyId}, dict:store(Id, 0, D1));
        D2 ->
            put({id, CopyId}, dict:store(Id, 0, D2))
    end.

%% 获取id
get_id(CopyId) ->
    case get({id, CopyId}) of
        undefined ->
            [];
        D ->
            dict:fetch_keys(D)
    end.

%% 删除id
del_id(CopyId, Id) ->
    case get({id, CopyId}) of
        undefined ->
            skip;
        D ->
            put({id, CopyId}, dict:erase(Id, D))
    end.

%% 怪物追踪目标时获取目标信息
get_att_target_info_by_id([MonAid, Key, AttType, _MonGroup]) -> 
    AttInfo = case get_mon(Key) of
        Mon when is_record(Mon, ets_mon), Mon#ets_mon.hp > 0 -> 
            X0 = Mon#ets_mon.x,
            Y0 = Mon#ets_mon.y,
            Hp0 = Mon#ets_mon.hp,
            {true, X0, Y0, Hp0, Mon};
        _ ->
            false
    end,
    mod_mon_active:trace_info_back(MonAid, AttType, AttInfo).
