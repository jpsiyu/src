%%------------------------------------------------------------------------------
%% @Module  : battle
%% @Author  : zzm
%% @Email   : ming_up@163.com
%% @Created : 2012.6.20
%% @Description: 战斗定义
%%------------------------------------------------------------------------------

%% 保存助攻列表的场景id
-define(SET_HURT_LIST_SCENE_LIST, [120]).

%% 战斗所需的属性
-record(battle_status, {
        id = 0,
        platform = "",
        server_num = 0,
        node = none,
        mid = 0,
        owner_id=0,
        boss = 0,
        name = "",
        career = 0,
        scene = 0,              %%所属场景
        copy_id = 0,            %%所属副本
        hp = 0, 
        hp_lim = 0,
        mp = 0, 
        mp_lim = 0,
        ice_hp = 0,
        ice_type = 0, 
        anger = 0,
        anger_lim = 0,
        att,                %% 攻击力
        ex_att = 1,         %% 额外攻击力(宠物攻击力等)
        def,                %% 防御值
        x,                  %% 默认出生X
        y,                  %% 默认出生y
        move_x = 0,         %% 位移x
        move_y = 0,         %% 位移y
        att_area = 0,       %% 攻击范围 
        immune_effect = 0,  %% 免疫特效
        immune_hurt   = 0,  %% 免疫伤害
        parry = 0,          %% 是否被点穴
        sid = none,         %% 玩家进程
        speed = 0,          %% 行走速度
        skill_status = {0, 0},  %% 人物技能状态（1移动施法状态，2持续施法状态） 
        battle_status = [],    %% 战斗状态
        ex_battle_status = [], %% 额外的战斗状态(宠物技能等)
        ex_skill_id = 0,    %% 额外触发的技能id
        effect_list   = [], %% 效果表现列表[{类型，持续时间，值}...]
        sign = 0,           %% 标示是怪还是人 1:怪， 2：人
        hit = 0,
        dodge = 0,
        crit = 0,
        ten = 0,
        fire = 0,           
        ice = 0,            
        drug = 0,
        hurt_add_num = 0,
        hurt_del_num = 0,
        combat_power = 0,        
        unyun = 0,          %% 抗晕
        unbeat_back = 0,    %% 抗击退
        unholding   = 0,    %% 抗拉
        unmove_time = 0,    %% 不能行走持续时间
        uncm = 0,           %% 抗沉默
        hurt_list = [],     %% 伤害加成列表
        hurt_del_list = [], %% 伤害减免列表
        buff_list = [],
        ftsh = [0, 0],           %% 反弹伤害
        suck_blood = [0, 0],     %% 吸血
        hate = 0,                %% 技能仇恨值
        shield = 0,              %% 法盾
        blink = 0,               %% 瞬间移动
        skill = [],
        skill_cd = [],
        skill_owner = [],
        pk_status,
        guild_id,
        friend_gids = [],
        realm,
        pk_value = 0,
        pid_team,
        kf_teamid = 0,
        lv = 1,
        act = 1,            %% 动作
        is_husong = 0,      %% 是否在护送中(0:否; >0:是)
        group = 0,          %% 战场阵营分组
        kind = 0,           %% 怪物类型
        visible = 0,        %% 可见性
        factionwar_stone = 0, %% 帮派水晶属性，现在用于城战中的某种攻击模式
        is_be_atted = 1,      %% 是否被攻击
        del_hp_each_time = 0, %% 每次被攻击怪物扣取血（0无效，>0每次扣除的血量）
        restriction = 0       %% 阴阳相克
    }).

%% 战斗信息回传
-record(battle_return, {
	hp = 0,                 %% 防守方hp
	anger = 0,              %% 防守方怒气
	hurt = 0,               %% 防守方受到的伤害
	x = 0,                  %% 防守方x位移
	y = 0,                  %% 防守方y位移
	shield = 0,             %% 防守方盾血量
	battle_status = [],     %% 防守buff列表
	hate = 0,               %% 防守方对攻击方的仇恨值
	sign = 0,               %% 攻击方类型
	hit_list = [],          %% 助攻列表
	is_calc_hurt = 1,       %% 是否计算伤害(0不算,1算)
	atter = []              %% 攻击方数据 #battle_return_player{} | #battle_return_mon{}
}).

%% 攻击方信息
-record(battle_return_atter, {
	id = 0,                 %% 攻击者id
	platform = [],          %% 攻击者平台
	server_num = 0,         %% 攻击者服数
	node = none,            %% 攻击者所在节点
	mid  = 0,               %% 怪物资源id
	pid = none,             %% 攻击者进程id
	name = [],              %% 攻击者名字
	pid_team = none,        %% 攻击者队伍信
	att_time = 0,           %% 攻击者攻击时刻
	guild_id = 0 			%% 帮派id
}).
