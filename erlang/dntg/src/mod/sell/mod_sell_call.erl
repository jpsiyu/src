%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-7
%% Description: 交易市场模块 call
%% --------------------------------------------------------
-module(mod_sell_call).
-export([handle_call/3]).

%% 查询交易
handle_call({'list', [Class1, Class2, Page, Lv, Color, Career, Str]}, _From, SellStatus) ->
    case lib_sell:list_sell(Class1, Class2, Page, Lv, Color, Career, Str) of
        {ok, TotalPage, SellList} ->
            {reply, [TotalPage, SellList], SellStatus};
        Error ->
            util:errlog("mod_sell list:~p", [Error]),
            {reply, [0, []], SellStatus}
    end;

%% 下架
handle_call({'sell_down', Id}, _From, SellStatus) ->
    case mod_sell:check_sell(Id) of
        {fail, Res} ->
            {reply, {fail, Res}, SellStatus};
        {ok, SellInfo} ->
            lib_sell:sell_down(SellInfo),
            {reply, ok, SellStatus}
    end;

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_sell:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.





