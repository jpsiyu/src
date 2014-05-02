%%%------------------------------------
%%% @Module  : mod_unite_info
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.12.16
%%% @Description: 公共服务info处理
%%%------------------------------------
-module(mod_unite_info).
-export([handle_info/2]).
-include("unite.hrl").

%% 默认匹配
handle_info(Info, Status) ->
    catch util:errlog("mod_unite:handle_info not match: ~p", [Info]),
    {noreply, Status}.

