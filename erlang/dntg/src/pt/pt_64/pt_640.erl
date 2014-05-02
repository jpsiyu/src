%%%------------------------------------------------
%%% @Module  : pt_640
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.7.7
%%% @Description: 大闹天宫(无边海)
%%%------------------------------------

-module(pt_640).
-export([read/2, write/2]).

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(64002, <<Res:8, RoomLv:8, RoomId:8>>) ->
    {ok, [Res, RoomLv, RoomId]};

read(64003, _) ->
    {ok, no};

read(64004, <<Res:32>>) ->
    {ok, Res};

read(64009, <<RoomLv:8, RoomId:8>>) ->
    {ok, [RoomLv, RoomId]};

read(64011, _) ->
    {ok, no};

read(_Cmd, _R) ->
    {error, no_match}.

%%%=========================================================================
%%% 组包函数
%%%=========================================================================

%%% 活动开始结束的通知(服务器主动发)
write(64001, [Type, Time]) ->
	Data = <<Type:8, Time:32>>,
    {ok, pt:pack(64001, Data)};

%%% 进入 退出战场
write(64002, [Res, Lv, ErrorData]) ->
	ErrorData2 = list_to_binary(ErrorData),
	EL = byte_size(ErrorData2),
	Data = <<Res:8, Lv:8, EL:16, ErrorData2/binary>>,
    {ok, pt:pack(64002, Data)};

%%% 任务信息(玩家进入场景后客户端请求)
write(64003, Bin) ->
	Data = Bin,
    {ok, pt:pack(64003, Data)};

%%% 领取奖励
write(64004, Bin) ->
	Data = Bin,
    {ok, pt:pack(64004, Data)};

%%% 击杀玩家 获得任务物品；被人击杀，掉落物品
write(64005, Bin) ->
	Data = Bin,
    {ok, pt:pack(64005, Data)};

%%% 任务信息(活动开始后服务器每5秒给客户端发送一次任务信息)
write(64006, Bin) ->
	Data = Bin,
    {ok, pt:pack(64006, Data)};

%%% 中间Boss剩余刷新时间 服务器主动发
write(64007, Time) ->
	Data = <<Time:32>>,
    {ok, pt:pack(64007, Data)};

%%% 队伍进入南天门提示
write(64009, [RoomLv, RoomId]) ->
	Data = <<RoomLv:8, RoomId:8>>,
    {ok, pt:pack(64009, Data)};

%%% 队伍进入南天门提示
write(64010, Res) ->
	Data = <<Res:8>>,
    {ok, pt:pack(64010, Data)};

%%% 获取南天门房间信息
write(64011, Bin) ->
	Data = Bin,
    {ok, pt:pack(64011, Data)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.


