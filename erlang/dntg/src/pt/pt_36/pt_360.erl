%%%--------------------------------------
%%% @Module  : pt_360
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.6.19
%%% @Description: 礼包相关
%%%--------------------------------------

-module(pt_360).
-export([read/2, write/2]).

%%
%% 客户端 -> 服务端 ----------------------------
%%

%% 获取已经获取的等级礼包列表
read(36001, _) ->
    {ok, get_list};

%% [在线倒计时礼包] 查询在线倒计时礼包数据
read(36002, _) ->
    {ok, get_data};

%% [在线倒计时礼包] 获取在线倒计时礼包奖励
read(36003, _) ->
    {ok, get_award};

%% [新服充值礼包] 打开面板请求需要的数据
read(36006, _) ->
    {ok, get_data};

%% [新服充值礼包] 领取礼包
read(36007, <<GiftId:32>>) ->
    {ok, GiftId};


read(36008, _R) ->
    {ok, []};

read(36009, <<Id:8>>) ->
    {ok, [Id]};

read(_, _) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ----------------------------
%%

%% 获取已经获取的等级礼包列表
write(36001, List) ->
	Len = length(List),
	Bin = list_to_binary(List),
    Data = <<Len:16, Bin/binary>>,
    {ok, pt:pack(36001, Data)};

%% [在线倒计时礼包] 查询在线倒计时礼包数据
write(36002, [GiftId, NeedTime, Type, Num]) ->
    Data = <<GiftId:32, NeedTime:32, Type:8, Num:16>>,
    {ok, pt:pack(36002, Data)};

%% [在线倒计时礼包] 获取在线倒计时礼包奖励
write(36003, [Result, GiftId, Needtime, Type, Num]) ->
    Data = <<Result:16, GiftId:32, Needtime:32, Type:8, Num:16>>,
    {ok, pt:pack(36003, Data)};

%% [新服充值礼包] 打开面板请求需要的数据
write(36006, [Total, Time, List]) ->
	Len = length(List),
	Bin = list_to_binary(List),
    Data = <<Total:32, Time:32, Len:16, Bin/binary>>,
    {ok, pt:pack(36006, Data)};

%% [新服充值礼包] 领取礼包
write(36007, [Result, GiftId, Needtime]) ->
    Data = <<Result:8, GiftId:32, Needtime:32>>,
    {ok, pt:pack(36007, Data)};


%% 大闹天空:在线礼包列表获取
write(36008, [Result, OnlineTime, GiftList]) ->
    {Len, Bin} = pack_gift_list_bin(GiftList),
    BinData = <<Result:8, OnlineTime:32, Len:16, Bin/binary>>,
    {ok, pt:pack(36008, BinData, 1)};


write(36009, [Result, TypeId, IsGet]) ->
    BinData = <<Result:8, TypeId:8, IsGet:8>>,
    {ok, pt:pack(36009, BinData)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.


pack_gift_list_bin(GiftList)->
    Len = length(GiftList),
    List = lists:map(fun({Id, [{Type, GoodId, Num}], TimeSpan, IsGet})->
                             <<Id:8, Type:8, GoodId:32, Num:8, TimeSpan:32, IsGet:8>>
                     end, GiftList),
    {Len, list_to_binary(List)}.



