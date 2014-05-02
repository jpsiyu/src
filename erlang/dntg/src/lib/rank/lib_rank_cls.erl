%%%--------------------------------------
%%% @Module  : lib_rank_cls
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.11.15
%%% @Description :  跨服排行榜
%%%--------------------------------------

-module(lib_rank_cls).
-include("rank.hrl").
-include("rank_cls.hrl").
-include("sql_rank.hrl").
-include("kf_1v1.hrl").
-include("kf_3v3.hrl").
-include("activity_kf_power.hrl").
-export([
	cls_get_kf_rank/1,
	cls_update_kf_data/3,
	refresh_1v1_rank/0,
	refresh_kf_rank/0,
	update_1v1_rank_user/1,
	update_3v3_rank_user/1,
	broadcast_kf_1v1_rank/0,
	broadcast_kf_3v3_rank/0,
	reload_kf_1v1_week/0,
	remote_get_kf_1v1_rank/2,
	remote_get_kf_rank/2,
	working/0,
	init_kf_1v1_ets/0,
	apply_handle/3,
	update_kf_1v1_rank/1,
	update_kf_rank/1,
	set_remote_get_rank/2,
	remove_cls_rank/0,
	get_rank_meridian/1,
	game_get_1v1_rank/1,
	game_get_kf_rank/1,
	game_get_pet_info/1,
	get_get_mount_info/1,
	game_get_equip_info/1,
	game_kf_rank_switch/0,
	game_clear_kf_rank/0,
	powerrank_send_power_to_kf/2,
	powerrank_get_power_list/4,
	powerrank_send_image_to_kf/5
]).

%%==================== 跨服节点调用方法  ====================%%
%% 刷新跨服1v1排行榜数据
refresh_1v1_rank() ->
	private_init_rank().

%% 挑战结束后，回写玩家数据到1v1排行榜中
update_1v1_rank_user([]) -> ok;
update_1v1_rank_user([Rd | Tail]) -> 
	private_update_rank_user(Rd),
	update_1v1_rank_user(Tail).

%% 挑战结束后，回写玩家数据到3v3排行榜中
update_3v3_rank_user([]) -> ok;
update_3v3_rank_user([Rd | Tail]) -> 
	private_update_rank_3v3_user(Rd),
	update_3v3_rank_user(Tail).

%% 1v1活动结束后，中心节点将排行榜数据发给游戏节点
broadcast_kf_1v1_rank() ->
	List = reload_kf_1v1_week(),
	Data = [{?RK_CLS_WEEK, List}],
	mod_clusters_center:apply_to_all_node(
		lib_rank_cls,
		apply_handle,
		[mod_rank, reset_kf_1v1_rank, Data],
		200
	).

%% 3v3活动结束后，中心节点将mvp排行榜数据发给游戏节点
broadcast_kf_3v3_rank() ->
	List = reload_kf_3v3_mvp(),
	Data = [{?RK_CLS_MVP, List}],
	mod_clusters_center:apply_to_all_node(
		lib_rank_cls,
		apply_handle,
		[mod_rank, reset_kf_1v1_rank, Data],
		200
	).

%% 加载1v1周榜
reload_kf_1v1_week() ->
	List = db:get_all(io_lib:format(?RK_CLS_GET_WEEK, [?RK_CLS_LIMIT])),
	ets:insert(
		?RK_KF_ETS_1V1_RANK,
		private_make_1v1_rank(?RK_CLS_WEEK, List)
	),
	List.

%% 加载3v3 mvp榜
reload_kf_3v3_mvp() ->
	List = db:get_all(io_lib:format(?RK_CLS_KF3V3_MVP, [?RK_CLS_LIMIT])),
	ets:insert(
		?RK_KF_ETS_1V1_RANK,
		private_make_1v1_rank(?RK_CLS_MVP, List)
	),
	List.

%% 游戏节点过来跨服节点获取1v1排行数据
remote_get_kf_1v1_rank(Node, RankType) ->
	Data = [{RankType, private_get_kf_1v1_rank(RankType)}],
	mod_clusters_center:apply_cast(
		Node,
		lib_rank_cls,
		apply_handle,
		[mod_rank, reset_kf_1v1_rank, Data]
	).

%% 游戏节点过来跨服节点获取排行数据
remote_get_kf_rank(Node, RankType) ->
	Data = [{RankType, private_get_kf_rank(RankType)}],
	mod_clusters_center:apply_cast(
		Node,
		lib_rank_cls,
		apply_handle,
		[mod_rank, reset_kf_rank, Data]
	).

%% 定时器凌晨调用
working() ->
	NowTime = util:unixtime(),
	Ids = private_get_id_list(),
	RankType = private_get_one([?RK_CLS_WEEK], Ids, 0),
	case RankType of
		0 ->
			WaitingTime = util:unixdate(NowTime) + 86400 + 120 - NowTime,
			{waiting, WaitingTime};
		_ ->
			%% 处理跨服竞技排行奖励
			private_timer_pk_award(NowTime),

			%% 处理跨服排行榜
			refresh_kf_rank(),

			%% 刷新斗战封神活动排行
			refresh_kf_power_rank(),

			{waiting, 120}
	end.

%% 服务启动时初始化跨服1v1排行榜数据
init_kf_1v1_ets() ->
	ets:insert(?RK_KF_1V1_CACHE_RANK, [
		#ets_kf_1v1_cache_rank{type_id = ?RK_CLS_WEEK, rank_list = undefined}
	]),
	ok.

%% 刷新跨服排行榜数据
refresh_kf_rank() ->
	spawn(fun() -> 
		%% 刷新玩家榜
		List = [
			?RK_KF_PLAYER_POWER, ?RK_KF_PLAYER_LEVEL, ?RK_KF_PLAYER_WEALTH, ?RK_KF_PLAYER_ACHIEVE,
			?RK_KF_PLAYER_MERIDIAN, ?RK_KF_PLAYER_GJPT, ?RK_KF_PLAYER_WEAR, ?RK_KF_PLAYER_HUANHUA
		],
		lists:foreach(fun(RankType) -> 
			private_refresh_kf_player(RankType),
			timer:sleep(100)
		end, List),

		%% 刷新宠物榜
		List2 = [?RK_KF_PET_POWER, ?RK_KF_PET_GROW, ?RK_KF_PET_LEVEL, ?RK_KF_MOUNT_POWER],
		lists:foreach(fun(RankType) -> 
			private_refresh_kf_pet(RankType),
			timer:sleep(100)
		end, List2),
	
		%% 刷新装备榜
		List3 = [?RK_KF_EQUIP_WEAPON, ?RK_KF_EQUIP_DEFENG, ?RK_KF_EQUIP_SHIPIN],
		lists:foreach(fun(RankType) -> 
			private_refresh_kf_equip(RankType),
			timer:sleep(100)
		end, List3),
	
		timer:sleep(5 * 1000),

		%% 通知游戏节点清除排行缓存，由玩家触发重新获取
		catch private_remove_game_kf_cache()	  
	end),

	ok.

%% 刷新斗战封神活动排行
refresh_kf_power_rank() ->
	spawn(fun() -> 
		lib_activity_kf_power:reload_rank()
	end),
	ok.

%% 获取跨服榜单数据
cls_get_kf_rank(RankType) ->
	case ets:lookup(?RK_KF_ETS_RANK, RankType) of
		[Rd] when is_record(Rd, kf_ets_rank) ->
			case Rd#kf_ets_rank.rank_list of
				undefined ->
					[];
				_ ->
					Rd#kf_ets_rank.rank_list
			end;
		_ ->
			[]
	end.

%% 玩家登录跨服后，更新玩家排行榜数据
cls_update_kf_data(player, PlayerInfo, [Power, Level, Coin, Achieve, Gjpt, Wear, Meridian]) ->
	private_update_player_rank(?RK_KF_PLAYER_POWER, PlayerInfo, Power),
	private_update_player_rank(?RK_KF_PLAYER_LEVEL, PlayerInfo, Level),
	private_update_player_rank(?RK_KF_PLAYER_WEALTH, PlayerInfo, Coin),
	private_update_player_rank(?RK_KF_PLAYER_ACHIEVE, PlayerInfo, Achieve),
	private_update_player_rank(?RK_KF_PLAYER_GJPT, PlayerInfo, Gjpt),
	private_update_player_rank(?RK_KF_PLAYER_WEAR, PlayerInfo, Wear),
	private_update_player_rank(?RK_KF_PLAYER_MERIDIAN, PlayerInfo, Meridian),
	ok;

%% 玩家登录跨服后，更新其他排行榜数据
cls_update_kf_data(other, PlayerInfo, [PetInfo, EquipInfo]) ->
	private_update_pet(PlayerInfo, PetInfo),
	private_update_equip(PlayerInfo, EquipInfo),
	ok.
	

%%==================== 游戏节点调用方法  ====================%%
%% 跨服排行榜开关
game_kf_rank_switch() ->
	true.

%% 游戏0号节点调用公共线执行业务逻辑通用方法
apply_handle(Module, Function, Args) ->
	mod_disperse:cast_to_unite(Module, Function, [Args]).

%% 重置跨服排行榜数据
update_kf_1v1_rank([]) -> ok;
update_kf_1v1_rank([{RankType, List} | Tail]) ->
	ets:insert(?RK_KF_1V1_CACHE_RANK, #ets_kf_1v1_cache_rank{
		type_id = RankType,
		rank_list = List,
		update = util:unixtime()
	}),
	update_kf_1v1_rank(Tail).

%% 重置跨服排行榜数据
update_kf_rank([]) -> ok;
update_kf_rank([{RankType, List} | Tail]) ->
	ets:insert(?RK_KF_CACHE_RANK, #ets_kf_cache_rank{
		type_id = RankType,
		rank_list = List,
		update = util:unixtime()
	}),
	update_kf_rank(Tail).

%% 游戏节点过来跨服节点获取排行数据
set_remote_get_rank(RankType, List) -> 
	mod_disperse:cast_to_unite(mod_rank, reset_kf_1v1_rank, [{RankType, List}]).

%% 清跨服排行榜缓存
remove_cls_rank() ->
	ets:insert(?RK_KF_1V1_CACHE_RANK, #ets_kf_1v1_cache_rank{
		type_id = ?RK_CLS_WEEK,
		rank_list = undefined
	}).

%% 获取榜单数据
game_get_1v1_rank(RankType) ->
	case ets:lookup(?RK_KF_1V1_CACHE_RANK, RankType) of
		[Rd] when is_record(Rd, ets_kf_1v1_cache_rank) ->
			case Rd#ets_kf_1v1_cache_rank.rank_list of
				undefined ->
					private_get_remote_kf_1v1_rank(RankType),
					[];
				_ ->
					Rd#ets_kf_1v1_cache_rank.rank_list
			end;
		_ ->
			[]
	end.

%% 获取跨服榜单数据
game_get_kf_rank(RankType) ->
	case ets:lookup(?RK_KF_CACHE_RANK, RankType) of
		[Rd] when is_record(Rd, ets_kf_cache_rank) ->
			case Rd#ets_kf_cache_rank.rank_list of
				undefined ->
					private_get_remote_kf_rank(RankType),
					[];
				_ ->
					Rd#ets_kf_cache_rank.rank_list
			end;
		_ ->
			private_get_remote_kf_rank(RankType),
			[]
	end.

%% 获取玩家在元神排行中的值
get_rank_meridian(RoleId) ->
	List = lib_rank:pp_get_rank(?RK_PERSON_VEIN),
	Result = lists:filter(fun(Row) -> 
		[Id, _, _, _, _, _, _, _] = Row,
		RoleId =:= Id 
	end, List),
	case Result of
		[[_, _, _, _, _, _, Meridian, _]] ->
			Meridian;
		_ ->
			0
	end.

%% 获取玩家在宠物榜中的值
game_get_pet_info(RoleId) ->
	List1 = lib_rank:pp_get_rank(?RK_PET_FIGHT),
	Result1 = lists:filter(fun(Row) -> 
		[Id, _, _, _, _, _] = Row,
		RoleId =:= Id 
	end, List1),
	[PowerInfoName, PowerInfoId, PowerInfoValue] = 
	case Result1 of
		[[_, PowerName, PowerId, _, _, PowerValue] | _] ->
			[PowerName, PowerId, PowerValue];
		_ ->
			[false, 0, 0]
	end,

	List2 = lib_rank:pp_get_rank(?RK_PET_GROW),
	Result2 = lists:filter(fun(Row) -> 
		[Id, _, _, _, _, _] = Row,
		RoleId =:= Id 
	end, List2),
	[GrouthInfoName, GrouthInfoId, GrouthInfoValue] = 
	case Result2 of
		[[_, GrouthName, GrouthId, _, _, GrouthValue] | _] ->
			[GrouthName, GrouthId, GrouthValue];
		_ ->
			[false, 0, 0]
	end,

	List3 = lib_rank:pp_get_rank(?RK_PET_LEVEL),
	Result3 = lists:filter(fun(Row) -> 
		[Id, _, _, _, _, _] = Row,
		RoleId =:= Id 
	end, List3),
	[LevelInfoName, LevelInfoId, LevelInfoValue] = 
	case Result3 of
		[[_, LevelName, LevelId, _, _, LevelValue] | _] ->
			[LevelName, LevelId, LevelValue];
		_ ->
			[false, 0, 0]
	end,
	MountInfo = get_get_mount_info(RoleId),
	[
		{power, PowerInfoName, PowerInfoId, PowerInfoValue},
		{grouth, GrouthInfoName, GrouthInfoId, GrouthInfoValue},
		{level, LevelInfoName, LevelInfoId, LevelInfoValue},
		MountInfo
	].

%% 获取玩家在坐骑榜中的值
get_get_mount_info(RoleId) ->
	List1 = lib_rank:pp_get_rank(?RK_MOUNT_FIGHT),
	Result1 = lists:filter(fun(Row) ->
		[Id, _, _, _, _, _, _] = Row,
		RoleId =:= Id 
	end, List1),
	[PowerInfoId, PowerInfoTypeId, PowerInfoValue] = 
	case Result1 of
		[[_, _, _, _, MoundId, MountTypeId, MountPower]] ->
			[MountTypeId, MoundId, MountPower];
		_ ->
			[0, 0, 0]
	end,
	{mount, PowerInfoId, PowerInfoTypeId, PowerInfoValue}.

%% 获取玩家在装备榜中的值
game_get_equip_info(RoleId) ->
	List1 = lib_rank:pp_get_rank(?RK_EQUIP_WEAPON),
	Result1 = lists:filter(fun(Row) -> 
		[Id, _, _, _, _, _, _, _] = Row,
		RoleId =:= Id 
	end, List1),

	List2 = lib_rank:pp_get_rank(?RK_EQUIP_DEFENG),
	Result2 = lists:filter(fun(Row) -> 
		[Id, _, _, _, _, _, _, _] = Row,
		RoleId =:= Id 
	end, List2),

	List3 = lib_rank:pp_get_rank(?RK_EQUIP_SHIPIN),
	Result3 = lists:filter(fun(Row) -> 
		[Id, _, _, _, _, _, _, _] = Row,
		RoleId =:= Id 
	end, List3),

	[
		{weapon, Result1},
		{defeng, Result2},
		{shipin, Result3}
	].

%% 清数据清掉重新获取
game_clear_kf_rank() ->
	ets:delete_all_objects(?RK_KF_CACHE_RANK).

%% [斗战封神活动] 将战力发到跨服结点进行上榜
powerrank_send_power_to_kf(Node, RankElement) ->
	[Platform, ServerId, Id, NickName, Realm, Career, Sex, Lv, Power] = RankElement,
	NewPlatform = util:make_sure_list(Platform),
	case ets:lookup(?RK_ETS_POWER_ACTIVITY, NewPlatform) of
		%% 该平台第一个上榜
		[] ->
			%% 插入ets
			Record = #kfrank_power_activity{
				platform = NewPlatform,
				rank_list = [RankElement]
			},
			ets:insert(?RK_ETS_POWER_ACTIVITY, Record),
			%% 能进前10，再cast回游戏线，再请求发玩家的形象过来
			mod_clusters_center:apply_cast(Node, lib_activity_kf_power, get_image, [Node, Platform, ServerId, Id, Power]),

			%% 排行数据入库
			db:execute(io_lib:format(?KF_POWER_RANK_INSERT, [NewPlatform, ServerId, Id, NickName, Realm, Career, Sex, Lv, Power]));
		%% 如果有数据，则要对比处理
		[Record] ->
			List = Record#kfrank_power_activity.rank_list,
			Length = length(List),
			LastElement = lists:last(Record#kfrank_power_activity.rank_list),
			LastPower = lists:last(LastElement),
			RankNum = data_activity:get_kf_power_config(rank_num),

			case Length >= RankNum andalso LastPower >= Power of
				%% 如果榜已满，且战力比最后一名还低，则不处理
				true ->
					skip;
				_ ->
					[NewList, NewExist, NewOldPower] = lists:foldl(fun(Row, [All, Exist, TargetOldPower]) -> 
						[_OldPlatform, OldServerId, OldId, _OldNickName, _OldRealm, _OldCareer, _OldSex, _OldLv, OldPower] = Row,
						if
							OldServerId =:= ServerId andalso OldId =:= Id ->
								[[RankElement | All], 1, OldPower];
							true ->
								[[Row | All], Exist, TargetOldPower]
						end
					end, [[], 0, 0], List),

					%% 如果已经存在，且战力一样，则不处理
					case NewOldPower =:= Power of
						true ->
							skip;
						_ ->
							[NewList2, Length2] = if
								NewExist =:= 0 -> [[RankElement | NewList], Length + 1];
								true -> [NewList, Length]
							end,

							NewList3 = lists:sort(fun([_, _, _, _, _, _, _, _, Power1], [_, _, _, _, _, _, _, _, Power2]) -> 
								Power1 >= Power2
							end, NewList2),

						NewList4 = if
							Length2 > RankNum -> lists:sublist(NewList3, RankNum);
							true -> NewList3
						end,

						ets:insert(?RK_ETS_POWER_ACTIVITY, Record#kfrank_power_activity{rank_list = NewList4}),

						%% 如果玩家排前10名，再cast回游戏线，再请求发玩家的形象过来
						[_, MyPos] = lists:foldl(fun([_, Nserverid, NId, _, _, _, _, _, _], [TmpPos, TmpMyPos]) -> 
							case Nserverid =:= ServerId andalso NId =:= Id of
								true -> [TmpPos + 1, TmpPos];
									_ -> [TmpPos + 1, TmpMyPos]
								end
							end, [1, 1], NewList4),
							case MyPos =< 10 of
								true -> mod_clusters_center:apply_cast(Node, lib_activity_kf_power, get_image, [Node, Platform, ServerId, Id, Power]);
								_ -> skip
							end,

							%% 排行数据入库
							db:execute(io_lib:format(?KF_POWER_RANK_INSERT, [Platform, ServerId, Id, NickName, Realm, Career, Sex, Lv, Power]))
					end
			end
	end.

%% [斗战封神活动] 保存玩家形象
powerrank_send_image_to_kf(_Node, Platform, ServerId, Id, Image) ->
	case ets:lookup(?RK_ETS_POWER_ACTIVITY, Platform) of
		[] ->
			skip;
		[Rd] ->
			%% 更新ets
			Element = {[Platform, ServerId, Id], Image},
			NewTop = lists:keydelete([Platform, ServerId, Id], 1, Rd#kfrank_power_activity.top_10),
			NewTop2 = lists:append(NewTop, [Element]),
			ets:insert(?RK_ETS_POWER_ACTIVITY, Rd#kfrank_power_activity{top_10 = NewTop2}),
			%% 形象数据入库，以便服务重启时重新载入
			db:execute(io_lib:format(?KF_POWER_IMAGE_INSERT, [Platform, ServerId, Id, util:term_to_bitstring(Image)]))
	end.

%% [斗战封神活动] 请求从游戏线发过来跨服中心，请求同步跨服战力排行数据到游戏线
powerrank_get_power_list(Node, Platform, ServerNum, Id) ->
	NewPlatform = util:make_sure_list(Platform),
	List = case ets:lookup(?RK_ETS_POWER_ACTIVITY, NewPlatform) of
		[] -> [];
		[Rd] -> [Rd#kfrank_power_activity.rank_list, Rd#kfrank_power_activity.top_10]
	end,
	mod_clusters_center:apply_cast(Node, lib_activity_kf_power, kfrank_reset_power_list, [Platform, ServerNum, Id, List]).



%%==================== 内部方法  ====================%%
%% 服务启动时加载好所有榜数据
private_init_rank() ->
	reload_kf_1v1_week(),
	reload_kf_3v3_mvp().

%% 远程更新跨服1v1榜单数据
private_get_remote_kf_1v1_rank(RankType) ->
	mod_clusters_node:apply_cast(lib_rank_cls, remote_get_kf_1v1_rank, [mod_disperse:get_clusters_node(), RankType]).

%% 远程更新跨服榜单数据
private_get_remote_kf_rank(RankType) ->
	mod_clusters_node:apply_cast(lib_rank_cls, remote_get_kf_rank, [mod_disperse:get_clusters_node(), RankType]).


%% 更新每日榜单
%% 活动结束时，将调用到该方法刷新数据
private_update_rank_user(Rd) ->
	NowTime = util:unixtime(),
	case is_record(Rd, bd_1v1_player) of
		true ->
			Sql = io_lib:format(?RK_CLS_GET_ROW, [Rd#bd_1v1_player.platform, Rd#bd_1v1_player.server_num, Rd#bd_1v1_player.id]),
			case db:get_row(Sql) of
				[] ->
					db:execute(
						io_lib:format(?RK_CLS_INSERT, [
							Rd#bd_1v1_player.platform,
							Rd#bd_1v1_player.server_num,
							Rd#bd_1v1_player.id,
							Rd#bd_1v1_player.node,
							Rd#bd_1v1_player.name,
							Rd#bd_1v1_player.country,
							Rd#bd_1v1_player.sex,
							Rd#bd_1v1_player.carrer,
							Rd#bd_1v1_player.image,
							Rd#bd_1v1_player.lv,
							Rd#bd_1v1_player.loop,
							Rd#bd_1v1_player.win_loop,
							Rd#bd_1v1_player.hp,
							Rd#bd_1v1_player.pt,
							Rd#bd_1v1_player.score,
							Rd#bd_1v1_player.loop,
							Rd#bd_1v1_player.win_loop,
							Rd#bd_1v1_player.hp,
							Rd#bd_1v1_player.score,
							Rd#bd_1v1_player.loop,
							Rd#bd_1v1_player.win_loop,
							Rd#bd_1v1_player.hp,
							Rd#bd_1v1_player.score,
							NowTime
						])
					);
				[Pt] ->
					db:execute(
						io_lib:format(?RK_CLS_UPDATE, [
							Rd#bd_1v1_player.name,
							Rd#bd_1v1_player.country,
							Rd#bd_1v1_player.sex,
							Rd#bd_1v1_player.carrer,
							Rd#bd_1v1_player.image,
							Rd#bd_1v1_player.lv,
							Rd#bd_1v1_player.loop,
							Rd#bd_1v1_player.win_loop,
							Rd#bd_1v1_player.hp,
							Rd#bd_1v1_player.pt,
							Rd#bd_1v1_player.score,
							Rd#bd_1v1_player.loop,
							Rd#bd_1v1_player.win_loop,
							Rd#bd_1v1_player.hp,
							Rd#bd_1v1_player.score,
							Rd#bd_1v1_player.loop,
							Rd#bd_1v1_player.win_loop,
							Rd#bd_1v1_player.hp,
							Rd#bd_1v1_player.score,
							NowTime,
							Rd#bd_1v1_player.platform,
							Rd#bd_1v1_player.server_num,
							Rd#bd_1v1_player.id
						])
					),
					private_bind_design(Rd, Pt + Rd#bd_1v1_player.pt)
			end;
		_ ->
			skip
	end.

%% 更新3v3周榜数据
%% 活动结束时，将调用到该方法刷新数据
private_update_rank_3v3_user(Rd) ->
	NowTime = util:unixtime(),
	case is_record(Rd, bd_3v3_player) of
		true ->
			Sql = io_lib:format(?RK_CLS_KF3V3_GET_ROW, [Rd#bd_3v3_player.platform, Rd#bd_3v3_player.server_num, Rd#bd_3v3_player.id]),
			case db:get_row(Sql) of
				[] ->
					Pt = case Rd#bd_3v3_player.pt < 0 of
						true -> 0;
						_ -> Rd#bd_3v3_player.pt
					end,
					db:execute(
						io_lib:format(?RK_CLS_KF3V3_INSERT, [
							Rd#bd_3v3_player.platform,
							Rd#bd_3v3_player.server_num,
							Rd#bd_3v3_player.id,
							Rd#bd_3v3_player.node,
							Rd#bd_3v3_player.name,
							Rd#bd_3v3_player.country,
							Rd#bd_3v3_player.sex,
							Rd#bd_3v3_player.career,
							Rd#bd_3v3_player.image,
							Rd#bd_3v3_player.lv,
							Pt,
							Rd#bd_3v3_player.score,
							Rd#bd_3v3_player.mvp_num,
							Rd#bd_3v3_player.pk_win_num,
							Rd#bd_3v3_player.pk_lose_num,
							NowTime
						])
					);
				[Pt] ->
					AddPt = Pt + Rd#bd_3v3_player.pt,
					AddPt2 = case AddPt < 0 of
						true -> 0;
						_ -> AddPt
					end,

					db:execute(
						io_lib:format(?RK_CLS_KF3V3_UPDATE, [
							Rd#bd_3v3_player.name,
							Rd#bd_3v3_player.country,
							Rd#bd_3v3_player.sex,
							Rd#bd_3v3_player.career,
							Rd#bd_3v3_player.image,
							Rd#bd_3v3_player.lv,
							AddPt2,
							Rd#bd_3v3_player.score,
							Rd#bd_3v3_player.mvp_num,
							Rd#bd_3v3_player.pk_win_num,
							Rd#bd_3v3_player.pk_lose_num,
							NowTime,
							Rd#bd_3v3_player.platform,
							Rd#bd_3v3_player.server_num,
							Rd#bd_3v3_player.id
						])
					)
			end;
		_ ->
			skip
	end.

%% 处理跨服竞技排行奖励
private_timer_pk_award(NowTime) ->
	db:execute(io_lib:format(?SQL_RK_TIMER_INSERT, [?RK_CLS_WEEK, NowTime])),
	private_init_rank(),
	case util:get_day_of_week() of
		7 ->
			spawn(fun() ->
				%% 发送跨服1v1奖励
				private_send_kf_1v1_award()
			end),

			spawn(fun() ->
				%% 发送跨服3v3奖励
				private_send_kf_3v3_award()
			end);
		_ ->
			skip
	end.

private_remove_game_kf_cache() ->
	mod_clusters_center:apply_to_all_node(
		lib_rank_cls,
		apply_handle,
		[mod_rank, remove_kf_rank_cache, []]
	).

%% 取出刷新过的排行榜id列表
private_get_id_list() ->
	case db:get_all(io_lib:format(?SQL_RK_TIMER_GET, [])) of
		[] ->
			[];
		List ->
			DayTime = util:unixdate(),
			[Id || [Id, LastTime] <- List, LastTime >= DayTime]
	end.

%% 取出一个还没刷新的排行榜id
private_get_one([], _Ids, TargetId) -> TargetId;
private_get_one([Id | Tail], Ids, TargetId) ->
	case lists:member(Id, Ids) of
		true -> private_get_one(Tail, Ids, TargetId);
		false -> private_get_one([], Ids, Id)
	end.

%% 清空所有榜数据
private_clean_all(RankType) ->
	case RankType of
		?RK_CLS_WEEK ->
			db:execute(io_lib:format(?RK_CLS_KF1V1_TRUNCATE, []));
		?RK_CLS_MVP ->
			db:execute(io_lib:format(?RK_CLS_KF3V3_TRUNCATE, []));
		_ ->
			skip
	end.

%% 发回游戏节点公共线发送奖励
private_rpc_send_gift_mail(Node, RoleList, Title, Content, GiftId) ->
	GoodsTypeId = lib_gift_new:get_goodsid_by_giftid(GiftId),
	case GoodsTypeId > 0 of
		true ->
			catch mod_clusters_center:apply_cast(
				Node,
				lib_mail,
				send_sys_mail_bg_4_1v1,
				[RoleList, Title, Content, GoodsTypeId, 2, 0, 0, 1, 0, 0, 0, 0]
			);
		_ ->
			skip
	end.

%% 发送跨服1v1周榜奖励
private_send_kf_1v1_award() ->
	case private_get_kf_1v1_rank(?RK_CLS_WEEK) of
		[] ->
			skip;
		List ->
			%% 前100名发奖励
			Title = data_activity_text:get_1v1_week_award_title(),
			Content = data_activity_text:get_1v1_week_award_content(),

            lists:foldl(fun([_, _, Id, Node | _], Position) ->
                case Position < 101 of
					true ->
						private_rpc_send_gift_mail(
							list_to_atom(binary_to_list(Node)),
							[Id],
							io_lib:format(Title, [Position]),
							io_lib:format(Content, [Position]),
							private_get_1v1_week_award_gift(Position)
						);
					_ ->
						skip
				end,
				Position + 1
        	end, 1, List),

			spawn(fun() -> 
				%% 为达标玩家发奖励
				private_send_kf_1v1_append_award(10000, 100, 100)
			end)
	end.

%% 发送跨服1v1达标奖励
private_send_kf_1v1_append_award(NeedScore, Start, Limit) -> 
	List = db:get_all(io_lib:format(?RK_CLS_KF1V1_DABIAO, [Start, Limit])),
	NewList = [[FNode, FId] || [FNode, FId, FScore] <- List, FScore >= NeedScore],
	Len = length(NewList),
	case Len =< 0 of
		true ->
			%% 清除表rank_kf_1v1数据
			private_clean_all(?RK_CLS_WEEK);
		_ ->
			spawn(fun() -> 
				lists:foreach(fun([Node, Id]) -> 
					private_rpc_send_gift_mail(
						list_to_atom(binary_to_list(Node)),
						[Id],
						data_activity_text:get_1v1_week_award_append_title(),
						data_activity_text:get_1v1_week_award_append_content(),
						535556
					)
				end, NewList)
			end),
			timer:sleep(1000),
			private_send_kf_1v1_append_award(NeedScore, Start + Limit, Limit)
	end.

%% 发送跨服3v3达标奖励
private_send_kf_3v3_append_award(NeedScore, Start, Limit) -> 
	List = db:get_all(io_lib:format(?RK_CLS_KF3V3_DABIAO, [Start, Limit])),
	NewList = [[FNode, FId] || [FNode, FId, FScore] <- List, FScore >= NeedScore],
	Len = length(NewList),
	case Len =< 0 of
		true ->
			%% 清除表rank_kf_3v3数据
			private_clean_all(?RK_CLS_MVP);
		_ ->
			spawn(fun() -> 
				lists:foreach(fun([Node, Id]) -> 
					private_rpc_send_gift_mail(
						list_to_atom(binary_to_list(Node)),
						[Id],
						data_activity_text:get_3v3_week_award_append_title(),
						data_activity_text:get_3v3_week_award_append_content(),
						535556
					)
				end, NewList)
			end),
			timer:sleep(1000),
			private_send_kf_3v3_append_award(NeedScore, Start + Limit, Limit)
	end.

private_get_1v1_week_award_gift(Position) ->
	if
		Position >= 51 andalso Position < 101 -> 535555;
		Position >= 21 andalso Position < 51 -> 535554;
		Position >= 11 andalso Position < 21 -> 535553;
		Position >= 5 andalso Position < 11 -> 535552;
		Position >= 2 andalso Position < 5 -> 535551;
		Position =:= 1 -> 535550;
		true -> 0
	end.

%% 发送跨服3v3 mvp排行奖励
private_send_kf_3v3_award() ->
	case private_get_kf_1v1_rank(?RK_CLS_MVP) of
		[] ->
			skip;
		List ->
			%% 前100名发奖励
			Title = data_activity_text:get_3v3_week_award_title(),
			Content = data_activity_text:get_3v3_week_award_content(),
            lists:foldl(fun([_, _, Id, Node, _, _, _, _, _, _, _, _, Mvp], Position) ->
				case Position < 101 of
					true ->
						private_rpc_send_gift_mail(
							list_to_atom(binary_to_list(Node)),
							[Id],
							io_lib:format(Title, [Position]),
							io_lib:format(Content, [Position, Mvp]),
							private_get_1v1_week_award_gift(Position)
						);
					_ ->
						skip
				end,
				Position + 1
        	end, 1, List),

			spawn(fun() -> 
				%% 为达标玩家发奖励
				Dabiao = data_kf_3v3:get_config(daobiao_num),
				private_send_kf_3v3_append_award(Dabiao, 100, 100)
			end)
	end.

%% 获取1v1排行榜数据
private_get_kf_1v1_rank(RankType) ->
	case ets:lookup(?RK_KF_ETS_1V1_RANK, RankType) of
		[RD] when is_record(RD, kf_ets_1v1_rank) ->
			RD#kf_ets_1v1_rank.rank_list;
		_ ->
			[]
	end.

%% 获取排行榜数据
private_get_kf_rank(RankType) ->
	case ets:lookup(?RK_KF_ETS_RANK, RankType) of
		[RD] when is_record(RD, kf_ets_rank) ->
			RD#kf_ets_rank.rank_list;
		_ ->
			[]
	end.

%% 构造跨服1v1排行榜数据在ets中的record
private_make_1v1_rank(TypeId, List) ->
    #kf_ets_1v1_rank{type_id = TypeId, rank_list = List}.

%% 构造跨服排行榜数据在ets中的record
private_make_kf_rank(TypeId, List) ->
    #kf_ets_rank{type_id = TypeId, rank_list = List}.

%% 绑定头衔称号
private_bind_design(Rd, Pt) ->
	%% 格式：[声望区间开始, 声望区间结束, 称号id]
	List = [
		[11450, 18949, 202301],
		[18950, 28749, 202302],
		[28750, 41099, 202303],
		[41100, 56199, 202304],
		[56200, 74199, 202305],
		[74200, 95299, 202306],
		[95300, 119649, 202307],
		[119650, 9999999, 202308]
	],
	Result = lists:filter(fun([Start, End, _]) -> 
		Pt >= Start andalso Pt =< End
	end, List),
	case Result of
		[[_, _, DesignId]] ->
			catch rpc:cast(Rd#bd_1v1_player.node, lib_designation, bind_1v1_title, [Rd#bd_1v1_player.id, DesignId]);
		_ ->
			skip
	end.

%% 刷新跨服排行榜玩家榜
private_refresh_kf_player(RankType) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_KF_PLAYER_GET, [RankType, ?RK_KF_LIMIT])
	),
    ets:insert(
		?RK_KF_ETS_RANK,
		private_make_kf_rank(RankType, List)
	).

%% 刷新跨服排行榜宠物榜
private_refresh_kf_pet(RankType) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_KF_PET_GET, [RankType, ?RK_KF_LIMIT])
	),
    ets:insert(
		?RK_KF_ETS_RANK,
		private_make_kf_rank(RankType, List)
	).

%% 刷新跨服装备榜
private_refresh_kf_equip(RankType) ->
	List = db:get_all(
		io_lib:format(?SQL_RK_KF_EQUIP_GET, [RankType, ?RK_KF_LIMIT])
	),
    ets:insert(
		?RK_KF_ETS_RANK,
		private_make_kf_rank(RankType, List)
	).

%% 将玩家数据刷新到榜单上
private_update_player_rank(RankType, PlayerInfo, Value) ->
	case Value < 1 of
		true ->
			skip;
		_ ->
			[PlatForm, ServerNum, RoleId, NickName, Realm, Career, Sex] = PlayerInfo,

			case cls_get_kf_rank(RankType) of
				%% 第一个人上榜
				[] ->
					Sql = io_lib:format(?SQL_RK_KF_PLAYER_INSERT, [
						RoleId, PlatForm, ServerNum, RankType, NickName, Realm, Career, Sex, Value, util:unixtime()
					]),
					db:execute(Sql),
					RankRecord = private_make_kf_rank(RankType, [[RoleId, PlatForm, ServerNum, NickName, Realm, Career, Sex, Value]]),
					ets:insert(?RK_KF_ETS_RANK, RankRecord);

				%% 非第一个人上榜，需要作几步的处理
				List when is_list(List) ->
					Length = length(List),
					LastElement = lists:nth(Length, List),
		            [_, _, _, _, _, _, _, LastValue] = LastElement,
		            case Value =< LastValue andalso Length >= ?RK_KF_LIMIT of
		                true ->
		                    skip;
		                _ ->
							Sql = io_lib:format(?SQL_RK_KF_PLAYER_INSERT, [
								RoleId, PlatForm, ServerNum, RankType, NickName, Realm, Career, Sex, Value, util:unixtime()
							]),
							db:execute(Sql),

							%% 第一步：循环列表，替换排行值
				            F = fun(RankRow, [Exist, NewList]) ->
								[OldRoleId, TmpOldPlat, OldServerNum, _, _, _, _, _] = RankRow,
								OldPlat = util:make_sure_list(TmpOldPlat),
								ChangePlatForm = util:make_sure_list(PlatForm),
				                case OldRoleId =:= RoleId andalso OldPlat == ChangePlatForm andalso OldServerNum =:= ServerNum of
				                    true ->
				                        [1, [[RoleId, PlatForm, ServerNum, NickName, Realm, Career, Sex, Value] | NewList]];
				                    _ ->
				                        [Exist, [RankRow | NewList]]
				                end
				            end,
				            [NewExist, List2] = lists:foldl(F, [0, []], List),

				            case NewExist of
				                %% 之前不在榜上
				                0 ->
				                    List3 = [[RoleId, PlatForm, ServerNum, NickName, Realm, Career, Sex, Value] | List2];
				                _ ->
				                    List3 = List2
				            end,

							%% 第二步：排序
							SortFun = fun([_, _, _, _, _, _, _, Value1], [_, _, _, _, _, _, _, Value2]) ->
								Value1 >= Value2
							end,
							List4 = lists:sort(SortFun, List3),

							%% 第四步：截取指定条数据保留在榜单中
							List5 = case length(List4) > ?RK_KF_LIMIT of
								true ->
									lists:sublist(List4, 1, ?RK_KF_LIMIT);
								_ ->
									List4
							end,

							%% 第五步：保存进榜单数据中
							RankRecord = private_make_kf_rank(RankType, List5),
							ets:insert(?RK_KF_ETS_RANK, RankRecord)
					end
			end
	end.

%% 将宠物数据刷新到榜单上
%% petid,platform,server_num,petname,role_id,nickname,realm,career,sex,value
private_update_pet_rank(RankType, PlayerInfo, [PetId, TmpPetName, PetValue]) ->
	PetName = case is_integer(TmpPetName) of
		true ->
			integer_to_list(TmpPetName);
		_ ->
			TmpPetName
	end,
	[PlatForm, ServerNum, RoleId, NickName, Realm, Career, Sex] = PlayerInfo,
	case cls_get_kf_rank(RankType) of
		%% 第一个人上榜
		[] ->
			Sql = io_lib:format(?SQL_RK_KF_PET_INSERT, [
				PlatForm, ServerNum, PetId, RankType, RoleId, NickName, PetName, Realm, Career, Sex, PetValue, util:unixtime()
			]),
			db:execute(Sql),

			RankRecord = private_make_kf_rank(RankType, [[PetId, PlatForm, ServerNum, PetName, RoleId, NickName, Realm, Career, Sex, PetValue]]),
			ets:insert(?RK_KF_ETS_RANK, RankRecord);

		%% 非第一个人上榜，需要作几步的处理
		List when is_list(List) ->
			Length = length(List),
			LastElement = lists:nth(Length, List),
            [_, _, _, _, _, _, _, _, _, LastValue] = LastElement,
            case PetValue =< LastValue andalso Length >= ?RK_KF_LIMIT of
                true ->
                    skip;
                _ ->
					Sql = io_lib:format(?SQL_RK_KF_PET_INSERT, [PlatForm, ServerNum, PetId, RankType, 
						RoleId, NickName, PetName, Realm, Career, Sex, PetValue, util:unixtime()
					]),
					db:execute(Sql),

					%% 第一步：循环列表，替换排行值
		            F = fun(RankRow, [Exist, NewList]) ->
		                [OldPetId, OldPlat, OldServerNum | _] = RankRow,
		                case OldPetId =:= PetId andalso OldPlat == PlatForm andalso OldServerNum =:= ServerNum of
		                    true ->
		                        [1, [[PetId, PlatForm, ServerNum, PetName, RoleId, NickName, Realm, Career, Sex, PetValue] | NewList]];
		                    _ ->
		                        [Exist, [RankRow | NewList]]
		                end
		            end,
		            [NewExist, List2] = lists:foldl(F, [0, []], List),

		            case NewExist of
		                %% 之前不在榜上
		                0 ->
		                    List3 = [[PetId, PlatForm, ServerNum, PetName, RoleId, NickName, Realm, Career, Sex, PetValue] | List2];
		                _ ->
		                    List3 = List2
		            end,

					%% 第二步：排序
					SortFun = fun([_, _, _, _, _, _, _, _, _, Value1], [_, _, _, _, _, _, _, _, _, Value2]) ->
						Value1 > Value2
					end,
					List4 = lists:sort(SortFun, List3),

					%% 第四步：截取指定条数据保留在榜单中
					List5 = case length(List4) > ?RK_KF_LIMIT of
						true ->
							lists:sublist(List4, 1, ?RK_KF_LIMIT);
						_ ->
							List4
					end,

					%% 第五步：保存进榜单数据中
					RankRecord = private_make_kf_rank(RankType, List5),
					ets:insert(?RK_KF_ETS_RANK, RankRecord)
			end
	end.

%% 将装备数据刷新到榜单上
private_update_equip_rank(RankType, PlayerInfo, Row) ->
	[PlatForm, ServerNum, RoleId, NickName, _Realm, _Career, _Sex] = PlayerInfo,
	[_RoleId, GtypeId, GoodsId, _RoleName, Value, Color, Career, SubType] = Row,
	case cls_get_kf_rank(RankType) of
		%% 第一个人上榜
		[] ->
			Sql = io_lib:format(?SQL_RK_KF_EQUIP_INSERT, [
				PlatForm, ServerNum, GoodsId, RankType, RoleId, NickName, GtypeId, SubType, 
				Color, Career, Value, util:unixtime()
			]),
			db:execute(Sql),
			RankRecord = private_make_kf_rank(RankType, [[RoleId,PlatForm,ServerNum,GoodsId,GtypeId,NickName,Color,Career,SubType,Value]]),
			ets:insert(?RK_KF_ETS_RANK, RankRecord);

		%% 非第一个人上榜，需要作几步的处理
		List when is_list(List) ->
			Length = length(List),
			LastElement = lists:nth(Length, List),
            [_, _, _, _, _, _, _, _, _, LastValue] = LastElement,
            case Value =< LastValue andalso Length >= ?RK_KF_LIMIT of
                true ->
                    skip;
                _ ->
					Sql = io_lib:format(?SQL_RK_KF_EQUIP_INSERT, [
						PlatForm, ServerNum, GoodsId, RankType, RoleId, NickName, GtypeId, SubType, 
						Color, Career, Value, util:unixtime()
					]),
					db:execute(Sql),

					%% 第一步：循环列表，替换排行值
		            F = fun(RankRow, [Exist, NewList]) ->
		                [_, OldPlat, OldServerNum, OldGoodsId | _] = RankRow,
		                case OldGoodsId =:= GoodsId andalso OldPlat == PlatForm andalso OldServerNum =:= ServerNum of
		                    true ->
		                        [1, [[RoleId,PlatForm,ServerNum,GoodsId,GtypeId,NickName,Color,Career,SubType,Value] | NewList]];
		                    _ ->
		                        [Exist, [RankRow | NewList]]
		                end
		            end,
		            [NewExist, List2] = lists:foldl(F, [0, []], List),

		            case NewExist of
		                %% 之前不在榜上
		                0 ->
		                    List3 = [[RoleId,PlatForm,ServerNum,GoodsId,GtypeId,NickName,Color,Career,SubType,Value] | List2];
		                _ ->
		                    List3 = List2
		            end,

					%% 第二步：排序
					SortFun = fun([_, _, _, _, _, _, _, _, _, Value1], [_, _, _, _, _, _, _, _, _, Value2]) ->
						Value1 > Value2
					end,
					List4 = lists:sort(SortFun, List3),

					%% 第四步：截取指定条数据保留在榜单中
					List5 = case length(List4) > ?RK_KF_LIMIT of
						true ->
							lists:sublist(List4, 1, ?RK_KF_LIMIT);
						_ ->
							List4
					end,

					%% 第五步：保存进榜单数据中
					RankRecord = private_make_kf_rank(RankType, List5),
					ets:insert(?RK_KF_ETS_RANK, RankRecord)
			end
	end.

private_update_pet(PlayerInfo, PetInfo) ->
	[
		{power, PowerInfoName, PowerInfoId, PowerInfoValue},
		{grouth, GrouthInfoName, GrouthInfoId, GrouthInfoValue},
		{level, LevelInfoName, LevelInfoId, LevelInfoValue},
		{mount, MountInfoName, MountInfoId, MountInfoValue}
	] = PetInfo,
	private_update_pet_rank(?RK_KF_PET_POWER, PlayerInfo, [PowerInfoId, PowerInfoName, PowerInfoValue]),
	private_update_pet_rank(?RK_KF_PET_GROW, PlayerInfo, [GrouthInfoId, GrouthInfoName, GrouthInfoValue]),
	private_update_pet_rank(?RK_KF_PET_LEVEL, PlayerInfo, [LevelInfoId, LevelInfoName, LevelInfoValue]),
	private_update_pet_rank(?RK_KF_MOUNT_POWER, PlayerInfo, [MountInfoId, MountInfoName, MountInfoValue]).	
	
private_update_equip(PlayerInfo, EquipInfo) ->
	[
		{weapon, Result1},
		{defeng, Result2},
		{shipin, Result3}
	] = EquipInfo,
	lists:foreach(fun(Row1) -> 
		private_update_equip_rank(?RK_KF_EQUIP_WEAPON, PlayerInfo, Row1)	  
	end, Result1),
	lists:foreach(fun(Row2) -> 
		private_update_equip_rank(?RK_KF_EQUIP_DEFENG, PlayerInfo, Row2)	  
	end, Result2),
	lists:foreach(fun(Row3) -> 
		private_update_equip_rank(?RK_KF_EQUIP_SHIPIN, PlayerInfo, Row3)	  
	end, Result3).
