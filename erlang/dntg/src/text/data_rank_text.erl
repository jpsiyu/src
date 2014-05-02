%%%-----------------------------------
%%% @Module  : data_rank_text
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_rank_text).
-export([get_activity_text/1, 
         get_activity_text/2,
         date_str/0]).

get_activity_text(Type) ->
    get_activity_text(Type, 0).
get_activity_text(Type, SubType) ->
    case Type of
        kfz_score_activity ->
            ["跨服礼包", "恭喜您在~p获得跨服积分排行第~p名，获得~p个跨服礼包。"];
        daily_flower_activity ->
            case SubType of
                1 ->
                    ["魅力排行奖励", "每日护花榜", "恭喜您在~s获得~s第~w名，获得~w个圣诞鲜花礼包"];
                _ ->
                    ["魅力排行奖励", "每日鲜花榜", "恭喜您在~s获得~s第~w名，获得~w个圣诞鲜花礼包"]
            end;
        gift_to_server_roles ->
            ["跨服名人堂战力榜奖励", "恭喜您在~p获得跨服名人堂战力榜第~p名，获得~p个~p。"];
        reward_kfz_combat_power ->
            case SubType of
                532265 ->
                    ["跨服钻石礼包"];
                532264 ->
                    ["跨服白金礼包"];
                532263 ->
                    ["跨服黄金礼包"];
                532262 ->
                    ["跨服豪华礼包"];
                532261 ->
                    ["跨服普通礼包"]
            end
            
    end.

date_str() ->
    "年~p月~p日".