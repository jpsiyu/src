%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-7
%% Description: 交易市场操作类
%% --------------------------------------------------------
-module(lib_sell).
-include("common.hrl").
-include("def_goods.hrl").
-include("goods.hrl").
-include("unite.hrl").
-include("sell.hrl").
-export(
    [
        get_sell/1,
        list_sell/7,
        sell_up/2,
        sell_down/1,
        clean_up/0,
        resell/1,
        test_expire/1,
        reload_sell/1,
        sub_list/3,
        self_list/1,
        self_list_count/1
    ]
).
-define(PAGE_SIZE,  6).  %% 每页显示条数
-define(CACHE_PAGE, 5).  %% 缓存页数
-define(EXPIRE_SPAN, 259200).  %% 过期暂留时长


%% 取挂售信息
get_sell(Id) ->
    ets:lookup(?ETS_SELL, Id).

%% 取挂售列表
list_sell(Class1, Class2, Page, Lv, Color, Career, <<>>) ->
    %io:format("list_sell:~p~n",[[Class1, Class2, Page, Lv, Color, Career]]),
    case Class1 of
        %% 全部
        0 ->
            if  Lv > 0 orelse Color > 0 orelse Career > 0 ->
                    Pattern = #ets_sell{is_expire=0, _='_'},
                    NewPattern = get_search_pattern(Pattern, Lv, Color, Career),
                    Totals = ets:select_count(?ETS_SELL, [{NewPattern, [], [true]}]),
                    case Totals > 0 of
                        true -> get_page_list2(NewPattern, Totals, Page);
                        false -> {ok, 0, []}
                    end;
                true ->
                    Pattern = #ets_sell{is_expire=0, _='_'},
                    Totals = ets:select_count(?ETS_SELL, [{Pattern, [], [true]}]),
                    case Totals > 0 of
                        true -> get_page_list2(Pattern, Totals, Page);
                        false -> {ok, 0, []}
                    end
            end;
        _ ->
            Pattern = #ets_sell{is_expire=0, class1 = Class1, class2 = Class2, _='_'},
            NewPattern = get_search_pattern(Pattern, Lv, Color, Career),
            Totals = ets:select_count(?ETS_SELL, [{NewPattern, [], [true]}]),
            case Totals > 0 of
                true -> get_page_list2(NewPattern, Totals, Page);
                false -> {ok, 0, []}
            end
    end;
list_sell(Class1, Class2, Page, Lv, Color, Career, Str) ->
    case Class1 of
        %% 全部
        0 -> Pattern = #ets_sell{is_expire=0, _='_'};
        _ -> Pattern = #ets_sell{is_expire=0, class1 = Class1, class2 = Class2, _='_'}
    end,
    NewPattern = get_search_pattern(Pattern, Lv, Color, Career),
    SellList = ets:match_object(?ETS_SELL, NewPattern),
    NewSellList = get_search_list(SellList, Str),
    Totals = length(NewSellList),
    case Totals > 0 of
        true ->
            TotalPage = util:ceil(Totals / ?PAGE_SIZE),
            {ok, TotalPage, get_page_list(NewSellList, Totals, Page)};
        false ->
            {ok, 0, []}
     end.

get_search_pattern(Pattern, Lv, Color, Career) ->
    case Lv > 0 of
        true ->  Pattern1 = Pattern#ets_sell{lv_num = Lv};
        false -> Pattern1 = Pattern
    end,
    case Color > 0 of
        true ->  Pattern2 = Pattern1#ets_sell{color = (Color-1)};
        false -> Pattern2 = Pattern1
    end,
    case Career > 0 of
        true ->  Pattern3 = Pattern2#ets_sell{career = Career};
        false -> Pattern3 = Pattern2
    end,
    Pattern3.

get_search_list(SellList, Str) ->
    case Str of
        <<>> -> SellList;
        _ ->
            F = fun(Info) -> binary:match(Info#ets_sell.goods_name, Str) =/= nomatch end,
            lists:filter(F, SellList)
    end.

get_ets_list(Pattern, Page) ->
    get_ets_list2(Page-1, ets:select_reverse(?ETS_SELL, [{Pattern, [], ['$_']}], ?PAGE_SIZE)).

get_ets_list2(0, {R,_}) -> R;
get_ets_list2(_, {_,'$end_of_table'}) -> [];
get_ets_list2(Page, {_,C}) ->
    get_ets_list2(Page-1, ets:select_reverse(C)).

get_page_list2(Pattern, Totals, Page) ->
    TotalPage = util:ceil(Totals / ?PAGE_SIZE),
    NewPage = case Page > TotalPage of true -> TotalPage; false -> Page end,
    {ok, TotalPage, get_ets_list(Pattern, NewPage)}.

get_page_list(SellList, Totals, Page) ->
    case SellList of
        [] -> [];
        _ ->
            Star = Totals - Page * ?PAGE_SIZE + 1,
            rsublist(SellList, 1, Star, Star + ?PAGE_SIZE, [])
    end.

rsublist(_, N, _, End, L) when N >= End -> L;
rsublist([H|T], N, Start, End, L) when N >= Start ->
    rsublist(T, N+1, Start, End, [H|L]);
rsublist([_|T], N, Start, End, L) ->
    rsublist(T, N+1, Start, End, L);
rsublist([], _, _, _, L) -> L.

%% 挂售
sell_up(SellInfo, GoodsInfo) ->
    ets:insert(?ETS_SELL, SellInfo),
    case  GoodsInfo#goods.id > 0 of
        true -> ets:insert(?ETS_SELL_GOODS, GoodsInfo);
        false -> skip
    end,
    ok.

%%取消挂售
sell_down(SellInfo) ->
    ets:delete(?ETS_SELL, SellInfo#ets_sell.id),
    case SellInfo#ets_sell.gid > 0 of
        true -> ets:delete(?ETS_SELL_GOODS, SellInfo#ets_sell.gid);
        false -> skip
    end.

%% 再次挂售
resell(SellInfo) ->
    End_time = util:unixtime() + SellInfo#ets_sell.time * 3600,
    Sql = io_lib:format(?sql_sell_update, [End_time, SellInfo#ets_sell.id]),
    db:execute(Sql),
    SellInfo#ets_sell{end_time=End_time, is_expire=0, expire_time=0}.


test_expire(Id) ->
    case ets:lookup(?ETS_SELL, Id) of
        %% 物品不在架上
        [] -> skip;
        [SellInfo] ->
            NowTime = util:unixtime() + ?EXPIRE_SPAN,
            Sql = io_lib:format(?sql_sell_update2, [NowTime, Id]),
            db:execute(Sql),
            NewSell = SellInfo#ets_sell{is_expire=1, expire_time=NowTime},
            ets:insert(?ETS_SELL, NewSell)
    end,
    ok.

%% 更新挂售记录
reload_sell(Id) ->
    case lib_goods_util:get_sell_info(Id) of
        [] -> skip;
        SellInfo ->
            case SellInfo#ets_sell.gid =:= 0 of
                true -> sell_up(SellInfo, #goods{});
                false ->
                    case lib_goods_util:get_goods_by_id(SellInfo#ets_sell.gid) of
                        [] -> sell_up(SellInfo, #goods{});
                        GoodsInfo -> sell_up(SellInfo, GoodsInfo)
                    end
            end
    end.

%% 过期清理
clean_up() ->
    NowTime = util:unixtime(),
    Pattern2 = #ets_sell{is_expire=1, expire_time = '$1', _='_'},
    SellList2 = ets:select(?ETS_SELL, [{Pattern2, [{'=<', '$1', NowTime}], ['$_']}]),
    ets:select_delete(?ETS_SELL, [{Pattern2, [{'=<', '$1', NowTime}], [true]}]),
    Pattern1 = #ets_sell{is_expire=0, end_time = '$1', _='_'},
    SellList1 = ets:select(?ETS_SELL, [{Pattern1, [{'=<', '$1', NowTime}], ['$_']}]),
    List1 = clean_up1(SellList1, []),
	spawn(fun() -> send_mail_alarm(SellList1) end),
    sell_expire(List1),
    List2 = clean_up2(SellList2, []),
    spawn(fun() -> lists:foreach(fun send_notice/1, List2) end).

clean_up1([H|T],L) ->
    NewH = H#ets_sell{is_expire=1, expire_time=(H#ets_sell.end_time + ?EXPIRE_SPAN)},
    ets:insert(?ETS_SELL, NewH),
    clean_up1(T,[{NewH#ets_sell.id,NewH#ets_sell.expire_time} | L]);
clean_up1([], L) -> L.

clean_up2([H|T],L) ->
    case H#ets_sell.gid > 0 of
        true -> ets:delete(?ETS_SELL_GOODS, H#ets_sell.gid);
        false -> skip
    end,
    NewL = case lists:keyfind(H#ets_sell.pid, 1, L) of
                false -> [{H#ets_sell.pid, [H]}|L];
                {Id,L2} -> lists:keyreplace(Id, 1, L, {Id, [H|L2]})
            end,
    clean_up2(T,NewL);
clean_up2([], L) -> L.

%% 挂售物品过期
sell_expire(SellList) ->
    F = fun() ->
            lists:foreach(fun sell_expire_item/1, SellList)
        end,
    lib_goods_util:transaction(F).

sell_expire_item({Id,Expire_time}) ->
    Sql = io_lib:format(?sql_sell_update2, [Expire_time, Id]),
    db:execute(Sql).

send_notice({PlayerId, SellList}) ->
    case lib_goods_sell:sell_expire(SellList) of
        {ok, MailList} ->
            case mod_chat_agent:lookup(PlayerId) of
                [] -> skip;
                [_Player] ->
                    Title = data_sell_text:mail_sys(),
                    %mod_disperse:cast_to_unite(mod_mail, update_mail_info, [PlayerId, MailList, Title])
                    mod_mail:update_mail_info(PlayerId, MailList, Title)
            end;
        Error -> 
            util:errlog("lib_sell sell_expire:~p", [Error])
    end,
    timer:sleep(1000).

sub_list(List, Star, Len) ->
    case Star < 1 of
        true ->
            NewLen = Len - 1 + Star,
            lists:sublist(List, 1, NewLen);
        false -> lists:sublist(List, Star, Len)
    end.

self_list(PlayerId) ->
    Pattern = #ets_sell{pid=PlayerId,  _='_'},
    ets:select_reverse(?ETS_SELL, [{Pattern, [], ['$_']}]).

self_list_count(PlayerId) ->
    Pattern = #ets_sell{pid=PlayerId,  _='_'},
    ets:select_count(?ETS_SELL, [{Pattern, [], [true]}]).


send_mail_alarm([]) ->
	ok;
send_mail_alarm(SellList) ->
	[H|SellListNext] = SellList,
	[Title, C] = data_sell_text:mail_text(gs_alarm),
    Content = io_lib:format(C, [H#ets_sell.goods_name]),
	lib_mail:send_sys_mail([H#ets_sell.pid], Title, Content),
	timer:sleep(100),
	send_mail_alarm(SellListNext).




