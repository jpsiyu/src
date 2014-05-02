%%%--------------------------------------
%%% @Module  : lib_fame_limit
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.6.2
%%% @Description: 限时名人堂（活动）
%%%--------------------------------------

%% #player_status.fame_limit : [铜币， 淘宝， 经验， 历练]

-module(lib_fame_limit).
-include("server.hrl").
-include("rank.hrl").
-include("fame_limit.hrl").
-include("gift.hrl").
-compile(export_all).

%% 开关
get_switch() ->
	lib_switch:get_switch(famelimit).

%% 是否在活动时间内
%% 返回：bool
in_activity_time() ->
	NowTime = util:unixtime(),
	[Start, End] = data_activity:get_fame_limit_time(),
	NowTime >= Start andalso NowTime < End.

%% 下线回写数据到表里
%% 淘宝是实时写库的，铜币、经验和历练只在下线时才回写
offline(PS) ->
	case get_switch() andalso in_activity_time() of
		true ->
			case PS#player_status.fame_limit of
				[Coin, _Taobao, Exp, PT] ->
					db:execute(
						io_lib:format(?SQL_FAME_LIMIT_UPDATE, [Coin, Exp, PT, PS#player_status.lv, PS#player_status.combat_power, PS#player_status.id])
					);
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%% [公共线] 清除数据
clear_data(_Args) ->
	case get_switch() of
		true ->
			NowTime = util:unixtime(),
			[Start, End] = data_activity:get_fame_limit_time(),
			%% 活动期间，走正常处理流程
			case NowTime >= Start andalso NowTime < End of
				true ->
					private_do_award_daily();
				_ ->
					%% 活动时间结束后的最后一次结算，除了发奖励，还要清掉称号
					case NowTime >= End andalso NowTime < End + 3600 of
						true ->
							private_do_award_daily(),

							%% 移除称号
							lists:map(fun(DesignId) -> 
								case lib_designation:get_roleids_by_design(DesignId) of
									[] -> skip;
									RoleList ->
										[lib_designation:remove_design_in_server(RoleId, DesignId) || RoleId <- RoleList]
								end
							end, [201405, 201406, 201403, 201404]);
						_ ->
							skip
					end
			end;
		_ ->
			skip
	end.

%% 每天0点处理奖励
private_do_award_daily() ->
	%% 发送邮件奖励
 	private_send_award_email(),
	%% 清表数据
	db:execute(io_lib:format(?SQL_FAME_LIMIT_DELETE, [])),
	db:execute(io_lib:format(?SQL_FAME_MASTER_DELETE, [])),
	%% 清排行榜数据，及雕像数据
	ets:delete_all_objects(?ETS_FAME_LIMIT_RANK),
	mod_disperse:send_other_server(ets, delete_all_objects, [?ETS_FAME_LIMIT_STATUE]),
	%% 清除雕像的人物形象
	{ok, BinData} = pt_220:write(22031, 1),
	lib_unite_send:send_to_scene(?SCENE_CHANG_AN, 0, BinData).

%% 触发：铜币
trigger_coin(PS, AddValue) ->
	case get_switch() andalso in_activity_time() of
		true ->
			AddCoin = round(AddValue),

			%% 统计最新值
			[V1, V2, V3, V4] = private_format_data({coin, AddCoin}, private_init_stat(PS)),

			Count = mod_daily_dict:get_count(PS#player_status.id, 1040),
			mod_daily_dict:set_count(PS#player_status.id, 1040, Count + 1),

			%% 刷新排行榜：当铜币大于指定值，且获得铜币次数是10的整数时，才会刷新排行榜，且实时入库
			case V1 > ?FAME_LIMIT_COIN_DOWN of
                true ->
					case Count rem 10 =:= 1 of
						true ->
							private_update_stat(PS, V1, V3, V4);
						_ ->
							skip
					end,

                    mod_disperse:cast_to_unite(
				        mod_fame_limit, update_rank, [
					        ?FAME_LIMIT_RANK_COIN,
				        	[PS#player_status.id, PS#player_status.nickname, PS#player_status.sex, PS#player_status.career, 
						    PS#player_status.realm, PS#player_status.lv, PS#player_status.combat_power, V1]
				        ]
			        );
                _ ->
                    skip
            end,

			PS#player_status{
				fame_limit = [V1, V2, V3, V4]
			};
		_ ->
			PS
	end.

%% 触发：淘宝
trigger_taobao(PS, AddValue) ->
	case get_switch() andalso in_activity_time() of
		true ->
			%% 统计最新值
			[V1, V2, V3, V4] = private_format_data({taobao, AddValue}, private_init_stat(PS)),

			%% 实时入库
			db:execute(
				io_lib:format(?SQL_FAME_LIMIT_UPDATE2, [value2, V2, PS#player_status.lv, PS#player_status.combat_power, PS#player_status.id])
			),

			%% 刷新排行榜
			mod_disperse:cast_to_unite(
				mod_fame_limit, update_rank, [
					?FAME_LIMIT_RANK_TAOBAO,
					[PS#player_status.id, PS#player_status.nickname, PS#player_status.sex, PS#player_status.career, 
						PS#player_status.realm, PS#player_status.lv, PS#player_status.combat_power, V2]
				]
			),

			PS#player_status{
				fame_limit = [V1, V2, V3, V4]
			};
		_ ->
			PS
	end.

%% 触发：经验
trigger_exp(PS, AddValue) ->
	case get_switch() andalso in_activity_time() of
		true ->
			AddExp = round(AddValue),

			%% 统计最新值
			[V1, V2, V3, V4] = private_format_data({exp, AddExp}, private_init_stat(PS)),

			Count = mod_daily_dict:get_count(PS#player_status.id, 1041),
			mod_daily_dict:set_count(PS#player_status.id, 1041, Count + 1),

			%% 刷新排行榜：当经验值大于指定值，且获得经验次数是10的整数时，才会刷新排行榜，且实时入库
            case V3 > ?FAME_LIMIT_EXP_DOWN of
                true ->
					%% 获得10次经验回写一次数据库
					case Count rem 10 == 1 of
						true ->
							private_update_stat(PS, V1, V3, V4);
						_ ->
							skip
					end,

					%% 获得10次经验刷新一次排行榜
					case Count rem 10 == 0 of
						true ->
							mod_disperse:cast_to_unite(
						        mod_fame_limit, update_rank, [
							    ?FAME_LIMIT_RANK_EXP,
							    [PS#player_status.id, PS#player_status.nickname, PS#player_status.sex, PS#player_status.career, 
								    PS#player_status.realm, PS#player_status.lv, PS#player_status.combat_power, V3]
						        ]
					        );
						_ ->
							skip
					end;
				_ ->
					skip
			end,

			PS#player_status{
				fame_limit = [V1, V2, V3, V4]
			};
		_ ->
			PS
	end.

%% 触发：历练
trigger_pt(PS, AddValue) ->
	case get_switch() andalso in_activity_time() of
		true ->
			AddPT = round(AddValue),

			%% 统计最新值
			[V1, V2, V3, V4] = private_format_data({pt, AddPT}, private_init_stat(PS)),

			Count = mod_daily_dict:get_count(PS#player_status.id, 1042),
			mod_daily_dict:set_count(PS#player_status.id, 1042, Count + 1),
			%% 刷新排行榜：当经验值大于指定值，且获得经验次数是10的整数时，才会刷新排行榜，且实时入库
            case V4 > ?FAME_LIMIT_PT_SPACE of
                true ->
					case Count rem 10 =:= 0 of
						true ->
							private_update_stat(PS, V1, V3, V4);
						_ ->
							skip
					end,

					%% 刷新排行榜
					mod_disperse:cast_to_unite(
						mod_fame_limit, update_rank, [
							?FAME_LIMIT_RANK_PT,
							[PS#player_status.id, PS#player_status.nickname, PS#player_status.sex, PS#player_status.career, 
								PS#player_status.realm, PS#player_status.lv, PS#player_status.combat_power, V4]
						]
					);
				_ ->
					skip
			end,

			PS#player_status{
				fame_limit = [V1, V2, V3, V4]
			};
		_ ->
			PS
	end.

%% [公共线] 更新排行榜
update_rank(RankType, Row) ->
	[NewRoleId, NewRoleName, NewSex, NewCareer, NewRealm, NewLevel, NewPower, NewValue] = Row,
	case get_rank_data(RankType) of
		%% 第一个人触发
		[] ->
			RankRecord = private_make_rank_info(RankType, [Row]),
			ets:insert(?ETS_FAME_LIMIT_RANK, RankRecord),

			%% 通知玩家游戏线进程处理成为霸主
			case misc:get_player_process(NewRoleId) of
				Pid when is_pid(Pid) ->
					gen_server:cast(Pid, {'fame_limit_be_statue', RankType});
				_ ->
					%% 不在线的暂时不处理
					skip
			end,

			%% 刷新玩家称号
			private_refresh_design(RankType, [Row]),

			%% 战力第一的玩家需要传闻数据
			private_set_first_rank();
		List ->
			FirstElement = lists:nth(1, List),
			[FirstRoleId, _, _, _, _, _, _, _] = FirstElement,

			Len = length(List),
			LastElement = lists:nth(Len, List),
			[_, _, _, _, _, _, _, LastValue] = LastElement,
			case NewValue =< LastValue andalso Len >= ?NUM_LIMIT of
				%% 如果排行榜记录数已经上限，而且目前的值还达不到最底要求，则不需要处理
				true ->
					skip;
				_ ->
					%% 第一步：循环列表，替换排行值
					F = fun(RankRow, [Exist, NewList]) ->
					        [OldRoleId, _, _, _, _, _, _, _] = RankRow,
						case OldRoleId =:= NewRoleId of
							true ->
								[1, [[NewRoleId, NewRoleName, NewSex, NewCareer, NewRealm, NewLevel, NewPower, NewValue] | NewList]];
							_ ->
								[Exist, [RankRow | NewList]]
						end
					end,
					[NewExist, List2] = lists:foldl(F, [0, []], List),
					case NewExist of
						%% 之前不在榜上
						0 ->
							List3 = [[NewRoleId, NewRoleName, NewSex, NewCareer, NewRealm, NewLevel, NewPower, NewValue] | List2];
						_ ->
							List3 = List2
					end,
					%% 第二步：排序
					SortFun = fun([_, _, _, _, _, _Level1, _Power1, Value1], [_, _, _, _, _, _Level2, _Power2, Value2]) ->
						if
							Value1 > Value2 -> true;
							true -> false
						end
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
					ets:insert(?ETS_FAME_LIMIT_RANK, RankRecord),
					
					NewFirstElement = lists:nth(1, List5),
					[NewFirstRoleId, _, _, _, _, _, _, _] = NewFirstElement,
					
					case FirstRoleId =/= NewFirstRoleId of
						true ->
							%% 通知玩家游戏线进程处理成为霸主
							case misc:get_player_process(NewFirstRoleId) of
								Pid when is_pid(Pid) ->
									gen_server:cast(Pid, {'fame_limit_be_statue', RankType});
								_ ->
									%% 玩家不在线，要想个办法处理
									skip
							end;
						_ ->
							skip
					end,

					%% 刷新上榜玩家称号
					private_refresh_design(RankType, List5)
			end
	end.

%% 获取排行榜数据
%% RankType : 8001~8004
get_rank_data(RankType) ->
	%% 通用获取
	case ets:lookup(?ETS_FAME_LIMIT_RANK, RankType) of
		[] ->
			[];
		[RD] when is_record(RD, ets_fame_limit_rank) ->
			RD#ets_fame_limit_rank.rank_list;
		_ ->
			[]
	end.

%% 获取雕像数据
%% 在玩家进入长安安全区时，会发起请求
get_masters() ->
	case get_switch() andalso in_activity_time() of
		true ->
			case ets:tab2list(?ETS_FAME_LIMIT_STATUE) of
				%% 如果ets表没数据，则从db中获取一次。一般只要第一个人触发就会有数据了
				[] ->
					Sql = io_lib:format(?SQL_FAME_MASTER_SELECT, []),
					case db:get_all(Sql) of
						[] ->
							[];
						DataList ->
							lists:map(fun([Type, Data]) ->
								TermData = util:to_term(Data),
								ets:insert(?ETS_FAME_LIMIT_STATUE, #ets_fame_limit_statue{type = Type, data = TermData}),
								[Type, TermData]
							end, DataList)
					end;
				List ->
					lists:map(fun(Rd) ->
						#ets_fame_limit_statue{type = Type, data = Data} = Rd,
						[Type, Data]
					end, List)
			end;
		_ ->
			skip
	end.

%% 成为霸主
make_master(Type, PS) ->
	Master = lib_player_server:get_player_statue(PS),
	case util:term_to_bitstring(Master) of
		<<"undefined">> ->
			skip;
		Data ->
			db:execute(
				io_lib:format(?SQL_FAME_MASTER_REPLACE, [Type, Data])
			),
			%% 保存进本游戏线ets中
			ets:insert(?ETS_FAME_LIMIT_STATUE, #ets_fame_limit_statue{type = Type, data = Master}),

			%% 删除除本游戏线外的其他游戏线的缓存，需要它们重新从db中获取
			mod_disperse:send_other_server(ets, delete_all_objects, [?ETS_FAME_LIMIT_STATUE]),

			%% 实时刷新雕像
			{ok, BinData} = pt_220:write(22030, [[Type, Master]]),
			lib_server_send:send_to_scene(?SCENE_CHANG_AN, 0, BinData)
	end.

%% 刷新排行榜
refresh_fame_limit_rank() ->
	private_refresh_coin(),
	private_refresh_taobao(),
	private_refresh_exp(),
	private_refresh_pt().

%% 获得礼包
get_gift(8001, 1) -> 534014;
get_gift(8001, 2) -> 534015;
get_gift(8001, 3) -> 534016;
get_gift(8001, 4) -> 534017;
get_gift(8002, 1) -> 534018;
get_gift(8002, 2) -> 534019;
get_gift(8002, 3) -> 534020;
get_gift(8002, 4) -> 534021;
get_gift(8003, 1) -> 534022;
get_gift(8003, 2) -> 534023;
get_gift(8003, 3) -> 534024;
get_gift(8003, 4) -> 534025;
get_gift(8004, 1) -> 534026;
get_gift(8004, 2) -> 534027;
get_gift(8004, 3) -> 534028;
get_gift(8004, 4) -> 534029;
get_gift(_, _) -> 0. 

%% 初始化数据
private_init_stat(PS) ->
	[TmpV1, TmpV2, TmpV3, TmpV4] = private_get_old_value(PS),
	case mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6052) of
		0 ->
			mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, 6052, 1),
			[0, 0, 0, 0];
		_ ->
			[TmpV1, TmpV2, TmpV3, TmpV4]
	end.

%% 回写数据到数据库，包括铜币，经验，历练，不包括淘宝
private_update_stat(PS, Coin, Exp, PT) ->
	db:execute(
		io_lib:format(?SQL_FAME_LIMIT_UPDATE, [Coin, Exp, PT, PS#player_status.lv, PS#player_status.combat_power, PS#player_status.id])
	).

private_refresh_coin() ->
	Sql = io_lib:format(?SQL_FAME_RANK_COIN, [?NUM_LIMIT]),
	List = db:get_all(Sql),
	RankRecord = private_make_rank_info(?RK_FAME_COIN, List),
	ets:insert(?ETS_FAME_LIMIT_RANK, RankRecord).

private_refresh_taobao() ->
	Sql = io_lib:format(?SQL_FAME_RANK_TAOBAO, [?NUM_LIMIT]),
	List = db:get_all(Sql),
	RankRecord = private_make_rank_info(?RK_FAME_TAOBAO, List),
	ets:insert(?ETS_FAME_LIMIT_RANK, RankRecord).

private_refresh_exp() ->
	Sql = io_lib:format(?SQL_FAME_RANK_EXP, [?NUM_LIMIT]),
	List = db:get_all(Sql),
	RankRecord = private_make_rank_info(?RK_FAME_EXP, List),
	ets:insert(?ETS_FAME_LIMIT_RANK, RankRecord).

private_refresh_pt() ->
	Sql = io_lib:format(?SQL_FAME_RANK_PT, [?NUM_LIMIT]),
	List = db:get_all(Sql),
	RankRecord = private_make_rank_info(?RK_FAME_PT, List),
	ets:insert(?ETS_FAME_LIMIT_RANK, RankRecord).

private_set_first_rank() ->
	ok.

%% 刷新玩家称号
private_refresh_design(ModuleId, RankList) ->
	Len = length(RankList),
	case Len > 0 of
		true ->
			%% 刷新排行第1名玩家的称号
			RoleId = private_get_first_roleid(RankList),
			case is_integer(RoleId) of
				true ->
				    	%% 绑定第一名称号
					private_refresh_first_design(ModuleId, RoleId);
				_ ->
					skip
			end;
		_ ->
			skip
	end.

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
private_refresh_first_design(ModuleId, RoleId) ->
	case private_get_design_id(ModuleId) of
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
private_refresh_second_to_ten_design(ModuleId, NewIds) ->
	case private_get_design_id(ModuleId) of
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

%% 构造排行榜数据在ets中的record
private_make_rank_info(RankType, List) ->
    #ets_fame_limit_rank{type_id = RankType, rank_list = List}.

%% 获得旧的数值
private_get_old_value(PS) ->
	case PS#player_status.fame_limit of
		[Coin, Taobao, Exp, PT] ->
			[Coin, Taobao, Exp, PT];
		_ ->
			Sql = io_lib:format(?SQL_FAME_LIMIT_SELECT, [PS#player_status.id]),
			case db:get_row(Sql) of
				[V1, V2, V3, V4, _Level, _Power] ->
					[V1, V2, V3, V4];
				_ ->
					db:execute(
						io_lib:format(?SQL_FAME_LIMIT_INSERT, [PS#player_status.id])
					),
					[0, 0, 0, 0]
			end
	end.

%% 格式化数值
private_format_data({coin, Value}, [V1, V2, V3, V4]) -> [V1 + Value, V2, V3, V4];
private_format_data({taobao, Value}, [V1, V2, V3, V4]) -> [V1, V2 + Value, V3, V4];
private_format_data({exp, Value}, [V1, V2, V3, V4]) -> [V1, V2, V3 + Value, V4];
private_format_data({pt, Value}, [V1, V2, V3, V4]) -> [V1, V2, V3, V4 + Value].

%% 取出称号id
private_get_design_id(?FAME_LIMIT_RANK_COIN) -> 201405;
private_get_design_id(?FAME_LIMIT_RANK_TAOBAO) -> 201406;
private_get_design_id(?FAME_LIMIT_RANK_EXP) -> 201403;
private_get_design_id(?FAME_LIMIT_RANK_PT) -> 201404;
private_get_design_id(_) -> 0.

%% 发送邮件奖励
private_send_award_email() ->
	case ets:tab2list(?ETS_FAME_LIMIT_RANK) of
		[] -> 
			skip;
		List ->
			lists:map(fun(Rd) -> 
				#ets_fame_limit_rank{type_id = Type, rank_list = Data} = Rd,
				private_send_email(Type, Data)
			end, List)
	end.

private_send_email(Type, List) ->
	Len = length(List),
	%% 处理第1名
	case Len > 0 of
		true ->
			FirstElement = lists:nth(1, List),
			[FirstId | _] = FirstElement,
			Title = data_activity_text:get_fame_limit_title(Type),
			Content = data_activity_text:get_fame_limit_content(Type, 1),
			GoodsTypeId = private_get_goodsid_by_gift(get_gift(Type, 1)),
			private_send_gift_mail([FirstId], Title, Content, GoodsTypeId);
		_ ->
			skip
	end,

	%% 处理第2至10名
	List2 = if
		Len < 2 -> [];
		Len < 10 -> lists:sublist(List, 2, Len - 1);
		true -> lists:sublist(List, 2, 9)
	end,
	case List2 of
		[] ->
			skip;
		_ ->
			RoleIds2 = [Id2 || [Id2 | _] <- List2],
			Title2 = data_activity_text:get_fame_limit_title(Type),
			Content2 = data_activity_text:get_fame_limit_content(Type, 2),
			GoodsTypeId2 = private_get_goodsid_by_gift(get_gift(Type, 2)),
			private_send_gift_mail(RoleIds2, Title2, Content2, GoodsTypeId2)
	end,
	
	%% 处理第11至50名
	List3 = if
		Len < 11 -> [];
		Len < 51 -> lists:sublist(List, 11, Len - 10);
		true -> lists:sublist(List, 11, 40)
	end,
	case List3 of
		[] ->
			skip;
		_ ->
			RoleIds3 = [Id3 || [Id3 | _] <- List3],
			Title3 = data_activity_text:get_fame_limit_title(Type),
			Content3 = data_activity_text:get_fame_limit_content(Type, 3),
			GoodsTypeId3 = private_get_goodsid_by_gift(get_gift(Type, 3)),
			private_send_gift_mail(RoleIds3, Title3, Content3, GoodsTypeId3)
	end,

	%% 处理第51至100名
	List4 = if
		Len < 51 -> [];
		Len < 101 -> lists:sublist(List, 51, Len - 50);
		true -> lists:sublist(List, 51, 50)
	end,
	case List4 of
		[] ->
			skip;
		_ ->
			RoleIds4 = [Id4 || [Id4 | _] <- List4],
			Title4 = data_activity_text:get_fame_limit_title(Type),
			Content4 = data_activity_text:get_fame_limit_content(Type, 4),
			GoodsTypeId4 = private_get_goodsid_by_gift(get_gift(Type, 4)),
			private_send_gift_mail(RoleIds4, Title4, Content4, GoodsTypeId4)
	end.

%% 发送礼包邮件
private_send_gift_mail(List, Title, Content, GoodsTypeId) ->
	SendIds = [Id || Id <- List, is_integer(Id), Id > 0],
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
