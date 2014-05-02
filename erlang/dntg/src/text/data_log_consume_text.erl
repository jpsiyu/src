%%%-----------------------------------
%%% @Module  : data_log_consume_text
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_log_consume_text).
-export([get_log_consume_text/1]).

get_log_consume_text(Type) ->
    case Type of
        guild_material ->
            ["元宝兑换个人财富"];
        _ ->
            [""]
    end.
