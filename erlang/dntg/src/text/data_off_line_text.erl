%%%------------------------------------
%%% @Module  : data_off_line_text
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2013.02.01
%%% @Description: 经验材料召回活动
%%%------------------------------------
-module(data_off_line_text).
-export(
    [
        get_off_line_error_text/1
    ]
).

get_off_line_error_text(Type) ->
    case Type of
        1 -> "失败，没有该类型任务!";
        2 -> "失败，超出最大兑换值!";
        3 -> "免费领取离线经验 ~p ";
        4 -> "使用 ~p 个如意令领取离线经验 ~p ";
        5 -> "失败，如意令数量不足!"
    end.

