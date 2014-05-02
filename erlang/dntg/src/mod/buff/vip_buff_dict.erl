%%%------------------------------------
%%% @Module  : vip_buff_dict
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.27
%%% @Description: 用进程字典存储VIP玩家的祝福BUFF(公共线中)
%%%------------------------------------


-module(vip_buff_dict).
-behaviour(gen_server).
-include("common.hrl").
-include("buff.hrl").
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% 插入操作
insert_buff(EtsVipBuff) -> 
	gen_server:cast(misc:get_global_pid(?MODULE), {insert_buff, EtsVipBuff}).

%% 查询操作
lookup_pid(Id) -> 
	gen_server:call(misc:get_global_pid(?MODULE), {lookup_pid, Id}).

start_link() ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    {ok, 0}.

handle_call({lookup_pid, Id}, _From, State) ->
    Rep = get({ets_vip_buff, Id}),
	{reply, Rep, State};

handle_call(Event, _From, Status) ->
    catch util:errlog("vip_buff_dict:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.


handle_cast({insert_buff, EtsVipBuff}, Status) ->
	put({ets_vip_buff, EtsVipBuff#ets_vip_buff.id}, EtsVipBuff),
	{noreply, Status};

handle_cast(Msg, Status) ->
    catch util:errlog("vip_buff_dict:handle_cast not match: ~p", [Msg]),
    {noreply, Status}.

handle_info(Info, Status) ->
    catch util:errlog("vip_buff_dict:handle_info not match: ~p", [Info]),
    {noreply, Status}.

terminate(_Reason, _Status) ->
    %catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.



