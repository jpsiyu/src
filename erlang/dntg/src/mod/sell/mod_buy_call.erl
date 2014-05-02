%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-8
%% Description: 交易市场求购模块call
%% --------------------------------------------------------
-module(mod_buy_call).
-export([handle_call/3]).
-include("sell.hrl").


%% 查询求购
handle_call({'list', [Class1, Class2, Page, Lv, Color, Career, Str]}, _From, SellStatus) ->
    case lib_buy:list_buy(Class1, Class2, Page, Lv, Color, Career, Str) of
        {ok, TotalPage, WtbList} ->
            {reply, [TotalPage, WtbList], SellStatus};
        Error ->
            util:errlog("mod_buy list:~p", [Error]),
            {reply, [0, []], SellStatus}
    end;

%% 下架
handle_call({'buy_down', Id}, _From, SellStatus) ->
    case mod_buy:check_buy(Id) of
        {fail, Res} ->
            {reply, {fail, Res}, SellStatus};
        {ok, _WtbInfo} ->
            ets:delete(?ETS_BUY, Id),
            {reply, ok, SellStatus}
    end;
%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_buy:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.





