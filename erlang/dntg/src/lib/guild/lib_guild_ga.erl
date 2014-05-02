%% --------------------------------------------------------
%% @Module:           |lib_guild_ga
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-05-00
%% @Description:      |帮派神兽额外功能
%% --------------------------------------------------------
-module(lib_guild_ga).

-include("common.hrl").
-include("record.hrl").
-include("server.hrl").
-include("goods.hrl").
-include("guild.hrl").
-include("sql_guild.hrl").
-include("unite.hrl").
-include("scene.hrl").
-include("sql_player.hrl").

-compile(export_all).

%% -----------------------------------------------------------------
%% 帮派神兽阶处理 
%% -----------------------------------------------------------------

%% 获取当前神兽阶段信息(包括神兽等级信息)
get_ga_stage(GuildId) ->
	case gen_server:call(mod_guild, {ga_stage_info, [GuildId]}) of
		[GaLv, GaStage, GaStageExp] ->
			[GaLv, GaStage, GaStageExp];
		_ ->
			[0, 0, 0]
	end.

%% 捐献给神兽升阶
ga_donate_stage(GuildId, RoleId, Num) ->
	GoodsTypeId = 411301,
	case GuildId =:= 0 of
		true ->
			0;
		false ->
			case lib_guild:del_goods_unite(RoleId, GoodsTypeId, Num) of
				1 ->
					case gen_server:call(mod_guild, {ga_donate_stage, [GuildId, RoleId, Num]}) of
						[_GALevel, RStage, _RStageExp, IsUp] ->
							case IsUp =:= 1 of
								true ->
									syn_ga_stage(GuildId, RStage);
								false ->
									skip
							end,
							1;
						_ ->
							0
					end;
				R when erlang:is_integer(R)->
					R;
				_ ->
					0
			end
	end.

%% 神兽升阶(同步数据, 通知所有成员)
syn_ga_stage(GuildId, Stage) ->
	lib_guild:send_guild(GuildId, guild_ga_stage, Stage).



%% -----------------------------------------------------------------
%% 帮派神兽技能处理(游戏线)
%% -----------------------------------------------------------------

%% 获取自己的神兽技能信息加成
get_ga_skill_add(PlayerStatus) ->
	GaSkill = PlayerStatus#player_status.guild_ga_skill,
	[
		 get_ga_skill_add_one(0, GaSkill#ga_skill.s_0)
		,get_ga_skill_add_one(1, GaSkill#ga_skill.s_1)
		,get_ga_skill_add_one(2, GaSkill#ga_skill.s_2)
		,get_ga_skill_add_one(3, GaSkill#ga_skill.s_3)
		,get_ga_skill_add_one(4, GaSkill#ga_skill.s_4)
		,get_ga_skill_add_one(5, GaSkill#ga_skill.s_5)
		,get_ga_skill_add_one(6, GaSkill#ga_skill.s_6)
		,get_ga_skill_add_one(7, GaSkill#ga_skill.s_7)
		,get_ga_skill_add_one(8, GaSkill#ga_skill.s_8)
		,get_ga_skill_add_one(9, GaSkill#ga_skill.s_9)
	 ].

%% 获取自己的神兽技能信息({技能, 等级}列表, 当前可修炼的{技能, 等级})
get_ga_skill(PlayerStatus) ->
	GaSkill = PlayerStatus#player_status.guild_ga_skill,
	[
	 	GaSkill#ga_skill.last_train,
		[
			 {0, GaSkill#ga_skill.s_0}
			 ,{1, GaSkill#ga_skill.s_1}
			 ,{2, GaSkill#ga_skill.s_2}
			 ,{3, GaSkill#ga_skill.s_3}
			 ,{4, GaSkill#ga_skill.s_4}
			 ,{5, GaSkill#ga_skill.s_5}
			 ,{6, GaSkill#ga_skill.s_6}
			 ,{7, GaSkill#ga_skill.s_7}
			 ,{8, GaSkill#ga_skill.s_8}
			 ,{9, GaSkill#ga_skill.s_9}
		]
	].

%% 获取指定神兽技能加成
%% 气血	50
%% 防御	5	
%% 命中	5	
%% 闪避	4	
%% 暴击	1	
%% 坚韧	3
%% 攻击	2	
%% 抗性	16	
%% 抗性	16	
%% 抗性	16
get_ga_skill_add_one(SkillType, SKillLevel) ->
	N = case SkillType of
		 0 ->
			 50;
		 1 ->
			 5;
		 2 ->
			 5;
		 3 ->
			 4;
		 4 ->
			 1;
		 5 ->
			 3;
		 6 ->
			 2;
		 7 ->
			 16;
		 8 ->
			 16;
		 9 ->
			 16
	 end,
	SKillLevel * N.

%% 提升技能
%% @return {Res, NewPs}
ga_skill_up(PlayerStatus) ->
	GuildInfo = PlayerStatus#player_status.guild,
	GaSkill = PlayerStatus#player_status.guild_ga_skill,
	_GaStage = case GuildInfo#status_guild.guild_ga_stage > 10 orelse GuildInfo#status_guild.guild_ga_stage < 1 of
				  true ->
					  1;
				  false ->
					  GuildInfo#status_guild.guild_ga_stage
			  end,
%% 	{_, _, DailyTimes, SkillLimit} = data_guild_ga_stage:get_stage_info(GaStage),
	SkillLimit = 99,
	DailyTimes = count_learn_times(GuildInfo#status_guild.guild_lv, GuildInfo#status_guild.guild_id),
	NowTimes = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 4040001),
	case NowTimes >= DailyTimes of
		true -> %% 线1
			case GaSkill#ga_skill.last_train of
				{LastSkillType, LastSKillLevel} ->
					{_, _, _, {NextSkillType, NextSKillLevel}} = data_guild_ga_stage:get_skill_info(LastSkillType, LastSKillLevel),
					case NextSKillLevel > SkillLimit orelse (NextSkillType =:= 0 andalso NextSKillLevel =:= 0)of
						true ->
							{3, PlayerStatus}; %% 超出上限
						false ->
							{_, UsedScore} =  data_guild_ga_stage:get_skill_cost(NextSKillLevel),
							case lib_player_server:use_factionwar_score(PlayerStatus,UsedScore) of
								{ok,{_PreRestScore ,_RestScore ,NewPlayerStatus1}} ->
									PlayerGoods = PlayerStatus#player_status.goods,
									case gen_server:call(PlayerGoods#status_goods.goods_pid, {'delete_more', 411801, 1}) of
										1 ->
											%% 不写日常了 mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 4040001),
											NewPlayerStatus2 = count_new_skill(NewPlayerStatus1, {NextSkillType, NextSKillLevel}),
											NewPlayerStatus3 = lib_player:count_player_attribute(NewPlayerStatus2),
											save_log_ga_skill_db(NewPlayerStatus3, _PreRestScore, UsedScore, NextSkillType, NextSKillLevel),
											lib_player:send_attribute_change_notify(NewPlayerStatus3, 0),
											{1, NewPlayerStatus3};
										_R ->
											%% 					io:format("_R ~p~n", [_R]),
											{4, NewPlayerStatus1}
									end;
								_ -> %% 帮战积分不够
									{2, PlayerStatus}
							end
					end;
				_ -> %% 错误的信息
					{3, PlayerStatus}
			end;
		false -> %% 线2
			case GaSkill#ga_skill.last_train of
				{LastSkillType, LastSKillLevel} ->
					{_, _, _, {NextSkillType, NextSKillLevel}} = data_guild_ga_stage:get_skill_info(LastSkillType, LastSKillLevel),
					case NextSKillLevel > SkillLimit orelse (NextSkillType =:= 0 andalso NextSKillLevel =:= 0)of
						true ->
							{3, PlayerStatus}; %% 超出上限
						false ->
							{_, UsedScore} =  data_guild_ga_stage:get_skill_cost(NextSKillLevel),
							case lib_player_server:use_factionwar_score(PlayerStatus,UsedScore) of
								{ok,{_PreRestScore ,_RestScore ,NewPlayerStatus1}} ->
									mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 4040001),
									NewPlayerStatus2 = count_new_skill(NewPlayerStatus1, {NextSkillType, NextSKillLevel}),
									NewPlayerStatus3 = lib_player:count_player_attribute(NewPlayerStatus2),
									save_log_ga_skill_db(NewPlayerStatus3, _PreRestScore, UsedScore, NextSkillType, NextSKillLevel),
									lib_player:send_attribute_change_notify(NewPlayerStatus3, 0),
									{1, NewPlayerStatus3};
								_ -> %% 帮战积分不够
									{2, PlayerStatus}
							end
					end;
				_ -> %% 错误的信息
					{3, PlayerStatus}
			end
	end.
	

%% 计算新技能等级
count_new_skill(PS, {NextSkillType, NextSKillLevel}) ->
	GaSkill = PS#player_status.guild_ga_skill,
	GaSkillNew = case NextSkillType of
					 0 ->
						 GaSkill#ga_skill{s_0 = NextSKillLevel, last_train = {NextSkillType, NextSKillLevel}};
					 1 ->
						 GaSkill#ga_skill{s_1 = NextSKillLevel, last_train = {NextSkillType, NextSKillLevel}};
					 2 ->
						 GaSkill#ga_skill{s_2 = NextSKillLevel, last_train = {NextSkillType, NextSKillLevel}};
					 3 ->
						 GaSkill#ga_skill{s_3 = NextSKillLevel, last_train = {NextSkillType, NextSKillLevel}};
					 4 ->
						 GaSkill#ga_skill{s_4 = NextSKillLevel, last_train = {NextSkillType, NextSKillLevel}};
					 5 ->
						 GaSkill#ga_skill{s_5 = NextSKillLevel, last_train = {NextSkillType, NextSKillLevel}};
					 6 ->
						 GaSkill#ga_skill{s_6 = NextSKillLevel, last_train = {NextSkillType, NextSKillLevel}};
					 7 ->
						 GaSkill#ga_skill{s_7 = NextSKillLevel, last_train = {NextSkillType, NextSKillLevel}};
					 8 ->
						 GaSkill#ga_skill{s_8 = NextSKillLevel, last_train = {NextSkillType, NextSKillLevel}};
					 9 ->
						 GaSkill#ga_skill{s_9 = NextSKillLevel, last_train = {NextSkillType, NextSKillLevel}}
				 end,
	save_ga_skill_db(PS#player_status.id, GaSkillNew),
	PS#player_status{guild_ga_skill = GaSkillNew}.
				
%% 玩家登录时候调用
%% @return #ga_skill{}
init_ga_skill(RoleId) ->
	Sql = io_lib:format(?SQL_GUILD_GA_SKILL_SELECT_ONE, [RoleId]),
    case db:get_row(Sql) of
        [] -> %% 没有数据 插入一条
			NowTime = util:unixtime(),
			Sql2 = io_lib:format(?SQL_GUILD_GA_SKILL_REPLACE, [RoleId, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NowTime]),
			db:execute(Sql2),
			make_record(RoleId, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        [Uid, S_0, S_1, S_2, S_3, S_4, S_5, S_6, S_7, S_8, S_9, Ptype, Plevel, _Cdtime] ->
			make_record(Uid, S_0, S_1, S_2, S_3, S_4, S_5, S_6, S_7, S_8, S_9, Ptype, Plevel)
    end.

%% 写入数据库
save_ga_skill_db(RoleId, GaSkill) ->
	NowTime = util:unixtime(),
	{A, B} = GaSkill#ga_skill.last_train,
	Sql2 = io_lib:format(?SQL_GUILD_GA_SKILL_REPLACE, [RoleId
													  , GaSkill#ga_skill.s_0
													  , GaSkill#ga_skill.s_1
													  , GaSkill#ga_skill.s_2
													  , GaSkill#ga_skill.s_3
													  , GaSkill#ga_skill.s_4
													  , GaSkill#ga_skill.s_5
													  , GaSkill#ga_skill.s_6
													  , GaSkill#ga_skill.s_7
													  , GaSkill#ga_skill.s_8
													  , GaSkill#ga_skill.s_9
													  , A
													  , B
													  , NowTime]),
	db:execute(Sql2).

%% 帮派技能学习日志
save_log_ga_skill_db(PS, PreSocre, UseScore, SkillType, SkillLevel) ->
	PlayerId = PS#player_status.id,
	GuildInfo = PS#player_status.guild,
	GuildId = GuildInfo#status_guild.guild_id, 
	NowTime = util:unixtime(),
	db:execute(io_lib:format(?SQL_LOG_GUILD_GA_SKILL_INSERT, [PlayerId, GuildId, NowTime, PreSocre, UseScore, SkillType, SkillLevel])).

make_record(_Uid, S_0, S_1, S_2, S_3, S_4, S_5, S_6, S_7, S_8, S_9, Ptype, Plevel) ->
	#ga_skill{
			  s_0 = S_0								%% 气血
			  , s_1 = S_1							%% 防御
			  , s_2 = S_2							%% 命中
			  , s_3 = S_3							%% 闪避
			  , s_4 = S_4							%% 暴击
			  , s_5 = S_5							%% 韧性
			  , s_6 = S_6							%% 攻击
			  , s_7 = S_7							%% 水抗
			  , s_8 = S_8							%% 雷抗
			  , s_9 = S_9							%% 冥抗
			  , last_train = {Ptype, Plevel}		%% 上次修炼的技能和等级{技能ID, 等级}
			 }.

%% 后台用清除神兽相关日常
clear_ga_call(GuildId) ->
	DailyGuildId = 4000000 + GuildId,
	mod_daily_dict:set_count(DailyGuildId, 4007808, 0),
	mod_daily_dict:set_count(DailyGuildId, 4007809, 0),
	ok.

%% 计算学习次数
count_learn_times(GuildLv, GuildId) ->
%% 	io:format("GuildLv ~p ~p ~n", [GuildId, GuildLv]),
	if
		GuildLv >= 15 -> 7;
		GuildLv >= 13 -> 6;
		GuildLv >= 10 -> 5;
		GuildLv >= 7 -> 4;
		GuildLv >= 4 -> 3;
		true  -> 
			case GuildId =:= 0 of
				true -> 0;
				false ->
					2
			end
	end.

%% ----------------------------------------------------------------- E N D ---------------------------------------------------------------