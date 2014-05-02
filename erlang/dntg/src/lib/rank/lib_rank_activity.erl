%%%--------------------------------------
%%% @Module  : lib_rank_activity
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.8.14
%%% @Description :  排行榜活动相关
%%%--------------------------------------

-module(lib_rank_activity).
-include("gift.hrl").
-include("rank.hrl").
-include("sql_rank_activity.hrl").
-include("sql_guild.hrl").
-compile(export_all).

%% 插入开服7天统计记录
insert_handle_stat() ->
	db:execute(io_lib:format(?SQL_RKACT_HANDLE_INSERT, [])).

%% 更新开服7天统计
update_handled(Field) ->
	Fileds = [player_level, player_power, player_meridian, player_achieve, pet_level, pet_power, dungeon_nine, arena_fighting, guild_fighting],
	case lists:member(Field, Fileds) of
		true ->
			case get_handle_stat() of
				[] ->
					insert_handle_stat();
				_ ->
					skip
			end,
			db:execute(io_lib:format(?SQL_RKACT_HANDLE_UPDATE, [Field]));
		_ ->
			skip
	end.

%% 获取开服7天处理统计记录
get_handle_stat() -> 
	db:get_row(io_lib:format(?SQL_RKACT_HANDLE_SELECT, [])).

%% 处理玩家等级榜前10
get_player_level_top() ->
	case db:get_all(io_lib:format(?SQL_RKACT_PERSON_LV, [])) of
		[] ->
			skip;
		List ->
            %% 更新为已经处理完
			update_handled(player_level),

			Title = data_activity_text:seven_day_player_level(title),
			Content = data_activity_text:seven_day_player_level(content),

			[_, One2, Two2, Three2, Four2, Five2] = 
			lists:foldl(fun([Id], [Num, One, Two, Three, Four, Five]) -> 
				if
					Num =:= 1 -> [Num + 1, [Id | One], Two, Three, Four, Five];
					Num =:= 2 -> [Num + 1, One, [Id | Two], Three, Four, Five];
					Num =:= 3 -> [Num + 1, One, Two, [Id | Three], Four, Five];
					Num < 7 -> [Num + 1, One, Two, Three, [Id | Four], Five];
					Num < 11 -> [Num + 1, One, Two, Three, Four, [Id | Five]];
					true ->	[Num + 1, One, Two, Three, Four, Five] 
				end
			end, [1, [], [], [], [], []], List),
			%% 第1名
			private_send_gold_mail(One2, Title, Content, 1000),
			%% 第2名
			private_send_gold_mail(Two2, Title, Content, 800),
			%% 第3名
			private_send_gold_mail(Three2, Title, Content, 500),
			%% 第4~6名
			private_send_gold_mail(Four2, Title, Content, 300),
			%% 第7~10名
			private_send_gold_mail(Five2, Title, Content, 100)
	end.

%% 处理玩家战力榜前10
get_player_power_top() ->
	case db:get_all(io_lib:format(?SQL_RKACT_PERSON_POWER, [])) of
		[] ->
			skip;
		List ->
            %% 更新为已经处理完
			update_handled(player_power),

			Title = data_activity_text:seven_day_player_power(title),
			Content = data_activity_text:seven_day_player_power(content),

			[_, One2, Two2, Three2, Four2, Five2] = 
			lists:foldl(fun([Id], [Num, One, Two, Three, Four, Five]) -> 
				if
					Num =:= 1 -> [Num + 1, [Id | One], Two, Three, Four, Five];
					Num =:= 2 -> [Num + 1, One, [Id | Two], Three, Four, Five];
					Num =:= 3 -> [Num + 1, One, Two, [Id | Three], Four, Five];
					Num < 7 -> [Num + 1, One, Two, Three, [Id | Four], Five];
					Num < 11 -> [Num + 1, One, Two, Three, Four, [Id | Five]];
					true ->	[Num + 1, One, Two, Three, Four, Five] 
				end
			end, [1, [], [], [], [], []], List),
			%% 第1名
			private_send_gold_mail(One2, Title, Content, 1000),
			%% 第2名
			private_send_gold_mail(Two2, Title, Content, 800),
			%% 第3名
			private_send_gold_mail(Three2, Title, Content, 500),
			%% 第4~6名
			private_send_gold_mail(Four2, Title, Content, 300),
			%% 第7~10名
			private_send_gold_mail(Five2, Title, Content, 100)
	end.

%% 处理玩家元神榜前10
get_player_meridian_top() ->
	case db:get_all(io_lib:format(?SQL_RKACT_PERSON_MERIDIAN, [])) of
		[] ->
			skip;
		List ->
            %% 更新为已经处理完
			update_handled(player_meridian),

			Title = data_activity_text:seven_day_player_meridian(title),
			Content = data_activity_text:seven_day_player_meridian(content),
			GoodsTypeId1 = private_get_goodsid_by_gift(532401),
			
			[_, One2, Two2, Three2, Four2, Five2] = 
			lists:foldl(fun([Id], [Num, One, Two, Three, Four, Five]) -> 
				if
					Num =:= 1 -> [Num + 1, [[Id] | One], Two, Three, Four, Five];
					Num =:= 2 -> [Num + 1, One, [[Id] | Two], Three, Four, Five];
					Num =:= 3 -> [Num + 1, One, Two, [[Id] | Three], Four, Five];
					Num < 7 -> [Num + 1, One, Two, Three, [[Id] | Four], Five];
					Num < 11 -> [Num + 1, One, Two, Three, Four, [[Id] | Five]];
					true ->	[Num + 1, One, Two, Three, Four, Five] 
				end
			end, [1, [], [], [], [], []], List),

			%% 第1名
			private_send_gift_mail(One2, Title, Content, GoodsTypeId1),
			%% 第2名
			GoodsTypeId2 = private_get_goodsid_by_gift(532402),
			private_send_gift_mail(Two2, Title, Content, GoodsTypeId2),
			%% 第3名
			GoodsTypeId3 = private_get_goodsid_by_gift(532403),
			private_send_gift_mail(Three2, Title, Content, GoodsTypeId3),
			%% 第4~6名
			GoodsTypeId4 = private_get_goodsid_by_gift(532404),
			private_send_gift_mail(Four2, Title, Content, GoodsTypeId4),
			%% 第7~10名
			GoodsTypeId5 = private_get_goodsid_by_gift(532405),
			private_send_gift_mail(Five2, Title, Content, GoodsTypeId5)
	end.

%% 处理玩家成就榜前3
get_player_achieve_top() ->
	case db:get_all(io_lib:format(?SQL_RKACT_PERSON_ACHIEVE, [])) of
		[] ->
			skip;
		List ->
            %% 更新为已经处理完
			update_handled(player_achieve),

			Title = data_activity_text:seven_day_player_achieve(title),
			Content = data_activity_text:seven_day_player_achieve(content),

			[_, One2, Two2, Three2] = 
			lists:foldl(fun([Id], [Num, One, Two, Three]) -> 
				if
					Num =:= 1 -> [Num + 1, [[Id] | One], Two, Three];
					Num =:= 2 -> [Num + 1, One, [[Id] | Two], Three];
					Num =:= 3 -> [Num + 1, One, Two, [[Id] | Three]];
					true ->	[Num + 1, One, Two, Three] 
				end
			end, [1, [], [], []], List),
			
			%% 第1名
			GoodsTypeId1 = private_get_goodsid_by_gift(532431),
			private_send_gift_mail(One2, Title, Content, GoodsTypeId1),
			%% 第2名
			GoodsTypeId2 = private_get_goodsid_by_gift(532432),
			private_send_gift_mail(Two2, Title, Content, GoodsTypeId2),
			%% 第3名
			GoodsTypeId3 = private_get_goodsid_by_gift(532433),
			private_send_gift_mail(Three2, Title, Content, GoodsTypeId3)
	end.

%% 处理宠物等级榜前10
get_pet_level_top() ->
	case db:get_all(io_lib:format(?SQL_RKACT_PET_LEVEL, [])) of
		[] ->
			skip;
		List ->
            %% 更新为已经处理完
			update_handled(pet_level),

			Title = data_activity_text:seven_day_pet_level(title),
			Content = data_activity_text:seven_day_pet_level(content),
			
			[_, One2, Two2, Three2, Four2, Five2] = 
			lists:foldl(fun([Id], [Num, One, Two, Three, Four, Five]) -> 
				if
					Num =:= 1 -> [Num + 1, [[Id] | One], Two, Three, Four, Five];
					Num =:= 2 -> [Num + 1, One, [[Id] | Two], Three, Four, Five];
					Num =:= 3 -> [Num + 1, One, Two, [[Id] | Three], Four, Five];
					Num < 7 -> [Num + 1, One, Two, Three, [[Id] | Four], Five];
					Num < 11 -> [Num + 1, One, Two, Three, Four, [[Id] | Five]];
					true ->	[Num + 1, One, Two, Three, Four, Five] 
				end
			end, [1, [], [], [], [], []], List),
			
			%% 第1名
			GoodsTypeId1 = private_get_goodsid_by_gift(532406),
			private_send_gift_mail(One2, Title, Content, GoodsTypeId1),
			%% 第2名
			GoodsTypeId2 = private_get_goodsid_by_gift(532407),
			private_send_gift_mail(Two2, Title, Content, GoodsTypeId2),
			%% 第3名
			GoodsTypeId3 = private_get_goodsid_by_gift(532408),
			private_send_gift_mail(Three2, Title, Content, GoodsTypeId3),
			%% 第4~6名
			GoodsTypeId4 = private_get_goodsid_by_gift(532409),
			private_send_gift_mail(Four2, Title, Content, GoodsTypeId4),
			%% 第7~10名
			GoodsTypeId5 = private_get_goodsid_by_gift(532410),
			private_send_gift_mail(Five2, Title, Content, GoodsTypeId5)
	end.

%% 处理宠物战力榜前10
get_pet_power_top() ->
	case db:get_all(io_lib:format(?SQL_RKACT_PET_FIGHT, [])) of
		[] ->
			skip;
		List ->
            %% 更新为已经处理完
			update_handled(pet_power),

			Title = data_activity_text:seven_day_pet_power(title),
			Content = data_activity_text:seven_day_pet_power(content),
			
			[_, One2, Two2, Three2, Four2, Five2] = 
			lists:foldl(fun([Id], [Num, One, Two, Three, Four, Five]) -> 
				if
					Num =:= 1 -> [Num + 1, [[Id] | One], Two, Three, Four, Five];
					Num =:= 2 -> [Num + 1, One, [[Id] | Two], Three, Four, Five];
					Num =:= 3 -> [Num + 1, One, Two, [[Id] | Three], Four, Five];
					Num < 7 -> [Num + 1, One, Two, Three, [[Id] | Four], Five];
					Num < 11 -> [Num + 1, One, Two, Three, Four, [[Id] | Five]];
					true ->	[Num + 1, One, Two, Three, Four, Five] 
				end
			end, [1, [], [], [], [], []], List),

			%% 第1名
			GoodsTypeId1 = private_get_goodsid_by_gift(532411),
			private_send_gift_mail(One2, Title, Content, GoodsTypeId1),
			%% 第2名
			GoodsTypeId2 = private_get_goodsid_by_gift(532412),
			private_send_gift_mail(Two2, Title, Content, GoodsTypeId2),
			%% 第3名
			GoodsTypeId3 = private_get_goodsid_by_gift(532413),
			private_send_gift_mail(Three2, Title, Content, GoodsTypeId3),
			%% 第4~6名
			GoodsTypeId4 = private_get_goodsid_by_gift(532414),
			private_send_gift_mail(Four2, Title, Content, GoodsTypeId4),
			%% 第7~10名
			GoodsTypeId5 = private_get_goodsid_by_gift(532415),
			private_send_gift_mail(Five2, Title, Content, GoodsTypeId5)
	end.

%% [公共线]开服七天内，家族达到4级，即为帮主及帮众发奖励邮件
get_guild_award(GuildId) ->
	case util:check_open_day(7) of
		true ->
			case db:get_all(io_lib:format(?SQL_GUILD_SELECT_ALL_MEMBER_ID, [GuildId])) of
				[] ->
					skip;
				List ->
					Title = data_activity_text:seven_day_guild_level(title),
					Content = data_activity_text:seven_day_guild_level(content),
					%% 给帮主发奖励
					MasterIds = [MasterId || [MasterId, MasterPos] <- List, MasterPos =:=1],
					MasterId = hd(MasterIds),
					case is_integer(MasterId) of
						true ->
							MasterGoodsTypeId = private_get_goodsid_by_gift(532436),
							private_send_gift_mail([[MasterId]], Title, Content, MasterGoodsTypeId);
						_ ->
							skip
					end,
					%% 给帮众发奖励
					MemberGoodsTypeId = private_get_goodsid_by_gift(532437),
					MemberIds = [[MemberId] || [MemberId, MemberPos] <- List, MemberPos =/=1],
					private_send_gift_mail(MemberIds, Title, Content, MemberGoodsTypeId)
			end;
		_ ->
			skip
	end.

%% 开服七天内，九重天霸主发奖励
get_ninesky_award() ->
	case lib_tower_dungeon:get_master_player_id_list(1) of
		[] ->
			skip;
		List ->
            %% 更新为已经处理完
			update_handled(dungeon_nine),

			%% 取最高的四层来发奖励
			SortFun = fun([Level1, _, _], [Level2, _, _]) ->
				Level1 >= Level2 
			end,
			LevelList = lists:sort(SortFun, List),

			Title = data_activity_text:seven_day_ninesky_dungeon(title),
			Content = data_activity_text:seven_day_ninesky_dungeon(content),
			
			lists:foldl(fun([_Level, RoleIds, _], Position) -> 
				if
					Position == 1 ->
						NewIds = [[TmpId] || TmpId <- RoleIds],
						private_send_gift_mail(NewIds, Title, Content, private_get_goodsid_by_gift(532426));
					Position == 2 ->
						NewIds = [[TmpId] || TmpId <- RoleIds],
						private_send_gift_mail(NewIds, Title, Content, private_get_goodsid_by_gift(532427));
					Position == 3 ->
						NewIds = [[TmpId] || TmpId <- RoleIds],
						private_send_gift_mail(NewIds, Title, Content, private_get_goodsid_by_gift(532428));
					Position == 4 ->
						NewIds = [[TmpId] || TmpId <- RoleIds],
						private_send_gift_mail(NewIds, Title, Content, private_get_goodsid_by_gift(532429));
					true ->
						skip
				end,
				Position + 1
			end, 1, LevelList)
	end.

%% 最强竞技战
get_arena_fighting_award() ->
	case db:get_all(io_lib:format(?SQL_RKACT_ACTIVITY_SELECT, [1])) of
		[] ->
			skip;
		List ->
            %% 更新为已经处理完
			update_handled(arena_fighting),

			Title = data_activity_text:seven_day_arena_fighting(title),
			Content = data_activity_text:seven_day_arena_fighting(content),
			F = fun([_, Field], Rank) ->
				case util:to_term(Field) of
					RoleIds when is_list(RoleIds) ->
						private_send_arena_award(RoleIds, Title, Content),
						Rank;
					_ ->
						Rank
				end
			end,
			lists:foldl(F, 1, List)
	end.

%% 最强帮派战
get_guild_fighting_award() ->
	case db:get_all(io_lib:format(?SQL_RKACT_ACTIVITY_SELECT, [2])) of
		[] ->
			skip;
		List ->
            %% 更新为已经处理完
			update_handled(guild_fighting),

			Title = data_activity_text:seven_day_guild_fighting(title),
			Content = data_activity_text:seven_day_guild_fighting(content),
			F = fun([_, Field], Rank) ->
				case util:to_term(Field) of
					RoleIds when is_list(RoleIds) ->
						private_send_guild_award(RoleIds, Title, Content),
						Rank;
					_ ->
						Rank
				end
			end,
			lists:foldl(F, 1, List)
	end.

%% 竞技场结束时，插入排前三的玩家
%% List : 如[121, 12, 34]或[121, 34]
insert_arena_stat(List) ->
	NewList = [RoleId || RoleId <- List, RoleId > 0],
	case NewList of
		[] ->
			skip;
		_ ->
			case db:get_one(io_lib:format(?SQL_RKACT_ACTIVITY_COUNT, [1])) of
				Num when is_integer(Num) ->
					case Num >= 3 of
						true -> 
							skip;
						_ ->
							Content = util:term_to_string(NewList),
							db:execute(io_lib:format(?SQL_RKACT_ACTIVITY_INSERT, [1, Content]))
					end;
				_ ->
					Content = util:term_to_string(NewList),
					db:execute(io_lib:format(?SQL_RKACT_ACTIVITY_INSERT, [1, Content]))
			end
	end.

%% 帮派战结束时，插入排前三的帮派帮主的id
%% List : 如[121, 12, 34]或[121, 34]，这里的数字为帮派id，需要再查一次表查出帮主id
insert_guild_stat(List) ->
	GuildIds = [GuildId || GuildId <- List, GuildId > 0],
	NewList = lists:map(fun(P) ->
		db:get_one(io_lib:format(?SQL_GUILD_SELECT_MASTERID, [P]))
	end, GuildIds),
	case NewList of
		[] ->
			skip;
		_ ->
			case db:get_one(io_lib:format(?SQL_RKACT_ACTIVITY_COUNT, [2])) of
				Num when is_integer(Num) ->
					case Num >= 3 of
						true -> 
							skip;
						_ ->
							Content = util:term_to_string(NewList),
							db:execute(io_lib:format(?SQL_RKACT_ACTIVITY_INSERT, [2, Content]))
					end;
				_ ->
					Content = util:term_to_string(NewList),
					db:execute(io_lib:format(?SQL_RKACT_ACTIVITY_INSERT, [2, Content]))
			end
	end.

%% 设置开服7天奖励已经发送
set_seven_day_award_already_sended(Field) ->
	Fileds = [player_level, player_power, player_meridian, player_achieve, pet_level, pet_power, dungeon_nine, arena_fighting, guild_fighting],
	case lists:member(Field, Fileds) of
		true ->
			db:execute(io_lib:format(?SQL_RKACT_HANDLE_UPDATE, [Field]));
		_ ->
			skip
	end.

%% 重新发送开服7天奖励
resend_seven_day_award(Field) ->
	FunList = [
		[player_level, get_player_level_top],
		[player_power, get_player_power_top],
		[player_meridian, get_player_meridian_top],
		[player_achieve, get_player_achieve_top],
		[pet_level, get_pet_level_top],
		[pet_power, get_pet_power_top],
		[dungeon_nine, get_ninesky_award],
		[arena_fighting, get_arena_fighting_award],
		[guild_fighting, get_guild_fighting_award]
	],
	[mod_disperse:cast_to_unite(lib_rank_activity, FunName, []) || [FieldName, FunName] <- FunList, FieldName =:= Field].

%% 发送鲜花魅力榜奖励
%% RankType : 7001每日护花榜, 7002每日鲜花榜
send_charm_rank_award(RankType) ->
	NowTime = util:unixtime(),
	[Start, End] = data_activity:get_charm_time(),
	%% 在活动期间内发送奖励（注意最后一次发奖励时间）
	case NowTime > Start andalso NowTime < End + 86400 of
		true ->
			private_send_charm_rank_award(RankType);
		_ ->
			%% 如果在活动结束后的第二天，清理西游第一美和西游第一帅称号
			case NowTime > End + 86400 andalso NowTime < End + 86400 + 86400 of
				true ->
					case RankType of
						?RK_CHARM_DAY_HUHUA ->
		            		lib_designation:remove_design_by_id(201408);
						?RK_CHARM_DAY_FLOWER ->
							lib_designation:remove_design_by_id(201402);
						_ ->
							skip
					end;
				_ ->
					skip
			end
	end.

%% 将护花榜前20名数据发到跨服
send_kf_flower_data(PlatFormId, ServerId) -> 
	Huhua = private_kf_flower_get_data(PlatFormId, ServerId, ?RK_CHARM_DAY_HUHUA, 20),
	Flower = private_kf_flower_get_data(PlatFormId, ServerId, ?RK_CHARM_DAY_FLOWER, 20),
	mod_clusters_node:apply_cast(lib_activity_festival, center_receive_rank_count, [
		mod_disperse:get_clusters_node(), [PlatFormId, Huhua, Flower]
	]).

%% 秘籍：重新发送昨天魅力鲜花榜奖励
%% RankType : 7001每日护花, 7002每日鲜花榜
gm_yestoday_charm_rank_award(RankType) ->
	mod_disperse:cast_to_unite(lib_rank_activity, resend_yestoday_charm_rank_award, [RankType]),
	ok.
resend_yestoday_charm_rank_award(RankType) ->
	Sex = if
		RankType =:= 7001 -> 1;
		true -> 2
	end,

	Sql = <<"SELECT pl.id, pl.nickname, pl.sex, pl.career, pl.realm, g.guild_name, f.value, pl.image
	FROM rank_daily_flower_copy AS f LEFT JOIN player_low AS pl ON f.id=pl.id LEFT JOIN guild_member as g ON f.id=g.id 
	WHERE pl.sex=~p ORDER BY f.value DESC LIMIT ~p">>,
	case db:get_all(io_lib:format(Sql, [Sex, ?NUM_LIMIT])) of
		[] ->
			skip;
		List ->
			private_send_charm_rank_award_mail(List)
	end.

%% 发送鲜花魅力榜奖励
%% RankType : 7001每日护花榜, 7002每日鲜花榜
private_send_charm_rank_award(RankType) ->
	case lib_rank:pp_get_rank(RankType) of
		[] ->
			skip;
		List ->
			private_send_charm_rank_award_mail(List)
	end.

private_send_charm_rank_award_mail(List) ->
	[OneList, SecondList, ThirdList, FouthList, _] = 
	lists:foldl(fun(Row, [TmpOneList, TmpSecondList, TmpThirdList, TmpFouthList, Position]) -> 
		[Id | _] = Row,
		if
            Position == 1 ->
                [[[Id] | TmpOneList], TmpSecondList, TmpThirdList, TmpFouthList, Position+1];
			Position == 2 ->
                [TmpOneList, [[Id] | TmpSecondList], TmpThirdList, TmpFouthList, Position+1];
            Position == 3 ->
                [TmpOneList, TmpSecondList, [[Id] | TmpThirdList], TmpFouthList, Position+1];
            Position >= 4 andalso Position =< 10 ->
                [TmpOneList, TmpSecondList, TmpThirdList, [[Id] | TmpFouthList], Position+1];
            true ->
                [TmpOneList, TmpSecondList, TmpThirdList, TmpFouthList, Position+1]
        end
	end, [[], [], [], [], 1], List),

	Title = data_activity_text:get_middle_and_national_charm_title(),

	%% 处理第一名
	case OneList of
		[] -> skip;
		_ ->
			%% 发邮件奖励
			private_send_gift_mail(
                OneList,
                Title,
                data_activity_text:get_middle_and_national_charm_content(1),
                private_get_goodsid_by_gift(data_activity:get_charm_gift(1))
            )
	end,

	%% 处理第二名
	case SecondList of
		[] -> skip;
		_ ->
			%% 发邮件奖励
			private_send_gift_mail(
                SecondList,
                Title,
                data_activity_text:get_middle_and_national_charm_content(2),
                private_get_goodsid_by_gift(data_activity:get_charm_gift(2))
            )
	end,

	%% 处理第三名
	case ThirdList of
		[] -> skip;
		_ ->
			%% 发邮件奖励
			private_send_gift_mail(
                ThirdList,
                Title,
                data_activity_text:get_middle_and_national_charm_content(3),
                private_get_goodsid_by_gift(data_activity:get_charm_gift(3))
            )
	end,

	%% 处理第四至十名
	case FouthList of
		[] -> skip;
		_ ->
			%% 发邮件奖励
			private_send_gift_mail(
                FouthList,
                Title,
                data_activity_text:get_middle_and_national_charm_content(4),
                private_get_goodsid_by_gift(data_activity:get_charm_gift(4))
            )
	end.

%% 最强竞技战，发送邮件
private_send_arena_award(RoleIds, Title, Content) ->
	Length = length(RoleIds),
	%% 第1名
	case Length > 0 of
		true ->
			OneId = lists:sublist(RoleIds, 1, 1),
			GoodsTypeId1 = private_get_goodsid_by_gift(532416),
			private_send_gift_mail([OneId], Title, Content, GoodsTypeId1);
		_ ->
			skip
	end,

	%% 第2名
	case Length > 1 of
		true ->
			TwoId = lists:sublist(RoleIds, 2, 1),
			GoodsTypeId2 = private_get_goodsid_by_gift(532417),
			private_send_gift_mail([TwoId], Title, Content, GoodsTypeId2);
		_ ->
			skip
	end,
	
	%% 第3名
	case Length > 2 of
		true ->
			ThreeId = lists:sublist(RoleIds, 3, 1),
			GoodsTypeId3 = private_get_goodsid_by_gift(532418),
			private_send_gift_mail([ThreeId], Title, Content, GoodsTypeId3);
		_ ->
			skip
	end.

%% 最强竞技战，发送邮件
private_send_guild_award(RoleIds, Title, Content) ->
	Length = length(RoleIds),
	%% 第1名
	case Length > 0 of
		true ->
			OneId = lists:sublist(RoleIds, 1, 1),
			GoodsTypeId1 = private_get_goodsid_by_gift(532421),
			private_send_gift_mail([OneId], Title, Content, GoodsTypeId1);
		_ ->
			skip
	end,

	%% 第2名
	case Length > 1 of
		true ->
			TwoId = lists:sublist(RoleIds, 2, 1),
			GoodsTypeId2 = private_get_goodsid_by_gift(532422),
			private_send_gift_mail([TwoId], Title, Content, GoodsTypeId2);
		_ ->
			skip
	end,

	%% 第3名
	case Length > 2 of
		true ->
			ThreeId = lists:sublist(RoleIds, 3, 1),
			GoodsTypeId3 = private_get_goodsid_by_gift(532423),
			private_send_gift_mail([ThreeId], Title, Content, GoodsTypeId3);
		_ ->
			skip
	end.

%% 发送绑定元宝邮件
private_send_gold_mail(List, Title, Content, Gold) ->
	case List of
		[] -> skip;
		_ -> lib_mail:send_sys_mail_bg(List, Title, Content, 0, 2, 0, 0, 0, 0, 0, 0, Gold)
	end.

%% 发送礼包邮件
private_send_gift_mail(List, Title, Content, GoodsTypeId) ->
	SendIds = [Id || [Id] <- List, is_integer(Id), Id > 0],
	case SendIds of
		[] ->
			skip;
		_ ->
			lib_mail:send_sys_mail_bg(SendIds, Title, Content, GoodsTypeId, 2, 0, 0, 1, 0, 0, 0, 0)
	end.

%% 通过礼包id取得物品id
private_get_goodsid_by_gift(GiftId) ->
	case data_gift:get(GiftId) of
		[] -> 
			0;
		Gift ->
			Gift#ets_gift.goods_id
	end.

%% 截取护花/鲜花榜前N条数据
private_kf_flower_get_data(PlatFormId, ServerId, RankType, RecordNum) ->
	case lib_rank:pp_get_rank(RankType) of
		[] -> [];
		List ->
			[_, RankList] = 
			lists:foldl(fun([Id, Name, _Sex, Career, _Realm, _Guild, Value, Image], [Num, Rank]) ->
				case Num < RecordNum of
					true ->
						[Num + 1, [[PlatFormId, ServerId, Id, Name, Value, Career, Image] | Rank]];
					_ ->
						[Num + 1, Rank]
				end
			end, [0, []], List),
			lists:reverse(RankList)
	end.
