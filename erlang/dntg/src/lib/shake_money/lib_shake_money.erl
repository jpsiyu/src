%%%------------------------------------
%%% @Module  : lib_shake_money
%%% @Author  : HHL
%%% @Created : 2014.3.18
%%% @Description: 摇钱树
%%%------------------------------------

-module(lib_shake_money).

%% ====================================================================
%% API functions
%% ====================================================================
-export([%% online/2,
         get_coin_num/2,
         get_coin_num_vip_add/2,
         get_coin_ka_list/5,
         %% get_shake_money_info/1,
         send_coin_ka/6,
         send_coin_ka_auto/3,
         get_coin_ka_tuple/2,
         money_list_format/2
         ]).
-define(SHAKE_MONEY(Id), lists:concat(["shake_money_", Id])).
-include("server.hrl").



%% ====================================================================
%% Internal functions
%% ====================================================================
%% online(RoleId, DailyPid)->
%%     %%　现在摇钱的次数
%%     NowShakeCount = mod_daily:get_count(DailyPid, RoleId, 8889),
%% 
%%     %% 摇钱6, 12, 18, 24次的是否已领取铜钱卡
%%     IsGet6  = mod_daily:get_count(DailyPid, RoleId, 8885),
%%     IsGet12 = mod_daily:get_count(DailyPid, RoleId, 8886),
%%     IsGet18 = mod_daily:get_count(DailyPid, RoleId, 8887),
%%     IsGet24 = mod_daily:get_count(DailyPid, RoleId, 8888),
%%     %% 根据领取铜钱卡的次数获取铜钱卡的id
%%     %%　CoinKaId = data_money_config:get_coin_ka_id(NowGetCoinKaCount + 1),
%%     io:format("~p ~p Args:~p~n", [?MODULE, ?LINE, [RoleId, IsGet6, IsGet12, IsGet18, IsGet24]]),
%%     ResultList = get_coin_ka_list(NowShakeCount, IsGet6, IsGet12, IsGet18, IsGet24),
%%     io:format("~p ~p ResultList:~p~n", [?MODULE,?LINE,ResultList]),
%%     put(?SHAKE_MONEY(RoleId), ResultList),
%%     ResultList.


%% get_shake_money_info(PS)->
%%     RoleId = PS#player_status.id,
%%     DailyPid = PS#player_status.dailypid, 
%%     case get(?SHAKE_MONEY(RoleId)) of
%%         undefined ->
%%             online(RoleId, DailyPid);
%%         List ->
%%             List
%%     end.

money_list_format(RoleId, DailyPid)->
    %%　现在摇钱的次数
    NowShakeCount = mod_daily:get_count(DailyPid, RoleId, 8889),

    %% 摇钱6, 12, 18, 24次的是否已领取铜钱卡
    IsGet6  = mod_daily:get_count(DailyPid, RoleId, 8885),
    IsGet12 = mod_daily:get_count(DailyPid, RoleId, 8886),
    IsGet18 = mod_daily:get_count(DailyPid, RoleId, 8887),
    IsGet24 = mod_daily:get_count(DailyPid, RoleId, 8888),
    %% 根据领取铜钱卡的次数获取铜钱卡的id
    %% io:format("~p ~p Args:~p~n", [?MODULE, ?LINE, [RoleId, IsGet6, IsGet12, IsGet18, IsGet24]]),
    ResultList = get_coin_ka_list(NowShakeCount, IsGet6, IsGet12, IsGet18, IsGet24),
    %% io:format("~p ~p ResultList:~p~n", [?MODULE,?LINE,ResultList]),
    %% put(?SHAKE_MONEY(RoleId), ResultList),
    ResultList.

%% 领取和发送铜钱卡
send_coin_ka(PS, ResultList, Type, GoodsId, ShakeCount, GoodsNum)->
    mod_daily:increment(PS#player_status.dailypid, PS#player_status.id, Type),
    GoodsPid = PS#player_status.goods#status_goods.goods_pid,
    CellNum = gen_server:call(GoodsPid, {'cell_num'}),
    case CellNum =< 0 of
        true ->
            Title = data_shake_money_text:get_shake_money_text(3),
            Content = io_lib:format(data_shake_money_text:get_shake_money_text(5), [ShakeCount, GoodsNum]),
            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, 
                                       [[PS#player_status.id], Title, Content, GoodsId, 2, 0, 0, GoodsNum, 0, 0, 0, 0]),
            {ok, BinData} = pt_110:write(63106, [1, GoodsId, GoodsNum, 0]),
            lib_unite_send:send_one(PS#player_status.socket, BinData);
        false ->
            gen_server:call(GoodsPid, {'give_more_bind', [], [{GoodsId, GoodsNum}]}),
            {ok, BinData} = pt_110:write(63106, [1, GoodsId, GoodsNum, 1]),
            lib_unite_send:send_one(PS#player_status.socket, BinData)
    end,
    NewTuple = {Type, GoodsId, 2, ShakeCount, GoodsNum},
    lists:keyreplace(Type, 1, ResultList, NewTuple).
    %% NewResultList.
    %% erase(?SHAKE_MONEY(PS#player_status.id)),
    %% put(?SHAKE_MONEY(PS#player_status.id), NewResultList).

send_coin_ka_auto(PS, ResultList, AutoType)->
    %% List = 
    case AutoType of
        auto_mail ->
            Title = data_shake_money_text:get_shake_money_text(3),
            Fun = fun({Type, GoodsId, IsGet, ShakeCount, GoodsNum}) ->
                          if
                              IsGet =/= 2 ->
                                  mod_daily:increment(PS#player_status.dailypid, PS#player_status.id, Type),
                                  Content = io_lib:format(data_shake_money_text:get_shake_money_text(4), [ShakeCount, GoodsNum]),
                                  mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PS#player_status.id], 
                                                             Title, Content, GoodsId, 2, 0, 0, GoodsNum, 0, 0, 0, 0]),
                                  {Type, GoodsId, 2, ShakeCount, GoodsNum};
                              true ->
                                  {Type, GoodsId, 2, ShakeCount, GoodsNum}
                          end
                  end,
            lists:map(Fun, ResultList);
        auto_bag ->
            GoodsPid = PS#player_status.goods#status_goods.goods_pid,
            Fun = fun({Type, GoodsId, IsGet, ShakeCount, GoodsNum}) ->
                          if
                              IsGet =/= 2 ->
                                  mod_daily:increment(PS#player_status.dailypid, PS#player_status.id, Type),
                                  GoodsPid = PS#player_status.goods#status_goods.goods_pid,
                                  CellNum = gen_server:call(GoodsPid, {'cell_num'}),
                                  case CellNum =< 0 of
                                      true ->
                                          Title = data_shake_money_text:get_shake_money_text(3),
                                          Content = io_lib:format(data_shake_money_text:get_shake_money_text(5), [ShakeCount, GoodsNum]),
                                          mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PS#player_status.id], 
                                                                     Title, Content, GoodsId, 2, 0, 0, GoodsNum, 0, 0, 0, 0]),
                                          {Type, GoodsId, 2, ShakeCount, GoodsNum};
                                      false ->
                                          gen_server:call(GoodsPid, {'give_more_bind', [], [{GoodsId, GoodsNum}]}),
                                          {Type, GoodsId, 2, ShakeCount, GoodsNum}
                                  end;
                              true ->
                                  {Type, GoodsId, 2, ShakeCount, GoodsNum}
                          end
                  end,
            lists:map(Fun, ResultList)
    end.
    %% erase(?SHAKE_MONEY(PS#player_status.id)),
    %% put(?SHAKE_MONEY(PS#player_status.id), List).
    



%% 获得铜钱的总数(免费和元宝)
get_coin_num(Lv, BaseCoefficient)->
    LevelCoefficient = data_money_config:get_level_coefficient(Lv),
    TempCoin = BaseCoefficient*(Lv+50)*(Lv+50)*LevelCoefficient,
    round(TempCoin).


%% Vip获得铜钱的加成数
get_coin_num_vip_add(VipType, Coin)->
    AddRate = case VipType of
                    0 -> 0;
                    1 -> 0.05;
                    2 -> 0.1;
                    3 -> 0.15;
                    _ -> 0
              end,
    round(Coin*AddRate).


%% ShakeCount:当前的摇钱次数; GetCount:领取次数;
get_coin_ka_list(ShakeCount, IsGet6, IsGet12, IsGet18, IsGet24) ->
    L = [{8885, 221101, IsGet6, 6, 5}, {8886, 221101, IsGet12, 12, 10}, 
         {8887, 221101, IsGet18, 18, 15}, {8888, 221101, IsGet24, 24, 25}],
    get_coin_ka_tuple(ShakeCount, L).
    

get_coin_ka_tuple(ShakeCount, L) ->
    get_coin_ka_tuple(ShakeCount, L, []).

get_coin_ka_tuple(_ShakeCount, [], TempList) ->
    TempList;
get_coin_ka_tuple(ShakeCount, [{GetType, CoinKaId, IsGet, NeedShake, CoinKanNum}|T], TempList) ->
    if
        IsGet =:= 0 andalso ShakeCount >= NeedShake ->
            Tuple = {GetType, CoinKaId, 1, NeedShake, CoinKanNum};
        IsGet =:= 0 andalso ShakeCount < NeedShake ->
            Tuple = {GetType, CoinKaId, 0, NeedShake, CoinKanNum};
        true -> 
            Tuple = {GetType, CoinKaId, 2, NeedShake, CoinKanNum}
    end,
      
    get_coin_ka_tuple(ShakeCount, T, TempList ++ [Tuple]).



