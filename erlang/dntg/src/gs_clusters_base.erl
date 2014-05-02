%%%-----------------------------------
%%% @Module  : gs_clusters_base
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2012.10.25
%%% @Description: 跨服线路
%%%-----------------------------------
-module(gs_clusters_base).
-export([start/0, stop/0]).

start() ->
    %% 跨服公用服务启动

    case config:get_cls_type() of
        1 ->
            %% 只在跨服中心启动
            cls_center();
        _ ->
            %% 只在跨服节点启动
            cls_node()
    end,

	ok.

%% 只在跨服中心启动
cls_center() ->
    start_scene_init(),
    start_scene_mon(),
    start_scene_npc(),
    start_mon(),
    start_scene(),
    start_mod_online(),
	%% 本地1v1初始化（这两行代码顺序不能乱）
%	ok = start_kf_1v1(),
%	ok = start_kf_1v1_mgr(),
%	
%	%% 诸神初始化（这两行代码顺序不能乱）
%	ok = start_god(),
%	ok = start_god_mgr(),
%
%	%% 本地3v3初始化（这两行代码顺序不能乱）
%	ok = start_kf_3v3(),
%	ok = start_kf_3v3_helper(),
%	ok = start_kf_3v3_mgr(),
%
    ok = start_change_line_queue(),
	ok = start_mod_rank_cls(),
	ok = start_rank_timer(),
%	ok = start_flower_rank_timer(),
    ok.

%% 只在跨服节点启动
cls_node() ->
    ok.


stop() ->
    ok.


%%场景数据初始化
start_scene_init() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_scene_init,
            {mod_scene_init, start_link,[]},
            permanent, 10000, supervisor, [mod_scene_init]}),
    ok.

%%开启场景监控树
start_scene() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_scene,
            {mod_scene, start_link,[]},
            permanent, 10000, supervisor, [mod_scene]}),
    ok.

%%场景怪物种类
start_scene_mon() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_scene_mon,
            {mod_scene_mon, start_link,[]},
            permanent, 10000, supervisor, [mod_scene_mon]}),
    ok.

%%场景npc种类
start_scene_npc() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_scene_npc,
            {mod_scene_npc, start_link,[]},
            permanent, 10000, supervisor, [mod_scene_npc]}),
    ok.

%%开启怪物监控树
start_mon() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_mon_create,
            {mod_mon_create, start_link,[]},
            permanent, 10000, supervisor, [mod_mon_create]}),
    ok.

%%开启本服1v1战场监控树
%start_kf_1v1() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_kf_1v1,
%            {mod_kf_1v1, start_link,[]},
%            permanent, 10000, supervisor, [mod_kf_1v1]}),
%    ok.
%
%%%开启本服1v1战场管理器监控树
%start_kf_1v1_mgr() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_kf_1v1_mgr,
%            {mod_kf_1v1_mgr, at_start_link,[]},
%            permanent, 10000, supervisor, [mod_kf_1v1_mgr]}),
%    ok.
%
%%%开启诸神战场管理器监控树
%start_god() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_god,
%            {mod_god, start_link,[]},
%            permanent, 10000, supervisor, [mod_god]}),
%    ok.
%
%%%开启诸神战场管理器监控树
%start_god_mgr() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_god_mgr,
%            {mod_god_mgr, at_start_link,[]},
%            permanent, 10000, supervisor, [mod_god_mgr]}),
%    ok.
%
%%%开启本服3v3战场监控树
%start_kf_3v3() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_kf_3v3,
%            {mod_kf_3v3, start_link,[]},
%            permanent, 10000, supervisor, [mod_kf_3v3]}),
%    ok.
%
%%%开启本服3v3战场帮助进程监控树
%start_kf_3v3_helper() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_kf_3v3_helper,
%            {mod_kf_3v3_helper, start_link,[]},
%            permanent, 10000, supervisor, [mod_kf_3v3_helper]}),
%    ok.
%
%%%开启本服3v3战场管理器监控树
%start_kf_3v3_mgr() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_kf_3v3_mgr,
%            {mod_kf_3v3_mgr, at_start_link,[]},
%            permanent, 10000, supervisor, [mod_kf_3v3_mgr]}),
%    ok.

%% 统计在线
start_mod_online() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_online,
                {mod_online, start_link,[]},
                permanent, 10000, supervisor, [mod_online]}),
    ok.

%% 跨服中心换线排队
start_change_line_queue() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_change_scene_cls_center,
                {mod_change_scene_cls_center, start_link,[]},
                permanent, 10000, supervisor, [mod_change_scene_cls_center]}),
    ok.

%% 排行榜服务进程
start_mod_rank_cls() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_rank_cls,
                {mod_rank_cls, start_link,[]},
                permanent, 10000, supervisor, [mod_rank_cls]}),
    ok.

%% 排行榜定时器
start_rank_timer() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {timer_rank_cls,
                {timer_rank_cls, start_link,[]},
                permanent, 10000, supervisor, [timer_rank_cls]}),
    ok.

%% 跨服鲜花定时器
%start_flower_rank_timer() ->
%    {ok,_} = supervisor:start_child(
%               gs_sup,
%               {timer_ml_rank_cls,
%                {timer_ml_rank_cls, start_link,[]},
%                permanent, 10000, supervisor, [timer_ml_rank_cls]}),
%    ok.
