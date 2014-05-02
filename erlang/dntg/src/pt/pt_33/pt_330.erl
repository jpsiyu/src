%%%--------------------------------------
%%% @Module  : pt_330
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.9
%%% @Description: 温泉
%%%--------------------------------------

-module(pt_330).
-export([read/2, write/2]).

%%
%% 客户端 -> 服务端 ----------------------------
%%

%% 进入温泉场景地图
read(33001, <<RoomId:8>>) ->
    {ok, RoomId};

%% 退出温泉场景地图
read(33002, _) ->
    {ok, leave_scene};

%% 查询房间列表
read(33003, _) ->
    {ok, get_room};

%% 获取收益
read(33005, _) ->
    {ok, get_gain};

%% 互动
read(33008, <<InteractType:8, PlayerId:32>>) ->
    {ok, [InteractType, PlayerId]};

%% 广播取消晕眩、结冰状态
read(33025, <<PlayerId:32, Type:8>>) ->
	 {ok, [PlayerId, Type]};

read(_, _) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ----------------------------
%%

%% 进入温泉场景地图
write(33001, [ErrorCode, InteractNum, InteractNum2, RoomId]) ->
    Data = <<ErrorCode:8, InteractNum:8, InteractNum2:8, RoomId:8>>,
    {ok, pt:pack(33001, Data)};

%% 退出温泉场景地图
write(33002, ErrorCode) ->
    Data = <<ErrorCode:8>>,
    {ok, pt:pack(33002, Data)};

%% 查询房间列表
write(33003, List) ->
	Len = length(List),
	BinData = list_to_binary(List),
    Data = <<Len:16, BinData/binary>>,
    {ok, pt:pack(33003, Data)};

%% 获取收益
write(33005, ErrorCode) ->
    Data = <<ErrorCode:8>>,
    {ok, pt:pack(33005, Data)};

%% 互动
write(33008, [ErrorCode, InteractType]) ->
    Data = <<ErrorCode:8, InteractType:8>>,
    {ok, pt:pack(33008, Data)};

%% 获取沙滩排行榜前10名榜单
write(33010, List) ->
    Len = length(List),
    Bin = list_to_binary(List),
    Data = <<Len:16, Bin/binary>>,
    {ok, pt:pack(33010, Data)};

%% 广播活动开始
write(33020, Second) ->
    Data = <<Second:32>>,
    {ok, pt:pack(33020, Data)};

%% 广播活动结束
write(33021, _) ->
    Data = <<>>,
    {ok, pt:pack(33021, Data)};

%% 广播活动结束
write(33023, [Aid, Bid, InteractType]) ->
    Data = <<Aid:32, Bid:32, InteractType:8>>,
    {ok, pt:pack(33023, Data)};

write(33025, [PlayerId, Type]) ->
    Data = <<PlayerId:32, Type:8>>,
    {ok, pt:pack(33025, Data)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.
