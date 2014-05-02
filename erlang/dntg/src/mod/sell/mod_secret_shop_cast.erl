%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-5-22
%% Description: TODO:
%% --------------------------------------------------------
-module(mod_secret_shop_cast).
-export([handle_cast/2]).
-include("shop.hrl").

%% 数据插入进程字典
handle_cast({add_dict, ShopInfo}, Status) ->
    case is_record(ShopInfo, ets_secret_shop) of
        true ->
            Key = ShopInfo#ets_secret_shop.role_id,
            Dict1 = dict:erase(Key, Status#state.dict),
            Dict = dict:append(Key, ShopInfo, Dict1),
            Status1 = Status#state{dict = Dict};
        false ->
            Status1 = Status
    end,
    {noreply, Status1};

handle_cast({'notice', Data}, Status) ->
    Len = length(Status#state.notice),
    if  Len =:= 0 -> 
            Status1 = [];
        Len < 20 -> 
            Status1 = Status#state.notice;
        true -> 
            [_|Status1] = Status#state.notice
    end,
    NewStatus = Status#state{notice = Status1 ++ [Data]},
    {noreply, NewStatus};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_secret_shop:handle_cast not match: ~p", [Event]),
    {noreply, Status}.



