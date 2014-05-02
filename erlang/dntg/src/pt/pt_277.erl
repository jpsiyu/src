%%%-------------------------------------------------------------------
%%% @Module	: pt_277
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 21 Aug 2012
%%% @Description: 七夕活动
%%%-------------------------------------------------------------------
-module(pt_277).
-export([read/2, write/2]).
%%
%% 客户端 -> 服务端 ----------------------------
%%

%% 查询活动完成情况
read(27700, _) ->
    {ok, []};
read(27706, _) ->
    {ok, []};
%% 领取活动奖励
read(27701, <<Type:8>>) ->
    {ok, [Type]};
read(27707, <<Type:8>>) ->
    {ok, [Type]};
read(27702, _) ->
    {ok, []};
read(27703, <<GiftId:32>>) ->
    {ok, [GiftId]};
read(27704, _) ->
    {ok, []};
read(27705, _) ->
    {ok, []};
read(27708, _) ->
    {ok, []};
read(27710, _) ->
    {ok, []};
read(27711, _) ->
    {ok, []};
read(27712, _) ->
    {ok, []};
read(_, _) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ----------------------------
%%
%% 查询完成情况
%% List:[{Type, Count, MaxCount, GiftId, CanGet},......]
write(27700, [List]) ->
    ListLen = length(List),
    BinList = lists:map(fun({Type, _Count, MaxCount, GiftId, Num, CanGet}) ->
				Count = case _Count > MaxCount of
					    true -> MaxCount;
					    false -> _Count
					end,
				[<<Type:8, Count:32, MaxCount:32, GiftId:32, Num:32, CanGet:8>>]
			end, List),
    Bin = list_to_binary(BinList),
    Data = <<ListLen:16, Bin/binary>>,
    {ok, pt:pack(27700, Data)};
write(27706, [List]) ->
    ListLen = length(List),
    BinList = [<<Type:8, Count:32, MaxCount:32, GiftId:32, Num:32, CanGet:8>>||{Type, Count, MaxCount, GiftId, Num, CanGet} <- List],
    Bin = list_to_binary(BinList),
    Data = <<ListLen:16, Bin/binary>>,
    {ok, pt:pack(27706, Data)};
%% 领取奖励
write(27701, [Result, GoodsTypeId, Num]) ->
    Data = <<Result:8, GoodsTypeId:32, Num:32>>,
    {ok, pt:pack(27701, Data)};
write(27707, [Result, GoodsTypeId, Num]) ->
    Data = <<Result:8, GoodsTypeId:32, Num:32>>,
    {ok, pt:pack(27707, Data)};
%% List:[{GiftId, IsGet},......]
write(27702, [List]) ->
    ListLen = length(List),
    BinList = [<<GiftId:32, IsGet:8>>||{GiftId, IsGet} <- List],
    Bin = list_to_binary(BinList),
    Data = <<ListLen:16, Bin/binary>>,
    {ok, pt:pack(27702, Data)};

write(27703, [Result, GiftId]) ->
    Data = <<Result:16, GiftId:32>>,
    {ok, pt:pack(27703, Data)};
    
write(27704, []) ->
    Data = <<>>,
    {ok, pt:pack(27704, Data)};
%% List:[{Num, Mlpt, Name},......]
write(27705, [List]) ->
    ListLen = length(List),
    BinList = [<<Num:8, Mlpt:32, Name/binary>>||{Num, Mlpt, Name} <- List],
    Bin = list_to_binary(BinList),
    Data = <<ListLen:16, Bin/binary>>,
    {ok, pt:pack(27705, Data)};

write(27708, [Num]) ->
    Data = <<Num:8>>,
    {ok, pt:pack(27708, Data)};
write(27709, [Num]) ->
    Data = <<Num:8>>,
    {ok, pt:pack(27709, Data)};
write(27710, [Time]) ->
    Data = <<Time:32>>,
    {ok, pt:pack(27710, Data)};
write(27711, [Result,GiftId]) ->
    Data = <<Result:8, GiftId:32>>,
    {ok, pt:pack(27711, Data)};
write(27712, [_GiftList]) ->
    Len = length(_GiftList),
    GiftList = [<<Day:8,GiftId:32,State:8,Num:8>> || {Day,GiftId,Num,_,State} <- _GiftList],
    Bin = list_to_binary(GiftList),
    Data = <<Len:16, Bin/binary>>,
    {ok, pt:pack(27712, Data)};
write(_, _) ->
    {ok, pt:pack(0, <<>>)}.
