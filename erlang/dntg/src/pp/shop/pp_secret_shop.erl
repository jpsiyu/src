%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-5-21
%% Description: 神秘商店
%% --------------------------------------------------------
-module(pp_secret_shop).
-export([handle/3, refresh_second/1]).
-include("shop.hrl").
-include("common.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("goods.hrl").

%% 商店列表(公共线)
handle(15200, UniteStatus, _) ->
    case mod_secret_shop:get_shop_list(UniteStatus#unite_status.id) of
        [ShopInfo] -> 
            case mod_daily_dict:get_count(UniteStatus#unite_status.id, 8002) of
                0 ->
                    mod_daily_dict:set_count(UniteStatus#unite_status.id, 8002, util:unixtime());
                _ -> 
                    skip
            end,
            {Time1, _R} = refresh_second(mod_daily_dict:get_count(UniteStatus#unite_status.id, 8002)),
            case Time1 > 0 of
                true -> 
                    Time = Time1;
                %% 已过自动刷新时间，通知客户端刷新
                false -> 
                    mod_daily_dict:set_count(UniteStatus#unite_status.id, 8002, util:unixtime()),
                    %Time = ?THREE_HOUR
                    Time = 5
            end,
            %io:format("Time:~p~n", [Time]),
            case ShopInfo#ets_secret_shop.goods_list =/= [] of
                true ->
%%                    case R =:= yes of
%%                        true ->
%%                            %% 重新刷新
%%                            mod_daily_dict:set_count(UniteStatus#unite_status.id, 8002, util:unixtime()),
%%                            NewShopInfo = lib_secret_shop:auto_refresh_shop(ShopInfo, UniteStatus);
%%                        false ->
%%                            NewShopInfo = ShopInfo
%%                    end,
                    NewShopInfo = ShopInfo,
                    FreeTime = 3 - mod_daily_dict:get_count(UniteStatus#unite_status.id, 8001),
                    case FreeTime > 0 of
                       true ->
                           FreeTime1 = FreeTime;
                       false -> 
                           FreeTime1 = 0
                   end,
                    {ok, BinData} = pt_152:write(15200, [NewShopInfo#ets_secret_shop.num, NewShopInfo#ets_secret_shop.goods_list, Time, FreeTime1]);
                false ->
                    {ok, ShopInfo1} = lib_secret_shop:init_secret_shop(UniteStatus#unite_status.id, UniteStatus#unite_status.lv),
                    FreeTime = 3 - mod_daily_dict:get_count(UniteStatus#unite_status.id, 8001),
                    case FreeTime > 0 of
                        true ->
                            FreeTime1 = FreeTime;
                        false -> 
                            FreeTime1 = 0
                    end,
                    {ok, BinData} = pt_152:write(15200, [ShopInfo1#ets_secret_shop.num, ShopInfo1#ets_secret_shop.goods_list, Time, FreeTime1])
            end;
        [] -> 
            {ok, ShopInfo} = lib_secret_shop:init_secret_shop(UniteStatus#unite_status.id, UniteStatus#unite_status.lv),
            {Time1, _} = refresh_second(mod_daily_dict:get_count(UniteStatus#unite_status.id, 8002)),
            case Time1 > 0 of
                true -> 
                    Time = Time1;
                false -> 
                    mod_daily_dict:set_count(UniteStatus#unite_status.id, 8002, util:unixtime()),
                    Time =?THREE_HOUR
            end,
            FreeTime = 3 - mod_daily_dict:get_count(UniteStatus#unite_status.id, 8001),
            case FreeTime > 0 of
                true ->
                    FreeTime1 = FreeTime;
                false -> 
                    FreeTime1 = 0
            end,
            {ok, BinData} = pt_152:write(15200, [ShopInfo#ets_secret_shop.num, ShopInfo#ets_secret_shop.goods_list, Time, FreeTime1])
    end,
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 刷新列表(游戏线)
handle(15201, PlayerStatus, [Type, GoodsId, Num]) ->
    %io:format("Type:~p~n", [Type]),
    Go = PlayerStatus#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'refresh_secret', PlayerStatus, Type, GoodsId, Num}) of
        {ok, [NewPlayerStatus, Res, ShopInfo]} ->
            {RefreshTime,_} = refresh_second(mod_daily_dict:get_count(PlayerStatus#player_status.id, 8002)),
            FreeTime = 3 - mod_daily_dict:get_count(PlayerStatus#player_status.id, 8001),
            case FreeTime > 0 of
                true ->
                    FreeTime1 = FreeTime;
                false -> 
                    FreeTime1 = 0
            end,
            {ok, BinData} = pt_152:write(15201, [Res, ShopInfo#ets_secret_shop.goods_list, Num, FreeTime1, RefreshTime]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            {ok, NewPlayerStatus};
        {'EXIT',_Reason} -> 
            skip
    end;

%% 购买神秘商店物品(游戏线)
handle(15202, PlayerStatus, [GoodsId,Num]) ->
    Go = PlayerStatus#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'pay_secret', PlayerStatus, GoodsId, Num}) of
        {ok, [NewPlayerStatus, Res, Num1, GoodsList]} ->
            {ok, BinData} = pt_152:write(15202, [Res, Num1, GoodsList]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            {ok, NewPlayerStatus};
        {'EXIT',_Reason} -> 
            skip
    end;

%% 神秘商店公告列表(公共线)
handle(15203, UniteStatus, _) ->
    NoticeList =
    case mod_secret_shop:call_notice_list() of
        {badrpc,_Reason} -> 
            [];
        List when is_list(List) -> 
            List;
        _ -> []
    end,
    {ok, BinData} = pt_152:write(15203, NoticeList),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

handle(_Cmd, _Status, _Data) ->
    ?INFO("pp_secret_shop no match", []),
    {error, "pp_secret_shop no match"}.

%% 刷新秒数
refresh_second(ShopInfoTime) ->
    NowTime = util:unixtime(),
    Time = NowTime - ShopInfoTime,
    case Time > ?THREE_HOUR of
        true ->
            Time1 = 0,
%%            Time1 = Time rem ?THREE_HOUR,
            Refresh = yes;
        false ->
            Refresh = no,
            Time1 = ?THREE_HOUR - Time
    end,
    {Time1, Refresh}.
    





