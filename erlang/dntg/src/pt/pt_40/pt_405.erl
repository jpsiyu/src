%%%------------------------------------
%%% @Module  : pt_405
%%% @Author  : hekai
%%% @Description: 
%%%------------------------------------

-module(pt_405).
-export([read/2, write/2]).

%% 设置帮派活动开启时间
read(40501,<<Week:8, Time:8>>) ->
	{ok, [Week, Time]};	

%% 进入副本
read(40503,_) ->
	{ok, done};	

%% 退出副本
read(40504,_) ->
	{ok, done};	

% ---------关卡3:死亡测试 read-------- %
%% 怪物列表
read(40505,_) ->
	{ok, done};	

%% 答题
read(40507,<<Num:8>>) ->
	{ok, [Num]};	

%% 退出副本
read(40508,_) ->
	{ok, done};	

% ---------关卡1:尖刺陷阱 read-------- %
%% 关卡一信息
read(40511,_) ->
	{ok, done};	

%% 尸体列表
read(40512,_) ->
	{ok, done};	

%% 关卡一提交完成
read(40513,_) ->
	{ok, done};	

%% 是否中陷阱
read(40514, <<X:16, Y:16>>) ->
	{ok, [X,Y]};	

%% 副本是否正在开启
read(40519,_) ->
	{ok, done};	

%% 查询副本设置状态与时间
read(40520,_) ->
	{ok, done};	
% ---------关卡2:死亡之路 read-------- %

%% 关卡二信息
read(40516,_) ->
	{ok, done};	

%% 关卡二提交完成
read(40517,_) ->
	{ok, done};	

read(_Cmd, _R) ->
    {error, no_match}.

%% 设置帮派活动开启时间
write(40501, [Res]) ->
	{ok, pt:pack(40501, <<Res:8>>)};

%% 提示玩家进入场景
write(40502, [TipType, Week, Time]) ->
	{ok, pt:pack(40502, <<TipType:8, Week:8, Time:8>>)};

%% 进入副本
write(40503, [Res, SceneId]) ->
	{ok, pt:pack(40503, <<Res:8, SceneId:16>>)};

%% 退出副本
write(40504, [Res]) ->
	{ok, pt:pack(40504, <<Res:8>>)};

% ---------关卡3:死亡测试 write-------- %
%% 怪物列表
write(40505, [AnimalList]) ->
	Len = length(AnimalList),
	List = [<<Animal:8,Color:8>> ||[Animal,Color]<-AnimalList],
	Bin = list_to_binary(List),
	{ok, pt:pack(40505, <<Len:16, Bin/binary>>)};

%% 测试题目
write(40506, [Type, Color, Animal]) ->
	{ok, pt:pack(40506, <<Type:8, Color:8, Animal:8>>)};

%% 答题
write(40507, [Res]) ->
	{ok, pt:pack(40507, <<Res:8>>)};

%% 关卡三信息
write(40508, [LeftTime, ActiveNum, LiveNum, CorrectNum]) ->
	{ok, pt:pack(40508, <<LeftTime:32, ActiveNum:16, LiveNum:16,CorrectNum:8>>)};

%% 倒计时
write(40509, [CountDownTime]) ->
	{ok, pt:pack(40509, <<CountDownTime:32>>)};

%% 通关奖励
write(40510, [Dun, IsPass, Llpt, Caifu]) ->
	{ok, pt:pack(40510, <<Dun:8, IsPass:8, Llpt:32, Caifu:32>>)};

% ---------关卡1:尖刺陷阱 write-------- %

%% 关卡一信息
write(40511, [LeftTime, ActiveNum, LiveNum, TrapNum, TrapMax]) ->
	{ok, pt:pack(40511, <<LeftTime:32, ActiveNum:16, LiveNum:16,TrapNum:8, TrapMax:8>>)};

%% 尸体列表
write(40512, [DieList]) ->
	Len = length(DieList),
	F = fun({_PlayerId,PlayerName, X, Y}) ->
			BinPlayerName = pt:write_string(PlayerName),
			<<BinPlayerName/binary, X:16, Y:16>>
	end,
	LBin = list_to_binary(lists:map(F, DieList)),
	{ok, pt:pack(40512, <<Len:16, LBin/binary>>)};

%% 关卡一提交完成
write(40513, [Res]) ->
	{ok, pt:pack(40513, <<Res:8>>)};

%% 踩中陷阱
write(40514, [Res, X, Y]) ->
	{ok, pt:pack(40514, <<Res:8, X:16, Y:16>>)};

% ---------关卡二:死亡之路 read-------- %
%% 关卡二信息
write(40516, [LeftTime, ActiveNum, LiveNum]) ->
	{ok, pt:pack(40516, <<LeftTime:32, ActiveNum:16, LiveNum:16>>)};

%% 关卡二提交完成
write(40517, [Res]) ->
	{ok, pt:pack(40517, <<Res:8>>)};

%% 关卡一踩中陷阱以及阵亡消息
write(40518, [Type, PlayerName]) ->
	BinPlayerName = pt:write_string(PlayerName),
	{ok, pt:pack(40518, <<Type:8, BinPlayerName/binary>>)};

%% 副本是否正在开启
write(40519, [Res]) ->
	{ok, pt:pack(40519, <<Res:8>>)};

%% 查询副本设置状态与时间
write(40520, [Status, Week, Time]) ->
	{ok, pt:pack(40520, <<Status:8, Week:8, Time:8>>)};
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
