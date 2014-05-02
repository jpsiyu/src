%%%--------------------------------------
%%% @Module  : lib_activity_kf_power
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2013.3.8
%%% @Description: 斗战封神活动，对比跨服战力
%%%--------------------------------------

-module(lib_activity_kf_power).
-include("server.hrl").
-include("unite.hrl").
-include("activity_kf_power.hrl").
-include("rank.hrl").
-include("rank_cls.hrl").
-compile(export_all).

%% 说明：
%% 排行列表数据：[[Platform, ServerId, Id, NickName, Realm, Career, Sex, Lv, Power], ...]
%% 玩家形象数据：[{[Platform, ServerId, Id], Image}, ...]

%% 秘籍：触发发放奖励
gm_re_send_award() -> 
	{_StartTime, EndTime} = case data_activity_time:get_time_by_type(?ACTIVITY_TIME_TYPE) of
		[Start, End] -> {Start, End};
		_ -> {0, 0}
	end,
	mod_disperse:cast_to_unite(lib_activity_kf_power, handle_kf_award, [EndTime]).

%% 秘籍：在跨服执行，清掉斗战封神活动排行数据
gm_clean_rank() ->
	spawn(fun() -> 
		DeleteSql2 = <<"DELETE FROM activity_power_rank_image">>,
		DeleteSql3 = <<"DELETE FROM activity_power_rank_list">>,
		db:execute(io_lib:format(DeleteSql2, [])),
		db:execute(io_lib:format(DeleteSql3, [])),
		ets:delete_all_objects(?RK_ETS_POWER_ACTIVITY),
		reload_rank()
	end),
	ok.

%% 秘籍：在跨服执行，清掉斗战封神活动排行数据重复数据
gm_delete_multi(Platform, ServerId, Id) ->
	spawn(fun() -> 
		SqlList = <<"DELETE FROM activity_power_rank_list WHERE platform='~s' AND server_num=~p AND id=~p">>,
		SqlImage = <<"DELETE FROM activity_power_rank_image WHERE platform='~s' AND server_num=~p AND id=~p">>,
		db:execute(io_lib:format(SqlList, [Platform, ServerId, Id])),
		db:execute(io_lib:format(SqlImage, [Platform, ServerId, Id])),
		reload_rank()
	end),
	ok.


%% 获取开关
get_switch() -> true.

%% 判断是否在活动时间内
%% @return bool
is_valide() ->
	case data_activity_time:get_time_by_type(?ACTIVITY_TIME_TYPE) of
		[Start, End] ->
			NowTime = util:unixtime(),
			NowTime >= Start andalso NowTime =< End;
		_ ->
			false
	end.

%% 获取本服排行数据
get_rank() ->
	case ets:lookup(?MODULE_RANK, ?MODULE_RANK_2) of
		[] -> [];
		[Rd] -> Rd
	end.

%% [游戏线] 将战力发到跨服结点进行上榜
send_power_to_kf(PS) ->
	case get_switch() of
		true ->
			case PS#player_status.lv >= data_activity:get_kf_power_config(level) 
				andalso PS#player_status.combat_power >= data_activity:get_kf_power_config(power) of
				true ->
					case is_valide() of
						true ->
							Node = mod_disperse:get_clusters_node(),
							CacheKey = {lib_activity_kf_power, PS#player_status.id},
							Element = [PS#player_status.platform, PS#player_status.server_num, PS#player_status.id, 
								PS#player_status.nickname, PS#player_status.realm, PS#player_status.career, 
								PS#player_status.sex, PS#player_status.lv, PS#player_status.combat_power
							],
							case mod_daily_dict:get_special_info(CacheKey) of
								undefined ->
									mod_clusters_node:apply_cast(mod_rank_cls, powerrank_send_power_to_kf, [Node, Element]),
									mod_daily_dict:set_special_info(CacheKey, PS#player_status.combat_power);
								OldPower ->
									case PS#player_status.combat_power > OldPower of
										true ->
											mod_clusters_node:apply_cast(mod_rank_cls, powerrank_send_power_to_kf, [Node, Element]),
											mod_daily_dict:set_special_info(CacheKey, PS#player_status.combat_power);
										_ ->
											skip
									end
							end;
						_ ->
							skip
					end;
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%% 请求发自身形象到跨服中心保存起来
get_image(Node, Platform, ServerId, Id, Power) ->
	case get_switch() of
		true ->
			case lib_player:get_player_info(Id, get_image) of
				Image when is_list(Image) ->
					mod_clusters_node:apply_cast(mod_rank_cls, powerrank_send_image_to_kf, [Node, Platform, ServerId, Id, [Power | Image]]);
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%% [公共线] 打开活动面板需要的数据
get_data(Platform, ServerId, Id) ->
	case get_rank() of
		[] ->
			%% 向跨服获取最新数据
			Node = mod_disperse:get_clusters_node(),
			mod_clusters_node:apply_cast(mod_rank_cls, powerrank_get_power_list, [Node, Platform, ServerId, Id]);
		Rd ->
			NowTime = util:unixtime(),
			case Rd#ets_module_rank.update + data_activity:get_kf_power_config(cache_time) > NowTime of
				%% 缓存还没到过期时间
				true ->
					MyRankNo = get_power_rank_myno(Platform, ServerId, Id, Rd#ets_module_rank.rank_list),
					{ok, Bin} = pt_319:write(31901, [MyRankNo, Rd#ets_module_rank.top_10, get_power_rank_gift(Id)]),
					lib_unite_send:send_to_uid(Id, Bin);
				%% 缓存过期，重新向跨服获取最新数据
				_ ->
					Node = mod_disperse:get_clusters_node(),
					mod_clusters_node:apply_cast(mod_rank_cls, powerrank_get_power_list, [Node, Platform, ServerId, Id])
			end
	end.

%% 跨服节点服务启动时，重新从表里面加载数据
reload_rank() ->
	case is_valide() of
		true ->
			case private_reload_list() of
				[] ->
					skip;
				RankRows ->
					ImageRows = private_reload_image(),
					%% 排行排行
					Sort = fun(Row1, Row2) -> 
						Power1 = lists:last(Row1),
						Power2 = lists:last(Row2),
						Power1 >= Power2
					end,

					Records = 
					lists:map(fun({RankPlatform, RankList}) -> 
						ImageList = lists:foldl(fun({ImagePlatform, NewImageRows}, TopRows) -> 
							case RankPlatform =:= ImagePlatform of
								true -> NewImageRows;
								_ -> TopRows
							end
						end, [], ImageRows),

						SortRankList = lists:sort(Sort, RankList),

						#kfrank_power_activity{
							platform = RankPlatform,
							top_10 = ImageList,
							rank_list = SortRankList
						}
					end, RankRows),
					ets:insert(?RK_ETS_POWER_ACTIVITY, Records)
			end;
		_ ->
			skip
	end.

%% 从跨服发送数据到游戏，设置缓存数据
kfrank_reset_power_list(Platform, ServerNum, Id, List) ->
	mod_disperse:cast_to_unite(mod_rank, kfrank_reset_power_list, [Platform, ServerNum, Id, List]).

%% 格式为前10玩家形象
formate_power_top10(List) ->
	F = fun({[Platform, ServerId, Id], [Power, _Id, Lv, Realm, Career, Sex, Weapon, Cloth, WLight, CLight, ShiZhuang, SuitId, Vip, Nick]}) ->
		[[FWeapon, FWS], [FArmor, FAS], [FAccessory, FAccS]] = case is_list(ShiZhuang) of
			true -> ShiZhuang;
			false -> [[0, 0], [ShiZhuang, 0], [0, 0]]
		end,
		NewPlatform = pt:write_string(Platform),
		S7 = pt:write_string(integer_to_list(CLight)),
		NickName = pt:write_string(Nick),
		<<
			NewPlatform/binary,	%% 平台
			ServerId:16,
			Id:32,			%% 玩家id    
			Lv:16,			%% 玩家等级
			Realm:8,		%% 国家
			Career:8,		%% 玩家职业
			Sex:8,			%% 玩家性别
			Weapon:32,		%% 武器
			Cloth:32,		%% 装备
			WLight:8,		%% 武器发光
			S7/binary,		%% 衣服发光
			FArmor:32,		%% 时装衣服id
			SuitId:32,		%% 套装id
			Vip:8,			%% vip
			NickName/binary,%% 玩家名字
			FAS:8,			%% 衣服时装强化数
			FWeapon:32,		%% 武器时装id
			FWS:8,			%% 武器时装强化数
			FAccessory:32,	%% 饰品时装id
			FAccS:8,		%% 饰品时装强化数
			Power:32
		>>
	end,
	[F(Row) || Row <- List].

%% [跨服战力排行活动] 格式化排行数据
format_power_list(List, [MyPlatform, MyServerNum, MyId]) ->
	F = fun([Platfrom, ServerNum, Id, Name, Realm, Career, Sex, LV, Power], [TmpList, TmpPos]) ->
		Platfrom2 = pt:write_string(Platfrom),
		Name2 = pt:write_string(Name),
		Bin = <<Platfrom2/binary, ServerNum:16, Id:32, Name2/binary, Career:8, Realm:8, Sex:8, LV:8, Power:32>>,
		if
			[Platfrom, ServerNum, Id] =:= [MyPlatform, MyServerNum, MyId] ->
				[[Bin | TmpList], TmpPos];
			true ->
				[[Bin | TmpList], TmpPos + 1]
		end
	end,
	[NewList, Pos] = lists:foldl(F, [[], 0], List),
	[lists:reserve(NewList), Pos].

%% 领取奖励
fetch_award(PS, GiftId) ->
	RequireLevel = data_activity:get_kf_power_config(level),
	RequirePower = data_activity:get_kf_power_config(award_power),
	Bool = is_valide(),
	if
		PS#player_status.lv < RequireLevel -> {error, 3};
		PS#player_status.combat_power < RequirePower -> {error, 4};
		Bool =:= false -> {error, 5};
		true ->
			%% 判断是否已经领取过了
			AlreadyGetList = case db:get_row(io_lib:format(?KF_POWER_AWARD_GET, [PS#player_status.id])) of
				[Field] -> util:bitstring_to_term(Field);
				[] -> []
			end,
			GiftConfList = data_activity:get_kf_power_config(power_gift),
			GiftList = [ConfGiftId || {_, ConfGiftId} <- GiftConfList],

			case lists:member(GiftId, GiftList) andalso lists:member(GiftId, AlreadyGetList) =:= false of
				true ->
					{NeedPower, _} = lists:keyfind(GiftId, 2, GiftConfList),
					case PS#player_status.combat_power >= NeedPower of
						true ->
							G = PS#player_status.goods,
							case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
								{ok, [ok, _NewPS]} ->
									AlreadyGetList2 = AlreadyGetList ++ [GiftId],
									StringGiftIds = util:term_to_bitstring(AlreadyGetList2),
									db:execute(io_lib:format(?KF_POWER_AWARD_INSERT, [PS#player_status.id, StringGiftIds])),
									{ok};
								{ok, [error, ErrorCode]} ->
									{error, ErrorCode};
								_ ->
									{error, 999}
							end;
						_ ->
							{error, 4}
					end;
				_ ->
					{error, 2}
			end
	end.

%% [公共线] 活动结束时，处理达标玩家奖励
handle_kf_award(NowTime) ->
	{_StartTime, EndTime} = case data_activity_time:get_time_by_type(?ACTIVITY_TIME_TYPE) of
		[Start, End] -> {Start, End};
		_ -> {0, 0}
	end,
	%% 在活动结束后的半个小时内刷新排行榜，则会发奖励
	case NowTime >= EndTime andalso NowTime < EndTime + 1200 of
		true ->
			case mod_daily_dict:get_special_info({lib_activity_kf_power, handle_kf_award}) of
				undefined ->
					mod_daily_dict:set_special_info({lib_activity_kf_power, handle_kf_award}, 1),

					spawn(fun() -> 
						%% 发达标奖励
						private_send_all_award()
					end),
					spawn(fun() -> 
						%% 发前三奖励
						private_send_top_3_award()
					end),
					ok;
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%% 发全服所有达标的玩家奖励
private_send_all_award() ->
	RequireLv = data_activity:get_kf_power_config(level),
	RequirePower = data_activity:get_kf_power_config(award_power),
	case db:get_all(io_lib:format(?KF_POWER_AWARD_GET2, [RequireLv, RequirePower])) of
		[] ->
			skip;
		List ->
			Title = data_activity_text:kf_power_rank_all_title(),
			Content = data_activity_text:kf_power_rank_all_content(),
			ConfGifts = data_activity:get_kf_power_config(power_gift),
			AllGiftIds =[GiftId || {_, GiftId} <- ConfGifts],
			lists:map(fun([Id, Power]) -> 
				AlreadyGiftIds = case db:get_row(io_lib:format(?KF_POWER_AWARD_GET, [Id])) of
					[Field] -> util:bitstring_to_term(Field);
					_ -> []
				end,
				lists:foreach(fun(AId) -> 
					case lists:member(AId, AlreadyGiftIds) of
						%% 判断是否达到战力值，是的话发奖励
						false ->
							{NeedPower, _} = lists:keyfind(AId, 2, ConfGifts),
							if
								Power >= NeedPower ->
									private_send_gift_mail([Id], Title, Content, AId);
								true ->
									skip
							end;
						_ ->
							skip
					end
				end, AllGiftIds)
			end, List)
	end.

%% [公共线] 单服未达标前三奖励
private_send_top_3_award() ->
	RequireLv = data_activity:get_kf_power_config(level),
	MinPower = data_activity:get_kf_power_config(top_3_power),
	MaxPower = data_activity:get_kf_power_config(award_power),
	ConfGift = data_activity:get_kf_power_config(top_3_gift),
	case db:get_all(io_lib:format(?KF_POWER_AWARD_GET3, [RequireLv, MinPower, MaxPower, 3])) of
		[] ->
			skip;
		List ->
			Title = data_activity_text:kf_power_rank_top3_title(),
			Content = data_activity_text:kf_power_rank_top3_content(),
			lists:foldl(fun([Id, _Power], Pos) -> 
				{_, GiftId} = lists:keyfined(Pos, 1, ConfGift),
				private_send_gift_mail([Id], Title, Content, GiftId)
			end, 1, List)
	end.

%% 发送礼包邮件
private_send_gift_mail(List, Title, Content, GiftId) ->
    case List of
        [] -> skip;
        _ -> 
			GoodsTypeId = lib_gift_new:get_goodsid_by_giftid(GiftId),
			lib_mail:send_sys_mail_bg(List, Title, Content, GoodsTypeId, 2, 0, 0, 1, 0, 0, 0, 0)
    end.

%% 重载排行数据
%% 返回格式如：[{4399, RankList}, {91wan, RankList}]
private_reload_list() ->
	case db:get_all(io_lib:format(?KF_POWER_RANK_GET, [])) of
		[] ->
			[];
		List ->
			Forms = [util:make_sure_list(DbPlatform) || [DbPlatform | _] <- List],
			lists:map(fun(Platform) ->
				RankList = lists:foldl(fun([DbPlatform2, DbServerNum2, Id2, NickName, Realm, Career, Sex, Lv, Power], TargetList) -> 
					Pf = util:make_sure_list(DbPlatform2),
					case Pf =:= Platform of
						true ->
							[[Pf, DbServerNum2, Id2, NickName, Realm, Career, Sex, Lv, Power] | TargetList];
						_ ->
							TargetList
					end
				end, [], List),
				{Platform, RankList}
			end, sets:to_list(sets:from_list(Forms)))
	end.

%% 重载前10玩家形象数据
%% 返回格式如：[{4399, ImageList}, {91wan, ImageList}]
private_reload_image() ->
	case db:get_all(io_lib:format(?KF_POWER_IMAGE_GET, [])) of
		[] ->
			[];
		List ->
			Forms = [util:make_sure_list(DbPlatform) || [DbPlatform | _] <- List],
			lists:map(fun(Platform) -> 
				ImageList = lists:foldl(fun([DbPlatform2, DbServerNum2, Id2, Content2], TargetList) ->
					Pf = util:make_sure_list(DbPlatform2),
					case Platform =:= Pf of
						true ->
							[{[Pf, DbServerNum2, Id2], util:bitstring_to_term(Content2)} | TargetList];
						_ ->
							TargetList
					end
				end, [], List),
				{Platform, ImageList}
			end, sets:to_list(sets:from_list(Forms)))
	end.

%% 获取在斗战封神排行榜上我的排行位置
get_power_rank_myno(_Platform, ServerNum, Id, List) ->
	[_, RankNo] = lists:foldl(fun([_RowPlatform, RowServerNum, RowId | _], [No, MyNo]) -> 
		case RowServerNum =:= ServerNum andalso RowId =:= Id of
			true -> [No + 1, No + 1];
			_ -> [No + 1, MyNo]
		end
	end, [0, 0], List),
	RankNo.

%% 获取斗战封神奖励领取情况
get_power_rank_gift(Id) ->
	FetchGifts = case db:get_row(io_lib:format(?KF_POWER_AWARD_GET, [Id])) of
		[] -> [];
		[Field] -> util:bitstring_to_term(Field)
	end,
	[begin 
		case lists:member(GiftId, FetchGifts) of
			true ->
				<<Power:32, GiftId:32, 1:8>>;
			_ ->
				<<Power:32, GiftId:32, 0:8>>
		end
	end || {Power, GiftId} <- data_activity:get_kf_power_config(power_gift)].


