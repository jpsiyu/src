%%------------------------------------------------------------------------------
%% @Module  : pt_611
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.4.25
%% @Description: 宠物副本和经验副本协议定义
%%------------------------------------------------------------------------------

-module(pt_611).
-export([read/2, write/2]).
-include("server.hrl").
-include("scene.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%

%% 宠物副本想法信息
read(61101, _) ->
    {ok, []};
    
%% 宠物副本配置信息
read(61102, _) ->
    {ok, []};

%% 装备副本开启列表
read(61171, _) ->
    {ok, []};

%% 装备副本的抽取操作协议（Type:1,2）
read(61173, <<DunId:32, Type:8>>) ->
     {ok, [DunId, Type]};

%% 副本打多一次
read(61174, _) ->
     {ok, []};
    
read(_Cmd, _R) ->
    util:errlog("~p ~p pp_dungeon_read:_Cmd:~p, _R:~p~n", [?MODULE, ?LINE, _Cmd, _R]),
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%% 宠物副本想法信息
write(61101, [Count, ThinkTime, ThinkList]) ->
    Len = length(ThinkList),
    Fun = fun({MonId, FruitFace}) ->
            <<MonId:32, FruitFace:32>>
    end,
    NewThinkList = list_to_binary([Fun(X) || X <- ThinkList]),
    {ok, pt:pack(61101, <<Count:8, ThinkTime:32, Len:16, NewThinkList/binary>>)};  
        
%% 宠物副本配置信息
write(61102, [Count]) ->
    {ok, pt:pack(61102, <<Count:8>>)};

%% 宠物副本关闭想法界面.
write(61103, []) ->
    {ok, pt:pack(61103, <<>>)};

%% 生成怪物.
%% 1刷小怪，2刷BOSS.
write(61104, MonType) ->
    {ok, pt:pack(61104, <<MonType:8>>)};  

%% 装备副本开启列表 
write(61171, [EnergyDunList])->
    Len = length(EnergyDunList),
    Bin = list_to_binary(EnergyDunList),
    {ok, pt:pack(61171, <<Len:16, Bin/binary>>)};


%% 装备副本通关返回 
write(61172, List)->
    [Code, DunId, BestTime, UsedTime, Level, KillCount, Exp, ExtractCount, RotaryGiftList, IsFirstPass, Gold] = List,
    Len = length(RotaryGiftList),
    Bin = list_to_binary(RotaryGiftList),
    {ok, pt:pack(61172, <<Code:8, DunId:32, BestTime:32, UsedTime:32, Level:8, KillCount:8, Exp:32, ExtractCount:8, Len:16, Bin/binary, IsFirstPass:8, Gold:8>>, 1)};


%% 装备副本抽奖 
write(61173, [Result, GoodsList, TotalCoin, TotalBGold])->
    Len = length(GoodsList),
    Bin = list_to_binary(GoodsList),
    {ok, pt:pack(61173, <<Result:8, Len:16, Bin/binary, TotalCoin:32, TotalBGold:16>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

