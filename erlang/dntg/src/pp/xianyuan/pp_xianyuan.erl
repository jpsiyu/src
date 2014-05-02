%%%--------------------------------------
%%% @Module  :  pp_xianyuan 
%%% @Author  :  hekai
%%% @Email   :  hekai@jieyou.cn
%%% @Created :  2012-9-27
%%% @Description: 仙缘系统
%%%--------------------------------------

-module(pp_xianyuan).
-include("server.hrl").
-include("common.hrl").
-include("xianyuan.hrl").
-export([handle/3]).

%% 仙缘修炼
handle(27201, PS, [Xy_type])
	 when (Xy_type >0 andalso Xy_type<11)->
		Register_time = PS#player_status.marriage#status_marriage.register_time,
		Parner_id = PS#player_status.marriage#status_marriage.parner_id,
		case Register_time>0 andalso Parner_id>0 of
			true ->
				Closeness = lib_relationship:find_intimacy_dict(PS#player_status.pid,
											PS#player_status.id, Parner_id),						
				Result = mod_xianyuan:xy_practice(PS#player_status.player_xianyuan, Xy_type, Closeness, PS),
				case Result of
					[1, Need_closeness] -> 
						Is_ok = lib_relationship:update_Intimacy(PS#player_status.pid,
											PS#player_status.id, Parner_id, -Need_closeness),
						case Is_ok of
							ok ->							
								mod_xianyuan:xy_practice_commit(PS#player_status.player_xianyuan, Xy_type, Closeness, Need_closeness, PS),
								ErrorCode = 1;
							_ -> ErrorCode = 9
						end;						
					[Code, _Need_closeness]  ->
						ErrorCode = Code
				end;
			false ->
				ErrorCode = 6
		end,
		{ok,BinData} = pt_272:write(27201,[Xy_type,ErrorCode]),
	    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
		handle(27203, PS, []);

%% 修炼加速
handle(27202, PS, _) -> 
	Result = mod_xianyuan:clearCD(PS#player_status.player_xianyuan, PS),	
	case Result of
		ok -> handle(27203, PS, []);
		Others ->
			%% 更新玩家属性
			PS2 = lib_player:count_player_attribute(Others),		
			lib_player:send_attribute_change_notify(PS2, 4),
			handle(27203, PS2, []),
			{ok,PS2}
	end;

%% 仙缘修炼、境界信息
handle(27203, PS, _) ->	
	Register_time = PS#player_status.marriage#status_marriage.register_time,
	Parner_id = PS#player_status.marriage#status_marriage.parner_id,
	{Xtype, Xlv, Jlv, RestCdTime, IsCDing,NewPS,NotifyFlag} = mod_xianyuan:xy_info(PS#player_status.player_xianyuan, PS),		
	Closeness = lib_relationship:find_intimacy_dict(PS#player_status.pid,
		PS#player_status.id, Parner_id),
	case Closeness =:=void of
		true -> 
			Closeness2 = 0;
		false -> 
			Closeness2 = Closeness
	end,	
	case Register_time>0 andalso Parner_id>0 of
		true -> 
			Sweetness = mod_xianyuan:get_sweetness(PS#player_status.player_xianyuan),
			case lib_player:get_player_info(Parner_id, name_career) of
				false ->
					case get(xy_parner) of
						undefined ->
							SQL = io_lib:format(?FIND_PARNER, [Parner_id]),
							Find_result = db:get_row(SQL),
							case Find_result of
								[_Parnet_career, _Parnet_name] ->
									Parnet_career = _Parnet_career, Parnet_name =_Parnet_name;
								_Other ->
									Parnet_career=0,Parnet_name=""
							end,
							put(xy_parner, [Parnet_career,Parnet_name]);
						[Career, NickName] ->
							Parnet_career = Career, Parnet_name = NickName
					end;
				[NickName, Career] ->
					Parnet_name = NickName,
					Parnet_career = Career								
			end;
		false ->
			case NewPS#player_status.marriage#status_marriage.divorce_state =:= 1 of
				true ->  Sweetness = mod_xianyuan:get_sweetness(NewPS#player_status.player_xianyuan);
				false -> Sweetness=0
			end,
			Parnet_career=0,Parnet_name=""
	end,
    Skill_lv_1 = NewPS#player_status.cp_skill#couple_skill.lv_1,
	Skill_lv_2 = NewPS#player_status.cp_skill#couple_skill.lv_2,
	Player_xianyuan = mod_xianyuan:getPlayer_xianyuan(NewPS#player_status.player_xianyuan),
	Ptype2 = Player_xianyuan#player_xianyuan.ptype2,	
	case Xtype=:=10 andalso Xlv=:=?MAX_XY_LV andalso Ptype2=:=10 of
		true ->  NewIsCDing = 2;
		false -> NewIsCDing = IsCDing
	end,
	{ok, BinData} = pt_272:write(27203, [Xtype, Xlv, Jlv, RestCdTime, NewIsCDing, Closeness2, Sweetness, Parnet_career,Parnet_name, Skill_lv_1, Skill_lv_2]),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData),
	case NotifyFlag =:= 1 of
		true ->
			%% 更新玩家属性
			NewPS2 = lib_player:count_player_attribute(NewPS),
			lib_player:send_attribute_change_notify(NewPS2, 4);
		false -> NewPS2 = NewPS
	end,
	{ok, NewPS2};

%% 使用物品增加甜蜜度
handle(27205, PS, _) ->
	Register_time = PS#player_status.marriage#status_marriage.register_time,
	Parner_id = PS#player_status.marriage#status_marriage.parner_id,
	case Register_time>0 andalso Parner_id>0 of
		true ->
			{ReturnCode, Sweetness_add} = mod_xianyuan:use_sweet_goods(PS),
			case ReturnCode of
				1 -> handle(27203, PS, []);
				_ -> skip
			end;
		false ->
			ReturnCode = 5, Sweetness_add=0
	end,	
	{ok, BinData} = pt_272:write(27205, [ReturnCode, Sweetness_add]),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData);

%% 仙缘修炼总加成
handle(27206, PS, [Uid]) ->
	case Uid =/= PS#player_status.id of
		true ->			
			case lib_player:get_pid_by_id(Uid) of
				Pid when is_pid(Pid) ->
					[Value1, Value2, Value3, Value4, Value5, Value6, Value7,Value8, Value9, Value10, Value1_1, Value2_1,
					Value3_1, Value4_1, Value5_1, Value6_1, Value7_1, Value8_1, Value9_1, Value10_1, JLevel]
						= gen_server:call(Pid, {'xianyuan_total_attribute'});	
				_Other ->
					[Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, Value10,Value1_1, Value2_1,
					Value3_1, Value4_1, Value5_1, Value6_1, Value7_1, Value8_1, Value9_1, Value10_1] =[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],					
					JLevel = 0
			end;
		false ->
			[Value1, Value2, Value3, Value4, Value5, Value6, Value7, Value8, Value9, Value10, Value1_1, Value2_1,
			Value3_1, Value4_1, Value5_1, Value6_1, Value7_1, Value8_1, Value9_1, Value10_1] = mod_xianyuan:count_attribute_2(PS),
			JLevel = mod_xianyuan:get_JLevel(PS#player_status.player_xianyuan)
	end,	
	{ok, BinData} = pt_272:write(27206, [Value1, Value2, Value3, Value4, Value5, Value6, Value7,Value8, Value9, Value10, Value1_1, Value2_1,
					Value3_1, Value4_1, Value5_1, Value6_1, Value7_1, Value8_1, Value9_1, Value10_1, JLevel]),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData);

%% 释放夫妻技能
handle(27207, PS, [Skill_id])
	when (Skill_id =:=1040 orelse Skill_id=:=1050)->
	Register_time = PS#player_status.marriage#status_marriage.register_time,
	Parner_id = PS#player_status.marriage#status_marriage.parner_id,
	case Register_time>0 andalso Parner_id>0 of
		true ->
			case lib_player:get_player_info(Parner_id) of
				PlayerStatus when is_record(PlayerStatus, player_status) ->
					[NewPS, ErrorCode, Left_cd] = lib_xianyuan:use_couple_skill(PS, PlayerStatus, Skill_id),
					case ErrorCode =:= 1 of
						true -> lib_marriage_other:add_skill_num(NewPS);
						false -> skip
					end;
				_Other ->
					NewPS=PS, ErrorCode = 3,Left_cd=0
			end;
		false ->
			NewPS=PS, ErrorCode = 2,Left_cd=0
	end,
	{ok,BinData} = pt_272:write(27207,[ErrorCode,Left_cd,Skill_id]),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData),
	{ok, NewPS};

%% 夫妻技能信息
handle(27208, PS, _) ->
	NowTime = util:unixtime(),
	Cp_skill = PS#player_status.cp_skill,
	[Id_1,Lv_1,Cd_1,Id_2,Lv_2,Cd_2] = [Cp_skill#couple_skill.id_1,Cp_skill#couple_skill.lv_1,Cp_skill#couple_skill.cd_1,
										Cp_skill#couple_skill.id_2,Cp_skill#couple_skill.lv_2,Cp_skill#couple_skill.cd_2],
	case Lv_1 >0 of
		true ->
			[_, NeedCd1, _] = data_cp_skill:get(1040, Lv_1),
			case NowTime - Cd_1> NeedCd1 of
				true ->
					LeftCd_1 = 0;
				false ->
					LeftCd_1 = Cd_1+NeedCd1-NowTime
			end;
		false ->
			LeftCd_1 = 0
	end,	
	case Lv_2 >0 of
		true ->
			[_, NeedCd2,_,_] = data_cp_skill:get(1050, Lv_2),
			case NowTime - Cd_2> NeedCd2 of
				true ->
					LeftCd_2 = 0;
				false ->
					LeftCd_2 = Cd_2+NeedCd2-NowTime
			end;
		false ->
			LeftCd_2 = 0
	end,
	Skill =[[Id_1,Lv_1,LeftCd_1],[Id_2,Lv_2,LeftCd_2]],
	{ok,BinData} = pt_272:write(27208,[Skill]),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData);

%% 查看Id玩家仙缘修炼、境界信息
handle(27209, PlayerStatus, [Id]) 
	when PlayerStatus#player_status.id =/= Id->	
	case lib_player:get_player_info(Id, xianyuan_data) of
		 [Register_time, Parner_id, Xian_pid, Skill_lv_1, Skill_lv_2, Pid, Divorce] ->
			 Player_xianyuan = mod_xianyuan:getPlayer_xianyuan(Xian_pid),
			 Xtype = Player_xianyuan#player_xianyuan.ptype2,					
			 _Xlv = lib_xianyuan:get_xianyuan_level(Player_xianyuan, 1, Xtype),
			 case Xtype=:=1 andalso _Xlv=:=0 of
				 true -> Xlv =1;
				 false -> Xlv = _Xlv
			 end,
			 Jlv = Player_xianyuan#player_xianyuan.jjie,					
			 Closeness = lib_relationship:find_intimacy_dict(Pid, Id, Parner_id),
			 case Closeness =:=void of
				 true -> 
					 Closeness2 = 0;
				 false -> 
					 Closeness2 = Closeness
			 end,
			 %% 判断是否结婚
			 case Register_time>0 andalso Parner_id>0 of
				 true ->
					 Sweetness = Player_xianyuan#player_xianyuan.sweetness, 
					 case PlayerStatus#player_status.id =/= Parner_id of
						 true ->									
							 case lib_player:get_player_info(Parner_id, name_career) of
								 false ->
									 SQL = io_lib:format(?FIND_PARNER, [Parner_id]),
									 Find_result = db:get_row(SQL),
									 case Find_result of
										 [_Parnet_career, _Parnet_name] ->
											 Parnet_career = _Parnet_career, Parnet_name =_Parnet_name;
										 _Other ->
											 Parnet_career=0,Parnet_name=""
									 end;
								 [NickName, Career] ->
									 Parnet_name = NickName,
									 Parnet_career = Career																							
							 end;
						 false ->
							 Parnet_career = PlayerStatus#player_status.career,
							 Parnet_name = PlayerStatus#player_status.nickname
					 end;
				 false ->
					 case Divorce =:= 1 of
						 true ->  Sweetness = Player_xianyuan#player_xianyuan.sweetness;
						 false -> Sweetness=0
					 end,
					 Parnet_career=0,Parnet_name=""
			 end;
		_Other ->
			Xtype=1, Xlv=1, Jlv=0, Closeness2=0, Sweetness=0, Parnet_career=0,Parnet_name="", Skill_lv_1=0, Skill_lv_2=0
	end,
	RestCdTime=0, IsCDing=0,
	{ok, BinData} = pt_272:write(27209, [Xtype, Xlv, Jlv, RestCdTime, IsCDing, Closeness2, Sweetness, Parnet_career,Parnet_name, Skill_lv_1, Skill_lv_2]),
	lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);

%% 错误处理
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_xianyuan no match", []),
	{error, "pp_xianyuan no match"}.

