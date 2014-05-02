%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-9-5
%% Description: 时装形象转换
%% --------------------------------------------------------
-module(lib_fashion_change2).
-compile(export_all).
-include("fashion.hrl").
-include("errcode_goods.hrl").
-include("def_goods.hrl").
-include("server.hrl").
-include("goods.hrl").
-include("mount.hrl").

%% 检查有没有时限性时装
init_fashion(Id) ->
    Sql = io_lib:format(?sql_change_select, [Id]),
    case db:get_all(Sql) of
        [] ->
            ok;
        List when is_list(List) ->
            handle_fashion(List);
        _ ->
            ok
    end,
    check_wardrobe(Id).

%% 处理时装
handle_fashion([]) ->
    ok;
handle_fashion([Info|T]) ->
    NowTime = util:unixtime(),
    case Info of
        [_, _, _, _, Ctime, _, _] when Ctime > NowTime ->
            handle_fashion(T);
        [_Cpos, _Cpid, _ColdId, _CnewId, _Ctime, _Original, _Gid] when _Ctime =< NowTime -> %% 过期了
            handle_expire_fashion(_Original, _Gid, _Cpid, _Cpos),
            handle_fashion(T);
        _ ->
            handle_fashion(T)
    end.

%% 检查有没有时限性时衣橱
check_wardrobe(Id) ->
    Sql = io_lib:format(?sql_wardrobe_select, [Id]),
    case db:get_all(Sql) of
        [] ->
            ok;
        List when is_list(List) ->
            handle_wardrobe(List, Id);
        _ ->
            ok
    end.

%% 处理时update_to_dict装
handle_wardrobe([], _) ->
    ok;
handle_wardrobe([Info|T], Id) ->
    NowTime = util:unixtime(),
    case Info of
        [_, _, _, _, Ctime, _] when Ctime > NowTime ->
            handle_wardrobe(T, Id);
        [Id2, _, Pos, GoodsId, _Ctime, _] when _Ctime =< NowTime -> %% 过期了
            if
                _Ctime =/= 0 ->
                    %Sql = io_lib:format(<<"update wardrobe set state = 2 where pid = ~p and time = ~p and pos = ~p limit 1">>, [Id, _Ctime, Pos]),
                    Sql = io_lib:format(<<"update wardrobe set state = 2 where id=~p">>, [Id2]),
                    db:execute(Sql),
                    Sql2 = io_lib:format(<<"select `original`, `gid` from fashion_change where pos = ~p and new_id = ~p and pid = ~p limit 1">>, [Pos, GoodsId, Id]),
                    case db:get_row(Sql2) of
                        [] ->
                            skip;
                        [Original, Gid] ->
                            update_goods_id(Original, Gid)
                    end;
                true ->
                    skip
            end,
            handle_wardrobe(T, Id);
        _ ->
            handle_wardrobe(T, Id)
    end.    

%% 处理过期时装 
handle_expire_fashion(OriginalId, Gid, Pid, Pos) ->
    if 
        Pos =/= 4 ->
            Sql1 = io_lib:format(?sql_update_fashion_goods, [OriginalId, Gid]),
            Sql2 = io_lib:format(?sql_update_fashion_goods2, [OriginalId, Gid]),
            Sql3 = io_lib:format(?sql_change_delete, [Pid, Pos, Gid]),
            db:execute(Sql1),
            db:execute(Sql2),
            db:execute(Sql3);
        true ->
            Flist = integer_to_list(OriginalId) ++ integer_to_list(1),
            Mfigure = list_to_integer(Flist),
            Sql1 = io_lib:format(<<"update mount set type_id = ~p, figure = ~p where id = ~p">>, [OriginalId, Mfigure, Gid]),
            db:execute(Sql1), 
            Sql2 = io_lib:format(?sql_change_delete, [Pid, Pos, Gid]),
            db:execute(Sql2)
    end.

update_goods_id(OriginalId, Gid) ->
    Sql1 = io_lib:format(?sql_update_fashion_goods, [OriginalId, Gid]),
    Sql2 = io_lib:format(?sql_update_fashion_goods2, [OriginalId, Gid]), 
    db:execute(Sql1),
    db:execute(Sql2).

%% 修改为数库类型
change_goods_id(Pid, GoodsId, OldTypeId, NewTypeId, Pos, Days) ->
    %io:format("change_goods_id = ~p~n", [{Pid, GoodsId, OldTypeId, NewTypeId, Pos, Days}]),
    NowTime = util:unixtime(),
    Time = Days * 86400 + NowTime,
    Sql = io_lib:format(<<"select pos from fashion_change where gid = ~p">>, [GoodsId]),
     case db:get_row(Sql) of
         [] ->
             case Days =:= 0 of
                true ->
                    update_goods_id(NewTypeId, GoodsId);
                false ->
                    Sql1 = io_lib:format(?sql_change_insert2, [Pos, Pid, NewTypeId, Time, OldTypeId, GoodsId]),
                    db:execute(Sql1),
                    update_goods_id(NewTypeId, GoodsId)
            end;
        [P] ->
            case Days =:= 0 of
                true ->
                    Sql1 = io_lib:format(<<"update fashion_change set original = ~p where gid = ~p">>, [NewTypeId, GoodsId]),
                    db:execute(Sql1),
                    handle_expire_fashion(OldTypeId, GoodsId, Pid, P);
                false ->
                    Sql1 = io_lib:format(?sql_change_update3, [NewTypeId, Time, GoodsId]),
                    db:execute(Sql1),
                    update_goods_id(NewTypeId, GoodsId)
            end
    end.

%% 坐骑
update_mount(Pid, NewTypeId, Fiurge, MountId, Pos, Flag) ->
    Sql1 = io_lib:format(<<"update mount set type_id = ~p, figure = ~p where id = ~p">>, [NewTypeId, Fiurge, MountId]),
    db:execute(Sql1),
    if
        Flag =:= yes ->
            Sql2 = io_lib:format(?sql_change_delete, [Pid, Pos, MountId]),
            db:execute(Sql2);
        true ->
            skip
    end.

change_mount_id(Pid, MountId, OldTypeId, NewTypeId, Fiurge, Pos, Days) ->
    %io:format("change_mount_id = ~p~n", [{Pid, MountId, OldTypeId, NewTypeId, Fiurge, Pos, Days}]),
    NowTime = util:unixtime(),
    Time = Days * 86400 + NowTime,
    Sql = io_lib:format(<<"select new_id from fashion_change where gid =~p and pos = 4">>, [MountId]),
    case db:get_row(Sql) of
         [] ->
            case Days =:= 0 of
                true ->
                    update_mount(Pid, NewTypeId, Fiurge, MountId, Pos, no);
                false ->
                    Sql1 = io_lib:format(?sql_change_insert2, [Pos, Pid, NewTypeId, Time, OldTypeId, MountId]),
                    db:execute(Sql1),
                    update_mount(Pid, NewTypeId, Fiurge, MountId, Pos, no)
            end;
        [_P] ->
            case Days =:= 0 of
                true ->
                    update_mount(Pid, NewTypeId, Fiurge, MountId, Pos, yes);
                false ->
                    Sql1 = io_lib:format(?sql_change_update4, [NewTypeId, Time, MountId]),
                    db:execute(Sql1),
                    update_mount(Pid, NewTypeId, Fiurge, MountId, Pos, no)
            end
    end.

%% 修改缓存
update_to_dict(Id, GoodsStatus, NewGoodsTypeId) ->
    Info = lib_goods_util:get_goods_info(Id, GoodsStatus#goods_status.dict),
    NewInfo = Info#goods{goods_id = NewGoodsTypeId},
    Dict = lib_goods_dict:add_dict_goods(NewInfo, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    NewStatus.

%% 添加装备变幻
add_fashion_change(PlayerStatus, GoodsInfo, Pos, GoodsStatus) ->
    Goods = PlayerStatus#player_status.goods,
    GoodsList = lib_goods_util:get_equip_list(PlayerStatus#player_status.id, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, GoodsStatus#goods_status.dict),
    case data_fashion_change:get_info(GoodsInfo#goods.goods_id, PlayerStatus#player_status.career) of
        [0,0] ->
            %% 形象类型不存在
            {fail, ?ERRCODE15_NO_GOODS_TYPE};   
        [Figure, Days] ->
            case Pos of
                1 ->    %%衣服
                    [Armor, S1] = Goods#status_goods.fashion_armor,
                    Id1 = lib_fashion_change:get_fashion_id(GoodsList, 1),
                    if  
                        Armor =< 0 orelse Id1 =< 0 -> %% 您未穿戴任何时装
                            {fail, ?ERRCODE15_FASHION_NONE};
                        Days >= 0 andalso Figure > 0 ->      %% 有时限性
                            change_goods_id(PlayerStatus#player_status.id, Id1, Armor, Figure, Pos, Days),
                            NewPS = update_wardrobe(PlayerStatus, Pos, Days, Figure),
                            NewStatus = update_to_dict(Id1, GoodsStatus, Figure),
                            NewPlayerStatus = NewPS#player_status{goods=Goods#status_goods{fashion_armor=[Figure,S1]}},
                            get_wear_degree(NewPlayerStatus),
                            {ok, NewPlayerStatus, NewStatus};
                        true ->
                            {fail, ?ERRCODE15_NO_GOODS_TYPE}
                    end;
                2 ->    %% 武器
                    [Weapon, S2] = Goods#status_goods.fashion_weapon,
                    Id2 = lib_fashion_change:get_fashion_id(GoodsList, 2),
                    if  
                        Weapon =< 0 orelse Id2 =< 0 -> %% 您未穿戴任何时装
                            {fail, ?ERRCODE15_FASHION_NONE};
                        Days >= 0 andalso Figure > 0 ->      %% 有时限性
                            change_goods_id(PlayerStatus#player_status.id, Id2, Weapon, Figure, Pos, Days),
                            NewPS = update_wardrobe(PlayerStatus, Pos, Days, Figure),
                            NewStatus = update_to_dict(Id2, GoodsStatus, Figure),
                            NewPlayerStatus = NewPS#player_status{goods=Goods#status_goods{fashion_weapon=[Figure,S2]}},
                            {ok, NewPlayerStatus, NewStatus};
                        true ->
                            {fail, ?ERRCODE15_NO_GOODS_TYPE}
                    end;
                3 ->    %% 饰品
                    [Accessory, S3] = Goods#status_goods.fashion_accessory,
                    Id3 = lib_fashion_change:get_fashion_id(GoodsList, 3),
                    if  
                        Accessory =< 0 orelse Id3 =< 0 -> %% 您未穿戴任何时装
                            {fail, ?ERRCODE15_FASHION_NONE};
                        Days >= 0 andalso Figure > 0 ->      %% 有时限性
                            change_goods_id(PlayerStatus#player_status.id, Id3, Accessory, Figure, Pos, Days),
                            NewPS = update_wardrobe(PlayerStatus, Pos, Days, Figure),
                            NewStatus = update_to_dict(Id3, GoodsStatus, Figure),
                            NewPlayerStatus = NewPS#player_status{goods=Goods#status_goods{fashion_accessory=[Figure,S3]}},
                            get_wear_degree(NewPlayerStatus),
                            {ok, NewPlayerStatus, NewStatus};
                        true ->
                            {fail, ?ERRCODE15_NO_GOODS_TYPE}
                    end;
                5 -> %% 头饰
                    [Head, S5] = Goods#status_goods.fashion_head,
                    Id5 = lib_fashion_change:get_fashion_id(GoodsList, 5),
                    if
                        Head =< 0 orelse Id5 =< 0 -> %% 您未穿戴任何时装
                            {fail, ?ERRCODE15_FASHION_NONE};
                        Days >= 0 andalso Figure > 0 -> %% 有时限性
                            %change_goods_id(PlayerStatus#player_status.id, Id5, Head, Figure, Pos, Days),
                            NewPS = update_wardrobe(PlayerStatus, Pos, Days, Figure),
                            NewStatus = update_to_dict(Id5, GoodsStatus, Figure),
                            NewPlayerStatus =
                            NewPS#player_status{goods=Goods#status_goods{fashion_head=[Figure,S5]}},
                            get_wear_degree(NewPlayerStatus),
                            {ok, NewPlayerStatus, NewStatus};
                        true ->
                            {fail, ?ERRCODE15_NO_GOODS_TYPE}
                    end;
                6 -> %% 尾饰
                    [TAIL, S6] = Goods#status_goods.fashion_tail,
                    Id6 = lib_fashion_change:get_fashion_id(GoodsList, 6),
                    if
                        TAIL =< 0 orelse Id6 =< 0 -> %% 您未穿戴任何时装
                            {fail, ?ERRCODE15_FASHION_NONE};
                        Days >= 0 andalso Figure > 0 -> %% 有时限性
                            %change_goods_id(PlayerStatus#player_status.id, Id6, TAIL, Figure, Pos, Days),
                            NewPS = update_wardrobe(PlayerStatus, Pos, Days, Figure),
                            NewStatus = update_to_dict(Id6, GoodsStatus, Figure),
                            NewPlayerStatus =
                            NewPS#player_status{goods=Goods#status_goods{fashion_tail=[Figure,S6]}},
                            get_wear_degree(NewPlayerStatus),
                            {ok, NewPlayerStatus, NewStatus};
                        true ->
                            {fail, ?ERRCODE15_NO_GOODS_TYPE}
                    end;
                7 -> %% 戒指饰
                    [Ring, S7] = Goods#status_goods.fashion_ring,
                    Id7 = lib_fashion_change:get_fashion_id(GoodsList, 7),
                    if
                        Ring =< 0 orelse Id7 =< 0 -> %% 您未穿戴任何时装
                            {fail, ?ERRCODE15_FASHION_NONE};
                        Days >= 0 andalso Figure > 0 -> %% 有时限性
                            %change_goods_id(PlayerStatus#player_status.id, Id7, Ring, Figure, Pos, Days),
                            NewPS = update_wardrobe(PlayerStatus, Pos, Days, Figure),
                            NewStatus = update_to_dict(Id7, GoodsStatus, Figure),
                            NewPlayerStatus =
                            NewPS#player_status{goods=Goods#status_goods{fashion_ring=[Figure,S7]}},
                            get_wear_degree(NewPlayerStatus),
                            {ok, NewPlayerStatus, NewStatus};
                        true ->
                            {fail, ?ERRCODE15_NO_GOODS_TYPE}
                    end;
                4 ->    %% 坐骑
                    Mount = PlayerStatus#player_status.mount,
                    M = lib_mount:get_equip_mount(PlayerStatus#player_status.id, Mount#status_mount.mount_dict),
                    %io:format("mount_figure = ~p~n", [{Mount#status_mount.mount_figure, M#ets_mount.id}]),
                    if  
                        M#ets_mount.id =< 0 -> %% 坐骑未出战
                            {fail, ?ERRCODE15_FASHION_NONE};
                        Days >= 0 andalso Figure > 0 ->      
                            Flist = integer_to_list(Figure) ++ integer_to_list(1),
                            Mfigure = list_to_integer(Flist),
                            change_mount_id(PlayerStatus#player_status.id, M#ets_mount.id, M#ets_mount.type_id, Figure, Mfigure, Pos, Days),
                            NewMount = M#ets_mount{type_id = Figure, figure = Mfigure},
                            Dict = lib_mount:add_dict(M#ets_mount.id, NewMount, Mount#status_mount.mount_dict),
                            NewPlayerStatus = PlayerStatus#player_status{mount=Mount#status_mount{mount_figure=Mfigure, mount_dict = Dict}},
                            {ok, NewPlayerStatus};
                        true ->
                            {fail, ?ERRCODE15_NO_GOODS_TYPE}
                    end
            end
    end.

%% --------------------------------------------------- 衣橱 -----------------------------------
%% 初始化
init_wardrobe(Id) ->
    Dict = dict:new(),
    Sql = io_lib:format(?sql_wardrobe_select, [Id]),
    case db:get_all(Sql) of
        [] -> 
            Dict2 = Dict;
        List when is_list(List) ->
            Dict2 = insert_dict(List, Dict);
        _ ->
            Dict2 = Dict
    end,
    Dict2.              

insert_dict([], Dict) ->
    Dict;
insert_dict([Info|T], Dict) ->
    case make_wardrobe_info(Info) of
        [] ->
            Dict2 = Dict;
        Wardrobe ->
            Key = Wardrobe#ets_wardrobe.goods_id,
            Dict2 = lib_mount:add_dict(Key, Wardrobe, Dict)
    end,
    insert_dict(T, Dict2).

make_wardrobe_info(Info) ->
    case Info of
        [Id, Pid, Pos, GoodsId, Time, State] ->
            Wardrobe = #ets_wardrobe{
                id = Id,
                pid = Pid,
                pos = Pos,
                goods_id = GoodsId,
                time = Time,
                state = State
            },
            Wardrobe;
        _ ->
            []
    end.
             
%% 激活时装
update_wardrobe(PS, Pos, Days, GoodsId) ->
    NowTime = util:unixtime(),
    case Days =/= 0 of
        true ->
            Time = NowTime + Days * 86400,
            State = 1;
        false ->
            Time = 0,
            State = 3
    end,
    case dict:is_key(GoodsId, PS#player_status.wardrobe) of
        true ->
            [W] = dict:fetch(GoodsId, PS#player_status.wardrobe),
            if
                W#ets_wardrobe.state =/= 3 andalso Days =/= 0 andalso W#ets_wardrobe.time >= NowTime ->
                    T1 = W#ets_wardrobe.time + Days * 86400,
                    S1 = W#ets_wardrobe.state;
                W#ets_wardrobe.state =/= 3 andalso Days =/= 0 andalso W#ets_wardrobe.time < NowTime ->
                    T1 = NowTime + Days * 86400,
                    S1 = 1;
                true ->
                    T1 = 0,
                    S1 = 3
            end,
            NewW = W#ets_wardrobe{time = T1, state = S1},
            Dict = lib_mount:add_dict(GoodsId, NewW, PS#player_status.wardrobe),
            %Sql = io_lib:format(<<"update wardrobe set time = ~p, state = ~p where pid = ~p and goods_id = ~p">>, [T1, S1, PS#player_status.id, GoodsId]),
            Sql = io_lib:format(<<"update wardrobe set time = ~p, state = ~p where id = ~p">>, [T1, S1, W#ets_wardrobe.id]),
            db:execute(Sql),
            NewPS = PS#player_status{wardrobe = Dict};
        false ->
            W = #ets_wardrobe{
                pid = PS#player_status.id,
                pos = Pos,
                time = Time,
                state = State,
                goods_id = GoodsId
            },
            Sql = io_lib:format(<<"insert into wardrobe set pid = ~p, goods_id =~p, time = ~p, pos = ~p, state = ~p">>, [PS#player_status.id, GoodsId, Time, Pos, State]),
            db:execute(Sql),
            Dict = lib_mount:add_dict(GoodsId, W, PS#player_status.wardrobe),
            NewPS = PS#player_status{wardrobe = Dict}
    end,
    NewPS.

%% 替换时装
replace_wardrobe(PlayerStatus, M, GoodsStatus) ->
    Goods = PlayerStatus#player_status.goods,
    GoodsList = lib_goods_util:get_equip_list(PlayerStatus#player_status.id, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, GoodsStatus#goods_status.dict),
    case M#ets_wardrobe.pos of
        1 ->
             %%衣服
            [Armor, S1] = Goods#status_goods.fashion_armor,
            Id1 = lib_fashion_change:get_fashion_id(GoodsList, 1),
            if  
                Armor =< 0 orelse Id1 =< 0 -> %% 您未穿戴任何时装
                    {fail, 2};
                true ->
                    case M#ets_wardrobe.state =:= 3 andalso M#ets_wardrobe.time =:= 0 of
                        true ->     %%永久
                            NewStatus = update_to_dict(Id1, GoodsStatus, M#ets_wardrobe.goods_id), 
                            NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_armor=[ M#ets_wardrobe.goods_id,S1]}},
                            update_goods_id(M#ets_wardrobe.goods_id, Id1),
                            {ok, NewPlayerStatus, NewStatus};
                        false ->
                            replace_update_id(PlayerStatus#player_status.id, M#ets_wardrobe.time,  M#ets_wardrobe.pos, M#ets_wardrobe.goods_id),
                            update_goods_id(M#ets_wardrobe.goods_id, Id1),
                            NewStatus = update_to_dict(Id1, GoodsStatus, M#ets_wardrobe.goods_id), 
                            NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_armor=[M#ets_wardrobe.goods_id,S1]}},
                            {ok, NewPlayerStatus, NewStatus}
                    end
            end;
        2 ->    %% 武器
            [Weapon, S2] = Goods#status_goods.fashion_weapon,
            Id2 = lib_fashion_change:get_fashion_id(GoodsList, 2),
            if  
                Weapon =< 0 orelse Id2 =< 0 -> %% 您未穿戴任何时装
                    {fail, 2};
                true ->
            case M#ets_wardrobe.state =:= 3 andalso M#ets_wardrobe.time =:= 0 of
                true ->     %%永久
                    NewStatus = update_to_dict(Id2, GoodsStatus, M#ets_wardrobe.goods_id), 
                    NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_weapon=[M#ets_wardrobe.goods_id,S2]}},
                    update_goods_id(M#ets_wardrobe.goods_id, Id2),
                    {ok, NewPlayerStatus, NewStatus};
                false ->
                    replace_update_id(PlayerStatus#player_status.id, M#ets_wardrobe.time,  M#ets_wardrobe.pos, M#ets_wardrobe.goods_id),
                    update_goods_id(M#ets_wardrobe.goods_id, Id2),
                    NewStatus = update_to_dict(Id2, GoodsStatus, M#ets_wardrobe.goods_id), 
                    NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_weapon=[M#ets_wardrobe.goods_id,S2]}},
                    {ok, NewPlayerStatus, NewStatus}
            end
            end;
        3 ->
            [Accessory, S3] = Goods#status_goods.fashion_accessory,
            Id3 = lib_fashion_change:get_fashion_id(GoodsList, 3),
            if  
                Accessory =< 0 orelse Id3 =< 0 -> %% 您未穿戴任何时装
                    {fail, 2};
                true ->
            case M#ets_wardrobe.state =:= 3 andalso M#ets_wardrobe.time =:= 0 of
                true ->     %%永久
                    NewStatus = update_to_dict(Id3, GoodsStatus, M#ets_wardrobe.goods_id), 
                    update_goods_id(M#ets_wardrobe.goods_id, Id3),
                    NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_accessory=[M#ets_wardrobe.goods_id,S3]}},
                    {ok, NewPlayerStatus, NewStatus};
                false ->
                    replace_update_id(PlayerStatus#player_status.id, M#ets_wardrobe.time,  M#ets_wardrobe.pos, M#ets_wardrobe.goods_id),
                    update_goods_id(M#ets_wardrobe.goods_id, Id3),
                    NewStatus = update_to_dict(Id3, GoodsStatus, M#ets_wardrobe.goods_id), 
                    NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_accessory=[M#ets_wardrobe.goods_id,S3]}},
                    {ok, NewPlayerStatus, NewStatus}
            end
        end;
        5 ->
            [Head, S5] = Goods#status_goods.fashion_head,
            Id5 = lib_fashion_change:get_fashion_id(GoodsList, 5),
            if  
                Head =< 0 orelse Id5 =< 0 -> %% 您未穿戴任何时装
                    {fail, 2};
                true ->
            case M#ets_wardrobe.state =:= 3 andalso M#ets_wardrobe.time =:= 0 of
                true ->     %%永久
                    NewStatus = update_to_dict(Id5, GoodsStatus, M#ets_wardrobe.goods_id), 
                    update_goods_id(M#ets_wardrobe.goods_id, Id5),
                    NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_head=[M#ets_wardrobe.goods_id,S5]}},
                    {ok, NewPlayerStatus, NewStatus};
                false ->
                    replace_update_id(PlayerStatus#player_status.id, M#ets_wardrobe.time,  M#ets_wardrobe.pos, M#ets_wardrobe.goods_id),
                    update_goods_id(M#ets_wardrobe.goods_id, Id5),
                    NewStatus = update_to_dict(Id5, GoodsStatus, M#ets_wardrobe.goods_id), 
                    NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_head=[M#ets_wardrobe.goods_id,S5]}},
                    {ok, NewPlayerStatus, NewStatus}
            end
        end;
        6 ->
            [Tail, S6] = Goods#status_goods.fashion_tail,
            Id6 = lib_fashion_change:get_fashion_id(GoodsList, 6),
            if  
                Tail =< 0 orelse Id6 =< 0 -> %% 您未穿戴任何时装
                    {fail, 2};
                true ->
            case M#ets_wardrobe.state =:= 3 andalso M#ets_wardrobe.time =:= 0 of
                true ->     %%永久
                    NewStatus = update_to_dict(Id6, GoodsStatus, M#ets_wardrobe.goods_id), 
                    update_goods_id(M#ets_wardrobe.goods_id, Id6),
                    NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_tail=[M#ets_wardrobe.goods_id,S6]}},
                    {ok, NewPlayerStatus, NewStatus};
                false ->
                    replace_update_id(PlayerStatus#player_status.id, M#ets_wardrobe.time,  M#ets_wardrobe.pos, M#ets_wardrobe.goods_id),
                    update_goods_id(M#ets_wardrobe.goods_id, Id6),
                    NewStatus = update_to_dict(Id6, GoodsStatus, M#ets_wardrobe.goods_id), 
                    NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_tail=[M#ets_wardrobe.goods_id,S6]}},
                    {ok, NewPlayerStatus, NewStatus}
            end
        end;
        7 ->
            [Ring, S7] = Goods#status_goods.fashion_ring,
            Id7 = lib_fashion_change:get_fashion_id(GoodsList, 7),
            if  
                Ring =< 0 orelse Id7 =< 0 -> %% 您未穿戴任何时装
                    {fail, 2};
                true ->
            case M#ets_wardrobe.state =:= 3 andalso M#ets_wardrobe.time =:= 0 of
                true ->     %%永久
                    NewStatus = update_to_dict(Id7, GoodsStatus, M#ets_wardrobe.goods_id), 
                    update_goods_id(M#ets_wardrobe.goods_id, Id7),
                    NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_ring=[M#ets_wardrobe.goods_id,S7]}},
                    {ok, NewPlayerStatus, NewStatus};
                false ->
                    replace_update_id(PlayerStatus#player_status.id, M#ets_wardrobe.time,  M#ets_wardrobe.pos, M#ets_wardrobe.goods_id),
                    update_goods_id(M#ets_wardrobe.goods_id, Id7),
                    NewStatus = update_to_dict(Id7, GoodsStatus, M#ets_wardrobe.goods_id), 
                    NewPlayerStatus = PlayerStatus#player_status{goods=Goods#status_goods{fashion_ring=[M#ets_wardrobe.goods_id,S7]}},
                    {ok, NewPlayerStatus, NewStatus}
            end
        end;
        _ ->
            {ok, PlayerStatus, GoodsStatus}
    end.

replace_update_id(Pid, Time, Pos, GoodsId) ->
    Sql = io_lib:format(<<"update fashion_change set new_id = ~p, time = ~p where pid = ~p and pos = ~p">>, [GoodsId, Time, Pid, Pos]),
    db:execute(Sql).

%% 着装度
get_wear_degree(PS) ->
    Dict = dict:filter(fun(_Key, [Value]) -> Value#ets_wardrobe.pos > 0 end, PS#player_status.wardrobe),
    DictList = dict:to_list(Dict),
    List = lib_goods_dict:get_list(DictList, []),
    F = fun(Wardrobe, Sum) ->
            if
                is_record(Wardrobe, ets_wardrobe) =:= true ->
                    GoodsId = Wardrobe#ets_wardrobe.goods_id,
                    X = data_fashion_change:get_wear_drgree(GoodsId),
                    X + Sum;
                true ->
                    Sum
            end
    end,
    N = lists:foldl(F, 0, List),
    Sql = io_lib:format(<<"update player_low set wear_degree = ~p where id = ~p">>, [N, PS#player_status.id]),
    db:execute(Sql).
    

