%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-13
%% Description: 150物品信息
%% --------------------------------------------------------
-module(pt_150).
-include("record.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-include("mount.hrl").
-export([read/2, write_goods_info/2, write/2]).

%%
%% 客户端 -> 服务 端 ------------------------------------------
%%

%% 查询物品详细信息
read(15000, <<GoodsId:32, Location:16>>) ->
	{ok, [GoodsId, Location]};

%% 查看别人物品信息
read(15001, <<RoleId:32, GoodsId:32>>) ->
	{ok, [RoleId, GoodsId]};

%% 查看地上的掉落包
read(15002, <<DropId:32>>) ->
    {ok, DropId};

%% 预览物品信息
read(15003, <<GoodsTypeId:32, Bind:16, Prefix:16, Stren:16>>) ->
	{ok, [GoodsTypeId, Bind, Prefix, Stren]};

%% 预览装备洗炼信息
read(15004, <<GoodsId:32>>) ->
	{ok, GoodsId};

%% 查看物品列表
read(15010, <<Pos:16>>) ->
	{ok, Pos};

%% 列出别人身上装备列表
read(15011, <<RoleId:32>>) ->
	{ok, RoleId};

%% 获取要修理装备列表
read(15012, _R) ->
	{ok, mend_list};

%% 列出背包打造装备列表
read(15014, _R) ->
	{ok, make_list};

%% 列出挂售物品列表
read(15015, <<PlayerId:32>>) ->
    {ok, PlayerId};

%% NPC已领取礼包列表
read(15016, _R) ->
	{ok, gift_list};

%% 背包扩展
read(15022, <<Type:8, Num:16, Gold:32>>) ->
    {ok, [Type, Num, Gold]};

%% 购买挂售物品
read(15024, <<PlayerId:32, GoodsId:32, GoodsNum:16>>) ->
    {ok, [PlayerId, GoodsId, GoodsNum]};

%%装备物品
read(15030, <<GoodsId:32, Cell:16>>) ->
    {ok, [GoodsId, Cell]};

%% 缷下装备
read(15031, <<GoodsId:32>>) ->
	{ok, GoodsId};

%% 修理装备
read(15033, <<GoodsId:32>>) ->
	{ok, GoodsId};

%% 修理全部装备
read(15035, _R) ->
	{ok, mend_all};

%%拖动背包物品
read(15040, <<GoodsId:32, OldCell:16, NewCell:16>>) ->
	{ok, [GoodsId, OldCell, NewCell]};

%%物品存入仓库
read(15041, <<NpcId:32, GoodsId:32, Num:16>>) ->
	{ok, [NpcId, GoodsId, Num]};

%% 从仓库取出物品
read(15042, <<NpcId:32, GoodsId:32, Num:16>>) ->
	{ok, [NpcId, GoodsId, Num]};

%% 使用物品
read(15050, <<GoodsId:32, Num:16>>) ->
	{ok, [GoodsId, Num]};

%% 销毁物品
read(15051, <<GoodsId:32, Num:16>>) ->
	{ok, [GoodsId, Num]};

%%整理背包
read(15052, _R) ->
    {ok, order};

%% 拣取地上掉落包的物品
read(15053, <<DropId:32>>) ->
    {ok, DropId};

%% 拆分物品
read(15054, <<GoodsId:32, Num:16>>) ->
    {ok, [GoodsId, Num]};
%% 气血内力回复
read(15055, <<ReplyType:8>>) ->
    {ok, ReplyType};

%% 气血内力包初始化
read(15056, _R) ->
    {ok, hp_init};

%% 在线礼包领取
read(15082, <<GiftId:32>>) ->
    {ok, GiftId};

%% NPC礼包领取
read(15083, <<GiftId:32, Bin/binary>>) ->
    {Card, _} = pt:read_string(Bin),
    {ok, [GiftId, Card]};

%% NPC兑换物品
read(15084, <<NpcTypeId:32, ExchangeId:32, ExchangeNum:16>>) ->
    {ok, [NpcTypeId, ExchangeId, ExchangeNum]};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%% 服务 端 -> 客户端 ------------------------------------------
%%

%%查询物品详细信息
write_goods_info(Cmd, [GoodsInfo, SuitNum, AttributeList, BaseSpeed, PlayerCareer]) ->
    case is_record(GoodsInfo, goods) of
        true ->
            GoodsId = GoodsInfo#goods.id,
            TypeId = GoodsInfo#goods.goods_id,
            Cell = GoodsInfo#goods.cell,
            Num = GoodsInfo#goods.num,
            Bind = GoodsInfo#goods.bind,
            Trade = GoodsInfo#goods.trade,
            Sell = GoodsInfo#goods.sell,
            Isdrop = GoodsInfo#goods.isdrop,
            EquipType = GoodsInfo#goods.equip_type,
            Attrition = data_goods:count_goods_attrition(GoodsInfo#goods.equip_type, GoodsInfo#goods.attrition, GoodsInfo#goods.use_num),
            Color = GoodsInfo#goods.color,
            Stren = GoodsInfo#goods.stren,
            SuitId = GoodsInfo#goods.suit_id,
            SuitNum = SuitNum,
            Forza = GoodsInfo#goods.forza,
            Agile = GoodsInfo#goods.agile,
            Wit = GoodsInfo#goods.wit,
            Vitality = GoodsInfo#goods.vitality,
            Spirit = GoodsInfo#goods.spirit,
            Hp = GoodsInfo#goods.hp,
            Mp = GoodsInfo#goods.mp,
            Att = GoodsInfo#goods.att,
            Def = GoodsInfo#goods.def,
            Hit = GoodsInfo#goods.hit,
            Dodge = GoodsInfo#goods.dodge,
            Crit = GoodsInfo#goods.crit,
            Ten = GoodsInfo#goods.ten,
            Prefix = GoodsInfo#goods.prefix,
            FirstPreFix = GoodsInfo#goods.first_prefix,
            Stren_ratio = GoodsInfo#goods.stren_ratio,
            Expire_time = GoodsInfo#goods.expire_time,
            %% 洗炼属性
            Addition1 = GoodsInfo#goods.addition_1,
            Addition2 = GoodsInfo#goods.addition_2,
            Addition3 = GoodsInfo#goods.addition_3,
            _AllList = [{1, Addition1},{2,Addition2},{3,Addition3}],
            AllList = [{Pos, Addition}|| {Pos, Addition} <- _AllList, Addition =/= []],
            F = fun({Type, Star, Value, TypeColor, _, _}) ->
                <<Type:16, Value:32, Star:16, TypeColor:8>>
            end,
            F2 = fun({Grade, AdditionList}) ->
                List = lists:map(F, AdditionList),
                ListBin = list_to_binary(List),
                Len = length(List),
                <<Grade:8, Len:16, ListBin/binary>>
            end,
            
            List2 = lists:map(F2, AllList),
            ListBin2 = list_to_binary(List2),
            ListNum = length(List2), 
            Note = pt:write_string(GoodsInfo#goods.note),
            Min_star = GoodsInfo#goods.min_star,
            Fire = GoodsInfo#goods.fire,
            Ice2 = GoodsInfo#goods.ice,
            Drug = GoodsInfo#goods.drug,
            case GoodsInfo#goods.type =:= ?GOODS_TYPE_MOUNT of
                true ->
                    case data_mount:get_mount_base(GoodsInfo#goods.goods_id) of
                        [] ->
                            Speed = 0;
                        Base ->
                            Speed = round((Base#mount_base.speed / BaseSpeed) * 100)
                    end;
                false ->
                    Speed = GoodsInfo#goods.speed
            end,
            if GoodsInfo#goods.type =:= 10 ->
                   Combat_power = data_goods:count_goods_power(GoodsInfo, AttributeList, PlayerCareer),
                   Ice = 0;
               GoodsInfo#goods.type =:= ?GOODS_TYPE_MOUNT ->
                   {Combat_power, Ice} = lib_mount:get_mount_power_for_goods(GoodsInfo#goods.stren, GoodsInfo#goods.goods_id);
               true ->
                   Combat_power = 0,
                   Ice = 0
            end;
        false ->
            GoodsId = 0,
            TypeId = 0,
            Cell = 0,
            EquipType = 0,
            Num = 0,
            Bind = 0,
            Trade = 0,
            Sell = 0,
            Isdrop = 0,
            Attrition = 0,
            Color = 0,
            Stren = 0,
            SuitId = 0,
            SuitNum = 0,
            Forza = 0,
            Agile = 0,
            Wit = 0,
            Vitality = 0,
            Spirit = 0,
            Hp = 0,
            Mp = 0,
            Att = 0,
            Def = 0,
            Hit = 0,
            Dodge = 0,
            Crit = 0,
            Ten = 0,
            Prefix = 0,
            FirstPreFix = 0,
            Stren_ratio = 0,
            Expire_time = 0,
            ListNum = 0,
            ListBin2 = <<>>,
            Note = <<0,0>>,
            Min_star = 0,
            Speed = 0,
            Combat_power = 0,
            Fire = 0,
            Ice2 = 0,
            Drug = 0,
            Ice = 0
    end,
    %io:format("150000 ~p~n", [{GoodsId, TypeId, Cell, Num, Bind, Trade,Sell, Isdrop, Attrition, Color, Stren,Hole, Hole1_goods, Hole2_goods, Hole3_goods, SuitId,SuitNum, Forza, Agile, Wit, Vitality, Spirit, Hp, Mp,Att, Def, Hit, Dodge, Crit, Ten, Prefix, Stren_ratio, Expire_time, Note, Min_star, Combat_power,ListNum, ListBin, Speed, Ice, Fire, Ice2,Drug}]),
    {ok, pt:pack(Cmd, <<GoodsId:32, TypeId:32, Cell:16, Num:16, Bind:16, Trade:16,
                            Sell:16, Isdrop:16, Attrition:16, Color:16, Stren:16,SuitId:16,
                            SuitNum:16, Forza:16, Agile:16, Wit:16, Vitality:16, Spirit:32, Hp:32, Mp:32,
                            Att:16, Def:16, Hit:16, Dodge:16, Crit:16, Ten:16, Prefix:16, FirstPreFix:16, Stren_ratio:16, 
                        Expire_time:32, Note/binary, Min_star:16, Combat_power:16, ListNum:16, ListBin2/binary, Speed:16, Ice:32, Fire:32, Ice2:32, Drug:32, EquipType:8>>)}.

%% 查看地上的掉落包
write(15002, [Res, DropId, DropList]) ->
    ListNum = length(DropList),
    F = fun(Data) ->
            case Data of
                {equip, {GoodsTypeId, Prefix, _Stren}} ->
                    <<GoodsTypeId:32, 1:16, Prefix:16>>;
                {goods, {GoodsTypeId, GoodsNum}} ->
                    <<GoodsTypeId:32, GoodsNum:16, 0:16>>
            end
        end,
    ListBin = list_to_binary(lists:map(F, DropList)),
    {ok, pt:pack(15002, <<Res:16, DropId:32, ListNum:16, ListBin/binary>>)};

%% 物品信息预览
write(15003, [Res, GoodsTypeId, Bind, Prefix, Stren, AttriList]) ->
	ListNum = length(AttriList),
	F = fun({AttriType, AttriId, Value, Star}) ->
				if AttriId > 50 ->
					   AttriVal = round(Value * 100);
				   true ->
					   AttriVal = round(Value)
				end,
				<<AttriType:16, AttriId:16, AttriVal:32, Star:16>>
		end,
	ListBin = list_to_binary(lists:map(F, AttriList)),
	{ok, pt:pack(15003, <<Res:16, GoodsTypeId:32, Bind:16, Prefix:16, Stren:16, ListNum:16, ListBin/binary>>)};

%% 预览装备洗炼信息
write(15004, [Res, GoodsId, GoodsTypeId, HasWash, Addition]) ->
	F = fun({Type, Star, Value, Color, Min, Max}) ->
				<<Type:8, Star:8, Value:16, Color:8, Min:32, Max:32>>
		end,
	ListNum1 = length(Addition),
	Bin1 = list_to_binary(lists:map(F, Addition)),
	{ok, pt:pack(15004, <<Res:16, GoodsId:32, GoodsTypeId:32, HasWash:8, ListNum1:16, Bin1/binary>>)};
					   
%% 物品列表
write(15010, [Pos, CellNum, Bcoin, Coin, Bgold, Gold, Point, GoodsList]) ->
	ListNum = length(GoodsList),
	F = fun(GoodsInfo) ->
            case is_record(GoodsInfo, goods) =:= true andalso is_integer(GoodsInfo#goods.id) =:= true of
                    true ->                    
				        GoodsId = GoodsInfo#goods.id,
            	        TypeId = GoodsInfo#goods.goods_id,
            	        Cell = GoodsInfo#goods.cell,
            	        GoodsNum = GoodsInfo#goods.num,
            	        Bind = GoodsInfo#goods.bind,
            	        Trade = GoodsInfo#goods.trade,
            	        Sell = GoodsInfo#goods.sell,
            	        Isdrop = GoodsInfo#goods.isdrop,
            	        Stren = GoodsInfo#goods.stren,
                        Color = GoodsInfo#goods.color,
                        Attrition = round(data_goods:count_goods_attrition(GoodsInfo#goods.equip_type, GoodsInfo#goods.attrition, GoodsInfo#goods.use_num)),
            	        <<GoodsId:32, TypeId:32, Cell:16, GoodsNum:16, Attrition:16, Bind:8, Trade:8, Sell:8, Isdrop:8, Stren:16, Color:8>>;
                    false ->
                        <<0:32, 0:32, 0:16, 0:16, 0:16, 0:8, 0:8, 0:8, 0:8, 0:16, 0:8>>
                end
        end,
	ListBin = list_to_binary(lists:map(F, GoodsList)),
	{ok, pt:pack(15010, <<Pos:16, CellNum:16, Bcoin:32, Coin:32, Bgold:32, Gold:32, Point:32, ListNum:16, ListBin/binary>>)};

%%查询别人身上装备列表
write(15011, [Res, RoleId, EquipList]) ->
	ListNum = length(EquipList),
	F = fun(GoodsInfo) ->
            GoodsId = GoodsInfo#goods.id,
            TypeId = GoodsInfo#goods.goods_id,
            Cell = GoodsInfo#goods.cell,
            GoodsNum = GoodsInfo#goods.num,
            Stren = GoodsInfo#goods.stren,
            Attrition = data_goods:count_goods_attrition(GoodsInfo#goods.equip_type, 
														 GoodsInfo#goods.attrition, 
														 GoodsInfo#goods.use_num),
            <<GoodsId:32, TypeId:32, Cell:16, GoodsNum:16, Attrition:16, Stren:16>>
        end,
    ListBin = list_to_binary(lists:map(F, EquipList)),
	{ok, pt:pack(15011, <<Res:16, RoleId:32, ListNum:16, ListBin/binary>>)};

%% 获取要修理装备列表
write(15012, MendList) ->
	ListNum = length(MendList),
	F = fun(GoodsInfo) ->
				GoodsId = GoodsInfo#goods.id,
            	Attrition = data_goods:count_goods_attrition(GoodsInfo#goods.equip_type, 
															 GoodsInfo#goods.attrition, 
															 GoodsInfo#goods.use_num),
            	Cost = data_goods:count_mend_cost(GoodsInfo),
            	<<GoodsId:32, Attrition:16, Cost:32>>
        end,
    ListBin = list_to_binary(lists:map(F, MendList)),
    {ok, pt:pack(15012, <<ListNum:16, ListBin/binary>>)};

%% 列出背包打造装备列表
write(15014, GoodsList) ->
	ListNum = length(GoodsList),
%% 				int:32 物品Id
%%         		int:16 孔数
%%         		int:16 镶嵌数
%%        		int:16 强化数
%%         		int:16 强化附加成功率
	F = fun(GoodsInfo) ->
				GoodsId = GoodsInfo#goods.id,
            	Hole = GoodsInfo#goods.hole,
            	InlayNum = lib_goods_util:get_inlay_num(GoodsInfo),
            	Stren = GoodsInfo#goods.stren,
            	Stren_ratio = GoodsInfo#goods.stren_ratio,
            	<<GoodsId:32, Hole:16, InlayNum:16, Stren:16, Stren_ratio:16>>
        end,
	ListBin = list_to_binary(lists:map(F, GoodsList)),
	{ok, pt:pack(15014, <<ListNum:16, ListBin/binary>>)};

%%列出挂售物品列表
write(15015, [PlayerId, PlayerName, SellList]) ->
    Nick = list_to_binary(PlayerName),
    Len = byte_size(Nick),
    ListNum = length(SellList),
    F = fun({GoodsId, GoodsTypeId, GoodsNum, PriceType, Price}) ->
            <<GoodsId:32, GoodsTypeId:32, GoodsNum:16, PriceType:8, Price:32>>
        end,
    ListBin = list_to_binary(lists:map(F, SellList)),
    {ok, pt:pack(15015, <<PlayerId:32, Len:16, Nick/binary, ListNum:16, ListBin/binary>>)};

%% NPC已领取礼包列表
write(15016, GiftList) ->
	ListNum = length(GiftList),
	F = fun(GiftId) ->
				<<GiftId:32>>
		end,
	ListBin = list_to_binary(lists:map(F, GiftList)),
	{ok, pt:pack(15016, <<ListNum:16, ListBin/binary>>)};

%% 扩展背包
%%扩充仓库
write(15022, [Res, NewNum, NewGold]) ->
    {ok, pt:pack(15022, <<Res:16, NewGold:32, NewNum:16>>)};

%% 购买挂售物品
write(15024, [Res, PlayerId, GoodsId, GoodsTypeId, GoodsNum]) ->
    {ok, pt:pack(15024, <<Res:16, PlayerId:32, GoodsId:32, GoodsTypeId:32, GoodsNum:16>>)};

%%装备物品
write(15030, [Res, GoodsId, OldGoodsId, OldGoodsTypeId, OldGoodsCell, OldAttrition, Bind]) ->
    {ok, pt:pack(15030, <<Res:16, GoodsId:32, OldGoodsId:32, OldGoodsTypeId:32, OldGoodsCell:16, OldAttrition:16, Bind:16>>)};

%% 缷下装备
write(15031, [Res, GoodsId, TypeId, Cell, Attrition, Bind, Stren]) ->
	{ok, pt:pack(15031, << Res:16, GoodsId:32, TypeId:32, Cell:16, Attrition:16, Bind:16, Stren:16>>)};

%%装备磨损
write(15032, GoodsList) ->
    ListNum = length(GoodsList),
    F = fun(GoodsInfo) ->
            GoodsId = GoodsInfo#goods.id,
            <<GoodsId:32>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(15032, <<ListNum:16, ListBin/binary>>)};

%%修理装备
write(15033, [Res, GoodsId, NewCoin, NewBcoin, Cost]) ->
    {ok, pt:pack(15033, <<Res:16, GoodsId:32, NewCoin:32, NewBcoin:32, Cost:32>>)};

%% 修理全部装备
write(15035, [Res, Coin, Bcoin, Cost]) ->
	{ok, pt:pack(15035, <<Res:16, Coin:32, Bcoin:32, Cost:32>>)};

%%拖动背包物品
write(15040, [Res, GoodsInfo1, GoodsInfo2]) ->
	GoodsId1 = GoodsInfo1#goods.id,
	GoodsTypeId1 = GoodsInfo1#goods.goods_id,
	Cell1 = GoodsInfo1#goods.cell,
	Num1 = GoodsInfo1#goods.num,
	GoodsId2 = GoodsInfo2#goods.id,
	GoodsTypeId2 = GoodsInfo2#goods.goods_id,
	Cell2 = GoodsInfo2#goods.cell,
	Num2 = GoodsInfo2#goods.num,
	{ok, pt:pack(15040, <<Res:16, GoodsId1:32, GoodsTypeId1:32, Cell1:16, Num1:16, 
						  GoodsId2:32, GoodsTypeId2:32, Cell2:16, Num2:16>>)};

%% 物品存入仓库
write(15041, [Res, GoodsId, Num]) ->
	{ok, pt:pack(15041, <<Res:16, GoodsId:32, Num:16>>)};

%% 从仓库取出物品
write(15042, [Res, GoodsId, GoodsList]) ->
	ListNum = length(GoodsList),
	F = fun(GoodsInfo) ->
					Id = GoodsInfo#goods.id,
					TypeId = GoodsInfo#goods.goods_id,
					Cell = GoodsInfo#goods.cell,
					Num = GoodsInfo#goods.num,
					Bind = GoodsInfo#goods.bind,
					Trade = GoodsInfo#goods.trade,
					Sell = GoodsInfo#goods.sell,
					Isdrop = GoodsInfo#goods.isdrop,%销毁
					Stren = GoodsInfo#goods.stren,
					Attrition = data_goods:count_goods_attrition(GoodsInfo#goods.equip_type, 
					GoodsInfo#goods.attrition, GoodsInfo#goods.use_num),
					<<Id:32, TypeId:32, Cell:16, Num:16, Attrition:16, Bind:8, Trade:8, Sell:8, Isdrop:8, Stren:16>>
		end,
	ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(15042, <<Res:16, GoodsId:32, ListNum:16, ListBin/binary>>)};

%% 使用物品
write(15050, [Res, GoodsId, GoodsTypeId, GoodsNum, Hp, Mp]) ->
	{ok, pt:pack(15050, <<Res:16, GoodsId:32, GoodsTypeId:32, GoodsNum:16, Hp:32, Mp:32>>)};

%% 销毁物品
write(15051, [Res, GoodsId, Num]) ->
	{ok, pt:pack(15051, <<Res:16, GoodsId:32, Num:16>>)};

%% 整理背包
write(15052, GoodsList) ->
    ListNum = length(GoodsList),
    F = fun(GoodsInfo) ->
            GoodsId = GoodsInfo#goods.id,
            TypeId = GoodsInfo#goods.goods_id,
            Cell = GoodsInfo#goods.cell,
            Num = GoodsInfo#goods.num,
            Bind = GoodsInfo#goods.bind,
            Trade = GoodsInfo#goods.trade,
            Sell = GoodsInfo#goods.sell,
            Isdrop = GoodsInfo#goods.isdrop,
            Stren = GoodsInfo#goods.stren,
            Color = GoodsInfo#goods.color,
            Attrition = data_goods:count_goods_attrition(GoodsInfo#goods.equip_type, GoodsInfo#goods.attrition, GoodsInfo#goods.use_num),
            <<GoodsId:32, TypeId:32, Cell:16, Num:16, Attrition:16, Bind:8, Trade:8, Sell:8, Isdrop:8, Stren:16, Color:8>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(15052, <<ListNum:16, ListBin/binary>>)};

%% 拣取地上掉落包的物品
write(15053, [Res, DropId]) ->
    {ok, pt:pack(15053, <<Res:16, DropId:32>>)};

%% 拆分物品
write(15054, [Res, OldGoodsId, GoodsInfo]) ->
    GoodsId = GoodsInfo#goods.id,
    GoodsTypeId = GoodsInfo#goods.goods_id,
    GoodsNum = GoodsInfo#goods.num,
    Cell = GoodsInfo#goods.cell,
    Bind = GoodsInfo#goods.bind,
    Trade = GoodsInfo#goods.trade,
    Sell = GoodsInfo#goods.sell,
    Isdrop = GoodsInfo#goods.isdrop,
    {ok, pt:pack(15054, <<Res:16, OldGoodsId:32, GoodsId:32, GoodsTypeId:32, GoodsNum:16, 
                          Cell:16, Bind:8, Trade:8, Sell:8, Isdrop:8>>)};
%% 气血内力回复
write(15055, [ReplyType, Span, MP, Bag, GoodsTypeId]) ->
    {ok, pt:pack(15055, <<ReplyType:8, Span:8, MP:32, Bag:32, GoodsTypeId:32>>)};

%% 气血内力包初始化
write(15056, [Hp_bag1, GoodsTypeId1, Mp_bag1, GoodsTypeId2, Hp_bag2, GoodsTypeId3, Mp_bag2, GoodsTypeId4]) ->
    {ok, pt:pack(15056, <<Hp_bag1:32, GoodsTypeId1:32, Mp_bag1:32, GoodsTypeId2:32, Hp_bag2:32, GoodsTypeId3:32, Mp_bag2:32, GoodsTypeId4:32>>)};

%% 在线礼包通知
write(15080, [GiftId, GiftTypeId, DelayTime, Exp, Gold, Silver, Coin, Bcoin, GoodsList]) ->
    ListNum = length(GoodsList),
    F = fun({GoodsTypeId, GoodsNum}) ->
            <<GoodsTypeId:32, GoodsNum:16>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(15080, <<GiftId:32, GiftTypeId:32, DelayTime:32, Exp:32, Gold:32, Silver:32, Coin:32, Bcoin:32, ListNum:16, ListBin/binary>>)};


%%在线礼包领取通知
write(15081, [GiftId, GiftTypeId, Exp, Gold, Bgold, Coin, Bcoin, GiftList]) ->
	ListNum = length(GiftList),
	F = fun({TypeId, GoodsNum}) ->
				<<TypeId:32, GoodsNum:16>>
		end,
	ListBin = list_to_binary(lists:map(F, GiftList)),
	{ok, pt:pack(15081, <<GiftId:32, GiftTypeId:32, Exp:32, Gold:32, Bgold:32, Coin:32, Bcoin:32, ListNum:16, ListBin/binary>>)};

%% 在线礼包领取
write(15082, [Res, GiftId]) ->
    {ok, pt:pack(15082, <<Res:16, GiftId:32>>)};

%% NPC礼包领取
write(15083, [Res, GiftId]) ->
    {ok, pt:pack(15083, <<Res:16, GiftId:32>>)};

%% NPC兑换物品
write(15084, [Res, NpcTypeId, ExchangeId, RemainNum]) ->
    {ok, pt:pack(15084, <<Res:16, NpcTypeId:32, ExchangeId:32, RemainNum:16>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.







