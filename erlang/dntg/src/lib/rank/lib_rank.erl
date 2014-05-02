%%%--------------------------------------
%%% @Module  : lib_rank
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.5.31
%%% @Description :  排行榜
%%%--------------------------------------

-module(lib_rank).
-include("common.hrl").
-include("record.hrl").
-include("goods.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("guild.hrl").
-include("rank.hrl").
-include("sql_rank.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("designation.hrl").
-include("fame_limit.hrl").
-include("marriage.hrl").
-compile(export_all).

%% 获取排行榜数据
pp_get_rank(RankType) ->
	private_get_rank_data(RankType, 0).

%% 公共线启动时初始化数据
unite_start() ->
	%% 将玩家被崇拜/鄙视数据读到ets中
	try db:get_all(io_lib:format(?SQL_RK_FETCH_ALL_POPULARITY, [])) of
		RoleInfoList when is_list(RoleInfoList) ->
			lists:foreach(fun([RoleId, PopularityInfo]) ->
				Popularity = util:to_term(PopularityInfo),
				Record = #ets_role_rank_info{role_id = RoleId, popularity = Popularity, stren7_num = 0, equip_list = null},
				ets:insert(?ETS_ROLE_RANK_INFO, Record)
			end, RoleInfoList),
			ok;
		_ ->
			error
	catch
		_:_ ->
			error
	end,

	%% 初始化名人堂排行榜
	private_init_rame_rank(0).

%% 刷新排行榜数据
refresh_rank(RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate) ->
	private_all_rank(RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate, 0).

%% 定时器每天刷新排行榜数据
timer_refresh_rank(RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate) ->
	private_all_rank(RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate, 1).

%% 刷新单个榜或全部榜
refresh_single(RankType) ->
	case RankType =:= 0 of
		true ->	
			%% 刷新其他所有榜
			refresh_rank(true, true, true, true, true, true, true, true);
		_ ->
			%% 只刷新一个榜
			private_make_data(RankType, 0)
	end.

%% 刷新单个榜或全部榜
timer_refresh_single(RankType) ->
	case RankType =:= 0 of
		true ->	
			%% 刷新其他所有榜
			timer_refresh_rank(true, true, true, true, true, true, true, true);
		_ ->
			%% 只刷新一个榜
			private_make_data(RankType, 1)
	end.

%% 排行榜刷新单个榜
refresh_single_by_timer(RankType) ->
	private_make_data(RankType, 1).

%% 按榜大类型刷
refresh_single_by_type(Type) ->
	if
		Type =:= charm ->
			lists:foreach(fun(RankType) -> private_make_data(RankType, 0) end, ?RK_TYPE_CHARM_LIST);
		true ->
			skip
	end.

%% 获取玩家战力榜记录
%% 返回：[] 或者 [[玩家id,玩家昵称,性别,职业,阵营,帮派名,排行数值,vip], ...]
get_power_rank_data(Num) ->
	case private_get_rank_data(?RK_PERSON_FIGHT, 0) of
		[] ->
			[];
		List ->
			Len = length(List),
			case Len > Num of
				true ->
					lists:sublist(List, 1, Num);
				_ ->
					lists:sublist(List, 1, Len)
			end
	end.

%% [数据后台调用] 刷新全部排行榜
refresh_by_manage_system(TimerType) ->
	Now = util:unixtime(),
	case get(lib_rank_refresh_by_manage_system) of
		undefined ->
			case TimerType of
				0 ->
					mod_disperse:cast_to_unite(mod_rank, refresh_rank, [true, true, true, true, true, true, true, true]);
				_ ->
					mod_disperse:cast_to_unite(mod_rank, timer_refresh_rank, [true, true, true, true, true, true, true, true])
			end,
			put(lib_rank_refresh_by_manage_system, Now);
		Value ->
			case Value + 60 > Now of
				true ->
					skip;
			    _ ->
					case TimerType of
						0 ->
							mod_disperse:cast_to_unite(mod_rank, refresh_rank, [true, true, true, true, true, true, true, true]);
						_ ->
							mod_disperse:cast_to_unite(mod_rank, timer_refresh_rank, [true, true, true, true, true, true, true, true])
					end,
					put(lib_rank_refresh_by_manage_system, Now)
			end
	end,
	ok.

%% 数据后台调用刷新单个榜
refresh_single_by_manage_system(RankType) ->
	case is_integer(RankType) of
		true ->
			mod_disperse:cast_to_unite(mod_rank, refresh_single, [RankType]),
			ok;
		_ ->
			ok
	end.

%% 数据后台调用刷新单个榜
refresh_single_by_manage_system_timer(RankType) ->
	case is_integer(RankType) of
		true ->
			mod_disperse:cast_to_unite(mod_rank, timer_refresh_single, [RankType]),
			ok;
		_ ->
			ok
	end.

%% 在排行榜刷新时，刷新玩家称号
rebind_design(RankType, RankList) ->
	Len = length(RankList),
	case Len > 0 of
		true ->
			%% 刷新排行第1名玩家的称号
			RoleId = private_get_first_roleid(RankList),
			case is_integer(RoleId) of
				true ->
					%% 绑定第一名称号
					private_refresh_first_design(RankType, RoleId),

					%% 绑定活动称号
					case RankType == ?RK_CHARM_DAY_FLOWER of
						true ->
							lib_activity_festival:qixi_bind_design_for_rank(RoleId);
						_ ->
							skip
					end;
				_ ->
					skip
			end,

			%% 刷新排行第2至10名玩家的称号
			case Len > 1 of
				true ->
					case private_get_second_to_ten_roleid(RankList) of
						[] -> skip;
						NewIds ->
							private_refresh_second_to_ten_design(RankType, NewIds)
					end;
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%% 更新排行榜名人堂荣誉完成情况
update_fame(FameId, PlayerList) ->
	case private_get_rank_data(?RK_FAME, 0) of
		[] ->
			skip;
		List when is_list(List) ->
			F = fun(R) ->
				[FId, FStatus, FList] = R,
				[NewStatus, NewList] = case FameId =:= FId of
					true ->
						[1, [PlayerList | FList]];
					_ ->
						[FStatus, FList]
				end,
				[FId, NewStatus, NewList]
			end,
			
			NewFameList = [F(Record) || Record <- List],
			RankRecord = private_make_rank_info(?RK_FAME, NewFameList),
    		ets:insert(?ETS_RANK, RankRecord);
		_ ->
			skip
	end.

%% 刷新竞技场每日上榜
refresh_arena_day() ->
	db:execute(io_lib:format(?SQL_RK_ARENA_DAY_DELETE, [])),
	db:execute(io_lib:format(?SQL_RK_ARENA_DAY_INSERT, [util:unixdate()])),
	refresh_single(?RK_ARENA_DAY),
	case pp_get_rank(?RK_ARENA_DAY) of
		[] ->
			skip;
		List ->
			%% 积分第一的玩家
			FirstId = case catch lists:sublist(List, 1) of
				[[TmpFirstId | _]] -> TmpFirstId;
				_ -> 0
			end,

			%% 竞技场积分第一的玩家获得称号
			lib_designation:bind_design_in_server(FirstId, 201409, "", 1),

			MergeTime = lib_activity_merge:get_activity_time(),
			case MergeTime > 0 of
				true ->
					%% 合服活动：竞技场上，谁是将军
					lib_activity_merge:do_rank_anera(List, MergeTime),
					
					%% 合服名人堂：首日竞技场积分第一
					lib_player_unite:trigger_fame(FirstId, [
						MergeTime, FirstId, 11701, 0, 1
					]),

					%% 合服名人堂：首日竞技场杀人第一
					case length(List) > 0 of
						true ->
							%% 找出杀人数第一的玩家
							[TargetRoleId, _TargetKill] = 
							lists:foldl(fun([RankRoleId, _, _, _, _, RankKill, _], [RoleId, Kill]) -> 
								case RankKill > Kill of
									true ->
										[RankRoleId, RankKill];
									_ ->
										[RoleId, Kill]
								end
							end, [0, 0], List),
							case TargetRoleId > 0 of
								true ->
									lib_player_unite:trigger_fame(TargetRoleId, [
										MergeTime, TargetRoleId, 11801, 0, 1
									]);
								_ ->
									skip
							end;
						_ ->
							skip
					end;
				_ ->
					skip
			end
	end.

%% [公共线]送花时调用，记录每日护花或鲜花榜
give_flower_daily(FromId, FromName, FromCareer, FromRealm, FromSex, FromGuild, FromImage, ToId, ToName, ToCareer, ToRealm, ToSex, ToGuild, ToImage, Score) ->
	private_update_score(FromId, FromName, FromCareer, FromRealm, FromSex, Score),
	case FromId /= ToId of
		true -> private_update_score(ToId, ToName, ToCareer, ToRealm, ToSex, Score);
		_ -> skip
	end,
	%% 刷新魅力排行榜
	RefreshData = {
		Score,
		{from, [FromId, FromName, FromSex, FromCareer, FromRealm, FromGuild, FromImage]},
		{to, [ToId, ToName, ToSex, ToCareer, ToRealm, ToGuild, ToImage]} 
	},
	mod_rank:refresh_flower_rank(RefreshData).

%% 参与战斗力评分，评分后才有可能上战斗力榜
eva_combat_power(PS) ->
	case PS#player_status.combat_power > 500 of
		true ->
			%% 这里需要发到公共线实时对战斗力进行排行
			mod_disperse:cast_to_unite(mod_rank, refresh_rank_of_player_power, [[
				PS#player_status.id,
				PS#player_status.nickname,
				PS#player_status.sex,
				PS#player_status.career,
				PS#player_status.realm,
				PS#player_status.guild#status_guild.guild_name,
				PS#player_status.combat_power,
				PS#player_status.vip#status_vip.vip_type
			]]);
		_ ->
			skip
	end.

%% 发送战斗力排行第一玩家的传闻，在登录或切换场景时每隔三小时发一次
%% PlayerCareer : 玩家职业
send_first_fight_rank_cw(PlayerId, PlayerCareer) ->
	CacheKey = lists:concat([rank_power_first_, PlayerCareer]),
	CacheTime = lists:concat([rank_power_first_time_, PlayerCareer]),
	case mod_daily_dict:get_special_info(CacheTime) of
		Time when is_integer(Time) ->
			NowTime = util:unixtime(),
			case NowTime - Time < ?RK_FIGHT_RANK_CW_TIME of
				true ->
					skip;
				_ ->
					case mod_daily_dict:get_special_info(CacheKey) of
						[RoleId, Name, Realm, Career, Sex] ->
							case PlayerId =/= RoleId of
								true ->
									skip;
								_ ->
									lib_chat:send_TV({all},1, 2, ["fightRank", 1, RoleId, Realm, Name, Sex, Career, 0]),
									mod_daily_dict:set_special_info(CacheTime, NowTime)
							end;
						_ ->
							skip
					end,
                    %% 长安城主传闻
                    lib_player:update_player_info(PlayerId, [{castellan, no}])
			end;
		_ ->
			skip
	end.

%% 最强战力玩家被杀传闻
%% 返回：bool
power_top_killed_cw(PlayerId, PlayerCareer, [Id2,Realm2,Name2,Sex2,Career2,Scene2,X2,Y2]) ->
	CacheKey = lists:concat([rank_power_first_, PlayerCareer]),
	case mod_daily_dict:get_special_info(CacheKey) of
		[RoleId, Name, Realm, Career, Sex] ->
			case PlayerId =/= RoleId of
				true ->
					false;
				_ ->
					Index = if
						PlayerCareer == 1 -> 2;
						PlayerCareer == 2 -> 3;
						PlayerCareer == 3 -> 4;
						true -> 2
					end,
					lib_chat:send_TV(
						{all}, 0, 2, 
						["yewaiPK", Index, RoleId, Realm, Name, Sex, Career, 0, 
						Id2,Realm2,Name2,Sex2,Career2, 0, Scene2, X2, Y2]
					),
					true
			end;
		_ ->
			false
	end.

%% 获取排行榜前50级玩家等级平均值
get_average_level() ->
	NowTime = util:unixtime(),
	case get(rank_average_level) of
		undefined ->
			Level = private_get_average_level(),
			put(rank_average_level, [NowTime, Level]);
		[Time, AveLevel] ->
			case Time + 120 > NowTime of
				true ->
					Level = AveLevel;
				_ ->
					Level = private_get_average_level(),
					put(rank_average_level, [NowTime, Level])
			end;
		_ ->
			Level = private_get_average_level(),
			put(rank_average_level, [NowTime, Level])
	end,
	Level.

private_get_average_level() ->
	case private_get_rank_data(?RK_PERSON_LV, 0) of
		[] ->
			0;
		RankList ->
			[Len, Total] = 
			lists:foldl(fun(Item, [Position, Sum]) -> 
				[_, _, _, _, _, _, LV, _, _] = Item,
				NewPosition = Position + 1,
				case NewPosition < 51 of
					true ->
						[NewPosition, Sum + LV];
					_ ->
						[Position, Sum]
				end
			end, [0, 0], RankList),
			round(Total / Len)
	end.

%% 评估穿在身上的装备
%% @spec evaluate_equip_list(PlayerId, PlayerName) -> [1, ScoreList] | [0, FailReason]
evaluate_equip_list(PS) ->
	PlayerId = PS#player_status.id,
	PlayerName = PS#player_status.nickname,
	Dict = lib_goods_dict:get_player_dict(PS),
    case lib_goods_util:get_equip_list(PlayerId, ?EQUIP, ?GOODS_LOC_EQUIP, Dict) of
		%% 身上无装备
        [] ->
			{error, 2};
        EquipList ->
            F = fun(Equip) ->
                    GoodsId = Equip#goods.id,
                    GoodsTypeId = Equip#goods.goods_id,
                    SubType = Equip#goods.subtype,
                    case Equip#goods.type == ?EQUIP andalso lists:member(SubType, ?RK_EQUIP_SUBTYPE) of
                        true ->
                            case data_goods_type:get(GoodsTypeId) of
                                [] ->
                                    [GoodsId, GoodsTypeId, SubType, PlayerId, list_to_binary(PlayerName), Equip#goods.color, 0, 0];
                                Info ->
                                    Career = Info#ets_goods_type.career,
                                    Color = Equip#goods.color,
                                    Score = private_get_equip_score(Equip, PS#player_status.career),
                                    [GoodsId, GoodsTypeId, SubType, PlayerId, list_to_binary(PlayerName), Color, Career, Score]
                            end;
                        false ->
                            [GoodsId, GoodsTypeId, SubType, PlayerId, list_to_binary(PlayerName), Equip#goods.color, 0, 0]
                    end
            end,
            ScoreList = [F(Equip) || Equip <- EquipList],
            SList = lists:filter(fun(List) -> lists:last(List) /= 0 end, ScoreList),
            case length(SList) of
                0 ->
					{error, 0};
                _ ->
					%% 向公共服务器发送评分数据，供参与装备排行
                    mod_disperse:cast_to_unite(mod_rank, update_equip_rank, [SList]),
					{ok, ScoreList}
            end
    end.

%% 评估单件装备（在游戏服务器玩家进程执行）
%% @spec evaluate_equip(GoodsId, PlayerId, PlayerName) -> [Result, DoubleScore]
%% @param Result : integer(), 0 | 1 （失败 | 成功）
%% @param DoubleScore  : integer(), 失败原因 | 分数
evaluate_equip(GoodsPid, GoodsId, PlayerId, PlayerName, PlayerCareer) ->
	Dict = lib_goods_dict:get_player_dict_by_goods_pid(GoodsPid),
    case lib_goods_util:get_goods_info(GoodsId, Dict) of
		%% 玩家物品不存在
        [] -> 
			[0, 0];
        Goods ->
            case Goods#goods.player_id == PlayerId of
				%% 不是玩家自己的物品
				false -> 
					[0, 0];
                _ ->
                    case Goods#goods.type == ?EQUIP andalso lists:member(Goods#goods.subtype, ?RK_EQUIP_SUBTYPE) of
                        %% 非装备类物品
						false -> 
							[0, 1];
						true ->
                            GoodsTypeId = Goods#goods.goods_id,
                            case data_goods_type:get(GoodsTypeId) of
								%% 物品没有配置
                                [] -> 
									[0, 0];
                                Info ->
									%% 计算评分
									Score = private_get_equip_score(Goods, PlayerCareer),
									case Score > 0 of
										true ->
		                                    %% 向公共线发送评分数据，供参与装备排行
		 									Career = Info#ets_goods_type.career,
		                                    Color = Goods#goods.color,

											%% 发到公共线刷新装备排行榜
											mod_disperse:cast_to_unite(mod_rank, update_equip_rank, [[[
												GoodsId,
												GoodsTypeId,
												Goods#goods.subtype,
												PlayerId,
												list_to_binary(PlayerName),
												Color,
												Career,
												Score
											]]]);
										_ ->
											skip
									end,
                                    [1, Score]
                            end
                    end
            end
    end.

%% 通过装备子类型，获得存入表字段中的类型
private_get_equip_db_type(Type) ->
	Re1 = lists:member(Type, ?RK_EQUIP_WEAPON_SUBTYPE),
	Re2 = lists:member(Type, ?RK_EQUIP_DEFEND_SUBTYPE),
	Re3 = lists:member(Type, ?RK_EQUIP_SHIPIN_SUBTYPE),
	if
		Re1 =:= true -> 1;
		Re2 =:= true -> 2;
		Re3 =:= true -> 3;
		true -> 0
	end.

%% 查看人物详细信息
query_role_rank_info(UniteStatus, RoleId, RankType, Position) ->
	case lists:member(RankType, ?ROLE_RANK_INFO_LIST) of
		false ->
			{error, 2};
		_ ->
			case is_on_role_rank(RoleId, RankType) of
				%% 不在榜上不能查看
				false ->	
					{error, 3};
				_ ->
					%% 获取结婚对象id和昵称
					Marriage = lib_player:get_player_info(RoleId, marriage),
					case is_record(Marriage, status_marriage) of
				        true ->
                            ParnerId = Marriage#status_marriage.parner_id,
				            ParnerName = Marriage#status_marriage.parner_name;
				        _ ->
                            ParnerId = 0,
				            ParnerName = ""
				    end,

					%% 获取仙缘属性
                    [XY1, XY2, XY3, XY4, XY5, XY6, XY7, XY8, XY9, XY10, 
					 XY1_1, XY2_1, XY3_1,XY4_1, XY5_1, XY6_1, XY7_1, XY8_1, XY9_1, XY10_1,
					 XYLevel] = lib_xianyuan:player_xianyuan_attribute(UniteStatus#unite_status.id, RoleId),
                    
					%% 获取元神属性
                    ToMerdian = private_get_meridian_data(RoleId),
					
                    %% 取得套装id
                    case lib_player:get_player_info(RoleId, goods) of
                        Goods when is_record(Goods, status_goods) ->
                            Dict = lib_goods_dict:get_player_dict_by_goods_pid(Goods#status_goods.goods_pid);
                        _ ->
                            Dict = []
                    end,
                    [{Str1, StrNum1}, {Str2, StrNum2}, {Str3, StrNum3}] = 
                    case Dict =/= [] of
                        true ->
                            lib_goods_util:get_suit_id_and_num(RoleId, Dict);
                        false ->
                            [{0,0}, {0,0}, {0,0}]
                    end,
                    %% 已使用崇拜/鄙视次数
					ActionNum = mod_daily:get_count(UniteStatus#unite_status.dailypid, UniteStatus#unite_status.id, 2200),

					%% 获取玩家身上装备
					EquipList = get_equip_list(RoleId),
					NewEquipList = private_format_equip(EquipList),

					%% 称号id
					DesignId = private_get_designation_id(RankType, Position),
					%% 获取排行辅助数据
					RankInfo = private_get_rank_info(RoleId),
					[ChongBai, BiShi] = private_get_action_num(RankInfo),
					
					Stren7Num = case RankInfo#ets_role_rank_info.stren7_num =:= 0 of
						true ->
							TmpStren7Num = lib_goods_util:get_stren7_num_from_list(EquipList),
							ets:insert(?ETS_ROLE_RANK_INFO, RankInfo#ets_role_rank_info{stren7_num = TmpStren7Num}),
							TmpStren7Num;
						_ ->
							RankInfo#ets_role_rank_info.stren7_num
					end,
					Data = case UniteStatus#unite_status.id =:= RoleId of
						%% 查看自己
						true ->
							%% 器灵
							[QLForza, QLAgile, QLWit, QLThew] = 
								case lib_player:get_player_info(UniteStatus#unite_status.id, qiling) of
									[Qiling] -> lib_qiling:calc_qiling_attr(Qiling);
									_ -> [0, 0, 0, 0]
								end,

							[
							 	
								UniteStatus#unite_status.id, UniteStatus#unite_status.name, UniteStatus#unite_status.sex, UniteStatus#unite_status.career, 
								UniteStatus#unite_status.realm, UniteStatus#unite_status.lv, ChongBai, BiShi, NewEquipList, ActionNum, Stren7Num, DesignId,
								ParnerId, ParnerName, 
								XY1, XY2, XY3, XY4, XY5, XY6, XY7, XY8, XY9, XY10, XYLevel,
								XY1_1, XY2_1, XY3_1,XY4_1, XY5_1, XY6_1, XY7_1, XY8_1, XY9_1, XY10_1,
								%% 无神
								ToMerdian,
								Str1, StrNum1, Str2, StrNum2, Str3, StrNum3,
								QLForza, QLAgile, QLWit, QLThew
							];
						%% 查看别人
						_ ->
							case lib_player:is_online_unite(RoleId) of
								%% 在线
								true ->
									Status = lib_player_unite:get_unite_status_unite(RoleId),
									
									[QLForza, QLAgile, QLWit, QLThew] = 
									case lib_player:get_player_info(RoleId, qiling) of
										[Qiling] -> lib_qiling:calc_qiling_attr(Qiling);
										_ -> [0, 0, 0, 0]
									end,
									
									[
                                        Status#unite_status.id, Status#unite_status.name, Status#unite_status.sex, 
                                        Status#unite_status.career, Status#unite_status.realm, Status#unite_status.lv,
									    ChongBai, BiShi, NewEquipList, ActionNum, Stren7Num, DesignId,
                                        ParnerId, ParnerName, 
                                        XY1, XY2, XY3, XY4, XY5, XY6, XY7, XY8, XY9, XY10, XYLevel,
										XY1_1, XY2_1, XY3_1,XY4_1, XY5_1, XY6_1, XY7_1, XY8_1, XY9_1, XY10_1,
                                        ToMerdian,
                                        Str1, StrNum1, Str2, StrNum2, Str3, StrNum3,
										QLForza, QLAgile, QLWit, QLThew
                                    ];
								_ ->
									[QLForza, QLAgile, QLWit, QLThew] = [0, 0, 0, 0],

									[Nick, Sex, LV, Career, Realm, _GuildId, _MountLimit, _HusongNpc, _Image|_] = lib_player:get_player_low_data(RoleId),
									[
                                        RoleId, Nick, Sex, Career, Realm, LV,ChongBai, BiShi, NewEquipList, ActionNum, Stren7Num, DesignId,
                                        ParnerId, ParnerName, 
                                        XY1, XY2, XY3, XY4, XY5, XY6, XY7, XY8, XY9, XY10, XYLevel,
										XY1_1, XY2_1, XY3_1,XY4_1, XY5_1, XY6_1, XY7_1, XY8_1, XY9_1, XY10_1,
                                        ToMerdian,
                                        Str1, StrNum1, Str2, StrNum2, Str3, StrNum3,
										QLForza, QLAgile, QLWit, QLThew
                                    ]
							end
					end,
					{ok, Data}
			end
	end.

%% 刷新所有排行榜
private_all_rank(RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate, FromTimer) ->
	case RoleUpdate of
		true -> 
			lists:foreach(fun(RankType) -> private_make_data(RankType, FromTimer) end, ?RK_TYPE_ROLE_LIST);
		_ -> skip
	end,
	case CharmUpdate of
		true -> 
			lists:foreach(fun(RankType) -> private_make_data(RankType, FromTimer) end, ?RK_TYPE_CHARM_LIST);
		_ -> skip
	end,
	case PetUpdate of
		true -> 
			lists:foreach(fun(RankType) -> private_make_data(RankType, FromTimer) end, ?RK_TYPE_PET_LIST);
		_ -> skip
	end,
	case EquipUpdate of
		true -> 
			lists:foreach(fun(RankType) -> private_make_data(RankType, FromTimer) end, ?RK_TYPE_EQUIP_LIST);
		_ -> skip
	end,
	case GuildUpdate of
		true -> 
			lists:foreach(fun(RankType) -> private_make_data(RankType, FromTimer) end, ?RK_TYPE_GUILD_LIST);
		_ -> skip
	end,
	case ArenaUpdate of
		true -> 
			lists:foreach(fun(RankType) -> private_make_data(RankType, FromTimer) end, ?RK_TYPE_ARENA_LIST);
		_ -> skip
	end,
	case CopyUpdate of
		true -> 
			lists:foreach(fun(RankType) -> private_make_data(RankType, FromTimer) end, ?RK_TYPE_COPY_LIST);
		_ -> skip
	end,
	case MountUpdate of
		true -> 
			lists:foreach(fun(RankType) -> private_make_data(RankType, FromTimer) end, ?RK_TYPE_MOUNT_LIST);
		_ -> skip
	end.

%% 查看元神信息
private_get_meridian_data(Uid) ->
	case lib_player:get_player_info(Uid, player_meridian) of
        false->
            {0, [{0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}, {0,0}]};
        PlayerMeridian ->
			PlayerMeridian2 = mod_meridian:getPlayer_meridian(PlayerMeridian),
%% 			{MeridianGap, [
%% 				{MerHp3,GenHp3}, {MerMp3,GenMp3}, {MerDef3,GenDef3}, {MerHit3,GenHit3}, 
%% 				{MerDodge3,GenDodge3}, {MerTen3,GenTen3}, {MerCrit3,GenCrit3}, {MerAtt3,GenAtt3}, 
%% 				{MerFire3,GenFire3}, {MerIce3,GenIce3}, {MerDrug3,Gen_Drug3}
%% 			]} = 
			lib_meridian:count_attr(PlayerMeridian2)
    end.
%%     case lib_player:get_player_info(Uid, player_meridian) of
%%         false->
%%             [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
%%         Player_meridian->
%%             [Hp3, Mp3, Def3, Hit3, Dodge3, Ten3,Crit3, Att3, Fire3, Ice3, Drug3] = mod_meridian:count_meridian_attribute(Player_meridian),
%%             T_Player_meridian = mod_meridian:getPlayer_meridian(Player_meridian),
%%             {Meridian_Gap,_} = lib_meridian:count_attr(T_Player_meridian),
%%             [Hp3, Mp3, Def3, Hit3, Dodge3, Ten3,Crit3, Att3, Fire3, Ice3, Drug3,Meridian_Gap]
%%     end.

%% 格式化装备数据
private_format_equip(List) ->
	F = fun(RD) ->
		%% 耐久度
		Naijiudu = data_goods:count_goods_attrition(RD#goods.equip_type, RD#goods.attrition, RD#goods.use_num),
		Id = RD#goods.id,
		Bind = RD#goods.bind,
		Trade = RD#goods.trade,
		Sell = RD#goods.sell,
		IsDrop = RD#goods.isdrop,
		GoodsId = RD#goods.goods_id,
		Cell = RD#goods.cell,
		Type = RD#goods.type,
		SubType = RD#goods.subtype,
		Color = RD#goods.color,
		Num = RD#goods.num,
		Prefix = RD#goods.prefix,
		Stren = RD#goods.stren,
		Hole = RD#goods.hole,
		<<Id:32, Bind:8, Trade:8, Sell:8, IsDrop:8, Naijiudu:8, GoodsId:32, Cell:8, Type:8, SubType:8, Color:8, Num:8, Prefix:8, Stren:8, Hole:8>>
	end,
	[F(Goods) || Goods <- List].

%% 获取排行榜位置是否有配置称号
private_get_designation_id(RankType, Position) ->
	if
		Position < 2 -> data_designation_config:get_design_id(RankType, 1);
		Position < 11 -> data_designation_config:get_design_id(RankType, 2);
		true -> 0
	end.

%% 装备类型 对应 装备排行榜类型
private_equiptype_to_ranktype(EquipType) ->
	if 
		EquipType =:= 1 -> ?RK_EQUIP_WEAPON;
		EquipType =:= 2 -> ?RK_EQUIP_DEFENG;
		EquipType =:= 3 -> ?RK_EQUIP_SHIPIN;
		true -> 0
	end.

%% 获取ets中的排行辅助数据
private_get_rank_info(RoleId) ->
	case catch ets:lookup(?ETS_ROLE_RANK_INFO, RoleId) of
	    [EtsRole] ->
	        EtsRole;
	    _ ->
			case check_unload_role_on_db(RoleId) of
				error ->
					[];
				RD ->
					RD
			end
	end.

%% 获取崇拜或鄙视次数
private_get_action_num(RankInfo) ->
	case is_record(RankInfo, ets_role_rank_info) of
		true ->
			Popularity = RankInfo#ets_role_rank_info.popularity,
		    Type = 0,   %% 崇拜鄙视数据统一计在类型0中
		    case lists:keyfind(Type, 1, Popularity) of
		        false ->
					[0, 0];
		        {_, Worship, Disdain} ->
		           [Worship, Disdain]
		    end;
		_ ->
			[0, 0]
	end.

%% 检查角色是否在榜，若在榜一并重新加载数据 -> false | error | EtsRoleRankInfo
check_rank_role_info(RoleId, RankTypeNum) ->
    case is_on_role_rank(RoleId, RankTypeNum) of
		%% 不在榜
        false -> 
            false;
        _ ->
            check_unload_role_on_db(RoleId)
    end.

%% 查询角色是否在对应排行榜上
%% @return false | integer
is_on_role_rank(RoleId, RankType) ->
	List1 = ?RK_TYPE_ROLE_LIST ++ [?RK_ARENA_WEEK, ?RK_ARENA_KILL, ?RK_COPY_COIN, ?RK_CHARM_DAY_HUHUA, ?RK_CHARM_DAY_FLOWER, ?RK_CHARM_HUHUA, ?RK_CHARM_FLOWER, ?RK_FAME_COIN, ?RK_FAME_TAOBAO, ?RK_FAME_EXP, ?RK_FAME_PT],
	List2 = [?RK_ARENA_DAY, ?RK_COPY_NINE],
	InList1 = lists:member(RankType, List1),
	InList2 = 	lists:member(RankType, List2),
    if
		InList1 =:= true ->
            case private_get_rank_data(RankType, 0) of
				[] -> 
					false;
                EtsRank ->
                    util:keyfind(RoleId, 1, EtsRank)
            end;
		InList2 =:= true ->
			 case private_get_rank_data(RankType, 0) of
				[] -> 
					false;
                EtsRank ->
                    util:keyfind(RoleId, 2, EtsRank)
            end;
		true ->
            false
    end.

%% 检查未加载到数据的角色在数据库中是否存在信息 -> error | EtsRoleRankInfo
check_unload_role_on_db(RoleId) ->
    Sql = io_lib:format(?SQL_RK_FETCH_POPULARITY, [RoleId]),
    try db:get_one(Sql) of
        null ->
            Sql2 = io_lib:format(?sql_insert_rank_role_popularity, [RoleId]),
            catch db:execute(Sql2),
            Record = #ets_role_rank_info{role_id=RoleId, popularity=[], equip_list=null},
            ets:insert(?ETS_ROLE_RANK_INFO, Record),
            Record;
        PopularityInfo ->
            Popularity = lib_goods_util:to_term(PopularityInfo),
            Record = #ets_role_rank_info{role_id = RoleId, popularity = Popularity, equip_list = null},
            ets:insert(?ETS_ROLE_RANK_INFO, Record),
            Record
   catch
       _:_ -> error
   end.

%% -> error | [RoleId, Nickname, Sex, Career, Realm, Level]
get_role_info_on_db(RoleId) ->
    Sql = io_lib:format(?sql_select_role_info, [RoleId]),
    case db:get_all(Sql) of
        [RoleInfo] -> RoleInfo;
        _ -> error
    end.

%% 角色被崇拜或鄙视 -> {ok, Worship, Disdain} | {error, ErrorCode}
%% RoleId：被崇拜或鄙视的玩家
%% RankTypeNum：排行榜id
%% LookUponType : 1 为崇拜，2鄙视
%% RoleAId：操作者id
look_upon_role(RoleId, RankTypeNum, LookUponType, RoleAId) ->
    case RoleId =:= RoleAId of
		%% 不能崇拜鄙视自己
        true -> {error, 5};
        false ->
            case lists:member(RankTypeNum, ?ROLE_RANK_INFO_LIST) of
				%% 排行榜类型有误
                false -> {error, 2};
                _ ->
                    case is_on_role_rank(RoleId, RankTypeNum) of
						%% 不在对应排行榜上
                        false -> {error, 3};
                        _ ->
                            case ets:lookup(?ETS_ROLE_RANK_INFO, RoleId) of
                                [EtsRole] ->
                                    [Worship, Disdain] = look_upon_role_by_ets_role(EtsRole, RankTypeNum, LookUponType),
                                    {ok, Worship, Disdain};
                                _ ->
                                    case ets:info(?ETS_ROLE_RANK_INFO, size) of
										%% 未加载数据
                                        0 -> 
											 {error, 0};
										%% 角色不在所有角色排行榜上
                                        _ -> 
                                            case check_unload_role_on_db(RoleId) of
												%% 加载数据有误
                                                error -> 
                                                    {error, 0};
                                                EtsRole ->
                                                    [Worship, Disdain] = look_upon_role_by_ets_role(EtsRole, RankTypeNum, LookUponType),
                                                    {ok, Worship, Disdain}
                                            end
                                    end
                            end
                    end
            end
    end.

%% 角色被崇拜或鄙视（已加载信息情况下处理） -> [Worship, Disdain]
look_upon_role_by_ets_role(EtsRoleRankInfo, _RankTypeNum, LookUponType) ->
    RoleId = EtsRoleRankInfo#ets_role_rank_info.role_id,
    Popularity = EtsRoleRankInfo#ets_role_rank_info.popularity,
    Type = 0,   %% 崇拜鄙视数据统一计在类型0中
    NewPopularity =
    case lists:keyfind(Type, 1, Popularity) of
        false ->
            case LookUponType =:= 1 of
                true ->
                    Return = [1, 0],
                    [{Type, 1, 0} | Popularity];
                false ->
                    Return = [0, 1],
                    [{Type, 0, 1} | Popularity]
            end;
        {_, Worship, Disdain} ->
            case LookUponType =:= 1 of
                true ->
                    Return = [Worship + 1, Disdain],
                    lists:keyreplace(Type, 1, Popularity, {Type, Worship + 1, Disdain});
                false ->
                    Return = [Worship, Disdain + 1],
                    lists:keyreplace(Type, 1, Popularity, {Type, Worship, Disdain + 1})
            end
    end,
    NewEtsRole = EtsRoleRankInfo#ets_role_rank_info{popularity = NewPopularity},
    ets:insert(?ETS_ROLE_RANK_INFO, NewEtsRole),
    catch update_popu_on_db(RoleId, NewPopularity),
    Return.

%% 数据库中更新崇拜鄙视数据
update_popu_on_db(RoleId, NewPopularity) ->
    PopularityInfo = util:term_to_string(NewPopularity),
    Sql = io_lib:format(?sql_update_rank_role_popularity, [RoleId, PopularityInfo]),
    db:execute(Sql).

%% 获得玩家身上装备列表
%% ViewId：正在公共线排行榜查看的人的ID
%% RoleId：被查看的人的ID
get_equip_list(RoleId) ->
	get_equip_list_from_db(RoleId).
%%   case misc:get_player_process(RoleId) of
%%     Pid when is_pid(Pid) ->
%% 		Dict = gen_server:call(Pid, {'apply_call', lib_goods_dict, get_player_dict_by_goods_pid, [Pid]}),
%% 		case gen_server:call(Pid, {'apply_call', lib_goods_util, get_equip_list, [RoleId, Dict]}) of
%% 			[_Moudle, _Method, _Args, _Info] ->
%% 				io:format("get_equip_list 1~n"),
%% 				get_equip_list_from_db(RoleId);
%% 			EquipList ->
%% 				io:format("get_equip_list 2~n"),
%% 				EquipList
%% 		end;
%%     _ -> 
%% 		io:format("get_equip_list 4~n"),
%% 		get_equip_list_from_db(RoleId)
%%   end.

%%     case ets:lookup(?ETS_UNITE, RoleId) of
%%         [Player] ->
%%             case mod_disperse:rpc_call_by_id(Player#ets_unite.server_id, lib_goods_util, get_equip_list, [RoleId]) of
%%                 {badrpc, _} ->
%%                     get_equip_list_from_db(RoleId);
%%                 [] ->
%%                     get_equip_list_from_db(RoleId);
%%                 EquipList ->
%%                     EquipList
%%             end;
%%         _ ->
%%             get_equip_list_from_db(RoleId)
%%     end.

%% get_equip_list_from_db(RoleId) -> error | EquipList
get_equip_list_from_db(RoleId) ->
    Sql = io_lib:format(?SQL_GOODS_LIST_BY_LOCATION, [RoleId, ?GOODS_LOC_EQUIP]),
    try db:get_all(Sql) of
        EquipList when is_list(EquipList) ->
            lists:foldr(
                fun(GoodsInfo, AccList) ->
                        case lib_goods_util:make_info(goods, GoodsInfo) of
                            [] -> AccList;
                            [GoodsRecord] -> [GoodsRecord | AccList]
                        end
                end,
                [],
                EquipList
            );
        _ -> error
    catch
        _:_ ->
            error
    end.

%% 构造排行分类
make_rank_type(RankType, SubType) ->
	private_make_rank_type(RankType, SubType).


%%=============================================
%%	私有接口
%%=============================================
%% 初始化名人堂排行榜
private_init_rame_rank(_FromTimer) ->
	List = lib_fame:get_rank_data(),
    RankRecord = private_make_rank_info(?RK_FAME, List),
    ets:insert(?ETS_RANK, RankRecord).

%% 构造排行分类
private_make_rank_type(RankType, SubType) ->
	case SubType == 0 of
		true -> RankType;
		_ -> RankType * 10 + SubType
	end.

%% 获取排行榜数据
private_get_rank_data(RankType, SubType) ->
	NewRankType = private_make_rank_type(RankType, SubType),
	SpecialList = [?RK_FAME_COIN, ?RK_FAME_TAOBAO, ?RK_FAME_EXP, ?RK_FAME_PT],
	case lists:member(RankType, SpecialList) of
		%% 限时名人堂（活动）排行榜
		true ->
			%% 通用获取
			case ets:lookup(?ETS_FAME_LIMIT_RANK, NewRankType) of
				[] ->
					[];
				[RD] when is_record(RD, ets_fame_limit_rank) ->
					RD#ets_fame_limit_rank.rank_list;
				_ ->
					[]
			end;
		%% 普通排行榜
		_ ->
			%% 通用获取
			case ets:lookup(?ETS_RANK, NewRankType) of
				[] ->
					[];
				[RD] when is_record(RD, ets_rank) ->
					RD#ets_rank.rank_list;
				_ ->
					[]
			end
	end.

%% 构造排行榜数据在ets中的record
private_make_rank_info(TypeId, List) ->
    #ets_rank{type_id = TypeId, rank_list = List}.

%% 送花之后，更新魅力值
private_update_score(Id, Name, Career, Realm, Sex, Score) ->
	Sql = io_lib:format(?SQL_RK_DAILY_FLOWER_FETCH_ROW, [Id]),
	case db:get_row(Sql) of
		[] ->
			Insert = io_lib:format(?SQL_RK_DAILY_FLOWER_INSERT, [Id, Name, Sex, Career, Realm, Score, util:unixtime()]),
			db:execute(Insert);
		[_, Value] ->
			Update = io_lib:format(?SQL_RK_DAILY_FLOWER_UPDATE, [Value + Score, util:unixtime(), Id]),
			db:execute(Update)
	end.

%% 生成每个榜的数据
%% 返回：ok
private_make_data(RankType, FromTimer) ->
	if
		RankType =:= ?RK_FAME ->
			private_init_rame_rank(FromTimer);

		RankType =:= ?RK_PERSON_FIGHT ->
			private_refresh_person_fight(FromTimer);
		RankType =:= ?RK_PERSON_LV ->
			private_refresh_person_lv(FromTimer);
		RankType =:= ?RK_PERSON_WEALTH ->
			private_refresh_person_wealth(FromTimer);
		RankType =:= ?RK_PERSON_ACHIEVE ->
			private_refresh_person_achieve(FromTimer);
		RankType =:= ?RK_PERSON_REPUTATION ->
			private_refresh_person_reputation(FromTimer);
		RankType =:= ?RK_PERSON_VEIN ->
			private_refresh_person_vein(FromTimer);
		RankType =:= ?RK_PERSON_HUANHUA ->
			private_refresh_person_huanhua(FromTimer);
		RankType =:= ?RK_PERSON_CLOTHES ->
			private_refresh_person_clothes(FromTimer);
		
		RankType =:= ?RK_PET_FIGHT ->
			private_refresh_pet_fight(FromTimer);
		RankType =:= ?RK_PET_GROW ->
			private_refresh_pet_grow(FromTimer);
		RankType =:= ?RK_PET_LEVEL ->
			private_refresh_pet_level(FromTimer);

		RankType =:= ?RK_EQUIP_WEAPON ->
			private_refresh_equip_weapon(FromTimer);
		RankType =:= ?RK_EQUIP_DEFENG ->
			private_refresh_equip_defeng(FromTimer);
		RankType =:= ?RK_EQUIP_SHIPIN ->
			private_refresh_equip_shipin(FromTimer);
		
		RankType =:= ?RK_GUILD_LV ->
			private_refresh_group_lv(FromTimer);

		RankType =:= ?RK_ARENA_DAY ->
			private_refresh_arena_day(FromTimer);
		RankType =:= ?RK_ARENA_WEEK ->
			private_refresh_arena_week(FromTimer);
		RankType =:= ?RK_ARENA_KILL ->
			private_refresh_arena_kill(FromTimer);

		RankType =:= ?RK_COPY_COIN ->
			private_refresh_copy_coin(FromTimer);
		RankType =:= ?RK_COPY_NINE ->
			private_refresh_copy_nine(FromTimer);
		RankType =:= ?RK_COPY_TOWER ->
			private_refresh_copy_tower(FromTimer);

		RankType =:= ?RK_CHARM_DAY_HUHUA ->
			private_refresh_charm_day_huhua(FromTimer);
		RankType =:= ?RK_CHARM_DAY_FLOWER ->
			private_refresh_charm_day_flower(FromTimer);
		RankType =:= ?RK_CHARM_HUHUA ->
			private_refresh_charm_huhua(FromTimer);
		RankType =:= ?RK_CHARM_FLOWER ->
			private_refresh_charm_flower(FromTimer);
		RankType =:= ?RK_CHARM_HOTSPRING ->
			private_refresh_charm_hotspring(FromTimer);

		RankType =:= ?RK_MOUNT_FIGHT ->
			private_refresh_mount_fight(FromTimer);
		RankType =:= ?RK_FLYER_POWER ->
			private_refresh_flyer_power(FromTimer);

		true ->
			skip
	end,
	ok.

%% 保存快照
save_snapshot(_FromTimer, _RankType, _RankSubType) ->
	ok.
	%% 从定时器过来的才需要处理
%% 	case FromTimer =:= 1 andalso RankType == 1001 of
%% 		true ->
%% 			case pp_get_rank_subtype(RankType, RankSubType) of
%% 				[] ->
%% 					skip;
%% 				List ->
%% 					Len = length(List),
%% 					SubList = 
%% 					if
%% 						Len < 20 ->
%% 							lists:sublist(List, Len);
%% 						true ->
%% 							lists:sublist(List, 20)
%% 					end,
%% 					StringList = lists:map(fun(Row) ->
%% 						Row2 = util:implode(";", Row),
%% 						
%% 					end, SubList),
%% 					String = string:join(StringList, "=="),
%% 
%% 					RankId = private_make_rank_type(RankType, RankSubType),
%% 					db:execute(io_lib:format(?SQL_RK_SNAPSHOT_INSERT, [RankId, String, util:unixtime()]))
%% 			end;
%% 		_ ->
%% 			skip
%% 	end.

%% 刷新“个人排行-战斗力榜”
private_refresh_person_fight(FromTimer) ->
	%% 删除战斗力多于?NUM_LIMIT外的冗余记录
    Num = db:get_one(io_lib:format(?SQL_RK_PERSON_FIGHT_COUNT, [])),
    DeleteNum = Num - ?NUM_LIMIT,
    case DeleteNum > 0 of
        true ->
            db:execute(io_lib:format(?SQL_RK_PERSON_FIGHT_DELETE, [DeleteNum]));
        false ->
            skip
    end,

	%% 重新取值
	List = db:get_all(io_lib:format(?SQL_RK_PERSON_FIGHT, [?NUM_LIMIT])),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_PERSON_FIGHT, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_PERSON_FIGHT, List),

	%% 合服活动：战力榜争夺战，谁主沉浮
	case FromTimer of
		1 -> lib_activity_merge:do_rank_power(?RK_PERSON_FIGHT);
		_ -> skip
	end.

%% 刷新“个人排行-等级榜”
private_refresh_person_lv(_FromTimer) ->
    List = db:get_all(
		io_lib:format(?SQL_RK_PERSON_LV, [?NUM_LIMIT])
	),
    ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_PERSON_LV, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_PERSON_LV, List).

%% 刷新“个人排行-财富榜”
private_refresh_person_wealth(FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_PERSON_WEALTH, [?NUM_LIMIT])		 
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_PERSON_WEALTH, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_PERSON_WEALTH, List),

	%% 名人堂：合服财富榜第一
	case length(List) > 0 andalso FromTimer =:= 1 of
		true ->
			[[RoleId | _]] = lists:sublist(List, 1),
			mod_fame:trigger(
				lib_activity_merge:get_activity_time(),
				RoleId, 12601, 0, 1
			);
		_ ->
			skip
	end.

%% 刷新“个人排行-成就榜”
private_refresh_person_achieve(_FromTimer) ->
    List = db:get_all(
		io_lib:format(?SQL_RK_PERSON_ACHIEVE, [?NUM_LIMIT])
	),
    ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_PERSON_ACHIEVE, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_PERSON_ACHIEVE, List).

%% 刷新“个人排行-仙府声望榜”
private_refresh_person_reputation(FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_PERSON_REPUTATION, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_PERSON_REPUTATION, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_PERSON_REPUTATION, List),

	%% 名人堂：合服声望榜第一
	case length(List) > 0 andalso FromTimer =:= 1 of
		true ->
			[[RoleId | _]] = lists:sublist(List, 1),
			mod_fame:trigger(
				lib_activity_merge:get_activity_time(),
				RoleId, 12501, 0, 1
			);
		_ ->
			skip
	end.

%% 刷新“个人排行-经脉榜”
private_refresh_person_vein(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_PERSON_VEIN, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_PERSON_VEIN, List)
	).

%% 刷新“个人排行-宠物幻化榜”
private_refresh_person_huanhua(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_PERSON_HUANHUA, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_PERSON_HUANHUA, List)
	).

%% 刷新“个人排行-着装度”
private_refresh_person_clothes(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_PERSON_CLOTHES, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_PERSON_CLOTHES, List)
	).

%% 刷新“宠物排行-战斗力榜”
private_refresh_pet_fight(FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_PET_FIGHT, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_PET_FIGHT, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_PET_FIGHT, List),
	
	%% 合服活动：宠物战力大比拼
	case FromTimer of
		1 -> lib_activity_merge:do_rank_power(?RK_PET_FIGHT);
		_ -> skip
	end.

%% 刷新“宠物排行-成长榜”
private_refresh_pet_grow(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_PET_GROW, [?NUM_LIMIT])		 
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_PET_GROW, List)
	).

%% 刷新“宠物排行-等级榜”
private_refresh_pet_level(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_PET_LEVEL, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_PET_LEVEL, List)
	).

%% 刷新“坐骑排行-战斗力榜”
private_refresh_mount_fight(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_MOUNT_FIGHT, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_MOUNT_FIGHT, List)
	).

%% 刷新“飞行器战斗力榜”
private_refresh_flyer_power(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_FILYER_GET, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_FLYER_POWER, List)
	).

%% 刷新“装备排行-武器榜”
private_refresh_equip_weapon(FromTimer) ->
	%% 清理过期数据
	private_delete_equip_overdue([?RK_EQUIP_WEAPON]),

    List = db:get_all(io_lib:format(?SQL_RK_EQUIP, [1, ?NUM_LIMIT])),
    ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_EQUIP_WEAPON, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_EQUIP_WEAPON, List),

	%% 名人堂：合服武器榜第一
	case length(List) > 0 andalso FromTimer =:= 1 of
		true ->
			[[RoleId | _]] = lists:sublist(List, 1),
			mod_fame:trigger(
				lib_activity_merge:get_activity_time(),
				RoleId, 12401, 0, 1
			);
		_ ->
			skip
	end.

%% 刷新“装备排行-防具榜”
private_refresh_equip_defeng(_FromTimer) ->
	%% 删除过期数据
	private_delete_equip_overdue([?RK_EQUIP_DEFENG]),

	List = db:get_all(
		io_lib:format(?SQL_RK_EQUIP, [2, ?NUM_LIMIT])
	),
    ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_EQUIP_DEFENG, List)
	).

%% 刷新“装备排行-饰品榜”
private_refresh_equip_shipin(_FromTimer) ->
	%% 删除过期数据
	private_delete_equip_overdue([?RK_EQUIP_SHIPIN]),

    List = db:get_all(
		io_lib:format(?SQL_RK_EQUIP, [3, ?NUM_LIMIT])
	),
    ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_EQUIP_SHIPIN, List)
	).

%% 刷新“帮派排行-帮会榜”
private_refresh_group_lv(_FromTimer) ->
    List = db:get_all(
		io_lib:format(?SQL_RK_GUILD_LV, [?NUM_LIMIT])
	),
    ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_GUILD_LV, List)
	).

%% 刷新“竞技排行-每日上榜”
private_refresh_arena_day(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_ARENA_DAY, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_ARENA_DAY, List)
	).

%% 刷新“竞技排行-每周上榜”
private_refresh_arena_week(_FromTimer) ->
	{Monday, NextMonday} = private_get_arena_weekly_time(),
	List = db:get_all(
		io_lib:format(?SQL_RK_ARENA_WEEK, [Monday, NextMonday, ?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_ARENA_WEEK, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_ARENA_WEEK, List).

%% 刷新“竞技排行-每周击杀榜”
private_refresh_arena_kill(_FromTimer) ->
	{Monday, NextMonday} = private_get_arena_weekly_time(),
	List = db:get_all(
		io_lib:format(?SQL_RK_ARENA_WEEK_KILL, [Monday, NextMonday, ?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_ARENA_KILL, List)
	).

%% 刷新“副本排行-铜钱副本”
private_refresh_copy_coin(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_COPY_COIN, [?NUM_LIMIT])		 
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_COPY_COIN, List)
	).

%% 刷新“副本排行-九重天霸主”
private_refresh_copy_nine(FromTimer) ->
	%% 名人堂：合服后单人，多人九重天霸主
	case FromTimer =:= 1 of
		true ->
			MergeTime = lib_activity_merge:get_activity_time(),
			%% 单人
			case lib_tower_dungeon:get_master_player_id_list(1) of
				[] ->
					skip;
				List ->
					Row = lists:filter(fun([Level, _, _]) -> 
						Level == 30
					end, List),
					case Row of
						[[_, RoleIds, _]] ->
							[mod_fame:trigger(MergeTime, RoleId, 12201, 0, 1) || RoleId <- RoleIds];
						_ ->
							skip
					end
			end,

			%% 多人
			case lib_tower_dungeon:get_master_player_id_list(2) of
				[] ->
					skip;
				List2 ->
					Row2 = lists:filter(fun([Level2, _, _]) -> 
						Level2 == 30
					end, List2),
					case Row2 of
						[[_, RoleIds2, _]] ->
							mod_fame:trigger_copy(MergeTime, 12301, 0, RoleIds2);
						_ ->
							skip
					end
			end;
		_ ->
			skip
	end.

%% 刷新“副本排行-炼狱副本”
private_refresh_copy_tower(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_COPY_TOWER, [?NUM_LIMIT])		 
	),
	List2 = private_format_copy_tower(List),
	ets:insert(
		?ETS_RANK, private_make_rank_info(?RK_COPY_TOWER, List2)
	).

%% 构造副本排行-炼狱副本数据结构，如果增加多人了，再改动这里的代码
private_format_copy_tower(List) ->
	List.

%% 刷新“魅力排行-每日护花榜”
private_refresh_charm_day_huhua(FromTimer) ->
	%% 处理合服名人堂：合服鲜花榜第一 和 合服护花榜第一
	lib_fame:do_charm_rank(?RK_CHARM_DAY_HUHUA),

	case FromTimer of
		%% 如果是从定时器过来的才需要执行
		1 ->
			%% 发放鲜花魅力榜奖励
			lib_rank_activity:send_charm_rank_award(?RK_CHARM_DAY_HUHUA),

			%% 将护花榜前20名数据发到跨服 
			Platfrom = config:get_platform(), 
			ServerNum = config:get_server_id(), 
			lib_rank_activity:send_kf_flower_data(Platfrom, ServerNum),

			lib_qixi:send_max_ml_gift(),

			%% 删除护花数据
			clean_last_day_flower(?RK_CHARM_DAY_HUHUA);
		_ ->
			skip
	end,

	List = db:get_all(
		io_lib:format(?SQL_RK_DAILY_FLOWER_FETCH, [1, ?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_CHARM_DAY_HUHUA, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_CHARM_DAY_HUHUA, List).

%% 刷新“魅力排行-每日鲜花榜”
private_refresh_charm_day_flower(FromTimer) ->
	%% 处理合服名人堂：合服鲜花榜第一 和 合服护花榜第一
	lib_fame:do_charm_rank(?RK_CHARM_DAY_FLOWER),
	
	case FromTimer of
		1 ->
			%% 发放鲜花榜奖励
			lib_rank_activity:send_charm_rank_award(?RK_CHARM_DAY_FLOWER),

			%% 删除鲜花数据
			clean_last_day_flower(?RK_CHARM_DAY_FLOWER);
		_ -> skip
	end,

	List = db:get_all(
		io_lib:format(?SQL_RK_DAILY_FLOWER_FETCH, [2, ?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_CHARM_DAY_FLOWER, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_CHARM_DAY_FLOWER, List).

%% 刷新“魅力排行-护花榜”
private_refresh_charm_huhua(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_CHARM_HUHUA, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_CHARM_HUHUA, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_CHARM_HUHUA, List).

%% 刷新“魅力排行-鲜花榜”
private_refresh_charm_flower(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_CHARM_FLOWER, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_CHARM_FLOWER, List)
	),

	%% 刷新上榜玩家称号
	rebind_design(?RK_CHARM_FLOWER, List).

%% 刷新“魅力排行-沙滩魅力榜”
private_refresh_charm_hotspring(_FromTimer) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_CHARM_HOTSPRING, [?NUM_LIMIT])
	),
	ets:insert(
		?ETS_RANK,
		private_make_rank_info(?RK_CHARM_HOTSPRING, List)
	).

%% 获得排行榜第1名的玩家id
private_get_first_roleid(List) ->
	[RoleId | _T] = lists:nth(1, List),
	RoleId.

%% 获得排行榜第2至10名的玩家id
private_get_second_to_ten_roleid(List) ->
	Len = length(List),
	if
		Len < 2 -> [];
		Len < 10 ->
		    	NewList = lists:sublist(List, 2, Len),
			[Id || [Id | _T] <- NewList];
		true ->
			NewList = lists:sublist(List, 2, 9),
			[Id || [Id | _T] <- NewList]
	end.

%% 刷新排行榜第1名玩家称号
private_refresh_first_design(RankType, RoleId) ->
	case data_designation_config:get_design_id(RankType, 1) of
		0 ->
			skip;
		DesignId ->
			%% 查出之前谁获得这个称号
			case lib_designation:get_roleids_by_design(DesignId) of
				[] ->
					lib_designation:bind_design(RoleId, DesignId, "", 1);
				OldIds when is_list(OldIds) ->
					%% 删除其他玩家拥有的这个称号
					lists:map(fun(OldId) -> 
						case OldId =:= RoleId of
							true ->
								skip;
							_ ->
								%% 删除掉之前已经拥有该称号的玩家称号
								lib_designation:remove_design_in_server(OldId, DesignId)
						end
					end, OldIds),

					%% 为这个玩家绑定称号
					lib_designation:bind_design(RoleId, DesignId, "", 1);
				_ ->
					skip
			end
	end.

%% 刷新排行榜第2名至第10名玩家称号
private_refresh_second_to_ten_design(RankType, NewIds) ->
	case data_designation_config:get_design_id(RankType, 2) of
		0 ->
			skip;
		DesignId ->
			%% 查出之前谁获得这个称号
			case lib_designation:get_roleids_by_design(DesignId) of
				%% 之前没有人获得该称号
				[] ->
					lists:map(fun(Id) -> 
						lib_designation:bind_design(Id, DesignId, "", 1)
					end, NewIds);
				OldIds ->
					%% 旧榜玩家如果不在新榜玩家里面，则移除称号
					F = fun(MoveRoleId) ->
						lib_designation:remove_design_in_server(MoveRoleId, DesignId)
					end,
					[F(Id) || Id <- OldIds, lists:member(Id, NewIds) =:= false],

					%% 新榜玩家不在旧榜中，则添加称号
					lists:map(fun(NewId) -> 
						case lists:member(NewId, OldIds) of
							true ->
								skip;
							_ ->
								lib_designation:bind_design(NewId, DesignId, "", 1)
						end
					end, NewIds)
			end
	end.

%% 查询本周时间范围[MinSecs, MaxSecs)（从周一午夜至下周一午夜前为止）
%% @spec get_arena_weekly_time() -> {MinSecs, MaxSecs}
private_get_arena_weekly_time() ->
    {MegaSecs, Secs, MicroSecs} = mod_time:now(),
    {Date, Time} = calendar:now_to_local_time({MegaSecs, Secs, MicroSecs}),
    WeekDay = calendar:day_of_the_week(Date),
    [[_,_],[Config_End_Hour,Config_End_Minute]] = data_arena_new:get_arena_config(arena_time),
	EndTime = (Config_End_Hour*60 + Config_End_Minute)*60,
    TodaySecs = calendar:time_to_seconds(Time),
    Timestamp = MegaSecs * 1000000 + Secs,
    case WeekDay == 1 andalso EndTime > TodaySecs of
        true ->     %% 未到周一竞技开始，则以上周结果为准
            Monday = Timestamp - 86400 * 7 - TodaySecs;
        false ->
            Monday = Timestamp - 86400 * (WeekDay - 1) - TodaySecs
    end,
    NextMonday = Monday + 7 * 86400,
    {Monday, NextMonday}.

%% 删除装备冗余数据
private_delete_equip_overdue(TypeList) ->
	F = fun(EquipType) ->
	    Num = db:get_one(io_lib:format(?SQL_RK_COUNT_EQUIP, [EquipType])),
	    DeleteNum = Num - ?NUM_LIMIT,
	    case DeleteNum > 0 of
	        true ->
	            db:execute(io_lib:format(?SQL_RK_DELETE_EQUIP_ORVERDUE, [EquipType, DeleteNum]));
	        false ->
	            skip
	    end
	end,
	lists:foreach(F, TypeList).

%% 取得装备分数（服务端保存的是客户端两倍分数）
%% 评分规则：装备等级*成色系数*5 + 强化等级*强化等级*20 + (宝石1级别+宝石2级别+宝石3级别)*60
%%      + (装备等级*装备前缀系数)*2 + 装备洗炼总星级*装备等级/2
%% 为便于保存，这里使用双倍分数：装备等级*2倍成色系数*5 + 强化等级平方*40 + 宝石总级别 * 120
%% 成色系数：白色2，绿色2.5，蓝色3，紫色3.5，橙色4， 与数据库中Color对应关系：0.5*Color+2
private_get_equip_score(Equip, PlayerCareer) ->
	lib_goods_info:get_goods_power(Equip, PlayerCareer).
%%     Level = Equip#goods.level,
%%     Stren = Equip#goods.stren,
%%     Color = Equip#goods.color,
%%     Prefix = Equip#goods.prefix,
%%     GemGrade1 = private_get_gem_grade(Equip#goods.hole1_goods),
%%     GemGrade2 = private_get_gem_grade(Equip#goods.hole2_goods),
%%     GemGrade3 = private_get_gem_grade(Equip#goods.hole3_goods),
%%     Level * ((Color + 4) * 5 + (Prefix + 4) * 2)
%%     + Stren * Stren * 40
%%     + (GemGrade1 + GemGrade2 + GemGrade3) * 120
%%     + Level.

%% 计算宝石级别
%% private_get_gem_grade(0) ->
%%     0;
%% private_get_gem_grade(GemTypeId) ->
%%     case data_goods_type:get_name(GemTypeId) of
%%         <<>> ->
%%             0;
%%         GoodsName ->
%%             <<F:8, S:8, _/binary>> = GoodsName,
%%             case F >= 48 andalso F =< 57 of
%%                 true ->
%%                     case S >= 48 andalso S =< 57 of
%%                         true ->
%%                             list_to_integer([F, S]);    %% (F - 48 ) * 10 + S - 48
%%                         false ->
%%                             list_to_integer([F])        %% F - 48
%%                     end;
%%                 false ->
%%                     0
%%             end
%%     end.


%% 将装备信息插入装备排行榜列表，保持有序 -> {是否更新， 是否原来已在榜上， 新排行}
%% @spec add_to_equip_rank(EquipInfo, RankList) -> {IsChanged, IsTop, NewRankList}
%% equip_rank : [Object]
%%      Object : [GoodsId, Timestamp, GoodsTypeId, EquipType, RoleId, RoleName, Color, Career, Score]
%% EquipInfo : [PlayerId, GoodsTypeId, GoodsId, NickName, Score, Color, Career, EquipType]
%% add_to_equip_rank(EquipInfo, RankList) ->
%% 	[RoleId1, GoodsTypeId1, EquipId1, RoleName1, Score1, Color1, Career1, _] = EquipInfo,
%% 	case util:keyfind(EquipId1, 3, RankList) of
%% 		%% 没在排行榜中
%% 		false ->
%% 			NewEquipInfo = [RoleId1, GoodsTypeId1, EquipId1, RoleName1, Score1, Color1, Career1],
%% 			case RankList of
%% 			        [] ->
%% 			            {true, false, [NewEquipInfo]};
%% 			
%% 			        %% 需要重排
%% 						_ ->
%% 			            NewRankList = lists:sort(fun equip_sort_by_score/2, [NewEquipInfo | RankList]),
%% 			            {true, false, NewRankList}
%% 			end;
%% 	
%% 		Equip ->
%% 		[RoleId2, _, _, RoleName2, Score2, Color2, _] = Equip,
%% 	    case RoleId1 =/= RoleId2 orelse Score1 =/= Score2 orelse Color1 =/= Color2 orelse RoleName1 =/= RoleName2 of
%% 				%% 装备有变更
%% 	                true ->
%% 	                    List = lists:delete(Equip, RankList),
%% 	                    {true, true, lists:sort(fun equip_sort_by_score/2, [EquipInfo | List]) };
%% 	                false ->
%% 	                    {false, true, RankList}
%% 	            end
%% 	    end.

%% 角色属性榜
get_pos_on_role_rank(RoleId, RankList) ->
    get_pos_on_rank(RoleId, RankList, 1, 1).

%% 宠物榜
get_pos_on_pet_rank(RoleId, RankList) ->
    get_pos_on_rank(RoleId, RankList, 1, 3).

%% get_pos_on_rank(RoleId, RankList, 1) -> RoleOrder
%% RoleOrder =:= 0 表示超出需要加载装备的排名，或者不在排行榜上
%% N 表示角色Id所在榜数据列表的第几位
get_pos_on_rank(_, [], _, _) ->
    0;
get_pos_on_rank(RoleId, [RoleInfo | RankList], StartOrder, N) ->
    RankRoleId = lists:nth(N, RoleInfo),
    case RoleId =:= RankRoleId of
        true -> StartOrder;
        false ->
            case StartOrder >= ?SPEC_ROLE_NUM of
                true -> 0;
                false ->
                    get_pos_on_rank(RoleId, RankList, StartOrder + 1, N)
            end
    end.

%% 更新装备排行榜（装备分数以2倍分数(整数)保存，发给客户端时才转换）
%% @spec update_equip_rank(EquipInfoList) -> ok | skip
update_equip_rank(EquipInfoList) ->
	[Weapons, Armors, Ornaments] = unzip_equip_info(EquipInfoList),
	lists:map(fun update_equip_rank_1/1, Weapons),
	lists:map(fun update_equip_rank_1/1, Armors),
	lists:map(fun update_equip_rank_1/1, Ornaments).

update_equip_rank_1(EquipInfo) ->
	[GoodsId, GoodsTypeId, SubType, RoleId, RoleName, Color, Career, Score] = EquipInfo,
	EquipType = private_get_equip_db_type(SubType),
	RankId = private_equiptype_to_ranktype(EquipType),
	case private_get_rank_data(RankId, 0) of
		%% 排行榜尚未生成初始数据
		[] ->
			Sql = io_lib:format(?SQL_RK_EQUIP_INSERT, [GoodsId, util:unixtime(), GoodsTypeId, EquipType, SubType, RoleId, binary_to_list(RoleName), Color, Career, Score]),
			db:execute(Sql),
			%% 刷新一次排行榜
			if
				RankId =:= ?RK_EQUIP_WEAPON ->
					private_refresh_equip_weapon(0);
				RankId =:= ?RK_EQUIP_DEFENG ->
					private_refresh_equip_defeng(0);
				RankId =:= ?RK_EQUIP_SHIPIN ->
					private_refresh_equip_shipin(0);					
            			true ->
					skip		
			end;

		%% 排行榜已经有数据，需要进行排序
        	EquipRank ->
			NewEquipRank = get_new_equip_rank(
				[EquipType, RoleId, GoodsTypeId, GoodsId, RoleName, Score, Color, Career, SubType], 
				#ets_rank{type_id = RankId, rank_list = EquipRank}
			),
			ets:insert(?ETS_RANK, NewEquipRank),

			%% 刷新上榜玩家称号
			case RankId =:= ?RK_EQUIP_WEAPON of
				true ->
					rebind_design(?RK_EQUIP_WEAPON, NewEquipRank#ets_rank.rank_list);
				_ ->
					skip
			end
    end.

%% 按分数比较，分数相同则按Id比较
%% @spec equip_sort_by_score(EquipA, EquipB) -> true | false
equip_sort_by_score(EquipA, EquipB) ->
	[_, _, _, _, ScoreA, _, _] = EquipA,
	[_, _, _, _, ScoreB, _, _] = EquipB,
    if
        ScoreA > ScoreB -> true;
        ScoreA < ScoreB -> false;
		true ->	true
    end.

%% 有人进行装备评分，得到新排行
get_new_equip_rank(NewEquip, EquipRank) ->
	Timestamp = util:unixtime(),
	[EquipType | EquipInfo] = NewEquip,
	[RoleId, GoodsTypeId, GoodsId, RoleName, Score, Color, Career, SubType] = EquipInfo,
	OldRankList = EquipRank#ets_rank.rank_list,

	%% 查该装备id在不在榜上
	OldEquip = util:keyfind(GoodsId, 3, OldRankList),

	%% 判断该装备role_id + subtype是否有在榜上
	F = fun(Item, PList) ->
		[PRoleId, _, _, _, _, _, _, PSubType] = Item,
		case PRoleId =:= RoleId andalso PSubType =:= SubType of
			true ->
				Item;
			_ ->
				PList
		end
	end,
	OldEquip2 = lists:foldl(F, [], OldRankList),
	
	NewRankList = case OldEquip /= false of
		%% 该装备在榜上
	    	true ->
			db:execute(io_lib:format(?SQL_RK_EQUIP_UPDATE, [util:unixtime(), Score, GoodsId])),
	    		[EquipInfo | lists:delete(OldEquip, OldRankList)];
		_ ->
			case OldEquip2 == [] of
				%% 通过role_id + subtype榜上查不到
				true ->
				    	Sql = io_lib:format(?SQL_RK_EQUIP_INSERT, [GoodsId, Timestamp, GoodsTypeId, EquipType, SubType, RoleId, binary_to_list(RoleName), Color, Career, Score]),
					db:execute(Sql),
		    			[EquipInfo | OldRankList];
		    		_ ->
					OldGoodsId = lists:nth(3, OldEquip2),
					db:execute(io_lib:format(?SQL_RK_EQUIP_DELETE, [OldGoodsId])),
					db:execute(io_lib:format(?SQL_RK_EQUIP_INSERT, [GoodsId, Timestamp, GoodsTypeId, EquipType, SubType, RoleId, binary_to_list(RoleName), Color, Career, Score])),
					[EquipInfo | lists:delete(OldEquip2, OldRankList)]
			end
	end,
	
	SortFun = fun(Row1, Row2) ->
		[_, _, _, _, Score1, _, _, _] = Row1,
		[_, _, _, _, Score2, _, _, _] = Row2,
		Score1 > Score2
	end,
	NewRankList2 = lists:sort(SortFun, NewRankList),
	EquipRank#ets_rank{rank_list = lists:sublist(NewRankList2, ?NUM_LIMIT)}.

%% 装备信息分离成三个列表(武器、防具、饰品)
unzip_equip_info(EquipInfoList) ->
    unzip_equip_info(EquipInfoList, [[], [], []]).

unzip_equip_info([], ListOfList) ->
    ListOfList;
unzip_equip_info([Equip | EquipInfoList], [Weapons, Armors, Ornaments]) ->
	SubType = lists:nth(3, Equip),
	Re1 = lists:member(SubType, ?RK_EQUIP_WEAPON_SUBTYPE),
	Re2 = lists:member(SubType, ?RK_EQUIP_DEFEND_SUBTYPE),
	Re3 = lists:member(SubType, ?RK_EQUIP_SHIPIN_SUBTYPE),
	if
		Re1 =:= true ->
			unzip_equip_info(EquipInfoList, [[Equip | Weapons], Armors, Ornaments]);
		Re2 =:= true ->
			unzip_equip_info(EquipInfoList, [Weapons, [Equip | Armors], Ornaments]);
		Re3 =:= true ->
			 unzip_equip_info(EquipInfoList, [Weapons, Armors, [Equip | Ornaments]]);
		true ->
			unzip_equip_info(EquipInfoList, [Weapons, Armors, Ornaments])
	end.

%% 备份昨天鲜花榜数据，并清理数据
clean_last_day_flower(RankType) ->
	Sex = case RankType of
		?RK_CHARM_DAY_HUHUA -> 1;
		_ -> 2
	end,
	%% 删除备份数据
	db:execute(
		io_lib:format(?SQL_RK_DAILY_FLOWER_DELETE_ALL, [Sex])
	),
	
	%% 备份数据
	TmpSql = <<"REPLACE INTO rank_daily_flower_copy SELECT * FROM rank_daily_flower WHERE sex=~p">>,
	db:execute(
		io_lib:format(TmpSql, [Sex])
	),
    db:execute(
		io_lib:format(?SQL_RK_DELETE_ALL_DAILY_FLOWER, [Sex])
	).
