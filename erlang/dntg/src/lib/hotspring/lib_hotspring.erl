%%%--------------------------------------
%%% @Module  : lib_hotspring
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.9
%%% @Description: 黄金沙滩
%%%--------------------------------------

-module(lib_hotspring).
-include("server.hrl").
-include("hotspring.hrl").
-include("rank.hrl").
-export([
	is_validate_time/1,				%% 是否在有效的活动时间内
	get_sceneid/1,				%% 取得当前活动场景id
	is_enterable/2,				%% 是否能够进入温泉
	count_gain/1,					%% 计算每分钟收益
	interact/3,					%% 互动
	broadcast/1,					%% 广播
	get_left_num/1,				%% 获取剩下互动次数
	timer_get_next_time/1,			%% 获取下次广播时间（秒）
	add_score/2,					%% 增加或减少魅力值
	insert_rank_charm/1,			%% 插入沙滩魅力榜
	update_interact_playerlist/3,		%% 更新玩家交互数据
	offline/1						%% 玩家下线
]).

%% 是否能够进入温泉
%% RoomId : 房间id
is_enterable(PS, RoomId) ->
	%% 玩家等级是否足够
	case PS#player_status.lv >= data_hotspring:get_require_lv() of
		true ->
			%% 操作太频繁
			case util:unixtime() - PS#player_status.hotspring#status_hotspring.exittime > 10 of
				true ->
					%% 从公共线进程中获取活动时间和房间列表
					[TimeRange, RoomList, PlayerList1, PlayerList2] = private_get_data_from_timer(PS#player_status.id),
					SceneId = get_sceneid(TimeRange),
					%% 是否同个场景
					case PS#player_status.scene =/= SceneId of
						true ->
							%% 是否在活动时间内
							case is_validate_time(TimeRange) of
								true ->
									%% 判断房间人数是否满了
									case private_is_room_full(RoomId, RoomList) of
										false ->
											%% 是否可以传送
											case lib_player:is_transferable(PS) of
												true ->
													%% 全部通过判断
													{ok, TimeRange, SceneId, PlayerList1, PlayerList2};
												false ->
													{error, 6}
											end;
										_ ->
											{error, 10}
									end;
								_ ->
									{error, 3}
							end;
						_ ->
							{error, 6}
					end;
				_ ->
					{error, 7}
			end;
		_ ->
			{error, 2}
	end.

%% 取得当前活动场景id
get_sceneid(TimeRange) ->
	NowTS = util:unixtime(),
	[{BeginAM, _EndAM}, {BeginPM, EndPM}] = private_get_activity_unixtime(TimeRange),
	TimeType = 
		if
			(NowTS >= BeginAM) andalso (NowTS < BeginPM) ->
				am;
			(NowTS >= BeginPM) andalso (NowTS =< EndPM + 1800) ->
				pm;
			true ->
				am
		end,
    data_hotspring:get_sceneid(TimeType).

%% 计算收益
count_gain(PS) ->
	HS = PS#player_status.hotspring,
	case HS#status_hotspring.timerange of
		%% 没有进入场景就发起协议，防刷
		undefined ->
			{error, 2};
		_ ->
			SceneId = get_sceneid(HS#status_hotspring.timerange),
			case PS#player_status.scene =/= SceneId of
				true ->
					{error, 2};
				_ ->
					%% 是否在活动时间内
					case is_validate_time(HS#status_hotspring.timerange) of
						false ->
							{error, 4};
						_ ->
							NowTS = util:unixtime(),
							NeedTime = data_hotspring:get_min_count_time(),
							KeepTime = NowTS - HS#status_hotspring.lasttime,
							case KeepTime < NeedTime of
								true ->
									{error, 5};
								_ -> 
									NewPS = private_get_gain(PS, NowTS, NeedTime),
									{ok, NewPS}
							end
					end
			end
	end.

%% 互动
%% InteractType : 互动类型，1（恶搞）锤子，2（恶搞）冰球，3（示好）飞吻
%% PlayerId : 被互动的玩家id
interact(PS, InteractType, PlayerId) ->
	case private_is_interactable(PS, PlayerId) of
		{ok, StatusAchieve} ->
			%% 定义的互动次数
			[Int1, Int2] = data_hotspring:get_interact_num(PS#player_status.vip#status_vip.vip_type),
			CanInt =
				case InteractType =:= 3 of
					true -> Int2;
					_ -> Int1
				end,

			%% 已经互动的次数
			AlreadyInt1 = mod_daily_dict:get_count(PS#player_status.id, 1021),
			AlreadyInt2 = mod_daily_dict:get_count(PS#player_status.id, 1022),
			AlreadyInt =
				case InteractType =:= 3 of
					true -> AlreadyInt2;
					_ -> AlreadyInt1
				end,

			%% 获得经验
			NewPS =
				case CanInt > AlreadyInt of
					true ->
						%% 多倍奖励
						MultiAward = private_get_multi_award_time(PS),

						TmpExp = data_hotspring:get_interact_exp(PS#player_status.lv),
						AddExp = private_offline_award(TmpExp),

						AddExp2 = round(AddExp * MultiAward),
						TmpNewPS = lib_player:add_exp(PS, AddExp2, 0),

						HS = TmpNewPS#player_status.hotspring,

						%% 处理排行榜魅力
						HS2 = case InteractType =:= 3 of
							true ->
								%% 扣互动次数
							    	mod_daily_dict:plus_count(PS#player_status.id, 1022, 1),

								%% 重复互动同一个人，不会获得积分
								case lists:member(PlayerId, HS#status_hotspring.charm_num2) of
									true -> HS;
									_ ->
										mod_disperse:cast_to_unite(lib_hotspring, add_score, [PlayerId, 1]),
										
										%% 如果已经互动5个人，则保存起来
										case length(HS#status_hotspring.charm_num2) =:= 4 of
											true ->
												update_interact_playerlist(PS#player_status.id, HS#status_hotspring.charm_num1, HS#status_hotspring.charm_num2);
											_ ->
												skip
										end,
										HS#status_hotspring{charm_num2 = [PlayerId | HS#status_hotspring.charm_num2]}
								end;
							_ ->
								%% 扣互动次数
								mod_daily_dict:plus_count(PS#player_status.id, 1021, 1),

								%% 重复互动同一个人，不会获得积分
								case lists:member(PlayerId, HS#status_hotspring.charm_num1) of
									true -> HS;
									_ ->
										mod_disperse:cast_to_unite(lib_hotspring, add_score, [PlayerId, -1]),
										%% 如果已经互动5个人，则保存起来
										case length(HS#status_hotspring.charm_num1) =:= 4 of
											true ->
												update_interact_playerlist(PS#player_status.id, HS#status_hotspring.charm_num1, HS#status_hotspring.charm_num2);
											_ ->
												skip
										end,
										HS#status_hotspring{charm_num1 = [PlayerId | HS#status_hotspring.charm_num1]}
								end
						end,

						HS3 = HS2#status_hotspring{interacttime = util:unixtime()},
						TmpNewPS2 = TmpNewPS#player_status{hotspring = HS3},

						%% 活跃度：参与黄金沙滩并与其他玩家互动5次
						mod_active:trigger(PS#player_status.status_active, 3, 0, PS#player_status.vip#status_vip.vip_type),

						TmpNewPS2;
					_ ->
						PS
				end,

			%% 成就：沙滩捣蛋鬼，累积沙滩恶作剧N次
			mod_achieve:trigger_social(PS#player_status.achieve, PS#player_status.id, 15, 0, 1),
			%% 成就：被锤晕啦，累积沙滩被恶作剧N次
			mod_achieve:trigger_social(StatusAchieve, PlayerId, 16, 0, 1),

			{ok, NewPS};
		{error, ErrorCode} ->
			{error, ErrorCode}
	end.

%% 增加或减少魅力值
add_score(RoleId, AddScore) ->
	case ets:lookup(ets_hotspring, RoleId) of
		[Record] ->
			NewScore = 
				case Record#ets_hotspring.score + AddScore >= 0 of
					true -> Record#ets_hotspring.score + AddScore;
					_ -> 0
				end,
			ets:insert(ets_hotspring, Record#ets_hotspring{score = NewScore});
	    	_ ->
			case lib_player:get_player_low_data(RoleId) of
				[NickName, Sex, _, Career, Realm| _] ->
					Score = case AddScore < 0 of
						true -> 0;
						_ -> AddScore
					end,
					db:execute(io_lib:format(?SQL_HOTSPRING_INSERT, [RoleId, NickName, Sex, Realm, Career, Score])),
					ets:insert(ets_hotspring, #ets_hotspring{id = RoleId, nickname = NickName, sex = Sex, realm = Realm, career = Career, score = Score});
				_ ->
				    skip
			end
	end.

%% 广播
broadcast(TimeRange) ->
	NowTS = util:unixtime(),
	TodayTS = util:unixdate(),
	[{BeginAM, EndAM}, {BeginPM, EndPM}] = private_get_activity_unixtime(TimeRange),

	if
		NowTS < BeginAM - 60 ->
			skip;

		%% 开始前第1分钟
		(NowTS >= BeginAM - 60) andalso (NowTS < BeginAM) ->
			%% 设置需要广播
			mod_daily_dict:set_special_info(hotspring_send_tv, 0),
			%% 初始化第一个房间
			mod_hotspring:init_room(),
			%% 魅力值从db读入ets
			private_read_from_db_to_ets(am);

		(NowTS >= BeginAM) andalso (NowTS < EndAM) ->
			%% 传闻活动开始
			case mod_daily_dict:get_special_info(hotspring_send_tv) of
				0 ->
					lib_chat:send_TV({all},1, 2, ["ablution", 0]),
					mod_daily_dict:set_special_info(hotspring_send_tv, 1);
				_ ->
					skip
			end,
			%% 广播活动开始
			private_broadcast_begin(EndAM - NowTS),
			%% 广播沙滩内排行榜数据
			case NowTS > BeginAM + 10 of
				true ->
					private_push_inside_rank_data();
				_ ->
					skip
			end;

		%% 在上午结束时间及超过结束时间1分钟内，广播活动结束
		(NowTS >= EndAM) andalso (NowTS < EndAM + 120) ->
			%% 广播活动结束
			private_broadcast_end(TimeRange);

		%% 在上午结束后的第3分钟，清除房间数据
		(NowTS >= EndAM + 120) andalso (NowTS < EndAM + 180) ->
			%% 清除房间数据
			mod_hotspring:clean_room(am),
			%% 将魅力值数据从ets回写db
			spawn(fun() -> 
				private_write_from_ets_to_db(am)
			end);

		%% 休眠
		(NowTS >= EndAM + 180) andalso (NowTS < BeginPM - 60) ->
			skip;

		%% 开始前第1分钟
		(NowTS >= BeginPM - 60) andalso (NowTS < BeginPM) ->
			%% 设置需要广播
			mod_daily_dict:set_special_info(hotspring_send_tv, 0),
			%% 初始化第一个房间
			mod_hotspring:init_room(),
			%% 魅力值从db读入ets
			private_read_from_db_to_ets(pm);

		%% 下午活动开始1分钟
		(NowTS >= BeginPM) andalso (NowTS < EndPM) ->
			%% 传闻活动开始
			case mod_daily_dict:get_special_info(hotspring_send_tv) of
				0 ->
					lib_chat:send_TV({all},1, 2, ["ablution", 0]),
					mod_daily_dict:set_special_info(hotspring_send_tv, 1);
				_ ->
					skip
			end,
			%% 广播活动开始
			private_broadcast_begin(EndPM - NowTS),
			%% 广播沙滩内排行榜数据
			case NowTS > BeginPM + 10 of
				true ->
					private_push_inside_rank_data();
				_ ->
					skip
			end;

		%% 在下午结束时间及超过结束时间2分钟内，广播活动结束
		(NowTS >= EndPM) andalso (NowTS < EndPM + 120) ->
			%% 广播活动结束
			private_broadcast_end(TimeRange);

		%% 在下午结束后的第3分钟，清除房间数据
		(NowTS >= EndPM + 120) andalso (NowTS < EndPM + 180) ->
			%% 清除房间数据
			mod_hotspring:clean_room(pm),
			%% 将ets_hotspring回写到db
			spawn(fun() -> 
				private_write_from_ets_to_db(pm)
			end);

		%% 在下午结束时间1分钟后到0点之间，不处理	
		(NowTS >= EndPM + 180) andalso (NowTS =< TodayTS + 86400) ->
			skip;

		true ->
			skip
	end.

%% 获得下次需要处理倒计时秒数，供定时器状态机使用
timer_get_next_time(TimeRange) ->
	TodayTS = util:unixdate(),
	NowTS = util:unixtime(),
	[{BeginAM, EndAM}, {BeginPM, EndPM}] = private_get_activity_unixtime(TimeRange),

	if
	    	%% ------------------------ 上午部分 ------------------------
		NowTS < BeginAM - 60 ->
			NextTime = BeginAM - NowTS - 60;

		(NowTS >= BeginAM - 60) andalso (NowTS < BeginAM) ->
			NextTime = 60;

		(NowTS >= BeginAM) andalso (NowTS < EndAM) ->
			NextTime = 20;

		(NowTS >= EndAM) andalso (NowTS < EndAM + 180) ->
			NextTime = 60;

		(NowTS >= EndAM + 180) andalso (NowTS < BeginPM - 60) ->
			NextTime = BeginPM - NowTS - 60;

		%% ------------------------ 下午部分 ------------------------
		(NowTS >= BeginPM - 60) andalso (NowTS < BeginPM) ->
			NextTime = 60;

		(NowTS >= BeginPM) andalso (NowTS < EndPM) ->
			NextTime = 20;
		
		(NowTS >= EndPM) andalso (NowTS < EndPM + 180) ->
			NextTime = 60;

		(NowTS >= EndPM + 180) andalso (NowTS =< TodayTS + 86400) ->
			NextTime = TodayTS + 86400 - NowTS;

		true ->
			NextTime = 120
	end,
	NextTime.

%% 获取剩下互动次数
%% 返回：[恶搞剩余次数，示好剩余次数]
get_left_num(PS) ->
	[DefNum, DefNum2] = data_hotspring:get_interact_num(PS#player_status.vip#status_vip.vip_type),
	%% 恶搞
	InteractedNum = mod_daily_dict:get_count(PS#player_status.id, 1021),
	%% 示好
	InteractedNum2 = mod_daily_dict:get_count(PS#player_status.id, 1022),
	Num = case DefNum > InteractedNum of
	   true -> DefNum - InteractedNum;
	   _ -> 0
	end,
	Num2 = case DefNum2 > InteractedNum2 of
	   true -> DefNum2 - InteractedNum2;
	   _ -> 0
	end,
	[Num, Num2].

%% 当前时间是否在活动有效时间内
is_validate_time(TimeRange) ->
	case TimeRange of
		[] ->
			false;
		_ ->
			NowTS = util:unixtime(),
			[{BeginTS1, EndTS1}, {BeginTS2, EndTS2}] = private_get_activity_unixtime(TimeRange),
			if
				(NowTS < BeginTS1) orelse (NowTS > EndTS2) ->
					false;
				(NowTS > EndTS1) andalso (NowTS < BeginTS2) ->
					false;
				true ->
					true
			end
	end.

%% 插入沙滩魅力榜
insert_rank_charm(RoleId) ->
	case db:get_one(io_lib:format(?SQL_HOTSPRING_RK_SELECT, [RoleId])) of
		null -> db:execute(io_lib:format(?SQL_HOTSPRING_RK_INSERT, [RoleId]));
		_ -> skip
	end.

%% 更新玩家交互数据
update_interact_playerlist(RoleId, List1, List2) ->
	mod_hotspring:update_interact_playerlist(RoleId, List1, List2).

%% 玩家下线
offline(PS) ->
	mod_hotspring:offline(
		PS#player_status.id,
		PS#player_status.copy_id,
		PS#player_status.hotspring#status_hotspring.charm_num1,
		PS#player_status.hotspring#status_hotspring.charm_num2
	).

%% 活动开始前，将沙滩魅力值数据从DB中读入ets中
private_read_from_db_to_ets(TimeType) ->
	ets:delete_all_objects(ets_hotspring),

	case TimeType of
		%% 上午需要清理数据
		am ->
			%% 清掉之前数据
			db:execute(io_lib:format(?SQL_HOTSPRING_DELETE, []));
		pm ->
			%% 从DB读入ets
			case db:get_all(io_lib:format(?SQL_HOTSPRING_GET_ALL, [])) of
			        [] ->
					skip;
			        List ->
					%% 每1次插入100条记录
					[_, LeftList] = 
						lists:foldl(fun([Id, NickName, Sex, Realm, Career, Score], [Num, InsertList]) ->
							Rd = #ets_hotspring{id=Id, nickname=NickName, sex=Sex, realm=Realm, career=Career, score = Score, score2 = Score},
							case Num rem 100 =:= 0 of
								true ->
									ets:insert(ets_hotspring, InsertList),
									[1, [Rd]];
								_ ->
									[Num + 1, [Rd | InsertList]]
							end
						end, [0, []], List),

					%% 剩下的作最后一次插入
					case length(LeftList) > 0 of
						true ->
							ets:insert(ets_hotspring, LeftList);
						_ ->
							skip
					end
			end
	end.

%% 活动结束后，将沙滩魅力值数据从ets写入DB中
private_write_from_ets_to_db(TimeType) ->
	List = ets:tab2list(ets_hotspring),
	%% 循环ets_hotspring
	lists:map(fun(Record) -> 
		db:execute(io_lib:format(?SQL_HOTSPRING_UPDATE, [Record#ets_hotspring.score, Record#ets_hotspring.id]))
	end, List),

	case TimeType =:= am of
		true ->
			%% 将上午魅力值加到排行榜表
			lists:map(fun(Record2) ->
				case Record2#ets_hotspring.score > 0 of
					true ->
						db:execute(io_lib:format(?SQL_HOTSPRING_RK_UPDATE, [Record2#ets_hotspring.score, Record2#ets_hotspring.id]));
					_ ->
						skip
				end
			end, List);
	    	_ ->
			%% 将上午魅力值加到排行榜表
			lists:map(fun(Record2) ->
				%% 下午减去上午的魅力值，更新到表里
				case Record2#ets_hotspring.score - Record2#ets_hotspring.score2 /= 0 of
					true ->
						db:execute(io_lib:format(?SQL_HOTSPRING_RK_UPDATE, [Record2#ets_hotspring.score - Record2#ets_hotspring.score2, Record2#ets_hotspring.id]));
					_ ->
						skip
				end
			end, List)
	end,

	%% 将魅力值小于0的记录更新为0
	db:execute(io_lib:format(?SQL_HOTSPRING_RK_UPDATE2, [])),

	%% 清除ets中的数据
	ets:delete_all_objects(ets_hotspring),

	%% 刷新沙滩魅力排行榜
	mod_rank:refresh_single(?RK_CHARM_HOTSPRING).

%% 推送沙滩排行榜前10名榜单
private_push_inside_rank_data() ->
	[TimeRange, RoomList, _, _] = mod_hotspring:get_data(0),
	SceneId = get_sceneid(TimeRange),
	case length(RoomList) > 0 of
		true ->
			TableList = ets:tab2list(ets_hotspring),
			F = fun(R1, R2) ->
				R1#ets_hotspring.score > R2#ets_hotspring.score
			end,
			TableList2 = lists:sort(F, TableList),
			TableList3 = lists:sublist(TableList2, 10),
			TableList4 = lists:foldl(fun(Rd, ReturnList) -> 
				#ets_hotspring{id = Id, nickname = NickName, sex = Sex, realm = Realm, career = Career, score = Score} = Rd,
				case Score > 0 of
					true ->
						NickName2 = pt:write_string(NickName),
						[<<Id:32, NickName2/binary, Sex:8, Realm:8, Career:8, Score:32>> | ReturnList];
					_ ->
						ReturnList
				end
			end, [], TableList3),
			TableList5 = lists:reverse(TableList4),

		    	{ok, BinData} = pt_330:write(33010, TableList5),
			[lib_unite_send:send_to_scene(SceneId, CopyId, BinData) || {CopyId, _} <- RoomList];
		_ ->
			skip
	end.

%% 奖励多倍奖励
private_get_multi_award_time(PS) ->
	lib_multiple:get_multiple_by_type(1,PS#player_status.all_multiple_data).

%% 结算收益（历练声望+经验）
private_get_gain(PS, NowTime, NeedTime) ->
	%% 多倍奖励
	MultiAward = private_get_multi_award_time(PS),
	%% 可获得收益的分钟数
	Minute = NeedTime div 60,
	%% 加历练声望
	LLPT = data_hotspring:get_llpt(PS#player_status.lv, PS#player_status.vip#status_vip.vip_type),
	LLPT2 = round(LLPT * MultiAward),
	NewPS = lib_player:add_pt(llpt, PS, LLPT2 * Minute),
	%% 加经验
	TmpExp = data_hotspring:get_exp(PS#player_status.lv),
	AddExp = private_offline_award(TmpExp),
	
	AddExp2 = round(AddExp * MultiAward),
	NewPS2 = lib_player:add_exp(NewPS, AddExp2, 0),
	%% 发升经验通知
	lib_player:send_attribute_change_notify(NewPS2, 2),

	NewHS = PS#player_status.hotspring#status_hotspring{
		lasttime = NowTime
	},
	NewPS2#player_status{hotspring = NewHS}.

%% 判断玩家自己能否发起互动
private_is_interactable(PS, PlayerId) ->
	HS = PS#player_status.hotspring,
	case HS#status_hotspring.timerange of
		%% 没有进入场景就发起协议，防刷
		undefined -> {error, 2};
		_ ->
			case PS#player_status.id =:= PlayerId of
				%% 被互动的人是自己
				true -> {error, 2};
				_ ->
					case is_validate_time(HS#status_hotspring.timerange) of
						%% 不在活动时间内
						false -> {error, 2};
						_ ->
							SceneId = get_sceneid(HS#status_hotspring.timerange),
							case PS#player_status.scene =/= SceneId of
								%% 不在沙滩场景中
								true -> {error, 3};
								_ ->
									case lib_player:get_player_info(PlayerId, hotspring_data) of
										%% 被互动的玩家不在线或不存在
										false -> {error, 8};
										[StatusAchieve, StatusScene, StatusCopyId] ->
											case PS#player_status.scene =/= StatusScene orelse PS#player_status.copy_id =/= StatusCopyId of
												%% 被互动玩家不在场景，或在场景但不同房间
												true -> {error, 8};
												_ ->	{ok, StatusAchieve}
											end
									end
							end
					end
			end
	end.

%% 获得活动时间戳
private_get_activity_unixtime(TimeRange) ->
	TodayTS = util:unixdate(),
	[{{BeginH1, BeginM1}, {EndH1, EndM1}}, {{BeginH2, BeginM2}, {EndH2, EndM2}}] = TimeRange,
	BeginTS1 = TodayTS + BeginH1 * 3600 + BeginM1 * 60,
	EndTS1 = TodayTS + EndH1 * 3600 + EndM1 * 60,
	BeginTS2 = TodayTS + BeginH2 * 3600 + BeginM2 * 60,
	EndTS2 = TodayTS + EndH2 * 3600 + EndM2 * 60,
	%% [{上午开始时间戳，上午结束时间戳}, {下午开始时间戳，下午结束时间戳}]
	[{BeginTS1, EndTS1}, {BeginTS2, EndTS2}].

%% 广播活动开始
%% 参数：Second	用到倒计时秒数
private_broadcast_begin(Second) ->
	{ok, BinData} = pt_330:write(33020, Second),
	lib_unite_send:send_to_all(data_hotspring:get_require_lv(), 100, BinData).

%% 广播活动结束
private_broadcast_end(TimeRange) ->
	{ok, BinData} = pt_330:write(33021, 1),
	lib_unite_send:send_to_all(data_hotspring:get_require_lv(), 100, BinData),

	%% 把人从场景中拉出去
	SceneId = get_sceneid(TimeRange),
	mod_hotspring:pull_out_of(SceneId).

%% 从定时器获得活动开始时间范围
%% 返回：[活动时间段TimeRange, 房间列表RoomList, 恶搞玩家列表PlayerList1, 示好玩家列表PlayerList2]
private_get_data_from_timer(RoleId) ->
	mod_hotspring:get_data(RoleId).

%% 检查指定房间人数是否满了
private_is_room_full(RoomId, RoomList) ->	
	private_get_room_num(RoomId, RoomList) >= data_hotspring:get_room_limit().

%% 取得指定房间人数
private_get_room_num(_RoomId, []) ->
	%% 找不到指定房间
	10000;
private_get_room_num(RoomId, [{Id, Num} | T]) ->
	case RoomId =:= Id of
		true -> Num;
		_ -> private_get_room_num(RoomId, T)
	end.

%% 下线经验奖励
private_offline_award(Award) ->
	case lib_off_line:activity_time() of
		true -> round(Award * (1 + 0.2));
		_ -> Award
	end.
