%% --------------------------------------------------------
%% @Module:           |pp_guild_scene
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-05
%% @Description:      |帮派场景相关功能处理接口 
%% --------------------------------------------------------

-module(pp_guild_scene).
-export([handle/3]).
-include("common.hrl").
-include("qlc.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("guild.hrl").
-include("buff.hrl").

%%=========================================================================
%% 接口函数
%%=========================================================================

%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 						帮派宴会相关 
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 进入帮派场景   
%% -----------------------------------------------------------------
handle(40100, PlayerStatus, [Type]) ->
	PlayerId = PlayerStatus#player_status.id,
	GuildQuitNum = mod_daily_dict:get_count(PlayerId, 4007806),
	case GuildQuitNum >= 1 of
		true ->
			{ok, BinData} = pt_400:write(40098, [1]),
		    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
			ok;
		false ->
			PlayerGuild = PlayerStatus#player_status.guild,
			case PlayerGuild#status_guild.guild_id =:= 0 orelse PlayerStatus#player_status.change_scene_sign =/= 0 of
				true -> 
					{ok, BinData} = pt_401:write(40100, [Type, 0]),
					lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
					ok;
				false ->
					case lib_guild_scene:enter_guild_scene(PlayerStatus, Type) of
						{ok, PlayerStatusNew} ->
							{ok, BinData} = pt_401:write(40100, [Type, 1]),
							lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
							{ok, PlayerStatusNew};
						_ ->
							{ok, BinData} = pt_401:write(40100, [Type, 0]),
							lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
							ok
					end
			end
	end;

%% -----------------------------------------------------------------
%% 召开帮宴
%% -----------------------------------------------------------------
handle(40101, PlayerStatus, [_PlayerId, GuildId, Type, Start_Time]) ->
	PlayerGuild = PlayerStatus#player_status.guild,
	case Type=:=1 andalso PlayerGuild#status_guild.guild_position > 2 of
		true ->  %% 职位不够
			{ok, BinData} = pt_401:write(40101, [5]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
			ok;
		false ->
			case mod_disperse:call_to_unite(lib_guild_base, get_guild, [GuildId]) of
				[] ->
					{ok, BinData} = pt_401:write(40101, [0]),
					lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
					ok;
				Guild -> %% 成功就会发40000公告协议 类型:51					
					{Res, NewPlayerStatus} = lib_guild_scene:start_one_guild_party(PlayerStatus, [Guild
							, PlayerStatus#player_status.id
							, PlayerStatus#player_status.nickname
							, PlayerStatus#player_status.image
							, PlayerStatus#player_status.sex
							, PlayerStatus#player_status.career
							, Type
							, Start_Time]),					
					{ok, BinData} = pt_401:write(40101, [Res]),
					lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
					%% 发送传闻 
					case Res =:= 1 andalso Type =:=3 of
						false ->
							skip;
						true ->	 	
							lib_chat:send_TV({all},0, 2, [xianyan,1
									,[Guild#ets_guild.name]
									,PlayerStatus#player_status.id
									,PlayerStatus#player_status.realm
									,PlayerStatus#player_status.nickname
									,PlayerStatus#player_status.sex
									,PlayerStatus#player_status.career
									,PlayerStatus#player_status.image
								])
					end,
					{ok, NewPlayerStatus}
			end
	end;


%% -----------------------------------------------------------------
%% 获取技能列表
%% -----------------------------------------------------------------
handle(40102, PlayerStatus, get_skill_list) ->  
	Res = 1,SkillList=[0,1,2,3,4,5],
    {ok, BinData} = pt_401:write(40102, [Res, SkillList]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	{ok, PlayerStatus};
%% -----------------------------------------------------------------
%% 使用宴会技能
%% -----------------------------------------------------------------
handle(40103, PlayerStatus, [_Skill_Id, _Target_PlayerId]) ->  
	Res = 1,
    {ok, BinData} = pt_401:write(40103, [Res]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	{ok, PlayerStatus};

%% -----------------------------------------------------------------
%% 使用宴会气氛物品
%% -----------------------------------------------------------------
handle(40105, PlayerStatus, [GoodsTypeId]) ->  
	PlayerId = PlayerStatus#player_status.id,
	GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
	{Res, _, Type, Mood_Add} = lib_guild_scene:use_mood_goods(PlayerStatus, GoodsTypeId),
	case Res of
		1 ->
			%% 对场景内的人广播_帮派宴会事件
			case GoodsTypeId of
				412004 ->	%%使用侍女
					{ok, BinData} = pt_401:write(40105, [Res, PlayerId, GoodsTypeId, Type, Mood_Add]),
					lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
				412002 ->	%%使用传音
					{ok, BinData} = pt_401:write(40105, [Res, PlayerId, GoodsTypeId, Type, Mood_Add]),
					lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
				_ ->
					{ok, BinData} = pt_401:write(40105, [Res, PlayerId, GoodsTypeId, Type, Mood_Add]),
					lib_server_send:send_to_scene(?GUILD_SCENE, GuildId, BinData)
			end;
		_ ->
			{ok, BinData} = pt_401:write(40105, [Res, PlayerId, GoodsTypeId, Type, Mood_Add]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData)
	end,
	{ok, PlayerStatus};

%% %% -----------------------------------------------------------------
%% %% 传音发送信息
%% %% -----------------------------------------------------------------
handle(40106, _PlayerStatus, [GuildId, _PlayerId, PlayerName, Title, Content]) ->  
	Res = 1,
	{ok, BinData} = pt_401:write(40106, [Res, PlayerName, Title, Content]),
	lib_server_send:send_to_scene(?GUILD_SCENE, GuildId, BinData);

%% -----------------------------------------------------------------
%% 查询宴会记录
%% -----------------------------------------------------------------
handle(40107, PlayerStatus, [G_Id]) ->
	Res = 1, Time = G_Id ,Sponsor_Id = PlayerStatus#player_status.id, Sponsor_Name = PlayerStatus#player_status.nickname,
    {ok, BinData} = pt_401:write(40107, [Res, Time, Sponsor_Id, Sponsor_Name]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	{ok, PlayerStatus};

%% -----------------------------------------------------------------
%% 帮宴传音 
%% -----------------------------------------------------------------
handle(40111, PlayerStatus, [_GuildId, _PlayerId, _Content]) ->  
	%% 发40000公告协议 类型:53
	Res = 1,
    {ok, BinData} = pt_401:write(40111, [Res]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	{ok, PlayerStatus};

%% -----------------------------------------------------------------
%% 帮派宴会开始时间
%% -----------------------------------------------------------------
handle(40113, PlayerStatus, _) ->  
	GuildIdSelf = PlayerStatus#player_status.guild#status_guild.guild_id, 
	%%获取今日召唤次数
	DailyGuildId = 4000000 + GuildIdSelf,
	CallTime = mod_daily_dict:get_count(DailyGuildId, 4007804),
	{Res, Time} = case CallTime > 0 of
		true ->
%% 			io:format("CallTime ~p~n", [CallTime]),
			{1, CallTime};
		false ->
			{0, 0}
	end,
	{ok, BinData} = pt_401:write(40113, [Res, Time]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	{ok, PlayerStatus};

%% %% -----------------------------------------------------------------
%% %% 查看答谢信息 已经废弃
%% %% -----------------------------------------------------------------
handle(40114, PlayerStatus, check_thank_gift) ->  
	PID = PlayerStatus#player_status.id,
	%% 还未处理数据,只是临时发送消息
    {ok, BinData} = pt_401:write(40114, [PID, "TEST1", 1, 1000]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	{ok, PlayerStatus};

%% -----------------------------------------------------------------
%% 升级宴会
%% -----------------------------------------------------------------
handle(40116, PlayerStatus, _) ->
	GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
	case mod_disperse:call_to_unite(lib_guild_base, get_guild, [GuildId]) of
		[] -> skip;
		Guild ->
			{ErrorCode, PlayerStatus2} = lib_guild_scene:upgrade_guild_party(PlayerStatus,Guild),
			{ok, BinData} = pt_401:write(40116, [ErrorCode]),
			lib_server_send:send_one(PlayerStatus2#player_status.socket, BinData),
			{ok, PlayerStatus2}
	end;

%% -----------------------------------------------------------------
%% 查看帮派神兽基本信息
%% -----------------------------------------------------------------
handle(40120, PlayerStatus, [GuildId]) ->  
	GuildIdSelf = PlayerStatus#player_status.guild#status_guild.guild_id,
	case GuildId =:= GuildIdSelf andalso GuildIdSelf > 0 of
		true ->
			[_, GA_Level, GA_Exp] = mod_disperse:call_to_unite(gen_server, call, [mod_guild, {get_guild_godanimal, [GuildId]}]),
			{_, Exp_Needed, _MId, CostCoin, _, _} = data_guild:get_guild_godanimal_info(GA_Level),
			{MId, _} = data_guild:get_ga_mod_id(GA_Level),
			GoldCost = GA_Level * 10,
			{_, GiftList} = data_guild:get_ga_mod_id(GA_Level),
		    {ok, BinData} = pt_401:write(40120, [MId
												, GA_Level
												, GA_Exp
												, Exp_Needed
												, 3								%% 可以击杀的次数,暂时写死,之后日常
												, CostCoin
												, 0
												, GoldCost
												, GiftList]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
		false ->
			skip
	end,
	{ok, PlayerStatus};

%% -----------------------------------------------------------------
%% 帮派神兽升级(花费铜币召唤神兽)
%% -----------------------------------------------------------------
handle(40121, PlayerStatus, [GuildId, _Type, StartTime, HType]) ->  
	GuildIdSelf = PlayerStatus#player_status.guild#status_guild.guild_id,
	GuildIdSelfP = PlayerStatus#player_status.guild#status_guild.guild_position,
	{Res, Time, PlayerStatusNew} = case GuildId > 0 andalso GuildIdSelf =:= GuildId andalso GuildIdSelfP =< 2 of
									   true ->
										   %%获取今日召唤次数
										   DailyGuildId = 4000000 + GuildId,
										   DailyTimes = mod_daily_dict:get_count(DailyGuildId, 4007808),
										   case DailyTimes >= 1 of
											   true ->
												   CallTime = mod_daily_dict:get_count(DailyGuildId, 4007809),
												   case CallTime > 0 of
													   true ->
														   {8, CallTime, PlayerStatus};
													   false ->
														   {5, 0, PlayerStatus}
												   end;
											   false ->
												   NowTime  = util:unixtime(),
												   NowData = util:unixdate(),
												   StartAt = NowData + StartTime * 60 * 30,	%% 开始时间
												   case StartAt - NowTime > 60 of
													   false ->
														   {0, 0, PlayerStatus}; 
													   true ->
														   lib_guild_scene:guild_godanimal_battle_start(PlayerStatus, [GuildId, 1, StartTime, HType])
												   end
										   end;
									   false ->
										   {0, 0, PlayerStatus}
								   end,
%% 	io:format("StartTime ~p ~p", [Time, StartTime]),
    {ok, BinData} = pt_401:write(40121, [Res, Time]),
	lib_server_send:send_one(PlayerStatusNew#player_status.socket, BinData),
	{ok, PlayerStatusNew};

%% -----------------------------------------------------------------
%% 帮派神兽召唤时间查询
%% -----------------------------------------------------------------
handle(40122, PlayerStatus, _) ->  
	GuildIdSelf = PlayerStatus#player_status.guild#status_guild.guild_id, 
	%%获取今日召唤次数
	DailyGuildId = 4000000 + GuildIdSelf,
	DailyTimes = mod_daily_dict:get_count(DailyGuildId, 4007808),
	{Res, Time} = case DailyTimes >= 1 of
		true ->
			CallTime = mod_daily_dict:get_count(DailyGuildId, 4007809),
			case CallTime > 0 of
				true ->
					{1, CallTime};
				false ->
					{0, 0}
			end;
		false ->
			{2, 0}
	end,
	{ok, BinData} = pt_401:write(40122, [Res, Time]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	{ok, PlayerStatus};

%% -----------------------------------------------------------------
%% 获取神兽战剩余时间
%% -----------------------------------------------------------------
handle(40130, PlayerStatus, _) ->  
	GuildIdSelf = PlayerStatus#player_status.guild#status_guild.guild_id, 
	%%获取今日召唤次数
	DailyGuildId = 4000000 + GuildIdSelf,
	DailyTimes = mod_daily_dict:get_count(DailyGuildId, 4007808),
	{Res, Time} = case DailyTimes >= 1 of
		true ->
			CallTime = mod_daily_dict:get_count(DailyGuildId, 4007809),
			case CallTime > 0 of
				true ->
					NowTime  = util:unixtime(),
					NowData = util:unixdate(),
					EndAt = NowData + CallTime * 60 * 30 + 15 * 60, %% 开始时间
					{1, EndAt - NowTime};
				false ->
					{0, 0}
			end;
		false ->
			{0, 0}
	end,
	{ok, BinData} = pt_401:write(40130, [Res, Time]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	{ok, PlayerStatus};

handle(40132, PlayerStatus, [PackId]) -> 
	[Res, Dian] = case PackId > 10 orelse PackId < 1 of
		true ->
			[0, 0];
		false->
			lib_guild_scene:ga_roll_go(PlayerStatus, PackId)
	end,
%% 	io:format("Res ~p ~p ~n", [Res, Dian]),
	{ok, BinData} = pt_401:write(40132, [Res, PackId, Dian]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	ok;

handle(40127, PlayerStatus, _) ->  
	%% 不处理发送来的信息
	GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
	List = mod_disperse:call_to_unite(gen_server, call, [mod_guild, {get_guild_ga_event, [GuildId]}]),
	{ok, BinData} = pt_401:write(40127, [List]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	{ok, PlayerStatus};

%% -----------------------------------------------------------------
%% 帮派场景退出
%% -----------------------------------------------------------------
handle(40198, PlayerStatus, _) ->  
	{SceneId, OutSceneId, X, Y} = data_guild:get_guild_scene_out(),
	case PlayerStatus#player_status.scene =:= SceneId of
		false ->
			PlayerStatus;
		true ->
			lib_scene:player_change_scene(PlayerStatus#player_status.id, OutSceneId, 0, X, Y,true),
			GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,		    		
			PartyName = ?GUILD_PARTYL ++ integer_to_list(GuildId),				
			case misc:whereis_name(global,PartyName) of
				undefined ->					
					skip;
				Pid when is_pid(Pid) ->
					NowTime  = util:unixtime(),
					Start_time = lib_guild_scene:get_part_start_time([GuildId]),
					case NowTime >= Start_time of
						true ->
							%% ========== 玩家帮宴中途退出，减少气氛值 start
							{MoodAdd, _NumLimit, _EfType} = data_guild:get_party_good_ef(0),
							Name = PlayerStatus#player_status.nickname,
							NowMood = lib_guild_scene:get_part_mood([GuildId]),
							%% 判断气氛值满,满了退出不减气氛值
							case NowMood >=1000	of
								true -> MoodAdd2 = 0;									
								false -> MoodAdd2 = -MoodAdd
							end,
							lib_guild_scene:add_part_mood([6, PlayerStatus#player_status.id, PlayerStatus#player_status.lv, Name, GuildId, MoodAdd2, 0]);							
							%% =================================== end
						false ->
							skip
					end;			
				_ ->
					skip
			end
	end,
	%% 此协议无返回
	{ok, PlayerStatus};

%% -----------------------------------------------------------------
%% 帮派神兽雕像怪物判断
%% -----------------------------------------------------------------
handle(40199, PlayerStatus, _) ->  
	GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
	case GuildId of
		0 ->
			skip;
		_ ->
			lib_guild_scene:guild_godanimal_sd(GuildId, 105)
	end,
	%% 此协议无返回
	{ok, PlayerStatus};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
handle(_Cmd, _Status, _Data) ->
    ?ERR("pp_guild_scene no match", []),
    {error, "pp_guild_scene no match"}.

%% ################宴会开始公告################
%% 发40000公告协议 类型:52
%% 
%% ################宴会过程记录待定################
%% 40000 
%% 
%% ################宴会结束################
%% 40000
%% (通知场景收起宴会相关物品_怪物)
%% 		发40000公告协议 类型:54

%% %% -----------------------------------------------------------------
%% %% 被使用宴会技能_单向
%% %% -----------------------------------------------------------------
%% write(40104, [Skill_Id, From_PlayerId]) ->
%%     {ok, pt:pack(40104, <<Skill_Id:32, From_PlayerId:32>>)};

%% ---------------------------E N D---------------------------------------------
