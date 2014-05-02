%%%--------------------------------------
%%% @Module  : pp_butterfly
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.6
%%% @Description: 捕蝴蝶活动
%%%--------------------------------------

-module(pp_butterfly).
-include("server.hrl").
-include("common.hrl").
-export([handle/3]).

%% 查询房间列表
handle(34203, PS, _) ->
	case PS#player_status.lv >= data_butterfly:require_level() of
		true ->
			List = mod_butterfly:get_room(),
			Limit = data_butterfly:get_room_limit(),
			NewList = lists:map(fun({Id, Num}) -> 
				<<Id:8, Num:16, Limit:16>>  
			end, List),
			{ok, BinData} = pt_342:write(34203, NewList),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		_ ->
			skip
	end;

%% 进入地图
handle(34205, PS, RoomId) ->
	case lib_butterfly:get_switch() of
		true ->
			%% 判断等级是否满足
			case PS#player_status.lv >= data_butterfly:require_level() of
				true ->
					case lib_butterfly:enter(PS, RoomId) of
						{ok, NewPS, Score, LimitUp, Exp, LLPT, StatList, AwardList} ->
							{ok, BinData} = pt_342:write(34205, [1, Score, LimitUp, Exp, LLPT, RoomId, StatList, AwardList]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData),

							%% 离线活动
							case mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 8895) of
								0 -> 
                                    mod_daily:increment(PS#player_status.dailypid, PS#player_status.id, 8895),
                                    %% 召回活动
							        catch lib_off_line:add_off_line_count(PS#player_status.id, 7, 1, 0),
                                    catch lib_off_line:add_off_line_count(PS#player_status.id, 13, 1, 1);
								_ -> skip
							end,

							{ok, NewPS};
						{error, ErrorCode} ->
							{ok, BinData} = pt_342:write(34205, [ErrorCode, 0, 0, 0, 0, 0, [], []]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData)
					end;
				_ ->
					{ok, BinData} = pt_342:write(34205, [2, 0, 0, 0, 0, 0, [], []]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			end;
		_ ->
			{ok, BinData} = pt_342:write(34205, [4, 0, 0, 0, 0, 0, [], []]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	end;

%% 退出地图
handle(34206, PS, _) ->
	%% 退出到原来进入的场景和坐标
	{SceneId, X, Y} = case mod_exit:lookup_last_xy(PS#player_status.id) of
		[OldSceneId, OldX, OldY] ->
			{OldSceneId, OldX, OldY};
		undefined ->
			data_butterfly:get_outer_scene()
	end,
	lib_scene:change_scene_queue(PS, SceneId, 0, X, Y, 0),

	Butterfly = PS#player_status.butterfly#player_butterfly{
		exittime = util:unixtime()
	},

	NewPS2 = case PS#player_status.butterfly#player_butterfly.speed > 0 of
		true ->
			PS#player_status{
				speed = Butterfly#player_butterfly.speed,
				butterfly = Butterfly
			};
		_ ->
			PS#player_status{
				butterfly = Butterfly
			}
	end,

	%% 房间人数加1
	mod_butterfly:change_num(PS#player_status.copy_id, -1),

	{ok, BinData1} = pt_342:write(34206, 1),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData1),

	%% 保存buff剩余时间
	lib_butterfly_goods:save_buff_time(NewPS2),

	{ok, NewPS2};

%% 使用道具
handle(34210, PS, [Type, PlayerId]) ->
	case lib_butterfly_goods:use_goods(PS, Type, PlayerId) of
		{ok} ->
			{ok, BinData1} = pt_342:write(34210, 1),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData1);
		{error, ErrorCode} ->
			{ok, BinData1} = pt_342:write(34210, ErrorCode),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData1)
	end;

%% 领取阶段目标奖励
handle(34216, PS, Level) ->
	case lib_butterfly:get_step_award(PS, Level) of
		{ok, NewPS} ->
			{ok, BinData} = pt_342:write(34216, [Level, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData),
			{ok, NewPS};
		{error, ErrorCode} ->
			{ok, BinData} = pt_342:write(34216, [Level, ErrorCode]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	end;

%% 错误处理
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_hotspring no match", []),
	{error, "pp_hotspring no match"}.
