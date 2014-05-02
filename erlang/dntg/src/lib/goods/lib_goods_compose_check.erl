%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-5-14
%% Description: TODO:
%% --------------------------------------------------------
-module(lib_goods_compose_check).
-compile(export_all).
-include("def_goods.hrl").
-include("goods.hrl").
-include("server.hrl").
-include("common.hrl").
-include("mount.hrl").

%% 检查装备品质升级
check_quality_upgrade(PlayerStatus, GoodsId, StoneTypeId, PrefixType, StoneList, GoodsStatus) ->
     GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
     Sell = PlayerStatus#player_status.sell,
     if
         %% 物品不存在
         is_record(GoodsInfo, goods) =:= false ->
             {fail, 2};
         %% 物品不存在
        GoodsInfo#goods.num < 1 ->
            {fail, 2};
         %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品位置不正确
        %GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
        %    {fail, 4};
        %% 物品类型不正确 ,不是装备
        GoodsInfo#goods.type =/= 10 -> 
            {fail, 5};
        %% 数量不对
        StoneTypeId =< 0 ->
            {fail, 11};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 8};
        true ->
            NowPrefix = case PrefixType of
                1 -> GoodsInfo#goods.first_prefix;
                2 -> GoodsInfo#goods.prefix
            end,
            GoodsQualityRule = data_equip:get_quality(PrefixType, GoodsInfo#goods.equip_type, NowPrefix + 1),
            if  %% 品质升级规则不存在
                is_record(GoodsQualityRule, ets_goods_quality_upgrade) =:= false ->
                    {fail, 6};
                GoodsQualityRule#ets_goods_quality_upgrade.prefix =/= NowPrefix 
                    andalso GoodsQualityRule#ets_goods_quality_upgrade.prefix =/= (NowPrefix + 1) ->
                    {fail, 6};
                StoneTypeId =/= GoodsQualityRule#ets_goods_quality_upgrade.stone_id ->
                    {fail, 5};
                %% 装备等级不足
                GoodsInfo#goods.level < GoodsQualityRule#ets_goods_quality_upgrade.less_level -> 
                    {fail, 12};
                %% 玩家铜钱不足
                (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < GoodsQualityRule#ets_goods_quality_upgrade.coin ->
                    {fail, 7};
                 true ->
                     case lib_goods_check:list_handle(fun check_quality_stone/2, [PlayerStatus, 0, [], GoodsStatus], StoneList) of
                         {fail, Res} ->
                             {fail, Res};
                         {ok, [_, Num, NewStoneList, _]} ->
                             if %%数量不对
                                 Num =/= GoodsQualityRule#ets_goods_quality_upgrade.stone_num ->
                                     {fail, 11};
                                 true ->
                                    {ok, GoodsInfo, NewStoneList, GoodsQualityRule}
                             end
                     end
            end
    end.
check_quality_stone({StoneId, StoneNum}, [PlayerStatus, Num, L, GoodsStatus]) ->
     StoneInfo = lib_goods_util:get_goods(StoneId, GoodsStatus#goods_status.dict),
     if
         is_record(StoneInfo, goods) =:= false orelse StoneInfo#goods.num < 1 ->
             {fail, 2};
         %% 物品不属于你所有
        StoneInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
         %% 物品类型不正确
        % (StoneInfo#goods.type /= 60 andalso StoneInfo#goods.type /= 11) orelse
        % (StoneInfo#goods.subtype /= 16 andalso StoneInfo#goods.subtype /= 27) -> %宝石
        %     {fail, 5};
        StoneInfo#goods.num < StoneNum ->
            {fail, 11};
        true ->
            {ok, [PlayerStatus, Num+StoneNum, [{StoneInfo, StoneNum}|L], GoodsStatus]}
     end.
    
%% 检查装备合成
equip_compose_check(PlayerStatus, GoodsId1, GoodsId2, GoodsId3, GoodsStatus) ->
    GoodsInfo1 = lib_goods_util:get_goods(GoodsId1, GoodsStatus#goods_status.dict),
    GoodsInfo2 = lib_goods_util:get_goods(GoodsId2, GoodsStatus#goods_status.dict),
    GoodsInfo3 = lib_goods_util:get_goods(GoodsId3, GoodsStatus#goods_status.dict),
    Sell = PlayerStatus#player_status.sell,
    if  %% 物品不存在
        is_record(GoodsInfo1, goods) =:= false orelse is_record(GoodsInfo2, goods) =:= false orelse is_record(GoodsInfo3, goods) =:= false ->
            {fail, 2};
        %% 物品不存在
        GoodsInfo1#goods.num < 1 orelse GoodsInfo2#goods.num < 1 orelse GoodsInfo3#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo1#goods.player_id =/= PlayerStatus#player_status.id
                orelse GoodsInfo2#goods.player_id =/= PlayerStatus#player_status.id
                orelse GoodsInfo3#goods.player_id =/= PlayerStatus#player_status.id->
            {fail, 3};
        %% 物品位置不正确
        GoodsInfo1#goods.location =/= ?GOODS_LOC_BAG orelse GoodsInfo2#goods.location =/= ?GOODS_LOC_BAG
                orelse GoodsInfo3#goods.location =/= ?GOODS_LOC_BAG->
            {fail, 4};
        %% 物品类型不正确
        GoodsInfo1#goods.type =/= 10 orelse GoodsInfo2#goods.type =/= 10 orelse GoodsInfo3#goods.type =/= 10 ->
            {fail, 5};
        %% 物品类型不正确
        GoodsInfo1#goods.equip_type =/= 2 orelse GoodsInfo2#goods.equip_type =/= 2 orelse GoodsInfo3#goods.equip_type =/= 2 ->
            {fail, 5};
        %% 物品类型不正确
        GoodsInfo2#goods.suit_id =:= 0 orelse GoodsInfo2#goods.suit_id =/= GoodsInfo3#goods.suit_id ->
            {fail, 5};
        %% 物品颜色不正确
        GoodsInfo1#goods.color =/= 2 orelse GoodsInfo2#goods.color < 3 orelse GoodsInfo3#goods.color < 3 orelse GoodsInfo2#goods.color =/= GoodsInfo3#goods.color->
            {fail, 6};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 8};
        true ->
            Cost = data_goods:count_equip_compose_cost(),
            case (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Cost of
                %% 玩家铜钱不足
                true -> {fail, 7};
                false ->
                    case get_compose_info(GoodsInfo1#goods.goods_id, GoodsInfo2#goods.goods_id) of
                        [] -> {fail, 5};
                        GoodsTypeInfo -> {ok, GoodsTypeInfo, GoodsInfo1, GoodsInfo2, GoodsInfo3}
                    end
            end
    end.

%% 组成新的id和物品
get_compose_info(BludeId, PerpleId) ->
    [_,_,_,H,_,_] = integer_to_list(BludeId),
    [A, B, C, _, E, F] = integer_to_list(PerpleId),
    NewId = list_to_integer(lists:concat([[A],[B],[C],[H],[E],[F]])),
    data_goods_type:get(NewId).

%% 检查装备强化
check_strengthen(PlayerStatus, GoodsStatus, EquipId, StoneList, LuckyId) ->
    Sell = PlayerStatus#player_status.sell,
    GoodsInfo = lib_goods_util:get_goods(EquipId, GoodsStatus#goods_status.dict),
    %StoneInfo = lib_goods_util:get_goods(StoneId, GoodsStatus#goods_status.dict),

    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不存在
        GoodsInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品位置不正确
        %GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
        %    {fail, 4};
        %% 物品类型不正确
        GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP andalso GoodsInfo#goods.type =/= ?GOODS_TYPE_MOUNT andalso GoodsInfo#goods.type =/= ?GOODS_TYPE_RUNE ->
            {fail, 5};
        %% 物品类型不正确
        GoodsInfo#goods.type =:= ?GOODS_TYPE_MOUNT andalso GoodsInfo#goods.equip_type =/= ?GOODS_EQUIPTYPE_MOUNT ->
            {fail, 5};
        %% 强化已达上限
        GoodsInfo#goods.stren >= PlayerStatus#player_status.lv -> 
            {fail, 8};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 9};
        %% 格子不足
        GoodsInfo#goods.stren > 6 andalso length(GoodsStatus#goods_status.null_cells) =:= 0 ->
            {fail, 11};
        %% 格子不足
        GoodsInfo#goods.stren =:= 6 andalso GoodsInfo#goods.equip_type =:= ?GOODS_EQUIPTYPE_FASHION
            andalso GoodsInfo#goods.expire_time > 0 andalso length(GoodsStatus#goods_status.null_cells) < 1 ->
            {fail, 11};
        true ->
            case data_goods_type:get(GoodsInfo#goods.goods_id) of
                [] ->
                    {fail, 2};
                %% 不可强化
                GoodsTypeInfo when GoodsTypeInfo#ets_goods_type.is_stren == 0 ->
                    {fail, 12};
                _ ->
                    GoodsStrengthenRule = data_equip:get_strengthen(GoodsInfo#goods.equip_type, GoodsInfo#goods.stren + 1),
                    %LuckyValueRule = data_equip:get_luck_value(GoodsInfo#goods.stren + 1),
                    UpgradeRule    = data_equip:get_upgrade(GoodsInfo#goods.goods_id),
                    
                    if  %% 强化规则不存在
                        is_record(GoodsStrengthenRule, ets_goods_strengthen) =:= false orelse (GoodsStrengthenRule#ets_goods_strengthen.is_upgrade == 1 andalso is_record(UpgradeRule, ets_equip_upgrade) == false) ->
                            {fail, 6};
                        %% 玩家铜钱不足
                        (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < GoodsStrengthenRule#ets_goods_strengthen.coin ->
                            {fail, 7};
                        true ->
                            %% 检查强化石的信息是否正确
                            case lib_goods_check:list_handle(fun check_strengthen_stone/2, [PlayerStatus, 0, [], GoodsStatus], StoneList) of
                                {fail, Res} ->
                                    {fail, Res};
                                {ok, [_, Num, NewStoneList, _]} ->
                                    if %%数量不对
                                        Num =/= GoodsStrengthenRule#ets_goods_strengthen.stone_num ->
                                            {fail, 13};
                                        true ->
                                            %% 如果装备强化等级大于等于突破(升级)规则所需的最小强化数，则返回正确的#ets_goods_type{},
                                            %% 否则返回[]，表现继续强化，不突破
                                            UpGradeGoodsInfo = 
                                            case GoodsStrengthenRule#ets_goods_strengthen.is_upgrade == 1 andalso GoodsInfo#goods.stren >= UpgradeRule#ets_equip_upgrade.less_stren of
                                                true  -> data_goods_type:get(UpgradeRule#ets_equip_upgrade.new_id);
                                                false -> []
                                            end,
                                            if 
                                                %% 突破物品不存在
                                                GoodsStrengthenRule#ets_goods_strengthen.is_upgrade == 1 andalso GoodsInfo#goods.stren >= UpgradeRule#ets_equip_upgrade.less_stren andalso UpGradeGoodsInfo == [] -> 
                                                    {fail, 14};
                                                LuckyId > 0 ->
                                                    case check_strengthen_lucky(LuckyId, PlayerStatus#player_status.id, GoodsInfo#goods.stren, GoodsStatus) of
                                                        {fail, Res} ->
                                                            {fail, Res};
                                                        {ok, LuckyRule, LuckyInfo} ->
                                                            if
                                                                GoodsStrengthenRule#ets_goods_strengthen.lucky_id =/= [] ->
                                                                    IsLuckyId = case lists:member(LuckyInfo#goods.goods_id, GoodsStrengthenRule#ets_goods_strengthen.lucky_id) of
                                                                        true ->
                                                                            true;
                                                                        false ->
                                                                            false
                                                                    end,
                                                                    if
                                                                        IsLuckyId =:= false ->
                                                                            {fail, 5};
                                                                        LuckyInfo#goods.goods_id =:= 121036 andalso (GoodsInfo#goods.level > 40 orelse GoodsInfo#goods.subtype =/= 10 orelse GoodsInfo#goods.color =/= 3) ->
                                                                            {fail, 5};
                                                                        true ->
                                                                            {ok, GoodsInfo, NewStoneList, LuckyInfo, LuckyRule, GoodsStrengthenRule, UpGradeGoodsInfo}
                                                                    end;
                                                                true ->
                                                                    {ok, GoodsInfo, NewStoneList, #goods{}, [], GoodsStrengthenRule, UpGradeGoodsInfo}
                                                            end
                                                    end;
                                                true ->
                                                    {ok, GoodsInfo, NewStoneList, #goods{}, [], GoodsStrengthenRule, UpGradeGoodsInfo}
                                            end
                                    end
                            end
                    end
            end
    end.

%% 检查强化石列表
check_strengthen_stone({StoneId, StoneNum}, [PlayerStatus, Num, L, GoodsStatus]) ->
     StoneInfo = lib_goods_util:get_goods(StoneId, GoodsStatus#goods_status.dict),
     if
         %% 数量不足
         is_record(StoneInfo, goods) =:= false orelse StoneInfo#goods.num < 1 ->
             {fail, 2};
         %% 物品不属于你所有
        StoneInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
         %% 物品类型不正确
        StoneInfo#goods.type =/= 11 orelse StoneInfo#goods.subtype =/= 10 ->
            {fail, 5};
        StoneInfo#goods.num < StoneNum ->
            {fail, 11};
        %% 物品位置不正确
        StoneInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        true ->
            {ok, [PlayerStatus, Num+StoneNum, [{StoneInfo, StoneNum}|L], GoodsStatus]}
     end.

%% 坐骑强化
check_mount_stren(PlayerStatus, GoodsStatus, Mount_id, StoneId, LuckyId) ->
    Mon = PlayerStatus#player_status.mount,
    case lib_mount:get_mount_info(Mount_id, Mon#status_mount.mount_dict) of
        %% 坐骑不存在
        [] -> {fail, 12};
        [Mount] ->
            StoneInfo = lib_goods_util:get_goods(StoneId, GoodsStatus#goods_status.dict),
            Sell = PlayerStatus#player_status.sell,
            if  %% 坐骑不属于你所有
                Mount#ets_mount.role_id =/= PlayerStatus#player_status.id ->
                    {fail, 13};
                %% 坐骑出战状态不能强化
                %Mount#ets_mount.status =/= 0 ->
                %    {fail, 14};
                %% 物品不存在
                is_record(StoneInfo, goods) =:= false orelse StoneInfo#goods.num < 1 ->
                    {fail, 2};
                %% 物品不属于你所有
                StoneInfo#goods.player_id =/= PlayerStatus#player_status.id ->
                    {fail, 3};
                %% 物品位置不正确
                StoneInfo#goods.location =/= ?GOODS_LOC_BAG ->
                    {fail, 4};
                %% 物品类型不正确
                StoneInfo#goods.type =/= 11 orelse StoneInfo#goods.subtype =/= 10 ->
                    {fail, 5};
                %% 物品类型不正确
                %StoneInfo#goods.level =/= Mount#ets_mount.stren + 1 ->
                %    {fail, 5};
                %% 强化已达上限
                Mount#ets_mount.stren >= ?MAX_STREN ->
                    {fail, 8};
                %% 正在交易中
                Sell#status_sell.sell_status =/= 0 ->
                    {fail, 9};
                %% 格子不足
                Mount#ets_mount.stren > 6 andalso length(GoodsStatus#goods_status.null_cells) =:= 0 ->
                    {fail, 11};
                true ->
                    case data_goods_type:get(Mount#ets_mount.type_id) of
                        [] ->
                            {fail, 2};
                        _ ->
                            GoodsStrengthenRule = data_equip:get_strengthen(3, Mount#ets_mount.stren+1),
                            %LuckyValueRule = data_equip:get_luck_value(Mount#ets_mount.stren + 1),
                            if  %% 强化规则不存在
                                is_record(GoodsStrengthenRule, ets_goods_strengthen) =:= false ->
                                    {fail, 6};
                                %% 玩家铜钱不足
                                (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < GoodsStrengthenRule#ets_goods_strengthen.coin ->
                                    {fail, 7};
                                 StoneInfo#goods.goods_id =/= GoodsStrengthenRule#ets_goods_strengthen.stone_id ->
                                    {fail, 5};
                                true ->
                                    if LuckyId > 0 ->
                                        case check_strengthen_lucky(LuckyId, PlayerStatus#player_status.id, Mount#ets_mount.stren, GoodsStatus) of
                                            {fail, Res} ->
                                                {fail, Res};
                                            {ok, LuckyRule, LuckyInfo} ->
                                                if
                                                    GoodsStrengthenRule#ets_goods_strengthen.lucky_id =/= [] ->
                                                        IsLuckyId = case lists:member(LuckyInfo#goods.goods_id, GoodsStrengthenRule#ets_goods_strengthen.lucky_id) of
                                                                        true ->
                                                                            true;
                                                                        false ->
                                                                            false
                                                                    end,
                                                        if
                                                            IsLuckyId =:= false ->
                                                                {fail, 5};
                                                            true ->
                                                                {ok, Mount, StoneInfo, LuckyInfo, LuckyRule, GoodsStrengthenRule}
                                                        end;
                                                    true ->
                                                        {ok, Mount, StoneInfo, #goods{}, [], GoodsStrengthenRule}
                                                end
                                        end;
                                        true ->
                                            {ok, Mount, StoneInfo, #goods{}, [], GoodsStrengthenRule}
                                    end
                            end
                    end
            end
    end.
                                    
%% 检查强化幸运符
check_strengthen_lucky(Lucky_id, PlayerId, _Stren, GoodsStatus) ->
    LuckyInfo = lib_goods_util:get_goods(Lucky_id, GoodsStatus#goods_status.dict),
    if  %% 物品不存在
        is_record(LuckyInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        LuckyInfo#goods.player_id =/= PlayerId ->
            {fail, 3};
        %% 物品位置不正确
        LuckyInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        LuckyInfo#goods.type =/= 12 orelse LuckyInfo#goods.subtype =/= 10 ->
            {fail, 5};
        true ->
            %% 物品类型不正确
            LuckyRule = data_equip:get_lucky(LuckyInfo#goods.goods_id),
            if
                is_record(LuckyRule, ets_stren_lucky) =:= false ->
                    {fail, 6};
                % LuckyRule#ets_stren_lucky.level =/= Stren + 1 andalso LuckyRule#ets_stren_lucky.level =/= 0 ->
                %     {fail, 5};
                true ->
                    {ok, LuckyRule, LuckyInfo}
            end
    end.

%% 装备分解
check_goods_resolve(PlayerStatus, GreemList, BlueList, PurpleList, GoodsStatus) ->
    case length(GreemList) > 0 of       %%绿色装备
        true ->
            case lib_goods_check:list_handle(fun check_resolve_goods/2, [1, PlayerStatus, [], [], 0,GoodsStatus], GreemList) of
                {ok, [_, _, Glist, Grule, Cost1, _]} ->
                    Fail1 = false,
                    Res1 = 1,
                    C1 = Cost1,
                    List1 = Glist,
                    Rule1 = Grule;
                {fail, Res} ->
                    C1 = 0,
                    List1 = 0,
                    Rule1 = 0,
                    Fail1 = true,
                    Res1 = Res
            end;
        false ->
            Fail1 = false,
            Res1 = 1,
            List1 = GreemList,
            Rule1 = 0,
            C1 = 0
    end,
    case length(BlueList) > 0 of        %%蓝色装备
        true ->
            case lib_goods_check:list_handle(fun check_resolve_goods/2, [2, PlayerStatus, [], [], 0, GoodsStatus], BlueList) of
                {ok, [_, _, Blist, Brule, Cost2, _]} ->
                    Fail2 = false,
                    Res2 = 1,
                    C2 = Cost2,
                    List2 = Blist,
                    Rule2 = Brule;
                {fail, R1} ->
                    C2 = 0,
                    List2 = 0,
                    Rule2 = 0,
                    Fail2 = true,
                    Res2 = R1
            end;
        false ->
            Fail2 = false,
            Res2 = 1,
            List2 = BlueList,
            Rule2 = 0,
            C2 = 0
    end, 
    case length(PurpleList) > 0 of      %%紫色装备
        true ->
            case lib_goods_check:list_handle(fun check_resolve_goods/2, [3, PlayerStatus, [], [], 0, GoodsStatus], PurpleList) of
                {ok, [_, _, Plist, Prule, Cost3, _]} ->
                    Fail3 = false,
                    Res3 = 1,
                    C3 = Cost3,
                    List3 = Plist,
                    Rule3 = Prule;
                {fail, R2} ->
                    C3 = 0,
                    List3 = 0,
                    Rule3 = 0,
                    Fail3 = true,
                    Res3 = R2
            end;
        false ->
            Fail3 = false,
            Res3 = 1,
            List3 = PurpleList,
            Rule3 = 0,
            C3 = 0
    end,

    if
        Fail1 =:= true ->
            {fail, Res1};
        Fail2 =:= true ->
            {fail, Res2};
        Fail3 =:= true ->
            {fail, Res3};
        %% 格子不足
        length(GoodsStatus#goods_status.null_cells) =< 0 orelse GoodsStatus#goods_status.null_cells =:= [] ->
            {fail, 12};
        true ->
            case (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) >= (C1 + C2 +C3) of
                true ->
%%                     io:format("List1=~p~n, Rule1=~p~n, List2=~p~n, Rule2=~p~n, List3=~p~n, Rule3=~p~n", [List1, Rule1, List2, Rule2, List3, Rule3]),
                    {ok, List1, Rule1, List2, Rule2, List3, Rule3, (C1 + C2 +C3)};
                false ->
                    {fail, 7}
            end
    end.
check_resolve_goods({GoodsId, Num}, [Color, PlayerStatus, L, RList, Cost, GoodsStatus]) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    Sell = PlayerStatus#player_status.sell,
    if  %% 装备不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 装备不存在
        GoodsInfo#goods.num < 1 ->
            {fail, 2};
        %% 装备不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 装备位置不正确
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 装备类型不正确
        GoodsInfo#goods.type =/= 10 ->
            {fail, 5};
        GoodsInfo#goods.hole1_goods =/= 0 orelse GoodsInfo#goods.hole2_goods =/= 0 orelse GoodsInfo#goods.hole3_goods =/= 0 ->
            {fail, 13};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 8};
        true ->
            Stren = case GoodsInfo#goods.stren > 0 of
                        true ->
                            GoodsInfo#goods.stren;
                        false ->
                            1
                    end,
            ResolveRule = data_equip:get_resolve(Color, Stren),
            if  %% 规则不存在
                is_record(ResolveRule, ets_goods_resolve) =:= false ->
                    {fail, 6};
                %% 玩家铜钱不足
                (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < ResolveRule#ets_goods_resolve.coin ->
                    {fail, 7};
                true ->
                    case  data_goods_type:get(ResolveRule#ets_goods_resolve.stone_id) of
                        [] -> 
                            {fail, 9};
                        _ ->
                            {ok, [Color, PlayerStatus, [{GoodsInfo, Num}|L], [ResolveRule|RList], ResolveRule#ets_goods_resolve.coin+Cost, GoodsStatus]}
                    end
            end
    end.

%% 装备精炼
check_weapon_compose(PlayerStatus, GoodsStatus, GoodsId, StoneList, StuffList) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    Sell = PlayerStatus#player_status.sell,
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不存在
        GoodsInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品位置不正确
        %GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
        %    {fail, 4};
        %% 物品类型不正确
        GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP ->
            {fail, 5};
        %% 石头数量不正确
        length(StoneList) =:= 0 orelse length(StoneList) =:= 0 ->
            {fail, 7};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 8};
        %% 背包满
        length(GoodsStatus#goods_status.null_cells) =:= 0 ->
            {fail, 9};
        GoodsInfo#goods.hole1_goods =/= 0 orelse GoodsInfo#goods.hole2_goods =/= 0 orelse GoodsInfo#goods.hole3_goods =/= 0 ->
            {fail, 14};
        true ->
            RuleInfo = data_equip:get_compose(GoodsInfo#goods.goods_id),
            if  %% 合成规则不存在
                is_record(RuleInfo, ets_weapon_compose) =:= false ->
                    {fail, 11};
                %% 玩家铜钱不足
                (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < RuleInfo#ets_weapon_compose.coin ->
                    {fail, 12};
                true ->
                    case lib_goods_check:list_handle(fun check_weapon_stone/2, [PlayerStatus#player_status.id, RuleInfo, 0, [], GoodsStatus], StoneList) of
                        {fail, Res} ->
                            {fail, Res};
                        {ok, [_, _, TotalStoneNum, NewStoneList, _]} ->
                            if  %% 石头数量不正确
                                TotalStoneNum =/= RuleInfo#ets_weapon_compose.stone_num ->
                                    {fail, 7};
                                true ->
                                   case lib_goods_check:list_handle(fun check_weapon_stuff/2, [PlayerStatus#player_status.id, RuleInfo, 0, [], GoodsStatus], StuffList) of
                                        {fail, Res} ->
                                            {fail, Res};
                                        {ok, [_, _, TotalStuffNum, NewStuffList, _]} ->
                                            if  %% 碎片数量不正确
                                                TotalStuffNum =/= RuleInfo#ets_weapon_compose.stuff_num ->
                                                    {fail, 7};
                                                true ->
                                                    case data_goods_type:get(RuleInfo#ets_weapon_compose.new_id) of
                                                        [] -> {fail, 2};
                                                        GoodsTypeInfo -> {ok, GoodsTypeInfo, GoodsInfo, RuleInfo, NewStoneList, NewStuffList}
                                                    end
                                            end;
                                        _R ->
                                            ok
                                            %io:format("check_weapon_compose _R = ~p~n", [_R])
                                    end
                            end
                    end
            end
    end.

%% 处理精炼石头
check_weapon_stone({StoneId, StoneNum}, [PlayerId, RuleInfo, Num, L, GoodsStatus]) ->
    StoneInfo = lib_goods_util:get_goods(StoneId, GoodsStatus#goods_status.dict),
    if %% 物品不存在
        is_record(StoneInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        StoneInfo#goods.player_id =/= PlayerId ->
            {fail, 3};
        %% 物品位置不正确
        StoneInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        StoneInfo#goods.goods_id =/= RuleInfo#ets_weapon_compose.stone_id ->
            {fail, 5};
        %% 物品数量不正确
        StoneNum < 1 orelse StoneInfo#goods.num < StoneNum ->
            {fail, 7};
        true ->
            {ok, [PlayerId, RuleInfo, Num+StoneNum, [{StoneInfo, StoneNum}|L], GoodsStatus]}
    end.

%% 处理精炼碎片
check_weapon_stuff({StuffId, StuffNum}, [PlayerId, RuleInfo, Num, L, GoodsStatus]) ->
    StuffInfo = lib_goods_util:get_goods(StuffId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(StuffInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        StuffInfo#goods.player_id =/= PlayerId ->
            {fail, 3};
        %% 物品位置不正确
        StuffInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        StuffInfo#goods.goods_id =/= RuleInfo#ets_weapon_compose.stuff_id ->
            {fail, 5};
        %% 物品数量不正确
        StuffNum < 1 orelse StuffInfo#goods.num < StuffNum ->
            {fail, 7};
        true ->
            {ok, [PlayerId, RuleInfo, Num+StuffNum, [{StuffInfo, StuffNum}|L], GoodsStatus]}
    end.

%% 装备进阶
check_equip_advanced(PlayerStatus, GoodsStatus, GoodsId, StoneList, StuffList) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    Sell = PlayerStatus#player_status.sell,
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不存在
        GoodsInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品位置不正确
        %GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
        %    {fail, 4};
        %% 物品类型不正确
        GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP ->
            {fail, 5};
        %% 石头数量不正确
        length(StoneList) =:= 0 orelse length(StoneList) =:= 0 ->
            {fail, 7};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 8};
        %% 背包满
        length(GoodsStatus#goods_status.null_cells) =:= 0 ->
            {fail, 9};
        %GoodsInfo#goods.hole1_goods =/= 0 orelse GoodsInfo#goods.hole2_goods =/= 0 orelse GoodsInfo#goods.hole3_goods =/= 0 ->
        %    {fail, 14};
        true ->
            RuleInfo = data_equip:get_compose(GoodsInfo#goods.goods_id),
            if  %% 合成规则不存在
                is_record(RuleInfo, ets_weapon_compose) =:= false ->
                    {fail, 11};
                %% 玩家铜钱不足
                (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < RuleInfo#ets_weapon_compose.coin ->
                    {fail, 12};
                true ->
                    case lib_goods_check:list_handle(fun check_weapon_stone/2, [PlayerStatus#player_status.id, RuleInfo, 0, [], GoodsStatus], StoneList) of
                        {fail, Res} ->
                            {fail, Res};
                        {ok, [_, _, TotalStoneNum, NewStoneList, _]} ->
                            if  %% 石头数量不正确
                                TotalStoneNum =/= RuleInfo#ets_weapon_compose.stone_num ->
                                    {fail, 7};
                                true ->
                                   case lib_goods_check:list_handle(fun check_weapon_stuff/2, [PlayerStatus#player_status.id, RuleInfo, 0, [], GoodsStatus], StuffList) of
                                        {fail, Res} ->
                                            {fail, Res};
                                        {ok, [_, _, TotalStuffNum, NewStuffList, _]} ->
                                            if  %% 碎片数量不正确
                                                TotalStuffNum =/= RuleInfo#ets_weapon_compose.stuff_num ->
                                                    {fail, 7};
                                                true ->
                                                    case data_goods_type:get(RuleInfo#ets_weapon_compose.new_id) of
                                                        [] -> {fail, 2};
                                                        GoodsTypeInfo -> 
                                                            NewGoodsInfo = lib_equip_reiki:get_goods_reiki(GoodsInfo),
                                                            {ok, GoodsTypeInfo, NewGoodsInfo, RuleInfo, NewStoneList, NewStuffList}
                                                    end
                                            end;
                                        _R ->
                                            ok
                                    end
                            end
                    end
            end
    end.

%% 处理进阶石头
check_advanced_stone({StoneId, StoneNum}, [PlayerId, RuleInfo, Num, L, GoodsStatus]) ->
    StoneInfo = lib_goods_util:get_goods(StoneId, GoodsStatus#goods_status.dict),
    if %% 物品不存在
        is_record(StoneInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        StoneInfo#goods.player_id =/= PlayerId ->
            {fail, 3};
        %% 物品位置不正确
        StoneInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        StoneInfo#goods.goods_id =/= RuleInfo#ets_weapon_compose.stone_id ->
            {fail, 5};
        %% 物品数量不正确
        StoneNum < 1 orelse StoneInfo#goods.num < StoneNum ->
            {fail, 7};
        true ->
            {ok, [PlayerId, RuleInfo, Num+StoneNum, [{StoneInfo, StoneNum}|L], GoodsStatus]}
    end.

%% 处理进阶碎片
check_advanced_stuff({StuffId, StuffNum}, [PlayerId, RuleInfo, Num, L, GoodsStatus]) ->
    StuffInfo = lib_goods_util:get_goods(StuffId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(StuffInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        StuffInfo#goods.player_id =/= PlayerId ->
            {fail, 3};
        %% 物品位置不正确
        StuffInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        StuffInfo#goods.goods_id =/= RuleInfo#ets_weapon_compose.stuff_id ->
            {fail, 5};
        %% 物品数量不正确
        StuffNum < 1 orelse StuffInfo#goods.num < StuffNum ->
            {fail, 7};
        true ->
            {ok, [PlayerId, RuleInfo, Num+StuffNum, [{StuffInfo, StuffNum}|L], GoodsStatus]}
    end.

%%检查装备继承
check_equip_inherit(PlayerStatus, GoodsStatus, LowId, HighId, StuffList) ->
    LowInfo = lib_goods_util:get_goods(LowId, GoodsStatus#goods_status.dict),
    HighInfo = lib_goods_util:get_goods(HighId, GoodsStatus#goods_status.dict),
    Sell = PlayerStatus#player_status.sell,
    if
        %% 物品不存在
        is_record(LowInfo, goods) =:= false orelse is_record(HighInfo, goods) =:= false ->
            {fail, 2};    
        true ->
            [A, B, C, D, _E, F] = integer_to_list(LowInfo#goods.goods_id),
            [A1, B1, C1, D1, _E1, F1] = integer_to_list(HighInfo#goods.goods_id),
            LowF = list_to_integer([F]),
            HighF = list_to_integer([F1]),
            %% 女武器为6,7,8,9,0,+5取个位为颜色
            if 
                LowF > 5 ->
                    [_Ten, Bit] = integer_to_list(LowF+5),
                    Flag = 1,
                    LowF1 = list_to_integer([Bit]);
                LowF =:= 0 ->
                    Flag = 1,
                    LowF1 = LowF+5;
                true ->
                    Flag = 0,
                    LowF1 = LowF
            end,
            if
                HighF > 5 ->
                    [_Ten1, Bit1] = integer_to_list(HighF+5),
                    Flag1 = 1,
                    HighF1 = list_to_integer([Bit1]);
                HighF =:= 0 ->
                    Flag1 = 1,
                    HighF1 = HighF+5;
                true ->
                    Flag1 = 0,
                    HighF1 = HighF
            end,
            %io:format("low1 = ~p~n", [{LowF1, HighF1, LowInfo#goods.goods_id, HighInfo#goods.goods_id}]),
            if  %% 装备性别不同
                LowF > 5 andalso HighF < 5 andalso HighF =/= 0 ->
                    {fail, 12};
                LowF =< 5 andalso LowF =/= 0 andalso (HighF > 5 orelse HighF =:= 0) ->
                    {fail, 12};
                Flag =/= Flag1 ->
                    {fail, 12};   
                %% 物品不属于你所有
                LowInfo#goods.player_id =/= PlayerStatus#player_status.id 
                orelse HighInfo#goods.player_id =/= PlayerStatus#player_status.id ->
                    {fail, 3};
                %% 物品位置不正确
                %HighInfo#goods.location =/= ?GOODS_LOC_BAG orelse LowInfo#goods.location =/= ?GOODS_LOC_BAG ->
                %    {fail, 4};
                %% 物品数量不正确
                HighInfo#goods.num < 1 orelse LowInfo#goods.num < 1 ->
                    {fail, 7};
                %% 正在交易中
                Sell#status_sell.sell_status =/= 0 ->
                    {fail, 8};
                %% 类型不对, 紫色以下的不能继承
                LowInfo#goods.subtype =/= HighInfo#goods.subtype orelse LowInfo#goods.type =/= HighInfo#goods.type ->
                    {fail, 5};
                LowF1 < 3 orelse HighF1 < 3 ->
                    {fail, 5};
                D =/= D1 orelse C =/= C1 orelse A =/=A1 orelse B =/= B1 ->
                    {fail, 5};
                true ->
                    %% 继承规则
                    EquipLevel = case LowInfo#goods.level >= HighInfo#goods.level of
                        true ->
                            LowInfo#goods.level;
                        false ->
                            HighInfo#goods.level
                    end,
                    Stren = case LowInfo#goods.stren >= HighInfo#goods.stren of
                        true ->
                            if
                                LowInfo#goods.stren > 0 ->
                                    LowInfo#goods.stren;
                                true ->
                                    1
                            end;
                        false ->
                            if
                                HighInfo#goods.stren > 0 ->
                                    HighInfo#goods.stren;
                                true ->
                                    1
                            end
                    end,
                    Level = data_goods:get_level(EquipLevel),
                    InheritRule = data_equip:get_inherit(Level),
                    Cost = Stren * EquipLevel * 250,
                    if
                        is_record(InheritRule, ets_inherit) =:= false ->
                            {fail, 11};
                        (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Cost ->
                            {fail, 9};
                        true ->
                            N1 = get_stone_num(LowInfo),
                            N2 = get_stone_num(HighInfo),
                            case lib_goods_check:list_handle(fun check_inherit_stuff/2, [PlayerStatus#player_status.id, InheritRule, [], GoodsStatus, 0], StuffList) of
                                {fail, Res} ->
                                    {fail, Res};
                                {ok, [_, _, NewStuffList, _, StuffNum]} ->
                                    if
                                        StuffNum =/= InheritRule#ets_inherit.num ->
                                            {fail, 7};
                                        %% 格子不足
                                        length(GoodsStatus#goods_status.null_cells) < N1 + N2 ->
                                            {fail, 6};
                                        true ->
                                            NewLowInfo = lib_equip_reiki:get_goods_reiki(LowInfo),
                                            NewHighInfo = lib_equip_reiki:get_goods_reiki(HighInfo),
                                            {ok, NewLowInfo, NewHighInfo, NewStuffList, InheritRule, Flag, Cost}
                                    end
                            end
                    end
            end
    end.

%% 装备宝石数
get_stone_num(GoodsInfo) ->
    Flag1 = case GoodsInfo#goods.hole1_goods > 0 of
        true ->
            1;
        false ->
            0
    end,
    Flag2 = case GoodsInfo#goods.hole2_goods > 0 of
        true ->
            1;
        false ->
            0
    end,
    Flag3 = case GoodsInfo#goods.hole3_goods > 0 of
        true ->
            1;
        false ->
            0
    end,
    Flag1+Flag2+Flag3.

check_inherit_stuff({StuffId, Num}, [PlayerId, Rule, L, GoodsStatus, N]) ->
    StuffInfo = lib_goods_util:get_goods(StuffId, GoodsStatus#goods_status.dict),
    if
        is_record(StuffInfo, goods) =:= false ->
            {fail, 2};
        StuffInfo#goods.player_id =/= PlayerId ->
            {fail, 3};
        StuffInfo#goods.num < Num ->
            {fail, 7};
        StuffInfo#goods.goods_id =/= Rule#ets_inherit.inherit_id ->
            {fail, 2};
        true ->
            {ok, [PlayerId, Rule, [{StuffInfo, Num}|L], GoodsStatus, Num+N]}
    end.

%% 装备升级
check_equip_upgrade(PlayerStatus, GoodsId, RuneId, Stuff1List, Stuff2List, Stuff3List, GoodsStatus) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    RuneInfo = case RuneId > 0 of
        true -> lib_goods_util:get_goods(RuneId, GoodsStatus#goods_status.dict);
        false -> #goods{}
    end,
    Sell = PlayerStatus#player_status.sell,
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false orelse is_record(RuneInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不存在
        GoodsInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不存在
        RuneId > 0 andalso RuneInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品不属于你所有
        RuneId > 0 andalso RuneInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品位置不正确
        %GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
        %    {fail, 4};
        %% 物品位置不正确
        RuneId > 0 andalso RuneInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP ->
            {fail, 5};
        %% 物品类型不正确
        RuneId > 0 andalso (RuneInfo#goods.type =/= ?GOODS_TYPE_RUNE orelse RuneInfo#goods.subtype =/= ?GOODS_SUBTYPE_GUARD_RUNE) ->
            {fail, 5};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 8};
        GoodsStatus#goods_status.null_cells =:= [] ->
            {fail, 10};
        true ->
            RuleInfo = data_equip:get_upgrade(GoodsInfo#goods.goods_id),
            %io:format("RuleInfo = ~p,~p~n", [GoodsInfo#goods.goods_id, RuleInfo]),
            if
                %% 升级规则不存在
                is_record(RuleInfo, ets_equip_upgrade) =:= false ->
                    {fail, 7};
                %% 玩家铜钱不足
                (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < RuleInfo#ets_equip_upgrade.coin ->
                    {fail, 9};
                %% 保护符不对
                RuneId > 0 andalso RuleInfo#ets_equip_upgrade.protect_id > 0 andalso RuneInfo#goods.goods_id =/= RuleInfo#ets_equip_upgrade.protect_id ->
                    {fail, 5};
                true ->
                    case lib_goods_check:list_handle(fun check_equip_upgrade_stuff/2, [PlayerStatus#player_status.id, RuleInfo#ets_equip_upgrade.trip_id, 0, [], GoodsStatus], Stuff1List) of
                        {fail, Res} ->
                            {fail, Res};
                        {ok, [_, _, TotalStuff1Num, NewStuff1List, _]} ->
                            if  %% 材料数量不正确
                                TotalStuff1Num < 1 orelse TotalStuff1Num =/= RuleInfo#ets_equip_upgrade.trip_num ->
                                    {fail, 6};
                                true ->
                                    case lib_goods_check:list_handle(fun check_equip_upgrade_stuff/2, [PlayerStatus#player_status.id, RuleInfo#ets_equip_upgrade.stone_id, 0, [], GoodsStatus], Stuff2List) of
                                        {fail, Res} ->
                                            {fail, Res};
                                        {ok, [_, _, TotalStuff2Num, NewStuff2List, _]} ->
                                            if  %% 材料数量不正确
                                                TotalStuff2Num =/= RuleInfo#ets_equip_upgrade.stone_num ->
                                                    {fail, 6};
                                                true ->
                                                    case lib_goods_check:list_handle(fun check_equip_upgrade_stuff/2, [PlayerStatus#player_status.id, RuleInfo#ets_equip_upgrade.iron_id, 0, [], GoodsStatus], Stuff3List) of
                                                        {fail, Res}->
                                                            {fail, Res};
                                                        {ok, [_, _, TotalStuff3Num, NewStuff3List, _]} ->
                                                            if  %% 材料数量不正确
                                                                TotalStuff3Num =/= RuleInfo#ets_equip_upgrade.iron_num ->
                                                                    {fail, 6};
                                                                true ->
                                                                    case data_goods_type:get(RuleInfo#ets_equip_upgrade.new_id) of
                                                                        [] -> {fail, 2};
                                                                        GoodsTypeInfo -> 
                                                                            NewGoodsInfo = lib_equip_reiki:get_goods_reiki(GoodsInfo),
                                                                            {ok, GoodsTypeInfo, NewGoodsInfo, RuneInfo, RuleInfo, NewStuff1List, NewStuff2List, NewStuff3List}
                                                                    end
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.
%% 处理装备升级材料
check_equip_upgrade_stuff({StuffId, StuffNum}, [PlayerId, Stuff_id, Num, L, GoodsStatus]) ->
    StuffInfo = lib_goods_util:get_goods(StuffId, GoodsStatus#goods_status.dict),
    if  %% 物品不存在
        is_record(StuffInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        StuffInfo#goods.player_id =/= PlayerId ->
            {fail, 3};
        %% 物品位置不正确
        StuffInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        StuffInfo#goods.goods_id =/= Stuff_id ->
            %io:format(" id = ~p~n", [{StuffInfo#goods.goods_id, Stuff_id}]),
            {fail, 5};
        %% 材料数量不正确
        StuffNum < 1 orelse StuffInfo#goods.num < StuffNum ->
            {fail, 6};
        true ->
            {ok, [PlayerId, Stuff_id, Num+StuffNum, [{StuffInfo, StuffNum}|L], GoodsStatus]}
    end.

%% 装备附加属性洗炼
check_attribute_wash(PlayerStatus, GoodsId, Time, Grade, StoneList, LockList, GoodsStatus) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    Lock_num = length(LockList),
    %% 1.检查装备
    Sell = PlayerStatus#player_status.sell,
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不存在
        GoodsInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品类型不正确
        GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP andalso GoodsInfo#goods.type =/= ?GOODS_TYPE_MOUNT ->
            {fail, 5};
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 8};
        true ->
            %% 检查洗炼规则
            WashRule = data_wash:get_wash_rule(Grade),
            TypeRule = data_wash:get_wash_attribute_type(GoodsInfo#goods.subtype),
            StarRule = data_wash:get_wash_star(Grade),
            if 
                is_record(TypeRule, ets_wash_attribute_type) =:= false orelse is_record(StarRule, ets_wash_star) =:= false 
                  orelse is_record(WashRule, ets_wash_rule) =:= false ->
                    {fail, 12};
                true ->
                    %% 检查洗炼石 
                    case lib_goods_check:list_handle(fun check_wash_stone2/2, [[], GoodsStatus, 0], StoneList) of
                        {fail, Res3} ->
                            {fail, Res3};
                        {ok, [NewStoneList, _, StoneNum]} ->
                            if 
                                StoneNum =< 0 ->
                                    {fail, 6};
                                StoneNum =/= Time + Time*Lock_num ->
                                    {fail, 6};
                                true ->
                                    %% 消耗的铜钱
                                    Cost = case Time > 1 of 
                                        false ->
                                            WashRule#ets_wash_rule.coin;
                                        true ->
                                            WashRule#ets_wash_rule.coin*Time
                                    end,
                                    if 
                                        (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Cost ->
                                            {fail, 9};
                                        Lock_num > 0 -> %有锁住
                                            case lib_goods_check:list_handle(fun check_attribute_type/2, [[], Grade, GoodsInfo], LockList) of 
                                                {fail, Res1} ->
                                                    {fail, Res1};
                                                {ok, _} ->
                                                    {ok, GoodsInfo, NewStoneList, LockList, WashRule, TypeRule, StarRule, Cost}
                                            end;
                                        true -> % 无锁住
                                            {ok, GoodsInfo, NewStoneList, [], WashRule, TypeRule, StarRule, Cost}
                                    end
                            end
                    end
            end
    end.

% check_wash_stone({StoneId, Num}, [L, GoodsStatus, N]) ->
%     StoneInfo = lib_goods_util:get_goods(StoneId, GoodsStatus#goods_status.dict),
%     if
%         %% 物品不存在
%         is_record(StoneInfo, goods) =:= false orelse StoneInfo#goods.num < 1 ->
%             {fail, 2};
%         %% 物品不属于你所有
%         StoneInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
%             {fail, 3};
%         StoneInfo#goods.location =/= ?GOODS_LOC_BAG ->
%             {fail, 4};
%         StoneInfo#goods.goods_id =/= 601501 ->
%             {fail, 5};
%         StoneInfo#goods.num < Num ->
%             {fail, 6};
%         true ->
%             {ok,[[{StoneInfo, Num}|L], GoodsStatus, Num+N]}
%     end.

%% 检查洗炼石头
check_wash_stone2({StoneId, Num}, [L,GoodsStatus, N]) ->
    StoneInfo = lib_goods_util:get_goods(StoneId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(StoneInfo, goods) =:= false orelse StoneInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        StoneInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
            {fail, 3};
        StoneInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        % %% 洗炼石类型不正确
        % StoneInfo#goods.goods_id =/= WashRule#ets_wash_rule.stone_id ->
        %     {fail, 5};
        StoneInfo#goods.num < Num ->
            {fail, 6};
        true ->
            {ok,[[{StoneInfo, Num}|L], GoodsStatus, Num+N]}
    end.

%% 处理锁定列表
check_attribute_type({Type, Star, Value, Color, Min, Max}, [L, Grade, GoodsInfo]) ->
    % if length(GoodsInfo#goods.addition) < 10 ->
    %     AttributeList = GoodsInfo#goods.addition;
    % true ->
    %     [Old|_] = GoodsInfo#goods.addition,
    %     [_|AttributeList] = tuple_to_list(Old)
    % end,
    case Grade of 
        1 ->
            AttributeList = GoodsInfo#goods.addition_1;
        2 ->
            AttributeList = GoodsInfo#goods.addition_2;
        _ ->
            AttributeList = GoodsInfo#goods.addition_3
    end,
    case lists:member({Type, Star, Value, Color, Min, Max}, AttributeList) of
        true ->
            {ok, [[{Type, Star, Value, Color, Min, Max}|L], Grade, GoodsInfo]};
        false ->
            {fail, 7}
    end.

%% 检查选择洗炼 属性
 check_attribute_sel(_PlayerStatus, _GoodsId, _Pos, _GoodsStatus) ->
    ok.
%     GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
%     if  %% 物品不存在
%         is_record(GoodsInfo, goods) =:= false  ->
%             {fail, 2};
%         %% 物品不存在
%         GoodsInfo#goods.num < 1 ->
%             {fail, 2};
%         %% 物品不属于你所有
%         GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
%             {fail, 3};
%         %% 物品位置不正确
%         %GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
%         %    {fail, 4};
%         %% 物品类型不正确
%         GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP andalso GoodsInfo#goods.type =/= ?GOODS_TYPE_MOUNT ->
%             {fail, 5};
%         true ->
%             case is_attribute_exist(GoodsInfo#goods.addition, Pos, []) of
%                 [] -> %% 属性不存在
%                     {fail, 6};
%                 AttrList ->
%                     {ok, [GoodsInfo, AttrList]}
%             end
%     end.
is_attribute_exist([], _Pos, L) ->
    L;
is_attribute_exist([H|T], Pos, L) ->
    %% {位置，属性}，如果不是，则表示只有一个属性，不能选
    [P|Attr] = tuple_to_list(H),
    case P =:= Pos of
        true ->
            is_attribute_exist(T, Pos, Attr ++ L);
        false ->
            is_attribute_exist(T, Pos, L)
    end.

%% 洗炼信息
check_attribute_get(PlayerStatus, GoodsId, GoodsStatus) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false  ->
            {fail, 2};
        %% 物品不存在
        GoodsInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品类型不正确
        GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP ->
            {fail, 4};
        true ->
            % case length(GoodsInfo#goods.addition) of
            %     1 ->
            %         [T] = GoodsInfo#goods.addition,
            %         [A|Attr] = tuple_to_list(T),
            %         if
            %             is_integer(A) =:= true ->
            %                 NewGoodsInfo = GoodsInfo#goods{addition=Attr};
            %             true ->
            %                 NewGoodsInfo = GoodsInfo
            %         end;
            %     _ ->
            %         NewGoodsInfo = GoodsInfo
            % end,
            {ok, GoodsInfo#goods.addition_1, GoodsInfo#goods.addition_2, GoodsInfo#goods.addition_3}
    end.

%% 隐藏时装
check_hide_fashion(PlayerStatus, GoodsId, GoodsStatus) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false  ->
            {fail, 2};
        %% 物品不存在
        GoodsInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品位置不正确
        GoodsInfo#goods.location =:= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP ->
            {fail, 5};
        GoodsInfo#goods.subtype =/= ?GOODS_FASHION_WEAPON andalso
        GoodsInfo#goods.subtype =/= ?GOODS_FASHION_ARMOR andalso GoodsInfo#goods.subtype =/= ?GOODS_FASHION_ACCESSORY andalso GoodsInfo#goods.subtype =/= ?GOODS_FASHION_HEAD andalso GoodsInfo#goods.subtype =/= ?GOODS_FASHION_TAIL andalso GoodsInfo#goods.subtype =/= ?GOODS_FASHION_RING ->
            {fail, 5};
        true ->
            G = PlayerStatus#player_status.goods,
            [Weapon, _] = G#status_goods.fashion_weapon,
            [Armor, _] = G#status_goods.fashion_armor,
            [Accessory, _] = G#status_goods.fashion_accessory,
            [Head, _] = G#status_goods.fashion_head,
            [Tail, _] = G#status_goods.fashion_tail,
            [Ring, _] = G#status_goods.fashion_ring,
            Flag1 = lib_goods_compose:check_fashion_dict(GoodsInfo#goods.goods_id, PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 1),
            Flag2 = lib_goods_compose:check_fashion_dict(GoodsInfo#goods.goods_id, PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 2),
            Flag3 = lib_goods_compose:check_fashion_dict(GoodsInfo#goods.goods_id, PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 3),
            Flag4 =
            lib_goods_compose:check_fashion_dict(GoodsInfo#goods.goods_id,
                PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 4),
            Flag5 =
            lib_goods_compose:check_fashion_dict(GoodsInfo#goods.goods_id,
                PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 5),
            Flag6 =
            lib_goods_compose:check_fashion_dict(GoodsInfo#goods.goods_id,
                PlayerStatus#player_status.change_dict, GoodsInfo#goods.id, 6),
            if
                GoodsInfo#goods.goods_id =/= Weapon andalso
                GoodsInfo#goods.goods_id =/= Armor andalso
                GoodsInfo#goods.goods_id =/= Accessory andalso
                GoodsInfo#goods.goods_id =/= Head andalso
                GoodsInfo#goods.goods_id =/= Tail andalso
                GoodsInfo#goods.goods_id =/= Ring andalso
                Flag1 =:= false andalso Flag2 =:= false andalso 
                Flag3 =:= false andalso Flag4 =:= false andalso 
                Flag5 =:= false andalso Flag6 =:= false ->
                    {fail, 5};
                true ->
                    {ok, GoodsInfo}
            end
    end.

%% ========================= 装备  end ==================================================================
%% 检查坐骑卡使用
check_mount_card(PlayerStatus, GoodsId, GoodsStatus) ->
    Mou = PlayerStatus#player_status.mount,
    Count = lib_mount:get_mount_count(PlayerStatus#player_status.id, Mou#status_mount.mount_dict),
    Sell = PlayerStatus#player_status.sell,
    
    if  %% 坐骑栏数量已满
        Count >= Mou#status_mount.mount_lim ->
            {fail, 2};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 3};
        true ->
            GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
            if
                %% 物品不存在
                is_record(GoodsInfo, goods) =:= false ->
                    {fail, 4};
                GoodsInfo#goods.num < 1 ->
                    {fail, 4};
                %% 物品不属于你所有
                GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
                    {fail, 5};
                %% 物品位置不正确
                GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
                    {fail, 6};
                %% 物品类型不正确
                GoodsInfo#goods.type =/= ?GOODS_TYPE_MOUNT orelse GoodsInfo#goods.subtype =/= ?GOODS_SUBTYPE_MOUNT_CARD ->
                    {fail, 7};
                true ->
                    case data_mount:get_mount_upgrade(GoodsInfo#goods.goods_id) of
                        [] -> {fail, 7};
                        Base ->
                            {ok, GoodsInfo, Base}
                    end
            end
    end.
     
%% 检查宝石合成
%%check_compose(PlayerStatus, GoodsStatus, RuneId, StoneTypeId, StoneList) ->
%%    case RuneId > 0 of
%%        true ->
%%            RuneInfo = lib_goods_util:get_goods(RuneId, GoodsStatus#goods_status.dict);
%%        false ->
%%            RuneInfo = #goods{player_id = PlayerStatus#player_status.id}
%%    end,
%%    Sell = PlayerStatus#player_status.sell,
%%    if 
%%        %% 物品不存在
%%        is_record(RuneInfo, goods) =:= false ->
%%            {fail, 2};
%%        %% 物品不属于你所有
%%        RuneInfo#goods.id > 0  andalso RuneInfo#goods.player_id =/= PlayerStatus#player_status.id ->
%%            {fail, 3};
%%        %% 物品位置不正确
%%        RuneInfo#goods.id > 0  andalso RuneInfo#goods.location =/= ?GOODS_LOC_BAG ->
%%            {fail, 4};
%%        %% 物品类型不正确
%%        RuneInfo#goods.id > 0  andalso (RuneInfo#goods.type =/= 12 orelse RuneInfo#goods.subtype =/= 13) ->
%%            {fail, 5};
%%        %% 物品数量不正确
%%        RuneInfo#goods.id > 0  andalso RuneInfo#goods.num < 1 ->
%%            {fail, 6};
%%        %% 物品数量不正确
%%        length(StoneList) =:= 0 ->
%%            {fail, 6};
%%        %% 正在交易中
%%        Sell#status_sell.sell_status =/= 0 ->
%%            {fail, 11};
%%        true ->
%%            %% 根据不同的宝石数得到相应的合成规则,成功率不同 
%%            case lib_goods_check:list_handle(fun check_compose_stone/2, [RuneInfo, StoneTypeId, 0, [], GoodsStatus], StoneList) of
%%                {fail, Res} ->
%%                    {fail, Res};
%%                {ok, [_, _, TotalStoneNum, NewStoneList, _]} ->
%%                    GoodsComposeRule = data_gemstone:get_compose_rule(StoneTypeId, TotalStoneNum),
%%                    if  %% 合成规则不存在
%%                        is_record(GoodsComposeRule, ets_goods_compose) =:= false ->
%%                            {fail, 7};
%%                        %% 物品数量不正确
%%                        TotalStoneNum > 4 ->
%%                            {fail, 6};
%%                        %% 玩家铜钱不足
%%                        (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < GoodsComposeRule#ets_goods_compose.coin ->
%%                            {fail, 8};
%%                        %% 背包满
%%                        length(GoodsStatus#goods_status.null_cells) =:= 0 ->
%%                            {fail, 9};
%%                        true ->
%%                            {ok, NewStoneList, RuneInfo, GoodsComposeRule}
%%                    end
%%            end
%%    end.
check_compose(PlayerStatus, GoodsStatus, RuneList, StoneTypeId, StoneList, Times, IsRune, PerNum) ->
    Sell = PlayerStatus#player_status.sell,
    if
        %% 物品数量不正确
        length(StoneList) =:= 0 ->
            {fail, 6};
            %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 11};
        Times =< 0 orelse PerNum =< 0 ->
            {fail, 6};
        (IsRune > 0 andalso length(RuneList) =< 0) orelse (IsRune =:= 0 andalso length(RuneList) > 0) ->
            {fail, 6};
        %% VIP等级不够
        Times > 1 andalso (PlayerStatus#player_status.vip#status_vip.vip_type =/= 3 orelse PlayerStatus#player_status.vip#status_vip.growth_lv < 1) ->
            {fail, 12};
        true ->
            case lib_goods_check:list_handle(fun check_compose_stone/2, [PlayerStatus#player_status.id, StoneTypeId, 0, [], GoodsStatus], StoneList) of
                {fail, Res} ->
                    {fail, Res};
                {ok, [_, _, TotalStoneNum, NewStoneList, _]} ->
                    if
                        TotalStoneNum < Times * PerNum ->
                            {fail, 6};
                        true ->
                            [{StoneInfo, _}|_] = NewStoneList,
                            GoodsComposeRule = data_gemstone:get_compose_rule(StoneTypeId, PerNum),
                            if  %% 合成规则不存在
                                is_record(GoodsComposeRule, ets_goods_compose) =:= false ->
                                    {fail, 7};
                                    %% 玩家铜钱不足
                                (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < GoodsComposeRule#ets_goods_compose.coin * Times ->
                                    {fail, 8};
                                %% 背包满
                                length(GoodsStatus#goods_status.null_cells) =:= 0 ->
                                    {fail, 9};
                                true ->
                                    if
                                        IsRune =< 0 ->
                                            NewRuneList = [{#goods{player_id = PlayerStatus#player_status.id}, 0}],
                                            {ok, NewStoneList, NewRuneList, GoodsComposeRule, Times, IsRune};
                                        true ->
                                            case lib_goods_check:list_handle(fun check_compose_rune/2, [StoneInfo, 0, [], GoodsStatus, PlayerStatus#player_status.id], RuneList) of
                                                {fail, Res} ->
                                                    {fail, Res};
                                                {ok, [_, RuneNum, NewRuneList, _, _]} ->
                                                    if
                                                        RuneNum =/= Times ->
                                                            {fail, 6};
                                                        true ->
                                                            {ok, NewStoneList, NewRuneList, GoodsComposeRule, Times, IsRune}
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.
                                
%% 护符
check_compose_rune({RuneId, RuneNum}, [StoneInfo, Num, L, GoodsStatus, PlayerId]) ->
    RuneInfo = lib_goods_util:get_goods(RuneId, GoodsStatus#goods_status.dict),
    if 
        %% 物品不存在
        is_record(RuneInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        RuneInfo#goods.player_id =/= PlayerId ->
            {fail, 3};
        %% 物品位置不正确
        RuneInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        (RuneInfo#goods.type =/= 12 orelse RuneInfo#goods.subtype =/= 13) ->
            {fail, 5};
        %% 物品数量不正确
        RuneInfo#goods.num < 1 ->
            {fail, 6};
        RuneInfo#goods.color < StoneInfo#goods.color ->
            {fail, 5};
       true ->
            {ok, [StoneInfo, Num+RuneNum, [{RuneInfo, RuneNum}|L], GoodsStatus, PlayerId]}
    end. 

%% 处理合成宝石
check_compose_stone({StoneId, StoneNum}, [PlayerId, StoneTypeId, Num, L, GoodsStatus]) ->
    StoneInfo = lib_goods_util:get_goods(StoneId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(StoneInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        StoneInfo#goods.player_id =/= PlayerId ->
            {fail, 3};
        %% 物品位置不正确
        StoneInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        StoneInfo#goods.goods_id =/= StoneTypeId ->
            {fail, 5};
        %% 物品类型不正确
        %RuneInfo#goods.id > 0 andalso RuneInfo#goods.color < StoneInfo#goods.color ->
        %    {fail, 5};
        %% 物品数量不正确
        StoneNum < 1 orelse StoneInfo#goods.num < StoneNum ->
            {fail, 6};
        true ->
            {ok, [PlayerId, StoneTypeId, Num+StoneNum, [{StoneInfo, StoneNum}|L], GoodsStatus]}
    end.

%% 宝石镶嵌
check_inlay(PlayerStatus, GoodsId,S1, R1, S2, R2, S3, R3, GoodsStatus) ->
    Sell = PlayerStatus#player_status.sell,
    %% 正在交易中
    if Sell#status_sell.sell_status =/= 0 ->
           {fail, 11};
       %% 缺少物品
       S1 =< 0 orelse R1 =< 0 ->
           {fail, 12};
       (S2 > 0 andalso R2 =< 0) orelse (R2 > 0 andalso S2 =< 0) ->
           {fail, 12};
       (S3 > 0 andalso R3 =< 0) orelse (R3 > 0 andalso S3 =< 0) ->
           {fail, 12};
       true ->
           GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
           case check_inlay_equip(PlayerStatus, GoodsInfo) of
               {fail, Res} ->
                   {fail, Res};
               ok ->
                   if   %%检查第一组
                       S1 > 0 andalso R1 > 0 ->
                           case check_stone_and_rune(S1, R1, PlayerStatus, GoodsStatus, GoodsInfo) of
                               {fail, Res1} ->
                                   {fail, Res1};
                               {ok, Stone1Info, Rune1Info, GoodsInlayRule1} ->
                                   if   %%检查第二组
                                       S2 >0 andalso R2 > 0 ->
                                           case check_stone_and_rune(S2, R2, PlayerStatus, GoodsStatus, GoodsInfo) of
                                               {fail, Res2} ->
                                                   {fail, Res2};
                                               {ok, Stone2Info, Rune2Info, GoodsInlayRule2} ->
                                                   if
                                                       (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < (GoodsInlayRule2#ets_goods_inlay.coin + GoodsInlayRule1#ets_goods_inlay.coin) ->
                                                           {fail, 8};
                                                       true ->
                                                           %%检查第三组
                                                           if S3 > 0 andalso R3 > 0 ->
                                                                  case check_stone_and_rune(S2, R2, PlayerStatus, GoodsStatus, GoodsInfo) of
                                                                      {fail, Res3} ->
                                                                          {fail, Res3};
                                                                      {ok, Stone3Info, Rune3Info, GoodsInlayRule3} ->
                                                                          if (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < (GoodsInlayRule2#ets_goods_inlay.coin + GoodsInlayRule1#ets_goods_inlay.coin + GoodsInlayRule3#ets_goods_inlay.coin) ->
                                                                                 {fail, 8};
                                                                             true ->
                                                                                 {ok, GoodsInfo, Stone1Info, Stone2Info, Stone3Info, Rune1Info, Rune2Info, Rune3Info, GoodsInlayRule1, GoodsInlayRule2, GoodsInlayRule3}
                                                                          end
                                                                  end;
                                                              true ->
                                                                  {ok, GoodsInfo, Stone1Info, Stone2Info, [], Rune1Info, Rune2Info, [], GoodsInlayRule1, GoodsInlayRule2, []}
                                                           end
                                                   end
                                           end;
                                       true ->
                                           {ok, GoodsInfo, Stone1Info, [], [], Rune1Info, [], [], GoodsInlayRule1, [], []}
                                   end
                               end;
                       true ->
                           %% 缺少物品
                           {fail, 12}
                   end
           end
    end.

check_stone_and_rune(StoneId, RuneId, PlayerStatus, GoodsStatus, GoodsInfo) ->
    StoneInfo = lib_goods_util:get_goods(StoneId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(StoneInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        StoneInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品位置不正确
        StoneInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品数量不正确
        StoneInfo#goods.num < 1 ->
            {fail, 13};
        true -> %%石头
            case lib_goods_check:list_handle(fun check_inlay_stone/2, StoneInfo,
                    [GoodsInfo#goods.hole1_goods,GoodsInfo#goods.hole2_goods,GoodsInfo#goods.hole3_goods]) of
                {fail, Res} ->
                    {fail, Res};
                {ok, StoneInfo} ->
                    %% 符
                    case check_inlay_rune(RuneId, PlayerStatus#player_status.id, StoneInfo, GoodsStatus) of
                        {fail, Res1} ->
                            {fail, Res1};
                        {ok, RuneInfo} ->
                            %% 规则
                            case check_inlay_rule(PlayerStatus, GoodsInfo, StoneInfo) of
                                {fail, Res3} ->
                                    {fail, Res3};
                                {ok, GoodsInlayRule} ->
                                    {ok, StoneInfo, RuneInfo, GoodsInlayRule}
                            end
                    end
            end
    end.

%% 处理镶嵌装备
check_inlay_equip(PlayerStatus, GoodsInfo) ->
    if
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不存在
        GoodsInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品位置不正确
        %GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
        %    {fail, 4};
        %% 物品类型不正确
        GoodsInfo#goods.type =/= 10 ->
            {fail, 5};
        %% 物品类型不正确
       % GoodsInfo#goods.type =:= 10 andalso (GoodsInfo#goods.subtype =:= 30 orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_ARMOR
       %     orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_WEAPON orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_ACCESSORY orelse GoodsInfo#goods.subtype =:= 70) ->
       %     {fail, 5};
        %% 没有孔位
        GoodsInfo#goods.hole =:= 0 ->
            {fail, 6};
        true ->
            InlayNum = lib_goods_util:get_inlay_num(GoodsInfo),
            case InlayNum =:= GoodsInfo#goods.hole of
                true -> {fail, 6};
                false -> ok
            end
    end.

%% 处理镶嵌石
check_inlay_stone(InlayTypeId, StoneInfo) ->
    if InlayTypeId > 0 ->
            InlayTypeInfo = data_goods_type:get(InlayTypeId),
            InlayAttribute = data_goods:get_inlay_attribute_by_type(InlayTypeInfo),
            StoneAttribute = data_goods:get_inlay_attribute_by_goods(StoneInfo),
            case is_record(InlayTypeInfo, ets_goods_type) of
                %% 物品类型不正确，已有相同类型的石头
                true when InlayAttribute =:= StoneAttribute ->
                    {fail, 5};
                true ->
                    {ok, StoneInfo};
                %% 未知错误，原镶嵌石类型不正确
                false ->
                    {fail, 10}
            end;
        true -> {ok, StoneInfo}
    end.

%% 处理镶嵌符
check_inlay_rune(RuneId, PlayerId, StoneInfo, GoodsStatus) ->
    RuneInfo = lib_goods_util:get_goods(RuneId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(RuneInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        RuneInfo#goods.player_id =/= PlayerId ->
            {fail, 3};
        %% 物品位置不正确
        RuneInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        RuneInfo#goods.type =/= 12 orelse RuneInfo#goods.subtype =/= 14 ->
            {fail, 5};
        %% 物品类型不正确
        RuneInfo#goods.color < StoneInfo#goods.color ->
            {fail, 5};
        true ->
            {ok, RuneInfo}
    end.

%% 处理镶嵌规则
check_inlay_rule(PlayerStatus, GoodsInfo, StoneInfo) ->
    GoodsInlayRule = data_gemstone:get_inlay_rule(StoneInfo#goods.goods_id),
    if
        %% 镶嵌规则不存在
        is_record(GoodsInlayRule, ets_goods_inlay) =:= false ->
            {fail, 7};
        %% 玩家铜钱不足
        (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < GoodsInlayRule#ets_goods_inlay.coin ->
            {fail, 8};
        true ->
            case length(GoodsInlayRule#ets_goods_inlay.equip_types) > 0
                    andalso lists:member(GoodsInfo#goods.subtype, GoodsInlayRule#ets_goods_inlay.equip_types) =:= false of
                %% 不可镶嵌的类型
                true -> {fail, 9};
                false -> {ok, GoodsInlayRule}
            end
    end.

check_backout(PlayerStatus, GoodsStatus, GoodsId, Pos1, RuneId1, Pos2, RuneId2, Pos3, RuneId3) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    Sell = PlayerStatus#player_status.sell,
    if  %% 缺少数据
        Pos1 =< 0 orelse RuneId1 =< 0 ->
            {fail, 12};
        (Pos2 > 0 andalso RuneId2 =< 0) orelse (Pos2 =< 0 andalso RuneId2 > 0) ->
           {fail, 12};
       (Pos3 > 0 andalso RuneId3 =< 0) orelse (Pos3 =< 0 andalso RuneId3 > 0) ->
           {fail, 12};
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false orelse GoodsInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品位置不正确
        %GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
        %    {fail, 4};
        %% 物品类型不正确
        GoodsInfo#goods.type =/= 10 ->
            {fail, 5};
        %% 格子不足
        length(GoodsStatus#goods_status.null_cells) =:= 0 ->
            {fail, 7};
        ((Pos1 > 0 andalso Pos2 > 0) orelse (Pos1 > 0 andalso Pos3 > 0) orelse (Pos2 > 0 andalso Pos2 > 0))
          andalso length(GoodsStatus#goods_status.null_cells) < 2 ->
            {fail, 7};
        (Pos1 > 0 andalso Pos2 > 0 andalso Pos3 > 0) andalso length(GoodsStatus#goods_status.null_cells) < 3 ->
            {fail, 7};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 9};
        true ->
            if
                Pos1 > 0 andalso RuneId1 > 0 ->
                    case check_backup_stone(Pos1, GoodsInfo, PlayerStatus, RuneId1, GoodsStatus) of
                        {fail, Res} ->
                            {fail, Res};
                        {ok, Cost1, RuneInfo1} ->
                            if
                                Pos2 > 0 andalso RuneId2 > 0 ->
                                    case check_backup_stone(Pos2, GoodsInfo, PlayerStatus, RuneId2, GoodsStatus) of
                                        {fail, Res2} ->
                                            {fail, Res2};
                                        {ok, Cost2, RuneInfo2} ->
                                            if
                                                (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Cost1 + Cost2 ->
                                                    {fail, 6};
                                                true ->
                                                    if
                                                        Pos3 > 0 andalso RuneId3 > 0 ->
                                                            case check_backup_stone(Pos3, GoodsInfo, PlayerStatus, RuneId3, GoodsStatus) of
                                                                {fail, Res3} ->
                                                                    {fail, Res3};
                                                                {ok, Cost3, RuneInfo3} ->
                                                                    if
                                                                        (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Cost1 + Cost2 +Cost3 ->
                                                                            {fail, 6};
                                                                        true ->
                                                                            {ok, GoodsInfo, Pos1, Pos2, Pos3, RuneInfo1, RuneInfo2, RuneInfo3}
                                                                    end
                                                            end;
                                                        true ->
                                                            {ok, GoodsInfo, Pos1, Pos2, 0, RuneInfo1, RuneInfo2, []}
                                                    end
                                            end
                                    end;
                                true ->
                                    {ok, GoodsInfo, Pos1, 0, 0, RuneInfo1, [], []}
                            end
                    end;
                true ->
                    {fail, 12}
            end
    end.
%% 检查石头和符
check_backup_stone(Pos, GoodsInfo, PlayerStatus, RuneId, GoodsStatus) ->
    Cost = data_goods:count_backout_cost(GoodsInfo),
    StoneTypeId = lib_goods_util:get_inlay_goods(GoodsInfo, Pos),
    if  %% 玩家铜钱不足
        (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Cost ->
            {fail, 6};
        %% 没有宝石可拆
        StoneTypeId =:= 0 ->
            {fail, 8};
        true ->
            StoneInfo = data_goods_type:get(StoneTypeId),
            if
                %% 物品不存在
                is_record(StoneInfo, ets_goods_type) =:= false ->
                    {fail, 2};
                true ->
                    case check_backout_rune(RuneId, GoodsInfo, StoneInfo#ets_goods_type.color, GoodsStatus) of
                        {fail, Res} ->
                            {fail, Res};
                        {ok, RuneInfo} ->
                            {ok, Cost, RuneInfo}
                    end
            end
    end.

%% 处理拆除符
check_backout_rune(RuneId, GoodsInfo, Color, GoodsStatus) ->
    RuneInfo = lib_goods_util:get_goods(RuneId, GoodsStatus#goods_status.dict),
    if  %% 物品不存在
        is_record(RuneInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        RuneInfo#goods.player_id =/= GoodsInfo#goods.player_id ->
            {fail, 3};
        %% 物品位置不正确
        RuneInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        RuneInfo#goods.type =/= 12 andalso RuneInfo#goods.subtype =/= 17 ->
            {fail, 5};
        %% 物品数量不正确
        RuneInfo#goods.color < Color ->
            {fail, 5};
        %% 物品数量不正确
        RuneInfo#goods.num < 1 ->
            {fail, 11};
        true ->
            {ok, RuneInfo}
    end.

%% 炼炉检查
check_forge(PlayerStatus, GoodsStatus, Id, Num, Flag) ->
    ForgeInfo = data_forge:get(Id),
    Sell = PlayerStatus#player_status.sell,
    if  %% 配方不存在
        is_record(ForgeInfo, ets_forge) =:= false ->
            {fail, 2};
        %% 物品数量不正确
        Num < 1 orelse Num > 1000 ->
            {fail, 6};
        %% 金额不足
        (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < (ForgeInfo#ets_forge.coin * Num) ->
            {fail, 3};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 5};
        true ->
            case lib_goods_check:list_handle(fun check_forge_goods/2, [PlayerStatus, Num, Flag, GoodsStatus], ForgeInfo#ets_forge.raw_goods) of
                {fail, Res} -> {fail, Res};
                {ok, _} ->
                    case data_goods_type:get(ForgeInfo#ets_forge.goods_id) of
                        %% 物品类型不存在
                        [] -> {fail, 2};
                        GoodsTypeInfo -> 
                            CellNum = lib_storage_util:get_null_storage_num(0, Num, GoodsTypeInfo#ets_goods_type.max_overlap),
                            case length(GoodsStatus#goods_status.null_cells) < CellNum of
                                %% 背包空间不足
                                true -> 
                                    {fail, 4};
                                false -> 
                                    {ok, ForgeInfo, GoodsTypeInfo}
                            end
                    end
            end
    end.
check_forge_goods({GoodsTypeId, GoodsNum}, [PlayerStatus, Num, Flag, GoodsStatus]) ->
    GoodsTypeList = case Flag of
                        1 -> lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id, GoodsTypeId, 0, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict);
                        2 -> lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id, GoodsTypeId, 2, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict);
                        _ -> lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id, GoodsTypeId, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict)
                    end,
    TotalNum = lib_goods_util:get_goods_totalnum(GoodsTypeList),
    case TotalNum >= (GoodsNum * Num) of
        false -> 
            {fail, 6};
        true -> 
            {ok, [PlayerStatus, Num, Flag, GoodsStatus]}
    end.

check_token_renewal(PlayerStatus, GoodsStatus, GoodsId, Days) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    NowTime = util:unixtime(),
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};    
        %% 物品类型不正确
        GoodsInfo#goods.type =/= 10 andalso GoodsInfo#goods.subtype =/= 80 ->
            {fail, 4};
        %% 物品数量不正确
        GoodsInfo#goods.num < 1 ->
            {fail, 5};
        %% 未到期
        GoodsInfo#goods.expire_time > NowTime ->
            {fail, 6};
        true ->
            %io:format("111 ~p~n", [{PlayerStatus#player_status.career, GoodsInfo#goods.goods_id}]),
            TokenInfo = data_token:get_token_inof(PlayerStatus#player_status.career, GoodsInfo#goods.goods_id),
            GoodsNum = mod_other_call:get_goods_num(PlayerStatus, 523501, GoodsStatus),
            
            if
                 is_record(TokenInfo, kf_token) =:= false ->
                     {fail, 7};
                 true ->
                     NeedNum = util:ceil(TokenInfo#kf_token.num/TokenInfo#kf_token.days) * Days,
                     %io:format("NeedNum = ~p~n", [NeedNum]),
                     if
                         %% 数量不足
                         GoodsNum < NeedNum ->
                             {fail, 8};
                         true ->
                             {ok, GoodsInfo, NeedNum}
                     end
             end
     end.

 %% 升级
check_token_upgrade(PlayerStatus, GoodsStatus, GoodsId) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    NowTime = util:unixtime(),
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};    
        %% 物品类型不正确
        GoodsInfo#goods.type =/= 10 andalso GoodsInfo#goods.subtype =/= 80 ->
            {fail, 4};
        %% 物品数量不正确
        GoodsInfo#goods.num < 1 ->
            {fail, 5};
        %% 过期
        GoodsInfo#goods.expire_time =< NowTime ->
            {fail, 6};
        true ->
            TokenInfo1 = data_token:get_token_inof(PlayerStatus#player_status.career, GoodsInfo#goods.goods_id),
            %io:format("111 ~p~n", [{PlayerStatus#player_status.career, GoodsInfo#goods.goods_id}]),
            GoodsNum = mod_other_call:get_goods_num(PlayerStatus, 523501, GoodsStatus),
            
            if
                 is_record(TokenInfo1, kf_token) =:= false ->
                     {fail, 7};
                 true ->
                     TokenInfo = data_token:get_token_inof(PlayerStatus#player_status.career, TokenInfo1#kf_token.next_id),
                     if
                         is_record(TokenInfo, kf_token) =:= false ->
                            {fail, 7};
                        true ->
                            GoodsTypeInfo = data_goods_type:get(TokenInfo#kf_token.token_id),
                            Day = util:ceil((GoodsInfo#goods.expire_time-NowTime)/86400),
                            NeedNum = util:ceil(TokenInfo#kf_token.num*Day/TokenInfo#kf_token.days),
                            %io:format("upgrade = ~p~n", [{Day, NeedNum, GoodsNum}]),
                            if
                                %% 数量不足
                                GoodsNum < NeedNum ->
                                    {fail, 8};
                                %% 跨服声望不足
                                PlayerStatus#player_status.kf_1v1#status_kf_1v1.pt < TokenInfo#kf_token.pt ->
                                    {fail, 9};
                                GoodsTypeInfo =:= [] ->
                                    {fail, 11};
                                true ->
                                    {ok, GoodsInfo, NeedNum, TokenInfo}
                            end
                     end
             end
     end.

check_change_sex_bag(PlayerStatus, GoodsStatus, GoodsId, EquipId) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    EquipInfo = lib_goods_util:get_goods(EquipId, GoodsStatus#goods_status.dict),
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false orelse is_record(EquipInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id orelse EquipInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};    
        %% 物品类型不正确
        (GoodsInfo#goods.type =/= 61 orelse GoodsInfo#goods.subtype =/= 26) orelse (EquipInfo#goods.type =/= 10 orelse EquipInfo#goods.subtype =/= 10) ->
            {fail, 4};
        %% 物品数量不正确
        GoodsInfo#goods.num < 1 orelse EquipInfo#goods.num < 1 ->
            {fail, 5};
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG orelse EquipInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 6};
        true ->
            {ok, GoodsInfo, EquipInfo}
    end.
     


