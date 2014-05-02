%%%-----------------------------------
%%% @Module  : pt_114
%%% @Author  : zhenghehe
%%% @Created : 2010.04.29
%%% @Description: 11聊天信息
%%%-----------------------------------
-module(pt_114).
-export([write/2]).
-include("record.hrl").

%% 发送护送求救
write(11401, [SceneId, X, Y, Nick]) ->
    Nick1 = list_to_binary(Nick),
    L = byte_size(Nick1),
    Data = <<SceneId:32, X:16, Y:16, L:16, Nick1/binary>>,
    {ok, pt:pack(11401, Data)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.