%%%-------------------------------------------------------------------
%%% @Module	: mod_turntable_call
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	:  5 Jul 2012
%%% @Description: 转盘call
%%%-------------------------------------------------------------------
-module(mod_turntable_call).
-export([handle_call/3]).
-include("server.hrl").
-include("turntable.hrl").
-include("common.hrl").
-include("unite.hrl").
-include("goods.hrl").
handle_call({get_free, PlayerID, Lv, Vip}, _From, State) ->
    %% TODO:获得原始概率
    case get(PlayerID) of
	undefined ->
	    case mod_turntable:private_check_time() of
		false ->
		    Reply = {error, 1};
		true ->
		    case Lv < data_turntable:get_require_lv() of
			true ->
			    Reply = {error, 2};
			false ->
			    Reply = data_turntable:get_free_cnt(Vip),
			    [A1, A2, A3, A4, I1, I2, I3, I4] = data_turntable:get_init_ratio(),
			    put(PlayerID, #player_ratio{free_cnt = Reply, coin_cnt = 0, 
							award1 = A1, award2 = A2, award3 = A3, award4 = A4,
							item1 = I1, item2 = I2, item3 = I3, item4 = I4})
		    end
	    end;
	Ratio ->
	    Reply = Ratio#player_ratio.free_cnt
    end,
    {reply, Reply, State};

handle_call({request_play, PS}, _From, State) ->
    case mod_turntable:private_check_span_time(PS#player_status.id) of
	ok ->
	    case get(PS#player_status.id) of
		undefined ->
		    NewState = State,
		    Reply = {error, 3};
		Ratio ->
		    case Ratio#player_ratio.free_cnt =:= 0 of
			false ->
			    %% 免费次数
			    %% io:format("free cnt:~p~n",[Ratio#player_ratio.free_cnt]),
			    put(PS#player_status.id, Ratio#player_ratio{free_cnt = (Ratio#player_ratio.free_cnt - 1)}),
			    Reply = mod_turntable:private_get_award(Ratio, State),
			    NewState = mod_turntable:private_handle_reply(PS, Reply, 0, State);
			%% io:format("free win, coin:~p ratio:~p~n",[NewState, Ratio]);
			true ->
			    case lib_goods_util:is_enough_money(PS, 10000, rcoin) of
				false ->
				    Reply = {error, 1},    %%铜币不足
				    NewState = State;
				true ->
				    CellNum = gen_server:call(PS#player_status.goods#status_goods.goods_pid, {'cell_num'}),
				    case CellNum =< 0 of
					true ->
					    Reply = {error, 2},    %%背包已满
					    NewState = State;			
					false ->
					    lib_player:update_player_info(PS#player_status.id, [{cost_turntable_coin, 10000}]),
					    lib_player:refresh_client(PS#player_status.id, 2),
					    Coin = orddict:fetch(acccoin, State),
					    State1 = orddict:store(acccoin, Coin + 5000, State),    %%非免费次数，奖池加5000
					    NewCoinCnt = Ratio#player_ratio.coin_cnt + 1,
					    NewAward1 = Ratio#player_ratio.award1 + (NewCoinCnt * 0.1 * 0.0002),    %%唐僧大奖
					    NewAward2 = Ratio#player_ratio.award2 + (NewCoinCnt * 0.1 * 0.0002),
					    NewAward3 = Ratio#player_ratio.award3 + (NewCoinCnt * 0.1 * 0.0002),
					    NewAward4 = Ratio#player_ratio.award4 - 3 * (NewCoinCnt * 0.1 * 0.0002),    %%勤奋大奖
					    Ratio1 = Ratio#player_ratio{coin_cnt = NewCoinCnt, award1 = NewAward1, award2 = NewAward2, award3 = NewAward3, award4 = NewAward4},
					    put(PS#player_status.id, Ratio1),
					    Reply = mod_turntable:private_get_award(Ratio, State1),
					    NewState = mod_turntable:private_handle_reply(PS, Reply, 1, State1)
					    %% io:format("coin win, coin:~p ratio:~p~n",[State1, Ratio1])
				    end
			    end
		    end
	    end;
	R ->
	    Reply = R,
	    NewState = State
    end,
    {reply, Reply, NewState};

handle_call(get_acccoin, _From, State) ->
    Reply = orddict:fetch(acccoin, State),
    {reply, Reply, State};
handle_call(get_luw, _From, State) ->
    Reply = mod_turntable:private_last_ultimate_winner(State),
    {reply, Reply, State};
handle_call(get_latest, _From, State) ->
    Reply = mod_turntable:private_latest_item(State),
    {reply, Reply, State};
handle_call(get_dict, _From, State) ->
    Reply = State,
    {reply, Reply, State};
handle_call({get_dict, Type}, _From, State) ->
    Reply = get(Type),
    {reply, Reply, State};
%% 默认匹配
handle_call(Event, _From, State) ->
    catch util:errlog("mod_turntable:handle_call not match: ~p", [Event]),
    {reply, ok, State}.
