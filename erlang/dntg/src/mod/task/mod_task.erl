%%%------------------------------------
%%% @Module  : mod_task
%%% @Author  : zhenghehe
%%% @Created : 2010.06.13
%%% @Description: 任务
%%%------------------------------------
-module(mod_task).
-behaviour(gen_server).
-export([start/0, stop/1, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-include("task.hrl").
-include("def_goods.hrl").
-include("unite.hrl").
-include("predefine.hrl").


-record(state, {
        task_query_cache = [],
        role_task = [],
        role_task_log = []
    }
).

start() ->
    gen_server:start_link(?MODULE, [], []).

%%停止任务进程
stop(Pid)
  when is_pid(Pid) ->
    gen_server:cast(Pid, stop).

init([]) ->
    {ok, #state{}}.

handle_call(Request, From, State) ->
    mod_task_call:handle_call(Request, From, State).

handle_cast(Msg, State) ->
    mod_task_cast:handle_cast(Msg, State).

handle_info(Info, State) ->
    mod_task_info:handle_info(Info, State).

terminate(_Info, State) ->
    {ok, State}.

code_change(_oldvsn, State, _extra) ->
    {ok, State}.

%% 从数据库加载角色的任务数据
flush_role_task(PS) ->
    F1 = fun(Tid, Tt, S ,ES, M, TP) ->
        Kind = case get_condition(Tid) of null -> 0; TD -> TD#task_condition.kind end,
        #role_task{id={PS#player_status.id, Tid}, role_id=PS#player_status.id, task_id=Tid, trigger_time = Tt, state = S, end_state = ES, mark = binary_to_term(M), type=TP, kind = Kind}
    end,
    F2 = fun(Tid2, Ty2, Tt2, Ft2) ->
        put_task_log_list(#role_task_log{role_id=PS#player_status.id, task_id=Tid2, type= Ty2, trigger_time = Tt2, finish_time = Ft2})
    end,
	%% 充值活动任务处理,切勿去掉
%%	TempSql = io_lib:format("delete from task_bag where role_id=~p and (task_id=~p or task_id=~p) and state=0", [PS#player_status.id, 200120, 200140]),
%%	db:execute(TempSql),
	%% 
    RoleTaskList = db:get_all(io_lib:format("select * from task_bag where role_id=~p", [PS#player_status.id])),
    RoleTaskListRed = [
        F1(Tid, Tt, S ,ES, M, TP)
        || [_, Tid, Tt, S ,ES, M, TP] <-RoleTaskList
    ],
    RoleTaskLogList1 = db:get_all(io_lib:format("select * from task_log where role_id=~p", [PS#player_status.id])),
    RoleTaskLogList2 = db:get_all(io_lib:format("select * from task_log_clear where role_id=~p", [PS#player_status.id])),
    RoleTaskLogList = RoleTaskLogList1 ++ RoleTaskLogList2,
    [
        F2(Tid2, Ty2, Tt2, Ft2)
        || [_, Tid2, Ty2, Tt2, Ft2] <-RoleTaskLogList
    ],
    set_task_bag_list(RoleTaskListRed),
    refresh_active(PS).
	%trigger_auto_task(PS).

%% 主动接取付费任务: 首充、99送水晶、888元宝
trigger_auto_task(PS) ->
	trigger_firstPay_task(PS),
	trigger_crystal_task(PS),
	trigger_888_task(PS).

%% 触发888充值活动任务
trigger_888_task(PS) ->
	NowTime = util:unixtime(),
	TimeConfig = data_activity_time:get_time_by_type(10),
	case TimeConfig of
		[_PayTaskStart, PayTaskEnd] -> skip;
		[] -> 
			PayTaskEnd = util:unixtime({{2012, 10, 30}, {6, 0, 0}})
	end,
	Is_recharge_task_time = lib_activity:is_pay_task_time(),
	Pay_task_id = 200120,
	case PS#player_status.lv >=30 of
		true ->
			if   
				Is_recharge_task_time -> %% 活动时间
					case find_task_log_exits(Pay_task_id) orelse find_task_bag_exits(Pay_task_id) of
						true -> skip;
						false ->
							TD = get_data(Pay_task_id, PS),
							add_trigger(PS#player_status.id, Pay_task_id, util:unixtime(), 0, TD#task.state, TD#task.content, TD#task.type, TD#task.kind)
					end;
				NowTime > PayTaskEnd ->					
					Is_exits = find_task_bag_exits(Pay_task_id),
					case Is_exits of
						true ->
							del_trigger(PS#player_status.id, Pay_task_id);
						false -> skip
					end;
				true ->
					skip
			end;
		false ->
			skip
	end.

%% 触发99元宝送水晶任务
%% 50级与60级不同时出现,任意个没完成从出现后一直在
trigger_crystal_task(PS) ->
	CrystalTask1= 200290,
	CrystalTask2= 200450,	
	NowTime = util:unixtime(),
	StartTime1 = util:unixtime({{2012, 11, 27}, {0, 0, 0}}),
	StartTime2 = util:unixtime({{2012, 12, 24}, {0, 0, 0}}),
	case NowTime>=StartTime1 of
		true ->
			if
			PS#player_status.lv >=59 ->
				case NowTime>=StartTime2 of
					true ->
						%% 50级的是否完成
						case find_task_log_exits(CrystalTask1) of
							true ->	
								case find_task_log_exits(CrystalTask2) of
									true -> skip;
									false -> private_crystal_trigger(PS, CrystalTask2)
								end;
							false -> private_crystal_trigger(PS, CrystalTask1)
						end;
					false -> skip
				end;
			PS#player_status.lv >=50 ->
				case find_task_log_exits(CrystalTask1) of
					true -> skip;
					false -> private_crystal_trigger(PS, CrystalTask1)
				end;
			true -> skip
		   end;
		false -> skip
	end.	

private_crystal_trigger(PS, TaskId) ->
	case find_task_bag_exits(TaskId) of
		true -> skip;
		false -> 
			TD = get_data(TaskId, PS),
			add_trigger(PS#player_status.id, TaskId, util:unixtime(), 0, TD#task.state, TD#task.content, TD#task.type, TD#task.kind)
	end.

%% 触发首充任务
trigger_firstPay_task(PS) ->
	%% 购买武器,首充任务
	Buy_weapon_id = 200140,
	case PS#player_status.lv >=20 of
		true ->
			case lib_gift_new:get_gift_fetch_status(PS#player_status.id, 532001) of
				1 -> skip;
				_ ->
				case find_task_log_exits(Buy_weapon_id)  orelse find_task_bag_exits(Buy_weapon_id) of
					true -> skip;
					false ->						
						_TD = get_data(Buy_weapon_id, PS),
						add_trigger(PS#player_status.id, Buy_weapon_id, util:unixtime(), 0, _TD#task.state, _TD#task.content, _TD#task.type, _TD#task.kind)
				end
			end;
		false -> skip
	end.

%% 刷新任务并发送更新列表
refresh_task(PS) ->
    refresh_active(PS),
    refresh_npc_ico(PS#player_status.id),
	%trigger_auto_task(PS),
    {ok, BinData} = pt_300:write(30006, []),
    lib_server_send:send_to_sid(PS#player_status.sid, BinData).

%% 遍历所有任务看是否可接任务
refresh_active(PS) ->
    Tids = data_task_lv:get_ids(PS#player_status.lv, PS#player_status.realm),
    F = fun(Tid) ->
            get_data(Tid, PS)
    end,
    QueryCacheListRed = [F(Tid) || Tid<-Tids, can_trigger(Tid, PS)],
    set_query_cache_list(QueryCacheListRed).

%% 用于委托任务 - 获取可接任务
get_active_proxy(PS) ->
    refresh_active_proxy(PS).

%% 用于委托任务
refresh_active_proxy(PS) ->
    Tids = data_task_lv:get_ids(PS#player_status.lv, PS#player_status.realm),
    [Tid || Tid<-Tids, can_trigger_msg_proxy(Tid, PS)].

%% 获取任务详细数据
get_data(TaskId, PS) ->
    data_task:get(TaskId, PS).

get_condition(TaskId) ->
    data_task_condition:get(TaskId).

is_special_task(TaskId) ->
    TaskId > 999999.

%% 获取玩家能在该Npc接任务或者交任务
get_npc_task_list(NpcId, PS) ->
    {CanTrigger, Link, UnFinish, Finish} = get_npc_task(NpcId, PS),
    F = fun(Tid, NS) -> TD = get_data(Tid, PS), [Tid, NS, TD#task.name, TD#task.type] end,
    F2 = fun(TD, NS) -> [TD#task.id, NS, TD#task.name, TD#task.type] end,
    L1 = [F2(T1, 1) || T1 <- CanTrigger, T1#task.level =< PS#player_status.lv],
    L2 = [F(T2, 4) || T2 <- Link],
    L3 = [F(T3, 2) || T3 <- UnFinish],
    L4 = [F(T4, 3) || T4 <- Finish],
    L1++L2++L3++L4.

%% 获取npc任务状态
get_npc_state(NpcId, PS)->
    {CanTrigger, Link, UnFinish, Finish} = get_npc_task(NpcId, PS),
    %% 0表示什么都没有，1表示有可接任务，2表示已接受任务但未完成，3表示有完成任务，4表示有任务相关
    case length(Finish) > 0 of
        true -> 3;
        false ->
            case length(Link)>0 of
                true-> 4;
                false->
                    case length([0 || RT <- CanTrigger, RT#task.level =< PS#player_status.lv])>0 of
                        true ->    1;
                        false ->
                            case length(UnFinish)>0 of
                                true -> 2;
                                false -> 0
                            end
                    end
            end
    end.

%% 获取npc任务关联
%%{可接任务，关联，任务未完成，完成任务}
get_npc_task(NpcId, PS)->
    CanTrigger = get_npc_can_trigger_task(NpcId),
    {Link, Unfinish, Finish} = get_npc_other_link_task(NpcId, PS),
    {CanTrigger, Link, Unfinish, Finish}.

%% 获取可接任务
get_npc_can_trigger_task(NpcId) ->
    [ TS || TS <-get_query_cache_list(), TS#task.start_npc =:= NpcId].

%% 获取已触发任务
get_npc_other_link_task(NpcId, PS) ->
    get_npc_other_link_task(get_task_bag_id_list(), {[], [], []}, NpcId, PS).
get_npc_other_link_task([], Result, _, _) ->
    Result;
get_npc_other_link_task([RT | T], {Link, Unfinish, Finish}, NpcId, PS) ->
    TD = get_data(RT#role_task.task_id, PS),
    case is_finish(RT, PS) andalso get_end_npc_id(RT) =:= NpcId of  %% 判断是否完成
        true -> get_npc_other_link_task(T, {Link, Unfinish, Finish++[RT#role_task.task_id]}, NpcId, PS);
        false ->
            case task_talk_to_npc(RT, NpcId) of %% 判断是否和NPC对话
                true -> get_npc_other_link_task(T, {Link++[RT#role_task.task_id], Unfinish, Finish}, NpcId, PS);
                false ->
                    case get_start_npc(TD#task.start_npc, PS#player_status.career) =:= NpcId of %% 判断是否接任务NPC
                        true -> get_npc_other_link_task(T, {Link, Unfinish++[RT#role_task.task_id], Finish}, NpcId, PS);
                        false -> get_npc_other_link_task(T, {Link, Unfinish, Finish}, NpcId, PS)
                    end
            end
    end.

%%检查任务的下一内容是否为与某npc的对话
task_talk_to_npc(RT, NpcId)->
    Temp = [0||[State,Fin,Type,Nid|_]<- RT#role_task.mark, State=:= RT#role_task.state, Fin=:=0, Type=:=talk, Nid =:= NpcId],
    length(Temp)>0.

%% 获取任务对话id
get_npc_task_talk_id(TaskId, NpcId, PS) ->
    case get_data(TaskId, PS) of
        null -> {none, 0};
        TD ->
            {CanTrigger, Link, UnFinish, Finish} = get_npc_task(NpcId, PS),
            case {
                lists:keymember(TaskId, #task.id, CanTrigger),
                lists:member(TaskId, Link),
                lists:member(TaskId, UnFinish),
                lists:member(TaskId, Finish)
            }of
                {true, _, _, _} -> {start_talk, TD#task.start_talk};    %% 任务触发对话
                {_, true, _, _} ->    %% 关联对话
                    case get_one_trigger(TaskId) of
                        false ->
                           {none, 0};
                        RT ->
                            [Fir|_] = [TalkId || [State,Fin,Type,Nid,TalkId|_] <- RT#role_task.mark, State=:= RT#role_task.state, Fin=:=0, Type=:=talk, Nid =:= NpcId],
                            {link_talk, Fir}
                    end;
                {_, _, true, _} -> {unfinished_talk, TD#task.unfinished_talk};  %% 未完成对话
                {_, _, _, true} ->   %% 提交任务对话
                    case get_one_trigger(TaskId) of
                        false ->
                           {none, 0};
                        RT ->
                            [Fir|_] = [TalkId || [_,_,Type,Nid,TalkId|_] <- RT#role_task.mark, Type=:=end_talk, Nid =:= NpcId],
                            {end_talk, Fir}
                    end;
                _ -> {none, 0}
            end
    end.

%% 获取提示信息
get_tip(active, TaskId, PS) ->
    TD = get_data(TaskId, PS),
    case get_start_npc(TD#task.start_npc, PS#player_status.career) of
        0 -> [];
        StartNpcId -> [to_same_mark([0, 0, start_talk, StartNpcId], PS)]
    end;

get_tip(trigger, TaskId, PS) ->
    RT = get_one_trigger(TaskId),
    [to_same_mark([State|T], PS) || [State | T] <-RT#role_task.mark, RT#role_task.state=:= State].

get_award_item(TD, PS) ->
    AI = get_active_item(TD),
    Items = TD#task.award_item ++ AI,
    [{ItemId, Num} || {Career, Sex, ItemId, Num} <- Items, (Career =:= 0 orelse Career =:= PS#player_status.career) andalso (Sex =:= 0 orelse Sex =:= PS#player_status.sex) ].

get_award_gift(TD, PS) ->
    [{GiftId, Num} || {Career, GiftId, Num} <- TD#task.award_gift, Career =:= 0 orelse Career =:= PS#player_status.career].

%% 获取开始npc的id
%% 如果需要判断职业才匹配第2,3
get_start_npc(StartNpc, _) when is_integer(StartNpc) -> StartNpc;

get_start_npc([], _) -> 0;

get_start_npc([{career, Career, NpcId}|T], RoleCareer) ->
    case Career =:= RoleCareer of
        false -> get_start_npc(T, RoleCareer);
        true -> NpcId
    end.

%% 转换成一致的数据结构
to_same_mark([_, Finish, start_talk, NpcId | _], _PS) ->
    {SId,SName} = get_npc_def_scene_info(NpcId, 0),
    %% [类型, 完成, NpcId, Npc名称, 0, 0, 所在场景Id]
    [0, Finish, NpcId, lib_npc:get_name_by_npc_id(NpcId), 0, 0, SId, SName, []];

to_same_mark([_, Finish, end_talk, NpcId | _], _PS) ->
    {SId,SName} = get_npc_def_scene_info(NpcId, 0),
    %% [类型, 完成, NpcId, Npc名称, 0, 0, 所在场景Id]
    [1, Finish, NpcId, lib_npc:get_name_by_npc_id(NpcId), 0, 0, SId, SName, []];


to_same_mark([_, Finish, kill, MonId, Num, NowNum | _], _PS) ->
    {SId,SName, X, Y, Npc} = get_mon_def_scene_info(MonId),
    Mid = case Npc > 0 of true -> Npc; false -> MonId end,
    %% [类型, 完成, MonId, Npc名称, 需要数量, 已杀数量, 所在场景Id]
    [2, Finish, Mid, lib_mon:get_name_by_mon_id(MonId), Num, NowNum, SId, SName, [X, Y]];

to_same_mark([_, Finish, talk, NpcId | _], _PS) ->
    {SId,SName} = get_npc_def_scene_info(NpcId, 0),
    %% [类型, 完成, NpcId, Npc名称, 0, 0, 所在场景Id]
    [3, Finish, NpcId, lib_npc:get_name_by_npc_id(NpcId), 0, 0, SId, SName, []];

to_same_mark([_, Finish, item, ItemId, Num, NowNum | _], _PS) ->
    {NpcId, ItemName, SceneId, SceneName, X, Y} = case lib_goods_drop:get_task_mon(ItemId) of
        [] -> {0, get_item_name(ItemId), 0, <<"未知场景">>, 0, 0};  %% 物品无绑定npc
        XNpcIdList ->
            ListLen = length(XNpcIdList),
            Rand = util:rand(1, ListLen),
            XNpcId = lists:nth(Rand,XNpcIdList),
            {XSId,XSName, X0, Y0, 0} = get_mon_def_scene_info(XNpcId),
            {XNpcId, get_item_name(ItemId), XSId, XSName, X0, Y0}
    end,
    %% [类型, 完成, 物品id, 物品名称, 0, 0, 0]
    [4, Finish, NpcId, ItemName, Num, NowNum, SceneId, SceneName, [NpcId, lib_mon:get_name_by_mon_id(NpcId), X, Y]];
    
to_same_mark([_, Finish, open_store | _], _PS) ->
    [5, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, equip ,ItemId | _], _PS) ->
    [6, Finish, ItemId, get_item_name(ItemId), 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, buy_equip ,ItemId, NpcId| _], _PS) ->
    {SId,SName} = get_npc_def_scene_info(NpcId, 0),
    [7, Finish, ItemId, get_item_name(ItemId), 0, 0, SId, SName, [NpcId, lib_npc:get_name_by_npc_id(NpcId)]];

to_same_mark([_, Finish, learn_skill ,SkillId | _], _PS) ->
    [8, Finish, SkillId, data_task_text:get_text(1), 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, add_friend | _], _PS) ->
    [9, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, join_guild | _], _PS) ->
    [10, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, use_equip ,ItemId | _], _PS) ->
    [11, Finish, ItemId, get_item_name(ItemId), 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, xlqy | _], _PS) ->
    [12, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, bzjf | _], _PS) ->
    [13, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, yxrw | _], _PS) ->
    [14, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, qh | _], _PS) ->
    [15, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, jd | _], _PS) ->
    [16, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, lh | _], _PS) ->
    [17, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, bpgx | _], _PS) ->
    [18, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, use_goods, SceneId, X, Y, ItemId | _], _PS) ->
    [19, Finish, ItemId, get_item_name(ItemId), 0, 0, SceneId, lib_scene:get_scene_name(SceneId), [X, Y]];

to_same_mark([_, Finish, movein_storage | _], _PS) ->
    [20, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark([_, Finish, big_face, NpcId, FaceId | _], _PS) ->
    {SId,SName} = get_npc_def_scene_info(NpcId, 0),
    [21, Finish, NpcId, lib_npc:get_name_by_npc_id(NpcId), 0, 0, SId, SName, [FaceId]];

to_same_mark([_, Finish, kill_avatar, NpcId | _], _PS) ->
    {SId,SName} = get_npc_def_scene_info(NpcId, 0),
    %% [类型, 完成, NpcId, Npc名称, 0, 0, 所在场景Id]
    [22, Finish, NpcId, lib_npc:get_name_by_npc_id(NpcId), 0, 0, SId, SName, []];

to_same_mark([_, Finish, open_task_sr | _], _PS) ->
    [23, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

%% 装备分解
to_same_mark([_, Finish, fj | _], _PS) ->
    [24, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

%% 宠物融合
to_same_mark([_, Finish, pet_derive | _], _PS) ->
    [25, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

%% 宠物成长
to_same_mark([_, Finish, pet_grow_up | _], _PS) ->
    [26, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

%% 进入指定场景
to_same_mark([_, Finish, enter_scene, SceneId | _], _PS) ->
	SceneName = lib_scene:get_scene_name(SceneId),
    [27, Finish, 0, <<>>, 0, 0, SceneId, SceneName, []];
    
%% 充值活动任务
to_same_mark([_, Finish, pay_task, _PayCount | _], _PS) ->
    [28, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

%% 普通充值任务
to_same_mark([_, Finish, pay_task_2, _PayCount | _], _PS) ->
    [29, Finish, 0, <<>>, 0, 0, 0, <<>>, []];

to_same_mark(MarkItem, _PS) ->
    MarkItem.

%%获取当前NPC所在的场景（自动寻路用）
get_npc_def_scene_info(NpcId, _Realm) ->
    case lib_npc:get_scene_by_npc_id(NpcId) of
        [] ->
            {0,<<>>};
        [SceneId, _, _, SceneName] ->
             {SceneId, SceneName}
    end.

%%获取当前NPC所在的场景（自动寻路用）
get_mon_def_scene_info(MonId) ->
    case lib_mon:get_mon_by_id(MonId) of
        [] ->
            Name = data_task_text:get_mon_name(),
            if
                MonId =:= 66003 ->
                    {220,Name, 38, 58, 30074};
                MonId =:= 66039 ->
                    {220,Name, 38, 58, 30074};
                true ->
                    {0,<<>>, 0, 0, 0}
            end;
        D ->
            case data_dungeon:get(D#ets_scene_mon.scene) of
                [] ->
                    {D#ets_scene_mon.scene, D#ets_scene_mon.name, D#ets_scene_mon.x, D#ets_scene_mon.y, 0};
                Dun ->
                    [Sid, _, _] = Dun#dungeon.out,
                    {Sid, D#ets_scene_mon.name, 0, 0, Dun#dungeon.npc}
            end
    end.

get_item_name(ItemId)->
    data_goods_type:get_name(ItemId).

%% 指定id任务是否可接
in_active(TaskId) ->
    find_query_cache_exits(TaskId).

get_active() ->
    get_query_cache_list().

get_active(type, Type) ->
    get_query_cache_list_type(Type).

%% 获取可接的有经验累积的任务
get_active_cumulate() ->
    [ T || T <- get_query_cache_list(), T#task.cumulate =:= 1].

%% 获取已触发任务列表
get_trigger() ->
	get_task_bag_id_list().
    
%% 获取已触发任务种类列表
get_trigger_type(Type) ->
    get_task_bag_id_list_type(Type).

%% 获取该阶段任务内容
get_phase(RT)->
    [[State | T] || [State | T] <- RT#role_task.mark, RT#role_task.state =:= State].

%% 获取任务阶段的未完成内容
get_phase_unfinish(RT)->
    [[State, Fin | T] || [State, Fin |T] <- RT#role_task.mark, RT#role_task.state =:= State ,Fin =:= 0].

get_one_trigger(TaskId) ->
    find_task_bag_list(TaskId).

%%获取结束任务的npcid
get_end_npc_id(RT) when is_record(RT, role_task)->
    get_end_npc_id(RT#role_task.mark);

get_end_npc_id(TaskId) when is_integer(TaskId) ->
    case get_one_trigger(TaskId) of
        false -> 0;
        RT -> get_end_npc_id(RT)
    end;
get_end_npc_id([]) -> 0;

get_end_npc_id(Mark) ->
    case lists:last(Mark) of
        [_, _, end_talk, NpcId, _] -> NpcId;
        _ -> 0  %% 这里是异常
    end.

%% 是否为帮会任务
is_guild_task(TaskId) ->
    case get_data(TaskId, null) of
        null -> false ;
        TD -> TD#task.contrib > 0 %% 有帮贡的任务一定是帮会任务
    end.

%% 是否已触发过
in_trigger(TaskId) ->
    find_task_bag_exits(TaskId).

%% 是否已完成任务列表里
in_finish(TaskId)->
    find_task_log_exits(TaskId).

%% 获取今天完成某任务的数量
get_today_count(TaskId) ->
    %{M, S, MS} = now(),
    %{_, Time} = calendar:now_to_local_time({M, S, MS}),
    %TodaySec = M * 1000000 + S - calendar:time_to_seconds(Time),
    %TomorrowSec = TodaySec + 86400,
    %length([0 || RTL <- get_task_log_id_list(), TaskId=:=RTL#role_task_log.task_id, RTL#role_task_log.finish_time >= TodaySec, RTL#role_task_log.finish_time < TomorrowSec]).
    case find_task_log_list(TaskId) of
        false ->
            0;
        RTL ->
            RTL#role_task_log.count
    end.

%% 特殊任务是否可以接受
is_special_trigger(TaskId, PS) ->
	Appointment_list = [900010, 900020, 900030, 900040, 900050],
	Husong_list = [400010, 400020, 400030, 400040, 400050, 400060, 400070, 400080, 400090],
	AutoTrigger_list = [200120, 200140, 200290, 200450],
	IsAppointment = lists:member(TaskId, Appointment_list),
	IsHusong = lists:member(TaskId, Husong_list),
	IsAutoTrigger = lists:member(TaskId, AutoTrigger_list),
	if 
		 IsAppointment -> %% 是否仙侣奇缘任务
			Count1 = get_today_count(TaskId),
			Count2 = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 3800),
			TriggerDaily = get_task_bag_id_list_type(10),
			case Count1>=1 orelse Count2 >=1 orelse length(TriggerDaily) >= 1 of
				true -> 0;				
				false ->1  %% 还原
				%%false ->0 %% 8.15晚12点前特殊处理
			end;
		 IsHusong -> %% 是否护送任务
			 Count1 = get_today_count(TaskId),
			 Count2 = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 4700),
			 case PS#player_status.lv <38 orelse  Count1 >= 3  orelse Count2 >=3 of
				 true -> 0;
				 false -> 1
			 end;
		IsAutoTrigger -> %% 是否自动接取任务, 一直不显示在可接列表
			0;
		true ->
			2
	end.
		

%%是否可以接受任务
can_trigger(TaskId, PS) ->
	case  is_special_trigger(TaskId, PS) of
		0 -> false;
		1 -> true;
		2 -> can_trigger_msg(TaskId, PS) =:= true
    end.
    
can_trigger_msg(TaskId, PS) ->
    Gs = PS#player_status.guild,
    case in_trigger(TaskId) of
        true ->
            Msg = data_task_text:get_can_trigger_msg(1),
            {false, Msg}; %%已经触发过了
        false ->
            case get_condition(TaskId) of
                null ->
                    Msg = data_task_text:get_can_trigger_msg(2),
                    {false, Msg};
                TD ->
					%% 11级限制放行的Id
					Except_TaskId = [200140, 200251, 200252, 200262, 200264, 200266, 200268, 200270,
						200272, 200274, 200276, 200278, 200280, 200290, 200450, 200032, 200253],
					case PS#player_status.lv+1 < TD#task_condition.level  orelse  (TD#task_condition.type =/= 13 andalso PS#player_status.lv >= TD#task_condition.level+11 andalso lists:member(TaskId, Except_TaskId)=:=false) of %% 1.等级不足或等级不符合(帮派试炼/如意神兵任务除外)  2.不能跨越11级以上,本来10级，加多一级容错
                        true -> 
                            Msg = data_task_text:get_can_trigger_msg(3),
                            {false, Msg}; %% 等级不足
                        false ->
                            case check_guild(TD#task_condition.type, Gs#status_guild.guild_id) of
                                false ->
                                    Msg = data_task_text:get_can_trigger_msg(4),
                                    {false, Msg};
                                true ->
                                    case check_realm(TD#task_condition.realm, PS#player_status.realm) of
                                        false -> 
                                            Msg = data_task_text:get_can_trigger_msg(5),
                                            {false, Msg}; %% 阵营不符合
                                        true ->
                                            case check_career(TD#task_condition.career, PS#player_status.career) of
                                                false -> 
                                                    Msg = data_task_text:get_can_trigger_msg(6),
                                                    {false, Msg}; %% 职业不符合
                                                true ->
                                                    case check_prev_task(TD#task_condition.prev) of
                                                        false -> 
                                                            Msg = data_task_text:get_can_trigger_msg(7),
                                                            {false, Msg}; %%前置任务未完成
                                                        true ->
                                                            case check_repeat(TaskId, TD#task_condition.repeat) of
                                                                false -> 
                                                                    Msg = data_task_text:get_can_trigger_msg(8),
                                                                    {false, Msg}; %%不 能重复做
                                                                true ->
                                                                    case length([1||ConditionItem <- TD#task_condition.condition, check_condition(ConditionItem, TaskId, PS)=:=false]) =:=0 of
                                                                        true ->
                                                                            true;
                                                                        false ->
                                                                            Msg = data_task_text:get_can_trigger_msg(9),
                                                                            {false, Msg}
                                                                    end
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

%%用于委托任务
can_trigger_msg_proxy(TaskId, PS) ->
    Gs = PS#player_status.guild,
    case in_trigger(TaskId) of
        true -> false; %%已经触发过了
        false ->
            case get_condition(TaskId) of
                null ->
                    false;
                TD ->
                    case PS#player_status.lv+1 < TD#task_condition.level of %% 跳了一级，主要为了可接任务的显示
                        true -> false; %% 等级不足
                        false ->
                            case check_guild(TD#task_condition.type, Gs#status_guild.guild_id) of
                                false -> false;
                                true ->
                                    case check_realm(TD#task_condition.realm, PS#player_status.realm) of
                                        false -> false; %% 阵营不符合
                                        true ->
                                            case check_career(TD#task_condition.career, PS#player_status.career) of
                                                false -> false; %% 职业不符合
                                                true ->
                                                    case check_repeat(TaskId, TD#task_condition.repeat) of
                                                        false -> false; %%不 能重复做
                                                        true ->
                                                            length([1||ConditionItem <- TD#task_condition.condition, check_condition(ConditionItem, TaskId, PS)=:=false]) =:=0 
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.

%% 获取下一等级的任务
next_lev_list(PS) ->
   Tids = data_task:get_ids(),
   F = fun(Tid) -> TD = get_data(Tid, PS), (PS#player_status.lv + 1) =:= TD#task.level end,
   [XTid || XTid<-Tids, F(XTid)].

%% 阵营检测
check_realm(Realm, PSRealm) ->
    case Realm =:= 0 of
        true -> true;
        false -> PSRealm =:= Realm
    end.
%% 职业检测
check_career(Career, PSCareer) ->
    case Career =:= 0 of
        true -> true;
        false -> PSCareer =:= Career
    end.

%% 检查是否为帮会任务
check_guild(Type, RSGuild) ->
    case Type =:= 3 of
        false -> true;
        true -> RSGuild > 0
    end.


%% 是否重复可以接
check_repeat(TaskId, Repeat) ->
    case Repeat =:= 0 of
        true -> find_task_log_exits(TaskId) =/= true;
        false -> true
    end.

%% 前置任务
check_prev_task(PrevId) ->
    case PrevId =:= 0 of
        true -> true;
        false -> find_task_log_exits(PrevId)
    end.

%% 能否触发任务的其他非硬性影响条件
trigger_other_condition(TD, PS) ->
    Go = PS#player_status.goods,
    case gen_server:call(Go#status_goods.goods_pid, {'cell_num'}) < length(TD#task.start_item) of
        true -> false; %% 空位不足，放不下触发时能获得的物品
        false -> true
    end.

%% 触发任务
trigger(TaskId, PS) ->
    normal_trigger(TaskId, PS).

normal_trigger(TaskId, PS) ->
    case can_trigger_msg(TaskId, PS) of
        {false, Msg} ->
            {false, Msg};
        true ->
            TD = get_data(TaskId, PS),
            case TD#task.level >  PS#player_status.lv of
                true ->
                    Msg = data_task_text:get_normal_trigger(1),
                    {false, Msg};
                false ->
                %case trigger_other_condition(TD, PS) of
                    %false -> {false, <<"背包空间不足！">>};
                    %true ->
                        %% TODO 任务开始给予物品
                        %case length(TD#task.start_item) > 0 of
                        %    true ->
                        %        lib_item:send_items_to_bag(TD#task.start_item, PS#player_status.id),
                        %        lib_storage:refresh_list(role_bag, PS#player_status.id);
                        %    false -> ok
                        %end,                        

						State = 
                        case TD#task.type =:= 9 of
                            true ->
								true;
                               %% Count = mod_daily:get_count(PS#player_status.id, 2000),
                               %% case Count > 5 of
                               %%     true ->
                               %%         {false, data_task_text:get_normal_trigger(2)};
                               %%     false ->
                               %%         true
                               %%end;
                            false ->
                                true
                        end,						

                        % 检查运镖条件
                        case State of
                            {false, Msg} ->
                                {false, Msg};
                            true ->						
                                case lib_husong:trigger_task(TD, PS) of
                                    {false, is_husonging} -> {false, data_task_text:get_normal_trigger(5)};
                                    {false, change_pk_fail} -> {false, data_task_text:get_normal_trigger(6)};
                                    {false, not_enough_physical} -> {false, data_task_text:get_normal_trigger(10)};
									{false, is_changing_scene} -> {false, data_task_text:get_normal_trigger(11)};
                                    {true, PS1} ->
                                        LastPS = lib_fly_mount:trigger_task(TD, PS1),
                                        add_trigger(LastPS#player_status.id, TaskId, util:unixtime(), 0, TD#task.state, TD#task.content, TD#task.type, TD#task.kind),
                                        if  %% 英雄帖任务
                                            TD#task.type == 9 ->
                                                %% 添加日常次数
                                                mod_daily:increment(LastPS#player_status.dailypid, LastPS#player_status.id, 2000);
                                            true ->
                                                skip
                                        end,
										
										%% 护送任务
                                        case TD#task.type =:= 7 andalso lists:member(TaskId, ?XS_HUSONG_TASK) == false of
                                            true ->
                                                %% 添加日常次数
                                                mod_daily_dict:increment(LastPS#player_status.id, 5000030),
                                                mod_daily:increment(LastPS#player_status.dailypid, LastPS#player_status.id, 5000030);
                                            false ->
                                                skip 
                                        end,

                                        {true, LastPS}
                                end
                        end
                %end
            end
    end.

%% 有部分任务内容在触发的时候可能就完成了
preact_finish(Rid) ->
    lists:member(true, [preact_finish(RT, Rid) || RT <- get_task_bag_id_list()]).

%% 阴曹地府副本任务.
%preact_finish(101270, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 500) > 0 of
%        true ->
%            event(kill, 30042, Rid#player_status.id);
%        false ->
%            false
%    end;

%% 云栈洞府副本任务.
%preact_finish(101730, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 561) > 0 of
%        true ->
%            event(kill, 56301, Rid#player_status.id);
%        false ->
%            false
%    end;
        
%% 鼠圣地宫副本任务.
%preact_finish(100441, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 562) > 0 of
%        true ->			
%            event(kill, 56201, Rid#player_status.id);
%        false ->
%            false
%    end;
    
%% 密林狼巢副本任务.
%preact_finish(100950, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 563) > 0 of
%        true ->
%            event(kill, 56404, Rid#player_status.id);
%        false ->
%            false
%    end;
    
%% 黑风山脚副本任务.
%preact_finish(102220, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 564) > 0 of
%        true ->
%            event(kill, 56414, Rid#player_status.id);
%        false ->
%            false
%    end;
    
%% 黑风洞副本任务.
%preact_finish(102330, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 565) > 0 of
%        true ->
%            event(kill, 56504, Rid#player_status.id);
%        false ->
%            false
%    end;
    
%% 云虚洞副本任务.
%preact_finish(101331, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 566) > 0 of
%        true ->
%            event(kill, 56604, Rid#player_status.id);
%        false ->
%            false
%    end;
    
%% 高府大宅副本任务.
%preact_finish(101570, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 567) > 0 of
%        true ->
%            event(kill, 56704, Rid#player_status.id);
%        false ->
%            false
%    end;
    
%% 榕树林副本任务.
%preact_finish(101820, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 568) > 0 of
%        true ->
%            event(kill, 56804, Rid#player_status.id);
%        false ->
%            false
%    end;
    
%% 观音洞副本任务.
%preact_finish(102131, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 570) > 0 of
%        true ->
%            event(kill, 57004, Rid#player_status.id);
%        false ->
%            false
%    end;
    
%% 铜币副本任务.
%preact_finish(101683, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 650) > 0 of
%        true ->
%            event(kill, 65001, Rid#player_status.id);
%        false ->
%            false
%    end;
   

%% 新手装备副本任务.
%preact_finish(101520, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 900) > 1 of
%        true ->
%            event(kill, 90004, Rid#player_status.id);
%        false ->
%            false
%    end;

%% 经验副本任务.
%preact_finish(101973, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 630) > 0 of
%        true ->
%            event(kill, 63001, Rid#player_status.id),
%            event(kill, 63001, Rid#player_status.id),
%            event(kill, 63001, Rid#player_status.id);
%        false ->
%            false
%    end;


%% 再战宠物副本
%preact_finish(101521, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 233) > 0 of
%        true ->			
%            event(enter_scene, {233}, Rid#player_status.id);
%        false ->
%            false
%    end;


%% 战宠物副本
%preact_finish(101285, Rid) ->
%    case mod_daily:get_count(Rid#player_status.dailypid, Rid#player_status.id, 910) > 0 of
%        true ->			
%			event(kill, 91023, Rid#player_status.id);
%        false ->
%            false
%    end;

%% 888充值活动任务
%preact_finish(200120, Rid) ->
%	NowTime = util:unixtime(),
%	TimeConfig = data_activity_time:get_time_by_type(10),	
%	case TimeConfig of
%		[PayTaskStart, PayTaskEnd] -> skip;
%		[] -> 
%			PayTaskStart= util:unixtime({{2015, 10, 30}, {6, 0, 0}}),
%			PayTaskEnd = util:unixtime({{2016, 10, 30}, {6, 0, 0}})
%	end,
%	OpenDay = util:get_open_day(),
%	Pay_task_id = 200120,
%	case NowTime >= PayTaskStart andalso NowTime =< PayTaskEnd andalso util:get_open_day() > 5 of
%		true ->
%			TriggerTime = get_trigger_time(Pay_task_id),
%			case TriggerTime =/= false andalso TriggerTime =/=0 of
%				true -> %%　开服少于10天,查询接取任务到现在的充值
%					    %%  开服大于10天,查询活动期间的充值
%					case OpenDay>=10 of
%						true ->
%							PayTaskTotal1 = lib_recharge_ds:get_pay_task_total(Rid#player_status.id, PayTaskStart, PayTaskEnd),
%							PayTaskTotal2 = lib_recharge_ds:get_gold_goods_total(Rid#player_status.id, PayTaskStart, PayTaskEnd);
%						false ->
%							PayTaskTotal1 = lib_recharge_ds:get_pay_task_total(Rid#player_status.id, TriggerTime, NowTime),
%							PayTaskTotal2 = lib_recharge_ds:get_gold_goods_total(Rid#player_status.id, TriggerTime, NowTime)
%					end,
%					PayTaskTotal = PayTaskTotal1 + PayTaskTotal2,
%					event(pay_task, {PayTaskTotal}, Rid#player_status.id);
%				false -> skip
%			end;
%		_ ->
%			skip
%	end;

%% 首充活动任务
%preact_finish(200140, Rid) ->
%	case Rid#player_status.lv >= 20 andalso Rid#player_status.is_pay of
%		true ->
%			event(pay_task_2, {1}, Rid#player_status.id);
%		_ ->
%			skip
%	end;


%% 50级充值送水晶任务
%preact_finish(200290, Rid) ->
%	CrystalTask = 200290, 
%	case Rid#player_status.lv >= 50 andalso in_trigger(CrystalTask) of
%		true ->
%			private_finish_CrystalpayTask(Rid, CrystalTask);
%		false -> skip
%	end;
		

%% 60级充值送水晶任务
%preact_finish(200450, Rid) ->
%	CrystalTask = 200450, 
%	case Rid#player_status.lv >= 59 andalso in_trigger(CrystalTask) of
%		true ->
%			private_finish_CrystalpayTask(Rid, CrystalTask);
%		false -> skip
%	end;

preact_finish(TaskId, Rid) when is_integer(TaskId) ->
    RT = get_one_trigger(TaskId),
	case RT of
		false -> skip;
        _ -> preact_finish(RT, Rid)
	end;

preact_finish(RT, Rid) ->
    lists:member(true, [preact_finish_check([State, Fin | T], Rid) || [State, Fin | T] <- RT#role_task.mark, State =:= RT#role_task.state, Fin =:= 0]).

%% 装备武器
preact_finish_check([_, 0, equip, ItemId | _], PS) when is_record(PS, player_status)->
    Go = PS#player_status.goods,
    %% 这里只能限制是武器，和衣服 - 其他部位再改接口
    [EQ1, EQ2, _, _, _, _] = Go#status_goods.equip_current,
    if
        EQ1 == ItemId ->
            event(equip, {ItemId}, PS#player_status.id);
        EQ2 == ItemId ->
            event(equip, {ItemId}, PS#player_status.id);
        true ->
            false
    end;

%% 加入帮派
preact_finish_check([_, 0, join_guild | _], PS) when is_record(PS, player_status)->
    Gs = PS#player_status.guild,
    case Gs#status_guild.guild_id > 0 of
        true ->
            event(join_guild, do, PS#player_status.id);
        false ->
            false
    end;

%% 购买武器
preact_finish_check([_, 0, buy_equip, _ItemId | _], _PS) when is_record(_PS, player_status)->
    %%Dict = lib_goods_dict:get_player_dict(PS),
	%%case lib_goods_util:get_task_goods_num(PS#player_status.id, ItemId, Dict) > 0 andalso ItemId =:= 111024 of
    %%    false -> false;
    %%    true -> event(buy_equip, {ItemId}, PS#player_status.id)
    %%end;
	skip;

%% 学习技能
preact_finish_check([_, 0, learn_skill, SkillId | _], PS) when is_record(PS, player_status)->
    Sk = PS#player_status.skill,
    case lists:keyfind(SkillId, 1, Sk#status_skill.skill_list) of
        false -> %% 还没学习过
            false;
        _ -> %% 学习了，升级
            event(learn_skill, {SkillId}, PS#player_status.id)
    end;

%% 收集物品
preact_finish_check([_, 0, item, ItemId, _, NowNum | _], PS) when is_record(PS, player_status) ->
    Dict = lib_goods_dict:get_player_dict(PS),
    Num = lib_goods_util:get_task_goods_num(PS#player_status.id, ItemId, Dict),
    case Num >  NowNum of
        false -> 
            false;
        true -> 
            event(item, [{ItemId, Num}], PS#player_status.id)
    end;

preact_finish_check(_, _) ->
    false.

%% 检测任务是否完成
is_finish(TaskId, PS) when is_integer(TaskId) ->
    case get_one_trigger(TaskId) of
        false -> false;
        RT -> is_finish(RT, PS)
    end;

is_finish(RT, PS) when is_record(RT, role_task) ->
    is_finish_mark(RT#role_task.mark, PS);

is_finish(Mark, PS) when is_list(Mark) ->
    is_finish_mark(Mark, PS).

is_finish_mark([], _) ->
    true;
is_finish_mark([MarkItem | T], PS) ->
    case check_content(MarkItem, PS) of
        false -> false;
        true -> is_finish_mark(T, PS)
    end.

%% 完成任务
finish(TaskId, ParamList, PS) ->
    case special_task(TaskId, PS) of
       false -> %% 普通任务
           normal_finish(TaskId, ParamList, PS);
       {xlqy, _TD} -> %% 做完仙侣特殊处理后会走回normal_finish/4
           lib_appointment:finish_task(TaskId, ParamList, PS);
       {eb, _TD} ->
           lib_task_eb:finish_task(TaskId, ParamList, PS);
       {sr, _TD} ->
           lib_task_sr:finish_task(TaskId, ParamList, PS);
       {fly_mount, TD} ->
           lib_fly_mount:finish_task(TD, PS);
       {husong, _TD} ->
           lib_husong:finish_task(TaskId, ParamList, PS);
	   {zyl, _TD} ->
           lib_task_zyl:finish_task(TaskId, ParamList, PS);
	   {bpsl, _TD} ->
		   lib_fortune:task_finish_task_mod(TaskId, ParamList, PS)
   end.

%% 奖励为原来任务设置
normal_finish(TaskId, ParamList, PS) ->
    normal_finish(TaskId, ParamList, PS, 1).

%% RewardRatio:奖励倍数
normal_finish(TaskId, _ParamList, RS, RewardRatio) ->
    Go = RS#player_status.goods,
    case is_finish(TaskId, RS) of
        false -> {false, data_task_text:get_text(2)};
        true ->
            TD = get_data(TaskId, RS),
            case award_condition(TD, RS) of
                {false, Reason} -> {false, Reason};
                {true, RS0} ->
                    %% 回收物品
                    case length(TD#task.end_item) > 0 of
                        true -> gen_server:call(Go#status_goods.goods_pid, {'delete_type', [ ItemId || {ItemId, _} <- TD#task.end_item]});
                        false -> false
                    end,				
                    %% 奖励固定物品
                    case get_award_item(TD, RS0) of
                        [] -> false;
                        Items ->
							Go0 = RS0#player_status.goods,                        
							ErrorCode = gen_server:call(Go0#status_goods.goods_pid, {'give_more_bind', RS0, Items}),
							case ErrorCode of
								ok ->				
									GiveList = [{goods, GoodsTypeId, GoodsNum} ||{GoodsTypeId, GoodsNum} <- Items],
									%[{GoodsTypeId, GoodsNum}] = Items,											
									%GiveList = [{goods, GoodsTypeId, GoodsNum}],
									lib_gift_new:send_goods_notice_msg(RS, GiveList);
								_ -> skip
							end                            
                    end,
                    %% 礼包
                    %R3 = case length(get_award_gift(TD, RS)) > 0 of
                    %    true ->
                    %        [lib_gift:send_gift(RS0#player_status.id, GiftId) || {GiftId, _} <- get_award_gift(TD, RS)],
                    %        true;
                    %    false -> false
                    %end,

                    %% 暂时屏蔽可选奖励共呢，奖励可选物品
                    %R3 = case length(TD#task.award_select_item) > 0 of
                    %    true ->
                    %        case [{Xid, Xnum} || {Xid, Xnum} <- TD#task.award_select_item, Yid <- ParamList, Xid =:= Yid] of
                    %            [] -> false;
                    %            SIL ->
                    %                lib_item:send_items_to_bag(SIL, RS#role_state.id)
                    %        end;
                    %    false -> false
                    %end,
                    %% 经验累积
                    %Ratio = lib_task_cumulate:get_ratio(TD),
                    %%io:format("Ratio:~p~n",[Ratio]),
                    case TD#task.contrib > 0 of
                        true -> lib_guild:add_donation(RS#player_status.id, round(TD#task.contrib * RewardRatio), 0);
                        false -> false
                    end,
                    RS1 = case TD#task.coin > 0 of
                        true -> RS0#player_status{coin = RS0#player_status.coin + round(TD#task.coin * RewardRatio)};
                        false -> RS0
                    end,
					%% 活动经验加成0.2
					case lists:member(TD#task.type, [9,14,15]) andalso  lib_off_line:activity_time() of
						true ->  ActivityRatio =0.2;
						false -> ActivityRatio =0
					end,
                    RS2 = lib_player:add_exp(RS1, round(TD#task.exp * (RewardRatio+ActivityRatio)), 0), %% 不受仿沉迷限制
                    RS3 = case TD#task.spt > 0 of
%%                         true -> RS2#player_status{spirit = RS2#player_status.spirit + round(TD#task.spt * RewardRatio)};
						true -> RS2;
                        false -> RS2
                    end,
                    RS4 = case TD#task.binding_coin > 0 of
                        true -> RS3#player_status{bcoin = RS3#player_status.bcoin + round(TD#task.binding_coin * RewardRatio)};
                        false -> RS3
                    end,
                    RS5 = case TD#task.llpt > 0 of
                        true -> 
							AddLLPT = round(TD#task.llpt * RewardRatio),
							%% 限时名人堂: 获得历练
							TmpRS4 = lib_fame_limit:trigger_pt(RS4, AddLLPT),

							TmpRS4#player_status{llpt = TmpRS4#player_status.llpt + AddLLPT};
                        false -> RS4
                    end,
                    RS6 = case TD#task.xwpt > 0 of
                        true -> RS5#player_status{xwpt = RS5#player_status.xwpt + round(TD#task.xwpt * RewardRatio)};
                        false -> RS5
                    end,
                    RS7 = case TD#task.fbpt > 0 of
                        true -> RS6#player_status{fbpt = RS6#player_status.fbpt + round(TD#task.fbpt * RewardRatio)};
                        false -> RS6
                    end,
                    RS8 = case TD#task.bppt > 0 of
                        true -> RS7#player_status{bppt = RS7#player_status.bppt + round(TD#task.bppt * RewardRatio)};
                        false -> RS7
                    end,
                    RS9 = case TD#task.gjpt > 0 of
                        true -> RS8#player_status{gjpt = RS8#player_status.gjpt + round(TD#task.gjpt * RewardRatio)};
                        false -> RS8
                    end,
                    LastRS = RS9,

                    %% 塔防积分
                    %case TD#task.attainment > 0 of
                    %    true ->
                    %        lib_td_battle:add_td_score(LastRS,TD#task.attainment);
                    %    false ->
                    %        skip
                    %end,

                    lib_player:add_task_award(LastRS),
                    Time = util:unixtime(),
                    RT = get_one_trigger(TaskId),
                    %% 数据库回写
                    add_log(RS#player_status.id, TaskId, TD#task.type, RT#role_task.trigger_time, Time),											

                    refresh_active(LastRS),					
                    %% 完成后一些特殊操作
                    case LastRS =/= RS of
                        true -> lib_player:send_attribute_change_notify(LastRS, 0);
                        false -> ok
                    end,
                    if
                        %% 新手宠物副本任务.
                        TaskId == 101285 ->
                            lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 910);
                        %% 铜币副本任务.
                        TaskId == 200180 ->
                            lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 650);                            
%%                         %% 阴曹地府副本任务.
%%                         TaskId == 101270 ->
%%                             lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 500);                            
%%                         %% 云栈洞府副本任务.
%%                         TaskId == 101730 ->
%%                             lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 561);
%%                         %% 鼠圣地宫副本任务.
%%                         TaskId == 100441 ->
%%                             lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 562);
%%                         %% 密林狼巢副本任务.
%%                         TaskId == 100950 ->							
%%                             lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 563);
%%                         %% 黑风山脚副本任务.
%%                         TaskId == 102220 ->
%%                             lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 564);
%%                         %% 黑风洞副本任务.
%%                         TaskId == 102330 ->
%%                             lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 565);
%%                         %% 云虚洞副本任务.
%%                         TaskId == 101331 ->
%%                             lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 566);
%%                         %% 高府大宅副本任务.
%%                         TaskId == 101570 ->
%%                             lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 567);
%%                         %% 榕树林副本任务.
%%                         TaskId == 101820 ->
%%                             lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 568);
%%                         %% 观音洞副本任务.
%%                         TaskId == 102131 ->
%%                             lib_dungeon:minus_dungeon_count(LastRS#player_status.id, LastRS#player_status.dailypid, 570);                                                        
                        true ->
                            skip
                    end,					

					NewLastRS = case TD#task.type of
						2 ->
							%% 日常任务：目前仅为阵营任务
							mod_daily:increment(RS#player_status.dailypid, RS#player_status.id, 6000004),
							Dialy_num_6 = mod_daily:get_count(RS#player_status.dailypid, RS#player_status.id, 6000004),
                            mod_active:trigger(RS#player_status.status_active, 16, 0, RS#player_status.vip#status_vip.vip_type),
							%% 运势任务(3700011:阵营荣耀)
							case RS#player_status.lv>=60 of
								true ->
									case Dialy_num_6>=1 of
										true ->  Is_increment_37 =  true;
										false -> Is_increment_37 =  false
									end;
								false ->
									case Dialy_num_6>=3 of
										true ->  Is_increment_37 =  true;
										false -> Is_increment_37 =  false
									end
							end,
							case Is_increment_37 of
								true ->									
									lib_fortune:fortune_daily(RS#player_status.id, 3700011, 1),											
									mod_daily:increment(RS#player_status.dailypid, RS#player_status.id, 3700011);
								false -> skip
							end,
							LastRS;
						7 -> 
							%% 护送任务
				 			mod_daily:increment(RS#player_status.dailypid, RS#player_status.id, 4700),
							LastRS;
                        9 -> 
							%% 诛妖任务
							mod_daily:increment(RS#player_status.dailypid, RS#player_status.id, 6000000),
							mod_achieve:trigger_task(LastRS#player_status.achieve, LastRS#player_status.id, 9, 0, 1),
							lib_task_cumulate:finish_task(LastRS#player_status.id, 4),
							%% 完成20次诛妖任务
							mod_active:trigger(LastRS#player_status.status_active, 11, 0, LastRS#player_status.vip#status_vip.vip_type),
							lib_off_line:add_off_line_count(LastRS#player_status.id, 3, 1, 0),
							LastRS;
						10 ->
							%% 仙侣奇缘任务
							mod_daily:increment(RS#player_status.dailypid, RS#player_status.id, 3800),
							LastRS;
						13 ->
							%% 试炼任务
							mod_daily:increment(RS#player_status.dailypid, RS#player_status.id, 6000003),
							LastRS;
						14 -> 
							%% 皇榜任务 
							mod_daily:increment(RS#player_status.dailypid, RS#player_status.id, 6000001),
							mod_achieve:trigger_task(LastRS#player_status.achieve, LastRS#player_status.id, 14, 0, 1),
							lib_task_cumulate:finish_task(LastRS#player_status.id, 2),
							mod_active:trigger(LastRS#player_status.status_active, 10, 0, LastRS#player_status.vip#status_vip.vip_type),
							lib_off_line:add_off_line_count(LastRS#player_status.id, 1, 1, 0),							
							LastRS;
						15 ->
							%% 平乱任务
							mod_daily:increment(RS#player_status.dailypid, RS#player_status.id, 6000002),
							mod_achieve:trigger_task(LastRS#player_status.achieve, LastRS#player_status.id, 15, 0, 1),
							lib_task_cumulate:finish_task(LastRS#player_status.id, 3),
							mod_active:trigger(LastRS#player_status.status_active, 9, 0, LastRS#player_status.vip#status_vip.vip_type),
							lib_off_line:add_off_line_count(LastRS#player_status.id, 2, 1, 0),
							LastRS;
						_ ->
							LastRS
                    end,
                    %% 成就：漫漫西行路，完成所有新手引导任务，本阵营主线任务，长安、高老庄、花果山、九原、苗疆、骊山主线任务
                    mod_achieve:trigger_task(NewLastRS#player_status.achieve, NewLastRS#player_status.id, 0, TaskId, 1),
					%% 完成了50级水晶任务, 主动接取60级水晶任务[含时间判断]
					case TaskId =:= 200290 of
						true -> trigger_crystal_task(NewLastRS);
						false -> skip
					end,
                    {true, NewLastRS}
            end
    end.

%% 奖励物品所需要的背包空间
award_item_num(TD, PS) ->
    %length(get_award_item(TD, PS)) + length(get_award_gift(TD, PS)) + TD#task.award_select_item_num - length(TD#task.end_item).
    length(get_award_item(TD, PS)).

%% 检查是否能完成奖励的条件
award_condition(TD, RS) ->
    Go = RS#player_status.goods,
    case gen_server:call(Go#status_goods.goods_pid, {'cell_num'}) < award_item_num(TD, RS) of
        true -> {false, data_task_text:get_text(3)};  %% 空位不足
        false ->
            {true, RS}
%            F = fun(ItemId, Num) ->
%                lib_item:query_bag_item_num(ItemId, RS#player_status.id) < Num
%            end,
%            case length([0 || {I, N} <- TD#task.end_item, F(I, N)]) =/= 0 of
%                true -> {false, data_task_text:get_text(4)};  %% 回收物品不足
%                false ->
%                    case lib_role:spend_coin(RS, TD#task.end_cost) of
%                        {false} -> {false, data_task_text:get_text(5)}; %% 上交金钱不足
%                        {true, RS1} ->
%                            case TD#task.contrib > 0 of
%                                false -> {true, RS1};
%                                true ->
%                                    G = lib_guild:get_guild_contrib_today(RS#player_status.guild_id, RS#player_status.id),
%                                    case G + TD#task.contrib > 1000 of
%                                        true -> {false, data_task_text:get_text(6)};
%                                        false -> {true, RS1}
%                                    end
%                            end
%                    end
%            end
    end.


%% 放弃任务
abnegate(TaskId, PS) ->
    case get_one_trigger(TaskId) of
        false -> false;
        RT ->
            case special_task(TaskId, PS) of
                {xlqy, _} -> 
                    case lib_appointment:cancel_appointment_task(PS, RT) of
                        true ->
                            del_trigger(PS#player_status.id, TaskId),
                            refresh_active(PS),
                            true;
                        false ->
                            false
                    end;
                {eb, _} ->
                    lib_task_eb:cancel_task(PS, TaskId),
                    del_trigger(PS#player_status.id, TaskId),
                    refresh_active(PS),
                    true;
                {sr, _} ->
                    lib_task_sr:cancel_task(PS, TaskId),
                    del_trigger(PS#player_status.id, TaskId),
                    refresh_active(PS),
                    true;
                {fly_mount, _} ->
                    NewPS = lib_fly_mount:cancel_task(PS, TaskId),
                    del_trigger(NewPS#player_status.id, TaskId),
                    refresh_active(NewPS),
                    {true, NewPS};
                {husong, _} ->
                    NewPS = lib_husong:cancel_task(PS, TaskId),
                    del_trigger(NewPS#player_status.id, TaskId),
                    refresh_active(NewPS),
                    {true, NewPS};
                {zyl, _} ->
                    lib_task_zyl:cancel_task(PS, TaskId),
                    del_trigger(PS#player_status.id, TaskId),
                    refresh_active(PS),
                    true;
                _Other ->
                    del_trigger(PS#player_status.id, TaskId),
                    refresh_active(PS),
                    true
            end
    end.


%% 或任务奖励的数据，帮会任务的个人经验和帮贡要做特殊处理、
get_award_data() ->
    ok.

%% 组织奖励的描述信息
get_award_msg(TD, PS) ->
    Msg = data_task_text:get_award_msg(),
    list_to_binary(
    [
        Msg,
        case TD#task.exp>0 of
            false -> [];
            true -> 
                Msg1 = data_task_text:get_award_msg(1),
                [Msg1, integer_to_list(TD#task.exp), <<" ">>]
        end,
        case TD#task.coin > 0 of
            false -> [];
            true ->
                Msg1 = data_task_text:get_award_msg(2),
                [Msg1, integer_to_list(TD#task.coin), <<" ">>]
        end,
        case TD#task.binding_coin > 0 of
            false -> [];
            true -> 
                Msg1 = data_task_text:get_award_msg(3),
                [Msg1, integer_to_list(TD#task.binding_coin), <<" ">>]
        end,
        case TD#task.spt > 0 of
            false -> [];
            true -> 
                Msg1 = data_task_text:get_award_msg(4),
                [Msg1, integer_to_list(TD#task.spt), <<" ">>]
        end,
        case TD#task.attainment > 0 of
            false -> [];
            true -> 
                Msg1 = data_task_text:get_award_msg(5),
                [Msg1, integer_to_list(TD#task.attainment), <<" ">>]
        end,
        case TD#task.llpt > 0 of
            false -> [];
            true -> 
                Msg1 = data_task_text:get_award_msg(6),
                [Msg1, integer_to_list(TD#task.llpt), <<" ">>]
        end,
        case TD#task.xwpt > 0 of
            false -> [];
            true -> 
                Msg1 = data_task_text:get_award_msg(7),
                [Msg1, integer_to_list(TD#task.xwpt), <<" ">>]
        end,
        case TD#task.fbpt > 0 of
            false -> [];
            true -> 
                Msg1 = data_task_text:get_award_msg(8),
                [Msg1, integer_to_list(TD#task.fbpt), <<" ">>]
        end,
        case TD#task.bppt > 0 of
            false -> [];
            true -> 
                Msg1 = data_task_text:get_award_msg(9),
                [Msg1, integer_to_list(TD#task.bppt), <<" ">>]
        end,
        case TD#task.gjpt > 0 of
            false -> [];
            true -> 
                Msg1 = data_task_text:get_award_msg(10),
                [Msg1, integer_to_list(TD#task.gjpt), <<" ">>]
        end,
        case length(TD#task.award_item) > 0 orelse length(TD#task.award_gift) > 0 of
            false -> [];
            true ->
                
                %% TODO 暂时没有礼包获取名字的接口
                %ItemNameList = [get_item_name(ItemId) || {ItemId, _} <- get_award_item(TD, PS)] ++ [lib_gift:get_name(GiftId) || {GiftId, _} <- get_award_gift(TD, PS)],
                ItemNameList = [get_item_name(ItemId) || {ItemId, _} <- get_award_item(TD, PS)],
                Msg1 = data_task_text:get_award_msg(11),
                [Msg1, util:implode("、", ItemNameList), <<" ">>]

        end
%        case TD#task.contrib > 0 of
%            false -> [];
%            true -> [data_task_text:get_text(7), integer_to_list(TD#task.contrib), <<" ">>]
%        end,
%        case TD#task.guild_exp > 0 of
%            false -> [];
%            true -> [data_task_text:get_text(8), integer_to_list(TD#task.guild_exp), <<" ">>]
%        end
    ]).


%% 杀怪事件
action(0, Rid, kill, ParamList)->
    case get_task_bag_id_list_kind(1) of
        [] -> false;
        RTL ->
            Result = [action_one(RT, Rid, kill, ParamList)|| RT<- RTL],
            lists:member(true, Result)
    end;

%% 已接所有任务更新判断
action(0, Rid, Event, ParamList)->
    case get_task_bag_id_list() of
        [] -> false;
        RTL ->
            Result = [action_one(RT, Rid, Event, ParamList)|| RT<- RTL],
            lists:member(true, Result)
    end;

%% 单个任务更新判断
action(TaskId, Rid, Event, ParamList)->
    case get_one_trigger(TaskId) of
        false -> false;
        RT -> action_one(RT, Rid, Event, ParamList)
    end.

action_one(RT, Rid, Event, ParamList) ->
    F = fun(MarkItem, Update)->
        [State, Finish, Eve| _T] = MarkItem,
        case State =:= RT#role_task.state andalso Finish =:= 0 andalso Eve=:=Event of
            false -> {MarkItem, Update};
            true ->
                {NewMarkItem, NewUpdate} = content(MarkItem, Rid, ParamList ),				
                case NewUpdate of
                    true -> {NewMarkItem, true};
                    false -> {NewMarkItem, Update}
                end
            end
        end,
    {NewMark, UpdateAble} = lists:mapfoldl(F ,false, RT#role_task.mark),
    case UpdateAble of
        false ->
            false;
        true ->
            NewState = case lists:member(false, [Fi=:=1||[Ts,Fi|_T1 ] <- NewMark,Ts=:=RT#role_task.state]) of
                true -> RT#role_task.state; %%当前阶段有未完成的
                false -> RT#role_task.state + 1 %%当前阶段有未完成的
            end,
            %% 更新任务记录和任务状态
            put_task_bag_list(RT#role_task{state=NewState, mark = NewMark}),
            if
                NewState > 0 ->
                    mod_task:refresh_npc_ico(Rid);
                    %{ok, BinData} = pt_30:write(30006, []),
                    %lib_send:send_to_uid(Rid, BinData);
                true ->
                    ok
            end,
            %% 通知客户端刷新任务栏
            TipList = get_tip(trigger, RT#role_task.task_id, Rid),
            {ok, BinData} = pt_302:write(30200, [RT#role_task.task_id, TipList]),
            lib_server_send:send_to_uid(Rid, BinData),
			
			case pet_grow_up =:= Event  of
	 			true ->
					mod_daily_dict:decrement(Rid, 5000000);
				false -> skip
			end,
            true
    end.


%% 检查物品是否为任务需要
can_gain_item(ItemId) ->
    case get_task_bag_id_list() of
        [] -> false;
        RTL ->
            Result = [can_gain_item(marklist, get_phase_unfinish(RT), ItemId) || RT <- RTL],
            lists:member(true, Result)
    end.

can_gain_item(marklist, MarkList, ItemId) ->
    length([0 || [_, _, Type, Id | _T] <- MarkList, Type =:= item, Id =:= ItemId])>0.

%% 检查物品是否为任务需要 返回所需要的物品ID列表
can_gain_item() ->
    case get_task_bag_id_list() of
        [] -> [];
        RTL ->
            F = fun(RT) ->
            		MarkList = get_phase_unfinish(RT),
                [{Id, Num, NowNum} || [_, _, Type, Id, Num, NowNum | _T] <- MarkList, Type =:= item]
            end,
            lists:flatmap(F, RTL)
    end.


%% pvp战斗完成时，需要失去的任务物品
%% pvp_task_item(Winners, Losers) ->
%%     LosersItem = [{Rid, get_loser_lose_item(Rid)} || Rid <- Losers],
%%     WinnerItam = [{Rid, get_winner_gain_item(Rid)} || Rid <- Winners],
%%     {WinnerItam, LosersItem}.
%% 
%% 
%% %% 获取失败者要掉出的任务品
%% get_loser_lose_item(Rid) ->
%%     case srv_yunbiao:is_trigger(Rid) of
%%         false -> [];
%%         true -> srv_yunbiao:get_task_item()
%%     end.
%% 
%% %% 获取胜利者可以得到的任务物品
%% get_winner_gain_item(Rid) ->
%%     case srv_yunbiao:can_rob(Rid) of   %% 检测今天还能不能再劫镖
%%         false -> [];
%%         true -> srv_yunbiao:get_task_item()
%%     end.

after_event(Rid) ->
    %% TODO 后续事件提前完成检测
    case preact_finish(Rid) of
        true -> ok;
        false ->
            %% TODO 通知角色数据更新
            refresh_npc_ico(Rid),
            {ok, BinData} = pt_300:write(30006, []),
            lib_server_send:send_to_uid(Rid, BinData)
    end.

%% 后续扩展------------------------------------

%% 对话事件
event(talk, {TaskId, NpcId}, Rid) ->
    action(TaskId, Rid, talk,[NpcId]);

%% 打怪事件成功
event(kill, Monid, Rid) ->
    action(0, Rid, kill, Monid);


%% 获得物品事件
event(item, ItemList, Rid) ->
    action(0, Rid, item, [ItemList]);

%% 打开商城事件
%event(open_store, _, Rid) ->

%% 添加好友
event(add_friend, _, Rid) ->
    action(0, Rid, add_friend, []);

%% 存入仓库物品
event(movein_storage, _, Rid) ->
    action(0, Rid, movein_storage, []);

%% 仙侣情缘
event(xlqy, _, Rid) ->
    action(0, Rid, xlqy, []);

%% 英雄任务
event(yxrw, _, Rid) ->
    action(0, Rid, yxrw, []);

%% 强化任务
event(qh, _, Rid) ->
    action(0, Rid, qh, []);

%% 鉴定任务
event(jd, _, Rid) ->
    action(0, Rid, jd, []);

%% 炼化任务
event(lh, _, Rid) ->
    action(0, Rid, lh, []);

%% 分解任务
event(fj, _, Rid) ->
    action(0, Rid, fj, []);

%% 帮派贡献
event(bpgx, _, Rid) ->
    action(0, Rid, bpgx, []);

%% 帮战积分
event(bzjf, _, Rid) ->
    action(0, Rid, bzjf, []);

%% 加入帮会
event(join_guild, _, Rid) ->
    action(0, Rid, join_guild, []);

%% 技能学习
event(learn_skill, {SkillId}, Rid) ->
    action(0, Rid, learn_skill, [SkillId]);

%% 装备物品事件
event(equip, {ItemId}, Rid) ->
    action(0, Rid, equip, [ItemId]);

%% 使用物品事件
event(use_equip, {ItemId}, Rid) ->
    action(0, Rid, use_equip, [ItemId]);

%% 指定场景使用物品
event(use_goods, {Scene, X, Y, ItemId}, Rid) ->
    action(0, Rid, use_goods, [Scene, X, Y, ItemId]);

%% 发送大表情
event(big_face, {FaceId}, Rid) ->
    action(0, Rid, big_face, [FaceId]);

%% 购买物品事件
event(buy_equip, {ItemId}, Rid) ->
    action(0, Rid, buy_equip, [ItemId]);

%% 击败NPC分身
event(kill_avatar, {NpcId}, Rid) ->
    action(0, Rid, kill_avatar, [NpcId]);

%% 宠物融合
event(pet_derive, _, Rid) ->
	action(0, Rid, pet_derive, []);

%% 宠物成长
event(pet_grow_up, _, Rid) ->
	action(0, Rid, pet_grow_up, []);

%% 进入指定场景
event(enter_scene, {SceneId}, Rid) ->
	action(0, Rid, enter_scene, [SceneId]);

%% 充值活动任务
event(pay_task, {PayCount}, Rid) ->
	action(0, Rid, pay_task, [PayCount]);

%% 普通充值任务
event(pay_task_2, {PayCount}, Rid) ->
	action(0, Rid, pay_task_2, [PayCount]).

%% 打怪事件失败
%% event(die, Rid) ->
%%     case srv_yunbiao:is_trigger(Rid) of
%%         false -> false;
%%         true -> %%srv_yunbiao:lose(Rid)
%%             srv_role:cast(Rid, {srv_yunbiao, lose, []}),
%%             true
%%     end.

%% 条件
%% 是否完成任务
check_condition({task, TaskId}, _, _) ->
    find_task_log_exits(TaskId);

%% 是否完成其中之一的任务
check_condition({task_one, TaskList}, _, _) ->
    lists:any(fun(Tid)-> find_task_log_exits(Tid) end, TaskList);

%% 今天的任务次数是否过多
check_condition({daily_limit, Num}, TaskId, _) ->
    get_today_count(TaskId) < Num;

%% 帮会任务等级
check_condition({guild_level, _Lev}, _, PS) ->
    Gs = PS#player_status.guild,
    case Gs#status_guild.guild_id > 0 of
        false -> false;
        true ->
            true
            %case lib_guild:get_guild_lev_by_id(Gs#status_guild.guild_id) of
            %    null -> false;
            %    GLevel -> GLevel >= Lev
            %end
    end;

%% 容错
check_condition(_Other, _, _PS) ->
    false.

check_condition_daily_limit([], _, Num, _, _) ->
    Num > 0;
check_condition_daily_limit([RTL | T], TaskId, Num, TodaySec, TomorrowSec) ->
    case
        TaskId =:= RTL#role_task_log.task_id andalso
        RTL#role_task_log.finish_time > TodaySec andalso
        RTL#role_task_log.finish_time < TomorrowSec
    of
        false -> check_condition_daily_limit(T, TaskId, Num, TodaySec, TomorrowSec);
        true -> %% 今天所完成的任务
            case Num - 1 > 0 of
                true -> check_condition_daily_limit(T, TaskId, Num - 1, TodaySec, TomorrowSec);
                false -> false
            end
    end.

%% 检测任务内容是否完成
check_content([_, Finish, kill, _NpcId, Num, NowNum], _Rid) ->
    Finish =:=1 orelse Num =:= NowNum;

check_content([_, Finish, talk, _, _], _Rid) ->
    Finish =:=1;

check_content([_, Finish, item, _, Num, NowNum], _Rid) ->
    Finish =:=1 orelse Num =:= NowNum;

check_content([_, Finish | _], _Rid) ->
    Finish =:= 1;

check_content(Other, _PS) ->
    ?DEBUG("错误任务内容~p",[Other]),
    false.

%% 杀怪
content([State, 0, kill, NpcId, Num, NowNum], _Rid, NpcList) ->
    case NpcId =:= NpcList of
        false ->
			{[State, 0, kill, NpcId, Num, NowNum], false};
        true ->
            case NowNum + 1 >= Num of
                true -> {[State,1 , kill , NpcId, Num, Num],  true};
                false ->{[State,0 , kill , NpcId, Num, NowNum + 1], true}
            end
    end;

%% 对话
content([State, 0, talk, NpcId, TalkId], _Rid, [NowNpcId]) ->
    case NowNpcId =:= NpcId of
        true -> {[State, 1, talk, NpcId, TalkId], true};
        false -> {[State, 0, talk, NpcId, TalkId], false}
    end;

%% 物品
content([State, 0, item, ItemId, Num, NowNum], _Rid, [ItemList]) ->
    case [XNum || {XItemId, XNum} <- ItemList, XItemId =:= ItemId] of
        [] -> {[State, 0, item, ItemId, Num, NowNum], false}; %% 没有任务需要的物品
        [HaveNum | _] ->
            case HaveNum+NowNum >= Num of
                true -> {[State, 1, item, ItemId, Num, Num], true};
                false -> {[State, 0, item, ItemId, Num, HaveNum+NowNum], true}
            end
    end;

%% 打开商城
%content([State, 0, open_store], _Rid, _) ->
%    {[State, 1, open_store], true};

%% 添加好友
content([State, 0, add_friend], _Rid, _) ->
    {[State, 1, add_friend], true};

%% 存入仓库物品
content([State, 0, movein_storage], _Rid, _) ->
    {[State, 1, movein_storage], true};

%% 仙侣情缘
content([State, 0, xlqy], _Rid, _) ->
    {[State, 1, xlqy], true};

%% 英雄任务
content([State, 0, yxrw], _Rid, _) ->
    {[State, 1, yxrw], true};

%% 帮战积分
content([State, 0, bzjf], _Rid, _) ->
    {[State, 1, bzjf], true};

%% 强化任务
content([State, 0, qh], _Rid, _) ->
    {[State, 1, qh], true};

%% 鉴定任务
content([State, 0, jd], _Rid, _) ->
    {[State, 1, jd], true};

%% 炼化任务
content([State, 0, lh], _Rid, _) ->
    {[State, 1, lh], true};

%% 分解任务
content([State, 0, fj], _Rid, _) ->
    {[State, 1, fj], true};

%% 帮派贡献
content([State, 0, bpgx], _Rid, _) ->
    {[State, 1, bpgx], true};

%% 加入帮派
content([State, 0, join_guild], _Rid, _) ->
    {[State, 1, join_guild], true};

%% 购买物品
content([State, 0, buy_equip, ItemId | _], _Rid, [NowItemId]) ->
    case NowItemId =:= ItemId of
        false -> {[State, 0, buy_equip, ItemId], false};
        true -> {[State, 1, buy_equip, ItemId], true}
    end;

%% 装备物品
content([State, 0, equip, ItemId], _Rid, [NowItemId]) ->
    case NowItemId =:= ItemId of
        false -> {[State, 0, equip, ItemId], false};
        true -> {[State, 1, equip, ItemId], true}
    end;

%% 使用物品
content([State, 0, use_equip, ItemId], _Rid, [NowItemId]) ->
    case NowItemId =:= ItemId of
        false -> {[State, 0, use_equip, ItemId], false};
        true -> {[State, 1, use_equip, ItemId], true}
    end;

%% 指定场景使用物品
%%content([State, 0, use_goods, SceneId, X, Y, ItemId], _Rid, [NowSceneId, _NowX, _NowY, NowItemId]) ->
%%	io:format("-----SceneId----NowSceneId----ItemId--NowItemId-[~p,~p,~p,~p]",[SceneId, NowSceneId, ItemId, NowItemId]),
%%    case SceneId =:= NowSceneId andalso ItemId =:= NowItemId of
%%		false -> {[State, 0, use_goods, SceneId, X, Y, ItemId], false};
%%        true -> {[State, 1, use_goods, SceneId, X, Y, ItemId], true}
%%    end;


%% 指定场景使用物品
content([State, 0, use_goods, SceneId, X, Y, _ItemId], _Rid, [NowSceneId, _NowX, _NowY, _NowItemId]) ->
    case SceneId =:= NowSceneId of
		false -> {[State, 0, use_goods, SceneId, X, Y, _ItemId], false};
        true -> {[State, 1, use_goods, SceneId, X, Y, _ItemId], true}
    end;


%% 技能学习
content([State, 0, learn_skill, SkillId], _Rid, [NowSkillId]) ->
    case NowSkillId =:= SkillId of
        false -> {[State, 0, learn_skill, SkillId], false};
        true -> {[State, 1, learn_skill, SkillId], true}
    end;

%% 发送大表情
content([State, 0, big_face, _, FaceId], _Rid, [NowFaceId]) ->
    case NowFaceId =:= FaceId of
        false -> {[State, 0, big_face, FaceId], false};
        true -> {[State, 1, big_face, FaceId], true}
    end;

%% 击败NPC分身
content([State, 0, kill_avatar, NpcId], _Rid, [NowNpcId]) ->
    case NowNpcId =:= NpcId of
        false -> {[State, 0, kill_avatar, NpcId], false};
        true -> {[State, 1, kill_avatar, NpcId], true}
    end;

%% 宠物融合
content([State, 0, pet_derive], _Rid, _) ->
    {[State, 1, pet_derive], true};

%% 宠物成长
content([State, 0, pet_grow_up], _Rid, _) ->
    {[State, 1, pet_grow_up], true};

%% 进入指定场景
content([State, 0, enter_scene, SceneId], _Rid, [NowSceneId]) ->
    case NowSceneId =:= SceneId of
        false -> {[State, 0, enter_scene, SceneId], false};
        true -> {[State, 1, enter_scene, SceneId], true}
    end;

%% 充值活动任务
content([State, 0, pay_task, PayCount], _Rid, [NowPayCount]) ->
	case NowPayCount >= PayCount of
        false ->
			{[State, 0, pay_task, PayCount], false};
        true ->
			{[State, 1, pay_task, PayCount], true}
    end;

%% 普通充值任务
content([State, 0, pay_task_2, PayCount], _Rid, [NowPayCount]) ->
	case NowPayCount >= PayCount of
        false ->
			{[State, 0, pay_task_2, PayCount], false};
        true ->
			{[State, 1, pay_task_2, PayCount], true}
    end;

%% 容错
content(MarkItem, _Other, _Other2) ->
    {MarkItem, false}.

%% 放弃任务后执行操作
after_finish(TaskId, _PS) when TaskId >= 1000000 andalso TaskId =< 1000003 ->
%    srv_yunbiao:after_finish(TaskId, PS);
    ok;

after_finish(_TaskId, _PS) ->
    ok.

%% 获取活动期间物品
get_active_item(_) ->
    [].
%get_active_item(TD) ->
%    [].
%    case mod_game_buff:check_buff(4) of
%        1 -> %% 无效
%            [];
%        _ -> %% {职业,物品id,数量}
%            case TD#task.type of
%                2 ->
%                    [{0,0,611601,1}];
%                3 ->
%                    [{0,0,611601,1}];
%                4 ->
%                    [{0,0,611601,1}];
%                5 ->
%                    [{0,0,611601,1}];
%                6 ->
%                    [{0,0,611601,1}];
%                9 ->
%                    [{0,0,611601,1}];
%                _ ->
%                    []
%            end
%    end.

%% 任务失败,算完成了任务一次(超时或者放弃)
task_fail(PS, RT) ->
    add_log(PS#player_status.id, RT#role_task.task_id, RT#role_task.type, RT#role_task.trigger_time, util:unixtime()),
    refresh_active(PS).

%% 是否是需要特殊处理的任务
special_task(TaskId, PS) ->
    case get_data(TaskId, PS) of
        null -> false;
        TD ->
            IsFlyTask = lists:member(TaskId, ?FLY_TASK),
            IsXSHusongTask = lists:member(TaskId, ?XS_HUSONG_TASK),
            if
                TD#task.type == 10 ->     {xlqy, TD};       %% 仙侣任务
				TD#task.type == 13 ->     {bpsl, TD};       %% 帮派试炼任务
                TD#task.type == 14 ->     {eb, TD};         %% 皇榜任务
                TD#task.type == 15 ->     {sr, TD};         %% 平乱任务
				TD#task.type == 9 ->      {zyl, TD};        %% 诛妖令任务
                IsFlyTask == true ->      {fly_mount, TD};
                TD#task.kind == 4 ->      {husong, TD};     %% 护送任务
                IsXSHusongTask == true -> {husong, TD};     %% 护送任务
                true -> false
            end
    end.

%% ------------------------------
%% 自动完成任务
%% ------------------------------

%% 完成副本任务
finish_dun_task(TaskId, Rid) ->
    case get_one_trigger(TaskId) of
        false ->
            skip;
        RT ->
            NewMark = auto_finish_mark(RT#role_task.mark, []),
            RT1 = RT#role_task{mark = NewMark, state=RT#role_task.state + 1},
            put_task_bag_list(RT1),
            upd_trigger(Rid, RT1#role_task.task_id, RT1#role_task.state, term_to_binary(RT1#role_task.mark)),
            mod_task:refresh_npc_ico(Rid),
             %% 通知客户端刷新任务栏
            TipList = get_tip(trigger, RT1#role_task.task_id, Rid),
            {ok, BinData} = pt_302:write(30200, [RT1#role_task.task_id, TipList]),
            lib_server_send:send_to_uid(Rid, BinData)
    end.

%% 检测任务是否完成
auto_finish(TaskId, Id) when is_integer(TaskId) ->
    case get_one_trigger(TaskId) of
        false ->
            Msg = data_task_text:get_auto_finish(1),
            {ok, BinData} = pt_300:write(30004, [0, Msg]),
            lib_server_send:send_to_uid(Id, BinData),
            false;
        RT ->
            case RT#role_task.state > 0 of
                true ->
                    Msg = data_task_text:get_auto_finish(2),
                    {ok, BinData} = pt_300:write(30004, [0, Msg]),
                    lib_server_send:send_to_uid(Id, BinData),
                    false;
                false ->
                    auto_finish(RT, Id)
            end
    end;

auto_finish(RT, Id) when is_record(RT, role_task) ->
    NewMark = auto_finish_mark(RT#role_task.mark, []),
    put_task_bag_list(RT#role_task{mark = NewMark, state=RT#role_task.state + 1}),
    %% 通知客户端刷新任务栏
    mod_task:refresh_npc_ico(Id),
    TipList = get_tip(trigger, RT#role_task.task_id, Id),
    {ok, BinData} = pt_302:write(30200, [RT#role_task.task_id, TipList]),
    lib_server_send:send_to_uid(Id, BinData),
    true.

auto_finish_mark([], NewMark) ->
    NewMark;
auto_finish_mark([MarkItem | T], NewMark) ->
    auto_finish_mark(T, NewMark ++ [auto_check_content(MarkItem)]).

%% 检测任务内容是否完成
auto_check_content([D1, _Finish, kill, D2, Num, _NowNum]) ->
    [D1, 1, kill, D2, Num, Num];

auto_check_content([D1, _Finish, item, D2, Num, _NowNum]) ->
    [D1, 1, item, D2, Num, Num];

auto_check_content([D1, _Finish | D2]) ->
    [D1, 1 | D2];

auto_check_content(Other) ->
    Other.

%% ===========进程字段记录===================

%% ---已完成任务---
%get_task_log_id_list() ->
%    Data = get(),
%    [ Value  || {Key, Value} <-Data, is_tuple(Key)].

put_task_log_list(TaskInfo) ->
    case find_task_log_list(TaskInfo#role_task_log.task_id) of
        false ->
            put({log, TaskInfo#role_task_log.task_id}, TaskInfo);
        Data ->
            C = Data#role_task_log.count + 1,
            put({log, TaskInfo#role_task_log.task_id}, TaskInfo#role_task_log{count = C})
    end.

find_task_log_list(TaskId) ->
    case get({log, TaskId}) of
        undefined ->
            false;
        Data ->
            Data
    end.

find_task_log_exits(TaskId) ->
    case find_task_log_list(TaskId) of
        false ->
            false;
        _ ->
            true
    end.

delete_task_log_list(TaskId) ->
    erase({log, TaskId}).


%% ----已接任务----

get_task_bag_id_list() ->
    get("lib_task_task_bag_id_list").

%% 按type类型
get_task_bag_id_list_type(Type)->
    L = get_task_bag_id_list(),
    [ T || T <- L, T#role_task.type =:= Type].


%% 按TaskId类型
get_task_bag_id_list_task_id(TaskId)->
    L = get_task_bag_id_list(),
    [ T || T <- L, T#role_task.task_id =:= TaskId].


%% 按kind类型
get_task_bag_id_list_kind(Kind)->
    L = get_task_bag_id_list(),
    [ T || T <- L, T#role_task.kind =:= Kind].

set_task_bag_list(Data) ->
    put("lib_task_task_bag_id_list", Data).

put_task_bag_list(TaskInfo) ->
    List = lists:keydelete(TaskInfo#role_task.task_id, 4, get_task_bag_id_list()),
    List1 = List ++ [TaskInfo],
    put("lib_task_task_bag_id_list", List1).

find_task_bag_list(TaskId) ->
    lists:keyfind(TaskId, 4, get_task_bag_id_list()).

find_task_bag_exits(TaskId) ->
    case find_task_bag_list(TaskId) of
        false ->
            false;
        _ ->
            true
    end.

%% 获取任务接取时间
get_trigger_time(TaskId) ->
	case find_task_bag_list(TaskId) of
        false ->
            false;
        RT ->
			RT#role_task.trigger_time
    end.

delete_task_bag_list(TaskId) ->
    put("lib_task_task_bag_id_list", lists:keydelete(TaskId, 4, get_task_bag_id_list())).

%% -------可接任务-------

get_query_cache_list() ->
    get("lib_task_query_cache_list").

set_query_cache_list(Data) ->
    put("lib_task_query_cache_list", Data).

%% 按类型
get_query_cache_list_type(Type)->
    [ T || T <- get_query_cache_list(), T#task.type =:= Type].

put_query_cache_list(TaskInfo) ->
    List = lists:keydelete(TaskInfo#task.id, 2, get_query_cache_list()),
    List1 = List ++ [TaskInfo],
    put("lib_task_query_cache_list", List1).

find_query_cache_list(TaskId) ->
    lists:keyfind(TaskId, 2, get_query_cache_list()).

find_query_cache_exits(TaskId) ->
    case find_query_cache_list(TaskId) of
        false ->
            false;
        _ ->
            true
    end.

delete_query_cache_list(TaskId) ->
    put("lib_task_query_cache_list", lists:keydelete(TaskId, 2, get_query_cache_list())).

%%-----------------原来------------

%% 添加完成日志
add_log(Rid, Tid, Type, TriggerTime, FinishTime) when Type > 1 andalso Type =/= 99 andalso Type =/= 16 ->
    del_trigger(Rid, Tid),
    put_task_log_list(#role_task_log{role_id=Rid, task_id=Tid, type = Type, trigger_time = TriggerTime, finish_time = FinishTime}),
    db:execute(lists:concat(["insert into `task_log_clear`(`role_id`, `task_id`, `type`, `trigger_time`, `finish_time`) values(",Rid,",",Tid,",",Type,",",TriggerTime,",",FinishTime,")"]));

add_log(Rid, Tid, Type, TriggerTime, FinishTime) ->
    del_trigger(Rid, Tid),
    put_task_log_list(#role_task_log{role_id=Rid, task_id=Tid, type = Type, trigger_time = TriggerTime, finish_time = FinishTime}),
    db:execute(lists:concat(["insert into `task_log`(`role_id`, `task_id`, `type`, `trigger_time`, `finish_time`) values(",Rid,",",Tid,",",Type,",",TriggerTime,",",FinishTime,")"])).

%% 添加完成日志
del_log(Rid, Tid, Type) when Type > 1->
    delete_task_log_list(Tid),
    db:execute(lists:concat(["delete from `task_log_clear` where role_id=",Rid," and task_id=",Tid]));

del_log(Rid, Tid, _Type) ->
    delete_task_log_list(Tid),
    db:execute(lists:concat(["delete from `task_log` where role_id=",Rid," and task_id=",Tid])).

%% 添加触发
add_trigger(Rid, Tid, TriggerTime, TaskState, TaskEndState, TaskMark, Type, Kind) ->
    put_task_bag_list(#role_task{
            id={Rid, Tid},
            role_id= Rid,
            task_id = Tid,
            trigger_time = TriggerTime,
            state=TaskState,
            type=Type,
            kind=Kind,
            end_state=TaskEndState,
            mark = TaskMark
        }),
    delete_query_cache_list(Tid),
    db:execute(sql_add_trigger, [Rid, Tid, TriggerTime, TaskState, TaskEndState, term_to_binary(TaskMark), Type]).

%% 更新任务记录器
upd_trigger(Rid, Tid, TaskState, TaskMark) ->
    db:execute(sql_upd_trigger, [TaskState, TaskMark, Rid, Tid]).

%% 删除触发的任务
del_trigger(Rid, Tid) ->
    delete_task_bag_list(Tid),
    db:execute(lists:concat(["delete from `task_bag` where role_id=",Rid," and task_id=",Tid])).

update_all_trigger(Rid, PS) ->
    F = fun(RT) ->
			IsFinish = case  RT#role_task.task_id of
			                  %101270 -> true;
							  %101730 -> true;
							  %100441 -> true;
							  %100950 -> true;
							  %102220 -> true;
							  %102330 -> true;
							  %101331 -> true;
							  %101570 -> true;
							  %101820 -> true;
							  %102131 -> true;
							  %101973 -> true;
							  %101683 -> true;
							  %101520 -> true;
							  %101285 -> true;
%%							  200120 -> true; %% 888充值活动任务
%%							  200140 -> true; %% 首充活动任务
							  %200290 -> true; %% 50级充值送水晶任务
							  %200450 -> true; %% 60级充值送水晶任务
							  _ ->false
						end,
			case IsFinish of								
				true -> 
						%% io:format("------RT#role_task.mark------~p~n",[RT#role_task.mark]),				
					    preact_finish(RT#role_task.task_id, PS),
						[RT2] = get_task_bag_id_list_task_id(RT#role_task.task_id),						
						%% 更新任务状态,防止特殊任务下线丢失状态
						upd_trigger(Rid, RT2#role_task.task_id, RT2#role_task.state, term_to_binary(RT2#role_task.mark));
				false -> upd_trigger(Rid, RT#role_task.task_id, RT#role_task.state, term_to_binary(RT#role_task.mark))
			end
    end,
    [ F(RT) || RT<-get_task_bag_id_list()],
    ok.

login_update_all_trigger(Rid, PS) ->
    F = fun(RT) ->
			IsFinish = case  RT#role_task.task_id of
			                  200032 -> true;							  
							  _ ->false
						end,
			case IsFinish of								
				true -> preact_finish(RT#role_task.task_id, PS),
						[RT2] = get_task_bag_id_list_task_id(RT#role_task.task_id),						
						%% 更新任务状态
						upd_trigger(Rid, RT2#role_task.task_id, RT2#role_task.state, term_to_binary(RT2#role_task.mark));
				false -> upd_trigger(Rid, RT#role_task.task_id, RT#role_task.state, term_to_binary(RT#role_task.mark))
			end
    end,
    [ F(RT) || RT<-get_task_bag_id_list()],
    ok.

%% 清除当天的日常任务 - db
daily_clear_db() ->
    db:execute("TRUNCATE TABLE `task_log_clear`"),
    timer:sleep(3000),
    %% 日常
    db:execute("delete from `task_bag` where `type` in(2, 10, 15)"),
    db:execute("delete from task_sr_bag"),
    ok.

%% 清除当天的日常任务进程字典
daily_clear_ref() ->
    Data = ets:tab2list(?ETS_ONLINE),
    [gen_server:cast(D#ets_online.pid, {'refresh_and_clear_task'}) || D <- Data],
    ok.

%% 清楚进程字典数据
daily_clear_dict() ->
    Data = get(),
    [erase(Key)|| {Key, Value} <- Data, is_record(Value, role_task_log), Value#role_task_log.type > 1 andalso Value#role_task_log.type =/=16],
    ok.

%% 刷新npc任务状态
refresh_npc_ico(Rid) when is_integer(Rid)->
    case misc:get_player_process(Rid) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'refresh_npc_ico'});
        _ ->
            skip
    end;
    
refresh_npc_ico(Status) ->
    NpcList = lib_npc:get_scene_npc(Status#player_status.scene),
    F = 
    fun(Npc) ->
            Id = Npc#ets_npc.id,
            S = 
            if
                Id == ?HB_NPC_ID ->
                    TriggerTaskEbNum = lib_task_eb:get_trigger_task_eb_num(),
                    TriggerTaskEbDaily = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000010),
                    MaxinumTriggerDaily = data_task_eb:get_task_config(maxinum_trigger_daily, []),
                    MaxinumTriggerEverytime = data_task_eb:get_task_config(maxinum_trigger_everytime, []),
                    MinTriggerLv = data_task_eb:get_task_config(min_trigger_lv, []),
                    if
                        TriggerTaskEbDaily < MaxinumTriggerDaily andalso TriggerTaskEbNum < MaxinumTriggerEverytime andalso Status#player_status.lv >= MinTriggerLv ->
                            1;
                        true ->
                            0
                    end;
                true ->
                    lib_task:get_npc_state(Id, Status)
            end,
            [Id, S]
    end,
    L = lists:map(F, NpcList),
    {ok, BinData} = pt_120:write(12020, [L]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData).


%% 完成水晶付费任务
private_finish_CrystalpayTask(PS, TaskId) ->
	NowTime = util:unixtime(),
	TriggerTime = get_trigger_time(TaskId),
	case TriggerTime =/= false andalso TriggerTime =/=0 of
		true ->
			PayTaskTotal1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, TriggerTime, NowTime),
			PayTaskTotal2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, TriggerTime, NowTime),
			PayTaskTotal = PayTaskTotal1 + PayTaskTotal2,
			event(pay_task_2, {PayTaskTotal}, PS#player_status.id);
		false ->
			skip
	end.

finish_pay_task_forhoutai(PS, 200120) ->
	finish_pay_task_200120(PS);
finish_pay_task_forhoutai(_PS, _OtherTaskId) ->
	skip.

%% [后台]激活完成充值任务
finish_pay_task_200120(PS) ->
	NowTime = util:unixtime(),
	TimeConfig = data_activity_time:get_time_by_type(10),	
	case TimeConfig of
		[PayTaskStart, PayTaskEnd] -> skip;
		[] -> 
			PayTaskStart= util:unixtime({{2015, 10, 30}, {6, 0, 0}}),
			PayTaskEnd = util:unixtime({{2016, 10, 30}, {6, 0, 0}})
	end,
	Pay_task_id = 200120,
	OpenDay = util:get_open_day(),
	case NowTime >= PayTaskStart andalso NowTime =< PayTaskEnd andalso util:get_open_day() > 5 of
		true ->
			TriggerTime = lib_task:get_trigger_time(PS#player_status.tid, Pay_task_id),
			case TriggerTime =/= false andalso TriggerTime =/=0 of
				true ->
					case OpenDay>=10 of
						true ->
							PayTaskTotal1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, PayTaskStart, PayTaskEnd),
							PayTaskTotal2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, PayTaskStart, PayTaskEnd);
						false ->
							PayTaskTotal1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, TriggerTime, NowTime),
							PayTaskTotal2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, TriggerTime, NowTime)
					end,
					PayTaskTotal = PayTaskTotal1 + PayTaskTotal2,
					lib_task:event(PS#player_status.tid, pay_task, {PayTaskTotal}, PS#player_status.id);
				false -> skip
			end;
		_ ->
			skip
	end.
