%%%------------------------------------
%%% @Module  : mod_server_info
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.12.16
%%% @Description: 角色info处理
%%%------------------------------------
-module(mod_server_info).
-export([handle_info/2]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("skill.hrl").
-include("battle.hrl").

%%==========战斗信息battle============
%%更新一般战斗信息
handle_info({'battle_info', BattleReturn}, Status) ->
    case Status#player_status.hp > 0 of
        true ->
            #battle_return{
                hp = Hp,
                x = X,
                y = Y,
                anger = Anger,
                battle_status = BattleStates
            } = BattleReturn,

            NewStatus = Status#player_status{
                hp = Hp,
                x = X,
                y = Y,
                battle_status = BattleStates,
                anger = Anger
            },
            %% 清除护送保护时间
            NewStatus2 = lib_husong:clear_protect_time(NewStatus),
            %%中断交易
            {ok, NewStatus3} = pp_sell:stop_sell(NewStatus2),
            {noreply, NewStatus3};
        false ->
            %%中断交易
            {ok, Status1} = pp_sell:stop_sell(Status),
            {noreply, Status1}
    end;

%% 死亡信息处理
handle_info({'battle_info_die', BattleReturn}, Status) ->
    case Status#player_status.hp > 0 of
        true -> 
            #battle_return{
                hp = _Hp,
                x  = X,
                y  = Y,
                anger = Anger,
                battle_status = BattleStates,
                hit_list      = HitList,
                atter         = Atter,
                sign          = Sign} = BattleReturn,

            #battle_return_atter{
                id = AttId,
                platform = AttPlatFrom,
                server_num = AttServerNum
            } = Atter,

            NewStatus = Status#player_status{
                hp = 0, %% 死亡直接置0
                x = X,
                y = Y,
                battle_status = BattleStates,
                anger = Anger
            },
                
            IsClustersScene = lib_scene:is_clusters_scene(NewStatus#player_status.scene), 
            DieStatus = if
                %% 跨服死亡处理
                IsClustersScene == true ->
                    %% 修正速度
                    lib_scene:change_speed(NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, NewStatus#player_status.speed, 2),
                    %% 修正形象
                    FixFigureStatus = lib_figure:player_die(NewStatus),

					%%设置诸神
					God_Scene_id_flag1 = lists:member(NewStatus#player_status.scene, data_god:get(scene_id2)),
					God_Scene_id_flag2 = lists:member(NewStatus#player_status.scene, data_god:get(scene_id2)),
					if
						God_Scene_id_flag1=:=true andalso God_Scene_id_flag2=:=true->
							mod_clusters_node:apply_cast(mod_god,when_kill,
												[AttPlatFrom,
                                                 AttServerNum,
                                                 AttId,
												 NewStatus#player_status.platform,
												 NewStatus#player_status.server_num,
												 NewStatus#player_status.id]);
						true->void	
					end,

                    %% 1v1处理 -------------------------------
                    Kf_1v1_Scene_id = data_kf_1v1:get_bd_1v1_config(scene_id2),
					if
						NewStatus#player_status.scene == Kf_1v1_Scene_id ->
                            lib_kf_1v1:when_kill(AttPlatFrom,
                                                 AttServerNum,
                                                 AttId,
                                                 0,
                                                 0,
                                                 0,
												 NewStatus#player_status.platform,
												 NewStatus#player_status.server_num,
												 NewStatus#player_status.id,
												 NewStatus#player_status.combat_power,
												 NewStatus#player_status.hp,
												 NewStatus#player_status.hp_lim);
						true-> void	
					end,
					
					%% 3v3处理 -------------------------------
					Kf3v3SceneIds = data_kf_3v3:get_config(scene_pk_ids),
					Kf3v3SceneInScene = lists:member(NewStatus#player_status.scene, Kf3v3SceneIds),
					if
						Kf3v3SceneInScene =:= true ->
							case Sign =:= 2 of
								true ->
									%% 助攻玩家列表
									_HitKeyList = lists:keydelete([AttId, AttPlatFrom, AttServerNum], 1, HitList),
									%% 将玩家设置为幽灵
									lib_player:update_player_info(NewStatus#player_status.id, [{force_change_pk_status, 7}]),
									mod_clusters_node:apply_cast(mod_kf_3v3, when_kill, [
										AttPlatFrom, AttServerNum, AttId, 
										NewStatus#player_status.platform, NewStatus#player_status.server_num, 
										NewStatus#player_status.id, _HitKeyList
									]);
								_ ->
									%% 将玩家设置为幽灵
									lib_player:update_player_info(NewStatus#player_status.id, [{force_change_pk_status, 7}])
							end;
						true-> skip
					end,

                    %% return
                    FixFigureStatus;

                %% 本服死亡处理 
                true ->
                    %1.插入玩家死亡时的时间.
                    NowTime = util:unixtime(),
                    put("player_die_time", NowTime),

                    %2.死亡处理
                    CalcDieStatus = lib_player:player_die(NewStatus, Sign, Atter, HitList),

                    %% return
                    CalcDieStatus
            end,

            %% 清除护送保护时间
            HusongStatus = lib_husong:clear_protect_time(DieStatus),
            %%中断交易
            {ok, SellStatus} = pp_sell:stop_sell(HusongStatus),
            {noreply, SellStatus};
        false ->
            {noreply, Status}
    end;

%% 持续改变hp，不致死
handle_info({last_change_hp, Int, Float}, Status) ->
    %% 先判断是否已经死亡
    case Status#player_status.hp > 0  of
        true ->
            HpMin = max(1, round(Status#player_status.hp + Status#player_status.hp_lim * Float + Int)),
            HpMax = min(Status#player_status.hp_lim, HpMin),
            case HpMax =< 0 of
                true ->
                    NewStatus = Status#player_status{hp = 1};   %% 不致死
                false ->
                    NewStatus = Status#player_status{hp = HpMax}
            end,
            %% 更新到场景数据
            mod_scene_agent:update(hp_mp, NewStatus),
            %%  广播给附近玩家
            {ok, BinData} = pt_120:write(12009, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, NewStatus#player_status.hp, NewStatus#player_status.hp_lim]),
            case lib_scene:is_broadcast_scene(NewStatus#player_status.scene) of
                true -> 
                    lib_server_send:send_to_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, BinData);
                false -> 
                    lib_server_send:send_to_area_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, BinData)
            end,
            {noreply, NewStatus};
        false ->
            {noreply, Status}
    end;

%% 设置战斗状态
handle_info({'BATTLE_STATUS', BattleStatus}, Status) ->
    NewStatus = Status#player_status{battle_status = BattleStatus},
    {noreply, NewStatus};

%% 设置技能cd
handle_info({'SKILL_CD', SkillId, LastTime}, Status) ->
    Skill = Status#player_status.skill,
    NewSkillCd = [{SkillId, LastTime} | lists:keydelete(SkillId, 1, Skill#status_skill.skill_cd)],
    {noreply, Status#player_status{skill = Skill#status_skill{skill_cd = NewSkillCd}}};

%% 进入锁妖塔
handle_info({'enter_tower', [_LeftTime, Sid, Ratio]}, Status) ->
	%mod_dungeon_data:set_tower_reward(Status#player_status.pid_dungeon_data, undefined),
	lib_scene:leave_scene(Status#player_status{copy_id = 0}),
    case pp_scene:handle(12005, Status, Sid) of
        {ok, NewStatus} -> 
            %{ok, BinData} = pt_280:write(28007, [0, 2]),
            %lib_send:send_one(Status#player_status.socket, BinData),
            mod_login:save_online(NewStatus),
            case Sid of
                300 ->
                    skip;
                    %lib_qixi:update_player_task(Status#player_status.id, t3);   %% 多人
                340 -> 
                    skip;
                    %lib_qixi:update_player_task(Status#player_status.id, t4);   %% 单人
                _ -> skip
            end,
            %% 双倍掉落需要增加一次进入次数
            if
                Ratio > 0 andalso Sid == 300 -> mod_daily:increment(Status#player_status.dailypid, Status#player_status.id, Sid);
                true -> skip
            end,
            NewStatus1 = if
                Ratio == 0 -> NewStatus;
                Sid == 340 orelse (Sid == 300 andalso NewStatus#player_status.leader == 1) -> 
                    case lib_goods_util:is_enough_money(NewStatus, 10, gold) of
                        true ->
                            StatusCostOk = lib_goods_util:cost_money(NewStatus, 10, gold),
                            log:log_consume(tower_doube_drop, gold, NewStatus, StatusCostOk, integer_to_list(Sid)),
                            lib_player:refresh_client(NewStatus#player_status.id, 2),
                            StatusCostOk;
                        false ->
                            %% 不足
                            NewStatus
                    end;
                true -> NewStatus
            end,
            %lib_facebook:send_fb_tower(NewStatus1#player_status.socket),
            %lib_doubt_account:do_event(Status#player_status.id, 4, Status#player_status.lv),
            {noreply, NewStatus1};
        _ -> {noreply, Status}
    end;

%% 跳层进入锁妖塔
handle_info({'enter_tower_by_level', [_LeftTime, TowerId, SidOnly, DPid]}, Status) ->
	%mod_dungeon_data:set_tower_reward(Status#player_status.pid_dungeon_data, undefined),
    case pp_scene:handle(12005, Status#player_status{copy_id = DPid}, SidOnly) of
        {ok, NewStatus} -> 
            mod_dungeon:join(DPid, Status#player_status.id),
            %{ok, BinData} = pt_280:write(28007, [0, 2]),
            %lib_send:send_one(Status#player_status.socket, BinData),
            %mod_daily:increment(Status#player_status.id, 2800),
            mod_daily:increment(Status#player_status.id, TowerId),
            mod_login:save_online(NewStatus),
            %lib_facebook:send_fb_tower(NewStatus#player_status.socket),
            %lib_doubt_account:do_event(Status#player_status.id, 4, Status#player_status.lv),
            {noreply, NewStatus};
        _ -> {noreply, Status}
    end;

%% 进入多人副本.
handle_info({'enter_multi_dungeon', [SceneId]}, Status) ->
	lib_scene:leave_scene(Status#player_status{copy_id = 0}),
    case pp_scene:handle(12005, Status, SceneId) of
        {ok, NewStatus} -> 
            mod_login:save_online(NewStatus),            
            {noreply, NewStatus};
        _ ->
			{noreply, Status}
    end;

%% 帮派镖车奖励
handle_info({'guild_biao_reward', Exp, Ratio}, Status) ->
     Status1 = lib_player:add_exp(Status, Exp, 0),
     lib_player:refresh_client(Status#player_status.id, 2), %% 刷新客户端
     %% 触发成就
     case Ratio =:= 1 of
         %% 运镖成功
         true -> 
			 skip;
         false -> skip
     end,
     {noreply, Status1};

%% 位移技能
handle_info({xy, [X, Y]}, Status) ->
    Status1 = Status#player_status{ x = X, y = Y },
    {noreply, Status1};

%% 婚车周围的经验
handle_info('marriage_exp', #player_status{lv = Lv}=Status) -> 
    NewStatus = lib_player:add_exp(Status, Lv*Lv*2),
    {noreply, NewStatus};

%% 多段技能(副技能)
handle_info({'combo_skill', AttKey, DefKey, DefSign, SkillId, SkillLv, LineX, LineY, ComboSkillList}, #player_status{skill=StatusSkill} = Status) -> 
    %Act = case data_skill:get(SkillId, SkillLv) of
    %    []     -> 0;
    %    Skill  -> Skill#player_skill.act
    %end,
    Act = 0,
    case DefSign of
        1 -> 
            [MonId | _] = DefKey,
            mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, battle_with_mon, 
                [Status#player_status.scene, AttKey, MonId, SkillId, SkillLv, Act, LineX, LineY]);
        _ -> 
            mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, battle_with_player, 
                [AttKey, DefKey, SkillId, SkillLv, Act, LineX, LineY])
    end,
    NewSkillRef = case ComboSkillList of
        [] -> 
            none;
        [{Time, NextSkillId} | T] -> 
            Msg = {'combo_skill', AttKey, DefKey, DefSign, NextSkillId, SkillLv, LineX, LineY, T},
            erlang:send_after(Time, self(), Msg)
    end,
    NewStatusSkill = StatusSkill#status_skill{combo_skill_ref = NewSkillRef},
    {noreply, Status#player_status{skill = NewStatusSkill}};

%% 多段技能中断
handle_info('interrupt_combo_skill', Status) -> 
    NewStatus = lib_skill:interrupt_combo_skill(Status),
    {noreply, NewStatus};

%% 默认匹配
handle_info(Info, Status) ->
    catch util:errlog("mod_server_info:handle_info not match: ~p~n", [Info]),
    {noreply, Status}.
