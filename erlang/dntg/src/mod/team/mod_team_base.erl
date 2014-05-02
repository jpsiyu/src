%%------------------------------------------------------------------------------
%% @Module  : mod_team_base
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.18
%% @Description: 组队基础功能
%%------------------------------------------------------------------------------

-module(mod_team_base).
-export([handle_call/3, handle_cast/2, handle_info/2]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("team.hrl").

%% --------------------------------- 同步消息 ----------------------------------

%% 获取队伍成员列表
handle_call('get_member_list', _From, State) ->
    {reply, {member_list, State#team.member}, State};

%% 获取队员平均等级
handle_call('get_avg_level', _From, State) ->
    AvgLv = lib_team:get_avg_level(State),
    {reply, AvgLv, State};

%% 获取State
handle_call('get_team_state', _From, State) ->
    {reply, State, State};
    %{noreply, State};

%% 获取队长id 
handle_call('get_leader_id', _From, State) ->
    {reply, State#team.leaderid, State};

%% 获取队伍队员人数
handle_call('get_member_count', _From, State) ->
    {reply, length(State#team.member), State};
    
%% 设置队伍拾取方式 
handle_call({'set_distribution_type', Num}, {From, _}, State) ->
    case From =:= State#team.leaderpid of
        true ->
            {ok, BinData} = pt_240:write(24018, [1, Num]),
            lib_team:send_team(State, BinData),
            {reply, 1, State#team{distribution_type = Num}};
        false ->
            {reply, 0, State}
    end;

%% 设置队员加入方式(1:不自动，2:自动)
handle_call({'set_join_type', Num}, {From, _}, State) ->
    case From =:= State#team.leaderpid of
        true ->
            {ok, BinData} = pt_240:write(24034, Num),
            lib_team:send_team(State, BinData),
            lib_team:set_ets_team(State#team{join_type = Num}, self()),
            case Num == 1 of
                true -> lib_team:delete_enlist2(State#team.leaderid);
                false -> skip
            end,
            {reply, 1, State#team{join_type = Num}};
        false ->
            {reply, 0, State}
    end;

%% 设置队员邀请玩家加入队伍(0:不允许，1:允许)
handle_call({'set_allow_member_invite', Num}, {From, _}, State) ->
    case From =:= State#team.leaderpid of
        true ->
            {ok, BinData} = pt_240:write(24064, Num),
            lib_team:send_team(State, BinData),
            %lib_team:set_ets_team(State#team{join_type = Num}, self()),
            %case Num == 1 of
            %    true -> delete_enlist2(State#team.leaderid);
            %    false -> skip
            %end,
            {reply, 1, State#team{is_allow_mem_invite = Num}};
        false ->
            {reply, 2, State}
    end;

%% 设置九重天双倍掉落(0:不是，1:是)
handle_call({'set_duoble_drop', Num}, {From, _}, State) ->
    case From =:= State#team.leaderpid of
        true ->
            {ok, BinData} = pt_240:write(24066, Num),
            lib_team:send_team(State, BinData),
            {reply, Num, State#team{is_double_drop = Num}};
        false ->
            {reply, 2, State}
    end;

%% 检查队伍成员等级
handle_call({'check_level', Level, _PlayerId, _PlayerLevel}, _From, State) ->
	%1.定义检查等级的函数.
    CheckLevel = 
		fun(Member) ->
				Member#mb.lv < Level
%% 			MemberId = Member#mb.id,			
%% 			if 
%% 				%1.检测自己的等级.
%% 				MemberId =:= PlayerId ->
%% 				io:format("MemberId =~p,PlayerId=~p 1.1~n",[MemberId,PlayerId]),
%% 					PlayerLevel < Level;
%% 				%2.检测别人的等级.
%% 				true -> io:format("MemberId =~p,PlayerId=~p 1.2~n",[MemberId,PlayerId]),
%% 					case lib_player:get_player_info(MemberId) of
%% 						[] -> false;
%% 						PlayerStatus -> PlayerStatus#player_status.lv < Level
%% 					end
%% 			 end
		end,
	%2.检查所有成员的等级.
    Res = 
		case lists:filter(CheckLevel, State#team.member) of
			[] -> 
				true;
			_ -> 
				false
		end,
    {reply, Res, State}.

%% --------------------------------- 异步消息 ----------------------------------

%% 申请加入队伍
handle_cast({'join_team_request', Id, Lv, Career, Realm, Nickname, Pid, SceneId, _JoinType}, State) ->
    %case (JoinType == 0 andalso State#team.create_type == 1) orelse (JoinType == 1 andalso State#team.create_type == 3) of
    %    true -> 
    case length(State#team.member) of
        ?TEAM_MEMBER_MAX ->
            {ok, BinData} = pt_240:write(24002, 2),
            lib_server_send:send_to_uid(Id, BinData),
            {noreply, State};
        _Any ->
            WubianhaiResult = SceneId =:= data_wubianhai_new:get_wubianhai_config(scene_id) andalso _Any >= ?WUBIANHAI_MEMBER_MAX,
            ButterflyResult = SceneId =:= data_butterfly:get_sceneid() andalso _Any >= data_butterfly:get_member_num(),
            LoverunResult = SceneId =:= data_loverun:get_loverun_config(scene_id) andalso _Any >= 2,
           	FishResult = SceneId =:= data_fish:get_sceneid() andalso _Any >= data_fish:get_member_num(),
			MemberCondition = 
				if
				    %% 判断是否在南天门内，队伍人数最多为3人
					WubianhaiResult -> true;
					%% 判断是否在蝴蝶谷内，队伍人数最多为3人
					ButterflyResult -> true;
                    %% 判断是否在爱情长跑内，队伍人数最多为2人
                    LoverunResult -> true;
					%% 判断是否在钓鱼内，队伍人数最多为3人
					FishResult -> true;
					true -> false
				end,

            case MemberCondition of
                false -> 
                    case lists:keyfind(Id, 2, State#team.member) of
                        false ->
                            case State#team.join_type =:= 2 of
                                true -> 
                                    %1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
                                    gen_server:cast(Pid, {'set_team', self(), 2, State#team.leaderid}),
                                    %2.增加组队成员.
                                    [Use | Free] = State#team.free_location,
                                    NewMemberList = State#team.member ++ [#mb{id = Id, pid = Pid, 
                                            nickname = Nickname, 
                                            location = Use, 
                                            lv = Lv, career = Career}],							
                                    NewState = State#team{member = NewMemberList, free_location = Free},
                                    %3.对其他队员进行队伍信息广播.
                                    lib_team:send_team_info(NewState),
                                    %4.发送系统通知.
                                    Msg = data_team_text:get_team_msg(1),
                                    {ok, BinData5} = pt_110:write(11004, lists:concat([Nickname, Msg])),
                                    lib_team:send_team(State, BinData5),
                                    %{ok, BinData6} = pt_24:write(24004, 1),
                                    %lib_send:send_one(LeaderSocket, BinData6),
                                    %5.发送加入成功.
                                    {ok, BinData2} = pt_240:write(24002, [1, State#team.leaderid]),
                                    lib_server_send:send_to_uid(Id, BinData2),
                                    %6.调整组队打怪经验.
                                    NewState1 = lib_team:extand_exp(Id, NewState),
                                    %7.设置组队表.
                                    lib_team:set_ets_team(NewState1, self()),
                                    %8.副本招募完队员进入副本倒计时.
                                    lib_team:dungeon_enlist2_full(NewState1),							

                                    %9.大闹天宫修改队伍PK模式.
                                    WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
                                    case SceneId of
                                        WubianhaiSceneId ->										
                                            lib_player:change_pk_status_cast(Id,4),
                                            %% 南天门内添加三职业Buff
                                            %% 队伍人数、是否为三职业在函数内有判断
                                            lib_wubianhai_new:add_wubianhai_buff(NewState1);
                                        _ ->
                                            skip
                                    end,

                                    {noreply, NewState1};
                                false ->
                                    %%向队长发送进队申请
                                    Data = [Id, Lv, Career, Realm, Nickname],
                                    {ok, BinData} = pt_240:write(24003, Data),
                                    lib_server_send:send_to_uid(State#team.leaderid, BinData),
                                    lib_chat:rpc_send_sys_msg_one(Id, data_team_text:get_team_msg(2)),
                                    {noreply, State}
                            end;
                        _ -> 
                            {ok, BinData} = pt_240:write(24002, 2),
                            lib_server_send:send_to_uid(Id, BinData),
                            {noreply, State}
                    end;
                true -> 
                    case LoverunResult of
                        true ->
                            %%加入组队失败，爱情长跑组队上限为2人
                            {ok, BinData} = pt_240:write(24002, 12);
                        false ->
                            %%加入组队失败，南天门组队上限为3人
                            {ok, BinData} = pt_240:write(24002, 10)
                    end,
                    lib_server_send:send_to_uid(Id, BinData),
                    {noreply, State}
            end
    end;
    %    false -> %% 该队伍在副本窗口中创建，你无法加入该队伍
    %        {ok, BinData} = pt_24:write(24002, 9),
    %        lib_send:send_to_uid(Id, BinData),
    %        {noreply, State}
    %end;

%% 队长回应加入队伍申请
handle_cast({'join_team_response', Res, Uid, LeaderId}, State) ->
    case LeaderId =:= State#team.leaderid of
        false ->
            %%不是队长，无权操作
            {ok, BinData1} = pt_240:write(24004, 3),
            lib_server_send:send_to_uid(LeaderId, BinData1),
            {noreply, State};
        true ->%%检查是否在副本中
            %     case is_pid(State#team.dungeon_pid) of
            %       false ->
            case Res of
                0 -> %%拒绝申请
                    {ok, BinData2} = pt_240:write(24002, 0),
                    lib_server_send:send_to_uid(Uid, BinData2),
                    {noreply, State};
                1 -> %%检查申请进队的人是否还在线
                    case lib_player:get_player_info(Uid) of
                        PlayerStatus when is_record(PlayerStatus, player_status) -> %%队伍是否满人
                            case length(State#team.member) of
                                ?TEAM_MEMBER_MAX ->
                                    {ok, BinData4} = pt_240:write(24002, 2),
                                    lib_server_send:send_to_uid(Uid, BinData4),
                                    {noreply, State};
                                _Any ->
									WubianHaiResult = PlayerStatus#player_status.scene =:= data_wubianhai_new:get_wubianhai_config(scene_id) andalso _Any >= ?WUBIANHAI_MEMBER_MAX,
									ButterflyResult = PlayerStatus#player_status.scene =:= data_butterfly:get_sceneid() andalso _Any >= data_butterfly:get_member_num(),
                                    LoverunResult = PlayerStatus#player_status.scene =:= data_loverun:get_loverun_config(scene_id) andalso _Any >= 2,
									FishResult = PlayerStatus#player_status.scene =:= data_fish:get_sceneid() andalso _Any >= data_fish:get_member_num(),
									MemberCondition = 
										if
											%% 判断是否在南天门内，队伍人数最多为3人
											WubianHaiResult -> true;
											%% 判断是否在蝴蝶谷内，队伍人数最多为3人
                                            ButterflyResult -> true;
                                            %% 判断是否在爱情长跑内，队伍人数最多为2人
                                            LoverunResult -> true;
											%% 判断是否在钓鱼内，队伍人数最多为3人
                                            FishResult -> true;
											true -> false
										end,

                                    case MemberCondition of
                                        false -> 
                                            if %%申请人是否加入其他队伍了
                                                is_pid(PlayerStatus#player_status.pid_team) =:= false ->										
                                                    %1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
                                                    gen_server:cast(PlayerStatus#player_status.pid, {'set_team', self(), 2, 
                                                            State#team.leaderid}),
                                                    %2.删除组队招募公告
                                                    lib_team:delete_proclaim(Uid),
                                                    %3.增加组队成员.
                                                    [Use | Free] = State#team.free_location,
                                                    NewMemberList = State#team.member ++ [#mb{id = Uid, 
                                                            pid = PlayerStatus#player_status.pid, 
                                                            nickname = PlayerStatus#player_status.nickname, 
                                                            location = Use, lv = PlayerStatus#player_status.lv, 
                                                            career = PlayerStatus#player_status.career}],
                                                    NewState = State#team{member = NewMemberList, free_location = Free},
                                                    %4.对其他队员进行队伍信息广播.
                                                    lib_team:send_team_info(NewState),
                                                    %5.发送系统通知.
                                                    {ok, BinData5} = pt_110:write(11004, 
                                                        lists:concat([PlayerStatus#player_status.nickname, 
                                                                data_team_text:get_team_msg(1)])),
                                                    lib_team:send_team(State, BinData5),
                                                    %6.发送成功加入队伍给队长.
                                                    {ok, BinData6} = pt_240:write(24004, 1),
                                                    lib_server_send:send_to_uid(LeaderId, BinData6),
                                                    %7.发送成功加入队伍给队员.
                                                    {ok, BinData7} = pt_240:write(24002, [1, LeaderId]),
                                                    lib_server_send:send_to_uid(Uid, BinData7),
                                                    %8.调整组队打怪经验.
                                                    NewState1 = lib_team:extand_exp(Uid, NewState),
                                                    %9.设置组队表.
                                                    lib_team:set_ets_team(NewState1, self()),
                                                    %10.副本招募完队员进入副本倒计时.
                                                    lib_team:dungeon_enlist2_full(NewState1), 

                                                    %11.大闹天宫修改队伍PK模式.
                                                    WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
                                                    case PlayerStatus#player_status.scene of
                                                        WubianhaiSceneId ->										
                                                            lib_player:change_pk_status_cast(Uid,4),
                                                            %% 南天门内添加三职业Buff
                                                            %% 队伍人数、是否为三职业在函数内有判断
                                                            lib_wubianhai_new:add_wubianhai_buff(NewState1);
                                                        _ ->
                                                            skip
                                                    end,

                                                    {noreply, NewState1};
                                                true -> 
                                                    {ok, BinData8} = pt_240:write(24002, 2),
                                                    lib_server_send:send_to_uid(LeaderId, BinData8),
                                                    {noreply, State}
                                            end;
                                        true -> 
                                            {ok, BinData8} = pt_240:write(24002, 2),
                                            lib_server_send:send_to_uid(LeaderId, BinData8),
                                            {noreply, State}
                                    end                     
                            end;
				       _Other ->
			                {ok, BinData3} = pt_240:write(24004, 0),
			                lib_server_send:send_to_uid(LeaderId, BinData3),
			                {noreply, State}					
                    end
                    % true -> {noeply, State}
                    %end
            end
    end;

%% 退出队伍
handle_cast({'quit_team', Uid, Type, Scene}, State) ->
    case lists:keyfind(Uid, 2, State#team.member) of
		%1.不在队伍成员列表..
        false ->			
            {ok, BinData1} = pt_240:write(24005, 0),
            lib_server_send:send_to_uid(Uid, BinData1),
            {noreply, State};
		%2.检查是否能退出队伍.
        Mb -> 
           % CanQuit =  case Type of
           %             offline -> true;
           %             [] -> 
           %                 case is_pid(State#team.dungeon_pid) of
           %                      true -> false;
           %                      false -> true
           %                 end
           %     end,
           %     case CanQuit of
           %         true ->
            case length(State#team.member) of
				%1.队伍没人.
                0 -> 
                    {ok, BinData2} = pt_240:write(24005, 0),
                    lib_server_send:send_to_uid(Uid, BinData2),
                    {noreply, State};
				%2.只有一个人的队伍就解散队伍.
                1 ->
					%1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
                    catch gen_server:cast(Mb#mb.pid, {'set_team', 0, 0, 0}),
					%2.删除组队招募公告
                    lib_team:delete_proclaim(Uid), 
					%3.删除副本招募公告
                    %lib_team:delete_dungeon_proclaim(Uid), 
                    lib_team:delete_enlist2(Uid),					
                    case Type of
                        offline -> ok;
                        _ -> 
                            lib_team:quit_team_quit_dungeon(State#team.dungeon_pid, State#team.leaderid)
                    end,
                    %gen_server:cast(self(), 'disband'),
                    {ok, BinData3} = pt_240:write(24005, 1),
                    lib_server_send:send_to_uid(Uid, BinData3),
                    {stop, normal, State};
				%2.检查是否是队长退队.
                _Any -> 
                    %是否在南天门内
                    WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
                    case Scene of
                        WubianhaiSceneId ->		
                            %% 删除南天门Buff，如玩家本身没有该Buff，会跳过
                            lib_wubianhai_new:del_wubianhai_buff(State);
                        _ -> skip
                    end,
                    %是否在爱情长跑活动场景中
                    LoverunSceneId = data_loverun:get_loverun_config(scene_id),
                    case Scene of
                        LoverunSceneId ->		
                            %% 中断长跑
                            lib_player:update_player_info(Uid, [{stop_loverun, no}]);
                        _ -> skip
                    end,
                    case Mb#mb.pid =:= State#team.leaderpid of
						%1.队长离开队伍.
                        true ->
							%% 删除组队招募公告
                            lib_team:delete_proclaim(Uid),
							%% 删除副本招募公告
                            lib_team:delete_enlist2(Uid), 
							%% 退队去除附加经验
                            State1 = lib_team:clean_extand_exp(Uid, State), 
                            %%通知队员队伍队长退出了
                            %% 重新设置空闲位置
                            Free = lists:sort([Mb#mb.location | State1#team.free_location]),
                            NewMb = lists:keydelete(Uid, 2, State1#team.member),
                            [H|_T] = NewMb,
                            NewState = State1#team{leaderid = H#mb.id, leaderpid = H#mb.pid, 
												   teamname = H#mb.nickname ++ data_team_text:get_team_msg(3), 
												   member = NewMb, free_location = Free},
                            {ok, BinData} = pt_240:write(24011, State#team.leaderid),
                            lib_team:send_team(NewState, BinData),						
							%1.旧队长：更新玩家进程和场景进程的数据，并告诉附近的玩家.
				            gen_server:cast(Mb#mb.pid, {'set_team', 0, 0, 0}),				
							%2.新队长：更新玩家进程和场景进程的数据，并告诉附近的玩家.
				            gen_server:cast(H#mb.pid, {'set_team', self(), 1, NewState#team.leaderid}),					
                            lib_team:send_team_info(NewState),
                            %%暂时离开队伍处理
                            case Type of
                                offline ->
                                    lib_team:quit_team_offline(Mb#mb.id, Mb#mb.nickname, 
															   self(), NewState, Scene, 
															   State#team.dungeon_pid);
                                _ -> 
                                    lib_team:quit_team_quit_dungeon(State#team.dungeon_pid, State#team.leaderid)
                            end,
                            {ok, BinData4} = pt_240:write(24005, 1),
                            lib_server_send:send_to_uid(Uid, BinData4),
                            lib_team:change_enlist2(Uid, H#mb.id, H#mb.nickname),
                            lib_team:set_ets_team(NewState, self()),
                            {noreply, NewState};
						%2.队员离开队伍.
                        false ->                            
							%1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
				            catch gen_server:cast(Mb#mb.pid, {'set_team', 0, 0, 0}),							
							%2.退队去除附加经验
                            State1 = lib_team:clean_extand_exp(Uid, State),
							%3.重新设置空闲位置
                            Free = lists:sort([Mb#mb.location | State1#team.free_location]),
                            NewMb = lists:keydelete(Uid, 2, State1#team.member),
                            NewState = State1#team{member = NewMb, free_location = Free},                            
                            {ok, BinData} = pt_240:write(24011, Mb#mb.id),
                            lib_team:send_team(NewState, BinData),                      
                            %%暂时离开队伍处理
                            case Type of
                                offline ->
                                    lib_team:quit_team_offline(Mb#mb.id, Mb#mb.nickname, self(), 
															   NewState, Scene, State#team.dungeon_pid);
                                _ -> 
                                    lib_team:quit_team_quit_dungeon(State#team.dungeon_pid, Uid)
                            end,
                            {ok, BinData5} = pt_240:write(24005, 1),
                            lib_server_send:send_to_uid(Uid, BinData5),
                            lib_team:set_ets_team(NewState, self()),
                            {noreply, NewState}
                    end
            end
            %        false -> {reply, 2, State}
            %    end
    end;

%% 邀请加入组队
handle_cast({'invite_request', Uid, LeaderId, LeaderName, LeaderLv, LeaderGBid, LeaderGid}, State) ->
    %case State#team.create_type /= 3 of
    %    true -> 
    case LeaderId =:= State#team.leaderid orelse State#team.is_allow_mem_invite == 1 of
		%1.你不是队长.
        false -> 
            {ok, BinData1} = pt_240:write(24006, 4),
            lib_server_send:send_to_uid(LeaderId, BinData1),
            {noreply, State};
        true -> 
            case length(State#team.member) >= ?TEAM_MEMBER_MAX of
                true ->
                    {ok, BinData2} = pt_240:write(24006, 3),
                    lib_server_send:send_to_uid(LeaderId, BinData2),
                    {noreply, State};
				%2.检查被邀请人是否在线.
                false ->
                    case lib_player:get_player_info(Uid) of
                        PlayerStatus when is_record(PlayerStatus, player_status)->
							%1.是否在帮派战中
                            case LeaderGBid =:= 0 orelse 
									 LeaderGid =:=  PlayerStatus#player_status.guild#status_guild.guild_id of
								%1.检查被邀请人是否加入了其他队伍
                                true -> 
                                    case is_pid(PlayerStatus#player_status.pid_team) of
                                        true ->
                                            {ok, BinData4} = pt_240:write(24006, 2),
                                            lib_server_send:send_to_uid(LeaderId, BinData4),
                                            {noreply, State};
										%2.被邀请人是否在队伍中
                                        false ->        
                                            case lists:keyfind(Uid, 2, State#team.member) of
                                                false ->
													WubianhaiResult = PlayerStatus#player_status.scene =:= data_wubianhai_new:get_wubianhai_config(scene_id) andalso 
														length(State#team.member) >= ?WUBIANHAI_MEMBER_MAX,
													ButterflyResult = PlayerStatus#player_status.scene =:= data_butterfly:get_sceneid() andalso 
														length(State#team.member) >= data_butterfly:get_member_num(),
                                                    LoverunResult = PlayerStatus#player_status.scene =:= data_loverun:get_loverun_config(scene_id) andalso length(State#team.member) >= 2,
													FishResult = PlayerStatus#player_status.scene =:= data_fish:get_sceneid() andalso 
														length(State#team.member) >= data_fish:get_member_num(),
													MemberCondition = 
														if
															%% 判断是否在南天门内，南天门内队伍人数最多为3人
															WubianhaiResult -> true;
															%% 判断是否在蝴蝶谷内，队伍人数最多为3人
                                                            ButterflyResult -> true;
                                                            %% 判断是否在爱情长跑内，队伍人数最多为2人
                                                            LoverunResult -> true;
															%% 判断是否在钓鱼内，队伍人数最多为3人
                                                            FishResult -> true;
															true ->
																false
														end,
                                                        case MemberCondition of
                                                            false -> 
                                                                {ok, BinData5} = pt_240:write(24007,
                                                                    [LeaderId, LeaderName, State#team.teamname, 
                                                                        State#team.distribution_type, LeaderLv]),
                                                                lib_server_send:send_to_uid(Uid, BinData5),
                                                                {ok, BinData6} = pt_240:write(24006, 1),
                                                                lib_server_send:send_to_uid(LeaderId, BinData6),
                                                                %发送系统公告.
                                                                %lib_chat:rpc_send_sys_msg_one(LeaderId, data_team_text:get_team_msg(5)),
                                                                {noreply, State};
                                                            true ->
                                                                %%加入组队失败，南天门组队上限为3人
                                                                case WubianhaiResult of
                                                                    true ->
                                                                        {ok, BinData6} = pt_240:write(24006, 10),
                                                                        lib_server_send:send_to_uid(LeaderId, BinData6);
                                                                    false ->
                                                                        %%加入组队失败，爱情长跑组队上限为2人
                                                                        case LoverunResult of
                                                                            true ->
                                                                                {ok, BinData6} = pt_240:write(24006, 13),
                                                                                lib_server_send:send_to_uid(LeaderId, BinData6);
                                                                            false ->
                                                                                {ok, BinData6} = pt_240:write(24006, 3),
                                                                                lib_server_send:send_to_uid(LeaderId, BinData6)
                                                                        end
                                                                end,
                                                                {noreply, State}
                                                        end;
                                                _ ->
                                                    {noreply, State}
                                            end     
                                    end;
                                false -> 
                                    {ok, BinData4} = pt_240:write(24006, 9),
                                    lib_server_send:send_to_uid(LeaderId, BinData4),
                                    {noreply, State}
                             end;
                        _Other ->
                            {ok, BinData3} = pt_240:write(24006, 5),
                            lib_server_send:send_to_uid(LeaderId, BinData3),
                            {noreply, State}					
                    end
            end
    end;
    %    false -> 
    %        {ok, BinData} = pt_24:write(24006, 10),
    %        lib_send:send_one(LeaderSocket, BinData),
    %        {noreply, State}
    %end;

%% 被邀请人回应加入队伍请求
handle_cast({'invite_response', Uid, Pid, Nick, Lv, Career, SceneId}, State) ->
    case lists:keyfind(Uid, 2, State#team.member) of
        false ->
            case length(State#team.member) < ?TEAM_MEMBER_MAX of
                true ->
					WubianhaiResult = SceneId =:= data_wubianhai_new:get_wubianhai_config(scene_id) andalso 
						length(State#team.member) >= ?WUBIANHAI_MEMBER_MAX,
					ButterflyResult = SceneId =:= data_butterfly:get_sceneid() andalso 
						length(State#team.member) >= data_butterfly:get_member_num(),
                    LoverunResult = SceneId =:= data_loverun:get_loverun_config(scene_id) andalso 
                        length(State#team.member) >= 2,
					FishResult = SceneId =:= data_fish:get_sceneid() andalso 
						length(State#team.member) >= data_fish:get_member_num(),
					MemberCondition = 
						if
							%% 判断是否在南天门内，南天门内队伍人数最多为3人
							WubianhaiResult -> true;
							%% 判断是否在蝴蝶谷内，队伍人数最多为3人
							ButterflyResult -> true;
                            %% 判断是否在爱情长跑内，队伍人数最多为2人
                            LoverunResult -> true;
							%% 判断是否在钓鱼内，队伍人数最多为3人
							FishResult -> true;
							true -> false
						end,
                    case MemberCondition of
                        false -> 
                            %1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
                            catch gen_server:cast(Pid, {'set_team', self(), 2, State#team.leaderid}),					
                            %2.删除组队招募公告.
                            lib_team:delete_proclaim(Uid),
                            %3.增加组队成员.
                            [Use | Free] = State#team.free_location,
                            MB = State#team.member ++ [#mb{id = Uid, pid = Pid, nickname = Nick, 
                                    location = Use, lv = Lv, career = Career}],
                            NewState = State#team{member = MB, free_location = Free},
                            %4.对其他队员进行队伍信息广播.
                            lib_team:send_team_info(NewState),
                            %5.发送系统通知.
                            {ok, BinData1} = pt_110:write(11004, lists:concat([Nick, data_team_text:get_team_msg(1)])),
                            lib_team:send_team(State, BinData1),
                            %6.发送同意入队.
                            {ok, BinData2} = pt_240:write(24008, [1, NewState#team.leaderid]),
                            lib_server_send:send_to_uid(Uid, BinData2),
                            %7.调整组队打怪经验.
                            NewState1 = lib_team:extand_exp(Uid, NewState),
                            %8.设置组队表.
                            lib_team:set_ets_team(NewState1, self()),

                            %9.大闹天宫修改队伍PK模式.
                            WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
                            case SceneId of
                                WubianhaiSceneId ->										
                                    lib_player:change_pk_status_cast(Uid,4),
                                    %% 南天门内添加三职业Buff
                                    %% 队伍人数、是否为三职业在函数内有判断
                                    lib_wubianhai_new:add_wubianhai_buff(NewState1);
                                _ ->
                                    skip
                            end,

                            {noreply, NewState1};
                        true -> 
                            {ok, BinData3} = pt_240:write(24008, 0),
                            lib_server_send:send_to_uid(Uid, BinData3),
                            {noreply, State}
                    end;    
                false ->
                    {ok, BinData3} = pt_240:write(24008, 0),
                    lib_server_send:send_to_uid(Uid, BinData3),
                    {noreply, State}
            end;		
        _ -> 
			{noreply, State}
    end;

%%踢出队伍
handle_cast({'kick_out', Uid, LeaderId}, State) ->
    {Result, RNewState} = case LeaderId =:= State#team.leaderid of
        false -> %%你不是队长
            {2, State};
        true -> 
          %  case is_pid(State#team.dungeon_pid) of
          %      false ->
            case lists:keyfind(Uid, 2, State#team.member) of
                false -> {0, State};
                Mb ->
					%1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
				    catch gen_server:cast(Mb#mb.pid, {'set_team', 0, 0, 0}),	
                    Free = lists:sort([Mb#mb.location | State#team.free_location]),
                    NewMb = lists:keydelete(Uid, 2, State#team.member),
                    NewState = State#team{member = NewMb, free_location = Free},					
                    {ok, BinData1} = pt_240:write(24011, Mb#mb.id),
                    lib_team:send_team(State, BinData1),
                    NewState2 = lib_team:clean_extand_exp(Uid, NewState), %% 退队去除附加经验
                    case lib_player:get_player_info(Uid) of
                        PlayerStatus when is_record(PlayerStatus, player_status)->
                            %是否在南天门内
                            WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
                            case PlayerStatus#player_status.scene of
                                WubianhaiSceneId ->		
                                    %% 删除南天门Buff，如玩家本身没有该Buff，会跳过
                                    lib_wubianhai_new:del_wubianhai_buff(State);
                                _ -> skip
                            end,
                            %是否在爱情长跑活动场景中
                            LoverunSceneId = data_loverun:get_loverun_config(scene_id),
                            case PlayerStatus#player_status.scene of
                                LoverunSceneId ->		
                                    %% 中断长跑
                                    mod_loverun:logout(PlayerStatus);
                                _ -> skip
                            end,
	                        {ok, BinData2} = pt_110:write(11004, lists:concat([PlayerStatus#player_status.nickname, data_team_text:get_team_msg(6)])),
	                        lib_team:send_team(NewState, BinData2),
	                        %% 如果在副本中，退出副本
	                        lib_team:quit_team_quit_dungeon(State#team.dungeon_pid, Uid);
                        _Other -> 
							[]				
                    end,
                    lib_team:set_ets_team(NewState2, self()),
                    {1, NewState2}
            end
           % true -> {4, State}
        %end
    end,
    {ok, BinData3} = pt_240:write(24009, Result),
    lib_server_send:send_to_uid(LeaderId, BinData3),
    {noreply, RNewState};

%% 委任队长
handle_cast({'change_leader', Uid, LeaderId}, State) ->
    {R, RNewState} = case LeaderId =:= State#team.leaderid of
        false -> %%非队长无法委任队长
            {0, State};
        true ->
            case lists:keyfind(Uid, 2, State#team.member) of
                false -> 
                    {0, State};
                Mb -> 
				    %1.删除组队招募公告.
                    lib_team:delete_proclaim(State#team.leaderid),
				    %2.删除副本招募公告.
                    lib_team:delete_enlist2(State#team.leaderid), 
                    NewState = State#team{leaderid = Mb#mb.id, leaderpid = Mb#mb.pid, 
					  					  teamname = Mb#mb.nickname ++ data_team_text:get_team_msg(3)},
                    %3.通知所有队员
                    lib_team:send_team_info(NewState),	
					%4.旧队长：更新玩家进程和场景进程的数据，并告诉附近的玩家.
				    catch gen_server:cast(State#team.leaderpid, {'set_team', self(), 2, NewState#team.leaderid}),	
				   	%5.新队长：更新玩家进程和场景进程的数据，并告诉附近的玩家.
				    catch gen_server:cast(Mb#mb.pid, {'set_team', self(), 1, NewState#team.leaderid}),			
                    lib_team:change_enlist2(State#team.leaderid, Mb#mb.id, Mb#mb.nickname),
                    {1, NewState}
           end
   end,
   {ok, BinData} = pt_240:write(24013, R),
   lib_server_send:send_to_uid(LeaderId, BinData),
   {noreply, RNewState};

%% 解散队伍
handle_cast('disband', State) ->
    {ok, BinData} = pt_240:write(24017, []),
    F = fun(Member) ->
			%1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
			catch gen_server:cast(Member#mb.pid, {'set_team', 0, 0, 0}),
			%2.通知队员解散队伍了.
            lib_server_send:send_to_uid(Member#mb.id, BinData)
        end,
    [F(M)||M <- State#team.member],
    {stop, normal, State};

%% 查看队伍信息
handle_cast({'send_team_info', Id}, State) ->
    case lib_player:is_online_global(State#team.leaderid) of
        false -> ok;
        true ->
            MemberInfoList = lib_team:pack_member(State#team.member),
            Data = [1, State#team.leaderid, State#team.teamname, MemberInfoList],
            {ok, BinData} = pt_240:write(24016, Data),
            lib_server_send:send_to_uid(Id, BinData)
    end,
    {noreply, State};

%% 更新所有队员信息.
handle_cast('update_team_info', State) ->
	lib_team:send_team_info(State),
    {noreply, State};

%% 登录马上归队
handle_cast({'login_back_to_team', Uid, Pid, Nick, Lv, Career}, State) ->
    case lists:keyfind(Uid, 2, State#team.member) of
        false -> 
            %case catch gen_server:cast(Pid, {'SET_TEAM_PID', self()}) of
            %    ok ->
                    [Use | Free] = State#team.free_location,
                    NewMemberList = State#team.member ++ [#mb{id = Uid, pid = Pid, nickname = Nick, location = Use, lv = Lv, career = Career}],
                    NewState = State#team{member = NewMemberList, free_location = Free},
                    NewState2 = lib_team:extand_exp(Uid ,NewState),
                    %send_team_info(NewState2),
                    %{ok, BinData1} = pt_11:write(11004, lists:concat([Nick, " 归队了"])),
                    %send_team(State, BinData1),
                    %lib_team:send_leaderid_area_scene(Uid, 2),
                    lib_team:set_ets_team(NewState2, self()),
                    {noreply, NewState2};
            %    _ -> {noreply, State}
            %end;
        _ -> {noreply, State}
    end;

%% 上线归队
handle_cast({'back_to_team', Uid, Pid, Nick, _DungeonScene, _Lv, _Career}, State) ->
        %case length(State#team.member) of
        %    ?TEAM_MEMBER_MAX -> 
        %        {ok, BinData} = pt_11:write(11004, "你离线前所属的队伍人数已满"),
        %        lib_send:send_to_uid(Uid, BinData),
        %        {noreply, State};
        %    _ -> 
        %        case lists:keyfind(Uid, 2, State#team.member) of
        %            false -> 
        %                case catch gen_server:cast(Pid, {'SET_TEAM_PID', self()}) of
        %                    ok ->
        %                        [Use | Free] = State#team.free_location,
        %                        NewMemberList = State#team.member ++ [#mb{id = Uid, pid = Pid, nickname = Nick, location = Use, lv = Lv}],
                                %% 更新队伍状态,设为队员
%%     case State#team.leaderid =:= Uid of
%%         true ->
%%             lib_team:send_leaderid_area_scene(Uid, 1);
%%         false -> 
%%             lib_team:send_leaderid_area_scene(Uid, 2)
%%     end,
        %                        NewState = State#team{member = NewMemberList, free_location = Free},
                                %% 离线归队副本处理
                                %case is_pid(State#team.dungeon_pid) andalso is_process_alive(State#team.dungeon_pid) of
                                %    true ->
                                %        case DungeonScene of
                                %            0 -> ok;
                                %            _ -> 
                                %                case lib_scene:is_dungeon_scene(DungeonScene) of
                                %                    true ->
                                %                        catch gen_server:call(Pid, {set_dungeon, State#team.dungeon_pid}),
                                %                        catch gen_server:call(State#team.dungeon_pid, {join, Uid}),
                                %                        {ok, BinData} = pt_24:write(24031, DungeonScene),
                                %                        lib_send:send_to_uid(Uid, BinData);
                                %                   false -> ok
                                %                end
                                %        end;
                                %    false -> ok
                                %end,
%%     M = State#team.member,
%%     NewM = lists:keydelete(Uid, 2, M),
%%     lib_team:send_team_info(State),
%%     {ok, BinData1} = pt_110:write(11004, lists:concat([Nick, data_team_text:get_team_msg(7)])),
%%     lib_team:send_team(State#team{member = NewM}, BinData1),
%%     {ok, BinData2} = pt_110:write(11004, data_team_text:get_team_msg(8)),
%%     lib_chat:rpc_send_msg_one(Uid, BinData2),
    %NewState = lib_team:extand_exp(Uid ,State),

	%2.增加组队成员.
%%    [Use | Free] = State#team.free_location,
%%    MB = State#team.member ++ [#mb{id = Uid, pid = Pid, nickname = Nick, 
%%								   location = Use, lv = Lv, career = Career}],
%%    NewState = State#team{member = MB, free_location = Free},
    case lists:keyfind(Uid, 2, State#team.member) of
        false -> 
            {ok, BinData} = pt_110:write(11004, data_team_text:get_team_msg(13)),
			lib_server_send:send_to_uid(Uid, BinData),
            {noreply, State};
        _ -> 		
			%3.更新玩家进程和场景进程的数据，并告诉附近的玩家.
		    case State#team.leaderid =:= Uid of
		        true ->						
					catch gen_server:cast(Pid, {'set_team', self(), 1, State#team.leaderid});	
		        false -> 
					catch gen_server:cast(Pid, {'set_team', self(), 2, State#team.leaderid})
		    end,	
		    %4.对其他队员进行队伍信息广播.
		    lib_team:send_team_info(State),
			%5.发送通知：归队了.
		    {ok, BinData1} = pt_110:write(11004, lists:concat([Nick, data_team_text:get_team_msg(7)])),
		    lib_team:send_team(State, BinData1),
			%6.发送通知：你成功进入离线前的队伍.
			{ok, BinData2} = pt_110:write(11004, data_team_text:get_team_msg(8)),
			lib_chat:rpc_send_msg_one(Uid, BinData2),
			%7.调整组队打怪经验.
		    NewState1 = lib_team:extand_exp(Uid, State),
			%8.设置组队表.
		    lib_team:set_ets_team(NewState1, self()),	
		    {noreply, NewState1}
	end;
                    %        _ -> {noreply, State}
                    %    end;
                    %_ -> {noreply, State}
                %end
        %end;

%% 设置队员等级.
handle_cast({'set_member_level', PlayerId, PlayerLevel}, State) ->
	case lists:keyfind(PlayerId, 2, State#team.member) of
		false -> 
			{noreply, State};
		TeamPlay ->
			%1.删除原来是数据.
			NewMemberList = lists:keydelete(PlayerId, 2, State#team.member),			
			NewMemberList2 = NewMemberList ++ [TeamPlay#mb{lv = PlayerLevel}],			
            NewState1 = State#team{member = NewMemberList2},
			%2.对其他队员进行队伍信息广播.
			lib_team:send_team_info(NewState1),			
			%3.调整组队打怪经验.
            NewState2 = lib_team:extand_exp(PlayerId, NewState1),
			{noreply, NewState2}
    end;
    
%% 队伍聊天
handle_cast({'TEAM_MSG', Id, Nick, Realm, Sex, Bin, GM,Vip, Career}, State) ->
    {ok, BinData} = pt_110:write(11006, [Id, Nick, Realm, Sex, Bin, GM,Vip, Career]),
    lib_team:send_team(State, BinData),
    {noreply, State}.

%% -------------------------------- 自定义消息 ---------------------------------

%% 玩家进程死了
handle_info({'DEAD', Uid, Scene}, State) ->
    case lists:keyfind(Uid, 2, State#team.member) of
        false -> 
            {noreply, State};
        Mb ->
            lib_team:delete_proclaim(Uid),
            lib_team:delete_enlist2(Uid), %% 删除副本招募公告
            State1 = lib_team:clean_extand_exp(Uid, State), %% 退队去除附加经验
            case length(State#team.member) of
                0 -> 
					{noreply, State1};
				%1.只有一个人的队伍就解散队伍
                1 ->
					%1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
					catch gen_server:cast(Mb#mb.pid, {'set_team', 0, 0, 0}),		
                    %quit_team_quit_dungeon(State#team.dungeon_pid, State#team.leaderid),
                    %gen_server:cast(self(), 'disband'),
                    {stop, normal, State1};
				%2.检查是否是队长退队
                _Any -> 
                    %是否在南天门内
                    WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
                    case Scene of
                        WubianhaiSceneId ->		
                            %% 删除南天门Buff，如玩家本身没有该Buff，会跳过
                            lib_wubianhai_new:del_wubianhai_buff(State);
                        _ -> skip
                    end,
                    %是否在爱情长跑活动场景中
                    LoverunSceneId = data_loverun:get_loverun_config(scene_id),
                    case Scene of
                        LoverunSceneId ->		
                            %% 中断长跑
                            lib_player:update_player_info(Uid, [{stop_loverun, no}]);
                        _ -> skip
                    end,
                    case Mb#mb.pid =:= State#team.leaderpid of
						%1.通知队员队伍队长退出了
                        true ->                           
                            %% 重新设置空闲位置
                            Free = lists:sort([Mb#mb.location | State1#team.free_location]),
                            NewMb = lists:keydelete(Uid, 2, State1#team.member),
                            [H|_T] = NewMb,
                            NewState = State1#team{leaderid = H#mb.id, leaderpid = H#mb.pid, 
												   teamname = H#mb.nickname ++ "的队伍", 
												   member = NewMb, free_location = Free},
                            {ok, BinData} = pt_240:write(24011, State#team.leaderid),
                            lib_team:send_team(NewState, BinData),							
							%2.旧队长：更新玩家进程和场景进程的数据，并告诉附近的玩家.
							catch gen_server:cast(Mb#mb.pid, {'set_team', 0, 0, 0}),
							%3.新队长：更新玩家进程和场景进程的数据，并告诉附近的玩家.
							catch gen_server:cast(H#mb.pid, {'set_team', self(), 1, NewState#team.leaderid}),							
                            lib_team:send_team_info(NewState),
                            %quit_team_quit_dungeon(State#team.dungeon_pid, State#team.leaderid),
                            %%暂时离开队伍处理
                            lib_team:quit_team_offline(Mb#mb.id, Mb#mb.nickname, self(), NewState, Scene, State#team.dungeon_pid),
                            lib_team:change_enlist2(Uid, H#mb.id, H#mb.nickname),
                            lib_team:set_ets_team(NewState, self()),
                            {noreply, NewState};
						%2.非队长退出
                        false ->                            
							%1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
							catch gen_server:cast(Mb#mb.pid, {'set_team', 0, 0, 0}),
                            %2.重新设置空闲位置
                            Free = lists:sort([Mb#mb.location | State1#team.free_location]),
                            NewMb = lists:keydelete(Uid, 2, State1#team.member),
                            NewState = State1#team{member = NewMb, free_location = Free},
                            {ok, BinData} = pt_240:write(24011, Mb#mb.id),
                            lib_team:send_team(NewState, BinData),
                            %quit_team_quit_dungeon(State#team.dungeon_pid, Mb#mb.id),
                            %%暂时离开队伍处理
                            lib_team:quit_team_offline(Mb#mb.id, Mb#mb.nickname, self(), NewState, Scene, State#team.dungeon_pid),
                            lib_team:set_ets_team(NewState, self()),
                            {noreply, NewState}
                    end
            end
    end.
