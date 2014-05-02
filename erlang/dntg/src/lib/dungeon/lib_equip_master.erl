%%------------------------------------------------------------------------------
%% @Module  : lib_equip_master
%% @Author  : HHL
%% @Email   : 1942007864@qq.com
%% @Created : 2014.2.25
%% @Description: 装备副本霸主信息
%%------------------------------------------------------------------------------
-module(lib_equip_master).

-include("dungeon.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("sql_dungeon.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-export([load_equip_masters/0,
         update_master/6,
         get_master_info/1,
         get_master_time/1,
         get_equip_list/2,
         update_get_equip_list/7,
         get_player_info/1,
         clean_equip_master/0]).


%% 记载数据
load_equip_masters() ->
    SQL = io_lib:format(?sql_select_equip_master, []),
    EquipMaster1 = db:get_all(SQL),
    EquipMaster = case EquipMaster1 of
                    [] -> 
                        %% 遍历副本id，将所有的数据初始化到进程
                        init_equip_master();
                    EquipMaster1 -> 
                        EquipMaster1
                  end,
    lists:foreach(fun(DunMasterLog)-> 
                      [DungeonId, RoleId, Name, Career, Sex,  PassTime] = DunMasterLog,
                      EquipOneMaster = #dntk_equip_dun_master{dun_id = DungeonId, 
                                                              role_id = RoleId, 
                                                              name = Name, 
                                                              career = Career,
                                                              sex = Sex,
                                                              pass_time = PassTime
                                                              },
                      ets:insert(?ETS_EQUIP_MASTER, EquipOneMaster)
                  end, EquipMaster).


%% rpc过程调用的方法顺序执行
update_get_equip_list(DunId, RoleId, PassTime, EquipList, Name, Career, Sex) ->
    DunIdList = get_all_master_by_roleid(RoleId),
    %% update_master(DunId, RoleId, PassTime, Name, Career, Sex),
    %% io:format("~p ~p DunIdList:~p~n", [?MODULE, ?LINE, DunIdList]),
    be_master(DunIdList, DunId, RoleId, PassTime, Name, Career, Sex),
    get_equip_list(RoleId, EquipList). 
    

%% 获取装备列表
get_equip_list(RoleId, EquipList) ->
    BinList = lists:map(fun(EnergyDunRecord) ->
                            {_RoleId, DungeonId} = EnergyDunRecord#dntk_equip_dun_log.id,
                            Level = EnergyDunRecord#dntk_equip_dun_log.level,
                            BestTime =EnergyDunRecord#dntk_equip_dun_log.best_time,
                            IsGift = EnergyDunRecord#dntk_equip_dun_log.gift,
                            Career1 = EnergyDunRecord#dntk_equip_dun_log.career,
                            {PassGiftId, Num} = case data_equip_energy:get_pass_gift_info(DungeonId, pass_gift, Career1) of
                                             {error, type_not_exist} -> util:errlog("dun_gift_info_type_not_exist!~n", []), {0, 0};
                                             {error, dun_gift_info_not_exist} -> util:errlog("dun_gift_info_not_exist!~n", []), {0, 0};
                                             {error, dun_not_exist} -> util:errlog("dun_not_exist!~n", []), {0, 0};
                                             {PassGiftId1, Num1} -> {PassGiftId1, Num1}
                                         end,
                            %% io:format("~p ~p PassGiftId:~p~n", [?MODULE, ?LINE, PassGiftId]),
                            SortId = EnergyDunRecord#dntk_equip_dun_log.sort_id,
                            CengId = data_equip_energy:get_ceng_id(DungeonId),
                            [Name, Career, Sex, PassTime] = 
                            case get_master_info(DungeonId) of
                                [] -> [[], 0, 0, 0];
                                MasterInfo -> MasterInfo
                            end,
                            %% io:format("~p ~p Master:~p~n", [?MODULE, ?LINE, [Name, Career, Sex, PassTime]]),
                            BName = pt:write_string(Name),
                            <<DungeonId:32, Level:8, BestTime:32, IsGift:8, PassGiftId:32, SortId:8, CengId:8, BName/binary, Career:8, Sex:8, PassTime:32,  Num:8>>
                        end, EquipList),
    {ok, BinData} = pt_611:write(61171, [BinList]),
    lib_unite_send:send_to_one(RoleId, BinData).
           

%% 添加和更新霸主信息
update_master(DunId, RoleId, PassTime, Name, Career, Sex) ->
    %% io:format("~p ~p UpdateMasterInfo:~p~n", [?MODULE, ?LINE, [DunId, RoleId, PassTime, Name, Career, Sex]]),
    case get_master_time(DunId) of
        0 ->
            NowTime = util:unixtime(),
            SQL = io_lib:format(?sql_replace_equip_master, [DunId, RoleId, Name, Career, Sex, PassTime, NowTime]),
            %% io:format("~p ~p SQL:~ts~n", [?MODULE, ?LINE, SQL]),
            db:execute(SQL),
            NewOneMaster = #dntk_equip_dun_master{dun_id = DunId, role_id = RoleId, name = Name, career = Career, 
                                                  sex = Sex, pass_time = PassTime, time = NowTime},
            ets:insert(?ETS_EQUIP_MASTER, NewOneMaster);
        MasterTime ->
            case PassTime > MasterTime of
                true ->
                   skip;
                false -> 
                   NowTime = util:unixtime(),
                   SQL = io_lib:format(?sql_replace_equip_master, [DunId, RoleId, Name, Career, Sex, PassTime, NowTime]),
                   %% io:format("~p ~p SQL:~ts~n", [?MODULE, ?LINE, SQL]),
                   db:execute(SQL),
                   NewOneMaster = #dntk_equip_dun_master{dun_id = DunId, role_id = RoleId, name = Name, career = Career, 
                                                         sex = Sex, pass_time = PassTime, time = NowTime},
                   %% io:format("~p ~p PassTime:~p, MasterTime:~p~nNewOneMaster:~p~n", [?MODULE, ?LINE, PassTime, MasterTime, NewOneMaster]),
                   ets:insert(?ETS_EQUIP_MASTER, NewOneMaster)
            end
    end.
%% %% 添加和更新霸主信息
%% update_master(DunId, RoleId, PassTime, Name, Career, Sex) ->
%%     case get_master_time(DunId) of
%%         0 ->
%%             case get_player_info(RoleId) of
%%                 [] -> 
%%                     skip;
%%                 [[Name, Career, Sex]] ->
%%                     NowTime = util:unixtime(),
%%                     SQL = io_lib:format(?sql_replace_equip_master, [DunId, RoleId, Name, Career, Sex, PassTime, NowTime]),
%%                     db:execute(SQL),
%%                     NewOneMaster = #dntk_equip_dun_master{dun_id = DunId, role_id = RoleId, name = Name, career = Career, 
%%                                                           sex = Sex, pass_time = PassTime, time = NowTime},
%%                     ets:insert(?ETS_EQUIP_MASTER, NewOneMaster)
%%             end;
%%         MasterTime ->
%%             case PassTime > MasterTime of
%%                 true ->
%%                     skip;
%%                 false -> 
%%                     case get_player_info(RoleId) of
%%                         [] -> 
%%                             skip;
%%                         [[Name, Career, Sex]] ->
%%                             NowTime = util:unixtime(),
%%                             SQL = io_lib:format(?sql_replace_equip_master, [DunId, RoleId, Name, Career, Sex, PassTime, NowTime]),
%%                             db:execute(SQL),
%%                             NewOneMaster = #dntk_equip_dun_master{dun_id = DunId, role_id = RoleId, name = Name, career = Career, 
%%                                                                   sex = Sex, pass_time = PassTime, time = NowTime},
%%                             %% io:format("~p ~p PassTime:~p, MasterTime:~p~nNewOneMaster:~p~n", [?MODULE, ?LINE, PassTime, MasterTime, NewOneMaster]),
%%                             ets:insert(?ETS_EQUIP_MASTER, NewOneMaster)
%%                     end
%%             end
%%     end.
    
%% ====================================================================
%% Internal functions
%% ====================================================================
%% init_equip_master()->
%%     EquipDunList = data_equip_energy:get_config(dungeon_list), 
%%     EquipMaster =  lists:map(fun(DunId) ->
%%                         SQL = io_lib:format(?sql_select_equip_master_by_dunid, [DunId]),
%%                         MasterLog1 =  db:get_all(SQL),
%%                         MasterLog = case MasterLog1 of
%%                                         [] -> [];
%%                                         [[DunId, RoleId, BestTime, Name, Career, Sex]] -> 
%%                                             [DunId, RoleId, Name, Career, Sex,  BestTime]
%%                                     end,
%%                         MasterLog
%%                       end, EquipDunList),
%%     NowTime = util:unixtime(),
%%     Fun = fun(Master) ->
%%                [DunId, RoleId, Name1, Career1, Sex1,  PassTime] = Master,  
%%                SQL = io_lib:format(?sql_replace_equip_master, [DunId, RoleId, Name1, Career1, Sex1, PassTime, NowTime]),
%%                db:execute(SQL)
%%           end,
%%     L = [X || X <- EquipMaster, X =/= []],
%%     lists:foreach(Fun, L),
%%     L.


init_equip_master()->
    EquipDunList = data_equip_energy:get_config(dungeon_list), 
    EquipMaster =  lists:map(fun(DunId) ->
                                [DunId, 0, "", 0, 0, 0]
                             end, EquipDunList),
    NowTime = util:unixtime(),
    Fun = fun(Master) ->
               [DunId, RoleId, Name1, Career1, Sex1,  PassTime] = Master,  
               SQL = io_lib:format(?sql_replace_equip_master, [DunId, RoleId, Name1, Career1, Sex1, PassTime, NowTime]),
               db:execute(SQL)
          end,
    lists:foreach(Fun, EquipMaster),
    EquipMaster.


%%　获取霸主信息
get_master_info(DunId) ->
    case ets:lookup(?ETS_EQUIP_MASTER, DunId) of
        [] -> [];
        [OneMaster] ->
            Name = OneMaster#dntk_equip_dun_master.name,
            Career = OneMaster#dntk_equip_dun_master.career,
            Sex = OneMaster#dntk_equip_dun_master.sex,
            PassTime = OneMaster#dntk_equip_dun_master.pass_time,
            [Name, Career, Sex, PassTime]
    end.


%% 获取霸主通关时间
get_master_time(DunId) ->
    case ets:lookup(?ETS_EQUIP_MASTER, DunId) of
        [] -> 0;
        [OneMaster] ->
            OneMaster#dntk_equip_dun_master.pass_time
    end.


%% 得到玩家的名字,职业,性别.
get_player_info(PlayerId) ->
    case db:get_all(io_lib:format(?sql_select_equip_player_info, [PlayerId])) of             
        null -> [];
        List -> List
    end.

%% 每天0点清理霸主的信息
clean_equip_master() -> 
%%     发送装备霸主礼品
%%     OldEquipMaster = ets:tab2list(?ETS_EQUIP_MASTER),
%%     FunSend = 
%%         fun(DunId, RoleId) ->
%%             case RoleId of
%%                 0 -> skip;
%%                 RoleId -> 
%%                 Title = data_dungeon_text:get_equip_master_config(title, 0),
%%                 
%%                 GoodsId = data_equip_config:get_gift_id(DunId),
%%                 Dun = data_dungeon:get(DunId),
%%                 case Dun of
%%                     [] -> skip;
%%                     Dun ->
%%                         Content = data_dungeon_text:get_equip_master_config(content, [Dun#dungeon.name]), 
%%                         lib_mail:send_sys_mail_bg([RoleId], Title, Content, GoodsId, 2, 0, 0, 1, 0, 0, 0, 0)
%%                 end
%%             end
%%         end,
%%     [FunSend(Master#dntk_equip_dun_master.dun_id, Master#dntk_equip_dun_master.role_id)|| Master <- OldEquipMaster],
    EquipMaster = init_equip_master(),
    %% io:format("~p ~p EquipMaster:~p~n", [?MODULE, ?LINE, EquipMaster]),
    lists:foreach(fun(DunMasterLog)-> 
                      [DungeonId, RoleId, Name, Career, Sex,  PassTime] = DunMasterLog,
                      EquipOneMaster = #dntk_equip_dun_master{dun_id = DungeonId, 
                                                              role_id = RoleId, 
                                                              name = Name, 
                                                              career = Career,
                                                              sex = Sex,
                                                              pass_time = PassTime
                                                              },
                      ets:insert(?ETS_EQUIP_MASTER, EquipOneMaster)
                  end, EquipMaster).

%% 获取玩家霸主
get_all_master_by_roleid(RoleId)->
    Ms = ets:fun2ms(fun(#dntk_equip_dun_master{role_id=RoleId1, dun_id = DunId}) when RoleId1 =:= RoleId -> [DunId] end),
    ets:select(?ETS_EQUIP_MASTER, Ms).

%% 删除和判断是否成为霸主
be_master(DunIdList, DunId, RoleId, PassTime, Name, Career, Sex) ->
    case DunIdList of
        [] ->
            update_master(DunId, RoleId, PassTime, Name, Career, Sex);
        DunIdList ->            
            Len = length(DunIdList),
            case Len of
                1 ->
                    [[DunId1]] = DunIdList,
                    if
                        DunId > DunId1 ->
                            remove_last_master_by_dunid(DunId1, RoleId),
                            update_master(DunId, RoleId, PassTime, Name, Career, Sex);
                        DunId =:= DunId1 ->
                            update_master(DunId, RoleId, PassTime, Name, Career, Sex);
                        true -> skip
                    end;
                _ ->
                    DunIdList1 = lists:flatten(DunIdList),
                    SortDunIdList = lists:sort(fun(X, Y) -> X > Y end, DunIdList1),
                    [DunId1|TDunIdList] = SortDunIdList,
                    if
                        DunId > DunId1 ->
                            lists:foreach(fun(DunId2) -> remove_last_master_by_dunid(DunId2, RoleId) end, SortDunIdList),
                            update_master(DunId, RoleId, PassTime, Name, Career, Sex);
                        DunId =:= DunId1 ->
                            lists:foreach(fun(DunId2) -> remove_last_master_by_dunid(DunId2, RoleId) end, TDunIdList),
                            update_master(DunId, RoleId, PassTime, Name, Career, Sex);
                        true -> 
                            lists:foreach(fun(DunId2) -> remove_last_master_by_dunid(DunId2, RoleId) end, TDunIdList)
                    end
            end
    end.
    
%% 移除旧的霸主信息
remove_last_master_by_dunid(DunId, RoleId) ->
    case ets:lookup(?ETS_EQUIP_MASTER, DunId) of
        [] -> skip;
        [OneMaster] ->
            if
                OneMaster#dntk_equip_dun_master.role_id =:= RoleId ->
                    NewOneMaster = #dntk_equip_dun_master{dun_id = DunId},
                    SQL = io_lib:format(?sql_replace_equip_master, [DunId, 0, "", 0, 0, 0, 0]),
                    db:execute(SQL),
                    ets:insert(?ETS_EQUIP_MASTER, NewOneMaster);
                true -> skip
            end
    end.












