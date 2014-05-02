%%%--------------------------------------
%%% @Module  : pt_48
%%% @Author  : 
%%% @Email   : 
%%% @Created : 2010.12.17
%%% @Description: 诸神消息的解包和组包
%%%--------------------------------------
-module(pt_485).
-export([read/2, write/2]).

%%%=========================================================================
%%% 解包函数
%%%=========================================================================

read(48500, <<>>) ->
    {ok, []};

read(48501, <<>>) ->
    {ok, []};

read(48502, <<>>) ->
    {ok, []};

read(48503, <<>>) ->
    {ok, []};

read(48504, <<>>) ->
    {ok, []};

read(48505, <<RoomNo:8>>) ->
    {ok, [RoomNo]};

read(48506, <<BinData/binary>>) ->
	{Flat, Bin1} = pt:read_string(BinData),
	<<Server_id:16,Id:32>> = Bin1,
    {ok, [Flat,Server_id,Id]};

read(48511, <<>>) ->
    {ok, []};

read(48512, <<Room_no:16>>) ->
    {ok, [Room_no]};

read(48514, <<BinData/binary>>) ->
	{Flat, Bin1} = pt:read_string(BinData),
	<<Server_id:16,Id:32>> = Bin1,
    {ok, [Flat,Server_id,Id]};

read(48515, <<>>) ->
    {ok, []};

read(48516, <<God_no:16>>) ->
    {ok, [God_no]};

read(48517, <<BinData/binary>>) ->
	{Flat, Bin1} = pt:read_string(BinData),
	<<Server_id:16,Id:32,God_no:16,Type:8>> = Bin1,
	{ok, [Flat,Server_id,Id,God_no,Type]};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================
write(48500, [ErroCode]) ->
    Data = <<ErroCode:8>>,
    {ok, pt:pack(48500, Data)};

write(48501, [Mod,Status,ResTime,God_no]) ->
    Data = <<Mod:8,Status:8,ResTime:32,God_no:16>>,
    {ok, pt:pack(48501, Data)};

write(48502, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(48502, Data)};

write(48503, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(48503, Data)};

write(48504, [My_room_no,Max_Room_Num,RoomList]) ->
	RoomListLen = length(RoomList),
	RoomListBin = write_RoomList(RoomList,<<RoomListLen:16>>),
    Data = <<My_room_no:8,Max_Room_Num:8,RoomListBin/binary>>,
    {ok, pt:pack(48504, Data)};

write(48505, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(48505, Data)};

write(48506, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(48506, Data)};

write(48507, [APlatform,AServer_num,AId,Aname,Acountry,Asex,Acarrer,Aimage,Alv,Apower]) ->
	APlatformBin = pt:write_string(APlatform),
	AnameBin = pt:write_string(Aname),
    Data = <<APlatformBin/binary,AServer_num:16,AId:32,AnameBin/binary,
			 Acountry:8,Asex:8,Acarrer:8,Aimage:8,Alv:16,Apower:32>>,
    {ok, pt:pack(48507, Data)};

write(48508, [Max_dead_num,My_dead_num,He_dead_num,My_win_loop,My_loop]) ->
    Data = <<Max_dead_num:8,My_dead_num:8,He_dead_num:8,My_win_loop:16,My_loop:16>>,
	{ok, pt:pack(48508, Data)};

write(48509, [My_score,My_win_loop,My_loop,He_score,He_win_loop,He_loop,Is_loop,Is_win]) ->
    Data = <<My_score:32,My_win_loop:16,My_loop:16,He_score:32,He_win_loop:16,He_loop:16,Is_loop:8,Is_win:8>>,
	{ok, pt:pack(48509, Data)};

write(48510, [Mod,Result,Win_loop,Loop,Score]) ->
    Data = <<Mod:8,Result:8,Win_loop:16,Loop:16,Score:32>>,
    {ok, pt:pack(48510, Data)};

write(48511, [PkList]) ->
	PkListLen = length(PkList),
	PkListBin = write_PkList(PkList,<<PkListLen:16>>),
	Data = <<PkListBin/binary>>,
	{ok, pt:pack(48511, Data)};

write(48512, [Mod,TopList,MyScore]) ->
	TopListLen = length(TopList),
	TopListBin = write_TopList(TopList,<<TopListLen:16>>),
	Data = <<Mod:8,TopListBin/binary,MyScore:32>>,
	{ok, pt:pack(48512, Data)};

write(48513, [God_no,Sea_win_loop,Sea_loop,Group_win_loop,
			  Group_loop,Sort_win_loop,Sort_loop,Pos,People_no,Score]) ->
	Data = <<God_no:16,Sea_win_loop:16,Sea_loop:16,Group_win_loop:16,
			  Group_loop:16,Sort_win_loop:16,Sort_loop:16,Pos:16,People_no:16,Score:32>>,
	{ok, pt:pack(48513, Data)};

write(48514, [Result,Flat,Server_id,Id]) ->
	FlatBin = pt:write_string(Flat),
    Data = <<Result:8,FlatBin/binary,Server_id:16,Id:32>>,
    {ok, pt:pack(48514, Data)};

write(48515, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(48515, Data)};

write(48516, [TopList,RestBs]) ->
	TopListLen = length(TopList),
	TopListBin = write_Top50List(TopList,<<TopListLen:16>>),
	Data = <<TopListBin/binary,RestBs:8>>,
	{ok, pt:pack(48516, Data)};

write(48517, [Flat,Server_id,Id,God_no,Type,Result,RestBs]) ->
	FlatBin = pt:write_string(Flat),
    Data = <<FlatBin/binary,Server_id:16,Id:32,God_no:16,Type:8,Result:8,RestBs:8>>,
    {ok, pt:pack(48517, Data)};
	
%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

%%房间列表
%%@param RoomList [{key,[values]}]
write_RoomList(RoomList,Bin)->
	case RoomList of
		[{Id,Num}|T]->
			New_Bin = <<Bin/binary,Id:8,Num:8>>,
			write_RoomList(T,New_Bin);
		_->Bin
	end.

%%积分榜列表
write_PkList(PkList,Bin)->
	case PkList of
		[{APlatform,AServer_num,AId,Aname,Acountry,Asex,Acarrer,Aimage,Alv,Apower,IsWin,Score}|T]->
			APlatformBin = pt:write_string(APlatform),
			AnameBin = pt:write_string(Aname),
			New_Bin = <<Bin/binary,APlatformBin/binary,AServer_num:16,AId:32,AnameBin/binary,Acountry:8,
						Asex:8,Acarrer:8,Aimage:8,Alv:16,Apower:32,IsWin:8,Score:32>>,
			write_PkList(T,New_Bin);
		_->Bin
	end.

write_TopList(TopList,Bin)->
	case TopList of
		[{No,APlatform,AServer_num,AId,Aname,Acountry,Asex,
		  Acarrer,Aimage,Alv,Apower,Win_loop,Loop,Score,Group_no,
		  Group_vote,Relive_vote,Sort_vote}|T]->
			APlatformBin = pt:write_string(APlatform),
			AnameBin = pt:write_string(Aname),
			New_Bin = <<Bin/binary,No:16,APlatformBin/binary,AServer_num:16,AId:32,AnameBin/binary,Acountry:8,
						Asex:8,Acarrer:8,Aimage:8,Alv:16,Apower:32,Win_loop:16,Loop:16,Score:32,Group_no:16,
						Group_vote:16,Relive_vote:16,Sort_vote:16>>,
			write_TopList(T,New_Bin);
		_->Bin
	end.

write_Top50List(TopList,Bin)->
	case TopList of
		[{APlatform,AServer_num,AId,God_no,Aname,Acountry,Asex,
		  Acarrer,Aimage,Alv,Apower,Sea_win_loop,Sea_loop,Sea_score,
		  Group_room_no,Group_win_loop,Group_loop,Group_score,Group_vote,
		  Group_relive_is_up,Relive_win_loop,Relive_loop,Relive_score,Relive_vote,
		  Sort_win_loop,Sort_loop,Sort_score,Sort_vote,Praise,Despise}|T]->
			APlatformBin = pt:write_string(APlatform),
			AnameBin = pt:write_string(Aname),
			New_Bin = <<Bin/binary,APlatformBin/binary,AServer_num:16,AId:32,God_no:16,AnameBin/binary,Acountry:8,Asex:8,
		  Acarrer:8,Aimage:8,Alv:16,Apower:32,Sea_win_loop:16,Sea_loop:16,Sea_score:32,
		  Group_room_no:16,Group_win_loop:16,Group_loop:16,Group_score:32,Group_vote:32,
		  Group_relive_is_up:8,Relive_win_loop:16,Relive_loop:16,Relive_score:32,Relive_vote:32,
		  Sort_win_loop:16,Sort_loop:16,Sort_score:32,Sort_vote:32,Praise:32,Despise:32>>,
			write_Top50List(T,New_Bin);
		_->Bin
	end.

