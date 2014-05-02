%%------------------------------------------------------------------------------
%%% @Module  : data_story_dun_config
%%% @Author  : liangjianxiong
%%% @Email   : ljianxiong@qq.com
%%% @Created : 2012.12.6
%%% @Description: 剧情副本配置
%%------------------------------------------------------------------------------


-module(data_story_dun_config).


%% 公共函数：外部模块调用.
-export([
		 get_config/1,               %% 得到剧情副本基本配置.
		 get_record_level/3,         %% 得到副本记录登记.
		 get_whpt/1,                 %% 得到武魂值.
		 get_mon_id/1,               %% 得到怪物的id.
		 get_chapter_dungeon_list/1, %% 得到第几章的所有副本列表.
		 get_chapter_id/1,           %% 得到副本是第几章.
		 get_gift_id/1,              %% 得到副本通关礼包ID.
		 get_gift_dungeon_id/1,      %% 得到副本通关礼包所属副本的ID.
         get_base_attribute/1,       %% 得到副本总积分得到的属性加成.
         get_master_reward/1,        %% 得到剧情副本霸主奖励.
         get_dun_id_by_designation/1,%% 得到副本id,by称号id
         get_designation_id_by_dun/1   %% 获取称号id
]).


%% 得到剧情副本基本配置.
get_config(Type)->
	case Type of
		%1.一个副本的挂机时间.
		auto_time -> 180;%%稳定服.
		%auto_time -> 10; %%开发服.
		
		%2.发礼包的副本列表.
		gift_dungeon_list -> [564,567,569,572,575,577,580,583,585];
        %3.所有封魔录的副本id 
        dun_list -> [562, 563, 564, 565, 566, 567, 568, 569, 570,
                     571, 572, 573, 574, 575, 576, 577, 578, 579,
                     580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593];
        %4.获取封魔录默认开始副本id（前两个）
        define_story_dun_id -> [562, 563];
        st_scene_xy -> {3, 21};
		%3.没有定义.
		_-> undefined
	end.


%% 得到副本记录登记.
get_record_level(DungeonId, TotalTime, KillMon) ->
    case DungeonId of
        562 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        563 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        500 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        566 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        567 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        568 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        570 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        564 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        565 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        569 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        574 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        571 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        573 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        572 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        575 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        576 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        577 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;  
        578 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        579 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        580 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        581 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        582 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        583 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;  
        584 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        585 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        586 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        587 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        588 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        589 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;  
        590 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        591 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        592 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        593 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        594 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        595 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        596 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        597 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        598 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        599 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        400 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        401 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        402 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        403 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        404 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        405 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        406 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        407 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        408 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        409 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        610 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        611 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        612 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        613 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        614 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        615 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        616 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        617 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        618 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        619 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        620 -> if KillMon >= 11 andalso TotalTime =< 40 -> 3; KillMon >= 11 andalso TotalTime =< 55 -> 2; true -> 1 end;
        _   -> 1
    end.

%% 得到武魂值
get_whpt(NpcId) ->
    case NpcId of
        56201 ->	100; 
        56404 ->	110;
        30042 ->	120;
        56604 ->	130;
        56704 ->	140;
        56804 ->	150;
        57004 ->	160;
        56414 ->	170;
        56504 ->	180;
        56904 ->	190;
        57404 ->	200;
        57104 ->	210;
        57304 ->	220;
        57204 ->	230;
        57504 ->	240;
        57604 ->	250;
        57705 ->	260;
        57804 ->	270;
        57904 ->	280;
        58004 ->	290;
        58104 ->	300;
        58204 ->	310;
        58304 ->	320;
        58404 ->	330;
        58504 ->	340;
        58604 ->	350;
        58704 ->	360;
        58804 ->	370;
        59004 ->	380;
        58904 ->	390;
        59104 ->	400;
        59204 ->	410;
        59304 ->	420;
        59404 ->	430;
        59504 ->	440;
        59604 ->	450;
        59704 ->	460;
        59804 ->	470;
        59904 ->	480;
        60004 ->	490;
        60104 ->	500;
        60204 ->	510;
        60304 ->	520;
        60404 ->	530;
        60504 ->	540;
        60604 ->	550;
        60704 ->	560;
        60804 ->	570;
        60904 ->	580;
        61004 ->	590;
        61104 ->	600;
        61108 ->	610;
        61112 ->	620;
        61116 ->	630;
        61120 ->	640;
        61124 ->	650;
        61128 ->	660;
        61132 ->	670;
        61136 ->	680;
        61140 ->	690;
        _     ->    0
    end.

%% 得到怪物的id.
get_mon_id(DungeonId) ->
	case DungeonId of
		562 -> 56201; %% No.1.
		563 -> 56404; %% No.2.
		500 -> 30042; %% No.3.
		566 -> 56604; %% No.4.
		567 -> 56704; %% No.5.
		568 -> 56804; %% No.6.
		570 -> 57004; %% No.7.
		564 -> 56414; %% No.8.
		565 -> 56504; %% No.9.
		569 -> 56904; %% No.10.
		574 -> 57404; %% No.11.
		571 -> 57104; %% No.12.
		573 -> 57304; %% No.13.
		572 -> 57204; %% No.14.
		575 -> 57504; %% No.15.
		576 -> 57604; %% No.16.
		577 -> 57705; %% No.17.
		578 -> 57804; %% No.18.
		579 -> 57904; %% No.19.
		580 -> 58004; %% No.20.
		581 -> 58104; %% No.21.
		582 -> 58204; %% No.22.
		583 -> 58304; %% No.23.
		584 -> 58404; %% No.24.
		585 -> 58504; %% No.25.
		586 -> 58604; %% No.26.
		587 -> 58704; %% No.27.
		588 -> 58804; %% No.28.
		589 -> 59004; %% No.29.
		590 -> 58904; %% No.20.
		591 -> 59104; %% No.31.
		592 -> 59204; %% No.32.
		593 -> 59304; %% No.33.
		594 -> 59404; %% No.34.
		595 -> 59504; %% No.35.
		596 -> 59604; %% No.36.
		597 -> 59704; %% No.37.
		598 -> 59804; %% No.38.
		599 -> 59904; %% No.39.
		600 -> 60004; %% No.40.
		601 -> 60104; %% No.41.
		602 -> 60204; %% No.42.
		603 -> 60304; %% No.43.
		604 -> 60404; %% No.44.
		605 -> 60504; %% No.45.
		606 -> 60604; %% No.46.
		607 -> 60704; %% No.47.
		608 -> 60804; %% No.48.
		609 -> 60904; %% No.49.
		610 -> 61004; %% No.50.
		611 -> 61104; %% No.51.
		612 -> 61108; %% No.52.
		613 -> 61112; %% No.53.
		614 -> 61116; %% No.54.
		615 -> 61120; %% No.55.
		616 -> 61124; %% No.56.
		617 -> 61128; %% No.57.
		618 -> 61132; %% No.58.
		619 -> 61136; %% No.59.
		620 -> 61140; %% No.60.
		_ -> 0
	end.

%% 得到第几章的所有副本列表.
get_chapter_dungeon_list(Chapter) ->
    case Chapter of
        1 -> [562,563,564,565,566,567,568,569];%第一章副本ID.
        2 -> [570,571,572,573,574,575,576,577];%第二章副本ID.
        3 -> [578,579,580,581,582,583,584,585];%第三章副本ID.
        4 -> [579,580,581,582,583,584,585,586];%第四章副本ID.
        _ -> []
	end.

%% 得到副本是第几章.
get_chapter_id(DungeonId) ->
	case DungeonId of
		562 -> 1; %% No.1.
		563 -> 1; %% No.2.
		500 -> 1; %% No.3.
		566 -> 1; %% No.4.
		567 -> 1; %% No.5.
		568 -> 1; %% No.6.
		570 -> 1; %% No.7.
		564 -> 1; %% No.8.
		565 -> 1; %% No.9.
		569 -> 1; %% No.10.
		574 -> 2; %% No.11.
		571 -> 2; %% No.12.
		573 -> 2; %% No.13.
		572 -> 2; %% No.14.
		575 -> 2; %% No.15.
		576 -> 2; %% No.16.
		577 -> 2; %% No.17.
		578 -> 2; %% No.18.
		579 -> 2; %% No.19.
		580 -> 2; %% No.20.
		581 -> 3; %% No.21.
		582 -> 3; %% No.22.
		583 -> 3; %% No.23.
		584 -> 3; %% No.24.
		585 -> 3; %% No.25.
		586 -> 3; %% No.26.
		587 -> 3; %% No.27.
		588 -> 3; %% No.28.
		589 -> 3; %% No.29.
		590 -> 3; %% No.20.
		591 -> 4; %% No.31.
		592 -> 4; %% No.32.
		593 -> 4; %% No.33.
		594 -> 4; %% No.34.
		595 -> 4; %% No.35.
		596 -> 4; %% No.36.
		597 -> 4; %% No.37.
		598 -> 4; %% No.38.
		599 -> 4; %% No.39.
		600 -> 4; %% No.40.
		601 -> 5; %% No.41.
		602 -> 5; %% No.42.
		603 -> 5; %% No.43.
		604 -> 5; %% No.44.
		605 -> 5; %% No.45.
		606 -> 5; %% No.46.
		607 -> 5; %% No.47.
		608 -> 5; %% No.48.
		609 -> 5; %% No.49.
		610 -> 5; %% No.50.
		611 -> 6; %% No.51.
		612 -> 6; %% No.52.
		613 -> 6; %% No.53.
		614 -> 6; %% No.54.
		615 -> 6; %% No.55.
		616 -> 6; %% No.56.
		617 -> 6; %% No.57.
		618 -> 6; %% No.58.
		619 -> 6; %% No.59.
		620 -> 6; %% No.60.
		_ -> 100
	end.

%% 得到副本通关礼包ID.
get_gift_id(DungeonId) ->
    case DungeonId of
        564 -> 531811; %% 第1章3回.
        567 -> 531812; %% 第1章6回.
        569 -> 531813; %% 第1章8回.
        572 -> 531814; %% 第2章3回.
        575 -> 531815; %% 第2章6回.
        577 -> 531816; %% 第2章8回.
        580 -> 531817; %% 第3章3回.
        583 -> 531818; %% 第3章6回.
        585 -> 531819; %% 第3章8回.
        _Other -> 0
    end.


%% 得到副本通关礼包所属副本的ID.
get_gift_dungeon_id(GiftId) ->
    case GiftId of
        531811 -> 564; %% 第1章3回.
        531812 -> 567; %% 第1章6回.
        531813 -> 569; %% 第1章8回.
        531814 -> 572; %% 第2章3回.
        531815 -> 575; %% 第2章6回.
        531816 -> 577; %% 第2章8回.
        531817 -> 580; %% 第3章3回.
        531818 -> 583; %% 第3章6回.
        531819 -> 585; %% 第3章8回.
		_Other -> 0
	end.

%% 得到副本总积分得到的属性加成.
get_base_attribute(TotalScore) ->
	if 
		TotalScore >= 180 -> [13200, 1320];
		TotalScore >= 170 -> [12000, 1200];
		TotalScore >= 160 -> [10800, 1080];
		TotalScore >= 150 -> [9600, 960];
		TotalScore >= 140 -> [8400, 840];
		TotalScore >= 130 -> [7200, 720];
		TotalScore >= 120 -> [6000, 600];
		TotalScore >= 110 -> [5000, 500];
		TotalScore >= 100 -> [4000, 400];
		TotalScore >= 90  -> [3000, 300];
		TotalScore >= 80  -> [2500, 250];
		TotalScore >= 70  -> [2000, 200];
		TotalScore >= 60  -> [1500, 150];
		TotalScore >= 50  -> [1200, 120];
		TotalScore >= 40  -> [900, 90];
		TotalScore >= 30  -> [600, 60];
		TotalScore >= 20  -> [400, 40];
		TotalScore >= 10  -> [200, 20];
		true              -> [0,0]
	end.

%% 得到剧情副本霸主奖励.
get_master_reward(Chapter) ->
	case Chapter of
		1 -> 531823;
		2 -> 531824;
		3 -> 531825;
		4 -> 531826;
		5 -> 531830;
		6 -> 531831;
		_ -> 531823
	end.

%%　获得副本id
get_dun_id_by_designation(DesignationId)->
    case DesignationId of
        203001 -> 562;
        203002 -> 563;
        203003 -> 564;
        203004 -> 565;
        203005 -> 566;
        203006 -> 567;
        203007 -> 568;
        203008 -> 569;
        203009 -> 570;
        203010 -> 571;
        203011 -> 572;
        203012 -> 573;
        203013 -> 574;
        203014 -> 575;
        203015 -> 576;
        203016 -> 577;
        203017 -> 578;
        203018 -> 579;
        203019 -> 580;
        203020 -> 581;
        203021 -> 582;
        203022 -> 583;
        203023 -> 584;
        203024 -> 585;
        203025 -> 586;
        203026 -> 587;
        203027 -> 588;
        203028 -> 589;
        203029 -> 590;
        203030 -> 591;
        203031 -> 592;
        203032 -> 593;
        _ -> 562
    end.

%%　获得称号id
get_designation_id_by_dun(DunId)->
    case DunId of
        562 -> 203001;
        563 -> 203002;
        564 -> 203003;
        565 -> 203004;
        566 -> 203005;
        567 -> 203006;
        568 -> 203007;
        569 -> 203008;
        570 -> 203009;
        571 -> 203010;
        572 -> 203011;
        573 -> 203012;
        574 -> 203013;
        575 -> 203014;
        576 -> 203015;
        577 -> 203016;
        578 -> 203017;
        579 -> 203018;
        580 -> 203019;
        581 -> 203020;
        582 -> 203021;
        583 -> 203022;
        584 -> 203023;
        585 -> 203024;
        586 -> 203025;
        587 -> 203026;
        588 -> 203027;
        589 -> 203028;
        590 -> 203029;
        591 -> 203030;
        592 -> 203031;
        593 -> 203032;
        _ -> 203001
    end.

