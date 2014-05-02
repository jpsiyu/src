%%%-----------------------------------
%%% @Module  : gs_server_base
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.12.08
%%% @Description: 游戏启动服务
%%%-----------------------------------
-module(gs_server_base).
-export([start/0, stop/0]).
-compile(export_all).

start() ->
    %start_db_heartbeat(),
    start_scene_init(),
    start_scene_mon(),
    start_scene_npc(),
    start_mon(),
    start_scene(),
    %%初始化关键词字典
    mod_word:init(),
	ok = start_pet(),
    ok = start_task(),
    ok = start_timer(),
    ok = start_daily_timer(),
	%ok = start_timer_oneminute(),
    %%游戏世界buff控制器
    ok = start_game_buff(),
	ok = start_guild_party(),
    ok.

%%关闭服务器时需停止
stop() ->
    gs_unite_base:stop(),
    ok.

%% %% 数据库心跳
%% start_db_heartbeat() ->
%%         {ok, _} = supervisor:start_child(
%%         gs_sup,
%%         {mod_db_heartbeat,
%%             {mod_db_heartbeat, start_link, []},
%%             permanent, infinity, supervisor, [mod_db_heartbeat]}),
%%     ok.

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

%%开启宠物监控树
start_pet() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_pet,
            {mod_pet, start_link,[]},
            permanent, 10000, supervisor, [mod_pet]}),
    ok.

%%开启定时器监控树
start_timer() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {timer_frame,
            {timer_frame, start_link,[]},
            permanent, 10000, supervisor, [timer_frame]}),
    ok.

%%开启每日定时器监控树
start_daily_timer() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {timer_day,
            {timer_day, start_link,[]},
            permanent, 10000, supervisor, [timer_day]}),
    ok.

%%开启定时器监控树(1分钟一次)
start_timer_oneminute() ->
	{ok,_} = supervisor:start_child(
        gs_sup,
        {timer_server_oneminute,
            {timer_server_oneminute, start_link,[]},
            permanent, 10000, supervisor, [timer_server_oneminute]}),
    ok.

%%开启任务监控树
start_task() ->
    db:prepare(sql_add_trigger,<<"insert into `task_bag`(`role_id`, `task_id`, `trigger_time`, `state`, `end_state`, `mark`, `type`) values(?,?,?,?,?,?,?)">>),
    db:prepare(sql_upd_trigger,<<"update `task_bag` set state=?,mark=? where role_id=? and task_id=?">>),
    ok.

%%开启游戏buff监控树
start_game_buff() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_game_buff,
                {mod_game_buff, start_link,[]},
                permanent, 10000, supervisor, [mod_game_buff]}),
    ok.

%%开启竞技场监控树
start_arena() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_arena,
            {mod_arena, start_link,[]},
            permanent, 10000, supervisor, [mod_arena]}),
    ok.

%%开启竞技场管理器监控树
start_arena_mgr() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_arena_mgr,
            {mod_arena_mgr, start_link,[]},
            permanent, 10000, supervisor, [mod_arena_mgr]}),
    ok.

%%开启帮派仙宴预约监控树
start_guild_party() ->
	{ok,_} = supervisor:start_child(
        gs_sup,
        {mod_guild_party,
            {mod_guild_party, start_link,[]},
            permanent, 10000, supervisor, [mod_guild_party]}),
    ok.

