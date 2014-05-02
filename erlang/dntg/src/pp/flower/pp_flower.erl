%% --------------------------------------------------------
%% @Module:           |pp_flower
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-03-22
%% @Description:      |鲜花功能管理
%% --------------------------------------------------------
-module(pp_flower).
-export([handle/3]).
-include("goods.hrl").
-include("unite.hrl").
-include("common.hrl").
-include("server.hrl").
-include("rela.hrl").
handle(29001, Status, [Type, Num, TargetPlayerName, FlowerType]) ->
    IsSendingOK = case lib_player:get_role_id_by_name(TargetPlayerName) of
		[] ->%%不存在角色
			{ok, BinData} = pt_290:write(29001, [2, 0, TargetPlayerName, 0, 0, 0]),
			lib_unite_send:send_to_one(Status#unite_status.id, BinData);
		TargetPlayerId ->
			case mod_chat_agent:lookup(TargetPlayerId) of
				[] ->%%不在线
					{ok, BinData} = pt_290:write(29001, [2, 0, TargetPlayerName, 0, 0, 0]),
					lib_unite_send:send_to_one(Status#unite_status.id, BinData);
				[RoleTarget] when is_record(RoleTarget, ets_unite) ->
					%%结合ID和数量判断花物品ID类型 goods_id=611601
					{RealFlowerType,RealFlowerNum,MlptAdd,IntimacyAdd,ExpAdd} = get_flowerid(FlowerType,Num),
					SelfPSPid = lib_player:get_player_info(Status#unite_status.id, pid),
					TargetPSPid = lib_player:get_player_info(TargetPlayerId, pid),
					case lib_player:get_player_info(Status#unite_status.id, goods) of
						PlayerGoods when is_record(PlayerGoods, status_goods) ->
							case gen_server:call(PlayerGoods#status_goods.goods_pid,{'delete_more', RealFlowerType, RealFlowerNum}) of
								1 ->
								  %% 调用排行榜接口，接入每日护花/鲜花榜 
%% 								  lib_rank:give_flower_daily(
%% 									Status#unite_status.id,
%% 									Status#unite_status.name,
%% 									Status#unite_status.career,
%% 									Status#unite_status.realm,
%% 									Status#unite_status.sex,
%% 									Status#unite_status.guild_name,
%% 									Status#unite_status.image,
%% 									RoleTarget#ets_unite.id,
%% 									RoleTarget#ets_unite.name,
%% 									RoleTarget#ets_unite.career,
%% 									RoleTarget#ets_unite.realm,
%% 									RoleTarget#ets_unite.sex,
%% 									RoleTarget#ets_unite.guild_name,
%% 									RoleTarget#ets_unite.image,
%% 									MlptAdd
%% 								),
								  mod_daily_dict:plus_count(Status#unite_status.id, 2900, 1), 
								  lib_player:update_player_info(Status#unite_status.id, [{mlpt, MlptAdd}, {add_exp, ExpAdd}]),
								  case RoleTarget#ets_unite.id =:= Status#unite_status.id of
									  true ->
										  skip;
									  false ->
										  lib_player:update_player_info(RoleTarget#ets_unite.id, [{mlpt, MlptAdd}, {add_exp, ExpAdd}])
								  end,
								  case gen_server:call(SelfPSPid, {get_rela_by_ABId, SelfPSPid, Status#unite_status.id, TargetPlayerId}) of
								      []->
									  skip;
								      [_Rela]->
									  if _Rela#ets_rela.rela =:= 1 orelse _Rela#ets_rela.rela =:= 4 ->
										  lib_relationship:update_Intimacy(TargetPSPid, TargetPlayerId, Status#unite_status.id, IntimacyAdd),
										  lib_relationship:update_Intimacy(SelfPSPid, Status#unite_status.id, TargetPlayerId, IntimacyAdd);
									     true ->
										  []
									  end
								  end,
								  save_flowerlog([Status#unite_status.id,
												  Status#unite_status.name,
												  Status#unite_status.sex,
												  RoleTarget#ets_unite.id,
												  RoleTarget#ets_unite.name,
												  0,
												  Num,
												  FlowerType,
												  RoleTarget#ets_unite.image,
												  RoleTarget#ets_unite.sex,
												  RoleTarget#ets_unite.career]),
								  {ok, BinData} = pt_290:write(29001, 
															   [1, 
																RealFlowerType, 
																TargetPlayerName, 
																MlptAdd, 
																IntimacyAdd, 
																ExpAdd]),
								  lib_unite_send:send_to_one(Status#unite_status.id, BinData),
								  {ok, BinData_29002} = pt_290:write(29002, 
																	 [Type, 
																	  Num, 
																	  Status#unite_status.id,
																	  Status#unite_status.name,
																	  0, Status#unite_status.career, 
																	  Status#unite_status.sex, 
																	  MlptAdd, 
																	  IntimacyAdd, 
																	  ExpAdd, 
																	  FlowerType]),
								  lib_unite_send:send_to_one(TargetPlayerId, BinData_29002),
								  %% 成就：亲密无间（1）：第一次送花
								  %%　StatusAchieve = lib_player:get_player_info(Status#unite_status.id, achieve),
								  %% lib_player_unite:trigger_achieve(Status#unite_status.id, trigger_social, [StatusAchieve, Status#unite_status.id, 3, 0, 1]),
								  %% 成就：亲密无间（X）：共送N朵花
								  %% lib_player_unite:trigger_achieve(Status#unite_status.id, trigger_social, [StatusAchieve, Status#unite_status.id, 11, 0, Num]),
								  %% 传闻
								  case Num=:=999 of
									  true -> %%全屏飘花 songhua,2,id,realm,name，sex,professional,headType		
										  case FlowerType of %% Type 1 匿名 2 不匿名
											  1 ->
												  case Type of
													  1 ->
														  lib_chat:send_TV({all},1, 2
																		   ,[songhua
																			 ,2
																			 ,RoleTarget#ets_unite.id
																			 ,RoleTarget#ets_unite.realm
																			 ,RoleTarget#ets_unite.name
																			 ,RoleTarget#ets_unite.sex
																			 ,RoleTarget#ets_unite.career
																			 ,RoleTarget#ets_unite.image
																			]);
													  2 ->
														  lib_chat:send_TV({all},1, 2
																		   ,[songhua
																			 ,1
																			 ,Status#unite_status.id
																			 ,Status#unite_status.realm
																			 ,Status#unite_status.name
																			 ,Status#unite_status.sex
																			 ,Status#unite_status.career
																			 ,Status#unite_status.image
																			 ,RoleTarget#ets_unite.id
																			 ,RoleTarget#ets_unite.realm
																			 ,RoleTarget#ets_unite.name
																			 ,RoleTarget#ets_unite.sex
																			 ,RoleTarget#ets_unite.career
																			 ,RoleTarget#ets_unite.image
																			])
												  end;
											  2 ->
												  case Type of
													  1 ->
														  lib_chat:send_TV({all},1, 2
																		   ,[songhua
																			 ,4
																			 ,RoleTarget#ets_unite.id
																			 ,RoleTarget#ets_unite.realm
																			 ,RoleTarget#ets_unite.name
																			 ,RoleTarget#ets_unite.sex
																			 ,RoleTarget#ets_unite.career
																			 ,RoleTarget#ets_unite.image
																			]);
													  2 ->
														  lib_chat:send_TV({all},1, 2
																		   ,[songhua
																			 ,3
																			 ,Status#unite_status.id
																			 ,Status#unite_status.realm
																			 ,Status#unite_status.name
																			 ,Status#unite_status.sex
																			 ,Status#unite_status.career
																			 ,Status#unite_status.image
																			 ,RoleTarget#ets_unite.id
																			 ,RoleTarget#ets_unite.realm
																			 ,RoleTarget#ets_unite.name
																			 ,RoleTarget#ets_unite.sex
																			 ,RoleTarget#ets_unite.career
																			 ,RoleTarget#ets_unite.image
																			])
												  end;
											  3 ->
												  case Type of
													  1 ->
														  lib_chat:send_TV({all},1, 2
																		   ,[songhua
																			 ,6
																			 ,RoleTarget#ets_unite.id
																			 ,RoleTarget#ets_unite.realm
																			 ,RoleTarget#ets_unite.name
																			 ,RoleTarget#ets_unite.sex
																			 ,RoleTarget#ets_unite.career
																			 ,RoleTarget#ets_unite.image
																			]);
													  2 ->
														  lib_chat:send_TV({all},1, 2
																		   ,[songhua
																			 ,5
																			 ,Status#unite_status.id
																			 ,Status#unite_status.realm
																			 ,Status#unite_status.name
																			 ,Status#unite_status.sex
																			 ,Status#unite_status.career
																			 ,Status#unite_status.image
																			 ,RoleTarget#ets_unite.id
																			 ,RoleTarget#ets_unite.realm
																			 ,RoleTarget#ets_unite.name
																			 ,RoleTarget#ets_unite.sex
																			 ,RoleTarget#ets_unite.career
																			 ,RoleTarget#ets_unite.image
																			])
												  end;
										      6 ->
												  case Type of
													  1 ->
														  lib_chat:send_TV({all},1, 2
																		   ,[songhua
																			 ,8
																			 ,RoleTarget#ets_unite.id
																			 ,RoleTarget#ets_unite.realm
																			 ,RoleTarget#ets_unite.name
																			 ,RoleTarget#ets_unite.sex
																			 ,RoleTarget#ets_unite.career
																			 ,RoleTarget#ets_unite.image
																			]);
													  2 ->
														  lib_chat:send_TV({all},1, 2
																		   ,[songhua
																			 ,7
																			 ,Status#unite_status.id
																			 ,Status#unite_status.realm
																			 ,Status#unite_status.name
																			 ,Status#unite_status.sex
																			 ,Status#unite_status.career
																			 ,Status#unite_status.image
																			 ,RoleTarget#ets_unite.id
																			 ,RoleTarget#ets_unite.realm
																			 ,RoleTarget#ets_unite.name
																			 ,RoleTarget#ets_unite.sex
																			 ,RoleTarget#ets_unite.career
																			 ,RoleTarget#ets_unite.image
																			])
												  end;
											  _ ->
												  skip
										  end;
									  false ->
										  skip
								  end,
								  {ok,ok};
							  Recv->%%没有物品或数量不足
								  case Recv =:= 2 orelse Recv =:= 3 of
									  true ->
										  {ok, BinData} = pt_290:write(29001, [3, RealFlowerType, TargetPlayerName, 0, 0, 0]),
										  lib_unite_send:send_to_one(Status#unite_status.id, BinData);
									  false ->
										  {ok, BinData} = pt_290:write(29001, [0, RealFlowerType, TargetPlayerName, 0, 0, 0]),
										  lib_unite_send:send_to_one(Status#unite_status.id, BinData)
								  end
						  end;
					  _ ->
						  {ok, BinData} = pt_290:write(29001, [0, RealFlowerType, TargetPlayerName, 0, 0, 0]),
						  lib_unite_send:send_to_one(Status#unite_status.id, BinData)
				  end
		  end
  end,
	case Num=:=999 andalso IsSendingOK=:={ok,ok} of
		true -> %%全屏飘花
			{ok, BinData_29005} = pt_290:write(29005, [lib_player:get_role_id_by_name(TargetPlayerName), FlowerType]),
			lib_unite_send:send_to_all(BinData_29005);
		false ->
			skip
	end,
	case IsSendingOK=:={ok,ok} of
		true->
			{ok, Status};
		false ->
			ok
	end;

handle(29003, Status, [TargetPlayerId, Num, TargetPlayerName]) ->
	case lib_player:get_role_id_by_name(TargetPlayerName)=:=TargetPlayerId of
		false ->%%名字和ID不符
			{ok, BinData} = pt_290:write(29003, [2, TargetPlayerName]),
			lib_unite_send:send_to_one(Status#unite_status.id, BinData),
			ok;
		true ->
			case mod_chat_agent:lookup(TargetPlayerId) of
				[] ->
					{ok, BinData} = pt_290:write(29003, [2, TargetPlayerName]),
					lib_unite_send:send_to_one(Status#unite_status.id, BinData),
					ok;
				[_PlayerT] ->
					%%回吻反馈
					{ok, BinData} = pt_290:write(29003, [1, TargetPlayerName]),
					lib_unite_send:send_to_one(Status#unite_status.id, BinData),
					{ok, BinData2} = pt_290:write(29004, [Status#unite_status.id, Status#unite_status.sex, Num, Status#unite_status.name]),
					lib_unite_send:send_to_one(TargetPlayerId, BinData2),
					ok
			end
	end;

handle(29006, Status, get_flower_record) ->
	LLL = get_flowerlog(Status#unite_status.id),
	{ok, BinData} = pt_290:write(29006, LLL),
	lib_unite_send:send_to_one(Status#unite_status.id, BinData);

%% 使用特效符
handle(29007, UniteStatus, [GoodTypeId, GoodsId]) ->
	TxfList = get_txf_list(),
	YHList = get_yh_list(),
	case lists:member(GoodTypeId, TxfList) of
		true ->
			PlayerGoods = lib_player:get_player_info(UniteStatus#unite_status.id, goods),
			Res = case gen_server:call(PlayerGoods#status_goods.goods_pid,{'delete_one', GoodsId, 1}) of
				1 ->
					case GoodTypeId of
						521002 ->
							{ok, BinData_29005} = pt_290:write(29005, [0, 4]),
							lib_unite_send:send_to_all(BinData_29005),
							1;
						_ ->
							0
					end;
				Recv->%%没有物品或数量不足
					case Recv =:= 2 orelse Recv =:= 3 of
						true ->
							2;
						false ->
							0
					end
			end,
			{ok, BinData} = pt_290:write(29007, [Res, GoodTypeId]),
			lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);
		false ->
			case lists:member(GoodTypeId, YHList) of
				true ->
					PlayerGoods = lib_player:get_player_info(UniteStatus#unite_status.id, goods),
					Res = case gen_server:call(PlayerGoods#status_goods.goods_pid,{'delete_one', GoodsId, 1}) of
						1 ->
							ExpAdd = case GoodTypeId == 521401 orelse GoodTypeId == 521406 orelse GoodTypeId == 521407 of
								true ->
									50000;
								_ ->
									10000
							end,
							lib_player:update_player_info(UniteStatus#unite_status.id, [{add_exp, ExpAdd}]),
							{ok, BinData_29008} = pt_290:write(29008, [UniteStatus#unite_status.id, GoodTypeId]),
							lib_unite_send:send_to_scene(UniteStatus#unite_status.scene, BinData_29008),
							1;
						Recv->%%没有物品或数量不足
							case Recv =:= 2 orelse Recv =:= 3 of
								true ->
									2;
								false ->
									0
							end
					end,
					{ok, BinData} = pt_290:write(29007, [Res, GoodTypeId]),
					lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);
				false ->
					ok
			end
	end;

%% 错误
handle(_Cmd, _Status, _Data) ->
	?DEBUG("pp_flower no match", []),
	{error, "pp_flower no match"}.



%% --------------------------------------------------------
%% 						私有函数
%% --------------------------------------------------------

%% 判断花类型和实际送花数量
get_flowerid(FlowerType,Num)->
	case FlowerType of
		1 -> %%红玫瑰
			case Num of
				1 -> {611601,1,1,1,1};
				9 -> {611601,9,9,9,9};
				99 -> {611602,1,99,99,99};
				999 -> {611603,1,999,999,999}
			end;
		2 -> %%蓝玫瑰
			case Num of
				1 -> {611604,1,1,1,1};
				9 -> {611604,9,9,9,9};
				99 -> {611605,1,99,99,99};
				999 -> {611606,1,999,999,999}
			end;
		3 -> %%生蛋贺卡
			case Num of
				1 -> {611607,1,1,1,1};
				9 -> {611607,9,9,9,9};
				99 -> {611608,1,99,99,99};
				999 -> {611609,1,999,999,999}
			end;
		6 -> %% 蔷薇
			case Num of
				1 -> {611610,1,1,1,1};
				99 -> {611611,1,99,99,99};
				999 -> {611612,1,999,999,999}
			end;
		_R -> %%类型异常
			{ok,error,0,0,0}
	end.

%% 特效符列表(全服广播)
get_txf_list() ->
	[521002].

%% 烟花列表(场景广播)
get_yh_list() ->
	[521401, 521402, 521403, 521404, 521405, 521406, 521407].

%% 写入送花记录
save_flowerlog([FromId, FromName, FromSex, ToId, ToName, _Time, Num, Type, HdShow, Sex, Voc])->
	db:execute(db:make_insert_sql(log_flower, ["fromid", "fromname", "fromsex", "toid", "toname", "time","num","type", "hdshow","sex","voc"], [FromId, FromName, FromSex, ToId, ToName, pt:get_time_stamp(), Num, Type, HdShow, Sex, Voc])),
	ok.

%% 读取送花记录
get_flowerlog(FromId)->
	db:get_all(io_lib:format(<<"select fromid, fromname, toid, toname, time, num, type, hdshow, sex, voc from log_flower where fromId = ~p or toid = ~p order by id">>, [FromId,FromId])).
