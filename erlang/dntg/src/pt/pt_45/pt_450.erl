%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-22
%% Description: vip功能
%% --------------------------------------------------------
-module(pt_450).
-export([read/2, write/2]).


%%VIP任务传送
read(45001, <<TransportType:8, Id:32, Scene:32, X:16, Y:16>>) ->
    {ok, [TransportType,Id, Scene, X, Y]};

%%VIP场景传送
read(45002, <<SceneId:16>>) ->
    {ok, [SceneId]};

%%VIP信息
read(45003, _) ->
    {ok, [no]};

%% 检测vip是否到期
read(45006, _) ->
    {ok, [no]};

%% 福利面板
read(45007, _) ->
    {ok, [no]};

%% 领取福利
read(45008, <<Type:8>>) ->
    {ok, [Type]};

%% 购买vip升级卡(卡为绑定)
read(45009, _) ->
    {ok, [no]};

%% 祝福冻结
read(45011, _) ->
    {ok, [no]};

%% 祝福解冻
read(45010, _) ->
    {ok, [no]};

%% 进入VIP挂机场景
read(45012, _) ->
    {ok, [no]};

%% 退出VIP挂机场景
read(45013, _) ->
    {ok, [no]};

%% 今天是否可领开服7天礼包
read(45014, _) ->
    {ok, [no]};

%% 领取开服7天礼包
read(45015, _) ->
    {ok, [no]};

%% 查询VIP信息(新)
read(45016, _) ->
    {ok, [no]};

%% 立即开通VIP
read(45017, <<Type:8>>) ->
    {ok, [Type]};

%% 查询VIP福利领取信息
read(45018, _) ->
    {ok, [no]};

%% 领取VIP周礼包
read(45019, _) ->
    {ok, [no]};

%% 领取每日福利
read(45020, _) ->
    {ok, [no]};

%% 为好友开通VIP
read(45021, <<Type:8, Bin/binary>>) ->
    {NickName, _Bin1} = pt:read_string(Bin),
    {ok, [Type, NickName]};

%% 获取VIP摇奖信息
read(45022, _) ->
    {ok, [no]};

%% 摇奖
read(45023, _) ->
    {ok, [no]};

%% 清空摇奖
read(45024, _) ->
    {ok, [no]};

%% VIP续费
read(45050, <<Time:8, AutoBuy:8>>) ->
	{ok, [Time, AutoBuy]};

%% 一键全摇奖
read(45051, _) ->
	{ok, []};

%%  VIP升级
read(45052, _) ->
	{ok, []};

%%  VIP升级信息
read(45053, _) ->
	{ok, []};

%%  查看首冲礼包领取情况
read(45062, _) ->
    {ok, []};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%% VIP任务传送
write(45001, [Error, LeftTimes]) ->
    {ok, pt:pack(45001, <<Error:8, LeftTimes:8>>)};

%%VIP场景传送
write(45002, [Error]) ->
    {ok, pt:pack(45002, <<Error:8>>)};

%%VIP信息
write(45003, [LeftTime]) ->
    {ok, pt:pack(45003, <<LeftTime:32>>)};

%% 福利面板
write(45007, [F1, F2, F3, F4, Time, Time1]) ->
    {ok, pt:pack(45007, <<F1:8, F2:8, F3:8, F4:8, Time:32, Time1:32>>)};

%% 领取福利
write(45008, [Err]) ->
    {ok, pt:pack(45008, <<Err:8>>)};

%% 领取福利
write(45009, [Err]) ->
    {ok, pt:pack(45009, <<Err:8>>)};

%% 祝福冻结
write(45011, [Err]) ->
    {ok, pt:pack(45011, <<Err:8>>)};

%% 祝福解冻
write(45010, [Time]) ->
    {ok, pt:pack(45010, <<Time:32>>)};

%% 进入VIP挂机场景
write(45012, [Err]) ->
    {ok, pt:pack(45012, <<Err:8>>)};

%% 退出VIP挂机场景
write(45013, [Err]) ->
    {ok, pt:pack(45013, <<Err:8>>)};

%% 今天是否可领开服7天礼包
write(45014, [Err]) ->
    {ok, pt:pack(45014, <<Err:8>>)};

%% 领取开服7天礼包
write(45015, [Err]) ->
    {ok, pt:pack(45015, <<Err:8>>)};

%% 查询VIP信息(新)
write(45016, [GrowthExp, NextExp, GrowthLv, RestTime, DailyAdd]) ->
    {ok, pt:pack(45016, <<GrowthExp:32, NextExp:32, GrowthLv:8, RestTime:32, DailyAdd:8>>)};

%% 立即开通VIP
write(45017, [Res, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(45017, <<Res:8, Str1/binary>>)};

%% 查询VIP福利领取信息
write(45018, [NowList, NextList, WeekState, DailyState, Time, NextWeekDay]) ->
    Data = pack1(NowList, NextList, WeekState, DailyState, Time, NextWeekDay),
    {ok, pt:pack(45018, Data)};

%% 领取VIP周礼包
write(45019, [Err, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(45019, <<Err:8, Str1/binary>>)};

%% 查询VIP福利领取信息
write(45020, [Err, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(45020, <<Err:8, Str1/binary>>)};

%% 为好友开通VIP
write(45021, [Err, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(45021, <<Err:8, Str1/binary>>)};

%% 获取VIP摇奖信息
write(45022, [List1, List2, NeedGold, RestNum]) ->
    Data = pack2(List1, List2, NeedGold, RestNum),
    {ok, pt:pack(45022, Data)};

%% 摇奖
write(45023, [Err, Str, GoodsId, GoodsNum]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(45023, <<Err:8, Str1/binary, GoodsId:32, GoodsNum:32>>)};

%% 清空摇奖
write(45024, [Err, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(45024, <<Err:8, Str1/binary>>)};

%% VIP续费
write(45050, [Err, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(45050, <<Err:8, Str1/binary>>)};

%% 一键全摇奖
write(45051, [Err, Str, GoodsList]) ->
    Str1 = pt:write_string(Str),
    Fun1 = fun(Elem1) ->
            {GoodsId, GoodsNum} = Elem1,
            <<GoodsId:32, GoodsNum:32>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- GoodsList]),
    Size1  = length(GoodsList),
    {ok, pt:pack(45051, <<Err:8, Str1/binary, Size1:16, BinList1/binary>>)};

%% VIP升级
write(45052, [Err, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(45052, <<Err:8, Str1/binary>>)};

%% VIP升级信息
write(45053, [Int1, Int2, Int3, Int4, Int5, Int6]) ->
    {ok, pt:pack(45053, <<Int1:32, Int2:32, Int3:32, Int4:32, Int5:32, Int6:32>>)};

%% 查看首冲礼包领取情况
write(45062, [ZhouKa, YueKa, BanNianKa]) ->
    {ok, pt:pack(45062, <<ZhouKa:8, YueKa:8, BanNianKa:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

pack1(NowList, NextList, WeekState, DailyState, Time, NextWeekDay) ->
    Fun1 = fun(Elem1) ->
            <<Elem1:32>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- NowList]),
    Size1  = length(NowList),
    BinList2 = list_to_binary([Fun1(X) || X <- NextList]),
    Size2  = length(NextList),
    NextWeekDay1 = pt:write_string(NextWeekDay),
    <<Size1:16, BinList1/binary, Size2:16, BinList2/binary, WeekState:8, DailyState:8, Time:32, NextWeekDay1/binary>>.

pack2(List1, List2, NeedGold, RestNum) ->
    Fun1 = fun(Elem1) ->
            {GoodsId, GoodsNum, _GoodsPro, GoodsType} = Elem1,
            <<GoodsId:32, GoodsType:8, GoodsNum:32>>
    end,
    %Fun2 = fun(Elem1) ->
    %        {GoodsId, _GoodsNum, _GoodsPro, _GoodsType} = Elem1,
    %        <<GoodsId:32>>
    %end,
    BinList1 = list_to_binary([Fun1(X) || X <- List1]),
    Size1  = length(List1),
    BinList2 = list_to_binary([Fun1(X) || X <- List2]),
    Size2  = length(List2),
    <<Size1:16, BinList1/binary, Size2:16, BinList2/binary, NeedGold:8, RestNum:8>>.
