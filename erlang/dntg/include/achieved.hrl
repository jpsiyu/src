%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-2-4
%% Description: 成就,称号 ets
%% --------------------------------------------------------

-define(ETS_CHENGJIU, ets_chengjiu).                    %% 成就列表
-define(ETS_CHENGJIU_AWARD, ets_chengjiu_award).        %% 成就奖励列表
-define(PLAYER_CHENGJIU, player_chengjiu).              %% 角色成就列表

-define(sql_chengjiu_insert, "insert into `chengjiu` set role_id=~p, chengjiu_id=~p, type=~p, count=~p, time=~p ").
-define(sql_update_cjpt, "update `player_pt` set cjpt = cjpt + ~p where id = ~p ").
-define(sql_chengjiu_update, "update `chengjiu` set count=~p, time=~p where role_id=~p and chengjiu_id=~p ").
-define(sql_chengjiu_select, "select role_id,chengjiu_id,type,count,time from `chengjiu` where role_id=~p ").
-define(sql_chengjiu_award_select, "select role_id,award_id,time from `chengjiu_award` where role_id=~p ").
-define(sql_cjpt_select, "select id,cjpt from `player_pt` where id=~p limit 1 ").
-define(sql_update_fix_chengjiu, "update `player_state` set `fix_chengjiu`=0 where `id` = ~p ").
-define(sql_chengjiu_award_insert, "insert into `chengjiu_award` set role_id=~p, award_id=~p, time=~p ").

%% 角色称号
-record(role_achieved_name, {
        id = 0,             %% 角色Id * 1000000 + 称号Id
        role_id = 0,        %% 角色Id
        name_id = 0,        %% 称号Id
        type1 = 0,          %% 类型1
        type2 = 0,          %% 类型2
        is_display = 0,     %% 是否显示(0不显示/1显示)
        get_time = 0        %% 获得时间
    }).

-record(achieved_name, {
        name_id = 0,        %% 称号Id
        name = <<>>,        %% 称号名
        type1 = 0,          %% 称号类型1
        type2 = 0,          %% 称号类型2
        sex_limit = 0,      %% 性别限制（0不限）
        display = 0,        %% 显示类型（0不可显示/1可显示）
        max_show_time = 0,  %% 最大显示时间
        chat_show = 0,      %% 是否在聊天窗口显示称号（0不显示/1显示）
        notice = 0,         %% 通知方式（0不通知/1提示/2传闻）
        swf_show = 0,       %% 是否Flash效果（0否/1是）
        describe = <<>>,    %% 达成条件描述
        hp = 0,             %% 气血
        mp = 0,             %% 内力
        att = 0,            %% 攻击
        def = 0,            %% 防御
        hit = 0,            %% 命中
        dodge = 0,          %% 闪避
        crit = 0,           %% 暴击
        ten = 0,            %% 坚韧
        res = 0             %% 全抗
    }).

%% 成就配置
-record(base_chengjiu, {
        id = 0,             %% 成就ID
        type = 0,           %% 类型
        type_id = 0,        %% 类型ID，如物品ID，任务ID...
        type_list = 0,      %% 类型ID列表，如物品ID列表，任务ID列表...
        lim_num = 0,        %% 限制数量
        is_count = 0,       %% 是否要统计
        count_span = 0,     %% 统计间隔
        ratio = 0,          %% 机率
        name_id = 0,        %% 称号
        cjpt = 0            %% 成就声望
    }).

%% 成就奖励配置
-record(base_chengjiu_award, {
        id = 0,             %% 奖励ID
        lim_list = [],      %% 成就限制
        lim_chengjiu = 0,   %% 成就声望限制
        attr_id = 0,        %% 奖励属性ID
        attr_value = 0,     %% 奖励属性值
        goods_id = 0,       %% 奖励物品类型ID
        goods_num = 0,      %% 奖励物品数量
        bind = 0            %% 绑定状态
    }).

%% 成就列表
-record(ets_chengjiu, {
        id = {0,0},         %% {角色ID,成就ID}
        type = 0,           %% 成就类型
        count = 0,          %% 统计数量
        time = 0            %% 完成时间
    }).

%% 成就奖励列表
-record(ets_chengjiu_award, {
        id = {0,0},         %% {角色ID,奖励ID}
        time = 0            %% 完成时间
    }).

%% 角色成就声望列表
-record(player_chengjiu, {
        id = 0,             %% 角色ID
        cjpt = 0            %% 成就声望
    }).
