%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-27
%% Description: TODO:
%% --------------------------------------------------------
-module(lib_shop).
-compile(export_all).
-include("common.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-include("shop.hrl").
-include("login_count.hrl").
-include("server.hrl").
-include("record.hrl").

%% 购买物品
pay_goods(PlayerStatus, GoodsStatus, GoodsTypeInfo, GoodsList, GoodsNum,
    ShopInfo, Cost, PayMoneyType) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 价格
            {PriceType, _Price} = data_goods:get_shop_price(ShopInfo, GoodsTypeInfo, PayMoneyType),
            %Cost = Price * GoodsNum,
            %% 扣钱
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, PriceType),
            GoodsInfo = case PriceType =:= point andalso GoodsTypeInfo#ets_goods_type.type =:= ?GOODS_TYPE_EQUIP
                            andalso GoodsTypeInfo#ets_goods_type.equip_type =/= ?GOODS_EQUIPTYPE_FASHION of
                            false -> 
                                lib_goods_util:get_new_goods(GoodsTypeInfo);
                            true ->
                                Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
                                Info#goods{prefix = 3}
                        end,
            %% 插入物品
            {ok, NewStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo, GoodsList),
            update_shop_counter(PlayerStatus#player_status.dailypid, NewStatus#goods_status.player_id, ShopInfo),
            log:log_consume(goods_pay, PriceType, PlayerStatus, NewPlayerStatus, GoodsInfo#goods.goods_id, GoodsNum, "pay for good"),
            
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus1 = NewStatus#goods_status{dict = Dict},
			%%添加消费送礼接口
			case PriceType of
				gold->
                    lib_activity:add_consumption(shangcheng,NewPlayerStatus,Cost),
                    F_NewPlayerStatus = lib_player:add_consumption(shangcheng,NewPlayerStatus,Cost,GoodsNum);
				_-> F_NewPlayerStatus = NewPlayerStatus
			end,
            case PriceType == gold orelse PriceType == silver_and_gold orelse PriceType == silver of
                true -> %% 运势任务(3700006:物美价廉)
					lib_fortune:fortune_daily(NewPlayerStatus#player_status.id, 3700006, 1);
                false -> skip
            end,
            {ok, F_NewPlayerStatus, NewStatus1}
        end,
    lib_goods_util:transaction(F).

%% 购买物品
pay_limit_goods(PlayerStatus, GoodsStatus, GoodsTypeInfo, GoodsList, GoodsNum, ShopInfo) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 价格
            case ShopInfo#ets_limit_shop.price_type of
                1 ->
                    PriceType = gold;
                2 ->
                    PriceType = bgold
            end,
            Cost = ShopInfo#ets_limit_shop.new_price * GoodsNum,
            %% 扣钱
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, PriceType),
            GoodsInfo = lib_goods_util:get_new_goods(GoodsTypeInfo),
            %% 插入物品
            {ok, NewStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, GoodsNum, GoodsInfo, GoodsList),
            update_limit_shop_counter(PlayerStatus#player_status.dailypid, NewStatus#goods_status.player_id, ShopInfo),
            log:log_consume(goods_pay, PriceType, PlayerStatus, NewPlayerStatus, GoodsInfo#goods.goods_id, GoodsNum, "pay_limit"),
            if
                ShopInfo#ets_limit_shop.new_price >= 58 ->
                    lib_chat:send_TV({all},0,2, ["qianggou", 
													NewPlayerStatus#player_status.id, 
													NewPlayerStatus#player_status.realm, 
													NewPlayerStatus#player_status.nickname, 
													NewPlayerStatus#player_status.sex, 
													NewPlayerStatus#player_status.career, 
													NewPlayerStatus#player_status.image, 
                                                    GoodsInfo#goods.goods_id]);
                true ->
                    skip
            end,
             Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
			
			%%添加消费送礼接口
			case PriceType of
				gold->F_NewPlayerStatus = lib_player:add_consumption(shangcheng,NewPlayerStatus,Cost,GoodsNum);
				_->F_NewPlayerStatus = NewPlayerStatus
			end,
            {ok, F_NewPlayerStatus, NewStatus2}
        end,
    lib_goods_util:transaction(F).

%% 出售物品
%% 返回  {ok, NewPlayerStatus, NewStatus} | Error
sell_goods(PlayerStatus, Status, NewCoin, NewBcoin, GoodsList) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 增加铜币
            NewPlayerStatus = PlayerStatus#player_status{bcoin = (PlayerStatus#player_status.bcoin + NewBcoin)},
            NewPlayerStatus2 = lib_goods_util:add_money(NewPlayerStatus, NewCoin, coin),
            %% 删除物品
            {ok, NewStatus} = lib_goods:delete_goods_list(Status, GoodsList),
            About = lists:concat([lists:concat([GoodsInfo#goods.id,":",GoodsInfo#goods.goods_id,":",GoodsNum,","]) || {GoodsInfo, GoodsNum} <- GoodsList]),
            log:log_produce(goods_sell, coin, PlayerStatus, NewPlayerStatus2, About),
            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
            {ok, NewPlayerStatus2, NewStatus2}
        end,
    lib_goods_util:transaction(F).

%%% 更新商店数量
update_shop_counter(DailyPid, PlayerId, ShopInfo) ->
    case ShopInfo#ets_shop.shop_type of
        ?SHOP_TYPE_GOLD ->
            case is_buy_continuous_shop_goods(ShopInfo#ets_shop.shop_type, ShopInfo#ets_shop.shop_subtype) of
                true ->
                    mod_daily:increment(DailyPid, PlayerId, 1503),
                    ok;
                false ->
                    skip
            end;
        _ ->
            skip
    end.

%% 更新限时商品数量
update_limit_shop_counter(DailyPid, PlayerId, ShopInfo) ->
    case ShopInfo#ets_limit_shop.unlimited =:= 1 of
        true ->
            %% 无限制,2时不减少
            case ShopInfo#ets_limit_shop.goods_num > 2 of
                true ->
                    if
			%% 开服物品
                        ShopInfo#ets_limit_shop.time_end > 0 andalso ShopInfo#ets_limit_shop.merge_end =:= 0 ->
                            update_limit_record(PlayerId, ShopInfo#ets_limit_shop.shop_id, ShopInfo#ets_limit_shop.list_id, 0);
			%% 合服物品
			ShopInfo#ets_limit_shop.merge_end > 0 andalso ShopInfo#ets_limit_shop.time_end =:= 0 ->
			    update_limit_record(PlayerId, ShopInfo#ets_limit_shop.shop_id, ShopInfo#ets_limit_shop.list_id, 1);
                        true ->
                            skip
                    end,
                    mod_daily:increment(DailyPid, PlayerId, ShopInfo#ets_limit_shop.limit_id),
                    %% 通知公共线更新
                    mod_disperse:cast_to_unite(ets, update_counter, [?ETS_LIMIT_SHOP, ShopInfo#ets_limit_shop.id, [{#ets_limit_shop.goods_num, -1}]]);
                false ->
                    if
                        %% 开服物品
                        ShopInfo#ets_limit_shop.time_end > 0 andalso ShopInfo#ets_limit_shop.merge_end =:= 0 ->
                            update_limit_record(PlayerId, ShopInfo#ets_limit_shop.shop_id, ShopInfo#ets_limit_shop.list_id, 0);
			%% 合服物品
			ShopInfo#ets_limit_shop.merge_end > 0 andalso ShopInfo#ets_limit_shop.time_end =:= 0 ->
			    update_limit_record(PlayerId, ShopInfo#ets_limit_shop.shop_id, ShopInfo#ets_limit_shop.list_id, 1);
			true ->
                            skip
                    end,
                    mod_daily:increment(DailyPid, PlayerId, ShopInfo#ets_limit_shop.limit_id)
            end;
        false ->
            if
                %% 开服物品
		ShopInfo#ets_limit_shop.time_end > 0 andalso ShopInfo#ets_limit_shop.merge_end =:= 0 ->
		    update_limit_record(PlayerId, ShopInfo#ets_limit_shop.shop_id, ShopInfo#ets_limit_shop.list_id, 0);
		%% 合服物品
		ShopInfo#ets_limit_shop.merge_end > 0 andalso ShopInfo#ets_limit_shop.time_end =:= 0 ->
		    update_limit_record(PlayerId, ShopInfo#ets_limit_shop.shop_id, ShopInfo#ets_limit_shop.list_id, 1);
		true ->
                    skip
            end,
            mod_daily:increment(DailyPid, PlayerId, ShopInfo#ets_limit_shop.limit_id),
            mod_disperse:cast_to_unite(ets, update_counter, [?ETS_LIMIT_SHOP, ShopInfo#ets_limit_shop.id, [{#ets_limit_shop.goods_num, -1}]])
    end.

%% 更新数据记录
update_limit_record(Pid, Pos, ListId, BuyType) ->
    Sql = io_lib:format(?sql_select_limit, [Pid]),
    case db:get_all(Sql) of
        [] ->
            case Pos of
                1 ->
                    Sql1 = io_lib:format(<<"insert into `limit_record` set `pid`=~p, `pos1`=~p, `buy_type`=~p">>, [Pid, ListId, BuyType]),
                    db:execute(Sql1),
		    Key = "select_limit" ++ integer_to_list(Pid),
		    mod_daily_dict:set_special_info(Key, [[ListId, 0, 0]]);
                2 ->
                    Sql1 = io_lib:format(<<"insert into `limit_record` set `pid`=~p, `pos2`=~p, `buy_type`=~p">>, [Pid, ListId, BuyType]),
                    db:execute(Sql1),
		    Key = "select_limit" ++ integer_to_list(Pid),
		    mod_daily_dict:set_special_info(Key, [[0, ListId, 0]]);
                3 ->
                    Sql1 = io_lib:format(<<"insert into `limit_record` set `pid`=~p, `pos3`=~p, `buy_type`=~p">>, [Pid, ListId, BuyType]),
                    db:execute(Sql1),
		    Key = "select_limit" ++ integer_to_list(Pid),
		    mod_daily_dict:set_special_info(Key, [[0, 0, ListId]]);
                _ ->
                    skip
            end;
        [[Pos1, Pos2, Pos3]] ->
            case Pos of
                1 ->
                    Sql1 = io_lib:format(<<"update `limit_record` set `pos1`=~p, `buy_type`=~p where pid=~p">>, [ListId, BuyType, Pid]),
                    db:execute(Sql1),
		    Key = "select_limit" ++ integer_to_list(Pid),
		    mod_daily_dict:set_special_info(Key, [[ListId, Pos2, Pos3]]);
                2 ->
                    Sql1 = io_lib:format(<<"update `limit_record` set `pos2`=~p, `buy_type`=~p where pid=~p">>, [ListId, BuyType, Pid]),
                    db:execute(Sql1),
		    Key = "select_limit" ++ integer_to_list(Pid),
		    mod_daily_dict:set_special_info(Key, [[Pos1, ListId, Pos3]]);
                3 ->
                    Sql1 = io_lib:format(<<"update `limit_record` set `pos3`=~p, `buy_type`=~p where pid=~p">>, [ListId, BuyType, Pid]),
                    db:execute(Sql1),
		    Key = "select_limit" ++ integer_to_list(Pid),
		    mod_daily_dict:set_special_info(Key, [[Pos1, Pos2, ListId]]);
                _ ->
                    skip
            end
    end.

get_limit_pay_record_and_type(Pid, Pos) ->
    Sql = io_lib:format(<<"select `pos1`, `pos2`, `pos3`, `buy_type` from `limit_record` where `pid` = ~p">>, [Pid]),
    case db:get_all(Sql) of
        [] ->
	    %% 4为排除所有类型，0开服，1合服，2活动，3普通
            {0, 4};
        [[Pos1, Pos2, Pos3, BuyType]] ->
            case Pos of
                1 ->
                    {Pos1, BuyType};
                2 ->
                    {Pos2, BuyType};
                3 ->
                    {Pos3, BuyType};
                _ ->
                    {[], 4}
            end
    end.
	
%% ---------------------------------------------------------------------------------------------------------
%% 取商店物品列表
get_shop_list(ShopType, ShopSubtype) ->
    case ShopSubtype > 0 of
        true -> 
            data_shop:get_shop_list(ShopType, ShopSubtype);
        false when ShopType =/= ?SHOP_TYPE_GOLD -> 
            data_shop:get_shop_list(ShopType, 0);
        false -> 
            data_shop:get_shop_list(ShopType)
    end.

%% 取商店物品列表
get_shop_info(ShopType, ShopSubtype, GoodsTypeId) ->
    data_shop:get_by_goods(ShopType, ShopSubtype, GoodsTypeId).


%% -------------------- 限时热卖 --------------------------------------------------------
%% 取限时商品物品信息
get_limit_shop_info(Pos, GoodsId) ->
    Pattern = #ets_limit_shop{shop_id = Pos, id = GoodsId, _ = '_'},
    case ets:match_object(?ETS_LIMIT_SHOP, Pattern) of
        [ShopInfo|_] ->
            ShopInfo;
        _ ->
            []
    end.

%% 取限时商品列表
get_limit_list(Id) ->
    OpenDay = util:get_open_day(),
    MergeTime = lib_activity_merge:get_activity_time(),
    Now = util:unixtime(),
    MergeDay = util:get_diff_days(Now, MergeTime),
    case OpenDay =< ?OPEN_DAYS orelse (MergeTime =/= 0 andalso MergeDay =< ?MERGE_DAYS) of
        true ->
	    L =
		if
		    %% 开服3天内
		    OpenDay =< ?OPEN_DAYS andalso MergeTime =:= 0 ->
			Key = "select_limit" ++ integer_to_list(Id),
			case mod_daily_dict:get_special_info(Key) of
			    undefined ->
				Sql = io_lib:format(?sql_select_limit, [Id]),
				Result = db:get_all(Sql),
				mod_daily_dict:set_special_info(Key, Result),
				Result;
			    Any ->
				Any
			end;
		    true ->
			Key = "select_limit" ++ integer_to_list(Id),
			case mod_daily_dict:get_special_info(Key) of
			    undefined ->
				Sql = io_lib:format(<<"select `pos1`, `pos2`, `pos3`, `buy_type` from `limit_record` where `pid` = ~p">>, [Id]),
				Result = case db:get_all(Sql) of
					     [] -> [];
					     [[_Pos1,_Pos2,_Pos3,_BuyType]] ->
						 case _BuyType =:= 0 of
						     true ->
							 %% 清掉开服购买过的记录
							 db:execute(io_lib:format(<<"delete from `limit_record` where `pid`=~p">>, [Id])),
							 [];
						     false -> [[_Pos1,_Pos2,_Pos3]]
						 end
					 end,
				mod_daily_dict:set_special_info(Key, Result),
				Result;
			    Any ->
				Any
			end
		end,
           case L of
               [] ->
                   List1 = get_single_info_new(1, 1),
                   NewList = check_shop_list([List1]),
                   List2 = get_single_info_new(2, 1),
                   NewList2 = check_shop_list([List2]),
                   List3 = get_single_info_new(3, 1),
                   NewList3 = check_shop_list([List3]);
               [[Pos1, Pos2, Pos3]] ->
                   if
                       Pos1 =:= 0 ->
                           List1 = get_single_info_new(1, 1);
                       true ->
                           List = get_single_info_new(1, Pos1+1),
                           case List of
                               [] ->
                                   List1 = get_single_info_new(1, Pos1);
                               _ ->
                                   List1 = List
                           end
                   end,
                   NewList = check_shop_list([List1]),
                   if
                       Pos2 =:= 0 ->
                           List2 = get_single_info_new(2, 1);
                       true ->
                           List22 = get_single_info_new(2, Pos2+1),
                           case List22 of
                               [] ->
                                   List2 = get_single_info_new(2, Pos2);
                               _ ->
                                   List2 = List22
                           end
                   end,
                   NewList2 = check_shop_list([List2]),
                   if
                       Pos3 =:= 0 ->
                           List3 = get_single_info_new(3, 1);
                       true ->
                           List33 = get_single_info_new(3, Pos3+1),
                           case List33 of
                               [] ->
                                   List3 = get_single_info_new(3, Pos3);
                               _ ->
                                   List3 = List33
                           end
                   end,
                   NewList3 = check_shop_list([List3])
           end;
        false ->
            List1 = get_single_info(?POS_ONE),
            if
                List1 =:= [] ->
                    init_limit_shop({0, 0, 0}),
                    List11 = get_single_info(?POS_ONE);
                true ->
                    List11 = List1
            end,
            NewList = check_shop_list([List11]),
            List2 = get_single_info(?POS_TWO),
            if
                List2 =:= [] ->
                    init_limit_shop({0, 0, 0}),
                    List22= get_single_info(?POS_TWO);
                true ->
                    List22 = List2
            end,
            NewList2 = check_shop_list([List22]),
            List3 = get_single_info(?POS_THREE),
            if
                List3 =:= [] ->
                    init_limit_shop({0, 0, 0}),
                    List33= get_single_info(?POS_THREE);
                true ->
                    List33 = List3
            end,
            NewList3 = check_shop_list([List33])
    end,
    NewList++NewList2++NewList3.


%% 取单个位置物品
get_single_info(Pos) ->
    Pattern = #ets_limit_shop{shop_id = Pos, _='_'},
    case ets:match_object(?ETS_LIMIT_SHOP, Pattern) of
        [List] ->
            List;
        _ ->
            []
    end.

%% 取单个位置物品
get_single_info_new(Pos, ListId) ->
    Pattern = #ets_limit_shop{shop_id = Pos, list_id = ListId, _='_'},
    case ets:match_object(?ETS_LIMIT_SHOP, Pattern) of
        [List] ->
            List;
        _ ->
            []
    end.

get_info_by_goods_id(GoodsTypeId) ->
    Pattern = #ets_limit_shop{goods_id = GoodsTypeId, _='_'},
    case ets:match_object(?ETS_LIMIT_SHOP, Pattern) of
        [List|_] ->
            List;
        _ ->
            []
    end.

%% 取 shop 列表
get_limit_shop_list(Pos) ->
    Pattern =  #ets_limit_shop{shop_id=Pos, _='_'},
    ShopList = ets:match_object(?ETS_LIMIT_SHOP, Pattern),
    NewShopList = check_shop_list(ShopList),
    NewShopList.

%% 检查
check_shop_list([]) -> [];
check_shop_list([ShopInfo|T]) ->
    if
        is_record(ShopInfo, ets_limit_shop) =:= true ->
            case ShopInfo#ets_limit_shop.price_list =:= [] of
                true ->
                    [ShopInfo | check_shop_list(T)];
                false ->    %% 有价格变化
                    F = fun({Min, Max, Price}, Info) ->
                        case Info#ets_limit_shop.goods_num > Min andalso Info#ets_limit_shop.goods_num < Max of
                            true ->
                                Info#ets_limit_shop{new_price = Price};
                            false ->
                                skip
                        end
                    end,
                    [F(List, ShopInfo) || List <- ShopInfo#ets_limit_shop.price_list],
                    [ShopInfo | check_shop_list(T)]
            end;
        true ->
            [#ets_limit_shop{} | check_shop_list(T)]
    end.
            
%% 初始化限时抢购
init_limit_shop({Id1, Id2, Id3}) ->
    case Id1=:=0 andalso Id2=:=0 andalso Id3=:=0 of
        true ->
            ets:delete_all_objects(?ETS_LIMIT_SHOP);
        false ->
            skip
    end,
    %%开服第几天
    OpenDay = util:get_open_day(),
    NowTime = util:unixtime(),
    OpenTime = util:get_open_time(),
    %% 合服第几天
    MergeTime = lib_activity_merge:get_activity_time(),
    MergeDay = util:get_diff_days(NowTime, MergeTime),
    if
	OpenDay =< ?OPEN_DAYS ->
            init_limit_open_days();
	MergeTime =/= 0 andalso MergeDay =< ?MERGE_DAYS ->
	    %% 合服天数暂时不写进hrl
	    init_limit_merge_days();
        true ->
	    case Id1 =:= 0 of
		true ->
		    L1 = data_limit_shop:get_by_shop_id(?POS_ONE),
		    case length(L1) > 0 of
			true ->
			    NewId1 = replace_limit_goods(L1, OpenDay, MergeDay, NowTime, OpenTime, MergeTime);
			false ->
			    NewId1 = Id1
		    end;
		false ->
		    renew_limit_num(Id1),
		    NewId1 = Id1
	    end,
	    case Id2 =:= 0 of
		true ->
		    L2 = data_limit_shop:get_by_shop_id(?POS_TWO),
		    case length(L2) > 0 of
			true ->
			    NewId2 = replace_limit_goods(L2, OpenDay, MergeDay, NowTime, OpenTime, MergeTime);
			false ->
			    NewId2 = Id2
		    end;
		false ->
		    renew_limit_num(Id2),
		    NewId2 = Id2
	    end,
	    case Id3 =:= 0 of
		true ->
		    L3 = data_limit_shop:get_by_shop_id(?POS_THREE),
		    case length(L3) > 0 of
			true ->
			    NewId3 = replace_limit_goods(L3, OpenDay, MergeDay, NowTime, OpenTime, MergeTime);
			false ->
			    NewId3 = Id3
		    end;
		false ->
		    renew_limit_num(Id3),
		    NewId3 = Id3
	    end,
	    {NewId1, NewId2, NewId3}
    end.

%% @param: OpenDay开服天数，MergeDay合服天数，NowTime当前时间，OpenTime开服时间戳，MergeTime合服时间戳
%% @return: GoodsTypeId
%% 替换限时抢购物品
replace_limit_goods(List, OpenDay, MergeDay, NowTime, OpenTime, MergeTime) ->
    %% 开服
    OpenList = [ShopInfo || ShopInfo <- List, ShopInfo#ets_limit_shop.goods_id =/= 0 
				 andalso ShopInfo#ets_limit_shop.time_begin =< OpenDay
				 andalso ShopInfo#ets_limit_shop.time_end >= OpenDay],
    Len = length(OpenList),
    case Len > 0 of
	true -> %% 有开服物品
	    OpenInfo = lists:nth(util:rand(1, Len), OpenList),
	    Day = OpenInfo#ets_limit_shop.time_end,
	    Info = OpenInfo#ets_limit_shop{time_end = OpenTime + Day * 86400},
	    ets:insert(?ETS_LIMIT_SHOP, Info),
	    Info#ets_limit_shop.goods_id;
	false ->
	    MergeList = [ShopInfo || ShopInfo <- List, ShopInfo#ets_limit_shop.goods_id =/= 0
					 andalso ShopInfo#ets_limit_shop.time_begin =:= 0
					 andalso ShopInfo#ets_limit_shop.time_end =:= 0
					 andalso ShopInfo#ets_limit_shop.merge_begin =< MergeDay
					 andalso ShopInfo#ets_limit_shop.merge_end >= MergeDay],
	    MergeLen = length(MergeList),
	    case MergeLen > 0 of
		true -> %% 有合服物品
		    MergeInfo = lists:nth(util:rand(1, MergeLen), MergeList),
		    Day = MergeInfo#ets_limit_shop.merge_end,
		    Info = MergeInfo#ets_limit_shop{merge_end = MergeTime + Day * 86400},
		    ets:insert(?ETS_LIMIT_SHOP, Info),
		    Info#ets_limit_shop.goods_id;
		false ->
		    %% 活动物品
		    ActivityList = [ShopInfo || ShopInfo <- List, ShopInfo#ets_limit_shop.goods_id =/= 0 
						    andalso ShopInfo#ets_limit_shop.time_begin =:= 0
						    andalso ShopInfo#ets_limit_shop.time_end =:= 0
						    andalso ShopInfo#ets_limit_shop.merge_begin =:= 0
						    andalso ShopInfo#ets_limit_shop.merge_end =:= 0
						    andalso ShopInfo#ets_limit_shop.activity_begin =< NowTime
						    andalso ShopInfo#ets_limit_shop.activity_end > NowTime],
		    LenActivityList = length(ActivityList),
		    case LenActivityList > 0 of
			true ->     %%有活动物品
			    ActivityInfo = lists:nth(util:rand(1, LenActivityList), ActivityList),
			    ets:insert(?ETS_LIMIT_SHOP, ActivityInfo),
			    ActivityInfo#ets_limit_shop.goods_id;
			false ->
			    DefaltList = [ShopInfo || ShopInfo <- List, ShopInfo#ets_limit_shop.goods_id =/= 0
							  andalso ShopInfo#ets_limit_shop.time_begin =:= 0
							  andalso ShopInfo#ets_limit_shop.time_end =:= 0
							  andalso ShopInfo#ets_limit_shop.merge_begin =:= 0
							  andalso ShopInfo#ets_limit_shop.merge_end =:= 0
							  andalso ShopInfo#ets_limit_shop.activity_begin =:= 0
							  andalso ShopInfo#ets_limit_shop.activity_end =:= 0],
			    DefaltInfo = lists:nth(util:rand(1, length(DefaltList)), DefaltList),
			    ets:insert(?ETS_LIMIT_SHOP, DefaltInfo),
			    DefaltInfo#ets_limit_shop.goods_id
		    end
	    end
    end.
    
%% 物品是否过期
is_expired(ShopInfo) ->
    Now = util:unixtime(),
    if
        ShopInfo#ets_limit_shop.time_end > 0 andalso ShopInfo#ets_limit_shop.time_end =< Now ->
            true;
        ShopInfo#ets_limit_shop.merge_end > 0 andalso ShopInfo#ets_limit_shop.merge_end =< Now ->
            true;
        ShopInfo#ets_limit_shop.activity_end > 0 andalso ShopInfo#ets_limit_shop.activity_end =< Now ->
            true;
        true ->
            false
    end.

%% 是否要重新加载
is_need_refresh({Id1, Id2, Id3}) ->
    ShopInfo1 = get_info_by_goods_id(Id1),
    ShopInfo2 = get_info_by_goods_id(Id2),
    ShopInfo3 = get_info_by_goods_id(Id3),
    case is_expired(ShopInfo1) =:= true orelse is_expired(ShopInfo2) =:= true orelse is_expired(ShopInfo3) =:= true of
        true ->
            true;
        false ->
            false
    end.
    
%% 处理恢复物品数量
renew_limit_num(GoodsTypeId) ->
    Pattern = #ets_limit_shop{goods_id = GoodsTypeId, _ = '_'},
    case ets:match_object(?ETS_LIMIT_SHOP, Pattern) of
        [ShopInfo|_] ->
            case ShopInfo#ets_limit_shop.refresh =:= 1 of %%要刷新
                true ->
                    List = data_limit_shop:get_by_shop_id(ShopInfo#ets_limit_shop.shop_id),
                    case length(List) > 0 of
                        true ->
                            InfoList = [Info || Info <- List, Info#ets_limit_shop.shop_id =:= ShopInfo#ets_limit_shop.shop_id
                                      andalso Info#ets_limit_shop.refresh =:= ShopInfo#ets_limit_shop.refresh 
                                      andalso Info#ets_limit_shop.goods_id =:= ShopInfo#ets_limit_shop.goods_id
                                      andalso Info#ets_limit_shop.time_begin =:= ShopInfo#ets_limit_shop.time_begin
                                      andalso Info#ets_limit_shop.time_end =:= ShopInfo#ets_limit_shop.time_end
						    andalso Info#ets_limit_shop.merge_begin =:= ShopInfo#ets_limit_shop.merge_begin
						    andalso Info#ets_limit_shop.merge_end =:= ShopInfo#ets_limit_shop.merge_end
                                      andalso Info#ets_limit_shop.activity_begin =:= ShopInfo#ets_limit_shop.activity_begin
                                      andalso Info#ets_limit_shop.activity_end =:= ShopInfo#ets_limit_shop.activity_end],
                            [OldInfo | _] = InfoList,
                            %% 更新数量
                            ets:update_element(?ETS_LIMIT_SHOP, ShopInfo#ets_limit_shop.id, {#ets_limit_shop.goods_num, OldInfo#ets_limit_shop.goods_num});
                        false ->
                            skip
                    end;
                false ->
                    skip
            end;
        _ ->
            skip
    end.

%% gate_update_open_time(Time) ->
%%     OldFlag = util:check_open_day(?OPEN_DAYS),
%%     R = #server_status{name=open_time, value=Time},
%%     ets:insert(?SERVER_STATUS, R),
%%     NewFlag = util:check_open_day(?OPEN_DAYS),
%%     case NewFlag =/= OldFlag of
%%         true -> 
%%             init_limit_shop({0, 0, 0});
%%         false -> 
%%             skip
%%     end,
%%     ok.

%%% =================================================
%%%                     连续登录商店
%%% =================================================
query_continuous_login_shop_goods_list(PlayerStatus) ->
    case ets:lookup(?ETS_LOGIN_COUNTER, PlayerStatus#player_status.id) of
        [EtsLoginCounter] ->
            ContinuousDays = EtsLoginCounter#ets_login_counter.continuous_days,
            {ShopType, ShopSubtype} = query_shop_id_by_continuous_days(ContinuousDays),
            GoodsList = get_shop_list(ShopType, ShopSubtype),
            {ShopType, ShopSubtype, GoodsList};
        _ ->
            {1, 0, []}
    end.

query_shop_id_by_continuous_days(ContinuousDays) ->
    if
        ContinuousDays >= 60 -> {1, 65};
        ContinuousDays >= 55 -> {1, 64};
        ContinuousDays >= 50 -> {1, 63};
        ContinuousDays >= 45 -> {1, 62};
        ContinuousDays >= 40 -> {1, 61};
        ContinuousDays >= 35 -> {1, 60};
        ContinuousDays >= 30 -> {1, 59};
        ContinuousDays >= 25 -> {1, 58};
        ContinuousDays >= 20 -> {1, 57};
        ContinuousDays >= 15 -> {1, 56};
        ContinuousDays >= 10 -> {1, 55};
        ContinuousDays >= 7 -> {1, 54};
        ContinuousDays >= 5 -> {1, 53};
        ContinuousDays >= 3 -> {1, 52};
        ContinuousDays >= 2 -> {1, 51};
        ContinuousDays >= 1 -> {1, 50};
        true -> {0, 0}
    end.

is_buy_continuous_shop_goods(ShopType, ShopSubtype) ->
    ShopType =:= ?SHOP_TYPE_GOLD andalso ShopSubtype >= 50 andalso ShopSubtype =< 65.

%% ------------------------------------------------- 
%% 开服前几天
init_limit_open_days() ->
    OpenDay = util:get_open_day(),
    OpenTime = util:get_open_time(),
    L = data_limit_shop:get_all_data(),
    OpenList = [ShopInfo || ShopInfo <- L, ShopInfo#ets_limit_shop.goods_id =/= 0 
                            andalso ShopInfo#ets_limit_shop.time_begin =< OpenDay
                            andalso ShopInfo#ets_limit_shop.time_end >= OpenDay],
    F = fun(ShopInfo) ->
            Day = ShopInfo#ets_limit_shop.time_end,
            Info = ShopInfo#ets_limit_shop{time_end = OpenTime + Day * 86400},
            ets:insert(?ETS_LIMIT_SHOP, Info)
    end,
    lists:map(F, OpenList),
    {0,0,0}.

%% 合服前几天
init_limit_merge_days() ->
    MergeTime = lib_activity_merge:get_activity_time(),
    Now = util:unixtime(),
    OpenDay = util:get_diff_days(Now, MergeTime),
    L = data_limit_shop:get_all_data(),
    OpenList = [ShopInfo || ShopInfo <- L, ShopInfo#ets_limit_shop.goods_id =/= 0 
				andalso ShopInfo#ets_limit_shop.merge_begin =< OpenDay
				andalso ShopInfo#ets_limit_shop.merge_end >= OpenDay],
    F = fun(ShopInfo) ->
		Day = ShopInfo#ets_limit_shop.merge_end,
		Info = ShopInfo#ets_limit_shop{merge_end = MergeTime + Day * 86400},
		ets:insert(?ETS_LIMIT_SHOP, Info)
	end,
    lists:map(F, OpenList),
    {0,0,0}.

get_new_limit_goods(Pos) ->
    OpenDay = util:get_open_day(),
    case OpenDay =< ?OPEN_DAYS of
        true ->
            NewId = Pos + 3,
            if 
                NewId < 10 ->
                    ShopInfo = get_single_info(NewId);
                true ->
                    ShopInfo = get_single_info(Pos)
            end;
        false ->
            ShopInfo = get_single_info(Pos)
    end,
    ShopInfo.



