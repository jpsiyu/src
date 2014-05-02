%%------------------------------------------------------------------------------
%% @Module  : mod_team_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.18
%% @Description: 组队副本功能
%%------------------------------------------------------------------------------

-module(mod_team_dungeon).
-export([handle_call/3, handle_cast/2, handle_info/2]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("team.hrl").
-include("tower.hrl").
-include("dungeon.hrl").

%% --------------------------------- 同步消息 ----------------------------------

%% 获取副本pid
handle_call('get_dungeon_pid', _From, State) ->
    {reply, State#team.dungeon_pid, State};

%% 创建队伍的副本服务
handle_call({create_dungeon, From, DunId, DunName, Level, RoleInfo}, _From, State) ->
    case is_pid(State#team.dungeon_pid) andalso misc:is_process_alive(State#team.dungeon_pid) of
		%1.副本已经存在.
        true -> 
            [_SceneId, PlayerId, _DailyPid, PlayerPid, DungeonDataPid, PlayerCopyId, _Scene, _X, _Y] = RoleInfo,
			%1.非队长的队员加入副本.
            case State#team.leaderid =/= PlayerId of
                true ->
                    %case catch gen:call(State#team.dungeon_pid, '$gen_call', {check_enter, DunId, Id, 0}) of
                    %    {ok, {true, _}} -> 
                    %        lib_dungeon:join(State#team.dungeon_pid, Id, Pid),
                    %        {reply, State#team.dungeon_pid, State};
                    %    {ok, {false, _}} -> {reply, mb_in_other_dungeon, State};
                    %    {'EXIT', _} -> {reply, ok, State}
                    %end;
                    case DunId =:= State#team.dungeon_scene of
                        true -> 
                            lib_dungeon:join(State#team.dungeon_pid, 
											 PlayerId, 
											 PlayerPid, 
											 DungeonDataPid, 
											 PlayerCopyId),
                            {reply, {State#team.dungeon_pid, noleader}, State};
                        false -> 
                            {reply, {0, not_the_same_dungeon}, State}
                    end;
                false ->
                    {reply, {0, mb_in_other_dungeon}, State}
            end;
		%2.队长创建副本.
        false ->
            [SceneId, PlayerId, DailyPid, PlayerPid, DungeonDataPid, _PlayerCopyId, Scene, X, Y] = RoleInfo,
            case PlayerId =:= State#team.leaderid of %% 判断是否队长
                true ->
					%1.删除副本招募.
                    lib_team:delete_enlist2(State#team.leaderid), 
                    lib_team:change_state(State, 1),
%%                     _Lv = if 
%%                             DunId =:= 630 ->
%%                                 lib_team:get_avg_level(State);
%%                             DunId =:= 650 ->
%%                                 lib_team:get_max_level(State);
%%                             DunId =:= 233 -> 
%%                                 lib_team:get_avg_level(State);
%%                             true->
%%                                 0
%%                         end,
%%                    Lv = 0,
					%1.剧情副本玩家大于等于40级杀死BOSS不加一.
					Dun = data_dungeon:get(DunId),
					case Dun#dungeon.type of
						?DUNGEON_TYPE_STORY -> skip;
%% 							case Level >= 40 of
%% 								true ->
									%设置冷却时间.
									%mod_dungeon_data:set_cooling_time(DungeonDataPid, 
									%								  PlayerId, 
									%								  DunId);
%% 								false ->
%% 									mod_daily:increment(DailyPid, PlayerId, DunId)
%% 							end;
						_ ->
					 		mod_daily:increment(DailyPid, PlayerId, DunId)
					end,
					%2.创建副本.
                    DPid = mod_dungeon:start(self(), From, DunId, [{PlayerId, PlayerPid, DungeonDataPid}], Level, 
						       Scene, X, Y),
                    %3.定义通知其它队员加入副本函数.
                    Fun = 
						fun(Id0) ->
                            case lib_player:get_player_info(Id0) of
                                []->
                                    ok;
                                PlayerStatus -> %% 必须与队长同一个场景才能收到进入副本的通知
                                    case PlayerStatus#player_status.scene =:= Scene of
                                        true ->
                                            {ok, BinData} = pt_240:write(24030, [SceneId, DunName]),
                                            lib_server_send:send_to_uid(PlayerStatus#player_status.id, BinData);
                                        false -> ok
                                    end
                            end
                        end,
					%4.宝岛副本不通知队友.
                    case DunId =:= 985 of 
                        true -> ok;
                        false ->
                            [Fun(Mb#mb.id) || Mb <- State#team.member, Mb#mb.id =/= PlayerId]
                    end,
                    {reply, {DPid, isleader}, State#team{dungeon_pid = DPid, dungeon_scene = DunId, create_type = 1}};
                false ->
                    {reply, {0, none}, State}
            end
    end;

%% 检查进入副本的体力值是否满足条件.
handle_call({'check_dungeon_physical', _PhysicalId, _PlayerId, _PlayerPhysical}, _From, State) ->
	
%% 	%1.定义检查体力值的函数.
%%     FunCheckPhysical = 
%% 		fun(Member) ->
%% 			MemberId = Member#mb.id,			
%% 			if 
%% 				%1.检测自己的等级.
%% 				MemberId == PlayerId ->
%% 					lib_physical:is_enough_physical(PlayerPhysical, PhysicalId);		
%% 							
%% 				%2.检测别人的等级.
%% 				true -> %%三个人组队有问题，所以进入副本只检测自己体力值是否足够.
%% 					case lib_player:get_player_info(MemberId, team) of
%% 		                false -> [];
%% 		                {ok, _PlayerId, _PlayerTid, _TeamPid, _Level, Physical, _Scene, _CopyId, _X, _Y} ->
%% 							lib_physical:is_enough_physical(Physical, PhysicalId)
%% 					end
%% 			 end
%% 		end,
%% 	
%% 	%2.检查所有成员的体力值.
%%     Res = lists:all(FunCheckPhysical, State#team.member),
	Res = true,
    {reply, Res, State}.

%% --------------------------------- 异步消息 ----------------------------------

%% 设置dungeon_pid
handle_cast({'set_dungeon_pid', DungeonPid}, State) ->
    case is_pid(DungeonPid) of
        true -> {noreply, State#team{dungeon_pid = DungeonPid}};
        false -> 
            lib_team:change_state(State, 0),
            {noreply, State#team{dungeon_pid = DungeonPid, dungeon_scene = 0}}
    end;

%% 队伍仲裁启动
handle_cast({'arbitrate_req', Uid, Nick, Msg, Type, Args}, State) ->
    case is_pid(State#team.dungeon_pid) andalso misc:is_process_alive(State#team.dungeon_pid) andalso Type =:= 1 of
        true ->
            {ok, BinData} = pt_120:write(12005, [0, 0, 0, data_team_text:get_team_msg(9), 0]),
            lib_server_send:send_to_uid(State#team.leaderid, BinData),
            {noreply, State};
        false ->
            case Uid =:= State#team.leaderid of
                true -> 
                    [Num, _, _, _, _, _] = State#team.arbitrate,
                    case length(State#team.member) of
                        0 -> {noreply, State};
                        1 -> 
                            self() ! {'arbitrate_result', Num + 1}, 
                            {noreply, State#team{arbitrate = [Num + 1, Type, 1, 0, [Uid], Args]}};
                        _ ->
                            NewState = State#team{arbitrate = [Num + 1, Type, 0, 0, [], Args]},
                            {ok, BinData} = pt_240:write(24037, [Num + 1, Nick, Msg]),
                            lib_team:send_team(State, BinData),
                            erlang:send_after(10 * 1000, self(), {'arbitrate_result', Num + 1}),
                            {noreply, NewState}
                    end;
                false -> {noreply, State}
            end
    end;

%% 队员回应仲裁
handle_cast({'arbitrate_res', Uid, Res, RecordId}, State) ->
    [Num, Type, True, False, ArMb, Args] = State#team.arbitrate,
    case lists:member(Uid, ArMb) of
        false ->
            case RecordId =:= Num of
                true ->
                    MbNum = length(State#team.member),
                    [NewTrue, NewFalse] = case Res of 
                        1 -> [True + 1, False];
                        0 -> [True, False + 1];
                        _ -> [True, False] 
                    end,
                    case NewTrue + NewFalse >= MbNum of
                        true -> self() ! {'arbitrate_result', Num};
                        false -> ok
                    end,
                    {ok, BinData} = pt_240:write(24039, [Num, Uid, Res]),
                    lib_team:send_team(State, BinData),
                    case Res of
                        1 -> 
                            {noreply, State#team{arbitrate = [Num, Type, NewTrue, NewFalse, [Uid | ArMb], Args]}};
                        0 -> 
                            lib_team:send_team(State, pt:pack(24040, <<>>)),
                            {noreply, State#team{arbitrate = [Num, 0, 0, 0, [], 0]}}
                    end;
                false -> 
                    {ok, BinData} = pt_240:write(24038, 0),
                    lib_server_send:send_to_uid(Uid, BinData),
                    {noreply, State}
            end;
        true -> 
            {ok, BinData} = pt_240:write(24038, 1),
            lib_server_send:send_to_uid(Uid, BinData),
            {noreply, State}
    end;

%% 赞成传送到副本区(8.29)
handle_cast({'goto_dungeon_area', Uid}, State) -> 
    case lists:member(Uid, State#team.goto_dungeon) of
        true -> {noreply, State};
        false -> 
            NewGotoDungeonList = [Uid|State#team.goto_dungeon],
            case length(NewGotoDungeonList) >= length(State#team.member) of
                true -> 
                    SceneName = case lib_scene:get_data(State#team.create_sid) of
                        S when is_record(S, ets_scene) -> S#ets_scene.name;
                        _ -> <<>>
                    end,
                    {ok, BinData} = pt_240:write(24052, [State#team.create_sid, SceneName, 1]),
                    lib_server_send:send_to_uid(State#team.leaderid, BinData),
                    {noreply, State#team{goto_dungeon = []}};
                false -> {noreply, State#team{goto_dungeon = NewGotoDungeonList}}
            end
    end;
    
%% 创建锁妖塔副本
handle_cast({'create_tower', {TowerSceneId, Ratio}}, State) ->
    ExReward = case lib_team:is_three_career(State) of
        true -> 1.2;
        false -> 1
    end,
    Now = util:unixtime(),

	case lib_player:get_player_info(State#team.leaderid, dailypid) of
		false -> ok;
		DailyPid ->
			mod_daily:increment(DailyPid, State#team.leaderid, TowerSceneId)			
	end,
	
	lib_team:delete_enlist2(State#team.leaderid),
    DungeonPid = mod_dungeon:start_tower(self(), 0, TowerSceneId,
								    [{State#team.leaderid, 
									  State#team.leaderpid, 
									  State#team.leader_dungeon_data_pid}], 
								   	  0, 
								    [[{TowerSceneId, Now}], [], Now, [], ExReward, Ratio]),
    TowerInfo = data_tower:get(TowerSceneId),
    case catch gen_server:call(DungeonPid, {check_enter, TowerSceneId, State#team.leaderid, 0}) of
        {'EXIT', _} ->
			{noreply, State};
        {false, _Msg} ->
			{noreply, State};
        {true, _SceneId} -> 
            %% 计时开始
            %BinData = pt:pack(28007, <<>>),
            %lib_send:send_to_uid(State#team.leaderid, BinData),			
            [Mb#mb.pid ! {'enter_tower', [TowerInfo#tower.time, TowerSceneId, Ratio]} || Mb <- State#team.member],
			
			%2.装备副本修改组队模式.
            case lib_player:get_player_info(State#team.leaderid, pk) of
                StatusPK when is_record(StatusPK, status_pk) ->
					PKType = StatusPK#status_pk.pk_status,
                    case PKType of
						0 -> skip;
						4 -> skip;
						_ ->
                            lib_player:change_pk_status_cast(State#team.leaderid, 4)
                    end;
				_Other ->
					skip
			end,

            %3.增加夫妻副本任务次数
            case Ratio > 0 of
                true -> lib_marriage_other:add_dun_num([[Mb#mb.id || Mb <- State#team.member], 2]);
                false -> lib_marriage_other:add_dun_num([[Mb#mb.id || Mb <- State#team.member], 1])
            end,
            

%%             %1.扣除队长进入副本次数.
%%             mod_daily:increment(State#team.leaderid, TowerSceneId),
%%             
%%             %2.扣除队长的体力值.
%%             case lib_player:get_player_info(State#team.leaderid, physical) of
%% 				false ->
%%                     skip;
%%                 Physical ->
%%                     lib_physical:cost_physical(playerid, 
%% 												{State#team.leaderid, 
%% 												 Physical, 
%% 												 103})
%%             end,                    
            {noreply, State#team{dungeon_pid = DungeonPid, dungeon_scene = TowerSceneId}}
    end;
    
%% 创建多人副本.
handle_cast({'create_multi_dungeon', {DungeonId}}, State) ->
	%1.增加进入副本次数.
	case lib_player:get_player_info(State#team.leaderid, dailypid) of
		false -> ok;
		DailyPid ->
			mod_daily:increment(DailyPid, State#team.leaderid, DungeonId)			
	end,

	%2.删除招募列表.
	lib_team:delete_enlist2(State#team.leaderid),

    AvgLv = lib_team:get_avg_level(State), 

	%3.创建副本.
    DungeonPid = mod_dungeon:start_multi_dungeon(self(), 0, DungeonId,
								    [{State#team.leaderid, 
									  State#team.leaderpid, 
									  State#team.leader_dungeon_data_pid}], 
								   	  AvgLv),

    %4.检测队长是否可以进副本.
    case catch gen_server:call(DungeonPid, {check_enter, DungeonId, State#team.leaderid, 0}) of
        {'EXIT', _} ->
			{noreply, State};
        {false, _Msg} ->
			{noreply, State};

        {true, _SceneId} ->
			%1.把全部人传进副本.
            [Mb#mb.pid ! {'enter_multi_dungeon', [DungeonId]} || Mb <- State#team.member],
			
			%2.修改组队模式.
            case lib_player:get_player_info(State#team.leaderid, pk) of
                StatusPK when is_record(StatusPK, status_pk) ->
					PKType = StatusPK#status_pk.pk_status,
                    case PKType of
						0 -> skip;
						4 -> skip;
						_ ->
                            lib_player:change_pk_status_cast(State#team.leaderid, 4)
                    end;
				_Other ->
					skip
			end,                
            {noreply, State#team{dungeon_pid = DungeonPid, dungeon_scene = DungeonId}}
    end.

%% -------------------------------- 自定义消息 ---------------------------------

%% 仲裁结果处理
handle_info({'arbitrate_result', N}, State) ->    
    [Num, Type, True, False, _, Args] = State#team.arbitrate,
    case N =:= Num of
        true -> 
            case True + False >= length(State#team.member) of
                true -> 
                    case Type of
                        1 -> %% 创建普通锁妖塔
                            if 
                                False =:= 0 -> gen_server:cast(self(), {'create_tower', Args});
                                true -> ok
                            end;
                        2 -> %% 创建跳层锁妖塔
                            if 
                                False =:= 0 -> gen_server:cast(self(), {create_tower_by_level, Args});
                                true -> ok
                            end;
                        3 -> %% 创建多人副本.
                            if 
                                False =:= 0 -> gen_server:cast(self(), {'create_multi_dungeon', Args});
                                true -> ok
                            end;
%%                         3 -> %% 报名3vs3跨服战
%%                             if 
%%                                 False =:= 0 ->
%%                                     %%!mod_kfz_3v3:apply_battle_sucess(Args);
%%                                     skip;
%%                                 true -> ok
%%                             end;
                        _ -> ok %% TODO 其他类型暂时用不上
                    end;
                false -> ok 
            end;
        false -> ok
    end,
    lib_team:send_team(State, pt:pack(24040, <<>>)),
    {noreply, State#team{arbitrate = [Num, 0, 0, 0, [], 0]}}.
