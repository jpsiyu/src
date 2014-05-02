%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-25
%% Description: 开服时间
%% --------------------------------------------------------
-module(pt_311).
-export([read/2, write/2]).

%% 取开服时间
read(31100, _R) ->
    {ok, open_time};

%% 默认配对
read(Cmd, _R) ->
    util:errlog("pt_311 read Cmd = ~p error~n", [Cmd]),
    ok.

%% 取开服时间
write(31100, Otime) ->
    {ok, pt:pack(31100, <<Otime:32>>)};

%% 默认配对
write(Cmd, _Bin) ->
    util:errlog("pt_311 write Cmd = ~p error~n", [Cmd]),
    {ok, pt:pack(0, <<>>)}.



