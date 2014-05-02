%%%------------------------------------
%%% @Module  : data_vip_dun_text
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2013.02.25
%%% @Description: VIP副本
%%%------------------------------------
-module(data_vip_dun_text).
-export(
    [
        get_vip_dun_text/1,
        get_vip_dun_error/1
    ]
).

get_vip_dun_text(Type) ->
    case Type of
        1 -> "获得 ~p VIP成长值";
        2 -> "VIP副本";
        3 -> "亲爱的玩家，您在VIP副本里剩余~p次特殊技能未使用，现为您发送~p个迷你成长丹作为技能补偿，敬请查收！";
        4 -> "按照谜语击杀对应怪物：耳朵长，尾巴短。只吃菜，不吃饭";
        5 -> "按照谜语击杀对应怪物：远看像黄球，近看毛茸茸。叽叽叽叽叫，最爱吃小虫";
        6 -> "按照谜语击杀对应怪物：四柱八栏杆，住着懒惰汉。鼻子团团转，尾巴打个圈";
        7 -> "按照谜语击杀对应怪物：任劳又任怨，田里活猛干，生产万顿粮，只把草当饭";
        _ ->
            ""
    end.

get_vip_dun_error(Type) ->
    case Type of
        0 -> "正在进入VIP副本";
        1 -> "失败，今天挑战次数已满";
        2 -> "失败，~p级以上玩家才能进行挑战";
        3 -> "失败，VIP半年卡、VIP月卡、VIP周卡才能进行挑战";
        4 -> "正在退出VIP副本";
        5 -> "失败，当前状态不允许传送";
        _ -> ""
    end.