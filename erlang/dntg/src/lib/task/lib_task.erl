%%%-----------------------------------
%%% @Module  : lib_task
%%% @Author  : zhenghehe
%%% @Created : 2010.05.05
%%% @Description: 任务  
%%%-----------------------------------
-module(lib_task).
-export(
    [
        flush_role_task/2,
        trigger/3,
		trigger_special/2,
        get_active/1,
        get_active/4,
        get_trigger/1,
        in_active/2,
        preact_finish/3,
        finish_dun_task/2,
        get_npc_state/2,
        finish/3,
        get_npc_task_list/3,
        convert_select_tag/2,
        event/3,
        event/4,
        get_today_count/2,
        get_active_proxy/1,
        refresh_active/1,
        in_trigger/2,
        abnegate/2,
        get_npc_task_talk_id/3,
        get_tip/3,
        normal_finish/3,
        normal_finish/4,
        auto_finish/3,
        is_finish/2,
        task_fail/2,
        get_data/2,
		get_task_type/2,
        get_task_bag_id_list/1,
        get_award_item/2,
        update_all_trigger/3,
		login_update_all_trigger/3,
        can_gain_item/1,
        get_one_trigger/2,
        get_task_bag_id_list_type/2,
        get_task_bag_id_list_kind/2,
        find_task_log_list/2,
        del_trigger/3,
        del_log/4,
        put_task_log_list/2,
        add_trigger/9,
        add_log/6,
        get_task_info/3,
        get_task_sr_info/4,
        fin_task/2,
        fin_task_goods/3,
        refresh_task/1,
        daily_clear_dict/1,
		get_tab_daily_task/1,
		get_trigger_time/2,
		finish_pay_task_houtai/2,
		fin_task_vip/3,
		finish_join_guild_task/1
    ]
).
-include("scene.hrl").
%-include("record.hrl").
-include("server.hrl").
-include("task.hrl").
%% 加载任务
flush_role_task(Tid, PS) ->
    gen_server:call(Tid, {flush_role_task, [PS]}).

%% 触发任务
trigger(Tid, TaskId, PS) ->
    gen_server:call(Tid, {trigger, [TaskId, PS]}).

%% 触发特殊任务
trigger_special(TaskId, PS) ->
	case trigger(PS#player_status.tid, TaskId, PS) of
				{true, NewRS} ->
					lib_task:preact_finish(NewRS#player_status.tid, TaskId, NewRS),
					lib_scene:refresh_npc_ico(NewRS),
					{ok, BinData1} = pt_300:write(30003, [TaskId, <<>>]),
					lib_server_send:send_to_sid(NewRS#player_status.sid, BinData1),
					pp_task:handle(30000, NewRS, ok),
					{true,NewRS};
				{false, Reason} ->
					{ok, BinData} = pt_300:write(30003, [0, Reason]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData),
					false
    end.

%% 获取可接任务
get_active(Tid) ->
    gen_server:call(Tid, {get_active, []}).
get_active(Tid, type, Type, TaskId) ->
    gen_server:call(Tid, {get_active, [type, Type, TaskId]}).

%% 获取已接任务
get_trigger(Tid) ->
    gen_server:call(Tid, {get_trigger, []}).

%% 是否可接
in_active(Tid, TaskId)->
    gen_server:call(Tid, {in_active, [TaskId]}).

%% 是否有可完成的任务
preact_finish(Tid, TaskId, PS) ->
    gen_server:cast(Tid, {preact_finish, [TaskId, PS]}).

%% 完成特殊副本的任务
finish_dun_task(Id, TaskId) ->
    case lib_player:get_online_info(Id) of
        [] -> [];
        P ->
            gen_server:cast(P#ets_online.tid, {finish_dun_task, [TaskId, Id]})
    end.

%% npc任务状态
get_npc_state(NpcId, PS) ->
    gen_server:call(PS#player_status.tid, {get_npc_state, [NpcId, PS]}).

finish(TaskId, ParamList, PS) ->
    gen_server:call(PS#player_status.tid, {finish, [TaskId, ParamList, PS]}).

%% 获取任务详细数据
get_data(TaskId, PS) ->
    data_task:get(TaskId, PS).

%% 获取任务类型
get_task_type(TaskId, PS) ->
	TD = get_data(TaskId, PS),
	case TD of
		null -> 0;
		TD ->TD#task.type
	end.

%% 获取npc任务
get_npc_task_list(Tid, NpcId, PlayerStatus)->
    gen_server:call(Tid, {get_npc_task_list, [NpcId, PlayerStatus]}).

%% 筛选标签转换函数
convert_select_tag(_, Val) when is_integer(Val) -> Val;

%% 职业筛选 战士，法师，刺客
convert_select_tag(RS, [career, Z, F, C]) ->
    case RS#player_status.career of
        1 -> Z;
        2 -> F;
        _ -> C
    end;

%% 职业筛选 秦楚汉
convert_select_tag(RS, [realm, T, W, A]) ->
    case RS#player_status.realm of
        1 -> T;
        2 -> W;
        _ -> A
    end;

%% 性别
convert_select_tag(RS, [sex, Msg, Msg2]) ->
    case RS#player_status.sex of
        1 -> Msg;
        _ -> Msg2
    end;

convert_select_tag(_, Val) -> Val.

%% 完成任务过程
event(E, List, Id)->
    case lib_player:get_online_info(Id) of
        [] -> [];
        P ->
            gen_server:cast(P#ets_online.tid, {event, [E, List, Id]})
    end.

event(Tid, E, List, Id)->
    gen_server:cast(Tid, {event, [E, List, Id]}).

%% 获取任务当天完成的次数
get_today_count(TaskId, PS)->
    gen_server:call(PS#player_status.tid, {get_today_count, [TaskId]}).

%% 获取可接委托任务
get_active_proxy(PS) ->
    gen_server:call(PS#player_status.tid, {get_active_proxy, [PS]}).

%% 刷新可接任务
refresh_active(PS) ->
    gen_server:call(PS#player_status.tid, {refresh_active, [PS]}).

%% 是否已接
in_trigger(Tid, TaskId) ->
    gen_server:call(Tid, {in_trigger, [TaskId]}).

%% 放弃任务
abnegate(TaskId, PS) ->
    gen_server:call(PS#player_status.tid, {abnegate, [TaskId, PS]}).

%%获取当前npc任务对话
get_npc_task_talk_id(TaskId, Nid, PS) ->
    gen_server:call(PS#player_status.tid, {get_npc_task_talk_id, [TaskId, Nid, PS]}).

%% tips
get_tip(E, TaskId, PS) ->
    gen_server:call(PS#player_status.tid, {get_tip, [E, TaskId, PS]}).

%% 完成任务
normal_finish(TaskId, List, PS)->
    gen_server:call(PS#player_status.tid, {normal_finish, [TaskId, List, PS]}).
normal_finish(TaskId, List, PS, RewardRatio)->
    gen_server:call(PS#player_status.tid, {normal_finish, [TaskId, List, PS, RewardRatio]}).

%% 自动完成
auto_finish(Tid, TaskId, Id) ->
    gen_server:call(Tid, {auto_finish, [TaskId, Id]}).

is_finish(TaskId, PS) ->
    gen_server:call(PS#player_status.tid, {is_finish, [TaskId, PS]}).

task_fail(PS, R) ->
    gen_server:cast(PS#player_status.tid, {task_fail, [PS, R]}).

get_task_bag_id_list(Tid) ->
    gen_server:call(Tid, {get_task_bag_id_list, []}).

get_award_item(TD, PS) ->
    gen_server:call(PS#player_status.tid, {get_award_item, [TD, PS]}).

%% 回写
update_all_trigger(Tid, Id, PS) ->
    case is_process_alive(Tid) of
        true ->
            gen_server:call(Tid, {update_all_trigger, [Id, PS]});
        false ->
            skip
    end.

%% 登录检查任务完成
login_update_all_trigger(Tid, Id, PS) ->
	case is_process_alive(Tid) of
        true ->
            gen_server:call(Tid, {login_update_all_trigger, [Id, PS]});
        false ->
            skip
    end.

can_gain_item(Tid) ->
    gen_server:call(Tid, {can_gain_item, []}).

%% 获取指定id任务
get_one_trigger(Tid, TaskId) ->
    gen_server:call(Tid, {get_one_trigger, [TaskId]}).

%% 按类型获取已接任务
get_task_bag_id_list_type(Tid, Type) ->
    gen_server:call(Tid, {get_task_bag_id_list_type, [Type]}).

%% 按任务种类
get_task_bag_id_list_kind(Tid, Kind) ->
    gen_server:call(Tid, {get_task_bag_id_list_kind, [Kind]}).

%% 获取已完成指定id任务
find_task_log_list(Tid, TaskId) ->
    gen_server:call(Tid, {find_task_log_list, [TaskId]}).

%% 获取任务接取时间
get_trigger_time(Tid, TaskId) ->
    gen_server:call(Tid, {get_trigger_time, [TaskId]}).

%% 删除已接任务
del_trigger(Tid, Id, TaskId) ->
    gen_server:cast(Tid, {del_trigger, [Id, TaskId]}).
%% 删除已完成任务
del_log(Tid, Rid, TaskId, Type) ->
    gen_server:cast(Tid, {del_log, [Rid, TaskId, Type]}).

put_task_log_list(Tid, Tinfo) ->
    gen_server:cast(Tid, {put_task_log_list, [Tinfo]}).

%% 接任务
add_trigger(Tid, Rid, Taskid, TriggerTime, TaskState, TaskEndState, TaskMark, Type, Kind) ->
    gen_server:cast(Tid, {add_trigger, [Rid, Taskid, TriggerTime, TaskState, TaskEndState, TaskMark, Type, Kind]}).

%% 完成任务
add_log(Tid, Rid, Taskid, Type, TriggerTime, FinishTime) ->
    gen_server:cast(Tid, {add_log, [Rid, Taskid, Type, TriggerTime, FinishTime]}).

%% Type = active | trigger
get_task_info(TaskId, Status, Type) ->
    TD = lib_task:get_data(TaskId, Status),
    TipList = lib_task:get_tip(Type, TaskId, Status),
    pt_300:pack_task({TD#task.id, TD#task.level, TD#task.type, TD#task.name, TD#task.desc, TD#task.transfer, TipList, TD#task.coin, TD#task.exp, TD#task.spt, TD#task.llpt, TD#task.xwpt, TD#task.fbpt, TD#task.bppt, TD#task.gjpt, TD#task.binding_coin, TD#task.attainment, TD#task.guild_exp, TD#task.contrib, TD#task.award_select_item_num, lib_task:get_award_item(TD, Status), TD#task.award_select_item, TD#task.kind}).

%% Type = active | trigger
get_task_sr_info(TaskId, Status, Type, Colour) ->
    TD = lib_task:get_data(TaskId, Status),
    TipList = lib_task:get_tip(Type, TaskId, Status),
    case TD#task.type =:= 15 of
        true ->
            RewardRatio = data_task_sr:get_task_sr_award(Colour),
            Coin = round(RewardRatio*TD#task.coin),
            Exp = round(RewardRatio*TD#task.exp),
            %%io:format("Task:~p~n",[[?MODULE,?LINE,TaskId,Colour,RewardRatio, Coin, Exp]]),
            pt_300:pack_task({TD#task.id, TD#task.level, TD#task.type, TD#task.name, TD#task.desc, TD#task.transfer, TipList, Coin, Exp, TD#task.spt, TD#task.llpt, TD#task.xwpt, TD#task.fbpt, TD#task.bppt, TD#task.gjpt, TD#task.binding_coin, TD#task.attainment, TD#task.guild_exp, TD#task.contrib, TD#task.award_select_item_num, lib_task:get_award_item(TD, Status), TD#task.award_select_item, TD#task.kind});
        _ ->
            pt_300:pack_task({TD#task.id, TD#task.level, TD#task.type, TD#task.name, TD#task.desc, TD#task.transfer, TipList, TD#task.coin, TD#task.exp, TD#task.spt, TD#task.llpt, TD#task.xwpt, TD#task.fbpt, TD#task.bppt, TD#task.gjpt, TD#task.binding_coin, TD#task.attainment, TD#task.guild_exp, TD#task.contrib, TD#task.award_select_item_num, lib_task:get_award_item(TD, Status), TD#task.award_select_item, TD#task.kind})
    end.

%% 完成打怪任务
fin_task(Status, Minfo) ->
    [Mid | _] = Minfo, 
    case misc:is_process_alive(Status#player_status.pid_team) of
        true ->
            gen_server:cast(Status#player_status.pid_team, {'fin_task', Minfo});
        false ->
            lib_task:event(Status#player_status.tid, kill, Mid, Status#player_status.id)
    end.

%% 完成搜集任务
fin_task_goods(Status, TaskList, Minfo) ->
    case misc:is_process_alive(Status#player_status.pid_team) of
        true ->
            gen_server:cast(Status#player_status.pid_team, {'fin_task_goods', TaskList, Minfo});
        false ->
            lib_task:event(Status#player_status.tid, item, TaskList, Status#player_status.id)
    end.

%% 刷新任务
refresh_task(PS) ->
    gen_server:cast(PS#player_status.tid, {refresh_task, [PS]}).

%% 删除进程字典
daily_clear_dict(PS) ->
    gen_server:call(PS#player_status.tid, {daily_clear_dict, []}).

%% 日常标签页--日常任务 
get_tab_daily_task(PS) ->
	Type_list = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
	F = fun(Type) ->
			 Config = data_task_tab:tab_daily_task_config(Type),
			 case Type of
				0 -> %% 情缘任务					
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 3800);
				1 -> %% 护送任务
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 4700);
				2 -> %% 诛妖任务 发布
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 5000040);
				3 -> %% 诛妖任务 领取
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 5000090);
				4 -> %% 平乱任务
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6000002);
				5 -> %% 皇榜任务
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6000001);
				6 -> %% 宠物副本
					Count =	mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 233);
				7 -> %% 铜钱副本 
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 650);
				8 -> %% 单人九重天
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 340);
				9 -> %% 多人九重天
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 300);
				10 -> %% 经验副本
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 630);
				11 -> %% 试炼任务
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6000003);
				12 -> %% 阵营任务
					Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6000004);
                13 -> %% 答题
                    Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 1027);
                14 -> %% 封魔录
                    Count = 0;
                15 -> %% 装备副本
                    Count = 0;
                16 -> %% 铜钱副本
                    Count = 0;
                17 -> %% 竞技场 
                    Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6000005);
                18 -> %% 帮派战
                    Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6000006);
                19 -> %% 蟠桃会
                    Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 6000007);
                20 -> %% 除魔卫道
                    Count = 0;
                21 -> %% 砸蛋
                    Count = 0;
                22 -> %% 摇钱树
                    Count = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 8889);
				_ -> Count =0					
			end,
			case Config =/=false of
				true ->
					{_, Need_lv, Max_n} = Config,
%% 					%% 特殊处理  60级后阵营任务之后1个，之前有4个
%% 					case PS#player_status.lv>=60 andalso Type=:=12 of
%% 						true -> 
%% 							[Type, Need_lv, Count, 1];	
%% 					    false ->
%% 							[Type, Need_lv, Count, Max_n]	
%% 					end;
                    case Count >= Max_n	of
                        true -> 
                            [Type, Need_lv, Max_n, Max_n];
                        false ->
                            [Type, Need_lv, Count, Max_n]
                    end;
				false ->
					skip
			end
		end,
		lists:map(F, Type_list).

%% 完成加入帮派任务
finish_join_guild_task(PlayerId) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'finish_join_guild_task_unite'});
        _ ->
            0
    end.

%% 激活完成充值任务
finish_pay_task_houtai(PlayerId, TaskId) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
			gen_server:cast(Pid, {'finish_pay_task_houtai', [TaskId]}),
			1;
        _ ->
            0
    end.

%% 完成vip任务--更新任务进度
fin_task_vip(_PS, _TaskId, _Num) ->
	skip.
%%	lib_task_vip:fin_task_vip(_PS, _TaskId, _Num).	
