%%%-------------------------------------------------------------------
%%% @Module	: mod_turntable
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 31 May 2012
%%% @Description: 转盘模块
%%%-------------------------------------------------------------------
-module(mod_turntable).

-compile(export_all).
-behaviour(gen_server).
-include("server.hrl").
-include("goods.hrl").
-include("turntable.hrl").
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 


%%%===================================================================
%%% API
%%%===================================================================

%% 登录广播活动开始
login_send(Id) ->
    case private_check_time() of
	true ->
	    {_, EndTS} = data_turntable:get_activity_unixtime(),
	    RemainTime = EndTS - util:unixtime(),
	    {ok, BinData} = pt_620:write(62004, [1, RemainTime]),
	    lib_unite_send:send_to_one(Id, BinData);
	false -> []
    end.
	    
%% 广播活动开始
broadcast_begin() ->
    {_, EndTS} = data_turntable:get_activity_unixtime(),
    RemainTime = EndTS - util:unixtime(),
    {ok, BinData} = pt_620:write(62004, [1, RemainTime]),
    lib_unite_send:send_to_all(BinData).

%% 广播活动结束
broadcast_end() ->
    {ok, BinData} = pt_620:write(62004, [0, 0]),
    lib_unite_send:send_to_all(BinData),
    stop().

ontime_write_db() ->
    case catch get_acccoin() of
	Acccoin when is_number(Acccoin) ->
	    NowTS = util:unixtime(),
	    Q = io_lib:format(<<"insert into turntable_ultimate_prize(`acccoin`, `timestamp`) values(~p,~p)">>,[Acccoin, NowTS]),
	    db:execute(Q),
	    clear_dict();
	Reason ->
	    util:errlog("mod_turntable ontime_write_db error Reason=~p~n",[Reason])
    end.
%%获取免费次数
get_free(ID, Lv, Vip) ->
    gen_server:call(misc:get_global_pid(?SERVER), {get_free, ID, Lv, Vip}).
%%获取累积铜币
get_acccoin() ->
    gen_server:call(misc:get_global_pid(?SERVER), get_acccoin).
%%获取至尊大奖玩家
get_last_ultimate_winner() ->
    gen_server:call(misc:get_global_pid(?SERVER), get_luw).
%%获取最近中奖列表
get_latest_item() ->
    gen_server:call(misc:get_global_pid(?SERVER), get_latest).

get_dict() ->
    gen_server:call(misc:get_global_pid(?SERVER), get_dict).
get_dict(Type) ->
    case Type of
	db_record ->
	    gen_server:call(misc:get_global_pid(?SERVER), {get_dict, Type});
	_ ->
	    []
    end.

clear_dict() ->
    gen_server:cast(misc:get_global_pid(?SERVER), clear_dict).
%%请求摇奖
request_play(PS) ->
    gen_server:call(misc:get_global_pid(?SERVER), {request_play, PS}).
stop() ->
    gen_server:cast(misc:get_global_pid(?SERVER), stop).
start_link() ->
    gen_server:start_link({global, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    process_flag(trap_exit, true),
    %%从数据库中读取上期累积铜币
    Q1 = io_lib:format(<<"select acccoin from turntable_ultimate_prize order by `timestamp` desc limit 1">>,[]),     
    %% ets:new(?ETS_PLAYER_GOODS, [named_table, public, duplicate_bag]),
    %% put(db_record,dict:new()),
    Dict = orddict:new(),
    case db:get_one(Q1) of
	Acccoin when is_number(Acccoin) ->
	    State = orddict:store(acccoin, Acccoin + 300000, Dict);
	_ ->
	    State = orddict:store(acccoin, 300000, Dict)
    end,
    %% State = {NewAcccoin, orddict:new()},
    {ok, State}.

handle_call(Req, From, State) ->
    case catch mod_turntable_call:handle_call(Req, From, State) of
        {reply, Reply, NewState} ->
            {reply, Reply, NewState};
        Reason ->
	    util:errlog("mod_turntable_call error: ~p, Reason=~p~n",[Req, Reason]),
	    {reply, error, State}
    end.

handle_cast(Req , State) ->
    case catch mod_turntable_cast:handle_cast(Req, State) of
        {noreply, NewState} ->
            {noreply, NewState};
	{stop, normal, NewState} ->
	    {stop, normal, NewState};
        Reason ->
            util:errlog("mod_turntable_cast error: ~p, Reason:=~p~n",[Req, Reason]),
            {noreply, State}
    end.

handle_info(Req, State) ->
    mod_turntable_info:handle_info(Req, State).

terminate(Reason, State) ->
    case Reason =:= normal of
	false ->
	    util:errlog("mod_turntable is terminate, Reason is ~p~n", [Reason]);
	true ->
	    []
    end,
    Coin = orddict:fetch(acccoin, State),
    Q = io_lib:format(<<"insert into turntable_ultimate_prize(`acccoin`, `timestamp`) values(~p,~p)">>,[Coin, util:unixtime()]),
    db:execute(Q),
    %% case catch dict:fetch(player_get, get(db_record)) of
    %% 	DBRecord when is_list(DBRecord) ->
    %% 	    [DBRecordHead|DBRecordTail] = DBRecord,
    %% 	    Acc0 = io_lib:format("values(~p,~p,~p,~p,~p)",[DBRecordHead#db_record.player_id,DBRecordHead#db_record.play_type,DBRecordHead#db_record.award,DBRecordHead#db_record.count,DBRecordHead#db_record.time]),
    %% 	    Concat = lists:foldl(fun(#db_record{player_id=PlayerID, play_type=PlayType, award=Award, count=Count, time=Time}, AccIn) ->
    %% 					 lists:concat([AccIn,io_lib:format(",(~p,~p,~p,~p,~p)", [PlayerID, PlayType, Award, Count, Time])])
    %% 				 end, Acc0, DBRecordTail),
    %% 	    Q1 = io_lib:format(<<"insert into log_turntable(`player_id`, `play_type`, `award`, `count`, `time`) ~ts">>,[Concat]),
    %% 	    db:execute(Q1);
    %% 	_ ->
    %% 	    []
    %% end,
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
%% 判断是否为活动时间
private_check_time() ->
    case lists:member(util:get_day_of_week(), data_turntable:get_start_day()) of
    	true ->
    	    NowTS = util:unixtime(),
    	    {BeginTS, EndTS} = data_turntable:get_activity_unixtime(),
    	    %% io:format("BeginTS:~p NowTS:~p EndTS:~p~n",[BeginTS, NowTS, EndTS]),
    	    if 
    		(NowTS < BeginTS) orelse (NowTS > EndTS) ->
    		    false;
    		true ->
    		    true
    	    end;
    	false ->
    	    false
    end.
    
%% 上一位获得至尊大奖
private_last_ultimate_winner(Dict) ->
    %%最后获取至尊大奖的时间戳与活动结束时间戳的时间之差在30分钟内
    case private_filter_ultimate_winner(Dict) of
	[] ->
	    false;
	V ->
	    {_, Winner, NickName, _, Coin, TS} = lists:last(V),
	    {BeginTS, EndTS} = data_turntable:get_activity_unixtime(),
	    case TS of
		TS when is_number(TS) ->
		    case (TS >= BeginTS) andalso (TS =< EndTS) of
			true ->
			    {Winner, NickName, Coin};
			false ->
			    false
		    end;
		_ ->
		    false
	    end
    end.

%% 最近获奖情况
private_latest_item(Dict) ->
    case private_filter_player_goods(Dict) of
	[] ->
	    [];
	Match when length(Match) >= 8 ->
	    {_, List} = lists:split(length(Match) - 8, Match),
	    List;
	Match ->
	    Match
    end.
%%时间间隔检查,防止加速器刷
private_check_span_time(PlayerID) ->
    Now = util:unixtime(),
    Span = io_lib:format("~pspan", [PlayerID]),
    case get(Span) of
	undefined ->
	    put(Span, Now),
	    ok;
	SpanTime ->
	    if
		%% 2次玩的间隔
		Now - SpanTime >= 1 -> 
		    put(Span, Now),
		    ok;
		true ->
		    {error, 3}    %%请求过快
	    end
    end.


%% 转盘结果,返回物品ID和累积铜币
%%@param:Ratio概率
%%@return:[ItemID,Acccoin]:[物品ID,累积铜币]
private_get_award(Ratio, State) ->
    Acccoin = orddict:fetch(acccoin, State),
    case Acccoin < 500000 orelse Ratio#player_ratio.free_cnt =/= 0 of
	true ->
	    %% 不能开出3个大奖
	    Rand = util:rand(1, 10000),
	    case Rand < (Ratio#player_ratio.award1 + Ratio#player_ratio.award2 + Ratio#player_ratio.award3) of
	       true ->
		    [{_, ItemID, _, _, _}] = private_get_goods_list(Ratio, Rand + (Ratio#player_ratio.award1 + Ratio#player_ratio.award2 + Ratio#player_ratio.award3)),
		    [ItemID, Acccoin];
	       false ->
		    [{_, ItemID, _, _, _}] = private_get_goods_list(Ratio, Rand),
		    [ItemID, Acccoin]
	    end;
	false ->
	    Rand = util:rand(1, 10000),
	    [{_, ItemID, _, _, _}] = private_get_goods_list(Ratio, Rand),
	    [ItemID, Acccoin]
    end.
%%根据概率选出中奖物品
private_get_goods_list(Ratio, Rand) ->
    L = private_update_ratio_list(Ratio),
    F = fun(X) ->
		{_,_,_,Begin,End} = X,
		(Rand >= Begin) andalso (Rand < End)
	end,
    lists:filter(F, L).
%%更新中奖概率
private_update_ratio_list(Ratio) ->
    #player_ratio{free_cnt=_, coin_cnt=_, 
		  award1=Ratio1, award2=Ratio2, award3=Ratio3, award4=Ratio4, 
		  item1=Ratio5, item2=Ratio6, item3=Ratio7, item4=Ratio8} = Ratio,
    S1 = 1 , E1 = Ratio1,
    S2 = E1, E2 = E1 + Ratio2,
    S3 = E2, E3 = E2 + Ratio3,
    S4 = E3, E4 = E3 + Ratio4,
    S5 = E4, E5 = E4 + Ratio5,
    S6 = E5, E6 = E5 + Ratio6,
    S7 = E6, E7 = E6 + Ratio7,
    S8 = E7, E8 = E7 + Ratio8,
    [G1, G2, G3, G4, G5, G6, G7, G8] = data_turntable:get_init_goods(),
    [
     {1, G1, Ratio1, S1, E1},
     {2, G2, Ratio2, S2, E2},
     {3, G3, Ratio3, S3, E3},
     {4, G4, Ratio4, S4, E4},
     {5, G5, Ratio5, S5, E5},
     {6, G6, Ratio6, S6, E6},
     {7, G7, Ratio7, S7, E7},
     {8, G8, Ratio8, S8, E8}
    ].
%% 处理中奖结果
%% @param:PlayType:0免费抽奖 1铜币抽奖
private_handle_reply(PS, ReplyList, PlayType, State) ->
    [Reply, _] = ReplyList,
    %% Reply = lists:nth(util:rand(1,5), [888888,777777,666666,555555,Reply1]), %测试用
    WinTime = util:unixtime(),
    PlayerID = PS#player_status.id,
    case Reply of
	888888 ->				%唐僧大奖
	    CoinState = orddict:fetch(acccoin, State),
	    %% %% 后台记录
	    %% case get(PlayerID) of
	    %% 	undefined ->
	    %% 	    [];
	    %% 	PR ->
	    %% 	    spawn(fun()->
	    %% 			  PlayCnt = PR#player_ratio.coin_cnt,
	    %% 			  Coin = CoinState,
	    %% 			  Q = io_lib:format(<<"insert into log_turntable(`id`, `play_cnt`, `coin`) values(~p, ~p, ~p)">>,[PlayerID, PlayCnt, Coin]),
	    %% 			  db:execute(Q)
	    %% 		  end)		    
	    %% end,
	    %% 清空抽奖次数，触发传闻和钱雨效果
	    [A1, A2, A3, A4, I1, I2, I3, I4] = data_turntable:get_init_ratio(),
	    %% put(db_record, dict:append(player_get, #db_record{player_id = PlayerID, play_type = PlayType, award=Reply, count=CoinState, time=WinTime}, get(db_record))),
	    put(PlayerID, #player_ratio{free_cnt = 0, coin_cnt = 0, 
					award1 = A1, award2 = A2, award3 = A3, award4 = A4,
					item1 = I1, item2 = I2, item3 = I3, item4 = I4}),    %%清空抽奖次数
	    %% PS1 = PS#player_status{coin = PS#player_status.coin + CoinState},
    	    %% ets:insert(?ETS_PLAYER_GOODS, #player_goods{id=PlayerID, nickname=PS#player_status.nickname, itemid=Reply, coin=State, timestamp=WinTime}),
	    NewState = orddict:append(?ETS_PLAYER_GOODS, 
				      #player_goods{id=PlayerID, nickname=PS#player_status.nickname, itemid=Reply, coin=CoinState, timestamp=WinTime}, State),
	    private_update(PS, Reply, WinTime, NewState),
	    Q1 = io_lib:format(<<"insert into log_turntable(`player_id`, `play_type`, `award`, `count`, `time`) values(~p,~p,~p,~p,~p)">>,[PlayerID, PlayType, Reply, CoinState, WinTime]),
	    db:execute(Q1),
	    orddict:store(acccoin, 300000, NewState);	
	777777 ->				%尾随大奖
	    [A1, A2, A3, A4, I1, I2, I3, I4] = data_turntable:get_init_ratio(),
	    case get(PlayerID) of
		undefined ->
		    put(PlayerID, #player_ratio{free_cnt = 0, coin_cnt = 0, 
					award1 = A1, award2 = A2, award3 = A3, award4 = A4,
					item1 = I1, item2 = I2, item3 = I3, item4 = I4});    %%清空抽奖次数
		A2Ratio ->
		    %% 清掉尾随大奖的概率，但不清玩家玩的总次数
		    put(PlayerID, A2Ratio#player_ratio{award2 = A2, award4 = A2Ratio#player_ratio.award4 + A2Ratio#player_ratio.award2 - A2})
	    end,
	    CoinState = orddict:fetch(acccoin, State),
	    Coin = util:floor(CoinState * 0.1),
	    %% PS1 = PS#player_status{coin = PS#player_status.coin + Coin},
	    %% ets:insert(?ETS_PLAYER_GOODS, #player_goods{id=PlayerID, nickname=PS#player_status.nickname, itemid=Reply, coin=Coin, timestamp=WinTime}),
	    %% put(db_record, dict:append(player_get, #db_record{player_id = PlayerID, play_type = PlayType, award=Reply, count=Coin, time=WinTime}, get(db_record))),
	    NewState = orddict:append(?ETS_PLAYER_GOODS, 
				      #player_goods{id=PlayerID, nickname=PS#player_status.nickname, itemid=Reply, coin=Coin, timestamp=WinTime}, State),
	    private_update(PS, Reply, WinTime, NewState),
	    Q1 = io_lib:format(<<"insert into log_turntable(`player_id`, `play_type`, `award`, `count`, `time`) values(~p,~p,~p,~p,~p)">>,[PlayerID, PlayType, Reply, Coin, WinTime]),
	    db:execute(Q1),
	    orddict:store(acccoin, CoinState - Coin, NewState);
	666666 ->				%线索大奖
	    [A1, A2, A3, A4, I1, I2, I3, I4] = data_turntable:get_init_ratio(),
	    case get(PlayerID) of
		undefined ->
		    put(PlayerID, #player_ratio{free_cnt = 0, coin_cnt = 0, 
						award1 = A1, award2 = A2, award3 = A3, award4 = A4,
						item1 = I1, item2 = I2, item3 = I3, item4 = I4});    %%清空抽奖次数
		A3Ratio ->
		    %% 清掉线索大奖的概率，但不清玩家玩的总次数
		    put(PlayerID, A3Ratio#player_ratio{award3 = A3, award4 = A3Ratio#player_ratio.award4 + A3Ratio#player_ratio.award3 - A3})
	    end,
	    CoinState = orddict:fetch(acccoin, State),
	    Coin = util:floor(CoinState * 0.05),
	    %% PS1 = PS#player_status{coin = PS#player_status.coin + Coin},
	    %% ets:insert(?ETS_PLAYER_GOODS, #player_goods{id=PlayerID, nickname=PS#player_status.nickname, itemid=Reply, coin=Coin, timestamp=WinTime}),
	    %% put(db_record, dict:append(player_get, #db_record{player_id = PlayerID, play_type = PlayType, award=Reply, count=Coin, time=WinTime}, get(db_record))),
	    NewState = orddict:append(?ETS_PLAYER_GOODS, 
				      #player_goods{id=PlayerID, nickname=PS#player_status.nickname, itemid=Reply, coin=Coin, timestamp=WinTime}, State),
	    private_update(PS, Reply, WinTime, NewState),
	    Q1 = io_lib:format(<<"insert into log_turntable(`player_id`, `play_type`, `award`, `count`, `time`) values(~p,~p,~p,~p,~p)">>,[PlayerID, PlayType, Reply, Coin, WinTime]),
	    db:execute(Q1),
    	    orddict:store(acccoin, CoinState - Coin, NewState);
	555555 ->				%勤奋奖
	    %% PS1 = PS#player_status{bcoin = PS#player_status.bcoin + 2000},
	    %% put(db_record, dict:append(player_get, #db_record{player_id = PlayerID, play_type = PlayType, award=Reply, count=2000, time=WinTime}, get(db_record))),
	    Q1 = io_lib:format(<<"insert into log_turntable(`player_id`, `play_type`, `award`, `count`, `time`) values(~p,~p,~p,~p,~p)">>,[PlayerID, PlayType, Reply, 5000, WinTime]),
	    db:execute(Q1),
	    private_delay_refresh_client(PS, Reply, 0),
	    State;
	Reply ->				%物品
	    %% put(db_record, dict:append(player_get, #db_record{player_id = PlayerID, play_type = PlayType, award=Reply, count=1, time=WinTime}, get(db_record))),
	    Q1 = io_lib:format(<<"insert into log_turntable(`player_id`, `play_type`, `award`, `count`, `time`) values(~p,~p,~p,~p,~p)">>,[PlayerID, PlayType, Reply, 1, WinTime]),
	    db:execute(Q1),
	    spawn(fun() ->
	    		  timer:sleep(2000),
			  GoodsPid = PS#player_status.goods#status_goods.goods_pid,
			  gen:call(GoodsPid, '$gen_call', {'give_more_bind', [], [{Reply, 1}]}),
			  IsPrecious = data_turntable:is_precious(Reply),
			  log:log_goods(turntable, IsPrecious, Reply, 1, PlayerID),
			  case IsPrecious of
			      1 ->
				  {ok, BinData} = pt_620:write(62001, [PlayerID, list_to_binary(PS#player_status.nickname), Reply, 0]),
				  lib_unite_send:send_to_all(BinData),
				  private_send_cw(PS, Reply, State);
				  %% ets:insert(?ETS_PLAYER_GOODS, #player_goods{id=PlayerID, nickname=PS#player_status.nickname, itemid=Reply, coin=0, timestamp=WinTime});				  
			      _ ->
				  []
			  end
		  end),
	    case data_turntable:is_precious(Reply) of
		1 ->
		    orddict:append(?ETS_PLAYER_GOODS, 
				   #player_goods{id=PlayerID, nickname=PS#player_status.nickname, itemid=Reply, coin=0, timestamp=WinTime}, 
				   State);
		_ ->
		    State
	    end
    end.

private_update(PS, ItemID, TS, Dict) ->
    PlayerID = PS#player_status.id,
    %% case ets:match(?ETS_PLAYER_GOODS, #player_goods{id=PlayerID, _='_', coin='$1', timestamp=TS}) of
    case private_filter_wincoin(PlayerID, TS, Dict) of
	Match when length(Match) =:= 1 ->
	    [WinCoin] = Match;
	Match ->
	    WinCoin = lists:last(Match)
    end,
    private_delay_refresh_client(PS, ItemID, WinCoin).

%% 一系列进程字典操作------------------BEGIN
private_filter_player_goods(Dict) ->
    F = fun(K, _V) when K =:= player_goods ->
		true;
	   (_K, _V) ->
		false
	end,
    case orddict:filter(F, Dict) of
	[] ->
	    Filter = [];
	[{_, Filter}] ->
	    Filter
    end,
    Filter.
private_filter_ultimate_winner(Dict) ->    
    Filter = private_filter_player_goods(Dict),
    lists:filter(fun(X) ->
		      case X of
			  {_, _, _, 888888, _, _} ->
			      true;
			  _ ->
			      false
		      end
	      end, Filter).
    
private_filter_wincoin(PlayerID, TimeStamp, Dict) ->
    Filter = private_filter_player_goods(Dict),
    lists:map(fun(X) ->
		      case X of
			  {_, PlayerID, _, _, Coin, TimeStamp} ->
			      Coin;
			  _ ->
			      []
		      end
	      end, Filter).
%% 一系列进程字典操作------------------END

%% 发奖
private_delay_refresh_client(PS, ItemID, WinCoin) ->	    
    spawn(fun() ->
    		  timer:sleep(2000),
		  case ItemID of
		      ItemID when ItemID =/= 555555 ->
			  {ok, BinData} = pt_620:write(62001, [PS#player_status.id, list_to_binary(PS#player_status.nickname), ItemID, WinCoin]),
			  lib_unite_send:send_to_all(BinData),
			  if
			      ItemID =:= 888888 ->
				  {ok, BinUltimate} = pt_620:write(62010, [1, PS#player_status.id, list_to_binary(PS#player_status.nickname), WinCoin]),
				  lib_unite_send:send_to_all(BinUltimate),
				  {ok, Bin} = pt_620:write(62005, []),
				  lib_unite_send:send_to_all(Bin),
				  lib_player:update_player_info(PS#player_status.id, [{add_turntable_coin, WinCoin}]);
			      ItemID =:= 777777 orelse ItemID =:= 666666 ->
				  lib_player:update_player_info(PS#player_status.id, [{add_turntable_coin, WinCoin}]);
			      true ->
				  ItemID
			  end;
		      _ ->
			  lib_player:update_player_info(PS#player_status.id, [{add_turntable_bcoin, 5000}])
		  end,
		  lib_player:refresh_client(PS#player_status.id, 2),
		  private_send_cw(PS, ItemID, WinCoin)
	  end).

%% 传闻
private_send_cw(PS, Award, Coin) ->
    case data_turntable_text:get_cw_message(PS, Award, Coin) of
	Msg when is_list(Msg) ->
	    lib_chat:send_TV({all},1,2, Msg);
	_ ->
	    []
    end.
