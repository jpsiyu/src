%%%--------------------------------------
%%% @Module  : pt_48
%%% @Author  : shebiao
%%% @Email   : shebiao@126.com
%%% @Created : 2010.12.17
%%% @Description: 竞技场消息的解包和组包
%%%--------------------------------------
-module(pt_480).
-export([read/2, write/2]).
-include("arena_new.hrl").
-define(SEPARATOR_STRING, "|").

%%%=========================================================================
%%% 解包函数
%%%=========================================================================

read(48000, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 竞技场状态检测
%% -----------------------------------------------------------------
read(48001, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 竞技场房间列表
%% -----------------------------------------------------------------
read(48002, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 进入竞技场
%% -----------------------------------------------------------------
read(48003, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 退出竞技场
%% -----------------------------------------------------------------
read(48004, <<>>) ->
    {ok, []};

read(48005, <<>>) ->
    {ok, []};

read(48009, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================
write(48000, [ErroCode]) ->
    Data = <<ErroCode:8>>,
    {ok, pt:pack(48000, Data)};

%% -----------------------------------------------------------------
%% 竞技场状态检测
%% -----------------------------------------------------------------
write(48001, [Status, Exp_multiple]) ->
    Data = <<Status:8, Exp_multiple:8>>,
    {ok, pt:pack(48001, Data)};

%% -----------------------------------------------------------------
%% 竞技场进入通知
%% -----------------------------------------------------------------
write(48002, [RoomLv,RoomId,RoomList]) ->
	RoomListLen = length(RoomList),
	RoomListBin = write_RoomList(RoomList,<<RoomListLen:16>>),
    Data = <<RoomLv:8,RoomId:16,RoomListBin/binary>>,
    {ok, pt:pack(48002, Data)};

%% -----------------------------------------------------------------
%% 进入竞技场
%% -----------------------------------------------------------------
write(48003, [Result,RoomLv,RoomId,Realm,TimeType,BossTime,RemainTime]) ->
    Data = <<Result:8,RoomLv:8,RoomId:16,Realm:8,TimeType:8,BossTime:32,RemainTime:32>>,
    {ok, pt:pack(48003, Data)};

%% -----------------------------------------------------------------
%% 退出竞技场
%% -----------------------------------------------------------------
write(48004, [Score,Continuous_kill,Anger,Killed,Assist,Boss,Top5List]) ->
	Top5ListLen = length(Top5List),
	Top5ListBin = write_Top5List(Top5List,<<Top5ListLen:16>>,1),
    Data = <<Score:16,Continuous_kill:16,Anger:8,Killed:16, Assist:16,Boss:8,Top5ListBin/binary>>,
    {ok, pt:pack(48004, Data)};

write(48005, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(48005, Data)};

write(48008, [Num,Exp,Llpt]) ->
    Data = <<Num:16,Exp:32,Llpt:32>>,
    {ok, pt:pack(48008, Data)};

write(48009, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(48009, Data)};

write(48010, []) ->
    Data = <<>>,
    {ok, pt:pack(48010, Data)};

write(48011, [Green_score,
              Red_score,
			  Green_kill_numen_num,
              Red_kill_numen_num,
			  Realm_no,
			  Kill_num,
			  Assist_num,
              Kill_boss_num,
              Kill_numen_num,
			  Max_continuous_kill,
              Continuous_score,
              Kill_boss_npc_score,
              Realm_no_score,
              Score]) ->
    Data = << Green_score:32,
              Red_score:32,
			  Green_kill_numen_num:8,
              Red_kill_numen_num:8,
			  Realm_no:8,
			  Kill_num:16,
              Assist_num:16,
              Kill_boss_num:8,
              Kill_numen_num:8,
              Max_continuous_kill:16,
              Continuous_score:16,
              Kill_boss_npc_score:16,
              Realm_no_score:16,
			  Score:32>>,
    {ok, pt:pack(48011, Data)};


write(48012, [Type, Time]) ->
  Data = <<Type:8, Time:32>>,
  {ok, pt:pack(48012, Data)};
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
		_->
			[H|T] = RoomList,
			{_Key,[Arena_room]} = H,
			Id = Arena_room#arena_room.id,
			Num = Arena_room#arena_room.num,
			New_Bin = <<Bin/binary,Id:16,Num:16>>,
			write_RoomList(T,New_Bin)
	end.

%%积分榜列表
write_Top5List(Top5List,Bin,Pos)->
	case Top5List of
		[]->Bin;
		_->
			[H|T] = Top5List,
			Id = H#arena.id,
			Nickname = H#arena.nickname,
			Score = H#arena.score,
			NicknameBin = pt:write_string(Nickname),
			New_Bin = <<Bin/binary,Pos:8,NicknameBin/binary,Score:16,Id:32>>,
			write_Top5List(T,New_Bin,Pos+1)
	end.
