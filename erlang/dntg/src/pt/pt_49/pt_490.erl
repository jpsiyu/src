%%------------------------------------------------------------------------------
%% @Module  : pt_490
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.31
%% @Description: 答题协议
%%------------------------------------------------------------------------------

-module(pt_490).
-export([read/2, write/2]).
-include("common.hrl").
-include("record.hrl").

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(49001, _) ->
    {ok, no};

%答题
read(49004, <<Type:8, Option:32, Time:8, Luck:8>>) ->
    {ok, [Type,Option,Time,Luck]};

read(49007, _) ->
    {ok, no};

read(49009, _) ->
    {ok, no};

%% 下一题开始时间.
read(49010, _) ->
    {ok, no};

read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================
write(49001, [Flag, QuizNum, Time]) ->
    Data = <<Flag:8, QuizNum:8, Time:32>>,
    {ok, pt:pack(49001, Data)};

write(49002, [Time, Flag, SubjectType, Subject, EndTime]) ->
	_Subject = list_to_binary([Subject]),
	Len = byte_size(_Subject),	
    Data = <<Time:32, Flag:8, SubjectType:8, Len:16, _Subject/binary, EndTime:32>>,
    {ok, pt:pack(49002, Data)};

%% 发送题目
write(49003, [Turn, Content, Options, AllTurn, Type, SubjectType, Subject]) ->
    [Options1,Options2,Options3,Options4] = Options,
    _Content = list_to_binary([Content]),
	_Subject = list_to_binary([Subject]),
    _Options1 = list_to_binary([Options1]),
    _Options2 = list_to_binary([Options2]),
    _Options3 = list_to_binary([Options3]),
    _Options4 = list_to_binary([Options4]),
    Len0 = byte_size(_Content),
    Len1 = byte_size(_Options1),
    Len2 = byte_size(_Options2),
    Len3 = byte_size(_Options3),
    Len4 = byte_size(_Options4),
	Len5 = byte_size(_Subject),
    Data = <<Turn:8, AllTurn:8, Type:8, SubjectType, 
			 Len5:16, _Subject/binary, 
			 Len0:16, _Content/binary, 4:16, 
			 Len1:16, _Options1/binary, 
			 Len2:16, _Options2/binary, 
			 Len3:16, _Options3/binary, 
			 Len4:16, _Options4/binary>>,
    {ok, pt:pack(49003, Data)};

write(49005, [Resutl,A,B,C,D,ScaleNum, CopyEyeNum, LuckNum, Continue, Grade, 
	Rank, Genius ,Turngenius, Exp, Correct, RankBin]) ->
    Data1 = [<<Resutl:8 , A:16, B:16, C:16, D:16, LuckNum:8, CopyEyeNum:8, 
			   ScaleNum:8,Continue:8, Grade:16, Rank:16, Genius:16,
			   Turngenius:16, Exp:32, Correct:8>>],
    Data2 = list_to_binary(Data1 ++ [RankBin]),
    {ok, pt:pack(49005, Data2)};

write(49006, _) ->
    {ok, pt:pack(49006, <<1:8>>)};

write(49007, [Resutl, Lnum, Cnum, Snum]) ->
    {ok, pt:pack(49007, <<Resutl:8, Lnum:8, Cnum:8, Snum:8>>)};

write(49008, [Rank, Exp, Gen]) ->
    {ok, pt:pack(49008, <<Rank:32, Exp:32, Gen:32>>)};

write(49009, [Resutl, DeleteList]) ->
    Fun = fun(Elem) ->
        <<Elem:32>>
    end,
    BinList = list_to_binary([Fun(X) || X <- DeleteList]),
    Size  = length(DeleteList),
    {ok, pt:pack(49009, <<Resutl:8, Size:16, BinList/binary>>)};

%% 下一题开始时间.
write(49010, [Count, Time]) ->
    {ok, pt:pack(49010, <<Count:32, Time:32>>)};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

