%% --------------------------------------------------------
%% @Module:           |lib_appointment
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-03-22 
%% @Description:      |仙侣奇缘_功能处理  
%% --------------------------------------------------------

-module(lib_appointment).

-compile(export_all).
-include("common.hrl").
-include("scene.hrl").
-include("unite.hrl").
-include("rela.hrl").
-include("server.hrl").
-include("appointment.hrl").
-include("task.hrl").

%-------------------------------------------------------------------------------
%								公共服务器	 
%-------------------------------------------------------------------------------
 
%% 上线初始化_读取数据库_写入ETS表  
online_unite(Id) -> 
   case get_appointment_config(Id) of
		R when is_record(R, ets_appointment_config) ->
			case R#ets_appointment_config.step =:= 3 of
				false ->
					skip;
				true -> %% 在种花游戏中 检查APP GAME 信息
					get_appointment_game(R)
			end,
			R#ets_appointment_config.now_partner_id;
		_ ->
			0
	end.

%% 下线保存_清除ETS数据_更新数据库
offline_unite(Id) -> 
    case ets:lookup(?ETS_APPOINTMENT_CONFIG, Id) of
        [] -> ok;
        [R] -> 			
            update_appointment_config(R, 2),
            ets:delete(?ETS_APPOINTMENT_CONFIG, Id),
			case R#ets_appointment_config.step < 1 of
				true ->
					lib_appointment:cancel_appointment_unite(R#ets_appointment_config.id, R#ets_appointment_config.now_partner_id);
				false ->
					skip
			end,
			PlayerId = Id,
			PartnerId = R#ets_appointment_config.now_partner_id,
			case check_unite_online(PartnerId) of
				[] -> %% 对方也下线了
					Game_Key = case R#ets_appointment_config.state =:= 4 of
						true -> %% 自己是主动方
							Id;
						false -> %% 自己是被邀请方
							PartnerId
					end,
					case ets:lookup(?ETS_APPOINTMENT_GAME, Game_Key) of
						[] -> %% 仙侣小游戏数据已经不存在
							ok;
						[Game] ->
							%% 回写数据库
							update_appointment_game(Game, 2),
							%% 清除GAME表
    						ets:delete(?ETS_APPOINTMENT_GAME, Game_Key)
					end;
				_ ->
					NowTime = util:unixtime(),
					case R#ets_appointment_config.state =:= 4 of
						true ->
							case R#ets_appointment_config.step of
								1 -> %% 通知对方进入经验状态
									case R#ets_appointment_config.begin_time =:= 0 of
										true ->
											lib_appointment:update_appointment_config(R#ets_appointment_config{begin_time = NowTime
																														, last_exp_time = NowTime
																														, step = 4}
																													 , 0),
											%% 更新对方
											lib_appointment:update_appconfig_partner_by_id(PartnerId, NowTime),
											PartnerName = lib_appointment:get_partner_name(PartnerId),
											SelfName = lib_appointment:get_partner_name(PlayerId),
											{ok, BinData1} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PartnerId, PartnerName, 0, 1]),
											lib_unite_send:send_to_one(PlayerId, BinData1),
											{ok, BinData2} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PlayerId, SelfName, 0, 0]),
											lib_unite_send:send_to_one(PartnerId, BinData2);
										false ->
											skip
									end;
								2 -> %% 通知对方进入经验状态
									case R#ets_appointment_config.begin_time =:= 0 of
										true ->
											lib_appointment:update_appointment_config(R#ets_appointment_config{begin_time = NowTime
																														, last_exp_time = NowTime
																														, step = 4}
																													 , 0),
											%% 更新对方
											lib_appointment:update_appconfig_partner_by_id(PartnerId, NowTime),
											PartnerName = lib_appointment:get_partner_name(PartnerId),
											SelfName = lib_appointment:get_partner_name(PlayerId),
											{ok, BinData1} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PartnerId, PartnerName, 0, 1]),
											lib_unite_send:send_to_one(PlayerId, BinData1),
											{ok, BinData2} = pt_270:write(27019, [1, ?ADD_EXP_TIME, 6, PlayerId, SelfName, 0, 0]),
											lib_unite_send:send_to_one(PartnerId, BinData2);
										false ->
											skip
									end;
								_ ->
									skip
							end;
						false ->
							ok
					end
			end
    end.



%% 更改个人配置的刷新时间和伴侣
set_appointment_config(Id, RefreshTime, RandIds) ->
    case ets:lookup(?ETS_APPOINTMENT_CONFIG, Id) of
        [] -> ok;
        [R] ->
            ets:insert(?ETS_APPOINTMENT_CONFIG, R#ets_appointment_config{refresh_time = RefreshTime, rand_ids = RandIds})
    end.

%% 更改伴侣 双方的伴侣 在开始 和结束的时候调用
%% @param Type: 约会状态(0: 无约会,4：邀请方,5：被邀请方)
set_partner_unite(PlayerId, Values, Type) ->
    case mod_chat_agent:lookup(PlayerId) of
        [] -> ok;
        [R1] ->
            mod_chat_agent:insert(R1#ets_unite{appointment = Values})
    end,
    case ets:lookup(?ETS_APPOINTMENT_CONFIG, PlayerId) of
        [] -> 
			%% 为玩家新建一条记录,并写数据库
			update_appointment_config(#ets_appointment_config{id = PlayerId, now_partner_id = Values, state = Type}, 0);
        [Config] ->
            [Recid, RecNum] = case Config#ets_appointment_config.recommend_partner of
                [] -> [0,0];
                Rec -> Rec
            end,
            case Recid =:= Values andalso Type =:= 4 of
                true -> 
                   R = Config#ets_appointment_config{now_partner_id = Values, state = Type, recommend_partner = [Recid, RecNum + 1]},
                   update_appointment_config(R, 0);
                false -> 
                   R = Config#ets_appointment_config{now_partner_id = Values, state = Type},
                   update_appointment_config(R, 0)
            end
    end.
%% 更改伴侣 以及约会状态 游戏线 CAST
set_partner_unite_s(PlayerId, Values, Type) ->
	mod_disperse:cast_to_unite(lib_appointment, set_partner_unite, [PlayerId, Values, Type]).

%% 取消约会_(单方面取消)
cancel_appointment_self(ConfigSelf) ->
	PartnerId = ConfigSelf#ets_appointment_config.now_partner_id,
	PlayerId = ConfigSelf#ets_appointment_config.id,
	ConfigSelfNew = ConfigSelf#ets_appointment_config{last_partner_id = PartnerId
													 , now_partner_id = 0
													 , state = 0
													 , step = 0
													 , begin_time = 0
													 , last_exp_time = 0
													 , gift_type = 0},
	update_appointment_config(ConfigSelfNew, 0),
	%% 同步聊天线玩家仙侣情缘信息
	case mod_chat_agent:lookup(PlayerId) of
		[Player1] when is_record(Player1, ets_unite)->
			mod_chat_agent:insert(Player1#ets_unite{appointment = 0});
		_ ->
			skip
	end,
	{ok, BinData} = pt_270:write(27012, [1]),
	lib_unite_send:send_to_one(PlayerId, BinData).

%% 取消约会_不会返还日常次数 
cancel_appointment_unite(PlayerId, PartnerId) ->
    State = case get_appointment_config(PlayerId) of
        [] -> ok;
        Config when is_record(Config, ets_appointment_config) -> 
			case get_appointment_config(PartnerId) of
				[] -> ok;
				Config2 when is_record(Config2, ets_appointment_config) ->
					update_appointment_both(Config#ets_appointment_config{last_partner_id = PartnerId, now_partner_id = 0, state = 0, step = 0, begin_time = 0, last_exp_time = 0, gift_type = 0}
											  ,Config2#ets_appointment_config{last_partner_id = PlayerId, now_partner_id = 0, state = 0, step = 0, begin_time = 0, last_exp_time = 0, gift_type = 0}
											  ,0),
					Config#ets_appointment_config.state;
				_ ->ok
            end;
		_ -> ok
    end,
    %% 通知双方
	update_unite_both(PlayerId, PartnerId),
	case State of
		4 ->
			{ok, BinData} = pt_270:write(27012, [1]),
%% 	io:format("27012 001 : ~p ~n", [State]), 
		    lib_unite_send:send_to_one(PlayerId, BinData),
		    lib_unite_send:send_to_one(PartnerId, BinData);
		5 ->
			{ok, BinDataSelf} = pt_270:write(27012, [1]),
			{ok, BinDataOther} = pt_270:write(27012, [2]),
%% 	io:format("27012 002 : ~p ~n", [State]), 
		    lib_unite_send:send_to_one(PlayerId, BinDataSelf),
		    lib_unite_send:send_to_one(PartnerId, BinDataOther);
		_ ->
			ok
	end.

%%　约会通知 同时更新双方的　ets_unite
update_unite_both(PlayerId, PartnerId) ->
	case mod_chat_agent:lookup(PlayerId) of
		[Player1] when is_record(Player1, ets_unite)->
			mod_chat_agent:insert(Player1#ets_unite{appointment = 0});
		_ ->
			skip
	end,
	case mod_chat_agent:lookup(PartnerId) of
		[Player2] when is_record(Player2, ets_unite)->
			mod_chat_agent:insert(Player2#ets_unite{appointment = 0});
		_ ->
			skip
	end.

%% 取消约会通知
cancel_appointment_msg(PlayerId, PartnerId) ->
    case mod_chat_agent:lookup(PlayerId) of
        [] -> ok;
        [CR] ->
            case mod_chat_agent:lookup(PartnerId) of
                [] ->ok;
                [CR2] ->
                    {ok, BinData} = pt_270:write(27013, [CR#ets_unite.name, CR2#ets_unite.name]),
                    lib_unite_send:send_to_sid(CR#ets_unite.sid, BinData),
                    lib_unite_send:send_to_sid(CR2#ets_unite.sid, BinData)
            end
    end.




%% 清除玩家ets_unite信息
%-------------------------------------------------------------------------------
%								种花小游戏
%-------------------------------------------------------------------------------

%% %% 开始种花_生成鲜花类型怪物_广播给场景
%% %% @return 鲜花的唯一ID
%% flower_game_start(Id, ConfigRecord1, ConfigRecord2, _Status) ->
%% 	case get_appointment_game(Id) of
%% 		error ->
%% 			error;
%% 		AppGame ->
%% 			case AppGame#ets_appointment_game.flower_id =:= 0 of
%% 				false -> %% 已经有花了
%% 					error;
%% 				true ->  %% 没花_抽奖
%% 					%% 更改CONFIG 和 GAME
%% 					update_appointment_both(ConfigRecord1#ets_appointment_config{step = 2}
%% 										   ,ConfigRecord2#ets_appointment_config{step = 2}
%% 										   ,1),
%% 					NP = util:rand(1, 3),
%% 					OP = util:rand(1, 2),
%% 					update_appointment_game(AppGame#ets_appointment_game{opt_type=OP
%% 																		,prize_type=NP}
%% 										   ,1),
%% 					%% 发送刷新结果
%% 					{ok, BinData} = pt_270:write(27029, [1, NP]),
%%     				lib_unite_send:send_to_one(Id, BinData)
%% 			end
%% 	end.

%% 开始种花_生成鲜花类型怪物_广播给场景
%% @return 鲜花的唯一ID
flower_game_start(Id, ConfigRecord1, _Status) ->
	case get_appointment_game(Id) of
		AppGame when is_record(AppGame, ets_appointment_game) ->
			case AppGame#ets_appointment_game.flower_id =:= 0 of
				false -> %% 已经有花了
					error;
				true ->  %% 没花_抽奖
					%% 更改CONFIG 和 GAME
					case lib_appointment:check_app(ConfigRecord1#ets_appointment_config.now_partner_id) of
						[] -> %% 对方不在线,只更改自己的状态
							%% 更改CONFIG 和 GAME
							lib_appointment:update_appointment_config(ConfigRecord1#ets_appointment_config{step = 2}, 1);
						TargetConfig ->
							%% 更改CONFIG 和 GAME
							update_appointment_both(ConfigRecord1#ets_appointment_config{step = 2}
										   ,TargetConfig#ets_appointment_config{step = 2}
										   ,1)
					end,
					NP = util:rand(1, 3),
					OP = util:rand(1, 2),
					update_appointment_game(AppGame#ets_appointment_game{opt_type=OP
																		,prize_type=NP}
										   ,1),
					%% 发送刷新结果
					{ok, BinData} = pt_270:write(27029, [1, NP]),
    				lib_unite_send:send_to_one(Id, BinData)
			end;
		_ ->
			error
	end.

%% 花费元宝刷新奖励
%% @return error 元宝不足 int 新的奖励类型
flower_new_prize(PlayerId, Status) ->
	[Info_Text] = data_appointment_text:get_log_consume_text(xlqy_game, 0),
	case get_appointment_game(PlayerId) of
		error ->
			error;
		AppGame ->
			case lib_player_unite:spend_assets_status_unite(PlayerId, 1, gold, xlqy_flower, Info_Text) of
				{ok, ok} ->
					NP = util:rand(1, 3),
					update_appointment_game(AppGame#ets_appointment_game{prize_type=NP}, 1),
					%% 发送刷新结果
					{ok, BinData} = pt_270:write(27029, [1, NP]),
					lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);
				{error, _IRes} -> %% 扣除元宝失败
					{ok, BinData} = pt_270:write(27029, [2, 0]),
					lib_unite_send:send_to_sid(Status#unite_status.sid, BinData)
			end
	end.

%% 开始种花_生成鲜花类型怪物_广播给场景_修改双方步骤_修改game_发送消息 
%% @return 鲜花的唯一ID
flower_creater(Id, PartnerId, Status) ->		
%% 	io:format("27030 001 : ~p ~n", [Id]), 
	case get_appointment_game(Id) of
		error ->
			ok;
		AppGame ->
			{Prize_type, OptType, FlowerId, X, Y} = case AppGame#ets_appointment_game.flower_status of
				0 ->
					Num = util:rand(1, 15),
					{MonTypeId, ScenseID, _, XL, YL} = get_flower_config(1, Num),
%% 					io:format("MonTypeId, ScenseID : ~p: ~p ~n", [MonTypeId, ScenseID]),
					FlowerIdL = lib_mon:create_mon(MonTypeId, ScenseID, XL, YL, 0, 0, 0, 0),
					%% 把鲜花ID插入定时删除的怪物列表
					timer_clear_mon:insert_mon(FlowerIdL, 102, ?CLEAR_FLOWER_TIME),
					{AppGame#ets_appointment_game.prize_type
					, AppGame#ets_appointment_game.opt_type
					, FlowerIdL, XL, YL};
				_ ->
					%% 已经有花
					{FlowerIdL, _, _, XL, YL} = get_flower_info(AppGame#ets_appointment_game.flower_id),
					{AppGame#ets_appointment_game.prize_type
					, AppGame#ets_appointment_game.opt_type
					, FlowerIdL, XL, YL}
			end,
			%% 更新游戏状态
			NowTime = util:unixtime(),
			update_appointment_game(AppGame#ets_appointment_game{flower_id  = FlowerId,
																 start_time = NowTime, 
																 opt_time = NowTime, 
																 opt_time_helper = NowTime},
																1),
%% 			io:format("FlowerId : ~p ~n", [FlowerId]),
			PartnerName1 = case lib_appointment:check_unite_online(PartnerId) of
                [] -> [];
                Partner1 -> 
					Partner1#ets_unite.name
            end,
			PartnerName2 = case lib_appointment:check_unite_online(Id) of
                [] -> [];
                Partner2 -> 
					Partner2#ets_unite.name
            end,
			{ok, BinData} = pt_270:write(27030, [Prize_type, OptType, FlowerId, X, Y, ?APP_GAME_TIME, PartnerName1]),
			lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
			OptType_P = 3 - OptType,
			{ok, BinData2} = pt_270:write(27030, [Prize_type, OptType_P, FlowerId, X, Y, ?APP_GAME_TIME, PartnerName2]),
			lib_unite_send:send_to_one(PartnerId, BinData2)
	end.

%% 获取鲜花信息
get_flower_info(FlowerId) ->
	%% 不知道失败会返回什么
	Flower = lib_mon:get_mon_info_by_id(102, FlowerId),
	{FlowerId, Flower#ets_mon.scene, Flower#ets_mon.x, Flower#ets_mon.y}.

%% 清除鲜花_公共线调用好像有问题
delete_flower_info(FlowerId, _Id) ->
	lib_mon:clear_scene_mon_by_id(102, FlowerId, 1).

%% 定时刷新的鲜花状态(响应客户端)
flower_new_status(Config, AppGame, Status) ->
	Np1 = util:rand(1, 2),
	Np2 = util:rand(3, 4),
	%% 获取当前鲜花状态
	FlowerDict = unpack_flower_status(0),
	FlowerDict1 = dict:store(Np1, 3, FlowerDict),
	FlowerDict2 = dict:store(Np2, 3, FlowerDict1),
	NewFlowerStatus = pack_flower_status(FlowerDict2),
	%% 更新鲜花状态
	NowTime = util:unixtime(),
	NewAppGame =case Config#ets_appointment_config.state of
					4 ->
						AppGame#ets_appointment_game{flower_status = NewFlowerStatus, opt_time = NowTime};
					5 ->
						AppGame#ets_appointment_game{flower_status = NewFlowerStatus, opt_time_helper = NowTime}
				end,
	update_appointment_game(NewAppGame, 1),
	flower_refresh(Config, NewAppGame, Status).
	
%% 更改鲜花状态 
do_flower(_OptStep, OptFlower, Config, Status) ->
	[AppGame, MyOpt, _MyOptTime] = get_appointment_game(Config),
	case AppGame of
		0 ->
			0;
		_ ->
			case MyOpt of
				0 ->
					0;
				_ ->
					%% 获取当前鲜花状态
					FlowerDict = unpack_flower_status(AppGame#ets_appointment_game.flower_status),
					{ok, OptThis} = dict:find(OptFlower, FlowerDict),
					NewFlowerDict = case MyOpt of
						1 ->%% 除虫
							case OptThis of
								0 ->
									FlowerDict;
								2 ->
									FlowerDict;
								1 ->
									dict:store(OptFlower, 0, FlowerDict);
								3 ->
									dict:store(OptFlower, 2, FlowerDict)
							end;
						2 ->%% 浇水
							case OptThis of
								0 ->
									FlowerDict;
								1 ->
									FlowerDict;
								2 ->
									dict:store(OptFlower, 0, FlowerDict);
								3 ->
									dict:store(OptFlower, 1, FlowerDict)
							end
					end,
					NewFlowerStatus = pack_flower_status(NewFlowerDict),
					%% 这里 增加了积分
					%% 记录首次操作的花朵
					case mod_daily_dict:get_count(Status#unite_status.id, 2705) of
						0 ->
							mod_daily_dict:set_count(Status#unite_status.id, 2705, OptFlower);
						_ ->
							skip
					end,
					NewAppGame = AppGame#ets_appointment_game{score = AppGame#ets_appointment_game.score + 1
																		,flower_status = NewFlowerStatus},
					update_appointment_game(NewAppGame, 1),
					%% 返回操作结果
					{ok, BinData} = pt_270:write(27032, [1]),
					lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
					%% 刷新花状态
					flower_refresh(Config, NewAppGame, Status),
					1
			end
	end.

%% 刷新鲜花_状态: 这里不更改花的状态
flower_refresh(Config, AppGame, _Status) ->%% 
	[F1, F2, F3, F4] = unpack_flower_status_4(AppGame#ets_appointment_game.flower_status),
	NowTime = util:unixtime(),
	TimeLeft = AppGame#ets_appointment_game.start_time + ?APP_GAME_TIME - NowTime,
	TotleScore = AppGame#ets_appointment_game.score,
%%  	io:format("do_flower[F1, F2, F3, F4] : ~p ~n", [[F1, F2, F3, F4, TimeLeft, TotleScore]]),
  	{ok, BinData} = pt_270:write(27031, [F1, F2, F3, F4, TimeLeft, TotleScore]),
	lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinData),
    lib_unite_send:send_to_one(Config#ets_appointment_config.now_partner_id, BinData),
	%% 判断是否需要开花
	case AppGame#ets_appointment_game.flower_status of
		0 ->
			{Res, New1, New2} = case mod_daily_dict:get_count(Config#ets_appointment_config.id, 2705) of
				0 ->
					{1, 1, 0};
				OptStep1 ->
					case mod_daily_dict:get_count(Config#ets_appointment_config.now_partner_id, 2705) of
						0 ->
							mod_daily_dict:set_count(Config#ets_appointment_config.id, 2705, 0),
							{1, 1, 0};
						OptStep2 ->
							mod_daily_dict:set_count(Config#ets_appointment_config.id, 2705, 0),
							mod_daily_dict:set_count(Config#ets_appointment_config.now_partner_id, 2705, 0),
							case OptStep1 == OptStep2 of
								false ->
									{1, 1, 0};
								true ->
									{2, 1, 1}
							end
					end
			end,
			NewAppGame = AppGame#ets_appointment_game{bloom_num = AppGame#ets_appointment_game.bloom_num + New1
																,double_num =  AppGame#ets_appointment_game.double_num + New2},
			update_appointment_game(NewAppGame, 1),
			%% 未加入并蒂判断
			flower_bloom(Res
						, NewAppGame#ets_appointment_game.bloom_num
						, NewAppGame#ets_appointment_game.double_num 
						, Config),
			1;
		_ ->
			0
	end.

%% 开花 通知双方
flower_bloom(Res, TotleFlower, DoubleFlower, Config) ->
	{ok, BinData} = pt_270:write(27033, [Res, TotleFlower, DoubleFlower]),
	lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinData),
    lib_unite_send:send_to_one(Config#ets_appointment_config.now_partner_id, BinData).

%% 通知双方 鲜花流程结束
flower_game_end(Config, AppGame, Status) ->
	%% 清除鲜花游戏信息
	case Config#ets_appointment_config.state =:= 4 of
		true ->
			%% 传闻
			case AppGame#ets_appointment_game.score > 300 of
				false ->
					skip;
				true ->
					%%
					[IdF, RealmF, NicknameF, SexF, CareerF, IimageF] = lib_player:get_player_info(Config#ets_appointment_config.id, sendTv_Message),
					[IdT, RealmT, NicknameT, SexT, CareerT, IimageT] = lib_player:get_player_info(Config#ets_appointment_config.now_partner_id, sendTv_Message),
					lib_chat:send_TV({all},1, 2
									,[xianlv
									 ,1
									 ,IdF
									 ,RealmF
									 ,NicknameF
									 ,SexF
									 ,CareerF
									 ,IimageF
									 ,IdT
									 ,RealmT
									 ,NicknameT
									 ,SexT
									 ,CareerT
									 ,IimageT
									 ,AppGame#ets_appointment_game.score
									 ])
			end,
			delete_flower_info(AppGame#ets_appointment_game.flower_id
					  , Config#ets_appointment_config.id);
		false ->
			skip
	end,
	%% 清除场景鲜花
	{Type, Num} = case AppGame#ets_appointment_game.prize_type of
		1 ->%% 1  经验 等级*等级*积分/10	
			Level = Status#unite_status.lv,
			GameScore = AppGame#ets_appointment_game.score,
			Add = (Level * Level * GameScore) div 10,
			%% 增加经验
			lib_player:update_player_info(AppGame#ets_appointment_game.id, [{add_exp, Add}]),
			{1, Add};
		2 ->%% 2  双倍经验 等级*等级*积分/5	
			Level = Status#unite_status.lv,
			GameScore = AppGame#ets_appointment_game.score,
			Add = (Level * Level * GameScore) div 5,
			%% 双倍经验
			lib_player:update_player_info(AppGame#ets_appointment_game.id, [{add_exp, Add}]),
			{2, Add};
		3 ->%% 3  亲密度
			Level = Status#unite_status.lv,
			GameScore = AppGame#ets_appointment_game.score,
			%% 增加亲密度
			Add = (Level * GameScore * 10) div 15,
			%% 亲密度:100 + 默契度
			      Pid = lib_player:get_player_info(Status#unite_status.id, pid),
			      lib_relationship:update_Intimacy(Pid, AppGame#ets_appointment_game.id, Config#ets_appointment_config.now_partner_id, Add),
			{3, Add};
		_ ->
			{0, 0}
	end, 
	case Type of
		0 ->
			skip;
		_ ->
			%% 通知双方送花结束 并发送奖励信息
			{ok, BinData} = pt_270:write(27034, [Type, Num]),
			lib_unite_send:send_to_one(Config#ets_appointment_config.id, BinData),
		    lib_unite_send:send_to_one(Config#ets_appointment_config.now_partner_id, BinData)
	end.

%-------------------------------------------------------------------------------
%								任务相关_在游戏线
%-------------------------------------------------------------------------------
%% 取消情缘任务
cancel_appointment_task(PS, _RT) ->
	case check_app_s(PS#player_status.id) of
		[] ->
			{ok, BinData} = pt_270:write(27015, [0, 0, <<"">>, 0]),
            lib_server_send:send_one(PS#player_status.socket, BinData),
            true;
		Config ->
			 case Config#ets_appointment_config.state =:= 5 of %% 3表示为被邀请方
                true -> 
                    true;
                false ->
                    case Config#ets_appointment_config.now_partner_id of
                        0 -> true;
                        PartnerId -> 
                            mod_disperse:cast_to_unite(lib_appointment, cancel_appointment_unite, [PS#player_status.id, PartnerId]),
                            mod_disperse:cast_to_unite(lib_appointment, cancel_appointment_msg, [PS#player_status.id, PartnerId])
                    end,
                    true
            end
	end.

%% 完成仙侣奇缘任务
finish_task(TaskId, ParamList, PS) ->
    lib_qixi:update_player_task(PS#player_status.id, 6),
	case check_app_s(PS#player_status.id) of
		[] ->
			%% 玩家不在线
			mod_task:normal_finish(TaskId, ParamList, PS);
		_Config ->
			mod_task:normal_finish(TaskId, ParamList, PS, 1)
	end.

%% 接受仙侣奇缘任务
trigger(Id) ->
	%% 判断今日做任务次数
	%% 判断任务进行状态:判断
	case check_unite_online_s(Id) of
		[] ->
			%% 玩家不在线
			set_partner_unite_s(Id, 0, 0);
		_Eu ->
			case check_app_s(Id) of
				[] ->
					%% 玩家不在线
					set_partner_unite_s(Id, 0, 0);
				_Config ->
					ok
			end
	end.

%-------------------------------------------------------------------------------
%								获取信息以及验证
%-------------------------------------------------------------------------------

%% 判断主动方玩家的ETS_APPOINTMENT_CONFIG信息
%% @return:   							ets_appointment_config
%% @return:   							[] 表示玩家不在线或APP信息不正常
check_app(PlayerId) ->
	case ets:lookup(?ETS_APPOINTMENT_CONFIG, PlayerId) of
		[] -> 
			[];
		[APPConfig] when is_record(APPConfig, ets_appointment_config)->
			APPConfig;
		_ ->
			[]
	end.

%% 判断被动方玩家ETS_APPOINTMENT_CONFIG信息,从游戏线判断
%% @return:   							ets_appointment_config 
%% @return:   							[] 表示玩家不在线或APP信息不正常
check_app_s(PlayerId) ->
	mod_disperse:call_to_unite(lib_appointment, check_app, [PlayerId]).

%% 判断被动方玩家公共线在线信息 
%% @return:   							ets_unite  表示玩家在线
%% @return:   							[] 表示玩家不在线
check_unite_online(PlayerId) ->
	case mod_chat_agent:lookup(PlayerId) of
		[] ->
			[];
		[Player] when is_record(Player, ets_unite)->
			Player;
		_ ->
			[]
	end.
%% 判断被动方玩家公共线在线信息,从游戏线判断
%% @return:   							ets_unite  表示玩家在线
%% @return:   							[] 表示玩家不在线
check_unite_online_s(PlayerId) ->
	mod_disperse:call_to_unite(lib_appointment, check_unite_online, [PlayerId]).

%% 从游戏线判断 修改玩家的 ets_appointment_config
%% @param:		
%% @return:   							[ets_appointment_config, ets_appointment_config] 表示双方都在线且APP信息正常
update_app_config_s(NewAppConfig, Type) ->
	mod_disperse:call_to_unite(lib_appointment, update_appointment_config, [NewAppConfig, Type]).


%-------------------------------------------------------------------------------
%							查找及组装仙侣情缘玩家信息	
%-------------------------------------------------------------------------------
%% 组装伴侣
package_partner(L) ->
	case L of
		[] ->
			[];
		_ ->
			lists:map(fun([_Id, _Nick, _Type1, _Type2]) ->
							case lib_player:get_player_info(_Id, goods) of
								LBGOOD when is_record(LBGOOD, status_goods) ->
									[E1, E2| _] = LBGOOD#status_goods.equip_current,
									case mod_chat_agent:lookup(_Id) of
										  [] -> [_Id, _Nick, _Type1, _Type2, 0, 0, 0, 0, E1, E2];
										  [R1] -> [_Id, _Nick, _Type1, _Type2, R1#ets_unite.sex, R1#ets_unite.lv, R1#ets_unite.career, R1#ets_unite.realm, E1, E2]
									end;
								_ ->
									case mod_chat_agent:lookup(_Id) of
										  [] -> [_Id, _Nick, _Type1, _Type2, 0, 0, 0, 0, 0, 0];
										  [R1] -> [_Id, _Nick, _Type1, _Type2, R1#ets_unite.sex, R1#ets_unite.lv, R1#ets_unite.career, R1#ets_unite.realm, 0, 0]
									end
							end
			end, L)
	end.

%% 寻找伴侣
%% Sex: 1 男；2 女
find_partners(_Ets_unite_pid, Sex) ->
	%% 先获取所有35级以上_未做过仙侣情缘任务的异性的ID和名字
%%  case ets:select(?ETS_UNITE, [{#ets_unite{id = '$1', name = '$2', lv = '$3', sex = Sex, realm = '$4', appointment = 0, _ = '_'}, [{'>=', '$3', 35}], [['$1', '$2', '$3', '$4']]}]) of
    case mod_chat_agent:match(find_partners, [35, Sex]) of
        [] -> [];
        R1 ->
			%% 判断今天做过的仙侣情缘任务次数
			[[Id, Nick, Level, Realm] || [Id, Nick, Level, Realm] <- R1, mod_daily_dict:get_count(Id, 2700) < 2]
    end.

%% 随机选择6种类型中的3中获取3个异性
%% 同国,等级,魅力排行,亲密度,随机,
rand_partners(UniteStatus, R, [Sex, Realm, Level]) ->
	%% 获取符合基本资格的玩家列表[ID,NICKNAME,XLQY_daily_0]
    _DFDF = case find_partners(UniteStatus#unite_status.pid, Sex) of
        [] -> [];
        L_Base ->
			%% 根据七种条件选出 0 - 7 个 不同的人
			NormalList = get_partner_by_type(UniteStatus, L_Base, R, [Sex, Realm, Level], 0),
			NormalList2 = lists:filter(fun(D) -> D =/= [] end, NormalList),
			case NormalList2 of
				[] ->
					[];
				A_NormalList ->
					rand_N(A_NormalList, [], 0)
			end
    end.

%% 去掉xiangto
rand_N([], ListAns, _) ->
	ListAns;
rand_N(_, ListAns, 3) ->
	ListAns;
rand_N(ListS, ListAns, Num) ->
	N1 = util:rand(1, length(ListS)),
	K = lists:nth(N1, ListS),
	ListAnsNext = [K|ListAns],
	ListSNext = lists:delete(K, ListS),
	NumNext = Num + 1,
  	rand_N(ListSNext, ListAnsNext, NumNext).

%% 根据类型获取推荐玩家
%% 同城>等级>国家>亲密>随机
get_partner_by_type(UniteStatus, L_Base, R, [_Sex, Realm, Level], _Type) ->
	GuildId = UniteStatus#unite_status.guild_id,
	%% 筛选出一个
	Fun = fun(List_This, Type) ->
				  	 ListCondition = case Type of
										 1 ->%% 同城
											 case mod_app:get_location_filter(R#ets_appointment_config.id) of
												 [] ->%% 没有同城
													 [];
												 SameLocation ->
													 lists:filter(fun([_Id, _Nick, _Level, _Realm]) -> 
																		  lists:any(fun(OneId) -> _Id =:= OneId end, SameLocation)
																  end, List_This)
											 end;
										 2 ->%% 国家
										     lists:filter(fun([_Id, _Nick, _Level, _Realm]) -> Realm == _Realm end, List_This);
										 3 ->%% 等级
										     lists:filter(fun([_Id, _Nick, _Level, _Realm]) -> _Level >= (Level - 3) andalso _Level =< (Level + 3) end, List_This);
										 4 ->%% 魅力
										     List_This;
										 5 -> %% 亲密度 
											 Pid = lib_player:get_player_info(R#ets_appointment_config.id, pid),
											 Friend_List = lib_relationship:load_relas(Pid, R#ets_appointment_config.id),
											 [[_Id, _Nick, _Level, _Realm] || [_Id, _Nick, _Level, _Realm] <- List_This, B <- Friend_List, B#ets_rela.idB =:= _Id];
										 6 ->%% 随机
										     List_This;
										 7 -> %% 帮派推荐
											 K7 = util:rand(1, 100),
											 case K7 > 15 of
												 true ->
													 [];
												 false ->
													 case mod_chat_agent:match(find_guild_friend, [GuildId]) of
												        [] -> [];
												        G1 ->
															[[_Id, _Nick, _Level, _Realm] || [_Id, _Nick, _Level, _Realm] <- List_This, B <- G1, B =:= _Id]
												     end
											 end;
										 8 -> %% 密友推荐
											 K8 = util:rand(1, 100),
											 case K8 > 12 of
												 true ->
													 [];
												 false ->
													 Pid = lib_player:get_player_info(R#ets_appointment_config.id, pid),
													 Friend_List = lib_relationship:load_relas(Pid, R#ets_appointment_config.id),
													 [[_Id, _Nick, _Level, _Realm] || [_Id, _Nick, _Level, _Realm] <- List_This, B <- Friend_List
													 , B#ets_rela.idB == _Id andalso B#ets_rela.closely =:= 1]
											 end
									 end,
					 case length(ListCondition) of
						 0 ->
							 {[], List_This};
						 L ->
							 K = util:rand(1, L),
							 ChoosenOne = lists:nth(K, ListCondition),
							 [Id, Name, _, _] = ChoosenOne,
							 ListNext = lists:delete(ChoosenOne, List_This),
							 case R#ets_appointment_config.last_partner_id == Id of
								 true ->
									 {[Id, Name, Type, 1], ListNext};
								 false ->
									 {[Id, Name, Type, 0], ListNext}
							 end
					 end
			 end,
	%% 同城 暂时没有,使用随机
	{L_Type1, LeftList1} = Fun(L_Base, 1),
%% 	io:format("1 ~p ~p~n", [L_Type1, LeftList1]),
	%% 国家推荐
	{L_Type2, LeftList2} = Fun(LeftList1, 2),
%% 	io:format("2 ~p ~p~n", [L_Type2, LeftList2]),
	%% 等级推荐
	{L_Type3, LeftList3} = Fun(LeftList2, 3),
%% 	io:format("3 ~p ~p~n", [L_Type3, LeftList3]),
	%% 魅力推荐 等待魅力排行榜接口
	{L_Type4, LeftList4} = Fun(LeftList3, 4),
%% 	io:format("4 ~p ~p~n", [L_Type4, LeftList4]),
	%% 亲密度推荐 #ets_rela
	{L_Type5, LeftList5} = Fun(LeftList4, 5),
%% 	io:format("5 ~p ~p~n", [L_Type5, LeftList5]),
	%% 随机推荐
	{L_Type6, LeftList6} = Fun(LeftList5, 6),
%% 	io:format("6 ~p ~p~n", [L_Type6, _LeftList6]),
	%% 随机推荐
	{L_Type7, LeftList7} = Fun(LeftList6, 7),
%% 	io:format("7 ~p ~p~n", [L_Type7, 0]),
	%% 随机推荐
	{L_Type8, _LeftList8} = Fun(LeftList7, 8),
%% 	io:format("8 ~p ~p~n", [L_Type8, 0]),
	[L_Type1, L_Type2, L_Type3, L_Type4, L_Type5, L_Type6, L_Type7, L_Type8].

%-------------------------------------------------------------------------------
%							ETS_表操作 && 数据库操作	
%-------------------------------------------------------------------------------


%% 获取玩家仙侣CONFIG : ETS没有就读数据库,如果也没有就返回空
get_appointment_config(Id) ->
	case ets:lookup(?ETS_APPOINTMENT_CONFIG, Id) of
		[] ->
			case db_get_appointment_config(Id) of
				0 -> %% 无数据,玩家没有进行过仙侣任务
					NS = #ets_appointment_config{id = Id},
					update_appointment_config(NS, 0),
					NS;
				Config when is_record(Config, ets_appointment_config)->
					Config;
				_ ->
					%% 错误的数据类型
					error
			end;
		[Config] when is_record(Config, ets_appointment_config)->
			Config;
		_ ->
			%% 错误的数据类型
			error
	end.

%% @return AppGame 小游戏记录, MyOpt自己的操作类型, MyOptTime上次自己操作的时间
get_appointment_game(Config) when is_record(Config, ets_appointment_config)->
%% 	io:format("27024 EXP_INTERVAL_TIME 1: ~p ~n", [Config#ets_appointment_config.state]),
	{AppGame, MyOpt, MyOptTime} = case Config#ets_appointment_config.state of
		4 ->
			case get_appointment_game(Config#ets_appointment_config.id) of
				false ->
					{0, 0, 0};
				MAppGame ->
					MOpt = MAppGame#ets_appointment_game.opt_type,
					MYft = MAppGame#ets_appointment_game.opt_time,
					{MAppGame, MOpt, MYft}
			end;
		5 ->
			case get_appointment_game(Config#ets_appointment_config.now_partner_id) of
				false ->
					{0, 0, 0};
				MAppGame ->
					MOpt = 3 - MAppGame#ets_appointment_game.opt_type,
					MYft = MAppGame#ets_appointment_game.opt_time_helper,
					{MAppGame, MOpt, MYft}
			end;
		_ ->
			{0, 0, 0}
	end,
%% 	io:format("27024 EXP_INTERVAL_TIME 2: ~p ~n", [Config#ets_appointment_config.state]),
	[AppGame, MyOpt, MyOptTime];
get_appointment_game(Id) ->
%% 	io:format("27024 EXP_INTERVAL_TIME 3: ~p ~n", [Id]),
	case ets:lookup(?ETS_APPOINTMENT_GAME, Id) of
		[] ->
			case db_get_appointment_game(Id) of
				0 -> %% 无数据
 					NS = #ets_appointment_game{id = Id},
 					update_appointment_game(NS, 0),
 					NS;
				AppGame when is_record(AppGame, ets_appointment_game)->
					AppGame;
				_ ->%% 错误的数据类型
					false
			end;
		[AppGame] when is_record(AppGame, ets_appointment_game)->
			AppGame;
		_ ->%% 错误的数据类型
			false
	end.

%%　同时更新双方的　config
%% @param:    							TYPE => 0:同时更新ETS和数据库 1:只更新ETS 2:只更新数据库
update_appointment_both(ConfigRecord1, ConfigRecord2, Type) ->
	update_appointment_config(ConfigRecord1, Type),
	update_appointment_config(ConfigRecord2, Type).

%% 更新仙侣状态 包含掉线后状态处理
update_appconfig_partner_by_id(PlayerId, NowTime) ->
	case check_app(PlayerId) of
		AppConfig when is_record(AppConfig, ets_appointment_config) ->
			NewAppConfig = AppConfig#ets_appointment_config{begin_time = NowTime, last_exp_time = NowTime, step = 4},
			update_appointment_config(NewAppConfig, 0);
		_ ->
			update_appointment_config_by_id(PlayerId, NowTime)
	end.

%% 更新仙侣状态 只供给上线修正仙侣状态用
update_appointment_config_by_id(PlayerId, NowTime) ->
	case db_get_appointment_config(PlayerId) of
		EAC when is_record(EAC, ets_appointment_config) ->
			NewEAC = EAC#ets_appointment_config{begin_time = NowTime, last_exp_time = NowTime, step = 4},
  			update_appointment_config(NewEAC, 1);
		_ ->
			skip
	end.
  
%% 更新仙侣情缘config
%% @param:    							TYPE => 0:同时更新ETS和数据库 1:只更新ETS 2:只更新数据库
update_appointment_config(InfoConfigRecord, Type) when is_record(InfoConfigRecord, ets_appointment_config) ->
	case Type of
		0 ->
			%% 同时更新ETS和数据库
			ets:insert(?ETS_APPOINTMENT_CONFIG, InfoConfigRecord),
			update_partner_unite(InfoConfigRecord),
			db_update_appointment_config(InfoConfigRecord);
		1 ->
			%% 只更新ETS
			ets:insert(?ETS_APPOINTMENT_CONFIG, InfoConfigRecord),
			update_partner_unite(InfoConfigRecord);
		2 ->
			%% 只更新数据库
			db_update_appointment_config(InfoConfigRecord)
	end.

%% 更新缓存
update_partner_unite(InfoConfigRecord) ->
	PlayerId = InfoConfigRecord#ets_appointment_config.id,
	case mod_chat_agent:lookup(PlayerId) of
        [] -> ok;
        [R1] ->
            mod_chat_agent:insert(R1#ets_unite{appointment = InfoConfigRecord#ets_appointment_config.now_partner_id})
    end.

%% 更新仙侣情缘game
%% @param:    							TYPE => 0:同时更新ETS和数据库 1:只更新ETS 2:只更新数据库
update_appointment_game(InfoGameRecord, Type) when is_record(InfoGameRecord, ets_appointment_game) ->
	case Type of
		0 ->
			%% 同时更新ETS和数据库
			ets:insert(?ETS_APPOINTMENT_GAME, InfoGameRecord),
			db_update_appointment_game(InfoGameRecord);
		1 ->
			%% 只更新ETS
			ets:insert(?ETS_APPOINTMENT_GAME, InfoGameRecord);
		2 ->
			%% 只更新数据库
			db_update_appointment_game(InfoGameRecord)
	end.

%% 更新该玩家的仙侣奇缘配置
db_update_appointment_config(Info_APPC_Record) ->
    RandIds1 = case util:term_to_bitstring(Info_APPC_Record#ets_appointment_config.rand_ids) of
        <<"undefined">> -> <<"[]">>;
        Other -> Other
    end,
    RecommendPartner1 = case util:term_to_bitstring(Info_APPC_Record#ets_appointment_config.recommend_partner) of
        <<"undefined">> -> <<"[]">>;
        Other2 -> Other2
    end,
    Mark1 = case util:term_to_bitstring(Info_APPC_Record#ets_appointment_config.mark) of
        <<"undefined">> -> <<"[]">>;
        Other3 -> Other3
    end,
	IAR = Info_APPC_Record#ets_appointment_config{
												  rand_ids = RandIds1,
												  recommend_partner = RecommendPartner1,
												  mark = Mark1
												  },
	[_|List_APPC] = tuple_to_list(IAR),
	[_|T] = List_APPC,
	Data = List_APPC ++ T,
	SQL  = io_lib:format(?SQL_APPOINTMENT_CONFIG_UPDATE_ONE, Data),
	db:execute(SQL).


%% 读取该玩家的仙侣奇缘配置 
%% @return:   							ets_appointment_config
db_get_appointment_config(Id) ->
	Data = [Id],
	SQL  = io_lib:format(?SQL_APPOINTMENT_CONFIG_SELECT_ONE, Data),		  
	case db:get_all(SQL) of
		[] -> 0;
		[DE] -> 
			%% 转换为RECORD
			DER = lists:reverse(DE),
			[Mark|T1] = DER,
			[RecommendPartner|T2] = T1,
			[RandIds|T3] = T2,
%% 			New_E_A_C = erlang:list_to_tuple([ets_appointment_config|DE]),
			%% 检测修正随机伴侣列表
			RandIds1 = util:string_to_term(erlang:binary_to_list(RandIds)),
			%% 检测修正红颜/蓝颜
			RecommendPartner1 = util:string_to_term(erlang:binary_to_list(RecommendPartner)),
			%% 检测修正仙侣玩家记录
			Mark1 = util:string_to_term(erlang:binary_to_list(Mark)),
			N1 = [RandIds1|T3],
			N2 = [RecommendPartner1|N1],
			N3 = [Mark1|N2],
			NewL = lists:reverse(N3),
			New_E_A_C_N = erlang:list_to_tuple([ets_appointment_config|NewL]),
			%% 插入ETS
			ets:insert(?ETS_APPOINTMENT_CONFIG, New_E_A_C_N),
			New_E_A_C_N
	end.

%% 删除玩家APPOINTMENT_CONFIG表记录
db_delete_appointment_config(Id) ->
	Data = [Id],
	SQL  = io_lib:format(?SQL_APPOINTMENT_CONFIG_DELETE_ONE, Data),
	db:execute(SQL).

%% 更新玩家的仙侣小游戏数据库
db_update_appointment_game(GameInfo) ->
	[_|ListGameInfo] = tuple_to_list(GameInfo),
	[_|T] = ListGameInfo,
	Data = ListGameInfo ++ T,
	SQL  = io_lib:format(?SQL_APPOINTMENT_GAME_UPDATE_ONE, Data),
	db:execute(SQL).

%% 获取玩家仙侣情缘GAME信息
%% @return ETS_APPOINTMENT_GAME
db_get_appointment_game(Id) ->
	Data = [Id],
	SQL  = io_lib:format(?SQL_APPOINTMENT_GAME_SELECT_ONE, Data),		  
	case db:get_all(SQL) of
		[] -> 0;
		[DE] -> 
			%% 转换为RECORD
			erlang:list_to_tuple([?ETS_APPOINTMENT_GAME|DE])
	end.

%% 删除玩家的仙侣game表记录
db_delete_appointment_game(Id) ->
	Data = [Id],
	SQL  = io_lib:format(?SQL_APPOINTMENT_GAME_DELETE_ONE, Data),
	db:execute(SQL).

%%    统计一个列表里面相同元素的个数
count(L) -> count(L, []).
count([], L2) -> lists:reverse(lists:keysort(2, L2));
count(L, L2) -> 
    [H|T] = L,
    NewL2 = case lists:keyfind(H, 1, L2) of
        false -> L2 ++ [{H, 1}];
        {H, Num} -> lists:keyreplace(H, 1, L2, {H, Num + 1})
    end,
    count(T, NewL2).

		             
%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 					仙侣情缘_代码整理区
%% *****************************************************************************
%% -----------------------------------------------------------------------------
	

%% 仙侣情缘任务结束_游戏线
appointment_end_all(Config) ->
	mod_disperse:cast_to_unite(lib_appointment, appointment_end_all, [Config, 0]).
%% 仙侣情缘任务结束_公共线
appointment_end_all(Config, 0) ->	
	PlayerId = Config#ets_appointment_config.id,
	PartnerId = Config#ets_appointment_config.now_partner_id,
	NewConfig = Config#ets_appointment_config{
											 	last_partner_id = Config#ets_appointment_config.now_partner_id,                                                %% 上次的伴侣
											 	now_partner_id = 0,                                                 %% 现在的伴侣
											 	refresh_time = 0,                                                   %% 上次刷新时间
											 	state = 0,                                                          %% 约会状态(4：邀请方,5：被邀请方)
												step = 0,                                                      	 %% 仙侣情缘进行到的步骤
											 	begin_time = 0,                                                     %% 仙侣奇缘约会开始时间
												last_exp_time = 0,                                                  %% 仙侣奇缘上次加经验的时间
												gift_type = 0,                                                 	 %% 礼物类型 物品ID},
												rand_ids = []
											 },
    case Config#ets_appointment_config.state of
        4 -> 
			%% 传闻(不在线就不发送传闻)
			case lib_appointment:check_unite_online(PartnerId) of
				[] -> %% 对方不在线
					skip;
				PlayerStatusT when is_record(PlayerStatusT, ets_unite) ->
					case lib_appointment:check_unite_online(PlayerId) of
						PlayerStatusF when is_record(PlayerStatusF, ets_unite) ->
							%% 亲密度:100 + 默契度
							PlayerPid = lib_player:get_player_info(PlayerId, pid),
							PartnerPid = lib_player:get_player_info(PartnerId, pid),
				 			lib_relationship:update_Intimacy(PlayerPid, PlayerId, PartnerId, 100),
							lib_relationship:update_Intimacy(PartnerPid, PartnerId, PlayerId, 100),
							lib_chat:send_TV({all},1, 2
									,[xianlv
									 ,2
									 ,PlayerStatusF#ets_unite.id
									 ,PlayerStatusF#ets_unite.realm
									 ,PlayerStatusF#ets_unite.name
									 ,PlayerStatusF#ets_unite.sex
									 ,PlayerStatusF#ets_unite.career
									 ,PlayerStatusF#ets_unite.image
									 ,PlayerStatusT#ets_unite.id
									 ,PlayerStatusT#ets_unite.realm
									 ,PlayerStatusT#ets_unite.name
									 ,PlayerStatusT#ets_unite.sex
									 ,PlayerStatusT#ets_unite.career
									 ,PlayerStatusT#ets_unite.image
									 ]);
						_ -> skip
					end;
				_ -> skip
			end,
			%% 完成任务
			finish_task_unite(PlayerId),
			%% 清除缘字
			{ok, BinData} = pt_270:write(27054, 1),
			lib_unite_send:send_to_one(PlayerId, BinData),
			mod_app:remove_two(PlayerId, PartnerId),
			%% 清除游戏数据
			ets:delete(?ETS_APPOINTMENT_GAME, PlayerId),
			db_delete_appointment_game(PlayerId),
			%% 重新7个最近一起情缘的玩家
            Mark = NewConfig#ets_appointment_config.mark,
            MarkL = length(Mark),
            NewMark = case MarkL > 6 of
                true -> [_H|T] = Mark, T ++ [PartnerId];
                false -> Mark ++ [PartnerId]
            end, 
            [{P1, _}|_] = count(NewMark),
			%% 更新红颜/蓝颜
            [Recid, RecNum] = case NewConfig#ets_appointment_config.recommend_partner of
                [] -> [0,0];
                Rec -> Rec
            end,
			ZJHachieve = lib_player:get_player_info(PlayerId, achieve),
			%% 成就：仙侣奇缘，完成仙侣情缘任务N次
			lib_player_unite:trigger_achieve(PlayerId, trigger_task, [ZJHachieve, PlayerId, 10, 0, 1]),
%% 			io:format("27008 000 : ~p : ~p ~n", [Recid, RecNum]),
            case Recid =:= P1 of
                true ->
                    NewRecNum = case RecNum > 3 of
                        true -> 0;
                        false -> RecNum
                    end,
					update_appointment_config(NewConfig#ets_appointment_config{
                            last_partner_id = PartnerId,
                            recommend_partner = [Recid, NewRecNum],
                            mark = NewMark
                        }, 0);
                false ->
                    case P1 =:= PartnerId of
                        true ->
							update_appointment_config(NewConfig#ets_appointment_config{
                                    last_partner_id = PartnerId, 
                                    recommend_partner = [PartnerId, 0], 
                                    mark = NewMark}, 0);
                        false ->
                            update_appointment_config(NewConfig#ets_appointment_config{
                                    last_partner_id = PartnerId,
                                    recommend_partner = [P1, 0],
                                    mark = NewMark}, 0)
                    end
            end;
        _ -> 
			update_appointment_config(NewConfig, 0)
    end.

finish_task_unite(PlayerId) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
%% 			io:format("213 ~p~n", [PlayerId]),
            gen_server:cast(Pid, {'finish_task_unite', PlayerId});
        _ ->
            skip
    end.

%% 位置顺序 X 坐标 Y 坐标  
%% @param Type 1 位置顺序 2 X 坐标 3 Y 坐标 
get_flower_config(Type, Num) ->
	TupleList =
        [
	       	{1, 147, 219}
			,{2, 170, 233}
			,{3, 150, 216}
			,{4, 171, 239}
			,{5, 155, 215}
			,{6, 168, 243}
			,{7, 146, 222}
			,{8, 166, 246}
			,{9, 144, 227}
			,{10, 162, 247}
			,{11, 144, 232}
			,{12, 158, 247}
			,{13, 143, 240}
			,{14, 154, 247}
			,{15, 149, 246}
        ],
	case lists:keyfind(Num, Type, TupleList) of
				false ->
					{0, 0, 0, 0, 0};
				{_, X, Y} ->
					{10005, 102, Num, X, Y}
	end.

%% 分解花状态
%% @return FlowerDict 字典
unpack_flower_status(FlowerStatus) ->
	F4 = FlowerStatus rem 10,
	F3 = (FlowerStatus div 10) rem 10,
	F2 = (FlowerStatus div 100) rem 10,
	F1 = FlowerStatus div 1000,
	FlowerDict = dict:new(),
	FlowerDict1 = dict:store(1, F1, FlowerDict),
	FlowerDict2 = dict:store(2, F2, FlowerDict1),
	FlowerDict3 = dict:store(3, F3, FlowerDict2),
	FlowerDict4 = dict:store(4, F4, FlowerDict3),
	FlowerDict4.

%% 分解花状态_转化成4个INT
%% @return FlowerDict 字典
unpack_flower_status_4(FlowerStatus) ->
	F4 = FlowerStatus rem 10,
	F3 = (FlowerStatus div 10) rem 10,
	F2 = (FlowerStatus div 100) rem 10,
	F1 = FlowerStatus div 1000,
	[F1, F2, F3, F4].

%% 打包花状态
pack_flower_status(FlowerDict) ->
	{ok, F4} = dict:find(4, FlowerDict),
	{ok, F3} = dict:find(3, FlowerDict),
	{ok, F2} = dict:find(2, FlowerDict),
	{ok, F1} = dict:find(1, FlowerDict),
	FlowerStatus = F1*1000 + F2*100 + F3*10 + F4,
	FlowerStatus.

%% 从游戏线获取其他用户的公共线信息
%% @return unite_status {error, 0:玩家不在线,1:玩家公共线信息错误,2:你查询的是自己} 
get_unite_status_server(Id) ->
    mod_disperse:call_to_unite(lib_appointment, get_unite_status_unite, [Id]).

%% 从公共线获取其他用户的公共线信息
%% @return unite_status {error, 0:玩家不在线,1:玩家公共线信息错误,2:你查询的是自己}
get_unite_status_unite(Id) ->
    case mod_chat_agent:lookup(Id) of
        [] ->
            {error, 0};
        [Player] ->
			case Player#ets_unite.pid =:= self() of
				true ->
					{error, 2};
				false ->
					case gen_server:call(Player#ets_unite.pid, 'base_data', 7000) of
						UniteStatus when is_record(UniteStatus, unite_status) ->
							UniteStatus;
						_ ->
							{error, 1}
					end
			end
    end.

%%Description:  						|获取伴侣名字 -> binary()
get_partner_name(Id) ->
    case mod_chat_agent:lookup(Id) of
        [] ->
            Sql = io_lib:format(<<"select nickname from player_low where id = ~p limit 1">>, [Id]),
            case db:get_one(Sql) of
                null -> <<"">>;
                Name -> Name
            end;
        [R] -> list_to_binary(R#ets_unite.name)
    end.

%% 清除单个
clear_all_flower_game(Game_Key) ->
	case ets:lookup(?ETS_APPOINTMENT_GAME, Game_Key) of
		[] -> %% 仙侣小游戏数据已经不存在
			ok;
		[Game] ->
			%% 回写数据库
			update_appointment_game(Game, 2),
			%% 清除GAME表
			ets:delete(?ETS_APPOINTMENT_GAME, Game_Key)
	end.

%% 每日清除种花游戏记录
clear_all_flower_game() ->
	ets:delete_all_objects(?ETS_APPOINTMENT_GAME),
	SQL  = io_lib:format(?SQL_APPOINTMENT_GAME_DELETE_ALL, []),
	db:execute(SQL).
