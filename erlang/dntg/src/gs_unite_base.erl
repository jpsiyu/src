%%%-----------------------------------
%%% @Module  : gs_unite_base
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.12.08
%%% @Description: 公共服务
%%%-----------------------------------
-module(gs_unite_base).
-include("common.hrl").
-include("record.hrl").
-export([start/0, stop/0]).

start() ->
	% 启动加载多倍经验配置
	ok = start_dets(),
	ok = start_multiple(),
	ok = init_unite_status(),
	ok = start_chat_agent(),
	ok = start_ip_ctrl(),
	ok = start_mail(),
	ok = start_mail_ban(),
	ok = start_daily_dict(),
	%% 以上基础功能,请勿移后
	ok = start_drop(),
	ok = start_timer(),
	ok = start_timer_unite_midday12_frame(),
	ok = start_timer_unite_afternoon6_frame(),
	ok = start_timer_unite_morning9_frame(),
	%ok = start_timer_unite_hotspring(),
	ok = start_timer_unite_rank(),
	ok = start_quiz_server(),
	ok = start_box(),
	ok = start_timer_unite_day(),
	ok = start_sell(),
	ok = start_secret_shop(),
	ok = start_husong(),
	ok = start_task_eb(),
	ok = start_task_zyl(),
	mod_word:init(),
	% 竞技场初始化（这两行代码顺序不能乱）
	ok = start_arena_new(),
	ok = start_arena_mgr_new(),
	%% 帮战初始化（这两行代码顺序不能乱）
	ok = start_factionwar(),
	ok = start_factionwar_mgr(),
	%% 蟠桃园初始化（这两行代码顺序不能乱）
	ok = start_peach(),
	ok = start_peach_mgr(),
	%% 跨服1v1初始化（这两行代码顺序不能乱）
	%ok = start_kf_1v1_state(),
	%% 跨服诸神状态（这两行代码顺序不能乱）
	%ok = start_god_state(),
	%% 跨服3v3初始化（这两行代码顺序不能乱）
	%ok = start_kf_3v3_state(),
	% 飞天号角
	ok = start_chat_bugle_call(),
	ok = start_chat_bugle_call_timer(),	
	ok = start_team_agent(),            %% 开启组队数据管理服务监控树.	
	ok = start_dungeon_agent(),         %% 开启副本管理服务监控树.
	%% 生肖大奖
	%ok = start_timer_unite_shengxiao20_frame(),
	ok = start_timer_unite_min(),
	ok = start_timer_unite_pay(),
	ok = start_mod_online(),
	ok = start_clear_mon_timer(),
	ok = start_boss(),                  %%开启BOSS监控树.	
	%ok = start_monster_siege(),         %%开启怪物攻城监控树.
	ok = start_fame(),
	%ok = start_timer_unite_butterfly(),
	%ok = start_timer_unite_fishing(),
	ok = start_change_line_queue(),
	ok = start_guild(),
	ok = start_rank(),
    ok = start_qixi(),
	% 大闹天宫初始化（这两行代码顺序不能乱）
    %%关闭南天门
%% 	ok = start_wubianhai_new(),
%% 	ok = start_wubianhai_mgr_new(),
	% 爱情长跑初始化（这两行代码顺序不能乱）
	%ok = start_loverun(),
	%ok = start_loverun_mgr(),
	%% 摇钱树
	ok = start_shake_money(),
	%% 结婚
	ok = start_marriage(),
	%% 限时名人堂（活动） 
	ok = start_fame_limit_rank(),
    ok = start_pet_refresh_skill_notice(),
    ok = start_chat_forbid(),
	ok = start_activity_festival(),
    % 城战（这两行代码顺序不能乱）
	%ok = start_city_war(),
	%ok = start_city_war_mgr(),
    ok = start_timer_unite_fewsecond(),
    ok = start_vip_dun(),
	ok = start_guild_dun(),
    ok = start_voice_chat(),
	ok.

%%关闭服务器时需停止
stop() ->
	mod_ban:ban_all(),
	List = mod_disperse:node_list(),
	F = fun(Node) ->
			case rpc:call(Node, mod_login, stop_all, []) of
				{badrpc, R} ->
					util:errlog("server stop:~p~n", [R]);
				_ ->
					skip
			end
	end,
	[F(S#node.node) || S <-List],
	%% 需要放到最后处理
	mod_dets:stop(), 
	AllList = mod_disperse:node_all_list(),
	%% 关闭节点
	[rpc:call(S#node.node, init, stop, []) || S <-AllList],
	io:format("server close!"),
	init:stop(),
	ok.

%%开启DETS
start_dets() ->
	mod_dets:start_link(),
	ok.

%%开启聊天数据保存进程
start_chat_agent() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_chat_agent,
                {mod_chat_agent, start_link,[]},
                permanent, 10000, supervisor, [mod_chat_agent]}),
    ok.

init_unite_status() ->
    %% 服务器开服时间
    Now_time = util:unixdate(),
    Open_time = case db:get_row(<<"select `reg_time` from `player_login` where 1 order by `id` limit 100,1 ">>) of
                    [] -> 
                        Now_time;
                    [Reg_time] when is_number(Reg_time) ->
                        Time = util:unixdate(Reg_time),
                        Time;
                    _ -> 
                        0
                end,
    ets:insert(?SERVER_STATUS, #server_status{name=open_time, value=Open_time}),
    ok.

%% 玩家IP控制器
start_ip_ctrl() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_ban,
                {mod_ban, start_link,[]},
                permanent, 10000, supervisor, [mod_ban]}),
    ok.

%%开启竞技场监控树
start_arena_new() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_arena_new,
            {mod_arena_new, start_link,[]},
            permanent, 10000, supervisor, [mod_arena_new]}),
    ok.
%%开启竞技场管理器监控树
start_arena_mgr_new() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_arena_mgr_new,
            {mod_arena_mgr_new, at_start_link,[]},
            permanent, 10000, supervisor, [mod_arena_mgr_new]}),
    ok.

%%开启帮战站场监控树
start_factionwar() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_factionwar,
            {mod_factionwar, start_link,[]},
            permanent, 10000, supervisor, [mod_factionwar]}),
    ok.
%%开启帮战站场管理器监控树
start_factionwar_mgr() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_factionwar_mgr,
            {mod_factionwar_mgr, at_start_link,[]},
            permanent, 10000, supervisor, [mod_factionwar_mgr]}),
    ok.

%%开启蟠桃园站场监控树
start_peach() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_peach,
            {mod_peach, start_link,[]},
            permanent, 10000, supervisor, [mod_peach]}),
    ok.
%%开启帮蟠桃园场管理器监控树
start_peach_mgr() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_peach_mgr,
            {mod_peach_mgr, at_start_link,[]},
            permanent, 10000, supervisor, [mod_peach_mgr]}),
    ok.

%%%开启跨服1v1战场状态监控树
%start_kf_1v1_state()->
%	{ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_kf_1v1_state,
%            {mod_kf_1v1_state, start_link,[]},
%            permanent, 10000, supervisor, [mod_kf_1v1_state]}),
%    ok.
%
%%%开启跨诸神战场状态监控树
%start_god_state()->
%	{ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_god_state,
%            {mod_god_state, start_link,[]},
%            permanent, 10000, supervisor, [mod_god_state]}),
%    ok.
%
%%%开启跨服3v3战场状态监控树
%start_kf_3v3_state()->
%	{ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_kf_3v3_state,
%            {mod_kf_3v3_state, start_link,[]},
%            permanent, 10000, supervisor, [mod_kf_3v3_state]}),
%    ok.

%%加载多倍经验监控树
start_multiple() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_multiple,
            {mod_multiple, start_link,[]},
            permanent, 10000, supervisor, [mod_multiple]}),
    ok.

%%开启号角监控树
start_chat_bugle_call() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_chat_bugle_call,
            {mod_chat_bugle_call, start_link,[]},
            permanent, 10000, supervisor, [mod_chat_bugle_call]}),
    ok.
%%开启号角监控树
start_chat_bugle_call_timer() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_chat_bugle_call_timer,
            {mod_chat_bugle_call_timer, start_link,[]},
            permanent, 10000, supervisor, [mod_chat_bugle_call_timer]}),
    ok.

%%开启组队数据管理服务监控树.
start_team_agent() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_team_agent,
            {mod_team_agent, start_link,[]},
            permanent, 10000, supervisor, [mod_team_agent]}),
    ok.

%%开启副本管理服务监控树.
start_dungeon_agent() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_dungeon_agent,
            {mod_dungeon_agent, start_link,[]},
            permanent, 10000, supervisor, [mod_dungeon_agent]}),
    ok.

%%开启邮件监控树
start_mail() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_mail,
                {mod_mail, start_link,[]},
                permanent, 10000, supervisor, [mod_mail]}),
    ok.

%%开启邮件封号监控树
start_mail_ban() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_mail_check,
                {mod_mail_check, start_link,[]},
                permanent, 10000, supervisor, [mod_mail_check]}),
    ok.

%%开启定时器监控树
start_timer() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {timer_unite_frame,
            {timer_unite_frame, start_link,[]},
            permanent, 10000, supervisor, [timer_unite_frame]}),
    ok.

%%开启定时器监控树
start_timer_unite_midday12_frame() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {timer_unite_midday12_frame,
            {timer_unite_midday12_frame, start_link,[]},
            permanent, 10000, supervisor, [timer_unite_midday12_frame]}),
    ok. 

%%开启定时器监控树
start_timer_unite_afternoon6_frame() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {timer_unite_afternoon6_frame,
            {timer_unite_afternoon6_frame, start_link,[]},
            permanent, 10000, supervisor, [timer_unite_afternoon6_frame]}),
    ok.    

%%开启定时器监控树
start_timer_unite_morning9_frame() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {timer_unite_morning9_frame,
            {timer_unite_morning9_frame, start_link,[]},
            permanent, 10000, supervisor, [timer_unite_morning9_frame]}),
    ok.    

%%开启定时器监控树
%start_timer_unite_hotspring() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {timer_unite_hotspring,
%            {timer_unite_hotspring, start_link,[]},
%            permanent, 10000, supervisor, [timer_unite_hotspring]}),
%    ok.    

%%开启定时器监控树
start_timer_unite_rank() ->
	{ok,_} = supervisor:start_child(
		gs_sup,
		{timer_unite_rank,
			{timer_unite_rank, start_link,[]},
			permanent, 10000, supervisor, [timer_unite_rank]}),
	ok.

%%开启定时器监控树
%start_timer_unite_butterfly() ->
%     {ok,_} = supervisor:start_child(
%         gs_sup,
%         {timer_unite_butterfly,
%             {timer_unite_butterfly, start_link,[]},
%             permanent, 10000, supervisor, [timer_unite_butterfly]}),
%     ok.
%
%%%开启定时器监控树
%start_timer_unite_fishing() ->
%     {ok,_} = supervisor:start_child(
%         gs_sup,
%         {timer_unite_fish,
%             {timer_unite_fish, start_link,[]},
%             permanent, 10000, supervisor, [timer_unite_fish]}),
%     ok.

%%开启帮派监控树
start_guild() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_guild,
            {mod_guild, start_link,[]},
            permanent, 10000, supervisor, [mod_guild]}),
    ok.

%% 宝箱监控树
start_box() ->
    {ok, _} = supervisor:start_child(
                gs_sup,
                {mod_box,
                 {mod_box, start_link, []},
                 permanent, 10000, supervisor, [mod_box]
                 }
                ),
    ok.

%% 开启每日定时器监控树
start_timer_unite_day() ->
    {ok, _} = supervisor:start_child(
        gs_sup,
        {timer_unite_day,
            {timer_unite_day, start_link, []},
            permanent, 10000, supervisor, [timer_unite_day]}),
    ok.

%% 开启交易市场监控树
start_sell() ->
    {ok, _} = supervisor:start_child(
        gs_sup,
        {mod_sell,
            {mod_sell, start_link, []},
            permanent, 10000, supervisor, [mod_sell]}),
    ok.

%% 开启求购模块监控树
%% start_buy() ->
%%     {ok, _} = supervisor:start_child(
%%         gs_sup,
%%         {mod_buy,
%%             {mod_buy, start_link, []},
%%             permanent, 10000, supervisor, [mod_buy]}),
%%     ok.

%% 开启神秘商店监控树
start_secret_shop() ->
    {ok, _} = supervisor:start_child(
        gs_sup,
        {mod_secret_shop,
            {mod_secret_shop, start_link, []},
            permanent, 10000, supervisor, [mod_secret_shop]}),
    ok.


%%开启皇榜任务监控树(1分钟一次)
start_task_eb() ->
	{ok,_} = supervisor:start_child(
        gs_sup,
        {mod_task_eb,
            {mod_task_eb, start,[]},
            permanent, 10000, supervisor, [mod_task_eb]}),
    ok.

%%开启诛妖令任务监控树(1分钟一次)
start_task_zyl() ->
	{ok,_} = supervisor:start_child(
        gs_sup,
        {mod_task_zyl,
            {mod_task_zyl, start,[]},
            permanent, 10000, supervisor, [mod_task_zyl]}),
    ok.

%% 开启护送监控
start_husong() ->
    {ok, _} = supervisor:start_child(
        gs_sup,
        {timer_husong,
            {timer_husong, start_link, []},
            permanent, 10000, supervisor, [timer_husong]}),
    ok.

%% 答题服务器
start_quiz_server() ->
    %加载题库
    lib_quiz:load_quiz(),
    ok.

%% %%每日次数
%% start_daily() ->
%%     {ok,_} = supervisor:start_child(
%%                gs_sup,
%%                {mod_daily,
%%                 {mod_daily, start_link,[]},
%%                 permanent, 10000, supervisor, [mod_daily]}),
%%     ok.

%%每日次数(不记录数据库)
start_daily_dict() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_daily_dict,
                {mod_daily_dict, start_link,[]},
                permanent, 10000, supervisor, [mod_daily_dict]}),
    ok.

%% 物品掉落
start_drop() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_drop,
                {mod_drop, start_link,[]},
                permanent, 10000, supervisor, [mod_drop]}),
    ok.

%%排行榜
start_rank() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_rank,
                {mod_rank, start_link,[]},
                permanent, 10000, supervisor, [mod_rank]}),
    ok.

%%开启定时器监控树(生肖大奖)
%start_timer_unite_shengxiao20_frame() ->
%	{ok,_} = supervisor:start_child(
%        gs_sup,
%        {timer_unite_shengxiao20_frame,
%            {timer_unite_shengxiao20_frame, start_link,[]},
%            permanent, 10000, supervisor, [timer_unite_shengxiao20_frame]}),
%    ok.

%%开启半分钟定时器监控树
start_timer_unite_min() ->
    {ok,_} = supervisor:start_child(
	       gs_sup,
	       {timer_unite_min,
		{timer_unite_min, start_link,[]},
		permanent, 10000, supervisor, [timer_unite_min]}),
    ok.

%% 开启订单处理进程
start_timer_unite_pay() ->
    {ok,_} = supervisor:start_child(
	       gs_sup,
	       {timer_unite_pay,
		{timer_unite_pay, start_link,[]},
		permanent, 10000, supervisor, [timer_unite_pay]}),
    ok.

%% 统计在线
start_mod_online() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_online,
                {mod_online, start_link,[]},
                permanent, 10000, supervisor, [mod_online]}),
    ok.

%%开启BOSS监控树.
start_boss() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_boss,
                {mod_boss, start_link,[]},
                permanent, 10000, supervisor, [mod_boss]}),
    ok.

%%开启怪物攻城监控树.
%start_monster_siege() ->
%    {ok,_} = supervisor:start_child(
%               gs_sup,
%               {mod_monster_siege,
%                {mod_monster_siege, start_link,[]},
%                permanent, 10000, supervisor, [mod_monster_siege]}),
%    ok.

%% 开启清除怪物定时器
start_clear_mon_timer() ->
	{ok,_} = supervisor:start_child(
        gs_sup,
        {mod_app,
            {mod_app, start_link,[]},
            permanent, 10000, supervisor, []}),
    ok.

%%关闭南天门
%% %%开启大闹天宫监控树
%% start_wubianhai_new() ->
%%     {ok,_} = supervisor:start_child(
%%         gs_sup,
%%         {mod_wubianhai_new,
%%             {mod_wubianhai_new, start_link,[]},
%%             permanent, 10000, supervisor, [mod_wubianhai_new]}),
%%     ok.
%% %%开启大闹天宫管理器监控树
%% start_wubianhai_mgr_new() ->
%%     {ok,_} = supervisor:start_child(
%%         gs_sup,
%%         {mod_wubianhai_mgr_new,
%%             {mod_wubianhai_mgr_new, at_start_link,[]},
%%             permanent, 10000, supervisor, [mod_wubianhai_mgr_new]}),
%%     ok.

%%开启名人堂
start_fame() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_fame,
                {mod_fame, start_link,[]},
                permanent, 10000, supervisor, [mod_fame]}),
    ok.

%% 换线排队
start_change_line_queue() ->
    {ok,_} = supervisor:start_child(
               gs_sup,
               {mod_change_scene,
                {mod_change_scene, start_link,[]},
                permanent, 10000, supervisor, [mod_change_scene]}),
    ok.

%%开启爱情长跑监控树
%start_loverun() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_loverun,
%            {mod_loverun, start_link, []},
%            permanent, 10000, supervisor, [mod_loverun]}),
%    ok.
%
%%%开启爱情长跑管理器监控树
%start_loverun_mgr() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_loverun_mgr,
%            {mod_loverun_mgr, at_start_link, []},
%            permanent, 10000, supervisor, [mod_loverun_mgr]}),
%    ok.

%%摇钱树
start_shake_money() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_shake_money,
            {mod_shake_money, start_link, []},
            permanent, 10000, supervisor, [mod_shake_money]}),
    ok.

%%结婚
start_marriage() ->
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_marriage,
            {mod_marriage, start_link, []},
            permanent, 10000, supervisor, [mod_marriage]}),
    ok.

%% 限时名人堂（活动） 
start_fame_limit_rank() ->
	{ok,_} = supervisor:start_child(
		gs_sup,
		{mod_fame_limit,
			{mod_fame_limit, start_link,[]},
			permanent, 10000, supervisor, [mod_fame_limit]}),
	ok.

%% 聊天禁言
start_chat_forbid() ->
	{ok,_} = supervisor:start_child(
		gs_sup,
		{mod_chat_forbid,
			{mod_chat_forbid, start, []},
			permanent, 10000, supervisor, [mod_chat_forbid]}),
	ok.

start_qixi() ->
    {ok,_} = supervisor:start_child(
	       gs_sup,
	       {mod_qixi,
		{mod_qixi, start_link, []},
		permanent, 10000, supervisor, [mod_qixi]}),
    ok.
    
start_pet_refresh_skill_notice() ->
    {ok,_} = supervisor:start_child(
	       gs_sup,
	       {mod_pet_refresh_skill,
		{mod_pet_refresh_skill, start_link, []},
		permanent, 10000, supervisor, [mod_pet_refresh_skill]}),
    ok.   

start_activity_festival() ->
	{ok,_} = supervisor:start_child(
		gs_sup,
		{mod_activity_festival,
			{mod_activity_festival, start, []},
			permanent, 10000, supervisor, [mod_activity_festival]}),
	ok.

%%开启城战监控树
%start_city_war() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_city_war,
%            {mod_city_war, start_link,[]},
%            permanent, 10000, supervisor, [mod_city_war]}),
%    ok.
%%%开启城战管理器监控树
%start_city_war_mgr() ->
%    {ok,_} = supervisor:start_child(
%        gs_sup,
%        {mod_city_war_mgr,
%            {mod_city_war_mgr, at_start_link,[]},
%            permanent, 10000, supervisor, [mod_city_war_mgr]}),
%    ok.
%% 开启数秒定时器监控树
start_timer_unite_fewsecond() ->
	{ok,_} = supervisor:start_child(
        gs_sup,
        {timer_unite_fewsecond,
            {timer_unite_fewsecond, start_link,[]},
            permanent, 10000, supervisor, [timer_unite_fewsecond]}),
    ok.

%% 开启VIP副本监控树
start_vip_dun() ->
	{ok,_} = supervisor:start_child(
        gs_sup,
        {mod_vip_dun,
            {mod_vip_dun, start_link,[]},
            permanent, 10000, supervisor, [mod_vip_dun]}),
    ok.


%% 开启帮派活动监控树
start_guild_dun() ->
	{ok,_} = supervisor:start_child(
        gs_sup,
        {mod_guild_dun,
            {mod_guild_dun, start_link,[]},
            permanent, 10000, supervisor, [mod_guild_dun]}),
    ok.

%% 开启语音聊天监控树
start_voice_chat() -> 
    {ok,_} = supervisor:start_child(
        gs_sup,
        {mod_chat_voice,
            {mod_chat_voice, start_link,[]},
            permanent, 10000, supervisor, [mod_chat_voice]}),
    ok.
