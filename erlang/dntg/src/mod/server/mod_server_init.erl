%%%------------------------------------
%%% @Module  : mod_server_init
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.06.14
%%% @Description: 数据初始化
%%%------------------------------------
-module(mod_server_init).
-behaviour(gen_server).
-export([
            start_link/0,
            init_mysql/0
        ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("common.hrl").
-include("record.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("skill.hrl").
-include("goods.hrl").
-include("guild.hrl").
-include("buff.hrl").
-include("outline.hrl").
-include("appointment.hrl").
-include("dungeon.hrl").
-include("task.hrl").
-include("gift.hrl").
-include("login_count.hrl").
-include("shop.hrl").
-include("drop.hrl").
-include("achieved.hrl").
-include("tower.hrl").
-include("rela.hrl").
-include("fame_limit.hrl").

start_link() ->
    gen_server:start_link({local,?MODULE}, ?MODULE, [], []).

init([]) ->
    %%初始ets表
    ok = init_ets(),
    %%初始mysql
    ok = init_mysql(),
    ok = init_server_status(),
	mod_fcm:start_link(),
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
    db:start(DbHost, DbPort, DbUser, DbPass, DbName, DbEncode, 15), 
    ok.

%%初始ETS表
init_ets() ->
    %% 节点
    ets:new(?ETS_NODE, [{keypos, #node.id}, named_table, public, set]),
    ets:new(?SERVER_STATUS, [{keypos,#server_status.name}, named_table, public, set]), %%服务器信息
    %% 职业选择
    ets:new(ets_career_count, [named_table, public, set]),
    %% 玩家在线数据
    ets:new(?ETS_ONLINE, [{keypos,#ets_online.id}, named_table, public, set]),
    %%用户场景信息
    ets:new(?ETS_SCENE, [{keypos, #ets_scene.id}, named_table, public, set]),
	%% 玩家血包ETS 
	ets:new(?ETS_HP_BAG, [{keypos, #ets_hp_bag.id}, named_table, public, set]),
     %% %% 活动礼包表
    ets:new(?ETS_GIFT, [{keypos, #ets_gift2.id}, named_table, public, set]),
    %% 限时热买
    ets:new(?ETS_LIMIT_SHOP, [{keypos, #ets_limit_shop.id}, named_table, public, set]),
    %% 连续登录
    ets:new(?ETS_LOGIN_COUNTER, [{keypos, #ets_login_counter.id}, named_table, public, set]), 
	%% 二级密码
	ets:new(?SECONDARY_PASSWORD, [{keypos, #secondary_password.id}, named_table, public, set]),
%% 	%% 帮战结果
%% 	ets:new(?ETS_GUILD_BATTLE_RESULT, [{keypos, #ets_guild_battle_result.id}, named_table, public, set]),
%% 	%% 帮战成员信息
%% 	ets:new(?ETS_GUILD_BATTLE_MEMBER_INFO, [{keypos, #ets_guild_battle_member_info.id}, named_table, public, set]),
%% 	%% 帮战成员结果
%% 	ets:new(?ETS_GUILD_BATTLE_MEMBER_RESULT, [{keypos, #ets_guild_battle_member_result.id}, named_table, public, set]),
%% 	%% 帮战场景
%% 	ets:new(?ETS_GUILD_BATTLE_SCENE, [{keypos, #ets_guild_battle_scene.id}, named_table, public, set]),
%% 	%% 帮派奖励物品配置表
%% 	ets:new(?ETS_BASE_GUILD_BATTLE_AWARD, [{keypos, #ets_base_guild_battle_award.guild_rank}, named_table, public, set]),
%% 	%% 仙侣
%% 	ets:new(?ETS_APPOINTMENT, [named_table, public, set, {keypos, #ets_appointment.id}]), 
%% 	%% 仙侣题目
%% 	ets:new(?ETS_APPOINTMENT_SUBJECT,  [named_table, public, set, {keypos, #ets_appointment_subject.id}]),
%% 	%% 仙侣题目
%% 	ets:new(?ETS_APPOINTMENT_SPECIAL_SUBJECT,  [named_table, public, set, {keypos, #ets_appointment_special_subject.id}]),
    %%委托任务
    ets:new(?ETS_ROLE_TASK_AUTO, [{keypos, #role_task_auto.id}, named_table, public, set]), 
    %% 游戏世界buff
    ets:new(?ETS_GAME_BUFF, [named_table, public, set, {keypos, #ets_game_buff.id}]),  
    %% 成就列表
    ets:new(?ETS_CHENGJIU,  [named_table, public, set, {keypos, #ets_chengjiu.id}]),            
    %% 成就奖励列表
    ets:new(?ETS_CHENGJIU_AWARD,  [named_table, public, set, {keypos, #ets_chengjiu_award.id}]),
    %% 角色成就列表
    ets:new(?PLAYER_CHENGJIU,  [named_table, public, set, {keypos, #player_chengjiu.id}]),
	%% 玩家拥有称号表
%% 	ets:new(?ETS_ROLE_DESIGNATION, [named_table, public, set, {keypos, #role_designation.id}]),
    %% 所有场景信息表
    ets:new(ets_load_all_scene, [named_table, public, set]),
	%% 铜币副本表
	ets:new(?ETS_COIN_DUNGEON, [named_table, public, set, {keypos, #ets_coin_dungeon.player_id}]), 
	%% 宠物副本表
	ets:new(?ETS_PET_DUNGEON, [named_table, public, set, {keypos, #ets_pet_dungeon.dungeon_pid}]),
	%% 限时名人堂（活动）雕像表
 	ets:new(?ETS_FAME_LIMIT_STATUE, [named_table, public, set, {keypos, #ets_fame_limit_statue.type}]),
	%% 老玩家列表
    ets:new(?ETS_OLD_BUCK, [named_table, public, set]), 
    ok.

init_server_status() ->
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
	%% 初始化名人堂
	lib_fame:server_start(),
    ok.
