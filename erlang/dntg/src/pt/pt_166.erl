%%%------------------------------------
%%% module  : pp_gemstone
%%% @Author : huangwenjie
%%% @Email  : 1015099316@qq.com
%%% @Create : 2014.2.19
%%% @Description: 宝石系统
%%%-------------------------------------
-module(pt_166).
-export([read/2, write/2]).

read(16600, _) ->
    {ok, []};

read(16601, <<EquipPos:8, GemPos:8>>) ->
    {ok, [EquipPos, GemPos]};

read(16602, <<EquipPos:8, GemPos:8>>) -> 
    {ok, [EquipPos, GemPos]};

read(16603, <<EquipPos:8, GemPos:8, Num:16, Bin/binary>>) ->
    {_, GoodsList} = pt:read_id_num_list(Bin, [], Num),
    {ok, [EquipPos, GemPos, GoodsList]};

read(16604, <<PlayerId:32>>) ->
    {ok, [PlayerId]};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.


write(16600, GemStonesInfo) -> 
    Len = length(GemStonesInfo),
    Bin = list_to_binary(GemStonesInfo),
    BinData = <<Len:16, Bin/binary>>,
    {ok, pt:pack(16600, BinData)};

write(16601, GemStoneInfo) ->
    {ok, pt:pack(16601, GemStoneInfo)};

write(16602, [Error, EquipPos, GemPos]) -> 
    Data = <<Error:8, EquipPos:8, GemPos:8>>,
    {ok, pt:pack(16602, Data)};

write(16603, [Error, IsUpgrade, Exp]) ->
    Data = <<Error:8, IsUpgrade:8, Exp:16>>,
    {ok, pt:pack(16603, Data)};

write(16604, [Error, AttrList]) ->
    Len = length(AttrList),
    Bin = list_to_binary(AttrList),
    BinData = <<Error:8, Len:16, Bin/binary>>,
    {ok, pt:pack(16604, BinData)};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.