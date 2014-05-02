%%%--------------------------------------
%%% @Module  : pt_48
%%% @Author  : 
%%% @Email   : 
%%% @Created : 2010.12.17
%%% @Description: 1v1消息的解包和组包
%%%--------------------------------------
-module(pt_482).
-export([read/2, write/2]).

%%%=========================================================================
%%% 解包函数
%%%=========================================================================
%% 1v1错误码
read(48200, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 1v1状态检测
%% -----------------------------------------------------------------
read(48201, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 进入准备区
%% -----------------------------------------------------------------
read(48202, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 退出准备区
%% -----------------------------------------------------------------
read(48203, <<>>) ->
    {ok, []};

read(48205, <<>>) ->
    {ok, []};

read(48206, <<>>) ->
    {ok, []};

read(48210, <<>>) ->
    {ok, []};
%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================
write(48200, [ErroCode]) ->
    Data = <<ErroCode:8>>,
    {ok, pt:pack(48200, Data)};

write(48201, [Status]) ->
    Data = <<Status:8>>,
    {ok, pt:pack(48201, Data)};

write(48202, [Result,Loop,State,RestTime,WholeRestTime,CurrentLoop]) ->
    Data = <<Result:8,Loop:8,State:8,RestTime:16,WholeRestTime:16,CurrentLoop:8>>,
    {ok, pt:pack(48202, Data)};

write(48203, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(48203, Data)};

write(48204, [Loop,State,RestTime,WholeRestTime,CurrentLoop]) ->
    Data = <<Loop:8,State:8,RestTime:16,WholeRestTime:16,CurrentLoop:8>>,
    {ok, pt:pack(48204, Data)};

write(48205, [PkList]) ->
	PkListLen = length(PkList),
	PkListBin = write_PkList(PkList,<<PkListLen:16>>),
    Data = <<PkListBin/binary>>,
    {ok, pt:pack(48205, Data)};

write(48206, [MyLoop,MyWinRate,MyHpRate,Top100List]) ->
	Top100ListLen = length(Top100List),
	Top100ListBen = write_Top100List(Top100List,<<Top100ListLen:16>>),
    Data = <<MyLoop:16,MyWinRate:16,MyHpRate:16,Top100ListBen/binary>>,
    {ok, pt:pack(48206, Data)};

write(48207, [AId,Aname,Acountry,Asex,Acarrer,Aimage,Alv,Apower,Alucky,
			  BId,Bname,Bcountry,Bsex,Bcarrer,Bimage,Blv,Bpower,Blucky]) ->
	AnameBin = pt:write_string(Aname),
	BnameBin = pt:write_string(Bname),
    Data = <<AId:32,AnameBin/binary,Acountry:8,Asex:8,Acarrer:8,Aimage:8,Alv:16,Apower:32,Alucky:16,
			 BId:32,BnameBin/binary,Bcountry:8,Bsex:8,Bcarrer:8,Bimage:8,Blv:16,Bpower:32,Blucky:16>>,
    {ok, pt:pack(48207, Data)};

write(48208, [WinId,AId,Aname,Acountry,Asex,Acarrer,Aimage,Alv,Apower,Alucky,AminHp,AmaxHp,
			  BId,Bname,Bcountry,Bsex,Bcarrer,Bimage,Blv,Bpower,Blucky,BminHp,BmaxHp]) ->
    AnameBin = pt:write_string(Aname),
	BnameBin = pt:write_string(Bname),
	Data = <<WinId:32,AId:32,AnameBin/binary,Acountry:8,Asex:8,Acarrer:8,Aimage:8,Alv:16,Apower:32,Alucky:16,AminHp:32,AmaxHp:32,
			 BId:32,BnameBin/binary,Bcountry:8,Bsex:8,Bcarrer:8,Bimage:8,Blv:16,Bpower:32,Blucky:16,BminHp:32,BmaxHp:32>>,
	{ok, pt:pack(48208, Data)};

write(48209, []) ->
    Data = <<>>,
    {ok, pt:pack(48209, Data)};

write(48210, [Loop,State,RestTime,WholeRestTime,CurrentLoop,Aname,Bname]) ->
	AnameBin = pt:write_string(Aname),
	BnameBin = pt:write_string(Bname),
    Data = <<Loop:8,State:8,RestTime:16,WholeRestTime:16,CurrentLoop:8,AnameBin/binary,BnameBin/binary>>,
	{ok, pt:pack(48210, Data)};
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
			New_Bin = <<Bin/binary,IsWin:8,Loop:8,MyPower:16,BId:32,BnameBin/binary,Bcountry:8,Bsex:8,Bcarrer:8,Bimage:8,Blv:16,Bpower:32>>,
			write_PkList(T,New_Bin)
	end.
write_Top100List(Top100List,Bin)->
	case Top100List of
		[]->Bin;
		[{BId,Bname,Bcountry,Bsex,Bcarrer,Bimage,Loops,WinRate,HpRate}|T]->
			BnameBin = pt:write_string(Bname),
			New_Bin = <<Bin/binary,BId:32,BnameBin/binary,Bcountry:8,Bsex:8,Bcarrer:8,Bimage:8,Loops:16,WinRate:16,HpRate:16>>,
			write_Top100List(T,New_Bin)
	end.
