%%%------------------------------------
%%% @Module     : pp_secondary_password
%%% @Author     : huangyongxing
%%% @Email      : huangyongxing@yeah.net
%%% @Created    : 2011.2.21
%%% @Description: 二级密码
%%%------------------------------------
-module(pp_secondary_password).
-compile(export_all).
-include("common.hrl").
-include("server.hrl").
-include("record.hrl").

%% %% 请求验证码（当未连接公共线时才发送至逻辑线）
%% handle(26001, PlayerStatus, TypeNum) ->
%%     case mod_disperse:call_to_unite(lib_captcha, handle_captcha_check, [PlayerStatus#player_status.id, TypeNum]) of
%%         {ok, BinData} ->
%% 			lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
%%         _ ->
%%             ok
%%     end;

%% %% 输入验证码（当未连接公共线时才发送至逻辑线）
%% handle(26002, PlayerStatus, [TypeNum, Code]) ->
%%     case mod_disperse:call_to_unite(lib_captcha, handle_captcha_enter, [PlayerStatus#player_status.id, TypeNum, Code, PlayerStatus#player_status.online_flag]) of
%%         {ok, BinData} ->
%%             lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
%%         _ ->
%%             ok
%%     end;

%%% ==========================================
%%%                 二级密码
%%% ==========================================

%% 查询是否已经设置
handle(26011, PlayerStatus, _) ->
    Result = lib_secondary_password:query_is_set_protected_info(PlayerStatus#player_status.id),
	{ok, BinData} = pt_260:write(26011, Result),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);

%% 设置密保
handle(26012, PlayerStatus, [QId1, QId2, Answer1, Answer2, Password]) ->
    case lib_secondary_password:set_secondary_password(PlayerStatus#player_status.id, [QId1, QId2, Answer1, Answer2, Password]) of
        ok -> Result = 1;
        {error, ErrorCode} -> Result = ErrorCode
    end,
    {ok, BinData} = pt_260:write(26012, Result),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);

%% 修改二级密码
handle(26013, PlayerStatus, [OldPassword, NewPassword]) ->
    case lib_secondary_password:change_password(PlayerStatus#player_status.dailypid,PlayerStatus#player_status.id, OldPassword, NewPassword) of
        {ok, RestTimes} -> Result = 1;
        {error, ErrorCode, RestTimes} -> Result = ErrorCode
    end,
    {ok, BinData} = pt_260:write(26013, [Result, RestTimes]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);

%% 查询密保问题(删除/设置密码)
handle(26014, PlayerStatus, Type) ->
    Result = lib_secondary_password:get_protected_question(PlayerStatus#player_status.dailypid,PlayerStatus#player_status.id, Type),
    {ok, BinData} = pt_260:write(26014, Result),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);

%% 删除二级密码
handle(26015, PlayerStatus, [Answer1, Answer2]) ->
    case lib_secondary_password:delete_password(PlayerStatus#player_status.dailypid,PlayerStatus#player_status.id, [Answer1, Answer2]) of
        {ok, RestTimes} -> Result = 1;
        {error, ErrorCode, RestTimes} -> Result = ErrorCode
    end,
    {ok, BinData} = pt_260:write(26015, [Result, RestTimes]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);

%% 验证二级密码
handle(26016, PlayerStatus, Password) ->
    case lib_secondary_password:enter_password(PlayerStatus#player_status.id, Password) of
        ok ->
            Result = 1,
            {ok, BinData} = pt_260:write(26016, Result),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
			lib_player_server:execute_13001(PlayerStatus);
        {error, ErrorCode} ->
            Result = ErrorCode,
            {ok, BinData} = pt_260:write(26016, Result),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
        _ ->
            skip
    end;

%% 查询删改剩余次数
handle(26017, PlayerStatus, _) ->
    RestTimes = lib_secondary_password:query_rest_times(PlayerStatus#player_status.dailypid,PlayerStatus#player_status.id, change),
    {ok, BinData} = pt_260:write(26017, RestTimes),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);

handle(_, _, _) ->
    ?DEBUG("pp_secondary_password no match", []),
    {error, "pp_secondary_password no match"}.
