%% ---------------------------------------------------------
%% Author:  HHL
%% Email:   
%% Created: 2014-4-9
%% Description:lib_mount3坐骑操作函数模块
%% --------------------------------------------------------
-module(lib_mount3).
-compile(export_all).
-include("mount.hrl").
-include("server.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-include("scene.hrl").
-include("errcode_goods.hrl").

%% ====================================================================
%% Internal functions
%% ====================================================================
% 九宫格发经验
add_exp_area(Scene, CopyId, X, Y, Exp, Pid) ->
    %% 判断是否跨服场景
    case lib_scene:is_clusters_scene(Scene) of
        true -> skip; %% 跨服场景不发放经验
        false -> 
            case mod_scene_agent:apply_call(Scene, lib_scene_agent, get_scene_user_pid_area, [CopyId, X, Y, 20]) of
                UserPidList when is_list(UserPidList) -> 
                    F = fun(Id) ->
                            if
                                Id =:= Pid ->
                                    gen_server:cast(Id, {'set_data', [{add_exp, Exp}]});
                                true ->
                                    gen_server:cast(Id, {'set_data', [{add_exp, round(Exp/5)}]})
                            end
                    end,
                    [F(Id) || Id <- UserPidList];
                _ ->
                    skip
            end
    end.

get_exp(Type) ->
    case Type of
        0 -> 20000;
        1 -> 40000;
        2 -> 80000;
        3 -> 160000;
        4 -> 320000;
        _ -> 0
    end.

%%　删除幻化形象
delete_from_dict(Dict, []) ->
    Dict;
delete_from_dict(Dict, [Change|T]) ->
    if
        is_record(Change, upgrade_change) =:= true ->
            Key = integer_to_list(Change#upgrade_change.mid) ++ integer_to_list(Change#upgrade_change.type_id),
            Dict1 = dict:erase(Key, Dict),
            delete_from_dict(Dict1, T);
        true ->
            delete_from_dict(Dict, T)
    end.



%% 检查幻化形象是否过去
check_time([], PS, L) ->
    [PS, L];
check_time([Upgrade|T], PS, L) ->
    NowTime = util:unixtime(),
    if
        is_record(Upgrade, upgrade_change) =:= true andalso (Upgrade#upgrade_change.time > NowTime orelse Upgrade#upgrade_change.time =:= 0) ->
            check_time(T, PS, [Upgrade|L]);
        Upgrade#upgrade_change.time =< NowTime andalso Upgrade#upgrade_change.time > 0 ->
            DeSQL = io_lib:format(?SQL_DELETE_UPGRADE_CHANGE, [Upgrade#upgrade_change.mid,
                                                             Upgrade#upgrade_change.type_id,
                                                             Upgrade#upgrade_change.time,
                                                             Upgrade#upgrade_change.state, PS#player_status.id]),
            db:execute(DeSQL), 
            Mou = PS#player_status.mount,
            Key = integer_to_list(Upgrade#upgrade_change.mid) ++ integer_to_list(Upgrade#upgrade_change.type_id),
            Dict = dict:erase(Key, Mou#status_mount.change_dict),
            %% 换形象
            case lib_mount:get_mount_info(Upgrade#upgrade_change.mid, Mou#status_mount.mount_dict) of
                [Mount] ->
                    %% 形象id = type + 强化等级数
                    Type = get_figure_by_level(Mount#ets_mount.level),
                    Figure = list_to_integer(integer_to_list(Type)++integer_to_list(1)),
                    NewMount1 = Mount#ets_mount{figure = Figure},
                    NewMount = lib_mount2:count_mount_attribute(NewMount1),
                    change_mount_figure_power(Figure, NewMount#ets_mount.combat_power, NewMount#ets_mount.id),
                    Dict2 = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, Mou#status_mount.mount_dict),
                    if
                        Mou#status_mount.mount_figure > 0 ->
                            NewPS = PS#player_status{mount=Mou#status_mount{mount_dict=Dict2, change_dict=Dict,mount_figure=Figure}};
                        true ->
                            NewPS = PS#player_status{mount=Mou#status_mount{mount_dict=Dict2, change_dict=Dict}}
                    end,
                    NewPS1 = lib_player:count_player_attribute(NewPS),
                    check_time(T, NewPS1, L);
                _ ->
                    check_time(T, PS, L)
            end;
        true ->
            check_time(T, PS, L)
    end.
    

%% 通过进阶level来获取形象id(mound_id)
get_figure_by_level(Level) ->
    AllList = data_mount:get_upgrade_all(),
    fix_figure(AllList, Level, []).
fix_figure([], _Level, L) ->
    L;
fix_figure([MountId|H], Level, L) ->
    case data_mount:get_mount_upgrade(MountId) of
        [] ->
            fix_figure(H, Level, L);
        Upgrade ->
            if
%%                 is_record(Upgrade, mount_upgrade) =:= true andalso Upgrade#mount_upgrade.level =:= Level andalso Level =:=2 ->
%%                     311006;
                is_record(Upgrade, mount_upgrade) =:= true andalso Upgrade#mount_upgrade.level =:= Level ->
                    Upgrade#mount_upgrade.mount_id;
                true ->
                    fix_figure(H, Level, L)
            end
    end.
    

%% 更新坐骑形象id
update(PS, Mount, Figure) ->
    Mou = PS#player_status.mount,
    NewMount = Mount#ets_mount{figure = Figure},
    change_mount_figure(Figure, NewMount#ets_mount.id),
    Dict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, Mou#status_mount.mount_dict),
    if
        Mount#ets_mount.status =:= 2 -> Fig = Figure;
        true -> Fig = 0
    end,
    NewPS = PS#player_status{mount=Mou#status_mount{mount_dict=Dict, mount_figure=Fig}},
    {ok, BinData1} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, 
                                          NewPS#player_status.server_num, NewPS#player_status.speed, Fig]),
    lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, 
                                       NewPS#player_status.x, NewPS#player_status.y, BinData1),
    {ok, BinData} = pt_160:write(16031, [1, Figure]),
    lib_server_send:send_one(NewPS#player_status.socket, BinData),
    NewPS.

change_mount_figure(Figure, Mid) ->
    Sql = io_lib:format(?SQL_CHANGE_FIGURE, [Figure, Mid]),
    db:execute(Sql).

change_mount_figure_power(Figure, Power, Mid) ->
    Sql = io_lib:format(?SQL_UP_FIGURE_AND_POWER, [Figure, Power, Mid]),
    db:execute(Sql).

%%　获取幻化和进阶形象
get_diff_change_figure_list(FigureList)->
    LevelFigure = data_mount:get_upgrade_all(),
    List = lists:foldl(fun(Upgrade, TempList)->
                        case lists:member(Upgrade#upgrade_change.type_id, LevelFigure) of
                            true ->
                                [{Upgrade#upgrade_change.type_id, Upgrade#upgrade_change.state, 
                                  Upgrade#upgrade_change.time, 1}|TempList];
                            false ->
                                [{Upgrade#upgrade_change.type_id, Upgrade#upgrade_change.state, 
                                  Upgrade#upgrade_change.time, 2}|TempList]
                        end
                end, [], FigureList),
    lists:sort(List).

%% 只获取幻化形象
get_change_figure_list(FigureList)->
    LevelFigure = data_mount:get_upgrade_all(),
    List = lists:foldl(fun(Upgrade, TempList)->
                               case lists:member(Upgrade#upgrade_change.type_id, LevelFigure) of
                                   true ->
                                       if
                                           Upgrade#upgrade_change.type_id =:= 311001 ->
                                               [{Upgrade#upgrade_change.type_id, Upgrade#upgrade_change.state, 
                                                 Upgrade#upgrade_change.time}|TempList];
                                           true ->
                                               TempList
                                       end;
                                   false ->
                                       [{Upgrade#upgrade_change.type_id, Upgrade#upgrade_change.state, 
                                         Upgrade#upgrade_change.time}|TempList]
                               end
                       end, [], FigureList),
    lists:sort(List).

%% 获取幻化形象添加的属性
get_figure_attr(FigureList)->
    ChangeFigureList = [FigureId || {FigureId, _State, _Time, Type} <- FigureList, Type=:=2],
    case ChangeFigureList of
        [] -> [];
        ChangeFigureList ->
            lib_mount2:get_attr_from_figure(ChangeFigureList)
    end.



%% 针对灵犀属性写的将上限放进列表
format_list_by_type([], _LingXiLimAttr, TempList) ->
    TempList;
format_list_by_type([H|N], LingXiLimAttr, TempList) ->
    {Type, Value} =  H,
    case lists:keyfind(Type, 1, LingXiLimAttr) of
        false -> LimValue = 1000;
        {_, LimValue} -> LimValue
    end,
    format_list_by_type(N, LingXiLimAttr, [{Type, Value, LimValue}|TempList]).



