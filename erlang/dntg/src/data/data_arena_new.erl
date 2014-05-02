%% Author: zengzhaoyuan
%% Created: 2012-5-19
%% Description: TODO: Add description to data_arena_new
-module(data_arena_new).
-include("scene.hrl").
-compile(export_all).
%%
%% Include files
%%

%%
%% Exported Functions
%%

%%
%% API Functions
%%
%% 基础数据配置
get_arena_config(Type)->
	case Type of
		% 开放日期(星期几)
		open_day -> [1,3,5];
        %open_day -> [];
		% [开始时刻，结束时刻]
		arena_time -> [[20,30],[21,0]];
		% 经验倍数
		exp_multiple ->1;
		% 等级限制（35级以上，含35）
		apply_level -> 30;
		% 房间最大人口数
        room_max_num -> 50;    %% 50
		% 另开启新房间人口条件
		room_new_num -> 45;    %% 45
		% 竞技场场景类型ID
        scene_id -> 120;
		% 长生点，红、黄、蓝
		scene_born->[[43,51],[10,18]];
		% 守护神ID,三个等级竞技场暂时设定为一样
		numer_id ->[{12001,12002,12003,12004,12005,12006},{12001,12002,12003,12004,12005,12006},{12001,12002,12003,12004,12005,12006}];
		% 守护神出生点[整场比赛只刷一次],
		numen_born->[[{43,51},{37,51},{42,44}],[{9,17},{19,15},{8,26}]];
		% 守护神被杀获取积分，杀之人额外获得
		numen_killed_score->50;
		% 结束后，全场第一奖励物品ID
		no1_gift_id -> 612001;
		no1_gift_num-> 1;
		% 离开竞技场的默认位置[场景类型ID, X坐标, Y坐标]
		leave_scene -> [102, 38, 54];
		% 怒气技能ID
		arena_skill_id -> 400001;
        % 死亡后增加技能buff
        die_skill_id ->   400021;
		% 最大怒气值次数
		max_anger -> 70;
		% 每次被杀，增加的怒气值
		add_anger -> 10;
		% 每次杀人，减少怒气值
		del_anger -> 5;
		% 默认怒气值 
		default_anger -> 20;
        % 定时增加怒气值 
        add_anger_timer_value -> 10;
        % 定时增加怒气的时间间隔(分钟)
        anger_interval -> 1;
		% boss掉落宝箱
		box_type -> 12007;
		%% 杀同一个人的有效间隔时间
		cd_time -> 10;
		%% 助攻时间
		assist_time -> 3;
		%% boss Id
		boss_id -> [12000,12010];
		%% boss 出生点
		boss_position -> [{8,53},{8,53},{8,53}];
		%% boss刷新时间 ->
		boss_time -> [{20,40}, {20, 50}, {21,10}];
		_ ->void
	end.

%%竞技场里所有NPC的类型ID中立boss+阵营守护神
get_npc_type_id()->
	[12001,12002,12003,12004,12005, 12006, 12000, 12010].

% 按照世界等级,这是竞技场人物保底玩法
get_hp_by_goable_lv(Lv)->
	if
		75=<Lv->40000;
		70=<Lv->40000;
		65=<Lv->35000;
		60=<Lv->30000;
		55=<Lv->25000;
		50=<Lv->20000;
		45=<Lv->15000;
		40=<Lv->10000;
		true->5000
	end.

%% 按照世界等级配置怪物血量 
get_hpatt_by_world_lv(Mon, Lv) ->
    IsMidNpc = lists:member(Mon#ets_mon.mid, [12001, 12004]),
    IsSideNpc = lists:member(Mon#ets_mon.mid, [12002, 12003, 12005, 12006]),
    IsBoss = lists:member(Mon#ets_mon.mid, [12000,12010]),
    if 
        IsMidNpc =:= true ->
            Att = Lv*20+max(Lv-40, 0)*20+max(Lv-50, 0)*20+max(Lv-60, 0)*20+max(Lv-70, 0)*20+max(Lv-80, 0)*20+max(Lv-90, 0)*20,
            Hp = Lv*50000+max(Lv-40, 0)*50000+max(Lv-50, 0)*50000+max(Lv-60, 0)*50000+max(Lv-70, 0)*50000+max(Lv-80, 0)*50000+max(Lv-90, 0)*50000;
        IsSideNpc =:= true ->
            Att = Lv*10+max(Lv-40, 0)*10+max(Lv-50, 0)*10+max(Lv-60, 0)*10+max(Lv-70, 0)*10+max(Lv-80, 0)*10+max(Lv-90, 0)*10,
            Hp = Lv*20000+max(Lv-40, 0)*20000+max(Lv-50, 0)*20000+max(Lv-60, 0)*20000+max(Lv-70, 0)*20000+max(Lv-80, 0)*20000+max(Lv-90, 0)*20000;
        IsBoss =:= true ->
            Att = Mon#ets_mon.att,
            Hp = Lv*30000+max(Lv-40, 0)*30000+max(Lv-50, 0)*30000+max(Lv-60, 0)*30000+max(Lv-70, 0)*30000+max(Lv-80, 0)*30000+max(Lv-90, 0)*30000;
        true ->
            Att = Mon#ets_mon.att,
            Hp = Mon#ets_mon.hp
    end,
    [Att, Hp].

%% 获取战场等级
%% @param PlayerLv 玩家等级
%% @return 0~3 0无战场 1低 2中 3高
get_room_lv(PlayerLv)->
	if
		PlayerLv<30->0;
		PlayerLv=<100->1;
		PlayerLv=<9999->2;
		true->3
    end.


%%根据阵营名词获取额外积分
%%@param RealmNo 阵营名次
%%@return 获取的积分
get_score_by_realm_no(RealmNo)->
	case RealmNo of
		1->30;
		2->15;
		3->0
	end.


%% 计算杀人兑换积分
get_kill_score(KillNum, OldScore) ->
   NewScore = if 
        KillNum =< 0 -> 0;
        KillNum =:= 1 -> 100;
        KillNum =:= 2 -> 180;
        KillNum =:= 3 -> 240;
        KillNum =< 6 -> 240+(KillNum-3)*30;
        KillNum =< 10 -> 310+(KillNum-6)*20;
        KillNum =< 25 -> 390+(KillNum-10)*10;
        KillNum =< 50 -> 540+(KillNum-25)*5;
        KillNum =< 100 -> 540+(KillNum-50)*2;
        true -> 765
    end,
    AddScore = round(NewScore - OldScore),
    {NewScore, AddScore}.

%% 计算助攻兑换积分
get_assist_score(AssistNum, OldScore) ->
	NewScore = 
    if 
        AssistNum =< 0 -> 0;
        AssistNum =:= 1 -> 50;
        AssistNum =:= 2 -> 90;
        AssistNum =:= 3 -> 120;
        AssistNum =< 6 -> 120+(AssistNum-3)*15;
        AssistNum =< 10 -> 155+(AssistNum-6)*10;
        AssistNum =< 25 -> 195+(AssistNum-10)*5;
        AssistNum =< 50 -> 270+(AssistNum-25)*2;
        true -> 320
    end,
    Add_Score = round(NewScore-OldScore),
    {NewScore, Add_Score}.

%% 击杀连斩积分加成
get_kill_continuous_score(X,OldScore) -> 	
	Add_Score = if 
		X =:= 0 -> 0;
		X =< 5 -> round((X*X-2*X+5)/2); 
		true -> round((X-4)*100/(X+8))
	end,
	_NewScore = OldScore + Add_Score,
	NewScore = 
	case _NewScore >= 300 of 
		true ->
			300;
		false ->
			_NewScore
	end,
	{NewScore, NewScore-OldScore}.

	

%% 击杀boss或者npc的积分加成
get_kill_bossnpc_score(NpcTypeId) ->
	case NpcTypeId of 
		12001 -> {1,0, 60};
		12002 -> {1,0, 80};
		12003 -> {1,0, 60};
		12004 -> {1,0, 80};
		12000 -> {2,100, 60};
        12010 -> {2, 100, 60};
		_-> {0, 0, 0}
	end.

%% 取boss的Id和地点
get_boss_id_position(BossTurn) ->
    case BossTurn of 
        1 -> {12000, 8, 53};
        2 -> {12010, 43, 17};
        _ -> 
            Rand = util:rand(1, 2),
            if 
                Rand =:= 1 -> {12000, 8, 53};
                Rand =:= 2 -> {12010, 43, 17}
            end
    end.


%% boss掉落宝箱归属
get_boss_own(Mid) ->
	case Mid of 
		12000 -> 1;
		12010 -> 2
    end.
		

%% 宝箱掉落位置
get_box_position(X,Y) ->
	Rand = util:rand(1,3),
	[{X+Rand,Y+Rand},{X-Rand,Y+Rand},{X,Y+Rand}].
