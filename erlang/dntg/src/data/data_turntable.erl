%%%-------------------------------------------------------------------
%%% @Module	: data_turntable
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	:  5 Jun 2012
%%% @Description: 转盘数据
%%%-------------------------------------------------------------------
-module(data_turntable).

-compile(export_all).

%% 玩家进入等级要求
get_require_lv() ->
    37.

%% 活动时间
get_activity_time() ->
    {{21, 0, 0}, {22, 0, 0}}.
%% 活动unix时间戳
get_activity_unixtime() ->
    TodayTS = util:unixdate(),
    {{BeginH, BeginM, BeginS}, {EndH, EndM, EndS}} = get_activity_time(),
    BeginTS = TodayTS + BeginH * 3600 + BeginM * 60 + BeginS,
    EndTS = TodayTS + EndH * 3600 + EndM * 60 + EndS,
    {BeginTS, EndTS}.

%% 活动开始日期
get_start_day() ->
    [2, 4, 6].
	%[1,2,3,4,5,6,7].

%% 免费次数
get_free_cnt(VipType) ->
    case VipType =/= 0 of
	true ->
	    2;
	false ->
	    1
    end.

%% 原始概率
get_init_ratio() ->
    L = data_turntable_init:get_goods_list(),
    F = fun(X) ->
		{_, _, _, _, Ratio, _, _} = X,
		Ratio
	end,
    lists:map(F, L).

get_init_goods() ->
    L = data_turntable_init:get_goods_list(),
    F = fun(X) ->
		{_, _, Goods, _, _, _, _} = X,
		Goods
	end,
    lists:map(F, L).

is_precious(GoodsID) ->
    L = data_turntable_init:get_goods_list(),
    case lists:keyfind(GoodsID, 3, L) of
	false ->
	    0;
	{_, _, _, Precious, _, _, _} ->
	    Precious
    end.
    
