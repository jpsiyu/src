%%%-------------------------------------------------------------------
%%% @Module	: pt_172
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	:  2 Nov 2012
%%% @Description: 
%%%-------------------------------------------------------------------
-module(pt_172).
-export([read/2, write/2]).
%%
%% 客户端 -> 服务端 ----------------------------
%%

%% 查询器灵信息
read(17200, _) ->
    {ok, []};
%% 器灵开孔
read(17201, _) ->
    {ok, []};
%% 器灵培养
read(17202, _) ->
    {ok, []};
read(17203, <<PlayerId:32>>) ->
    {ok, [PlayerId]};
read(_, _) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ----------------------------
%%

pack(Type, List) ->
    Len = length(List),
    Bin = list_to_binary([<<Pos:8, Open:8, Lv:8, Exp:32, Type:8>> || {Pos, Open, Lv, Exp} <- List]),
    <<Len:16, Bin/binary>>.
%% 查询完成情况
%% @param:Forza|Agile|Wit|Thew = #status_qiling.forza|agile|wit|thew = [{位置，开启，等级，经验},...]
write(17200, [Forza, Agile, Wit, Thew]) ->
    ForzaBin = pack(1,Forza),
    AgileBin = pack(2,Agile),
    WitBin = pack(3,Wit),
    ThewBin = pack(4,Thew),
    Data = <<ForzaBin/binary, AgileBin/binary, WitBin/binary, ThewBin/binary>>,
    {ok, pt:pack(17200, Data)};
%% 器灵开孔
write(17201, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(17201, Data)};
%% 器灵培养
write(17202, [Result,Type,Pos]) ->
    Data = <<Result:8, Type:8, Pos:8>>,
    {ok, pt:pack(17202, Data)};
%% 器灵属性加成查询
write(17203, [Forza, Agile, Wit, Thew, PlayerId]) ->
    Data = <<Forza:16, Agile:16, Wit:16, Thew:16, PlayerId:32>>,
    {ok, pt:pack(17203, Data)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.
