%%%--------------------------------------
%%% @Module  : pp_battle
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.07.25
%%% @Description: 战斗
%%%--------------------------------------
-module(pp_battle).
-export([handle/3]).
-include("server.hrl").
-include("scene.hrl").
-include("skill.hrl").
-include("dungeon.hrl").

%%发动攻击:玩家VS怪:怪物ID, 技能Id, 动作, 攻击的x坐标点(群攻中的直线，前面扇形等无目标要客户端传值，其余情况为0), 攻击的y坐标点(群攻中的直线，前面扇形等无目标要客户端传值，其余情况为0)
handle(20001, Status, [MonId, SkillId, AttMovieType, LineX, LineY]) ->
    NowTime = util:longunixtime(),
    case use_skill_base_check(Status, SkillId, 1, NowTime) of
        {false, ErrCode} -> 
            mod_battle:battle_fail(ErrCode, Status, []),
            {ok, Status};
        {true, SkillLv} ->
            AttKey = [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num],
            %%　通过场景进程来判断是跨服还是本地(消息发送到场景进程处理并执行lib_battle:battle_with_mon)
            mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, battle_with_mon, 
                [Status#player_status.scene, AttKey, MonId, SkillId, SkillLv, AttMovieType, LineX, LineY]),

            %% 更新装备磨损信息
            {ok, AttrStatus} = mod_other_call:updata_equip_attrition(Status),
            {ok, AttrStatus#player_status{last_att_time = NowTime}}
    end;
   

%% 发动攻击 - 玩家VS玩家
handle(20002, Status, [PlayerId, Platform, SerNum, SkillId, AttMovieType, LineX, LineY]) ->
	NowTime = util:longunixtime(),	
    case use_skill_base_check(Status, SkillId, 1, NowTime) of
		{false, ErrCode} -> 
			mod_battle:battle_fail(ErrCode, Status, []),
			{ok, Status};
		{true, SkillLv} -> 
			AttKey = [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num],
			DefKey = [PlayerId, Platform, SerNum],
			 mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, battle_with_player, 
				 [AttKey, DefKey, SkillId, SkillLv, AttMovieType, LineX, LineY
			]),

			%% 更新装备磨损信息
			{ok, AttrStatus} = mod_other_call:updata_equip_attrition(Status),
			{ok, AttrStatus#player_status{last_att_time = NowTime}}
	end;

%%复活
handle(20004, _Status, [_Type]) ->
    %% 特殊场景cast处理
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    case _Status#player_status.scene of
        %% 攻城战场景死亡变成灵魂状态
        CityWarSceneId ->
            Pk = _Status#player_status.pk,
            Value = 7,
            Status = _Status#player_status{
                pk = Pk#status_pk{
                    pk_status = Value,
                    old_pk_status = _Status#player_status.pk#status_pk.pk_status
                }
            },
            mod_scene_agent:update(pk, Status),
            %通知场景的玩家
            {ok, BinData0} = pt_120:write(12084, [_Status#player_status.id, _Status#player_status.platform, _Status#player_status.server_num, Value, Pk#status_pk.pk_value]),
            lib_server_send:send_to_scene(_Status#player_status.scene, _Status#player_status.copy_id, BinData0),
            %每次更改PK状态保存一下坐标
            lib_player:update_player_state(Status);
        _ ->
            Status = _Status
    end,
    %% 是否BOSS场景类型
    ReturnScene = case lib_scene:get_res_type(Status#player_status.scene) =:= ?SCENE_TYPE_BOSS of
        true -> 
            case _Type of
                3 -> Status#player_status.scene;
                _ -> 0
            end;
        false -> 0
    end,
	%% 不允许复活的地图列表
	No_revive_map_List = [251],
	Flag = lists:member(Status#player_status.scene, No_revive_map_List),
    case Flag of
        false->
            SceneId = Status#player_status.scene,
            %% 场景类型
            SceneType = lib_scene:get_res_type(SceneId),
            ReviveRuleRes = case SceneType =:= ?SCENE_TYPE_BOSS of
                %% 进入BOSS场景复活规则判断
                true ->
                    lib_battle:check_revive_rule(Status);
                false ->
                    1
            end,
            %io:format("ReviveRuleRes:~p~n", [ReviveRuleRes]),
            case ReviveRuleRes =:= 1 orelse _Type =/= 3 of
                true ->
                    Type =		
                    case SceneId of
                        %1.塔防副本只能用免费回城复活.
                        234 -> 3;
						235 -> 3;
                        _ -> _Type
                    end,
                    
                    %1.定义检测塔防副本时间函数.
                    FunCheckKingDun = 
                    fun() ->
                        NowTime = util:unixtime(),
                        LastTime = 
                        case get("player_die_time") of
                            undefined -> 
                                0;
                            LastTime1 ->
                                LastTime1
                        end,					
                        case NowTime-LastTime >= 6 of
                            true ->
                                false;
                            false ->
                                true
                        end
                    end,
                    %2.塔防副本6秒后才能复活.
                    DungeonType = lib_dungeon:get_dungeon_type(Status#player_status.scene),
                    case DungeonType of	
                        ?DUNGEON_TYPE_KINGDOM_RUSH ->
							IsKingTime = FunCheckKingDun();
                        ?DUNGEON_TYPE_MULTI_KING ->
							IsKingTime = FunCheckKingDun();
                        _ ->
                            IsKingTime = false
                    end,
                    %HpLim = round(Status#player_status.hp_lim * 0.05),
                    if 
                        %1.塔防副本复活时间未到.
                        IsKingTime ->
                            Result = 4,
                            Status1 = Status;

                        %2.血量大于某个值，玩家未死亡(放进里面判断，让玩家原地原血量复活，防止假死)
                        %Status#player_status.hp > HpLim ->
                        %    Result = 1,
                        %    Status1 = Status;

                        %3.处理复活的事情.
                        true ->            
                            {Result,Status1} = lib_battle:revive(Status,Type)
                    end,
                    %Send 20004
                    {ok, BinData} = pt_200:write(20004, [Result, ReturnScene]),
                    lib_server_send:send_to_sid(Status1#player_status.sid, BinData),
                    Scene_id = data_peach:get_peach_config(scene_id),
                    if
                        Scene_id =:= Status1#player_status.scene ->
                            {ok,Bin} = pt_481:write(48108, [Status1#player_status.id,Status1#player_status.peach_num]),
                            mod_disperse:call_to_unite(lib_unite_send,send_to_scene, 
                                [Scene_id,
                                    Status1#player_status.copy_id,
                                    Bin]);
                        true->void
                    end,

                    %% 1.剧情副本死掉退出副本.
                    case DungeonType of		
                        ?DUNGEON_TYPE_STORY ->
                            lib_dungeon:send_record(Status#player_status.copy_id, false),
                            lib_dungeon:quit(Status#player_status.copy_id, Status#player_status.id, 3),
                            lib_dungeon:clear(role, Status#player_status.copy_id);
                        ?DUNGEON_TYPE_DNTK_EQUIP ->
                            lib_dungeon:quit(Status#player_status.copy_id, Status#player_status.id, 3),
                            lib_dungeon:clear(role, Status#player_status.copy_id);
                        _ ->
                            skip
                    end,
                    
                    %2.返回复活处理的操作.
                    {ok, hp_mp, Status1};
                %% Boss场景复活规则
                false ->
                    %% 复活冷却时间未到
                    {ok, BinData} = pt_200:write(20004, [5, ReturnScene]),
                    lib_server_send:send_to_sid(Status#player_status.sid, BinData)
            end;
		true->
			skip
	end;

%% 发动辅助技能
handle(20006, Status, [PlayerId, Platform, SerNum, SkillId, Act]) -> 
	NowTime = util:longunixtime(),
	case use_skill_base_check(Status, SkillId, 3, NowTime) of
		{false, ErrCode} -> 
			mod_battle:battle_fail(ErrCode, Status, []);
		{true, SkillLv} -> 
			AttKey = [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num],
			DefKey = [PlayerId, Platform, SerNum],
			mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, battle_with_anyone, 
				[AttKey, DefKey, SkillId, SkillLv, Act])
	end,
	ok;

%% 采集怪物
%% MonId : 怪物唯一ID
handle(20008, Status, [MonId, Type]) when Type == 1 orelse Type == 2 ->
    mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, collect, [[Status#player_status.id, Status#player_status.platform, Status#player_status.server_num], MonId, Type]),
    ok;

%% 施放特殊技能
%% SkillId:技能id
%% Id :施放对象id
handle(20009, Status, [SkillId, Id, Platform1, SerNum1, Type]) when Id > 0 ->
    Platform = Status#player_status.platform, 
    SerNum = Status#player_status.server_num,
    case lib_skill:special_skill(Status, SkillId) of
        {true, SkillId1} ->
            %io:format("20009 ~p~n", [Type]), 
            lib_battle:battle_use_whole_skill(Status#player_status.scene, [Status#player_status.id, Platform, SerNum], SkillId1, [Id, Platform1, SerNum1], Type);
        1 -> %% 爱情长跑 
            if
                Id == Status#player_status.id -> %% 对自己施放
                    mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, special_skill, [[Id, Platform, SerNum], [Id, Platform1, SerNum1], SkillId]);
                Status#player_status.parner_id == Id -> %% 对自己的伴侣施放 
                    mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, special_skill, [[Id, Platform, SerNum], [Status#player_status.id, Platform1, SerNum1], SkillId]),
                    mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, special_skill, [[Status#player_status.id, Platform, SerNum], [Id, Platform1, SerNum1], SkillId]);
                true -> %% 对别人施放
                    case lib_player:get_player_info(Id, parner_id) of
                        false -> skip;
                        GirlId -> 
                            mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, special_skill, [[Status#player_status.parner_id, Platform, SerNum], [GirlId, Platform1, SerNum1], SkillId]),
                            mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, special_skill, [[Status#player_status.id, Platform, SerNum], [Id, Platform1, SerNum1], SkillId])
                    end
            end,
            ok;
        false -> skip;
        {false, NewStatus} -> {ok, NewStatus}
    end;

%% 采集怪物 金币怪物
%% MonId : 怪物唯一ID
handle(20010, Status, MonId) ->
    mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, pick, [[Status#player_status.id, Status#player_status.platform, Status#player_status.server_num], [MonId]]),
    ok;

%% 特殊攻击协议（用于模拟攻击）
%% DefType: 被攻击者类型 1是怪物 2是人
handle(20012, Status, [_AttId, DefType, DefId, Platform, ServerNum, SkillId]) when DefType == 1 orelse DefType == 2 ->
    Now = util:longunixtime(),
    LastAttTime = case get("simulate_battle") of
        undefined -> 0;
        _T -> _T
    end, 
    if
        Now - LastAttTime < 700 -> skip; 
        Status#player_status.factionwar_stone == 13 -> %% 现在只支持炮塔玩家控制炮塔
            case SkillId == 904002 of
                true -> case lib_skill:special_skill(Status, SkillId) of
                        {false, NewStatus} -> {ok, NewStatus};
                        _ -> skip
                    end;
                false -> 
                    case lists:keyfind(mid, 1, Status#player_status.factionwar_option) of
                        {_, AttId, _, _} ->
                            put("simulate_battle", Now),
                            mod_battle:send_msg([Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status#player_status.hp, Status#player_status.mp, Status#player_status.anger, SkillId, 1, Status#player_status.x, Status#player_status.y, 0, [], 2, Status#player_status.scene, Status#player_status.copy_id,  Status#player_status.x,  Status#player_status.y, 0, 1, lib_skill_buff:pack_buff([], 0, []), [], 0]),
                            mod_scene_agent:apply_cast(Status#player_status.scene, lib_battle, simulate_battle, [Status#player_status.scene, AttId, DefType, [DefId, Platform, ServerNum], SkillId]);
                        false -> skip
                    end
            end;
        true -> skip
    end;

handle(_Cmd, _Status, _Data) ->
    {error, "pp_battle no match"}.

%% 技能使用基本判断
use_skill_base_check(Status, SkillId, Type, NowTime) ->
	#player_status{mount = Mount, skill = Skill, marriage = Marriage} = Status,
	if
		Mount#status_mount.mount_figure > 0 -> {false, 7};			%% 在坐骑上不能战斗
		Marriage#status_marriage.is_cruise == 1 -> {false, 12};		%% 巡游中不能发起攻击
		true ->
			case lists:keyfind(SkillId, 1, Skill#status_skill.skill_list) of
				false -> {false, 6}; %% 技能配置有错
				{_, SkillLv} -> 
					case Type of
						1 -> 
							% {true, SkillLv};
							case Status#player_status.last_att_time + 700 < NowTime of
							   true  -> {true, SkillLv};
							   false -> {false, 2} %% 出手太快
							end;
						_ ->  
							{true, SkillLv}
					end
			end
	end.

