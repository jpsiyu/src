%%----------------------------------------------------
%% @Module: lib_npc_transport
%% @Auther: hc
%% @Email : 215837829@qq.com
%% @Data  : 2010-10-15
%%----------------------------------------------------
-module(lib_npc_transport).
-export([
    get_transport_info/3,
    transport/2,
    to_one_place/2
        ]).

-include("common.hrl").
-include("record.hrl").
-include("server.hrl").

%获取NPC传送信息
get_transport_info(_SceneId, Npcid, Num) ->
    Info = data_npc_transport:get(Npcid),
    {value, Res} = lists:keysearch(Num,1,Info),
    Res.

%传送
transport(PlayerStatus, Res) ->
    {_,Lv,[SceneId, X, Y]} = Res,
    case PlayerStatus#player_status.lv < Lv of
        true ->
            {1, PlayerStatus};
        false ->
            %通知别人离开场景
            lib_scene:leave_scene(PlayerStatus),
            %pp_scene:handle(12004, PlayerStatus, s),
            NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
            SceneName = lib_scene:get_scene_name(NewPlayerStatus#player_status.scene),
            {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, SceneName, NewPlayerStatus#player_status.scene]),
            lib_server_send:send_to_uid(NewPlayerStatus#player_status.id, BinData),
            {0, NewPlayerStatus}
    end.

%
to_one_place(PlayerStatus, [SceneId, X, Y]) ->
    %通知别人离开场景
    lib_scene:leave_scene(PlayerStatus),
    %%pp_scene:handle(12004, PlayerStatus, s),
    NewPlayerStatus = PlayerStatus#player_status{scene=SceneId, x=X, y=Y},
    SceneName = lib_scene:get_scene_name(NewPlayerStatus#player_status.scene),
    {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, SceneName, NewPlayerStatus#player_status.scene]),
    lib_server_send:send_to_uid(NewPlayerStatus#player_status.id, BinData),
    NewPlayerStatus.
