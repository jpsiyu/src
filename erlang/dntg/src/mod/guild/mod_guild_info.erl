%%%------------------------------------
%%% @Module  : mod_guild_info
%%% @Author  : 
%%% @Created : 2012.02.02
%%% @Description: 帮派info处理
%%%------------------------------------
-module(mod_guild_info).
-export([handle_info/2]).

%% 默认匹配
handle_info(Info, State) ->
	catch util:errlog("mod_guild:handle_info not match: ~p", [Info]),
    {noreply, State}.