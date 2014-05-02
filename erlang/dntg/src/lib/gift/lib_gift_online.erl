%%%--------------------------------------
%%% @Module  : lib_gift_online
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.22
%%% @Description: 在线礼包
%%%--------------------------------------

-module(lib_gift_online).
-compile(export_all).
-include("server.hrl").
-include("gift_online.hrl").

%%=========================================醉西游：在线礼包========================================================= 
%% 玩家登录后，获得在线倒计时奖励数据
get_online_award_info(PS) ->
	[FirstGiftId, FirstTime, _, _] = get_lb_base(1),
	NowTime = util:unixtime(),
	case db:get_row(io_lib:format(?SQL_ONLINE_AWARD_GET, [PS#player_status.id])) of
		%% 如果没有记录，则需插入一条
		[] ->
			db:execute(io_lib:format(?SQL_ONLINE_AWARD_INSERT, [PS#player_status.id, 0, NowTime, FirstTime])),
			{next, [FirstGiftId, FirstTime, [0, NowTime, FirstTime]]};
		Row ->
			ZeroTime = util:unixdate(),
			[GetNum, LastOffline, NeedTime] = Row,
			case NowTime >= ZeroTime andalso LastOffline < ZeroTime of
				%% 如果昨天下线，今天上线，则重新计数
				true ->
					db:execute(io_lib:format(?SQL_ONLINE_AWARD_UPDATE, [0, NowTime, FirstTime, PS#player_status.id])),
					{next, [FirstGiftId, FirstTime, [0, NowTime, FirstTime]]};
				%% 今天下线今天再上线的
				_ ->
					[NowGiftId, _, _, _] = get_lb_base(GetNum + 1),
					{next, [NowGiftId, NeedTime, [GetNum, LastOffline, NeedTime]]}
			end
	end.

%% 领取在线倒计时奖励
fetch_online_award(PS) ->
	case PS#player_status.online_award of
		[GetNum, LastOffline, NeedTime] ->
			NowTime = util:unixtime(),
			Go = PS#player_status.goods,
			CheckTime01 = util:unixtime(?SP_ONLINE_START_AT),
			CheckTime02 = util:unixtime(?SP_ONLINE_END_AT),
			%% 看是否有下一个礼包
			[GiftId, Type, Num, NextGiftId, NextNeedtime] = case NowTime > CheckTime01 andalso NowTime < CheckTime02 of
				true -> %% 特殊倒计时
					[GiftId0, _] = data_gift_config:get_newyear_data(GetNum + 1),
					[NextGiftId0, NextNeedtime0] = data_gift_config:get_newyear_data(GetNum + 2),
					case GiftId0 > 0  of
						true ->
							[GiftId0, 1, GetNum + 1, NextGiftId0, NextNeedtime0];
						_ ->
							[0, 0, 0, NextGiftId0, NextNeedtime0]
					end;
				false -> %% 正常倒计时
					[GiftId0, _] = data_gift_config:get_online_data(GetNum + 1),
					[NextGiftId0, NextNeedtime0] = data_gift_config:get_online_data(GetNum + 2),
					case GiftId0 > 0  of
						true ->
							[GiftId0, 0, 0, NextGiftId0, NextNeedtime0];
						_ ->
							[0, 0, 0, NextGiftId0, NextNeedtime0]
					end
			end,
			case GiftId > 0  of
				true ->
					case NowTime - LastOffline >= NeedTime of
						true ->
							case gen:call(Go#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
								{ok, [ok, NewPS]} ->
									%% 修改数据库
									db:execute(io_lib:format(?SQL_ONLINE_AWARD_UPDATE, [GetNum + 1, NowTime, NextNeedtime, PS#player_status.id])),
									NewRecord =  [GetNum + 1, NowTime, NextNeedtime],
									case NextGiftId > 0 of
										true -> %% 还有
											{[1, GiftId, NextNeedtime, Type, Num], NewPS#player_status{online_award = NewRecord}};
										false -> %% 最后一个了
											%% 运势任务(3700013:在线有礼)
											lib_fortune:fortune_daily(PS#player_status.id, 3700013, 1),
											{[1, GiftId, 0, Type, Num], NewPS#player_status{online_award = NewRecord}}
									end;
								{ok, [error, ErrorCode]} ->
									{[ErrorCode, GiftId, NowTime - LastOffline, Type, Num], PS}
							end;
						false -> %% 时间未到，继续返回数据给前端倒计时
							LeftTime = NeedTime - (NowTime - LastOffline),
							{[102, GiftId, LeftTime, Type, Num], PS}
					end;
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%% %% 玩家下线时处理在线倒计时奖励
%% offline_do_onlie_award(PS) ->
%% 	Record = PS#player_status.online_award,
%% 	case Record =/= [] of
%% 		true ->
%% 			NowTime = util:unixtime(),
%% 			[GetNum, LastOffline, NeedTime] = Record,
%% 			case GetNum >= data_gift_config:max_online_num() of
%% 				true ->
%% 					skip;
%% 				_ ->
%% 					TmpTime = NeedTime - (NowTime - LastOffline),
%% 					NewNeedTime = case TmpTime >= 0 of
%% 						true -> TmpTime;
%% 						_ -> 0
%% 					end,
%% 					db:execute(io_lib:format(?SQL_ONLINE_AWARD_UPDATE, [GetNum, NowTime, NewNeedTime, PS#player_status.id]))
%% 			end;
%% 		_ ->
%% 		skip
%% 	end.

%% 获取可以领取的礼包信息
get_lb_base(GetNum) ->
	NowTime = util:unixtime(),
	CheckTime01 = util:unixtime(?SP_ONLINE_START_AT),
	CheckTime02 = util:unixtime(?SP_ONLINE_END_AT),
	[GiftId, Time, Type, Num] = case NowTime > CheckTime01 andalso NowTime < CheckTime02 of
		true -> %% 特殊倒计时
			[GiftId0, Time0] = data_gift_config:get_newyear_data(GetNum),
			case GiftId0 > 0  of
				true ->
					[GiftId0, Time0, 1, GetNum];
				_ ->
					[0, 0, 0, 0]
			end;
		false -> %% 正常倒计时
			[GiftId0, Time0] = data_gift_config:get_online_data(GetNum),
			case GiftId0 > 0  of
				true ->
					[GiftId0, Time0, 0, 0];
				_ ->
					[0, 0, 0, 0]
			end
	end,
	[GiftId, Time, Type, Num].

%%=========================================大闹天空：在线礼包=========================================================
%% 玩家登录后，获得在线倒计时奖励数据
load(RoleId, Lv)->
    [MinLv, MaxLv] = data_gift_config:get_config(lv_qj),
    if
        Lv < MinLv orelse Lv > MaxLv ->
            [];
        true -> 
            NowTime = util:unixtime(),
            case db:get_row(io_lib:format(?SQL_ONLINE_INFO, [RoleId])) of
                %% 如果没有记录，则需插入一条
                [] ->
                    InitGiftList1 = data_online_gift:get_online_gift_by_lv(Lv),
                    InitGiftList = util:term_to_string(InitGiftList1),
                    db:execute(io_lib:format(?SQL_ONLINE_INSERT, [RoleId, 0, InitGiftList, 0, NowTime])),
                    NewOnlineGift = #login_online_gift{role_id=RoleId, count=0, gift_list=InitGiftList1, online_time=0, time=NowTime},
                    NewOnlineGift;
                Row ->
                    ZeroTime = util:unixdate(),
                    [_RoleId, Count, GiftList1, OnlineTime, Time] = Row,
                    case NowTime >= ZeroTime andalso Time < ZeroTime of
                        %% 如果昨天下线，今天上线，则重新计数
                        true ->
                            InitGiftList1 = data_online_gift:get_online_gift_by_lv(Lv),
                            InitGiftList = util:term_to_string(InitGiftList1),
                            db:execute(io_lib:format(?SQL_ONLINE_UPDATE, [0, InitGiftList, 0, NowTime, RoleId])),
                            NewOnlineGift = #login_online_gift{role_id=RoleId, count=0, gift_list=InitGiftList1, online_time=0, time=NowTime},
                            NewOnlineGift;
                        %% 今天下线今天再上线的
                        _ ->
                            GiftList =  util:bitstring_to_term(GiftList1),
                            NewOnlineGift = #login_online_gift{role_id=RoleId, count=Count, gift_list=GiftList, 
                                                               online_time=OnlineTime, time=NowTime},
                            NewOnlineGift
                    end
            end
    end.


%% 获取玩家的在线礼包数据
get_online_gift_info(PS) ->
    Record = case PS#player_status.online_award of
                 [] ->
                     load(PS#player_status.id, PS#player_status.lv);
                 OnlineGiftRecord ->
                     Time = OnlineGiftRecord#login_online_gift.time,
                     case util:diff_day(Time) > 0 of
                         true -> 
                             load(PS#player_status.id, PS#player_status.lv);
                         false ->
                             OnlineGiftRecord
                     end
             end,
    update_online_gift_info(Record).


%% 获取数据的时候，对数据做一次更新
update_online_gift_info(Record)->
    NowTime = util:unixtime(),
    RoleId = Record#login_online_gift.role_id,
    LoginTime = Record#login_online_gift.time,
    OnlineTime = Record#login_online_gift.online_time,
    GiftList = Record#login_online_gift.gift_list,
    NewOnlineTime = OnlineTime + NowTime - LoginTime,
    NewGiftList = change_online_gift_state(GiftList, NewOnlineTime),
    if
        NewGiftList =:= GiftList ->
            UpSQL = io_lib:format(?SQL_ONLINE_TIME_UPDATE, [NewOnlineTime, NowTime, RoleId]),
            db:execute(UpSQL),
            Record#login_online_gift{online_time=NewOnlineTime, time=NowTime};
        true ->
            SGiftList = util:term_to_string(NewGiftList),
            UpSQL = io_lib:format(?SQL_ONLINE_UPDATE, [Record#login_online_gift.count, SGiftList, NewOnlineTime, NowTime, RoleId]),
            db:execute(UpSQL),
            Record#login_online_gift{online_time=NewOnlineTime, gift_list=NewGiftList, time=NowTime}
    end.

%% 如果物品可以领取就变成可领取状态
change_online_gift_state(GiftList, OnlineTime)->
    TempOnlineTime = OnlineTime+3,
    lists:map(fun({Id, GoodInfo, TimeSpan, IsGet})->
                      if
                          TempOnlineTime > TimeSpan ->
                              if
                                  IsGet =:= 0 ->
                                      {Id, GoodInfo, TimeSpan, 1};
                                  IsGet =:= 1 ->
                                      {Id, GoodInfo, TimeSpan, 1};
                                  true ->
                                      {Id, GoodInfo, TimeSpan, 2}
                              end;
                          true ->
                              {Id, GoodInfo, TimeSpan, IsGet}
                      end
              end, GiftList).

%% 获取对应的数据
fetch_online_gift_info(Record, Type)->
    case Type of
        online_time -> Record#login_online_gift.online_time;
        gift_list -> Record#login_online_gift.gift_list;
        _ -> type_error
    end.

%% 领取物品
get_online_gift_op(PS, TypeId)->
    NowTime = util:unixtime(),
    Goods = PS#player_status.goods,
    Record = get_online_gift_info(PS),
    Count = Record#login_online_gift.count,
    GiftList = Record#login_online_gift.gift_list,
    MaxCount = data_gift_config:get_config(max_count),
    if
        Count > MaxCount ->
            {fail, 4};
        true ->
            case TypeId of
                13 ->
                    [Count1, GoodsList, NewGiftList] = count_gift_list(GiftList),
                    if
                        Count1 =< 0 ->
                            {fail, 5};
                        true ->
                            [Coin, BGold, GoodsLen, GoodsList1] = count_gold_list(GoodsList, 0, 0, []),
                            case GoodsLen =< 0 of
                                true ->
                                    NewPS = give_online_money(Coin, BGold, PS),
                                    NewCount = Count + Count1,
                                    NewOnlineGiftRecord = update_online_gift_info(Record, NewCount, NowTime, NewGiftList),
                                    {ok, 1, NewPS#player_status{online_award = NewOnlineGiftRecord}};
                                false ->
                                    CellNum = gen_server:call(Goods#status_goods.goods_pid, {'cell_num'}),
                                    if
                                        CellNum < GoodsLen ->
                                            {fail, 2};
                                        true ->
                                            case gen_server:call(Goods#status_goods.goods_pid, {'give_more_bind', PS, GoodsList1}) of
                                                ok -> 
                                                    NewPS = give_online_money(Coin, BGold, PS),
                                                    NewCount = Count + Count1,
                                                    NewOnlineGiftRecord = update_online_gift_info(Record, NewCount, NowTime, NewGiftList),
                                                    {ok, 1, NewPS#player_status{online_award = NewOnlineGiftRecord}};
                                                _ ->
                                                    {fail, 0}
                                            end
                                    end
                            end
                    end;
                TypeId ->
                    case lists:keyfind(TypeId, 1, GiftList) of
                        false -> {fail, 6};
                        {TypeId, [{GoodType, GoodId, Num}], _TimeSpan, IsGet} ->
                            if
                                IsGet =:= 0 -> {fail, 5};
                                IsGet =:= 2 -> {fail, 3};
                                true ->
                                    CellNum = gen_server:call(Goods#status_goods.goods_pid, {'cell_num'}),
                                    if
                                        CellNum < 1 ->
                                            {fail, 2};
                                        true ->
                                            case GoodType of
                                                1 ->
                                                    case gen_server:call(Goods#status_goods.goods_pid, {'give_more_bind',PS,[{GoodId, Num}]}) of
                                                        ok -> 
                                                            NewCount = Count + 1,
                                                            NewTuple = {TypeId, [{GoodType, GoodId, Num}], _TimeSpan, 2},
                                                            NewGiftList = lists:keyreplace(TypeId, 1, GiftList, NewTuple),
                                                            NewOnlineGiftRecord=update_online_gift_info(Record, NewCount, NowTime, NewGiftList),
                                                            {ok, 1, PS#player_status{online_award = NewOnlineGiftRecord}};
                                                        _ ->
                                                            {fail, 0}
                                                    end;
                                                2 ->
                                                    NewCount = Count + 1,
                                                    NewTuple = {TypeId, [{GoodType, GoodId, Num}], _TimeSpan, 2},
                                                    NewGiftList = lists:keyreplace(TypeId, 1, GiftList, NewTuple),
                                                    NewOnlineGiftRecord = update_online_gift_info(Record, NewCount, NowTime, NewGiftList),
                                                    NewPS = lib_player:add_money(PS, Num, bcoin),
                                                    log:log_produce(equip_zhuan_pan_coin, bcoin, PS, NewPS, "online_gift_coin"),
                                                    {ok, 1, NewPS#player_status{online_award = NewOnlineGiftRecord}};
                                                3 ->
                                                    NewCount = Count + 1,
                                                    NewTuple = {TypeId, [{GoodType, GoodId, Num}], _TimeSpan, 2},
                                                    NewGiftList = lists:keyreplace(TypeId, 1, GiftList, NewTuple),
                                                    NewOnlineGiftRecord = update_online_gift_info(Record, NewCount, NowTime, NewGiftList),
                                                    NewPS = lib_player:add_money(PS, Num, bgold),
                                                    log:log_produce(equip_zhuan_pan_bgold, bgold, PS, NewPS, "online_gift_bglod"),
                                                    {ok, 1, NewPS#player_status{online_award = NewOnlineGiftRecord}};
                                                _ ->
                                                    {fail, 7}
                                            end
                                    
                                    end
                            end
                    end
            end
    end.


%% 计算领取的物品个数和物品列表和返回新的在线礼品数据
count_gift_list(GiftList)->
    Fun = fun(E, [TempCount, TempGoodsList, TempGiftList])->
                  {TypeId, GoodInfo, TimeSpan, IsGet} = E,
                  if
                      IsGet =:= 1 ->
                          E1 = {TypeId, GoodInfo, TimeSpan, 2},
                          NewTempGiftList = lists:keyreplace(TypeId, 1,TempGiftList, E1),
                          [TempCount+1, [GoodInfo|TempGoodsList], NewTempGiftList];
                      true ->
                          [TempCount, TempGoodsList, TempGiftList]
                  end
          end,
    [Count, GoodsList, GiftList1] = lists:foldl(Fun, [0, [], GiftList], GiftList),
    GoodsList1 = lists:flatten(GoodsList),
    [Count, GoodsList1, lists:sort(GiftList1)].


%% 计算铜钱和元宝和物品
count_gold_list([], TCoin, TBGold, TGoodsList)->
    [TCoin, TBGold, length(TGoodsList), TGoodsList];
count_gold_list([{Type, GoodId, Num}|T], TCoin, TBGold, TGoodsList)->
    case Type of
        1 ->
            NewTGoodsList = [{GoodId, Num}|TGoodsList],
            count_gold_list(T, TCoin, TBGold, NewTGoodsList);
        2 ->
            count_gold_list(T, TCoin+Num, TBGold, TGoodsList);
        3 ->
            count_gold_list(T, TCoin, TBGold+Num, TGoodsList);
        _ ->
            count_gold_list(T, TCoin, TBGold, TGoodsList)
    end.

%% 更新玩家的钱：返回PS
give_online_money(Coin, BGold, PS)->
    if
        Coin > 0 andalso BGold > 0->
            NewPS1 = lib_player:add_money(PS, Coin, bcoin),
            log:log_produce(online_gift_coin, bcoin, PS, NewPS1, "online_gift_coin"),
            NewPS = lib_player:add_money(NewPS1, BGold, bgold),
            log:log_produce(online_gift_bgold, bgold, NewPS1, NewPS, "online_gift_bgold");
        Coin > 0 ->
            NewPS = lib_player:add_money(PS, Coin, bcoin),
            log:log_produce(equip_zhuan_pan_coin, bcoin, PS, NewPS, "online_gift_coin");
        BGold > 0 ->
            NewPS = lib_player:add_money(PS, BGold, bgold),
            log:log_produce(equip_zhuan_pan_bgold, bgold, PS, NewPS, "equip_zhuan_pan_bglod");
        true -> 
            NewPS = PS
    end,
    NewPS.

%% 领取物品后更新在线礼包数据
update_online_gift_info(Record, Count, NowTime, GiftList)->
    RoleId = Record#login_online_gift.role_id,
    OnlineTime = Record#login_online_gift.online_time,
    Time = Record#login_online_gift.time,
    NewOnlineTime = OnlineTime + NowTime - Time,
    SGiftList = util:term_to_string(GiftList),
    UpSQL = io_lib:format(?SQL_ONLINE_UPDATE, [Count, SGiftList, NewOnlineTime, NowTime, RoleId]),
    db:execute(UpSQL),
    NewRecord = Record#login_online_gift{count=Count,gift_list=GiftList,online_time=NewOnlineTime,time=NowTime},
    NewRecord.
    %% put(?LOGIN_ONLINE_KEY(RoleId), NewRecord).


%% 玩家下线时处理在线奖励
offline_do_onlie_award(PS) ->
    Record = PS#player_status.online_award,
    case Record =/= [] of
        true ->
            update_online_gift_info(Record);
        _ ->
        skip
    end.

