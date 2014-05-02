%%------------------------------------------------------------------------------
%% @Module  : mod_tower_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.6.5
%% @Description: 爬塔副本服务
%%------------------------------------------------------------------------------

-module(mod_tower_dungeon).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-include("tower.hrl").

-export([
		create_scene/3,                %% 创建副本场景.
        tower_next_level/4,            %% 锁妖塔进入下一层.
        tower_reward/3,                %% 锁妖塔每层结算.
        total_tower_reward/3,          %% 锁妖塔累计结算.
        total_tower_reward_offline/1,  %% 锁妖塔累计结算（下线）.
        kill_npc/3                     %% 杀死塔里面的怪.
]).

-export([ handle_call/3, 
		 handle_cast/2, 
		 handle_info/2]).


%% --------------------------------- 公共函数 ----------------------------------

%% 创建副本场景.
create_scene(SceneId, CopyId, State) ->
    TowerState = State#dungeon_state.tower_state,
	create_mon(SceneId, CopyId, State#dungeon_state.level, TowerState#tower_state.ratio),    
    {SceneId, State}.

%% 每层开始(锁妖塔).
tower_next_level(DungeonPid, Uid, SceneId, NowSceneId) ->
    case is_pid(DungeonPid) of
        true -> DungeonPid ! {'tower_next_level', Uid, SceneId, NowSceneId};
        false -> ok
    end.

%% 每层结算(锁妖塔).
tower_reward(DungeonPid, SceneId, RewardTime) ->
    case is_pid(DungeonPid) of
        true -> 
	        DungeonPid ! {'tower_reward', SceneId, RewardTime};
        false -> 	
			ok
    end.

%% 结算.
total_tower_reward(DungeonPid, Uid, _Type) ->
    case is_pid(DungeonPid) of
        true ->
            DungeonPid ! {'total_tower_reward', Uid};
        false -> ok
    end.

%% 下线结算.
total_tower_reward_offline(Status) ->
    case is_pid(Status#player_status.copy_id) of
        true -> 
            case catch gen:call(Status#player_status.copy_id, '$gen_call', 
								{'total_tower_reward_offline', Status}) of
                {'EXIT', _} -> 0;
                {ok, Res} -> Res;
                _ -> 0
            end;
        false -> 0
    end.


%% --------------------------------- 内部函数 ----------------------------------


%% 锁妖塔累计奖励(下线)(锁妖塔).
handle_call({'total_tower_reward_offline', Status}, _From, State) ->
    TowerState = State#dungeon_state.tower_state,
    case TowerState#tower_state.csid of
        [] -> {reply, 0, State};
        [SceneId | _] -> 
            Uid = Status#player_status.id,
			PlayerId = Status#player_status.lv,
            [Exp, Llpt, _Items, Honour, KingHonour, NewRewarders, ActiveBox] = 
				case lists:keyfind(Uid, 1, TowerState#tower_state.rewarder) of %% 判断是否已经领取过
	                false -> [0, 0, [], 0, 0,[{Uid, SceneId} | TowerState#tower_state.rewarder], 0];
	                {_, RewardSceneId} -> 
	                    TowerInfo = data_tower:get(RewardSceneId),
	                    [TowerInfo#tower.total_exp, 
	                     TowerInfo#tower.total_llpt, 
	                     TowerInfo#tower.total_items,
	                     TowerInfo#tower.total_honour,
	                     TowerInfo#tower.total_king_honour,
	                     lists:keyreplace(Uid, 1, TowerState#tower_state.rewarder, {Uid, SceneId}),
	                     1
	                 ]
	            end,
            TowerInfo2 = data_tower:get(SceneId),
            %% 发放奖励
            case TowerInfo2#tower.total_exp - Exp > 0 of
                true ->
                    SceneInfo = data_dungeon:get(State#dungeon_state.begin_sid),
                    TowerName = binary_to_list(SceneInfo#dungeon.name),


                    %AfterCutItems = TowerInfo2#tower.total_items -- Items,
                    AfterCutHonour = TowerInfo2#tower.total_honour - Honour,
                    AfterCutKingHonour = TowerInfo2#tower.total_king_honour - KingHonour,
                    {AfterExRExp, AfterExRLlpt, ExRewardSign} = case TowerState#tower_state.exreward of
                        1 ->  %% 一般奖励
                            {TowerInfo2#tower.total_exp - Exp, TowerInfo2#tower.total_llpt - Llpt, 0};
                        ExReward -> %% 三种职业提高20%的奖励
                            {round((TowerInfo2#tower.total_exp - Exp)*ExReward), 
							 round((TowerInfo2#tower.total_llpt - Llpt)*ExReward), 1}
                    end,

                    %% 写入数据库
                    Status1 = lib_player:add_pt(llpt, Status, AfterExRLlpt),
                    Status2 = lib_player:add_honour(Status1, AfterCutHonour),
                    Status3 = lib_player:add_king_honour(Status2, AfterCutKingHonour),
                    %% 发送邮件通知
                    RoleInfo = State#dungeon_state.role_list,
					TowerType = 
						case State#dungeon_state.begin_sid of
							300 -> 2; %多人副本.
							340 -> 1; %单人.
							_   -> 3
						end,
                    lib_tower_dungeon:tower_reward_mail(
					  							Uid, 
												PlayerId,
												TowerType,
												TowerName, 
												TowerInfo2#tower.level, 
												AfterExRExp, AfterExRLlpt, 
												AfterCutHonour, AfterCutKingHonour, 
												ExRewardSign, 0, 
                                                State#dungeon_state.active_scene, ActiveBox, 
                                                [RXX1#dungeon_player.id|| RXX1 <- RoleInfo],
												State#dungeon_state.time, 0),
                    %% 远征岛日志
                    log:log_tower(Status#player_status.id, 
                        Status#player_status.nickname,
                        TowerName,
                        TowerInfo2#tower.level,
                        util:unixtime() - State#dungeon_state.time,
                        AfterCutHonour,
                        Status3#player_status.honour,
                        KingHonour,
                        Status3#player_status.chengjiu#status_chengjiu.king_honour
                    ),
                    {reply, AfterExRExp, State#dungeon_state{tower_state = TowerState#tower_state{rewarder = NewRewarders}}};
                false -> 
                    {reply, 0, State#dungeon_state{tower_state = TowerState#tower_state{rewarder = NewRewarders}}}
            end
    end.

%% 获取这一层的奖励(锁妖塔).
handle_cast({'now_level_reward', Uid}, State) ->
	case State#dungeon_state.type of
		?DUNGEON_TYPE_TOWER ->
		    TowerState = State#dungeon_state.tower_state,
		    [{S1, _}|_] = TowerState#tower_state.esid,
		    S3 = case TowerState#tower_state.csid of
		        [] -> [];
		        [S2|_] -> S2
		    end,
		    TowerInfo1 = data_tower:get(S1),
		    TowerInfo2 = data_tower:get(S3),
		    TowerInfo3 = case lists:keyfind(Uid, 1, TowerState#tower_state.rewarder) of
		        false -> #tower{};
		        {_, S4} -> 
		            case lists:member(S4, ?TOWER_END_SCENEID) of
		                true -> #tower{};
		                false -> data_tower:get(S4)
		            end
		    end,
            %% 经验倍数
            Ratio = case TowerState#tower_state.ratio > 0 of
                true -> TowerState#tower_state.ratio;
                false -> 1
            end,
            Exp       = trunc(TowerInfo1#tower.exp*Ratio),
            Llpt      = trunc(TowerInfo1#tower.llpt*Ratio),
            TotalExp  = trunc(TowerInfo2#tower.total_exp*Ratio)-trunc(TowerInfo3#tower.total_exp*Ratio),
            TotalLlpt = trunc(TowerInfo2#tower.total_llpt*Ratio)-trunc(TowerInfo3#tower.total_llpt*Ratio),
		    {ok, BinData} = pt_280:write(28006, [Exp, 
												  Llpt, 
												  TotalExp, 
												  TotalLlpt, 
												  TowerInfo1#tower.level, 
												  TowerInfo1#tower.sid]),
		    lib_server_send:send_to_uid(Uid, BinData);
		_ ->
			skip
	end,
    {noreply, State};

%% 获取新一层的剩余时间(锁妖塔).
handle_cast({'tower_left_time', Uid, _DailyPid}, State) ->
    TowerState = State#dungeon_state.tower_state,
    case TowerState#tower_state.esid of
        [] -> 
			{noreply, State};
        [{SceneId, BTime}|_] -> 
            TowerInfo = data_tower:get(SceneId),
            Count = 0, %mod_daily:get_count(DailyPid, Uid, State#dungeon_state.begin_sid),
            %{LeftTime, Type} = case lists:member(SceneId, TowerState#tower_state.csid) of
            %    true -> {TowerInfo#tower.time + BTime  + TowerState#tower_state.extand_time - TowerState#tower_state.etime, 2};
            LeftTime = TowerInfo#tower.time + BTime + 
					   TowerState#tower_state.extand_time - util:unixtime(),
            {ok, BinData} = case LeftTime > 0 of
                true -> pt_280:write(28002, [LeftTime, 2, Count]);
                false -> pt_280:write(28002, [0, 2, Count])
            end,
            lib_server_send:send_to_uid(Uid, BinData),
            {noreply, State}
    end.

%% 锁妖塔每层开始(锁妖塔).
handle_info({'tower_next_level', Id, SceneId, NowSceneId}, State) ->
    TowerState = State#dungeon_state.tower_state,
    case lists:keyfind(SceneId, 1, TowerState#tower_state.esid) of %% 是否已经进过这场景
        {_, BTime} ->
           case lists:member(SceneId, TowerState#tower_state.csid) of %% 这个场景是否已经打完了
               true ->
                   BeginCountTime = TowerState#tower_state.etime - BTime,
                   {ok, BinData} = pt_280:write(28007, [BeginCountTime, 1]),
                   lib_server_send:send_to_uid(Id, BinData);
               false ->
                   BeginCountTime =  util:unixtime() - BTime,
                   {ok, BinData} = pt_280:write(28007, [BeginCountTime, 2]),
                   lib_server_send:send_to_uid(Id, BinData)
           end,
            {noreply, State};
        false ->
            case lists:keyfind(NowSceneId, 1, TowerState#tower_state.esid) of
                false -> {noreply, State}; 
                {_, _BTime} -> 
                    %1.关闭上一层的定时器.
                    CloseTimer = TowerState#tower_state.close_timer,
                    if 
                        is_reference(CloseTimer) ->
                            erlang:cancel_timer(CloseTimer);
                        true ->
                            skip
                    end,

                    %2.重新设置定时器.
                    TowerInfo = data_tower:get(SceneId),	
                    CloseTimer2 = erlang:send_after((TowerInfo#tower.time+5)*1000, self(), dungeon_time_end),

                    NowTime = util:unixtime(),
                    {ok, BinData} = pt_280:write(28007, [0, 2]),
                    [lib_server_send:send_to_uid(R#dungeon_player.id, BinData) || R <- State#dungeon_state.role_list],
                    {noreply, State#dungeon_state{tower_state = TowerState#tower_state{esid = [{SceneId, NowTime}|TowerState#tower_state.esid], btime = NowTime, extand_time = 0, close_timer = CloseTimer2}}}
            end
    end;

%% 锁妖塔每层奖励结算(锁妖塔).
handle_info({'tower_reward', SceneId, RewardTime}, State) ->
    TowerState = State#dungeon_state.tower_state,
	
	%% 是否已经发放奖励了.
    case lists:member(SceneId, TowerState#tower_state.csid) of 
        true ->	
            {noreply, State};
        false ->
            case SceneId of
                0 -> {noreply, State};
                _ ->
                    RoleInfo = State#dungeon_state.role_list,
                    CloseTimer = TowerState#tower_state.close_timer,
                    if 
                        is_reference(CloseTimer) ->
                            erlang:cancel_timer(CloseTimer);
                        true ->
                            skip
                    end,

                    %1.告诉客户端计时结束.
                    [lib_server_send:send_to_uid(RX#dungeon_player.id, pt:pack(28003, <<>>)) || RX <- RoleInfo],
                    F = fun(RL) ->
                            Id = RL#dungeon_player.id,
                            case lib_player:get_player_info(Id) of
                                false -> [];
                                Player ->
                                    [Weapon, Cloth , _, WLight, _CLight|_] = Player#player_status.goods#status_goods.equip_current, 
                                    ShiZhuang = [Player#player_status.goods#status_goods.fashion_weapon, 
                                        Player#player_status.goods#status_goods.fashion_armor, 
                                        Player#player_status.goods#status_goods.fashion_accessory],
                                    [{Player#player_status.id, Player#player_status.lv, 
                                            Player#player_status.realm, Player#player_status.career, 
                                            Player#player_status.sex, Weapon, Cloth, WLight, 
                                            Player#player_status.goods#status_goods.stren7_num, ShiZhuang, 
                                            Player#player_status.goods#status_goods.suit_id, 
                                            Player#player_status.vip#status_vip.vip_type, 
                                            Player#player_status.nickname}]
                            end
                    end,

                    TowerInfo = data_tower:get(SceneId),

                    %1.闯天路：单人通过九重天的第N层.
                    if length(RoleInfo) == 1 andalso State#dungeon_state.begin_sid == 340 ->
                            [Player1] = RoleInfo, 
                            case lib_player:get_player_info(Player1#dungeon_player.id, achieve) of
                                false -> ok;
                                StatusAchieve ->
                                    lib_player_unite:trigger_achieve(Player1#dungeon_player.id, trigger_trial, 
                                        [StatusAchieve, Player1#dungeon_player.id, 32, 0, TowerInfo#tower.level])
                            end;
                        true -> ok
                    end,

                    %2.判断能否当上霸主.            
                    case TowerInfo#tower.be_master =:= 1 of
                        true ->
                            DunInfo = data_dungeon:get(State#dungeon_state.begin_sid),
                            TowerName = binary_to_list(DunInfo#dungeon.name),
                            L = lists:flatmap(F, RoleInfo), %% 获取通关人员列表
                            mod_disperse:cast_to_unite(lib_tower_dungeon, be_master, 
                                [SceneId, L, RewardTime, 
                                    1, TowerName, State#dungeon_state.begin_sid]); %% 判断能否当上霸主
                        false -> ok
                    end,
                    MeberIds = [RXX1#dungeon_player.id|| RXX1 <- RoleInfo],

                    %5.计算要发放的经验.
                    ExReward = TowerState#tower_state.exreward,
                    %% 经验倍数
                    Ratio = case TowerState#tower_state.ratio > 0 of
                        true -> TowerState#tower_state.ratio;
                        false -> 1
                    end,
                    {NowRewardExp, NowRewardLlpt} = 
                    case ExReward of
                        %1.一般奖励.
                        1 ->  
                            {round(TowerInfo#tower.exp*Ratio), round(TowerInfo#tower.llpt*Ratio)};
                        %2.三种职业提高20%的奖励.
                        ExReward -> 
                            {round(TowerInfo#tower.exp*ExReward*Ratio), round(TowerInfo#tower.llpt*ExReward*Ratio)}
                    end,

                    %6.为每个玩家做一个奖励的记录.
                    F3 = fun(Rx) -> 
                            case lib_tower_dungeon:get_tower_reward(Rx#dungeon_player.id) of
                                [] ->
                                    lib_tower_dungeon:set_tower_reward(Rx#dungeon_player.id, 
                                        #ets_tower_reward{player_id = Rx#dungeon_player.id, 
                                            dungeon_pid = self(), 
                                            fin_sid = SceneId, 
                                            begin_sid = State#dungeon_state.begin_sid, 
                                            exreward = TowerState#tower_state.exreward, 
                                            active_scene = State#dungeon_state.active_scene, 
                                            dungeon_time = State#dungeon_state.time,
                                            member_ids   = MeberIds
                                        });
                                [R] ->
                                    lib_tower_dungeon:set_tower_reward(Rx#dungeon_player.id, 
                                        R#ets_tower_reward{player_id = Rx#dungeon_player.id, 
                                            dungeon_pid = self(), 
                                            fin_sid = SceneId,
                                            member_ids = MeberIds
                                        })
                            end,
                            gen_server:cast(Rx#dungeon_player.pid, {'tower_reward_exp', 
                                    NowRewardExp, 
                                    NowRewardLlpt,
                                    State#dungeon_state.begin_sid,
                                    TowerInfo#tower.level,
                                    MeberIds
                                })
                    end,
                    [F3(RX1)|| RX1 <- RoleInfo],
                    %% 触发目标
                    case lists:member(TowerInfo#tower.level, [5, 10, 20, 26]) of
                        true ->
                            lists:foreach(fun(TargetRole) ->
						  case TowerInfo#tower.level =:= 20 andalso State#dungeon_state.begin_sid =:= 300 of
						      true -> lib_qixi:update_player_task(TargetRole#dungeon_player.id, 9, 1);
						      false -> []
						  end,
                                        case misc:get_player_process(TargetRole#dungeon_player.id) of
                                            false -> ok;
                                            Pid when is_pid(Pid) ->
						gen_server:cast(Pid, {trigger_target, [TargetRole#dungeon_player.id, 203, TowerInfo#tower.level]});
                                            _ -> ok
                                        end
                                end, RoleInfo);
                        _ ->
                            ok
                    end,
		    
                    %% 对随时离线的人员赋值
                    NewMaxIds = case TowerState#tower_state.max_ids of
                        [] -> MeberIds;
                        _ -> TowerState#tower_state.max_ids
                    end,
                    {noreply, State#dungeon_state{tower_state = 
                            TowerState#tower_state{
                                max_ids = NewMaxIds,
                                csid = [SceneId|TowerState#tower_state.csid], 
                                etime = util:unixtime()}}}
            end
    end;

%% 锁妖塔累计奖励(锁妖塔).
handle_info({'total_tower_reward', Uid}, State) ->
	%1.关闭锁妖塔界面.
    case State#dungeon_state.begin_sid == 300 orelse State#dungeon_state.begin_sid == 340 of
        true ->						
			lib_server_send:send_to_uid(Uid, pt:pack(28008, <<>>));
        false ->
        	ok
	end,
	{noreply, State};

%%     TowerState = State#dungeon_state.tower_state,
%%     case TowerState#tower_state.csid of %% 是否有通关的场景
%%         [] -> 
%% 			{noreply, State};
%%         [_SceneId | _] ->
%% 			%2.发奖励.
%%             case lib_tower_dungeon:reward(Uid, 1) of
%%                 false -> 
%% 					{noreply, State};
%%                 {AfterExRExp, AfterExRLlpt, AfterCutItems, AfterCutHonour, 
%% 				 AfterCutKingHonour, _ExRewardSign, _ActiveBox, TowerName, Level, TotalTime} -> 
%%                     case lists:keyfind(Uid, 2, State#dungeon_state.role_list) of
%%                         false -> 
%% 							{noreply, State};
%%                         R ->
%%                             %        [Exp, Llpt, Items, Honour, KingHonour, NewRewarders, ActiveBox] = case lists:keyfind(Uid, 1, TowerState#tower_state.rewarder) of %% 判断是否已经领取过
%%                             %            false -> [0, 0, [], 0, 0,[{Uid, SceneId} | TowerState#tower_state.rewarder], 0];
%%                             %            {_, RewardSceneId} -> 
%%                             %                TowerInfo = data_tower:get(RewardSceneId),
%%                             %                [TowerInfo#tower.total_exp, 
%%                             %                    TowerInfo#tower.total_llpt, 
%%                             %                    TowerInfo#tower.total_items,
%%                             %                    TowerInfo#tower.total_honour,
%%                             %                    TowerInfo#tower.total_king_honour,
%%                             %                    lists:keyreplace(Uid, 1, TowerState#tower_state.rewarder, {Uid, SceneId}),
%%                             %                    1
%%                             %                ]
%%                             %        end,
%%                             %        TowerInfo2 = data_tower:get(SceneId),
%%                             %        case TowerInfo2#tower.total_exp - Exp > 0 of
%%                             %            true ->
%%                             %                DungeonInfo = data_dungeon:get(State#dungeon_state.begin_sid),
%%                             %                TowerName = binary_to_list(DungeonInfo#dungeon.name),
%%                             %                AfterCutItems = TowerInfo2#tower.total_items -- Items,
%%                             %                AfterCutHonour = TowerInfo2#tower.total_honour - Honour,
%%                             %                AfterCutKingHonour = TowerInfo2#tower.total_king_honour - KingHonour,
%%                             %                {AfterExRExp, AfterExRLlpt, ExRewardSign} = case TowerState#tower_state.exreward of
%%                             %                    1 ->  %% 一般奖励
%%                             %                        {TowerInfo2#tower.total_exp - Exp, TowerInfo2#tower.total_llpt - Llpt, 0};
%%                             %                    ExReward -> %% 三种职业提高20%的奖励
%%                             %                        {round((TowerInfo2#tower.total_exp - Exp)*ExReward), round((TowerInfo2#tower.total_llpt - Llpt)*ExReward), 1}
%%                             %               end,
%%                             gen_server:cast(R#dungeon_player.pid, {'tower_reward', AfterExRExp, AfterExRLlpt, AfterCutItems, AfterCutHonour, AfterCutKingHonour, Level, TotalTime, TowerName}),
%%                             %lib_tower_dungeon:tower_reward_mail(Uid, TowerName, TowerInfo2#tower.level, AfterExRExp, AfterExRLlpt, AfterCutHonour, AfterCutKingHonour, ExRewardSign, 1, State#dungeon_state.active_scene, ActiveBox),
%%                             {noreply, State}
%%                     end
%%             end
%%     end;

%% 超时全部离开.
handle_info('CLOSE_TOWER_DUNGEON', State) ->
    F = fun(R) -> 
            %total_tower_reward(self(), R#dungeon_player.id, quit), 
            %lib_dungeon:clear(team, self())
            %total_tower_reward(self(), R#dungeon_player.id, quit),
            lib_dungeon:quit(self(), R#dungeon_player.id, 2),
            lib_dungeon:clear(role, self())
    end,
    [F(R) || R <- State#dungeon_state.role_list],
    {noreply, State}.


%% --------------------------------- 私有函数 ----------------------------------


%% 杀死塔里面的怪.
kill_npc(_, State, _) -> State.
%kill_npc([], State, Sid) ->
%    TowerState = State#dungeon_state.tower_state,
%    case lists:keyfind(Sid, 1, TowerState#tower_state.esid) of
%        false -> skip;
%        {_, BTime} -> 
%            TowerInfo = data_tower:get(Sid),
%            case BTime + TowerInfo#tower.time + 
%                TowerState#tower_state.extand_time - util:unixtime() of %% 重新发送倒计时
%                %1.还有剩余时间.
%                BeginCountTime when BeginCountTime > 0 -> 
%                    {ok, BinData} = pt_280:write(28002, [BeginCountTime, 2, 0]),
%                    [lib_server_send:send_to_uid(R#dungeon_player.id, BinData)|| 
%                        R <- State#dungeon_state.role_list];
%                %2.没剩余时间了.
%                _ -> 
%                    {ok, BinData} = pt_280:write(28002, [0, 2, 0]),
%                    [lib_server_send:send_to_uid(R#dungeon_player.id, BinData)|| 
%                        R <- State#dungeon_state.role_list]
%            end
%    end,
%    State;
%kill_npc(NpcIdList, State, Sid) ->
%    [NpcId|T] = NpcIdList,
%    TowerState = State#dungeon_state.tower_state,
%    TowerMon = data_tower_mon:get(NpcId),
%    case TowerMon#tower_mon.time =:= 0 of
%        true -> State;
%        false -> 
%            case NpcId /= 40166 orelse (NpcId == 40166 andalso (Sid == 413 orelse Sid == 420)) of %% 和氏璧只在13和20层起作用
%                false -> State;
%                true -> 
%                    TowerState = State#dungeon_state.tower_state,
%                    ExTime = TowerState#tower_state.extand_time + TowerMon#tower_mon.time,
%                    NTS = TowerState#tower_state{extand_time = ExTime},
%                    kill_npc(T, State#dungeon_state{tower_state = NTS}, Sid)
%            end
%    end.

%% 创建怪物.
create_mon(SceneId, CopyId, Level, DropNum) ->
	TowerInfo = data_tower:get(SceneId),
	NowBoxRate = util:rand(1, 100),
	BoxRate = TowerInfo#tower.box_rate,
	BoxCount = TowerInfo#tower.box_count,
	BoxMonRate = TowerInfo#tower.box_mon_rate,		
	MonPlace = TowerInfo#tower.mon_place,
	
	if 
		NowBoxRate =< BoxRate ->
			NewMonPlace = util:list_shuffle(MonPlace),
			create_mon_list(NewMonPlace, NewMonPlace, BoxMonRate, SceneId, CopyId, Level, BoxCount, DropNum);
		true ->
			skip
	end.

%% 创建宠物怪物列表.
%% 1.怪物数量用完了.
create_mon_list(_MonPlace1, _MonPlace2, _BoxMonRate, _SceneId, _CopyId, _Level, 0, _DropNum) -> skip;
%% 2.宝箱坐标用完了.
create_mon_list([], MonPlace, BoxMonRate, SceneId, CopyId, Level, BoxCount, DropNum) -> 
	create_mon_list(MonPlace, MonPlace, BoxMonRate, SceneId, CopyId, Level, BoxCount, DropNum);
create_mon_list([{X1, Y1}|MonPlaceTail], MonPlace, BoxMonRate, SceneId, CopyId, Level, BoxCount, DropNum) ->
	case BoxCount =< 0 of
		true ->
			create_mon_list(MonPlaceTail, MonPlace, BoxMonRate, SceneId, CopyId, Level, 0, DropNum);
		false ->
			BoxMonId = get_box_type(30098, BoxMonRate),
            mod_scene_agent:apply_call(SceneId, mod_mon_create, create_mon, 
                [BoxMonId, SceneId, X1, Y1, 0, CopyId, 1, [{auto_lv, Level},{drop_num, DropNum}]]),
			create_mon_list(MonPlaceTail, MonPlace, BoxMonRate, SceneId, CopyId, Level, BoxCount-1, DropNum)
	end.    

%% 获取刷新宝箱的类型
get_box_type(BoxId, BoxRate) ->
    case BoxRate of
        [] ->
            BoxId;
        _ ->
            %总概率
            F = fun([_, R1], Sum1) ->
                Sum1 + R1
            end,
            AllRate = lists:foldl(F, 0, BoxRate),
            %随机刷新
            M = util:rand(1, AllRate),
            F1 = fun([BoxId0, R2], [Sum2, BoxId1]) ->
                    case M > Sum2 andalso M =< Sum2 + R2 of
                        true ->
                            [Sum2 + R2, BoxId0];
                        _ ->
                            [Sum2 + R2, BoxId1]
                    end
            end,
            [_, BoxId2] = lists:foldl(F1, [0, 0], BoxRate),
            %二次修正
            case BoxId2 of
                0 ->
                    BoxId;
                _ ->
                    BoxId2
            end
    end.
