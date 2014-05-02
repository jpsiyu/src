%%%------------------------------------
%%% @Module  : data_change_name_text
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2013.02.25
%%% @Description: 改名
%%%------------------------------------
-module(data_change_name_text).
-export(
    [
        get_change_name_text/1
    ]
).

get_change_name_text(Type) ->
    case Type of
        1 -> "好友改名通知";
        2 -> "一入江湖岁月催！您的好友 【~s】 厌倦凡尘名利，使用改名卡改名换姓为 【~s】 ，从此匿迹于江湖。";
        _ ->
            ""
    end.
