%%%--------------------------------------
%%% @Module  : mod_rank_cls
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.11.15
%%% @Description :  跨服排行榜
%%%--------------------------------------

-module(mod_rank_cls).
-behaviour(gen_server).
-include("common.hrl").
-include("rank.hrl").
-include("rank_cls.hrl").
-include("sql_rank.hrl").
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% 启动服务
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 1v1活动结束时，将玩家数据更新到库和榜上
%% Data : [#bd_1v1_player, ...]
update_1v1_rank_user(Data) ->
	lib_rank_cls:update_1v1_rank_user(Data).

%% 3v3活动结束时，将玩家数据更新到库和榜上
%% Data : [#bd_3v3_player, ...]
update_3v3_rank_user(Data) ->
	lib_rank_cls:update_3v3_rank_user(Data).

%% 活动结束后，将排行榜数据广播给游戏节点
broadcast_kf_1v1_rank() ->
	gen_server:cast(?MODULE, {broadcast_kf_1v1_rank}).

%% 活动结束后，将mvp排行榜数据广播给游戏节点
broadcast_kf_3v3_rank() ->
	gen_server:cast(?MODULE, {broadcast_kf_3v3_rank}).

%% [斗战封神活动] 玩家战力需要进行上榜处理
powerrank_send_power_to_kf(Node, Row) ->
	gen_server:cast(?MODULE, {powerrank_send_power_to_kf, [Node, Row]}).

%% [斗战封神活动] 玩家形象
powerrank_send_image_to_kf(Node, Platform, ServerId, Id, Image) ->
	gen_server:cast(?MODULE, {powerrank_send_image_to_kf, [Node, Platform, ServerId, Id, Image]}).

%% [斗战封神活动] 请求从游戏线发过来跨服中心，请求同步跨服战力排行数据到游戏线
powerrank_get_power_list(Node, Platform, ServerNum, Id) ->
	gen_server:cast(?MODULE, {powerrank_get_power_list, [Node, Platform, ServerNum, Id]}).

stop() ->
    gen_server:call(?MODULE, stop).

%%%------------------------------------
%%%             回调函数
%%%------------------------------------

init([]) ->
	process_flag(trap_exit, true),
	%% 刷新跨服1v1排行榜
	lib_rank_cls:refresh_1v1_rank(),
	timer:sleep(500),
	%% 刷新跨服排行榜
	lib_rank_cls:refresh_kf_rank(),
	%% 刷新斗战封神排行
	lib_activity_kf_power:reload_rank(),
	{ok, []}.

handle_call(_Request, _From, State) ->
	{reply, ok, State}.

%% 活动结束后，将排行榜数据广播给游戏节点
handle_cast({broadcast_kf_1v1_rank}, State) ->
	lib_rank_cls:broadcast_kf_1v1_rank(),
	{noreply, State};

%% 活动结束后，将mvp排行榜数据广播给游戏节点
handle_cast({broadcast_kf_3v3_rank}, State) ->
	lib_rank_cls:broadcast_kf_3v3_rank(),
	{noreply, State};

%% 统一处理方法
%% Args : 必须由[]包起来，里面的内容才是真正的参数
handle_cast({Fun, Args}, State) ->
	spawn(fun() -> 
		apply(lib_rank_cls, Fun, Args)
	end),
	{noreply, State};

handle_cast(_Msg, State) ->
   {noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
    ?ERR("~nmod_rank_cls terminate reason: ~w~n", [_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
