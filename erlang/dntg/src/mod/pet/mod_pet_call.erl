%%%------------------------------------
%%% @Module  : mod_pet_call
%%% @Author  : zhenghehe
%%% @Created : 2012.02.02
%%% @Description: 宠物处理call
%%%------------------------------------
-module(mod_pet_call).
-export([handle_call/3]).

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_pet:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.