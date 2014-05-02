%%%--------------------------------------
%%% @Module  : lib_achieve_ds
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.11
%%% @Description: 成就数据源
%%%--------------------------------------

-module(lib_achieve_ds).
-include("achieve.hrl").
-export([
	init_data/1,
	clear_data/1,
	get_all/1,
	get_stat/1,
	get_score/1,
	add_score/3,
	get_stat_by_type/2,
	save/1,
	save_stat/1,
	get_row/2,
	insert/4
]).

%% 初始化数据
init_data(RoleId) ->
	%% 加载成就数据
    private_reload(RoleId),
	%% 加载成就统计数据
	[_, TotalScore] = private_reload_stat(RoleId),
	%% 加载成就点数
    private_reload_score(RoleId),
	%% 获得的成就点，相当于等值的气血上限，该返回值会放在#player_status.achieve#status_achieve.attr中
	%% 在计算玩家属性时参与计算
	[TotalScore].

%% 清理数据
clear_data(RoleId) ->
	private_erase_achieve(RoleId),
	erase(?GAME_ACHIEVE_STAT(RoleId)),
	erase(?GAME_ACHIEVE_SCORE(RoleId)).

%% 获取所有成就记录
get_all(RoleId) ->
	List = case get(?GAME_ACHIEVE_ALLID(RoleId)) of
		undefined ->
			private_reload(RoleId);
		R ->
			R
	end,
	F = fun(Id) ->
		get(?GAME_ACHIEVE(RoleId, Id))
	end,
	[F(AchieveId) || AchieveId <- List].

%% 获取所有大类统计记录
get_stat(RoleId) ->
	case get(?GAME_ACHIEVE_STAT(RoleId)) of
		undefined ->
			[D, _] = private_reload_stat(RoleId),
			D;
		R ->
			R
	end.

%% 获取玩家成就点数
get_score(RoleId) ->
	case get(?GAME_ACHIEVE_SCORE(RoleId)) of
		undefined ->
			private_reload_score(RoleId);
		R ->
			R
	end.

%% 添加成就点数
add_score(RoleId, AchieveType, AddScore) ->
	%% 保存成就点数
	Score = get_score(RoleId),
	private_save_score(RoleId, Score + AddScore),

	case get_stat_by_type(RoleId, AchieveType) of
		%% 插入统计记录
		[] ->
			save_stat(#role_achieve_stat{id = {RoleId, AchieveType}, score = AddScore});
		RD ->
			NewMaxLevel = private_upgrade_level(
				AchieveType,
				RD#role_achieve_stat.score,
				AddScore,
				RD#role_achieve_stat.maxlevel
			),
			if
				%% 等级
				NewMaxLevel > RD#role_achieve_stat.maxlevel ->
					save_stat(RD#role_achieve_stat{maxlevel = NewMaxLevel, score = RD#role_achieve_stat.score + AddScore});
				true ->
					save_stat(RD#role_achieve_stat{score = RD#role_achieve_stat.score + AddScore})
			end
	end.

%% 通过大类ID取得该大类的统计
get_stat_by_type(RoleId, AchieveType) ->
	case get_stat(RoleId) of
		[] ->
			[];
		List when is_list(List) ->
			case lists:keyfind({RoleId, AchieveType}, #role_achieve_stat.id, List) of
				false ->
					[];
				RD ->
					RD
			end;
		_ ->
			[]
	end.

%% 保存成就数据
save(RD) ->
	{RoleId, AchieveId} = RD#role_achieve.id,
	case get(?GAME_ACHIEVE_ALLID(RoleId)) of
		undefined ->
			private_reload(RoleId);
		List ->
			NewList = [AchieveId | lists:delete(AchieveId, List)],
			put(?GAME_ACHIEVE_ALLID(RoleId), NewList)
	end,
	put(?GAME_ACHIEVE(RoleId, AchieveId), RD),
	db:execute(io_lib:format(?sql_achieve_insert, [RoleId, AchieveId, RD#role_achieve.count, RD#role_achieve.time, RD#role_achieve.getaward])).

%% 保存统计
save_stat(RD) ->
	{RoleId, AchieveType} = RD#role_achieve_stat.id,
	All = get_stat(RoleId),
	Data = [RD | lists:keydelete({RoleId, AchieveType}, #role_achieve_stat.id, All)],
	put(?GAME_ACHIEVE_STAT(RoleId), Data),
	db:execute(
		io_lib:format(?sql_achieve_stat_insert, [
			RoleId,
			AchieveType,
			RD#role_achieve_stat.curlevel,
			RD#role_achieve_stat.maxlevel,
			RD#role_achieve_stat.score]
		)
	).

%% 取一条成就记录
get_row(RoleId, AchieveId) ->
    case get_all(RoleId) of
		[] ->
			[];
		List ->
			case lists:keyfind({RoleId,AchieveId}, #role_achieve.id, List)	of
				false ->
					[];
				RD ->
					RD
			end
	end.

%% 插入新成就记录
insert(RoleId, AchieveId, Count, FinishTime) ->
	RD = #role_achieve{id = {RoleId, AchieveId}, count = Count, time = FinishTime},
	save(RD),
	RD.

%% db玩家成就数据重载到字典中
private_reload(RoleId) ->
	private_erase_achieve(RoleId),
    List = db:get_all(io_lib:format(?sql_achieve_fetch_all, [RoleId])),
    D = private_list_to_record(List, []),
    put(?GAME_ACHIEVE_ALLID(RoleId), D),
	D.

%% 清掉成就数据
private_erase_achieve(RoleId) ->
	case erase(?GAME_ACHIEVE_ALLID(RoleId)) of
		List when is_list(List), List =/= [] ->
			[erase(?GAME_ACHIEVE(RoleId, Id)) || Id <- List];
		_ ->
			skip
	end.

%% 数据表记录转成列表
private_list_to_record([], D) ->
    D;
private_list_to_record([[RoleId, AchieveId, Count, FinishTime, GetAward] | T], D) ->
	put(?GAME_ACHIEVE(RoleId, AchieveId), #role_achieve{id = {RoleId, AchieveId}, count = Count, time = FinishTime, getaward = GetAward}),
	private_list_to_record(
		T,
		[AchieveId | D]
	).

%% db玩家成就统计数据重载到字典中
private_reload_stat(RoleId) ->
	erase(?GAME_ACHIEVE_STAT(RoleId)),
    List = db:get_all(io_lib:format(?sql_achieve_stat_fetch_all, [RoleId])),
    [D, TotalScore] = private_list_to_stat_record(List, [[], 0]),
    put(?GAME_ACHIEVE_STAT(RoleId), D),
    [D, TotalScore].

%% db玩家成就点数重载到字典中
private_reload_score(RoleId) ->
	erase(?GAME_ACHIEVE_SCORE(RoleId)),
	Sql = io_lib:format(?sql_achieve_fetch_score, [RoleId]),
    case db:get_row(Sql) of
        [] -> 
			0;
        [Score] ->
			put(?GAME_ACHIEVE_SCORE(RoleId), Score),
			Score
    end.

%% 升到下一级的等级
private_upgrade_level(AchieveType, NowScore, AddScore, MaxLevel) ->
	LevelScore = data_achieve:get_score_by(AchieveType, MaxLevel),
	if 
		(NowScore + AddScore) >= LevelScore ->
			NewMaxLevel = MaxLevel + 1;
		true ->
			NewMaxLevel = MaxLevel
	end,
	if 
		NewMaxLevel =:= MaxLevel ->
			MaxLevel;
		NewMaxLevel > 4 ->
			4;
		true ->
			NewMaxLevel
	end.

%% 数据表记录转成大类统计列表
private_list_to_stat_record([], [D, TotalScore]) ->
    [D, TotalScore];
private_list_to_stat_record([[RoleId, AchieveType, CurLevel, MaxLevel, Score] | T], [D, TotalScore]) ->
	private_list_to_stat_record(
		T,
		[[#role_achieve_stat{id = {RoleId, AchieveType}, curlevel = CurLevel, maxlevel = MaxLevel, score = Score} | D], TotalScore + Score]
	).

%% 保存成就点数
private_save_score(RoleId, NewScore) ->
	put(?GAME_ACHIEVE_SCORE(RoleId), NewScore).
