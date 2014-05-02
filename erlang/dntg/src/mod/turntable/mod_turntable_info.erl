%%%-------------------------------------------------------------------
%%% @Module	: mod_turntable_info
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	:  5 Jul 2012
%%% @Description: 转盘info
%%%-------------------------------------------------------------------
-module(mod_turntable_info).
-export([handle_info/2]).
handle_info(Info, Status) ->
    util:errlog("mod_server:handle_info not match: ~p", [Info]),
    {noreply, Status}.
