%%%------------------------------------
%%% @Module     : mod_rank_info
%%% @Author     : zhenghehe
%%% @Created    : 2012.02.04
%%% @Description: 排行榜info
%%%------------------------------------
-module(mod_rank_info).
-include("common.hrl").
-include("rank.hrl").
-export([handle_info/2]).

%% 默认匹配
handle_info(Info, State) ->
	catch util:errlog("mod_rank:handle_info not match: ~p", [Info]),
    {noreply, State}.