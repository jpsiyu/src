%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-9-25
%% Description: 临时背包
%% --------------------------------------------------------
-module(lib_temp_bag).
-compile(export_all).
-include("server.hrl").
-include("goods.hrl").
-include("sql_goods.hrl").
-include("drop.hrl").

%% 取列表
init_temp_list(PlayerId) ->
    Dict = dict:new(),
    Sql = io_lib:format(<<"select id, goods_id, num, prefix, bind, stren, pos from temp_bag where pid = ~p">>, [PlayerId]),
    case db:get_all(Sql) of
        [] -> 
            Dict2 = Dict;
        List when is_list(List) ->
            Dict2 = make_temp_list(List, Dict, PlayerId);
        _ ->
            Dict2 = Dict
    end,
    Dict2.

make_temp_list([], D, _) ->
    D;
make_temp_list([Info|T], Dict, Pid) ->
    case Info of
        [Id, GoodsId, Num, Prefix, Bind, Stren, Pos] ->
            Temp = #temp_bag{
                id = Id,
                pid = Pid,
                goods_id = GoodsId,
                bind = Bind,
                prefix = Prefix,
                stren = Stren,
                num = Num,
                pos = Pos
            },
            Dict2 = lib_mount:add_dict(Id, Temp, Dict),
            make_temp_list(T, Dict2, Pid);
        _ ->
            make_temp_list(T, Dict, Pid)
    end.

% 取列表
get_temp_list(PS) ->
    case PS#player_status.temp_dict =/= [] of
        true ->
            Dict1 = dict:filter(fun(_Key, [Value]) -> Value#temp_bag.pid =:=
                        PS#player_status.id end, PS#player_status.temp_dict),
            DictList = dict:to_list(Dict1),
            lib_goods_dict:get_list(DictList, []);
        false ->
            []
    end.

%% 保存物品
%% PlayerId, GoodsTypeId, Bind:绑定, Prefix:前缀, Stren:强化, Pos:章节
%% 返回NewPS
insert_temp_goods(PS, DropList, Pos) ->
    case is_list(DropList) of
        true ->
            insert_goods(PS, DropList, Pos);
        false ->
            PS
    end.

insert_goods(NewPS, [], _) ->
    NewPS;
insert_goods(PS, [DropInfo|T], Pos) ->
    if is_record(DropInfo, ets_drop_goods) =:= true ->
        Dict1 = dict:filter(fun(_Key, [Value]) -> Value#temp_bag.pid =:= PS#player_status.id andalso Value#temp_bag.goods_id =:= DropInfo#ets_drop_goods.goods_id andalso Value#temp_bag.pos =:= Pos end, PS#player_status.temp_dict),
        DictList = dict:to_list(Dict1),
        List = lib_goods_dict:get_list(DictList, []),
        case List of
            [] ->   %% 新增加
			    F = fun() ->
					Sql = io_lib:format(<<"insert into temp_bag set pid=~p, goods_id=~p, bind=~p, prefix=~p, stren=~p, pos=~p, num=~p">>, [PS#player_status.id, DropInfo#ets_drop_goods.goods_id, DropInfo#ets_drop_goods.bind, DropInfo#ets_drop_goods.prefix, DropInfo#ets_drop_goods.stren, Pos, DropInfo#ets_drop_goods.num]),
            		db:execute(Sql),
            		Id = db:get_one(?SQL_LAST_INSERT_ID),
					{ok, Id}
				end,
			    case lib_goods_util:transaction(F) of
				    {ok, Id} ->
            		    Temp = #temp_bag{
                		id = Id,
                		pid = PS#player_status.id,
                		goods_id = DropInfo#ets_drop_goods.goods_id,
                		bind = DropInfo#ets_drop_goods.bind,
                		prefix = DropInfo#ets_drop_goods.prefix,
                		stren = DropInfo#ets_drop_goods.stren,
                		num = DropInfo#ets_drop_goods.num,
                		pos = Pos
            		    },
            		    Dict = lib_mount:add_dict(Id, Temp, PS#player_status.temp_dict),
            		    NewPS = PS#player_status{temp_dict = Dict};
				    _ ->
					    NewPS = PS
			    end;
            [Tm] ->  %% 叠加
                Sql = io_lib:format(<<"update temp_bag set num = ~p where id = ~p">>, [Tm#temp_bag.num + DropInfo#ets_drop_goods.num, Tm#temp_bag.id]),
                db:execute(Sql),
                NewT = Tm#temp_bag{num = Tm#temp_bag.num + DropInfo#ets_drop_goods.num},
                Dict = lib_mount:add_dict(Tm#temp_bag.id, NewT, PS#player_status.temp_dict),
                NewPS = PS#player_status{temp_dict = Dict}
            end,
            insert_goods(NewPS, T, Pos);
        true ->
            insert_goods(PS, T, Pos)
    end.

%% 取单个
get_one_temp_goods(Id, PS) ->
    case dict:is_key(Id, PS#player_status.temp_dict) of
        true ->
            [Temp] = dict:fetch(Id, PS#player_status.temp_dict),
            %io:format("get_one Temp = ~p~n", [Temp]),
            case data_goods_type:get(Temp#temp_bag.goods_id) of
                [] ->
                    {4, #temp_bag{}};
                _GoodsTypeInfo ->
                    {1, Temp}
            end;
        false ->
            {4, #temp_bag{}}
    end.

%% 取全部
get_all_list(PS) ->
    List = get_temp_list(PS),
    %io:format("get_all_list = ~p~n", [List]),
    make_goods_list(List, []).

make_goods_list([], L) ->
    L;
make_goods_list([Temp|T], L) ->
    if
        is_record(Temp, temp_bag) =:= true ->
            make_goods_list(T, [{goods, Temp#temp_bag.goods_id, Temp#temp_bag.num, Temp#temp_bag.prefix, Temp#temp_bag.stren, Temp#temp_bag.bind}|L]);
        true ->
            make_goods_list(T, L)
    end.

delete_temp_one(PS, Id) ->
    Sql = io_lib:format(<<"delete from temp_bag where id = ~p">>, [Id]),
    db:execute(Sql),
    Dict = dict:erase(Id, PS#player_status.temp_dict),
    PS#player_status{temp_dict = Dict}.

delete_temp_all(PS) ->
    Sql = io_lib:format(<<"delete from temp_bag where pid = ~p">>, [PS#player_status.id]),
    db:execute(Sql),
    Dict = dict:new(),
    PS#player_status{temp_dict = Dict}.

%% 是否可以存放, 
%% true: 可以放
is_can_store(PS, Pos) ->
    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#temp_bag.pid =:=
                        PS#player_status.id andalso Value#temp_bag.pos =:= Pos end, PS#player_status.temp_dict),
    DictList = dict:to_list(Dict1),
    List = lib_goods_dict:get_list(DictList, []),
    case List of
        [] ->
            true;
        _ ->
            false
    end.
    
%% 写日志
write_log(_Pid, []) ->
    ok;
write_log(Pid, [{goods, GoodsTypeId, Num, Prefix, Stren, Bind} | H]) ->
    log:log_temp_bag(Pid, GoodsTypeId, Num, Prefix, Stren, Bind),
    write_log(Pid, H).












