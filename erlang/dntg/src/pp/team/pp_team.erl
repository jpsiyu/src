%%%--------------------------------------
%%% @Module  : pp_team
%%% @Author  : zhenghehe
%%% @Created : 2010.07.06
%%% @Description:  组队功能管理
%%%--------------------------------------
-module(pp_team).
-export([handle/3]).
%% -include("record.hrl").
-include("common.hrl").
-include("server.hrl").
-include("team.hrl").
-include("dungeon.hrl").
-include("scene.hrl").

%%创建队伍
handle(24000, Status, [Type, Sid, TeamName, AutoEnter, Distribution, IsAllowMemInvite]) ->
	IsChangeSceneSign = Status#player_status.change_scene_sign,
	if		
		%1.创建组队失败，正在排队进入场景中.					
		IsChangeSceneSign=/=0 ->
            {ok, BinData} = pt_240:write(24000, [6, [], Type]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData);
		
		%2.非换线中.
		true->	
		    case is_pid(Status#player_status.pid_team) of
		        false -> 
		            case lists:member(AutoEnter, [1,2]) andalso lists:member(Distribution, [0,1,2]) of
		                    true ->
		                        case mod_team:start(Status#player_status.id, 
													Status#player_status.pid,
													Status#player_status.pid_dungeon_data, 
		                        					Status#player_status.nickname, 
													TeamName, Status#player_status.lv, 
		                        					Status#player_status.career, AutoEnter, 
													Distribution, Type, Sid, IsAllowMemInvite) of                  
		                            {ok, PidTeam} ->
		                            	%1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
										catch gen_server:cast(Status#player_status.pid, {'set_team', PidTeam, 1, 
																						 Status#player_status.id}),
										%2.更新公共线的队伍ID.
		    							lib_player:update_unite_info(Status#player_status.unite_pid,[{team_id, Status#player_status.id}]),
		                                {ok, BinData} = pt_240:write(24000, [1, TeamName, Type]),
		                                lib_server_send:send_to_sid(Status#player_status.sid, BinData),
		%%                                 case Type of
		%%                                     2 -> 
		%%                                         mod_disperse:rpc_cast_by_id(?UNITE, ets, insert, [?ETS_DUNGEON_ENLIST, #ets_dungeon_enlist{id = Status#player_status.id, sid = Sid, nickname = Status#player_status.nickname}]),
		%%                                         handle(24043, Status, Sid);
		%%                                     _ -> ok
		%%                                 end,
		                                %% 加入方式
		                                {ok, BinData1} = pt_240:write(24034, AutoEnter),
		                                lib_server_send:send_to_sid(Status#player_status.sid, BinData1),
		                                {ok, BinData2} = pt_240:write(24018, [1, Distribution]),
		                                lib_server_send:send_to_sid(Status#player_status.sid, BinData2),
		                                NewStatus = Status#player_status{pid_team = PidTeam, leader = 1},
		
										%大闹天宫修改队伍PK模式.
										WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
										case Status#player_status.scene of
											WubianhaiSceneId ->			
												lib_player:change_pkstatus(Status, 4);
										 	_ ->
												skip
										end,
		
		                                {ok, NewStatus};
		                            _Any ->
		                                {ok, BinData} = pt_240:write(24000, [0, [], Type]),
		                                lib_server_send:send_to_sid(Status#player_status.sid, BinData)
		                        end;
		                    false -> ok
		                end;
		        true ->
		            {ok, BinData} = pt_240:write(24000, [2, [], Type]),
		            lib_server_send:send_to_sid(Status#player_status.sid, BinData)
		    end
	end;

%% 加入队伍
handle(24002, Status, [Uid, JoinType]) ->
	IsChangeSceneSign = Status#player_status.change_scene_sign,	
	if 
		%1.不可以加入自己的队伍.
		Status#player_status.id == Uid ->
		    {ok, BinData} = pt_240:write(24002, 9),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
	   
		%2.加入组队失败，正在排队进入场景中.					
		IsChangeSceneSign=/=0 ->
		    {ok, BinData} = pt_240:write(24002, 11),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
	   
	   true ->
		    _Gs = Status#player_status.guild,
		    case is_pid(Status#player_status.pid_team) of
		        false ->
		           % case is_pid(Status#player_status.copy_id) of
		           %      false ->
		            case lib_player:get_player_info(Uid) of
		                PlayerStatus when is_record(PlayerStatus, player_status)->
		%%                     %% 是否在帮派战中 _marked_by_wuzhenhua _status_guild已经没有帮战相关信息
		%%                     case Gs#status_guild.guild_id =:= PlayerStatus#player_status.guild_id of
		%%                     case Gs#status_guild.guild_battle_flag =:= 0 orelse 
		%%                     	 Gs#status_guild.guild_id =:= Record#ets_online.guild_id of						
		%%                         true ->
		                            %%队伍是否存在
		                            case is_pid(PlayerStatus#player_status.pid_team) andalso 
											 misc:is_process_alive(PlayerStatus#player_status.pid_team) of
		                                true -> 
		                                    gen_server:cast(PlayerStatus#player_status.pid_team, 
															{'join_team_request', 
															 Status#player_status.id, 
															 Status#player_status.lv, 
															 Status#player_status.career, 
															 Status#player_status.realm, 
															 Status#player_status.nickname, 
															 Status#player_status.pid,
															 Status#player_status.scene, JoinType});
		                                false ->
		                                    {ok, BinData} = pt_240:write(24002, 3),
		                                    lib_server_send:send_to_sid(Status#player_status.sid, BinData)
		                            end;
		%%                         false -> 
		%%                             {ok, BinData} = pt_240:write(24002, 8),
		%%                             lib_server_send:send_to_sid(Status#player_status.sid, BinData)
		%%                      end;
		                _ -> 
		                    %% 玩家不在线
		                    {ok, BinData} = pt_240:write(24002, 7),
		                    lib_server_send:send_to_sid(Status#player_status.sid, BinData)
		            end;
		             %   true -> 
		             %       {ok, BinData} = pt_24:write(24002, 6),
		             %       lib_send:send_one(Status#player_status.socket, BinData)
		            %end;
		        true -> 
		            {ok, BinData} = pt_240:write(24002, 4),
		            lib_server_send:send_to_sid(Status#player_status.sid, BinData)
		    end
	end;

%% 队长回应加入队伍请求
handle(24004, Status, [Res, Uid]) ->
	IsChangeSceneSign = Status#player_status.change_scene_sign,	
	if		
		%1.正在排队进入场景中，无法加入新成员.					
		IsChangeSceneSign=/=0 ->
            {ok, BinData} = pt_240:write(24004, 7),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData);
		
		true ->	
			case is_pid(Status#player_status.pid_team) of
			    true ->
			        gen_server:cast(Status#player_status.pid_team, 
									{'join_team_response', Res, Uid, Status#player_status.id}); 
				false -> %%你没有队伍
			        {ok, BinData} = pt_240:write(24004, 4),
			        lib_server_send:send_to_sid(Status#player_status.sid, BinData)
			end
	end;

%% 离开队伍 
handle(24005, Status, Type) ->
    case is_pid(Status#player_status.pid_team) of
        true ->
            case misc:is_process_alive(Status#player_status.pid_team) of
				%1.组队进程死了，也让他退队伍
                false ->  
                	%1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
					catch gen_server:cast(Status#player_status.pid, {'set_team', 0, 0, 0}),
                    lib_dungeon:quit(Status#player_status.copy_id, Status#player_status.id, 6),
                    lib_dungeon:clear(role, Status#player_status.copy_id),
                    {ok, BinData} = pt_240:write(24005, 1),
                    lib_server_send:send_to_uid(Status#player_status.id, BinData);
				%2.组队进程没死，让组队进程自己去处理.
                true -> 
                    gen_server:cast(Status#player_status.pid_team, 
									{'quit_team', 
									 Status#player_status.id, 
									 Type, 
									 Status#player_status.scene})       
            end;
        false -> 
			ok
    end;

%% 邀请别人加入队伍
handle(24006, Status, Uid) ->
	IsChangeSceneSign = Status#player_status.change_scene_sign,	
	if 
		%1.不可以邀请自己加入队伍.
		Status#player_status.id == Uid ->
			{ok, BinData} = pt_240:write(24006, 11),
	        lib_server_send:send_to_sid(Status#player_status.sid, BinData);
		
		%2.邀请组队失败，正在排队进入场景中.					
		IsChangeSceneSign=/=0 ->
            {ok, BinData} = pt_240:write(24006, 12),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData);
		
	   true ->
			Gs = Status#player_status.guild,
			PlayerTeamPid = Status#player_status.pid_team,
			case lib_player:get_player_info(Uid, team) of
				%2.被邀请人在线.
				{ok, _PlayerId, _PlayerTid, Player2TeamPid, _Level, _Physical, _Scene, _CopyId, _X, _Y} ->
			        case  is_pid(Player2TeamPid) of
						%1.创建组队后邀请玩家.
			            false ->
							%1.创建组队.
			                TeamPid = 
								case is_pid(PlayerTeamPid) of
			                        true -> 
										PlayerTeamPid;
			                        false -> 
			                            TeamName1 = Status#player_status.nickname ++ data_team_text:get_team_msg(3),
			                            case mod_team:start(Status#player_status.id,													 
															Status#player_status.pid,
															Status#player_status.pid_dungeon_data, 
															Status#player_status.nickname, TeamName1, 
															Status#player_status.lv, 
															Status#player_status.career, 
															2, 1, 1, 0, 1) of
											%1.创建组队成功.
			                                {ok, NewTeamPid} ->
			            						%1.更新玩家进程和场景进程的数据，并告诉附近的玩家.
												catch gen_server:cast(Status#player_status.pid, {'set_team', NewTeamPid, 1, 
																								 Status#player_status.id}),
												%2.发送创建队伍成功.
			                                    {ok, BinData0} = pt_240:write(24000, [1, TeamName1, 1]),
			                                    lib_server_send:send_to_uid(Status#player_status.id, BinData0),
			                                    
												%大闹天宫修改队伍PK模式.
												WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
												case Status#player_status.scene of
													WubianhaiSceneId ->			
														lib_player:change_pkstatus(Status, 4);
										 			_ ->
														skip
												end,
											                                    
			                                    NewTeamPid;
											%2.创建组队失败.
			                                _Any ->
			                                    {ok, BinData} = pt_240:write(24000, [0, [], 1]),
			                                    lib_server_send:send_to_uid(Status#player_status.id, BinData),
			                                    0
			                            end
			                	end,
							%2.邀请玩家入队.
			                case is_pid(TeamPid) of
			                    true ->
			                        gen_server:cast(TeamPid, {'invite_request', Uid, Status#player_status.id, 
															  Status#player_status.nickname, 
															  Status#player_status.lv, 
															  0, 
															  Gs#status_guild.guild_id});
			                    false -> 
									ok
			                end;
						%2.被邀请人已经加入其他队伍.
			            true -> 
			                {ok, BinData2} = pt_240:write(24006, 2),
			                lib_server_send:send_to_uid(Status#player_status.id, BinData2)
			        end;
				%1.被邀请人已经下线.
			    _ -> 
			        {ok, BinData3} = pt_240:write(24006, 5),
			        lib_server_send:send_to_sid(Status#player_status.sid, BinData3)			
			end
	end;

%% 被邀请人回应邀请请求
handle(24008, Status, [LeaderId, Res]) ->
  %  case is_pid(Status#player_status.copy_id) of
  %      false ->
            case Res of
                0 -> %%被邀请人拒绝了
                    {ok, BinData} = pt_110:write(11004, Status#player_status.nickname ++ data_team_text:get_team_msg(10)),
                    lib_chat:rpc_send_msg_one(LeaderId, BinData),
                    ok;
                1 -> %%被邀请人同意了，检查队长还在线不
                    case lib_player:get_player_info(LeaderId, team) of
                        %%检查队伍还存在不
                        {ok, _PlayerId, _PlayerTid, TeamPid, _Level, _Physical, _Scene, _CopyId, _X, _Y} ->
                            case is_pid(TeamPid) of
                                true ->
                                    case is_pid(Status#player_status.pid_team) of
                                        false -> %%邀请人没有加入队伍
                                            gen_server:cast(TeamPid, {'invite_response',
																	  Status#player_status.id, 
																	  Status#player_status.pid, 
																	  Status#player_status.nickname, 
																	  Status#player_status.lv, 
																	  Status#player_status.career,
																	  Status#player_status.scene});
                                        true -> ok %%邀请人已经加入队伍了
                                    end;
                                false -> 
                                    %%队伍已经不存在了
                                    {ok, BinData} = pt_240:write(24008, 2),
                                    lib_server_send:send_to_uid(Status#player_status.id, BinData)
                            end;
						%%队长不在线
                        _ -> 
							ok                            
                        end
                end;
       %     true -> 
       %         {ok, BinData} = pt_24:write(24008, 4),
       %         lib_send:send_one(Status#player_status.socket, BinData)
       % end;

%% 踢出队伍
handle(24009, Status, Uid) ->
    case Status#player_status.id =:= Uid of
        false ->
            case is_pid(Status#player_status.pid_team) of
                true ->
                    gen_server:cast(Status#player_status.pid_team, {'kick_out', Uid, Status#player_status.id});
                false -> ok
            end;
        true ->
            %% 不能踢自己
            {ok, BinData} = pt_240:write(24009, 3), 
            lib_server_send:send_to_uid(Status#player_status.id, BinData)
    end;

%% 委任队长
handle(24013, Status, Uid) ->
	LoverunSceneId = data_loverun:get_loverun_config(scene_id),
    case is_pid(Status#player_status.pid_team) andalso
		LoverunSceneId =/= Status#player_status.scene of
        true ->
            gen_server:cast(Status#player_status.pid_team, {'change_leader', Uid, Status#player_status.id});
        false ->
            ok
    end;

%% 获取队伍信息
handle(24016, Status, Uid) ->	
	%1.获取组队进程.
	GetTeamPid = 
		if 
			%1.请求的人是自己.
			Uid == Status#player_status.id ->
				{ok, Status#player_status.pid_team};
			%2.是其他玩家.
			true ->
			    case lib_player:get_player_info(Uid, team) of
					%2.玩家在线.
			        {ok, _PlayerId, _PlayerTid, TeamPid, _Level, _Physical, _Scene, _CopyId, _X, _Y} ->
						{ok, TeamPid};
					%1.玩家不在线.
			        _ -> 
			            {ok, BinData} = pt_240:write(24016, [0, 0, [], []]),
			            lib_server_send:send_to_uid(Status#player_status.id, BinData),
						false
				end
		end,
    %2.发送协议.
    case GetTeamPid of
        false -> 
            skip;
        {ok, TeamPid2} ->
            case is_pid(TeamPid2) of
                true ->
                    catch gen_server:cast(TeamPid2, {'send_team_info', 
													 Status#player_status.id});
                false ->
                    {ok, BinData2} = pt_240:write(24016, [2, 0, [], []]),
                    lib_server_send:send_to_uid(Status#player_status.id, BinData2)
            end
    end;

%% 解散队伍
handle(24017, Status, []) ->
    case is_pid(Status#player_status.pid_team) of
        true -> case Status#player_status.leader == 1 of
                true -> 
                    catch gen_server:cast(Status#player_status.pid_team, 'disband'), 
                    ok;
                false -> skip
            end;
        false -> skip
    end;

%% 设置队伍拾取方式
handle(24018, Status, Num) ->
    Res = case is_pid(Status#player_status.pid_team) andalso lists:member(Num, [0, 1, 2])of
        true ->
            case catch gen:call(Status#player_status.pid_team, '$gen_call', {'set_distribution_type', Num}) of
                {ok, 1} -> 1;
                {ok, 0} -> 0;
                {ok, _} -> 0;
                {'EXIT', _Reason} -> 0
            end;
        false -> 0
    end,
    case Res of
        1 -> ok;
        0 ->
            {ok, BinData} = pt_240:write(24018, [0, 0]),
            lib_server_send:send_to_uid(Status#player_status.id, BinData);
        _ -> 
            {ok, BinData} = pt_240:write(24018, [0, 0]),
            lib_server_send:send_to_uid(Status#player_status.id, BinData)
    end;

%% 获取离线前的组队信息
handle(24032, Status, []) ->	
   %case cache_op:lookup_unite(?ETS_TMB_OFFLINE, Status#player_status.id) of
   case mod_team_agent:get_tmb_offline(Status#player_status.id) of
       [] -> %lib_team:delete_tmb_all_server(Status#player_status.id);
			ok;
       [R] -> 
           Time = util:unixtime(),
           case Time - R#ets_tmb_offline.offtime =< 300 of
               true -> 
                   case is_pid(R#ets_tmb_offline.team_pid) of
                       true ->
						   case misc:is_process_alive(R#ets_tmb_offline.team_pid) of
							   true ->
								   %1.上线归队.
								   catch gen_server:cast(R#ets_tmb_offline.team_pid, 
														 {'back_to_team', 
														  Status#player_status.id, 
														  Status#player_status.pid, 
														  Status#player_status.nickname, 
														  R#ets_tmb_offline.dungeon_scene, 
														  Status#player_status.lv, 
														  Status#player_status.career});
							   false ->
								   skip
						   end;
                       false -> 
                           {ok, BinData} = pt_110:write(11004, data_team_text:get_team_msg(11)),
                           lib_chat:rpc_send_msg_one(Status#player_status.id, BinData) 
                   end;
               false -> 
                   {ok, BinData} = pt_110:write(11004, data_team_text:get_team_msg(12)),
                   lib_chat:rpc_send_msg_one(Status#player_status.id, BinData)
           end,
           lib_team:delete_tmb(Status#player_status.id)
   end;

%% 获得周围队伍状态
handle(24033, Status, LeaderIdList) ->
    Fun = fun(Id) ->
            case Id /= Status#player_status.id of
                true ->
                    case lib_player:get_player_info(Id, team) of
						{ok, _PlayerId, _PlayerTid, TeamPid, _Level, _Physical, _Scene, _CopyId, _X, _Y} ->
                            case is_pid(TeamPid) andalso 
								misc:is_process_alive(TeamPid) of
                                true ->
                                    %case lib_team:get_mb_num_join_type(TeamPid) of
                                    %    error -> [];
                                    %    {Num, JoinType} when is_integer(Num) andalso is_integer(JoinType) -> [{Id, Num, JoinType}];
                                    %    _ -> []
                                    %end;
                                    case catch mod_disperse:call_to_unite(ets, lookup, [?ETS_TEAM, TeamPid]) of
                                        [ET] when is_record(ET, ets_team)->
                                            [{Id, ET#ets_team.mb_num, ET#ets_team.join_type}];										
                                        _Other ->
                                            []
                                    end;
                                false -> []
                            end;
						_ ->
							[]
                    end;
                false ->
                    []
            end
        end,
    Result = lists:flatmap(Fun, LeaderIdList),
    {ok, BinData} = pt_240:write(24033, Result),
    lib_server_send:send_to_uid(Status#player_status.id, BinData);

%% 设置队员加入方式
handle(24034, Status, JoinType) ->
   Res = case is_pid(Status#player_status.pid_team) andalso lists:member(JoinType, [1, 2]) of
        true ->
            case catch gen:call(Status#player_status.pid_team, '$gen_call', {'set_join_type', JoinType}) of
                {ok, 1} -> 1;
                {ok, 0} -> 0;
                {ok, _} -> 0;
                {'EXIT', _Reason} -> 0
            end;
        false -> 0
    end,
    case Res of
        1 -> ok;
        0 ->
            {ok, BinData} = pt_240:write(24034, 0),
            lib_server_send:send_to_uid(Status#player_status.id, BinData);
        _ -> 
            {ok, BinData} = pt_240:write(24034, 0),
            lib_server_send:send_to_uid(Status#player_status.id, BinData)
    end; 

%% 队员投票
handle(24038, Status, [RecordId, Res]) ->
    case is_pid(Status#player_status.pid_team) of
        true ->
            gen_server:cast(Status#player_status.pid_team, {'arbitrate_res', Status#player_status.id, Res, RecordId});
        false -> ok %% 这里是异常情况
    end;

%% 赞成传送到副本区(8.29)
handle(24053, Status, []) -> 
    case is_pid(Status#player_status.pid_team) of
        true -> 
            catch gen_server:cast(Status#player_status.pid_team, {'goto_dungeon_area', Status#player_status.id});
        false -> skip
    end;

%% 获取队伍是否进入副本
handle(24045, Status, []) ->
    Sid = case is_pid(Status#player_status.pid_team) of
        true -> 
            case gen:call(Status#player_status.pid_team, '$gen_call', get_dungeon) of
                {'EXIT', _} -> 0;
                {ok, DungeonPid} when is_pid(DungeonPid) -> 
                    case gen:call(DungeonPid, '$gen_call', 'get_begin_sid') of
                        {'EXIT', _} -> 0;
                        {ok, SceneId} when is_integer(SceneId) -> SceneId;
                        _ -> 0
                    end;
                _ -> 0
            end;
        false -> 0
    end,
    {ok, BinData} = pt_240:write(24045, Sid),
    lib_server_send:send_to_uid(Status#player_status.id, BinData);

%% 设置是否允许队员邀请玩家进入
handle(24064, Status, IsAllowMemInvite) ->
   Res = case is_pid(Status#player_status.pid_team) andalso 
				  lists:member(IsAllowMemInvite, [0, 1]) of
        true ->
            case catch gen:call(Status#player_status.pid_team, '$gen_call', 
								{'set_allow_member_invite', IsAllowMemInvite}) of
                {ok, 1} -> 1;
                {ok, _} -> 2;
                {'EXIT', _Reason} -> 2
            end;
        false -> 0
    end,
    case Res of
        1 -> ok;
        _ -> 
            {ok, BinData} = pt_240:write(24064, 2),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData)
    end;

%% 获取队伍的坐标信息.
handle(24065, Status, []) ->
	%1.查询队伍的坐标信息.
	Result = 
		case is_pid(Status#player_status.pid_team) of
			true ->
				%1.获取其他队员的Id.
				MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),													
				NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
				
				%2.获取其他队员的坐标信息.
			    FunGetLocal = 
					fun(PlayerId) ->
			            case lib_player:get_player_info(PlayerId, team) of
			                {ok, _PlayerId1, _PlayerTid1, _TeamPid1, _Level1, 
							 _Physical1, Scene1, _CopyId1, X1, Y1} ->
								[{PlayerId, Scene1, X1, Y1}];
							_ ->
			                	[]
			            end
					end,
				TeamLocalList = lists:flatmap(FunGetLocal, NewMemberIdList),
				TeamLocalList1 = [{Status#player_status.id, 
						   Status#player_status.scene, 
						   Status#player_status.x, 
						   Status#player_status.y}] ++ TeamLocalList,
				{ok, TeamLocalList1};
	        false -> 
				false
	    end,
	
	%2.发送结果.
	case Result of
        {ok, TeamLocalList3} ->
		    {ok, BinData} = pt_240:write(24065, TeamLocalList3),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
        _ -> 
			skip
    end;

%% 设置九重天双倍掉落.
handle(24066, Status, Code) ->
   Res = case is_pid(Status#player_status.pid_team) andalso 
				  lists:member(Code, [0, 1]) of
        true ->
            case catch gen:call(Status#player_status.pid_team, '$gen_call', 
								{'set_duoble_drop', Code}) of
                {ok, 2} -> 2;
                {ok, _Res} -> 1;
                _ -> 2
            end;
        false -> 2
    end,
    case Res of
        1 -> ok;
        _ -> 
            {ok, BinData} = pt_240:write(24066, Res),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData)
    end;

%% 进入副本投票.
handle(24067, Status, DungeonId) ->
	%1.得到玩家当前场景数据.
	PlayerScene = 
		case lib_scene:get_data(Status#player_status.scene) of
            SceneData when is_record(SceneData, ets_scene) ->
				SceneData;
			_ ->
				#ets_scene{}
		end,

    HS2 = Status#player_status.husong,
    IsChangeSceneSign = Status#player_status.change_scene_sign,
    IsFlyMount = Status#player_status.mount#status_mount.fly_mount,
    EnterTime = lib_dungeon:check_enter_time(DungeonId),

	Res =
    if  PlayerScene#ets_scene.type =:= ?SCENE_TYPE_GUILD orelse
        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_ARENA orelse
        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_BOSS orelse
        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_ACTIVE ->								
            {false, data_scene_text:get_sys_msg(28)};
		
		%1.检测进去副本时间限制.
		EnterTime == false ->
			{false, data_dungeon_text:get_dungeon_text(7)};
		
        %1.护送美女状态.					
        HS2#status_husong.husong=/=0 ->
            {false, data_dungeon_text:get_tower_text(1)};

        %2.换线中.					
        IsChangeSceneSign=/=0 ->
            {false, data_dungeon_text:get_tower_text(35)};

        %3.在飞行坐骑上不能进入把副本.					
        IsFlyMount=/=0 ->
            {false, data_dungeon_text:get_dungeon_text(5)};

        true ->
            case data_dungeon:get(DungeonId) of
                [] -> {false, data_dungeon_text:get_tower_text(2)};
                Dun -> %% 普通场景进入副本 
                    case lib_scene:check_dungeon_requirement(Status, Dun#dungeon.condition) of
                        {false, Reason} -> {false, Reason};
                        {true} ->
                            Count = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, DungeonId),
                            if
                                %% 进入次数已满
                                Count >= Dun#dungeon.count -> 
									{false, data_scene_text:get_sys_msg(21)}; 

                                %% 组队九重天
                                true -> 
                                    case lib_dungeon:check_team_condition(Status, DungeonId) of
                                        {false, Reason1} -> {false, Reason1};
                                        _ ->
                                            %% 队伍是否同意
                                            Text = data_dungeon_text:get_tower_text(2, [Dun#dungeon.name]),
                                            gen_server:cast(Status#player_status.pid_team, 
                                                {'arbitrate_req', 
                                                    Status#player_status.id, 
                                                    Status#player_status.nickname, 
                                                    Text, 3, {DungeonId}})
                                    end
                            end
                    end
            end
    end,
    case Res of
        {false, Msg} ->
            {ok, BinData} = pt_120:write(12005, [0, 0, 0, Msg, 0]),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        _ ->
			ok
    end;

handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_team no match", []),
    {error, "pp_team no match"}.

%%更改队名
%handle(24014, Status, TeamName) ->
%    Res = case validate_team_name(len, TeamName) of
%        {true, ok} -> 
%            case gen_server:call(Status#player_status.pid_team, {'CHANGE_TEAMNAME', TeamName}) of
%                not_leader -> 0;
%                1 -> 1;
%                _ -> 0
%            end;
%        {false, len_error} -> 2;    %%队名长度不符合
%        {false, illegal} -> 3       %%非法字符
%    end,
%     {ok, BinData} = pt_24:write(24014, Res),
%     lib_send:send_one(Status#player_status.socket, BinData);

%% %% 登记副本招募
%% handle(24041, Status, Sid) ->
%%     case is_pid(Status#player_status.pid_team) of
%%         true -> 
%%             mod_disperse:rpc_cast_by_id(?UNITE, ets, insert, [?ETS_DUNGEON_ENLIST, #ets_dungeon_enlist{id = Status#player_status.id, sid = Sid, nickname = Status#player_status.nickname}]),
%%             {ok, BinData} = pt_240:write(24041, 1),
%%             lib_server_send:send_one(Status#player_status.socket, BinData);
%%         false -> ok
%%     end;
%% 
%% %% 注销副本招募
%% handle(24042, Status, []) ->
%%     case Status#player_status.leader =:= 1 of
%%         true ->
%% %%             case ets:match(?ETS_ONLINE, #ets_online{sid = '$1', pid_team = Status#player_status.pid_team, _ = '_'}) of
%% %%                 [] -> ok;
%% %%                 Sids -> 
%% %%                     {ok, Bin} = pt_24:write(24044, []),
%% %%                     [lib_server_send:send_to_sid(Sid, Bin)||[Sid]<-Sids]
%% %%             end,
%%             {ok, Bin} = pt_240:write(24044, []),
%%             lib_team:send_to_member(Status#player_status.pid_team, Bin),
%%             mod_disperse:rpc_cast_by_id(?UNITE, ets, delete, [?ETS_DUNGEON_ENLIST, Status#player_status.id]),
%%             {ok, BinData} = pt_240:write(24042, 1),
%%             lib_server_send:send_one(Status#player_status.socket, BinData);
%%         false -> 
%%             {ok, BinData} = pt_240:write(24042, 0),
%%             lib_server_send:send_one(Status#player_status.socket, BinData)
%%     end;

%% %% 获取副本招募列表
%% handle(24043, Status, Sid) ->
%%     L = mod_disperse:call_to_unite(ets, match_object, [?ETS_DUNGEON_ENLIST, #ets_dungeon_enlist{sid = Sid, _ = '_'}]),
%%     {ok, BinData} = pt_240:write(24043, L),
%%     lib_server_send:send_one(Status#player_status.socket, BinData);

%% % 切线加入队伍
%% handle(24061, Status, [LeaderId, Line]) -> 
%%     case Line == Status#player_status.online_flag of
%%         true -> 
%%             case is_pid(Status#player_status.pid_team) of
%%                 true ->  handle(24005, Status, []); %% 离开队伍
%%                 false -> skip
%%             end,
%%             %% 进入队伍
%%             handle(24002, Status#player_status{pid_team = 0}, [LeaderId, 1]);
%%         false ->
%%             mod_disperse:rpc_cast_by_id(99, lib_team, change_line_into_team, [Status#player_status.id, LeaderId, Line]),
%%             case lib_yunbiao:transport(Status, [Status#player_status.scene, Status#player_status.x, Status#player_status.y, Line]) of
%%                 {ok, NewStatus} -> {ok, NewStatus};
%%                 _ -> 
%%                     mod_disperse:rpc_cast_by_id(99, ets, delete, [?ETS_CHANGE_LINE_INFO_TEAM, Status#player_status.id]),
%%                     ok
%%             end
%%     end;

%%检查队名长度是否合法
%validate_team_name(len, TeamName) ->
%    case asn1rt:utf8_binary_to_list(list_to_binary(TeamName)) of
%        {ok, CharList} ->
%            Len = string_width(CharList),  
%            %% 队名最大长度暂时设为15个中文字 
%            case Len < 31 andalso Len > 1 of
%                true ->
%                    {true, ok};
%                false ->
%                    %%队伍名称长度为1~15个汉字
%                    {false, len_error}
%            end;
%        {error, _Reason} ->
%            %%非法字符
%            {false, illegal}
%    end.

%% 字符宽度，1汉字=2单位长度，1数字字母=1单位长度
%string_width(String) ->
%    string_width(String, 0).
%string_width([], Len) ->
%    Len;
%string_width([H | T], Len) ->
%    case H > 255 of
%        true ->
%            string_width(T, Len + 2);
%        false ->
%            string_width(T, Len + 1)
%    end.
