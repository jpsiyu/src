%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-1-7
%% Description: 物品合成,洗炼强化等操作
%% --------------------------------------------------------
-module(lib_goods_compose).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("server.hrl").
-include("fashion.hrl").

%% 装备品质升级(颜色不变,改变前缀)
quality_upgrade(PlayerStatus, GoodsStatus, GoodsInfo, StoneList, GoodsQualityRule, PrefixType) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 花费铜钱
            Cost = GoodsQualityRule#ets_goods_quality_upgrade.coin,
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
            %% 扣掉品质石
            {ok, NewStatus} = lib_goods:delete_goods_list(GoodsStatus, StoneList),
            Bind = get_bind([{GoodsInfo,1}]++StoneList),
            case Bind > 0 of
                true ->
                    Trade = 1;
                false ->
                    Trade = 0
            end,
            NowPrefix = case PrefixType of
                1 -> GoodsInfo#goods.first_prefix; %% 进阶前缀
                2 -> GoodsInfo#goods.prefix        %% 品质前缀
            end,
            [NewGoodsInfo, NewStatus1] = change_goods_quality(GoodsInfo, GoodsQualityRule#ets_goods_quality_upgrade.prefix, Bind, Trade, NewStatus, PrefixType),
            NewPrefix = case PrefixType of
                1 -> NewGoodsInfo#goods.first_prefix; %% 进阶前缀
                2 -> NewGoodsInfo#goods.prefix        %% 品质前缀
            end,
            [{StoneInfo, Num}|_] = StoneList,
            NewStoneNum = StoneInfo#goods.num - Num,
            (catch log:log_quality_up(PlayerStatus, NewGoodsInfo, StoneInfo#goods.goods_id, Cost, 1)),
            %% 日志 prefix_up:品质升级 
            About = lists:concat(["prefix_up type ",PrefixType," ",GoodsInfo#goods.goods_id,"+",NowPrefix," => +",NewPrefix]),
            log:log_consume(goods_up_prefix, coin, PlayerStatus, NewPlayerStatus, GoodsInfo#goods.goods_id, 1, About),
            D = lib_goods_dict:handle_dict(NewStatus1#goods_status.dict),
            NewStatus2 = NewStatus1#goods_status{dict = D}, 
            {ok, 1, NewPlayerStatus, NewStatus2, [NewGoodsInfo#goods.first_prefix, NewGoodsInfo#goods.prefix, Bind, NewStoneNum, NewGoodsInfo]}
    end,
    lib_goods_util:transaction(F).

%% 根据强化等级计算成功率
get_stren_ratio(GoodsInfo, GoodsStrengthenRule) ->
    [A, B, C, D, E] = GoodsStrengthenRule#ets_goods_strengthen.sratio,
    if
        GoodsInfo#goods.stren_ratio =:= 0 ->
            A;
        GoodsInfo#goods.stren_ratio =:= 1 ->
            B;
        GoodsInfo#goods.stren_ratio =:= 2 ->
            C;
        GoodsInfo#goods.stren_ratio =:= 3 ->
            D;
        GoodsInfo#goods.stren_ratio =:= 4 ->
            E;
        true ->
            E
    end.

%% 装备强化
%% NewGoodsTypeInfo #ets_goods_type{} | []
strengthen(PlayerStatus, GoodsStatus, GoodsInfo, StoneList, LuckyInfo, LuckyRule, GoodsStrengthenRule, NewGoodsTypeInfo) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 花费铜钱
            Cost = GoodsStrengthenRule#ets_goods_strengthen.coin,
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
            %% 根据之前强化失败次数检查当前强化成功率
            case LuckyRule =/= [] of
                true ->
                    LR = LuckyRule#ets_stren_lucky.ratio;
                false ->
                    LR = 0
            end,
            TimeRatio = get_stren_ratio(GoodsInfo, GoodsStrengthenRule),
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
            %%帮派加成
            GuildRatio = lib_guild:get_furnace_add(PlayerStatus#player_status.id, PlayerStatus#player_status.guild#status_guild.guild_id, Cost),
            NewSRatio = SRatio + LR + GuildRatio,
            NewCRatio = CRatio + LR + GuildRatio,
            NewRatio = if  NewCRatio >= 10000 -> 
                    NewCRatio;
                true -> 
                    NewSRatio
            end,
            %StoneNum = GoodsStrengthenRule#ets_goods_strengthen.stone_num,
            %% 扣掉强化石
            {ok, NewStatus1} = lib_goods:delete_goods_list(GoodsStatus, StoneList),
            
            if
                LuckyInfo#goods.goods_id > 0 ->
                    %%扣掉幸运符
                    LuckyId = LuckyInfo#goods.goods_id,
                    [NewStatus3, _] = lib_goods:delete_one(LuckyInfo, [NewStatus1, 1]);
                true ->
                    LuckyId = 0,
                    NewStatus3 = NewStatus1
            end,
            About1 = get_about(StoneList++[{LuckyInfo, 1}]),
            %% 绑定状态
            Bind = get_bind(StoneList++[{LuckyInfo, 1}]),
            [{StoneInfo, _}|_] = StoneList,
            Ram = util:rand(1, 10000),
            case NewRatio >= Ram of
                %% 强化成功
                true ->
                    Res = 1,
                    [NewGoodsInfo, NewStatus4] = strengthen_ok(PlayerStatus, GoodsInfo, Bind, NewStatus3, GoodsStrengthenRule, NewGoodsTypeInfo),
                    log:log_stren(GoodsInfo, StoneInfo#goods.id, StoneInfo#goods.goods_id, NewRatio, Cost, 1, PlayerStatus#player_status.lv, LuckyId, About1),
                    NewStatus5 = NewStatus4;
                %% 强化失败
                false ->
                    case GoodsStrengthenRule#ets_goods_strengthen.fail_num /= 0 andalso GoodsInfo#goods.stren_ratio >= GoodsStrengthenRule#ets_goods_strengthen.fail_num of
                        true ->
                            %% 成功
                            Res = 1,
                            [NewGoodsInfo, NewStatus4] = strengthen_ok(PlayerStatus, GoodsInfo, Bind, NewStatus3, GoodsStrengthenRule, NewGoodsTypeInfo),
                             (catch log:log_stren(GoodsInfo, StoneInfo#goods.id, StoneInfo#goods.goods_id, NewRatio, Cost, 1, PlayerStatus#player_status.lv, LuckyId, About1)),
                            NewStatus5 = NewStatus4;
                        false ->
                            Res = 0,
                            %% 求保护：累积强化+7失败而掉级N次
                            %case GoodsInfo#goods.stren >= 6 of
                            %    true ->
                            %        mod_achieve:trigger_hidden(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 3, 0, 1);
                            %    false ->
                            %        skip
                            %end,
                            [NewGoodsInfo, NewStatus4] = strengthen_fail(GoodsInfo, Bind, NewStatus3, GoodsStrengthenRule),
                            NewStatus5 = NewStatus4,
                            (catch log:log_stren(GoodsInfo, StoneInfo#goods.id, StoneInfo#goods.goods_id, NewRatio, Cost, 0, PlayerStatus#player_status.lv, LuckyId, About1))
                    end
            end,
            %% 日志 strengthen:装备强化 
            About = lists:concat(["strengthen ",GoodsInfo#goods.id," +",GoodsInfo#goods.stren," => +",NewGoodsInfo#goods.stren]),
            log:log_consume(goods_stren, coin, PlayerStatus, NewPlayerStatus, GoodsInfo#goods.goods_id, 1, About),
            Dict = lib_goods_dict:handle_dict(NewStatus5#goods_status.dict),
            NewStatus6 = NewStatus5#goods_status{dict = Dict},
            {ok, Res, NewPlayerStatus, NewStatus6, NewGoodsInfo}
        end,
    lib_goods_util:transaction(F).
    
strengthen_ok(PlayerStatus, GoodsInfo, Bind, GoodsStatus, GoodsStrengthenRule, GoodsTypeInfo) ->
    NewStrengthen = GoodsInfo#goods.stren + 1,
    %% 强化失败次数
    Stren_ratio = 0,
    case GoodsStrengthenRule#ets_goods_strengthen.is_upgrade == 1 andalso GoodsTypeInfo /= [] of
        true -> 
         %% 删除原装备
            DelOldEquipGoodsStatus = lib_goods:delete_goods(GoodsInfo, GoodsStatus),
            %% 生成新装备,如果物品中有一个是绑定的，新物品就是绑定的
            %Bind = get_bind([{GoodsInfo,GoodsInfo#goods.num},{RuneInfo,1}] ++ GoodsList),
            Trade = case Bind > 0 of 
                true  -> 1; 
                false -> 0 
            end,
            %[NewStren, Prefix, Star] = count_upgrade_loss(GoodsInfo, RuneInfo),
            %%             io:format("NewStren=~p, Prefix=~p, Star=~p~n", [NewStren, Prefix, Star]),
            [Cell|NullCells] = DelOldEquipGoodsStatus#goods_status.null_cells,
            ChangeCellGoodsStatus = DelOldEquipGoodsStatus#goods_status{null_cells = NullCells},
            Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
            if
                GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                    Cell2 = GoodsInfo#goods.cell,
                    Loc = GoodsInfo#goods.location;
                true ->
                    Cell2 = Cell,
                    Loc = ?GOODS_LOC_BAG
            end,
            FirstPrefix = GoodsInfo#goods.prefix,
            Prefix      = GoodsInfo#goods.prefix,
            Addition1    = GoodsInfo#goods.addition_1,
            Addition2    = GoodsInfo#goods.addition_2,
            Addition3    = GoodsInfo#goods.addition_3,
            GoodsInfo2 = Info#goods{
                player_id = PlayerStatus#player_status.id, 
                location = Loc, cell = Cell2, num = 1, 
                bind = Bind, trade = Trade, color = max(Info#goods.color, GoodsInfo#goods.color),
                first_prefix = FirstPrefix, prefix = Prefix, 
                stren = NewStrengthen, stren_ratio = Stren_ratio,
                addition_1 = Addition1, 
                addition_2 = Addition2, 
                addition_3 = Addition3, 
                subtype=GoodsInfo#goods.subtype, 
                equip_type=GoodsInfo#goods.equip_type, 
                type=GoodsInfo#goods.type, 
                hole1_goods=GoodsInfo#goods.hole1_goods, 
                hole2_goods=GoodsInfo#goods.hole2_goods, 
                hole3_goods=GoodsInfo#goods.hole3_goods,
                reiki_list=GoodsInfo#goods.reiki_list},

            [AddGoodsInfo, AddGoodsStatus] = add_goods(GoodsInfo2, ChangeCellGoodsStatus),

            Dict = lib_goods_dict:handle_dict(AddGoodsStatus#goods_status.dict),
            ChangeDictGoodsStatus = AddGoodsStatus#goods_status{dict = Dict},
            if
                GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                    EquipSuit = lib_goods_util:change_equip_suit(ChangeDictGoodsStatus#goods_status.equip_suit, GoodsInfo#goods.suit_id, AddGoodsInfo#goods.suit_id),
                    SuitId = lib_goods_util:get_full_suit(EquipSuit);
                true ->
                    EquipSuit = ChangeDictGoodsStatus#goods_status.equip_suit,
                    SuitId    = ChangeDictGoodsStatus#goods_status.suit_id
            end,
            Stren7_num = lib_goods:add_stren7_num(AddGoodsInfo, ChangeDictGoodsStatus#goods_status.stren7_num),

            NewStatus    = ChangeDictGoodsStatus#goods_status{stren7_num = Stren7_num, suit_id = SuitId, equip_suit = EquipSuit},
            NewGoodsInfo = AddGoodsInfo;
        _ -> 
            %% 修改物品强化属性
            case Bind > 0 of
                true ->  
                    [NewGoodsInfo, NewStatus] = change_goods_stren(GoodsInfo, NewStrengthen, Stren_ratio, Bind, 1, GoodsStatus);
                false -> 
                    [NewGoodsInfo, NewStatus] = change_goods_stren(GoodsInfo, NewStrengthen, Stren_ratio, GoodsInfo#goods.bind, GoodsInfo#goods.trade, GoodsStatus)
            end
    end,
    [NewGoodsInfo, NewStatus].

strengthen_fail(GoodsInfo, Bind, GoodsStatus, GoodsStrengthenRule) ->
    FailStren = util:rand_with_weight(GoodsStrengthenRule#ets_goods_strengthen.fail_level),
    NewStrengthen = max(0, GoodsInfo#goods.stren - FailStren),
    %% 强化附加成功率
    Stren_ratio =  GoodsInfo#goods.stren_ratio + 1,
    case Bind > 0 of
        true ->
            [NewGoodsInfo, NewStatus] = change_goods_stren(GoodsInfo, NewStrengthen, Stren_ratio, Bind, 1, GoodsStatus);
        false ->
            [NewGoodsInfo, NewStatus] = change_goods_stren(GoodsInfo, NewStrengthen, Stren_ratio, GoodsInfo#goods.bind, GoodsInfo#goods.trade, GoodsStatus)
    end,
    [NewGoodsInfo, NewStatus].

%% 分解重叠
resolve_clean_bag(PlayerStatus, GoodsStatus) ->
    %% 查询背包物品列表
    GoodsList = lib_goods_util:get_goods_list(GoodsStatus#goods_status.player_id, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
    %% 按物品类型ID排序
    GoodsList1 = lib_goods_util:sort(GoodsList, bind_id),
    %% 整理
    [Num, _, NewStatus] = lists:foldl(fun lib_goods:clean_bag/2, [1, {}, GoodsStatus], GoodsList1),
    %% 重新计算
    if
        Num >= PlayerStatus#player_status.cell_num ->
            Num1 = PlayerStatus#player_status.cell_num;
        true ->
            Num1 = Num
    end,
    NullCells = lists:seq(Num1, PlayerStatus#player_status.cell_num),
    NewStatus#goods_status{null_cells = NullCells}.

%% 分解绿色
resolve_gream(_PlayerId, [], [], G, L, R, S) ->
    {S, L, R, G};
resolve_gream(PlayerId, [GoodsInfo|T], [Rule|H], GoodsStatus, L, R, S) ->
    Bind = get_bind([GoodsInfo]),
    Trade = case Bind > 0 of 
                true ->
                    1;
                false ->
                    0
            end,
    %% 分解新物品
    Stone_Ram = util:rand(1, 100),
    case Rule#ets_goods_resolve.stone_ratio >= Stone_Ram of
        true ->
            GoodsId = Rule#ets_goods_resolve.stone_id,
            GoodsNum = 1,
            GoodsTypeInfo = case  data_goods_type:get(GoodsId) of
                                [] ->
                                    #ets_goods_type{};
                                TypeInfo ->
                                    TypeInfo
                            end,
            Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
            if
                GoodsStatus#goods_status.null_cells =:= [] ->
                    StoneInfo = #goods{},
                    NewGoodsStatus1 = GoodsStatus;
                true ->
                    [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
                    NewGoodsStatus = GoodsStatus#goods_status{null_cells = NullCells},
                    NewInfo = Info#goods{player_id = PlayerId, location = ?GOODS_LOC_BAG, cell=Cell, num=GoodsNum, bind=Bind, trade=Trade},
                    [StoneInfo, NewGoodsStatus1] = add_goods(NewInfo, NewGoodsStatus)
            end;
        false ->
            StoneInfo = #goods{},
            NewGoodsStatus1 = GoodsStatus
    end,
    %% 幸运符
    Ram = util:rand(1, 100),
    case Rule#ets_goods_resolve.lucky_ratio >= Ram of
        true ->
            GoodsId1 = Rule#ets_goods_resolve.lucky_id,
            GoodsTypeInfo1 = case  data_goods_type:get(GoodsId1) of
                                [] ->
                                    #ets_goods_type{};
                                TypeInfo1 ->
                                    TypeInfo1
                            end,
            Info1 = lib_goods_util:get_new_goods(GoodsTypeInfo1),
            if
                NewGoodsStatus1#goods_status.null_cells =:= [] ->
                    LuckyInfo = #goods{},
                    NewGoodsStatus3 = NewGoodsStatus1;
                true ->
                    [Cell1|NullCells1] = NewGoodsStatus1#goods_status.null_cells,
                    NewGoodsStatus2 = NewGoodsStatus1#goods_status{null_cells = NullCells1},
                    NewInfo1 = Info1#goods{player_id = PlayerId, location = ?GOODS_LOC_BAG, cell=Cell1, num=1, bind=Bind, trade=Trade},
                    [LuckyInfo, NewGoodsStatus3] = add_goods(NewInfo1, NewGoodsStatus2)
            end;
        false ->
            LuckyInfo = #goods{},
            NewGoodsStatus3 = NewGoodsStatus1
    end,
     %%保留物品
    Ram1 = util:rand(1, 100),
    case Rule#ets_goods_resolve.reserve_ratio >= Ram1 of
        true ->
            GoodsId2 = Rule#ets_goods_resolve.reserve_id,
            GoodsTypeInfo2 = case  data_goods_type:get(GoodsId2) of
                                [] ->
                                    #ets_goods_type{};
                                TypeInfo2 ->
                                    TypeInfo2
                            end,
            Info2 = lib_goods_util:get_new_goods(GoodsTypeInfo2),
            if
                NewGoodsStatus3#goods_status.null_cells =:= [] ->
                    ReserveInfo = #goods{},
                    NewGoodsStatus5 = NewGoodsStatus3;
                true ->
                    [Cell2|NullCells2] = NewGoodsStatus3#goods_status.null_cells,
                    NewGoodsStatus4 = NewGoodsStatus3#goods_status{null_cells = NullCells2},
                    NewInfo2 = Info2#goods{player_id = PlayerId, location = ?GOODS_LOC_BAG, cell=Cell2, num=1, bind=Bind, trade=Trade},
                    [ReserveInfo, NewGoodsStatus5] = add_goods(NewInfo2, NewGoodsStatus4)
            end;
        false ->
            ReserveInfo = #goods{},
            NewGoodsStatus5 = NewGoodsStatus3
    end,
    Linfo = case LuckyInfo#goods.goods_id > 0 of
        true -> [LuckyInfo|L];
        false -> L
    end,
    Rinfo = case ReserveInfo#goods.goods_id > 0 of
        true -> [ReserveInfo|R];
        false -> R
    end,
    Sinfo = case StoneInfo#goods.goods_id > 0 of
        true -> [StoneInfo|S];
        false -> S
    end,
    resolve_gream(PlayerId, T, H, NewGoodsStatus5, Linfo, Rinfo, Sinfo).
   
%% 分解蓝色
resolve_blue(_PlayerId, [], [], G, L, R, S) ->
    {S, L, R, G};
resolve_blue(PlayerId, [GoodsInfo|T], [Rule|H], GoodsStatus, L, R, S) ->
    Bind = get_bind([GoodsInfo]),
    Trade = case Bind > 0 of 
                true ->
                    1;
                false ->
                    0
            end,
    %% 分解新物品
    Stone_Ram = util:rand(1, 100),
    case Rule#ets_goods_resolve.stone_ratio >= Stone_Ram of
        true ->
            GoodsId = Rule#ets_goods_resolve.stone_id,
            GoodsNum = 1,
            GoodsTypeInfo = case  data_goods_type:get(GoodsId) of
                                [] ->
                                    #ets_goods_type{};
                                TypeInfo ->
                                    TypeInfo
                            end,
            Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
            if
                GoodsStatus#goods_status.null_cells =:= [] ->
                    StoneInfo = #goods{},
                    NewGoodsStatus1 = GoodsStatus;
                true ->
                    [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
                    NewGoodsStatus = GoodsStatus#goods_status{null_cells = NullCells},
                    NewInfo = Info#goods{player_id = PlayerId, location = ?GOODS_LOC_BAG, cell=Cell, num=GoodsNum, bind=Bind, trade=Trade},
                    [StoneInfo, NewGoodsStatus1] = add_goods(NewInfo, NewGoodsStatus)
            end;
        false ->
            StoneInfo = #goods{},
            NewGoodsStatus1 = GoodsStatus
    end,
    %% 幸运符
    Ram = util:rand(1, 100),
    case Rule#ets_goods_resolve.lucky_ratio >= Ram of
        true ->
            GoodsId1 = Rule#ets_goods_resolve.lucky_id,
            GoodsTypeInfo1 = case  data_goods_type:get(GoodsId1) of
                                [] ->
                                    #ets_goods_type{};
                                TypeInfo1 ->
                                    TypeInfo1
                            end,
            Info1 = lib_goods_util:get_new_goods(GoodsTypeInfo1),
            if
                NewGoodsStatus1#goods_status.null_cells =:= [] ->
                    LuckyInfo = #goods{},
                    NewGoodsStatus3 = NewGoodsStatus1;
                true ->
                    [Cell1|NullCells1] = NewGoodsStatus1#goods_status.null_cells,
                    NewGoodsStatus2 = NewGoodsStatus1#goods_status{null_cells = NullCells1},
                    NewInfo1 = Info1#goods{player_id = PlayerId, location = ?GOODS_LOC_BAG, cell=Cell1, num=1, bind=Bind, trade=Trade},
                    [LuckyInfo, NewGoodsStatus3] = add_goods(NewInfo1, NewGoodsStatus2)
            end;
        false ->
            LuckyInfo = #goods{},
            NewGoodsStatus3 = NewGoodsStatus1
    end,
     %%保留物品
    Ram1 = util:rand(1, 100),
    case Rule#ets_goods_resolve.reserve_ratio >= Ram1 of
        true ->
            GoodsId2 = Rule#ets_goods_resolve.reserve_id,
            GoodsTypeInfo2 = case  data_goods_type:get(GoodsId2) of
                                [] ->
                                    #ets_goods_type{};
                                TypeInfo2 ->
                                    TypeInfo2
                            end,
            Info2 = lib_goods_util:get_new_goods(GoodsTypeInfo2),
            if
                NewGoodsStatus3#goods_status.null_cells =:= [] ->
                    ReserveInfo = #goods{},
                    NewGoodsStatus5 = NewGoodsStatus3;
                true ->
                    [Cell2|NullCells2] = NewGoodsStatus3#goods_status.null_cells,
                    NewGoodsStatus4 = NewGoodsStatus3#goods_status{null_cells = NullCells2},
                    NewInfo2 = Info2#goods{player_id = PlayerId, location = ?GOODS_LOC_BAG, cell=Cell2, num=1, bind=Bind, trade=Trade},
                    [ReserveInfo, NewGoodsStatus5] = add_goods(NewInfo2, NewGoodsStatus4)
            end;
        false ->
            ReserveInfo = #goods{},
            NewGoodsStatus5 = NewGoodsStatus3
    end,
    Linfo = case LuckyInfo#goods.goods_id > 0 of
        true -> [LuckyInfo|L];
        false -> L
    end,
    Rinfo = case ReserveInfo#goods.goods_id > 0 of
        true -> [ReserveInfo|R];
        false -> R
    end,
    Sinfo = case StoneInfo#goods.goods_id > 0 of
        true -> [StoneInfo|S];
        false -> S
    end,        
    resolve_blue(PlayerId, T, H, NewGoodsStatus5, Linfo, Rinfo, Sinfo).

%% 分解紫色
resolve_purple(_PlayerId, [], [], G, L, R, S) ->
    {S, L, R, G};
resolve_purple(PlayerId, [GoodsInfo|T], [Rule|H], GoodsStatus, L, R, S) ->
    Bind = get_bind([GoodsInfo]),
    Trade = case Bind > 0 of 
                true ->
                    1;
                false ->
                    0
            end,
    %% 分解新物品
    Stone_Ram = util:rand(1, 100),
    case Rule#ets_goods_resolve.stone_ratio >= Stone_Ram of
        true ->
            GoodsId = Rule#ets_goods_resolve.stone_id,
            GoodsTypeInfo = case  data_goods_type:get(GoodsId) of
                                [] ->
                                    #ets_goods_type{};
                                TypeInfo ->
                                    TypeInfo
                            end,
            Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
            if
                GoodsStatus#goods_status.null_cells =:= [] ->
                    StoneInfo = #goods{},
                    NewGoodsStatus1 = GoodsStatus;
                true ->
                    [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
                    NewGoodsStatus = GoodsStatus#goods_status{null_cells = NullCells},
                    NewInfo = Info#goods{player_id = PlayerId, location = ?GOODS_LOC_BAG, cell=Cell, num=1, bind=Bind, trade=Trade},
                    [StoneInfo, NewGoodsStatus1] = add_goods(NewInfo, NewGoodsStatus)
            end;
        false ->
            StoneInfo = #goods{},
            NewGoodsStatus1 = GoodsStatus
    end,
    %% 幸运符
    Ram = util:rand(1, 100),
    case Rule#ets_goods_resolve.lucky_ratio >= Ram of
        true ->
            GoodsId1 = Rule#ets_goods_resolve.lucky_id,
            GoodsTypeInfo1 = case  data_goods_type:get(GoodsId1) of
                                [] ->
                                    #ets_goods_type{};
                                TypeInfo1 ->
                                    TypeInfo1
                            end,
            Info1 = lib_goods_util:get_new_goods(GoodsTypeInfo1),
            if
                NewGoodsStatus1#goods_status.null_cells =:= [] ->
                    LuckyInfo = #goods{},
                    NewGoodsStatus3 = NewGoodsStatus1;
                true ->
                    [Cell1|NullCells1] = NewGoodsStatus1#goods_status.null_cells,
                    NewGoodsStatus2 = NewGoodsStatus1#goods_status{null_cells = NullCells1},
                    NewInfo1 = Info1#goods{player_id = PlayerId, location = ?GOODS_LOC_BAG, cell=Cell1, num=1, bind=Bind, trade=Trade},
                    [LuckyInfo, NewGoodsStatus3] = add_goods(NewInfo1, NewGoodsStatus2)
            end;
        false ->
            LuckyInfo = #goods{},
            NewGoodsStatus3 = NewGoodsStatus1
    end,
     %%保留物品
    Ram1 = util:rand(1, 100),
    case Rule#ets_goods_resolve.reserve_ratio >= Ram1 of
        true ->
            GoodsId2 = Rule#ets_goods_resolve.reserve_id,
            GoodsTypeInfo2 = case  data_goods_type:get(GoodsId2) of
                                [] ->
                                    #ets_goods_type{};
                                TypeInfo2 ->
                                    TypeInfo2
                            end,
            Info2 = lib_goods_util:get_new_goods(GoodsTypeInfo2),
            if
                NewGoodsStatus3#goods_status.null_cells =:= [] ->
                    ReserveInfo = #goods{},
                    NewGoodsStatus5 = NewGoodsStatus3;
                true ->
                    [Cell2|NullCells2] = NewGoodsStatus3#goods_status.null_cells,
                    NewGoodsStatus4 = NewGoodsStatus3#goods_status{null_cells = NullCells2},
                    NewInfo2 = Info2#goods{player_id = PlayerId, location = ?GOODS_LOC_BAG, cell=Cell2, num=1, bind=Bind, trade=Trade},
                    [ReserveInfo, NewGoodsStatus5] = add_goods(NewInfo2, NewGoodsStatus4)
            end;
        false ->
            ReserveInfo = #goods{},
            NewGoodsStatus5 = NewGoodsStatus3
    end,
     Linfo = case LuckyInfo#goods.goods_id > 0 of
        true -> [LuckyInfo|L];
        false -> L
    end,
    Rinfo = case ReserveInfo#goods.goods_id > 0 of
        true -> [ReserveInfo|R];
        false -> R
    end,
    Sinfo = case StoneInfo#goods.goods_id > 0 of
        true -> [StoneInfo|S];
        false -> S
    end,
    resolve_purple(PlayerId, T, H, NewGoodsStatus5, Linfo, Rinfo, Sinfo).

get_all_resolve_id([], L) ->
    L;
get_all_resolve_id([GoodsInfo|H], L) ->
    case GoodsInfo =/= [] of
        true ->
            get_all_resolve_id(H, [GoodsInfo#goods.goods_id]++L);
        false ->
            get_all_resolve_id(H, L)
    end.

%% 装备分解
goods_resolve(PlayerStatus, GoodsStatus, GreamList, GreamRule, BlueList, BlueRule, PurpleList, PurpleRule, Cost) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 花费铜钱
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
            %% 删除装备
            case length(GreamList) > 0 of
                true ->
                    {ok, Status1} = lib_goods:delete_goods_list(GoodsStatus, GreamList),
                    {StoneList1, LuckList1, Reserve1, NewStatus1} = resolve_gream(PlayerStatus#player_status.id, GreamList, GreamRule, Status1, [], [], []);
                false ->
                    NewStatus1 = GoodsStatus,
                    LuckList1 = [], 
                    StoneList1 = [],
                    Reserve1 = []
            end,
            case length(BlueList) > 0 of
                true ->
                    {ok, Status2} = lib_goods:delete_goods_list(NewStatus1, BlueList),
                    {StoneList2, LuckList2, Reserve2,NewStatus2} = resolve_blue(PlayerStatus#player_status.id, BlueList, BlueRule, Status2, [], [], []);
                false ->
                    NewStatus2 = NewStatus1,
                    LuckList2 = [], 
                    StoneList2 = [],
                    Reserve2 = []
            end,
            case length(PurpleList) > 0 of
                true ->
                    {ok, Status3} = lib_goods:delete_goods_list(NewStatus2, PurpleList),
                    {StoneList3, LuckList3, Reserve3, NewStatus3} = resolve_purple(PlayerStatus#player_status.id, PurpleList, PurpleRule, Status3, [], [], []);
                false ->
                    NewStatus3 = NewStatus2,
                    LuckList3 = [], 
                    StoneList3 = [],
                    Reserve3 = []
            end,
            %% 日志
            NewList = StoneList1++StoneList2++StoneList3++LuckList1++LuckList2++LuckList3++Reserve1++Reserve2++Reserve3,
            IdList = get_all_resolve_id(NewList, []),
            About1 = lists:concat([lists:concat([Info#goods.goods_id,":",Num,","]) || {Info, Num} <- GreamList++BlueList++PurpleList]),
            log:log_equip_resolve(PlayerStatus#player_status.id, About1, IdList),
            About3 = lists:concat(["equip_resolve",About1]),
            log:log_consume(goods_resolve, coin, PlayerStatus, NewPlayerStatus, About3),
            Dict = lib_goods_dict:handle_dict(NewStatus3#goods_status.dict),
            NewGoodsStatus4 = NewStatus3#goods_status{dict = Dict},
            NewGoodsStatus5 = resolve_clean_bag(NewPlayerStatus, NewGoodsStatus4),
            {ok, NewPlayerStatus, NewGoodsStatus5, StoneList1, StoneList2, StoneList3, 
             LuckList1, LuckList2, LuckList3, Reserve1, Reserve2, Reserve3}
        end,
    lib_goods_util:transaction(F).

%% 装备合成(融合,蓝色+紫色+紫色)
equip_compose(PlayerStatus, GoodsStatus, GoodsTypeInfo, GoodsInfo1, GoodsInfo2, GoodsInfo3) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 花费铜钱
            Cost = data_goods:count_equip_compose_cost(),
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
            GoodsList = [{GoodsInfo1,1},{GoodsInfo2,1},{GoodsInfo3,1}],
            %% 删除装备
            {ok, NewStatus} = lib_goods:delete_goods_list(GoodsStatus, GoodsList),
            %% 装备合成
            Bind = get_bind(GoodsList),
            Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
            case Bind > 0 of
                true ->  Trade = 1;
                false -> Trade = 0
            end,
            Prefix = lists:min([GoodsInfo1#goods.prefix, GoodsInfo2#goods.prefix, GoodsInfo3#goods.prefix]),
            %% 格子
            [Cell|NullCells] = NewStatus#goods_status.null_cells,
            NewGoodsStatus = NewStatus#goods_status{null_cells = NullCells},
            GoodsInfo = Info#goods{player_id = PlayerStatus#player_status.id, location = ?GOODS_LOC_BAG, cell=Cell, num=1, bind=Bind, trade=Trade, prefix=Prefix},
            %% 添加新装备
            [NewGoodsInfo, NewGoodsStatus1] = add_goods(GoodsInfo, NewGoodsStatus),
            %% 日志       equip_compose:装备合成 
            About1 = lists:concat([GoodsInfo1#goods.id,":",GoodsInfo1#goods.goods_id,"+",GoodsInfo2#goods.id,":",GoodsInfo2#goods.goods_id,"+",GoodsInfo3#goods.id,":",GoodsInfo3#goods.goods_id,"=>",NewGoodsInfo#goods.id,":",NewGoodsInfo#goods.goods_id]),
            log:log_equip_compose(PlayerStatus#player_status.id, About1),
            About2 = lists:concat(["equip_compose ",About1]),
            log:log_consume(equip_compose, coin, PlayerStatus, NewPlayerStatus, NewGoodsInfo#goods.goods_id, 1, About2),
            Dict = lib_goods_dict:handle_dict(NewGoodsStatus1#goods_status.dict),
            NewGoodsStatus2 = NewGoodsStatus1#goods_status{dict = Dict},
            {ok, NewPlayerStatus, NewGoodsStatus2, NewGoodsInfo}
        end,
    lib_goods_util:transaction(F).

%% 装备继承(基础属性+附加属性和强化)
equip_inherit(PlayerStatus, GoodsStatus, LowInfo, HighInfo, StuffList, _InheritRule, Flag, Cost) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 花费铜钱
            %Cost =InheritRule#ets_inherit.coin,
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
            GoodsList = [{LowInfo,1},{HighInfo,1}] ++ StuffList,
            %% 删除装备
            {ok, NewStatus} = lib_goods:delete_goods_list(GoodsStatus, GoodsList),
            %% 新装备
            Bind = get_bind(GoodsList),
            case Bind > 0 of
                true ->  Trade = 1;
                false -> Trade = 0
            end,
           
            %% 添加新装备
            [NewGoodsInfo, NewGoodsStatus1] = inherit_new_goods(LowInfo, HighInfo, NewStatus, Bind, Trade, Flag),
            %% 宝石
            NewGoodsStatus2 = inherit_new_stone(LowInfo, HighInfo, NewGoodsStatus1, Bind, Trade, NewPlayerStatus#player_status.id),
            %% 写log
            [{StuffInfo, _N}|_] = StuffList,
            About1 = lists:concat([LowInfo#goods.id,":",LowInfo#goods.goods_id,"+",HighInfo#goods.id,":",HighInfo#goods.goods_id,"+",StuffInfo#goods.id,":",StuffInfo#goods.goods_id,"=>",NewGoodsInfo#goods.id,":",NewGoodsInfo#goods.goods_id]),
            log:log_equip_inherit(PlayerStatus#player_status.id, About1),
            About2 = lists:concat(["equip_inherit ",About1]),
            log:log_consume(equip_inherit, coin, PlayerStatus, NewPlayerStatus, NewGoodsInfo#goods.goods_id, 1, About2),
            Dict = lib_goods_dict:handle_dict(NewGoodsStatus2#goods_status.dict),
            NewGoodsStatus3 = NewGoodsStatus2#goods_status{dict = Dict},
            {ok, NewPlayerStatus, NewGoodsStatus3, NewGoodsInfo#goods.goods_id, NewGoodsInfo#goods.bind, NewGoodsInfo#goods.prefix, NewGoodsInfo#goods.stren}
        end,
    lib_goods_util:transaction(F).

%% 继承脱下宝石
inherit_new_stone(LowInfo, HighInfo, GoodsStatus, Bind, Trade, PlayerId) ->
    case LowInfo#goods.hole1_goods > 0 of
        true ->
            [_, NewGoodsStatus1] = add_stone_goods(LowInfo#goods.hole1_goods, Bind, Trade, PlayerId, GoodsStatus);
        false ->
            NewGoodsStatus1 = GoodsStatus
    end,
    case LowInfo#goods.hole2_goods > 0 of
        true ->
            [_, NewGoodsStatus2] = add_stone_goods(LowInfo#goods.hole2_goods, Bind, Trade, PlayerId, NewGoodsStatus1);
        false ->
            NewGoodsStatus2 = NewGoodsStatus1
    end,
    case LowInfo#goods.hole3_goods > 0 of
        true ->
            [_, NewGoodsStatus3] = add_stone_goods(LowInfo#goods.hole3_goods, Bind, Trade, PlayerId, NewGoodsStatus2);
        false ->
            NewGoodsStatus3 = NewGoodsStatus2
    end,

    case HighInfo#goods.hole1_goods > 0 of
        true ->
            [_, NewGoodsStatus4] = add_stone_goods(HighInfo#goods.hole1_goods, Bind, Trade, PlayerId, NewGoodsStatus3);
        false ->
            NewGoodsStatus4 = NewGoodsStatus3
    end,
    case HighInfo#goods.hole2_goods > 0 of
        true ->
            [_, NewGoodsStatus5] = add_stone_goods(HighInfo#goods.hole2_goods, Bind, Trade, PlayerId, NewGoodsStatus4);
        false ->
            NewGoodsStatus5 = NewGoodsStatus4
    end,
    case HighInfo#goods.hole3_goods > 0 of
        true ->
            [_, NewGoodsStatus6] = add_stone_goods(HighInfo#goods.hole3_goods, Bind, Trade, PlayerId, NewGoodsStatus5);
        false ->
            NewGoodsStatus6 = NewGoodsStatus5
    end,
    NewGoodsStatus6.

add_stone_goods(GoodsTypeId, Bind, Trade, PlayerId, GoodsStatus) ->
    case data_goods_type:get(GoodsTypeId) of
        [] ->
            [0, GoodsStatus];
    GoodsTypeInfo ->
        Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
        %% 格子
        [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
        NewGoodsStatus = GoodsStatus#goods_status{null_cells = NullCells},
        NewInfo = Info#goods{player_id = PlayerId, bind = Bind, trade = Trade, cell = Cell, num = 1, location = ?GOODS_LOC_BAG},
        %% 添加宝石
        add_goods(NewInfo, NewGoodsStatus)
    end.

%% 继承出新装备
inherit_new_goods(_LowInfo, HighInfo, GoodsStatus, _Bind, _Trade, _Flag) ->
    [HighInfo, GoodsStatus].

    % [A, B, C, D, E, F] = integer_to_list(LowInfo#goods.goods_id),
    % [_A1, _B1, _C1, _D1, E1, F1] = integer_to_list(HighInfo#goods.goods_id),
    % LowF = list_to_integer([F]),
    % HighF = list_to_integer([F1]),
    %         %% 女武器为6,7,8,9,0,+5取个位为颜色
    % if 
    %      LowF > 5 ->
    %         [_Ten, Bit] = integer_to_list(LowF+5),
    %         LowF1 = list_to_integer([Bit]);
    %     LowF =:= 0 ->
    %         LowF1 = LowF+5;
    %     true ->
    %         LowF1 = LowF
    % end,
    % if
    %     HighF > 5 ->
    %         [_Ten1, Bit1] = integer_to_list(HighF+5),
    %         HighF1 = list_to_integer([Bit1]);
    %     HighF =:= 0 ->
    %         HighF1 = HighF+5;
    %     true ->
    %         HighF1 = HighF
    % end,
    % case LowF1 =:= HighF1 of
    %     true ->
    %         %% 个位颜色相等
    %         F2 = LowF1,
    %         case list_to_integer([E]) >= list_to_integer([E1]) of
    %             true ->
    %                 E2 = E;
    %             false ->
    %                 E2 =E1
    %         end;
    %     false ->
    %         case LowF1 > HighF1 of
    %             true ->
    %                 F2 = LowF1;
    %             false ->
    %                 F2 = HighF1
    %         end,
    %         case LowF1 =:= 5 of % 橙色
    %             true ->
    %                 E2 = E;
    %             false ->
    %                 case HighF1 =:= 5 of
    %                     true ->
    %                         E2 = E1;
    %                     false ->
    %                         case list_to_integer([E]) >= list_to_integer([E1]) of
    %                             true ->
    %                                 E2 = E;
    %                             false ->
    %                                 E2 = E1
    %                         end
    %                 end
    %         end
    % end,
    % %% 返回原形，女武器用
    % case Flag =:= 1 of
    %     true ->
    %         case F2 =:= 5 of
    %             true ->
    %                 [_, Bit2] = integer_to_list(F2 + 5);
    %             false ->
    %                 [Bit2] = integer_to_list(F2 + 5)
    %         end;
    %     false ->
    %         [Bit2] = integer_to_list(F2)
    % end,
    % %io:format("inherit =~p~n", [{Flag, [A],[B],[C],[D],[E2],[Bit2], F2}]),
    % NewGoodsTypeId = list_to_integer(lists:concat([[A],[B],[C],[D],[E2],[Bit2]])),
    % %io:format("inherit =~p~n", [{Flag, [A],[B],[C],[D],[E2],[Bit], NewGoodsTypeId}]),
    % GoodsTypeInfo = data_goods_type:get(NewGoodsTypeId),
    % %case is_record(GoodsTypeInfo, ets_goods_type) of
    %     %true ->
    %         Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
    %         if
    %             HighInfo#goods.addition =:= [] andalso LowInfo#goods.addition =/= [] ->
    %                 NewAttribute = LowInfo#goods.addition;
    %             HighInfo#goods.addition =/= [] andalso LowInfo#goods.addition =:= [] ->
    %                 NewAttribute = HighInfo#goods.addition;
    %             HighInfo#goods.addition =:= [] andalso LowInfo#goods.addition =:= [] ->
    %                 NewAttribute = HighInfo#goods.addition;
    %             true ->
    %                 LowAttribute = data_goods:get_addition_power(LowInfo), 
    %                 HighAttribute = data_goods:get_addition_power(HighInfo),
    %         %%新附加属性
    %                 NewAttribute = case HighAttribute > LowAttribute of
    %                             true ->
    %                                 HighInfo#goods.addition;
    %                             false ->
    %                                 LowInfo#goods.addition
    %                         end
    %         end,
    %         %% 强化数
    %         NewStren = case HighInfo#goods.stren >= LowInfo#goods.stren of
    %                 true ->
    %                     HighInfo#goods.stren;
    %                 false ->
    %                     LowInfo#goods.stren
    %             end,
    %         %% 前缀
    %         Prefix = case HighInfo#goods.prefix >= LowInfo#goods.prefix of
    %             true ->
    %                 HighInfo#goods.prefix;
    %             false ->
    %                 LowInfo#goods.prefix
    %         end,
    %         %% 洗炼星下限
    %         MinStar = case  HighInfo#goods.min_star >= LowInfo#goods.min_star of
    %             true ->
    %                 HighInfo#goods.min_star;
    %             false ->
    %                 LowInfo#goods.min_star
    %         end,
    %         %% 格子
    %         [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
    %         NewGoodsStatus = GoodsStatus#goods_status{null_cells = NullCells},
    %         if
    %             HighInfo#goods.reiki_level >= LowInfo#goods.reiki_level ->
    %                 NewInfo = Info#goods{player_id = HighInfo#goods.player_id, stren = NewStren, addition = NewAttribute,
    %             bind = Bind, trade = Trade, cell = Cell, prefix = Prefix, num = 1, min_star = MinStar, location = ?GOODS_LOC_BAG, reiki_level=HighInfo#goods.reiki_level, qi_level=HighInfo#goods.qi_level, reiki_value=HighInfo#goods.reiki_value, reiki_times=HighInfo#goods.reiki_times, reiki_list=HighInfo#goods.reiki_list},
    %                 [NewGoodsInfo, NewStatus] = add_goods(NewInfo, NewGoodsStatus),
    %                 case NewGoodsInfo#goods.reiki_level > 0 of
    %                     true ->
    %                         Sql = io_lib:format(<<"UPDATE add_reiki set gid = ~p where gid = ~p">>, [NewGoodsInfo#goods.id, HighInfo#goods.id]),
    %                         db:execute(Sql);
    %                     false ->
    %                         skip
    %                 end;
    %             true ->
    %                 NewInfo = Info#goods{player_id = HighInfo#goods.player_id, stren = NewStren, addition = NewAttribute,
    %             bind = Bind, trade = Trade, cell = Cell, prefix = Prefix, num = 1, min_star = MinStar, location = ?GOODS_LOC_BAG, reiki_level=LowInfo#goods.reiki_level, qi_level=LowInfo#goods.qi_level, reiki_value=LowInfo#goods.reiki_value, reiki_times=LowInfo#goods.reiki_times, reiki_list=LowInfo#goods.reiki_list},
    %                 [NewGoodsInfo, NewStatus] = add_goods(NewInfo, NewGoodsStatus),
    %                 case NewGoodsInfo#goods.reiki_level > 0 of
    %                     true ->
    %                         Sql = io_lib:format(<<"UPDATE add_reiki set gid = ~p where gid = ~p">>, [NewGoodsInfo#goods.id, LowInfo#goods.id]),
    %                         db:execute(Sql);
    %                     false ->
    %                         skip
    %                 end
    %         end,
    %         [NewGoodsInfo, NewStatus].
            
%% 装备精炼
weapon_compose(PlayerStatus, GoodsStatus, GoodsTypeInfo, GoodsInfo, RuleInfo, StoneList, StuffList) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 花费铜钱
            PlayerStatus2 = lib_goods_util:cost_money(PlayerStatus, RuleInfo#ets_weapon_compose.coin, coin),
            %% 删除石头
            GoodsList = [{GoodsInfo,GoodsInfo#goods.num}|StoneList] ++ StuffList,
            {ok, NewStatus} = lib_goods:delete_goods_list(GoodsStatus, GoodsList),
            %% 装备合成
            Bind = get_bind(GoodsList),
            Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
            case Bind > 0 of
                true ->  
                    Trade = 1;
                false -> 
                    Trade = 0
            end,
            Prefix = GoodsInfo#goods.prefix,
            Stren = GoodsInfo#goods.stren,
            Addition1 = GoodsInfo#goods.addition_1,
            Addition2 = GoodsInfo#goods.addition_2,
            Addition3 = GoodsInfo#goods.addition_3,
            [Cell|NullCells] = NewStatus#goods_status.null_cells,
            NewGoodsStatus = NewStatus#goods_status{null_cells = NullCells},
            GoodsInfo2 = Info#goods{player_id = PlayerStatus#player_status.id, location = GoodsInfo#goods.location, cell = Cell, num = 1, bind = Bind, trade = Trade, prefix = Prefix, stren = Stren, addition_1 = Addition1, addition_2 = Addition2, addition_3 = Addition3, subtype=GoodsInfo#goods.subtype,equip_type=GoodsInfo#goods.equip_type, type=GoodsInfo#goods.type},
            [NewGoodsInfo, NewGoodsStatus1] = add_goods(GoodsInfo2, NewGoodsStatus),
            %% 日志
            About1 = lists:concat([lists:concat([StoneInfo#goods.goods_id,":",GoodsNum,","]) || {StoneInfo, GoodsNum} <- StoneList++StuffList]),
            log:log_weapon_compose(PlayerStatus#player_status.id, RuleInfo, GoodsInfo, NewGoodsInfo, About1),
            About2 = lists:concat(["weapon_compose",About1]),
            log:log_consume(weapon_compose, coin, PlayerStatus, PlayerStatus2, NewGoodsInfo#goods.goods_id, 1, About2),
            Dict = lib_goods_dict:handle_dict(NewGoodsStatus1#goods_status.dict),
            NewGoodsStatus2 = NewGoodsStatus1#goods_status{dict = Dict},
            {ok, PlayerStatus2, NewGoodsStatus2, NewGoodsInfo}
        end,
    lib_goods_util:transaction(F).

%% 装备进阶
equip_advanced(PlayerStatus, GoodsStatus, GoodsTypeInfo, GoodsInfo, RuleInfo, StoneList, StuffList) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 花费铜钱
            PlayerStatus2 = lib_goods_util:cost_money(PlayerStatus, RuleInfo#ets_weapon_compose.coin, coin),
            %% 删除石头
            GoodsList = [{GoodsInfo,GoodsInfo#goods.num}|StoneList] ++ StuffList,
            {ok, NewStatus} = lib_goods:delete_goods_list(GoodsStatus, GoodsList),
            %% 装备合成
            Bind = get_bind(GoodsList),
            Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
            case Bind > 0 of
                true ->  
                    Trade = 1;
                false -> 
                    Trade = 0
            end,
            FirstPrefix = GoodsInfo#goods.prefix,
            Prefix      = GoodsInfo#goods.prefix,
            Stren       = GoodsInfo#goods.stren,
            Addition1    = GoodsInfo#goods.addition_1,
            Addition2    = GoodsInfo#goods.addition_2,
            Addition3    = GoodsInfo#goods.addition_3,

            [Cell|NullCells] = NewStatus#goods_status.null_cells,
            if
                GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                    Cell2 = GoodsInfo#goods.cell;
                true ->
                    Cell2 = Cell
            end,
            NewGoodsStatus = NewStatus#goods_status{null_cells = NullCells},
            GoodsInfo2 = Info#goods{player_id = PlayerStatus#player_status.id, location = GoodsInfo#goods.location, cell = Cell2, num = 1, bind = Bind, trade = Trade, first_prefix = FirstPrefix, prefix = Prefix, stren = Stren, addition_1 = Addition1, addition_2 = Addition2, addition_3 = Addition3, subtype=GoodsInfo#goods.subtype, equip_type=GoodsInfo#goods.equip_type, type=GoodsInfo#goods.type, hole1_goods=GoodsInfo#goods.hole1_goods, hole2_goods=GoodsInfo#goods.hole2_goods, hole3_goods=GoodsInfo#goods.hole3_goods, reiki_level = GoodsInfo#goods.reiki_level, qi_level=GoodsInfo#goods.qi_level, reiki_value=GoodsInfo#goods.reiki_value, reiki_times=GoodsInfo#goods.reiki_times, reiki_list=GoodsInfo#goods.reiki_list},
            [NewGoodsInfo, NewGoodsStatus1] = add_goods(GoodsInfo2, NewGoodsStatus),
            if
                GoodsInfo#goods.reiki_level > 0 ->           
                    Sql = io_lib:format(<<"UPDATE add_reiki set gid = ~p where gid = ~p">>, [NewGoodsInfo#goods.id, GoodsInfo#goods.id]),
                    db:execute(Sql);
                true ->
                    skip
            end,
            %% 日志
            About1 = lists:concat([lists:concat([StoneInfo#goods.goods_id,":",GoodsNum,","]) || {StoneInfo, GoodsNum} <- StoneList++StuffList]),
            log:log_equip_advanced(PlayerStatus#player_status.id, RuleInfo, GoodsInfo, NewGoodsInfo, About1),
            About2 = lists:concat(["equip_advanced",About1]),
            log:log_consume(equip_advanced, coin, PlayerStatus, PlayerStatus2, NewGoodsInfo#goods.goods_id, 1, About2),
            Dict = lib_goods_dict:handle_dict(NewGoodsStatus1#goods_status.dict),
            NewGoodsStatus2 = NewGoodsStatus1#goods_status{dict = Dict},
            if
                GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                    EquipSuit = lib_goods_util:change_equip_suit(NewGoodsStatus2#goods_status.equip_suit, GoodsInfo#goods.suit_id, NewGoodsInfo#goods.suit_id),
                    SuitId = lib_goods_util:get_full_suit(EquipSuit);
                true ->
                    EquipSuit = NewGoodsStatus2#goods_status.equip_suit,
                    SuitId = NewGoodsStatus2#goods_status.suit_id
            end,
            Stren7_num = lib_goods:add_stren7_num(NewGoodsInfo, NewGoodsStatus2#goods_status.stren7_num),
            NewGoodsStatus3 = NewGoodsStatus2#goods_status{stren7_num = Stren7_num, suit_id = SuitId, equip_suit = EquipSuit},
            {ok, PlayerStatus2, NewGoodsStatus3, NewGoodsInfo}
        end,
    lib_goods_util:transaction(F).

%% 计算装备升级损失
count_upgrade_loss(GoodsInfo, RuneInfo) ->
    %% 损失规则
    case GoodsInfo#goods.level < 40 of
        true ->
            NewStren = GoodsInfo#goods.stren,
            Prefix = GoodsInfo#goods.prefix,
            Wash = GoodsInfo#goods.min_star;
        false ->
            Stren = case RuneInfo#goods.id > 0 of       %% 强化
                        true -> 
                            GoodsInfo#goods.stren;
                        false ->    %% 无保护符
                            Rem = util:rand(1, 100),
                            StrenLoss = data_equip:get_upgrade_lose(1, Rem),
                            GoodsInfo#goods.stren - StrenLoss
                    end,
            NewStren = case Stren > 0 of        %% 最多掉到1
                           true ->
                               Stren;
                           false ->
                               case GoodsInfo#goods.stren >= 1 of
                                   true ->
                                       1;
                                   false ->
                                       0
                               end
                       end,
            Prefix1 = case RuneInfo#goods.id > 0 of         %%品质
                          true ->
                              GoodsInfo#goods.prefix;
                          false ->
                              Rem1 = util:rand(1, 100),
                              PrefixLoss = data_equip:get_upgrade_lose(2, Rem1),
                              GoodsInfo#goods.prefix - PrefixLoss
                      end,
            Prefix = case Prefix1 >= 0 of
                         true ->
                             Prefix1;
                         false ->
                             0
                     end,
            %% 洗炼损失
            Wash1 = case RuneInfo#goods.id > 0 of
                       true ->
                           GoodsInfo#goods.min_star;
                       false ->
                           Rem2 = util:rand(1, 100),
                           WashLoss = data_equip:get_upgrade_lose(2, Rem2),
                           GoodsInfo#goods.min_star - WashLoss
                    end,
            Wash = case Wash1 > 0 of
                       true ->
                           Wash1;
                       false ->
                           1
                   end
    end,
    [NewStren, Prefix, Wash].
    
%% 装备升级
%% NewStuff1List碎片, NewStuff2List石头, NewStuff3List铁
equip_upgrade(PlayerStatus, GoodsStatus, GoodsTypeInfo, GoodsInfo, RuneInfo, RuleInfo, NewStuff1List, NewStuff2List, NewStuff3List) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 删除材料
            GoodsList = NewStuff1List ++ NewStuff2List ++ NewStuff3List,
            {ok, NewStatus1} = lib_goods:delete_goods_list(GoodsStatus, GoodsList),
            %% 花费铜钱
            Cost = RuleInfo#ets_equip_upgrade.coin,
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
            %% 删除保护符
            %case RuneInfo#goods.id > 0 of
            %    true ->
            %        {ok, NewStatus2} = lib_goods:delete_goods_list(NewStatus1, [{RuneInfo,1}]);
            %    false ->
            %        NewStatus2 = NewStatus1
            %end,
            %% 删除原装备
            NewStatus3 = lib_goods:delete_goods(GoodsInfo, NewStatus1),
            %% 生成新装备,如果物品中有一个是绑定的，新物品就是绑定的
            Bind = get_bind([{GoodsInfo,GoodsInfo#goods.num},{RuneInfo,1}] ++ GoodsList),
            Trade = case Bind > 0 of 
                true -> 
                    1; 
                false -> 
                    0 
            end,
            %[NewStren, Prefix, Star] = count_upgrade_loss(GoodsInfo, RuneInfo),
            %%             io:format("NewStren=~p, Prefix=~p, Star=~p~n", [NewStren, Prefix, Star]),
            [Cell|NullCells] = NewStatus3#goods_status.null_cells,
            NewStatus4 = NewStatus3#goods_status{null_cells = NullCells},
            Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
            if
                GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP andalso PlayerStatus#player_status.lv >= Info#goods.level ->
                    Cell2 = GoodsInfo#goods.cell,
                    Loc = GoodsInfo#goods.location;
                true ->
                    Cell2 = Cell,
                    Loc = ?GOODS_LOC_BAG
            end,
            FirstPrefix = GoodsInfo#goods.prefix,
            Prefix      = GoodsInfo#goods.prefix,
            Stren       = GoodsInfo#goods.stren,
            Addition1    = GoodsInfo#goods.addition_1,
            Addition2    = GoodsInfo#goods.addition_2,
            Addition3    = GoodsInfo#goods.addition_3,
            GoodsInfo2 = Info#goods{
                player_id = PlayerStatus#player_status.id, 
                location = Loc, cell = Cell2, num = 1, 
                bind = Bind, trade = Trade, color = GoodsInfo#goods.color,
                first_prefix = FirstPrefix, prefix = Prefix, 
                stren = Stren, addition_1 = Addition1, addition_2 = Addition2, addition_3 = Addition3,
                subtype=GoodsInfo#goods.subtype, 
                equip_type=GoodsInfo#goods.equip_type, 
                type=GoodsInfo#goods.type, 
                hole1_goods=GoodsInfo#goods.hole1_goods, 
                hole2_goods=GoodsInfo#goods.hole2_goods, 
                hole3_goods=GoodsInfo#goods.hole3_goods,
                reiki_list=GoodsInfo#goods.reiki_list},

            [NewGoodsInfo, NewStatus] = add_goods(GoodsInfo2, NewStatus4),
            if
                GoodsInfo#goods.reiki_level > 0 andalso RuneInfo#goods.id > 0 ->
                    Sql = io_lib:format(<<"UPDATE add_reiki set gid = ~p where gid = ~p">>, [NewGoodsInfo#goods.id, GoodsInfo#goods.id]),
                    db:execute(Sql);
                true ->
                    skip
            end,
            Res = 1,
            About = lists:concat([lists:concat([StuffInfo#goods.goods_id,":",StuffNum,","]) || {StuffInfo, StuffNum} <- NewStuff1List++NewStuff2List++NewStuff3List]),
            %% 日志
            log:log_consume(equip_upgrade, coin, PlayerStatus, NewPlayerStatus, ""),
           % RuneNum = case RuneInfo#goods.id > 0 of 
           %     true -> 1; 
           %     false -> 0 
           % end,
            log:equip_upgrade(RuleInfo, PlayerStatus#player_status.id, GoodsInfo#goods.id, NewGoodsInfo#goods.id, RuneInfo#goods.goods_id, 0, Cost, Res, About),
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus5 = NewStatus#goods_status{dict = Dict},
            if
                GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                    EquipSuit = lib_goods_util:change_equip_suit(NewStatus5#goods_status.equip_suit, GoodsInfo#goods.suit_id, NewGoodsInfo#goods.suit_id),
                    SuitId = lib_goods_util:get_full_suit(EquipSuit);
                true ->
                    EquipSuit = NewStatus5#goods_status.equip_suit,
                    SuitId = NewStatus5#goods_status.suit_id
            end,
            Stren7_num = lib_goods:add_stren7_num(NewGoodsInfo, NewStatus5#goods_status.stren7_num),
            NewStatus6 = NewStatus5#goods_status{stren7_num = Stren7_num, suit_id = SuitId, equip_suit = EquipSuit},
            {ok, NewPlayerStatus, NewStatus6, NewGoodsInfo}
    end,
    lib_goods_util:transaction(F).

%% 装备洗炼     ------------------- wash begin -------------
attribute_wash(PlayerStatus, GoodsStatus, GoodsInfo, _Time, Grade, StoneInfoList, LockList, WashRule, TypeRule, StarRule, Cost) ->
    attribute_wash_single(PlayerStatus, GoodsStatus, GoodsInfo, StoneInfoList, LockList, Grade, WashRule, TypeRule, StarRule, Cost).
    % case Time > 1 of
    %     true ->     %%批量
    %         attribute_wash_large(PlayerStatus, GoodsStatus, GoodsInfo, Time, StoneInfoList, LockList, StoneList, RuleList, TypeRule, StrenRule, Cost);
    %     false ->    %% 单次
    %         attribute_wash_single(PlayerStatus, GoodsStatus, GoodsInfo, StoneInfoList, LockList, StoneList, RuleList, TypeRule, StrenRule, Cost)
    % end.
       
%% 单次洗炼
attribute_wash_single(PlayerStatus, GoodsStatus, GoodsInfo, StoneInfoList, LockList, Grade, WashRule, TypeRule, StarRule, Cost) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 花费铜钱
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
            %% 删除材料
            GoodsList = StoneInfoList,
            {ok, NewStatus1} = lib_goods:delete_goods_list(GoodsStatus, GoodsList),
            Len = length(LockList),
            case Len > 0 of
                true ->     %%有锁住
                    NewGoodsInfo = wash_addition_lock(GoodsInfo, WashRule, TypeRule, StarRule, LockList, Grade, NewPlayerStatus);
                false ->    %%无锁
                    NewGoodsInfo = wash_addition_no_lock(GoodsInfo, WashRule, TypeRule, StarRule, Grade, NewPlayerStatus)
            end,
            Bind = get_bind([{GoodsInfo,GoodsInfo#goods.num}] ++ StoneInfoList),
            Trade = case Bind > 0 of 
                        true -> 
                            1; 
                        false -> 
                            0 
                    end,
            [NewGoodsInfo1, NewStatus] = change_goods_addition(NewGoodsInfo, Bind, Trade, Grade, NewStatus1),
            %% 写log
            About1 = lists:concat([lists:concat([Info#goods.goods_id,":",Num,","]) || {Info, Num} <- GoodsList]),
            case Grade of 
                1 ->
                    Addition = NewGoodsInfo1#goods.addition_1,
                    log:log_equip_wash(PlayerStatus#player_status.id, About1, GoodsInfo#goods.goods_id, NewGoodsInfo1#goods.addition_1, GoodsInfo#goods.id);
                2 ->
                    Addition = NewGoodsInfo1#goods.addition_2,
                    log:log_equip_wash(PlayerStatus#player_status.id, About1, GoodsInfo#goods.goods_id, NewGoodsInfo1#goods.addition_2, GoodsInfo#goods.id);
                _ ->
                    Addition = NewGoodsInfo1#goods.addition_3,
                    log:log_equip_wash(PlayerStatus#player_status.id, About1, GoodsInfo#goods.goods_id, NewGoodsInfo1#goods.addition_3, GoodsInfo#goods.id)
            end,
            About2 = lists:concat(["attribute_wash",About1]),
            log:log_consume(attribute_wash, coin, PlayerStatus, NewPlayerStatus, NewGoodsInfo1#goods.goods_id, 1, About2),
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
%%             io:format("AttributeList=~p~n", [NewGoodsInfo1#goods.addition]),
            {ok, NewPlayerStatus, NewGoodsInfo1, Addition, NewStatus2}
        end,
    lib_goods_util:transaction(F).

%% 批量洗炼
% attribute_wash_large(PlayerStatus, GoodsStatus, GoodsInfo, Time, StoneInfoList, LockList, StoneList, RuleList, TypeRule, StrenRule, Cost) ->
%     F = fun() ->
%             ok = lib_goods_dict:start_dict(),
%             %% 花费铜钱
%             NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
%             %% 删除材料
%             GoodsList = StoneInfoList ++ StoneList,
%             {ok, NewStatus1} = lib_goods:delete_goods_list(GoodsStatus, GoodsList),
%             Len = length(LockList),
%             case Len > 0 of
%                 true ->     %%有锁住
%                     {NewGoodsInfo, AttributeList} = wash_addition_lock_large(GoodsInfo, RuleList, TypeRule, StrenRule, LockList, Time, NewPlayerStatus);
%                 false ->    %%无锁
%                     {NewGoodsInfo, AttributeList} = wash_addition_no_lock_large(GoodsInfo, RuleList, TypeRule, StrenRule, Time, NewPlayerStatus)
%             end,
%             Bind = get_bind([{GoodsInfo,GoodsInfo#goods.num}] ++ StoneInfoList ++ StoneList),
%             Trade = case Bind > 0 of 
%                         true -> 
%                             1; 
%                         false -> 
%                             0 
%                     end,
%             %% 属性不写数据库
%             [NewGoodsInfo1, NewStatus] = change_goods_info(NewGoodsInfo, Bind, Trade, NewStatus1),
%             %% 写log
%             About1 = lists:concat([lists:concat([Info#goods.goods_id,":",Num,","]) || {Info, Num} <- GoodsList]),
%             log:log_equip_wash(PlayerStatus#player_status.id, About1, GoodsInfo#goods.goods_id, NewGoodsInfo1#goods.addition, GoodsInfo#goods.id),
%             About2 = lists:concat(["attribute_wash",About1]),
%             log:log_consume(attribute_wash, coin, PlayerStatus, NewPlayerStatus, NewGoodsInfo1#goods.goods_id, 1, About2),
%             Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
%             NewStatus2 = NewStatus#goods_status{dict = Dict},
% %%             io:format("large AttributeList=~p~n", [NewGoodsInfo1#goods.addition]),
%             {ok, NewPlayerStatus, NewGoodsInfo1, AttributeList, NewStatus2}
%         end,
%     lib_goods_util:transaction(F).

%% 没有锁定洗炼属性
wash_addition_no_lock(GoodsInfo, WashRule, TypeRule, StarRule, Grade, PS) ->
    %% 最大条数
    MaxNum = WashRule#ets_wash_rule.num,
    Num = util:rand(2, MaxNum),
    AttributeList = get_wash_list_nolock([], StarRule, TypeRule, Num, Grade, GoodsInfo, PS),
    case Grade of 
        1 ->
            NewGoodsInfo = GoodsInfo#goods{addition_1 = AttributeList};
        2 ->
            NewGoodsInfo = GoodsInfo#goods{addition_2 = AttributeList};
        _ ->
            NewGoodsInfo = GoodsInfo#goods{addition_3 = AttributeList}
    end,
    NewGoodsInfo.

% get_old_attribute(GoodsId) ->
%     Sql = io_lib:format(<<"select `addition` from `goods_low` where `gid` = ~p">>, [GoodsId]),
%     [[L]] = db:get_all(Sql),
%     util:bitstring_to_term(L).

% %% 没有锁批量洗炼属性
% wash_addition_no_lock_large(GoodsInfo, RuleList, TypeRule, StrenRule, Times, PS) ->
%     %%批量属性
%     {All, AttributeList} = get_wash_addition_nolock_large([], GoodsInfo, RuleList, TypeRule, StrenRule, Times, PS),
%     %OldAttr = get_old_attribute(GoodsInfo#goods.id),
%     %OldAttr1 = [0] ++ OldAttr,
%     %OldAttr2 = list_to_tuple(OldAttr1),
%     %io:format("All = ~p~n", [All]),
%     NewGoodsInfo = GoodsInfo#goods{addition = All},
%     EquipLevel = data_goods:get_level(GoodsInfo#goods.level),
%     UpStarRule = data_wash:get_wash_star(EquipLevel, GoodsInfo#goods.min_star),
%     %% 升星判断
%     case is_record(UpStarRule, ets_wash_star) of
%         true ->
%             case UpStarRule#ets_wash_star.is_upstar =/= 0 of
%                 true -> %%可升下限
%                     %%升星次数
%                     Time = UpStarRule#ets_wash_star.num,    
%                     if
%                         GoodsInfo#goods.wash_time + Times >= Time ->
%                             MinStar = case (NewGoodsInfo#goods.min_star + 1) =< StrenRule#ets_wash_strength.max_star of
%                                 true ->
%                                     NewGoodsInfo#goods.min_star + 1;
%                                 false ->
%                                     StrenRule#ets_wash_strength.max_star
%                             end,
%                             NewGoodsInfo1 = NewGoodsInfo#goods{min_star = MinStar, wash_time = 0};
%                         true ->
%                             NewGoodsInfo1 = NewGoodsInfo#goods{wash_time = NewGoodsInfo#goods.wash_time + Times}
%                     end;
%                 false ->
%                     NewGoodsInfo1 = NewGoodsInfo#goods{wash_time = NewGoodsInfo#goods.wash_time + Times}
%             end;
%         false ->
%             NewGoodsInfo1 = NewGoodsInfo#goods{wash_time = NewGoodsInfo#goods.wash_time + Times}
%     end,
%     {NewGoodsInfo1, AttributeList}.

%% 获得没有锁批量洗炼属性
% get_wash_addition_nolock_large(L, GoodsInfo, _RuleList, _TypeRule, _StrenRule, 0, _PS) ->
%     OldAttr = get_old_attribute(GoodsInfo#goods.id),
%     case OldAttr =:= undefined of
%         true ->
%             OldAttr1 = [0];
%         false ->
%             OldAttr1 = [0] ++ OldAttr
%     end,
%     OldAttr2 = list_to_tuple(OldAttr1),
%     {[OldAttr2|L], L};
% get_wash_addition_nolock_large(L, GoodsInfo, RuleList, TypeRule, StrenRule, Times, PS) ->
%     %% 最大条数
%     MaxNum = RuleList#ets_wash_rule.num,
%     Num = util:rand(2, MaxNum),
%     AttributeList1 = get_wash_list_nolock([], StrenRule, TypeRule, Num, GoodsInfo, PS),
%     %%构造属性表[{times,{属性1}, {属性2}}]
%     AttributeList = [Times] ++ AttributeList1,
%     AttributeTuple = list_to_tuple(AttributeList),
%     get_wash_addition_nolock_large([AttributeTuple|L], GoodsInfo, RuleList, TypeRule, StrenRule, Times-1, PS).
    
%% 有锁定洗炼属性
wash_addition_lock(GoodsInfo, WashRule, TypeRule, StarRule, LockList, Grade, PS) ->
    %% 最大条数
    MaxNum = WashRule#ets_wash_rule.num,
    LockLen = length(LockList),
    N = LockLen + 1,
    case N >= MaxNum of
        true ->
            LimNum = MaxNum;
        false ->
            LimNum = N
    end,
    Num = util:rand(LimNum, MaxNum),
    case LockLen >= Num of 
        true -> % 全部锁住
            NewGoodsInfo = GoodsInfo;
        false ->
            NewNum = Num - LockLen,
            List = get_wash_list_nolock([], StarRule, TypeRule, NewNum, Grade, GoodsInfo, PS),
            case Grade of 
                1 ->
                    NewGoodsInfo = GoodsInfo#goods{addition_1 = LockList++List};
                2 ->
                    NewGoodsInfo = GoodsInfo#goods{addition_2 = LockList++List};
                _ ->
                    NewGoodsInfo = GoodsInfo#goods{addition_3 = LockList++List}
            end
    end,
    NewGoodsInfo.

%%有锁定批量洗炼
% wash_addition_lock_large(GoodsInfo, RuleList, TypeRule, StrenRule, LockList, Times, PS) ->
%     %%批量属性
%     {All,AttributeList} = get_wash_addition_lock_large([], GoodsInfo, RuleList, TypeRule, StrenRule, LockList, Times, PS),
%     %io:format("lock All = ~p~n", [All]),
%     %OldAttr = get_old_attribute(GoodsInfo#goods.id),
%     %OldAttr1 = [0] ++ OldAttr,
%     NewGoodsInfo1 = GoodsInfo#goods{addition = All},
%     EquipLevel = data_goods:get_level(GoodsInfo#goods.level),
%     UpStarRule = data_wash:get_wash_star(EquipLevel, GoodsInfo#goods.min_star),
%     WashTime = GoodsInfo#goods.wash_time + Times,
%     case UpStarRule#ets_wash_star.is_upstar =/= 0 of
%                 true ->
%                     %%升星次数
%                     Time = UpStarRule#ets_wash_star.num,
%                     if  %% 下限星升级
%                         WashTime >= Time ->
%                             MinStar = case (GoodsInfo#goods.min_star + 1) =< StrenRule#ets_wash_strength.max_star of
%                                 true ->
%                                     GoodsInfo#goods.min_star + 1;
%                                 false ->
%                                     StrenRule#ets_wash_strength.max_star
%                             end,
%                             NewGoodsInfo = NewGoodsInfo1#goods{min_star = MinStar, wash_time = 0};
%                         true ->
%                             NewGoodsInfo = NewGoodsInfo1#goods{wash_time = WashTime}
%                     end;
%                 false ->
%                     NewGoodsInfo = NewGoodsInfo1#goods{wash_time = WashTime}
%     end,
%     {NewGoodsInfo, AttributeList}.

%% 获得有锁时的批量属性
% get_wash_addition_lock_large(L, GoodsInfo, _RuleList, _TypeRule, _StrenRule, _LockList, 0, _PS) ->
%     OldAttr = get_old_attribute(GoodsInfo#goods.id),
%     OldAttr1 = [0] ++ OldAttr,
%     OldAttr2 = list_to_tuple(OldAttr1),
%     {[OldAttr2|L], L};
% get_wash_addition_lock_large(L, GoodsInfo, RuleList, TypeRule, StrenRule, LockList, Times, PS) ->
%     %% 最大条数
%     MaxNum = RuleList#ets_wash_rule.num,
%     LockLen = length(LockList),
%     N = LockLen + 1,
%     case N >= MaxNum of
%         true ->
%             LimNum = MaxNum;
%         false ->
%             LimNum = N
%     end,
%     Num = util:rand(LimNum, MaxNum),
%     case LockLen >= Num of
%         true ->     %%没有新属性
%             AttributeList = [Times] ++ LockList,
%             AttributeTuple = list_to_tuple(AttributeList),
%             get_wash_addition_lock_large([AttributeTuple|L], GoodsInfo, RuleList, TypeRule, StrenRule, LockList, Times-1, PS);
%         false ->    %%有新属性
%             NewNum = Num - LockLen,
%             L1 = get_id(LockList, []),
%             %% 获得列表
%             List = get_wash_list_lock([], StrenRule, TypeRule, NewNum, GoodsInfo, L1, LockLen, PS),
%             AttributeList = [Times] ++ LockList ++ List,
%             AttributeTuple = list_to_tuple(AttributeList),
%             get_wash_addition_lock_large([AttributeTuple|L], GoodsInfo, RuleList, TypeRule, StrenRule, LockList, Times-1, PS)
%     end.

%% 洗炼 列表
get_wash_list_nolock(L, _StrenRule, _TypeRule, 0, _Grade, _GoodsInfo, _PS) ->
    L;
get_wash_list_nolock(L, StarRule, TypeRule, Num, Grade, GoodsInfo, PS) ->
    %% 类型
    %Rem = util:rand(1, 100),
    Type = util:rand_with_weight(TypeRule#ets_wash_attribute_type.type_list),
    %% 星数
    Star = util:rand_with_weight(StarRule#ets_wash_star.star_list),
    %% 颜色和值的大小
    ColorRule = data_wash:get_wash_color(Grade, Star),
    ValueRule = data_wash:get_wash_value(Grade, Type, Star),
    RangRule = data_wash:get_wash_value_rang(Grade, Type),
    case is_record(ValueRule, ets_wash_value) =:= false orelse is_record(ColorRule, ets_wash_color) =:= false orelse is_record(RangRule, ets_wash_value_rang) =:= false of 
        true -> % 没有配置
            Color = 1,
            Value = 1,
            MinValue = 1,
            MaxValue = 2,
            util:errlog("data_wash not record Star:~p, Type:~p, Grade:~p~n", [Star, Type, Grade]);
        false ->
            Color = ColorRule#ets_wash_color.color,
            Value = ValueRule#ets_wash_value.value,
            {MinValue, MaxValue} = RangRule#ets_wash_value_rang.rang     
    end,
    get_wash_list_nolock([{Type, Star, Value, Color, MinValue, MaxValue}|L], StarRule, TypeRule, Num-1, Grade, GoodsInfo, PS).


% get_wash_list_lock(L, _StrenRule, _TypeRule, 0, _GoodsInfo, _IdList, _LockLen, _PS) ->
%     L;
% get_wash_list_lock(L, StrenRule, TypeRule, Num, GoodsInfo, IdList, LockLen, PS) ->
%     %% 类型
%     Type = get_lock_type(TypeRule#ets_wash_attribute_type.type_list, IdList, GoodsInfo#goods.wash_time),
%     %% 最小星数下一级
%     MinStar = case GoodsInfo#goods.min_star > 0 of
%                   true ->
%                       GoodsInfo#goods.min_star - 1;
%                   false ->
%                       0
%               end,
%     MinRatio = get_minstar_ratio(StrenRule#ets_wash_strength.star_list, MinStar),
%     StarRatio = util:rand(MinRatio+1, 10000),
%     %% 星数
%     Star = get_type(StrenRule#ets_wash_strength.star_list, StarRatio),
%     %% 颜色
%     Level = data_goods:get_level(GoodsInfo#goods.level),
%     Color = get_lock_color(Level, LockLen, Star, GoodsInfo#goods.wash_time),
%     %% 传闻
%     if
%         Color =:= 4 ->
%             lib_chat:send_TV({all},0,3, ["equipWash", 
%                                 Type,
% 								PS#player_status.id, 
% 								PS#player_status.realm, 
% 								PS#player_status.nickname, 
% 								PS#player_status.sex, 
% 								PS#player_status.career, 
% 								PS#player_status.image]);
%         true ->
%             skip
%     end,
%     %% 属性值
%     MinRule = data_wash:get_wash_type_value(Type, Star),
%     case MinRule =/= [] of
%         true ->
%             Value = util:rand(MinRule#ets_wash_type_value.min, MinRule#ets_wash_type_value.max);
%         false ->
%             Value = 0
%     end,
%     %% 最小值
%     MinStarRule = data_wash:get_wash_type_value(Type, GoodsInfo#goods.min_star),
%     case MinStarRule =/= [] of
%         true ->
%             Min = MinStarRule#ets_wash_type_value.min;
%         false ->
%             Min = 0
%     end,
%     %% 最大值
%     MaxStarRule = data_wash:get_wash_type_value(Type, StrenRule#ets_wash_strength.max_star),
%     case MaxStarRule =/= [] of
%         true ->
%             Max = MaxStarRule#ets_wash_type_value.max;
%         false ->
%             Max = 0
%     end,
%     get_wash_list_lock([{Type, Star, Value, Color, Min, Max}|L], StrenRule, TypeRule, Num-1, GoodsInfo, IdList, LockLen, PS).
               
%% 取所有type id
get_id([], L) ->
    L;
get_id([{T, _S, _V, _C, _M1, _M2}|H], L) ->
    get_id(H, [T] ++ L).

%% 同类型条数
gets_same_num([], _T, N) ->
    N;
gets_same_num([Type|L], T, N) ->
    case Type =:= T of
        true ->
            Num = N + 1,
            gets_same_num(L, T, Num);
        false ->
            gets_same_num(L, T, N)
    end.

%% 获取有锁定时的类型表
% get_lock_type(List, IdList, RefreshTime) ->
%     Rem = util:rand(1, 100),
%     Type = get_type(List, Rem),
%     Type1 = case lists:member(Type, IdList) of  %%锁定里面有了
%                 true ->
%                     Num = gets_same_num(IdList, Type, 0),
%                     LockNumRule = data_wash:get_wash_lock_num(Num + 1), 
%                     %% 出现同一类型次数限制
%                     case RefreshTime >= LockNumRule#ets_wash_lock_num.min_refresh of
%                         true ->
%                             Type;
%                         false ->
%                             get_lock_type(List, IdList, RefreshTime)
%                     end;
%                 false ->
%                     Type
%             end,
%     Type1.

%% 锁定颜色
% get_lock_color(Level, LockLen, Star, RefreshTime) ->
%     ColorRule = data_wash:get_wash_color(Level, Star),
%     Color = ColorRule#ets_wash_color.color,
%     LockColorRule = data_wash:get_wash_lock_color(LockLen),
%     C = case Color =:= LockColorRule#ets_wash_lock_color.color of
%             true ->
%                 case RefreshTime >= LockColorRule#ets_wash_lock_color.min_refresh of
%                     true ->
%                         Color;
%                     false ->
%                         ColorRule2 = data_wash:get_wash_color(Level, Star -1),
%                         ColorRule2#ets_wash_color.color
%                 end;
%             false ->
%                 Color
%         end,
%     C.

%% 获得最小星数概率
get_minstar_ratio([], _MinStar) ->
    1;
get_minstar_ratio([{Star, Ratio}|T], MinStar) ->
    case Star =:= MinStar of
        true ->
            Ratio;
        false ->
            get_minstar_ratio(T, MinStar)
    end.

get_type([], _Rem) ->
    0;
get_type([{Type, Ratio}|T], Rem) ->
    case Ratio >= Rem of
        true ->
            Type;
        false ->
            get_type(T, Rem)
    end.

%% 选择洗炼属性
attribute_sel(GoodsStatus, GoodsInfo, Grade, AttrList) ->
    F = fun()->
            ok = lib_goods_dict:start_dict(),
            [NewGoodsInfo, NewStatus] = change_goods_addition(GoodsInfo, AttrList, Grade, GoodsStatus),
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
            {ok, NewGoodsInfo, NewStatus2}
        end,
    lib_goods_util:transaction(F).
             
%% 隐藏时装
hide_fashion(PlayerStatus, GoodsInfo, Show) ->
    F = fun() ->
        G = PlayerStatus#player_status.goods,
        [Weapon, _] = G#status_goods.fashion_weapon,
        [Armor, _] = G#status_goods.fashion_armor,
        [Accessory, _] = G#status_goods.fashion_accessory,
        [Head, _] = G#status_goods.fashion_head,
        [Tail, _] = G#status_goods.fashion_tail,
        [Ring, _] = G#status_goods.fashion_ring,
        Flag1 = check_fashion_dict(GoodsInfo#goods.goods_id, PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 1),
        Flag2 = check_fashion_dict(GoodsInfo#goods.goods_id, PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 2),
        Flag3 = check_fashion_dict(GoodsInfo#goods.goods_id, PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 3),
        Flag4 = check_fashion_dict(GoodsInfo#goods.goods_id, PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 4),
        Flag5 = check_fashion_dict(GoodsInfo#goods.goods_id, PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 5),
        Flag6 = check_fashion_dict(GoodsInfo#goods.goods_id, PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 6),
        %io:format("hide = ~p~n", [{Accessory, Flag1, Flag2, Flag3, GoodsInfo#goods.goods_id, Show}]),
        if
            GoodsInfo#goods.goods_id =:= Weapon orelse Flag2 =:= true ->
                lib_goods_util:change_fashion_state(Show,
                    G#status_goods.hide_fashion_armor,
                    G#status_goods.hide_fashion_accessory,
                    G#status_goods.hide_head, G#status_goods.hide_tail,
                    G#status_goods.hide_ring, PlayerStatus#player_status.id),
                NewPlayerStatus = PlayerStatus#player_status{goods = G#status_goods{hide_fashion_weapon = Show}};
            GoodsInfo#goods.goods_id =:= Armor orelse Flag1 =:= true ->
                lib_goods_util:change_fashion_state(G#status_goods.hide_fashion_weapon, Show, 
                    G#status_goods.hide_fashion_accessory, 
                    G#status_goods.hide_head, 
                    G#status_goods.hide_tail, 
                    G#status_goods.hide_ring, PlayerStatus#player_status.id),
                NewPlayerStatus = PlayerStatus#player_status{goods = G#status_goods{hide_fashion_armor = Show}};
            GoodsInfo#goods.goods_id =:= Accessory orelse Flag3 =:= true ->
                lib_goods_util:change_fashion_state(G#status_goods.hide_fashion_weapon, 
                    G#status_goods.hide_fashion_armor, Show, 
                    G#status_goods.hide_head, 
                    G#status_goods.hide_tail, 
                    G#status_goods.hide_ring,
                    PlayerStatus#player_status.id),
                NewPlayerStatus = PlayerStatus#player_status{goods = G#status_goods{hide_fashion_accessory = Show}};
            GoodsInfo#goods.goods_id =:= Head orelse Flag4 =:= true ->
                lib_goods_util:change_fashion_state(G#status_goods.hide_fashion_weapon, 
                    G#status_goods.hide_fashion_armor, 
                    G#status_goods.hide_fashion_accessory, Show,
                    G#status_goods.hide_tail, 
                    G#status_goods.hide_ring,
                    PlayerStatus#player_status.id),
                NewPlayerStatus = PlayerStatus#player_status{goods = G#status_goods{hide_head = Show}};
            GoodsInfo#goods.goods_id =:= Tail orelse Flag5 =:= true ->
                lib_goods_util:change_fashion_state(G#status_goods.hide_fashion_weapon, 
                    G#status_goods.hide_fashion_armor, 
                    G#status_goods.hide_fashion_accessory,
                    G#status_goods.hide_head,
                    Show, 
                    G#status_goods.hide_ring,
                    PlayerStatus#player_status.id),
                NewPlayerStatus = PlayerStatus#player_status{goods = G#status_goods{hide_tail = Show}};
            GoodsInfo#goods.goods_id =:= Ring orelse Flag6 =:= true ->
                lib_goods_util:change_fashion_state(G#status_goods.hide_fashion_weapon, 
                    G#status_goods.hide_fashion_armor, 
                    G#status_goods.hide_fashion_accessory,
                    G#status_goods.hide_head,
                    G#status_goods.hide_tail, 
                    Show,
                    PlayerStatus#player_status.id),
                NewPlayerStatus = PlayerStatus#player_status{goods = G#status_goods{hide_ring = Show}};
            true ->
                NewPlayerStatus = PlayerStatus
        end,
        {ok, NewPlayerStatus}
    end,
    lib_goods_util:transaction(F).   

check_fashion_dict(GoodsTypeId, Dict, GoodsId, Pos) ->
    case dict:is_key(GoodsId, Dict) of
        true ->
            [Change] = dict:fetch(GoodsId, Dict),
            GoodsTypeId =:= Change#ets_change.old_id andalso Change#ets_change.pos =:= Pos;
        false ->
            false 
    end.

%% ------------ wash end ---------------------------------
%% ============================== 装备  end ========================================================

%% 宝石合成
compose(PlayerStatus, Status, StoneList, RuneList, GoodsComposeRule, Times, IsRune) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 根据宝石数和幸运符计算成功率
            Ratio = case IsRune > 0 of
                        true -> 
                            GoodsComposeRule#ets_goods_compose.ratio + 25;
                        false -> 
                            GoodsComposeRule#ets_goods_compose.ratio
                    end,
            %% 花费铜钱
            Cost = GoodsComposeRule#ets_goods_compose.coin * Times,
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
            %% 日志 compose:合成 
            About = lists:concat(["compose",GoodsComposeRule#ets_goods_compose.goods_id," x",GoodsComposeRule#ets_goods_compose.goods_num," => ",GoodsComposeRule#ets_goods_compose.new_id]),
            log:log_consume(stone_compose, coin, PlayerStatus, NewPlayerStatus, About),
            %% 扣掉宝石
            {ok, NewStatus1} = lib_goods:delete_goods_list(Status, StoneList),
            %% 扣掉幸运符
            {ok, NewStatus2} = lib_goods:delete_goods_list(NewStatus1, RuneList),
            [{RuneInfo, _RuneNum}| _] = RuneList,
            About1 = lists:concat([lists:concat([StoneInfo#goods.id,":",GoodsNum,","]) || {StoneInfo, GoodsNum} <- StoneList]),
            %% 更新物品状态
            Bind = get_bind(RuneList++StoneList),
            GoodsTypeInfo = data_goods_type:get(GoodsComposeRule#ets_goods_compose.new_id),
            [NewStatus3, SucNum, FailNum] = new_compose(RuneInfo, GoodsTypeInfo, Bind, NewStatus2, NewPlayerStatus, Ratio, GoodsComposeRule, About1, 0, 0, Times),
            if
                GoodsTypeInfo#ets_goods_type.color >= 2 andalso SucNum > 0 ->
                    %% 传闻
                    lib_chat:send_TV({all},0,3, ["hecheng", 
													1, 
													PlayerStatus#player_status.id, 
													PlayerStatus#player_status.realm, 
													PlayerStatus#player_status.nickname, 
													PlayerStatus#player_status.sex, 
													PlayerStatus#player_status.career, 
													PlayerStatus#player_status.image, 
													GoodsTypeInfo#ets_goods_type.goods_id]);
                    true -> skip
            end,
            Dict = lib_goods_dict:handle_dict(NewStatus3#goods_status.dict),
            NewStatus4 = NewStatus3#goods_status{dict = Dict},
            {ok, NewPlayerStatus, NewStatus4, SucNum, FailNum, Cost, GoodsTypeInfo#ets_goods_type.goods_id}
        end,
    lib_goods_util:transaction(F).


new_compose(_RuneInfo, _GoodsTypeInfo, _Bind, NewStatus, _PlayerStaut, _Ratio, _GoodsComposeRule, _About, SucNum, FailNum, 0) ->
    [NewStatus, SucNum, FailNum];
new_compose(RuneInfo, GoodsTypeInfo, Bind, GoodsStatus, PlayerStatus, Ratio, GoodsComposeRule, About, SucNum, FailNum, Times) ->
    Ram = util:rand(1, 100),
    if
        RuneInfo#goods.goods_id > 0 ->
            N = 1;
        true ->
            N = 0
    end,
    case Ratio >= Ram of
        %% 合成成功
        true when is_record(GoodsTypeInfo, ets_goods_type) ->
            (catch log:log_compose(PlayerStatus#player_status.id, PlayerStatus#player_status.lv, GoodsComposeRule, 
                     GoodsTypeInfo#ets_goods_type.subtype, RuneInfo#goods.goods_id, N, GoodsComposeRule#ets_goods_compose.coin, 1, About)),
            SucNum2 = SucNum + 1,
            FailNum2 = FailNum,
            {ok, NewStatus1} = compose_ok(GoodsStatus, GoodsTypeInfo, 1, Bind),
            Dict = lib_goods_dict:handle_dict(NewStatus1#goods_status.dict),
            NewStatus2 = NewStatus1#goods_status{dict = Dict};
        _ ->
            mod_achieve:trigger_hidden(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 1, 0, 1),
            (catch log:log_compose(PlayerStatus#player_status.id, PlayerStatus#player_status.lv, GoodsComposeRule, 
                     GoodsTypeInfo#ets_goods_type.subtype, RuneInfo#goods.goods_id, N, GoodsComposeRule#ets_goods_compose.coin, 0, About)),
            SucNum2 = SucNum,
            FailNum2 = FailNum + 1,
            NewStatus2 = GoodsStatus
    end,
    new_compose(RuneInfo, GoodsTypeInfo, Bind, NewStatus2, PlayerStatus, Ratio, GoodsComposeRule, About, SucNum2, FailNum2, Times - 1).

compose_ok(GoodsStatus, GoodsTypeInfo, GoodsNum, Bind) ->
    Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
    case Info#goods.type =:= ?GOODS_TYPE_EQUIP andalso Info#goods.subtype =:= 70 of
        true ->
            Note = <<>>; %%lib_couple:get_ring_owner(GoodsStatus#goods_status.player_id);
        false ->
            Note = <<>>
    end,
    case Bind > 0 of
        true -> 
            NewInfo = Info#goods{bind=Bind, trade=1, note = Note};
        false -> 
            NewInfo = Info#goods{note = Note}
    end,
    lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, NewInfo).

%% 宝石镶嵌
inlay(PlayerStatus, Status, GoodsInfo, Stone1Info, Stone2Info, Stone3Info, Rune1Info, Rune2Info, Rune3Info, GoodsInlayRule1, GoodsInlayRule2, GoodsInlayRule3) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 宝石1
            case Stone1Info =/= [] andalso Rune1Info =/= [] andalso GoodsInlayRule1 =/= [] of
                true ->
                    [NewPlayerStatus, NewStatus, NewGoodsInfo] = inlay_stone(PlayerStatus, Status, GoodsInfo, Stone1Info, Rune1Info, GoodsInlayRule1);
                false ->
                    [NewPlayerStatus, NewStatus, NewGoodsInfo] = [PlayerStatus, Status, GoodsInfo]
            end,
            %% 宝石2
            case Stone2Info =/= [] andalso Rune2Info =/= [] andalso GoodsInlayRule2 =/= [] of
                true ->
                    [NewPlayerStatus1, NewStatus1, NewGoodsInfo1] = inlay_stone(NewPlayerStatus, NewStatus, NewGoodsInfo, Stone2Info, Rune2Info, GoodsInlayRule2);
                false ->
                    [NewPlayerStatus1, NewStatus1, NewGoodsInfo1] = [NewPlayerStatus, NewStatus, NewGoodsInfo]
            end,
            %% 宝石3
            case Stone3Info =/= [] andalso Rune3Info =/= [] andalso GoodsInlayRule3 =/= [] of
                true ->
                    [NewPlayerStatus2, NewStatus2, NewGoodsInfo2] = inlay_stone(NewPlayerStatus1, NewStatus1, NewGoodsInfo1, Stone3Info, Rune3Info, GoodsInlayRule3);
                false ->
                    [NewPlayerStatus2, NewStatus2, NewGoodsInfo2] = [NewPlayerStatus1, NewStatus1, NewGoodsInfo1]
            end,
            Dict = lib_goods_dict:handle_dict(NewStatus2#goods_status.dict),
            NewStatus3 = NewStatus2#goods_status{dict = Dict},
            {ok, NewPlayerStatus2, NewStatus3, NewGoodsInfo2}
        end,
    lib_goods_util:transaction(F).

%% 镶嵌宝石
inlay_stone(PlayerStatus, Status, GoodsInfo, StoneInfo, RuneInfo, GoodsInlayRule) ->
    %% 花费铜钱
    Cost = GoodsInlayRule#ets_goods_inlay.coin,
    NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
    %% 日志   inlay:装备镶嵌 , stone:石头
    About = lists:concat(["inlay ",GoodsInfo#goods.id,", stone",StoneInfo#goods.goods_id]),
    log:log_consume(stone_inlay, coin, PlayerStatus, NewPlayerStatus, GoodsInfo#goods.goods_id, 1, About),
    %% 扣掉宝石
    [NewStatus1, _] = lib_goods:delete_one(StoneInfo, [Status, 1]),
    %% 扣掉幸运符
    [NewStatus2, _] = lib_goods:delete_one(RuneInfo, [NewStatus1, 1]),
    About1 = get_about([{RuneInfo, 1}]),
    %% 绑定状态
    Bind = get_bind([{StoneInfo,0}]++[{RuneInfo, 1}]),
    case Bind > 0 of
    true -> 
        [NewGoodsInfo, NewStatus3] = inlay_ok(GoodsInfo, StoneInfo, Bind, 1, NewStatus2);
    false -> 
        [NewGoodsInfo, NewStatus3] = inlay_ok(GoodsInfo, StoneInfo, GoodsInfo#goods.bind, GoodsInfo#goods.trade, NewStatus2)
    end,
	%% 触发名人堂
	trigger_fame(PlayerStatus#player_status.mergetime, PlayerStatus#player_status.id, StoneInfo#goods.goods_id),
	log:log_inlay(GoodsInfo, StoneInfo#goods.id, StoneInfo#goods.goods_id, Cost, 1, PlayerStatus#player_status.lv, About1),
	[NewPlayerStatus, NewStatus3, NewGoodsInfo].
    
inlay_ok(GoodsInfo, StoneInfo, Bind, Trade, GoodsStatus) ->
    case GoodsInfo#goods.hole1_goods > 0 of
        false ->
            change_goods_hole2(GoodsInfo, 1, StoneInfo#goods.goods_id, Bind, Trade, GoodsStatus);
        true when GoodsInfo#goods.hole2_goods =:= 0 ->
            change_goods_hole2(GoodsInfo, 2, StoneInfo#goods.goods_id, Bind, Trade, GoodsStatus);
        true when GoodsInfo#goods.hole3_goods =:= 0 ->
            change_goods_hole2(GoodsInfo, 3, StoneInfo#goods.goods_id, Bind, Trade, GoodsStatus)
    end.

%% 镶嵌名人堂
trigger_fame(MergeTime, PlayerId, TypeId) ->
    [_,_,_,_,_,Level] = integer_to_list(TypeId),
    L = case list_to_integer([Level]) of
        0 ->
            10;
        Level2 ->
            Level2
    end,
    mod_fame:trigger(MergeTime, PlayerId, 10, 0, L).

% 宝石拆除
backout(PlayerStatus, Status, GoodsInfo, Pos1, Pos2, Pos3, RuneInfo1, RuneInfo2, RuneInfo3) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 位置1
            case Pos1 > 0 andalso RuneInfo1 =/= [] of
                true ->
                    [NewStatus1, NewPlayerStatus1, NewGoodsInfo1] = handle_backout(PlayerStatus, Status, GoodsInfo, Pos1, RuneInfo1);
                false ->
                    [NewStatus1, NewPlayerStatus1, NewGoodsInfo1] = [Status, PlayerStatus, GoodsInfo]
            end,
            %% 位置2
            case Pos2 > 0 andalso RuneInfo2 =/= [] of
                true ->
                    [NewStatus2, NewPlayerStatus2, NewGoodsInfo2] = handle_backout(PlayerStatus, NewStatus1, NewGoodsInfo1, Pos2, RuneInfo2);
                false ->
                    [NewStatus2, NewPlayerStatus2, NewGoodsInfo2] = [NewStatus1, NewPlayerStatus1, NewGoodsInfo1]
            end,
            %% 位置3
            case Pos3 > 0 andalso RuneInfo3 =/= [] of
                true ->
                    [NewStatus3, NewPlayerStatus3, NewGoodsInfo3] = handle_backout(PlayerStatus, NewStatus2, NewGoodsInfo2, Pos3, RuneInfo3);
                false ->
                    [NewStatus3, NewPlayerStatus3, NewGoodsInfo3] = [NewStatus2, NewPlayerStatus2, NewGoodsInfo2]
            end,
            Dict = lib_goods_dict:handle_dict(NewStatus3#goods_status.dict),
            NewStatus4 = NewStatus3#goods_status{dict = Dict},
            {ok, NewPlayerStatus3, NewStatus4, NewGoodsInfo3}
        end,
    lib_goods_util:transaction(F).

%% 处理拆除
handle_backout(PlayerStatus, Status, GoodsInfo, Pos, RuneInfo) ->
    %% 花费铜钱
    Cost = data_goods:count_backout_cost(GoodsInfo),
    NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
    %% 扣掉幸运符
    [NewStatus1, _] = lib_goods:delete_one(RuneInfo, [Status, 1]),
    About1 = get_about([{RuneInfo, 1}]),
    StoneId = lib_goods_util:get_inlay_goods(GoodsInfo, Pos),
    %% 绑定状态
    Bind = get_bind([{GoodsInfo,0}]++[{RuneInfo, 0}]),
    [NewGoodsInfo, {ok, NewStatus2}] = backout_ok(NewStatus1, GoodsInfo, StoneId, Pos, Bind),
    (catch log:log_backout(GoodsInfo, StoneId, 0, Cost, 1, About1)),
    %% 日志   backout:装备拆除 , hole:孔位
    About = lists:concat(["backout ",GoodsInfo#goods.id,", hole ", Pos]),
    log:log_consume(stone_backout, coin, PlayerStatus, NewPlayerStatus, GoodsInfo#goods.goods_id, 1, About),
    [NewStatus2, NewPlayerStatus, NewGoodsInfo].

backout_ok(GoodsStatus, GoodsInfo, StoneId, StonePos, Bind) ->
    [NewGoodsInfo, NewStatus] = change_goods_hole2(GoodsInfo, StonePos, 0, GoodsInfo#goods.bind, GoodsInfo#goods.trade, GoodsStatus),
    GoodsTypeInfo = data_goods_type:get(StoneId),
    Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
    case Bind > 0 of
        true ->  
            NewInfo = Info#goods{bind = Bind, trade = 1};
        false -> 
            NewInfo = Info
    end,
    [NewGoodsInfo, lib_goods:add_goods_base(NewStatus, GoodsTypeInfo, 1, NewInfo)].

%% 炼炉合成
forge(PlayerStatus, GoodsStatus, ForgeInfo, GoodsTypeInfo, Num, Flag) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 花费铜钱
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, ForgeInfo#ets_forge.coin * Num, coin),
            %% 删除材料
            Raw_goods = case Num > 1 of
                            true -> 
                                [{Gid,Gnum*Num} || {Gid,Gnum} <- ForgeInfo#ets_forge.raw_goods];
                            false -> 
                                ForgeInfo#ets_forge.raw_goods
                        end,
            {GoodsStatus1, Bind, _} = lists:foldl(fun handle_raw_goods/2, {GoodsStatus, 0, Flag}, Raw_goods),
            %% 炼化东西
            Ram = util:rand(1, 100),
            case ForgeInfo#ets_forge.ratio >= Ram of
                true ->
                    Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
                    case ForgeInfo#ets_forge.bind > 0 orelse Bind > 0 of
                        true ->  
                            GoodsInfo = Info#goods{bind=2, trade=1};
                        false -> 
                            GoodsInfo = Info#goods{bind = 0}
                    end,
                    {ok, NewGoodsStatus} = lib_goods:add_goods_base(GoodsStatus1, GoodsTypeInfo, Num, GoodsInfo),
                    log:log_forge(PlayerStatus#player_status.id, ForgeInfo#ets_forge.id, ForgeInfo#ets_forge.goods_id, Num, 1),
                    Res = 1;
                false ->
                    NewGoodsStatus = GoodsStatus1,
                    log:log_forge(PlayerStatus#player_status.id, ForgeInfo#ets_forge.id, 0, 0, 0),
                    Res = 0
            end,
            %% 日志
            log:log_consume(forge, coin, PlayerStatus, NewPlayerStatus, ForgeInfo#ets_forge.goods_id, Num, ""),
            Dict = lib_goods_dict:handle_dict(NewGoodsStatus#goods_status.dict),
            NewGoodsStatus2 = NewGoodsStatus#goods_status{dict = Dict},
            {ok, Res, NewPlayerStatus, NewGoodsStatus2}
        end,
    lib_goods_util:transaction(F).

handle_raw_goods({GoodsTypeId, GoodsNum}, {GoodsStatus, Bind1, Flag}) ->
    GoodsList = case Flag of
                    1 -> 
                        lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, 0, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict);
                    2 -> 
                        lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, 2, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict);
                    _ -> 
                        lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict)
                end,
    [NewStatus, _, DelList] = lists:foldl(fun delete_one/2, [GoodsStatus, GoodsNum, []], GoodsList),
    Bind2 = get_bind(DelList),
    NewBind = case Bind2 > 0 of
                  true -> 
                      Bind2;
                  false -> 
                      Bind1
              end,
    {NewStatus, NewBind, Flag}.

%% ------------------- private ----------------------------------------- 
%% 替换洗炼属性
change_goods_addition(GoodsInfo, AttrList, Grade, GoodsStatus) when is_list(AttrList) ->
    NewGoodsInfo = lib_goods_util:change_goods_addition(GoodsInfo, Grade, AttrList),
    Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    [NewGoodsInfo, NewStatus].

%%改变属性，不改附加属性
change_goods_info(GoodsInfo, Bind, Trade, GoodsStatus) ->
    NewGoodsInfo = lib_goods_util:change_goods_info(GoodsInfo, Bind, Trade),
    Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    [NewGoodsInfo, NewStatus].

%% 洗炼属性
change_goods_addition(GoodsInfo, Bind, Trade, Grade, GoodsStatus) ->
    NewGoodsInfo = lib_goods_util:change_goods_addition(GoodsInfo, Bind, Trade, Grade),
    Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    [NewGoodsInfo, NewStatus].

%%物品品质
change_goods_quality(GoodsInfo, Prefix, Bind, Trade, GoodsStatus, PrefixType) ->
    NewGoodsInfo = lib_goods_util:change_goods_quality(GoodsInfo, Prefix, Bind, Trade, PrefixType),
    Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    [NewGoodsInfo, NewStatus].

%% 装备强化
change_goods_stren(GoodsInfo, Stren, Stren_ratio, Bind, Trade, GoodsStatus) ->
    NewGoodsInfo = lib_goods_util:change_goods_stren(GoodsInfo, Stren, Stren_ratio, Bind, Trade),
    Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
    if
        GoodsInfo#goods.subtype =:= 10 andalso GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
            [Wq, Yf, Zq, _S1, S2, Sz] = GoodsStatus#goods_status.equip_current,
            NewCurrent = [Wq, Yf, Zq, Stren, S2, Sz],
            NewStatus = GoodsStatus#goods_status{dict=Dict, equip_current=NewCurrent};
        true ->
            NewStatus = GoodsStatus#goods_status{dict = Dict}
    end,
    [NewGoodsInfo, NewStatus].

%%时效
%% change_goods_expire(GoodsInfo, ExpireTime, GoodsStatus) ->
%%     NewGoodsInfo = lib_goods_util:change_goods_expire(GoodsInfo, ExpireTime),
%%     Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
%%     NewStatus = GoodsStatus#goods_status{dict = Dict},
%%     [NewGoodsInfo, NewStatus].

change_goods_type(GoodsInfo, GoodsTypeId, GoodsStatus) ->
    NewGoodsInfo = lib_goods_util:change_goods_type(GoodsInfo, GoodsTypeId),
    Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    [NewGoodsInfo, NewStatus].

%% 改变孔数,打孔用
change_goods_hole(GoodsInfo, Hole, Bind, Trade, GoodsStatus) ->
    NewGoodsInfo = lib_goods_util:change_goods_hole(GoodsInfo, Hole, Bind, Trade),
    Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    [NewGoodsInfo, NewStatus].

change_goods_hole2(GoodsInfo, StoneNum, StoneId, Bind, Trade, GoodsStatus) ->
    case StoneNum of
        1 -> NewGoodsInfo = lib_goods_util:change_goods_hole2(GoodsInfo, StoneId, GoodsInfo#goods.hole2_goods, GoodsInfo#goods.hole3_goods, Bind, Trade);
        2 -> NewGoodsInfo = lib_goods_util:change_goods_hole2(GoodsInfo, GoodsInfo#goods.hole1_goods, StoneId, GoodsInfo#goods.hole3_goods, Bind, Trade);
        3 -> NewGoodsInfo = lib_goods_util:change_goods_hole2(GoodsInfo, GoodsInfo#goods.hole1_goods, GoodsInfo#goods.hole2_goods, StoneId, Bind, Trade)
    end,
    Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    [NewGoodsInfo, NewStatus].

get_about(GoodsList) ->
    F = fun({GoodsInfo,GoodsNum}) ->
            case GoodsInfo#goods.id > 0 of
                true -> lists:concat([GoodsInfo#goods.id,":",GoodsInfo#goods.goods_id,":",GoodsNum,","]);
                false -> []
            end
        end,
    lists:concat([F(I) || I <- GoodsList]).

get_bind(GoodsList) ->
    F = fun({GoodsInfo,_}, Bind) ->
            case GoodsInfo#goods.bind > 0 of
                true -> 2;
                false -> Bind
            end
        end,
    lists:foldl(F, 0, GoodsList).

%% 添加新物品信息
add_goods(GoodsInfo, GoodsStatus) ->
    GoodsId = lib_goods_util:add_goods(GoodsInfo),
    NewGoodsInfo = GoodsInfo#goods{id = GoodsId},
    Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    [NewGoodsInfo, NewStatus].

delete_one(GoodsInfo, [GoodsStatus, GoodsNum, DelList]) ->
    if GoodsNum > 0 andalso GoodsInfo#goods.id > 0 ->
            case GoodsInfo#goods.num > GoodsNum of
                %% 部分
                true ->
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    lib_goods:change_goods_num(GoodsInfo, NewNum, GoodsStatus),
                    [GoodsStatus, 0, [{GoodsInfo,GoodsNum}|DelList]];
                %% 全部
                false ->
                    NewNum = GoodsNum - GoodsInfo#goods.num,
                    NewStatus = lib_goods:delete_goods(GoodsInfo, GoodsStatus),
                    [NewStatus, NewNum, [{GoodsInfo,GoodsInfo#goods.num}|DelList]]
            end;
        true ->
            [GoodsStatus, GoodsNum, DelList]
    end.

            


