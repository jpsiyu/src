%%%---------------------------------------
%%% @Module  : data_pet
%%% @Author  : shebiao
%%% @Email   : shebiao@126.com
%%% @Created : 2010-06-24
%%% @Description:  宠物配置
%%%---------------------------------------
-module(data_pet).
-compile(export_all).
-include("pet.hrl").

get_pet_config(Type, _Args) ->
    case Type of
        % 宠物卡[类型，子类型]
        goods_pet_card       -> [62, 10];
        % 宠物幻化卡[类型，子类型]
        goods_figure_card       -> [62, 14];
        % 宠物口粮[类型，子类型]
        goods_pet_food      -> [62, 13];
        %% 修行卷[类型，子类型]
        goods_potential_spell -> [62, 48];
        % 成长丹[类型，子类型]
        goods_grow_up_medicine -> [62, 42];
        %% 资质丹
        goods_aptitude_medicine -> [62, 11];
        %% % 宠物成长元宝提升费用
        %% growth_gold_cost -> 100;
        % 孵化后的默认级别
        default_level       -> 1;
        % 孵化后的默认资质
        default_aptitude    -> 30;
        % 每天默认砸蛋机会次数
        default_egg_broken_time -> 1;
        % 每天最大砸蛋机会次数
        maxinum_egg_broken_time -> 2;
        % 宠物容量[基础容量，最大容量]
        capacity            -> [5, 10];
        % 宠物栏购买价格
        buy_capacity_gold   -> 50;
        % 最高级别
        maxinum_level       -> 80;
        % 体力值同步间隔
        strength_sync_interval -> 120;
        % 升级时间允许的误差
        upgrade_inaccuracy  -> 3;
        % 升级经验的最大值
        maxinum_upgrade_exp -> 50000;
        % 每天最大提升宠物成长的次数
        maxinum_growth_time -> 20;
        % 每天免费提升宠物成长次数
        free_growth_time -> 1;
        % 每天前三次宠物提升经验
        first_three_growth_exp -> {ten, 1000};
        % 操作日志保留时间
        log_save_time -> 14*86400;
        % 每天最大改名次数
        maxinum_rename_num -> 5;
        % 潜能最高级
        maxinum_potenial_lv -> 10;
        % 属性还原丹[类型，子类型]
        goods_restore_attr_medicine -> [62, 33];
        % 还童费用
        restore_cost -> 10000;
        %% % 潜能修行费用
        %% practice_potential_cost -> 10;
        %% 批量修行次数
        potential_batch_practice_num -> 10;
        %% 批量成长次数
        grow_up_batch_num -> 10;
        %% 每天免费潜能修行次数
        free_practice_potential -> 1;
        % 融合铜币费用
        derive_cost -> 1000;
        %% 成长丹
        grow_up_goods -> 624201;
        %% 潜能丹 
        potential_goods -> 624801
    end.



%% 获取宠物潜能成长费用，批量成长,潜能通用接口
%% @param:Count:需要成长次数, Already:已经成长次数
get_grow_up_cost_batch(Count, Already, Type) ->
    FreeTimes = case Type of 
        grow ->get_pet_config(free_growth_time, []);
        potential ->get_pet_config(free_practice_potential, [])
    end,
    LeftFreeTimes = FreeTimes - Already,
    case LeftFreeTimes >= 0 of 
        true ->
            Count - LeftFreeTimes;
        false -> 
            Count
    end.		

%% 获取成长值升级经验
%% {成长值，成长升级经验}
get_grow_exp(Growth) ->
    GrowthExpInfo = 
        [
     {0 , 80 },{ 1 , 120 },{ 2 , 180 },{ 3 , 260 },{ 4 , 360 },{ 5 , 480 },{ 6 , 620 },{ 7 , 780 },{ 8 , 960 },{ 9 , 1040 },
     {10 , 700 },{ 11 , 850 },{ 12 , 1000 },{ 13 , 1150 },{ 14 , 1300 },{ 15 , 1450 },{ 16 , 1600 },{ 17 , 1750 },{ 18 , 1900 },{ 19 , 2050 },
	 {20 , 1250 },{ 21 , 1350 },{ 22 , 1450 },{ 23 , 1550 },{ 24 , 1650 },{ 25 , 1750 },{ 26 , 1850 },{ 27 , 1950 },{ 28 , 2050 },{ 29 , 2150 },
	 {30 , 1370 },{ 31 , 1455 },{ 32 , 1540 },{ 33 , 1625 },{ 34 , 1710 },{ 35 , 1795 },{ 36 , 1880 },{ 37 , 1965 },{ 38 , 2050 },{ 39 , 2135 },
	 {40 , 1365 },{ 41 , 1435 },{ 42 , 1510 },{ 43 , 1585 },{ 44 , 1660 },{ 45 , 1735 },{ 46 , 1810 },{ 47 , 1885 },{ 48 , 1960 },{ 49 , 2035 },
	 {50 , 1170 },{ 51 , 1205 },{ 52 , 1240 },{ 53 , 1275 },{ 54 , 1310 },{ 55 , 1345 },{ 56 , 1380 },{ 57 , 1415 },{ 58 , 1450 },{ 59 , 1485 },
	 {60 , 832 },{ 61 , 857 },{ 62 , 882 },{ 63 , 907 },{ 64 , 932 },{ 65 , 957 },{ 66 , 982 },{ 67 , 1007 },{ 68 , 1032 },{ 69 , 1057 },
	 {70 , 700 },{ 71 , 732 },{ 72 , 764 },{ 73 , 796 },{ 74 , 828 },{ 75 , 860 },{ 76 , 892 },{ 77 , 924 },{ 78 , 956 },{ 79 , 988 },
	 {80 , 988}
        ],
    case  lists:keysearch(Growth, 1, GrowthExpInfo) of
        {value, {_, Exp}} -> Exp;
        false -> 988
    end.

%% 获取升级经验
%% {级别，升级经验}
get_upgrade_info(Level) ->
    UpgradeInfo = get_upgrade_exp_info(),
    case  lists:keysearch(Level, 1, UpgradeInfo) of
        {value, {_, UpgradeExp}} -> UpgradeExp;
        false -> 1000000
    end.

get_upgrade_exp_info() ->
    [
     {0, 0},
     {1, 2},{2, 4},{3, 8},{4, 12},{5, 16},{6, 22},{7, 30},{8, 40},{9, 60},{10, 80},
     {11, 100},{12, 200},{13, 400},{14, 600},{15, 800},{16, 1000},{17, 1400},{18, 1900},{19, 2600},{20, 3100},
     {21, 3600},{22, 4100},{23, 4600},{24, 5200},{25, 5800},{26, 6400},{27, 7100},{28, 7900},{29, 8800},{30, 9800},
     {31, 11000},{32, 12500},{33, 14000},{34, 14600},{35, 16000},{36, 17600},{37, 19712},{38, 22077},{39, 24727},{40, 24694},
     {41, 31017},{42, 34739},{43, 38908},{44, 43577},{45, 48806},{46, 54663},{47, 61222},{48, 68569},{49, 76797},{50, 86013},
     {51, 96335},{52, 107895},{53, 120842},{54, 135343},{55, 151585},{56, 169775},{57, 190148},{58, 212965},{59, 238521},{60, 267144},
     {61, 299201},{62, 335105},{63, 375318},{64, 420356},{65, 470799},{66, 527295},{67, 590570},{68, 661438},{69, 740811},{70, 800076},
     {71, 864082},{72, 915927},{73, 970882},{74, 1029135},{75, 1090884},{76, 1156337},{77, 1225717},{78, 1299260},{79, 1377215},{80, 1377215}
    ].

%% 获取最小资质
%% Quality:宠物品质
get_min_aptitude(Quality) ->
    AptitudeList = [30, 46, 61, 91, 101],
    lists:nth(Quality+1, AptitudeList).

%% 快乐值消耗
%% Quality:宠物品质
get_strength_sync_value(Quality) ->
    ValueList = [1, 1, 1, 2, 3],
    lists:nth(Quality+1, ValueList).

%% 获取品质:0白1绿2蓝3紫4橙
%% Aptitude:资质
get_quality(Aptitude) ->
    if
        Aptitude>=0 andalso Aptitude=<300 ->
            0;
        Aptitude>=301 andalso Aptitude=<600 ->
            1;
        Aptitude>=601 andalso Aptitude=<800 ->
            2;
        Aptitude>=801 andalso Aptitude=<1000 ->
            3;
        true ->
            4
    end.

get_strength_threshold(Quality) ->
    StrengthList =  [1000, 1000, 1000, 1000, 1000],
    lists:nth(Quality+1, StrengthList).


%% 通过成长丹获得成长经验
%% @param:GoodsTypeId:成长丹Id
get_growth_exp_by_medicine(GoodsTypeId, GoodsNum) ->
    BaseGoodsPet = lib_pet:get_base_goods_pet(GoodsTypeId),
    if   BaseGoodsPet =:= [] ->
	    util:errlog("pet create config error goods_id=[~p]", [GoodsTypeId]);
	 true ->
	    {medicine, BaseGoodsPet#base_goods_pet.effect * GoodsNum}
    end.

%% 通过潜能丹获得潜能经验
%% @param:GoodsTypeId:潜能丹Id
get_potential_exp_by_medicine(GoodsTypeId, GoodsNum) ->
    BaseGoodsPet = lib_pet:get_base_goods_pet(GoodsTypeId),
    if   BaseGoodsPet =:= [] ->
	    util:errlog("pet create config error goods_id=[~p]", [GoodsTypeId]),
	    {0,0};
	 true ->
	    {BaseGoodsPet#base_goods_pet.effect div 25, BaseGoodsPet#base_goods_pet.effect * GoodsNum}
    end.

%% 通过潜能丹获得潜能经验
%% @param:GoodsTypeId:潜能丹Id
get_upgrade_exp_by_medicine(GoodsTypeId, GoodsNum) ->
    BaseGoodsPet = lib_pet:get_base_goods_pet(GoodsTypeId),
    if   BaseGoodsPet =:= [] ->
	    util:errlog("pet create config error goods_id=[~p]", [GoodsTypeId]),
	    0;
	 true ->
	    BaseGoodsPet#base_goods_pet.effect * GoodsNum
    end.

%% 成长经验
%% Type:coin铜币提升 gold元宝提升 
%% CurrentExp:当前的成长经验
%% NewGrowthExp:每个成长值升级所需经验
get_growth_exp(Type, _CurrentExp, _NewGrowthExp, _Growth) ->
    case Type of
	free ->
            ExpProbability = [
			      {one, 100, 950},
			      {five, 500, 50},
			      {direct, 1, 0}
                             ];
	coin ->
            DirectProbability = 0,                                    
            ExpProbability = [
                             {one, 5, 900},
                             {ten, 50, 100},
                             {direct, 1, DirectProbability}
                             ];
       item  ->
            DirectProbability = 0,
            %% if
            %%     Growth >= 40 -> 0;
            %%     true ->
            %%         if
            %%             CurrentExp < NewGrowthExp/2 -> 0;
            %%             true -> 5
            %%         end
            %% end,
            ExpProbability = [
                             {one, 100, 950},
                             {five, 500, 50},
                             {direct, 1, DirectProbability}
                             ]
            
    end,
    Sum = lists:foldl(fun({_Type, _Exp, _Pro}, Acc) -> _Pro+Acc end, 0, ExpProbability),
    Rand = util:rand(1, Sum),
    get_growth_exp_helper(Rand, ExpProbability, 0).

get_growth_exp_helper(_Rand, [], _Acc) ->
    {direct, 1};
get_growth_exp_helper(Rand, [H|T], Acc) ->
    {_Type, _Exp, _Pro} = H,
    Acc1 = Acc+_Pro,
    if
        Rand =< Acc1 ->
            {_Type, _Exp};
        true ->
            get_growth_exp_helper(Rand, T, Acc1)
    end.

get_growth_addition_config() ->
    %% 宠物成长  加成百分比   加成固定值
    [
     {1,4,4},{2,8,8},{3,12,12},{4,16,16},{5,20,20},{6,24,24},{7,28,28},{8,32,32},{9,36,36},{10,40,40},
     {11,44,44},{12,48,48},{13,52,52},{14,56,56},{15,60,60},{16,64,64},{17,68,68},{18,72,72},{19,76,76},{20,80,80},
     {21,84,84},{22,88,88},{23,92,92},{24,96,96},{25,100,100},{26,104,104},{27,108,108},{28,112,112},{29,116,116},{30,120,120},
     {31,124,124},{32,128,128},{33,132,132},{34,136,136},{35,140,140},{36,144,144},{37,148,148},{38,152,152},{39,156,156},{40,160,160},
     {41,164,164},{42,168,168},{43,172,172},{44,176,176},{45,180,180},{46,184,184},{47,188,188},{48,192,192},{49,196,196},{50,200,200},
     {51,204,204},{52,208,208},{53,212,212},{54,216,216},{55,220,220},{56,224,224},{57,228,228},{58,232,232},{59,236,236},{60,240,240},
     {61,244,244},{62,248,248},{63,252,252},{64,256,256},{65,260,260},{66,264,264},{67,268,268},{68,272,272},{69,276,276},{70,280,280},
     {71,284,284},{72,288,288},{73,292,292},{74,296,296},{75,300,300},{76,304,304},{77,308,308},{78,312,312},{79,316,316},{80,320,320}
    ].

get_growth_addition(Growth) ->
    GrowthAdditionConfig = get_growth_addition_config(),
    case lists:keysearch(Growth, 1, GrowthAdditionConfig) of
        {value, {_, Percentage, Fixed}} ->
            [Percentage, Fixed];
        false ->
            [0, 0]
    end.

get_growth_phase_config() ->
    [% 宠物成长  还童上限    阶段加成    增加砸蛋(概率)    形像效果
     [{0, 9}, 11, 0, 0, {0, 0}],
     [{10, 19}, 20, 20, 0, {0, 0}],
     [{20, 29}, 30, 40, 0, {0, 0}],
     [{30, 39}, 40, 60, 20, {0, 0}],
     [{40, 49}, 50, 80, 30, {0, 0}],
     [{50, 59}, 60, 100, 40, {0, 0}],
     [{60, 69}, 70, 120, 60, {0, 0}],
     [{70, 79}, 80, 140, 80, {0, 0}],
     [{80, 100}, 100, 160, 80, {0, 0}]       %% 这是最高阶
    ].

%% 宠物是否升阶
%% @return: 0否 1是
is_growth_upgrade_phase(OldGrowth, NewGrowth) ->
    List = get_growth_phase_config(),
    F1 = fun([{OldGrowthMin, OldGrowthMax}, _, _, _, _]) ->
		OldGrowth >= OldGrowthMin andalso OldGrowth =< OldGrowthMax
	end,
    OldFilter = lists:filter(F1, List),
    F2 = fun([{NewGrowthMin, NewGrowthMax}, _, _, _, _]) ->
		NewGrowth >= NewGrowthMin andalso NewGrowth =< NewGrowthMax
	end,
    NewFilter = lists:filter(F2, List),
    case OldFilter =:= NewFilter of
	true -> 0;
	false -> 1
    end.	    
%% 分离与成长值有关的配置
get_growth_phase_info(Growth, Type) ->
    GrowthPhaseConfig = get_growth_phase_config(),
    Phase = get_growth_phase(Growth),
    Item = lists:nth(Phase, GrowthPhaseConfig),
    case Type of
        addition ->
            [_, _, Addition, _, _] = Item,
            Addition;
        figure ->
            [_, _, _, _, Figure] = Item,
            Figure;
        err_broken ->
            [_, _, _, ErrBroken, _] = Item,
            Rand = util:rand(0, 100),
            if
                ErrBroken >0 andalso Rand =< ErrBroken -> 1;
                true -> 0
            end;
        max_scale ->
            [_, MaxScale, _, _, _] = Item,
            MaxScale;
        phase ->
            Phase
    end.

%%取单次成长和潜能的物品数量
%% Growth:成长等级
get_single_grow_goods_num(Growth) ->
    Phase = get_growth_phase(Growth),
    case Phase of 
        1 -> 1;
        2 -> 2;
        3 -> 4;
        4 -> 8;
        5 -> 16;
        6 -> 32;
        7 -> 64;
        _ -> 128
    end.

get_growth_phase(Growth) ->
    GrowthPhaseConfig = get_growth_phase_config(),
    get_growth_phase_helper(Growth, GrowthPhaseConfig, 1).
    
get_growth_phase_helper(_, [], _) ->
    1;
get_growth_phase_helper(Growth, [H|T], Pos) ->
    [{Min, Max}, _, _, _, _] = H,
    if
        Growth >= Min andalso Growth =< Max ->
            Pos;
        true ->
            get_growth_phase_helper(Growth, T, Pos+1)
    end.

get_default_growth_scale() ->
    [25, 25, 25, 25].

    
get_growth_scale(Growth) ->
    MaxScale = get_growth_phase_info(Growth, max_scale),
    Rand1 = util:rand(0, MaxScale),
    Rand2 = util:rand(0, MaxScale),
    Rand3 = util:rand(0, MaxScale),
    Rand4 = util:rand(0, MaxScale),
    case Rand1 =:= 0 andalso Rand2 =:= 0 andalso Rand3 =:= 0 andalso Rand4 =:= 0 of
        true ->
            get_growth_scale(Growth);
        false ->
            ForzaScale = util:floor(100*Rand1/(Rand1+Rand2+Rand3+Rand4)),
            WitScale = util:floor(100*Rand2/(Rand1+Rand2+Rand3+Rand4)),
            AgileScale = util:floor(100*Rand3/(Rand1+Rand2+Rand3+Rand4)),
            ThewScale = util:floor(100*Rand4/(Rand1+Rand2+Rand3+Rand4)),
            Rest = 100-ForzaScale-WitScale-AgileScale-ThewScale,
            [NewForzaScale, NewWitScale, NewAgileScale, NewThewScale] = 
            if
                Rest =<0 ->
                    [ForzaScale, WitScale, AgileScale, ThewScale];
                true ->
                    case util:rand(1, 4) of
                        1 ->
                            [ForzaScale+Rest, WitScale, AgileScale, ThewScale];
                        2 ->
                            [ForzaScale, WitScale+Rest, AgileScale, ThewScale];
                        3 ->
                            [ForzaScale, WitScale, AgileScale+Rest, ThewScale];
                        _ ->
                            [ForzaScale, WitScale, AgileScale, ThewScale+Rest]
                    end
            end,
            case NewForzaScale>MaxScale orelse NewWitScale>MaxScale orelse NewAgileScale>MaxScale orelse NewThewScale>MaxScale of
                true ->
                    get_growth_scale(Growth);
                false ->
                    [NewForzaScale, NewWitScale, NewAgileScale, NewThewScale]
            end
    end.

get_egg_broken_cost(PlayerLevel) ->
    if
        PlayerLevel>=1 andalso PlayerLevel=<39 -> 2000;
        PlayerLevel>=40 andalso PlayerLevel=<49 -> 4000;
        PlayerLevel>=50 andalso PlayerLevel=<59 -> 6000;
        PlayerLevel>=60 andalso PlayerLevel=<69 -> 8000;
        PlayerLevel>=70 andalso PlayerLevel=<79 -> 10000;
	PlayerLevel>=80 andalso PlayerLevel=<89 -> 12000;
	PlayerLevel>=90 andalso PlayerLevel=<99 -> 14000;
        true -> 14000
    end.

get_egg_broken_mult(Aptitude) ->
    MultProbabilitys = 
    if
	%% 1倍概率    3倍概率    5倍概率
        Aptitude>=1 andalso Aptitude=<600 ->
	    [{1, 90}, {3, 10}, {5, 0}];
        Aptitude>=601 andalso Aptitude=<800 ->
	    [{1, 80}, {3, 15}, {5, 4}];
        Aptitude>=801 andalso Aptitude=<1000 ->
	    [{1, 70}, {3, 22}, {5, 8}];
        true ->
	    [{1, 70}, {3, 22}, {5, 8}]
    end,
    Sum = lists:foldl(fun({_Mult1, _Pro1}, Acc1) -> _Pro1+Acc1 end, 0, MultProbabilitys),
    Rand = util:rand(1, Sum),
    Mult = get_egg_broken_exp_mult(Rand, MultProbabilitys, 0),
    Mult.

get_egg_broken_exp_mult(_, [], _Acc) ->
    5;
get_egg_broken_exp_mult(Rand, [{Mult, Pro}|T], Acc) ->
    Acc1 = Acc+Pro,
    if
        Rand =< Acc1 -> Mult;
        true ->
            get_egg_broken_exp_mult(Rand, T, Acc1)
    end.

%% 提升成长对额外资质上限的提高
grow_to_aptitudemax(Growth) -> 
    if 
        Growth >= 80 -> 200; 
        Growth >= 75 -> 180;
        Growth >= 70 -> 160;
        Growth >= 65 -> 140;
        Growth >= 60 -> 120; 
        Growth >= 55 -> 105;
        Growth >= 50 -> 90;
        Growth >= 45 -> 75;
        Growth >= 40 -> 60; 
        Growth >= 35 -> 50;
        Growth >= 30 -> 40;
        Growth >= 25 -> 30;
        Growth >= 15 -> 15; 
        Growth >= 10 -> 10;
        Growth >= 5 -> 5;
        true -> 0
    end.

%% 基础资质固有加成
calc_pet_aptitude_attr(BaseAptitude) ->
    if 
        BaseAptitude >= 700 ->
            Hp = round(3*BaseAptitude),
            Att = round(0.08*BaseAptitude),
            Def = round(0.15*BaseAptitude);
        BaseAptitude >= 551 ->
            Hp = round(2*BaseAptitude),
            Att = round(0.06*BaseAptitude),
            Def = round(0.12*BaseAptitude);
        BaseAptitude >= 300 ->
            Hp = round(1.5*BaseAptitude),
            Att = round(0.04*BaseAptitude),
            Def = round(0.08*BaseAptitude);
        true ->
            Hp = round(1*BaseAptitude),
            Att = round(0.03*BaseAptitude),
            Def = round(0.05*BaseAptitude)
    end,
    [Hp, Att, Def].
    
%% 初始化砸蛋cd
get_egg_cd()->
    [{1, 0}, {2, 0}, {3, 0}].

%% 砸蛋的基础配置
get_egg_config(Type)->
    case Type of
        egg_12_loop_times -> 1;
        egg_3_loop_times -> 1;
        _Type ->
            skip
    end.


