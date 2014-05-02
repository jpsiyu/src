%%%---------------------------------------
%%% @Module  : data_pet_skill
%%% @Author  : zhenghehe
%%% @Created : 2011-11-22
%%% @Description:  宠物技能配置
%%%---------------------------------------
-module(data_pet_skill).
-compile(export_all).

get_pet_config(Type, _Args) ->
    case Type of
	maxinum_passive_skill -> 8;
        maxinum_trigger_skill -> 2;
	maxinum_active_skill -> 2
    end.
get_pet_potential_skill() ->
    %%潜能级别   技能个数
    [
     {0, 1},
     {0, 2},
     {10, 3},
     {20, 4},
     {30, 5},
     {40, 6},
     {50, 7},
     {60, 8}
    ].
get_max_skill_num(PAL, Growth) ->
    GrowthCell = 
    if
	Growth >= 25 andalso Growth < 35 -> 1;
	Growth >= 35 -> 2;
	true -> 0
    end,
    PALCell =
    if
	PAL < 10 -> 2;
	PAL < 20 -> 3;
	PAL < 30 -> 4;
	PAL < 40 -> 5;
	PAL < 50 -> 6;
	PAL < 60 -> 7;
	PAL < 70 -> 8;
	true -> 8
	%% PAL < 80 -> 9;
	%% true -> 10
    end,
    GrowthCell + PALCell.


%% get_max_skill_num(PotentialAverageLev) ->
%%     PotentialSkillInfo = get_pet_potential_skill(),
%%     get_max_skill_num_helper(PotentialAverageLev, PotentialSkillInfo, {0, 0}).
%% get_max_skill_num_helper(_, [], {_PAL0, Num0}) ->
%%     Num0;
%% get_max_skill_num_helper(PotentialAverageLev, [{PAL, Num}|T], {_PAL0, _Num0}) ->
%%     if
%%         PotentialAverageLev =< PAL ->
%%             Num;
%%         true ->
%%             get_max_skill_num_helper(PotentialAverageLev, T, {PAL, Num})
%%     end.
get_pet_skill_probability(SkillCount) ->
    %%技能个数    替换概率
    SkillProbability = 
	[
	 {1, 0},
	 {2, 50},
	 {3, 55},
	 {4, 60},
	 {5, 70},
	 {6, 80},
	 {7, 85},
	 {8, 90},
	 {9, 90},
	 {10, 90}
	],
    case lists:keysearch(SkillCount, 1, SkillProbability) of
        {value, {_, Probability}} -> Probability;
        false -> 0
    end.
get_skill_books() ->
    [
     621611,621612,621613,621614,
     621711,621712,621713,621714,
     621811,621812,621813,621814,
     621911,621912,621913,621914,
     622011,622012,622013,622014,
     622111,622112,622113,622114,
     622211,622212,622213,622214,
     622311,622312,622313,622314,
     622411,622412,622413,622414,
     622511,622512,622513,622514,
     622611,622612,622613,622614,
     621601,
     621701,
     621801,
     621901,
     622001,
     622101,
     622201,
     622301,
     622401,
     622501,
     622601,
     625111,625112,625113,625114,
     625211,625212,625213,625214,
     625311,625312,625313,625314,
     625411,625412,625413,625414,
     625511,625512,625513,625514,
     625611,625612,625613,625614,
     625711,625712,625713,625714,
     625811,625812,625813,625814
    ].
get_skill_type_by_goods_type(GoodsTypeId) ->
    TypeInfo1 = [
		 621611,621612,621613,621614,
		 621711,621712,621713,621714,
		 621811,621812,621813,621814,
		 621911,621912,621913,621914,
		 622011,622012,622013,622014,
		 622111,622112,622113,622114,
		 622211,622212,622213,622214,
		 622311,622312,622313,622314,
		 622411,622412,622413,622414,
		 622511,622512,622513,622514,
		 622611,622612,622613,622614
		],
    TypeInfo2 = [
		 621601,
		 621701,
		 621801,
		 621901,
		 622001,
		 622101,
		 622201,
		 622301,
		 622401,
		 622501,
		 622601
		],
    TypeInfo3 = [
		 625111,625112,625113,625114,
		 625211,625212,625213,625214,
		 625311,625312,625313,625314,
		 625411,625412,625413,625414,
		 625511,625512,625513,625514,
		 625611,625612,625613,625614,
		 625711,625712,625713,625714,
		 625811,625812,625813,625814
		],
    Type1 = lists:member(GoodsTypeId, TypeInfo1),
    Type2 = lists:member(GoodsTypeId, TypeInfo2),
    Type3 = lists:member(GoodsTypeId, TypeInfo3),
    if
        Type1 =:= true -> 0;			%非触发类
        Type2 =:= true -> 1;			%触发类
        Type3 =:= true -> 2;			%主动技能
        true ->
            error
    end.
%%被动类技能            
get_skill_book_type(GoodsTypeId) ->
    T1 = lists:member(GoodsTypeId, [621611,621612,621613,621614]),
    T2 = lists:member(GoodsTypeId, [621711,621712,621713,621714]),
    T3 = lists:member(GoodsTypeId, [621811,621812,621813,621814]),
    T4 = lists:member(GoodsTypeId, [621911,621912,621913,621914]),
    T5 = lists:member(GoodsTypeId, [622011,622012,622013,622014]),
    T6 = lists:member(GoodsTypeId, [622111,622112,622113,622114]),
    T7 = lists:member(GoodsTypeId, [622211,622212,622213,622214]),
    T8 = lists:member(GoodsTypeId, [622311,622312,622313,622314]),
    T9 = lists:member(GoodsTypeId, [622411,622412,622413,622414]),
    T10 = lists:member(GoodsTypeId, [622511,622512,622513,622514]),
    T11 = lists:member(GoodsTypeId, [622611,622612,622613,622614]),
    if
        T1 =:= true -> 1;
        T2 =:= true -> 2;
        T3 =:= true -> 3;
	T4 =:= true -> 4;
        T5 =:= true -> 5;
        T6 =:= true -> 6;
	T7 =:= true -> 7;
	T8 =:= true -> 8;
	T9 =:= true -> 9;
        T10 =:= true -> 10;
        T11 =:= true -> 11;
	true -> error
    end.
%%触发类技能
get_skill_book_info(GoodsTypeId) ->
    %%{概率，持续时间，类型}
    case GoodsTypeId of
        621601 -> 
            {25, 15, 1};
        621701 -> 
            {25, 16, 2};
        621801 -> 
            {25, 16, 3};
        621901 -> 
            {25, 17, 4};
        622001 -> 
            {25, 18, 5};
        622101 -> 
            {25, 19, 6};
        622201 -> 
            {25, 20, 7};
        622301 -> 
            {25, 21, 8};
        622401 -> 
            {25, 22, 9};
        622501 -> 
            {25, 23, 10};
        622601 -> 
            {25, 24, 11}
    end.

%% 获取技能等级加成系数
get_skill_addition_factor(Type, SkillLv) ->
    LvFac1 = [100, 200, 300, 400],		%气血
    LvFac2 = [11, 22, 33, 44],			%内力
    LvFac3 = [6, 12, 18, 24],	       		%攻击
    LvFac4 = [6, 12, 18, 24],			%防御
    LvFac5 = [3.6, 7.2, 10.8, 14.4],		%命中
    LvFac6 = [3, 6, 9, 12],			%闪避
    LvFac7 = [0.6, 1.2, 1.8, 2.4],		%暴击
    LvFac8 = [1.2, 1.44, 3.6, 4.8],		%坚韧
    LvFac9 = [11, 22, 33, 44],			%火
    LvFac10 = [11, 22, 33, 44],			%水
    LvFac11 = [11, 22, 33, 44],			%毒
    case Type of
	1 -> lists:nth(SkillLv, LvFac1);
	2 -> lists:nth(SkillLv, LvFac2);
	3 -> lists:nth(SkillLv, LvFac3);
	4 -> lists:nth(SkillLv, LvFac4);
	5 -> lists:nth(SkillLv, LvFac5);
	6 -> lists:nth(SkillLv, LvFac6);
	7 -> lists:nth(SkillLv, LvFac7);
	8 -> lists:nth(SkillLv, LvFac8);
	9 -> lists:nth(SkillLv, LvFac9);
	10 -> lists:nth(SkillLv, LvFac10);
	11 -> lists:nth(SkillLv, LvFac11)
    end.
%% 通过技能书ID获取技能等级
get_skill_level_by_goods_type_id(GoodsTypeId) ->
    Lv1 = [621611,621711,621811,621911,622011,622111,622211,622311,622411,622511,622611,
	   625111,625211,625311,625411,625511,625611,625711,625811],
    Type1 = lists:member(GoodsTypeId, Lv1),
    Lv2 = [621612,621712,621812,621912,622012,622112,622212,622312,622412,622512,622612,
	   625112,625212,625312,625412,625512,625612,625712,625812],
    Type2 = lists:member(GoodsTypeId, Lv2),
    Lv3 = [621613,621713,621813,621913,622013,622113,622213,622313,622413,622513,622613,
	   625113,625213,625313,625413,625513,625613,625713,625813],
    Type3 = lists:member(GoodsTypeId, Lv3),
    Lv4 = [621614,621714,621814,621914,622014,622114,622214,622314,622414,622514,622614,
	   625114,625214,625314,625414,625514,625614,625714,625814],
    Type4 = lists:member(GoodsTypeId, Lv4),
    if
	Type1 =:= true -> 1;
	Type2 =:= true -> 2;
	Type3 =:= true -> 3;
	Type4 =:= true -> 4;
	true -> error
    end.
%% 通过物品ID获取某种技能
get_skill_series_by_goods_type_id(GoodsTypeId) ->
    S1 = [621611,621612,621613,621614],T1 = lists:member(GoodsTypeId, S1),
    S2 = [621711,621712,621713,621714],T2 = lists:member(GoodsTypeId, S2),
    S3 = [621811,621812,621813,621814],T3 = lists:member(GoodsTypeId, S3),
    S4 = [621911,621912,621913,621914],T4 = lists:member(GoodsTypeId, S4),
    S5 = [622011,622012,622013,622014],T5 = lists:member(GoodsTypeId, S5),
    S6 = [622111,622112,622113,622114],T6 = lists:member(GoodsTypeId, S6),
    S7 = [622211,622212,622213,622214],T7 = lists:member(GoodsTypeId, S7),
    S8 = [622311,622312,622313,622314],T8 = lists:member(GoodsTypeId, S8),
    S9 = [622411,622412,622413,622414],T9 = lists:member(GoodsTypeId, S9),
    S10 = [622511,622512,622513,622514],T10 = lists:member(GoodsTypeId, S10),
    S11 = [622611,622612,622613,622614],T11 = lists:member(GoodsTypeId, S11),
    S12 = [625111,625112,625113,625114],T12 = lists:member(GoodsTypeId, S12),
    S13 = [625211,625212,625213,625214],T13 = lists:member(GoodsTypeId, S13),
    S14 = [625311,625312,625313,625314],T14 = lists:member(GoodsTypeId, S14),
    S15 = [625411,625412,625413,625414],T15 = lists:member(GoodsTypeId, S15),
    S16 = [625511,625512,625513,625514],T16 = lists:member(GoodsTypeId, S16),
    S17 = [625611,625612,625613,625614],T17 = lists:member(GoodsTypeId, S17),
    S18 = [625711,625712,625713,625714],T18 = lists:member(GoodsTypeId, S18),
    S19 = [625811,625812,625813,625814],T19 = lists:member(GoodsTypeId, S19),
    if
	T1 =:= true -> hd(S1);
	T2 =:= true -> hd(S2);
	T3 =:= true -> hd(S3);
	T4 =:= true -> hd(S4);
	T5 =:= true -> hd(S5);
	T6 =:= true -> hd(S6);
	T7 =:= true -> hd(S7);
	T8 =:= true -> hd(S8);
	T9 =:= true -> hd(S9);
	T10 =:= true -> hd(S10);
	T11 =:= true -> hd(S11);
	T12 =:= true -> hd(S12);
	T13 =:= true -> hd(S13);
	T14 =:= true -> hd(S14);
	T15 =:= true -> hd(S15);
	T16 =:= true -> hd(S16);
	T17 =:= true -> hd(S17);
	T18 =:= true -> hd(S18);
	T19 =:= true -> hd(S19);
	true -> error
    end.
	    
	    
get_refresh_skill_config_by_type(Type) ->
    %% {扣除元宝,增加幸运值,增加祝福值}
    case Type of
	0 -> {0, 5, 0};				%免费
	1 -> {10, 10, 0};			%单次
	2 -> {110, 120, 10}			%批量
    end.
%% 免费刷新技能次数
get_refresh_skill_free_count() ->
    3.

%% 珍贵物品ID
get_precious_goods() ->
    [625001,
     623203,
     122505,
     122506,
     624201,
     621407,
     621408,
     621409,
     621410,
     621411,
     621412
    ].
