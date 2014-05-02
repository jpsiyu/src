%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-1-29
%% Description: 开宝箱
%% --------------------------------------------------------
-module(lib_box).
-export(
    [
        open/3,
        open/5,
        save_open/8,
        get_box_bag/1,
        mod_box_bag/2,
        init_counter/0,
        get_open_box_goods/2,
        get_box_goods_num/2,
        box_exchange/5,
        init_exchange_record/2
    ]
).
-include("common.hrl").
-include("record.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("box.hrl").
-include("server.hrl").

%% 开宝箱
open(PlayerStatus, BoxInfo, BoxNum) ->
    BoxId = BoxInfo#ets_box.id,
    BoxBag = get_box_bag(PlayerStatus),
    BoxCounter = get_box_counter(BoxId),
    PlayerCounter = get_box_player_counter(PlayerStatus#player_status.id, BoxId),
    %% 开宝箱
    NowTime = util:unixtime(),
    [NewBoxCounter, NewPlayerCounter, GoodsList] = open_box(BoxNum, [BoxInfo, BoxNum, PlayerStatus#player_status.career, NowTime, 0], [BoxCounter, PlayerCounter, []]),
    [NewBoxBag, GiveList, NoticeList] = add_goods(GoodsList, [BoxBag, [], []]),
    %% 事务处理扣费和添加物品
    Cost = case BoxNum of
                50 -> BoxInfo#ets_box.price3;
                10 -> BoxInfo#ets_box.price2;
                1 -> BoxInfo#ets_box.price;
                _ -> BoxInfo#ets_box.price * BoxNum
            end,
    F = fun() ->
            handle_counter(NewBoxCounter, NewPlayerCounter),
            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, gold),
            NewPlayerStatus2 = mod_box_bag(NewPlayerStatus, NewBoxBag),
            About = lists:concat([binary_to_list(BoxInfo#ets_box.name)," x",BoxNum]),
            log:log_consume(box_open, gold, PlayerStatus, NewPlayerStatus, About),
            ets:insert(?ETS_BOX_COUNTER, NewBoxCounter),
            ets:insert(?ETS_BOX_PLAYER_COUNTER, NewPlayerCounter),
            {ok, NewPlayerStatus2, GiveList, NoticeList}
        end,
    lib_goods_util:transaction(F).
open(PlayerStatus, BoxInfo, BoxNum, BoxBag, Bind) ->
    BoxId = BoxInfo#ets_box.id,
    BoxCounter = get_box_counter(BoxId),
    PlayerCounter = get_box_player_counter(PlayerStatus#player_status.id, BoxId),
    %% 开宝箱
    NowTime = util:unixtime(),
    [NewBoxCounter, NewPlayerCounter, GoodsList] = open_box(BoxNum, [BoxInfo, BoxNum, PlayerStatus#player_status.career, NowTime, 0], [BoxCounter, PlayerCounter, []]),
    [NewBoxBag, GiveList, NoticeList, _] = add_goods(GoodsList, [BoxBag, [], [], Bind]),
    handle_counter(NewBoxCounter, NewPlayerCounter),
    {ok, NewBoxBag, GiveList, NoticeList}.

%% 保存开宝箱的信息
save_open(PlayerStatus, GoodsStatus, BoxInfo, BoxNum, Cost, GoodsInfo, NewBoxBag, GiveList) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            case is_record(GoodsInfo, goods) of
                true ->
                    NewPlayerStatus = PlayerStatus,
                    {ok, NewStatus, _} = lib_goods:delete_one(GoodsStatus, GoodsInfo, 1),
                    log:log_goods_use(PlayerStatus#player_status.id, GoodsInfo#goods.goods_id, 1);
                false ->
                    NewStatus = GoodsStatus,
                    NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Cost, gold),
                    About = lists:concat([binary_to_list(BoxInfo#ets_box.name)," x",BoxNum]),
                    log:log_consume(box_open, gold, PlayerStatus, NewPlayerStatus, About)
            end,
            NewPlayerStatus2 = mod_box_bag(NewPlayerStatus, NewBoxBag),
            F1 = fun({GoodsTypeId, GoodsNum, Bind}) -> 
                         log:log_box(1, NewPlayerStatus#player_status.id, BoxInfo#ets_box.id, BoxNum, GoodsTypeId, GoodsNum, Bind) 
                 end,
            lists:foreach(F1, GiveList),
            Dict = lib_goods_dict:handle_dict(GoodsStatus#goods_status.dict),
            NewStatus1 = NewStatus#goods_status{dict = Dict},
            {ok, NewPlayerStatus2, NewStatus1}
        end,
    lib_goods_util:transaction(F).

%% 开宝箱操作
open_box(0, _, ResList) ->
    ResList;
open_box(Num, [BoxInfo, BoxNum, Career, NowTime, OpenHigh], [BoxCounter, PlayerCounter, GoodsList]) ->
    %% 计数加一
    [NewBoxCounter, NewPlayerCounter] = add_count(BoxCounter, PlayerCounter),
    %% 过滤物品列表
    BoxGoodsList = filter_goods(BoxInfo#ets_box.goods_list, [BoxInfo#ets_box.id, BoxNum, Career, NowTime, OpenHigh, BoxCounter, PlayerCounter]),
    %% 开宝箱物品
    case open_box_goods(BoxNum, BoxInfo, BoxGoodsList, PlayerCounter) of
        [] ->
            %% 再次循环
            open_box(Num-1, [BoxInfo, BoxNum, Career, NowTime, OpenHigh], [NewBoxCounter, NewPlayerCounter, GoodsList]);
        BoxGoods ->
            %% 更新计数器
            [NewBoxCounter2, NewPlayerCounter2] = update_counter(BoxGoods, NowTime, NewBoxCounter, NewPlayerCounter),
            NewOpenHigh = case BoxGoods#ets_box_goods.type =:= 1 of
                              true -> 1;
                              false -> OpenHigh
                          end,
            %% 再次循环
            open_box(Num-1, [BoxInfo, BoxNum, Career, NowTime, NewOpenHigh], [NewBoxCounter2, NewPlayerCounter2, [BoxGoods|GoodsList]])
    end.

%% 开宝箱物品
open_box_goods(BoxNum, BoxInfo, BoxGoodsList, PlayerCounter) ->
    if  PlayerCounter#ets_box_player_counter.guard =:= 0 
            andalso BoxNum >= 10
            andalso BoxInfo#ets_box.guard_num > 0
            andalso PlayerCounter#ets_box_player_counter.count >= BoxInfo#ets_box.guard_num ->
                Info = get_high_goods(BoxGoodsList);
            true ->
                Rand = util:rand(1, BoxInfo#ets_box.ratio),
                Info = find_goods(BoxGoodsList, Rand)
    end,
    case Info of
        [] -> 
            get_base_goods(BoxInfo);
        _ -> 
            Info
    end.

%% 取保底物品
get_base_goods(BoxInfo) ->
    Len = length(BoxInfo#ets_box.base_goods),
    case Len > 0 of
        true ->
            GoodsTypeId = lists:nth(util:rand(1, Len), BoxInfo#ets_box.base_goods),
            #ets_box_goods{box_id=BoxInfo#ets_box.id, goods_id=GoodsTypeId, goods_num = 1};
        false -> 
            []
    end.

%% 取高级物品
get_high_goods(BoxGoodsList) ->
    GoodsList = [BoxGoods || BoxGoods <- BoxGoodsList, BoxGoods#ets_box_goods.type =:= 1],
    Len = length(GoodsList),
    case Len > 0 of
        true -> 
            lists:nth(util:rand(1, Len), GoodsList);
        false -> 
            []
    end.


%% 处理计数器
handle_counter(BoxCounter, PlayerCounter) ->
    mod_box_counter(BoxCounter),
    mod_player_counter(PlayerCounter).

add_goods([BoxGoods|T], [BoxBag, GiveList, NoticeList, Bind]) ->
    GoodsTypeId = BoxGoods#ets_box_goods.goods_id,
    GoodsNum = BoxGoods#ets_box_goods.goods_num,
    %GoodsNum = 1,
    case data_goods_type:get(GoodsTypeId) of
        [] -> 
            add_goods(T, [BoxBag, GiveList, NoticeList, Bind]);
        GoodsTypeInfo ->
            NewNoticeList = case BoxGoods#ets_box_goods.notice =:= 1 of
                                true -> 
                                    [{GoodsTypeId, GoodsNum, GoodsTypeInfo#ets_goods_type.goods_name} | NoticeList];
                                false -> 
                                    NoticeList
                            end,
            NewBind = case Bind > 0 of
                          true -> 
                              Bind;
                          false -> 
                              BoxGoods#ets_box_goods.bind
                      end,
            NewGiveList = [{GoodsTypeId, GoodsNum, NewBind} | GiveList],
            NewBoxBag = add_bag(BoxBag, [GoodsTypeId, NewBind, GoodsNum, GoodsTypeInfo#ets_goods_type.max_overlap]),
            add_goods(T, [NewBoxBag, NewGiveList, NewNoticeList, Bind])
    end;
add_goods([], ResList) -> ResList.

add_bag([{Id,Num,Bind}|T], [Id2, Bind2, GoodsNum, Max]) when Id =/= Id2 ->
    [{Id,Num,Bind}|add_bag(T, [Id2, Bind2, GoodsNum, Max])];

add_bag([{Id,Num,Bind}|T], [Id, Bind2, GoodsNum, Max]) when Bind =/= Bind2 ->
    [{Id,Num,Bind}|add_bag(T, [Id, Bind2, GoodsNum, Max])];

add_bag([{Id,Num,Bind}|T], [Id, Bind, GoodsNum, Max]) when Num+GoodsNum >= Max ->
    [{Id,Num,Bind}|add_bag(T, [Id, Bind, GoodsNum, Max])];

add_bag([{Id,Num,Bind}|T], [_Id, _Bind, GoodsNum, _Max]) ->
    [{Id,Num+GoodsNum,Bind}|T];

add_bag([], [Id, Bind, GoodsNum, _]) ->
    [{Id,GoodsNum,Bind}].

%% 计数加一
add_count(BoxCounter, PlayerCounter) ->
    NewBoxCounter = BoxCounter#ets_box_counter{count = (BoxCounter#ets_box_counter.count + 1)},
    NewPlayerCounter = PlayerCounter#ets_box_player_counter{count = (PlayerCounter#ets_box_player_counter.count + 1)},
    [NewBoxCounter, NewPlayerCounter].

%% 更新计数器
update_counter(BoxGoods, NowTime, BoxCounter, PlayerCounter) ->
    LimitGoods1 = [{G1,T1} || {G1,T1} <- BoxCounter#ets_box_counter.limit_goods, NowTime < T1],
    if  BoxGoods#ets_box_goods.lim_box > 0 ->
            LimitGoods2 = [{BoxGoods#ets_box_goods.goods_id, (NowTime + BoxGoods#ets_box_goods.lim_box * 3600)} | LimitGoods1],
            NewBoxCounter = BoxCounter#ets_box_counter{limit_goods = LimitGoods2};
        true -> 
            NewBoxCounter = BoxCounter
    end,
    LimitGoods3 = [{G2,T2,C2} || {G2,T2,C2} <- PlayerCounter#ets_box_player_counter.limit_goods, NowTime < T2 orelse PlayerCounter#ets_box_player_counter.count < C2],
    if  BoxGoods#ets_box_goods.lim_player > 0 andalso BoxGoods#ets_box_goods.lim_num > 0 ->
            LimitGoods4 = [{BoxGoods#ets_box_goods.goods_id, (NowTime + BoxGoods#ets_box_goods.lim_player), (PlayerCounter#ets_box_player_counter.count + BoxGoods#ets_box_goods.lim_num)} | LimitGoods3],
            NewPlayerCounter = PlayerCounter#ets_box_player_counter{limit_goods = LimitGoods4};
        BoxGoods#ets_box_goods.lim_player > 0 ->
            LimitGoods4 = [{BoxGoods#ets_box_goods.goods_id, (NowTime + BoxGoods#ets_box_goods.lim_player), 0} | LimitGoods3],
            NewPlayerCounter = PlayerCounter#ets_box_player_counter{limit_goods = LimitGoods4};
        BoxGoods#ets_box_goods.lim_num > 0 ->
            LimitGoods4 = [{BoxGoods#ets_box_goods.goods_id, 0, (PlayerCounter#ets_box_player_counter.count + BoxGoods#ets_box_goods.lim_num)} | LimitGoods3],
            NewPlayerCounter = PlayerCounter#ets_box_player_counter{limit_goods = LimitGoods4};
        true -> 
            NewPlayerCounter = PlayerCounter
    end,
    if  BoxGoods#ets_box_goods.type =:= 1 andalso NewPlayerCounter#ets_box_player_counter.guard =:= 0 ->
            NewPlayerCounter2 = NewPlayerCounter#ets_box_player_counter{guard=1};
        true -> 
            NewPlayerCounter2 = NewPlayerCounter
    end,
    [NewBoxCounter, NewPlayerCounter2].

%% 过滤物品列表
filter_goods([], _) -> [];
filter_goods([{GoodsTypeId, GoodsNum}|L], [BoxId, BoxNum, Career, NowTime, OpenHigh, BoxCounter, PlayerCounter]) ->
    BoxGoods = data_box:get_box_goods(BoxId, GoodsTypeId, GoodsNum),
    %% 机率为0
    Filter1 = (BoxGoods#ets_box_goods.ratio =:= 0),
    %% 单次宝箱限制
    case Filter1 =:= false andalso BoxNum =:= 1 andalso BoxGoods#ets_box_goods.type =:= 1 of
        true -> 
            Filter2 = true;
        false -> 
            Filter2 = Filter1
    end,
    %% 单批宝箱限制
    case Filter2 =:= false andalso OpenHigh =:= 1 andalso BoxGoods#ets_box_goods.type =:= 1 of
        true -> 
            Filter3 = true;
        false -> 
            Filter3 = Filter2
    end,
    %% 职业限制
    case Filter3 =:= false andalso BoxGoods#ets_box_goods.lim_career > 0 of
        true ->
            case BoxGoods#ets_box_goods.lim_career =/= Career of
                    true -> 
                        Filter4 = true;
                    false -> 
                        Filter4 = Filter3
            end;
        false -> 
            Filter4 = Filter3
    end,
    %% 个人限制
    case Filter4 =:= false andalso BoxGoods#ets_box_goods.lim_player > 0 of
        true ->
            case lists:keyfind(GoodsTypeId, 1, PlayerCounter#ets_box_player_counter.limit_goods) of
                {_, LimitTime5, _} when NowTime =< LimitTime5 ->
                    Filter5 = true;
                _ -> 
                    Filter5 = Filter4
            end;
        false -> 
            Filter5 = Filter4
    end,
    %% 次数限制
    case Filter5 =:= false andalso BoxGoods#ets_box_goods.lim_num > 0 of
        true ->
            case lists:keyfind(GoodsTypeId, 1, PlayerCounter#ets_box_player_counter.limit_goods) of
                {_, _, LimitNum6} when PlayerCounter#ets_box_player_counter.count =< LimitNum6 ->
                    Filter6 = true;
                _ -> 
                    Filter6 = Filter5
            end;
        false -> 
            Filter6 = Filter5
    end,
    %% 全服限制
    case Filter6 =:= false andalso BoxGoods#ets_box_goods.lim_box > 0 of
        true ->
            case lists:keyfind(GoodsTypeId, 1, BoxCounter#ets_box_counter.limit_goods) of
                {_, LimitTime7} when NowTime =< LimitTime7 ->
                    Filter7 = true;
                _ -> 
                    Filter7 = Filter6
            end;
        false -> 
            Filter7 = Filter6
    end,
    case Filter7 of
        true -> 
            filter_goods(L, [BoxId, BoxNum, Career, NowTime, OpenHigh, BoxCounter, PlayerCounter]);
        false -> 
            [BoxGoods | filter_goods(L, [BoxId, BoxNum, Career, NowTime, OpenHigh, BoxCounter, PlayerCounter])]
    end.

%% 查找匹配机率的值
find_goods(_, 0) -> [];
find_goods([Info|T], Rand) ->
    case Rand >= Info#ets_box_goods.ratio_start andalso Rand =< Info#ets_box_goods.ratio_end of
        true -> 
            Info;
        false -> 
            find_goods(T, Rand)
    end;
find_goods([], _) -> [].

%% 取宝箱计数器
get_box_counter(BoxId) ->
    case ets:lookup(?ETS_BOX_COUNTER, BoxId) of
        [BoxCounter] -> 
            BoxCounter;
        [] -> 
            add_box_counter(BoxId)
    end.

%% 取玩家计数器
get_box_player_counter(PlayerId, BoxId) ->
    case ets:lookup(?ETS_BOX_PLAYER_COUNTER, PlayerId) of
        [PlayerCounter] -> 
            PlayerCounter;
        [] -> 
            add_player_counter(PlayerId, BoxId)
    end.

%% 添加宝箱计数器
add_box_counter(BoxId) ->
    Sql = io_lib:format(?SQL_BOX_COUNTER_INSERT, [BoxId]),
    db:execute(Sql),
    BoxCounter = #ets_box_counter{box_id = BoxId},
    ets:insert(?ETS_BOX_COUNTER, BoxCounter),
    BoxCounter.

%% 更新宝箱计数器
mod_box_counter(BoxCounter) ->
    Sql = io_lib:format(?SQL_BOX_COUNTER_UPDATE, [BoxCounter#ets_box_counter.count, util:term_to_string(BoxCounter#ets_box_counter.limit_goods), BoxCounter#ets_box_counter.box_id]),
    db:execute(Sql),
    ets:insert(?ETS_BOX_COUNTER, BoxCounter).

%% 添加玩家计数器
add_player_counter(PlayerId, BoxId) ->
    Sql = io_lib:format(?SQL_BOX_PLAYER_COUNTER_INSERT, [PlayerId, BoxId]),
    db:execute(Sql),
    PlayerCounter = #ets_box_player_counter{pid=PlayerId, box_id=BoxId},
    ets:insert(?ETS_BOX_PLAYER_COUNTER, PlayerCounter),
    PlayerCounter.

%% 更新玩家计数器
mod_player_counter(PlayerCounter) ->
    Sql = io_lib:format(?SQL_BOX_PLAYER_COUNTER_UPDATE, [PlayerCounter#ets_box_player_counter.count, PlayerCounter#ets_box_player_counter.guard, util:term_to_string(PlayerCounter#ets_box_player_counter.limit_goods), PlayerCounter#ets_box_player_counter.pid, PlayerCounter#ets_box_player_counter.box_id]),
    db:execute(Sql),
    ets:insert(?ETS_BOX_PLAYER_COUNTER, PlayerCounter).

%% 取宝箱包裹
get_box_bag(PlayerStatus) ->
    case PlayerStatus#player_status.box_bag of
        null -> 
            add_box_bag(PlayerStatus#player_status.id);
        BoxBag -> 
            BoxBag
    end.

%% 添加宝箱包裹
add_box_bag(PlayerId) ->
    Sql = io_lib:format(?SQL_BOX_BAG_SELECT, [PlayerId]),
    case db:get_row(Sql) of
        [] ->
            Sql2 = io_lib:format(?SQL_BOX_BAG_INSERT, [PlayerId]),
            db:execute(Sql2),
            [];
        [Mgoods_list] ->
            lib_goods_util:to_term(Mgoods_list)
    end.

%% 更新宝箱包裹
mod_box_bag(PlayerStatus, GoodsList) ->
    Sql = io_lib:format(?SQL_BOX_BAG_UPDATE, [util:term_to_string(GoodsList), PlayerStatus#player_status.id]),
    db:execute(Sql),
    PlayerStatus#player_status{box_bag = GoodsList}.

%% 获得淘宝背包里面物品数量
get_box_goods_num(PlayerStatus, GoodsTypeId) ->
    NewBag = get_box_bag(PlayerStatus),
    case PlayerStatus#player_status.box_bag of
        null ->
            filter_bag_goods(NewBag, GoodsTypeId, 0);
        BoxBag ->
            filter_bag_goods(BoxBag, GoodsTypeId, 0)
    end.

filter_bag_goods([], _, N) ->
    N;
filter_bag_goods([{GoodsTypeId, Num, _}|H], GoodsId, N) ->
    if
        GoodsTypeId =:= GoodsId ->
            filter_bag_goods(H, GoodsId, N + Num);
        true ->
            filter_bag_goods(H, GoodsId, N)
    end.

%% 初始化宝箱计数器
init_counter() ->
    %% 宝箱计数器
    F = fun([Mbox_id, Mcount, Mlimit_goods]) ->
                CounterInfo = #ets_box_counter{
                                    box_id = Mbox_id,
                                    count = Mcount,
                                    limit_goods = lib_goods_util:to_term(Mlimit_goods)
                            },
                ets:insert(?ETS_BOX_COUNTER, CounterInfo)
         end,
    case db:get_all(?SQL_BOX_COUNTER_SELECT_ALL) of
        [] -> skip;
        CounterList when is_list(CounterList) ->
            lists:foreach(F, CounterList);
        _ -> skip
    end,
    %% 玩家计数器
    F2 = fun([Mpid, Mbox_id, Mcount, Mguard, Mlimit_goods]) ->
                CounterInfo2 = #ets_box_player_counter{
                                    pid = Mpid,
                                    box_id = Mbox_id,
                                    count = Mcount,
                                    guard = Mguard,
                                    limit_goods = lib_goods_util:to_term(Mlimit_goods)
                             },
                ets:insert(?ETS_BOX_PLAYER_COUNTER, CounterInfo2)
         end,
    case db:get_all(?SQL_BOX_PLAYER_COUNTER_SELECT_ALL) of
        [] -> 
            skip;
        CounterList2 when is_list(CounterList2) ->
            lists:foreach(F2, CounterList2);
        _ -> skip
    end,
    ok.

%% 取开宝箱元宝替代物品
get_open_box_goods(BoxId, BoxNum) ->
    if  BoxId =:= 1 andalso BoxNum =:= 1 -> 612802;
        BoxId =:= 2 andalso BoxNum =:= 1 -> 612803;
        BoxId =:= 3 andalso BoxNum =:= 1 -> 612804;
        true -> 0
    end.

%% 兑换
box_exchange(PlayerStatus, Stone, EquipTypeInfo, Pos, GoodsStatus) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            if Pos =:= 0 ->
                NewStatus1 = GoodsStatus,
                StoneTypeId = Stone,
                GoodsId = 0,
                %%更新宝箱数量
                NewPlayerStatus = change_box_exchange_num(Stone, PlayerStatus);
            true ->
                NewPlayerStatus = PlayerStatus,
                GoodsId = Stone#goods.id,
                StoneTypeId = Stone#goods.goods_id,
                %% 删除物品
                [NewStatus1, _] = lib_goods:delete_one(Stone, [GoodsStatus,1])
            end,
            %% 添加物品
            Info = lib_goods_util:get_new_goods(EquipTypeInfo),
            [Cell|NullCells] = NewStatus1#goods_status.null_cells,
            NewGoodsStatus = NewStatus1#goods_status{null_cells = NullCells},
            %% 取玩家身上同类型物品
            SameEquipStren = case NewGoodsStatus#goods_status.dict =:= [] of 
                false ->
                    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.type=:=Info#goods.type andalso Value#goods.subtype =:= Info#goods.subtype andalso Value#goods.equip_type =:= Info#goods.equip_type andalso Value#goods.location=:= ?GOODS_LOC_EQUIP end, NewGoodsStatus#goods_status.dict),
                    DictList = dict:to_list(Dict1),
                    SameEquipList = lib_goods_dict:get_list(DictList, []),
                    case SameEquipList =:= [] of 
                        true -> 0;
                        false ->
                            [One | _] = SameEquipList,
                            One#goods.stren 
                    end;
                true ->
                    0
            end,
            GoodsInfo = Info#goods{player_id = PlayerStatus#player_status.id, location = ?GOODS_LOC_BAG, cell=Cell, num=1, bind=2, trade=1, prefix=3, first_prefix=1, color = 3, stren = SameEquipStren},
            [NewGoodsInfo, NewGoodsStatus1] = lib_goods_compose:add_goods(GoodsInfo, NewGoodsStatus),
            log:log_box_exchange(PlayerStatus#player_status.id, StoneTypeId, 1, NewGoodsInfo#goods.goods_id),
            %% 消耗
            log:log_throw(box_exchange, PlayerStatus#player_status.id, GoodsId, StoneTypeId, 1, 0, 0),
            %% 产出
            log:log_goods(box_exchange, NewGoodsInfo#goods.subtype, NewGoodsInfo#goods.goods_id, 1, PlayerStatus#player_status.id),
            Dict = lib_goods_dict:handle_dict(NewGoodsStatus1#goods_status.dict),
            NewGoodsStatus2 = NewGoodsStatus1#goods_status{dict = Dict},
            {ok, NewPlayerStatus, NewGoodsStatus2, NewGoodsInfo}
    end,
    lib_goods_util:transaction(F).

%%更新宝箱数量 
change_box_exchange_num(GoodsTypeId, PlayerStatus) ->
    Bag = PlayerStatus#player_status.box_bag,
    NewBag = bag_delete_goods(Bag, GoodsTypeId),
    mod_box_bag(PlayerStatus, NewBag).

%% 修改宝箱列表
bag_delete_goods(Bag, GoodsTypeId) ->
    L = get_bag_member(Bag, GoodsTypeId),
    case L of
        {0,0,0} ->
            Bag;
        {TypeId, Num, Bind} when Num > 1 ->
            lists:keyreplace(GoodsTypeId, 1, Bag, {TypeId, Num - 1, Bind});
        {_TypeId, Num, _Bind} when Num =< 1 ->
            lists:delete(L, Bag);
        _ ->
            Bag
    end.
                                                                                                                
%% 获取宝箱记录
get_bag_member([], _) ->
    {0,0,0};
get_bag_member([{GoodsTypeId, Num, Bind}|H], GoodsId) ->
    if
        GoodsTypeId =:= GoodsId ->
            {GoodsTypeId, Num, Bind};
        true ->
            get_bag_member(H, GoodsId)
    end.

%% 初始化兑换记录
init_exchange_record(Id, Dict) ->
   Sql = io_lib:format(?sql_select_exchange, [Id]),
    case db:get_all(Sql) of
        [] ->
            Dict2 = Dict;
        List when is_list(List) ->
            Info = make_exchange_info(Id, List),
            Dict2 = lib_mount:add_dict(Id, Info, Dict);
        _ ->
            Dict2 = Dict
    end,
    Dict2.

make_exchange_info(Id, List) ->
    case List of
        [[TypeList, GiftList]] ->
            if
                GiftList =:= <<>> ->
                    NewGiftList = [];
                true ->
                    NewGiftList = util:bitstring_to_term(GiftList)
            end,
            if
                TypeList =:= <<>> ->
                    NewTypeList = [];
                true ->
                    NewTypeList = util:bitstring_to_term(TypeList)
            end,
            Exchange = #ets_box_exchange{
                pid = Id,
                type_list = NewTypeList,
                gift_list = NewGiftList
            };
        _ ->
            Exchange = #ets_box_exchange{}
    end,
    Exchange.
