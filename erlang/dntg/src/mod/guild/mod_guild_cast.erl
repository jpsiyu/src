%%%------------------------------------
%%% @Module  : mod_guild_call
%%% @Author  : zhenghehe
%%% @Created : 2012.02.02
%%% @Description: 帮派cast处理
%%%------------------------------------
-module(mod_guild_cast).
-include("guild.hrl").
-include("fortune.hrl").
-include("sql_guild.hrl").   
-export([handle_cast/2]).
-compile(export_all).

%% -----------------------------------------------------------------
%% 处理帮派每日事件
%% -----------------------------------------------------------------
handle_cast({daily_work, GuildId}, State) ->
    NewState = daily_work(GuildId, State),
    {noreply, NewState};

%% -----------------------------------------------------------------
%% 处理过期的解散申请
%% -----------------------------------------------------------------
handle_cast('handle_expired_disband', State) ->
    %% lib_guild:handle_expired_disband(),
    {noreply, State};

%% -----------------------------------------------------------------
%% 处理掉级导致的自动解散
%% -----------------------------------------------------------------
handle_cast('handle_auto_disband', State) ->
    %% lib_guild:handle_auto_disband(),
    {noreply, State};

%% -----------------------------------------------------------------
%% 发送帮派邮件
%% -----------------------------------------------------------------
handle_cast({'send_mail', _SubjectType, _Param}, State) ->
    %% lib_guild:send_mail(SubjectType, Param),
    {noreply, State};

%% -----------------------------------------------------------------
%% 记录帮主登陆(每日会清零)
%% -----------------------------------------------------------------
handle_cast({chief_login, GuildId, RoleId}, State) ->
	Key = "chieflogin" ++ integer_to_list(GuildId),
	put(Key, [RoleId, 1]),
    {noreply, State};

%% -----------------------------------------------------------------
%% 修正帮主数据
%% -----------------------------------------------------------------
handle_cast({fix_chief, GuildId, RoleId, RoleName}, State) ->
	StateNew = case dict:find(GuildId, State) of
		{ok, Value} ->
			Data = [RoleId, RoleName, GuildId],
		    SQL  = io_lib:format(?SQL_GUILD_UPDATE_CHANGE_CHIEF, Data),
		    db:execute(SQL),
			Member00 = mod_guild_call:get_guild_member([RoleId, 1, 0]),
			Member20 = mod_guild_call:get_guild_member([Value#ets_guild.chief_id, 1, 0]),
			case Value#ets_guild.chief_id =:= 0 of
				true ->
					skip;
				false ->
					case Member20 of
						Member2 when is_record(Member2, ets_guild_member) ->
							Member3 = Member2#ets_guild_member{position = 5},
							mod_guild_call:update_guild_member([Member3]);
						_ ->
							skip
					end
			end,
			case Member00 of
				Member0 when is_record(Member0, ets_guild_member) ->
					Member1 = Member0#ets_guild_member{position = 1},
					mod_guild_call:update_guild_member([Member1]);
				_ ->
					skip
			end,
			ValueNext = Value#ets_guild{chief_id = RoleId, chief_name = RoleName},
			dict:store(GuildId, ValueNext, State);
		_ ->
			State
	end,

    {noreply, StateNew};

%% 修正运势任务数据
handle_cast({fix_fortune_log, [fix]}, Status) ->
	SQL1  = io_lib:format("DELETE FROM fortune WHERE status=3 and id NOT IN (SELECT role_id FROM task_log_clear WHERE TYPE= 13)", []),
	db:execute(SQL1),
	New_Key = "role_fortune",
	erlang:erase(New_Key),
	NewDict = dict:new(),
	put(New_Key, NewDict),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 发送帮派战奖励
%% -----------------------------------------------------------------
handle_cast({factionwer_prize, [GuildId, _, ContributionAdd, MemberList, MaterialAdd]}, Status) ->
	{_IsOk, NewStatus} = case dict:find(GuildId, Status) of
		{ok, Value} ->
			% 计算增加的帮派建设
		    ContributionTotal = Value#ets_guild.contribution + ContributionAdd,
		    % 处理帮派升级
		    [NewLevel, NewMemberCapacity, NewContribution, NewContributionThreshold, NewContributionDaily] = lib_guild:calc_new_level(Value#ets_guild.level, ContributionTotal, Value#ets_guild.member_capacity, Value#ets_guild.level),
			%% 更新帮派表
			{ok, StatusSaved} = if  %% (1) 帮派升级
									NewLevel > Value#ets_guild.level ->
										lib_guild:get_guild_award(Value#ets_guild.level, NewLevel, GuildId),
										Data1 = [NewLevel, Value#ets_guild.funds, NewContribution, Value#ets_guild.id],
										SQL1  = io_lib:format(?SQL_GUILD_UPDATE_GRADE_BZ, Data1),
										db:execute(SQL1),
										NewGuild = Value#ets_guild{level                  = NewLevel,
																   member_capacity        = NewMemberCapacity,
																   contribution           = NewContribution,
																   contribution_threshold = NewContributionThreshold,
																   contribution_daily     = NewContributionDaily},
										%% 通知成员
										lib_guild:send_guild(Value#ets_guild.id, 'guild_upgrade', [Value#ets_guild.id, Value#ets_guild.name, Value#ets_guild.level, NewLevel]),
										mod_guild_call:update_guild([NewGuild, Status]);
									true -> %% (2) 帮派没有升级
										NewGuild = Value#ets_guild{contribution = Value#ets_guild.contribution + ContributionAdd},
										NewContribution = NewGuild#ets_guild.contribution,
										Data = [Value#ets_guild.funds, NewContribution, GuildId],
										SQL  = io_lib:format(?SQL_GUILD_UPDATE_FUNDS_CONTRIBUTION, Data),
										db:execute(SQL),
										mod_guild_call:update_guild([NewGuild, Status])
								end,
			%% 发送成员奖励
			mod_guild_call:update_guild_member([factionwer_prize, GuildId, MemberList, MaterialAdd]),
			{true, StatusSaved};
		error ->
			{false, Status}
	end,
    {noreply, NewStatus};

%% -----------------------------------------------------------------
%% 更新帮派成员帮派战信息
%% -----------------------------------------------------------------
handle_cast({factionwar_info, [Id, WarScore, KillNum, NowTime]}, Status) -> 
	mod_guild_call:update_guild_member([factionwar_info, Id, WarScore, KillNum, NowTime]),
	{noreply, Status};



%% -----------------------------------------------------------------
%% 发放帮派目标奖励
%% -----------------------------------------------------------------
handle_cast({send_achieved_prize, [PlayerId, GuildId, G_Funds ,G_Contribution ,G_menber_Donate ,G_menber_Material]}, State) ->
    lib_guild:send_achieved_prize([PlayerId, GuildId, G_Funds ,G_Contribution ,G_menber_Donate ,G_menber_Material]),
    {noreply, State};

%% -----------------------------------------------------------------
%% 改名
%% -----------------------------------------------------------------
handle_cast({gai_ming, GuildId, NewName, NewNameUp}, State) ->
	NDState = dict:update(GuildId, 
				fun(GuildInfoOld) -> 
						GuildInfoOld#ets_guild{name = NewName, name_upper = NewNameUp}
				end, State),
	GuildMemberKeyNew = ?GUILD_MEMBER_INFO ++ integer_to_list(GuildId),
	case get(GuildMemberKeyNew) of
		undefined ->
			[];
		Value2 ->
			D0 = dict:new(),
			NewDictOne = ccname_many_member(dict:to_list(Value2), D0, NewName),
			put(GuildMemberKeyNew, NewDictOne)
	end,
	lib_factionwar:update_factionwar_name(GuildId, NewName),
    {noreply, NDState};


%% -----------------------------------------------------------------
%% 帮派神炉写入奖励(绑定铜币)
%% -----------------------------------------------------------------
handle_cast({put_furnace_back, RoleId, GuildId, CoinCost}, State) ->
	case dict:find(GuildId, State) of
		{ok, Guild} when is_record(Guild, ets_guild) ->
			case mod_guild_call:get_guild_member([RoleId, 1, State]) of
				GuildMember when is_record(GuildMember, ets_guild_member) ->
					case Guild#ets_guild.id =:= GuildMember#ets_guild_member.guild_id andalso Guild#ets_guild.furnace_level > 0 of
						true ->
						    [Num1, _, _] = data_guild:get_furnace_info(Guild#ets_guild.furnace_level),
							NumLimit = data_guild:get_f_limit(Guild#ets_guild.furnace_level),
							FAdd = erlang:round(CoinCost * Num1 / 100),
							%% 玩家日常进程
							DailyPid = lib_player:get_player_info(GuildMember#ets_guild_member.id, dailypid),
							OldDailyFB = mod_daily:get_count(DailyPid, GuildMember#ets_guild_member.id, 4008000),
							case OldDailyFB + FAdd >= NumLimit of
										true ->
											UpToNumLimit = NumLimit - OldDailyFB,
											NewFB = GuildMember#ets_guild_member.furnace_back+UpToNumLimit,
											NewDailyFB = NumLimit,
											mod_daily:set_count(DailyPid, GuildMember#ets_guild_member.id, 4008000, NewDailyFB);
										false ->
											NewFB = GuildMember#ets_guild_member.furnace_back + FAdd,
											NewDailyFB = OldDailyFB + FAdd,
											mod_daily:set_count(DailyPid, GuildMember#ets_guild_member.id, 4008000, NewDailyFB)
									end,
							NewGuildMember = GuildMember#ets_guild_member{furnace_back = NewFB},
							mod_guild_call:update_guild_member([NewGuildMember]);
						false ->
							ok
					end;
				_->
					ok
			end;
		_ ->
			ok
	end,
    {noreply, State};

%% -----------------------------------------------------------------
%% 处理运势任务更新 
%% -----------------------------------------------------------------
handle_cast({fortune_daily_check, [RoleId, Type, Count]}, State) ->
	case RoleId =:= 0 orelse Type =:= 0 orelse Count =:= 0 of
		true ->
			ok;
		false ->
			case mod_guild_call:get_fortune(RoleId) of
				Fortune when is_record(Fortune, rc_fortune) ->
					FortuneRoleId = Fortune#rc_fortune.role_id,
				    FortuneTaskId = Fortune#rc_fortune.task_id,
					Status = Fortune#rc_fortune.status,
					case Status >= 2 of
						true ->
							ok;
						false ->
							case FortuneRoleId =:= RoleId of
								false ->
									ok;
								true ->
									case FortuneTaskId > 0 of
										true ->
											{DailyId, Num} = lib_fortune:get_daily(FortuneTaskId),
											case DailyId =:= Type of
												false ->
													ok;
												true ->
												    case Count >= Num of
														true ->
															{ok, BinData} = pt_370:write(37021, [Num, Num]),
													    	lib_unite_send:send_to_one(RoleId, BinData);
														_ ->
															{ok, BinData} = pt_370:write(37021, [Count, Num]),
												    		lib_unite_send:send_to_one(RoleId, BinData)
													end
											end;
										false ->
											ok
									end
							end
					end;
				_ ->
					ok
			end
	end,
    {noreply, State};

handle_cast({update_guild_member, [offline, PlayerId]}, Status) ->
   	mod_guild_call:update_guild_member([offline, PlayerId, Status]),
    {noreply, Status};

handle_cast({clear_fortune_log, [clear]}, Status) ->
   	clear_fortune_log(),
    {noreply, Status};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_guild:handle_cast not match: ~p", [Event]),
    {noreply, Status}.

clear_fortune_log() -> 
	New_Key2 = "role_fortune",
	New_Key = "fortune_log", 
	erlang:erase(New_Key2),
	erlang:erase(New_Key),
	SQL  = io_lib:format(?SQL_GUILD_FORTUNE_DELETE_ALL, []),
	db:execute(SQL),
	NewDict = dict:new(),
	put(New_Key, NewDict),
	put(New_Key2, NewDict).

%% 帮派每日处理事件 
daily_work(GuildId, State) ->
	case dict:find(GuildId, State) of
		error ->
			io:format("GuildId error~n", []),
			State;
		{ok, OnGuild} -> 
			NewState = base_calc(OnGuild, State),
			NewState
	end.

%% 单个帮派处理开始
%% 判断是否掉级,是否解散
base_calc(Guild, State)->
	%% 帮派神炉邮件发送日返利
	%send_furnace_back(Guild#ets_guild.id),
	[_, _ContributionThreshold, ContributionDaily] = data_guild:get_level_info(Guild#ets_guild.level),
	[IsDestroyed, LastDays] = case Guild#ets_guild.level > 1 of
		true -> %%　置零
			[0, 0];
		false -> %% 判断一级持续时间
			case Guild#ets_guild.leve_1_last >= 3 of
				true -> %% 解散掉帮派
					[1, 0];
				false ->
					[Title1, Format1] = data_guild_text:get_mail_text(guild_level_1),
					Content1 = io_lib:format(Format1, [1, 3 - (Guild#ets_guild.leve_1_last + 1), 1]),
					send_info_mail(Guild#ets_guild.id, [Title1, Content1]),
					[0, Guild#ets_guild.leve_1_last + 1]
			end
	end,
	case IsDestroyed =:= 0 of
		true ->
			[_IsLevelDown, NewContributionThreshold, NewContributionDaily, NewContribution, GuildLevel] = case Guild#ets_guild.contribution >= ContributionDaily of
				true -> %% 不用降级
					[0, Guild#ets_guild.contribution_threshold, Guild#ets_guild.contribution_daily, Guild#ets_guild.contribution - ContributionDaily, Guild#ets_guild.level];
				false -> %% 降级
					case Guild#ets_guild.level =:= 1 of
						true ->
							[1, Guild#ets_guild.contribution_threshold, Guild#ets_guild.contribution_daily, Guild#ets_guild.contribution, 1];
						false ->
							[Title, Format] = data_guild_text:get_mail_text(guild_degrade),
							Content = io_lib:format(Format, [Guild#ets_guild.name, Guild#ets_guild.level, Guild#ets_guild.level - 1]),
							send_info_mail(Guild#ets_guild.id, [Title, Content]),
							NewGuildLevel = Guild#ets_guild.level - 1,
							[_, ContributionThresholdNew, NDL] = data_guild:get_level_info(NewGuildLevel),
							[1, ContributionThresholdNew, NDL, ContributionThresholdNew + Guild#ets_guild.contribution - ContributionDaily, NewGuildLevel]
					end
			end,
			GuildChiefId = Guild#ets_guild.chief_id,
			[_IsClear, IsChangeChief, NewLeveDay] = case lib_player:get_player_info(GuildChiefId, pid) of
				Pid when is_pid(Pid) -> 
					[1, 0, 0];
				_ ->
					Key = "chieflogin" ++ integer_to_list(Guild#ets_guild.id),
					case erlang:erase(Key) of
						undefined ->
							case Guild#ets_guild.base_left >= 7 of
								true -> 
									[0, 1, 0];
								false -> 
									[0, 0, Guild#ets_guild.base_left + 1]
							end;
						_Val -> 
							[1, 0, 0]
					end
			end,
			[Guild2B, IsCOk]= zdth(Guild, IsChangeChief),
			Nlxsj = case IsCOk of
						1 ->
							0;
						_ ->
							NewLeveDay
					end,
			[BaseMemberLimitNew, _, _] = data_guild:get_level_info(GuildLevel),
			MemberLimit = BaseMemberLimitNew + Guild2B#ets_guild.house_level * 5,
			%% 建设 上限 每日 等级 1级时间 离线时间 成员上限 帮派ID
            SQLData = [NewContribution, NewContributionThreshold, NewContributionDaily, GuildLevel, LastDays, Nlxsj, MemberLimit, Guild2B#ets_guild.id],
            SQL = io_lib:format(?SQL_GUILD_DAILY_1, SQLData),
            db:execute(SQL),
			NewGuild = Guild2B#ets_guild{contribution = NewContribution, contribution_threshold=NewContributionThreshold, contribution_daily=NewContributionDaily, level = GuildLevel, leve_1_last = LastDays, base_left = Nlxsj, member_capacity = MemberLimit},
			dict:store(NewGuild#ets_guild.id, NewGuild, State);
		false ->
			destroy_guild(Guild),
			State
	end.

%%　解散符合条件的帮派
destroy_guild(Guild)->
	erlang:spawn(fun()->
						 SleepTime = util:rand(1000, 1000 * 20),
						 timer:sleep(SleepTime),
						 lib_guild:confirm_disband_guild(Guild#ets_guild.id, Guild#ets_guild.name, 1),
		                 lib_guild:send_guild(Guild#ets_guild.id, 'guild_disband', [Guild#ets_guild.id, Guild#ets_guild.name])
				 end).

%% 判断是否需要修正副帮主,处理转让帮主
zdth(Guild, IsChangeChief) ->
	Condition = [Guild#ets_guild.id, 2],
	Info_LS = mod_guild_call:get_guild_member([Condition, 2, 0]),
	DeputyChiefNum  = length(Info_LS),
	GuildOne = case DeputyChiefNum > 2 of
		true -> %% 修正副帮主过多
			[H1|T1] = Info_LS,
			[H2|T2] = T1,
			case ann_be_zl(T2) of
				ok -> 
					erlang:spawn(fun()->
										 SleepTime = util:rand(333, 3333),
										 timer:sleep(SleepTime),
										 ann_be_zl_syn(T2)
								 end);
				_ ->
					skip
			end,
			Guild#ets_guild{deputy_chief1_id = H1#ets_guild_member.id
						   , deputy_chief1_name = H1#ets_guild_member.name
						   , deputy_chief2_id = H2#ets_guild_member.id
						   , deputy_chief2_name = H2#ets_guild_member.name
						   , deputy_chief_num = 2};
		false -> %% 修正数量不正确
			NewNumDC = case deputy_chief1_id =:= 0 andalso deputy_chief2_id =:= 0 of
						   true -> 0;
						   false ->
							   case deputy_chief1_id =:= 0 andalso deputy_chief2_id =/= 0 of
								   true -> 1;
								   false ->
									   case deputy_chief1_id =/= 0 andalso deputy_chief2_id =:= 0 of
										   true -> 1;
										   false ->
											   case deputy_chief1_id =/= 0 andalso deputy_chief2_id =/= 0 of
												   true -> 2;
												   false ->
													   Guild#ets_guild.deputy_chief_num
											   end
									   end
							   end
					   end,
			Guild#ets_guild{deputy_chief_num = NewNumDC}
	end,
	[GuildTwo, IsCOk] = case IsChangeChief of
		1 ->
			[Res, PlayerId1, PlayerId2, PlayerName2, GuildLsx] = 
			if
				DeputyChiefNum =:= 0 ->
					Members0 = mod_guild_call:get_guild_member([GuildOne#ets_guild.id, 0, 0]),
					Members = lists:sort(fun(Member01, Member02) ->
												 Member01#ets_guild_member.donate >= Member02#ets_guild_member.donate
										 end, Members0),
					Mids = [Member#ets_guild_member.id||Member <- Members],
					Mids2 = lists:delete(GuildOne#ets_guild.chief_id, Mids),
					case Mids2 =:= [] of
						true ->
							[noneed, 0, 0, 0, GuildOne];
						false ->
							OneId = lists:nth(1, Mids2),
							[MemberC] = [Member||Member <- Members, Member#ets_guild_member.id =:= OneId],
							[ok, GuildOne#ets_guild.chief_id, MemberC#ets_guild_member.id, MemberC#ets_guild_member.name, GuildOne]
					end;
				true ->
					case GuildOne#ets_guild.deputy_chief1_id =:= 0 of
						true ->
							GuildLs = GuildOne#ets_guild{deputy_chief2_id = 0, deputy_chief2_name = <<>>},
							[ok, GuildOne#ets_guild.chief_id, GuildOne#ets_guild.deputy_chief2_id, GuildOne#ets_guild.deputy_chief2_name, GuildLs];
						false ->
							Id2 = GuildOne#ets_guild.deputy_chief2_id, Name2 = GuildOne#ets_guild.deputy_chief2_name,
							GuildLs = GuildOne#ets_guild{deputy_chief1_id = Id2, deputy_chief1_name = Name2, deputy_chief2_id = 0, deputy_chief2_name = <<>>},
							[ok, GuildOne#ets_guild.chief_id, GuildOne#ets_guild.deputy_chief1_id, GuildOne#ets_guild.deputy_chief1_name, GuildLs]
					end
			end,
			case Res of
				ok ->
					case db:transaction(fun() -> lib_guild:demise_chief_db(PlayerId1, PlayerId2, PlayerName2, GuildLsx#ets_guild.id) end) of
						ok -> 
%% 							io:format("Members 3 ~p ~p ~n ", [PlayerId2, GuildLsx#ets_guild.id]),
							BeCM1 = mod_guild_call:get_guild_member([PlayerId2, 1, 0]),%% 新帮主
							BeDM1 = mod_guild_call:get_guild_member([PlayerId1, 1, 0]),%% 旧帮主
							BeC = BeCM1#ets_guild_member{position = 1},
							BeD = BeDM1#ets_guild_member{position = 5},
							%% 同步两个玩家的信息
							mod_guild_call:update_guild_member([start, BeC]),
							mod_guild_call:update_guild_member([start, BeD]),
							spawn(fun()->
										lib_guild:guild_other_syn([BeC#ets_guild_member.id , BeC#ets_guild_member.guild_id, BeC#ets_guild_member.guild_name, 1]),
										lib_guild:guild_other_syn([BeD#ets_guild_member.id , BeD#ets_guild_member.guild_id, BeD#ets_guild_member.guild_name, 5])
								  end),
							[GuildLsx#ets_guild{chief_id = PlayerId2, chief_name = PlayerName2}, 1];
						_R ->
							[GuildOne, 0]
					end;
				_ ->
					[GuildOne, 0]
			end;
		_ ->
			[GuildOne, 0]
	end,
	[GuildTwo, IsCOk].

%% 处理副帮主信息
ann_be_zl([])->
	ok;
ann_be_zl(T)->
	[H1|T1] = T,
	H2 = H1#ets_guild_member{position = 3},
	mod_guild_call:update_guild_member([start, H2]),
	ann_be_zl(T1).

%% 处理副帮主信息
ann_be_zl_syn([])->
	ok;
ann_be_zl_syn(T) ->
	[H1|T1] = T,
	lib_guild:guild_other_syn([H1#ets_guild_member.id , H1#ets_guild_member.guild_id, H1#ets_guild_member.guild_name, 3]),
	Sql  = io_lib:format( "update guild_member set position=~p where id= ~p", [3, H1#ets_guild_member.id]),
	db:execute(Sql),
	timer:sleep(500),
	ann_be_zl_syn(T1).

%% 发送邮件
send_info_mail(GuildId, [Title, Content])->
	SQLx  = io_lib:format("select id from guild_member where guild_id = ~p", [GuildId]),
	GuildMemberList = db:get_all(SQLx), 
	GuildMemberListNew = [One||[One]<-GuildMemberList],
	gen_server:cast(mod_mail, {send_sys_mail, [GuildMemberListNew, Title, Content]}).

%% 帮派神炉返利
% send_furnace_back(GuildId) ->
% 	GuildMemberKey = ?GUILD_MEMBER_INFO ++ integer_to_list(GuildId),
% 	case get(GuildMemberKey) of 
% 		undefined ->
% 			skip;
% 		GuildMemberDict ->
% 			List = dict:to_list(GuildMemberDict),
% 			F = fun({_,Member}) ->
% 					Id = Member#ets_guild_member.id,
% 					[Title, Format1] = data_guild_text:get_mail_text(guild_furance),
% 					Coin = Member#ets_guild_member.furnace_back,
% 					ConTent = io_lib:format(Format1,[Coin]),
% 					NewMember = Member#ets_guild_member{furnace_back = 0, furnace_daily_back = 0},
% 							NewDict = dict:store(Id, NewMember, GuildMemberDict),
% 							put(GuildMemberKey, NewDict),
% 							lib_guild_base:update_guild_member_base0(NewMember),
% 					case Coin =:= 0 of 
% 						true ->
% 							skip;		
% 						%% 发邮件
% 						false ->
% 							gen_server:cast(mod_mail, {send_sys_mail, [Id, Title, ConTent, 0, 0, Coin, 0]})
% 					end
% 			end,
% 			lists:map(F, List)
% 	end.

%% 修正成员新数量,修正成员信息中帮派名字错误的问题
ccname_many_member([], DictOne, _NewGuildName)->
	DictOne;
ccname_many_member(ValueList, DictOne, NewGuildName)->
	[H|T] = ValueList,
	{MemberId, OldGuildMember} = H,
	NewGuildMember = OldGuildMember#ets_guild_member{guild_name = NewGuildName},
	NewDictOne = dict:store(MemberId, NewGuildMember, DictOne),
	ccname_many_member(T, NewDictOne, NewGuildName).

%%修正帮主职位
fix_guild_chief_ht(GuildId, RoleId, RoleName) ->
	mod_disperse:cast_to_unite(mod_guild_cast, fix_guild_chief, [GuildId, RoleId, RoleName]).

fix_guild_chief(GuildId, RoleId, RoleName) ->
	gen_server:cast(mod_guild, {fix_chief, GuildId, RoleId, util:make_sure_binary(RoleName)}).
