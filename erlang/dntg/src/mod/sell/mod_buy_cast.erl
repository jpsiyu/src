%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-8
%% Description: 交易市场求购模块cast
%% --------------------------------------------------------
-module(mod_buy_cast).
-export([handle_cast/2]).
-include("sell.hrl").

%% 记录更新
handle_cast({'buy_reload', Id}, Status) ->
    case lib_buy:reload_buy(Id) of
        [] -> ets:delete(?ETS_BUY, Id);
        WtbInfo when is_record(WtbInfo, ets_buy) ->
            ets:insert(?ETS_BUY, WtbInfo);
        _ -> skip
    end,
    {noreply, Status};

%% 过期清理
handle_cast({'buy_clean'}, Status) ->
    lib_buy:buy_clean(),
    {noreply, Status};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_buy_cast:handle_cast not match: ~p", [Event]),
    {noreply, Status}.




