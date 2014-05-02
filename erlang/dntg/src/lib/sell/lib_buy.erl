%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-8
%% Description: 交易市场求购操作类
%% --------------------------------------------------------
-module(lib_buy).
-include("common.hrl").
-include("unite.hrl").
-include("goods.hrl").
-include("server.hrl").
-include("sell.hrl").
-export(
    [
        list_buy/7,
        self_list/1,
        self_list_count/1,
        buy_up/2,
        buy_down/2,
        buy_clean/0,
        del_buy_base/1,
        update_buy_num/2,
        reload_buy/1,
        init_buy/0
    ]
).
-define(PAGE_SIZE,  6).  %% 每页显示条数
-define(GOODS_WTB_LIST_MAX_NUM,     30).    %% 求购列表最大物品数

%% 查询求购列表
list_buy(Class1, Class2, Page, Lv, Color, Career, <<>>) ->
    case Class1 of
        %% 全部
        0 ->
            if  Lv > 0 orelse Color > 0 orelse Career > 0 ->
                    Pattern = #ets_buy{_='_'},
                    NewPattern = get_search_pattern(Pattern, Lv, Color, Career),
                    Totals = ets:select_count(?ETS_BUY, [{NewPattern, [], [true]}]),
                    case Totals > 0 of
                        true -> get_page_list2(NewPattern, Totals, Page);
                        false -> {ok, 0, []}
                    end;
                true ->
                    Pattern = #ets_buy{_='_'},
                    Totals = get_est_size(?ETS_BUY),
                    case Totals > 0 of
                        true -> get_page_list2(Pattern, Totals, Page);
                        false -> {ok, 0, []}
                    end
            end;
        _ ->
            Pattern = #ets_buy{class1 = Class1, class2 = Class2, _='_'},
            NewPattern = get_search_pattern(Pattern, Lv, Color, Career),
            Totals = ets:select_count(?ETS_BUY, [{NewPattern, [], [true]}]),
            case Totals > 0 of
                true -> get_page_list2(NewPattern, Totals, Page);
                false -> {ok, 0, []}
            end
    end;
list_buy(Class1, Class2, Page, Lv, Color, Career, Str) ->
    case Class1 of
        %% 全部
        0 -> Pattern = #ets_buy{_='_'};
        _ -> Pattern = #ets_buy{class1 = Class1, class2 = Class2, _='_'}
    end,
    NewPattern = get_search_pattern(Pattern, Lv, Color, Career),
    WtbList = ets:match_object(?ETS_BUY, NewPattern),
    NewWtbList = get_search_list(WtbList, Str),
    Totals = length(NewWtbList),
    case Totals > 0 of
        true ->
            TotalPage = util:ceil(Totals / ?PAGE_SIZE),
            {ok, TotalPage, get_page_list(NewWtbList, Totals, Page)};
        false ->
            {ok, 0, []}
     end.

get_search_pattern(Pattern, Lv, Color, Career) ->
    case Lv > 0 of
        true ->  Pattern1 = Pattern#ets_buy{lv_num = Lv};
        false -> Pattern1 = Pattern
    end,
    case Color > 0 of
        true ->  Pattern2 = Pattern1#ets_buy{color = (Color-1)};
        false -> Pattern2 = Pattern1
    end,
    case Career > 0 of
        true ->  Pattern3 = Pattern2#ets_buy{career = Career};
        false -> Pattern3 = Pattern2
    end,
    Pattern3.

get_search_list(WtbList, Str) ->
    case Str of
        <<>> -> WtbList;
        _ ->
            F = fun(Info) -> binary:match(Info#ets_buy.goods_name, Str) =/= nomatch end,
            lists:filter(F, WtbList)
    end.

get_page_list2(Pattern, Totals, Page) ->
    TotalPage = util:ceil(Totals / ?PAGE_SIZE),
    NewPage = case Page > TotalPage of true -> TotalPage; false -> Page end,
    {ok, TotalPage, get_ets_list(Pattern, NewPage)}.

get_page_list(WtbList, Totals, Page) ->
    case WtbList of
        [] -> [];
        _ ->
            Star = Totals - Page * ?PAGE_SIZE + 1,
            rsublist(WtbList, 1, Star, Star + ?PAGE_SIZE, [])
    end.

get_ets_list(Pattern, Page) ->
    get_ets_list2(Page-1, ets:select_reverse(?ETS_BUY, [{Pattern, [], ['$_']}], ?PAGE_SIZE)).

get_ets_list2(0, {R,_}) -> R;
get_ets_list2(_, {_,'$end_of_table'}) -> [];
get_ets_list2(Page, {_,C}) ->
    get_ets_list2(Page-1, ets:select_reverse(C)).

get_est_size(Tab) ->
    case ets:info(Tab, size) of
        undefined -> 0;
        Size -> Size
    end.

rsublist(_, N, _, End, L) when N >= End -> L;
rsublist([H|T], N, Start, End, L) when N >= Start ->
    rsublist(T, N+1, Start, End, [H|L]);
rsublist([_|T], N, Start, End, L) ->
    rsublist(T, N+1, Start, End, L);
rsublist([], _, _, _, L) -> L.

%% 自身求购列表
self_list(PlayerId) ->
    Pattern = #ets_buy{pid=PlayerId,  _='_'},
    ets:select_reverse(?ETS_BUY, [{Pattern, [], ['$_']}]).

%% 自身求购列表数量
self_list_count(PlayerId) ->
    Pattern = #ets_buy{pid=PlayerId,  _='_'},
    ets:select_count(?ETS_BUY, [{Pattern, [], [true]}]).

%% 求购物品上架
buy_up(PlayerStatus, [GoodsTypeId, Num, Prefix, Stren, PriceType, Price, Time]) ->
    case check_buy_up(PlayerStatus, [GoodsTypeId, Num, Prefix, Stren, PriceType, Price, Time]) of
        {fail, Res} -> {fail, Res};
        {ok, WtbInfo, Cost} ->
            F = fun() ->
                        %% Buy求购, Price:价格, Time:时长
                    About = lists:concat(["Buy ",binary_to_list(WtbInfo#ets_buy.goods_name)," x",WtbInfo#ets_buy.num," 价格：",WtbInfo#ets_buy.price," 时长：",WtbInfo#ets_buy.time]),
                    %% 扣钱
                    PlayerStatus1 = lib_goods_util:cost_money(PlayerStatus, Cost, coin),
                    log:log_consume(buy_fee, coin, PlayerStatus, PlayerStatus1, About),
                    Money = Price * Num,
                    case PriceType =:= 1 of
                        true ->
                            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus1, Money, gold),
                            log:log_consume(buy_up, gold, PlayerStatus1, NewPlayerStatus, About);
                        false ->
                            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus1, Money, rcoin),
                            log:log_consume(buy_up, rcoin, PlayerStatus1, NewPlayerStatus, About)
                    end,
                    NewWtbInfo = add_buy_base(WtbInfo),
                    log:log_buy(1, NewWtbInfo, 0, 0),
                    {ok, NewPlayerStatus, NewWtbInfo}
                end,
            lib_goods_util:transaction(F)
    end.

%% 检查求购物品
check_buy_up(PlayerStatus, [GoodsTypeId, Num, Prefix, Stren, PriceType, Price, Time]) ->
    GoodsTypeInfo = data_goods_type:get(GoodsTypeId),
    Sell = PlayerStatus#player_status.sell,
    if  %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 12};
        %% 物品不存在
        is_record(GoodsTypeInfo, ets_goods_type) =:= false ->
            {fail, 2};
        %% 物品不可求购
        GoodsTypeInfo#ets_goods_type.search =:= 0 ->
            {fail, 3};
        %% 数量错误
        Num < 1 ->
            {fail, 4};
        %% 数量错误
        GoodsTypeInfo#ets_goods_type.max_overlap =< 1 andalso Num =/= 1 ->
            {fail, 4};
        %% 数量错误
        GoodsTypeInfo#ets_goods_type.max_overlap > 1 andalso Num > GoodsTypeInfo#ets_goods_type.max_overlap ->
            {fail, 4};
        %% 前缀错误
        Prefix < 0 orelse Prefix > 3 ->
            {fail, 5};
        %% 强化数错误
        Stren < 0 orelse Stren > 10 ->
            {fail, 6};
        %% 价格错误
        (PriceType =/= 0 andalso PriceType =/= 1) orelse Price < 1 orelse Price > 99999999 ->
            {fail, 7};
        %% 时长错误
        Time =/= 6 andalso Time =/= 12 andalso Time =/= 24 ->
            {fail, 8};
        true ->
            Cost = data_goods:count_buy_cost(PriceType, Price, Time) * Num,
            Remain = case PriceType of
                         0 -> PlayerStatus#player_status.coin - (Price * Num);
                         1 -> PlayerStatus#player_status.gold - (Price * Num)
                     end,
            if  %% 手续费不足
                PriceType =:= 0 andalso (Remain + PlayerStatus#player_status.bcoin) < Cost ->
                    {fail, 9};
                %% 手续费不足
                PriceType =:= 1 andalso (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Cost ->
                    {fail, 9};
                %% 手续费不足
                Remain < 0 ->
                    {fail, 9};
                true ->
                    case mod_disperse:call_to_unite(lib_buy, self_list_count, [PlayerStatus#player_status.id]) of
                        %% 公共线错误
                        {badrpc,_Reason} -> {fail, 10};
                        [] -> {fail, 10};
                        %% 求购物品数量已达上限
                        MaxNum when is_number(MaxNum) andalso MaxNum >= ?GOODS_WTB_LIST_MAX_NUM ->
                            {fail, 11};
                        _ ->
                            Lv_num = data_goods:get_equip_level(GoodsTypeInfo#ets_goods_type.level),
                            EndTime = util:unixtime() + Time*3600,
                            SellClass = data_sell:get_sell_class(GoodsTypeInfo#ets_goods_type.type, GoodsTypeInfo#ets_goods_type.subtype, GoodsTypeInfo#ets_goods_type.career, GoodsTypeInfo#ets_goods_type.sex),
                            {Class1, Class2} = {SellClass#ets_sell_class.max_type, SellClass#ets_sell_class.min_type},
                            WtbInfo = #ets_buy{class1=Class1, class2=Class2, pid=PlayerStatus#player_status.id, goods_id=GoodsTypeId, goods_name = GoodsTypeInfo#ets_goods_type.goods_name, num=Num, type=GoodsTypeInfo#ets_goods_type.type, subtype=GoodsTypeInfo#ets_goods_type.subtype, lv=GoodsTypeInfo#ets_goods_type.level, lv_num=Lv_num, color=GoodsTypeInfo#ets_goods_type.color, career=GoodsTypeInfo#ets_goods_type.career, prefix=Prefix, stren=Stren, price_type=PriceType, price=Price, time=Time, end_time=EndTime},
                            {ok, WtbInfo, Cost}
                    end
            end
    end.

%% 取消求购
buy_down(PlayerStatus, Id) ->
    case check_buy_down(PlayerStatus, Id) of
        {fail, Res} -> {fail, Res};
        {ok, WtbInfo} ->
            case mod_disperse:call_to_unite(mod_buy, call_buy_down, [Id]) of
                {badrpc, _} -> {fail, 0};
                {fail, Res2} -> {fail, Res2};
                ok ->
                    case lib_goods_sell:buy_down(PlayerStatus, WtbInfo) of
                        {fail, Res3} -> {fail, Res3};
                        {ok, NewPlayerStatus} -> {ok, NewPlayerStatus};
                        _ -> {fail, 0}
                    end;
                _ -> {fail, 0}
            end
    end.

%% 检查求购物品
check_buy_down(PlayerStatus, Id) ->
    case mod_disperse:call_to_unite(ets, lookup, [?ETS_BUY, Id]) of
        %% 没有找到该记录
        [] -> {fail, 2};
        [WtbInfo] ->
            if  is_record(WtbInfo, ets_buy) =:= false ->
                    {fail, 2};
                %% 不属于你的求购记录
                WtbInfo#ets_buy.pid =/= PlayerStatus#player_status.id ->
                    {fail, 3};
                true ->
                    {ok, WtbInfo}
            end;
         _ -> {fail, 0}
    end.

%% 过期清理
buy_clean() ->
    NowTime = util:unixtime(),
    Pattern = #ets_buy{end_time = '$1', _='_'},
    WtbList = ets:select(?ETS_BUY, [{Pattern, [{'=<', '$1', NowTime}], ['$_']}]),
    ets:select_delete(?ETS_BUY, [{Pattern, [{'=<', '$1', NowTime}], [true]}]),
    List = clean_up(WtbList, []),
    spawn(fun() -> lists:foreach(fun send_notice/1, List) end).

clean_up([H|T],L) ->
    NewL = case lists:keyfind(H#ets_buy.pid, 1, L) of
                false -> [{H#ets_buy.pid, [H]}|L];
                {Id,L2} -> lists:keyreplace(Id, 1, L, {Id, [H|L2]})
            end,
    clean_up(T,NewL);
clean_up([], L) -> L.

send_notice({PlayerId, WtbList}) ->
    case (catch lib_goods_sell:buy_expire(WtbList)) of
        {ok, MailList} ->
            case mod_chat_agent:lookup(PlayerId) of
                [] -> skip;
                [_Player] -> 
                    Title = data_sell_text:mail_sys(),
                    mod_disperse:cast_to_unite(mod_mail, update_mail_info, [PlayerId, MailList, Title])
            end;
        Error ->
            ?INFO("lib_goods_sell buy_expire:~p", [Error])
    end,
    timer:sleep(1000).


%% 添加求购记录
add_buy_base(WtbInfo) ->
    Sql = io_lib:format(<<"insert into `buy_list` set `class1`=~p, `class2`=~p, `pid`=~p, `goods_id`=~p, `goods_name`='~s', `num`=~p, `type`=~p, `subtype`=~p, `lv`=~p, `lv_num`=~p, `color`=~p, `career`=~p, `prefix`=~p, `stren`=~p, `price_type`=~p, `price`=~p, `time`=~p, `end_time`=~p ">>,
        [WtbInfo#ets_buy.class1, WtbInfo#ets_buy.class2, WtbInfo#ets_buy.pid, WtbInfo#ets_buy.goods_id, WtbInfo#ets_buy.goods_name, WtbInfo#ets_buy.num, WtbInfo#ets_buy.type, WtbInfo#ets_buy.subtype, WtbInfo#ets_buy.lv, WtbInfo#ets_buy.lv_num, WtbInfo#ets_buy.color, WtbInfo#ets_buy.career, WtbInfo#ets_buy.prefix, WtbInfo#ets_buy.stren, WtbInfo#ets_buy.price_type, WtbInfo#ets_buy.price, WtbInfo#ets_buy.time, WtbInfo#ets_buy.end_time]),
    db:execute(Sql),
    Id = db:get_one(<<"SELECT LAST_INSERT_ID() ">>),
    WtbInfo#ets_buy{id=Id}.

%% 删除求购记录
del_buy_base(Id) ->
    Sql = io_lib:format(?sql_buy_delete, [Id]),
    db:execute(Sql).

%% 更新求购数量
update_buy_num(WtbInfo, Num) ->
    Sql = io_lib:format(?sql_buy_update, [Num, WtbInfo#ets_buy.id]),
    db:execute(Sql),
    WtbInfo#ets_buy{num = Num}.

%% 重载记录
reload_buy(Id) ->
    Sql = io_lib:format(?sql_buy_select, [Id]),
    Data = db:get_row(Sql),
    make_buy(Data).


%% 初始化求购市场
init_buy() ->
    ets:delete_all_objects(?ETS_BUY),
    F = fun(Data) ->
            WtbInfo = make_buy(Data),
            ets:insert(?ETS_BUY, WtbInfo)
        end,
    Sql = ?sql_buy_select2,
    case db:get_all(Sql) of
        [] -> skip;
        WtbList when is_list(WtbList) ->
            lists:foreach(F, WtbList);
        _ -> skip
    end,
    ok.

make_buy(Info) ->
    case Info of
        [Mid, Mclass1, Mclass2, Mpid, Mgoods_id, Mgoods_name, Mnum, Mtype, Msubtype, Mlv, Mlv_num, Mcolor, Mcareer, Mprefix, Mstren, Mprice_type, Mprice, Mtime, Mend_time] ->
            #ets_buy{
                id = Mid,
                class1 = Mclass1,
                class2 = Mclass2,
                pid = Mpid,
                goods_id = Mgoods_id,
                goods_name = Mgoods_name,
                num = Mnum,
                type = Mtype,
                subtype = Msubtype,
                lv = Mlv,
                lv_num = Mlv_num,
                color = Mcolor,
                career = Mcareer,
                prefix = Mprefix,
                stren = Mstren,
                price_type = Mprice_type,
                price = Mprice,
                time = Mtime,
                end_time = Mend_time
           };
        _ -> []
    end.




