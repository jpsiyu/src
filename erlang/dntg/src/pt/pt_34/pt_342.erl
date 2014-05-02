%%%--------------------------------------
%%% @Module  : pt_342
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.6
%%% @Description: 捕蝴蝶活动
%%%--------------------------------------

-module(pt_342).
-export([read/2, write/2]).

%%
%% 客户端 -> 服务端 ----------------------------
%%

%% 查询房间列表
read(34203, _) ->
    {ok, get_room};

%% 进入地图
read(34205, <<RoomId:8>>) ->
    {ok, RoomId};

%% 退出地图
read(34206, _) ->
    {ok, leave};
  
%% 使用道具
read(34210, <<Type:8, PlayerId:32>>) ->
    {ok, [Type, PlayerId]};

%% 领取阶段目标奖励
read(34216, <<Level:8>>) ->
    {ok, Level};

read(_, _) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ------------------------------------
%%

%% 广播活动开始
write(34201, LeftTime) ->
	Data = <<LeftTime:32>>,
    {ok, pt:pack(34201, Data)};

%% 广播活动结束
write(34202, _) ->
	Data = <<>>,
    {ok, pt:pack(34202, Data)};

%% 查询房间列表
write(34203, List) ->
	Len = length(List),
	BinData = list_to_binary(List),
    Data = <<Len:16, BinData/binary>>,
    {ok, pt:pack(34203, Data)};

%% 进入地图
write(34205, [Result, Score, LimitUp, Exp, LLPT, RoomId, StatList, AwardList]) ->
	StatLen = length(StatList),
	StatBin = list_to_binary(StatList),
	AwardLen = length(AwardList),
	AwardBin = list_to_binary(AwardList),
	Data = <<Result:8, Score:16, LimitUp:16, Exp:32, LLPT:32, RoomId:8, StatLen:16, StatBin/binary, AwardLen:16, AwardBin/binary>>,
    {ok, pt:pack(34205, Data)};

%% 退出地图
write(34206, Result) ->
	Data = <<Result:8>>,
    {ok, pt:pack(34206, Data)};

%% 获得道具
write(34209, List) ->
	Len = length(List),
	BinData = list_to_binary(List),
	Data = <<Len:16, BinData/binary>>,
    {ok, pt:pack(34209, Data)};

%% 使用道具
write(34210, Result) ->
	Data = <<Result:8>>,
    {ok, pt:pack(34210, Data)};

%% 打怪获得道具
write(34211, List) ->
	Len = length(List),
	BinData = list_to_binary(List),
	Data = <<Len:16, BinData/binary>>,
    {ok, pt:pack(34211, Data)};

%% 获得收益
write(34212, [Score, Exp, LLPT, StatList, AwardList]) ->
	StatLen = length(StatList),
	StatBin = list_to_binary(StatList),
	AwardLen = length(AwardList),
	AwardBin = list_to_binary(AwardList),
	Data = <<Score:16, Exp:32, LLPT:32, StatLen:16, StatBin/binary, AwardLen:16, AwardBin/binary>>,
    {ok, pt:pack(34212, Data)};

%% 打怪获得积分
write(34214, [MonId, Score]) ->
	Data = <<MonId:32, Score:16>>,
    {ok, pt:pack(34214, Data)};

%% 满积分获得翻牌
write(34215, [Result, GoodsTypeId, Num, Bind]) ->
	Data = <<Result:16, GoodsTypeId:32, Num:8, Bind:8>>,
    {ok, pt:pack(34215, Data)};

%% 领取阶段目标奖励
write(34216, [Level, ErrorCode]) ->
	Data = <<Level:8, ErrorCode:16>>,
    {ok, pt:pack(34216, Data)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.
