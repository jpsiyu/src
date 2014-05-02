%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-9-7
%% Description: 武器注灵
%% --------------------------------------------------------
-module(lib_equip_reiki).
-compile(export_all).
-include("reiki.hrl").
-include("errcode_goods.hrl").
-include("def_goods.hrl").
-include("server.hrl").
-include("goods.hrl").

%% 初始化注灵
init_equip_reiki(GoodsStatus) ->
    GoodsList = lib_goods_util:get_list_by_type(?GOODS_TYPE_EQUIP, GoodsStatus#goods_status.dict),
    %io:format("GoodsList = ~p~n", [GoodsList]),
    NewDict = init_goods_reiki(GoodsList, GoodsStatus#goods_status.dict),
    GoodsStatus#goods_status{dict = NewDict}. 

init_goods_reiki([], Dict) ->
    Dict;
init_goods_reiki([GoodsInfo|T], Dict) ->
    Sql = io_lib:format(?sql_reiki_select, [GoodsInfo#goods.id]),
    case db:get_all(Sql) of
        [[Level, QiLevel, Att, Times, Attribute]] ->
            NewGoodsInfo = GoodsInfo#goods{reiki_level = Level, reiki_value = util:bitstring_to_term(Att), reiki_list = util:bitstring_to_term(Attribute), reiki_times = Times, qi_level = QiLevel},
            NewDict = lib_goods_dict:add_dict_goods(NewGoodsInfo, Dict);
        [] ->
            NewDict = Dict
    end,
    init_goods_reiki(T, NewDict).

get_goods_reiki(GoodsInfo) ->
    Sql = io_lib:format(?sql_reiki_select, [GoodsInfo#goods.id]),
    case db:get_row(Sql) of
        [] ->
            GoodsInfo;
        [Level, QiLevel, Att, Times, Attribute] ->
            NewGoodsInfo = GoodsInfo#goods{reiki_level = Level, reiki_value = util:bitstring_to_term(Att), reiki_list = util:bitstring_to_term(Attribute), reiki_times = Times, qi_level = QiLevel},
            NewGoodsInfo
    end.

%% 检查注灵
check_add_reiki(PlayerStatus, GoodsId, GoodsStatus) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 6};
        GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP ->
            {fail, 4};
        PlayerStatus#player_status.lv < 45 ->
            {fail, 5};
        GoodsInfo#goods.color < 3 ->
            {fail, 8};
        true ->
            [_A, _B, _C, _D, E, _F] = integer_to_list(GoodsInfo#goods.goods_id),
            GoodsLevel = list_to_integer([E]),
            NewGoodsInfo = get_goods_reiki(GoodsInfo),
            %io:format("level ~p~n", [{NewGoodsInfo#goods.reiki_level}]),
            if
                GoodsLevel < 4 ->
                    {fail, 9};
                true ->
                    ReikiRule = data_reiki:get_cost(NewGoodsInfo#goods.subtype, NewGoodsInfo#goods.reiki_level+1),
                    LevelRule = data_reiki:get_level(NewGoodsInfo#goods.goods_id),
                    %io:format("ReikiRule = ~p~n", [ReikiRule]),
                    if
                        is_record(ReikiRule, reiki_cost) =:= false orelse is_record(LevelRule, reiki_level) =:= false ->
                            {fail, 7};
                        PlayerStatus#player_status.llpt < ReikiRule#reiki_cost.llpt ->
                            {fail, 3};
                        NewGoodsInfo#goods.reiki_level >= LevelRule#reiki_level.level ->
                            {fail, 11};
                        true ->
                            {ok, NewGoodsInfo, ReikiRule}
                    end
            end
    end.

%% 检查器灵
check_qi_reiki(PlayerStatus, GoodsId, GoodsStatus) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 6};
        GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP orelse GoodsInfo#goods.subtype =/= ?GOODS_TYPE_EQUIP ->
            {fail, 4};
        PlayerStatus#player_status.lv < 45 ->
            {fail, 5};
        GoodsInfo#goods.color < 3 ->
            {fail, 8};
        true ->
            [_A, _B, _C, _D, E, _F] = integer_to_list(GoodsInfo#goods.goods_id),
            GoodsLevel = list_to_integer([E]),
            if
                GoodsLevel < 4 ->
                    {fail, 9};
                true ->
                    ReiKiRule = data_reiki:get_up_reiki(GoodsInfo#goods.qi_level+1),
                    if
                        is_record(ReiKiRule, reiki_up) =:= false ->
                            {fail, 7};
                        GoodsInfo#goods.reiki_level < ReiKiRule#reiki_up.need_level ->
                            {fail, 11};
                        PlayerStatus#player_status.gold < ReiKiRule#reiki_up.gold ->
                            {fail, 3};
                        true ->
                            {ok, GoodsInfo, ReiKiRule}
                    end
            end
    end.

%% 武器注灵
add_reiki(PlayerStatus, GoodsInfo, ReikiRule, GoodsStatus) ->
    F = fun() ->
            %ok = lib_goods_dict:start_dict(),
            %% 花费声望
            Cost = ReikiRule#reiki_cost.llpt,
            NewPlayerStatus = lib_player:cost_pt(llpt, PlayerStatus, Cost),
            Ram = util:rand(1, 100),
            if
                Ram =< ReikiRule#reiki_cost.radio ->
                    %%成功
                    Res = 1,
                    [NewGoodsInfo, NewStatus] = reiki_ok(GoodsInfo, ReikiRule, GoodsStatus),
                    log:log_reiki(PlayerStatus, NewGoodsInfo, Cost, 1, 1, GoodsInfo#goods.reiki_level, NewGoodsInfo#goods.reiki_level, NewGoodsInfo#goods.qi_level, NewGoodsInfo#goods.qi_level, NewGoodsInfo#goods.reiki_times, util:term_to_string(NewGoodsInfo#goods.reiki_value), util:term_to_string(NewGoodsInfo#goods.reiki_list), 0);
                true ->
                    if
                        GoodsInfo#goods.reiki_times >= ReikiRule#reiki_cost.times ->
                            %%成功
                            Res = 1,
                            [NewGoodsInfo, NewStatus] = reiki_ok(GoodsInfo, ReikiRule, GoodsStatus),
                            log:log_reiki(PlayerStatus, NewGoodsInfo, Cost, 1, 1, GoodsInfo#goods.reiki_level, NewGoodsInfo#goods.reiki_level, NewGoodsInfo#goods.qi_level, NewGoodsInfo#goods.qi_level, NewGoodsInfo#goods.reiki_times, util:term_to_string(NewGoodsInfo#goods.reiki_value), util:term_to_string(NewGoodsInfo#goods.reiki_list), 0);
                        true ->
                            %%失败
                            Res = 0,
                            [NewGoodsInfo, NewStatus] = reiki_fail(GoodsInfo, GoodsStatus),
                            log:log_reiki(PlayerStatus, NewGoodsInfo, Cost, 1, 0, GoodsInfo#goods.reiki_level, NewGoodsInfo#goods.reiki_level, NewGoodsInfo#goods.qi_level, NewGoodsInfo#goods.qi_level, NewGoodsInfo#goods.reiki_times, util:term_to_string(NewGoodsInfo#goods.reiki_value), util:term_to_string(NewGoodsInfo#goods.reiki_list), 0)
                    end
            end,
            %Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            %NewStatus1 = NewStatus#goods_status{dict = Dict},
            {ok, Res, NewPlayerStatus, NewGoodsInfo, NewStatus}
    end,
    lib_goods_util:transaction(F). 

%%注灵成功
reiki_ok(GoodsInfo, ReikiRule, GoodsStatus) ->
    Times = 0,
    Level = GoodsInfo#goods.reiki_level + 1,
    Value = ReikiRule#reiki_cost.value,
    [NewGoodsInfo, NewStatus] = change_goods_reiki(GoodsInfo, Times, Level, Value, GoodsStatus),
    [NewGoodsInfo, NewStatus].

%%注灵失败
reiki_fail(GoodsInfo, GoodsStatus) ->
    Times = GoodsInfo#goods.reiki_times + 1,
    Level = GoodsInfo#goods.reiki_level,
    Value = GoodsInfo#goods.reiki_value,
    [NewGoodsInfo, NewStatus] = change_goods_reiki(GoodsInfo, Times, Level, Value, GoodsStatus),
    [NewGoodsInfo, NewStatus].

change_goods_reiki(GoodsInfo, Times, Level, Value, GoodsStatus) ->
    Sql = io_lib:format(<<"replace into add_reiki (gid, level, qi_level, att, times, attribute) VALUES (~p, ~p, ~p, '~s', ~p, '~s')">>, [GoodsInfo#goods.id, Level, GoodsInfo#goods.qi_level, util:term_to_string(Value), Times, util:term_to_string(GoodsInfo#goods.reiki_list)]),
    %% 变成绑定
    Sql2 = io_lib:format(<<"update goods_low set bind = ~p where gid=~p">>, [2, GoodsInfo#goods.id]),
    db:execute(Sql),
    db:execute(Sql2),
    NewGoodsInfo = GoodsInfo#goods{reiki_level = Level, reiki_times = Times, reiki_value = Value, bind=2},
    Dict = lib_goods_dict:add_dict_goods(NewGoodsInfo, GoodsStatus#goods_status.dict),
    NewStatus = GoodsStatus#goods_status{dict = Dict},
    [NewGoodsInfo, NewStatus].
            
%% 检查获取信息
check_get_reiki(PlayerStatus, GoodsId, GoodsStatus) ->
   GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
   if
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP orelse GoodsInfo#goods.subtype =/= ?GOODS_TYPE_EQUIP ->
            {fail, 4};
        true ->
            {ok, GoodsInfo}
    end.

