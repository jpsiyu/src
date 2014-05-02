%% --------------------------------------------------------
%% @Module:           |lib_fortune
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-03-22
%% @Description:      |运势任务 
%% --------------------------------------------------------
-module(lib_fortune).
-include("common.hrl").
-include("goods.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("guild.hrl").
-include("daily.hrl").
-include("fortune.hrl").
-include("task.hrl").
-export([
		role_login/1									%% 玩家登陆检测运势信息
		, role_logout/1									%% 玩家登出保存运势信息
		, get_task_37000/1								%% 获取玩家运势任务并检查(37000使用)
		, get_guild_member_fortune/1					%% 获取帮派成员的运势
		, get_new_fortune_task/1						%% 获取任务的时候调用
		, get_new_fortune_task/2						%% 刷新任务的时候调用
		, set_fortune_task/2							%% 设置运势任务
		, update_one_fortune/2							%% 更新运势信息
		, get_one_fortune/1								%% 获取一条运势记录(根据ID)
		, receive_task/1								%% 接受运势任务
		, check_fortune_task/1							%% 检查运势任务
		, task_get_new_one/1							%% 获取一个新的运势任务
		, task_get_new_one/2							%% 获取一个新的运势任务
		, color_get_role/0								%% 获取成员运势颜色
		, color_get_task/1								%% 获取任务运势颜色
		, thank_orange/4								%% 被刷新为橙色发送感谢信息
		, task_get_help/3								%% 找他人帮忙刷新
		, task_set_new_color/4							%% 刷新颜色
%% 		, task_send_guild_prize/7						%% 发送运势任务奖励
		, taks_times_refresh/1							%% 供给日常模块调用(刷新运势任务数据)
		, taks_times_refresh_do/1						%% 供给日常模块调用(刷新运势任务数据)(由上一个函数调用)
		, task_finish/2									%% 完成运势任务
		, task_finish_task_mod/3
		, get_fortune_log_format/1						%% 获取颜色刷新日志:并打包
		, save_fortune_log/2							%% 保存颜色刷新日志
		, get_fortune_log/1								%% 获取颜色刷新日志
		, clear_all_fortune_log/0						%% 每日清除 颜色刷新日志
		, get_daily/1									%% 获取日常信息
		, get_prize/2									%% 获取任务奖励信息
		, get_tasks/0									%% 获取任务ID列表(所有试炼任务)
		, get_daily_all/0
		, fortune_daily/3
		, get_color/1									%% 获取任务颜色(所有颜色)
]).
-compile(export_all).

%% 玩家本日登陆初始化运势
role_login(PlayerId) ->
	case get_one_fortune(PlayerId) of
		MyRcf when is_record(MyRcf, rc_fortune) ->
			{ok, BinData} = pt_370:write(37025, [MyRcf#rc_fortune.role_color]),
    		lib_unite_send:send_to_one(PlayerId, BinData);
		_ ->
			NewColorRole = color_get_role(),
			MyRcfC = #rc_fortune{
						role_id = PlayerId
					   , role_color = NewColorRole
						},
			update_one_fortune(PlayerId, MyRcfC),
			{ok, BinData} = pt_370:write(37025, [NewColorRole]),
    		lib_unite_send:send_to_one(PlayerId, BinData)
	end.

%% 玩家登出保存运势
role_logout(PlayerId) ->
	%% 临时使用 每次登陆初始化信息,
	case get_one_fortune(PlayerId) of
		[] ->
			skip;
		MyRcf ->
			update_one_fortune(PlayerId, MyRcf)
	end.

%% 获取成员运势列表
get_guild_member_fortune(GuildId) ->
	case GuildId =:= 0 of
		true->
			[];
		false->
%% 			Ids = ets:match(?ETS_UNITE, #ets_unite{id='$1', guild_id=GuildId, _='_'}),
			Ids = mod_chat_agent:match(guild_members_id_by_id, [GuildId]),
			case gen_server:call(mod_guild, {get_fortune_list, [Ids]}, 7000) of
				[] ->
					[];
				RL ->
					[util:record_to_list(R)||R<-RL, R =/= error]
			end
	end.

%% 选择任务
set_fortune_task(PlayerId, Sel) ->
	case Sel of
		0 ->
			{0,0};
		1 ->
			case get_one_fortune(PlayerId) of
				[] ->
					{0,0};
				RL ->
					RLNext = RL#rc_fortune{task_id = RL#rc_fortune.refresh_task, refresh_task = 0},
					update_one_fortune(PlayerId, RLNext),
					{1, RL#rc_fortune.task_id}
			end;
		_ ->
			{0,0}
	end.

%% 获取一个新的任务 刷新到选择的任务中 以及颜色 不用元宝 不用铜币 不记录时间(玩家无任务的时候调用)
get_task_37000([PlayerId, Lv]) ->
	RL = case get_one_fortune(PlayerId) of
		[] ->
			NewColorRole = color_get_role(),
			#rc_fortune{role_id = PlayerId, role_color = NewColorRole};
		RLX ->
			RLX
	end,
	case RL#rc_fortune.task_id == 0 of
		false ->
			update_one_fortune(PlayerId, RL),
			RL;
		true ->
			NewTaskId = task_get_new_one(Lv),
			NewColor = color_get_task(RL#rc_fortune.role_color),
			RLNext = RL#rc_fortune{task_id = NewTaskId, task_color = NewColor},
			update_one_fortune(PlayerId, RLNext),
			RLNext
	end.

%% 获取一个新的任务 刷新到选择的任务中 以及颜色 不用元宝 不用铜币 记录首次时间
get_new_fortune_task([PlayerId, Lv]) ->
	case get_one_fortune(PlayerId) of
		[] ->
			{0, 0, ?FORTUNE_REFRESH_TASK};
		RL ->
			case RL#rc_fortune.refresh_time == 0 of
				false ->
					{0, 0, ?FORTUNE_REFRESH_TASK};
				true ->
					NewTaskId = task_get_new_one(RL#rc_fortune.task_id, Lv),
					RLNext = RL#rc_fortune{refresh_task = NewTaskId, refresh_time = 1},
					update_one_fortune(PlayerId, RLNext),
					{1, NewTaskId, ?FORTUNE_REFRESH_TASK}
			end
	end.

%% 根据类型刷新 刷新到刷新的任务中 1 时间刷新 2 元宝刷新 3 铜币刷新
get_new_fortune_task([PlayerId, Lv], Type) ->
	case get_one_fortune(PlayerId) of
		[] ->
			{0, 0, ?FORTUNE_REFRESH_TASK};
		RL ->
			NowTime = util:unixtime(),
			IsPassed = case Type of
				1 ->
					case NowTime - RL#rc_fortune.refresh_time >= ?FORTUNE_REFRESH_TASK of
						false ->
							0;
						true ->
							0
					end;
				2 ->
					case lib_player_unite:spend_assets_status_unite(PlayerId, 10, gold, fortune_refresh_gold, "") of
						{ok, ok} ->
							0;
						_ ->
							0
					end;
				3 ->
					case lib_player_unite:spend_assets_status_unite(PlayerId, 10000, coin, fortune_refresh_coin, "") of
						{ok, ok} ->
							1;
						_ ->
							0
					end
			end,
			case IsPassed of
				0 ->
					{0, 0, ?FORTUNE_REFRESH_TASK};
				1 ->
					NewTaskId = task_get_new_one(RL#rc_fortune.task_id, Lv),
					RLNext = RL#rc_fortune{refresh_task = NewTaskId, refresh_time = 2},
					update_one_fortune(PlayerId, RLNext),
					{1, NewTaskId, ?FORTUNE_REFRESH_TASK}
			end
	end.

%% 接任务
receive_task(PlayerId) ->
	case get_one_fortune(PlayerId) of
		[] ->
			0;
		RL ->
			RLNext = RL#rc_fortune{status = 1},
			update_one_fortune(PlayerId, RLNext),
			RLNext
	end.

%% 添加进日常里面 检查运势任务完成度
taks_times_refresh(RoleDaily) ->
	lib_fortune:taks_times_refresh_do(RoleDaily).

%% 检查
taks_times_refresh_do(RoleDaily)->
	%% 获取试炼任务ID列表
	DaliyFortunAll = get_daily_all(),
	{RoleId, Type} = RoleDaily#ets_daily.id,
	%% 检查是否在列表内
	case lists:keyfind(Type, 1, DaliyFortunAll) of
		{_, _Num} ->
%% 			io:format("D ~p  ~p  ~n", [RoleId, Type]),
			Count = RoleDaily#ets_daily.count,
			gen_server:cast(mod_guild, {fortune_daily_check, [RoleId, Type, Count]});
		_ ->
			skip
	end.

%% 检查运势任务完成度 (改进添加复查功能)
check_fortune_task(Fortune) ->
    RoleId = Fortune#rc_fortune.role_id,
    TaskId = Fortune#rc_fortune.task_id,
	Status = Fortune#rc_fortune.status,
	case Status =:= 1 of
		true ->
			TaskList = data_fortune:get_task_info(),
			TaskLength = length(TaskList),
			{D_DailyId, Num, RD1} = case TaskId > TaskLength of
				true ->
					{0, 1, 1};
				false ->
					{DailyIdX, NumX} = get_daily(TaskId),
					RD1X = mod_daily_dict:get_count(RoleId, DailyIdX),
					{DailyIdX, NumX, RD1X}
			end,
			case RD1 >= Num of
				true -> %% 发送更新37000
				 	NewFortune = Fortune#rc_fortune{count = Num, status = 2},
					update_one_fortune(RoleId, NewFortune),
					{ok, BinData} = pt_370:write(37021, [Num, Num]),
		    		lib_unite_send:send_to_one(RoleId, BinData),
					true;
				false ->
					RDCheck = recheck_fortune(RoleId, D_DailyId, RD1),
					case RDCheck >= Num of
						true -> %% 发送更新37000
						 	NewFortune = Fortune#rc_fortune{count = Num, status = 2},
							update_one_fortune(RoleId, NewFortune),
							{ok, BinData} = pt_370:write(37021, [Num, Num]),
				    		lib_unite_send:send_to_one(RoleId, BinData),
							true;
						false ->
							%% 发送更新37000
							case Status =:= 2 of
								true ->
									{ok, BinData} = pt_370:write(37021, [Num, Num]),
				    				lib_unite_send:send_to_one(RoleId, BinData);
								false ->
									NewFortune = Fortune#rc_fortune{count = Num},
									update_one_fortune(RoleId, NewFortune),
									{ok, BinData} = pt_370:write(37021, [RD1, Num]),
						    		lib_unite_send:send_to_one(RoleId, BinData),
									false
							end
					end
			end;
		false->
			case Status =:= 2 of
				true ->
					true;
				false ->
					false
			end
	end.

%% 针对指定特殊数据进行复查
recheck_fortune(PlayerId, DailyId, NumNow) ->
	case DailyId of
		3700009 ->%% 仙侣奇缘任务
			server_daily_check(PlayerId, 3800);
		3700011 ->%% 阵营任务
			server_daily_check(PlayerId, 6000004);
		_ ->
			NumNow
	end.

server_daily_check(PlayerId, DailyId) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
            gen_server:call(Pid, {check_daily, DailyId});
        _ ->
            0
    end.
	
%-------------------------------------------------------------------------------
%								任务相关功能
%-------------------------------------------------------------------------------
	
	
%% 随机一个新的任务
task_get_new_one(Lv) ->
	TaskList1 = get_tasks(),
	TaskList = sai_task(TaskList1, Lv),
	NLength = erlang:length(TaskList),
	K = util:rand(1, NLength),
	lists:nth(K, TaskList).

%% 随机一个新的任务
task_get_new_one(Old,Lv) ->
	TaskList1 = get_tasks(),
	TaskList = sai_task(TaskList1, Lv),
	TaskLeft = lists:delete(Old, TaskList),
	NLength = erlang:length(TaskLeft),
	K = util:rand(1, NLength),
	lists:nth(K, TaskLeft).

sai_task(TaskList1, _Lv)-> TaskList1.
	%case Lv < 45 of
	%	true ->
	%		[Id || Id <- TaskList1, lists:member(Id, [1, 2, 3, 5, 7, 11])];
	%	false ->
	%		TaskList1
	%end.

%% 完成运势任务
task_finish(PlayerStatus, NewFortune) ->
	case NewFortune#rc_fortune.status =:= 2 of
		true ->
			lib_task:event(PlayerStatus#player_status.tid, yxrw, do, PlayerStatus#player_status.id),
			case pp_task:handle(30004, PlayerStatus, [430010, {from_fortune, NewFortune}]) of
				{ok, PlayerStatus1} ->
					PlayerStatus3 = other_module_inteface(PlayerStatus1),
					{1, PlayerStatus3};
				_ ->
					{0, PlayerStatus}
			end;
		false->
			{0, PlayerStatus}
	end.

%% 完成运势任务
task_finish_task_mod(TaskId, ParamList, PlayerStatus) ->
	case ParamList of
		{from_fortune, NewFortune} when is_record(NewFortune, rc_fortune) ->
			PLV = PlayerStatus#player_status.lv,
			LvLimit = if 
						  PLV >= 61 -> 100;
						  PLV >= 56 -> 60;
						  true -> 55
			end,
			SelfId = PlayerStatus#player_status.id,
			_SelfName = PlayerStatus#player_status.nickname,
		 	NewFortune2 = NewFortune#rc_fortune{status = 3},
		 	mod_disperse:call_to_unite(lib_fortune, update_one_fortune, [SelfId, NewFortune2]),
%% 			io:format("YOYO ~p ~p ~n", [NewFortune#rc_fortune.task_color, LvLimit]),
		    {GoodTypeId, Num, _GuildMoney, _GuildGAAdd, ExpB, _PackId} = get_prize(NewFortune#rc_fortune.task_color, LvLimit),
		    ExpAdd = PlayerStatus#player_status.lv * PlayerStatus#player_status.lv * ExpB, 
		    Goods = PlayerStatus#player_status.goods,
			TermKey = case NewFortune#rc_fortune.task_color >= 4 of
						  true ->
							  %% 紫色
							  RD = util:rand(1, 100),
							  KeyLine = case PLV > 50 of
											true ->
												50;
											false ->
												30
										end,
							  case RD > KeyLine of
								  true ->
%% 									  'give_more';
									  'give_more_bind';
								  false ->
									  'give_more'
							  end;
						  false ->
							  'give_more_bind'
					  end,
			case gen_server:call(Goods#status_goods.goods_pid, {TermKey, [], [{GoodTypeId, Num}]}) of
				ok ->
					 %% 完成一次运势任务
					 mod_daily:set_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 3700001, 1),
					 PlayerStatus2 = lib_player:add_exp(PlayerStatus, ExpAdd),
					 mod_task:normal_finish(TaskId, ParamList, PlayerStatus2);
				_ ->
					{false, data_task_text:get_text(3)}
			end;
		_ ->
			{false, data_task_text:get_text(999)}
	end.

%% 完成奖励(帮派奖励)
%% task_send_guild_prize(SelfId, SelfName, TaskId, TaskColor, GuildId, GuildMoney, _GuildGAAdd) ->
%% %% 	%% 增加帮派财富
%% %% 	case  mod_disperse:call_to_unite(lib_guild, get_guild, [GuildId]) of
%% %% 		[] ->
%% %% 			skip;
%% %% 		Guild ->
%% %% 			GuildNew = Guild#ets_guild{funds = Guild#ets_guild.funds + GuildMoney},
%% %%             mod_disperse:call_to_unite(lib_guild_base, update_guild, [GuildNew])
%% %% 	end,
%% 	%% 增加神兽成长
%% 	lib_guild_scene:guild_godanimal_exp_add([SelfId, SelfName, TaskId, TaskColor, GuildId, GuildMoney]).

%% 其他模块外部接口
other_module_inteface(PS) ->
	mod_achieve:trigger_task(PS#player_status.achieve, PS#player_status.id, 13, 0, 1),
    lib_qixi:update_player_task(PS#player_status.id, 5),
	PS.

%-------------------------------------------------------------------------------
%								运气相关功能
%-------------------------------------------------------------------------------

%% 找他人帮刷新任务颜色
task_get_help(SelfId, GuildId, RoleId) ->
	case SelfId =:= RoleId of
		true-> %% 自己
			{4, 0};
		false ->
			case mod_chat_agent:lookup(RoleId) of
				[] -> %% 玩家不在线
					{3, 0};
				[RoleEu] ->
					case RoleEu#ets_unite.guild_id =:= GuildId of
						false -> %% 不同帮派
							{5, 0};
						true -> %% 
							case get_one_fortune(SelfId) of
								[] -> %% 自己没有运势信息
									{6, 0};
								RLSelf -> 
									NowTime = util:unixtime(),
									case NowTime - RLSelf#rc_fortune.call_help_time > ?FORTUNE_HELP of
										false -> %% 冷却时间未到
											{2, 0};
										true ->
											case get_one_fortune(RoleId) of
												[] -> %% 玩家没有运势信息
													{7, 0};
												_RL ->%% 成功 发送通知并更新时间
										            {ok, BinData} = pt_370:write(37006, SelfId),
										            lib_unite_send:send_to_one(RoleId, BinData),
													RLSelfNext = RLSelf#rc_fortune{call_help_time = NowTime},
													update_one_fortune(SelfId, RLSelfNext),
													{1, 3}
											end
									end
							end
					end
			end
	end.

%% 帮他人刷新任务颜色
task_set_new_color(SelfId, SelfName, GuildId, RoleId) ->
	case mod_chat_agent:lookup(RoleId) of
		[] -> %% 玩家不在线
			{2, 0, 0, 0};
		[RoleEu] ->
			case RoleEu#ets_unite.guild_id =:= GuildId of
				false -> %% 不同帮派
					{5, 0, 0, 0};
				true -> 
					case get_one_fortune(SelfId) of
						[] -> %% 自己没有运势信息
							{6, 0, 0, 0};
						RLSelf -> 
							case RLSelf#rc_fortune.refresh_left > 0 of
								false ->
									{9, 0, 0, 0};
								true ->
									NowTime  = util:unixtime(),
									case NowTime - RLSelf#rc_fortune.refresh_color_time > ?FORTUNE_REFRESH_COLOR of
										false ->
											{3, 0, 0, 0};
										true ->
											case get_one_fortune(RoleId) of
												[] ->
													%% 玩家没有运势信息
													{7, 0, 0, 0};
												RL ->
													case RL#rc_fortune.status > 2 of
														true ->
															%% 玩家未接任务或人物已交
															{8, 0, 0, 0};
														false ->
															case RL#rc_fortune.task_color >= 5 of
																true ->
																	{11, 0, 0, 0};
																false ->
																	NewColor = color_get_task(RLSelf#rc_fortune.role_color),			%% 获取新的颜色
																	RLNext = RL#rc_fortune{task_color = NewColor, brefresh_num = RL#rc_fortune.brefresh_num + 1},
																	update_one_fortune(RoleId, RLNext),
																	RLSelfNext = RLSelf#rc_fortune{refresh_left = RLSelf#rc_fortune.refresh_left - 1
																								   ,refresh_color_time = NowTime},
																	update_one_fortune(SelfId, RLSelfNext),
																	{ok, BinData} = pt_370:write(37003, [SelfId
																										, RLSelf#rc_fortune.refresh_left
																										, RoleId
																										, NewColor
																										, RL#rc_fortune.brefresh_num
																										, RL#rc_fortune.task_id
																										, SelfName
																										, RoleEu#ets_unite.name]),
																	%% 写入日志 缓存ONLY 不存数据库
																	save_fortune_log(RoleId, #rc_fortune_log{role_id = RoleId
																									,refresh_role = SelfId
																									,refresh_fortune = RLSelf#rc_fortune.role_color
																									,task_id = RL#rc_fortune.task_id
																									,color = NewColor
																									}),
																	%% 公告给帮派成员
		%% 															Ids = ets:match(?ETS_UNITE, #ets_unite{id='$1', guild_id=GuildId, _='_'}),
																	Ids = mod_chat_agent:match(guild_id_pid_sid, [GuildId]),
																	[lib_unite_send:send_to_one(Id, BinData)||[Id, _, _]<-Ids],
																	{1, RLSelfNext#rc_fortune.refresh_left, ?FORTUNE_REFRESH_COLOR, 0}
															end
													end
											end
									end
							end
					end
			end
	end.

%% 感谢赠送  2 送物品1 3 送物品2
thank_orange(SelfId, SelfName, RoleId, Type) ->
	[Title, Format] = data_guild_text:get_mail_text(fortune_thank),
	Content = io_lib:format(Format, [SelfName]),
	case Type of
		1 ->
			case lib_player_unite:spend_assets_status_unite(SelfId, 10000, coin, fortune_gift, "送礼") of
				{ok, ok} ->
					%% 发送邮件礼物;
					lib_mail:send_sys_mail_bg([RoleId], Title, Content, 521301, 2, 0, 0, 1, 0, 0, 0, 0),
					mod_daily_dict:increment(SelfId, 3701001),
					mod_daily_dict:increment(RoleId, 3701002),
					1;
				_R ->
					0
			end;
		2 ->
			case lib_player_unite:spend_assets_status_unite(SelfId, 10, gold, fortune_gift, "送礼") of
				{ok, ok} ->
					%% 发送邮件礼物;
					lib_mail:send_sys_mail_bg([RoleId], Title, Content, 521304, 2, 0, 0, 1, 0, 0, 0, 0),
					mod_daily_dict:increment(SelfId, 3701001),
					mod_daily_dict:increment(RoleId, 3701002),
					1;
				_R ->
					0
			end;
		_ ->
			0
	end.

%% 随机玩家运势颜色
color_get_role() ->
	NewRand_1 = util:rand(0, 1000),
	NewRand = NewRand_1 div 10,
	if
		NewRand > 96 -> 5;
		NewRand > 88 -> 4;
		NewRand > 70 -> 3;
		NewRand > 35 -> 2;
		true -> 1
	end.

%% 获取任务颜色
color_get_task(RoleColor) ->
	{TC1, TC2, TC3, TC4, _} = get_color(RoleColor),
	NewRand_1 = util:rand(0, 1000),
	NewRand = NewRand_1 div 10,
%% 	io:format("NewRand ~p~n", [NewRand]),
	if
		NewRand > TC1 -> 5;
		NewRand > TC2 -> 4;
		NewRand > TC3 -> 3;
		NewRand > TC4 -> 2;
		true -> 1
	end.

%-------------------------------------------------------------------------------
%								基本数据_
%-------------------------------------------------------------------------------

%% 运势日常计数器(游戏线)
fortune_daily(PlayerId, Type, Num) ->
%% 	io:format("S :~p ~p ~p ~n", [PlayerId, Type, Num]),
	mod_daily_dict:plus_count(PlayerId, Type, Num).


%% 获取帮派成员的运势信息
get_one_fortune(PlayerId) ->
	case gen_server:call(mod_guild, {get_fortune, [PlayerId]}, 7000) of
		RL when is_record(RL, rc_fortune)->
			RL;
		_ ->
			[]
	end.


%% 更新帮派成员运势信息
update_one_fortune(PlayerId, Fortune) ->
	gen_server:call(mod_guild, {update_fortune, [PlayerId, Fortune]}, 7000).


%% 获取任务ID列表(所有试炼任务)
get_tasks() ->
	TaskList = data_fortune:get_task_info(),
	lists:map(fun({TaskId, _, _Did, _NT ,_})->
				   TaskId
			  end, TaskList).


%% 根据运气颜色获取任务颜色表
get_color(RoleColor) ->
	TupleList = [
					{1, 35,25,23,10,7}
					, {2, 20,20,30,17,13}
					, {3, 10,15,33,22,20}
					, {4, 7,14,26,27,26}
					, {5, 5,12,18,32,33}
				],
	case lists:keyfind(RoleColor, 1, TupleList) of
		false ->
			[];
		Value ->
			{_, P1, P2, P3, P4, P5} = Value,
			{ 
			 100 - P5
			,100 - P5 - P4
			,100 - P5 - P4 - P3
			,100 - P5 - P4 - P3 - P2
			,100 - P5 - P4 - P3 - P2 - P1
			 }
	end.


%% 根据任务类似获取完成条件和日常ID
get_daily(TaskId) ->
	TaskList = data_fortune:get_task_info(),
	TaskLength = length(TaskList),
	case TaskId > TaskLength of
		true ->
			{0, 0};
		false ->
			case lists:keyfind(TaskId, 1, TaskList) of
				{_, _, Did, NT ,_} ->
					{Did, NT};
				_ ->
					{0, 0}
			end
	end.

%% 根据任务类似获取完成条件和日常ID
get_daily_all() ->
	TaskList = data_fortune:get_task_info(),
	lists:map(fun({_, _, Did, NT ,_})->
				   {Did, NT}
			  end, TaskList).


%% 根据颜色获取任务奖励
%% @param 颜色ID
%% @return 物品ID, 物品奖励数量 帮派资金 神兽成长值 经验 礼包ID
get_prize(TaskColor, LvLimit) ->
	GoodsTypeId = 411001,			%% 帮派建设令
	{GoodsNum, GuildMoney, GAAdd, Exp, GPackId} = data_fortune:get_color_prize(TaskColor, LvLimit),
	{GoodsTypeId, GoodsNum, GuildMoney, GAAdd, Exp, GPackId}.


%% 获取玩家运势刷新纪录:并打包
get_fortune_log_format(RoleId) ->
	FortuneLogList = get_fortune_log(RoleId),
%% 	io:format("FortuneLogList ~p~n", [FortuneLogList]),
	F = fun(OneFl) ->
				[OneFl#rc_fortune_log.refresh_role, OneFl#rc_fortune_log.task_id, OneFl#rc_fortune_log.color, OneFl#rc_fortune_log.refresh_fortune]
		end,
	[F(FOne) || FOne <- FortuneLogList].


%% 保存玩家运势刷新纪录
save_fortune_log(RoleId, FortuneLog) when is_record(FortuneLog, rc_fortune_log) ->
	gen_server:call(mod_guild, {update_fortune_log, [RoleId, FortuneLog]}, 7000).

%% 获取玩家运势刷新纪录
get_fortune_log(RoleId) ->
	case gen_server:call(mod_guild, {get_fortune_log, [RoleId]}, 7000) of
		error ->
			[];
		R ->
			R
	end.

%% 清除玩家运势记录 每日
clear_all_fortune_log() ->
	gen_server:cast(mod_guild, {clear_fortune_log, [clear]}).

%% 清除玩家运势记录 (后台)
clear_fortune_ht() ->
	mod_disperse:cast_to_unite(lib_fortune, clear_all_fortune_log, []).

%%修正本服玩家
fix_fortune_ht() ->
	mod_disperse:cast_to_unite(lib_fortune, fix_fortune, []).

fix_fortune() ->
	gen_server:cast(mod_guild, {fix_fortune_log, [fix]}).
