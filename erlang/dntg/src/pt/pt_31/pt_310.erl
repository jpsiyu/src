%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-22
%% Description: 活动礼包
%% --------------------------------------------------------
-module(pt_310).
-export([read/2, write/2]).
-include("gift.hrl").

%%
%% 客户端 -> 服务 端 ------------------------------------------
%%

%% 取活动礼包列表
read(31000, _R) ->
    {ok, gift_list};

%% 活动礼包领取
%% GiftId: 礼包ID  Name:卡号
read(31002, <<GiftId:32, Bin/binary>>) ->
    {Name, _} = pt:read_string(Bin),
    {ok, [GiftId, Name]};

%% 100服活动 打开面板
read(31020, _) ->
    {ok, gift_data};

%% 100服活动 领取奖励
read(31021, _) ->
    {ok, fetch_award};

%% 默认配对
read(Cmd, _R) ->
    util:errlog("pt_310 read Cmd = ~p error~n", [Cmd]),
    {ok, pt:pack(0, <<>>)}.
    
%%
%% 服务 端-> 客户端  ------------------------------------------
%%
write(31000, GiftList) ->
    ListNum = length(GiftList),
    F = fun(GiftInfo) ->
                Id = GiftInfo#ets_gift2.id,
                Name = GiftInfo#ets_gift2.name,
                NameLen = byte_size(Name),
                Url = GiftInfo#ets_gift2.url,
                UrlLen = byte_size(Url),
                Lv = GiftInfo#ets_gift2.lv,
                Time_start = GiftInfo#ets_gift2.time_start,
                Time_end = GiftInfo#ets_gift2.time_end,
                case GiftInfo#ets_gift2.is_show =:= 1 of
                    true ->
                        Coin = GiftInfo#ets_gift2.coin,
                        Bcoin = GiftInfo#ets_gift2.bcoin,
                        Gold = GiftInfo#ets_gift2.gold,
                        Bgold = GiftInfo#ets_gift2.bgold,
                        Num1 = length(GiftInfo#ets_gift2.goods_list),
                        %% 处理物品列表
                        F1 = fun(Item) ->
                                     case Item of
                                         {goods, Gid, Gnum} ->
                                             <<Gid:32, Gnum:16>>;
                                         {equip, Gid, _, _} ->
                                             <<Gid:32, 1:16>>;
                                         _ ->
                                             <<>>
                                     end
                             end,
                        Bin1 = list_to_binary(lists:map(F1, GiftInfo#ets_gift2.goods_list));
                    false ->
                        Coin = 0,
                        Bcoin = 0,
                        Gold = 0,
                        Bgold = 0,
                        Num1 = 0,
                        Bin1 = <<>>
                end,
                <<Id:32, NameLen:16, Name/binary, UrlLen:16, Url/binary, Lv:16, Coin:32, Bcoin:32, Gold:32, 
                  Bgold:32, Time_start:32, Time_end:32, Num1:16, Bin1/binary>>
        end,
    ListBin = list_to_binary(lists:map(F, GiftList)),
    {ok, pt:pack(31000, <<ListNum:16, ListBin/binary>>)};

%% 活动礼包通知
%% Res:1 活动列表更新
write(31001, Res) ->
    {ok, pt:pack(31001, <<Res:8>>)};

%% 領取活动礼包
%% Res:结果， GiftId:礼包ID
write(31002, [Res, GiftId]) ->
    {ok, pt:pack(31002, <<Res:16, GiftId:32>>)};

%% 100服活动 打开面板
write(31020, [Gold, Recharge, EndTime, GiftId, FetchStatus]) ->
    {ok, pt:pack(31020, <<Gold:32, Recharge:32, EndTime:32, GiftId:32, FetchStatus:8>>)};

%% 100服活动 领取奖励
write(31021, [GiftId, Error]) ->
    {ok, pt:pack(31021, <<GiftId:32, Error:16>>)};

%% 默认配对
write(Cmd, _Bin) ->
    util:errlog("pt_310 write Cmd = ~p error~n", [Cmd]),
    {ok, pt:pack(0, <<>>)}.




