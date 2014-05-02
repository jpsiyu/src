%%%--------------------------------------
%% @Module  : lib_special_activity
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-05
%% @Description:      |特殊活动
%% --------------------------------------------------------
-module(lib_special_activity).
-include("common.hrl").
-include("server.hrl").
-include("activity.hrl").
-include("daily.hrl").

-define(OD_START_TIME, {{2001,12,28},{0,0,0}}). %% 活动开始时间  (需要改)
-define(OD_END_TIME, {{2001,1,6},{0,0,0}}). 	%% 活动结束时间  (需要改)
-define(OD_COUNT_TIME, {{2001,12,28},{0,0,0}}). %% 老玩家分界时间(需要改)
-compile(export_all).

%% 获取类型
get_type(PS) ->
	NowTime = util:unixtime(),
	CheckTime02 = util:unixtime(?OD_END_TIME),
	case CheckTime02 >= NowTime of
		true ->
			[{_, Flag}] = is_old_buck([PS#player_status.id]),
			case Flag =:= 0 of
				true ->
					1;
				_ ->
					2
			end;
		false ->
			3
	end.
	
%% 邀请方获取信息
inviter_get_info(PS) ->
	[{_, Flag}] = is_old_buck([PS#player_status.id]),
	NowTime = util:unixtime(),
	CheckTime02 = util:unixtime(?OD_END_TIME),
	TimeLeft = case CheckTime02 >= NowTime of
				   true ->
					   CheckTime02 - NowTime;
				   _ ->
					   0
			   end,
	case Flag =:= 0 of
		true ->
			[NumALl, NumGot] = inviter_get_info_db(PS#player_status.id),
			[1, 534121, NumALl, NumGot, TimeLeft];
		_ ->
			[0, 0, 0, 0, TimeLeft]
	end.

%% 老玩家获取信息
old_buck_get_info(PS) ->
	[{_, Flag}] = is_old_buck([PS#player_status.id]),
	case Flag =:= 0 of
		true ->
			[0, <<>>, []];
		_ ->
			[T1, T2, T3, T4, T5, InviteId, InviteName] = case get({old_buck, PS#player_status.id}) of
				undefined ->
					old_buck_get_info_db(PS#player_status.id);
				R ->
					R
			end,
			PTaskList = [{1, 1, T1, 534116}, {2, 5, T2, 534117}, {3, 2, T3, 534118}, {4, 4, T4, 534119}, {5, 5, T5, 534120}],
			case InviteId == 0 of
				true ->
					[2, InviteName, PTaskList];
				_ ->
					[1, InviteName, PTaskList]
			end
	end.

%% 输入邀请人信息
input_inviter(PS, TargetName) ->
	[{_, Flag}] = is_old_buck([PS#player_status.id]),
	case Flag =:= 0 of
		true -> %% 是邀请人
			0;
		_ -> %% 是老玩家
			case PS#player_status.nickname == TargetName of
				true -> %% 不能填写自己
					4;
				_ ->
					case get_role_id(TargetName) of
						0 -> %% 错误的名字
							3;
						TargetId ->
							[{_, Flag2}] = is_old_buck([TargetId]),
							case Flag2 =/= 0 of
								true ->%% 对象也是老玩家不能被选为邀请人
									2;
								_ ->
									insert_invite_db(PS#player_status.id, TargetId, TargetName)
							end
					end
			end
	end.
	

%% 领取礼包
get_gift(PS, Type, Num) ->
	Go = PS#player_status.goods,
	RoleId = PS#player_status.id,
	[{_, TrueType}] = is_old_buck([PS#player_status.id]),
	case Type =:= TrueType of
		true ->
			case TrueType of
				1 -> %% 老玩家
					[T1, T2, T3, T4, T5, InviteId, InviteName] = old_buck_get_info_db(PS#player_status.id),
					case InviteId =:= 0 of
						true ->
							0;
						false ->
							PTaskList = [{1, 1, T1, 534116}, {2, 5, T2, 534117}, {3, 2, T3, 534118}, {4, 4, T4, 534119}, {5, 5, T5, 534120}],
							case lists:keyfind(Num, 1, PTaskList) of
								{_, CNumNeed, CNumNow, GiftId0} ->
									case CNumNow >= CNumNeed andalso CNumNow < 99999 of
										true ->
											PTaskList2 = lists:keyreplace(Num, 1, PTaskList, {Num, CNumNeed, 99999, GiftId0}),
											[T1New, T2New, T3New, T4New, T5New] = [TNew||{_, _, TNew, _} <-PTaskList2],
%% 													io:format("NeedTime 1 1 1 ~p", [2321]),
											old_buck_update_db(RoleId, T1New, T2New, T3New, T4New, T5New, InviteId, InviteName),
											put({old_buck, RoleId}, [T1New, T2New, T3New, T4New, T5New, InviteId, InviteName]),
											%% 发放物品
											case gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', [], [{GiftId0, 1}]}) of
												ok ->
%% 													io:format("NeedTime 1 1 1 ~p", [2321]),
													1;
												_RR->
%% 													io:format("NeedTime 1 1 2 ~p", [_RR]),
													%% 回写
													old_buck_update_db(RoleId, T1, T2, T3, T4, T5, InviteId, InviteName),
													put({old_buck, RoleId}, [T1, T2, T3, T4, T5, InviteId, InviteName]),
													2
											end;
										_ ->
											0
									end;
								_ ->
									0
							end
					end;
				0 ->
					[NumALl, NumGot] = inviter_get_info_db(PS#player_status.id),
					case NumGot >= NumALl * 5 of
						true ->
							0;
						_ ->
							%% 更新邀请者数据
							inviter_update_db(PS#player_status.id, NumALl, NumGot + 1),
							%% 发放物品
							case gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', [], [{534121, 1}]}) of
								ok ->
									1;
								_RR->
									%% 回写
									inviter_update_db(PS#player_status.id, NumALl, NumGot),
									2
							end
					end
			end;
		_ ->
			0
	end.
	
%% ------------------------------------------------- 分 隔 线 -----------------------------------------------------------------------

%% 登录处理
role_login(RoleId) ->
	[{_, TrueType}] = is_old_buck([RoleId]),
	case TrueType =:= 1 of
		true -> %% 是老玩家初始化信息
			skip;
%% 			old_buck_get_info_db(RoleId);
		false ->
			skip
	end.
	
%% 处理老玩家任务进度
add_old_buck_task(RoleId, Type) ->
	[{_, TrueType}] = is_old_buck([RoleId]),
	case TrueType of
		1 ->
			Data = [RoleId],
			SQL  = case Type of
					   1 ->
						   io_lib:format("UPDATE activity_old_buck SET task_1 = task_1+1 WHERE id = ~p", Data);
					   2 ->
						   io_lib:format("UPDATE activity_old_buck SET task_2 = task_2+1 WHERE id = ~p", Data);
					   3 ->
						   io_lib:format("UPDATE activity_old_buck SET task_3 = task_3+1 WHERE id = ~p", Data);
					   4 ->
						   io_lib:format("UPDATE activity_old_buck SET task_4 = task_4+1 WHERE id = ~p", Data);
					   5 ->
						   io_lib:format("UPDATE activity_old_buck SET task_5 = task_5+1 WHERE id = ~p", Data)
			end,
			db:execute(SQL);
		_ ->
			skip
	end.

%% 根据ID列表批量判断玩家是否老玩家 读取 ETS_OLD_BUCK
%% [{id, type}] ID 和 是否老玩家0 表示不是,1表示
is_old_buck(IDList)->
	%% 获取所有老玩家列表
	OldBuckList = case ets:lookup(?ETS_OLD_BUCK, 0) of
					  [{0, Obj}] ->
						  Obj;
					  [] ->
						  old_buck_init_db()
				  end, 
	NowTime = util:unixtime(),
	CheckTime01 = util:unixtime(?OD_START_TIME),
	CheckTime02 = util:unixtime(?OD_END_TIME),
	NewList = case NowTime < CheckTime02 andalso NowTime > CheckTime01 of
		true ->
			lists:map(fun(Id) ->
							  case lists:member(Id, OldBuckList) of
								  true -> %% 是老玩家
									  {Id, 1};
								  _ ->
									  {Id, 0}
							  end
					  end, IDList);
		false ->
			[{Id, 0}||Id<-IDList]
	end,
	NewList.

%% 当ETS为空的时候读取数据库
old_buck_init_db() ->
	%% 查询条件1
	CheckTime01 = util:unixtime(?OD_COUNT_TIME),
	Data = [45, CheckTime01],
	SQL  = io_lib:format("select a.id from player_low a left join player_login b on a.id=b.id where a.lv >= ~p and b.logout_time <= ~p", Data),
	OldBuckList1 = case db:get_all(SQL) of
		[] ->
			[];
		D ->
			[Dv||[Dv]<-D]
	end,
	%% 查询条件2
	SQL2  = io_lib:format("SELECT id FROM activity_old_buck", []),
	OldBuckList2 = case db:get_all(SQL2) of
		[] ->
			[];
		E ->
			[Ev||[Ev]<-E]
	end,
	OldBuckList = lists:concat([OldBuckList1,OldBuckList2]),
%% 	io:format("OldBuckList ~p~n", [OldBuckList]),
	ets:insert(?ETS_OLD_BUCK, {0, OldBuckList}),
	OldBuckList.

%% 完成邀请人插入(这里不会初始化缓存信息)
insert_invite_db(RoleId, TargetId, TargetName)->
	case get({old_buck, RoleId}) of
		undefined ->
			0;
		[T1, T2, T3, T4, T5, InviteId, _InviteName] ->
			case InviteId =/= 0 of
				true ->
					5;
				_ ->
					case db:transaction(fun() ->insert_invite_db_tran(RoleId, T1, T2, T3, T4, T5, TargetId, TargetName) end) of
%% 					case insert_invite_db_tran(RoleId, T1, T2, T3, T4, T5, TargetId, TargetName) of
						1 ->
				    		put({old_buck, RoleId}, [T1, T2, T3, T4, T5, TargetId, TargetName]),
							1;
						7 -> %% 对方数量满
							7;
						_R ->
%% 							io:format("Format 12 1 ~p~n", [_R]),
							0
					end
			end
	end.

insert_invite_db_tran(RoleId, T1, T2, T3, T4, T5, TargetId, TargetName) ->
	[InviteNum, GiftGot] = inviter_get_info_db(TargetId),
	case InviteNum >= 5 of
		true ->
			7;
		_ ->
			%% 更新邀请者数据
			inviter_update_db(TargetId, InviteNum + 1, GiftGot),
			%% 更新老玩家数据
			old_buck_update_db(RoleId, T1, T2, T3, T4, T5, TargetId, TargetName),
			1
	end.

%% 读取老玩家信息
old_buck_get_info_db(RoleId)->
	Data = [RoleId],
	SQL  = io_lib:format("SELECT task_1, task_2, task_3, task_4, task_5, invite_id, invite_name FROM activity_old_buck where id = ~p", Data),
	case db:get_row(SQL) of
		[T1, T2, T3, T4, T5, InviteId, InviteName]->
			put({old_buck, RoleId}, [T1, T2, T3, T4, T5, InviteId, InviteName]),
			[T1, T2, T3, T4, T5, InviteId, InviteName];
		_->
			old_buck_insert_db(RoleId),
			put({old_buck, RoleId}, [0, 0, 0, 0, 0, 0, ""]),
			[0, 0, 0, 0, 0, 0, ""]
	end.

%% 插入老玩家信息
old_buck_insert_db(RoleId)->
	Data = [RoleId, 0, 0, 0, 0, 0, 0, ""],
	SQL  = io_lib:format("INSERT INTO activity_old_buck (id, task_1, task_2, task_3, task_4, task_5, invite_id, invite_name)VALUES(~p, ~p, ~p, ~p, ~p, ~p, ~p, '~s')", Data),
	db:execute(SQL).

%% 更新老玩家信息
old_buck_update_db(RoleId, T1, T2, T3, T4, T5, InviteId, InviteName)->
	Data = [T1, T2, T3, T4, T5, InviteId, InviteName, RoleId],
	SQL  = io_lib:format("UPDATE activity_old_buck SET task_1=~p, task_2=~p, task_3=~p, task_4=~p, task_5=~p, invite_id=~p, invite_name='~s' where id=~p", Data),
	db:execute(SQL).

%% 读取邀请方数据
inviter_get_info_db(RoleId)->
	Data = [RoleId],
	SQL  = io_lib:format("SELECT invite_num, gift_got FROM activity_ob_invite where id = ~p", Data),
	case db:get_row(SQL) of
		[InviteNum, GiftGot]->
			[InviteNum, GiftGot];
		_->
			inviter_insert_db(RoleId),
			[0, 0]
	end.

%% 插入邀请方信息
inviter_insert_db(RoleId)->
	Data = [RoleId, 0, 0],
	SQL  = io_lib:format("INSERT INTO activity_ob_invite (id, invite_num, gift_got)VALUES(~p, ~p, ~p)", Data),
	db:execute(SQL).

%% 更新邀请方信息
inviter_update_db(RoleId, InviteNum, GiftGot)->
	Data = [InviteNum, GiftGot, RoleId],
	SQL  = io_lib:format("UPDATE activity_ob_invite SET invite_num=~p, gift_got=~p where id=~p", Data),
	db:execute(SQL).

%% 根据名字获取ID
get_role_id(PlayerInfo) when is_list(PlayerInfo) ->
	case lib_player:get_role_id_by_name(PlayerInfo) of
        null ->
            0;
        PlayerId ->
            PlayerId
    end;
get_role_id(PlayerInfo) when is_binary(PlayerInfo) ->
    Name = binary_to_list(PlayerInfo),
    get_role_id(Name);
get_role_id(_) ->
    0.