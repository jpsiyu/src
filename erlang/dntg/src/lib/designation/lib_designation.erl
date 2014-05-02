%%%--------------------------------------
%%% @Module  : lib_designation
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.19
%%% @Description: 称号
%%%--------------------------------------

-module(lib_designation).
-include("common.hrl").
-include("server.hrl").
-include("designation.hrl").
-include("sql_guild.hrl").
-export([
	get_switch/0,							%% 开关
	online/1,								%% 游戏线玩家登录时初始化
	get_all_by_role/1,						%% 获取玩家所有称号记录
	set_display/2,							%% 在称号面板设置显示称号
	set_hide/3,								%% 在称号面板设置隐藏称号
	bind_design/4,							%% 获得称号
	bind_design_in_server/4,				%% 获得称号，玩家在线会发到玩家游戏线主进程操作
	remove_design_in_server/2,				%% 移除称号，玩家在线会发到玩家游戏线主进程操作
	remove_design_on_my_process/2,			%% 移除称号，从玩家进程调用过来的
	remove_design_by_id/1,					%% 移除称号，通过称号id
	bind_guild_design/2,					%% 帮派战胜利后为帮主及帮众绑定称号
	get_client_design_by_ids/2,				%% 返回前端需要的头顶数据
	get_client_design/1,					%% 返回前端需要的头顶数据
	get_roleids_by_design/1,				%% 查询获得指定称号的玩家ID列表
	get_affected_attr/1,					%% 影响玩家的属性
	bind_1v1_title/2,						%% 绑定跨服1v1头衔称号
	change_name/1,							%% 改名影响称号
	change_name_on_ps_status/2				%% 修改玩家身上的称号名称
]).

%% 称号功能开关：false关，true开
get_switch() ->
	lib_switch:get_switch(designation).

%% 游戏线玩家登录时初始化
%% 返回值给#player_status.designation保存，格式为：[{称号id, 替换后的内容或"", 失效时间戳或0}]
online(RoleId) ->
	case lib_designation_ds:get_all_by_role(RoleId) of
		[] -> [];
		List ->
			NowTime = util:unixtime(),
			lists:foldl(fun(Design, ParamList) ->
				%% 只取出设置了显示的称号
				case Design#role_designation.display =:= 1 of
					true ->
						%% 过期的称号不显示
						case Design#role_designation.end_time > 0 andalso Design#role_designation.end_time =< NowTime of
							true ->
								ParamList;
							_ ->
								BaesDesign = data_designation:get_by_id(Design#role_designation.design_id),
								%% 如果是动态文字称号，需要替换文字
								case BaesDesign#designation.type of
									3 ->
										Content = io_lib:format(BaesDesign#designation.name, [Design#role_designation.content]);
									_ ->
										Content = ""
								end,
								[{Design#role_designation.design_id, Content, Design#role_designation.end_time} | ParamList]
						end;
					_ ->
                        ParamList
				end
			end, [], List)
	end.

%% 移除称号，通过称号id
remove_design_by_id(DesignId) ->
	case db:get_all(io_lib:format(?SQL_DESIGN_GET_ROLE_BY_DESIGN, [DesignId])) of
	    List when is_list(List) ->
			lists:foreach(fun([OldRoleId]) -> 
				remove_design_in_server(OldRoleId, DesignId)
			end, List);
		_ ->
			skip
	end.

%% 获取玩家所有称号记录
get_all_by_role(RoleId) -> 
	lib_designation_ds:get_all_by_role(RoleId).

%% 显示称号
set_display(PS, DesignId) ->
	case get_switch() of
		true ->
			%% 基础检查
			case private_set_display_base_check(PS, DesignId) of
				{error, ErrorCode} ->
					{error, ErrorCode};
				{ok, MyDesign, Design} ->
					case Design#designation.overlying of
						%% 可叠加称号
						1 ->
							%% 检查是否达到可叠加称号的个数上限
							case private_check_special_can_display(PS) of
								{ok} ->
									NewPS = private_set_display_save_result(PS, MyDesign, Design),
									{ok, NewPS};
								{error} ->
									{error, 5}
							end;

						_ ->
							%% 取出普通不可叠加称号，如果有则替换一个；如果没有，则设置该称号
							case private_get_common_design(PS) of
								[] ->
									NewPS = private_set_display_save_result(PS, MyDesign, Design),
									{ok, NewPS};
								DisIds ->
									DisId = hd(DisIds),
									case set_hide(PS, DisId, inside) of
										{error, _HideError} ->
											{error, 0};
										{ok, NewPS, SetType} ->
	                                		ErrNum = case SetType == inside of
                                            	true -> 50;
                                                _ -> 7
                                        	end,

											%% 被替换的称号隐藏掉
											{ok, BinData} = pt_340:write(34002, [ErrNum, DisId, 0]),
           									lib_server_send:send_to_sid(PS#player_status.sid, BinData),

											NewPS2 = private_set_display_save_result(NewPS, MyDesign, Design),
											{ok, NewPS2}
									end
							end
					end
			end;
		_ ->
			{error, 0}
	end.

%% 隐藏称号
set_hide(PS, DesignId, SetType) ->
	case get_switch() of
		true ->
			case private_can_hide(PS, DesignId) of
				{ok, RoleDesign, Design} ->
					%% 设置为隐藏
					NewDesign = RoleDesign#role_designation{display = 0},
					lib_designation_ds:update_design(NewDesign),

					%% 将该称号从#player_status.designation中删除
					NewList = private_remove_id_from_display(DesignId, PS#player_status.designation),
					NewPS = PS#player_status{designation = NewList},

					%% 改变属性
					NewPS2 = private_sub_attr(NewPS, Design),
					NewPS3 = lib_player:count_player_attribute(NewPS2),
					%% 发送属性变化通知
					lib_player:send_attribute_change_notify(NewPS3, 4),

					%% 广播头上的称号变化
					{ok, Bin} = pt_120:write(12096, [NewPS3#player_status.id, NewPS3#player_status.platform, NewPS3#player_status.server_num, NewPS3#player_status.designation]),
					lib_server_send:send_to_area_scene(NewPS3#player_status.scene, NewPS3#player_status.copy_id, NewPS3#player_status.x, NewPS3#player_status.y, Bin),

					{ok, NewPS3, SetType};
				{error, ErrorCode} ->
					{error, ErrorCode}
			end;
		_ ->
			{error, 2}
	end.

%% 返回前端需要的头顶数据
get_client_design_by_ids(_RoleId, DesignList) ->
	List = 
	lists:foldl(fun({DesignId, Content, _EndTime}, ParamList) ->
		Content2 = pt:write_string(Content),
		[<<DesignId:32, Content2/binary>> | ParamList]
	end, [], DesignList),
	{length(List), list_to_binary(List)}.

%% 返回前端需要的头顶数据
get_client_design(PS) ->
	get_client_design_by_ids(PS#player_status.id, PS#player_status.designation).

%% 获得称号
%% RoleId			玩家ID
%% DesignId			称号ID
%% ReplaceContent	替换内容，例如“XXX的相公”称号中的XXX
%% LineType			线路类型，1公共线，0游戏线
bind_design(RoleId, DesignId, ReplaceContent, LineType) ->
	case get_switch() of
		true ->
			case data_designation:get_by_id(DesignId) of
				%% 称号没有配置，不处理
				[] ->
					skip;
				BaseDesign ->
					NowTime = util:unixtime(),

					%% 取出玩家现在的称号及显示情况
					OwnDesignList = lib_designation_ds:get_all_by_role(RoleId),

					%% 判断自己是不是已经有该称号
					case private_get_owned_by_id(OwnDesignList, DesignId) of
						%% 没有获得该称号则插入称号数据
						[] ->
                            case BaseDesign#designation.type == 5 of
                                true ->
                                    DesignationList = lib_designation_ds:get_design_by_role_type(RoleId, BaseDesign#designation.type),
                                    case DesignationList of
                                        [] ->
                                            lib_designation_ds:insert(RoleId, BaseDesign#designation.type, DesignId, 0, ReplaceContent, util:unixtime(), BaseDesign#designation.time_limit);
                                        [[_RoleId, _DesignType, _DesignId]] ->
                                            lib_designation_ds:update_design_by_role_type(DesignId, NowTime, RoleId, BaseDesign#designation.type)
                                    end;
                                _Other ->
                                   lib_designation_ds:insert(RoleId, BaseDesign#designation.type, DesignId, 0, ReplaceContent, util:unixtime(), BaseDesign#designation.time_limit)
                            end,
							case BaseDesign#designation.type == 3 andalso ReplaceContent /= "" of
								true ->
									Content = io_lib:format(BaseDesign#designation.name, [ReplaceContent]);
								_ ->
									Content = BaseDesign#designation.name
							end,

							{ok, BinData} = pt_340:write(34003, [DesignId, 0, Content]),
							lib_server_send:send_to_uid(RoleId, BinData);

						%% 有称号则更新数据
						[OldDesign] ->
							EndTime = case BaseDesign#designation.time_limit > 0 of
								true -> NowTime + BaseDesign#designation.time_limit;
								_ -> 0
							end,
							lib_designation_ds:update_design(
								OldDesign#role_designation{
									end_time = EndTime,
									content = ReplaceContent
								}
							);
						_ ->
							skip
					end,
					%% 判断是不是唯一称号，是的话其他人的该称号需要删除
					private_remove_other_design(BaseDesign, RoleId, LineType),
                    case BaseDesign#designation.type == 5 of
                        true -> 
                            {BaseDesign#designation.id, "", 0};
                        false ->
                            skip
                    end
			end;
		_ ->
			skip
	end.

%% 绑定称号
%% 如果玩家在线，发到玩家游戏线绑定，如果不在线，直接绑定
%% LineType: 1公共线，0游戏线
bind_design_in_server(RoleId, DesignId, ReplaceContent, LineType) ->
	case misc:get_player_process(RoleId) of
		Pid when is_pid(Pid) ->
			gen_server:cast(Pid, {bind_design, [RoleId, DesignId, ReplaceContent]});
		_ ->
			bind_design(RoleId, DesignId, ReplaceContent, LineType)
	end.

%% 移除称号
%% 如果玩家在线，发到玩家游戏线移除；如果不在线，直接删除
remove_design_in_server(RoleId, DesignId) ->
	case misc:get_player_process(RoleId) of
		Pid when is_pid(Pid) ->
			gen_server:cast(Pid, {remove_design, [RoleId, DesignId]});
		_ ->
			lib_designation_ds:delete_design_by_id(RoleId, DesignId)
	end.

%% 在自己进程移除称号
remove_design_on_my_process(PS, DesignId) ->
	BaseDesign = data_designation:get_by_id(DesignId),
	case BaseDesign =/= [] of
		true ->
			%% 删除称号表中的记录
			lib_designation_ds:delete_design_by_id(PS#player_status.id, DesignId),

			%% 如果称号已经设置为显示，需要脱下来并扣回属性
			case private_check_if_set_display(DesignId, PS#player_status.designation) of
				true ->
					NewList = private_remove_id_from_display(DesignId, PS#player_status.designation),
					NewPS = PS#player_status{designation = NewList},
					%% 改变属性
					NewPS2 = private_sub_attr(NewPS, BaseDesign),
					NewPS3 = lib_player:count_player_attribute(NewPS2),
					lib_player:send_attribute_change_notify(NewPS3, 4),

					{ok, BinData} = pt_340:write(34002, [1, BaseDesign#designation.id, 0]),
		   			lib_server_send:send_to_sid(PS#player_status.sid, BinData),

					%% 广播头上的称号消失
					{ok, Bin} = pt_120:write(12096, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num, NewList]),
					lib_server_send:send_to_area_scene(PS#player_status.scene, PS#player_status.copy_id, PS#player_status.x, PS#player_status.y, Bin),

					NewPS3;
				_ ->
					PS
			end;
		_ ->
			PS
	end.

%% 绑定跨服头衔称号
bind_1v1_title(RoleId, DesignId) ->
	RawList = [202301,202302,202303,202304,202305,202306,202307,202308],
	case get_all_by_role(RoleId) of
		[] ->
			bind_design_in_server(RoleId, DesignId, "", 1);
		List ->
			Ids = [Rd#role_designation.design_id || Rd <- List, lists:member(Rd#role_designation.design_id, RawList)],
			case lists:member(DesignId, Ids) of
				true ->
					Ids2 = lists:dropwhile(fun(Id) -> 
						DesignId =:= Id
					end, Ids),
					[remove_design_in_server(RoleId, Id) || Id <- Ids2];
				_ ->
					[remove_design_in_server(RoleId, Id) || Id <- Ids],
					bind_design_in_server(RoleId, DesignId, "", 1)
			end
	end.

%% 获取称号影响的玩家属性
get_affected_attr(PS) ->
	DefaultAttr = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	F = fun({DesignId, _Content, _EndTime}, Attr) ->
		case data_designation:get_by_id(DesignId) of
			[] ->
				Attr;
			BaseDesign ->
				private_count_attr_list(Attr, BaseDesign)
		end
	end,
	lists:foldl(F, DefaultAttr, PS#player_status.designation).

%% 改名影响称号
change_name(PS) ->
	ParnerId = PS#player_status.marriage#status_marriage.parner_id,
	case ParnerId > 0 of
		true ->
			%% 更新数据表，将名字替换为最新
			DesignId = case PS#player_status.sex of
				1 -> 201802;
				2 -> 201801
			end,
			db:execute(io_lib:format(?SQL_DESIGN_CHANGE_REPLACE, [PS#player_status.nickname, ParnerId, DesignId])),

			%% 刷新玩家头上的称号
			lib_player:update_player_info(ParnerId, [{change_design, [DesignId, PS#player_status.nickname]}]);
		_ ->
			skip
	end.

%% 修改玩家身上的称号称号
change_name_on_ps_status(PS, [DesignId, NickName]) ->
	BaesDesign = data_designation:get_by_id(DesignId),
	case BaesDesign#designation.type of
		3 ->
			Content = io_lib:format(BaesDesign#designation.name, [NickName]);
		_ ->
			Content = ""
	end,
	NewDesignation = lists:map(fun({RDesignId, ROldName, REndTime}) -> 
		case RDesignId =:= DesignId of
			true ->
				{RDesignId, Content, REndTime};
			_ ->
				{RDesignId, ROldName, REndTime}
		end
	end, PS#player_status.designation),
	PS#player_status{designation = NewDesignation}.

%% 计算影响玩家属性的值
private_count_attr_list(Attr, BaseDesign) ->
	[Att, Def, HP, MP, Forza, Agile, Wit, Hit, Dodge, Crit, Ten, Res, Thew, Fire, Ice, Drug] = Attr,
	[
		Att + BaseDesign#designation.att,
		Def + BaseDesign#designation.def,
		HP + BaseDesign#designation.hp,
		MP + BaseDesign#designation.mp,
		Forza + BaseDesign#designation.forza + BaseDesign#designation.addbase,
		Agile + BaseDesign#designation.agile + BaseDesign#designation.addbase,
		Wit + BaseDesign#designation.wit + BaseDesign#designation.addbase,
		Hit + BaseDesign#designation.hit,
		Dodge + BaseDesign#designation.dodge,
		Crit + BaseDesign#designation.crit,
		Ten + BaseDesign#designation.ten,
		Res + BaseDesign#designation.res,
		Thew + BaseDesign#designation.thew + BaseDesign#designation.addbase,
		Fire + BaseDesign#designation.fire + BaseDesign#designation.res,
		Ice + BaseDesign#designation.ice + BaseDesign#designation.res,
		Drug + BaseDesign#designation.drug + BaseDesign#designation.res
	].

%% 查询获得指定称号的玩家ID列表
get_roleids_by_design(DesignId) ->
	Sql = io_lib:format(?SQL_DESIGN_GET_ROLE_BY_DESIGN, [DesignId]),
	case db:get_all(Sql) of
		[] ->	[];
		List -> [RoleId || [RoleId] <- List]
	end.

%% [公共线] 帮战结束，为帮主及帮众绑定称号
bind_guild_design(GuildId, LineType) ->
	%% 找出所有帮派成员
	case db:get_all(io_lib:format(?SQL_GUILD_SELECT_ALL_MEMBER_ID, [GuildId])) of
		[] ->
			skip;
		List ->
			%% 找出帮主，单独为帮主绑定一个称号
			MasterIds = [Id || [Id, Position] <- List, Position =:=1],
			MasterId = hd(MasterIds),
			case is_integer(MasterId) of
				true ->
					bind_design_in_server(MasterId, ?DESIGN_GUILD_MASTER_ID, "", LineType);
				_ ->
					skip
			end,

			%% 帮众成员id列表
			MemberList = [Id2 || [Id2, Position2] <- List, Position2 /=1],

			%% 查出上一届谁获得帮众的称号
			case get_roleids_by_design(?DESIGN_GUILD_MEMBER_ID) of
				%% 没有人获得，则为当前帮众直接绑定称号
				[] ->
					[bind_design_in_server(MemberId, ?DESIGN_GUILD_MEMBER_ID, "", LineType) || MemberId <- MemberList];
				RoleList ->
					%% 删除已经获得该称号的玩家的称号
					[remove_design_in_server(RemoveId, ?DESIGN_GUILD_MEMBER_ID) || RemoveId <- RoleList],
					[bind_design_in_server(BindRoleId, ?DESIGN_GUILD_MEMBER_ID, "", LineType) || BindRoleId <- MemberList]

			end
    end.

%% 在已经获得的称号里面找出指定称号
private_get_owned_by_id(OwnDesignList, DesignId) ->
	F = fun(RD) ->
		#role_designation{role_id = _RoleId, design_type = _DesignType, design_id = OldDesignId, display = _Display, content = _Content, get_time = _GetTime, end_time = _EndTime} = RD,
		if 
			OldDesignId =:= DesignId -> true;
			true -> false
		end
	end,
	lists:filter(F, OwnDesignList).

%% 唯一称号处理
%% BaseDesign		#designation
%% RoleId			玩家ID
%% LineType			线路类型：1公共线，0游戏线
private_remove_other_design(BaseDesign, RoleId, LineType) ->
	case BaseDesign#designation.onlyone =:= 1 of
		true ->
			case lib_player:get_player_low_data(RoleId) of
				[NickName1, Sex1, _, Career1, Realm1 | _] ->
					RoleList = get_roleids_by_design(BaseDesign#designation.id),
					DesignStat = lib_designation_ds:get_stat(BaseDesign#designation.id),
					case DesignStat of
						%% 之前没有人得到过，属于第一个获得的人
						[] ->
							lib_designation_ds:insert_stat(BaseDesign#designation.id, BaseDesign#designation.type, RoleId, NickName1),
							%% 首次获得称号传闻
							case BaseDesign#designation.notice > 0 of
								true ->
									private_send_first_get_design(
										RoleId, Realm1, NickName1, Sex1, Career1, BaseDesign#designation.id, LineType
									);
								_ ->
									skip	
							end;

						%% 非第一个人获得
						[_, _, OldRoleId, _] ->
							lib_designation_ds:update_stat(BaseDesign#designation.id, RoleId, NickName1),

							%% 当新获得称号的玩家跟之前的玩家不一样时，才需要发传闻
							case RoleId =/= OldRoleId of
								true ->
								    %% 删除之前的玩家获得的称号
									remove_design_in_server(OldRoleId, BaseDesign#designation.id),

									%% 发传闻
									case BaseDesign#designation.notice > 0 of
										true ->
											[SendName, SendSex, _, SendCareer, SendRealm | _] = lib_player:get_player_low_data(OldRoleId),
											private_send_get_design(
												BaseDesign#designation.notice, 
												RoleId, Realm1, NickName1, Sex1, Career1, 0,
												OldRoleId, SendRealm, SendName, SendSex, SendCareer, 0,
												BaseDesign#designation.id, LineType
											);
										_ ->
											skip	
									end;
								_ ->
									skip
							end,

							%% 删除有可能存在的，多余的玩家获得了该称号
							lists:foreach(fun(RId) -> 
								case RId /= RoleId andalso RId /= OldRoleId of
									true ->
										remove_design_in_server(RId, BaseDesign#designation.id);
									_ ->
										skip
								end
							end, RoleList)
					end;
				_ ->
					skip
			end;
		_ ->
			skip
	end.

%% 设置显示称号的基本检查
private_set_display_base_check(PS, DesignId) ->
	case private_check_if_set_display(DesignId, PS#player_status.designation) of
		true ->
			{error, 4}; %% 同个称号已经存在
		_ ->
			case lib_designation_ds:get_by_design_id(PS#player_status.id, DesignId) of
				[] -> 
					{error, 2}; %% 未获得该称号
				MyDesign ->
					case MyDesign#role_designation.display =:= 1 of
						true -> 
							{error, 0}; %% 已经设置为显示
						_ ->
							case data_designation:get_by_id(DesignId) of
								[] -> 
									{error, 0}; %% 称号没有配置数据
								Design ->
									case Design#designation.display =:= 0 of
										true -> 
											{error, 4}; %% 称号不能显示
										_ ->
											case MyDesign#role_designation.end_time > 0 andalso MyDesign#role_designation.end_time < util:unixtime() of
												true ->
													{error, 3}; %% 显示时间已过
												_ ->
													{ok, MyDesign, Design}
											end
									end
							end
					end
			end
	end.

%% 判断称号是否已经被设置为显示
%% 返回：bool
private_check_if_set_display(DesignId, DesignList) ->
	lists:any(fun({Id, _Content, _EndTime}) -> 
		Id == DesignId
	end, DesignList).

%% 将称号id从显示的数据里面移除掉
%% 返回：[{id,content},...]
private_remove_id_from_display(DesignId, DesignList) ->
	lists:filter(fun({Id, _Content, _EndTime}) -> 
		Id /= DesignId
	end, DesignList).

%% 设置为显示
private_set_display_save_result(PS, RoleDesign, Design) ->
	NewDesign = RoleDesign#role_designation{display = 1},
	lib_designation_ds:update_design(NewDesign),
	%% 将该称号加到#player_status.designation
	case Design#designation.type of
		3 ->
			Content = io_lib:format(Design#designation.name, [RoleDesign#role_designation.content]);
		_ ->
			Content = ""
	end,
	NewList = [{Design#designation.id, Content, NewDesign#role_designation.end_time} | PS#player_status.designation],
	NewPS = PS#player_status{designation = NewList},
	%% 改变属性
	NewPS2 = private_add_attr(NewPS, Design),
	NewPS3 = lib_player:count_player_attribute(NewPS2),
	%% 发送属性变化通知
	lib_player:send_attribute_change_notify(NewPS3, 4),
	NewPS3.

%% 是否可以设置称号为不显示
private_can_hide(PS, DesignId) ->
	case lib_designation_ds:get_by_design_id(PS#player_status.id, DesignId) of
		[] -> 
			{error, 2}; %% 未获得该称号
		MyDesign ->
			case MyDesign#role_designation.display =:= 0 of
				true -> 
					{error, 3}; %% 本来就是没显示
				_ ->
					case data_designation:get_by_id(DesignId) of
						[] -> 
							{error, 4}; %%没有称号配置数据
						Design ->
							{ok, MyDesign, Design}
					end
			end
	end.

%% 判断可叠加类称号显示个数是否达到上限
private_check_special_can_display(PS) ->
	F = fun({Id, _Content, _EndTime}, Num) ->
		TmpDesign = data_designation:get_by_id(Id),
		case is_record(TmpDesign, designation) andalso TmpDesign#designation.overlying =:= 1 of
			true ->
				Num + 1;
			_ ->
				Num
		end
	end,
	NewNum = lists:foldl(F, 0, PS#player_status.designation),
	case NewNum >= data_designation:get_max_flaunt_num() of
		true ->
			{error};
		_ ->
			{ok}
	end.

%% 取出非叠加称号id列表
%% 返回：[id, ...]
private_get_common_design(PS) ->
	F = fun({Id, _Content, _EndTime}, DisList) ->
		TmpDesign = data_designation:get_by_id(Id),
		case is_record(TmpDesign, designation) andalso TmpDesign#designation.overlying =:= 0 of
			true ->
				[Id | DisList];
			_ ->
				DisList
		end
	end,
	lists:foldl(F, [], PS#player_status.designation).

%% 增加玩家属性
private_add_attr(PS, Design) ->
	PS#player_status{
		att = PS#player_status.att + Design#designation.att,						% 攻击
		def = PS#player_status.def + Design#designation.def,						% 防御
		hp_lim = PS#player_status.hp_lim + Design#designation.hp,					% 气血上限
		mp = PS#player_status.mp + Design#designation.mp,							% 内力
		forza = PS#player_status.forza + Design#designation.forza + Design#designation.addbase,		% 力量
		agile = PS#player_status.agile + Design#designation.agile + Design#designation.addbase,		% 身法
		wit = PS#player_status.wit + Design#designation.wit + Design#designation.addbase,			% 灵力
		thew = PS#player_status.thew + Design#designation.thew + Design#designation.addbase,		% 体质
		hit = PS#player_status.hit + Design#designation.hit,						% 命中率
		dodge = PS#player_status.dodge + Design#designation.dodge,					% 躲避
		crit = PS#player_status.crit + Design#designation.crit,						% 暴击
		ten = PS#player_status.ten + Design#designation.ten,						% 坚韧
		fire = PS#player_status.fire + Design#designation.fire + Design#designation.res,	% 火
		ice = PS#player_status.ice + Design#designation.ice + Design#designation.res,		% 冰
		drug = PS#player_status.drug + Design#designation.drug + Design#designation.res		% 毒
	}.

%% 减少玩家属性
private_sub_attr(PS, Design) ->
	PS1 = case PS#player_status.att - Design#designation.att > 0 of
		true -> PS#player_status{att = PS#player_status.att - Design#designation.att};
		_ -> PS#player_status{att = 1}
	end,
	PS2 = case PS1#player_status.def - Design#designation.def > 0 of
		true -> PS1#player_status{def = PS1#player_status.def - Design#designation.def};
		_ -> PS1#player_status{def = 1}
	end,
	PS3 = case PS2#player_status.hp_lim - Design#designation.hp > 0 of
		true -> PS2#player_status{hp_lim = PS2#player_status.hp_lim - Design#designation.hp};
		_ -> PS2#player_status{hp_lim = 1}
	end,
	PS4 = case PS3#player_status.mp - Design#designation.mp > 0 of
		true -> PS3#player_status{mp = PS3#player_status.mp - Design#designation.mp};
		_ -> PS3#player_status{mp = 1}
	end,
	PS5 = case PS4#player_status.forza - Design#designation.forza - Design#designation.addbase > 0 of
		true -> PS4#player_status{forza = PS4#player_status.forza - Design#designation.forza - Design#designation.addbase};
		_ -> PS4#player_status{forza = 1}
	end,
	PS6 = case PS5#player_status.agile - Design#designation.agile - Design#designation.addbase > 0 of
		true -> PS5#player_status{agile = PS5#player_status.agile - Design#designation.agile - Design#designation.addbase};
		_ -> PS5#player_status{agile = 1}
	end,
	PS7 = case PS6#player_status.wit - Design#designation.wit - Design#designation.addbase > 0 of
		true -> PS6#player_status{wit = PS6#player_status.wit - Design#designation.wit - Design#designation.addbase};
		_ -> PS6#player_status{wit = 1}
	end,
	PS8 = case PS7#player_status.hit - Design#designation.hit > 0 of
		true -> PS7#player_status{hit = PS7#player_status.hit - Design#designation.hit};
		_ -> PS7#player_status{hit = 1}
	end,
	PS9 = case PS8#player_status.dodge - Design#designation.dodge > 0 of
		true -> PS8#player_status{dodge = PS8#player_status.dodge - Design#designation.dodge};
		_ -> PS8#player_status{dodge = 1}
	end,
	PS10 = case PS9#player_status.crit - Design#designation.crit > 0 of
		true -> PS9#player_status{crit = PS9#player_status.crit - Design#designation.crit};
		_ -> PS9#player_status{crit = 1}
	end,
	PS11 = case PS10#player_status.ten - Design#designation.ten > 0 of
		true -> PS10#player_status{ten = PS10#player_status.ten - Design#designation.ten};
		_ -> PS10#player_status{ten = 1}
	end,
	PS12 = case PS11#player_status.thew - Design#designation.thew - Design#designation.addbase > 0 of
		true -> PS11#player_status{thew = PS11#player_status.thew - Design#designation.thew - Design#designation.addbase};
		_ -> PS11#player_status{thew = 1}
	end,
	PS13 = case PS12#player_status.fire - Design#designation.fire - Design#designation.res > 0 of
		true -> PS12#player_status{fire = PS12#player_status.fire - Design#designation.fire - Design#designation.res};
		_ -> PS12#player_status{fire = 1}
	end,
	PS14 = case PS13#player_status.ice - Design#designation.ice - Design#designation.res > 0 of
		true -> PS13#player_status{ice = PS13#player_status.ice - Design#designation.ice - Design#designation.res};
		_ -> PS13#player_status{ice = 1}
	end,
	PS15 = case PS14#player_status.drug - Design#designation.drug - Design#designation.res > 0 of
		true -> PS14#player_status{drug = PS14#player_status.drug - Design#designation.drug - Design#designation.res};
		_ -> PS14#player_status{drug = 1}
	end,
	PS16 = case PS15#player_status.hp > PS15#player_status.hp_lim of
		true -> PS15#player_status{hp = PS15#player_status.hp_lim};
		_ -> PS15
	end,
	PS16.

%% 发传闻：首次获得需要发传闻的称号
private_send_first_get_design(RoleId, Realm, NickName, Sex, Career, DesignId, LineType) ->
	lib_chat:send_TV({all}, LineType, 2, [
		"chenghao", 1, RoleId, Realm, NickName, Sex, Career, 0, DesignId				
	]).

%%  发传闻：非首次获得需要发传闻的称号
private_send_get_design(Notice, RoleId1, Realm1, NickName1, Sex1, Career1, Head1, RoleId2, Realm2, NickName2, Sex2, Career2, Head2, DesignId, LineType) ->
	if
		Notice =:= 1 ->
			lib_chat:send_TV({all}, LineType, 2, [
				"chenghao", 3, RoleId1, Realm1, NickName1, Sex1, Career1, Head1, RoleId2, Realm2, NickName2, Sex2, Career2, Head2, DesignId
			]);
		Notice =:= 2 ->
			lib_chat:send_TV({all}, LineType, 2, [
				"chenghao", 2, RoleId1, Realm1, NickName1, Sex1, Career1, Head1, RoleId2, Realm2, NickName2, Sex2, Career2, Head2, DesignId
			]);
		true ->
			skip
	end.
