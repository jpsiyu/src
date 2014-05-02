%%%--------------------------------------
%%% @Module  : pp_activity_pk_power
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2013.3.11
%%% @Description: 斗战封神活动
%%%--------------------------------------

-module(pp_activity_kf_power).
-include("server.hrl").
-include("unite.hrl").
-include("rank.hrl").
-compile(export_all).

%% [公共线] 打开界面
handle(31901, US, _) ->
	case is_record(US, unite_status) of
		true ->
			lib_activity_kf_power:get_data(US#unite_status.platform, US#unite_status.server_num, US#unite_status.id);
		_ ->
			skip
	end;

%% [公共线] 打开前100名排行
handle(31902, US, _) ->
	case is_record(US, unite_status) of
		true ->
			case lib_activity_kf_power:get_rank() of
				[] ->
					{ok, Bin} = pt_319:write(31902, []),
					lib_unite_send:send_to_sid(US#unite_status.sid, Bin);
				Rd ->
					{ok, Bin} = pt_319:write(31902, Rd#ets_module_rank.rank_list),
					lib_unite_send:send_to_sid(US#unite_status.sid, Bin)
			end;
		_ ->
			skip
	end;

%% [游戏线] 领取奖励
handle(31910, PS, GiftId) ->
	case is_record(PS, player_status) of
		true ->
			case lib_activity_kf_power:fetch_award(PS, GiftId) of
				{ok} ->
					{ok, Bin} = pt_319:write(31910, [GiftId, 1]),
					lib_server_send:send_to_sid(PS#player_status.sid, Bin);
				{error, Error} ->
					{ok, Bin} = pt_319:write(31910, [GiftId, Error]),
					lib_server_send:send_to_sid(PS#player_status.sid, Bin)
			end;
		_ ->
			skip
	end;

%% 错误处理
handle(Cmd, _Status, _Data) ->
	util:errlog("pp_activity_kf_power: cmd[~p] no match", [Cmd]),
	{error, "pp_activity_kf_power no match"}.

