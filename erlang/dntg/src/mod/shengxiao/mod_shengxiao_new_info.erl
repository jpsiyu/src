%%%------------------------------------
%%% @Module  : mod_shengxiao_new_info
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.5.31
%%% @Description: 生肖大奖info
%%%------------------------------------
-module(mod_shengxiao_new_info).
-export([handle_info/2]).

%% 默认匹配
handle_info(Info, State) ->
	catch util:errlog("mod_shengxiao_new:handle_info not match: ~p", [Info]),
    {noreply, State}.
