%%%-------------------------------------------------------------------
%%% @Module	: pt_316
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 18 Jul 2012
%%% @Description: 首服礼包
%%%-------------------------------------------------------------------
-module(pt_316).
-export([read/2, write/2]).

%% 填写信息
%% read(31600, <<Bin/binary>>) ->
%%     {Phone, Bin1} = pt:read_string(Bin),
%%     {Email, _} = pt:read_string(Bin1),
%%     {ok, [Phone, Email]};
read(31600, <<Activity:8, Update:8, Charge:8, Time1:8, Time2:8, Time3:8, Bin/binary>>) ->
    {Phone, _} = pt:read_string(Bin),
    {ok, [Activity, Update, Charge, Time1, Time2, Time3, Phone]};

%% 默认配对
read(Cmd, _R) ->
    util:errlog("pt_314 read Cmd = ~p error~n", [Cmd]),
    ok.

%% 返回结果客户端
write(31600, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(31600, Data)};

%% 发送图标显示通知
write(31601, []) ->
    Data = <<>>,
    {ok, pt:pack(31601, Data)};

%% 默认配对
write(Cmd, _Bin) ->
    util:errlog("pt_316 write Cmd = ~p error~n", [Cmd]),
    {ok, pt:pack(0, <<>>)}.
