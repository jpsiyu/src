
%%%---------------------------------------
%%% @Module  : data_pet_potential
%%% @Author  : zhenghehe
%%% @Created : 2011-11-22
%%% @Description:  宠物潜能配置
%%%---------------------------------------
-module(data_pet_potential).
-include("pet.hrl").
-compile(export_all).
get(1) ->
    #ets_base_pet_potential{id=1, lv=0, name= <<"精气">> }; %血誓
get(2) ->
    #ets_base_pet_potential{id=2, lv=0, name= <<"内力">> }; %圣逾
get(3) ->
    #ets_base_pet_potential{id=3, lv=0, name= <<"攻击">> }; %审判
get(4) ->
    #ets_base_pet_potential{id=4, lv=0, name= <<"防御">> }; %神佑
get(5) ->
    #ets_base_pet_potential{id=5, lv=0, name= <<"命中">> }; %疾风
get(6) ->
    #ets_base_pet_potential{id=6, lv=0, name= <<"闪避">> }; %幻影
get(7) ->
    #ets_base_pet_potential{id=7, lv=0, name= <<"暴击">> }; %泯灭
get(8) ->
    #ets_base_pet_potential{id=8, lv=0, name= <<"坚韧">> }; %荆棘
get(9) ->
    #ets_base_pet_potential{id=9, lv=0, name= <<"雷抗">> }; %炽焰
get(10) ->
    #ets_base_pet_potential{id=10, lv=0, name= <<"水抗">> }; %凋零
get(11) ->
    #ets_base_pet_potential{id=11, lv=0, name= <<"冥抗">> }; %黄泉
get(12) ->
    #ets_base_pet_potential{id=12, lv=0, name= <<"经验">> };
get(_Id) ->
    [].

%% 加成不走这里
get_potentials_info() ->
    PotentialsInfo = [
		      { 0 , 80 ,  [{0 , 0} , 0, 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ]},
		      { 1 , 120 ,  [{200 , 40} , 40, 20 , 24 , 10 , 8 , 4 , 8 , 33 , 33 , 33 ]},
		      { 2 , 180 ,  [{400 , 80} , 80, 40 , 48 , 20 , 16 , 8 , 16 , 66 , 66 , 66 ]},
		      { 3 , 260 ,  [{600 , 120} , 120, 60 , 72 , 30 , 24 , 12 , 24 , 99 , 99 , 99 ]},
		      { 4 , 360 ,  [{800 , 160} , 160, 80 , 96 , 40 , 32 , 16 , 32 , 132 , 132 , 132 ]},
		      { 5 , 480 ,  [{1000 , 200} , 200, 100 , 120 , 50 , 40 , 20 , 40 , 165 , 165 , 165 ]},
		      { 6 , 620 ,  [{1200 , 240} , 240, 120 , 144 , 60 , 48 , 24 , 48 , 198 , 198 , 198 ]},
		      { 7 , 780 ,  [{1400 , 280} , 280, 140 , 168 , 70 , 56 , 28 , 56 , 231 , 231 , 231 ]},
		      { 8 , 960 ,  [{1600 , 320} , 320, 160 , 192 , 80 , 64 , 32 , 64 , 264 , 264 , 264 ]},
		      { 9 , 1040 ,  [{1800 , 360} , 360, 180 , 216 , 90 , 72 , 36 , 72 , 297 , 297 , 297 ]},
		      { 10 , 700 ,  [{2000 , 400} , 400, 200 , 240 , 100 , 80 , 40 , 80 , 330 , 330 , 330 ]},
		      { 11 , 850 ,  [{2200 , 440} , 440, 220 , 264 , 110 , 88 , 44 , 88 , 363 , 363 , 363 ]},
		      { 12 , 1000 ,  [{2400 , 480} , 480, 240 , 288 , 120 , 96 , 48 , 96 , 396 , 396 , 396 ]},
		      { 13 , 1150 ,  [{2600 , 520} , 520, 260 , 312 , 130 , 104 , 52 , 104 , 429 , 429 , 429 ]},
		      { 14 , 1300 ,  [{2800 , 560} , 560, 280 , 336 , 140 , 112 , 56 , 112 , 462 , 462 , 462 ]},
		      { 15 , 1450 ,  [{3000 , 600} , 600, 300 , 360 , 150 , 120 , 60 , 120 , 495 , 495 , 495 ]},
		      { 16 , 1600 ,  [{3200 , 640} , 640, 320 , 384 , 160 , 128 , 64 , 128 , 528 , 528 , 528 ]},
		      { 17 , 1750 ,  [{3400 , 680} , 680, 340 , 408 , 170 , 136 , 68 , 136 , 561 , 561 , 561 ]},
		      { 18 , 1900 ,  [{3600 , 720} , 720, 360 , 432 , 180 , 144 , 72 , 144 , 594 , 594 , 594 ]},
		      { 19 , 2050 ,  [{3800 , 760} , 760, 380 , 456 , 190 , 152 , 76 , 152 , 627 , 627 , 627 ]},
		      { 20 , 1250 ,  [{4000 , 800} , 800, 400 , 480 , 200 , 160 , 80 , 160 , 660 , 660 , 660 ]},
		      { 21 , 1350 ,  [{4200 , 840} , 840, 420 , 504 , 210 , 168 , 84 , 168 , 693 , 693 , 693 ]},
		      { 22 , 1450 ,  [{4400 , 880} , 880, 440 , 528 , 220 , 176 , 88 , 176 , 726 , 726 , 726 ]},
		      { 23 , 1550 ,  [{4600 , 920} , 920, 460 , 552 , 230 , 184 , 92 , 184 , 759 , 759 , 759 ]},
		      { 24 , 1650 ,  [{4800 , 960} , 960, 480 , 576 , 240 , 192 , 96 , 192 , 792 , 792 , 792 ]},
		      { 25 , 1750 ,  [{5000 , 1000} , 1000, 500 , 600 , 250 , 200 , 100 , 200 , 825 , 825 , 825 ]},
		      { 26 , 1850 ,  [{5200 , 1040} , 1040, 520 , 624 , 260 , 208 , 104 , 208 , 858 , 858 , 858 ]},
		      { 27 , 1950 ,  [{5400 , 1080} , 1080, 540 , 648 , 270 , 216 , 108 , 216 , 891 , 891 , 891 ]},
		      { 28 , 2050 ,  [{5600 , 1120} , 1120, 560 , 672 , 280 , 224 , 112 , 224 , 924 , 924 , 924 ]},
		      { 29 , 2150 ,  [{5800 , 1160} , 1160, 580 , 696 , 290 , 232 , 116 , 232 , 957 , 957 , 957 ]},
		      { 30 , 1375 ,  [{6000 , 1200} , 1200, 600 , 720 , 300 , 240 , 120 , 240 , 990 , 990 , 990 ]},
		      { 31 , 1455 ,  [{6200 , 1240} , 1240, 620 , 744 , 310 , 248 , 124 , 248 , 1023 , 1023 , 1023 ]},
		      { 32 , 1540 ,  [{6400 , 1280} , 1280, 640 , 768 , 320 , 256 , 128 , 256 , 1056 , 1056 , 1056 ]},
		      { 33 , 1625 ,  [{6600 , 1320} , 1320, 660 , 792 , 330 , 264 , 132 , 264 , 1089 , 1089 , 1089 ]},
		      { 34 , 1710 ,  [{6800 , 1360} , 1360, 680 , 816 , 340 , 272 , 136 , 272 , 1122 , 1122 , 1122 ]},
		      { 35 , 1795 ,  [{7000 , 1400} , 1400, 700 , 840 , 350 , 280 , 140 , 280 , 1155 , 1155 , 1155 ]},
		      { 36 , 1880 ,  [{7200 , 1440} , 1440, 720 , 864 , 360 , 288 , 144 , 288 , 1188 , 1188 , 1188 ]},
		      { 37 , 1965 ,  [{7400 , 1480} , 1480, 740 , 888 , 370 , 296 , 148 , 296 , 1221 , 1221 , 1221 ]},
		      { 38 , 2050 ,  [{7600 , 1520} , 1520, 760 , 912 , 380 , 304 , 152 , 304 , 1254 , 1254 , 1254 ]},
		      { 39 , 2135 ,  [{7800 , 1560} , 1560, 780 , 936 , 390 , 312 , 156 , 312 , 1287 , 1287 , 1287 ]},
		      { 40 , 1365 ,  [{8000 , 1600} , 1600, 800 , 960 , 400 , 320 , 160 , 320 , 1320 , 1320 , 1320 ]},
		      { 41 , 1435 ,  [{8200 , 1640} , 1640, 820 , 984 , 410 , 328 , 164 , 328 , 1353 , 1353 , 1353 ]},
		      { 42 , 1510 ,  [{8400 , 1680} , 1680, 840 , 1008 , 420 , 336 , 168 , 336 , 1386 , 1386 , 1386 ]},
		      { 43 , 1585 ,  [{8600 , 1720} , 1720, 860 , 1032 , 430 , 344 , 172 , 344 , 1419 , 1419 , 1419 ]},
		      { 44 , 1660 ,  [{8800 , 1760} , 1760, 880 , 1056 , 440 , 352 , 176 , 352 , 1452 , 1452 , 1452 ]},
		      { 45 , 1735 ,  [{9000 , 1800} , 1800, 900 , 1080 , 450 , 360 , 180 , 360 , 1485 , 1485 , 1485 ]},
		      { 46 , 1810 ,  [{9200 , 1840} , 1840, 920 , 1104 , 460 , 368 , 184 , 368 , 1518 , 1518 , 1518 ]},
		      { 47 , 1885 ,  [{9400 , 1880} , 1880, 940 , 1128 , 470 , 376 , 188 , 376 , 1551 , 1551 , 1551 ]},
		      { 48 , 1960 ,  [{9600 , 1920} , 1920, 960 , 1152 , 480 , 384 , 192 , 384 , 1584 , 1584 , 1584 ]},
		      { 49 , 2035 ,  [{9800 , 1960} , 1960, 980 , 1176 , 490 , 392 , 196 , 392 , 1617 , 1617 , 1617 ]},
		      { 50 , 1170 ,  [{10000 , 2000} , 2000, 1000 , 1200 , 500 , 400 , 200 , 400 , 1650 , 1650 , 1650 ]},
		      { 51 , 1205 ,  [{10200 , 2040} , 2040, 1020 , 1224 , 510 , 408 , 204 , 408 , 1683 , 1683 , 1683 ]},
		      { 52 , 1240 ,  [{10400 , 2080} , 2080, 1040 , 1248 , 520 , 416 , 208 , 416 , 1716 , 1716 , 1716 ]},
		      { 53 , 1275 ,  [{10600 , 2120} , 2120, 1060 , 1272 , 530 , 424 , 212 , 424 , 1749 , 1749 , 1749 ]},
		      { 54 , 1310 ,  [{10800 , 2160} , 2160, 1080 , 1296 , 540 , 432 , 216 , 432 , 1782 , 1782 , 1782 ]},
		      { 55 , 1345 ,  [{11000 , 2200} , 2200, 1100 , 1320 , 550 , 440 , 220 , 440 , 1815 , 1815 , 1815 ]},
		      { 56 , 1380 ,  [{11200 , 2240} , 2240, 1120 , 1344 , 560 , 448 , 224 , 448 , 1848 , 1848 , 1848 ]},
		      { 57 , 1415 ,  [{11400 , 2280} , 2280, 1140 , 1368 , 570 , 456 , 228 , 456 , 1881 , 1881 , 1881 ]},
		      { 58 , 1450 ,  [{11600 , 2320} , 2320, 1160 , 1392 , 580 , 464 , 232 , 464 , 1914 , 1914 , 1914 ]},
		      { 59 , 1485 ,  [{11800 , 2360} , 2360, 1180 , 1416 , 590 , 472 , 236 , 472 , 1947 , 1947 , 1947 ]},
		      { 60 , 832 ,  [{12000 , 2400} , 2400, 1200 , 1440 , 600 , 480 , 240 , 480 , 1980 , 1980 , 1980 ]},
		      { 61 , 857 ,  [{12200 , 2440} , 2440, 1220 , 1464 , 610 , 488 , 244 , 488 , 2013 , 2013 , 2013 ]},
		      { 62 , 882 ,  [{12400 , 2480} , 2480, 1240 , 1488 , 620 , 496 , 248 , 496 , 2046 , 2046 , 2046 ]},
		      { 63 , 907 ,  [{12600 , 2520} , 2520, 1260 , 1512 , 630 , 504 , 252 , 504 , 2079 , 2079 , 2079 ]},
		      { 64 , 932 ,  [{12800 , 2560} , 2560, 1280 , 1536 , 640 , 512 , 256 , 512 , 2112 , 2112 , 2112 ]},
		      { 65 , 957 ,  [{13000 , 2600} , 2600, 1300 , 1560 , 650 , 520 , 260 , 520 , 2145 , 2145 , 2145 ]},
		      { 66 , 982 ,  [{13200 , 2640} , 2640, 1320 , 1584 , 660 , 528 , 264 , 528 , 2178 , 2178 , 2178 ]},
		      { 67 , 1007 ,  [{13400 , 2680} , 2680, 1340 , 1608 , 670 , 536 , 268 , 536 , 2211 , 2211 , 2211 ]},
		      { 68 , 1032 ,  [{13600 , 2720} , 2720, 1360 , 1632 , 680 , 544 , 272 , 544 , 2244 , 2244 , 2244 ]},
		      { 69 , 1057 ,  [{13800 , 2760} , 2760, 1380 , 1656 , 690 , 552 , 276 , 552 , 2277 , 2277 , 2277 ]},
		      { 70 , 700 ,  [{14000 , 2800} , 2800, 1400 , 1680 , 700 , 560 , 280 , 560 , 2310 , 2310 , 2310 ]},
		      { 71 , 732 ,  [{14200 , 2840} , 2840, 1420 , 1704 , 710 , 568 , 284 , 568 , 2343 , 2343 , 2343 ]},
		      { 72 , 764 ,  [{14400 , 2880} , 2880, 1440 , 1728 , 720 , 576 , 288 , 576 , 2376 , 2376 , 2376 ]},
		      { 73 , 796 ,  [{14600 , 2920} , 2920, 1460 , 1752 , 730 , 584 , 292 , 584 , 2409 , 2409 , 2409 ]},
		      { 74 , 828 ,  [{14800 , 2960} , 2960, 1480 , 1776 , 740 , 592 , 296 , 592 , 2442 , 2442 , 2442 ]},
		      { 75 , 860 ,  [{15000 , 3000} , 3000, 1500 , 1800 , 750 , 600 , 300 , 600 , 2475 , 2475 , 2475 ]},
		      { 76 , 892 ,  [{15200 , 3040} , 3040, 1520 , 1824 , 760 , 608 , 304 , 608 , 2508 , 2508 , 2508 ]},
		      { 77 , 924 ,  [{15400 , 3080} , 3080, 1540 , 1848 , 770 , 616 , 308 , 616 , 2541 , 2541 , 2541 ]},
		      { 78 , 956 ,  [{15600 , 3120} , 3120, 1560 , 1872 , 780 , 624 , 312 , 624 , 2574 , 2574 , 2574 ]},
		      { 79 , 988 ,  [{15800 , 3160} , 3160, 1580 , 1896 , 790 , 632 , 316 , 632 , 2607 , 2607 , 2607 ]},
		      { 80 , 988 ,  [{16000 , 3200} , 3200, 1600 , 1920 , 800 , 640 , 320 , 640 , 2640 , 2640 , 2640 ]}
		     ],
    PotentialsInfo.

get_level_exp(Level) ->
    PotentialsInfo = get_potentials_info(),
    case Level >= 80 of
	true ->
	    {_Lv, Exp, _} = lists:nth(80, PotentialsInfo);
	false ->
	    {_Lv, Exp, _} = lists:nth(Level+1, PotentialsInfo)
    end,
    Exp.


%% 取潜能类型和经验
get_potentials_type_and_exp() ->
    Rand = util:rand(1,100),
    if 
        Rand =< 5 -> {3, {1, 100, 1}}; 
        Rand =< 13 -> {4, {1, 100, 1}};
        Rand =< 25 -> {5, {1, 100, 1}};
        Rand =< 37 -> {6, {1, 100, 1}};
        Rand =< 47 -> {7, {1, 100, 1}};
        Rand =< 57 -> {8, {1, 100, 1}};
        Rand =< 64 -> {9, {1, 100, 1}};
        Rand =< 76 -> {10, {1, 100, 1}};
        Rand =< 88 -> {11, {1, 100, 1}};
        true -> {1, {1, 100, 1}}
    end.

%% 5倍经验
get_potentials_type_and_exp2() ->
    {Type, {Num, Exp, Rate}} = get_potentials_type_and_exp(),
    Rand = util:rand(1, 100),
    if 
        Rand =< 5 -> {Type, {Num, Exp*5, 5}};
        true -> {Type, {Num, Exp, Rate}}
    end.

%% 取批量潜能经验类型和经验
get_potentials_batch(0, List) -> List;
get_potentials_batch(Times, List) ->
    One = get_potentials_type_and_exp2(),
    get_potentials_batch(Times - 1, [One | List]).

%% 潜能阶段加成倍数
get_potential_level_addition(PotentialAverageLev) ->
    if
        PotentialAverageLev >=10 andalso PotentialAverageLev <20 ->
            1;
        PotentialAverageLev >=20 andalso PotentialAverageLev <30 ->
            2;
        PotentialAverageLev >=30 andalso PotentialAverageLev <40 ->
            3;
        PotentialAverageLev >=40 andalso PotentialAverageLev <50 ->
            4;
        PotentialAverageLev >=50 andalso PotentialAverageLev < 60 ->
            5;
        PotentialAverageLev >=60 andalso PotentialAverageLev < 70 ->
            6;    
        PotentialAverageLev >=70 andalso PotentialAverageLev < 80 ->
            8;
        PotentialAverageLev >=80 ->
            10;
        true ->
            0
    end.

%%潜能阶段加成单倍奖励
calc_potential_phase_addition(PotentialAverageLev) ->
    LevelAddition = get_potential_level_addition(PotentialAverageLev),    
    Hp    = LevelAddition*150, 
    Mp    = LevelAddition*40, 
    Att   = LevelAddition*15, 
    Def   = LevelAddition*20, 
    Hit   = LevelAddition*8, 
    Dodge = LevelAddition*6, 
    Crit  = LevelAddition*3, 
    Ten   = LevelAddition*6, 
    Fire  = LevelAddition*31, 
    Ice   = LevelAddition*31, 
    Drug  = LevelAddition*31,
    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug].

%% 潜能等级加成
get_potential_addition(PotentialLevel, Type) ->
    Hp    = PotentialLevel*150, 
    Mp    = PotentialLevel*40, 
    Att   = PotentialLevel*15, 
    Def   = PotentialLevel*20, 
    Hit   = PotentialLevel*8, 
    Dodge = PotentialLevel*6, 
    Crit  = PotentialLevel*3, 
    Ten   = PotentialLevel*6, 
    Fire  = PotentialLevel*31, 
    Ice   = PotentialLevel*31, 
    Drug  = PotentialLevel*31,
    List = [{Hp, Mp}, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug],
    lists:nth(Type, List).

%% 单次潜能消耗物品数量
%% AverageLev:平均等级
get_single_potential_goods_num(AverageLev) ->
    if  
        AverageLev <10 -> 1;
        AverageLev <20 -> 2;
        AverageLev <30 -> 4;
        AverageLev <40 -> 8;
        AverageLev <50 -> 16;
        AverageLev <60 -> 32;
        AverageLev <70 -> 64;
        true -> 128
    end.
% get_potential_addition(Level, Type) ->
%     PotentialsInfo = get_potentials_info(),
%     case Level >= 80 of
% 	true ->
% 	    {_Lv, _Exp, AdditionList} = lists:nth(80, PotentialsInfo);
% 	false ->
% 	    {_Lv, _Exp, AdditionList} = lists:nth(Level+1, PotentialsInfo)
%     end,
%     lists:nth(Type, AdditionList).

% get_practice_potential_probability_config() ->
%     [
%     {1, 65},    % 精气
%      {2, 0},	 %法力，占位用
%     {3, 61},    % 攻击
%     {4, 70},    % 防御
%     {5, 72},    % 命中
%     {6, 72},    % 闪避
%     {7, 72},    % 暴击
%     {8, 72},    % 坚韧
%     {9, 72},    % 火抗
%     {10, 72},   % 冰抗
%     {11, 72}   % 毒抗
%     %{12, 118} % 潜能经验
%     ].

% get_practice_potential_probability_free_config() ->
%     [
%      {1, 65},    % 精气
%      {2, 0},	 %法力，占位用
%      {3, 61},    % 攻击
%      {4, 70},    % 防御
%      {5, 92},    % 命中
%      {6, 92},    % 闪避
%      {7, 92},    % 暴击
%      {8, 92},    % 坚韧
%      {9, 92},    % 火抗
%      {10, 92},   % 冰抗
%      {11, 92}   % 毒抗
%      %{12, 25} % 潜能经验
%     ].

%% 确定潜能类型
%% PotentialLevels:潜能等级列表
% calc_practice_potential_type(PotentialLevels) when PotentialLevels /= [] ->
%     AverLev = lists:foldl(fun({_Type, _Lev}, Acc) -> _Lev+Acc end, 0, PotentialLevels)/length(PotentialLevels),
%     Type = find_more_than_3time(PotentialLevels, AverLev*3),       %大于平均等级3级以上的潜能
%     PotentialProbability = get_practice_potential_probability_config(),    %从属性概率列表随机确定潜能类型
%     NewPotentialProbability = 
%     if
%         Type =:= 0 ->
%             PotentialProbability;
%         true ->
%             {_, Pro} = lists:nth(Type, PotentialProbability),
%             NewPro = util:ceil(Pro/2),		%获得该潜能的概率减半
%             lists:keyreplace(Type, 1, PotentialProbability, {Type, NewPro})
%     end,
%     Sum = lists:foldl(fun({_Type1, _Pro1}, Acc1) -> _Pro1+Acc1 end, 0, NewPotentialProbability),
%     Rand = util:rand(1, Sum),
%     calc_practice_potential_type_helper(Rand, NewPotentialProbability, 0).
% %% 随机一个潜能
% get_potentials_one(PracticeType) ->
%     PotentialProbability = case PracticeType of
%                   free_practice -> get_practice_potential_probability_free_config();    %从属性概率列表随机确定潜能类型
%                   _ -> get_practice_potential_probability_config()
%               end,
%     TotalRatio = lib_goods_util:get_ratio_total(PotentialProbability, 2),
%     Rand = util:rand(1, TotalRatio),
%     {TypeId, _, Exp} = lib_goods_util:find_ratio(PotentialProbability, 0, Rand, 2),
%     {TypeId, Exp}.
% 随机选出4个潜能类型，其中经验潜能为保底潜能
% get_one_potential_type(PracticeType) ->
%     PotentialProbability = case PracticeType of
% 			       free_practice -> get_practice_potential_probability_free_config();    %从属性概率列表随机确定潜能类型
% 			       _ -> get_practice_potential_probability_config()
% 			   end,
%     TmpList = lists:map(fun(_) ->
% 				TotalRatio = lib_goods_util:get_ratio_total(PotentialProbability, 2),
% 				Rand = util:rand(1, TotalRatio),
% 				{TypeId, _} = lib_goods_util:find_ratio(PotentialProbability, 0, Rand, 2),
% 				TypeId
% 			end, [1]),  
%     TmpList.				%有一个保底经验潜能
% @param: FourType=[11,2,3,5]
% @return: [{Type,{Num, Exp,Mul}},...]->[{11,{1,5,1}},{12,{2,15,3}},...]
% get_potential_exp_by_one(OneType) ->
%     {L1,_} = lists:mapfoldl(fun(X, Acc) ->
% 			   lists:partition(fun(Y) -> X=:=Y end, Acc)
% 			end, OneType, OneType),
%     L2 = lists:filter(fun(X) -> X=/=[] end, L1),
%     lists:map(fun(X) -> {hd(X), get_potential_exp_mul_by_typenum(hd(X), length(X))} end, L2).



    


% %% 获取潜能值与倍率
% get_potential_exp_mul_by_typenum(Type, Num) ->
%     case Type =:= 12 of
% 	true ->
% 	    ExpMulList = [{1,5,1},{2,15,3},{3,25,5},{4,50,10}]; %经验潜能
% 	false ->
% 	    ExpMulList = [{1,5,1},{2,30,3},{3,250,5},{4,0,10}] %其他潜能
%     end,
%     case lists:keyfind(Num, 1, ExpMulList) of
% 	null ->
% 	    hd(ExpMulList);
% 	Finded -> 
% 	    Finded
%     end.

%%[{11,{1,5,1}},{12,{2,15,3}},{类型，{个数，经验，倍率}}...]
% get_potential_exp_batch() ->
%     TypeExpList = lists:map(fun(Type) ->
% 				    Rand = get_rand_exp_by_type(Type),
% 				    {Type, Rand}
% 			    end, [1,3,4,5,6,7,8,9,10,11]),
%     TotalExp = lists:foldl(fun({_, Exp}, Acc) ->
% 				   Acc + Exp
% 			   end, 0, TypeExpList),
%     NewList = adjust_exp(TypeExpList, TotalExp),
%     lists:map(fun({Type,Exp}) ->
% 		      {Type,{1,Exp*5+50,0}}
% 	      end, NewList).
%% 不能传入Type为2,因为Type=:=2内力已经与气血合并成精气
% get_rand_exp_by_type(Type) ->
%     %% {类型,{开始范围,结束范围}}
%     L = [{1, {0, 30}},{3, {0, 28}},{4, {0, 35}},{5, {0, 35}},{6, {0, 35}},{7, {0, 35}},{8, {0, 35}},{9, {0, 35}},{10, {0, 35}},{11, {0, 35}}],
%     {_,{Begin, End}} = lists:keyfind(Type, 1, L),
%     util:rand(Begin, End).

% adjust_exp(TypeExpList, TotalExp) when TotalExp < 80 ->
%     NewList = lists:map(fun({Type,Exp}) ->
% 				Exp1 = case Exp + 1 > 32 of
% 					   true -> 32;
% 					   false -> Exp+1
% 				       end,
% 				{Type, Exp1}
% 			end, TypeExpList),
%     NewTotal = lists:foldl(fun({_, Exp}, Acc) ->
% 				   Acc + Exp
% 			   end, 0, NewList),

%     adjust_exp(NewList, NewTotal);
% adjust_exp(TypeExpList, TotalExp) when TotalExp > 240 ->
%     NewList = lists:map(fun({Type,Exp}) ->
% 				Exp1 = case Exp - 1 < 0 of
% 					   true -> 0;
% 					   false -> Exp-1
% 				       end,
% 				{Type, Exp1}
% 			end, TypeExpList),
%     NewTotal = lists:foldl(fun({_, Exp}, Acc) ->
% 				   Acc + Exp
% 			   end, 0, NewList),

%     adjust_exp(NewList, NewTotal);
% adjust_exp(TypeExpList, _) ->
%     TypeExpList.
	
% find_more_than_3time([], _AverLev3) ->
%     0;
% find_more_than_3time([H|T], AverLev3) ->
%     {Type, Lev} = H,
%     if
%         Lev > AverLev3 ->
%             Type;
%         true ->
%             find_more_than_3time(T, AverLev3)
% end.

% calc_practice_potential_type_helper(_Rand, [], _Acc) ->
%     11;
% calc_practice_potential_type_helper(Rand, [H|T], Acc) ->
%     {Id, Probability} = H,
%     Acc1 = Acc+Probability,
%     if
%         Rand =< Acc1 ->
%             Id;
%         true ->
%             calc_practice_potential_type_helper(Rand, T, Acc1)
%     end.


% get_free_practice_potential_exp() ->
%     ExpProbability = [
% 		      {1, 5, 650},
% 		      {3, 15, 300},
% 		      {5, 25, 45},
% 		      {10, 50, 5}
% 		     ],
%     Sum = lists:foldl(fun({_Mul, _Exp, _Pro}, Acc) -> _Pro+Acc end, 0, ExpProbability),
%     Rand = util:rand(1, Sum),
%     get_practice_potential_exp_helper(Rand, ExpProbability, 0).

% get_practice_potential_exp() ->
%     ExpProbability = [
%     {1, 5, 250},
%     {3, 15, 700},
%     {5, 25, 45},
%     {10, 50, 5}
%     ],
%     Sum = lists:foldl(fun({_Mul, _Exp, _Pro}, Acc) -> _Pro+Acc end, 0, ExpProbability),
%     Rand = util:rand(1, Sum),
%     get_practice_potential_exp_helper(Rand, ExpProbability, 0).

% get_practice_potential_exp_helper(_Rand, [], _Acc) ->
%     50;
% get_practice_potential_exp_helper(Rand, [H|T], Acc) ->
%     {Mul, Exp, Probability} = H,
%     Acc1 = Acc+Probability,
%     if
%         Rand =< Acc1 ->
%             {Mul, Exp};
%         true ->
%             get_practice_potential_exp_helper(Rand, T, Acc1)
%     end.



% get_potential_exp_lv_by_id(PotentialId, PotentialList) ->
%     ExpLvList = lists:map(fun(Potential) -> 
% 				  {Potential#pet_potential.potential_type_id, Potential#pet_potential.exp, Potential#pet_potential.lv}
% 			  end, PotentialList),
%     {_, Exp, Lv} = case lists:keyfind(PotentialId, 1, ExpLvList) of
% 		       false -> {0,0,0};
% 		       R -> R
% 		   end,
%     {Exp, Lv}.
