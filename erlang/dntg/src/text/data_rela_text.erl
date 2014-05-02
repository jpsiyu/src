%%%-----------------------------------
%%% @Module  : data_rela_text
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_rela_text).
-export([get_def_group_name/0,
         get_sys_msg/1,
         get_enemy/0,
         get_intimacy_text/1]).

get_def_group_name() ->
    "我的好友".

get_sys_msg(Type) ->
    case Type of
        1 ->
            "加好友请求已发出，等待对方回应";
        2 ->
            "成功添加好友"
    end.

get_enemy() ->
    ["赏恶令", "江湖传言，有人对你使用了赏恶令，在接下来的半个小时内，你的行踪将完全被他人掌握，小心行事，切记切记！"].

get_intimacy_text(Type) ->
    case Type of
        1 ->
            "击杀~p，与~p亲密度增加1点";
        2 ->
            "增加亲密度~p点";
        3 ->
            "离婚后亲密度降为~p点"
    end.

