%%%--------------------------------------
%%% @Module  : lib_rank_refresh
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.5.31
%%% @Description :  排行榜刷新相关
%%%--------------------------------------

-module(lib_rank_refresh).
-include("rank.hrl").
-include("sql_rank.hrl").
-include("designation.hrl").
-include("server.hrl").
-export([
	refresh_rank_700/3,
	refresh_person_rank/2,
	refresh_rank_online/1,
	refresh_player_level_rank/1,
	refresh_rank_of_player_power/2,
	refresh_rank_of_person_level/2,
	change_sex/2,
	private_change_sex_format1/3,
	private_change_sex_format2/3,
	private_change_sex_format3/3
]).

%% 刷新 魅力护花榜7001/鲜花榜7002
%% RankType : 排行榜类型7001或7002
%% Row : [RoleId, RoleName, RoleSex, RoleCareer, RoleRealm, GuildName, RoleImage]
refresh_rank_700(RankType, Row, AddScore) ->
	if
		RankType =:= 7001 ->
			private_refresh_rank_700(RankType, Row, AddScore);
		RankType =:= 7002 ->
			private_refresh_rank_700(RankType, Row, AddScore);
		true ->
			skip
	end.

%% 刷新 玩家战力榜
%% RankType : 排行榜类型id
%% Row : [Id, NickName, Sex, Career, Realm, GuildName, CombatPower, VipType]
refresh_rank_of_player_power(RankType, Row) ->
	[NewRoleId, NewNickName, NewSex, NewCareer, NewRealm, NewGuildName, NewPower, NewVip] = Row,

	case private_get_rank_data(RankType, 0) of
		%% 第一个人上榜
		[] ->
			Sql = io_lib:format(?SQL_RK_PERSON_FIGHT_UPDATE, [NewRoleId, NewPower, util:unixtime()]),
			db:execute(Sql),

			RankRecord = private_make_rank_info(RankType, [Row]),
			ets:insert(?ETS_RANK, RankRecord),

			%% 刷新上榜玩家称号
			lib_rank:rebind_design(RankType, [Row]),

			%% 战力第一的玩家需要传闻数据
			private_get_power_top_by_career([Row]);

		%% 非第一个人上榜，需要作几步的处理
		List when is_list(List) ->
			Length = length(List),
			LastElement = lists:nth(Length, List),
            [_, _, _, _, _, _, LastPower, _] = LastElement,
            case NewPower =< LastPower andalso Length >= ?NUM_LIMIT of
                true ->
                    skip;
                _ ->
					Sql = io_lib:format(?SQL_RK_PERSON_FIGHT_UPDATE, [NewRoleId, NewPower, util:unixtime()]),
					db:execute(Sql),

					%% 第一步：循环列表，替换排行值
		            F = fun(RankRow, [Exist, NewList]) ->
		                [OldRoleId, _, _, _, _, _, _, _] = RankRow,
		                case OldRoleId =:= NewRoleId of
		                    true ->
		                        [1, [[NewRoleId, NewNickName, NewSex, NewCareer, NewRealm, NewGuildName, NewPower, NewVip] | NewList]];
		                    _ ->
		                        [Exist, [RankRow | NewList]]
		                end
		            end,
		            [NewExist, List2] = lists:foldl(F, [0, []], List),

		            case NewExist of
		                %% 之前不在榜上
		                0 ->
		                    List3 = [[NewRoleId, NewNickName, NewSex, NewCareer, NewRealm, NewGuildName, NewPower, NewVip] | List2];
		                _ ->
		                    List3 = List2
		            end,

					%% 第二步：排序
					SortFun = fun([_, _, _, _, _, _, Power1, _], [_, _, _, _, _, _, Power2, _]) ->
						Power1 > Power2
					end,
					List4 = lists:sort(SortFun, List3),

					%% 第四步：截取指定条数据保留在榜单中
					List5 = case length(List4) > ?NUM_LIMIT of
						true ->
							lists:sublist(List4, 1, ?NUM_LIMIT);
						_ ->
							List4
					end,

					%% 第五步：保存进榜单数据中
					RankRecord = private_make_rank_info(RankType, List5),
					ets:insert(?ETS_RANK, RankRecord),

					%% 刷新上榜玩家称号
					lib_rank:rebind_design(RankType, List5),

					%% 刷新排行第一的玩家传闻数据
					private_get_power_top_by_career(List5)
			end
	end.

%% 刷新 玩家榜等级榜
%% RankType : 排行榜类型
%% Row : [RoleId, NickName, Sex, Career, Realm, GuildName, Value, Vip, Exp]
refresh_rank_of_person_level(RankType, Row) ->
	[NewRoleId, _NewNickName, _NewSex, _NewCareer, _NewRealm, _NewGuildName, NewValue, _NewVip, _Exp] = Row,

	case private_get_rank_data(RankType, 0) of
		%% 第一个人上榜
		[] ->
			RankRecord = private_make_rank_info(RankType, [Row]),
			ets:insert(?ETS_RANK, RankRecord),

			%% 绑定上榜玩家称号
			lib_rank:rebind_design(RankType, [Row]);

		%% 非第一个人上榜，需要作几步的处理
		List when is_list(List) ->
            Length = length(List),
			LastElement = lists:nth(Length, List),
			[_, _, _, _, _, _, LastValue, _, _] = LastElement,

			case NewValue =< LastValue andalso Length >= ?NUM_LIMIT of
				true ->
					skip;
				_ ->
					%% 第一步：循环列表，替换等级
					F = fun(RankRow, [Exist, NewList]) ->
						[OldRoleId, _, _, _, _, _, _, _, _] = RankRow,
						case OldRoleId =:= NewRoleId of
							true ->
								[1, [Row | NewList]];
							_ ->
								[Exist, [RankRow | NewList]]
						end
					end,
					[NewExist, List2] = lists:foldl(F, [0, []], List),

					case NewExist of
						%% 之前不在榜上
						0 ->
							List3 = [Row | List2];
						_ ->
							List3 = List2
					end,

					%% 第二步：排序
					SortFun = fun([_, _, _, _, _, _, LV1, _, Exp1], [_, _, _, _, _, _, LV2, _, Exp2]) ->
						if
							LV1 > LV2 -> true;
							(LV1 == LV2) and (Exp1 >= Exp2) -> true;
							true -> false
						end
					end,
					List4 = lists:sort(SortFun, List3),

					%% 第三步：截取指定条数的数据保留在榜单中
					List5 = case length(List4) > ?NUM_LIMIT of
						true ->
							lists:sublist(List4, 1, ?NUM_LIMIT);
						_ ->
							List4
					end,

					%% 第四步：保存进榜单数据中
					RankRecord = private_make_rank_info(RankType, List5),
					ets:insert(?ETS_RANK, RankRecord),

					%% 绑定称号
					lib_rank:rebind_design(RankType, List5)
			end
	end.

%% 刷新 玩家榜(不包括玩家战力榜，玩家等级榜)
%% RankType : 排行榜类型
%% Row : [RoleId, NickName, Sex, Career, Realm, GuildName, Value, Vip]
refresh_person_rank(RankType, Row) ->
	[NewRoleId, _NewNickName, _NewSex, _NewCareer, _NewRealm, _NewGuildName, NewValue, _NewVip] = Row,

	case private_get_rank_data(RankType, 0) of
		%% 第一个人上榜
		[] ->
			RankRecord = private_make_rank_info(RankType, [Row]),
			ets:insert(?ETS_RANK, RankRecord),

			%% 绑定上榜玩家称号
			lib_rank:rebind_design(RankType, [Row]);

		%% 非第一个人上榜，需要作几步的处理
		List when is_list(List) ->
			LastElement = lists:nth(length(List), List),
			[_, _, _, _, _, _, LastValue, _, _] = LastElement,

			case NewValue =< LastValue of
				true ->
					skip;
				_ ->
					%% 第一步：循环列表，替换等级
					F = fun(RankRow, [Exist, NewList]) ->
						[OldRoleId, _, _, _, _, _, _, _, _] = RankRow,
						case OldRoleId =:= NewRoleId of
							true ->
								[1, [Row | NewList]];
							_ ->
								[Exist, [RankRow | NewList]]
						end
					end,
					[NewExist, List2] = lists:foldl(F, [0, []], List),

					case NewExist of
						%% 之前不在榜上
						0 ->
							List3 = [Row | List2];
						_ ->
							List3 = List2
					end,

					if
						RankType =:= ?RK_PERSON_LV ->
							%% 第二步：排序
							SortFun = fun([_, _, _, _, _, _, LV1, _, Exp1], [_, _, _, _, _, _, LV2, _, Exp2]) ->
								if
									LV1 > LV2 -> true;
									(LV1 == LV2) and (Exp1 >= Exp2) -> true;
									true -> false
								end
							end,
							List4 = lists:sort(SortFun, List3);
						true ->
							%% 第二步：排序
							SortFun = fun([_, _, _, _, _, _, Value1, _, _], [_, _, _, _, _, _, Value2, _, _]) ->
								if
									Value1 > Value2 -> true;
									true -> false
								end
							end,
							List4 = lists:sort(SortFun, List3)
					end,

					%% 第三步：截取指定条数的数据保留在榜单中
					List5 = case length(List4) > ?NUM_LIMIT of
						true ->
							lists:sublist(List4, 1, ?NUM_LIMIT);
						_ ->
							List4
					end,

					%% 第四步：保存进榜单数据中
					RankRecord = private_make_rank_info(RankType, List5),
					ets:insert(?ETS_RANK, RankRecord),

					%% 绑定称号
					lib_rank:rebind_design(RankType, List5)
			end
	end.

%% [游戏线] 玩家登录时触发刷榜
%% 目前只刷玩家战力榜
refresh_rank_online(PlayerStatus) ->
	%% 取开服时间戳
	OpenTime = util:get_open_time(),
	%% 当前时间
	NowTime = util:unixtime(),
	if
		%% 开服30天后，战斗力指定值为20000才进行处理，以下类推。这样做为了减少数据量的处理	
		NowTime > OpenTime + 30 * 86400 ->	
			RequireCombatPower = 9000;
		NowTime > OpenTime + 20 * 86400 ->
			RequireCombatPower = 7500;
		NowTime > OpenTime + 10 * 86400 ->	
			RequireCombatPower = 6000;
		NowTime > OpenTime + 5 * 86400 ->	
			RequireCombatPower = 5000;
		NowTime > OpenTime + 3 * 86400 ->	
			RequireCombatPower = 4000;
		NowTime > OpenTime + 2 * 86400 ->	
			RequireCombatPower = 3000;
		true ->	
			RequireCombatPower = 2000
	end,

	%% 战斗力 大于某个值 才进行刷新进榜的业务
	case PlayerStatus#player_status.combat_power > RequireCombatPower of
		true ->
			RankInfo = [
				PlayerStatus#player_status.id, PlayerStatus#player_status.nickname, PlayerStatus#player_status.sex, 
				PlayerStatus#player_status.career, PlayerStatus#player_status.realm, PlayerStatus#player_status.guild#status_guild.guild_name, 
				PlayerStatus#player_status.combat_power, PlayerStatus#player_status.vip#status_vip.vip_type
			],
			mod_disperse:cast_to_unite(mod_rank, refresh_rank_of_player_power, [RankInfo]);
		_ ->
			skip
	end,
	ok.

%% [游戏线] 玩家等级上升时刷新进等级榜
refresh_player_level_rank(PlayerStatus) ->
	%% 30级以上玩家才会刷新榜
	RequireLV = 30,

	%% 等级大于某个值 才进行刷新进榜的业务
	case PlayerStatus#player_status.lv > RequireLV of
		true ->
			LVRankInfo = [
				PlayerStatus#player_status.id, PlayerStatus#player_status.nickname, PlayerStatus#player_status.sex, 
				PlayerStatus#player_status.career, PlayerStatus#player_status.realm, PlayerStatus#player_status.guild#status_guild.guild_name, 
				PlayerStatus#player_status.lv, PlayerStatus#player_status.vip#status_vip.vip_type, PlayerStatus#player_status.exp
			],
			mod_disperse:cast_to_unite(mod_rank, update_player_level_rank, [LVRankInfo]);
		_ ->
			skip
	end.

%% 变性，需要将该玩家在排行榜中有性别的榜中更换性别
change_sex(RoleId, RoleSex) ->
	private_change_sex(?RK_PERSON_FIGHT, 0, RoleId, RoleSex, private_change_sex_format1),
	private_change_sex(?RK_PERSON_LV, 0, RoleId, RoleSex, private_change_sex_format2),
	private_change_sex(?RK_PERSON_WEALTH, 0, RoleId, RoleSex, private_change_sex_format1),
	private_change_sex(?RK_PERSON_ACHIEVE, 0, RoleId, RoleSex, private_change_sex_format1),
	private_change_sex(?RK_PERSON_REPUTATION, 0, RoleId, RoleSex, private_change_sex_format1),
	private_change_sex(?RK_PERSON_CLOTHES, 0, RoleId, RoleSex, private_change_sex_format1),
	private_change_sex(?RK_PERSON_HUANHUA, 0, RoleId, RoleSex, private_change_sex_format1),
	private_change_sex(?RK_ARENA_DAY, 1, RoleId, RoleSex, private_change_sex_format3),
	private_change_sex(?RK_ARENA_WEEK, 0, RoleId, RoleSex, private_change_sex_format3),

	%% 处理魅力榜
	db:execute(io_lib:format(?SQL_RK_CHANGE_SEX, [RoleSex, RoleId])),
	private_change_charm(RoleId, RoleSex).

private_change_sex(RankType, SubType, RoleId, RoleSex, FunName) ->
	case private_get_rank_data(RankType, SubType) of
		[] ->
			skip;
		List ->
			%% 替换性别
			NewList = lists:map(fun(Row) -> apply(lib_rank_refresh, FunName, [Row, RoleId, RoleSex]) end, List),
			%% 回写回缓存
			RankId = lib_rank:make_rank_type(RankType, SubType),
			ets:insert(
				?ETS_RANK,
				private_make_rank_info(RankId, NewList)
			)
	end.

private_change_sex_format1(Row, RoleId, RoleSex) ->
	[Id, _A1, _Sex, _A2, _A3, _A4, _A5, _A6] = Row,
	case RoleId =:= Id of
		true -> [Id, _A1, RoleSex, _A2, _A3, _A4, _A5, _A6];
		_ -> Row
	end.
private_change_sex_format2(Row, RoleId, RoleSex) ->
	[Id, _A1, _Sex, _A2, _A3, _A4, _A5, _A6, _A7] = Row,
	case RoleId =:= Id of
		true -> [Id, _A1, RoleSex, _A2, _A3, _A4, _A5, _A6, _A7];
		_ -> Row
	end.
private_change_sex_format3(Row, RoleId, RoleSex) ->
	[Id, _A1, _A2, _A3, _Sex, _A4, _A5] = Row,
	case RoleId =:= Id of
		true -> [Id, _A1, _A2, _A3, RoleSex, _A4, _A5];
		_ -> Row
	end.

%% 处理魅力榜
private_change_charm(RoleId, RoleSex) ->
	case RoleSex of
		%% 现在是男的，以前是女的
		1 ->
			DailyId = ?RK_CHARM_DAY_FLOWER,
			DailyId2 = ?RK_CHARM_DAY_HUHUA,
			AllId = ?RK_CHARM_FLOWER,
			AllId2 = ?RK_CHARM_HUHUA;
		2 ->
			DailyId = ?RK_CHARM_DAY_HUHUA,
			DailyId2 = ?RK_CHARM_DAY_FLOWER,
			AllId = ?RK_CHARM_HUHUA,
			AllId2 = ?RK_CHARM_FLOWER
	end,
	private_rechange_charm_rank(RoleId, DailyId, DailyId2),
	private_rechange_charm_rank(RoleId, AllId, AllId2).

private_rechange_charm_rank(RoleId, RankType, RankType2) ->
	%% 处理每日
	case lib_rank:pp_get_rank(RankType) of
		[] ->
			skip;
		DailyList ->
			[DailyLastList, DailyLastRow] = 
			lists:foldl(fun(Row, [DailyAll, DailyRow]) -> 
				[DailyRoleId | _] = Row,
				case RoleId =:= DailyRoleId of
					true ->
						[DailyAll, Row];
					_ ->
						[[Row | DailyAll], DailyRow]
				end
			end, [[], []], DailyList),
			%% 在之前的榜中存在，数据需要拿到相反的榜
			case DailyLastRow of
				[] ->
					skip;
				_ ->
					%% 保存之前的榜数据
					DailyLastList2 = lists:reverse(DailyLastList),
					ets:insert(
						?ETS_RANK,
						private_make_rank_info(RankType, DailyLastList2)
					),
					%% 绑定称号
					lib_rank:rebind_design(RankType, DailyLastList2),
					%% 刷新相反的榜
					[NewRoleId, NewNickName, NewSex, NewCareer, NewRealm, NewGuildName, NewScore, NewImage] = DailyLastRow,
					private_refresh_rank_700(RankType2, [NewRoleId, NewNickName, NewSex, NewCareer, NewRealm, NewGuildName, NewImage], NewScore)
			end
	end.

%% 刷新 护花榜7001/鲜花榜7002
%% RankType : 排行榜类型7001或7002
%% Row : [RoleId, RoleName, RoleSex, RoleCareer, RoleRealm, GuildName]
%% AddScore : 新增的魅力值
private_refresh_rank_700(RankType, UpdateRow, AddScore) ->
	[NewRoleId, NewNickName, NewSex, NewCareer, NewRealm, NewGuildName, NewImage] = UpdateRow,
	DesignId = data_designation_config:get_design_id(RankType, 1),

	case private_get_rank_data(RankType, 0) of
		%% 第一个人上榜
		[] ->
			RankRecord = private_make_rank_info(RankType, [[NewRoleId, NewNickName, NewSex, NewCareer, NewRealm, NewGuildName, AddScore, NewImage]]),
			ets:insert(?ETS_RANK, RankRecord),

			%% 绑定称号
			lib_designation:bind_design(NewRoleId, DesignId, "", 1),

			%% 中秋国庆活动：魅力称号 西游第一帅，西游第一美
			case lists:member(RankType, [?RK_CHARM_DAY_HUHUA, ?RK_CHARM_DAY_FLOWER]) of
				true ->
					lib_activity_festival:bind_middle_and_national_design(RankType, NewRoleId);
				_ ->
					skip
			end;

		%% 非第一个人上榜，需要作几步的处理
		List when is_list(List) ->
			%% 取出排名第一的记录
			[FirstElement | _] = List,
			[FirstRoleId | _] = FirstElement,

		            %% 第一步：循环列表，替换排行值
		            F = fun(RankRow, [Exist, NewList]) ->
		                [OldRoleId, _, _, _, _, _, OldValue, _] = RankRow,
		                case OldRoleId =:= NewRoleId of
		                    true ->
		                        [1, [[NewRoleId, NewNickName, NewSex, NewCareer, NewRealm, NewGuildName, OldValue + AddScore, NewImage] | NewList]];
		                    _ ->
		                        [Exist, [RankRow | NewList]]
		                end
		            end,
		            [NewExist, List2] = lists:foldl(F, [0, []], List),
		
		            case NewExist of
		                %% 之前不在榜上
		                0 ->
		                    List3 = [[NewRoleId, NewNickName, NewSex, NewCareer, NewRealm, NewGuildName, AddScore, NewImage] | List2];
		                _ ->
		                    List3 = List2
		            end,

			%% 第二步：排序
			SortFun = fun([_, _, _, _, _, _, Power1, _], [_, _, _, _, _, _, Power2, _]) ->
				Power1 > Power2
			end,
			List4 = lists:sort(SortFun, List3),

			%% 第四步：截取指定条数据保留在榜单中
			List5 = case length(List4) > ?NUM_LIMIT of
				true ->
					lists:sublist(List4, 1, ?NUM_LIMIT);
				_ ->
					List4
			end,

			%% 取出最新排名第一的记录
			[NewFirstElement | _] = List5,
			[NewFirstRoleId, _, _, _, _, _, _, _] = NewFirstElement,

			%% 第五步：保存进榜单数据中
			RankRecord = private_make_rank_info(RankType, List5),
			ets:insert(?ETS_RANK, RankRecord),

			case is_integer(FirstRoleId) andalso is_integer(NewFirstRoleId) andalso FirstRoleId =/= NewFirstRoleId of
				true ->
					%% 绑定称号
					lib_designation:bind_design(NewFirstRoleId, DesignId, "", 1);
				_ ->
					skip
			end,

			%% 中秋国庆活动：魅力称号，西游第一帅，西游第一美
			case lists:member(RankType, [?RK_CHARM_DAY_HUHUA, ?RK_CHARM_DAY_FLOWER]) of
				true ->
					lib_activity_festival:bind_middle_and_national_design(RankType, NewFirstRoleId);
				_ ->
					skip
			end
	end.

%% 通过榜单，查找三个职业战力最高的记录
%% 1神将, 2天尊, 3罗刹
private_get_power_top_by_career(List) ->
	F = fun(Row, [Career1, Career2, Career3, Career1Row, Career2Row, Career3Row]) ->
		[_RoleId, _NickName, _Sex, Career, _Realm, _GuildName, Power, _Vip] = Row,
		if
			Career == 1 ->
				case Power > Career1 of
					true -> [Power, Career2, Career3, Row, Career2Row, Career3Row];
					_ -> [Career1, Career2, Career3, Career1Row, Career2Row, Career3Row]
				end;
			Career == 2 ->
				case Power > Career2 of
					true -> [Career1, Power, Career3, Career1Row, Row, Career3Row];
					_ -> [Career1, Career2, Career3, Career1Row, Career2Row, Career3Row]
				end;
			Career == 3 ->
				case Power > Career3 of
					true -> [Career1, Career2, Power, Career1Row, Career2Row, Row];
					_ -> [Career1, Career2, Career3, Career1Row, Career2Row, Career3Row]
				end;
			true -> [Career1, Career2, Career3, Career1Row, Career2Row, Career3Row]
		end	
	end,
	[LC1, LC2, LC3, LR1, LR2, LR3] = lists:foldl(F, [0, 0, 0, [], [], []], List),
	case LC1 > 0 of
		true ->
			[LR1Id, LR1NickName, LR1Sex, LR1Career, LR1Realm, _, _, _] = LR1,
			private_set_first_fight_rank(LR1Id, LR1NickName, LR1Realm, LR1Career, LR1Sex);
		_ -> skip
	end,
	case LC2 > 0 of
		true ->
			[LR2Id, LR2NickName, LR2Sex, LR2Career, LR2Realm, _, _, _] = LR2,
			private_set_first_fight_rank(LR2Id, LR2NickName, LR2Realm, LR2Career, LR2Sex);
		_ -> skip
	end,
	case LC3 > 0 of
		true ->
			[LR3Id, LR3NickName, LR3Sex, LR3Career, LR3Realm, _, _, _] = LR3,
			private_set_first_fight_rank(LR3Id, LR3NickName, LR3Realm, LR3Career, LR3Sex);
		_ -> skip
	end.

%% 获取指定当前排行榜数据
private_get_rank_data(RankType, SubType) ->
	NewRankType = lib_rank:make_rank_type(RankType, SubType),
	case ets:lookup(?ETS_RANK, NewRankType) of
		[RD] when is_record(RD, ets_rank) ->
			RD#ets_rank.rank_list;
		_ ->
			[]
	end.

%% 战斗力排行第一的玩家，在登录或切换场景时，每隔三小时发一次传闻
%% 此方法是在登录或切换的时候调用一次
private_set_first_fight_rank(RoleId, Name, Realm, Career, Sex) ->
	CacheKey = lists:concat([rank_power_first_, Career]),
	CacheTime = lists:concat([rank_power_first_time_, Career]),
	case mod_daily_dict:get_special_info(CacheKey) of
		%% 还没有处理排行第一的数据
		undefined ->
			mod_daily_dict:set_special_info(CacheKey, [RoleId, Name, Realm, Career, Sex]),
			mod_daily_dict:set_special_info(CacheTime, 0);
		Row ->
			[CId, _, _, _, _] = Row,
			case CId =:= RoleId of
				%% 如果排第一的还是同个人，不处理
				true ->
					skip;
				_ ->
					mod_daily_dict:set_special_info(CacheKey, [RoleId, Name, Realm, Career, Sex]),
					mod_daily_dict:set_special_info(CacheTime, 0)
			end
	end.

%% 构造排行榜数据在ets中的record
private_make_rank_info(TypeId, List) ->
    #ets_rank{type_id = TypeId, rank_list = List}.
