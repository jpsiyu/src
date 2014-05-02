%%%--------------------------------------
%%% @Module : pp_rank
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.5.31
%%% @Description : 排行榜
%%%--------------------------------------

-module(pp_rank).
-export([handle/3]).
-include("server.hrl").
-include("unite.hrl").
-include("rank.hrl").
-include("rank_cls.hrl").
-include("common.hrl").
-include("mount.hrl").

%% 查看名人堂
handle(22074, UniteStatus, get_rank) ->
	lib_fame_merge:get_fame_data(UniteStatus);

%% 合服合服名人堂
handle(22076, UniteStatus, get_rank) ->
	lib_fame_merge:get_merge_fame_data(UniteStatus);

%% 查询个人排行
handle(22001, UniteStatus, RankType) ->
	%% 参数判断
	PersionList = [?RK_PERSON_FIGHT, ?RK_PERSON_LV, ?RK_PERSON_WEALTH, 
	?RK_PERSON_ACHIEVE, ?RK_PERSON_REPUTATION, ?RK_PERSON_HUANHUA, ?RK_PERSON_CLOTHES],
	Data = case lists:member(RankType, PersionList) of
		true ->
			case lib_rank:pp_get_rank(RankType) of
				[] ->
					[];
				List ->
					case RankType =:= ?RK_PERSON_LV of
						true ->
							private_get_player_level_data(List);
						_ ->
							private_get_player_data(List)
					end
			end;
		false ->
			[]
	end,
    {ok, BinData} = pt_220:write(22080, [22001, RankType, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	
	%% 发送世界等级
	case RankType =:= ?RK_PERSON_FIGHT of
		true ->
			{WorldLevel, _} = mod_rank:get_world_level(),
			{ok, LevelBinData} = pt_220:write(22085, WorldLevel),
    		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, LevelBinData);
		_ ->
			skip
	end;

%% 查询个人排行 -- 元神榜
handle(22019, UniteStatus, get_rank) ->
	Data = case lib_rank:pp_get_rank(?RK_PERSON_VEIN) of
		[] ->
			[];
		List ->
			F = fun(P) ->
				[PId, PName, PSex, PCareer, PRealm, PGuild, PLevel, PVip] = P,
				NewPName = case PName =:= undefined of
					true -> <<"">>;
					_ -> PName
				end,
				NewName = pt:write_string(NewPName),
				TmpGuild = case PGuild =:= undefined of
					true -> <<"">>;
					_ -> PGuild
				end,
				NewGuild = pt:write_string(TmpGuild),
				<<PId:32,
				  NewName/binary,
				  PSex:8, PCareer:8, PRealm:8,
				  NewGuild/binary,
				  PLevel:16, PVip:8>>
			end,
			[F(Item) || Item <- List]
	end,
    {ok, BinData} = pt_220:write(22081, [22019, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 查询宠物排行
handle(22004, UniteStatus, RankType) ->
	Data = case lists:member(RankType, ?RK_TYPE_PET_LIST) of
		true ->
			 case lib_rank:pp_get_rank(RankType) of
				 [] ->
					 [];
				 List ->
					F = fun(PRow) ->
						[NId, NPetName, NPetId, NName, NRealm, NValue] = PRow,
						PName = pt:write_string(NPetName),
						RName = pt:write_string(NName),
						<<NId:32, PName/binary, NPetId:32, RName/binary, NRealm:8, NValue:32>>
					end,
					 [F(Row) || Row <- List]
			end;
		false ->
			[]
	end,
    {ok, BinData} = pt_220:write(22080, [22004, RankType, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 查询装备排行
handle(22002, UniteStatus, RankType) ->
	Data = case lists:member(RankType, [?RK_EQUIP_WEAPON, ?RK_EQUIP_DEFENG, ?RK_EQUIP_SHIPIN]) of
		true ->
			 case lib_rank:pp_get_rank(RankType) of
				 [] ->
					 [];
				 List ->
					F = fun(PRow) ->
						case PRow of
							[PUId, PTypeId, PId, PUName, PScore, PColor, PCareer, _] ->
								TmpName = case PUName =:= undefined of
									true -> <<"">>;
									_ -> PUName
								end,
								NewName = pt:write_string(TmpName),
								<<PUId:32, PTypeId:32, PId:32, NewName/binary, PScore:32, PColor:8, PCareer:8>>;
							_ ->
								TmpName3 = <<"">>,
								NewName3 = pt:write_string(TmpName3),
								<<0:32, 0:32, 0:32, NewName3/binary, 0:32, 0:8, 0:8>>
						end
					end,
					[F(Row) || Row <- List]
			end;
		false ->
			[]
	end,
    {ok, BinData} = pt_220:write(22080, [22002, RankType, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 查询帮会排行
handle(22003, UniteStatus, get_rank) ->
	Data = case lib_rank:pp_get_rank(?RK_GUILD_LV) of
		[] ->
			[];
		List ->
			F = fun(PGId, PGName, PRealm, PNum, PLevel) ->
				NewName = pt:write_string(PGName),
				<<PGId:32, NewName/binary, PRealm:8, PNum:8, PLevel:8>>
			end,
			[F(GId, GName, Realm, Num, Level) || [GId, GName, Realm, Num, Level] <- List]
	end,
    {ok, BinData} = pt_220:write(22081, [22003, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 查询竞技排行 - 竞技每日上榜
handle(22005, UniteStatus, get_rank) ->
	case lib_rank:pp_get_rank(?RK_ARENA_DAY) of
		[] ->
			{ok, BinData} = pt_220:write(22080, [22005, 1, []]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		List ->
			F = fun(Row) ->
				[Id, Name, Career, Realm, Sex, KillNum, Score] = Row,
				TmpName = case Name =:= undefined of
					true -> <<"">>;
					_ -> Name
				end,
				NewName = pt:write_string(TmpName),
				<<Id:32, NewName/binary, Career:8, Realm:8, Sex:8, KillNum:32, Score:32>>
			end,
			Data = [F(Item) || Item <- List],
			{ok, BinData} = pt_220:write(22080, [22005, 1, Data]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end;

%% 查询竞技排行 - 竞技每周上榜
handle(22020, UniteStatus, get_rank) ->
	Data = case lib_rank:pp_get_rank(?RK_ARENA_WEEK) of
		[] ->
			[];
		List ->
			F = fun(Row) ->
				[Id, Name, Career, Realm, Sex, KillNum, Score] = Row,
				TmpName = case Name =:= undefined of
					true -> <<"">>;
					_ -> Name
				end,
				NewName = pt:write_string(TmpName),
				<<Id:32, NewName/binary, Career:8, Realm:8, Sex:8, KillNum:32, Score:32>>
			end,
			[F(Item) || Item <- List]
	end,
    {ok, BinData} = pt_220:write(22081, [22020, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 查询竞技排行 - 竞技每周击杀榜
handle(22021, UniteStatus, get_rank) ->
	Data = case lib_rank:pp_get_rank(?RK_ARENA_KILL) of
		[] ->
			[];
		List ->
			F = fun(Row) ->
				[Id, Name, Career, Realm, Guild, KillNum] = Row,
				TmpName = case Name =:= undefined of
					true -> <<"">>;
					_ -> Name
				end,
				NewName = pt:write_string(TmpName),
				TmpGuild = case Guild =:= undefined of
					true -> <<"">>;
					_ -> Guild
				end,
				NewGuild = pt:write_string(TmpGuild),
				<<Id:32, NewName/binary, Career:8, Realm:8, NewGuild/binary, KillNum:32>>
			end,
			[F(Item) || Item <- List]
	end,
    {ok, BinData} = pt_220:write(22081, [22021, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 查询副本排行-铜钱副本
handle(22022, UniteStatus, get_rank) ->
	Data = case lib_rank:pp_get_rank(?RK_COPY_COIN) of
		[] ->
			[];
		List ->
			F = fun(PRow) ->
				[Id, Name, Career, Realm, Sex, Zan, _Coin, TotalCoin] = PRow,
				TmpName = case Name =:= undefined of
					true -> <<"">>;
					_ -> Name
				end,
				NewName = pt:write_string(TmpName),
				<<Id:32, NewName/binary, Career:8, Realm:8, Sex:8, Zan:16, TotalCoin:32>>
			end,
			[F(Row) || Row <- List]
	end,
    {ok, BinData} = pt_220:write(22081, [22022, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 查询竞技排行 - 九重天霸主排行
handle(22023, UniteStatus, RankType) ->
	case lists:member(RankType, [?RK_COPY_NINE, ?RK_COPY_NINE2]) of
		true ->
			CacheKey = lists:concat([rank_handle_22023, RankType]),
		        case get(CacheKey) of
			        undefined ->
				        put(CacheKey, util:unixtime()),
					private_handle_22023(UniteStatus, RankType);
			        Time ->
				        case Time + 30 > util:unixtime() of
					        true ->
						        skip;
					        _ ->
						        put(CacheKey, util:unixtime()),
							private_handle_22023(UniteStatus, RankType)
					end
		        end;
		_ ->
			skip
	end;

%% 查询炼狱排行
handle(22024, UniteStatus, get_rank) ->
	Data = case lib_rank:pp_get_rank(?RK_COPY_TOWER) of
		[] ->
			[];
		List ->
			F2 = fun([Id, Name, Career, Realm, Sex]) ->
				TmpName = case Name =:= undefined of
					true -> <<"">>;
					_ -> Name
				end,
				NewName = pt:write_string(TmpName),
				<<Id:32, NewName/binary, Career:8, Realm:8, Sex:8>>
			end,
			F = fun(PRow) ->
				[PassNum, Time | PList] = PRow,
				PlayerLlist = [F2(PlayerRow) || PlayerRow <- [PList]],
				Len = length(PlayerLlist),
				Bin = list_to_binary(PlayerLlist),
				<<PassNum:8, Time:32, Len:16, Bin/binary>>
			end,
			[F(Row) || Row <- List]
	end,
	{ok, BinData} = pt_220:write(22081, [22024, Data]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 查询魅力排行
handle(22014, UniteStatus, RankType) ->
	%% 参数判断
	case lists:member(RankType, [?RK_CHARM_DAY_HUHUA, ?RK_CHARM_DAY_FLOWER, ?RK_CHARM_HUHUA, ?RK_CHARM_FLOWER, ?RK_CHARM_HOTSPRING]) of
		true ->
			RankData = private_get_charm_rank(RankType),
			{ok, BinData} = pt_220:write(22080, [22014, RankType, RankData]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		false ->
			skip
	end;

%% 限时名人堂（活动）排行
handle(22018, UniteStatus, RankType) ->
	%% 参数判断
	case lists:member(RankType, [?RK_FAME_COIN, ?RK_FAME_TAOBAO, ?RK_FAME_EXP, ?RK_FAME_PT]) of
		true ->
		    CacheKey = lists:concat([rank_handle_22018_, RankType]),
			case get(CacheKey) of
				undefined ->
					put(CacheKey, util:unixtime()),
					RankData = private_handle_22018(RankType),
					{ok, BinData} = pt_220:write(22080, [22018, RankType, RankData]),
					lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				Time ->
					case Time + 10 > util:unixtime() of
						true ->
							skip;
						_ ->
							RankData = private_handle_22018(RankType),
							{ok, BinData} = pt_220:write(22080, [22018, RankType, RankData]),
							lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
					end
			end;
		false ->
			skip
	end;

%% 查询坐骑排行
handle(22040, UniteStatus, RankType) ->
	Data = case lists:member(RankType, ?RK_TYPE_MOUNT_LIST) of
		true ->
			 case lib_rank:pp_get_rank(RankType) of
				 [] ->
					 [];
				 List ->
					F = fun(PRow) ->
						[RoleId,RoleName,Career,Realm,MountId,MountType,Power] = PRow,
						TmpName = case RoleName =:= undefined of
							true -> <<"">>;
							_ -> RoleName
						end,
						NewRoleName = pt:write_string(TmpName),
						<<RoleId:32, NewRoleName/binary, Career:8, Realm:8, MountId:32,MountType:32,Power:32>>
					end,
					 [F(Row) || Row <- List]
			end;
		false ->
			[]
	end,
    {ok, BinData} = pt_220:write(22080, [22040, RankType, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 坐骑-详细信息
handle(22041, UniteStatus, Id) ->
	case db:get_row(io_lib:format(?SQL_MOUNT_SELECT2, [Id])) of
		[_RoleId,TypeId,Figure,Stren,Power,Level,_Star,Quality,NickName] ->
			{ok, BinData} = pt_220:write(22041, [Figure, Power, Stren, Quality, Level, NickName, TypeId]),
    		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		_ ->
			skip	
	end;

%% 查询飞行器战力排行
handle(22042, UniteStatus, _) ->
	 Data = case lib_rank:pp_get_rank(?RK_FLYER_POWER) of
		 [] ->
			 [];
		 List ->
			F = fun(PRow) ->
				[Id, Name, Career, Realm, Sex, FlyerId, FlyerName, Power, Quality] = PRow,
				Name2 = pt:write_string(Name),
				FlyerName2 = util:to_term(FlyerName),
				FlyerName3 = pt:write_string(FlyerName2),
				<<Id:32, Name2/binary, Career:8, Realm:8, Sex:8, FlyerId:32, FlyerName3/binary, Power:32, Quality:8>>
			end,
			 [F(Row) || Row <- List]
	end,
    {ok, BinData} = pt_220:write(22081, [22042, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% [游戏线]参与战斗力评分
handle(22070, PS, eva) ->
	case get(rank_handle_22070) of
		undefined ->
			put(rank_handle_22070, util:unixtime()),
			lib_rank:eva_combat_power(PS),
			NewPS = lib_player:count_hightest_combat_power(PS),
			{ok, NewPS};
			%% 让客户端刷新榜单
%% 			mod_disperse:cast_to_unite(pp_rank, refresh_player_power_rank, [PS#player_status.id]);
		Time ->
			case Time + 30 > util:unixtime() of
				true ->
					{ok, PS};
				_ ->
					put(rank_handle_22070, util:unixtime()),
					lib_rank:eva_combat_power(PS),
					NewPS = lib_player:count_hightest_combat_power(PS),
					{ok, NewPS}
					%% 让客户端刷新榜单
%% 					mod_disperse:cast_to_unite(pp_rank, refresh_player_power_rank, [PS#player_status.id])
			end
	end;

%% [游戏线]身上装备快速评分
handle(22017, PS, eva) ->
	case get(rank_handle_22017) of
		undefined ->
			put(rank_handle_22017, util:unixtime()),
			private_handle_22017(PS);
		Time ->
			case Time + 10 > util:unixtime() of
				true ->
					skip;
				_ ->
					put(rank_handle_22017, util:unixtime()),
					private_handle_22017(PS)
			end
	end;

%% 查看角色基础信息
handle(22016, UniteStatus, [PlayerId, RankType, Position]) ->
    case lib_rank:query_role_rank_info(UniteStatus, PlayerId, RankType, Position) of
        {ok, Data} ->
			case catch pt_220:write(22016, [1, RankType, Data]) of
				{ok, BinData} ->
            		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				_ ->
					util:errlog("22016, PlayerId = ~p, RankType = ~p, Position = ~p, Data = ~p~n", [PlayerId, RankType, Position, Data]),
					skip
			end;
        _ ->
            skip
    end;

%% 崇拜/鄙视玩家
handle(22015, UniteStatus, [RoleId, LookUponType, RankTypeNum]) ->
	%% 取出当天已使用的次数
	DailyTimes = mod_daily:get_count(UniteStatus#unite_status.dailypid, UniteStatus#unite_status.id, 2200),

	%% 最后一次操作的时间
	LastTime = get_time(),
	NowTime = util:unixtime(),
	case NowTime - LastTime < 3 of
		false ->
			%% 刷新操作时间
            lib_server_dict:rank_look(NowTime),
            case DailyTimes < 10 of
                true ->
                    case lib_rank:look_upon_role(RoleId, RankTypeNum, LookUponType, UniteStatus#unite_status.id) of
                        {ok, Worship, Disdain} ->
							%% 操作数加1
                            catch mod_daily:increment(UniteStatus#unite_status.dailypid, UniteStatus#unite_status.id, 2200),
                            {ok, BinData} = pt_220:write(22015, [1, LookUponType, RankTypeNum, RoleId, Worship, Disdain, DailyTimes + 1]),
                            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
                        {error, ErrorCode} ->
                            {ok, BinData} = pt_220:write(22015, [ErrorCode, LookUponType, RankTypeNum, RoleId, 0, 0, DailyTimes]),
                            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
                        skip ->
                            skip
                    end;
				%% 已达每天上限，错误码6
                false ->
                    {ok, BinData} = pt_220:write(22015, [6, LookUponType, RankTypeNum, RoleId, 0, 0, DailyTimes]),
                    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
            end;
		%% 过于频繁，错误码4
        true ->
            {ok, BinData} = pt_220:write(22105, [4, LookUponType, RankTypeNum, RoleId, 0, 0, DailyTimes]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
    end;

%% [游戏线] 限时名人堂（活动）获取雕像数据
handle(22030, PS, _) ->
	case lib_fame_limit:get_masters() of
		List  when is_list(List) ->
			{ok, BinData} = pt_220:write(22030, List),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		_ ->
			skip
	end;

%% [游戏线] 单件装备评分
handle(22071, PS, GoodsId) ->
	case is_integer(GoodsId) of
		true ->
			case get(rank_handle_22071) of
				undefined ->
					put(rank_handle_22071, util:unixtime()),
					private_handle_22071(PS, GoodsId);
				Time ->
					case Time + 10 > util:unixtime() of
						true ->
							skip;
						_ ->
							put(rank_handle_22071, util:unixtime()),
							private_handle_22071(PS, GoodsId)
					end
			end;
		_ ->
			skip
	end;

%% 跨服1v1玩家自己信息
handle(22050, US, _) ->
	[PtValue, WeekScore] = case lib_player:get_player_info(US#unite_status.id, kf_1v1_info) of
		{_CombatPower, _Hp, _HpLim, _Scene, Pt, _LoopDay, _MaxCombatPower, StatusKf1v1} -> 
			[Pt, StatusKf1v1#status_kf_1v1.score_week];
		_ ->
			[0, 0]
	end,
	{ok, BinData} = pt_220:write(22050, [PtValue, 0, WeekScore, 0, 0]),
	lib_unite_send:send_to_sid(US#unite_status.sid, BinData);

%% 跨服1v1每周榜
handle(22052, US, _) ->
	List = lib_rank_cls:game_get_1v1_rank(?RK_CLS_WEEK),
	List2 = lists:map(fun(Row) -> 
		[Platform,ServerNum,Id,_Node,Name,Realm,Carrer,Sex,Loop,WinLoop,Score,Pt,Lv] = Row,
		NewPF = pt:write_string(Platform),
		NewName = case Name =:= undefined of
			true -> <<"">>;
			_ -> Name
		end,
		NewName2 = pt:write_string(NewName),
		<<Id:32,NewPF/binary,ServerNum:16,NewName2/binary,Realm:8,Carrer:8,Sex:8,Score:32,Loop:16,WinLoop:16,Pt:32,Lv:16>>
	end, List),
	{ok, BinData} = pt_220:write(22052, List2),
	lib_unite_send:send_to_sid(US#unite_status.sid, BinData);

%% 跨服3v3 mvp榜
handle(22053, US, _) ->
	List = lib_rank_cls:game_get_1v1_rank(?RK_CLS_MVP),
	List2 = lists:map(fun(Row) -> 
		[Platform,ServerNum,Id,_Node,Name,Realm,Carrer,Sex,Lv,Pt,Win,Lose,Mvp] = Row,
		NewPF = pt:write_string(Platform),
		Name2 = pt:write_string(Name),
		Loop = Win + Lose,
		<<Id:32,NewPF/binary,ServerNum:16,Name2/binary,Realm:8,Carrer:8,Sex:8,Mvp:32,Loop:16,Win:16,Pt:32,Lv:16>>
	end, List),
	{ok, BinData} = pt_220:write(22053, List2),
	lib_unite_send:send_to_sid(US#unite_status.sid, BinData);

%% 跨服3v3玩家自己信息
handle(22054, US, _) ->
	[PtValue, Mvp, PkNum, PkWin, ScoreWeek] = case lib_player:get_player_info(US#unite_status.id, kf_pk_info) of
		{StatusKf1v1, StatusKf3v3} -> 
			[StatusKf1v1#status_kf_1v1.pt, StatusKf3v3#status_kf_3v3.mvp, StatusKf3v3#status_kf_3v3.kf3v3_pk_num, StatusKf3v3#status_kf_3v3.kf3v3_pk_win, StatusKf3v3#status_kf_3v3.kf3v3_score_week];
		_ ->
			[0, 0, 0, 0, 0]
	end,
%% 	io:format("ScoreWeek = ~p~n", [ScoreWeek]),
	{ok, BinData} = pt_220:write(22054, [PtValue, 0, Mvp, PkNum, PkWin, ScoreWeek]),
	lib_unite_send:send_to_sid(US#unite_status.sid, BinData);

%% 跨服3v3本地周积分榜
handle(22055, US, _) ->
	List = lib_kf_3v3_rank:get_bd_week_rank(),
	List2 = lists:map(fun(Row) -> 
		[Id,Name,Realm,Carrer,Sex,Lv,Pt,Score,Win,Lose] = Row,
		Name2 = pt:write_string(Name),
		Loop = Win + Lose,
		<<Id:32,Name2/binary,Realm:8,Carrer:8,Sex:8,Score:32,Loop:16,Win:16,Pt:32,Lv:16>>
	end, List),
	{ok, BinData} = pt_220:write(22055, List2),
	lib_unite_send:send_to_sid(US#unite_status.sid, BinData);

%% 跨服玩家相关榜
handle(22058, US, RankType) ->
	NewList = case lib_rank_cls:game_get_kf_rank(RankType) of
		[] ->
			[];
		List ->
			F = fun(Item) ->
				[Id, Platform, ServerId, Nick, Realm, Career, Sex, Value] = Item,
				Platform2 = pt:write_string(Platform),
				Nick2 = pt:write_string(Nick),
				<<Id:32, Platform2/binary, ServerId:16, Nick2/binary, Realm:8, Career:8, Sex:8, Value:32>>
			end,
			[F(Row) || Row <- List]
	end,
    {ok, BinData} = pt_220:write(22058, [RankType, NewList]),
    lib_unite_send:send_to_sid(US#unite_status.sid, BinData);

%% 跨服宠物相关榜
handle(22059, US, RankType) ->
	NewList = case lib_rank_cls:game_get_kf_rank(RankType) of
		[] ->
			[];
		List ->
			F = fun(Item) ->
				[_PetId, Platform, ServerId, PetName, RoleId, NickName, Realm, Career, Sex, Value] = Item,
				Platform2 = pt:write_string(Platform),
				NickName2 = pt:write_string(NickName),
				PetName2 = pt:write_string(PetName),
				<<RoleId:32, Platform2/binary, ServerId:16, NickName2/binary, PetName2/binary, Realm:8, Career:8, Sex:8, Value:32>>
			end,
			[F(Row) || Row <- List]
	end,
    {ok, BinData} = pt_220:write(22059, [RankType, NewList]),
    lib_unite_send:send_to_sid(US#unite_status.sid, BinData);

%% 跨服装备相关榜
handle(22060, US, RankType) ->
	NewList = case lib_rank_cls:game_get_kf_rank(RankType) of
		[] ->
			[];
		List ->
			F = fun(Item) ->
				[RoleId, Platform, ServerId, _GoodsId, GoodsType, NickName, Color, Career, _EquipSubType, Score] = Item,
				Platform2 = pt:write_string(Platform),
				NickName2 = pt:write_string(NickName),
				<<RoleId:32, Platform2/binary, ServerId:16, GoodsType:32, NickName2/binary, Score:32, Color:8, Career:8>>
			end,
			[F(Row) || Row <- List]
	end,
    {ok, BinData} = pt_220:write(22060, [RankType, NewList]),
    lib_unite_send:send_to_sid(US#unite_status.sid, BinData);

%% [魅力榜活动] 获取数据
handle(22065, UniteStatus, _) ->
	{ok, Bin} = pt_220:write(22065, [
			private_get_charm_rank(?RK_CHARM_DAY_FLOWER, 20),
			private_get_charm_rank(?RK_CHARM_DAY_HUHUA, 20)
		]
	),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, Bin);

handle(_Cmd, _LogicStatus, _Data) ->
	?DEBUG("pp_rank no match", []),
	{error, "pp_rank no match"}.

get_time() ->
	case lib_server_dict:rank_look() of
		undefined -> 0;
		Time -> Time
	end.

%% 全身装备评估
private_handle_22017(PS) ->
	case lib_rank:evaluate_equip_list(PS) of
		{error, ErrorCode} ->
			{ok, BinData} = pt_220:write(22017, [ErrorCode, []]),
    		lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		{ok, List} ->
			F = fun([_, TypeId, _, _, _, Color, _, Score]) ->
				<<TypeId:32, Color:8, Score:16>>
			end,
			NewList = [F(Item) || Item <- List],
			{ok, BinData} = pt_220:write(22017, [1, NewList]),
    		lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	end.

%% 单件装备评估
private_handle_22071(PS, GoodsId) ->
	GoodsPid = PS#player_status.goods#status_goods.goods_pid,
	Result = lib_rank:evaluate_equip(GoodsPid, GoodsId, PS#player_status.id, PS#player_status.nickname, PS#player_status.career),
	{ok, BinData} = pt_220:write(22071, Result),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData).

%% 获取鲜花魅力榜数据
private_get_charm_rank(RankType) ->
	case lib_rank:pp_get_rank(RankType) of
		[] ->
			[];
		List ->
			F = fun(PRow) ->
				[Id, Name, Sex, Career, Realm, Guild, Value, Image] = PRow,
				TmpName = case Name =:= undefined of
					true -> <<"">>;
					_ -> Name
				end,
				NewName = pt:write_string(TmpName),
				GuildName = case Guild =:= undefined of
					true -> <<"">>;
					_ -> Guild
				end,
				NewGuild = pt:write_string(GuildName),
				<<Id:32, NewName/binary, Sex:8, Career:8, Realm:8, NewGuild/binary, Value:32, Image:16>>
			end,
			[F(Row) || Row <- List]
	end.

%% 限时名人堂（活动）排行
private_handle_22018(RankType) ->
	case lib_fame_limit:get_rank_data(RankType) of
		[] ->
			[];
		List ->
			F = fun(PRow) ->
				[Id, Name, Sex, Career, Realm, Level, Power, Value] = PRow,
				TmpName = case Name =:= undefined of
					true -> <<"">>;
					_ -> Name
				end,
				NewName = pt:write_string(TmpName),
				<<Id:32, NewName/binary, Sex:8, Career:8, Realm:8, Level:8, Power:32, Value:32>>
			end,
			[F(Row) || Row <- List]
	end.

%% 获取玩家等级排行数据
private_get_player_level_data(List) ->
	F = fun(Item) ->
		[PId, PName, PSex, PCareer, PRealm, PGuild, PValue, PVip, _PExp] = Item,
		TmpName = case PName =:= undefined of
			true -> <<"">>;
			_ -> PName
		end,
		NewName = pt:write_string(TmpName),
		TmpGuild = case PGuild =:= undefined of
			true -> <<"">>;
			_ -> PGuild
		end,
		NewGuild = pt:write_string(TmpGuild),
		<<PId:32, NewName/binary, PSex:8, PCareer:8, PRealm:8, NewGuild/binary, PValue:32, PVip:8>>
	end,
	[F(Row) || Row <- List].

%% 获取玩家其他排行数据
private_get_player_data(List) ->
	F = fun(Item) ->
		[PId, PName, PSex, PCareer, PRealm, PGuild, PValue, PVip] = Item,
		TmpName = case PName =:= undefined of
			true -> <<"">>;
			_ -> PName
		end,
		NewName = pt:write_string(TmpName),
		TmpGuild = case PGuild =:= undefined of
			true -> <<"">>;
			_ -> PGuild
		end,
		NewGuild = pt:write_string(TmpGuild),
		<<PId:32, NewName/binary, PSex:8, PCareer:8, PRealm:8, NewGuild/binary, PValue:32, PVip:8>>
	end,
	[F(Row) || Row <- List].

%% 处理九重天
private_handle_22023(UniteStatus, RankType) ->
	GetType = case RankType of
		?RK_COPY_NINE -> 1;
		?RK_COPY_NINE2 -> 2
	end,
	Data = case lib_tower_dungeon:rank_master(GetType) of
		[] ->
			[];
		List ->
			F2 = fun(PName) ->
				PName2 = pt:write_string(PName),
				<<PName2/binary>>
			end,
			F = fun(PRow) ->
				[Level, PlayerList, Time] = PRow,
				NewPlayerLlist = [F2(NickName) || NickName <- PlayerList],
				Len = length(NewPlayerLlist),
				Bin = list_to_binary(NewPlayerLlist),
				<<Level:8, Len:16, Bin/binary, Time:32>>
			end,
			[F(Row) || Row <- List]
	end,
	{ok, BinData} = pt_220:write(22080, [22023, RankType, Data]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData).

%% 中秋国庆活动：获取魅力榜
private_get_charm_rank(RankType, RecordNum) ->
	case lib_rank:pp_get_rank(RankType) of
		[] ->
			[];
		List ->
			[LastList, _] = 
			lists:foldl(fun([Id, Nick, Sex, Career, Realm, _, Value, Image], [TmpList, Position]) -> 
				case Position =< RecordNum of
					true ->
						TmpNick = case Nick =:= undefined of
							true -> <<"">>;
							_ -> Nick
						end,
						NewNick = pt:write_string(TmpNick),
						Data = <<Id:32, NewNick/binary, Sex:8, Career:8, Realm:8, Value:32, Image:16>>,
						[[Data | TmpList], Position + 1];
					_ ->
						[TmpList, Position + 1]
				end
			end, [[], 1], List),
			lists:reverse(LastList)
	end.
