%%%-----------------------------------
%%% @Module  : pt_123
%%% @Author  : zhenghehe
%%% @Created : 2011.06.23
%%% @Description: 12场景信息
%%%-----------------------------------
-module(pt_123).
-export([read/2, write/2]).
-include("server.hrl").
-include("scene.hrl").

%%加载所有场景npc, elem, monster信息
read(12300, _) ->
    {ok, load_all_scene};

read(_Cmd, _R) ->
    {error, no_match}.

%%加场景信息
write(12300, SceneInfoBin) ->
    {ok, pt:pack(12300, SceneInfoBin)};

%% 坐骑飞行
write(12301, [Pid, Platform, SerNum, Flyer, Speed]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12301, <<Pid:32, Platform1/binary, SerNum:16, Flyer:32, Speed:32>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.