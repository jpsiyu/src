%%%------------------------------------------------
%%% @Module  : pt_612
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.8.7
%%% @Description: 九重天副本11、21、31层的神秘商店
%%%------------------------------------

-module(pt_612).
-export([read/2, write/2]).


%% 获取神秘商店物品信息
read(61200, _) ->
    {ok, []};
    
%% 购买物品
read(61201, <<GoodsId:32, GoodsNum:16>>) ->
    {ok, [GoodsId, GoodsNum]};
    
read(_Cmd, _R) ->
    {error, no_match}.


%% 获取神秘商店物品信息
write(61200, Bin) ->
    Data = Bin,
    {ok, pt:pack(61200, Data)};
        
%% 购买物品
write(61201, [Error, GoodsId, Num]) ->
    {ok, pt:pack(61201, <<Error:8, GoodsId:32, Num:16>>)};
    
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.


