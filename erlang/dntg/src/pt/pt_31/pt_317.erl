%% --------------------------------------------------------
%% @Module:           |pt_317
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-05
%% @Description:      |特殊活动
%% --------------------------------------------------------
-module(pt_317).
-export([read/2, write/2]).
-include("unite.hrl").
-include("scene.hrl").

%% 老玩家招募 :　查询活动基本信息
read(31700, _) ->
    {ok, 31700};

%% 老玩家招募 :　自己邀请方(显示可以邀请别人的界面)
read(31701, _) ->
    {ok, 31701};

%% 老玩家招募 :　老玩家方(显示回归任务的界面) 
read(31702, _) ->
    {ok, 31702};

%% 老玩家招募 :　感激一名邀请人
read(31703, <<Bin/binary>>) ->
    {Name, _} = pt:read_string(Bin),
    {ok, [Name]};

%% 老玩家招募 :　领取礼包(检查背包)
read(31704,  <<Type:8, Num:8>>) ->
    {ok, [Type, Num]};

%% 错误
read(_Cmd, _R) ->
    {error, no_match}.


%% 老玩家招募 :　查询活动基本信息
write(31700, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(31700, Data)};

%% 老玩家招募 :　自己邀请方(显示可以邀请别人的界面)
write(31701, [Res, GiftId, RoleNum, GiftGotNum, TimeLeft]) ->
    Data = <<Res:8, GiftId:32, RoleNum:16, GiftGotNum:16, TimeLeft:32>>,
    {ok, pt:pack(31701, Data)};

%% 老玩家招募 :　老玩家方(显示回归任务的界面) 
write(31702, [Res, Name, TaskArray, TimeLeft]) ->
    Bin = pack_31702(TaskArray),
	BinName = pt:write_string(Name),
    Data = <<Res:8, BinName/binary, Bin/binary, TimeLeft:32>>,
    {ok, pt:pack(31702, Data)};

%% 老玩家招募 :　感激一名邀请人
write(31703, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(31703, Data)};

%% 老玩家招募 :　领取礼包(检查背包)
write(31704, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(31704, Data)};
    
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.


%% -----------------------------------------------------------------
%% 打包31702
%% -----------------------------------------------------------------
pack_31702([]) ->
    <<0:16, <<>>/binary>>;
pack_31702(List) ->
    Rlen = length(List),
    F = fun({CNum, TaskNeedNum, TaskNowNum, GiftId}) ->
        <<CNum:16, TaskNeedNum:32, TaskNowNum:32, GiftId:32>>
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.