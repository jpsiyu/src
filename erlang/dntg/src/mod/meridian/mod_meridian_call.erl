%% Author: Administrator
%% Created: 2012-3-15
%% Description: TODO: Add description to mod_meridian_call
-module(mod_meridian_call).
-include("server.hrl").
-include("meridian.hrl").
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([handle_call/3]).

%%
%% API Functions
%%
handle_call({getPlayer_meridian}, _From, Player_meridian) ->
    {reply, Player_meridian, Player_meridian};

handle_call({upMer,PlayerStatus, [MeridianId]}, _From, Player_meridian) ->
	Lev = lib_meridian:get_mer_level(Player_meridian,MeridianId),
	if
		%%检查是否已达最高级
		Lev>=?MERIDIAN_MAX_LV ->
			Result = 5,Reply = ok,State = Player_meridian;
		true ->
			%%检测是否有正在修行的脉
			Mid = Player_meridian#player_meridian.mid,
			case Mid of
				0->	%无正在修炼的元神
					IsCDing = 0;
				_-> %检测是否已修炼完成
					T_Lev = lib_meridian:get_mer_level(Player_meridian,Mid),
					T_D = lib_meridian:get_data_meridian(Mid,T_Lev),
					if
						T_D=:=#data_meridian{} -> 
							IsCDing = 0;
		                true -> 
							GapTime = util:unixtime()-Player_meridian#player_meridian.cdtime,
							if
								T_D#data_meridian.need_cd<GapTime->
									IsCDing = 0;
								true->
									IsCDing = 1
							end
					end
			end,
			case IsCDing of
				1->Result = 9,Reply = ok,State = Player_meridian;
				_->
					%%检测是否满足产品条件
					D = lib_meridian:get_data_meridian(MeridianId,Lev+?MER_UP_GAP),
					if
						D=:=#data_meridian{} -> 
							Result = 6,Reply = ok,State = Player_meridian; 
		                true -> 
							if
								D#data_meridian.need_goods_id=:=0->
									Have_Tupo = true;
								true->
									Tupo = lib_meridian:get_tupo(MeridianId,Player_meridian),
									Have_Tupo = (Lev=<Tupo)
							end,
							case Have_Tupo of
								false->Result = 10,Reply = ok,State = Player_meridian;
								true->
									if
										%%检测玩家等级
										D#data_meridian.need_level>PlayerStatus#player_status.lv ->
											Result = 2,Reply = ok,State = Player_meridian;
										true->
											%%检测玩家前置内功是否达到要求
											case lib_meridian:check_mer_preconditon(Player_meridian,D#data_meridian.preconditon) of
												false->
													Result = 7,Reply = ok,State = Player_meridian;
												true->
													if
														%%检测历练声望
														D#data_meridian.need_llpt>PlayerStatus#player_status.llpt ->
															Result = 4,Reply = ok,State = Player_meridian;
														true->
															if
																%%检测金钱
																D#data_meridian.need_coin>(PlayerStatus#player_status.coin+PlayerStatus#player_status.bcoin) ->
																	Result = 3,Reply = ok,State = Player_meridian;
																true->
																	if
																		%%检测武魂
																		D#data_meridian.need_whpt>PlayerStatus#player_status.whpt->
																			Result = 8,Reply = ok,State = Player_meridian;
																		true->
																		    %%扣除金钱
																			Money = PlayerStatus#player_status.bcoin - D#data_meridian.need_coin,
																			if
																				Money>=0->
																					%%扣除金钱
																					NewPlayer_Status1 = lib_goods_util:cost_money(PlayerStatus, D#data_meridian.need_coin, bcoin),
																					% 写消费日志
																					About = lists:concat(["upMer ",MeridianId," up to ",Lev]),
																					log:log_consume(meridian_upMer, bcoin, PlayerStatus, NewPlayer_Status1, About);
																				true->
																					GapMoney = D#data_meridian.need_coin - PlayerStatus#player_status.bcoin,
																					%%扣除绑定金钱
																					NewPlayer_Status0 = lib_goods_util:cost_money(PlayerStatus, PlayerStatus#player_status.bcoin, bcoin),
																					% 写消费日志
																					About0 = lists:concat(["upMer ",MeridianId," up to ",Lev]),
																					log:log_consume(meridian_upMer, bcoin, PlayerStatus, NewPlayer_Status0, About0),
																					%%扣除非绑定金钱
																					NewPlayer_Status1 = lib_goods_util:cost_money(NewPlayer_Status0, GapMoney, coin),
																					% 写消费日志
																					About = lists:concat(["upMer ",MeridianId," up to ",Lev]),
																					log:log_consume(meridian_upMer, coin, NewPlayer_Status0, NewPlayer_Status1, About)
																			end,
																			%%扣除历练声望
																			_NewPlayerStatus = lib_player:minus_pt(llpt, NewPlayer_Status1, D#data_meridian.need_llpt),
																			%%扣除武魂
																			NewPlayerStatus = lib_player:minus_whpt(_NewPlayerStatus, D#data_meridian.need_whpt),
																			%%更新经脉数据
																			State = lib_meridian:update(Player_meridian,1,MeridianId,Lev+?MER_UP_GAP,0,MeridianId),
																			%%目标
																			case MeridianId of
%% 																				%% 目标303: 将元神攻击提升到10级
%% 																				7->mod_target:trigger(PlayerStatus#player_status.status_target, PlayerStatus#player_status.id, 303, Lev);
%% 																				%% 目标204:将元神防御提升到10级
%% 																				2 -> mod_target:trigger(PlayerStatus#player_status.status_target, PlayerStatus#player_status.id, 204, Lev);
%% 																				%% 目标104: 将元神精气提升到5级
%% 																				1 -> mod_target:trigger(PlayerStatus#player_status.status_target, PlayerStatus#player_status.id, 104, Lev);
                                                                                %% 目标：将心法升到5级 102
                                                                                5 -> mod_target:trigger(PlayerStatus#player_status.status_target, PlayerStatus#player_status.id, 102, Lev);
                                                                                %%  目标：将心法的总等级提升到30级 304
                                                                                10 -> mod_target:trigger(PlayerStatus#player_status.status_target, PlayerStatus#player_status.id, 304, Lev+?MER_UP_GAP);
																				_->void	
																			end,
																			lib_meridian:achieve_sum_yuanshen(PlayerStatus, Player_meridian),
																			Result = 1,
																			Reply = NewPlayerStatus
																	end															
															end
													end
										end
									end
							end
					end
			end
    end,
	{ok,BinData} = pt_250:write(25001,[MeridianId,Result]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
    {reply, Reply, State};

%%升级根骨
%%@param MeridianId 经脉穴位
%%@param IsUse 是否使用经脉保护符
%%@param IsBuy 是否自动购买材料
handle_call({upGen,PlayerStatus, [MeridianId,IsUse,IsBuy]}, _From, Player_meridian) ->
    %%  目标：心法境界阶段到达脱胎换骨 505
    {GenLev,_Val} = lib_meridian:count_attr(Player_meridian),
    mod_target:trigger(PlayerStatus#player_status.status_target, PlayerStatus#player_status.id, 505, GenLev),
	%%检测是否已是最高级
	Lev = lib_meridian:get_gen_level(Player_meridian,MeridianId),
	if
		Lev>=?MERIDIAN_MAX_GEN ->
			Result = 3,Reply = ok,State = Player_meridian;
		true ->
			%%获取升级需要的条件
			R = lib_meridian:get_data_meridian_gen(MeridianId,Lev+?GEN_UP_GAP),
			if
				R =:= #data_meridian_gen{} ->
					Result = 4,Reply = ok,State = Player_meridian;
				true ->
                    if
						%%检测金钱
						R#data_meridian_gen.need_coin > (PlayerStatus#player_status.coin+PlayerStatus#player_status.bcoin) ->
							Result = 6,Reply = ok,State = Player_meridian;
						true->
							%%检测升级材料
							case lib_meridian:check_goods(PlayerStatus,[[R#data_meridian_gen.need_goods_id,R#data_meridian_gen.need_goods_num]],IsBuy) of
								{false,NewPlayerStatus} ->
                                	Result = 5,Reply = NewPlayerStatus,State = Player_meridian;
                                {true,NewPlayerStatus} ->
                                	%%扣除材料
                                    case lib_meridian:delete_goods(NewPlayerStatus,[[R#data_meridian_gen.need_goods_id,R#data_meridian_gen.need_goods_num]]) of
										false ->
											Result = 5,Reply = NewPlayerStatus,State = Player_meridian;
										true->
											log:log_throw(mind_up, PlayerStatus#player_status.id, 0, R#data_meridian_gen.need_goods_id, 1, 0, 0),
											%% 检测是否使用保护符
											if
												IsUse =:=1 -> 
													case lib_meridian:delete_goods(NewPlayerStatus,[[?GEN_BAOHU_GOOD_ID,1]]) of
														false ->
															DeleteBaoHuFu = 0;
													    true ->
															log:log_throw(mind_up, PlayerStatus#player_status.id, 0, ?GEN_BAOHU_GOOD_ID, 1, 0, 0),
															DeleteBaoHuFu = 1
													end;
												true->
													DeleteBaoHuFu = 2
											end,
											case DeleteBaoHuFu of
												0->Result = 8,Reply = NewPlayerStatus,State = Player_meridian;
												_->
													Money = NewPlayerStatus#player_status.bcoin - R#data_meridian_gen.need_coin,
													if
														Money>=0->
															%%扣除金钱
															NewPlayer_Status1 = lib_goods_util:cost_money(NewPlayerStatus, R#data_meridian_gen.need_coin, bcoin),
															% 写消费日志
															About = lists:concat(["upGen ",MeridianId," up to ",Lev]),
															log:log_consume(meridian_upGen, bcoin, NewPlayerStatus, NewPlayer_Status1, About);
														true->
															GapMoney = R#data_meridian_gen.need_coin - NewPlayerStatus#player_status.bcoin,
															%%扣除绑定金钱
															NewPlayer_Status0 = lib_goods_util:cost_money(NewPlayerStatus, NewPlayerStatus#player_status.bcoin, bcoin),
															% 写消费日志
															About0 = lists:concat(["upGen ",MeridianId," up to ",Lev]),
															log:log_consume(meridian_upGen, bcoin, NewPlayerStatus, NewPlayer_Status0, About0),
															%%扣除非绑定金钱
															NewPlayer_Status1 = lib_goods_util:cost_money(NewPlayer_Status0, GapMoney, coin),
															% 写消费日志
															About = lists:concat(["upGen ",MeridianId," up to ",Lev]),
															log:log_consume(meridian_upGen, coin, NewPlayer_Status0, NewPlayer_Status1, About)
													end,
													%%概率检测
													Rate = util:rand(1, 100),
													Old_AddRate = lib_meridian:get_gen_rate(Player_meridian,MeridianId),
													VNPlayerStatus = lib_vip:check_vip(PlayerStatus),
													Vip = VNPlayerStatus#player_status.vip,
													case Rate=<R#data_meridian_gen.rate+Old_AddRate+lib_meridian:get_rate_vip(Vip#status_vip.vip_type) of
														true ->
															State = lib_meridian:update(Player_meridian,2,MeridianId,Lev+?GEN_UP_GAP,0,0),
															Reply = NewPlayer_Status1,
															lib_meridian:gen_send_tv(State,Reply,Lev+?GEN_UP_GAP),
															Result = 1;
														false ->
															%% 检测是否使用保护符
															if
																IsUse =:=1 -> 
																	case DeleteBaoHuFu of
																		0 ->
																			case R#data_meridian_gen.failto of
																				-1->Failto = Lev;
																				Others -> Failto = Others
																			end,
																			AddRate = lib_meridian:get_gen_rate(Player_meridian,MeridianId) + ?GEN_FAIL_ADD_RATE,
																			State = lib_meridian:update(Player_meridian,2,MeridianId,Failto,AddRate,0),
																			Reply = NewPlayer_Status1;
																		1->
																			AddRate = lib_meridian:get_gen_rate(Player_meridian,MeridianId) + ?GEN_FAIL_ADD_RATE,
																			State = lib_meridian:update(Player_meridian,2,MeridianId,Lev,AddRate,0),
																			Reply = NewPlayer_Status1
																	end;
		                                                        true ->
																	case R#data_meridian_gen.failto of
																		-1->Failto = Lev;
																		Others -> Failto = Others
																	end,
																	AddRate = lib_meridian:get_gen_rate(Player_meridian,MeridianId) + ?GEN_FAIL_ADD_RATE,
																	State = lib_meridian:update(Player_meridian,2,MeridianId,Failto,AddRate,0),
																	Reply = NewPlayer_Status1
															end,
															Result = 7,
															%%成就:境界难升呐！累积元神境界提升失败N次，每次失败调用一次
															mod_achieve:trigger_hidden(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 2, 0, 1)
													end
											end
									end
							end
                    end        
			end
	end,
	{ok,BinData} = pt_250:write(25002,[MeridianId,Result]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
	{reply, Reply, State};

handle_call({clearCD,PlayerStatus}, _From, Player_meridian) ->
	%%检测是否有正在修行的脉
	Mid = Player_meridian#player_meridian.mid,
	case Mid of
		0->	%无正在修炼的元神
			Miding = 0, 
			RestCdTime = 0,
			IsCDing = 0;
		_-> %检测是否已修炼完成
			T_Lev = lib_meridian:get_mer_level(Player_meridian,Mid),
			T_D = lib_meridian:get_data_meridian(Mid,T_Lev),
			if
				T_D=:=#data_meridian{} -> 
					Miding = 0, 
					RestCdTime = 0,
					IsCDing = 0;
                true -> 
					GapTime = util:unixtime()-Player_meridian#player_meridian.cdtime,
					if
						T_D#data_meridian.need_cd<GapTime->
							Miding = 0, 
							RestCdTime = 0,
							IsCDing = 0;
						true->
							Miding = Mid, 
							RestCdTime = T_D#data_meridian.need_cd-GapTime,
							IsCDing = 1
					end
			end
	end,
	case IsCDing of
		1->
		   %%计算元宝
		   _Yb = RestCdTime div (60*5),
		   case _Yb of
			   0->
				   if
					  RestCdTime>0->
						  T_Yb=1;
					  true->
						  T_Yb = 0
				   end;
			   _->T_Yb = _Yb
		   end,
		   %%VIP
		   Vip = PlayerStatus#player_status.vip,
		   case Vip#status_vip.vip_type of
				1->IsVip=1;
				2->IsVip=1;
				3->IsVip=1;
                4->IsVip=1;
				_->IsVip=0
		   end,
		   if
			   IsVip=:=1->Yb = 0;
			   true-> Yb = T_Yb
		   end,
		   if
				(PlayerStatus#player_status.gold+PlayerStatus#player_status.bgold)<Yb->
					Result = 3,Reply = ok,State = Player_meridian;
				true->
					%%扣除金钱
					NewPlayer_Status = lib_goods_util:cost_money(PlayerStatus, Yb, silver_and_gold),
					% 写消费日志
					About = lists:concat(["clearMerCD ",Miding]),
					log:log_consume(meridian_clearMerCD, gold, PlayerStatus, NewPlayer_Status, About),
					lib_meridian:update_mid_to_0(PlayerStatus#player_status.id),
					Result = 1,Reply = NewPlayer_Status,State = Player_meridian#player_meridian{mid=0}
		   end;
		_->
		   Result = 2,Reply = ok,State = Player_meridian
	end,
	{ok,BinData} = pt_250:write(25004,[Result]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
    {reply, {Miding,Reply}, State};

handle_call({tupo,PlayerStatus,MeridianId,IsBuy}, _From, Player_meridian) ->
    Lev = lib_meridian:get_mer_level(Player_meridian,MeridianId),
	if
		%%检查是否已达最高级
		Lev>=?MERIDIAN_MAX_LV ->
			Result = 4,Replay= PlayerStatus,State = Player_meridian;
		true ->
			%%检测是否满足产品条件
			D = lib_meridian:get_data_meridian(MeridianId,Lev+?MER_UP_GAP),
			if
				D=:=#data_meridian{} -> 
					Result = 5,Replay= PlayerStatus,State = Player_meridian; 
		        true -> 
					%%检测是否需要突破
					if
						D#data_meridian.need_goods_id=:=0->
							Have_Tupo = true;
						true->
							Tupo = lib_meridian:get_tupo(MeridianId,Player_meridian),
							Have_Tupo = (Lev=<Tupo)
					end,
					case Have_Tupo of
						false-> %%需要突破
							%%检测升级材料
							case lib_meridian:check_goods(PlayerStatus,[[D#data_meridian.need_goods_id,D#data_meridian.need_goods_num]],IsBuy) of
								{false,NewPlayerStatus} ->
                                	Result = 2,Replay= NewPlayerStatus,State = Player_meridian;
                                {true,NewPlayerStatus} ->
                                	%%扣除材料
                                    case lib_meridian:delete_goods(NewPlayerStatus,[[D#data_meridian.need_goods_id,D#data_meridian.need_goods_num]]) of
										false ->
											Result = 2,Replay= NewPlayerStatus,State = Player_meridian;
										true->
											log:log_throw(mind_up, PlayerStatus#player_status.id, 0, D#data_meridian.need_goods_id, D#data_meridian.need_goods_num, 0, 0),
											case MeridianId of
												6->State = Player_meridian#player_meridian{thpmp=Lev};
												2->State = Player_meridian#player_meridian{tdef=Lev};
												3->State = Player_meridian#player_meridian{tdoom=Lev};
												4->State = Player_meridian#player_meridian{tjook=Lev};
												5->State = Player_meridian#player_meridian{ttenacity=Lev};
												1->State = Player_meridian#player_meridian{tsudatt=Lev};
												7->State = Player_meridian#player_meridian{tatt=Lev};
												8->State = Player_meridian#player_meridian{tfiredef=Lev};
												9->State = Player_meridian#player_meridian{ticedef=Lev};
												10->State = Player_meridian#player_meridian{tdrugdef=Lev};
												_->State = Player_meridian
											end,
											%%更新DB
											lib_meridian:update_tupo(State),
											Result = 1,
											Replay= NewPlayerStatus
									end
							end;
						true-> %%不需要突破
							Result = 3,Replay= PlayerStatus,State = Player_meridian
					end
			end
	end,
	{ok,BinData} = pt_250:write(25005,[Result]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),		
    {reply, Replay, State};

handle_call(_Request, _From, State) ->
    Reply = no_handle,
    {reply, Reply, State}.


%%
%% Local Functions
%%

