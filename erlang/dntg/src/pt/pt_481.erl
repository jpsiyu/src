%%%--------------------------------------
%%% @Module  : pt_48
%%% @Author  : 
%%% @Email   : 
%%% @Created : 2010.12.17
%%% @Description: 蟠桃园消息的解包和组包
%%%--------------------------------------
-module(pt_481).
-export([read/2, write/2]).
-include("peach.hrl").

%%%=========================================================================
%%% 解包函数
%%%=========================================================================

read(48100, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 蟠桃园状态检测
%% -----------------------------------------------------------------
read(48101, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 蟠桃园房间列表
%% -----------------------------------------------------------------
read(48102, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 进入蟠桃园
%% -----------------------------------------------------------------
read(48103, <<RoomId:16>>) ->
    {ok, [RoomId]};

%% -----------------------------------------------------------------
%% 退出蟠桃园
%% -----------------------------------------------------------------
read(48104, <<>>) ->
    {ok, []};

read(48105, <<>>) ->
    {ok, []};

read(48109, <<>>) ->
    {ok, []};

read(48110, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================
write(48100, [ErroCode]) ->
    Data = <<ErroCode:8>>,
    {ok, pt:pack(48100, Data)};

%% -----------------------------------------------------------------
%% 蟠桃园状态检测
%% -----------------------------------------------------------------
write(48101, [Status]) ->
    Data = <<Status:8>>,
    {ok, pt:pack(48101, Data)};

%% -----------------------------------------------------------------
%% 蟠桃园进入通知
%% -----------------------------------------------------------------
write(48102, [RoomList]) ->
	RoomListLen = length(RoomList),
	RoomListBin = write_RoomList(RoomList,<<RoomListLen:16>>),
    Data = <<RoomListBin/binary>>,
    {ok, pt:pack(48102, Data)};

%% -----------------------------------------------------------------
%% 进入蟠桃园
%% -----------------------------------------------------------------
write(48103, [RoomId,Result,RemainTime]) ->
    Data = <<RoomId:16,Result:8,RemainTime:32>>,
    {ok, pt:pack(48103, Data)};

%% -----------------------------------------------------------------
%% 退出蟠桃园
%% -----------------------------------------------------------------
write(48104, [Score,Anger,Top5List,Acquisition,Plunder,Robbed]) ->
	Top5ListLen = length(Top5List),
	Top5ListBin = write_Top5List(Top5List,<<Top5ListLen:16>>,1),
    Data = <<Score:16,Anger:8,Top5ListBin/binary,Acquisition:16,Plunder:16,Robbed:16>>,
    {ok, pt:pack(48104, Data)};

write(48105, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(48105, Data)};

write(48106, []) ->
    Data = <<>>,
    {ok, pt:pack(48106, Data)};

write(48107, [Score,Acquisition_score,Plunder_score,Robbed_score,
			  Goods_A_Num,Goods_B_Num,TopList,Card_rate,Add_Exp]) ->
	TopListLen = length(TopList),
	TopListBin = write_TopList(TopList,<<TopListLen:16>>),
    Data = <<Score:16,Acquisition_score:16,Plunder_score:16,Robbed_score:16,
			  Goods_A_Num:16,Goods_B_Num:16,TopListBin/binary,Card_rate:8,Add_Exp:32>>,
    {ok, pt:pack(48107, Data)};

write(48108, [Uid,Peach_Num]) ->
    Data = <<Uid:32,Peach_Num:16>>,
    {ok, pt:pack(48108, Data)};

write(48109, [X,Y]) ->
    Data = <<X:16,Y:16>>,
    {ok, pt:pack(48109, Data)};

write(48110, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(48110, Data)};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

%%房间列表
%%@param RoomList [{key,[values]}]
write_RoomList(RoomList,Bin)->
	case RoomList of
		[]->Bin;
		[{Id,Num}|T]->
			New_Bin = <<Bin/binary,Id:16,Num:16>>,
			write_RoomList(T,New_Bin)
	end.

%%积分榜列表
write_Top5List(Top5List,Bin,Pos)->
	case Top5List of
		[]->Bin;
		[{Nickname,Peach_num,Uid}|T]->
			NicknameBin = pt:write_string(Nickname),
			New_Bin = <<Bin/binary,Pos:8,NicknameBin/binary,Peach_num:16,Uid:32>>,
			write_Top5List(T,New_Bin,Pos+1)
	end.

write_TopList(TopList,Bin)->
	case TopList of
		[]->Bin;
		[{NickName,Peach_Num}|T]->
			NicknameBin = pt:write_string(NickName),
			New_Bin = <<Bin/binary,NicknameBin/binary,Peach_Num:16>>,
			write_TopList(T,New_Bin)
	end.

