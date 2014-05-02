%%%--------------------------------------
%%% @Module  : pt_319
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2013.3.11
%%% @Description: 斗战封神活动
%%%--------------------------------------

-module(pt_319).
-export([read/2, write/2]).

%% 打开界面
read(31901,  _) ->
    {ok, []};

%% 打开前100名排行
read(31902,  _) ->
    {ok, []};

%% 领取奖励
read(31910,  <<GiftId:32>>) ->
    {ok, GiftId};

%% 错误
read(_Cmd, _R) ->
    {error, no_match}.


%% 打开界面
write(31901, [MyRankNo, Top10List, GiftList]) ->
	Top10Bin = list_to_binary(Top10List),
	Top10Len = length(Top10List),
	GiftListLen = length(GiftList), 
	GiftListBin = list_to_binary(GiftList),
    Data = <<MyRankNo:32, GiftListLen:16, GiftListBin/binary, Top10Len:16, Top10Bin/binary>>,
    {ok, pt:pack(31901, Data)};

%% 打开前100名排行
write(31902, List) ->
	NewList = 
	[begin
		PlatformName = pt:write_string(Platform),
		NickName = pt:write_string(Name),
		<<PlatformName/binary, ServerId:16, Id:32, NickName/binary, Career:8, Realm:8, Sex:8, Power:32>> 
	end || [Platform, ServerId, Id, Name, Realm, Career, Sex, _Lv, Power] <- List],
	Len = length(List), 
	Bin = list_to_binary(NewList),
    Data = <<Len:16, Bin/binary>>,
    {ok, pt:pack(31902, Data)};

%% 领取奖励
write(31910, [GiftId, Error]) ->
    Data = <<GiftId:32, Error:16>>,
    {ok, pt:pack(31910, Data)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
