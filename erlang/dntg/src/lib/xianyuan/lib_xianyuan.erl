%%%--------------------------------------
%%% @Module  :  lib_xianyuan 
%%% @Author  :  hekai
%%% @Email   :  hekai@jieyou.cn
%%% @Created :  2012-9-27
%%% @Description: 仙缘系统
%%%---------------------------------------

-module(lib_xianyuan).
-compile(export_all).
-include("server.hrl").
-include("common.hrl").
-include("scene.hrl").
-include("xianyuan.hrl").
-define(CP_SKILL_1, 1040).  %% 夫妻技能1 天涯咫尺 
-define(CP_SKILL_2, 1050).  %% 夫妻技能2 相濡以沫
-define(SWEET_GOOD_ID, 602031). %% 增加幸福甜蜜度物品

%% 上线初始化夫妻技能
online(PS)->    
	Cp_skill = PS#player_status.cp_skill,
	SQL =io_lib:format(?FIND_CP_SKILL, [PS#player_status.id]),
	Skill = db:get_all(SQL),
	F = fun([Id, Lv, Cd]) ->
			{Id, Lv, Cd}
		end,
	TupleList = lists:map(F, Skill),
	Skill1 = lists:keyfind(?CP_SKILL_1, 1, TupleList),
	Skill2 = lists:keyfind(?CP_SKILL_2, 1, TupleList),

	%% 查询修炼类型10，反推技能级别，用作容错处理
	SQL2 = io_lib:format(?FIND_TYPE_10, [PS#player_status.id]),    
	case db:get_row(SQL2) of
		[Type_10_Lv] ->
			if 
			  Type_10_Lv=<40 ->
				SLv_1 = util:floor((Type_10_Lv+2)/4),
				SLv_2 = util:floor(Type_10_Lv/4);
			  true ->
				SLv_1 =10, SLv_2 =10
			end;
		[] ->
			SLv_1 = 0,
			SLv_2 = 0
	end,
	case Skill1 of
		false ->
			case SLv_1>0 of
				true -> %% 容错处理
					SQL1 = io_lib:format(?INSERT_CP_SKILL, [PS#player_status.id,?CP_SKILL_1,SLv_1,0]),
					db:execute(SQL1),
					NewPS1 = PS#player_status{cp_skill=Cp_skill#couple_skill{id_1 =?CP_SKILL_1, lv_1=SLv_1}};
				false ->
					NewPS1 = PS#player_status{cp_skill=Cp_skill#couple_skill{id_1 =?CP_SKILL_1, lv_1=0}}
			end;
		{_Id, Lv, Cd} ->
			case SLv_1>Lv of
				true -> %% 容错处理
					SQL1_2 = io_lib:format(?UPDATE_CP_SKILL_LV, [SLv_1,PS#player_status.id,?CP_SKILL_1]),
					db:execute(SQL1_2),
					NewPS1 = PS#player_status{cp_skill=Cp_skill#couple_skill{id_1 =?CP_SKILL_1, lv_1=SLv_1, cd_1= Cd}};
				false ->
					case Lv>10 of
						true -> LvB = 10;
						false -> LvB = Lv
					end,
					NewPS1 = PS#player_status{cp_skill=Cp_skill#couple_skill{id_1 =?CP_SKILL_1, lv_1=LvB, cd_1= Cd}}
			end			
	end,
	Lv_1 = NewPS1#player_status.cp_skill#couple_skill.lv_1,
	Cd_1 = NewPS1#player_status.cp_skill#couple_skill.cd_1,
	case Skill2 of
		false ->	
			case SLv_2>0 of
				true -> %% 容错处理
					SQL3 = io_lib:format(?INSERT_CP_SKILL, [PS#player_status.id,?CP_SKILL_2,SLv_2,0]),
					db:execute(SQL3),
					NewPS2 = NewPS1#player_status{cp_skill=Cp_skill#couple_skill{id_1 =?CP_SKILL_1, lv_1=Lv_1, cd_1= Cd_1, id_2 =?CP_SKILL_2, lv_2=SLv_2}};
				false ->
					NewPS2 = NewPS1#player_status{cp_skill=Cp_skill#couple_skill{id_1 =?CP_SKILL_1, lv_1=Lv_1, cd_1= Cd_1, id_2 =?CP_SKILL_2, lv_2=0}}
			end;			
		{_Id2, Lv2, Cd2} ->
			case SLv_2>Lv2 of
				true -> %% 容错处理
					SQL4 = io_lib:format(?UPDATE_CP_SKILL_LV, [SLv_2,PS#player_status.id,?CP_SKILL_2]),
					db:execute(SQL4),
					NewPS2 = NewPS1#player_status{cp_skill=Cp_skill#couple_skill{id_1 =?CP_SKILL_1, lv_1=Lv_1, cd_1= Cd_1, id_2 =?CP_SKILL_2, lv_2=SLv_2, cd_2= Cd2}};				false ->
					case Lv2>10 of
						true -> LvC = 10;
						false -> LvC = Lv2
					end,
					NewPS2 = NewPS1#player_status{cp_skill=Cp_skill#couple_skill{id_1 =?CP_SKILL_1, lv_1=Lv_1, cd_1= Cd_1, id_2 =?CP_SKILL_2, lv_2=LvC, cd_2= Cd2}}
			end			
	end,
	NewPS2.

%% 使用夫妻技能
%% @param PS1 玩家自己PS
%% @param PS2 对方PS
%% @param Skill_id 技能Id
%% 读取cp_skill 可能存在小问题
use_couple_skill(PS1, PS2, Skill_id) ->
	case Skill_id of
		?CP_SKILL_1 ->				
			Cp_skill = PS1#player_status.cp_skill,
			{Id,Lv,Cd} = {Cp_skill#couple_skill.id_1,Cp_skill#couple_skill.lv_1,Cp_skill#couple_skill.cd_1},
			%% 是否已激活该技能
			case  Lv=:=0 orelse Id=:=0 of
				true -> NewPS1 = PS1, ReturnCode = 6, Left_cd=0;
				false -> 
					NowTime = util:unixtime(),
					%% 需要的Cd时间
					[_, NeedCd, _] = data_cp_skill:get(?CP_SKILL_1, Lv), 
					%% Cd是否结束
					case NowTime - Cd> NeedCd of
						true ->                             
							%% 判断是否可以传送
							case PS1#player_status.scene =:= 998 of
								true ->
									NewPS1 = PS1, ReturnCode = 9, Left_cd=0;
								false ->                                    
									HS = PS1#player_status.husong,									
									if  %% 运镖中
										HS#status_husong.husong /= 0 ->
											NewPS1 = PS1, ReturnCode = 8, Left_cd=0;									    											
										true -> %% 坐骑上
											case PS1#player_status.mount#status_mount.fly_mount =/= 0  orelse PS1#player_status.mount#status_mount.fly =/= 0 of
												true -> 
													NewPS1 = PS1,ReturnCode = 10, Left_cd=0;
												_ ->%% 巡游中
													case  lib_marriage:marry_state(PS1#player_status.marriage) of
														8 -> NewPS1 = PS1, ReturnCode = 13, Left_cd=0;
														_ ->%% 是否Boss场景															 
															case lib_scene:get_data(PS2#player_status.scene) of
                                                                _S when is_record(_S, ets_scene) ->
																	SceneType = _S#ets_scene.type;
																_ ->
																	SceneType = 0
															end,
															%% 0表示PK模式不对;1表示正常,当需修复坐标值场景入口;2表示正常
															Correct_pk = 
															case SceneType =:= ?SCENE_TYPE_BOSS of
																true -> 
																	Pk = PS1#player_status.pk,
																	case Pk#status_pk.pk_status =:= 2 orelse Pk#status_pk.pk_status =:= 3 of
																		true ->  1;																			
																		false -> 0																			
																	end;
																false -> 2																		
															end,															
															case Correct_pk of
																0 -> %%此处返回暂为15,后面客户端同步后改为14,提示PK模式不对
																	NewPS1 = PS1, ReturnCode = 14, Left_cd=0;	
																_Other ->
																	case lib_player:get_player_info(PS2#player_status.id, position_info) of
																		false ->
																			NewPS1 = PS1,ReturnCode = 3, Left_cd=0;
																		{_, _, _X, _Y} ->																			
																			%% 判断是否可以传送至PS2中的场景
																			[ReplyCode, _SceneId] = is_transferable(PS1, PS2),
%%																			[SceneId, X, Y] = lib_vip:get_aim_xy([_SceneId, _X, _Y]),
																			SceneId=_SceneId, X = _X, Y = _Y,
																			case  ReplyCode of
																				1 ->																			
																					%% 切换场景，记录cd时间:缓存，数据库, 返回PS
																					%% 采取小飞鞋那种切换方式                                                            
																					NewPS = prepare_to_use_skill(PS1, Skill_id),
																					lib_scene:leave_scene(NewPS),
																					NewPS1 = NewPS#player_status{scene=SceneId, x=X, y=Y},
																					case lib_scene:get_data(SceneId) of
                                                                                        S when is_record(S, ets_scene) ->
																							SceneName = S#ets_scene.name;
																						_ ->
																							SceneName = <<>>
																					end,
																					{ok, BinData} = pt_120:write(12005, [NewPS1#player_status.scene, 
																							NewPS1#player_status.x, 
																							NewPS1#player_status.y, 
																							SceneName, NewPS1#player_status.scene]),
																					lib_server_send:send_one(NewPS1#player_status.socket, BinData),
																					ReturnCode = 1, Left_cd=NeedCd;
																				_ ->
																					NewPS1 = PS1, ReturnCode = ReplyCode, Left_cd=0
																			end
																	end
															end
													end													                                                    
											end
									end
							end;
						false ->
							NewPS1 = PS1,ReturnCode = 5, Left_cd=Cd+NeedCd-NowTime
					end
			end;			
		?CP_SKILL_2 ->
			%% 给对方加血技能
			Cp_skill = PS1#player_status.cp_skill,            
			{Id,Lv,Cd} = {Cp_skill#couple_skill.id_2,Cp_skill#couple_skill.lv_2,Cp_skill#couple_skill.cd_2},
			%% 是否已激活该技能
			case  Lv=:=0 orelse Id=:=0 of
				true -> NewPS1 = PS1, ReturnCode = 6, Left_cd=0;
				false -> 
					NowTime = util:unixtime(),
					%% 需要的Cd时间
					[_, NeedCd,_,Ratio] = data_cp_skill:get(?CP_SKILL_2, Lv), 
					%% Cd是否结束
					case NowTime - Cd> NeedCd of
						true ->
							Scene1 = PS1#player_status.scene,
							Scene2 = PS2#player_status.scene,							
							case Scene1 =:= Scene2 of
								true ->	
									case lib_player:get_player_info(PS2#player_status.id, hp) of
										false -> 
											NewPS1 = PS1,ReturnCode = 3, Left_cd=0;
										Hp ->
											Hp_lim = lib_player:get_player_info(PS2#player_status.id, hp_lim),
											Hp_add = trunc(Hp_lim*Ratio/100),		
											case Hp<Hp_lim of
												true ->
													case Hp+Hp_add>Hp_lim of
														true ->
															Hp_add2 = Hp_lim -Hp;
														false ->
															Hp_add2 = Hp_add
													end,
													case lib_player:add_hp(PS2#player_status.id, Hp_add2) of
														true ->
															NewPS1 = prepare_to_use_skill(PS1, Skill_id),
															ReturnCode = 1, Left_cd=NeedCd;
														false ->
															NewPS1 = PS1,ReturnCode = 15, Left_cd=0
													end;
												false ->
													NewPS1 = PS1,ReturnCode = 12, Left_cd=0
											end
									end;									
								false ->
									NewPS1 = PS1,ReturnCode = 4, Left_cd=NowTime - Cd
							end;
						false ->
							NewPS1 = PS1,ReturnCode = 5, Left_cd=Cd+NeedCd-NowTime
					end
			end;
		_Other ->
			NewPS1 = PS1,ReturnCode = 15, Left_cd=0
	end,
	[NewPS1, ReturnCode, Left_cd].

%% 升级夫妻技能
%% @param  PS
%% @param  Xtype 仙缘修炼类型
%% @param  Xtype 修炼级别
%% @return NewPS
upgrade_cp_skill(PS, Xtype, XLevel) -> 
	Cp_skill = PS#player_status.cp_skill,            
	Cp_skill_1_level = Cp_skill#couple_skill.lv_1,
	Cp_skill_2_level = Cp_skill#couple_skill.lv_2,
	NewPS = upgrade_two_cp_skill(PS, [Xtype, XLevel], [Cp_skill_1_level,Cp_skill_2_level]),
	NewPS.


%% 升级夫妻技能 内部方法
%% @param  PS
%% @param  Xtype 仙缘修炼类型
%% @param  Xtype 修炼级别
%% @param  Skill_1_Lv 技能1当前级别
%% @param  Skill_2_Lv 技能2当前级别
%% @return NewPS
upgrade_two_cp_skill(PS, [Xtype, XLevel], [Skill_1_Lv,Skill_2_Lv]) ->
	case Skill_1_Lv<10 of
		true -> Cp_skill_data_10001 = get_data_cp_skill_1(?CP_SKILL_1, Skill_1_Lv+1);
		false -> Cp_skill_data_10001 = get_data_cp_skill_1(?CP_SKILL_1, Skill_1_Lv)
	end,
	case Skill_2_Lv<10 of
		true -> Cp_skill_data_20001 = get_data_cp_skill_2(?CP_SKILL_2, Skill_2_Lv+1);
		false -> Cp_skill_data_20001 = get_data_cp_skill_2(?CP_SKILL_2, Skill_2_Lv)
	end,	
	case Skill_1_Lv =:= 0 of
		true -> Flag1 =0;
		false -> Flag1 =1
	end,
	case Skill_2_Lv =:= 0 of
		true -> Flag2 =0;
		false -> Flag2 =1
	end,
	{NXtype, NXLevel} = Cp_skill_data_10001#cp_skill_1.condition,
	%% 升级夫妻技能1
	case NXtype=:= Xtype andalso NXLevel=:=XLevel of
		true ->
			NewPS =note_upgrade_cp_skill(PS, ?CP_SKILL_1, Flag1);
		false ->
			NewPS = PS
	end,
	{NXtype2, NXLevel2} = Cp_skill_data_20001#cp_skill_2.condition,
	%% 升级夫妻技能2
	case NXtype2=:= Xtype andalso NXLevel2=:=XLevel of
		true ->
			NewPS2 =note_upgrade_cp_skill(NewPS, ?CP_SKILL_2, Flag2);
		false ->
			NewPS2 = NewPS
	end,
	NewPS2.

%% 使用技能前预处理 记录Cd时间：数据库/缓存
%% @param PS1
%% @param Skill_id
%% @Return NewPS
prepare_to_use_skill(PS1, Skill_id) ->
	NowTime =util:unixtime(),
    SQL =io_lib:format(?UPDATE_CP_SKILL_CD, [NowTime, PS1#player_status.id, Skill_id]),
    db:execute(SQL),
    note_use_cp_skill(PS1, Skill_id).

%% 记录使用夫妻技能时间
%% @param PS1
%% @param Skill_id
%% @Return NewPS
note_use_cp_skill(PS1, Skill_id) ->
	Cp_skill = PS1#player_status.cp_skill,
    NowTime =util:unixtime(),
	case Skill_id of
		?CP_SKILL_1 ->
			NewPs = PS1#player_status{cp_skill=Cp_skill#couple_skill{cd_1=NowTime}};		
		?CP_SKILL_2 ->
			NewPs = PS1#player_status{cp_skill=Cp_skill#couple_skill{cd_2=NowTime}}	
	end,
	NewPs.

%% 记录夫妻技能升级
%% @param PS1
%% @param Skill_id
%% @param Flag 第一次激活标志  0是 1否
%% @Return NewPS
note_upgrade_cp_skill(PS1, Skill_id, Flag) ->	
	Cp_skill = PS1#player_status.cp_skill,
	NowTime =util:unixtime(),
	case Skill_id of
		?CP_SKILL_1 ->		
			Lv = Cp_skill#couple_skill.lv_1,			
			NewPs = PS1#player_status{cp_skill=Cp_skill#couple_skill{lv_1=Lv+1}};
		?CP_SKILL_2 ->
			Lv = Cp_skill#couple_skill.lv_2,
			NewPs = PS1#player_status{cp_skill=Cp_skill#couple_skill{lv_2=Lv+1}}
	end,
	case Flag of
		0 ->
			%% 写数据库操作
			SQL =io_lib:format(?INSERT_CP_SKILL, [PS1#player_status.id, Skill_id, 1, NowTime]),
			db:execute(SQL);
		1 ->
			%% 写数据库操作
			SQL =io_lib:format(?UPDATE_CP_SKILL_LV, [Lv+1, PS1#player_status.id, Skill_id]),
			db:execute(SQL)
	end,
	NewPs.

%% 是否可以传到2场景
%% @param ReturnCode 返回码
is_transferable(PS1, PS2) ->    
    _SceneId2 = PS2#player_status.scene,
    SceneId2 = lib_vip:boss_scene_deal(_SceneId2),
    MScene = ets:lookup(?ETS_SCENE, SceneId2), 
    [Scene] = MScene,
    Res = [Scene#ets_scene.id,Scene#ets_scene.x,Scene#ets_scene.y],
    {_, {_, Level}} = lists:keysearch(lv, 1, Scene#ets_scene.requirement),
    case Res of
        [] -> %% 该场景不可传送
            ReturnCode =7; 
        R ->
            [SceneId2, _X, _Y] = lib_vip:get_aim_xy(R),
            %% 等级是否满足
            case PS1#player_status.lv >= Level of
                true -> 
                    Flag1 = lib_vip:is_forbidden_fly_to_scene_type(SceneId2),
                    Flag2 = lib_vip:is_forbidden_fly_from_scene_type(PS1#player_status.scene),
                    Flag3 = lib_vip:is_forbidden_fly_scene_id(PS1#player_status.scene),
					VipScene = data_vip_new:get_config(scene_id),
                    VipScene2 = data_vip_new:get_config(scene_id2),
					VipScene3 = data_vip_new:get_config(scene_id3),
					SceneList = [VipScene, VipScene2, VipScene3, 998],
					case lists:member(SceneId2, SceneList) of
						true ->  Flag4 = true;
						false -> Flag4 = false
					end,
                    case Flag1 =:= true orelse Flag2 =:= true orelse Flag3 =:= true orelse Flag4 =:= true of
                        false ->
                            ReturnCode =1; 
                        true -> %% 该场景不可传送
                            ReturnCode =7
                    end;
                false ->
                    ReturnCode =11 
            end
    end,
    [ReturnCode, SceneId2].


%% 获取仙缘系统人物属性加成
%% 基础属性*（1+甜蜜度加成%）+甜蜜度保底属性
%% @param Player_xianyuan 仙缘数据
%% @return [气血, .... ,毒抗]
count_attribute(PS, Player_xianyuan) ->
	XList = [1,2,3,4,5,6,7,8,9,10],
	F1 = fun(Xtype) ->
			count_attribute(PS, Player_xianyuan, Xtype)
		end,
	AttrList = lists:map(F1, XList),
	F2 = fun(Attr) ->
			F3 = fun({_Type, Value}) ->
					Value
				 end,
			lists:map(F3, Attr)
		 end,
	F3 = fun(Xtype) ->
			count_sweet_attribute_lim(PS, Player_xianyuan, Xtype)
		end,	
	AttrLimList = lists:map(F3, XList),
	[[V1],[V2],[V3],[V4],[V5],[V6],[V7],[V8],[V9],[V10]] = lists:map(F2, AttrList),
	[V1_lim, V2_lim, V3_lim, V4_lim, V5_lim, V6_lim, V7_lim, V8_lim, V9_lim, V10_lim] = AttrLimList,
	V1_1 = util:floor((V1*Player_xianyuan#player_xianyuan.sweetness)/1000)+V1_lim,
    V2_1 = util:floor((V2*Player_xianyuan#player_xianyuan.sweetness)/1000)+V2_lim,
	V3_1 = util:floor((V3*Player_xianyuan#player_xianyuan.sweetness)/1000)+V3_lim,
	V4_1 = util:floor((V4*Player_xianyuan#player_xianyuan.sweetness)/1000)+V4_lim,
	V5_1 = util:floor((V5*Player_xianyuan#player_xianyuan.sweetness)/1000)+V5_lim,
	V6_1 = util:floor((V6*Player_xianyuan#player_xianyuan.sweetness)/1000)+V6_lim,
	V7_1 = util:floor((V7*Player_xianyuan#player_xianyuan.sweetness)/1000)+V7_lim,
	V8_1 = util:floor((V8*Player_xianyuan#player_xianyuan.sweetness)/1000)+V8_lim,
	V9_1 = util:floor((V9*Player_xianyuan#player_xianyuan.sweetness)/1000)+V9_lim,
	V10_1 = util:floor((V10*Player_xianyuan#player_xianyuan.sweetness)/1000)+V10_lim,
	[V1_1,V2_1,V3_1,V4_1,V5_1,V6_1,V7_1,V8_1,V9_1,V10_1].

%% 获取指定仙缘类型人物属性加成
count_attribute(_PS, Player_xianyuan, Xtype) ->	
	%% 是否有正在修炼的仙缘
	Ptype = Player_xianyuan#player_xianyuan.ptype,
	case Ptype of
		0 -> Flag = 0; 
		_->			
			Xy_type_lv_1 = lib_xianyuan:get_xianyuan_level(Player_xianyuan, 1, Ptype), 
			Xy_data_1 = lib_xianyuan:get_data_xianyuan(Ptype, Xy_type_lv_1),
			if  
				Xy_data_1 =:= #data_xianyuan{} ->				
					Flag = 0; 
				true -> 
					P_time = util:unixtime() - Player_xianyuan#player_xianyuan.cdtime,
					if
						P_time > Xy_data_1#data_xianyuan.need_cdtime ->
							Flag = 0; 
						true ->
							Flag = 1
					end
			end							
	end,
	%% 如果指定类型是正在修炼的类型,则该类型下降一级
	Lv = get_xianyuan_level(Player_xianyuan, 1, Xtype),
	if 
		Flag =:= 1 andalso Ptype =:= Xtype ->
			Lv2 = Lv-1;
		true ->
			Lv2 = Lv
	end,
	Data_xianyuan = get_data_xianyuan(Xtype, Lv2),
	Data_xianyuan#data_xianyuan.value.

%% 获取仙缘系统属性加成[分开基础属性与加成]
%% 基础属性*（1+甜蜜度加成%）+甜蜜度保底属性
%% @param Player_xianyuan 仙缘数据
%% @return [气血, .... ,毒抗,气血加成 ... ,毒抗加成]
count_attribute_2(PS, Player_xianyuan) ->
	XList = [1,2,3,4,5,6,7,8,9,10],
	F1 = fun(Xtype) ->
			count_attribute(PS, Player_xianyuan, Xtype)
		end,
	AttrList = lists:map(F1, XList),
	F2 = fun(Attr) ->
			F3 = fun({_Type, Value}) ->
					Value
				 end,
			lists:map(F3, Attr)
		 end,
	F3 = fun(Xtype) ->
			count_sweet_attribute_lim(PS, Player_xianyuan, Xtype)
		end,	
	AttrLimList = lists:map(F3, XList),
	[[V1],[V2],[V3],[V4],[V5],[V6],[V7],[V8],[V9],[V10]] = lists:map(F2, AttrList),
	[V1_lim, V2_lim, V3_lim, V4_lim, V5_lim, V6_lim, V7_lim, V8_lim, V9_lim, V10_lim] = AttrLimList,
	V1_1 = util:floor((V1*Player_xianyuan#player_xianyuan.sweetness)/1000)+V1_lim,
    V2_1 = util:floor((V2*Player_xianyuan#player_xianyuan.sweetness)/1000)+V2_lim,
	V3_1 = util:floor((V3*Player_xianyuan#player_xianyuan.sweetness)/1000)+V3_lim,
	V4_1 = util:floor((V4*Player_xianyuan#player_xianyuan.sweetness)/1000)+V4_lim,
	V5_1 = util:floor((V5*Player_xianyuan#player_xianyuan.sweetness)/1000)+V5_lim,
	V6_1 = util:floor((V6*Player_xianyuan#player_xianyuan.sweetness)/1000)+V6_lim,
	V7_1 = util:floor((V7*Player_xianyuan#player_xianyuan.sweetness)/1000)+V7_lim,
	V8_1 = util:floor((V8*Player_xianyuan#player_xianyuan.sweetness)/1000)+V8_lim,
	V9_1 = util:floor((V9*Player_xianyuan#player_xianyuan.sweetness)/1000)+V9_lim,
	V10_1 = util:floor((V10*Player_xianyuan#player_xianyuan.sweetness)/1000)+V10_lim,
	[V1,V2,V3,V4,V5,V6,V7,V8,V9,V10,V1_1-V1,V2_1-V2,V3_1-V3,V4_1-V4,V5_1-V5,V6_1-V6,V7_1-V7,V8_1-V8,V9_1-V9,V10_1-V10].

%%获取甜蜜度保底加成
count_sweet_attribute_lim(_PS, Player_xianyuan, Xtype) ->
	Sweet = Player_xianyuan#player_xianyuan.sweetness,
	_Level = (Sweet-1000) div 50,
	case  _Level>=0 of
		true -> Level =_Level;
		false -> Level = 0
	end,
	if 
		Xtype =:= 1 -> %% 气血
			Level*50;
		Xtype =:= 2 -> %% 攻击 
			Level*2;
		Xtype =:= 3 -> %% 防御
			Level*5;
		Xtype =:= 4 -> %% 命中
			Level*5;
		Xtype =:= 5 -> %% 闪避
			Level*4;
		Xtype =:= 6 -> %% 暴击
			Level*1;
		Xtype =:= 7 -> %% 坚韧
			Level*3;
		Xtype =:= 8 -> %% 雷抗性
			Level*16;
		Xtype =:= 9 -> %% 水抗性
			Level*16;
		Xtype =:= 10 -> %% 冥抗性
			Level*16
	end.

%%获取仙缘系统附加人物基础属性加成
%% @return [气血、雷抗、水抗、冥抗]
count_base_attribute(Player_xianyuan) ->
	Jjie_level = lib_xianyuan:get_xianyuan_level(Player_xianyuan, 2, 0), 
	Jjie_data = lib_xianyuan:get_data_jjie(Jjie_level),
	[Value1, Value2, Value3, Value4] = Jjie_data#data_jjie.value,
	[Value1, Value2, Value3, Value4].

%% 获取仙缘修炼数据
%% @param XyType 类型 1-10
%% @param Level  级别 1-40
%% @return #data_xianyuan
get_data_xianyuan(XyType, Level)->
	case data_xianyuan:get(XyType,Level) of
		[] -> #data_xianyuan{};
		L ->list_to_tuple([data_xianyuan|L])
    end.

%% 获取仙缘境界数据
%% @param Level  级别 1-4
%% @return #data_jjie
get_data_jjie(Level)->
	case data_xianyuan_jjie:get(Level) of
		[] -> #data_jjie{};
		L ->list_to_tuple([data_jjie|L])
    end.


%% 获取夫妻技能1数据
%% @param SkillId 技能Id
%% @param Level   级别 1-10
%% @return #data_jjie
get_data_cp_skill_1(SkillId, Level)->
	case data_cp_skill:get(SkillId, Level) of
		[] -> #cp_skill_1{};
		L ->list_to_tuple([cp_skill_1|L])
    end.


%% 获取夫妻技能2数据
%% @param SkillId 技能Id
%% @param Level   级别 1-10
%% @return #data_jjie
get_data_cp_skill_2(SkillId, Level)->
	case data_cp_skill:get(SkillId, Level) of
		[] -> #cp_skill_2{};
		L ->list_to_tuple([cp_skill_2|L])
    end.

%% 触发境界
%% @param PS         玩家状态
%% @param NJlevel    当前境界级别
%% @param NSweetness 当前甜蜜度
trigger_jjie(PS, NJlevel, NSweetness) ->
	%% JLevel = data_xianyuan_jjie:get_jlevel(NSweetness),	
    case NJlevel<4 of
		true ->
			NJlevel2 = NJlevel+1;
		false ->
			NJlevel2 =NJlevel
	end,
	Data_jjie = get_data_jjie(NJlevel2),
	{Need_sweet_start,Need_sweet_end} = Data_jjie#data_jjie.need_sweetness,
	case   NSweetness>=Need_sweet_start andalso  NSweetness=<Need_sweet_end of
		true -> 
			{ok,BinData} = pt_272:write(27204,[NJlevel2]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData),
			NJlevel2;
		false ->
			NJlevel
	end.

%% 获取指定仙缘修炼、境界当前等级
%% @param Player_xianyuan 玩家仙缘对象
%% @param Type   1获取修炼等级 2获取境界
%% @param XyType 仙缘类型
%% @return Value int
get_xianyuan_level(Player_xianyuan, Type, XyType) 
	when Type =:=1 orelse Type =:=2 ->
	if 
		Type =:=1 ->
			case XyType of
				1->Player_xianyuan#player_xianyuan.hpmp;      %%气血内功等级    
				2->Player_xianyuan#player_xianyuan.def;       %%防御内功等级
				3->Player_xianyuan#player_xianyuan.doom;      %%命中内功等级
				4->Player_xianyuan#player_xianyuan.jook;      %%闪避内功等级
				5->Player_xianyuan#player_xianyuan.tenacity;  %%坚韧内功等级
				6->Player_xianyuan#player_xianyuan.sudatt;    %%暴击内功等级
				7->Player_xianyuan#player_xianyuan.att;       %%攻击内功等级
				8->Player_xianyuan#player_xianyuan.firedef;   %%火坑内功等级
				9->Player_xianyuan#player_xianyuan.icedef;    %%冰抗内功等级
				10->Player_xianyuan#player_xianyuan.drugdef   %%毒抗内功等级
			end;
		Type =:=2 ->
			Player_xianyuan#player_xianyuan.jjie
	end.

%% 使用增加甜蜜度的物品
use_sweet_goods(Playerstatus, Playerr_xianyuan) ->
	PlayerGoods = Playerstatus#player_status.goods,
	Sweetness =  Playerr_xianyuan#player_xianyuan.sweetness,
	GoodsTypeId = ?SWEET_GOOD_ID,
	case Sweetness>= 2000 of
		true -> ReturnCode =2;
		false ->
			case gen_server:call(PlayerGoods#status_goods.goods_pid,{'delete_more', GoodsTypeId, 1}) of
				1 ->
					log:log_goods_use(Playerstatus#player_status.id, GoodsTypeId, 1),					
					ReturnCode =1;
				2 -> 
					ReturnCode =3;
				3 ->
					%% 物品数量不足
					ReturnCode =3;
				_Other ->
					%% 扣除失败
					ReturnCode =4
			end	
	end,
	ReturnCode.

%% 更新玩家仙缘修炼、境界数据
%% @param Playerr_xianyuan 玩家仙缘修炼、境界数据
%% @param Ptype			   修炼类型
%% @param Lev			   
update(Playerr_xianyuan,Ptype,Lev)->
	NowTime = util:unixtime(),
	NPlayerr_xianyuan =			
	case Ptype of
		1-> Playerr_xianyuan#player_xianyuan{hpmp=Lev,ptype=Ptype,cdtime=NowTime};        %%气血内功等级    
		2-> Playerr_xianyuan#player_xianyuan{def=Lev,ptype=Ptype,cdtime=NowTime};       %%防御内功等级
		3-> Playerr_xianyuan#player_xianyuan{doom=Lev,ptype=Ptype,cdtime=NowTime};      %%命中内功等级
		4-> Playerr_xianyuan#player_xianyuan{jook=Lev,ptype=Ptype,cdtime=NowTime};      %%闪避内功等级
		5-> Playerr_xianyuan#player_xianyuan{tenacity=Lev,ptype=Ptype,cdtime=NowTime};  %%坚韧内功等级
		6-> Playerr_xianyuan#player_xianyuan{sudatt=Lev,ptype=Ptype,cdtime=NowTime};    %%暴击内功等级
		7-> Playerr_xianyuan#player_xianyuan{att=Lev,ptype=Ptype,cdtime=NowTime};       %%攻击内功等级
		8-> Playerr_xianyuan#player_xianyuan{firedef=Lev,ptype=Ptype,cdtime=NowTime};   %%火坑内功等级
		9-> Playerr_xianyuan#player_xianyuan{icedef=Lev,ptype=Ptype,cdtime=NowTime};   %%冰抗内功等级
		10-> Playerr_xianyuan#player_xianyuan{drugdef=Lev,ptype=Ptype,cdtime=NowTime}   %%毒抗内功等级
	end,
    [_Name|L] = tuple_to_list(NPlayerr_xianyuan),
	[Uid|Value] = L,
	Params = Value ++ [Uid],
	Sql = io_lib:format(?UPDATE_XIANYUAN,Params),
	db:execute(Sql),
	NPlayerr_xianyuan.

%% 更新正在修炼仙缘类型至0
%% @param  Ptype2  上一次修炼类型
%% @param  Uid	   玩家Id
update_ptype_to_0(Ptype2, Uid) ->
	Sql = io_lib:format(?UPDATE_PTYPE_TO_0,[Ptype2, Uid]),
	db:execute(Sql).

%% 更新境界数据
%% @param Jjie		境界级别 
%% @param Sweetness 甜蜜度
%% @param Uid		玩家Id
update_jjie([Jjie, Sweetness], Uid) ->
	Sql = io_lib:format(?UPDATE_XIANYUAN_JJIE,[Jjie, Sweetness, Uid]),
	db:execute(Sql).

%% 更新甜蜜度
%% @param Sweetness 甜蜜度
%% @param Uid		玩家Id
update_sweet(Sweetness, Uid) ->
	Sql = io_lib:format(?UPDATE_XIANYUAN_SWEET,[Sweetness, Uid]),
	db:execute(Sql).

%% 加载指定玩家仙缘信息
%% @param Uid 玩家ID
%% @return [#player_xianyuan]
load(Uid)->
	%%加载数据库仙缘信息，如果没有，直接新建一条记录。
	case find(Uid) of
		 []->
			 insert(Uid),
			 #player_xianyuan{uid=Uid, ptype2=1, sweetness=1000};
		 L -> 
			 write_player_xianyuan(L)
	end.

%%查找玩家的仙缘信息
find(Uid)->
	db:get_row(io_lib:format(?FIND_XIANYUAN, [Uid])).

%%插入记录
insert(Uid)->
    Sql = io_lib:format(?INSERT_XIANYUAN, [Uid,1,1000]), %% --> 上一次修炼类型初始化为1
	db:execute(Sql).

%%将数据库记录转换
write_player_xianyuan([
					  Uid,       %%玩家ID,
					  HpMp,      %%气血内功等级,
					  Def,       %%防御内功等级,
					  Doom,      %%命中内功等级,
					  Jook,      %%闪避内功等级,
					  Tenacity,  %%坚韧内功等级,
					  Sudatt,    %%暴击内功等级,
					  Att,       %%攻击内功等级,
					  Firedef,   %%火坑内功等级,
					  Icedef,    %%冰抗内功等级,
					  Drugdef,   %%毒抗内功等级,
					  Jjie,      %%境界等级,共4个
					  Ptype,	 %%当前修炼类型
					  Ptype2,	 %%上一次修炼类型
                      Cdtime,	 %%开始CD时间
					  Sweetness  %%拥有甜蜜度
        			])->
	#player_xianyuan{
          uid=Uid,			%%玩家ID,
		  hpmp=HpMp,		%%气血、内力内功等级,
		  def=Def,			%%防御内功等级,
		  doom=Doom,		%%命中内功等级,
		  jook=Jook,		%%闪避内功等级,
		  tenacity=Tenacity,  %%坚韧内功等级,
		  sudatt=Sudatt,    %%暴击内功等级,
		  att=Att,			%%攻击内功等级,
		  firedef=Firedef,  %%火坑内功等级,
		  icedef=Icedef,    %%冰抗内功等级,
		  drugdef=Drugdef,  %%毒抗内功等级,
		  jjie=Jjie,		%%境界等级,共4个
		  ptype=Ptype ,		%%当前修炼类型
		  ptype2=Ptype2,    %%上一次修炼类型
		  cdtime=Cdtime,     %%开始CD时间
		  sweetness = Sweetness  %%拥有甜蜜度
        }.

%% 获取IdB玩家仙缘属性
%% @param  IdA 自己Id
%% @param  IdB 其它玩家Id
%% @return [XY1, XY2, XY3, XY4, XY5, XY6, XY7, XY8, XY9, XY10,XY1_1, XY2_1, XY3_1,
%%			XY4_1, XY5_1, XY6_1, XY7_1, XY8_1, XY9_1, XY10_1,XYLevel]
player_xianyuan_attribute(IdA, IdB) ->
	case IdA =/= IdB of
		true ->			
			case lib_player:get_pid_by_id(IdB) of
				Pid when is_pid(Pid) ->
					[Value1, Value2, Value3, Value4, Value5, Value6, Value7,Value8, Value9, Value10, Value1_1, Value2_1,
					Value3_1, Value4_1, Value5_1, Value6_1, Value7_1, Value8_1, Value9_1, Value10_1,JLevel] = gen_server:call(Pid, {'xianyuan_total_attribute'});	
				_Other ->
					[Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, Value10,Value1_1, Value2_1,
					Value3_1, Value4_1, Value5_1, Value6_1, Value7_1, Value8_1, Value9_1, Value10_1] =[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],					
					JLevel = 0
			end;
		false ->
			case lib_player:get_player_info(IdA) of
				PS when is_record(PS, player_status) ->
					[Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, Value10, Value1_1, Value2_1,
					Value3_1, Value4_1, Value5_1, Value6_1, Value7_1, Value8_1, Value9_1, Value10_1] = mod_xianyuan:count_attribute_2(PS),
					JLevel = mod_xianyuan:get_JLevel(PS#player_status.player_xianyuan);
				_ ->
					[Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, Value10, Value1_1, Value2_1,
					Value3_1, Value4_1, Value5_1, Value6_1, Value7_1, Value8_1, Value9_1, Value10_1] =[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],					
					JLevel = 0
			end
	end,
	[Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, Value10,  Value1_1,
	Value2_1,Value3_1, Value4_1, Value5_1, Value6_1, Value7_1, Value8_1, Value9_1, Value10_1,JLevel].
	
