%%%--------------------------------------
%%% @Module  : pp_fcm
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.28
%%% @Description:  防沉迷系统
%%%--------------------------------------

-module(pp_fcm).
-export([handle/3]).
-include("server.hrl").

%% 身份获取
%% 0 获取身份失败
%% 1 身份已经提交
%% 2 身份未提交
%% 3 身份已提交且为未成年人，因累计离线时间不够禁止游戏。
%% 4 身份未提交，因累计离线时间不够禁止游戏。
handle(42001, Status, State) ->
	%io:format("recv 42001~n"),
	%io:format("42001 State:~p~n", [State]),
    case State >= 0 andalso State =< 2 of
        true ->
            [Error, Name, IdCardNo, UnderAgeFlag] = lib_fcm:get_fcm_info(Status#player_status.id, State),
            {ok, BinData} = pt_420:write(42001, [Error, Name, IdCardNo, UnderAgeFlag]),
            %io:format("42001:~p~n", [BinData]),
            %io:format("Error:~p, Name:~p, IdCardNo:~p, UnderAgeFlag:~p~n", [Error, Name, IdCardNo, UnderAgeFlag]),
            %io:format("Error:~p~n", [Error]),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        false -> skip
    end;

%% 身份提交
handle(42002, Status, [State, Name, IdCardNo]) ->
	%io:format("recv 42002~n"),
	%io:format("42002 State:~p~n", [State]),
	%int:8  结果码
	%       0 失败
    %       1 成功
    %       2 姓名不合法
    %       3 身份证号不合法
    case State >= 0 andalso State =< 2 of
        true ->
            case length(Name) > 20 orelse util:check_keyword(Name) =:= true of
                true -> {ok, BinData} = pt_420:write(42002, [2, 1]);
                false ->
                    case length(IdCardNo) > 20 of
                        true -> {ok, BinData} = pt_420:write(42002, [3, 1]);
                        false ->
                            %% 判断是否未成年,0 表示未填写实名信息  1 表示填写了实名信息且已经成年  2 表示填写了实 名但未成年
                            case State of
                                0 -> 
                                    %% 检查身份证号的有效性
                                    %% 0 失败  1 成功  2 姓名不合法  3 身份证号不合法
                                    case lib_fcm:validate_idcard(IdCardNo) of
                                        true ->
                                            UnderAgeFlag = case lib_fcm:is_idcard_under_age(IdCardNo) of
                                                true -> 1;
                                                false -> 0
                                            end,
                                            BadCardNo = false;
                                        false -> 
                                            UnderAgeFlag = 1,
                                            BadCardNo = true
                                    end;
                                2 -> 
                                    UnderAgeFlag = 1,
                                    BadCardNo = false;
                                1 -> 
                                    UnderAgeFlag = 0,
                                    BadCardNo = false
                            end,
                            case BadCardNo of
                                true ->
                                    %io:format("Error:3, UnderAgeFlag:1~n"),
                                    {ok, BinData} = pt_420:write(42002, [3, 1]);
                                false ->
                                    %% 身份提交
                                    case State of
                                        0 -> _State = 0;
                                        _ -> _State = 1
                                    end,
                                    Res = lib_fcm:submit_fcm_info(Status#player_status.id, Name, IdCardNo, UnderAgeFlag, _State),
                                    %io:format("Error:1, UnderAgeFlag:~p~n", [UnderAgeFlag]),
                                    {ok, BinData} = pt_420:write(42002, [Res, UnderAgeFlag])
                            end
                            %io:format("UnderAgeFlag:~p~n", [UnderAgeFlag])
                    end
            end,
            %io:format("42002:~p~n", [BinData]),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        false -> skip
    end;

handle(42003, Status, _) ->
	%io:format("recv 42003~n"),
    lib_fcm:execute_42003(Status#player_status.id);

handle(_Cmd, _PlayerStatus, _Bin) ->
    util:errlog("pp_fcm handle ~p error~n", [_Cmd]),
    {ok, no_match}.

