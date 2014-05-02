%%%------------------------------------
%%% @Module  : mod_fcm_info
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.27
%%% @Description: handle_info
%%%------------------------------------
-module(mod_fcm_info).
-export([handle_info/2]).

%% 默认匹配
handle_info(Info, Status) ->
    catch util:errlog("mod_fcm_info:handle_info not match: ~p~n", [Info]),
    {noreply, Status}.

