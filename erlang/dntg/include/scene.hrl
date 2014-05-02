%%%------------------------------------------------
%%% File    : scene.hrl
%%% Author  : xyao
%%% Created : 2011-07-15
%%% Description: 场景管理器
%%%------------------------------------------------

-define(ETS_SCENE, ets_scene).                                  %% 场景
-define(TABLE_AREA(Id, CopyId),  {Id, 0, CopyId}).          %% 9宫格保存

%%写死出生点的副本（因为有些副本把传送点当做退出副本，所以进去副本写死出生点）.
-define(DUNGEON_SCENE_BORN, [233,465,500,561,562,630]).

%%需要体力值的副本场景 
%% change by xieyunfei
%% -define(DUNGEON_SCENE_PHYSICAL, [233,300,500,561,562,650]).
-define(DUNGEON_SCENE_PHYSICAL, []).

%% 禁止用12005传送的场景.
%% 南天门-420,VIP挂机-430,爱情长跑-990
%% 温泉-231,232,蝴蝶谷-450,竞技场-223,帮战-106,帮派场景-105,钓鱼-451,蟠桃会-440.
-define(FORBID_ENTER_SCENE_LIST, [420, 430, 990, 231, 232, 450, 223, 106, 105, 451, 440]).

%%需要全场景广播的场景 
-define(ALLBRO, [2,6]).
-define(ALLBRO_ID, [434, 251]).

%% 场景类型定义.
-define(SCENE_TYPE_NORMAL, 0).  %% 普通场景.
-define(SCENE_TYPE_OUTSIDE, 1). %% 野外场景.
-define(SCENE_TYPE_DUNGEON, 2). %% 副本场景.
-define(SCENE_TYPE_GUILD, 3).   %% 帮会场景.
-define(SCENE_TYPE_SAFE, 4).    %% 安全场景.
-define(SCENE_TYPE_ARENA, 5).   %% 竞技场景.
-define(SCENE_TYPE_TOWER, 6).   %% 爬塔场景.
-define(SCENE_TYPE_BOSS, 7).    %% Boss场景.
-define(SCENE_TYPE_ACTIVE, 8).  %% 活动场景（黄金沙滩，蝴蝶谷）.
-define(SCENE_TYPE_CLUSTERS, 9).  %% 跨服场景.

-record(scene_user_pet, {
        pet_figure = 0,                    
        pet_nimbus = 0,                    
        pet_name = [],                      
        pet_level = 0,
        pet_quality = 0
    }).

-record(scene_user_sit, {
        sit_down = 0,                       % 打坐，值大于0表示在打坐中，1打坐，2双修
        sit_role = 0                        % 双修角色ID
    }).

-record(scene_user_husong, {
        husong_lv = 0,
        husong_npc = 0,
        husong_pt = 0
    }).

-record(scene_user_pk, {
        pk_status = 0,
        pk_value
    }).

-record(battle_attr, {
        att = 0,                %% 攻击力
        def = 0,                %% 防御值
        att_area = 0,           %% 攻击范围 
        hit   = 0,
        dodge = 0,
        crit = 0,
        ten  = 0,
        fire = 0,           
        ice  = 0,            
        drug = 0,
        hurt_add_num = 0,
        hurt_del_num = 0,
        combat_power = 0,
        skill = [],
        medal_skill = [],      %% 勋章技能
        battle_status = [],    %% 战斗状态
        ex_battle_status = [], %% 额外战斗状态(宠物等)
        skill_cd      = [],    %% 技能cd
        skill_status  = {0, 0},%% {技能施法状态(0无状态,1移动施法状态,2定点持续施法状态), 状态结束时间(ms)}
        hit_list      = []     %% 攻击者列表[{玩家id, 攻击的时间(ms)}..]
    }).

%%竞技场状态
-record(scene_user_arena, {
        continues_kill=0
    }).

%%蟠桃园状态
-record(scene_user_peach, {
        peach_num=0
    }).

%% 场景用户数据
%% 只保留场景所需的信息
-record(ets_scene_user, {
        id = 0,                        %% 用户ID
        nickname = [],                 %% 玩家名
        sex = 0,                       %% 性别 1男 2女
        lv = 1,                        %% 等级
        scene = 0,                     %% 场景id
        copy_id = 0,                   %% 副本id
        guild_id = 0,                  %% 帮派id
        guild_name = [],               %% 帮派名字
        guild_position = 0,            %% 帮派职位
        node=none,                     %% 来自节点
        platform = "",                 %% 平台标示
        server_num = 0,                %% 所在的服标示
        sid = {},                      %% 玩家发送消息进程
        pid = 0,                       %% 玩家进程
        x = 0,                         %% X坐标
        y = 0,                         %% Y坐标
        hp = 0,                        %% 气血
        hp_lim = 0,                    %% 气血上限
        mp = 0,                        %% 内力
        mp_lim = 0,                    %% 内力上限
        anger = 0,                     %% 怒气值
        anger_lim = 0,                 %% 怒气上限
        ice_hp = 0,                    %% 冰冻额外血量
        leader = 0,                    %% 是否队长
        pid_team = 0,                  %% 组队进程id
        pet = #scene_user_pet{},       %% 宠物数据
        sit = #scene_user_sit{},       %% 打坐数据
        equip_current = [],            %% 衣服
        fashion_weapon = [0,0],        %% 穿戴的武器时装 - [武器时装类型ID，武器时装强化数]
        fashion_armor = [0,0],         %% 穿戴的衣服时装 - [衣服时装类型ID，衣服时装强化数]
        fashion_accessory = [0,0],     %% 穿戴的饰品时装 - [饰品时装类型ID，饰品时装强化数]
        fashion_head = [0,0],
        fashion_tail = [0,0],
        fashion_ring = [0,0],
        hide_fashion_armor = 0,        %% 是否隐藏衣服时装，1为隐藏
        hide_fashion_accessory = 0,    %% 是否隐藏饰品时装，1为隐藏
        hide_fashion_weapon = 0,       %% 是否隐藏武器时装，1为隐藏
        hide_head = 0,                 % 是否隐藏头时装，1为隐藏
        hide_tail = 0,                 % 是否隐藏尾时装，1为隐藏
        hide_ring = 0,                 % 是否隐藏戒指时装，1为隐藏
        career = 0,                    %% 职业
        realm = 0,                     %% 国家，阵营
        group = 0,                     %% 战斗分组（目前为竞技场阵营）
        design = [],     	           %% 称号列表
        fly_mount = 0,                 %% 飞行坐骑id
        speed = 0,                     %% 玩家速度
        mount_figure,                  %% 坐骑形象
        fly = 0,                       %% 飞行
        flyer = 0,                     %% 飞行器
        flyer_figure = 0,	           %% 飞行器形象
        flyer_sky_figure = 0,	       %% 九重天形象
        vip_type,                      %% vip类型
        husong = #scene_user_husong{}, %% 护送数据
        factionwar_stone = 0,          %% 帮派战水晶
        collect_pid = {0, 0},          %% 采集的怪物的{进程pid, mid}
        battle_attr = #battle_attr{},  %% PK状态
        pk = #scene_user_pk{} ,        %% PK值
        figure = 0,                    %% 形象
        qiling = 0,					   %% 器灵形象
        suit_id = 0,                   %% 当前装备全套的套装ID
        stren7_num = 0,                %% 当前身上装备加7以上的装备数量
        arena = #scene_user_arena{},   %% 竞技场
        peach = #scene_user_peach{},   %% 蟠桃园
        parner_id = 0,                 %% 伴侣ID
        marriage_parner_id = 0,        %% 结婚伴侣ID
        marriage_register_time = 0,    %% 结婚时间
        is_cruise = 0,                 %% 是否在巡游状态中 0.否 1.是
        guild_rela = {[],[]},          %% 同盟帮派列表
        image =0,                      %% 头像
        visible = 0,                   %% 是否可见 0:可见 1:不可见
        kf_teamid = 0,                 %% 跨服组队
        body_effect = 0,
        feet_effect = 0
    }).

%% 场景数据结构
-record(ets_scene,
    {
        id = 0,              %% 场景ID包括资源id
        worker = 0,          %% 工作进程编号
        name = <<>>,         %% 场景名称
        type = 0,            %% 场景类型(0:安全场景, 1:野外场景, 2:副本场景)
        x = 0,               %% 默认开始点
        y = 0,               %% 默认开始点
        elem=[],             %% 场景元素
        requirement = [],    %% 进入需求
        mask = "",
        npc = [],
        mon = [],
        jump = [],
        sid = 0,
        width = 0,
        height = 0
    }
).


%% 场景怪物 - 任务用
-record(ets_scene_mon,
    {
        id = 0,              %% 怪物ID
        scene = 0,           %% 场景
        name = <<>>,         %% 场景名称
        mname = <<>>,        %% 怪物名字
        kind = 0,            %% 怪物类型
        x = 0,               %% X坐标
        y = 0,               %% Y坐标
        lv = 0,              %% 怪物等级
        out = 0              %% 是否挂机
    }
).


-record(ets_mon, {
        id = 0,
        name = <<>>,
        kind = 0,        %%0 怪物，1采集物品，2旗子，3矿点
        boss = 0,        %%0普通怪，1野外BOSS，2宠物BOSS，3世界BOSS，4帮派BOSS，5副本BOSS，6爬塔BOSS，7塔防BOSS
        career = 0,
        auto,            %% 0读取默认属性，1动态根据公式生成属性
        scene,           %% 所属场景唯一
        copy_id,         %% 副本id
        mid,             %% 怪物类型ID
        icon = 0,        %% 资源id
        lv,
        hp,
        hp_lim,
        mp,
        mp_lim,
        hp_num,          %% 回血数值
        mp_num,          %% 回魔数值
        att,             %% 攻击
        def,             %% 防御值
        speed,           %% 移动速度
        att_speed,       %% 攻击速度
        hit = 0,         %% 命中
        dodge = 0,       %% 躲避
        crit = 0,        %% 暴击
        ten = 0,         %% 坚韧
        fire = 0,        %% 火
        ice = 0,         %% 冰
        drug = 0,        %% 毒
        unyun = 0,       %% 抗晕
        unbeat_back = 0, %% 抗击退
        unholding = 0,   %% 抗拉
        uncm = 0,        %% 抗沉默
        skill = [],      %% 技能
        now_skill = [],  %% 现在的持有技能
        skill_owner = [],%% 表示怪物属于技能触发（召唤追踪类技能），当此怪物杀死对方时，与施法方杀死对方效果同等, 值={Id, Platform, SerNum, Pid, Node, TeamPid}
        skill_cd = [],	 %% 存放怪物释放过技能的cd
        att_area,        %% 攻击范围
        trace_area,      %% 追踪范围
        beat_back,       %% 击退
        x,               %% 当前X
        y,               %% 当前Y
        d_x,             %% 默认出生X
        d_y,             %% 默认出生y
        aid = none,      %% 怪物活动进程
        retime,          %% 重生时间
        type = 0,        %% 怪物战斗类型（0被动，1主动）
        exp=0,           %% 怪物经验
        llpt=0,          %% 怪物掉落历练声望
        coin=0,          %% 怪物掉落铜钱
        drop_goods,      %% 怪物可掉落物品[{Goodsid1, DropRate1}, {Goodsid2, DropRate2}, ...]
        battle_status = [],     %% 战斗状态
        att_type = 0,           %% 0近战，1远程
        drop = 0,               %% 掉落方式
        drop_num = 0,           %% 掉落计算次数
        out = 0,                %% 是否挂机
        group = 0,              %% 怪物阵营id: 帮派类型为帮派ID、争夺战为阵营ID
        realm = 0,              %% 镖车所属国家
        path = [],              %% 自动行走路径
        path_no = 0,            %% 路径编号(1|2|3..)
        owner_id = 0,       %% 拥有者
        color = 0,          %% 颜色属性
        ai_type = 0,        %% 怪物AI类型
        ai_option = [],     %% 怪物AI配置
        collect_time = 0,   %% 采集怪物的采集时间
        collect_count = 0,  %% 采集怪物的可采集次数
        collect_times = 0,  %% 已经被采集次数
        event = [],         %% 怪物ai事件
        skip  = 0,          %% 炼狱副本的跳层属性
        restriction = 0,    %% 阴阳相克属性
        is_fight_back = 1,  %% 是否会反击
        is_be_atted   = 1,  %% 是否可攻击
        is_be_clicked = 1,  %% 是否可被点击
        del_hp_each_time = 0,  %% 每次被攻击怪物扣取血（0无效，>0每次扣除的血量）
        change_player_id = 0   %% 怪物变身为玩家的玩家id
    }).

-record(ets_npc, {
        id = 0,           %% 是唯一id又是资源id
        func = 0,         %% 功能
        icon = 0,         %% 资源
        image = 0,        %% 头像
        name,
        scene,
        sname = <<>>,
        x,
        y,
        talk,
        realm = 0
    }).


%%怪物召唤
-record(mon_call, {
        goods_id = 0,
        boss_id = 0,
        call_scene = 0,
        call_x_rand = 0,
        call_y_rand = 0,
        born_x_y = 0,
        livingtime=0
    }).

%% 所有场景的npc及怪物信息
-record(load_all_scene_info, {
        data = <<>>
    }).


%% 怪物活动进程state
-record(mon_act, {
        att = [],            %% 攻击对象[Key, Pid, AttType] AttType: 1怪物; 2玩家
        first_att = [],      %% 第一个攻击该怪物的玩家信息 [Key, Pid, AttType]
        minfo=[],            %% 怪物信息 ets_mon{}
        klist=[],            %% 伤害列表
        hate=[],             %% 仇恨列表
        clist = [],          %% 采集列表
        ref=[],              %% 普通定时器引用
        ready_ref=[],        %% 等待场景信息返回定时器引用
        eref = [],           %% 事件定时器引用
        last_att_player_id = 0, %% 最后攻击的玩家id(用于计算怪物被怪物杀死时的掉落)
        create_time = 0,     %% 创建时间
        begin_atted_time = 0 %% 开始被攻击的时间
    }
).
