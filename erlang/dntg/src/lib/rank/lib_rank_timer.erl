%%%--------------------------------------
%%% @Module  : lib_rank_timer
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.11.14
%%% @Description :  排行榜定时器相关
%%%--------------------------------------

-module(lib_rank_timer).
-include("rank.hrl").
-include("sql_rank.hrl").
-export([
	working/0			%% 定时器正常执行刷新	 
]).

%% 定时器正常执行刷新
working() ->
	NowTime = util:unixtime(),

	%% 取出今天已经刷新过的排行榜id列表
	Ids = private_get_id_list(),

	%% 取出一个今天还没刷新的排行榜id
	RankType = private_get_one(?RK_TIMER_REFRESH_IDS, Ids, 0),

	case RankType of
		0 ->
			%% 休眠到第二天0:0:15才开始再次刷新排行榜
			WaitingTime = util:unixdate(NowTime) + 86400 + 15 - NowTime,
			{waiting, WaitingTime};
		_ ->
			spawn(fun() -> 
				%% 更新该排行榜已经刷新
				db:execute(io_lib:format(?SQL_RK_TIMER_INSERT, [RankType, util:unixtime()])),

				%% 开始刷新逻辑
				try lib_rank:refresh_single_by_timer(RankType) of
					_ -> skip
				catch
					_:Error -> util:errlog("lib_rank_timer working = ~p~n", [Error])
				end,

				%% 指定其中一个榜，用来处理其他逻辑
				case RankType =:= ?RK_PERSON_FIGHT of
					true ->
						spawn(fun() -> 
							%% 清玩家3v3 mvp数据
 							Week = util:get_day_of_week(),
							case Week =:= 7 of
								true -> lib_kf_3v3:clean_week_data();
								_ -> skip
							end,

							%% 每逢1号和15号，清3v3被举报次数
							lib_kf_3v3:clean_report_data(),

							%% 周日，发放本服周积分榜奖励
							case Week =:= 7 of
								true -> spawn(fun() -> lib_kf_3v3_rank:send_bd_week_award() end);
								_ -> skip
							end
						end),

						spawn(fun() -> 
							%% 处理斗战封神活动奖励
							lib_activity_kf_power:handle_kf_award(NowTime)
						end);
					_ ->
						skip
				end
			end),

			{waiting, 15}
	end.

%% 取出一个还没刷新的排行榜id
private_get_one([], _Ids, TargetId) -> TargetId;
private_get_one([Id | Tail], Ids, TargetId) ->
	case lists:member(Id, Ids) of
		true -> private_get_one(Tail, Ids, TargetId);
		false -> private_get_one([], Ids, Id)
	end.

%% 取出刷新过的排行榜id列表
private_get_id_list() ->
	case db:get_all(io_lib:format(?SQL_RK_TIMER_GET, [])) of
		[] ->
			[];
		List ->
			DayTime = util:unixdate(),
			[Id || [Id, LastTime] <- List, LastTime >= DayTime]
	end.
