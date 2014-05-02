%% Author: Administrator
%% Created: 2012-10-27
%% Description: TODO: Add description to lib_bd_1v1
-module(lib_kf_1v1).

%%
%% Include files
%%
-include("unite.hrl").
-include("server.hrl").
-include("kf_1v1.hrl").
%%
%% Exported Functions
%%
-export([
	 load_player_kf_1v1/1,
	 execute_48301/1,
	 execute_48302/1,
	 execute_48303/1,
	 execute_48305/1,
	 execute_48306/1,
	 execute_48310/1,
     execute_48312/1,
	 execute_48313/2,
	 execute_48314/1,
	 execute_48315/1,
	 sort_player/1,
	 when_kill/12,
	 execute_end_bd_1v1/2,
	 login_out_bd_1v1/1,
	 look_match/2,
	 look_match_4_kill/2,
	 look_my_match/6,
	 get_my_no/5,
	 get_top/2,
	 update_log_kf_1v1/1,
	 log_kf_1v1/5
]).

%%
%% API Functions
%%

%% 按照当前轮次及玩家Id，查询其对阵记录
look_match([],[_Platform,_Server_num,_Id])->{error,none};
look_match([{[Temp_Current_loop,APlatform,AServer_num,AId,BPlatform,BServer_num,BId],Value}|T],[Platform,Server_num,Id])->
	if
		Value#bd_1v1_room.win_id=:=0 andalso ((APlatform=:=Platform andalso AServer_num=:=Server_num andalso AId=:=Id) 
				  orelse (BPlatform=:=Platform andalso BServer_num=:=Server_num andalso BId=:=Id)) ->
			{ok,{[Temp_Current_loop,APlatform,AServer_num,AId,BPlatform,BServer_num,BId],Value}};
		true->
			look_match(T,[Platform,Server_num,Id])
	end.
look_match_4_kill([],[_Platform,_Server_num,_Id,_KilledPlatform,_KilledServer_num,_KilledUid])->{error,none};
look_match_4_kill([{[Temp_Current_loop,APlatform,AServer_num,AId,BPlatform,BServer_num,BId],Value}|T],[Platform,Server_num,Id,KilledPlatform,KilledServer_num,KilledUid])->
	if
		Value#bd_1v1_room.win_id=:=0 andalso 
			(((APlatform=:=Platform andalso AServer_num=:=Server_num andalso AId=:=Id) andalso (BPlatform=:=KilledPlatform andalso BServer_num=:=KilledServer_num andalso BId=:=KilledUid))
				  orelse 
			 ((APlatform=:=KilledPlatform andalso AServer_num=:=KilledServer_num andalso AId=:=KilledUid) andalso (BPlatform=:=Platform andalso BServer_num=:=Server_num andalso BId=:=Id))) ->
			{ok,{[Temp_Current_loop,APlatform,AServer_num,AId,BPlatform,BServer_num,BId],Value}};
		true->
			look_match_4_kill(T,[Platform,Server_num,Id,KilledPlatform,KilledServer_num,KilledUid])
	end.

%% 加载玩家跨服1v1数据
%% 返回：[#status_kf_1v1, #status_kf_3v3]
load_player_kf_1v1(Uid)->
	SQL = io_lib:format(<<"select * from player_kf_1v1 where id=~p">>, [Uid]),
	
	%% 3v3周积分
	ScoreWeek = case  db:get_one(io_lib:format(<<"SELECT score FROM rank_bd_3v3 WHERE id=~p">>, [Uid])) of
		null -> 0;
		ScoreField -> ScoreField
	end,
	
	case db:get_row(SQL) of
		[] ->
			[#status_kf_1v1{}, #status_kf_3v3{kf3v3_score_week = ScoreWeek}];
		L ->
			TmpList = lists:reverse(L),
			[_Kf3v3Report, Kf3v3PkWin, Kf3v3PkNum, Kf3v3Mvp | L2] = TmpList,
			List2 = lists:reverse(L2),
			StatusKf1v1 = list_to_tuple([status_kf_1v1 | List2]),
			StatusKf3v3 = list_to_tuple([status_kf_3v3 | [0, Kf3v3Mvp, Kf3v3PkNum, Kf3v3PkWin, ScoreWeek]]),

			[StatusKf1v1, StatusKf3v3]
	end.

execute_48301(UniteStatus)->
	Bd_1v1_stauts = mod_kf_1v1_state:get_status(),
	{ok, BinData} = pt_483:write(48301, [Bd_1v1_stauts]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid,BinData),
	ok.

execute_48302(UniteStatus)->
	%% 检测是否可以进入
	Scene_id1 = data_kf_1v1:get_bd_1v1_config(scene_id1),
	case lib_scene:scene_check_enter(UniteStatus#unite_status.id,Scene_id1) of
		{true,_}->
			case lib_player:get_player_info(UniteStatus#unite_status.id,kf_1v1_info) of
				{Combat_power,_Hp,_Hp_lim,_Scene,Pt,Loop_day,Max_Combat_power, _Status_Kf_1v1}->
					Min_power = data_kf_1v1:get_bd_1v1_config(min_power),
					if
						Min_power=<Combat_power->%%战力够
							Pt_lv = data_kf_1v1:get_pt_lv(Pt),
							Platform = config:get_platform(),
							Server_num = config:get_server_num(),
							Node = mod_disperse:get_clusters_node(),
							Result = 1,
							mod_clusters_node:apply_cast(mod_kf_1v1,enter_prepare,[UniteStatus,Platform,Server_num,Node,Pt_lv,Combat_power,Loop_day,Max_Combat_power]);
						true->
							Result = 3
					end;
				_->
					Result = 3
			end;
		_ER->
			Result = 4
	end,
	case Result of
		1->
			spawn(fun()-> 
				mod_rank:remote_update_kf_rank(UniteStatus#unite_status.dailypid, UniteStatus#unite_status.id)
			end),
			void;
		_->
			{ok, BinData} = pt_483:write(48302, [Result,0,0,0,0,0,0,0,0]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid,BinData)
	end,
	ok.

execute_48303(UniteStatus)->
	Scene_id1 = data_kf_1v1:get_bd_1v1_config(scene_id1),
	if
		Scene_id1 =:= UniteStatus#unite_status.scene -> %%在指定场景内，可操作
			Platform = config:get_platform(),
			Server_num = config:get_server_num(),
			Node = mod_disperse:get_clusters_node(),
			mod_clusters_node:apply_cast(mod_kf_1v1,exit_prepare,[Node,Platform,Server_num,UniteStatus#unite_status.id]);
		true->
			{ok, BinData} = pt_483:write(48303, [2]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid,BinData)
	end,
	
	ok.

execute_48305(UniteStatus)->
	Platform = config:get_platform(),
	Server_num = config:get_server_num(),
	Node = mod_disperse:get_clusters_node(),
	mod_clusters_node:apply_cast(mod_kf_1v1,get_player_pk_list,[Node,Platform,Server_num,UniteStatus#unite_status.id]),
	ok.
look_my_match([],_Player_dict,_Platform,_Server_num,_Id,Result)->Result;
look_my_match([{[_Current_Loop,APlatform,AServer_num,AId,BPlatform,BServer_num,BId],Value}|T],Player_dict,Platform,Server_num,Id,Result)->
	if
		(APlatform=:=Platform andalso AServer_num=:=Server_num andalso AId=:=Id) 
		  orelse (BPlatform=:=Platform andalso BServer_num=:=Server_num andalso BId=:=Id) ->
			if
				Value#bd_1v1_room.win_id=:=Id->
					IsWin = 1;
				Value#bd_1v1_room.win_id=:=0->
					IsWin = 2;
				true->
					IsWin = 0
			end,
			Loop = Value#bd_1v1_room.loop,
			if
				APlatform=:=Platform andalso AServer_num=:=Server_num andalso AId=:=Id->
					if
						BId =:= 0 -> %防止轮空之时
							BPlayer = #bd_1v1_player{};
						true->
							BPlayer = dict:fetch([BPlatform,BServer_num,BId], Player_dict)
					end,
					MyPower = Value#bd_1v1_room.player_a_power,
					BPower = Value#bd_1v1_room.player_b_power;
				true->
					if
						BId =:= 0 ->
							BPlayer = #bd_1v1_player{};
						true->
							BPlayer = dict:fetch([APlatform,AServer_num,AId], Player_dict)
					end,
					MyPower = Value#bd_1v1_room.player_b_power,
					BPower = Value#bd_1v1_room.player_a_power
			end,
			look_my_match(T,Player_dict,Platform,Server_num,Id,Result++[{
				IsWin,
				Loop,
				MyPower,
				BPlayer#bd_1v1_player.id,
				BPlayer#bd_1v1_player.name,
				BPlayer#bd_1v1_player.country,
				BPlayer#bd_1v1_player.sex,
				BPlayer#bd_1v1_player.carrer,
				BPlayer#bd_1v1_player.image,
				BPlayer#bd_1v1_player.lv,
				BPower									 
			}]);
		true->
			look_my_match(T,Player_dict,Platform,Server_num,Id,Result)
	end.

execute_48306(UniteStatus)->
	Platform = config:get_platform(),
	Server_num = config:get_server_num(),
	Node = mod_disperse:get_clusters_node(),
	mod_clusters_node:apply_cast(mod_kf_1v1,get_player_top_list,[Node,Platform,Server_num,UniteStatus#unite_status.id]),
	ok.

execute_48312(UniteStatus)->
	Look_list = mod_kf_1v1_state:get_look_list(),
	{ok, BinData} = pt_483:write(48312, [Look_list]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid,BinData),
	ok.

execute_48313(UniteStatus,Params)->
	[Loop,A_Flat,A_Server_id,A_Id,B_Flat,B_Server_id,B_Id] = Params,
	Platform = config:get_platform(),
	Server_num = config:get_server_num(),
	Node = mod_disperse:get_clusters_node(),
	mod_clusters_node:apply_cast(mod_kf_1v1,look_war,
		[Node,Platform,Server_num,UniteStatus#unite_status.id,
		 Loop,A_Flat,A_Server_id,A_Id,B_Flat,B_Server_id,B_Id]),
	ok.

execute_48315(UniteStatus)->
	Scene_id2 = data_kf_1v1:get_bd_1v1_config(scene_id2),
	if
		UniteStatus#unite_status.scene =:= Scene_id2->
			Platform = config:get_platform(),
			Server_num = config:get_server_num(),
			case lib_player:get_player_info(UniteStatus#unite_status.id,kf_1v1_info) of
				{T_Combat_power,T_Hp,T_Hp_lim,_Scene,_Pt,_Loop_day,_Max_Combat_power, _Status_Kf_1v1}->
					Combat_power=T_Combat_power,Hp=T_Hp,Hp_lim=T_Hp_lim;
				_->
					Combat_power=0,Hp=0,Hp_lim=0
			end,
			mod_clusters_node:apply_cast(mod_kf_1v1,when_logout,[Platform,Server_num,UniteStatus#unite_status.id,Hp,Hp_lim,Combat_power,2]),
			Result = 1;
		true->
			Result = 2
	end,
	{ok, BinData} = pt_483:write(48315, [Result]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid,BinData),
	ok.

execute_48314(UniteStatus)->
	Platform = config:get_platform(),
	Server_num = config:get_server_num(),
	Top_list = mod_kf_1v1_state:get_top_list(),
	My_no = get_my_no(Top_list,Platform,Server_num,UniteStatus#unite_status.id,1),
	{ok, BinData} = pt_483:write(48314, [My_no,Top_list]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid,BinData),
	ok.
get_my_no([],_Platform,_Server_num,_Id,_No)->0;
get_my_no([{BPlatform,BServer_num,BId,_Bname,_Bcountry,_Bsex,_Bcarrer,_Bimage,_Loops,_WinRate,_HpRate,_Pt,_Score,_Lv}|T],Platform,Server_num,Id,No)->
	if
		[BPlatform,BServer_num,BId]=:=[Platform,Server_num,Id]->No;
		true->
			get_my_no(T,Platform,Server_num,Id,No+1)
	end.
get_top([],Result)->Result;
get_top([{_Key,Value}|T],Result)->	
	MyLoop = Value#bd_1v1_player.loop,
	if
		MyLoop=<0 ->
			MyWin = 0,
			MyHp = 0;
		true->
			MyWin = Value#bd_1v1_player.win_loop,
			MyHp = Value#bd_1v1_player.hp*100 div MyLoop
	end,
	get_top(T,Result++[{
		Value#bd_1v1_player.platform,
		Value#bd_1v1_player.server_num,
		Value#bd_1v1_player.id, 	% 玩家Id
		Value#bd_1v1_player.name,	% 玩家名称
		Value#bd_1v1_player.country, %玩家国家
		Value#bd_1v1_player.sex,	%性别
		Value#bd_1v1_player.carrer,	%职业
		Value#bd_1v1_player.image,	%头像
		MyLoop,
		MyWin,
		MyHp,
		Value#bd_1v1_player.pt,
		Value#bd_1v1_player.score,
		Value#bd_1v1_player.lv							
	}]).

execute_48310(UniteStatus)->
	case lib_player:get_player_info(UniteStatus#unite_status.id,kf_1v1_info) of
		{_Combat_power,_Hp,_Hp_lim,_Scene,_Pt,Loop_day,_Max_Combat_power, _Status_Kf_1v1}->
			Loop_max_day = data_kf_1v1:get_bd_1v1_config(loop_max_day),
			if
				Loop_max_day=<Loop_day->
					Result = 6;
				true->
					Result = 1,
					Platform = config:get_platform(),
					Server_num = config:get_server_num(),
					Node = mod_disperse:get_clusters_node(),
					mod_clusters_node:apply_cast(mod_kf_1v1,sign_up,[Node,Platform,Server_num,UniteStatus#unite_status.id])
			end;
		_->
			Result = 6
	end,
	case Result of
		1->void;
		_->
			{ok, BinData} = pt_483:write(48310, [Result]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid,BinData)
	end,
	ok.

%% 杀人判胜负
when_kill(Platform,Server_num,Uid,UidPower,UidHp,UidHpLim,KilledPlatform,KilledServer_num,KilledUid,KilledUidPower,KilledUidHp,KilledUidHpLim)->
	mod_clusters_node:apply_cast(mod_kf_1v1,when_kill,[Platform,Server_num,Uid,UidPower,UidHp,UidHpLim,KilledPlatform,KilledServer_num,KilledUid,KilledUidPower,KilledUidHp,KilledUidHpLim]),
	ok.

%%处理最终1v1分数
%%@param PlayerStatus #player_status
%%@param IsWin 是否胜利
%%@param Hp 最小血量
%%@param MaxHp 最大血量
execute_end_bd_1v1(PlayerStatus,[Loop,WinLoop,Hp,Pt,Score])->
	Bd_1v1 = PlayerStatus#player_status.kf_1v1,
	%判断是否同一周
	Now_Time = util:unixtime(),
	{{Last_Year,Last_Month,Last_Day},_} = calendar:now_to_local_time(util:unixtime_to_now(Bd_1v1#status_kf_1v1.last_time)),
	{{Year,Month,Day},_} = calendar:now_to_local_time(util:unixtime_to_now(Now_Time)),
	LastDays = calendar:date_to_gregorian_days(Last_Year,Last_Month,Last_Day),
	Days = calendar:date_to_gregorian_days(Year,Month,Day),
	Gap_Days = Days - LastDays, 
	if
		Gap_Days<0-> %日期有误情况，按本周算
			IsSameWeek = 1;
		true-> %有1天以上差距
			if
				0=:=Gap_Days->%一天内
					IsSameWeek = 0;
				7=<Gap_Days->%一星期以上
					IsSameWeek = 2;
				true->%一星期以内
					%%星期几
					Last_Day_of_week = calendar:day_of_the_week(Last_Year,Last_Month,Last_Day),
					Day_of_week = calendar:day_of_the_week(Year,Month,Day),
					if
						Day_of_week<Last_Day_of_week-> %%之前的星期更大
							IsSameWeek = 2;
						true->
							IsSameWeek = 1
					end	
			end
	end,
	case IsSameWeek of
		2-> %%非同周
			if
				Bd_1v1#status_kf_1v1.last_time=<0->
					SQL = io_lib:format(?sql_insert_player_Bd_1v1_one,[PlayerStatus#player_status.id,Loop,WinLoop,Hp,Pt,Score,
																	   Loop,WinLoop,Hp,Score,Loop,WinLoop,Hp,Score,Now_Time]);
				true->
					SQL = io_lib:format(?sql_Bd_1v1_update_unsame_week,[Loop,WinLoop,Hp,Pt,Score,Loop,WinLoop,Hp,Score,Loop,WinLoop,Hp,Score,
																		Now_Time,PlayerStatus#player_status.id])
			end,
			New_Bd_1v1 = Bd_1v1#status_kf_1v1{
			  	loop = Bd_1v1#status_kf_1v1.loop + Loop,				%总参与轮次
			  	win_loop = Bd_1v1#status_kf_1v1.win_loop + WinLoop,			%总胜利次数
			  	hp = Bd_1v1#status_kf_1v1.hp + Hp,					%总剩余血量
				pt = Bd_1v1#status_kf_1v1.pt + Pt,
				score = Bd_1v1#status_kf_1v1.score + Score,
			  	loop_week = Loop,			%周总参与次数
			  	win_loop_week = WinLoop,		%周总胜利次数
			 	hp_week = Hp,			%周总剩余血量
			  	score_week = Score,		%周总最大血量
			  	loop_day = Loop,			%天总参与轮次
			  	win_loop_day = WinLoop,		%天总胜利次数
			  	hp_day = Hp,				%天总剩余血量
			  	score_day = Score,			%天总最大血量
				last_time = Now_Time			%最后参与时间									   
	  		};
		1-> %% 同周
			if
				Bd_1v1#status_kf_1v1.last_time=<0->
					SQL = io_lib:format(?sql_insert_player_Bd_1v1_one,[PlayerStatus#player_status.id,Loop,WinLoop,Hp,Pt,Score,
																	   Loop,WinLoop,Hp,Score,Loop,WinLoop,Hp,Score,Now_Time]);
				true->
					SQL = io_lib:format(?sql_Bd_1v1_update_same_week,[Loop,WinLoop,Hp,Pt,Score,Loop,WinLoop,Hp,Score,
																	  Loop,WinLoop,Hp,Score,Now_Time,PlayerStatus#player_status.id])
			end,
			New_Bd_1v1 = Bd_1v1#status_kf_1v1{
				loop = Bd_1v1#status_kf_1v1.loop + Loop,				%总参与轮次
			  	win_loop = Bd_1v1#status_kf_1v1.win_loop + WinLoop,			%总胜利次数
			  	hp = Bd_1v1#status_kf_1v1.hp + Hp,					%总剩余血量
			  	pt = Bd_1v1#status_kf_1v1.pt + Pt,				%总最大血量
				score = Bd_1v1#status_kf_1v1.score + Score,
			  	loop_week = Bd_1v1#status_kf_1v1.loop_week + Loop,			%周总参与次数
			  	win_loop_week = Bd_1v1#status_kf_1v1.win_loop_week + WinLoop,		%周总胜利次数
			 	hp_week = Bd_1v1#status_kf_1v1.hp_week + Hp,			%周总剩余血量
			  	score_week = Bd_1v1#status_kf_1v1.score_week + Score,		%周总最大血量
			  	loop_day = Loop,			%天总参与轮次
			  	win_loop_day = WinLoop,		%天总胜利次数
			  	hp_day = Hp,				%天总剩余血量
			  	score_day = Score,			%天总最大血量
				last_time = Now_Time			%最后参与时间									   
	  		};
		_-> %% 同日
			if
				Bd_1v1#status_kf_1v1.last_time=<0->
					SQL = io_lib:format(?sql_insert_player_Bd_1v1_one,[PlayerStatus#player_status.id,Loop,WinLoop,Hp,Pt,Score,
																	   Loop,WinLoop,Hp,Score,Loop,WinLoop,Hp,Score,Now_Time]);
				true->
					SQL = io_lib:format(?sql_Bd_1v1_update_same_day,[Loop,WinLoop,Hp,Pt,Score,Loop,WinLoop,Hp,Score,
																	 Loop,WinLoop,Hp,Score,Now_Time,PlayerStatus#player_status.id])
			end,
			New_Bd_1v1 = Bd_1v1#status_kf_1v1{
				loop = Bd_1v1#status_kf_1v1.loop + Loop,				%总参与轮次
			  	win_loop = Bd_1v1#status_kf_1v1.win_loop + WinLoop,			%总胜利次数
			  	hp = Bd_1v1#status_kf_1v1.hp + Hp,					%总剩余血量
			  	pt = Bd_1v1#status_kf_1v1.pt + Pt,				%总最大血量
				score = Bd_1v1#status_kf_1v1.score + Score,	
			  	loop_week = Bd_1v1#status_kf_1v1.loop_week + Loop,			%周总参与次数
			  	win_loop_week = Bd_1v1#status_kf_1v1.win_loop_week + WinLoop,		%周总胜利次数
			 	hp_week = Bd_1v1#status_kf_1v1.hp_week + Hp,			%周总剩余血量
			  	score_week = Bd_1v1#status_kf_1v1.score_week + Score,		%周总最大血量
			  	loop_day = Bd_1v1#status_kf_1v1.loop_day + Loop,			%天总参与轮次
			  	win_loop_day = Bd_1v1#status_kf_1v1.win_loop_day + WinLoop,		%天总胜利次数
			  	hp_day = Bd_1v1#status_kf_1v1.hp_day + Hp,				%天总剩余血量
			  	score_day = Bd_1v1#status_kf_1v1.score_day + Score,			%天总最大血量
				last_time = Now_Time			%最后参与时间									   
	  		}
	end,
	db:execute(SQL),
	New_PlayerStatus = PlayerStatus#player_status{kf_1v1=New_Bd_1v1},
	New_PlayerStatus.

%%排序玩家记录
%%规则：获胜次数大、胜率大、血量比大。
sort_player(Player_dict_List)->
	lists:sort(fun({_K1,A},{_K2,B})-> 
		if
			A#bd_1v1_player.score>B#bd_1v1_player.score->true;
			A#bd_1v1_player.score =:= B#bd_1v1_player.score->
				if
					A#bd_1v1_player.win_loop>B#bd_1v1_player.win_loop-> true;
					A#bd_1v1_player.win_loop=:=B#bd_1v1_player.win_loop->%%两个都比指定的小或大
						if
							A#bd_1v1_player.loop=<0->false;
							true->
								if
									B#bd_1v1_player.loop=<0->true;
									true->%%均大于0
										A_rate = A#bd_1v1_player.win_loop/A#bd_1v1_player.loop,
										B_rate = B#bd_1v1_player.win_loop/B#bd_1v1_player.loop,
										if
											A_rate > B_rate -> true;
											A_rate =:= B_rate ->
												A_Hp_rate = A#bd_1v1_player.hp/A#bd_1v1_player.loop,
												B_Hp_rate = B#bd_1v1_player.hp/B#bd_1v1_player.loop,
												if
													B_Hp_rate =< A_Hp_rate ->true;
													true->false
												end;
											true->false
										end
								end
						end;
					true->false
				end;
			true->false
		end					   
	end, Player_dict_List).

%%登陆时踢出战斗区
%%@param PlayerStatus 玩家状态
%%@return NewPlayerStatus
login_out_bd_1v1(PlayerStates)->
	Bd_1v1_Scene_id1 = data_kf_1v1:get_bd_1v1_config(scene_id1),
	Bd_1v1_Scene_id2 = data_kf_1v1:get_bd_1v1_config(scene_id2),
	[SceneId,X,Y] = data_kf_1v1:get_bd_1v1_config(leave_scene),
	if
		PlayerStates#player_status.scene =:= Bd_1v1_Scene_id1
		  orelse PlayerStates#player_status.scene =:= Bd_1v1_Scene_id2-> % 准备区的，丢出来
			NewPlayerStates = PlayerStates#player_status{
				 scene = SceneId,                    % 场景id
			     copy_id = 0,                        % 副本id 
			     y = X,
			     x = Y
			},
			NewPlayerStates;
		true->PlayerStates
	end.

%%1v1日志入库
update_log_kf_1v1(Log_1v1_dict)->
	Log_1v1_dict_list = dict:to_list(Log_1v1_dict),
	lists:foreach(fun({[Power,Type],{Win_loop,Loop}})-> 
		db:execute(io_lib:format(<<"update log_kf_1v1 set win_loop=win_loop+~p,`loop`=`loop`+~p where power=~p and type=~p">>, [Win_loop,Loop,Power,Type]))					  
	end, Log_1v1_dict_list).

%%1v1日志
log_kf_1v1(Win_power,Win_carrer,Loos_power,Loos_carrer,Log_1v1_dict)->
	Win_key = [get_log_kf_1v1_power(Win_power),get_log_kf_1v1_type(Win_carrer,Loos_carrer)],
	Loos_key = [get_log_kf_1v1_power(Loos_power),get_log_kf_1v1_type(Loos_carrer,Win_carrer)],
	case dict:is_key(Win_key, Log_1v1_dict) of
		false->
			New_win_Log_1v1_dict = dict:store(Win_key, {1,1}, Log_1v1_dict);
		true->
			{Win_Loop1,Loop1} = dict:fetch(Win_key, Log_1v1_dict),
			New_win_Log_1v1_dict = dict:store(Win_key, {Win_Loop1+1,Loop1+1}, Log_1v1_dict)
	end,
	case dict:is_key(Loos_key, New_win_Log_1v1_dict) of
		false->
			New_loos_Log_1v1_dict = dict:store(Loos_key, {0,1}, New_win_Log_1v1_dict);
		true->
			{Win_Loop2,Loop2} = dict:fetch(Loos_key, New_win_Log_1v1_dict),
			New_loos_Log_1v1_dict = dict:store(Loos_key, {Win_Loop2,Loop2+1}, New_win_Log_1v1_dict)
	end,
	New_loos_Log_1v1_dict.
get_log_kf_1v1_power(Power)->
	if 
		Power>35000->1000000;
		Power>30000->35000;
		Power>25000->30000;
		Power>20000->25000;
		Power>15000->20000;
		Power>10000->15000;
		true->10000
	end.
get_log_kf_1v1_type(A_carrer,B_carrer)->%%职业对阵类型
	case A_carrer of
		1->
			case B_carrer of
				1->1;
				2->2;
				3->3
			end;
		2->
			case B_carrer of
				1->4;
				2->5;
				3->6
			end;
		3->
			case B_carrer of
				1->7;
				2->8;
				3->9
			end
	end.

%%
%% Local Functions
%%

