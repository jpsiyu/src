%%%------------------------------------
%%% @Module  : pp_off_line
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2013.02.01
%%% @Description: 经验材料召回活动
%%%------------------------------------
-module(pp_off_line).
-compile(export_all).
-include("server.hrl").
-include("common.hrl").

%% 是否显示小图标
handle(31800, PlayerStatus, _) ->
    BeginTime = data_off_line:get_off_line_config(begin_time),
    LastShowTime = data_off_line:get_off_line_config(last_show_time),
    case date() >= BeginTime andalso date() =< LastShowTime of
        true ->
            {ok, BinData} = pt_318:write(31800, [1]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        false ->
            skip
    end;

%% 显示信息
handle(31801, PlayerStatus, _) ->
    BeginTime = data_off_line:get_off_line_config(begin_time),
    LastShowTime = data_off_line:get_off_line_config(last_show_time),
    case date() >= BeginTime andalso date() =< LastShowTime of
        true ->
            [List1, List2] = divide_list(PlayerStatus#player_status.off_line_award, [], []),
            %io:format("List1:~p, List2:~p~n", [List1, List2]),
            {ok, BinData} = pt_318:write(31801, [List1, List2]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        false ->
            skip
    end;

%% 领取
handle(31802, PlayerStatus, [Type, Num, CostType]) ->
    %% 数据验证
    case Type >= 1 andalso Type =< 8 andalso Num > 0 andalso CostType >= 1 andalso CostType =< 2 of
        true ->
            BeginTime = data_off_line:get_off_line_config(begin_time),
            LastShowTime = data_off_line:get_off_line_config(last_show_time),
            case date() >= BeginTime andalso date() =< LastShowTime of
                true ->
                    {Res, Str, NewPlayerStatus} = lib_off_line:get_off_line_award(PlayerStatus, Type, Num, CostType),
                    {ok, BinData} = pt_318:write(31802, [Res, Str]),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
                    {ok, NewPlayerStatus};
                false ->
                    skip
            end;
        false ->
            skip
    end;

handle(_Cmd, _LogicStatus, _Data) ->
    ?DEBUG("pp_off_line no match", []),
    {error, "pp_off_line no match"}.

divide_list([], L1, L2) -> [L1, L2];
divide_list([H | T], L1, L2) ->
    case H of
        {_Type1, _Num1, _Exp1} ->
            divide_list(T, [H | L1], L2);
        {_Type2, _Num2, _AwardNum2, _Level2, _GoodsId2} ->
            divide_list(T, L1, [H | L2]);
        _ ->
            divide_list(T, L1, L2)
    end.
