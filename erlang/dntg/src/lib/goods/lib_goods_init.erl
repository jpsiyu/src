%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-13
%% Description: 物品实用工具类
%% --------------------------------------------------------
-module(lib_goods_init).
-compile(export_all).
-include("common.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("sell.hrl").


init_goods_online(PlayerId, GoodsDict) ->
    %% 初始化在线玩家背包物品表
    NewDict = init_goods(PlayerId, GoodsDict),
    NewDict.

init_goods(PlayerId, GoodsDict) ->
    F4 = fun([Id, _GoodsTypeId, _GoodsNum, Location, _Prefix, _Stren, _Type, _Equip_type]) ->
%%            case Type =:= ?GOODS_TYPE_EQUIP andalso Equip_type =:= ?GOODS_EQUIPTYPE_FASHION of
%%                true when Location =/= ?GOODS_LOC_FASHION 
%%                    andalso Location =/= ?GOODS_LOC_BAG
%%                    andalso Location =/= ?GOODS_LOC_STORAGE ->  %% 移入衣橱
%%                    Sql41 = io_lib:format(?SQL_GOODS_UPDATE_CELL, [?GOODS_LOC_FASHION, 0, Id]),
%%                    db:execute(Sql41),
%%                    GoodsTypeInfo = data_goods_type:get(GoodsTypeId),
%%                    Content = lists:concat([data_sell_text:goods_text(1),
%%                                            binary_to_list(GoodsTypeInfo#ets_goods_type.goods_name),
%%                                            data_sell_text:goods_text(2)]),
%%                    mod_disperse:call_to_unite(lib_mail, send_sys_mail, [PlayerId, data_sell_text:goods_text(3), Content, 0, 0, 0, 0]);
%%                true -> skip;
%%                false -> %% 删除物品
%%                    lib_goods_util:delete_goods(Id),
%%                    log:log_throw(2, PlayerId, Id, GoodsTypeId, GoodsNum, Prefix, Stren)
%%            end,
            case Location of
                %% 交易市场
                3 ->
                    lib_goods_util:del_sell_by_goods(Id);
%%                     (catch mod_disperse:cast_to_unite(mod_sell, cast_sell_expire, [PlayerId, Id])); 暂时不知道有没有用
                %% 邮件附件
%%                 7 -> lib_mail:delete_mail_goods_on_db(Id); 后面再加上
                _ -> skip
            end
         end,
    Sql4 = io_lib:format(?SQL_GOODS_LIST_BY_EXPIRE, [PlayerId, util:unixtime()]),
    case db:get_all(Sql4) of
        [] -> skip;
        GoodsList4 when is_list(GoodsList4) ->
            F44 = fun() -> lists:foreach(F4, GoodsList4) end,
            lib_goods_util:transaction(F44);
        _ -> skip
    end,
    
    Sql1 = io_lib:format(?SQL_GOODS_LIST_BY_LOCATION, [PlayerId, ?GOODS_LOC_EQUIP]),
    NewGoodsDict1 = case db:get_all(Sql1) of
                        [] -> 
                            GoodsDict;
                        GoodsList1 when is_list(GoodsList1) ->
                            insert_dict(GoodsList1, GoodsDict);
                        _ -> 
                            GoodsDict
                    end,
    Sql2 = io_lib:format(?SQL_GOODS_LIST_BY_LOCATION, [PlayerId, ?GOODS_LOC_BAG]),
    NewGoodsDict2 = case db:get_all(Sql2) of
                        [] -> 
                            NewGoodsDict1;
                        GoodsList2 when is_list(GoodsList2) ->
                            insert_dict(GoodsList2, NewGoodsDict1);
                        _ -> 
                            NewGoodsDict1
                    end,
    Sql3 = io_lib:format(?SQL_GOODS_LIST_BY_LOCATION, [PlayerId, ?GOODS_LOC_FASHION]),
    NewGoodsDict3 = case db:get_all(Sql3) of
                        [] -> 
                            NewGoodsDict2;
                        GoodsList3 when is_list(GoodsList3) ->
                            insert_dict(GoodsList3, NewGoodsDict2);
                        _ -> 
                            NewGoodsDict2
                    end,
    Sql5 = io_lib:format(?SQL_GOODS_LIST_BY_LOCATION, [PlayerId, ?GOODS_LOC_MOUNT]),
    NewGoodsDict4 = case db:get_all(Sql5) of
                        [] -> 
                            NewGoodsDict3;
                        GoodsList5 when is_list(GoodsList5) ->
                            insert_dict(GoodsList5, NewGoodsDict3);
                        _ -> 
                            NewGoodsDict3
                    end,
    NewGoodsDict4.

insert_dict([], Dict) ->
    Dict;
insert_dict([Info|H], Dict) ->
    case lib_goods_util:make_info(goods, Info) of
            [GoodsInfo] -> 
                NewGoodsDict1 = lib_goods_dict:add_dict_goods(GoodsInfo, Dict);
            _ -> 
                NewGoodsDict1 = Dict
    end,
    insert_dict(H, NewGoodsDict1).

%% 初始化公共线物品
init_unite_goods() ->
    %% 挂售市场
    ok = init_sell(),
    %%挂售市场物品
    ok = init_sell_goods(),
    ok.

%% 初始化挂售市场
init_sell() ->
    ets:delete_all_objects(?ETS_SELL),
    F = fun(Data) ->
            SellInfo = lib_goods_util:make_sell(Data),
            ets:insert(?ETS_SELL, SellInfo)
        end,
    case db:get_all(?SQL_SELL_SELECT) of
        [] -> skip;
        SellList when is_list(SellList) ->
            lists:foreach(F, SellList);
        _ -> skip
    end,
    ok.

%% 初始化挂售市场物品
init_sell_goods() ->
    ets:delete_all_objects(?ETS_SELL_GOODS),
    F = fun(Info) ->
                case lib_goods_util:make_info(goods, Info) of
                    [GoodsInfo] -> ets:insert(?ETS_SELL_GOODS, GoodsInfo);
                    _ -> skip
                end
         end,
    Sql = io_lib:format(?SQL_GOODS_LIST_BY_SELL, [?GOODS_LOC_SELL, ?GOODS_TYPE_EQUIP]),
    case db:get_all(Sql) of
        [] -> skip;
        GoodsList when is_list(GoodsList) ->
            lists:foreach(F, GoodsList);
        _ -> skip
    end,
    ok.

