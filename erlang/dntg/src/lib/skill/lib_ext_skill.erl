%%%-----------------------------------
%%% @Module  : lib_ext_skill
%%% @Author  : zhenghehe
%%% @Created : 2010.07.27
%%% @Description: 扩展技能
%%%-----------------------------------
-module(lib_ext_skill).
-export(
    [
        combo_buff/3,
        clear_combo_buff/1,
        combo_buff_online/2
    ]
).
-include("server.hrl").
-include("skill.hrl").
-define(COMBO_BUFF, coin_dungeon_combo_buff).

%% 铜币副本连斩buff加成
combo_buff(Status, Combo, MaxCombo) -> 
    Lv = if 
        Combo < MaxCombo -> 0;
        Combo == 50   -> 1;
        Combo == 100  -> 2;
        Combo == 200  -> 3;
        Combo == 300  -> 4;
        Combo == 400  -> 5;
        Combo == 500  -> 6;
        Combo == 600  -> 7;
        true -> 0
    end,
    if 
        Lv == 0 -> skip;
        true ->
            Lv0 = 
            case get(?COMBO_BUFF) of
                undefined ->
                    0;
                Val ->
                    Val
            end,
            case Lv>Lv0 of
                true -> %% 更替buff
                    put(?COMBO_BUFF, Lv),
                    lib_skill_buff:add_buff([{400002, Lv}], Status, util:longunixtime());
                false -> skip
            end
    end.

%% 铜币副本连斩buff加成
combo_buff_online(Status, MaxCombo) -> 
    Lv = if 
        MaxCombo >= 600 -> 7;
        MaxCombo >= 500 -> 6;
        MaxCombo >= 400 -> 5;
        MaxCombo >= 300 -> 4;
        MaxCombo >= 200 -> 3;
        MaxCombo >= 100 -> 2;
        MaxCombo >= 50 ->  1;
        true -> 0
    end,
    if 
        Lv == 0 -> Status;
        true -> lib_skill_buff:add_buff([{400002, Lv}], Status, util:longunixtime())
    end.
               

%% 退出铜币副本清除连斩buff加成
clear_combo_buff(Status) -> 
    erase(?COMBO_BUFF),
    Status.
