%%%--------------------------------------
%%% @Module  : lib_butterfly_goods
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.10
%%% @Description: 捕蝴蝶活动涉及到的道具使用
%%%--------------------------------------

-module(lib_butterfly_goods).
-include("server.hrl").
-include("scene.hrl").
-include("butterfly.hrl").
-include("buff.hrl").
-compile(export_all).

%% 使用道具
use_goods(PS, Type, PlayerId) ->
	{SceneId, _, _} = data_butterfly:get_scene(),
	case PS#player_status.scene =:= SceneId of
		true ->
			Bool = lib_butterfly:check_time_from_timer(
				PS#player_status.butterfly#player_butterfly.weekrange,
				PS#player_status.butterfly#player_butterfly.timerange
			),
			case Bool of
				true ->
					ItemNum = private_get_item_num(PS, Type),
					case ItemNum < 1 of
						true ->
							%% 道具不足
							{error, 2};
						_ ->
							%% 添加buff效果
							private_use_goods(PS, PlayerId, Type),
							{ok}
					end;
				_ ->
					%% 不在蝴蝶谷无法使用道具
					{error, 3}
			end;
		_ ->
			%% 不在蝴蝶谷无法使用道具
			{error, 3}
	end.

%% 刷新道具数量
refresh_item_num(PS) ->
	List = private_get_all_item_num(PS),
	NewList = [<<Type:8, Num:16>> || {Type, Num} <- List],
	{ok, BinData} = pt_342:write(34209, NewList),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData).

%% 是否拥有双倍积分符
has_double(RoleId) ->
	case lib_player:get_player_buff(RoleId, 2, ?BUTTERFLY_BUFF_DOUBLE_ID) of
		[] -> 
			false;
		[Buff] -> 
			case Buff#ets_buff.end_time > util:unixtime() of
				true ->
					true;
				_ ->
					false
			end;
		_ -> 
			false
	end.

%% 移除buff
remove_buff(PS) ->
    case lib_buff:match_two(PS#player_status.player_buff, 2, []) of
	%case buff_dict:match_two(PS#player_status.id, 2) of
		[] ->
			skip;
		List ->
			lists:map(fun(Record) -> 
				if
					Record#ets_buff.attribute_id =:= ?BUTTERFLY_BUFF_SPEED_UP_ID orelse
					Record#ets_buff.attribute_id =:= ?BUTTERFLY_BUFF_SPEED_DOWN_ID orelse
					Record#ets_buff.attribute_id =:= ?BUTTERFLY_BUFF_DOUBLE_ID -> 
						NewRecord = Record#ets_buff{end_time = 0},
						buff_dict:delete_id(Record#ets_buff.id),
						lib_player:send_buff_notice(PS, [NewRecord]);
					true ->
						skip
				end
			end, List)
	end.

%% 在退出蝴蝶谷场景时，将buff剩余时间保存起来，下次退入场景时还原
save_buff_time(PS) ->
	NowTime = util:unixtime(),
	{SceneId, _, _}  = data_butterfly:get_scene(),
    case lib_buff:match_three(PS#player_status.player_buff, 2, ?BUTTERFLY_BUFF_SPEED_UP_ID, []) of
	%case lib_player:get_player_buff(PS#player_status.id, 2, ?BUTTERFLY_BUFF_SPEED_UP_ID) of
		[] ->
			skip;
		[Buff] ->
			case Buff#ets_buff.end_time > NowTime + 5 of
				%% 缓存时间剩余多于5秒才需要处理
				true ->
					mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_SPEED_UP_TIME, Buff#ets_buff.end_time - NowTime),
					private_update_buff(PS, Buff, ?BUTTERFLY_SPEED_UP_GOODS, 0, [SceneId]);
				_ ->
					skip
			end;
		_ ->
			skip
	end,
    case lib_buff:match_three(PS#player_status.player_buff, 2, ?BUTTERFLY_BUFF_SPEED_DOWN_ID, []) of
	%case lib_player:get_player_buff(PS#player_status.id, 2, ?BUTTERFLY_BUFF_SPEED_DOWN_ID) of
		[] ->
			skip;
		[Buff2] ->
			case Buff2#ets_buff.end_time > NowTime + 5 of
				%% 缓存时间剩余多于5秒才需要处理
				true ->
					mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_SPEED_DOWN_TIME, Buff2#ets_buff.end_time - NowTime),
					private_update_buff(PS, Buff2, ?BUTTERFLY_SPEED_DOWN_GOODS, 0, [SceneId]);
				_ ->
					skip
			end;
		_ ->
			skip
	end,
    case lib_buff:match_three(PS#player_status.player_buff, 2, ?BUTTERFLY_BUFF_DOUBLE_ID, []) of
	%case lib_player:get_player_buff(PS#player_status.id, 2, ?BUTTERFLY_BUFF_DOUBLE_ID) of
		[] ->
			skip;
		[Buff3] ->
			case Buff3#ets_buff.end_time > NowTime + 5 of
				%% 缓存时间剩余多于5秒才需要处理
				true ->
					mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_DOUBLE_TIME, Buff3#ets_buff.end_time - NowTime),
					private_update_buff(PS, Buff3, ?BUTTERFLY_DOUBLE_SCORE_GOODS, 0, [SceneId]);
				_ ->
					skip
			end;
		_ ->
			skip
	end,
	ok.

%% 重新进入蝴蝶谷场景时，将buff还原出来
recover_buff_time(PS) ->
	{SceneId, _, _}  = data_butterfly:get_scene(),
	
	SpeedUpTime = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_SPEED_UP_TIME),
	case SpeedUpTime > 0 of
		true ->
			private_add_new_buff(PS, ?BUTTERFLY_SPEED_UP_GOODS, ?BUTTERFLY_BUFF_SPEED_UP_ID, SpeedUpTime, [SceneId]),
			mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_SPEED_UP_TIME, 0);
		_ ->
			skip
	end,
	SpeedDownTime = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_SPEED_DOWN_TIME),
	case SpeedDownTime > 0 of
		true ->
			private_add_new_buff(PS, ?BUTTERFLY_SPEED_DOWN_GOODS, ?BUTTERFLY_BUFF_SPEED_DOWN_ID, SpeedDownTime, [SceneId]),
			mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_SPEED_DOWN_TIME, 0);
		_ ->
			skip
	end,
	DoubleTime = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_DOUBLE_TIME),
	case DoubleTime > 0 of
		true ->
			private_add_new_buff(PS, ?BUTTERFLY_DOUBLE_SCORE_GOODS, ?BUTTERFLY_BUFF_DOUBLE_ID, DoubleTime, [SceneId]),
			mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_DOUBLE_TIME, 0);
		_ ->
			skip
	end,
	ok.

%% buff失效处理
invalid_buff(PS, Buff) ->
	if
		%% 加速符或减速符失效
		Buff#ets_buff.attribute_id =:= ?BUTTERFLY_BUFF_SPEED_UP_ID orelse
		Buff#ets_buff.attribute_id =:= ?BUTTERFLY_BUFF_SPEED_DOWN_ID ->				  
			case Buff#ets_buff.end_time =< util:unixtime() of
				true ->
					OldSpeed = PS#player_status.butterfly#player_butterfly.speed,
					%% 改变速度, 并更新给客户端
					NewPS = PS#player_status{speed = OldSpeed},
					{ok, BinData} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, NewPS#player_status.server_num, NewPS#player_status.speed, 0]),
					lib_server_send:send_to_sid(NewPS#player_status.sid, BinData);
				_ ->
					skip
			end;
		true ->
			skip
	end.

%% 获得所有道具数量
private_get_all_item_num(PS) ->
	[
		{1, private_get_item_num(PS, 1)},
		{2, private_get_item_num(PS, 2)},
		{3, private_get_item_num(PS, 3)}
	].

%% 取得道具数量
private_get_item_num(PS, Type) ->
	if
		Type =:= 1 ->
			mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_SPEED_UP);
		Type =:= 2 ->
			mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_SPEED_DOWN);
		Type =:= 3 ->
			mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_DOUBLE);
		true ->
			0
	end.

%% 使用道具
private_use_goods(User, RoleId, Type) ->
	PS = case User#player_status.id =:= RoleId of
		true -> 
			User;
		_ ->
			lib_player:get_player_info(RoleId)
	end,
	case is_record(PS, player_status) andalso PS#player_status.id > 0 of
		true ->
			if
				%% 加速符
				Type =:= 1 ->
					private_speed_up(PS);
				%% 减速符
%% 				Type =:= 2 ->
%% 					private_speed_down(PS);
				%% 双倍积分符
%% 				Type =:= 3 ->
%% 					private_double_score(PS);
				true ->
					skip
			end,

			%% 扣除道具
			private_use_item_num(User, Type),

			%% 刷新道具
			refresh_item_num(User);
		_ ->
			skip
	end.

%% 使用道具：加速
private_speed_up(PS) ->
	NowTime = util:unixtime(),
	{SceneId, _, _}  = data_butterfly:get_scene(),
	Butterfly = PS#player_status.butterfly,
    case lib_buff:match_three(PS#player_status.player_buff, 2, ?BUTTERFLY_BUFF_SPEED_UP_ID, []) of
	%case lib_player:get_player_buff(PS#player_status.id, 2, ?BUTTERFLY_BUFF_SPEED_UP_ID) of
		%% 第一次使用加速符
		[] ->
			%% 插入新buff
			private_add_new_buff(PS, ?BUTTERFLY_SPEED_UP_GOODS, ?BUTTERFLY_BUFF_SPEED_UP_ID, ?BUTTERFLY_BUFF_SPEED_TIME, [SceneId]),

			%% 改变速度, 并更新给客户端
			NewPS = PS#player_status{
				speed = round(Butterfly#player_butterfly.speed * ?BUTTERFLY_SPEED_UP_RATE)
			},
			{ok, BinData} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, NewPS#player_status.server_num, NewPS#player_status.speed, 0]),
			lib_server_send:send_to_sid(NewPS#player_status.sid, BinData);

		%% 非第一次使用加速符
		[BuffInfo] ->
			%% 更新buff时间到数据库
			EndTime = case BuffInfo#ets_buff.end_time + ?BUTTERFLY_BUFF_SPEED_TIME =< NowTime of
				true ->
					NowTime + ?BUTTERFLY_BUFF_SPEED_TIME;
				_ ->
					BuffInfo#ets_buff.end_time + ?BUTTERFLY_BUFF_SPEED_TIME
			end,

			%% 更新buff
			private_update_buff(PS, BuffInfo, ?BUTTERFLY_SPEED_UP_GOODS, EndTime, [SceneId]),

			%% 改变速度, 并更新给客户端
			NewPS = PS#player_status{
				speed = round(Butterfly#player_butterfly.speed * ?BUTTERFLY_SPEED_UP_RATE)
			},
			{ok, BinData} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, NewPS#player_status.server_num, NewPS#player_status.speed, 0]),
			lib_server_send:send_to_sid(NewPS#player_status.sid, BinData);
		_ ->
			skip
	end.

%% 添加新buff
%% PS : 玩家#player_status
%% GoodsId : buff使用到的物品ID，用于显示图标
%% AttributeId : buff使用到的属性类型id，用于区别不同属性
%% KeepTime : buff持续秒数
%% Scene : 限制的场景id列表
private_add_new_buff(PS, GoodsId, AttributeId, KeepTime, Scene) ->
	EndTime = util:unixtime() + KeepTime,
	NewBuff = lib_player:add_player_buff(PS#player_status.id, 2, GoodsId, AttributeId, 0, EndTime, Scene),
	buff_dict:insert_buff(NewBuff),
	lib_player:send_buff_notice(PS, [NewBuff]).

%% 更新buff
%% PS : 玩家#player_status
%% OldBuff : 旧的buff数据#ets_buff
%% GoodsId : buff使用到的物品ID，用于显示图标
%% EndTime : buff结束时间
%% Scene : 限制的场景id列表
private_update_buff(PS, OldBuff, GoodsId, EndTime, Scene) ->
	case EndTime =< 0 of
		true ->
			NewBuff = lib_player:mod_buff(OldBuff, GoodsId, 0, EndTime, Scene),
			buff_dict:insert_buff(NewBuff),
			lib_player:send_buff_notice(PS, [NewBuff]),
			buff_dict:delete_id(OldBuff#ets_buff.id);
		_ ->
			NewBuff = lib_player:mod_buff(OldBuff, GoodsId, 0, EndTime, Scene),
			buff_dict:insert_buff(NewBuff),
			lib_player:send_buff_notice(PS, [NewBuff])
	end.

%% 扣除道具
private_use_item_num(PS, Type) ->
	if
		Type =:= 1 ->
			mod_daily:plus_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_SPEED_UP, -1);
		Type =:= 2 ->
			mod_daily:plus_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_SPEED_DOWN, -1);
		Type =:= 3 ->
			mod_daily:plus_count(PS#player_status.dailypid, PS#player_status.id, ?BUTTERFLY_CACHE_DOUBLE, -1);
		true ->
			skip
	end.

%% 使用道具：减速
%% private_speed_down(PS) ->
%% 	NowTime = util:unixtime(),
%% 	{SceneId, _, _}  = data_butterfly:get_scene(),
%% 
%% 	case lib_player:get_player_buff(PS#player_status.id, 2, ?BUTTERFLY_BUFF_SPEED_DOWN_ID) of
%% 		%% 第一次使用加速符
%% 		[] ->
%% 			%% 检查是否用过减速符，有的话需要抵消时间
%% 			case lib_player:get_player_buff(PS#player_status.id, 2, ?BUTTERFLY_BUFF_SPEED_UP_ID) of
%% 				%% 没用过，不需要抵消时间
%% 				[] ->
%% 					%% 插入新buff
%% 					private_add_new_buff(PS, ?BUTTERFLY_SPEED_DOWN_GOODS, ?BUTTERFLY_BUFF_SPEED_DOWN_ID, ?BUTTERFLY_BUFF_SPEED_TIME, [SceneId]),
%% 
%% 					%% 改变速度, 并更新给客户端
%% 					NewPS = PS#player_status{
%% 						speed = round(PS#player_status.speed * ?BUTTERFLY_SPEED_DOWN_RATE)
%% 					},
%% 					{ok, BinData} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, NewPS#player_status.server_num, NewPS#player_status.speed, 0]),
%% 					lib_server_send:send_to_sid(NewPS#player_status.sid, BinData);
%% 
%% 				%% 有使用过减速符，需要作抵消时间处理
%% 				[DownBuff] ->
%% 					DownTime = DownBuff#ets_buff.end_time - ?BUTTERFLY_BUFF_SPEED_TIME,
%% 					case DownTime > NowTime of
%% 						%% 抵消减速时间
%% 						true ->
%% 							private_update_buff(PS, DownBuff, ?BUTTERFLY_SPEED_UP_GOODS, DownTime, [SceneId]);
%% 
%% 						%% 设置减速符过期
%% 						_ ->
%% 							private_update_buff(PS, DownBuff, ?BUTTERFLY_SPEED_UP_GOODS, 0, [SceneId])
%% 					end;
%% 				_ ->
%% 					skip
%% 			end;
%% 
%% 		%% 非第一次使用加速符
%% 		[BuffInfo] ->
%% 			%% 更新buff时间到数据库
%% 			EndTime = case BuffInfo#ets_buff.end_time + ?BUTTERFLY_BUFF_SPEED_TIME =< NowTime of
%% 				true ->
%% 					NowTime + ?BUTTERFLY_BUFF_SPEED_TIME;
%% 				_ ->
%% 					BuffInfo#ets_buff.end_time + ?BUTTERFLY_BUFF_SPEED_TIME
%% 			end,
%% 
%% 			%% 检查是否用过减速符，有的话需要抵消时间
%% 			case lib_player:get_player_buff(PS#player_status.id, 2, ?BUTTERFLY_BUFF_SPEED_UP_ID) of
%% 				%% 没用过减速符，不需要抵消时间
%% 				[] ->
%% 					%% 更新buff
%% 					private_update_buff(PS, BuffInfo, ?BUTTERFLY_SPEED_DOWN_GOODS, EndTime, [SceneId]);
%% 				
%% 				%% 有用过减速符，需要抵消时间
%% 				[DownBuff] ->
%% 					DownTime = DownBuff#ets_buff.end_time - ?BUTTERFLY_BUFF_SPEED_TIME,
%% 					case DownTime > NowTime of
%% 						%% 抵消减速时间
%% 						true ->
%% 							%% 更新buff
%% 							private_update_buff(PS, DownBuff, ?BUTTERFLY_SPEED_UP_GOODS, DownTime, [SceneId]);
%% 
%% 						%% 设置减速符过期
%% 						_ ->
%% 							%% 更新buff
%% 							private_update_buff(PS, DownBuff, ?BUTTERFLY_SPEED_UP_GOODS, 0, [SceneId])
%% 					end;
%% 				_ ->
%% 					skip
%% 			end;
%% 		_ ->
%% 			skip
%% 	end.

%% 使用双倍经验符
%% private_double_score(PS) ->
%% 	NowTime = util:unixtime(),
%% 	{SceneId, _, _}  = data_butterfly:get_scene(),
%% 
%% 	case lib_player:get_player_buff(PS#player_status.id, 2, ?BUTTERFLY_BUFF_DOUBLE_ID) of
%% 		[] ->
%% 			EndTime = NowTime + ?BUTTERFLY_BUFF_DOUBLE_TIME,
%% 			NewBuff = lib_player:add_player_buff(PS#player_status.id, 2, ?BUTTERFLY_DOUBLE_SCORE_GOODS, ?BUTTERFLY_BUFF_DOUBLE_ID, 0, EndTime, [SceneId]),
%% 			buff_dict:insert_buff(NewBuff),
%% 			lib_player:send_buff_notice(PS, [NewBuff]);
%% 		[BuffInfo] ->
%% 			EndTime = case BuffInfo#ets_buff.end_time + ?BUTTERFLY_BUFF_DOUBLE_TIME =< NowTime of
%% 				true ->
%% 					NowTime + ?BUTTERFLY_BUFF_DOUBLE_TIME;
%% 				_ ->
%% 					BuffInfo#ets_buff.end_time + ?BUTTERFLY_BUFF_DOUBLE_TIME
%% 			end,
%% 			NewBuff = lib_player:mod_buff(BuffInfo, ?BUTTERFLY_DOUBLE_SCORE_GOODS, 0, EndTime, [SceneId]),
%% 
%% 			buff_dict:insert_buff(NewBuff),
%% 			lib_player:send_buff_notice(PS, [NewBuff]);
%% 		_ ->
%% 			skip
%% 	end.
