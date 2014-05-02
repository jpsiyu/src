%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-13
%% Description: 物品模块
%% --------------------------------------------------------
-module(mod_goods).
-behaviour(gen_server).
-export([start/2, stop/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("goods.hrl").
-include("common.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("server.hrl").

start(PlayerId, CellNum) ->
    gen_server:start_link(?MODULE, [PlayerId, CellNum], []).

%%停止进程
stop(Pid) ->
	case is_pid(Pid) andalso is_process_alive(Pid) of
		true -> gen_server:cast(Pid, stop);
		false -> skip
	end.

init([PlayerId, CellNum]) ->
    GoodsDict = dict:new(),
	GoodsDict1 = lib_goods_init:init_goods_online(PlayerId, GoodsDict),
    NullCells = lib_goods_util:get_null_cells(PlayerId, CellNum, GoodsDict1),
    GiftList = lib_goods_util:get_gift_got_list(PlayerId),
    GoodsList = lib_goods_util:get_equip_list(PlayerId, GoodsDict1),
    EquipSuit = lib_goods_util:get_equip_suit(GoodsList),
    SuitId = lib_goods_util:get_full_suit(EquipSuit),
    Stren7_num = lib_goods_util:get_stren7_num_from_list(GoodsList),
    [CurrentEquip, _] = lib_goods_util:get_current_equip_by_list(GoodsList, [[0,0,0,0,0,0], on]),
    GoodsStatus = #goods_status{player_id = PlayerId, null_cells = NullCells, gift_list = GiftList, 
								 equip_current = CurrentEquip, equip_suit=EquipSuit, suit_id=SuitId, 
								 stren7_num=Stren7_num, dict=GoodsDict1},
    GoodsStatus1 = lib_equip_reiki:init_equip_reiki(GoodsStatus),
    {ok, GoodsStatus1}.

%% 获取dict
handle_call({'get_dict'}, _From, GoodsStatus) ->
    {reply, GoodsStatus#goods_status.dict, GoodsStatus};

%%装备磨损
handle_call({'attrit', PlayerStatus, UseNum}, _From, GoodsStatus) ->
    EquipList = lib_goods_util:get_equip_list(PlayerStatus#player_status.id, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, GoodsStatus#goods_status.dict),
    [_, AttritonList, ZeroEquipList, NewGoodsStatus1] = lib_goods:attrit_equip(EquipList, UseNum, [], [], GoodsStatus),
    %%广播耐久更新
    {ok, BinData1} = pt_150:write(15012, AttritonList),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData1),
    %% 人物属性更新
    case length(ZeroEquipList) > 0 of
        %% 有耐久为0的装备
        true ->
            %% 人物属性重新计算
            F = fun(GoodsInfo, ESuit) -> lib_goods_util:del_equip_suit(ESuit, GoodsInfo#goods.suit_id) end,
            EquipSuit = lists:foldl(F, GoodsStatus#goods_status.equip_suit, ZeroEquipList),
            NewStatus = NewGoodsStatus1#goods_status{equip_suit = EquipSuit},
            {ok, NewPlayerStatus} = lib_goods_util:count_role_equip_attribute(PlayerStatus, NewStatus),
            lib_player:send_attribute_change_notify(NewPlayerStatus, 1),
            %% 返回更新人物属性
            {reply, NewPlayerStatus, NewStatus};
       false ->
           {reply, PlayerStatus, NewGoodsStatus1}
    end;

%%使用物品背包武器变性
handle_call({'change_sex_bag', PlayerStatus, [GoodsId, EquipId]}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_change_sex_bag(PlayerStatus, GoodsStatus, GoodsId, EquipId) of
        {fail, Res} ->
            {reply, [Res, 0], GoodsStatus};
        {ok, GoodsInfo, EquipInfo} ->
            case mod_other_call:change_sex_bag(GoodsStatus, GoodsInfo, EquipInfo) of
                {ok, NewStatus, NewEquipInfo} ->
                    {reply, [1, NewEquipInfo#goods.goods_id], NewStatus};
                _R ->
                    io:format("eerr ~p~n", [_R]),
                    {reply, [10, 0], GoodsStatus}
            end
    end;

%% 变性   
handle_call({'change_sex', Id}, _From, GoodsStatus) ->
    GoodsInfo = lib_goods_util:get_goods_by_cell(Id, ?GOODS_LOC_EQUIP, 1, GoodsStatus#goods_status.dict),
    if
        is_record(GoodsInfo, goods) =/= true ->
            {reply, {ok, 0}, GoodsStatus};
        true ->
            [G1,G2,G3,G4,G5,A] = integer_to_list(GoodsInfo#goods.goods_id),
            B = list_to_integer([A]) + 5,
            C = integer_to_list(B),
            case length(C) of
                2 ->
                    [_, D] = C;
                1 ->
                    [D] = C
            end,
            F = fun() ->
                NewId = list_to_integer([G1,G2,G3,G4,G5,D]),
                NewGoodsInfo = GoodsInfo#goods{goods_id = NewId},
                Dict = lib_goods_dict:add_dict_goods(NewGoodsInfo, GoodsStatus#goods_status.dict),
                NewStatus = GoodsStatus#goods_status{dict = Dict},
                lib_fashion_change2:update_goods_id(NewId, GoodsInfo#goods.id),
                {ok, NewStatus, NewId}
            end,
            case lib_goods_util:transaction(F) of
                {ok, NewStatue, NewId} ->
                    {reply, {ok, NewId}, NewStatue};
                _R ->
                    {reply, error, GoodsStatus}
            end
    end;

handle_call(Event, From, GoodsStatus) ->
	mod_goods_call:handle_call(Event, From, GoodsStatus).

%%设置物品信息
handle_cast({'SET_STATUS', NewStatus}, _GoodsStatus) ->
	{noreply, NewStatus};

%%接受交易
handle_cast({'recv_sell'}, GoodsStatus) ->
    NewStatus = GoodsStatus#goods_status{sell_status=1},
    {noreply, NewStatus};

%%停止游戏进程
handle_cast(stop, GoodsStatus) ->
    {stop, normal, GoodsStatus};

%%中断交易
handle_cast({'stop_sell'}, GoodsStatus) ->
    NewStatus = GoodsStatus#goods_status{sell_status=0},
    {noreply, NewStatus}.

handle_info(_Reason, GoodsStatus) ->
	{noreply, GoodsStatus}.

terminate(_Reason, _GoodsStatus) ->
	ok.

code_change(_OldVsn, GoodsStatus, _Extra) ->
	{ok, GoodsStatus}.




