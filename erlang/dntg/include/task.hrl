%%%--------------------------------------
%%% @Module  : task.hrl
%%% @Author  : zhenghehe
%%% @Created : 2012.02.04
%%% @Description : 任务record
%%%--------------------------------------
%%-------------------------------任务ETS宏定义--------------------------------
-define(ETS_ROLE_TASK, ets_role_task).                          %% 已接任务
-define(ETS_ROLE_TASK_LOG, ets_role_task_log).                  %% 已完成任务
-define(ETS_ROLE_TASK_AUTO, ets_role_task_auto).                %% 委托任务
-define(ETS_TASK_QUERY_CACHE, ets_task_query_cache).            %% 当前所有可接任务
-define(ETS_TASK_CUMULATE, ets_task_cumulate).                  %% 经验累积任务历史日志
%%-------------------------------任务ETS宏定义---------------------------------
-define(FLY_TASK, [100481, 100610, 101310]).
-define(FLY_MOUNT_SPEED, 150).

-define(TASK_SR_TRIGGER, 1).                                    %% 已接平乱任务
-define(TASK_SR_ACTIVE, 0).                                     %% 可接平乱任务

-define(XS_HUSONG_TASK, [100870,101070,101580]).                %% 新手护送任务
-define(XS_HUSONG_NPC, 23).                                     %% 新手护送任务NPC
-define(KILL_AVATAR_TASK, [200160]).                            %% 击败NPC分身任务

-define(HS_TIME_OUT, 24 * 60 * 60).                             %% 护送任务失效时间
-define(HS_DOUBLE_START, 20 * 60 * 60).                         %% 财神奖励启动时间 8:00(修改时候请记得修改timer_husong)
-define(HS_DOUBLE_OVER,  20 * 60 * 60 + 30 *60).                %% 财神奖励结束时间 8:30
-define(HS_INTER_TIMES,  3).                					%% 每日劫镖次数限制
-define(HS_GUOYUN_TIME,  30*60).                                %% 双倍时间
-define(HS_PROTECT_TIME, 15).                                   %% 护送保护时间
-define(EB_NEXT_REF_TIME, 30*60).                               %% 皇榜任务刷新时间

-define(SQL_SELECT_TASK_HIS, <<"select `offline_day`,`last_finish_time`,`cucm_exp` from `task_his` where `role_id`=~p and `task_id`=~p limit 1">>).
-define(SQL_INSECT_UPDATE_TASK_HIS, <<"insert into `task_his` set `role_id`=~p, `task_id`=~p, `offline_day`=~p, `last_finish_time`=~p, `cucm_exp`=~p ON DUPLICATE KEY UPDATE `offline_day`=~p,`last_finish_time`=~p,`cucm_exp`=~p">>).
-define(SQL_UPDATE_TASK_HIS, <<"update `task_his` set `offline_day`=~p,`last_finish_time`=~p,`cucm_exp`=~p where `role_id`=~p and `task_id`=~p">>).

%% 任务数据
-record(task,
    {
        id
        ,role_id
        ,name = <<"">>
        ,desc = <<"">>			                                %% 描述
        %% 部分限制条件
        ,class = 0                                              %% 任务分类，0普通任务，1运镖任务，2帮会任务
        ,type = 0				                                %% 类型
        ,kind = 0				                                %% 种类
        ,level = 1				                                %% 需要等级
        ,repeat = 0				                                %% 可否重复
        ,realm = 0                                              %% 阵营
        ,career = 0				                                %% 职业限制
        ,prev = 0				                                %% 上一个必须完成的任务id
        ,proxy = 0                                              %% 是否可以委托
        ,transfer = 0                                           %% 是否传送
        ,start_item = []		                                %% 开始获得物品{ItemId, Number}
        ,end_item = []			                                %% 结束回收物品
        ,start_npc = 0			                                %% 开始npcid
        ,end_npc = 0			                                %% 结束npcid
        ,start_talk = 0		                                    %% 开始对话
        ,end_talk = 0			                                %% 结束对话
        ,unfinished_talk = 0 	                                %% 未完成对话
        ,condition = []			                                %% 条件内容	[{task, 任务id}, {item, 物品id, 物品数量}]
        ,content = []			                                %% 任务内容 [[State, 1, kill, NpcId, Num, NowNum], [State, 0, talk, NpcId, TalkId], [State, 0, item, ItemId, Num, NowNum]]
        ,state = 0      		                                %% 完成任务需要的状态值 state = length(content)
        %% 任务奖励
        ,exp = 0				                                %% 经验
        ,coin = 0				                                %% 金钱
        ,binding_coin = 0                                       %% 绑定金
        ,spt = 0                                                %% 灵力
        ,llpt = 0                                               % 历练声望
        ,xwpt = 0                                               % 修为声望
        ,fbpt = 0                                               % 副本声望
        ,bppt = 0                                               % 帮派声望
        ,gjpt = 0                                               % 国家声望
        ,attainment	= 0			                                %% 修为
        ,contrib = 0			                                %% 贡献
        ,guild_exp = 0			                                %% 帮会经验
        ,award_select_item_num = 0                              %% 可选物品的个数
        ,award_item = []		                                %% 奖励物品
        ,award_select_item = []                                 %% 奖励可选物品
        ,award_gift = []		                                %% 礼包奖励
        ,start_cost = 0                                         %% 开始时是消耗铜币
        ,end_cost = 0 			                                %% 结束时消耗游戏币
        ,next = 0				                                %% 结束触发任务id
        ,next_cue = 0                                           %% 是否弹出结束npc的对话框
        ,proxy_time = 0
        ,proxy_gold = 0
        ,cumulate = 0                                           %% 是否经验累积
    }
).

%% 角色任务记录
-record(role_task,
    {
        id,
        role_id=0,
        task_id=0,
        type = 0,
        kind = 0,
        trigger_time=0,
        state=0,
        end_state=0,
        mark=[]                                                 %%任务记录器格式[State=int(),Finish=bool(), Type=atom((), ...]
    }
).

%% 角色任务历史记录
-record(role_task_log,
    {
        role_id=0,
        task_id=0,
        type = 0,
        trigger_time=0,
        finish_time=0,
        count = 1              %% 完成的次数
    }
).

%% 任务条件数据
-record(task_condition,
    {
        id
        ,type = 0
        ,kind = 0
        ,level = 1				                                %% 需要等级
        ,repeat = 0				                                %% 可否重复
        ,realm = 0                                              %% 阵营
        ,career = 0				                                %% 职业限制
        ,prev = 0				                                %% 上一个必须完成的任务id
        ,condition = []                                         %% 扩充条件	TODO 具体描述日后再加
    }
).

%% 自动完成的任务记录
-record(role_task_auto,
    {
        id              = {0, 0}
        ,role_id        = 0
        ,task_id        = 0
        ,type           = 0
        ,tid            = 0                                     %% 任务进程
        ,name           = <<>>
        ,number         = 0                                     %% 委托次数
        ,gold           = 0                                     %% 需要元宝
        ,trigger_time   = 0                                     %% 触发时间
        ,finish_time    = 0                                     %% 完成时间
        ,exp            = 0	                                    %% 经验
        ,llpt           = 0                                     %% 历练声望
        ,xwpt           = 0                                     %% 修为声望
    }
).

%% 新经验累积返还(经验累积)
-record(task_cumulate, {
        id          = {0, 0},                                   %% {角色id, 任务id}
        role_id     = 0,                                        %% 用户ID
        task_id     = 0,                                        %% 任务ID(1.经验本，2.皇榜，3.平乱，4.诛妖)
        task_name   = <<>>,                                     %% 任务名称
        offline_day = 0,                                        %% 累积天数
        last_finish_time = 0,                                   %% 最后完成时间
        cucm_exp    = 0                                         %% 累积经验
    }).

%% 皇榜任务
-record(role_eb_task, {
        task_id     = 0,                                        %% 任务类型
        color = 0                                               %% 任务颜色
    }).
