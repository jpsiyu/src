%%%------------------------------------------------
%%% File    : data_task_eb
%%% Author  : zhenghehe
%%% Created : 2010-08-28
%%% Description: 皇榜任务配置
%%%------------------------------------------------
-module(data_task_eb).
-compile(export_all).

get_task_config(Type, _Args) ->
    case Type of
        sys_refresh_task_num -> 10;
        maxinum_trigger_daily -> 20;
        min_trigger_lv -> 26;
        maxinum_trigger_everytime -> 2;
        refresh_goods -> 501203
    end.

get_sys_refresh_config() ->
    % 任务品质  随机概率    最多个数
    [
    [0, 48, 7],
    [1, 19, 4],
    [2, 18, 4],
    [3, 10, 2],
    [4, 5, 1]    
    ].

get_finish_refresh_config() ->
    % 任务品质  概率
    [[0, 45],
    [1, 25],
    [2, 15],
    [3, 10],
    [4, 5]].

get_gold_refresh_config(Lv) ->
	if 
		Lv =<49 ->
			% 任务品质  概率
			[
				[0, 15, 5],
				[1, 35, 4],
				[2, 30, 4],
				[3, 15, 3],
				[4, 5, 1]
			];
		Lv =<59 ->
			% 任务品质  概率
			[
				[0, 15, 5],
				[1, 35, 4],
				[2, 36, 4],
				[3, 10, 3],
				[4, 4, 1]
			];
		true ->
			% 任务品质  概率
			[
				[0, 15, 5],
				[1, 35, 4],
				[2, 39, 4],
				[3, 8, 3],
				[4, 3, 1]
			]
	
	end.

%%get_gold_refresh_config() ->
%%    [{60, [[0, 38,  5],[1, 24,  4],[2, 19,  4],[3, 15,  3],[4, 4,  1]]},
%%    {30, [[0, 36,  5],[1, 22,  4],[2, 21,  5],[3, 14,  3],[4, 7,  2]]},
%%    {10, [[0, 32,  5],[1, 19,  4],[2, 23,  5],[3, 16,  3],[4, 10, 2]]}].

get_gold_refresh_cost(Level) ->
    if
        Level >= 30 andalso Level =< 39 ->
            3000;
        Level >= 40 andalso Level =< 49 ->
            6000;
        true ->
            10000
    end.

gold_refresh_lottery_color2(Lv) ->
    GoldRefreshConfig = get_gold_refresh_config(Lv),
    Sum = lists:foldl(fun({Probability, _}, Acc0)-> Probability+Acc0 end, 0, GoldRefreshConfig),
    Rand = util:rand(1, Sum),
    gold_refresh_lottery_color2_helper(Rand, GoldRefreshConfig, 0).

gold_refresh_lottery_color2_helper(_Rand, [], _Acc) ->
    10;
gold_refresh_lottery_color2_helper(Rand, [H|T], Acc) ->
    {Probability, _} = H,
    if
        Rand =< Acc+Probability ->
            Probability;
        true ->
            gold_refresh_lottery_color2_helper(Rand, T, Probability+Acc)
    end.


