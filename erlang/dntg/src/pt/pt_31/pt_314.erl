%%%--------------------------------------
%%% @Module  : pt_314
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.24
%%% @Description: 每日活动列表-礼包
%%%--------------------------------------

-module(pt_314).
-export([read/2, write/2]).

%% 获取每日活动列表面板数据
read(31401, _) ->
    {ok, get_info};

%% 领取首充礼包
read(31402, _) ->
    {ok, fetch_gift};

%% 领取新手礼包
read(31403, <<Key/binary>>) ->
	{NewKey, _} = pt:read_string(Key),
    {ok, NewKey};

%% 获取收藏游戏奖励
read(31404, _) ->
    {ok, get_info};

%% 请求是否获取过收藏游戏的奖励
read(31405, _) ->
    {ok, get_info};

%% [活跃度] 查询面板数据
read(31406, _) ->
    {ok, get_active_info};

%% [活跃度] 领取奖励
read(31407, _) ->
    {ok, get_my_allactive};

%% 通过输入卡号领取奖励
read(31408, <<CardType:16, CardNo/binary>>) ->
	{NewCardNo, _} = pt:read_string(CardNo),
    {ok, [CardType, NewCardNo]};

%% [活跃度] 剩余项数
read(31409, _) ->
    {ok, get_active_left};

%% [升级向前冲] 打开面板需要的数值
read(31410, _) ->
    {ok, get_data};

%% [升级向前冲] 领取奖励
read(31411, _) ->
    {ok, get_award};

%% [首服充值活动] 打开面板
read(31413, _) ->
    {ok, get_data};

%% [首服充值活动] 领取奖励
read(31414, <<GiftId:32>>) ->
    {ok, GiftId};

%% [中秋国庆活动] 查看活跃度数据
read(31417, _) ->
    {ok, get_data};

%% [中秋国庆活动] 领取活跃度礼包
read(31418, <<Type:8>>) ->
    {ok, Type};

%% [充值送礼] 打开面板
read(31420, _) ->
	{ok, get_data};

%% 临时，春节版 [充值送礼] 打开面板
read(31430, _) ->
    {ok, get_data};

%% 临时，春节版 [充值送礼] 领取奖励
read(31431, <<GiftId:32>>) ->
    {ok, GiftId};

%% [充值送礼] 领取奖励
read(31421, <<GiftId:32>>) ->
    {ok, GiftId};

%% 获取活动奖励领取统计
read(31480, <<Num:16, Bin/binary>>) ->
    List = read_id_type_list(Bin, [], Num),
	{ok, List};

%% 获取倍率
read(31482, _) ->
    {ok, []};

%% 查询消费礼包
read(31483, _) ->
    {ok, []};

%% 获取倍率
read(31484, <<No:32>>) ->
    {ok, [No]};

%% [开服7天内每天登录奖励] 打开面板
read(31415, _) ->
    {ok, get_data};

%% [开服7天内每天登录奖励] 领取奖励
read(31416, <<Day:8>>) ->
    {ok, Day};

%% 開服前10天每日領取綁定元寶状态
read(31450, _) ->
    {ok, no};

%% 開服前10天每日領取綁定元寶
read(31451, <<Res:8>>) ->
    {ok, [Res]};

%% [合服] 打开面板需要的数据
read(31485, _) ->
    {ok, get_data};

%% [通用] 领取奖励
read(31486, <<In:32>>) ->
    {ok, In};

%% [合服充值礼包] 打开面板
read(31487, _) ->
    {ok, get_data};

%% [合服充值礼包] 领取奖励
read(31488, <<GiftId:32>>) ->
    {ok, GiftId};

%% 幸福回归
read(31489, _) ->
    {ok, []};

%% 开服充值累计送礼包活动基本信息
read(31490, _) ->
    {ok, 31490};

%% 开服充值累计送礼包活动领取礼包
read(31491, _) ->
    {ok, 31491};

%% 开服充值累计送礼包活动领取礼包(图标)
read(31492, _) ->
    {ok, 31492};

%% 消费返元宝查询
read(31493, _) ->
    {ok, 31493};

%% 领取消费返元宝
read(31494, <<Id:32>>) ->
	{ok, [Id]};

%% 默认配对
read(Cmd, R) ->
    util:errlog("pt_314 read Cmd = ~p error = ~p~n", [Cmd, R]),
    ok.

%% 获取每日活动列表面板数据
write(31401, Data) ->
	Len = length(Data),
	Bin = list_to_binary(Data),
    {ok, pt:pack(31401, <<Len:16, Bin/binary>>)};

%% 领取首充礼包
write(31402, Result) ->
	Bin = <<Result:8>>,
	{ok, pt:pack(31402, Bin)};

%% 领取新手礼包
write(31403, ErrorCode) ->
	Bin = <<ErrorCode:8>>,
	{ok, pt:pack(31403, Bin)};

%% 获取收藏游戏奖励
write(31404, ErrorCode) ->
	Bin = <<ErrorCode:8>>,
	{ok, pt:pack(31404, Bin)};

%% 请求是否获取过收藏游戏的奖励
write(31405, ErrorCode) ->
	Bin = <<ErrorCode:8>>,
    {ok, pt:pack(31405, Bin)};

%% [活跃度] 查询面板数据
write(31406, [Active, _ActiveLimit, OptList, _AwardList]) ->
	Len = length(OptList),
	ListBin = list_to_binary(OptList),
	%Len2 = length(_AwardList),
	%ListBin2 = list_to_binary(_AwardList),
	%%Bin = <<Active:16, _ActiveLimit:16, Len:16, ListBin/binary, Len2:16, ListBin2/binary>>,
    Bin = <<Active:16, Len:16, ListBin/binary>>,
	{ok, pt:pack(31406, Bin)};

%% [活跃度] 领取奖励
write(31407, [AllActive]) ->
	Bin = <<AllActive:16>>,
	{ok, pt:pack(31407, Bin)};

%% 通过输入卡号领取奖励
write(31408, [GiftId, Result]) ->
	Bin = <<GiftId:32, Result:16>>,
	{ok, pt:pack(31408, Bin)};

%% [活跃度] 剩余项数
write(31409, [ActiveLeft]) ->
    Bin = <<ActiveLeft:16>>,
    {ok, pt:pack(31409, Bin)};

%% [升级向前冲] 打开面板需要的数值
write(31410, List) ->
	Len = length(List),
	Data = list_to_binary(List),
	Bin = <<Len:16, Data/binary>>,
	{ok, pt:pack(31410, Bin)};

%% [升级向前冲] 领取奖励
write(31411, [Level, Result]) ->
	Bin = <<Level:8, Result:16>>,
	{ok, pt:pack(31411, Bin)};

%% [首服充值活动] 打开面板
write(31413, [Recharge, List, LeftSecond]) ->
	Len = length(List),
	Data = list_to_binary(List),
	Bin = <<Recharge:32, Len:16, Data/binary, LeftSecond:32>>,
	{ok, pt:pack(31413, Bin)};

%% [首服充值活动] 领取奖励
write(31414, [GiftId, Result]) ->
	Bin = <<GiftId:32, Result:16>>,
	{ok, pt:pack(31414, Bin)};

%% [开服7天内每天登录奖励] 打开面板
write(31415, List) ->
	Len = length(List),
	BinData = list_to_binary(List),
	Bin = <<Len:16, BinData/binary>>,
	{ok, pt:pack(31415, Bin)};

%% [开服7天内每天登录奖励] 领取奖励
write(31416, [GiftId, Result]) ->
	Bin = <<GiftId:32, Result:16>>,
	{ok, pt:pack(31416, Bin)};

%% [中秋国庆活动] 查看活跃度数据
write(31417, List) ->
	Len = length(List),
	BinData = list_to_binary(List),
	Bin = <<Len:16, BinData/binary>>,
	{ok, pt:pack(31417, Bin)};

%% [中秋国庆活动] 领取活跃度礼包
write(31418, [Type, GiftId, ErrorCode]) ->
	Bin = <<Type:8, GiftId:32, ErrorCode:16>>,
	{ok, pt:pack(31418, Bin)};

%% [充值送礼] 打开面板
write(31420, [Recharge, List, LeftSecond, ReGiftId, ReNumNow, TrueReNum, ReYbLimit]) ->
	Len = length(List),
	Data = list_to_binary(List),
	Bin = <<Recharge:32, Len:16, Data/binary, LeftSecond:32, ReGiftId:32, ReNumNow:32, TrueReNum:32, ReYbLimit:32>>,
	{ok, pt:pack(31420, Bin)};

%% 临时，春节版 [充值送礼] 打开面板
write(31430, [Recharge, List, LeftSecond, ReGiftId, ReNumNow, TrueReNum, ReYbLimit]) ->
	Len = length(List),
	Data = list_to_binary(List),
	Bin = <<Recharge:32, Len:16, Data/binary, LeftSecond:32, ReGiftId:32, ReNumNow:32, TrueReNum:32, ReYbLimit:32>>,
	{ok, pt:pack(31430, Bin)};

%% [充值送礼] 领取奖励
write(31421, [GiftId, Result]) ->
	Bin = <<GiftId:32, Result:16>>,
	{ok, pt:pack(31421, Bin)};

%% 临时，春节版 [充值送礼] 领取奖励
write(31431, [GiftId, Result]) ->
	Bin = <<GiftId:32, Result:16>>,
	{ok, pt:pack(31431, Bin)};

%% 開服前10天每日領取綁定元寶状态
write(31450, Error) ->
	Bin = <<Error:8>>,
	{ok, pt:pack(31450, Bin)};

%% 開服前10天每日領取綁定元寶
write(31451, Error) ->
	Bin = <<Error:8>>,
	{ok, pt:pack(31451, Bin)};

%% 获取活动奖励领取统计
write(31480, [Type, Status, Level]) ->
	Bin = <<Type:16, Status:8, Level:8>>,
	{ok, pt:pack(31480, Bin)};

%% 活跃度变化通知
write(31481, _) ->
	Bin = <<>>,
	{ok, pt:pack(31481, Bin)};

%% 活跃度变化通知
write(31482, DataList) ->
	DataListLength = length(DataList),
	Bin = write_DataList(DataList,<<DataListLength:16>>),
	{ok, pt:pack(31482, Bin)};

%% 消费礼包查询
write(31483, [DataList,RestTime]) ->
	DataListLength = length(DataList),
	Bin = write_DataList2(DataList,<<DataListLength:16>>),
	{ok, pt:pack(31483, <<Bin/binary,RestTime:32>>)};

%%领取消费礼包 
write(31484, [Result]) ->
	Bin = <<Result:8>>,
	{ok, pt:pack(31484, Bin)};

%% [合服] 打开面板需要的数据 
write(31485, Time) ->
	Bin = <<Time:32>>,
	{ok, pt:pack(31485, Bin)};

%% [通用] 领取奖励
write(31486, [In, Error]) ->
	Bin = <<In:32, Error:16>>,
	{ok, pt:pack(31486, Bin)};

%% [合服充值礼包] 打开面板
write(31487, [Recharge, List, LeftTime]) ->
	Len = length(List),
	BinData = list_to_binary(List),
	Bin = <<Recharge:32, Len:16, BinData/binary, LeftTime:32>>,
	{ok, pt:pack(31487, Bin)};

%% [合服充值礼包] 领取奖励
write(31488, [GiftId, ErrorCode]) ->
	Bin = <<GiftId:32, ErrorCode:16>>,
	{ok, pt:pack(31488, Bin)};

%% [幸福回归] 领取奖励
write(31489, [Res]) ->
	Bin = <<Res:8>>,
	{ok, pt:pack(31489, Bin)};

%% 开服充值累计送礼包活动基本信息
write(31490, [PackageNum, YBNeed]) ->
	Bin = <<PackageNum:32, YBNeed:32>>,
	{ok, pt:pack(31490, Bin)};

%% 开服充值累计送礼包活动领取礼包
write(31491, [Res]) ->
	Bin = <<Res:8>>,
	{ok, pt:pack(31491, Bin)};

%% 开服充值累计送礼包活动领取礼包(图标)
write(31492, [Res]) ->
	Bin = <<Res:8>>,
	{ok, pt:pack(31492, Bin)};

%% 消费返元宝查询
write(31493, [PacketList, LeftTime]) ->
	Len = length(PacketList),
	F = fun([Id, Flag, Status, TheDay, FetchTime, Expenditure]) ->
			<<Id:32, Flag:8, Status:8, TheDay:32, FetchTime:32, Expenditure:32>>
		end,
	Bin = list_to_binary(lists:map(F, PacketList)),
	{ok, pt:pack(31493, <<Len:16, Bin/binary, LeftTime:32>>)};

%% 领取消费返元宝
write(31494, [Res]) ->
	Bin = <<Res:8>>,
	{ok, pt:pack(31494, Bin)};

%% 默认配对
write(Cmd, _Bin) ->
	util:errlog("pt_314 write Cmd = ~p error~n", [Cmd]),
	{ok, pt:pack(0, <<>>)}.

write_DataList(DataList,Bin)->
	case DataList of
		[]->Bin;
		[{Type,Multiple,BeginTime,EndTime}|T]->
			write_DataList(T,<<Bin/binary,Type:8,Multiple:8,BeginTime:32,EndTime:32>>);
		[_|T]->
			write_DataList(T,Bin)
	end.

write_DataList2(DataList,Bin)->
	case DataList of
		[]->Bin;
		[{No,Goods_id,Goods_num,Type,Need_Eqout,Need_Times,Eqout,Times}|T]->
			write_DataList2(T,<<Bin/binary,No:32,Goods_id:32,Goods_num:16,Type:8,Need_Eqout:32,Need_Times:32,Eqout:32,Times:32>>);
		[_|T]->
			write_DataList2(T,Bin)
	end.

read_id_type_list(<<Type:16, Rest/binary>>, List, ListNum) when ListNum > 0 ->
    NewList = [Type | List],
    read_id_type_list(Rest, NewList, ListNum - 1);
read_id_type_list(_, List, _) -> List.
