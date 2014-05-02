%%%--------------------------------------
%%% @Module  : pt_341
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.2
%%% @Description: 目标
%%%--------------------------------------

-module(pt_341).
-export([read/2, write/2]).

%%
%% 客户端 -> 服务端 ----------------------------
%%

%% 获得目标列表
read(34101, _) ->
    {ok, get_info};

%% 领取奖励
read(34102, <<TargetId:32>>) ->
    {ok, TargetId};

%% 领取达到指定等级后弹出来的小窗奖励
read(34106, <<GiftId:32>>) ->
    {ok, GiftId};

read(_, _) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ------------------------------------
%%

%% 获得目标列表
write(34101, [GroupList, RoleTargetList]) ->
	Len1 = length(GroupList),
	Len2 = length(RoleTargetList),
    Bin1 = list_to_binary(GroupList),
	Bin2 = list_to_binary(RoleTargetList),
	Data = <<Len1:16, Bin1/binary, Len2:16, Bin2/binary>>,
    {ok, pt:pack(34101, Data)};

%% 领取奖励
write(34102, [TargetId, GiftId, ErrorCode]) ->
	Data = <<TargetId:32, GiftId:32, ErrorCode:16>>,
    {ok, pt:pack(34102, Data)};

%% 领取达到指定等级后弹出来的小窗奖励
write(34106, [GiftId, ErrorCode]) ->
	Data = <<GiftId:32, ErrorCode:16>>,
    {ok, pt:pack(34106, Data)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.
