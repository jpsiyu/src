%%%------------------------------------
%%% module  : lib_gemstone
%%% @Author : huangwenjie
%%% @Email  : 1015099316@qq.com
%%% @Create : 2014.2.19
%%% @Description: 宝石系统
%%%-------------------------------------
-module(lib_gemstone).
-include("server.hrl").
-include("common.hrl").
-include("gemstone.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-compile(export_all).

%% ################################# 登陆 ##################################
%% 玩家上线初始化
%% param:Pid::宝石系统进程, PlayerId::玩家Id
role_login(Pid, PlayerStatus) -> 
    private_init_gemstone(Pid, PlayerStatus).

%% 玩家上线初始化,把已经激活的装备写进进程字典
%% param:PlayerId::玩家Id
%% return:List ->[{Type, Value}] 属性列表
private_init_gemstone(GemPid, PlayerStatus) ->
    PlayerId = PlayerStatus#player_status.id, 
    case db:get_all(io_lib:format(<<"select player_id, id, state, level, exp from gemstone where player_id = ~p">>, [PlayerId])) of 
        [] -> 
            GemAttr = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            NewPlayerStatus = PlayerStatus#player_status{gemstone_attr = GemAttr},
            NewPlayerStatus;
        All -> 
            %% 已激活的宝石栏位信息
            GemStones = lists:map(fun([PlayerId2, Id, State, Level, Exp]) -> 
                        private_make_gemstone_record([PlayerId2,Id, State, Level, Exp]) 
                    end, All), 
            update_all_active_gemstones(GemPid, PlayerId, GemStones),
            %% 计算属性
            %% test
            NewPlayerStatus = count_player_attr(PlayerStatus),
            NewPlayerStatus
    end.

%% 构建宝石记录
private_make_gemstone_record([_PlayerId, Id, State, Level, Exp]) -> 
    EquipPos = Id div 100,
    GemPos = Id rem 100,
    GemActiveRecord = data_gemstone_new:get_gemstone_active(EquipPos, GemPos),
    Type = case is_record(GemActiveRecord, gemstone_active) of 
        true -> GemActiveRecord#gemstone_active.type;
        false -> 0
    end,
    #gemstone{
        id = Id,
        equip_pos = EquipPos,
        gem_pos = GemPos,
        type = Type,
        state = State,
        level = Level,
        exp = Exp
    }.


%% ############################ 进程字典操作 ###############################
%% 更新全部激活的栏位
update_all_active_gemstones(GemPid, PlayerId, GemStones) -> 
    mod_gemstone:update_all(GemPid, PlayerId, GemStones).

get_all_active_gemstones(GemPid, PlayerId) -> 
    mod_gemstone:get_all(GemPid, PlayerId).

get_one_active_gemstone(GemPid, PlayerId, EquipPos, GemPos) -> 
    Id = EquipPos*100+GemPos,
    mod_gemstone:get_one(GemPid, PlayerId, Id).

update_one_active_gemstone(GemPid, PlayerId, GemStone) ->
    mod_gemstone:update_one(GemPid, PlayerId, GemStone).

get_single_equip_gemstones(GemPid, PlayerId, EquipPos) ->
    mod_gemstone:get_one_equippos(GemPid, PlayerId, EquipPos).


%%########################### 打包操作 ####################################
%% 打包协议16600,
parse_gemstone_list(Status) ->
    GemPid = Status#player_status.gem_pid,
    PlayerId = Status#player_status.id,
    %%有装备的位置及装备战斗力
    List = lists:foldl(
        fun(EquipPos, Acc) ->
            GoodsInfo = private_get_equip(Status, EquipPos),
            case is_record(GoodsInfo, goods) of
                false ->
                    Acc;
                %% 有装备
                true ->
                    AttributeList = data_goods:get_goods_attribute(GoodsInfo),
                    _CombatPower = data_goods:count_goods_power(GoodsInfo, AttributeList, Status#player_status.career),
                    %% 再加上宝石栏的攻击力
                    CombatPower2 = count_single_equip_pos(Status, EquipPos),
                    CombatPower = CombatPower2+_CombatPower,
                    Level = Status#player_status.lv,
                    %% 打包单个装备位置的已激活和可激活的宝石栏属性
                    {IsActive, GemBinList} = pack_one_equip_gemstone(EquipPos, PlayerId, GemPid, Level), 
                    Bin = <<EquipPos:8, IsActive:8, CombatPower:32, GemBinList/binary>>,
                    [Bin | Acc]
            end
        end, [], lists:seq(1, 12)),
    %io:format("List:~p~n", [List]),
    List.

%% 打包单个装备的宝石栏
pack_one_equip_gemstone(EquipPos, PlayerId, GemPid, EquipLevel) ->
    [StateList, GemList] = lists:foldl(
        fun(GemPos, Acc) -> 
            [StateTemList, GemTemList] = Acc,
            case get_one_active_gemstone(GemPid, PlayerId, EquipPos, GemPos) of
                GemStone when is_record(GemStone, gemstone) ->
                    Level = GemStone#gemstone.level,
                    Exp = GemStone#gemstone.exp,
                    State = private_get_gemstone_state(GemStone, EquipLevel, EquipPos, GemPos),
                    case State =/= 0 of 
                        true ->
                            [[State|StateTemList], [{GemPos, State, Level, Exp}|GemTemList]];
                        false ->
                            Acc
                    end;
                %% 没激活，判断是否可激活
                _ ->
                    Level = 0,
                    Exp = 0,
                    State = private_get_gemstone_state(0, EquipLevel, EquipPos, GemPos),
                    case State =:= 2 of
                        true ->
                            [[State|StateTemList], [{GemPos, State, Level, Exp}|GemTemList]];
                        false ->
                            Acc
                    end
            end
        end, [[], []], lists:seq(1, 6)),
    case lists:member(2, StateList) of 
        true ->
            IsActive = 1;
        false -> 
            IsActive = 0
    end,
    F2 = fun({GemPos, State, Level2, Exp}) ->
            <<GemPos:8, State:8, Level2:8, Exp:32>>
        end,
    %io:format("GemList:~p~n", [GemList]),
    GemBinList = [F2({GemPos, State, Level2, Exp}) || {GemPos, State, Level2, Exp} <- GemList],
    Len = length(GemBinList),
    List = list_to_binary(GemBinList),
    GemBinList2 = <<Len:16, List/binary>>,
    {IsActive, GemBinList2}.

%% 打包单个宝石栏
parse_gemstone_one(Status, EquipPos, GemPos) ->
    PlayerId = Status#player_status.id,
    GemPid = Status#player_status.gem_pid,
    GoodsInfo = private_get_equip(Status, EquipPos),
    case is_record(GoodsInfo, goods) of 
        false ->
            <<EquipPos:8, GemPos:8, 0:8, 0:32, 4:8, 0:8, 0:8>>;
        true ->
            GemStone = get_one_active_gemstone(GemPid, PlayerId, EquipPos, GemPos),
            case is_record(GemStone, gemstone) of
                true ->
                    State = private_get_gemstone_state(GemStone, Status#player_status.lv, EquipPos, GemPos),
                    Level = GemStone#gemstone.level,
                    Exp = GemStone#gemstone.exp,
                    %% 装备位置是否显示可激活
                    IsActive = private_get_equippos_state(GemPid, PlayerId, EquipPos, Status#player_status.lv),
                    %% 战斗力
                    CombatPower2 = count_single_equip_pos(Status, EquipPos),
                    AttributeList = data_goods:get_goods_attribute(GoodsInfo),
                    _CombatPower = data_goods:count_goods_power(GoodsInfo, AttributeList, Status#player_status.career),
                    TotalPower = _CombatPower + CombatPower2,
                    <<EquipPos:8, GemPos:8, IsActive:8, TotalPower:32, State:8, Level:8, Exp:32>>;
                false ->
                    State = private_get_gemstone_state(GemStone, Status#player_status.lv, EquipPos, GemPos),
                    <<EquipPos:8, GemPos:8, 0:8, 0:32, State:8, 0:8, 0:32>>
            end
    end.



    
%%######################### 计算属性 #####################################
%% 扩展属性，处理全抗
expand_attr(AttrList) -> 
    case AttrList =:= [] of 
        true -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{12,0},{13,0},{14,0},{15,0}];
        false ->
            FullList = 
                lists:map(fun(Y) ->
                    {Type, _} = Y,
                    lists:map(fun(X) -> 
                        case Type =:= X of 
                            true -> Y;
                            false -> {X, 0}
                        end
                    end, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
                end,  AttrList),
            FullList2 = lists:foldl(fun(Z, Acc) -> 
                lists:zipwith(fun({N, Xx}, {N, Yy}) -> {N, Xx+Yy} end, Z, Acc)
                    end, [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{12,0},{13,0},{14,0},{15,0},{16,0}], FullList),
            %% 处理全抗
            case lists:keyfind(16, 1, FullList2) of 
                false -> FullList2;
                {_, Value} -> 
                    [{_,Hp},{_,Mp},{_,Att},{_,Def},{_,Hit},{_,Dodge},{_,Crit},{_,Ten}, {_,Forza},{_,Wit},{_,Agile},{_,Thew},{_,Fire},{_,Ice},{_,Drug} |_] = FullList2,
                    [{1,Hp},{2,Mp},{3,Att},{4,Def},{5,Hit},{6,Dodge},{7,Crit},{8,Ten},{9,Forza},{10,Wit},{11,Agile},{12,Thew},{13,Fire+Value},{14,Ice+Value},{15,Drug+Value}]
            end
    end.

%% 计算所有宝石栏的属性
%% param:Type 0 不进行一级属性转换为二级属性
calc_gemstone_attr(PlayerStatus, GemStones, Type) ->
    case GemStones =:= [] of 
        true -> 
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        false -> 
            Foldl = lists:foldl(
                fun(GemStoneX, Acc) -> 
                    GemAttrRecord = data_gemstone_new:get_gemstone_attr(GemStoneX#gemstone.type, GemStoneX#gemstone.level),
                    _GemStoneAttr = GemAttrRecord#gemstone_attr.attr,
                    %% 判断该装备位置是否有装备
                    GemStoneAttr = case private_get_equip(PlayerStatus, GemStoneX#gemstone.equip_pos) =:= 0 of  
                        true -> 
                            expand_attr([]);
                        false -> 
                            expand_attr([{GemStoneX#gemstone.type, _GemStoneAttr}])
                    end,
                    lists:zipwith(fun({N,X},{N,Y}) -> {N,X+Y} end, GemStoneAttr, Acc)
                end, [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{12,0},{13,0},{14,0},{15,0}], GemStones),
            %% 一级属性转换为二级属性
            [{1,Hp1},{2,Mp1},{3,Att1},{4,Def1},{5,Hit1},{6,Dodge1},{7,Crit1},{8,Ten1},{9,Forza1},{10,Agile1},{11,Wit1},{12,Thew1},{13,Fire1},{14,Ice1},{15,Drug1}] = Foldl,
            [Hp2,Mp2,Att2,Def2,Hit2,Dodge2] = one_to_two(Forza1,Agile1,Wit1,Thew1,PlayerStatus#player_status.career),
            NewAttr = [{1,Hp1+Hp2},{2,Mp1+Mp2},{3,Att1+Att2},{4,Def1+Def2},{5,Hit1+Hit2},{6,Dodge1+Dodge2},{7,Crit1},{8,Ten1},{9,Forza1},{10,Agile1},{11,Wit1},{12,Thew1},{13,Fire1},{14,Ice1},{15,Drug1}],
            case Type of 
                0 ->
                    [round(V) || {_Type, V} <- Foldl];
                1 ->
                    [round(V) || {_Type, V} <- NewAttr]
            end
    end.

%%计算玩家属性
count_player_attr(Status) -> 
    GemPid = Status#player_status.gem_pid,
    GemStones = get_all_active_gemstones(GemPid, Status#player_status.id),
    case GemStones =:= [] of 
        true -> 
            Status;
        false ->
            GemStoneAttr = calc_gemstone_attr(Status, GemStones, 0),
            NewStatus = Status#player_status{gemstone_attr = GemStoneAttr},
            lib_player:count_player_attribute(NewStatus)
    end.

%% 计算单个装备位置宝石栏的战斗力
count_single_equip_pos(Status, EquipPos) ->
    GemPid = Status#player_status.gem_pid,
    GemStones = get_single_equip_gemstones(GemPid, Status#player_status.id, EquipPos),
    case GemStones =:= [] of 
        true -> 
            0;
        false ->
            GemStoneAttr = calc_gemstone_attr(Status, GemStones, 1),
            CombatPower = count_equip_pos_power(GemStoneAttr),
            CombatPower
    end.

%% 计算单个装备位置的战斗力
count_equip_pos_power(GemStoneAttr) ->
   [Hp14, _Mp14, Att14, Def14, Hit14, Dodge14, Crit14, Ten14, _Forza14, _Agile14, _Wit14, _Thew14, Fire14, Ice14, Drug14] = GemStoneAttr, 
   Combat_power = Att14*0.8988+Def14*0.3+Hit14*0.3113+Dodge14*0.3736+Crit14*1+Ten14*0.5+Hp14*0.06+(Fire14+Ice14+Drug14)*0.1,
   round(Combat_power).

%% 查看别人的宝石栏总属性
get_gemstone_attr_all(Status, Sid) ->
    GemStones = get_all_active_gemstones(Status#player_status.gem_pid, Status#player_status.id),
    GemStoneAttr = calc_gemstone_attr(Status, GemStones, 0),
    [Hp14, Mp14, Att14, Def14, Hit14, Dodge14, Crit14, Ten14, Forza14, Agile14, Wit14, Thew14, Fire14, Ice14, Drug14] = GemStoneAttr,
    NewAttrList = [{1,Hp14},{2,Mp14},{3,Att14},{4,Def14},{5,Hit14},{6,Dodge14},{7,Crit14},{8,Ten14},{9,Forza14},{10,Agile14},{11,Wit14},{12,Thew14},{13,Fire14},{14,Ice14},{15,Drug14}],
    F = fun({Type, Value}) ->
            <<Type:8, Value:32>>
        end,
    NewList2 = [F({Type, Value}) || {Type, Value} <- NewAttrList],
    {ok, Bin} = pt_166:write(16604, [1,NewList2]),
    lib_server_send:send_to_sid(Sid, Bin).

%% ############################################## 功能部分 ####################################
%% 激活宝石栏位
active_gemstone(PS, EquipPos, GemPos) ->
    GemPid = PS#player_status.gem_pid,
    PlayerId = PS#player_status.id,
    ActiveRecord = data_gemstone_new:get_gemstone_active(EquipPos, GemPos),
    Id = EquipPos*100 + GemPos,
    case ActiveRecord =:= [] of 
        true -> 
            {fail, 0};   %策划没配置
        false -> 
            case get_one_active_gemstone(GemPid, PlayerId, EquipPos, GemPos) of    
                %% 该栏位没激活可以进行操作
                [] -> 
                    case private_get_equip(PS, EquipPos) of 
                        GoodsInfo when is_record(GoodsInfo, goods) -> 
                            case PS#player_status.lv >= ActiveRecord#gemstone_active.equip_min of 
                                true -> 
                                    case PS#player_status.coin >= ActiveRecord#gemstone_active.cost of 
                                        true ->
                                            LeftCoin = PS#player_status.coin - ActiveRecord#gemstone_active.cost,
                                            NewPS = PS#player_status{coin = LeftCoin},
                                            lib_player:refresh_client(NewPS#player_status.id, 2),
                                            %% 激活宝石栏
                                            SQL = io_lib:format(<<"insert into gemstone (player_id, id, state, level, exp) values (~p, ~p, ~p, ~p, ~p)">>, [PlayerId, Id, 1, 1, 0]),
                                            db:execute(SQL),
                                            GemStone = private_make_gemstone_record([PlayerId, Id, 1, 1, 0]),
                                            update_one_active_gemstone(GemPid, PlayerId, GemStone),
                                            %% 日志
                                            log_gemstone_active(GemStone#gemstone.equip_pos, GemStone#gemstone.gem_pos,PlayerId), 
                                            %% 消耗日志
                                            About = lists:concat(["gemstone_active","_", EquipPos,"_", GemPos]),
                                            log:log_consume(stone_inlay, coin, PS, NewPS, About),
                                            %% 神炉返利
                                            lib_guild:put_furnace_back(NewPS, ActiveRecord#gemstone_active.cost),
                                            {ok, NewPS};
                                        %% 铜币不足
                                        false ->
                                            {fail, 4}
                                    end;
                                %% 装备等级不够
                                false ->
                                    {fail, 3}
                            end;
                        %% 没有装备
                        _ ->
                            {fail, 2}
                    end;
                %% 已激活
                _ ->
                    {fail, 5}
            end
    end.

%% 宝石栏升级物品检查
check_upgrade_goods({GoodsTypeId, Num}, [PlayerStatus, Type, GoodsList, Exp, GoodsStatus]) -> 
    %GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    GoodsInfoList = lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id, GoodsTypeId, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
    TotalNum = lib_goods_util:get_goods_totalnum(GoodsInfoList),
    if 
        TotalNum < Num ->
            {fail, 6};
        true -> 
            UpgradeRule = data_gemstone_new:get_gemstone_upgrade(GoodsTypeId),
            case is_record(UpgradeRule, gemstone_upgrade) of
                false ->
                    {fail, 8};
                true -> 
                    case lists:keyfind(Type, 1, UpgradeRule#gemstone_upgrade.add_exp) of 
                        false -> 
                            {fail, 8};
                        {_, ExpAdd} ->
                            {ok, [PlayerStatus, Type, [{GoodsInfoList, Num}|GoodsList], Exp+ExpAdd*Num, GoodsStatus]}
                    end
            end 
    end.
    


%% 宝石栏位升级检查
check_gemstone_upgrade(PlayerStatus, GemStone, GoodsList, GoodsStatus) -> 
    case lib_goods_check:list_handle(fun check_upgrade_goods/2, [PlayerStatus, GemStone#gemstone.type, [], 0, GoodsStatus], GoodsList) of 
        {fail, Res} -> 
            {fail, Res};
        {ok, [_NewPS, _Type, NewGoodsList, Exp, _]} -> 
            %% 判断是否有装备
            case lib_goods_util:get_goods_by_cell(PlayerStatus#player_status.id, ?GOODS_LOC_EQUIP, GemStone#gemstone.equip_pos, GoodsStatus#goods_status.dict) of 
                GoodsInfo when is_record(GoodsInfo, goods) -> 
                    case GemStone#gemstone.level >= ?MAXLEVEL of 
                        false ->
                            {ok, NewGoodsList, Exp};
                        true -> 
                            {fail, 9}
                    end;
                _ -> {fail, 2}
            end
    end.

%% 升级宝石栏
gemstone_upgrade(PlayerStatus, GoodsStatus, GemStone, Exp, NewGoodsList) ->
     F = fun() ->
         ok = lib_goods_dict:start_dict(),
        EquipPos = GemStone#gemstone.equip_pos,
        GemPos = GemStone#gemstone.gem_pos,
        Id = EquipPos*100 + GemPos,
        OldLevel = GemStone#gemstone.level,
        OldExp = GemStone#gemstone.exp,
        GemAttrRecord = data_gemstone_new:get_gemstone_attr(GemStone#gemstone.type, OldLevel),
        case is_record(GemAttrRecord, gemstone_attr) of 
            true ->  
                [IsUpgrade, NewLevel, NewExp] = calc_value(GemStone#gemstone.type, OldLevel, OldExp, Exp, []),
                {ok, NewStatus} = delete_goods_list(GoodsStatus, NewGoodsList),
                NewGemstone = GemStone#gemstone{level = NewLevel, exp = NewExp},
                update_one_active_gemstone(PlayerStatus#player_status.gem_pid, PlayerStatus#player_status.id, NewGemstone),
                SQL = io_lib:format(<<"update gemstone set level = ~p, exp = ~p where player_id = ~p and id = ~p">>, [NewLevel, NewExp, PlayerStatus#player_status.id, Id]),
                db:execute(SQL),
                %% 日志
                log_gemstone_upgrade(GemStone#gemstone.equip_pos, GemStone#gemstone.gem_pos, GemStone#gemstone.level, GemStone#gemstone.exp, NewGemstone#gemstone.level, NewGemstone#gemstone.exp, PlayerStatus#player_status.id),
                %NewPlayerStatus = count_player_attr(PlayerStatus),
                 Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                 NewStatus1 = NewStatus#goods_status{dict = Dict},
                {ok, PlayerStatus, IsUpgrade, Exp, NewStatus1};
            false ->
                 Dict = lib_goods_dict:handle_dict(GoodsStatus#goods_status.dict),
                 NewStatus = GoodsStatus#goods_status{dict = Dict},
                {ok, NewStatus, 0, 0, GoodsStatus}
        end
     end,
     lib_goods_util:transaction(F).
    

%% 删除物品列表
%% NewGoodsList::[{GoodsInfoList,Num}]  GoodsInfoList:: [GoodsInfo1,GoodsInfo2]
delete_goods_list(GoodsStatus, []) -> {ok, GoodsStatus};
delete_goods_list(GoodsStatus, [{GoodsInfoList, Num} | T]) ->
    {ok, NewGoodsStatus} = lib_goods:delete_more(GoodsStatus, GoodsInfoList, Num),
    delete_goods_list(NewGoodsStatus, T).
    


%%############################################# 功能部分 end #####################################

%% 取装备位置装备
%%return: 0.没有装备|物品信息GoodsInfo#goods
private_get_equip(PlayerStatus, EquipPos) -> 
    Go = PlayerStatus#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'gemstone_equip', PlayerStatus, EquipPos}) of 
        {ok, GoodsInfo} ->
            case is_record(GoodsInfo, goods) of 
                true ->
                    GoodsInfo;
                false -> 
                    0
            end;
        {'EXIT', _Reason} ->
            0
    end.

%% 取宝石栏的状态 0.未激活 1.激活 2.可激活 3.最大等级
private_get_gemstone_state(GemStone, Level, EquipPos, GemPos) ->
    case is_record(GemStone, gemstone) of 
        true ->
            case GemStone#gemstone.level >= ?MAXLEVEL of 
                true -> 3;
                false ->1
            end;
        false ->
            ActiveRecord = data_gemstone_new:get_gemstone_active(EquipPos, GemPos),
            case is_record(ActiveRecord, gemstone_active) of 
                true ->
                    case Level >= ActiveRecord#gemstone_active.equip_min of
                        true -> 2;
                        false -> 0
                    end;
                false ->
                    0
            end
    end.

%% 判断装备位置是否显示可激活状态
private_get_equippos_state(GemPid, PlayerId, EquipPos, Level) ->
    StateList = lists:foldl(fun(GemPos, Acc) -> 
        case get_one_active_gemstone(GemPid, PlayerId, EquipPos, GemPos) of 
            GemStone when is_record(GemStone, gemstone) ->
                [1|Acc];
            _ ->
                State = private_get_gemstone_state(0, Level, EquipPos, GemPos),
                [State|Acc]
        end 
            end, [], [1,2,3,4,5,6]),
    case lists:member(2, StateList) of 
        true -> 1;
        false -> 0
    end.

%% 一级属性转化为二级属性
one_to_two(Forza, Agile, Wit, Thew, Career) ->
    %% 职业收益
    [HpY, MpY, AttY, DefY, HitY, DodgeY] = case Career of
        1 -> [1, 1, 1, 1, 2, 3];  %% 神将
        2 -> [1, 2, 1, 1, 2, 3];    %% 天尊
        _ -> [1, 1, 1, 1, 2, 3]  %% 罗刹
    end,
    Hp = Thew * 10 * HpY,
    Mp = Thew * 2 * MpY,
    Att = Forza * 1 * AttY,
    Def = Thew * 1 * DefY,
    Hit = Wit * 2.5 * HitY,
    Dodge = Agile * 2 * DodgeY,
    %Crit = 5,
    [Hp, Mp, Att, Def, Hit, Dodge].

%%#################################### 日志操作 #####################################
%% 激活日志
log_gemstone_active(EquipPos, GemPos, PlayerId) -> 
    SQL = io_lib:format(<<"insert into log_gemstone_active (player_id, equip_pos, gem_pos, time) values (~p, ~p, ~p, ~p)">>, [PlayerId, EquipPos, GemPos, util:unixtime()]),
    db:execute(SQL).

%% 升级日志
log_gemstone_upgrade(EquipPos, GemPos, OldLevel, OldExp, NewLevel, NewExp, PlayerId) -> 
    SQL = io_lib:format(<<"insert into log_gemstone_upgrade (player_id, equip_pos, gem_pos, old_level, old_exp, new_level, new_exp, time) values (~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p)">>, [PlayerId, EquipPos, GemPos, OldLevel, OldExp, NewLevel, NewExp, util:unixtime()]),
    db:execute(SQL).

%%###################################### end ##############################################

%% 升级经验
calc_value(Type, OldLevel, OldExp, AddExp, List) ->
    GemAttrRecord = data_gemstone_new:get_gemstone_attr(Type, OldLevel),
    case is_record(GemAttrRecord, gemstone_attr) of
        true->
            case OldExp + AddExp >= GemAttrRecord#gemstone_attr.exp_limit of
                true ->
                    %% 升级
                    NewLevel = OldLevel + 1,
                    case NewLevel >= ?MAXLEVEL of
                        true ->
                            NewExp = GemAttrRecord#gemstone_attr.exp_limit,
                            [1, NewLevel, NewExp];
                        false ->
                            NewExp = OldExp + AddExp - GemAttrRecord#gemstone_attr.exp_limit,
                            calc_value(Type, NewLevel, NewExp,  0, [1 | List])
                    end;
                false ->
                    IsUpgrade = case lists:member(1, List) of
                        true -> 1;
                        false -> 0
                    end,
                    NewExp = OldExp + AddExp,
                    [IsUpgrade, OldLevel, NewExp]
            end;
        false ->
            IsUpgrade =case lists:member(1, List) of
                true -> 1;
                false -> 0
            end,
            [IsUpgrade, OldLevel, OldExp]
    end.


%% 取装备宝石栏信息,查看物品信息时调用
get_gemstone_4_goodsinfo(PlayerStatus, Location, EquipPos) ->
    PlayerId = PlayerStatus#player_status.id,
    GemPid = PlayerStatus#player_status.gem_pid,
    %% 只有装备位置上的装备才有宝石栏信息
    case Location =:= ?GOODS_LOC_EQUIP andalso EquipPos >= 1 andalso EquipPos =< 12 of 
        true ->
            %% 取该装备上激活的宝石栏的信息
            GemStoneList = mod_gemstone:get_one_equippos(GemPid, PlayerId, EquipPos),
            GemStoneAttr = calc_gemstone_attr(PlayerStatus, GemStoneList, 1),
            CombatPower = count_equip_pos_power(GemStoneAttr),
            {GemStoneList, CombatPower};
        false ->
            {[], 0}
    end.



