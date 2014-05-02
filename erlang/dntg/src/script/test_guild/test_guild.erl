%%%---------------------------------------------
%%% @Module  : test_guild
%%% @Author  : zhenghehe
%%% @Created : 2012.01.07
%%% @Description: 帮派系统测试脚本
%%%---------------------------------------------
-module(test_guild).
-compile(export_all).

start() ->
    case gen_tcp:connect("localhost", 9010, [binary, {packet, 0}]) of
        {ok, Socket1} ->
            gen_tcp:send(Socket1, <<"<policy-file-request/>\0">>),
            rec(Socket1),
            gen_tcp:close(Socket1);
        {error, _Reason1} ->
            io:format("connect failed!~n")
	end,
    case gen_tcp:connect("localhost", 9010, [binary, {packet, 0}]) of
		{ok, Socket} ->
			login(Socket),
            enter(Socket),
			timer:sleep(1000),
			%create_guild(Socket),
            %timer:sleep(5000),
            %apply_disband_guild(Socket),
            %timer:sleep(5000),
            %confirm_disband_guild(Socket),
            %apply_guild_list(Socket),
            %apply_member_list(Socket),
            %get_guild_info(Socket),
            %set_position(Socket),
            %donate_money(Socket),
            %list_donate(Socket),
            %get_paid(Socket),
            %depot_goods_list(Socket),
            %upgrade_hall(Socket),
            %timer:sleep(1000),
            %upgrade_mall(Socket),
            %active_skill(Socket),
            %upgrade_skill(Socket),
			%enter_hall(Socket),
			apply_battle(Socket),
            ok;
		{error, _Reason} ->
            io:format("connect failed!~n")
	end.

%%登陆
login(Socket) ->
    L = byte_size( <<1:16,10000:16,2:32,1273027133:32,3:16,"htc",32:16,"b33d9ace076ca0ac7a8afa56923a03a4">>),
    gen_tcp:send(Socket, <<L:16,10000:16,2:32,1273027133:32,3:16,"htc",32:16,"b33d9ace076ca0ac7a8afa56923a03a4">>),
	rec(Socket).

%%选择角色进入
enter(Socket) ->
    gen_tcp:send(Socket, <<8:16,10004:16, 3:32>>),
	rec(Socket).

%%心跳包
keep_alive(Socket) ->
    L = byte_size(<<1:16, 10006:16>>),
    gen_tcp:send(Socket, <<L:16, 10006:16>>),
	rec(Socket),
    timer:sleep(5000),
    keep_alive(Socket).

rec(Socket) ->
    receive
        {tcp, Socket, <<"<cross-domain-policy><allow-access-from domain='*' to-ports='*' /></cross-domain-policy>">>} -> 
            io:format("revc : ~p~n", ["flash_file"]);
        {tcp, Socket, <<_L:16,Cmd:16, Bin:16>>} -> 
            io:format("revc : ~p~n", [[Cmd, Bin]]);
        {tcp, Socket, <<_L:16, 59004:16, Code:16>>} ->
            io:format("recv: ~p ~p~n", [59004, Code]);
        {tcp, Socket, <<_L:16, 10004:16, Code:8>>} ->
            io:format("revc : ~p~n", [[10004, Code]]),
            case Code =:= 1 of
                true ->
                    spawn(fun()->keep_alive(Socket)end);
                false ->
                    skip
            end;
        {tcp, Socket, <<_L:16, 10000:16, Uid:32>>} ->
            io:format("recv : ~p ~p~n", [10000, Uid]);
        {tcp, Socket, <<_L:16, 10003:16, Res:8, Uid:32>>} ->
            io:format("recv : ~p ~p ~p~n", [10003, Res, Uid]);
        {tcp, Socket, <<_L:16, 10006:16>>} ->
            skip;
        {tcp, Socket, <<_L:16, 40001:16, Bin/binary>>} ->
            {Result, GuildId, GuildName, GuildPosition, UseType, CoinLeft, BindCoinLeft} = pt_400_c:read(40001, Bin),
            io:format("create guild Result[~p] GuildId[~p] GuildName[~p] GuildPosition[~p] UseType[~p] CoinLeft[~p] BindCoinLeft[~p]~n", [Result, GuildId, GuildName, GuildPosition, UseType, CoinLeft, BindCoinLeft]);
        {tcp, Socket, <<_L:16, 40002:16, Bin/binary>>} ->
            Result = pt_400_c:read(40002, Bin),
            io:format("apply disband guild result[~p]~n", [Result]);
        {tcp, Socket, <<_L:16, 40003:16, Bin/binary>>} ->
            {Flag, GuildId, GuildName, Result} = pt_400_c:read(40003, Bin),
            io:format("confirm disband guild Flag[~p], GuildId[~p], GuildName[~p], Result[~p]~n", [Flag, GuildId, GuildName, Result]);
        {tcp, Socket, <<_L:16, 40010:16, Bin/binary>>} ->
            {Result, PageTotal, PageNo, RecordNum, L} = pt_400_c:read(40010, Bin),
            io:format("apply guild list Result[~p] Pagetotal[~p] PageNo[~p] RecordNum[~p] L[~p]~n", [Result, PageTotal, PageNo, RecordNum, L]);
        {tcp, Socket, <<_L:16, 40011:16, Bin/binary>>} ->
            {Result, PageTotal, PageNo, RecordNum, L} = pt_400_c:read(40011, Bin),
            io:format("apply member list Result[~p] Pagetotal[~p] PageNo[~p] RecordNum[~p] L[~p]~n", [Result, PageTotal, PageNo, RecordNum, L]);
        {tcp, Socket, <<_L:16, 40014:16, Bin/binary>>} ->
            {Result, T} = pt_400_c:read(40014, Bin),
            case Result of
                1 ->
                    {GuildId, GuildName, GuildTenet, GuildAnnounce, InitiatorId, InitiatorName, ChiefId, ChiefName, DeputyChief1Id, DeputyChief1Name, DeputyChief2Id, DeputyChief2Name, DeputyChiefNum,MemberNum,NewMemberCapacity,Realm,Level,Reputation,Funds,Contribution,ContributionDaily,CombatNum,CombatVictoryNum,QQ,CreateTime, ContributionThreshold, DepotLevel, HallLevel, DepotNextLevelCoin, DepotNextLevelContribution, HallNextLevelCoin,  HallNextLevelContribution, DisbandFlag, DisbandConfirmTime, CreateType, HouseLevel, HouseNextLevelGold, RenameFlag, MallLevel,MallContri,MallContriCostDaily,MallFundsCostDaily,MallContriCostUpgrade,MallFundsCostUpgrade} = T,
                    io:format("get guild info ~p~n", [[GuildId, GuildName, GuildTenet, GuildAnnounce, InitiatorId, InitiatorName, ChiefId, ChiefName, DeputyChief1Id, DeputyChief1Name, DeputyChief2Id, DeputyChief2Name, DeputyChiefNum,MemberNum,NewMemberCapacity,Realm,Level,Reputation,Funds,Contribution,ContributionDaily,CombatNum,CombatVictoryNum,QQ,CreateTime, ContributionThreshold, DepotLevel, HallLevel, DepotNextLevelCoin, DepotNextLevelContribution, HallNextLevelCoin,  HallNextLevelContribution, DisbandFlag, DisbandConfirmTime, CreateType, HouseLevel, HouseNextLevelGold, RenameFlag, MallLevel,MallContri,MallContriCostDaily,MallFundsCostDaily,MallContriCostUpgrade,MallFundsCostUpgrade]]);
                _ ->
                    skip
            end;
        {tcp, Socket, <<_L:16, 40017:16, Bin/binary>>} ->
            Result = pt_400_c:read(40017, Bin),
            io:format("set position Result[~p]~n", [Result]);
        {tcp, Socket, <<_L:16, 40019:16, Bin/binary>>} ->
            {Result, CoinLeft, BindCoinLeft, DonationAdd, PaidAdd} = pt_400_c:read(40019, Bin),
            io:format("donate money ~p~n", [[Result, CoinLeft, BindCoinLeft, DonationAdd, PaidAdd]]);
        {tcp, Socket, <<_L:16, 40021:16, Bin/binary>>} ->
            {Result, PageTotal, PageNo, RecordNum, L} = pt_400_c:read(40021, Bin),
            io:format("list donate ~p~n", [[Result, PageTotal, PageNo, RecordNum, L]]);
        {tcp, Socket, <<_L:16, 40023:16, Bin/binary>>} ->
            {Result, Num, BindCoinLeft} = pt_400_c:read(40023, Bin),
            io:format("get paid ~p~n", [[Result, Num, BindCoinLeft]]);
        {tcp, Socket, <<_L:16, 40027:16, Bin/binary>>} ->
            {Result, RecordNum, L} = pt_400_c:read(40027, Bin),
            io:format("depot goods list ~p~n", [[Result, RecordNum, L]]);
        {tcp, Socket, <<_L:16, 40032:16, Bin/binary>>} ->
            {Result, GuildId, OldLevel, NewLevel, ContributionUse, FunsUse} = pt_400_c:read(40032, Bin),
            io:format("upgrade hall ~p~n", [[Result, GuildId, OldLevel, NewLevel, ContributionUse, FunsUse]]);
        {tcp, Socket, <<_L:16, 40033:16, Bin/binary>>} ->
            {Result, GuildId, OldLevel, NewLevel, NewMemberCapacity, DonationAdd, PaidAdd} = pt_400_c:read(40033, Bin),
            io:format("upgrade house ~p~n", [[Result, GuildId, OldLevel, NewLevel, NewMemberCapacity, DonationAdd, PaidAdd]]);
        {tcp, Socket, <<_L:16, 40090:16, Bin/binary>>} ->
            {Result, GuildId, OldMallLevel, NewMallLevel, ContributionCost, FundsCost} = pt_400_c:read(40090, Bin),
            io:format("update mall ~p~n", [[Result, GuildId, OldMallLevel, NewMallLevel, ContributionCost, FundsCost]]);
        {tcp, Socket, <<_L:16, 40065:16, Bin/binary>>} ->
            {Result, ActiveSkillId} = pt_400_c:read(40065, Bin),
            io:format("active skill ~p~n", [[Result, ActiveSkillId]]);
        {tcp, Socket, <<_L:16, 40064:16, Bin/binary>>} ->
            {Result, SkillId, SkillLevel} = pt_400_c:read(40064, Bin),
            io:format("upgrade skill ~p~n", [[Result, SkillId, SkillLevel]]);
		{tcp, Socket, <<_L:16, 40035:16, Bin/binary>>} ->
			{Result, HallEnterLeftTime} = pt_400_c:read(40035, Bin),
			io:format("enter hall ~p~n", [[Result, HallEnterLeftTime]]);
		{tcp, Socket, <<_L:16, 12005:16, Bin/binary>>} ->
			{_Scene, _X, _Y, _Name, _Sid} = pt_400_c:read(12005, Bin),
			{ok, Bin1} = pt_400_c:write(12002, []),
			gen_tcp:send(Socket, Bin1),
    		rec(Socket),
    		rec(Socket);
		{tcp, Socket, <<_L:16, 12002:16, Bin/binary>>} ->
			io:format("12002 ~p~n", [Bin]);
		{tcp, Socket, <<_L:16, 50001:16, Bin/binary>>} ->
			Error = pt_500_c:read(50001, Bin),
			io:format("apply battle ~p~n", [Error]);
		{tcp, Socket, <<_L:16, 50003:16, Bin/binary>>} ->
			{Error, Zone} = pt_500_c:read(50003, Bin),
			io:format("enter battle ~p~n", [[Error, Zone]]),
			case Error =:= 1 of
				true ->
					load_scene(Socket);
				false ->
					skip
			end;
		{tcp, Socket, <<_L:16, 50004:16, Bin/binary>>} ->
			Error = pt_500_c:read(50004, Bin),
			io:format("leave battle ~p~n", [Error]),
			case Error =:= 1 of
				true ->
					load_scene(Socket);
				false ->
					skip
			end;
		{tcp, Socket, <<_L:16, 50007:16, Bin/binary>>} ->
			io:format("battle info ~p~n", [Bin]);
		{tcp, Socket, <<_L:16, 50015:16, Bin/binary>>} ->
			io:format("apply list ~p~n", [Bin]);
		{tcp, Socket, <<_L:16, 50017:16, Bin/binary>>} ->
			io:format("battle final score ~p~n", [Bin]);
		{tcp, Socket, <<_L:16, 50018:16, Bin/binary>>} ->
			io:format("total_guild_battle_rank ~p~n", [Bin]);
		{tcp, Socket, <<_L:16, 50021:16, Bin/binary>>} ->
			<<Error:16>> = Bin,
			io:format("use angry ~p~n", [Error]);
		{tcp, Socket, <<_L:16, 50022:16, Bin/binary>>} ->
			<<Result:8, Score:32>> = Bin,
			io:format("query score ~p~n", [[Result, Score]]);
		{tcp, Socket, <<_L:16, 50025:16, Bin/binary>>} ->
			<<Result:16, Score:32, Exp:32, Llpt:32>> = Bin,
			io:format("get award ~p~n", [[Result, Score, Exp, Llpt]]);
        {tcp, Socket, <<_L:16, _Cmd:16, _Bin/binary>>} ->
            skip;
        {tcp_closed, Socket} ->
            gen_tcp:close(Socket),
			erlang:exit(1)
	after 500 ->
        ok
    end.

create_guild(Socket) ->
    {ok, Bin} = pt_400_c:write(40001, [0, "响亮的帮派名字", "响亮的帮派公告"]),
    gen_tcp:send(Socket, Bin),
	rec(Socket),
	rec(Socket).

apply_disband_guild(Socket) ->
    {ok, Bin} = pt_400_c:write(40002, [646]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

confirm_disband_guild(Socket) ->
    {ok, Bin} = pt_400_c:write(40003, [646, 1]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

apply_guild_list(Socket) ->
    {ok, Bin} = pt_400_c:write(40010, [5,1]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

apply_member_list(Socket) ->
    {ok, Bin} = pt_400_c:write(40011, [647, 5, 1]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

get_guild_info(Socket) ->
    {ok, Bin} = pt_400_c:write(40014, [647]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

set_position(Socket) ->
    {ok, Bin} = pt_400_c:write(40017, [4, 2]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

donate_money(Socket) ->
    {ok, Bin} = pt_400_c:write(40019, [647, 200000]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

list_donate(Socket) ->
    {ok, Bin} = pt_400_c:write(40021, [647, 5, 1]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

get_paid(Socket) ->
    {ok, Bin} = pt_400_c:write(40023, [647]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

depot_goods_list(Socket) ->
    {ok, Bin} = pt_400_c:write(40027, [647]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

upgrade_hall(Socket) ->
    {ok, Bin} = pt_400_c:write(40032, [647]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

upgrade_house(Socket) ->
    {ok, Bin} = pt_400_c:write(40033, [647]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

upgrade_mall(Socket) ->
    {ok, Bin} = pt_400_c:write(40090, [647]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

active_skill(Socket) ->
    {ok, Bin} = pt_400_c:write(40065, [20571]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

upgrade_skill(Socket) ->
    {ok, Bin} = pt_400_c:write(40064, [20571]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

enter_hall(Socket) ->
	{ok, Bin} = pt_400_c:write(40035, [1]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

apply_battle(Socket) ->
	{ok, Bin} = pt_500_c:write(50001, []),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

enter_battle(Socket) ->
	{ok, Bin} = pt_500_c:write(50003, []),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

load_scene(Socket) ->
	gen_tcp:send(Socket, <<4:16,12002:16>>),
	rec(Socket),
    rec(Socket).

leave_battle(Socket) ->
	{ok, Bin} = pt_500_c:write(50004, []),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

battle_info(Socket) ->
	{ok, Bin} = pt_500_c:write(50007, []),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

apply_list(Socket) ->
	{ok, Bin} = pt_500_c:write(50015, [5, 1]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

battle_final_score(Socket) ->
	{ok, Bin} = pt_500_c:write(50017, []),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

total_guild_battle_rank(Socket) ->
	{ok, Bin} = pt_500_c:write(50018, [5, 1]),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

use_angry(Socket) ->
	{ok, Bin} = pt_500_c:write(50021, []),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

query_score(Socket) ->
	{ok, Bin} = pt_500_c:write(50022, []),
    gen_tcp:send(Socket, Bin),
    rec(Socket),
    rec(Socket).

get_award(Socket) ->
	gen_tcp:send(Socket, <<4:16,50025:16>>),
	rec(Socket),
    rec(Socket).