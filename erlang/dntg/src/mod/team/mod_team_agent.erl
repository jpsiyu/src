%%------------------------------------------------------------------------------
%% @Module  : mod_team_agent
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.30
%% @Description: 组队数据管理服务器
%%------------------------------------------------------------------------------

-module(mod_team_agent).
-behaviour(gen_server).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("team.hrl").

-export([start_link/0, stop/0, init/1, 
		 handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([
         set_tmb_offline/1,                  %% 保存队伍暂离成员列表.
		 get_tmb_offline/1,                  %% 获取队伍暂离成员列表.
		 del_tmb_offline/1,                  %% 删除获取队伍暂离成员列表.
		 create_dungeon_enlist2/1,           %% 创建副本招募.
		 set_dungeon_enlist2/1,              %% 设置副本招募.
		 get_dungeon_enlist2_by_scene_id/1,  %% 获取副本招募.
		 get_dungeon_enlist2_by_player_id/1, %% 获取副本招募.
		 del_dungeon_enlist2/1               %% 删除副本招募.
]).

%% --------------------------------- 公共函数 ----------------------------------

%% 启动服务器
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%% 停止服务器
stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

%% 保存队伍暂离成员列表.
set_tmb_offline(TMBOffline)->
	gen_server:call(misc:get_global_pid(?MODULE),{'set_tmb_offline',TMBOffline}).

%% 获取队伍暂离成员列表.
get_tmb_offline(Id)->
	gen_server:call(misc:get_global_pid(?MODULE),{'get_tmb_offline',Id}).

%% 删除获取队伍暂离成员列表.
del_tmb_offline(Id)->
	gen_server:cast(misc:get_global_pid(?MODULE),{'del_tmb_offline',Id}).

%% 创建副本招募.
create_dungeon_enlist2(DungeonEnlist)->
	gen_server:call(misc:get_global_pid(?MODULE),{'create_dungeon_enlist2', DungeonEnlist}).

%% 设置副本招募.
set_dungeon_enlist2(DungeonEnlist)->
	gen_server:call(misc:get_global_pid(?MODULE),{'set_dungeon_enlist2', DungeonEnlist}).

%% 获取副本招募.
get_dungeon_enlist2_by_scene_id(SceneId)->
	gen_server:call(misc:get_global_pid(?MODULE),{'get_dungeon_enlist2_by_scene_id', SceneId}).

%% 获取副本招募.
get_dungeon_enlist2_by_player_id(PlayerId)->
	gen_server:call(misc:get_global_pid(?MODULE),{'get_dungeon_enlist2_by_player_id', PlayerId}).

%% 删除副本招募.
del_dungeon_enlist2(PlayerId)->
	gen_server:cast(misc:get_global_pid(?MODULE),{'del_dungeon_enlist2', PlayerId}).

%% --------------------------------- 内部函数 ----------------------------------

%% 启动服务器.
init([]) ->
	%1.一分钟后启动检测招募列表是否还有效.
	erlang:send_after(60 * 1000, self(), 'check_enlist2_alive'),
    {ok, ?MODULE}.

%% 保存队伍暂离成员列表.
handle_call({'set_tmb_offline', TMBOffline}, _From, State) ->
	put(TMBOffline#ets_tmb_offline.id, TMBOffline),
    {reply, 0, State};

%% 获取队伍暂离成员列表.
handle_call({'get_tmb_offline',Id}, _From, State) ->
	 case get(Id) of
		 undefined ->
		     {reply, [], State};
		 TMBOffline ->
		     {reply, [TMBOffline], State}
     end;

%% 创建副本招募.
handle_call({'create_dungeon_enlist2', DungeonEnlist2}, _From, State) ->
	PlayerId = DungeonEnlist2#ets_dungeon_enlist2.id,
	SceneId = DungeonEnlist2#ets_dungeon_enlist2.sid,

	%1.检查否是创建副本招募.
    Data = get(),
    F = fun({Key, DungeonEnlist}) ->
        case Key of
            {dungeon_enlist2, _PlayerId, _SceneId} 
				when _SceneId =:= SceneId andalso _PlayerId =:= PlayerId->
                [DungeonEnlist];
            _ ->
                []
        end
    end,
    Data2 = lists:flatmap(F, Data),

	%2.创建副本招募.
	case Data2 =:= [] of
		true ->
			put({dungeon_enlist2, PlayerId, SceneId}, DungeonEnlist2);
		false ->
			skip
	end,
    {reply, 0, State};

%% 创建副本招募.
handle_call({'set_dungeon_enlist2', DungeonEnlist2}, _From, State) ->
	PlayerId = DungeonEnlist2#ets_dungeon_enlist2.id,
	SceneId = DungeonEnlist2#ets_dungeon_enlist2.sid,
	put({dungeon_enlist2, PlayerId, SceneId}, DungeonEnlist2),
    {reply, 0, State};

%% 获取副本招募.
handle_call({'get_dungeon_enlist2_by_scene_id', SceneId}, _From, State) ->
    Data = get(),
    F = fun({Key, DungeonEnlist2}) ->
        case Key of
            {dungeon_enlist2, _PlayerId, _SceneId} when _SceneId =:= SceneId ->
                [DungeonEnlist2];
            _ ->
                []
        end
    end,
    Data2 = lists:flatmap(F, Data),
	{reply, Data2, State};

%% 获取副本招募.
handle_call({'get_dungeon_enlist2_by_player_id', PlayerId}, _From, State) ->
    Data = get(),
    F = fun({Key, DungeonEnlist2}) ->
        case Key of
            {dungeon_enlist2, _PlayerId, _SceneId} when _PlayerId =:= PlayerId ->
                [DungeonEnlist2];
            _ ->
                []
        end
    end,
    Data2 = lists:flatmap(F, Data),
	{reply, Data2, State};

%% 默认匹配
handle_call(Event, _From, State) ->
    catch util:errlog("mod_team_agent:handle_call not match: ~p", [Event]),
    {reply, ok, State}.

%% 删除获取队伍暂离成员列表.
handle_cast({'del_tmb_offline', Id}, State) ->
    case get(Id) of
         undefined ->
             [];
         _TMBOffline ->             
             erase(Id)
	end,
	{noreply, State};

%% 删除副本招募.
handle_cast({'del_dungeon_enlist2', PlayerId}, State) ->
    Data = get(),
    F = fun({Key, _}) ->
        case Key of
            {dungeon_enlist2, _PlayerId, _SceneId} when _PlayerId =:= PlayerId ->
                erase(Key);
            _ ->
                skip
        end
    end,
    lists:foreach(F, Data),
	{noreply, State};

%% 默认匹配
handle_cast(Event, State) ->
    catch util:errlog("mod_team_agent:handle_cast not match: ~p", [Event]),
    {noreply, State}.

%% 检测副本招募是否还有效.
handle_info('check_enlist2_alive', State) ->

	%1.一分钟检测一次.
	erlang:send_after(60 * 1000, self(), 'check_enlist2_alive'),

    Data = get(),
    F = fun({Key, _}) ->
        case Key of
            {dungeon_enlist2, _PlayerId, _SceneId} ->				 
		         case lib_player:get_player_info(_PlayerId, team) of
					 
					 %1.玩家在线.
					{ok, _PlayerId2, _PlayerTid2, _TeamPid2, _Level2, 
					 _Physical2, _Scene2, _CopyId2, _X2, _Y2} ->
						if 
							%1.如果已经进去副本了，招募要删掉.
							is_pid(_CopyId2) ->
								erase(Key);
							
							%2.如果有组队，招募是正常的.
							is_pid(_TeamPid2) ->
								skip;							
							
							%3.没有组队，招募要删掉.
							true ->
								erase(Key)
						end;

					%2.玩家不在线.
					_ -> 
						erase(Key)
		        end;                
            _ ->
                skip
        end
    end,
    lists:foreach(F, Data),

	{noreply, State};

%% 默认匹配
handle_info(Info, State) ->
    catch util:errlog("mod_team_agent:handle_info not match: ~p", [Info]),
    {noreply, State}.

%% 服务器停止.
terminate(_R, _State) ->
    ok.

%% 热代码替换.
code_change(_OldVsn, State, _Extra)->
    {ok, State}.
