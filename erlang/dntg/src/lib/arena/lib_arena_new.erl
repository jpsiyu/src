%% Author: zengzhaoyuan
%% Created: 2012-5-21
%% Description: TODO: Add description to lib_arena_new
-module(lib_arena_new).
-include("server.hrl").
-include("unite.hrl").
-include("arena_new.hrl").
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([mt_start_link/4,
		 execute_48001/1,
		 execute_48003/1,
		 execute_48004/1,
		 execute_48009/1,
		 send_48010_to_all/0,
		 sort_arena_room/1,
		 sort_arena_room/2,
		 login_out_arena/1,
		 set_score_by_kill_player/3,
		 set_score_by_kill_npc/2,
		 stop_continuous_kill_by_numen_kill/2,
		 update_arena_used_score/2]). 
-compile(export_all).
%%
%% API Functions
%%
%% 手动启动服务器(慎用本方法，如果是竞技场中途使用，当前竞技场记录将作废)
%% @param Config_Begin_Hour 起始时刻
%% @param Config_Begin_Minute 起始时刻
%% @param Config_End_Hour 终止时刻
%% @param Config_End_Minute 终止时刻
%% @return ok
mt_start_link(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute)->
	%%重置竞技场
	mod_arena_mgr_new:mt_start_link(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute),
	ok.


%%更新进入竞技场时间方法
update_enter_time(Id,War_end_time)->
	lib_player:update_player_info(Id, [{war_end_time,War_end_time}]),
	lib_player_unite:update_unite_info(Id, [{war_end_time,War_end_time}]).

%%更新竞技场兑换积分
%%@param Id 玩家ID
%%@param UsedScore 积分
update_arena_used_score(Id,UsedScore)->
	db:execute(io_lib:format(<<"update player_arena set arena_score_used=arena_score_used+~p where id=~p">>,[UsedScore,Id])).

%% 手动启动服务器(慎用本方法，如果是竞技场中途使用，当前竞技场记录将作废)
%% @param Config_Begin_Hour 起始时刻
%% @param Config_Begin_Minute 起始时刻
%% @param Config_End_Hour 终止时刻
%% @param Config_End_Minute 终止时刻
%% @param Boss_Time 创建boss的时间间隔
%% @return ok|_
execute_48099(_Uid,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, Boss_Time)->
	%%重置竞技场
	mod_arena_mgr_new:mt_start_link(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, Boss_Time),
	ok.

%% 48001协议处理结果
execute_48001(UniteStatus) ->
	Apply_level = data_arena_new:get_arena_config(apply_level),
	Exp_multiple = data_arena_new:get_arena_config(exp_multiple),
	if 
		UniteStatus#unite_status.lv < Apply_level ->
			Status = 0,
			{ok, BinData} = pt_480:write(48001, [Status, Exp_multiple]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		true ->
			mod_arena_new:execute_48001(UniteStatus, Exp_multiple)
		end,
	ok.

%% 48003协议处理结果。
execute_48003(UniteStatus)->
	SceneId = data_arena_new:get_arena_config(scene_id),
	case lib_scene:scene_check_enter(UniteStatus#unite_status.id,SceneId) of
		{error,_Code}->
			{ok, BinData} = pt_480:write(48003, [7, 0, 0, 0, 0, 0, 0]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		{true,_}->
			mod_arena_new:goin_room(UniteStatus)
	end,
	ok.

%% 48004协议处理结果。
execute_48004(Uid)->
	mod_arena_new:score_list(Uid),
	ok.

%% 48009协议处理结果。
execute_48009(UniteStatus)->
 	mod_arena_new:leave_room(UniteStatus),
	ok.

%% 竞技场开始时，48010协议广播所有符合等级的在线玩家
send_48010_to_all()->
	{ok, BinData} = pt_480:write(48010, []),
	Apply_level = data_arena_new:get_arena_config(apply_level),
	lib_unite_send:send_to_all(Apply_level, 999,BinData),
	ok.


%% 结算
account_score(Multiple_all_data,Arena,Arena_room)->
	Realm_no = sort_arena_room(Arena_room,Arena#arena.realm),
	
	Realm_no_score = data_arena_new:get_score_by_realm_no(Realm_no),
	
	Multiple = lib_multiple:get_multiple_by_type(4,Multiple_all_data),
	Score = Multiple*(Realm_no_score + Arena#arena.score),
	{Realm_no,Realm_no_score,Score}.
	


%%处理最终竞技场分数
%%@param PlayerStatus #player_status
%%@param Id 玩家ID
%%@param Score 积分
%%@param Kill_num 杀人数
%%@param Max_continuous_kill 最大连斩数
execute_end_arena(PlayerStatus,[RoomLv,Room_Id,Score,Kill_num,Killed_Num,Max_continuous_kill])->
	Arena = PlayerStatus#player_status.arena,
	%判断是否同一周
	Now_Time = util:unixtime(),
	{{Last_Year,Last_Month,Last_Day},_} = calendar:now_to_local_time(util:unixtime_to_now(Arena#status_arena.arena_last_time)),
	{{Year,Month,Day},_} = calendar:now_to_local_time(util:unixtime_to_now(Now_Time)),
	LastDays = calendar:date_to_gregorian_days(Last_Year,Last_Month,Last_Day),
	Days = calendar:date_to_gregorian_days(Year,Month,Day),
	Gap_Days = Days - LastDays, 
	if
		Gap_Days=<0-> %日期有误情况，按本周算
			IsSameWeek = true;
		true-> %有1天以上差距
			if
				7=<Gap_Days->%一星期以上
					IsSameWeek = false;
				true->%一星期以内
					%%星期几
					Last_Day_of_week = calendar:day_of_the_week(Last_Year,Last_Month,Last_Day),
					Day_of_week = calendar:day_of_the_week(Year,Month,Day),
					if
						Day_of_week<Last_Day_of_week-> %%之前的星期更大
							IsSameWeek = false;
						true->
							IsSameWeek = true
					end	
			end
	end,
	case IsSameWeek of
		false->
			if
				Arena#status_arena.arena_last_time=<0->
					SQL = io_lib:format(?sql_insert_player_arena_one,[PlayerStatus#player_status.id,RoomLv,Room_Id,Score,
																	  Score,Score,Kill_num,Kill_num,Killed_Num,
																	  Max_continuous_kill,Max_continuous_kill,Now_Time]);
				true->
					SQL = io_lib:format(?sql_arena_update_unsame_week,[RoomLv,Room_Id,Score,Score,Score,
															   Kill_num,Kill_num,Killed_Num,Max_continuous_kill,
															   Max_continuous_kill,Now_Time,PlayerStatus#player_status.id])
			end,
			New_Arena = Arena#status_arena{
				arena_room_lv = RoomLv,
				arena_room_id = Room_Id,										   
				arena_score_total = Arena#status_arena.arena_score_total+Score,				%竞技场总积分
			    arena_score_week = Score,				%竞技场周积分
			    arena_score_day = Score,				%竞技场日积分
			    arena_kill_week = Kill_num,				%竞技场周杀人次数
			    arena_kill_day = Kill_num,					%竞技场日杀人数
				arena_killed_total = Arena#status_arena.arena_killed_total + Killed_Num,
			    arena_max_continuous_kill_week = Max_continuous_kill,	%竞技场周最高连斩数
			    arena_max_continuous_kill_day = Max_continuous_kill,	%竞技场日最高连斩数
				arena_join_total = Arena#status_arena.arena_join_total+1,
				arena_last_time = Now_Time 									   
	  		};
		true->
			Max_arena_max_continuous_kill_week = max(Arena#status_arena.arena_max_continuous_kill_week,Max_continuous_kill),
			if
				Arena#status_arena.arena_last_time=<0->
					SQL = io_lib:format(?sql_insert_player_arena_one,[PlayerStatus#player_status.id,RoomLv,Room_Id,Score,
																	  Score,Score,Kill_num,Kill_num,Killed_Num,
																	  Max_continuous_kill,Max_continuous_kill,Now_Time]);
				true->
					SQL = io_lib:format(?sql_arena_update_same_week,[RoomLv,Room_Id,Score,Score,Score,Kill_num,
															 Kill_num,Killed_Num,Max_arena_max_continuous_kill_week,
															 Max_continuous_kill,Now_Time,PlayerStatus#player_status.id])
			end,
			New_Arena = Arena#status_arena{
				arena_room_lv = RoomLv,
				arena_room_id = Room_Id,										   
				arena_score_total = Arena#status_arena.arena_score_total+Score,				%竞技场总积分
			    arena_score_week = Arena#status_arena.arena_score_week + Score,				%竞技场周积分
			    arena_score_day = Score,				%竞技场日积分
			    arena_kill_week = Arena#status_arena.arena_kill_week + Kill_num,				%竞技场周杀人次数
			    arena_kill_day = Kill_num,					%竞技场日杀人数
				arena_killed_total = Arena#status_arena.arena_killed_total + Killed_Num,
			    arena_max_continuous_kill_week = Max_arena_max_continuous_kill_week,	%竞技场周最高连斩数
			    arena_max_continuous_kill_day = Max_continuous_kill,	%竞技场日最高连斩数
				arena_join_total = Arena#status_arena.arena_join_total+1,
				arena_last_time = Now_Time									   
	  		}
	end,
	db:execute(SQL),
	New_PlayerStatus = PlayerStatus#player_status{arena=New_Arena},
	New_PlayerStatus.

%%设置积分-杀人
set_score_by_kill_player(Uid,KilledUid,HitList)->
	mod_arena_new:set_score(player,Uid,KilledUid,HitList),
	execute_48004(Uid),
	execute_48004(KilledUid).

%%设置积分-杀守护神、箱子
set_score_by_kill_npc(Uid,NPCTypeId)->
	%%设置积分
	mod_arena_new:set_score(npc,Uid,NPCTypeId, []),
	execute_48004(Uid).

%%终止连斩数，被守护神击杀时
stop_continuous_kill_by_numen_kill(NPCTypeId,KilledPlayerId)->
	mod_arena_new:stop_continuous_kill_by_numen_kill(NPCTypeId,KilledPlayerId),
	execute_48004(KilledPlayerId).
	

%% 与当前时间比，竞技场剩余时间
%% @return int 0为未开始或已结束，单位是秒
get_arena_remain_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute)->
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60+Second,
	Config_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute)*60,
	Config_End = (Config_End_Hour*60 + Config_End_Minute)*60,
	if
		NowTime<Config_Begin->0;
		Config_Begin=<NowTime andalso NowTime<Config_End->Config_End-NowTime;
		Config_End=<NowTime->0
	end.

%%登陆时踢出竞技场
%%@param PlayerStatus 玩家状态
%%@return NewPlayerStatus
login_out_arena(PlayerStates)->
	Arena_Scene_Id = data_arena_new:get_arena_config(scene_id),
	[SceneId,X,Y] = data_arena_new:get_arena_config(leave_scene),
	if
		PlayerStates#player_status.scene =:= Arena_Scene_Id->
			NewPlayerStates = PlayerStates#player_status{
														 scene = SceneId,                          % 场景id
													     copy_id = 0,                        % 副本id 
													     x = X,
													     y = Y
														 },
			Pk = NewPlayerStates#player_status.pk,
			if
				Pk#status_pk.pk_status=:=6->%%阵营模式
					NewPk = Pk#status_pk{pk_status=2}, %给切回国家模式
					NewPlayerStates#player_status{pk=NewPk};
				true->NewPlayerStates
			end;
		true->PlayerStates
	end.
	
%%
%% Local Functions
%%

%%对房间两个个阵营排序
%%@param Arena_room 阵营房间
%%@return [1,2,3] 排序后的阵营号(降序)
sort_arena_room_4_realm(Arena_room)->
	%% 按人数排阵营
	if 
		Arena_room#arena_room.green_num >= Arena_room#arena_room.red_num ->
			[1, 2];
		true ->
			[2,1]
	end.


%%对房间三个阵营排序
%%@param Arena_room 阵营房间
%%@return [1,2,3] 排序后的阵营号(积分降序，战力、人数升序)
sort_arena_room(Arena_room) ->
	if 
		Arena_room#arena_room.green_score >= Arena_room#arena_room.red_score ->
			[1,2];
		true ->
			[2,1]
	end.


%%获取指定阵营排序值
%%@param Arena_room 阵营房间
%%@param Realm 指定阵营名次
%%@return [1,2,3] 排序后的阵营号
sort_arena_room(Arena_room,Realm)->
	Sort = sort_arena_room(Arena_room),
	get_pos_in_list(Realm,Sort,1).
get_pos_in_list(Value,List,Pos)->
	Len = length(List),
	Element = lists:nth(Pos, List),
	if
		Len=<Pos orelse Element=:=Value->Pos;
		true->
			get_pos_in_list(Value,List,Pos+1)
	end.


%% 改变boss的奖励归属
%% param: CopyId = int()  房间Id
change_boss_award(CopyId, Mid) ->
	mod_arena_new:change_boss_award(CopyId, Mid).

%% 更新玩家怒气值
update_anger(PlayerId) ->
	mod_arena_new:update_anger(PlayerId),
	execute_48004(PlayerId).