%%%-----------------------------------
%%% @Module  : data_skill_text
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_skill_text).
-compile(export_all).

get_skill_text(Type) ->
    Text = 
    case Type of
        1 ->
            <<"您已经学习了该技能！">>;
        2 ->
            <<"当前技能尚未学习！">>;
        3 ->
            <<"当前已经是最高等级了">>;
        4 ->
            "技能升级";
        5 ->
            <<"技能学习失败">>;
        6 ->
            <<"职业不同，不能学习！">>;
        7 ->
            "等级不足~p级";
        8 ->
            "铜币不足~p";
        10 ->
            "历练声望不足~p";
        11 ->
            %"~s尚未学习";
            "前置技能未学习或者未达到前置等级";
        12 ->
            "~s等级未达到~p级"
    end,
    Text.
