%% --------------------------------------------------------
%% @Module:           |pt_132
%% @Author:           |zhenghehe
%% @Created:          |2012-03-22
%% @Description:      |飞行系统协议
%% --------------------------------------------------------
-module(pt_132).
-export([read/2, write/2]).

read(13201, _) ->
    {ok, fly};

read(_Cmd, _R) ->
    {error, no_match}.

write(13201, [Result]) ->
    {ok, pt:pack(13201, <<Result:16>>)};

write(13202, [Result]) ->
    {ok, pt:pack(13202, <<Result:16>>)};
   
write(13203, [Msg]) ->
    MsgBin = pt:write_string(Msg),
    {ok, pt:pack(13203, <<MsgBin/binary>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.