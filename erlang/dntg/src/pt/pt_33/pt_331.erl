%%%--------------------------------------
%%% @Module  : pt_330
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.9
%%% @Description: 全民垂钓
%%%--------------------------------------

-module(pt_331).
-export([read/2, write/2]).

%%
%% 客户端 -> 服务端 ----------------------------
%%

%% 进入场景
read(33101, <<RoomId:8>>) ->
    {ok, RoomId};

%% 退出场景
read(33102, _) ->
    {ok, leave_scene};

%% 查询房间列表
read(33103, _) ->
    {ok, get_room};

%% 开始钓鱼
read(33106, <<MonId:32>>) ->
    {ok, MonId};

%% 收竿
read(33107, _) ->
    {ok, end_fishing};

%% 取消钓鱼
read(33108, _) ->
    {ok, cancel_fishing};

%% 偷鱼
read(33109, <<PlayerId:32>>) ->
    {ok, PlayerId};

%% 取消偷鱼读条
read(33110, _) ->
    {ok, cancel_steal_cd};

%% 完成偷鱼读条
read(33111, _) ->
    {ok, finish_steal_cd};

%% 查看被偷对象的鱼
read(33115, <<PlayerId:32>>) ->
    {ok, PlayerId};

%% 领取阶段目标奖励
read(33117, _) ->
    {ok, get_step_award};

%% 请求翻牌结果
read(33126, _) ->
    {ok, get_max_score_award};

read(_, _) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ----------------------------
%%

%% 进入场景
write(33101, [ErrorCode, RoomId, Score, LimitUp, Exp, LLPT, Stealed, FishList, StepAwardId]) ->
    Len = length(FishList),
	ListBin = list_to_binary(FishList),
    Data = <<ErrorCode:8, RoomId:8, Score:16, LimitUp:16, Exp:32, LLPT:32, Stealed:8, Len:16, ListBin/binary, StepAwardId:8>>,
    {ok, pt:pack(33101, Data)};

%% 退出场景
write(33102, ErrorCode) ->
    Data = <<ErrorCode:8>>,
    {ok, pt:pack(33102, Data)};

%% 查询房间列表
write(33103, List) ->
	Len = length(List),
	BinData = list_to_binary(List),
    Data = <<Len:16, BinData/binary>>,
    {ok, pt:pack(33103, Data)};

%% 开始钓鱼
write(33106, [RoleId, FishId, ErrorCode]) ->
    Data = <<RoleId:32, FishId:32, ErrorCode:8>>,
    {ok, pt:pack(33106, Data)};

%% 收杆
write(33107, [RoleId, ErrorCode, FishId]) ->
    Data = <<RoleId:32, ErrorCode:8, FishId:32>>,
    {ok, pt:pack(33107, Data)};

%% 取消钓鱼
write(33108, [RoleId, ErrorCode]) ->
    Data = <<RoleId:32, ErrorCode:8>>,
    {ok, pt:pack(33108, Data)};

%% 偷鱼
write(33109, [RoleId, PlayerId, ErrorCode]) ->
    Data = <<RoleId:32, PlayerId:32, ErrorCode:8>>,
    {ok, pt:pack(33109, Data)};

%% 取消偷鱼读条
write(33110, ErrorCode) ->
    Data = <<ErrorCode:8>>,
    {ok, pt:pack(33110, Data)};

%% 完成偷鱼读条
write(33111, [ErrorCode, FishId]) ->
    Data = <<ErrorCode:8, FishId:32>>,
    {ok, pt:pack(33111, Data)};

%% 查看被偷对象的鱼
write(33115, [PlayerId, List]) ->
	Len = length(List),
	BinData = list_to_binary(List),
    Data = <<PlayerId:32, Len:16, BinData/binary>>,
    {ok, pt:pack(33115, Data)};

%% 领取阶段目标奖励
write(33117, ErrorCode) ->
    Data = <<ErrorCode:16>>,
    {ok, pt:pack(33117, Data)};

%% 刷新收益
write(33119, [Score, Exp, LLPT, List]) ->
	Len = length(List),
	BinData = list_to_binary(List),
    Data = <<Score:16, Exp:32, LLPT:32, Len:16, BinData/binary>>,
    {ok, pt:pack(33119, Data)};

%% 消息提示
write(33121, [Type, FishId]) ->
    Data = <<Type:8, FishId:32>>,
    {ok, pt:pack(33121, Data)};

%% 弹出翻牌面板
write(33125, Result) ->
    Data = <<Result:8>>,
    {ok, pt:pack(33125, Data)};

%% 翻牌结果
write(33126, [ErrorCode, GoodsTypeId, GoodsNum, Bind]) ->
    Data = <<ErrorCode:16, GoodsTypeId:32, GoodsNum:8, Bind:8>>,
    {ok, pt:pack(33126, Data)};

%% 广播活动开始
write(33140, Second) ->
    Data = <<Second:32>>,
    {ok, pt:pack(33140, Data)};

%% 广播活动结束
write(33141, _) ->
    Data = <<>>,
    {ok, pt:pack(33141, Data)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.
