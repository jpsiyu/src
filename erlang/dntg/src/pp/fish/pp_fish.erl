%%%--------------------------------------
%%% @Module  : pp_fish
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.9.17
%%% @Description: 全民垂钓
%%%--------------------------------------

-module(pp_fish).
-include("server.hrl").
-include("common.hrl").
-export([handle/3]).

%% 进入场景
handle(33101, PS, RoomId) ->
	case lib_fish:get_switch() == true andalso lists:member(RoomId, [1,2,3,4,5,6,7,8,9,10]) of
		true ->
			%% 判断是否进入场景过于频繁
			case PS#player_status.fish#status_fish.exittime + 10 < util:unixtime() of
				true ->
					case lib_fish:enter(PS, RoomId) of
						{ok, NewPS} ->
							{ok, BinData} = pt_331:write(33101, [
								1, RoomId,
								NewPS#player_status.fish#status_fish.score,
								data_fish:get_score_limitup(),
								NewPS#player_status.fish#status_fish.exp,
								NewPS#player_status.fish#status_fish.llpt,
								NewPS#player_status.fish#status_fish.steal_num,
								private_format_fish_stat(NewPS#player_status.fish#status_fish.fish_stat),
								private_get_step_award(NewPS#player_status.fish#status_fish.step_award)
							]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData),

							%% 离线活动
							case mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 8894) of
								0 -> 
                                    mod_daily:increment(PS#player_status.dailypid, PS#player_status.id, 8894),
                                    %% 召回活动
                                    catch lib_off_line:add_off_line_count(PS#player_status.id, 7, 1, 0),
                                    catch lib_off_line:add_off_line_count(PS#player_status.id, 13, 1, 1);
								_ -> skip
							end,

							{ok, NewPS};
						{error, ErrorCode} ->
							{ok, BinData} = pt_331:write(33101, [ErrorCode, 0, 0, 0, 0, 0, 0, [], 0]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData)
					end;
				_ ->
					{ok, BinData} = pt_331:write(33101, [7, 0, 0, 0, 0, 0, 0, [], 0]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			end;
		_ ->
			skip
	end;

%% 退出场景
handle(33102, PS, _) ->
	case lib_fish:get_switch() of
		true ->
			%% 退出到原来进入的场景和坐标
			{SceneId, X, Y} = case mod_exit:lookup_last_xy(PS#player_status.id) of
				[OldSceneId, OldX, OldY] ->
					{OldSceneId, OldX, OldY};
				undefined ->
					TmpSceneId = data_fish:get_sceneid(),
					{TmpX, TmpY} = data_fish:get_outer_scene(),
					{TmpSceneId, TmpX, TmpY}
			end,
			lib_scene:change_scene_queue(PS, SceneId, 0, X, Y, 0),

			{ok, BinData} = pt_331:write(33102, 1),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData),

			Fish = PS#player_status.fish#status_fish{
				exittime = util:unixtime(),
				fishing_time = 0,
				fishing_monid = 0,
				steal_playerid = 0,
				steal_time = 0
			},
			{ok, PS#player_status{fish = Fish}};
		_ ->
			skip
	end;

%% 查询房间列表
handle(33103, PS, _) ->
	case lib_fish:get_switch() of
		true ->
			case PS#player_status.lv >= data_fish:require_lv() of
				true ->
					SceneId = data_fish:get_sceneid(),
		            List = mod_daily_dict:get_room(fish, SceneId),
		            AllNum = lists:foldl(fun({_, N}, C)-> N+C end, 0, List),
					Limit = data_fish:get_room_limit(),
		            NowRoom = AllNum div Limit + 1,
		            MaxRoom = data_fish:get_room_num_limit(),
		            Room = case NowRoom > MaxRoom of
		                true -> MaxRoom;
		                false -> NowRoom
		            end,
		            RoomList = lists:sublist(List, Room),
		            NewList = pack2(RoomList),

					{ok, BinData} = pt_331:write(33103, NewList),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData);
				_ ->
					skip
			end;
		_ ->
			skip
	end;

%% 抛杆
%% MonId : 场景中的怪物id（非怪物类型）
handle(33106, PS, MonId) ->
	case lib_fish:get_switch() of
		true ->
			case lib_fish:start_fishing(PS, MonId) of
				{ok, NewPS} ->
					{ok, BinData} = pt_331:write(33106, [PS#player_status.id, MonId, 1]),
                    lib_server_send:send_to_scene(PS#player_status.scene, PS#player_status.copy_id, BinData),
					{ok, NewPS};
				{error, ErrorCode} ->
					{ok, BinData} = pt_331:write(33106, [PS#player_status.id, MonId, ErrorCode]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			end;
		_ ->
			skip
	end;

%% 收杆
handle(33107, PS, _) ->
	case lib_fish:get_switch() of
		true ->
            case PS#player_status.scene =:= data_fish:get_sceneid() of
				true ->
                    case lib_fish:end_fishing(PS) of
                        {ok, NewPS, FishId} ->
                            {ok, BinData} = pt_331:write(33107, [PS#player_status.id, 1, FishId]),
                            lib_server_send:send_to_scene(PS#player_status.scene, PS#player_status.copy_id, BinData), 
                            {ok, NewPS};
                        {error, ErrorCode} ->
                            {ok, BinData} = pt_331:write(33107, [PS#player_status.id, ErrorCode, 0]),
                            lib_server_send:send_to_sid(PS#player_status.sid, BinData)
                    end;
                _ ->
                    skip
            end;
		_ ->
			skip
	end;

%% 取消钓鱼
handle(33108, PS, _) ->
	case lib_fish:get_switch() of
		true ->
			case PS#player_status.scene =:= data_fish:get_sceneid() of
				true ->
					{ok, BinData} = pt_331:write(33108, [PS#player_status.id, 1]),
					lib_server_send:send_to_scene(PS#player_status.scene, PS#player_status.copy_id, BinData),
					Fish = PS#player_status.fish#status_fish{
						fishing_time = 0,
						fishing_monid = 0
					},
					{ok, PS#player_status{fish = Fish}};
				_ ->
					skip
			end;
		_ ->
			skip
	end;

%% 偷鱼
handle(33109, PS, PlayerId) ->
	case lib_fish:get_switch() of
		true ->
			case lib_fish:steal_fish(PS, PlayerId) of
				{ok, NewPS} ->
                    {ok, BinData} = pt_331:write(33109, [PS#player_status.id, PlayerId, 1]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData),

					%% 提示对方有人来偷鱼了
					lib_fish:send_msg(PlayerId, 3, 0),

					{ok, NewPS};
				{error, ErrorCode} ->
					{ok, BinData} = pt_331:write(33109, [PS#player_status.id, PlayerId, ErrorCode]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			end;
		_ ->
			skip
	end;

%% 取消偷鱼读条
handle(33110, PS, _) ->
	case lib_fish:get_switch() of
		true ->
			case PS#player_status.scene =:= data_fish:get_sceneid() of
				true ->
					case PS#player_status.fish#status_fish.steal_playerid > 0 of
						true ->
							{ok, BinData} = pt_331:write(33110, 1),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData),
							Fish = PS#player_status.fish#status_fish{
								steal_playerid = 0,
								steal_time = 0
							},
							{ok,
								PS#player_status{fish = Fish}
							};
						_ ->
							{ok, BinData} = pt_331:write(33110, 2),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData)
					end;
				_ ->
					skip
			end;
		_ ->
			skip
	end;

%% 完成偷鱼读条
handle(33111, PS, _) ->
	case lib_fish:get_switch() of
		true ->
			case PS#player_status.scene =:= data_fish:get_sceneid()  of
				true ->
					case lib_fish:finish_steal(PS) of
						{ok, NewPS, FishId} ->
							{ok, BinData} = pt_331:write(33111, [1, FishId]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData),
							{ok, NewPS};
						{error, NewPS, FishId} -> 
							{ok, BinData} = pt_331:write(33111, [2, FishId]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData),
							{ok, NewPS};
						{error, _ErrorCode} ->
							{ok, BinData} = pt_331:write(33111, [2, 0]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData)
					end;
				_ ->
					skip
			end;
		_ ->
			skip
	end;

%% 查看被偷对象的鱼
handle(33115, PS, PlayerId) ->
	case lib_fish:get_switch() of
		true ->
            case PS#player_status.scene =:= data_fish:get_sceneid()  of
				true ->
                    List = 
                    case lib_player:get_player_info(PlayerId, fish_data) of
                        [_, PlayerFish, SceneId, CopyId] ->
                            case PS#player_status.scene =:= SceneId andalso PS#player_status.copy_id =:= CopyId of
                                true ->
                                    lists:map(fun({Id, Num}) -> 
                                        <<Id:32, Num:16>>
                                    end, PlayerFish#status_fish.fish_stat);
                                _ ->
                                    []
                            end;
                        _ ->
                            []
                    end,
                    {ok, BinData} = pt_331:write(33115, [PlayerId, List]),
                    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
                _ ->
                    skip
            end;
		_ ->
			skip
	end;

%% 领取阶段目标奖励
handle(33117, PS, _) ->
	case lib_fish:get_switch() of
		true ->
			case PS#player_status.scene =:= data_fish:get_sceneid() of
				true ->
					case lib_fish:get_step_award(PS) of
						{ok, NewPS} ->
							{ok, BinData} = pt_331:write(33117, 1),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData),
							{ok, NewPS};
						{error, ErrorCode} ->
							{ok, BinData} = pt_331:write(33117, ErrorCode),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData)
					end;
				_ ->
					skip
			end;
		_ ->
			skip
	end;

%% 请求翻牌结果
handle(33126, PS, _) ->
	case lib_fish:get_switch() of
		true ->
			case PS#player_status.scene =:= data_fish:get_sceneid() of
				true ->
					case lib_fish:get_score_award(PS) of
						{ok, NewPS, GoodsTypeId, GoodsNum, Bind} ->
							{ok, BinData} = pt_331:write(33126, [1, GoodsTypeId, GoodsNum, Bind]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData),
							{ok, NewPS};
						{error, ErrorCode} ->
							{ok, BinData} = pt_331:write(33126, [ErrorCode, 0, 0, 0]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData)
					end;
				_ ->
					skip
			end;
		_ ->
			skip
	end;

%% 错误处理
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_hotspring no match", []),
	{error, "pp_hotspring no match"}.

%% 格式化鱼列表数据
private_format_fish_stat(List) ->
	lists:map(fun({FishId, FishNum}) -> 
		<<FishId:32, FishNum:16>>
	end, List).

%% 取出已经领取的奖励的最后一个
private_get_step_award(StetAward) ->
	case StetAward of
		[] -> 0;
		_ -> 
			Id = lists:min(StetAward),
			Id2 = if
				Id == 4 -> 1;
				Id == 3 -> 2;
				Id == 2 -> 3;
				Id == 1 -> 4;
				true -> 1
			end,
			Id2
	end.

pack2(RoomList) ->
	MaxNum = data_fish:get_room_limit(),
	Fun1 = fun(Elem1) ->
		{RoomId, NowNum} = Elem1,
		case NowNum > MaxNum of
		    true -> <<RoomId:8, MaxNum:16, MaxNum:16>>;
		    false -> <<RoomId:8, NowNum:16, MaxNum:16>>
		end
	end,
	[Fun1(X) || X <- RoomList].
