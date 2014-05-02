%%%------------------------------------
%%% @Module  : data_off_line
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2013.02.01
%%% @Description: 经验材料召回活动
%%%------------------------------------
-module(data_off_line).
-export(
    [
        get_off_line_config/1,
        get_task1_exp/1,
        get_task2_exp/1,
        get_task3_exp/1,
        get_off_line_num/1,
        get_off_line_exp/1,
        get_off_line_award/3,
        get_off_line_text/1,
        get_per_goods_num/1
    ]
).
-include("server.hrl").

get_off_line_config(Type) ->
    case Type of
        begin_time -> {2013, 2, 6};
        end_time -> {2013, 2, 15};
        last_show_time -> {2013, 2, 18};
        goods_type_id -> 522011;
        daily_type -> 20130210;
        _ -> void
    end.

get_task1_exp(Lv) ->
    if
        Lv >= 70 -> 521300;
        Lv >= 60 -> 375000;
        Lv >= 50 -> 291000;
        Lv >= 40 -> 210000;
        Lv >= 30 -> 150000;
        true -> 0
    end.

get_task2_exp(Lv) ->
    if
        Lv >= 70 -> 695000;
        Lv >= 60 -> 500000;
        Lv >= 50 -> 388000;
        Lv >= 40 -> 280000;
        Lv >= 30 -> 200000;
        true -> 0
    end.

get_task3_exp(Lv) ->
    if
        Lv >= 70 -> 260600;
        Lv >= 60 -> 187500;
        Lv >= 50 -> 145500;
        Lv >= 40 -> 105000;
        Lv >= 30 -> 75000;
        true -> 0
    end.

get_off_line_num([Day, Type]) -> 
    case Type of
        1 -> 20 * Day;
        2 -> 10 * Day;
        3 -> 5 * Day;
        4 -> Day;
        5 -> Day;
        6 -> 2 * Day;
        7 -> Day;
        8 -> Day;
        9 -> 2 * Day;
        10 -> 2 * Day;
        11 -> Day;
        12 -> Day;
        13 -> Day;
        14 -> Day;
        15 -> Day;
        16 -> 2 * Day;
        _ -> Day
    end.

get_off_line_exp([Num, PlayerLv, Type, StatusVip]) -> 
    %会员经验
    VipCount = case StatusVip#status_vip.vip_type of	        
        0 -> 0;   %非会员.	        
        1 -> 0.2; %黄金会员.	        
        2 -> 0.3; %白金会员.        
        3 -> 0.5; %紫金会员.
        _ -> 0    %防出错.
    end,
    %% VIP等级加成系数
    VipGrowthLvCount = data_vip_new:get_exp_add(StatusVip#status_vip.growth_lv),
    Exp = case Type of
        1 -> Num * data_off_line:get_task1_exp(PlayerLv);
        2 -> Num * data_off_line:get_task2_exp(PlayerLv);
        3 -> Num * data_off_line:get_task3_exp(PlayerLv);
        4 -> round(Num * PlayerLv * PlayerLv * 1305 * (1 + 0.5 + VipCount + VipGrowthLvCount));
        5 -> round(Num * PlayerLv * PlayerLv * 222 * (1 + 0.5 + VipCount + VipGrowthLvCount));
        6 -> Num * PlayerLv * PlayerLv * 360;
        7 -> Num * PlayerLv * PlayerLv * 750;
        _ -> round(Num * 60 * (PlayerLv * PlayerLv * 1.48))
    end,
    case Exp > 0 of
        true -> Exp;
        false -> 0
    end.

get_off_line_award(TypeId, Level, PlayerLv) ->
    case TypeId of
        9 ->
            if
                Level >= 30 -> 534148;
                Level >= 28 -> 534147;
                Level >= 26 -> 534146;
                Level >= 24 -> 534145;
                Level >= 22 -> 534144;
                Level >= 20 -> 534143;
                Level >= 15 -> 534142;
                Level >= 10 -> 534141;
                Level >= 5 -> 534140;
                true -> 0
            end;
        10 ->
            if
                Level >= 30 -> 534157;
                Level >= 28 -> 534156;
                Level >= 26 -> 534155;
                Level >= 24 -> 534154;
                Level >= 22 -> 534153;
                Level >= 20 -> 534152;
                Level >= 15 -> 534151;
                Level >= 10 -> 534150;
                Level >= 5 -> 534149;
                true -> 0
            end;
        11 ->
            if
                Level >= 50 -> 534167;
                Level >= 45 -> 534166;
                Level >= 40 -> 534165;
                Level >= 35 -> 534164;
                Level >= 30 -> 534163;
                Level >= 25 -> 534162;
                Level >= 20 -> 534161;
                Level >= 15 -> 534160;
                Level >= 10 -> 534159;
                Level >= 5 -> 534158;
                true -> 0
            end;
        12 ->
            if
                Level >= 50 -> 534178;
                Level >= 45 -> 534177;
                Level >= 40 -> 534176;
                Level >= 35 -> 534175;
                Level >= 30 -> 534174;
                Level >= 25 -> 534173;
                Level >= 20 -> 534172;
                Level >= 15 -> 534171;
                Level >= 10 -> 534170;
                Level >= 5 -> 534169;
                true -> 0
            end;
        13 ->
            534200;
        14 ->
            if
                PlayerLv >= 60 -> 534192;
                PlayerLv >= 50 -> 534191;
                true -> 534190
            end;
        15 -> 
            112224;
        16 ->
            523501
    end.

get_off_line_text(Type) ->
    case Type of
        1 -> "单人九重天材料召回";
        2 -> "多人九重天材料召回";
        3 -> "单人炼狱副本材料召回";
        4 -> "多人炼狱副本材料召回";
        5 -> "春节累计单人九重天次数 ~p 次，本次征战至第 ~p 层，共召回 ~p 个材料礼包。";
        6 -> "春节累计多人九重天次数 ~p 次，本次征战至第 ~p 层，共召回 ~p 个材料礼包。";
        7 -> "春节累计单人炼狱副本次数 ~p 次，本次征战至第 ~p 层，共召回 ~p 个材料礼包。";
        8 -> "春节累计多人炼狱副本次数 ~p 次，本次征战至第 ~p 层，共召回 ~p 个材料礼包。";
        9 -> "蝴蝶谷/钓鱼活动材料召回";
        10 -> "决战南天门材料召回";
        11 -> "蟠桃会材料召回";
        12 -> "跨服3v3材料召回";
        13 -> "春节累计蝴蝶谷/钓鱼活动次数 ~p 次，共召回 ~p 个材料礼包。";
        14 -> "春节累计决战南天门次数 ~p 次，共召回 ~p 个材料礼包。";
        15 -> "春节累计蟠桃会次数 ~p 次，共召回 ~p 个宝石碎片。";
        16 -> "春节累计跨服3v3次数 ~p 次，共召回 ~p 个跨服勋章。";
        _ -> ""
    end.

get_per_goods_num(Type) ->
    case Type of
        1 -> 2;
        2 -> 1;
        3 -> 2;
        4 -> 30;
        5 -> 5;
        6 -> 8;
        7 -> 17;
        _ -> 1
    end.
