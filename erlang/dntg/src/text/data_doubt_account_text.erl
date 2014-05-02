%%%-----------------------------------
%%% @Module  : data_doubt_account_text
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_doubt_account_text).
-export([get_coin_text/1]).

get_coin_text(Type) ->
    case Type of
        1 ->
            "输入正确，今天领奖次数超过5次，无法再获得奖励";
        2 ->
            "输入正确，获得500绑定铜币"
        
    end.