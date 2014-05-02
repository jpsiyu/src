%%%--------------------------------------
%%% @Module  : pt_48
%%% @Author  : 
%%% @Email   : 
%%% @Created : 2010.12.17
%%% @Description: 1v1消息的解包和组包
%%%--------------------------------------
-module(pt_483).
-export([read/2, write/2]).

%%%=========================================================================
%%% 解包函数
%%%=========================================================================
%% 1v1错误码
read(48300, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 1v1状态检测
%% -----------------------------------------------------------------
read(48301, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 进入准备区
%% -----------------------------------------------------------------
read(48302, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 退出准备区
%% -----------------------------------------------------------------
read(48303, <<>>) ->
    {ok, []};

read(48305, <<>>) ->
    {ok, []};

read(48306, <<>>) ->
    {ok, []};

read(48310, <<>>) ->
    {ok, []};

read(48312, <<>>) ->
    {ok, []};

read(48313, <<Loop:16,BinData/binary>>) ->
	{A_Flat, Bin1} = pt:read_string(BinData),
	<<A_Server_id:16,A_Id:32,Bin2/binary>> = Bin1,
	{B_Flat, Bin3} = pt:read_string(Bin2),
	<<B_Server_id:16,B_Id:32>> = Bin3,
    {ok, [Loop,A_Flat,A_Server_id,A_Id,B_Flat,B_Server_id,B_Id]};

read(48314, <<>>) ->
    {ok, []};

read(48315, <<>>) ->
    {ok, []};
%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================
write(48300, [ErroCode]) ->
    Data = <<ErroCode:8>>,
    {ok, pt:pack(48300, Data)};

write(48301, [Status]) ->
    Data = <<Status:8>>,
    {ok, pt:pack(48301, Data)};

write(48302, [Result,Loop,State,RestTime,WholeRestTime,CurrentLoop,MyLoop,IsSign,Loop_day]) ->
    Data = <<Result:8,Loop:16,State:8,RestTime:16,WholeRestTime:16,CurrentLoop:16,MyLoop:16,IsSign:8,Loop_day:16>>,
	{ok, pt:pack(48302, Data)};

write(48303, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(48303, Data)};

write(48304, [Loop,State,RestTime,WholeRestTime,CurrentLoop,MyLoop,IsSign,Loop_day]) ->
    Data = <<Loop:16,State:8,RestTime:16,WholeRestTime:16,CurrentLoop:16,MyLoop:16,IsSign:8,Loop_day:16>>,
    {ok, pt:pack(48304, Data)};

write(48305, [PkList]) ->
	PkListLen = length(PkList),
	PkListBin = write_PkList(PkList,<<PkListLen:16>>),
    Data = <<PkListBin/binary>>,
    {ok, pt:pack(48305, Data)};

write(48306, [MyLoop,MyWinRate,MyHpRate,MyPt,MyScore]) ->
    Data = <<MyLoop:16,MyWinRate:16,MyHpRate:16,MyPt:32,MyScore:32>>,
    {ok, pt:pack(48306, Data)};

write(48307, [APlatform,AServer_num,AId,Aname,Acountry,Asex,Acarrer,Aimage,Alv,Apower,Alucky,
			  BPlatform,BServer_num,BId,Bname,Bcountry,Bsex,Bcarrer,Bimage,Blv,Bpower,Blucky]) ->
	APlatformBin = pt:write_string(APlatform),
	BPlatformBin = pt:write_string(BPlatform),
	AnameBin = pt:write_string(Aname),
	BnameBin = pt:write_string(Bname),
    Data = <<APlatformBin/binary,AServer_num:16,AId:32,AnameBin/binary,Acountry:8,Asex:8,Acarrer:8,Aimage:8,Alv:16,Apower:32,Alucky:16,
			 BPlatformBin/binary,BServer_num:16,BId:32,BnameBin/binary,Bcountry:8,Bsex:8,Bcarrer:8,Bimage:8,Blv:16,Bpower:32,Blucky:16>>,
    {ok, pt:pack(48307, Data)};

write(48308, [WinPlatform,WinServer_num,WinId,APlatform,AServer_num,AId,Aname,Acountry,Asex,Acarrer,Aimage,Alv,Apower,Alucky,AminHp,AmaxHp,
			  BPlatform,BServer_num,BId,Bname,Bcountry,Bsex,Bcarrer,Bimage,Blv,Bpower,Blucky,BminHp,BmaxHp,
			  ALastPt,APt,ALastScore,AScore,BLastPt,BPt,BLastScore,BScore,Loop]) ->
    WinPlatformBin = pt:write_string(WinPlatform),
	APlatformBin = pt:write_string(APlatform),
	BPlatformBin = pt:write_string(BPlatform),
	AnameBin = pt:write_string(Aname),
	BnameBin = pt:write_string(Bname),
	Data = <<WinPlatformBin/binary,WinServer_num:16,WinId:32,APlatformBin/binary,AServer_num:16,AId:32,AnameBin/binary,Acountry:8,Asex:8,Acarrer:8,Aimage:8,Alv:16,Apower:32,Alucky:16,AminHp:32,AmaxHp:32,
			 BPlatformBin/binary,BServer_num:16,BId:32,BnameBin/binary,Bcountry:8,Bsex:8,Bcarrer:8,Bimage:8,Blv:16,Bpower:32,Blucky:16,BminHp:32,BmaxHp:32,
			 ALastPt:32,APt:32,ALastScore:32,AScore:32,BLastPt:32,BPt:32,BLastScore:32,BScore:32,Loop:16>>,
	{ok, pt:pack(48308, Data)};

write(48309, []) ->
    Data = <<>>,
    {ok, pt:pack(48309, Data)};

write(48310, [Result]) ->
    Data = <<Result:8>>,
	{ok, pt:pack(48310, Data)};

write(48311, [Platform,Server_num,Id,Name,Country]) ->
	PlatformBin = pt:write_string(Platform),
	NameBin = pt:write_string(Name),
    Data = <<PlatformBin/binary,Server_num:16,Id:32,NameBin/binary,Country:8>>,
	{ok, pt:pack(48311, Data)};

write(48312, [WarList]) ->
	WarListLen = length(WarList),
	WarListBin = write_WarList(WarList,<<WarListLen:16>>),
    Data = <<WarListBin/binary>>,
	{ok, pt:pack(48312, Data)};

write(48313, [Result]) ->
    Data = <<Result:8>>,
	{ok, pt:pack(48313, Data)};

write(48314, [MyNo,Top100List]) ->
	Top100ListLen = length(Top100List),
	Top100ListBen = write_Top100List(Top100List,<<Top100ListLen:16>>),
	Data = <<MyNo:16,Top100ListBen/binary>>,
    {ok, pt:pack(48314, Data)};

write(48315, [Result]) ->
    Data = <<Result:8>>,
	{ok, pt:pack(48315, Data)};
%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

write_PkList(PkList,Bin)->
	case PkList of
		[]->Bin;
		[{IsWin,Loop,MyPower,BId,Bname,Bcountry,Bsex,Bcarrer,Bimage,Blv,Bpower}|T]->
			BnameBin = pt:write_string(Bname),
			New_Bin = <<Bin/binary,IsWin:8,Loop:16,MyPower:16,BId:32,BnameBin/binary,Bcountry:8,Bsex:8,Bcarrer:8,Bimage:8,Blv:16,Bpower:32>>,
			write_PkList(T,New_Bin)
	end.
write_Top100List(Top100List,Bin)->
	case Top100List of
		[]->Bin;
		[{_BPlatform,_BServer_num,BId,Bname,Bcountry,Bsex,Bcarrer,Bimage,Loops,WinRate,HpRate,Pt,Score,Lv}|T]->
			BnameBin = pt:write_string(Bname),
			New_Bin = <<Bin/binary,BId:32,BnameBin/binary,Bcountry:8,Bsex:8,Bcarrer:8,Bimage:8,Loops:16,WinRate:16,HpRate:16,Pt:32,Score:32,Lv:16>>,
			write_Top100List(T,New_Bin)
	end.

write_WarList([],Bin)->Bin;
write_WarList([{Loop,APlatform,AServer_num,AId,Aname,Acountry,Asex,Acarrer,Aimage,Alv,Apower,
				BPlatform,BServer_num,BId,Bname,Bcountry,Bsex,Bcarrer,Bimage,Blv,Bpower}|T],Bin)->
	APlatformBin = pt:write_string(APlatform),
	BPlatformBin = pt:write_string(BPlatform),
	AnameBin = pt:write_string(Aname),
	BnameBin = pt:write_string(Bname),
	write_WarList(T,<<Bin/binary,Loop:16,APlatformBin/binary,AServer_num:16,AId:32,AnameBin/binary,Acountry:8,Asex:8,Acarrer:8,Aimage:8,Alv:16,Apower:32,
			 BPlatformBin/binary,BServer_num:16,BId:32,BnameBin/binary,Bcountry:8,Bsex:8,Bcarrer:8,Bimage:8,Blv:16,Bpower:32>>).
	
