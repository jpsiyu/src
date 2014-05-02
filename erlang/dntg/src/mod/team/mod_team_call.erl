%%%------------------------------------
%%% @Module  : mod_team_call
%%% @Author  : zhenghehe
%%% @Created : 2010.07.06
%%% @Description: 组队模块call
%%%------------------------------------
-module(mod_team_call).
-export([handle_call/3]).
-include("team.hrl").
-include("server.hrl").

%% ------------------------------- 组队基础功能 --------------------------------

%% 获取队伍成员列表
handle_call('get_member_list', _From, State) ->
	mod_team_base:handle_call('get_member_list', _From, State);

%% 获取队员平均等级
handle_call('get_avg_level', _From, State) ->
    mod_team_base:handle_call('get_avg_level', _From, State);

%% 获取State
handle_call('get_team_state', _From, State) ->
	mod_team_base:handle_call('get_team_state', _From, State);

%% 获取队长id 
handle_call('get_leader_id', _From, State) ->
    mod_team_base:handle_call('get_leader_id', _From, State);

%% 获取队伍队员人数
handle_call('get_member_count', _From, State) ->
    mod_team_base:handle_call('get_member_count', _From, State);
    
%% 设置队伍拾取方式 
handle_call({'set_distribution_type', Num}, {From, Other}, State) ->
	mod_team_base:handle_call({'set_distribution_type', Num}, {From, Other}, State);

%% 设置队员加入方式(1:不自动，2:自动)
handle_call({'set_join_type', Num}, {From, Other}, State) ->
	mod_team_base:handle_call({'set_join_type', Num}, {From, Other}, State);

%% 设置队员邀请玩家加入队伍(0:不允许，1:允许)
handle_call({'set_allow_member_invite', Num}, {From, Other}, State) ->
	mod_team_base:handle_call({'set_allow_member_invite', Num}, {From, Other}, State);

%% 检查队伍成员等级
handle_call({'check_level', Level, PlayerId, PlayerLevel}, _From, State) ->
	mod_team_base:handle_call({'check_level', Level, PlayerId, PlayerLevel}, _From, State);

%% 设置九重天双倍掉落(0:不是，1:是)
handle_call({'set_duoble_drop', Num}, {From, Other}, State) ->
	mod_team_base:handle_call({'set_duoble_drop', Num}, {From, Other}, State);

%% ------------------------------- 组队副本功能 --------------------------------

%% 获取副本id
handle_call(get_dungeon, _From, State) ->
    mod_team_dungeon:handle_call(get_dungeon, _From, State);

%% 创建队伍的副本服务
handle_call({create_dungeon, From, DunId, DunName, Level, RoleInfo}, _From, State) ->
	mod_team_dungeon:handle_call({create_dungeon, From, DunId, DunName, Level, RoleInfo}, _From, State);

%% 检查队伍成员进入副本的体力值是否满足条件.
handle_call({'check_dungeon_physical', PhysicalId, PlayerId, PlayerPhysical}, _From, State) ->
	mod_team_dungeon:handle_call({'check_dungeon_physical', PhysicalId, PlayerId, PlayerPhysical}, _From, State);

handle_call(_R, _From, State) ->
    catch util:errlog("mod_team:handle_call not match: ~p", [_R]),
    {reply, _R, State}.

%%#############################################################################################################

%%更改队名
%handle_call({'CHANGE_TEAMNAME', TeamName}, {From, _}, State) ->
%    case From =:= State#team.leaderpid of
%        false -> %%不是队长，没有权限修改队名
%            {reply, not_leader, State};
%        true -> 
%            NewState = State#team{teamname = TeamName},
%            %%通知队员队名改变了
%            {ok, BinData} = pt_24:write(24015, TeamName),
%            [lib_send:send_to_uid(X#mb.id, BinData) || X <- NewState#team.member],
%            {reply, 1, NewState}
%    end;


