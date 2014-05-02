%%%-------------------------------------------------------------------
%%% @Module	: data_flyer
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 19 Dec 2012
%%% @Description: 
%%%-------------------------------------------------------------------
-module(data_flyer).
-include("flyer.hrl").
-compile(export_all).

%% 产生属性机率列表
get_attr_type_ratio() ->
    %% 1气血 2攻击 3防御 4雷抗 5水抗 6冥抗 7命中 8闪避 9暴击 10坚韧
    [{1,10},{2,8},{3,10},{4,10},{5,10},{6,10},{7,10},{8,10},{9,11},{10,11}].

%% 产生星星类型机率列表
get_star_type_ratio() ->
    [{1,0},{2,0},{3,316},{4,318},{5,316},{6,314},{7,312},{8,310},{9,308},{10,306},{11,304},{12,303},{13,302},{14,301},{15,300},{16,0},{17,0},{18,0},{19,0},{20,0},{21,220},{22,220},{23,220},{24,220},{25,220},{26,220},{27,220},{28,220},{29,220},{30,220},{31,218},{32,216},{33,214},{34,212},{35,210},{36,208},{37,206},{38,204},{39,202},{40,200},{41,0},{42,0},{43,0},{44,0},{45,0},{46,0},{47,0},{48,0},{49,0},{50,0},{51,110},{52,108},{53,105},{54,102},{55,99},{56,96},{57,93},{58,90},{59,87},{60,84},{61,81},{62,78},{63,75},{64,72},{65,70},{66,0},{67,0},{68,0},{69,0},{70,0},{71,0},{72,0},{73,0},{74,0},{75,0},{76,30},{77,30},{78,30},{79,30},{80,30},{81,30},{82,30},{83,30},{84,30},{85,30},{86,0},{87,0},{88,0},{89,0},{90,0},{91,0},{92,0},{93,0},{94,0},{95,13},{96,11},{97,10},{98,8},{99,6},{100,2}].

%% 具体属性值表
%% {飞行器序号,[{属性,参数},...]}
get_attr_val_ratio() ->
    [
     {1, [{1,0.188},{2,2.809},{3,0.938},{4,0.313},{5,0.313},{6,0.313},{7,0.973},{8,1.168},{9,3.125},{10,1.563}]},
     {2, [{1,0.144},{2,2.161},{3,0.721},{4,0.24},{5,0.24},{6,0.24},{7,0.748},{8,0.898},{9,2.404},{10,1.202}]},
     {3, [{1,0.112},{2,1.674},{3,0.559},{4,0.186},{5,0.186},{6,0.186},{7,0.58},{8,0.696},{9,1.863},{10,0.931}]},
     {4, [{1,0.09},{2,1.354},{3,0.452},{4,0.151},{5,0.151},{6,0.151},{7,0.469},{8,0.563},{9,1.507},{10,0.753}]},
     {5, [{1,0.075},{2,1.128},{3,0.376},{4,0.125},{5,0.125},{6,0.125},{7,0.391},{8,0.469},{9,1.255},{10,0.627}]},
     {6, [{1,0.064},{2,0.96},{3,0.32},{4,0.107},{5,0.107},{6,0.107},{7,0.332},{8,0.399},{9,1.068},{10,0.534}]},
     {7, [{1,0.055},{2,0.83},{3,0.277},{4,0.092},{5,0.092},{6,0.092},{7,0.287},{8,0.345},{9,0.923},{10,0.461}]},
     {8, [{1,0.048},{2,0.726},{3,0.242},{4,0.081},{5,0.081},{6,0.081},{7,0.252},{8,0.302},{9,0.808},{10,0.404}]},
     {9, [{1,0.043},{2,0.642},{3,0.214},{4,0.071},{5,0.071},{6,0.071},{7,0.222},{8,0.267},{9,0.715},{10,0.357}]},
     {10, [{1,0.038},{2,0.573},{3,0.191},{4,0.064},{5,0.064},{6,0.064},{7,0.198},{8,0.238},{9,0.637},{10,0.319}]}
    ].

get_flyer_max_star(Nth) ->
    L = [{1,5},{2,6},{3,8},{4,9},{5,10},{6,12},{7,12},{8,12},{9,12},{10,12}],
    case lists:keyfind(Nth, 1, L) of
	false -> 0;
	{_, Star} -> Star
    end.
	    

get_base_attr(Nth) ->
    L = data_flyer_config:get_base_attr_config(),
    case lists:keyfind(Nth, 1, L) of
	false -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
	{_, R} -> R
    end.
	    
get_max_lv(Nth) ->
    L = data_flyer_config:get_train_cost_config(),
    case lists:keyfind(Nth, 1, L) of
	false -> 0;
	{_, {Lv, _}} -> Lv
    end.

get_train_cost(Nth) ->
    L = data_flyer_config:get_train_cost_config(),
    case lists:keyfind(Nth, 1, L) of
	false -> 0;
	{_, {_, Cost}} -> Cost
    end.

get_speed(Nth) ->    
    L = [{1,8},{2,8},{3,16},{4,16},{5,16},{6,24},{7,24},{8,24},{9,24},{10,32}],
    case lists:keyfind(Nth, 1, L) of
	false -> 0;
	{_, V} -> V
    end.
	    
get_name(Nth) ->
    L = data_flyer_config:get_flyer_name(),
    case lists:keyfind(Nth, 1, L) of
	false -> "";
	{_, V} -> V
    end.


get_upgrade_cost(FlyerNth, StarNum) ->
    L = data_flyer_config:get_upgrade_star_cost(),
    case lists:keyfind(FlyerNth, 1, L) of
	false -> false;
	{_, V} ->
	    case lists:keyfind(StarNum, 1, V) of
		false -> false;
		{_, GoodsNum, Cost} -> {GoodsNum, Cost}
	    end
    end.
    
get_backward_cost(FlyerNth, StarNum) ->
    L = data_flyer_config:get_backward_star_cost(),
    case lists:keyfind(FlyerNth, 1, L) of
	false -> false;
	{_, V} ->
	    case lists:keyfind(StarNum, 1, V) of
		false -> false;
		{_, Cost} -> Cost
	    end
    end.

%% 星星品质
get_one_star_quality(Star) ->
    MinLv = Star#flyer_star.star_value,
    if
	MinLv =< 15 -> 1;
	MinLv =< 40 -> 2;
	MinLv =< 70 -> 3;
	MinLv =< 90 -> 4;
	MinLv =< 100 -> 5;
	true -> 0
    end.

%% 飞行器品质
get_flyer_quality(Nth, Stars) ->
    MaxStar = get_flyer_max_star(Nth),
    StarNum = length(Stars),
    case StarNum =:= MaxStar of
	false -> 1;
	true ->
	    %% 全部星开完才有加成
	    MinLvStar = util:min_ex(Stars, 4),
	    MinLv = MinLvStar#flyer_star.star_value,
	    if
		MinLv =< 15 -> 1;
		MinLv =< 40 -> 2;
		MinLv =< 70 -> 3;
		MinLv =< 90 -> 4;
		MinLv =< 100 -> 5;
		true -> 0
	    end
    end.
%% 全星级加成
get_all_star_addition(Nth, Stars) ->
    Quality = get_flyer_quality(Nth, Stars),
    if
	Quality =:= 1 -> 0;
	Quality =:= 2 -> 0.025;
	Quality =:= 3 -> 0.05;
	Quality =:= 4 -> 0.1;
	Quality =:= 5 -> 0.2;
	true -> 0
    end.

%% 飞行器形象组合参数
get_all_star_figure(Nth, Stars) ->
    Quality = get_flyer_quality(Nth, Stars),
    if
	%% 星星为1
	Quality =:= 1 -> 1;
	Quality =:= 2 -> 1;
	%% 月亮为2
	Quality =:= 3 -> 2;
	Quality =:= 4 -> 2;
	%% 太阳为3
	Quality =:= 5 -> 3;
	true -> 1
    end.
%% 获得飞行器连珠评分
get_all_star_score(Nth, Stars) ->
    case Nth =:= 10 of
	true -> 0;
	false ->
    Quality = get_flyer_quality(Nth, Stars),
    if
	Quality =:= 1 -> 2;
	Quality =:= 2 -> 4;
	Quality =:= 3 -> 6;
	Quality =:= 4 -> 9;
	Quality =:= 5 -> 12;
	true -> 0
    end
    end.
%% X星连珠
get_nine_star_convergence_num(Score) ->
    if
	Score < 12 -> 0;
	Score < 24 -> 1;
	Score < 36 -> 2;
	Score < 48 -> 3;
	Score < 60 -> 4;
	Score < 72 -> 5;
	Score < 84 -> 6;
	Score < 96 -> 7;
	Score < 108 -> 8;
	true -> 9
    end.

get_nine_star_convergence_attr_sub(N, L) ->
    case lists:keyfind(N, 1, L) of
	false -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
	{_, List} -> List
    end.
	    
	    
get_unlock_gold(Nth) ->
    L = [{1,0},{2,200},{3,400},{4,800},{5,1400},{6,2200},{7,3200},{8,4400},{9,6800},{10,10000}],
    case lists:keyfind(Nth, 1, L) of
	false -> 100000;
	{_, V} -> V
    end.
get_backcount(Nth) ->
    L = [{1,125},{2,150},{3,200},{4,225},{5,250},{6,300},{7,300},{8,300},{9,375},{10,375}],
    case lists:keyfind(Nth, 1, L) of
	false -> 100000;
	{_, V} -> V
    end.


is_scene_legal(SceneType, SceneId) ->
    SceneLegal = lists:member(SceneType, [0,1,3,9]) orelse (SceneType =:= 6 andalso SceneId >= 340) orelse lists:member(SceneId, [224,225,226,227]), %合法场景
    SceneIlegal = lists:member(SceneId, [251,253,254,255,256]), %跨服比赛场景
    if
	SceneIlegal =:= true -> false;
	SceneLegal =:= true -> true;
	true -> false
    end.
	    
    
