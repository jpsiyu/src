%%%--------------------------------------
%%% @Module  : mod_rank
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.5.31
%%% @Description :  排行榜
%%%--------------------------------------

-module(mod_rank).
-behaviour(gen_server).
-include("common.hrl").
-include("rank.hrl").
-include("sql_rank.hrl").
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% 启动服务
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 按类型刷新排行榜
refresh_rank(RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate) ->
	gen_server:cast(?MODULE, {'refresh_rank', RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate}).

%% 每天凌晨按类型刷新排行榜
timer_refresh_rank(RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate) ->
	gen_server:cast(?MODULE, {'timer_refresh_rank', RoleUpdate, PetUpdate, EquipUpdate, GuildUpdate, ArenaUpdate, CopyUpdate, CharmUpdate, MountUpdate}).

%% 刷单个榜
refresh_single(RankType) ->
	gen_server:cast(?MODULE, {'refresh_single', RankType}).

%% 刷单个榜
timer_refresh_single(RankType) ->
	gen_server:cast(?MODULE, {'timer_refresh_single', RankType}).

%% 更新排行榜名人堂荣誉完成情况
update_fame(FameId, PlayerList) ->
	gen_server:cast(?MODULE, {'update_fame', FameId, PlayerList}).

%% 刷新玩家战力榜
refresh_rank_of_player_power(Row) ->
	gen_server:cast(?MODULE, {'refresh_rank_of_player_power', Row}).

%% 刷新魅力榜，每3分钟刷新一次
refresh_flower_rank(RefreshData) ->
	gen_server:cast(?MODULE, {'refresh_flower_rank', RefreshData}).

%% 清理角色榜的装备数据
clean_role_rank_equip_info() ->
    gen_server:cast(?MODULE, 'clean_role_rank_equip_info').

%% 更新装备排行榜
update_equip_rank(GoodsInfoList) ->
    gen_server:cast(?MODULE, {'update_equip_rank', GoodsInfoList}).

%% 更新玩家等级榜
update_player_level_rank(Row) ->
    gen_server:cast(?MODULE, {'update_player_level_rank', Row}).

%% 获取排行榜前50级玩家等级平均值
get_average_level() ->
	gen_server:call(?MODULE, {'get_average_level'}).

%% 获取世界等级
%% 返回：{世界等级, 更新时间}
get_world_level() ->
	gen_server:call(?MODULE, {'get_world_level'}).

%% 刷新每日竞技场排行榜，120秒后开始刷新
refresh_arena_day() ->
	timer:apply_after(120 * 1000, mod_rank, refresh_arena_day2, []).

%% 刷新竞技场每日上榜
refresh_arena_day2() ->
	lib_rank:refresh_arena_day().

refresh_fame_limit_rank() ->
	case lib_fame_limit:in_activity_time() of
		true ->
			lib_fame_limit:refresh_fame_limit_rank();
		_ ->
			skip
	end.

%% 变性
%% Sex : 1男，2女
change_sex(RoleId, Sex) ->
	gen_server:cast(?MODULE, {'change_sex', RoleId, Sex}).

%% [管理后台秘籍] 刷新单个榜
%% TimerType : 1走定时器模式，会触发活动奖励等，0只是刷新榜单数据
refresh_single_in_manage(RankType, TimerType) ->
	case lists:member(RankType, ?RK_TIMER_REFRESH_IDS) of
		true ->
			case TimerType of
				1 ->
					mod_disperse:cast_to_unite(mod_rank, timer_refresh_single, [RankType]);
				_ ->
					mod_disperse:cast_to_unite(mod_rank, refresh_single, [RankType])
			end,
			ok;
		_ ->
			fail
	end.

%% [管理后台秘籍] 刷新所有榜
%% 只是纯刷新数据到排行榜，不会触发活动
refresh_all_in_manage() ->
	Now = util:unixtime(),
	case get(mod_rank_refresh_all_in_manage) of
		undefined ->
			mod_disperse:cast_to_unite(mod_rank, refresh_rank, [true, true, true, true, true, true, true, true]),
			put(mod_rank_refresh_all_in_manage, Now);
		Value ->
			case Value + 60 > Now of
				true ->
					skip;
		    	_ ->
					mod_disperse:cast_to_unite(mod_rank, refresh_rank, [true, true, true, true, true, true, true, true]),
					put(mod_rank_refresh_all_in_manage, Now)
			end
	end,
	ok.

%% 清跨服排行榜缓存
remove_cls_rank(_Data) ->
	gen_server:cast(?MODULE, {'remove_cls_rank'}).

%% 重新设置游戏节点这边的跨服1v1排行榜数据
%% Data : [{RankType, List}, ...]
reset_kf_1v1_rank(Data) ->
	gen_server:cast(?MODULE, {'reset_kf_1v1_rank', Data}).

%% 重新设置游戏节点这边的跨服排行榜数据
%% Data : [{RankType, List}, ...]
reset_kf_rank(Data) ->
	gen_server:cast(?MODULE, {'reset_kf_rank', Data}).

%% 玩家进入跨服之后，更新跨服排行榜数据
remote_update_kf_rank(_DailyPid, RoleId) ->
	case lib_rank_cls:game_kf_rank_switch() of
		true ->
			case mod_daily_dict:get_count(RoleId, 8900) of
				0 ->
					gen_server:cast(?MODULE, {'remote_update_kf_rank', [RoleId]}),
					mod_daily_dict:set_count(RoleId, 8900, util:unixtime());
				Time ->
					NowTime = util:unixtime(),
					SecondTime = util:unixdate(NowTime) + 14 * 3600,
					case SecondTime > Time of
						true ->
							gen_server:cast(?MODULE, {'remote_update_kf_rank', [RoleId]}),
							mod_daily_dict:set_count(RoleId, 8900, SecondTime);
						_ ->
							skip
					end
			end;
		_ ->
			skip
	end.

%% 清除跨服排行榜缓存
remove_kf_rank_cache([]) ->
	gen_server:cast(?MODULE, {'remove_kf_rank_cache'}).
remove_kf_rank_cache() ->
	gen_server:cast(?MODULE, {'remove_kf_rank_cache'}).


%% [斗战封神活动] 设置排行榜缓存
kfrank_reset_power_list(Platform, ServerId, Id, List) ->
	gen_server:cast(?MODULE, {'kfrank_reset_power_list', Platform, ServerId, Id, List}).

stop() ->
    gen_server:call(?MODULE, stop).


init([]) ->
	process_flag(trap_exit, true),
	%% 初始化排行榜数据
	lib_rank:unite_start(),
	%% 刷新一次排行榜
 	refresh_rank(true, true, true, true, true, true, true, true),
	%% 刷新一次本服跨服3v3周积分榜
	lib_kf_3v3_rank:refresh_bd_week_rank(),

	{ok, #rank_state{}}.

handle_call(Request, From, State) ->
    mod_rank_call:handle_call(Request, From, State).

handle_cast(Msg, State) ->
    mod_rank_cast:handle_cast(Msg, State).

handle_info(Info, State) ->
    mod_rank_info:handle_info(Info, State).

terminate(_Reason, _State) ->
    ?ERR("~nmod_rank terminate reason: ~w~n", [_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

