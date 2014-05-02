%%%--------------------------------------
%%% @Module : timer_rank
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.5.31
%%% @Description :  排行榜定时器，10分钟会被调用一次
%%%--------------------------------------

-module(timer_rank).
-include("common.hrl").
-include("record.hrl").
-include("rank.hrl").
-include("sql_rank.hrl").
-export([
	init/0,			%% 初始化回调
	handle/1,		%% 处理状态变更回调
	terminate/2		%% 中止回调
]).

%% 用于mod_timer初始化状态时回调
%% @return {ok, State} | {ignore, Reason} | {stop, Reason}
init() ->
    {ok, []}.

%% gen_fsm状态变更回调
handle(State) ->
	%% 开服7天活动奖励处理（在第八天的时候会触发）
	%% 这里面的都是直接读表取数据发奖励，跟排行榜ets数据没联系
	private_seven_day_activity(),

	{ok, State}.

%% mod_timer终止回调
terminate(Reason, _State) ->
    ?DEBUG("timer_rank terminate, reason=[~w]~n", [Reason]),
    ok.


%% 开服7天活动奖励处理（在第八天的时候会触发）
private_seven_day_activity() ->
	%% 开服第8天才处理
	case util:get_open_day() == 8 of
		true ->
			%% 正常情况下，当天0点的第10分钟内就可以全部处理完成
			%% 如果定时器异常没有执行，在1天内只要定时器还在跑，也会继续处理
			[_Id, PlayerLevel, PlayerPower, PlayerMeridian, PlayerAchieve, PetLevel, 
			PetPower, DungeonNine, ArenaFighting, GuildFighting] = 
				case lib_rank_activity:get_handle_stat() of
					[] ->
						lib_rank_activity:insert_handle_stat(),
						[1, 0, 0, 0, 0, 0, 0, 0, 0, 0];
					Row ->
						Row
				end,

			HandleList = [
				{player_lv, PlayerLevel},
				{player_power, PlayerPower},
				{player_meridian, PlayerMeridian},
				{player_achieve, PlayerAchieve},
				{pet_lv, PetLevel},
				{pet_power, PetPower},
				{dungeon_nine, DungeonNine},
				{arena_fight, ArenaFighting},
				{guild_fight, GuildFighting}
			],
			lists:foreach(fun({Type, Value}) -> 
				private_seven_day_award(Type, Value)
			end, HandleList);
		_ ->
			ok
	end.

private_seven_day_award(Type, Value) ->
	FunConf = [
		{player_lv, lib_rank_activity, get_player_level_top},
		{player_power, lib_rank_activity, get_player_power_top},
		{player_meridian, lib_rank_activity, get_player_meridian_top},
		{player_achieve, lib_rank_activity, get_player_achieve_top},
		{pet_lv, lib_rank_activity, get_pet_level_top},
		{pet_power, lib_rank_activity, get_pet_power_top},
		{dungeon_nine, lib_rank_activity, get_ninesky_award},
		{arena_fight, lib_rank_activity, get_arena_fighting_award},
		{guild_fight, lib_rank_activity, get_guild_fighting_award}
	],
	case Value of
		1 -> skip;
		_ ->
			case lists:keyfind(Type, 1, FunConf) of
				{_, Mod, Fun} ->
					spawn(fun() ->
						Mod:Fun()
					end),

					timer:sleep(200);
				_ -> skip
			end
	end.
