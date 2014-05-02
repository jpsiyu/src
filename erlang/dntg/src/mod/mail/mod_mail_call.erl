%%%------------------------------------
%%% @Module  : mod_mail_call
%%% @Author  : zhenghehe
%%% @Created : 2012.02.01
%%% @Description: 信件call处理
%%%------------------------------------
-module(mod_mail_call).
-export([handle_call/3]).
%% -include("common.hrl").
%% -include("record.hrl").
%% -include("mail.hrl").
%% -include("player.hrl").

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_mail:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.