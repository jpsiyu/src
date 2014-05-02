%%%------------------------------------
%%% @Module  : lib_coin_dungeon
%%% @Author  : zzm
%%% @Email   : ming_up@163.com
%%% @Created : 2011.12.26
%%% @Description: 钱多多副本
%%%----------------------------------

-module(lib_coin_dungeon).
-export([create_scene/3,          %% 创建铜币副本场景.
		 create_mon/3,            %% 创建怪物.
		 create_boss/2,           %% 创建Boss.
         is_can_buff/2,           %% 是否能释放.
         reward/2,                %% 发放奖励.
         offline_reward/1,        %% 下线发放奖励.
		 reward_single/4          %% 单次发放奖励.
%%       coin_rank/5,             %% 
%%       coin_rank/7,             %%
    ]).

-include("dungeon.hrl").
-include("record.hrl").
-include("common.hrl").
-include("server.hrl").
-include("sql_rank.hrl").

%% --------------------------------- 公共函数 ----------------------------------
  
%% 创建铜币副本场景
create_scene(SceneId, CopyId, State) ->
    %% 创建场景数据服务.
    mod_scene_agent:apply_call(SceneId, mod_scene, copy_dungeon_scene, 
        [SceneId, CopyId, State#dungeon_state.level, 0]),
    %% 创建怪物.
    %mod_scene_agent:apply_cast(SceneId, lib_coin_dungeon, create_mon, 
    %    [1, SceneId, CopyId]),


    %% boss创建延迟时间
    The2thDelayTime = data_coin_dungeon:get_2th_dely_time(),
    erlang:send_after(The2thDelayTime * 1000, CopyId, 'create_boss'),
	
	%% 修改副本场景ID.
    ChangeSceneId =  
		fun(DunScene) ->
	        case DunScene#dungeon_scene.sid =:= SceneId of
	            true -> 
					DunScene#dungeon_scene{id = SceneId};
	            false -> 
					DunScene
	        end
    	end,
	
	%% 更新副本状态.
    CoinDun  = State#dungeon_state.coin_dun,
    NewState = State#dungeon_state{
        scene_list = [ChangeSceneId(DunScene)||DunScene<-State#dungeon_state.scene_list],
        coin_dun = CoinDun#coin_dun{dun_end_time = util:unixtime() + The2thDelayTime, step = ?KILL_MON_STEP}
    },
 	{SceneId, NewState}.

%% 创建怪物.
create_mon(Level, Scene, CopyId) ->
    case lists:keyfind(Level, 1, ?COIN_DUN_LEVEL_LIST) of
        false ->
			skip;
        {_Level, NewMonId, _NewBossId} ->
			[mod_mon_create:create_mon(NewMonId, Scene, X, Y, 1, CopyId, 1, [])
				||{X,Y}<-?COIN_DUN_MON_LOCA],
            ok
    end.

%% 创建Boss.
create_boss(State, CopyId) -> 
    #dungeon_state{coin_dun=CoinDun, begin_sid=Scene} = State,
    #coin_dun{boss_level = BossLevel, kill_boss_lim_timer=OldKillBossLimTimer} = CoinDun,

    %% 取消定时器
    util:cancel_timer(OldKillBossLimTimer),

    case lists:keyfind(BossLevel, 1, ?COIN_DUN_LEVEL_LIST) of
        false ->
            %% 自动退出副本
            [lib_dungeon:quit(self(), Role#dungeon_player.id, 4) || Role <- State#dungeon_state.role_list],
            lib_dungeon:clear(role, self()),
            State;
        {_Level, _NewMonId, NewBossId} ->

            %% 创建boss
            lib_mon:async_create_mon(NewBossId, Scene, 13, 28, 1, CopyId, 1, []),

            KillBossLimTime  = data_coin_dungeon:get_kill_boss_lim_time(),
            KillBossLimTimer = erlang:send_after((KillBossLimTime+3)*1000, self(), dungeon_time_end),
            NewCoinDun = CoinDun#coin_dun{
                boss_level=BossLevel+1, 
                kill_boss_lim_timer=KillBossLimTimer,
                dun_end_time = util:unixtime() + KillBossLimTime,
                step = ?KILL_BOSS_STEP
            },

            %% 告诉客户端更新时间
            {ok, BinData} = pt_610:write(61057, [KillBossLimTime, ?KILL_BOSS_STEP]),
            lib_server_send:send_to_scene(Scene, CopyId, BinData),
            State#dungeon_state{coin_dun=NewCoinDun}
    end.
	
%% 是否能释放
is_can_buff(PlayerId, SkillId) -> 
    NeedCombo = case SkillId of
        339000 -> 50;
        _ -> 1000
    end,
    Res = case ets:lookup(?ETS_COIN_DUNGEON, PlayerId) of
        [] -> false;
        [ECD] -> ECD#ets_coin_dungeon.combo >= NeedCombo
    end,
    Res.


%% 发放奖励
reward(PlayerStatus, State) ->
	#coin_dun{
		coin=_Coin, 
		bcoin = _BCoin, 
		max_combo = MaxCombo,
	  	total_send_coin = TotalSendCoin, 
		total_send_bcoin = TotalSendBCoin} = State#dungeon_state.coin_dun,		  
	Coin = _Coin-TotalSendCoin,
	BCoin = _BCoin-TotalSendBCoin,		  
	Id = PlayerStatus#player_status.id, 
	NickName = PlayerStatus#player_status.nickname,	
	Pid = PlayerStatus#player_status.pid,

	if 
		is_pid(Pid) ->
			case ets:lookup(?ETS_COIN_DUNGEON, Id) of
				[] -> skip;
				_ ->

					%发放奖励
					%{ok, BinData} = pt_610:write(61054, [RCoin, RBCoin, KillMon, KillBoss, MaxCombo]),
					%lib_server_send:send_to_uid(Id, BinData),

					gen_server:cast(Pid, {'coin_dungeon_reward', Coin, BCoin}),
					%gen_server:cast(Pid, {'clear_combo_buff'}),
					clear_ets(Id),
					%1.更新铜币副本排行榜.
 					TotalCoin1 = BCoin,
					Sql1 = io_lib:format(?sql_select_rank_coin_dungeon,[Id]),
					Sql2 = io_lib:format(?sql_insert_rank_coin_dungeon,
										 [Id, NickName, MaxCombo, BCoin, TotalCoin1]),			
					TotalCoin2 = db:get_one(Sql1),
					if TotalCoin2 =:= null ->
							catch db:execute(Sql2);
					   true->
							if TotalCoin1 > TotalCoin2 ->
								   catch db:execute(Sql2);
							   true->
								   skip
							end
					end,
					ok
			end;
		  true ->
			skip
	  end.    

%% 下线发放奖励
offline_reward(#player_status{id = Id, nickname = _Name, career = _Career} = Status) ->
    case ets:lookup(?ETS_COIN_DUNGEON, Id) of
        [] -> skip;
        [ECD] -> 
            Ratio = 1 + ECD#ets_coin_dungeon.max_combo/2000,
            RCoin = round(ECD#ets_coin_dungeon.coin * Ratio),
            RBCoin = round(ECD#ets_coin_dungeon.bcoin * Ratio),
			
			%1.不增加铜币，改为发物品
    		PSGo = Status#player_status.goods,
    		gen_server:call(PSGo#status_goods.goods_pid, {'give_goods', Status, 601001, RCoin}),
			
			%2.增加绑定铜币.
            Status2 = lib_player:add_coin(Status, RBCoin),
			log:log_produce(coin_dungeon, coin, Status, Status2, ""),
			
            clear_ets(Id),
            %% 下线发放邮件通知
            lib_mail:send_sys_mail([Id], data_dungeon_text:get_coin_dungeon_text(1), 
				lists:concat([data_dungeon_text:get_coin_dungeon_text(2), 
							  RBCoin, 
							  data_dungeon_text:get_coin_dungeon_text(3), 
							  RCoin, 
							  data_dungeon_text:get_coin_dungeon_text(4)])),
            %%mod_disperse:rpc_to_unite(lib_coin_dungeon, coin_rank, 
			%%   [Id, Name, Career, RCoin, RBCoin, ECD#ets_coin_dungeon.max_combo, RCoin+RBCoin]),
            ok 
    end.

%% 清除ets记录
clear_ets(PlayerId) ->
    ets:delete(?ETS_COIN_DUNGEON, PlayerId).

%% 单次发放奖励
reward_single(Id, Pid, Coin, BCoin) when is_pid(Pid)->
    case ets:lookup(?ETS_COIN_DUNGEON, Id) of
        [] -> skip;
        _ ->
			gen_server:cast(Pid, {'coin_dungeon_reward', Coin, BCoin})
    end.
