%%%-----------------------------------
%%% @Module  : data_cw_text
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_cw_text).
-compile(export_all).

get_cw_text(Type) ->
    case Type of
        guild_battle_prepare_cw ->
            ["帮战<c8>~p分钟</c8>后正式开始，请各路英雄做好准备！"];
        guild_battle_start_cw ->
            ["帮派战正式开启，各路英雄出发吧！"];
        cw_guild_battle_refresh_monster ->
            ["天降神魔兵"];
        intercept ->
            ["<c4> ~p 帮派竟被神秘人恶意破坏!</c4>"];
        guoyun ->
            ["国运期间，奖励翻倍！"];
        yunbiao_success ->
            ["帮派镖车成功抵达国都，获得~p  帮派资金"];
        yunbiao_failed ->
            ["运送帮派镖车失败，获得 ~p 帮派资金"];
        guild_mon ->
            ["的帮派镖车"];
        quiz_end ->
            ["答题活动结束！"];
        yunbiao ->
            ["<~p>~s </~p> <c0>大喝一声， </c0><~p>~s</~p> <c0> 竟仓皇失措，所护镖银也悉数被劫！</c0>"];
        refresh_hs ->
            ["获得了护送美女", "的殊荣，丰厚奖励让人羡慕"]
    end.

get_vip_color(Type) ->
    case Type of
        1 ->
            "<c2>黄金VIP</c2> ";
        2 ->
            "<c3>白金VIP</c2> ";
        3 ->
            "<c4>钻石VIP</c2> ";
        _ ->
            ""
    end.

get_vip_text(Type) ->
    case Type of
        1 ->
            " 成为 ";
        2 ->
            "，正享受着多倍经验、强化加成、免费飞行等超多特权福利！";
        _ ->
            ""
    end.
    
get_egg_broken_text(Type) ->
    case Type of
        five_mult_exp -> 
            "在砸幸运宠物蛋时获得 <c4>5倍经验奖励</c4>，真是太幸运了。";
        again ->
            "在砸幸运宠物蛋时获得 <c4>再砸1次蛋</c4> 的机会，真是令人羡慕啊。"                  
    end.

stren(Type) ->
    case Type of
        1 ->
            " 历尽千辛万苦终于将 ";
        2 ->
            " 强化到 <";
        3 ->
            "太可惜了! ";
        4 ->
            "> 失败了！降到 <";
        5 ->
            " 的 ";
        6 ->
            " 强化到 +";
        7 ->
            "，威力大幅提升，大家祝贺吧！";
        8 ->
            " 失败了！降到 +";
        9 ->
            " 历尽千辛万苦终于合成出 ";
        _ ->
            ""
    end.

sell_up(Type) ->
    case Type of
        0 ->
            "铜钱";
        1 ->
            "元宝";
        2 ->
            " 挂售了";
        3 ->
            "个";
        4 ->
            ", 出售价格为";
        5 ->
            ", 欲购从速!";
        _ ->
            ""
    end.

%% 获得名人堂荣誉
get_fame_text() ->
	["恭喜 ~s 第一个完成 ~s，获得称号 ~s！真是太厉害了！"].

drop_text(Type) ->
    case Type of
        1 ->
            " 越战越勇，<c9>";
        2 ->
            "</c9> 节节败退，看来手中的 ";
        3 ->
            " 是保不住了！";
        _ ->
            ""
    end.

get_kill_text() ->
    ["杀戮通知", "你被【~s】的玩家【~s】杀死了"].

get_realm_name(Realm) ->
    if
        Realm == 1 ->
            "昆仑";
        Realm == 2 ->
            "玄都";
        true ->
            "蓬莱"
    end.
