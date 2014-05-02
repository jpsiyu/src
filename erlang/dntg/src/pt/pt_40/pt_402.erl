%% --------------------------------------------------------
%% @Module:           |pt_402
%% @Author:           | 
%% @Email:            | 
%% @Created:          |2012-00-00
%% @Description:      |帮战
%% --------------------------------------------------------

-module(pt_402).
-export([read/2, write/2]).

%%%=========================================================================
%%% 读包函数_write
%%%=========================================================================
read(40200, <<Config_Begin_Hour:8,Config_Begin_Minute:8,Sign_Up_Time:8,Loop_Time:8,Max_faction:8>>) ->
    {ok, [Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction]};

read(40201, _) ->
    {ok, []};

read(40203, _) ->
    {ok, []};

read(40205, _) ->
    {ok, []};

read(40207, _) ->
    {ok, []};

read(40208, _) ->
    {ok, []};

read(40209, <<BUid:32>>) ->
    {ok, [BUid]};

read(40210, <<Type:8>>) ->
    {ok, [Type]};

read(40212, _) ->
    {ok, []};

read(40214, <<PageNow:16>>) ->
    {ok, [PageNow]};

read(40216, _) ->
    {ok, []};

read(40217, _) ->
    {ok, []};

read(40219, _) ->
    {ok, []};

read(40220, _) ->
    {ok, []};

read(40221, _) ->
    {ok, []};
%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%%=========================================================================
%%% 写包函数_write
%%%=========================================================================
write(40201, [Result,RestTime,SignUpNo,LoopTime,Loop]) ->
    {ok, pt:pack(40201, <<Result:8,RestTime:16,SignUpNo:16,LoopTime:8,Loop:8>>)};

write(40202, [RestTime,LoopTime]) ->
    {ok, pt:pack(40202, <<RestTime:16,LoopTime:8>>)};

write(40203, [Result,SignUpNum]) ->
    {ok, pt:pack(40203, <<Result:8,SignUpNum:16>>)};

write(40204, [Result,Loop,RestTime]) ->
    {ok, pt:pack(40204, <<Result:8,Loop:8,RestTime:16>>)};

write(40205, [Result,Loop,CurrentLoop,RestTime]) ->
    {ok, pt:pack(40205, <<Result:8,Loop:8,CurrentLoop:8,RestTime:16>>)};

write(40206, [IsUp]) ->
    {ok, pt:pack(40206, <<IsUp:8>>)};

write(40207, [Result,Loop,RestTime]) ->
    {ok, pt:pack(40207, <<Result:8,Loop:8,RestTime:16>>)};

write(40208, [RestTime,FactionWarScore,Score,Anger,RestRevive,
			  IsGetJGB,FactionName,FactionWarList,KillList,
			  Jgb_FactionId,FyList]) ->
	FactionNameBin = pt:write_string(FactionName),
	FactionWarListLength = length(FactionWarList),
	FactionWarListBin = write_factionwar_list(FactionWarList,<<FactionWarListLength:16>>),
	KillListLength = length(KillList),
	KillListBin = write_kill_list(KillList,<<KillListLength:16>>),
	FyListLength = length(FyList),
	FyListBin = write_fylist(FyList,<<FyListLength:16>>),
    {ok, pt:pack(40208, <<RestTime:16,FactionWarScore:32,Score:32,Anger:8,RestRevive:8,
			  IsGetJGB:8,FactionNameBin/binary,FactionWarListBin/binary,KillListBin/binary,
			  Jgb_FactionId:32,FyListBin/binary>>)};

write(40209, [Result]) ->
    {ok, pt:pack(40209, <<Result:8>>)};

write(40210, [Result]) ->
    {ok, pt:pack(40210, <<Result:8>>)};

write(40211, [FactionName,KillNum,Score,PersonFactionFund,FactionNo,FactionWarScore,Exp,ResultList,KillList]) ->
	FactionNameBin = pt:write_string(FactionName),
	ResultListLength = length(ResultList),
	ResultListBin = write_result_list(ResultList,<<ResultListLength:16>>),
	KillListLength = length(KillList),
	KillListBin = write_kill_list(KillList,<<KillListLength:16>>),
    {ok, pt:pack(40211, <<FactionNameBin/binary,KillNum:16,Score:32,PersonFactionFund:32,
						  FactionNo:16,FactionWarScore:32,Exp:32,ResultListBin/binary,KillListBin/binary>>)};

write(40212, [Result]) ->
    {ok, pt:pack(40212, <<Result:8>>)};

write(40213, []) ->
    {ok, pt:pack(40213, <<>>)};

write(40214, [WarScore,LastKillNum,No,FactionNo,PageNow,PageNum,ResultList]) ->
	ResultListLength = length(ResultList),
	ResultListBin = write_result_list2(ResultList,<<ResultListLength:16>>),
    {ok, pt:pack(40214, <<WarScore:32,LastKillNum:32,No:16,FactionNo:16,PageNow:16,PageNum:16,ResultListBin/binary>>)};

write(40215, []) ->
    {ok, pt:pack(40215, <<>>)};

write(40216, [Result]) ->
    {ok, pt:pack(40216, <<Result:8>>)};

%% 交付水晶结果
write(40217, Result) ->
    {ok, pt:pack(40217, <<Result:8>>)};

%% 广播水晶类型(废弃，转移到12107)
write(40218, [Id, StoneType]) ->
    {ok, pt:pack(40218, <<Id:32, StoneType:8>>)};

write(40219, [X,Y]) ->
    {ok, pt:pack(40219, <<X:16,Y:16>>)};

write(40221, [RandScore]) ->
    {ok, pt:pack(40221, <<RandScore:16>>)};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

write_factionwar_list(FactionWarList,Bin)->
	case FactionWarList of
		[]->Bin;
		[H|T]->
			{FactionName,Num,Score} = H,
			FactionNameBin = pt:write_string(FactionName),
			write_factionwar_list(T,<<Bin/binary,FactionNameBin/binary,Num:16,Score:32>>)
	end.

write_kill_list(KillList,Bin)->
	case KillList of
		[]->Bin;
		[H|T]->
			{Name,FactionName,Num} = H,
			NameBin = pt:write_string(Name),
			FactionNameBin = pt:write_string(FactionName),
			write_kill_list(T,<<Bin/binary,NameBin/binary,FactionNameBin/binary,Num:16>>)
	end.

write_result_list(ResultList,Bin)->
	case ResultList of
		[]->Bin;
		[H|T]->
			{FactionName,Realm,Score,FactionWarScore} = H,
			FactionNameBin = pt:write_string(FactionName),
			write_result_list(T,<<Bin/binary,FactionNameBin/binary,Realm:8,Score:32,FactionWarScore:32>>)
	end.

write_result_list2(ResultList,Bin)->
	case ResultList of
		[]->Bin;
		[H|T]->
			{No,FactionName,Realm,FactionWarScore,Last_is_win} = H,
			FactionNameBin = pt:write_string(FactionName),
			write_result_list2(T,<<Bin/binary,No:16,FactionNameBin/binary,Realm:8,FactionWarScore:32,Last_is_win:8>>)
	end.

write_fylist(FyList,Bin)->
	case FyList of
		[]->Bin;
		[{MonTypeId,MonId,Uid,FactionId,FactionName}|T] ->
case catch pt:write_string(FactionName) of
	{'EXIT', _R} ->
			FactionNameBin = <<>>;
	_Bin -> FactionNameBin = _Bin
end,			
%% 			FactionNameBin = pt:write_string(FactionName),
			write_fylist(T,<<Bin/binary,MonTypeId:32,MonId:32,Uid:32,FactionId:32,FactionNameBin/binary>>);
		[_H|T] ->
			write_fylist(T,Bin)
	end.
