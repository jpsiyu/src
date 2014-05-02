%%%------------------------------------
%%% @Module  : lib_team
%%% @Author  : zhenghehe
%%% @Created : 2010.08.07
%%% @Description: 组队模块公共函数
%%%------------------------------------

-module(lib_team).

%% 公共函数：外部模块调用.
-export([
        get_leaderid/1,                %% 获取队长id
        get_member_lv/1,               %% 获取队员等级
		get_dungeon_pid/1,             %% 获取队伍副本进程id
        get_team_dungeon_sid/1,        %% 获取队伍副本场景id
        get_team_num_ets/1,            %% 获取队伍人数(ets表)
		get_mb_num_join_type/1,        %% 获取队员数量和加入方式
        get_mb_num/1,                  %% 获取队伍成员数量
        get_mb_ids/1,                  %% 获取队员id列表
		get_members/1,                 %% 获取队员列表
		trans/1,                       %% 获取组队模块的数据.
        set_dungeon_pid/2,             %% 设置副本进程PID.
        set_member_level/1,            %% 设置队员等级.
        send_to_member/2,              %% 广播给队员
        send_to_team_where_I_am/2,     %% 告诉队友我在哪里
		update_team_info/1,            %% 更新所有队员信息.
		delete_proclaim/1,             %% 招募-删除招募信息
        delete_tmb/1,                  %% 删除离线组队记录
        back_to_dungeon/1,             %% 离线归队副本处理        
        check_level/4,                 %% 检查队伍成员等级
		check_dungeon_physical/4,      %% 检查进入副本的体力值是否满足条件.
        team_arbitrate/6,              %% 启动队员投票
        drop_distribution/4,           %% 掉落包分配
        create_dungeon/6               %% 创建副本
%%      set_line/2,                    %% 设置线路
%%      delete_dungeon_proclaim/1,     %% 副本招募-删除副本招募
%%      hange_line_into_team/3,        %% 切线进队
%%      is_change_line_into_team/2,    %% 切线进队
%%      kfz_3v3_team/1,                %% 跨服战开启组队
%%      drop_choose_success/2,         %% 拾取掉落包成功反馈
%%      drop_choose_fail/2,            %% 拾取掉落包失败反馈
]).

%% 内部函数：组队服务本身调用.
-export([
        get_avg_level/1,               %% 获取队员平均等级
        get_max_level/1,               %% 获取队员最高等级
        set_ets_team/2,                %% 设置组队缓存
        clear_ets_team/1,              %% 组队缓存清除
        send_team_info/1,              %% 向队伍所有成员发送队伍信息
        send_team/2,                   %% 向所有队员发送信息
        pack_member/1,                 %% 组装队员列表
        quit_team_offline/6,           %% 离线暂离队处理
        quit_team_quit_dungeon/2,      %% 退队并且退出副本，不能进入原来的副本
        turn_choose/3,                 %% 轮流拾取序号 
        turn_choose/4,                 %% 重新遍历一次
		rand_drop/6,                   %% 随机掉落.
        turn_drop/7,                   %% 轮流掉落
        single_drop/4,                 %% 单人拾取掉落包列表
        team_add_exp/3,                %% 组队分成经验
        is_three_career/1,             %% 队伍中是否有三种职业
        is_two_sex/1,                  %% 队伍中是否有两个性别
        change_state/2,                %% 改变队伍状态(0:正常;1:在副本)
        delete_enlist2/1,              %% 副本招募-删除副本招募(8.28)
        change_enlist2/3,              %% 副本招募-更改副本招募
        dungeon_enlist2_full/1,        %% 副本招募-副本招募完队员进入副本倒计时
        change_enlist2_mb_num/2,       %% 副本招募-招募组队人数更改
        extand_exp/2,                  %% 师徒关系增加打怪经验
        clean_extand_exp/2             %% 退队去除附加经验		
]).

-include("common.hrl").
%% -include("record.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("team.hrl").
-include("dungeon.hrl").
-include("unite.hrl").


%% --------------------------------- 公共函数 ----------------------------------


%% 获取队长id
get_leaderid(TeamPid) ->
    case is_pid(TeamPid) of
        false -> 0;
        true -> gen_server:call(TeamPid, 'get_leader_id')
    end.

%% 获取队员等级
get_member_lv(Id) ->
    case lib_player:get_player_info(Id, lv) of
		Level when is_integer(Level) andalso Level > 0 ->
			Level;
        _Other -> 
			0
    end.

%% 获取副本进程id
get_dungeon_pid(TeamPid) ->
    case is_pid(TeamPid) of
        false -> false;
        true -> gen_server:call(TeamPid, 'get_dungeon_pid')
    end.

%% 获取队伍副本场景
get_team_dungeon_sid(TeamPid) ->
    case catch gen:call(TeamPid, '$gen_call', 'get_team_state') of
        {'EXIT', _} -> 
			0;
        {ok, State} when is_record(State, team) andalso 
					      is_integer(State#team.dungeon_scene) -> 
			State#team.dungeon_scene;
        _ -> 
			0
    end.

%% 获取队伍人数(ets表)
get_team_num_ets(TeamPid) ->
    case is_pid(TeamPid) of
        false -> 0;
        true -> 
            case cache_op:lookup_unite(?ETS_TEAM, TeamPid) of
                [] -> 0;
                [R] -> R#ets_team.mb_num
            end
    end.

%% 获取队员数量和加入方式
get_mb_num_join_type(TeamPid) ->
    case cache_op:lookup_unite(?ETS_TEAM, TeamPid) of
        [] -> error;
        [T] -> {T#ets_team.mb_num, T#ets_team.join_type}
    end.

%% 获取队伍成员数量(包括队长)
get_mb_num(TeamPid) ->
    case is_pid(TeamPid) of
        false -> 0;
        true -> 
            case catch gen_server:call(TeamPid, 'get_member_count') of
                {'EXIT', _} -> 0;
                Other -> Other
            end
    end.

%% 获取队员id列表
get_mb_ids(TeamPid) ->
	case catch gen:call(TeamPid, '$gen_call', 'get_team_state') of
		{'EXIT', _} -> 
			[];
		{ok, State} when is_record(State, team) -> 
			[Mb#mb.id || Mb <- State#team.member];
	    _ ->
			[]
	end.

%% 获取队员列表
get_members(TeamPid) ->
	case catch gen:call(TeamPid, '$gen_call', 'get_team_state') of
		{'EXIT', _} ->
			[];
		{ok, State} when is_record(State, team) ->
			State#team.member;
	    _ ->
			[]
	end.

%% 获取组队模块的数据.
%% @return pid_team 组队进程ID.
%% @return physical 玩家体力值.
trans(Status) ->
   {ok, 
		Status#player_status.id,
		Status#player_status.tid,
		Status#player_status.pid_team, 
		Status#player_status.lv, 
		%%  change by xieyunfei
		Status#player_status.physical#status_physical.physical_count,
		Status#player_status.scene,
		Status#player_status.copy_id,
		Status#player_status.x,
		Status#player_status.y
	}.
   
%% 设置副本进程PID
set_dungeon_pid(TeamPid, Dungeon_pid) ->  
    case is_pid(TeamPid) of
        false -> ok;
        true ->
            gen_server:cast(TeamPid, {'set_dungeon_pid', Dungeon_pid})
    end.

%% 设置队员等级.
set_member_level(PlayerStatus) ->  
    case is_pid(PlayerStatus#player_status.pid_team) of
        false -> ok;
        true ->
            gen_server:cast(PlayerStatus#player_status.pid_team, 
							{'set_member_level', 
							PlayerStatus#player_status.id,
							PlayerStatus#player_status.lv})
    end.

%% 设置线路 
%% set_line(Id, Line) -> 
%%     case ets:lookup(?ETS_TEAM_ENLIST, Id) of
%%         [] -> ok;
%%         [R] -> 
%%             ets:insert(?ETS_TEAM_ENLIST, R#ets_team_enlist{online_flag = Line})
%%     end.

%% 广播给队员
send_to_member(TeamPid, Bin) ->
    case is_pid(TeamPid) andalso is_binary(Bin) of
        false -> false;
        true -> gen_server:cast(TeamPid, {'send_to_member', Bin})
    end.

%% 告诉队友我在哪里
send_to_team_where_I_am(PS, SceneName) -> 
    case is_pid(PS#player_status.pid_team) of
        true ->
            {ok, BinData} = pt_240:write(24054, [PS#player_status.id, SceneName]), 
            send_to_member(PS#player_status.pid_team, BinData);
        false -> skip
    end.

%% 更新所有队员信息.
update_team_info(TeamPid) ->
    case is_pid(TeamPid) of
        false -> false;
        true -> gen_server:cast(TeamPid, 'update_team_info')
    end.

%% 删除招募信息 
delete_proclaim(Id) ->
    cache_op:match_delete_unite(?ETS_TEAM_ENLIST, #ets_team_enlist{id = {'_', Id}, _ = '_'}).

%% 删除离线组队记录
delete_tmb(Id) ->
    %%cache_op:match_delete_unite(?ETS_TMB_OFFLINE, #ets_tmb_offline{id = Id, _ = '_'}).
    mod_team_agent:del_tmb_offline(Id).

%% 离线归队副本处理
back_to_dungeon(Status) ->
	case mod_dungeon_agent:get_dungeon_record(Status#player_status.id) of
		[] -> back_to_dungeon2(Status);
		[Record] ->
			SceneId = Record#dungeon_record.scene_id,
			case lists:member(SceneId, ?BACK_DUNGEON_LIST) of
				true ->
					%1.单人副本上线重连.
					back_to_dungeon1(Status, Record);
				false ->
					%2.多人副本上线重连.
					back_to_dungeon2(Status)
			end	
	end.

%% 离线归队副本处理1.
back_to_dungeon1(Status, Record) ->
	%1.副本上线重连.	
	Status2 =
        case catch gen_server:call(Record#dungeon_record.dungeon_pid, 
									{join_online, 
									Status#player_status.id,
									Status#player_status.pid,  
									Status#player_status.pid_dungeon_data}) of
            {'EXIT', _} -> Status;
            {true, MaxCombo1} ->
				Group1 = 
					if 
						Record#dungeon_record.scene_id == 234 -> 1; 
						Record#dungeon_record.scene_id == 235 -> 1;
						true -> Status#player_status.group
					end,
				Scene1 = data_scene:get(Record#dungeon_record.scene_id),
                Status1 = Status#player_status{
						      scene = Record#dungeon_record.scene_id, 
						      x = Scene1#ets_scene.x, 
						      y = Scene1#ets_scene.y, 
						      copy_id = Record#dungeon_record.dungeon_pid,
						      group = Group1},
                lib_skill_buff:coin_dun_combo_skill_online(Status1, MaxCombo1)
		end,

    %2.离线归队处理.
    case mod_team_agent:get_tmb_offline(Status2#player_status.id) of
        [] -> 
			Status2;
        [R] -> 
            Time = util:unixtime(),
			%离队时间是否少于5分钟.
            case Time - R#ets_tmb_offline.offtime =< 300 of
                true ->
					%是否为组队进程.
                    case is_pid(R#ets_tmb_offline.team_pid) andalso 
							 misc:is_process_alive(R#ets_tmb_offline.team_pid) of
                        true ->
                            TeamMemberNum = get_mb_num(R#ets_tmb_offline.team_pid),
							%队伍人数小于5人
                            case TeamMemberNum < 5 of 
                                true ->
									%归队.
                                    catch gen_server:cast(R#ets_tmb_offline.team_pid, 
															{'login_back_to_team', 
															Status2#player_status.id, 
															Status2#player_status.pid, 
															Status2#player_status.nickname, 
															Status2#player_status.lv, 
															Status2#player_status.career}),
                                    Status2#player_status{pid_team = R#ets_tmb_offline.team_pid, 
																   leader = 2};
                                false -> Status2
                            end;
                        false -> Status2
                    end;
                false -> Status2
            end
    end.

%% 离线归队副本处理2.
back_to_dungeon2(Status) ->
    %% 离线归队副本处理
    case mod_team_agent:get_tmb_offline(Status#player_status.id) of
        [] -> %lib_team:delete_tmb_all_server(Status#player_status.id);
			Status;
        [R] -> 
            Time = util:unixtime(),
			%离队时间是否少于5分钟.
            case Time - R#ets_tmb_offline.offtime =< 300 of
                true ->
					%是否为组队进程.
                    case is_pid(R#ets_tmb_offline.team_pid) andalso 
							 misc:is_process_alive(R#ets_tmb_offline.team_pid) of
                        true ->
                            TeamMemberNum = get_mb_num(R#ets_tmb_offline.team_pid),
							%队伍人数小于5人
                            case TeamMemberNum < 5 of 
                                true ->
									%归队.
                                    catch gen_server:cast(R#ets_tmb_offline.team_pid, 
															{'login_back_to_team', 
															Status#player_status.id, 
															Status#player_status.pid, 
															Status#player_status.nickname, 
															Status#player_status.lv, 
															Status#player_status.career}),
                                    Status1 = Status#player_status{pid_team = R#ets_tmb_offline.team_pid, 
																   leader = 2},
									%判断副本进程.
                                    case is_pid(R#ets_tmb_offline.dungeon_pid) of
                                        true ->
											%判断副本场景.
                                            case R#ets_tmb_offline.dungeon_scene of
                                                0 -> Status1;
                                                DSceneId -> 
													%是否为副本场景.
                                                    case lib_scene:is_dungeon_scene(R#ets_tmb_offline.dungeon_scene) of
                                                        true ->
                                                            case DSceneId of
                                                                0 -> Status1;
                                                                SceneId -> 
                                                                    Scene = data_scene:get(SceneId),
																	%是否大于副本可允许进入的最大人数
                                                                    case more_than_people(R#ets_tmb_offline.dungeon_begin_sid, TeamMemberNum) of
                                                                        true ->
																			%进入副本.
                                                                            case catch gen_server:call(R#ets_tmb_offline.dungeon_pid, 
																										{join_online, 
																										Status#player_status.id, 
																										Status#player_status.pid,
																										Status#player_status.pid_dungeon_data}) of
                                                                                {'EXIT', _} -> Status1;
                                                                                {true, MaxCombo} ->
																					Group2 = 
																						if 
																						    SceneId == 234 -> 1;
																						    SceneId == 235 -> 1;
																							true -> Status1#player_status.group
																						end,
                                                                                    NewStatus = Status1#player_status{scene = R#ets_tmb_offline.dungeon_scene, 
                                                                                        x = Scene#ets_scene.x, 
                                                                                        y = Scene#ets_scene.y, 
                                                                                        copy_id = R#ets_tmb_offline.dungeon_pid,
                                                                                        group = Group2},
                                                                                    lib_skill_buff:coin_dun_combo_skill_online(NewStatus, MaxCombo);
                                                                                _ -> Status1
                                                                            end;
                                                                        false -> Status1
                                                                    end
                                                            end;
                                                        false -> Status1
                                                    end
                                            end;
                                        false -> Status1
                                    end;
                                false -> Status
                            end;
                        false -> Status
                    end;
                false -> Status
            end
    end.

%% 是否大于副本可允许进入的最大人数
more_than_people(Scene, TeamMemNum) ->
    case data_dungeon:get(Scene) of
        Dun when is_record(Dun, dungeon) ->
            case lists:keyfind(less, 1, Dun#dungeon.condition) of
                false -> true;
                {less, Num} -> TeamMemNum + 1 =< Num
            end;
        _ -> true
    end.

%% 切线进队
%% change_line_into_team(PlayerId, LeaderId, Line) ->
%%     ets:insert(?ETS_CHANGE_LINE_INFO_TEAM, #ets_change_line_into_team{id = PlayerId, leader_id = LeaderId, line = Line}).
%% 
%% is_change_line_into_team(PlayerId, Line) -> 
%%     Res = case ets:lookup(?ETS_CHANGE_LINE_INFO_TEAM, PlayerId) of
%%         [] -> skip;
%%         [R] -> 
%%             if R#ets_change_line_into_team.line == Line -> R#ets_change_line_into_team.leader_id;
%%                 true -> skip
%%             end
%%     end,
%%     ets:delete(?ETS_CHANGE_LINE_INFO_TEAM, PlayerId),
%%     Res.

%% 检查队伍成员等级，全部队员大于等于Lv时返回true，否则返回false
check_level(TeamPid, Level, PlayerId, PlayerLevel) ->
    gen_server:call(TeamPid, {'check_level', Level, PlayerId, PlayerLevel}).

%% 检查队伍成员进入副本的体力值是否满足条件，全部队员满足时返回true，否则返回false
check_dungeon_physical(TeamPid, PhysicalId, PlayerId, PlayerPhysical) ->
    gen_server:call(TeamPid, {'check_dungeon_physical', PhysicalId, PlayerId, PlayerPhysical}).

%% 掉落包分配
drop_distribution(PlayerStatus, MonStatus, DropRule, DropList) ->
    case is_pid(PlayerStatus#player_status.pid_team) of
        true -> 
            gen_server:cast(PlayerStatus#player_status.pid_team, 
							{'DROP_DISTRIBUTION', [PlayerStatus, MonStatus, DropRule, DropList]});
        false -> 
            single_drop(PlayerStatus, MonStatus, DropRule, DropList)
    end.

%% 队伍投票
team_arbitrate(TeamPid, Id, Nick, Msg, Type, Args) ->
     gen_server:cast(TeamPid, {'arbitrate_req', Id, Nick, Msg, Type, Args}).

%% 创建副本服务
create_dungeon(TeamPid, From, DunId, DunName, Level, RoleInfo) ->
    gen_server:call(TeamPid, {create_dungeon, From, DunId, DunName, Level, RoleInfo}).


%% --------------------------------- 内部函数 ----------------------------------


%% 获取队员平均等级
get_avg_level(State) ->
    L1 = [get_member_lv(R#mb.id) || R <- State#team.member],
    L2 = [M || M <- L1, M =/= 0],
    round(lists:sum(L2)/length(L2)).

%% 获取队员最高等级
get_max_level(State) ->
    L1 = [get_member_lv(R#mb.id) || R <- State#team.member],
    lists:max(L1).

%% 设置组队缓存
set_ets_team(Team, TeamPid) ->
    case is_list(Team#team.member) andalso is_integer(Team#team.join_type) of
        true ->
            cache_op:insert_unite(?ETS_TEAM, #ets_team{
                    team_pid = TeamPid,
                    mb_num = length(Team#team.member), 
                    join_type = Team#team.join_type}),
            %% 更新副本招募
            change_enlist2_mb_num(Team#team.leaderid, length(Team#team.member));
        false -> ok
    end.

%% 组队缓存清除
clear_ets_team(TeamPid) ->
    cache_op:delete_unite(?ETS_TEAM, TeamPid).

%% 向队伍所有成员发送队伍信息
send_team_info(Team) ->
    State = case is_pid(Team#team.dungeon_pid) of
        true -> 1;
        false -> 0
    end,
    Data = [Team#team.leaderid, 
			Team#team.teamname, 
			pack_member(Team#team.member), 
			Team#team.distribution_type, 
			Team#team.join_type, 
			State, 
			Team#team.is_allow_mem_invite,
			Team#team.is_double_drop],
    {ok, BinData} = pt_240:write(24010, Data),
    send_team(Team, BinData).

%% 向所有队员发送信息
send_team(Team, Bin) ->
    F = fun(MemberId) ->
            lib_server_send:send_to_uid(MemberId, Bin)
    end,
    [F(M#mb.id)||M <- Team#team.member].

%% 组装队员列表
pack_member(MemberList) when is_list(MemberList) ->
    % put(member_place, 1), %% 为队员编号
    F = fun(Mb) ->
            Id = Mb#mb.id,
            Location = Mb#mb.location,
            case lib_player:get_player_info(Id) of
                PlayerStatus when is_record(PlayerStatus, player_status)-> 
                    SceneName = case lib_scene:get_data(PlayerStatus#player_status.scene) of
                        S when is_record(S, ets_scene) -> S#ets_scene.name;
                        _ -> <<>>
                    end,
                    [[PlayerStatus#player_status.id, 
					  PlayerStatus#player_status.lv, 
					  PlayerStatus#player_status.career, 
					  PlayerStatus#player_status.realm, 
					  PlayerStatus#player_status.nickname, 
					  PlayerStatus#player_status.sex,
					  PlayerStatus#player_status.vip#status_vip.vip_type, 
					  PlayerStatus#player_status.goods#status_goods.equip_current, 
					  PlayerStatus#player_status.hp, 
					  PlayerStatus#player_status.hp_lim, 
					  Location, 
					  PlayerStatus#player_status.mp, 
					  PlayerStatus#player_status.mp_lim, 
					  PlayerStatus#player_status.image, 
					  SceneName,
					  PlayerStatus#player_status.goods#status_goods.fashion_weapon,
					  PlayerStatus#player_status.goods#status_goods.fashion_armor
					 ]];
                _Other -> 
					[]
            end
    end,
    lists:flatmap(F, MemberList).

%% 离线暂离队处理
quit_team_offline(Uid, Nick, TeamPid, Team, Scene, DunPid) ->
    Time = util:unixtime(),
    %% 下线时记录消息
    case lib_scene:is_dungeon_scene(Scene) of %andalso ResScene /= 660 andalso ResScene /= 661 andalso ResScene /= 662 andalso ResScene /= 233 of %% 如果在古墓场景里面就不记录下线信息
        true ->
            %cache_op:insert_unite(?ETS_TMB_OFFLINE, #ets_tmb_offline{id = Uid, team_pid = TeamPid, offtime = Time, dungeon_scene = Scene, dungeon_pid = DunPid, dungeon_begin_sid = Team#team.dungeon_scene});
            mod_team_agent:set_tmb_offline(#ets_tmb_offline{id = Uid, team_pid = TeamPid, offtime = Time, dungeon_scene = Scene, dungeon_pid = DunPid, dungeon_begin_sid = Team#team.dungeon_scene});
        false ->
            %cache_op:insert_unite(?ETS_TMB_OFFLINE, #ets_tmb_offline{id = Uid, team_pid = TeamPid, offtime = Time})
            mod_team_agent:set_tmb_offline(#ets_tmb_offline{id = Uid, team_pid = TeamPid, offtime = Time})
    end,
    {ok, BinData} = pt_110:write(11004, Nick ++ data_team_text:get_team_msg(4)),
    send_team(Team, BinData).

%% 退队并且退出副本，不能进入原来的副本
quit_team_quit_dungeon(DungeonPid, Uid) ->
    %lib_dungeon:quit(DungeonPid, Uid, 1), %% 设置个人状态
    %lib_dungeon:clear(role, Dungeon_pid), %% 清理副本场景(如果是最后一个人)
	%2.一些特定副本下线不清除，要断线重连.
    case is_pid(DungeonPid) of
        false -> skip;
        true -> 
		    case gen:call(DungeonPid, '$gen_call', 'get_begin_sid') of
		        {'EXIT', _} -> skip;
		        {ok, SceneId} when is_integer(SceneId) ->
				    case lists:member(SceneId, ?BACK_DUNGEON_LIST) of
				        true ->
				            skip;
				        _Other ->
							lib_dungeon:quit(DungeonPid, Uid, 1), %% 设置个人状态
							lib_dungeon:clear(role, DungeonPid)
					end;
		        _ -> skip
		    end
	end,
    ok.

%% 轮流拾取序号 
%% Num:上一次标记的拾取位置
%% Team:队伍记录
%% F:判断是否可以捡取的函数 
%% L:队员队列
turn_choose(Num, Team, F) ->
    case Num >= ?TEAM_MEMBER_MAX of
        true -> turn_choose(once, 0, Team, F);
        false ->
            case lists:keyfind(Num + 1, 5, Team#team.member) of
                false -> turn_choose(Num + 1, Team, F);
                Mb ->
                    case F(Mb) of
                        [] -> turn_choose(Num + 1, Team, F);
                        [R] -> {R, Num + 1}
                    end
            end
    end.

%% 重新遍历一次
turn_choose(once, Num, Team, F) ->
    case Num >= ?TEAM_MEMBER_MAX of
        true -> {none, none};
        false ->
            case lists:keyfind(Num + 1, 5, Team#team.member) of
                false -> turn_choose(once, Num + 1, Team, F);
                Mb ->
                    case F(Mb) of
                        [] -> turn_choose(once, Num + 1, Team, F);
                        [R] -> {R, Num + 1}
                    end
            end
    end.

%% 单人拾取掉落包列表
single_drop(PlayerStatus, MonStatus, DropRule, DropList)-> 
    F = fun(DropItem) ->
           lib_goods_drop:handle_drop(PlayerStatus, MonStatus, DropRule, DropItem)
    end,
    L = [F(X) || X <- DropList],
    lib_goods_drop:send_drop(PlayerStatus, MonStatus, DropRule, L).

%% 随机掉落
rand_drop([], [_MonStatus, _DropRule], _PlayerList1, _PlayerList2, _Num, Result) -> 
    Result;
rand_drop(DropList, [MonStatus, DropRule], PlayerList1, PlayerList2, Num, Result) ->
	case Num of
		%1.已经分完一轮.
		0 ->
			NewNum = length(PlayerList1),
			rand_drop(DropList, [MonStatus, DropRule], PlayerList1, PlayerList1, NewNum, Result);
		
		%2.继续分下一个.
		_Other ->		
		    [H | T] = DropList, 
		    Rand = util:rand(1, 500) rem Num + 1, %% 随机
		    Player1 = lists:nth(Rand, PlayerList2),
			PlayerList3 = lists:delete(Player1, PlayerList2), 
		    DropBin = lib_goods_drop:handle_drop(Player1, MonStatus, DropRule, H),
		    rand_drop(T, [MonStatus, DropRule], PlayerList1, PlayerList3, Num-1, [DropBin | Result])
    end.

%% 轮流掉落
turn_drop([], [_MonStatus, _DropRule], _F, _Team, Num, _KPlayer, Result) -> 
    {Result, Num};
turn_drop(DropList, [MonStatus, DropRule], F, Team, Num, KPlayer, Result) -> 
    {R, Num1} = case Num >= ?TEAM_MEMBER_MAX of
        true -> turn_choose(once, 0, Team, F);
        false -> turn_choose(Num, Team, F)
    end,
    case R =:= none of
        false -> 
            [H | T] = DropList,
            DropBin = lib_goods_drop:handle_drop(R, MonStatus, DropRule, H),
            turn_drop(T, [MonStatus, DropRule], F, Team, Num1, KPlayer, [DropBin | Result]);
        true -> 
            [H | T] = DropList,
            DropBin = lib_goods_drop:handle_drop(KPlayer#player_status{id = 0}, MonStatus, DropRule, H),
            turn_drop(T, [MonStatus, DropRule], F, Team, Num1, KPlayer, [DropBin | Result])
    end.

%% 组队分成经验
team_add_exp({PlayerStatus, ExpX}, MemExp, Llpt) ->
    gen_server:cast(PlayerStatus#player_status.pid, {'EXP', MemExp * ExpX}),
    case Llpt > 0 of
        true -> 
            gen_server:cast(PlayerStatus#player_status.pid, {'llpt',Llpt});
        false -> skip
    end.

%% 队伍中是否有三种职业
is_three_career(State) when is_record(State, team)->
    L = [R#mb.career || R <- State#team.member],
    [lists:member(N, L)||N <- [1,2,3]] =:= [true, true, true];

is_three_career(L) ->
    L1 = [P#player_status.career || {P, _} <- L],
    [lists:member(N, L1)||N <- [1,2,3]] =:= [true, true, true].

is_two_sex(L) ->
    L1 = [P#player_status.sex||{P, _} <- L],
    [lists:member(X,L1)||X<-[1,2]] == [true, true].

%% 改变队伍状态(0:正常;1:在副本)
change_state(Team, State) ->
    {ok, Bin} = pt_240:write(24063, State),
    send_team(Team, Bin).

%% 副本招募-更改副本招募
change_enlist2(OldId, NewId, NewNick) ->
    case mod_team_agent:get_dungeon_enlist2_by_player_id(OldId) of
        [] -> skip;
        [R] -> 
            NewR = R#ets_dungeon_enlist2{id = NewId, nickname = NewNick},
			mod_team_agent:del_dungeon_enlist2(OldId), 
			mod_team_agent:set_dungeon_enlist2(NewR)
    end.

%% 副本招募-删除副本招募(8.28)
delete_enlist2(Id) ->
	mod_team_agent:del_dungeon_enlist2(Id).
 
%% 副本招募-删除副本招募
%% delete_dungeon_proclaim(Id) -> 
%%     ets:delete(?ETS_DUNGEON_ENLIST, Id).

%% 副本招募-副本招募完队员进入副本倒计时
dungeon_enlist2_full(Team) ->
    case Team#team.create_type == 3 of
        true -> 
            case length(Team#team.member) >= ?TEAM_MEMBER_MAX of
                true -> %% 满人了
                    SceneName = case lib_scene:get_data(Team#team.create_sid) of
                        S when is_record(S, ets_scene) -> S#ets_scene.name;
                        _ -> <<>>
                    end,
                    {ok, BinData} = pt_240:write(24052, [Team#team.create_sid, SceneName, 0]),
                    %[lib_send:send_to_uid(M#mb.id, BinData)||M <- Team#team.member, M#mb.id /= Team#team.leaderid],
                    send_team(Team, BinData),
                    ok;
                false -> skip
            end;
        false -> skip
    end.

%% 副本招募-招募组队人数更改
change_enlist2_mb_num(LeaderId, Num) ->
    case mod_team_agent:get_dungeon_enlist2_by_player_id(LeaderId) of
        [] -> 
			skip;
        RList ->
			[mod_team_agent:set_dungeon_enlist2(R#ets_dungeon_enlist2{mb_num = Num})||R<-RList]
    end.

%% 师徒关系增加打怪经验
%% Id:新进队伍的玩家id
extand_exp(Id, Team) ->
    Members = Team#team.member,
    case lists:keyfind(Id, 2, Members) of
        false -> Team;
        Mb1 ->
            %% 找出徒弟们的id
            ApprenticeIds = [],
            %% 如果有师傅，加经验
            NewMembers = Members,
            %% 队中有徒弟，给他们加经验
            F = fun([AppId], M) -> 
                     case lists:keyfind(AppId, 2, Members) of
                        false -> M;
                        AMb -> ExtandExp2 = 
                            case Mb1#mb.lv - AMb#mb.lv of
                                LvGap2 when LvGap2 =< 0 -> 1;
                                LvGap2 when LvGap2 > 50 -> 1.5;
                                LvGap2 -> LvGap2 / 100 + 1
                            end,
                            lists:keyreplace(AppId, 2, M,  AMb#mb{sht_exp = {Id, ExtandExp2}})
                    end
            end,
            %% 输出最后的队伍记录
            LastMember = lists:foldl(F, NewMembers, ApprenticeIds),
            Team#team{member = LastMember}
    end.

%% 退队去除附加经验
clean_extand_exp(Id, Team) -> 
    F = fun(Mb) -> 
           {Id1, _} = Mb#mb.sht_exp,
           case Id1 =:= Id of
               true -> Mb#mb{sht_exp = {0, 1}};
               false -> Mb
           end
   end,
   Team#team{member = [F(M) || M <- Team#team.member]}.

%%#############################################################################################################

%% 跨服战开启组队
%% kfz_3v3_team(Ids) ->
%%      gen_server:start(?MODULE, [kfz, Ids], []).

%% 获取队员数量和加入方式
%%get_mb_num_join_type(TeamPid) ->
%%    case catch gen:call(TeamPid,'$gen_call','get_team_state', 500) of
%%        {'EXIT', _} -> error;
%%        {ok, State} when (is_record(State, team) andalso is_list(State#team.member))-> {length(State#team.member), State#team.join_type};
%%        _ -> error
%%    end.

%% 拾取掉落包成功反馈
%%drop_choose_success(TeamPid, DropId) when is_integer(DropId) ->
%%    case is_pid(TeamPid) andalso is_process_alive(TeamPid) of
%%        true -> TeamPid ! {'CHOOSE_OK', DropId};
%%        false -> ok
%%    end.

%% 拾取掉落包失败反馈
%%drop_choose_fail(TeamPid, DropId) when is_integer(DropId) ->
%%    case is_pid(TeamPid) andalso is_process_alive(TeamPid) of
%%        true -> TeamPid ! {'CHOOSE_FAIL', DropId};
%%        false -> ok
%%    end.

%% init([kfz, Ids]) -> 
%%     State = init_kfz_3v3(Ids, #team{free_location = [1,2,3,4,5], distribution_type = 2, join_type = 0, create_type = 1, create_sid = 0}),
%%     send_team_info(State),
%%     lib_team:set_ets_team(State, self()),
%%     TeamId = lib_scene:get_global_scene_auto_id(),
%%     NewState = State#team{id = TeamId},
%%     misc:register(global, misc:team_process_name(TeamId), self()),
%%     {ok, NewState}.

%% init_kfz_3v3([], State) -> State;
%% init_kfz_3v3([Id|Tids], State) -> 
%%     case ets:lookup(?ETS_ONLINE, Id) of
%%         [] -> init_kfz_3v3(Tids, State);
%%         [R] ->
%%             [H|T] = State#team.free_location,
%%             NewMb = #mb{
%%                 id = R#ets_online.id,
%%                 pid = R#ets_online.pid,
%%                 nickname = R#ets_online.nickname,
%%                 lv = R#ets_online.lv,
%%                 location = H,
%%                 career = R#ets_online.career
%%             },
%%             State2 = case H == 1 of
%%                 true -> 
%%                     set_player_status_team(Id, R#ets_online.pid, 1), 
%%                     State#team{leaderid = Id, leaderpid = R#ets_online.pid};
%%                 false -> 
%%                     set_player_status_team(Id, R#ets_online.pid, 2), 
%%                     State
%%             end,
%%             gen_server:cast(R#ets_online.pid, {'SET_TEAM_PID', self()}),
%%             NewState = State2#team{member = [NewMb|State#team.member], free_location = T},
%%             init_kfz_3v3(Tids, NewState)
%%     end.


