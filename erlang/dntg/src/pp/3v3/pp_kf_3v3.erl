%%%--------------------------------------
%%% @Module : pp_kf_3v3
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3
%%%--------------------------------------

-module(pp_kf_3v3).
-include("unite.hrl").
-include("kf_3v3.hrl").
-export([handle/3]).

%% 获取3v3图标状态
handle(48401, US, _) ->
	Status = mod_kf_3v3_state:get_status(),
	{ok, BinData} = pt_484:write(48401, Status),
	lib_unite_send:send_to_sid(US#unite_status.sid, BinData);

%% 进入准备区
handle(48402, US, _) ->
	Result = 
	case US#unite_status.lv >= data_kf_3v3:get_config(min_lv) of
		true ->
			Status = mod_kf_3v3_state:get_status(),
			case Status =:= ?KF_3V3_STATUS_ACTION of
				true ->
					case lib_scene:scene_check_enter(US#unite_status.id, data_kf_3v3:get_config(scene_id1)) of
						{true, _} ->
							case lib_player:get_player_info(US#unite_status.id, kf_3v3_info) of
								{CombatPower, MaxCombatPower, _Scene, VipLv, Kf1v1Data} ->
									[Pt, Score] = Kf1v1Data,
									case CombatPower >= data_kf_3v3:get_config(min_power) of
										true ->
											%% 今天已经pk次数
											PkNum = mod_daily:get_count(US#unite_status.dailypid, US#unite_status.id, 5705),
											%% 总共被举报次数
											Report = lib_kf_3v3:get_report_num(US#unite_status.id),
											mod_clusters_node:apply_cast(mod_kf_3v3, enter_prepare, [
												[
													[US#unite_status.platform, US#unite_status.server_num, 
														US#unite_status.id, US#unite_status.name, US#unite_status.lv,
													 	US#unite_status.realm, US#unite_status.career, US#unite_status.sex,
													 	US#unite_status.image, VipLv],
													mod_disperse:get_clusters_node(), CombatPower, MaxCombatPower, Pt, Score, PkNum, Report
												]
											]),

											%% 更新玩家数据到跨服排行榜
											mod_rank:remote_update_kf_rank(US#unite_status.dailypid, US#unite_status.id),

											{ok};
										_ ->
											{error, 3}
									end;
								_ ->
									{error, 4}
							end;
						_ ->
							{error, 4}
					end;
				_ ->
					{error, 5}
			end;
		_ ->
			{error, 2}
	end,

	case Result of
		{error, ErrorCode} ->
			{ok, BinData} = pt_484:write(48402, [ErrorCode]),
			lib_unite_send:send_to_sid(US#unite_status.sid, BinData);
		_ ->
			skip
	end;

%% 退出准备区
handle(48403, US, _) ->
	case US#unite_status.scene =:= data_kf_3v3:get_config(scene_id1) of
		true ->
			case US#unite_status.lv >= data_kf_3v3:get_config(min_lv) of
				true ->
					mod_clusters_node:apply_cast(mod_kf_3v3, exit_prepare, [
						US#unite_status.platform,
						US#unite_status.server_num,
						US#unite_status.id
					]);
				_ ->
					{ok, BinData} = pt_484:write(48403, 2),
					lib_unite_send:send_to_sid(US#unite_status.sid, BinData)
			end;
		_ ->
			{ok, BinData} = pt_484:write(48403, 2),
			lib_unite_send:send_to_sid(US#unite_status.sid, BinData)
	end;

%% 查看玩家已经打过的对阵表
handle(48405, US, _) ->
	mod_clusters_node:apply_cast(mod_kf_3v3_helper, get_pk_log, [
		US#unite_status.platform,
		US#unite_status.server_num,
		mod_disperse:get_clusters_node(),
		US#unite_status.id
	]);

%% 报名
handle(48410, US, _) ->
	case US#unite_status.scene =:= data_kf_3v3:get_config(scene_id1) of
		true ->
			case lib_kf_3v3:sign_up(US) of
				{error, ErrorCode} ->
					{ok, BinData} = pt_484:write(48410, [ErrorCode, 0]),
					lib_unite_send:send_to_sid(US#unite_status.sid, BinData);
				_ ->
					skip
			end;
		_ ->
			{ok, BinData} = pt_484:write(48410, [2, 0]),
			lib_unite_send:send_to_sid(US#unite_status.sid, BinData)
	end;

%% 查看本场积分排行
handle(48414, US, _) ->
	mod_clusters_node:apply_cast(mod_kf_3v3, get_score_rank, [
		US#unite_status.platform,
		US#unite_status.server_num,
		mod_disperse:get_clusters_node(),
		US#unite_status.id
	]);

%% 请求恢复幽灵状态
handle(48417, US, _) ->
	case lists:member(US#unite_status.scene, data_kf_3v3:get_config(scene_pk_ids)) of
		true ->
			lib_player:update_player_info(US#unite_status.id, [{force_change_pk_status, 0}]),
			{ok, BinData} = pt_484:write(48417, [1]),
			lib_unite_send:send_to_sid(US#unite_status.sid, BinData);
		_ ->
			skip
	end;

%% 举报
handle(48424, US, [Platform, ServerNum, Id]) ->
	case lists:member(US#unite_status.scene, data_kf_3v3:get_config(scene_pk_ids)) of
		true ->
			mod_clusters_node:apply_cast(mod_kf_3v3, report, [
				US#unite_status.platform,
				US#unite_status.server_num,
				US#unite_status.id,
				Platform, ServerNum, Id
			]);
		_ ->
			skip
	end;

%% 挂机
handle(48430, US, _) ->
	case data_kf_3v3:get_config(onhook_switch) of
		1 -> 
			case lists:member(US#unite_status.scene, data_kf_3v3:get_config(scene_pk_ids)) of
				true ->
					case US#unite_status.lv >= data_kf_3v3:get_config(min_lv) of
						true ->
							mod_clusters_node:apply_cast(mod_kf_3v3, onhook, [
								US#unite_status.platform,
								US#unite_status.server_num,
								US#unite_status.id
							]);
						_ ->
							skip
					end;
				_ ->
					skip
			end;
		_ ->
			skip
	end;

%% 错误处理
handle(Cmd, _Status, _Data) ->
	util:errlog("pp_kf_3v3 no match, Cmd = ~p~n", [Cmd]),
	{error, "pp_kf_3v3 no match"}.
