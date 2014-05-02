%% --------------------------------------------------------
%% @Module:           |mod_guild_godanimal_timer
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-00-00
%% @Description:      |帮派神兽_妖兽召唤战 
%% --------------------------------------------------------
-module(mod_guild_godanimal_timer).
-behaviour(gen_fsm).
-include("guild.hrl").
-include("scene.hrl").
-export([start_link/1, init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).
-compile(export_all).

-define(GA_TIMEOUT_BASE, 5 * 1000). 	 	 		%% 计时基础周期 1 秒
-define(GA_TIME_LAST, 15 * 60). 	 				%% 战斗持续时间 每15秒BOSS掉1%血,战斗持续 
-define(GA_TIME_XG_CALL, 180). 	 					%% 英雄模式召唤小怪间隔 180 秒
-define(GA_TIME_XG_DIE, 15). 	 					%% 英雄模式召唤小怪间隔 180 秒

-define(GA_TIME_XG_TBXB, 1). 	 					%% 通报小兵
-define(GA_TIME_XG_YJDW, 2). 	 					%% 淫叫大王
-define(GA_TIME_XG_JYXB, 3). 	 					%% 精英小兵

%% 设定神兽战RECORD
-record(god_animal_battle, {guild_id = 0		 	 										%% 帮派ID
							, ga_id = 0		 	 											%% 妖兽怪物ID
							, ga_lv = 0	 	 												%% 神兽等级
						    , ga_difficulty	= 0 											%% 神兽难度等级 0 简单 1 普通 
						    , ga_xiaoguai 													%% 小怪字典
					   		, start_god_animal_time = 0 									%% 开始时间
					   		, stop_god_animal_time = 0 										%% 结束时间
							, roll_end_time = 0 											%% Roll点结束时间
							, roll_times = 0 											    %% Roll装备次数
							, fighters 	 													%% 战斗者字典_dict
							, fight_rank = []
						   }).

start_link([GALV, StartTime, GuildId, HType]) ->
        gen_fsm:start({global,?GGATIMER ++ integer_to_list(GuildId)}
					  , ?MODULE
					  , [GALV, StartTime, GuildId, HType]
					  , []).

init([GALV, StartTime, GuildId, HType])->
	NowTime  = util:unixtime(),
	NowData = util:unixdate(),
	StartAfter = NowData + StartTime * 60 * 30 - NowTime,	%% 开始时间差
	SleepTime = case StartAfter > 0 of
		true->
			StartAfter * 1000;
		false ->
			0
	end,
	io:format("StartTime ~p ~p ~p ~n", [NowData, NowTime, StartTime]),
	EndAfter = StartAfter + ?GA_TIME_LAST, 					%% 开始时间
	NewDict = dict:new(),
    Status = #god_animal_battle{guild_id = GuildId
							   , ga_lv = GALV
							   , ga_difficulty = HType
							   , ga_xiaoguai = NewDict
							   , fighters = NewDict
							   , start_god_animal_time = StartAfter + NowTime					
							   , stop_god_animal_time = EndAfter + NowTime},
    {ok, waiting_call, Status, SleepTime}.

%% --------------------------------------------------------------------------
%% 帮派神兽_等待召唤
%% --------------------------------------------------------------------------
waiting_call(timeout, Status) ->
	MonId = case Status#god_animal_battle.ga_difficulty of
		0 ->%% 简单
			lib_guild_scene:guild_godanimal_call([Status#god_animal_battle.guild_id, Status#god_animal_battle.ga_lv]);
		1 ->%% 普通
			IDSL = lib_guild_scene:guild_godanimal_call_h([Status#god_animal_battle.guild_id, Status#god_animal_battle.ga_lv, Status#god_animal_battle.ga_difficulty]),
%% 			erlang:spawn(fun() ->
%% 				  timer:sleep(30 * 1000),
%% 				  lib_guild_scene:guild_call_tsst([Status#god_animal_battle.guild_id, Status#god_animal_battle.ga_lv])
%% 		    end),
			IDSL;
		_ -> %% 错误的类型,走简单类型
			lib_guild_scene:guild_godanimal_call([Status#god_animal_battle.guild_id, Status#god_animal_battle.ga_lv])
	end,
	NewStatus = Status#god_animal_battle{ga_id = MonId},
	mod_disperse:cast_to_unite(lib_guild, send_guild, [Status#god_animal_battle.guild_id, guild_godanimal_start, [1]]),
	NowTime  = util:unixtime(),
	log_ga_start(Status#god_animal_battle.guild_id, Status#god_animal_battle.ga_lv, NowTime),
	{next_state, waitting, NewStatus, 0}.

%% --------------------------------------------------------------------------
%% 帮派神兽_妖兽战处理
%% --------------------------------------------------------------------------
waitting(timeout, Status) ->
	NowTime  = util:unixtime(),
	case Status#god_animal_battle.ga_difficulty of
		1 ->%% 普通
			case (Status#god_animal_battle.stop_god_animal_time - NowTime) >= 0 of
				true -> %% 时间未到
					TimeLast = ?GA_TIME_LAST - (Status#god_animal_battle.stop_god_animal_time - NowTime),
					{XGNum, XGId, YJId, JYIdList} = case dict:find(?GA_TIME_XG_TBXB, Status#god_animal_battle.ga_xiaoguai) of
						{ok, {XGNum0, XGId0}} ->
							case dict:find(?GA_TIME_XG_YJDW, Status#god_animal_battle.ga_xiaoguai) of
								{ok, YJId0} ->
									case dict:find(?GA_TIME_XG_JYXB, Status#god_animal_battle.ga_xiaoguai) of
										{ok, JYIdList0} ->
											{XGNum0, XGId0, YJId0, JYIdList0};
										_ ->
											{XGNum0, XGId0, YJId0, []}
									end;
								_ ->
									{XGNum0, XGId0, 0, []}
							end;
						_ ->
							{0, 0, 0, []}
					end,
					%% 判断是否到时间召唤精英小怪或银角
					XiaoGuaiDict0 = case TimeLast >= XGNum * (?GA_TIME_XG_CALL + ?GA_TIME_XG_DIE) andalso XGId =/= 0 of
						true -> 
							%% 清除小怪
                            lib_mon:clear_scene_mon_by_mids(?GUILD_SCENE, Status#god_animal_battle.guild_id, 1, [10606]),
							%% 判断召唤
							{Type, Value} = case YJId =:= 0 of
								true ->
									lib_guild_scene:guild_call_yjdw([Status#god_animal_battle.guild_id, Status#god_animal_battle.ga_lv]);
								false -> %% 小怪要叠加
									{_, NewList} = lib_guild_scene:guild_call_jyxg([Status#god_animal_battle.guild_id, Status#god_animal_battle.ga_lv]),
									{?GA_TIME_XG_JYXB, JYIdList ++ NewList}
							end,
							%% 修改数据
							ST1 = dict:store(?GA_TIME_XG_TBXB, {XGNum, 0}, Status#god_animal_battle.ga_xiaoguai),
							dict:store(Type, Value, ST1);
						_ ->
							Status#god_animal_battle.ga_xiaoguai
					end,
					%% 判断是否要召唤小怪
					XiaoGuaiDict1 = case TimeLast >= (XGNum + 1) * (?GA_TIME_XG_CALL) of
						true -> 
							%% 召唤小怪
							{TypeTb, ValueTb} = lib_guild_scene:guild_call_tbxb([Status#god_animal_battle.guild_id, Status#god_animal_battle.ga_lv]),
							%% 修改数据
							dict:store(TypeTb, {XGNum + 1, ValueTb}, XiaoGuaiDict0);
						_ ->
							XiaoGuaiDict0
					end,
					NewStatus0 = Status#god_animal_battle{ga_xiaoguai = XiaoGuaiDict1},
					case guild_godanimal_send_rank(NewStatus0) of
						{ok, killed} -> %% 时间未到前 神兽进程 不存在了 (判定成功击杀)
							start_roll(NewStatus0);
						{ok, fighting, RankInfo, DamageList, HpLim, HpNow} -> %% 战斗进行中 
							TsstIdOld = get(tsstid),
							TsstId = lib_guild_scene:guild_call_tsst([Status#god_animal_battle.guild_id
																	, Status#god_animal_battle.ga_lv
																	, Status#god_animal_battle.start_god_animal_time
																	, NowTime
																	, HpLim
																	, HpNow
																	, TsstIdOld]),
							put(tsstid, TsstId),
							Dict1 = NewStatus0#god_animal_battle.fighters,
							DictNew = rank_loop1(DamageList, Dict1),
							NewStatus = NewStatus0#god_animal_battle{fight_rank = RankInfo, fighters = DictNew},
							{next_state, waitting, NewStatus, ?GA_TIMEOUT_BASE}
					end;
				_ -> %% 时间到
					time_over_handle(Status),
					{stop, normal, Status}
			end;
		_ -> %% 走简单类型
			case (Status#god_animal_battle.stop_god_animal_time - NowTime) >= 0 of
				true -> %% 时间未到
					case guild_godanimal_send_rank(Status) of
						{ok, killed} -> %% 时间未到前 神兽进程 不存在了 (判定成功击杀)
							start_roll(Status);
						{ok, fighting, RankInfo, DamageList, _HpLim, _HpNow} -> %% 战斗进行中 
							Dict1 = Status#god_animal_battle.fighters,
							DictNew = rank_loop1(DamageList, Dict1),
							NewStatus = Status#god_animal_battle{fight_rank = RankInfo, fighters = DictNew},
							{next_state, waitting, NewStatus, ?GA_TIMEOUT_BASE}
					end;
				_ -> %% 时间到
					time_over_handle(Status),
					{stop, normal, Status}
			end
	end.

rank_loop1([], DictNew) ->
	DictNew;
rank_loop1(Kinfo, DictOld) ->
	[{RoleId, Damage}|KinfoN] = Kinfo,
	DictNew = dict:store(RoleId, Damage, DictOld),
	rank_loop1(KinfoN, DictNew).

roll_dian(timeout, Status) ->
	case get(new_prize) of
		undefined ->
			{stop, normal, Status};
		Value ->
			[CheckTime, WPId, Length] = case Status#god_animal_battle.ga_difficulty of
				1 ->
					[{WPId1, RollEndTime1}, {WPId2, RollEndTime2}, {WPId3, RollEndTime3}, {WPId4, RollEndTime4}, {WPId5, RollEndTime5}, {WPId6, RollEndTime6}] = Value,
					NowTime  = util:unixtime(),
					case Status#god_animal_battle.roll_times of
						1 ->
							[RollEndTime1, WPId1, 6];
						2 ->
							[RollEndTime2, WPId2, 6];
						3 ->
							[RollEndTime3, WPId3, 6];
						4 ->
							[RollEndTime4, WPId4, 6];
						5 ->
							[RollEndTime5, WPId5, 6];
						6 ->
							[RollEndTime6, WPId6, 6];
						_ ->
							[over, 0, 6]
					end;
				_ ->
					[{WPId1, RollEndTime1}, {WPId2, RollEndTime2}, {WPId3, RollEndTime3}, {WPId4, RollEndTime4}] = Value,
					NowTime  = util:unixtime(),
					case Status#god_animal_battle.roll_times of
						1 ->
							[RollEndTime1, WPId1, 4];
						2 ->
							[RollEndTime2, WPId2, 4];
						3 ->
							[RollEndTime3, WPId3, 4];
						4 ->
							[RollEndTime4, WPId4, 4];
						_ ->
							[over, 0, 4]
					end
			end,
			case CheckTime of
				over -> 
					win_over_handle(Status),
					{stop, normal, Status};
				_ ->
					case NowTime >= CheckTime of
						false -> %% 时辰未到
							OverTime = (CheckTime - NowTime) * 1000,
							{next_state, roll_dian, Status, OverTime};
						true -> %% 时辰到了
							[Res, RoleId, RollDian, WinerList] = get_roll_winers(Status#god_animal_battle.roll_times, WPId),
							case Res =:= 1 of
								true ->
									{ok, BinData} = pt_401:write(40133, [WinerList, Length]),
									sand_to_rank(Status#god_animal_battle.fight_rank, BinData),
									{next_state, roll_dian_s, {WPId, RoleId, RollDian, Value, Length, Status}, 5 * 1000};
								false ->
									{ok, BinData} = pt_401:write(40133, [[[0, 0, 0, [], 0]], Length]),
									sand_to_rank(Status#god_animal_battle.fight_rank, BinData),
									{next_state, roll_dian_s, {WPId, 0, 0, Value, Length, Status}, 5 * 1000}
							end
					end
			end
	end.

%% 发奖(期间不接受ROLL点,5秒)
roll_dian_s(timeout, {WPId, WinnerId, RollDian, Value, Length, Status}) ->
	RollTimes =  Status#god_animal_battle.roll_times + 1,
	WPIdNext = case RollTimes > length(Value) of
		true ->
			0;
		_ ->
			{WPIdN, _} = lists:nth(RollTimes, Value),
			WPIdN
	end,
	case WinnerId =:= 0 of
		true ->
			case RollTimes > Length of
				true ->
					{next_state, roll_dian, Status#god_animal_battle{roll_times = RollTimes}, 0};
				false ->
					RankInfo = Status#god_animal_battle.fight_rank,
					GiftList = [[RollTimes, WPIdNext]],
					{ok, BinData} = pt_401:write(40131, [GiftList, Length]),
					sand_to_rank(RankInfo, BinData),
					{next_state, roll_dian, Status#god_animal_battle{roll_times = RollTimes}, 0}
			end;
		false ->
			CWWP = data_guild:get_ga_chuanwen_list(),
			case lists:member(WPId, CWWP) of
				true ->
					erlang:spawn(fun()->
							 case lib_player:get_player_info(WinnerId, sendTv_Message) of
								 [IdT, RealmT, NicknameT, SexT, CareerT, IimageT] ->
							 		lib_chat:send_TV({all},0, 2,[killShenshou, IdT, RealmT, NicknameT, SexT, CareerT, IimageT, WPId]);
								 _ ->
									 skip
							 end
				 	end);
				false ->
					skip
			end,
			%% 发物品
			[Title, Format] = data_guild_text:get_mail_text(ga_roll_win),
			Content = io_lib:format(Format, [RollDian]),
			mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, 
											   [[WinnerId], 
												Title,
												Content, 
												WPId, 
												2, 0, 0, 1, 0, 0, 0, 0]),
            case RollTimes > Length of
				true ->
					{next_state, roll_dian, Status#god_animal_battle{roll_times = RollTimes}, 0};
				false ->
					RankInfo = Status#god_animal_battle.fight_rank,
					%% 发下一个物品出来的信息
					GiftList = [[RollTimes, WPIdNext]],
					{ok, BinData} = pt_401:write(40131, [GiftList, Length]),
					sand_to_rank(RankInfo, BinData),
					{next_state, roll_dian, Status#god_animal_battle{roll_times = RollTimes}, 0}
			end
	end.

%% 神兽死亡处理
handle_event({ga_killed, _AttId2, GuildId}, StateName, Status) ->
	%% 判断是否在正确的状态中
	case Status#god_animal_battle.guild_id =:= GuildId andalso StateName =:= waitting of
		true->
			io:format("Status"),
			%% 神兽被击杀,开始正常roll点
			start_roll(Status);
		false ->
			%% 错误的消息
			MId = Status#god_animal_battle.ga_id,
			GALevel = Status#god_animal_battle.ga_lv,
			lib_guild_scene:log_ga_battle(GuildId, GALevel, 3, []),
            lib_mon:clear_scene_mon_by_mids(?GUILD_SCENE, Status#god_animal_battle.guild_id, 1, [MId]),
			{ok, BinData} = pt_401:write(40126, [0, GALevel, 0]),
			mod_disperse:cast_to_unite(lib_unite_send, send_to_guild, [GuildId, BinData]),
			{stop, normal, Status}
	end;
%% 神兽战小怪死亡处理
handle_event({ga_xg_killed, MonId, MonTypeId, GuildId}, StateName, Status) ->
	%% 判断是否在正确的状态中
	NewStatus = case Status#god_animal_battle.guild_id =:= GuildId andalso StateName =:= waitting of
		true->
			XiaoGuaiDict1 = case MonTypeId of
				10606 -> %% 通报小兵
					case dict:find(?GA_TIME_XG_TBXB, Status#god_animal_battle.ga_xiaoguai) of
						{ok, {XGNum0, _}} ->
							dict:store(?GA_TIME_XG_TBXB, {XGNum0, 0}, Status#god_animal_battle.ga_xiaoguai);
						_ ->
							Status#god_animal_battle.ga_xiaoguai
					end;
				10605 -> %% 银角大王
					case dict:find(?GA_TIME_XG_YJDW, Status#god_animal_battle.ga_xiaoguai) of
						{ok, _} ->
							dict:store(?GA_TIME_XG_YJDW, 0, Status#god_animal_battle.ga_xiaoguai);
						_ ->
							Status#god_animal_battle.ga_xiaoguai
					end;
				_ -> %% 精英小怪
					case dict:find(?GA_TIME_XG_JYXB, Status#god_animal_battle.ga_xiaoguai) of
						{ok, JYIdList0} ->
							dict:store(?GA_TIME_XG_JYXB, lists:delete(MonId, JYIdList0), Status#god_animal_battle.ga_xiaoguai);
						_ ->
							Status#god_animal_battle.ga_xiaoguai
					end
			end,
			Status#god_animal_battle{ga_xiaoguai = XiaoGuaiDict1};
		false ->
			Status
	end,
	{next_state, StateName, NewStatus, 0};
handle_event(test_time, StateName, Status) ->
	NowTime  = util:unixtime(),
	case StateName == waiting_call of
		true ->
			NewStatus = Status#god_animal_battle{start_god_animal_time = NowTime					
							   , stop_god_animal_time = ?GA_TIME_LAST + NowTime},
			{next_state, StateName, NewStatus, 0};
		false ->
			{next_state, StateName, Status, 0}
	end;
handle_event(_Event, StateName, Status) ->
    {next_state, StateName, Status}.


handle_sync_event({roll, PlayerId, PlayerName, PackId}, _From, StateName, Status) ->
	case StateName =:= roll_dian of
		true ->
			Is_Winner = case get(ylist) of
				undefined ->
					pass;
				Value ->
					case lists:member(PlayerId, Value) of
						true ->
							forbid;
						false ->
							pass
					end
			end,
			case Is_Winner of
				pass ->
					case get({roll, PackId}) of
						undefined ->
							RollDict = dict:new(),
							Rand = util:rand(1, 100),
							NewRollDict = dict:store(PlayerId, [PlayerName, Rand], RollDict),
							put({roll, PackId}, NewRollDict),
							{reply, [1, Rand], StateName, Status, 0};
						RollDictOld ->
							case dict:find(PlayerId, RollDictOld) of
								{ok, [_, ValueDian]} ->
									{reply, [1, ValueDian], StateName, Status, 0};
								error ->
									Rand = util:rand(1, 100),
									NewRollDict = dict:store(PlayerId, [PlayerName, Rand], RollDictOld),
									put({roll, PackId}, NewRollDict),
									{reply, [1, Rand], StateName, Status, 0}
							end
					end;
				forbid ->
					{reply, [2, 0], StateName, Status, 0}
			end;
		false ->
			{reply, [0, 0], StateName, Status, 0}
	end;
handle_sync_event(_Event, _From, StateName, Status) ->
    {reply, ok, StateName, Status}.

%%中断服务
handle_info(stop, _StateName, Status) ->
    {stop, normal, Status};
handle_info(_Info, StateName, Status) ->
    {next_state, StateName, Status}.

terminate(_Reason, _StateName, _Status) ->
    ok.

code_change(_OldVsn, StateName, Status, _Extra) ->
    {ok, StateName, Status}.


%% --------------------------------------------------------------------------
%% 内部函数 
%% --------------------------------------------------------------------------

guild_godanimal_send_rank(Status) ->
	lib_guild_scene:guild_godanimal_send_rank([Status#god_animal_battle.guild_id, Status#god_animal_battle.ga_id]).


start_roll(Status) ->
	spawn(fun() ->
				  clear_all_guaiwu(Status)
		  end),
	NowTime  = util:unixtime(),
	BaseP = case Status#god_animal_battle.ga_difficulty of
				1 ->
					data_guild:get_ga_pack_by_level(Status#god_animal_battle.ga_lv);
				_ ->
					data_guild:get_ga_pack_by_level_2(Status#god_animal_battle.ga_lv)
			end,
	[WPId10, WPId20, WPId30, WPId40, WPId50, WPId60] = make_new_4([BaseP, BaseP, BaseP, BaseP, BaseP, BaseP], [], 0),
	[WPId1, WPId2, WPId3, WPId4, WPId5, WPId6] = check_zero(WPId10, WPId20, WPId30, WPId40, WPId50, WPId60),
	RollEndTime1 = NowTime + 30,
	RollEndTime2 = NowTime + 60,
	RollEndTime3 = NowTime + 90,
	RollEndTime4 = NowTime + 120,
	RollEndTime5 = NowTime + 150,
	RollEndTime6 = NowTime + 180,
	{ok, BinData} = case Status#god_animal_battle.ga_difficulty of
		1 ->
			put(new_prize, [{WPId1, RollEndTime1}
						   , {WPId2, RollEndTime2}
						   , {WPId3, RollEndTime3}
						   , {WPId4, RollEndTime4}
						   , {WPId5, RollEndTime5}
						   , {WPId6, RollEndTime6}]),
			GiftList = [[1, WPId1]],
			%% 发下一个物品出来的信息
			pt_401:write(40131, [GiftList, 6]);
		_ ->
			put(new_prize, [{WPId1, RollEndTime1}
						   , {WPId2, RollEndTime2}
						   , {WPId3, RollEndTime3}
						   , {WPId4, RollEndTime4}]),
			GiftList = [[1, WPId1]],
			%% 发下一个物品出来的信息
			pt_401:write(40131, [GiftList, 4])
	end,
	%% 发送伤害排名奖励
	sand_to_rank(Status#god_animal_battle.fight_rank, BinData),
	%% 进入roll点过程奖励
	{next_state, roll_dian, Status#god_animal_battle{roll_times = Status#god_animal_battle.roll_times + 1}, 0}.

time_over_handle(Status) ->
	spawn(fun() ->
				  clear_all_guaiwu(Status)
		  end),
	lib_guild_scene:time_over_ga([Status#god_animal_battle.guild_id
												, Status#god_animal_battle.ga_id
												, Status#god_animal_battle.ga_lv
												, Status#god_animal_battle.fight_rank
												, []]).

win_over_handle(Status) ->
	lib_guild_scene:ga_is_kill_ok([Status#god_animal_battle.guild_id
												, Status#god_animal_battle.ga_id
												, Status#god_animal_battle.ga_lv
												, Status#god_animal_battle.fight_rank
												, []]).


log_ga_start(Gid, GaLv, Time) ->
	SQL = io_lib:format(<<"insert into log_ga_start set gid=~p, galv=~p, time=~p">>, [Gid, GaLv, Time]),
	db:execute(SQL).

check_zero(WPId10, WPId20, WPId30, WPId40, WPId50, WPId60) ->
	WPId1 = case WPId10 of
				0 ->
					112214;
				_ ->
					WPId10
			end,
	WPId2 = case WPId20 of
				0 ->
					112214;
				_ ->
					WPId20
			end,
	WPId3 = case WPId30 of
				0 ->
					112214;
				_ ->
					WPId30
			end,
	WPId4 = case WPId40 of
				0 ->
					112214;
				_ ->
					WPId40
			end,
	WPId5 = case WPId50 of
				0 ->
					112214;
				_ ->
					WPId50
			end,
	WPId6 = case WPId60 of
				0 ->
					112214;
				_ ->
					WPId60
			end,
	[WPId1, WPId2, WPId3, WPId4, WPId5, WPId6].

make_new_4([], PrizeList, _IsWQ)->
	PrizeList;
make_new_4(Pack4, PrizeList, IsWQ)->
	[H|Pack4T] = Pack4,
	[SunPack, Limit] = lists:foldl(fun({GoodsTypeId, Type, GL}, AccListBack) ->
						case IsWQ =:= 1 andalso Type =:= 1 of
							true -> 
								AccListBack;
							false -> 
								case AccListBack =:= [] of
									true ->
										[[{GoodsTypeId, Type, GL}], GL];
									false ->
										[AccList, NowLimit] = AccListBack,
										NewLimit = NowLimit + GL,
										[[{GoodsTypeId, Type, NewLimit}|AccList], NewLimit]
								end
						end
				end, [], H),
	SJD = util:rand(1, Limit),
	[WPId, IsWQNew] = make_new_1(lists:reverse(SunPack), SJD),
	make_new_4(Pack4T, [WPId|PrizeList], IsWQNew).
	
make_new_1(SunPack, SJD) ->
	case SunPack =:= [] of
		true ->
			[0, 0];
		false ->
			[H|T] = SunPack,
			{A, B, C} = H,
			case SJD < C of
				true ->
					case B =:= 1 of
						true->
							[A, 1];
						false ->
							[A, 0]
					end;
				false ->
					make_new_1(T, SJD)
			end
	end.

get_roll_winers(PackId, WPId)-> 
	case get({roll, PackId}) of
		undefined ->
			[0, 0, 0, [[0, 0, 0, [], 0]]];
		DictB ->
			List1 = dict:to_list(DictB),
			[{SA1, [SB1, SC1]}|_T1] = lists:sort(fun({_, [_, A1]}, {_, [_, B1]})->
							   A1 >= B1
					   end, List1),
			case get(ylist) of
				undefined ->
					put(ylist, [SA1]);
				Value ->
					put(ylist, [SA1|Value])
			end,
			[1, SA1, SC1, [[1, WPId, SA1, SB1, SC1]]]
	end.

%% sand_to_rank
sand_to_rank([], _BinData)->
	ok;
sand_to_rank(RankInfo, BinData)->
	[[_RanKNum, RoleId, _Damage, _]|RankInfoN] = RankInfo,
	lib_server_send:send_to_uid(RoleId, BinData),
	sand_to_rank(RankInfoN, BinData).

%% 清除所有召唤物
clear_all_guaiwu(Status) ->
	GuildId = Status#god_animal_battle.guild_id,
	%% 清除各种相关怪物
    lib_mon:clear_scene_mon_by_mids(?GUILD_SCENE, GuildId, 1, [10604,10605,10606,40202,40203,40204,40205,40206,10607,10608,10609,10610]).
	
