%% --------------------------------------------------------
%% @Module:           |pp_appointment
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-04-10
%% @Description:      |仙侣奇缘处理
%% --------------------------------------------------------

-module(pp_appointment).
-export([handle/3]).
-include("common.hrl").
-include("scene.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("appointment.hrl").

%-------------------------------------------------------------------------------
%								仙侣情缘_流程类 
%-------------------------------------------------------------------------------

%% 请求三位异性玩家 - 公共线 
handle(27000, UniteStatus, [Type]) ->
	PlayerId = UniteStatus#unite_status.id,
	case lib_appointment:check_app(PlayerId) of
		[] ->%% 玩家已经离线或APP信息错误(这一步可不要)
			ok;
		Config ->
			%% 获取VIP信息
			case lib_player:get_player_info(PlayerId, vip_type) of
				VipInfo when erlang:is_record(VipInfo, status_vip) ->
					VipRe = mod_daily_dict:get_count(PlayerId, 2702),
					LeftRe = case VipInfo#status_vip.vip_type > 0 of
						true->
							3 - VipRe;
						false ->
							0
					end,
					%% 获取 => 异性 国家 等级
					Sex = 3 - UniteStatus#unite_status.sex,
					Realm = UniteStatus#unite_status.realm,
					Level = UniteStatus#unite_status.lv,
					NowTime = util:unixtime(),
					LeftTime = ?REFRESH_TIME - (NowTime - Config#ets_appointment_config.refresh_time),
					%% 刷新条件 判定/处理
					[Res, AppConfigInfo, ResTimeLeft, ResVipLeft] = case Type of
						0 -> %% 普通刷新,
							case LeftTime >= 0 of
								true -> %% 未到刷新时间_不刷新
									[2, Config, LeftTime, LeftRe];
								false -> 
									[1, Config#ets_appointment_config{refresh_time = NowTime}, ?REFRESH_TIME, LeftRe]
							end;
						1 -> %% 元宝刷新
							case LeftRe > 0 of %% vip有免费即时刷新
								true -> 
									mod_daily_dict:increment(UniteStatus#unite_status.id, 2702), %% 使用次数+1
									[1, Config#ets_appointment_config{refresh_time = NowTime}, ?REFRESH_TIME, LeftRe-1];
								false ->  %% VIP剩余次数为0 ,使用元宝刷新
									ServerPid = lib_player:get_pid_by_id(PlayerId),
									[Info_Text] = data_appointment_text:get_log_consume_text(xlqy_log, 0),
									case gen_server:call(ServerPid, {spend_assets, [PlayerId, 1, gold, xlqy_refresh, Info_Text]}) of
										{ok, ok} ->
											[1, Config#ets_appointment_config{refresh_time = NowTime}, ?REFRESH_TIME, LeftRe];
										{error, _IRes} ->
											%% 扣除元宝失败
											[4, Config, LeftTime, LeftRe]
									end
							end;
						 2 ->
							 ServerPid = lib_player:get_pid_by_id(PlayerId),
							 case lib_vip_info:get_growth_lv(PlayerId) of
								 TypeXR when erlang:is_integer(TypeXR) ->
									 case TypeXR >= 4 andalso VipInfo#status_vip.vip_type =:= 3 of
										 true ->
											 case lib_marriage:get_parner_id(PlayerId) of
												 ParnerId when is_integer(ParnerId) ->
													 case lib_appointment:check_unite_online(ParnerId) of
														 [] ->
															 [6, Config, LeftTime, LeftRe];
														 Player ->
															 case gen_server:call(ServerPid, {spend_assets, [PlayerId, 20, gold, xlqy_refresh, "XLQY_VIP_4"]}) of
																{ok, ok} ->
																	RVIP4 = [Player#ets_unite.id, Player#ets_unite.name, 6, 0],
																	[99, Config#ets_appointment_config{rand_ids = [RVIP4]}, ?REFRESH_TIME, LeftRe];
																{error, _IRes} ->
																	%% 扣除元宝失败
																	[2, Config, LeftTime, LeftRe]
															 end
													 end;
												 _ ->
													 [6, Config, LeftTime, LeftRe]
											 end;
										 _ ->
											 [5, Config, LeftTime, LeftRe]
									 end;
								 _ ->
									 [5, Config, LeftTime, LeftRe]
							 end
					end,
					%% 查找伴侣 ResEnd = 0 表示找不到玩家 1 成功刷新 2 元宝不足  5 => VIP等级不够 6 => 您的仙侣不在线
					[ResEnd, AppConfigEnd] = case Res of
						 1 ->
							 case lib_appointment:rand_partners(UniteStatus, Config, [Sex, Realm, Level]) of
								 [] ->
									 [0, AppConfigInfo#ets_appointment_config{rand_ids = []}];
								 L2 ->
							 		 [1, AppConfigInfo#ets_appointment_config{rand_ids = L2}]
							 end;
						 5 ->
							 [5, AppConfigInfo]; 
						 6 ->
							 [6, AppConfigInfo];
						 99 ->
							 [1, AppConfigInfo];
						 _ ->
							 case AppConfigInfo#ets_appointment_config.rand_ids =:= [] of
								 true ->
									 [0, AppConfigInfo];
								 false ->
									 [1, AppConfigInfo]
							 end
					end,
					%% 插入缓冲
					lib_appointment:update_appointment_config(AppConfigEnd, 0),
					%% 打包找到的玩家
					Pack_Info = lib_appointment:package_partner(AppConfigEnd#ets_appointment_config.rand_ids),
					{ok, BinData} = pt_270:write(27000, [ResEnd, Pack_Info, ResTimeLeft, ResVipLeft]),
					lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				_ ->
					ok
			end
	end;

%% 发送邀请给异性 - 公共线
handle(27001, UniteStatus, [PlayerId]) ->
    Res = case lib_appointment:check_unite_online(PlayerId) of
        [] -> [2, [], 0];
        TargetPlayer ->
%% 			io:format("TargetPlayer  ~p~n", [TargetPlayer#ets_unite.appointment]), 
            case TargetPlayer#ets_unite.appointment =:= 0 of
                true -> 
					case lib_appointment:check_unite_online(UniteStatus#unite_status.id) of
                        [] -> [0, [], 0];
                        SelfEU -> 
                            case SelfEU#ets_unite.appointment =:= 0 of
                                true -> 
									%% 双方都不在仙侣情缘状态 发送邀请
									case lib_player:get_player_info(SelfEU#ets_unite.id, goods) of
										LBGOOD when is_record(LBGOOD, status_goods) ->
											[E1, E2| _] = LBGOOD#status_goods.equip_current,
		                                    {ok, BinData} = pt_270:write(27002, [SelfEU#ets_unite.id
																				, SelfEU#ets_unite.name
																				, SelfEU#ets_unite.sex
																				, SelfEU#ets_unite.lv
																				, SelfEU#ets_unite.career
																				, SelfEU#ets_unite.realm
																				, E1
																				, E2]),
		                                    lib_unite_send:send_to_sid(TargetPlayer#ets_unite.sid, BinData),
											[1, TargetPlayer#ets_unite.name, TargetPlayer#ets_unite.id];
										_ ->
											[2, [], 0]
									end;
                                false -> [3, [], 0]
                            end
                    end;
                false -> [4, [], 0]
            end
    end,
    {ok, BinData2} = pt_270:write(27001, Res),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData2);

%% 收到邀请回应  - 公共线
handle(27003, UniteStatus, [FromPlayerId, Res]) ->
    [Res1, NickName] = 
	case lib_appointment:check_unite_online(FromPlayerId) of
        [] -> [2, []];
        FromPlayer ->
            case FromPlayer#ets_unite.appointment =:= 0 of
                true ->
                    case lib_appointment:check_unite_online(UniteStatus#unite_status.id) of
                        [] -> [0, []];
                        SelfEU -> 
                            case SelfEU#ets_unite.appointment =:= 0 of
                                true ->
                                    case Res of
                                        0 -> 
                                            {ok, BinData} = pt_270:write(27004, [SelfEU#ets_unite.id, SelfEU#ets_unite.name, Res]),
                                            lib_unite_send:send_to_uid(FromPlayerId, BinData),
                                            [1, FromPlayer#ets_unite.name];
                                        1 -> %% 获取自己今日接受的仙侣次数
                                            DailyCount = mod_daily_dict:get_count(UniteStatus#unite_status.id, 2700),
											case DailyCount < 2 of
                                                true -> %% 获取邀请方今日做过的仙侣次数
													FromPlayerDailyCount = mod_daily_dict:get_count(FromPlayerId, 2701),
                                                    case FromPlayerDailyCount < 1 of
                                                        true ->
                                                            %% 更改双方的伴侣_更改双方的仙侣奇缘状态_公共线状态
                                                            lib_appointment:set_partner_unite(UniteStatus#unite_status.id, FromPlayerId, 5),
                                                            lib_appointment:set_partner_unite(FromPlayerId, UniteStatus#unite_status.id, 4),
															%% 获取亲密度 以及根据亲密度获取可以赠送的礼物
															Intimacy = lib_relationship:find_intimacy(FromPlayerId, UniteStatus#unite_status.id),
															ItemType = item_type(Intimacy),
															%% 发送邀请方缘字_送礼列表
                                                            {ok, BinData1} = pt_270:write(27015, [0, SelfEU#ets_unite.id, SelfEU#ets_unite.name, ItemType]),
                                                            lib_unite_send:send_to_sid(FromPlayer#ets_unite.sid, BinData1),
															%% 发送应答给邀请人
                                                            {ok, BinData} = pt_270:write(27004, [SelfEU#ets_unite.id, SelfEU#ets_unite.name, Res]),
                                                            lib_unite_send:send_to_sid(FromPlayer#ets_unite.sid, BinData),
                                                            [1, FromPlayer#ets_unite.name];
                                                        false ->[6, []]
                                                    end;
                                                false ->[5, []]
                                            end
                                    end;
                                false -> [3, []]
                            end
                    end;
                false -> [4, []]
            end
    end,
    {ok, BinData2} = pt_270:write(27003, [Res1, NickName, FromPlayerId]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData2);

%% 对异性使用物品 - 游戏服务器(估计改到公共线比较好)
handle(27005, PlayerStatus, [PartnerId, Type, _Bang]) ->
	case mod_daily_dict:get_count(PlayerStatus#player_status.id, 2701) of
		0 ->
			case lib_appointment:check_app_s(PlayerStatus#player_status.id) of
				[] -> 
					%% 玩家APPCONFIG错误
					{ok, BinData0} = pt_270:write(27005, [6]),
					lib_server_send:send_one(PlayerStatus#player_status.socket, BinData0);
				Config ->
					case Config#ets_appointment_config.state =:= 4 of
						false -> 
							case Config#ets_appointment_config.now_partner_id =:= 0 of
								true ->
									%% 对方已经取消约会
									{ok, BinData11} = pt_270:write(27005, [11]),
									lib_server_send:send_one(PlayerStatus#player_status.socket, BinData11);
								false ->
									%% 玩家不是仙侣情缘主动方
									{ok, BinData7} = pt_270:write(27005, [7]),
									lib_server_send:send_one(PlayerStatus#player_status.socket, BinData7)
							end;
						true ->
							case PartnerId =:= Config#ets_appointment_config.now_partner_id andalso PartnerId > 0 of
								false ->
									%% 对象ID错误
									{ok, BinData} = pt_270:write(27005, [4]),
									lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
								true -> 
									%% 获取对方的坐标(借用打坐的数据)
									case lib_player:get_player_info(PartnerId, lib_sit) of
		        						_PartnerPS when is_record(_PartnerPS, player_status_sit)->
											[X, Y] = [?APP_EXP_X, ?APP_EXP_Y],
											case abs(_PartnerPS#player_status_sit.x - X) < 34 andalso abs(_PartnerPS#player_status_sit.y - Y) < 34 of
												false -> 											%% 不在仙侣任务范围内
													{ok, BinData} = pt_270:write(27005, [10]),
													lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
												true ->
													case abs(PlayerStatus#player_status.x - X) < 34 andalso abs(PlayerStatus#player_status.y - Y) < 34 of
														false -> 
															%% 不在仙侣任务范围内
															{ok, BinData} = pt_270:write(27005, [8]),
															lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
														true ->
															%% 使用物品_礼物
															{NewPlayerStatus, Res, RItemId, RTitle, RContent} = case Type of % 2,3 为元宝
																  2 -> 
																	  case lib_goods_util:is_enough_money(PlayerStatus, 10, gold) of
																		  true -> 
																			  PlayerStatus1 = lib_goods_util:cost_money(PlayerStatus, 10, gold),
																			  [Title, Content] = data_appointment_text:get_sys_mail(2, PlayerStatus1#player_status.sex),
																			  ItemId = case PlayerStatus1#player_status.sex =:= 1 of
																						   true -> 521302;			%% 男送女 琉璃凤钗 id:521302
																						   false -> 521304 			%% 女送男 同心玉佩 id:521304
																					   end,
																			  [Msg] = data_appointment_text:get_log_consume_text(xlqy_item, gold),
																			  log:log_consume(xlqy_item, gold, PlayerStatus, PlayerStatus1, Msg),
																			  mod_daily_dict:set_special_info({PlayerStatus#player_status.id, PartnerId}, 1),
																			  {PlayerStatus1, 1, ItemId, Title, Content};
																		  false -> 
																			  {PlayerStatus, 3, 0, [], []} %% 元宝不足
																	  end;
																  1 -> 
																	  case lib_goods_util:is_enough_money(PlayerStatus, 10000, coin) of
																		  true -> 
																			  PlayerStatus1 = lib_goods_util:cost_money(PlayerStatus, 10000, coin),
																			  [Title, Content] = data_appointment_text:get_sys_mail(1, PlayerStatus1#player_status.sex),
																			  ItemId = case PlayerStatus1#player_status.sex =:= 1 of
																						   true -> 521301; 			%% 男送女 沉香玉镯 id:521301
																						   false -> 521303			%% 女送男 五彩香囊 id:521303
																					   end,
																			  [Msg] = data_appointment_text:get_log_consume_text(xlqy_item, coin),
																			  log:log_consume(xlqy_item, coin, PlayerStatus, PlayerStatus1, Msg),
																			  {PlayerStatus1, 1, ItemId, Title, Content};
																		  false -> 
																			  {PlayerStatus, 2, 0, [], []} %% 铜钱不足
																	  end;
																  _ -> 
																	  {PlayerStatus, 0, 0, [], []}
															end,
															case Res =:= 1 of
																true -> %% 送礼正常
																	PlayerPid = PlayerStatus#player_status.pid,
																	PartnerPid = lib_player:get_player_info(PartnerId, pid),
																	lib_relationship:update_xlqy_count(PlayerPid, PartnerPid, PlayerStatus#player_status.id, PartnerId),
																	put(songlizhong, 1),
																	%% 发送礼物邮件
																	mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, 
																							   [[PartnerId], 
																								RTitle,
																								PlayerStatus#player_status.nickname ++ RContent, 
																								RItemId, 
																								2, 0, 0, 1, 0, 0, 0, 0]),
																	%% 增加双方的日常 _为了方便测试 不写入日常
				                                                    mod_daily_dict:plus_count(PlayerStatus#player_status.id, 2701, 1),
																	mod_daily_dict:plus_count(PartnerId, 2700, 1),
																	%% 当前正在小游戏选择状态
																	mod_daily_dict:set_count(PlayerStatus#player_status.id, 2705, 1),
																	mod_daily_dict:set_count(PartnerId, 2705, 1),
																	%% 刷新背包
																	lib_player:refresh_client(PlayerStatus#player_status.id, 2),
																	%% 询问是否要进行种花小游戏
																	send_question(0, PlayerStatus#player_status.id, PartnerId),
																	%% 更新双方的约会状态
				%% 													NowTime = util:unixtime(), 
																	case lib_appointment:check_app_s(PartnerId) of 
																			   [] -> 
																				   case lib_appointment:db_get_appointment_config(PartnerId) of
																						0 -> %% 无数据,玩家没有进行过仙侣任务
																							NS = #ets_appointment_config{id = PartnerId},
																							lib_appointment:update_app_config_s(NS, 0);
																						_ ->
																							skip
																					end;
																			   _ ->
																				   skip
																	end,
																	%% 记录仙侣情缘状态数据
																	mod_app:start_one_xlqy(PlayerStatus#player_status.id, PartnerId, 1),
																	{ok, BinData2} = pt_270:write(27005, [1]),
																	lib_server_send:send_to_uid(PlayerStatus#player_status.id, BinData2),
																	{ok, NewPlayerStatus};
																false ->  %% 送礼失败
																	{ok, BinData} = pt_270:write(27005, [Res]),
																	lib_server_send:send_to_uid(PlayerStatus#player_status.id, BinData)
															end
													end;
												_ ->
													{ok, BinData} = pt_270:write(27005, [10]),
													lib_server_send:send_to_uid(PlayerStatus#player_status.id, BinData)
											end;
										_->
											{ok, BinData} = pt_270:write(27005, [10]),
											lib_server_send:send_to_uid(PlayerStatus#player_status.id, BinData)
									end
							end
					end
			end;
		_ ->
			{ok, BinData} = pt_270:write(27005, [5]),
			lib_server_send:send_to_uid(PlayerStatus#player_status.id, BinData)
	end;

%% 回答是否进行游戏 - 游戏服务器(估计改到公共线比较好)
handle(27022, UniteStatus, [AnswerId]) ->
    case lib_appointment:check_app(UniteStatus#unite_status.id) of
        [] -> ok;
        Config ->
			PartnerId = Config#ets_appointment_config.now_partner_id,
			NowTime = util:unixtime(), 
            %% 不用再次
			Res = case Config#ets_appointment_config.step < 2 of
					  false ->%% 已经回答过
						  case Config#ets_appointment_config.begin_time =:= 0 of
							  true->
								    %% 更新对方
									lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
									%% 更新自己
									lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
																										   , last_exp_time = NowTime
																										   , step = 4}
																			 , 0),
									%% 跳到 约会流程 约会信息
									PlayerId = UniteStatus#unite_status.id,
									PartnerName = lib_appointment:get_partner_name(PartnerId),
									SelfName = lib_appointment:get_partner_name(PlayerId),
									{ok, BinData1} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PartnerId, PartnerName, 0, 1]),
									lib_unite_send:send_to_one(PlayerId, BinData1),
									{ok, BinData2} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PlayerId, SelfName, 0, 0]),
									lib_unite_send:send_to_one(PartnerId, BinData2),
									0;
							  false->
								    %% 跳到 约会流程 约会信息
									PlayerId = UniteStatus#unite_status.id,
									TimeLeft = ?ADD_EXP_TIME - (NowTime - Config#ets_appointment_config.begin_time),
									PartnerName = lib_appointment:get_partner_name(PartnerId),
									SelfName = lib_appointment:get_partner_name(PlayerId),
									{ok, BinData1} = pt_270:write(27019, [1, TimeLeft, 6, PartnerId, PartnerName, 0, 0]),
									lib_unite_send:send_to_one(PlayerId, BinData1),
									{ok, BinData2} = pt_270:write(27019, [1, TimeLeft, 6, PlayerId, SelfName, 0, 0]),
									lib_unite_send:send_to_one(PartnerId, BinData2),
									0
						  end;
					  true -> 
						  case lib_appointment:check_app(Config#ets_appointment_config.now_partner_id) of
							  [] -> 
									%% 更新对方
									lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
									%% 更新自己
									lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
																										   , last_exp_time = NowTime
																										   , step = 4}
																			 , 0),
									%% 跳到 约会流程 约会信息
									PlayerId = UniteStatus#unite_status.id,
									PartnerName = lib_appointment:get_partner_name(PartnerId),
									SelfName = lib_appointment:get_partner_name(PlayerId),
									{ok, BinData1} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PartnerId, PartnerName, 0, 1]),
									lib_unite_send:send_to_one(PlayerId, BinData1),
									{ok, BinData2} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PlayerId, SelfName, 0, 0]),
									lib_unite_send:send_to_one(PartnerId, BinData2),
									0;
							  TargetPlayerApp -> 
								  case AnswerId =:= 0 of
									  true -> %% 不进行游戏
										  {ok, Bin1} = pt_270:write(27026, [0]),
										  {ok, Bin2} = pt_270:write(27026, [1]),
										  lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, Bin1),
										  lib_unite_send:send_to_one(TargetPlayerApp#ets_appointment_config.id, Bin2), 
										  %% 更新玩家 双方的仙侣状态为约会中
										  lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
										  %% 更新自己
										  lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
																												   , last_exp_time = NowTime
																												   , step = 4}
																					 , 0),
										  %% 跳到 约会流程 约会信息
										  PlayerId = UniteStatus#unite_status.id,
										  PartnerName = lib_appointment:get_partner_name(PartnerId),
										  SelfName = lib_appointment:get_partner_name(PlayerId),
										  {ok, BinDataX1} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PartnerId, PartnerName, 0, 1]),
										  lib_unite_send:send_to_one(PlayerId, BinDataX1),
										  {ok, BinDataX2} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PlayerId, SelfName, 0, 0]),
										  lib_unite_send:send_to_one(PartnerId, BinDataX2),
										  1;
									  false -> 
										  {ok, Bin1} = pt_270:write(27026, [0]),
										  {ok, Bin2} = pt_270:write(27026, [1]),
										  lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, Bin1),
										  lib_unite_send:send_to_one(TargetPlayerApp#ets_appointment_config.id, Bin2), 
										  %% 更新玩家 双方的仙侣状态为约会中
										  lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
										  %% 更新自己
										  lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
																												   , last_exp_time = NowTime
																												   , step = 4}
																					 , 0),
										  %% 跳到 约会流程 约会信息
										  PlayerId = UniteStatus#unite_status.id,
										  PartnerName = lib_appointment:get_partner_name(PartnerId),
										  SelfName = lib_appointment:get_partner_name(PlayerId),
										  {ok, BinDataX1} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PartnerId, PartnerName, 0, 1]),
										  lib_unite_send:send_to_one(PlayerId, BinDataX1),
										  {ok, BinDataX2} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PlayerId, SelfName, 0, 0]),
										  lib_unite_send:send_to_one(PartnerId, BinDataX2),
										  1
								  end
						  end
				  end,
			{ok, BinData} = pt_270:write(27022, [Res]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
    end;

%% 仙侣约会增加经验 - 游戏服务器(估计改到公共线比较好)
handle(27007, PlayerStatus, exp_add) -> 
    case lib_appointment:check_app_s(PlayerStatus#player_status.id) of
        [] -> ok;
        Config ->
            Time = util:unixtime(), 
            %% 是否间隔5S
            case Time - Config#ets_appointment_config.last_exp_time >= ?EXP_INTERVAL_TIME of
                true -> 
                    %% 是否在有效时间内
                    case Time - Config#ets_appointment_config.begin_time =< ?ADD_EXP_TIME of
                        true -> 
                            %% 判断距离 
							[X, Y] = [?APP_EXP_X, ?APP_EXP_Y],
                            case abs(PlayerStatus#player_status.x - X) > 34 orelse abs(PlayerStatus#player_status.y - Y) > 34 of
                                true -> ok;
                                false ->
                                    %% 增加经验
									lib_appointment:update_app_config_s(Config#ets_appointment_config{last_exp_time = Time}
													   , 0),
									ExpKey = case Config#ets_appointment_config.state =:= 4 of
										true ->
											{PlayerStatus#player_status.id, Config#ets_appointment_config.now_partner_id};
										false ->
											{Config#ets_appointment_config.now_partner_id, PlayerStatus#player_status.id}
									end,
                                    Exp = add_exp(ExpKey, PlayerStatus#player_status.lv),
									ExpNew = case Exp =< 0 of
										true ->
											0;
										false ->
											Exp
									end,
                                    {ok, BinData} = pt_130:write(13017, ExpNew),
                                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
                                    NewPlayerStatus = lib_player:add_exp(PlayerStatus, ExpNew, 0),
                                    {ok, NewPlayerStatus}
                            end;
                        false -> %% 超时发送结束
							ok
                    end;
                false -> ok
            end
    end;

%% 对对方的评价 - 游戏服务器(估计改到公共线比较好)
handle(27010, UniteStatus, [PartnerId, Type, Rose]) ->
	%% 判断并扣除玫瑰
	_Res = case Rose of
		0 -> %%　不送花
			0;
		Num when Num =:= 9 orelse Num =:= 99  orelse Num =:= 999 ->
			case lib_player:get_player_info(PartnerId, sendTv_Message) of
				false ->
					0;
				[IdT, RealmT, NicknameT, SexT, CareerT, IimageT] ->
					case pp_flower:handle(29001, UniteStatus, [2, Num, util:make_sure_list(NicknameT), 1]) of
						{ok, _} ->
							Res2 = case UniteStatus#unite_status.sex of
									  1 ->
										  3;
									  2 ->
										  4
								  end,
							lib_chat:send_TV({all},1, 2
											,[xianlv
											 ,Res2
											 ,UniteStatus#unite_status.id
											 ,UniteStatus#unite_status.realm
											 ,UniteStatus#unite_status.name
											 ,UniteStatus#unite_status.sex
											 ,UniteStatus#unite_status.career
											 ,UniteStatus#unite_status.image
											 ,IdT
											 ,RealmT
											 ,NicknameT
											 ,SexT
											 ,CareerT
											 ,IimageT
											 ]),
							1;
						_ ->
							0
					end
			end;
		_ ->
			0
	end,
    {ok, BinData} = pt_270:write(27011, [UniteStatus#unite_status.id
										, UniteStatus#unite_status.name
										, UniteStatus#unite_status.sex 
										, UniteStatus#unite_status.image
										, UniteStatus#unite_status.career
										, Type
										, Rose]),
    lib_unite_send:send_to_one(PartnerId, BinData);


%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 					仙侣情缘_代码整理区
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% 获取红粉/蓝颜知己 - 公共服务器
handle(27020, Status, get_appointment) ->
    case lib_appointment:check_app(Status#unite_status.id) of
        [] -> ok;
        Config ->
			AL = Config#ets_appointment_config.recommend_partner,
			case AL of
                [] -> 
					{ok, BinData} = pt_270:write(27020, [0, [], 0, 0, 0, 0, 0, 0, 0]),
                    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);
                [RecId, RecNum] -> 
                    [Type, PName, Sex, Lv, Voc, Realm, Weapon, Clothes] = case RecNum > 2 of
                        true -> [0,[],0,0,0,0,0,0];
                        false -> 
                            case lib_appointment:check_unite_online(RecId) of
                                [] -> 
									Sql = io_lib:format(<<"select nickname, sex, lv, career, realm from player_low where id = ~p">>, [RecId]),
						            case db:get_all(Sql) of
						                [] -> [0,[],0,0,0,0,0,0];
						                [[SName, SSex, SLv, SVoc, SRealm]] -> 
											[0, SName, SSex, SLv, SVoc, SRealm, 0, 0]
						            end;
                                RecommendPartner -> 
									case lib_player:get_player_info(RecommendPartner#ets_unite.id, goods) of
										LBGOOD when is_record(LBGOOD, status_goods) -> 
											[E1, E2| _] = LBGOOD#status_goods.equip_current,
											[1 
											, RecommendPartner#ets_unite.name
											, RecommendPartner#ets_unite.sex
											, RecommendPartner#ets_unite.lv
											, RecommendPartner#ets_unite.career
											, RecommendPartner#ets_unite.realm
											, E1
											, E2];
										_ ->
											[1 
											, RecommendPartner#ets_unite.name
											, RecommendPartner#ets_unite.sex
											, RecommendPartner#ets_unite.lv
											, RecommendPartner#ets_unite.career
											, RecommendPartner#ets_unite.realm
											, 0
											, 0]
									end
                            end
                    end,
                    case lib_appointment:check_unite_online(Status#unite_status.id) of
                        [] -> ok;
                        _ChatInfo ->
							case Type of
								0 ->
									{ok, BinData} = pt_270:write(27020, [0, PName, Type, Sex, Lv, Voc, Realm, 0, 0]),
                            		lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);
								_ ->
									{ok, BinData} = pt_270:write(27020, [RecId, PName, Type, Sex, Lv, Voc, Realm, Weapon, Clothes]),
		                            lib_unite_send:send_to_sid(Status#unite_status.sid, BinData)
							end
                    end
            end
    end;

%% 仙侣奇缘聊天 - 公共服务器
handle(27016, Status, PartnerId) ->
    case lib_appointment:check_unite_online(PartnerId) of
        [] -> 
            {ok, BinData} = pt_270:write(27016, [0, [], 0, 0, 0]),
            lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);
        Partner -> 
            {ok, BinData} = pt_270:write(27016, [PartnerId, Partner#ets_unite.name, Partner#ets_unite.sex, Partner#ets_unite.career, 1]),
            lib_unite_send:send_to_sid(Status#unite_status.sid, BinData)
    end;

%% 上线获取仙侣情缘状态 - 公共服务器 
handle(27014, UniteStatus, get_xlqy_state) when is_record(UniteStatus, unite_status)->
	PlayerId = UniteStatus#unite_status.id,
	case lib_appointment:check_app(UniteStatus#unite_status.id) of
		[] -> ok;
		ConfigSelf ->
			%% 判断是否已经有日常数据
			%% 邀请次数
%% 	        InventTimes = mod_daily_dict:get_count(PlayerId, 2701),
			%% 被邀请次数
%% 			BeInventedTimes = mod_daily_dict:get_count(PlayerId, 2700),
			%% 送礼状态(取消/完成,都要清零)
			Gift_Times = mod_daily_dict:get_count(PlayerId, 2705),
			NowTime = util:unixtime(), 
			case ConfigSelf#ets_appointment_config.now_partner_id of
				0 -> %% 没有伴侣
					ok;
				_PartnerId when Gift_Times =:= 0 -> %% 送礼之前
					lib_appointment:cancel_appointment_self(ConfigSelf);
				PartnerId when Gift_Times >= 1 ->  %% 送礼之后
					case lib_appointment:check_unite_online(PartnerId) of
						[] -> %% 对方不在线
							case ConfigSelf#ets_appointment_config.state of
								4 -> %% 主动方  --- > 直接跳到 完成
									lib_appointment:appointment_end_all(ConfigSelf, 0);
								_ -> %% 被动方  --- > 直接清除仙侣信息
									lib_appointment:cancel_appointment_self(ConfigSelf)
							end;
						OnlinePartner ->
							_PartnerName1 = OnlinePartner#ets_unite.name,
							case lib_appointment:check_app(PartnerId) of
								[] -> %% 对方没有仙侣信息
									case ConfigSelf#ets_appointment_config.state of
										4 -> %% 主动方  --- > 直接跳到 完成
											lib_appointment:appointment_end_all(ConfigSelf, 0);
										_ -> %% 被动方  --- > 直接清除仙侣信息
											lib_appointment:cancel_appointment_self(ConfigSelf)
									end;
								ConfigPartner ->
									%% 判断对方的仙侣是不是自己
									case ConfigPartner#ets_appointment_config.now_partner_id =:= PlayerId of
										false -> %% 不是自己
											case ConfigSelf#ets_appointment_config.state of
												4 -> %% 主动方  --- > 直接跳到 完成
													lib_appointment:appointment_end_all(ConfigSelf, 0);
												_ -> %% 被动方  --- > 直接清除仙侣信息
													lib_appointment:cancel_appointment_self(ConfigSelf)
											end;
										true -> %% 是自己(根据对方的状态来决定自己的操作)
											GiftTimesPartner = mod_daily_dict:get_count(PartnerId, 2705),
%% 											io:format("STEP ~p~n", [ConfigPartner#ets_appointment_config.step]),
											case GiftTimesPartner >= 1 of
												true -> %% 日常正常
													case ConfigPartner#ets_appointment_config.step of
														0 -> %% 因为已经送礼,这里表示未答题,直接回答否
															case ConfigSelf#ets_appointment_config.state of
																4 -> %% 主动方  --- > 直接跳到 完成
																	lib_appointment:appointment_end_all(ConfigSelf, 0);
																_ -> %% 被动方  --- > 直接清除仙侣信息
																	lib_appointment:cancel_appointment_self(ConfigSelf)
															end;
														1 -> %% 已经答题,需要判断对方状态
															case ConfigSelf#ets_appointment_config.state of
																4 -> %% 主动方  --- > 直接跳到 完成
																	lib_appointment:appointment_end_all(ConfigSelf, 0);
																_ -> %% 被动方  --- > 直接清除仙侣信息
																	lib_appointment:cancel_appointment_self(ConfigSelf)
															end;
														2 -> %% 已经抽奖
															case ConfigSelf#ets_appointment_config.state of
																4 -> %% 主动方  --- > 直接跳到 完成
																	lib_appointment:appointment_end_all(ConfigSelf, 0);
																_ -> %% 被动方  --- > 直接清除仙侣信息
																	lib_appointment:cancel_appointment_self(ConfigSelf)
															end;
														3 -> %% 种花游戏中 (继续种花)
															case ConfigSelf#ets_appointment_config.state of
																4 -> %% 主动方  --- > 直接跳到 完成
																	lib_appointment:appointment_end_all(ConfigSelf, 0);
																_ -> %% 被动方  --- > 直接清除仙侣信息
																	lib_appointment:cancel_appointment_self(ConfigSelf)
															end;
														4 -> %% 经验中
															case NowTime - ConfigPartner#ets_appointment_config.begin_time =< ?ADD_EXP_TIME of
																true -> %% 约会中_发剩余时间
																	%% 更新自己
																	TimeLeft = ?ADD_EXP_TIME - (NowTime - ConfigPartner#ets_appointment_config.begin_time),
																	lib_appointment:update_appointment_config(ConfigSelf#ets_appointment_config{begin_time = ConfigPartner#ets_appointment_config.begin_time
																																		   , last_exp_time = ConfigPartner#ets_appointment_config.last_exp_time
																																		   , step = 4}
																											 , 0),
																	%% 跳到 约会流程 约会信息
																	PartnerName = lib_appointment:get_partner_name(PartnerId),
																	SelfName = lib_appointment:get_partner_name(PlayerId),
																	{ok, BinDataX1} = pt_270:write(27019, [1, TimeLeft, 6, PartnerId, PartnerName, 0, 1]),
																	lib_unite_send:send_to_one(PlayerId, BinDataX1),
																	{ok, BinDataX2} = pt_270:write(27019, [1, TimeLeft, 6, PlayerId, SelfName, 0, 0]),
																	lib_unite_send:send_to_one(PartnerId, BinDataX2);
																false -> %% 已经结束 完成任务
																	case ConfigSelf#ets_appointment_config.state of
																		4 -> %% 主动方  --- > 直接跳到 完成
																			lib_appointment:appointment_end_all(ConfigSelf, 0);
																		_ -> %% 被动方  --- > 直接清除仙侣信息
																			lib_appointment:cancel_appointment_self(ConfigSelf)
																	end
															end;
														5 -> %% 评价对方中
															case ConfigSelf#ets_appointment_config.state of
																4 -> %% 主动方  --- > 直接跳到 完成
																	lib_appointment:appointment_end_all(ConfigSelf, 0);
																_ -> %% 被动方  --- > 直接清除仙侣信息
																	lib_appointment:cancel_appointment_self(ConfigSelf)
															end;
														_ -> %%不正常状态
															case ConfigSelf#ets_appointment_config.state of
																4 -> %% 主动方  --- > 直接跳到 完成
																	lib_appointment:appointment_end_all(ConfigSelf, 0);
																_ -> %% 被动方  --- > 直接清除仙侣信息
																	lib_appointment:cancel_appointment_self(ConfigSelf)
															end
													end;
												false ->
													case ConfigSelf#ets_appointment_config.state of
														4 -> %% 主动方  --- > 直接跳到 完成
															lib_appointment:appointment_end_all(ConfigSelf, 0);
														_ -> %% 被动方  --- > 直接清除仙侣信息
															lib_appointment:cancel_appointment_self(ConfigSelf)
													end
											end
									end
							end
					end
			end
	end,
	ok;

%% 取消约会 - 公共服务器
handle(27012, Status, end_appointment) when is_record(Status, unite_status) ->
    case lib_appointment:check_app(Status#unite_status.id) of
        [] -> ok;
        Config -> case Config#ets_appointment_config.now_partner_id of
                0 -> ok;
                PartnerId -> 
                    CanCancel = case lib_appointment:check_app(Status#unite_status.id) of
                        [] -> true;
                        PartnerAppConfig -> case PartnerAppConfig#ets_appointment_config.step == 0 of
                                true -> true;
                                false -> false
                            end
                    end,
                    case CanCancel of
                        true ->
							%% 取消
                            lib_appointment:cancel_appointment_unite(Status#unite_status.id, PartnerId),
							lib_appointment:cancel_appointment_msg(Status#unite_status.id, PartnerId);
                        false -> 
							%% 无法取消,发送通知
                            [Msg] = data_appointment_text:get_sys_msg(1),
                            lib_chat:send_sys_msg_one(Status#unite_status.sid, Msg)
                    end
            end
    end;


%% 仙侣情缘结束  - 游戏线
handle(27008, PlayerStatus, [TaskId]) when is_record(PlayerStatus, player_status)->
%% 	NowTime = util:unixtime(), 
    case lib_appointment:check_app_s(PlayerStatus#player_status.id) of
        [] -> ok;
        Config -> 
            %% 完成仙侣奇缘任务
			%% 允许5秒误差
			case Config#ets_appointment_config.now_partner_id =:= 0 of
				true ->
					ok;
				false ->
					%% 现在是在约会中且自己是主动方
					case Config#ets_appointment_config.step =:= 4 of
						false -> %% 还在经验时间内
							ok;
						true ->
							NewPlayerStatus = case Config#ets_appointment_config.state of
								4 ->
									%% 完成任务
									lib_task:event(PlayerStatus#player_status.tid, xlqy, do, PlayerStatus#player_status.id),
									%% 评价对方
									case lib_appointment:check_unite_online_s(Config#ets_appointment_config.now_partner_id) of
				                        [] -> ok;
				                        TargetPlayerEu ->
				                            %% 评价对方
				                            {ok, BinData2} = pt_270:write(27009, [TargetPlayerEu#ets_unite.id, TargetPlayerEu#ets_unite.name]),
				                            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData2),
											{ok, BinData3} = pt_270:write(27009, [PlayerStatus#player_status.id, PlayerStatus#player_status.nickname]),
				                            lib_server_send:send_to_uid(TargetPlayerEu#ets_unite.id, BinData3)
				                    end,
									%% 刷新NPC
									{ok, BinData} = pt_300:write(30004, [TaskId, <<>>]),
		                   	 		lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
									PlayerStatus;
								_ ->
									PlayerStatus
							end,
							%% 改变自己的仙侣数据
							lib_appointment:appointment_end_all(Config),
							{ok, NewPlayerStatus}
					end
			end
	end;

%% 用于转送
handle(27051, PlayerStatus, [SceneId, _X, _Y]) ->
	case PlayerStatus#player_status.copy_id =:= 0 of
		false ->
			{ok, BinData} = pt_270:write(27051, [2]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
		true ->
			case PlayerStatus#player_status.husong#status_husong.husong =:= 0 of
				false ->
					{ok, BinData} = pt_270:write(27051, [2]),
					lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
				true ->
					case PlayerStatus#player_status.scene =:= 231 orelse PlayerStatus#player_status.scene =:= 998 of
						true ->
							{ok, BinData} = pt_270:write(27051, [2]),
							lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
						false ->
                            case lib_player:is_transferable(PlayerStatus) of
                                false ->
                                    {ok, BinData} = pt_270:write(27051, [2]),
                                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
                                true ->
                                    {X, Y} = case mod_daily_dict:get_count(PlayerStatus#player_status.id, 2751) of
                                        0 ->
                                            case lib_appointment:check_app_s(PlayerStatus#player_status.id) of
                                                [] -> {_X, _Y};
                                                Config ->
                                                    %% 申请一个坐标
                                                    NewPointN = new_point(),
                                                    mod_daily_dict:set_count(PlayerStatus#player_status.id, 2751, NewPointN),
                                                    mod_daily_dict:set_count(Config#ets_appointment_config.now_partner_id, 2751, NewPointN),
                                                    get_point(NewPointN)
                                            end;
                                        PointN ->
                                            get_point(PointN)
                                    end,
                                    %% 							io:format("1"),
                                    lib_scene:player_change_scene(PlayerStatus#player_status.id, SceneId, 0, X, Y,true),
                                    %% 							io:format("2"),
                                    {ok, BinData} = pt_270:write(27051, [1]),
                                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData)
                            end
					end
			end
	end,
	{ok, PlayerStatus};

%% 参加自愿同意(无红颜/蓝颜)
handle(27052, UniteStatus, _) ->
	DailyCountSelf1 = mod_daily_dict:get_count(UniteStatus#unite_status.id, 2700),%% 被邀请次数
	DailyCountSelf2 = mod_daily_dict:get_count(UniteStatus#unite_status.id, 2701),%% 邀请次数
	case DailyCountSelf1 < 2 andalso DailyCountSelf2 < 1 of
		true ->
			ResX = case mod_app:get_one(3 - UniteStatus#unite_status.sex) of
				[] ->
					mod_app:insert_one([UniteStatus#unite_status.id, UniteStatus#unite_status.sex]),
					1;
				[TargetId] ->
					%% 直接跳到送礼状态
					case lib_appointment:check_unite_online(TargetId) of
						[] -> 
							mod_app:remove_one(TargetId),
							mod_app:insert_one([UniteStatus#unite_status.id, UniteStatus#unite_status.sex]),
							1;
						TargetIdEU -> 
							case TargetIdEU#ets_unite.appointment =:= 0 of
								false ->
									mod_app:remove_one(TargetId),
									mod_app:insert_one([UniteStatus#unite_status.id, UniteStatus#unite_status.sex]),
									1;
								true ->
									%% 双方同时进行仙侣情缘
						            lib_appointment:set_partner_unite(UniteStatus#unite_status.id, TargetId, 4),
						            lib_appointment:set_partner_unite(TargetId, UniteStatus#unite_status.id, 4),
									%% 获取亲密度 以及根据亲密度获取可以赠送的礼物
									Intimacy1 = lib_relationship:find_intimacy(UniteStatus#unite_status.id, TargetId),
									ItemType1 = item_type(Intimacy1),
									Intimacy2 = lib_relationship:find_intimacy(TargetId, UniteStatus#unite_status.id),
									ItemType2 = item_type(Intimacy2),
									%% 发送缘字_送礼列表_双方
						            {ok, BinData1} = pt_270:write(27015, [0, UniteStatus#unite_status.id, UniteStatus#unite_status.name, ItemType2]),
						            lib_unite_send:send_to_one(TargetId, BinData1),
						            {ok, BinData2} = pt_270:write(27015, [0, TargetIdEU#ets_unite.id, TargetIdEU#ets_unite.name, ItemType1]),
						            lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData2),
									1
							end
					end
			end,
			{ok, BinDataxx} = pt_270:write(27052, [ResX]),
			lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinDataxx);
		false ->
			{ok, BinDataxx} = pt_270:write(27052, [2]),
			lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinDataxx)
	end,
	{ok, UniteStatus};

%% 玩家登陆记录区域
handle(27053, UniteStatus, Location) ->
	mod_app:insert_location(UniteStatus#unite_status.id, Location),
	ok;

%%	抽奖_小游戏奖励类型 - 公共线
handle(27029, UniteStatus, xlqy_get_new_prize) ->
	PlayerId = UniteStatus#unite_status.id,
	case lib_appointment:check_app(PlayerId) of
        [] -> %% 玩家仙侣信息错误
			ok;
        Config when Config#ets_appointment_config.state =:= 4 -> %% 判断是否在符合的流程中 且本人是 主动方
			case Config#ets_appointment_config.step =:= 1 of
				true -> %% 开始游戏流程
					lib_appointment:flower_game_start(PlayerId, Config, UniteStatus);
				false when Config#ets_appointment_config.step =:= 2 ->
					%% 再次抽奖 只刷新奖励
					lib_appointment:flower_new_prize(PlayerId, UniteStatus);
				_ -> %% 错误的流程中
					ok
			end;
        _r -> %% 玩家仙侣信息错误
			ok
	end,
	ok;

%%  种花_开始 - 公共线
handle(27030, UniteStatus, xlqy_confirm_flower_start) ->
	PlayerId = UniteStatus#unite_status.id,
	case lib_appointment:check_app(PlayerId) of
		[] -> %% 玩家仙侣信息错误
			ok;
		Config when Config#ets_appointment_config.step =:= 2 ->
			case Config#ets_appointment_config.state of
				4 -> %% 主动方
					case lib_appointment:check_app(Config#ets_appointment_config.now_partner_id) of
						[] -> %% 对方不在线,只更改自己的状态
							%% 更改CONFIG 和 GAME
							lib_appointment:update_appointment_config(Config#ets_appointment_config{step = 3}, 1),
							lib_appointment:flower_creater(Config#ets_appointment_config.id
														  , Config#ets_appointment_config.now_partner_id
														  , UniteStatus);
						TargetConfig ->
							%% 更改CONFIG 和 GAME
							lib_appointment:update_appointment_both(Config#ets_appointment_config{step = 3}
												   ,TargetConfig#ets_appointment_config{step = 3}
												   ,1),
							lib_appointment:flower_creater(Config#ets_appointment_config.id
														  , Config#ets_appointment_config.now_partner_id
														  , UniteStatus)
					end,
					ok;
				5 -> %% 被动方
					Game_Id = Config#ets_appointment_config.now_partner_id,
					case lib_appointment:get_appointment_game(Game_Id) of
						error ->
							ok;
						AppGame ->
							case AppGame#ets_appointment_game.flower_id of
								0 ->
									ok;
								FlowerId ->
									NowTime = util:unixtime(),
									TimeLeft = ?APP_GAME_TIME - (NowTime - AppGame#ets_appointment_game.start_time),
									OptType = 3 - AppGame#ets_appointment_game.opt_type,
									{_, _, X, Y} = lib_appointment:get_flower_info(FlowerId),
									PrizeType = AppGame#ets_appointment_game.prize_type,
									PartnerName = case lib_appointment:check_unite_online(Config#ets_appointment_config.now_partner_id) of
		                                [] -> [];
		                                Partner -> 
											Partner#ets_unite.name
		                            end,
									{ok, BinData} = pt_270:write(27030, [PrizeType, OptType, FlowerId, X, Y, TimeLeft, PartnerName]),
									lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
							end
					end
			end;
		_->
			ok
	end;

%%  除虫/浇水 - 公共线
handle(27032, UniteStatus, [OptStep, OptFlower]) ->
	PlayerId = UniteStatus#unite_status.id,
	case lib_appointment:check_app(PlayerId) of
		[] -> %% 玩家仙侣信息错误
			ok;
        Config ->
			case Config#ets_appointment_config.step =:= 3 of
				false -> %% 错误的流程信息
					ok;
				_ ->
					%% 结果
					Res = lib_appointment:do_flower(OptStep, OptFlower, Config, UniteStatus),
					{ok, BinData} = pt_270:write(27032, [Res]),
					lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
			end
	end;

%% 刷新下一轮鲜花 超时则通知游戏结束 - 公共线
handle(27024, UniteStatus, xlqy_game_refresh) ->
    case lib_appointment:check_app(UniteStatus#unite_status.id) of
        [] -> ok;
        Config ->
			case lib_appointment:get_appointment_game(Config) of
				[0, 0, 0] ->
					ok;
				[AppGame, _MyOpt, MyOptTime] ->
					Time = util:unixtime(), 
					case Time - MyOptTime >= ?APP_GAME_OPT_TIME of
		                true -> 
		                    case Time - AppGame#ets_appointment_game.start_time < ?APP_GAME_TIME of
								true ->	
									%% 有效时间内_刷新鲜花
									lib_appointment:flower_new_status(Config, AppGame, UniteStatus);
								false ->
									%% 超出有效时间_种花结束
									lib_appointment:flower_game_end(Config, AppGame, UniteStatus),
									%% 更新玩家仙侣奇缘状态
									NowTime = util:unixtime(), 
									%% 检查对方的信息_不在线就直接写数据库
									case lib_appointment:get_appointment_config(Config#ets_appointment_config.now_partner_id) of
										Config2 when is_record(Config2, ets_appointment_config) ->
											lib_appointment:update_appointment_both(
											  Config#ets_appointment_config{begin_time = NowTime, last_exp_time = NowTime, step = 4}
											  ,Config2#ets_appointment_config{begin_time = NowTime, last_exp_time = NowTime, step = 4}
											  ,0);
										_ ->
											lib_appointment:update_appointment_config(
											  Config#ets_appointment_config{begin_time = NowTime, last_exp_time = NowTime, step = 4}, 1)
									end,
									PartnerId = Config#ets_appointment_config.now_partner_id,
									PlayerId = Config#ets_appointment_config.id,
									PartnerName = lib_appointment:get_partner_name(PartnerId),
									SelfName = lib_appointment:get_partner_name(PlayerId),
									{ok, BinDataX1} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PartnerId, PartnerName, 0, 1]),
									lib_unite_send:send_to_one(PlayerId, BinDataX1),
									{ok, BinDataX2} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PlayerId, SelfName, 0, 0]),
									lib_unite_send:send_to_one(PartnerId, BinDataX2)
							end;
						false ->
							ok
					end
			end
	end,
	ok;

%% 广播蜡烛-获取场景蜡烛 - 已经没有蜡烛了
handle(27006, _Status, broadcast_candle) -> 
    ?DEBUG("handle_appointment no match", [27006]);

%% 用于上线获取_改变为只发送,无接受了
handle(27021, _Status, send_questions) ->
	?DEBUG("handle_appointment no match", [27021]);

%% 获取双方情缘次数
handle(27065, Status, _) -> 
    %% 必须男女组队接受考验
    case is_pid(Status#player_status.pid_team) of
        false ->
            Num = 0,
            Res = 2;
        true ->
            %% 只否2人组队
            MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),
            case length(MemberIdList) =:= 2 of
                false ->
                    Num = 0,
                    Res = 2;
                true -> 
                    NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
                    [ParnerId] = NewMemberIdList,
                    %%                    %% 必须男方为队长进行预约
                    %%                    case Status#player_status.leader =:= 1 andalso Status#player_status.sex =:= 1 of
                    %%                        false ->
                    %%                            Num = 0,
                    %%                            Res = 3;
                    %%                        true ->
                    %% 必须男女组队
                    [_ParnerName, ParnerSex, _ParnerScene, _ParnerCopyId] = case lib_player:get_player_info(ParnerId, loverun) of
                        false -> ["", 0, 0, 0];
                        Any -> Any
                    end,
                    case ParnerSex =:= Status#player_status.sex of
                        true ->
                            Num = 0,
                            Res = 2;
                        false ->
                            %% 男女双方必须在红娘范围内
                            {_Scene, _CopyId, ParnerX, ParnerY} = 
                            case lib_player:get_player_info(ParnerId, position_info) of
                                false -> {0, 0, 0, 0};
                                Any2 -> Any2
                            end,
                            case is_near_matchmaker(ParnerX, ParnerY) =:= true andalso is_near_matchmaker(Status#player_status.x, Status#player_status.y) =:= true of
                                false ->
                                    Num = 0,
                                    Res = 5;
                                true ->
                                    %% 40级以上才能接受任务
                                    ParnerLv = case lib_player:get_player_info(ParnerId, lv) of
                                        false -> 0;
                                        _Lv -> _Lv
                                    end,
                                    case ParnerLv >= 40 andalso Status#player_status.lv >= 40 of
                                        false ->
                                            Num = 0,
                                            Res = 6;
                                        true ->
                                            %% 亲密度不足
                                            case lib_relationship:find_intimacy(Status#player_status.id, ParnerId) >= 998 of
                                                false ->
                                                    Num = 0,
                                                    Res = 4;
                                                true ->
                                                    Num = lib_relationship:find_xlqy_count(Status#player_status.id, ParnerId),
                                                    Res = 1
                                            end
                                    end
                            end
                    end
                    %%                    end
            end
    end,
    {ok, BinData} = pt_270:write(27065, [Res, Num, 22]),
    lib_server_send:send_one(Status#player_status.socket, BinData);
    

%% 错误处理
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("handle_appointment no match", []),
    {error, "handle_appointment no match"}.


%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 					仙侣情缘_功能性函数
%% *****************************************************************************
%% -----------------------------------------------------------------------------


new_point() ->
	PointList = get_point_list(),
	util:rand(1, length(PointList)).

get_point(N) ->
	PointList = get_point_list(),
	lists:nth(N, PointList).

get_point_list()->
	[
	 {168,217},
	 {172,214},
	 {167,210},
	 {161,217},
	 {163,222},
	 {168,223},
	 {162,227},
	 {156,223},
	 {169,230},
	 {171,234},
	 {171,240},
	 {168,243},
	 {165,245},
	 {161,246},
	 {156,246},
	 {153,246},
	 {150,245},
	 {148,244},
	 {143,238},
	 {144,232},
	 {145,225},
	 {147,220},
	 {150,215},
	 {153,215},
	 {156,215},
	 {157,229},
	 {155,231},
	 {151,234},
	 {149,237},
	 {147,239}
	 ].

add_exp(ExpKey, Lv) ->
	case mod_daily_dict:get_special_info(ExpKey) of
		1 ->
			round(Lv*Lv*2*2);
		_ ->
			round(Lv*Lv*2)
	end.

%% 发送题 游戏线
send_question(_, BoyId, GirlId) ->
    %% 这里获取初始问题(即:询问是否开始游戏).
    %% [Comment, Option1, Option2] = data_appointment_text:get_question_text(),
    {ok, BinData} = pt_270:write(27021, [1]),
	lib_server_send:send_to_uid(BoyId, BinData),
	lib_server_send:send_to_uid(GirlId, BinData).

%% 根据亲密度判断可选的额外赠送物品
item_type(Intimacy) ->
   case Intimacy >= 1000 of
        true -> 
            case Intimacy >= 2000 of
                true -> 
                    case Intimacy >= 3000 of
                        true -> 
                            case Intimacy >= 5000 of
                                true -> 
                                    case Intimacy >= 10000 of
                                        true -> 5;	%% 亲密度大于10000
                                        false -> 4	%% 亲密度大于5000
                                    end;
                                false -> 3 %% 亲密度大于3000
                            end;
                        false -> 2 %% 亲密度大于2000
                    end;
                false -> 1  %% 亲密度大于1000
            end;
        false -> 0 %% 亲密度少于1000
    end.


%% 
%% 
%% 													
%% 								
%% 									end;
%% 								
%% 								
%% 							
%% 	
%%     case lib_appointment:check_app(UniteStatus#unite_status.id) of
%%         [] -> ok;
%%         Config -> 
%% 			PartnerId = Config#ets_appointment_config.now_partner_id,
%% 			%% 判断是否已经有日常数据
%% 			%% 邀请次数
%% 	        InventTimes = mod_daily_dict:get_count(PlayerId, 2701),
%% 			%% 被邀请次数
%% 			BeInventedTimes = mod_daily_dict:get_count(PlayerId, 2700),
%% 			NowTime = util:unixtime(), 
%% %% 			io:format("~p~n", [Config#ets_appointment_config.step]),
%% 			%% 判断是否需要清除数据(步骤在送礼物前_伴侣不在线_超出任务时间), 不会清除日常数据
%% 			case Config#ets_appointment_config.step < 1 of
%% 				true -> %% 未送礼物 清除仙侣数据
%% 			        case mod_daily_dict:get_count(PlayerId, 2705) of
%% 						0 ->
%% 							lib_appointment:cancel_appointment_unite(UniteStatus#unite_status.id, PartnerId);
%% 						_ ->
%% 							{ok, BinData} = pt_270:write(27021, [1]),
%% 							lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
%% 							lib_unite_send:send_to_one(PartnerId, BinData)
%% 					end;
%% 				false ->
%% 					case lib_appointment:check_unite_online(PartnerId) of
%% 						PartnerOnline when is_record(PartnerOnline, ets_unite) ->
%% 							case InventTimes =:= 0 andalso BeInventedTimes =:= 0 of
%% 								true -> %% 没有每日记录_清除自己的数据
%% 									lib_appointment:cancel_appointment_unite(UniteStatus#unite_status.id, PartnerId);
%% 								false ->
%% 									PartnerName1 = PartnerOnline#ets_unite.name,
%% 									case Config#ets_appointment_config.step of
%% 										1 ->%% 表示不同意进行小游戏_跳到经验流程
%% 											%% 更新对方
%% 											lib_appointment:update_appointment_config_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 											%% 更新自己
%% 											lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																												   , last_exp_time = NowTime
%% 																												   , step = 4}
%% 																					 , 0),
%% 											{ok, BinData} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 											lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinData),
%% 											lib_unite_send:send_to_one(PartnerId, BinData);
%% 										2 ->%% 抽奖
%% 											case Config#ets_appointment_config.state of
%% 												4 -> %% 主动方,弹出抽奖界面
%% 													{ok, Bin1} = pt_270:write(27026, [2]),
%% %% 													io:format("~p~n", [32]),
%% 													lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, Bin1);
%% 												_ ->
%% 													ok
%% 											end;
%% 										3 ->%% 种花游戏中 
%% 											case lib_appointment:get_appointment_game(Config) of
%% 												[0, 0, 0] ->
%% 													ok;
%% 												[AppGame, MyOpt, _MyOptTime] ->
%% 													case AppGame#ets_appointment_game.flower_id of
%% 														0 ->
%% 															ok;
%% 														FlowerId ->
%% 															TimeLeft = NowTime - AppGame#ets_appointment_game.start_time,
%% 															OptType = MyOpt,
%% 															{_, _, X, Y} = lib_appointment:get_flower_info(FlowerId),
%% 															PrizeType = AppGame#ets_appointment_game.prize_type,
%% 															PartnerNamex = PartnerName1,
%% 															{ok, BinData} = pt_270:write(27030, [PrizeType, OptType, FlowerId, X, Y, TimeLeft, PartnerNamex]),
%% 															lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
%% 													end
%% 											end;
%% 										4 ->%% 经验中
%% 											case NowTime - Config#ets_appointment_config.begin_time =< ?ADD_EXP_TIME of
%% 												true -> %% 约会中_发剩余时间
%% 													%% 更新对方
%% 													lib_appointment:update_appointment_config_by_id(Config#ets_appointment_config.now_partner_id, Config#ets_appointment_config.begin_time),
%% 													%% 更新自己
%% 													lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = Config#ets_appointment_config.begin_time
%% 																														   , last_exp_time = Config#ets_appointment_config.last_exp_time
%% 																														   , step = 4}
%% 																							 , 0),
%% 													%% 跳到 约会流程 约会信息
%% 													{ok, BinData} = pt_270:write(27019, [1, NowTime - Config#ets_appointment_config.begin_time]),
%% 													lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinData),
%% 													lib_unite_send:send_to_one(PartnerId, BinData);
%% 												false -> %% 已经结束 完成任务
%% 													case Config#ets_appointment_config.state of
%% 														4 ->
%% 															lib_appointment:appointment_end_all(Config, 0);
%% 														_ ->
%% 															ok
%% 													end
%% 											end;
%% 										_ ->
%% 											ok
%% 									end
%% 							end;
%%                			 _ -> 
%% 							case InventTimes =:= 0 andalso BeInventedTimes =:= 0 of
%% 								true ->
%% 									%% 没有每日记录_清除自己的数据
%% 									lib_appointment:cancel_appointment_unite(UniteStatus#unite_status.id, PartnerId);
%% 								false ->
%% 									GameKey = case Config#ets_appointment_config.state =:= 4 of
%% 										true ->
%% 											Config#ets_appointment_config.id;
%% 										false ->
%% 											Config#ets_appointment_config.now_partner_id
%% 									end,
%% 									%% 判断仙侣是否已经结束 clear_all_flower_game
%% 									case Config#ets_appointment_config.step =:= 1 
%% 										andalso Config#ets_appointment_config.begin_time =:= 0 
%% 										andalso Config#ets_appointment_config.last_exp_time =:= 0 of
%% 										true -> %% 自己已经回答,但是对方未回答,且未开始约会状态, 直接跳到约会状态
%% 											%% 更新对方
%% 											lib_appointment:update_appointment_config_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 											%% 更新自己
%% 											lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																												   , last_exp_time = NowTime
%% 																												   , step = 4}
%% 																					 , 0),
%% 											%% 清除小游戏信息
%% 											lib_appointment:clear_all_flower_game(GameKey),
%% 											%% 发送约会信息
%% 											{ok, BinData} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 											lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinData),
%% 											lib_unite_send:send_to_one(PartnerId, BinData);
%% 										false ->
%% 										    case Config#ets_appointment_config.step =:= 2 orelse Config#ets_appointment_config.step =:= 3 of
%% 												true ->%% 种花中,且对方不在线 
%% 													%% 更新对方
%% 													lib_appointment:update_appointment_config_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 													%% 更新自己
%% 													lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																														   , last_exp_time = NowTime
%% 																														   , step = 4}
%% 																							 , 0),
%% %% 													io:format("~p~n", [41]),
%% 													%% 清除小游戏信息
%% 													lib_appointment:clear_all_flower_game(GameKey),
%% 													%% 跳到 约会流程 约会信息
%% 													{ok, BinData} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 													lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinData),
%% 													lib_unite_send:send_to_one(PartnerId, BinData);
%% 												false ->
%% 													case NowTime - Config#ets_appointment_config.begin_time =< ?ADD_EXP_TIME of
%% 														true -> %% 约会中_发剩余时间
%% 															%% 更新对方
%% 															lib_appointment:update_appointment_config_by_id(Config#ets_appointment_config.now_partner_id, Config#ets_appointment_config.begin_time),
%% 															%% 更新自己
%% 															lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = Config#ets_appointment_config.begin_time
%% 																																   , last_exp_time = Config#ets_appointment_config.last_exp_time
%% 																																   , step = 4}
%% 																									 , 0),
%% 															%% 清除小游戏信息
%% 															lib_appointment:clear_all_flower_game(GameKey),
%% %% 															io:format(" t ~p~n", [NowTime - Config#ets_appointment_config.begin_time]),
%% 															%% 跳到 约会流程 约会信息
%% 															{ok, BinData} = pt_270:write(27019, [1, NowTime - Config#ets_appointment_config.begin_time]),
%% 															lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinData),
%% 															lib_unite_send:send_to_one(PartnerId, BinData);
%% 														false -> %% 已经结束 完成任务
%% 															case Config#ets_appointment_config.state of
%% 																4 ->
%% 																	lib_appointment:appointment_end_all(Config, 0);
%% 																_ ->
%% 																	ok
%% 															end
%% 													end
%% 											end
%% 									end
%% 							end
%% 					end
%%             end
%%     end,

%% %% 回答是否进行游戏 - 游戏服务器(估计改到公共线比较好)
%% handle(27022, UniteStatus, [AnswerId]) ->
%%     case lib_appointment:check_app(UniteStatus#unite_status.id) of
%%         [] -> ok;
%%         Config ->
%% 			PartnerId = Config#ets_appointment_config.now_partner_id,
%% 			NowTime = util:unixtime(), 
%%             %% 不用再次
%% 			Res = case Config#ets_appointment_config.step < 2 of
%% 					  false ->%% 已经回答过
%% 						  case lib_appointment:check_app(Config#ets_appointment_config.now_partner_id) of
%% 							  [] -> %% 对方不在线
%% 									%% 更新对方
%% 									lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 									%% 更新自己
%% 									lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																										   , last_exp_time = NowTime
%% 																										   , step = 4}
%% 																			 , 0),
%% 									%% 跳到 约会流程 约会信息
%% 									{ok, BinDatax} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 									lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinDatax),
%% 									lib_unite_send:send_to_one(PartnerId, BinDatax),
%% 									0;
%% 							  TargetPlayerApp -> 
%% 								  	case TargetPlayerApp#ets_appointment_config.step < 2 of
%% 										false ->
%% 											%% 更新对方
%% 											lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 											%% 更新自己
%% 											lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																												   , last_exp_time = NowTime
%% 																												   , step = 4}
%% 																					 , 0),
%% 											%% 跳到 约会流程 约会信息
%% 											{ok, BinDatax} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 											lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinDatax),
%% 											lib_unite_send:send_to_one(PartnerId, BinDatax),
%% 											0;
%% 										true ->
%% 											3
%% 									end
%% 						  end;
%% 					  true -> 
%% 						  case lib_appointment:check_app(Config#ets_appointment_config.now_partner_id) of
%% 							  [] -> 
%% 									%% 更新对方
%% 									lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 									%% 更新自己
%% 									lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																										   , last_exp_time = NowTime
%% 																										   , step = 4}
%% 																			 , 0),
%% 									%% 跳到 约会流程 约会信息
%% 									{ok, BinDatax} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 									lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinDatax),
%% 									lib_unite_send:send_to_one(PartnerId, BinDatax),
%% 									0;
%% 							  TargetPlayerApp -> 
%% 								  case AnswerId =:= 0 of
%% 									  true -> %% 不进行游戏
%% 										  {ok, Bin1} = pt_270:write(27026, [0]),
%% 										  {ok, Bin2} = pt_270:write(27026, [1]),
%% 										  lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, Bin1),
%% 										  lib_unite_send:send_to_one(TargetPlayerApp#ets_appointment_config.id, Bin2), 
%% 										  %% 更新玩家 双方的仙侣状态为约会中
%% 										  lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 										  %% 更新自己
%% 										  lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																												   , last_exp_time = NowTime
%% 																												   , step = 4}
%% 																					 , 0),
%% 										  %% 跳到 约会流程 约会信息
%% 										  {ok, BinDataxx} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 										  lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinDataxx),
%% 										  lib_unite_send:send_to_one(PartnerId, BinDataxx),
%% 										  1;
%% 									  false -> 
%% 										  case TargetPlayerApp#ets_appointment_config.step == 1 andalso AnswerId =:= 1 of
%% 											  true ->
%% 												  lib_appointment:update_appointment_config(Config#ets_appointment_config{step = 1}, 0),
%% 												  {ok, Bin1} = pt_270:write(27026, [2]),
%% 												  {ok, Bin2} = pt_270:write(27026, [3]),
%% 												  case Config#ets_appointment_config.state =:= 4 of
%% 													  true ->
%% 														  lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, Bin1),
%% 														  lib_unite_send:send_to_one(TargetPlayerApp#ets_appointment_config.id, Bin2);
%% 													  false ->
%% 														  lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, Bin2),
%% 														  lib_unite_send:send_to_one(TargetPlayerApp#ets_appointment_config.id, Bin1)
%% 												  end;
%% 											  false ->
%% 												  %% 对方未答题则只更改自己状态_等待对方答题
%% 												  lib_appointment:update_appointment_config(Config#ets_appointment_config{step = 1}, 0)
%% 										  end,
%% 										  1
%% 								  end
%% 						  end
%% 				  end,
%% 			{ok, BinData} = pt_270:write(27022, [Res]),
%% 			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
%%     end;


%% %%    用于上线获取_已经废弃_获取题目 - 游戏服务器
%% handle(27021, Status, send_questions) ->
%%     case lib_appointment:check_app_self(Status#player_status.id, 1) of
%%         [] -> ok;
%%         Config -> 
%%             {BoyId, GirlId} = case Status#player_status.sex of
%%                 1 -> {Status#player_status.id, 0};
%%                 2 -> {0, Status#player_status.id};
%%                 _ -> {0, 0}
%%             end,
%%             NowTime = util:unixtime(),
%%             case (NowTime - Config#ets_appointment.begin_time) > (?ANSWER_TIME + 40) of
%%                 true -> ok;
%%                 false ->
%% 					send_question(0, BoyId, GirlId)
%%             end
%%     end;
%% %%    请求两位异性玩家 - 公共服务器
%% handle(27000, Status, [Type]) ->
%% 	case ets:lookup(?ETS_UNITE, Status#unite_status.id) of
%%         [] -> ok;
%%         [P] ->
%% 			%% 获取VIP次数
%% 			VipRe = mod_daily_dict:get_count(Status#unite_status.id, 2702),
%% 		    LeftRe = 999-VipRe,
%% 			%% 获取 => 异性
%% 			Sex = 3 - P#ets_unite.sex,
%% 			Realm = P#ets_unite.realm,
%% 			Level = P#ets_unite.lv,
%% 			NowTime = util:unixtime(),
%% 			R = case ets:lookup(?ETS_APPOINTMENT_CONFIG, Status#unite_status.id) of
%% 					[] ->
%% 						%% 找不到玩家的仙侣奇缘信息
%% 						%% 读取数据库并初始化 玩家的 ets_appointment_config
%% 						#ets_appointment_config{id = Status#unite_status.id};
%% 					[R_R] ->
%% 						R_R
%% 				end,
%% 			%% 返回结果
%% 			[Is_Send, Res, Pack_Info, Time_Left, Vip_Left] = case Type of
%% 				 0 -> %% 普通刷新,
%% 					LeftTime = ?REFRESH_TIME - (NowTime - R#ets_appointment_config.refresh_time),
%% 					case LeftTime >= 0 of
%%                         true -> 
%% 							%% 未到刷新时间
%% 							PackL3 = lib_appointment:package_partner(R#ets_appointment_config.rand_ids),
%% 							[1, PackL3, LeftTime, LeftRe];
%%                         false -> 
%% 							case lib_appointment:rand_partners(Status#unite_status.pid, R, [Sex, Realm, Level]) of %% 随机挑选伴侣
%%                                 [] ->
%%                                     ets:insert(?ETS_APPOINTMENT_CONFIG, R#ets_appointment_config{refresh_time = NowTime, rand_ids = []}),  
%% 									[0, 0, [], ?REFRESH_TIME, LeftRe];
%%                                 L2 ->
%%                                     ets:insert(?ETS_APPOINTMENT_CONFIG, R#ets_appointment_config{refresh_time = NowTime, rand_ids = L2}),
%%                                     PackL2 = lib_appointment:package_partner(L2),			
%% 									[0, 1, PackL2, ?REFRESH_TIME, LeftRe]
%%                             end
%%                     end;
%% 				 1 -> %% 元宝刷新
%% 					case LeftRe > 0 of %% vip有免费即时刷新
%%                         true -> 
%%                             mod_daily_dict:increment(Status#unite_status.id, 2702), %% 使用次数+1
%%                             case lib_appointment:rand_partners(Status#unite_status.pid, R, [Sex, Realm, Level]) of %% 随机挑选伴侣
%%                                 [] ->
%%                                     ets:insert(?ETS_APPOINTMENT_CONFIG, R#ets_appointment_config{refresh_time = NowTime, rand_ids = []}),  
%%                                     [0, 0, [], ?REFRESH_TIME, LeftRe-1];
%%                                 L2 ->
%%                                     ets:insert(?ETS_APPOINTMENT_CONFIG, R#ets_appointment_config{refresh_time = NowTime, rand_ids = L2}),
%%                                     PackL2 = lib_appointment:package_partner(L2),		
%%                                     [0, 1, PackL2, ?REFRESH_TIME, LeftRe]
%%                             end;
%%                         false -> 
%% 							case lib_appointment:rand_partners(Status#unite_status.pid, R, [Sex, Realm, Level]) of
%%                                 [] -> 
%% 									lib_appointment:gold_refresh_partner(Status#unite_status.id, [], R#ets_appointment_config.refresh_time, LeftRe),
%%                                 	[1, 0,0,0,0];
%% 								L2 ->
%%                                     PackL4 = lib_appointment:package_partner(L2),
%% 									lib_appointment:gold_refresh_partner(Status#unite_status.id, PackL4, R#ets_appointment_config.refresh_time, LeftRe),
%%                             		[1, 0,0,0,0]
%% 							end
%%                     end
%% 			end,
%% 			case Is_Send of
%% 				0 ->
%% 					{ok, BinData} = pt_270:write(27000, [Res, Pack_Info, Time_Left, Vip_Left]),
%%             		lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);
%% 				1 ->
%% 					%% 已经通过cast 发送了
%% 					skip
%% 			end
%% 	end;
%% %% 回答是否进行游戏 - 游戏服务器(估计改到公共线比较好)
%% handle(27022, UniteStatus, [AnswerId]) ->
%%     case lib_appointment:check_app(UniteStatus#unite_status.id) of
%%         [] -> ok;
%%         Config ->
%% 			PartnerId = Config#ets_appointment_config.now_partner_id,
%% 			NowTime = util:unixtime(), 
%%             %% 不用再次
%% 			Res = case Config#ets_appointment_config.step < 2 of
%% 					  false ->%% 已经回答过
%% 						  case lib_appointment:check_app(Config#ets_appointment_config.now_partner_id) of
%% 							  [] -> %% 对方不在线
%% 									%% 更新对方
%% 									lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 									%% 更新自己
%% 									lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																										   , last_exp_time = NowTime
%% 																										   , step = 4}
%% 																			 , 0),
%% 									%% 跳到 约会流程 约会信息
%% 									{ok, BinDatax} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 									lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinDatax),
%% 									lib_unite_send:send_to_one(PartnerId, BinDatax),
%% 									0;
%% 							  TargetPlayerApp -> 
%% 								  	case TargetPlayerApp#ets_appointment_config.step < 2 of
%% 										false ->
%% 											%% 更新对方
%% 											lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 											%% 更新自己
%% 											lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																												   , last_exp_time = NowTime
%% 																												   , step = 4}
%% 																					 , 0),
%% 											%% 跳到 约会流程 约会信息
%% 											{ok, BinDatax} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 											lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinDatax),
%% 											lib_unite_send:send_to_one(PartnerId, BinDatax),
%% 											0;
%% 										true ->
%% 											3
%% 									end
%% 						  end;
%% 					  true -> 
%% 						  case lib_appointment:check_app(Config#ets_appointment_config.now_partner_id) of
%% 							  [] -> 
%% 									%% 更新对方
%% 									lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 									%% 更新自己
%% 									lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																										   , last_exp_time = NowTime
%% 																										   , step = 4}
%% 																			 , 0),
%% 									%% 跳到 约会流程 约会信息
%% 									{ok, BinDatax} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 									lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinDatax),
%% 									lib_unite_send:send_to_one(PartnerId, BinDatax),
%% 									0;
%% 							  TargetPlayerApp -> 
%% 								  case AnswerId =:= 0 of
%% 									  true -> %% 不进行游戏
%% 										  {ok, Bin1} = pt_270:write(27026, [0]),
%% 										  {ok, Bin2} = pt_270:write(27026, [1]),
%% 										  lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, Bin1),
%% 										  lib_unite_send:send_to_one(TargetPlayerApp#ets_appointment_config.id, Bin2), 
%% 										  %% 更新玩家 双方的仙侣状态为约会中
%% 										  lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 										  %% 更新自己
%% 										  lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																												   , last_exp_time = NowTime
%% 																												   , step = 4}
%% 																					 , 0),
%% 										  %% 跳到 约会流程 约会信息
%% 										  {ok, BinDataxx} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 										  lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinDataxx),
%% 										  lib_unite_send:send_to_one(PartnerId, BinDataxx),
%% 										  1;
%% 									  false -> 
%% 										  {ok, Bin1} = pt_270:write(27026, [0]),
%% 										  {ok, Bin2} = pt_270:write(27026, [1]),
%% 										  lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, Bin1),
%% 										  lib_unite_send:send_to_one(TargetPlayerApp#ets_appointment_config.id, Bin2), 
%% 										  %% 更新玩家 双方的仙侣状态为约会中
%% 										  lib_appointment:update_appconfig_partner_by_id(Config#ets_appointment_config.now_partner_id, NowTime),
%% 										  %% 更新自己
%% 										  lib_appointment:update_appointment_config(Config#ets_appointment_config{begin_time = NowTime
%% 																												   , last_exp_time = NowTime
%% 																												   , step = 4}
%% 																					 , 0),
%% 										  %% 跳到 约会流程 约会信息
%% 										  {ok, BinDataxx} = pt_270:write(27019, [1, ?ADD_EXP_TIME]),
%% 										  lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinDataxx),
%% 										  lib_unite_send:send_to_one(PartnerId, BinDataxx),
%% 										  1
%% 								  end
%% 						  end
%% 				  end,
%% 			{ok, BinData} = pt_270:write(27022, [Res]),
%% 			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
%%     end;

%% 是否在红娘附近
is_near_matchmaker(X, Y) ->
    case (X - 170) * (X - 170) + (Y - 211) * (Y - 211) =< 100 of
        true -> true;
        false -> false
    end.
