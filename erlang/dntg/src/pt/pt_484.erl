%%%--------------------------------------
%%% @Module : pt_484
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3协议处理
%%%--------------------------------------

-module(pt_484).
-include("kf_3v3.hrl").
-export([read/2, write/2]).

read(48401, _) ->
    {ok, get_status};

read(48402, _) ->
    {ok, enter_prepare};

read(48403, _) ->
    {ok, []};

read(48405, _) ->
    {ok, get_list};

read(48406, _) ->
    {ok, get_info};

read(48410, _) ->
    {ok, single_sign_up};

read(48412, <<>>) ->
    {ok, []};

read(48414, _) ->
    {ok, get_rank};

read(48417, _) ->
    {ok, reset_pk_status};

read(48424, <<ServerNum:16, Id:32, Platform/binary>>) ->
	{NewPlat, _} = pt:read_string(Platform),
    {ok, [NewPlat, ServerNum, Id]};
  
read(48430, _) ->
    {ok, onhook};

read(_Cmd, _R) ->
    {error, no_match}.


write(48401, Status) ->
	Data = <<Status:8>>,
	{ok, pt:pack(48401, Data)};

write(48402, [ErrorCode]) ->
	Data = <<ErrorCode:8>>,
	{ok, pt:pack(48402, Data)};

write(48403, Result) ->
	Data = <<Result:8>>,
	{ok, pt:pack(48403, Data)};

write(48404, [Status, Loop, LeftTime, PkNum, PkWinNum, SignUp]) ->
	Data = <<Status:8, Loop:8, LeftTime:16, PkNum:16, PkWinNum:16, SignUp:8>>,
	{ok, pt:pack(48404, Data)};

write(48405, List) ->
	LastList = 
	lists:map(fun(Rd) -> 
		Result = Rd#bd_3v3_fight.result,

		AList = lists:map(fun([APlatform, AServerNum, AId, AName, ACountry, ASex, ACareer, ALv, APower]) -> 
			APlatform2 = pt:write_string(APlatform),
			AName2 = pt:write_string(AName),
			<<APlatform2/binary, AServerNum:16, AId:32, AName2/binary, ACountry:8, ASex:8, ACareer:8, ALv:8, APower:32>>
		end, Rd#bd_3v3_fight.player_a),
		ALen = length(AList),
		ABin = list_to_binary(AList),
		
		BList = lists:map(fun([BPlatform, BServerNum, BId, BName, BCountry, BSex, BCareer, BLv, BPower]) -> 
			BPlatform2 = pt:write_string(BPlatform),
			BName2 = pt:write_string(BName),
			<<BPlatform2/binary, BServerNum:16, BId:32, BName2/binary, BCountry:8, BSex:8, BCareer:8, BLv:8, BPower:32>>
		end, Rd#bd_3v3_fight.player_b),
		BLen = length(BList),
		BBin = list_to_binary(BList),

		<<Result:8, ALen:16, ABin/binary, BLen:16, BBin/binary>>
	end, List),
	LastLen = length(LastList),
	LastBin = list_to_binary(LastList),
	Data = <<LastLen:16, LastBin/binary>>,
	{ok, pt:pack(48405, Data)};

write(48406, [PkNum, PkWinNum, Pt, Score, Mvp]) ->
	Data = <<PkNum:16, PkWinNum:16, Pt:32, Score:32, Mvp:16>>,
	{ok, pt:pack(48406, Data)};

write(48407, [APower, AList, BPower, BList]) ->
	ALen = length(AList),
	Abin = list_to_binary(AList),
	BLen = length(BList),
	Bbin = list_to_binary(BList),
	Data = <<APower:32, ALen:16, Abin/binary, BPower:32, BLen:16, Bbin/binary>>,
	{ok, pt:pack(48407, Data)};

write(48408, [PkResult, GoodsNum, AddScore, AddPt, AddExp, 
	OccupyNumA, OccupyValueA, OccupyNumB, OccupyValueB, PlayerList, DoubleAward]) ->
	Len = length(PlayerList),
	Bin = list_to_binary(PlayerList),
	Data = <<PkResult:8, GoodsNum:16, AddScore:32, AddPt:32, AddExp:32, 
	OccupyNumA:8, OccupyValueA:16, OccupyNumB:8, OccupyValueB:16, DoubleAward:8, Len:16, Bin/binary>>,
	{ok, pt:pack(48408, Data, 1)};

write(48409, []) ->
	Data = <<>>,
	{ok, pt:pack(48409, Data)};

write(48410, [Result, CDTime]) ->
	Data = <<Result:8, CDTime:16>>,
	{ok, pt:pack(48410, Data)};

write(48411, [Platform,Server_num,Id,Name,Country]) ->
	PlatformBin = pt:write_string(Platform),
	NameBin = pt:write_string(Name),
	Data = <<PlatformBin/binary,Server_num:16,Id:32,NameBin/binary,Country:8>>,
	{ok, pt:pack(48411, Data)};

write(48412, [LeftTime, OccupyNumA, OccupyValueA, OccupyNumB, OccupyValueB, SortList]) ->
	Len = length(SortList),
	Bin = list_to_binary(SortList),
	Data = <<LeftTime:16, OccupyNumA:8, OccupyValueA:16, OccupyNumB:8, OccupyValueB:16, Len:16, Bin/binary>>,
	{ok, pt:pack(48412, Data)};

write(48414, [MyNo, TopList]) ->
	Len = length(TopList),
	Bin = list_to_binary(TopList),
	Data = <<MyNo:16, Len:16, Bin/binary>>,
	{ok, pt:pack(48414, Data)};

write(48417, [Result]) ->
	Data = <<Result:8>>,
	{ok, pt:pack(48417, Data)};

write(48424, [Result, CdTime]) ->
	Data = <<Result:8, CdTime:16>>,
	{ok, pt:pack(48424, Data)};

write(48430, Result) ->
	Data = <<Result:8>>,
	{ok, pt:pack(48430, Data)};

write(_Cmd, _R) ->
	{ok, pt:pack(0, <<>>)}.
