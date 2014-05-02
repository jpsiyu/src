%%%------------------------------------
%%% @Module  : lib_husong
%%% @Author  : zhenghehe
%%% @Created : 2010.12.07
%%% @Description: 护送模块公共函数
%%%------------------------------------
-module(lib_husong).
-export([
		 trigger_task/2, 
         is_protect_time/1, 
         clear_protect_time/1, 
         count_player_speed/1,
         skill_timeout_process/1,
         cancel_task/2,
         finish_task/3,
         online/1,
         husong_terminate/2,										%% 被劫镖
         transport/2,
         send_help/1,
         send_help_to_guild/3,
         count_player_attribute/1,
         trigger_reward/1,
%%          rand_reward/0,
         offline/1,
         set_husong_npc/2,
         get_husong_npc/1,
         set_husong_ref/2,
         get_husong_ref/1,
         guoyun_notify/0,
         guoyun_left_time/0,
         guoyun_left_time/1,
         is_double/1,
         cant_intercept/2,
		 husong_pk_check/1,  										%% 护送切换PK状态检查
		 save_husong_score/2,										%% 保存护送积分记录
		 is_husonging/2,												%% 判断现在是否在护送任务状态
		 csjl/0
		]).

-include("common.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("task.hrl").
-include("sql_player.hrl").

-define(TRIGGER_SCENE, 102).
%%NPC X Y 坐标
-define(TRIGGER_X, 59).
-define(TRIGGER_Y, 35).

%% 触发护送任务
trigger_task(TD,PS) ->
    HS = PS#player_status.husong, 
 	MountS = PS#player_status.mount,
	%% 是否护送任务
    case TD#task.kind =:= 4 orelse lists:member(TD#task.id, ?XS_HUSONG_TASK) of 
        true ->
            %% 临时去掉（有bug）
			case MountS#status_mount.mount_figure =:= 0 of
				false ->
					%% 坐骑上不允许
					{false, is_husonging};
				true -> 
                    %% 运镖任务必须要102长安城
					case TD#task.type =:= 7 andalso PS#player_status.scene =/= ?TRIGGER_SCENE of
						true ->
							{false, is_changing_scene};
						false ->
							case TD#task.type =:= 7 andalso (abs(PS#player_status.x - ?TRIGGER_X) > 10 orelse abs(PS#player_status.y - ?TRIGGER_Y) > 10 ) of
								true ->
									{false, is_husonging};
								false ->
		                            case PS#player_status.change_scene_sign =:= 0 of
										false -> %% 在场景切换中
											{false, is_changing_scene};
										true ->
								            %% 是否在护送
								            case HS#status_husong.husong =:= 0 of
								                true ->
								                    Level = TD#task.level,
								                    Pk = PS#player_status.pk,
								                    CanChangePK = 
								                    case Pk#status_pk.pk_status =:= 2 of
								                        true ->
								                            {true, PS};
								                        false ->
															case lists:member(TD#task.id, ?XS_HUSONG_TASK) of
																true ->
																	{true, PS};
																false ->
																	case is_double(online) of
																		false ->
																			{true, PS};
																		true ->
																			case data_yunbiao:is_unchange_pk_day() of
																				true ->
																					{true, PS};
																				false ->
																					case lib_player:change_pkstatus(PS, 2) of
																						{ok, _ErrCode, _Type, _LeftTime, PSPK} -> 
																							{true, PSPK};
																						{error, _ErrCode, _Type, _LeftTime, _} -> 
																							{false, PS}
																					end
																			end												                            
																	end
															end
								                    end,
								                    case CanChangePK of
								                        {true, PS0} ->
															%%change by xieyunfei
								                            case lib_physical:is_enough_physical(PS0, 0) of
								                                true ->
								                                    [HuSongColor, PS1] = 
								                                    case lists:member(TD#task.id, ?XS_HUSONG_TASK) of
								                                        true ->
								                                            [?XS_HUSONG_NPC, PS0];
								                                        false ->
								                                            BuffAddition = data_yunbiao:get_husong_phase_buff(PS0#player_status.lv),
								                                            Buff = {BuffAddition, 0.55},
								                                            _PS = add_buff(PS0, Buff),
																			case TD#task.type =:= 0 of
																				true -> %% 是新手主线
																					[5, _PS];
																				false->
																					[HS#status_husong.husong_npc, _PS]
																			end
								                                    end,
								                                    %% 广播护送Npc形象和人物属性
								                                    send_figure_change_notify(PS1#player_status.scene, PS1#player_status.copy_id, PS1#player_status.x, PS1#player_status.y, PS1#player_status.id, PS1#player_status.platform, PS1#player_status.server_num, Level, PS1#player_status.hp, PS1#player_status.hp_lim, PS1#player_status.speed, HuSongColor),
								                                    %% 保存护送Npc颜色
								                                    set_husong_npc(PS1#player_status.id, HuSongColor),
								                                    %% 更新人物属性
								                                    send_husong_attribute_notify(PS1),

												    HS2 = PS1#player_status.husong, 
								                                    PS2 = PS1#player_status{husong=HS2#status_husong{husong = 1, husong_lv = TD#task.level, husong_npc = HuSongColor, husong_start_at = util:unixtime(), husong_pt = util:unixtime()}},
								                                    mod_scene_agent:update(husong, PS2),

								                                    {true, PS2};
								                                false ->
								                                    {false, not_enough_physical}
								                            end;
								                        {false, _} ->
								                            {false, change_pk_fail}
								                    end;
								                false ->
								                    {false, is_husonging}
								            end
									end
							end
					end
			end;
        false ->
            {true, PS}
    end.

%% 取消护送
cancel_task(PS, TaskId) ->
    Hs = PS#player_status.husong,
    case lists:member(TaskId, ?XS_HUSONG_TASK) of
        true ->
            skip;
        false ->
            send_husong_result_notify(PS, 0)
    end,
    Hs1 = Hs#status_husong{husong=0,husong_start_at=0, husong_lv = 0, husong_pt=0,hs_buff=[],hs_skill_trigger=[0,0,0],husong_npc=1},
    PS1 = PS#player_status{ husong=Hs1 },
    mod_scene_agent:update(husong, PS1),
    PS2 = 
    case lists:member(TaskId, ?XS_HUSONG_TASK) of
        false ->
            clean_buff(PS1);
        true ->
            PS1
    end,
    %% 广播护送NPC消失和人物属性
    send_figure_change_notify(PS2#player_status.scene, PS2#player_status.copy_id, PS2#player_status.x,PS2#player_status.y, PS2#player_status.id, PS2#player_status.platform, PS2#player_status.server_num, 0, PS2#player_status.hp, PS2#player_status.hp_lim, PS2#player_status.speed, 0),
    %% 更新人物属性
    send_husong_attribute_notify(PS2),
    set_husong_npc(PS2#player_status.id, 1),
    set_husong_ref(PS2#player_status.id, 0),
    PS2.

%% 完成护送任务
finish_task(TaskId, ParamList, PS) ->
    Hs = PS#player_status.husong,
    Hs1 = case ParamList of
			  4 ->
				  Hs#status_husong{husong=0, husong_lv = 0, husong_pt=0,hs_buff=[],hs_skill_trigger=[0,0,0],husong_npc=1};
			  [4] ->
				  Hs#status_husong{husong=0, husong_lv = 0, husong_pt=0,hs_buff=[],hs_skill_trigger=[0,0,0],husong_npc=1};
			  _ ->
				  Hs#status_husong{husong=0, husong_lv = 0, husong_pt=0,hs_buff=[],hs_skill_trigger=[0,0,0]}
	end,
    PS1 = PS#player_status{husong = Hs1},
    mod_scene_agent:update(husong, PS1),
    PS2 = 
    case lists:member(TaskId, ?XS_HUSONG_TASK) of
        false ->
            clean_buff(PS1);
        true ->
            PS1
    end,
    send_figure_change_notify(PS2#player_status.scene, PS2#player_status.copy_id, PS2#player_status.x,PS2#player_status.y, PS2#player_status.id, PS2#player_status.platform, PS2#player_status.server_num, 0, PS2#player_status.hp, PS2#player_status.hp_lim, PS2#player_status.speed, 0),
    set_husong_npc(PS2#player_status.id, 1), 
    send_husong_attribute_notify(PS2),
    case lists:member(TaskId, ?XS_HUSONG_TASK) of
        true ->
            skip;
        false ->
            send_husong_result_notify(PS2, 1),
            case mod_task:get_one_trigger(TaskId) of
                false ->
                    skip;
                _RT ->
					case ParamList of
						4 ->
							skip;
						[4] ->
							skip;
						_ ->
		                    Mul = 
		                    case is_double(Hs) of
		                        true ->
		                            2;
		                        false ->
		                            1
		                    end,
		                    gen_server:cast(PS2#player_status.pid, {'husong_reward', Mul})
					end
            end            
    end,
	case lists:member(TaskId, [101295, 101296, 101297, 101070]) of
		true ->
			skip;
		false ->
			lib_special_activity:add_old_buck_task(PS2#player_status.id, 2),
			lib_qixi:update_player_task(PS2#player_status.id, 1),
		    mod_achieve:trigger_social(PS2#player_status.achieve, PS2#player_status.id, 13, 0, 1),
			mod_active:trigger(PS2#player_status.status_active, 1, 0, PS2#player_status.vip#status_vip.vip_type)
	end,
    set_husong_ref(PS2#player_status.id, 0),
    mod_task:normal_finish(TaskId, ParamList, PS2).

%% 上线护送初始
online(PS) ->
    case get_husong_task(PS) of
        [] ->
            B = PS#player_status.husong,
            PS#player_status{husong=B#status_husong{husong = 0}};
        RT -> 
            TD = data_task:get(RT#role_task.task_id, PS),            
			case data_yunbiao:is_probability_100_day() of
				true -> HusongNpc = 5;
				false -> HusongNpc = get_husong_npc(PS#player_status.id)
			end,
            B = PS#player_status.husong,
            case lists:member(RT#role_task.task_id, ?XS_HUSONG_TASK) of
                true ->
                    PS1 = PS#player_status{husong=B#status_husong{husong=1, husong_lv=TD#task.level, husong_npc = HusongNpc}},
                    PS1;
                false ->
                    LelfTime = util:unixtime() - RT#role_task.trigger_time,
                    case LelfTime =< ?HS_TIME_OUT of
                        true ->
                            PS1 = PS#player_status{husong=B#status_husong{husong=1, husong_lv=TD#task.level, husong_npc = HusongNpc}},
							BuffAddition = data_yunbiao:get_husong_phase_buff(PS1#player_status.lv),
							Buff = {BuffAddition, 0.55},
							PS2 = add_buff_online(PS1, Buff),
							case is_double(online) of
								false ->
									PS2;
								true ->
									case data_yunbiao:is_unchange_pk_day() of
										true -> PS2;
										false ->
											case lib_player:change_pkstatus(PS2, 2) of
												{ok, _ErrCode, _Type, _LeftTime, PSPK} -> 
													PSPK;
												{error, _ErrCode, _Type, _LeftTime, _} -> 
													PS2
											end
									end		                            
							end;
                        false -> 
                            gen_server:cast(PS#player_status.pid, {'apply_cast', pp_task, handle, [30005, PS, [RT#role_task.task_id]]}),
                            PS
                    end
            end
    end.


%% 下线保存
offline(PS) ->
    case get("husong_reward") of
        undefined ->
            PS;
        {Exp,Coin,_} ->
            NewStatus1 = lib_player:add_coin(PS, Coin),
            NewStatus2 = lib_player:add_exp(NewStatus1, Exp),
            erase("husong_reward"),
            [Title, Format] = data_yunbiao_text:get_reward(),
            Content = io_lib:format(Format, [Exp, Coin]),
            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PS#player_status.id],Title,Content,0,0,0,0,0,0,0,0,0]),
            NewStatus2
    end.


    

%% 收到护送求救传送
transport(PS, [SceneId, X, Y]) ->
    Hs = PS#player_status.husong,
    case lists:member(PS#player_status.scene, ?FORBIMAP) orelse lib_scene:is_dungeon_scene(PS#player_status.scene) of
        true -> 
            {ok, BinData0} = pt_120:write(12005, [0, 0, 0, data_yunbiao_text:get_transport(2), 0]),
            lib_server_send:send_to_sid(PS#player_status.sid, BinData0);
        false ->
            case Hs#status_husong.husong > 0 of
                true ->
                    {ok, BinData1} = pt_120:write(12005, [0, 0, 0, data_yunbiao_text:get_transport(3), 0]),
                    lib_server_send:send_to_sid(PS#player_status.sid, BinData1);
                false ->
                    case lib_scene:get_data(SceneId) of
                        [] -> 
                            {ok, BinData2} = pt_120:write(12005, [0, 0, 0, data_yunbiao_text:get_transport(4), 0]),
                            lib_server_send:send_to_sid(PS#player_status.sid, BinData2);
                        S  ->
                            case lists:keyfind(lv, 1, S#ets_scene.requirement) of 
                                false -> ok;%% 这里是异常情况
                                {lv, Lv} ->
                                    case PS#player_status.lv < Lv of
                                        true ->
                                            Format = data_yunbiao_text:get_transport(5),
                                            Msg = io_lib:format(Format, [Lv]),
                                            {ok, BinData3} = pt_120:write(12005, [0, 0, 0, Msg, 0]),
                                            lib_server_send:send_to_sid(PS#player_status.sid, BinData3);
                                        false ->
                                            % 通知别人离开场景
                                            lib_scene:leave_scene(PS),
                                            %pp_scene:handle(12004, PS, s),
                                            NewPlayerStatus = PS#player_status{scene=SceneId, x=X, y=Y},
                                            {ok, BinData4} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, S#ets_scene.name, S#ets_scene.sid]),
                                            lib_server_send:send_to_sid(NewPlayerStatus#player_status.sid, BinData4),
                                            {ok, NewPlayerStatus}
                                    end
                            end
                    end
            end
    end.

%% 发出求救信号
send_help(PS) -> 
    Hs = PS#player_status.husong,
    Gs = PS#player_status.guild,        
    case Hs#status_husong.husong =:= 0 of
        false -> 
            case Gs#status_guild.guild_id =:= 0 of
                true -> no_guild;
                false -> 
					SceneType = lib_scene:get_res_type(PS#player_status.scene),
                    %% 只能在普通，野外，安全三种场景求救
					case SceneType =:= 0 orelse SceneType =:= 1 orelse SceneType =:= 4 of
						true ->
                            %% 判断是否在监狱
                            case PS#player_status.scene =:= 998 of
                                false ->
                                    {ok, BinData} = pt_114:write(11401, [
                                            PS#player_status.scene,
                                            PS#player_status.x,
                                            PS#player_status.y,
                                            PS#player_status.nickname
                                        ]),
                                    mod_disperse:cast_to_unite(lib_husong, send_help_to_guild, [PS#player_status.id, Gs#status_guild.guild_id, BinData]),
                                    true;
                                true -> false
                            end;
						false ->
							false
					end
            end;
        true -> 
            false
    end.

send_help_to_guild(Id, GuildId, Bin) when GuildId =/= 0 -> 
	L = mod_chat_agent:match(guild_id_pid_sid, [GuildId]),
    [lib_unite_send:send_to_sid(Sid, Bin)||[OneId, _Pid, Sid] <- L, OneId =/= Id];
send_help_to_guild(_, _, _) -> ok.

%%护送任务后，更新属性
send_husong_attribute_notify(PS) ->
    lib_player:send_attribute_change_notify(PS, 1).

%% 广播护送Npc形象
%% Level: 
%%      0 => 没护送Npc形象
%%      _ => 护送Npc形象
send_figure_change_notify(Scene, CopyId, X, Y, PlayerId, Platform, ServNum,  Level, Hp, Hp_lim, Speed, NpcId) ->
    {ok, BinData1} = pt_120:write(12082, [2, PlayerId, Platform, ServNum, Speed]),
    lib_server_send:send_to_area_scene(Scene, CopyId, X, Y, BinData1),
    {ok, BinData2} = pt_120:write(12093, [PlayerId, Platform, ServNum, Level, Hp, Hp_lim, NpcId]),
    lib_server_send:send_to_area_scene(Scene, CopyId, X, Y, BinData2).

%% 更新护送Npc颜色
set_husong_npc(Id, HusongColor) ->
    db:execute(io_lib:format(?UPDATE_PLAYER_LOW_SET_HUSONG_COLOR, [HusongColor, Id])).

%% 查询护送Npc颜色
get_husong_npc(Id) ->
    db:get_one(io_lib:format(?SELECT_PLAYER_LOW_HUSONG_COLOR, [Id])).

%% 更新刷新护送Npc颜色
set_husong_ref(Id, Ref) ->
    db:execute(io_lib:format(?UPDATE_PLAYER_LOW_SET_HUSONG_REF, [Ref, Id])).

%% 查询刷新护送Npc颜色
get_husong_ref(Id) ->
    db:get_one(io_lib:format(?SELECT_PLAYER_LOW_HUSONG_REF, [Id])).

%% 护送保护时间
is_protect_time(User) when is_record(User, ets_scene_user)->
    Hs = User#ets_scene_user.husong,
    Hs#scene_user_husong.husong_pt =/= 0 andalso util:unixtime() - Hs#scene_user_husong.husong_pt < ?HS_PROTECT_TIME.

%% 判断是否能够被劫镖(供给战斗模块使用)
cant_intercept(MyUser, SrcUser) ->
    SrcHs = SrcUser#ets_scene_user.husong,
    case SrcHs#scene_user_husong.husong_lv > 0 of
        false ->
            false;
        true ->
            MyPhase = data_yunbiao:get_husong_phase(MyUser#ets_scene_user.lv),
            SrcPhase = data_yunbiao:get_husong_phase(SrcUser#ets_scene_user.lv),
            if
                MyPhase == SrcPhase ->
                    true;
                true ->
                    false
            end
    end.

%% 设置护送保护时间为0
clear_protect_time(PS) ->
    Hs = PS#player_status.husong,
    PS1 = PS#player_status{husong=Hs#status_husong{husong_pt = 0}},
    mod_scene_agent:update(husong, PS1),
    PS1.

%% 身上是否有护送类的任务(包含正常的护送任务，新手护送任务)
get_husong_task(Status) ->            
    TaskList = lib_task:get_trigger(Status#player_status.tid),
    F = fun(#role_task{kind = Kind, task_id = TaskId} = RT) ->
            IsNewHs = lists:member(TaskId, ?XS_HUSONG_TASK),
            if
                Kind == 4 -> {true, 1, RT}; %% 护送任务
                IsNewHs == true -> {true, 2, RT}; %%新手运镖(支线)
                true -> {false, 0, RT}
            end
    end,
    L = [F(X)||X<-TaskList],
    case lists:keyfind(true, 1, L) of
        {_, _, Val} ->
            Val;
        false ->
            []
    end.
    
%% 重新计算玩家速度(暂时理解)
count_player_speed(PlayerStatus) ->
    HS = PlayerStatus#player_status.husong,
    Buffs = HS#status_husong.hs_buff,
    count_player_speed_helper(Buffs, PlayerStatus#player_status.speed).

%% 重新计算玩家速度(暂时理解)
count_player_speed_helper([], Acc) ->
    Acc;
count_player_speed_helper([H|T], Acc) ->
    [SkillId,Val,_NowTime,_Time] = H,
    case SkillId of
        0 ->
            Val1 = Acc,
            count_player_speed_helper(T, Acc+Val1);
        1 ->
            count_player_speed_helper(T, Acc+Val);
        _ ->
            count_player_speed_helper(T, Acc)
    end.


%% 重新计算玩家状态(暂时理解)
count_player_attribute(PlayerStatus) ->
    HS = PlayerStatus#player_status.husong,
    Buffs = HS#status_husong.hs_buff,
    count_player_attribute_helper(Buffs, 0).

%% 重新计算玩家状态(暂时理解)
count_player_attribute_helper([], Acc) ->
    Acc;
count_player_attribute_helper([H|T], Acc) ->
    [SkillId,Val,_NowTime,_Time] = H,
    case SkillId of
        2 ->
            count_player_attribute_helper(T, Acc+Val);
        _ ->
            count_player_attribute_helper(T, Acc)
    end.

%% 玩家技能超时处理(暂时理解)
skill_timeout_process(PlayerStatus) ->
    HS = PlayerStatus#player_status.husong,
    Buffs = HS#status_husong.hs_buff,
    NowTime = util:unixtime(),
    NewBuffs = skill_timeout_process_helper(Buffs, [], NowTime),
    HS1 = HS#status_husong{ hs_buff=NewBuffs },
    PlayerStatus#player_status{husong=HS1}.

%% 玩家技能超时处理(暂时理解)
skill_timeout_process_helper([], NewBuffs, _NowTime) ->
    NewBuffs;
skill_timeout_process_helper([H|T], NewBuffs, NowTime) ->
    [SkillId,Val,StartTime, Time] = H,
    case NowTime-StartTime>=Time of
        true ->
            skill_timeout_process_helper(T,NewBuffs,NowTime);
        false ->
            skill_timeout_process_helper(T,[[SkillId,Val,StartTime, Time]|NewBuffs],NowTime)
    end.
    
%% 是否财神降临时间(8点到8点半) 完成任务在时间内
is_double(_PS) when is_record(_PS, player_status) ->
	NowTime = util:unixtime(),
	NowZero = util:unixdate(),
	case NowTime - NowZero >= ?HS_DOUBLE_START andalso NowTime - NowZero =< ?HS_DOUBLE_OVER of
		true ->
			true;
		false ->
			false
	end;
%%	%% HuSongStartTime = HuSongStatus#status_husong.husong_start_at,
%%	HuSongStartTime = mod_daily:get_refresh_time(PS#player_status.dailypid, PS#player_status.id, 5000030),
%%	NowZero = util:unixdate(),
%%	case HuSongStartTime =:= 0 of
%%		true ->
%%%% 			io:format("2 2 ~p ~n", [HuSongStartTime]),
%%			false;
%%		false ->
%%			TimeHSL = HuSongStartTime - NowZero,
%%			case TimeHSL > ?HS_DOUBLE_START andalso TimeHSL =< ?HS_DOUBLE_OVER of
%%				false ->
%%%% 			io:format("2 ~p ~n", [3]),
%%					false;
%%				true ->
%%					NowTime = util:unixtime(),
%%					TimeHL = NowTime - NowZero,
%%					case TimeHL > ?HS_DOUBLE_START andalso TimeHL =< ?HS_DOUBLE_OVER of
%%						true ->
%%							true;
%%						false ->
%%%% 			io:format("2 ~p ~n", [4]),
%%							false
%%					end
%%			end
%%	end;
is_double(online) ->
	NowTime = util:unixtime(),
	NowZero = util:unixdate(),
	case NowTime - NowZero >= ?HS_DOUBLE_START andalso NowTime - NowZero =< ?HS_DOUBLE_OVER of
		true ->
			true;
		false ->
			false
	end;
is_double(_) ->
	false.

%% 发送护送任务奖励
trigger_reward(PS) ->
    HS = PS#player_status.husong,
	Multi = lib_multiple:get_multiple_by_type(9,PS#player_status.all_multiple_data),
%% 	io:format(" ~p ~n", [HS#status_husong.husong_npc]),
    {_Exp, _Coin}= case is_double(PS) of
                    false ->
%% 						io:format("1 ~p ~n", [HS#status_husong.husong_npc]),
						data_yunbiao:get_husong_phase_reward(PS#player_status.lv, HS#status_husong.husong_npc);
                    true ->					
%% 						io:format("2 ~p ~n", [HS#status_husong.husong_npc]),						
                        {Exp0, Coin0} = data_yunbiao:get_husong_phase_reward(PS#player_status.lv, HS#status_husong.husong_npc),
						{Exp0 * 2, Coin0 * 2}
                end,
	Exp = _Exp*Multi, Coin = _Coin*Multi,
	case PS#player_status.combat_power >= 2000 of
		false -> %% 战斗力低于2000不会双倍,只有绑定
			{Exp, 0, Coin, 0};
		true ->
		    case lib_anti_brush:calc_anti_brush_score(PS) of
		        false -> %% 	有10%的概率获得绑定铜币，89%的概率获得非绑铜币，有1%的几率获得双倍非绑铜币与经验奖励	
		            Pro0 =10,
		            Rand = util:rand(1,1000),
					if
						Rand =< Pro0 ->
		            		{Exp * 2, Coin * 2, 0, 1};				%% 非绑定, 双倍, 最后一个1表示双倍
						true ->
							{Exp, Coin, 0, 0}						%% 非绑定, 无双倍
					end;
		        true -> 
						{Exp, 0, Coin, 0}						%% 绑定
		    end
	end.


%% 附加护送buff
add_buff_online(PS, Buff) ->
    {BuffAdd, Speed} = Buff,
	[Hp, Kang, Def] = BuffAdd,
    Hs = PS#player_status.husong,
    PS1 = PS#player_status{husong=Hs#status_husong{hs_buff2 = [Hp, Speed], hs_buff3 = [Kang, Def]}},
    PS2 = lib_player:count_player_speed(lib_player:count_player_attribute(PS1)),
	PS2.

%% 附加护送buff
add_buff(PS, Buff) ->
    {BuffAdd, Speed} = Buff,
	[Hp, Kang, Def] = BuffAdd,
    Hs = PS#player_status.husong,
    PS1 = PS#player_status{husong=Hs#status_husong{hs_buff2 = [Hp, Speed], hs_buff3 = [Kang, Def]}},
    PS2 = lib_player:count_player_speed(lib_player:count_player_attribute(PS1)),
	PS2#player_status{hp = PS2#player_status.hp_lim}.

%% 去除护送buff
clean_buff(PS) ->
    Hs = PS#player_status.husong,
    PS1 = PS#player_status{husong=Hs#status_husong{hs_buff2 = [0, 1], hs_buff3 = [0, 0]}},
    lib_player:count_player_speed(lib_player:count_player_attribute(PS1)).

%% 发送护送通知
send_husong_result_notify(PS, Result) ->
    Count = 2000 - mod_daily_dict:get_count(PS#player_status.id, 5000030),
    {ok, BinData} = pt_460:write(46009, [Result, Count]),
    lib_server_send:send_to_sid(PS#player_status.sid, BinData).

%% 发送 财神降临 开始通知
guoyun_notify() ->
    Time = lib_husong:guoyun_left_time(util:unixtime()),
    {ok, BinData} = pt_460:write(46010, [Time]),
    lib_unite_send:send_to_all(BinData),
    ok.

%% 获取双倍护送剩余时间
guoyun_left_time(BeginTime) ->
    Time = util:unixtime(),
    LeftTime = BeginTime + ?HS_GUOYUN_TIME - Time,
    case LeftTime < 0 of
        true -> 0;
        false -> LeftTime
    end.

%% 获取双倍护送剩余时间
guoyun_left_time() ->
    BeginTime = util:unixdate() + ?HS_DOUBLE_START, %% 每天20点开启
    guoyun_left_time(BeginTime).

%% 劫杀处理(由玩家死亡处理调用)
%% Self : 持镖者player_status 
%% Killer : 劫镖者player_status
husong_terminate(Self, Killer) when is_record(Self, player_status) andalso is_record(Killer, player_status) ->
    Hs = Self#player_status.husong,
	case Hs#status_husong.husong =:= 0 of
		true -> %% 不在护送中
			ok;
		false -> %% 在护送中(处理得到奖励)
			case Self#player_status.realm =:= Killer#player_status.realm of
				true -> %% 同国家玩家杀死,不处理
					{ok, BinData} = pt_460:write(46020, [2]),
					lib_server_send:send_to_sid(Killer#player_status.sid, BinData),
					ok;
				false ->
					LvLimtSelf = Self#player_status.lv div 10,				%% 自己的等级段
					LvLimtKiller = Killer#player_status.lv div 10, 			%% 劫镖者的等级段
					case LvLimtSelf =/= LvLimtKiller of
						true ->
							{ok, BinData} = pt_460:write(46020, [1]),
							lib_server_send:send_to_sid(Killer#player_status.sid, BinData),
							ok;
						false ->
							%% 获取每日劫镖次数
							InterceptTimes = data_yunbiao:get_intercept_times(Killer#player_status.id),
							case InterceptTimes >= ?HS_INTER_TIMES of
								true ->
									{ok, BinData} = pt_460:write(46020, [3]),
									lib_server_send:send_to_sid(Killer#player_status.sid, BinData);
								false ->
									
									%% 添加传闻
									lib_chat:send_TV({all},0, 2
													,[husong
													 ,2
													 ,Killer#player_status.id
													 ,Killer#player_status.realm
													 ,Killer#player_status.nickname
													 ,Killer#player_status.sex
													 ,Killer#player_status.career
													 ,Killer#player_status.image
													 ,Self#player_status.id
													 ,Self#player_status.realm
													 ,Self#player_status.nickname
													 ,Self#player_status.sex
													 ,Self#player_status.career
													 ,Self#player_status.image
													 ]),
									%% 护送任务基本奖励(根据等级和NPC颜色获取奖励基数, 不计算积分)
									{Exp0, Coin0}=data_yunbiao:get_husong_phase_reward(Self#player_status.lv, Hs#status_husong.husong_npc),
									%% 减半
									{Exp, Coin} = case is_double(Hs) of
				                        false ->
				                            {round(Exp0/2),round(Coin0/2)};
				                        true ->
				                            {Exp0,Coin0}
				                    end,
									%% 增加成功劫镖次数和被劫镖次数
									data_yunbiao:put_intercept_times(Killer#player_status.id),
									data_yunbiao:put_be_intercept_times(Self#player_status.id),
									%%　发送给劫镖者奖励
									gen_server:cast(Killer#player_status.pid, {'intercept_husong', Exp, Coin}),
									%%　发送给被劫镖者奖励
				                    gen_server:cast(Self#player_status.pid, {'reward_husong', Exp, Coin}),
									%%	广播护送Npc形象
				                    send_figure_change_notify(Self#player_status.scene, Self#player_status.copy_id, Self#player_status.x, Self#player_status.y, Self#player_status.id, Self#player_status.platform, Self#player_status.server_num, 0, Self#player_status.hp, Self#player_status.hp_lim, Self#player_status.speed, 0),
									%%	更新玩家的护送任务信息(结束护送)
				                    SelfHsOver = Self#player_status{husong=Hs#status_husong{husong=0,husong_start_at=0, husong_pt=0,hs_buff=[],hs_skill_trigger=[0,0,0],husong_npc=0}},
									%%	更新场景中的护送状态
				                    mod_scene_agent:update(husong, SelfHsOver),
									%% 发送任务失败
									TaskId = data_yunbiao:get_hs_task_id(SelfHsOver#player_status.lv, SelfHsOver#player_status.realm),
									%% 成就：护圣，累积成功打劫N次
									mod_achieve:trigger_social(Killer#player_status.achieve, Killer#player_status.id, 14, 0, 1),
									%% 运势任务(3700010:劫财劫色)
									lib_fortune:fortune_daily(Killer#player_status.id, 3700010, 1),
									case pp_task:handle(30004, SelfHsOver, [TaskId, 4]) of
										{ok, PsTaskOver} ->
											{ok, PsTaskOver};
										_ ->
											{ok, SelfHsOver}
									end
							end
					end
			end
	end.

%% %% 劫持护送_OLD 
%% intercept_husong(AttPS, DefPS) ->
%%     Hs = DefPS#player_status.husong,
%%     %%AttPhase = data_yunbiao:get_husong_phase(AttPS#player_status.lv),
%%     %%DefPhase = data_yunbiao:get_husong_phase(DefPS#player_status.lv),
%%     case get_husong_task(DefPS) of
%%         [] ->  {false, DefPS};
%%         RT ->
%%             case lists:member(RT#role_task.task_id, ?XS_HUSONG_TASK) of
%%                 true ->
%%                     {false, DefPS};
%%                 false ->
%%                     {Exp0,Coin0}=data_yunbiao:get_husong_phase_reward(DefPS#player_status.lv, Hs#status_husong.husong_npc),
%%                     {Exp,Coin} = 
%%                     case is_double(Hs) of
%%                         false ->
%%                             {round(Exp0/2),round(Coin0/2)};
%%                         true ->
%%                             {Exp0,Coin0}
%%                     end,
%%                     gen_server:cast(AttPS#player_status.pid, {'intercept_husong', Exp,Coin}),
%%                     gen_server:cast(DefPS#player_status.pid, {'reward_husong', Exp,Coin}),
%%                     %%case AttPhase =< DefPhase of
%%                     %%    true ->
%%                     send_figure_change_notify(DefPS#player_status.scene, DefPS#player_status.copy_id, DefPS#player_status.x, DefPS#player_status.y, DefPS#player_status.id, DefPS#player_status.platform, DefPS#player_status.server_num, 0, DefPS#player_status.hp, DefPS#player_status.hp_lim, DefPS#player_status.speed, 0),
%%                     PS1 = DefPS#player_status{husong=Hs#status_husong{husong=0,husong_start_at=0, husong_pt=0,hs_buff=[],hs_skill_trigger=[0,0,0],husong_npc=0}},
%%                     mod_scene_agent:update(husong, PS1),
%%                     util:errlog("intercept_husong", []),
%%                     {true, PS1}
%%             end
%%     end.

%% 判断是否允许切换PK状态(护送判定)
husong_pk_check(PlayerS) ->
	Hs = PlayerS#player_status.husong,
	case Hs#status_husong.husong > 0 of
		false ->
			false;
		true ->
			case is_double(online) of
				true ->				
					true;
				false ->
					false
			end
	end.


%% 判断是否护送任务(发送传闻用)
is_husonging(PlayerStatus, TaskId) ->
	HsList = [400010, 400020, 400030, 400040, 400050, 400060, 400070, 400080, 400090, 400100, 400110, 400120, 400130, 400140, 400150],
	case lists:member(TaskId, HsList) of
		true ->
			Hs = PlayerStatus#player_status.husong,
			Color = Hs#status_husong.husong_npc,
			case Color of
				5 ->
					lib_chat:send_TV({all},0, 2
									,[husong
									 ,1
									 ,PlayerStatus#player_status.id
									 ,PlayerStatus#player_status.realm
									 ,PlayerStatus#player_status.nickname
									 ,PlayerStatus#player_status.sex
									 ,PlayerStatus#player_status.career
									 ,PlayerStatus#player_status.image
									 ,1
									 ,102
									 ,132
									 ,105
									 ]);
				4 ->
					lib_chat:send_TV({all},0, 2
									,[husong
									 ,1
									 ,PlayerStatus#player_status.id
									 ,PlayerStatus#player_status.realm
									 ,PlayerStatus#player_status.nickname
									 ,PlayerStatus#player_status.sex
									 ,PlayerStatus#player_status.career
									 ,PlayerStatus#player_status.image
									 ,2
									 ,102
									 ,132
									 ,105
									 ]);
				_ ->
					skip
			end,
			case lib_mount:player_get_off_mount(PlayerStatus) of
				{false, _}->
					{ok, PlayerStatus};
				{ok, mount, NewPlayerStatus} ->
					{ok, mount, NewPlayerStatus};
				_ ->
					{ok, PlayerStatus}
			end;
		false->
			{ok, PlayerStatus}
	end.

%% 保存护送任务记录
save_husong_score(_PlayerId, _Score) ->
	1.
	
%% 财神降临
csjl() ->
	gen_fsm:send_all_state_event(timer_husong, {gocsjl}).
