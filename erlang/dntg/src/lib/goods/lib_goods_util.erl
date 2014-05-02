%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-13
%% Description: 物品实用工具类
%% --------------------------------------------------------
-module(lib_goods_util).
-compile(export_all).
-include("common.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("server.hrl").
-include("sell.hrl").
-include("sql_player.hrl").
-include("fashion.hrl").

%% 获取背包空位
get_null_cells(_PlayerId, CellNum, GoodsDict) ->
    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.location =:= ?GOODS_LOC_BAG end, GoodsDict),
    DictList = dict:to_list(Dict1),
    List = lib_goods_dict:get_list(DictList, []),
    Cells = lists:map(fun(GoodsInfo) -> [GoodsInfo#goods.cell] end, List),
    AllCells = lists:seq(1, CellNum),
    NullCells = lists:filter(fun(X) -> not(lists:member([X], Cells)) end, AllCells),
    NullCells.

%% NPC已领取礼包列表
get_gift_got_list(PlayerId) ->
    Sql = io_lib:format(?SQL_GIFT_QUEUE_SELECT_GOT, [PlayerId]),
    List = db:get_all(Sql),
    [GiftId || [GiftId] <- List].

%% 取装备列表
get_equip_list(PlayerId, Dict) ->
    EquipList = get_equip_list(PlayerId, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, Dict),
    MountList = get_equip_list(PlayerId, ?GOODS_TYPE_MOUNT, ?GOODS_LOC_EQUIP, Dict),
    EquipList ++ MountList.

%% 套装
get_equip_suit(EquipList) ->
    F = fun(GoodsInfo, EquipSuit) -> 
				add_equip_suit(EquipSuit, GoodsInfo#goods.suit_id) end,
    lists:foldl(F, [], EquipList).

%% 取全身发光的强化数
get_stren7_num_from_list(EquipList) ->
	Stren7List = [Info || Info <- EquipList, Info#goods.location =:= ?GOODS_LOC_EQUIP, Info#goods.stren >= ?EQUIP_SHINE_STREN, Info#goods.subtype =/= 60, Info#goods.subtype =/= 61, Info#goods.subtype =/= 62, Info#goods.subtype =/= 63, Info#goods.subtype =/= 64, Info#goods.subtype =/= 65],
	lists:foldl(fun lib_goods:add_stren7_num/2, 111111111111, Stren7List).

%% 当前装备
get_current_equip_by_list(GoodsList, [CurrentEquip, Type]) ->
	lists:foldl(fun get_current_equip_by_info/2, [CurrentEquip, Type], GoodsList).
  
%% 物品信息
get_goods_info(GoodsId, Dict) ->
    case Dict =/= [] of
        true ->
            Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.id =:= GoodsId end, Dict),
            DictList = dict:to_list(Dict1),
            List = lib_goods_dict:get_list(DictList, []);
        false ->
            List = []
    end,
%%     io:format("DictList = ~p, List = ~p, GoodsId = ~p~n", [DictList, List, GoodsId]),
    case List =:= [] of
        true ->
            _GoodsInfo = get_goods_by_id(GoodsId),
            _GoodsInfo;
        false ->
            [GoodsInfo|_] = List,
            GoodsInfo
    end.

get_goods_by_id(GoodsId) ->
	Sql = io_lib:format(?SQL_GOODS_SELECT_BY_ID, [GoodsId]),
	Info = db:get_row(Sql),
	case make_info(goods, Info) of
		[] ->
			[];
		[GoodsInfo] ->
			GoodsInfo
	end.

%%     %% 查 goods 表
%%     SqlGoods = io_lib:format(?SQL_SELECT_GOODS_BY_ID, [GoodsId]),
%%     [Player_id, Type, Subtype, Price_type, Price, Sell_price, Vitality, Spirit, Hp, Mp, 
%%      Forza, Agile, Wit, Att, Def, Hit, Dodge, Crit, Ten, Speed, Suit_id, Skill_id, Expire_time] = db:get_row(SqlGoods),
%%     io:format("9999~n"),
%%     %% 查 goods_low 表
%%     SqlLow = io_lib:format(?SQL_SELECT_GOODS_LOW_BY_ID, [GoodsId]),
%%     [Equip_type, Bind, Trade, Sell, Isdrop, Level, Quality, Quality_his, Quality_factor, Star, Stren, 
%%      Stren_ratio, Stren_his, Stren_fail, Hole, Hole1_goods, Hole2_goods, Hole3_goods, Addition, Wash, 
%%      Soul, Color, Prefix, Note] = db:get_row(SqlLow),
%%     io:format("000000~n"),
%%     %% goods_high
%%     SqlHigh = io_lib:format(?SQL_SELECT_GOODS_High_BY_ID, [GoodsId]),
%%     [Guild_id, Goods_id, Attrition, Use_num, Location, Cell, Num] = db:get_row(SqlHigh),
%%     io:format("aaaaaa~n"),
%%     Info = [GoodsId, Player_id, Guild_id, Goods_id, Type, Subtype, Equip_type, Price_type, Price,
%%             Sell_price, Bind, Trade, Sell, Isdrop, Level, Vitality, Spirit, Hp, Mp, Forza, Agile, Wit, Att,
%%             Def, Hit, Dodge, Crit, Ten, Speed, Attrition, Use_num, Suit_id, Skill_id, Quality, Quality_his, 
%%             Quality_factor, Star, Stren, Stren_ratio, Stren_his, Stren_fail, Hole, Hole1_goods, Hole2_goods, 
%%             Hole3_goods, Addition, Wash, Soul,Location, Cell, Num, Color, Expire_time, Prefix, Note],
%%     case make_info(goods, Info) of
%%         [] ->
%%             [];
%%         [GoodsInfo] ->
%%             GoodsInfo
%%     end.
    

%% 验证物品信息
make_info(Table, Info) ->
    case Table of
        goods when Info =/= [] ->
            [Id, Player_id, Guild_id, Goods_id, Type, Subtype, Equip_type, Price_type, Price,
            Sell_price, Bind, Trade, Sell, Isdrop, Level, Vitality, Spirit, Hp, Mp, Forza, Agile, Wit, Att,
            Def, Hit, Dodge, Crit, Ten, Speed, Attrition, Use_num, Suit_id, Skill_id,
            Stren, Stren_ratio, Hole, Hole1_goods, Hole2_goods, Hole3_goods, Addition1, Addition2,Addition3, 
            Location, Cell, Num, Color, Expire_time, FirstPrefix, Prefix, Min_star, Wash_time, Note, Ice, Fire, Drug] = Info,
            [#goods{ id=Id, player_id=Player_id, guild_id=Guild_id, goods_id=Goods_id, type=Type, subtype=Subtype,
                   equip_type=Equip_type, price_type=Price_type, price=Price, sell_price=Sell_price,
                   bind=Bind, trade=Trade, sell=Sell, isdrop=Isdrop, level=Level, vitality=Vitality, spirit=Spirit,
                   hp=Hp, mp=Mp, forza=Forza, agile=Agile, wit=Wit, att=Att, def=Def, hit=Hit, dodge=Dodge,
                   crit=Crit, ten=Ten, speed=Speed, attrition=Attrition, use_num=Use_num, suit_id=Suit_id, skill_id=Skill_id, stren=Stren,
                   stren_ratio=Stren_ratio, hole=Hole, hole1_goods=Hole1_goods, 
                   hole2_goods=Hole2_goods,hole3_goods=Hole3_goods, addition_1=to_term(Addition1), addition_2 = to_term(Addition2), addition_3 = to_term(Addition3),
                   location=Location, cell=Cell, num=Num, color=Color, expire_time=Expire_time, first_prefix=FirstPrefix, prefix=Prefix, 
                   min_star=Min_star, wash_time=Wash_time, note=Note, ice=Ice, fire=Fire, drug=Drug}];
        _ -> []
    end.

transaction(F) ->
	db:transaction(F, fun lib_goods_dict:close_dict/0).

deeploop(F, N, Data) ->
	case N > 0 of
		true ->
			[N1, Data1] = F(N, Data),
			deeploop(F, N1, Data1);
		false ->
			Data
	end.

%% 套装件数
get_suit_num(EquipSuit, SuitId) ->
	case SuitId > 0 of
		true ->
			case lists:keyfind(SuitId, 1, EquipSuit) of
				false -> 0;
				{SuitId, SuitNum} ->
					SuitNum
			end;
		false ->
			0
	end.

%% 通过物品信息得到物品
get_new_goods(GoodsTypeInfo) ->
	if GoodsTypeInfo#ets_goods_type.type =/= ?GOODS_TYPE_PET andalso GoodsTypeInfo#ets_goods_type.expire_time > 0 ->
            case GoodsTypeInfo#ets_goods_type.expire_time > 1200000000 of
                true -> ExpireTime = GoodsTypeInfo#ets_goods_type.expire_time;
                false -> ExpireTime = util:unixtime() + GoodsTypeInfo#ets_goods_type.expire_time
            end;
        true -> ExpireTime = 0
    end,
	#goods{
		goods_id = GoodsTypeInfo#ets_goods_type.goods_id,
        type = GoodsTypeInfo#ets_goods_type.type,
        subtype = GoodsTypeInfo#ets_goods_type.subtype,
        equip_type = GoodsTypeInfo#ets_goods_type.equip_type,
        price_type = GoodsTypeInfo#ets_goods_type.price_type,
        price = GoodsTypeInfo#ets_goods_type.price,
        sell_price = GoodsTypeInfo#ets_goods_type.sell_price,
        bind = GoodsTypeInfo#ets_goods_type.bind,
        trade = GoodsTypeInfo#ets_goods_type.trade,
        sell = GoodsTypeInfo#ets_goods_type.sell,
        isdrop = GoodsTypeInfo#ets_goods_type.isdrop,
        level = GoodsTypeInfo#ets_goods_type.level,
        vitality = GoodsTypeInfo#ets_goods_type.vitality,
        spirit = GoodsTypeInfo#ets_goods_type.spirit,
        hp = GoodsTypeInfo#ets_goods_type.hp,
        mp = GoodsTypeInfo#ets_goods_type.mp,
        forza = GoodsTypeInfo#ets_goods_type.forza,
        agile = GoodsTypeInfo#ets_goods_type.agile,
        wit = GoodsTypeInfo#ets_goods_type.wit,
        att = GoodsTypeInfo#ets_goods_type.att,
        def = GoodsTypeInfo#ets_goods_type.def,
        hit = GoodsTypeInfo#ets_goods_type.hit,
        dodge = GoodsTypeInfo#ets_goods_type.dodge,
        crit = GoodsTypeInfo#ets_goods_type.crit,
        ten = GoodsTypeInfo#ets_goods_type.ten,
        speed = GoodsTypeInfo#ets_goods_type.speed,
        attrition = GoodsTypeInfo#ets_goods_type.attrition,
        use_num = data_goods:count_goods_use_num(GoodsTypeInfo#ets_goods_type.equip_type, GoodsTypeInfo#ets_goods_type.attrition),
        suit_id = GoodsTypeInfo#ets_goods_type.suit_id,
        skill_id = GoodsTypeInfo#ets_goods_type.skill_id,
        color = GoodsTypeInfo#ets_goods_type.color,
        addition_1 = GoodsTypeInfo#ets_goods_type.addition,
        expire_time = ExpireTime,
        ice = GoodsTypeInfo#ets_goods_type.ice,
        fire = GoodsTypeInfo#ets_goods_type.fire,
        drug = GoodsTypeInfo#ets_goods_type.drug
	 }.
  
%% 读取物品
get_goods(GoodsId, Dict) ->
    case GoodsId > 0 andalso dict:is_key(GoodsId, Dict) of
        true ->
            List = dict:fetch(GoodsId, Dict),
            case List =:= [] of
                true ->
                    [];
                false ->
                    [GoodsInfo|_] = List,
                    GoodsInfo
            end;
        false ->
            []
    end.

%% 取物品列表
get_goods_list(PlayerId, Pos, Dict) ->
	case lib_goods:is_cache(Pos) of
		true ->
            Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.location =:= Pos end, Dict),
            DictList = dict:to_list(Dict1),
            lib_goods_dict:get_list(DictList, []);
		false ->
			Sql = io_lib:format(?SQL_GOODS_LIST_BY_LOCATION, [PlayerId, Pos]),
			get_list(goods, Sql)
	end.

%% 取需修理装备列表
get_mend_list(PlayerId, Dict) ->
	L1 = get_equip_list(PlayerId, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, Dict),
	L2 = get_equip_list(PlayerId, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_BAG, Dict),
	F = fun(GoodsInfo) ->
				case GoodsInfo#goods.attrition =:= 0 of
					true ->
						[];
					false ->
						UseNum = data_goods:count_goods_use_num(GoodsInfo#goods.equip_type,
															GoodsInfo#goods.attrition),
						case UseNum =/= GoodsInfo#goods.use_num of
							true ->
								[GoodsInfo];
							false ->
								[]
						end
				end
		end,
	lists:flatmap(F, L1++L2).

%% 获取同类物品列表
get_type_goods_list(PlayerId, GoodsTypeId, Bind, Location, Dict) ->
	case lib_goods:is_cache(Location) of
		true ->
            Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.location =:= Location 
                                andalso Value#goods.goods_id =:= GoodsTypeId andalso Value#goods.bind =:= Bind end, Dict),
            DictList = dict:to_list(Dict1),
            lib_goods_dict:get_list(DictList, []);
		false -> %%仓库
			Sql = io_lib:format(?SQL_GOODS_LIST_BY_TYPE1, [PlayerId, ?GOODS_LOC_STORAGE, GoodsTypeId, Bind]),
			get_list(goods, Sql)
	end.
get_type_goods_list(PlayerId, GoodsTypeId, Location, Dict) ->
    case lib_goods:is_cache(Location) of
        true ->
            Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.location =:= Location 
                                andalso Value#goods.goods_id =:= GoodsTypeId end, Dict),
            DictList = dict:to_list(Dict1),
            lib_goods_dict:get_list(DictList, []);
        false -> %% 仓库
            Sql = io_lib:format(?SQL_GOODS_LIST_BY_TYPE2, [PlayerId, Location, GoodsTypeId]),
            get_list(goods, Sql)
    end.

%% 取物品总数
get_goods_totalnum(GoodsList) ->
    lists:foldl(fun(X, Sum) -> X#goods.num + Sum end, 0, GoodsList).

%% 镶嵌数
get_inlay_num(GoodsInfo) ->
	length([Id || Id <- [GoodsInfo#goods.hole1_goods, GoodsInfo#goods.hole2_goods, GoodsInfo#goods.hole3_goods], Id > 0]).

%% 取镶嵌位置的镶嵌物品类型Id
get_inlay_goods(GoodsInfo, Pos) ->
    case Pos of
        1 -> GoodsInfo#goods.hole1_goods;
        2 -> GoodsInfo#goods.hole2_goods;
        3 -> GoodsInfo#goods.hole3_goods;
        _ -> 0
    end.
	
%% 获取身上时装信息
get_equip_fashion(_RoleId, FashionType, Dict) ->
    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.location =:= ?GOODS_LOC_EQUIP 
                                andalso Value#goods.type =:= ?GOODS_TYPE_EQUIP andalso Value#goods.subtype =:= FashionType end, Dict),
    DictList = dict:to_list(Dict1),
    List = lib_goods_dict:get_list(DictList, []),
    case List =:= [] of
        true ->
            [0,0];
        false ->
            [Info|_] = List,
            [Info#goods.goods_id,Info#goods.stren]
    end.

get_list_by_subtype(Type, SubType, Dict) ->
    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.type =:= Type andalso Value#goods.subtype =:= SubType end, Dict),
    DictList = dict:to_list(Dict1),
    lib_goods_dict:get_list(DictList, []).

get_list_by_type(Type, Dict) ->
    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.type =:= Type end, Dict),
    DictList = dict:to_list(Dict1),
    lib_goods_dict:get_list(DictList, []).

get_goods_by_cell(_PlayerId, Location, Cell, Dict) ->
    case Dict =/= [] of
        true ->
            Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.location =:= Location andalso Value#goods.cell =:= Cell end, Dict),
            DictList = dict:to_list(Dict1),
            List = lib_goods_dict:get_list(DictList, []),
            case List =/= [] of
                true ->
                    [GoodsInfo|_] = List,
                    GoodsInfo;
                false ->
                    []
            end;
        false ->
            []
    end.

get_goods_by_type(_PlayerId, GoodsTypeId, Location, Dict) ->
    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.location =:= Location andalso Value#goods.goods_id =:= GoodsTypeId end, Dict),
    DictList = dict:to_list(Dict1),
    List = lib_goods_dict:get_list(DictList, []),
    case List =/= [] of
        true ->
            [GoodsInfo|_] = List,
            GoodsInfo;
        false ->
            []
    end.

%% 修改套装
change_equip_suit(EquipSuit, OldSuit, NewSuit) ->
	EquipSuit1 = del_equip_suit(EquipSuit, OldSuit),
	EquipSuit2 = add_equip_suit(EquipSuit1, NewSuit),
	EquipSuit2.

del_equip_suit(EquipSuit, SuitId) ->
	if SuitId > 0 ->
		 case lists:keyfind(SuitId, 1, EquipSuit) of
			 false ->
				 EquipSuit;
			 [SuitId, SuitNum] when SuitNum > 0 ->
				 lists:keyreplace(SuitId, 1, EquipSuit, {SuitId, SuitNum - 1});
			 {SuitId, _} ->
				 lists:keydelete(SuitId, 1, EquipSuit)
		 end;
	   true ->
		   EquipSuit
	end.

add_equip_suit(EquipSuit, SuitId) ->
	if SuitId > 0 ->
		   case lists:keyfind(SuitId, 1, EquipSuit) of
			   false ->
				   [{SuitId, 1}|EquipSuit];
			   {SuitId, SuitNum} ->
				   lists:keyreplace(SuitId, 1, EquipSuit, {SuitId, SuitNum + 1})
		   end;
	   true ->
		   EquipSuit
   end.
						  
%% 取装备全套套装的ID
get_full_suit([{SuitId, SuitNum}|T]) ->
	Suit = data_suit:get_belong(SuitId),
    case Suit =/= [] of
        true ->
            Max = Suit#suit_belong.max,
	       if Max > 3 andalso Max =:= SuitNum ->
		          SuitId;
	           true ->
		          get_full_suit(T)
            end;
        false ->
            get_full_suit(T)
	end;

get_full_suit([]) ->
	0.

%% 人物装备属性重新计算
count_role_equip_attribute(PlayerStatus, GoodsStatus) ->
	%% 装备属性
	EquipAffect = get_equip_affect(PlayerStatus, GoodsStatus#goods_status.stren7_num, GoodsStatus#goods_status.dict),
	%% 更新人物属性
    G = PlayerStatus#player_status.goods,
	PlayerStatus1 = PlayerStatus#player_status{
					goods = G#status_goods{equip_current = GoodsStatus#goods_status.equip_current,
					suit_id = GoodsStatus#goods_status.suit_id,
					stren7_num = GoodsStatus#goods_status.stren7_num,
					equip_attribute = EquipAffect}
				},
    %% 装备的技能汇总
    PlayerStatus2 = get_medal_skill(PlayerStatus1, GoodsStatus#goods_status.dict),
	NewPlayerStatus = lib_player:count_player_attribute(PlayerStatus2),
	{ok, NewPlayerStatus}.

%% @spec get_medal_skill(#player_status{}=Status, Dict) -> NewStatus
%% 取勋章技能加成
%% @end
get_medal_skill(#player_status{id=PlayerId} = Status, Dict) -> 
    GoodsList = get_equip_list(PlayerId, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, Dict),
    EquipList = filter_equip_list(GoodsList, [], []),
    GoodsTypeIdList = [GoodsInfo#goods.goods_id || GoodsInfo <- EquipList],
    lib_skill:goods_skill(Status, GoodsTypeIdList).

%% @spec get_medal_skill_online(#player_status{}=Status, Dict) -> NewStatus
%% 上线时取勋章技能加成（是否过期判断）
%% @end
get_medal_skill_online(#player_status{id=PlayerId} = Status, Dict) -> 
    NowTime = util:unixtime(),
    GoodsList = get_equip_list(PlayerId, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, Dict),
    EquipList = filter_equip_list(GoodsList, [], []),
    GoodsTypeIdList = [GoodsInfo#goods.goods_id || GoodsInfo <- EquipList, (GoodsInfo#goods.expire_time =:= 0 orelse GoodsInfo#goods.expire_time > NowTime)],
    lib_skill:goods_skill(Status, GoodsTypeIdList).

%% 取装备的属性加成
get_equip_affect(PS, Stren7_num, Dict) ->
	GoodsList = get_equip_list(PS#player_status.id, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, Dict),
	EquipList = filter_equip_list(GoodsList, [], []),
	% 装备属性加成
    GoodsEffect = [data_goods:count_goods_effect(GoodsInfo) || GoodsInfo <- EquipList],
    Effect1 = data_goods:sum_effect(GoodsEffect),
	%% 装备套装属性加成
    EquipSuit = get_equip_suit(EquipList),
	Effect2 = data_goods:count_suit_effect(EquipSuit),
	%% 全身发光属性加成
    MinLevel = case get_level_list([], EquipList) of
        [] ->
            0;
        List ->
            lists:min(List)
    end,
    Effect3 = data_goods:count_shine_effect(MinLevel, Stren7_num),
    %% 时装套装
    if
        PS#player_status.wardrobe =/= [] ->
            List2 = dict:fetch_keys(PS#player_status.wardrobe);
        true ->
            List2 = []
    end,
    [{N1,N2,N3,N4,N5,N6}] = cacul_fashion_num(List2, [{0,0,0,0,0,0}]),
    Effect4 = data_goods:count_fashion_effect(90001, N1),
    Effect5 = data_goods:count_fashion_effect(90002, N2),
    Effect6 = data_goods:count_fashion_effect(90003, N3),
    Effect7 = data_goods:count_fashion_effect(90004, N4),
    Effect8 = data_goods:count_fashion_effect(90005, N5),
    Effect9 = data_goods:count_fashion_effect(90006, N6),
	data_goods:sum_effect([Effect1, Effect2, Effect3, Effect4,Effect5,Effect6,Effect7,Effect8,Effect9]).

   
%% 套装数量
cacul_fashion_num([], L) ->
    L;
cacul_fashion_num([GoodsId|H], [{N1,N2,N3,N4,N5,N6}]) ->
    List1 = data_fashion_change:get_fashion_list(1),
    List2 = data_fashion_change:get_fashion_list(2),
    List3 = data_fashion_change:get_fashion_list(3),
    List4 = data_fashion_change:get_fashion_list(4),
    List5 = data_fashion_change:get_fashion_list(5),
    List6 = data_fashion_change:get_fashion_list(6),
    L1 = lists:member(GoodsId, List1),
    L2 = lists:member(GoodsId, List2),
    L3 = lists:member(GoodsId, List3),
    L4 = lists:member(GoodsId, List4),
    L5 = lists:member(GoodsId, List5),
    L6 = lists:member(GoodsId, List6),
    %L1 = lists:member(GoodsId, ?FASHION_ONE),
    %L2 = lists:member(GoodsId, ?FASHION_TWO),
    %L3 = lists:member(GoodsId, ?FASHION_THREE),
    %L4 = lists:member(GoodsId, ?FASHION_FOUR),
    %L5 = lists:member(GoodsId, ?FASHION_FINE),
    %L6 = lists:member(GoodsId, ?FASHION_SIX),
    if
        L1 =:= true ->
            cacul_fashion_num(H, [{N1+1,N2,N3,N4,N5,N6}]);
        L2 =:= true ->
            cacul_fashion_num(H, [{N1,N2+1,N3,N4,N5,N6}]);
        L3 =:= true ->
            cacul_fashion_num(H, [{N1,N2,N3+1,N4,N5,N6}]);
        L4 =:= true ->
            cacul_fashion_num(H, [{N1,N2,N3,N4+1,N5,N6}]);
        L5 =:= true ->
            cacul_fashion_num(H, [{N1,N2,N3,N4,N5+1,N6}]);
        L6 =:= true ->
            cacul_fashion_num(H, [{N1,N2,N3,N4,N5,N6+1}]);
        true ->
            cacul_fashion_num(H, [{N1,N2,N3,N4,N5,N6}])
    end.       

filter_equip_list([], _, L) -> L;
filter_equip_list([G|T], FL, L) ->
    case lists:member(G#goods.cell, FL) of
        false -> 
            NewFL = [G#goods.cell|FL],
            case G#goods.attrition =:= 0 orelse G#goods.use_num > 0 of
                true -> 
					filter_equip_list(T, NewFL, [G|L]);
                false -> 
					filter_equip_list(T, NewFL, L)
            end;
        true -> 
			filter_equip_list(T, FL, L)
    end.

%% 取套装id和件数
get_suit_id_and_num(PlayerId, Dict) ->
    GoodsList = get_equip_list(PlayerId, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, Dict),
    EquipList = filter_equip_list(GoodsList, [], []),
    EquipSuit = get_equip_suit(EquipList),
    BelongList = data_goods:get_suit_belong(EquipSuit, []),
    %% 非人民币套装
    List1 = [{Id, Num, Level, Series} || {Id, Num, Level, Series} <- BelongList, Series =:= 1],
    %% 人民币套装
    List2 = [{Id, Num, Level, Series} || {Id, Num, Level, Series} <- BelongList, Series =:= 2],
    %% 武器套装
    List3 = [{Id, Num, Level, Series} || {Id, Num, Level, Series} <- BelongList, Series =:= 3],
    case List1 =/= [] of
        true -> %%取最小等级
            [F|Rest1] = List1,
            {SuitId1, _, _, _, Num1} = data_goods:get_min_level_suit(Rest1, F, 0);
        false ->
            {SuitId1, Num1} = {0, 0}
    end,    
    case List2 =/= [] of
        true -> %%取最小等级
            [S|Rest2] = List2,
            {SuitId2, _, _, _, Num2} = data_goods:get_min_level_suit(Rest2, S, 0);
        false ->
            {SuitId2, Num2} = {0, 0}
    end,
    case List3 =/= [] of
        true -> %%取最小等级
            [R|Rest3] = List3,
            {SuitId3, _, _, _, Num3} = data_goods:get_min_level_suit(Rest3, R, 0);
        false ->
            {SuitId3, Num3} = {0, 0}
    end,
    [{SuitId1, Num1}, {SuitId2, Num2}, {SuitId3, Num3}].
        
%% 取装备的等级列表
get_level_list(L, []) ->
    L;
get_level_list(L, [GoodsInfo|H])  ->
    case is_record(GoodsInfo, goods) andalso GoodsInfo#goods.subtype =/= ?GOODS_FASHION_ARMOR andalso GoodsInfo#goods.subtype =/= ?GOODS_FASHION_WEAPON andalso GoodsInfo#goods.subtype =/= ?GOODS_FASHION_ACCESSORY andalso GoodsInfo#goods.subtype =/= ?GOODS_SUBTYPE_WEDDING_RING andalso GoodsInfo#goods.subtype =/= 80 andalso GoodsInfo#goods.subtype =/=?GOODS_FASHION_HEAD andalso GoodsInfo#goods.subtype =/=?GOODS_FASHION_TAIL andalso GoodsInfo#goods.subtype =/=?GOODS_FASHION_RING of
        true ->
            get_level_list([GoodsInfo#goods.level|L], H);
        false ->
            get_level_list(L, H)
    end.

change_goods_cell_and_use(GoodsInfo, Location, Cell, UseNum) ->
    Sql = io_lib:format(?SQL_GOODS_UPDATE_CELL_USENUM, [Location, Cell, UseNum, GoodsInfo#goods.id]),
    db:execute(Sql),
    GoodsInfo#goods{location = Location, cell = Cell, use_num = UseNum}.

%% 更改物品格子位置和数量
change_goods_cell_and_num(GoodsInfo, Location, Cell, Num) ->
    Sql = io_lib:format(?SQL_GOODS_UPDATE_CELL_NUM, [Location, Cell, Num, GoodsInfo#goods.id]),
    db:execute(Sql),
    GoodsInfo#goods{location=Location, cell=Cell, num=Num}.

%% 更改物品格子位置
change_goods_cell(GoodsInfo, Location, Cell) ->
    case is_integer(GoodsInfo#goods.id) of
        true ->
            Sql = io_lib:format(?SQL_GOODS_UPDATE_CELL, [Location, Cell, GoodsInfo#goods.id]),
            db:execute(Sql),
            GoodsInfo#goods{location=Location, cell=Cell};
        false ->
            #goods{}
    end.

%%当玩家下线时，更新装备磨损信息
goods_offline(PlayerId, UseNum, Dict) ->
    EquipList = get_equip_list(PlayerId, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, Dict),
    lists:foldl(fun save_goods_use/2, UseNum, EquipList),
    ok.

%% 下线保存耐久
save_goods_use(GoodsInfo, UseNum) ->
    case GoodsInfo#goods.attrition > 0 of
        %% 耐久度降为0
        true when GoodsInfo#goods.use_num =< UseNum ->
            change_goods_use(GoodsInfo, 0);
        true ->
            change_goods_use(GoodsInfo, (GoodsInfo#goods.use_num - UseNum));
        false -> 
            skip
    end,
    UseNum.

%% 更改装备品质
change_goods_quality(GoodsInfo, Prefix, Bind, Trade, 1) ->
    Color = change_goods_color_by_first_prefix(GoodsInfo, Prefix),
    Sql = io_lib:format(?SQL_GOODS_UPDATE_QUALITY_FIRST_PREFIX, [Prefix, Color, Bind, Trade, GoodsInfo#goods.id]),
    db:execute(Sql),
    GoodsInfo#goods{first_prefix = Prefix, color = Color, trade = Trade, bind = Bind};
%% 更改装备品质
change_goods_quality(GoodsInfo, Prefix, Bind, Trade, 2) ->
    Sql = io_lib:format(?SQL_GOODS_UPDATE_QUALITY_PREFIX, [Prefix, Bind, Trade, GoodsInfo#goods.id]),
    db:execute(Sql),
    GoodsInfo#goods{prefix = Prefix, trade = Trade, bind = Bind}.

%% 根据进阶前缀确立新颜色
change_goods_color_by_first_prefix(GoodsInfo, Prefix) -> 
    if
        Prefix > 3 -> max(GoodsInfo#goods.color, 4); %% 前缀大于3为橙色
        Prefix > 0 -> max(GoodsInfo#goods.color, 3); %% 前缀大于3为紫色
        true       -> GoodsInfo#goods.color
    end.
            
    
%% 更改装备强化
change_goods_stren(GoodsInfo, Stren, Stren_ratio, Bind, Trade) ->
    Sql = io_lib:format(?SQL_GOODS_UPDATE_STREN, [Stren, Stren_ratio, Bind, Trade, GoodsInfo#goods.id]),
    db:execute(Sql),
    GoodsInfo#goods{stren=Stren, stren_ratio=Stren_ratio, bind=Bind, trade=Trade}.

%% %% 更改物品时效
%% change_goods_expire(GoodsInfo, ExpireTime) ->
%%     Sql = io_lib:format(?SQL_GOODS_UPDATE_EXPIRE, [ExpireTime, GoodsInfo#goods.id]),
%%     db:execute(Sql),
%%     GoodsInfo#goods{expire_time=ExpireTime}.

%% 更改物品类型ID
change_goods_type(GoodsInfo, GoodsTypeId) ->
    GoodsTypeInfo = data_goods_type:get(GoodsTypeId),
    Color = GoodsTypeInfo#ets_goods_type.color,
    Sql1 = io_lib:format(?SQL_GOODS_UPDATE_GOODS1, [GoodsTypeId, GoodsInfo#goods.id]),
    db:execute(Sql1),
    Sql2 = io_lib:format(?SQL_GOODS_UPDATE_GOODS2, [GoodsTypeId, Color, GoodsInfo#goods.id]),
    db:execute(Sql2),
    GoodsInfo#goods{goods_id = GoodsTypeId, color = Color}.

%% 更改时装类型ID
change_fashion_type(GoodsInfo, GoodsTypeId, Bind, Trade) ->
    Sql1 = io_lib:format(?SQL_GOODS_UPDATE_GOODS1, [GoodsTypeId, GoodsInfo#goods.id]),
    db:execute(Sql1),
    Sql2 = io_lib:format(?SQL_GOODS_UPDATE_GOODS3, [GoodsTypeId, Bind, Trade, GoodsInfo#goods.id]),
    db:execute(Sql2),
    GoodsInfo#goods{goods_id = GoodsTypeId, bind = Bind, trade = Trade}.

%% 更改装备孔数
change_goods_hole(GoodsInfo, Hole, Bind, Trade) ->
    Sql = io_lib:format(?SQL_GOODS_UPDATE_HOLE1, [Hole, Bind, Trade, GoodsInfo#goods.id]),
    db:execute(Sql),
    GoodsInfo#goods{hole = Hole, bind = Bind, trade = Trade}.

%% 更改装备孔物品
change_goods_hole2(GoodsInfo, Hole1_goods, Hole2_goods, Hole3_goods, Bind, Trade) ->
    Sql = io_lib:format(?SQL_GOODS_UPDATE_HOLE2, [Hole1_goods, Hole2_goods, Hole3_goods, Bind, Trade, GoodsInfo#goods.id]),
    db:execute(Sql),
    GoodsInfo#goods{hole1_goods=Hole1_goods, hole2_goods=Hole2_goods, hole3_goods=Hole3_goods, bind=Bind, trade=Trade}.

%% 更改玩家
change_goods_player(GoodsInfo, PlayerId, Location, Cell) ->
    Sql1 = io_lib:format(?SQL_GOODS_UPDATE_PLAYER1, [PlayerId, GoodsInfo#goods.id]),
    db:execute(Sql1),
    Sql2 = io_lib:format(?SQL_GOODS_UPDATE_PLAYER2, [PlayerId, GoodsInfo#goods.id]),
    db:execute(Sql2),
    Sql3 = io_lib:format(?SQL_GOODS_UPDATE_PLAYER3, [PlayerId, Location, Cell, GoodsInfo#goods.id]),
    db:execute(Sql3),
    GoodsInfo#goods{player_id = PlayerId, location = Location, cell = Cell}.

%% 更改装备附加属性
change_goods_addition(GoodsInfo, Bind, Trade, Grade) ->
    case Grade of 
        1 ->
            Sql = io_lib:format(?SQL_GOODS_UPDATE_ADDITION_1, [util:term_to_string(GoodsInfo#goods.addition_1), Bind, Trade, GoodsInfo#goods.id]);
        2 ->
            Sql = io_lib:format(?SQL_GOODS_UPDATE_ADDITION_2, [util:term_to_string(GoodsInfo#goods.addition_2), Bind, Trade, GoodsInfo#goods.id]);
        3 ->
            Sql = io_lib:format(?SQL_GOODS_UPDATE_ADDITION_3, [util:term_to_string(GoodsInfo#goods.addition_3), Bind, Trade, GoodsInfo#goods.id])
    end,
    db:execute(Sql),
    GoodsInfo#goods{bind = Bind, trade = Trade}.

%% 更改信息
change_goods_info(GoodsInfo, Bind, Trade) ->
    WashTime = GoodsInfo#goods.wash_time,
    MinStar = GoodsInfo#goods.min_star,
    Sql = io_lib:format(?SQL_GOODS_UPDATE_INFO, [Bind, Trade, WashTime, MinStar, GoodsInfo#goods.id]),
    db:execute(Sql),
    GoodsInfo#goods{bind = Bind, trade = Trade}.

%% 替换洗炼属性
change_goods_addition(GoodsInfo, Grade, AttrList) ->
    case Grade of 
        1 ->
            NewGoodsInfo = GoodsInfo#goods{addition_1 = AttrList},
            Sql = io_lib:format(?SQL_GOODS_UPDATE_ATTR1, [util:term_to_string(AttrList), GoodsInfo#goods.id]);
        2 ->
            NewGoodsInfo = GoodsInfo#goods{addition_2 = AttrList},
            Sql = io_lib:format(?SQL_GOODS_UPDATE_ATTR2, [util:term_to_string(AttrList), GoodsInfo#goods.id]);
        _ ->
            NewGoodsInfo = GoodsInfo#goods{addition_3 = AttrList},
            Sql = io_lib:format(?SQL_GOODS_UPDATE_ATTR3, [util:term_to_string(AttrList), GoodsInfo#goods.id])
    end,
    db:execute(Sql),
    NewGoodsInfo.

%%取多条记录
get_list(Table, Sql) ->
	List = get_list(Sql),
	lists:flatmap(fun(GoodsInfo) -> make_info(Table, GoodsInfo) end, List).

get_list(Sql) ->
	List = (catch db:get_all(Sql)),
	case is_list(List) of
		true ->
			List;
		false ->
			[]
	end.

%% 计算余额够不够 true为充足，false为不足
is_enough_money(PlayerStatus, Cost, Type) ->
	case Type of
        silver_and_gold -> 
            (PlayerStatus#player_status.bgold + PlayerStatus#player_status.gold) >= Cost;
		coin ->     
			(PlayerStatus#player_status.bcoin + PlayerStatus#player_status.coin) >= Cost;
        rcoin ->    
			PlayerStatus#player_status.coin >= Cost;
        silver ->   
			PlayerStatus#player_status.bgold >= Cost;
        gold ->     
			PlayerStatus#player_status.gold >= Cost;
        bcoin ->    
			PlayerStatus#player_status.bcoin >= Cost;
        point ->    
			PlayerStatus#player_status.point >= Cost
    end.

%% 扣除角色金钱
cost_money(PlayerStatus, Cost, point) ->
	NewPlayerStatus = PlayerStatus#player_status{point = (PlayerStatus#player_status.point - Cost)},
	if %% Playeer:玩家,  MoneyError:金钱错误
		NewPlayerStatus#player_status.point < 0 ->
			lists:concat(["Playeer：",NewPlayerStatus#player_status.id," ",", MoneyError：point=", NewPlayerStatus#player_status.point]),
			throw(money_error);
		true ->
			skip
	end,
	Sql = io_lib:format(?SQL_PLAYER_UPDATE_POINT, [NewPlayerStatus#player_status.point, NewPlayerStatus#player_status.id]),
	db:execute(Sql),
	NewPlayerStatus;

cost_money(PlayerStatus, Cost, Type) ->
	case Type of
		coin ->
			case PlayerStatus#player_status.bcoin < Cost of
				false ->
					NewPlayerStatus = PlayerStatus#player_status{bcoin = (PlayerStatus#player_status.bcoin - Cost)};
				true ->
					NewPlayerStatus = PlayerStatus#player_status{bcoin = 0, coin = (PlayerStatus#player_status.bcoin + PlayerStatus#player_status.coin - Cost)}
			end;
		fcoin ->
			case PlayerStatus#player_status.coin < Cost of
				false ->
					NewPlayerStatus = PlayerStatus#player_status{coin = (PlayerStatus#player_status.coin - Cost)};
				true ->
					NewPlayerStatus = PlayerStatus#player_status{coin = 0, bcoin = (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin - Cost)}
			end;
		rcoin ->
			NewPlayerStatus = PlayerStatus#player_status{coin = (PlayerStatus#player_status.coin - Cost)};
		bgold -> 
			case PlayerStatus#player_status.bgold < Cost of
				false ->
					NewPlayerStatus = PlayerStatus#player_status{bgold = (PlayerStatus#player_status.bgold - Cost)};
				true ->
					NewPlayerStatus = PlayerStatus#player_status{bgold = 0, gold = (PlayerStatus#player_status.bgold + PlayerStatus#player_status.gold - Cost)}
			end;
		silver -> NewPlayerStatus = PlayerStatus#player_status{bgold = (PlayerStatus#player_status.bgold - Cost)};
		gold ->   NewPlayerStatus = PlayerStatus#player_status{gold = (PlayerStatus#player_status.gold - Cost)};
		bcoin ->  NewPlayerStatus = PlayerStatus#player_status{bcoin = (PlayerStatus#player_status.bcoin - Cost)};
        silver_and_gold -> 
            case PlayerStatus#player_status.bgold < Cost of
				false ->
					NewPlayerStatus = PlayerStatus#player_status{bgold = (PlayerStatus#player_status.bgold - Cost)};
				true ->
					NewPlayerStatus = PlayerStatus#player_status{bgold = 0, gold = (PlayerStatus#player_status.bgold + PlayerStatus#player_status.gold - Cost)}
			end
	end,
	%判断金钱数
	if  NewPlayerStatus#player_status.coin < 0  orelse NewPlayerStatus#player_status.bgold < 0 
		orelse NewPlayerStatus#player_status.gold < 0 orelse NewPlayerStatus#player_status.bcoin < 0 ->
			%% Playeer:玩家,  MoneyError:金钱错误
			lists:concat(["Playeer：",NewPlayerStatus#player_status.id," ",
				  NewPlayerStatus#player_status.nickname,
				  " MoneyError：coin=", NewPlayerStatus#player_status.coin,
				  ", bgold=",NewPlayerStatus#player_status.bgold,
				  ", gold=",NewPlayerStatus#player_status.gold,
				  ", bcoin=",NewPlayerStatus#player_status.bcoin]),
			throw(money_error);
		true -> 
			skip
	end,
	Sql = io_lib:format(?SQL_PLAYER_UPDATE_MONEY, [
		NewPlayerStatus#player_status.coin, 
		NewPlayerStatus#player_status.bgold,
		NewPlayerStatus#player_status.gold, 
		NewPlayerStatus#player_status.bcoin, 
		NewPlayerStatus#player_status.id
	]),
	db:execute(Sql),
	%% 限时名人堂（活动）
	NewPlayerStatus2 = case lists:member(Type, [coin, fcoin, rcoin, bcoin]) of
		true ->
			lib_fame_limit:trigger_coin(NewPlayerStatus, Cost);
		_ ->
			NewPlayerStatus
	end,
	NewPlayerStatus2.

%% 扣除挂售的铜币（挂售铜币，交易铜币专用）
cost_sell_money(PlayerStatus, Cost, rcoin) ->
	NewPlayerStatus = PlayerStatus#player_status{coin = (PlayerStatus#player_status.coin - Cost)},
	%判断金钱数
	if  NewPlayerStatus#player_status.coin < 0  orelse NewPlayerStatus#player_status.bgold < 0 
		orelse NewPlayerStatus#player_status.gold < 0 orelse NewPlayerStatus#player_status.bcoin < 0 ->
			%% Playeer:玩家,  MoneyError:金钱错误
			lists:concat(["Playeer：",NewPlayerStatus#player_status.id," ",
				  NewPlayerStatus#player_status.nickname,
				  " MoneyError：coin=", NewPlayerStatus#player_status.coin,
				  ", bgold=",NewPlayerStatus#player_status.bgold,
				  ", gold=",NewPlayerStatus#player_status.gold,
				  ", bcoin=",NewPlayerStatus#player_status.bcoin]),
			throw(money_error);
		true -> 
			skip
	end,
	Sql = io_lib:format(?SQL_PLAYER_UPDATE_MONEY, [
		NewPlayerStatus#player_status.coin, 
		NewPlayerStatus#player_status.bgold,
		NewPlayerStatus#player_status.gold, 
		NewPlayerStatus#player_status.bcoin, 
		NewPlayerStatus#player_status.id
	]),
	db:execute(Sql),
	NewPlayerStatus.

%% 增加角色金钱
add_money(PlayerStatus, Amount, point) -> 
	NewPlayerStatus = PlayerStatus#player_status{point = (PlayerStatus#player_status.point + Amount)},
	Sql = io_lib:format(?SQL_PLAYER_UPDATE_MONEY, NewPlayerStatus#player_status.point),
	db:execute(Sql),
	NewPlayerStatus;

add_money(PlayerStatus, Amount, Type) ->
	case Type of
        coin ->
			%% 成就：西游巨富，拥有N万铜钱
			Total = PlayerStatus#player_status.coin + Amount,
			mod_achieve:trigger_role(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 2, 0, Total),
			NewPlayerStatus = PlayerStatus#player_status{coin =Total};
        rcoin -> 
			%% 成就：西游巨富，拥有N万铜钱
			Total = PlayerStatus#player_status.coin + Amount,
			mod_achieve:trigger_role(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 2, 0, Total),
			NewPlayerStatus = PlayerStatus#player_status{coin = (PlayerStatus#player_status.coin + Amount)};
        bgold -> NewPlayerStatus = PlayerStatus#player_status{bgold = (PlayerStatus#player_status.bgold+ Amount)};
        gold ->   NewPlayerStatus = PlayerStatus#player_status{gold = (PlayerStatus#player_status.gold + Amount)};
        bcoin ->  NewPlayerStatus = PlayerStatus#player_status{bcoin = (PlayerStatus#player_status.bcoin + Amount)}
    end,
    Sql = io_lib:format(?SQL_PLAYER_UPDATE_MONEY, [NewPlayerStatus#player_status.coin, 
												   NewPlayerStatus#player_status.bgold, 
												   NewPlayerStatus#player_status.gold, 
												   NewPlayerStatus#player_status.bcoin, 
												   NewPlayerStatus#player_status.id]),
    db:execute(Sql),
    NewPlayerStatus.

%% 更改物品耐久度
change_goods_use(GoodsInfo, UseNum) ->
	Sql = io_lib:format(?SQL_GOODS_UPDATE_USENUM, [UseNum, GoodsInfo#goods.id]),
	db:execute(Sql),
	GoodsInfo#goods{use_num = UseNum}.

%% 更改物品数量
change_goods_num(GoodsInfo, Num) ->
	Sql = io_lib:format(?SQL_GOODS_UPDATE_NUM, [Num, GoodsInfo#goods.id]),
	db:execute(Sql),
	GoodsInfo#goods{num = Num}.	

%% 扩充背包
extend_bag(PlayerStatus, CellNum) ->
	NewCellNum = PlayerStatus#player_status.cell_num + CellNum,
	Sql = io_lib:format(?SQL_PLAYER_UPDATE_CELL, [NewCellNum, PlayerStatus#player_status.id]),
	db:execute(Sql),
	PlayerStatus#player_status{cell_num = NewCellNum}.

%% 插入物品
add_goods(GoodsInfo) ->
    Sql1 = io_lib:format(?SQL_GOODS_INSERT, [GoodsInfo#goods.player_id, GoodsInfo#goods.type, 
											 GoodsInfo#goods.subtype, GoodsInfo#goods.price_type, 
											 GoodsInfo#goods.price, GoodsInfo#goods.sell_price, 
											 GoodsInfo#goods.vitality, GoodsInfo#goods.spirit, 
											 GoodsInfo#goods.hp, GoodsInfo#goods.mp, GoodsInfo#goods.forza, 
											 GoodsInfo#goods.agile, GoodsInfo#goods.wit, GoodsInfo#goods.att, 
											 GoodsInfo#goods.def, GoodsInfo#goods.hit, GoodsInfo#goods.dodge, 
											 GoodsInfo#goods.crit, GoodsInfo#goods.ten, GoodsInfo#goods.speed, 
											 GoodsInfo#goods.suit_id, GoodsInfo#goods.skill_id, 
											 GoodsInfo#goods.expire_time]),
    db:execute(Sql1),
    GoodsId = db:get_one(?SQL_LAST_INSERT_ID),
    Sql2 = io_lib:format(?SQL_GOODS_LOW_INSERT, [GoodsId, GoodsInfo#goods.player_id, GoodsInfo#goods.goods_id, 
												 GoodsInfo#goods.equip_type, GoodsInfo#goods.bind, 
												 GoodsInfo#goods.trade, GoodsInfo#goods.sell, 
												 GoodsInfo#goods.isdrop, GoodsInfo#goods.level, 
												 GoodsInfo#goods.stren, 
												 GoodsInfo#goods.stren_ratio, GoodsInfo#goods.hole, GoodsInfo#goods.hole1_goods, 
												 GoodsInfo#goods.hole2_goods, GoodsInfo#goods.hole3_goods, GoodsInfo#goods.color, 
												 util:term_to_string(GoodsInfo#goods.addition_1), util:term_to_string(GoodsInfo#goods.addition_2), util:term_to_string(GoodsInfo#goods.addition_3), GoodsInfo#goods.first_prefix,
												 GoodsInfo#goods.prefix, GoodsInfo#goods.min_star, GoodsInfo#goods.wash_time, GoodsInfo#goods.note, GoodsInfo#goods.ice, GoodsInfo#goods.fire, GoodsInfo#goods.drug]),
    db:execute(Sql2),
    Sql3 = io_lib:format(?SQL_GOODS_HIGHT_INSERT, [GoodsId, GoodsInfo#goods.player_id, GoodsInfo#goods.goods_id, 
												   GoodsInfo#goods.guild_id, GoodsInfo#goods.attrition, 
												   GoodsInfo#goods.use_num, GoodsInfo#goods.location, 
												   GoodsInfo#goods.cell, GoodsInfo#goods.num]),
    db:execute(Sql3),
    GoodsId.

%% 删除物品
delete_goods(GoodsId) ->
	Sql = io_lib:format(?SQL_GOODS_DELETE_BY_ID, [GoodsId]),
	db:execute(Sql).

%% 删除帮派物品
delete_goods_by_guild(GuildId) ->
    Sql = io_lib:format(?SQL_GOODS_DELETE_BY_GUILD, [GuildId]),
    db:execute(Sql),
    ok.

%% 添加挂售记录
add_sell(SellInfo) ->
    Sql = io_lib:format(?SQL_SELL_INSERT, [SellInfo#ets_sell.class1, SellInfo#ets_sell.class2, SellInfo#ets_sell.gid, SellInfo#ets_sell.pid, SellInfo#ets_sell.nickname, SellInfo#ets_sell.accname, SellInfo#ets_sell.goods_id, SellInfo#ets_sell.goods_name, SellInfo#ets_sell.num, SellInfo#ets_sell.type, SellInfo#ets_sell.subtype, SellInfo#ets_sell.lv, SellInfo#ets_sell.lv_num, SellInfo#ets_sell.color, SellInfo#ets_sell.career, SellInfo#ets_sell.price_type, SellInfo#ets_sell.price, SellInfo#ets_sell.time, SellInfo#ets_sell.end_time]),
    db:execute(Sql),
    db:get_one(?SQL_LAST_INSERT_ID).

%% 删除挂售记录
del_sell(Id) ->
    Sql = io_lib:format(?SQL_SELL_DELETE, [Id]),
    db:execute(Sql).

%% 删除挂售记录
del_sell_by_goods(GoodsId) ->
    Sql = io_lib:format(?SQL_SELL_DELETE_GID, [GoodsId]),
    db:execute(Sql).

%% 取挂售记录
get_sell_info(Id) ->
    Sql = io_lib:format(?SQL_SELL_SELECT_ID, [Id]),
    case db:get_row(Sql) of
        [] -> [];
        Data -> make_sell(Data)
    end.

make_sell([Mid, Mclass1, Mclass2, Mgid, Mpid, Mnickname, Maccname, Mgoods_id, Mgoods_name, Mnum, Mtype, 
           Msubtype, Mlv, Mlv_num, Mcolor, Mcareer, Mprice_type, Mprice, Mtime, Mend_time, Mis_expire, Mexpire_time]) ->
    #ets_sell{id=Mid, class1=Mclass1, class2=Mclass2, gid=Mgid, pid=Mpid, nickname=Mnickname, accname=Maccname, goods_id=Mgoods_id, goods_name = Mgoods_name,
        num=Mnum, type=Mtype, subtype=Msubtype, lv=Mlv, lv_num=Mlv_num, color=Mcolor, career=Mcareer, price_type=Mprice_type,
        price=Mprice, time=Mtime, end_time=Mend_time, is_expire=Mis_expire, expire_time=Mexpire_time}.

to_term(BinString) ->
	case util:bitstring_to_term(BinString) of
		undefined ->
			[];
		Term ->
			Term
	end.

%% 取物品类型信息
get_ets_info(Tab, Id) ->
	I = case is_integer(Id) of
			true ->
				ets:lookup(Tab, Id);
			false ->
				ets:match_object(Tab, Id)
		end,
	case I of
		[Info|_] ->
			Info;
		_ ->
			[]
	end.

get_ets_list(Tab, Pattern) ->
    ets:match_object(Tab, Pattern).

%% 取装备列表
get_equip_list(_PlayerId, Type, Location, Dict) ->
    case Dict =/= [] of
        true ->
            Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.type=:=Type andalso Value#goods.location=:=Location end, Dict),
            DictList = dict:to_list(Dict1),
            List = lib_goods_dict:get_list(DictList, []),
            List;
        false ->
            []
    end.

get_current_equip_by_info(GoodsInfo, [CurrentEquip1, Type]) ->
	[Wq, Yf, Zq, WqStren, YfStren, Sz] = CurrentEquip1,
    case is_record(GoodsInfo, goods) of
        true when GoodsInfo#goods.type =:= ?GOODS_TYPE_EQUIP andalso GoodsInfo#goods.subtype =:= 10 ->
            CurrentEquip = case Type of
                               on -> [GoodsInfo#goods.goods_id, Yf, Zq, GoodsInfo#goods.stren, YfStren, Sz];
                               off -> [0, Yf, Zq, 0, YfStren, Sz]
                           end;
        true when GoodsInfo#goods.type =:= ?GOODS_TYPE_EQUIP andalso GoodsInfo#goods.subtype =:= 21 ->
            CurrentEquip = case Type of
                               on -> [Wq, GoodsInfo#goods.goods_id, Zq, WqStren, GoodsInfo#goods.stren, Sz];
                               off -> [Wq, 0, Zq, WqStren, 0, Sz]
                           end;
        true when GoodsInfo#goods.type =:= ?GOODS_TYPE_MOUNT ->
            CurrentEquip = case Type of
                               on -> [Wq, Yf, GoodsInfo#goods.goods_id, WqStren, YfStren, Sz];
                               off -> [Wq, Yf, 0, WqStren, YfStren, Sz]
                           end;
        true when GoodsInfo#goods.type =:= ?GOODS_TYPE_EQUIP andalso GoodsInfo#goods.subtype =:= ?GOODS_FASHION_ARMOR ->
            CurrentEquip = case Type of
                               on -> [Wq, Yf, Zq, WqStren, YfStren, GoodsInfo#goods.goods_id];
                               off -> [Wq, Yf, Zq, WqStren, YfStren, 0]
                           end;
        _ ->
            CurrentEquip = [Wq, Yf, Zq, WqStren, YfStren, Sz]
    end,
    [CurrentEquip, Type].

%% 按格子位置排序
sort(GoodsList, Type) ->
	case Type of
		id -> F = fun(G1, G2) -> G1#goods.id < G2#goods.id end;
		cell -> F = fun(G1, G2) -> G1#goods.cell < G2#goods.cell end;
		bind -> F = fun(G1, G2) -> G1#goods.bind > G2#goods.bind end;
        goods_id -> F = fun(G1, G2) -> G1#goods.goods_id < G2#goods.goods_id end;
        bind_id -> 
            F = fun(G1, G2) -> 
                if
                    G1#goods.goods_id =:= G2#goods.goods_id ->
                        G1#goods.bind < G2#goods.bind;
                    true ->
                        G1#goods.goods_id < G2#goods.goods_id 
                end
        end;
		_ -> F = fun(G1, G2) -> G1#goods.cell < G2#goods.cell end
		end,
	lists:sort(F, GoodsList).

%% 取机率总和
get_ratio_total(RatioList, N) ->
    F = fun(RatioInfo, Sum) ->
                element(N, RatioInfo) + Sum
        end,
    lists:foldl(F, 0, RatioList).

%% 查找匹配机率的值
find_ratio([], _, _, _) -> null;
find_ratio(InfoList, Start, Rand, N) ->
    [Info | List] = InfoList,
    End = Start + element(N, Info),
    case Rand > Start andalso Rand =< End of
        true -> Info;
        false -> find_ratio(List, End, Rand, N)
    end.

%% 取任务物品数量
%% @spec get_task_goods_num(PlayerId, GoodsTypeId) -> num | 0
get_task_goods_num(_PlayerId, GoodsTypeId, Dict) ->
    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.goods_id=:=GoodsTypeId end, Dict),
    DictList = dict:to_list(Dict1),
    GoodsList = lib_goods_dict:get_list(DictList, []),
    get_goods_totalnum(GoodsList).

%% 帮派仓库物品列表
get_guild_goods_list(GuildId) ->
    Sql = io_lib:format(?SQL_GOODS_LIST_BY_GUILD, [GuildId]),
    get_list(goods, Sql).

%% 隐藏时装
change_fashion_state(Weapon, Armor, Accessory, Head, Tail, Ring, PlayerId) ->
    Sql = io_lib:format(?sql_update_fashion, [Weapon, Armor, Accessory, Head, Tail, Ring, PlayerId]),
    db:execute(Sql).




