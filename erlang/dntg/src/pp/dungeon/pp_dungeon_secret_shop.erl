%%%------------------------------------
%%% @Module  : pp_dungeon_secret_shop
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.8.7
%%% @Description: 九重天11、21、31层神秘商店
%%%------------------------------------

-module(pp_dungeon_secret_shop).
-export([handle/3, pack/3]).
-include("common.hrl").
-include("server.hrl").
-include("shop.hrl").

%%获取神秘商店物品信息
handle(61200, Status, _) ->
    SceneId = Status#player_status.scene,
    SceneList = data_dungeon_secret_shop:get_secret_shop_config(use_scene),
    case lists:member(SceneId, SceneList) of
        false -> 
            VipDun = false,
            Bin = pack([], Status#player_status.scene, Status#player_status.id);
        true ->
            %% VIP副本特殊处理
            VipDunScene = data_vip_dun:get_vip_dun_config(scene_id),
            case SceneId =:= VipDunScene of
                true -> 
                    VipDun = true,
                    Bin = <<>>,
                    mod_vip_dun:get_vip_dun_shop_list(Status);
                false ->
                    VipDun = false,
                    AllGoods = data_dungeon_shop:get_goods(),
                    %io:format("AllGoods:~p~n", [AllGoods]),
                    ExtraNum = data_vip_new:get_extra_dun_shop_num(Status#player_status.vip#status_vip.growth_lv),
                    _GoodsList = goods_deal(AllGoods, [], SceneId, Status#player_status.id, ExtraNum),
                    %io:format("_GoodsList:~p~n", [_GoodsList]),
                    GoodsList = lists:reverse(lists:keysort(5, _GoodsList)),
                    %io:format("GoodsList:~p~n", [GoodsList]),
                    Bin = pack(GoodsList, Status#player_status.scene, Status#player_status.id)
            end
    end,
    case VipDun of
        false ->
            {ok, BinData} = pt_612:write(61200, Bin),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        true ->
            skip
    end;
    
%%购买物品
handle(61201, Status, [GoodsId, GoodsNum]) ->
    case GoodsId > 0 andalso GoodsNum > 0 of
        true ->
            VipDunScene = data_vip_dun:get_vip_dun_config(scene_id),
            GoodsInfo = case Status#player_status.scene =:= VipDunScene of
                true -> 
                    get_goods(mod_vip_dun:get_call_shop_list(Status#player_status.id), GoodsId);
                false ->
                    data_dungeon_shop:get_goods(GoodsId, Status#player_status.scene)
            end,
            %% 是否从配置中读到数据
            case is_record(GoodsInfo, base_dungeon_shop) of
                false ->
                    NewStatus = Status,
                    skip;
                true ->
                    %% 获取当前可购买数量
                    Temp = integer_to_list(Status#player_status.id) ++ "_" ++ integer_to_list(Status#player_status.scene) ++ "_" ++ integer_to_list(GoodsInfo#base_dungeon_shop.goods_id),
                    DailyNum = case mod_daily_dict:get_special_info(Temp) of
                        undefined -> 0;
                        _DailyNum -> _DailyNum
                    end,
                    ExtraNum = case Status#player_status.scene =:= VipDunScene of
                        true -> 0;
                        false -> data_vip_new:get_extra_dun_shop_num(Status#player_status.vip#status_vip.growth_lv)
                    end,
                    TempNowNum = case GoodsInfo#base_dungeon_shop.limit_num of
                        999 -> 999;
                        _ -> GoodsInfo#base_dungeon_shop.limit_num + ExtraNum - DailyNum
                    end,
                    NowNum = case TempNowNum > 0 of
                        true -> TempNowNum;
                        false -> 0
                    end,
                    %% 是否胜利帮派
                    IsCityWarWin = case NowNum of
                        999 ->
                            case Status#player_status.guild#status_guild.is_city_war_win of
                                1 -> true;
                                _ -> false
                            end;
                        _ ->
                            true
                    end,
                    case IsCityWarWin of
                        %% 失败，只有攻城战胜利帮派的成员才能购买
                        false ->
                            NewStatus = Status,
                            {ok, BinData} = pt_612:write(61201, [8, GoodsId, NowNum]);
                        true ->
                            %% 判断物品表是否存在该物品
                            case GoodsInfo of
                                [] ->
                                    NewStatus = Status,
                                    {ok, BinData} = pt_612:write(61201, [5, GoodsId, NowNum]);
                                Any when is_record(Any, base_dungeon_shop) ->
                                    %% 从配置表中读出
                                    GoodsSceneId = GoodsInfo#base_dungeon_shop.buy_scene,
                                    %% bcoin rcoin silver gold
                                    GoodsType = case NowNum == 999 andalso Status#player_status.guild#status_guild.is_city_war_win == 1 andalso Status#player_status.scene == 102 of
                                        true -> coin;
                                        false -> gold
                                    end,
                                    GoodsPrice = GoodsInfo#base_dungeon_shop.price,
                                    GoodsIsBind = GoodsInfo#base_dungeon_shop.bind,
                                    %% 判断是否在九重天11、21、31层中
                                    SceneId = Status#player_status.scene,
                                    SceneList = data_dungeon_secret_shop:get_secret_shop_config(use_scene),
                                    case lists:member(SceneId, SceneList) of
                                        false -> 
                                            NewStatus = Status,
                                            {ok, BinData} = pt_612:write(61201, [6, GoodsId, NowNum]);
                                        true ->
                                            %% 判断在本层是否可以购买该物品
                                            case GoodsSceneId =:= SceneId of
                                                false -> 
                                                    NewStatus = Status,
                                                    {ok, BinData} = pt_612:write(61201, [7, GoodsId, NowNum]);
                                                true ->
                                                    %% 判断是否可以购买
                                                    case NowNum < GoodsNum of
                                                        true -> 
                                                            NewStatus = Status,
                                                            {ok, BinData} = pt_612:write(61201, [2, GoodsId, NowNum]);
                                                        false ->
                                                            %% 判读用户是否够钱
                                                            %case GoodsType of
                                                            %    gold -> PSMoney = Status#player_status.gold;
                                                            %    bgold -> PSMoney = Status#player_status.bgold;
                                                            %    coin -> PSMoney = Status#player_status.coin;
                                                            %    bcoin -> PSMoney = Status#player_status.bcoin;
                                                            %    _ -> PSMoney = 0
                                                            %end,
                                                            case lib_goods_util:is_enough_money(Status, GoodsPrice * GoodsNum, GoodsType) of
                                                            %case PSMoney < GoodsPrice * GoodsNum of
                                                                false -> 
                                                                    NewStatus = Status,
                                                                    {ok, BinData} = pt_612:write(61201, [3, GoodsId, NowNum]);
                                                                true ->
                                                                    %% 判断背包是否已满
                                                                    GoodsPid = Status#player_status.goods#status_goods.goods_pid,
                                                                    %{ok, CellNum} = gen:call(GoodsPid, '$gen_call', {'cell_num'}),
                                                                    CellNum = gen_server:call(GoodsPid, {'cell_num'}),
                                                                    case CellNum =< 0 of
                                                                        true -> 
                                                                            NewStatus = Status,
                                                                            {ok, BinData} = pt_612:write(61201, [4, GoodsId, NowNum]);
                                                                        false ->
                                                                            %lib_task_vip:fin_task_vip(Status, 700040, 1),
                                                                            %% 成功购买
                                                                            mod_daily_dict:set_special_info(Temp, DailyNum + GoodsNum),
                                                                            _NewStatus = lib_goods_util:cost_money(Status, GoodsPrice * GoodsNum, GoodsType),                                                                            
                                                                            case GoodsType of
                                                                                %%消费返礼--财迷商店
                                                                                gold ->
																					%% 消费返红包接口
		                                                                            lib_activity:add_consumption(cmsd, Status, GoodsPrice * GoodsNum),
                                                                                    NewStatus = lib_player:add_consumption(cmsd, _NewStatus, GoodsPrice * GoodsNum, GoodsNum);
                                                                                _ -> 
                                                                                    NewStatus = _NewStatus
                                                                            end,
                                                                            log:log_consume(nine_secret, GoodsType, Status, NewStatus, "nine_secret consume"),
                                                                            case GoodsIsBind of
                                                                                0 -> gen:call(GoodsPid, '$gen_call', {'give_more', [], [{GoodsId, GoodsNum}]});
                                                                                _ -> gen:call(GoodsPid, '$gen_call', {'give_more_bind', [], [{GoodsId, GoodsNum}]})
                                                                            end,
                                                                            lib_player:refresh_client(Status#player_status.id, 2),
                                                                            RestNum = NowNum - GoodsNum,
                                                                            {ok, BinData} = pt_612:write(61201, [1, GoodsId, RestNum])
                                                                    end
                                                            end
                                                    end
                                            end
                                    end;
                                _Any ->
                                    NewStatus = Status,
                                    {ok, BinData} = pt_612:write(61201, [5, GoodsId, NowNum])
                            end
                    end,
                    lib_server_send:send_one(Status#player_status.socket, BinData)
            end;
        false -> 
            NewStatus = Status,
            skip
    end,
    {ok, NewStatus};
                             
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_secret_shop no match", []),
    {error, "pp_secret_shop no match"}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%===========工具函数==========%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pack(List1, SceneId, PlayerId) ->
    %% List1
    Fun1 = fun(Elem1) ->
            {Id, Type, Price, LimitNum, _Order} = Elem1,
            %% 获取当前可购买数量
            Temp = integer_to_list(PlayerId) ++ "_" ++ integer_to_list(SceneId) ++ "_" ++ integer_to_list(Id),
            
            DailyNum = case mod_daily_dict:get_special_info(Temp) of
                undefined -> 0;
                _DailyNum -> _DailyNum
            end,
            %io:format("Temp:~p, DailyNum:~p~n", [Temp, DailyNum]),
            %io:format("DailyNum:~p~n", [DailyNum]),
            TempNowNum = LimitNum - DailyNum,
            NowNum = case TempNowNum > 0 of
                true -> TempNowNum;
                false -> 0
            end,
            <<Id:32, Type:8, Price:32, NowNum:16>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List1]),
    Size1  = length(List1),
    <<Size1:16, BinList1/binary>>.

%% #base_secret_shop{} 转为{goods_id, price_type, price}
goods_deal([], L, _SceneId, _PlayerId, _ExtraNum) -> L;
goods_deal([H | T], L, SceneId, PlayerId, ExtraNum) ->
    case is_record(H, base_dungeon_shop) of
        true -> 
            case H#base_dungeon_shop.buy_scene =:= SceneId of
                true -> 
                    L1 = [{H#base_dungeon_shop.goods_id, 1, H#base_dungeon_shop.price, H#base_dungeon_shop.limit_num + ExtraNum, H#base_dungeon_shop.order} | L];
                false -> 
                    L1 = L,
                    skip
            end;
        false -> 
            L1 = L,
            skip
    end,
    goods_deal(T, L1, SceneId, PlayerId, ExtraNum).

get_goods([], _GoodsId) -> error;
get_goods([H | T], GoodsId) ->
    case is_record(H, base_dungeon_shop) of
        true ->
            case H#base_dungeon_shop.goods_id =:= GoodsId of
                true ->
                    H;
                false ->
                    get_goods(T, GoodsId)
            end;
        false ->
            get_goods(T, GoodsId)
    end.
