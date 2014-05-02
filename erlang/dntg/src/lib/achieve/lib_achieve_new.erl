%%%--------------------------------------
%%% @Module  : lib_achieve_new
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.9
%%% @Description: 成就
%%%--------------------------------------

-module(lib_achieve_new).
-include("server.hrl").
-include("achieve.hrl").
-include("gift.hrl").
-export([
        online/1,
        offline/1,
        get_index_data/1,
        fetch_award_by_type/2,
        fetch_achieve_award/2,
        compare_data/2,
        trigger_task/4,
        trigger_equip/4,
        trigger_role/4,
        trigger_trial/4,
        trigger_social/4,
        trigger_hidden/4,
        admin_modify/3,
        admin_reset_pt/1,
        test_finish_type/2,	%% 秘籍：完成一类成就
        test_finish_one/2	%% 秘籍：完成一个成就
    ]).

%% 上线操作
online(RoleId) ->
	lib_achieve_ds:init_data(RoleId).

%% 下线操作
offline(RoleId) ->
	lib_achieve_ds:clear_data(RoleId).

%% 打开面板获得整个面板需要的数据
get_index_data(RoleId) ->
	TotalScore = lib_achieve_ds:get_score(RoleId),

	%% 成就列表
	All = lib_achieve_ds:get_all(RoleId),
	F2 = fun(RD) ->
		#role_achieve{id={_, AchieveId}, count = Count, time = FinishTime, getaward = GetAward} = RD,
		case data_achieve:get_base(AchieveId) of
			[] ->
				SortType = 1,
				SortId = 1;
			BaseAchieve ->
				SortType = BaseAchieve#base_achieve.sort_type,
				SortId = BaseAchieve#base_achieve.sort_id
		end,
		<<AchieveId:32, Count:32, FinishTime:32, GetAward:8, SortType:32, SortId:8>>
	end,
	AllList = [F2(Item) || Item <- All],

	%% 总览统计
	Stat = lib_achieve_ds:get_stat(RoleId),
	InitData = fun(TypeId) ->
		StatList = lists:filter(fun(RD) -> 
			#role_achieve_stat{id = {_RoleId, AchieveType}, curlevel = _CurLevel, maxlevel = _MaxLevel, score = _Score} = RD,
			if
				AchieveType =:= TypeId ->
					true;
				true ->
					false
			end
		end, Stat),

		case StatList of
			[] ->
				<<TypeId:8, 1:8, 0:8, 0:16>>;
			[Record] ->
				#role_achieve_stat{id = {RoleId, AchieveType}, curlevel = CurLevel, maxlevel = MaxLevel, score = Score} = Record,
				<<AchieveType:8, CurLevel:8, MaxLevel:8, Score:16>>
		end
	end,
	StatList = [InitData(TypeId) || TypeId <- [1,2,4,5,6,7]],

	AllListLen = length(AllList),
	AllListBin = list_to_binary(AllList),
	StatListLen = length(StatList),
	StatListBin = list_to_binary(StatList),
	ScoreLimitUp = data_achieve:get_score_limitup(),
	<<TotalScore:32, ScoreLimitUp:32, AllListLen:16, AllListBin/binary, StatListLen:16, StatListBin/binary>>.

%% 领取大类成长等级奖励
fetch_award_by_type(PS, AchieveType) ->
	RoleId = PS#player_status.id,
	case lib_achieve_ds:get_stat_by_type(RoleId, AchieveType) of
		[] ->
			{error, 2};
		RD ->
			if 
				RD#role_achieve_stat.curlevel > RD#role_achieve_stat.maxlevel ->
					{error, 2};
				true ->
					case data_achieve:get_award_id(AchieveType, RD#role_achieve_stat.curlevel) of
						0 ->
							skip;
						GoodsId ->
							case mod_other_call:send_bind_goods(PS, GoodsId, 1, 2) of
					            ok ->
									{CurLevel, NewMaxLevel} = case RD#role_achieve_stat.curlevel =:= 4 andalso RD#role_achieve_stat.maxlevel =:= 4 of
										true ->
											{RD#role_achieve_stat.curlevel, 3};
										_ ->
											{RD#role_achieve_stat.curlevel + 1, RD#role_achieve_stat.maxlevel}
									end,

									NewRD = RD#role_achieve_stat{curlevel = CurLevel, maxlevel = NewMaxLevel},
									lib_achieve_ds:save_stat(NewRD),
									{ok};
								{fail, Res} ->
									{error, Res};
					         	_ ->
									{error, ?ERROR_GIFT_999}
							end
					end
			end
	end.

%% 领取成就奖励
fetch_achieve_award(RoleId, AchieveId) ->
	case data_achieve:get_base(AchieveId) of
		[] -> {error, 2};
		Achieve ->
			case lib_achieve_ds:get_row(RoleId, AchieveId) of
				[] -> {error, 3};
				RoleAchieve ->
					if
						RoleAchieve#role_achieve.time =< 0 -> {error, 3};
						true ->
							if
								RoleAchieve#role_achieve.getaward =:= 1 -> {error, 4};
								true ->
									%% 增加成就点数
									lib_achieve_ds:add_score(RoleId, Achieve#base_achieve.type, Achieve#base_achieve.score),
									
									%% 更新#player_status.cjpt
									case misc:get_player_process(RoleId) of
								        Pid when is_pid(Pid) ->
											gen_server:cast(Pid, {add_cjpt, [Achieve#base_achieve.score]});
								        _ -> 
								            skip
								    end,

									%% 设置为已经领取奖励
									NewRA = RoleAchieve#role_achieve{getaward = 1},
									lib_achieve_ds:save(NewRA),

									Stat = lib_achieve_ds:get_stat_by_type(RoleId, Achieve#base_achieve.type),
									{ok, lib_achieve_ds:get_score(RoleId), Achieve, Stat#role_achieve_stat.maxlevel, Stat#role_achieve_stat.score}
							end
					end
			end
	end.

%% 1:任务成就
trigger_task(RoleId, TypeId, ActionId, ActionNum) ->
	private_do_action(RoleId, ?ACHIEVE_TYPE_TASK, TypeId, ActionId, ActionNum).

%% 2:神装成就
trigger_equip(RoleId, TypeId, ActionId, ActionNum) ->
	private_do_action(RoleId, ?ACHIEVE_TYPE_EQUIP, TypeId, ActionId, ActionNum).

%% 4:角色成就
trigger_role(RoleId, TypeId, ActionId, ActionNum) ->
	private_do_action(RoleId, ?ACHIEVE_TYPE_ROLE, TypeId, ActionId, ActionNum).

%% 5:试炼成就
trigger_trial(RoleId, TypeId, ActionId, ActionNum) ->
	private_do_action(RoleId, ?ACHIEVE_TYPE_TRIAL, TypeId, ActionId, ActionNum).

%% 6:社会成就
trigger_social(RoleId, TypeId, ActionId, ActionNum) ->
	private_do_action(RoleId, ?ACHIEVE_TYPE_SOCIAL, TypeId, ActionId, ActionNum).

%% 7:隐藏成就
trigger_hidden(RoleId, TypeId, ActionId, ActionNum) ->
	private_do_action(RoleId, ?ACHIEVE_TYPE_HIDDEN, TypeId, ActionId, ActionNum).

%% 跟其他玩家对比成就数据
compare_data(_RoleId, PlayerId) ->
	case private_is_online_by_id(PlayerId) of
		false ->
			{error, 2};
		_ ->
			PlayerScore = lib_achieve_ds:get_score(PlayerId),

			%% 总览统计
			Stat = lib_achieve_ds:get_stat(PlayerId),
			InitData = fun(TypeId) ->
				StatList = lists:filter(fun(RD) -> 
					{_, AchieveType} = RD#role_achieve_stat.id,
					if
						AchieveType =:= TypeId ->
							true;
						true ->
							false
					end
				end, Stat),

				case StatList of
					[] ->
						<<TypeId:8, 0:16>>;
					[Record] ->
						{_, AchieveType} = Record#role_achieve_stat.id,
						Score = Record#role_achieve_stat.score,
						<<AchieveType:8, Score:16>>
				end
			end,
			StatList = [InitData(TypeId) || TypeId <- [1,2,4,5,6,7]],
			{ok, [PlayerScore, StatList]}
	end.

%% TODO: 测试命令用，完成整类成就
test_finish_type(RoleId, Type) ->
    TypeList = data_achieve:get_by_type(Type),
	[test_finish_one(RoleId, BaseAchieve#base_achieve.id) || BaseAchieve <- TypeList],
    ok.

%% TODO: 测试命令用，完成单个成就
test_finish_one(RoleId, AchieveId) ->
	case data_achieve:get_base(AchieveId) of
		[] -> 
			skip;
		BaseInfo ->
			case lib_achieve_ds:get_row(RoleId, AchieveId) of
				[] ->
					_RoleAchieve = lib_achieve_ds:insert(RoleId, AchieveId, BaseInfo#base_achieve.lim_num, util:unixtime()),
				    private_send_notice(RoleId, AchieveId, 0),
				    private_add_design(RoleId, BaseInfo#base_achieve.name_id);
				RoleAchieve ->
					case RoleAchieve#role_achieve.time > 0 of
						true ->
							skip;
						_ ->
							_RoleAchieve = lib_achieve_ds:insert(RoleId, AchieveId, BaseInfo#base_achieve.lim_num, util:unixtime()),
				    		private_send_notice(RoleId, AchieveId, 0),
				    		private_add_design(RoleId, BaseInfo#base_achieve.name_id)
					end
			end
	end.

%% 管理后台修改
%% 只能修改次数，当次数达到完成成就条件时，会修改数据为完成
admin_modify(RoleId, AchieveId, Count) ->
	case is_integer(RoleId) andalso is_integer(AchieveId) and is_integer(Count) of
		true ->
			case data_achieve:get_base(AchieveId) of
				Achieve when is_record(Achieve, base_achieve) ->
					case db:get_one(io_lib:format(<<"SELECT id FROM player_high WHERE id=~p">>, [RoleId])) of
						%% 玩家不存在
						null ->
							4;
						_Id ->
							case db:get_row(io_lib:format(?sql_achieve_get_row, [RoleId, AchieveId])) of
								[TmpCount, Time, GetAward] ->
									case Time =:= 0 of
										true ->
											case Count + TmpCount >= Achieve#base_achieve.lim_num of
												true ->
													InCount = Achieve#base_achieve.lim_num,
													InTime = util:unixtime(),
													InAward = GetAward;
												_ ->
													InCount = Count + TmpCount,
													InTime = 0,
													InAward = GetAward
											end,
											db:execute(io_lib:format(?sql_achieve_update, [InCount, InTime, InAward, RoleId, AchieveId])),
											1;
										%% 成就已经完成
										_ ->
											5
									end;
								_ ->
									case Count >= Achieve#base_achieve.lim_num of
										true ->
											InCount = Achieve#base_achieve.lim_num,
											InTime = util:unixtime(),
											InAward = 0;
										_ ->
											InCount = Count,
											InTime = 0,
											InAward = 0
									end,
									db:execute(io_lib:format(?sql_achieve_insert, [RoleId, AchieveId, InCount, InTime, InAward])),
									1
							end
					end;
				%% 成就不存在
				_ ->
					3
			end;
		%% 参数错误
		_ ->
			2
	end.

%% 管理后台修正玩家成就点
admin_reset_pt(RoleId) ->
	case is_integer(RoleId) of
		true ->
			Sql = <<"SELECT achieve_id, get_award FROM role_achieve WHERE role_id=~p">>,
			case db:get_all(io_lib:format(Sql, [RoleId])) of
				[] ->
					skip;
				List ->
					List2 = [Aid || [Aid, Status] <- List, Status > 0],
					TotalNum = lists:foldl(fun(AchieveId, Num) -> 
						case data_achieve:get_base(AchieveId) of
							[] -> Num;
							Base -> Num + Base#base_achieve.score
						end
					end, 0, List2),

					%% 更新db
					UpdateSql = <<"UPDATE player_pt SET cjpt=~p WHERE id=~p">>,
					db:execute(io_lib:format(UpdateSql, [TotalNum, RoleId])),
					%% 更新玩家身上的值
					case misc:get_player_process(RoleId) of
						Pid when is_pid(Pid) ->
							gen_server:cast(Pid, [{update_cjpt, TotalNum}]);
						_ ->
							skip
					end
			end,
			ok;
		_ ->
			ok
	end.

%% 是否在线
private_is_online_by_id(Id) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            true;
        _ ->
            false
    end.

%% 成就内部处理
private_do_action(RoleId, AchieveType, SonType, ActionId, ActionNum) ->
    case data_achieve:get_by_type_id(AchieveType, SonType) of
		[] ->
			skip;
		BaseList ->
    		lists:foldl(fun private_handle_one/2, [RoleId, ActionId, ActionNum], BaseList)
	end.

%% 成就达成通知
private_send_notice(RoleId, AchieveId, Score) ->
    {ok, BinData} = pt_350:write(35001, [AchieveId, Score]),
    lib_server_send:send_to_uid(RoleId, BinData).

%% 成就统计数量通知
private_send_counter(RoleAchieve) ->
    {RoleId, AchieveId} = RoleAchieve#role_achieve.id,
    {ok, Bin} = pt_350:write(35002, [AchieveId, RoleAchieve#role_achieve.count]),
    lib_server_send:send_to_uid(RoleId, Bin).

%% 获得称号
private_add_design(RoleId, DesignId) ->
	if 
		is_integer(DesignId) andalso (DesignId > 0) ->
			lib_designation:bind_design(RoleId, DesignId, "", 0);
        true -> 
			skip
    end.

%% 单个成就处理
private_handle_one(BaseInfo, [RoleId, TypeId, Num]) ->
    case BaseInfo#base_achieve.type_list =:= [] orelse lists:member(TypeId, BaseInfo#base_achieve.type_list) of
        true ->
            case BaseInfo#base_achieve.is_count > 0 of
                %% 有统计数
                true ->  
                    private_handle_has_count(BaseInfo, RoleId, Num);
                %% 无统计数，只要触发即可完成
                false -> 
                    private_handle_no_count(BaseInfo, RoleId, Num)
            end;
        false -> 
            skip
    end,
    [RoleId, TypeId, Num].

%% 处理有统计的成就
private_handle_has_count(BaseInfo, RoleId, Num) ->
    AchieveId = BaseInfo#base_achieve.id,
    case lib_achieve_ds:get_row(RoleId, AchieveId) of
		%% 第一次触发该类统计
        [] ->
            case Num >= BaseInfo#base_achieve.lim_num of
				%% 达到次数上限，可完成成就
                true ->
		RoleAchieve = lib_achieve_ds:insert(RoleId, AchieveId, Num, util:unixtime()),
                    private_send_notice(RoleId, AchieveId, 0),
                    private_add_design(RoleId, BaseInfo#base_achieve.name_id),
					log:log_chengjiu(RoleId, AchieveId, Num, RoleAchieve#role_achieve.count, lib_achieve_ds:get_score(RoleId));
                _ ->
					RoleAchieve = lib_achieve_ds:insert(RoleId, AchieveId, Num, 0),
                    private_send_counter(RoleAchieve),
					log:log_chengjiu(RoleId, AchieveId, Num, RoleAchieve#role_achieve.count, lib_achieve_ds:get_score(RoleId))
            end;
		%% 如果已经有统计，但还未达成
        RoleAchieve when RoleAchieve#role_achieve.time =:= 0 ->
            case RoleAchieve#role_achieve.count + Num >= BaseInfo#base_achieve.lim_num of
                %% 达到次数上限，可完成成就
				true ->
					NewRD = RoleAchieve#role_achieve{count = RoleAchieve#role_achieve.count + Num, time = util:unixtime()},
					lib_achieve_ds:save(NewRD),
					private_send_notice(RoleId, AchieveId, 0),
					private_add_design(RoleId, BaseInfo#base_achieve.name_id),
					log:log_chengjiu(RoleId, AchieveId, Num, NewRD#role_achieve.count, lib_achieve_ds:get_score(RoleId));
                %% 未成次数上限，继续统计
				_ ->
					NewRD = RoleAchieve#role_achieve{count = RoleAchieve#role_achieve.count + Num},
					lib_achieve_ds:save(NewRD),
                    private_send_counter(NewRD),
					log:log_chengjiu(RoleId, AchieveId, Num, NewRD#role_achieve.count, lib_achieve_ds:get_score(RoleId))
            end;
		%% 数据异常，不处理
        _ -> 
            skip
    end.

%% 处理无统计数的成就
private_handle_no_count(BaseInfo, RoleId, Num) ->
    AchieveId = BaseInfo#base_achieve.id,
    case lib_achieve_ds:get_row(RoleId, AchieveId) of
		%% 不需要统计的成就，没有记录才需要处理
        [] ->
            case BaseInfo#base_achieve.lim_num > 0 andalso Num < BaseInfo#base_achieve.lim_num of
                %% 没达到要求则跳过处理
				true -> 
                    skip;
                _ ->
                    RoleAchieve = lib_achieve_ds:insert(RoleId, AchieveId, Num, util:unixtime()),
                    private_send_notice(RoleId, AchieveId, 0),
                    private_add_design(RoleId, BaseInfo#base_achieve.name_id),
					log:log_chengjiu(RoleId, AchieveId, Num, RoleAchieve#role_achieve.count,  lib_achieve_ds:get_score(RoleId))
            end;
        _ -> 
			skip
    end.
