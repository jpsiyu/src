%%%------------------------------------
%%% @Module  : mod_mail_info
%%% @Author  : zhenghehe
%%% @Created : 2012.02.04
%%% @Description: 任务info处理
%%%------------------------------------
-module(mod_task_info).
-export([handle_info/2]).
%% 默认匹配
handle_info(Info, State) ->
    catch util:errlog("mod_task:handle_info not match: ~p", [Info]),
    {noreply, State}.