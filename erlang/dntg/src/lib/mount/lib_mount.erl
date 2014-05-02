%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-5-3
%% Description: TODO:
%% --------------------------------------------------------
-module(lib_mount).
-compile(export_all).
-include("mount.hrl").
-include("server.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-include("scene.hrl").
-include("fashion.hrl").

%% ================================================登录坐骑数据初始化===============================================
%%坐骑初始化
mount_init(RoleId, Dict) ->
    %% 更新数据的坐骑状态
    F1 = fun(Data, IsOn) ->
                 case make_mount_info(Data) of
                     [] -> IsOn;
                     Mount ->
                         Status = case IsOn > 0 of
                                      true when Mount#ets_mount.status > 0 ->
                                          Sql11 = io_lib:format(?SQL_UPDATE_STATUE, [0, Mount#ets_mount.id]),
                                          db:execute(Sql11),
                                          0;
                                      true -> 0;
                                      false -> 
                                          Mount#ets_mount.status
                                  end,
                         NewIsOn = case Status > 0 of
                                       true -> Status;
                                       false -> IsOn
                                   end,
                         NewIsOn
                 end
         end,
    SeSQL = io_lib:format(?SQL_MOUNT_SELECT, [RoleId]),
    case db:get_all(SeSQL) of
        [] -> 
            Dict2 = Dict;
        List1 when is_list(List1) ->
            %% 改变坐骑状态
            lists:foldl(F1, 0, List1),
            %%　初始化到字典
            Dict2 = insert_dict(List1, Dict);
        _ -> 
            Dict2 = Dict
    end,
    Dict2.

%% 格式化坐骑信息
make_mount_info(Data) ->
    case Data of
        [Mid, MName1, RoleId, TypeId, Figure, Speed, CombatPower, MStatus, Bind, Level, 
         Star, StarValue, QualityLv, QualityAttr, LingXiNum, LingXiAttr, LingXiGXId]->
            
            if
                MName1 =:= <<>> ->
                    MName = data_goods_type:get_name(TypeId);
                true ->
                    MName = MName1
            end,
            Mount = #ets_mount{
                               id = Mid,
                               name = MName,
                               role_id = RoleId,
                               type_id = TypeId,
                               figure = Figure,
                               speed = Speed,
                               combat_power = CombatPower,
                               status = MStatus, 
                               bind = Bind,
                               level = Level, 
                               star = Star, 
                               star_value = StarValue, 
                               quality_lv = QualityLv,
                               quality_attr = util:bitstring_to_term(QualityAttr),
                               lingxi_num = LingXiNum,
                               lingxi_attr = util:bitstring_to_term(LingXiAttr),
                               lingxi_gx_id = LingXiGXId
                              },
            %% 计算总属性
            lib_mount2:count_mount_attribute(Mount);
        _ ->  
            []
    end.

insert_dict([], Dict) ->
    Dict;
insert_dict([Info|T], Dict) ->
    case make_mount_info(Info) of
        [] ->
            Dict2 = Dict;
        Mount ->
            Key = Mount#ets_mount.id,
            Dict2 = add_dict(Key, Mount, Dict)
    end,
    insert_dict(T, Dict2).

%% ================================================登录坐骑形象幻化初始化===============================================
%%　坐骑形象幻化数据初始化
mount_change_init(RoleId, Dict) ->
    SeSQL = io_lib:format(?SQL_SELECT_MOUNT_CHANGE_BY_PID, [RoleId]),
    case db:get_all(SeSQL) of
        [] -> 
            Dict2 = Dict;
        List1 when is_list(List1) ->
            Dict2 = insert_change_dict(List1, Dict);
        _ -> 
            Dict2 = Dict
    end,
    Dict2.

insert_change_dict([], Dict) ->
    Dict;
insert_change_dict([Info|T], Dict) ->
    case make_mount_change_info(Info) of
        [] ->
            Dict2 = Dict;
        Change ->
            %%　Key = 坐骑id+形象id
            Key = integer_to_list(Change#upgrade_change.mid) ++ integer_to_list(Change#upgrade_change.type_id),
            %% io:format("~p ~p Key:~p~n", [?MODULE, ?LINE, Key]),
            Dict2 = add_dict(Key, Change, Dict)
    end,
    insert_change_dict(T, Dict2).

%% 坐骑幻化形象数据格式化
make_mount_change_info(Data) ->
    case Data of
        [_Id, Mid, Pid, TypeId, Time, State] ->
            _Now = util:unixtime(),
            %if
            %Time > Now orelse Time =:= 0 ->                
            Change = #upgrade_change{
                                     mid = Mid,
                                     pid = Pid,
                                     type_id = TypeId,
                                     time = Time,
                                     state = State
                                    },
            %true ->
            %Change = []
            %Sql = io_lib:format(<<"delete from upgrade_change where id = ~p">>, [Id]),
            %db:execute(Sql)
            %end,
            %% io:format("~p ~p Change:~p~n", [?MODULE, ?LINE, Change]),
            Change;
        _ ->  
            %% io:format("~p ~p Data:~p~n", [?MODULE, ?LINE, Data]),
            []
    end.



%% ================================================坐骑上下坐骑基本操作===============================================
%% 坐骑列表
get_mount_list(Id, Dict) ->
    case Dict =/= [] of
        true ->
            Dict1 = dict:filter(fun(_Key, [Value]) -> Value#ets_mount.role_id =:= Id end, Dict),
            DictList = dict:to_list(Dict1),
            lib_goods_dict:get_list(DictList, []);
        false ->
            []
    end.

%%乘上坐骑
get_on(PlayerStatus, MountId, Dict) ->
    case check_get_on(PlayerStatus, MountId, Dict) of
        {fail, Res} ->
            %% io:format("~p ~p Res:~p~n", [?MODULE, ?LINE, Res]),
            {fail, Res};
        {ok, Mount} ->
            %% 坐骑骑乘
            NewMount = change_status(Mount, 2),
            Dict2 = add_dict(NewMount#ets_mount.id, NewMount, Dict),
            NewPlayerStatus = change_player_status(PlayerStatus, Dict2),
            {ok, NewPlayerStatus, NewMount}
    end.

%% 检查骑乘
check_get_on(PlayerStatus, MountId, Dict) ->
    HuSong = PlayerStatus#player_status.husong,
    Cdict = PlayerStatus#player_status.change_dict,
    %% io:format("~p ~p Cdict:~p~n", [?MODULE, ?LINE, Cdict]),
    case dict:is_key(MountId, Cdict) of
        true ->
            [Change] = dict:fetch(MountId, Cdict),
            Figure = Change#ets_change.new_id;
        false ->
            Figure = 0
    end,
    case lib_scene:get_res_type(PlayerStatus#player_status.scene) of
        ?SCENE_TYPE_ACTIVE -> {fail, 7};    %% 活动场景不可以
        _ -> 
            case get_mount_info(MountId, Dict) of
                [] -> {fail, 2};    %% 坐骑不存在
                [Mount] ->
                    if  
                        Mount#ets_mount.role_id =/= PlayerStatus#player_status.id ->
                            {fail, 3};  %% 坐骑不属于你所有
                        Mount#ets_mount.status =:= 2 ->
                            {fail, 4};  %% 坐骑已是骑乘状态                       
                        Mount#ets_mount.status =/= 1 ->
                            {fail, 6};  %% 坐骑不是出战状态                    
                        HuSong#status_husong.husong > 0 ->
                            {fail, 5};  %% 护送不能骑                       
                        PlayerStatus#player_status.factionwar_stone > 0 ->
                            {fail, 5};  %% 帮派护送石头不能骑
                        true ->
                            if
                                Figure =/= 0 ->
                                    NewMount = Mount#ets_mount{figure = Figure},
                                    {ok, NewMount};
                                true ->
                                    {ok, Mount}
                            end
                    end
            end
    end.

%% 离开坐骑
get_off(PlayerStatus, MountId, Dict) ->
    case check_get_off(PlayerStatus#player_status.id, MountId, Dict) of
        {fail, Res} -> 
            %% io:format("~p ~p Res:~p~n", [?MODULE, ?LINE, Res]),
            {fail, Res};
        {ok, Mount} ->
            NewMount = change_status(Mount, 1),
            Dict2 = add_dict(NewMount#ets_mount.id, NewMount, Dict),
            NewPlayerStatus = change_player_status(PlayerStatus, Dict2),
            {ok, NewPlayerStatus}
    end.

%% 检查离开
check_get_off(RoleId, MountId, Dict) ->
    case get_mount_info(MountId, Dict) of
        %% 坐骑不存在
        [] -> {fail, 2};
        [Mount] ->
            if  %% 坐骑不属于你所有
                Mount#ets_mount.role_id =/= RoleId ->
                    {fail, 3};
                %% 坐骑已是休息状态
                Mount#ets_mount.status =/= 2 ->
                    {fail, 4};
                true ->
                    {ok, Mount}
            end
    end.

%% ================================================坐骑强化操作===============================================

%% 根据强化次数计算成功率
get_stren_ratio(Mount, GoodsStrengthenRule) ->
    [A, B, C, D, E] = GoodsStrengthenRule#ets_goods_strengthen.sratio,
    if
        Mount#ets_mount.stren_ratio =:= 0 ->
            A;
        Mount#ets_mount.stren_ratio =:= 1 ->
            B;
        Mount#ets_mount.stren_ratio =:= 2 ->
            C;
        Mount#ets_mount.stren_ratio =:= 3 ->
            D;
        Mount#ets_mount.stren_ratio =:= 4 ->
            E;
        true ->
            E
    end.

get_type(Figure) ->
    Flist = integer_to_list(Figure),
    if
        length(Flist) =:= 7 ->
            [A,B,C,D,E,F,_] = Flist,
            list_to_integer([A,B,C,D,E,F]);
        true ->
            Figure
    end.

%% 坐骑强化
mount_strengthen(PlayerStatus, GoodsStatus, Mount, StoneInfo, LuckyInfo, LuckyRule, GoodsStrengthenRule) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 根据之前强化失败次数检查当前强化成功率
            case LuckyRule =/= [] of
                true ->
                    LR = LuckyRule#ets_stren_lucky.ratio;
                false ->
                    LR = 0
            end,
            TimeRatio = get_stren_ratio(Mount, GoodsStrengthenRule),
            Vip = PlayerStatus#player_status.vip,
            if  Vip#status_vip.vip_type =:= 3 ->
                    SRatio = TimeRatio * (1 + 0.1),
                    CRatio = TimeRatio * (1 + 0.1);
                Vip#status_vip.vip_type =:= 2 ->
                    SRatio = TimeRatio * (1 + 0.06),
                    CRatio = TimeRatio * (1 + 0.06);
                Vip#status_vip.vip_type =:= 1 ->
                    SRatio = TimeRatio * (1 + 0.03),
                    CRatio = TimeRatio * (1 + 0.03);
                true -> 
                    SRatio = TimeRatio,
                    CRatio = TimeRatio
            end,
            NewSRatio = SRatio + LR,
            NewCRatio = CRatio + LR,
            NewRatio = if  NewCRatio >= 10000 -> 
                               NewCRatio;
                           true -> 
                               NewSRatio
                       end,
            %% 花费铜钱
            Cost = GoodsStrengthenRule#ets_goods_strengthen.coin,
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
			lib_guild:put_furnace_back(NewPlayerStatus, Cost),
            %% 扣掉强化石
            [NewStatus1, _NewStoneNum] = lib_goods:delete_one(StoneInfo, [GoodsStatus, 1]),
            %% 绑定状态
            Bind1 = lib_goods_compose:get_bind([{StoneInfo,0}]++[{LuckyInfo, 1}]),
            if
                Mount#ets_mount.bind > 0 orelse Bind1 > 0 ->
                    Bind = 2;
                true ->
                    Bind = Bind1
            end,
            case Bind > 0 of
                true ->
                    Trade = 1;
                false ->
                    Trade = 0
            end,
            if
                LuckyInfo#goods.goods_id > 0 ->
                    LuckyId = LuckyInfo#goods.goods_id,
                    %%扣掉幸运符
                    [NewStatus3, _] = lib_goods:delete_one(LuckyInfo, [NewStatus1, 1]);
                true ->
                    LuckyId = 0,
                    NewStatus3 = NewStatus1
            end,
            About1 = lib_goods_compose:get_about([{StoneInfo,1}]++[{LuckyInfo, 1}]),
            Ram = util:rand(1, 10000),
            case NewRatio >= Ram of
                %% 强化成功
                true ->
                    Res = 1,
                    NewMount = mount_strengthen_ok(Mount, Bind, Trade),
                    log:log_mount_stren(Mount, StoneInfo#goods.goods_id, NewRatio, Cost, 1, PlayerStatus#player_status.lv, LuckyId, About1);
                %% 强化失败
                false ->
                    case Mount#ets_mount.stren_ratio >= GoodsStrengthenRule#ets_goods_strengthen.fail_num of
                        true ->
                            %% 成功
                            Res = 1,
                            NewMount = mount_strengthen_ok(Mount, Bind, Trade),
                            (catch log:log_mount_stren(Mount, StoneInfo#goods.goods_id, NewRatio, Cost, 1, PlayerStatus#player_status.lv, LuckyId, About1));
                        false ->
                            Res = 0,
                             %% 求保护：累积强化因失败而掉级N次
                            case Mount#ets_mount.stren >= 6 of
                                true ->
                                    mod_achieve:trigger_hidden(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 3, 0, 1);
                                false ->
                                    skip
                            end,
                            NewMount = mount_strengthen_fail(Mount, Bind, Trade),
                            (catch log:log_mount_stren(Mount, StoneInfo#goods.goods_id, NewRatio, Cost, 0, PlayerStatus#player_status.lv, LuckyId, About1))
                    end
            end,
            Mou = NewPlayerStatus#player_status.mount,
            OldDict = Mou#status_mount.mount_dict,
            MountDict = add_dict(NewMount#ets_mount.id, NewMount, OldDict),
            NewPlayerStatus1 = change_player_status(NewPlayerStatus, MountDict),
            %% 日志 strengthen:装备强化 
            About = lists:concat(["mount_strengthen ", Mount#ets_mount.id, " +",Mount#ets_mount.stren," => +",NewMount#ets_mount.stren]),
            log:log_consume(mount_stren, coin, PlayerStatus, NewPlayerStatus1, Mount#ets_mount.id, 1, About),
            Dict = lib_goods_dict:handle_dict(NewStatus3#goods_status.dict),
            NewStatus4 = NewStatus3#goods_status{dict = Dict},
            {ok, Res, NewPlayerStatus1, NewStatus4, NewMount}
        end,
    lib_goods_util:transaction(F).

%% 强化成功
mount_strengthen_ok(Mount, Bind, Trade) ->
    NewStrengthen = Mount#ets_mount.stren + 1,
    Mount1 = Mount#ets_mount{stren = NewStrengthen},
    Stren_ratio = 0,
    %% 新形象
    Ftype = get_type(Mount#ets_mount.figure),
    %io:format("Ftyp = ~p~n", [{Ftype, Mount#ets_mount.figure, Mount#ets_mount.type_id}]),
    if
        Mount#ets_mount.type_id =:= Ftype ->
            NewFigure = get_stren_figure(Mount1);
        true ->
            NewFigure = Mount#ets_mount.figure
    end,
    NewName = Mount1#ets_mount.name,
    NewMount = count_mount(Mount1),
    change_stren(NewMount, NewName, NewFigure, NewStrengthen, Stren_ratio, Bind, Trade, NewMount#ets_mount.combat_power, NewMount#ets_mount.attribute, NewMount#ets_mount.att_per).

%% 强化失败
mount_strengthen_fail(Mount, Bind, Trade) ->
    NewStrengthen = Mount#ets_mount.stren,
    Stren_ratio = Mount#ets_mount.stren_ratio + 1,
    Mount1 = Mount#ets_mount{stren = NewStrengthen},
    %% 新形象
    NewFigure = Mount#ets_mount.figure, %get_stren_figure(Mount1),
    NewName = Mount1#ets_mount.name,
    NewMount = count_mount(Mount1),
    change_stren(Mount, NewName, NewFigure, NewStrengthen, Stren_ratio, Bind, Trade, NewMount#ets_mount.combat_power, NewMount#ets_mount.attribute, Mount#ets_mount.att_per).



%% ================================================坐骑卡使用,出战,回收===============================================
%% 坐骑卡使用
%% use_mount_card(PS, GoodsStatus, GoodsInfo, Base) ->
%%     F = fun() ->
%%                 ok = lib_goods_dict:start_dict(),
%%                 %% 扣掉坐骑卡
%%                 {ok, NewStatus, _} = lib_goods:delete_one(GoodsStatus, GoodsInfo, 1),
%%                 %% 新增坐骑
%%                 Mount = make_mount(GoodsStatus#goods_status.player_id, Base),
%%                 %Speed = Base#mount_base.speed,
%%                 Mount1 = Mount#ets_mount{bind=GoodsInfo#goods.bind, trade=GoodsInfo#goods.trade},
%%                 Figure = get_stren_figure(Mount1),
%%                 %% Name = data_goods_type:get_name(Mount#ets_mount.type_id),
%%                 Name = data_goods_type:get_name(Figure),
%%                 %% io:format("~p ~p Name:~ts~n", [?MODULE, ?LINE, Name]),
%%                 Mount3 = Mount1#ets_mount{figure = Figure, name = Name, status = 1},
%%                 Mount2 = count_mount(Mount3),
%%                 NewMount = add_mount(Mount2),
%%                 
%%                 log:log_mount_card(NewMount, GoodsInfo#goods.id, GoodsInfo#goods.goods_id, 1),
%%                 Mon = PlayerStatus#player_status.mount,
%%                 Dict = add_dict(NewMount#ets_mount.id, NewMount, Mon#status_mount.mount_dict),
%%                 NewPS = PS#player_status{mount = Mon#status_mount{mount_dict = Dict}},
%%                 Dict1 = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
%%                 NewStatus2 = NewStatus#goods_status{dict = Dict1},
%%                 {ok, NewPS, NewStatus2, NewMount}
%%         end,
%%     lib_goods_util:transaction(F).



use_mount_card(PS, GoodsStatus, GoodsInfo, Base) ->
    case check_used_moun_card(PS, GoodsInfo) of
        0 ->
            if
                Base#mount_upgrade.level =:= 1 ->
                    F = fun() ->
                                ok = lib_goods_dict:start_dict(),
                                %% 扣掉坐骑卡
                                {ok, NewStatus, _} = lib_goods:delete_one(GoodsStatus, GoodsInfo, 1),
                                %% 新增坐骑
                                Mount = make_mount(GoodsStatus#goods_status.player_id, Base),
                                %Speed = Base#mount_base.speed,
                                Mount1 = Mount#ets_mount{bind=GoodsInfo#goods.bind, trade=GoodsInfo#goods.trade},
                                Figure = get_stren_figure(Mount1),
                                %% Name = data_goods_type:get_name(Mount#ets_mount.type_id),
                                Name = data_goods_type:get_name(Figure),
                                %% io:format("~p ~p Name:~ts~n", [?MODULE, ?LINE, Name]),
                                Mount3 = Mount1#ets_mount{figure = Figure, name = Name, status = 1},
                                Mount2 = count_mount(Mount3),
                                NewMount = add_mount(Mount2),
                                
                                log:log_mount_card(NewMount, GoodsInfo#goods.id, GoodsInfo#goods.goods_id, 1),
                                Mon = PS#player_status.mount,
                                Dict = add_dict(NewMount#ets_mount.id, NewMount, Mon#status_mount.mount_dict),
                                NewPS = PS#player_status{mount = Mon#status_mount{mount_dict = Dict}},
                                Dict1 = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                                NewStatus2 = NewStatus#goods_status{dict = Dict1},
                                {ok, 1, NewPS, NewStatus2, NewMount}
                        end,
                    lib_goods_util:transaction(F);
                true ->
                    F = fun() ->
                                ok = lib_goods_dict:start_dict(),
                                %% 扣掉坐骑卡
                                {ok, NewStatus, _} = lib_goods:delete_one(GoodsStatus, GoodsInfo, 1),
                                %% 新增坐骑
                                NewBase = data_mount:get_mount_upgrade(311001),
                                Mount = make_mount(GoodsStatus#goods_status.player_id, NewBase),
                                %Speed = Base#mount_base.speed,
                                Mount1 = Mount#ets_mount{bind=GoodsInfo#goods.bind, trade=GoodsInfo#goods.trade},
                                %% Figure = get_stren_figure(Mount1),
                                Figure = Base#mount_upgrade.mount_id,
                                %% Name = data_goods_type:get_name(Mount#ets_mount.type_id),
                                Name = data_goods_type:get_name(Figure),
                                %% io:format("~p ~p Name:~ts~n", [?MODULE, ?LINE, Name]),
                                Mount3 = Mount1#ets_mount{figure = Figure, name = Name, status = 1},
                                Mount2 = count_mount(Mount3),
                                NewMount = add_mount(Mount2),
                                
                                %% 暂时处理
                                Sql = io_lib:format(?SQL_REPAIR, [NewMount#ets_mount.id, PS#player_status.id, Base#mount_upgrade.mount_id]),
                                db:execute(Sql),
                                %% 

                                log:log_mount_card(NewMount, GoodsInfo#goods.id, GoodsInfo#goods.goods_id, 1),
                                Mon = PS#player_status.mount,
                                Dict = add_dict(NewMount#ets_mount.id, NewMount, Mon#status_mount.mount_dict),
                                NewPS = PS#player_status{mount = Mon#status_mount{mount_dict = Dict}},
                                Dict1 = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                                NewStatus2 = NewStatus#goods_status{dict = Dict1},
                                {ok, 1, NewPS, NewStatus2, NewMount}
                        end,
                    lib_goods_util:transaction(F)
            end;
        1 ->
            F = fun() ->
                        Mount = PS#player_status.mount,
                        M = get_equip_mount(PS#player_status.id, Mount#status_mount.mount_dict),
                        ok = lib_goods_dict:start_dict(),
                        %% 扣掉坐骑卡
                        {ok, NewStatus, _} = lib_goods:delete_one(GoodsStatus, GoodsInfo, 1),
                        Change = #upgrade_change{
                                                 mid = M#ets_mount.id,
                                                 pid = PS#player_status.id,
                                                 time = 0,
                                                 type_id = Base#mount_upgrade.mount_id,
                                                 state = 3
                                                },
                        % 新增数据到幻化表+更新内存
                        Sql2 = io_lib:format(<<"insert into upgrade_change set mid=~p, pid=~p, type_id=~p, time=~p, state=~p">>, 
                                             [Change#upgrade_change.mid, Change#upgrade_change.pid, Change#upgrade_change.type_id, 
                                              Change#upgrade_change.time, Change#upgrade_change.state]),
                        db:execute(Sql2),
                        
                        Key = integer_to_list(Change#upgrade_change.mid) ++ integer_to_list(Change#upgrade_change.type_id),
                        ChangeDict = lib_mount:add_dict(Key, Change, Mount#status_mount.change_dict),
                        
                        %% 更换形象数据库和内存
                        NewMount = M#ets_mount{figure = Base#mount_upgrade.mount_id},
                        Sql = io_lib:format(?SQL_CHANGE_FIGURE, [Base#mount_upgrade.mount_id, NewMount#ets_mount.id]),
                        db:execute(Sql),
                        Dict = lib_mount:add_dict(M#ets_mount.id, NewMount, Mount#status_mount.mount_dict),
                        if
                            M#ets_mount.status =:= 2 ->
                                NewPS = PS#player_status{mount = Mount#status_mount{mount_dict = Dict, 
                                                                                    change_dict = ChangeDict, 
                                                                                    mount_figure= NewMount#ets_mount.figure}};
                            true ->
                                NewPS = PS#player_status{mount = Mount#status_mount{mount_dict = Dict, change_dict = ChangeDict}}
                        end,
                        %% 日志
                        log:log_mount_card(NewMount, GoodsInfo#goods.id, GoodsInfo#goods.goods_id, 1),
                        %% 新物品的状态
                        Dict1 = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                        NewStatus2 = NewStatus#goods_status{dict = Dict1},
                        {ok, 11, NewPS, NewStatus2, NewMount}
                end,
            lib_goods_util:transaction(F);
        _Code -> 
            {fail, _Code}
    end.


            

%% 检查使用坐骑卡
check_used_moun_card(PS, GoodsInfo)->
    SQL = io_lib:format(?SQL_MOUNT_ID_SELECT, [PS#player_status.id]),
    case db:get_all(SQL) of
        [] ->
            0;
        _ ->
            Mount = PS#player_status.mount,
            M = get_equip_mount(PS#player_status.id, Mount#status_mount.mount_dict),
            case M of
                [] -> 
                    8;
                M ->
                    List = lib_mount2:get_mount_change_list(Mount#status_mount.change_dict, M#ets_mount.id),
                    T1 = lib_mount2:is_typeid_change(List, GoodsInfo#goods.goods_id),
                    if
                        T1 == no ->
                            1;
                        true ->
                            9
                    end
            end
    end.
            
    

%% 坐骑出战
go_out(PlayerStatus, Mount_id, Dict) ->
    Mou = PlayerStatus#player_status.mount,
    case PlayerStatus#player_status.scene =:= 251 orelse
         PlayerStatus#player_status.scene =:= 250 orelse 
         PlayerStatus#player_status.scene =:= 252 orelse
         lists:member(PlayerStatus#player_status.scene, data_kf_3v3:get_config(scene_pk_ids)) of
        true ->
            {fail, 5};
        false ->
            case Mou#status_mount.fly > 0 of
                true ->
                    {fail, 6};
                false ->
                    case check_go_out(PlayerStatus#player_status.id, Mount_id, Dict) of
                        {fail, Res} -> 
                            {fail, Res};
                        {ok, Mount, OldMount} ->
                            F = fun() ->
                                        %% 原坐骑休息
                                        case OldMount#ets_mount.id > 0 of
                                            true -> 
                                                OldMount2 = change_status(OldMount, 0),
                                                Dict2 = add_dict(OldMount2#ets_mount.id, OldMount2, Dict);
                                            false -> 
                                                Dict2 = Dict
                                        end,
                                        %% 新坐骑出战
                                        NewMount = change_status(Mount, 1),
                                        Dict3 = add_dict(NewMount#ets_mount.id, NewMount, Dict2),
                                        {ok, NewMount, OldMount#ets_mount.id, Dict3}
                                end,
                            case lib_goods_util:transaction(F) of
                                {ok, NewMount, OldMount_id, NewDict} ->
                                    NewPlayerStatus = change_player_status(PlayerStatus, NewDict),
                                    NewPS = lib_mount_repair:get_out_repair(NewPlayerStatus, NewMount),
                                    if
                                        NewMount#ets_mount.level >= 3 ->
                                            lib_flyer:unlock_flyer_by_mount(NewPS#player_status.pid, NewPS#player_status.id);
                                        true ->
                                            skip
                                    end,
                                    {ok, NewPS, NewMount, OldMount_id};
                                _Error ->
                                    {fail, 0}
                            end
                    end
            end
    end.

%% 检查出战
check_go_out(Role_id, Mount_id, Dict) ->
    
            case get_mount_info(Mount_id, Dict) of
                %% 坐骑不存在
                [] -> {fail, 2};
                [Mount] ->
                    if  %% 坐骑不属于你所有
                        Mount#ets_mount.role_id =/= Role_id ->
                            {fail, 3};
                        %% 坐骑已是出战状态
                        Mount#ets_mount.status =/= 0 ->
                            {fail, 4};
                        true ->
                            OldMount = get_equip_mount(Role_id, Dict),
                            {ok, Mount, OldMount}
                    end
            end.

%% 坐骑休息
mount_rest(PlayerStatus, Mount_id, Dict) ->
    case PlayerStatus#player_status.scene =:= 251 of
        true ->
            {fail, 5};
        false ->
            case check_mount_rest(PlayerStatus#player_status.id, Mount_id, Dict) of
                {fail, Res} -> {fail, Res};
                {ok, Mount} ->
                    %% 坐骑休息
                    NewMount = change_status(Mount, 0),
                    NewDict = add_dict(NewMount#ets_mount.id, NewMount, Dict),
                    NewPlayerStatus = change_player_status(PlayerStatus, NewDict),
                    {ok, NewPlayerStatus}
            end
    end.

%% 检查休息
check_mount_rest(Role_id, Mount_id, Dict) ->
    case get_mount_info(Mount_id, Dict) of
        %% 坐骑不存在
        [] -> {fail, 2};
        [Mount] ->
            if  %% 坐骑不属于你所有
                Mount#ets_mount.role_id =/= Role_id ->
                    {fail, 3};
                %% 坐骑已是休息状态
                Mount#ets_mount.status =:= 0 ->
                    {fail, 4};
                true ->
                    {ok, Mount}
            end
    end.

%% 构造新的坐骑
make_mount(Role_id, Base) ->
    %%　Flist = integer_to_list(Base#mount_upgrade.mount_id) ++ integer_to_list(1),
    %%　Figure = list_to_integer(Flist),
    Figure = Base#mount_upgrade.mount_id,
    Mount = #ets_mount{
        role_id = Role_id,
        type_id = Base#mount_upgrade.mount_id,
        figure = Figure,
        speed = Base#mount_upgrade.speed
    },
    lib_mount2:count_mount_attribute(Mount).

%% 坐骑回收
mount_recover(PlayerStatus, GoodsStatus, Mount) ->
    F = fun() ->
                ok = lib_goods_dict:start_dict(),
                [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
                %% 删除坐骑
                Mou = PlayerStatus#player_status.mount,
                Dict = dict:erase(Mount#ets_mount.id, Mou#status_mount.mount_dict),
                NewPlayerStatus = change_player_status(PlayerStatus, Dict),
                delete_mount(Mount#ets_mount.id),
                %% 添加物品
                [Hp, Att, Hit, Crit, _,_,_] = Mount#ets_mount.attribute,
                Info = #goods{id=0, player_id = Mount#ets_mount.role_id, num=1, type=?GOODS_TYPE_MOUNT, 
                              subtype=?GOODS_SUBTYPE_MOUNT_CARD, speed=Mount#ets_mount.speed,
                              stren=Mount#ets_mount.stren, stren_ratio=Mount#ets_mount.stren_ratio, 
                              goods_id=Mount#ets_mount.type_id,bind=Mount#ets_mount.bind, trade=Mount#ets_mount.trade, 
                              cell=Cell, location=?GOODS_LOC_BAG, hp=Hp, att=Att,hit=Hit, crit=Crit},
                [NewInfo, NewStatus1] = lib_goods:add_goods(Info, GoodsStatus),
                NewStatus = NewStatus1#goods_status{null_cells = NullCells},
                GoodsDict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                NewStatus2 = NewStatus#goods_status{dict = GoodsDict},
                {ok, NewPlayerStatus, NewStatus2, NewInfo}
        end,
    lib_goods_util:transaction(F).
  
%% 检查坐骑回收
check_mount_recover(PlayerStatus, MountId, GoodsStatus) ->
    Mou = PlayerStatus#player_status.mount,
    case get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] ->
            {fail, 2}; %% 坐骑不存在
        [Mount] ->
            Cells = length(GoodsStatus#goods_status.null_cells),
            if  
                Mount#ets_mount.role_id =/= PlayerStatus#player_status.id ->
                    {fail, 3}; %% 坐骑不属于你所有
                Cells =:= 0 ->
                    {fail, 4}; %% 背包已满
                Mount#ets_mount.status =/= 0 ->
                    {fail, 5}; %% 不是休息状态
                true ->
                    {ok, Mount}
            end
    end.
                    
%% 重新计算坐骑属性
count_mount(Mount) ->
    Mount1 = lib_mount2:count_mount_attribute(Mount),
    Mount1.

%% ================================================坐骑私有函数===============================================
%% 坐骑消息
get_mount_info(Mid, Dict) ->
    case dict:is_key(Mid, Dict) of
        true ->
            dict:fetch(Mid, Dict);
        false ->
            []
    end.

%% 插入字典
add_dict(Key, Obj, Dict) ->
    case dict:is_key(Key, Dict) of
        true ->
            Dict1 = dict:erase(Key, Dict),
            Dict2 = dict:append(Key, Obj, Dict1);
        false ->
            Dict2 = dict:append(Key, Obj, Dict)
    end,
    Dict2.

%% 更改坐骑状态
change_status(Mount, Status) ->
    Sql = io_lib:format(?SQL_UPDATE_STATUE, [Status, Mount#ets_mount.id]),
    db:execute(Sql),
    NewMount = Mount#ets_mount{status = Status},
    NewMount.

%% 更改player_status
change_player_status(PlayerStatus, Dict) ->
    Mount = get_equip_mount(PlayerStatus#player_status.id, Dict),
    Figure = Mount#ets_mount.figure,
    Mou = PlayerStatus#player_status.mount,
    case Mount#ets_mount.status >= 2 of
        true ->  
            PlayerStatus1 = PlayerStatus#player_status{mount=Mou#status_mount{mount = Mount#ets_mount.id, 
                                                                              mount_figure = Figure, 
                                                                              mount_speed = Mount#ets_mount.speed, 
                                                                              mount_dict = Dict}};
        false -> 
            PlayerStatus1 = PlayerStatus#player_status{mount=Mou#status_mount{mount = 0, mount_figure = 0, mount_speed = 0, mount_dict = Dict}}
    end,
    M1 = PlayerStatus1#player_status.mount,
    
    PlayerStatus2 = PlayerStatus1#player_status{mount = M1#status_mount{mount_attribute = Mount#ets_mount.attribute}},
    PlayerStatus3 = lib_player:count_player_speed(PlayerStatus2),
    lib_player:count_player_attribute(PlayerStatus3).

%%获得出战坐骑
get_equip_mount(PlayerId, Dict) ->
    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#ets_mount.status > 0 andalso Value#ets_mount.role_id =:= PlayerId end, Dict),
    DictList = dict:to_list(Dict1),
    List = lib_goods_dict:get_list(DictList, []),
    case List =/= [] of
        true ->
            [Mount|_] = List,
            Mount;
        false ->
            #ets_mount{}
    end.

%% 强化
change_stren(Mount, NewName, NewFigure, NewStren, Stren_ratio, Bind, Trade, ComPower, Attribute, AttPer) ->
    Sql = io_lib:format(?SQL_MOUNT_STREN, [NewName, NewFigure, NewStren, Stren_ratio, Bind, Trade, ComPower, util:term_to_string(Attribute), AttPer, Mount#ets_mount.id]),
    db:execute(Sql),
    Mount#ets_mount{name=NewName, figure=NewFigure, stren=NewStren, stren_ratio=Stren_ratio, bind=Bind, trade=Trade, combat_power=ComPower, attribute=Attribute, att_per=AttPer}.

%% 坐骑数量
get_mount_count(PlayerId, Dict) ->
    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#ets_mount.role_id =:= PlayerId end, Dict),
    dict:size(Dict1).

%% 形象
get_stren_figure(Mount) ->
    %%     case Mount#ets_mount.stren > 0 of
    %%         true ->
    %%             FigureRule = data_mount:get_stren(Mount#ets_mount.stren),
    %%             Flist = integer_to_list(Mount#ets_mount.type_id) ++ integer_to_list(FigureRule#mount_stren.figure),
    %%             list_to_integer(Flist);
    %%         false ->
    %% Flist = integer_to_list(Mount#ets_mount.type_id) ++ integer_to_list(1),
    Flist = integer_to_list(Mount#ets_mount.type_id),
    list_to_integer(Flist).
    %%     end.

%% 属性
get_mount_attribute(Mount) ->
    case Mount#ets_mount.stren > 0 of
        true ->
            FigureRule = data_mount:get_stren(Mount#ets_mount.stren),
            Base = data_mount:get_mount_base(Mount#ets_mount.type_id),
            {[round(Base#mount_base.hp*(1+FigureRule#mount_stren.percent/100)), FigureRule#mount_stren.att, FigureRule#mount_stren.hit, FigureRule#mount_stren.crit, round(Base#mount_base.resist*(1+FigureRule#mount_stren.percent/100)), round(Base#mount_base.resist*(1+FigureRule#mount_stren.percent/100)), round(Base#mount_base.resist*(1+FigureRule#mount_stren.percent/100))], FigureRule#mount_stren.att_per};
        false ->
            Base = data_mount:get_mount_base(Mount#ets_mount.type_id),
            case Base =/= [] of
                true ->
                    {[Base#mount_base.hp, 0, 0, 0, Base#mount_base.resist, Base#mount_base.resist, Base#mount_base.resist], 0};
                false ->
                    {Mount#ets_mount.attribute, Mount#ets_mount.att_per}
            end
    end.

%% 获取坐骑的战斗力
%% 战斗力计算公式： (坚韧*31+气血*8+防御*38+闪避*38+命中*38+暴击*93+攻击*94+火抗性*13+冰抗性*13+毒抗性*13)/100
%% 用于坐骑卡计算战斗力
get_mount_power_for_goods(Stren, TypeId) ->
    Mount = #ets_mount{stren = Stren, type_id = TypeId},
    NewMount = lib_mount2:count_mount_attribute(Mount),
    [_Hp, _Att, _Hit, _Crit, _Fire, Ice, _Drug] =
    NewMount#ets_mount.attribute,
    {NewMount#ets_mount.combat_power, Ice}.
%%    Base = data_mount:get_mount_base(TypeId),
%%    case Base =/= [] of
%%        true ->
%%            [Hp, _Fire, Ice, _Drug] = [Base#mount_base.hp, Base#mount_base.resist, Base#mount_base.resist, Base#mount_base.resist];
%%        false ->
%%            [Hp, _Fire, Ice, _Drug] = [0,0,0,0]
%%    end,
%%    case Stren > 0 of
%%        true ->
%%            FigureRule = data_mount:get_stren(Stren),
%%            case FigureRule =/= [] of
%%                true ->
%%                    [Att, Hit, Crit, P] = [FigureRule#mount_stren.att, FigureRule#mount_stren.hit, FigureRule#mount_stren.crit, FigureRule#mount_stren.percent];
%%                false ->
%%                    [Att, Hit, Crit, P] = [0, 0, 0, 0]
%%            end;
%%        false ->
%%            [Att, Hit, Crit, P] = [0, 0, 0, 0]
%%    end,
%%    Ice2 = round(Ice*(1+P/100)),
%%    Power = round((Hp*(1+P/100)*0.06 + Hit*0.3113 + Crit*1 + Att*0.8988 + Ice2*0.1 + Ice2*0.1 + Ice2*0.1)),
%%    {Power, Ice2}.

%% 添加坐骑
add_mount(M) ->
    QualityInitAttr  = data_mount_config:get_config(quality_init_attr),
    LintXiInitAttr  = data_mount_config:get_config(lingxi_init_attr),
    Sql = io_lib:format(?SQL_MOUNT_INSERT, [M#ets_mount.role_id, M#ets_mount.name, M#ets_mount.type_id, M#ets_mount.figure, 
                                            M#ets_mount.stren, M#ets_mount.stren_ratio, M#ets_mount.speed, M#ets_mount.combat_power, 
                                            M#ets_mount.status, util:term_to_string(M#ets_mount.attribute), M#ets_mount.bind,
                                            M#ets_mount.trade, M#ets_mount.att_per, util:term_to_string(QualityInitAttr),
                                            util:term_to_string(LintXiInitAttr)]),
    db:execute(Sql),
    Id = db:get_one(?SQL_LAST_MOUNT_ID),
    M#ets_mount{id = Id, quality_attr = QualityInitAttr, lingxi_attr = LintXiInitAttr}.

%% 删除坐骑
delete_mount(MountId) ->
    Sql = io_lib:format(?SQL_MOUNT_DELETE, [MountId]),
    db:execute(Sql).

%% 获取坐骑信息 -> [坐骑ID，坐骑形像，坐骑速度，坐骑属性]
get_mount_info_by_role(RoleId, Dict) ->
    Mount = get_equip_mount(RoleId, Dict),
    case Mount#ets_mount.status =:= 2 of
        true ->
            [Mount#ets_mount.id, Mount#ets_mount.figure, Mount#ets_mount.speed, Mount#ets_mount.attribute];
        false -> 
            [0, 0, 0, Mount#ets_mount.attribute]
    end.

%% get_mount_info_by_role(RoleId, Dict, Flyers, Pid) ->
%%     Mount = get_equip_mount(RoleId, Dict),
%%     if
%%         Mount#ets_mount.level >= 3 ->
%%         case length(Flyers) < 2 of
%%         true ->
%%             NewFlyers = lib_flyer:activate_flyer_by_mount(Pid, RoleId);
%%         false ->
%%             NewFlyers = Flyers
%%         end,
%%             Flyer = 311401;
%%         true ->
%%         NewFlyers = Flyers,
%%             Flyer = 0
%%     end,
%%     case Mount#ets_mount.status =:= 2 of
%%         true ->
%%             [Mount#ets_mount.id, Mount#ets_mount.figure, Mount#ets_mount.speed, Mount#ets_mount.attribute, Flyer, NewFlyers];
%%         false -> [0, 0, 0, Mount#ets_mount.attribute, Flyer, NewFlyers]
%%     end.

%% 下坐骑（给其它模块调用, 游戏线）
%% 成功返回{ok,mount, NewPlayerStatus}，失败返回错误码
player_get_off_mount(PlayerStatus) ->
    M = PlayerStatus#player_status.mount,
    Mount = get_equip_mount(PlayerStatus#player_status.id, M#status_mount.mount_dict),
    if
        Mount#ets_mount.id > 0 ->
            case get_off(PlayerStatus, Mount#ets_mount.id, M#status_mount.mount_dict) of
                {fail, Res} ->
                    {fail, Res};
                {ok, NewPlayerStatus} ->
                    {ok, mount, NewPlayerStatus}
            end;
        true ->
            {fail, 0}
    end.
            
                
            


