%%%------------------------------------
%%% @Module  : mod_shengxiao_new_cast
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.5.31
%%% @Description: 生肖大奖cast
%%%------------------------------------
-module(mod_shengxiao_new_cast).
-export([handle_cast/2]).

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_shengxiao_new:handle_cast not match: ~p", [Event]),
    {noreply, Status}.
