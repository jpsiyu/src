%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-7
%% Description: 交易市场模块
%% --------------------------------------------------------
-module(mod_sell).
-behaviour(gen_server).
-export([start_link/0, call_sell_list/7, call_sell_down/1, cast_sell_reload/1, cast_sell_clean/0, cast_sell_expire/2, cast_sell_refresh/0, check_sell/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("sell.hrl").

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    Status = #sell_status{},
    {ok, Status}.

call_sell_list(Class1, Class2, Page, Lv, Color, Career, Str) ->
    case gen:call(?MODULE, '$gen_call', {'list', [Class1, Class2, Page, Lv, Color, Career, Str]}) of
        {ok, Res} -> Res;
        {'EXIT',_Reason} -> [0, []]
    end.

%% 公共线记录下架
call_sell_down(Id) ->
    case gen:call(?MODULE, '$gen_call', {'sell_down', Id}) of
        {ok, Res} -> Res;
        {'EXIT',_Reason} -> {fail, 0}
    end.

%% 公共线重加载交易记录
cast_sell_reload(Id) ->
    gen_server:cast(?MODULE, {'sell_reload', Id}).

%% 公共线过期清理
cast_sell_clean() ->
    gen_server:cast(?MODULE, {'clean'}).

%% 公共线时效物品清理
cast_sell_expire(PlayerId, GoodsId) ->
    gen_server:cast(?MODULE, {'expire', PlayerId, GoodsId}).

%% 公共线重加载
cast_sell_refresh() ->
    gen_server:cast(?MODULE, {'refresh'}).

handle_call(Request, From, Status) ->
    mod_sell_call:handle_call(Request, From, Status).

handle_cast(Msg, Status) ->
    mod_sell_cast:handle_cast(Msg, Status).

handle_info(_Info, Status) ->
    {noreply, Status}.


terminate(_Reason, _SellStatus) ->
    ok.

code_change(_OldVsn, SellStatus, _Extra)->
    {ok, SellStatus}.

%% Local Function

%% 检查交易物品
check_sell(Id) ->
    case ets:lookup(?ETS_SELL, Id) of
        %% 物品不在架上
        [] -> {fail, 2};
        [SellInfo] -> {ok, SellInfo}
    end.




