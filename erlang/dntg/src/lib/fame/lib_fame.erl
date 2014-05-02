%%%--------------------------------------
%%% @Module  : lib_fame
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.6.2
%%% @Description: 名人堂
%%%--------------------------------------

-module(lib_fame).
-include("server.hrl").
-include("fame.hrl").
-include("goods.hrl").
-include("rank.hrl").
-include("designation.hrl").
-export([
	get_switch/0,
	server_start/0,
	get_rank_data/0,
	trigger/4,
	trigger_copy/3,
	trigger_in_manage/2,
	merge_trigger/4,
	merge_trigger_copy/2,
	remove_trigger/1,
	cost_coin/0,
	do_charm_rank/1,
	reload_data/0
]).


%% 称号功能开关：false关，true开
get_switch() ->
	lib_switch:get_switch(fame).

%% [公共线] 游戏服务启动时执行，初始化名人堂数据，方便在游戏中判断是否可达成名人堂的荣誉
server_start() ->
	case get_switch() of
		true ->
			%% 创建ets表
			ets:new(?ETS_FAME, [named_table, public, set, {keypos, #ets_fame.id}]),
			%% 往ets表插入已经在名人堂表中的数据
			Sql = io_lib:format(?SQL_FAME_FETCH_ALL_ID, []),
			case db:get_all(Sql) of
				[] ->
					skip;
				List ->
					F = fun([FameId], NewList) ->
						[#ets_fame{id = FameId} | NewList]
					end,
					FameList = lists:foldl(F, [], List),
					ets:insert(?ETS_FAME, FameList)
			end;
		_ ->
			skip
	end.

%% 重新载入数据到ets中
reload_data() ->
	case get_switch() of
		true ->
			%% 清旧数据
			ets:delete_all_objects(?ETS_FAME),
			%% 往ets表插入已经在名人堂表中的数据
			Sql = io_lib:format(?SQL_FAME_FETCH_ALL_ID, []),
			case db:get_all(Sql) of
				[] ->
					skip;
				List ->
					F = fun([FameId], NewList) ->
						[#ets_fame{id = FameId} | NewList]
					end,
					FameList = lists:foldl(F, [], List),
					ets:insert(?ETS_FAME, FameList)
			end,
			mod_disperse:cast_to_unite(mod_rank, refresh_single, [?RK_FAME]);
		_ ->
			skip
	end.

%% 取得名人堂排行榜数据
get_rank_data() ->
	case get_switch() of
		true ->
			case data_fame:get_ids_list(all) of
				%% 如果没有配置荣誉数据，直接返回空数组
				[] ->
					[];

				FameList ->
					%% 查询所有已达成荣誉的记录
					Sql = io_lib:format(?SQL_FAME_SELECT, []),
					case db:get_all(Sql) of
						%% 如果没有人达成过荣誉
						[] ->
							F = fun(BaseFame) ->
								[BaseFame#base_fame.id, 0, []]
							end,
							[F(BaseFame) || BaseFame <- FameList];
		
						%% 如果已有达成的记录
						RoleList ->
							F3 = fun([PlayeId, FameId, PlayerName, PlayerRealm, PlayerCareer, PlayerSex, _AddTime, Image], [BaseFame, Status, ResultList]) ->
								if 
									BaseFame#base_fame.id =:= FameId ->
										TmpStatus = [1 | Status],
										TmpResult = [[PlayeId, PlayerName, PlayerRealm, PlayerCareer, PlayerSex, Image] | ResultList],
										[BaseFame, TmpStatus, TmpResult];
									true ->
										TmpStatus = [0 | Status],
										[BaseFame, TmpStatus, ResultList]
								end
							end,

							F2 = fun(BaseFame, [ParRoleList, TargetList]) ->
		
								[_, StatusList, NewResultList] = lists:foldl(F3, [BaseFame, [], []], ParRoleList),
								
								Status = case lists:member(1, StatusList) of
									true -> 1;
									_ -> 0
								end,

								[ParRoleList, [[BaseFame#base_fame.id, Status, NewResultList] | TargetList]]

							end,

							%% 循环所有荣誉记录，再看每条荣誉记录是否有被达成的记录存在
							[_LastRoleList, LastResultList] = lists:foldl(F2, [RoleList, []], FameList),
							LastResultList
					end
			end;
		_ ->
			[]
	end.

%% 触发：普通单人荣誉
trigger(RoleId, FameType, ActionId, ActionValue) ->
	case get_switch() of
		true ->
			try private_trigger_one(FameType, ActionId, ActionValue, RoleId) of
				ok -> skip
			catch
				_ : R ->
					util:errlog("error! Module=lib_fame, Funcion=trigger, Param=(~p, ~p, ~p, ~p), error = ~p", [RoleId, FameType, ActionId, ActionValue, R])
			end;
		_ ->
			skip
	end.

%% 合服触发：普通单人荣誉
merge_trigger(RoleId, FameId, ActionId, ActionValue) ->
	case get_switch() of
		true ->
			case data_fame:get_fame(FameId) of
				[] ->
					skip;
				FameRD ->
					private_do_single(FameRD, ActionId, ActionValue, RoleId)
			end;
		_ ->
			skip
	end.

%% 触发：第一个击杀指定副本BOSS
%% 这类荣誉比较特殊，由多人组队击杀boss从而达成，多个玩家可同时达成荣誉
trigger_copy(Type, BossId, PlayerList) ->
	case get_switch() of
		true ->
			try private_trigger_multi(Type, BossId, PlayerList) of
				ok -> skip
			catch
				_ : R ->
					util:errlog("error! Module=lib_fame, Funcion=trigger_copy, Param=(~p, ~p, ~p, ~p), error = ~p", [?FAME_TYPE_COPY, BossId, PlayerList, R])
			end;
		_ ->
			skip
	end.

%% 触发：合区首日的多人九重天30层霸主
%% 这类荣誉比较特殊，由多人组队击杀boss从而达成，多个玩家可同时达成荣誉
merge_trigger_copy(FameId, PlayerList) ->
	case get_switch() of
		true ->
			case data_fame:get_fame(FameId) of
				[] ->
					skip;
				FameRD ->
					private_do_multi(FameRD, [30, PlayerList])
			end;
		_ ->
			skip
	end.

%% 管理后台秘籍小工具触发
trigger_in_manage(RoleId, FameId) ->
	case lib_player:get_player_low_data(RoleId) of
		[_NickName, _Sex, _LV, _Career, _Realm, _GuildId, _MountLimit, _HusongNpc, _Image | _] ->
			case data_fame:get_fame(FameId) of
				[] ->
					skip;
				Fame ->
					db:execute(io_lib:format(?SQL_FAME_DELETE2, [FameId])),
					db:execute(io_lib:format(?SQL_FAME_INSERT, [FameId, RoleId, util:unixtime()])),
					mod_fame:reload_data(),
					mod_disperse:cast_to_unite(mod_rank, refresh_single, [?RK_FAME]),
					%% 移除原有称号
					case lib_designation:get_roleids_by_design(Fame#base_fame.design_id) of
						[] ->
							skip;
						RoleList ->
							[lib_designation:remove_design_in_server(OldRoleId, Fame#base_fame.design_id) || OldRoleId <- RoleList]
					end,
					lib_designation:bind_design_in_server(RoleId, Fame#base_fame.design_id, "", 0)
			end;
		_ ->
			%% 取消获得该名人堂的记录
			case RoleId == 0 of
				true ->
					case FameId == 1988201 of
						true ->
							mod_fame:reload_data();
						_ ->
							mod_fame:remove_trigger(FameId)
					end;
				_ ->
					skip
			end
	end.

%% 取消触发
remove_trigger(FameId) ->
	case data_fame:get_fame(FameId) of
		[] ->
			skip;
		Fame ->
			db:execute(io_lib:format(?SQL_FAME_DELETE2, [FameId])),
			ets:delete(?ETS_FAME, FameId),
			mod_rank:refresh_single(?RK_FAME),
			%% 移除原有称号
			case lib_designation:get_roleids_by_design(Fame#base_fame.design_id) of
				[] ->
					skip;
				RoleList ->
					[lib_designation:remove_design_in_server(OldRoleId, Fame#base_fame.design_id) || OldRoleId <- RoleList]
			end
	end.

%% 合区首日的铜钱消耗第一
cost_coin() ->
	case lib_activity_merge:get_activity_time() of
		0 ->
			skip;
		Time ->
			NowTime = util:unixtime(),
			case NowTime >= Time andalso NowTime < Time + 86400 of
				true ->
					case db:get_one(io_lib:format(?SQL_FAME_MERGE_COST_COIN, [Time, util:unixdate(Time) + 86400])) of
						RoleId when is_integer(RoleId) ->
							mod_fame:trigger(Time, RoleId, 12101, 0, 1);
						_ ->
							skip
					end;
				_ ->
					skip
			end
	end.

%% 合服名人堂：合服鲜花榜第一 和 合服护花榜第一
do_charm_rank(RankType) ->
	FameId = case RankType of
		?RK_CHARM_DAY_HUHUA -> 11901;
		?RK_CHARM_DAY_FLOWER -> 12001
	end,
	case lib_rank:pp_get_rank(RankType) of
		[] ->
			skip;
		List ->
			%% 名人堂：合服护花榜第一
			case length(List) > 0 of
				true ->
					[[RoleId | _]] = lists:sublist(List, 1),
					mod_fame:trigger(
						lib_activity_merge:get_activity_time(),
						RoleId, FameId, 0, 1
					);
				_ ->
					skip
			end
	end.

%% 处理单人的荣誉：拿出同类型荣誉列表，再单个处理
private_trigger_one(FameType, ActionId, ActionValue, RoleId) ->
	case data_fame:get_list_by_type(FameType) of
		[] ->
			skip;
		IdList ->
			lists:foreach(fun(FameRD) -> 
				private_do_single(FameRD, ActionId, ActionValue, RoleId)
			end, IdList)
	end,
	ok.

%% 处理多人的荣誉：拿出同类型荣誉列表，再单个处理
private_trigger_multi(Type, BossId, PlayerList) ->
	List = data_fame:get_list_by_type(Type),
	case List =/= [] of
		true ->	
    		lists:foldl(fun private_do_multi/2, [BossId, PlayerList], List);
    	_ ->
			skip
	end,
	ok.

%% 处理单个荣誉
private_do_single(FameRD, ActionId, ActionValue, RoleId) ->
	if
		is_record(FameRD, base_fame) ->
			case private_is_fame_finish(FameRD) of
				false ->
					Result = lists:member(ActionId, FameRD#base_fame.target_id),
					if 
						FameRD#base_fame.target_id =:= [] andalso FameRD#base_fame.num =< ActionValue ->
							[Nickname, Sex, _, Career, Realm, _, _, _, Image| _] = lib_player:get_player_low_data(RoleId),
							private_finish_fame(FameRD, RoleId, Nickname, Realm, Career, Sex, Image);
						
						FameRD#base_fame.target_id =/= [] andalso (Result =:= true) andalso (FameRD#base_fame.num =< ActionValue) ->
							[Nickname, Sex, _, Career, Realm, _, _, _, Image| _] = lib_player:get_player_low_data(RoleId),
							private_finish_fame(FameRD, RoleId, Nickname, Realm, Career, Sex, Image);

						true ->
							skip
					end;
				_ ->
					skip
			end;
		true ->
			skip
	end.

%% 单个玩家完成荣誉
private_finish_fame(FameRD, PlayerId, PlayerNickName, PlayerRealm, PlayerCareer, PlayerSex, PlayerImage) ->
	%% 荣誉更新为达成
	Sql = io_lib:format(?SQL_FAME_INSERT, [FameRD#base_fame.id, PlayerId, util:unixtime()]),
	db:execute(Sql),
	ets:insert(?ETS_FAME, #ets_fame{id = FameRD#base_fame.id}),

	%% 通知排行榜更新名人堂数据
	mod_rank:update_fame(FameRD#base_fame.id, [PlayerId, PlayerNickName, PlayerRealm, PlayerCareer, PlayerSex, PlayerImage]),

	%% 绑定称号
	case FameRD#base_fame.design_id > 0 of
		true ->
			%% 发传闻
			lib_chat:send_TV({all}, 1, 2, ["mrt",1, PlayerId, PlayerRealm, PlayerNickName, PlayerSex, PlayerCareer, 0, FameRD#base_fame.desc, FameRD#base_fame.design_id]),

			lib_designation:bind_design(PlayerId, FameRD#base_fame.design_id, "", 0);
		_ ->
			skip
	end.

%% 处理是否可达成荣誉
private_do_multi(FameRD, [BossId, PlayerList]) ->
	case lists:member(BossId, FameRD#base_fame.target_id) of
		false ->
			[BossId, PlayerList];
		_ ->
			case private_is_fame_finish(FameRD) of
				true ->
					[BossId, PlayerList];
				_ ->
					%% 触发完成该荣誉
					private_multi_finish_fame(FameRD, PlayerList),
					[BossId, PlayerList]
			end
	end.

%% 是否名人堂指定的荣誉已被完成
private_is_fame_finish(FameRD) ->
	case ets:lookup(?ETS_FAME, FameRD#base_fame.id) of
		[] ->
			false;
		_ ->
			true
	end.

%% 多个玩家完成荣誉
private_multi_finish_fame(FameRD, PlayerList) ->
	F = fun(PlayerId) ->
		case lib_player:get_player_low_data(PlayerId) of
			%% 玩家数据不存在
			[] ->
				skip;
			[NickName, Sex, _, Career, Realm, _, _, _, Image|_] ->
				private_finish_fame(FameRD, PlayerId, NickName, Realm, Career, Sex, Image);
			_ ->
				skip
		end
	end,
	[F(PlayerId) || PlayerId <- PlayerList].
