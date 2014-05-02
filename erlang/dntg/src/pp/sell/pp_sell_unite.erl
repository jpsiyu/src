%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-8
%% Description: TODO:
%% --------------------------------------------------------
-module(pp_sell_unite).
-export([handle/3]).
-include("common.hrl").
-include("goods.hrl").
-include("sell.hrl").
-include("unite.hrl").

%%查询别人物品详细信息
handle(18000, Status, GoodsId) ->
    GoodsInfo = get_goods_info(GoodsId),
    %io:format("1800 GoodsInfo = ~p~n", [GoodsInfo]),
    case is_record(GoodsInfo, goods) of
        %% 坐骑
        true when GoodsInfo#goods.type =:= 31 andalso GoodsInfo#goods.subtype =:= 10 ->
            {ok, BinData} = pt_150:write_goods_info(18000, [GoodsInfo, 0, [], 180]);
        true ->
            AttributeList = data_goods:get_goods_attribute(GoodsInfo),
            {ok, BinData} = pt_150:write_goods_info(18000, [GoodsInfo, 0, AttributeList, 180]);
        false ->
            {ok, BinData} = pt_150:write_goods_info(18000, [#goods{}, 0, [], 180])
    end,
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 挂售列表
handle(18020, Status, [Class1, Class2, Page, Lv, Color, Career, Str]) ->
    %io:format("18020:~p~n", [[Class1, Class2, Page, Lv, Color, Career, Str]]),
    NewPage = case Page =< 0 of 
                  true -> 1; 
                  false -> Page 
              end,
    [TotalPage, SellList] = mod_sell:call_sell_list(Class1, Class2, NewPage, Lv, Color, Career, Str),
    {ok, BinData} = pt_180:write(18020, [Class1, Class2, NewPage, TotalPage, SellList]),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 自身挂售列表
handle(18021, Status, _) ->
    %io:format("18021:~p~n", [self_list]),
    SellList = lib_sell:self_list(Status#unite_status.id),
    {ok, BinData} = pt_180:write(18021, SellList),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 求购列表
handle(18050, Status, [Class1, Class2, Page, Lv, Color, Career, Str]) ->
    %io:format("18050:~p~n",[[Class1, Class2, Page, Lv, Color, Career, Str]]),
    NewPage = case Page =< 0 of 
                  true -> 1; 
                  false -> Page 
              end,
    [TotalPage, WtbList] = mod_buy:call_sell_list(Class1, Class2, NewPage, Lv, Color, Career, Str),
    {ok, BinData} = pt_180:write(18050, [Class1, Class2, NewPage, TotalPage, WtbList]),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 自身求购列表
handle(18051, Status, _) ->
    WtbList = lib_buy:self_list(Status#unite_status.id),
    {ok, BinData} = pt_180:write(18051, WtbList),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

handle(_Cmd, _Status, _Data) ->
    ?INFO("pp_sell_unite no match: ~p", [[_Cmd,_Data]]),
    {error, pp_sell_unite_no_match}.


get_goods_info(GoodsId) ->
    case lib_goods_util:get_ets_info(?ETS_SELL_GOODS, GoodsId) of
        [] ->
            case lib_goods_util:get_goods_by_id(GoodsId) of
                [] -> [];
                GoodsInfo ->
                    ets:insert(?ETS_SELL_GOODS, GoodsInfo),
                    GoodsInfo
            end;
        GoodsInfo -> 
            GoodsInfo
    end.





