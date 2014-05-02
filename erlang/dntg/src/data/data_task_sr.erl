%%%------------------------------------------------
%%% File    : data_task_sr
%%% Author  : zhenghehe
%%% Created : 2010-08-28
%%% Description: 平乱任务配置
%%%------------------------------------------------
-module(data_task_sr).
-compile(export_all).

get_task_config(Type, _Args) ->
    case Type of
        maxinum_trigger_daily -> 20;
        min_trigger_lv -> 30;
        task_sr_gift -> 
            if _Args =:= 10 -> [{531331,1}];
               _Args =:= 20 -> [{531332,1}];
               true  -> [{0,0}]
            end;
        refresh_goods -> 501202
    end.

%%奖励加成比例=基础奖励*颜色比例
get_task_sr_award(Colour) ->
    if Colour =:= 0 -> 0.6;
       Colour =:= 1 -> 0.8;
       Colour =:= 2 -> 1;
       Colour =:= 3 -> 1.3;
       Colour =:= 4 -> 1.6;
       true -> 1
    end.


%%平乱任务列表
get_ids(Level) ->
    Lev = util:floor(Level/10),
    if Lev =:= 3 ->
           TaskSrList=[600190,600200,600010,600020,600030,600040,600050,600060,600070,600080,
                       600090,600100,600110,600120,600130,600140,600150,600160,600170,600180,600190];
       Lev =:= 4 ->
           TaskSrList=[600210,600220,600230,600240,600250,600260,600270,600280,600290,600300,
                        600310,600320,600330,600340,600350,600360,600370,600380,600390,600400,600210];
       Lev =:= 5 ->
           TaskSrList=[600410,600420,600430,600440,600450,600460,600470,600480,600490,600500,
                       600510,600520,600530,600540,600550,600560,600570,600580,600590,600600,600410];
       Lev =:= 6 ->
           TaskSrList=[600610,600620,600630,600640,600650,600660,600670,600680,600690,600700,
                       600710,600720,600730,600740,600750,600760,600770,600780,600790,600800,600610];
       Lev =:= 7 ->
           TaskSrList=[600810,600820,600830,600840,600850,600860,600870,600880,600890,600900,
                       600910,600920,600930,600940,600950,600960,600970,600980,600990,601000,600810];
       true ->
           TaskSrList=[600810,600820,600830,600840,600850,600860,600870,600880,600890,600900,
                       600910,600920,600930,600940,600950,600960,600970,600980,600990,601000,600810]
    end,
    [{0,TaskSrList},{1,TaskSrList},{2,TaskSrList},{3,TaskSrList},{4,TaskSrList}].

get_refresh_config(Lv) ->
	if
		Lv =< 49 ->
			% 颜色 初始概率  刷新概率
			[
				[0, 35, 35],
				[1, 30, 30],
				[2, 19, 19],
				[3, 10, 10],
				[4, 6, 6]
			];
		true ->
			% 颜色 初始概率  刷新概率
            [
                [0, 35, 35],
                [1, 30, 30],
                [2, 19, 19],
                [3, 10, 10],
                [4, 6, 6]
            ]
	end.

get_refresh_config_new(Lv) ->
    if
        Lv =< 49 ->
            % 颜色 初始概率  刷新概率
            [
                {0,1,70},
                {1,2,60},
                {2,3,50},
                {3,4,40},
                {4,4,100}
            ];
        true ->
            % 颜色 初始概率  刷新概率
            [
                {0,1,70},
                {1,2,60},
                {2,3,50},
                {3,4,40},
                {4,4,100}
            ]
    end.
    

%% 依据级别获取刷新铜钱
get_refresh_cost(Level) ->
    if
        Level >= 30 andalso Level =< 39 ->
            500;
        Level >= 40 andalso Level =< 49 ->
            1000;
		Level >= 50 andalso Level =< 59 ->
            1500;
		Level >= 60 andalso Level =< 69 ->
            2000;
		Level >= 70 andalso Level =< 79 ->
            2500;
        true ->
            3000
    end.

%% 刷新保底次数
get_refresh_lim(ColorTarget) ->
	TupleList = 
	[
		{0, 3},
		{1, 3},
		{2, 5},
		{3, 8},
		{4, 10}
	],
	{_, Lim} = lists:keyfind(ColorTarget, 1, TupleList),
	Lim.	

refresh_task_sr_init_color(Lv) ->
    RefreshConfig = get_refresh_config(Lv),
    Sum = lists:foldl(fun([_, Probability, _], Acc)-> Probability+Acc end, 0, RefreshConfig),
    Rand = util:rand(1, Sum),
    refresh_task_sr_init_color_helper(Rand, RefreshConfig, 0).

refresh_task_sr_init_color_helper(_Rand, [], _Acc) ->
    4;
refresh_task_sr_init_color_helper(Rand, [H|T], Acc) ->
    [Color, Probability, _] = H,
    if
        Rand =< Probability+Acc ->
            Color;
        true ->
            refresh_task_sr_init_color_helper(Rand, T, Probability+Acc)
    end.

refresh_task_sr_color(Lv,Color) ->
    RefreshConfig = get_refresh_config_new(Lv),
    case lists:keyfind(Color, 1, RefreshConfig) of
        false ->
            0;
        {C1, C2, Pro} ->
            Rand = util:rand(1, 100),
            case Rand =< Pro of
                true ->
                    C2;
                false ->
                    C1
            end
    end.

refresh_task_sr_color_helper(_Rand, [], _Acc) ->
    4;
refresh_task_sr_color_helper(Rand, [H|T], Acc) ->
    [Color, _, Probability] = H,
    if
        Rand =< Probability+Acc ->
            Color;
        true ->
            refresh_task_sr_color_helper(Rand, T, Probability+Acc)
    end.