%%%--------------------------------------
%%% @Module  : mod_fame_limit
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.5.31
%%% @Description :  限时名人堂（活动）
%%%--------------------------------------

-module(mod_fame_limit).
-behaviour(gen_server).
-include("common.hrl").
-export([start_link/0, update_rank/2, update_master/2, clear_data/0, stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%%%------------------------------------
%%%             接口函数
%%%------------------------------------

%% 启动服务
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 更新排行榜
update_rank(RankType, Row) ->
	gen_server:cast(?MODULE, {update_rank, [RankType, Row]}).

update_master(Type, Master) ->
	gen_server:cast(?MODULE, {update_master, [Type, Master]}).

%% 每天0点清数据
clear_data() ->
	gen_server:cast(?MODULE, {clear_data, [1]}).

stop() ->
    gen_server:call(?MODULE, stop).


%%%------------------------------------
%%%             回调函数
%%%------------------------------------
init([]) ->
	process_flag(trap_exit, true),
	{ok, []}.

handle_call({Fun, Args} , _FROM, Status) ->
    {reply, apply(lib_fame_limit, Fun, Args), Status};

handle_call(_R , _FROM, Status) ->
    {reply, ok, Status}.

handle_cast({Fun, Args}, State) ->
	apply(lib_fame_limit, Fun, Args),
	{noreply, State};

handle_cast(_R , Status) ->
    {noreply, Status}.

handle_info(Info, State) ->
    mod_rank_info:handle_info(Info, State).

terminate(_Reason, _State) ->
    ?ERR("~nmod_fame_limit terminate reason: ~w~n", [_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
