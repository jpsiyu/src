%%% @Module  : lib_mon_die
%%% @Author  : zzm
%%% @mail    : ming_up@163.com
%%% @Created : 2010.05.08
%%% @Description: 怪物死亡/掉落处理
%%%-----------------------------------
-module(lib_mon_die).
-include("scene.hrl").
-include("server.hrl").
-export([
	drop/6,
	mon_exp_reduction/3,
	execute_any_fun/3,
	execute_any_fun_clusters/3,
	finish_task/3,
	finish_task_goods/4
]).

%% 怪物掉落处理
%% PS：最后攻击玩家的ps
%% Kind：怪物类型（如采集，旗子，正常怪物等）
%% Mon：怪物 #ets_mon
%% Klist：仇恨列表
%% LastAtterPid ：最后攻击玩家进程
%% FirstAtterPid：第一次攻击玩家进程
drop(7, PS, Mon, _Klist, _LastAtterPid, _FirstAtterPid) -> 
	lib_goods_drop:mon_drop(PS, Mon, []);
drop(_Kind, PS, Mon, Klist, LastAtterPid, FirstAtterPid) ->
	case catch mon_drop(PS, Mon, Klist, LastAtterPid, FirstAtterPid) of
		{ok, DropOwnerPid, PlayerStatus} ->
            %% 活动双倍
            ActivityExpRate = lib_multiple:get_multiple_by_type(11, PS#player_status.all_multiple_data),
            ExpRate         = ActivityExpRate * lib_off_line:get_dungeon_exp(PlayerStatus),
            LastExp         = trunc(Mon#ets_mon.exp*ExpRate),

			%% 衰减参数
			Weaken = mon_exp_reduction(Mon#ets_mon.kind, PlayerStatus#player_status.lv, Mon#ets_mon.lv),

			%% 处理打怪人物经验
			PlayerBaseExp = LastExp,
			case PlayerBaseExp > 0 of
				true ->
					case is_pid(PlayerStatus#player_status.pid_team) of
						true -> %% 有队伍
							DoExpMon = Mon#ets_mon{exp = PlayerBaseExp},
							gen_server:cast(PlayerStatus#player_status.pid_team, {'kill_mon', DoExpMon, PlayerStatus#player_status.scene});
						false -> %% 没队伍
							gen_server:cast(DropOwnerPid, {'EXP', round(Weaken * PlayerBaseExp)}),
							case Mon#ets_mon.llpt > 0 of
								true  -> gen_server:cast(DropOwnerPid, {'llpt', Mon#ets_mon.llpt});
								false -> skip
							end
					end;
				_ ->
					skip
			end;
		_Other ->
			util:errlog("Error: lib_mon_die:drop/6 Error ~p~n", [_Other]),
			ok
	end.

%% 打怪经验衰减 衰减参数
mon_exp_reduction(MonKind, PlayerLv, MonLv) -> 
	if 
		%% 采集怪不做衰减
		MonKind == 1          -> 1;
		%% 低于自身20级以上的怪物，击杀获得经验值降低为5%
		PlayerLv > MonLv + 20 -> 0.05;
		%% 低于自身10级以上的怪物，击杀获得经验值降低为30%
		PlayerLv > MonLv + 10 -> 0.3;
		true                  -> 1
	end.

%% 怪物掉落
%% PS：最后攻击玩家的ps
%% Klist：仇恨列表
%% LastAtterPid ：最后攻击玩家进程
%% FirstAtterPid：第一次攻击玩家进程
mon_drop(PS, Minfo, List, LastAtterPid, FirstAtterPid) ->
	case Minfo#ets_mon.drop of
		0 -> %% 最大伤害
			MaxHurtPid = mod_mon_active:calc_hatred_list(List, none, 0),
			case List =:= [] orelse MaxHurtPid =:= LastAtterPid of
				true->
					lib_goods_drop:mon_drop(PS, Minfo, List),
					{ok, LastAtterPid, PS};
				false ->
					case catch gen:call(MaxHurtPid, '$gen_call', 'base_data') of
						{ok, PlayerStatus} ->
							lib_goods_drop:mon_drop(PlayerStatus, Minfo, List),
							{ok, MaxHurtPid, PlayerStatus};
						{'EXIT', _Reason} ->
							lib_goods_drop:mon_drop(PS, Minfo, List),
							{ok, LastAtterPid, PS}
					end
			end;
		1 ->%% 最后伤害
			lib_goods_drop:mon_drop(PS, Minfo, List),
			{ok, LastAtterPid, PS};
		2 ->%% 最先伤害
			case FirstAtterPid =/= LastAtterPid of
				true->
					case catch gen:call(FirstAtterPid, '$gen_call', 'base_data') of
						{ok, PlayerStatus} ->
							lib_goods_drop:mon_drop(PlayerStatus, Minfo, List),
							{ok, FirstAtterPid, PlayerStatus};
						{'EXIT',_Reason} ->
							lib_goods_drop:mon_drop(PS, Minfo, List),
							{ok, LastAtterPid, PS}
					end;
				false ->
					case get_player_status(FirstAtterPid) of
						{ok, self} ->
							PlayerStatus = PS;
						PlayerStatus1 when is_record(PlayerStatus1, player_status) ->
							PlayerStatus = PlayerStatus1;
						_ ->
							PlayerStatus = PS
					end,
					lib_goods_drop:mon_drop(PlayerStatus, Minfo, List),
					{ok, LastAtterPid, PS}
			end;
		3 ->
            %% 以组队单位计算贡献伤害
            List1 = mod_mon_active:team_sort_klist(List),
            Len = length(List1),
            case Len of
                1 ->
                    [{MaxHurtPid , _, _, _} | _] = List1,
                    if
                        MaxHurtPid =:= self() ->
                            lib_goods_drop:diablo_drop([PS], Minfo);
                        true ->
                            case gen:call(MaxHurtPid, '$gen_call', 'base_data') of
                                {ok, PlayerStatus} ->
                                    lib_goods_drop:diablo_drop([PlayerStatus], Minfo);
                                {'EXIT', _R} ->
                                    lib_goods_drop:diablo_drop([PS], Minfo)
                            end
                    end;
                _ ->
                    List2 = lists:nthtail(Len - 2, List1),
                    [{MaxHurtPid , _, _, _}, {MaxSecondHurtPid, _, _, _}] = List2,
                    case get_player_status(MaxHurtPid) of
                        {ok, self} ->
                            P1 = PS;
                        PlayerStatus1 when is_record(PlayerStatus1, player_status) ->
                            P1 = PlayerStatus1;
                        _ ->
                            P1 = PS
                    end,
                    case get_player_status(MaxSecondHurtPid) of
                        {ok, self} ->
                            P2 = PS;
                        PlayerStatus2 when is_record(PlayerStatus2, player_status) ->
                            P2 = PlayerStatus2;
                        _ ->
                            P2 = PS
                    end,
                    case get_player_status(LastAtterPid) of
                        {ok, self} ->
                            P3 = PS;
                        PlayerStatus3 when is_record(PlayerStatus3, player_status) ->
                            P3 = PlayerStatus3;
                        _ ->
                            P3 = PS
                    end,
                    lib_goods_drop:diablo_drop([P2, P1, P3], Minfo)
            end,
            {ok, LastAtterPid, PS}   
	end.

get_player_status(Pid) ->
	if
		Pid =:= self() ->
			{ok, self};
		true ->
			case catch gen:call(Pid, '$gen_call', 'base_data') of
				{ok, PlayerStatus} ->
					PlayerStatus;
				{'EXIT', _R} ->
					_R;
				Other -> Other
			end
	end.

%% 完成任务
finish_task(List, Mon, PS) ->
	F = fun(Pid) ->
			if 
				PS#player_status.pid =:= Pid ->
					lib_task:fin_task(PS, [Mon#ets_mon.mid, Mon#ets_mon.scene, Mon#ets_mon.copy_id, Mon#ets_mon.x, Mon#ets_mon.y]);
				true ->
					gen_server:cast(Pid, {'fin_task', [Mon#ets_mon.mid, Mon#ets_mon.scene, Mon#ets_mon.copy_id, Mon#ets_mon.x, Mon#ets_mon.y]})
			end
	end,
	[F(Pid) || {Pid, _, _, _ } <- List].

%% 完成任务
finish_task_goods(TaskList, List, Mon, PS) ->
	F = fun(Pid) ->
			if 
				PS#player_status.pid =:= Pid ->
					lib_task:fin_task_goods(PS, TaskList, [Mon#ets_mon.mid, Mon#ets_mon.scene, Mon#ets_mon.copy_id, Mon#ets_mon.x, Mon#ets_mon.y]);
				true ->
					gen_server:cast(Pid, {'fin_task_goods', TaskList, [Mon#ets_mon.mid, Mon#ets_mon.scene, Mon#ets_mon.copy_id, Mon#ets_mon.x, Mon#ets_mon.y]})
			end
	end,
	[F(Pid) || {Pid, _, _, _} <- List].

%% @spec execute_any_fun_clusters(Mon, Klist, LastKiller) -> ok.
%% 跨服中，怪物死亡需要执行的一些操作
%%       Mon = #ets_mon{} 怪物记录
%%       Klist = list() = [tuple1, tuple2...]
%%                        tuple1 = {Pid, HurtValue, Key, PidTeam, Name}
%%                        Pid = pid()           玩家进程
%%                        HurtValue = integer() 总伤害值
%%                        Key = list() = [Id, PlatForm, ServerNum] 玩家Key
%%                        PidTeam = pid()       组队进程
%%                        Name = string         玩家名字
%%       LastKiller = tuple() = {Key, Pid}      最后击倒怪物的玩家Key和pid
%%                        Key = list() = [Id, PlatForm, ServerNum] 玩家Key
%% -------------------------------------------------------------------------------
%% NODE: 因本函数在跨服场景的怪物进程操作，所以在对玩家的进程(Pid)进程操作的时候，
%%       要使用 mod_clusters_center:apply_cast/4 进行操作
%% -------------------------------------------------------------------------------
%% @end
execute_any_fun_clusters(Mon, _Klist, LastKiller) -> 
	{[Id, PlatForm, ServerNum], _Pid} = LastKiller,

    %% 跨服3v3神被占领
    Kf3v3MonList = data_kf_3v3:get_occupy_ids(),
    case lists:member(Mon#ets_mon.mid, Kf3v3MonList) of
        true ->
            catch mod_kf_3v3:mon_die(PlatForm, ServerNum, Id, Mon#ets_mon.mid);
        _ ->
            skip
    end,
    ok.

%% 本服怪物死亡需要执行的一些操作(由mod_server_cast调用), 注意不要call玩家进程和组队进程
%% Klist : 伤害玩家列表数据
execute_any_fun(Mon, PS, _Klist) ->
    AttId2 = PS#player_status.id,

    lib_guild_scene:guild_mon_dead(Mon, PS),

    %% 完成竞技场统计
    ArenaMonList = data_arena_new:get_npc_type_id(),
    case lists:member(Mon#ets_mon.mid, ArenaMonList) of
        true ->
            lib_arena_new:set_score_by_kill_npc(AttId2, Mon#ets_mon.mid);
        false ->
            skip
    end,
    %%完成帮战统计
    FactionwarMonList = data_factionwar:get_npc_type_id(),
    case lists:member(Mon#ets_mon.mid, FactionwarMonList) andalso Mon#ets_mon.mid /= 10547 of %% 过滤了帮派水晶，积分会在交付时再加上
        true ->
            lib_factionwar:set_score_by_kill_npc(AttId2, Mon#ets_mon.mid,Mon#ets_mon.id);
        false ->
            skip
    end,
    %%完成幡桃统计
    PeachMonList = data_peach:get_npc_type_id(),
    case lists:member(Mon#ets_mon.mid, PeachMonList) of
        true ->
            lib_peach:set_score_by_kill_npc(AttId2, Mon#ets_mon.mid);
        false ->
            skip
    end,

    %% 南天门
    WubianhaiMonIdList = data_wubianhai_new:get_wubianhai_config(mon_id),
     case lists:member(Mon#ets_mon.mid, WubianhaiMonIdList) of
        true ->
            gen_server:cast(self(), {'wubianhai_kill_mon', Mon#ets_mon.mid}); 
        false ->
            skip
    end,

    case Mon#ets_mon.boss > 0 of
        true  -> gen_server:cast(self(), {'kill_boss', [Mon#ets_mon.boss, Mon#ets_mon.mid]});
        false -> ok
    end,

    %% 攻城战怪物死亡处理
    %lib_city_war:mon_die(Mon, PS),
    ok.
