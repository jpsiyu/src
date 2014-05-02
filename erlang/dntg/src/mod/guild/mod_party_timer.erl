%% --------------------------------------------------------
%% @Module:           |mod_party_timer
%% @Author:           |wzh
%% @Email:            |45517168@qq.com
%% @Created:          |2012-00-00
%% @Description:      |帮派宴会_进行中管理 
%% --------------------------------------------------------
-module(mod_party_timer).
-behaviour(gen_fsm).
-export([start_party/2, waiting/2]).
-export([start_link/1, init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).
-include("common.hrl").
-include("guild.hrl").
-include("sql_guild.hrl").

-define(TIMEOUT_PARTY, 5000). 	 	 %% 检查周期	1/1000	秒为单位
-define(WAIT_PARTY, 5 * 60 * 1000).  %% 检查周期	1/1000	秒为单位
-define(PARTY_P, 100). 		 	 %% 宴会准备时间_以	1/1000	秒为单位

-define(PARTY_FOOD_TIME, 60).		 %% 食物刷新时间		1		秒为单位
-define(PARTY_EXP_TIME, 30). 		 %% 经验刷新时间		1		秒为单位
-define(PARTY_LAST, 15* 60). 	 %% 宴会持续时间_以	1		秒为单位
%% 设定宴会_Record
-record(party_status, {guild_id = 0		 	 					%% 帮派ID
					   , guild_name = 0		 	 					%% 帮派名字
					   , sponsor_id = 0	 	 							%% 主办者ID
					   , sponsor_name = []	 	 					    %% 主办者名字
					   , sponsor_image = 0	 	 						%% 主办者头像
					   , sponsor_sex = 0	 	 						%% 主办者性别
					   , sponsor_voc = 0	 	 						%% 主办者职业					
					   , party_type = 0	 	 							%% 宴会类型
					   , start_party_at = 0	 	 						%% 宴会开始时间
					   , stop_party_at = 0	 	 						%% 宴会结束时间
					   , party_food_time = 0	 	 					%% 宴会生成食物时间
					   , party_exp_mood_time = 0	 	 				%% 宴会经验和气氛刷新
					   , mood_info = 0	 	 							%% 宴会气氛值
					   , girl_1 = 0	 	 								%% 美女
					   , girl_2 = 0	 	 								%% 美女
					   , girl_3 = 0	 	 								%% 美女
					   , girl_4 = 0	 	 								%% 美女
					   , girl_5 = 0	 	 								%% 美女
					   , girl_6 = 0	 	 								%% 美女
					   , girl_num = 0	 	 							%% 美女数量
					   , goods_event 	 								%% 宴会物品使用记录
					   , party_event 	 								%% 宴会事件_dict
					   , is_send = 0 									%% 传闻事件
					   , upgrader = []                                  %% 升级玩家
					   }).

start_link([Start_After_Time, [GuildId, GuildName, Sponsor_Id, Sponsor_Name, Sponsor_image, Sponsor_sex, Sponsor_voc, PartyType, Db_flag]]) ->
    Result = gen_fsm:start({global,?GUILD_PARTYL ++ integer_to_list(GuildId)}
					  , ?MODULE
					  , [Start_After_Time, [GuildId, GuildName, Sponsor_Id, Sponsor_Name, Sponsor_image, Sponsor_sex, Sponsor_voc, PartyType]]
					  , []),
	case Result of
		{ok, _} ->
			if
				Db_flag =:= 0 ->
					%% 记录预约 db:
					NowTime  = util:unixtime(),
					Booking_time = NowTime+Start_After_Time,
					F = fun() ->
							Sql1 = io_lib:format(?SQL_GUILD_PARTY_START, [GuildId, GuildName, Sponsor_Id,  Sponsor_Name, Sponsor_image, Sponsor_sex, Sponsor_voc, PartyType, Booking_time]),
							Sql2 = io_lib:format(?SQL_GUILD_PARTY_START_NOCLEAR, [GuildId, GuildName, Sponsor_Id,  Sponsor_Name, Sponsor_image, Sponsor_sex, Sponsor_voc, PartyType, Booking_time]),					
							db:execute(Sql1),
							db:execute(Sql2)
						end,
					db:transaction(F);					
				true ->
					skip
			end;
		_ -> skip
	end.

init([Start_After_Time, [GuildId, GuildName, Sponsor_Id, Sponsor_Name, Sponsor_image, Sponsor_sex, Sponsor_voc, PartyType]])->
	NowTime  = util:unixtime(),
	Party_Event = dict:new(),
	Goods_Event = dict:new(),
    Status = #party_status{guild_id = GuildId
						   , guild_name = GuildName
						   , sponsor_id = Sponsor_Id
						   , sponsor_name = Sponsor_Name
						   , sponsor_image = Sponsor_image
						   , sponsor_sex = Sponsor_sex
						   , sponsor_voc = Sponsor_voc						  
						   , party_type = PartyType
						   , start_party_at = NowTime + Start_After_Time
						   , stop_party_at = NowTime + Start_After_Time + ?PARTY_LAST
						   , party_food_time = 0
						   , party_exp_mood_time = 0
						   , goods_event = Goods_Event
						   , party_event = Party_Event},
	
%% 	io:format("1 ~p ~n", [Start_After_Time]),
    {ok, start_party, Status, Start_After_Time * 1000}.


%% --------------------------------------------------------------------------
%% 宴会开始前处理 
%% --------------------------------------------------------------------------
start_party(timeout, Status) ->
	NowTime  = util:unixtime(),
	case NowTime + 10 > Status#party_status.start_party_at of
		true ->
			NewStatus = Status#party_status{stop_party_at = NowTime + ?PARTY_LAST
											, party_food_time = NowTime - 30
										    , party_exp_mood_time = NowTime},
			case start_party_handle(NewStatus) of
				1 ->
					open_guild_event(NewStatus, 0),
					%% 玩家已经在帮宴场景中，添加气氛值
					SceneUser = lib_scene:get_scene_user_field(?GUILD_SCENE, Status#party_status.guild_id, id),
					{MoodAdd, _NumLimit, _EfType} = data_guild:get_party_good_ef(0),
				 	NewStatus2 = add_mood(5, 0, 0, "none", length(SceneUser)*MoodAdd, 0, NewStatus),
					creat_food(NewStatus2, 0),
                    %% 清除预约记录
					Sql = io_lib:format(?SQL_GUILD_PARTY_DELETE, [Status#party_status.guild_id]),
					db:execute(Sql),
					{next_state, waiting, NewStatus2, ?PARTY_P};
				_ ->
					{stop, normal, NewStatus}
			end;
		false ->
			TimeLeft = Status#party_status.start_party_at - NowTime,
%% 			io:format("1 ~p ~p ~n", [1, TimeLeft]),
			{next_state, start_party, Status, TimeLeft * 1000}
	end.
%% --------------------------------------------------------------------------
%% 宴会中处理 
%% --------------------------------------------------------------------------
waiting(timeout, Status) ->
%% 	io:format("2 ~p ~p ~n", [1, 1]),
	NowTime  = util:unixtime(),
	case NowTime > Status#party_status.start_party_at of
		true ->
			case (Status#party_status.stop_party_at - NowTime) >= 0 of
				true ->
					%%　宴会进行中
					New_Exp_Time = case (NowTime - Status#party_status.party_exp_mood_time) >= ?PARTY_EXP_TIME of
						true ->
							send_guild_event(Status, 3),
							send_girl(Status),
							NowTime;
						false ->
							Status#party_status.party_exp_mood_time
					end,
					Refresh_Status = Status#party_status{party_exp_mood_time = New_Exp_Time},
					{next_state, waiting, Refresh_Status, ?TIMEOUT_PARTY};
				_ ->
					{stop, normal, Status}
			end;
		false ->
			{next_state, waiting, Status, ?WAIT_PARTY}
	end.


handle_event(_Event, StateName, Status) ->
    {next_state, StateName, Status}.

%% 增加宴会气氛值
handle_sync_event({get_now_State}, _From, StateName, Status) ->
	NowTime  = util:unixtime(),
	Info = case NowTime > Status#party_status.start_party_at of
			   true ->
				   {ok, StateName};
			   false ->
				   0
		   end,
    {reply, Info, StateName, Status, 0};

%% 增加宴会气氛值
handle_sync_event({add_mood, Type, Uid, Lv, Name, MoodAdd, GoodTypeId}, _From, StateName, Status) ->
	StatusNew = add_mood(Type, Uid, Lv, Name, MoodAdd, GoodTypeId, Status),
	StatusNew2 = case StatusNew#party_status.mood_info >= 1000 andalso StatusNew#party_status.is_send =:= 0 of
		false ->
			StatusNew;
		true->
			lib_chat:send_TV({all},0, 2, [xianyan, 2, [Status#party_status.guild_name], Status#party_status.party_type]),
			StatusNew#party_status{is_send = 1}
	end,
    {reply, ok, StateName, StatusNew2, 0};

%% 获取宴会开始时间
handle_sync_event(get_start_time, _From, StateName, Status) ->
    {reply, Status#party_status.start_party_at, StateName, Status, 0};

%% 获取宴会气氛值
handle_sync_event(get_mood, _From, StateName, Status) ->
    {reply, Status#party_status.mood_info, StateName, Status, 0};

%% 获取宴会物品使用数量
handle_sync_event({get_goods_use, GoodsTypeId}, _From, StateName, Status) ->
	Info = get_goods_use(GoodsTypeId, Status),
    {reply, Info, StateName, Status, 0};

%% 获取宴会类型
handle_sync_event(get_party_type, _From, StateName, Status) ->
    {reply, Status#party_status.party_type, StateName, Status, 0};

%% 宴会添加刷新美女
handle_sync_event({start_refresh_girl, GirlType}, _From, StateName, Status) ->
	NewStatus = start_refresh_girl(GirlType, Status),
    {reply, ok, StateName, NewStatus, 0};

%% 帮宴期间进入场景
handle_sync_event({enter_scene, PlayerId}, _From, StateName, Status) ->
	NowTime = util:unixtime(),
	%%EXPA1 = case Status#party_status.party_type of
	%%	1->16;
	%%	2->32;
	%%	3->48
	%%end,
	Mood = Status#party_status.mood_info,
	%%ExpAdd = round(EXPA1 * Mood * 0.002625 / 10),
	Info1 = erlang:integer_to_list(0),
	Users_Here = lib_scene:get_scene_user_field(?GUILD_SCENE, Status#party_status.guild_id, pid),
	JoinNum = length(Users_Here),
	%% 累积经验、历练
	case get(guild_party_exp) of
		undefined ->
			All_Exp =0;
         Exp ->
			All_Exp =Exp 
	end,
	case get(guild_party_llpt) of
		undefined ->
			All_Llpt =0;
         Llpt ->
			All_Llpt =Llpt
	end,
	{ok, BinData} = pt_401:write(40108, [Status#party_status.stop_party_at - NowTime, Mood, 0,
						[Info1], JoinNum], All_Exp, All_Llpt,Status#party_status.upgrader, Status#party_status.party_type),
	lib_server_send:send_to_uid(PlayerId, BinData),
    {reply, ok, StateName, Status, 0};

%% 升级帮宴类型 
handle_sync_event({upgrade_guild_party, Uid, UName}, _From, StateName, Status) ->
	Type1 = Status#party_status.party_type,
	case Type1<3 of
		true -> Type2 = Type1+1;
		false -> Type2 = Type1
	end,
	NewStatus = Status#party_status{party_type = Type2, sponsor_id = Uid, upgrader = UName},
	creat_food(NewStatus, Type1),
	send_guild_event(NewStatus, 8),
    {reply, ok, StateName, NewStatus, 0};

%% 关闭
handle_sync_event(stop, _From, _StateName, Status) ->
    {stop, normal, Status};

%% 错误
handle_sync_event(_Event, _From, StateName, Status) ->
    {reply, ok, StateName, Status, 0}.


%% 发送宴会_过程通知
handle_info({send_guild_event, NewEvent}, StateName, Status) ->
	Event_List = Status#party_status.party_event,
	New_Status = Status#party_status{party_event = [NewEvent|Event_List]},
	send_guild_event(New_Status, 1),
    {next_state, StateName, New_Status, 0};
%%中断服务
handle_info(stop, _StateName, Status) ->
    {stop, normal, Status};
handle_info(_Info, StateName, Status) ->
    {next_state, StateName, Status}.

terminate(_Reason, _StateName, Status) ->
	terminate_handle(Status),
    ok.

code_change(_OldVsn, StateName, Status, _Extra) ->
    {ok, StateName, Status}.


%% 增加气氛值
add_mood(Type, Uid, Lv, Name, MoodAdd, GoodTypeId, Status) ->
	NewGoodsEvent = case dict:find(GoodTypeId, Status#party_status.goods_event) of
		error ->
			dict:store(GoodTypeId, 1, Status#party_status.goods_event);
		{ok, Value} ->
			dict:store(GoodTypeId, Value + 1, Status#party_status.goods_event)
	end,
	NewMood = case Status#party_status.mood_info + MoodAdd >= 1000 of
				  true ->
					  1000;
				  false ->
					  MoodAdd2 = Status#party_status.mood_info + MoodAdd,
					  case MoodAdd2 < 0 of
						  true -> 0;
						  false -> MoodAdd2
					  end					  
			  end,
	NowTime = util:unixtime(),
	Info1 = erlang:integer_to_list(MoodAdd),
	Info2 = erlang:integer_to_list(GoodTypeId),
	{InfoType, Uid, Lv, Info} = {Type, Uid, Lv, [Name, ?SEPARATOR_STRING, Info1, ?SEPARATOR_STRING, Info2]},
	lib_guild_scene:get_guild_party_refresh([Status#party_status.guild_id
											, Status#party_status.stop_party_at - NowTime 
										 	, NewMood
										 	, InfoType, Uid, Lv, Info
											, Status#party_status.party_type
											, Status#party_status.upgrader]),
	Status#party_status{mood_info = NewMood, goods_event = NewGoodsEvent}.

%% 使用物品
get_goods_use(GoodsTypeId, Status) ->
	case dict:find(GoodsTypeId, Status#party_status.goods_event) of
		error ->
			0;
		{ok, Value} ->
			Value
	end.

%% 开始刷新侍女
start_refresh_girl(_GirlType, Status) ->
	case Status#party_status.girl_num of
		0 ->
			NewNum = 1,
			Status#party_status{girl_1 = 1, girl_num = NewNum};
		1 ->
			NewNum = 2,
			Status#party_status{girl_2 = 2, girl_num = NewNum};
		2 ->
			NewNum = 3,
			Status#party_status{girl_3 = 3, girl_num = NewNum};
		3 ->
			NewNum = 4,
			Status#party_status{girl_4 = 4, girl_num = NewNum};
		4 ->
			NewNum = 5,
			Status#party_status{girl_5 = 5, girl_num = NewNum};
		5 ->
			NewNum = 6,
			Status#party_status{girl_6 = 6, girl_num = NewNum};
		_ ->
			skip
	end.

%% 发送美女
send_girl(Status) ->
    GuildId = Status#party_status.guild_id,
	case Status#party_status.girl_1 of
		0 ->
			skip;
		_R1 ->
			{ok, BinData1} = pt_401:write(40115, [_R1]),
			lib_server_send:send_to_scene(?GUILD_SCENE, GuildId, BinData1)
	end,
	case Status#party_status.girl_2 of
		0 ->
			skip;
		_R2 ->
			{ok, BinData2} = pt_401:write(40115, [_R2]),
			lib_server_send:send_to_scene(?GUILD_SCENE, GuildId, BinData2)
	end,
	case Status#party_status.girl_3 of
		0 ->
			skip;
		_R3 ->
			{ok, BinData3} = pt_401:write(40115, [_R3]),
			lib_server_send:send_to_scene(?GUILD_SCENE, GuildId, BinData3)
	end,
	case Status#party_status.girl_4 of
		0 ->
			skip;
		_R4 ->
			{ok, BinData4} = pt_401:write(40115, [_R4]),
			lib_server_send:send_to_scene(?GUILD_SCENE, GuildId, BinData4)
	end,
	case Status#party_status.girl_5 of
		0 ->
			skip;
		_R5 ->
			{ok, BinData5} = pt_401:write(40115, [_R5]),
			lib_server_send:send_to_scene(?GUILD_SCENE, GuildId, BinData5)
	end,
	case Status#party_status.girl_6 of
		0 ->
			skip;
		_R6 ->
			{ok, BinData6} = pt_401:write(40115, [_R6]),
			lib_server_send:send_to_scene(?GUILD_SCENE, GuildId, BinData6)
	end.

%% --------------------------------------------------------------------------
%% 内部函数
%% --------------------------------------------------------------------------

start_party_handle(Status) ->
	%% 开始宴会
	lib_guild_scene:guild_party_starting([Status#party_status.guild_id
										  , Status#party_status.sponsor_id
										  , Status#party_status.sponsor_name
										  , Status#party_status.party_type
										  , Status#party_status.start_party_at]),
	1.
%% 发送帮派宴会事件
open_guild_event(Status, _Send_Type) ->
	NowTime = util:unixtime(),
	%%EXPA1 = case Status#party_status.party_type of
	%%	1->16;
	%%	2->32;
	%%	3->48
	%%end,
	Mood = Status#party_status.mood_info,
	%%　ExpAdd = round(EXPA1 * Mood * 0.002625 / 10),
	Info1 = erlang:integer_to_list(0),
	Users_Here = lib_scene:get_scene_user_field(?GUILD_SCENE, Status#party_status.guild_id, pid),
	JoinNum = length(Users_Here),
	%% 累积经验、历练
	case get(guild_party_exp) of
		undefined ->
			All_Exp =0;
         Exp ->
			All_Exp =Exp 
	end,
	case get(guild_party_llpt) of
		undefined ->
			All_Llpt =0;
         Llpt ->
			All_Llpt =Llpt
	end,
	{ok, BinData} = pt_401:write(40108, [Status#party_status.stop_party_at - NowTime, Mood,
			0, [Info1], JoinNum, All_Exp, All_Llpt,Status#party_status.upgrader, Status#party_status.party_type]),
	lib_server_send:send_to_scene(?GUILD_SCENE, Status#party_status.guild_id, BinData).
	

%% 发送帮派宴会事件
send_guild_event(Status, Send_Type) ->
	NowTime = util:unixtime(),
	{InfoType, Info} = case Send_Type of
						   0 ->
							   {0, []};
						   1 ->
							   Event_List = Status#party_status.party_event,
							   [H|_] = Event_List,
							   H;
						   3 ->
							   {3, []};
						   8 ->
							   {8, []}
					   end,
	lib_guild_scene:get_guild_party_refresh([Status#party_status.guild_id
											, Status#party_status.stop_party_at - NowTime 
										 	, Status#party_status.mood_info
										 	, InfoType, 0, 0, Info
											, Status#party_status.party_type
											, Status#party_status.upgrader]).

creat_food(Status, _Type) ->
	case _Type=:=0 of
		true ->
		 	Type = Status#party_status.party_type;
		false ->
			Type = _Type
	end,
 	%% 清除没吃完的食物
 	lib_guild_scene:clear_food(Status#party_status.guild_id, Type),
	%% 生成食物
	lib_guild_scene:guild_party_food_creater([Status#party_status.guild_id
										  , Status#party_status.sponsor_id
										  , Status#party_status.sponsor_name
										  , Status#party_status.party_type
										  , Status#party_status.start_party_at]).						
							  
terminate_handle(Status) ->
	%% 清除食物
	lib_guild_scene:clear_food(Status#party_status.guild_id, Status#party_status.party_type),
	lib_guild_scene:guild_party_over([Status#party_status.guild_id
									 , Status#party_status.party_type
									 , Status#party_status.sponsor_id
									 ]).










