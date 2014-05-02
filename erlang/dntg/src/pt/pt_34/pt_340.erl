%%%--------------------------------------
%%% @Module  : pt_340
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.19
%%% @Description: 称号
%%%--------------------------------------

-module(pt_340).
-export([read/2, write/2]).

%%
%% 客户端 -> 服务端 ----------------------------
%%

%% 获得称号列表
read(34001, <<RoleId:32>>) ->
    {ok, RoleId};

%% 设置显示或取消显示
read(34002, <<DesignId:32, SetStatus:8>>) ->
    {ok, [DesignId, SetStatus]};

read(_, _) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ------------------------------------
%%

%% 获得称号列表
write(34001, [RoleId, List]) ->
	Len = length(List),
    Bin = list_to_binary(List),
	Data = <<RoleId:32, Len:16, Bin/binary>>,
    {ok, pt:pack(34001, Data)};

%% 设置显示或取消显示
write(34002, [Result, DesignId, NewStatus]) ->
    {ok, pt:pack(34002, <<Result:8, DesignId:32, NewStatus:8>>)};

%% 获得新称号
write(34003, [DesignId, Display, Content]) ->
	Content2 = pt:write_string(Content),
    {ok, pt:pack(34003, <<DesignId:32, Display:8, Content2/binary>>)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.
