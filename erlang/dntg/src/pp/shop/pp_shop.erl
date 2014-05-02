%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-27
%% Description: 商城物品(公共线)
%% --------------------------------------------------------
-module(pp_shop).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("shop.hrl").
-include("unite.hrl").

%% 取商店物品列表
%% ShopType:商店NPC编号，1为商城
%% ShopSubtype:商店子类型，全部则为0
handle(15300, UniteStatus, [ShopType, ShopSubtype]) ->
    ShopList = lib_shop:get_shop_list(ShopType, ShopSubtype),
    {ok, BinData} = pt_153:write(15300, [ShopType, ShopSubtype, ShopList]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 取兑换商店物品列表
handle(15301, UniteStatus, NpcId) ->
    %% 兑换列表
    ExchangeList = [data_exchange:get(Id) || Id <- data_exchange:get_by_npc(NpcId)],
    case ExchangeList of
        [] -> 
            %% 剩余次数
            RemainNum = 0;
        [Info|_] ->
            case Info#ets_goods_exchange.limit_num > 0 andalso Info#ets_goods_exchange.limit_id > 0 of
                true -> 
                    RemainNum = Info#ets_goods_exchange.limit_num - mod_daily:get_count(UniteStatus#unite_status.dailypid, UniteStatus#unite_status.id, Info#ets_goods_exchange.limit_id);
                false -> 
                    RemainNum = 0
            end
    end,
    {ok, BinData} = pt_153:write(15301, [NpcId, RemainNum, ExchangeList]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 热买商品列表
handle(15305, UniteStatus, _) ->
    NowTime = util:unixtime(),
    ShopList = lib_shop:get_limit_list(UniteStatus#unite_status.id),
    {ok, BinData} = pt_153:write(15305, [ShopList, NowTime]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%%购买物品(游戏线)
%% PayMoneyType: 1元宝, 2绑定元宝
handle(15310, PlayerStatus, [GoodsTypeId, GoodsNum, ShopType, ShopSubtype, PayMoneyType]) ->
    case lib_secondary_password:is_pass(PlayerStatus)  of
        false ->
            skip;
        true ->
            Go = PlayerStatus#player_status.goods,
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'pay', PlayerStatus, GoodsTypeId, GoodsNum, ShopType, ShopSubtype, PayMoneyType}) of
                {ok, [NewPlayerStatus, Res, GoodsList]} ->
                    {ok, BinData} = pt_153:write(15310, [Res, GoodsTypeId, GoodsNum, ShopType, NewPlayerStatus#player_status.bcoin, 
                            NewPlayerStatus#player_status.coin, NewPlayerStatus#player_status.bgold, 
                            NewPlayerStatus#player_status.gold, NewPlayerStatus#player_status.point, GoodsList]),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),    
                    case Res =:= 1 of
                        true ->
                            lib_task:event(NewPlayerStatus#player_status.tid, buy_equip, {GoodsTypeId}, NewPlayerStatus#player_status.id);
                        false -> 
                            skip
                    end,
                    {ok, NewPlayerStatus};
                {'EXIT',_Reason} -> 
                    skip
            end
    end;
    
%%出售物品(游戏线)
handle(15311, PlayerStatus, [ShopType, GoodsList]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            Go = PlayerStatus#player_status.goods,
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'sell', PlayerStatus, ShopType, GoodsList}) of
                {ok, [NewPlayerStatus, Res]} ->
                    {ok, BinData} = pt_153:write(15311, Res),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
                    {ok, NewPlayerStatus};
                {'EXIT',_Reason} -> skip
            end
    end;

%% 获取连续登录商店(游戏线)
handle(15312, PlayerStatus, _) ->
    {ShopType, ShopSubtype, GoodsList} = lib_shop:query_continuous_login_shop_goods_list(PlayerStatus),
    {ok, BinData} = pt_153:write(15312, [ShopType, ShopSubtype, GoodsList]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%% 购买热卖商品(游戏线)
handle(15315, PlayerStatus, [Pos, GoodsId, GoodsNum]) ->
    case lib_secondary_password:is_pass(PlayerStatus)  of
        false ->
            skip;
        true ->
            Go = PlayerStatus#player_status.goods,
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'pay_limit', PlayerStatus, Pos, GoodsId, GoodsNum}) of
                {ok, [NewPlayerStatus, Res, GoodsTypeId, GoodsList]} ->
                    pp_login_gift:handle(31204, PlayerStatus, no),
                    {ok, BinData} = pt_153:write(15315, [Res, GoodsTypeId, GoodsNum, NewPlayerStatus#player_status.bcoin, 
                                                         NewPlayerStatus#player_status.coin, NewPlayerStatus#player_status.bgold, 
                                                         NewPlayerStatus#player_status.gold, NewPlayerStatus#player_status.point, GoodsList]),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
                    {ok, NewPlayerStatus};
                {'EXIT',_Reason} -> 
                    skip
            end
    end;

handle(_Cmd, _Status, _Data) ->
    ?INFO("pp_shop no match", []),
    {error, "pp_shop no match"}.





