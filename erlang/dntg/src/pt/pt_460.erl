%%%--------------------------------------
%%% @Module  : pt_460
%%% @Author  : zhenghehe
%%% @Created : 2010.10.12
%%% @Description: 
%%%--------------------------------------
-module(pt_460).
-export([read/2, write/2]).

%% 刷新护送NPC颜色
read(46000, <<Type:8, TaskId:32>>) ->
    {ok, [Type, TaskId]};

%% 释放护送技能
read(46001, <<SkillId:16>>) ->
    {ok, [SkillId]};

%% 护送技能同步
read(46002, _) ->
    {ok, no};

%% 被劫镖求救信号
read(46003, _) ->
    {ok, no};

%% 接收求救信号传送
read(46004, <<SceneId:32, X:16, Y:16>>) ->
    {ok, [SceneId, X, Y]};

%% 获得护送奖励
read(46006, _) ->
    {ok, no};

%% 查询护送奖励信息
read(46007, _) ->
    {ok, no};

%% 护送美女任务剩余时间
read(46008, _) ->
    {ok, []};

%% 获取双倍护送剩余时间
read(46010, _) ->
    {ok, []};

read(46011, _) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%% 刷新护送NPC颜色
write(46000, [Result, C]) ->
    {ok, pt:pack(46000, <<Result:16, C:8>>)};

%% 释放护送技能
write(46001, [Result]) ->
    {ok, pt:pack(46001, <<Result:16>>)};

%% 被劫镖求救信号
write(46003, [Result]) ->
    {ok, pt:pack(46003, <<Result:16>>)};

%% 触发护送基础奖励
write(46005, [Exp,Coin,Bcoin]) ->
    {ok, pt:pack(46005, <<Exp:32,Coin:32,Bcoin:32>>)};

%% 获得护送奖励
write(46006, [Mul]) ->
    {ok, pt:pack(46006, <<Mul:8>>)};

%% 查询护送奖励信息
write(46007, [Hp, Rewards]) ->
    F = fun({C,Exp,Coin}) ->
        <<C:8, Exp:32,Coin:32,0:32>>
    end,
    List = lists:map(F, Rewards),
    Len = length(List),
    RewardsBin = list_to_binary(List),
    Data = <<Hp:32, Len:16, RewardsBin/binary>>,
    {ok, pt:pack(46007, Data)};

%% 护送美女任务剩余时间
write(46008, [LelfTime]) ->
    {ok, pt:pack(46008, <<LelfTime:32>>)};

%% 护送美女任务结束
write(46009, [Result, Count]) ->
    {ok, pt:pack(46009, <<Result:16, Count:16>>)};

%% 获取双倍护送剩余时间
write(46010, [LelfTime]) ->
    {ok, pt:pack(46010, <<LelfTime:32>>)};

write(46011, [C]) ->
    {ok, pt:pack(46011, <<C:8>>)};

write(46020, [Type]) ->
    {ok, pt:pack(46020, <<Type:8>>)};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.