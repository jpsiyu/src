%%%------------------------------------
%%% @Module  : mod_pet_cast
%%% @Author  : zhenghehe
%%% @Created : 2012.02.02
%%% @Description: 宠物处理cast
%%%------------------------------------
-module(mod_pet_cast).
-include("common.hrl").
%-include("record.hrl").
-include("goods.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("scene.hrl").
-export([handle_cast/2]).


%% -----------------------------------------------------------------
%% 发送宠物邮件
%% -----------------------------------------------------------------
handle_cast({'send_mail', SubjectType, Param}, State) ->
    lib_pet:send_mail(SubjectType, Param),
    {noreply, State};

%% -----------------------------------------------------------------
%% 记录操作日志
%% -----------------------------------------------------------------
handle_cast({'log_pet', Type, PlayerId, PetId, Param}, State) ->
    lib_pet:log_pet(Type, PlayerId, PetId, Param),
    {noreply, State};

%% -----------------------------------------------------------------
%% 删除操作日志
%% -----------------------------------------------------------------
handle_cast({'delete_log'}, State) ->
    lib_pet:delete_log(),
    {noreply, State};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_pet:handle_cast not match: ~p", [Event]),
    {noreply, Status}.