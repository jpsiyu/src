%%%------------------------------------------------
%%% @Module  : pt_641
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.13
%%% @Description: 城战
%%%------------------------------------

-module(pt_641).
-export(
    [
        read/2, 
        write/2
    ]
).

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
%read(64100, _) ->
%    {ok, no};

%read(64101, _) ->
%    {ok, no};

%read(64102, _) ->
%    {ok, no};

read(64103, _) ->
    {ok, no};

read(64104, <<AidTarget:8>>) ->
    {ok, [AidTarget]};

read(64105, <<Type:8>>) ->
    {ok, [Type]};

read(64106, <<GuildId:32, Answer:8>>) ->
    {ok, [GuildId, Answer]};

read(64107, _) ->
    {ok, no};

read(64108, <<Num:32>>) ->
    {ok, [Num]};

read(64109, <<Type:8>>) ->
    {ok, [Type]};

read(64110, <<Type:8>>) ->
    {ok, [Type]};

read(64111, _) ->
    {ok, []};

read(64112, _) ->
    {ok, []};

%% 放下炸弹
read(64113, _R) ->
    {ok, []};

read(64114, _) ->
    {ok, []};

read(64117, _) ->
    {ok, []};

read(64120, _) ->
    {ok, []};

read(64121, _) ->
    {ok, []};

read(64122, _) ->
    {ok, []};

read(_Cmd, _R) ->
    {error, no_match}.

%%%=========================================================================
%%% 组包函数
%%%=========================================================================

%% 广播长安城主信息
write(64100, [GuildName, WinnerName, WinnerSex, ParnerName, RestTime]) ->
    GuildName2 = pt:write_string(util:make_sure_list(GuildName)),
    WinnerName2 = pt:write_string(util:make_sure_list(WinnerName)),
    ParnerName2 = pt:write_string(util:make_sure_list(ParnerName)),
    {ok, pt:pack(64100, <<GuildName2/binary, WinnerName2/binary, WinnerSex:8, ParnerName2/binary, RestTime:32>>)};

%%% 活动开始前广播
write(64101, [RestTime, State, Time, WinnerInfo]) ->
    case WinnerInfo of
        [GuildName, _WinnerName, _WinnerSex, _ParnerName] ->
            ok;
        _ ->
            GuildName = ""
    end,
    GuildName2 = pt:write_string(util:make_sure_list(GuildName)),
    {ok, pt:pack(64101, <<RestTime:32, State:8, Time:32, GuildName2/binary>>)};

%%% 活动开始后广播
write(64102, [RestTime, GuildInfoList, Name1, Sex, Name2]) ->
    Pack = pack4(RestTime, GuildInfoList, Name1, Sex, Name2),
    {ok, pt:pack(64102, Pack)};

%%% 报名信息
write(64103, [Res, Str, AidState, AidTarget, GuildInfoList, Shield1, Shield2, Shield3, Shield4, Shield5]) ->
    Pack = pack1(Res, Str, AidState, AidTarget, GuildInfoList, Shield1, Shield2, Shield3, Shield4, Shield5),
    {ok, pt:pack(64103, Pack)};

%% 援助/取消申请/撤兵
write(64104, [Res, Str]) ->
    Str1 = pt:write_string(util:make_sure_list(Str)),
    {ok, pt:pack(64104, <<Res:8, Str1/binary>>)};

%%% 审批申请信息
write(64105, [Res, Str, ApprovalInfoList, AidInfoList]) ->
    Pack = pack2(Res, Str, ApprovalInfoList, AidInfoList),
    {ok, pt:pack(64105, Pack)};

%% 援助/取消申请/撤兵
write(64106, [Res, Str]) ->
    Str1 = pt:write_string(util:make_sure_list(Str)),
    {ok, pt:pack(64106, <<Res:8, Str1/binary>>)};

%%% 审批抢夺信息
write(64107, [Res, Str, SeizeInfoList, AllCoin]) ->
    Pack = pack3(Res, Str, SeizeInfoList, AllCoin),
    {ok, pt:pack(64107, Pack)};

%% 捐献铜币
write(64108, [Res, Str]) ->
    Str1 = pt:write_string(util:make_sure_list(Str)),
    {ok, pt:pack(64108, <<Res:8, Str1/binary>>)};

%% 进入/退出活动
write(64109, [Res, Str]) ->
    Str1 = pt:write_string(util:make_sure_list(Str)),
    {ok, pt:pack(64109, <<Res:8, Str1/binary>>)};

%% 职业变换
write(64110, [Res, Str]) ->
    Str1 = pt:write_string(util:make_sure_list(Str)),
    {ok, pt:pack(64110, <<Res:8, Str1/binary>>)};

%% 城战面板1(定时广播更新)
write(64111, [List1, List2, List3, NowTowerNum, TotalTowerNum, NowCarNum, TotalCarNum]) ->
    Pack = pack5(List1, List2, List3, NowTowerNum, TotalTowerNum, NowCarNum, TotalCarNum),
    {ok, pt:pack(64111, Pack)};

%% 城战面板2(及时更新)
write(64112, [DoctorNum, MaxNum1, GhostNum, MaxNum2]) ->
    {ok, pt:pack(64112, <<DoctorNum:8, MaxNum1:8, GhostNum:8, MaxNum2:8>>)};

%% 城战面板3(及时更新)
write(64114, [Score]) ->
    {ok, pt:pack(64114, <<Score:32>>)};

%% 结算信息
write(64116, [GuildList1, PlayerList1, GuildList2, PlayerList2, Winner, WinnerName, LoserName]) ->
    Pack = pack6(GuildList1, PlayerList1, GuildList2, PlayerList2, Winner, WinnerName, LoserName),
    {ok, pt:pack(64116, Pack)};

%% 复活剩余时间
write(64117, [RestTime]) ->
    {ok, pt:pack(64117, <<RestTime:8>>)};

%% 审批按钮是否闪烁(定时广播给进攻方、防守方的正副帮主)
write(64118, [Type]) ->
    {ok, pt:pack(64118, <<Type:8>>)};

%% 攻防互换倒计时
write(64119, [Time, AttName, DefName]) ->
    AttName1 = pt:write_string(util:make_sure_list(AttName)),
    DefName1 = pt:write_string(util:make_sure_list(DefName)),
    {ok, pt:pack(64119, <<Time:8, AttName1/binary, DefName1/binary>>)};

%% 领取城战经验BUFF
write(64120, [Res, Str]) ->
    Str1 = pt:write_string(util:make_sure_list(Str)),
    {ok, pt:pack(64120, <<Res:8, Str1/binary>>)};

%% 获取雕像
write(64121, [List]) ->
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
	{ok, pt:pack(64121, <<Len:16, Bin/binary>>)};

%% 获胜帮派
write(64122, [Str]) ->
    Str1 = pt:write_string(util:make_sure_list(Str)),
    {ok, pt:pack(64122, <<Str1/binary>>)};

%% 广播
write(64123, [Type]) ->
    {ok, pt:pack(64123, <<Type:8>>)};

%% 加积分
write(64124, [Score]) ->
    {ok, pt:pack(64124, <<Score:8>>)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.

pack1(Res, Str, AidState, AidTarget, GuildInfoList, Shield1, Shield2, Shield3, Shield4, Shield5) ->
    Fun1 = fun(Elem1) ->
            {Duty, GuildName, NowNum, TotalNum, MasterName, _Lv} = Elem1,
            GuildName1 = pt:write_string(util:make_sure_list(GuildName)),
            MasterName1 = pt:write_string(util:make_sure_list(MasterName)),
            <<Duty:8, GuildName1/binary, NowNum:16, TotalNum:16, MasterName1/binary>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- GuildInfoList]),
    Size1  = length(GuildInfoList),
    Str1 = pt:write_string(util:make_sure_list(Str)),
    <<Res:8, Str1/binary, AidState:8, AidTarget:8, Size1:16, BinList1/binary, Shield1:8, Shield2:8, Shield3:8, Shield4:8, Shield5:8>>.

pack2(Res, Str, ApprovalInfoList, AidInfoList) ->
    Fun1 = fun(Elem1) ->
            {GuildId, GuildName, MasterName, Realm, NowNum, TotalNum} = Elem1,
            GuildName1 = pt:write_string(util:make_sure_list(GuildName)),
            MasterName1 = pt:write_string(util:make_sure_list(MasterName)),
            <<GuildId:32, GuildName1/binary, MasterName1/binary, Realm:8, NowNum:16, TotalNum:16>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- ApprovalInfoList]),
    Size1  = length(ApprovalInfoList),
    BinList2 = list_to_binary([Fun1(X) || X <- AidInfoList]),
    Size2  = length(AidInfoList),
    Str1 = pt:write_string(util:make_sure_list(Str)),
    <<Res:8, Str1/binary, Size1:16, BinList1/binary, Size2:16, BinList2/binary>>.

pack3(Res, Str, SeizeInfoList, AllCoin) ->
    Fun1 = fun(Elem1) ->
            {GuildName, MasterName, Realm, NowNum, TotalNum, Fund} = Elem1,
            GuildName1 = pt:write_string(util:make_sure_list(GuildName)),
            MasterName1 = pt:write_string(util:make_sure_list(MasterName)),
            <<GuildName1/binary, MasterName1/binary, Realm:8, NowNum:16, TotalNum:16, Fund:32>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- SeizeInfoList]),
    Size1  = length(SeizeInfoList),
    Str1 = pt:write_string(util:make_sure_list(Str)),
    <<Res:8, Str1/binary, Size1:16, BinList1/binary, AllCoin:32>>.

pack4(RestTime, GuildInfoList, Name1, Sex, Name2) ->
    Fun1 = fun(Elem1) ->
            {Type, GuildName, Member, MaxMember} = Elem1,
            GuildName1 = pt:write_string(util:make_sure_list(GuildName)),
            <<Type:8, GuildName1/binary, Member:16, MaxMember:16>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- GuildInfoList]),
    Size1  = length(GuildInfoList),
    Name1Str = pt:write_string(Name1),
    Name2Str = pt:write_string(Name2),
    <<RestTime:32, Size1:16, BinList1/binary, Name1Str/binary, Sex:8, Name2Str/binary>>.

pack5(List1, List2, List3, NowTowerNum, TotalTowerNum, NowCarNum, TotalCarNum) ->
    Fun1 = fun(Elem1) ->
            {Type, Per} = Elem1,
            <<Type:8, Per:8>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List1]),
    Size1  = length(List1),
    Fun2 = fun(Elem2) ->
            {GuildName, Num, Score} = Elem2,
            GuildName1 = pt:write_string(GuildName),
            <<GuildName1/binary, Num:32, Score:32>>
    end,
    BinList2 = list_to_binary([Fun2(X) || X <- List2]),
    Size2  = length(List2),
    BinList3 = list_to_binary([Fun2(X) || X <- List3]),
    Size3  = length(List3),
    <<Size1:16, BinList1/binary, Size2:16, BinList2/binary, Size3:16, BinList3/binary, NowTowerNum:8, TotalTowerNum:8, NowCarNum:8, TotalCarNum:8>>.

pack6(GuildList1, PlayerList1, GuildList2, PlayerList2, Winner, WinnerName, LoserName) ->
    Fun1 = fun(Elem1) ->
            {Name, Score} = Elem1,
            Name1 = pt:write_string(util:make_sure_list(Name)),
            <<Name1/binary, Score:32>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- GuildList1]),
    Size1  = length(GuildList1),
    BinList2 = list_to_binary([Fun1(X) || X <- PlayerList1]),
    Size2  = length(PlayerList1),
    BinList3 = list_to_binary([Fun1(X) || X <- GuildList2]),
    Size3  = length(GuildList2),
    BinList4 = list_to_binary([Fun1(X) || X <- PlayerList2]),
    Size4  = length(PlayerList2),
    WinnerName1 = pt:write_string(util:make_sure_list(WinnerName)),
    LoserName1 = pt:write_string(util:make_sure_list(LoserName)),
    <<Size1:16, BinList1/binary, Size2:16, BinList2/binary, Size3:16, BinList3/binary, Size4:16, BinList4/binary, Winner:8, WinnerName1/binary, LoserName1/binary>>.
