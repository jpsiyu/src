%% Author: zengzhaoyuan
%% Created: 2012-7-4
%% Description: TODO: Add description to lib_factionwar
-module(lib_factionwar).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([mt_start/5,
		 is_factionwar/1,
		 execute_40201/1,
		 execute_40203/1,
		 execute_40205/1,
		 execute_40208/1,
		 execute_40209/2,
		 execute_40210/2,
		 execute_40212/1,
		 execute_40214/2,
		 execute_40216/1,
		 execute_40219/1,
		 update_player_factionwar/4,
		 update_reset_last_is_win/0,
		 update_last_is_win/1,
		 get_factionNo_resultlist/7,
		 update_factionwar_used_score/2,
		 get_player_factionwar_no/3,
		 get_loop/3,
		 get_born_pos/1,
		 is_spirit/1,
		 set_score_by_kill_player/5,
		 set_score_by_kill_npc/3,
         set_score_by_stone/3,
		 login_out_factionwar/1,
		 get_faction_ids_by_lv_and_funds/1,
		 delete_player_factionwar/1,
		 update_player_factionwar/2,
		 update_factionwar/6,
		 insert_into_factionwar/4,
		 update_factionwar_name/2,
		 update_factionwar_chief_id/2,
		 delete_factionwar/1,
		 load_factionwar/0,
		 get_top_100_player_factionwar/0,
		 load_player_factionwar/1,
		 load_player_factionwar_guild/1,
		 get_round_time/2,
         add_stone/3,
         del_stone/2
     ]).
-include("unite.hrl").
-include("server.hrl").
-include("factionwar.hrl").
-include("guild.hrl").
%%
%% API Functions
%%
%%检测是否帮战进行时
%% @param GuildId 帮派Id
%% @return true|false
is_factionwar(GuildId)->
	[Result,_RestTime,_SignUpNo,_Loop_time,_Loop]=mod_factionwar:get_status(GuildId),
	case Result of
		2->true;
		3->true;
		_->false
	end.

%% 重置所有帮战最后获胜标志
update_reset_last_is_win()->
	db:execute(io_lib:format(<<"update factionwar set last_is_win=0">>,[])).

%% 重置所有帮战最后获胜标志
update_last_is_win(Faction_id)->
	db:execute(io_lib:format(<<"update factionwar set last_is_win=1 where faction_id=~p">>,[Faction_id])).

%%更新竞技场兑换积分
%%@param Id 玩家ID
%%@param UsedScore 积分
update_factionwar_used_score(Id,UsedScore)->
	db:execute(io_lib:format(<<"update player_factionwar set war_score_used=war_score_used+~p where id=~p">>,[UsedScore,Id])).

%%手动开启帮战
mt_start(Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction)->
	mod_factionwar_mgr:mt_start_link(Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction),
	ok.

execute_40201(UniteStatus)->
	[Result,RestTime,SignUpNo,Loop_time,Loop]=mod_factionwar:get_status(UniteStatus#unite_status.guild_id),
	{ok,BinData} = pt_402:write(40201, [Result,RestTime,SignUpNo,Loop_time,Loop]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_40203(UniteStatus)->
	case lib_guild:guild_today_check(UniteStatus#unite_status.id, UniteStatus#unite_status.id) of
		false->void; %当天有退帮
		true->
			[Result,SignUpNum]=mod_factionwar:member_sign_up(UniteStatus),
			{ok,BinData} = pt_402:write(40203, [Result,SignUpNum]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end,
	ok.

execute_40205(UniteStatus)->
	case lib_guild:guild_today_check(UniteStatus#unite_status.id, UniteStatus#unite_status.id) of
		false->void; %当天有退帮
		true->
			FactionId = UniteStatus#unite_status.guild_id,
			case FactionId of
				0->Result=8,Loop=0,CurrentLoop=0,RestTime=0;
				_->
					%检测是否在副本中
					case lib_scene:is_dungeon_scene(UniteStatus#unite_status.scene) of
						false->
							Target_Scene_id = data_factionwar:get_factionwar_config(scene_id),
							case lib_scene:scene_check_enter(UniteStatus#unite_status.id,Target_Scene_id) of
								{error,_}->Result=5,Loop=0,CurrentLoop=0,RestTime=0;
								{true,_}->
                                    DailyPid = lib_player:get_player_info(UniteStatus#unite_status.id,dailypid),
                                    mod_daily:increment(DailyPid, UniteStatus#unite_status.id, 6000006),
                                    [Result,Loop,CurrentLoop,RestTime]=mod_factionwar:enter_factionwar(UniteStatus)
							end;
						true->
							Result=5,Loop=0,CurrentLoop=0,RestTime=0
					end
			end,
			{ok,BinData} = pt_402:write(40205, [Result,Loop,CurrentLoop,RestTime]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end,
	ok.

execute_40208(Uid)->
	mod_factionwar:get_factionwar_info(Uid),
	ok.

execute_40209(UniteStatus,_BUid)->
	case mod_factionwar:can_use_anger(UniteStatus) of
		1->
			SKillId = data_factionwar:get_factionwar_config(anger_skill_id),
            MyKey  = [UniteStatus#unite_status.id, UniteStatus#unite_status.platform, UniteStatus#unite_status.server_num], 
			case lib_battle:battle_use_whole_skill(UniteStatus#unite_status.scene,MyKey,SKillId,MyKey) of
%% 			case lib_battle:battle_use_whole_skill(UniteStatus#unite_status.scene,UniteStatus#unite_status.id,SKillId,BUid) of				
				false->Result = 4;
				true->
					Result = mod_factionwar:use_anger(UniteStatus)
			end;
		_-> Result = 2
	end,
	{ok,BinData} = pt_402:write(40209, [Result]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_40210(UniteStatus,Type)->
	Scene_id = data_factionwar:get_factionwar_config(scene_id),
	if
		Scene_id=:=UniteStatus#unite_status.scene->
			case lib_guild:is_guild_position(bz,UniteStatus#unite_status.guild_position) of
				false->
					Result = 3;
				true ->
					case lib_player:get_player_info(UniteStatus#unite_status.id,position_info) of
						false->Result = 3;
						{Scene,Copy_id,X,Y}->
							Result = mod_factionwar:use_faction_leader_skill(UniteStatus,Type,{Scene,Copy_id,X,Y})	
					end
			end;
		true->
			Result = 5
	end,
	{ok,BinData} = pt_402:write(40210, [Result]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_40212(UniteStatus)->
	Result = mod_factionwar:exit_factionwar(UniteStatus),
	{ok,BinData} = pt_402:write(40212, [Result]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_40216(UniteStatus)->
	Scene_id = data_factionwar:get_factionwar_config(scene_id),
	if
		Scene_id=:=UniteStatus#unite_status.scene->
			Result = mod_factionwar:get_zj(UniteStatus#unite_status.guild_id,UniteStatus#unite_status.id);
		true->
			Result = 3
	end,
	{ok,BinData} = pt_402:write(40216, [Result]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_40219(UniteStatus)->
	case mod_factionwar:get_chief_id(UniteStatus#unite_status.guild_id) of
		0-> X = 0,Y = 0;
		Chief_id->
			case lib_player:get_player_info(Chief_id, position_info) of
				false->X = 0,Y = 0;
				{_Scence,_Copy,_X,_Y}->
					Scene_id = data_factionwar:get_factionwar_config(scene_id),
					if
						Scene_id=:=_Scence andalso UniteStatus#unite_status.copy_id=:=_Copy->
							[X,Y] = [_X,_Y];
						true->
							X = 0,Y = 0
					end
			end
	end,
	{ok, BinData} = pt_402:write(40219, [X,Y]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_40214(UniteStatus,PageNow)->
	%每页数目
	PageSize = 8,
	{Factionwar_dbs,Top_100_player_factionwar} = mod_factionwar:top_list(),
	%获取个人
	case lib_player:get_player_info(UniteStatus#unite_status.id, factionwar) of
		false->
			[WarScore,LastKillNum,No] = [0,0,0];
		Factionwar->
			[WarScore,LastKillNum] = [Factionwar#status_factionwar.war_score,Factionwar#status_factionwar.last_kill_num],
			No = get_player_factionwar_no(Top_100_player_factionwar,UniteStatus#unite_status.id,0)
	end,
	%获取帮派
	Factionwar_dbs_to_list = dict:to_list(Factionwar_dbs),
	Sort_Factionwar_dbs_to_list = lists:sort(fun({_K1,V1},{_K2,V2})-> 
		if
			V2#factionwar_db.faction_war_score =< V1#factionwar_db.faction_war_score->true;
			true->false
		end
	end, Factionwar_dbs_to_list),
	%计算页码
	Length = length(Sort_Factionwar_dbs_to_list),
	if
		Length rem PageSize =:= 0 ->
			PageNum = Length div PageSize;
		true -> 
			PageNum = (Length div PageSize) + 1
	end,
	%计算当前页码
	if
		PageNow=<0 orelse PageNum<PageNow-> %%超出页码范围
			F_Page_Now = 1;
		true ->
			F_Page_Now = PageNow
	end,
	%计算范围
	MinNo = (PageNow-1) * PageSize + 1,
	MaxNo = PageNow * PageSize,
	{FactionNo,ResultList} = get_factionNo_resultlist(Sort_Factionwar_dbs_to_list,
													  UniteStatus#unite_status.guild_id,
													  MinNo,MaxNo,1,0,[]),
	{ok,BinData} = pt_402:write(40214, [WarScore,LastKillNum,No,FactionNo,F_Page_Now,PageNum,ResultList]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.
%%获取玩家帮派记录排名
%% @param Index 从0开始 
get_player_factionwar_no(Top_100_player_factionwar,Id,Index)->
	case Top_100_player_factionwar of
		[]->Index;
		[[H]|T]->
			if
				Id=:=H ->Index+1;
				true->
					get_player_factionwar_no(T,Id,Index+1)
			end
	end.
get_factionNo_resultlist(Sort_Factionwar_dbs_to_list,Guild_id,MinNo,MaxNo,Pos,FactionNo,ResultList)->
	case Sort_Factionwar_dbs_to_list of
		[]->{FactionNo,ResultList};
		[{K,V}|T]->
			if
				MinNo=<Pos andalso Pos=<MaxNo -> 
					New_ResultList = ResultList++[{Pos,
												  V#factionwar_db.faction_name,
												  V#factionwar_db.faction_realm,
												  V#factionwar_db.faction_war_score,
												  V#factionwar_db.last_is_win}];
				true->
					New_ResultList = ResultList
			end,
			if
				K=:=Guild_id ->
					New_FactionNo = Pos;
				true->
					New_FactionNo = FactionNo
			end,
			get_factionNo_resultlist(T,Guild_id,MinNo,MaxNo,Pos+1,New_FactionNo,New_ResultList)
	end.

%%判断是否幽灵状态
%% @param Uid 玩家ID
%% @return 1幽灵 0非幽灵
is_spirit(Uid)->
	mod_factionwar:is_spirit(Uid).

%%通过玩家ID，获取玩家竞技场所在阵营
%%@param Id 玩家ID
%%@return 0时为错 1~5
get_born_pos(Id)->
	mod_factionwar:get_born_pos(Id).

%%设置积分-杀人
set_score_by_kill_player(Uid,KilledUid,Uid_Achieve,KilledUid_Achieve,_HitList)->
	mod_factionwar:set_score(player,Uid,KilledUid,Uid_Achieve,KilledUid_Achieve,_HitList),
	execute_40208(Uid),
	execute_40208(KilledUid).

%%设置积分-杀守护神、箱子
set_score_by_kill_npc(Uid,NPCTypeId,NPCId)->
	mod_factionwar:set_score(npc,Uid,NPCTypeId,NPCId,[],[]),
	execute_40208(Uid).

%%设置积分-交付神石
set_score_by_stone(Uid,NPCTypeId,NPCId)->
	mod_factionwar:set_score(stone,Uid,NPCTypeId,NPCId,[],[]),
	execute_40208(Uid).

%%计算轮次
%% @param Sign_up_num 报名数
%% @param Max_faction_num 每张地图允许最大帮派数
%% @param Loop 默认轮次值，调用本方法时，赋值0即可
get_loop(Sign_up_num,Max_faction_num,Loop)->
	if
		Sign_up_num=:=0->Loop;
		Sign_up_num=<Max_faction_num->Loop+1;
		true->
			if
				(Sign_up_num rem Max_faction_num)=:=0 ->
					Temp_Sign_up_num = (Sign_up_num div Max_faction_num);
				true->
					Temp_Sign_up_num = (Sign_up_num div Max_faction_num) + 1
			end,
			get_loop(Temp_Sign_up_num,Max_faction_num,Loop+1)
	end.

%%登陆时踢出竞技场
%%@param PlayerStatus 玩家状态
%%@return NewPlayerStatus
login_out_factionwar(PlayerStates)->
	Factionwar_Scene_Id = data_factionwar:get_factionwar_config(scene_id),
	[SceneId,X,Y] = data_factionwar:get_factionwar_config(leave_scene),
	if
		PlayerStates#player_status.scene =:= Factionwar_Scene_Id->
			NewPlayerStates = PlayerStates#player_status{
														 scene = SceneId,                          % 场景id
													     copy_id = 0,                        % 副本id 
													     y = X,
													     x = Y
														 },
			NewPlayerStates;
		true->PlayerStates
	end.

%%获取前100名帮战记录玩家
get_top_100_player_factionwar()->
	SQL = io_lib:format(<<"select id from player_factionwar order by war_score desc,war_add_num limit 100">>, []),
	db:get_all(SQL).
	
%%加载玩家帮战信息
%% @param Uid 玩家ID
%% @return [column1,column2,...]
load_player_factionwar(Uid)->
	SQL = io_lib:format(<<"select * from player_factionwar where id=~p">>, [Uid]),
	case db:get_row(SQL) of
		[]->#status_factionwar{};
		L->list_to_tuple([status_factionwar|L])
	end.

%%加载玩家帮战信息,帮派进程调用
%% @param Uid 玩家ID
%% @return [column1,column2,...]
load_player_factionwar_guild(Uid)->
	SQL = io_lib:format(<<"select * from player_factionwar where id=~p">>, [Uid]),
	case db:get_row(SQL) of
		[]->#factionwar_info{};
		L->list_to_tuple([factionwar_info|L])
	end.

%%加载所有帮战记录
load_factionwar()->
	SQL = io_lib:format(<<"select * from factionwar order by faction_score desc,faction_war_score desc,faction_war_add_num">>, []),
	L = db:get_all(SQL),
	Records = [list_to_tuple([factionwar_db|R]) || R <- L],
	factionwar_to_dict(Records,dict:new()).
factionwar_to_dict(Records,Dict)->
	case Records of
		[]->Dict;
		[H|T]->
			New_Dict = dict:store(H#factionwar_db.faction_id, H, Dict),
			factionwar_to_dict(T,New_Dict)
	end.

%% 获取按过滤条件后的帮派ID
%% @param Lv 帮派等级
%% @param Funds 帮派资金
%% @return []|[id1,id2,....]
get_faction_ids_by_lv_and_funds(Lv)->
%% 	SQL = io_lib:format(<<"select id,name,realm,level from guild where level>=~p and funds>=~p">>,[Lv,Funds]),
	SQL = io_lib:format(<<"select id,name,realm,level from guild where level>=~p">>,[Lv]),
	db:get_all(SQL).

update_player_factionwar(Uid,WarScore,KillNum,NowTime)->
	SQL1 = io_lib:format(<<"select count(*) from player_factionwar where id=~p">>,[Uid]),
	case db:get_one(SQL1) of
		Num when is_integer(Num)->
			if
				Num=:=0->
					Flag = false;
				true->
					Flag = true
			end;
		true->
			Flag = true
	end,
	case Flag of
		false->
			SQL = io_lib:format(<<"insert into player_factionwar(id,war_score,war_last_score,last_kill_num,war_add_num,war_last_time) 
								   values(~p,~p,~p,~p,1,~p)">>,[Uid,WarScore,WarScore,KillNum,NowTime]);
		true->
			SQL = io_lib:format(<<"update player_factionwar set war_score=war_score+~p,war_last_score=~p,
								   last_kill_num=~p,war_add_num=war_add_num+1,war_last_time=~p where id=~p">>,
								[WarScore,WarScore,KillNum,NowTime,Uid])
	end,
	db:execute(SQL),
	ok.
	

%%更新玩家帮战记录
%%@param WarScore 单场帮战记录
%%@param Uid 玩家Id
update_player_factionwar(Player_Status,[WarScore,KillNum,NowTime,Uid])->
	Factionwar = Player_Status#player_status.factionwar,
	if
		Factionwar#status_factionwar.war_last_time=<0-> %无记录状态
			SQL = io_lib:format(<<"insert into player_factionwar(id,war_score,war_last_score,last_kill_num,war_add_num,war_last_time) 
								   values(~p,~p,~p,~p,1,~p)">>,[Uid,WarScore,WarScore,KillNum,NowTime]);
		true->
			SQL = io_lib:format(<<"update player_factionwar set war_score=war_score+~p,war_last_score=~p,
								   last_kill_num=~p,war_add_num=war_add_num+1,war_last_time=~p where id=~p">>,
								[WarScore,WarScore,KillNum,NowTime,Uid])
	end,
	db:execute(SQL),
	New_Factionwar = Factionwar#status_factionwar{
		war_score = Factionwar#status_factionwar.war_score + WarScore,			%个人帮战战功
	  	war_last_score = WarScore,		%个人上场帮战战功
	  	war_add_num = Factionwar#status_factionwar.war_add_num + 1,		%参加帮战次数
	  	war_last_time = NowTime									  
	},
	Player_Status#player_status{factionwar=New_Factionwar}.

%%更新帮派帮战记录
%%@param Score 帮战积分
%%@param WarScore 帮战战分
%%@param IsFinalWin 是否最终夺冠 0没有 1夺冠
%%@param FactionId 帮派ID
update_factionwar(Score,WarScore,Now_Time,IsFinalWin,FactionId,Factionwar_db)->
	%判断是否同一周
	{{Last_Year,Last_Month,Last_Day},_} = calendar:now_to_local_time(util:unixtime_to_now(Factionwar_db#factionwar_db.faction_war_last_time)),
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
			SQL = io_lib:format(<<"update factionwar set faction_score=faction_score+~p,
										  				 faction_last_score=~p,
														 faction_war_score=faction_war_score+~p,
														 faction_war_week_score=~p,
														 faction_war_last_score=~p,
														 faction_war_add_num=faction_war_add_num+1,
														 faction_war_last_time=~p,
													     final_win_num=final_win_num+~p 
								   where faction_id=~p">>,
					[Score,Score,WarScore,WarScore,WarScore,Now_Time,IsFinalWin,FactionId]),
			New_Factionwar_db = Factionwar_db#factionwar_db{
				faction_score = Factionwar_db#factionwar_db.faction_score + Score,
				faction_last_score = Score,
				faction_war_score = Factionwar_db#factionwar_db.faction_war_score + WarScore,
				faction_war_week_score = WarScore,
				faction_war_last_score = WarScore,
				faction_war_add_num = Factionwar_db#factionwar_db.faction_war_add_num + 1,
				faction_war_last_time = Now_Time,
				final_win_num = Factionwar_db#factionwar_db.final_win_num +IsFinalWin,
				last_is_win = IsFinalWin
			};
		true->
			SQL = io_lib:format(<<"update factionwar set faction_score=faction_score+~p,
										  				 faction_last_score=~p,
														 faction_war_score=faction_war_score+~p,
														 faction_war_week_score=faction_war_week_score+~p,
														 faction_war_last_score=~p,
														 faction_war_add_num=faction_war_add_num+1,
														 faction_war_last_time=~p,
													     final_win_num=final_win_num+~p 
								   where faction_id=~p">>,
					[Score,Score,WarScore,WarScore,WarScore,Now_Time,IsFinalWin,FactionId]),
			New_Factionwar_db = Factionwar_db#factionwar_db{
				faction_score = Factionwar_db#factionwar_db.faction_score + Score,
				faction_last_score = Score,
				faction_war_score = Factionwar_db#factionwar_db.faction_war_score + WarScore,
				faction_war_week_score = Factionwar_db#factionwar_db.faction_war_week_score + WarScore,
				faction_war_last_score = WarScore,
				faction_war_add_num = Factionwar_db#factionwar_db.faction_war_add_num + 1,
				faction_war_last_time = Now_Time,
				final_win_num = Factionwar_db#factionwar_db.final_win_num +IsFinalWin,
				last_is_win = IsFinalWin
			}
	end,
	db:execute(SQL),
	New_Factionwar_db.
	
%%更改帮派名字
%%@param FactionId 帮派ID
%%@param Faction_name 帮派名字
update_factionwar_name(FactionId,Faction_name)->
	SQL = io_lib:format(<<"update factionwar set faction_name='~s' where faction_id=~p">>,[Faction_name,FactionId]),
	db:execute(SQL).

%%更改帮派帮主ID
%%@param FactionId 帮派ID
%%@param Chief_id 帮主ID
update_factionwar_chief_id(FactionId,Chief_id)->
	SQL = io_lib:format(<<"update factionwar set faction_chief_id=~p where faction_id=~p">>,[Chief_id,FactionId]),
	db:execute(SQL).

%%删除帮战个人记录
delete_player_factionwar(Uid)->
	SQL = io_lib:format(<<"delete from player_factionwar where id=~p">>,[Uid]),
	db:execute(SQL).

%%初始化帮战记录
insert_into_factionwar(Faction_id,Faction_name,Faction_chief_id,Faction_realm)->
	SQL = io_lib:format(<<"insert into factionwar(faction_id,faction_name,faction_chief_id,faction_realm) values(~p,'~s',~p,~p)">>,[Faction_id,Faction_name,Faction_chief_id,Faction_realm]),
	db:execute(SQL).
%%删除帮战记录
delete_factionwar(Faction_id)->
	SQL = io_lib:format(<<"delte from factionwar where faction_id=~p">>,[Faction_id]),
	db:execute(SQL).
%%
%% Local Functions
%%
%% 获取每轮结束时刻
%% @param WholeTime 所有时间（秒）
%% @param Loop 轮次
%% @param [每轮结束时刻]  第几分钟结束，如[11,3]->[3,6,11]
get_round_time(WholeTime,Loop)->
	LoopTime = WholeTime div Loop,
	Rem = WholeTime rem Loop,
	[H|T] = get_round_time_sub(LoopTime,Loop,[]),
	Temp_result = lists:append([H+Rem], T),
	lists:reverse(Temp_result).
get_round_time_sub(LoopTime,Loop,Result)->
	case Loop of
		0->Result;
		_->
			Temp_Result = lists:append(Result,[LoopTime*Loop]),
			get_round_time_sub(LoopTime,Loop-1,Temp_Result)
	end.

%% 采集了帮派水晶
%% Type 1:正常采集 2:打劫所得
add_stone(#player_status{id = Id, socket = Socket, scene = Scene, copy_id = CopyId, x = X, y = Y, realm = Realm, nickname = NickName, sex = Sex, career = Career} = Status, Stone, Type) -> 
    NewStone = case Type of
        1 -> %% 采集所得
            {ok, BinData1} = pt_130:write(13034, [1, [{1, 500001}]]),
            lib_server_send:send_one(Socket, BinData1),
            N = util:rand(1, 100),
            if
                N =< 5  -> 1; % 白
                N =< 20 -> 2; % 绿
                N =< 80 -> 3; % 蓝
                N =< 95 -> 4; % 紫
                true    -> 5  % 橙
            end;
        _ -> Stone
    end,
    %% 传闻
    case Type == 1 andalso NewStone == 5 of
        true -> lib_chat:send_TV({scene, Scene, CopyId}, 0, 2, ["caijiSS",Id, Realm, NickName, Sex, Career, 0]);
        false -> ok
    end,
    NewStatus = Status#player_status{factionwar_stone = NewStone},
    mod_scene_agent:update(factionwar_stone, NewStatus),
    {ok, BinData} = pt_121:write(12107, [Id, NewStone]),
    lib_server_send:send_to_area_scene(Scene, CopyId, X, Y, BinData),
    NewStatus.

%% 交付/被劫帮派水晶
%% Type 1:正常交付 2:被劫
del_stone(#player_status{id = Id, socket = Socket, scene = Scene, copy_id = CopyId, x = X, y = Y, factionwar_stone = Stone} = Status, Type) -> 
    if
        Stone == 0 -> Status;
        Stone > 0 andalso Stone < 11 -> 
            NewStatus = Status#player_status{factionwar_stone = 0},
            case Type of
                1 -> lib_factionwar:set_score_by_stone(Id, Stone, 0);
                _ -> ok
            end,
            mod_scene_agent:update(factionwar_stone, NewStatus),
            {ok, BinData} = pt_121:write(12107, [Id, 0]),
            lib_server_send:send_to_area_scene(Scene, CopyId, X, Y, BinData),
            {ok, BinData1} = pt_130:write(13034, [2, [{1, 500001}]]), %% 技能消失
            lib_server_send:send_one(Socket, BinData1),
            NewStatus;
        true -> Status
    end.
