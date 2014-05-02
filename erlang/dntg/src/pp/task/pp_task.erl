%%%--------------------------------------
%%% @Module  : pp_scene
%%% @Author  : zhenghehe
%%% @Created : 2010.09.24
%%% @Description:  任务模块
%%%--------------------------------------
-module(pp_task).
-export([handle/3]).
-include("server.hrl").
-include("scene.hrl").
-include("daily.hrl").
-include("task.hrl").

%% 获取任务列表
handle(30000, PlayerStatus, _) ->
    %% 可接任务
    ActiveIds = lib_task:get_active(PlayerStatus#player_status.tid),
    ActiveList = lists:map(
        fun(TD) ->    
	    %% 获取提示信息
            TipList = lib_task:get_tip(active, TD#task.id, PlayerStatus),
            {TD#task.id, TD#task.level, TD#task.type, TD#task.name, TD#task.desc, TD#task.transfer, TipList, TD#task.coin, TD#task.exp, TD#task.spt, TD#task.llpt, TD#task.xwpt, TD#task.fbpt, TD#task.bppt, TD#task.gjpt, TD#task.binding_coin, TD#task.attainment, TD#task.guild_exp, TD#task.contrib, TD#task.award_select_item_num, lib_task:get_award_item(TD, PlayerStatus), TD#task.award_select_item, TD#task.kind}
        end,
        ActiveIds
    ),
    %% 已接任务
    TriggerBag = lib_task:get_trigger(PlayerStatus#player_status.tid),
    TriggerList = lists:map(
        fun(RT) ->
            TD = lib_task:get_data(RT#role_task.task_id, PlayerStatus),
            TipList = lib_task:get_tip(trigger, RT#role_task.task_id, PlayerStatus),
            {TD#task.id, TD#task.level, TD#task.type, TD#task.name, TD#task.desc, TD#task.transfer, TipList, TD#task.coin, TD#task.exp, TD#task.spt, TD#task.llpt, TD#task.xwpt, TD#task.fbpt, TD#task.bppt, TD#task.gjpt, TD#task.binding_coin, TD#task.attainment, TD#task.guild_exp, TD#task.contrib, TD#task.award_select_item_num, lib_task:get_award_item(TD, PlayerStatus), TD#task.award_select_item, TD#task.kind}
        end,
        TriggerBag
    ),
    %% 获取皇榜任务和平乱任务次数
    {TriggerTaskEbDaily, SrTaskTriggerDaily} = mod_daily:get_task_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id),
    {ok, BinData} = pt_300:write(30000, [ActiveList, TriggerList,
            SrTaskTriggerDaily, TriggerTaskEbDaily]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);

%% 触发任务
%% 触发任务
handle(30003, PlayerStatus, [TaskId]) ->
	Task_type = lib_task:get_task_type(TaskId, PlayerStatus), 
	Special_type = [9, 14, 15],
	Special_Task_id = [200120, 200140, 200290, 200450],
	case lists:member(Task_type, Special_type) orelse lists:member(TaskId, Special_Task_id) of
		true -> skip;
		false ->
		    case lib_task:trigger(PlayerStatus#player_status.tid, TaskId, PlayerStatus) of
				{true, NewRS} ->
					lib_task:preact_finish(NewRS#player_status.tid, TaskId, NewRS),
					lib_scene:refresh_npc_ico(NewRS),
					%{ok, BinData} = pt_30:write(30006, []),
					%lib_send:send_one(NewRS#player_status.socket, BinData),
					{ok, BinData1} = pt_300:write(30003, [TaskId, <<>>]),
					lib_server_send:send_to_sid(NewRS#player_status.sid, BinData1),
					handle(30000, NewRS, ok),
					%% 护送任务判断与处理(含有返回值处理)
					lib_husong:is_husonging(NewRS, TaskId);
				{false, Reason} ->
					{ok, BinData} = pt_300:write(30003, [0, Reason]),
					lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
            end
    end;

%% 阵营任务特殊处理 
%handle(30004, PlayerStatus, [10012, _])->
%    ?DEBUG("这里要弹出大地图窗口", []),
%    lib_conn:pack_send(PlayerStatus#player_status.socket, 30011, []),
%    {ok, PlayerStatus};

%% 完成任务
handle(30004, PlayerStatus, [TaskId, SelectItemList])->
    case TaskId =:= 100480 andalso PlayerStatus#player_status.realm =:= 0 of
        true ->
            Msg = data_task_text:get_choose_country(),
            {ok, BinData} = pt_300:write(30004, [0, Msg]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
        false ->
            case lib_task:finish(TaskId, SelectItemList, PlayerStatus) of
                {true, NewRS} ->
                    {ok, BinData} = pt_300:write(30004, [TaskId, <<>>]),
                    lib_server_send:send_to_sid(NewRS#player_status.sid, BinData),
                    lib_scene:refresh_npc_ico(NewRS),           %% 刷新npc图标
                    case NewRS#player_status.lv > PlayerStatus#player_status.lv of
                        true -> ok;
                        false ->
                            handle(30000, NewRS, ok)
                            %{ok, BinData1} = pt_30:write(30006, []),
                            %lib_send:send_one(NewRS#player_status.socket, BinData1)
                    end,
                    next_task_cue(TaskId, NewRS),       %% 显示npc的默认对话
                    %lib_task:after_finish(TaskId, NewRS),  %% 完成后的特殊操作
                    {ok, NewRS};
                {false, Reason} ->
                    {ok, BinData} = pt_300:write(30004, [0, Reason]),
                    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
            end
    end;

%% 放弃任务
handle(30005, PlayerStatus, [TaskId])->
    case lib_task:abnegate(TaskId, PlayerStatus) of
        {true, PS} -> %% 放弃运镖任务
            lib_scene:refresh_npc_ico(PlayerStatus),
            {ok, BinData} = pt_300:write(30006, []),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
            {ok, PS};
        true ->
            lib_scene:refresh_npc_ico(PlayerStatus),
            {ok, BinData} = pt_300:write(30006, []),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
        false -> 
            {ok, BinData} = pt_300:write(30005, [0]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
    end;

%% 任务对话事件
handle(30007, PlayerStatus, [TaskId, NpcId])->
    lib_task:event(PlayerStatus#player_status.tid, talk, {TaskId, NpcId}, PlayerStatus#player_status.id);


%% 触发并完成任务
%handle(30008, PlayerStatus, [TaskId, SelectItemList])->
%    case lib_task:trigger_and_finish(TaskId, SelectItemList, PlayerStatus) of
%        {true, NewRS} ->    
%            lib_conn:pack_send(NewRS#player_status.socket, 30004, [TaskId, <<>>]), %% 完成任务
%            lib_scene:refresh_npc_ico(NewRS),           %% 刷新npc图标
%            lib_conn:pack_send(NewRS#player_status.socket, 30006, []), %% 发送更新命令
%            next_task_cue(TaskId, NewRS),       %% 显示npc的默认对话
%            lib_task:after_finish(TaskId, NewRS),  %% 完成后的特殊操作
%            {ok, NewRS};
%        {false, Reason} -> 
%            lib_task:abnegate(TaskId, PlayerStatus),
%            {ok, [0, Reason], PlayerStatus}
%    end;

%% 获取任务奖励信息
handle(30009, PlayerStatus, [TaskId]) ->
    case lib_task:get_data(TaskId, PlayerStatus) of
        null -> {ok, PlayerStatus};
        TD ->
%%             {ok, [TD#task.id, TD#task.coin, TD#task.exp, TD#task.spt, TD#task.llpt, TD#task.xwpt, TD#task.fbpt, TD#task.bppt, TD#task.gjpt, TD#task.binding_coin, TD#task.attainment, TD#task.guild_exp, TD#task.contrib, TD#task.award_select_item_num, lib_task:get_award_item(TD, PlayerStatus), TD#task.award_select_item], PlayerStatus}
            {ok, BinData} = pt_300:write(30009, [TD#task.id, TD#task.coin, TD#task.exp, TD#task.spt, TD#task.llpt, TD#task.xwpt, TD#task.fbpt, TD#task.bppt, TD#task.gjpt, TD#task.binding_coin, TD#task.attainment, TD#task.guild_exp, TD#task.contrib, TD#task.award_select_item_num, lib_task:get_award_item(TD, PlayerStatus), TD#task.award_select_item]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
    end;


%% 日常标签页--日常任务
handle(30010, PlayerStatus, _) ->    
	Data = lib_task:get_tab_daily_task(PlayerStatus),
	{ok, BinData} = pt_300:write(30010, [Data]),
	lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);	

%% 阵营选择
handle(30012, PlayerStatus, [Realm]) ->
    Go = PlayerStatus#player_status.goods,
    case PlayerStatus#player_status.realm > 0 of    %% 阵营选择任务是否完成
        true ->
            {ok, BinData} = pt_300:write(30012, [1, <<>>]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
        false ->
            case lib_task:in_trigger(PlayerStatus#player_status.tid, 100480) of
                true ->
                    Realm1 = case Realm of
                        1 -> % 秦
                            1;
                        2 -> % 楚
                            2;
                        3 -> % 汉
                            3;
                        _ -> % 随机
                            gen_server:call(Go#status_goods.goods_pid, {'give_more', PlayerStatus, [{531801, 1}]}),
                            get_rand_realm()
                    end,
                    PlayerStatus1 = PlayerStatus#player_status{realm = Realm1},
                    F1 = fun() ->
                        put_rand_realm(Realm1),
                        db:execute(io_lib:format(<<"update `player_low` set realm = ~p where id = ~p">>, [Realm1, PlayerStatus1#player_status.id]))
                    end,
                    case
                        db:transaction(F1) =:= 1
                    of
                        true ->
                            %% 更新公共线的阵营
                            lib_player:update_unite_info(PlayerStatus1#player_status.unite_pid, [{realm, Realm1}]),

                            {ok, BinData} = pt_300:write(30012, [1, <<>>]),
                            lib_server_send:send_to_sid(PlayerStatus1#player_status.sid, BinData),
                            {ok, BinData1} = pt_120:write(12090, [PlayerStatus1#player_status.id, PlayerStatus1#player_status.platform, PlayerStatus1#player_status.server_num, Realm1]),
                            lib_server_send:send_to_area_scene(PlayerStatus1#player_status.scene, PlayerStatus1#player_status.copy_id, PlayerStatus1#player_status.x, PlayerStatus1#player_status.y, BinData1),
							{ok, PlayerStatus1};
                        false ->
                            {ok, BinData2} = pt_300:write(30012, [0, <<>>]),
                            lib_server_send:send_to_sid(PlayerStatus1#player_status.sid, BinData2)
                    end;
                false ->
                    {ok, BinData} = pt_300:write(30012, [0, <<>>]),
                    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
            end
    end;

%% 刷新任务
handle(30013, PS, _) ->
    lib_task:refresh_active(PS),
    {ok, BinData} = pt_300:write(30006, []),
    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
    lib_scene:refresh_npc_ico(PS);

%% 查询人数最少的国家
handle(30016, PS, _) ->
    Realm = get_rand_realm(),
    {ok, BinData} = pt_300:write(30016, [Realm]),
    lib_server_send:send_to_sid(PS#player_status.sid, BinData);

%% 查询888充值活动任务结束时间
handle(30017, PS, _) ->
	TimeConfig = data_activity_time:get_time_by_type(10),
	case TimeConfig of
		[_PayTaskStart, PayTaskEnd] -> skip;
		[] -> 
			PayTaskEnd = util:unixtime({{2012, 10, 30}, {6, 0, 0}})
	end,
	{ok, BinData} = pt_300:write(30017, [PayTaskEnd]),
    lib_server_send:send_to_sid(PS#player_status.sid, BinData);

%% 任务失败
handle(30040, PS, [TaskId]) ->
    TaskList = lib_task:get_trigger(PS#player_status.tid),
    case lists:keysearch(TaskId, 4, TaskList) of
        {value, RT} ->
            lib_task:task_fail(PS, RT),
            lib_scene:refresh_npc_ico(PS),
            {ok, BinData} = pt_300:write(30006, []),
            lib_server_send:send_to_sid(PS#player_status.sid, BinData);
        false ->
            skip
    end;
    
%% 获取委托列表
handle(30100, PS, []) ->
    mod_task_proxy:refresh_list(PS);

%% 开始委托任务
handle(30105, RS, [List]) ->
    case mod_task_proxy:action(RS, List) of
        {false, Msg} ->
            {ok, BinData} = pt_301:write(30105, [0, Msg]),
            lib_server_send:send_to_sid(RS#player_status.sid, BinData);
        {true, NewRS} ->
            {ok, BinData} = pt_301:write(30105, [1, <<>>]),
            lib_server_send:send_to_sid(NewRS#player_status.sid, BinData),
            {ok, NewRS}
    end;

%% 获取委托任务的奖励列表
handle(30110, RS, [TaskId]) ->
    mod_task_proxy:award(RS, TaskId);

%% 立即完成委托任务
handle(30115, RS, [List]) ->
    case mod_task_proxy:once_finish(RS, List) of
        {false, Msg} ->
            {ok, BinData} = pt_301:write(30115, [0, Msg]),
            lib_server_send:send_to_sid(RS#player_status.sid, BinData);
        {true, NewRS} ->
            {ok, BinData} = pt_301:write(30115, [1, <<>>]),
            lib_server_send:send_to_sid(NewRS#player_status.sid, BinData),
            {ok, NewRS}
    end;

%% 取每天任务完成数
handle(30201, RS, task_num) ->
    TaskList = case mod_daily:get_all(RS#player_status.dailypid, RS#player_status.id) of
                    [] -> [];
                    L ->
                        F = fun(T) ->
                                {_,Type} = T#ets_daily.id,
                                case Type < 1000 of
                                    true -> [{Type, T#ets_daily.count}];
                                    false -> []
                                end
                            end,
                        lists:merge([F(X) || X <- L])
                end,
    {ok, BinData} = pt_302:write(30201, TaskList),
    lib_server_send:send_to_sid(RS#player_status.sid, BinData);




%% 获取任务累积列表
handle(30202, RS, task_cumulate) ->
    %io:format("Recv 30202~n"),
    TaskList = mod_task_cumulate:lookup_all_task(RS#player_status.id),
    F = fun(T1, T2) -> T1#task_cumulate.task_id < T2#task_cumulate.task_id end,
    TaskList2 = lists:sort(F, TaskList),
    %io:format("TaskList2:~p~n", [TaskList2]),
    {ok, BinData} = pt_302:write(30202, [TaskList2, RS#player_status.lv]),
    %io:format("send 30202~n"),
    lib_server_send:send_to_sid(RS#player_status.sid, BinData);

%% 领取任务累积经验
handle(30203, RS, [Task_id, Type]) ->
    MaxId = length(data_task_cumulate:get_task_cumulate_data(task_id_list)),
    case Task_id >= 0 andalso Task_id =< MaxId andalso Type >= 0 andalso Type =< 1 of
        true ->
            %io:format("Recv 30203~n"),
            [Exp, Count] = lib_task_cumulate:cumulate_exp(RS#player_status.id, Task_id),
            case Exp =< 0 of
                true ->
                    {ok, BinData} = pt_302:write(30203, [2, Task_id]),
                    %io:format("send 30203 0~n"),
                    lib_server_send:send_to_sid(RS#player_status.sid, BinData),
                    NewRS2 = RS;
                false ->
                    %% 0免费领取，1元宝领取
                    case Type of
                        0 -> 
                            lib_task_cumulate:award_cumulate_exp(RS#player_status.id, Task_id),
                            {ok, BinData} = pt_302:write(30203, [1, Task_id]),
                            %io:format("send 30203 1~n"),
                            lib_server_send:send_to_sid(RS#player_status.sid, BinData),
                            NewExp = round(Exp * 0.6),
                            %% 日志
                            spawn(fun() ->
                                        lib_task_cumulate:exp_log(RS#player_status.id, 1000 + Task_id, util:unixtime(), RS#player_status.lv, Count, NewExp, no)
                                end),
                            NewRS2 = lib_player:add_exp(RS, NewExp);
                        1 -> 
                            NeedGold = Exp div 2000 div RS#player_status.lv,
                            case RS#player_status.gold < NeedGold of
                                true -> 
                                    {ok, BinData} = pt_302:write(30203, [3, Task_id]),
                                    %io:format("send 30203 2~n"),
                                    lib_server_send:send_to_sid(RS#player_status.sid, BinData),
                                    NewRS2 = RS;
                                false -> 
                                    lib_task_cumulate:award_cumulate_exp(RS#player_status.id, Task_id),
                                    {ok, BinData} = pt_302:write(30203, [1, Task_id]),
                                    %io:format("send 30203 3~n"),
                                    lib_server_send:send_to_sid(RS#player_status.sid, BinData),
                                    NewRS1 = lib_goods_util:cost_money(RS, NeedGold, gold),
                                    lib_player:refresh_client(RS),
                                    %% 日志
                                    spawn(fun() ->
                                                lib_task_cumulate:exp_log(RS#player_status.id, 1000 + Task_id, util:unixtime(), RS#player_status.lv, Count, Exp, gold)
                                        end),
                                    NewRS2 = lib_player:add_exp(NewRS1, Exp)
                            end;
                        _ -> NewRS2 = RS
                    end
            end,
            {ok, NewRS2};
        false -> skip
    end;

%% 显示景阳经验累积值
handle(30301, RS, _) ->
    %景阳部分
    Exp = trunc(lib_jy:cale_con_exp(RS#player_status.id, RS#player_status.lv) / 0.6),
    GoldNum = trunc(Exp/ 50000),
    Goodsid = case RS#player_status.lv >= 50 of true -> 672002; _ -> 672001 end,
    GoodsNum = util:ceil(GoldNum/10),
    %篝火部分
    Days = lib_wine_outline:get_outline_days(RS#player_status.id),
    ExpFire  = lib_wine_outline:countexp(RS, Days, 2),
    [GoodsidFire, GoodsNumFire, GoldNumFire] = lib_wine_outline:get_cost(RS, ExpFire),

    {ok, BinData} = pt_303:write(30301, [[Exp, GoldNum, Goodsid, GoodsNum], [Days, ExpFire, GoldNumFire, GoodsidFire, GoodsNumFire]]),
    lib_server_send:send_to_sid(RS#player_status.sid, BinData);

%% 获取景阳经验累积值
handle(30302, RS, [Ftype, Type]) ->
    case Ftype of
        %景阳找回
        1 ->
            case Type of
                %免费找回
                0 ->
                    Count = mod_daily:get_count(RS#player_status.dailypid, RS#player_status.id, 630),
                    case Count > 0 of
                        true ->
                            RS1 = lib_jy:get_con_exp(RS),
                            {ok, BinData} = pt_303:write(30302, [Ftype, 1]),
                            lib_server_send:send_to_sid(RS1#player_status.sid, BinData),
%%                             lib_practice:replace_money(RS1),
                            {ok, RS1};
                        _ ->
                            {ok, BinData} = pt_303:write(30302, [Ftype, 2]),
                            lib_server_send:send_to_sid(RS#player_status.sid, BinData)
                    end;
                %元宝找回
                1 ->
                    {Err, RS1} = lib_jy:get_con_exp_gold(RS),
                    {ok, BinData} = pt_303:write(30302, [Ftype, Err]),
                    lib_server_send:send_to_sid(RS1#player_status.sid, BinData),
%%                     lib_practice:replace_money(RS1),
                    {ok, RS1};
                 2 ->
                    {Err, RS1} = lib_jy:get_con_exp_goods(RS),
                    {ok, BinData} = pt_303:write(30302, [Ftype, Err]),
                    lib_server_send:send_to_sid(RS1#player_status.sid, BinData),
%%                     lib_practice:replace_money(RS1),
                    {ok, RS1};
                _ ->
                    ok
            end;
        %篝火找回
        2 ->
            [Err, RS1] = lib_wine_outline:fetch_exp(RS, Type),
            {ok, BinData} = pt_303:write(30302, [Ftype, Err]),
            lib_server_send:send_to_sid(RS1#player_status.sid, BinData),
            {ok, RS1};
        _ ->
            ok
    end;

%% 跟NPC打招呼，发大表情 
handle(30303, PlayerStatus, [FaceId]) ->
    case lib_task:in_trigger(PlayerStatus#player_status.tid, 100640) orelse lib_task:in_trigger(PlayerStatus#player_status.tid, 100720) orelse lib_task:in_trigger(PlayerStatus#player_status.tid, 100800) of
        true ->
            lib_task:event(PlayerStatus#player_status.tid, big_face, {FaceId}, PlayerStatus#player_status.id);
        false ->
            skip
    end;

%% 完成击败NPC分身任务
handle(30304 , PlayerStatus, [NpcId]) ->
    case lists:any(fun(X) -> lib_task:in_trigger(PlayerStatus#player_status.tid, X) end, ?KILL_AVATAR_TASK) of
        true ->
            lib_task:event(PlayerStatus#player_status.tid, kill_avatar, {NpcId}, PlayerStatus#player_status.id);
        false ->
            skip
    end;

%% 指定场景使用物品
handle(30305 , PlayerStatus, [GoodsId, Num]) ->
    pp_goods:handle(15050, PlayerStatus, [GoodsId, Num]);   

%% 使用元宝快速完成任务
handle(30600, PlayerStatus, [TaskId]) ->
	Type = lib_task:get_task_type(TaskId, PlayerStatus),	
	if 
		PlayerStatus#player_status.lv>=55 andalso Type=:=15 -> %% -> 平乱任务55级后可以使用铜钱快速完成
			[ResultCode, PlayerStatus2] =finish_task_quick(PlayerStatus, TaskId, 6000, coin);
        PlayerStatus#player_status.lv>=60 andalso Type=:=14 -> %% -> 皇榜任务60级后可以使用铜钱快速完成
			[ResultCode, PlayerStatus2] =finish_task_quick(PlayerStatus, TaskId, 8000, coin);
		PlayerStatus#player_status.lv>=65 andalso Type=:=9 ->  %% -> 诛妖任务65级后可以使用铜钱快速完成
			[ResultCode, PlayerStatus2] =finish_task_quick(PlayerStatus, TaskId, 10000, coin);
        true ->											   %% ->  其它情况使用3元宝快速完成
			[ResultCode, PlayerStatus2] =finish_task_quick(PlayerStatus, TaskId, 3, gold)
	end,
	case ResultCode of
		1 ->
			lib_player:refresh_client(PlayerStatus2#player_status.id, 2),
			Result = handle(30004, PlayerStatus2, [TaskId, []]),
			case Result of
				 {ok, PlayerStatus3} when is_record(PlayerStatus3, player_status) ->
					NewPS = PlayerStatus3; 
				 _ ->
					NewPS = PlayerStatus2
			end;
		_ ->
			NewPS = PlayerStatus2
	end,
	{ok, BinData} = pt_306:write(30600, [ResultCode]),
	lib_server_send:send_to_sid(NewPS#player_status.sid, BinData),
	{ok, NewPS};
	
handle(_Cmd, _PlayerStatus, _Data) ->
    {error, bad_request}.

%% 快速完成任务
finish_task_quick(PlayerStatus, TaskId, Cost, CostType) -> 
	case lib_goods_util:is_enough_money(PlayerStatus, Cost, CostType) of
		true ->
			case lib_task:auto_finish(PlayerStatus#player_status.tid, TaskId, PlayerStatus#player_status.id) of
				true -> 
					CostPS = lib_goods_util:cost_money(PlayerStatus, Cost, CostType),
					log:log_consume(task_proxy_finish, CostType, PlayerStatus, CostPS, "finish task quickly"),
					[1, CostPS];							
				false -> 
					[0, PlayerStatus]
			end;
		false ->
			case CostType of
				gold -> ResultCode =2;
				coin -> ResultCode =3
			end,
			[ResultCode, PlayerStatus]
	end.

%% 完成任务后是否弹结束npc的默认对话
next_task_cue(TaskId, PlayerStatus) ->
    case lib_task:get_data(TaskId, PlayerStatus) of
        null -> false;
        TD ->
            case TD#task.next_cue of
                0 -> false;
                _ -> 
                   Id = TD#task.end_npc,
                   Npc = lib_npc:get_data(TD#task.end_npc),
                   %TalkList = data_talk:get(Npc#ets_npc.talk),
                   TalkList = Npc#ets_npc.talk,
                   TaskList = lib_task:get_npc_task_list(PlayerStatus#player_status.tid, TD#task.end_npc, PlayerStatus),
                   {ok, BinData} = pt_320:write(32000, [Id, TaskList, TalkList]),
                   lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
                   true
            end
    end.

%% 随机选择阵营，默认最少人数的
get_rand_realm() ->
	ZeroTime = util:unixdate(),
	NowTime = util:unixtime(),	
	%% 每天凌晨12:00 -12:10 不读取排行榜数据
    case NowTime >=ZeroTime andalso NowTime =< ZeroTime + 10*60 of
		true ->
			get_minimnum_realm();
		false ->		    
			Top_player_20 = mod_disperse:call_to_unite(lib_rank,get_power_rank_data,[20]),
			QinNum = statist_player_realm(Top_player_20, 1),
			ChuNum = statist_player_realm(Top_player_20, 2),
			HanNum = statist_player_realm(Top_player_20, 3),
			[Min2, _, _Max2] = lists:sort([QinNum, ChuNum, HanNum]),
			case judge_factor() of
				true -> get_minimnum_realm();
				false -> statist_minimnum_realm(Min2, [QinNum, ChuNum, HanNum])
			end			
	end.

%% 全服国家1.15因子,最多比最少是否大于1.15
judge_factor() ->
	case db:get_row("SELECT `qin`, `chu`, `han` FROM `log_realm` WHERE 1 LIMIT 1") of
		[] ->
			true;
		[Qin, Chu, Han] ->
			[Min, _, Max] = lists:sort([Qin, Chu, Han]),
			Min =/=0 andalso Max/Min >1.15   
	end.

%% 读取数据库，返回人数最少的国家
get_minimnum_realm() ->
	case db:get_row("SELECT `qin`, `chu`, `han` FROM `log_realm` WHERE 1 LIMIT 1") of
		[] ->
			db:execute("insert into `log_realm`(qin, chu, han) values (0,0,0)"),
			util:rand(1,3);
		[Qin, Chu, Han] ->
			[Min, _, _] = lists:sort([Qin, Chu, Han]),
			statist_minimnum_realm(Min, [Qin, Chu, Han])      
	end.

%% 返回国家
statist_minimnum_realm(Minimnum, [Qin, Chu, _Han]) ->
	if
		Minimnum =:=  Qin -> %% 秦
			1;
		Minimnum =:=  Chu -> %% 楚
			2;
		true -> %% 汉
			3
	end.

%% 统计战力榜玩家国家分布情况
statist_player_realm(Player, TargetRealm) ->
	F = fun([_, _, _, _, Realm, _, _, _], Count) ->
			if 
				Realm =:= TargetRealm ->
					Count + 1;
				true ->
					Count
			end
		end,
	lists:foldl(F, 0, Player).
    
%% 统计国家人数
put_rand_realm(Realm) ->
    case Realm of
        1 ->
            db:execute("update `log_realm` set qin = qin + 1 where 1");
        2 ->
            db:execute("update `log_realm` set chu = chu + 1 where 1");
        _ ->
            db:execute("update `log_realm` set han = han + 1 where 1")
    end.


