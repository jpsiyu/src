%%------------------------------------------------------------------------------
%% @Module  : mod_coin_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.4.25
%% @Description: 铜币副本服务
%%------------------------------------------------------------------------------

-module(mod_coin_dungeon).
-export([handle_cast/2, 
        handle_info/2,
        kill_npc/4,
        combo_buff_online/2
    ]).

-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").

%% --------------------------------- 公共函数 ----------------------------------

%% 杀怪事件.
kill_npc(State, _Scene, _SceneResId, [NpcId|_]) ->	

    %1.得到铜币副本状态.
    CoinDun = State#dungeon_state.coin_dun,
    #coin_dun{
        %mon_level           = MonLevel,
        %boss_level          = BossLevel, 
        %last_kill_time      = LastKillTime, 
        combo               = Combo, 
        max_combo           = MaxCombo, 
        kill_mon            = KillMon, 
        kill_boss           = KillBoss,
        coin                = Coin, 
        bcoin               = BCoin, 
        total_send_coin     = TotalSendCoin, 
        total_send_bcoin    = TotalSendBCoin, 
        kill_boss_lim_timer = OldKillBossLimTimer,
        dun_end_time        = DunEndTime,
        step                = OldStep
    } = CoinDun,

    %3.处理杀怪事件.
    case lists:keyfind(NpcId, 3, ?COIN_DUN_LEVEL_LIST) of

        %1.处理boss怪的杀死事件.
        {_BossLevel, _MonId, _BossId} ->

            %1.取消定时器.
            util:cancel_timer(OldKillBossLimTimer),

            %计算连斩.
            NewCombo = Combo + 1,
            NewMaxCombo = max(NewCombo, MaxCombo),

            %摇奖.
            CoinNum = data_coin_dungeon:lottery_config(),
            CoinValue = data_coin_dungeon:get_coin_value(),
            LotteryTime = data_coin_dungeon:get_lottery_time(),

            %告诉客户端.
            {ok, BinData1} = pt_610:write(61051, CoinNum*CoinValue),
            {ok, BinData2} = pt_610:write(61057, [LotteryTime, ?LOTTERY_STEP]),
            Fun = fun(PlayerId, PlayerPid) ->
                    %通知副本抽奖.
                    lib_server_send:send_to_uid(PlayerId, BinData1),
                    lib_server_send:send_to_uid(PlayerId, BinData2),

                    send_coin_dungeon_state(PlayerId, Coin, KillBoss+1, KillMon, NewCombo, BCoin, NewMaxCombo, ?LOTTERY_STEP, LotteryTime),
                    %到达一定连斩数释放一个buff.
                    combo_buff(PlayerPid, NewCombo, NewMaxCombo),
                    set_ets(PlayerId, NewCombo, NewMaxCombo, Coin, BCoin, 
                        TotalSendCoin, TotalSendBCoin)
            end,
            [Fun(X#dungeon_player.id, X#dungeon_player.pid)||X<-State#dungeon_state.role_list],
            NewCoinDun = CoinDun#coin_dun{coin_num = CoinNum, 
                combo = NewCombo, 
                max_combo = NewMaxCombo, 
                last_kill_time = 0, 
                kill_boss = KillBoss+1, 
                is_can_next = 1,
                step = ?LOTTERY_STEP,
                dun_end_time = util:unixtime() + LotteryTime
            },
            State#dungeon_state{coin_dun = NewCoinDun, close_timer=[]};

        %2.处理小怪的杀死事件.
        false ->
            case lists:member(NpcId, ?COIN_DUN_MON_LIST) of
                true ->
                    %1.计算连斩.
                    NewCombo = Combo + 1,
                    %2.计算最大连斩.
                    NewMaxCombo = case NewCombo > MaxCombo of
                        true ->  NewCombo;
                        false -> MaxCombo
                    end,
                    MonValue = data_coin_dungeon:mon_value(),
                    NewCoin = Coin + MonValue,

                    %% 剩余时间
                    Now = util:unixtime(),
                    LeftTime = max(0, DunEndTime-Now),

                    Fun2 = fun(PlayerId, PlayerPid) ->
                            %1.马上发送绑定铜币给玩家.
                            gen_server:cast(PlayerPid, {'coin_dungeon_reward_coin', MonValue}),
                            send_coin_dungeon_state(PlayerId, NewCoin, KillBoss, KillMon+1, 
                                NewCombo, BCoin, NewMaxCombo, OldStep, LeftTime),
                            %到达一定连斩数释放一个buff.
                            combo_buff(PlayerPid, NewCombo, NewMaxCombo),
                            %ets记录.
                            set_ets(PlayerId, NewCombo, NewMaxCombo, NewCoin, BCoin,
                                TotalSendCoin, TotalSendBCoin)
                    end,
                    [Fun2(X#dungeon_player.id, X#dungeon_player.pid)||X<-State#dungeon_state.role_list],
                    NewCoinDun = CoinDun#coin_dun{last_kill_time = Now, combo = NewCombo, 
                        max_combo = NewMaxCombo, 
                        kill_mon = KillMon + 1, coin = NewCoin},
                    State#dungeon_state{coin_dun = NewCoinDun};
                false ->
                    State
            end
    end.


%% --------------------------------- 内部函数 ----------------------------------

%% 获取新版钱多多副本副本信息
handle_cast({'coin_dungeon_state', Uid}, State) ->
    case State#dungeon_state.coin_dun of
        [] -> {noreply, State};
        #coin_dun{coin = Coin, bcoin=BCoin, kill_mon = KillMon, kill_boss = KillBoss, coin_num = CoinNum,
            combo=Combo, max_combo = MaxCombo, step = OldStep, dun_end_time=DunEndTime} = _CoinDun ->
            %% 剩余时间
            Now = util:unixtime(),
            LeftTime = max(0, DunEndTime-Now),
            send_coin_dungeon_state(Uid, Coin, KillBoss, KillMon, Combo, BCoin, MaxCombo, OldStep, LeftTime),
            %% 如果是摇奖阶段，重新告诉客户端摇奖的数量
            case OldStep == ?LOTTERY_STEP of
                true ->
                    CoinValue = data_coin_dungeon:get_coin_value(), 
                    {ok, BinData} = pt_610:write(61051, CoinNum*CoinValue),
                    lib_server_send:send_to_uid(Uid, BinData);
                false -> skip
            end,
            {noreply, State}
    end.

%% 刷新一批金币
handle_info({'coin_create', PlayerId, PlayerPid}, State) ->
    case State#dungeon_state.coin_dun of		
        [] -> 
            {noreply, State};
        #coin_dun{boss_level = _Level, coin_num = CoinNum, coin = Coin, bcoin = BCoin, 
            total_send_coin = TotalSendCoin, total_send_bcoin = TotalSendBCoin, combo=Combo, 
            kill_mon = KillMon, kill_boss=KillBoss, max_combo = MaxCombo, step=OldStep, dun_end_time=DunEndTime,
            kill_boss_lim_timer = KillBossLimTimer} = CoinDun -> 
            case CoinNum == 0 of
                true -> {noreply, State};
                false -> 

                    util:cancel_timer(KillBossLimTimer),

                    %% 改成不捡金币，摇完奖直接给金币
                    CoinValue       = data_coin_dungeon:get_coin_value(),
                    TotalCoinValue  = CoinNum*CoinValue,
                    set_ets(PlayerId, Combo, MaxCombo, Coin, BCoin, TotalSendCoin, TotalSendBCoin),

                    %% 剩余时间
                    Now = util:unixtime(),
                    LeftTime = max(0, DunEndTime-Now),

                    %4.发送钱多多副本状态
                    send_coin_dungeon_state(PlayerId, Coin + TotalCoinValue, KillBoss, KillMon, Combo, BCoin, MaxCombo, OldStep, LeftTime),
                    %5.马上发送金钱给玩家.
                    gen_server:cast(PlayerPid, {'coin_dungeon_reward_coin', TotalCoinValue}),

                    %% 刷新新一波怪物
                    Ref = erlang:send_after(4 * 1000, self(), 'coin_dungeon_next_level'),
                    NewCoinDun = CoinDun#coin_dun{next_level_ref = Ref},
                    {noreply, State#dungeon_state{coin_dun = NewCoinDun}}
            end
    end;

%% 生成下一波怪物
handle_info('coin_dungeon_next_level', State) ->
    case State#dungeon_state.coin_dun of
        [] -> 
            {noreply, State};
        #coin_dun{is_can_next=IsCanNext, next_level_ref = Ref,
            coin = Coin, bcoin = BCoin, coin_num=CoinNum,
            total_send_coin = TotalSendCoin, total_send_bcoin = TotalSendBCoin, 
            combo=Combo, max_combo = MaxCombo} = _CoinDun when IsCanNext == 1 ->
            %关闭下一波定时器定时器.
            util:cancel_timer(Ref),

            %发送奖励.
            Fun2 = fun(PlayerId, PlayerPid) ->						   
                    lib_coin_dungeon:reward_single(PlayerId, PlayerPid, Coin + CoinNum -TotalSendCoin, BCoin-TotalSendBCoin),
                    %ets记录.
                    set_ets(PlayerId, Combo, MaxCombo, Coin, BCoin,
                        TotalSendCoin, TotalSendBCoin)
            end,
            [Fun2(X#dungeon_player.id, X#dungeon_player.pid)||X<-State#dungeon_state.role_list],

            CoinValue       = data_coin_dungeon:get_coin_value(),

            %刷出新的一波boss
            NewState = lib_coin_dungeon:create_boss(State, self()),
            NewCoinDun = NewState#dungeon_state.coin_dun,
            NewCoinDun2 = NewCoinDun#coin_dun{
                coin_num=0,
                coin = Coin + CoinNum * CoinValue,
                is_can_next=0,
                total_send_coin = Coin,
                total_send_bcoin = BCoin},
            {noreply, NewState#dungeon_state{coin_dun = NewCoinDun2}};			
        _ -> 
            {noreply, State}
    end;

%% 刷新怪物.
handle_info('create_boss', State) ->
    #dungeon_state{begin_sid=SceneId, close_timer=_CloseTimer} = State,
    CopyId = self(),
    %% 停止总倒计时
    %util:cancel_timer(CloseTimer),
    %% 清理场景小怪
    MonId = data_coin_dungeon:get_mon_id(),
    lib_mon:clear_scene_mon_by_mids(SceneId, self(), 1, [MonId]),
    NewState = lib_coin_dungeon:create_boss(State, CopyId),
    {noreply, NewState}.

%% --------------------------------- 私有函数 ----------------------------------

%% 发送钱多多副本状态
send_coin_dungeon_state(PlayerId, Coin, KillBoss, KillMon, Combo, BCoin, MaxCombo, Step, LeftTime) ->
    {ok, BinData} = pt_610:write(61050, [Coin, BCoin, KillBoss, KillMon, Combo, MaxCombo, Step, LeftTime]),	
    lib_server_send:send_to_uid(PlayerId, BinData).

%% 连斩buff加成
combo_buff(PlayerPid, Combo, MaxCombo) -> 
    SkillLv = if 
        Combo < MaxCombo -> 0;
        Combo == 20   -> 1;
        Combo == 40   -> 2;
        Combo == 80   -> 3;
        Combo == 100  -> 4;
        Combo == 150  -> 5;
        true -> 0
    end,
    if 
        SkillLv == 0 -> ok;
        true -> 
            gen_server:cast(PlayerPid, {'combo_buff', Combo, MaxCombo, SkillLv})
    end.

%% 连斩buff加成
combo_buff_online(PlayerPid, MaxCombo) -> 
    gen_server:cast(PlayerPid, {'combo_buff_online', MaxCombo}).

%% 设置ets记录
set_ets(PlayerId, Combo, MaxCombo, Coin, BCoin, TotalSendCoin, TotalSendBCoin) ->
    ets:insert(?ETS_COIN_DUNGEON, #ets_coin_dungeon{player_id = PlayerId, 
            combo = Combo, max_combo = MaxCombo, coin = Coin, bcoin = BCoin,
            total_send_coin = TotalSendCoin, total_send_bcoin = TotalSendBCoin}).
