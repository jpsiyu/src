%%%------------------------------------
%%% @Module  : mod_team_cast
%%% @Author  : zhenghehe
%%% @Created : 2010.07.06
%%% @Description: 组队模块cast
%%%------------------------------------
-module(mod_team_cast).
-export([handle_cast/2]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("team.hrl").

%% ------------------------------- 组队基础功能 --------------------------------

%% 申请加入队伍
handle_cast({'join_team_request', Id, Lv, Career, Realm, Nickname, Pid, SceneId, _JoinType}, State) ->
	mod_team_base:handle_cast({'join_team_request', Id, Lv, Career, Realm, Nickname, Pid, SceneId, _JoinType}, State);

%% 队长回应加入队伍申请
handle_cast({'join_team_response', Res, Uid, LeaderId}, State) ->
	mod_team_base:handle_cast({'join_team_response', Res, Uid, LeaderId}, State);

%% 退出队伍
handle_cast({'quit_team', Uid, Type, Scene}, State) ->
	mod_team_base:handle_cast({'quit_team', Uid, Type, Scene}, State);

%% 邀请加入组队
handle_cast({'invite_request', Uid, LeaderId, LeaderName, LeaderLv, LeaderGBid, LeaderGid}, State) ->
	mod_team_base:handle_cast({'invite_request', Uid, LeaderId, LeaderName, LeaderLv, LeaderGBid, LeaderGid}, State);

%% 被邀请人回应加入队伍请求
handle_cast({'invite_response', Uid, Pid, Nick, Lv, Career, SceneId}, State) ->
	mod_team_base:handle_cast({'invite_response', Uid, Pid, Nick, Lv, Career, SceneId}, State);

%% 踢出队伍
handle_cast({'kick_out', Uid, LeaderId}, State) ->
	mod_team_base:handle_cast({'kick_out', Uid, LeaderId}, State);

%% 委任队长
handle_cast({'change_leader', Uid, LeaderId}, State) ->
	mod_team_base:handle_cast({'change_leader', Uid, LeaderId}, State);

%% 解散队伍
handle_cast('disband', State) ->
	mod_team_base:handle_cast('disband', State);

%% 查看队伍信息
handle_cast({'send_team_info', Id}, State) ->
	mod_team_base:handle_cast({'send_team_info', Id}, State);

%% 更新所有队员信息.
handle_cast('update_team_info', State) ->
	mod_team_base:handle_cast('update_team_info', State);

%% 登录马上归队
handle_cast({'login_back_to_team', Uid, Pid, Nick, Lv, Career}, State) ->
	mod_team_base:handle_cast({'login_back_to_team', Uid, Pid, Nick, Lv, Career}, State);

%% 上线归队
handle_cast({'back_to_team', Uid, _Pid, Nick, _DungeonScene, _Lv, _Career}, State) ->
	mod_team_base:handle_cast({'back_to_team', Uid, _Pid, Nick, _DungeonScene, _Lv, _Career}, State);

%% 设置队员等级.
handle_cast({'set_member_level', PlayerId, PlayerLevel}, State) ->
	mod_team_base:handle_cast({'set_member_level', PlayerId, PlayerLevel}, State);
	
%% 队伍聊天
handle_cast({'TEAM_MSG', Id, Nick, Realm, Sex, Bin, GM,Vip, Career}, State) ->
	mod_team_base:handle_cast({'TEAM_MSG', Id, Nick, Realm, Sex, Bin, GM,Vip, Career}, State);

%% ----------------------------- 组队物品掉落功能 ------------------------------

%% 掉落包分配
handle_cast({'DROP_DISTRIBUTION', [PlayerStatus, MonStatus, DropRule, DropList]}, State) ->
	mod_team_drop:handle_cast({'DROP_DISTRIBUTION', [PlayerStatus, MonStatus, DropRule, DropList]}, State);

%% 广播给队员
handle_cast({'send_to_member', Bin}, State) ->
	mod_team_drop:handle_cast({'send_to_member', Bin}, State);

%% 队友完成任务处理
handle_cast({'fin_task', Mon}, State) ->
	mod_team_drop:handle_cast({'fin_task', Mon}, State);

%% 队友完成任务搜集处理
handle_cast({'fin_task_goods', TaskList, Mon}, State) ->
	mod_team_drop:handle_cast({'fin_task_goods', TaskList, Mon}, State);

%% 队友杀死怪物处理
handle_cast({'kill_mon', Mon, _AttScene}, State) ->
	mod_team_drop:handle_cast({'kill_mon', Mon, _AttScene}, State);

%% ------------------------------- 组队副本功能 --------------------------------

%% 设置dungeon_pid
handle_cast({'set_dungeon_pid', DungeonPid}, State) ->
	mod_team_dungeon:handle_cast({'set_dungeon_pid', DungeonPid}, State);

%% 队伍仲裁启动
handle_cast({'arbitrate_req', Uid, Nick, Msg, Type, Args}, State) ->
	mod_team_dungeon:handle_cast({'arbitrate_req', Uid, Nick, Msg, Type, Args}, State);

%% 队员回应仲裁
handle_cast({'arbitrate_res', Uid, Res, RecordId}, State) ->
	mod_team_dungeon:handle_cast({'arbitrate_res', Uid, Res, RecordId}, State);

%% 赞成传送到副本区(8.29)
handle_cast({'goto_dungeon_area', Uid}, State) ->
	mod_team_dungeon:handle_cast({'goto_dungeon_area', Uid}, State);

%% 创建锁妖塔副本
handle_cast({'create_tower', TowerSceneId}, State) ->
	mod_team_dungeon:handle_cast({'create_tower', TowerSceneId}, State);

%% 创建多人副本.
handle_cast({'create_multi_dungeon', Data}, State) ->
	mod_team_dungeon:handle_cast({'create_multi_dungeon', Data}, State);

handle_cast(_R, State) ->
    catch util:errlog("mod_team:handle_cast not match: ~p", [_R]),
    {noreply, State}.

%%更新队伍资料
%handle_cast({'UPDATE_TEAM_INFO', Team}, State) ->
%    send_team_info(Team),
%    {noreply, State};

%% %% 创建跳层锁妖塔副本
%% handle_cast({create_tower_by_level, [_TowerSceneId, _ActiveSceneId]}, _State) ->
%%     ExReward = case is_three_career(State) of
%%         true -> 1.2;
%%         false -> 1
%%     end,
%%     Now = util:unixtime(),
%%     DPid = mod_dungeon:start_tower_by_level(self(), 0, TowerSceneId, [{State#team.leaderid, State#team.leaderpid}], 0, [[{TowerSceneId, Now}], [], Now, [], ExReward, 0], ActiveSceneId),
%%     TowerInfo = data_tower:get(ActiveSceneId),
%%     case catch gen_server:call(DPid, {check_enter, ActiveSceneId, State#team.leaderid, 0}) of
%%         {'EXIT', _} -> {noreply, State};
%%         {false, _Msg} -> {noreply, State};
%%         {true, SceneId} -> 
%%             %% 计时开始
%%             %BinData = pt:pack(28007, <<>>),
%%             %lib_send:send_to_uid(State#team.leaderid, BinData),
%%             [Mb#mb.pid ! {'enter_tower_by_level', [TowerInfo#tower.time, TowerSceneId, SceneId, DPid]} || Mb <- State#team.member],
%%             %mod_daily:increment(State#team.leaderid, TowerSceneId),
%%             mod_daily:increment(State#team.leaderid, 2800),
%%             {noreply, State#team{dungeon_pid = DPid, dungeon_scene = TowerSceneId}}
%%     end;
%%     skip;