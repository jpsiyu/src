%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-8-11
%% Description: 时装形象转换
%% --------------------------------------------------------
-module(lib_fashion_change).
-compile(export_all).
-include("fashion.hrl").
-include("errcode_goods.hrl").
-include("def_goods.hrl").
-include("server.hrl").
-include("goods.hrl").
-include("mount.hrl").

%% 初始化形象转换
change_figure_init(PlayerStatus, GoodsDict) ->
    Sql = io_lib:format(?sql_change_select, [PlayerStatus#player_status.id]),
    case db:get_all(Sql) of
        [] ->
            NewPlayerStatus = PlayerStatus;
        List when is_list(List) ->
            NewPlayerStatus = insert_dict(List, PlayerStatus, GoodsDict);
        _ ->
            NewPlayerStatus = PlayerStatus
    end,
    NewPlayerStatus.

%% 插入缓存,替换之前的形象
insert_dict([], PS, _GoodsDict) ->
    PS;
insert_dict([Info|T], PS, GoodsDict) ->
    case make_change_info(Info, GoodsDict) of
        [] ->
            PS2 = PS;
        Change ->
            Key = Change#ets_change.gid,
            Dict2 = lib_mount:add_dict(Key, Change, PS#player_status.change_dict),
            Goods = PS#player_status.goods,
            %% 更新形象
            case Change#ets_change.pos of
                1 ->
                    [Armor, S1] = Goods#status_goods.fashion_armor,
                    if
                        Armor =/= Change#ets_change.new_id andalso Armor =/= 0 ->
                            PS2 = PS#player_status{change_dict=Dict2, goods=Goods#status_goods{fashion_armor=[Change#ets_change.new_id, S1]}};
                        true ->
                            PS2 = PS#player_status{change_dict=Dict2}
                    end;
                2 ->    %% 武器
                    [Weapon, S2] = Goods#status_goods.fashion_weapon,
                    if
                        Weapon =/= Change#ets_change.new_id andalso Weapon =/= 0 ->
                            PS2 = PS#player_status{change_dict=Dict2, goods=Goods#status_goods{fashion_weapon=[Change#ets_change.new_id, S2]}};
                        true ->
                            PS2 = PS#player_status{change_dict=Dict2}
                    end;
                3 ->    %% 饰品
                    [Accessory, S3] = Goods#status_goods.fashion_accessory,
                    if
                        Accessory =/= Change#ets_change.new_id andalso Accessory =/= 0 ->
                            PS2 = PS#player_status{change_dict=Dict2, goods=Goods#status_goods{fashion_accessory=[Change#ets_change.new_id, S3]}};
                        true ->
                            PS2 = PS#player_status{change_dict=Dict2}
                    end;
                4 ->    %% 坐骑
                    Mount = PS#player_status.mount,
                    %io:format("insert ~p~n", [{Mount#status_mount.mount_figure, Change#ets_change.new_id}]),
                    if
                        Mount#status_mount.mount_figure =/= Change#ets_change.new_id ->
                            PS2 = PS#player_status{mount = Mount#status_mount{mount_figure=Change#ets_change.new_id}};
                        true ->
                            PS2 = PS#player_status{change_dict=Dict2}
                    end;
                _ ->
                    PS2 = PS
            end
    end,
    insert_dict(T, PS2, GoodsDict).

%% 检查数据
make_change_info(Info, GoodsDict) ->
    NowTime = util:unixtime(),
    case Info of
        [Cpos, Cpid, ColdId, CnewId, Ctime, Original, Gid] when Ctime > NowTime ->
            if 
                Gid =:= 0 ->        %% 重新处理
                    GoodsList = lib_goods_util:get_equip_list(Cpid, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, GoodsDict),
                    GoodsId = get_fashion_id(GoodsList, Cpos),
                    if
                        GoodsId > 0 ->
                            Sql = io_lib:format(?sql_change_update2, [GoodsId, Cpid, Cpos, Original]),
                            db:execute(Sql);
                        true ->
                            skip
                    end;
                true ->
                    GoodsId = Gid
            end,
            if
                GoodsId > 0 ->
                    Change = #ets_change{
                        pos = Cpos,
                        old_id = ColdId,
                        new_id = CnewId,
                        time = Ctime,
                        pid = Cpid,
                        original = Original,
                        gid = GoodsId
                    };
                true ->
                    Change = []
            end,
            Change;
        [_Cpos, _Cpid, _ColdId, _CnewId, _Ctime, _Original, _Gid] when _Ctime =< NowTime ->
            delete_change(_Cpid, _Cpos, _Gid),
            [];
        _ ->
            []
    end.

%% 获得时装的id
get_fashion_id([], _) ->
    0;
get_fashion_id([GoodsInfo|T], Pos) ->
    case Pos of
        1 ->
            if
                GoodsInfo#goods.subtype =:= ?GOODS_FASHION_ARMOR ->
                    GoodsInfo#goods.id;
                true ->
                    get_fashion_id(T, Pos)
            end;
        2 ->
            if
                GoodsInfo#goods.subtype =:= ?GOODS_FASHION_WEAPON ->
                    GoodsInfo#goods.id;
                true ->
                    get_fashion_id(T, Pos)
            end;
        3 ->
            if
                GoodsInfo#goods.subtype =:= ?GOODS_FASHION_ACCESSORY ->
                    GoodsInfo#goods.id;
                true ->
                    get_fashion_id(T, Pos)
            end;
        5 ->
            if
                GoodsInfo#goods.subtype =:= ?GOODS_FASHION_HEAD ->
                    GoodsInfo#goods.id;
                true ->
                    get_fashion_id(T, Pos)
            end;
        6 ->
            if
                GoodsInfo#goods.subtype =:= ?GOODS_FASHION_TAIL ->
                    GoodsInfo#goods.id;
                true ->
                    get_fashion_id(T, Pos)
            end;
        7 ->
            if
                GoodsInfo#goods.subtype =:= ?GOODS_FASHION_RING ->
                    GoodsInfo#goods.id;
                true ->
                    get_fashion_id(T, Pos)
            end;
        _ ->
            get_fashion_id(T, Pos)
    end.

%% 使用变换卷
add_figure_change(PlayerStatus, GoodsInfo, Pos, GoodsDict) ->
    Dict = PlayerStatus#player_status.change_dict,
    Goods = PlayerStatus#player_status.goods,
    GoodsList = lib_goods_util:get_equip_list(PlayerStatus#player_status.id, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, GoodsDict),
    case data_fashion_change:get_info(GoodsInfo#goods.goods_id, PlayerStatus#player_status.career) of
        [0,0] ->
            %% 形象类型不存在
            {fail, ?ERRCODE15_NO_GOODS_TYPE};
        [Figure, Days] ->
            case Pos of
                1 ->    %%衣服
                    [Armor, S1] = Goods#status_goods.fashion_armor,
                    Id1 = get_fashion_id(GoodsList, 1),
                    if  Armor =< 0 orelse Id1 =< 0 -> %% 您未穿戴任何时装
                        {fail, ?ERRCODE15_FASHION_NONE};
                    true ->
                        NewDict = handle_figure_change(PlayerStatus#player_status.id, Armor, Dict, Figure, Pos, Days, Id1),
                        NewPlayerStatus = PlayerStatus#player_status{change_dict = NewDict, goods=Goods#status_goods{fashion_armor=[Figure,S1]}},
                        {ok, NewPlayerStatus}
                    end;
                2 ->    %% 武器
                    [Weapon, S2] = Goods#status_goods.fashion_weapon,
                    Id2 = get_fashion_id(GoodsList, 2),
                    if  Weapon =< 0 orelse Id2 =< 0 -> %% 您未穿戴任何时装
                        {fail, ?ERRCODE15_FASHION_NONE};
                    true ->
                        NewDict = handle_figure_change(PlayerStatus#player_status.id, Weapon, Dict, Figure, Pos, Days, Id2),
                        NewPlayerStatus = PlayerStatus#player_status{change_dict = NewDict, goods=Goods#status_goods{fashion_weapon=[Figure,S2]}},
                        {ok, NewPlayerStatus}
                    end;
                3 ->    %% 饰品
                    [Accessory, S3] = Goods#status_goods.fashion_accessory,
                    Id3 = get_fashion_id(GoodsList, 3),
                    if  Accessory =< 0 orelse Id3 =< 0 -> %% 您未穿戴任何时装
                        {fail, ?ERRCODE15_FASHION_NONE};
                    true ->
                        NewDict = handle_figure_change(PlayerStatus#player_status.id, Accessory, Dict, Figure, Pos, Days, Id3),
                        NewPlayerStatus = PlayerStatus#player_status{change_dict = NewDict, goods=Goods#status_goods{fashion_accessory=[Figure,S3]}},
                        {ok, NewPlayerStatus}
                    end;
                4 ->    %% 坐骑
                    Mount = PlayerStatus#player_status.mount,
                    M = lib_mount:get_equip_mount(PlayerStatus#player_status.id, Mount#status_mount.mount_dict),
                    %io:format("mount_figure = ~p~n", [{Mount#status_mount.mount_figure, M#ets_mount.id}]),
                    if  M#ets_mount.id =< 0 -> %% 坐骑未出战
                        {fail, ?ERRCODE15_FASHION_NONE};
                    true ->
                        Flist = integer_to_list(Figure) ++ integer_to_list(1),
                        Mfigure = list_to_integer(Flist),
                        NewDict = handle_figure_change(PlayerStatus#player_status.id, Mount#status_mount.mount_figure, Dict, Mfigure, Pos, Days, M#ets_mount.id),
                        NewPlayerStatus = PlayerStatus#player_status{change_dict = NewDict, mount=Mount#status_mount{mount_figure=Mfigure}},     %% 是否要改变坐骑dict的形象?
                        {ok, NewPlayerStatus}
                    end;
                _ ->
                    {fail, ?ERRCODE15_NO_GOODS_TYPE}
            end
    end.

handle_figure_change(Id, OldTypeId, Dict, Figure, Pos, Days, GoodsId) ->
    case dict:is_key(GoodsId, Dict) of
        true ->
            %% 更新叠加
            [Change] = dict:fetch(GoodsId, Dict),
            OldTime = Change#ets_change.time,
            if  Change#ets_change.new_id =:= Figure ->
                NewChange = Change#ets_change{time = OldTime + Days * 86400};
            true ->
                NewChange = new_figure_change(Id, Change#ets_change.original, Figure, Pos, Days, GoodsId)
            end,
            NewDict = save_change(NewChange, Dict, update),
            NewDict;
        false ->
            Change = new_figure_change(Id, OldTypeId, Figure, Pos, Days, GoodsId),
            NewDict = save_change(Change, Dict, insert),
            NewDict
    end.

new_figure_change(Pid, OldId, NewId, Pos, Day, GoodsId) ->
    NowTime = util:unixtime(),
    Change = #ets_change{
                            pos = Pos, 
                            pid = Pid,
                            old_id = OldId,
                            new_id = NewId,
                            time = NowTime + Day * 86400,
                            original = OldId,
                            gid = GoodsId
                        },
    Change.

save_change(Change, Dict, Type) ->
    case Type of
        insert ->
            Sql = io_lib:format(?sql_change_insert, [Change#ets_change.pos, Change#ets_change.pid, Change#ets_change.old_id, Change#ets_change.new_id, Change#ets_change.time, Change#ets_change.original, Change#ets_change.gid]),
            db:execute(Sql),
            Dict2 = lib_mount:add_dict(Change#ets_change.gid, Change, Dict),
            Dict2;
        update ->
            Sql = io_lib:format(?sql_change_update, [Change#ets_change.time, Change#ets_change.new_id, Change#ets_change.gid, Change#ets_change.pid, Change#ets_change.pos]),
            db:execute(Sql),
            Dict2 = lib_mount:add_dict(Change#ets_change.gid, Change, Dict),
            Dict2;
        _ ->
            Dict
    end.

delete_change(Cpid, Cpos, Gid) ->
    Sql = io_lib:format(?sql_change_delete, [Cpid, Cpos, Gid]),
    db:execute(Sql).
            
%% 查看是否有使用过变幻卷
%% 有返回变幻后的id，没有返回0
get_change_before(ChangeDict, _Pos, GoodsId) ->
    case dict:is_key(GoodsId, ChangeDict) of
        true ->
            [Change] = dict:fetch(GoodsId, ChangeDict),
            %io:format("Change = ~p~n", [{Change#ets_change.gid, GoodsId}]),
            if
                Change#ets_change.gid =:= GoodsId ->
                    Change#ets_change.new_id;
                true ->
                    0
            end;
        false ->
            0
    end.
            
                    
            
