%%%------------------------------------
%%% @Module  : buff_dict_info
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.27
%%% @Description: handle_info
%%%------------------------------------
-module(buff_dict_info).
-export([handle_info/2]).

%% 默认匹配
handle_info(Info, Status) ->
    catch util:errlog("buff_dict_info:handle_info not match: ~p~n", [Info]),
    {noreply, Status}.
