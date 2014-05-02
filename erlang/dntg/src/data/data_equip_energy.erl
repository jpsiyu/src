%%------------------------------------------------------------------------------
%% @Module  : 
%% @Author  : 
%% @Email   : @qq.com
%% @Created : 2014.2.17
%% @Description: equit 
%%------------------------------------------------------------------------------

-module(data_equip_energy).
-include("dungeon.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([get_config/1, 
         get_record_level/2,
         get_mon_num/1,
         is_equip_dun/1,
         get_pass_gift_info/3,
         get_dunid_by_sort_id/1,
         get_ceng_id/1,
         get_level_dungeon_list/1,
         get_coin_num/1,
         get_bglod_num/1
         ]).

%% 340-347,348-355,356-363
%% 得到剧情副本基本配置.
get_config(Type)->
    case Type of
        dungeon_list -> [340, 341, 342, 343, 344, 345, 346, 347, 
                         348, 349, 350, 351, 352, 353, 354, 355, 
                         356, 357, 358, 359, 360, 361, 362, 363, 
                         364, 365, 366, 367, 368, 369, 370, 371,
                         372, 373, 374, 375, 376, 377, 378, 379];
        boss_list -> [34002, 34004, 34006, 34008, 34010, 34012, 34014, 34016, 
                      34018, 34020, 34022, 34024, 34026, 34028, 34030, 34032, 
                      34034, 34036, 34038, 34040, 34042, 34044, 34046, 34048,
                      34050, 34052, 34054, 34056, 34058, 34060, 34062, 34064,
                      34066, 34068, 34070, 34072, 34074, 34076, 34078, 34080];
        first_dunid -> 340;
        coin_ka -> [221101,221102, 221103, 221104, 221113, 221112, 221111];
        bgold_ka -> [611102];
        goods -> [{{111041, 1}, 30}]; 
        goods_list -> [{{111041, 1},30},{{501202, 1},50},{{612501, 1},50},{{221111, 1},60},{{221112, 1},32},{{205101, 1},40}];
        eq_scene_xy -> {27, 35};
                
        _-> 
            undefined
    end.


%% 判断副本是不是装备副本
is_equip_dun(DunId) ->
    DunList = get_config(dungeon_list),
    lists:member(DunId, DunList).


%%　判断副本的星级
get_record_level(UsedTime, LevelCondition) ->
    [{Level1, Time1}, {Level2, Time2}, {Level3, Time3}] = LevelCondition,
    if
        UsedTime < Time1 -> Level1;
        UsedTime < Time2 -> Level2;
        UsedTime < Time3 -> Level3;
        true -> 1
    end.


%% 获取单个信息
get_pass_gift_info(DunId, Type, Career)->
    case is_equip_dun(DunId) of
        false ->
            {error, dun_not_exist};
        _ ->
            case data_equip_gift:get_gift(DunId) of
                [] ->
                    {error, dun_gift_info_not_exist};
                EquipGiftConfig ->
                    case Type of
                        id -> 
                            EquipGiftConfig#dntk_equip_dun_config.id;
                        f_rotary_gift -> 
                            EquipGiftConfig#dntk_equip_dun_config.f_rotary_gift;
                        s_rotary_gift -> 
                            EquipGiftConfig#dntk_equip_dun_config.s_rotary_gift;
                        pass_gift ->
                            PassGift = EquipGiftConfig#dntk_equip_dun_config.pass_gift,
                            case PassGift of
                                [{GoodsId, Num}] -> {GoodsId, Num};
                                PassGift ->  case lists:keyfind(Career, 1, PassGift) of
                                                 false -> {0, 0};
                                                 {_Career, GoodsId, Num} ->  {GoodsId, Num}
                                             end
                            end;
                        extraction_count ->
                            EquipGiftConfig#dntk_equip_dun_config.extraction_count;
                        send ->
                            EquipGiftConfig#dntk_equip_dun_config.send;
                        level_condition ->
                            EquipGiftConfig#dntk_equip_dun_config.level_condition;
                        gold ->
                            EquipGiftConfig#dntk_equip_dun_config.gold;
                        _ ->
                            {error, type_not_exist} 
                    end
            end
    end.
        

%% 获取铜币数量221001,221002, 221003, 221004
get_coin_num(CoinKaId)->
    case CoinKaId of
        221104 -> 20000; 
        221103 -> 10000;
        221102 -> 5000;
        221101 -> 1000;
        221113 -> 10000;
        221112 -> 5000;
        221111 -> 2000;
        _  -> 0
    end.
  
%% 获取绑定元宝的数量
get_bglod_num(BGoldId)->
    case BGoldId of
        611102 -> 1; 
        _  -> 0
    end.

%% 获取每关装备副本的怪物数量和npcID（用于判断是否结束副本）
get_mon_num(DungeonId)->
    case DungeonId of
        340 ->  {340, 15, []};
        341 ->  {341, 10, []};
        342 ->  {342, 10, []};
        343 ->  {343, 10, []};
        344 ->  {344, 10, []};
        346 ->  {345, 10, []};
        347 ->  {346, 10, []};
        348 ->  {347, 10, []};
        
        349 ->  {348, 10, []};
        350 ->  {349, 10, []};
        352 ->  {350, 10, []};
        353 ->  {351, 10, []};
        354 ->  {352, 10, []};
        355 ->  {353, 10, []};
        356 ->  {354, 10, []};
        358 ->  {355, 10, []};
        
        359 ->  {356, 10, []};
        360 ->  {357, 10, []};
        361 ->  {358, 10, []};
        362 ->  {359, 10, []};
        364 ->  {360, 10, []};
        365 ->  {361, 10, []};
        366 ->  {362, 10, []};
        367 ->  {363, 10, []};
        _   ->  {0, 0}
    end.

%%　
get_dunid_by_sort_id(SortId) ->
    case SortId of
        1 -> 340;   %% 1
        2 -> 341;
        3 -> 342;
        4 -> 343;
        5 -> 344;
        6 -> 345;
        7 -> 346;
        8 -> 347;
        9 -> 348;   %% 2
        10 -> 349;
        11 -> 350;
        12 -> 351;
        13 -> 352;
        14 -> 353;
        15 -> 354;
        16 -> 355;
        17 -> 356;  %% 3
        18 -> 357;
        19 -> 358;
        20 -> 359;
        21 -> 360;
        22 -> 361;
        23 -> 362;
        24 -> 363;
        25 -> 364;  %% 4
        26 -> 365;
        27 -> 366;
        28 -> 367;
        29 -> 368;
        30 -> 369;
        31 -> 370;
        32 -> 371;
        33 -> 372;  %% 5
        34 -> 373;
        35 -> 374;
        36 -> 375;
        37 -> 376;
        38 -> 377;
        39 -> 378;
        40 -> 379;
        _ -> 0
    end.
        
%% 得到第几章的所有副本列表.
get_level_dungeon_list(Level) ->
    case Level of
        1 -> [340, 341, 342, 343, 344, 345, 346, 347];%第一层副本ID.
        2 -> [348, 349, 350, 351, 352, 353, 354, 355];%第二层副本ID.
        3 -> [356, 357, 358, 359, 360, 361, 362, 363];%第三层副本ID.
        4 -> [364, 365, 366, 367, 368, 369, 370, 371];%第4层副本ID.
        5 -> [372, 373, 374, 375, 376, 377, 378, 379];%第5层副本ID.
        _ -> []
    end.

%% 得到副本是第几层.
get_ceng_id(DungeonId) ->
    case DungeonId of
        340 -> 1;   %% 1
        341 -> 1;
        342 -> 1; 
        343 -> 1; 
        344 -> 1;  
        345 -> 1; 
        346 -> 1; 
        347 -> 1; 
        348 -> 2;   %% 2
        349 -> 2;   
        350 -> 2;
        351 -> 2;
        352 -> 2;
        353 -> 2;
        354 -> 2;
        355 -> 2;
        356 -> 3;   %% 3
        357 -> 3;
        358 -> 3;   
        359 -> 3;
        360 -> 3;
        361 -> 3;
        362 -> 3;
        363 -> 3;
        364 -> 4;   %% 4
        365 -> 4;
        366 -> 4;
        367 -> 4;
        368 -> 4;
        369 -> 4;
        370 -> 4;
        371 -> 4;
        372 -> 5;   %% 5
        373 -> 5;
        374 -> 5;
        375 -> 5;
        376 -> 5;
        377 -> 5;
        378 -> 5;
        379 -> 5;
        _ -> 100
    end.




