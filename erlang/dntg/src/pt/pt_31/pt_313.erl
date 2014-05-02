%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-25
%% Description: TODO:
%% --------------------------------------------------------
-module(pt_313).
-export([read/2, write/2]).

%% 取玩家的活动信息
read(31301, <<ActivityId:32>>) ->
    {ok, ActivityId};

%% 玩家活动奖励领取
read(31302, <<ActivityId:32>>) ->
    {ok, ActivityId};

%% 默认配对
read(Cmd, _R) ->
    util:errlog("pt_313 read Cmd = ~p error~n", [Cmd]),
    {ok, pt:pack(0, <<>>)}.

%% 取玩家的活动信息
%%  Res  0 => 失败
%%       1 => 成功
%%       2 => 没有活动信息
%%  ActivityId int:32 活动ID
%%  CurrentCount int:32 当前统计数
%%  TotalCount int:32 总统计数
write(31301, [Res, ActivityId, CurrentCount, TotalCount, GoodsList]) ->
    ListNum = length(GoodsList),
    F = fun({TypeId, GoodsNum}) ->
                <<TypeId:32, GoodsNum:16>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(31301, <<Res:16, ActivityId:32, CurrentCount:32, TotalCount:32, ListNum:16, ListBin/binary>>)};
    
%% 玩家活动奖励领取
write(31302, [Res, ActivityId, GoodsList]) ->
    ListNum = length(GoodsList),
    F = fun({TypeId, GoodsNum}) ->
            <<TypeId:32, GoodsNum:16>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(31302, <<Res:16, ActivityId:32, ListNum:16, ListBin/binary>>)};

%% 默认配对
write(Cmd, _Bin) ->
    util:errlog("pt_313 write Cmd = ~p error~n", [Cmd]),
    {ok, pt:pack(0, <<>>)}.


