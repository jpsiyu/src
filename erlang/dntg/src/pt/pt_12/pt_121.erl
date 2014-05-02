%%%-----------------------------------
%%% @Module  : pt_121
%%% @Author  : zhenghehe
%%% @Created : 2011.06.23
%%% @Description: 121场景信息
%%%-----------------------------------
-module(pt_121).
-export([read/2, write/2]).

%% 动作表情
read(12100, <<FaceId:32>>) ->
    {ok, [FaceId]};

%% 飞行坐骑剩余
read(12106, <<Type:8>>) ->
    {ok, Type};

read(_Cmd, _R) ->
    {error, no_match}.

%% 动作表情
write(12100, [FaceId, RoleId, Platform, SerNum, RoleName]) ->
    Platform1 = pt:write_string(Platform),
    BinRoleNameInfo = pt:write_string(RoleName),
    {ok, pt:pack(12100, <<FaceId:32, RoleId:32, Platform1/binary, SerNum:16, BinRoleNameInfo/binary>>)};

%% 怪物说话
write(12103, [MonId, TalkMsg]) ->
    TalkMsg_b = pt:write_string(TalkMsg),
    {ok, pt:pack(12103, <<MonId:32, TalkMsg_b/binary>>)};

%%飞行坐骑变更
write(12106, [PlayerId, Platform, SerNum, Speed, FlyMountId, Permanent, LeftTime]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12106, <<PlayerId:32, Platform1/binary, SerNum:16, Speed:16, FlyMountId:32, Permanent:8, LeftTime:32>>)};

%% 广播帮战水晶/城战 状态
write(12107, [Id, StoneType]) ->
    {ok, pt:pack(12107, <<Id:32, StoneType:8>>)};

%% 广播可见 状态
write(12108, [Id, Platform, ServerNum, Visible]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12108, <<Id:32, Platform1/binary, ServerNum:16, Visible:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
