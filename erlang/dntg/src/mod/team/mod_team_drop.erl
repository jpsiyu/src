%%------------------------------------------------------------------------------
%% @Module  : mod_team_drop
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.18
%% @Description: 组队物品掉落功能
%%------------------------------------------------------------------------------

-module(mod_team_drop).
-export([handle_cast/2]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("team.hrl").

%% --------------------------------- 异步消息 ----------------------------------

%% 掉落包分配
handle_cast({'DROP_DISTRIBUTION', [PlayerStatus, MonStatus, DropRule, DropList]}, State) ->
    case length(State#team.member) of
        0 ->
            lib_team:single_drop(PlayerStatus, MonStatus, DropRule, DropList),  
            {noreply, State};
        1 -> 
            lib_team:single_drop(PlayerStatus, MonStatus, DropRule, DropList),
            {noreply, State};
        _ ->
            X = PlayerStatus#player_status.x,
            Y = PlayerStatus#player_status.y,
			%1.定义查找玩家附近队友函数.
            F = fun(Mb) ->
                    Id = Mb#mb.id,
                    case PlayerStatus#player_status.id =:= Id of
                        false ->
                            case lib_player:get_player_info(Id) of
                                Player2 when is_record(Player2, player_status)->
                                    X1 = Player2#player_status.x,
                                    Y1 = Player2#player_status.y,
                                    case Player2#player_status.scene =:= PlayerStatus#player_status.scene 
										 andalso Player2#player_status.copy_id =:= PlayerStatus#player_status.copy_id
										 andalso X1 < X + 15 andalso X1 > X - 15 andalso Y1 < Y + 15 
										 andalso Y1 > Y - 15 of
                                        true -> [Player2];
                                        false -> []
                                    end;
                                _Other -> 
									[]
                            end;
                        true -> [PlayerStatus]
                    end
            end,
            case State#team.distribution_type of
				%1.自由拾取.
                0 -> 
                    lib_team:single_drop(PlayerStatus#player_status{id = 0}, MonStatus, DropRule, DropList),
                    {noreply, State};
				
				%2.随机拾取.
                1 -> 
                    SL = lists:flatmap(F, State#team.member),
                    case length(SL) of 
                        0 -> 
                            lib_team:single_drop(PlayerStatus#player_status{id = 0}, MonStatus, DropRule, DropList),
                            {noreply, State};  
                        1 ->
                            [R1] = SL, 
                            lib_team:single_drop(R1, MonStatus, DropRule, DropList),
                            {noreply, State};
                        Num ->
							L = lib_team:rand_drop(DropList, [MonStatus, DropRule], SL, SL, Num, []),
                            lib_goods_drop:send_drop(PlayerStatus, MonStatus, DropRule, L),
                            {noreply, State}
                    end;
				
				%3.轮流拾取.
                2 -> 
                    {L, Num} = lib_team:turn_drop(DropList, [MonStatus, DropRule], F, State, State#team.turn, PlayerStatus, []),
                    lib_goods_drop:send_drop(PlayerStatus, MonStatus, DropRule, L),
                    {noreply, State#team{turn = Num}}
            end
    end;

%% 广播给队员
handle_cast({'send_to_member', Bin}, State) ->
    lib_team:send_team(State, Bin),
    {noreply, State};

%% 队友完成任务处理
%% 1.打过怪物但没有杀死怪物可以通过handle_cast({'fin_task'这里完成任务.
%% 2.杀死怪物的玩家走handle_cast({'kill_mon'拿经验.
handle_cast({'fin_task', [Mid, SceneId, CopyId, X, Y]}, State) ->
    %% ---在副本和不在副本中的区别只在于:队员可共享杀怪任务的范围----
    %% 非副本中，一定范围内共享怪物杀死事件
    F = fun(Mb) ->
            Id = Mb#mb.id,
            case lib_player:get_player_info(Id, team) of
                {ok, _PlayerId1, _PlayerTid1, _TeamPid1, _Level1, _Physical1, _Scene1, _CopyId1, _X1, _Y1} ->
                    case _Scene1 == SceneId andalso
                          _CopyId1 == CopyId andalso
				          _X1 < X+20 andalso 
				          _X1 > X-20 andalso  
			              _Y1 < Y+20 andalso 
						  _Y1 > Y-20 of
                        true->
                            lib_player:rpc_cast_by_id(_PlayerId1, lib_task, event, 
													  [_PlayerTid1, kill, Mid, Id]);
                        false ->
                            skip
                    end;
				_ -> 
					[]
            end
        end,
    %% 在副本中的时候，同场景共享怪物杀死事件
    F2 = fun(Mb) ->
         Id = Mb#mb.id, 
         case lib_player:get_player_info(Id, team) of
			{ok, _PlayerId2, _PlayerTid2, _TeamPid2, _Level2, _Physical2, _Scene2, _CopyId2, _X2, _Y2} ->
                case _Scene2 == SceneId of
                    true->
                        lib_player:rpc_cast_by_id(_PlayerId2, lib_task, event, 
												 [_PlayerTid2, kill, Mid, Id]);
                    false ->
                        skip
                end;
			_ -> 
				[]
        end
    end,
    case lib_scene:is_dungeon_scene(SceneId) of
        true -> %% 在副本中 
            [F2(Mb) || Mb <-State#team.member];
        false -> %% 不在副本中
            [F(Mb) || Mb <-State#team.member]
    end,
    {noreply, State};

%% 队友完成任务搜集处理
handle_cast({'fin_task_goods', TaskList, [_Mid, Scene, CopyId, X, Y]}, State) ->
    %% ---在副本和不在副本中的区别只在于:队员可共享杀怪任务的范围----
    %% 非副本中，一定范围内共享怪物杀死事件
    F = fun(Mb) ->
            Id = Mb#mb.id,
            case lib_player:get_player_info(Id, team) of
                {ok, PlayerId, PlayerTid, _TeamPid, _Level, _Physical, _Scene, _CopyId, _X, _Y} ->                
                    case _Scene == Scene andalso
                          _CopyId == CopyId andalso
						  _X < X+20 andalso 
						  _X > X-20 andalso  
						  _Y < Y+20 andalso 
						  _Y > Y-20 of
                        true->
                            lib_player:rpc_cast_by_id(PlayerId, lib_task, event, 
													  [PlayerTid, item, TaskList, Id]);
                        false ->
                            skip
                    end;
                _ -> 
					[]
            end
        end,
    [F(Mb) || Mb <-State#team.member],
    {noreply, State};

%% 队友杀死怪物处理
%% 1.打过怪物但没有杀死怪物可以通过handle_cast({'fin_task'这里完成任务.
%% 2.杀死怪物的玩家走handle_cast({'kill_mon'拿经验.
handle_cast({'kill_mon', Mon, _AttScene}, State) ->
    %% ---在副本和不在副本中的区别只在于:队员可共享杀怪任务的范围----
    %% 非副本中，一定范围内共享怪物杀死事件
    Fun1 = fun(Mb) ->
            Id = Mb#mb.id,
            case lib_player:get_player_info(Id) of
                PlayerStatus when is_record(PlayerStatus, player_status)->
                    case PlayerStatus#player_status.scene == Mon#ets_mon.scene andalso  PlayerStatus#player_status.x < Mon#ets_mon.x+20 andalso PlayerStatus#player_status.x > Mon#ets_mon.x-20 andalso  PlayerStatus#player_status.y < Mon#ets_mon.y+20 andalso PlayerStatus#player_status.y > Mon#ets_mon.y-20 of
                        true->
                            %lib_task:event(PlayerStatus#player_status.tid, kill, Mon#ets_mon.mid, Id), %% 队伍成员杀掉怪物
                            %lib_target_day:kill_mon_target(Mon#ets_mon.mid, Id), %% 每日成就(暂时用不上)

                            ExpX = if
                                %% 采集怪物不做衰减
                                Mon#ets_mon.kind == 1 -> 1;
                                true -> 
                                    lib_player:reduce_mon_exp_arg(PlayerStatus#player_status.lv , Mon#ets_mon.lv)
                            end,
                            {_, ShtExp} = Mb#mb.sht_exp,
                            [{PlayerStatus, (ExpX * ShtExp)}];
                        false ->
                            []
                    end;
                _Other -> 
					[]
            end
        end,
    %% 在副本中的时候，同场景共享怪物杀死事件
    Fun2 = fun(Mb) ->
         Id = Mb#mb.id, 
         case lib_player:get_player_info(Id) of
             PlayerStatus when is_record(PlayerStatus, player_status)->
                case PlayerStatus#player_status.scene == Mon#ets_mon.scene andalso
					  PlayerStatus#player_status.copy_id == Mon#ets_mon.copy_id of
                      true->
                          %lib_task:event(PlayerStatus#player_status.tid, kill, Mon#ets_mon.mid, Id), %% 队伍成员杀掉怪物
                          %%lib_target_day:kill_mon_target(Mon#ets_mon.mid, Id), %% 每日成就
                          %case PlayerStatus#player_status.x < Mon#ets_mon.x+20 andalso PlayerStatus#player_status.x > Mon#ets_mon.x-20 andalso  PlayerStatus#player_status.y < Mon#ets_mon.y+20 andalso PlayerStatus#player_status.y > Mon#ets_mon.y-20 of
                          %    true ->
                          ExpX = if
                              %% 采集怪物不做衰减
                              Mon#ets_mon.kind == 1 -> 1;
                              true -> 
                                  lib_player:reduce_mon_exp_arg(PlayerStatus#player_status.lv , Mon#ets_mon.lv)
                          end,
                          {_, ShtExp} = Mb#mb.sht_exp,
                          [{PlayerStatus, (ExpX * ShtExp)}];
                         %  false -> []
                        %end;
                    false -> []
                end;
			_Other -> 
				[]
        end
    end,
    case lib_scene:is_dungeon_scene(Mon#ets_mon.scene) of
        true -> %% 在副本中 
            L = lists:flatmap(Fun2, State#team.member),
            case length(L) of
                0 -> ok;
                1 -> [PlayerStatus] = L, %% 只有一个人符合分经验的规则
                    lib_team:team_add_exp(PlayerStatus, Mon#ets_mon.exp, Mon#ets_mon.llpt);
                MNum ->
                    %% 三职业经验本加成
                    ExpDungeon = (Mon#ets_mon.mid == 22031 orelse Mon#ets_mon.mid == 22032 orelse Mon#ets_mon.mid == 22041) andalso lib_team:is_three_career(L),
                    AppointDungeon = (Mon#ets_mon.mid >= 23301 andalso Mon#ets_mon.mid =< 23349) andalso lib_team:is_two_sex(L),
                    SpecialDungeonExp = case ExpDungeon orelse AppointDungeon of
                        true -> 0.2;
                        false -> 0
                    end,
                    MemExp = round(Mon#ets_mon.exp * ((1 + 1.5*MNum/5)/MNum+SpecialDungeonExp)),
                    [lib_team:team_add_exp(PlayerStatus, MemExp, Mon#ets_mon.llpt) || PlayerStatus <- L]
            end;
        false -> %% 不在副本中
            L = lists:flatmap(Fun1, State#team.member),
            case length(L) of
                0 -> ok;
                1 -> [PlayerStatus] = L, %% 只有一个人符合分经验的规则 
                    lib_team:team_add_exp(PlayerStatus, Mon#ets_mon.exp, Mon#ets_mon.llpt);
                MNum ->
                    MemExp = round(Mon#ets_mon.exp * (1 + 1.5*MNum/5)/MNum),
                    [lib_team:team_add_exp(PlayerStatus, MemExp, Mon#ets_mon.llpt) || PlayerStatus <- L]
            end
    end,
    %% 触发成就
    case Mon#ets_mon.boss > 0 of
        true -> 
            %%　增加亲密度
%%             L2 = [{PlayerStatus#player_status.id, PlayerStatus#player_status.nickname}||{Player,_} <- L, 
%% 				mod_daily:get_count(PlayerStatus#player_status.id, 3701) < 200],
%%             mod_disperse:rpc_cast_by_id(?UNITE, lib_relationship2, team_intimacy, [L2, Mon#ets_mon.name]),
%%             [mod_daily:increment(Xid, 3701)||{Xid, _}<-L2];
				skip;
        false -> skip
    end,
%%     %% 触发运势
%%     case Mon#ets_mon.boss of
%%         %% 野外BOSS
%%         1 -> 
%%             lib_fortune:rpc_trigger_task_list([Player#ets_online.id || {Player,_} <- L], 4, Mon#ets_mon.mid, 1),
%%             [lib_target_week:do_event(Player#ets_online.id, Player#ets_online.lv, 5, 1, Mon#ets_mon.mid) || {Player,_} <- L];
%%         %% 宠物BOSS
%%         2 -> 
%%             lib_fortune:rpc_trigger_task_list([Player#ets_online.id || {Player,_} <- L], 5, Mon#ets_mon.mid, 1),
%%             [lib_target_week:do_event(Player#ets_online.id, Player#ets_online.lv, 5, 1, Mon#ets_mon.mid) || {Player,_} <- L];
%%         %% 世界BOSS
%%         3 -> 
%%             lib_fortune:rpc_trigger_task_list([Player#ets_online.id || {Player,_} <- L], 6, Mon#ets_mon.mid, 1),
%%             [lib_target_week:do_event(Player#ets_online.id, Player#ets_online.lv, 5, 1, Mon#ets_mon.mid) || {Player,_} <- L];
%%         %% 帮派BOSS
%%         4 -> 
%%             lib_fortune:rpc_trigger_task_list([Player#ets_online.id || {Player,_} <- L], 7, Mon#ets_mon.mid, 1);
%%         _ -> skip
%%     end,
    {noreply, State}.

%% 分配物品
%handle_cast({'distribution', PlayerStatus, DropId}, State) ->
%    case length(State#team.member) of
%        0 ->  {noreply, State};
%        1 ->  
%            catch gen_server:cast(PlayerStatus#player_status.pid, {'TEAM_DISTRIBUTION', DropId}),
%            {noreply, State};
%        _ ->
%            X = PlayerStatus#player_status.x,
%            Y = PlayerStatus#player_status.y,
%            F = fun(Mb) ->
%                    Id = Mb#mb.id,
%                    case PlayerStatus#player_status.id =:= Id of
%                        false ->
%                            case ets:lookup(?ETS_ONLINE, Id) of
%                                [] -> [];
%                                [Player] ->
%                                    X1 = Player#ets_online.x,
%                                    Y1 = Player#ets_online.y,
%                                    case Player#ets_online.scene =:= PlayerStatus#player_status.scene andalso X1 < X + 15 andalso X1 > X - 15 andalso Y1 < Y + 15 andalso Y1 > Y - 15 of
 %                                       true -> [Player#ets_online.pid];
 %                                       false -> []
 %                                   end
 %                           end;
 %                       true -> [PlayerStatus#player_status.pid]
 %                   end
 %           end,
 %           case lists:member(DropId, State#team.drop_choosing_l) orelse lists:member(DropId, State#team.drop_choose_success_l) of
 %               false ->
 %                  NewState = State#team{drop_choosing_l = [DropId | State#team.drop_choosing_l]},
 %                   case State#team.distribution_type of
 %                       0 -> %% 自由拾取         
 %                           catch gen_server:cast(PlayerStatus#player_status.pid, {'TEAM_DISTRIBUTION', DropId}),
 %                           {noreply, NewState};
 %                       1 -> %% 随机拾取
 %                           SL = lists:flatmap(F, State#team.member),
 %                           case length(SL) of       
 %                               1 -> 
 %                                   catch gen_server:cast(PlayerStatus#player_status.pid, {'TEAM_DISTRIBUTION', DropId}),
 %                                   {noreply, NewState};
 %                               Num ->
 %                                   T = util:rand(1, 500) rem Num + 1, %% 随机
 %                                   Pid = lists:nth(T, SL),
 %                                   catch gen_server:cast(Pid, {'TEAM_DISTRIBUTION', DropId}),
 %                                   {noreply, NewState}
 %                           end;
 %                       2 -> %% 轮流拾取
 %                           {Pid, Num} = case State#team.turn >= ?TEAM_MEMBER_MAX of
 %                               true -> lib_team:turn_choose(once, 0, NewState, F);
 %                               false -> lib_team:turn_choose(State#team.turn, NewState, F)
 %                           end,
 %                           case is_pid(Pid) of
 %                               true ->
 %                                   catch gen_server:cast(Pid, {'TEAM_DISTRIBUTION', DropId}),
 %                                    {noreply, NewState#team{turn = Num}};
 %                               false -> {noreply, NewState}
 %                           end
 %                   end;
 %               true -> {noreply, State}
 %           end
 %   end;
