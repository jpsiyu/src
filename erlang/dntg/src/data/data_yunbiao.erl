%%%---------------------------------------
%%% @Module  : data_yunbiao
%%% @Author  : zzm
%%% @Email   : ming_up@163.com
%%% @Created : 2010-12-08
%%% @Description:  运镖数据
%%%---------------------------------------

-module(data_yunbiao).
-export([get_yunbiao_config/2
		, put_intercept_times/1
		, put_be_intercept_times/1
		, get_intercept_times/1
		, get_be_intercept_times/1
		, get_skill/1
		, receive_husong_npc/0
		, refresh_husong_npc/2
		, get_husong_phase/1
		, get_husong_phase_hp/1
		, get_husong_phase_buff/1
		, get_husong_phase_reward/2
		, get_husong_phase_config/1
		, get_npc_name/1
		, get_hs_task_id/2
		, get_power_limit/1
		, get_die_scene/0
		, is_probability_100_day/0
		, is_unchange_pk_day/0]).

-define(SQL_INSERTORUPDATE,     		"insert into log_husong_score set player_id=~p, scores=~p ON DUPLICATE KEY UPDATE scores=~p").
-define(SQL_SELECT_ALL,             	"select player_id, scores from log_husong_score").
-define(SQL_SELECT_ONE,             	"select scores from log_husong_score where player_id = ~p").

%% 增加玩家劫镖次数(每日)
put_intercept_times(RoleId) ->
	mod_daily_dict:increment(RoleId, 10002).

%% 增加玩家被劫镖次数(每日)
put_be_intercept_times(RoleId) ->
	mod_daily_dict:increment(RoleId, 10003).

%% 获取玩家劫镖次数(每日)
get_intercept_times(RoleId) ->
	mod_daily_dict:get_count(RoleId, 10002).

%% 获取玩家被劫镖次数(每日)
get_be_intercept_times(RoleId) ->
	mod_daily_dict:get_count(RoleId, 10003).

get_yunbiao_config(Type, _Args) ->
    case Type of
        reduce_speed -> 80;
        refresh_goods -> 612501;
        refresh_cost -> 10000;
        call_cost -> 20;
        maxinum_skill_trigger -> 1
    end.

get_npc_name(HusongColor) ->
    NpcNames = [{1, "彩女"},
    {2, "御女"},
    {3, "美人"},
    {4, "婕妤"},
    {5, "昭仪"}],
    {_, Name} = lists:nth(HusongColor, NpcNames),
    Name.
  
get_receive_config() ->
	case data_yunbiao:is_probability_100_day() of
		true ->
			[
			%% 颜色，概率
			{1, 0}, %% 白色
			{2, 0}, %% 绿色
			{3, 0},  %% 蓝色
			{4, 0},  %% 紫色
			{5, 100}   %% 橙色
			];
		false ->
			[
			%% 颜色，概率
			{1, 80}, %% 白色
			{2, 10}, %% 绿色
			{3, 7},  %% 蓝色
			{4, 2},  %% 紫色
			{5, 1}   %% 橙色
			]
	end.
    
%% 刷新护送NPC颜色
receive_husong_npc() ->
    RefreshConfig = get_receive_config(),
    Sum = lists:foldl(fun({_, Probability}, Acc)-> Probability+Acc end, 0, RefreshConfig),
    Rand = util:rand(1, Sum),
    receive_husong_npc_helper(Rand, RefreshConfig, 0).

receive_husong_npc_helper(_Rand, [], _Acc) ->
    1;
receive_husong_npc_helper(Rand, [H|T], Acc) ->
    {Color, Probability} = H,
    if
        Rand =< Probability+Acc ->
            Color;
        true ->
            receive_husong_npc_helper(Rand, T, Probability+Acc)
    end.
    
get_refresh_config(Lv) ->
    if
        Lv =< 39 ->
            [
                {1, 2, 50},
                {2, 3, 40},
                {3, 4, 30},
                {4, 5, 20}
            ];
        Lv =< 54 ->
            [
                {1, 2, 50},
                {2, 3, 35},
                {3, 4, 25},
                {4, 5, 12}
            ];
        Lv =< 66 ->
            [
                {1, 2, 50},
                {2, 3, 30},
                {3, 4, 20},
                {4, 5, 10}
            ];
        Lv =< 78 ->
            [
                {1, 2, 50},
                {2, 3, 30},
                {3, 4, 20},
                {4, 5, 10}
            ];
        true ->
            [
                {1, 2, 50},
                {2, 3, 30},
                {3, 4, 20},
                {4, 5, 10}
            ]
    end.

%% 刷新护送NPC颜色
refresh_husong_npc(Color, Lv) ->
    RefreshConfig = get_refresh_config(Lv),
    case lists:keyfind(Color, 1, RefreshConfig) of
        false ->
            failed;
        {C1, C2, Pro} ->
            Rand = util:rand(1, 100),
            case Rand =< Pro of
                true ->
                    C2;
                false ->
                    C1
            end
    end.

%%　护送奖励配置
%%　@return 任务等级, 奖励, [颜色, 经验奖励, 铜币奖励]
get_husong_phase_config(Level) ->
    if
        Level>=30 andalso Level=<39 -> 
            {1, 15000
			, [{1,22785,3900}, {2,30380,4900}, {3,37975,6000}, {4,49367,8050}, {5,60760,9500}]
			, 1500, 1500};
        Level>=40 andalso Level=<49 -> 
            {2, 20000
			, [{1,37665,6500}, {2,50220,8000}, {3,62775,10000}, {4,81607,13200}, {5,100440,16000}]
			, 2000, 2000};
        Level>=50 andalso Level=<59 -> 
            {3, 32000
			, [{1,56265,9750}, {2,75020,11250}, {3,93775,14250}, {4,122000,15000}, {5,150000,18000}]
			, 2500, 2500};
        Level>=60 andalso Level=<69 -> 
            {4, 45000
			,[{1,78585,13000}, {2,104780,15000}, {3,130975,19000}, {4,170267,20000}, {5,209560,24000}]
			, 4000, 4000};
        Level>=70 andalso Level=<79 -> 
			{5, 60000
			,[{1,104625,16250}, {2,139500,18750}, {3,174375,23750}, {4,226687,25000}, {5,279000,30000}]
			, 6000, 6000};
        true ->
            {6, 80000
			,[{1,104625,12500}, {2,139500,16250}, {3,174375,18750}, {4,226687,22500}, {5,279000,25000}]
			, 8000, 8000}
    end.

get_husong_phase(Level) ->
    {Phase, _, _, _, _} = get_husong_phase_config(Level),
    Phase.

get_husong_phase_hp(Level) ->
    {_, Hp, _, _, _} = get_husong_phase_config(Level),
    Hp.

get_husong_phase_buff(Level) ->
    {_, Hp, _, Kang, Def} = get_husong_phase_config(Level),
    [Hp, Kang, Def].

get_husong_phase_reward(Level, HusongColor) ->
    {_, _, Rewards, _, _} = get_husong_phase_config(Level),
	case HusongColor >= 1 andalso HusongColor =< 5 of
		false ->
			{11100, 2500};
		true ->
		    case lists:keyfind(HusongColor, 1, Rewards) of
		        {_,Exp,Coin} ->
		            {Exp,Coin};
		        false ->
		            {0,0}
		    end
	end.

get_skill(0) ->
    [0, 100, 3];
get_skill(1) ->
    [1, -50, 5];
get_skill(2) ->
    [2, 10, 5];
get_skill(_) ->
    [0, 0, 0].

%% 运镖死亡后的地点
get_die_scene() ->
	%{102, 113, 124}.
	{102, 103, 122}.

%% 获取运镖任务ID
get_hs_task_id(Lv, Realm) ->
	TList = [
	    {3, [{1, 400010}, {2, 400020}, {3, 400030}]},
	    {4, [{1, 400040}, {2, 400050}, {3, 400060}]},
	    {5, [{1, 400070}, {2, 400080}, {3, 400090}]},
		{6, [{1, 400100}, {2, 400110}, {3, 400120}]},
		{7, [{1, 400130}, {2, 400140}, {3, 400150}]}
    ],
	LvLim = Lv div 10,
	case lists:keyfind(LvLim, 1, TList) of
		false ->
			400010;
		{_, TList2} ->
			case lists:keyfind(Realm, 1, TList2) of
				{_, Tid} ->
					Tid;
				_ ->
					400010
			end
	end.
		
%% 获得战斗力限制
get_power_limit(Lv) ->
	TList = [
	    {3, 1000},
	    {4, 2000},
		{5, 4000},
	    {6, 4000},
	    {7, 5000},
		{8, 7000},
	    {9, 8000}
    ],
	case lists:keyfind(Lv, 1, TList) of
		false ->
			0;
		{_, Limit} ->
			Limit
	end.

%% 是否橙色概率百分百日期
is_probability_100_day() ->
	StartDay = util:unixtime({{2012, 12, 31}, {0, 0, 0}}),
	EndDay = util:unixtime({{2013, 1, 1}, {23, 59, 59}}),	
	NowTime = util:unixtime(),
	NowTime>= StartDay andalso NowTime=<EndDay.

%% 是否国运不强制切换PK模式日期
is_unchange_pk_day() ->
	StartDay = util:unixtime({{2013, 2, 1}, {0, 0, 0}}),
	EndDay = util:unixtime({{2013, 2, 15}, {23, 59, 59}}),	
	NowTime = util:unixtime(),
	NowTime>= StartDay andalso NowTime=<EndDay.
