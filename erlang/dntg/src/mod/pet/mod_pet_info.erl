%%%------------------------------------
%%% @Module  : mod_pet_info
%%% @Author  : zhenghehe
%%% @Created : 2012.02.02
%%% @Description: 宠物处理info
%%%------------------------------------
-module(mod_pet_info).
-export([handle_info/2]).

%% 默认匹配
handle_info(Info, State) ->
	catch util:errlog("mod_pet:handle_info not match: ~p", [Info]),
    {noreply, State}.