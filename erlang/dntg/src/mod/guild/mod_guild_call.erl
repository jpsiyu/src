%%%------------------------------------
%%% @Module  : mod_guild_call
%%% @Author  : zhenghehe
%%% @Created : 2012.02.02
%%% @Description: 帮派call处理  
%%%------------------------------------
-module(mod_guild_call).
-include("guild.hrl").
-include("fortune.hrl").
-include("sql_guild.hrl").    
-export([handle_call/3]).
-compile(export_all).

%% 更新或添加一条帮派信息_缓存
handle_call({update_guild, [Guild]}, _From, Status) ->
   	{Info, NewStatus} = update_guild([Guild, Status]),
    {reply, Info, NewStatus};

%% 删除一个帮派信息_缓存 
handle_call({delete_guild, [GuildId]}, _From, Status) ->
   	{Info, NewStatus} = delete_guild([GuildId, Status]),
    {reply, Info, NewStatus};

%% 条件查询帮派信息
handle_call({get_guild, [Condition, Type]}, _From, Status) ->
	case Condition =:= 0 andalso Type =/= 0 of
		true ->
			{reply, [], Status};
		false ->
			{Info, NewStatus} = get_guild([Condition, Type, Status]),
		    {reply, Info, NewStatus}
	end;

%% 查询帮派列表的扩展信息VIP, 同盟帮派
handle_call({get_40034_more, [GuildIdList]}, _From, Status) ->
	case GuildIdList =:= [] of
		true ->
			{reply, [], Status};
		false ->
			Info = guild_rela_handle:get_40034_more(GuildIdList, Status),
		    {reply, Info, Status}
	end;

%% 单独获取帮派等级 
handle_call({get_guild_level, GuildId}, _From, Status) ->
	case dict:find(GuildId, Status) of
		{ok, Guild} when is_record(Guild, ets_guild) ->
			{reply, Guild#ets_guild.level, Status};
		_ ->
			{reply, false, Status}
	end;

%% 更新或添加一条帮派成员信息_缓存
handle_call({update_guild_member, [GuildMember]}, _From, Status) ->
   	Info = update_guild_member([GuildMember]),
    {reply, Info, Status};

%% 帮派成员离线
handle_call({update_guild_member, [offline, PlayerId]}, _From, Status) ->
   	Info = update_guild_member([offline, PlayerId, Status]),
    {reply, Info, Status};

%% 条件删除一个帮派成员信息_缓存
handle_call({delete_guild_member, [Condition, Type]}, _From, Status) ->
	case Condition =:= 0 of
		true ->
			{reply, [], Status};
		false ->
			Info = delete_guild_member([Condition, Type, Status]),
    		{reply, Info, Status}
	end;
   	

%% 条件查询帮派成员信息 
handle_call({get_guild_member, [Condition, Type]}, _From, Status) ->
	case Condition =:= 0 of
		true ->
			{reply, [], Status};
		false ->
			Info = get_guild_member([Condition, Type, Status]),
		    {reply, Info, Status}
	end;

%% 单独获取财富
handle_call({get_guild_member_caifu, RoleId}, _From, Status) ->
	case RoleId =:= 0 of
		true ->
			{reply, 0, Status};
		false ->
			case get_guild_member([RoleId, 1, Status]) of
				Ginfo when is_record(Ginfo, ets_guild_member) ->
					{reply, Ginfo#ets_guild_member.material, Status};
				_ ->
					{reply, 0, Status}
			end
	end;

%% 更新或添加一条帮派申请
handle_call({update_guild_apply, [GuildApply]}, _From, Status) ->
   	Info = update_guild_apply([GuildApply]),
    {reply, Info, Status};

%% 删除一个帮派申请
handle_call({delete_guild_apply, [Condition, Type]}, _From, Status) ->
   	Info = delete_guild_apply([Condition, Type, Status]),
%% 	io:format(" :  ~p~n", [Info]),
    {reply, Info, Status};

%% 条件查询帮派申请
handle_call({get_guild_apply, [Condition, Type]}, _From, Status) ->
   	Info = get_guild_apply([Condition, Type, Status]),
%% 	io:format(" :  ~p~n", [Info]),
    {reply, Info, Status};

%% 更新或添加一条帮派邀请
handle_call({update_guild_invite, [GuildInvite]}, _From, Status) ->
   	Info = update_guild_invite([GuildInvite]),
    {reply, Info, Status};

%% 删除一个帮派邀请
handle_call({delete_guild_invite, [Condition, Type]}, _From, Status) ->
   	Info = delete_guild_invite([Condition, Type, Status]),
    {reply, Info, Status};

%% 条件查询帮派邀请
handle_call({get_guild_invite, [Condition, Type]}, _From, Status) ->
   	Info = get_guild_invite([Condition, Type, Status]),
    {reply, Info, Status};

%% 根据类型创建一条新的目标记录
handle_call({new_guild_achieve_info, [GuildId, AchieveType]}, _From, Status) ->
   	Info = new_guild_achieve_info([GuildId, AchieveType]),
    {reply, Info, Status};

%% 修改_添加_帮派_目标信息
handle_call({set_guild_achieve_info, AchieveOne}, _From, Status) ->
   	Info = set_guild_achieve_info(AchieveOne),
    {reply, Info, Status};

%% 获取帮派目标信息
handle_call({get_guild_achieve_info, GuildId}, _From, Status) ->
   	Info = get_guild_achieve_info(GuildId),
    {reply, Info, Status};

%% 修改_帮派目标列表_领取奖励
handle_call({get_guild_achieve_prize, [Guildid, AchievedType]}, _From, Status) ->
   	Info = get_guild_achieve_prize([Guildid, AchievedType]),
    {reply, Info, Status};

%% 修改_添加_帮派通讯录
handle_call({set_guild_contact_info, ContactOne}, _From, Status) ->
   	Info = set_guild_contact_info(ContactOne),
    {reply, Info, Status};

%% 获取帮派通讯录
handle_call({get_guild_contact_info, GuildId}, _From, Status) ->
   	ContactInfo = get_guild_contact_info(GuildId),
    {reply, ContactInfo, Status};

%% 获取帮派技能信息_个人
handle_call({get_guild_skill_player, [GuildId, GuildMember]}, _From, Status) ->
   	Info = get_guild_skill_player([GuildId, GuildMember, Status]),
    {reply, Info, Status};

%% 获取帮派技能信息_帮派
handle_call({get_guild_skill_guild, GuildId}, _From, Status) ->
   	Info = get_guild_skill_guild([GuildId, Status]),
    {reply, Info, Status};

%% 获取帮派技能改变
handle_call({init_guild_skill_guild, GuildId}, _From, Status) ->
	case GuildId =:= 0 of
		true ->
			{reply, [], Status};
		false ->
		   	Info = init_guild_skill_guild([GuildId, Status]),
		    {reply, Info, Status}
	end;

%% 更新或添加一条帮派神兽信息
handle_call({update_guild_godanimal, [GuildId, AnimalLeve, AnimalExp]}, _From, Status) ->
   	Info = update_guild_godanimal([GuildId, AnimalLeve, AnimalExp, Status]),
    {reply, Info, Status};

%% 更新或添加一条帮派神兽战斗胜利处理 
handle_call({guild_godanimal_win, [GuildId, AnimalLeve, AnimalExp]}, _From, Status) ->
   	Info = guild_godanimal_win([GuildId, AnimalLeve, AnimalExp, Status]),
    {reply, Info, Status};

%% 删除一个帮派的神兽信息
handle_call({delete_guild_godanimal, [Condition]}, _From, Status) ->
   	Info = delete_guild_godanimal([Condition, Status]),
    {reply, Info, Status};

%% 查询帮派神兽信息
handle_call({get_guild_godanimal, [Condition]}, _From, Status) ->
	case Condition =:= 0 of
		true ->
			{reply, [], Status};
		false ->
		   	Info = get_guild_godanimal([Condition, Status]),
		    {reply, Info, Status}
	end;

%% 更新或添加一条帮派神兽 成长信息
handle_call({save_guild_ga_event, [GuildId, Event]}, _From, Status) ->
   	Info = save_guild_ga_event([GuildId, Event]),
    {reply, Info, Status};

%% 查询帮派神兽信息 成长信息
handle_call({get_guild_ga_event, [GuildId]}, _From, Status) ->
	case GuildId =:= 0 of
		true ->
			{reply, [], Status};
		false ->
		   	Info = get_guild_ga_event(GuildId),
		    {reply, Info, Status}
	end;

%% 查询帮派神兽阶段信息
handle_call({ga_stage_info, [GuildId]}, _From, Status) ->
	case GuildId =:= 0 of
		true ->
			{reply, [], Status};
		false ->
			[_, GALevel, _] = get_guild_godanimal([GuildId, Status]),
		   	[Stage, StageExp] = ga_stage_info(GuildId),
		    {reply, [GALevel, Stage, StageExp], Status}
	end;

%% 帮派神兽升阶
handle_call({ga_donate_stage, [GuildId, RoleId, Num]}, _From, Status) ->
	case GuildId =:= 0 orelse RoleId =:= 0 of
		true ->
			{reply, [], Status};
		false ->
			[_, GALevel, _] = get_guild_godanimal([GuildId, Status]),
		   	[RStage, RStageExp, IsUp] = ga_donate_stage(GuildId, RoleId, Num, Status),
		    {reply, [GALevel, RStage, RStageExp, IsUp], Status}
	end;

%% 获取所有帮派信息
handle_call(get_all_guilds, _From, Status) ->
    {reply, Status, Status};

%% 插入运势信息
handle_call({update_fortune, [PlayerId, OneFortune]}, _From, Status) ->
	case PlayerId =:= 0 of
		true ->
			{reply, [], Status};
		false when is_record(OneFortune, rc_fortune)->
		   	Info = update_fortune(PlayerId, OneFortune),
    		{reply, Info, Status};
		_ ->
			{reply, [], Status}
	end;

%% 获取运势信息
handle_call({get_fortune, [PlayerId]}, _From, Status) ->
	case PlayerId =:= 0 of
		true ->
			{reply, [], Status};
		false ->
		   	Info = get_fortune(PlayerId),
    		{reply, Info, Status}
	end;
   	

%% 获取运势信息_批量 
handle_call({get_fortune_list, [PlayerIdList]}, _From, Status) ->
   	Info = get_fortune_list(PlayerIdList),
    {reply, Info, Status};

%% 插入运势信息
handle_call({update_fortune_log, [PlayerId, FortuneLog]}, _From, Status) ->
   	Info = update_fortune_log(PlayerId, FortuneLog),
    {reply, Info, Status};

%% 获取运势信息
handle_call({get_fortune_log, [PlayerId]}, _From, Status) ->
   	Info = get_fortune_log(PlayerId),
    {reply, Info, Status};

%% 获取运势信息_批量
handle_call({clear_fortune_log, [clear]}, _From, Status) ->
   	Info = clear_fortune_log(),
    {reply, Info, Status};

%% GET_APP_FLOWER_POINT
handle_call({app_point_get, [Point_Num, PlayerId]}, _From, Status) ->
    Info = app_point_get(Point_Num, PlayerId),
    {reply, Info, Status};

%% PUT_APP_FLOWER_POINT
handle_call({app_point_put, [Point_Num, PlayerId]}, _From, Status) ->
    Info = app_point_put(Point_Num, PlayerId),
    {reply, Info, Status};

%% DELETE_APP_FLOWER_POINT
handle_call({app_point_del, [Point_Num, PlayerId]}, _From, Status) ->
    Info = app_point_del(Point_Num, PlayerId),
    {reply, Info, Status};

%% 提供给帮派战使用
handle_call({get_all_guild_id}, _From, Status) ->
	Ids = dict:fetch_keys(Status),
    {reply, Ids, Status};

%% 帮派合并操作
handle_call({make_merge_1, [DelGuildId, NewGuildId, NewGuildName]}, _From, Status) ->
	%% 删除帮派
	NewStatus = dict:erase(DelGuildId, Status),
	%% 删除帮派邀请
	delete_guild_invite([DelGuildId, 0, NewStatus]),
	%% 删除帮派申请
	delete_guild_apply([DelGuildId, 0, NewStatus]),
	%% 更改成员的帮派信息
	GuildMemberIndexKey = ?GUILD_INDEX_MEMBER,
	GuildMemberKeyOld = ?GUILD_MEMBER_INFO ++ integer_to_list(DelGuildId),
	GuildMemberKeyNew = ?GUILD_MEMBER_INFO ++ integer_to_list(NewGuildId),
	case get(GuildMemberIndexKey) of
		undefined ->
			skip;
		Value1 ->
			%% 更新键值对
			NewDictOne_I = dict:map(fun(_KeyRid, ValueGid) ->
							 case ValueGid =:= DelGuildId of
								 true ->
									 NewGuildId;
								 false ->
									 ValueGid
							 end
					 end, Value1),
			put(GuildMemberIndexKey, NewDictOne_I)
	end,
	ValueList = case get(GuildMemberKeyOld) of
		undefined ->
			[];
		Value2 ->
			dict:to_list(Value2)
	end,
	erase(GuildMemberKeyOld),
	case get(GuildMemberKeyNew) of
		undefined ->
			ok;
		Value3 ->
			NewDictOne = add_many_member(ValueList, Value3, NewGuildId, NewGuildName),
			put(GuildMemberKeyNew, NewDictOne)
	end,
	Re = [V||{V,_}<-ValueList],
	NewStatus2 = dict:update(NewGuildId, 
							 fun(GuildInfoOld) -> 
									  GuildInfoOld#ets_guild{member_num = GuildInfoOld#ets_guild.member_num + length(Re)}
							 end, NewStatus),
    {reply, Re, NewStatus2};

%% 捐献建筑操作
handle_call({build_donate, [GuildId, PlayerId, BuildType, DonateCoin]}, _From, Status) ->
	[Res, GuildOne] = case dict:find(GuildId, Status) of
		{ok, Guild} when is_record(Guild, ets_guild) ->
			 GuildLv = Guild#ets_guild.level,
			 [BuildLV, Threshold, NowGrows] = mod_guild:get_build_cz(Guild, BuildType),
			 case BuildLV >= GuildLv of
				 false ->
					 NeedGrows = Threshold - NowGrows,
					 case NeedGrows >= DonateCoin of
						 true ->
							 case lib_player_unite:spend_assets_status_unite(PlayerId, DonateCoin, coin, guild_donate, "guild,donate,build") of
								 {ok, ok} -> 
									 NewGuild = case BuildType of
										 1 ->
											 mod_guild:furnace_up(DonateCoin, Guild);
										 2 ->
											 mod_guild:mall_up(DonateCoin, Guild);
										 3 ->
											 mod_guild:depot_up(DonateCoin, Guild);
										 4 ->
											 mod_guild:altar_up(DonateCoin, Guild)
									 end,
									 [1, NewGuild];
								 _ ->
									 [4, Guild]
							 end;
						 false ->
							 [5, Guild]
					 end;
				 true ->
					 [3, Guild]
			 end;
		_ ->
			[110, []]
	end,
	NewStatus = case GuildOne =:= [] of
					false ->
						dict:store(GuildId, GuildOne, Status);
					true ->
						Status
				end,
	{reply, Res, NewStatus};

%% 捐献建筑操作(使用资金) 
handle_call({build_donate_funds, [GuildId, _PlayerId, BuildType, Num]}, _From, Status) ->
	[Res, GuildOne] = case dict:find(GuildId, Status) of
		{ok, Guild} when is_record(Guild, ets_guild) ->
			 GuildLv = Guild#ets_guild.level,
			 [BuildLV, Threshold, NowGrows] = mod_guild:get_build_cz(Guild, BuildType),
			 case BuildLV >= GuildLv of
				 false ->
					 NeedGrows = Threshold - NowGrows,
					 case NeedGrows >= Num of
						 true ->
							 case Guild#ets_guild.funds >= 1000 andalso Guild#ets_guild.funds >= Num of
								 true ->
									 NewGuildS1 = Guild#ets_guild{funds = Guild#ets_guild.funds - Num},
									 Data = [NewGuildS1#ets_guild.funds, NewGuildS1#ets_guild.contribution, NewGuildS1#ets_guild.id],
									 SQL  = io_lib:format(?SQL_GUILD_UPDATE_FUNDS_CONTRIBUTION, Data),
									 db:execute(SQL),
									 NewGuild = case BuildType of
										 1 ->
											 mod_guild:furnace_up(Num, NewGuildS1);
										 2 ->
											 mod_guild:mall_up(Num, NewGuildS1);
										 3 ->
											 mod_guild:depot_up(Num, NewGuildS1);
										 4 ->
											 mod_guild:altar_up(Num, NewGuildS1)
									 end,
									 [1, NewGuild];
								 false ->
									 [2, Guild]
							 end;
						 false ->
							 [5, Guild]
					 end;
				 true ->
					 [3, Guild]
			 end;
		_ ->
			[110, []]
	end,
	NewStatus = case GuildOne =:= [] of
					false ->
						dict:store(GuildId, GuildOne, Status);
					true ->
						Status
				end,
	{reply, Res, NewStatus};

%% 获取强化利润
handle_call({check_furnace_back, RoleId, GuildId}, _From, Status) ->
	Res = case mod_guild_call:get_guild_member([RoleId, 1, Status]) of
		GuildMember when is_record(GuildMember, ets_guild_member) ->
			case GuildId =:= GuildMember#ets_guild_member.guild_id andalso GuildMember#ets_guild_member.furnace_back > 0 of
				true ->
					{ok, GuildMember#ets_guild_member.furnace_back};
				false ->
					{no, 0}
			end;
		_->
			{no, 0}
	end,
    {reply, Res, Status};

%% 获取强化利润
handle_call({get_furnace_back, RoleId, GuildId}, _From, Status) ->
	Res = case mod_guild_call:get_guild_member([RoleId, 1, Status]) of
		GuildMember when is_record(GuildMember, ets_guild_member) ->
			case GuildId =:= GuildMember#ets_guild_member.guild_id andalso GuildMember#ets_guild_member.furnace_back > 0 of
				true ->
					NewGuildMember = GuildMember#ets_guild_member{furnace_back = 0},
					mod_guild_call:update_guild_member([NewGuildMember]),
					{ok, GuildMember#ets_guild_member.furnace_back};
				false ->
					{no, 0}
			end;
		_->
			{no, 0}
	end,
    {reply, Res, Status};

%% 帮派解散时给全体成员发送帮派神炉返利
handle_call({send_furnace_back, [GuildId]}, _From, Status) ->    
    Res = case mod_guild_call:get_guild_member([GuildId, 0, Status]) of 
        GuildMemberList when is_list(GuildMemberList) ->
            send_furnace_back_by_mail(GuildMemberList),
            {ok, 1};
        _ ->
            {ok, 1}
    end,
    {reply, Res, Status};

%% 转接帮派关系功能
handle_call({guild_rela, Data}, _From, Status) ->
	Info = guild_rela_handle:handle_call(Data, Status),
    {reply, Info, Status};

%% 调用测试_返回进程ID
handle_call({test, _T}, _From, Status) ->
    {reply, self(), Status};
%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_guild:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.




%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 		 			以下函数都必须使用call调用_请勿直接使用
%% *****************************************************************************
%% -----------------------------------------------------------------------------
add_many_member([], DictOne, _NewGuildId, _NewGuildName)->
	DictOne;
add_many_member(ValueList, DictOne, NewGuildId, NewGuildName)->
	[H|T] = ValueList,
	{MemberId, OldGuildMember} = H,
	NewGuildMember = OldGuildMember#ets_guild_member{guild_id = NewGuildId
													, guild_name = NewGuildName
													, position = 5
													},
	NewDictOne = dict:store(MemberId, NewGuildMember, DictOne),
	add_many_member(T, NewDictOne, NewGuildId, NewGuildName).

	

%% -----------------------------------------------------------------
%% 帮派信息_相关 
%% Guild_Index : 帮派ID,帮派国家,帮派等级,解散标志
%% Guild_Info_ : ets_guild每个帮派一个Key
%% -----------------------------------------------------------------

update_guild([Guild, Status]) when is_record(Guild, ets_guild)->
	New_Status = dict:store(Guild#ets_guild.id, Guild, Status),
	{ok, New_Status};
update_guild([_Guild, Status])->
	{ok, Status}.

delete_guild([GuildId, Status]) ->
	New_Status = dict:erase(GuildId, Status),
	{ok, New_Status}.

%% 查询帮派信息
%% @param  Conditionc:查询条件
%% @param  Type:      查询类型: 0 全部, 1 按ID查询, 2 按名字查询, 3 按等级查询, 4 按解散状态查询, 5 UPPERNAME查询, 
%%							    6 按国家查询, 7 按帮主名字查询 8 同时输入帮主名字和帮派名字
%%							    11 国家,帮派名字, 12 国家,帮主名字 13, 国家, 帮派名字, 帮主名字
%% @return 0:查询失败
get_guild([Condition, Type, Status]) ->
	Info = if
			   Type == 0 ->
				   	dict:to_list(Status);
			   Type == 1  ->
					case dict:find(Condition, Status) of
						{_, V} ->
							V;
						_ ->
							[]
					end;
			   true ->
				   Dict_X = if
								Type == 2  ->
									dict:filter(fun(_, Value) -> Value#ets_guild.name =:= Condition end, Status);
								Type == 3  ->
									dict:filter(fun(_, Value) -> Value#ets_guild.level =:= Condition end, Status);
								Type == 4  ->
									dict:filter(fun(_, Value) -> Value#ets_guild.disband_flag =:= Condition end, Status);
								Type == 5  ->
									dict:filter(fun(_, Value) -> Value#ets_guild.name_upper =:= Condition end, Status);
								Type == 6  ->
									dict:filter(fun(_, Value) -> Value#ets_guild.realm =:= Condition end, Status);
								Type == 7  ->
									dict:filter(fun(_, Value) -> Value#ets_guild.chief_name =:= Condition end, Status);
								Type == 8  ->
									dict:filter(fun(_, Value) -> 
														[GuildName, ChiefName] = Condition,
														Value#ets_guild.name =:= GuildName andalso Value#ets_guild.chief_name =:= ChiefName end
											   , Status);
								Type == 11  ->
									dict:filter(fun(_, Value) -> 
														[Rrealm, GuildName] = Condition,
														Value#ets_guild.realm =:= Rrealm andalso Value#ets_guild.name =:= GuildName end
											   , Status);
								Type == 12  ->
									dict:filter(fun(_, Value) -> 
														[Rrealm, ChiefName] = Condition,
														Value#ets_guild.realm =:= Rrealm andalso Value#ets_guild.chief_name =:= ChiefName end
											   , Status);
								Type == 13  ->
									dict:filter(fun(_, Value) -> 
														[Rrealm, GuildName, ChiefName] = Condition,
														Value#ets_guild.realm =:= Rrealm andalso Value#ets_guild.name =:= GuildName andalso Value#ets_guild.chief_name =:= ChiefName end
											   , Status);
								true ->
									[]
							end,
				   case Dict_X of
					   [] ->
						   [];
					   _ ->
						   ValueList = dict:to_list(Dict_X),
						   ValueList
				   end
	end,
	{Info, Status}.

%% -----------------------------------------------------------------
%% 帮派成员信息_相关
%% -----------------------------------------------------------------

%% 更新/添加帮派成员::更新INDEX和Member两个字典
update_guild_member([GuildMember]) when is_record(GuildMember, ets_guild_member)->
	GuildMemberIndexKey = ?GUILD_INDEX_MEMBER,
	GuildMemberKey = ?GUILD_MEMBER_INFO ++ integer_to_list(GuildMember#ets_guild_member.guild_id),
	case get(GuildMemberIndexKey) of
		undefined ->
			GuildDictI = dict:new(),
			NewDictOne_I = dict:store(GuildMember#ets_guild_member.id, GuildMember#ets_guild_member.guild_id, GuildDictI),
			put(GuildMemberIndexKey, NewDictOne_I);
		Value1 ->
			NewDictOne_I = dict:store(GuildMember#ets_guild_member.id, GuildMember#ets_guild_member.guild_id, Value1),
			put(GuildMemberIndexKey, NewDictOne_I)
	end,
	case get(GuildMemberKey) of
		undefined ->
			Guild_Dict = dict:new(),
			NewDictOne = dict:store(GuildMember#ets_guild_member.id, GuildMember, Guild_Dict),
			lib_guild_base:update_guild_member_base0(GuildMember),
			put(GuildMemberKey, NewDictOne),
			ok;
		Value2 ->
			NewDictOne = dict:store(GuildMember#ets_guild_member.id, GuildMember, Value2),
			put(GuildMemberKey, NewDictOne),
			lib_guild_base:update_guild_member_base0(GuildMember),
			ok
	end;
update_guild_member([start, GuildMember]) when is_record(GuildMember, ets_guild_member)->
	GuildMemberIndexKey = ?GUILD_INDEX_MEMBER,
	GuildMemberKey = ?GUILD_MEMBER_INFO ++ integer_to_list(GuildMember#ets_guild_member.guild_id),
	case get(GuildMemberIndexKey) of
		undefined ->
			GuildDictI = dict:new(),
			NewDictOne_I = dict:store(GuildMember#ets_guild_member.id, GuildMember#ets_guild_member.guild_id, GuildDictI),
			put(GuildMemberIndexKey, NewDictOne_I);
		Value1 ->
			NewDictOne_I = dict:store(GuildMember#ets_guild_member.id, GuildMember#ets_guild_member.guild_id, Value1),
			put(GuildMemberIndexKey, NewDictOne_I)
	end,
	case get(GuildMemberKey) of
		undefined ->
			Guild_Dict = dict:new(),
			NewDictOne = dict:store(GuildMember#ets_guild_member.id, GuildMember, Guild_Dict),
			put(GuildMemberKey, NewDictOne),
			ok;
		Value2 ->
			NewDictOne = dict:store(GuildMember#ets_guild_member.id, GuildMember, Value2),
			put(GuildMemberKey, NewDictOne),
			ok
	end;
update_guild_member([offline, PlayerId, Status])->
	GuildMemberIndexKey = ?GUILD_INDEX_MEMBER,
	case get(GuildMemberIndexKey) of
		undefined ->
			%% 重新从数据库载入信息_所有帮派;
			dict:map(fun(Key, _) -> lib_guild_base:init_all_guild_member(Key) end, Status),
			[];
		Value1 ->
			case dict:find(PlayerId, Value1) of
				error ->			%%帮派信息不存在
					[];
				{ok, G_Id} ->		
					GuildMemberKey = ?GUILD_MEMBER_INFO ++ integer_to_list(G_Id),
					case get(GuildMemberKey) of
						undefined ->
							[];
						Value2 ->
							%% 获取单个帮派成员
							case dict:find(PlayerId, Value2) of
								error ->			%%成员信息不存在
									[];
								{ok, GuildMemberOne} ->		
									GuildMemberOneNew = GuildMemberOne#ets_guild_member{online_flag = 0},
									update_guild_member([GuildMemberOneNew])
							end
					end
			end
	end,
	ok;
update_guild_member([factionwer_prize, GuildId, MemberList, MaterialAdd])->
	GuildMemberIndexKey = ?GUILD_INDEX_MEMBER,
	case get(GuildMemberIndexKey) of
		undefined ->
			[];
		_Value1 ->

			GuildMemberKey = ?GUILD_MEMBER_INFO ++ integer_to_list(GuildId),
			case get(GuildMemberKey) of
				undefined ->
					[];
				Value2 ->
					%% 发送奖励 
					lists:foreach(fun(MemberId) ->
										case dict:find(MemberId, Value2) of
											error ->			%%成员信息不存在
												[];
											{ok, GuildMemberOne} ->		
												GuildMemberOneNew
												= GuildMemberOne#ets_guild_member{material = GuildMemberOne#ets_guild_member.material + MaterialAdd},
												update_guild_member([GuildMemberOneNew])
										end
								  end, MemberList),
					[]
			end
	end,
	ok;

update_guild_member([factionwar_info, PlayerId, WarScore, KillNum, NowTime])->
    GuildMemberIndexKey = ?GUILD_INDEX_MEMBER,
    case get(GuildMemberIndexKey) of
        undefined ->
            [];
        Value1 ->
            case dict:find(PlayerId, Value1) of
                error ->            %%帮派信息不存在
                    [];
                {ok, G_Id} ->       
                    GuildMemberKey = ?GUILD_MEMBER_INFO ++ integer_to_list(G_Id),
                    case get(GuildMemberKey) of
                        undefined ->
                            [];
                        Value2 ->
                            %% 获取单个帮派成员
                            case dict:find(PlayerId, Value2) of
                                error ->            %%成员信息不存在
                                    [];
                                {ok, GuildMemberOne} ->     
                                    FactionWar = GuildMemberOne#ets_guild_member.factionwar,
                                    NewFactionWar = FactionWar#factionwar_info{
                                        war_score = FactionWar#factionwar_info.war_score + WarScore,
                                        war_last_score = WarScore,
                                        war_add_num = FactionWar#factionwar_info.war_add_num + 1,
                                        last_kill_num = KillNum,
                                        war_last_time = NowTime
                                        },
                                    GuildMemberOneNew = GuildMemberOne#ets_guild_member{factionwar = NewFactionWar},
                                    update_guild_member([GuildMemberOneNew])
                            end
                    end
            end
    end,
    ok.
%% 条件删除帮派成员
%% @param  Conditionc:删除条件
%% @param  Type:      删除条件: 0 帮派ID 1 成员ID
%% @return undefined :查询失败
delete_guild_member([Condition, Type, Status]) ->
	GuildMemberIndexKey = ?GUILD_INDEX_MEMBER,
	case Type of
		0 ->
			GuildMemberKey = ?GUILD_MEMBER_INFO ++ integer_to_list(Condition),
			erlang:erase(GuildMemberKey);
		1 ->
			case get(GuildMemberIndexKey) of
				undefined ->
					%% 重新从数据库载入信息_所有帮派;
					dict:map(fun(Key, _) -> lib_guild_base:init_all_guild_member(Key) end, Status),
					[];
				Value1 ->
					case dict:find(Condition, Value1) of
						error ->			%%帮派信息不存在
							[];
						{ok, G_Id} ->		
							GuildMemberKey = ?GUILD_MEMBER_INFO ++ integer_to_list(G_Id),
							case get(GuildMemberKey) of
								undefined ->
									[];
								Value2 ->
                                    %% 返回帮派神炉铜币
                                    case dict:find(Condition, Value2) of 
                                        error ->
                                            skip;
                                        {ok, GuildMember} -> 
                                            send_furnace_back_by_mail([GuildMember])
                                    end,
									%% 删除帮派成员
									NewDictOne = dict:erase(Condition, Value2),
									put(GuildMemberKey, NewDictOne)
							end,
							%% 删除帮派成员索引
							NewDictOne_I = dict:erase(Condition, Value1),
							put(GuildMemberIndexKey, NewDictOne_I)
					end
			end
	end.
		
%% 查询帮派成员
%% @param  Conditionc:查询条件
%% @param  Type:      查询类型: 0 帮派ID 1 成员ID
%% @return undefined :查询失败_需要重新读数据
get_guild_member([Condition, Type, Status]) ->
	GuildMemberIndexKey = ?GUILD_INDEX_MEMBER,
	case Type of
		0 ->
			GuildMemberKey = ?GUILD_MEMBER_INFO ++ integer_to_list(Condition),
			GuildMemberS = case get(GuildMemberKey) of
				undefined ->
					[];
				Value ->
					ValueList = dict:to_list(Value),
					[V||{_,V}<-ValueList]
			end,
			GuildMemberS;
		2 ->
			[G_Id , Position] = Condition,
			GuildMemberKey = ?GUILD_MEMBER_INFO ++ integer_to_list(G_Id),
			case get(GuildMemberKey) of
				undefined ->
					[];
				Value2 ->
					DictFiltered = dict:filter(fun(_, ValueS) -> ValueS#ets_guild_member.position =:= Position end, Value2),
					ValueList = dict:to_list(DictFiltered),
					[V ||{_, V} <- ValueList]
			end;
		1 ->
			case get(GuildMemberIndexKey) of
				undefined ->
					%% 重新从数据库载入信息_所有帮派;
					dict:map(fun(Key, _) -> lib_guild_base:init_all_guild_member(Key) end, Status),
					[];
				Value1 ->
					case dict:find(Condition, Value1) of
						error ->			%%帮派信息不存在
							[];
						{ok, G_Id} ->		
							GuildMemberKey = ?GUILD_MEMBER_INFO ++ integer_to_list(G_Id),
							case get(GuildMemberKey) of
								undefined ->
									[];
								Value2 ->
									%% 获取单个帮派成员
									case dict:find(Condition, Value2) of
										error ->			%%成员信息不存在
											[];
										{ok, GuildMemberOne} ->		
											GuildMemberOne
									end
							end
					end
			end
	end.

%% 邮件给帮派成员发送帮派神炉返利
send_furnace_back_by_mail([]) -> skip;
send_furnace_back_by_mail([GuildMember|T]) ->
    case is_record(GuildMember, ets_guild_member) of 
        true ->
            [Title, Format1] = data_guild_text:get_mail_text(guild_furance),
            Coin = GuildMember#ets_guild_member.furnace_back,
            ConTent = io_lib:format(Format1,[Coin]), 
            case Coin > 0 of 
                true ->
                    gen_server:cast(mod_mail, {send_sys_mail, [GuildMember#ets_guild_member.id, Title, ConTent, 0, 0, Coin, 0]});
                false ->
                    skip
            end;
        false ->
            skip
    end,
    send_furnace_back_by_mail(T).



%% -----------------------------------------------------------------
%% 帮派申请与邀请
%% -----------------------------------------------------------------

%% 更新/添加帮派申请
update_guild_apply([GuildApply]) when is_record(GuildApply, ets_guild_apply)->
	GuildApplyKey = ?GUILD_APPLY,
	NewDictOneI = case get(GuildApplyKey) of
		undefined ->
			DictApply = dict:new(),
			dict:store({GuildApply#ets_guild_apply.player_id, GuildApply#ets_guild_apply.guild_id}, GuildApply, DictApply);
		Value1 ->
			dict:store({GuildApply#ets_guild_apply.player_id, GuildApply#ets_guild_apply.guild_id}, GuildApply, Value1)
	end,
	put(GuildApplyKey, NewDictOneI).

%% 条件删除帮派申请
%% @param  Conditionc:查询条件
%% @param  Type:      查询类型: 0 帮派ID 1 成员ID 2 成员ID+帮派ID
%% @return undefined :查询失败_需要重新读数据
delete_guild_apply([Condition, Type, Status]) ->
	GuildApplyKey = ?GUILD_APPLY,
	case get(GuildApplyKey) of
		undefined ->
			%% 重新从数据库载入信息_所有帮派;
			dict:map(fun(Key, _) -> 
							GuildApplyListRL = lib_guild_base:load_all_guild_apply(Key),
							lists:foreach(fun(GuildApply) -> mod_guild_call:update_guild_apply([GuildApply]) end, GuildApplyListRL)
							end, Status),
			[];
		Value1 ->
			NewDictOne = case Type of
				0 ->
					dict:filter(fun({_RoleId, GuildId}, _ValueS) -> GuildId =/= Condition end, Value1);
				1 ->
					dict:filter(fun({RoleId, _GuildId}, _ValueS) -> RoleId =/= Condition end, Value1);
				2 ->
					[PlayerIdL, GuildIdL] = Condition,
					dict:erase({PlayerIdL, GuildIdL}, Value1)
			end,
			put(GuildApplyKey, NewDictOne)
	end.
		
%% 查询帮派申请
%% @param  Conditionc:查询条件
%% @param  Type:      查询类型: 0 帮派ID 1 成员ID 2 成员ID+帮派ID
%% @return undefined :查询失败_需要重新读数据
get_guild_apply([Condition, Type, Status]) ->
 	GuildApplyKey = ?GUILD_APPLY,
	case get(GuildApplyKey) of
		undefined ->
			%% 重新从数据库载入信息_所有帮派;
			dict:map(fun(Key, _) -> 
							GuildApplyListRL = lib_guild_base:load_all_guild_apply(Key),
							lists:foreach(fun(GuildApply) -> mod_guild_call:update_guild_apply([GuildApply]) end, GuildApplyListRL)
							end, Status),
			[];
		Value1 ->
			case Type of
				0 ->
					DictFiltered = dict:filter(fun({_RoleId,  _GuildId}, _ValueS) -> _GuildId =:= Condition end, Value1),
					ValueList = dict:to_list(DictFiltered),
					[V ||{_, V} <- ValueList];
				1 ->
					DictFiltered = dict:filter(fun({_RoleId,  _GuildId}, _ValueS) -> _RoleId =:= Condition end, Value1),
					ValueList = dict:to_list(DictFiltered),
					[V ||{_, V} <- ValueList];
				2 ->
					[PlayerIdL, GuildIdL] = Condition,
					case dict:find({PlayerIdL, GuildIdL}, Value1) of
						error ->
							[];
						{ok, Value} ->
							Value
					end
			end
	end.

%% 更新/添加帮派邀请
update_guild_invite([GuildInvite]) ->
	GuildInviteKey = ?GUILD_INVITE,
	case get(GuildInviteKey) of
		undefined ->
			Dict_Invite = dict:new(),
			NewDictOne_I = dict:store({GuildInvite#ets_guild_invite.player_id, GuildInvite#ets_guild_invite.guild_id}, GuildInvite, Dict_Invite),
			put(GuildInviteKey, NewDictOne_I);
		Value1 ->
			NewDictOne_I = dict:store({GuildInvite#ets_guild_invite.player_id, GuildInvite#ets_guild_invite.guild_id}, GuildInvite, Value1),
			put(GuildInviteKey, NewDictOne_I)
	end.

%% 条件删除帮派邀请
%% @param  Conditionc:查询条件
%% @param  Type:      查询类型: 0 帮派ID 1 成员ID 2 成员ID+帮派ID
%% @return undefined :查询失败_需要重新读数据
delete_guild_invite([Condition, Type, Status]) ->
	GuildInviteKey = ?GUILD_INVITE,
	case get(GuildInviteKey) of
		undefined ->
			%% 重新从数据库载入信息_所有帮派;
			dict:map(fun(Key, _) -> 
							GuildInviteListRL = lib_guild_base:load_all_guild_invite(Key),
							lists:foreach(fun(GuildInvite) -> mod_guild_call:update_guild_invite([GuildInvite]) end, GuildInviteListRL)
							end, Status),
			[];
		Value1 ->
			NewDictOne = case Type of
				0 ->
					dict:filter(fun({_RoleId, _GuildId}, _ValueS) -> _GuildId =/= Condition end, Value1);
				1 ->
					dict:filter(fun({_RoleId, _GuildId}, _ValueS) -> _RoleId =/= Condition end, Value1);
				2 ->
					[PlayerId, GuildId] = Condition,
					dict:erase({PlayerId, GuildId}, Value1)
			end,
			put(GuildInviteKey, NewDictOne)
	end.
		
%% 查询帮派邀请
%% @param  Conditionc:查询条件
%% @param  Type:      查询类型: 0 帮派ID 1 成员ID 2 成员ID+帮派ID
%% @return undefined :查询失败_需要重新读数据
get_guild_invite([Condition, Type, Status]) ->
 	GuildInviteKey = ?GUILD_INVITE,
	case get(GuildInviteKey) of
		undefined ->
			%% 重新从数据库载入信息_所有帮派;
			dict:map(fun(Key, _) -> 
							GuildInviteListRL = lib_guild_base:load_all_guild_invite(Key),
							lists:foreach(fun(GuildInvite) -> mod_guild_call:update_guild_invite([GuildInvite]) end, GuildInviteListRL)
							end, Status),
			[];
		Value1 ->
			case Type of
				0 ->
					NewDictOne = dict:filter(fun({_RoleId, _GuildId}, _ValueS) -> _GuildId =:= Condition end, Value1),
					ValueList = dict:to_list(NewDictOne),
					[V ||{_, V} <- ValueList];
				1 ->
					NewDictOne = dict:filter(fun({_RoleId, _GuildId}, _ValueS) -> _RoleId =:= Condition end, Value1),
%% 					io:format("NewDictOne : ~p~n", [NewDictOne]),
					ValueList = dict:to_list(NewDictOne),
					[V ||{_, V} <- ValueList];
				2 ->
					[PlayerId, GuildId] = Condition,
					case dict:find({PlayerId, GuildId}, Value1) of
						error ->
							[];
						{ok, R} ->
							R
					end
			end
	end.

%% -----------------------------------------------------------------
%% 帮派技能相关
%% -----------------------------------------------------------------

%% 获取帮派技能信息_个人
get_guild_skill_player([GuildId, GuildMember, Status])->
	GuildIdKey = ?GUILD_SKILL_MEMBER++integer_to_list(GuildMember#ets_guild_member.id),
	ContactInfo = case get(GuildIdKey) of
		undefined -> 
			init_guild_skill_player([GuildId, GuildMember, GuildIdKey, Status]);
		Value->
			[SkillListPANDG, Player_Donate_Old] = Value,
			case GuildMember#ets_guild_member.donate_total == Player_Donate_Old of
				true ->
					SkillListPANDG;
				false ->
					init_guild_skill_player([GuildId, GuildMember, GuildIdKey, Status])
			end
	end,
	ContactInfo.

%% 初始化帮派技能ID_个人
init_guild_skill_player([GuildId, GuildMember, GuildIdKey, Status]) ->
	SkillList_G = get_guild_skill_guild([GuildId, Status]),
	SkillList = data_guild:get_guild_skill_all(),
	BaseSkillList = [10001, 10002, 10003, 10004, 10005, 10006, 10007],
	SkillList_P = guild_skill_init_player([BaseSkillList,SkillList,[]], GuildMember#ets_guild_member.donate_total),
	SkillListPANDG = lists:zipwith(fun(X, Y) -> case erlang:element(1, X) =< erlang:element(1, Y) of
								   true ->
									   X;
								   false ->
									   Y
							   end
				  end, SkillList_G, SkillList_P),
	put(GuildIdKey, [SkillListPANDG, GuildMember#ets_guild_member.donate_total]),
	SkillListPANDG.

%% 获取帮派技能信息_帮派
get_guild_skill_guild([GuildId, Status])->
	GuildIdKey = ?GUILD_SKILL++integer_to_list(GuildId),
	{Guild_Info, _} = get_guild([GuildId, 1, Status]),
	Guild_Skillt_Info = case get(GuildIdKey) of
		undefined -> 
			init_guild_skill_guild([GuildId, Status]);
		Value->
			%% 判断等级是否有变化
			[SkillListGuild, GuildLevelOld] = Value,
			case Guild_Info#ets_guild.level == GuildLevelOld of
				true ->
					SkillListGuild;
				false ->
					init_guild_skill_guild([GuildId, Status])
			end
	end,
	Guild_Skillt_Info.
	
%% 初始化帮派技能ID
init_guild_skill_guild([GuildId, Status]) ->
	GuildIdKey = "Guild_Skill_"++integer_to_list(GuildId),
	{Guild_Info, _} = get_guild([GuildId, 1, Status]),
%% 	io:format("~nGuild_Info: : ~p: ~p~n", [Guild_Info, GuildId]),
	SkillList = data_guild:get_guild_skill_all(),
	BaseSkillList = [10001, 10002, 10003, 10004, 10005, 10006, 10007],
	%% 获取了目前帮派达到的技能等级
	Skill_TupleList_Step_3 = guild_skill_init([BaseSkillList,SkillList,[]], Guild_Info#ets_guild.level),
	put(GuildIdKey, [Skill_TupleList_Step_3, Guild_Info#ets_guild.level]),
	%%put(GuildIdKey, Skill_TupleList_Step_3),
	Skill_TupleList_Step_3.

%% 递归挑选帮派技能信息_帮派_私有
guild_skill_init([[],_,List3], _Guild_level)->
	lists:usort(List3);
guild_skill_init([List1,List2,List3], Guild_level)->
	[H|List1_Next] = List1,	
	{LT3_1, List2_Next} = lists:partition(fun(A) -> erlang:element(2, A) == H end, List2),
	LT3_1_S = lists:sort(fun(A, B) -> erlang:element(1, A) < erlang:element(1, B) end, LT3_1),
	LT3_Next = case lists:partition(fun(A) -> erlang:element(4, A) < Guild_level end, LT3_1_S) of
		{LT3_1_S_1, []} ->
			[LT3_1_S_1_Next|_] = lists:reverse(LT3_1_S_1),
			LT3_1_S_1_Next;
		{_LT3_A, LT3_B} ->
			[LT3_1_S_1_Next|_] = LT3_B,
			LT3_1_S_1_Next
	end,
	List3_Next = [LT3_Next|List3],
	guild_skill_init([List1_Next, List2_Next, List3_Next], Guild_level).

%% 递归挑选帮派技能信息_个人_私有
guild_skill_init_player([[],_,List3], _Player_Donate)->
	lists:usort(List3);
guild_skill_init_player([List1,List2,List3], Player_Donate)->
	[H|List1_Next] = List1,	
	{LT3_1, List2_Next} = lists:partition(fun(A) -> erlang:element(2, A) == H end, List2),
	LT3_1_S = lists:sort(fun(A, B) -> erlang:element(1, A) < erlang:element(1, B) end, LT3_1),
	LT3_Next = case lists:partition(fun(A) -> erlang:element(5, A) < Player_Donate end, LT3_1_S) of
		{LT3_1_S_1, []} ->
			[LT3_1_S_1_Next|_] = lists:reverse(LT3_1_S_1),
			LT3_1_S_1_Next;
		{_LT3_A, LT3_B} ->
			[LT3_1_S_1_Next|_] = LT3_B,
			LT3_1_S_1_Next
	end,
	List3_Next = [LT3_Next|List3],
	guild_skill_init_player([List1_Next, List2_Next, List3_Next], Player_Donate).

%% -----------------------------------------------------------------
%% 帮派通讯录相关
%% -----------------------------------------------------------------

%% 获取帮派通讯录
get_guild_contact_info(GuildId) ->
	GuildIdKey = ?GUILD_CONTACT_BOOK++integer_to_list(GuildId),
	ContactInfo = case get(GuildIdKey) of
		undefined -> 
			Data = db:get_all(io_lib:format(?SQL_GUILD_CONTACT_BOOK_SELECT, [GuildId])),
			put(GuildIdKey, Data),
			Data;
		Value->
			Value
	end,
	ContactInfo.

%% 修改_添加_帮派通讯录
set_guild_contact_info([PlayerId, GuildId, PlayerName, City, QQ, PhoneNum, BirDay, HideType, PlayerLv]) ->
	GuildIdKey = ?GUILD_CONTACT_BOOK++integer_to_list(GuildId),
	Sql = io_lib:format(?SQL_GUILD_CONTACT_BOOK_INSERTORUPDATE
						,[PlayerId, GuildId, PlayerName, City, QQ, PhoneNum, BirDay, HideType, PlayerLv
								  , GuildId, PlayerName, City, QQ, PhoneNum, BirDay, HideType, PlayerLv]),
	db:execute(Sql),
	case get(GuildIdKey) of
		undefined -> 
			Data = db:get_all(io_lib:format(?SQL_GUILD_CONTACT_BOOK_SELECT, [GuildId])),
			put(GuildIdKey, Data);
		Value->
			F = fun(G_Value) ->
						[PlayerIdX|_] = G_Value,
						case PlayerIdX =:= PlayerId of
						   true->
							  [PlayerId, GuildId, PlayerName, City, QQ, PhoneNum, BirDay, HideType, PlayerLv];
						   false->
							  G_Value
						end
			end,
			NewContactInfo = [F(D) || D <- Value],
			NLC = [[PlayerId, GuildId, PlayerName, City, QQ, PhoneNum, BirDay, HideType, PlayerLv]|NewContactInfo],
			NLC_2 = lists:usort(NLC),
			put(GuildIdKey, NLC_2)
	end,
	ok.

%% -----------------------------------------------------------------
%% 帮派成就相关
%% -----------------------------------------------------------------

%% 根据类型创建一条新的目标记录
new_guild_achieve_info([GuildId, AchieveType]) ->
	Dictlist = get_guild_achieve_info(GuildId),
	NewRecord = [GuildId, AchieveType, 0, 0, 0, 0, 0, 1],
	save_guild_achieve(Dictlist, NewRecord),
	{GuildId, AchieveType, 0, 0, 0, 0, 0, 1}.

%% 获取帮派成就列表
get_guild_achieve_info(GuildId) ->
	GuildIdKey = ?GUILD_ACHIEVED++integer_to_list(GuildId),
	Achieved_Info = case get(GuildIdKey) of
		undefined -> 
			Data = db:get_all(io_lib:format(?SQL_GUILD_ACHIEVE_SELECT, [GuildId])),
			DictList = [erlang:list_to_tuple(D) || D <- Data],
			put(GuildIdKey, DictList),
			DictList;
		Value->
			Value
	end,
%% 	io:format("achieve : : ~p: ~p~n", [Achieved_Info, GuildId]), 
	Achieved_Info.

%% 修改帮派成就列表_领取奖励
get_guild_achieve_prize([GuildId, AchievedType]) ->
	Dictlist = get_guild_achieve_info(GuildId),
	case lists:keysearch(AchievedType, 2, Dictlist) of
				   false ->
					   %% 无成就记录
					   NewRecord = new_guild_achieve_info([GuildId, AchievedType]),
					   [0,NewRecord];
				   {value, Value} ->%%
					   {_, _, _, IsAchieved, GetPrize, Condition1NumOld, Condition2NumOld, AchievedLevel} = Value,
					   case GetPrize >= IsAchieved of
						   true ->
							   [0,[]];
						   false ->
							   [_, _, AchieveTime, IsAchieved, GetPrize, Condition1NumOld, Condition2NumOld, AchievedLevel] = Value,
							   Full_Type = AchievedType * 10 + AchievedLevel,
							   GetPrizeNew = GetPrize + 1,
							   AchievedLevelNew = AchievedLevel + 1,
							   save_guild_achieve(Dictlist, [GuildId, AchievedType, AchieveTime, IsAchieved, GetPrizeNew, Condition1NumOld, Condition2NumOld, AchievedLevelNew]),
							   [_ ,_ ,G_Funds ,G_Contribution ,G_menber_Donate ,G_menber_Material] = data_guild:get_guild_achieve_more(Full_Type),
							   [1,[G_Funds ,G_Contribution ,G_menber_Donate ,G_menber_Material]]
					   end
	end.

%% 修改帮派成就列表_新条件_由事件触发_不是由协议触发的 
set_guild_achieve_info([GuildId, AchievedType, Condition1_now, Condition2_now]) ->
	Dictlist = get_guild_achieve_info(GuildId),
	ValueNew = case lists:keysearch(AchievedType, 2, Dictlist) of
		false ->
			Full_Type = AchievedType * 10 + 1,
			%%[{_, _Max_AchievedLevel, _}] = data_guild:get_guild_achieve_info_data(AchievedType, 1),			%% 获取最高等级限制
			[Condition1	,Condition2	,_	,_	,_	,_] = data_guild:get_guild_achieve_more_data(Full_Type),		%% 获取等级目标的到达条件
			case Condition1_now >= Condition1 andalso Condition2_now >= Condition2 of
				false ->
					%% 未达到条件
					[GuildId, AchievedType, 0, 0, 0, Condition1_now, Condition2_now, 1];
				true ->
					IsAchieved = 1,
					AchievedLevel = 2,
					[GuildId, AchievedType, 0, IsAchieved, 0, Condition1_now, Condition2_now, AchievedLevel]
			end;
		{value, Value} ->
			{_, _, AchieveTime, IsAchieved, GetPrize, _Condition1NumOld, _Condition2NumOld, AchievedLevel} = Value,
			Full_Type = AchievedType * 10 + AchievedLevel,
			[{_, Max_AchievedLevel, _}] = data_guild:get_guild_achieve_info_data(AchievedType, 1),					%% 获取最高等级限制
			[Condition1	,Condition2	,_	,_	,_	,_] = data_guild:get_guild_achieve_more_data(Full_Type),		%% 获取等级目标的到达条件
			if
				IsAchieved >= Max_AchievedLevel ->
					Value;
				Condition1_now >= Condition1 andalso Condition2_now >= Condition2  ->
					IsAchieved_New = IsAchieved + 1,
					NowTime = util:unixtime(),
					[GuildId, AchievedType, NowTime, IsAchieved_New, GetPrize, Condition1_now, Condition2_now, AchievedLevel];
				true ->
						[GuildId, AchievedType, AchieveTime, IsAchieved, GetPrize, Condition1_now, Condition2_now, AchievedLevel]
			end
	end,
	save_guild_achieve(Dictlist, ValueNew),
	ok.

%% 私有_修改帮派成就列表_缓存以及数据库
save_guild_achieve(Dictlist, [GuildId, AchievedType, AchieveTime, IsAchieved, GetPrize, Condition1_num, Condition2_num, AchievedLevel])->
	New_Key = GuildId*100000 + AchievedType,
	Sql = io_lib:format(?SQL_GUILD_ACHIEVE_INSERTORUPDATE
						,[New_Key, GuildId, AchievedType, AchieveTime, IsAchieved, GetPrize, Condition1_num, Condition2_num, AchievedLevel
						 ,GuildId, AchievedType, AchieveTime, IsAchieved, GetPrize, Condition1_num, Condition2_num, AchievedLevel]),
	db:execute(Sql),
	GuildIdKey = ?GUILD_ACHIEVED++integer_to_list(GuildId),
	NewDictOne_List = case lists:keysearch(AchievedType, 2, Dictlist) of
		false ->
			%% 没有这个类型的数据_插入新数据
			[{GuildId, AchievedType, AchieveTime, IsAchieved, GetPrize, Condition1_num, Condition2_num, AchievedLevel}|Dictlist];
		{value, _} ->
			lists:keyreplace(AchievedType, 2, Dictlist, {GuildId, AchievedType, AchieveTime, IsAchieved, GetPrize, Condition1_num, Condition2_num, AchievedLevel})
	end,
	put(GuildIdKey, NewDictOne_List).

%% -----------------------------------------------------------------
%% 帮派神兽相关 
%% -----------------------------------------------------------------

%% 更新帮派神兽信息
%% @param AnimalLeve	神兽等级
%% @param AnimalExp	    神兽经验值
update_guild_godanimal([GuildId, AnimalLeve, AnimalExp, _Status]) ->
	New_Key = ?GUILD_GODANIMAL,
	%% 存数据库
	GA_One = save_guild_godanimal_sql([GuildId, AnimalLeve, AnimalExp]),
	GA_Dict = case get(New_Key) of
		undefined ->
			init_guild_godanimal([GuildId]);
		Value ->
			Value
	end,
	New_GA_Dict = dict:store(GuildId, GA_One, GA_Dict),
	put(New_Key, New_GA_Dict),
	New_GA_Dict.

%% 帮派神兽战斗胜利
guild_godanimal_win([GuildId, AnimalLeve, AnimalExp, Status]) ->
	%% 获取帮派等级
	GuildLv = case dict:find(GuildId, Status) of
		{_, V} ->
			V#ets_guild.level;
		_ ->
			0
	end,
	case AnimalLeve > (GuildLv * 3 + 35) of
		true ->
			false;
		false ->
			New_Key = ?GUILD_GODANIMAL,
			%% 存数据库
			GA_One = save_guild_godanimal_sql([GuildId, AnimalLeve, AnimalExp]),
			GA_Dict = case get(New_Key) of
				undefined ->
					init_guild_godanimal([GuildId]);
				Value ->
					Value
			end,
			New_GA_Dict = dict:store(GuildId, GA_One, GA_Dict),
			put(New_Key, New_GA_Dict),
			true
	end.

%% 删除一条帮派神兽信息
%% 删除的时候如果没有数据,不进行初始化
delete_guild_godanimal([GuildId, _Status]) ->
	New_Key = ?GUILD_GODANIMAL,
	%% 删除数据库内容
	delete_guild_godanimal_sql([GuildId]),
	case get(New_Key) of
		undefined ->
			%% 重新初始化
			ok;
		Value ->
			dict:erase(GuildId, Value),
			ok
	end.

%% 获取帮派神兽信息
get_guild_godanimal([GuildId, _Status]) ->
	New_Key = ?GUILD_GODANIMAL,
	case get(New_Key) of
		undefined ->
			%% 重新初始化
			GA_Dict = init_guild_godanimal([GuildId]),
			{_, GA_One} = dict:find(GuildId, GA_Dict),
			GA_One;
		Value ->
			case dict:find(GuildId, Value) of
				error ->
					%% 缓存中无数据_初始化神兽信息
					GA_Dict = init_guild_godanimal([GuildId]),
					{_, GA_One} = dict:find(GuildId, GA_Dict),
					GA_One;
				{ok, GA_One} ->
					GA_One
			end
	end.

%% 初始化帮派的帮派神兽
init_guild_godanimal([GuildId]) ->
	New_Key = ?GUILD_GODANIMAL,
	GA_Dict = case get(New_Key) of
		undefined ->
			dict:new();
		Value ->
			Value
	end,
	New_GA_Dict = case get_guild_godanimal_sql([GuildId]) of
		[] ->
			%% 数据库中无信息_初始化神兽_0级
			GA_One = save_guild_godanimal_sql([GuildId, 35, 0]),
			dict:store(GuildId, GA_One, GA_Dict);
		[GA_One] ->
			dict:store(GuildId, GA_One, GA_Dict)
	end,
	put(New_Key, New_GA_Dict),
	New_GA_Dict.


%% 私有_修改/插入帮派神兽数据库
save_guild_godanimal_sql([GuildId, AnimalLeve, AnimalExp]) ->
	SQL = io_lib:format(?SQL_GUILD_GODANIMAL_INSERTORUPDATE
						,[GuildId, AnimalLeve, AnimalExp
						 ,AnimalLeve, AnimalExp]),
	db:execute(SQL),
	[GuildId, AnimalLeve, AnimalExp].


%% 私有_读取帮派神兽数据库
%% @param Condition => 0 读取所有神兽数据, 非0 读取指定帮派的神兽信息
get_guild_godanimal_sql([Condition]) ->
	SQL  = case Condition of
				0 ->
					io:format("error get_guild_godanimal_sql"),
					io_lib:format(?SQL_GUILD_GODANIMAL_SELECT_ALL, []);
				_ ->
					io_lib:format(?SQL_GUILD_GODANIMAL_SELECT_ONE, [Condition])
		   end,
	case db:get_all(SQL) of
		[[GuildId, GA_Level, GA_Exp]] ->
			NewLevel = case GA_Level > ?GodAnimal_Level_Limit of
				true ->
					save_guild_godanimal_sql([GuildId, ?GodAnimal_Level_Limit, GA_Exp]),
					?GodAnimal_Level_Limit;
				false ->
					GA_Level
			end,
			[[GuildId, NewLevel, GA_Exp]];
		R ->
			R
	end.


%% 私有_删除帮派神兽数据库
delete_guild_godanimal_sql([GuildId]) ->
	SQL = io_lib:format(?SQL_GUILD_GODANIMAL_DELETE_ONE, [GuildId]),
	db:execute(SQL).


%% 记录帮派神兽成长事件
save_guild_ga_event([GuildId, NewGAEvent])->
	New_Key = "ga_event",
	BinNewGAEvent = util:term_to_bitstring(NewGAEvent),
	SQL = io_lib:format(?SQL_GUILD_GA_LOG_INSERTORUPDATE
						,[GuildId, BinNewGAEvent
						 ,BinNewGAEvent]),
	db:execute(SQL),
	GALogDict = case get(New_Key) of
		undefined ->
			dict:new();
		Value ->
			Value
	end,
	New_GA_Dict = dict:store(GuildId, NewGAEvent, GALogDict),
	put(New_Key, New_GA_Dict),
	New_GA_Dict.

%% 获取帮派神兽成长事件
get_guild_ga_event(GuildId) ->
	New_Key = "ga_event",
	F = fun(GID) ->
				SQL  = io_lib:format(?SQL_GUILD_GA_LOG_SELECT_ONE, [GID]),
				case db:get_all(SQL) of
					 [] ->
						 [];
					 [[VV]] ->
						 case util:string_to_term(erlang:binary_to_list(VV)) of
							 undefined ->
								 [];
							 Vl ->
								 Vl
						 end
				end
		end,
	EventGot = case get(New_Key) of
		undefined ->
			V = F(GuildId),
			GALogDict = dict:new(),
			NewGADict = dict:store(GuildId, V, GALogDict),
			put(New_Key, NewGADict),
			V;
		Value ->
			case dict:find(GuildId, Value) of
				error ->
					V = F(GuildId),
					GALogDict = dict:new(),
					NewGADict = dict:store(GuildId, V, GALogDict),
					put(New_Key, NewGADict),
					V;
				{ok, GAEvent} ->
					GAEvent
			end
	end, 
	EventGot.

%% -----------------------------------------------------------------
%% 帮派神兽相关 (神兽养成部分)
%% -----------------------------------------------------------------
%% @return Stage, StageExp, 是否升级(0 未升级 1 升级)
ga_donate_stage(GuildId, RoleId, Num, Status) ->
	CaiFuAdd = Num * 3,
	StageExpAdd = Num * 10,
	[StageOld, StageExpOld] = ga_stage_info(GuildId),
	{_, GrowsNeed, _, _} = data_guild_ga_stage:get_stage_info(StageOld),
	StageExp1 = StageExpOld + StageExpAdd,
	[RStage, RStageExp, IsUp] = 
	case StageOld >= 10 of
		true ->
			[StageOld, StageExp1, 0];
		false ->
			case StageExp1 >= GrowsNeed of
				true -> %% 升级
					[StageNew, StageExpNew] = loop_update(StageExp1, GrowsNeed, StageOld, 10),
					replace_ga_stage_info(GuildId, StageNew, StageExpNew),
					[StageNew, StageExpNew, 1];
				false ->
					replace_ga_stage_info(GuildId, StageOld, StageExp1),
					[StageOld, StageExp1, 0]
			end
	end,
	GuildMember = get_guild_member([RoleId, 1, Status]),
	update_guild_member([GuildMember#ets_guild_member{material = GuildMember#ets_guild_member.material + CaiFuAdd}]),
	[RStage, RStageExp, IsUp].

loop_update(StageExp1, _, StageOld, 0) ->
	[StageOld, StageExp1];
loop_update(StageExp1, GrowsNeedNow, StageOld, Times) ->
	case StageExp1 >= GrowsNeedNow of
		true ->
			StageExpNew = StageExp1 - GrowsNeedNow,
			StageNew = case StageOld >= 10 of
						   true ->
							   10;
						   false ->
							   StageOld + 1
					   end,
			{_, GrowsNeedNew, _, _} = data_guild_ga_stage:get_stage_info(StageNew),
			loop_update(StageExpNew, GrowsNeedNew, StageNew, Times - 1);
		false ->
			[StageOld, StageExp1]
	end.

ga_stage_info(GuildId) ->
	case get({ga_stage, GuildId}) of
		{Stage, StageExp} ->
			[Stage, StageExp];
		_ ->
			init_ga_stage_info(GuildId)
	end.

init_ga_stage_info(GuildId) ->
	Sql = io_lib:format(?SQL_GUILD_GA_STAGE_SELECT_ONE, [GuildId]),
    [Stage, StageExp] = case db:get_row(Sql) of
        [] -> %% 没有数据 插入一条
			Sql2 = io_lib:format(?SQL_GUILD_GA_STAGE_REPLACE, [GuildId, 1, 0]),
			db:execute(Sql2),
			[1, 0];
        [_, StageOld, StageExpOld] ->
			[StageOld, StageExpOld]
    end,
	put({ga_stage, GuildId}, {Stage, StageExp}),
	[Stage, StageExp].

replace_ga_stage_info(GuildId, Stage, StageExp) ->
	Sql2 = io_lib:format(?SQL_GUILD_GA_STAGE_REPLACE, [GuildId, Stage, StageExp]),
	db:execute(Sql2),
	put({ga_stage, GuildId}, {Stage, StageExp}),
	[Stage, StageExp].

%% -----------------------------------------------------------------
%% 帮派试炼任务 == 运势任务 相关
%% -----------------------------------------------------------------

%% 插入运势信息
update_fortune(PlayerId, OneFortune) ->
	New_Key = "role_fortune",
%% 	io:format(" ft 1: ~p ~n" , [PlayerId]),
	NewDict2 = case get(New_Key) of
		undefined ->
			NewDict = dict:new(),
			dict:store(PlayerId, OneFortune, NewDict);
		Value ->
			dict:store(PlayerId, OneFortune, Value)
	end,
	update_fortune_db(OneFortune),
	put(New_Key, NewDict2),
	ok.

%% 获取运势信息 
get_fortune(PlayerId) ->
	New_Key = "role_fortune",
	case get(New_Key) of
		undefined ->
			case get_fortune_db(PlayerId) of
				[] ->
					error;
				Fortune ->
					NewDict = dict:new(),
					NewDict2 = dict:store(PlayerId, Fortune, NewDict),
					put(New_Key, NewDict2),
					Fortune
			end;	  
		Value ->
			case dict:find(PlayerId, Value) of
				error ->
					case get_fortune_db(PlayerId) of
						[] ->
							error;
						Fortune ->
							NewDict2 = dict:store(PlayerId, Fortune, Value),
							put(New_Key, NewDict2),
							Fortune
					end;	
				{ok, Fortune} ->
					Fortune
			end
	end.

%% 获取帮派成员运势列表
get_fortune_list(PlayerIdList) ->
	[get_fortune(PlayerId)||PlayerId<-PlayerIdList].

%% 写入成员运势 数据库
update_fortune_db(OneFortune) ->
	OneFortuneList = util:record_to_list(OneFortune),
	[_|T] = OneFortuneList,
	Data = OneFortuneList ++ T,
	SQL = io_lib:format(?SQL_GUILD_FORTUNE_INSERTORUPDATE,Data),
	db:execute(SQL).

%% 获取成员运势信息 数据库
get_fortune_db(PlayerId) ->
	SQL  = io_lib:format(?SQL_GUILD_FORTUNE_SELECT_ONE, [PlayerId]),
	case db:get_all(SQL) of
		 [] ->
			 [];
		 [R] ->
			 util:list_to_record(R, rc_fortune)
	end.
					 
%% 写入运势刷新纪录(最大只记录4条)
update_fortune_log(PlayerId, FortuneLog) ->
%% 	io:format("PlayerId 1: ~p ~n", [PlayerId]),
	New_Key = "fortune_log",
	NewDict2 = case get(New_Key) of
		undefined ->
			NewDict = dict:new(),
			dict:store(PlayerId, [FortuneLog], NewDict);
		Value ->
			case dict:find(PlayerId, Value) of
				error ->
					dict:store(PlayerId, [FortuneLog], Value);
				{ok, FortuneLogList} ->
					case erlang:length(FortuneLogList) >= 4 of
						true->
							L1 = lists:reverse(FortuneLogList),
							[_|L2] = L1,
							L3 = lists:reverse(L2),
							dict:store(PlayerId, [FortuneLog|L3], Value);
						false ->
							dict:store(PlayerId, [FortuneLog|FortuneLogList], Value)
					end
			end
	end,
	put(New_Key, NewDict2),
	ok.

get_fortune_log(PlayerId) ->
%% 	io:format("PlayerId 2: ~p ~n", [PlayerId]),	
	New_Key = "fortune_log",
	case get(New_Key) of
		undefined ->
			error;
		Value ->
			case dict:find(PlayerId, Value) of
				error ->
					error;
				{ok, FortuneLogList} ->
					FortuneLogList
			end
	end.

clear_fortune_log() ->
	New_Key2 = "role_fortune",
	New_Key = "fortune_log",
	SQL  = io_lib:format(?SQL_GUILD_FORTUNE_DELETE_ALL, []),
	db:execute(SQL),
	erlang:erase(New_Key2),
	erlang:erase(New_Key),
	NewDict = dict:new(),
	put(New_Key, NewDict),
	put(New_Key2, NewDict).
	
%% -----------------------------------------------------------------
%% 其他数据
%% -----------------------------------------------------------------
app_point_get(Point_Num, PlayerId) ->
	New_Key = app_game_point,
	case get(New_Key) of
		undefined ->
			%% 重新初始化
			Dict = dict:new(),
			NewDict = dict:store(Point_Num, [{PlayerId}], Dict),
			put(New_Key, NewDict),
			NewDict;
		Value ->
			Value
	end.

app_point_put(Point_Num, PlayerId) ->
	New_Key = app_game_point,
	Dict = app_point_get(Point_Num, PlayerId),
	NewDict = case dict:find(Point_Num, Dict) of
		error ->
			dict:store(Point_Num, [{PlayerId}], Dict);
		{ok, Value} ->
			case lists:keyfind(PlayerId, 1, Value) of
				false ->
					NewList = [{PlayerId}|Value],
					dict:store(Point_Num, NewList, Dict);
				_Value2 ->
					Dict
			end
			  end,
	put(New_Key, NewDict),
	NewDict.

app_point_del(Point_Num, PlayerId) ->
	New_Key = app_game_point,
	case get(New_Key) of
		undefined ->
			skip;
		Dict ->
			case dict:find(Point_Num, Dict) of
				error ->
					skip;
				{ok, Value} ->
					case lists:keytake(PlayerId, 1, Value) of
						fasle ->
							skip;
						{value, _, TupleList2} ->
							NewDict = dict:store(Point_Num, TupleList2, Dict),
							put(New_Key, NewDict)
					end
			end
	end.

%% ----------------------------- E  N  D ---------------------------------------


