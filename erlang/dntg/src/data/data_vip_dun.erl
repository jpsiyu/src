%%%---------------------------------------
%%% @Module  : data_vip_dun
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2013-02-25
%%% @Description:  VIP副本
%%%---------------------------------------

-module(data_vip_dun).
-export(
    [
        get_vip_dun_config/1,
        get_vip_dun_buy_gold/1,
        get_vip_dun_shop_list/1
    ]).
-include("shop.hrl").

get_vip_dun_config(Type) ->
    case Type of
        scene_id -> 429;
        leave -> [102, 112, 141];
        min_lv -> 35;
        %% 格子情况{{X, Y}, Type, Shape} Type:1-6 Shape:1/2
        vip_dun_cell -> 
            [
                {{63, 87}, 1}, 
                {{58, 83}, 2}, 
                {{55, 80}, 3}, 
                {{53, 77}, 2}, 
                {{50, 74}, 9}, 
                {{45, 70}, 5}, 
                {{41, 74}, 2}, 
                {{38, 77}, 4}, 
                {{33, 81}, 8}, 
                {{29, 77}, 2}, 
                {{26, 74}, 5}, 
                {{23, 71}, 6}, 
                {{21, 69}, 2},
                {{18, 65}, 7}, 
                {{15, 63}, 5}, 
                {{12, 60}, 6}, 
                {{8, 55}, 14}, 
                {{12, 51}, 3}, 
                {{15, 49}, 4}, 
                {{19, 44}, 10}, 
                {{15, 39}, 2}, 
                {{11, 34}, 4}, 
                {{15, 30}, 5},
                {{18, 27}, 2}, 
                {{21, 25}, 3}, 
                {{23, 22}, 4}, 
                {{26, 19}, 5}, 
                {{31, 14}, 9}, 
                {{35, 19}, 2}, 
                {{38, 22}, 7},
                {{41, 25}, 4},
                {{45, 29}, 5},
                {{50, 24}, 4}, 
                {{54, 20}, 14}, 
                {{59, 25}, 3},
                {{62, 27}, 4},
                {{64, 30}, 2}, 
                {{69, 35}, 7}
            ];
        %% 战斗怪
        mon_type_id1 -> 42901;
        mon_type_id2 -> 42902;
        mon_type_id3 -> 42903;
        mon_type_id4 -> 42904;
        %% 宝箱
        mon_type_id0 -> 42905;
        %% 副本时间
        dun_time -> 30 * 60;
        %% 离线时间
        leave_time -> 3 * 60;
        %% 骰子最大购买次数
        max_buy_num -> 4;
        %% BOSS
        mon_boss_id -> 42910;
        mon_multi_id1 -> 42906;
        mon_multi_id2 -> 42907;
        mon_multi_id3 -> 42908;
        mon_multi_id4 -> 42909;
        _ -> void
    end.

get_vip_dun_buy_gold(Num) ->
    case Num of
        1 -> 5;
        2 -> 10;
        3 -> 15;
        4 -> 20;
        _ -> 0
    end.

get_vip_dun_shop_list(TotalNum) ->
    case TotalNum of
        14 -> 
            [
                #base_dungeon_shop{goods_id=632001,price_type=1,price=5,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632002,price_type=1,price=10,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632003,price_type=1,price=15,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=501204,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0}
            ];
        30 -> 
            [
                #base_dungeon_shop{goods_id=632001,price_type=1,price=5,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632002,price_type=1,price=10,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632003,price_type=1,price=15,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=501204,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0}
            ];
        38 -> 
            [
                #base_dungeon_shop{goods_id=632001,price_type=1,price=5,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632002,price_type=1,price=10,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632003,price_type=1,price=15,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=501204,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0}
            ];
        52 -> 
            [
                #base_dungeon_shop{goods_id=632001,price_type=1,price=4,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632002,price_type=1,price=8,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632003,price_type=1,price=12,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=501204,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0}
            ];
        68 -> 
            [
                #base_dungeon_shop{goods_id=632001,price_type=1,price=4,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632002,price_type=1,price=8,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632003,price_type=1,price=12,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=501204,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0}
            ];
        76 -> 
            [
                #base_dungeon_shop{goods_id=632001,price_type=1,price=4,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632002,price_type=1,price=8,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632003,price_type=1,price=12,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=501204,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0}
            ];
        90 -> 
            [
                #base_dungeon_shop{goods_id=632001,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632002,price_type=1,price=6,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632003,price_type=1,price=9,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=501204,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0}
            ];
        106 -> 
            [
                #base_dungeon_shop{goods_id=632001,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632002,price_type=1,price=6,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632003,price_type=1,price=9,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=501204,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0}
            ];
        114 -> 
            [
                #base_dungeon_shop{goods_id=632001,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632002,price_type=1,price=6,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=632003,price_type=1,price=9,bind=2,buy_scene=429,limit_num=2,order=0},
                #base_dungeon_shop{goods_id=501204,price_type=1,price=3,bind=2,buy_scene=429,limit_num=2,order=0}
            ];
        _ -> []
    end.
