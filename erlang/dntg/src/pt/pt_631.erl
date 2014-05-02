%%%------------------------------------------------
%%% @Module  : pt_631
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.21
%%% @Description: 摇钱树
%%%------------------------------------

-module(pt_631).
-export([read/2, write/2]).

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(63101, _) ->
    {ok, []};

read(63102, _) ->
    {ok, []};

read(63103, <<Type:8>>) ->
    {ok, [Type]};

read(63104, <<NeedGold:8>>) ->
    {ok, [NeedGold]};

read(63105, _) ->
    {ok, []};

read(63106, <<Type:32>>) ->
    {ok, [Type]};

read(63107, _) ->
    {ok, []};

read(63108, _) ->
    {ok, []};

read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================

%%% 获取玩家摇钱信息
write(63101, [List]) ->
    Bin = pack_list(List),
    {ok, pt:pack(63101, Bin)};

%%% 当前次数消耗获得情况
write(63102, [Type, Coin, CoinAdd, VipType, VipLevel, LessShake, TotalShake, VipAddCount, ShakeGold, CdTime, CoolGold]) ->
    Data = <<Type:8, Coin:32, CoinAdd:32, VipType:8, VipLevel:8, LessShake:8, TotalShake:8, VipAddCount:8, ShakeGold:16, CdTime:32, CoolGold:16>>,
    {ok, pt:pack(63102, Data)};

%%% 摇钱消耗信息
write(63103, [Gold, BindGold, Coin]) ->
    Data = <<Gold:32, BindGold:32, Coin:32>>,
    {ok, pt:pack(63103, Data)};

%%% 摇钱
write(63104, [Res, Coin, Gold, Type]) ->
    Data = <<Res:8, Coin:32, Gold:16, Type:8>>,
    {ok, pt:pack(63104, Data)};

%% %%% 当前级别物品
%% write(63105, [GoodsId, CanGet, NeedNum, GoodsNum]) ->
%%     Data = <<GoodsId:32, CanGet:8, NeedNum:8, GoodsNum:16>>,
%%     {ok, pt:pack(63105, Data)};

%%% 当前级别物品
write(63105, [ResultList]) ->
    {Len, Bin} = pack_coin_ka_list(ResultList),
    {ok, pt:pack(63105, <<Len:16, Bin/binary>>)};

%%% 获取当前级别物品
write(63106, [Result, GoodsId, GoodsNum, Cartoon]) ->
    Data = <<Result:8, GoodsId:32, GoodsNum:8, Cartoon:8>>,
    {ok, pt:pack(63106, Data)};

%%% 摇钱树冷却时间
write(63107, [Res, Gold]) ->
    Data = <<Res:8, Gold:32>>,
    {ok, pt:pack(63107, Data)};

%%% 摇钱树榜
write(63108, [List]) ->
    Len = length(List),
    Bin = list_to_binary(List),
    {ok, pt:pack(63108, <<Len:16, Bin/binary>>)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.


%% 打包其他用户的投注信息
pack_list(List) ->
    Fun = fun(Elem) ->
                {_Time, Name, Coin, Mutil} = Elem,
                Name1 = list_to_binary(Name),
                NL    = byte_size(Name1),
                <<NL:16, Name1/binary, Coin:32, Mutil:8>>
    end,
    BinList = list_to_binary([Fun(X) || X <- List]),
    Size  = length(List),
    <<Size:16, BinList/binary>>.

pack_coin_ka_list(ResultList) ->
    Len = length(ResultList),
    List = lists:map(fun({Type,GoodId,IsGet,ShakeCount,Num})-> <<Type:32,GoodId:32,IsGet:8,ShakeCount:8,Num:16>> end, ResultList),
    {Len, list_to_binary(List)}.




