%%%--------------------------------------
%%% @Module  : pp_setting
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.27
%%% @Description: 设定
%%%--------------------------------------

-module(pp_setting).
-export([handle/3]).
-include("unite.hrl").
-include("setting.hrl").

%% 保存挂机设定
handle(11901, US, Content) ->
	case private_check_content(Content) of
		{ok, Setting} ->
			RoleId = US#unite_status.id,
			Error = case catch private_get_setting_from_db(RoleId) of
				[] ->
					case catch private_insert_setting(RoleId, Setting) of
						ok -> 1;
						_ -> 0
					end;
				Onhook when is_binary(Onhook) ->
					case catch private_update_setting(RoleId, Setting) of
						ok -> 1;
						_ -> 0
					end;
				_ ->
					0
			end,
			put(?ROLE_SETTING(RoleId), Setting),
			{ok, BinData} = pt_119:write(11901, Error),
			lib_unite_send:send_to_sid(US#unite_status.sid, BinData);
		{error, _ErrorCode} ->
			{ok, BinData} = pt_119:write(11901, 0),
			lib_unite_send:send_to_sid(US#unite_status.sid, BinData)
	end;

%% 获取挂机设定
handle(11902, US, get_setting) ->
	RoleId = US#unite_status.id,
	case get(?ROLE_SETTING(RoleId)) of
		undefined ->
			case private_get_setting_from_db(RoleId) of
				[] ->
					put(?ROLE_SETTING(RoleId), 0),
					{ok, BinData} = pt_119:write(11902, <<>>),
					lib_unite_send:send_to_sid(US#unite_status.sid, BinData);
				Onhook ->
					put(?ROLE_SETTING(RoleId), Onhook),
					{ok, BinData} = pt_119:write(11902, Onhook),
					lib_unite_send:send_to_sid(US#unite_status.sid, BinData)
			end;
		GetResult ->
			{ok, BinData} = pt_119:write(11902, GetResult),
			lib_unite_send:send_to_sid(US#unite_status.sid, BinData)
	end;

%% 错误处理
handle(_Cmd, _Status, _Data) ->
	{error, "pp_setting no match"}.

private_get_setting_from_db(RoleId) ->
	Select = io_lib:format(?sql_setting_get_setting, [RoleId]),
	case db:get_one(Select) of
		null ->
			[];
		Onhook ->
			Onhook
	end.

private_insert_setting(RoleId, Setting) ->
	db:execute(
	  io_lib:format(?sql_setting_insert_setting, [RoleId, Setting])
	),
	ok.

private_update_setting(RoleId, Setting) ->
	db:execute(
	  io_lib:format(?sql_setting_update_setting, [Setting, RoleId])
	),
	ok.

private_check_content(Content) ->
	Content1 = re:replace(Content, "\"", "*", [{return, list}, global]),
	NewContent = re:replace(Content1, "\'", "*", [{return, list}, global]),
	case util:check_length(NewContent, ?ONHOOK_LENGTH) of
		true ->
			{ok, NewContent};
		false ->
			%% 长度超规定
			{error, 2}
	end.
