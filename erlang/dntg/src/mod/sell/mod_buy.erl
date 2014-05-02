%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-8
%% Description: 交易市场求购模块
%% --------------------------------------------------------
-module(mod_buy).
-behaviour(gen_server).
-export([start_link/0, call_sell_list/7, call_buy_down/1, cast_buy_reload/1, cast_buy_clean/0, check_buy/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("sell.hrl").
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

call_sell_list(Class1, Class2, Page, Lv, Color, Career, Str) ->
    case gen:call(?MODULE, '$gen_call', {'list', [Class1, Class2, Page, Lv, Color, Career, Str]}) of
        {ok, Res} -> Res;
        {'EXIT',_Reason} -> [0, []]
    end.

%% 公共线记录下架
call_buy_down(Id) ->
    case gen:call(?MODULE, '$gen_call', {'buy_down', Id}) of
        {ok, Res} -> Res;
        {'EXIT',_Reason} -> {fail, 0}
    end.

%% 公共线记录更新
cast_buy_reload(Id) ->
    gen_server:cast(?MODULE, {'buy_reload', Id}).

%% 公共线过期清理
cast_buy_clean() ->
    gen_server:cast(?MODULE, {'buy_clean'}).

init([]) ->
    {ok, ?MODULE}.

handle_call(Request, From, Statue) ->
    mod_buy_call:handle_call(Request, From, Statue).

handle_cast(Msg, Statue) ->
    mod_buy_cast:handle_cast(Msg, Statue).

handle_info(_Info, Statue) ->
    {noreply, Statue}.


terminate(_Reason, _Status) ->
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

%%
%% Local Function
%%
%% 检查交易物品
check_buy(Id) ->
    case ets:lookup(?ETS_BUY, Id) of
        %% 物品不在架上
        [] -> {fail, 2};
        [WtbInfo] -> {ok, WtbInfo}
    end.




