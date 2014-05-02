%%%-----------------------------------
%%% @Module  : pp_npc
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.12.29
%%% @Description: npc
%%%-----------------------------------
-module(pp_npc).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").

%% 获取npc默认对话和关联任务
%% return {ok, [int, list, list], record}
handle(32000, PlayerStatus, [Id]) ->
    case lib_npc:get_npc_info_by_id(Id) of
        [] -> ok;
        Npc ->
            {TaskList, TalkList} = default_talk(Npc, PlayerStatus),
            {ok, BinData} = pt_320:write(32000, [Id, TaskList, TalkList]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
    end;

%% 任务对话
handle(32001, PlayerStatus, [Id, TaskId])->
    case lib_npc:get_npc_info_by_id(Id) of
        [] -> ok;
        Npc -> task_talk(Id, TaskId, Npc, PlayerStatus)
    end;

%%获取npc传送列表
handle(32003, PlayerStatus, [Id])->
    Data = data_npc_transport:get(Id),
    {ok, BinData} = pt_320:write(32003, [Data, Id]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);

%%npc传送
handle(32004, PlayerStatus, [Id,Num])->
    SceneId = PlayerStatus#player_status.scene,
    Res = lib_npc_transport:get_transport_info(SceneId, Id, Num),
    {ErrorCode, NewStatus} = lib_npc_transport:transport(PlayerStatus,Res),
    {ok, BinData} = pt_320:write(32004, [ErrorCode]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
    {ok, NewStatus};

%% 请求传出红名监狱
handle(32005, _PlayerStatus, _)->
    ok;
%%     {Error, NewPlayer_status} = lib_pk_control:reques_out(PlayerStatus),
%%     {ok, BinData} = pt_32:write(32005, [Error]),
%%     lib_send:send_one(PlayerStatus#player_status.socket, BinData),
%%     case Error of
%%         0 ->
%%             {ok, NewPlayer_status};
%%         _ ->
%%             ok
%%     end;

%%npc传送
handle(32006, PlayerStatus, _)->
    NewPlayerStatus = lib_npc_transport:to_one_place(PlayerStatus, [989,30,85]),
    {ok, BinData} = pt_320:write(32006, [0]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
    {ok, NewPlayerStatus};

handle(_Cmd, _PlayerStatus, _Data) ->
    {error, bad_request}.

%% --------- 私有函数 ----------

default_talk(Npc, PlayerStatus) ->
    %TalkList = data_talk:get(Npc#ets_npc.talk),
    TalkList = Npc#ets_npc.talk,
    TaskList = lib_task:get_npc_task_list(PlayerStatus#player_status.tid, Npc#ets_npc.id, PlayerStatus),
    {TaskList, TalkList}.

task_talk(Id, TaskId, Npc, PlayerStatus) ->
    {_Type, TalkId} = lib_task:get_npc_task_talk_id(TaskId, Npc#ets_npc.id, PlayerStatus),
    %TalkList = data_talk:get(TalkId),
    TalkList = TalkId,
%    %% 如果是开始对话或结束对话，加入任务奖励
%    NewTalkList =
%    case (Type =:= start_talk orelse Type =:= end_talk ) andalso TalkList =/= [] of
%        false -> TalkList;
%        true -> add_awrad_talk(TaskId, TalkList, PlayerStatus)
%    end,
    {ok, BinData} = pt_320:write(32001, [Id, TaskId, TalkList]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData).

%add_awrad_talk(TaskId, TalkList, PlayerStatus)->
%    [FiPlayerStatust | T ] = TalkList,
%    TD = lib_task:get_data(TaskId, PlayerStatus),
%    NewFiPlayerStatust = FiPlayerStatust ++ [{task_award, lib_task:get_award_msg(TD, PlayerStatus), []}],
%    [NewFiPlayerStatust | T].
