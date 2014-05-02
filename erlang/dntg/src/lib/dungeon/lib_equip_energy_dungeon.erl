-module(lib_equip_energy_dungeon).

-include("dungeon.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("sql_dungeon.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-export([online/1,
		 get_equip_energy_list_cast/1,
         get_equip_energy_list_call/1,
         kill_npc/4,
         kill_boss/3,
         extraction_goods/3,
         send_equip_fail_result/3,
         get_equip_energy_state/0,
         save_equip_energy_state/1,
         send_pass_goods/7,
         send_good_mail/5,
         get_rgift_goodid/2,
         get_rgift_goodid/1,
         caculate_npc/1,
         get_one_dun_log_record/3,
         goods_add_and_get_coin/4,
         rotary_gift_rmove_rate/1,
         rotary_gift_to_bin_list/1]).


%% cast获取装备副本列表
get_equip_energy_list_cast(RoleId)->
	EquipList = case get(?DUNGEON_EQUIP_LOG_KEY(RoleId)) of
        			undefined ->
            			lib_equip_energy_dungeon:online(RoleId);
						%% get(?DUNGEON_EQUIP_LOG_KEY(RoleId));
        			EquipLog -> EquipLog
    			end,
    mod_disperse:cast_to_unite(lib_equip_master, get_equip_list, [RoleId, EquipList]).

%% call获取装备副本列表
get_equip_energy_list_call(RoleId)->
    case get(?DUNGEON_EQUIP_LOG_KEY(RoleId)) of
        undefined ->
            lib_equip_energy_dungeon:online(RoleId);
            %% get(?DUNGEON_EQUIP_LOG_KEY(RoleId));
        EquipLog -> EquipLog
    end.

%% 杀怪事件处理->通关处理
kill_npc([MonId|_], _MonAutoId, _EventSceneId, State) ->
    NowTime = util:unixtime(),
    [{PlayerId, PlayerPid, DungeonDataPid}|_] = [{Role#dungeon_player.id, 
                                                   Role#dungeon_player.pid, 
                                                   Role#dungeon_player.dungeon_data_pid} || Role <- State#dungeon_state.role_list],
    EquipDunState = get_equip_energy_state(),    
    NpcList = EquipDunState#dntk_equip_dun_state.npc_list,
    NpcCount = EquipDunState#dntk_equip_dun_state.npc_count,
    case lists:member(MonId, NpcList) of
        false -> State;
        _   ->
            DunId = EquipDunState#dntk_equip_dun_state.dun_id,
            BossList = data_equip_energy:get_config(boss_list),
            IsBoss = lists:member(MonId, BossList),
            IsKillBoss = mod_dungeon_data:get_equip_energy_is_gift(DungeonDataPid, PlayerId, DunId),
            if
                IsBoss =:= true andalso IsKillBoss=:=0 ->
                    kill_boss(DunId, 1, State);
                true ->
                    skip
            end,
            Mon = data_mon:get(MonId),
            EquipDunConfig = data_equip_gift:get_gift(DunId),
            Dun = data_dungeon:get(DunId),
            NowKillCount = EquipDunState#dntk_equip_dun_state.kill_count + 1,
            UsedTime = NowTime - EquipDunState#dntk_equip_dun_state.start_time,
            TotalExp = EquipDunState#dntk_equip_dun_state.total_exp,
            if
                Mon =:= [] -> 
                    save_equip_energy_state([{kill_count, NowKillCount}, {total_exp, TotalExp}]),
                    State;
                EquipDunConfig =:= [] -> 
                    NowTotalExp = TotalExp + Mon#ets_mon.exp,
                    save_equip_energy_state([{kill_count, NowKillCount}, {total_exp, NowTotalExp}]), 
                    State;
                true ->
                    if
                       NowKillCount < NpcCount ->
                            NowTotalExp = TotalExp + Mon#ets_mon.exp,
                            save_equip_energy_state([{kill_count, NowKillCount}, {total_exp, NowTotalExp}]),
                            State;
                       true ->
                           NowTotalExp = TotalExp + Mon#ets_mon.exp,
                           save_equip_energy_state([{kill_count, NowKillCount}, {total_exp, NowTotalExp}]),
                           Level = data_equip_energy:get_record_level(UsedTime, EquipDunConfig#dntk_equip_dun_config.level_condition),
                           EquipDunLogList = mod_dungeon_data:get_equip_energy_list_call(DungeonDataPid, PlayerId),
                           %% util:errlog("~p ~p Call_EquipDunLogList:~p~n", [?MODULE, ?LINE, EquipDunLogList]),
                           EquipOneLog = get_one_dun_log_record(PlayerId, DunId, EquipDunLogList),
                           case EquipOneLog of
                               [] -> State;
                               EquipOneLog ->
                                    %% 判断星级和最佳时间还有是否已经发送礼包
                                    OldLevel = EquipOneLog#dntk_equip_dun_log.level,
                                    OldBestTime = EquipOneLog#dntk_equip_dun_log.best_time,
                                    IsGift = EquipOneLog#dntk_equip_dun_log.gift,
                                    TotalCount = EquipOneLog#dntk_equip_dun_log.total_count,
                                    Name = EquipOneLog#dntk_equip_dun_log.name,
                                    Career = EquipOneLog#dntk_equip_dun_log.career,
                                    Sex = EquipOneLog#dntk_equip_dun_log.sex,
                                    ExCount = EquipDunConfig#dntk_equip_dun_config.extraction_count,
                                    if
                                        IsGift =:= 0 ->
                                            List = updata_player_state_equip(EquipDunLogList, EquipOneLog, Level, 
                                                                             UsedTime, TotalCount+1, 1, NowTime, 
                                                                             PlayerId, DungeonDataPid, DunId, 1),
                                            PGiftInfo= EquipDunConfig#dntk_equip_dun_config.pass_gift,  
                                            Gold = EquipDunConfig#dntk_equip_dun_config.gold,
                                            case pass_goods_solve(Career, PGiftInfo) of
                                                skip -> 
                                                    util:errlog("~p ~p equip_pass_goods_fail!~n", [?MODULE, ?LINE]);
                                                GoodsList ->
                                                    spawn(lib_equip_energy_dungeon, send_pass_goods, [PlayerId, PlayerPid, GoodsList, 0, 0, Dun#dungeon.name, 1])
                                            end,
                                            FRGift = EquipDunConfig#dntk_equip_dun_config.f_rotary_gift,
                                            save_equip_energy_state([{all_goods, FRGift}]),
                                            FRGiftBinList = rotary_gift_to_bin_list(FRGift),
                                            %% {ok, BinData} = pt_611:write(61172, [1, DunId, UsedTime, UsedTime, Level, NowKillCount, NowTotalExp, ExCount, RGiftBinList, 1]),                                            
                                            {ok, BinData} = pt_611:write(61172, [1, DunId, UsedTime, UsedTime, Level, NowKillCount, NowTotalExp, ExCount, FRGiftBinList, 1, Gold]),
                                            lib_server_send:send_to_uid(PlayerId, BinData),
                                            %%　新开启一关主动推
                                            %% mod_disperse:cast_to_unite(lib_equip_master, get_equip_list, [PlayerId, List]),
                                            mod_disperse:cast_to_unite(lib_equip_master, update_get_equip_list, [DunId, PlayerId, UsedTime, List, Name, Career, Sex]),
                                            CloseTimer = waite_for_min(State#dungeon_state.close_timer),
                                            State#dungeon_state{close_timer = CloseTimer};
                                        true ->
                                            if
                                                Level > OldLevel -> NowLevel = Level;
                                                true -> NowLevel = OldLevel
                                            end,
                                            if
                                                UsedTime < OldBestTime -> NowBestTime = UsedTime;
                                                true ->  NowBestTime = OldBestTime
                                            end,
                                            
                                            %% mod_disperse:cast_to_unite(lib_equip_master, update_master, [DunId, PlayerId, NowBestTime]),
                                            
                                            %% 更新内存和数据库
                                            List = updata_player_state_equip(EquipDunLogList, EquipOneLog, NowLevel, NowBestTime, TotalCount+1, 1, NowTime, PlayerId, DungeonDataPid, DunId, 2),
                                            
                                            %% 随机通关物品
                                            SRGift = EquipDunConfig#dntk_equip_dun_config.s_rotary_gift,
                                            RandSRGiftList = rand_rotary_gift(SRGift),
                                            save_equip_energy_state([{all_goods, RandSRGiftList}]),
                                            RGiftBinList = rotary_gift_to_bin_list(RandSRGiftList),
                                            Gold = EquipDunConfig#dntk_equip_dun_config.gold,
                                            {ok, BinData} = pt_611:write(61172, [1, DunId, NowBestTime, UsedTime, Level, NowKillCount, NowTotalExp, ExCount, RGiftBinList, 0, Gold]),
                                            lib_server_send:send_to_uid(PlayerId, BinData),
                                            %%　新开启一关主动推
                                            %% mod_disperse:cast_to_unite(lib_equip_master, get_equip_list, [PlayerId, List]),
                                            mod_disperse:cast_to_unite(lib_equip_master, update_get_equip_list, [DunId, PlayerId, NowBestTime, List, Name, Career, Sex]),
                                            CloseTimer = waite_for_min(State#dungeon_state.close_timer),
                                            State#dungeon_state{close_timer = CloseTimer}
                                    end
                           end
                    end
            end
    end.
        

%%　抽取奖品
extraction_goods(DungeonId, DunId, Type) ->
    case is_pid(DungeonId) of
        true ->
            DungeonId ! {'extraction_goods', DunId, Type};
        false ->
            skip
    end.


%%  退出发送界面数据返回判断
%%  Type：退出类型:超时或者主动退出
send_equip_fail_result(DunState, PlayerState, _Type)->
    RoleId = PlayerState#player_status.id,
    NowTime = util:unixtime(),
    EquipEnergyState = lib_equip_energy_dungeon:get_equip_energy_state(),
    DunId = EquipEnergyState#dntk_equip_dun_state.dun_id,
    Dun = data_dungeon:get(DunId),
    KillCount = EquipEnergyState#dntk_equip_dun_state.kill_count,
    TotalExp = EquipEnergyState#dntk_equip_dun_state.total_exp,
    UsedTime = NowTime - EquipEnergyState#dntk_equip_dun_state.start_time, 
    NpcCount = EquipEnergyState#dntk_equip_dun_state.npc_count,
    EquipDunConfig = data_equip_gift:get_gift(DunId),
    if
        EquipDunConfig =:= [] ->
            DunState;
        DunState#dungeon_state.is_die =:= 1 ->
            skip;   
        true ->  
            if
                KillCount  < NpcCount ->
                    DunDataPid = PlayerState#player_status.pid_dungeon_data,
                    EquipDunLog = mod_dungeon_data:get_equip_energy_list_call(DunDataPid, RoleId),
                    OneEquipDunLog = get_one_dun_log_record(RoleId, DunId, EquipDunLog),
                    
                    case OneEquipDunLog of
                        [] -> DunState;
                        OneEquipDunLog ->
                            TotalCount = OneEquipDunLog#dntk_equip_dun_log.total_count,
                            %% 更新内存
                            NewOneEquipDunLog = OneEquipDunLog#dntk_equip_dun_log{total_count = TotalCount+1, time = NowTime},
                            NewEquipDunLog = lists:keydelete(NewOneEquipDunLog#dntk_equip_dun_log.id, #dntk_equip_dun_log.id, EquipDunLog) ++ [NewOneEquipDunLog],
                            mod_dungeon_data:set_equip_energy_list(DunDataPid, RoleId, NewEquipDunLog),
                            %% 更新数据库
                            UpSQL = io_lib:format(?sql_update_equip_log_fail_id, [TotalCount+1, NowTime, RoleId, DunId]),
                            db:execute(UpSQL),
                            %% 发送失败数据
                            {ok, BinData} = pt_610:write(61006, [DunId, 10, 0, UsedTime, 0, KillCount, TotalExp, 0, 0]),
                            lib_server_send:send_to_uid(RoleId, BinData),
                            DunState
                    end;
                true ->
                    ChouQuNum = EquipEnergyState#dntk_equip_dun_state.extract_count,
                    Goods = EquipEnergyState#dntk_equip_dun_state.goods,
                    if
                        ChouQuNum =:= 0 andalso Goods =:= [] ->
                            %% 随机通关物品
                            RotaryGift = EquipEnergyState#dntk_equip_dun_state.all_goods,
                            [{{GId, GNum}, _GRate}] = get_rgift_goodid(RotaryGift),
                            %% {GoodsList, TotalCoin} = goods_add_and_get_coin([{GId, GNum}], [], 0, 0),
                            {GoodsList, TotalCoin, TotalBGold} = goods_add_and_get_coin([{GId, GNum}], [], 0, 0),
                            spawn(lib_equip_energy_dungeon, send_pass_goods, 
                                  [RoleId, PlayerState#player_status.pid, GoodsList, TotalCoin, TotalBGold, Dun#dungeon.name, 2]),
                            DunState;
                        true ->
                            DunState 
                    end

            end
    end.

%% 玩家通关的装备副本信息，加载到内存
online(RoleId)->
    SeSQL = io_lib:format(?sql_select_equip_dungeon_log, [RoleId]),
    PlayerAllOpenEnergyDun = db:get_all(SeSQL),
    AllOpenEnergyDunList = 
        case PlayerAllOpenEnergyDun of
            [] -> 
                %% 初始化第一个装备副本信息(写死)
                FDunId = data_equip_energy:get_config(first_dunid),
                Dun = data_dungeon:get(FDunId),
                if
                    Dun =:= [] -> skip;
                    true ->
                         PlayerInfo = lib_player:get_player_info(RoleId, name_career_sex),
                         if
                            PlayerInfo =:= false -> [Name, Career, Sex] =  ["", 0, 0];
                            true -> [Name, Career, Sex] =  PlayerInfo
                        end,
                        DunId = Dun#dungeon.id,
                        NowTime = util:unixtime(),
                        InSQL = io_lib:format(?sql_insert_equip_dungeon_log, [RoleId, DunId, 1, 0, 0, 0, 1, 0, NowTime, Name, Career, Sex, 0]),
                        db:execute(InSQL),
                        [[RoleId, DunId, 1, 0, 0, 0, 1, 0, NowTime, Name, Career, Sex, 0]]
                end;
           PlayerAllOpenEnergyDun ->
                PlayerAllOpenEnergyDun
        end,
    L = lists:map(fun(DunLog)-> 
                      [RoleId, DungeonId, SortId, TotalCount, Level, BestTime, IsOpen, IsGift, Time, Name1, Career1, Sex1, IsKillBoss] = DunLog,
                      #dntk_equip_dun_log{id = {RoleId, DungeonId}, sort_id = SortId, total_count = TotalCount, 
                                          level = Level, best_time = BestTime, is_opne = IsOpen, gift = IsGift, time = Time,
                                          name = Name1, career = Career1, sex = Sex1, is_kill_boss = IsKillBoss}
              end, AllOpenEnergyDunList),
    put(?DUNGEON_EQUIP_LOG_KEY(RoleId), L),
    L.

%% 获取单个副本的日志记录    
get_one_dun_log_record(PlayerId, DunId, EquipEnergyDunLogList)->
    case lists:keyfind({PlayerId, DunId}, #dntk_equip_dun_log.id, EquipEnergyDunLogList) of
        false ->  
            EquipEnergyDunLogList1 = online(PlayerId),
            case lists:keyfind({PlayerId, DunId}, #dntk_equip_dun_log.id, EquipEnergyDunLogList1) of
                false ->  [];
                Tuple1 -> Tuple1
            end;
        Tuple ->  Tuple
    end.


%% 更新内存和数据库信息或者新开启一个新的副本
updata_player_state_equip(EquipLogList, EquipLog, NowLevel, NowBestTime, TotalCount, IsGift, NowTime, PlayerId, DungeonDataPid, DunId, _Type) ->
    %% 更新内存
    NewEquipLog = EquipLog#dntk_equip_dun_log{level=NowLevel,best_time=NowBestTime,total_count=TotalCount,gift=IsGift, time=NowTime},
    NewEquipLogList = lists:keydelete(NewEquipLog#dntk_equip_dun_log.id, #dntk_equip_dun_log.id, EquipLogList) ++ [NewEquipLog],
    
    %% 更新当前副本的数据库数据
    UpSQL = io_lib:format(?sql_update_equip_log_by_id, [NowLevel, NowBestTime, TotalCount, IsGift, NowTime, PlayerId, DunId]),
    db:execute(UpSQL),
    
    NextSortId = NewEquipLog#dntk_equip_dun_log.sort_id + 1,
    NextDunId = data_equip_energy:get_dunid_by_sort_id(NextSortId),
    IsEquipDun = data_equip_energy:is_equip_dun(NextDunId),
    SeSQL = io_lib:format(?sql_select_equip_dungeon_log_by_id, [PlayerId, NextDunId]),
    NextDun = db:get_all(SeSQL),
    if
        NextDun =:= [] andalso IsEquipDun -> 
            if
                NewEquipLog#dntk_equip_dun_log.career =:= 0 orelse NewEquipLog#dntk_equip_dun_log.sex =:= 0 ->
                    PlayerInfo = lib_player:get_player_info(PlayerId, name_career_sex),
                    if
                        PlayerInfo =:= false -> [Name, Career, Sex] =  ["", 0, 0];
                        true -> [Name, Career, Sex] =  PlayerInfo
                    end,
                    UpSQL1 = io_lib:format(?sql_update_equip_playerinfo_by_id, [Name, Career, Sex, PlayerId, DunId]),
                    db:execute(UpSQL1),
                    InSQL = io_lib:format(?sql_insert_equip_dungeon_log, 
                                          [PlayerId, NextDunId, NextSortId, 0, 0, 0, 1, 0, util:unixtime(),Name, Career, Sex, 0]),
                    NextEquipLog = #dntk_equip_dun_log{id = {PlayerId, NextDunId}, sort_id = NextSortId, level = 0, best_time = 0, 
                                                       total_count = 0, gift = 0, is_opne = 1, time = util:unixtime(), 
                                                       name = Name, career = Career, sex = Sex, is_kill_boss = 0};
                true -> 
                    InSQL = io_lib:format(?sql_insert_equip_dungeon_log, 
                                          [PlayerId, NextDunId, NextSortId, 0, 0, 0, 1, 0, util:unixtime(), 
                                           NewEquipLog#dntk_equip_dun_log.name, NewEquipLog#dntk_equip_dun_log.career, 
                                           NewEquipLog#dntk_equip_dun_log.sex, 0]),
                    NextEquipLog = #dntk_equip_dun_log{id = {PlayerId, NextDunId}, sort_id = NextSortId, level = 0, best_time = 0, 
                                                       total_count = 0, gift = 0, is_opne = 1, time = util:unixtime(), 
                                                       name = NewEquipLog#dntk_equip_dun_log.name, 
                                                       career = NewEquipLog#dntk_equip_dun_log.career,
                                                       sex = NewEquipLog#dntk_equip_dun_log.sex, is_kill_boss = 0}
            end,
            db:execute(InSQL),
            
            NewEquipLogList1 =  NewEquipLogList ++ [NextEquipLog],
            mod_dungeon_data:set_equip_energy_list(DungeonDataPid, PlayerId, NewEquipLogList1),
            NewEquipLogList1;
        true ->
            mod_dungeon_data:set_equip_energy_list(DungeonDataPid, PlayerId, NewEquipLogList),
            NewEquipLogList
    end.
            
            
%%     %%　判断是新增还是更新数据库
%%     if
%%         Type =:= 1 ->   %%通关,开启下一关
%%             %% 更新当前副本的记录
%%             UpSQL = io_lib:format(?sql_update_equip_log_by_id, [NowLevel, NowBestTime, TotalCount, IsGift, NowTime, PlayerId, DunId]),
%%             db:execute(UpSQL),
%%             NextSortId = NewEquipLog#dntk_equip_dun_log.sort_id + 1,
%%             NextDunId = data_equip_energy:get_dunid_by_sort_id(NextSortId),
%%             IsEquipDun = data_equip_energy:is_equip_dun(NextDunId),
%%             SeSQL = io_lib:format(?sql_select_equip_dungeon_log_by_id, [PlayerId, NextDunId]),
%%             NextDun = db:get_all(SeSQL),
%%             if
%%                 NextDun =:= [] andalso IsEquipDun -> 
%%                     if
%%                         NewEquipLog#dntk_equip_dun_log.career =:= 0 orelse NewEquipLog#dntk_equip_dun_log.sex =:= 0 ->
%%                             PlayerInfo = lib_player:get_player_info(PlayerId, name_career_sex),
%%                             if
%%                                 PlayerInfo =:= false -> [Name, Career, Sex] =  ["", 0, 0];
%%                                 true -> [Name, Career, Sex] =  PlayerInfo
%%                             end,
%%                             UpSQL1 = io_lib:format(?sql_update_equip_playerinfo_by_id, [Name, Career, Sex, PlayerId, DunId]),
%%                             db:execute(UpSQL1),
%%                             InSQL = io_lib:format(?sql_insert_equip_dungeon_log, 
%%                                                   [PlayerId, NextDunId, NextSortId, 0, 0, 0, 1, 0, util:unixtime(),Name, Career, Sex, 0]),
%%                             NextEquipLog = #dntk_equip_dun_log{id = {PlayerId, NextDunId}, sort_id = NextSortId, level = 0, best_time = 0, 
%%                                                                total_count = 0, gift = 0, is_opne = 1, time = util:unixtime(), 
%%                                                                name = Name, career = Career, sex = Sex, is_kill_boss = 0};
%%                         true -> 
%%                             InSQL = io_lib:format(?sql_insert_equip_dungeon_log, 
%%                                                   [PlayerId, NextDunId, NextSortId, 0, 0, 0, 1, 0, util:unixtime(), 
%%                                                    NewEquipLog#dntk_equip_dun_log.name, NewEquipLog#dntk_equip_dun_log.career, 
%%                                                    NewEquipLog#dntk_equip_dun_log.sex, 0]),
%%                             NextEquipLog = #dntk_equip_dun_log{id = {PlayerId, NextDunId}, sort_id = NextSortId, level = 0, best_time = 0, 
%%                                                                total_count = 0, gift = 0, is_opne = 1, time = util:unixtime(), 
%%                                                                name = NewEquipLog#dntk_equip_dun_log.name, 
%%                                                                career = NewEquipLog#dntk_equip_dun_log.career,
%%                                                                sex = NewEquipLog#dntk_equip_dun_log.sex, is_kill_boss = 0}
%%                     end,
%%                     db:execute(InSQL),
%%                     
%%                     NewEquipLogList1 =  NewEquipLogList ++ [NextEquipLog],
%%                     mod_dungeon_data:set_equip_energy_list(DungeonDataPid, PlayerId, NewEquipLogList1),
%%                     NewEquipLogList1;
%%                 true ->
%%                     mod_dungeon_data:set_equip_energy_list(DungeonDataPid, PlayerId, NewEquipLogList),
%%                     NewEquipLogList
%%             end;
%%         Type =:= 2 -> %% 更新通关时间和记录
%%             NextSortId = NewEquipLog#dntk_equip_dun_log.sort_id + 1,
%%             NextDunId = data_equip_energy:get_dunid_by_sort_id(NextSortId),
%%             IsEquipDun = data_equip_energy:is_equip_dun(NextDunId),
%%             SeSQL = io_lib:format(?sql_select_equip_dungeon_log_by_id, [PlayerId, NextDunId]),
%%             NextDun = db:get_all(SeSQL),
%%             if
%%                 NextDun =:= [] andalso IsEquipDun -> 
%%                     if
%%                         NewEquipLog#dntk_equip_dun_log.career =:= 0 orelse NewEquipLog#dntk_equip_dun_log.sex =:= 0 ->
%%                             PlayerInfo = lib_player:get_player_info(PlayerId, name_career_sex),
%%                             if
%%                                 PlayerInfo =:= false -> [Name, Career, Sex] =  ["", 0, 0];
%%                                 true -> [Name, Career, Sex] =  PlayerInfo
%%                             end,
%%                             UpSQL1 = io_lib:format(?sql_update_equip_playerinfo_by_id, [Name, Career, Sex, PlayerId, DunId]),
%%                             db:execute(UpSQL1),
%%                             InSQL = io_lib:format(?sql_insert_equip_dungeon_log, 
%%                                                   [PlayerId, NextDunId, NextSortId, 0, 0, 0, 1, 0, util:unixtime(),Name, Career, Sex, 0]),
%%                             NextEquipLog = #dntk_equip_dun_log{id = {PlayerId, NextDunId}, sort_id = NextSortId, level = 0, best_time = 0, 
%%                                                                total_count = 0, gift = 0, is_opne = 1, time = util:unixtime(), 
%%                                                                name = Name, career = Career, sex = Sex, is_kill_boss = 0};
%%                         true -> 
%%                             InSQL = io_lib:format(?sql_insert_equip_dungeon_log, 
%%                                                   [PlayerId, NextDunId, NextSortId, 0, 0, 0, 1, 0, util:unixtime(), 
%%                                                    NewEquipLog#dntk_equip_dun_log.name, NewEquipLog#dntk_equip_dun_log.career, 
%%                                                    NewEquipLog#dntk_equip_dun_log.sex, 0]),
%%                             NextEquipLog = #dntk_equip_dun_log{id = {PlayerId, NextDunId}, sort_id = NextSortId, level = 0, best_time = 0, 
%%                                                                total_count = 0, gift = 0, is_opne = 1, time = util:unixtime(), 
%%                                                                name = NewEquipLog#dntk_equip_dun_log.name, 
%%                                                                career = NewEquipLog#dntk_equip_dun_log.career,
%%                                                                sex = NewEquipLog#dntk_equip_dun_log.sex, is_kill_boss = 0}
%%                     end,
%%                     db:execute(InSQL),
%%                     NewEquipLogList1 =  NewEquipLogList ++ [NextEquipLog],
%%                     mod_dungeon_data:set_equip_energy_list(DungeonDataPid, PlayerId, NewEquipLogList1),
%%                     NewEquipLogList1;
%%                 true ->
%%                     if
%%                         NewEquipLog#dntk_equip_dun_log.career =:= 0 orelse NewEquipLog#dntk_equip_dun_log.sex =:= 0 ->
%%                             PlayerInfo = lib_player:get_player_info(PlayerId, name_career_sex),
%%                             if
%%                                 PlayerInfo =:= false -> [Name, Career, Sex] =  ["", 0, 0];
%%                                 true -> [Name, Career, Sex] =  PlayerInfo
%%                             end,
%%                             NewEquipLog1 = NewEquipLog#dntk_equip_dun_log{name=Name,career=Career,sex=Sex},
%%                             NewEquipLogList1 = lists:keydelete(NewEquipLog1#dntk_equip_dun_log.id, #dntk_equip_dun_log.id, NewEquipLogList) ++ [NewEquipLog1];
%%                         true ->
%%                             NewEquipLogList1 = NewEquipLogList
%%                     end,
%%                     
%%                     UpSQL = io_lib:format(?sql_update_equip_log_by_id, [NowLevel, NowBestTime, TotalCount, IsGift, NowTime, PlayerId, DunId]),
%%                     db:execute(UpSQL),
%%                     mod_dungeon_data:set_equip_energy_list(DungeonDataPid, PlayerId, NewEquipLogList1),
%%                     NewEquipLogList1
%%             end
%%     end.
    
%% 击杀boss添加击杀boss记录
kill_boss(DunId, IsKillBoss, State)->
    NowTime = util:unixtime(),
    [{PlayerId, _PlayerPid, DungeonDataPid}|_] = [{Role#dungeon_player.id, 
                                                   Role#dungeon_player.pid, 
                                                   Role#dungeon_player.dungeon_data_pid} || Role <- State#dungeon_state.role_list],
    
    EquipLogList = mod_dungeon_data:get_equip_energy_list_call(DungeonDataPid, PlayerId),
    EquipOneLog = get_one_dun_log_record(PlayerId, DunId, EquipLogList),
    case EquipOneLog of
        [] -> skip;
        EquipOneLog ->
            NewEquipLog = EquipOneLog#dntk_equip_dun_log{is_kill_boss = IsKillBoss, time = NowTime},
            NewEquipLogList = lists:keydelete(NewEquipLog#dntk_equip_dun_log.id, #dntk_equip_dun_log.id, EquipLogList) ++ [NewEquipLog],
            UpSQL = io_lib:format(?sql_update_equip_kill_boss, [IsKillBoss, NowTime, PlayerId, DunId]),
            db:execute(UpSQL),
            mod_dungeon_data:set_equip_energy_list(DungeonDataPid, PlayerId, NewEquipLogList)
    end.
  
%% 获取副本状态
get_equip_energy_state()->
    case get("equip_energy_dun_state") of
        undefined ->
            FlyDunState = #dntk_equip_dun_state{},
            put("equip_energy_dun_state", FlyDunState),
            get("equip_energy_dun_state");
        State -> 
            State
    end.
         
%% 保存副本状态
set_equip_energy_state(EquipEnergyState)->
    put("equip_energy_dun_state", EquipEnergyState).

%% 保存副本状态数据
save_equip_energy_state([])->skip;
save_equip_energy_state([SaveData|TailSaveData])->
    {KeyType, Value} = SaveData,
    EquipEnergyState = get_equip_energy_state(),
    EquipEnergyState2 = 
        case KeyType of
            equip_dun_pid -> EquipEnergyState#dntk_equip_dun_state{equip_dun_pid = Value};
            dun_id -> EquipEnergyState#dntk_equip_dun_state{dun_id = Value};
            start_time -> EquipEnergyState#dntk_equip_dun_state{start_time = Value};
            end_time -> EquipEnergyState#dntk_equip_dun_state{end_time = Value};
            kill_count -> 
                EquipEnergyState#dntk_equip_dun_state{kill_count = Value};
            total_exp -> 
                EquipEnergyState#dntk_equip_dun_state{total_exp = Value};
            npc_list -> 
                EquipEnergyState#dntk_equip_dun_state{npc_list = Value};
            npc_count ->
                EquipEnergyState#dntk_equip_dun_state{npc_count = Value};
            extract_count -> 
                EquipEnergyState#dntk_equip_dun_state{extract_count = Value};
            goods ->
                EquipEnergyState#dntk_equip_dun_state{goods = Value};
            all_goods ->
                EquipEnergyState#dntk_equip_dun_state{all_goods = Value};
            _ -> EquipEnergyState
        end,
    set_equip_energy_state(EquipEnergyState2),
    save_equip_energy_state(TailSaveData).

%%　将转盘数据打包成二进制列表
rotary_gift_to_bin_list(RotaryGiftList) ->
    lists:map(fun({{GoodId, Num}, _Rate}) -> <<GoodId:32, Num:8>> end, RotaryGiftList).

%% 将转盘数据去到概率
rotary_gift_rmove_rate(RotaryGiftList)->
    lists:map(fun({{GoodsId, Num}, _Rate}) -> {GoodsId, Num} end, RotaryGiftList).


%% 通关和抽取奖励
%% Type:1:通关,2:抽取
send_pass_goods(PlayerId, PlayerPid, GoodsList, TotalCoin, TotalBGold, DunName, Type) -> 
    case is_pid(PlayerPid) andalso misc:is_process_alive(PlayerPid) of
        true ->
            gen_server:cast(PlayerPid, {'equip_give_goods', GoodsList, TotalCoin, TotalBGold, DunName, Type});
        _ ->
            Pid = misc:get_player_process(PlayerId),
            case misc:is_process_alive(Pid) of
                true ->
                    gen_server:cast(Pid, {'equip_give_goods', GoodsList, TotalCoin, TotalBGold, DunName, Type});
                _ ->
                    util:errlog("equip send pass goods fail,goods_pid is not a alive!~n", []),
                    skip
            end
    end.


%% 发送物品邮件(背包不够空间才会调用)
send_good_mail(PlayerId, Title, Content, GoodId, Num) -> 
    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PlayerId], Title, Content, GoodId, 2, 0, 0, Num, 0, 0, 0, 0]).

    
%% 获取相应概率抽奖的物品
get_rgift_goodid([], _Rand)->    
    [];
get_rgift_goodid([H|T], Rand)->
    {_GoodsId, _Num, Rate} = H,
    case Rand < Rate of
        true ->  [H];
        false -> get_rgift_goodid(T, Rand)
    end. 
    

get_rgift_goodid(SRGift)->
    TotalRatio = lib_goods_util:get_ratio_total(SRGift, 2),
    Rand = util:rand(1, TotalRatio),
    case lib_goods_util:find_ratio(SRGift, 0, Rand, 2) of
        null -> 
            %% io:format("~p ~p find_ratio!!!~n", [?MODULE, ?LINE]),
            data_equip_energy:get_config(goods);
        GoodsInfo -> 
            [GoodsInfo]
    end.


%% 计算怪物的数量和怪物的列表id
caculate_npc(MonList) ->
    NpcCount = length(MonList),
    L = lists:map(fun(MList) -> [ModId,_X,_Y,_Z,_W]=MList, ModId end, MonList),
    [MonL1, _L] = lists:foldl(fun(X, [TempList, [X|CompareList]]) ->
                            case lists:member(X, CompareList) of
                                true -> [TempList, CompareList];
                                false -> [[X|TempList], CompareList]
                            end
                           end, [[], L], L),
    {MonL1, NpcCount}.


%% 将同类型的物品数量累加起来和区别铜钱计算铜钱总数
goods_add_and_get_coin([], TempGoodList, TempCoin, TempBGold) ->
    {TempGoodList, TempCoin, TempBGold};
goods_add_and_get_coin([{GoodId, Num}|T], TempGoodList, TempCoin, TempBGold) ->
    CoinKaList = data_equip_energy:get_config(coin_ka),
    BGoldKaList = data_equip_energy:get_config(bgold_ka),
    case lists:keyfind(GoodId, 1, TempGoodList) of
        false ->
            case lists:member(GoodId, CoinKaList) of
                true ->
                    CoinValue = data_equip_energy:get_coin_num(GoodId),
                    NewTempCoin = Num*CoinValue + TempCoin,
                    goods_add_and_get_coin(T, TempGoodList, NewTempCoin, TempBGold);
                _ ->
                    case lists:member(GoodId, BGoldKaList) of
                        true ->
                            BGoldValue = data_equip_energy:get_bglod_num(GoodId),
                            NewTempBGold = Num*BGoldValue + TempBGold,
                            goods_add_and_get_coin(T, TempGoodList, TempCoin, NewTempBGold);
                        _ ->
                            NewTempGoodList = lists:keydelete(GoodId, 1, TempGoodList),
                            goods_add_and_get_coin(T, [{goods, GoodId, Num, 2}|NewTempGoodList], TempCoin, TempBGold)
                    end
            end;
        {GoodId, Num1} ->
            NewTempGoodList = lists:keydelete(GoodId, 1, TempGoodList),
            goods_add_and_get_coin(T, [{goods, GoodId, Num+Num1, 2}|NewTempGoodList], TempCoin, TempBGold)
    end.

            
%% 处理通关物品
pass_goods_solve(Career, PassGiftInfo)->
    case PassGiftInfo of
        [{GoodId1, Num1}] -> [{goods, GoodId1, Num1, 2}];
        PassGiftInfo -> 
            case lists:keyfind(Career, 1, PassGiftInfo) of
                false -> skip;
                {_Career, GoodId, Num} -> [{goods, GoodId, Num, 2}]
            end
    end.

rand_rotary_gift(SRGift)->
    if
        SRGift =:= [] ->
            %% util:errlog("~p ~p equip_gift_config_error!~n", [?MODULE, ?LINE]),
            data_equip_energy:get_config(goods_list);
        true ->
            rand_rotary_gift(SRGift, [], 0, 0)
    end.

rand_rotary_gift(_SRGift, TempGiftList, 6, _LoopCount)->
    %% io:format("~p ~p TempGiftList:~p~n", [?MODULE, ?LINE, TempGiftList]),
    TempGiftList;
rand_rotary_gift(_SRGift, TempGiftList, _Count, 20)->
    case length(TempGiftList) of
        6 ->
            TempGiftList;
        _ ->
            List = data_equip_energy:get_config(goods_list),
            %% 默认的转盘数据
            util:errlog("~p ~p get_define_list:~p~n", [?MODULE, ?LINE, List]),
            List
    end;
rand_rotary_gift(SRGift, TempGiftList, Count, LoopCount)->
    TotalRatio = lib_goods_util:get_ratio_total(SRGift, 2),
    Rand = util:rand(1, TotalRatio),
    case lib_goods_util:find_ratio(SRGift, 0, Rand, 2) of
        null -> 
            rand_rotary_gift(SRGift, TempGiftList, Count, LoopCount+1);
        {GoodsInfo, _Rate} -> 
            NewTempGiftList = [GoodsInfo | TempGiftList],
            NewSRGift = lists:keydelete(GoodsInfo, 1, SRGift),
            rand_rotary_gift(NewSRGift, NewTempGiftList, Count + 1, LoopCount+1)
    end.


%% 停留一分钟抽奖
waite_for_min(CloseTimer)->
    if 
        is_reference(CloseTimer) -> erlang:cancel_timer(CloseTimer);
        true -> skip
    end,
    %2.重新设置定时器.
    erlang:send_after(60*1000, self(), dungeon_time_end).

