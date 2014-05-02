%% --------------------------------------------------------
%% @Module:           |pp_fortune
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-03-22
%% @Description:      |运势任务
%% --------------------------------------------------------
-module(pp_fortune).
-export([handle/3]).
-include("common.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("fortune.hrl").

%% 取自己的运势信息（公共线）
handle(37000, UniteStatus, [Type]) ->
	TypeFortune = case Type of
		1 ->
			lib_fortune:get_task_37000([UniteStatus#unite_status.id, UniteStatus#unite_status.lv]);
		_ ->
			lib_fortune:get_one_fortune(UniteStatus#unite_status.id)
	end,
	case TypeFortune of
		PlayerFortune when is_record(PlayerFortune, rc_fortune)->
			PLV = UniteStatus#unite_status.lv,
			LvLimit = if 
						  PLV >= 61 -> 100;
						  PLV >= 56 -> 60;
						  true -> 55
			end,
			{GoodTypeId, Num, GuildMoney, GuildGAAdd, ExpB, PackId} = case PlayerFortune#rc_fortune.task_color =:= 0 of
																		  true ->
																			{0, 0, 0, 0, 0, 0};
																		  false ->
																			lib_fortune:get_prize(PlayerFortune#rc_fortune.task_color, LvLimit)
																	  end,
			IsRefreshed= PlayerFortune#rc_fortune.refresh_time,
			ExpAdd = UniteStatus#unite_status.lv * UniteStatus#unite_status.lv * ExpB,
		    {ok, BinData} = pt_370:write(37000, [1									%% int:16 成功或失败
								,PlayerFortune#rc_fortune.role_color				%% int:16 运势ID
								,PlayerFortune#rc_fortune.task_color				%% int:16 任务颜色ID
								,PlayerFortune#rc_fortune.refresh_left				%% int:16 刷新颜色剩余次数
								,PlayerFortune#rc_fortune.task_id					%% int:32 任务ID
								,PlayerFortune#rc_fortune.count						%% int:32 任务统计数
								,IsRefreshed										%% int:32 下次刷新所剩秒数
								,PlayerFortune#rc_fortune.status					%% int:8 任务完成状态，0未接取，1已接取，2已完成，3已交任务
								,GuildMoney											%% int:32 奖励的帮派资金
								,GuildGAAdd											%% int:16 奖励的神兽成长值
								,ExpAdd												%% int:32 奖励的经验
								,GoodTypeId											%% int:32 奖励的物品ID
								,Num												%% int:8  物品数量
								,PackId												%% int:32 奖励的礼包ID
								]),
			lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);
		_ ->
			{ok, BinData} = pt_370:write(37000, [0,0,0,0,0,0,0,0,0,0,0,0,0,0]),
			lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData)
	end,
	ok;

%% 取帮派成员的运势信息（公共线）
handle(37001, UniteStatus, _) ->
	PList = lib_fortune:get_guild_member_fortune(UniteStatus#unite_status.guild_id),
    {ok, BinData} = pt_370:write(37001, [PList]),
    lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);

%% 刷新帮派成员的任务颜色（公共线）
handle(37002, UniteStatus, [RoleId]) ->
	SelfId = UniteStatus#unite_status.id,
	SelfName = UniteStatus#unite_status.name,
	GuildId = UniteStatus#unite_status.guild_id,
	case SelfId == RoleId of
		true ->
			{ok, BinData} = pt_370:write(37002, [4, 0, 0, 0]),
    		lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);
		false ->
			{Res, RefreshNum, BrefreshNum, RefreshSpan} = lib_fortune:task_set_new_color(SelfId, SelfName, GuildId, RoleId),
			{ok, BinData} = pt_370:write(37002, [Res, RefreshNum, BrefreshNum, RefreshSpan]),
    		lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData)
	end;
	
%% 取颜色刷新日志（公共线） 
handle(37004, UniteStatus, _) ->
    LogList = lib_fortune:get_fortune_log_format(UniteStatus#unite_status.id),
    {ok, BinData} = pt_370:write(37004, LogList),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);


%% 找他帮忙（公共线）
handle(37005, UniteStatus, RoleId) ->
	{Res, TimeLeft} =  lib_fortune:task_get_help(UniteStatus#unite_status.id, UniteStatus#unite_status.guild_id, RoleId),
	{ok, BinData} = pt_370:write(37005, [Res, TimeLeft]),
    lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);


%% 感谢信息通知（公共线）
%handle(37007, UniteStatus, _Role_id) ->
%    {ok, BinData} = pt_370:write(37007, [0, 0, 0, 0]),
%    lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);

%% 感谢某人
handle(37008, UniteStatus, [RoleId, Type]) ->
	CountSelf = mod_daily_dict:get_count(UniteStatus#unite_status.id, 3701001),
	CountTarget = mod_daily_dict:get_count(RoleId, 3701002),
	case CountSelf < 1 andalso CountTarget < 5 of
		true ->
			Res = lib_fortune:thank_orange(UniteStatus#unite_status.id, UniteStatus#unite_status.name, RoleId, Type),
		    {ok, BinData} = pt_370:write(37008, [Res]),
		    lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);
		false ->
			ok
	end;
		
	

%% 获取运势任务（公共线）
handle(37010, UniteStatus, _) ->
	{Res, NewTaskId, TimeLeft} = lib_fortune:get_new_fortune_task([UniteStatus#unite_status.id, UniteStatus#unite_status.lv]),
    {ok, BinData} = pt_370:write(37010, [Res, NewTaskId, TimeLeft]),
    lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);

%% 刷新运势任务（公共线）
%% @param Type 1 时间刷新 2 元宝刷新 3 铜币刷新
handle(37011, UniteStatus, [Type]) ->
	{Res, NewTaskId, TimeLeft} = case Type of
									 0 ->
										 lib_fortune:get_new_fortune_task([UniteStatus#unite_status.id, UniteStatus#unite_status.lv]);
									 _ ->
										 lib_fortune:get_new_fortune_task([UniteStatus#unite_status.id, UniteStatus#unite_status.lv], Type)
								 end,
    {ok, BinData} = pt_370:write(37011, [Res, NewTaskId, TimeLeft]),
%% 	io:format("37011: ~p~n", [NewTaskId]),
    lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);

%% 选择运势任务（公共线）
handle(37012, UniteStatus, Sel) ->
	{Res, NewTaskId} = lib_fortune:set_fortune_task(UniteStatus#unite_status.id, Sel),
    {ok, BinData} = pt_370:write(37012, [Res, NewTaskId, 0]),
    lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);

%% 接取运势任务（公共线）
handle(37013, UniteStatus, _) ->
    case lib_fortune:receive_task(UniteStatus#unite_status.id) of
        NewFortune when is_record(NewFortune, rc_fortune)->
			%% 发送反馈信息
            {ok, BinData} = pt_370:write(37013, [1, NewFortune#rc_fortune.task_id, NewFortune#rc_fortune.count, NewFortune#rc_fortune.refresh_task, 0, NewFortune#rc_fortune.status]),
            lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData),
			%% 检查任务完成度
			lib_fortune:check_fortune_task(NewFortune);
        _ ->
            {ok, BinData} = pt_370:write(37013, [0, 0, 0, 0, 0, 0]),
            lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData)
    end,
    ok;

%% 交运势任务（逻辑线）
handle(37016, PlayerStatus, [_TaskId]) ->
%%  	io:format("37016 TaskId : ~p ~n", [_TaskId]),
	NewFortune = mod_disperse:call_to_unite(lib_fortune, get_one_fortune, [PlayerStatus#player_status.id]),
	{Res, PlayerStatusNew} = case mod_disperse:call_to_unite(lib_fortune, check_fortune_task, [NewFortune]) of
		true when is_record(NewFortune, rc_fortune) ->		%% 成功完成任务 不完成任务
			case NewFortune#rc_fortune.task_color >= 1 andalso NewFortune#rc_fortune.task_color =< 5 of
				true -> 
					lib_fortune:task_finish(PlayerStatus, NewFortune);
				false ->
					{0, PlayerStatus}
			end;
		_ ->		%% 失败 不完成任务
			{0, PlayerStatus}
	end,
	{ok, BinData} = pt_370:write(37016, [Res, 430010, 3]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	{ok, PlayerStatusNew};

%% 接运势任务（逻辑线）
handle(37020, PlayerStatus, [TaskId]) ->
	 case lib_task:trigger(PlayerStatus#player_status.tid, TaskId, PlayerStatus) of
        {true, NewRS} ->
            lib_task:preact_finish(NewRS#player_status.tid, TaskId, NewRS),
            lib_scene:refresh_npc_ico(NewRS),
            {ok, BinData1} = pt_370:write(37020, [1]),
            lib_server_send:send_to_sid(NewRS#player_status.sid, BinData1),
            pp_task:handle(30000, NewRS, ok),
            {ok, NewRS};
        {false, _Reason} ->
            {ok, BinData} = pt_370:write(37020, [2]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
    end;

%% 接运势任务（逻辑线）
handle(37021, UniteStatus, _) ->
	case lib_fortune:get_one_fortune(UniteStatus#unite_status.id) of
		PlayerFortune when is_record(PlayerFortune, rc_fortune)->
			lib_fortune:check_fortune_task(PlayerFortune);
		_ ->
			ok
	end,
	ok;

%% 取自己的运势信息:附带刷新（公共线）
handle(37030, UniteStatus, _) ->
	case lib_fortune:get_task_37000(UniteStatus#unite_status.id) of
		PlayerFortune when is_record(PlayerFortune, rc_fortune)->
			PLV = UniteStatus#unite_status.lv,
			LvLimit = if 
						  PLV >= 61 -> 100;
						  PLV >= 56 -> 60;
						  true -> 55
			end,
			{GoodTypeId, Num, GuildMoney, GuildGAAdd, ExpB, PackId} = case PlayerFortune#rc_fortune.task_color =:= 0 of
																		  true ->
																			{0, 0, 0, 0, 0, 0};
																		  false ->
																			lib_fortune:get_prize(PlayerFortune#rc_fortune.task_color, LvLimit)
																	  end,
			IsRefreshed= PlayerFortune#rc_fortune.refresh_time,
			ExpAdd = UniteStatus#unite_status.lv * UniteStatus#unite_status.lv * ExpB,
		    {ok, BinData} = pt_370:write(37030, [1									%% int:16 成功或失败
								,PlayerFortune#rc_fortune.role_color				%% int:16 运势ID
								,PlayerFortune#rc_fortune.task_color				%% int:16 任务颜色ID
								,PlayerFortune#rc_fortune.refresh_left				%% int:16 刷新颜色剩余次数
								,PlayerFortune#rc_fortune.task_id					%% int:32 任务ID
								,PlayerFortune#rc_fortune.count						%% int:32 任务统计数
								,IsRefreshed											%% int:32 下次刷新所剩秒数
								,PlayerFortune#rc_fortune.status					%% int:8 任务完成状态，0未接取，1已接取，2已完成，3已交任务
								,GuildMoney											%% int:32 奖励的帮派资金
								,GuildGAAdd											%% int:16 奖励的神兽成长值
								,ExpAdd												%% int:32 奖励的经验
								,GoodTypeId											%% int:32 奖励的物品ID
								,Num												%% int:8  物品数量
								,PackId												%% int:32 奖励的礼包ID
								]),
			lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData),
			lib_fortune:check_fortune_task(PlayerFortune);
		_ ->
			{ok, BinData} = pt_370:write(37030, [0,0,0,0,0,0,0,0,0,0,0,0,0,0]),
			lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData)
	end,
	ok;

%% 接运势任务（逻辑线）
handle(37025, UniteStatus, _) ->
	case lib_fortune:get_one_fortune(UniteStatus#unite_status.id) of
		PlayerFortune when is_record(PlayerFortune, rc_fortune)->
			{ok, BinData} = pt_370:write(37025, [PlayerFortune#rc_fortune.role_color]),
    		lib_unite_send:send_to_one(UniteStatus#unite_status.id, BinData);
		_ ->
			ok
	end,
	ok;

handle(_Cmd, _Status, _Data) ->
%% 	io:format("37000: ~p ~p ~p~n", [_Cmd, _Status, _Data]),
    ?INFO("pp_fortune no match", []),
    {error, "pp_fortune no match"}.
