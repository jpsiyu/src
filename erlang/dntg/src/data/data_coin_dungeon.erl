%%%------------------------------------
%%% @Module  : data_coin_dungeon
%%% @Author  : zzm
%%% @Email   : ming_up@163.com
%%% @Created : 2011.12.26
%%% @Description: 钱多多副本
%%%-----------------------------------

-module(data_coin_dungeon).
-compile(export_all).

%% 获取第二阶段(生成boss)的延迟时间(秒)
get_2th_dely_time() -> 60.

%% 获取击杀boss的限制时间(秒)
get_kill_boss_lim_time() -> 30.

%% 获取击杀boss的限制时间(秒)
get_lottery_time() -> 99.

%% 获取每个金币的价值
get_coin_value() -> 100.

%% 小怪id
get_mon_id() -> 65001.

%% 连斩间距(秒)
combo_config(Combo) ->
    if
        Combo < 50  -> 15;
        Combo < 100 -> 15;
        Combo < 300 -> 10;
        Combo < 600 -> 10;
        Combo < 800 -> 5;
        true        -> 5
    end.

%% 每波刷新的金币
lottery_config() -> util:rand(19, 99).

%% 小怪价值
mon_value() -> 40.
