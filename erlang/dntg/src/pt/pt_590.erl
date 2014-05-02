%%%-----------------------------------
%%% @Module  : pt_590
%%% @Author  : xhg
%%% @Email   : xuhuguang@jieyou.com
%%% @Created : 2011.01.20
%%% @Description: 59连接提示信息
%%%-----------------------------------
-module(pt_590).
-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%% 进入游戏错误提示信息
write(59004, Code) ->
    {ok, pt:pack(59004, <<Code:16>>)};

%% 隐藏线路
write(59005, Line) ->
    {ok, pt:pack(59005, <<Line:16>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
