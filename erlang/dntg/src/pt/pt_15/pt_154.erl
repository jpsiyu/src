%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-4-14
%% Description: 装备系统
%% --------------------------------------------------------
-module(pt_154).
-export([write/2, read/2]).
-include("goods.hrl").
-include("fashion.hrl").

%% C -> S
%%强化
read(15400, <<EquipId:32, StoneListLen:16, StoneListBin/binary>>) ->
    {<< LuckyId:32>>, StoneList} = pt:read_id_num_list(StoneListBin, [], StoneListLen),
    {ok, [EquipId, StoneList, LuckyId]};

%% 装备品质升级
read(15402, <<GoodsId:32, StoneTypeId:32, PrefixType:8, Num:16, Bin/binary>>) ->
    {_, StoneList} = pt:read_id_num_list(Bin, [], Num),
    %io:format("upgrade ~p~n", [{GoodsId, StoneTypeId, StoneList}]),
    {ok, [GoodsId, StoneTypeId, PrefixType, StoneList]};

%% 装备精炼
%%read(15406, <<GoodsId:32, Num:16, Bin/binary>>) ->
%%    {Rest, StoneList} = pt:read_id_num_list(Bin, [], Num),
%%    case Rest of
%%        <<Num2:16, Bin2/binary>> -> 
%%            {_, ChipList} = pt:read_id_num_list(Bin2, [], Num2);
%%        _ -> ChipList = []
%%    end,
%%    %io:format("11 ~p~n", [{GoodsId, StoneList, ChipList}]),
%%    {ok, [GoodsId, StoneList, ChipList]};

%% 装备继承
read(15408, <<LowId:32, HighId:32, Num:16, Bin/binary>>) ->
    {_Rest, StuffList} = pt:read_id_num_list(Bin, [], Num),
    %io:format("15408 ~p~n", [{LowId, HighId, StuffList}]),
    {ok, [LowId, HighId, StuffList]};

%% 装备升级
read(15410, <<GoodsId:32, RuneId:32, Num:16, Bin/binary>>) ->
    {Rest, TripList} = pt:read_id_num_list(Bin, [], Num),
    case Rest of
        <<Num2:16, Bin2/binary>> ->
            {Rest2, StoneList} = pt:read_id_num_list(Bin2, [], Num2),
            case Rest2 of
                <<Num3:16, Bin3/binary>> ->
                    {_, IronList} = pt:read_id_num_list(Bin3, [], Num3);
                _ ->
                    IronList = []
            end;
        _ ->
            StoneList = [],
            IronList = []
    end,
    %io:format("22 ~p~n", [{GoodsId, RuneId, TripList, StoneList, IronList}]),
    {ok, [GoodsId, RuneId, TripList, StoneList, IronList]};

%% 装备洗炼
read(15412, <<GoodsId:32, Time:16, Grade:8, Num:16, Bin/binary>>) ->
    {Rest1, StoneList1} = pt:read_id_num_list(Bin, [], Num),
    case Rest1 of
        <<LockNum:16, Bin1/binary>> ->
            case LockNum > 0 of
                true ->
                    {Rest2, LockList} = read_lock_list(Bin1, [], LockNum);
                false ->
                    Rest2 = [],
                    LockList = []
            end,
            case Rest2 of
                <<Num2:16, Bin2/binary>> ->  
                    {_, _StoneList} = pt:read_id_num_list(Bin2, [], Num2);
                _ -> 
                    _StoneList = []
            end;
        _ ->
            LockList = [],
            _StoneList = []
    end,
    Time1 = case Time > 1 of
                true ->
                    Time;
                false ->
                    1
            end,
    {ok, [GoodsId, Time1, Grade, StoneList1, LockList]};

%% 选择洗炼属性
read(15413, <<GoodsId:32, Pos:16>>) ->
    {ok, [GoodsId, Pos]};

%% 获取装备洗炼信息
read(15414, <<GoodsId:32>>) ->
    {ok, GoodsId}; 

%% 隐藏时装或挂挂饰 1:隐藏, 0:显示
read(15415, <<GoodsId:32, Show:8>>) ->
    {ok, [GoodsId, Show]};

%% 装备进阶
read(15416, <<GoodsId:32, Num:16, Bin/binary>>) ->
    {Rest, StoneList} = pt:read_id_num_list(Bin, [], Num),
    case Rest of
        <<Num2:16, Bin2/binary>> -> 
            {_, ChipList} = pt:read_id_num_list(Bin2, [], Num2);
        _ -> ChipList = []
    end,
    %io:format("11 ~p~n", [{GoodsId, StoneList, ChipList}]),
    {ok, [GoodsId, StoneList, ChipList]};

%% 取变换信息
read(15417, _R) ->
    {ok, change_info};

%% 取衣橱列表
read(15418, <<Pos:8>>) ->
    {ok, Pos};

read(15419, <<GoodsId:32, Pos:8>>) ->
    {ok, [Pos, GoodsId]};

%% 装备分解
read(15401, <<GreemNum:16, _Glen:16, Bin/binary>>) ->
    {Rest, GreemList} = read_id_list(Bin, [], GreemNum),
    case Rest of
        <<BlueNum:16, _Blen:16, Bin2/binary>> ->
            {Rest2, BlueList} = read_id_list(Bin2, [], BlueNum),
            case Rest2 of
                <<PurpleNum:16, _Plen:16, Bin3/binary>> ->
                    {_, PurpleList} = read_id_list(Bin3, [], PurpleNum);
                _ ->
                    PurpleList = []
            end;
        _ ->
            BlueList = [],
            PurpleList = []
    end,
    %io:format("GreemList=~p, BlueList=~p, PurpleList=~p~n", [GreemList, BlueList, PurpleList]),
    {ok, [GreemList, BlueList, PurpleList]};

%%装备合成
%%read(15405, <<BlueId:32, PurpleId:32, PurpleId2:32>>) ->
%%    {ok, [BlueId, PurpleId, PurpleId2]};

%% 宝石合成
%read(15420, <<RuneId:32, StoneTypeId:32, Num:16, Bin/binary>>) ->
%    {_, StoneList} = pt:read_id_num_list(Bin, [], Num),
%    io:format("15420 [~p]~n", [{RuneId, StoneTypeId, Num, StoneList}]),
%    {ok,[RuneId, StoneTypeId, StoneList]};

%% IsRune:是否用幸运符 0:不用, 1:用
%% PerNum:每次用几个石头
read(15420, <<Times:16, IsRune:8, StoneTypeId:32, PerNum:16, Num:16, Bin/binary>>) ->
    {Rest, StoneList} = pt:read_id_num_list(Bin, [], Num),
    case Rest of
        <<Num2:16, Bin2/binary>> ->
            {_, RuneList} = pt:read_id_num_list(Bin2, [], Num2);
        _ ->
            RuneList = []
    end,
    {ok,[RuneList, StoneTypeId, StoneList, Times, IsRune, PerNum]};

%% 宝石镶嵌
read(15421, <<EquipId:32, StoneId1:32, RuneId1:32, S2:32, R2:32, S3:32, R3:32>>) ->   
    {ok, [EquipId, StoneId1, RuneId1, S2, R2, S3, R3]};

%% 宝石拆除
read(15422, <<EquipId:32, StonePos1:8, RuneId1:32, StonePos2:8, RuneId2:32, StonePos3:8, RuneId3:32>>) ->
    {ok, [EquipId, StonePos1, RuneId1, StonePos2, RuneId2, StonePos3, RuneId3]};

%% 炼炉合成
read(15430, <<ForgeId:32, Num:16, Flag:8>>) ->
    {ok, [ForgeId, Num, Flag]};

%% 注灵
read(15435, <<GoodsId:32>>) ->
    {ok, GoodsId};

%% 提升器灵
read(15436, <<GoodsId:32>>) ->
    {ok, GoodsId};

%% 获得器灵信息
read(15437, <<GoodsId:32>>) ->
    {ok, GoodsId};

%% 取武器洗炼礼包信息
read(15440, _R) ->
    {ok, wash_gift};

%% 取武器洗炼礼包信息
read(15441, <<Gift:32>>) ->
    {ok, Gift};

%% 器灵激活
read(15442, <<TypeId:16>>) ->
    {ok, [TypeId]};

%% 默认匹配
read(_Cmd, _Bin) ->
    {error, nomatch}.

%% S -> C

%%装备强化
write(15400, [Res, GoodsId, NewStren, NewStrenRatio, Bind, Coin, Bcoin]) ->
    {ok, pt:pack(15400, <<Res:16, GoodsId:32, NewStren:16, NewStrenRatio:16, Bind:16, Coin:32, Bcoin:32>>)};

%%%% 装备分解
write(15401, [Res, StoneList1, StoneList2, StoneList3, LuckList1, LuckList2, LuckList3, Reserve1, Reserve2, Reserve3]) ->
    {L1, B1} = write_list(StoneList1),
    {L2, B2} = write_list(StoneList2),
    {L3, B3} = write_list(StoneList3),
           
    {L4, B4} = write_list(LuckList1),
    {L5, B5} = write_list(LuckList2),
    {L6, B6} = write_list(LuckList3),
            
    {L7, B7} = write_list(Reserve1),
    {L8, B8} = write_list(Reserve2),
    {L9, B9} = write_list(Reserve3),
    {ok, pt:pack(15401, <<Res:16, L1:16, B1/binary, L2:16, B2/binary, L3:16, B3/binary, L4:16, B4/binary, L5:16, B5/binary, L6:16, B6/binary, L7:16, B7/binary, L8:16, B8/binary, L9:16, B9/binary>>)};
    
%%品质升级
write(15402, [Res, GoodsId, PrefixType, FirstPrefix, Prefix, NewStoneNum, Bind, NewCoin, Bcoin]) ->
    {ok, pt:pack(15402, <<Res:16, GoodsId:32, PrefixType:8, FirstPrefix:16, Prefix:16, NewStoneNum:16, Bind:16, NewCoin:32, Bcoin:32>>)};

%% 装备合成
write(15405, [Res, EquipId, Bind, Prefix, Coin, Bcoin]) ->
   {ok, pt:pack(15405, <<Res:16, EquipId:32, Bind:16, Prefix:16, Coin:32, Bcoin:32>>)};

%% 装备精炼
write(15406, [Res, GoodsTypeId, Bind, Prefix]) ->
    {ok, pt:pack(15406, <<Res:16, GoodsTypeId:32, Bind:16, Prefix:16>>)};

%%装备继承
write(15408, [Res, GoodsTypeId, Bind, Prefix, Stren]) ->
    {ok, pt:pack(15408, <<Res:16, GoodsTypeId:32, Bind:16, Prefix:16, Stren:16>>)};

%% 装备升级
write(15410, [Res, GoodsTypeId, Bind, Prefix, Stren]) ->
    {ok, pt:pack(15410, <<Res:16, GoodsTypeId:32, Bind:16, Prefix:16, Stren:16>>)};

%% 装备洗炼
write(15412, [Res, Times, GoodsId, Bind, Grade, AdditionList]) ->
    case Times > 1 of
        true ->
            Len = length(AdditionList),
            ListBin = list_to_binary(get_addition_list(AdditionList, [])),
            {ok, pt:pack(15412, <<Res:16, GoodsId:32, Bind:16, Len:16, ListBin/binary>>)};
        false ->
            Len = length(AdditionList),
            F = fun({Type, Star, Value, Color, Min, Max}) ->
                        <<Type:16, Star:16, Value:32, Color:16, Min:32, Max:32>>
                end,
            List = lists:map(F, AdditionList),  
            ListBin = list_to_binary([<<Len:16>>] ++ List),
            {ok, pt:pack(15412, <<Res:16, GoodsId:32, Bind:16, Grade:8, ListBin/binary>>)}
    end;

%% 选择洗炼属性
write(15413, [Res, GoodsId]) ->
    {ok, pt:pack(15413, <<Res:16, GoodsId:32>>)};

%% 获取洗炼信息
write(15414, [Res, AdditionList1, AdditionList2, AdditionList3]) ->
    AllList = [{1, AdditionList1}, {2, AdditionList2}, {3, AdditionList3}],
    F = fun({Type, Star, Value, Color, Min, Max}) ->
            <<Type:16, Star:16, Value:32, Color:16, Min:32, Max:32>>
        end,
    F2 = fun({Grade, AdditionList}) ->
            List = lists:map(F, AdditionList),
            ListBin = list_to_binary(List),
            Len = length(List),
            <<Grade:8, Len:16, ListBin/binary>>
        end,
    
    List2 = lists:map(F2, AllList),
    ListBin2 = list_to_binary(List2),
    Len2 = length(List2),
    {ok, pt:pack(15414, <<Res:16, Len2:16, ListBin2/binary>>)};

write(15415, [Res]) ->
    {ok, pt:pack(15415, <<Res:16>>)};

%% 装备进阶
write(15416, [Res, GoodsTypeId, Bind, Prefix]) ->
    {ok, pt:pack(15416, <<Res:16, GoodsTypeId:32, Bind:16, Prefix:16>>)};

%% 获取变换信息
write(15417, [Res, List]) ->
    Len = length(List),
    F = fun({Pos, GoodsTypeId, Time}) ->
            <<Pos:8, GoodsTypeId:32, Time:32>>
        end,
    List2 = lists:map(F, List),
    ListBin = list_to_binary(List2),
    {ok, pt:pack(15417, <<Res:16, Len:16, ListBin/binary>>)};

%% 衣橱列表
write(15418, [Res, List, List2]) ->
    Len = length(List),
    Len2 = length(List2),
    F = fun(Wardrobe) ->
            GoodsId = Wardrobe#ets_wardrobe.goods_id,
            State = Wardrobe#ets_wardrobe.state,
            Time = Wardrobe#ets_wardrobe.time,
            Pos = Wardrobe#ets_wardrobe.pos,
            <<GoodsId:32, State:8, Time:32, Pos:8>>
        end,
    F2 = fun(GoodsTypeId) ->
            <<GoodsTypeId:32>>
    end,
    ListBin = list_to_binary(lists:map(F, List)),
    ListBin2 = list_to_binary(lists:map(F2, List2)),
    {ok, pt:pack(15418, <<Res:16, Len:16, ListBin/binary, Len2:16, ListBin2/binary>>)};

write(15419, [Res]) ->
    {ok, pt:pack(15419, <<Res:16>>)};

%% 宝石合成
write(15420, [Res, SucNum, FailNum, Cost, GoodsType]) ->
    {ok, pt:pack(15420, <<Res:16, SucNum:16, FailNum:16, Cost:32, GoodsType:32>>)};

%% 宝石镶嵌
write(15421, [Res, EquipId, StoneTypeId, NewCoin, Bind]) ->
    {ok, pt:pack(15421, <<Res:16, EquipId:32, StoneTypeId:32, NewCoin:32, Bind:16>>)};

%% 宝石拆除
write(15422, [Res, EquipId, NewCoin]) ->
    {ok, pt:pack(15422, <<Res:16, EquipId:32, NewCoin:32>>)};

%%  炼炉合成
write(15430, [Res, ForgeId, Num, Notice]) ->
    {ok, pt:pack(15430, <<Res:16, ForgeId:32, Num:16, Notice:8>>)};

%% 注灵
write(15435, [Res, Level, Type, Value]) ->
    {ok, pt:pack(15435, <<Res:16, Level:32, Type:16, Value:32>>)};

%% 注灵信息
write(15437, [Res, Level, QiLevel]) ->
    {ok, pt:pack(15437, <<Res:16, Level:32, QiLevel:32>>)};

write(15440, [Res, List]) ->
    Num = length(List),
    F = fun({GiftId, S}) ->
            <<GiftId:32, S:8>>
    end,
    ListBin = list_to_binary(lists:map(F, List)),
    {ok, pt:pack(15440, <<Res:16, Num:16, ListBin/binary>>)};

write(15441, [Res, GiftId]) ->
    {ok, pt:pack(15441, <<Res:16, GiftId:32>>)};

write(15442, [QiLingId, Res]) ->
    {ok, pt:pack(15442, <<QiLingId:32, Res:8>>)};
    
write(_Cmd, _Bin) ->
    {ok, pt:pack(0, <<>>)}.

get_addition_list([], L) ->
    L;
get_addition_list([H|T], L) ->
    [Pos|AdditionList] = tuple_to_list(H),
    F = fun({Type, Star, Value, Color, Min, Max}) ->
            <<Type:16, Star:16, Value:32, Color:16, Min:32, Max:32>>
        end,
    Len = length(AdditionList),
    List = [<<Pos:8>>] ++ [<<Len:16>>] ++ lists:map(F, AdditionList),
    get_addition_list(T, L++List).

write_list(List) ->
    F = fun(Info) ->
            case Info =/= [] of
                true ->
                    GoodsId = Info#goods.id,
                    TypeId = Info#goods.goods_id,
                    Bind = Info#goods.bind,
                    <<GoodsId:32, Bind:16, TypeId:32>>;
                false ->
                    <<>>
            end
        end,
    Len = length(List),
    case Len > 0 of
        true ->
            ListBin = list_to_binary(lists:map(F, List)),
            {Len, ListBin};
        false ->
            {0, <<>>}
    end.

%%读取Id列表 -> {Rest, IdList}
read_id_list(<<Id:32, Rest/binary>>, L, Num) when Num > 0 ->
    NewL = case lists:member(Id, L) of
               false -> [{Id, 1}|L];
               true -> L
           end,
    read_id_list(Rest, NewL, Num-1);
read_id_list(Rest, L, _) -> {Rest, L}.

read_lock_list(<<Id:16, Star:16, Value:32, Color:16, Min:32, Max:32, Rest/binary>>, L, Num) when Num > 0 ->
    NewL = case lists:member(Id, L) of
               false -> L++[{Id, Star, Value, Color, Min, Max}];
               true -> L
           end,
    read_lock_list(Rest, NewL, Num-1);
read_lock_list(Rest, L, _) -> {Rest, L}.




