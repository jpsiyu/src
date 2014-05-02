%%%------------------------------------
%%% @Module  : mod_clusters_init
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2012.10.25
%%% @Description: 集群数据初始化
%%%------------------------------------
-module(mod_clusters_init).
-behaviour(gen_server).
-export([
            start_link/0,
            init_mysql/0
        ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("common.hrl").
-include("clusters.hrl").
-include("scene.hrl").
-include("record.hrl").
-include("rank_cls.hrl").

start_link() ->
    gen_server:start_link({local,?MODULE}, ?MODULE, [], []).

init([]) ->
    %%初始ets表
    ok = init_ets(),
    %%初始mysql
    ok = init_mysql(),
    {ok, ?MODULE}.

handle_cast(_R , Status) ->
    {noreply, Status}.

handle_call(_R , _FROM, Status) ->
    {reply, ok, Status}.

handle_info(_Reason, Status) ->
    {noreply, Status}.

terminate(_Reason, Status) ->
    {ok, Status}.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

%% ================== 私有函数 =================
%% mysql数据库连接初始化
init_mysql() ->
    [DbHost, DbPort, DbUser, DbPass, DbName, DbEncode] = config:get_mysql(),
    db:start(DbHost, DbPort, DbUser, DbPass, DbName, DbEncode, 30),
    ok.

%% 初始ETS表
init_ets() ->
    %% 节点
    ets:new(?ETS_NODE, [{keypos, #node.id}, named_table, public, set]),
    %% 用户场景信息
    ets:new(?ETS_SCENE, [{keypos, #ets_scene.id}, named_table, public, set]),
	%% 跨服1v1排行榜
	ets:new(?RK_KF_ETS_1V1_RANK, [{keypos, #kf_ets_1v1_rank.type_id}, named_table, public, set]),
	%% 跨服鲜花排行
	ets:new(?RK_KF_SP_LIST, [{keypos, #kf_ets_sp_list.type}, named_table, public, set]),
	ets:new(?RK_KF_FLOWER_RANK, [{keypos, #kf_ets_flower_rank.m_key}, named_table, public, set]),
	%% 跨服排行榜
	ets:new(?RK_KF_ETS_RANK, [{keypos, #kf_ets_rank.type_id}, named_table, public, set]),%% 跨服排行榜
	%% 跨服战力排行榜活动
	ets:new(?RK_ETS_POWER_ACTIVITY, [{keypos, #kfrank_power_activity.platform}, named_table, public, set]),	
	ok.
