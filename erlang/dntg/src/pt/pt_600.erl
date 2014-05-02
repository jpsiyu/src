%%%-----------------------------------
%%% @Module  : 600
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.07.14
%%% @Description: 60 网关
%%%-----------------------------------
-module(pt_600).
-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%

%% 获取游戏登陆信息
read(60000, <<Bin/binary>>) ->
    {Accname, _} = pt:read_string(Bin),
    {ok, Accname};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%% 服务器信息
write(60000, [[], State]) ->
    {ok, pt:pack(60000, <<0:16, <<>>/binary, State:8>>)};
write(60000, [List, State]) ->
    Rlen = length(List),
    F = fun([Ip, Port, Num, S]) ->
        Ip1 = pt:write_string(Ip),
        <<Ip1/binary, Port:16, Num:16, S:8>>
    end, 
    RB = list_to_binary([F(D) || D <- List]),
    {ok, pt:pack(60000, <<Rlen:16, RB/binary, State:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
