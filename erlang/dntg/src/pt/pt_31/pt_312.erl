%% ---------------------------------------------------------
%% Author:  HHL
%% Email:   
%% Created: 2014-3-7
%% Description: TODO:
%% --------------------------------------------------------
-module(pt_312).
-export([read/2, write/2]).


%% 查询可领取连续登录奖励
read(31200, _R) ->
    {ok, query_gift};

%% 领取连续登录奖励
%% int: 8 类型（0未充值连续登录/1已充值连续登录/2未登录）
%% int: 8 天数
read(31201, <<Type:8, Days:8>>) ->
    {ok, [Type, Days]};

%% 重置连续登录天数
read(31202, _R) ->
    {ok, reset_days};

%% 每日福利列表
read(31204, _R) ->
    {ok, no};


%% 累积登录信息
read(31205, _R) ->
    {ok, no};

%% 累积签到
read(31206, <<Type:8, Day:8, SignCount:8>>) ->
    {ok, [Type, Day, SignCount]};

%% 点击领取签到物品
read(31207, <<SignCount:8, GoodId:32, IsVip:8>>) ->
    {ok, [SignCount, GoodId, IsVip]};

%% 翻牌信息
read(31208, _R) ->
    {ok, []};

%% 翻牌操作
read(31209, _R) ->
    {ok, []};

%% 默认配对
read(Cmd, _R) ->
    util:errlog("pt_312 read Cmd = ~p error:~p~n", [Cmd, _R]),
    {ok, pt:pack(0, <<>>)}.


%%  查询可领取连续登录奖励
%%  int: 8 结果（0失败/1成功）
%%  int: 8 当前连续登录天数
%%  int: 8 此前未登录天数
%%  int: 8 是否已充值（0否/1是）
write(31200, [Result, ContinuousDays, NoLoginDays, IsCharged, ContinuousGiftInfo, NoLoginGiftInfo]) ->
    Bin1 = pack_gift_info(ContinuousGiftInfo),
    Bin2 = pack_gift_info(NoLoginGiftInfo),
    {ok, pt:pack(31200, <<Result:8, ContinuousDays:8, NoLoginDays:8, IsCharged:8, Bin1/binary, Bin2/binary>>)};

%% 领取连续登录奖励
write(31201, [Type, Days, Result]) ->
    {ok, pt:pack(31201, <<Type:8, Days:8, Result:8>>)};

%% 重置连续登录天数
write(31202, Result) ->
    {ok, pt:pack(31202, <<Result:8>>)};

%% 通知客户端充值状态变更
%% NewStatus:   int: 8 充值状态（0未充值/1已充值）
write(31203, NewState) ->
    {ok, pt:pack(31203, <<NewState:8>>)};


%% 每日福利列表
write(31204, [List]) ->
    Bin = pack(List),
    {ok, pt:pack(31204, Bin)};

%% 累积登录信息
write(31205, List) ->
    [VipType, SignCount, LessSignAddCount, LoginCount, DropCountLess, Mouth, SignDayList, SignGoodList] = List,
    {DaysLen, DayBin} = pack_signdays_info(SignDayList),
    {GoodLen, GoodBin} = pack_signgood_info(SignGoodList),
    Bin = <<VipType:8, SignCount:8, LessSignAddCount:8, LoginCount:8, DropCountLess:8, Mouth:8, DaysLen:16, DayBin/binary, GoodLen:16, GoodBin/binary>>,
    {ok, pt:pack(31205, Bin, 1)};

%% 签到结果
write(31206, [Code]) ->
    {ok, pt:pack(31206, <<Code:8>>)};

%% 签到物品领取
write(31207, List) ->
    [Code, SignGoodList] = List,
    {SignCount, GoodLen, GoodBin} = pack_sign_count_good(SignGoodList),
    Bin = <<Code:8, SignCount:8, GoodLen:16, GoodBin/binary>>,
    {ok, pt:pack(31207, Bin, 1)};

%%　翻牌信息
write(31208, [DropCountLess, _DropGoods]) ->
    DLen = length(_DropGoods),
    DropGoods = list_to_binary([<<GoodsTypeId:32, Num:8>> || {{GoodsTypeId, Num}, _Ratio} <- _DropGoods]),
    Data = <<DropCountLess:8, DLen:16,DropGoods/binary>>,
    {ok, pt:pack(31208, Data)};

%%　翻牌操作
write(31209, [Code, GoodId, Num]) ->
    {ok, pt:pack(31209, <<Code:8, GoodId:32, Num:8>>)};

%% 默认配对
write(Cmd, _Bin) ->
    util:errlog("pt_312 write Cmd = ~p error~n", [Cmd]),
    {ok, pt:pack(0, <<>>)}.


%% 连续登录 或 未登录 奖励信息打包
pack_gift_info([]) ->
    <<0:16, <<>>/binary>>;
pack_gift_info(GiftInfo) ->
    Len = length(GiftInfo),
    F = fun({IsCharged, Days, Times}) ->
                <<IsCharged:8, Days:8, Times:8>>
        end,
    Bin = list_to_binary(lists:map(F, GiftInfo)),
    <<Len:16, Bin/binary>>.


%%　每日福利
pack(List) ->
    Fun1 = fun(Elem1) ->
            {Err, Num, Total} = Elem1,
            <<Err:8, Num:8, Total:8>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List]),
    Size1  = length(List),
    <<Size1:16, BinList1/binary>>.


%% 签到的日子
pack_signdays_info(SignDayList) ->
    Len = length(SignDayList),
    F = fun({Day, IsSign})->
                <<Day:8, IsSign:8>>
        end,
    Bin = list_to_binary(lists:map(F, SignDayList)),
    {Len, Bin}.


%% 签到物品奖励
pack_signgood_info(SignGoodList) ->
    Len = length(SignGoodList),
    F = fun({Day, GoodList})->
               F1 = fun({GoodId, Num, IsVipGift, IsGet}) -> <<GoodId:32, Num:8, IsVipGift:8, IsGet:8>> end,
               Len1 = length(GoodList),
               Bin = list_to_binary(lists:map(F1, GoodList)),
               <<Day:8, Len1:16, Bin/binary>>
        end,
    Bin = list_to_binary(lists:map(F, SignGoodList)),
    {Len, Bin}.


%% 点击领取物品之后刷新物品
pack_sign_count_good(SignCountGoodList)->
    case SignCountGoodList of
        [] -> {0, 0, list_to_binary([])};
        _ ->
            [{SignCount, GoodList}] = SignCountGoodList,
            Len = length(GoodList),
            F = fun({GoodId, Num, IsVipGift, IsGet})->
                        <<GoodId:32, Num:8, IsVipGift:8, IsGet:8>>
                end,
            Bin = list_to_binary(lists:map(F, GoodList)),
            {SignCount, Len, Bin}
    end.





