%%%------------------------------------------------
%%% File    : skill.hrl
%%% Author  : xyao
%%% Created : 2011-12-13
%%% Description: 技能
%%%------------------------------------------------

-define(WARRIOR_BASE_SKILL_ID,  100101).
-define(MAGE_MON_BASE_SKILL_ID, 200101).
-define(ASSASIN_BASE_SKILL_ID,  300101).
-define(MON_BASE_SKILL_ID,      400101).
-define(MON_BASE_SKILL_LV, 1).


%% 技能等级数据
-record(skill_lv_data, {
        learn_condition = [], %% 学习条件
        use_condition   = [], %% 使用条件
        combat_power    = 0,  %% 增加的战斗力
        area            = 0,  %% 每级的攻击范围
        distance        = 0,  %% 攻击距离
        att_num         = 0,  %% 攻击人数
        data            = []  %% 效果数据
    }).

%% 技能
-record(player_skill, {
        skill_id = 0,     % 技能id
        name = <<>>,      % 技能名字
        lv = 1,           % 等级
        career = 0,       % 职业
        type = 0,         % 技能类型:(1主动，2被动，3辅助，4副技能)
        obj = 0,          % 释放目标(1自己，2攻击目标，3选择单体目标，4选择坐标)
        mod = 0,          % 技能模式(1单体攻击，2群体攻击)
        aoe_mod = 0,      % 群攻选取模式(1矩形群体攻击，2直线群体攻击，3前方矩形群攻，4后背矩形群攻)
        cd = 0,           % CD时间
        attime = 0,       % 攻击次数，如攻击2次
        limit = [],       % 限制使用的技能有
        pro = 0,          % 附加成功概率
        stack = 0,        % buff叠加次数
        status = 0,       % 技能状态: 1移动施法状态, 2持续施法状态, 技能释放时间(下方的use_time)结束，则状态结束
        use_time = 0,     % 技能释放时间
        skill_link = [],  % 连接技能
        combo_skill = [], % 副技能[{下个技能id, 延迟(ms)}...]
        base_effect_id = 0, % 基础特效
        is_calc_hurt   = 1, % 是否计算伤害，默认1；1是, 0否
        data = #skill_lv_data{} % 技能等级数据
    }).
