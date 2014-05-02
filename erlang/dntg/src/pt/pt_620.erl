%%%-------------------------------------------------------------------
%%% @Module	: pt_620
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	:  5 Jun 2012
%%% @Description: 转盘协议
%%%-------------------------------------------------------------------
-module(pt_620).
-export([read/2, write/2]).
%%
%% 客户端 -> 服务端 ----------------------------
%%

%% 获取剩余次数
read(62000, _) ->
    {ok, get_free};

%% 请求转盘开始
read(62002, _) ->
    {ok, request_play};
%% 请求累积铜币
read(62003, _) ->
    {ok, get_acccoin};
read(62005, _) ->
    {ok, money_rain};
read(62006, _) ->
    {ok, remain_time};
read(_, _) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ----------------------------
%%

%% 免费次数
write(62000, [ErrorCode, FreeCnt, ItemIDList]) ->
    ListLen = length(ItemIDList),
    List = [<<ItemID:32>>||ItemID <- ItemIDList],
    Bin = list_to_binary(List),
    Data = <<ErrorCode:8, FreeCnt:8, ListLen:16, Bin/binary>>,
    {ok, pt:pack(62000, Data)};

%% 获取物品
write(62001, [PlayerID, NickName, ItemID, Coin]) ->
    NameLen = byte_size(NickName),
    Data = <<PlayerID:32, NameLen:16, NickName/binary, ItemID:32, Coin:32>>,
    {ok, pt:pack(62001, Data)};

%% 寻找唐僧请求
write(62002, [CanGet, ItemID]) ->
    Data = <<CanGet:8, ItemID:32>>,
    {ok, pt:pack(62002, Data)};

%% 累积铜币
write(62003, [LastCoin]) ->
    Data = <<LastCoin:32>>,
    {ok, pt:pack(62003, Data)};

%% 广播活动开始和结束
write(62004, [Code, RemainTime]) ->
    Data = <<Code:8, RemainTime:32>>,
    {ok, pt:pack(62004, Data)};

%% 触发钱雨效果
write(62005, []) ->
    Data = <<>>,
    {ok, pt:pack(62005, Data)};

%% %% 活动倒计时
%% write(62006, [RemainTime]) ->
%%     Data = <<RemainTime:32>>,
%%     {ok, pt:pack(62006, Data)};

%%唐僧大奖得主
write(62010, [IsWin, Winner, WinnerName, UltimateCoin]) ->
    NameLen = byte_size(WinnerName),
    Data = <<IsWin:8, Winner:32, NameLen:16, WinnerName/binary, UltimateCoin:32>>,
    {ok, pt:pack(62010, Data)};
    
write(_, _) ->
    {ok, pt:pack(0, <<>>)}.
