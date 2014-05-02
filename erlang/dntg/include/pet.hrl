%%%------------------------------------------------
%%% File    : pet.hrl
%%% Author  : zhenghehe
%%% Created : 2012-01-12
%%% Description: 宠物record
%%%------------------------------------------------
%%------------------------------宠物宏定义-------------------------------
-define(PET_UPDATE_TIMES, 1000). %定时器检测周期
%%------------------------------宠物宏定义--------------------------------
%% 宠物物品配置
-record(base_goods_pet, {
        id = 0,                                                 % 物品类型ID
        name = <<>>,                                            % 物品名称
        base_aptitude = 0,                                      % 基础资质      %%手机版修改
        extra_aptitude_max = 0,                                 % 额外资质上限  %% 修改
	    aptitude_ratio = 0,					                    % 资质概率
        growth_min = 0,                                         % 成长下限
        growth_max = 0,                                         % 成长上限
        effect = 0,                                             % 物品效用
        probability = 0,                                        % 商城出现的概率
        sell = 0,                                               % 是否商城出售
        type = 0,                                               % 类型
        subtype = 0,                                            % 子类型
        color = 0,                                              % 品阶
        price = 0,                                              % 价格
        level = 0,                                              % 级别
        expire_time = 0                                         % 失效时间
    }).

%% 宠物幻化物品配置
-record(base_goods_figure, {
	  id = 0,				    % 物品类型ID
	  figure_id = 0,			% 形象ID
	  type = 0,                 % 类型
	  subtype = 0,              % 子类型
	  last_time = 0,            % 持续时间
	  figure_attr = [],			% 附加属性
	  activate_value = 0		% 激活增加幻化值
	  }).

%% 宠物
-record(player_pet, {
        id = 0,                                                 % 宠物ID
        name = <<>>,                                            % 宠物名称
        player_id = 0,                                          % 角色昵称
        type_id = 0,                                            % 宠物类型ID
	    origin_figure = 0,					                    % 原始宠物形象
        figure = 0,                                             % 现在宠物形象
	    change_flag = 0,					                        % 是否有幻化，0 没有， 1 有
	    figure_type = 0,					                        % 0永久幻化 1限时幻化
	    figure_expire_time = 0,			                        % 形象过期时间
        nimbus = 0,                                             % 光环
        level = 0,                                              % 等级
        base_aptitude = 0,                                      % 基础资质        %%手机版
        extra_aptitude = 0,                                     % 额外资质        手机版
        extra_aptitude_max = 0,                                 % 额外资质上限    手机版
        quality = 0,                                            % 品阶
        forza = 0,                                              % 力量
        wit = 0,                                                % 灵力
        agile = 0,                                              % 身法
        thew = 0,                                               % 体质
        base_addition = [],                                     % 基础属性加成
        forza_scale = 0,                                        % 力量成长
        wit_scale = 0,                                          % 灵力成长
        agile_scale = 0,                                        % 身法成长
        thew_scale = 0,                                         % 体质成长
        last_forza_scale = 0,                                   % 力量成长
        last_wit_scale = 0,                                     % 灵力成长
        last_agile_scale = 0,                                   % 身法成长
        last_thew_scale = 0,                                    % 体质成长
        growth = 0,                                             % 成长
        growth_exp = 0,                                         % 成长经验
        maxinum_growth = 0,                                     % 成长上限
        strength = 0,                                           % 快乐值
        strength_threshold = 0,                                 % 快乐值上限
        fight_flag = 0,                                         % 放出标志位 1放出 0收回
        fight_starttime = 0,                                    % 放出时间
        upgrade_exp = 0,                                        % 升级经验
        create_time = 0,                                        % 创建时间
        pet_attr = [],                                          % 宠物加成属性[气血,内力,攻击,防御,命中,躲避,暴击,坚韧]
        potentials = [],                                        % 宠物潜能列表
        pet_potential_attr = [],                                % 宠物潜能加成属性
        pet_potential_phase_addition = [],                      % 宠物潜能阶段加成
        skills = [],                                            % 宠物技能
        pet_skill_attr = [],                                    % 宠物技能加成属性
        name_upper = <<>>,                                      % 转换成大写后的宠物名称
        strength_nexttime = 0,                                  % 下次同步快乐值时间
        base_aptitude_attr = [],
        combat_power = 0                                        % 战斗力
    }).

%% 宠物潜能配置
-record(ets_base_pet_potential, {
        id = 0,                   % 潜能类型ID
        lv = 0,                   % 默认等级
        name = <<>>               % 潜能名称
    }).

%% 宠物潜能
-record(pet_potential, {
        pet_id = 0,               % 宠物ID
        potential_type_id = 0,    % 潜能类型ID
        location = 0,             % 位置
        lv = 0,                   % 等级
        exp = 0,                  % 经验
        name = <<>>,              % 潜能名称
        create_time = 0           
    }).

%% 宠物技能
-record(pet_skill, {
        id = 0,                         % 记录ID
        pet_id = 0,                     % 宠物ID
        type_id = 0,                    % 物品类型ID
        level = 0,                      % 级别
        type = 0                        % 技能类型 0 被动类 1 触发类 2主动技能
    }).

%%==================================新版宠物砸蛋==========================================================
-define(ETS_EGG_INFO, ets_egg_info).    %% ets表名
-define(ETS_EGG_KEY, ets_egg_key).      %% key
-define(EGG_KEY(Id), lists:concat(["egg_", Id])).

%% 玩家宠物砸蛋日志
-record(pet_egg_log, {
        role_id = 0,                    %% 玩家id
        egg_cd = [],                    %% 蛋的类型cd
        get_good = [],                  %% 获得物品id
        time = 0                        %% 时间
    }).

%% 玩家砸蛋公告
-record(egg_log_notice, {
        key = ?ETS_EGG_KEY,             %% key
        notice_list = []                %% 玩家砸蛋记录公告[{role_id, name, egg_type, good_id, num}]
    }).


%% 宠物砸蛋福利
-record(pet_egg, {
        egg_type = 0,                   %%  蛋的类型(唯一标示1:银蛋,2:金蛋,3:彩蛋)
        money_type = 0,                 %%  砸蛋消耗的货币类型，1代表铜币，2代表元宝（可使用绑定，优先扣除）
        used_price = 0,                 %%  砸蛋消耗的货币数量
        used_price2 = 0,                %%  砸蛋消耗的货币数量(10次)
        cd_time = 0,                    %%  免费砸蛋的间隔时间,填0表示不能免费砸蛋，彩蛋不能免费砸
        base_goods = [],                %%  保底物品
        goods_list = [],                %%  砸蛋获得的物品, [{lv1, lv2, [GoodsId,...]},{...}...]
        save_count = 0,                 %%  保底回合次数
        save_goods_list = []            %%  保底获得物品回合必定获得该物品, [{lv1, lv2, [GoodsId,...]}, {...},...]
                                        %%  解释：[{等级1, 等级2, [物品id,...]},...]
    }).


%%　砸蛋物品
-record(pet_egg_goods, {
        good_id = 0,              %% 物品id
        egg_type = 0,             %% 蛋的类型(唯一标示1:银蛋,2:金蛋,3:彩蛋)
        type = 0,                 %% 类型，0 普通物品，1 高级物品
        bind = 0,                 %% 是否绑定 0绑定，1非绑定
        notice = 0,               %% 通告类型，0 普通，1 全服
        rate = 0,                 %% 概率
        lim_num = 0,              %% 次数限制，至少N次才能出来匹配    
        lv = []                   %% 物品的对应的等级范围  , [1, 49]
    }).
















