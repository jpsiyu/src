%%------------------------------------------------------------------------------
%% @Module  : pp_quiz
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.31
%% @Description: 答题协议处理
%%------------------------------------------------------------------------------

-module(pp_quiz).
-export([handle/3]).
-include("common.hrl").
-include("record.hrl").
-include("server.hrl").
-include("quiz.hrl").

%% 报名(0=已经报名，1=报名成功，2=等级不够，3=今天已经过参加答题, 4=答题服务还是开始).
handle(49001, Status, _) ->
    case Status#player_status.lv >= ?QUIZ_START_LEVEL of
        true -> 
            case lib_quiz:sign(Status) of
                {ok, E, LeftTime, _TatolTurn} ->
                    TatolTurn = _TatolTurn,
                    Error = E;
                {expire, _E} ->
                    TatolTurn = 0,
                    LeftTime = 0,
                    Error = 4;
                _ ->
                    TatolTurn = 0,
                    LeftTime = 0,
                    Error = 4
             end,
            {ok, BinData} = pt_490:write(49001, [Error, TatolTurn, LeftTime]),            
            lib_server_send:send_one(Status#player_status.socket, BinData),
			%% 判断任务触发
			case Error of
				1 ->
					lib_special_activity:add_old_buck_task(Status#player_status.id, 4);
				_ ->
					skip
			end,
			ok;
        _ ->
            {ok, BinData} = pt_490:write(49001, [2, 0, 0]),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end;

%% 答题.
handle(49004, Status, [Type,Option,Time,Luck]) ->
    lib_quiz:answer(Status, [Type,Option,Time,Luck]);

%% 获得报名状态.
handle(49007, Status, _) ->
	[Ifsign,Lnum, Cnum, Snum] = 
		case lib_quiz:get_sign_status(Status) of
		{ok,[_, _Ifsign, _, _, _Lnum, _Cnum, _Snum]} ->
	           [_Ifsign, _Lnum, _Cnum, _Snum];
		_ ->
			[0, 0, 0, 0]
		end,	
   %{ok,[_,Ifsign, _, _, Lnum, Cnum, Snum]} =  lib_quiz:get_sign_status(Status),
   {ok, BinData} = pt_490:write(49007, [Ifsign, Lnum, Cnum, Snum]),
   lib_server_send:send_one(Status#player_status.socket, BinData);

%% 使用放大镜.
handle(49009, Status, _) ->
	lib_quiz:handle_use_scale(Status);

%% 下一题开始时间.
handle(49010, Status, _) ->
	lib_quiz:handle_next_start_time(Status);

%% 没有协议匹配.
handle(_Cmd, _LogicStatus, _Data) ->
    ?DEBUG("pp_quiz no match", []),
    {error, "pp_quiz no match"}.
