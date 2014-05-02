%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-1-6
%% Description: 物品掉落处理
%% --------------------------------------------------------
-module(lib_goods_drop).
-include("goods.hrl").
-include("server.hrl").
-include("common.hrl").
-include("def_goods.hrl").
-include("drop.hrl").
-include("sql_goods.hrl").
-include("scene.hrl").
-export(
    [      
      send_drop_notice/2,
      get_task_mon/1,
      mon_drop/3,
      send_drop/4,
      diablo_drop/2,
      get_drop_item/2,
      handle_drop/4,
	  get_drop_goods_list/1,
	  filter_goods/2,
	  get_drop_num_list/1,
	  drop_goods_list/2
    ]
).

send_drop_notice(PlayerStatus, DropInfo) ->
    {ok, BinData1} = pt_120:write(12021, [PlayerStatus#player_status.id, PlayerStatus#player_status.platform, PlayerStatus#player_status.server_num, DropInfo#ets_drop.id, PlayerStatus#player_status.nickname]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData1),
    lib_team:send_to_member(PlayerStatus#player_status.pid_team, BinData1),
    {ok, BinData2} = pt_120:write(12019, DropInfo#ets_drop.id),
    lib_server_send:send_to_scene(PlayerStatus#player_status.scene, PlayerStatus#player_status.copy_id, BinData2),
    ok.

%% 根据物品类型取任务怪ID
%% @spec get_task_mon(GoodsTypeId) -> mon_id | 0
get_task_mon(GoodsTypeId) ->
    data_drop:get_task_mon(GoodsTypeId).

%% 普通怪掉落
common_drop(PlayerStatus, MonStatus, DropRule, PList) -> 
    %% 取掉落物品列表
    [StableGoods, TaskGoods, RandGoods, _, _] = get_drop_goods_list(DropRule),
    %% 取任务物品
    TaskList = get_task_goods(PlayerStatus#player_status.tid, TaskGoods),
    %% 取随机物品掉落数列表
    DropNumList = get_drop_num_list(DropRule),
    %% 掉落物品
    DropGoods = drop_goods_list(RandGoods, DropNumList),
    DropList = StableGoods ++ DropGoods,
    %% 处理任务物品
    handle_task_list(PlayerStatus, PList, TaskList, MonStatus),
    alloc_drop(PlayerStatus, MonStatus, DropRule, DropList),
    ok.

%% BOSS怪掉落
boss_drop(PlayerStatus, MonStatus, DropRule, PList) ->
    F = fun() ->
            [StableGoods, TaskGoods, RandGoods, _, _] = get_drop_goods_list(DropRule),
            TaskList = get_task_goods(PlayerStatus#player_status.tid, TaskGoods),
            NowTime = util:unixdate(),
            %% 过滤随机掉落物品列表
            RandGoods2 = filter_goods(RandGoods, {NowTime, DropRule#ets_drop_rule.counter_goods}),
            DropNumList = get_drop_num_list(DropRule),
            DropGoods = drop_goods_list(RandGoods2, DropNumList),
            DropList = StableGoods ++ DropGoods,
            handle_task_list(PlayerStatus, PList, TaskList, MonStatus),
            alloc_drop(PlayerStatus, MonStatus, DropRule, DropList),
            ok
        end,
    lib_goods_util:transaction(F).

%% 怪物掉落
mon_drop(PlayerStatus, MonStatus, PList) ->
   %% io:format("drop... mid=~p, Rule=~p~n", [MonStatus#ets_mon.mid, data_drop:get_rule(MonStatus#ets_mon.mid)]),
    case data_drop:get_rule(MonStatus#ets_mon.mid) of
        %% 掉落规则不存在
        [] ->
            %% 完成打怪任务
            case length(PList) < 2 of
                true ->
                    lib_task:event(PlayerStatus#player_status.tid, kill, MonStatus#ets_mon.mid, PlayerStatus#player_status.id);
                false ->
                    lib_mon_die:finish_task(PList, MonStatus, PlayerStatus)
            end,
            Res = ok;
        %% ---特殊双倍掉落-----{
        %% 普通怪掉落
        DropRule when DropRule#ets_drop_rule.boss =:= 0, MonStatus#ets_mon.drop_num > 0 ->
            ResM1 = (catch common_drop(PlayerStatus, MonStatus, DropRule, PList)),
            ResM2 = (catch common_drop(PlayerStatus, MonStatus, DropRule, PList)),
            Res = case ResM1 == ok andalso ResM2 == ok of true -> ok; false -> {ResM1, ResM2} end;
        %% BOSS怪掉落
        DropRule when MonStatus#ets_mon.drop_num > 0->
            ResM1 = (catch common_drop(PlayerStatus, MonStatus, DropRule, PList)),
            ResM2 = (catch common_drop(PlayerStatus, MonStatus, DropRule, PList)),
            Res = case ResM1 == ok andalso ResM2 == ok of true -> ok; false -> {ResM1, ResM2} end;
        %% }----END------------

        %% 普通怪掉落
        DropRule when DropRule#ets_drop_rule.boss =:= 0 ->
            Res = (catch common_drop(PlayerStatus, MonStatus, DropRule, PList));
        %% BOSS怪掉落
        DropRule ->
            Res = (catch boss_drop(PlayerStatus, MonStatus, DropRule, PList))
    end,
    if  Res =/= ok ->
            ?INFO("mon_drop:~p", [Res]);
        true -> skip
    end,
    ok.

%% 过滤随机掉落物品列表
filter_goods([Info|T], {NowTime, CounterGoods}) ->
    GoodsTypeId = Info#ets_drop_goods.goods_id,
    case lists:member(GoodsTypeId, CounterGoods) of
        true ->
            case get_mon_goods_counter(GoodsTypeId) of
                [] -> [Info | filter_goods(T, {NowTime, CounterGoods})];
                [Counter] ->
                    if  NowTime =/= Counter#ets_mon_goods_counter.time ->
                            [Info | filter_goods(T, {NowTime, CounterGoods})];
                        Counter#ets_mon_goods_counter.drop_num >= Counter#ets_mon_goods_counter.goods_num ->
                            filter_goods(T, {NowTime, CounterGoods});
                        true ->
                            [Info | filter_goods(T, {NowTime, CounterGoods})]
                    end
            end;
        false ->
            [Info | filter_goods(T, {NowTime, CounterGoods})]
    end;
filter_goods([], _) -> [].

%% 取掉落物品列表
get_drop_goods_list(DropRule) ->
    F = fun(Id, [StableGoods, TaskGoods, RandGoods, NowTime, Hour]) ->
            case data_drop:get_goods(Id) of
                [] -> [StableGoods, TaskGoods, RandGoods, NowTime, Hour];
                DropGoods when DropGoods#ets_drop_goods.time_start > 0 andalso DropGoods#ets_drop_goods.time_start > NowTime ->
                    [StableGoods, TaskGoods, RandGoods, NowTime, Hour];
                DropGoods when DropGoods#ets_drop_goods.time_end > 0 andalso DropGoods#ets_drop_goods.time_end < NowTime ->
                    [StableGoods, TaskGoods, RandGoods, NowTime, Hour];
                DropGoods when DropGoods#ets_drop_goods.hour_start > 0 andalso DropGoods#ets_drop_goods.hour_start > Hour ->
                    [StableGoods, TaskGoods, RandGoods, NowTime, Hour];
                DropGoods when DropGoods#ets_drop_goods.hour_end > 0 andalso DropGoods#ets_drop_goods.hour_end < Hour ->
                    [StableGoods, TaskGoods, RandGoods, NowTime, Hour];
                DropGoods when DropGoods#ets_drop_goods.type =:= 1 ->       %固定
                    [[DropGoods|StableGoods], TaskGoods, RandGoods, NowTime, Hour];
                DropGoods when DropGoods#ets_drop_goods.type =:= 2 ->       %任务
                    [StableGoods, [DropGoods|TaskGoods], RandGoods, NowTime, Hour];
                DropGoods when DropGoods#ets_drop_goods.type =:= 0 ->       %随机
                    [StableGoods, TaskGoods, [DropGoods|RandGoods], NowTime, Hour];
                _ -> [StableGoods, TaskGoods, RandGoods, NowTime, Hour]
            end
        end,
    {_,{H,_,_}} = calendar:local_time(),
    lists:foldl(F, [[],[],[],util:unixtime(), H], DropRule#ets_drop_rule.drop_list).

%% 取任务物品
get_task_goods(Tid, TaskGoods) ->
    if length(TaskGoods) > 0 ->
            NeedGoods = lib_task:can_gain_item(Tid),
            GoodsList = lists:foldl(fun filter_task/2, [], NeedGoods),
            if length(GoodsList) > 0 ->
                    [TaskList, _] = lists:foldl(fun find_task/2, [[], GoodsList], TaskGoods),
                    TaskList;
                true -> []
            end;
        true -> []
    end.

filter_task({GoodsTypeId, MaxNum, Num}, List) ->
    case Num < MaxNum of
        true -> 
            [GoodsTypeId | List];
        false -> 
            List
    end.

find_task(DropGoods, [List, GoodsList]) ->
    case lists:member(DropGoods#ets_drop_goods.goods_id, GoodsList) of
        true ->
            Rand = util:rand(1, 1000),
            case Rand =< DropGoods#ets_drop_goods.ratio of
                true -> 
                    [[{DropGoods#ets_drop_goods.goods_id,1} | List], GoodsList];
                false -> 
                    [List, GoodsList]
            end;
        false -> [List, GoodsList]
    end.

%% 取随机物品掉落数列表
get_drop_num_list(DropRule) ->
   find_ratio(DropRule#ets_drop_rule.drop_rule, 0, util:rand(1, 1000)).

%% 查找匹配机率的值
find_ratio([], _, _) -> [];
find_ratio([{L,R}|_], S, Ra) when Ra > S andalso Ra =< (S + R) -> L;
find_ratio([{_,R}|T], S, Ra) -> find_ratio(T, (S + R), Ra).

%% 查找匹配机率的值
get_goods_ratio([], R) -> R;
get_goods_ratio([H|T], R) ->
    get_goods_ratio(T, H#ets_drop_goods.ratio + R).

%% 掉落物品
drop_goods_list(RandGoods, DropNumList) ->
    case DropNumList of
        [] -> [];
        _ ->
            DropFactor = get_drop_factor(),
            lists:merge([drop_goods(RandGoods, DropFactor, N, DropNum) || {N, DropNum} <- DropNumList])
    end.

%% 掉落物品
drop_goods(RandGoods, DropFactor, N, DropNum) ->
    DropList = make_drop_list(RandGoods, DropFactor, N, []),
    case DropNum =:= 0 orelse length(DropList) =:= 0 of
        true -> [];
        false ->
            TotalRatio = get_goods_ratio(DropList, 0),
            find_drop_goods(DropList, DropNum, TotalRatio, [])
    end.

%% 查找随机掉落物品表
find_drop_goods(DropList, DropNum, TotalRatio, Result) ->
    Rand = util:rand(1, TotalRatio),
    case find_goods(DropList, 0, Rand) of
        [] -> Result;
        DropGoods ->
            NewDropGoods = rand_item(DropGoods),
            NewResult = [NewDropGoods | Result],
            if  DropNum > 1 ->
                    NewDropList = lists:delete(DropGoods, DropList),
                    find_drop_goods(NewDropList, (DropNum - 1), (TotalRatio - DropGoods#ets_drop_goods.ratio), NewResult);
                true -> NewResult
            end
    end.

%% 随机物品数或者装备强化品质等级
rand_item(DropGoods) ->
    Num = case DropGoods#ets_drop_goods.num > 1 of
              true -> 
                  util:rand(1, DropGoods#ets_drop_goods.num);
              false -> 
                  1
          end,
    Stren = case DropGoods#ets_drop_goods.stren > 0 of
                true -> 
                    util:rand(0, DropGoods#ets_drop_goods.stren);
                false -> 
                    0
            end,
    Prefix = case DropGoods#ets_drop_goods.prefix > 0 of
                 true -> 
                     data_goods:rand_prefix(DropGoods#ets_drop_goods.prefix);
                 false -> 
                     0
             end,
    DropGoods#ets_drop_goods{num=Num, stren=Stren, prefix=Prefix}.

%% 查找匹配机率的值
find_goods([], _, _) -> [];
find_goods([H|_], S, Ra) when Ra > S andalso Ra =< (S + H#ets_drop_goods.ratio) -> H;
find_goods([H|T], S, Ra) -> 
    find_goods(T, (S + H#ets_drop_goods.ratio), Ra).

make_drop_list([], _D, _N, L) -> L;
make_drop_list([DropGoods|RandGoods], DropFactor, N, L) when DropGoods#ets_drop_goods.list_id =:= N ->
    case DropGoods#ets_drop_goods.factor =:= 1 of
        true ->
            case lists:keyfind(DropGoods#ets_drop_goods.goods_id, 1, DropFactor#ets_drop_factor.drop_factor_list) of
                {_, R} -> 
                    make_drop_list(RandGoods, DropFactor, N, [DropGoods#ets_drop_goods{ratio = round(DropGoods#ets_drop_goods.ratio * R) } | L]);
                false -> 
                    make_drop_list(RandGoods, DropFactor, N, [DropGoods#ets_drop_goods{ratio = round(DropGoods#ets_drop_goods.ratio * DropFactor#ets_drop_factor.drop_factor)} | L])
            end;
        false ->
            make_drop_list(RandGoods, DropFactor, N, [DropGoods | L])
    end;
make_drop_list([_H|T], D, N, L) ->
    make_drop_list(T, D, N, L).

%% 处理任务物品
handle_task_list(PS, PList, TaskList, MonStatus) ->
    if  length(TaskList) > 0 ->
            case length(PList) < 2 of
                true ->
                    case is_pid(PS#player_status.pid_team) of
                        true ->
                            gen_server:cast(PS#player_status.pid_team, {'fin_task_goods', TaskList,
                                    [MonStatus#ets_mon.mid, MonStatus#ets_mon.scene, MonStatus#ets_mon.copy_id, 
                                        MonStatus#ets_mon.x, MonStatus#ets_mon.y]}),
                            gen_server:cast(PS#player_status.pid_team, {'fin_task',
                                    [MonStatus#ets_mon.mid, MonStatus#ets_mon.scene, MonStatus#ets_mon.copy_id, 
                                        MonStatus#ets_mon.x, MonStatus#ets_mon.y]});
                        false ->
                            lib_task:event(PS#player_status.tid, item, TaskList, PS#player_status.id),
                            lib_task:event(PS#player_status.tid, kill, MonStatus#ets_mon.mid, PS#player_status.id)
                    end;                    
                false ->
                    %%　搜集任务
                    lib_mon_die:finish_task_goods(TaskList, PList, MonStatus, PS),
                    lib_mon_die:finish_task(PList, MonStatus, PS)
            end;
        true -> 
            %% 完成打怪任务
            case length(PList) < 2 of
                true ->
                    case is_pid(PS#player_status.pid_team) of
                        true ->
                            gen_server:cast(PS#player_status.pid_team, {'fin_task',
                                    [MonStatus#ets_mon.mid, MonStatus#ets_mon.scene, MonStatus#ets_mon.copy_id, 
                                        MonStatus#ets_mon.x, MonStatus#ets_mon.y]});
                        false ->
                            lib_task:event(PS#player_status.tid, kill, MonStatus#ets_mon.mid, PS#player_status.id)
                    end;                    
                false ->
                    lib_mon_die:finish_task(PList, MonStatus, PS)
            end
    end.

%% 分派掉落
alloc_drop2(PlayerStatus, MonStatus, DropRule, DropList) ->
    if 
        length(DropList) > 0 ->
            if 
                PlayerStatus#player_status.pid_team =/= 0 ->
                    lib_team:drop_distribution(PlayerStatus, MonStatus, DropRule, DropList);
                true ->
                    handle_drop_list(PlayerStatus, MonStatus, DropRule, DropList)
		    end;
        true -> 
            skip
    end.

alloc_drop(PlayerStatus, MonStatus, DropRule, DropList) ->
    DropList1 = filter_reduce_list(DropList, [], PlayerStatus, MonStatus),
%%    T = lists:member(MonStatus#ets_mon.mid, [35105,35110,35115,35120,35125,35130,35135,35140,35145,35150]),
%%    if
%%        T =:= true ->
%%            R = util:rand(1,100),
%%            if
%%                R =< 60 ->
%%                    DropList1 = [#ets_drop_goods{mon_id=MonStatus#ets_mon.mid, type=0, goods_id=601401, num=1, bind=2, notice=1}] ++ [#ets_drop_goods{mon_id=MonStatus#ets_mon.mid, type=0, goods_id=602101, num=1, bind=2, notice=1}];
%%                R > 60 andalso R =< 95 ->
%%                    DropList1 = [#ets_drop_goods{mon_id=MonStatus#ets_mon.mid, type=0, goods_id=601401, num=1, bind=2, notice=1}] ++ [#ets_drop_goods{mon_id=MonStatus#ets_mon.mid, type=0, goods_id=112201, num=1, bind=2, notice=1}] ++ [#ets_drop_goods{mon_id=MonStatus#ets_mon.mid, type=0, goods_id=602101, num=1, bind=2, notice=1}];
%%                R > 95 ->
%%                    DropList1 = [#ets_drop_goods{mon_id=MonStatus#ets_mon.mid, type=0, goods_id=601601, num=1, bind=2, notice=1}] ++ [#ets_drop_goods{mon_id=MonStatus#ets_mon.mid, type=0, goods_id=601401, num=1, bind=2, notice=1}] ++ [#ets_drop_goods{mon_id=MonStatus#ets_mon.mid, type=0, goods_id=602101, num=1, bind=2, notice=1}];
%%                true ->
%%                    DropList1 = []
%%            end;
%%        true ->
%%            DropList1 = filter_reduce_list(DropList, [], PlayerStatus, MonStatus)
%%    end,    
%    T = lists:member(MonStatus#ets_mon.mid, [99010,99011,99012,99013,99014,99015,99016,99017,99018,99018,99020,99021,99022,99023,99024]),
%    if
%        T =:= true ->
%            DropList2 = DropList1 ++ [#ets_drop_goods{mon_id=MonStatus#ets_mon.mid, type=0, goods_id=221212, num=1, bind=2, notice=1}] ++ [#ets_drop_goods{mon_id=MonStatus#ets_mon.mid, type=0, goods_id=221212, num=1, bind=2, notice=1}] ++ [#ets_drop_goods{mon_id=MonStatus#ets_mon.mid, type=0, goods_id=221212, num=1, bind=2, notice=1}];
%        true ->
%            DropList2 = DropList1
%    end,
    if length(DropList1) > 0 ->
        if 
            PlayerStatus#player_status.pid_team =/= 0 ->
                lib_team:drop_distribution(PlayerStatus, MonStatus, DropRule, DropList1);
            true ->
                handle_drop_list(PlayerStatus, MonStatus, DropRule, DropList1)
		end;
	true -> 
        skip
    end.

%% 过虑衰减物品
filter_reduce_list([], L, _PS, _MonStatus) ->
    L;
filter_reduce_list([DropInfo|H], L, PS, MonStatus) ->
    if
        is_record(DropInfo, ets_drop_goods) =:= true ->
            case DropInfo#ets_drop_goods.reduce =:= 0 of
                true ->
                    filter_reduce_list(H, [DropInfo|L], PS, MonStatus);
                false ->
                    Rand = util:rand(1, 100),
                    Level = round(PS#player_status.lv - MonStatus#ets_mon.lv),
                    if
                        Level >= 8 andalso Level < 10 andalso Rand < 15 ->
                            filter_reduce_list(H, L, PS, MonStatus);
                        Level >= 10 andalso Level < 12 andalso Rand < 40 ->
                            filter_reduce_list(H, L, PS, MonStatus);
                        Level >= 12 andalso Level < 15 andalso Rand < 65 ->
                            filter_reduce_list(H, L, PS, MonStatus);
                        Level >= 15 andalso Rand < 80 ->
                            filter_reduce_list(H, L,PS, MonStatus);
                        true ->
                            filter_reduce_list(H, [DropInfo|L], PS, MonStatus)
                    end
            end;
        true ->
            filter_reduce_list(H, L, PS, MonStatus)
    end.

%% 处理掉落物品列表
handle_drop_list(PlayerStatus, MonStatus, DropRule, DropList) ->
    if  length(DropList) > 0 ->
            ExpireTime = util:unixtime() + ?GOODS_DROP_EXPIRE_TIME,
            [_, _, _, _, DropBin] = lists:foldl(fun handle_drop_item/2, [PlayerStatus, 
																		 MonStatus, 
																		 DropRule, 
																		 ExpireTime, 
																		 []], 
												DropList),
            %% 广播
            {ok, BinData} = pt_120:write(12017, [MonStatus#ets_mon.id, ?GOODS_DROP_EXPIRE_TIME, 
												 MonStatus#ets_mon.scene, DropBin, MonStatus#ets_mon.x, MonStatus#ets_mon.y]),
            case DropRule#ets_drop_rule.broad =:= 1 of
                true -> 
                    lib_server_send:send_to_scene(MonStatus#ets_mon.scene, MonStatus#ets_mon.copy_id, BinData);
                false when PlayerStatus#player_status.pid_team >0 -> 
                    lib_team:send_to_member(PlayerStatus#player_status.pid_team, BinData);
                false ->
                    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
            end;
        
        true -> 
            skip
    end.

%% 处理掉落物品
handle_drop_item(DropGoods, [PlayerStatus, MonStatus, DropRule, ExpireTime, DropBin]) ->
    PlayerId = PlayerStatus#player_status.id,
    GoodsTypeId = case DropGoods#ets_drop_goods.replace_list =/= [] of
                      true ->
                          TeamNum = lib_team:get_team_num_ets(PlayerStatus#player_status.pid_team),
                          case TeamNum =< 1 of
                              true -> 
                                  lists:nth(PlayerStatus#player_status.career, DropGoods#ets_drop_goods.replace_list);
                              false -> 
                                  DropGoods#ets_drop_goods.goods_id
                          end;
                      false -> 
                          DropGoods#ets_drop_goods.goods_id
                  end,
    GoodsNum = DropGoods#ets_drop_goods.num,
    DropId = mod_drop:get_drop_id(),
    GoodsDrop = #ets_drop{  id = DropId,
                            player_id = PlayerId,
                            team_id = PlayerStatus#player_status.pid_team,
                            scene = MonStatus#ets_mon.scene,
                            goods_id = GoodsTypeId,
                            num = DropGoods#ets_drop_goods.num,
                            stren = DropGoods#ets_drop_goods.stren,
                            prefix = DropGoods#ets_drop_goods.prefix,
                            bind = get_bind(DropGoods, PlayerStatus),
                            notice = DropGoods#ets_drop_goods.notice,
                            broad = DropRule#ets_drop_rule.broad,
                            expire_time = ExpireTime,
                            mon_id = MonStatus#ets_mon.mid,
                            mon_name = MonStatus#ets_mon.name
                         },
    mod_drop:add_drop(GoodsDrop),
    case lists:member(GoodsTypeId, DropRule#ets_drop_rule.counter_goods) of
        true ->
            case get_mon_goods_counter(GoodsTypeId) of
                [] -> skip;
                [Counter] ->
                    NowTime = util:unixdate(),
                    if  NowTime =/= Counter#ets_mon_goods_counter.time ->
                            mod_mon_goods_counter(Counter, 1, NowTime);
                        true ->
                            mod_mon_goods_counter(Counter, Counter#ets_mon_goods_counter.drop_num + 1, Counter#ets_mon_goods_counter.time)
                    end
            end;
        false -> skip
    end,
    Platform = pt:write_string(PlayerStatus#player_status.platform),
    ServerNum = PlayerStatus#player_status.server_num,
    [PlayerStatus, MonStatus, DropRule, ExpireTime, [<<DropId:32, GoodsTypeId:32, GoodsNum:32, PlayerId:32, Platform/binary, ServerNum:16>> | DropBin]].

%% 判断掉落物品的绑定
get_bind(GoodsDrop, PS) ->
    if
        GoodsDrop#ets_drop_goods.power_bind > 0 andalso PS#player_status.combat_power < GoodsDrop#ets_drop_goods.power_bind ->
            2;
        GoodsDrop#ets_drop_goods.recharge_bind > 0 andalso PS#player_status.is_pay =/= true ->
            2;
        GoodsDrop#ets_drop_goods.vip_bind > 0 andalso PS#player_status.vip#status_vip.vip_type =:= 0 ->
            2;
        GoodsDrop#ets_drop_goods.guild_bind > 0 andalso PS#player_status.guild#status_guild.guild_lv < GoodsDrop#ets_drop_goods.guild_bind ->
            2;
        true ->
            GoodsDrop#ets_drop_goods.bind
    end.

mod_mon_goods_counter(Counter, DropNum, Time) ->
    Sql = io_lib:format(?SQL_MON_GOODS_COUNTER_UPDATE2, [DropNum, Time, Counter#ets_mon_goods_counter.goods_id]),
    db:execute(Sql),
    NewCounter = Counter#ets_mon_goods_counter{drop_num = DropNum, time = Time},
    mod_disperse:cast_to_unite(ets, insert, [?ETS_MON_GOODS_COUNTER, NewCounter]),
    NewCounter.

%% 取ETS 怪物掉落物品计数器
get_mon_goods_counter(GoodsTypeId) ->
    case mod_disperse:call_to_unite(ets, lookup, [?ETS_MON_GOODS_COUNTER, GoodsTypeId]) of
        [Info] -> [Info];
        _ -> []
    end.

%% 取ETS 怪物物品掉落系数
get_drop_factor() ->
    case mod_disperse:call_to_unite(ets, lookup, [?ETS_DROP_FACTOR, 1]) of
        [Info] -> Info;
        _ -> #ets_drop_factor{}
    end.

%% 野外BOSS掉落
diablo_drop(PlayerList, MonStatus) ->
    Len = length(PlayerList),
    case data_drop:get_rule(MonStatus#ets_mon.mid) of
        %% 掉落规则不存在
        [] -> ok;
        _DropRule when Len =:= 0 -> ok;
        DropRule ->
            if  Len > 3 -> 
                    NewPlayerList = lists:sublist(PlayerList, 3);
                Len =:= 2 -> 
                    NewPlayerList = PlayerList ++ lists:sublist(PlayerList, 1);
                true -> 
                    NewPlayerList = PlayerList
            end,
            F = fun() ->
                    [StableGoods, _TaskGoods, RandGoods, _, _] = get_drop_goods_list(DropRule),
                    NowTime = util:unixdate(),
                    RandGoods2 = filter_goods(RandGoods, {NowTime, DropRule#ets_drop_rule.counter_goods}),
                    DropNumList = get_drop_num_list(DropRule),
                    DropGoods = drop_goods_list(RandGoods2, DropNumList),
                    DropList = StableGoods ++ DropGoods,
                    if  Len =:= 1 ->
                            [Player1 | _] = NewPlayerList,
                            alloc_drop(Player1, MonStatus, DropRule, DropList);
                        true ->
                            [Player1, Player2, Player3 | _] = NewPlayerList,
                            DropList1 = filter_reduce_list(DropList, [], Player1, MonStatus),
                            Len2 = length(DropList1),
                            if  Len2 =< 4 ->
                                    alloc_drop2(Player1, MonStatus, DropRule, lists:sublist(DropList1,2)),
                                    alloc_drop2(Player2, MonStatus, DropRule, lists:sublist(DropList1,3,1)),
                                    alloc_drop2(Player3, MonStatus, DropRule, lists:sublist(DropList1,4,1));
                                Len2 =:= 5 ->
                                    alloc_drop2(Player1, MonStatus, DropRule, lists:sublist(DropList1,2)),
                                    alloc_drop2(Player2, MonStatus, DropRule, lists:sublist(DropList1,3,2)),
                                    alloc_drop2(Player3, MonStatus, DropRule, lists:sublist(DropList1,5,1));
                                Len2 =:= 6 ->
                                    alloc_drop2(Player1, MonStatus, DropRule, lists:sublist(DropList1,2)),
                                    alloc_drop2(Player2, MonStatus, DropRule, lists:sublist(DropList1,3,2)),
                                    alloc_drop2(Player3, MonStatus, DropRule, lists:sublist(DropList1,5,2));
                                Len2 =:= 7 ->
                                    alloc_drop2(Player1, MonStatus, DropRule, lists:sublist(DropList1,3)),
                                    alloc_drop2(Player2, MonStatus, DropRule, lists:sublist(DropList1,4,2)),
                                    alloc_drop2(Player3, MonStatus, DropRule, lists:sublist(DropList1,6,2));
                                Len2 =:= 8 ->
                                    alloc_drop2(Player1, MonStatus, DropRule, lists:sublist(DropList1,3)),
                                    alloc_drop2(Player2, MonStatus, DropRule, lists:sublist(DropList1,4,3)),
                                    alloc_drop2(Player3, MonStatus, DropRule, lists:sublist(DropList1,7,2));
                                true ->
                                    Len13 = round(Len2 * 0.2),
                                    Len12 = round(Len2 * 0.3),
                                    Len11 = Len2 - Len12 - Len13,
                                    alloc_drop2(Player1, MonStatus, DropRule, lists:sublist(DropList1,Len11)),
                                    alloc_drop2(Player2, MonStatus, DropRule, lists:sublist(DropList1,Len11+1,Len12)),
                                    alloc_drop2(Player3, MonStatus, DropRule, lists:sublist(DropList1,Len11+Len12+1,Len13))
                            end
                    end
            end,
            lib_goods_util:transaction(F),
            ok
    end.

%% 处理单个掉落物品
handle_drop(Player, MonStatus, DropRule, DropGoods) ->
    PlayerId = Player#player_status.id,
    Platform = pt:write_string(Player#player_status.platform),
    ServerNum = Player#player_status.server_num,
    %GoodsTypeId = DropGoods#ets_drop_goods.goods_id,
    GoodsTypeId = case DropGoods#ets_drop_goods.replace_list =/= [] of
                      true ->
                          TeamNum = lib_team:get_team_num_ets(Player#player_status.pid_team),
                          case TeamNum =< 1 of
                              true -> 
                                  lists:nth(Player#player_status.career, DropGoods#ets_drop_goods.replace_list);
                              false -> 
                                  DropGoods#ets_drop_goods.goods_id
                          end;
                      false -> 
                          DropGoods#ets_drop_goods.goods_id
                  end,
    GoodsNum = DropGoods#ets_drop_goods.num,
    ExpireTime = util:unixtime() + ?GOODS_DROP_EXPIRE_TIME,
    DropId = mod_drop:get_drop_id(),
    GoodsDrop = #ets_drop{  id = DropId,
                            player_id = PlayerId,
                            team_id = Player#player_status.pid_team,
							copy_id = Player#player_status.copy_id,
                            scene = MonStatus#ets_mon.scene,
                            goods_id = GoodsTypeId,
                            num = DropGoods#ets_drop_goods.num,
                            stren = DropGoods#ets_drop_goods.stren,
                            prefix = DropGoods#ets_drop_goods.prefix,
                            bind = get_bind(DropGoods, Player),
                            notice = DropGoods#ets_drop_goods.notice,
                            broad = DropRule#ets_drop_rule.broad,
                            expire_time = ExpireTime,
                            mon_id = MonStatus#ets_mon.mid,
                            mon_name = MonStatus#ets_mon.name
                         },
    mod_drop:add_drop(GoodsDrop),
    case lists:member(GoodsTypeId, DropRule#ets_drop_rule.counter_goods) of
        true ->
            case get_mon_goods_counter(GoodsTypeId) of
                [] -> skip;
                [Counter] ->
                    NowTime = util:unixdate(),
                    if  NowTime =/= Counter#ets_mon_goods_counter.time ->
                            mod_mon_goods_counter(Counter, 1, NowTime);
                        true ->
                            mod_mon_goods_counter(Counter, Counter#ets_mon_goods_counter.drop_num + 1, Counter#ets_mon_goods_counter.time)
                    end
            end;
        false -> skip
    end,
    <<DropId:32, GoodsTypeId:32, GoodsNum:32, PlayerId:32, Platform/binary, ServerNum:16>>.

%% 广播
send_drop(Player, MonStatus, DropRule, DropBin) ->
    {ok, BinData} = pt_120:write(12017, [MonStatus#ets_mon.id, ?GOODS_DROP_EXPIRE_TIME, MonStatus#ets_mon.scene, DropBin, 0, 0]),
    case DropRule#ets_drop_rule.broad =:= 1 of
        true -> 
            lib_server_send:send_to_scene(MonStatus#ets_mon.scene, MonStatus#ets_mon.copy_id, BinData);
        false when Player#player_status.pid_team > 0-> 
            lib_team:send_to_member(Player#player_status.pid_team, BinData);
        false ->
            lib_server_send:send_to_sid(Player#player_status.sid, BinData)
    end.

%% 根据物品类型取掉落物品
get_drop_item([], _) -> null;
get_drop_item([{Type,Item}|DropGoods], GoodsTypeId) ->
    if  element(1, Item) =:= GoodsTypeId ->
            {Type, Item};
        true ->
            get_drop_item(DropGoods, GoodsTypeId)
    end.


