%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-7
%% Description: 交易信息,市场交易
%% --------------------------------------------------------
-module(pt_180).
-export([read/2, write/2]).
-include("sell.hrl").

%%
%% 客户端 -> 服务端 ----------------------------
%%

%%查询物品详细信息
read(18000, <<GoodsId:32>>) ->
    {ok, GoodsId};

%% 发起交易
read(18010, <<PlayerId:32>>) ->
    {ok, PlayerId};

%% 接受交易
read(18011, <<PlayerId:32>>) ->
    {ok, PlayerId};

%% 添加或删除交易物品
read(18012, <<Action:8, GoodsId:32, GoodsTypeId:32, GoodsNum:16>>) ->
    {ok, [Action, GoodsId, GoodsTypeId, GoodsNum]};

%% 锁定交易
read(18013, _R) ->
    {ok, lock};

%% 确认交易
read(18014, _R) ->
    {ok, confirm};

%% 中断交易
read(18015, _R) ->
    {ok, stop};

%% 修改交易金钱
read(18016, <<Coin:32, Gold:32>>) ->
    {ok, [Coin, Gold]};

%% 挂售列表
read(18020, <<Class1:32, Class2:32, Page:32, Lv:16, Color:8, Career:8, _Len:16, Str/binary>>) ->
    {ok, [Class1, Class2, Page, Lv, Color, Career, Str]};

%% 自身挂售列表
read(18021, _R) ->
    {ok, self_list};

%% 挂售物品
%% Show: 0不发传闻, 1:发传闻
read(18030, <<GoodsId:32, Num:32, PriceType:8, Price:32, Time:8, Show:8>>) ->
    {ok, [GoodsId, Num, PriceType, Price, Time, Show]};

%% 取消挂售
read(18031, <<Id:32>>) ->
    {ok, Id};

%% 购买挂售物品
read(18032, <<Id:32>>) ->
    {ok, Id};

%% 再次挂售
read(18033, <<Id:32, Flag:8>>) ->
    {ok, [Id,Flag]};

%% 求购列表
read(18050, <<Class1:8, Class2:8, Page:32, Lv:16, Color:8, Career:8, _Len:16, Str/binary>>) ->
    {ok, [Class1, Class2, Page, Lv, Color, Career, Str]};

%% 自身求购列表
read(18051, _R) ->
    {ok, self_wtb};

%% 求购物品
read(18052, <<GoodsTypeId:32, Num:32, Prefix:8, Stren:8, PriceType:8, Price:32, Time:8>>) ->
    {ok, [GoodsTypeId, Num, Prefix, Stren, PriceType, Price, Time]};

%% 取消求购
read(18053, <<Id:32>>) ->
    {ok, Id};

%% 出售求购物品
read(18054, <<Id:32, GoodsId:32>>) ->
    {ok, [Id, GoodsId]};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ----------------------------
%%

%% 交易状态通知
write(18001, [PlayerId, Status, PlayerName, Lv, Combat_power, Vip]) ->
    Nick = list_to_binary(PlayerName),
    Len = byte_size(Nick),
    {ok, pt:pack(18001, <<PlayerId:32, Status:16, Len:16, Nick/binary, Lv:8, Combat_power:16, Vip:8>>)};

%% 交易物品通知
write(18002, [PlayerId, GoodsList]) ->
    SellList = lists:keydelete(money, 1, GoodsList),
    ListNum = length(SellList),
    F = fun({GoodsId, GoodsTypeId, GoodsNum}) ->
            <<GoodsId:32, GoodsTypeId:32, GoodsNum:16>>
        end,
    ListBin = list_to_binary(lists:map(F, SellList)),
    {ok, pt:pack(18002, <<PlayerId:32, ListNum:16, ListBin/binary>>)};

%% 交易金钱通知
write(18003, [PlayerId, Coin, Gold]) ->
    {ok, pt:pack(18003, <<PlayerId:32, Coin:32, Gold:32>>)};

%% 发起交易
write(18010, [Res, PlayerId]) ->
    {ok, pt:pack(18010, <<Res:16, PlayerId:32>>)};

%% 发起交易
write(18011, [Res, PlayerId]) ->
    {ok, pt:pack(18011, <<Res:16, PlayerId:32>>)};

%% 添加或删除交易物品
write(18012, [Res, Action, GoodsId, GoodsTypeId, GoodsNum]) ->
    {ok, pt:pack(18012, <<Res:16, Action:8, GoodsId:32, GoodsTypeId:32, GoodsNum:16>>)};

%% 修改交易金钱
write(18016, [Res, Coin, Gold]) ->
    {ok, pt:pack(18016, <<Res:16, Coin:32, Gold:32>>)};

%% 锁定交易
write(18013, Res) ->
    {ok, pt:pack(18013, <<Res:16>>)};

%% 确认交易
write(18014, Res) ->
    {ok, pt:pack(18014, <<Res:16>>)};

%% 中断交易
write(18015, Res) ->
    {ok, pt:pack(18015, <<Res:16>>)};

%% 挂售列表
write(18020, [Class1, Class2, Page, TotalPage, SellList]) ->
    ListNum = length(SellList),
    F = fun(Info) ->
            Id = Info#ets_sell.id,
            GoodsId = Info#ets_sell.gid,
            GoodsTypeId = Info#ets_sell.goods_id,
            GoodsNum = Info#ets_sell.num,
            PriceType = Info#ets_sell.price_type,
            Price = Info#ets_sell.price,
            PlayerId = Info#ets_sell.pid,
            <<Id:32, GoodsId:32, GoodsTypeId:32, GoodsNum:32, PriceType:8, Price:32, PlayerId:32>>
        end,
    ListBin = list_to_binary(lists:map(F, SellList)),
    {ok, pt:pack(18020, <<Class1:8, Class2:8, Page:32, TotalPage:32, ListNum:16, ListBin/binary>>)};

%% 自身挂售列表
write(18021, SellList) ->
    ListNum = length(SellList),
    NowTime = util:unixtime(),
    F = fun(Info) ->
            Id = Info#ets_sell.id,
            GoodsId = Info#ets_sell.gid,
            GoodsTypeId = Info#ets_sell.goods_id,
            GoodsNum = Info#ets_sell.num,
            PriceType = Info#ets_sell.price_type,
            Price = Info#ets_sell.price,
            Is_expire = Info#ets_sell.is_expire,
            Expire_time = case Info#ets_sell.expire_time - NowTime > 0 of
                              true -> Info#ets_sell.expire_time - NowTime;
                              false -> 1
                          end,
            <<Id:32, GoodsId:32, GoodsTypeId:32, GoodsNum:32, PriceType:8, Price:32, Is_expire:8, Expire_time:32>>
        end,
    ListBin = list_to_binary(lists:map(F, SellList)),
    {ok, pt:pack(18021, <<ListNum:16, ListBin/binary>>)};

%% 挂售物品
write(18030, [Res, SellInfo]) ->
    Id = SellInfo#ets_sell.id,
    Class1 = SellInfo#ets_sell.class1,
    Class2 = SellInfo#ets_sell.class2,
    GoodsId = SellInfo#ets_sell.gid,
    GoodsTypeId = SellInfo#ets_sell.goods_id,
    GoodsNum = SellInfo#ets_sell.num,
    PriceType = SellInfo#ets_sell.price_type,
    Price = SellInfo#ets_sell.price,
    {ok, pt:pack(18030, <<Res:16, Class1:8, Class2:8, Id:32, GoodsId:32, GoodsTypeId:32, GoodsNum:32, PriceType:8, Price:32>>)};

%% 取消挂售
write(18031, [Res, Id]) ->
    {ok, pt:pack(18031, <<Res:16, Id:32>>)};

%% 购买挂售物品
write(18032, [Res, Id]) ->
    {ok, pt:pack(18032, <<Res:16, Id:32>>)};

%% 再次挂售
write(18033, [Res, Id, Flag]) ->
    {ok, pt:pack(18033, <<Res:16, Id:32, Flag:8>>)};

%% 求购列表
write(18050, [Class1, Class2, Page, TotalPage, WtbList]) ->
    ListNum = length(WtbList),
    F = fun(Info) ->
            Id = Info#ets_buy.id,
            GoodsTypeId = Info#ets_buy.goods_id,
            GoodsNum = Info#ets_buy.num,
            Prefix = Info#ets_buy.prefix,
            Stren = Info#ets_buy.stren,
            PriceType = Info#ets_buy.price_type,
            Price = Info#ets_buy.price,
            PlayerId = Info#ets_buy.pid,
            <<Id:32, GoodsTypeId:32, GoodsNum:32, Prefix:8, Stren:8, PriceType:8, Price:32, PlayerId:32>>
        end,
    ListBin = list_to_binary(lists:map(F, WtbList)),
    {ok, pt:pack(18050, <<Class1:8, Class2:8, Page:32, TotalPage:32, ListNum:16, ListBin/binary>>)};

%% 自身求购列表
write(18051, WtbList) ->
    ListNum = length(WtbList),
    F = fun(Info) ->
            Id = Info#ets_buy.id,
            GoodsTypeId = Info#ets_buy.goods_id,
            GoodsNum = Info#ets_buy.num,
            Prefix = Info#ets_buy.prefix,
            Stren = Info#ets_buy.stren,
            PriceType = Info#ets_buy.price_type,
            Price = Info#ets_buy.price,
            <<Id:32, GoodsTypeId:32, GoodsNum:32, Prefix:8, Stren:8, PriceType:8, Price:32>>
        end,
    ListBin = list_to_binary(lists:map(F, WtbList)),
    {ok, pt:pack(18051, <<ListNum:16, ListBin/binary>>)};

%% 求购物品物品
write(18052, [Res, WtbInfo]) ->
    Id = WtbInfo#ets_buy.id,
    Class1 = WtbInfo#ets_buy.class1,
    Class2 = WtbInfo#ets_buy.class2,
    GoodsTypeId = WtbInfo#ets_buy.goods_id,
    GoodsNum = WtbInfo#ets_buy.num,
    Prefix = WtbInfo#ets_buy.prefix,
    Stren = WtbInfo#ets_buy.stren,
    PriceType = WtbInfo#ets_buy.price_type,
    Price = WtbInfo#ets_buy.price,
    {ok, pt:pack(18052, <<Res:16, Class1:8, Class2:8, Id:32, GoodsTypeId:32, GoodsNum:32, Prefix:8, Stren:8, PriceType:8, Price:32>>)};

%% 取消求购
write(18053, [Res, Id]) ->
    {ok, pt:pack(18053, <<Res:16, Id:32>>)};

%% 出售求购物品
write(18054, [Res, Id]) ->
    {ok, pt:pack(18054, <<Res:16, Id:32>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.




