%%%------------------------------------
%%% @Module  : data_shake_money_text
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.9.21
%%% @Description: 摇钱树
%%%------------------------------------
-module(data_shake_money_text).
-compile(export_all).

get_shake_money_text(Type) ->
    case Type of
        0 ->
            "摇动摇钱树，获得";
        1 ->
            "绑定铜币";
        2 ->
            "获得 小型铜币卡 X ";
        3 ->
            "摇钱树奖励";
        4 ->
            "您成功摇钱~p次，自动发放 小型铜币卡 X ~p 奖励!";
        5 ->
            "您成功摇钱~p次，发放 小型铜币卡 X ~p 奖励，背包容量不足，奖励通过邮件发送!"
    end.
