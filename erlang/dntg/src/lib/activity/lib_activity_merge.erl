%%%--------------------------------------
%%% @Module  : lib_activity_merge
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.9.24
%%% @Description: 合服活动
%%%--------------------------------------

-module(lib_activity_merge).
-include("server.hrl").
-include("gift.hrl").
-include("merge.hrl").
-include("activity.hrl").
-include("sql_guild.hrl").
-include("rank.hrl").
-include("fame.hrl").
-include("designation.hrl").
-compile(export_all).

%% [游戏线]设置合服活动开启
set_time(Time) ->
	%% 判断是否已经在管理后台点击过合服活动，避免重复点击
	case db:get_one(io_lib:format(?sql_merge_stat_select, [])) of
		null ->
			private_start_activity(Time);
		LastTime ->
			case LastTime == Time of
				true ->
					skip;
				_ ->
					private_start_activity(Time)
			end
	end.

%% 取消合服活动
cancel_merge() ->
	%% 清除合服统计录
	db:execute(io_lib:format(?sql_merge_stat_delete, [])),
	%% 清除合服名人堂记录及称号
	RemoveFameList = [12601,12501,12401,12301,12201,12001,11901,11801,11701,11601,11501],
	lists:foreach(fun(FameId) -> 
		BaseFame = data_fame:get_fame(FameId),
		db:execute(io_lib:format(?SQL_FAME_DELETE2, [FameId])),
		db:execute(io_lib:format(?SQL_DESIGN_DELETE2, [BaseFame#base_fame.design_id])),
		db:execute(io_lib:format(?SQL_DESIGN_DELETE_STAT, [BaseFame#base_fame.design_id]))
	end, RemoveFameList),
%% 	Sql1 = <<"DELETE FROM fame_vote">>,
%% 	Sql2 = <<"DELETE FROM game_var">>,
%% 	db:execute(io_lib:format(Sql1, [])),
%% 	db:execute(io_lib:format(Sql2, [])),
	%% 存入缓存
	mod_daily_dict:set_special_info(lib_activity_merge_time, 0),
	%% 广播全服出现合服活动图标
	{ok, BinData} = pt_314:write(31480, [104, 1, 1]),
	lib_server_send:send_to_all(BinData),
	%% 刷新名人堂
	mod_disperse:cast_to_unite(mod_rank, refresh_single, [?RK_FAME]).

%% 获取当时设置合服活动开始时间戳
get_activity_time() ->
	case mod_daily_dict:get_special_info(lib_activity_merge_time) of
		undefined ->
			case db:get_one(io_lib:format(?sql_merge_stat_select, [])) of
				null ->
					mod_daily_dict:set_special_info(lib_activity_merge_time, 0),
					0;
				Field ->
					mod_daily_dict:set_special_info(lib_activity_merge_time, Field),
					Field
			end;
		Time ->
			Time
	end.

%% 获取合服活动开始当天0点时间戳
get_activity_day() ->
	case get_activity_time() of
		0 -> 0;
		Time -> util:unixdate(Time)
	end.

%% 取得现在是合服第几天
get_merge_day() ->
    Now = util:unixtime(),
    MergeTime = get_activity_time(),
    Day = (Now - MergeTime) div 86400,
    Day + 1.

%% [公共线]豪华礼包大回馈
%% 给全服等级大于40的玩家发邮件礼包
%% TODO : 缺礼包id
send_mail() ->
	%% 如果该活动没执行过，则可以执行
	case db:get_one(io_lib:format(?sql_merge_stat_select1, [activity1])) of
		0 ->
			db:execute(io_lib:format(?sql_merge_stat_update, [activity1, 1])),
			lib_mail:send_sys_mail_to_all(
				data_activity_text:get_merge_login_title(),
				data_activity_text:get_merge_login_content(),
				private_get_goodsid_by_gift(data_merge:get_mail_gift()),
				2, 1, 0, 0, 0, 0, 40, 0
			);
		_ ->
			skip
	end.

%% 充值活动：更新充值总额
%% 返回：最新合服充值总额
update_recharge(PS, RechargeTotal) ->
	case RechargeTotal > 0 of
		true ->
		    %% 判断是否合服后七天内充值
			NowTime = util:unixtime(),
			%% 合服时间戳
			MergeTime = PS#player_status.mergetime,
			%% 合服当天0点时间戳
			MergeDay = util:unixdate(MergeTime),
		    case NowTime >= MergeTime andalso NowTime =< MergeDay + data_merge:get_recharge_day() * 86400 of
		        true ->
		            db:execute(io_lib:format(?sql_merge_recharge_update, [RechargeTotal, PS#player_status.id]));
		        _ ->
		            skip
		    end;
		_ ->
			skip
	end.

%% 处理玩家战力榜/宠物战力榜
do_rank_power(RankType) ->
	%% 在合服活动第5天后，发放奖励
	NowTime = util:unixtime(),
	DayTime = get_activity_day(),
	AfterDay = data_merge:get_rank_day(),
	case NowTime >= DayTime + AfterDay * 86400 andalso NowTime < DayTime + (AfterDay + 1) * 86400 of
		true ->
			case lib_rank:pp_get_rank(RankType) of
				[] ->
					skip;
				List ->
					private_rank_power(RankType, List)
			end;
		_ ->
			skip
	end.

%% 处理竞技场每日上榜
do_rank_anera(List, MergeTime) ->
	NowTime = util:unixtime(),
    case NowTime >= MergeTime andalso NowTime =< util:unixdate(MergeTime) + data_merge:get_rank_day() * 86400 of
        true ->
			private_rank_power(?RK_ARENA_DAY, List);
		_ ->
			skip
	end.

%% 帮派战奖励
%% 在活动期间，帮派战结束时发送奖励
guild_award(RankList) ->
	%% 活动开启后的5天内才有效
	NowTime = util:unixtime(),
    case NowTime >= get_activity_time() andalso NowTime =< get_activity_day() + data_merge:get_guild_day() * 86400 of
        true ->
            [OneList, SecondList, ThirdList, _] = 
                lists:foldl(fun(Id, [TmpOneList, TmpSecondList, TmpThirdList, Position]) ->
                    if
                        Position < 2 ->
                            [[Id | TmpOneList], TmpSecondList, TmpThirdList, Position+1];
                        Position >= 2 andalso Position =< 5 ->
                            [TmpOneList, [Id | TmpSecondList], TmpThirdList, Position+1];
                        Position >= 6 andalso Position =< 10 ->
                            [TmpOneList, TmpSecondList, [Id | TmpThirdList], Position+1];
                        true ->
                            [TmpOneList, TmpSecondList, TmpThirdList, Position+1]
                    end
            end, [[], [], [], 1], RankList),
            %% 第一名奖励
            private_send_guild_member(OneList, 1),

            %% 第二至五名奖励
            private_send_guild_member(SecondList, 2),

            %% 第六至十名奖励
            private_send_guild_member(ThirdList, 3);
        _ ->
            skip
    end.

%% 获取礼包领取状态
%% 返回：0未领取，1已经领取
get_gift_fetch_status(PS, GiftId) ->
	RoleId = PS#player_status.id,
	CacheKey = lists:concat(["merge_recharge_", RoleId, "_", GiftId]),
	Result = mod_daily:get_special_info(PS#player_status.dailypid, CacheKey),
	case Result of
		undefined ->
			All = db:get_all(io_lib:format(?sql_merge_recharge_gift_select, [RoleId])),
			case lists:member([GiftId], All) of
				true ->
					mod_daily:set_special_info(PS#player_status.dailypid, CacheKey, 1),
					1;
				_ ->
					mod_daily:set_special_info(PS#player_status.dailypid, CacheKey, 0),
					0
			end;
		Data ->
			Data
	end.

%% 获取合服充值总额
get_recharge_total(RoleId) ->
	case db:get_one(io_lib:format(?sql_merge_recharge_select, [RoleId])) of
		null -> 0;
		Total -> Total
	end.

%% 打开合服充值礼包面板需要的数据
get_recharge_gift_data(PS) ->
	MergeDay = util:unixdate(PS#player_status.mergetime),
	NowTime = util:unixtime(),
	case NowTime > MergeDay + data_merge:get_recharge_day() * 86400 of
		true ->
			[];
		_ ->
			%% 判断图标是否该出现
			case lib_activity:get_finish_stat(PS, ?ACTIVITY_FINISH_MERGE_RECHARGE) of
				[0, _] ->
					%% 充值总额
					Recharge = get_recharge_total(PS#player_status.id),
					%% 活动剩余时间
					LeftSecond = MergeDay + data_merge:get_recharge_day() * 86400 - NowTime,
					%% 礼包及需要的元宝
					List = lists:map(fun([GiftId, RequireGold]) -> 
						FetchStatus = get_gift_fetch_status(PS, GiftId),
						<<GiftId:32, FetchStatus:8, RequireGold:32>>
					end, data_merge:get_recharge_gift_and_gold()),

					[Recharge, LeftSecond, List];
				_ ->
					[]
			end
	end.

%% [合服充值礼包] 领取奖励
fetch_recharge_gift(PS, GiftId) ->
	case PS#player_status.mergetime of
		0 -> {error, 999};
		_ ->
			MergeDay = util:unixdate(PS#player_status.mergetime),
			NowTime = util:unixtime(),
			case NowTime > MergeDay + data_merge:get_recharge_day() * 86400 of
				true -> {error, 103};
				_ ->
					%% 礼包及需要的元宝
					ResultList = lists:filter(fun([GId, _]) -> 
						GId =:= GiftId
					end, data_merge:get_recharge_gift_and_gold()),
					case ResultList of
						[[TargetId, TargetRecharge]] ->
							case TargetId of
								0 -> {error, 999};
								_ ->
									case get_gift_fetch_status(PS, GiftId) of
										1 -> {error, 2};
										_ ->
											%% 充值总额
											Recharge = get_recharge_total(PS#player_status.id),
											case Recharge < TargetRecharge of
												true -> {error, 3};
												_ ->
													case private_fetch_recharge_gift(PS, GiftId) of
														{ok} -> {ok};
														{error, Err} -> {error, Err}
													end
											end
									end
							end;
						_ ->
							{error, 999}
					end
			end
	end.

private_fetch_recharge_gift(PS, GiftId) ->
	G = PS#player_status.goods,
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
		{ok, [ok, _NewPS]} ->
			%% 更新礼包为领取
			db:execute(io_lib:format(?sql_merge_recharge_gift_insert, [PS#player_status.id, GiftId, 1])),
			CacheKey = lists:concat(["merge_recharge_", PS#player_status.id, "_", GiftId]),
			mod_daily:set_special_info(PS#player_status.dailypid, CacheKey, 1),

			%% 如果已经领取完所有礼包，则图标下次登录不再出现
			Result = lists:all(fun([GId, _]) -> 
				GiftKey = lists:concat(["merge_recharge_", PS#player_status.id, "_", GId]),
				case mod_daily:get_special_info(PS#player_status.dailypid, GiftKey) of
					1 -> true;
					_ -> false
				end
			end, data_merge:get_recharge_gift_and_gold()),

			case Result of
				true ->
					lib_activity:finish_activity(PS, ?ACTIVITY_FINISH_MERGE_RECHARGE);
				_ ->
					skip
			end,
			{ok};
		{ok, [error, ErrorCode]} ->
			{error, ErrorCode}
	end.

%% 开启合服活动
private_start_activity(Time) ->
	%% 插入合服活动统计记录
	db:execute(io_lib:format(?sql_merge_stat_insert, [Time, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])),
	spawn(fun() -> 
		%% 删除上一次合服充值活动的礼包领取记录
		db:execute(io_lib:format(?sql_merge_recharge_gift_delete, [])),
		%% 清零上一次合服充值总额
		db:execute(io_lib:format(?sql_merge_recharge_update2, [])),
		%% 存入缓存
		mod_daily_dict:set_special_info(lib_activity_merge_time, Time),
		%% 广播全服出现合服活动图标
		{ok, BinData} = pt_314:write(31480, [104, 0, 1]),
		lib_server_send:send_to_all(BinData)
	end),
	spawn(fun() -> 
		%% 刷新名人堂
		mod_disperse:cast_to_unite(mod_rank, refresh_single, [?RK_FAME])	  
	end),
	spawn(fun() -> 
		%% 发全服40级邮件礼包
		mod_disperse:cast_to_unite(lib_activity_merge, send_mail, [])		  
	end).

%% 获取帮派帮主和成员数据
private_send_guild_member(GuildList, Position) ->
    F = fun(GuildId) ->
        case db:get_all(io_lib:format(?SQL_GUILD_SELECT_ALL_MEMBER_ID, [GuildId])) of
            [] ->
                skip;
            List ->
                Title = data_merge_text:get_rank_title(4, Position),
                Content = data_merge_text:get_rank_content(4, Position),

				case Position == 1 of
					%% 第1名，帮主跟帮众的奖励不一样
					true ->
						%% 给帮主发奖励
		                MasterIds = [MasterId || [MasterId, MasterPos] <- List, MasterPos =:=1],
		                MasterId = hd(MasterIds),
		                case is_integer(MasterId) of
		                    true ->
		                        private_send_gift_mail(
                                    [MasterId],
                                    Title,
                                    Content,
                                    private_get_goodsid_by_gift(data_merge:get_guild_gift(1, 1))
                                );
		                    _ ->
		                        skip
		                end,
		                %% 给帮众发奖励
		                MemberIds = [MemberId || [MemberId, MemberPos] <- List, MemberPos =/=1],
		                private_send_gift_mail(
                            MemberIds,
                            Title,
                            Content,
                            private_get_goodsid_by_gift(data_merge:get_guild_gift(1, 2))
                        );
					
					%% 其他名次，帮主跟帮众奖励一样
					_ ->
		                MemberIds = [MemberId || [MemberId, _MemberPos] <- List],
		                private_send_gift_mail(
                            MemberIds,
                            Title,
                            Content,
                            private_get_goodsid_by_gift(data_merge:get_guild_gift(Position, 0))
                        )
				end
        end
    end,
    lists:map(F, GuildList).

%% 排行榜相关奖励
%% RankType : 榜类型，1玩家战力榜，2宠物战力榜，3竞技场每日上榜
private_rank_power(RankType, RankList) ->
    %% 排行榜记录一定是玩家id作为第一位数据
    [OneList, SecondList, ThirdList, _] = 
        lists:foldl(fun([Id | _], [TmpOneList, TmpSecondList, TmpThirdList, Position]) ->
            if
                Position < 2 ->
                    [[Id | TmpOneList], TmpSecondList, TmpThirdList, Position+1];
                Position >= 2 andalso Position =< 5 ->
                    [TmpOneList, [Id | TmpSecondList], TmpThirdList, Position+1];
                Position >= 6 andalso Position =< 10 ->
                    [TmpOneList, TmpSecondList, [Id | TmpThirdList], Position+1];
                true ->
                    [TmpOneList, TmpSecondList, TmpThirdList, Position+1]
            end
    end, [[], [], [], 1], RankList),
    %% 第一名奖励
    private_send_gift_mail(
        OneList,
        data_merge_text:get_rank_title(RankType, 1),
        data_merge_text:get_rank_content(RankType, 1),
        private_get_goodsid_by_gift(data_merge:get_rank_gift(RankType, 1))
    ),

    %% 第二至五名奖励
    private_send_gift_mail(
        SecondList,
        data_merge_text:get_rank_title(RankType, 2),
        data_merge_text:get_rank_content(RankType, 2),
        private_get_goodsid_by_gift(data_merge:get_rank_gift(RankType, 2))
    ),

    %% 第六至十名奖励
    private_send_gift_mail(
        ThirdList,
        data_merge_text:get_rank_title(RankType, 3),
        data_merge_text:get_rank_content(RankType, 3),
        private_get_goodsid_by_gift(data_merge:get_rank_gift(RankType, 3))
    ).

%% 发送礼包邮件
private_send_gift_mail(List, Title, Content, GoodsTypeId) ->
    case List of
        [] -> skip;
        _ -> lib_mail:send_sys_mail_bg(List, Title, Content, GoodsTypeId, 2, 0, 0, 1, 0, 0, 0, 0)
    end.

%% 通过礼包id取得物品id
private_get_goodsid_by_gift(GiftId) ->
	case data_gift:get(GiftId) of
		[] -> 0;
		Gift -> Gift#ets_gift.goods_id
	end.
