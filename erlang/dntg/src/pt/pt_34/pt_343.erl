%%%------------------------------------------------
%%% @Module  : pt_343
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.8.21
%%% @Description: 爱情长跑
%%%------------------------------------

-module(pt_343).
-export([read/2, write/2]).

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(34300, _) ->
    {ok, no};

read(34301, _) ->
    {ok, no};

read(34302, _) ->
    {ok, no};

read(34303, <<Res:8, RoomId:8>>) ->
    {ok, [Res, RoomId]};

read(34304, _) ->
    {ok, no};

read(34305, <<GoodsId:32, PlayerId:32>>) ->
    {ok, [GoodsId, PlayerId]};

read(34306, _) ->
    {ok, no};

read(34307, _) ->
    {ok, no};

read(34309, _) ->
    {ok, no};

read(34310, _) ->
    {ok, no};

read(34311, _) ->
    {ok, no};

read(34312, _) ->
    {ok, no};

read(34313, _) ->
    {ok, no};

read(34314, _) ->
    {ok, no};

read(_Cmd, _R) ->
    {error, no_match}.

%%%=========================================================================
%%% 组包函数
%%%=========================================================================

%% 活动开始结束的通知(服务器主动发)
write(34300, [Time]) ->
	Data = <<Time:32>>,
    {ok, pt:pack(34300, Data)};

%% 领取道具
write(34301, Bin) ->
    Data = Bin,
    {ok, pt:pack(34301, Data)};

%% 房间列表
write(34302, Bin) ->
    Data = Bin,
    {ok, pt:pack(34302, Data)};

%% 进入、退出场景
write(34303, [Err, RoomId]) ->
	Data = <<Err:8, RoomId:8>>,
    {ok, pt:pack(34303, Data)};

%% 开始长跑,返回错误码
write(34304, [Err]) ->
	Data = <<Err:8>>,
    {ok, pt:pack(34304, Data)};

%% 使用道具
write(34305, [Err]) ->
	Data = <<Err:8>>,
    {ok, pt:pack(34305, Data)};

%% 提交任务
write(34306, [Err]) ->
	Data = <<Err:8>>,
    {ok, pt:pack(34306, Data)};

%% 结算
write(34308, Bin) ->
	Data = Bin,
    {ok, pt:pack(34308, Data)};

%% 任务状态
write(34309, [Err]) ->
	Data = <<Err:8>>,
    {ok, pt:pack(34309, Data)};

%% 活动开始的剩余时间  用公共线
write(34310, [Time]) ->
	Data = <<Time:32>>,
    {ok, pt:pack(34310, Data)};

%% 已完成长跑的玩家信息(所有)  用公共线
write(34311, Bin) ->
	Data = Bin,
    {ok, pt:pack(34311, Data)};

%% 距离上一波开跑已过去的时间(秒) 游戏线
write(34312, [Time]) ->
	Data = <<Time:32>>,
    {ok, pt:pack(34312, Data)};

%% 玩家报名后，在开跑前，定时获得经验(10秒) 游戏线
write(34313, [Exp]) ->
	Data = <<Exp:32>>,
    {ok, pt:pack(34313, Data)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.



