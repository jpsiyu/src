%% --------------------------------------------------------
%% @Module:           |lib_guild_scene
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-00-00
%% @Description:      |帮派业务_场景_业务处理  
%% --------------------------------------------------------

-module(lib_guild_scene).
-include("common.hrl").
-include("record.hrl").
-include("server.hrl").
-include("goods.hrl").
-include("guild.hrl").
-include("sql_guild.hrl").
-include("unite.hrl").
-include("scene.hrl").
-include("sql_player.hrl").

-export([
		 enter_guild_scene/2														%% 进入帮派场景
		, guild_party_food_creater/1												%% 创建帮派宴会_采集类怪物
 		, guild_party_food_opt/1													%% 帮派宴会_采集类怪物互动
		, get_guild_party_refresh/1													%% 刷新宴会信息
		, add_part_mood/1															%% 增加宴会气氛值
 		, get_guild_party_base_info/1												%% 获取帮派宴会基本信息
		, get_part_mood/1															%% 获取当前宴会的气氛值
		, get_part_start_time/1															%% 获取宴会开始时间
 		, start_one_guild_party/2													%% 召开帮派宴会
 		, guild_party_starting/1													%% 帮派宴会开始
		, get_guild_party_skill/1													%% 获取技能列表
 		, use_guild_party_skill/1													%% 使用帮派宴会技能
 		, accept_guild_party_skill/1												%% 被动_被使用帮派宴会技能
		, use_mood_goods/2														    %% 使用帮派气氛物品
		, guild_party_thank/3													%% 帮派宴会答谢
		, clear_food/2
		, guild_mon_dead/2
		, guild_godanimal_sd/2
 		, guild_party_over/1														%% 帮派宴会结束
		, send_mail_party/6														
		, guild_godanimal_call/1													%% 帮派神兽_妖兽召唤妖兽
		, guild_godanimal_send_rank/1												%% 帮派神兽_妖兽战斗排行榜信息						
		, guild_godanimal_exp_add/1													%% 帮派神兽_成长提升
]).
-compile(export_all).

%% -----------------------------------------------------------------
%% 进入帮派场景
%% -----------------------------------------------------------------
enter_guild_scene(PlayerStatus, Type) when is_record(PlayerStatus, player_status) ->
	%% 进入帮派场景
	GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
	%% 判断是否在神兽战斗中
	PartyName2 = ?GGATIMER ++ integer_to_list(GuildId),
	case misc:whereis_name(global, PartyName2) of
		Pid2 when is_pid(Pid2) ->
			%% 战斗已经在进行中 发送神兽战斗信息
			skip;
		_ ->
			%% 召唤妖兽
			skip
	end,
	%% 进入场景位置判断
	{SceneId, X, Y} = data_guild:get_guild_scene_info(Type),
	case lib_player:is_transferable(PlayerStatus) of
		false ->
			PlayerStatus;
		true ->
			Pk = PlayerStatus#player_status.pk,
			{IsOk, PlayerStatusPk} = case Pk#status_pk.pk_status =:= 0 orelse Pk#status_pk.pk_status =:= 3 of
				true ->
					{ok, PlayerStatus};
				false ->
					case lib_player:change_pkstatus(PlayerStatus, 3) of
				        {ok, _ErrCode, _Type, _LeftTime, PSPK} -> 
				            {ok, PSPK};
				        {error, _ErrCode, _Type, _LeftTime, _} -> 
				            {error, PlayerStatus}
				    end
			end,
			case IsOk =:= ok of
				true ->
					NewPlayerStatus = lib_scene:change_scene(PlayerStatusPk,SceneId,GuildId,X,Y,true),
					%% 是否在帮派宴会中
					PartyName = ?GUILD_PARTYL ++ integer_to_list(GuildId),				
					case misc:whereis_name(global,PartyName) of
						undefined ->					
							skip;
						Pid when is_pid(Pid) ->					
							NowTime  = util:unixtime(),
							Start_time = get_part_start_time([GuildId]),
							%% ========== 玩家进入帮宴增加气氛值 start
							{MoodAdd, _NumLimit, _EfType} = data_guild:get_party_good_ef(0),
							Name = NewPlayerStatus#player_status.nickname,
							case NowTime >= Start_time of
								true ->
									add_part_mood([5, NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.lv, Name, GuildId, MoodAdd, 0]);
								false ->
									    case  (Start_time - NowTime =< 30) of
											true ->
												add_part_mood([5, NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.lv, Name, GuildId, 0, 0]);
											false ->
												skip
										end								
							end;
						_ ->
							skip
					end,
					{ok, NewPlayerStatus};
				_ ->
					PlayerStatusPk
			end
	end.

%% *****************************************************************************
%% 			　　帮派场景内活动__帮派宴会相关
%% *****************************************************************************

%% -----------------------------------------------------------------
%% 享用帮派食物_给怪物处理那边调用
%% -----------------------------------------------------------------
guild_party_food_opt(_Player_status) ->
	%%暂时未定义
	skip.
	
%% -----------------------------------------------------------------
%% 获取帮派宴会基本信息
%% -----------------------------------------------------------------
get_guild_party_base_info(_Player_status) ->
	skip.

%% -----------------------------------------------------------------
%% 帮派宴会_定时刷新_气氛值,经验,消息
%% -----------------------------------------------------------------
get_guild_party_refresh([GuildId, Time_Left, Mood, InfoType, Uid, _Lv_t, Info, Type, Upgrader]) ->
	Users_Here = lib_scene:get_scene_user_field(?GUILD_SCENE, GuildId, pid),
    Num =length(Users_Here),
	%%　修正场景人数
	case Num=:=0 of
		true -> JoinNum =1;
	    false -> JoinNum = Num
	end,
	case InfoType =:= 3 of
		true ->
			lists:foreach(fun(U_Pid) ->
								  gen_server:cast(U_Pid, {'guild_party_add', Type, Mood})
						  end, Users_Here);
		false ->
			skip
	end,	
	lists:foreach(fun(U_Pid) ->
						 gen_server:cast(U_Pid, {'guild_party_exp', Type, Time_Left, Mood, InfoType, Info, JoinNum, Upgrader})
						  end, Users_Here),
	%% 帮宴期间玩家进入场景特殊处理
	 case Uid =/= 0 of
		true ->									
			case misc:get_player_process(Uid) of
				Pid when is_pid(Pid) ->			
					case misc:is_process_alive(Pid) of 
						true ->
							gen_server:cast(Pid, {'guild_party_exp', Type, Time_Left, Mood, InfoType, Info, JoinNum, Upgrader});							
						false -> skip
					end;		
				_ ->
					skip
			end;			
		false ->
			skip
	end.

%% -----------------------------------------------------------------
%% 召开帮派宴会_召开不是开始
%% -----------------------------------------------------------------
start_one_guild_party(PlayerStatus, [Guild, SponsorId, SponsorName, SponsorImage, SponsorSex, SponsorVoc, PartyType, StartTime]) ->
	GuildId = Guild#ets_guild.id,
	PlayerScene = PlayerStatus#player_status.scene,
	PlayerCopyId = PlayerStatus#player_status.copy_id,
	{PartyCheck, GACheck} = check_can_start(GuildId, StartTime),
	case PartyCheck =:= true andalso GACheck =:= true andalso PlayerScene =:= ?GUILD_SCENE andalso PlayerCopyId =:= GuildId of
		true ->
			NowTime  = util:unixtime(),
			NowData = util:unixdate(),
			Start_At = NowData + StartTime * 30 * 60,
			DailyGuildId = 4000000 + GuildId,
			DailySS = mod_daily_dict:get_count(DailyGuildId, 4007804),
			case DailySS > 0 of
				true->
					{3, PlayerStatus};
				false ->
					case PartyType >3 orelse PartyType < 1 of
						true ->
							{2, PlayerStatus};
						false ->
							case StartTime > 48 of
								true->
									{0, PlayerStatus};
								false ->%% 
									case Start_At =< NowTime + 5 * 60 of	
										true ->
											%% 准备时间不够1小时,无法召开宴会
											{6, PlayerStatus};
										false ->
											{Fouds, Gold, Coins} = data_guild:get_party_cost(PartyType),											
											case lib_goods_util:is_enough_money(PlayerStatus, Gold, gold) of
											 	true ->
												 	case lib_goods_util:is_enough_money(PlayerStatus, Coins, coin) of
													 	true ->	
															%% 扣除帮派财富															
															case  mod_disperse:call_to_unite(lib_guild_base, get_guild_member_by_player_id, [PlayerStatus#player_status.id]) of
																GuildMember when is_record(GuildMember, ets_guild_member) ->																										
																	Material = GuildMember#ets_guild_member.material,																	
																	case  Material>=  Fouds of
																		true ->
																			mod_disperse:call_to_unite(lib_guild_base, update_guild_member, [GuildMember#ets_guild_member{material = Material- Fouds}]),
																			StatusCostOk1 = lib_goods_util:cost_money(PlayerStatus, Coins, coin),
																			StatusCostOk2 = lib_goods_util:cost_money(StatusCostOk1, Gold, gold),
																			lib_player:refresh_client(StatusCostOk2#player_status.id, 1), %% 更新背包
																			log:log_consume(guild_party, coin, PlayerStatus, StatusCostOk1, ["guild party"]), 
																			log:log_consume(guild_party, gold, StatusCostOk1, StatusCostOk2, ["guild party"]),
																			%% 启动帮派宴会服务
																			Start_After = Start_At - NowTime,
																			Db_flag = 0,
																			mod_daily_dict:set_count(DailyGuildId, 4007804, StartTime),
																			mod_party_timer:start_link([Start_After, [GuildId
																						, Guild#ets_guild.name
																						, SponsorId
																						, SponsorName
																						, SponsorImage
																						, SponsorSex
																						, SponsorVoc
																						, PartyType
																						, Db_flag]]),																			
																			%% 广播给帮派成员
																			mod_disperse:cast_to_unite(lib_guild, send_guild, [GuildId, guild_party_will_start, [SponsorId, SponsorName, PartyType, StartTime]]),
																			mod_disperse:cast_to_unite(lib_guild_scene, send_mail_party, [GuildId, SponsorId, SponsorName, StartTime, PartyType,1]),
																			{1, StatusCostOk2};
																		false ->
																			{2, PlayerStatus}
															end;	
																_ -> {0, PlayerStatus}
															end;																														
													 	false ->
														 	{8, PlayerStatus}
												 	end;
											 	false ->
												 	{7, PlayerStatus}
										 	end
									end
							end
					end
			end;
		false ->
			{9, PlayerStatus}
	end.

%% -----------------------------------------------------------------
%% 升级帮派宴会
%% -----------------------------------------------------------------
upgrade_guild_party(PlayerStatus,Guild) ->
	GuildId = Guild#ets_guild.id,
	PartyName = ?GUILD_PARTYL ++ integer_to_list(GuildId),
	case misc:whereis_name(global, PartyName) of
		undefined -> %% 帮宴未开始
			{2,PlayerStatus}; 
		Pid when is_pid(Pid) ->
			Type = gen_fsm:sync_send_all_state_event(Pid, get_party_type),
			case Type>=3 of %% 已经是最高级
				true -> {3,PlayerStatus}; 
				false -> 
					Gold = data_guild:get_upgrade_party_cost(Type+1), 
					case lib_goods_util:is_enough_money(PlayerStatus, Gold, gold) of
						true ->						
							PlayerStatus2 = lib_goods_util:cost_money(PlayerStatus, Gold, gold),
							lib_player:refresh_client(PlayerStatus2#player_status.id, 2), %% 更新背包
							log:log_consume(guild_party, gold, PlayerStatus, PlayerStatus2, ["upgrade guild party"]),
							case gen_fsm:sync_send_all_state_event(Pid, {upgrade_guild_party, PlayerStatus2#player_status.id,
										PlayerStatus2#player_status.nickname}) of
								ok ->
									mod_disperse:cast_to_unite(lib_guild_scene, send_mail_party, [GuildId, PlayerStatus2#player_status.id,
											PlayerStatus2#player_status.nickname, 0, Type+1,2]),
									{1,PlayerStatus2};
								_ -> %% 失败
									{0,PlayerStatus}
							end;
						%% 元宝不足
						false -> {4,PlayerStatus}
					end
			end
	end.	

%% -----------------------------------------------------------------
%% 开始帮派宴会
%% -----------------------------------------------------------------
guild_party_starting([GuildId, SponsorId, SponsorName, PartyType, StartTime]) ->
	NowData = util:unixdate(),
	Start_At = ((StartTime - NowData) div 60) div 30,	
	%% 广播给帮派成员
	mod_disperse:cast_to_unite(lib_guild, send_guild, [GuildId, guild_party_starting, [SponsorId, SponsorName, PartyType, Start_At]]).

%% -----------------------------------------------------------------
%% 帮派宴会食物刷新 
%% -----------------------------------------------------------------
guild_party_food_creater([GuildId, _, _, PartyType, _]) ->
	XY_List = data_guild:get_party_point(),
	SceneUser = lib_scene:get_scene_user_field(?GUILD_SCENE, GuildId, id),
	F = fun({X,Y}, Count) ->
			case PartyType of
				1 ->
                    MonId = lib_mon:sync_create_mon(10050, ?GUILD_SCENE, X, Y, 0, GuildId, 1, []),
					send_change_look(MonId, 10050, 0, SceneUser);
				2 ->
                    MonId = lib_mon:sync_create_mon(10051, ?GUILD_SCENE, X, Y, 0, GuildId, 1, []),
					send_change_look(MonId, 10051, 0, SceneUser);
				3 ->
					case (X =:= 28 andalso Y =:=97 ) orelse  (X =:= 40 andalso Y =:=84) of
						true -> 
                            MonId = lib_mon:sync_create_mon(10053, ?GUILD_SCENE, X, Y, 0, GuildId, 1, []),
							send_change_look(MonId, 10053, 0, SceneUser),
							Count+1;
						false ->
                            MonId = lib_mon:sync_create_mon(10052, ?GUILD_SCENE, X, Y, 0, GuildId, 1, []),
							send_change_look(MonId, 10052, 0, SceneUser),
							Count+1
					end					
			end
		end,
	lists:foldl(F, 0, XY_List),
	{ok, BinData} = pt_401:write(40109, []),
	lib_server_send:send_to_scene(?GUILD_SCENE, GuildId, BinData).	

%% 生成食物-内部函数
food_point_make(_, 0, PointOk) ->
	PointOk;
food_point_make(PointList, FoodNum, PointOk) ->
	TableNum = erlang:length(PointList),
	Num = util:rand(1, TableNum),
	Tuple = lists:nth(Num, PointList),
    PointListNext = lists:delete(Tuple, PointList),
	PointOkNext = case PointOk of
		[] ->
			[Tuple];
		_ ->
			lists:keystore(1, 999, PointOk, Tuple)
	end,
	FoodNumNext = FoodNum - 1,
	food_point_make(PointListNext, FoodNumNext, PointOkNext).


%% 发送食物变身.
%% MonId:怪物自增ID, MonMid:怪物类型ID.
%% ChangeType:0默认变身，1狂暴变身，2狂暴变身还原，3伪装变身，4伪装变身还原.
send_change_look(MonId, MonMid, ChangeType, RoleList) ->
	NewMon = data_mon:get(MonMid),
	case NewMon =:= [] of
	    true ->
	        skip;
	    false ->
			{ok, BinData} = pt_120:write(12085, [MonId, 
	                                     		 NewMon#ets_mon.icon,
	                                     		 111,0,0,
	                                     		 ChangeType,
	                                     		 NewMon#ets_mon.name
												 ]),
			[lib_player:rpc_cast_by_id(id, 
									   lib_server_send, 
									   send_to_uid, 
									   [id, BinData])
									  ||id<-RoleList]
	end.


%% -----------------------------------------------------------------
%% 获取帮派宴会技能 
%% -----------------------------------------------------------------
get_guild_party_skill(_Player_status) ->
	skip.

%% -----------------------------------------------------------------
%% 使用帮派宴会技能
%% -----------------------------------------------------------------
use_guild_party_skill(_Player_status)->
	skip.

%% -----------------------------------------------------------------
%% 被动_被使用帮派宴会技能
%% -----------------------------------------------------------------
accept_guild_party_skill(_Player_status) ->
	skip.


%% -----------------------------------------------------------------
%% 使用帮派宴会气氛物品
%% -----------------------------------------------------------------
use_mood_goods(Playerstatus, GoodsTypeId) ->
	GuildId = Playerstatus#player_status.guild#status_guild.guild_id,
	PartyName = ?GUILD_PARTYL ++ integer_to_list(GuildId),
	case misc:whereis_name(global, PartyName) of
		undefined ->
			{0, 0, 0, 0};
		Pid when is_pid(Pid) ->
			NowState = gen_fsm:sync_send_all_state_event(Pid, {get_now_State}),
			case NowState of
				{ok, waiting} ->
					PlayerGoods = Playerstatus#player_status.goods,
					{MoodAdd, NumLimit, _EfType} = data_guild:get_party_good_ef(GoodsTypeId),
					GoodsUsed = get_part_goods_use([GuildId, GoodsTypeId]),
					case GoodsUsed >= NumLimit of
						true ->%% 超过使用数量限制
							{2, 0, 0, 0};
						false ->
							MoodNow = get_part_mood([GuildId]),
							if 
								GoodsTypeId =:=412002  -> %% 传音物品特殊处理
									{1, GoodsTypeId, 0, MoodAdd};
								true ->
									case MoodNow >= 1000 of
										true -> %% 气氛值已经满了
											Name = Playerstatus#player_status.nickname,
											case gen_server:call(PlayerGoods#status_goods.goods_pid,{'delete_more', GoodsTypeId, 1}) of
												1 ->
													log:log_goods_use(Playerstatus#player_status.id, GoodsTypeId, 1),
													%% 扣除成功										
													add_part_mood([7, 0, 0, Name, GuildId, 0, GoodsTypeId]);
												_ -> %% 扣除失败											
													skip
											end,
											case GoodsTypeId =:=412001 of
												true -> NewType = util:rand(1, 3);
											    false -> NewType = 0
											end,
											{3, 0, NewType, 0};
										false ->
											case gen_server:call(PlayerGoods#status_goods.goods_pid,{'delete_more', GoodsTypeId, 1}) of
												1 ->
													log:log_goods_use(Playerstatus#player_status.id, GoodsTypeId, 1),
													%% 扣除成功										
													Name = Playerstatus#player_status.nickname,
													add_part_mood([1, 0, 0, Name, GuildId, MoodAdd, GoodsTypeId]),
													NewType = get_eff_type(GuildId, GoodsTypeId),
													%% 广播给场景内的玩家
													{1, GoodsTypeId, NewType, MoodAdd};
												2 -> 
													{5, 0, 0, 0};
												3 ->
													%% 物品数量不足
													{5, 0, 0, 0};
												_Other ->
													%% 扣除失败
													{4, 0, 0, 0}
											end
									end
						  end
					end;
				_ ->
					{0, 0, 0, 0}
			end
	end.

%% 根据不同的物品ID产生不同的宴会效果
get_eff_type(GuildId, GoodsTypeId)->
	case GoodsTypeId of
		412001 -> %% 烟花
			util:rand(1, 3);
		412002 -> %% 传音
			0;
		412003 -> %% 舞女
			0;
		412004 -> %% 侍女
			GirlType = util:rand(1,6),
			start_refresh_girl(GuildId, GirlType),
			GirlType
	end.

%% 刷新侍女
start_refresh_girl(GuildId, GirlType)->
	PartyName = ?GUILD_PARTYL ++ integer_to_list(GuildId),
	case misc:whereis_name(global, PartyName) of
		undefined ->
			undefined;
		Pid when is_pid(Pid) ->
			gen_fsm:sync_send_all_state_event(Pid, {start_refresh_girl, GirlType})
	end.


%% -----------------------------------------------------------------
%% 宴会气氛增加
%% -----------------------------------------------------------------
add_part_mood([Type, Uid, Lv, Name, GuildId, MoodAdd, GoodsTypeId]) ->
	PartyName = ?GUILD_PARTYL ++ integer_to_list(GuildId),
	case misc:whereis_name(global, PartyName) of
		undefined ->
			undefined;
		Pid when is_pid(Pid) ->
			gen_fsm:sync_send_all_state_event(Pid, {add_mood, Type, Uid, Lv, Name, MoodAdd, GoodsTypeId})
	end.

%% -----------------------------------------------------------------
%% 获取当前宴会气氛
%% -----------------------------------------------------------------
get_part_mood([GuildId]) ->
	PartyName = ?GUILD_PARTYL ++ integer_to_list(GuildId),
	case misc:whereis_name(global, PartyName) of
		undefined ->
			undefined;
		Pid when is_pid(Pid) ->
			gen_fsm:sync_send_all_state_event(Pid, get_mood)
	end.


%% -----------------------------------------------------------------
%% 获取宴会开始时间
%% -----------------------------------------------------------------
get_part_start_time([GuildId]) ->
	PartyName = ?GUILD_PARTYL ++ integer_to_list(GuildId),
	case misc:whereis_name(global, PartyName) of
		undefined ->
			undefined;
		Pid when is_pid(Pid) ->
			gen_fsm:sync_send_all_state_event(Pid, get_start_time)
	end.


%% -----------------------------------------------------------------
%% 获取当前宴会物品使用数量
%% -----------------------------------------------------------------
get_part_goods_use([GuildId, GoodsTypeId]) ->
	PartyName = ?GUILD_PARTYL ++ integer_to_list(GuildId),
	case misc:whereis_name(global, PartyName) of
		undefined ->
			undefined;
		Pid when is_pid(Pid) ->
			gen_fsm:sync_send_all_state_event(Pid, {get_goods_use, GoodsTypeId})
	end.

%% -----------------------------------------------------------------
%% 帮派宴会答谢
%% -----------------------------------------------------------------
guild_party_thank(GuildId, Type, TargetPlayerId) ->
	case Type>1 of
		true ->
			User_lv = lib_scene:get_scene_user_field(?GUILD_SCENE, GuildId, lv),
			User_lv2 = lists:sublist(User_lv, 1, 20),
			LLPT = calculate_thank_llpt(Type, User_lv2),
			case ets:lookup(?ETS_ONLINE, TargetPlayerId) of
				[] -> 0;
				[R] ->
					%% 发送历练答谢
					gen_server:cast(R#ets_online.pid, {'guild_party_thank', [length(User_lv), Type, LLPT, GuildId]}),												
					1
			end;
		false -> skip
	end.

%% 计算仙宴举办人可获得的历练
calculate_thank_llpt(Type, UserLv) ->	
	F = fun(Lv, Total) ->
			[_Coin, LLPT] = 
			case Type of
				1 ->
					%% 答谢_增加历练
					ADDllpt = (100 - (10 - Lv * 0.1) * (10 - Lv * 0.1)) * 7.2,
					[0, round(ADDllpt)];
				2 ->
					%% 答谢_赠送历练2
					ADDllpt = (100 - (10 - Lv * 0.1) * (10 - Lv * 0.1)) * 7.2,
					[0, round(ADDllpt)];
				3 ->
					%% 答谢_赠送历练3
					ADDllpt = (100 - (10 - Lv * 0.1) * (10 - Lv * 0.1)) * 7.2,
					[0, round(ADDllpt)]
			end,
			Total + LLPT
		end,
	lists:foldl(F, 0, UserLv).
	
%% -----------------------------------------------------------------
%% 清除帮宴食物
%% -----------------------------------------------------------------
clear_food(GuildId, PartyType) ->
	MonTypeId = data_guild:get_party_food_mid(PartyType),
    case MonTypeId of
		{MonTypeId0} -> 
            lib_mon:clear_scene_mon_by_mids(?GUILD_SCENE, GuildId, 1, [MonTypeId0]);
		{MonTypeId1, MonTypeId2} ->
			lib_mon:clear_scene_mon_by_mids(?GUILD_SCENE, GuildId, 1, [MonTypeId1, MonTypeId2])
	end.
	
%% -----------------------------------------------------------------
%% 帮宴邮件服务_本功能在公共线
%% @param IsUpgrade 是否帮宴升级 1 否| 2 是
%% -----------------------------------------------------------------
send_mail_party(GuildId, SelfId, SelfName, StartTime, PartyType, IsUpgrade) ->
	case GuildId =:= 0 of
		true->
			[];
		false->
			{GiftId, TxtType, GiftId2, Num} = case PartyType of
						 3 ->
							 {532234, ga_party_mail_3, 532231, 1};
						 2 ->
							 {532233, ga_party_mail_2, 0, 0};
						 1 ->
							 {532232, ga_party_mail_1, 0, 0};
						 _ ->
							 {0, 0}
			end,
			[Title, Format, Title2, Content2] = data_guild_text:get_mail_text(TxtType),
			case IsUpgrade of
				1 ->
					NameList = get_member_name_list(GuildId),	
					StartTime1 = StartTime div 2,
					StartTime2 = case StartTime rem 2 of
									 0 ->
										 0;
									 1 ->
										 30
								 end,
					Content = io_lib:format(Format, [SelfName, StartTime1, StartTime2]),
					%% 发送通知邮件所有人
					lib_mail:send_sys_mail_bg(NameList, 
						Title,
						Content,
						GiftId2, 
						2, 0, 0, Num, 0, 0, 0, 0),
					%% 类型2以上,发送通知邮件(召开人)
					case PartyType> 1 of
						true ->
							lib_mail:send_sys_mail_bg([SelfId], 
								Title2,
								Content2, 
								GiftId, 
								2, 0, 0, 1, 0, 0, 0, 0);
						false -> skip
					end;
				2 ->
					%% 类型2以上,发送通知邮件(召开人)
					case PartyType> 1 of
						true ->
							lib_mail:send_sys_mail_bg([SelfId], 
								Title2,
								Content2, 
								GiftId, 
								2, 0, 0, 1, 0, 0, 0, 0);
						false -> skip
					end;
				_ -> skip
			end
	end.
	
%% 私有_邮件服务 
get_member_name_list(GuildId) ->
    MemberList = lib_guild_base:get_guild_member_by_guild_id(GuildId),
    get_member_name_list_helper(MemberList, []).
get_member_name_list_helper([], NameList) ->
    NameList;
get_member_name_list_helper(MemberList, NameList) ->
    [Member|MemberLeft] = MemberList,
    get_member_name_list_helper(MemberLeft, NameList++[Member#ets_guild_member.name]).

%% -----------------------------------------------------------------
%% 帮派宴会结束
%% -----------------------------------------------------------------
guild_party_over([GuildId, PartyType, SponsorId]) ->
	clear_food(GuildId, PartyType),
	%% 给予举办人/升级人-历练奖励
	guild_party_thank(GuildId, PartyType, SponsorId),
	%% 对场景内的人广播_帮派宴会结束信息
	{ok, BinData} = pt_401:write(40112, []),	
	mod_disperse:cast_to_unite(lib_unite_send, send_to_guild, [GuildId, BinData]).

%% *****************************************************************************
%% 			　　帮派场景内活动__帮派神兽相关
%% *****************************************************************************

%% -----------------------------------------------------------------
%% 帮派神兽 刷新 神雕
%% -----------------------------------------------------------------
guild_godanimal_sd(GuildId, _SceneId)->
	%% 获取帮派神兽等级
	[_, GA_Level, _] = mod_disperse:call_to_unite(gen_server, call, [mod_guild, {get_guild_godanimal, [GuildId]}]),
	{MId, _} = data_guild:get_ga_mod_id(GA_Level),
    lib_mon:clear_scene_mon_by_mids(?GUILD_SCENE, GuildId, 1, [MId]),
	{ScenseID, X, Y} = {?GUILD_SCENE, 89, 25},
    lib_mon:sync_create_mon(MId, ScenseID, X, Y, 0, GuildId, 1, []).
	
	
%% -----------------------------------------------------------------
%% 帮派神兽_妖兽_升级/剿灭判断
%% -----------------------------------------------------------------
guild_godanimal_battle_start(PlayerStatus, [GuildId, Type, StartTime, HType]) ->
	PlayerScene = PlayerStatus#player_status.scene,
	PlayerCopyId = PlayerStatus#player_status.copy_id,
	{PartyCheck, GACheck} = check_can_start(GuildId, StartTime),
	case PartyCheck =:= true andalso GACheck =:= true andalso PlayerScene =:= ?GUILD_SCENE andalso PlayerCopyId =:= GuildId of
		true -> 
			[_, GA_Level, _GAExp] = mod_disperse:call_to_unite(gen_server, call, [mod_guild, {get_guild_godanimal, [GuildId]}]),
			{_, _ExpNeeded, _, _FundsCost, _, _} = data_guild:get_guild_godanimal_info(GA_Level),
			case GA_Level < 40 andalso HType > 0 of
				true ->
					{9, 0, PlayerStatus};
				false ->
					{Is_All_Pass, _,  PlayerStatusNew} = case Type of
						1 ->%%
							DailyGuildId = 4000000 + GuildId,
							mod_daily_dict:set_count(DailyGuildId, 4007808, 1),
							mod_daily_dict:set_count(DailyGuildId, 4007809, StartTime),
							{1, 0, PlayerStatus};
						2 ->
							%% 
							{0, 0, PlayerStatus}
					end,
					Res = case Is_All_Pass of
						1 ->	
							%% 启动神兽进程
							mod_guild_godanimal_timer:start_link([GA_Level, StartTime, GuildId, HType]),
							%% 通知帮派成员
							mod_disperse:cast_to_unite(lib_guild, send_guild, [GuildId, guild_godanimal_call, [1, StartTime]]),							
							mod_disperse:cast_to_unite(lib_guild_scene, send_mail_ga_animal, [GuildId, StartTime]),
							1;
						_ ->
							Is_All_Pass
					end,
					{Res, StartTime, PlayerStatusNew}
			end;
		false ->
			{2, 0, PlayerStatus}
	end.

send_mail_ga_animal(GuildId, StartTime) ->
	StartTime1 = StartTime div 2,
	StartTime2 = case StartTime rem 2 of
		0 -> 0;
		1 -> 30
	end,
	NameList = get_member_name_list(GuildId),
	[Title, Content] = data_guild_text:get_mail_text(ga_animal_booking),
	Content2 = io_lib:format(Content, [StartTime1, StartTime2]),
	lib_mail:send_sys_mail_bg(NameList,Title,Content2,0,0, 0, 0, 0, 0, 0, 0, 0).

%% -----------------------------------------------------------------
%% 帮派神兽_妖兽_召唤妖兽
%% -----------------------------------------------------------------
guild_godanimal_call([GuildId, GA_Level]) ->
	{_, _, MId, _, _, _} = data_guild:get_guild_godanimal_info(GA_Level),
	{ScenseID, X, Y} = {?GUILD_SCENE, 70, 46},
    lib_mon:sync_create_mon(MId, ScenseID, X, Y, 0, GuildId, 1, []).

%% -----------------------------------------------------------------
%% 帮派神兽_妖兽_召唤妖兽_英雄模式
%% -----------------------------------------------------------------
guild_godanimal_call_h([GuildId, GALevel, _CallLevel]) ->
	{ScenseID, X, Y} = {?GUILD_SCENE, 70, 46},
	%% 召唤金角大王
    lib_mon:sync_create_mon(10604, ScenseID, X, Y, 0, GuildId, 1, [{auto_lv, GALevel}]).

%% 召唤通报小兵
guild_call_tbxb([GuildId, GALevel]) ->
	{ScenseID, X, Y} = {?GUILD_SCENE, 64, 41},
    Mid = lib_mon:sync_create_mon(10606, ScenseID, X, Y, 0, GuildId, 1, [{auto_lv, GALevel}]),
	{1, Mid}.

%% 召唤银角大王
guild_call_yjdw([GuildId, GALevel]) ->
	{ScenseID, X, Y} = {?GUILD_SCENE, 70, 46},
	Mid = lib_mon:sync_create_mon(10605, ScenseID, X, Y, 1, GuildId, 1, [{auto_lv, GALevel}, {auto_att, 0}]),
	{2, Mid}.

%% 召唤精英小怪
guild_call_jyxg([GuildId, GALevel]) ->
	{ScenseID, X, Y} = {?GUILD_SCENE, 70, 46},
	MId1 = lib_mon:sync_create_mon(40202, ScenseID, X + 1, Y, 1, GuildId, 1, [{auto_lv, GALevel}, {auto_att, 0}]),
	MId2 = lib_mon:sync_create_mon(40203, ScenseID, X + 2, Y, 1, GuildId, 1, [{auto_lv, GALevel}, {auto_att, 0}]),
	MId3 = lib_mon:sync_create_mon(40204, ScenseID, X + 3, Y, 1, GuildId, 1, [{auto_lv, GALevel}, {auto_att, 0}]),
	MId4 = lib_mon:sync_create_mon(40205, ScenseID, X + 4, Y, 1, GuildId, 1, [{auto_lv, GALevel}, {auto_att, 0}]),
	MId5 = lib_mon:sync_create_mon(40206, ScenseID, X + 5, Y, 1, GuildId, 1, [{auto_lv, GALevel}, {auto_att, 0}]),
	{3, [MId1, MId2, MId3, MId4, MId5]}.

%% 召唤唐僧师徒
guild_call_tsst([GuildId, GALevel, StartAt, NowTime, HpLim, HpNow, TsstIdOld]) ->
	{ScenseID, X, Y} = {?GUILD_SCENE, 65, 55},
	[MId1old, MId2old, MId3old, MId4old] = case TsstIdOld of
											   undefined ->
												   [0,0,0,0];
											   R ->
												   R
										   end,
	HpP = round((HpNow * 100) / HpLim),
	[MId1, MId2, MId3, MId4] = if
		NowTime - StartAt > 60 andalso HpP > 93 andalso MId1old == 0 ->
			Ls1 = lib_mon:sync_create_mon(10610, ScenseID, X, Y, 1, GuildId, 1, [{auto_lv, GALevel}, {auto_att, 0}]),
			[Ls1, MId2old, MId3old, MId4old];
		NowTime - StartAt > 5 * 60 andalso HpP > 67 andalso MId2old == 0 ->
			Ls2 = lib_mon:sync_create_mon(10609, ScenseID, X, Y, 1, GuildId, 1, [{auto_lv, GALevel}, {auto_att, 0}]),
			[MId1old, Ls2, MId3old, MId4old];
		NowTime - StartAt > 9 * 60 andalso HpP > 41 andalso MId3old == 0 ->
			Ls3 = lib_mon:sync_create_mon(10608, ScenseID, X, Y, 1, GuildId, 1, [{auto_lv, GALevel}, {auto_att, 0}]),
			[MId1old, MId2old, Ls3, MId4old];
		NowTime - StartAt > 14 * 60 andalso HpP > 8 andalso MId4old == 0 ->
			Ls4 = lib_mon:sync_create_mon(10607, ScenseID, X, Y, 1, GuildId, 1, [{auto_lv, GALevel}, {auto_att, 0}]),
			[MId1old, MId2old, MId3old, Ls4];
		true ->
			[MId1old, MId2old, MId3old, MId4old]
	end,
	[MId1, MId2, MId3, MId4].

%% 帮派神兽成长
guild_godanimal_exp_add([RoldID, SelfName, TaskId, TaskColor, GuildId, GuildMoney]) ->
	[_, GALevel, _GAExp] = mod_disperse:call_to_unite(gen_server, call, [mod_guild, {get_guild_godanimal, [GuildId]}]),
	%% 神兽等级,	成长度,	怪物ID,	升级所需铜币
	{_, _ExpNeeded, _MId, _, _, _} = data_guild:get_guild_godanimal_info(GALevel),
	GAEvent = mod_disperse:call_to_unite(gen_server, call, [mod_guild, {get_guild_ga_event, [GuildId]}]),
	NewGAEvent = case GAEvent of
		[] ->
			[[RoldID, TaskId, TaskColor, GuildMoney]];
		_ ->
			case erlang:length(GAEvent) >= 4 of
				true ->
					[H1|T1] = GAEvent,
					[H2|T2] = T1,
					[H3|_] = T2,
					[[RoldID, util:make_sure_list(SelfName), TaskId, TaskColor, GuildMoney], H1, H2, H3];
				false ->
					[[RoldID, util:make_sure_list(SelfName), TaskId, TaskColor, GuildMoney]|GAEvent]
			end
	end,
	mod_disperse:call_to_unite(gen_server, call, [mod_guild, {save_guild_ga_event, [GuildId, NewGAEvent]}]).

	
%% -----------------------------------------------------------------
%% 帮派神兽_妖兽战斗排行榜广播_只给造成了伤害的人广播 
%% -----------------------------------------------------------------
guild_godanimal_send_rank([_GuildId, GAId]) ->
    case lib_mon:get_scene_mon_by_ids(?GUILD_SCENE, [GAId], all) of
	   [GAMonEts] when is_record(GAMonEts, ets_mon)->
		   	Kinfo = lib_mon:klist(GAMonEts#ets_mon.aid),
			DamageList = [{RoleId, Damage}||{_Pid, Damage, RoleId} <- Kinfo],
			RankInfo = rank_damage(Kinfo),
			{ok, fighting, RankInfo, DamageList, GAMonEts#ets_mon.hp_lim, GAMonEts#ets_mon.hp};
	   [] ->
		   timer:sleep(1000),
		   case lib_mon:get_scene_mon_by_ids(?GUILD_SCENE, [GAId], all) of
			   [GAMonEts] when is_record(GAMonEts, ets_mon)->
				   	Kinfo = lib_mon:klist(GAMonEts#ets_mon.aid),
					DamageList = [{RoleId, Damage}||{_Pid, Damage, RoleId} <- Kinfo],
					RankInfo = rank_damage(Kinfo),
					{ok, fighting, RankInfo, DamageList, GAMonEts#ets_mon.hp_lim, GAMonEts#ets_mon.hp};
			   [] ->
				   	{ok, killed}
			end
	end.

%% 时间到
time_over_ga([GuildId, _GAId, GALevel, RankInfo, _WinerList]) ->
	{_, _, MId, _, _Prize1, _Prize23} = data_guild:get_guild_godanimal_info(GALevel),
	RankInfoLenght = erlang:length(RankInfo),
	case RankInfoLenght < 1 of
		true ->
			skip;
		false ->
			ExpAdd1 = erlang:round(GALevel * GALevel * 200 * 20 /RankInfoLenght),
			ExpAdd = case ExpAdd1 > erlang:round(GALevel * GALevel * 200 * 4) of
						 true ->
							 erlang:round(GALevel * GALevel * 200 * 4);
						 false ->
							 ExpAdd1
					 end,
			send_prize_lose(RankInfo, GALevel, ExpAdd)
	end,
	log_ga_battle(GuildId, GALevel, 0, []),
    lib_mon:clear_scene_mon_by_mids(?GUILD_SCENE, GuildId, 1, [MId]),
	{ok, BinData} = pt_401:write(40126, [0, GALevel, 0]),
	mod_disperse:cast_to_unite(lib_unite_send, send_to_guild, [GuildId, BinData]),
	ok.

%% 杀死了
ga_is_kill_ok([GuildId, _GAId, GALevel, RankInfo, _WinerList]) ->
	RankInfoLenght = erlang:length(RankInfo),
	case RankInfoLenght < 1 of
		true ->
			log_ga_battle(GuildId, GALevel, 2, []),
			{ok, BinData} = pt_401:write(40126, [0, GALevel, 0]),
			mod_disperse:cast_to_unite(lib_unite_send, send_to_guild, [GuildId, BinData]);
		false ->
			GALevelNew = case GALevel >= ?GodAnimal_Level_Limit of
							 true ->
								 ?GodAnimal_Level_Limit;
							 false ->
								 GALevel + 1
						 end,
			ExpAdd1 = erlang:round(GALevel * GALevel * 200 * 20 /RankInfoLenght),
			ExpAdd = case ExpAdd1 > erlang:round(GALevel * GALevel * 200 * 4) of
						 true ->
							 erlang:round(GALevel * GALevel * 200 * 4);
						 false ->
							 ExpAdd1
					 end,
			RankInfoLeft = send_win3(RankInfo, ExpAdd),
			send_prize_lose(RankInfoLeft, GALevel, ExpAdd),
			log_ga_battle(GuildId, GALevel, 1, RankInfo),
			case mod_disperse:call_to_unite(gen_server, call, [mod_guild, {guild_godanimal_win, [GuildId, GALevelNew, 0]}]) of
				true -> 
					{ok, BinData} = pt_401:write(40126, [1, GALevelNew, 0]),
					mod_disperse:cast_to_unite(lib_unite_send, send_to_guild, [GuildId, BinData]);
				false ->
					{ok, BinData} = pt_401:write(40126, [2, GALevelNew, 0]),
					mod_disperse:cast_to_unite(lib_unite_send, send_to_guild, [GuildId, BinData])
			end
	end,
	ok.

get_3_2(RankInfo) ->
	case RankInfo of
		[] ->
			[0, 0, 0, 0, 0, 0, RankInfo];
		_ ->
			[[_, RoleId01, Damage01, _]|RankInfoN1] = RankInfo,
			case RankInfoN1 of
				[] ->
					[RoleId01, 0, 0, Damage01, 0, 0, RankInfoN1];
				_ ->
					[[_, RoleId02, Damage02, _]|RankInfoN2] = RankInfoN1,
					case RankInfoN2 of
						[] ->
							[RoleId01, RoleId02, 0, Damage01, Damage02, 0, RankInfoN2];
						_ ->
							[[_, RoleId03, Damage03, _]|RankInfoN3] = RankInfoN2,
							[RoleId01, RoleId02, RoleId03, Damage01, Damage02, Damage03, RankInfoN3]
					end
			end
	end.

get_3(RankInfo) ->
	case RankInfo of
		[] ->
			[0, 0, 0];
		_ ->
			[[_, RoleId01, _, _]|RankInfoN1] = RankInfo,
			case RankInfoN1 of
				[] ->
					[RoleId01, 0, 0];
				_ ->
					[[_, RoleId02, _, _]|RankInfoN2] = RankInfoN1,
					case RankInfoN2 of
						[] ->
							[RoleId01, RoleId02, 0];
						_ ->
							[[_, RoleId03, _, _]|_RankInfoN3] = RankInfoN2,
							[RoleId01, RoleId02, RoleId03]
					end
			end
	end.
			 

log_ga_battle(GuildId, GALevel, Type, RankInfo) ->
	[Id1, Id2, Id3] = get_3(RankInfo),
	SQL = io_lib:format(?SQL_GUILD_GA_BATTLE, [GuildId, GALevel, Type, Id1, Id2, Id3]),
	db:execute(SQL).

send_win3(RankInfo, ExpAdd) ->
	[Id1, Id2, Id3, Damage01, Damage02, Damage03, RankInfoLeft] = get_3_2(RankInfo),
	lib_player:update_player_info(Id1, [{add_exp, erlang:round(ExpAdd * 3)}]),
	{ok, BinData1} = pt_401:write(40128, [erlang:round(ExpAdd * 3), Damage01, 1]),
	lib_server_send:send_to_uid(Id1, BinData1),
	lib_player:update_player_info(Id2, [{add_exp, erlang:round(ExpAdd * 2)}]),
	{ok, BinData2} = pt_401:write(40128, [erlang:round(ExpAdd * 2), Damage02, 2]),
	lib_server_send:send_to_uid(Id2, BinData2),
	lib_player:update_player_info(Id3, [{add_exp, erlang:round(ExpAdd * 1.5)}]),
	{ok, BinData3} = pt_401:write(40128, [erlang:round(ExpAdd * 1.5), Damage03, 3]),
	lib_server_send:send_to_uid(Id3, BinData3),
	RankInfoLeft.

%% 战斗失败的奖励
send_prize_lose([], _GALevel, _ExpAdd)->
	ok;
send_prize_lose(RankInfo, GALevel, ExpAdd)->
	[[_RanKNum, RoleId, Damage, _]|RankInfoN] = RankInfo,
	lib_player:update_player_info(RoleId, [{add_exp, ExpAdd}]),
	{ok, BinData} = pt_401:write(40128, [ExpAdd, Damage, 0]),
	lib_server_send:send_to_uid(RoleId, BinData),
	send_prize_lose(RankInfoN, GALevel, ExpAdd).


send_prize_win([], _, _, _, _ExpAdd) ->
	ok;
send_prize_win(RankInfo, Prize1, Prize23, GALevel, ExpAdd) ->
	[[RanKNum, RoleId, _Damage, _]|RankInfoN] = RankInfo,
	[TitleC, ContentC, GiftIdC] = case RanKNum of
		1 ->
			[Title, Format] = data_guild_text:get_mail_text(ga_top_1),
			Content = io_lib:format(Format, [GALevel]),
			[Title, Content, Prize1];
		2 ->
			[Title, Format] = data_guild_text:get_mail_text(ga_top_2),
			Content = io_lib:format(Format, [GALevel]),
			[Title, Content, Prize23];
		3 ->
			[Title, Format] = data_guild_text:get_mail_text(ga_top_3),
			Content = io_lib:format(Format, [GALevel]),
			[Title, Content, Prize23]
	end,
	mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, 
									   [[RoleId], 
										TitleC,
										ContentC, 
										GiftIdC, 
										2, 0, 0, 1, 0, 0, 0, 0]),
	lib_player:update_player_info(RoleId, [{add_exp, ExpAdd}]),
	{ok, BinData} = pt_401:write(40128, [ExpAdd, 0, 0]),
	lib_server_send:send_to_uid(RoleId, BinData),
	send_prize_win(RankInfoN, Prize1, Prize23, GALevel, ExpAdd).

%% send_rold_info([], _WinerList)-> 
%% 	ok;
%% send_rold_info(RankInfo, WinerList)->
%% 	[[_RanKNum, RoleId, _Damage, _]|RankInfoN] = RankInfo,
%% 	{ok, BinData} = pt_401:write(40133, [WinerList]),
%% 	lib_server_send:send_to_uid(RoleId, BinData),
%% 	send_rold_info(RankInfoN, WinerList).

%% send_prize_roll([]) ->
%% 	ok;
%% send_prize_roll(WinerList) ->
%% 	[[Num, Prize, SA3, _SB3, SC3]|WinerListN] = WinerList,
%% 	[Title, Format] = data_guild_text:get_mail_text(ga_roll_win),
%% 	Content = io_lib:format(Format, [SC3]),
%% 	mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, 
%% 									   [[SA3], 
%% 										Title,
%% 										Content, 
%% 										Prize, 
%% 										1, 0, 0, 1, 0, 0, 0, 0]),
%% 	
%% 	case SA3 =/= 0 andalso Num =:= 1 of
%% 		true ->
%% 			[IdT, RealmT, NicknameT, SexT, CareerT, IimageT] = lib_player:get_player_info(SA3, sendTv_Message),
%% 			lib_chat:send_TV({all},0, 2
%% 							,[killShenshou, IdT, RealmT, NicknameT, SexT, CareerT, IimageT, Prize]);
%% 		false ->
%% 			skip
%% 	end,
%% 	send_prize_roll(WinerListN).

rank_damage(Kinfo)->
	Klength = erlang:length(Kinfo),
	if
		Klength =:= 0 -> [];
		true ->
			NewK = lists:keysort(2, Kinfo),
			NewKSorted = NewK,
			DamageAll = rank_loop1(NewKSorted, 0),
			RankInfo = rank_loop2(NewKSorted, DamageAll, []),
			Date1 = case erlang:length(RankInfo) > 5 of
				false ->
					RankInfo;
				true ->
					{LR, _} = lists:split(5, RankInfo),
					LR
			end,
			rank_loop3(RankInfo, Date1),
			RankInfo
	end.

rank_loop1([], D) ->
	D;
rank_loop1(Kinfo, D) ->
	[{_Pid, Damage, _RoleId}|KinfoN] = Kinfo,
	DN = D + Damage,
	rank_loop1(KinfoN, DN).

rank_loop2([], _DamageAll, Dlist) ->
	Dlist;
rank_loop2(Kinfo, DamageAll, Dlist) ->
	[{_Pid, Damage, RoleId}|KinfoN] = Kinfo,
	RanKNum = erlang:length(Kinfo),
	DamageP = (Damage * 1000) div DamageAll,
	Dlist1 = [RanKNum, RoleId, Damage, DamageP],
	DlistN = [Dlist1|Dlist],
	rank_loop2(KinfoN, DamageAll, DlistN).

rank_loop3([], _Date1) ->
	ok;
rank_loop3(RankInfo, Date1) ->
	[[RanKNum, RoleId, Damage, DamageP]|RankInfoN] = RankInfo,
	Date = [RanKNum, Damage, DamageP, Date1],
	{ok, BinData} = pt_401:write(40124, Date),
	lib_server_send:send_to_uid(RoleId, BinData),
	rank_loop3(RankInfoN, Date1).

ga_roll_go(PS, PackId)->
	PartyName2 = ?GGATIMER ++ integer_to_list(PS#player_status.guild#status_guild.guild_id),
	case misc:whereis_name(global, PartyName2) of
		Pid2 when is_pid(Pid2) ->
			gen_fsm:sync_send_all_state_event(Pid2, {roll, PS#player_status.id, PS#player_status.nickname, PackId});
		_ ->
			[0, 0]
	end.

%% 帮派相关怪物死亡
guild_mon_dead(Mon, PS) ->
	MonTypeId = Mon#ets_mon.mid,
	MonBossType = Mon#ets_mon.boss,
	case MonBossType =:= 4 of
		true ->
			ga_be_killed(Mon, PS),
			1;
		false ->
			case lists:member(MonTypeId, [10606, 10605]) of
				true ->
					ga_xg_be_killed(Mon, PS),
					1;
				false ->
					case MonTypeId =:= 10050 orelse MonTypeId =:= 10051 orelse MonTypeId =:= 10052 orelse MonTypeId =:= 10053 of
						true ->
							case PS#player_status.id =:= 0 of
								true ->
									skip;
								false ->
									case MonTypeId of
										10050 -> Count = mod_daily_dict:get_count(PS#player_status.id, 4007810);
										10051 -> Count = mod_daily_dict:get_count(PS#player_status.id, 4007811);
										10052 -> Count = mod_daily_dict:get_count(PS#player_status.id, 4007812);
										10053 -> Count = mod_daily_dict:get_count(PS#player_status.id, 4007812)
									end,							
									case Count>= 20 of
										true ->
											{ok, BinData} = pt_401:write(40197, [1]),
											lib_server_send:send_to_uid(PS#player_status.id, BinData);
										false ->
											{ok, BinData} = pt_401:write(40197, [2]),
											lib_server_send:send_to_uid(PS#player_status.id, BinData),
											LBGOOD = PS#player_status.goods,
											GTypeId = case MonTypeId of
														  10050 -> 532236;
														  10051 -> 532237;
														  10052 -> 532238;
														  10053 -> 532238
													  end,
											%% 仙宴食物
											GiveList = [{GTypeId, 1}],  %% 绑定物品
											case gen_server:call(LBGOOD#status_goods.goods_pid, {'give_more_bind', [], GiveList}, 7000) of
								                ok ->
													%% 更新玩家信息---仙宴中吃食物数量
													case GTypeId of
														532236 -> mod_daily_dict:plus_count(PS#player_status.id, 4007810, 1);
														532237 -> mod_daily_dict:plus_count(PS#player_status.id, 4007811, 1);
														532238 -> mod_daily_dict:plus_count(PS#player_status.id, 4007812, 1)
													end,											
								                    ok;
								                _ -> %% 失败
								                    ok
								            end
									end
							end,
							1;
						false ->
							2
					end
			end
	end.

to_ga_info({killmon, AttId2}, GuildId) ->
	PartyName2 = ?GGATIMER ++ integer_to_list(GuildId),
	case misc:whereis_name(global, PartyName2) of
		Pid2 when is_pid(Pid2) ->
			case mod_disperse:call_to_unite(gen_server, call, [mod_guild, {get_guild_godanimal, [GuildId]}]) of
				[_, GALevel, _GAExp] ->
					{_, _, _MId, _, _Prize1, Prize23} = data_guild:get_guild_godanimal_info(GALevel),
					[Title, Format] = data_guild_text:get_mail_text(ga_top_last),
					Content = io_lib:format(Format, [GALevel]),
					mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, 
															   [[AttId2], 
																Title,
																Content, 
																Prize23, 
																2, 0, 0, 1, 0, 0, 0, 0]),
					1;
				_ ->
					1
			end;
		_ ->
			1
	end.

%% 帮派活动启动判断
%% @retrun {PartyCheck, GACheck} 宴会判定结果,神兽判定结果
check_can_start(GuildId, StartTime) ->
	DailyGuildId = 4000000 + GuildId,
	DailyTimeGp = mod_daily_dict:get_count(DailyGuildId, 4007804),
	DailyTimeGa = mod_daily_dict:get_count(DailyGuildId, 4007809),
	case StartTime =:= DailyTimeGp orelse StartTime =:= DailyTimeGa of
		true->
			{false, false};
		false->
			{true, true}
	end.
	
ga_be_killed(_Mon, PS) ->
	case PS#player_status.guild#status_guild.guild_id =:= 0 of
		true ->
			skip;
		false ->
			PartyName2 = ?GGATIMER ++ integer_to_list(PS#player_status.guild#status_guild.guild_id),
			case misc:whereis_name(global, PartyName2) of
				Pid2 when is_pid(Pid2) -> 
					gen_fsm:send_all_state_event(Pid2, {ga_killed, 0, PS#player_status.guild#status_guild.guild_id});
				_ ->
					skip
			end
	end.

ga_xg_be_killed(Mon, PS) ->
	MonTypeId = Mon#ets_mon.mid,
	MonId = Mon#ets_mon.id,
	case PS#player_status.guild#status_guild.guild_id =:= 0 of
		true ->
			skip;
		false ->
			PartyName2 = ?GGATIMER ++ integer_to_list(PS#player_status.guild#status_guild.guild_id),
			case misc:whereis_name(global, PartyName2) of
				Pid2 when is_pid(Pid2) -> 
					gen_fsm:send_all_state_event(Pid2, {ga_xg_killed, MonId, MonTypeId, PS#player_status.guild#status_guild.guild_id});
				_ ->
					skip
			end
	end. 
