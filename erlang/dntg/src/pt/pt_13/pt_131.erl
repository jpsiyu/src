%% --------------------------------------------------------
%% @Module:           |pt_131
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-03-22
%% @Description:      |打坐双修协议
%% --------------------------------------------------------
-module(pt_131).
-export([read/2, write/2]).
-include("server.hrl").
-include("buff.hrl").
-include("goods.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%

%% 打坐
read(13101, _) ->
    {ok, sit_down};

%% 打坐回血
read(13102, _) ->
    {ok, sit_down_reply};

%% 取消打坐
read(13103, _) ->
    {ok, sit_up};

%% 双修邀请
read(13104, <<PlayerId:32>>) ->
    {ok, PlayerId};

%% 双修邀请回应
read(13105, <<PlayerId:32, Flag:8>>) ->
    {ok, [PlayerId, Flag]};

%% %% 离线修炼加速
%% read(13108, <<UseType:8, Time:8>>) ->
%%     {ok, [UseType, Time]};

%%查询离线挂机信息
read(13111, _) ->
    {ok, query_offlineTime};

%%兑换离线挂机经验
read(13112, <<Type:8,Time:16>>) ->
    {ok, [Type,Time]};

%%查询离线挂机信息
read(13113, _) ->
    {ok, []};

read(13114, _) ->
    {ok, []};

read(_Cmd, _R) ->
    {error, no_match}.
%%
%%客户端 -> 服务端 ----------------------------
%%

%% 打坐
write(13101, [PlayerId, LeftTime]) ->
    {ok, pt:pack(13101, <<PlayerId:32, LeftTime:32>>)};

%% 打坐回蓝
write(13102, [Mp, Mp_lim, Exp_Add]) ->
    {ok, pt:pack(13102, <<Mp:32, Mp_lim:32, Exp_Add:32>>)};

%% 取消打坐
write(13103, PlayerId) ->
    {ok, pt:pack(13103, <<PlayerId:32>>)};
%% 双修邀请
write(13104, Res) ->
    {ok, pt:pack(13104, <<Res:16>>)};

%% 双修邀请回应
write(13105, [Res, LeftTime]) ->
    {ok, pt:pack(13105, <<Res:16, LeftTime:32>>)};

%% 双修邀请通知
write(13106,[Type, PlayerId, LeftTime, PlayerName])->
	Name = pt:write_string(PlayerName),
	Data = <<Type:16, PlayerId:32, LeftTime:32, Name/binary>>,
	{ok, pt:pack(13106, Data)};

%% %% 离线修炼加速
%% write(13108, [Res, LeftTime, Exp_Add]) ->
%%     {ok, pt:pack(13108, <<Res:8, LeftTime:32, Exp_Add:32>>)};

%% 双修开始通知场景---发九宫格
%% PosX:16  X坐标
%% PosY:16  Y坐标
%% From_Player_Id:32  邀请人角色ID
%% From_Player_Name:string  邀请人角色名称
%% Rec_Player_Id:32  被邀请人角色ID
%% Rec_Player_Name:string  被邀请人角色名称   

write(13107,[PosX, PosY, From_Player_Id, From_Player_Name,Rec_Player_Id, Rec_Player_Name])->
	Bin_From_Player_Name = pt:write_string(From_Player_Name),
	Bin_Rec_Player_Name = pt:write_string(Rec_Player_Name),
	{ok, pt:pack(13107,<<PosX:16, PosY:16,From_Player_Id:32,Bin_From_Player_Name/binary,Rec_Player_Id:32,Bin_Rec_Player_Name/binary>>)};

%% 查询离线挂机信息
write(13111, [Time,Exp,Tb,Yb]) ->
	Data = <<Time:16,Exp:32,Tb:16,Yb:16>>,
    {ok, pt:pack(13111, Data)};

%% 兑换离线挂机经验
write(13112, [Result,Exp]) ->
	Data = <<Result:8,Exp:32>>,
    {ok, pt:pack(13112, Data)};

write(13114, [Flag, Left]) ->
    Data = <<Flag:8, Left:32>>,
    {ok, pt:pack(13114, Data)};
    
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
