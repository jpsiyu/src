%%%--------------------------------------
%%% @Module  : pp_tower_dungeon
%%% @Author  : zzm
%%% @Email   : ming_up@163.com
%%% @Created : 2011.01.06
%%% @Description: 锁妖塔
%%%--------------------------------------

-module(pp_tower_dungeon).
-export([handle/3]).
-include("common.hrl").
%-include("record.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("dungeon.hrl").
-include("tower.hrl").
-include("scene.hrl").

%% 进入锁妖塔
handle(28000, Status, TowerType) ->
	%1.得到玩家当前场景数据.
	PlayerScene = 
		case lib_scene:get_data(Status#player_status.scene) of
            SceneData when is_record(SceneData, ets_scene) ->
				SceneData;
			_ ->
				#ets_scene{}
		end,
	
	%1.计算进入副本你的时间间隔.
	NowTime = util:unixtime(),
	LastTime = 
		case get({dungeon, Status#player_status.id}) of
			undefined -> 
				NowTime-6;
			LastTime1 ->
				LastTime1
		end,
	LastTime2 = NowTime - LastTime,
	put({dungeon, Status#player_status.id}, NowTime),
	
	%1.跳层到那种地图.
    {TowerSceneId, Ratio, ExText}= case TowerType of
        9 ->  {300, 0, ""}; % 多人九重天
        10 -> {340, 0, ""}; % 单人九重天
        30 -> {900, 0, ""}; % 新手爬塔副本.
        31 -> {300, 2, "<font color='#fffc00'>双倍</font>"}; % 多人九重天(双倍掉落)
        32 -> {340, 2, ""}; % 单人九重天(双倍掉落)
		_ ->  {340, 0, ""}  % 容错处理.
    end,
    HS2 = Status#player_status.husong,
    IsChangeSceneSign = Status#player_status.change_scene_sign,
    IsFlyMount = Status#player_status.mount#status_mount.fly_mount,
    AddCount = if Ratio == 0 -> 1; true -> 2 end,
	Res =
    if  PlayerScene#ets_scene.type =:= ?SCENE_TYPE_GUILD orelse
        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_ARENA orelse
        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_BOSS orelse
        PlayerScene#ets_scene.type =:= ?SCENE_TYPE_ACTIVE ->								
            {false, data_scene_text:get_sys_msg(28)};
        %1.护送美女状态.					
        HS2#status_husong.husong=/=0 ->
            {false, data_dungeon_text:get_tower_text(1)};

        %2.换线中.					
        IsChangeSceneSign=/=0 ->
            {false, data_dungeon_text:get_tower_text(35)};

        %3.在飞行坐骑上不能进入把副本.					
        IsFlyMount=/=0 ->
            {false, data_dungeon_text:get_dungeon_text(5)};

        %4.副本操作太快.
        LastTime2 =< 5 ->										
            {false, data_dungeon_text:get_dungeon_text(3)};
        true ->
            case data_dungeon:get(TowerSceneId) of
                [] -> {false, data_dungeon_text:get_tower_text(2)};
                Dun -> %% 普通场景进入副本
                    case Ratio == 0 orelse lib_goods_util:is_enough_money(Status, 10, gold) of
                        true -> 
                            case lib_scene:check_dungeon_requirement(Status, Dun#dungeon.condition) of
                                {false, Reason} -> {false, Reason};
                                {true} ->
                                    Count = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, TowerSceneId),
                                    if
                                        %% 进入次数已满
                                        Count + AddCount > Dun#dungeon.count -> {false, data_dungeon_text:get_tower_text(36)}; 
                                        %% 单人九重天
                                        TowerSceneId == 340 -> 
                                            %% 次数+1
                                            mod_daily:plus_count(Status#player_status.dailypid, Status#player_status.id, TowerSceneId, AddCount),
                                            lib_team:delete_enlist2(Status#player_status.id),
                                            Now = util:unixtime(),
                                            DungeonPid = mod_dungeon:start_tower(0, 0, TowerSceneId,
                                                [{Status#player_status.id, 
                                                        Status#player_status.pid, 
                                                        Status#player_status.pid_dungeon_data}], 
                                                0, 
                                                [[{TowerSceneId, Now}], [], Now, [], 1, Ratio]),
                                            TowerInfo = data_tower:get(TowerSceneId),
                                            case catch gen_server:call(DungeonPid, {check_enter, TowerSceneId, Status#player_status.id, 0}) of
                                                {'EXIT', _} ->
                                                    ok;
                                                {false, _Msg} ->
                                                    {false, _Msg};
                                                {true, _SceneId} ->			
                                                    Status#player_status.pid ! {'enter_tower', [TowerInfo#tower.time, TowerSceneId, Ratio]},
                                                    ok
                                            end;
                                        %% 组队九重天
                                        true -> 
                                            case check_team_condition(Status, Dun, TowerSceneId, AddCount) of
                                                {false, Reason1} -> {false, Reason1};
                                                true ->
                                                    %% 队伍是否同意
                                                    Text = data_dungeon_text:get_tower_text(3, [ExText, Dun#dungeon.name]),
                                                    gen_server:cast(Status#player_status.pid_team, 
                                                        {'arbitrate_req', 
                                                            Status#player_status.id, 
                                                            Status#player_status.nickname, 
                                                            Text, 1, {TowerSceneId, Ratio}})
                                            end
                                    end
                            end;
                        false -> {false, data_dungeon_text:get_tower_text(37)}
                    end
            end
    end,
    case Res of
        {false, Msg} -> 
            {ok, BinData} = pt_120:write(12005, [0, 0, 0, Msg, 0]),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        _ ->
			ok
    end;

%% 获取剩余时间
handle(28002, Status, []) ->
    case is_pid(Status#player_status.copy_id) of
        true ->
            %Count = mod_daily:get_count(Status#player_status.id, ?TOWER_BEGIN_SCENEID),
            gen_server:cast(Status#player_status.copy_id, {'tower_left_time', 
														   Status#player_status.id,
														   Status#player_status.dailypid});
        false -> ok
    end;

%% 获取每层霸主 -- 公共服务器(99线)
handle(28001, Status, SceneId) -> %% 这里SceneId是资源id
    lib_tower_dungeon:next_level_get_master([Status#unite_status.id], SceneId);

%% 获取剧情副本霸主 -- 公共服务器.
handle(61014, Status, []) ->
    lib_story_master:get_story_masters(Status#unite_status.id);

%% 计时结束
%handle(28003, Status, [LeaderId, Time]) -> ok;

%% 霸主每天领取奖励
handle(28004, Status, []) ->
    Res = case mod_disperse:rpc_call_by_id(99, lib_tower_dungeon, get_reward, [Status#player_status.id]) of
        {badrpc, _} -> 0;
        not_master -> 2;
        has_gotten -> 3;
        SceneId ->
            TowerInfo = data_tower:get(SceneId),
            Status#player_status.pid ! {'tower_reward', 
                TowerInfo#tower.master_exp, 
                TowerInfo#tower.master_llpt, []},
            Msg = lists:concat([data_dungeon_text:get_tower_text(14), 
								TowerInfo#tower.level, 
								data_dungeon_text:get_tower_text(15)]),
            lib_unite_send:send_sys_msg_one(Status#player_status.socket, Msg),
            1
    end,
    {ok, BinData} = pt_280:write(28004, Res),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    ok;

%% 离开锁妖塔
handle(28005, Status, []) ->
	CopyId = Status#player_status.copy_id,
    PlayerId = Status#player_status.id,
    case is_pid(CopyId) of
        true -> 
            %mod_dungeon:total_tower_reward(Status#player_status.copy_id, Status#player_status.id, quit),
			lib_dungeon:set_logout_type(CopyId, ?DUN_EXIT_CLICK_BUTTON),
            lib_dungeon:quit(CopyId, PlayerId, 5),
            lib_dungeon:clear(role, CopyId);
        false -> ok
    end;

%% 获取这一层的奖励
handle(28006, Status, []) -> %% 这里SceneId是资源id
    case is_pid(Status#player_status.copy_id) of
        true -> gen_server:cast(Status#player_status.copy_id, {'now_level_reward', Status#player_status.id});
        false -> ok
    end;

%% 超时全部离开
handle(28010, _Status, []) ->
	ok;
%%     case is_pid(Status#player_status.copy_id) of
%%         true -> 
%%             Status#player_status.copy_id ! 'CLOSE_TOWER_DUNGEON';
%%         %mod_dungeon:total_tower_reward(Status#player_status.copy_id, Status#player_status.id, quit),
%%         %mod_dungeon:quit(Status#player_status.copy_id, Status#player_status.id),
%%         %mod_dungeon:clear(role, Status#player_status.copy_id);
%%         false -> ok
%%     end;

%% 增加跳层次数
handle(28011, Status, []) ->
    case goods_util:is_enough_money(Status, 10000, coin) of
        true ->
            Vip = Status#player_status.vip,
            Status1 = goods_util:cost_money(Status, 10000, coin),
            mod_daily:increment(Status#player_status.dailypid, Status#player_status.id, 2801),
            log:log_consume(add_skip_level, coin, Status, Status1, data_dungeon_text:get_tower_text(16)),
            Count = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 2801) + Vip#status_vip.vip_type - mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 2800),
            {ok, BinData} = pt_280:write(28011, [1, Count]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            lib_player:refresh_client(Status1#player_status.id, 2),
            {ok, Status1};
        false -> 
            {ok, BinData} = pt_280:write(28011, [0, 0]),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end; 

handle(_Cmd, _Status, _Data) ->
    ?DEBUG("handle_tower no match", []),
    {error, "handle_tower no match"}.

check_tower_condition([], _) -> true;
check_tower_condition([H|T], LeaderScene) -> 
    %case ets:lookup(?ETS_ONLINE, H) of
	case lib_player:get_player_info(H, dungeon) of        
        {ok, SceneId} -> 
            if 
                %Info#ets_online.is_pra /= 0 -> %% 检查是否有离线挂机
                %    {false, data_dungeon_text:get_tower_text(17)};
                SceneId =/= LeaderScene ->
                    {false, data_dungeon_text:get_tower_text(18)};
                true -> 
					check_tower_condition(T, LeaderScene)
            end;
		_ -> check_tower_condition(T, LeaderScene)
    end.

check_team_condition(Status, Dun, TowerSceneId, AddCount) -> 
    if
        is_pid(Status#player_status.pid_team) == false -> {false, data_dungeon_text:get_tower_text(13)};
        Status#player_status.leader /= 1 -> {false, data_dungeon_text:get_tower_text(12)};
        true -> 
            case lib_team:get_mb_num(Status#player_status.pid_team) =< 3 of
                false -> {false, data_dungeon_text:get_tower_text(11)};
                true -> 
                    MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),													
                    NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
                    case check_tower_condition(NewMemberIdList, Status#player_status.scene) of
                        {false, Reason1} -> {false, Reason1};
                        true ->
                            FunCheckCount = fun(PlayerId) ->
                                    if PlayerId =:= Status#player_status.id ->
                                            mod_daily:get_count(Status#player_status.dailypid,
                                                Status#player_status.id,
                                                TowerSceneId) + AddCount > Dun#dungeon.count;
                                        true ->
                                            case lib_player:get_player_info(PlayerId, dailypid) of
                                                false -> false;
                                                DailyPid ->
                                                    mod_daily:get_count(DailyPid, PlayerId, 
                                                        TowerSceneId) + AddCount > Dun#dungeon.count
                                            end
                                    end
                            end,
                            MCL = [FunCheckCount(MbId) || MbId <- NewMemberIdList],
                            case lists:member(true, MCL) of
                                true ->
                                    {false, data_dungeon_text:get_tower_text(3)};
                                false ->
                                    true
                            end
                    end
            end
    end.
