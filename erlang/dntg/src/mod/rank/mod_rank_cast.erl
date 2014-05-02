%%%--------------------------------------
%%% @Module  : mod_rank_cast
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.5.31
%%% @Description :  排行榜
%%%--------------------------------------

-module(mod_rank_cast).
-include("common.hrl").
-include("rank.hrl").
-include("rank_cls.hrl").
-include("sql_rank.hrl").
-include("designation.hrl").
-export([handle_cast/2]).

%% 按类型刷新排行榜
handle_cast({'refresh_rank', RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate}, State) ->
	lib_rank:refresh_rank(RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate),
	{noreply, State};

%% 按类型刷新排行榜
handle_cast({'timer_refresh_rank', RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate}, State) ->
	lib_rank:timer_refresh_rank(RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate),
	{noreply, State};

%% 刷单个榜[只刷新数据]
handle_cast({'refresh_single', RankType}, State) ->
	 spawn(fun() ->
        catch lib_rank:refresh_single(RankType)
    end),
	{noreply, State};

%% 刷单个榜[刷新数据，还会触发活动奖励等]
handle_cast({'timer_refresh_single', RankType}, State) ->
	 spawn(fun() ->
        catch lib_rank:timer_refresh_single(RankType)
    end),
	{noreply, State};

%% 更新排行榜名人堂荣誉完成情况
handle_cast({'update_fame', FameId, PlayerList}, State) ->
	spawn(fun() ->
        catch lib_rank:update_fame(FameId, PlayerList)
    end),
	{noreply, State};

%% 更新排行榜（装备排行除外，需要手工评分）
handle_cast({'update_rank', RoleUpdate, EquipUpdate, GuildUpdate, PetUpdate, ArenaUpdate}, State) ->
    spawn(fun() ->
        catch lib_rank:update_rank(RoleUpdate, EquipUpdate, GuildUpdate, PetUpdate, ArenaUpdate)
    end),
    {noreply, State};

%% 更新装备排行
handle_cast({'update_equip_rank', GoodsInfoList}, State) ->
    spawn(fun() ->
        catch lib_rank:update_equip_rank(GoodsInfoList)
    end),
    {noreply, State};

%% 更新玩家战力排行榜
handle_cast({'refresh_rank_of_player_power', Row}, State) ->
	lib_rank_refresh:refresh_rank_of_player_power(?RK_PERSON_FIGHT, Row),
    {noreply, State};

%% 更新玩家等级排行榜
handle_cast({'update_player_level_rank', Row}, State) ->
	lib_rank_refresh:refresh_rank_of_person_level(?RK_PERSON_LV, Row),
    {noreply, State};

%% 生成鲜花榜
handle_cast('flower_rank', State) ->
    spawn(fun() ->
        catch lib_rank:create_flower_rank()
    end),
    {noreply, State};

%% 清理角色榜的装备数据
handle_cast('clean_role_rank_equip_info', State) ->
    spawn(fun() ->
        catch lib_rank:clean_role_rank_equip_info()
    end),
    {noreply, State};

%% 刷新魅力榜
handle_cast({'refresh_flower_rank', RefreshData}, State) ->
	{AddScore,
		{from, [FromId, FromName, FromSex, FromCareer, FromRealm, FromGuild, FromImage]},
		{to, [ToId, ToName, ToSex, ToCareer, ToRealm, ToGuild, ToImage]} 
	} = RefreshData,
	
	FromRankType = case FromSex of
		1 -> 7001;
		_ -> 7002
	end,
	lib_rank_refresh:refresh_rank_700(FromRankType, [FromId, FromName, FromSex, FromCareer, FromRealm, FromGuild, FromImage], AddScore),

	case FromId /= ToId of
		true ->
			ToRankType = case ToSex of
				1 -> 7001;
				_ -> 7002
			end,
			lib_rank_refresh:refresh_rank_700(ToRankType, [ToId, ToName, ToSex, ToCareer, ToRealm, ToGuild, ToImage], AddScore);
		_ -> skip
	end,
	{noreply, State};

%% 变性
handle_cast({'change_sex', RoleId, Sex}, State) ->
	lib_rank_refresh:change_sex(RoleId, Sex),
	{noreply, State};

%% 清跨服排行榜缓存
handle_cast({'remove_cls_rank'}, State) ->
	lib_rank_cls:remove_cls_rank(),

	%% 刷新跨服排行榜，清数据清掉重新获取
	lib_rank_cls:game_clear_kf_rank(),

	{noreply, State};

%% 重新设置游戏节点这边的跨服1v1排行榜数据
%% Data : [{RankType, List}, ...]
handle_cast({'reset_kf_1v1_rank', Data}, State) ->
	%% 刷新跨服1v1榜单数据
	lib_rank_cls:update_kf_1v1_rank(Data),

	%% 刷新跨服排行榜，清数据清掉重新获取
	lib_rank_cls:game_clear_kf_rank(),

	%% 刷新3v3本地周积分榜
	lib_kf_3v3_rank:refresh_bd_week_rank(),

	{noreply, State};

%% 重新设置游戏节点这边的跨服排行榜数据
%% Data : [{RankType, List}, ...]
handle_cast({'reset_kf_rank', Data}, State) ->
	lib_rank_cls:update_kf_rank(Data),
	{noreply, State};

%% 玩家进入跨服之后，更新跨服排行榜数据
handle_cast({'remote_update_kf_rank', [RoleId]}, State) ->
	case lib_player:get_player_info(RoleId, kf_rank_info) of
		[PlatForm, ServerNum, NickName, Realm, Career, Sex, Power, Lv, Coin, Cjpt, Gjpt] ->
			PlayerInfo = [PlatForm, ServerNum, RoleId, NickName, Realm, Career, Sex],

			%% 玩家相关榜
			spawn(fun() -> 
				%% 着装度
				Wear = db:get_one(io_lib:format(?SQL_RK_GET_WEAR_DEGREE, [RoleId])),
				%% 境界总等级
				Meridian = lib_rank_cls:get_rank_meridian(RoleId),
				catch mod_clusters_node:apply_cast(
					lib_rank_cls,
					cls_update_kf_data, 
					[player, PlayerInfo, [Power, Lv, Coin, Cjpt, Gjpt, Wear, Meridian]]
				)
			end),

			%% 宠物，装备，坐骑榜
			spawn(fun() -> 
				PetInfo = lib_rank_cls:game_get_pet_info(RoleId),
				EquipInfo = lib_rank_cls:game_get_equip_info(RoleId),
				catch mod_clusters_node:apply_cast(
					lib_rank_cls,
					cls_update_kf_data,
					[other, PlayerInfo, [PetInfo, EquipInfo]]
				)
			end);
		_ ->
			skip
	end,
	{noreply, State};

%% 清除跨服排行榜缓存
handle_cast({'remove_kf_rank_cache'}, State) ->
	ets:delete_all_objects(?RK_KF_CACHE_RANK),
	{noreply, State};

%% [斗战封神活动] 刷新跨服战力活动排行榜
handle_cast({'kfrank_reset_power_list', Platform, ServerId, Id, List}, State) ->
	case List of
		[] ->
			Rank = #ets_module_rank{type_id = ?MODULE_RANK_2, update = util:unixtime()},
			ets:insert(?MODULE_RANK, Rank),

			MyRankNo = lib_activity_kf_power:get_power_rank_myno(Platform, ServerId, Id, Rank#ets_module_rank.rank_list),
			{ok, Bin} = pt_319:write(31901, [MyRankNo, Rank#ets_module_rank.top_10, lib_activity_kf_power:get_power_rank_gift(Id)]),
			lib_unite_send:send_to_uid(Id, Bin);

		[AllList, Top10] ->
			%% 将前10的玩家形象数据构造好，不用每次玩家请求再构造
			[TopImage, _] = lists:foldl(fun([ArgPlatform, ArgServerId, ArgId | _], [TmpTopImage, TmpPos]) -> 
				case TmpPos < 11 of
					true ->
						case lists:keyfind([ArgPlatform, ArgServerId, ArgId], 1, Top10) of
							false -> [TmpTopImage, TmpPos + 1];
							Tuple -> [[Tuple | TmpTopImage], TmpPos + 1]
						end;
					_ ->
						[TmpTopImage, TmpPos]
				end
			end, [[], 1], AllList),
			NewTopImage = lib_activity_kf_power:formate_power_top10(lists:reverse(TopImage)),
			Rank = #ets_module_rank{type_id = ?MODULE_RANK_2, update = util:unixtime(), rank_list = AllList, top_10 = NewTopImage},
			ets:insert(?MODULE_RANK, Rank),

			MyRankNo = lib_activity_kf_power:get_power_rank_myno(Platform, ServerId, Id, Rank#ets_module_rank.rank_list),
			{ok, Bin} = pt_319:write(31901, [MyRankNo, Rank#ets_module_rank.top_10, lib_activity_kf_power:get_power_rank_gift(Id)]),
			lib_unite_send:send_to_uid(Id, Bin),

			{ok, Bin2} = pt_319:write(31902, Rank#ets_module_rank.rank_list),
			lib_unite_send:send_to_uid(Id, Bin2)
	end,
	{noreply, State};


%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_rank:handle_cast not match: ~p", [Event]),
    {noreply, Status}.
