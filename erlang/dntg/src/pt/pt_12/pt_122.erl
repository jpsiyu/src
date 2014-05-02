%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-22
%% Description: TODO:
%% --------------------------------------------------------
-module(pt_122).
-export([write/2]).


%% vip到期广播
write(12202, [RoleId, Platform, SerNum]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12202, <<RoleId:32, Platform1/binary, SerNum:16>>)};

%VIP广播
write(12203, [Rid, Platform, SerNum, VipType]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12203, <<Rid:32, Platform1/binary, SerNum:16, VipType:8>>)};

write(_Cmd, _Bin) ->
    {ok, pt:pack(0, <<>>)}.


