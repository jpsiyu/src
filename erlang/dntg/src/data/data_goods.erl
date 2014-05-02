%%%------------------------------------------------
%%% File    : data_goods.hrl
%%% Author  : xyj
%%% Created : 2012-4-18
%%% Description: 物品常量数据和计算公式
%%%------------------------------------------------
-module(data_goods).
-compile(export_all).
-include("record.hrl").
-include("figure.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("goods.hrl").
-include("shop.hrl").

%% 计算等级类型
get_level(Level) ->
    if  Level =< 19 -> 1;
        Level =< 29 -> 2;
        Level =< 39 -> 3;
        Level =< 49 -> 4;
        Level =< 59 -> 5;
        Level =< 69 -> 6;
        Level =< 79 -> 7;
        Level =< 89 -> 8;
        Level =< 99 -> 9;
        true -> 10
    end.

%% 装备附加属性系数
get_addition_factor(AttriId) ->
    case AttriId of
        1 -> 79.54;
        2 -> 26.52;
        3 -> 5.3;
        4 -> 0;
        5 -> 27.55;
        6 -> 33.06;
        7 -> 88.39;
        8 -> 44.19;
        9 -> 26.52;
        10 -> 26.52;
        11 -> 26.52;
        _ -> 0
    end.

%% 装备附加属性战斗力
get_addition_power(GoodsInfo) ->
    case is_record(GoodsInfo, goods) of
        true ->
            Attr = GoodsInfo#goods.addition_1++GoodsInfo#goods.addition_2++GoodsInfo#goods.addition_3,
            sum(Attr, 0);
        false ->
            0
    end.

sum([], Sum) ->
    Sum;
sum([H|T], Sum) ->
    case H of
        {AttributeId, _, Value, _, _, _} ->
            S = Value * get_addition_factor(AttributeId) + Sum,
            sum(T, S);
        _ ->
            sum(T, Sum)
    end.
    
get_shop_price(ShopInfo, GoodsTypeInfo, PayMoneyType) ->
    case ShopInfo#ets_shop.shop_type of
        ?SHOP_TYPE_GOLD when ShopInfo#ets_shop.shop_subtype == ?SHOP_SUBTYPE_COMMON orelse ShopInfo#ets_shop.shop_subtype == ?SHOP_SUBTYPE_COMMON2-> 
            case PayMoneyType of
                1 -> %% 元宝
                    {gold, ShopInfo#ets_shop.new_price};
                2 -> %% 元宝或者绑定元宝
                    {silver_and_gold, ShopInfo#ets_shop.new_price}
            end;
        ?SHOP_TYPE_GOLD when ShopInfo#ets_shop.shop_subtype =:= ?SHOP_SUBTYPE_GOLD_BIND ->
            {silver, ShopInfo#ets_shop.new_price};
        ?SHOP_TYPE_GOLD when ShopInfo#ets_shop.shop_subtype =:= ?SHOP_SUBTYPE_POINT ->
            {point, ShopInfo#ets_shop.new_price};
        ?SHOP_TYPE_GOLD when ShopInfo#ets_shop.shop_subtype >= 50 andalso ShopInfo#ets_shop.shop_subtype =< 65 ->
            {gold, ShopInfo#ets_shop.new_price};
        ?SHOP_TYPE_GOLD ->
            Price = case ShopInfo#ets_shop.new_price > 0 of
                        true -> ShopInfo#ets_shop.new_price;
                        false -> GoodsTypeInfo#ets_goods_type.price
                    end,
            {gold, Price};
        ?SHOP_TYPE_FORGE ->
            Price = case ShopInfo#ets_shop.new_price > 0 of
                        true -> ShopInfo#ets_shop.new_price;
                        false -> GoodsTypeInfo#ets_goods_type.price
                    end,
            {rcoin, Price};
        ?SHOP_TYPE_SIEGE_SHOP ->
            Price = case ShopInfo#ets_shop.new_price > 0 of
                        true -> ShopInfo#ets_shop.new_price;
                        false -> GoodsTypeInfo#ets_goods_type.price
                    end,
            {coin, Price};
        _ ->
            PriceType = if  ShopInfo#ets_shop.goods_id =:= 214081 -> rcoin;
                            true -> get_price_type(GoodsTypeInfo#ets_goods_type.price_type)
                        end,
            Price = case ShopInfo#ets_shop.new_price > 0 of
                        true -> ShopInfo#ets_shop.new_price;
                        false -> GoodsTypeInfo#ets_goods_type.price
                    end,
            {PriceType, Price}
    end.

%% 计算挂售价格
count_sell_cost(GoodsId, PriceType, Price, Time) ->
    case GoodsId =:= 0 of
        true -> 
            case PriceType =:= 0 of
                %% 拍卖元宝
                true -> 
                    if  Time =< 6  ->   util:ceil(Price*0.008);
                        Time =< 12 ->   util:ceil(Price*0.015);
                        true ->         util:ceil(Price*0.03)
                    end;
                %% 拍卖铜钱
                false -> 
                    if  Time =< 6  ->   util:ceil(Price*15);
                        Time =< 12 ->   util:ceil(Price*20);
                        true ->         util:ceil(Price*25)
                    end
            end;
        false ->
            case PriceType =:= 0 of
                %% 铜钱
                true ->
                    if  Time =< 6  ->   util:ceil(Price*0.02);
                        Time =< 12 ->   util:ceil(Price*0.035);
                        true ->         util:ceil(Price*0.06)
                    end;
                %% 元宝
                false ->
                    if  %Time =< 6  ->   util:ceil(Price*15);
                        Time =< 12 ->   max(500,  util:ceil(Price*25)); %% 保底500铜币
                        true ->         max(1000, util:ceil(Price*50))  %% 保底1000铜币
                    end
            end
    end.

%% 计算求购价格
count_wtb_cost(PriceType, Price, Time) ->
    case PriceType =:= 0 of
        %% 铜钱
        true ->
            if  Time =< 6  ->   util:ceil(Price*0.02);
                Time =< 12 ->   util:ceil(Price*0.035);
                true ->         util:ceil(Price*0.06)
            end;
        %% 元宝
        false ->
            if  Time =< 6  ->   util:ceil(Price*15);
                Time =< 12 ->   util:ceil(Price*20);
                true ->         util:ceil(Price*25)
            end
    end.

%% 取修理装备价格
%% 0.02*（装备等级+50）*（装备等级+50）*装备颜色系数
%% 装备颜色系数
%     绿色&蓝色	1
%     一元	    2
%     两仪	    3
%     三花	    4
%     四象	    5
%     五行	    6
%     六合	    7
count_mend_cost(GoodsInfo) ->
    TotalCost = 0.02 * (GoodsInfo#goods.level+50) * (GoodsInfo#goods.level+50) * (GoodsInfo#goods.first_prefix + 1),
    TotalUseNum = count_goods_use_num(GoodsInfo#goods.equip_type, GoodsInfo#goods.attrition),
    case TotalUseNum > 0 of
        true  -> util:ceil( TotalCost * (TotalUseNum - GoodsInfo#goods.use_num) / TotalUseNum );
        false -> 0
    end.

%% 取装备拆除价格
count_backout_cost(_GoodsInfo) ->
    10000.

%% 取装备合成价格
count_equip_compose_cost() ->
    100000.

%% 取得装备的使用次数
count_goods_use_num(_EquipType, Attrition) -> Attrition * 169.
   % case EquipType of
   %     1 ->  Attrition * 135;   %% 武器
   %     _ ->  Attrition * 160    %% 防具和饰品
   % end.

%% 取得装备当前耐久度
count_goods_attrition(_EquipType, OldAttrition, UseNum) ->
    Attrition = case OldAttrition > 0 of
                    false -> 0;
                    true when UseNum =:= 0 -> 0;
                    true -> round(UseNum / 169 + 0.5)
                    %true when EquipType =:= 1 -> round(UseNum / 135 + 0.5);
                    %true -> round(UseNum / 160 + 0.5)
                end,
    case Attrition > OldAttrition of
        true -> OldAttrition;
        false -> Attrition
    end.

%% 取装备的属性加成
count_goods_effect(GoodsInfo) ->
    NowTime = util:unixtime(),
    if
        GoodsInfo#goods.expire_time =:= 0 orelse GoodsInfo#goods.expire_time > NowTime ->
        %% 基础值 
        BaseEffect = count_base_effect(GoodsInfo),
        %% 装备强化加成 强化属性*(1+品质加成)
        Effect2 = count_stren_effect(GoodsInfo, BaseEffect),
        %% 附加属性加成
        Effect3 = get_addition_effect(GoodsInfo),
        %% 装备镶嵌加成
        Effect4 = count_inlay_effect(GoodsInfo),
        %% 注灵加成
        Effect5 = get_reiki_effect(GoodsInfo),
        sum_effect([BaseEffect, Effect2, Effect3, Effect4, Effect5]);
    true ->
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end.

get_reiki_effect(GoodsInfo) ->
    if
        GoodsInfo#goods.reiki_value =/= [] ->
            [AttributeId, Value] = GoodsInfo#goods.reiki_value,
            sum_effect([get_effect(A, V) || {_, A, V, _} <- [{?GOODS_ATTRIBUTE_REIKI, AttributeId, Value, 0}]]);
        true ->
            NewGoodsInfo = lib_equip_reiki:get_goods_reiki(GoodsInfo),
            if
                NewGoodsInfo#goods.reiki_value =/= [] ->
                    [AttributeId, Value] = NewGoodsInfo#goods.reiki_value,
                    sum_effect([get_effect(A, V) || {_, A, V, _} <- [{?GOODS_ATTRIBUTE_REIKI, AttributeId, Value, 0}]]);
                true ->
                    sum_effect([])
            end
    end.

get_reiki_attribute(GoodsInfo) ->
    if
        GoodsInfo#goods.reiki_value =/= [] ->
            [AttributeId, Value] = GoodsInfo#goods.reiki_value,
            [{?GOODS_ATTRIBUTE_REIKI, AttributeId, Value, 0}];
        true ->
            NewGoodsInfo = lib_equip_reiki:get_goods_reiki(GoodsInfo),
            if
                NewGoodsInfo#goods.reiki_value =/= [] ->
                    [AttributeId, Value] = NewGoodsInfo#goods.reiki_value,
                    [{?GOODS_ATTRIBUTE_REIKI, AttributeId, Value, 0}];
                true ->
                    []
            end
    end.

%% 计算装备镶嵌加成
count_inlay_effect(GoodsInfo) ->
    AttributeList = get_inlay_attribute(GoodsInfo),
    sum_effect([get_effect(AttributeId, Value) || {_, AttributeId, Value, _} <- AttributeList]).

%% 取基础值,原始属性+原始属性*品质加成+进阶属性*(1+强化等级%)
count_base_effect(GoodsInfo) ->
    %% 装备原始属性
    Effect = get_effect_by_goods(GoodsInfo),
    %% 装备品质加成：原始属性*品质加成
    Effect1 = count_prefix_effect(GoodsInfo),
    %% 装备进阶前缀加成:进阶属性*(1+强化等级%)
    Effect2 = count_first_prefix_effect(GoodsInfo),
    %% 基础值
    sum_effect([Effect, Effect1, Effect2]).

%% 计算装备战斗力
count_goods_power(GoodsInfo, _AttributeList, PlayerCareer) ->
    % io:format("AttributeList:~p~n", [AttributeList]),
    % %% 装备原始属性
    % Effect = get_effect_by_goods(GoodsInfo),
    % %% 装备品质前缀加成
    % Effect1 = count_prefix_effect(GoodsInfo),
    % %% 装备进阶前缀加成
    % Effect2 = count_first_prefix_effect(GoodsInfo),
    % [Hp1, _Mp1, Att1, Def1, Hit1, Dodge1, Crit1, Ten1, Forza1, Agile1, Wit1, Thew1, Fire1, Ice1, Drug1 | _]
    % = sum_effect([Effect, Effect1, Effect2]),
    % %% 装备属性
    % [Hp2, _Mp2, Att2, Def2, Hit2, Dodge2, Crit2, Ten2, Forza2, Agile2, Wit2, Thew2, Fire2, Ice2, Drug2 | _]
    % = sum_effect([get_effect(AttributeId, Value) || {AttributeType, AttributeId, Value, _Star} <- AttributeList, AttributeType =/= ?GOODS_ATTRIBUTE_TYPE_STREN_REWARD, AttributeId > 0, AttributeId =< 16, Value > 0]),
    % %% 一级属性转化为二级属性
    % [Hp3, _Mp3, Att3, Def3, Hit3, Dodge3, Crit3, Ten3] = one2two(Forza1+Forza2, Agile1+Agile2, Wit1+Wit2, Thew1+Thew2),
    %% 战斗力计算公式： (坚韧*31+气血*8+防御*38+闪避*38+命中*38+暴击*93+攻击*94+火抗性*13+冰抗性*13+毒抗性*13)/100
    %% 职业系数 唐门 1.107 逍遥 1.081 昆仑 1
    AttributeList = count_goods_effect(GoodsInfo),
    [Hp1, _Mp1, Att1, Def1, Hit1, Dodge1, Crit1, Ten1, Forza1, Agile1, Wit1, Thew1, Fire1, Ice1, Drug1 | _] = AttributeList,
    [Hp2, _Mp2, Att2, Def2, Hit2, Dodge2, Crit2, Ten2] = one2two(Forza1, Agile1, Wit1, Thew1, PlayerCareer),
    CHpLim = (Hp1 + Hp2),
    CAtt = (Att1 + Att2),
    CDef = (Def1 + Def2),
    CHit = (Hit1 + Hit2),
    CDodge = (Dodge1 + Dodge2),
    CCrit = (Crit1 + Crit2),
    CTen = (Ten1 + Ten2),
    CFire = (Fire1),
    CIce = (Ice1),
    CDrug = (Drug1),
    Combat_power = round(CTen*1.76 + CHpLim*0.26 + CDef*1.32 + CDodge*1.65 + CHit*1.37 + CCrit*3.52 + CAtt*3.97 + CFire*0.44 + CIce*0.44 + CDrug*0.44),
    Combat_power.

one2two(Forza, Agile, Wit, Thew, PlayerCareer) ->
    %% 职业收益
    [HpY, MpY, AttY, DefY, HitY, DodgeY] = case PlayerCareer of
        1 -> [1, 1, 1, 1, 2, 3];  %% 神将
        2 -> [1, 2, 1, 1, 2, 3];  %% 天尊
        _ -> [1, 1, 1, 1, 2, 3]   %% 罗刹
    end,
    Hp = Thew * 10 * HpY,
    Mp = Thew * 2 * MpY,
    Att = Forza * 1 * AttY,
    Def = Thew * 1 * DefY,
    Hit = Wit * 2.5 * HitY,
    Dodge = Agile * 2 * DodgeY,
    Crit = 0,
    Ten = 0,
    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten].

%% 取装备属性列表
get_goods_attribute(GoodsInfo) ->
    %% 基础值
    BaseEffect = count_base_effect(GoodsInfo),
    %% 装备强化
    AttributeList2 = get_stren_attribute(GoodsInfo, BaseEffect),
    %% 装备镶嵌
    AttributeList3 = get_inlay_attribute(GoodsInfo),
    %% 装备附加属性
    AttributeList4 = get_addition_attribute(GoodsInfo),
    %% 注灵
    AttributeList5 = get_reiki_attribute(GoodsInfo),
    lists:append([AttributeList2,AttributeList3,AttributeList4, AttributeList5]).

%% 取装备镶嵌属性列表
get_inlay_attribute(GoodsInfo) ->
    StoneList = [GoodsInfo#goods.hole1_goods, GoodsInfo#goods.hole2_goods, GoodsInfo#goods.hole3_goods],
    AttributeList = [get_attribute_by_type(StoneTypeId) || StoneTypeId <- StoneList, StoneTypeId > 0],
    [{?GOODS_ATTRIBUTE_TYPE_INLAY, AttributeId, Value, 0} || {AttributeId, Value} <- AttributeList].

%% 附加属性加成
get_addition_effect(GoodsInfo) ->
    AdditionList = get_addition_attribute(GoodsInfo),
    sum_effect([get_effect(AttributeId, Value) || {_, AttributeId, Value, _} <- AdditionList]).

%% 取装备附加属性列表
get_addition_attribute(GoodsInfo) ->
    % if
    %     length(GoodsInfo#goods.addition) < 10 ->
    %         Attr =  GoodsInfo#goods.addition;
    %     true ->
    %         case is_list(GoodsInfo#goods.addition) of
    %             true ->
    %                 [Old|_] = GoodsInfo#goods.addition,
    %                 [_|Attr] = tuple_to_list(Old);
    %             false ->
    %                 Attr = []
    %         end
    % end,
    Attr = GoodsInfo#goods.addition_1++GoodsInfo#goods.addition_2++GoodsInfo#goods.addition_3,
    [{?GOODS_ATTRIBUTE_TYPE_ADDITION, AttributeId, Value, Star} || {AttributeId, Star, Value, _, _, _} <- Attr, Value > 0].

%% 获得套装的归属信息,返回[{id,num,level,series}]
get_suit_belong([], L) ->
    L;
get_suit_belong([{SuitId, Num}|H], L) ->
    SuitAtt = data_suit:get_belong(SuitId),
    case SuitAtt =/= [] of
        true ->
            get_suit_belong(H, [{SuitId, Num, SuitAtt#suit_belong.level, SuitAtt#suit_belong.series}|L]);
        false ->
            get_suit_belong(H, L)
    end.
            
%% 取最小等级
get_min_level_suit([], {Id, Num, Level, Series}, N) ->
    case N >= Num of
        true ->
            All = N;
        false ->
            All = Num
    end,
    {Id, Num, Level, Series, All};
get_min_level_suit([{Id, Num, Level, Series}|H], {Id1, Num1, Level1, Series1}, N) ->
    case Level < Level1 of
        true ->
            if
                N =:= 0 ->
                    get_min_level_suit(H, {Id, Num, Level, Series}, Num+Num1+N);
                true ->
                    get_min_level_suit(H, {Id, Num, Level, Series}, Num+N)
            end;
        false ->
            if
                N =:= 0 ->
                    get_min_level_suit(H, {Id1, Num1, Level1, Series1}, Num+Num1+N);
                true ->
                    get_min_level_suit(H, {Id1, Num1, Level1, Series1}, Num+N)
            end
    end.
    
%% 计算套装加成
count_suit_effect(EquipSuit) ->
    BelongList = get_suit_belong(EquipSuit, []),
    %% 非人民币套装
    List1 = [{Id, Num, Level, Series} || {Id, Num, Level, Series} <- BelongList, Series =:= 1],
    %% 人民币套装
    List2 = [{Id, Num, Level, Series} || {Id, Num, Level, Series} <- BelongList, Series =:= 2],
    %% 武器套装
    List3 = [{Id, Num, Level, Series} || {Id, Num, Level, Series} <- BelongList, Series =:= 3],
    %io:format("List1 = ~p, List2 = ~p, List3 = ~p, equip=~p~n", [List1, List2, List3, EquipSuit]),
    case List1 =/= [] of
        true -> %%取最小等级
            [F|Rest1] = List1,
            MinLevel1 = get_min_level_suit(Rest1, F, 0);
        false ->
            MinLevel1 = 0
    end,    
    case List2 =/= [] of
        true -> %%取最小等级
            [S|Rest2] = List2,
            MinLevel2 = get_min_level_suit(Rest2, S, 0);
        false ->
            MinLevel2 = 0
    end,
    case List3 =/= [] of
        true -> %%取最小等级
            [R|Rest3] = List3,
            MinLevel3 = get_min_level_suit(Rest3, R, 0);
        false ->
            MinLevel3 = 0
    end,
    case MinLevel1 =/= 0 of
        true ->
            MinList1 = get_suit_attribute(MinLevel1);
        false ->
            MinList1 = []
    end,
    case MinLevel2 =/= 0 of
        true ->
            MinList2 = get_suit_attribute(MinLevel2);
        false ->
            MinList2 = []
    end,
    case MinLevel3 =/= 0 of
        true ->
            MinList3 = get_suit_attribute(MinLevel3);
        false ->
            MinList3 = []
    end,
    sum_effect([get_effect(AttributeId, Value) || {AttributeId, Value} <- MinList1 ++ MinList2 ++ MinList3]).
    
%% 取装备套装属性
get_suit_attribute({SuitId, _SuitNum, _Level, _Series, Num}) ->
    Attribute = data_suit:get_attribute(SuitId, Num),
    %io:format("get_suit_attribute = ~p, SuitId=~p, SuitNum=~p~n", [Attribute, SuitId, Num]),
    case Attribute =/= [] of
        true ->
            Attribute#suit_attribute.value_type;
        false ->        %% 后台只有2，4，6，3时算2
            Attribute1 = data_suit:get_attribute(SuitId, Num - 1),
            case Attribute1 =/= [] of
                true ->
                    Attribute1#suit_attribute.value_type;
                false ->
                    []
            end
    end.

%% 计算进阶前缀加成 进阶配置属性*(强化等级/100)
count_first_prefix_effect(GoodsInfo) ->
    %% 进阶对基础属性的加成为0
    AttributeList = get_first_prefix_attribute(GoodsInfo),
    %%保底值，有值 进阶属性*(强化等级%)
    PrefixLimit = [{?GOODS_ATTRIBUTE_TYPE_PREFIX, AttributeId1, round(Value1*(GoodsInfo#goods.stren/100)), 0} || {AttributeId1, Value1} <- data_equip:get_quality_limit(1, GoodsInfo#goods.equip_type, GoodsInfo#goods.first_prefix)],
    AttributeList2 = match_attr_type(?STREN_TYPE, GoodsInfo, PrefixLimit, []),
    sum_effect([get_effect(AttributeId, Value) || {_, AttributeId, Value, _} <- AttributeList ++ AttributeList2]).

%% 计算品质前缀加成
count_prefix_effect(GoodsInfo) ->
    AttributeList = get_prefix_attribute(GoodsInfo),
    %%保底值为0,所以该值属性为0
    PrefixLimit = [{?GOODS_ATTRIBUTE_TYPE_PREFIX, AttributeId1, Value1, 0} || {AttributeId1, Value1} <- data_equip:get_quality_limit(2, GoodsInfo#goods.equip_type, GoodsInfo#goods.prefix)],
    AttributeList2 = match_attr_type(?STREN_TYPE, GoodsInfo, PrefixLimit, []),
    sum_effect([get_effect(AttributeId, Value) || {_, AttributeId, Value, _} <- AttributeList ++ AttributeList2]).

%% 取装备进阶前缀属性列表，该值为0
get_first_prefix_attribute(GoodsInfo) ->
    if  GoodsInfo#goods.first_prefix > 0 ->
            PFactor = get_prefix_main_factor(1, GoodsInfo#goods.equip_type, GoodsInfo#goods.prefix),
            [{?GOODS_ATTRIBUTE_TYPE_PREFIX, AttributeId, Value * PFactor, 0} || {AttributeId, Value} <- get_attribute_by_goods(GoodsInfo)];
        true -> []
    end.

%% 取装备品质前缀属性列表
get_prefix_attribute(GoodsInfo) ->
    if  GoodsInfo#goods.prefix > 0 ->
            PFactor = get_prefix_main_factor(2, GoodsInfo#goods.equip_type, GoodsInfo#goods.prefix),
            [{?GOODS_ATTRIBUTE_TYPE_PREFIX, AttributeId, Value * PFactor, 0} || {AttributeId, Value} <- get_attribute_by_goods(GoodsInfo)];
        
        true -> []
    end.

%% 计算装备强化加成
count_stren_effect(GoodsInfo, PrefixEffect) ->
    AttributeList = get_stren_attribute(GoodsInfo, PrefixEffect),
    sum_effect([get_effect(AttributeId, Value) || {_, AttributeId, Value, _} <- AttributeList]).

%% 取装备强化属性列表
get_stren_attribute(GoodsInfo, PrefixEffect) ->
    if  GoodsInfo#goods.stren > 0 ->
        case GoodsInfo#goods.subtype =/= 60 andalso GoodsInfo#goods.subtype =/= 61 andalso GoodsInfo#goods.subtype =/= 62 andalso GoodsInfo#goods.subtype =/= 63 andalso GoodsInfo#goods.subtype =/= 64 andalso GoodsInfo#goods.subtype =/= 65 of
            true ->
                %% SFactor 和AttibuteList1 都为0
                SFactor = get_stren_factor(GoodsInfo#goods.equip_type, GoodsInfo#goods.stren),
                AttributeList1 = [{?GOODS_ATTRIBUTE_TYPE_STREN, AttributeId, Value*SFactor, 0} || {AttributeId,Value} <- get_attribute_by_prefix_effect(PrefixEffect)],
                %% 强化奖励数值 强化属性*(1+品质加成)
                %% 品质加成系数
                PFactor = get_prefix_main_factor(2, GoodsInfo#goods.equip_type, GoodsInfo#goods.prefix),
                Attr = [{?GOODS_ATTRIBUTE_TYPE_STREN, AttributeId2, round(Value2*(1+PFactor)), 0} || {AttributeId2, Value2} <- data_equip:get_stren_limit(GoodsInfo#goods.equip_type, GoodsInfo#goods.stren)],
                AttributeList2 = match_attr_type(?STREN_TYPE, GoodsInfo, Attr, []),
                %% +7以上奖励 强化(1,9,1)有加成，其他为0
                Level = get_level(GoodsInfo#goods.level),
                AttributeList3 = calculate_value(data_equip:get_stren7_reward(GoodsInfo#goods.equip_type, GoodsInfo#goods.stren, Level), []),
                AttributeList1 ++ AttributeList2 ++ AttributeList3;
            false ->
                %% 时装强化
                FashionStren = data_fashion:get_fashion_stren(GoodsInfo#goods.stren),
                case FashionStren =/= [] of
                    true ->
                        %% 基础加成
                        AttriList1 = [{?GOODS_ATTRIBUTE_TYPE_STREN, AttrId, Value*FashionStren#fashion_stren.addition/100, 0} || {AttrId, Value} <- get_attribute_by_goods(GoodsInfo)],
                        %% 保底
                        AttriList2 = [{?GOODS_ATTRIBUTE_TYPE_STREN, 3, FashionStren#fashion_stren.att, 0}, {?GOODS_ATTRIBUTE_TYPE_STREN, 5, FashionStren#fashion_stren.hit, 0}, {?GOODS_ATTRIBUTE_TYPE_STREN, 7, FashionStren#fashion_stren.crite, 0}],
                        %% 百分比
                        AttriList3 = calculate_value(FashionStren#fashion_stren.percent, []),
                        AttriList = AttriList1 ++ AttriList2 ++ AttriList3;
                    false ->
                        AttriList = []
                end,
                AttriList
        end;
        true -> []
    end.

%% +7以上奖励/100
calculate_value([], L) ->
    L;
calculate_value([{AttributeId, Value}|T], L) ->
    if
        AttributeId > 50 andalso Value > 0 ->
            calculate_value(T, [{?GOODS_ATTRIBUTE_TYPE_STREN_REWARD, AttributeId, Value/100, 0}|L]);
        Value > 0 ->
            calculate_value(T, [{?GOODS_ATTRIBUTE_TYPE_STREN_REWARD, AttributeId, Value, 0}|L]);
        true ->
            calculate_value(T, L)
    end.

%% 强化保底匹配
match_attr_type([], _GoodsInfo, _Attr, L) ->
    L;
match_attr_type([H|T], GoodsInfo, Attr, L) ->
    if
        H =:= 1 ->
            case GoodsInfo#goods.hp > 0 of
                true ->
                    [L1] = [{?GOODS_ATTRIBUTE_TYPE_STREN, Id, Value, 0} || {_, Id, Value, _} <- Attr, Id =:= 1],
                    match_attr_type(T, GoodsInfo, Attr, [L1|L]);
                false ->
                    match_attr_type(T, GoodsInfo, Attr, L)
            end;
        H =:= 2 ->
             case GoodsInfo#goods.mp > 0 of
                true ->
                    [L2] = [{?GOODS_ATTRIBUTE_TYPE_STREN, Id, Value, 0} || {_, Id, Value, _} <- Attr, Id =:= 2],
                    match_attr_type(T, GoodsInfo, Attr, [L2|L]);
                false ->
                    match_attr_type(T, GoodsInfo, Attr, L)
            end;
         H =:= 3 ->
             case GoodsInfo#goods.att > 0 of
                true ->
                    [L3] = [{?GOODS_ATTRIBUTE_TYPE_STREN, Id, Value, 0} || {_, Id, Value, _} <- Attr, Id =:= 3],
                    match_attr_type(T, GoodsInfo, Attr, [L3|L]);
                false ->
                    match_attr_type(T, GoodsInfo, Attr, L)
            end;
         H =:= 4 ->
             case GoodsInfo#goods.def > 0 of
                true ->
                    [L4] = [{?GOODS_ATTRIBUTE_TYPE_STREN, Id, Value, 0} || {_, Id, Value, _} <- Attr, Id =:= 4],
                    match_attr_type(T, GoodsInfo, Attr, [L4|L]);
                false ->
                    match_attr_type(T, GoodsInfo, Attr, L)
            end;
         H =:= 5 ->
             case GoodsInfo#goods.hit > 0 of
                true ->
                    [L5] = [{?GOODS_ATTRIBUTE_TYPE_STREN, Id, Value, 0} || {_, Id, Value, _} <- Attr, Id =:= 5],
                    match_attr_type(T, GoodsInfo, Attr, [L5|L]);
                false ->
                    match_attr_type(T, GoodsInfo, Attr, L)
            end;
         H =:= 6 ->
             case GoodsInfo#goods.dodge > 0 of
                true ->
                    [L6] = [{?GOODS_ATTRIBUTE_TYPE_STREN, Id, Value, 0} || {_, Id, Value, _} <- Attr, Id =:= 6],
                    match_attr_type(T, GoodsInfo, Attr, [L6|L]);
                false ->
                    match_attr_type(T, GoodsInfo, Attr, L)
            end;
         H =:= 7 ->
             case GoodsInfo#goods.crit > 0 of
                true ->
                    [L7] = [{?GOODS_ATTRIBUTE_TYPE_STREN, Id, Value, 0} || {_, Id, Value, _} <- Attr, Id =:= 7],
                    match_attr_type(T, GoodsInfo, Attr, [L7|L]);
                false ->
                    match_attr_type(T, GoodsInfo, Attr, L)
            end;
         H =:= 8 ->
             case GoodsInfo#goods.ten > 0 of
                true ->
                    [L8] = [{?GOODS_ATTRIBUTE_TYPE_STREN, Id, Value, 0} || {_, Id, Value, _} <- Attr, Id =:= 8],
                    match_attr_type(T, GoodsInfo, Attr, [L8|L]);
                false ->
                    match_attr_type(T, GoodsInfo, Attr, L)
            end;
         H =:= 13 ->
             case GoodsInfo#goods.fire > 0 of
                true ->
                    [L13] = [{?GOODS_ATTRIBUTE_TYPE_STREN, Id, Value, 0} || {_, Id, Value, _} <- Attr, Id =:= 13],
                    match_attr_type(T, GoodsInfo, Attr, [L13|L]);
                false ->
                    match_attr_type(T, GoodsInfo, Attr, L)
            end;
         H =:= 14 ->
             case GoodsInfo#goods.ice > 0 of
                true ->
                    [L14] = [{?GOODS_ATTRIBUTE_TYPE_STREN, Id, Value, 0} || {_, Id, Value, _} <- Attr, Id =:= 14],
                    match_attr_type(T, GoodsInfo, Attr, [L14|L]);
                false ->
                    match_attr_type(T, GoodsInfo, Attr, L)
            end;
         H =:= 15 ->
             case GoodsInfo#goods.drug > 0 of
                true ->
                    [L15] = [{?GOODS_ATTRIBUTE_TYPE_STREN, Id, Value, 0} || {_, Id, Value, _} <- Attr, Id =:= 15],
                    match_attr_type(T, GoodsInfo, Attr, [L15|L]);
                false ->
                    match_attr_type(T, GoodsInfo, Attr, L)
            end;
        true ->
            match_attr_type(T, GoodsInfo, Attr, L)
    end.

%% 计算全身发光属性加成
count_shine_effect(Level, Stren7_num) ->
    AttributeList = get_shine_attribute(Level, Stren7_num),
    sum_effect([get_effect(AttributeId, Value) || {AttributeId, Value} <- AttributeList, Value > 0]).

%% 取全身发光属性列表
get_shine_attribute(Level, Stren7_num) ->
    L = get_level(Level),
    Stren = lib_goods:get_min_stren7_num2(Stren7_num),
    data_equip:get_whole_reward(L, Stren).

%% 时装套装加成
count_fashion_effect(Type, Num) ->
    AttributeList = data_fashion_change:get_suit_effect(Type, Num),
    %io:format("AttributeList = ~p~n", [{AttributeList}]),
    sum_effect([get_effect(AttributeId, Value) || {AttributeId, Value} <- AttributeList, Value > 0]).

%% 随机生成掉落的前缀
rand_prefix(MaxPrefix) ->
    if  MaxPrefix =:= 3 ->
            Rand = util:rand(1, 100),
            if  Rand > 90 -> 3;
                Rand > 65 -> 2;
                Rand > 30 -> 1;
                true -> 0
            end;
        MaxPrefix > 0 ->
            util:rand(0, MaxPrefix);
        true -> 0
    end.

%% 装备前缀主属性加成系数,品质有值，进阶为0
get_prefix_main_factor(PrefixType, EquipType, Prefix) ->
    data_equip:get_quality_factor(PrefixType, EquipType, Prefix)/100.
    
%% 装备强化加成系数,配置为0
get_stren_factor(EquipType, Stren) ->
    data_equip:get_stren_factor(EquipType, Stren)/100.

get_attribute_by_type(GoodsTypeInfo) when is_record(GoodsTypeInfo, ets_goods_type) ->
    if  GoodsTypeInfo#ets_goods_type.hp > 0       -> {1, GoodsTypeInfo#ets_goods_type.hp};
        GoodsTypeInfo#ets_goods_type.mp > 0       -> {2, GoodsTypeInfo#ets_goods_type.mp};
        GoodsTypeInfo#ets_goods_type.att > 0      -> {3, GoodsTypeInfo#ets_goods_type.att};
        GoodsTypeInfo#ets_goods_type.def > 0      -> {4, GoodsTypeInfo#ets_goods_type.def};
        GoodsTypeInfo#ets_goods_type.hit > 0      -> {5, GoodsTypeInfo#ets_goods_type.hit};
        GoodsTypeInfo#ets_goods_type.dodge > 0    -> {6, GoodsTypeInfo#ets_goods_type.dodge};
        GoodsTypeInfo#ets_goods_type.crit > 0     -> {7, GoodsTypeInfo#ets_goods_type.crit};
        GoodsTypeInfo#ets_goods_type.ten > 0      -> {8, GoodsTypeInfo#ets_goods_type.ten};
        true                                        -> {0, 0}
    end;
get_attribute_by_type(TypeId) when is_integer(TypeId) ->
    get_attribute_by_type(data_goods_type:get(TypeId));
get_attribute_by_type(_) ->
    {0, 0}.

get_effect_by_goods(GoodsInfo) ->
%    if
%        GoodsInfo#goods.reiki_value =:= [] ->
%          Att = GoodsInfo#goods.att;
%        true ->
%            [_Type, Value] = GoodsInfo#goods.reiki_value,
%            Att = GoodsInfo#goods.att + Value
%    end,
    [ GoodsInfo#goods.hp,
      GoodsInfo#goods.mp,
      GoodsInfo#goods.att,
      GoodsInfo#goods.def,
      GoodsInfo#goods.hit,
      GoodsInfo#goods.dodge,
      GoodsInfo#goods.crit,
      GoodsInfo#goods.ten,
      0, 0, 0, 0, GoodsInfo#goods.fire, GoodsInfo#goods.ice, GoodsInfo#goods.drug, 0, 0, 0, 0, 0, 0, 0, 0 ].

get_attribute_by_goods(GoodsInfo) ->
    plus_attribute(get_effect_ids(), get_effect_by_goods(GoodsInfo)).

get_attribute_by_prefix_effect(Effect) ->
    plus_attribute(get_effect_ids(), Effect).

get_effect_ids() ->
    [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,51,52,53,54,55,56,57,58].

%% get_effect_id([Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Forza, Agile, Wit, Thews, Fire, Ice, Drug, HpRatio, MpRatio, AttRatio, DefRatio, HitRatio, DodgeRatio, CritRatio, TenRatio]) ->
%%     if  Hp > 0              -> 1;
%%         Mp > 0              -> 2;
%%         Att > 0             -> 3;
%%         Def > 0             -> 4;
%%         Hit > 0             -> 5;
%%         Dodge > 0           -> 6;
%%         Crit > 0            -> 7;
%%         Ten > 0             -> 8;
%%         Forza > 0           -> 9;
%%         Agile > 0           -> 10;
%%         Wit > 0             -> 11;
%%         Thews > 0           -> 12;
%%         Fire > 0            -> 13;
%%         Ice > 0             -> 14;
%%         Drug > 0            -> 15;
%%         HpRatio > 0         -> 51;
%%         MpRatio > 0         -> 52;
%%         AttRatio > 0        -> 53;
%%         DefRatio > 0        -> 54;
%%         HitRatio > 0        -> 55;
%%         DodgeRatio > 0      -> 56;
%%         CritRatio > 0       -> 57;
%%         TenRatio > 0        -> 58;
%%         true                -> 0
%%     end.

%% get_effect_value([Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Forza, Agile, Wit, Thews, Fire, Ice, Drug, HpRatio, MpRatio, AttRatio, DefRatio, HitRatio, DodgeRatio, CritRatio, TenRatio]) ->
%%     if  Hp > 0              -> Hp;
%%         Mp > 0              -> Mp;
%%         Att > 0             -> Att;
%%         Def > 0             -> Def;
%%         Hit > 0             -> Hit;
%%         Dodge > 0           -> Dodge;
%%         Crit > 0            -> Crit;
%%         Ten > 0             -> Ten;
%%         Forza > 0           -> Forza;
%%         Agile > 0           -> Agile;
%%         Wit > 0             -> Wit;
%%         Thews > 0           -> Thews;
%%         Fire > 0            -> Fire;
%%         Ice > 0             -> Ice;
%%         Drug > 0            -> Drug;
%%         HpRatio > 0         -> HpRatio;
%%         MpRatio > 0         -> MpRatio;
%%         AttRatio > 0        -> AttRatio;
%%         DefRatio > 0        -> DefRatio;
%%         HitRatio > 0        -> HitRatio;
%%         DodgeRatio > 0      -> DodgeRatio;
%%         CritRatio > 0       -> CritRatio;
%%         TenRatio > 0        -> TenRatio;
%%         true                 -> 0
%%     end.
    
%% [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Forza, Agile, Wit, Thews, Fire, Ice, Drug, 
%% HpRatio, MpRatio, AttRatio, DefRatio, HitRatio, DodgeRatio, CritRatio, TenRatio, IceRatio, FireRatio, DrugRatio]
get_effect(AttributeId, Value) ->
    case AttributeId of
        1  -> [Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        2  -> [0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        3  -> [0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        4  -> [0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        5  -> [0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        6  -> [0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        7  -> [0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        8  -> [0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        9  -> [0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        10 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        11 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        12 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        13 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        14 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        15 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        16 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, Value, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		18 -> [0, 0, 0, 0, 0, 0, 0, 0, Value, Value, Value, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        51 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        52 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        53 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0];
        54 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0];
        55 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0];
        56 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0];
        57 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0];
        58 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0];
        66 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, Value, Value];
        67 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0];
        69 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, Value, Value, Value, Value, Value, Value, Value, Value, Value, Value];
		%% 蝴蝶谷使用：80加速符, 81减速符, 82双倍积分符
		%% 变身功能使用 97
		?FIGURE_BUFF_ATTID -> figure_buff(Value);
        _  -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end.

%% [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Forza, Agile, Wit, Thews, Fire, Ice, Drug
%%, HpRatio, MpRatio, AttRatio, DefRatio, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio]
get_effect2(AttributeId, Value) ->
    case AttributeId of
        1  -> [Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        2  -> [0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        3  -> [0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        4  -> [0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        5  -> [0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        6  -> [0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        7  -> [0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        8  -> [0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        9  -> [0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        10 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        11 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        12 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        13 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        14 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        15 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        16 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, Value, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		18 -> [0, 0, 0, 0, 0, 0, 0, 0, Value, Value, Value, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        51 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        52 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        53 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0];
        54 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0];
        55 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0];
        56 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0];
        57 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0];
        58 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0];
        63 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0];
        64 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0];
        65 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value];
        67 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, 0, 0, 0, 0, 0, 0, 0, 0];
        69 -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, Value, Value, Value, Value, Value, Value, Value, Value, Value, Value, Value];
		%% 变身功能使用 97
		?FIGURE_BUFF_ATTID -> figure_buff(Value);
        _  -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end.

sum_effect(EffectList) ->
    sum_effect(EffectList, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]).

sum_effect([L|T], D) ->
    sum_effect(T, plus_effect(L, D));
sum_effect([], D) -> D.

plus_effect([L1|T1], [L2|T2]) ->
    [L1+L2|plus_effect(T1,T2)];
plus_effect([L1|T1], []) ->
    [L1|plus_effect(T1,[])];
plus_effect([], _) -> [].

plus_attribute([L1|T1], [L2|T2]) ->
    case L2 > 0 of
        true ->  [{L1,L2}|plus_attribute(T1,T2)];
        false -> plus_attribute(T1,T2)
    end;
plus_attribute(_, []) -> [];
plus_attribute([], _) -> [].

% 镶嵌宝石的属性类型ID
get_inlay_attribute_by_goods(StoneInfo) ->
    case is_record(StoneInfo, goods) of
        true when StoneInfo#goods.hp > 0    -> 1;
        true when StoneInfo#goods.mp > 0    -> 2;
        true when StoneInfo#goods.att > 0   -> 3;
        true when StoneInfo#goods.def > 0   -> 4;
        true when StoneInfo#goods.hit > 0   -> 5;
        true when StoneInfo#goods.dodge > 0 -> 6;
        true when StoneInfo#goods.crit > 0  -> 7;
        true when StoneInfo#goods.ten > 0   -> 8;
        _ -> 0
    end.

get_inlay_attribute_by_type(GoodsTypeInfo) ->
    case is_record(GoodsTypeInfo, ets_goods_type) of
        true when GoodsTypeInfo#ets_goods_type.hp > 0    -> 1;
        true when GoodsTypeInfo#ets_goods_type.mp > 0    -> 2;
        true when GoodsTypeInfo#ets_goods_type.att > 0   -> 3;
        true when GoodsTypeInfo#ets_goods_type.def > 0   -> 4;
        true when GoodsTypeInfo#ets_goods_type.hit > 0   -> 5;
        true when GoodsTypeInfo#ets_goods_type.dodge > 0 -> 6;
        true when GoodsTypeInfo#ets_goods_type.crit > 0  -> 7;
        true when GoodsTypeInfo#ets_goods_type.ten > 0   -> 8;
        _ -> 0
    end.

%%默认装备格子位置, 0 默认位置，1 武器，2 头盔，3 衣服，4 裤子， 5 鞋子， 6 腰带，7 手套，8 护符一，9 护符二，10 项链，11 戒指一，12 戒指二，13 坐骑，14 衣服时装，15 结婚戒指，16 武器时装，17 饰品时装
get_equip_cell(Subtype) ->
    case Subtype of
        10 -> 1;    % 武器
        20 -> 2;    % 头盔
        21 -> 3;    % 衣服
        22 -> 4;    % 裤子
        23 -> 5;    % 鞋子
        24 -> 6;    % 腰带
        25 -> 7;    % 手套
        30 -> 8;    % 护符一
        33 -> 10;   % 项链
        32 -> 11;   % 戒指一
        60 -> 14;   % 衣服时装
        70 -> 15;   % 结婚戒指
        61 -> 16;   % 武器时装
        62 -> 17;   % 饰品时装
        63 -> 18;   % 头饰时装
        64 -> 19;   % 尾饰时装
        65 -> 20;   % 戒指时装
        80 -> 13;   % 跨服勋章
        _ ->
            Subtype
    end.

%%坐骑默认装备格子位置, 0 默认位置，1 马鞍，2 缰绳
get_mount_equip_cell(Subtype) ->
    case Subtype of
        40 -> 1;    % 马鞍
        41 -> 2     % 缰绳
    end.

%% 取价格类型
get_price_type(Type) ->
    case Type of
        1 -> coin;      % 铜钱
        2 -> silver;    % 银两
        3 -> gold;      % 金币
        4 -> bcoin;     % 绑定的铜钱
        _ -> coin       % 铜钱
    end.

%% 取消费类型
get_consume_type(Type) ->
    case Type of
        skill -> 1;                     % 技能升级
        meridian_upMer -> 2;            % 元神升级
        mind_up -> 3;                   % 境界提升
        pl_refresh -> 4;                % 平乱刷新
        refresh_biao_color -> 5;        % 美女刷新
        goods_pay -> 6;                 % 商城购买
        break_egg -> 7;                 % 宠物砸蛋
        forg -> 8;                      % 炼炉消耗
        revive -> 9;                    % 原地复活
        sell_fee -> 10;                 % 市场挂售
        practice_unline -> 11;          % 离线挂机
        func_heap -> 12;                % 功能累积
        pet_enhance -> 13;              % 成长提升
        guild_donate -> 14;             % 帮派捐献
        guild_party -> 15;              % 召开仙宴
        sl_refresh -> 16;               % 试炼刷新
        chat_send_pos -> 17;            % 发送坐标 
        goods_stren -> 18;              % 装备强化
        attribute_wash -> 19;           % 属性洗炼
        goods_resolve -> 20;            % 装备分解
        goods_up_prefix -> 21;          % 品质提升
        equip_upgrade -> 22;            % 装备升级
        equip_inherit -> 23;            % 装备继承
        equip_compose -> 24;            % 装备融合
        weapon_compose -> 25;           % 装备精炼
        stone_compose -> 26;            % 宝石合成
        stone_inlay -> 27;              % 宝石镶嵌
        stone_backout -> 28;            % 宝石拆除
        %% 元宝
        shop_pay -> 29;                 % npc购买
        box_open -> 30;                 % 淘宝
        pet_practice -> 31;             % 宠物潜能
        xlqx_refresh -> 32;             % 仙侣刷新
        hb_refresh -> 33;               % 皇榜刷新        
        task_proxy_finish -> 34;        % 立即完成任务
        reborn -> 35;                   % 原地复活
        guild_house_upgrade -> 36;      % 厢房升级
        bless_gift -> 37;               % 好友回赠

        find_lucky -> 38;               % 寻找唐僧
        lunar -> 39;                    % 生肖大奖
        mount_stren -> 40;              % 坐骑强化
        derive_pet -> 41;               % 宠物继承
        pet_pay -> 42;                  % 宠物召唤
        guild_create -> 43;             % 创建帮派
        goods_mend -> 44;               % 修理
        pay_secret -> 45;               % 神秘商店购买
        refresh_secret -> 46;           % 神秘商店刷新
        sell_pay -> 47;                 % 购买挂售物品
        sell_up -> 48;                  % 挂售金钱
        guild_rename -> 49;             % 帮派改名
        guild_join_bless -> 50;         % 入帮祝福
        guild_material -> 51;           % 元宝兑换帮派财富
        fortune_refresh_task -> 52;     % 立即刷新运势任务
        fortune_finish_task -> 53;      % 立即完成运势任务
		fortune_refresh_gold -> 54;     % 元宝刷新运势任务
        fortune_refresh_coin -> 55;     % 铜币刷新运势任务
        xlqy_refresh -> 56;             % 仙侣奇缘刷新
        xlqy_item -> 57;                % 仙侣奇缘送物品
        xlqy_bang -> 58;                % 仙侣奇缘棒棒糖
		xlqy_flower -> 59;              % 仙侣奇缘种花游戏奖励
        gift_exchange -> 60;            % 礼包兑换
        send_gift -> 61;                % 送东西
        pay_vip_upgrade -> 62;          % 购买VIP绑定卡
        extend_bag -> 63;               % 扩展背包
        goods_extend_guild -> 64;       % 扩展帮派仓库
        del_sell_list -> 65;            % 删除交易列表
        guild_animal -> 66;             % 帮派神兽
        outline_jy -> 67;               % 景阳
        send_mail -> 68;                % 发邮件
        guil_mail -> 69;                % 发帮派邮件
        buy_fee -> 70;                  % 求购物品
        buy_up -> 71;                   % 求购物品上架
        task_cumulate -> 72;            % 元宝领取任务
        meridian_upGen -> 73;           % 升级根骨
        meridian_clearMerCD -> 74;      % 加速升级元神
        task_proxy -> 75;               % 任务委托
        offline_upspeed -> 76;          % 离线挂机加速
        get_sit_offline_exp -> 77;      % 挂机经验
        equip_advanced -> 78;           % 装备进阶
        nine_secret -> 79;              % 九重天神秘商店
        kill -> 80;                     % 被杀或红名
        arena_exchange -> 81;           % 竞技场积分消费
        battle_exchange -> 82;          % 帮战积分兑换  
        tree -> 83;                     % 摇钱树,消耗元宝
        marriage -> 84;                 % 结婚登记，消耗非绑定铜币
        wedding -> 85;                  % 举办婚礼，消耗元宝
        wedding_bless -> 86;            % 结婚时宾客祝福
        bride -> 87;                    % 新郎新娘：获得非绑定元宝或者非绑定铜币
        denaturation -> 88;             % 变性
        pay_invitation -> 89;           % 元宝买喜帖
        parade_pay -> 90;               % 巡游购买
        early_parade -> 91;             % 预约巡游消费元宝
        mount_star_upgrade -> 92;       % 坐骑进阶升星
        mount_upfly -> 93;              % 坐骑升星
        divorce -> 94;                  % 离婚
        tower_doube_drop -> 95;         % 双倍掉落装备副本        
        city_war -> 96;                 % 城战捐献铜币
        flyer_train -> 97;              % 飞行器训练
        flyer_upgrade_star -> 98;       % 飞行器升星
        flyer_backward -> 99;           % 飞行器回退
        send_festival_card -> 101;      % 送贺卡
        pet_refresh_skill -> 102;       % 宠物技能刷新
        pet_copy_skill -> 103;           % 宠物技能购买
        city_war_donate -> 104;         % 攻城战铜币捐献
        vip_dun_buy_num -> 105;         % VIP副本购买骰子次数
        change_sex -> 106;              % 变性消耗
        equip_extraction_goods -> 107;  % 装备副本消耗抽取物品
        mount_up_quality -> 108;        % 坐骑资质培养
        _ -> 100                        % 其它类型
    end.

%% 取货币生产类型
get_produce_type(Type) ->
    case Type of
        mail_attachment -> 1;           % 邮件附件
        goods_sell -> 2;                % 出售物品
        goods_drop -> 3;                % 拣取物品
        goods_use ->  4;                % 使用物品
        sell_pay -> 5;                  % 购买挂售的金钱
        sell_cancel -> 6;               % 取消挂售的金钱
        wtb_pay -> 7;                   % 出售求购的物品
        wtb_cancel -> 8;                % 取消求购
        task ->  9;                     % 任务奖励
        coin_dungeon -> 10;             % 铜钱副本产出
        gift -> 11;                     % 礼包获得
        collect_game -> 12;             % 收藏游戏
        guild_weal -> 13;               % 帮派福利
        god_party_collect -> 14;        % 仙宴采集
        red_envelope -> 15;             % 红包
        activity -> 16;                 % 活跃度
        vip -> 17;                      % vip福利
        lunar -> 18;                    % 生肖大奖
        find_lucky -> 19;               % 唐僧大奖
        level_forward -> 20;            % 升级向前冲
        pay -> 21;                      % 充值
        achieve -> 22;                  % 领取成就奖励
        tree -> 23;                     % 摇钱树,获得绑定铜币
        login -> 24;                    % 登录器登录奖励
        get_gold -> 25;                 % 使用元宝道具获得元宝
        vip_pdc -> 26;                  % vip等级特权产出，绑定元宝和绑定铜币
        vip_dun -> 27;                  % vip副本产出
        equip_zhuan_pan_coin -> 28;     % 装备副本转盘产出铜钱     
        equip_zhuan_pan_bgold -> 29;    % 装备副本转盘产出绑定元宝
        guild_furnaceback -> 30;        % 帮派神炉返利
        _ when is_number(Type) -> Type;
        _ -> 0
    end.

%% 物品消耗类型
get_goods_passoff_type(Type) ->
    case Type of
        throw -> 1;                     %背包丢弃
        goods_use -> 2;                 %背包使用,技能使用
        npc_sell -> 3;                  %NPC出售
        npc_exchange -> 4;              %NPC兑换
        pet_grow -> 5;                  %成长提升
        pet_practice -> 6;              %潜能修行
        pet_feed -> 7;                  %宠物喂养
        mind_up -> 8;                   %境界提升
        task -> 9;                      %任务回收
        talk -> 10;                     %世界喊话
        create_guild -> 11;             %创建帮派
        guild_donate -> 12;             %帮派捐献
        storage_throw -> 13;            %仓库销毁
        flower -> 14;                   %赠送鲜花
        beauty_refresh -> 15;           %美女刷新
        box_exchange -> 16;             %淘宝兑换
        _ -> 50                         %其它
    end.

%% 物品产出类型
get_goods_produce_type(Type) ->
    case Type of
        mon_drop -> 1;                  %% 怪物掉落
	    turntable -> 2;			        %% 唐僧产出
        wb_sea -> 3;                    %% 无边海功能产出
        vip -> 4;                       %% vip领取
        box_exchange -> 5;              %% 淘宝兑换
        story_dungeon -> 6;             %% 封魔录挂机
        _ -> 0
    end.

%% 帮派仓库升级所需材料 [铜币数, 帮派建设卡数]
get_extend_guild(GuildLevel) ->
    case GuildLevel of
        2 -> [500000, 50];
        3 -> [1000000, 100];
        4 -> [2000000, 200];
        5 -> [3000000, 300];
        6 -> [4000000, 400];
        7 -> [5000000, 500];
        8 -> [6000000, 600];
        9 -> [8000000, 800];
        10 -> [10000000, 1000];
        _ -> [0, 0]
    end.

%% 背包仓库扩展栏
get_extend_num(GoodsTypeId) ->
    case GoodsTypeId of
        222001 -> 1;    %% 1级背包栏
        222002 -> 6;    %% 6级背包栏
        222101 -> 1;    %% 1级仓库栏
        222102 -> 6;    %% 6级背包栏
        _ -> 0
    end.

%% 取赠送物品信息  [GoodsTypeId,Coin,Gold] | []
get_send_gift(Type, SubType) ->
    case Type of
        1 ->
            case SubType of
                1 -> [521301,8000,0];
                2 -> [521304,0,5];
                _ -> []
            end;
        _ -> []
    end.

%% 变身
figure_buff(Value)->
	ValueInt = round(Value),
	case data_figure:get(ValueInt) of
		[] ->
			[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		Figure ->
			[Figure#figure.hp_lim 		%% Hp
			, 0
			, Figure#figure.att		%% Att
			, Figure#figure.def		%% Def
			, Figure#figure.hit		%% Hit
			, Figure#figure.dodge		%% Dodge
			, Figure#figure.crit		%% Crit
			, Figure#figure.ten			%% Ten
			, 0		%% Forza
			, 0		%% Agile
			, 0		%% Wit
			, 0		%% Thews
			, Figure#figure.fire		%% Fire
			, Figure#figure.ice			%% Ice
			, Figure#figure.drug		%% Drug
			, 0		%% HpRatio
			, 0		%% MpRatio
			, 0		%% AttRatio
			, 0		%% DefRatio
			, 0		%% HitRatio
			, 0		%% DodgeRatio
			, 0		%% CritRatio
			, 0		%% TenRatio
			, 0		%% IceRatio
			, 0		%% FireRatio
			, 0		%% DrugRatio
			]
	end.
	
		
		
		
		
		
		
		
		
		
		
		
		
		
