%%%------------------------------------------------
%%% File    : guild.hrl
%%% Author  : zhenghehe
%%% Created : 2012-02-02
%%% Description: record
%%%------------------------------------------------ 

%% -----------------------------帮派进程字典KEY宏定义-------------------------------------GuildParty
-define(GUILD_INDEX_MEMBER, "Guild_Index_Member").         						%% 帮派索引_成员ID:帮派ID
-define(GUILD_MEMBER_INFO, "GuildMember_Info_").         						%% 帮派成员信息
-define(GUILD_APPLY, "GuildApply_").											%% 帮派申请
-define(GUILD_INVITE, "GuildInvite_").											%% 帮派邀请
-define(GUILD_SKILL, "Guild_Skill_").         									%% 帮派技能
-define(GUILD_SKILL_MEMBER, "Guild_Skill_Member_").         					%% 帮派成员个人技能
-define(GUILD_CONTACT_BOOK, "Contact_Book_").         							%% 帮派通讯录
-define(GUILD_ACHIEVED, "Guild_Achieved_").         							%% 帮派目标
-define(GUILD_GODANIMAL, "Guild_GodAnimal").         							%% 帮派神兽
-define(GUILD_PARTYL, "GuildParty").         									%% 帮派宴会
-define(GGATIMER, "GGATimer").         											%% 帮派神兽进程名字头
-define(GodAnimal_TIME_LAST, 15 * 100).         								%% 帮派神兽时间1
-define(GodAnimal_Level_Limit, 65).         									%% 帮派神兽时间2
-define(GUILD_SCENE, 105).         												%% 帮派场景ID
-define(FULIWUPI, 532252).         												
-define(FULIWUPI2, 532253).         											
-define(MFYJCS, 3).         													%% 免费摇奖次数
-define(GUILD_TOP_LEVEL, 15).         											%% 帮派等级上限

%% -----------------------------帮派record定义-------------------------------------

%% 帮派
-record(ets_guild, {
        id = 0,                        % 记录ID
        name = <<>>,                   % 帮派名称
        name_upper = <<>>,             % 帮派名称（大写）
		rename_flag = 0,               % 改名标记
        tenet = <<>>,                  % 帮派宣言
        announce = <<>>,               % 帮派公告
        initiator_id = 0,              % 创始人ID
        initiator_name = <<>>,         % 创始人名称
        chief_id = 0,                  % 现任帮主ID
        chief_name = <<>>,             % 现任帮主昵称
        deputy_chief1_id = 0,          % 副帮主1ID
        deputy_chief1_name = <<>>,     % 副帮主1昵称
        deputy_chief2_id = 0,          % 副帮主2ID
        deputy_chief2_name = <<>>,     % 副帮主2昵称
        deputy_chief_num = 0,          % 副帮主数
        member_num = 0,                % 当前成员数
        member_capacity = 0,           % 成员上限
        realm = 0,                     % 阵营
        level = 0,                     % 级别
        reputation = 0,                % 声望
        funds = 0,                     % 帮派资金
        contribution = 0,              % 建设值
        contribution_daily = 0,        % 每日收取的建设值
        contribution_threshold = 0,    % 建设值上限
        contribution_get_nexttime = 0, % 下次收取建设值时间
        leve_1_last = 0,               % 一级持续天数
        base_left = 0,        		   % 基本计数器
        qq = 0,                        % QQ群
        create_time = 0,               % 记录创建时间
        create_type = 0,               % 创建类型
        disband_flag = 0,              % 解散申请标记
        disband_confirm_time = 0,      % 解散申请的确认开始时间
        disband_deadline_time = 0,     % 掉级后的自动解散时间
        furnace_level = 0,             % 神炉等级
        mall_level = 0,                % 商城等级
        depot_level = 0,               % 仓库等级
        altar_level = 0,               % 祭坛等级
        hall_level = 0,                % 大厅等级
        house_level = 0,               % 厢房等级
        mall_contri = 0,               % 商城累积的建设度
        merge_guild_id = 0,            % 邀请合并的帮派ID
        merge_guild_direction = 0,     % 邀请合并的方向 0保留本帮 1解散本帮     
		gather_member_lasttime = 0,    % 帮主召唤最后时间
        furnace_growth = 0,            % 神炉成长
        mall_growth = 0,               % 商城成长
        depot_growth = 0,              % 仓库成长
        altar_growth = 0,               % 祭坛成长
        apply_setting = 1,             % 申请加入帮派设置,1.自动通过 2.拒绝所有人通过 3.需要审批通过
        auto_passconfig = []        % 自动通过加入帮派申请条件[最低等级,最低战力]
    }).

%% 个人帮战积分
-record(factionwar_info,{
    id = 0,                 %玩家ID
    war_score = 0,          %个人帮战战功
    war_score_used = 0,     %个人帮战
    war_last_score = 0,     %个人上场帮战战功
    last_kill_num = 0,      %上次帮战杀人记录
    war_add_num = 0,        %参加帮战次数
    war_last_time = 0       %上次参赛时间
}).

%% 帮派成员
-record(ets_guild_member, {
        id = 0,                       % 记录ID
        name = <<>>,                  % 角色昵称
        guild_id = 0,                 % 帮派ID
        guild_name = <<>>,            % 帮派名称
        donate_total = 0,             % 历史总贡献
        donate_total_card = 0,        % 建设令的历史总贡献
        donate_total_coin = 0,        % 铜钱的历史总贡献
        donate_lasttime = 0,          % 最后贡献时间
        donate_total_lastday = 0,     % 日贡献
        donate_total_lastweek = 0,    % 周贡献
        paid_get_lasttime = 0,        % 日福利最后获取时间
        create_time = 0,              % 记录创建时间
        title = <<>>,                 % 帮派称号
        remark = <<>>,                % 个人备注
        sex   = 0,                    % 性别
        honor = 0,                    % 荣誉
        jobs  = 0,                    % 职位
        level = 0,                    % 等级
        position = 0,                 % 帮派职位
        online_flag = 0,              % 是否在线
        last_login_time = 0,          % 最后登录时间
        career = 0,                   % 职业        
        depot_store_lasttime = 0,     % 帮派仓库最后存入物品时间
        depot_store_num = 0,          % 帮派仓库存入数量
        version = 0,                  % 乐观锁
        donate  = 0,                  % 贡献
        paid_add = 0,                 % 日福利增加
        image = 0,                    % 头像
        vip = 0,                      % VIP类型
        material = 0,                 % 帮派财富
		pray_times = 0,               % 祭坛祈福次数_每日清零?
        furnace_daily_back = 0,       % 神炉日返利,用于判断是否达到上限
		furnace_back = 0,             % 可领取的神炉返利,领取后清零
        factionwar = #factionwar_info{}   % 帮派战信息
    }).



%% 帮派申请
-record(ets_guild_apply, {
        id = 0,                       % 记录ID
        guild_id = 0,                 % 帮派ID
        player_id = 0,                % 角色ID
        player_name = <<>>,           % 角色昵称
        player_sex   = 0,             % 性别
        player_jobs  = 0,             % 职位
        player_level = 0,             % 等级        
        create_time = 0,              % 申请时间
        player_career = 0,            % 职业
        online_flag = 0,              % 线路
        player_vip_type = 0           % VIP类型
    }).

%% 帮派邀请
-record(ets_guild_invite, {
        id = 0,                       % 记录ID
        guild_id = 0,                 % 帮派ID
        player_id = 0,                % 角色ID
        create_time = 0               % 邀请时间
    }).


% 帮派技能
-record(ets_guild_skill, {
        id = {0, 0},        % key{帮派id，技能id} 
        guild_id = 0,       % 帮派id
        skill_id = 0,       % 技能id
        lv = 0              % 技能等级
    }).

% 帮派成员技能
-record(ets_guild_member_skill, {
        id = {0, 0},    % key{玩家技能， 技能id}
        player_id = 0,  % 玩家id
        skill_id = 0,   % 技能id
        lv = 0,         % 技能等级
        active_time = 0,% 激活时间
        active = 0      % 是否激活（1为激活，0为没有激活）
    }).

