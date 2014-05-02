%%%---------------------------------------------
%%% @Module  : pt_400_c
%%% @Author  : zhenghehe
%%% @Created : 2012.01.07
%%% @Description: 帮派系统测试客户端组包解包
%%%---------------------------------------------
-module(pt_400_c).
-compile(export_all).
write(40001, [UseType, Name, Tenet]) ->
    Name1 = pt:write_string(Name),
    Tenet1 = pt:write_string(Tenet),
    Data = <<UseType:8, Name1/binary, Tenet1/binary>>,
    {ok, pt:pack(40001, Data)};

write(40002, [GuildId]) ->
    {ok, pt:pack(40002, <<GuildId:32>>)};

write(40003, [GuildId, Result]) ->
    {ok, pt:pack(40003, <<GuildId:32, Result:16>>)};

write(40010, [PageSize, PageNo]) ->
    {ok, pt:pack(40010, <<PageSize:16, PageNo:16>>)};

write(40011, [GuildId, PageSize, PageNo]) ->
    {ok, pt:pack(40011, <<GuildId:32, PageSize:16, PageNo:16>>)};

write(40014, [GuildId]) ->
    {ok, pt:pack(40014, <<GuildId:32>>)};

write(40017, [RoleId, NewPosition]) ->
    {ok, pt:pack(40017, <<RoleId:32, NewPosition:16>>)};

write(40019, [GuildId, Num]) ->
    {ok, pt:pack(40019, <<GuildId:32, Num:32>>)};

write(40021, [GuildId, PageSize, PageNo]) ->
    {ok, pt:pack(40021, <<GuildId:32, PageSize:16, PageNo:16>>)};

write(40023, [GuildId]) ->
    {ok, pt:pack(40023, <<GuildId:32>>)};

write(40027, [GuildId]) ->
    {ok, pt:pack(40027, <<GuildId:32>>)};

write(40032, [GuildId]) ->
    {ok, pt:pack(40032, <<GuildId:32>>)};

write(40033, [GuildId]) ->
    {ok, pt:pack(40033, <<GuildId:32>>)};

write(40037, []) ->
    {ok, pt:pack(40037, <<>>)};

write(40038, []) ->
    {ok, pt:pack(40038, <<>>)};

write(40040, []) ->
    {ok, pt:pack(40040, <<>>)};

write(40044, []) ->
    {ok, pt:pack(40044, <<>>)};

write(40055, []) ->
    {ok, pt:pack(40055, <<>>)};

write(40064, [SkillId]) ->
    {ok, pt:pack(40064, <<SkillId:32>>)};

write(40065, [SkillId]) ->
    {ok, pt:pack(40065, <<SkillId:32>>)};

write(40090, [GuildId]) ->
    {ok, pt:pack(40090, <<GuildId:32>>)};

write(40035, [Type]) ->
	{ok, pt:pack(40035, <<Type:8>>)};

write(12002, []) ->
	{ok, pt:pack(12002, <<>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

read(40001, <<Result:16, GuildId:32, Bin/binary>>) ->
    {GuildName, Res} = pt:read_string(Bin),
    <<GuildPosition:16, UseType:8, CoinLeft:32, BindCoinLeft:32>> = Res,
    {Result, GuildId, GuildName, GuildPosition, UseType, CoinLeft, BindCoinLeft};

read(40002, <<Result:16>>) ->
    Result;

read(40003, <<Flag:16, GuildId:32, Bin/binary>>) ->
    {GuildName, Res} = pt:read_string(Bin),
    <<Result:16>> = Res,
    {Flag, GuildId, GuildName, Result};

read(40010, <<Result:16, PageTotal:16, PageNo:16, RecordNum:16, Bin/binary>>) ->
    case RecordNum > 0 of
        false ->
            L = [];
        true ->
            L = unpack_guild_list(Bin, RecordNum, [])
    end,
    {Result, PageTotal, PageNo, RecordNum, L};

read(40011, <<Result:16, PageTotal:16, PageNo:16, RecordNum:16, Bin/binary>>) ->
    case RecordNum >0 of
        false ->
            L = [];
        true ->
            L = unpack_member_list(Bin, RecordNum, [])
    end,
    {Result, PageTotal, PageNo, RecordNum, L};

read(40014, <<Result:16, Bin/binary>>) ->
    case Result of
        1 ->
            <<GuildId:32, Bin2/binary>> = Bin,
            {GuildName, Bin3} = pt:read_string(Bin2),
            {GuildTenet, Bin4} = pt:read_string(Bin3),
            {GuildAnnounce, Bin5} = pt:read_string(Bin4),
            <<InitiatorId:32, Bin6/binary>> = Bin5,
            {InitiatorName, Bin7} = pt:read_string(Bin6),
            <<ChiefId:32, Bin8/binary>> = Bin7,
            {ChiefName, Bin9} = pt:read_string(Bin8),
            <<DeputyChief1Id:32, Bin10/binary>> = Bin9,
            {DeputyChief1Name, Bin11} = pt:read_string(Bin10),
            <<DeputyChief2Id:32, Bin12/binary>> = Bin11,
            {DeputyChief2Name, Bin13} = pt:read_string(Bin12),
            <<DeputyChiefNum:16,MemberNum:16,NewMemberCapacity:16,Realm:16,Level:16,Reputation:16,Funds:32,Contribution:32,ContributionDaily:32,CombatNum:16,CombatVictoryNum:16,QQ:32,CreateTime:32, ContributionThreshold:32, DepotLevel:16, HallLevel:16, DepotNextLevelCoin:32, DepotNextLevelContribution:32, HallNextLevelCoin:32,  HallNextLevelContribution:32, DisbandFlag:16, DisbandConfirmTime:32, CreateType:8, HouseLevel:16, HouseNextLevelGold:32, RenameFlag:8, MallLevel:16,MallContri:32,MallContriCostDaily:32,MallFundsCostDaily:32,MallContriCostUpgrade:32,MallFundsCostUpgrade:32>> = Bin13,
            {1, {GuildId, GuildName, GuildTenet, GuildAnnounce, InitiatorId, InitiatorName, ChiefId, ChiefName, DeputyChief1Id, DeputyChief1Name, DeputyChief2Id, DeputyChief2Name, DeputyChiefNum,MemberNum,NewMemberCapacity,Realm,Level,Reputation,Funds,Contribution,ContributionDaily,CombatNum,CombatVictoryNum,QQ,CreateTime, ContributionThreshold, DepotLevel, HallLevel, DepotNextLevelCoin, DepotNextLevelContribution, HallNextLevelCoin,  HallNextLevelContribution, DisbandFlag, DisbandConfirmTime, CreateType, HouseLevel, HouseNextLevelGold, RenameFlag, MallLevel,MallContri,MallContriCostDaily,MallFundsCostDaily,MallContriCostUpgrade,MallFundsCostUpgrade}};
        _ ->
            {Result, {}}
    end;

read(40017, <<Result:16>>) ->
    Result;

read(40019, <<Result:16, CoinLeft:32, BindCoinLeft:32, DonationAdd:32, PaidAdd:32>>) ->
    {Result, CoinLeft, BindCoinLeft, DonationAdd, PaidAdd};

read(40021, <<Result:16, PageTotal:16, PageNo:16, RecordNum:16, Bin/binary>>) ->
    case RecordNum > 0 of
        false ->
            L = [];
        true ->
            L = unpack_donate_list(Bin, RecordNum, [])
    end,
    {Result, PageTotal, PageNo, RecordNum, L};

read(40023, <<Result:16, Num:32, BindCoinLeft:32>>) ->
    {Result, Num, BindCoinLeft};

read(40027, <<Result:16, RecordNum:16, Bin/binary>>) ->
    case RecordNum > 0 of
        false ->
            L = [];
        true ->
            L = unpack_depot_goods_list(Bin, RecordNum, [])
    end,
    {Result, RecordNum, L};

read(40032, <<Result:16, GuildId:32, OldLevel:16, NewLevel:16, ContributionUse:32, FunsUse:32>>) ->
    {Result, GuildId, OldLevel, NewLevel, ContributionUse, FunsUse};

read(40033, <<Result:16, GuildId:32, OldLevel:16, NewLevel:16, NewMemberCapacity:32, DonationAdd:32, PaidAdd:32>>) ->
    {Result, GuildId, OldLevel, NewLevel, NewMemberCapacity, DonationAdd, PaidAdd};

read(40037, <<Result:16, RecordNum:16, Bin/binary>>) ->
    case RecordNum > 0 of
        false ->
            L = [];
        true ->
            L = unpack_member_battle_score_list(Bin, RecordNum, [])
    end,
    {Result, RecordNum, L};

read(40038, <<Result:8, GuildId:32, WinNum:32, LoseNum:32, StoneNum:32, BattleScore:32>>) ->
    {Result, GuildId, WinNum, LoseNum, StoneNum, BattleScore};

read(40040, <<Result:8, RecordNum:16, Bin/binary>>) ->
    case RecordNum > 0 of
        false ->
            L = [];
        true ->
            L = unpack_guild_goods_list(Bin, RecordNum, [])
    end,
    {Result, RecordNum, L};

read(40044, <<Result:8, RecordNum:16, Bin/binary>>) ->
    case RecordNum > 0 of
        false ->
            L = [];
        true ->
            L = unpack_member_award_list(Bin, RecordNum, [])
    end,
    {Result, RecordNum, L};

read(40055, <<Result:8, RecordNum:16, Bin/binary>>) ->
    case RecordNum > 0 of
        false ->
            L = [];
        true ->
            L = unpack_guild_event_list(Bin, RecordNum, [])
    end,
    {Result, RecordNum, L};

read(40064, <<Result:8, SkillId:32, SkillLevel:8>>) ->
    {Result, SkillId, SkillLevel};

read(40065, <<Result:8, ActiveSkillId:32>>) ->
    {Result, ActiveSkillId};

read(40090, <<Result:16, GuildId:32, OldMallLevel:16, NewMallLevel:16, ContributionCost:32, FundsCost:32>>) ->
    {Result, GuildId, OldMallLevel, NewMallLevel, ContributionCost, FundsCost};

read(40035, <<Result:16, HallEnterLeftTime:32>>) ->
	{Result, HallEnterLeftTime};

read(12005, <<Scene:32, X:16, Y:16, Bin/binary>>) ->
	{Name, Res} = pt:read_string(Bin),
	<<Sid:32>> = Res,
	{Scene, X, Y, Name, Sid};

read(_Cmd, _R) ->
    {error, no_match}.

unpack_guild_list(_Bin, 0, AccList) ->
    AccList;
unpack_guild_list(Bin, RecordNum, AccList) ->
    <<GuildId:32, Bin2/binary>> = Bin,
    {GuildName, Bin3} = pt:read_string(Bin2),
    <<ChiefId:32, Bin4/binary>> = Bin3,
    {ChiefName, Bin5} = pt:read_string(Bin4),
    <<MemberNum:16, MemberCapacity:16, Level:16, Realm:16, Bin6/binary>> = Bin5,
    {Tenet, Bin7} = pt:read_string(Bin6),
    <<Funds:32, Bin8/binary>> = Bin7,
    {Announce, Bin9} = pt:read_string(Bin8),
    <<CreateType:8, HouseLevel:16, Bin10/binary>> = Bin9,
    NewAccList = [{GuildId, GuildName, ChiefId, ChiefName, MemberNum, MemberCapacity, Level, Realm, Tenet, Funds, Announce, CreateType, HouseLevel}|AccList],
    unpack_guild_list(Bin10, RecordNum-1, NewAccList).

unpack_member_list(_Bin, 0, AccList) ->
    AccList;
unpack_member_list(Bin, RecordNum, AccList) ->
    <<MemberId:32, Bin2/binary>> = Bin,
    {MemberName, Bin3} = pt:read_string(Bin2),
    <<Sex:16, Career:16, Level:16, GuildPosition:16, Donate:32, OnlineFlag:16, Bin4/binary>> = Bin3,
    {Title, Bin5} = pt:read_string(Bin4),
    <<LastLoginTime:32, Image:16, Vip:8, Bin6/binary>> = Bin5,
    NewAccList = [{MemberId, MemberName, Sex, Career, Level, GuildPosition, Donate, OnlineFlag, Title, LastLoginTime, Image, Vip}|AccList],
    unpack_member_list(Bin6, RecordNum-1, NewAccList).

unpack_donate_list(_Bin, 0, AccList) ->
    AccList;
unpack_donate_list(Bin, RecordNum, AccList) ->
    <<PlayerId:32, Bin2/binary>> = Bin,
    {PlayerName, Bin3} = pt:read_string(Bin2),
    <<PlayerLevel:16, GuildPosition:16, DonateTotal:32, DonateTotalLastWeek:32, DonateTotalLastDay:32, PlayerSex:16, PlayerCareer:16, DonateTotalCard:32, DonateTotalCoin:32, OnlineFlag:8, LastLoginTime:32, Image:16, Vip:8, Bin4/binary>> = Bin3,
    NewAccList = [{PlayerId, PlayerName, PlayerLevel, GuildPosition, DonateTotal, DonateTotalLastWeek, DonateTotalLastDay, PlayerSex, PlayerCareer, DonateTotalCard, DonateTotalCoin, OnlineFlag, LastLoginTime, Image, Vip}|AccList],
    unpack_donate_list(Bin4, RecordNum-1, NewAccList).

unpack_depot_goods_list(_Bin, 0, AccList) ->
    AccList;
unpack_depot_goods_list(Bin, RecordNum, AccList) ->
    <<Id:32, TypeId:32, Cell:16, Num:16, Stren:16, Bin2/binary>> = Bin,
    NewAccList = [{Id, TypeId, Cell, Num, Stren}|AccList],
    unpack_depot_goods_list(Bin2, RecordNum-1, NewAccList).

unpack_member_battle_score_list(_Bin, 0, AccList) ->
    AccList;
unpack_member_battle_score_list(Bin, RecordNum, AccList) ->
    <<PlayerId:32, Bin2/binary>> = Bin,
    {PlayerName, Bin3} = pt:read_string(Bin2),
    <<Level:8, Career:8, Sex:8, WinNum:32, LoseNum:32, StoneNum:32, BattleScore:32, BattleScoreTotal:32, Bin4/binary>> = Bin3,
    NewAccList = [{PlayerId, PlayerName, Level, Career, Sex, WinNum, LoseNum, StoneNum, BattleScore, BattleScoreTotal}|AccList],
    unpack_member_battle_score_list(Bin4, RecordNum-1, NewAccList).

unpack_guild_goods_list(_Bin, 0, AccList) ->
    AccList;
unpack_guild_goods_list(Bin, RecordNum, AccList) ->
    <<GoodsTypeId:32, GoodsNum:16, DonateNeed:16, Bin2/binary>> = Bin,
    NewAccList = [{GoodsTypeId, GoodsNum, DonateNeed}|AccList],
    unpack_guild_goods_list(Bin2, RecordNum-1, NewAccList).

unpack_member_award_list(_Bin, 0, AccList) ->
    AccList;
unpack_member_award_list(Bin, RecordNum, AccList) ->
    <<Id:32, GoodsId:32, GoodsNum:16, Score:16, PlayerId:32, Bin2/binary>> = Bin,
    NewAccList = [{Id, GoodsId, GoodsNum, Score, PlayerId}|AccList],
    unpack_member_award_list(Bin2, RecordNum-1, NewAccList).

unpack_guild_event_list(_Bin, 0, AccList) ->
    AccList;
unpack_guild_event_list(Bin, RecordNum, AccList) ->
    <<Time:32, EventType:16, Bin2/binary>> = Bin,
    {EventParam, Bin3} = pt:read_string(Bin2),
    NewAccList = [{Time, EventType, EventParam}|AccList],
    unpack_guild_event_list(Bin3, RecordNum-1, NewAccList).

                        
