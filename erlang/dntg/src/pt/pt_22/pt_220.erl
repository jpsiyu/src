%%%--------------------------------------
%%% @Module : pt_220
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.5.31
%%% @Description : 排行榜
%%%--------------------------------------

-module(pt_220).
-export([read/2, write/2]).

%%
%% 客户端 -> 服务端 ----------------------------
%%

%% [中秋国庆活动] 获取魅力排行榜
read(22065, _) ->
    {ok, get_rank};

%% 查看名人堂
read(22074, _) ->
	{ok, get_rank};

%% 查看合服名人堂
read(22076, _) ->
	{ok, get_rank};

%% 查询个人排行
read(22001, <<RankType:16>>) ->
	{ok, RankType};

%% 查询个人排行 -- 元神榜
read(22019, _) ->
	{ok, get_rank};

%% 查询宠物排行
read(22004, <<RankType:16>>) ->
	{ok, RankType};

%% 查询装备排行
read(22002, <<RankType:16>>) ->
	{ok, RankType};

%% 查询帮会排行
read(22003, _) ->
	{ok, get_rank};

%% 竞技每日上榜
read(22005, _) ->
	{ok, get_rank};

%% 竞技每周上榜
read(22020, _) ->
	{ok, get_rank};

%% 竞技每周击杀榜
read(22021, _) ->
	{ok, get_rank};

%% 查询铜钱副本排行
read(22022, _) ->
	{ok, get_rank};

%% 九重天霸主排行
read(22023, <<RankType:16>>) ->
	{ok, RankType};

%% 查询炼狱排行
read(22024, _) ->
	{ok, get_rank};

%% 1v1 排行榜
read(22025, _) ->
	{ok, get_rank};

%% 查询魅力排行
read(22014, <<RankType:16>>) ->
	{ok, RankType};

%% 限时名人堂（活动）排行
read(22018, <<RankType:16>>) ->
	{ok, RankType};

%% 坐骑-战力排行
read(22040, <<RankType:16>>) ->
	{ok, RankType};

%% 飞行器-战力排行
read(22042, _) ->
	{ok, get_rank};

%% [游戏线]参与战斗力评分
read(22070, _) ->
	{ok, eva};

%% 查看角色基础信息
read(22016, <<PlayerId:32, RankType:16, Position:16>>) ->
	{ok, [PlayerId, RankType, Position]};

%% 崇拜/鄙视玩家
read(22015, <<PlayerId:32, ActionType:8, RankType:16>>) ->
	{ok, [PlayerId, ActionType, RankType]};

%% [游戏线]身上装备快速评分
read(22017, _) ->
	{ok, eva};

%% [游戏线] 限时名人堂（活动）获取雕像数据
read(22030, _) ->
	{ok, get_data};

%% 坐骑-详细信息
read(22041, <<Id:32>>) ->
	{ok, Id};



%% 查看投票结果 
read(22075, _) ->
	{ok, get_data};

%%---------- 跨服排行榜 ----------
%% 跨服1v1玩家自己信息
read(22050, _) ->
	{ok, get_info};

%% 跨服1v1每周榜
read(22052, _) ->
	{ok, get_rank};

%% 跨服3v3mvp榜
read(22053, _) ->
	{ok, get_rank};

%% 跨服3v3玩家自己信息
read(22054, _) ->
	{ok, get_info};

%% 跨服3v3本服周积分排行榜
read(22055, _) ->
	{ok, get_info};

%% 跨服玩家相关榜
read(22058, <<RankType:16>>) ->
	{ok, RankType};

%% 跨服宠物相关榜
read(22059, <<RankType:16>>) ->
	{ok, RankType};

%% 跨服装备相关榜
read(22060, <<RankType:16>>) ->
	{ok, RankType};

%% [游戏线] 单件装备评分
read(22071, <<GoodsId:32>>) ->
	{ok, GoodsId};


read(_, _) ->
	{error, no_match}.

%%
%% 服务端 -> 客户端 ------------------------------------
%%

%% 查看名人堂
write(22074, List) ->
	NewList = private_format_fame_data(List, 0),
	Len = length(NewList),
	Data = list_to_binary(NewList),
	Bin = <<Len:16, Data/binary>>,
	{ok, pt:pack(22074, Bin)};

%% 查看合服名人堂
write(22076, List) ->
	NewList = private_format_fame_data(List, 1),
	Len = length(NewList),
	Data = list_to_binary(NewList),
	Bin = <<Len:16, Data/binary>>,
	{ok, pt:pack(22076, Bin)};

%% 弹出领取名人堂成就奖励面板
write(22072, FameId) ->
	Data = <<FameId:32>>,
	{ok, pt:pack(22072, Data)};

%% [通用] - 返回带有排行类型的列表数据
write(22080, [PTCode, RankType, List]) ->
	Len = length(List),
	Bin = list_to_binary(List),
	Data = <<RankType:16, Len:16, Bin/binary>>,
	{ok, pt:pack(PTCode, Data)};

%% [通用] - 返回没带排行类型的列表数据
write(22081, [PTCode, List]) ->
	Len = length(List),
	Bin = list_to_binary(List),
	Data = <<Len:16, Bin/binary>>,
	{ok, pt:pack(PTCode, Data)};

%% 查看角色基础信息
write(22016, [ErrorCode, RankType, Result]) ->
	if
		ErrorCode =:= 1 ->
			[
                RoleId, Nick, Sex, Career, Realm, LV, ChongBai, BiShi, NewEquipList, ActionNum, 
				Stren7Num, DesignId, ParnerId, ParnerName, 
                XY1, XY2, XY3, XY4, XY5, XY6, XY7, XY8, XY9, XY10, XYLevel,
				XY1_1, XY2_1, XY3_1,XY4_1, XY5_1, XY6_1, XY7_1, XY8_1, XY9_1, XY10_1,
                ToMerdian,
                Str1, StrNum1, Str2, StrNum2, Str3, StrNum3,
				QLForza, QLAgile, QLWit, QLThew
            ] = Result,
			
			%% 元神
			{MeridianGap, [
				{MerHp3,GenHp3}, {MerMp3,GenMp3}, {MerDef3,GenDef3}, {MerHit3,GenHit3}, 
				{MerDodge3,GenDodge3}, {MerTen3,GenTen3}, {MerCrit3,GenCrit3}, {MerAtt3,GenAtt3}, 
				{MerFire3,GenFire3}, {MerIce3,GenIce3}, {MerDrug3,GenDrug3}
			]} = ToMerdian,
			
			NickName = pt:write_string(Nick),
			EquipLen = length(NewEquipList),
			EquipBin = list_to_binary(NewEquipList),
			NewStren7Num = pt:write_string(Stren7Num),
            ParnerNickName = pt:write_string(ParnerName),
			Data = <<ErrorCode:8, RankType:16, RoleId:32, NickName/binary, Sex:8, Career:8, Realm:8, LV:8, 
			    ChongBai:32, BiShi:32, EquipLen:16, EquipBin/binary, ActionNum:8, NewStren7Num/binary, DesignId:32,
                ParnerId:32, ParnerNickName/binary,
                XY1:32, XY2:32, XY3:32, XY4:32, XY5:32, XY6:32, XY7:32, XY8:32, XY9:32, XY10:32, 
                XY1_1:32,XY2_1:32,XY3_1:32,XY4_1:32,XY5_1:32,XY6_1:32,XY7_1:32,XY8_1:32,XY9_1:32,XY10_1:32,XYLevel:8,
				%% 元神
				MerHp3:16, MerMp3:16, MerDef3:16, MerHit3:16, MerDodge3:16, MerTen3:16, MerCrit3:16, MerAtt3:16, MerFire3:16, MerIce3:16, MerDrug3:16, 
				GenHp3:16, GenMp3:16, GenDef3:16, GenHit3:16, GenDodge3:16, GenTen3:16, GenCrit3:16, GenAtt3:16, GenFire3:16, GenIce3:16, GenDrug3:16, 
				MeridianGap:8,
                Str1:32, StrNum1:16, Str2:32, StrNum2:16, Str3:32, StrNum3:16,
				QLForza:16, QLAgile:16, QLWit:16, QLThew:16
            >>,
		    {ok, pt:pack(22016, Data)};
		true ->
			skip
	end;

%% [游戏线]身上装备快速评分
write(22017, [ErrorCode, List]) ->
	Len = length(List),
	Bin = list_to_binary(List),
	Data = <<ErrorCode:8, Len:16, Bin/binary>>,
	{ok, pt:pack(22017, Data)};

%% 崇拜/鄙视玩家
write(22015, [ErrorCode, ActionType, RankType, RoleId, Chongbai, Bishi, Num]) ->
	Data = <<ErrorCode:8, ActionType:8, RankType:16, RoleId:32, Chongbai:32, Bishi:32, Num:8>>,
	{ok, pt:pack(22015, Data)};

%% 限时名人堂（活动）获取雕像数据
write(22030, List) ->  
	F = fun([Type, [Id, Lv, Realm, Career, Sex, Weapon, Cloth, WLight, CLight, ShiZhuang, SuitId, Vip, Nick]]) ->
		[[FWeapon, FWS], [FArmor, FAS], [FAccessory, FAccS]] = case is_list(ShiZhuang) of
			true -> ShiZhuang;
			false -> [[0, 0], [ShiZhuang, 0], [0, 0]]
		end,
		Nick_b = list_to_binary(Nick),
		NL = byte_size(Nick_b),
		S7 = pt:write_string(integer_to_list(CLight)),
		<<
			Type:32,			%% 雕像id
			Id:32,			%% 玩家id    
			Lv:16,			%% 玩家等级
			Realm:8,			%% 国家
			Career:8,			%% 玩家职业
			Sex:8,			%% 玩家性别
			Weapon:32,		%% 武器
			Cloth:32,			%% 装备
			WLight:8,			%% 武器发光
			S7/binary,		%% 衣服发光
			FArmor:32,		%% 时装衣服id
			SuitId:32,			%% 套装id
			Vip:8,			%% vip
			NL:16,			%% 玩家名字
			Nick_b/binary,	%% 玩家名字
			FAS:8,			%% 衣服时装强化数
			FWeapon:32,		%% 武器时装id
			FWS:8,			%% 武器时装强化数
			FAccessory:32,		%% 饰品时装id
			FAccS:8			%% 饰品时装强化数
		>>
	end,
	Bin = list_to_binary([F(E) || E <- List]),
	Len = length(List),
	{ok, pt:pack(22030, <<Len:16, Bin/binary>>)};

%% [公共线]清除雕像上的人物形象
write(22031, _) ->
	Data = <<1:32>>,
	{ok, pt:pack(22031, Data)};

%% 跨服玩家相关榜
write(22058, [RankType, List]) ->
	Len = length(List),
	Bin = list_to_binary(List),
	Data = <<RankType:16, Len:16, Bin/binary>>,
	{ok, pt:pack(22058, Data)};

%% 跨服宠物相关榜
write(22059, [RankType, List]) ->
	Len = length(List),
	Bin = list_to_binary(List),
	Data = <<RankType:16, Len:16, Bin/binary>>,
	{ok, pt:pack(22059, Data)};

%% 跨服装备相关榜
write(22060, [RankType, List]) ->
	Len = length(List),
	Bin = list_to_binary(List),
	Data = <<RankType:16, Len:16, Bin/binary>>,
	{ok, pt:pack(22060, Data)};



%% [游戏线]领取名人堂成就奖励
write(22073, ErrorCode) ->
	Data = <<ErrorCode:32>>,
	{ok, pt:pack(22073, Data)};

%% [游戏线] 单件装备评分
write(22071, [ErrorCode, Result]) ->
	Data = <<ErrorCode:8, Result:16>>,
	{ok, pt:pack(22071, Data)};

%% 查看投票结果
write(22075, [List, LeftSecond]) ->
	Len = length(List),
	Bin = list_to_binary(List),
	Data = <<Len:16, Bin/binary, LeftSecond:32>>,
	{ok, pt:pack(22075, Data)};

%% 坐骑-详细信息
write(22041, [Picture, Power, Stren, Quality, LV, NickName, Type]) ->
	NewNick = pt:write_string(NickName),
	Data = <<Picture:32, Power:32, Stren:8, Quality:16, LV:8, NewNick/binary, Type:32>>,
	{ok, pt:pack(22041, Data)};

%% 飞行器-战力榜
write(22042, List) ->
	Len = length(List),
	Bin = list_to_binary(List),
	Data = <<Len:16, Bin/binary>>,
	{ok, pt:pack(22042, Data)};

%%---------- 跨服排行榜 ----------
%% 跨服1v1玩家自己信息
write(22050, [Pt,PtRank,Score,Loop,LoopWin]) ->
	Data = <<Pt:32, PtRank:16, Score:32, Loop:16, LoopWin:16>>,
	{ok, pt:pack(22050, Data)};

%% 跨服1v1每周榜
write(22052, List) ->
	Len = length(List),
	Bin = list_to_binary(List),
	Data = <<Len:16,Bin/binary>>,
	{ok, pt:pack(22052, Data)};

%% 跨服3v3 mvp榜
write(22053, List) ->
	Len = length(List),
	Bin = list_to_binary(List),
	Data = <<Len:16,Bin/binary>>,
	{ok, pt:pack(22053, Data)};

%% 跨服3v3玩家自己信息
write(22054, [Pt,PtRank,Mvp,Loop,LoopWin, ScoreWeek]) ->
	Data = <<Pt:32, PtRank:16, Mvp:32, Loop:16, LoopWin:16, ScoreWeek:32>>,
	{ok, pt:pack(22054, Data)};

%% 跨服3v3本服周积分排行榜
write(22055, List) ->
	Len = length(List),
	Bin = list_to_binary(List),
	Data = <<Len:16,Bin/binary>>,
	{ok, pt:pack(22055, Data)};

%% 获取世界等级
write(22085, Level) ->
	Data = <<Level:8>>,
	{ok, pt:pack(22085, Data)};

%% [中秋国庆活动] 获取魅力排行榜
write(22065, [FlowerList, HuhuaList]) ->
	Len = length(FlowerList),
	Len2 = length(HuhuaList),
	Data = list_to_binary(FlowerList),
	Data2 = list_to_binary(HuhuaList),
	Bin = <<Len:16, Data/binary, Len2:16, Data2/binary>>,
	{ok, pt:pack(22065, Bin)};

write(_, _) ->
	{ok, pt:pack(0, <<>>)}.

%% 构造名人堂数据
private_format_fame_data(List, FameType) ->
	NewList = case List =:= [] of
		true ->
			[];
		_ ->
			FameIds = data_fame:get_ids(FameType),
			F2 = fun(Pid, Pname, Prealm, Pcareer, Psex, Pimage) ->
				Name = pt:write_string(Pname),
				<<Pid:32, Name/binary, Prealm:8, Pcareer:8, Psex:8, Pimage:16>>
			end,
			F = fun([FameId, Status, PlayerList]) ->
				NewPlayerLlist = [F2(Id, NickName, Realm, Career, Sex, Image) || [Id, NickName, Realm, Career, Sex, Image] <- PlayerList],
				Length = length(NewPlayerLlist),
				Bin = list_to_binary(NewPlayerLlist),
				<<FameId:32, Status:8, Length:16, Bin/binary>>
			end,
			[F([TmpFameId, TmpStatus, TmpPlayerList]) ||  [TmpFameId, TmpStatus, TmpPlayerList] <- List, lists:member(TmpFameId, FameIds)]
	end,
	NewList.
