%%%------------------------------------
%%% @Module  : lib_guild_dun
%%% @Author  : hekai
%%% @Description: 
%%%------------------------------------

-module(lib_guild_dun).
-compile(export_all).
-include("server.hrl").
-include("guild_dun.hrl").


init() ->
	NowTime = util:unixtime(),
	SQL = io_lib:format(?SELECT_DATA_FOR_INIT, [NowTime-6*60]),
	db:get_all(SQL).

%% 预约帮派副本
booking_dun(PS, Week, Time) ->
	NowTime = util:unixtime(),
	NowWeek = util:get_day_of_week(),
	ZeroTime= util:unixdate(),
	case Week>=NowWeek of
	true ->
		case Week=:=NowWeek of
		true ->
			BookingTime = ZeroTime+Time*30*60;
		false ->
			WeekGrap = Week-NowWeek,
			BookingTime = WeekGrap*86400+ZeroTime+Time*30*60				
		end,
		case BookingTime>NowTime+5*60 of
		true ->
			PlayerGuild = PS#player_status.guild,
			Position = PlayerGuild#status_guild.guild_position,
			GuildId = PlayerGuild#status_guild.guild_id,
			case Position=:=1 orelse  Position=:=2 of
			true ->
			case lib_guild:guild_today_times(PS#player_status.id, PS#player_status.id) of
			true ->
				{MdTimestamp, NextMdTimestamp} = util:get_week_time(),
				SQL1 = io_lib:format("select ifnull(count(*),0) from guild_dun where guild_id=~p and (openning_time between ~p and ~p) limit 1", [GuildId, MdTimestamp, NextMdTimestamp]),
				Count = db:get_one(SQL1),
				DunName = ?GUILD_DUN++integer_to_list(GuildId), 			
				case misc:whereis_name(global, DunName)=:=undefined andalso Count=:=0 of
					true ->
						SQL2 = io_lib:format(?INSERT_INTO_GUILD_DUN, [GuildId,  PS#player_status.id, PS#player_status.nickname,NowTime,BookingTime]),
						db:execute(SQL2),
						mod_guild_dun:booking_dun(GuildId, BookingTime),					
						%% 发送邮件通知全帮派成员
						mod_disperse:cast_to_unite(lib_guild_dun, send_mail_booking_dun, [GuildId, BookingTime]),
						ErrorCode = 0; %% 预约成功
					false -> 
						ErrorCode = 3 %% 本周已经预约或者举行过
				end;
			false -> ErrorCode=4
			end;			
			false ->
				ErrorCode = 2 %% 不是帮主、副帮主,没有权限
			end;
		false ->
			ErrorCode = 1 %% 预约时间不对,至少提前5分钟
		end;
	false ->
			ErrorCode = 1 %% 预约时间不对,至少提前5分钟
	end,
	{ok, BinData} = pt_405:write(40501, [ErrorCode]),
	lib_server_send:send_one(PS#player_status.socket, BinData).

%% 发送预约帮派副本邮件通知
send_mail_booking_dun(GuildId, BookingTime) ->
	NameList = lib_guild_scene:get_member_name_list(GuildId),
	[Title, Content] = data_guild_text:get_mail_text(open_guild_dun),
	Week = util:get_day_of_week(BookingTime),
	{{_Year, _Month, _Day}, {Hour, Minute, _Second}} = util:seconds_to_localtime(BookingTime),
	Week2 = 
	case Week of
		1 -> "一";
		2 -> "二";
		3 -> "三";
		4 -> "四";
		5 -> "五";
		6 -> "六";
		7 -> "日";
		_ -> ""
	end,
	Content2 = io_lib:format(Content, [Week2, Hour, Minute]),
	lib_mail:send_sys_mail_bg(NameList,Title,Content2,0,0, 0, 0, 0, 0, 0, 0, 0).

%% 重启还原数据
restart_init([], GuildDunState) ->
	GuildDunState;
restart_init(BookingList, GuildDunState) ->
	[H|T] =BookingList,
	[GuildId, BeginTime] = H,
	GuildDun = #guild_dun{
			guild_id = 	GuildId,
			start_time = BeginTime
		},	
	NewAllGuildDun = dict:store(GuildId, GuildDun, GuildDunState#guild_dun_state.guild_dun),
	NewGuildDunState = GuildDunState#guild_dun_state{
        guild_dun = NewAllGuildDun
	},
	restart_init(T, NewGuildDunState).
	


%% 进入副本
enter_dun(PlayerId, Lv, NickName, GuildId, GuildDunState) ->
	NowTime = util:unixtime(),
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
		true ->
			{ok,GuildDun2}=GuildDun1,
			AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
			Dun = GuildDun2#guild_dun.beginning_dun,	
			case Dun>=1 andalso Dun=<3 of
			true ->
				Dun2 = integer_to_list(Dun),
				StartTime =	GuildDun2#guild_dun.start_time,	
				ActiveNum = GuildDun2#guild_dun.active_num,
				%% 加上10s的进入时间.
				case NowTime<StartTime+10*60 of
					true ->	PkStatus = 0;					
					false -> PkStatus = ?SOUL_STATUS 					
				end,	
				%% 1.切换场景
				SceneAtom = list_to_atom("dun"++Dun2++"_scene"),
				DunScene = data_guild_dun:get_dun_config(SceneAtom),
				BornAtom = list_to_atom("dun"++Dun2++"_born"),
				[X,Y] = data_guild_dun:get_dun_config(BornAtom),
				%% 2.根据进入时间切换PK状态
				lib_player:update_player_info(PlayerId, [{force_change_pk_status, PkStatus}]),
				lib_scene:player_change_scene(PlayerId, DunScene, GuildId, X, Y, false),
				PlayerGuildDun =#player_guild_dun{id=PlayerId,pk_status=PkStatus,in_dun=1,lv=Lv, nickname= NickName},
				%% 3.记录时间
				case Dun of
					1 -> PlayerGuildDun2=PlayerGuildDun#player_guild_dun{
							player_dun_1=#player_dun_1{start_time = StartTime}
						};
					2 -> PlayerGuildDun2=PlayerGuildDun#player_guild_dun{
							player_dun_2=#player_dun_2{start_time = StartTime}						
						};
					3 -> PlayerGuildDun2=PlayerGuildDun#player_guild_dun{
							player_dun_3=#player_dun_3{start_time = StartTime}
						};
					_ -> PlayerGuildDun2 = PlayerGuildDun
				end,
				AllPlayerGuildDun2 = dict:store(PlayerId, PlayerGuildDun2, AllPlayerGuildDun),	
				GuildDun3 = GuildDun2#guild_dun{
					active_num = ActiveNum+1,
					player_guild_dun=AllPlayerGuildDun2
				},
				AllGuildDun2 = dict:store(GuildId, GuildDun3, AllGuildDun),
				GuildDunState2=GuildDunState#guild_dun_state{
					guild_dun = AllGuildDun2
				},	
				case Dun=:=1 of
					true ->
						case NowTime< StartTime of
							true ->
								{ok, BinData2} = pt_405:write(40509, [StartTime-NowTime]),
								lib_player:update_player_info(PlayerId, [{unite_to_server, BinData2}]);
							false -> skip
						end;
					false -> skip 
				end,
				ErrorCode = 0; %% 成功
			false ->
				ErrorCode = 1, %% 失败
				Dun = 0,
				Dun2 = "1",
				GuildDunState2=GuildDunState
			end;			
		false ->
			ErrorCode = 1, %% 帮派副本未开启
			Dun = 0,
			Dun2 = "1",
			GuildDunState2=GuildDunState
	end,	
	case Dun=/=0 of
		true -> dun_panel(Dun, GuildId, GuildDunState2, 0);
		false -> skip
	end,	
	SceneId = data_guild_dun:get_dun_config(list_to_atom("dun"++Dun2++"_scene")),	
	{ok, BinData} = pt_405:write(40503, [ErrorCode, SceneId]),	
	lib_player:update_player_info(PlayerId, [{unite_to_server, BinData}]),
	GuildDunState2.

%% 退出副本
exit_dun(PlayerId, GuildId, GuildDunState) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	Scene = data_guild_dun:get_dun_config(exit_scene),
	[X,Y] = data_guild_dun:get_dun_config(exit_xy),
	case GuildDun1=/=error of
		true ->
			{ok,GuildDun2}=GuildDun1,
			Dun = GuildDun2#guild_dun.beginning_dun,
			AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,			
			PlayerGuildDun1 = dict:find(PlayerId, AllPlayerGuildDun),	
			case PlayerGuildDun1=/=error of
			true -> 
				{ok,PlayerGuildDun2}=PlayerGuildDun1,
				PlayerGuildDun3 = PlayerGuildDun2#player_guild_dun{
					in_dun=0
				},
				AllPlayerGuildDun2 = dict:store(PlayerId, PlayerGuildDun3, AllPlayerGuildDun),	
				ActiveNum = GuildDun2#guild_dun.active_num,
				GuildDun3 = GuildDun2#guild_dun{
					player_guild_dun=AllPlayerGuildDun2,
					active_num = ActiveNum-1
				},
				AllGuildDun2 = dict:store(GuildId, GuildDun3, AllGuildDun),
				GuildDunState2=GuildDunState#guild_dun_state{
					guild_dun = AllGuildDun2
				},
				%% 设置pk状态
				lib_player:update_player_info(PlayerId, [{force_change_pk_status, 0}]),	
				%% 切换场景				
				lib_scene:player_change_scene(PlayerId, Scene, 0, X, Y, false),
				ErrorCode = 0; %% 成功
			false -> 
				Dun =0,
				ErrorCode = 0, %% 失败				
				GuildDunState2=GuildDunState,
				%% 设置pk状态
				lib_player:update_player_info(PlayerId, [{force_change_pk_status, 0}]),				
				lib_scene:player_change_scene(PlayerId, Scene, 0, X, Y, false)
			end;			
		false ->
			Dun =0,
			ErrorCode = 0, %% 帮派副本未开启			
			GuildDunState2=GuildDunState,
			lib_player:update_player_info(PlayerId, [{force_change_pk_status, 0}]),				
			lib_scene:player_change_scene(PlayerId, Scene, 0, X, Y, false)
	end,
	case Dun=/=0 of
		true -> dun_panel(Dun, GuildId, GuildDunState2, 0);
		false -> skip
	end,
	{ok, BinData} = pt_405:write(40504, [ErrorCode]),	
	lib_player:update_player_info(PlayerId, [{unite_to_server, BinData}]),
	GuildDunState2.

%% 登录处理
login_out(PlayerStatus) ->
	PlayerScene = PlayerStatus#player_status.scene,
	GuildDunScene = [data_guild_dun:get_dun_config(dun1_scene), data_guild_dun:get_dun_config(dun2_scene), data_guild_dun:get_dun_config(dun3_scene)],
	case  lists:member(PlayerScene, GuildDunScene) of
        true ->
			PlayerGuild = PlayerStatus#player_status.guild,
			GuildId = PlayerGuild#status_guild.guild_id,
			PlayerId =  PlayerStatus#player_status.id,
            mod_guild_dun:exit_dun(PlayerId, GuildId),
			Scene = data_guild_dun:get_dun_config(exit_scene),
			[X,Y] = data_guild_dun:get_dun_config(exit_xy),
            PlayerStatus#player_status{
                scene = Scene,
                x = X,
                y = Y
            };
        false ->
            PlayerStatus
    end.

%% 提示玩家 
%% @Type 提示类型 1开始前5分钟提示|2开始提示|3副本结束
remind_msg(Guild, BeginTime, Type) ->
	Week = util:get_day_of_week(BeginTime),
	{{_Year, _Month, _Day}, {Hour, _Minute, _Second}} = util:seconds_to_localtime(BeginTime),
	{ok, BinData} = pt_405:write(40502, [Type, Week, Hour]),
	lib_unite_send:send_to_guild(Guild, BinData).


%% 提示倒计时
countdown_msg(_DunScene, GuildId, Countdown, GuildDunState) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
	true ->
		{ok, BinData} = pt_405:write(40509, [Countdown]),
		{ok,GuildDun2}=GuildDun1,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		PlayerGuildDunList = dict:to_list(AllPlayerGuildDun),				
		F1 = fun({_,PlayerGuildDun1}) -> PlayerGuildDun1#player_guild_dun.in_dun=:=1 end,
		PlayerGuildDunList2 = lists:filter(F1, PlayerGuildDunList),	
%%		io:format("---PlayerGuildDunList2-2--~p,~p~n", [length(PlayerGuildDunList2), length(PlayerGuildDunList)]),
		F2 = fun({_,PlayerGuildDun2}) ->
				lib_player:update_player_info(PlayerGuildDun2#player_guild_dun.id, [{unite_to_server, BinData}])
		end,
		lists:foreach(F2, PlayerGuildDunList2);		
	false -> skip
	end.
	

%% 自动传送 
%% @GuildId			帮派Id
%% @GuildDunState   状态
%% @Dun 1|2|3		关卡1/2/3
%% @StartTime       开始时间 
%% @EndTime         结束时间
auto_transfer(GuildId, GuildDunState, Dun, StartTime, EndTime) when (Dun>=1 andalso Dun=<3) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
		true ->
		{ok,GuildDun2}=GuildDun1,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		PlayerGuildDunList = dict:to_list(AllPlayerGuildDun),
		%% 1.将幽灵状态切换成和平状态
		F1 = fun({_,PlayerGuildDun}) ->
				case PlayerGuildDun#player_guild_dun.pk_status=:=?SOUL_STATUS of
				true ->
				lib_player:update_player_info(PlayerGuildDun#player_guild_dun.id, [{force_change_pk_status, 0}]);
				false -> skip
				end
		end,
		lists:foreach(F1, PlayerGuildDunList),
		%% 2.初始化player_guild_dun副本开始时间 
		F2 = fun(_Key, Value) ->
			Value2 = Value#player_guild_dun{
			pk_status = 0	
			},
			case Dun of
				1 -> Value2#player_guild_dun{player_dun_1 = #player_dun_1{start_time = StartTime},pk_status=0};					
				2 -> Value2#player_guild_dun{player_dun_2 = #player_dun_2{start_time = StartTime},pk_status=0};
				3 -> Value2#player_guild_dun{player_dun_3 = #player_dun_3{start_time = StartTime},pk_status=0};
				_ -> Value2
			end
		end,
		AllPlayerGuildDun2=dict:map(F2, AllPlayerGuildDun),
		%% 3.初始化帮派活动记录
		GuildDun3 = GuildDun2#guild_dun{
			player_guild_dun=AllPlayerGuildDun2,
			beginning_dun=Dun,
			start_time=StartTime,
			end_time=EndTime,
			active_num=GuildDun2#guild_dun.active_num,
			die_num=0	
		},
		NewAllGuildDun = dict:store(GuildId, GuildDun3, GuildDunState#guild_dun_state.guild_dun),
		NewGuildDunState = GuildDunState#guild_dun_state{
        guild_dun = NewAllGuildDun
	    },
		%% 4.传送
		F3 = fun({_,PlayerGuildDun},Acc) ->
				case Acc<10 of
					true ->
						Dun2 = integer_to_list(Dun),
						PlayerId = PlayerGuildDun#player_guild_dun.id,
						SceneAtom = list_to_atom("dun"++Dun2++"_scene"),
						Dun1Scene = data_guild_dun:get_dun_config(SceneAtom),
						BornAtom = list_to_atom("dun"++Dun2++"_born"),
						[X,Y] = data_guild_dun:get_dun_config(BornAtom),
						lib_scene:player_change_scene(PlayerId, Dun1Scene, GuildId, X, Y, false),
						Acc+1;
					false ->
						timer:sleep(200),
						0
				end								
		end,
		lists:foldl(F3, 0, PlayerGuildDunList),	
		GuildDunState2 = NewGuildDunState;
		false -> GuildDunState2 =GuildDunState
	end,
	dun_panel(Dun, GuildId, GuildDunState2, 0),
	GuildDunState2.

%% 设置正在进行的关卡
set_beginning_dun(Dun, GuildId, StartTime, EndTime, GuildDunState) when (Dun>=1 andalso Dun=<3) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),	
	case GuildDun1=/=error of
		true ->
			{ok,GuildDun2}=GuildDun1,
			GuildDun3 = GuildDun2#guild_dun{
				beginning_dun=Dun,
				start_time=StartTime,
				end_time=EndTime
			},
			NewAllGuildDun = dict:store(GuildId, GuildDun3, GuildDunState#guild_dun_state.guild_dun),
			GuildDunState#guild_dun_state{
				guild_dun = NewAllGuildDun
			};
		false -> GuildDunState
	end.

%% 结束副本
stop_guild_dun(GuildId, GuildDunState) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,	
	% 将玩家传送出副本
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
	true -> 
		Scene = data_guild_dun:get_dun_config(exit_scene),
		[X,Y] = data_guild_dun:get_dun_config(exit_xy),
		{ok,GuildDun2}=GuildDun1,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		PlayerGuildDunList = dict:to_list(AllPlayerGuildDun),
		F1 = fun({_,PlayerGuildDun1}) -> PlayerGuildDun1#player_guild_dun.in_dun=:=1 end,
		PlayerGuildDunList2 = lists:filter(F1, PlayerGuildDunList),	
		F2 = fun({_, PlayerGuildDun2}, Acc) ->				
			case Acc<20 of
				true ->
				case PlayerGuildDun2#player_guild_dun.pk_status =:=?SOUL_STATUS of
					true ->
						lib_player:update_player_info(PlayerGuildDun2#player_guild_dun.id, [{force_change_pk_status, 0}]);
					false -> skip
				end,
				lib_scene:player_change_scene(PlayerGuildDun2#player_guild_dun.id, Scene, 0, X, Y, false),
				Acc+1;
				false ->
				timer:sleep(600),
				0
			end
		end,
		lists:foldl(F2, 0, PlayerGuildDunList2);
	false -> skip
	end,
	%% 清掉帮派活动记录
	AllGuildDun2 = dict:erase(GuildId, AllGuildDun),
	GuildDunState#guild_dun_state{
		guild_dun = AllGuildDun2
	}.


%% 奖励结算
award_dun(GuildId, GuildDunState, Dun) when (Dun>=1 andalso Dun=<3)->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
	true ->
		{ok,GuildDun2}=GuildDun1,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		PlayerGuildDunList = dict:to_list(AllPlayerGuildDun),
		if
		Dun=:=1 ->
			send_award(1, PlayerGuildDunList);				 
		Dun=:=2 ->			
	   	 skip;
		Dun=:=3 ->
			send_award(3, PlayerGuildDunList)
	  end;
  false -> skip
  end.

%% 发放得历练声望和帮派财富奖励
send_award(Dun, PlayerGuildDunList)  when (Dun>=1 andalso Dun=<3) ->
	case Dun of
		1 -> 
			F0 = fun({_,PlayerGuildDun})->
						PlayerGuildDun#player_guild_dun.player_dun_1#player_dun_1.is_pass=:=1				
				end,
			{PassPlayerList, _NotPassPlayerList} = lists:partition(F0,PlayerGuildDunList);
		2 -> PassPlayerList = [],_NotPassPlayerList=[] ;
		3 ->
			F0 = fun({_,PlayerGuildDun})->
					PlayerGuildDun#player_guild_dun.pk_status=:=0 andalso
					PlayerGuildDun#player_guild_dun.player_dun_3#player_dun_3.correct_num>0					
			end,
			{PassPlayerList, _NotPassPlayerList} = lists:partition(F0,PlayerGuildDunList)	
	end,
	AwardRatio = data_guild_dun:get_dun_config(dun_award_ratio), 
	Ratio = length(PassPlayerList)*AwardRatio,			
	CaifuBase = 100,			
	AwardCaifu = util:floor(CaifuBase*(1+Ratio)),
	case AwardCaifu>150 of
		true -> AwardCaifu2 = 150;
		false -> AwardCaifu2 =AwardCaifu
	end,
	case length(PassPlayerList)=/=0 of
		true -> AwardCaifu3 = AwardCaifu2;
		false -> AwardCaifu3 = util:floor(AwardCaifu2/2)
	end,
	%% 所有玩家获得历练声望和帮派财富
	F1 = fun({_,PlayerGuildDun1}, Acc0) ->
			case Acc0<10 of
				true ->
					IsPass = 
					case Dun of
						1 ->
							case PlayerGuildDun1#player_guild_dun.player_dun_1#player_dun_1.is_pass=:=1 of						
								true -> 1;
								false -> 2
							end;
						2 -> 1;
						3 ->
							case PlayerGuildDun1#player_guild_dun.pk_status=:=0 andalso 
								PlayerGuildDun1#player_guild_dun.player_dun_3#player_dun_3.correct_num>0 of						
								true -> 1;
								false -> 2
							end
					end,					
					Lv = PlayerGuildDun1#player_guild_dun.lv,
					LlptBase = Lv*2800+(100-(10-Lv*0.1)*(10-Lv*0.1))*1400,
					AwardLlpt = util:floor(LlptBase*(1+Ratio)),					
					case length(PassPlayerList)=/=0 of
						true -> AwardLlpt2 = AwardLlpt;
						false -> AwardLlpt2 = util:floor(AwardLlpt/2)
					end,
%%					io:format("---IsPass---~p,~p~n", [PlayerGuildDun1#player_guild_dun.id, IsPass]),
					{ok, BinData} = pt_405:write(40510, [3, IsPass,AwardLlpt2, AwardCaifu3]),	
					lib_player:update_player_info(PlayerGuildDun1#player_guild_dun.id, [{unite_to_server, BinData}]),
					lib_player:update_player_info(PlayerGuildDun1#player_guild_dun.id, [{guild_dun_award, [AwardLlpt2, AwardCaifu3]}]),
					Acc0+1;
				false -> timer:sleep(200),0
			end
	end,
	lists:foldl(F1, 0, PlayerGuildDunList),
	send_pass_award(Dun, PassPlayerList).
	
%% 发放通关奖励
send_pass_award(_Dun, PassPlayerList)  when (_Dun>=1 andalso _Dun=<3) ->
	[Title, Content] = data_guild_text:get_mail_text(guild_dun_award),
	GoodsId = data_guild_dun:get_dun_config(pass_award_gift),
	F2 = fun({_,PlayerGuildDun2}, Acc1) ->
			case Acc1<10 of
				true -> 
					lib_mail:send_sys_mail_bg([PlayerGuildDun2#player_guild_dun.id], Title, Content, GoodsId, 2, 0, 0,1,0,0,0,0),
					Acc1+1;
				false ->
					timer:sleep(200),Acc1=0
			end
	end,
	lists:foldl(F2, 0, PassPlayerList).

%% ----------------------------- 
%% 关卡一:尖刺陷阱 
%% -----------------------------

%% 初始化陷阱格
init_dun_1(GuildId, GuildDunState) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
	true ->
		{ok,GuildDun2}=GuildDun1,
		CentralPosition = data_guild_dun:get_dun1_central_position(),	
		Dun1Radius = data_guild_dun:get_dun_config(dun1_radius),
		RandTypeList = [1],

		F1 = fun(RandType, Acc0) ->
				TupleData = lists:keyfind(RandType,1,CentralPosition),
				case TupleData=/=false of
					true ->
						F2 = fun(RandList2, Acc1)->
								case RandType of
									1 -> 
										%% 随机一个陷阱格,计算出数据形式为[[X1,X2],[Y1,Y2]]即陷阱格XY坐标区域
										[{X, Y}] = util:list_rand(RandList2),						
										[[{X-Dun1Radius,X+Dun1Radius},{Y-Dun1Radius,Y+Dun1Radius}]|Acc1];
%%									2 ->
%%										%% 随机两个陷阱格
%%										Rand1 = util:list_rand(RandList2),						
%%										RandList3 = lists:delete(Rand1, RandList2),
%%										Rand2 = util:list_rand(RandList3),
%%										[{X1, Y1}] = Rand1,
%%										[{X2, Y2}] = Rand2,
%%										Acc2 = [[{X1-Dun1Radius,X1+Dun1Radius},{Y1-Dun1Radius,Y1+Dun1Radius}]|Acc1],
%%										[[{X2-Dun1Radius,X2+Dun1Radius},{Y2-Dun1Radius,Y2+Dun1Radius}]|Acc2];
									_ -> Acc1
								end				
						end,
						{_, RandList1}=TupleData,
						lists:foldl(F2, [], RandList1)++Acc0;
					false -> Acc0
				end
		end,
		TrapArea= lists:foldl(F1, [], RandTypeList),
		Row4InitData = dun_1_row4_init(4, [], []),
		Row4DataConfig = lists:keyfind(2,1,CentralPosition),
		{_, Row4DataList} = Row4DataConfig,
		TrapArea2 = dun_1_row4_init_help(Row4InitData, Row4DataList, Dun1Radius, 1, []),
%%		io:format("---TrapArea2---~p~n", [TrapArea2]),
		TrapArea3 = TrapArea++TrapArea2,
		GuildDun3 = GuildDun2#guild_dun{
			dun1 = #sys_guild_dun1{
				trap_area = TrapArea3
			}
		},
		AllGuildDun2 = dict:store(GuildId, GuildDun3, AllGuildDun),
		GuildDunState#guild_dun_state{
			guild_dun = AllGuildDun2
		};		
	false ->
		GuildDunState
	end.
dun_1_row4_init_help([], _Row4DataList, _Dun1Radius, _Num, Acc1) ->
	Acc1;
dun_1_row4_init_help(Row4InitData, Row4DataList, Dun1Radius, Num, Acc1) ->
	[H|T] = Row4InitData,
	[InitPoint1, InitPoint2] = H,
	AccList = lists:nth(Num, Row4DataList),
	[{X1, Y1}] = lists:nth(InitPoint1,AccList),
	[{X2, Y2}]= lists:nth(InitPoint2,AccList),
	Acc2 = [[{X1-Dun1Radius,X1+Dun1Radius},{Y1-Dun1Radius,Y1+Dun1Radius}]|Acc1],
	Acc3 = [[{X2-Dun1Radius,X2+Dun1Radius},{Y2-Dun1Radius,Y2+Dun1Radius}]|Acc2],
	dun_1_row4_init_help(T, Row4DataList, Dun1Radius, Num+1, Acc3).
%% 陷阱初始化第四排--模拟器
dun_1_row4_init(0, _Psafe, TrapList)->
	TrapList;
dun_1_row4_init(Num, Psafe, TrapList) ->
	TypeList = [1,2,3],
	case Psafe=/=[] of
		true ->
			[Psafe0] = Psafe,
			RandType1 = util:list_rand(TypeList),
			TypeList2 = lists:delete(RandType1, TypeList),
			RandType2 = util:list_rand(TypeList2),
			case Psafe0 of
				1 ->
					case lists:member(RandType1,[1,2]) andalso lists:member(RandType2,[1,2]) of
						true ->
							ConflictList = [1,2],
							RandType3 = 3,
							RandType4 = util:list_rand(ConflictList),
							Psafe2 = lists:delete(RandType4,ConflictList),
							dun_1_row4_init(Num-1, Psafe2, [[RandType3, RandType4]|TrapList]);
						false ->
							Psafe2 = lists:delete(RandType2,TypeList2),
							dun_1_row4_init(Num-1, Psafe2, [[RandType1, RandType2]|TrapList])
					end;
				3 ->
					case lists:member(RandType1,[2,3]) andalso lists:member(RandType2,[2,3]) of
						true ->
							ConflictList = [2,3],
							RandType3 = 1,
							RandType4 = util:list_rand(ConflictList),
							Psafe2 = lists:delete(RandType4,ConflictList),
							dun_1_row4_init(Num-1, Psafe2, [[RandType3, RandType4]|TrapList]);
						false ->
							Psafe2 = lists:delete(RandType2,TypeList2),
							dun_1_row4_init(Num-1, Psafe2, [[RandType1, RandType2]|TrapList])
					end;
				_ ->
					Psafe2 = lists:delete(RandType2,TypeList2),
					dun_1_row4_init(Num-1, Psafe2, [[RandType1, RandType2]|TrapList])
			end;
		false ->
			RandType1 = util:list_rand(TypeList),
			TypeList2 = lists:delete(RandType1, TypeList),
			RandType2 = util:list_rand(TypeList2),
			Psafe2 = lists:delete(RandType2, TypeList2),
			dun_1_row4_init(Num-1, Psafe2, [[RandType1,RandType2]])
	end.


%% 关卡1尸体列表
dun_1_die_list(GuildId, GuildDunState) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
	true ->
		{ok,GuildDun2}=GuildDun1,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		Dun = GuildDun2#guild_dun.dun1,	
		DieLog = Dun#sys_guild_dun1.die_log,		
		{ok, BinData} = pt_405:write(40512, [DieLog]),	
		PlayerGuildDunList = dict:to_list(AllPlayerGuildDun),				
		F1 = fun({_,PlayerGuildDun1}) -> PlayerGuildDun1#player_guild_dun.in_dun=:=1 end,
		PlayerGuildDunList2 = lists:filter(F1, PlayerGuildDunList),	
		F2 = fun({_,PlayerGuildDun2}) ->
				lib_player:update_player_info(PlayerGuildDun2#player_guild_dun.id, [{unite_to_server, BinData}])
		end,
		lists:foreach(F2, PlayerGuildDunList2);		
	false -> skip
	end.

%% 跳跃尖刺陷阱
%% @PlayerId		玩家Id
%% @GuildId			帮派Id
%% @X				将跳跃的坐标x
%% @Y				将跳跃的坐标y
%% @GuildDunState   状态
%% 通知是否可跳、伤害、死亡
jump_grid(PlayerId, PlayerName, Lv, GuildId, X, Y, GuildDunState) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
		true ->
			{ok,GuildDun2}=GuildDun1,
			AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
			PlayerGuildDun1 = dict:find(PlayerId, AllPlayerGuildDun),	
			case PlayerGuildDun1=/=error of
				true ->
					{ok,PlayerGuildDun2}=PlayerGuildDun1,
					PlayerDun1 = PlayerGuildDun2#player_guild_dun.player_dun_1,
					%% 1.计算是否踩中陷阱[如果踩中,计算伤害]
					Dun1 = GuildDun2#guild_dun.dun1,
					TrapArea = Dun1#sys_guild_dun1.trap_area,
					DieLog = Dun1#sys_guild_dun1.die_log,
					PkState= PlayerGuildDun2#player_guild_dun.pk_status,
					DieNum=GuildDun2#guild_dun.die_num,
					TrapNum =PlayerDun1#player_dun_1.trap_num,
					Nickname = PlayerGuildDun2#player_guild_dun.nickname,
%%					InjureMax = data_guild_dun:get_dun1_injure_config(GuildDun2#guild_dun.active_num),
					case calculate_is_trap(X, Y, TrapArea) of
						true ->	
							% 通知死亡
							TrapNum2 = TrapNum+1,																						 
							lib_player:update_player_info(PlayerId, [{force_change_pk_status, ?SOUL_STATUS}]),
							PkState2 = ?SOUL_STATUS,DieNum2=DieNum+1,DieLog2=[{PlayerId,Nickname,X,Y}|DieLog],
							ErrorCode =0;
						false -> ErrorCode =1,TrapNum2 = TrapNum,PkState2 = PkState,DieNum2=DieNum,DieLog2=DieLog
					end,							
					PlayerGuildDun3 = PlayerGuildDun2#player_guild_dun{
						player_dun_1 = PlayerDun1#player_dun_1{trap_num=TrapNum2},
						pk_status = PkState2
					},
					AllPlayerGuildDun2 = dict:store(PlayerId, PlayerGuildDun3, AllPlayerGuildDun),	
					GuildDun3 = GuildDun2#guild_dun{
						player_guild_dun=AllPlayerGuildDun2,
						die_num=DieNum2,
						dun1=Dun1#sys_guild_dun1{die_log=DieLog2}
					},
					AllGuildDun2 = dict:store(GuildId, GuildDun3, AllGuildDun),
					GuildDunState2=GuildDunState#guild_dun_state{
						guild_dun = AllGuildDun2
					};					    
				false ->
					PkState2 = 0,
					ErrorCode =2, %% 未知错误
					GuildDunState2=GuildDunState
			end;
		false -> 
			PkState2 =0,
			ErrorCode = 3, %% 帮派副本未开启			
			GuildDunState2=GuildDunState
	end,
	case ErrorCode=:=0 orelse ErrorCode=:=1 of
		true ->
			{ok, BinData} = pt_405:write(40514, [ErrorCode, X, Y]),	
			lib_player:update_player_info(PlayerId, [{unite_to_server, BinData}]),
			case ErrorCode of
				0 ->					
					dun_panel(1, GuildId, GuildDunState2, 0),
					{ok, BinData2} = pt_405:write(40518, [1, PlayerName]),	
					lib_player:update_player_info(PlayerId, [{unite_to_server_scene, BinData2}]),					
					spawn(fun() ->						
						timer:sleep(5000),
						mod_guild_dun:back_to_life(PlayerId, GuildId)					
						end);
				1 -> 
					RandExp = util:floor(Lv*util:rand(200, 800)/10),
					RandBCoin = util:floor(Lv*util:rand(10, 50)/10),
					lib_player:update_player_info(PlayerId, [{add_exp, RandExp}]),	
					lib_player:update_player_info(PlayerId, [{add_coin, RandBCoin}])
			end,
			case PkState2=:=?SOUL_STATUS of
				true -> dun_1_die_list(GuildId, GuildDunState2);
				false -> skip
			end;			
		false -> skip
	end,
	GuildDunState2.

%% 关卡1复活
back_to_life(PlayerId, GuildId, GuildDunState) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
		true ->
		{ok,GuildDun2}=GuildDun1,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		PlayerGuildDun1 = dict:find(PlayerId, AllPlayerGuildDun),	
		DieNum=GuildDun2#guild_dun.die_num,	
		Dun1 = GuildDun2#guild_dun.dun1,
		DieLog = Dun1#sys_guild_dun1.die_log,
		case PlayerGuildDun1=/=error of
			true ->				
				{ok,PlayerGuildDun2}=PlayerGuildDun1,	
				PlayerDun1 = PlayerGuildDun2#player_guild_dun.player_dun_1,
				Dun1Scene = data_guild_dun:get_dun_config(dun1_scene),
				[X2,Y2] = data_guild_dun:get_dun_config(dun1_born),
				lib_player:update_player_info(PlayerId, [{force_change_pk_status, 0}]),
				lib_scene:player_change_scene(PlayerId, Dun1Scene, GuildId, X2, Y2, false),	
				DieLog2 = lists:keydelete(PlayerId, 1, DieLog),
				PlayerGuildDun3 = PlayerGuildDun2#player_guild_dun{
						player_dun_1 = PlayerDun1#player_dun_1{trap_num=0},
						pk_status = 0
				},
				AllPlayerGuildDun2 = dict:store(PlayerId, PlayerGuildDun3, AllPlayerGuildDun),
				GuildDun3 = GuildDun2#guild_dun{
					player_guild_dun=AllPlayerGuildDun2,
					die_num=DieNum-1,
					dun1=Dun1#sys_guild_dun1{die_log=DieLog2}
				},
				AllGuildDun2 = dict:store(GuildId, GuildDun3, AllGuildDun),
				GuildDunState2=GuildDunState#guild_dun_state{
					guild_dun = AllGuildDun2
				},
				dun_1_die_list(GuildId, GuildDunState2),
				dun_panel(1, GuildId, GuildDunState2, 0);
			false ->
				GuildDunState2 = GuildDunState
		end;
		false ->
			GuildDunState2 = GuildDunState
	end,
	GuildDunState2.
	

%% 计算是否陷阱格
%% @return false否|true是
calculate_is_trap(_X, _Y, []) ->
	false;
calculate_is_trap(X, Y, TrapArea) ->
	[H|T] = TrapArea,
	[{X1,X2},{Y1,Y2}]=H,
	case X>X1 andalso X<X2 andalso Y>Y1 andalso Y<Y2 of
		true ->  true;
		false -> calculate_is_trap(X, Y, T)
	end.

%% 完成所有跳跃
finish_all_jump(PlayerId, GuildId, GuildDunState) ->
	NowTime = util:unixtime(),
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
		true ->
		{ok,GuildDun2}=GuildDun1,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		PlayerGuildDun1 = dict:find(PlayerId, AllPlayerGuildDun),	
		case PlayerGuildDun1=/=error of
			true ->
			EndTime = GuildDun2#guild_dun.end_time,
			case NowTime=<EndTime of
			true ->
				{ok,PlayerGuildDun2}=PlayerGuildDun1,
				PlayerDun1 = PlayerGuildDun2#player_guild_dun.player_dun_1,	
				case  PlayerGuildDun2#player_guild_dun.pk_status=/=?SOUL_STATUS of
				true ->
					case PlayerDun1#player_dun_1.is_pass =/=1 of
						true ->
							PlayerGuildDun3 = PlayerGuildDun2#player_guild_dun{
								player_dun_1 = PlayerDun1#player_dun_1{is_pass=1,end_time=NowTime}
							},
							AllPlayerGuildDun2 = dict:store(PlayerId, PlayerGuildDun3, AllPlayerGuildDun),	
							GuildDun3 = GuildDun2#guild_dun{
								player_guild_dun=AllPlayerGuildDun2
							},
							AllGuildDun2 = dict:store(GuildId, GuildDun3, AllGuildDun),
							GuildDunState2=GuildDunState#guild_dun_state{
								guild_dun = AllGuildDun2
							},
							ErrorCode=0; %% 成功
						false ->
							ErrorCode = 3, %% 已提交
							GuildDunState2 = GuildDunState
					end;
				false ->
						ErrorCode = 4, %% 已死亡
						GuildDunState2 = GuildDunState
				end;								
			false ->
				ErrorCode = 2, %% 失败，已结束
				GuildDunState2 = GuildDunState
			end;				
			false ->
			ErrorCode = 1, %% 未知错误
			GuildDunState2 = GuildDunState
		end;
		false ->
		ErrorCode = 1, %% 未知错误
		GuildDunState2 = GuildDunState
	end,
	{ok, BinData} = pt_405:write(40513, [ErrorCode]),	
	lib_player:update_player_info(PlayerId, [{unite_to_server, BinData}]),
	GuildDunState2.

%% ----------------------------- 
%% 关卡二:死亡之路
%% -----------------------------
init_mon(GuildId) ->
	SceneId = data_guild_dun:get_dun_config(dun2_scene),
	lib_mon:clear_scene_mon(SceneId, GuildId, 0),	
	[MonId0, MonId1, MonId2] = data_guild_dun:get_dun2_mon_id(),
	Xy0 = data_guild_dun:get_dun2_mon_config(0),
	Xy1 = data_guild_dun:get_dun2_mon_config(1),
	Xy2 = data_guild_dun:get_dun2_mon_config(2),	
	[X0, Y0] = Xy0,
    lib_mon:sync_create_mon(MonId0, SceneId, X0, Y0, 1, GuildId, 1, [{auto_lv, 20}]),
	F1 = fun({X1,Y1})	->
            lib_mon:sync_create_mon(MonId1, SceneId, X1, Y1, 1, GuildId, 1, [{auto_lv, 20}])
	end,
	lists:foreach(F1, Xy1),
	F2 = fun({X2,Y2})	->
            lib_mon:sync_create_mon(MonId2, SceneId, X2, Y2, 1, GuildId, 1, [{auto_lv, 20}])
	end,
	lists:foreach(F2, Xy2).

%%  关卡二提交完成
dun2_finish_escape(PlayerId, GuildId, GuildDunState) ->
	NowTime = util:unixtime(),
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
		true ->
		{ok,GuildDun2}=GuildDun1,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		PlayerGuildDun1 = dict:find(PlayerId, AllPlayerGuildDun),	
		case PlayerGuildDun1=/=error of
			true ->
			EndTime = GuildDun2#guild_dun.end_time,
			case NowTime=<EndTime of
			true ->
				{ok,PlayerGuildDun2}=PlayerGuildDun1,
				PlayerDun2 = PlayerGuildDun2#player_guild_dun.player_dun_2,	
				case  PlayerGuildDun2#player_guild_dun.pk_status=/=?SOUL_STATUS of
				true ->
					case PlayerDun2#player_dun_2.is_pass =/=1 of
						true ->
							PlayerGuildDun3 = PlayerGuildDun2#player_guild_dun{
								player_dun_1 = PlayerDun2#player_dun_2{is_pass=1,end_time=NowTime}
							},
							AllPlayerGuildDun2 = dict:store(PlayerId, PlayerGuildDun3, AllPlayerGuildDun),	
							GuildDun3 = GuildDun2#guild_dun{
								player_guild_dun=AllPlayerGuildDun2
							},
							AllGuildDun2 = dict:store(GuildId, GuildDun3, AllGuildDun),
							GuildDunState2=GuildDunState#guild_dun_state{
								guild_dun = AllGuildDun2
							},
							ErrorCode=0; %% 成功
						false ->
							ErrorCode = 3, %% 已提交
							GuildDunState2 = GuildDunState
					end;
				false ->
					ErrorCode = 4, %% 已死亡
					GuildDunState2 = GuildDunState
				end;								
			false ->
				ErrorCode = 2, %% 失败，已结束
				GuildDunState2 = GuildDunState
			end;				
			false ->
			ErrorCode = 1, %% 未知错误
			GuildDunState2 = GuildDunState
		end;
		false ->
		ErrorCode = 1, %% 未知错误
		GuildDunState2 = GuildDunState
	end,
	{ok, BinData} = pt_405:write(40517, [ErrorCode]),	
	lib_player:update_player_info(PlayerId, [{unite_to_server, BinData}]),
	GuildDunState2.

%% 关卡二死亡处理
dun2_die_handle(PS, GuildDunState) ->
	[PlayerId,GuildId] = get_id_player_guild(PS), 
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
	true ->
		{ok,GuildDun2}=GuildDun1,
		DieNum=GuildDun2#guild_dun.die_num,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		PlayerGuildDun1 = dict:find(PlayerId, AllPlayerGuildDun),					
		case PlayerGuildDun1=/=error of
			true ->				
				{ok,PlayerGuildDun2}=PlayerGuildDun1,
				PlayerGuildDun3 = PlayerGuildDun2#player_guild_dun{
					pk_status = ?SOUL_STATUS
				},
				AllPlayerGuildDun2 = dict:store(PlayerId, PlayerGuildDun3, AllPlayerGuildDun),	
				GuildDun3 = GuildDun2#guild_dun{
					player_guild_dun=AllPlayerGuildDun2,
					die_num=DieNum+1
				},
				AllGuildDun2 = dict:store(GuildId, GuildDun3, AllGuildDun),
				GuildDunState2=GuildDunState#guild_dun_state{
					guild_dun = AllGuildDun2
				},
				ErrorCode = 0;
			false -> 
				ErrorCode = 1,
				GuildDunState2= GuildDunState	
		end;			
	false -> 
		ErrorCode = 1,
		GuildDunState2= GuildDunState		
	end,
	case ErrorCode=:=0 of
	true ->
		lib_player:update_player_info(PlayerId, [{force_change_pk_status, ?SOUL_STATUS}]),
		dun_panel(2, GuildId, GuildDunState2, 0);
	false -> skip
	end,	
	GuildDunState2.

%% ----------------------------- 
%% 关卡三:死亡测试
%% -----------------------------

%% 判断关卡三是否结束：玩家未完全死亡或者还剩未答题
%% @return true是|false否
dun_3_is_end(GuildId, GuildDunState) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),	
	case GuildDun1=/=error of
	true ->
		{ok,GuildDun2}=GuildDun1,
		MaxNum = data_guild_dun:get_dun_config(dun3_max_question), %% 最大题量
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		PlayerGuildDunList = dict:to_list(AllPlayerGuildDun),
		F1 = fun({_,PlayerGuildDun1}) ->
				PlayerGuildDun1#player_guild_dun.pk_status=/=?SOUL_STATUS andalso
				PlayerGuildDun1#player_guild_dun.player_dun_3#player_dun_3.correct_num<MaxNum
		end,
		PlayerGuildDunList2 = lists:filter(F1, PlayerGuildDunList),		
		length(PlayerGuildDunList2)<0;
	false -> true
	end.

%% 获取活动设置时间 
get_start_time(PlayerId, GuildId) ->
	NowTime = util:unixtime(),                   
	{MdTimestamp, NextMdTimestamp} = util:get_week_time(),
	SQL = io_lib:format("select openning_time from guild_dun where guild_id=~p and (openning_time between ~p and ~p) limit 1", [GuildId, MdTimestamp, NextMdTimestamp]),
	OpTime = db:get_one(SQL),
	case OpTime=:=null of
		true -> StartTime= 0;
		false -> StartTime=OpTime
	end,		
	case StartTime=/=0 of
		true ->
			case StartTime>NowTime of
				true -> ErrorCode = 1;					
				false ->
					%% 此处判断暂时使用StartTime/EndTime判断，后面关卡增加EndTime不是固定的得使用dun_is_open
					EndTime = StartTime+10*1*60,
					case NowTime>=StartTime andalso NowTime<EndTime of
						true -> ErrorCode = 2;
						false -> ErrorCode = 3	
					end
			end;
		false -> ErrorCode = 0
	end,
	Week = util:get_day_of_week(StartTime),
	{{_Year, _Month, _Day}, {Hour, Minute, _Second}} = util:seconds_to_localtime(StartTime),	
	case Minute>0 of
		true ->  BookingTime= Hour*2+1;
		false -> BookingTime= Hour*2
	end, 
	{ok, BinData} = pt_405:write(40520, [ErrorCode, Week, BookingTime]),
	lib_server_send:send_to_uid(PlayerId, BinData).
%% 副本是否正在开启
dun_is_open(PlayerId, GuildId, GuildDunState) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),	
	ErrorCode = 
	case GuildDun1=/=error of
	true ->
		{ok,GuildDun2}=GuildDun1,
		BeginDun = GuildDun2#guild_dun.beginning_dun,
		case BeginDun>=1 andalso BeginDun=<3 of
			true -> 0;
			false -> 1
		end;
	false -> 1
	end,
	{ok, BinData} = pt_405:write(40519, [ErrorCode]),
	lib_player:update_player_info(PlayerId, [{unite_to_server, BinData}]).

	
%% 传送去答题
%% 1. 统一PK状态7
transfer_to_answer_question(GuildId, GuildDunState) ->
	NowTime = util:unixtime(),
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
	true ->
		{ok,GuildDun2}=GuildDun1,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		Dun = GuildDun2#guild_dun.dun3,
		MaxPlayerId = Dun#sys_guild_dun3.max_player_id,		
		MaxNum = data_guild_dun:get_dun_config(dun3_max_question), %% 最大题量
		
		%% 1. 判断上一个玩家是否超时未答题，设置死亡
		Dun3AfterAnswerXy = data_guild_dun:get_dun_config(dun3_after_answer_xy),
		Dun3Scene = data_guild_dun:get_dun_config(dun3_scene),
		[X,Y] = data_guild_dun:get_dun_config(dun3_answer_xy),
		case MaxPlayerId=/=0 of
			true ->
				LastData = mod_exit:lookup_last_xy(MaxPlayerId),													
				MaxPlayerGuildDun = dict:find(MaxPlayerId, AllPlayerGuildDun),	
				case MaxPlayerGuildDun=/=error of
					true ->
						{ok,MaxPlayerGuildDun2}=MaxPlayerGuildDun,
						Dun = GuildDun2#guild_dun.dun3,
						case Dun#sys_guild_dun3.is_answer=:=0 of
							true ->
								MaxPlayerGuildDun3 = MaxPlayerGuildDun2#player_guild_dun{
									pk_status = ?SOUL_STATUS
								},
								AllPlayerGuildDun2 = dict:store(MaxPlayerId, MaxPlayerGuildDun3, AllPlayerGuildDun),	
								GuildDun3 = GuildDun2#guild_dun{
									player_guild_dun=AllPlayerGuildDun2,
									dun3 =  Dun#sys_guild_dun3{max_player_id=0}
								},
								AllGuildDun2 = dict:store(GuildId, GuildDun3, AllGuildDun),
								GuildDunState2=GuildDunState#guild_dun_state{
									guild_dun = AllGuildDun2
								},
								%% 通知超时未答题
								{ok, BinData} = pt_405:write(40507, [2]),
								lib_player:update_player_info(MaxPlayerId, [{unite_to_server, BinData}]),
								lib_player:update_player_info(MaxPlayerId, [{force_change_pk_status, ?SOUL_STATUS}]);
							false -> 
								GuildDun3 = GuildDun2,
								AllGuildDun2 =AllGuildDun,
								GuildDunState2=GuildDunState
						end;
					false ->
						GuildDun3 = GuildDun2,
						AllGuildDun2 =AllGuildDun,
						GuildDunState2=GuildDunState
				end,
				case LastData=/=undefined of
					true ->
						[LastScene, LastX, LastY] = LastData;
					false ->
						%% 找不到，配置默认
						LastScene=Dun3Scene,
						[LastX,LastY]=Dun3AfterAnswerXy
				end,
				lib_scene:player_change_scene(MaxPlayerId, LastScene, GuildId, LastX, LastY, false);
			false -> 
				GuildDun3 = GuildDun2,
				AllGuildDun2 =AllGuildDun,
				GuildDunState2=GuildDunState
		end,
        
		%% 2.筛选出在副本内玩家
		PlayerGuildDunList = dict:to_list(GuildDun3#guild_dun.player_guild_dun),		
		F1 = fun({_,PlayerGuildDun1}) ->
				PlayerGuildDun1#player_guild_dun.in_dun=:=1 andalso
				PlayerGuildDun1#player_guild_dun.pk_status=/=?SOUL_STATUS andalso
				PlayerGuildDun1#player_guild_dun.player_dun_3#player_dun_3.correct_num<MaxNum
		end,
		PlayerGuildDunList2 = lists:filter(F1, PlayerGuildDunList),
		%% 3.根据Id由小到大排序
		F2 = fun({_,PlayerGuildDun2}, {_,PlayerGuildDun3}) -> 
				PlayerGuildDun2#player_guild_dun.id=<PlayerGuildDun3#player_guild_dun.id
			 end,
		PlayerGuildDunList3 = lists:sort(F2, PlayerGuildDunList2),
		%% 4.从排序结果中找出比MaxPlayerId大最接近的一个
		F3 = fun({_,PlayerGuildDun4})-> PlayerGuildDun4#player_guild_dun.id>MaxPlayerId end,		
		PlayerGuildDunList4 =  lists:filter(F3, PlayerGuildDunList3),				
		case  length(PlayerGuildDunList4)=:=0 of
			true -> 
				case length(PlayerGuildDunList3)=:=1 of
					true ->  
						% 仅剩下一个玩家
						PlayerGuildDunList5 = PlayerGuildDunList3;
					false ->
						% 重新一轮答题
						PlayerGuildDunList5 = PlayerGuildDunList3
				end;    % 取比MaxPlayerId大最接近的一个
			false -> PlayerGuildDunList5 = PlayerGuildDunList4
		end,
		case length(PlayerGuildDunList5)>=1 of
			true ->
				%% 5. 如果当前MaxPlayerId不为0，则将当前玩家传回原处，传送下一个玩家，再初始化怪物与题目
				{_,PlayerGuildDun} = lists:nth(1,PlayerGuildDunList5),
				PlayerId = PlayerGuildDun#player_guild_dun.id,	
				PositonInfo =lib_player: get_player_info(PlayerId, position_info),
				case PositonInfo=/=false of
					true ->
						{LastScene2, _LastCopyId2, LastX2, LastY2} = PositonInfo,
						mod_exit:insert_last_xy(PlayerId, LastScene2, LastX2, LastY2);
					false -> skip
				end,
				lib_scene:player_change_scene(PlayerId, Dun3Scene, GuildId, X, Y, false),
				%% 6. 传送下一个玩家,生成怪物与题目				   				   
				[RandAnimal, RandQuestion, Dun3] = create_animal_question(GuildId, GuildDunState2),
				case  RandAnimal=/= [] of
					true ->
						%%  通知刷新怪物以及题目
						{ok, BinData1} = pt_405:write(40505, [RandAnimal]),	
						{ok, BinData2} = pt_405:write(40506, RandQuestion),	
						lib_player:update_player_info(PlayerId, [{unite_to_server_scene, BinData1}]),	
						lib_player:update_player_info(PlayerId, [{unite_to_server, BinData2}]);
					false -> skip
				end,

				PerLoop = data_guild_dun:get_dun_config(dun3_per_loop),
				GuildDun4 = GuildDun3#guild_dun{
					dun3 = Dun3#sys_guild_dun3{max_player_id=PlayerId,start_time=NowTime,end_time=NowTime+PerLoop}
				},
				AllGuildDun3 = dict:store(GuildId, GuildDun4, AllGuildDun2),
				GuildDunState3=GuildDunState2#guild_dun_state{
					guild_dun = AllGuildDun3
				},				
				IsEnd=0;			
			false ->				
				IsEnd=1,
				GuildDunState3 = GuildDunState2
		end;		
	false ->
		IsEnd=0,
		GuildDunState3 = GuildDunState
	end,
	%% IsEnd 0未结束|1结束
	[IsEnd,	GuildDunState3]. 
		

%% 生成怪物以及题目
%% ！通知刷新怪物以及题目
create_animal_question(GuildId, GuildDunState) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
	true -> 
		{ok,GuildDun2}=GuildDun1,
		Dun = GuildDun2#guild_dun.dun3,
		%% 1.生成怪物、题目、答案
		RandAnimal = create_animal(),	
		RandQuestion = create_question(),
		Answer = calcula_answer(RandAnimal, RandQuestion),
%%		io:format("----Answer---~p~n", [Answer]),
		Dun3 = Dun#sys_guild_dun3{
			animal = RandAnimal,
			question = RandQuestion,
			answer = Answer,
			is_answer = 0
		};	
	false ->
		Dun3 = #sys_guild_dun3{},
		RandAnimal = [],
		RandQuestion = [1,1,1]
	end,
	[RandAnimal, RandQuestion, Dun3].

%% 生成随机测试怪物
create_animal() ->
	AnimalNum = util:rand(9,12), % 刷新出9-12只怪物
	create_animal_helper(AnimalNum, []).

create_animal_helper(0,RandData) ->
	RandData;
create_animal_helper(Num,RandData) ->
	RandAnimal = util:rand(1,4), 
	RandColor = util:rand(1,3),
	RandData2=[[RandAnimal,RandColor]|RandData],
	create_animal_helper(Num-1,RandData2).

%% 生成随机题目
create_question() ->
	RandType = util:rand(1,3), % 随机题目类型
	RandColor = util:rand(1,3),
	RandAnimal = util:rand(1,4),	
	[RandType, RandColor, RandAnimal].

%% 计算答案
calcula_answer(RandAnimal, RandQuestion) ->
	[RandType, RandColor, RandAnimal2] = RandQuestion,
	case RandType of
		1 ->
			F = fun([Animal,Color],Acc) ->
					case Color=:=RandColor andalso Animal=:=RandAnimal2 of
						true -> Acc+1;
						false -> Acc
					end
			end,
			lists:foldl(F, 0, RandAnimal);
		2 -> 
			F = fun([_Animal,Color],Acc) ->
					case Color=:=RandColor of
						true -> Acc+1;
						false -> Acc
					end
			end,
			lists:foldl(F, 0, RandAnimal);
		3 -> 
			F = fun([Animal,_Color],Acc) ->
					case  Animal=:=RandAnimal2 of
						true -> Acc+1;
						false -> Acc
					end
			end,
			lists:foldl(F, 0, RandAnimal);
		_ -> 99
	end.

%% 答题
answer_question(Answer,PlayerId,GuildId,GuildDunState) ->
	NowTime = util:unixtime(),
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
	true -> 
		{ok,GuildDun2}=GuildDun1,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		PlayerGuildDun1 = dict:find(PlayerId, AllPlayerGuildDun),	
		case PlayerGuildDun1=/=error of
			true ->
				{ok,PlayerGuildDun2}=PlayerGuildDun1,
				PlayerDun = PlayerGuildDun2#player_guild_dun.player_dun_3,
				CorrectNum= PlayerDun#player_dun_3.correct_num,
				PkState= PlayerGuildDun2#player_guild_dun.pk_status,
				DieNum=GuildDun2#guild_dun.die_num,
				Dun = GuildDun2#guild_dun.dun3,
				EndTime = Dun#sys_guild_dun3.end_time,
				CorrectAnswer = Dun#sys_guild_dun3.answer,								
				case PlayerGuildDun2#player_guild_dun.pk_status=/=?SOUL_STATUS of
				true ->
					case NowTime=<EndTime of
						true ->
							case Dun#sys_guild_dun3.is_answer=/=1 of
								true ->
									case Answer=:=CorrectAnswer of
										true ->  
											%% 答对题 
											CorrectNum2 = CorrectNum+1,
											PkState2 = PkState,
											DieNum2 = DieNum,
											ErrorCode = 0; % 答对题
										false -> 
											%% 答错题，设置死亡
											CorrectNum2 = CorrectNum,
											%%PkState2 = PkState, %% 调试方便，暂时不设置死亡
											PkState2 = ?SOUL_STATUS,
											DieNum2 = DieNum+1,
											ErrorCode = 3 % 答错题
									end,						
									PlayerGuildDun3 = PlayerGuildDun2#player_guild_dun{
										pk_status = PkState2,
										player_dun_3 = PlayerDun#player_dun_3{correct_num=CorrectNum2}
									},
									AllPlayerGuildDun2 = dict:store(PlayerId, PlayerGuildDun3, AllPlayerGuildDun),	
									GuildDun3 = GuildDun2#guild_dun{
										player_guild_dun=AllPlayerGuildDun2,
										die_num=DieNum2,
										dun3=Dun#sys_guild_dun3{is_answer=1}
									},
									AllGuildDun2 = dict:store(GuildId, GuildDun3, AllGuildDun),
									GuildDunState2=GuildDunState#guild_dun_state{
										guild_dun = AllGuildDun2
									};
								false ->
									ErrorCode = 4,   % 已答题
									GuildDunState2 = GuildDunState
							end;										
						false ->
							ErrorCode = 2,   % 已过时
							GuildDunState2 = GuildDunState
					end;
				false ->
						ErrorCode = 5,   % 已死亡，不能答题
						GuildDunState2 = GuildDunState
				end;				
			false ->
				ErrorCode = 1,   % 未知错误
				GuildDunState2 = GuildDunState
		end;		
	false ->
		 ErrorCode = 1,   % 未知错误
		 GuildDunState2 = GuildDunState
	end,
	case ErrorCode  of
		0 -> dun_panel(3, GuildId, GuildDunState2, PlayerId);
		3 -> lib_player:update_player_info(PlayerId, [{force_change_pk_status, ?SOUL_STATUS}]);
		_ -> skip
	end,
    {ok, BinData} = pt_405:write(40507, [ErrorCode]),
	lib_player:update_player_info(PlayerId, [{unite_to_server, BinData}]),
	GuildDunState2.

%% 关卡三怪物列表
dun_3_animal(PlayerId, GuildId, GuildDunState) ->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
	true -> 
		{ok,GuildDun2}=GuildDun1,
		Dun = GuildDun2#guild_dun.dun3,
		AnimalList = Dun#sys_guild_dun3.animal,	
		{ok, BinData1} = pt_405:write(40505, [AnimalList]),	
		lib_player:update_player_info(PlayerId, [{unite_to_server, BinData1}]);
    false -> skip
	end.


%% 关卡面板信息(更新所有人或更新个人)
%% @ PlayerId为0更新所有人，否则更新PlayerId个人
dun_panel(Dun, GuildId, GuildDunState, PlayerId) when (Dun>=1 andalso Dun=<3)->
	AllGuildDun = GuildDunState#guild_dun_state.guild_dun,
	GuildDun1 = dict:find(GuildId, AllGuildDun),
	case GuildDun1=/=error of
	true ->
		NowTime = util:unixtime(),
		{ok,GuildDun2}=GuildDun1,
		AllPlayerGuildDun = GuildDun2#guild_dun.player_guild_dun,
		case Dun of
		1 ->
		%% 关卡1信息: 倒计时、参与人数，存活人数，踩中陷阱数
		ActiveNum = GuildDun2#guild_dun.active_num,
		DieNum = GuildDun2#guild_dun.die_num,
		StartTime = GuildDun2#guild_dun.start_time,
		EndTime = GuildDun2#guild_dun.end_time,
		case NowTime>=StartTime andalso EndTime> NowTime of
			true -> EndTime2 = EndTime-NowTime;
			false -> EndTime2 =0
		end,
		case PlayerId=:=0 of
			true ->
				PlayerGuildDunList = dict:to_list(AllPlayerGuildDun),				
				F1 = fun({_,PlayerGuildDun1}) -> PlayerGuildDun1#player_guild_dun.in_dun=:=1 end,
				PlayerGuildDunList2 = lists:filter(F1, PlayerGuildDunList),	
%%				InjureMax = data_guild_dun:get_dun1_injure_config(GuildDun2#guild_dun.active_num),
				InjureMax = 1,
				F2 = fun({_,PlayerGuildDun2}) ->
						PlayerDun = PlayerGuildDun2#player_guild_dun.player_dun_1,
						TrapNum = PlayerDun#player_dun_1.trap_num,
						{ok, BinData} = pt_405:write(40511, [EndTime2, ActiveNum, ActiveNum-DieNum, TrapNum, InjureMax]),	
						lib_player:update_player_info(PlayerGuildDun2#player_guild_dun.id, [{unite_to_server, BinData}])
				end,
				lists:foreach(F2, PlayerGuildDunList2);
			false ->
				PlayerGuildDun = dict:find(PlayerId, AllPlayerGuildDun),	
				InjureMax = data_guild_dun:get_dun1_injure_config(GuildDun2#guild_dun.active_num),
				case PlayerGuildDun=/=error of	
				true ->
					{ok,PlayerGuildDun0}=PlayerGuildDun, 
					PlayerDun = PlayerGuildDun0#player_guild_dun.player_dun_1,
					TrapNum = PlayerDun#player_dun_1.trap_num,
					{ok, BinData} = pt_405:write(40511, [EndTime2, ActiveNum, ActiveNum-DieNum, TrapNum, InjureMax]),	
					lib_player:update_player_info(PlayerGuildDun0#player_guild_dun.id, [{unite_to_server, BinData}]);
				false -> skip
				end
		end;
		2 ->
		%% 关卡1信息: 倒计时、参与人数，存活人数
		ActiveNum = GuildDun2#guild_dun.active_num,
		DieNum = GuildDun2#guild_dun.die_num,
		EndTime = GuildDun2#guild_dun.end_time,
		case EndTime> NowTime of
			true -> EndTime2 = EndTime-NowTime;
			false -> EndTime2 =0
		end,
		PlayerGuildDunList = dict:to_list(AllPlayerGuildDun),				
		F1 = fun({_,PlayerGuildDun1}) -> PlayerGuildDun1#player_guild_dun.in_dun=:=1 end,
		PlayerGuildDunList2 = lists:filter(F1, PlayerGuildDunList),	
		F2 = fun({_,PlayerGuildDun2}) ->
				{ok, BinData} = pt_405:write(40516, [EndTime2, ActiveNum, ActiveNum-DieNum]),	
				lib_player:update_player_info(PlayerGuildDun2#player_guild_dun.id, [{unite_to_server, BinData}])
		end,
		lists:foreach(F2, PlayerGuildDunList2);
		3 ->
		%% 关卡1信息: 倒计时、参与人数，存活人数，答对题数
		Dun3 = GuildDun2#guild_dun.dun3,
		ActiveNum = GuildDun2#guild_dun.active_num,
		DieNum = GuildDun2#guild_dun.die_num,
		EndTime =Dun3#sys_guild_dun3.end_time,						
		case EndTime> NowTime of
			true -> EndTime2 = EndTime-NowTime;
			false -> EndTime2 =0
		end,
		case PlayerId=:=0 of
			true ->
				PlayerGuildDunList = dict:to_list(AllPlayerGuildDun),				
				F1 = fun({_,PlayerGuildDun1}) -> PlayerGuildDun1#player_guild_dun.in_dun=:=1 end,
				PlayerGuildDunList2 = lists:filter(F1, PlayerGuildDunList),	
				F2 = fun({_,PlayerGuildDun2}) ->
						PlayerDun = PlayerGuildDun2#player_guild_dun.player_dun_3,
						CorrectNum = PlayerDun#player_dun_3.correct_num,
						{ok, BinData} = pt_405:write(40508, [EndTime2, ActiveNum, ActiveNum-DieNum, CorrectNum]),	
						lib_player:update_player_info(PlayerGuildDun2#player_guild_dun.id, [{unite_to_server, BinData}])
				end,
				lists:foreach(F2, PlayerGuildDunList2);
			false ->
				PlayerGuildDun = dict:find(PlayerId, AllPlayerGuildDun),	
				case PlayerGuildDun=/=error of	
				true ->
					{ok,PlayerGuildDun0}=PlayerGuildDun, 
					PlayerDun = PlayerGuildDun0#player_guild_dun.player_dun_3,
					CorrectNum = PlayerDun#player_dun_3.correct_num,
					{ok, BinData} = pt_405:write(40508, [EndTime2, ActiveNum, ActiveNum-DieNum, CorrectNum]),	
					lib_player:update_player_info(PlayerGuildDun0#player_guild_dun.id, [{unite_to_server, BinData}]);
				false -> skip
				end
		end;
		_ -> skip
		end;
	false ->
		skip
	end.


%% 获取PlayerId、GuildId
get_id_player_guild(PS) ->
	PlayerId = PS#player_status.id,
	PlayerGuild = PS#player_status.guild,
	GuildId = PlayerGuild#status_guild.guild_id, 
	[PlayerId, GuildId].



