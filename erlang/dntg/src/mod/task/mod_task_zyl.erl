%%%------------------------------------
%%% @Module  : mod_task_zyl
%%% @Author  : hekai
%%% @Created : 2012.07.31
%%% @Description: 诛妖令
%%%------------------------------------
-module(mod_task_zyl).
-behaviour(gen_server).
-export([start/0, stop/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).
-include("server.hrl").
-include("def_goods.hrl").
-include("goods.hrl").

start() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

init([]) ->
	Color = [1, 2, 3, 4],
    %% 加载当前诛妖榜
	F = fun(Type) ->			
			SQL = io_lib:format("select count(*) from task_zyl where type = ~p and status = ~p",[Type,0]),
			[Num] = db:get_row(SQL),
			Tp = integer_to_list(Type),
			DictType = "zyl_now_" ++ Tp,
			erase(DictType),
			put(DictType,Num)
		end,
	[F(X)||X <-Color],
	{ok, []}.

handle_call({set_zyl_now, [Num,Type]}, _From, State) ->
	Tp = integer_to_list(Type),
	DictType = "zyl_now_" ++ Tp,
	erase(DictType),
	put(DictType,Num),
	{reply, ok, State};

handle_call({get_zyl_now, [Type]}, _From, State) ->
	Tp = integer_to_list(Type),
	DictType = "zyl_now_" ++ Tp,
	Value = get(DictType),
	Reply = 
	case  Value=:= undefined of
		true -> 0;
		false -> Value
	end,
	{reply, Reply, State}.

handle_cast({reset_zyl}, State) ->
	Color = [1, 2, 3, 4],
    %% 加载当前诛妖榜
	F = fun(Type) ->			
			SQL = io_lib:format("select count(*) from task_zyl where type = ~p and status = ~p",[Type,0]),
			[Num] = db:get_row(SQL),
			Tp = integer_to_list(Type),
			DictType = "zyl_now_" ++ Tp,
			erase(DictType),
			put(DictType,Num)
		end,
	[F(X)||X <-Color],
	{noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
    
