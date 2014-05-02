%%%------------------------------------
%%% @Module  : mod_scene_agent_info
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2012.05.18
%%% @Description: 场景管理info处理
%%%------------------------------------
-module(mod_scene_agent_info).
-include("scene.hrl").
-export([handle_info/2]).

%% 监控不存在的怪物,清空内存数据
handle_info('monitor', Status) ->
    AllUser = lib_scene_agent:get_scene_user(),
    F = fun(User) ->
        case misc:get_player_process(User#ets_scene_user.id) of
            Pid when is_pid(Pid) ->
                skip;
            _ ->
                lib_scene_agent:del_user([User#ets_scene_user.id, User#ets_scene_user.platform, User#ets_scene_user.server_num]) 
        end
    end,
    [ F(User) || User <-AllUser],
    {noreply, Status};

%% 默认匹配
handle_info(Info, Status) ->
    catch util:errlog("mod_server:handle_info not match: ~p", [Info]),
    {noreply, Status}.
