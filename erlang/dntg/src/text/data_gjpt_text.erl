%%%------------------------------------
%%% @Module  : data_gjpt_text
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.7
%%% @Description: 国家声望
%%%------------------------------------
-module(data_gjpt_text).
-compile(export_all).

get_gjpt_text(Type) ->
    case Type of
	0 -> "罪恶值减少 ";
	1 -> " 点"
    end.
