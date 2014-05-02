%%%-------------------------------------------------------------------
%%% @Module	: pt_315
%%% @Author	: 节日活动
%%% @Email	: 
%%% @Created	: 2012
%%% @Description: 节日活动
%%%-------------------------------------------------------------------
-module(pt_315).
-export([read/2, write/2]).

%% 节日充值活动:类型1(获取基本信息)
read(31500, <<Type:8>>) ->
    {ok, [Type]};

%% 节日充值活动:类型1(领取指定礼包)
read(31501, <<Type:8, Times:32, GiftId:32>>) ->
    {ok, [Type, Times, GiftId]};

%% 收到贺卡列表
read(31506, _) ->
	{ok, done};

%% 发送贺卡  
read(31507, <<Bin/binary>>) ->
	{ReceiveName2, Bin2} = pt:read_string(Bin),
	<<AnimationId:8, GiftId:32, Bin3/binary>> = Bin2,	
	{WishMsg2, _} = pt:read_string(Bin3),
	{ok, [ReceiveName2, AnimationId, GiftId, WishMsg2]};

%% 阅读贺卡
read(31508, <<CardId:32>>) ->
	{ok, [CardId]};

%% 删除贺卡
read(31509, <<CardId:32>>) ->
	{ok, [CardId]};

%% 收取礼物
read(31510, <<CardId:32>>) ->
	{ok, [CardId]};

%% 获取是否显示跨服鲜花榜图标
read(31511, _) ->
	{ok, 31511};

%% 获取跨服鲜花榜数据
read(31512, <<Sex:8, Type:8>>) ->
	{ok, [Sex, Type]};

%% 元宵节花灯列表
read(31513, _) ->
	{ok, done};

%% 元宵节花灯详细
read(31514, <<LampId:32>>) ->
	{ok, [LampId]};

%% 燃放元宵节花灯
read(31515, <<LampType:8>>) ->
	{ok, [LampType]};

%% 邀请好友为花灯送祝福
read(31516, <<Bin/binary>>) ->
	{InviterName, Bin2} =  pt:read_string(Bin),
	<<LampId:32, _/binary>> = Bin2,
	{ok, [InviterName, LampId]};

%% 花灯送祝福记录
read(31517, <<LampId:32>>) ->
	{ok, [LampId]};

%% 为花灯送祝福 
read(31518, <<LampId:32>>) ->
	{ok, [LampId]};

%% 收获花灯
read(31519, <<LampId:32>>) ->
	{ok, [LampId]};

%% 单笔充值礼包列表
read(31530, _) ->
    {ok, []};

%% 领取礼包
read(31531, <<GiftId:32>>) ->
    {ok, [GiftId]};

%% 默认配对
read(Cmd, _R) ->
    util:errlog("pt_315 read Cmd = ~p error~n", [Cmd]),
    ok.

%% 节日充值活动:类型1(获取基本信息)
write(31500, [Res, TodayMoney, GGlist]) ->
	GGlistBin = pack_31500(GGlist),
    Data = <<Res:8, TodayMoney:32, GGlistBin/binary>>,
    {ok, pt:pack(31500, Data)};

%% 节日充值活动:类型1(领取指定礼包)
write(31501, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(31501, Data)};

%% 收到贺卡
write(31505, [Name]) ->
	Bin_Name = pt:write_string(Name),
    {ok, pt:pack(31505, <<Bin_Name/binary>>)};

%% 收到贺卡列表
write(31506, [Num, ReceiveList]) ->
	Len = length(ReceiveList),
	F = fun([CardId, Status, PlayerId, PlayerName, AnimationId, GiftId, WishMsg, Time]) ->
			Bin_PlayerName = pt:write_string(PlayerName),
			Bin_WishMsg = pt:write_string(WishMsg),
			<<CardId:32, Status:8, PlayerId:32, Bin_PlayerName/binary,
				AnimationId:8, GiftId:32, Bin_WishMsg/binary, Time:32>>
		 end,
	RBin = list_to_binary(lists:map(F, ReceiveList)),
    {ok, pt:pack(31506, <<Num:16, Len:16, RBin/binary>>)};

%% 发送贺
write(31507, [Result]) ->
    {ok, pt:pack(31507, <<Result:8>>)};

%% 阅读贺卡&&收取礼物
write(31508, [Result]) ->
    {ok, pt:pack(31508, <<Result:8>>)};

%% 删除贺卡
write(31509, [Result]) ->
    {ok, pt:pack(31509, <<Result:8>>)};

%% 收取礼物
write(31510, [Result, GoodId]) ->
    {ok, pt:pack(31510, <<Result:8, GoodId:32>>)};

%% 获取是否显示跨服鲜花榜图标
write(31511, [Result]) ->
    {ok, pt:pack(31511, <<Result:8>>)};

%% 获取跨服鲜花榜数据
write(31512, [Res, Sex, List]) ->
	Bin = pack_31512(List),
    {ok, pt:pack(31512, <<Res:8, Sex:8, Bin/binary>>)};

%% 元宵花灯列表
write(31513, [LampList]) ->
	Len = length(LampList),
	F = fun([LampId, PlayerName, X, Y, LampType]) ->
			BinPlayerName = pt:write_string(PlayerName),
			<<LampId:32, BinPlayerName/binary, X:16, Y:16, LampType:8>>
		 end,
	LBin = list_to_binary(lists:map(F, LampList)),
    {ok, pt:pack(31513, <<Len:16, LBin/binary>>)};

%% 元宵花灯详细
write(31514, [PlayerName, LeftTime, GetWishNum, GetWishNumMax, SendWishNum, SendWishNumMax]) ->
	BinPlayerName = pt:write_string(PlayerName),
	{ok, pt:pack(31514, <<BinPlayerName/binary, LeftTime:32,GetWishNum:16,
			GetWishNumMax:16, SendWishNum:16, SendWishNumMax:16>>)};

%% 燃放元宵节花灯
write(31515, [Res, Exp, LampId]) ->
	{ok, pt:pack(31515, <<Res:8, Exp:32, LampId:32>>)};

%% 邀请好友为花灯送祝福
write(31516, [Res]) ->
	{ok, pt:pack(31516, <<Res:8>>)};

%% 花灯送祝福记录
write(31517, [WishSenderList]) ->
	Len = length(WishSenderList),
	F = fun(PlayerName) ->
			BinPlayerName = pt:write_string(PlayerName),
			<<BinPlayerName/binary>>
		 end,
	WBin = list_to_binary(lists:map(F, WishSenderList)),
	{ok, pt:pack(31517, <<Len:16, WBin/binary>>)};

%% 为花灯送祝福
write(31518, [Res, Exp, GoodsId]) ->
	{ok, pt:pack(31518, <<Res:8, Exp:32, GoodsId:32>>)};

%% 收获花灯
write(31519, [Res, GoodsId]) ->
	{ok, pt:pack(31519, <<Res:8, GoodsId:32>>)};

%% 广播元宵花灯变化 
write(31520, [ChangeType, LampList]) ->
	Len = length(LampList),
	F = fun([LampId, PlayerName, X, Y, LampType]) ->
			BinPlayerName = pt:write_string(PlayerName),
			<<LampId:32, BinPlayerName/binary, X:16, Y:16, LampType:8>>
		 end,
	LBin = list_to_binary(lists:map(F, LampList)),
	{ok, pt:pack(31520, <<ChangeType:8, Len:16, LBin/binary>>)};

%% 广播好友为花灯送祝福
write(31521, [PlayerName, LampType, X, Y, LeftNum]) ->
	BinPlayerName = pt:write_string(PlayerName),
	{ok, pt:pack(31521, <<BinPlayerName/binary, LampType:8, X:16, Y:16, LeftNum:8>>)};

write(31530, [List, RemainTime]) ->
    Len = length(List),
    GiftList = [<<Quota:32, GiftId:32, Num:16>> || {Quota, GiftId, Num} <- List],
    Bin = list_to_binary(GiftList),
    Data = <<Len:16, Bin/binary, RemainTime:32>>,
    {ok, pt:pack(31530, Data)};

write(31531, [Result, GiftId]) ->
    Data = <<Result:8, GiftId:32>>,
    {ok, pt:pack(31531, Data)};
    
%% 默认配对
write(Cmd, _Bin) ->
    util:errlog("pt_315 write Cmd = ~p error~n", [Cmd]),
    {ok, pt:pack(0, <<>>)}.

%% -----------------------------------------------------------------
%% 打包31500
%% -----------------------------------------------------------------
pack_31500([]) ->
    <<0:16, <<>>/binary>>;
pack_31500(_List) ->
    _Rlen = length(_List),
    List = case _Rlen > 5 of
	       true ->
		   [_,_|Rest]=_List,
		   Rest;
	       false -> _List
	   end,
    Rlen = length(List),
    F = fun({Time0, _Recharge, GiftListNext}) ->
				BinGiftListNext = pack_31500_2(GiftListNext),
				<<Time0:32, BinGiftListNext/binary>>
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.

pack_31500_2([]) ->
    <<0:16, <<>>/binary>>;
pack_31500_2(List) ->
    Rlen = length(List),
    F = fun([GiftId, _RechargeNeed, ZT]) ->
				<<ZT:8, GiftId:32>>
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.

%% -----------------------------------------------------------------
%% 打包31512
%% -----------------------------------------------------------------
pack_31512([]) ->
    <<0:16, <<>>/binary>>;
pack_31512(List) ->
    Rlen = length(List),
    F = fun([IsHere, ServerNum, RoleId, RoleName, MLPT, Voc, Image]) ->
        Bin_Name = pt:write_string(RoleName),
		Bin_ServerNum = pt:write_string(ServerNum),
        <<IsHere:8, Bin_ServerNum/binary, RoleId:32, Bin_Name/binary, MLPT:32, Voc:8, Image:16>>
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.