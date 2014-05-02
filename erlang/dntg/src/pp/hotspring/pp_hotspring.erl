%%%--------------------------------------
%%% @Module  : pp_hotspring
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.9
%%% @Description: 温泉
%%%--------------------------------------

-module(pp_hotspring).
-include("server.hrl").
-include("common.hrl").
-export([handle/3]).

%% 进入温泉场景
handle(33001, PS, RoomId) ->
	case is_integer(RoomId) of
		true ->
			case lib_hotspring:is_enterable(PS, RoomId) of
				{ok, TimeRange, SceneId, PlayerList1, PlayerList2} ->
					%% 获取进入随机坐标
					{X, Y} = data_hotspring:get_enter_xy(),

					%% 保存进入前的场景及坐标
					mod_exit:insert_last_xy(PS#player_status.id, PS#player_status.scene, PS#player_status.x, PS#player_status.y),

					%% 切换到温泉场景
					lib_scene:change_scene_queue(PS, SceneId, RoomId, X, Y, 0),

					%% 保存温泉需要用到的数据
					HS = PS#player_status.hotspring,
					NewPS2 = PS#player_status{
						hotspring = HS#status_hotspring{
							%% 活动时间配置
							timerange = TimeRange,
							lasttime = util:unixtime(),
							charm_num1 = PlayerList1,
							charm_num2 = PlayerList2
						}
					},

					%% 房间人数加1
					mod_hotspring:change_num(RoomId, 1),

					%% 插入沙滩魅力排行榜表记录
					lib_hotspring:insert_rank_charm(PS#player_status.id),

					%% 取出互动次数
					[Int1, Int2] = lib_hotspring:get_left_num(PS),

					{ok, BinData} = pt_330:write(33001, [1, Int1, Int2, RoomId]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData),

					%% 召回活动
					private_call_back_activity(PS#player_status.id),
					
					{ok, NewPS2};
				{error, ErrorCode} ->
					{ok, BinData} = pt_330:write(33001, [ErrorCode, 0, 0, 0]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			end;
		_ ->
			{ok, BinData} = pt_330:write(33001, [20, 0, 0, 0]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	end;

%% 退出温泉场景地图
handle(33002, PS, leave_scene) ->
	case PS#player_status.scene =:= 231 orelse PS#player_status.scene =:= 232 of
		true ->
			HS = PS#player_status.hotspring,

			%% 保存玩家互动的玩家数据
			lib_hotspring:update_interact_playerlist(
				PS#player_status.id,
				HS#status_hotspring.charm_num1,
				HS#status_hotspring.charm_num2
			),

			%% 退出到原来进入的场景和坐标
			{SceneId, X, Y} = case mod_exit:lookup_last_xy(PS#player_status.id) of
				[OldSceneId, OldX, OldY] ->
					{OldSceneId, OldX, OldY};
				undefined ->
					data_hotspring:get_outer_scene()
			end,
			lib_scene:change_scene_queue(PS, SceneId, 0, X, Y, 0),

			NewPS2 = PS#player_status{
				hotspring = HS#status_hotspring{exittime = util:unixtime()}
			},

			%% 房间人数减1
			mod_hotspring:change_num(PS#player_status.copy_id, -1),

			{ok, BinData1} = pt_330:write(33002, 1),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData1),

			{ok, NewPS2};
		_ ->
			{ok, PS}
	end;

%% 查询房间列表
handle(33003, PS, _) ->
	case PS#player_status.lv >= data_hotspring:get_require_lv() of
		true ->
			List = mod_hotspring:get_room(),
			Limit = data_hotspring:get_room_limit(),
			NewList = lists:map(fun({Id, Num}) -> 
				<<Id:8, Num:16, Limit:16>>  
			end, List),
			{ok, BinData} = pt_330:write(33003, NewList),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		_ ->
			skip
	end;

%% 获取收益
handle(33005, PS, get_gain) ->
	case PS#player_status.lv >= data_hotspring:get_require_lv() of
		true ->
			case lib_hotspring:count_gain(PS) of
				{ok, NewPS} ->
					{ok, BinData} = pt_330:write(33005, 1),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData),
					{ok, NewPS};
				{error, ErrorCode} ->
					{ok, BinData} = pt_330:write(33005, ErrorCode),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			end;
		_ ->
			skip
	end;

%% 互动
handle(33008, PS, [InteractType, PlayerId]) ->
	if
		(InteractType =:= 1) orelse (InteractType =:= 2) orelse (InteractType =:= 3) ->
			if
				is_integer(PlayerId) == true ->
					CacheKey = lists:concat([pp_hotspring_33008, InteractType]),
					case get(CacheKey) of
						undefined ->
							put(CacheKey, util:unixtime()),
							private_handle_33008(PS, InteractType, PlayerId);
						Time ->
							case Time + 10 > util:unixtime() of
								true ->
									skip;
								_ ->
									put(CacheKey, util:unixtime()),
									private_handle_33008(PS, InteractType, PlayerId)
							end
					end;
				true ->
					skip
			end;
		true ->
			skip
	end;

%% 玩家取消晕眩、结冰状态
handle(33025, PS, [PlayerId, Type]) ->
	case PS#player_status.id =:= PlayerId andalso lists:member(Type, [1, 2, 3]) of
		true ->
			{ok, BroadData} = pt_330:write(33025, [PlayerId, Type]),
			lib_server_send:send_to_area_scene(
				PS#player_status.scene,
				PS#player_status.copy_id,
				PS#player_status.x,
				PS#player_status.y,
				BroadData
			);
		_ ->
			skip
	end;

%% 错误处理
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_hotspring no match", []),
	{error, "pp_hotspring no match"}.


%% 互动
private_handle_33008(PS, InteractType, PlayerId) ->	
	case lib_hotspring:interact(PS, InteractType, PlayerId) of
		{ok, NewPS} ->
			{ok, BinData} = pt_330:write(33008, [1, InteractType]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData),

			%%广播给整个场景
			{ok, BroadData} = pt_330:write(33023, [
				PS#player_status.id,
				PlayerId,
				InteractType
			]),
			lib_server_send:send_to_area_scene(
				PS#player_status.scene,
				PS#player_status.copy_id,
				PS#player_status.x,
				PS#player_status.y,
				BroadData
			),

			{ok, NewPS};
		{error, ErrorCode} ->
			{ok, BinData} = pt_330:write(33008, [ErrorCode, InteractType]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	end.

%% 召回活动
private_call_back_activity(RoleId) ->
	NowTime = util:unixtime(),
	NowDay = util:unixdate(NowTime),
	Day1 = NowDay + 12 * 3600,
	Day2 = NowDay + 18 * 3600,
	case get({pp_hotspring, callback, RoleId}) of
		undefined ->
			put({pp_hotspring, callback, RoleId}, NowTime + 10),
			lib_off_line:add_off_line_count(RoleId, 6, 1, 0);
		OldTime ->
			if
				NowTime >= Day1 andalso NowTime < Day2 andalso OldTime >= Day1 andalso OldTime < Day2 -> skip;
				NowTime >= Day2 andalso OldTime >= Day2 -> skip;
				true ->
					put({pp_hotspring, callback, RoleId}, NowTime + 10),
					lib_off_line:add_off_line_count(RoleId, 6, 1, 0)
			end
	end.
