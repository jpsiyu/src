%%%------------------------------------
%%% @Module  : mod_unite_init
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.06.30
%%% @Description: 公共线数据初始化
%%%------------------------------------
-module(mod_unite_init).
-behaviour(gen_server).
-export([
            start_link/0,
            init_mysql/0
        ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("common.hrl").
-include("unite.hrl").
-include("box.hrl").
-include("record.hrl").
-include("guild.hrl").
-include("team.hrl").
-include("dungeon.hrl").
-include("outline.hrl").
-include("appointment.hrl").
-include("mail.hrl").
-include("shop.hrl").
-include("sell.hrl").
-include("goods.hrl").
-include("drop.hrl").
-include("quiz.hrl").
-include("rank.hrl").
-include("tower.hrl").
-include("buff.hrl").
-include("rela.hrl").
-include("hotspring.hrl").
-include("fame_limit.hrl").
-include("pet.hrl").

start_link() ->
    gen_server:start_link({local,?MODULE}, ?MODULE, [], []).

init([]) ->
    %%初始ets表
    ok = init_ets(),
    %%初始mysql
    ok = init_mysql(),
    %%设置在线状体为0
    lib_player:set_online(),
    ok = init_box(),
    %% 公共线物品
    ok = lib_goods_init:init_unite_goods(),
    %% 求购市场
%%     ok = lib_buy:init_buy(),
	%% 爬塔副本初始化.
	lib_tower_dungeon:get_master(),
	%% 加载所有剧情副本霸主.
	lib_story_master:load_story_masters(),
    %% 加载装备副本霸主
    lib_equip_master:load_equip_masters(),
	vip_buff_dict:start_link(),
	mod_exit:start_link(),
	mod_task_cumulate:start_link(),
	buff_dict:start_link(),
	mod_gjpt:start_link(),
	mod_revive:start_link(),
    %% 刷新一次限时抢购，防止合服后没有物品
    spawn(fun() -> timer:sleep(60000),lib_shop:init_limit_shop({0,0,0}) end),
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

%%初始ETS表
init_ets() ->
    %% 节点
    ets:new(?ETS_NODE, [{keypos, #node.id}, named_table, public, set]),
    ets:new(?SERVER_STATUS, [{keypos,#server_status.name}, named_table, public, set]),  %%服务器信息   
    %% 答题相关    
	ets:new(?ETS_QUIZ, [{keypos, #ets_quiz.id}, named_table, public, set]), %% 答题活动日常题库
	ets:new(?ETS_QUIZ_OTHER, [{keypos, #ets_quiz.id}, named_table, public, set]), %% 答题活动主题题库
    ets:new(?ETS_QUIZ_S, [{keypos, #ets_quiz_s.id}, named_table, public, set]), %% 答题活动题库
    ets:new(ets_quiz_answer, [{keypos, #quiz_answer.role_id}, named_table, public, set]),   %%答案题库
    ets:new(ets_quiz_member, [{keypos, #quiz_member.role_id}, named_table, public, set]),   %%报名题库
    ets:new(quiz_process, [{keypos, #quiz_process.id}, named_table, public, set]),          %%报名题库        
    %% 宝箱全局计数
    ets:new(?ETS_BOX_COUNTER, [{keypos, #ets_box_counter.box_id}, named_table, public, set]),
    %% 宝箱单玩家计数
    ets:new(?ETS_BOX_PLAYER_COUNTER, [{keypos, #ets_box_player_counter.pid}, named_table, public, set]),
    %% 限时热买
    ets:new(?ETS_LIMIT_SHOP, [{keypos, #ets_limit_shop.id}, named_table, public, set]),
    %% 市场交易
    ets:new(?ETS_SELL, [{keypos, #ets_sell.id}, named_table, public, set]),
    %% 求购市场
    ets:new(?ETS_BUY, [{keypos, #ets_buy.id}, named_table, public, set]),
    %% 挂售市场物品表
    ets:new(?ETS_SELL_GOODS, [{keypos, #goods.id}, named_table, public, set]),          
    %% 好友
    ets:new(?ETS_RELA_INFO, [{keypos,#ets_rela_info.id}, named_table, public, set]), %%好友资料
    %% 帮派表
    %% ets:new(?ETS_GUILD, [{keypos, #ets_guild.id}, named_table, public, set]), 
	%% 帮派成员
    %% ets:new(?ETS_GUILD_MEMBER, [{keypos, #ets_guild_member.id}, named_table, public, set]),
	%% 帮派申请
    %% ets:new(?ETS_GUILD_APPLY, [{keypos, #ets_guild_apply.id}, named_table, public, set]),
    %% 帮派邀请
    %% ets:new(?ETS_GUILD_INVITE, [{keypos, #ets_guild_invite.id}, named_table, public, set]),
    %% 帮派奖励物品表
    %% ets:new(?ETS_GUILD_AWARD, [{keypos, #ets_guild_award.guild_id}, named_table, public, set]), 
    %% 帮派成员奖励物品表
    %% ets:new(?ETS_GUILD_AWARD_ALLOC, [{keypos, #ets_guild_award_alloc.id}, named_table, public, set]), 
    %% 帮派成员技能
    %% ets:new(?ETS_GUILD_MEMBER_SKILL, [{keypos, #ets_guild_member_skill.id}, named_table, public, set]),
    %% 帮派技能
    %% ets:new(?ETS_GUILD_SKILL, [{keypos, #ets_guild_skill.id}, named_table, public, set]),
    %% 帮派线路独占信息
    %% ets:new(?ETS_GUILD_EXCLUSIVE, [{keypos, #ets_guild_exclusive.guild_id}, named_table, public, set]),
    %% 组队招募
    ets:new(?ETS_TEAM_ENLIST, [{keypos, #ets_team_enlist.id}, named_table, public, ordered_set]), 
    %ets:new(?ETS_TMB_OFFLINE, [named_table, public, set, {keypos, #ets_tmb_offline.id}]), %% 队伍暂离成员列表
    %% 副本招募
    %%ets:new(?ETS_DUNGEON_ENLIST2, [{keypos, #ets_dungeon_enlist2.id}, named_table, public, set]), 
    %% 副本招募
	%% ets:new(?ETS_DUNGEON_ENLIST,  [named_table, public, set, {keypos, #ets_dungeon_enlist.id}]),  
	%% 爬塔霸主副本表
	ets:new(?ETS_TOWER_MASTER, [named_table, public, set, {keypos, #ets_tower_master.sid}]),
	%% 剧情副本霸主副本表
	ets:new(?ETS_STORY_MASTER, [named_table, public, set, {keypos, #ets_story_master.chapter}]),
    %% 装备副本霸主表
    ets:new(?ETS_EQUIP_MASTER, [named_table, public, set, {keypos, #dntk_equip_dun_master.dun_id}]),
    %% 砸蛋公告表
    ets:new(?ETS_EGG_INFO, [named_table, public, set, {keypos, #egg_log_notice.key}]),
    %% 组队缓存
    ets:new(?ETS_TEAM, [named_table, public, set, {keypos, #ets_team.team_pid}]), 
    %% 仙侣奇缘
    ets:new(?ETS_APPOINTMENT_CONFIG, [named_table, public, set, {keypos, #ets_appointment_config.id}]),    
	ets:new(?ETS_APPOINTMENT_GAME,   [named_table, public, set, {keypos, #ets_appointment_game.id}]),
    %% 怪物掉落物品计数器
    ets:new(?ETS_MON_GOODS_COUNTER, [{keypos, #ets_mon_goods_counter.goods_id}, named_table, public, set]), 
    %% 怪物物品掉落系数
    ets:new(?ETS_DROP_FACTOR, [{keypos, #ets_drop_factor.id}, named_table, public, set]), 
    %% 本服一般排行榜ets
    ets:new(?ETS_RANK, [named_table, public, set, {keypos, #ets_rank.type_id}]),
	%% 本地缓存跨服竞技排行榜ets
    ets:new(?RK_KF_1V1_CACHE_RANK, [named_table, public, set, {keypos, #ets_kf_1v1_cache_rank.type_id}]),
	lib_rank_cls:init_kf_1v1_ets(),
	%% 本地缓存跨服一般排行榜ets
    ets:new(?RK_KF_CACHE_RANK, [named_table, public, set, {keypos, #ets_kf_cache_rank.type_id}]),
    %% 排行榜角色信息
    ets:new(?ETS_ROLE_RANK_INFO, [{keypos, #ets_role_rank_info.role_id}, named_table, public, set]),
	%% 本服模块排行榜ets
	ets:new(?MODULE_RANK, [named_table, public, set, {keypos, #ets_module_rank.type_id}]),
    %% 系统公告
    ets:new(ets_sys_notice, [named_table, public, set]),
	%% 沙滩魅力榜
	ets:new(ets_hotspring, [{keypos, #ets_hotspring.id}, named_table, public, set]),
	%% 沙滩互动玩家列表
	ets:new(ets_hotspring_interact, [{keypos, #ets_hotspring_interact.id}, named_table, public, set]),
	%% 限时名人堂（活动）
	ets:new(?ETS_FAME_LIMIT_RANK, [{keypos, #ets_fame_limit_rank.type_id}, named_table, public, set]),
	%% 老玩家列表
    ets:new(?ETS_OLD_BUCK, [named_table, public, set]), 
	ok.

%% 初始化开宝箱
init_box() ->
    lib_box:init_counter(),
    ok.
