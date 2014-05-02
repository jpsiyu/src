%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-7
%% Description: 交易市场模块cast
%% --------------------------------------------------------
-module(mod_sell_cast).
-include("sell.hrl").
-export([handle_cast/2]).

%% 时效物品清理
handle_cast({'expire', PlayerId, GoodsId}, SellStatus) ->
    Pattern = #ets_sell{ pid = PlayerId, gid = GoodsId, _='_' },
    case ets:match_object(?ETS_SELL, Pattern) of
        [] -> {noreply, SellStatus};
        [SellInfo|_] ->
            lib_sell:sell_down(SellInfo),
            {noreply, SellStatus}
    end;

%% 交易重加载
handle_cast({'refresh'}, SellStatus) ->
    lib_goods_init:init_sell(),
    {noreply, SellStatus};

%% 重加载
handle_cast({'sell_reload', Id}, SellStatus) ->
    lib_sell:reload_sell(Id),
    {noreply, SellStatus};

%% 交易过期清理
handle_cast({'clean'}, SellStatus) ->
    lib_sell:clean_up(),
    {noreply, SellStatus};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_sell:handle_cast not match: ~p", [Event]),
    {noreply, Status}.





