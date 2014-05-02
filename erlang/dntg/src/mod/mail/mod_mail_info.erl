%%%------------------------------------
%%% @Module  : mod_mail_info
%%% @Author  : zhenghehe
%%% @Created : 2012.02.01
%%% @Description: 信件info处理
%%%------------------------------------
-module(mod_mail_info).
-export([handle_info/2]).
%% -include("common.hrl").
%% -include("record.hrl").
%% -include("mail.hrl").
%% -include("player.hrl").
%% 默认匹配
handle_info(Info, State) ->
	catch util:errlog("mod_mail:handle_info not match: ~p", [Info]),
    {noreply, State}.