%%%--------------------------------------
%%% @Module  : pt_119
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.27
%%% @Description: 设定
%%%--------------------------------------

-module(pt_119).
-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%

%%保存挂机设定
read(11901, <<Setting/binary>>) ->
	{Content, _} = pt:read_string(Setting),
    {ok, Content};

%%获取挂机设定
read(11902, _) ->
    {ok, get_setting}.

%%
%%服务端 -> 客户端 ----------------------------
%%

%%保存挂机设定
write(11901, ErrorCode) ->
    Data = <<ErrorCode:8>>,
    {ok, pt:pack(11901, Data)};
	
%%获取挂机设定
write(11902, Setting) ->
	Data = pt:write_string(Setting),
    Bin = <<Data/binary>>,
    {ok, pt:pack(11902, Bin)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
