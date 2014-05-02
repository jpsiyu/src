%%%--------------------------------------
%%% @Module  : lib_mount_repair
%%% @Author  : xyj
%%% @Created : 2012.11.13
%%% @Description: 修复坐骑
%%%-------------------------------------

-module(lib_mount_repair).
-compile(export_all).
-include("mount.hrl").
-include("server.hrl").
-include("goods.hrl").

is_change(Dict, TypeId, Mid) ->
    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#upgrade_change.type_id =:= TypeId andalso Value#upgrade_change.mid =:= Mid end, Dict),
    DictList = dict:to_list(Dict1),
    List = lib_goods_dict:get_list(DictList, []),
    case List =/= [] of
        true ->
            yes;
        false ->
            no
    end.
   
get_change(TypeId, Mid, Pid) ->
    Change = #upgrade_change{
        mid = Mid,
        pid = Pid,
        time = 0,
        type_id = TypeId,
        state = 3
    },
    Change.

%% 修复幻化, 三阶以下
repair_low_level(PS, Mou, Mount) ->
    case Mount#ets_mount.status =:= 2 of
        true ->
            M1 = is_change(Mou#status_mount.change_dict, 311001, Mount#ets_mount.id),
            M2 = is_change(Mou#status_mount.change_dict, 311002, Mount#ets_mount.id),
            M4 = is_change(Mou#status_mount.change_dict, 311004, Mount#ets_mount.id),
            M6 = is_change(Mou#status_mount.change_dict, 311006, Mount#ets_mount.id),
            if
                Mount#ets_mount.type_id =:= 311002 ->

                    if
                        M1 =:= no ->
                            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311001]),
                            db:execute(Sql);
                        M2 =:= no ->
                            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311002]),
                            db:execute(Sql);
                        M6 =:= no ->
                            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311006]),
                            db:execute(Sql);
                        true ->
                            skip
                    end;
                Mount#ets_mount.type_id =:= 311004 ->
                    if
                        M1 =:= no ->
                            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311001]),
                            db:execute(Sql);
                        M4 =:= no ->
                            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311004]),
                            db:execute(Sql);
                        M6 =:= no ->
                            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311006]),
                            db:execute(Sql);
                        true ->
                            skip
                    end;
                Mount#ets_mount.type_id =:= 311006 ->
                    if
                        M1 =:= no ->
                            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311001]),
                            db:execute(Sql);
                        M6 =:= no ->
                            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311006]),
                            db:execute(Sql);
                        true ->
                            skip
                    end;
                Mount#ets_mount.type_id =:= 311001 ->
                    if
                        M1 =:= no ->
                            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311001]),
                            db:execute(Sql);
                        true ->
                            skip
                    end;
                true ->
                    skip
            end;
        false ->
            skip
    end.

%% 高阶
repair_high_level(Mount, Mou, Pid) ->
    Sql = io_lib:format(<<"select old_type from log_mount_upgrade where mount_id=~p and new_type=311008 and status=1 and role_id=~p limit 1">>, [Mount#ets_mount.id, Pid]),
    case db:get_row(Sql) of
        [] ->
            List = lib_mount2:get_figure_list(Mount#ets_mount.level);
        OldId ->
            List = lib_mount2:get_figure_list(Mount#ets_mount.level) ++ OldId
    end,
    F = fun(Mid) ->
            M = is_change(Mou#status_mount.change_dict, Mid, Mount#ets_mount.id),
            if
                M =:= no ->
                    Sql1 = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, Pid, Mid]),
                    db:execute(Sql1);
                true ->
                    skip
            end
    end,
    [F(Mid) || Mid <- List].

%% 修复幻化
repair_mount_change(PS) ->
    D = dict:new(),
    Mou = PS#player_status.mount,
    Mount = lib_mount:get_equip_mount(PS#player_status.id, Mou#status_mount.mount_dict),
    if
        Mount#ets_mount.level >= 3 ->
            repair_high_level(Mount, Mou, PS#player_status.id);
        true ->
            repair_low_level(PS, Mou, Mount)
    end,
    NewDict = lib_mount:mount_change_init(PS#player_status.id, D),
    S1 = dict:size(NewDict),
    S2 = dict:size(Mou#status_mount.mount_dict),
    io:format("~p ~p S1:~p, S2:~p~n", [?MODULE, ?LINE, S1, S2]),
    if
        S1 > S2 ->
            NewMou = Mou#status_mount{change_dict = NewDict},
            NewPS = PS#player_status{mount = NewMou};
        true ->
            NewPS = PS
    end,
    NewPS.

get_out_repair(PS, Mount) ->
    case Mount#ets_mount.status =:= 1 of
        true ->
            if
                Mount#ets_mount.type_id =:= 311001 ->
                    NewPS = repair(PS, Mount, 311001);
                Mount#ets_mount.type_id =:= 311002 ->
                    NewPS = repair(PS, Mount, 311002);
                Mount#ets_mount.type_id =:= 311004 ->
                    NewPS = repair(PS, Mount, 311004);
                Mount#ets_mount.type_id =:= 311006 ->
                    NewPS = repair(PS, Mount, 311006);
                true ->
                    D = dict:new(),
                    Mou = PS#player_status.mount,
                    repair_high_level(Mount, Mou, PS#player_status.id),
                    NewDict = lib_mount:mount_change_init(PS#player_status.id, D),
                    NewMou = Mou#status_mount{change_dict = NewDict},
                    NewPS = PS#player_status{mount = NewMou}
            end;
        false ->
            NewPS = PS
    end,
    NewPS.

repair(PS, Mount, 311001) ->
    %io:format("come 311001.......~n"),
    Mou = PS#player_status.mount,
    case is_change(Mou#status_mount.change_dict, 311001, Mount#ets_mount.id) =:= no of
        true ->
            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311001]),
            db:execute(Sql),
            Change1 = get_change(311001, Mount#ets_mount.id, PS#player_status.id),
            Key = integer_to_list(Change1#upgrade_change.mid) ++ integer_to_list(Change1#upgrade_change.type_id),
            NewDict1 = lib_mount:add_dict(Key, Change1, Mou#status_mount.change_dict),
            NewMou1 = Mou#status_mount{change_dict = NewDict1},
            NewPS = PS#player_status{mount = NewMou1};
        false ->
            NewPS = PS
    end,
    NewPS;

repair(PS, Mount, 311002) ->
    %io:format("come 311002.......~n"),
    Mou = PS#player_status.mount,
    case is_change(Mou#status_mount.change_dict, 311001, Mount#ets_mount.id) =:= no of
        true ->
            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311001]),
            db:execute(Sql),
            Change1 = get_change(311001, Mount#ets_mount.id, PS#player_status.id),
            Key1 = integer_to_list(Change1#upgrade_change.mid) ++ integer_to_list(Change1#upgrade_change.type_id),
            NewDict1 = lib_mount:add_dict(Key1, Change1, Mou#status_mount.change_dict),
            NewMou1 = Mou#status_mount{change_dict = NewDict1},
            NewPS = PS#player_status{mount = NewMou1};
        false ->
            NewMou1 = Mou,
            NewPS = PS
    end,
    case is_change(NewMou1#status_mount.change_dict, 311002, Mount#ets_mount.id) =:= no of
        true ->
            Sql1 = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311002]),
            db:execute(Sql1),
            Change2 = get_change(311002, Mount#ets_mount.id, PS#player_status.id),
            Key2 = integer_to_list(Change2#upgrade_change.mid) ++ integer_to_list(Change2#upgrade_change.type_id),
            NewDict2 = lib_mount:add_dict(Key2, Change2, NewMou1#status_mount.change_dict),
            NewMou2 = NewMou1#status_mount{change_dict = NewDict2},
            NewPS2 = NewPS#player_status{mount = NewMou2};
        false ->
            NewMou2 = NewMou1,
            NewPS2 = NewPS
    end,
    case is_change(NewMou2#status_mount.change_dict, 311006, Mount#ets_mount.id) =:= no of
        true ->
            Sql2 = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311006]),
            db:execute(Sql2),
            Change3 = get_change(311006, Mount#ets_mount.id, PS#player_status.id),
            Key3 = integer_to_list(Change3#upgrade_change.mid) ++ integer_to_list(Change3#upgrade_change.type_id),
            NewDict3 = lib_mount:add_dict(Key3, Change3, NewMou2#status_mount.change_dict),
            NewMou3 = NewMou2#status_mount{change_dict = NewDict3},
            NewPS3 = NewPS2#player_status{mount = NewMou3};
        false ->
            NewPS3 = NewPS2
    end,
    NewPS3;

repair(PS, Mount, 311004) ->
    %io:format("come 311004.......~n"),
    Mou = PS#player_status.mount,
    case is_change(Mou#status_mount.change_dict, 311001, Mount#ets_mount.id) =:= no of
        true ->
            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311001]),
            db:execute(Sql),
            Change1 = get_change(311001, Mount#ets_mount.id, PS#player_status.id),
            Key1 = integer_to_list(Change1#upgrade_change.mid) ++ integer_to_list(Change1#upgrade_change.type_id),
            NewDict1 = lib_mount:add_dict(Key1, Change1, Mou#status_mount.change_dict),
            NewMou1 = Mou#status_mount{change_dict = NewDict1},
            NewPS = PS#player_status{mount = NewMou1};
        false ->
            NewMou1 = Mou,
            NewPS = PS
    end,
    case is_change(NewMou1#status_mount.change_dict, 311004, Mount#ets_mount.id) =:= no of
        true ->
            Sql1 = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311004]),
            db:execute(Sql1),
            Change2 = get_change(311004, Mount#ets_mount.id, PS#player_status.id),
            Key2 = integer_to_list(Change2#upgrade_change.mid) ++ integer_to_list(Change2#upgrade_change.type_id),
            NewDict2 = lib_mount:add_dict(Key2, Change2, NewMou1#status_mount.change_dict),
            NewMou2 = NewMou1#status_mount{change_dict = NewDict2},
            NewPS2 = NewPS#player_status{mount = NewMou2};
        false ->
            NewMou2 = NewMou1,
            NewPS2 = NewPS
    end,
    case is_change(NewMou2#status_mount.change_dict, 311006, Mount#ets_mount.id) =:= no of
        true ->
            Sql2 = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311006]),
            db:execute(Sql2),
            Change3 = get_change(311006, Mount#ets_mount.id, PS#player_status.id),
            Key3 = integer_to_list(Change3#upgrade_change.mid) ++ integer_to_list(Change3#upgrade_change.type_id),
            NewDict3 = lib_mount:add_dict(Key3, Change3, NewMou2#status_mount.change_dict),
            NewMou3 = NewMou2#status_mount{change_dict = NewDict3},
            NewPS3 = NewPS2#player_status{mount = NewMou3};
        false ->
            NewPS3 = NewPS2
    end,
    NewPS3;

repair(PS, Mount, 311006) ->
    %io:format("come 311006.......~n"),
    Mou = PS#player_status.mount,
    case is_change(Mou#status_mount.change_dict, 311001, Mount#ets_mount.id) =:= no of
        true ->
            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311001]),
            db:execute(Sql),
            Change1 = get_change(311001, Mount#ets_mount.id, PS#player_status.id),
            Key1 = integer_to_list(Change1#upgrade_change.mid) ++ integer_to_list(Change1#upgrade_change.type_id),
            NewDict1 = lib_mount:add_dict(Key1, Change1, Mou#status_mount.change_dict),
            NewMou1 = Mou#status_mount{change_dict = NewDict1},
            NewPS = PS#player_status{mount = NewMou1};
        false ->
            NewMou1 = Mou,
            NewPS = PS
    end,
    case is_change(NewMou1#status_mount.change_dict, 311006, Mount#ets_mount.id) =:= no of
        true ->
            Sql1 = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, 311006]),
            db:execute(Sql1),
            Change2 = get_change(311006, Mount#ets_mount.id, PS#player_status.id),
            Key2 = integer_to_list(Change2#upgrade_change.mid) ++ integer_to_list(Change2#upgrade_change.type_id),
            NewDict2 = lib_mount:add_dict(Key2, Change2, NewMou1#status_mount.change_dict),
            NewMou2 = NewMou1#status_mount{change_dict = NewDict2},
            NewPS2 = NewPS#player_status{mount = NewMou2};
        false ->
            NewPS2 = NewPS
    end,
    NewPS2.

%% 增加幻化
add_change(PS, Mou, Mount) ->
    M = is_change(Mou#status_mount.change_dict, Mount#ets_mount.type_id, Mount#ets_mount.id),
    if
        M =:= no ->
            NewMou = PS#player_status.mount,
            Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, Mount#ets_mount.type_id]),
            db:execute(Sql),
            Change = get_change(Mount#ets_mount.type_id, Mount#ets_mount.id, PS#player_status.id),
            Key = integer_to_list(Change#upgrade_change.mid) ++ integer_to_list(Change#upgrade_change.type_id),
            NewDict1 = lib_mount:add_dict(Key, Change, NewMou#status_mount.change_dict),
            NewMou1 = NewMou#status_mount{change_dict = NewDict1},
            NewPS = PS#player_status{mount = NewMou1};
        true ->
            NewPS = PS
    end,
    NewPS.

%% %% 增加幻化
%% add_change(PS, Mou, Mount) ->
%%     M = is_change(Mou#status_mount.change_dict, Mount#ets_mount.type_id, Mount#ets_mount.id),
%%     if
%%         M =:= no ->
%%             Sql = io_lib:format(?SQL_REPAIR, [Mount#ets_mount.id, PS#player_status.id, Mount#ets_mount.type_id]),
%%             db:execute(Sql),
%%             Change = get_change(Mount#ets_mount.type_id, Mount#ets_mount.id, PS#player_status.id),
%%             Key = integer_to_list(Change#upgrade_change.mid) ++ integer_to_list(Change#upgrade_change.type_id),
%%             NewDict1 = lib_mount:add_dict(Key, Change, Mou#status_mount.change_dict),
%%             NewMou1 = Mou#status_mount{change_dict = NewDict1},
%%             NewPS = PS#player_status{mount = NewMou1};
%%         true ->
%%             NewPS = PS
%%     end,
%%     NewPS.
