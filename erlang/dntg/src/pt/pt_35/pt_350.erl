%%%--------------------------------------
%%% @Module  : pt_350
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.9
%%% @Description: 成就
%%%--------------------------------------

-module(pt_350).
-export([read/2, write/2]).

%%
%% 客户端 -> 服务端 ----------------------------
%%

%% 打开成就面板
read(35011, _) ->
    {ok, get_info};

%% 领取大类成长等级奖励
read(35012, <<AchieveType:8>>) ->
    {ok, AchieveType};

%% 领取成就奖励
read(35021, <<AchieveId:32>>) ->
    {ok, AchieveId};

%% 成就对比
read(35022, <<PlayerId:32>>) ->
    {ok, PlayerId};

%% 成就客户端触发通知
%% read(35010, <<Cj_id:32>>) ->
%%     {ok, Cj_id};

read(_Cmd, _R) ->
    util:errlog("read ~p nomatch~n", [_Cmd]),
   	{error, no_match}.

%%
%% 服务端 -> 客户端 ------------------------------------
%%

%% 打开成就面板
write(35011, BinData) ->
    {ok, pt:pack(35011, BinData)};

%% 领取大类成长等级奖励
write(35012, ErrorCode) ->
	Bin = <<ErrorCode:16>>,
    {ok, pt:pack(35012, Bin)};

%% 成就达成通知
write(35001, [AchieveId, Score]) ->
    {ok, pt:pack(35001, <<AchieveId:32, Score:32>>)};

%% 成就统计数字通知
write(35002, [AchieveId, Count]) ->
    {ok, pt:pack(35002, <<AchieveId:32, Count:32>>)};

%% 领取成就奖励
write(35021, [ErrorCode, Score, MaxLevel, AchieveType, AchieveTypeScore]) ->
    {ok, pt:pack(35021, <<ErrorCode:8, Score:32, MaxLevel:8, AchieveType:8, AchieveTypeScore:16>>)};

%% 成就对比
write(35022, [ErrorCode, Score, StatList]) ->
	Length = length(StatList),
	Bin = list_to_binary(StatList),
    {ok, pt:pack(35022, <<ErrorCode:8, Score:32, Length:16, Bin/binary>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
