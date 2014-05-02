%%%------------------------------------------------
%%% @Module  : pt_101
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.18
%%% @Description: 改名
%%%------------------------------------

-module(pt_101).
-export([read/2, write/2]).

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(10101, <<Bin/binary>>) ->
    {Name, _} = pt:read_string(Bin),
    {ok, [Name]};

read(10111, <<GuildId:32, Bin/binary>>) ->
    {GuildName, _} = pt:read_string(Bin),
    {ok, [GuildId, GuildName]};

read(_Cmd, _R) ->
    {error, no_match}.

%%%=========================================================================
%%% 组包函数
%%%=========================================================================

%%% 服务器主动通知客户端可改名
write(10100, [Res]) ->
	Data = <<Res:8>>,
    {ok, pt:pack(10100, Data)};

%%% 角色改名
write(10101, [Res]) ->
	Data = <<Res:8>>,
    {ok, pt:pack(10101, Data)};

%%% 帮派改名
write(10111, [Res]) ->
	Data = <<Res:8>>,
    {ok, pt:pack(10111, Data)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.



