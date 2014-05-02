%%%------------------------------------
%%% @Module  : mod_battle
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.05.18
%%% @Description: 战斗
%%%------------------------------------
-module(mod_battle).
-compile(export_all).
-include("scene.hrl").
-include("server.hrl").
-include("skill.hrl").
-include("battle.hrl").


%% @spec -> {true, #ets_scene_user | #ets_mon } | {false, ErrCode, #ets_scene_user | #ets_mon}
%% 发起战斗
%% @end
battle(OriginalAer, OriginalDer, SkillId, SkillLv) -> 
	battle(OriginalAer, OriginalDer, SkillId, SkillLv, 1, 0, 0).
battle(OriginalAer, OriginalDer, SkillId, SkillLv, AttMovieType, X, Y) ->
	NowTime = util:longunixtime(),
	Aer     = init_data(OriginalAer),
	Der     = init_data(OriginalDer), 

	case check_use_skill(Aer, Der, SkillId, SkillLv, NowTime) of
		{false, ErrCode, AerSkillCheck} -> 
			battle_fail(ErrCode, AerSkillCheck, Der),
			{false, ErrCode, back_data(OriginalAer, AerSkillCheck)};

        %% ！！！当Aer为怪物时，SkillR中的skill_id有可能与传入的SkillId不一样
		{true, AerSkillCheck, SkillR} -> 
			case skill(AerSkillCheck#battle_status{act = AttMovieType}, Der, SkillR, X, Y, NowTime) of
				{true, AerBattle} -> 
                    %% 技能释放成功，记录cd时间
                    AerSkillCd = set_skill_cd(AerBattle, SkillR#player_skill.skill_id, NowTime),
					{true, back_data(OriginalAer, AerSkillCd)};
				{false, SkillErrCode, AerBattle} -> 
					battle_fail(SkillErrCode, AerBattle, Der),
					{false, SkillErrCode, back_data(OriginalAer, AerBattle)}
			end
	end.

%% @spec -> true | {false, ErrCode}
%% 施放辅助技能
%% @end
assist_skill(OriginalAer, OriginalDer, SkillId, SkillLv, Act) ->
	NowTime = util:longunixtime(),
	%% 初始数据
	Aer = init_data(OriginalAer),
	Der = init_data(OriginalDer),

	case check_use_skill(Aer#battle_status{act=Act}, Der, SkillId, SkillLv, NowTime) of
		{false, ErrCode, AerSkillCheck} -> 
			battle_fail(ErrCode, AerSkillCheck, Der),
			{false, ErrCode};
		{true, AerSkillCheck, SkillR} ->
			%% {技能数据，玩家自身没有的被天赋新影响的效果数据，天赋列表}
			%{SkillTalentR, TalentDatas, _Tids} = calc_skill_talent(SkillR#player_skill.skill_link, SkillR, [], AerSkillCheck, []),
            TalentDatas = [],

			%% cd大于15秒的回写
			skill_cd_mark(SkillR, AerSkillCheck, NowTime),

			%% 根据技能释放对象(1自己,2攻击者)判断受益方
			User = case SkillR#player_skill.obj == 1 of
				true  -> AerSkillCheck;
				false -> Der
            end,
            if
                SkillR#player_skill.type /= 3 -> {false, 6}; %% 非辅助技能
                SkillR#player_skill.mod  == 2 -> 
                    double_assist_skill(AerSkillCheck, User, SkillR, TalentDatas, NowTime),  %% 群攻
                    UserSkillCd = set_skill_cd(User, SkillId, NowTime),
                    {true, UserSkillCd};
                true ->
                    single_assist_skill(AerSkillCheck, User, SkillR, TalentDatas, NowTime), %% 单攻
                    UserSkillCd = set_skill_cd(User, SkillId, NowTime),
                    {true, UserSkillCd} 
            end
	end.

%%初始化战斗双方属性
init_data(Arr) ->
    if
        is_record(Arr, ets_mon) ->
            #battle_status{
                id = Arr#ets_mon.id,
                mid = Arr#ets_mon.mid,
                owner_id = Arr#ets_mon.owner_id,
                boss = Arr#ets_mon.boss,
                name = Arr#ets_mon.name,
                career = Arr#ets_mon.career,
                scene = Arr#ets_mon.scene,
                copy_id = Arr#ets_mon.copy_id,
                lv = Arr#ets_mon.lv,
                hp = Arr#ets_mon.hp,
                hp_lim = Arr#ets_mon.hp_lim,
                mp = Arr#ets_mon.mp,
                mp_lim = Arr#ets_mon.mp_lim,
                att = Arr#ets_mon.att,
                def = Arr#ets_mon.def,
                x = Arr#ets_mon.x,
                y = Arr#ets_mon.y,
                att_area = Arr#ets_mon.att_area,
                sid = Arr#ets_mon.aid,
                hit = Arr#ets_mon.hit,
                dodge = Arr#ets_mon.dodge,
                crit = Arr#ets_mon.crit,
                ten = Arr#ets_mon.ten,
                fire = Arr#ets_mon.fire,          
                ice = Arr#ets_mon.ice,           
                drug = Arr#ets_mon.drug,   
                unyun = Arr#ets_mon.unyun,    
                unbeat_back = Arr#ets_mon.unbeat_back,   
                unholding = Arr#ets_mon.unholding,
                uncm = Arr#ets_mon.uncm,
				skill = [],
				skill_cd = Arr#ets_mon.skill_cd,
                battle_status = Arr#ets_mon.battle_status,
                speed = Arr#ets_mon.speed,
                sign = 1,
				skill_owner = Arr#ets_mon.skill_owner,
                group = Arr#ets_mon.group,
                kind = Arr#ets_mon.kind,
				is_be_atted = Arr#ets_mon.is_be_atted,
                realm = Arr#ets_mon.realm,
                del_hp_each_time = Arr#ets_mon.del_hp_each_time,
                restriction = Arr#ets_mon.restriction
            };
        
        is_record(Arr, ets_scene_user) ->
            BA = Arr#ets_scene_user.battle_attr,
            PK = Arr#ets_scene_user.pk,
            HuSong = Arr#ets_scene_user.husong,
            {FriendGIds, _} = Arr#ets_scene_user.guild_rela,
            AttArea = case Arr#ets_scene_user.factionwar_stone of
                11 -> 4;
                12 -> 8;
                15 -> 5;
                16 -> 5;
                _ -> BA#battle_attr.att_area
            end,
            #battle_status{
                id = Arr#ets_scene_user.id,
                platform = Arr#ets_scene_user.platform,
                server_num = Arr#ets_scene_user.server_num,
                node = Arr#ets_scene_user.node,
                name = Arr#ets_scene_user.nickname,
                career = Arr#ets_scene_user.career,
                scene = Arr#ets_scene_user.scene,
                copy_id = Arr#ets_scene_user.copy_id,
                lv = Arr#ets_scene_user.lv,
                hp = Arr#ets_scene_user.hp,
                hp_lim = Arr#ets_scene_user.hp_lim,
                mp = Arr#ets_scene_user.mp,
                mp_lim = Arr#ets_scene_user.mp_lim,
                %anger = Arr#ets_scene_user.anger,
                %anger_lim = Arr#ets_scene_user.anger_lim,
                ice_hp = Arr#ets_scene_user.ice_hp,
                att = BA#battle_attr.att,
                def = BA#battle_attr.def,
                x = Arr#ets_scene_user.x,
                y = Arr#ets_scene_user.y,
				att_area = AttArea,
                sid = Arr#ets_scene_user.pid,
                hit = BA#battle_attr.hit,
                dodge = BA#battle_attr.dodge,
                crit = BA#battle_attr.crit,
                ten = BA#battle_attr.ten,
                fire = BA#battle_attr.fire,          
                ice = BA#battle_attr.ice,           
                drug = BA#battle_attr.drug,
                hurt_add_num = BA#battle_attr.hurt_add_num,
                hurt_del_num = BA#battle_attr.hurt_del_num,
                combat_power = BA#battle_attr.combat_power,
				skill = BA#battle_attr.skill,
				skill_cd = BA#battle_attr.skill_cd,
				skill_status = BA#battle_attr.skill_status,
                battle_status = BA#battle_attr.battle_status,
                ex_battle_status = BA#battle_attr.ex_battle_status,
                speed = Arr#ets_scene_user.speed,
                pk_status = PK#scene_user_pk.pk_status,
                guild_id = Arr#ets_scene_user.guild_id,
                friend_gids = FriendGIds,
                realm = Arr#ets_scene_user.realm,
                pid_team = Arr#ets_scene_user.pid_team,
                pk_value = PK#scene_user_pk.pk_value,
                sign = 2,
                is_husong = HuSong#scene_user_husong.husong_lv,
                group =  Arr#ets_scene_user.group,
                factionwar_stone = Arr#ets_scene_user.factionwar_stone,
                visible = Arr#ets_scene_user.visible,
                kf_teamid = Arr#ets_scene_user.kf_teamid
            };
        is_record(Arr, player_status) ->
            PK      = Arr#player_status.pk,
            Guild   = Arr#player_status.guild,
            SK      = Arr#player_status.skill,
             AttArea = case Arr#player_status.factionwar_stone of
                11 -> 4;
                12 -> 8;
                15 -> 5;
                16 -> 5;
                _ -> Arr#player_status.att_area
            end,
            #battle_status{
                id = Arr#player_status.id,
                name = Arr#player_status.nickname,
                career = Arr#player_status.career,
                scene = Arr#player_status.scene,
                copy_id = Arr#player_status.copy_id,
                hp = Arr#player_status.hp,
                hp_lim = Arr#player_status.hp_lim,
                mp = Arr#player_status.mp,
                mp_lim = Arr#player_status.mp_lim,
                att =  Arr#player_status.att,
                def =  Arr#player_status.def,
                x = Arr#player_status.x,
                y = Arr#player_status.y,
                att_area = AttArea,
                sid = Arr#player_status.pid,
                hit = Arr#player_status.hit,
                dodge = Arr#player_status.dodge,
                crit = Arr#player_status.crit,
                ten = Arr#player_status.ten,
                fire = Arr#player_status.fire,          
                ice = Arr#player_status.ice,           
                drug = Arr#player_status.drug, 
				skill = SK#status_skill.skill_list,
				skill_cd = SK#status_skill.skill_cd,
                battle_status = Arr#player_status.battle_status,
                ex_battle_status = Arr#player_status.ex_battle_status, 
                speed = Arr#player_status.speed,
                pk_status = PK#status_pk.pk_status,
                guild_id = Guild#status_guild.guild_id,
                realm = Arr#player_status.realm,
                pid_team = Arr#player_status.pid_team,
                pk_value = PK#status_pk.pk_value,
                visible = Arr#player_status.visible,
                sign = 2,
                group =  Arr#player_status.group,
                kf_teamid = Arr#player_status.kf_teamid
            };

        true ->
            Arr
    end.

%% 回写
back_data(ArrInit, Arr) ->
    if
        Arr#battle_status.sign == 1->
            ArrInit#ets_mon{
                hp = Arr#battle_status.hp,
                mp = Arr#battle_status.mp,
				battle_status = Arr#battle_status.battle_status,
				skill_cd      = Arr#battle_status.skill_cd
            };
        Arr#battle_status.sign == 2 ->
            BA = ArrInit#ets_scene_user.battle_attr,
            ArrInit#ets_scene_user{
                hp = Arr#battle_status.hp,
                mp = Arr#battle_status.mp,
				x           = Arr#battle_status.x,
				y           = Arr#battle_status.y,
                battle_attr = BA#battle_attr{
					battle_status = Arr#battle_status.battle_status,
					skill_cd      = Arr#battle_status.skill_cd,
					skill_status  = Arr#battle_status.skill_status
                }
            }
    end.

%%发送消息
send_active_msg(Aer, DefList, LineX, LineY, SkillId, SkillLv) -> 
	#battle_status{
		id = Id,
		platform = Platform,
		server_num = SerNum,
		hp = Hp,
        mp = Mp,
		x = X,
		y = Y,
		act = Act,
		buff_list = AerBuffList,
		effect_list = EffectList,
		sign = Sign,
		scene = SceneId,
		copy_id = CopyId
	} = Aer,
	case Sign of
        1 -> Cmd = 20003; %% 怪物发起的攻击
		_ -> Cmd = 20001  %% 玩家发起的攻击
	end,
	{ok, BinData} = pt_200:write(Cmd, [Id, Platform, SerNum, Hp, Mp, SkillId, SkillLv, X, Y, Act, LineX, LineY, AerBuffList, EffectList, DefList]),
	case lib_scene:is_broadcast_scene(SceneId) of
		true  -> lib_server_send:send_to_scene(SceneId, CopyId, BinData);
		false -> lib_server_send:send_to_area_scene(SceneId, CopyId, X, Y, BinData)
	end.

%%发送辅助技能信息
send_assist_msg(Sign, Id, Platform, SerNum, SkillId, SkillLv, Mp, Act, AssistList, SceneId, CopyId, X, Y) ->
    {ok, BinData} = pt_200:write(20006, [Sign, Id, Platform, SerNum, SkillId, SkillLv, Mp, Act, AssistList]),
	case lib_scene:is_broadcast_scene(SceneId) of
		true ->
			lib_server_send:send_to_scene(SceneId, CopyId, BinData);
		false ->
			lib_server_send:send_to_area_scene(SceneId, CopyId, X, Y, BinData)
	end.

%% 使用主动技能
skill(Aer, Der, Skill, X, Y, NowTime) ->
	%% 主动技能或者副技能才处理
	case Skill#player_skill.type == 1 orelse Skill#player_skill.type == 4 of
		true ->
			%% 处理技能与天赋技能影响(策划未定要)
			% {SkillTalentR, TalentDatas, _Tids} = calc_skill_talent(Skill#player_skill.skill_link, Skill, [], Aer, []),
			TalentDatas = [],
            %% test
            %case Aer#battle_status.sign == 1 of
            %    true -> skip;
            %    false -> skip
            %        io:format("SkillId, ~p, mod ~p data = ~p~n hp=~p, action=~p~n", 
            %            [SkillR#player_skill.skill_id, SkillR#player_skill.mod, SkillR#player_skill.data, 
            %                Aer#battle_status.hp, Aer#battle_status.act])
            %end,

			%% cd大于15秒的回写
			skill_cd_mark(Skill, Aer, NowTime),

			%% 加入施法状态(施法状态为0 或者 副技能不写入施法状态)
			Aer2 = case Skill#player_skill.status > 0 andalso Skill#player_skill.type /= 4 of
				true -> Aer#battle_status{skill_status = {Skill#player_skill.status, Skill#player_skill.use_time + NowTime - 500}};
				_ -> Aer
			end,

			Result = if
				Skill#player_skill.mod == 2 orelse Skill#player_skill.mod == 3 orelse Skill#player_skill.mod == 4 ->
					%% 群攻
					double_active_skill(Aer2, Der, Skill, TalentDatas, X, Y, NowTime);
				true ->
					%% 单体攻击
					single_active_skill(Aer2, Der, Skill, TalentDatas, NowTime)
			end,
			case Result of
				{true, AerAfBattle, DefList} -> 
					send_active_msg(AerAfBattle, DefList, X, Y, Skill#player_skill.skill_id, Skill#player_skill.lv),

					%% 释放后续的副技能
					combo_skill(Skill#player_skill.combo_skill, Aer, Der, Skill#player_skill.lv, X, Y),
					{true, AerAfBattle};
				{false, Error, LastAer} -> 
					 {false, Error, LastAer}
			 end;

		%% 技能出错
		_ ->
			% util:errlog("mod_battle skill, id=~p,type=~p~n",[Skill#player_skill.skill_id, Skill#player_skill.type]),
			{false, 6, Aer}
	end.

%% 释放副技能
%% ComboSkillList : 副技能[{延迟毫秒数, 技能id}, ...]
combo_skill([], _Aer, _Der, _SkillLv, _LineX, _LineY) -> ok;
combo_skill(ComboSkillList, Aer, Der, SkillLv, LineX, LineY) -> 
	[{Time, SkillId} | T] = ComboSkillList,
	AttKey  = [Aer#battle_status.id, Aer#battle_status.platform, Aer#battle_status.server_num],
	DefKey  = [Der#battle_status.id, Der#battle_status.platform, Der#battle_status.server_num],
	DefSign = Der#battle_status.sign,
	Msg = {'combo_skill', AttKey, DefKey, DefSign, SkillId, SkillLv, LineX, LineY, T},
	spawn(fun() -> 
		timer:sleep(Time),
		rpc_cast_to_node(Aer#battle_status.node, erlang, send, [Aer#battle_status.sid, Msg])
	end).

%% 是否可以采集
is_can_collect(Player, Mon) -> 
    Aer = init_data(Player),
    Der = init_data(Mon),
    if
        Aer#battle_status.pk_status == 7 -> 5;
        Mon#ets_mon.mid == 40421 orelse Mon#ets_mon.mid == 40461 orelse Mon#ets_mon.mid == 40471 -> 
            case Aer#battle_status.group == Der#battle_status.group of  %% 如果是炮塔，相同阵营才能采集
                true -> true;
                false -> 5
            end;
        Mon#ets_mon.mid == 12006 -> % 竞技场宝箱只有同分组的玩家才能拾取
            case Aer#battle_status.group =:= Der#battle_status.group of 
                true -> true;
                false -> 10
            end;
        %% 分组相同不能采集
        Aer#battle_status.group > 0 andalso Der#battle_status.group > 0 andalso Aer#battle_status.group =:=  Der#battle_status.group -> 
            false;
        true -> true
    end.

%% 群攻
double_active_skill(Aer, Der, SkillR, TalentDatas, LineX, LineY, NowTime) ->
	%% 计算技能持续效果
	AerAfterEffect  = calc_aer_last_effect(Aer#battle_status.battle_status, Aer, NowTime, Aer),
	LvData = SkillR#player_skill.data,
    #skill_lv_data{area = Area, att_num = AttNum, data = Data} = LvData,
    #battle_status{x = OldAerX, y = OldAerY} = Aer,
   % {ArgX, ArgY} = if
   %     SkillR#player_skill.aoe_mod == 3 andalso LineX /= 0 -> {LineX, LineY};     %% x,y区域选怪攻击
   %     SkillR#player_skill.aoe_mod == 2 andalso LineX /= 0 -> {OldAerX, OldAerY}; %% 直线选取怪物攻击
   %     SkillR#player_skill.obj > 1 -> {Der#battle_status.x, Der#battle_status.y}; %% 普通选取
   %     true ->  {OldAerX, OldAerY}
   % end,

	%% 群攻召唤
	DelAMData = case lists:keyfind(call_mon, 1, Data) of
		false -> Data;
		{_, AddMonList} -> 
			[_, _, ArgsList, _] = AddMonList,
			spawn(fun() -> call_mon(ArgsList, Aer, Aer, Der) end),
			lists:keydelete(call_mon, 1, Data)
	end,

	%% 群攻范围内选取攻击对象
	AllUser = if
		SkillR#player_skill.aoe_mod == 2 andalso LineX /= 0-> %% 直线范围选取 
			get_line_user_for_battle(Aer#battle_status.copy_id, LineX, LineY, OldAerX, OldAerY, Area, Aer#battle_status.group);
		SkillR#player_skill.aoe_mod == 3 andalso LineX /= 0-> %% 群攻定点矩形范围选取
			get_user_for_battle(Aer#battle_status.copy_id, LineX, LineY, Area, Aer#battle_status.group);
		true -> %% 群攻目标矩形范围选取
			get_user_for_battle(Der#battle_status.copy_id, Der#battle_status.x, Der#battle_status.y, Area, Aer#battle_status.group)
	end,

	%% 有阵营属性的怪物会攻击不同阵营的怪物，无阵营属性的怪物不会攻击其他怪物
	AllMon = case Aer#battle_status.sign == 2 orelse Aer#battle_status.group > 0 of
		true ->
			if 
				SkillR#player_skill.aoe_mod == 2 andalso LineX /= 0 -> %% 直线范围选取 
					get_line_mon_for_battle(Aer#battle_status.scene, Aer#battle_status.copy_id, LineX, LineY, OldAerX, OldAerY, Area, Aer#battle_status.group);
				SkillR#player_skill.aoe_mod == 3 andalso LineX /= 0 -> %% 群攻定点矩形范围选取
					get_mon_for_battle(Aer#battle_status.scene, Aer#battle_status.copy_id, LineX, LineY, Area, Aer#battle_status.group);
				true -> %% 群攻目标矩形范围选取
					get_mon_for_battle(Der#battle_status.scene, Der#battle_status.copy_id, Der#battle_status.x, Der#battle_status.y, Area, Aer#battle_status.group)
			end;
		false ->
			[]
	end,

    AfDelAMSkillR        = SkillR#player_skill{data = LvData#skill_lv_data{data=DelAMData}},
	AfDoubleAttHandleAer = AerAfterEffect#battle_status{ex_battle_status=[]}, %% 群攻不执行宠物主动技能

	%% 群攻
	F = fun(DerInit, {AerMd, DList}) ->
		{AerAfCoreB, DListAfCoreB} = do_core_battle(AfDoubleAttHandleAer, DerInit, AfDelAMSkillR, TalentDatas, NowTime),

		%% 可继承的属性
		AerMdAfCoreB = AerMd#battle_status{
            hp            = AerAfCoreB#battle_status.hp,
			effect_list   = AerMd#battle_status.effect_list ++ AerAfCoreB#battle_status.effect_list,
			battle_status = AerAfCoreB#battle_status.battle_status,
			x             = AerAfCoreB#battle_status.x,
			y             = AerAfCoreB#battle_status.y
		},
		{AerMdAfCoreB,  DListAfCoreB++DList}
	end,

	%% 可攻击对象过滤
	F2 = fun(ESU) -> 
		CanAttDer = init_data(ESU),
		if
			(Aer#battle_status.id        == CanAttDer#battle_status.id          andalso 
			Aer#battle_status.sign       == CanAttDer#battle_status.sign        andalso 
			Aer#battle_status.platform   == CanAttDer#battle_status.platform    andalso 
            Aer#battle_status.server_num == CanAttDer#battle_status.server_num) orelse (
            Der#battle_status.id         == CanAttDer#battle_status.id          andalso 
			Der#battle_status.sign       == CanAttDer#battle_status.sign        andalso 
			Der#battle_status.platform   == CanAttDer#battle_status.platform    andalso 
			Der#battle_status.server_num == CanAttDer#battle_status.server_num)  ->
				[];
			true ->
				case check_pk_status(Aer, CanAttDer) of
                    true  -> [CanAttDer];
					false -> []
				end
		end
	end,

    %% 距离排序
    %F3 = fun(#battle_status{x=X1, y=Y1}, #battle_status{x=X2, y=Y2}) -> 
    %        abs(X1 - OldAerX) + abs(Y1 - OldAerY) =< abs(X2 - OldAerX) + abs(Y2 - OldAerY)
    %end,
    %% 根据pk条件过滤(DListAll = [#battle_status{}, #battle_status{}...])
    %% 优先处理选中的防守者
    CountDer = case 
        Der#battle_status.id         == 0                             orelse ( 
        Aer#battle_status.id         == Der#battle_status.id          andalso 
        Aer#battle_status.sign       == Der#battle_status.sign        andalso 
        Aer#battle_status.platform   == Der#battle_status.platform)   of
        true -> [];
        false  -> 
            case check_pk_status(Aer, Der) of
                true  -> [Der];
                false -> []
            end
    end,
    DListAll   = CountDer ++ lists:flatmap(F2, AllUser) ++ lists:flatmap(F2, AllMon),
	DerListLen = length(DListAll),
    %% 选取攻击个数
	DListSub6 = if
		DerListLen == 0 -> [];
        AttNum == 0     -> DListAll;
		true            -> lists:sublist(DListAll, 1, AttNum)
	end,
	{NewAer, NewDList} = lists:foldl(F, {AerAfterEffect, []}, DListSub6),

	%% 计算反弹伤害
	ABuffList = lib_skill_buff:pack_buff(NewAer#battle_status.battle_status, NowTime, []),
	{true, NewAer#battle_status{buff_list = ABuffList}, NewDList}.

%% 单体攻击
single_active_skill(Aer, Der, SkillR, TalentDatas, NowTime) ->
	case Aer#battle_status.id == Der#battle_status.id            andalso 
		Aer#battle_status.sign == Der#battle_status.sign         andalso
		Aer#battle_status.platform == Der#battle_status.platform andalso 
		Aer#battle_status.server_num == Der#battle_status.server_num of
		true -> %% 攻击自己   
			{false, 9, Aer};
		false ->
			case check_pk_status(Aer, Der) of
				true ->
					%% 持续效果
					AerAfLastEffct = calc_aer_last_effect(Aer#battle_status.battle_status, Aer, NowTime, Aer),
					% DerAfLastEffct = calc_der_last_effect(Der#battle_status.battle_status, Der, NowTime, Der),

					%% 宠物技能效果
					% [AerEx, DerEx] = cale_ex_effect(AerAfLastEffct#battle_status.ex_battle_status, AerAfLastEffct, DerAfLastEffct, AerAfLastEffct#battle_status.battle_status, DerAfLastEffct#battle_status.battle_status, NowTime),

					%% 计算技能效果
					{AerAfCoreB, DListAfCoreB} = do_core_battle(AerAfLastEffct, Der, SkillR, TalentDatas, NowTime),
					BuffList = lib_skill_buff:pack_buff(AerAfCoreB#battle_status.battle_status, NowTime, []),
					{true, AerAfCoreB#battle_status{buff_list = BuffList}, DListAfCoreB};
				false ->
					{false, 28, Aer}
			end
	end.

%% 群攻辅助
double_assist_skill(Aer, _User, SkillData, TalentDatas, NowTime) ->
    SkillLvData = SkillData#player_skill.data,
    #skill_lv_data{area = Area} = SkillLvData,

	F = fun(User) ->
			UserLE  = calc_der_last_effect(User#battle_status.battle_status, User, NowTime, User),

			%% 处理技能buff
			UserAE = calc_assist_effect(SkillLvData#skill_lv_data.data, UserLE, NowTime, SkillData#player_skill.skill_id, SkillData#player_skill.lv, SkillData#player_skill.stack),
			UserTE = calc_talent_assist_last_effect(TalentDatas, UserAE, NowTime),
			%% 更新战斗状态
            case User#battle_status.sign == 2 of
                true -> assister_update_scene_info(UserTE);
                false -> skip
            end,
            send_to_node_pid(User#battle_status.node, User#battle_status.sid,  {'BATTLE_STATUS', UserTE#battle_status.battle_status}),
			%% 打包buff列表
            DBuffList = lib_skill_buff:pack_buff(UserTE#battle_status.battle_status, NowTime, []),
            [UserTE#battle_status.sign, UserTE#battle_status.id, UserTE#battle_status.platform, UserTE#battle_status.server_num, UserTE#battle_status.hp, DBuffList, UserTE#battle_status.effect_list]
	end,
	%% 获取释放辅助技能时的收益列表
	AssistMemberList = if
		is_pid(Aer#battle_status.pid_team) orelse Aer#battle_status.sign == 1 orelse Aer#battle_status.kf_teamid /= 0 ->
			L = lib_scene_agent:get_scene_user_for_assist(Aer#battle_status.copy_id, Aer#battle_status.x, Aer#battle_status.y, Area, Aer#battle_status.pid_team, Aer#battle_status.kf_teamid, Aer#battle_status.group, Aer#battle_status.sign),
			[F(init_data(D)) || D <- L];
		true ->
			[F(Aer)]
	end,
	send_assist_msg(Aer#battle_status.sign, Aer#battle_status.id, Aer#battle_status.platform, Aer#battle_status.server_num, SkillData#player_skill.skill_id, SkillData#player_skill.lv, Aer#battle_status.mp, Aer#battle_status.act, AssistMemberList, Aer#battle_status.scene, Aer#battle_status.copy_id, Aer#battle_status.x, Aer#battle_status.y).

%% 单体辅助
single_assist_skill(Aer, User, SkillData, TalentDatas, NowTime) -> 
	UserLE  = calc_der_last_effect(User#battle_status.battle_status, User, NowTime, User),
    SkillLvData  = SkillData#player_skill.data,

	%% 处理技能buff
	UserAE = calc_assist_effect(SkillLvData#skill_lv_data.data, UserLE, NowTime, SkillData#player_skill.skill_id, SkillData#player_skill.lv, SkillData#player_skill.stack),
    UserTE = calc_talent_assist_last_effect(TalentDatas, UserAE, NowTime),
    %% 更新战斗状态
    case User#battle_status.sign == 2 of
        true  -> assister_update_scene_info(UserTE);
        false -> skip
    end,
    send_to_node_pid(User#battle_status.node, User#battle_status.sid, {'BATTLE_STATUS', UserTE#battle_status.battle_status}),
	%% 打包buff列表
	DBuffList = lib_skill_buff:pack_buff(UserTE#battle_status.battle_status, NowTime, []),
	AssList   = [[UserTE#battle_status.sign, UserTE#battle_status.id, UserTE#battle_status.platform, UserTE#battle_status.server_num, UserTE#battle_status.hp, DBuffList, UserTE#battle_status.effect_list]],
	%% 发消息
	send_assist_msg(Aer#battle_status.sign, Aer#battle_status.id, Aer#battle_status.platform, Aer#battle_status.server_num, SkillData#player_skill.skill_id, SkillData#player_skill.lv, Aer#battle_status.mp, Aer#battle_status.act, AssList, User#battle_status.scene, User#battle_status.copy_id, User#battle_status.x, User#battle_status.y).

%% 战斗核心计算
do_core_battle(Aer, Der, SkillR, TalentDatas, NowTime) -> 
	%% 计算技能效果
	DerAfLastEffect = calc_der_last_effect(Der#battle_status.battle_status, Der, NowTime, Der),

	%% 计算主动技能
	{AerAfSkill, DerAfSkill} = case SkillR of
		[] ->
			{Aer, DerAfLastEffect};
		_ ->
            Data = SkillR#player_skill.data#skill_lv_data.data,
			%% 天赋点
			{AerAfTalent, DerAfTalent}    = calc_talent_active_effect(TalentDatas, Aer, DerAfLastEffect, NowTime, Aer, DerAfLastEffect),

			%% 技能本体
			{AerAfActive, DerAfActive}    = calc_active_effect(Data, AerAfTalent, DerAfTalent, AerAfTalent#battle_status.battle_status, DerAfTalent#battle_status.battle_status, NowTime, SkillR#player_skill.skill_id, SkillR#player_skill.lv, SkillR#player_skill.stack, AerAfTalent, DerAfTalent),
			%% @case_return
			{AerAfActive, DerAfActive}
	end,

    %% 根据职业选择防御
    RightDefValue = select_def_by_career(AerAfSkill#battle_status.career, DerAfSkill, SkillR#player_skill.skill_id),

	%% 计算伤害
	[Hpb, Hurt, HurtType, Shieldb] = calc_hurt(
		%% 攻击方
		AerAfSkill#battle_status.att, 
		AerAfSkill#battle_status.hit, 
		AerAfSkill#battle_status.crit,
		AerAfSkill#battle_status.hp, 
		AerAfSkill#battle_status.hurt_list,
        AerAfSkill#battle_status.restriction,
        AerAfSkill#battle_status.hurt_add_num,
        AerAfSkill#battle_status.sign,
        AerAfSkill#battle_status.career,

		%% 防守方
		RightDefValue, 
		DerAfSkill#battle_status.dodge,
		DerAfSkill#battle_status.ten, 
		DerAfSkill#battle_status.hp,
        DerAfSkill#battle_status.mp, 
		DerAfSkill#battle_status.shield, 
		DerAfSkill#battle_status.hurt_del_list, 
		DerAfSkill#battle_status.immune_hurt,
        DerAfSkill#battle_status.restriction,
		DerAfSkill#battle_status.hurt_del_num,
		DerAfSkill#battle_status.sign,
        DerAfSkill#battle_status.career,
        DerAfSkill#battle_status.kind,
        DerAfSkill#battle_status.del_hp_each_time,

		%% 技能属性
		SkillR#player_skill.is_calc_hurt
	),

	%% 其他自定义战斗参数
	%% 判断此攻击者是否有继承了父类属性，如果有，等同父类攻击了防守者
	[RetrunAtter, RetrunSign] = 
	case AerAfSkill#battle_status.skill_owner of
		[] -> 
			[
				#battle_return_atter{
					id          = AerAfSkill#battle_status.id,         
					platform    = AerAfSkill#battle_status.platform,  
					server_num  = AerAfSkill#battle_status.server_num, 
					node        = AerAfSkill#battle_status.node,    
					mid         = AerAfSkill#battle_status.mid,       
					pid         = AerAfSkill#battle_status.sid,     
					name        = AerAfSkill#battle_status.name,      
					pid_team    = AerAfSkill#battle_status.pid_team,
					att_time    = NowTime,
					guild_id    = AerAfSkill#battle_status.guild_id
				},
				AerAfSkill#battle_status.sign
			];
		{OwnerId, OwnerPlatform, OwnerServerNum, OwnerPid, OwnerNode, OwnerTeamPid, OwnerName, OwnerSign} -> %% 父类属性
			[
				#battle_return_atter{
					id          = OwnerId,         
					platform    = OwnerPlatform,  
					server_num  = OwnerServerNum, 
					node        = OwnerNode,
					mid         = AerAfSkill#battle_status.mid,       
					pid         = OwnerPid, 
					name        = OwnerName,      
					pid_team    = OwnerTeamPid,
					att_time    = NowTime,
					guild_id    = AerAfSkill#battle_status.guild_id
				},
				OwnerSign
			]
	end,

	BattleReturn = #battle_return{ 
		hp          = Hpb,
		%anger       = DerAfSkill#battle_status.anger,
		hurt        = Hurt,
		x           = DerAfSkill#battle_status.x,
		y           = DerAfSkill#battle_status.y,
		shield      = Shieldb,
		battle_status = DerAfSkill#battle_status.battle_status,
		hate        = AerAfSkill#battle_status.hate,
		sign        = RetrunSign,
		is_calc_hurt= SkillR#player_skill.is_calc_hurt,
		atter       = RetrunAtter
	},

	%% 更新防守方数据
	if
		is_pid(DerAfSkill#battle_status.sid) == false -> skip;
		DerAfSkill#battle_status.sign == 2 -> %% 防守方是玩家
			der_update_scene_info(DerAfSkill, BattleReturn, RetrunAtter);
		true -> %% 防守方是怪物
			send_to_node_pid(DerAfSkill#battle_status.node, DerAfSkill#battle_status.sid, {'battle_info', BattleReturn})
	end,
	DBuffList = lib_skill_buff:pack_buff(DerAfSkill#battle_status.battle_status, NowTime, []),

    %% 计算反弹和吸血效果
    AerAfFtsh      = calc_ftsh(AerAfSkill, DerAfSkill#battle_status.ftsh, Hurt),
    AerAfSuckBlood = calc_suck_blood(AerAfFtsh, AerAfSkill#battle_status.suck_blood, Hurt),
	LastAer        = AerAfSuckBlood,

	LastDList = [[DerAfSkill#battle_status.sign, DerAfSkill#battle_status.id, DerAfSkill#battle_status.platform, DerAfSkill#battle_status.server_num, Hpb, DerAfSkill#battle_status.mp, Hurt, HurtType, DerAfSkill#battle_status.move_x, DerAfSkill#battle_status.move_y, DBuffList, DerAfSkill#battle_status.effect_list]],
	{LastAer, LastDList}.

%%计算伤害
%%Att[攻击], Def[防御], Hit[命中], Der[防御], Crit[暴击], Ten[坚韧]
%%HurtType (0正常减血，1躲避，2暴击，3抵消, 4反弹，5免疫)
calc_hurt(
	%% 攻击方属性
	AttA, HitA, CritA, _HpA, HurtListA, RestrictionA, HurtAddNumA, SignA, CareerA,
	%% 防守方属性
	DefD, DodgeD, TenD,  HpD, _MpD, ShieldD, HurtDelListD, ImmuneHurtD, RestrictionD, HurtDelNumD, SignD, CareerD, KindD, DelHpEachTime,
	%% 技能属性
	IsCalcHurt
)->
    if
        DelHpEachTime > 0 andalso is_integer(DelHpEachTime) -> 
            [HpD, DelHpEachTime, 0, ShieldD];
        ImmuneHurtD == 1 -> %% 直接免疫这次伤害
            [HpD, 1, 5, ShieldD];
        IsCalcHurt == 0 -> %% 不算这次伤害
            [HpD, 0, 6, ShieldD];
        true ->
            % 下面公式中，分母多出来的+1是为了避免程序错误 
            % 命中率的公式=0.25+自己的命中/（自己的命中+对方躲闪）
            HitR = if
                CareerA == 2 -> 1.2;
                true -> 1
            end,
            Hit0 = (0.25 + HitA / (HitA + DodgeD+1)*HitR),
            Hit = min(1, Hit0),
            %Status : (0普通攻击,1躲避,3暴击)
            {HurtAfHit, HurtTypeAfHit} = if
                %% 针对特殊怪物类型的特殊伤害处理
                KindD == 10 -> {1, 0};
                KindD == 7  -> {0, 0};
                KindD == 11 -> {0, 0};
                true -> 
                    case util:rand(1,1000) > Hit * 1000 of
                        false -> % 命中
                            % 伤害的公式=自己的攻击^2/(自己的攻击+对方防御)*伤害系数*(1+技能伤害加成比例-技能伤害减少比例)+技能固定伤害
                            AttR = if
                                SignD   == 1                      -> 1;    %% 怪物是防守方
                                CareerD == 1 andalso CareerA == 2 -> 0.95; %% 天尊攻击神将
                                CareerD == 1 andalso CareerA == 3 -> 0.97; %% 罗刹攻击神将
                                CareerD == 2 andalso CareerA == 3 -> 0.95; %% 罗刹攻击天尊
                                true -> 1
                            end,
                            AttR1 = if
                                %% 玩家攻击玩家 伤害加深和减免系数才有用
                                SignD == 2 andalso SignA == 2 -> AttR + HurtAddNumA/1000 - HurtDelNumD/1000;
                                true -> AttR
                            end,
                            %% 阴阳属性
                            RestrictionRatio = if
                                RestrictionA /= 0 andalso RestrictionD /= 0 andalso RestrictionA /= RestrictionD -> 1.5;
                                true -> 1
                            end,

                            AttMd = (AttA*AttA) / (AttA + DefD+1)*AttR1*RestrictionRatio, %% 人物攻击

                            Att   = calc_hurt_list(HurtListA ++ HurtDelListD, AttMd, AttMd),

                            % 是否暴击
                            % 暴击率的公式=自己的暴击/(自己的暴击+对方坚韧)
                            Crit = CritA/(CritA + TenD+1),
                            %% 伤害浮动102% - 98%
                            RandHurtR = (util:rand(-20, 20) + 1000)/1000,
                            case util:rand(1,1000) > Crit * 1000 of
                                true -> % 没暴击
                                    {round(Att*RandHurtR), 0};
                                false ->
                                    {round(Att*2.0*RandHurtR), 2}
                            end;
                        true -> % miss
                            {0, 1}
                    end
            end,
			Hurt = max(1, HurtAfHit),
			%% 吸收伤害
			{HurtAfShield, Shield, HurtTypeAfShield} = case ShieldD > 0 of
				true  ->
					if
						Hurt > ShieldD -> {Hurt - ShieldD, 0, HurtTypeAfHit};
						true           -> {0, ShieldD - Hurt, 3}
					end;
				false -> {Hurt, 0, HurtTypeAfHit}
			end,
			case HurtAfShield > 0 of
				true ->
					HpbAfHurt = HpD -  HurtAfShield,
					LastHpD = case HpbAfHurt =< 0 of
						true  -> 0; %死亡状态
						false -> HpbAfHurt
					end,
					[LastHpD, HurtAfShield, HurtTypeAfShield, Shield];
				false ->
					[HpD, Hurt, HurtTypeAfShield, Shield]
			end
	end.

%% 计算增加或者防御伤害列表数值
calc_hurt_list([], Att, _) ->
   case  Att < 1 of
	   true -> 1;
	   false -> Att
   end;
calc_hurt_list([H|T], Att, OldAtt) -> 
	AttAdd = case is_float(H) of
		true  -> Att * H;
		false -> H
	end,
	calc_hurt_list(T, Att + AttAdd, OldAtt).

%%获取群攻范围内的玩家
get_user_for_battle(CopyId, X, Y, Area, Group) ->
	lib_scene_agent:get_scene_user_for_battle(CopyId, X, Y, Area, Group).

%% 获取直线范围内玩家
get_line_user_for_battle(CopyId, OX, OY, X, Y, Area, Group) -> 
	K = case OX - X == 0 of
		true -> 0;
		false -> (OY - Y) / (OX - X)
	end,
	B = -1*(K*X-Y),
	lib_scene_agent:get_line_user_for_battle(CopyId, OX, OY, X, Y, Area, K, B, Group).

%%获取群攻范围内的怪物
get_mon_for_battle(Q, CopyId, X, Y, Area, Group) ->
	lib_mon:get_mon_for_battle(Q, CopyId, X, Y, Area, Group).

%% 获取直线范围内的怪物
get_line_mon_for_battle(Q, CopyId, OX, OY, X, Y, Area, Group) -> 
	K = case OX - X == 0 of
		true -> 0;
		false -> (OY - Y) / (OX - X)
	end,
	B = -1*(K*X-Y),
	lib_mon:get_line_mon_for_battle(Q, CopyId, OX, OY, X, Y, Area, K, B, Group).

%% 主动技能天赋效果
calc_talent_active_effect([], Aer, Der, _NowTime, _OldAer, _OldDer) -> {Aer, Der};
calc_talent_active_effect([{Tid, TLv, TEff, Stack} | T], Aer, Der, NowTime,  OldAer, OldDer) ->
	{Aer1, Der1} = calc_active_effect(TEff, Aer, Der, Aer#battle_status.battle_status, Der#battle_status.battle_status, NowTime, Tid, TLv, Stack, OldAer, OldDer),
	calc_talent_active_effect(T, Aer1, Der1, NowTime, OldAer, OldDer).

%% 主动技能基础属性加成通用处理
calc_active_skill_base_attr_value(N, K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer) -> 
	[PerMil, AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] = D,

	case PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil of
		true -> 
			{User, SU, OldUser} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer),
            case check_skill_effect_condition(EffectCondition, User, NowTime, true) of
                false -> {Aer, SA, Der, SD};
                true  -> 
                    %% 增加持续buff
                    case LastTime > 0 of
                        true -> 
                            {NewSU, NewEff} = calc_buff_swap(K, [Int, Float], LastTime, SU, NowTime, SkillId, SkillLv, Stack, EffectId),
                            NewUser = set_effect_list(User, NewEff);
                        false -> 
                            NewV     = value_cate(Int, Float, element(N, User), element(N, OldUser)),
                            NewUser  = set_effect_list(setelement(N, User, NewV), {EffectId, 0, 0}),
                            NewSU    = SU
                    end,
                    set_affected_parties(AffectedParties, Aer, SA, Der, SD, NewUser, NewSU)
            end;
		false -> {Aer, SA, Der, SD}
	end.

%% 异常状态buff替换/添加
calc_active_skill_abnormality(K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv) -> 
	[PerMil, AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] = D,
	case PerMil == 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil of
		true -> 
			{User, SU, _} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, 0, 0),
            case check_skill_effect_condition(EffectCondition, User, NowTime, true) of
                false -> {Aer, SA, Der, SD};
                true  -> 
                    %% 增加持续buff
                    case is_can_set_abnormality(K, User) of
                        true -> 
                            case LastTime > 0 of
                                true -> 
                                    {NewSU, NewEff} = calc_abnormality_buff_swap(K, [Int, Float], LastTime, SU, NowTime, SkillId, SkillLv, EffectId),
                                    SetEffectUser = set_effect_list(User, NewEff),
                                    NewUser  = interrupt_skill_status(K, SetEffectUser);
                                false -> 
                                    NewUser  = User,
                                    NewSU    = SU
                            end;
                        false -> 
                            NewUser  = User,
                            NewSU    = SU
                    end,
                    set_affected_parties(AffectedParties, Aer, SA, Der, SD, NewUser, NewSU)
            end;
		false -> {Aer, SA, Der, SD}
	end.

%% 异常状态buff替换/添加
calc_assist_skill_abnormality(K, D, User, SU, NowTime, SkillId, SkillLv) -> 
	[PerMil, _AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] = D,
	case PerMil == 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil of
		true -> 
			%% 增加持续buff
			case is_can_set_abnormality(K, User) of
				true -> 
                    %% 判断技能效果是否满足作用条件
                    case check_skill_effect_condition(EffectCondition, User, NowTime, true) of
                        false ->
                            NewUser  = User,
                            NewSU    = SU;
                        true  -> 
                            case LastTime > 0 of
                                true -> 
                                    {NewSU, NewEff} = calc_abnormality_buff_swap(K, [Int, Float], LastTime, SU, NowTime, SkillId, SkillLv, EffectId),
                                    SetEffectUser = set_effect_list(User, NewEff),
                                    NewUser  = interrupt_skill_status(K, SetEffectUser);
                                false -> 
                                    NewUser  = User,
                                    NewSU    = SU
                            end
                    end;
				false -> 
					NewUser  = User,
					NewSU    = SU
			end,
            {NewUser, NewSU};
		false -> {User, SU}
	end.

%% 根据作用方状态判断是否可以添加这个异常状态(K)
is_can_set_abnormality(K, User) -> 
	case K of
		yun  -> User#battle_status.immune_effect == 0 andalso User#battle_status.unyun == 0;   %% 晕
		cm   -> User#battle_status.immune_effect == 0 andalso User#battle_status.uncm  == 0;   %% 沉默
		fear -> User#battle_status.immune_effect == 0;   %% 恐惧
		pressure_point -> User#battle_status.parry == 0; %% 点穴
		_ -> true
	end.

calc_active_skill_abnormality(K, D, User, SU, NowTime, SkillId, SkillLv) -> 
	[PerMil, _AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] = D,
	case PerMil == 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil of
		true -> 
            case check_skill_effect_condition(EffectCondition, User, NowTime, true) of
                false -> {User, SU};
                true  -> 
                    %% 增加持续buff
                    case LastTime > 0 of
                        true -> 
                            {NewSU, NewEff} = calc_abnormality_buff_swap(K, [Int, Float], LastTime, SU, NowTime, SkillId, SkillLv, EffectId),
                            NewUser  = set_effect_list(User, NewEff);
                        false -> 
                            NewUser  = User,
                            NewSU    = SU
                    end,
                    {NewUser, NewSU}
            end;
		false -> {User, SU}
	end.

%% 获取作用方
%% AffectedParties : 1攻击方  2防守方
get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer) -> 
	case AffectedParties of
		1 -> {Aer, SA, OldAer};
		_ -> {Der, SD, OldDer}
	end.

%% 替换作用方的#battle_status{} 和 #battle_status.battle_status
%% AffectedParties : 1攻击方  2防守方
set_affected_parties(AffectedParties, Aer, SA, Der, SD, User, SU) -> 
	 case AffectedParties of
		1 -> {User, SU, Der, SD};
		_ -> {Aer, SA, User, SU}
	end.

%% 获取作用方 -> {参照方,_,_,作用方,_,_}
get_double_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer) -> 
	case AffectedParties of
		1 -> {Der, SD, OldDer, Aer, SA, OldAer}; %% 作用方是攻击方
		_ -> {Aer, SA, OldAer, Der, SD, OldDer}
	end.

%% 替换参照方和作用方的#battle_status{} 和 #battle_status.battle_status
set_double_affected_parties(AffectedParties, User, SU, Affecter, SF) -> 
	 case AffectedParties of
		1 -> {Affecter, SF, User, SU}; %% 作用方是攻击方
		_ -> {User, SU, Affecter, SF}
	end.

%% 设置特效列表，发送给客户端，显示特效
set_effect_list(User, []) -> User;
set_effect_list(User, {0, _, _}) -> User;
set_effect_list(User, {EffectId, LastTime, Value}) -> 
	OldEffList = User#battle_status.effect_list,
	User#battle_status{effect_list = [{EffectId, LastTime, Value} | OldEffList]}.

%% 主动技能效果
%% SA攻击方持续状态
%% SD防守方持续状态
calc_active_effect([] , Aer, Der, SA, SD, _Time, _SkillId, _SkillLv, _Stack, _OldAer, _OldDer) ->
	{Aer#battle_status{battle_status = SA}, Der#battle_status{battle_status = SD}};
calc_active_effect([{K, D} | T] , Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer) ->
	case K of
		att -> %% 攻击
			N = #battle_status.att,
			{NewAer, NewSA, NewDer, NewSD} = calc_active_skill_base_attr_value(N, K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer),
			calc_active_effect(T, NewAer, NewDer, NewSA, NewSD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		def -> %% 防御
			N = #battle_status.def,
			{NewAer, NewSA, NewDer, NewSD} = calc_active_skill_base_attr_value(N, K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer),
			calc_active_effect(T, NewAer, NewDer, NewSA, NewSD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		hit -> %% 命中
			N = #battle_status.hit,
			{NewAer, NewSA, NewDer, NewSD} = calc_active_skill_base_attr_value(N, K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer),
			calc_active_effect(T, NewAer, NewDer, NewSA, NewSD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		dodge -> %% 闪避
			N = #battle_status.dodge,
			{NewAer, NewSA, NewDer, NewSD} = calc_active_skill_base_attr_value(N, K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer),
			calc_active_effect(T, NewAer, NewDer, NewSA, NewSD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		crit -> %% 暴击率
			N = #battle_status.crit,
			{NewAer, NewSA, NewDer, NewSD} = calc_active_skill_base_attr_value(N, K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer),
			calc_active_effect(T, NewAer, NewDer, NewSA, NewSD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		ten -> %% 抗暴率
			N = #battle_status.ten,
			{NewAer, NewSA, NewDer, NewSD} = calc_active_skill_base_attr_value(N, K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer),
			calc_active_effect(T, NewAer, NewDer, NewSA, NewSD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
        fire_def -> %% 火抗，雷抗
            N = #battle_status.fire,
            {NewAer, NewSA, NewDer, NewSD} = calc_active_skill_base_attr_value(N, K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer),
            calc_active_effect(T, NewAer, NewDer, NewSA, NewSD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
        ice_def -> %% 冰抗，水抗
            N = #battle_status.ice,
            {NewAer, NewSA, NewDer, NewSD} = calc_active_skill_base_attr_value(N, K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer),
            calc_active_effect(T, NewAer, NewDer, NewSA, NewSD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
        drug_def -> %% 毒抗，冥抗
            N = #battle_status.drug,
            {NewAer, NewSA, NewDer, NewSD} = calc_active_skill_base_attr_value(N, K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer),
            calc_active_effect(T, NewAer, NewDer, NewSA, NewSD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		speed -> %% 速度
			[PerMil, AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] = D,
			case (
                    (Int > 0 orelse Float > 0) orelse AffectedParties == 1 orelse 
					(AffectedParties == 2 andalso Der#battle_status.immune_effect == 0)
				) 
                andalso (PerMil >= 1000 orelse util:rand(1, 1000) < PerMil) 
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
				false -> 
					calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				true ->
					{User, SU, _} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer),

					case swap_speed_buff(User#battle_status.speed, Int, Float, SU, NowTime) of
						false -> calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
						{true, NewSpeed} ->
							NewSU = [{speed, SkillId, {speed, SkillId}, SkillLv, 0, Int, Float, NowTime+LastTime} | SU], 
							lib_scene:change_speed(User#battle_status.id, User#battle_status.platform, User#battle_status.server_num, User#battle_status.scene, User#battle_status.copy_id, User#battle_status.x, User#battle_status.y, NewSpeed, User#battle_status.sign), %% 广播
							UserEL  = set_effect_list(User, {EffectId, LastTime, NewSpeed}),
							{AerEL, SAEL, DerEL, SDEL} = set_affected_parties(AffectedParties, Aer, SA, Der, SD, UserEL, NewSU),
							calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
					end 
			end;
		hurt -> %% 攻击伤害
			[PerMil, AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse util:rand(1, 1000) < PerMil) 
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
				false -> calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				true  -> 
					{User, SU, _} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer),
					case LastTime > 0 of
						true -> 
							{NewSU, NewEff} = calc_buff_swap(K, [Int, Float], LastTime, SU, NowTime, SkillId, SkillLv, Stack, EffectId),
							NewUser = set_effect_list(User, NewEff);
						false -> 
							NewUser = set_effect_list(User#battle_status{hurt_list = [Int, Float | User#battle_status.hurt_list]}, {EffectId, 0, 0}),
							NewSU   = SU
					end,
					{AerEL, SAEL, DerEL, SDEL} = set_affected_parties(AffectedParties, Aer, SA, Der, SD, NewUser, NewSU),
					calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
			end;
		hurt_del ->  %% 防御伤害
			[PerMil, AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse util:rand(1, 1000) < PerMil) 
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
				false -> calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				true  -> 
					{User, SU, _} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer),
					case LastTime > 0 of
						true -> 
							{NewSU, NewEff} = calc_buff_swap(K, [Int, Float], LastTime, SU, NowTime, SkillId, SkillLv, Stack, EffectId),
							NewUser = set_effect_list(User, NewEff);
						false -> 
							NewUser = set_effect_list(User#battle_status{hurt_del_list = [Int, Float | User#battle_status.hurt_del_list]}, {EffectId, 0, 0}),
							NewSU   = SU
					end,
					{AerEL, SAEL, DerEL, SDEL} = set_affected_parties(AffectedParties, Aer, SA, Der, SD, NewUser, NewSU),
					calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
			end;
		yun -> %% 晕
			{AerEL, SAEL, DerEL, SDEL} = calc_active_skill_abnormality(K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv),
			calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		cm -> %% 沉默
			{AerEL, SAEL, DerEL, SDEL} = calc_active_skill_abnormality(K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv),
			calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		shield -> %% 盾
            [PerMil, AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] = D,
            %% 要先对配置值进行计算
            NewD = [PerMil, AffectedParties, value_cate(Int, Float, 0, OldAer#battle_status.att), 0, LastTime, EffectId, EffectCondition],
			{AerEL, SAEL, DerEL, SDEL} = calc_active_skill_abnormality(K, NewD, Aer, Der, SA, SD, NowTime, SkillId, SkillLv),
			calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		immune_hurt -> %% 免疫伤害
			{AerEL, SAEL, DerEL, SDEL} = calc_active_skill_abnormality(K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv),
			calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		immune_effect -> %% 免疫特效
			{AerEL, SAEL, DerEL, SDEL} = calc_active_skill_abnormality(K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv),
			calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		fear -> %% 恐惧
			{AerEL, SAEL, DerEL, SDEL} = calc_active_skill_abnormality(K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv),
			calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		ftsh -> %% 反弹伤害
			{AerEL, SAEL, DerEL, SDEL} = calc_active_skill_abnormality(K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv),
			calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		pressure_point -> %% 点穴
			{AerEL, SAEL, DerEL, SDEL} = calc_active_skill_abnormality(K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv),
			calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		parry -> %% 格挡
			{AerEL, SAEL, DerEL, SDEL} = calc_active_skill_abnormality(K, D, Aer, Der, SA, SD, NowTime, SkillId, SkillLv),
			calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
		suck_blood -> %% 吸血
			[PerMil, AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil)
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
				true -> 
					{User, SU, _OldUser} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer),
					%% 增加持续buff
					case LastTime > 0 of
						true -> 
							{NewSU, _NewEff} = calc_abnormality_buff_swap(K, [Int, Float], LastTime, SU, NowTime, SkillId, SkillLv, EffectId),
							NewUser = User;
						false -> 
							NewUser  = User#battle_status{suck_blood = [Int, Float]},
							NewSU    = SU
					end,
					{AerEL, SAEL, DerEL, SDEL} = set_affected_parties(AffectedParties, Aer, SA, Der, SD, NewUser, NewSU),
					calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				false -> 
					calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
			end;

		add_blood -> %% 持续改变血量，数值=Int+作用方的血上限*float
			[PerMil, AffectedParties, Int, Float, [Count, GapTime], EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil) 
                andalso (
					(AffectedParties == 2 andalso Der#battle_status.immune_effect == 0 andalso Der#battle_status.parry == 0) orelse 
					AffectedParties  == 1
				) 
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
				true ->
					{User, SU, _OldUser} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer), 
					Data  = [Count, GapTime, Int, Float],
					_Pid  = spawn(fun() -> last_change_hp(User#battle_status.node, User#battle_status.sid, Data) end), 
					NewSU = [{K, SkillId, {K, SkillId}, SkillLv, 0, Int, Float, NowTime+Count*GapTime}|SU],
					UserEL= set_effect_list(User, {EffectId, Count*GapTime, 0}),
					{AerEL, SAEL, DerEL, SDEL} = set_affected_parties(AffectedParties, Aer, SA, Der, SD, UserEL, NewSU),
					calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				false -> 
					calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
			end;
        add_blood_ac_att -> %%  持续加血(血量根据人物攻击力)，数值=Int+攻击方的攻击力*float
			[PerMil, AffectedParties, OldInt, OldFloat, [Count, GapTime], EffectId, EffectCondition] = D,
            Int = value_cate(OldInt, OldFloat, 0, OldAer#battle_status.att),
            Float = 0,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil) andalso 
				(
					(AffectedParties == 2 andalso Der#battle_status.immune_effect == 0 andalso Der#battle_status.parry == 0) orelse 
					AffectedParties  == 1
				) 
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
				true ->
					{User, SU, _OldUser} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer), 
					Data  = [Count, GapTime, Int, Float],
					_Pid  = spawn(fun() -> last_change_hp(User#battle_status.node, User#battle_status.sid, Data) end), 
					NewSU = [{K, SkillId, {K, SkillId}, SkillLv, 0, Int, Float, NowTime+Count*GapTime}|SU],
					UserEL= set_effect_list(User, {EffectId, Count*GapTime, 0}),
					{AerEL, SAEL, DerEL, SDEL} = set_affected_parties(AffectedParties, Aer, SA, Der, SD, UserEL, NewSU),
					calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				false -> 
					calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
			end;
		drug -> % 加毒
			[PerMil, AffectedParties, Int, Float, [Count, GapTime], EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil) andalso 
				(
					(AffectedParties == 2 andalso Der#battle_status.immune_effect == 0 andalso Der#battle_status.parry == 0 andalso Der#battle_status.del_hp_each_time == 0) orelse 
					AffectedParties  == 1
				) 
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
				true ->
					{User, SU, _OldUser} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer), 
					Data  = [Count, GapTime, Int, Float],
					_Pid   = spawn(fun() -> last_change_hp(User#battle_status.node, User#battle_status.sid, Data) end), 
					NewSU = [{K, SkillId, {K, SkillId}, SkillLv, 0, Int, Float, NowTime+Count*GapTime}|SU],
					UserEL= set_effect_list(User, {EffectId, Count*GapTime, 0}),
					{AerEL, SAEL, DerEL, SDEL} = set_affected_parties(AffectedParties, Aer, SA, Der, SD, UserEL, NewSU),
					calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				false -> 
					calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
			end;

		blood -> % 流血
			[PerMil, AffectedParties, Int, Float, [Count, GapTime], EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil) andalso 
				(
					(AffectedParties == 2 andalso Der#battle_status.immune_effect == 0 andalso Der#battle_status.parry == 0 andalso Der#battle_status.del_hp_each_time == 0) orelse 
					AffectedParties  == 1
				) 
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
				true ->
					{User, SU, _OldUser} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer), 
					Data  = [Count, GapTime, Int, Float],
					_Pid   = spawn(fun() -> last_change_hp(User#battle_status.node, User#battle_status.sid, Data) end), 
					NewSU = [{K, SkillId, {K, SkillId}, SkillLv, 0, Int, Float, NowTime+Count*GapTime}|SU],
					UserEL= set_effect_list(User, {EffectId, Count*GapTime, 0}),
					{AerEL, SAEL, DerEL, SDEL} = set_affected_parties(AffectedParties, Aer, SA, Der, SD, UserEL, NewSU),
					calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				false -> 
					calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
			end;
	   
		hold -> %% 冲刺(向目标位置进行位移)
			[PerMil, AffectedParties, EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil) andalso
				(
					(AffectedParties == 2 andalso Der#battle_status.immune_effect == 0 andalso Der#battle_status.parry == 0) orelse 
					AffectedParties  == 1
				) 
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of 
				false -> calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				true -> 
					{User, SU, _OldUser, Affecter, SF, _OldAffecter} = get_double_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer), 
					UserOldX     = User#battle_status.x,
					UserOldY     = User#battle_status.y,
					AffecterOldX = Affecter#battle_status.x,
					AffecterOldY = Affecter#battle_status.y,

					X0 = if
						UserOldX > AffecterOldX -> UserOldX - 1; %% 目标在右面,移动到目标的左面(x-1)
						UserOldX < AffecterOldX -> UserOldX + 1; %% 目标在左面,移动到目标的右面(x+1)
						true                    -> UserOldX
					end,
					Y0 = if
						UserOldY > AffecterOldY -> UserOldY - 1; %% 目标在下面,移动到目标的上面(y-1)
						UserOldY < AffecterOldY -> UserOldY + 1; %% 目标在上面,移动到目标的下面(y+1)
						true                    -> UserOldY
					end,
					%判断是否障碍物
					[AffecterX, AffecterY] = case lib_scene:can_be_moved(Affecter#battle_status.scene, X0, Y0) of
						true  -> [UserOldX, UserOldY];
						false -> [X0, Y0]
					end,
					send_to_node_pid(Affecter#battle_status.node, Affecter#battle_status.sid, {xy, [AffecterX, AffecterY]}),
					NewAffecter = set_effect_list(Affecter#battle_status{x = AffecterX, y = AffecterY, move_x = AffecterX, move_y = AffecterY}, {EffectId, 0, 0}),
					{AerEL, SAEL, DerEL, SDEL} = set_double_affected_parties(AffectedParties, User, SU, NewAffecter, SF),
					calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
			end;

		back -> %% 击退(远离目标位置)
			%% [概率，作用方，击退距离(坐标距离)，特效配置id]
			[PerMil, AffectedParties, BackArea, EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil) andalso 
				(
					(AffectedParties == 2 andalso Der#battle_status.immune_effect == 0 andalso Der#battle_status.parry == 0 andalso Der#battle_status.unbeat_back == 0) orelse 
					AffectedParties  == 1
				) 
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of  
				false -> 
					calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				true ->
					{User, SU, _OldUser, Affecter, SF, _OldAffecter} = get_double_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer), 
					UserOldX     = User#battle_status.x,
					UserOldY     = User#battle_status.y,
					AffecterOldX = Affecter#battle_status.x,
					AffecterOldY = Affecter#battle_status.y,
					Angle       = math:atan2(AffecterOldY - UserOldY, AffecterOldX - UserOldX),
					if
						Angle /= 0 -> 
							X0 = round(AffecterOldX+BackArea*math:cos(Angle)),
							Y0 = round(AffecterOldY+BackArea*math:sin(Angle));
						AffecterOldY == UserOldY andalso AffecterOldX - UserOldX /= 0 -> %% Y轴相等
							X0 = round(AffecterOldX + BackArea * (AffecterOldX - UserOldX) div abs(AffecterOldX - UserOldX)),
							Y0 = AffecterOldY;
						AffecterOldX == UserOldX andalso AffecterOldY - UserOldY /= 0-> %% X轴相等
							Y0 = round(AffecterOldY + BackArea * (AffecterOldY - UserOldY) div abs(AffecterOldY - UserOldY)),
							X0 = AffecterOldX;
						true -> %% 其他情况 
							X0 = AffecterOldX + BackArea,
							Y0 = AffecterOldY
					end,
					%判断是否障碍物
					NewAffecter = case lib_scene:can_be_moved(Affecter#battle_status.scene, X0, Y0) of
						true  -> 
							Affecter;
						false -> 
							set_effect_list(Affecter#battle_status{x=X0, y=Y0, move_x=X0, move_y=Y0}, {EffectId, 0, 0})
					end,
					{AerEL, SAEL, DerEL, SDEL} = set_double_affected_parties(AffectedParties, User, SU, NewAffecter, SF),
					calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
			end;
        %% 按攻击方一定血量上限比例改变血量
        hp -> 
            [PerMil, AffectedParties, Int, Float, _LastTime, EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil)
               andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
                false -> 
					calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				true ->
                    if
                        AffectedParties == 1 -> %% 作用方自己
                            NewHp = value_cate(Int, Float, Aer#battle_status.hp, Aer#battle_status.hp_lim),
                            Hp    = min(Aer#battle_status.hp_lim, NewHp),
                            AerEL = Aer#battle_status{hp = Hp},
                            broadcast_hp(AerEL),
                            calc_active_effect(T, AerEL, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
                        true -> %% 作用方是别人
                            HpChange    = value_cate(Int, Float, 0, Aer#battle_status.hp_lim),
                            AerHurtList = Aer#battle_status{hurt_list=[abs(HpChange)|Aer#battle_status.hurt_list]},
                            AerEL       = set_effect_list(AerHurtList, {EffectId, 0, 0}),
                            calc_active_effect(T, AerEL, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
                    end
			end;

        %% 根据各自(攻击方/防守方)血上限影响血量
	    change_hp_ac_lim -> 
            [PerMil, AffectedParties, Int, Float, _LastTime, EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil)
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
                false -> 
					calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				true ->
                    if
                        AffectedParties == 1 -> %% 作用方自己
                            NewHp = value_cate(Int, Float, Aer#battle_status.hp, Aer#battle_status.hp_lim),
                            Hp    = min(Aer#battle_status.hp_lim, NewHp),
                            AerEL = Aer#battle_status{hp = Hp},
                            broadcast_hp(AerEL),
                            calc_active_effect(T, AerEL, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
                        true -> %% 作用方是别人
                            HpChange    = value_cate(Int, Float, 0, Der#battle_status.hp_lim),
                            AerHurtList = Aer#battle_status{hurt_list=[abs(HpChange)|Aer#battle_status.hurt_list]},
                            AerEL       = set_effect_list(AerHurtList, {EffectId, 0, 0}),
                            calc_active_effect(T, AerEL, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
                    end
			end;

		%% 变身
		change ->
			[PerMil, AffectedParties, FigureId, LastTime, EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil) andalso 
				(
					(AffectedParties == 2 andalso Der#battle_status.immune_effect == 0 andalso Der#battle_status.parry == 0) orelse 
					AffectedParties  == 1
				) 
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
				false -> 
					calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				true -> 
					{User, SU, _OldUser} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer), 
					change(User, FigureId, LastTime, SkillId),
					NewUser = set_effect_list(User, {EffectId, 0, 0}),
					{AerEL, SAEL, DerEL, SDEL} = set_affected_parties(AffectedParties, Aer, SA, Der, SD, NewUser, SU),
					calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
			end;

		%% 召唤怪物
		call_mon -> 
			[PerMil, AffectedParties, ArgsList, EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil)
                andalso check_skill_effect_condition(EffectCondition, OldAer, OldDer, NowTime, true) of
				true ->
					{User, SU, _OldUser} = get_affected_parties(AffectedParties, Aer, SA, Der, SD, OldAer, OldDer), 

					spawn(fun() -> call_mon(ArgsList, User, OldAer, Der) end),
					NewUser = set_effect_list(User, {EffectId, 0, 0}),
					{AerEL, SAEL, DerEL, SDEL} = set_affected_parties(AffectedParties, Aer, SA, Der, SD, NewUser, SU),
					calc_active_effect(T, AerEL, DerEL, SAEL, SDEL, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
				false -> 
					calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)   
			end;
        %% 增加仇恨
        hate -> 
            NewAer = Aer#battle_status{hate = D},
            calc_active_effect(T, NewAer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer);
	   _ ->
		   calc_active_effect(T, Aer, Der, SA, SD, NowTime, SkillId, SkillLv, Stack, OldAer, OldDer)
   end.

%% 持续辅助技能天赋效果
calc_talent_assist_last_effect([], User, _) -> User;
calc_talent_assist_last_effect([{Tid, TLv, TEff, Stack}|T], User, NowTime) -> 
	NewUser = calc_assist_effect(TEff, User, NowTime, Tid, TLv, Stack),
	calc_talent_assist_last_effect(T, NewUser, NowTime).

%% 玩家辅助技能
calc_assist_effect(SkillData, User, NowTime, SkillId, SkillLv, Stack) -> 
	NewUser = calc_assist_last_effect(SkillData, User#battle_status.battle_status, NowTime, SkillId, SkillLv, User, Stack),
	NewUser.

%% 持续性buff处理
calc_assist_last_effect([], SU, _NowTime, _SkillId, _SkillLv, User, _Stack) ->
	User#battle_status{battle_status = SU};
calc_assist_last_effect([{K, D}|T], SU, NowTime, SkillId, SkillLv, User, Stack) ->
	case K of
		speed ->  % 速度
			[PerMil, _AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] = D,
			case (PerMil == 0 orelse PerMil >= 1000 orelse util:rand(1, 1000) < PerMil)
                andalso check_skill_effect_condition(EffectCondition, User, NowTime, true) of
				false -> 
					calc_assist_last_effect(T, SU, NowTime, SkillId, SkillLv, User, Stack);
				true ->
					case swap_speed_buff(User#battle_status.speed, Int, Float, SU, NowTime) of
						false ->
							calc_assist_last_effect(T, SU, NowTime, SkillId, SkillLv, User, Stack);
						{true, NewSpeed} ->
							NewSU = [{speed, SkillId, {speed, SkillId}, SkillLv, 0, Int, Float, NowTime+LastTime}|SU], 
							%% 广播
							lib_scene:change_speed(User#battle_status.id, User#battle_status.platform, User#battle_status.server_num, User#battle_status.scene, User#battle_status.copy_id, User#battle_status.x, User#battle_status.y, NewSpeed, User#battle_status.sign),
							UserEL = set_effect_list(User, {EffectId, LastTime, NewSpeed}),
							calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, UserEL, Stack)
					end 
			end;

		% 眩晕
		yun ->  
			{NewUser, NewSU} = calc_assist_skill_abnormality(K, D, User, SU, NowTime, SkillId, SkillLv),
			calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, NewUser, Stack);

		%% 法盾
		shield -> 
            [PerMil, AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] = D,
            NewD = [PerMil, AffectedParties, value_cate(Int, Float, 0, User#battle_status.att), 0, LastTime, EffectId, EffectCondition],
			{NewUser, NewSU} = calc_assist_skill_abnormality(K, NewD, User, SU, NowTime, SkillId, SkillLv),
			calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, NewUser, Stack);

		%% 免疫特效
		immune_effect -> 
			{NewUser, NewSU} = calc_assist_skill_abnormality(K, D, User, SU, NowTime, SkillId, SkillLv),
			calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, NewUser, Stack);

		%% 免疫伤害
		immune_hurt ->
			{NewUser, NewSU} = calc_assist_skill_abnormality(K, D, User, SU, NowTime, SkillId, SkillLv),
			calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, NewUser, Stack);

		%% 沉默
		cm -> 
			{NewUser, NewSU} = calc_assist_skill_abnormality(K, D, User, SU, NowTime, SkillId, SkillLv),
			calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, NewUser, Stack);

		%% 恐惧
		fear -> 
			{NewUser, NewSU} = calc_assist_skill_abnormality(K, D, User, SU, NowTime, SkillId, SkillLv),
			calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, NewUser, Stack);

		%% 反弹伤害
		ftsh ->
			{NewUser, NewSU} = calc_assist_skill_abnormality(K, D, User, SU, NowTime, SkillId, SkillLv),
			calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, NewUser, Stack);

		%% 点穴
		pressure_point -> 
			{NewUser, NewSU} = calc_assist_skill_abnormality(K, D, User, SU, NowTime, SkillId, SkillLv),
			calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, NewUser, Stack);

		%% 格挡
		parry -> 
			{NewUser, NewSU} = calc_assist_skill_abnormality(K, D, User, SU, NowTime, SkillId, SkillLv),
			calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, NewUser, Stack);
		%% 持续加血
		add_blood -> 
			[PerMil, _AffectedParties, Int, Float, [Count, GapTime], EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil)
                andalso check_skill_effect_condition(EffectCondition, User, NowTime, true) of
				true ->
					Data  = [Count, GapTime, Int, Float],
					_Pid  = spawn(fun() -> last_change_hp(User#battle_status.node, User#battle_status.sid, Data) end), 
					NewSU = [{K, SkillId, {K, SkillId}, SkillLv, 0, Int, Float, NowTime+Count*GapTime}|SU],
					UserEL= set_effect_list(User, {EffectId, Count*GapTime, 0}),
					calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, UserEL, Stack);
				false -> 
					calc_assist_last_effect(T, SU, NowTime, SkillId, SkillLv, User, Stack)
			end;

		%% 召唤怪物
		call_mon ->
			[PerMil, _AffectedParties, ArgsList, EffectId, EffectCondition] = D,
			case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil) 
                andalso check_skill_effect_condition(EffectCondition, User, NowTime, true) of
				true ->
					spawn(fun() -> call_mon(ArgsList, User, User, []) end),
					UserEL = set_effect_list(User, {EffectId, 0, 0}),
					calc_assist_last_effect(T, SU, NowTime, SkillId, SkillLv, UserEL, Stack);
				false -> 
					calc_assist_last_effect(T, SU, NowTime, SkillId, SkillLv, User, Stack)
			end;

	   unfly -> 
		   OldEL    = User#battle_status.effect_list,
		   NewUser  = User#battle_status{effect_list = [{11, 2000, 0}|OldEL]},
		   calc_assist_last_effect(T, SU, NowTime, SkillId, SkillLv, NewUser, Stack);

		_ -> %% 其余是统一机制
			case D of
				[PerMil, _AffectedParties, Int, Float, LastTime, EffectId, EffectCondition] -> 
                    case (PerMil >= 1000 orelse PerMil == 0 orelse util:rand(1, 1000) < PerMil)
                        andalso check_skill_effect_condition(EffectCondition, User, NowTime, true) of
						true -> 
							{NewSU, NewEff} = calc_buff_swap(K, [Int, Float], LastTime, SU, NowTime, SkillId, SkillLv, Stack, EffectId),
							NewUser = set_effect_list(User, NewEff),
							calc_assist_last_effect(T, NewSU, NowTime, SkillId, SkillLv, NewUser, Stack);
						false -> 
							calc_assist_last_effect(T, SU, NowTime, SkillId, SkillLv, User, Stack)
					end;
				_ -> 
					calc_assist_last_effect(T, SU, NowTime, SkillId, SkillLv, User, Stack)
			end
	end.

%% 计算属性
value_cate(Int, Float, Sum, Base) -> 
	FloatValue = if
		Float /= 0 ->  Base * Float;
		true ->  0
	end,
	MSum = round(Sum + FloatValue + Int),
	case MSum < 1 of
		true  -> 1;
		false -> MSum
	end.

%% 判断攻击距离
check_distance([Distance, X1, Y1], [X2, Y2]) -> 
	case Distance + 2 >= abs(X1 - X2) of %放宽一格的验证
		true ->
			case Distance * 1.5 + 2 >= abs(Y1 - Y2) of
				true -> true;
				false -> false
			end;
		false -> false
	end.

%% 计算攻击方持续效果 - 主要是加成效果
calc_aer_last_effect([] , Aer, _Time, _) -> Aer;
calc_aer_last_effect([{K, SkillId, _, _SkillLv, _Stack, Int, Float, T} | H] , Aer, Time, OldAer) ->
	case K of
		att -> %% 攻击
			case T > Time of
				true ->
					Att = value_cate(Int, Float, Aer#battle_status.att, OldAer#battle_status.att),
					Aer1 = Aer#battle_status{att = Att},
					calc_aer_last_effect(H , Aer1, Time, OldAer);
				false ->
					Aer1 = Aer#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Aer#battle_status.battle_status)},
					calc_aer_last_effect(H , Aer1, Time, OldAer)
			end;
		hit -> %% 命中
			case T > Time of
				true ->
					Hit = value_cate(Int, Float, Aer#battle_status.hit, OldAer#battle_status.hit),
					Aer1 = Aer#battle_status{hit = Hit},
					calc_aer_last_effect(H , Aer1, Time, OldAer);
				false ->
					Aer1 = Aer#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Aer#battle_status.battle_status)},
					calc_aer_last_effect(H , Aer1, Time, OldAer)
			end;
		crit -> %% 暴击
			case T > Time of
				true ->
					Crit = value_cate(Int, Float, Aer#battle_status.crit, OldAer#battle_status.crit),
					Aer1 = Aer#battle_status{crit = Crit},
					calc_aer_last_effect(H , Aer1, Time, OldAer);
				false ->
					Aer1 = Aer#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Aer#battle_status.battle_status)},
					calc_aer_last_effect(H , Aer1, Time, OldAer)
			end;
		hurt -> %% 加深伤害
			case T > Time of
				true ->
					Aer1 = Aer#battle_status{hurt_list = [Int, Float|Aer#battle_status.hurt_list]},
					calc_aer_last_effect(H , Aer1, Time, OldAer);
				false ->
					Aer1 = Aer#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Aer#battle_status.battle_status)},
					calc_aer_last_effect(H , Aer1, Time, OldAer)
			end;
		change -> %% 变身
			case T > Time of
				true -> 
					calc_aer_last_effect(H, Aer, Time, OldAer);
				false ->
					Aer1 = Aer#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Aer#battle_status.battle_status)},
					change(Aer, 0, 0, 0),
					calc_aer_last_effect(H, Aer1, Time, OldAer)
			end;
		_ ->
			case T > Time of
				true -> calc_aer_last_effect(H , Aer, Time, OldAer);
				false -> 
					Aer1 = Aer#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Aer#battle_status.battle_status)},
					calc_aer_last_effect(H, Aer1, Time, OldAer)
			end
	end.

%% 计算防守方持续效果 - 主要是抵御和被附加的效果
calc_der_last_effect([] , Der, _Time, _) -> Der;
calc_der_last_effect([{K, SkillId, _, _SkillLv, _Stack, Int, Float, T} | H] , Der, Time, OldDer) ->
	case K of
		def -> %% 防御
			case T > Time of
				true ->
					Value = value_cate(Int, Float, Der#battle_status.def, OldDer#battle_status.def),
					Der1 = Der#battle_status{def = Value},
					calc_der_last_effect(H , Der1, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H , Der1, Time, OldDer)
			end;
		dodge -> %% 闪避
			case T > Time of
				true ->
					Value = value_cate(Int, Float, Der#battle_status.dodge, OldDer#battle_status.dodge),
					Der1 = Der#battle_status{dodge = Value},
					calc_der_last_effect(H , Der1, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H , Der1, Time, OldDer)
			end;
		ten -> %% 坚韧
			case T > Time of
				true ->
					Value = value_cate(Int, Float, Der#battle_status.ten, OldDer#battle_status.ten),
					Der1 = Der#battle_status{ten = Value},
					calc_der_last_effect(H , Der1, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H , Der1, Time, OldDer)
			end;
		fire_def -> %% 暴击伤害抵消
			case T > Time of
				true ->
					Value = value_cate(Int, Float, Der#battle_status.fire, OldDer#battle_status.fire),
					Der1 = Der#battle_status{fire = Value},
					calc_der_last_effect(H , Der1, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H , Der1, Time, OldDer)
			end;
		ice_def ->  %% 格挡
			case T > Time of
				true ->
					Value = value_cate(Int, Float, Der#battle_status.ice, OldDer#battle_status.ice),
					Der1 = Der#battle_status{ice = Value},
					calc_der_last_effect(H , Der1, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H , Der1, Time, OldDer)
			end;
		drug_def -> %% 伤害增加次数
			case T > Time of
				true ->
					Value = value_cate(Int, Float, Der#battle_status.drug, OldDer#battle_status.drug),
					Der1 = Der#battle_status{drug = Value},
					calc_der_last_effect(H , Der1, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H , Der1, Time, OldDer)
			end;
		hurt -> %% 加深伤害
			case T > Time of
				true ->
					Der1 = Der#battle_status{hurt_list = [Int, Float|Der#battle_status.hurt_list]},
					calc_der_last_effect(H , Der1, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H , Der1, Time, OldDer)
			end;
		ftsh -> %% 对自身反弹伤害
			case T > Time of
				true ->
					Der1 = Der#battle_status{ftsh = [Int, Float]},
					calc_der_last_effect(H , Der1, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H , Der1, Time, OldDer)
			end;
		shield -> %% 对自身法盾
			case T > Time of
				true ->
					Shield = Int,
					Der1 = Der#battle_status{shield = Shield},
					calc_der_last_effect(H , Der1, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H , Der1, Time, OldDer)
			end;
		immune_effect -> %% 免疫特效
			case T > Time of
				true -> 
					Der1 = Der#battle_status{immune_effect = 1},
					calc_der_last_effect(H, Der1, Time, OldDer);
				false -> 
					Der1 = Der#battle_status{immune_effect = 0, battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H, Der1, Time, OldDer)
			end;
		immune_hurt -> %% 免疫伤害
			case T > Time of
				true -> 
					Der1 = Der#battle_status{immune_hurt = 1},
					calc_der_last_effect(H, Der1, Time, OldDer);
				false -> 
					Der1 = Der#battle_status{immune_hurt = 0, battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H, Der1, Time, OldDer)
			end;
		hurt_del -> %% 对自身伤害减免
			case T > Time of
				true ->
					Der1 = Der#battle_status{hurt_del_list = [Int, Float | Der#battle_status.hurt_del_list]},
					calc_der_last_effect(H , Der1, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H , Der1, Time, OldDer)
			end;
		change -> %% 变身
			case T > Time of
				true -> 
					calc_der_last_effect(H, Der, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					change(Der, 0, 0, 0),
					calc_der_last_effect(H, Der1, Time, OldDer)
			end;
		parry -> %% 格挡
			case T > Time of
				true -> 
					Der1 = Der#battle_status{parry = 1, battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H, Der1, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H, Der1, Time, OldDer)
			end;
		_ ->
			case T > Time of
				true -> 
					calc_der_last_effect(H , Der, Time, OldDer);
				false ->
					Der1 = Der#battle_status{battle_status = lists:keydelete({K, SkillId}, 3, Der#battle_status.battle_status)},
					calc_der_last_effect(H, Der1, Time, OldDer)
			end
	end.

%% 检查PK状态
%% pk状态：和平模式 0，全体模式 1， 国家模式 2， 帮派模式 3，队伍模式 4， 善恶模式 5, 战场阵营6, 幽灵7
check_pk_status(Aer, Der) ->
    case Aer#battle_status.sign of
        1 -> %% 攻击方是怪物
            case Aer#battle_status.group == Der#battle_status.group andalso Aer#battle_status.group > 0 andalso Der#battle_status.group > 0 of
                true ->
                    false;
                _ ->
                    true
            end;
        2 ->
            CityDoor = lists:member(Der#battle_status.mid, [40440, 40441, 40442, 40443, 40444, 40464, 40465, 40466, 40467, 40468, 40474, 40475, 40476, 40477, 40478]),
            NoPkLimScene = lists:member(Aer#battle_status.scene, data_god:get(scene_id2)),
            if
                Aer#battle_status.visible == 1 orelse Der#battle_status.visible == 1 -> false;
                Aer#battle_status.scene == 251 orelse NoPkLimScene == true -> true; %% 1vs1地图不管pk模式
                %% 只有弩车和冲车能攻击城门怪物
                CityDoor == true andalso (Aer#battle_status.factionwar_stone /= 11 andalso Aer#battle_status.factionwar_stone /= 12) -> false; 
				Der#battle_status.is_be_atted == 0 -> false; %% 不可攻击的怪物
                Der#battle_status.sign  ==  1 -> %% 防御方是怪物
                    %% 防御方是怪物
                    case Aer#battle_status.group =:=  Der#battle_status.group andalso Aer#battle_status.group > 0  andalso Der#battle_status.group > 0 of
                        true ->
                            false;
                        _ ->
                            true
                    end;
                Der#battle_status.sign  ==  2 ->
                    %% 是否安全区
					IsSafeScene = lib_scene:is_safe(Aer#battle_status.scene, Der#battle_status.x, Der#battle_status.y) orelse lib_scene:is_safe(Aer#battle_status.scene, Aer#battle_status.x, Aer#battle_status.y),
					if
						IsSafeScene == true -> battle_fail(8, Aer, []), false;
						Aer#battle_status.group > 0 andalso Der#battle_status.group > 0 andalso Aer#battle_status.group =:= Der#battle_status.group -> false;
						Der#battle_status.pk_status == 0 orelse Aer#battle_status.pk_status == 0 -> false;
						Aer#battle_status.pk_status == 2 -> 
							Aer#battle_status.realm =/= Der#battle_status.realm;
						Aer#battle_status.pk_status == 3 -> 
							Aer#battle_status.guild_id =/= Der#battle_status.guild_id andalso lists:member(Der#battle_status.guild_id, Aer#battle_status.friend_gids) == false;
						Aer#battle_status.pk_status == 4 -> 
							is_pid(Aer#battle_status.pid_team) == false orelse Aer#battle_status.pid_team /= Der#battle_status.pid_team;
						Aer#battle_status.pk_status == 5 -> 
							Der#battle_status.pk_value > 200;
						true -> true
					end
			end
	end.

%% 计算反弹伤害
calc_ftsh(Aer, _, _) when Aer#battle_status.del_hp_each_time /= 0 -> Aer; %% 有受到固定伤害的怪物不受反弹伤害 
calc_ftsh(Aer, [0, 0], _Hurt) -> Aer;
calc_ftsh(Aer, [Int, Float], Hurt) -> 
    Value = value_cate(Int, Float, 0, Hurt),
    if
        Aer#battle_status.hp > Value -> 
            set_effect_list(Aer#battle_status{hp=Aer#battle_status.hp - Value}, {4, 0, Value});
        true ->  
            set_effect_list(Aer#battle_status{hp = 1}, {4, 0, Value})
    end.

%% 计算吸血
calc_suck_blood(Aer, [0, 0], _Hurt) -> Aer;
calc_suck_blood(Aer, [Int, Float],  Hurt) ->
    SuckBloodHp = value_cate(Int, Float, 0, Hurt),
    Hp = min(Aer#battle_status.hp + SuckBloodHp, Aer#battle_status.hp_lim),
    set_effect_list(Aer#battle_status{hp=Hp}, {7, 0, SuckBloodHp}).

%% 防守方数据更新(玩家)
der_update_scene_info(Der, BattleReturn, RetrunAtter) ->
	%% 防守方信息
	#battle_status{
		id = DefId,
		platform = DefPlatfrom,
		server_num = DefServerNum,
		node = DefNode,
		sid  = DefPid,
		skill_status = SkillStatus
	} = Der,

	%% 防守方需更新的信息
	#battle_return{
		hp = Hp,
		x  = X,
		y  = Y,
		%anger = Anger,
		shield = Shield,
		battle_status = BattleStatus,
		sign = Sign
	} = BattleReturn,

	%% 攻击者信息
	#battle_return_atter{
		id = AttId, 
		platform = AttPlatForm,
		server_num = AttServerNum,
		att_time = NowTime
	} = RetrunAtter,

	DefKey = [DefId, DefPlatfrom, DefServerNum],
	AttKey = [AttId, AttPlatForm, AttServerNum],

	case lib_scene_agent:get_user(DefKey) of
		[] -> skip;
		User -> 
			%% 法盾计算
			BattleStatus1 = case lists:keyfind(shield, 1, BattleStatus) of
				false ->
					BattleStatus;
				{_, SkillId,_,SkillLv,_,_,_,T} ->
					case Shield > 0 of
						true ->
							[{shield, SkillId, {shield, SkillId}, SkillLv, 0, Shield, 0, T}|lists:keydelete(shield, 1, BattleStatus)];
						false ->
							lists:keydelete(shield, 1, BattleStatus)
					end
			end,
			BA = User#ets_scene_user.battle_attr,
			%% 竞技场(120)的场景被玩家攻击会记录攻击者
			case lists:member(User#ets_scene_user.scene, ?SET_HURT_LIST_SCENE_LIST) andalso Sign == 2 of
				true -> 
					HitList = [{AttKey, NowTime}|lists:keydelete(AttKey, 1, BA#battle_attr.hit_list)];
				false -> 
					HitList = BA#battle_attr.hit_list
			end,
			case Hp == 0 of
				true ->  
					HitList1     = [],
					SkillStatus1 = {0, 0};
				false -> 
					HitList1     = HitList,
					SkillStatus1 = SkillStatus
			end,
			NewBA = BA#battle_attr{
				hit_list = HitList1, 
				battle_status = BattleStatus1,
				skill_status  = SkillStatus1
			},
			NewUser = User#ets_scene_user{
				hp = Hp,
				x = X,
				y = Y,
				%anger = Anger,
				battle_attr = NewBA
			},
				
			%% 打断采集怪物
			NewUser1 = lib_battle:interrupt_collect(NewUser),
			lib_scene_agent:put_user(NewUser1),
			case Hp > 0 of
				true -> 
					Msg = {'battle_info', BattleReturn#battle_return{battle_status = BattleStatus1, atter = []}};
				false -> 
					Msg = {'battle_info_die', BattleReturn#battle_return{hit_list = HitList, battle_status = BattleStatus1}}
			end,
			send_to_node_pid(DefNode, DefPid, Msg)
	end.

%% 辅助技能完成后更新玩家场景数据
assister_update_scene_info(#battle_status{id=Id, platform=Platform, server_num = ServerNum, battle_status=BS} = _Assister) -> 
    case lib_scene_agent:get_user([Id, Platform, ServerNum]) of
        #ets_scene_user{battle_attr = BA} = User ->
            NewBA = BA#battle_attr{ 
                battle_status = BS
            },
            NewUser = User#ets_scene_user{
                battle_attr = NewBA
            },
            lib_scene_agent:put_user(NewUser);
        [] -> skip
    end.

%% 异常状态替换规则
calc_abnormality_buff_swap(K, [Int, Float], LastTime, SU, NowTime, SkillId, SkillLv, EffectId) -> 
	case lists:keyfind({K, SkillId}, 3, SU) of
		%% 没有这个buff就直接加上
		false ->  
			NewSU  = [{K, SkillId, {K, SkillId}, SkillLv, 0, Int, Float, NowTime+LastTime}|SU],
			NewEff = {EffectId, LastTime, 0};

        %% 如果有这个buff就不加
		_ -> 
			NewSU  = SU,
			NewEff = []
	end,
	{NewSU, NewEff}.

%% 持续buff替换规则 -> NewUD = list() = [{K, SkillId, {K, SkillId}, SKillLv, Stack, V, Time} .. ]
calc_buff_swap(K, [Int, Float], LastTime, SU, NowTime, SkillId, SkillLv, Stack, EffectId) -> 
	case lists:keyfind({K, SkillId}, 3, SU) of

        %% 没有这个技能就直接加上
		false -> 
			case Stack > 0 of
				true -> 
                    %% 如果配置中buff叠加数大于0，则Stack值初始为1，否则为0
					NewSU  = [{K, SkillId, {K, SkillId}, SkillLv, 1, Int, Float, NowTime+LastTime} | SU],
					NewEff = {EffectId, LastTime, 0};
				false ->  
					NewSU  = [{K, SkillId, {K, SkillId}, SkillLv, 0, Int, Float, NowTime+LastTime} | SU],
					NewEff = {EffectId, LastTime, 0}
			end;

        %% 有这个技能buff，等级大替换等级小的buff信息
		{_, _, _, Lv0, Stack0, Int0, Float0, _} -> 
			case Lv0 < SkillLv of
				true -> 
                    %% 如果配置中buff叠加数大于0，则Stack值初始为1，否则为0
					case Stack > 0 of
						true -> 
							NewSU  = [{K, SkillId, {K, SkillId}, SkillLv, 1, Int, Float, NowTime+LastTime} | lists:keydelete({K, SkillId}, 3, SU)],
							NewEff = {EffectId, LastTime, 0};
						false -> 
							NewSU  = [{K, SkillId, {K, SkillId}, SkillLv, 0, Int, Float, NowTime+LastTime} | lists:keydelete({K, SkillId}, 3, SU)],
							NewEff = {EffectId, LastTime, 0}
					end;
				false -> 
					if 
                        %% 有叠加数，则每次释放该buff，buff中stack都加1
						Stack > 1 andalso Stack0 < Stack andalso Lv0 == SkillLv ->
							NewSU  = [{K, SkillId, {K, SkillId}, Lv0, Stack0+1, Int0 + Int, buff_value_add(Float0, Float), NowTime+LastTime} | lists:keydelete({K, SkillId}, 3, SU)],
							NewEff = {EffectId, LastTime, 0};
                         %% 等级相同，重数相同（包含没有叠加数的情况，即stack=0），更新持续时间
						Stack0 == Stack andalso Lv0 == SkillLv -> 
							NewSU  = [{K, SkillId, {K, SkillId}, Lv0, Stack0, Int0, Float0, NowTime+LastTime} | lists:keydelete({K, SkillId}, 3, SU)],
							NewEff = {EffectId, LastTime, 0};
                        %% 其余情况不作处理
						true -> 
							NewSU  = SU,
							NewEff = []
					end
			end
	end,
	{NewSU, NewEff}.

%% 特殊化的小函数，技能数值相加
buff_value_add(V, V1) when is_float(V) orelse is_float(V1) -> (V*1000+V1*1000)/1000;
buff_value_add(V, V1) -> V+V1.

%% 检查速度buff
%% Id:玩家id; 
%% Scene:玩家场景唯一id; 
%% X:x坐标; 
%% Y:y坐标; 
%% BaseSpeed:基础速度; 
%% BattleStatus:战斗状态;
%% Time:longunixtime; 
%% Sign:1.怪物 2.人
check_speed_buff_broadcast(Id, Platform, SerNum, Scene, CopyId, X, Y, BaseSpeed, BattleStatus, Time, Sign1) ->
   {SpeedParameList, NewBattleStatus, Sign} = check_speed_buff_helper(BattleStatus, [], Time, [], 0, BaseSpeed),
   case Sign == 0 of
	   true -> skip;
	   false -> 
		   Speed = round(BaseSpeed + lists:sum(SpeedParameList)),
		   lib_scene:change_speed(Id, Platform, SerNum, Scene, CopyId, X, Y, Speed, Sign1)
   end,
   NewBattleStatus.

%% 检查buff(Sign == 0 不需要需要广播速度)
check_speed_buff(BaseSpeed, BattleStatus, Time) -> 
	{SpeedParameList, NewBattleStatus, Sign} = check_speed_buff_helper(BattleStatus, [], Time, [], 0, BaseSpeed),
	Speed = round(BaseSpeed + lists:sum(SpeedParameList)),
	{NewBattleStatus, Speed, Sign}.

%% 重新计算速度buff
count_speed_buff(BaseSpeed, BattleStatus, Time) -> 
	{SpeedParameList, NewBattleStatus, _Sign} = check_speed_buff_helper(BattleStatus, [], Time, [], 0, BaseSpeed),
	Speed = round(BaseSpeed + lists:sum(SpeedParameList)),
	{NewBattleStatus, Speed}.

check_speed_buff_helper([], SpeedParameList, _Time, List, Sign, _BaseSpeed) -> {SpeedParameList, List, Sign};
check_speed_buff_helper([H|BattleStatus], SpeedParameList, Time, List, Sign, BaseSpeed) -> 
	case H of
		{speed, _, _, _, _, Int, Float, T} -> %% 减速 
			case T > Time of
				true  -> check_speed_buff_helper(BattleStatus, [Int + BaseSpeed * Float|SpeedParameList], Time, [H|List], Sign, BaseSpeed);
				false -> check_speed_buff_helper(BattleStatus, SpeedParameList, Time, List, 1, BaseSpeed) %% buff过期
			end;
		_ -> check_speed_buff_helper(BattleStatus, SpeedParameList, Time, [H|List], Sign, BaseSpeed)
	end.

%% 替换速度buff (加速和减速各保留一个)
swap_speed_buff(BaseSpeed, Int, Float, BattleStatus, NowTime) -> 
	case swap_speed_buff_helper(Int, Float, BattleStatus, 0, 0, NowTime) of
		true            -> false; %% 已经有一个加（减）速buff了
		{false, 0, 0}   -> {true, value_cate(Int, Float, BaseSpeed, BaseSpeed)}; %% 没有其他速度buff
		{false, IntPos, FloatPos} -> 
			NewSpeed = round(Int + IntPos + BaseSpeed * (1 + FloatPos + Float)),
			{true, NewSpeed}
	end.
%% 替换速度buff (加速和减速各保留一个)
swap_speed_buff_helper(_Int, _Float, [], IntPos, FloatPos, _) -> {false, IntPos, FloatPos};
swap_speed_buff_helper(Int, Float, [{speed, _, _, _, _, IntOriginal, FloatOriginal, T}|Tail], _IntPos, _FloatPos, NowTime) when T >= NowTime -> 
	if
		IntOriginal*Int > 0 orelse FloatOriginal*Float > 0 -> true;
		true -> swap_speed_buff_helper(Int, Float, Tail, IntOriginal, FloatOriginal, NowTime)
	end;
swap_speed_buff_helper(Int, Float, [_|Tail], IntPos, FloatPos, NowTime) -> swap_speed_buff_helper(Int, Float, Tail, IntPos, FloatPos, NowTime).

%% 检查特殊状态(眩晕，沉默)
check_special_state(State, BattleStatus, Time) -> check_special_state(State, BattleStatus, 0, Time, []).
check_special_state(_State, [], StateParame, _Time, List) -> {List, StateParame};
check_special_state(State, [H|Effect], StateParame, Time, List) -> 
	case H of
		{State, _SkillId, _, _SkillLv, _Stack, _Int, _Float, T} -> 
			case T > Time of
				true ->  check_special_state(State, Effect, 1, Time, [H|List]);
				false -> check_special_state(State, Effect, StateParame, Time, List)
			end;
		_ -> check_special_state(State, Effect, StateParame, Time, [H|List])
	end.

%% 技能天赋综合效果
%% 返回 : {#player_skill, [{天赋id，天赋等级，天赋效果, 天赋叠加数}..], Tids}
calc_skill_talent([], Skill, TalentDatas, _, Tids) -> {Skill, TalentDatas, Tids};
calc_skill_talent([Tid | TalentList], Skill, TalentDatas, Aer, Tids) ->
	case lists:keyfind(Tid, 1, Aer#battle_status.skill) of
		false -> calc_skill_talent(TalentList, Skill, TalentDatas, Aer, Tids);
		{Tid, TLv} -> 
			BaseSkill = data_skill:get(Tid, TLv),
			#player_skill{stack = Stack, data = [_, _| TalentEffect1]} = BaseSkill,

			{NewSkill, NewTalentData} = calc_skill_talent_effect(TalentEffect1, Skill),
			case NewTalentData == [] of %% 没有效果了
				true -> 
					calc_skill_talent(TalentList, NewSkill, TalentDatas, Aer, [{Tid, TLv} | Tids]);
				false -> 
					calc_skill_talent(TalentList, NewSkill, [{Tid, TLv, NewTalentData, Stack} | TalentDatas], Aer, [{Tid, TLv} | Tids])
			end
	end.

%% 技能天赋效果叠加
%% TalentEffect : 天赋效果
calc_skill_talent_effect(TalentEffect, Skill) ->
	case Skill#player_skill.data of
		[_, _ | T] -> calc_skill_talent_effect(TalentEffect, Skill, T, []);
		_ -> {Skill, []}
	end.

calc_skill_talent_effect([], Skill, SEffect, NewTEffect) -> 
	[C, M | _T] = Skill#player_skill.data,
	{Skill#player_skill{data = [C, M] ++ SEffect}, NewTEffect};
calc_skill_talent_effect([{K, V} | TEffect], Skill, SEffect, NewTEffect) -> 
	case K of
		_ -> 
			calc_skill_talent_effect(TEffect, Skill, SEffect, [{K, V} | NewTEffect])
	end.

%% 人物游戏线buff处理
calc_assist_status_effect(Status, SkillData, NowTime, SkillId, SkillLv) ->
	User = init_data(Status), 
	NewUser = calc_assist_last_effect(SkillData, User#battle_status.battle_status, NowTime, SkillId, SkillLv, User, 0),
	Status#player_status{battle_status = NewUser#battle_status.battle_status}.

%% 招怪
%% InheritList 继承列表
call_mon([], _, _ , _) -> ok;
call_mon([{MonId, Num, IsActive, InheritList} | ArgsList], User, Aer, Der) ->
	%% 参照方
	#battle_status{scene=Scene, copy_id=CopyId, x=X, y=Y} = User,
	%% 召唤方
	#battle_status{
	 	id=AttId, name=AttName, platform=AttPlatform, server_num=AttServerNum, group=AttGroup, 
		lv=AttLv, sid=AttSid, node=AttNode, pid_team=AttTeamPid, sign=AttSign
	} = Aer,
	%% 召唤方的攻击目标
	#battle_status{id=DefId, platform=DefPlatform, server_num=DefServerNum, sign=DefSign, sid=DefSid} = Der,

	F = fun(_) -> 
		X1 = X+util:rand(-2, 2),
		Y1 = Y+util:rand(-2, 2),
		X2 = case X1 > 0 of true -> X1; false -> 0 end,
		Y2 = case Y1 > 0 of true -> Y1; false -> 0 end,
		%% 一般继承属性：分组属性，主动攻击属性，等级属性
		Args = case IsActive of
			1 -> [{group, AttGroup}, {auto_lv, AttLv}, {auto_att, 0}];
			_ -> [{group, AttGroup}, {auto_lv, AttLv}]
		end,
		%% 特殊继承属性列表
		InheritArgs = case InheritList of
			[] -> [];
			_  -> 
				InheritMArgs = call_mon_inherit_list(InheritList, [], Aer),
				%%NOTE: skill_owner属性，表示怪物属于技能触发，召唤追踪类技能，当此怪物杀死对方时，与施法方杀死对方效果同等
				[{skill_owner, {AttId, AttPlatform, AttServerNum, AttSid, AttNode, AttTeamPid, AttName, AttSign}} | InheritMArgs]
		end,
		%% 继承父辈的攻击目标
		AttTargetList = case Der of
			[] -> 
				Args;
			#battle_status{id=DefId,  platform=DefPlatform, server_num=DefServerNum, sign=DefSign, sid=DefSid} -> 
				DefKey = case DefSign of
					%% 怪物key
					1 -> DefId;
					%% 玩家key
					_ -> [DefId, DefPlatform, DefServerNum]
				end,
				lists:keyreplace(auto_att, 1, Args, {auto_att, [DefKey, DefSid, DefSign]})
		end,
		%% 每个招唤怪物延时500毫秒出现
		timer:sleep(500),
		lib_mon:async_create_mon(MonId, Scene, X2, Y2, IsActive, CopyId, 1, InheritArgs ++ AttTargetList)
	end,
	util:for(1, Num, F),
	call_mon(ArgsList, User, Aer, Der).

%% 处理怪物召唤的继承列表,转化为怪物生成时的参数列表
call_mon_inherit_list([], Args, _) -> Args;
call_mon_inherit_list([{K, Int, Float}|T], Args, User) -> 
	NewArgs = case K of
		att -> [{att, value_cate(Int, Float, User#battle_status.att, User#battle_status.att)}| Args];
		_   -> Args
	end,
	call_mon_inherit_list(T, NewArgs, User).

%% 检查可以使用技能
%% @spec
%% @retrun {true, NewAer} | {false, ErrCode, NewAer} 
%%         ErrCode = 4(距离目标太远) | 5(cd时间未到) | 6(技能配置有误) | 10(怒气不足) | 21(晕) | 22(沉默) | 23(恐惧) | 24(缠绕) | 25(点穴)
%% @end
check_use_skill(Aer, Der, SkillId, SkillLv, NowTime) -> 
	%% 检查异常状态(沉默，眩晕...)
	case check_abnormality_eff(Aer, NowTime, SkillId) of
		{false, ErrorCode, AerEff} -> {false, ErrorCode, AerEff};
		{true,  AerEff} -> 
			%% 检查技能释放条件
			case check_skill_condition(AerEff, Der, SkillId, SkillLv, NowTime) of
				{false, ErrorCode, AerCon} -> {false, ErrorCode, AerCon};
				{true, AerCon, SkillR} -> {true, AerCon, SkillR}
			end
	end.

%% 检查是否处于异常状态
%% @spec
%% @retrun {true, NewAer} | {false, ErrCode, NewAer} 
%%         ErrCode = 21(晕) | 22(沉默) | 23(恐惧) | 24(缠绕) | 25(点穴)
%% @end
check_abnormality_eff(Aer, NowTime, SkillId) -> 
	BattleStatus = Aer#battle_status.battle_status,

	%% 眩晕
	{YunBattleStatus, YunNum} = check_special_state(yun, BattleStatus, NowTime),

	Result = case YunNum of
		0 -> 
			%% 沉默
            case is_base_skill(SkillId) of
                true -> 
                    CmBattleStatus = YunBattleStatus, 
                    CmNum = 0;
                false -> {CmBattleStatus, CmNum} = check_special_state(cm, YunBattleStatus, NowTime)
            end,
            case CmNum of
				0 -> 
					%% 恐惧
					{FearBattleStatus, FearNum} = check_special_state(fear, CmBattleStatus, NowTime),
					case FearNum of
						0 -> 
							%% 缠绕
							{BindBattleStatus, BindNum} = check_special_state(bind, FearBattleStatus, NowTime),
							case BindNum of
								0 ->
									%% 点穴
									{PPointBattleStatus, PPointNum} = check_special_state(pressure_point, BindBattleStatus, NowTime),
									case PPointNum of
										0 -> {true, BindBattleStatus};
										_ -> {false, 25, PPointBattleStatus}
									end;
								_ -> {false, 24, BindBattleStatus}
							end;
						_ -> {false, 23, FearBattleStatus}
					end;
				_ ->  {false, 22, CmBattleStatus}
			end;
		_ -> {false, 21, YunBattleStatus}
	end,

	%% 组织新Aer
	case Result of
		{true, LastBattleStatus} -> {true, Aer#battle_status{battle_status=LastBattleStatus}};
		{false, ErrCode, LastBattleStatus} -> {false, ErrCode, Aer#battle_status{battle_status=LastBattleStatus}}
	end.

%% 检查技能施放条件
%% @spec
%% @retrun  4(距离目标太远) | 5(cd时间未到) | 6(技能配置有误) | 10(怒气不足) | 26(处于施法状态中)
%% @end
check_skill_condition(Aer, Der, SkillId, SkillLv, NowTime) -> 
	case data_skill:get(SkillId, SkillLv) of
		[] -> %%无此技能配置
			{false, 6, Aer};
		SkillR ->
			case SkillR#player_skill.type of
				2 -> {false, 6, Aer}; %% 技能配置有误
				_ -> 
                    Distance = case SkillR#player_skill.data#skill_lv_data.distance of
                        0 -> Aer#battle_status.att_area;
                        SkillDistance -> SkillDistance
                    end,
                    %% 判断距离(obj=1：对自己释放)
                    case SkillR#player_skill.obj == 1 orelse 
                        check_distance([Distance, Aer#battle_status.x, Aer#battle_status.y], [Der#battle_status.x, Der#battle_status.y]) 
                        of 
                        false -> 
                            {false, 4, Aer}; %% 距离不足
                        true  -> 
                            {SkillStatus, StatusEndTime} = Aer#battle_status.skill_status,
                            case SkillR#player_skill.type == 4 orelse SkillStatus == 0 orelse NowTime >= StatusEndTime of
                                false -> {false, 26, Aer}; %% 处于施法状态不能放副技能外的技能
                                true  -> 
                                    LevelData   = SkillR#player_skill.data,
                                    UseConditon = LevelData#skill_lv_data.use_condition,
                                    %% 判断策划配置中使用条件是否满足
                                    case check_skill_use_condition(UseConditon, Aer, NowTime) of
                                        {false, UseCErrorCode} -> 
                                            {false, UseCErrorCode, Aer};
                                        {true, UseCAer} -> 
                                            case is_cd(SkillId, Aer#battle_status.skill_cd, NowTime, SkillR#player_skill.cd) of
                                                false -> %% 如果怪物cd未有到，转为普通攻击
                                                    case Aer#battle_status.sign of
                                                        1 -> {true, UseCAer, data_skill:get(?MON_BASE_SKILL_ID, ?MON_BASE_SKILL_LV)};
                                                        _ -> {false, 5, Aer} %% cd时间未到
                                                    end;
                                                true -> {true, UseCAer, SkillR}
                                            end
                                    end
                            end
                    end
            end
    end.

%% 检查技能施放条件
check_skill_use_condition([], Aer, _Now) -> {true, Aer};
check_skill_use_condition([{K, V} | T], Aer, Now) -> 
	Result = case K of
        mp -> 
			case V > Aer#battle_status.mp of
				false -> {true, Aer#battle_status{mp = Aer#battle_status.mp - V}};
				true  -> {false, 27} %% mp不足
			end;
		_ -> {true, Aer}
	end,
	case Result of
		{true, NewAer} -> check_skill_use_condition(T, NewAer, Now);
		_ -> Result
	end.

%% 判断是否基础技能
is_base_skill(SkillId) -> 
    lists:member(SkillId, [?WARRIOR_BASE_SKILL_ID, ?MAGE_MON_BASE_SKILL_ID, ?ASSASIN_BASE_SKILL_ID, ?MON_BASE_SKILL_ID]).

%% 根据职业选择防御属性
select_def_by_career(AerCareer, Der, SkillId) -> 
    case is_base_skill(SkillId) of
        true  -> Der#battle_status.def; %% 打怪和普通攻击使用普通防御
        false -> 
            case AerCareer of
                1 -> Der#battle_status.fire; %% 神将选择火抗
                2 -> Der#battle_status.ice;  %% 天尊选择冰抗
                3 -> Der#battle_status.drug; %% 罗刹选择冥抗
                _ -> Der#battle_status.def
            end
    end.


%% 判断技能cd
is_cd(SkillId, SkillCdList, NowTime, SkillCd) -> 
	case lists:keyfind(SkillId, 1, SkillCdList) of
		false -> true;
		{_, LastUseTime} -> 
            NowTime - SkillCd + 200 > LastUseTime
	end.

%% 设置cd信息
set_skill_cd(#battle_status{skill_cd=SkillCdList} = User, SkillId, NowTime) -> 
    NewSkillCdList = [{SkillId, NowTime}| lists:keydelete(SkillId, 1, SkillCdList)],
    User#battle_status{skill_cd = NewSkillCdList}.

%% 打包错误信息
pack_error_data(Aer, _Der) when Aer#battle_status.sign == 1 orelse is_record(Aer, ets_mon) -> [];
pack_error_data(Aer, Der) -> 
	AerData = if
		is_record(Aer, battle_status) -> {
				Aer#battle_status.sign, Aer#battle_status.id, Aer#battle_status.platform, Aer#battle_status.server_num, Aer#battle_status.hp, Aer#battle_status.x, Aer#battle_status.y, Aer#battle_status.node 
			};
		is_record(Aer, ets_scene_user) -> {
				2, Aer#ets_scene_user.id, Aer#ets_scene_user.platform, Aer#ets_scene_user.server_num, Aer#ets_scene_user.hp, Aer#ets_scene_user.x, Aer#ets_scene_user.y, Aer#ets_scene_user.node
			};
		is_record(Aer, player_status) -> {
				2, Aer#player_status.id, Aer#player_status.platform, Aer#player_status.server_num, Aer#player_status.hp, Aer#player_status.x, Aer#player_status.y, none
			}
	end,
	DerData = if
		Der == [] -> {0, 0, "", 0, 0, 0, 0};
		is_record(Der, battle_status) -> {
				Der#battle_status.sign, Der#battle_status.id, Der#battle_status.platform, Der#battle_status.server_num, Der#battle_status.hp, Der#battle_status.x, Der#battle_status.y
			};
		is_record(Der, ets_scene_user) -> {
				2, Der#ets_scene_user.id, Der#ets_scene_user.platform, Der#ets_scene_user.server_num, Der#ets_scene_user.hp, Der#ets_scene_user.x, Der#ets_scene_user.y
			};
		is_record(Der, ets_mon) -> {
				1, Der#ets_mon.id, "", 0, Der#ets_mon.hp, Der#ets_mon.x, Der#ets_mon.y
			}
	end,
	[AerData, DerData].

%% 战斗失败
%% ErrCode =
%%        1 对方没血
%%        2 出手太快
%%        3 自己没血
%%        4 距离太远
%%        5 技能cd未到
%%        6 技能数据有误
%%        7 坐骑不能战斗 
%%        8 安全区不能pk
%%        9 对方处于护送保护时间
%%        10 怒气不足，不能释放技能 
%%        11 同等级段内的不能劫镖
%%        12 巡游中不能攻击
%%        21 晕
%%        22 沉默
%%        23 恐惧
%%        24 缠绕
%%        25 点穴
%%        26 处于施法状态中
%%        27 mp不足
battle_fail(ErrCode, Aer, Der) -> 
	ErrData = pack_error_data(Aer, Der),
	battle_fail(ErrCode, ErrData).
battle_fail(State, [{Sign1, PlayerId1, Platform1, SerNum1, Hp1, X1, Y1, Node}, {Sign2, PlayerId2, Platform2, SerNum2, Hp2, X2, Y2}]) ->
	{ok, BinData} = pt_200:write(20005, [State, Sign1, PlayerId1, Platform1, SerNum1, Hp1, X1, Y1, Sign2, PlayerId2, Platform2, SerNum2, Hp2, X2, Y2]),
	rpc_cast_to_node(Node, lib_server_send, send_to_uid, [PlayerId1, BinData]);
battle_fail(_, _) -> skip.

%% 发送消息
send_to_node_pid(Node, Pid, Msg) ->
	case Node =:= none of
		true ->
			Pid ! Msg;
		false ->
			rpc:cast(Node, erlang, send, [Pid, Msg])
	end.

%% 远程过程调用函数(跨服中心服->单服跨服节点)
rpc_cast_to_node(Node, M, F, A) ->
	case Node =:= none of
		true ->
			erlang:apply(M, F, A);
		false ->
			rpc:cast(Node, M, F, A)
	end.

%% 持续更新血量
last_change_hp(Node, Pid, Data) ->
	[Count, GapTime, Int, Float] = Data,
	timer:sleep(GapTime),
	send_to_node_pid(Node, Pid, {last_change_hp, Int, Float}),
	LeftCount = Count - 1,
	case LeftCount > 0 of
		true ->
			NewData = [LeftCount, GapTime, Int, Float],
			last_change_hp(Node, Pid, NewData);
		false ->
			ok
	end.

%% 变身
change(#battle_status{id=Id, mid=Mid, scene=Scene, copy_id=CopyId, x=X, y=Y, sid=Pid, sign=Sign, node=Node}=_User, FigureId, LastTime, SkillId) ->
	if
		Sign == 2 -> %% 玩家接口
			rpc_cast_to_node(Node, mod_server_cast, set_data, [[{figure, {FigureId, LastTime, SkillId}}], Pid]);
		Sign == 1 -> 
			FigrueId1 = case FigureId == 0 of
				true -> 
					Mon = data_mon:get(Mid),
					Mon#ets_mon.icon;
				false -> FigureId
			end,
			{ok, BinData} = pt_120:write(12098, [Id, FigrueId1]),
			lib_server_send:send_to_area_scene(Scene, CopyId, X, Y, BinData),
			ok;
		true -> skip
	end.

%% 记录技能cd到游戏线
skill_cd_mark(SkillR, Aer, NowTime) -> 
	case Aer#battle_status.sign == 2 andalso SkillR#player_skill.cd > 15000 andalso Aer#battle_status.lv > 45 of
		true  -> send_to_node_pid(Aer#battle_status.node, Aer#battle_status.sid, {'SKILL_CD', SkillR#player_skill.skill_id, NowTime});
		false -> skip
	end.

%% 移除施法状态
%% K : 断开类型(yun, cm, fear, pressure_point...)
interrupt_skill_status(K, #battle_status{scene=SceneId, copy_id=CopyId, x=X, y=Y, sign=Sign, 
	id=Id, platform=Platform, server_num=ServerNum, node=Node, sid=Pid, skill_status = {Status, _}} = User) 
	when Status > 0, K == yun orelse K == pressure_point ->

	{ok, BinData} = pt_200:write(20014, [Sign, Id, Platform, ServerNum, Status]),
	case lib_scene:is_broadcast_scene(SceneId) of
		true -> lib_server_send:send_to_scene(SceneId, CopyId, BinData);
		false -> lib_server_send:send_to_area_scene(SceneId, CopyId, X, Y, BinData)
	end,
	send_to_node_pid(Node, Pid, 'interrupt_combo_skill'),
	User#battle_status{skill_status={0, 0}};
interrupt_skill_status(_, User) -> User.

%% 血量变化，广播血量
broadcast_hp(#battle_status{hp=Hp, hp_lim=HpLim, id=Id, platform=Platform, server_num=ServerNum, 
        scene=SceneId, copy_id=CopyId, x=X, y=Y, sign=Sign}= _User) -> 
    case Sign of
        1 -> %% 怪物
            {ok, BinData} = pt_120:write(12081, [Id, Hp]);
        _ -> %% 玩家
            {ok, BinData} = pt_120:write(12009, [Id, Platform, ServerNum, Hp, HpLim])
    end,
   	case lib_scene:is_broadcast_scene(SceneId) of
		true  -> lib_server_send:send_to_scene(SceneId, CopyId, BinData);
		false -> lib_server_send:send_to_area_scene(SceneId, CopyId, X, Y, BinData)
	end.


%% 判断技能效果是否起作用
check_skill_effect_condition([], _User, _NowTime, Result) -> Result;
check_skill_effect_condition(EffectCondition, User, NowTime, Result) -> 
    check_skill_effect_condition(EffectCondition, User, User, NowTime, Result).
check_skill_effect_condition([], _Aer, _Der, _NowTime, Result) -> Result;
check_skill_effect_condition([{Type, AffectedParties, Args}|T], Aer, Der, NowTime, Result) -> 
    User = case AffectedParties of
        1 -> Aer;
        2 -> Der
    end,
    F = fun({K, SkillId, _, _SkillLv, _Stack, _Int, _Float, Time}) -> 
            case Type of
                1 -> NowTime < Time andalso lists:member(lib_skill_buff:get_buff_no(K), Args);
                3 -> NowTime < Time andalso lists:member(SkillId, Args);
                _ -> true
            end
    end,
    TmpResult = case Type of
        2 -> User#battle_status.hp / User#battle_status.hp_lim < Args;
        _ -> lib_skill_buff:is_condition_fullfilled(F, User#battle_status.battle_status)
    end,
    check_skill_effect_condition(T, Aer, Der, NowTime, Result andalso TmpResult).
