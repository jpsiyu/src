%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-23
%% Description: 物品进程字典
%% --------------------------------------------------------
-module(lib_goods_dict).
-compile(export_all).
-include("goods.hrl").
-include("sell.hrl").
-include("common.hrl").
-include("server.hrl").

%% 进程字典
start_dict() ->
	put(goods_act, []),
	ok.

close_dict() ->
	erase(goods_act),
	ok.

append_dict(Val, Dict) ->
	case get(goods_act) of
		undefined ->
			NewDict = handle_item([[Val]], Dict);
		Val2 ->
			put(goods_act, Val2++[Val]),
            NewDict = Dict
	end,
	NewDict.

handle_dict(Dict) ->
    case erase(goods_act) of
        undefined -> 
            D = Dict;
        Val when is_list(Val) -> 
            D = handle_item([Val], Dict),
            D;
        _ -> 
            D = Dict
    end,
	D.

handle_item([[]], D) ->
    D;
handle_item([Item], D) ->
    [Item1|T] = Item,
    D1 = handle_item1(Item1, D),
    handle_item([T], D1).

handle_item1(Item, D) ->
    case Item of
        {add, goods, GoodsInfo} ->
            D1 = add_dict_goods(GoodsInfo, D);
        {del, goods, GoodsId} ->
            D1 = dict:erase(GoodsId, D);
        {add, sell, SellInfo} ->
            ets:insert(?ETS_SELL, SellInfo),
            D1 = D;
        {del, sell, Id} ->
            ets:delete(?ETS_SELL, Id),
            D1 = D;
        Other ->
            ?DEBUG("handle_dict other:~p", [Other]),
            D1 = D
    end,
    D1.

%% 增加物品
add_dict_goods(GoodsInfo, Dict) ->
    Key = GoodsInfo#goods.id,
    case is_integer(Key) andalso Key > 0 of
        true ->
            case dict:is_key(Key, Dict) of
                true ->
                    %% 更新
                    Dict1 = dict:erase(Key, Dict),
                    Dict2 = dict:append(Key, GoodsInfo, Dict1);
                false ->
                    Dict2 = dict:append(Key, GoodsInfo, Dict)
            end;
        false ->
            Dict2 = Dict
    end,
    Dict2.

%% 取出列表,从dict取
get_list([], L) ->
    L;
get_list([H|T], L) ->
    {_, List} = H,
    L1 = List ++ L,
    get_list(T, L1).
    
%% 获取dict
get_player_dict(PlayerStatus) ->
    Go = PlayerStatus#player_status.goods,
    Dict = case gen:call(Go#status_goods.goods_pid, '$gen_call', {'get_dict'}) of
               {ok, D} ->
                   D;
               {'EXIT', _Reason} ->
                   []
           end,
    Dict.

get_player_dict_by_goods_pid(Pid) ->
    Dict = case gen:call(Pid, '$gen_call', {'get_dict'}) of
               {ok, D} ->
                   D;
               {'EXIT', _Reason} ->
                   []
           end,
    Dict.




