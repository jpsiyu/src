%%%--------------------------------------
%% @Module  : lib_pet_egg
%% @Author  : HHL
%% @Created : 2014.03.27
%% @Description : 宠物砸蛋功能
%%%--------------------------------------

-module(lib_pet_egg).

%% ====================================================================
%% API functions
%% ====================================================================
-export([get_egg_info/1, 
         get_egg_record/1, 
         egg_broken/2,
         get_egg_notice/1,
         insert_egg_notice/3,
         online/1]).
-include("pet.hrl").
-include("sql_pet.hrl").
-include("server.hrl").



%% ====================================================================
%% Internal functions
%% ====================================================================
get_egg_info(PS)->
    RoleId = PS#player_status.id,
    DailyPid = PS#player_status.dailypid,
    PetEggLog = get_egg_record(RoleId),
    egg_info_format(PetEggLog, DailyPid, RoleId).
    

%%　砸蛋
egg_broken(PS, Type)->
    NowTime = util:unixtime(),
    PetEggLog = get_egg_record(PS#player_status.id),
    EggCd = PetEggLog#pet_egg_log.egg_cd,
    %% Pet = lib_pet:get_maxinum_growth_pet(PS#player_status.id),
    Goods = PS#player_status.goods,
    CellNum = gen_server:call(Goods#status_goods.goods_pid, {'cell_num'}),
    %% io:format("~p ~p CellNum:~p~n", [?MODULE, ?LINE, CellNum]),
    if
%%         Pet =:= [] ->
%%             {error, PS, 2};
        CellNum < 1 andalso (Type =:= 1 orelse Type =:= 2) ->
            {error, PS, 6};
        CellNum < 1 andalso Type =:= 3 ->
            {error, PS, 6};
        true ->
            case lists:keyfind(Type, 1, EggCd) of
                false -> {error, PS, 5};
                {Type, CdTime} ->
                    case egg_broken_check(PS, Type, NowTime, CdTime) of
                        {fail, ErrodCode} -> 
                            %% io:format("~p ~p ErrodCode:~p~n", [?MODULE, ?LINE, ErrodCode]), 
                            {error, PS, ErrodCode};
                        {true, MoneyType, Price} ->
                            %% io:format("~p ~p MoneyType:~p, Price:~p~n", [?MODULE, ?LINE, MoneyType, Price]),
                            %% 砸蛋操作
                            GetGoodsList = egg_broken_123(PS#player_status.id, PS#player_status.dailypid, PS#player_status.lv, Type, PetEggLog),
                            [GiveGoods, NoticeList] = get_notice_list(GetGoodsList, Type),
                            NewGiveGoods = goods_add(GiveGoods, []),
                            %% io:format("~p ~p NewGiveGoods:~p~n", [?MODULE, ?LINE, NewGiveGoods]),
                            case gen_server:call(PS#player_status.goods#status_goods.goods_pid, {'give_more', PS, NewGiveGoods}) of
                                ok ->
                                    if
                                        NoticeList =/= [] ->
                                            mod_disperse:cast_to_unite(lib_pet_egg, insert_egg_notice, [PS, Type, NoticeList]);
                                        true ->
                                            skip
                                    end,
                                    case MoneyType of
                                        free -> 
                                            {ok, PS, [GiveGoods, NoticeList], 1};
                                        coin ->
                                            NewPS1 = case GiveGoods of
                                                            [] -> PS;
                                                            GiveGoods ->
                                                                NewPS = lib_goods_util:cost_money(PS, Price, coin),
                                                                About = lists:concat([NewPS#player_status.id, "_coin_egg_broken_", NewPS#player_status.scene]),
                                                                log:log_consume(break_egg, coin, PS, NewPS, About),
                                                                lib_player:refresh_client(NewPS),
                                                                NewPS
                                                       end,
                                            {ok, NewPS1, [GiveGoods, NoticeList], 1};
                                        gold ->
                                           NewPS1 = case GiveGoods of
                                                            [] -> PS;
                                                            GiveGoods ->
                                                                NewPS = lib_goods_util:cost_money(PS, Price, gold),
                                                                About = lists:concat([NewPS#player_status.id,"_gold_egg_broken_", NewPS#player_status.scene]),
                                                                log:log_consume(break_egg, gold, PS, NewPS, About),
                                                                lib_player:refresh_client(NewPS),
                                                                NewPS
                                                       end,
                                           {ok, NewPS1, [GiveGoods, NoticeList], 1}
                                    end;
                                _Error -> 
                                    %% io:format("~p ~p _Error:~p~n", [?MODULE, ?LINE, _Error]),
                                    {error, PS, 0}
                            end
                    end
            end
    end.
            

%%　获取砸蛋公告
get_egg_notice(PS)->
    NoticeRecord = ets:lookup(?ETS_EGG_INFO, ?ETS_EGG_KEY),
    NoticeList = case NoticeRecord of
                    [] -> [];
                    [Record] ->
                        Record#egg_log_notice.notice_list
                 end,
    %% io:format("~p ~p NoticeList:~p~n", [?MODULE, ?LINE, NoticeList]),
    List = lists:map(fun({RoleId, Name, EggType, GoodId, _Num}) ->
                        BName = pt:write_string(Name),
                        <<RoleId:32, BName/binary, EggType:8, GoodId:32>>
                     end, NoticeList),
    %% io:format("~p ~p List:~p~n", [?MODULE, ?LINE, List]),
    {ok, BinData} = pt_410:write(41051, [1, List]),
    lib_unite_send:send_to_one(PS#player_status.id, BinData).

%%========================================私有内部方法==========================================================
%%　更新砸蛋公告数据(保留最多20条数据)
insert_egg_notice(PS, Type, GoodsList)->
    %% io:format("~p ~p Type:~p, List:~p~n", [?MODULE, ?LINE, Type, GoodsList]),
    lists:foreach(fun(GoodId)->
                     insert_egg_notice(PS#player_status.id, PS#player_status.nickname, Type, GoodId)
                  end, GoodsList).
insert_egg_notice(RoleId, Name, EggType, GoodId)->
    NoticeRecord = ets:lookup(?ETS_EGG_INFO, ?ETS_EGG_KEY),
    %% io:format("~p ~p NoticeRecord:~p~n", [?MODULE, ?LINE, NoticeRecord]),
    NewRecord = case NoticeRecord of
                   [] -> 
                       NewList = [{RoleId, Name, EggType, GoodId, 1}],
                       #egg_log_notice{notice_list = NewList};   
                   [Record] ->
                       List = [{RoleId, Name, EggType, GoodId, 1}|Record#egg_log_notice.notice_list],
                       NewList = case length(List) > 5 of
                                    true -> lists:sublist(List, 5);
                                    false -> List
                                 end,
                       Record#egg_log_notice{notice_list = NewList}
                end,
    %% io:format("~p ~p NewRecord:~p~n", [?MODULE, ?LINE, NewRecord]),
    ets:insert(?ETS_EGG_INFO, NewRecord).

%% 玩家获取砸蛋的内存数据
get_egg_record(RoleId)->
    case get(?EGG_KEY(RoleId)) of
        undefined ->
            online(RoleId);
        Record ->
            %% 过12点之后的数据刷新
            case util:diff_day(Record#pet_egg_log.time) > 0 of
                true ->
                    online(RoleId);
                false -> 
                    Record
            end
    end.
        

%%　玩家登录时从DB加载数据
online(RoleId)->
    NowTime =  util:unixtime(),
    SeSQL = io_lib:format(?SQL_SE_PET_EGG_BY_ROLE, [RoleId]),
    PetEggLog = case db:get_all(SeSQL) of
                    [] ->
                        EggCd = data_pet:get_egg_cd(),
                        SEggCd = util:term_to_string(EggCd),
                        ReSQL = io_lib:format(?SQL_RE_PET_EGG, [RoleId, SEggCd, "[]", NowTime]),
                        db:execute(ReSQL),
                        #pet_egg_log{role_id = RoleId, egg_cd = EggCd, get_good =[], time = NowTime};
                    [[RoleId, EggCd, GetGoods, UpTime]] ->
                        TermEggCd = util:bitstring_to_term(EggCd),
                        NewEggCd = update_cd_time(TermEggCd, NowTime),
                        %% io:format("~p ~p TermEggCd:~p,~n NewEggCd:~p~n", [?MODULE, ?LINE, TermEggCd, NewEggCd]),
                        case util:diff_day(UpTime) > 0 of
                            true -> 
                                SEggCd = util:term_to_string(NewEggCd),
                                ReSQL = io_lib:format(?SQL_RE_PET_EGG, [RoleId, SEggCd, "[]", NowTime]),
                                db:execute(ReSQL),
                                #pet_egg_log{role_id = RoleId, egg_cd = NewEggCd, get_good = [], time = NowTime};
                            false -> 
                                NewGetGoods = util:bitstring_to_term(GetGoods),
                                if
                                    TermEggCd =/= NewEggCd ->
                                        SEggCd = util:term_to_string(NewEggCd),
                                        SGetGoods = util:term_to_string(NewGetGoods),
                                        ReSQL = io_lib:format(?SQL_RE_PET_EGG, [RoleId, SEggCd, SGetGoods, NowTime]),
                                        db:execute(ReSQL);
                                    true ->
                                        skip
                                end,
                                #pet_egg_log{role_id = RoleId, egg_cd = NewEggCd, get_good = NewGetGoods, time = UpTime}
                         end
                end,
    put(?EGG_KEY(RoleId), PetEggLog),
    PetEggLog.


%% 砸蛋数据组装
egg_info_format(PetEggLog, DailyPid, RoleId) ->
    EggCd = PetEggLog#pet_egg_log.egg_cd,
    NowTime =  util:unixtime(), 
    EggInfoList = lists:map(fun({EggType, CdTime}) ->
                        if
                            EggType > 0 andalso EggType < 4 ->
                                if
                                    NowTime > CdTime orelse CdTime =:= 0 ->
                                        Cd = 0;
                                    true ->
                                        Cd = CdTime - NowTime
                                end,
                                EggTypeRecord = data_egg_goods:get_egg_type(EggType),
                                MoneyType = EggTypeRecord#pet_egg.money_type,
                                if
                                    EggType =:= 1 orelse EggType =:= 2 ->
                                        Price = EggTypeRecord#pet_egg.used_price,
                                        LessTime = 0;
                                        
                                    true ->
                                        Price = EggTypeRecord#pet_egg.used_price2,
                                        EggBreakTime = mod_daily:get_count(DailyPid, RoleId, 5000004),
                                        SaveCount = EggTypeRecord#pet_egg.save_count,
                                        LessTime = SaveCount - EggBreakTime   
                                end,
                                %% io:format("~p ~p Args:~p~n", [?MODULE, ?LINE, [EggType, MoneyType, Price, Cd, LessTime]]),
                                <<EggType:8, MoneyType:8, Price:32, Cd:32, LessTime:16>>;
                            true ->
                                <<>>
                        end
                      end,EggCd),
    [X || X <- EggInfoList, X =/= <<>>].
    
                
%% 砸蛋条件检查                     
egg_broken_check(PS, Type, NowTime, CdTime) ->
    EggTypeRecord = data_egg_goods:get_egg_type(Type),      
    if
        Type =:= 1 orelse Type =:= 2 ->
            IsFree = case NowTime > CdTime of
                         true -> 1;
                         false -> 0
                     end,
            case IsFree of
                1 -> {true, free, 0};
                _ -> 
                    NeedCoinNum = EggTypeRecord#pet_egg.used_price,
                    if
                        PS#player_status.coin < NeedCoinNum ->
                            {fail, 3};
                        true ->
                            {true, coin, NeedCoinNum}
                    end
            end;
        Type =:= 3 ->
            NeedGoldNum = EggTypeRecord#pet_egg.used_price2,
            if
                PS#player_status.gold < NeedGoldNum ->
                    {fail, 4};
                true ->
                    {true, gold, NeedGoldNum}
            end;
        true ->
            {fail, 5}
    end.

            
%% 砸蛋操作           
egg_broken_123(RoleId, DailyPid, Lv, Type, PetEggLog) ->
    EggTypeRecord = data_egg_goods:get_egg_type(Type),
    AllGoodList = EggTypeRecord#pet_egg.goods_list,
    SaveGoods = EggTypeRecord#pet_egg.save_goods_list,
    SaveCount = EggTypeRecord#pet_egg.save_count,
    CdTime = EggTypeRecord#pet_egg.cd_time,
    BaseGood = EggTypeRecord#pet_egg.base_goods,
    GoodList = get_good_list(AllGoodList, Lv),
    %% io:format("~p ~p GoodList:~p~n", [?MODULE, ?LINE, GoodList]),
    if
        Type =:= 1 orelse Type =:= 2 ->
            LoopTime = data_pet:get_egg_config(egg_12_loop_times),
            egg_broken_loop(RoleId, DailyPid, PetEggLog, CdTime, GoodList, Type, SaveCount, SaveGoods, BaseGood, [], LoopTime);
        Type =:= 3 ->
            LoopTime = data_pet:get_egg_config(egg_3_loop_times),
            egg_broken_loop(RoleId, DailyPid, PetEggLog, CdTime, GoodList, Type, SaveCount, SaveGoods, BaseGood, [], LoopTime);
        true ->
            []
    end.
   
%% 砸蛋1次和10次
egg_broken_loop(_RoleId, _DailyPid, _PetEggLog, _CdTime, _GoodList, _Type, _SaveCount, _SaveGoods, _BaseGood, TempGoods, 0) ->
    TempGoods;
egg_broken_loop(RoleId, DailyPid, PetEggLog, CdTime, GoodList, Type, SaveCount, SaveGoods, BaseGood, TempGoods, LoopCount) ->
    ColorEggCount = mod_daily:get_count(DailyPid, RoleId, 5000004),
    %% io:format("~p ~p Type:~p, ColorEggCount:~p, SaveCount:~p~n", [?MODULE, ?LINE, Type, ColorEggCount, SaveCount]),
    if
        Type =:= 3 andalso ColorEggCount >= SaveCount ->    %%　如果彩蛋砸了超过100次,就必爆珍贵物品
            NeedGoodList = SaveGoods;
        true ->
            NeedGoodList = format_good_list(RoleId, DailyPid, GoodList, Type)
    end,
    TotalRatio = lib_goods_util:get_ratio_total(NeedGoodList, 2),
    Rand = util:rand(1, TotalRatio),
    {GoodsTypeId, _R} = case lib_goods_util:find_ratio(NeedGoodList, 0, Rand, 2) of
                            null -> 
                                %% io:format("~p ~p null!~n", [?MODULE, ?LINE]),
                                {BaseGood, 0};
                            {_GoodsTypeId, _Rate} -> {_GoodsTypeId, _Rate}
                        end,
    %% io:format("~p ~p GoodsTypeId:~p~n", [?MODULE, ?LINE, GoodsTypeId]),
    case Type of
        1 ->
            update_pet_egg_log(RoleId, Type, PetEggLog, CdTime);
        2 -> 
            update_pet_egg_log(RoleId, Type, PetEggLog, CdTime),
            mod_daily:increment(DailyPid, RoleId, 5000005);
        3 ->
            case lists:keyfind(GoodsTypeId, 1, SaveGoods) of
                false ->
                     mod_daily:increment(DailyPid, RoleId, 5000004);
                {GoodsTypeId, _R1} ->
                     mod_daily:set_count(DailyPid, RoleId, 5000004, 0)
            end
    end,            
    egg_broken_loop(RoleId, DailyPid, PetEggLog, CdTime, GoodList, Type, SaveCount, SaveGoods, BaseGood, [GoodsTypeId|TempGoods], LoopCount-1).
    
    
%% 根据等级获取砸蛋物品列表
get_good_list([], _Lv) -> [];
get_good_list([{Lv1, Lv2, GoodList}|T], Lv) ->
    if
       Lv1 < Lv andalso Lv < Lv2 ->
           GoodList;
       true ->
           get_good_list(T, Lv)
    end.
    
%%　组合物品id和概率
format_good_list(RoleId, DailyPid, List, Type)->
    List1 = 
    lists:map(fun(GoodId)->
                    GoodRecord = data_egg_goods:get_egg_good(GoodId, Type),
                    if
                        Type =:= 1 -> {GoodRecord#pet_egg_goods.good_id, GoodRecord#pet_egg_goods.rate};
                        Type =:= 2 ->
                            GoldEggCount = mod_daily:get_count(DailyPid, RoleId, 5000005),
                            LimNum = GoodRecord#pet_egg_goods.lim_num,
                            if
                                LimNum < GoldEggCount -> {GoodRecord#pet_egg_goods.good_id, GoodRecord#pet_egg_goods.rate};
                                true -> {}
                            end;
                        Type =:= 3 ->
                            ColorEggCount = mod_daily:get_count(DailyPid, RoleId, 5000004),
                            LimNum = GoodRecord#pet_egg_goods.lim_num,
                            if
                                LimNum < ColorEggCount -> {GoodRecord#pet_egg_goods.good_id, GoodRecord#pet_egg_goods.rate};
                                true -> {}
                            end;
                        true -> {}
                    end                                
              end, List),
    [G || G <- List1, G =/= {}].


%%　组装物品的绑定和非绑格式和筛选出需要发传闻物品
get_notice_list(GoodsList, Type)->
    Fun = fun(GoodId, [GiveList, NiticeList])->
                  case data_egg_goods:get_egg_good(GoodId, Type) of
                      [] ->
                          [GiveList, NiticeList];
                      GoodInfo ->
                          if 
                              GoodInfo#pet_egg_goods.bind =:= 0 ->
                                  NewGiveList = [{goods, GoodId, 1, 2}|GiveList];
                              true ->
                                  NewGiveList = [{goods, GoodId, 1, 0}|GiveList]
                          end,
                          if 
                              GoodInfo#pet_egg_goods.notice =:= 0 ->
                                  NewNiticeList = NiticeList;
                              true ->
                                  NewNiticeList = [GoodId|NiticeList]
                          end,
                          [NewGiveList, NewNiticeList]
                  end
          end,
    lists:foldl(Fun, [[], []], GoodsList).
    
%% 如果金蛋和银蛋的cd时间为0就更新
update_pet_egg_log(RoleId, Type, PetEggLog, CdTime) ->
    EggCd = PetEggLog#pet_egg_log.egg_cd,
    NowTime = util:unixtime(),
    case lists:keyfind(Type, 1, EggCd) of
        false -> skip;
        {Type, CdTime1} ->
            %% io:format("~p ~p Type:~p, CdTime1:~p~n", [?MODULE, ?LINE, Type, CdTime1]),
            if
                CdTime1 =:= 0 andalso (Type=:=1 orelse Type=:=2) ->
                    NewEggCd = lists:keyreplace(Type, 1, EggCd, {Type, NowTime + CdTime}),
                    NewPetEggLog = PetEggLog#pet_egg_log{egg_cd = NewEggCd, time = NowTime},
                    %% io:format("~p ~p NewPetEggLog:~p~n", [?MODULE, ?LINE, NewPetEggLog]),
                    put(?EGG_KEY(RoleId), NewPetEggLog),
                    SEggCd = util:term_to_string(NewEggCd),
                    ReSQL = io_lib:format(?SQL_RE_PET_EGG, [RoleId, SEggCd, "[]", NowTime]),
                    db:execute(ReSQL);
                CdTime1 < NowTime andalso (Type=:=1 orelse Type=:=2) ->
                    NewEggCd = lists:keyreplace(Type, 1, EggCd, {Type, NowTime + CdTime}),
                    NewPetEggLog = PetEggLog#pet_egg_log{egg_cd = NewEggCd, time = NowTime},
                    %% io:format("~p ~p NewPetEggLog:~p~n", [?MODULE, ?LINE, NewPetEggLog]),
                    put(?EGG_KEY(RoleId), NewPetEggLog),
                    SEggCd = util:term_to_string(NewEggCd),
                    ReSQL = io_lib:format(?SQL_RE_PET_EGG, [RoleId, SEggCd, "[]", NowTime]),
                    db:execute(ReSQL);                    
                true ->
                    skip
            end
    end.

%% 更新cd
update_cd_time(TermEggCd, NowTime)->
    lists:map(fun({Type, CdTime})->
                      if
                          CdTime > NowTime ->
                              NewCD = CdTime;
                          true ->
                              NewCD = 0
                      end,
                      {Type, NewCD}
              end, TermEggCd).



%% 将同类型的物品数量累加起来
goods_add([], TempGoodList) ->
    TempGoodList;
goods_add([{goods, GoodId, Num, Bind}|T], TempGoodList) ->
    case lists:keyfind(GoodId, 2, TempGoodList) of
        false ->
            goods_add(T, [{goods, GoodId, Num, Bind}|TempGoodList]);
        {goods, GoodId, Num1, _Bind1} ->
            NewTempGoodList = lists:keydelete(GoodId, 2, TempGoodList),
            goods_add(T, [{goods, GoodId, Num+Num1, Bind}|NewTempGoodList])
    end.

