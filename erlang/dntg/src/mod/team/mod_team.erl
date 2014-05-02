%%%------------------------------------
%%% @Module  : mod_team
%%% @Author  : zhenghehe
%%% @Created : 2010.07.06
%%% @Description: 组队模块
%%%------------------------------------

-module(mod_team).
-behaviour(gen_server).
-export([start/12, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("team.hrl").
%-include("record.hrl").
%-include("tower.hrl").

%% --------------------------------- 公共函数 ----------------------------------

%% 开启组队进程
start(Uid, Pid, DungeonDataPid, Nick, TeamName, Lv, Career, AutoEnter, Distribution, CreateType, CreateSid, IsAllowMemInvite) ->
    gen_server:start(?MODULE, [Uid, Pid, DungeonDataPid, Nick, TeamName, Lv, Career, AutoEnter, 
							   Distribution, CreateType, CreateSid, IsAllowMemInvite], []).

%% --------------------------------- 内部函数 ----------------------------------

%% 启动服务器.
init([Uid, Pid, DungeonDataPid, Nick, TeamName, Lv, Career, AutoEnter, Distribution, 
	CreateType, CreateSid, IsAllowMemInvite]) ->
    lib_team:delete_proclaim(Uid),
    TeamId = 1,
    State = #team{id = TeamId, 
                  leaderid = Uid, 
                  leaderpid = Pid,
				  leader_dungeon_data_pid = DungeonDataPid, 
                  teamname = TeamName, 
                  member = [#mb{id = Uid, 
                             pid = Pid, 
                             nickname = Nick, 
                             location = 1, 
                             lv = Lv, 
                             career = Career}], 
                  free_location = [2, 3, 4, 5], 
                  distribution_type = Distribution, 
                  join_type = AutoEnter, 
                  create_type = CreateType, 
                  create_sid = CreateSid,
				  is_allow_mem_invite = IsAllowMemInvite},
    lib_team:set_ets_team(State, self()),
    %misc:register(global, misc:team_process_name(TeamId), self()),
    {ok, State}.

%% 同步消息处理.
handle_call(Event, From, Status) ->
    mod_team_call:handle_call(Event, From, Status).

%% 异步消息处理.
handle_cast(Event, Status) ->
    mod_team_cast:handle_cast(Event, Status).

%% handle_info信息处理
handle_info(Info, Status) ->
    mod_team_info:handle_info(Info, Status).

%% 服务器停止.
terminate(_R, State) ->
	%1.更新玩家进程的组队数据.
    FunSetTeam = 
		fun(Member) ->
			gen_server:cast(Member#mb.pid, {'set_team', 0, 0, 0})
    	end,
    [FunSetTeam(Member)||Member <- State#team.member],

    %2.清理离线队员列表.
    %cache_op:match_delete_unite(?ETS_TMB_OFFLINE, 
	%							#ets_tmb_offline{team_pid = self(), _ = '_'}),
    lib_team:clear_ets_team(self()),

	%3.删除副本招募.
    lib_team:delete_enlist2(State#team.leaderid), 
    %misc:unregister(global, misc:team_process_name(State#team.id)),
    ok.

%% 热代码替换.
code_change(_OldVsn, State, _Extra)->
    {ok, State}.