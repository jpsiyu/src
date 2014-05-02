%% --------------------------------------------------------
%% @Module:           |pt_361
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-00-00
%% @Description:      |开箱子
%% --------------------------------------------------------

-module(pt_361).
-export([read/2, write/2]).

%%
%% 客户端 -> 服务端 ----------------------------
%%

read(36101, <<PackageId:32>>) ->
    {ok, [PackageId]};

read(36102, <<PackageId:32>>) ->
    {ok, [PackageId]};

read(36111, <<PackageId:32>>) ->
    {ok, [PackageId]};

read(36112, _) ->
    {ok, 36112};

read(_, _) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ----------------------------
%%

write(36101, [Res, XYZ, BoxWPList]) ->
    Bin = pack_36101(BoxWPList),
    Data = <<Res:8, XYZ:32, Bin/binary>>,
    {ok, pt:pack(36101, Data)};

write(36102, [Res, XYZ, XuHao, GoodsTypeId, Num]) ->
    Data = <<Res:8, XYZ:32, XuHao:16, GoodsTypeId:32, Num:16>>,
    {ok, pt:pack(36102, Data)};

write(36111, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(36111, Data)};

write(36112, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(36112, Data)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.

%% -----------------------------------------------------------------
%% 打包36101
%% -----------------------------------------------------------------
pack_36101([]) ->
    <<0:16, <<>>/binary>>;
pack_36101(List) ->
    Rlen = length(List),
    F = fun({XuHao, GoodsTypeId, Num}) ->
        <<XuHao:16, GoodsTypeId:32, Num:16>>
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.