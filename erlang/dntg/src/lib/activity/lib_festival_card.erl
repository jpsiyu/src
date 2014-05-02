%%%--------------------------------------
%%% @Module  : lib_festival_card
%%% @Created : 
%%% @Description: 节日贺卡[圣诞祝福活动]
%%%--------------------------------------

-module(lib_festival_card).
-include("activity.hrl").
-include("gift.hrl").
-include("server.hrl").
-include("mail.hrl").
-compile(export_all).

%% 上线初始化
online(Status) ->
	CardList = private_get_db_cardlist(Status#player_status.id),
	FormatCardList = [private_write_into_festival_card([Id, Is_read, Sender_id, Sender_name, Animation_id, Gift_id, Wish_msg, Send_time])
		||[Id, Is_read, Sender_id, Sender_name, _, Animation_id, Gift_id, Wish_msg, Send_time]<-CardList],
	private_write_to_dict(Status#player_status.id, FormatCardList),
	case data_activity_festival:is_festival_day() of
		true -> 
			spawn(fun() -> timer:sleep(1*30*1000),
					private_notify_has_unread(Status#player_status.id)					
				end
			);
		false -> skip
	end.

%% 加载收到贺卡列表
get_festival_cardlist(Status) ->
	Key = list_to_atom("festival_card_"++integer_to_list(Status#player_status.id)),
	case get(Key) of
		undefined -> 
			CardList = private_get_db_cardlist(Status#player_status.id),
			FormatCardList = [private_write_into_festival_card([Id, Is_read, Sender_id, Sender_name, Animation_id, Gift_id, Wish_msg, Send_time])
				||[Id, Is_read, Sender_id, Sender_name, _, Animation_id, Gift_id, Wish_msg, Send_time]<-CardList],	 
			private_write_to_dict(Status#player_status.id, FormatCardList);
		FormatCardList -> skip
	end,
	FormatCardList.

%% 发送系统贺卡--更新db
system_send_festivial_card_db() ->
	SQL1 = io_lib:format("select id from player_low where 1= ~p order by id asc", [1]),		
	PlayerIdList = db:get_all(SQL1),
	NowTime = util:unixtime(),
	Animation_id = data_activity_festival:sys_festivial_card_id(),
	GiftId = data_activity_festival:sys_festivial_card_gift(),
	Wish_msg = data_activity_festival:sys_festivial_card_wishmsg(), 
	F = fun(ReceiveId) ->			
			SQL2 = io_lib:format("insert into activity_festival_card(sender_id, sender_name, receiver_id, 
				animation_id, gift_id, wish_msg, send_time) values(~p, '~s', ~p, ~p, ~p, '~s', ~p)",
			[0, "系统", ReceiveId, Animation_id, GiftId, Wish_msg, NowTime]),
			db:execute(SQL2)
		end,
	spawn(
		fun() ->
			lists:foldl(
				fun([Id], Counter) ->
					catch F(Id),
						case Counter < 20 of
							true ->
								Counter + 1;
							false ->
								timer:sleep(200),
								1
						end
					end, 1, PlayerIdList)
		end),
	ok.

%% 发送系统贺卡--更新dict
system_send_festivial_card_dict() ->
    Data = ets:tab2list(?ETS_ONLINE),
    [gen_server:cast(D#ets_online.pid, {'sys_send_festivial_card'}) || D <- Data],
    ok.

sys_send_festivial_card(Status) ->
	NowTime = util:unixtime(),
	Sender_id =0, Sender_name ="系统",
	NewestId = lib_festival_card:private_get_dbcardlist_newid(Status#player_status.id),	
	AnimationId = data_activity_festival:sys_festivial_card_id(),
	GiftId = data_activity_festival:sys_festivial_card_gift(),
	WishMsg = data_activity_festival:sys_festivial_card_wishmsg(), 
	Data = #festivial_card{
		id = NewestId,
		is_read = 1,
		sender_id = Sender_id,
		sender_name = Sender_name,
		animation_id = AnimationId,
		gift_id = GiftId,
		wish_msg = WishMsg,
		send_time = NowTime
	},	
	lib_festival_card:private_write_send_to_dict(Status#player_status.id, Data),
	{ok, Bindata} = pt_315:write(31505, [Sender_name]),	
	lib_server_send:send_to_uid(Status#player_status.id, Bindata).	

%% 发送贺卡
send_festivial_card(Status, [ReceiveName, AnimationId, GiftId, WishMsg]) ->
	NowTime = util:unixtime(),
	ReceiveName2 = object_to_list(ReceiveName),
	{ReceiveId, _ReceiveName3} = mod_disperse:call_to_unite(lib_mail, check_name, [ReceiveName2]),
	SNum_Id = 6053,
	SNum = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, SNum_Id),
	case ReceiveId=:=0 of
		true ->
			{2, Status};
		false ->
			case private_animation_gift_isexist(AnimationId, GiftId) of
				true -> 
				case SNum>30 of
					true -> {4, Status};					
					false ->
						case private_get_player_receive_card_num(ReceiveId)>20 of
							true -> {7, Status};
							false ->
								WishMsg2 = util:make_sure_list(WishMsg),
								case private_check_content(WishMsg2) of  %% 检查内容合法性
									true ->			
										CostResult = private_send_festivial_card_cost(Status, AnimationId, GiftId),
										case CostResult of
											error ->
												{6, Status};
											error2 ->
												{0, Status};
											error3 ->
												{8, Status};
											{ok, NewStatus} ->
												Sender_id = NewStatus#player_status.id, Sender_name = NewStatus#player_status.nickname,
   												private_write_send_to_db(Sender_id, Sender_name, ReceiveId, AnimationId, GiftId, WishMsg2),
												NewestId = private_get_dbcardlist_newid(ReceiveId),
												private_write_log_send([NewestId, Sender_id, Sender_name, ReceiveId, AnimationId, GiftId, NowTime]),
												Data = #festivial_card{
													id = NewestId,
													is_read = 1,
													sender_id = Sender_id,
													sender_name = Sender_name,
													animation_id = AnimationId,
													gift_id = GiftId,
													wish_msg = WishMsg2,
													send_time = NowTime
												},
												case ReceiveId =/= Status#player_status.id of
													true ->
														case lib_player:is_online_global(ReceiveId)  of	
															true -> 																										
																lib_player:rpc_cast_by_id(ReceiveId, lib_festival_card, private_write_send_to_dict, [ReceiveId, Data]),
																{ok, Bindata} = pt_315:write(31505, [Sender_name]),	
																lib_server_send:send_to_uid(ReceiveId, Bindata);
															false -> skip
														end;
													false ->
														lib_festival_card:private_write_send_to_dict(ReceiveId, Data),
														{ok, Bindata} = pt_315:write(31505, [Sender_name]),	
														lib_server_send:send_to_uid(ReceiveId, Bindata)
												end,												
												mod_daily:increment(Status#player_status.dailypid, Status#player_status.id, SNum_Id),
												{1, NewStatus}
										end;								
									_Error ->
										{3, Status}
								end
						end							
				end;	
				false -> {5, Status}
			end						
	end.

private_get_player_receive_card_num(Id) ->
	TodayTimeStart = util:unixdate(),
	TodayTimeEnd = TodayTimeStart + 24*3600,	
	SQL = io_lib:format("select count(*) from activity_festival_card where receiver_id=~p and (send_time between ~p and ~p)  and sender_id != 0
		limit 1", [Id, TodayTimeStart, TodayTimeEnd]),	
	Num = db:get_one(SQL),
	case Num of
		null -> 0;
		Num -> Num
	end.

private_send_festivial_card_cost(Status, AnimationId, GiftId) ->
	AnimationCost = data_activity_festival:get_festivial_card_cost(AnimationId),
%%	GiftCost = data_activity_festival:get_festivial_card_gift_cost(GiftId),
	GoodsCost = data_activity_festival:get_festivial_card_gift_cost2(GiftId),
	Cost_goods_id = data_activity_festival:get_festivial_card_constant(cost_goods_id),	
	GoodsNum =lib_goods_info:get_goods_num(Status, Cost_goods_id, 0),
	NCoin = Status#player_status.coin + Status#player_status.bcoin,
	Is_enough_Goods =  GoodsNum>=GoodsCost,
%%	Is_enough_gold = lib_goods_util:is_enough_money(Status, GiftCost, gold),	
	case NCoin>= AnimationCost of
		true ->
			case GiftId =:= 0 of
				true ->
					Flag =0;
				false ->
					GoodNum =lib_goods_info:get_goods_num(Status, GiftId, 0),
					case GoodNum<1 of
						true ->
							case Is_enough_Goods of
								true ->
									Flag = 1;									
								false ->
									Flag = 2
							end;
						false -> 
							Flag = 3
					end
			end,
			case Flag=:=2 of
				true-> error3;					
				false ->
					NewStatus = lib_goods_util:cost_money(Status, AnimationCost, coin),
					log:log_consume(send_festival_card, coin, Status, NewStatus, "send festival card"),
					if 
						Flag=:= 1 ->	
%%							NewStatus2 = lib_goods_util:cost_money(NewStatus, GiftCost, gold),	
%%							log:log_consume(send_festival_card_gift, gold, NewStatus, NewStatus2, ["send festival card gift"]),
%%							Reply = {ok, NewStatus2};
							Go = NewStatus#player_status.goods,								
							NewStatus2 = NewStatus,
							case gen_server:call(Go#status_goods.goods_pid, {'delete_more', Cost_goods_id, GoodsCost}) of
								1 ->
									Reply = {ok, NewStatus};
								_Recv ->
									Reply = error2
							end;
						Flag=:= 3 ->
							Go = NewStatus#player_status.goods,								
							NewStatus2 = NewStatus,
							case gen_server:call(Go#status_goods.goods_pid, {'delete_more', GiftId, 1}) of
								1 ->
									Reply = {ok, NewStatus};
								_Recv ->
									Reply = error2
							end;							
						true -> 
							NewStatus2 = NewStatus,
							Reply = {ok, NewStatus}
					end,
					lib_player:refresh_client(NewStatus2#player_status.id, 2),
					Reply
			end;
		false ->
			error
	end.

private_animation_gift_isexist(AnimationId, GiftId) ->
	GiftList = data_activity_festival:get_festivial_card_gift(),	
	CardList = data_activity_festival:get_festivial_card_id(),
	case lists:member(AnimationId, CardList) andalso  lists:member(GiftId, GiftList) of
		true -> true;
		false -> false
	end.


private_notify_has_unread(Id) ->
	SQL = io_lib:format("select sender_name from activity_festival_card where receiver_id=~p and is_read= 1", [Id]),
	NameList = db:get_all(SQL),
	F = fun(Sender_name) ->
		{ok, Bindata} = pt_315:write(31505, [Sender_name]),	
		lib_server_send:send_to_uid(Id, Bindata)
		end,
	lists:foreach(F, NameList).

%% 阅读贺卡
read_festivial_card(Id, CardId) ->
	SQL = io_lib:format("update activity_festival_card set is_read=0 where id = ~p limit 1", [CardId]),
	db:execute(SQL),
	case private_get_festivial_card_by_id(Id, CardId) of
		false -> {error, 2}; %% 贺卡不存在
		CF ->
			CardInfo = CF#festivial_card{
				is_read = 0
			}, 
			private_update_festivial_card(Id, CardInfo),
			ok
	end.

%% 删除贺卡
delete_festivial_card(Id, CardId) ->
	Key = list_to_atom("festival_card_"++integer_to_list(Id)),
	CardList = get(Key),
	List = lists:keydelete(CardId, 2, CardList),
    put(Key, List),
	SQL = io_lib:format("delete from activity_festival_card where id=~p", [CardId]),
    db:execute(SQL),
	ok.

%% 收取贺卡礼物
recv_festivial_card_gift(Status, CardId) ->
	Go = Status#player_status.goods,
	SQL = io_lib:format("select gift_id from activity_festival_card where id=~p limit 1", [CardId]),
	GiftId = db:get_one(SQL),
	case GiftId=:=0 of
		true -> {error, 2};
		false ->
			GiveList = [{GiftId, 1}],
%%			gen:call(Go#status_goods.goods_pid, '$gen_call', {'give_more', [], GiveList}),
			case gen_server:call(Go#status_goods.goods_pid, {'give_more', [], GiveList}) of
                ok ->					                    
					case private_get_festivial_card_by_id(Status#player_status.id, CardId) of
						false ->
							{error, 5}; %% 贺卡不存在
						CF ->
							CardInfo = CF#festivial_card{
								gift_id=0
						 	}, 
							private_delete_attachment_on_db(CardId),
							private_write_log_fetch_card_gift(CardId, GiftId),
							private_update_festivial_card(Status#player_status.id, CardInfo),							
							{ok,GiftId}
					end;
                {fail, 2} ->        %% 物品不存在
                    {error, 3};
                {fail, 3} ->        %% 背包空间不足
                    {error, 4};
                _Error ->            %% 未知错误
                    {error, 6}
            end	
	end.

private_delete_attachment_on_db(CardId) ->
	SQL = io_lib:format("update activity_festival_card set gift_id=0 where id = ~p limit 1", [CardId]),
	db:execute(SQL).

private_get_festivial_card_by_id(Id, CardId) ->
	Key = list_to_atom("festival_card_"++integer_to_list(Id)),
	CardList = get(Key),
    lists:keyfind(CardId, 2, CardList).

private_update_festivial_card(Id, CardInfo) ->
	Key = list_to_atom("festival_card_"++integer_to_list(Id)),
	CardList = get(Key),
    List = lists:keydelete(CardInfo#festivial_card.id, 2, CardList),
    List1 = List ++ [CardInfo],
    put(Key, List1).

private_write_send_to_db(Sender_id, Sender_name, ReceiveId, AnimationId, GiftId, WishMsg) ->
	NowTime = util:unixtime(),
	SQL = io_lib:format("insert into activity_festival_card(sender_id, sender_name, receiver_id, 
		animation_id, gift_id, wish_msg, send_time) values(~p, '~s', ~p, ~p, ~p, '~s', ~p)",
		[Sender_id, Sender_name, ReceiveId, AnimationId, GiftId, WishMsg, NowTime]),
	db:execute(SQL).

private_write_log_send(Data) ->
	[CardId, Sender_id, Sender_name, ReceiveId, AnimationId, GiftId, SendTime] = Data,
	CostCoin = data_activity_festival:get_festivial_card_cost(AnimationId),
	CostGoods = data_activity_festival:get_festivial_card_gift_cost2(GiftId),
	SQL = io_lib:format("insert into log_festival_card(card_id, sender_id, sender_name, receiver_id, 
				animation_id, gift_id, cost_coin, cost_goods, send_time) values(~p, ~p, '~s', ~p, ~p, ~p, ~p, ~p, ~p)",
		[CardId, Sender_id, Sender_name, ReceiveId, AnimationId, GiftId, CostCoin, CostGoods, SendTime]),
	db:execute(SQL).

private_write_log_fetch_card_gift(CardId, _GiftId) ->
	NowTime = util:unixtime(),
	SQL = io_lib:format("update log_festival_card set status=~p, fetch_time=~p where card_id=~p ",[1, NowTime, CardId]),			
	db:execute(SQL).

private_write_send_to_dict(Id, Data) ->	
	Key = list_to_atom("festival_card_"++integer_to_list(Id)),
	case get(Key) of
		undefined ->
			put(Key, [Data]);	
		CardList ->
			CardList2 = CardList ++ [Data],
			put(Key, CardList2)
	end.
   
private_get_dbcardlist_newid(Id) ->
	SQL = io_lib:format("select id from activity_festival_card where receiver_id=~p order by id desc limit 1", [Id]),
	QueredId = db:get_one(SQL),
	case QueredId of
		null -> QueredId2 =0;
		_Other -> QueredId2 = QueredId
	end,
	QueredId2.

%% 从db中加载Id玩家贺卡列表
private_get_db_cardlist(Id) ->
	SQL = io_lib:format("select * from activity_festival_card where receiver_id=~p order by send_time desc", [Id]),
    db:get_all(SQL).

private_write_to_dict(Id, FormatCardList) ->
	Key = list_to_atom("festival_card_"++integer_to_list(Id)),
	put(Key, FormatCardList).

private_write_into_festival_card([Id, Is_read, Sender_id,
		Sender_name, Animation_id, Gift_id, Wish_msg, Wish_time]) ->
	#festivial_card{
		id = Id,
		is_read = Is_read,
		sender_id = Sender_id,
		sender_name = Sender_name,
		animation_id = Animation_id,
		gift_id = Gift_id,
		wish_msg = Wish_msg,
		send_time = Wish_time
	}.
	

%% 转换为list
object_to_list(Object) when is_binary(Object) ->
    binary_to_list(Object);
object_to_list(Object) when is_list(Object) ->
    Object;
object_to_list(_) ->
    [].

%% 检查内容（数据库字符集UTF-8，为varchar(200)，限制100汉字）
private_check_content(Content) ->
    case util:check_length(Content, 200) of
        true ->
			case lib_mail:check_keyword(Content, ?ESC_CHARS) of
                false ->
                    true;
                true ->
                    {error, ?CONTENT_SENSITIVE}
            end;
        false ->
            {error, ?WRONG_CONTENT}       %% 内容长度非法
    end.
