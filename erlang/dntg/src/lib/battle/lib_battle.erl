%% ---------------------------------------------------------
%% Author:  xyao
%% Email:   jiexiaowen@gmail.com
%% Created: 2012-4-26
%% Description: 战斗
%% --------------------------------------------------------
-module(lib_battle).
-export(
    [
        revive/2,
        battle_with_mon/8,
        battle_with_player/7,
        battle_with_anyone/5,			%% 使用辅助技能
        battle_use_whole_skill/4,
        battle_use_whole_skill/5,
        collect/3,
        pick/2,
        interrupt_collect/1,
        special_skill/3,
        check_revive_rule/1,
        simulate_battle/5,
        mon_active_skill/4,
        mon_assist_skill/4
    ]).
-include("scene.hrl").
-include("server.hrl").
-include("skill.hrl").

%%复活方式维护方法(如有特殊复活方式，请添加在if条件里)
%%@param Status #player_status
%%@param Scene #ets_scence
%%@param Type 复活方式  1元宝 2绑定元宝 3回城
%%@return New_Status #player_status
revive_sub(Status,Scene,Type)->
	God_scene_id2_list_Flag = lists:member(Status#player_status.scene,data_god:get(scene_id2)),
	Kf_1v1_scene_id = data_kf_1v1:get_bd_1v1_config(scene_id1),
	Peach_scene_id = data_peach:get_peach_config(scene_id),
	Arena_scene_id = data_arena_new:get_arena_config(scene_id),
	Factionwar_Scene_id = data_factionwar:get_factionwar_config(scene_id),
	Wubianhai_scene_id = data_wubianhai_new:get_wubianhai_config(scene_id),
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
	Kf3v3InPkScene = lists:member(Status#player_status.scene, data_kf_3v3:get_config(scene_pk_ids)),
    EquipEnergyScene = lists:member(Status#player_status.scene, data_equip_energy:get_config(dungeon_list)),
    HpLim = round(Status#player_status.hp_lim * 0.05),
	if
		%%前面这4个判断选项顺序不能变，如有添加，请从第5个判断开始添加
		Scene=:=[]-> %找不到场景数据(10%原地站起)
			SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			X=Status#player_status.x,
			Y=Status#player_status.y,
			Hp = Status#player_status.hp_lim*10 div 100,
			Mp = Status#player_status.mp_lim*10 div 100,
			Revive_type = 2;
		Type =:= 1 -> %元宝复活
			SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			X=Status#player_status.x,
			Y=Status#player_status.y,
			Hp = Status#player_status.hp_lim,
			Mp = Status#player_status.mp_lim,
			Revive_type = 1;
		Type =:= 2 -> %绑定元宝复活
			SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			X=Status#player_status.x,
			Y=Status#player_status.y,
			Hp = Status#player_status.hp_lim*30 div 100,
			Mp = Status#player_status.mp_lim*30 div 100,
			Revive_type = 1;
        Type =:= 4 -> %原血量复活
			SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			X=Status#player_status.x,
			Y=Status#player_status.y,
			Hp = Status#player_status.hp,
			Mp = Status#player_status.mp,
			Revive_type = 1;
		Status#player_status.lv < 30-> %新手挂掉(100%原地站起)
			SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			X=Status#player_status.x,
			Y=Status#player_status.y,
			Hp = Status#player_status.hp_lim,
			Mp = Status#player_status.mp_lim,
			Revive_type = 1;
        %2.血量大于某个值，玩家未死亡(防假死)
        Status#player_status.hp > HpLim ->
            SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			X=Status#player_status.x,
			Y=Status#player_status.y,
			Hp = Status#player_status.hp,
			Mp = Status#player_status.mp,
			Revive_type = 1;
		God_scene_id2_list_Flag=:=true-> %%诸神战斗场景
			SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			X=Status#player_status.x,
			Y=Status#player_status.y,
			Hp = Status#player_status.hp_lim,
			Mp = Status#player_status.mp_lim,
			Revive_type = 2;
		Status#player_status.scene=:=401-> %%兰若密林
			New_Scene = lib_scene:get_data(161),
			SceneId = New_Scene#ets_scene.id,
			CopyId = 0,
			X = New_Scene#ets_scene.x,
			Y = New_Scene#ets_scene.y,
			Hp = Status#player_status.hp_lim,
			Mp = Status#player_status.mp_lim,
			Revive_type = 2;
		Status#player_status.scene=:=400 %%小雷音寺
		  orelse Status#player_status.scene=:=404 %天王殿
		  orelse Status#player_status.scene=:=405 %地藏殿
		  orelse Status#player_status.scene=:=406-> %罗汉殿
			New_Scene = lib_scene:get_data(240), %高老庄
			SceneId = New_Scene#ets_scene.id,
			CopyId = 0,
			X = New_Scene#ets_scene.x,
			Y = New_Scene#ets_scene.y,
			Hp = Status#player_status.hp_lim,
			Mp = Status#player_status.mp_lim,
			Revive_type = 2;
		Status#player_status.scene=:=402 %%失魂洞
		  orelse Status#player_status.scene=:=403 %鬼王谷
		  orelse Status#player_status.scene=:=407 %鬼王谷
		  orelse Status#player_status.scene=:=408 %不知殿
		  orelse Status#player_status.scene=:=409 %不觉殿
		  orelse Status#player_status.scene=:=410 %落魄洞
		  orelse Status#player_status.scene=:=411 %丧胆洞
		  orelse Status#player_status.scene=:=412 ->%白虎岭
			New_Scene = lib_scene:get_data(103), %江南郊外
			SceneId = New_Scene#ets_scene.id,
			CopyId = 0,
			X = New_Scene#ets_scene.x,
			Y = New_Scene#ets_scene.y,
			Hp = Status#player_status.hp_lim,
			Mp = Status#player_status.mp_lim,
			Revive_type = 2;
		Status#player_status.scene=:=413
		  orelse Status#player_status.scene=:=414->%70BOSS场景
			New_Scene = lib_scene:get_data(108), %火焰山复活
			SceneId = New_Scene#ets_scene.id,
			CopyId = 0,
			X = New_Scene#ets_scene.x,
			Y = New_Scene#ets_scene.y,
			Hp = Status#player_status.hp_lim,
			Mp = Status#player_status.mp_lim,
			Revive_type = 2;
		Status#player_status.scene=:=Kf_1v1_scene_id-> %1v1
			SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			X=Scene#ets_scene.x,
			Y=Scene#ets_scene.y,
			Hp = Status#player_status.hp_lim*10 div 100,
			Mp = Status#player_status.mp_lim*10 div 100,
			Revive_type = 2;
		Status#player_status.scene=:=Peach_scene_id-> %蟠桃园
			SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			X=Scene#ets_scene.x,
			Y=Scene#ets_scene.y,
			Hp = Status#player_status.hp_lim*50 div 100,
			Mp = Status#player_status.mp_lim*50 div 100,
			Revive_type = 2;
		Status#player_status.scene=:=Arena_scene_id-> %竞技场
			Realm = Status#player_status.group,
			case Realm of
				0-> %竞技场中无记录，直接扔回主城
					[SceneId,X,Y] = data_arena_new:get_arena_config(leave_scene),
					CopyId = 0,
					Hp = Status#player_status.hp_lim*10 div 100,
					Mp = Status#player_status.mp_lim*10 div 100,
					Revive_type = 2;
				_-> %50%血蓝复活
					SceneId = Status#player_status.scene,
					CopyId = Status#player_status.copy_id,
					Scene_Born_List = data_arena_new:get_arena_config(scene_born),
					[X,Y] = lists:nth(Realm, Scene_Born_List),
					Hp = Status#player_status.hp_lim*50 div 100,
					Mp = Status#player_status.mp_lim*50 div 100,
                    SkillId = data_arena_new:get_arena_config(die_skill_id),
                    %% 施放竞技场buff
                    MyKey = [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num],
                    lib_battle:battle_use_whole_skill(SceneId,
													  MyKey,
													  SkillId,
													  MyKey),
					Revive_type = 2
			end;
		Status#player_status.scene=:=Factionwar_Scene_id-> %帮战
			[Born_pos,SceneId,CopyId,X,Y] = lib_factionwar:get_born_pos(Status#player_status.id),
			case Born_pos of
				0-> %竞技场中无记录，直接扔回主城
					Hp = Status#player_status.hp_lim*10 div 100,
					Mp = Status#player_status.mp_lim*10 div 100,
					Revive_type = 2;
				_-> %100%满血满蓝复活
					Skill_wd = data_factionwar:get_factionwar_config(skill_wd),
					%添加无敌属性
                    MyKey = [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num],
					lib_battle:battle_use_whole_skill(SceneId,
													  MyKey,
													  Skill_wd,
													  MyKey),
					Hp = Status#player_status.hp_lim,
					Mp = Status#player_status.mp_lim,
					Revive_type = 2
			end;
		Status#player_status.scene=:=Wubianhai_scene_id-> %大闹天宫
			SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			Scene_Born_List = data_wubianhai_new:get_wubianhai_config(scene_born),
			PsX = Status#player_status.x,
			PsY = Status#player_status.y,
			[[BornX1, BornY1], [BornX2, BornY2]] = Scene_Born_List,
			Dist1 = (BornX1 - PsX) * (BornX1 - PsX) + (BornY1 - PsY) * (BornY1 - PsY),
			Dist2 = (BornX2 - PsX) * (BornX2 - PsX) + (BornY2 - PsY) * (BornY2 - PsY),
			case Dist1 > Dist2 of
				true -> [X, Y] = [BornX2, BornY2];
				false -> [X, Y] = [BornX1, BornY1]
			end,
			Hp = Status#player_status.hp_lim,
			Mp = Status#player_status.mp_lim,
			Revive_type = 2;
		Status#player_status.scene=:=234-> %% 塔防副本.
			New_Scene = lib_scene:get_data(234),
			SceneId = New_Scene#ets_scene.id,
			CopyId = Status#player_status.copy_id,
			X = New_Scene#ets_scene.x,
			Y = New_Scene#ets_scene.y,
            MyKey = [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num],
 			lib_battle:battle_use_whole_skill(
				SceneId,MyKey,901056,MyKey),
			Hp = Status#player_status.hp_lim,
			Mp = Status#player_status.mp_lim,
			Revive_type = 2;
		Status#player_status.scene=:=235-> %% 多人塔防副本.
			New_Scene = lib_scene:get_data(235),
			SceneId = New_Scene#ets_scene.id,
			CopyId = Status#player_status.copy_id,
			X = New_Scene#ets_scene.x,
			Y = New_Scene#ets_scene.y,
            MyKey = [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num],
 			lib_battle:battle_use_whole_skill(
				SceneId,MyKey,901056,MyKey),
			Hp = Status#player_status.hp_lim,
			Mp = Status#player_status.mp_lim,
			Revive_type = 2;		
        %% 攻城战场景
        Status#player_status.scene =:= CityWarSceneId ->
            [X, Y] = lib_city_war:get_revive_xy(Status),
            %% 加入死亡列表
            mod_city_war:die_deal(Status#player_status.id),
            SceneId = CityWarSceneId, 
            CopyId = 0,
            Hp = Status#player_status.hp_lim,
            Mp = Status#player_status.mp_lim,
            Revive_type = 2;
		%% 跨服3v3
		Kf3v3InPkScene =:= true ->
			SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			[[XA, YA], [XB, YB]] = data_kf_3v3:get_config(position2),
			case Status#player_status.kf_3v3#status_kf_3v3.team_side of
				0 ->
					X = Scene#ets_scene.x,
					Y = Scene#ets_scene.y;
				1 ->
					X = XA,
					Y = YA;
				_ ->
					X = XB,
					Y = YB
			end,
			Hp = Status#player_status.hp_lim,
			Mp = Status#player_status.mp_lim,
			Revive_type = 2;
        %% 装备副本
        EquipEnergyScene =:= true ->
            SceneId = Status#player_status.scene,
            CopyId = Status#player_status.copy_id,
            New_Scene = lib_scene:get_data(SceneId),
            X = New_Scene#ets_scene.x,
            Y = New_Scene#ets_scene.y,
            Hp = Status#player_status.hp_lim*30 div 100,
            Mp = Status#player_status.mp_lim*30 div 100,
            Revive_type = 2;
		true->%正常死亡(默认复活方式)
			SceneId = Status#player_status.scene,
			CopyId = Status#player_status.copy_id,
			X=Scene#ets_scene.x,
			Y=Scene#ets_scene.y,
			Hp = Status#player_status.hp_lim*10 div 100,
			Mp = Status#player_status.mp_lim*10 div 100,
			Revive_type = 2
	end,
	Status1 = Status#player_status{hp = Hp, mp = Mp,att_protected=5},
	New_Status = lib_scene:change_scene_4_revive(Status1,SceneId,CopyId,X,Y,Revive_type),
	New_Status.

%%复活方法
%%@param Status #player_status
%%@param Type 
%%		1元宝原地复活 
%%   	2绑定元宝原地复活
%%    	3回城复活
%%      4根据参数Status的血量复活
revive(Status,Type)->
	Gold = 10,
	BGold = 10,
    %% 某些场景限制情况
    %% 南天门只允许回城复活
    Wubianhai_scene_id = data_wubianhai_new:get_wubianhai_config(scene_id),
    %% 攻城战只允许回城复活
    CityWarInfoSceneId = data_city_war:get_city_war_config(scene_id),
    case lists:member(Status#player_status.scene, [Wubianhai_scene_id, CityWarInfoSceneId]) of
        true ->
            case Type of
                3 ->
                    New_Status = Status,
                    Result = 1;
                _ ->
                    Result = 4,
                    New_Status = Status
            end;
        false ->
            case Type of
                1-> %元宝原地复活
                    if
                        Gold=<Status#player_status.gold+Status#player_status.bgold->
                            Result = 1,
                            %%扣除元宝
                            New_Status = lib_goods_util:cost_money(Status, Gold, silver_and_gold),
                            % 写消费日志
                            About = lists:concat([Status#player_status.id," silver_and_gold revive ",Status#player_status.scene]),
                            log:log_consume(revive, gold, Status, New_Status, About);
                        true->
                            New_Status = Status,
                            Result = 0
                    end;
                2-> %绑定元宝原地复活
                    if
                        BGold=<Status#player_status.bgold->
                            Result = 1,
                            %%扣除元宝
                            New_Status = lib_goods_util:cost_money(Status, Gold, bgold),
                            % 写消费日志
                            About = lists:concat([Status#player_status.id," bgold revive ",Status#player_status.scene]),
                            log:log_consume(revive, bgold, Status, New_Status, About);
                        true->
                            New_Status = Status,
                            Result = 2
                    end;
                _-> %新手原地复活、回城复活
                    New_Status = Status,
                    Result = 1	
            end
    end,
	case Result of
		1->
			Scene = lib_scene:get_data(New_Status#player_status.scene),
			New_Status_Final = revive_sub(New_Status,Scene,Type);
		_->
			New_Status_Final = Status
	end,
	{Result,New_Status_Final}.

%% 使用群体技能
%% @param SceneId 场景ID
%% @param MyKey 攻击者key
%% @param SKillId 技能ID
%% @param SrcKey 被攻击者key
%% @return
battle_use_whole_skill(SceneId, MyKey, SKillId, SrcKey)->
	battle_use_whole_skill(SceneId, MyKey, SKillId, SrcKey, 2).
battle_use_whole_skill(SceneId, MyKey, SKillId, SrcKey, Type)->
	case data_skill:get(SKillId, 1) of
		[] -> 
			false;
		Skill ->
			if
				Skill#player_skill.type == 1 -> %% 主动技能
					case Type of
						2 -> %% 玩家 
							mod_scene_agent:apply_cast(SceneId, lib_battle, battle_with_player, [MyKey, SrcKey, SKillId, 1, 1, 0, 0]),
							true;
						1 -> %% 怪物
							[MonId | _] = SrcKey,
							mod_scene_agent:apply_cast(SceneId, lib_battle, battle_with_mon, [SceneId, MyKey, MonId, SKillId, 1, 1, 0, 0]),
							true;
						_ -> 
							false
					end;
				Skill#player_skill.type == 3 -> %% 辅助技能
					mod_scene_agent:apply_cast(SceneId, lib_battle, battle_with_anyone, [MyKey, SrcKey, SKillId, 1, 1]),
					true;
				true -> %% 其他技能
					false
			end
	end.

%% 和怪物战斗
%% AttKey  :玩家key
%% MonId   :怪物唯一id
%% SkillId :所使用的技能id
battle_with_mon(Scene, AttKey, MonId, SkillId, SkillLv, AttMovieType, LineX, LineY) ->
	case lib_scene_agent:get_user(AttKey) of
		[] ->
			skip;
		User ->
			NewMon = case LineX /= 0 andalso LineY /= 0 of
				true  -> #ets_mon{hp=1, x = LineX, y = LineY};
				false ->  
					case lib_mon:lookup(Scene, MonId) of
						[]  -> [];
						Mon -> Mon
					end
			end,
			case NewMon of
				[] ->
					mod_battle:battle_fail(1, User, []);
				_  ->
					case User#ets_scene_user.hp > 0 of
						true ->
							case mod_battle:battle(User, NewMon, SkillId, SkillLv, AttMovieType, LineX, LineY) of
								{false, ErrCode, _Aer} ->
									mod_battle:battle_fail(ErrCode, User, NewMon);
								{true, Aer} ->
									lib_player:update_player_info(Aer#ets_scene_user.id, [{hp, Aer#ets_scene_user.hp}, {anger, Aer#ets_scene_user.anger}]),
									lib_scene_agent:put_user(Aer)
							end;
						false ->
							mod_battle:battle_fail(3, User, NewMon)
					end
			end
	end.

%% 和玩家战斗
%% AttKey : 攻击玩家key
%% DefKey : 目标玩家key
%% SkillId : 所使用的技能id
%% AttMovieType : 攻击动作
battle_with_player(AttKey, DefKey, SkillId, SkillLv, AttMovieType, LineX, LineY) ->
	case lib_scene_agent:get_user(AttKey) of
		[] ->
			false;
		User ->
			Player = case AttKey == DefKey of
				true  -> User;
				false -> lib_scene_agent:get_user(DefKey)
			end,
			case Player of
				[] -> 
					false;
				_  ->
					IsProtect = lib_husong:is_protect_time(Player),
					if
						User#ets_scene_user.hp   =< 0 -> mod_battle:battle_fail(3, User, []);
						Player#ets_scene_user.hp =< 0 -> mod_battle:battle_fail(1, User, []);
						IsProtect -> mod_battle:battle_fail(9, User, []);
						true -> 
							case mod_battle:battle(User, Player, SkillId, SkillLv, AttMovieType, LineX, LineY) of
								{false, ErrCode, _Aer} ->
									mod_battle:battle_fail(ErrCode, User, Player),
									false;
								{true, Aer} ->
									lib_player:update_player_info(Aer#ets_scene_user.id, [{hp, Aer#ets_scene_user.hp}, {anger, Aer#ets_scene_user.anger}]),
                                    %% 如果是竞技场技能，要更新玩家怒气
                                    Arena_scene_id = data_arena_new:get_arena_config(scene_id),
                                    Arena_skill_id = data_arena_new:get_arena_config(arena_skill_id),
                                    case Aer#ets_scene_user.scene =:= Arena_scene_id andalso SkillId =:= Arena_skill_id of 
                                        true ->
                                            lib_player:update_player_info(Aer#ets_scene_user.id,[{arena_anger, 20}]);
                                        false ->
                                            skip
                                    end,
									Aer1 = interrupt_collect(Aer),
									lib_scene_agent:put_user(Aer1),
									true
							end
					end
			end
	end.

%% 使用辅助技能
%% AttKey : 攻击玩家key
%% DefKey : 被攻击玩家key
%% SkillId : 技能id
%% SkillLv : 技能等级
%% Act : 动作
battle_with_anyone(AttKey, DefKey, SkillId, SkillLv, Act) ->
	case lib_scene_agent:get_user(AttKey) of
		[] ->
			false;
		User ->
			Player = case AttKey == DefKey of
				true -> User;
				false -> lib_scene_agent:get_user(DefKey)
			end, 
			case Player of
				[] -> false;
				_ -> 
					if
						User#ets_scene_user.hp =< 0 -> mod_battle:battle_fail(3, User, []), false;
						Player#ets_scene_user.hp =< 0 -> mod_battle:battle_fail(1, User, Player), false;
						true -> mod_battle:assist_skill(User, Player, SkillId, SkillLv, Act), true
					end
			end
	end.

%% 采集怪物
%% MyKey : 玩家key
%% SrcId : 怪物自动id
%% Type : 1开始采集, 2结束采集
collect(MyKey, SrcId, Type) ->
	[MyId | _] = MyKey,
	case lib_scene_agent:get_user(MyKey) of
		[] -> skip;
		User ->
			Res = case lib_mon:lookup(User#ets_scene_user.scene, SrcId) of
				[] -> 4;
				Mon ->
					if 
						Mon#ets_mon.hp =< 0 orelse User#ets_scene_user.hp =< 0 -> 4;
						% User#ets_scene_user.factionwar_stone /= 0 andalso User#ets_scene_user.scene == 109 -> 9;
						% User#ets_scene_user.factionwar_stone /= 0 -> 8;
						abs(User#ets_scene_user.x - Mon#ets_mon.x) > 5 orelse abs(User#ets_scene_user.y - Mon#ets_mon.y) > 5 orelse User#ets_scene_user.copy_id /= Mon#ets_mon.copy_id -> 3;
						true -> 
							case mod_battle:is_can_collect(User, Mon) of
								true -> 
									 case (Mon#ets_mon.mid /= 10500 andalso Mon#ets_mon.mid /= 10507) orelse  mod_factionwar:can_kill_jgb(MyId) of %% 帮派金箍棒特殊处理
									 	false -> 6;
									 	true ->  
											Mon#ets_mon.aid ! {'collect_info', MyKey, User#ets_scene_user.pid, Type},
											if
												Type == 1 andalso (User#ets_scene_user.collect_pid /= {Mon#ets_mon.aid, Mon#ets_mon.mid}) -> 
													User1 = User#ets_scene_user{collect_pid={Mon#ets_mon.aid, Mon#ets_mon.mid}},
													lib_scene_agent:put_user(User1);
												Type == 2 andalso User#ets_scene_user.collect_pid /= {0, 0} ->
													User1 = User#ets_scene_user{collect_pid={0, 0}},
													lib_scene_agent:put_user(User1);
												true -> skip
											end,
											Type
									 end;
								_ErrCode -> _ErrCode
							end
					end
			end,
			%% Res: 1开始成功,2采集成功,3距离太远,4失败,5阵营不同不能采集,6需要先占领封印才能解封金箍棒,7需先击杀相应的神兽才能占领,8运送神石中不能占领
			{ok, BinData} = pt_200:write(20008, Res),
			send_to_uid(User#ets_scene_user.node, MyId, BinData)
	end.

%% 拾取型怪物
%% MyKey : 玩家key
%% MonList : [怪物自增id, ...]
pick(MyKey, MonList) ->
    case lib_scene_agent:get_user(MyKey) of
        [] -> skip;
        User ->
            F = fun(SrcId) -> 
                    case lib_mon:lookup(User#ets_scene_user.scene, SrcId) of
                        [] -> skip;
                        Mon ->
                            Res = if 
                                Mon#ets_mon.hp =< 0 orelse User#ets_scene_user.hp =< 0 orelse (Mon#ets_mon.kind /= 9) -> 2;
                                abs(User#ets_scene_user.x - Mon#ets_mon.x) > 5 orelse abs(User#ets_scene_user.y - Mon#ets_mon.y) > 5 orelse User#ets_scene_user.copy_id /= Mon#ets_mon.copy_id -> 3;
                                true ->
                                    lib_mon:insert(Mon#ets_mon{hp = 0}),
                                    %% 触发技能
                                    case lib_figure:mon_skill(Mon#ets_mon.mid) of
                                        false -> skip;
                                        SkillId -> 
                                            SkillData = data_skill:get(SkillId, 1),
                                            if
                                                SkillData#player_skill.type == 3 ->
                                                    mod_battle:assist_skill(Mon, User, SkillId, 1, 0);
                                                % mod_battle:mon_assist_skill(Mon, User, SkillId, 1, 0);
                                                SkillData#player_skill.type == 1 -> 
                                                    mod_battle:battle(Mon, User, SkillId, 1);
                                                true -> skip
                                            end
                                    end,
                                    % if
                                    % 	Mon#ets_mon.mid >= 25317 andalso Mon#ets_mon.mid =< 25320 ->
                                    % 		%SkillId1 = lists:nth(util:rand(1,7), [508004,508005,508007,508008,508009,508010,508011]),
                                    % 		SkillId1 = lists:nth(util:rand(1,6), [508005,508007,508008,508009,508010,508011]),
                                    % 		{ok, BinData2} = pt_130:write(13034, [1, [{1,SkillId1}]]),
                                    % 		send_to_uid(User#ets_scene_user.node, User#ets_scene_user.id, BinData2),
                                    % 		mod_kfrun_room:skill_msg([User#ets_scene_user.copy_id, {User#ets_scene_user.platform, User#ets_scene_user.server_num, User#ets_scene_user.id}, BinData2, SkillId1, 1]);
                                    % 	true -> skip
                                    % end,
                                    mod_mon_active:die(Mon#ets_mon.aid),
                                    %% 怪物死亡调用，放其他逻辑
                                    pick_mon_die(User, Mon),
                                    1
                            end,
                            {ok, BinData} = pt_200:write(20010, [Res, Mon#ets_mon.mid]),
                            send_to_uid(User#ets_scene_user.node, User#ets_scene_user.id, BinData)
                    end
            end,
            [F(Id) || Id <- MonList]
    end,
    ok.

%% 战斗打断怪物采集
interrupt_collect(User) ->
	{Aid, _Mid} = User#ets_scene_user.collect_pid,
	case is_pid(Aid) of
		true ->
			Aid ! {'stop_collect', [User#ets_scene_user.id, User#ets_scene_user.platform, User#ets_scene_user.server_num]};
		false -> 
			skip
	end,
	User#ets_scene_user{collect_pid={0, 0}}.

%% 怪物模拟战斗
simulate_battle(Scene, MonId, DefType, DefKey, SkillId) ->
	case lib_mon:lookup(Scene, MonId) of
		[] -> skip;
		Mon -> Mon#ets_mon.aid ! {'ATTACK_ONCE', DefType, DefKey, SkillId}
	end.


%% 怪物主动技能
%% DefType : 1怪物，2为玩家
mon_active_skill(Aer, [], SkillId, SkillLv) ->
    %% 没有防守方，以自己为防守方
    mon_active_skill(Aer, Aer, SkillId, SkillLv);
mon_active_skill(Aer, [DefKey, DefType], SkillId, SkillLv) -> 
	Der = case DefType of
		1 ->
			[MonId | _] = DefKey,
			lib_mon:lookup(Aer#ets_mon.scene, MonId);
		_ -> 
			lib_scene_agent:get_user(DefKey)
	end,
	case Der of
		[] -> 
			%% 没有找到攻击对象
			Msg = {false, 3},
			mod_mon_active:att_info_back(Aer#ets_mon.aid, Msg);
		_  -> 
			mon_active_skill(Aer, Der, SkillId, SkillLv)
	end;
mon_active_skill(Aer, Der, SkillId, SkillLv) ->
	Msg = case mod_battle:battle(Aer, Der, SkillId, SkillLv) of
		{true,  AerAfBattle} -> 
			{true, {AerAfBattle#ets_mon.hp, AerAfBattle#ets_mon.battle_status, AerAfBattle#ets_mon.x, AerAfBattle#ets_mon.y, AerAfBattle#ets_mon.skill_cd}};
		{false, ErrCode, _AerAfBattle} -> 
			{false, ErrCode}
	end,
	mod_mon_active:att_info_back(Aer#ets_mon.aid, Msg),
	ok.

%% 怪物使用辅助技能
mon_assist_skill(Aer, [DefKey, DefType], SkillId, SkillLv) -> 
	Der = case DefType of
		1 ->
			[MonId | _] = DefKey,
			lib_mon:lookup(Aer#ets_mon.scene, MonId);
		_ ->
			lib_scene_agent:get_user(DefKey)
	end,
	case Der of
		[] ->
			%% 没有找到辅助对象
			Msg = {false, 3},
			mod_mon_active:att_info_back(Aer#ets_mon.aid, Msg); 
		_ -> 
			mon_assist_skill(Aer, Der, SkillId, SkillLv)
	end;
mon_assist_skill(Aer, Der, SkillId, SkillLv) ->
	case mod_battle:assist_skill(Aer, Der, SkillId, SkillLv, 1) of
        {true, NewAer}    -> mod_mon_active:att_info_back(Aer#ets_mon.aid, {true, NewAer#ets_mon.skill_cd});
		{false, _ErrCode} -> mon_active_skill(Aer, Der, 901011, 1)
	end.

%% 有特殊条件的辅助技能
special_skill(MyKey, SrcKey, SkillId) ->
    case lib_scene_agent:get_user(MyKey) of
        [] ->
            false;
        User ->
            case User#ets_scene_user.hp > 0 of
                true ->
                    case MyKey =:= SrcKey of
                        true -> %% 释放对象是自己
							mod_battle:assist_skill(User, {}, SkillId, 1, 1),
                            true;
                        false -> %% 释放对象是玩家
                            case lib_scene_agent:get_user(SrcKey) of
                                [] ->
                                    false;
                                Player ->
                                    case Player#ets_scene_user.hp > 0 of
                                        true ->
											mod_battle:assist_skill(User, Player, SkillId, 1, 1),
                                            true;
                                        false ->
                                            false
                                    end
                            end
                    end;
                false->
                    false
            end
    end.

%% 进入BOSS场景复活规则判断
check_revive_rule(Status) ->
    PlayerId = Status#player_status.id,
    SceneId = Status#player_status.scene,
    ReviveRole = mod_revive:get_role(PlayerId),
    case dict:find(SceneId, ReviveRole) of
        {ok, Info} ->
            {LastTime, _Num, LastDieTime} = Info,
            Num = _Num + 1,
            Time = util:unixtime() - LastTime,
            ClearBool = Time > 60,
            %io:format("Time:~p, ClearBool:~p~n", [Time, ClearBool]),
            %% 是否达到清数据要求
            case ClearBool of
                true ->
                    NewReviveRole = dict:store(SceneId, {util:unixtime(), 1, LastDieTime}, ReviveRole),
                    mod_revive:set_role(PlayerId, NewReviveRole),
                    Res = 1;
                false ->
                    MiddleTime = util:unixtime() - LastDieTime,
                    CanRevive = (Num >= 31 andalso MiddleTime >= 12) orelse (Num >= 16 andalso Num < 31 andalso MiddleTime >= 8) orelse (Num >= 6 andalso Num < 16 andalso MiddleTime >= 5) orelse Num < 6,
                    %io:format("MiddleTime:~p, Num:~p, CanRevive:~p~n", [MiddleTime, Num, CanRevive]),
                    %% 是否可复活
                    case CanRevive of
                        true ->
                            NewReviveRole = dict:store(SceneId, {util:unixtime(), Num , LastDieTime}, ReviveRole),
                            mod_revive:set_role(PlayerId, NewReviveRole),
                            Res = 1;
                        false ->
                            Res = 2
                    end
            end;
        _ ->
            NewReviveRole = dict:store(SceneId, {util:unixtime(), 1, util:unixtime()}, ReviveRole),
            mod_revive:set_role(PlayerId, NewReviveRole),
            Res = 1
    end,
    Res.

%% 拾取怪死亡之后调用
%% User : #ets_user
%% Mon : #ets_mon
pick_mon_die(User, Mon) ->
	Kf3v3SkillIds = data_kf_3v3:get_all_skill_id(),
	case lists:member(Mon#ets_mon.mid, Kf3v3SkillIds) of
		true ->
			mod_kf_3v3:use_skill(User#ets_scene_user.platform, User#ets_scene_user.server_num, User#ets_scene_user.id, Mon#ets_mon.mid);
		_ ->
			skip
    end.

%% 发送协议
send_to_uid(Node, Id, BinData) -> 
	 case Node =:= none of
		true -> lib_server_send:send_to_uid(Id, BinData);
		false -> rpc:cast(Node, lib_server_send, send_to_uid, [Id, BinData])
	end.
