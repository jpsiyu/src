%%%------------------------------------
%%% @Module  : mod_shake_money
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.21
%%% @Description: 摇钱树
%%%------------------------------------

-module(mod_shake_money).
-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).
-record(log_shake_money, {role_id, name, total_coin, time}).
-define(MONEY_RANK_KEY, "money_rank_info").

%% 查询
get_info() -> 
	gen_server:call(misc:get_global_pid(?MODULE), {get_info}).

%% 查询
get_rank_info() -> 
    gen_server:call(misc:get_global_pid(?MODULE), {get_rank_info}).

%% 插入
insert_info(Str, Coin, Mutil) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {insert_info, Str, Coin, Mutil}).

%% 排行榜插入
money_rank_add(RoleId, Name, Coin) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {money_rank_add, RoleId, Name, Coin}).

start_link() ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    {ok, 0}.

%% handle_call信息处理
handle_call({get_info}, _From, Status) ->
    List = get(),
    Reply = lists:sublist(lists:reverse(lists:keysort(1, deal_list(List, []))), 10),
    {reply, Reply, Status};

%% handle_call信息处理
handle_call({get_rank_info}, _From, Status) ->
    List = look_rank_info(),
    {reply, List, Status};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("shake_money:handle_call not match: ~p~n", [Event]),
    {reply, ok, Status}.

%% handle_cast信息处理
handle_cast({insert_info, Str, Coin, Mutil}, Status) ->
    put({shake_info, util:longunixtime()}, {Str, Coin, Mutil}),
    {noreply, Status};


%% handle_cast, 玩家add钱数
handle_cast({money_rank_add, RoleId, Name, Coin}, Status) ->
    money_rank_insert(RoleId, Name, Coin),
    {noreply, Status};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("shake_money:handle_cast not match: ~p~n", [Event]),
    {noreply, Status}.

%% handle_info信息处理
%% 默认匹配
handle_info(Info, Status) ->
    catch util:errlog("shake_money:handle_info not match: ~p~n", [Info]),
    {noreply, Status}.

terminate(_Reason, _Status) ->
    %catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

deal_list([], L) -> L;
deal_list([H | T], L) -> 
    case H of
        {{shake_info, _Time}, {Str, Coin, Mutil}} ->
            deal_list(T, [{_Time, Str, Coin, Mutil} | L]);
        _ -> 
            deal_list(T, L)
    end.

%% 摇钱榜添加
money_rank_insert(RoleId, Name, Coin)->
    List = get(?MONEY_RANK_KEY),
    %% io:format("~p ~p List:~p~n", [?MODULE,?LINE,List]),
    case List of
        undefined ->
            NewList = [#log_shake_money{role_id = RoleId, name =Name, total_coin = Coin, time = util:unixtime()}],
            put(?MONEY_RANK_KEY, NewList);
        List ->
            case lists:keyfind(RoleId, 2, List) of
                false ->
                    NewList = [#log_shake_money{role_id = RoleId, name =Name, total_coin = Coin, time = util:unixtime()}] ++ List,
                    put(?MONEY_RANK_KEY, NewList);
                Record ->
                    TotalCoin = Record#log_shake_money.total_coin + Coin,
                    NewRecord =  Record#log_shake_money{total_coin = TotalCoin, time = util:unixtime()},
                    NewList = lists:keyreplace(RoleId, 2, List, NewRecord),
                    put(?MONEY_RANK_KEY, NewList)
            end
    end.


look_rank_info()->
    List = get(?MONEY_RANK_KEY),
    %% io:format("~p ~p List:~p~n", [?MODULE,?LINE,List]),
    case List of
        undefined ->
            [];
        List ->
            [One|_T] = List,
            case util:diff_day(One#log_shake_money.time) > 0 of
                true ->
                    erase(?MONEY_RANK_KEY),
                    [];
                false ->
                    SortList = lists:sort(fun(A, B)->
                                                  if
                                                      A#log_shake_money.total_coin > B#log_shake_money.total_coin ->
                                                          true;
                                                      A#log_shake_money.total_coin =:= B#log_shake_money.total_coin ->
                                                          if
                                                              A#log_shake_money.time < B#log_shake_money.time -> true;
                                                              true -> false
                                                          end;
                                                      true ->
                                                          false
                                                  end
                                          end, List),
                    List1 = lists:sublist(SortList, 1, 5),
                    %% io:format("~p ~p List1:~p~n", [?MODULE,?LINE,List1]),
                    lists:map(fun(M) ->
                                      RoleId = M#log_shake_money.role_id,
                                      BName = pt:write_string(M#log_shake_money.name),
                                      Coin = M#log_shake_money.total_coin,
                                      <<RoleId:32, BName/binary, Coin:32>>
                              end, List1)
            end
    end.







