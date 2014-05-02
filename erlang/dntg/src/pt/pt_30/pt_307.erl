%%%-----------------------------------
%%% @Module  : pt_307
%%% @Author  : hekai
%%% @Created : 2012.07.31
%%% @Description: 30 任务信息
%%%-----------------------------------
-module(pt_307).
-include("record.hrl").
-include("task.hrl").
-export([read/2, write/2]).

%% 发布列表
read(30700, _) ->
	{ok, done};

%% 诛妖榜列表
read(30701, _) ->
	{ok, done};

%% 发布诛妖令
read(30702, <<Type:8>>) ->
	{ok, [Type]};

%% 领取诛妖令
read(30703, <<Type:8>>) ->
	{ok, [Type]};

read(_Cmd, _R) ->
    {error, no_match}.

%% 发布列表
write(30700, [Reward, Zyl_num, LeftPubDaily]) ->
	RLen = length(Reward),    
    ZLen = length(Zyl_num),
 
	F1 = fun([Type, Coin, Exp]) ->
			<<Type:8, Coin:32, Exp:32>>
		 end,
	RBin = list_to_binary(lists:map(F1, Reward)),
    
	F2 = fun([Type, Zyl_now, Zyl_publish, Zyl_bget]) ->			
			<<Type:8, Zyl_now:16, Zyl_publish:16, Zyl_bget:16>>
		 end,
	ZBin = list_to_binary(lists:map(F2, Zyl_num)),

    %%RBin = pack_list(Reward),
    %%ZBin = pack_list(Zyl_num),			
    %%Data = <<RBin/binary, ZBin/binary,  LeftPubDaily:16>>,

	Data = <<RLen:16, RBin/binary, ZLen:16,ZBin/binary, LeftPubDaily:16>>,
    {ok, pt:pack(30700, Data)};

%% 诛妖榜列表
write(30701, [Has_num, Get_num, LeftPubDaily]) ->
    HLen = length(Has_num),    
    GLen = length(Get_num),

	F1 = fun([Type, Zyl_Publish_now, Coin, Exp]) ->
			<<Type:8, Zyl_Publish_now:16, Coin:32, Exp:32>>
		 end,
	HBin = list_to_binary(lists:map(F1, Has_num)),
    
	F2 = fun([Type, Zyl_num]) ->			
			<<Type:8, Zyl_num:16>>
		 end,
	GBin = list_to_binary(lists:map(F2, Get_num)),
	
    Data = <<	HLen:16, HBin/binary, GLen:16,GBin/binary, LeftPubDaily:16>>,
    {ok, pt:pack(30701, Data)};

%% 发布诛妖令
write(30702, Result) ->
    {ok, pt:pack(30702, <<Result:16>>)};

%% 领取诛妖令
write(30703, Result) ->
    {ok, pt:pack(30703, <<Result:16>>)};

%% 诛妖令被领取通知
write(30704, [Coin, Exp]) ->
    {ok, pt:pack(30704, <<Coin:32, Exp:32>>)};
  
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

%% -----------私有函数------------
%%pack_list([]) -> <<0:16>>;
%%pack_list(List) ->
%%    Len = length(List),
%%    Bin = list_to_binary([pack_list(X) || X <- List]),
%%    <<Len:16, Bin/binary>>.
