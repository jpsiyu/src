%%% -------------------------------------------------------------------
%%% Author  : zengzhaoyuan
%%% Description :
%%%
%%% Created : 2012-5-22
%%% -------------------------------------------------------------------
-module(mod_arena_new).
-behaviour(gen_server).
-include("arena_new.hrl").
-include("server.hrl").
-include("unite.hrl").
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([set_time/5,
		 set_status/1,
		 set_score/4,
		 stop_continuous_kill_by_numen_kill/2,
		 open_arena/0,
		 call_boss/1,
		 goin_room/1,
		 score_list/1,
         change_boss_award/2,
         update_anger/1,
         add_anger_timer/0,
		 end_arena/4]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

-record(state, {
				arena_stauts=0,  %竞技场状态 0还未开启 1开启中 2当天已结束
				config_begin_hour=0,
				config_begin_minute=0,
				config_end_hour=0,
				config_end_minute=0,
				boss_time = [],
				arena_player_lv_dict = dict:new(), %%Key:玩家ID--Value:当时玩家等级
				arena_room_1_max_id=0, 	%低级场自增长ID
				arena_room_2_max_id=0,	%中级场自增长ID
				arena_room_3_max_id=0,	%高级场自增长ID
				arena_room_1_dict = dict:new(),
				arena_room_2_dict = dict:new(),
				arena_room_3_dict = dict:new(),
				arena_1_dict = dict:new(),
				arena_2_dict = dict:new(),
				arena_3_dict = dict:new()
}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

%% ====================================================================
%% Server functions
%% ====================================================================

%%设置竞技场时间(不方法不可随便调用，会重置所有属性，很危险)
set_time(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute,Boss_time)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_time,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, Boss_time}).

%%设置状态
%%@param Arena_Status 竞技场状态 0还未开启 1开启中 2当天已结束
set_status(Arena_Status)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_status,Arena_Status}).

%%玩家积分处理
%%@param Type 原子值,player|npc
%%@param Uid 谁杀的玩家ID
%%@param KilledTypeId 被杀类型ID(player时，取玩家ID值，npc时，取其类型ID)
%%@param HitList 助攻列表
set_score(Type,Uid,KilledUidOrNPCTypeId, HitList)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_score,Type,Uid,KilledUidOrNPCTypeId,HitList}).

%%终止玩家连斩数，因为被NPC守护神击杀
%%@param NPCTypeId 守护神类型ID
%%@param KilledPlayerId 玩家ID
stop_continuous_kill_by_numen_kill(NPCTypeId,KilledPlayerId)->
	gen_server:cast(misc:get_global_pid(?MODULE),{stop_continuous_kill_by_numen_kill,NPCTypeId,KilledPlayerId}).

%%开启竞技场
open_arena()->
	gen_server:cast(misc:get_global_pid(?MODULE),{open_arena}).

%%定时召唤宝箱
call_boss(Boss_turn)->
	gen_server:cast(misc:get_global_pid(?MODULE),{call_boss, Boss_turn}).

%% 48001协议
execute_48001(UniteStatus, Exp_multiple) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {execute_48001, UniteStatus, Exp_multiple}).


%%进入房间
%%@param PlayerId 玩家ID
%%@param RoomLv 房间等级
%%@param RoomId 房间号
%%@return {Result,RoomLv,RoomId,Realm,RemainTime}
goin_room(UniteStatus)->
	gen_server:cast(misc:get_global_pid(?MODULE),{goin_room,UniteStatus}).

%%竞技场积分榜
%%@param PlayerId 玩家ID
%%@return 
%% {error,1} 未有玩家等级记录
%% {error,2} 对应房间段未有玩家竞技场记录
%% {ok,{Score,Continuous_kill,Anger,Top5List}} Top5List->[Arena]
score_list(PlayerId)->
	gen_server:cast(misc:get_global_pid(?MODULE),{score_list,PlayerId}).

%% 玩家离开竞技场
leave_room(UniteStatus) ->
	gen_server:cast(misc:get_global_pid(?MODULE),{leave_room,UniteStatus}).

%%竞技场结束时处理逻辑
end_arena(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute)->
	gen_server:cast(misc:get_global_pid(?MODULE),{end_arena,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute}).

%%改变boss的奖励归属
change_boss_award(CopyId, Mid) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{change_boss_award, CopyId, Mid}).

%% 更新玩家怒气值
update_anger(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {update_anger, PlayerId}).

%% 定时更新玩家怒气值
add_anger_timer() ->
    gen_server:cast(misc:get_global_pid(?MODULE), {add_anger_timer}).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% 玩家离开竞技场
handle_cast({leave_room,UniteStatus}, State) ->
	%检测玩家是否第一次访问，并记录玩家第一次访问等级。防跳级依据。
    PlayerId = UniteStatus#unite_status.id,
	Arena_player_lv_dict = State#state.arena_player_lv_dict,
	case dict:is_key(PlayerId, Arena_player_lv_dict) of
		false-> %无记录，当天第一次请求
			HaveRecord = 0;
		true-> %有记录，当天已看过房间列表
			HaveRecord = 1
	end,
	case HaveRecord of
		0->
            Reply = {error,1},
            NewState = State;
		1->
			[Arena_player_lv] = dict:fetch(PlayerId, Arena_player_lv_dict),
			RoomLv = data_arena_new:get_room_lv(Arena_player_lv#arena_player_lv.lv),
			case RoomLv of
				1->
					Arena_dict = State#state.arena_1_dict;
				2->
					Arena_dict = State#state.arena_2_dict;
				3->
					Arena_dict = State#state.arena_3_dict
			end,
			case dict:is_key(PlayerId, Arena_dict) of
				false->
					Reply = {error,2},
                    NewState = State;
				true->
					%玩家竞技记录
					[Arena] = dict:fetch(PlayerId, Arena_dict),
					NewArena = Arena#arena{is_leave = 1},
					Temp_Arena_dict = dict:erase(PlayerId, Arena_dict),
					New_Arena_dict = dict:append(PlayerId, NewArena, Temp_Arena_dict),
                    Reply = {ok, NewArena#arena.pk_status},
					case RoomLv of
						1 ->
							NewState = State#state{arena_1_dict = New_Arena_dict};
						2 ->
							NewState = State#state{arena_2_dict = New_Arena_dict};
						3->
							NewState = State#state{arena_3_dict = New_Arena_dict}
					end 
			end
	end,
    case Reply of 
        {error, _ErrorCode} ->
            lib_player:change_pk_status(UniteStatus#unite_status.id, 2);
        {ok, PkStatus} ->
            lib_player:change_pk_status(UniteStatus#unite_status.id, PkStatus)
    end,
    [SceneId, X, Y] = data_arena_new:get_arena_config(leave_scene),
    lib_scene:player_change_scene_queue(UniteStatus#unite_status.id, SceneId, 0, X, Y, [{group, 0}]),
    {ok, BinData} = pt_480:write(48009, [1]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    {noreply, NewState};


handle_cast({stop_continuous_kill_by_numen_kill,NPCTypeId,KilledPlayerId}, State) ->
	NpcTypeIdList = data_arena_new:get_npc_type_id(),
	case lists:member(NPCTypeId, NpcTypeIdList) of
		false->
            {noreply, State};
		true->
			%检测玩家是否第一次访问，并记录玩家第一次访问等级。防跳级依据。
			Arena_player_lv_dict = State#state.arena_player_lv_dict,
			case dict:is_key(KilledPlayerId, Arena_player_lv_dict) of
				false-> %无记录，当天第一次请求
					HaveRecord = 0;
				true-> %有记录，当天已看过房间列表
					HaveRecord = 1
			end,
			case HaveRecord of
				0->
                    {noreply, State};
				1->
					[Arena_player_lv] = dict:fetch(KilledPlayerId, Arena_player_lv_dict),
					RoomLv = data_arena_new:get_room_lv(Arena_player_lv#arena_player_lv.lv),
					case RoomLv of
						1->
							Arena_dict = State#state.arena_1_dict;
						2->
							Arena_dict = State#state.arena_2_dict;
						3->
							Arena_dict = State#state.arena_3_dict
					end,
					case dict:is_key(KilledPlayerId, Arena_dict) of
						false->
                            {noreply, State};%无玩家记录
						true->
							%玩家竞技记录
							[Arena] = dict:fetch(KilledPlayerId, Arena_dict),
							NewArena = Arena#arena{continuous_kill=0},
							Temp_Arena_dict = dict:erase(KilledPlayerId,Arena_dict),
							New_Arena_dict = dict:append(KilledPlayerId,NewArena,Temp_Arena_dict),
							case RoomLv of
								1->
									{noreply, State#state{
										arena_1_dict = New_Arena_dict
									}};
								2->
									{noreply, State#state{
										arena_2_dict = New_Arena_dict
									}};
								3->
									{noreply, State#state{
										arena_3_dict = New_Arena_dict
									}}
							end
					end
			end
	end;


%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%% 48001协议
handle_cast({execute_48001, UniteStatus, Exp_multiple}, State) ->
    ArenaStatus = State#state.arena_stauts,
    {ok, BinData} = pt_480:write(48001, [ArenaStatus, Exp_multiple]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    {noreply, State};

handle_cast({goin_room,UniteStatus}, State) ->
    %% 检查时间和等级,发送48000错误码
    ApplyLevel =  data_arena_new:get_arena_config(apply_level),
    if 
        State#state.arena_stauts =/= 1 ->
            {ok, BinData} = pt_480:write(48000, [1]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            New_State3 = State;
        UniteStatus#unite_status.lv < ApplyLevel ->
            {ok, BinData} = pt_480:write(48000, [2]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            New_State3 = State;
        true ->
            PlayerId = UniteStatus#unite_status.id, 
            Pid      = UniteStatus#unite_status.pid,
            NickName = UniteStatus#unite_status.name,
            Country  = UniteStatus#unite_status.realm,
            Sex      = UniteStatus#unite_status.sex,
            Career   = UniteStatus#unite_status.career,
            Image    = UniteStatus#unite_status.image,
            PlayerLv = UniteStatus#unite_status.lv,
           %检测玩家是否第一次访问，并记录玩家第一次访问等级。防跳级依据。
            Arena_player_lv_dict = State#state.arena_player_lv_dict,
            case dict:is_key(PlayerId, Arena_player_lv_dict) of
                false-> %无记录，当天第一次请求
                    New_Arena_player_lv = #arena_player_lv{id=PlayerId,lv=PlayerLv},
                    New_Arena_player_lv_dict = dict:append(PlayerId,New_Arena_player_lv,Arena_player_lv_dict);
                true-> %有记录，当天已看过房间列表
                    [New_Arena_player_lv] = dict:fetch(PlayerId, Arena_player_lv_dict),
                    New_Arena_player_lv_dict = Arena_player_lv_dict
            end,
            New_State1=State#state{arena_player_lv_dict=New_Arena_player_lv_dict},
            %计算玩家对应房间等级，给出房间列表
            RoomLv = data_arena_new:get_room_lv(New_Arena_player_lv#arena_player_lv.lv),
            Scene_id = data_arena_new:get_arena_config(scene_id),
            Numen_born = data_arena_new:get_arena_config(numen_born),
            %% 每方有三个守护神
            [{Numen_position_x1,Numen_position_y1},{Numen_position_x2,Numen_position_y2},{Numen_position_x3,Numen_position_y3}] = lists:nth(1, Numen_born),
            [{Numen_position_x4,Numen_position_y4},{Numen_position_x5,Numen_position_y5},{Numen_position_x6,Numen_position_y6}] = lists:nth(2, Numen_born),
            Numer_id = data_arena_new:get_arena_config(numer_id),
            %% 按世界等级创建boss
            WorldLv = lib_player:world_lv(1),
            case RoomLv of
                1->
                    Arena_room_1_dict = New_State1#state.arena_room_1_dict,
                    Temp_RoomList = dict:to_list(Arena_room_1_dict),
                    case Temp_RoomList of
                        []-> 
                            New_Arena_room_1_max_id = New_State1#state.arena_room_1_max_id+1,
                            New_Arena_room_1_dict = dict:append(New_Arena_room_1_max_id,
                                                        #arena_room{
                                                            room_lv=1, %房间类型
                                                            id=New_Arena_room_1_max_id  %房间ID
                                                        },
                                                        New_State1#state.arena_room_1_dict),
                            CopyId = integer_to_list(1) ++ "_" ++ integer_to_list(New_Arena_room_1_max_id),
                            %% 每方三个守护神 1,2,3为天庭的，4,5,6为鬼域的
                            {Numer_id1,Numer_id2,Numer_id3,Numer_id4,Numer_id5, Numer_id6} = lists:nth(1, Numer_id),
                            lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [Numer_id1,Numer_id2, Numer_id3, Numer_id4, Numer_id5, Numer_id6]),
                            %% 创建天庭守护神
                            lib_mon:async_create_mon(Numer_id1, Scene_id, Numen_position_x1, Numen_position_y1, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id2, Scene_id, Numen_position_x2, Numen_position_y2, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id3, Scene_id, Numen_position_x3, Numen_position_y3, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                            %% 创建鬼域守护神
                            lib_mon:async_create_mon(Numer_id4, Scene_id, Numen_position_x4, Numen_position_y4, 1, CopyId, 0, [{group, 2}, {auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id5, Scene_id, Numen_position_x5, Numen_position_y5, 1, CopyId, 0, [{group, 2}, {auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id6, Scene_id, Numen_position_x6, Numen_position_y6, 1, CopyId, 0, [{group, 2}, {auto_lv, WorldLv}]);
                    
                        _->
                            Room_new_num = data_arena_new:get_arena_config(room_new_num),
                            Can_Add_RoomList = [L||{_,[L]}<-Temp_RoomList,L#arena_room.num<Room_new_num],
                            case Can_Add_RoomList of
                                []-> %无低于约定人数的房间，新建一个房间
                                    New_Arena_room_1_max_id = New_State1#state.arena_room_1_max_id+1,
                                    New_Arena_room_1_dict = dict:append(New_Arena_room_1_max_id,
                                                                #arena_room{
                                                                    room_lv=1, %房间类型
                                                                    id=New_Arena_room_1_max_id  %房间ID
                                                                },
                                                                New_State1#state.arena_room_1_dict),
                                    CopyId = integer_to_list(1) ++ "_" ++ integer_to_list(New_Arena_room_1_max_id),
                                    {Numer_id1,Numer_id2,Numer_id3,Numer_id4,Numer_id5, Numer_id6} = lists:nth(1, Numer_id),
                                    lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [Numer_id1,Numer_id2, Numer_id3, Numer_id4, Numer_id5, Numer_id6]),
                                    %% 创建天庭守护神
                                    lib_mon:async_create_mon(Numer_id1, Scene_id, Numen_position_x1, Numen_position_y1, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id2, Scene_id, Numen_position_x2, Numen_position_y2, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id3, Scene_id, Numen_position_x3, Numen_position_y3, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                                    %% 创建鬼域守护神
                                    lib_mon:async_create_mon(Numer_id4, Scene_id, Numen_position_x4, Numen_position_y4, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id5, Scene_id, Numen_position_x5, Numen_position_y5, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id6, Scene_id, Numen_position_x6, Numen_position_y6, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]);
                            
                                _-> %仍然有低于约定人数的房间
                                    New_Arena_room_1_max_id = New_State1#state.arena_room_1_max_id,
                                    New_Arena_room_1_dict = Arena_room_1_dict
                        
                            end
                    end,
                    New_State2 = New_State1#state{arena_room_1_max_id=New_Arena_room_1_max_id,
                                          arena_room_1_dict = New_Arena_room_1_dict};
                2->
                    Arena_room_2_dict = New_State1#state.arena_room_2_dict,
                    Temp_RoomList = dict:to_list(Arena_room_2_dict),
                    case Temp_RoomList of
                        []-> 
                            New_Arena_room_2_max_id = New_State1#state.arena_room_2_max_id+1,
                            New_Arena_room_2_dict = dict:append(New_Arena_room_2_max_id,
                                                        #arena_room{
                                                            room_lv=2, %房间类型
                                                            id=New_Arena_room_2_max_id  %房间ID
                                                        },
                                                        New_State1#state.arena_room_2_dict),
                            CopyId = integer_to_list(2) ++ "_" ++ integer_to_list(New_Arena_room_2_max_id),
                            {Numer_id1,Numer_id2,Numer_id3,Numer_id4,Numer_id5, Numer_id6} = lists:nth(2, Numer_id),
                            lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [Numer_id1,Numer_id2,Numer_id3,Numer_id4,Numer_id5, Numer_id6]),
                            %% 创建天庭守护神
                            lib_mon:async_create_mon(Numer_id1, Scene_id, Numen_position_x1, Numen_position_y1, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id2, Scene_id, Numen_position_x2, Numen_position_y2, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id3, Scene_id, Numen_position_x3, Numen_position_y3, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                            %% 创建鬼域守护神
                            lib_mon:async_create_mon(Numer_id4, Scene_id, Numen_position_x4, Numen_position_y4, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id5, Scene_id, Numen_position_x5, Numen_position_y5, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id6, Scene_id, Numen_position_x6, Numen_position_y6, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]);                 
                    
                        _->
                            Room_new_num = data_arena_new:get_arena_config(room_new_num),
                            Can_Add_RoomList = [L||{_,[L]}<-Temp_RoomList,L#arena_room.num<Room_new_num],
                            case Can_Add_RoomList of
                                []-> %无低于约定人数的房间，新建一个房间
                                    New_Arena_room_2_max_id = New_State1#state.arena_room_2_max_id+1,
                                    New_Arena_room_2_dict = dict:append(New_Arena_room_2_max_id,
                                                                #arena_room{
                                                                    room_lv=2, %房间类型
                                                                    id=New_Arena_room_2_max_id  %房间ID
                                                                },
                                                                New_State1#state.arena_room_2_dict),
                                    CopyId = integer_to_list(2) ++ "_" ++ integer_to_list(New_Arena_room_2_max_id),
                                    {Numer_id1,Numer_id2,Numer_id3,Numer_id4,Numer_id5, Numer_id6} = lists:nth(2, Numer_id),
                                    lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [Numer_id1,Numer_id2,Numer_id3,Numer_id4,Numer_id5, Numer_id6]),
                                    %% 创建天庭守护神
                                    lib_mon:async_create_mon(Numer_id1, Scene_id, Numen_position_x1, Numen_position_y1, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id2, Scene_id, Numen_position_x2, Numen_position_y2, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id3, Scene_id, Numen_position_x3, Numen_position_y3, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                                    %% 创建鬼域守护神
                                    lib_mon:async_create_mon(Numer_id4, Scene_id, Numen_position_x4, Numen_position_y4, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id5, Scene_id, Numen_position_x5, Numen_position_y5, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id6, Scene_id, Numen_position_x6, Numen_position_y6, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]);                 
                            
                                _-> %仍然有低于约定人数的房间
                                    New_Arena_room_2_max_id = New_State1#state.arena_room_2_max_id,
                                    New_Arena_room_2_dict = Arena_room_2_dict
                            
                            end
                    end,
                    New_State2 = New_State1#state{arena_room_2_max_id=New_Arena_room_2_max_id,
                                          arena_room_2_dict = New_Arena_room_2_dict};
                3->
                    Arena_room_3_dict = New_State1#state.arena_room_3_dict,
                    Temp_RoomList = dict:to_list(Arena_room_3_dict),
                    case Temp_RoomList of
                        []-> 
                            New_Arena_room_3_max_id = New_State1#state.arena_room_3_max_id+1,
                            New_Arena_room_3_dict = dict:append(New_Arena_room_3_max_id,
                                                        #arena_room{
                                                            room_lv=3, %房间类型
                                                            id=New_Arena_room_3_max_id  %房间ID
                                                        },
                                                        New_State1#state.arena_room_3_dict),
                            CopyId = integer_to_list(3) ++ "_" ++ integer_to_list(New_Arena_room_3_max_id),
                            {Numer_id1,Numer_id2,Numer_id3,Numer_id4,Numer_id5, Numer_id6} = lists:nth(3, Numer_id),
                            lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [Numer_id1,Numer_id2,Numer_id3,Numer_id4,Numer_id5, Numer_id6]),
                            %% 创建天庭守护神
                            lib_mon:async_create_mon(Numer_id1, Scene_id, Numen_position_x1, Numen_position_y1, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id2, Scene_id, Numen_position_x2, Numen_position_y2, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id3, Scene_id, Numen_position_x3, Numen_position_y3, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                            %% 创建鬼域守护神
                            lib_mon:async_create_mon(Numer_id4, Scene_id, Numen_position_x4, Numen_position_y4, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id5, Scene_id, Numen_position_x5, Numen_position_y5, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]),
                            lib_mon:async_create_mon(Numer_id6, Scene_id, Numen_position_x6, Numen_position_y6, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]);
                    
                        _->
                            Room_new_num = data_arena_new:get_arena_config(room_new_num),
                            Can_Add_RoomList = [L||{_,[L]}<-Temp_RoomList,L#arena_room.num<Room_new_num],
                            case Can_Add_RoomList of
                                []-> %无低于约定人数的房间，新建一个房间
                                    New_Arena_room_3_max_id = New_State1#state.arena_room_3_max_id+1,
                                    New_Arena_room_3_dict = dict:append(New_Arena_room_3_max_id,
                                                                #arena_room{
                                                                    room_lv=3, %房间类型
                                                                    id=New_Arena_room_3_max_id  %房间ID
                                                                },
                                                                New_State1#state.arena_room_3_dict),
                                    CopyId = integer_to_list(3) ++ "_" ++ integer_to_list(New_Arena_room_3_max_id),
                                    {Numer_id1,Numer_id2,Numer_id3,Numer_id4,Numer_id5, Numer_id6} = lists:nth(3, Numer_id),
                                    lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [Numer_id1,Numer_id2,Numer_id3,Numer_id4,Numer_id5, Numer_id6]),
                                    %% 创建天庭守护神
                                    lib_mon:async_create_mon(Numer_id1, Scene_id, Numen_position_x1, Numen_position_y1, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id2, Scene_id, Numen_position_x2, Numen_position_y2, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id3, Scene_id, Numen_position_x3, Numen_position_y3, 1, CopyId, 0, [{group, 1},{auto_lv, WorldLv}]),
                                    %% 创建鬼域守护神
                                    lib_mon:async_create_mon(Numer_id4, Scene_id, Numen_position_x4, Numen_position_y4, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id5, Scene_id, Numen_position_x5, Numen_position_y5, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]),
                                    lib_mon:async_create_mon(Numer_id6, Scene_id, Numen_position_x6, Numen_position_y6, 1, CopyId, 0, [{group, 2},{auto_lv, WorldLv}]);
                            
                                    _-> %仍然有低于约定人数的房间
                                        New_Arena_room_3_max_id = New_State1#state.arena_room_3_max_id,
                                        New_Arena_room_3_dict = Arena_room_3_dict
                            end
                    end,
                    New_State2 = New_State1#state{arena_room_3_max_id=New_Arena_room_3_max_id,
                                          arena_room_3_dict = New_Arena_room_3_dict}
            end,
            %获取玩家记录
            case RoomLv of
                1->
                    Arena_dict = New_State2#state.arena_1_dict,
                    Arena_room_dict = New_State2#state.arena_room_1_dict,
                    Default_RoomId = New_State2#state.arena_room_1_max_id;
                2->
                    Arena_dict = New_State2#state.arena_2_dict,
                    Arena_room_dict = New_State2#state.arena_room_2_dict,
                    Default_RoomId = New_State2#state.arena_room_2_max_id;
                3->
                    Arena_dict = New_State2#state.arena_3_dict,
                    Arena_room_dict = New_State2#state.arena_room_3_dict,
                    Default_RoomId = New_State2#state.arena_room_3_max_id
            end,
            case dict:is_key(PlayerId, Arena_dict) of
                false-> %无记录，该玩家未报名
                    RoomId = Default_RoomId;
                true-> %有记录，当天已看过房间列表
                    [Arena] = dict:fetch(PlayerId, Arena_dict),
                    RoomId = Arena#arena.room_id
            end,
            %% 进入房间
            Room_max_num = data_arena_new:get_arena_config(room_max_num),
            Arena_remain_time = lib_arena_new:get_arena_remain_time(State#state.config_begin_hour,State#state.config_begin_minute,State#state.config_end_hour,State#state.config_end_minute),
            case RoomLv of 
                1 ->
                    {Code, Result} = goin_room_sub(RoomId, Room_max_num,PlayerId,Pid,NickName,Country,Sex,Career,Image,PlayerLv,RoomLv,Arena_remain_time,Arena_dict,Arena_room_dict,New_State2#state.boss_time),
                    case Code of 
                        1 ->
                            {Reply, New_Arena_room_dict,New_Arena_dict} = Result,
                            New_State3 = New_State2#state{
                            arena_room_1_dict = New_Arena_room_dict,
                            arena_1_dict = New_Arena_dict
                            };
                        _ ->
                            Reply = Result,
                            New_State3 = New_State2 
                    end;
                2 ->
                    {Code, Result} = goin_room_sub(RoomId,Room_max_num,PlayerId,Pid,NickName,Country,Sex,Career,Image,PlayerLv,RoomLv,Arena_remain_time,Arena_dict,Arena_room_dict,New_State2#state.boss_time),
                    case Code of 
                        1 ->
                            {Reply, New_Arena_room_dict, New_Arena_dict} = Result,
                            New_State3 = New_State2#state{
                            arena_room_2_dict = New_Arena_room_dict,
                            arena_2_dict = New_Arena_dict
                            };
                        _ ->
                            Reply = Result,
                            New_State3 = New_State2
                    end;
                3 ->
                    {Code, Result} = goin_room_sub(RoomId,Room_max_num,PlayerId,Pid,NickName,Country,Sex,Career,Image,PlayerLv,RoomLv,Arena_remain_time,Arena_dict,Arena_room_dict,New_State2#state.boss_time),
                    case Code of 
                        1 ->
                            {Reply, New_Arena_room_dict, New_Arena_dict} = Result,
                            New_State3 = New_State2#state{
                            arena_room_3_dict = New_Arena_room_dict,
                            arena_3_dict = New_Arena_dict
                            };
                        _ ->
                        Reply = Result,
                        New_State3 = New_State2
                    end
            end,
            {Result2, RoomLv2, RoomId2, Realm2, TimeType2, BossTime2, RemainTime2} = Reply,
            case Result2 of 
                1 -> %成功进入
                    DailyPid = lib_player:get_player_info(UniteStatus#unite_status.id, dailypid),
                    mod_daily:increment(DailyPid, UniteStatus#unite_status.id, 6000005),
                    SceneBorn = data_arena_new:get_arena_config(scene_born),   
                    [X, Y] = lists:nth(Realm2, SceneBorn),
                    CopyId2 = integer_to_list(RoomLv2) ++ "_" ++ integer_to_list(RoomId2),
                    lib_scene:player_change_scene_queue(UniteStatus#unite_status.id, Scene_id, CopyId2, X, Y, [{group, Realm2}]);
                _ ->
                    skip
            end,
            {ok, BinData} = pt_480:write(48003, [Result2, RoomLv2, RoomId2, Realm2, TimeType2, BossTime2, RemainTime2]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
    end,
    {noreply, New_State3};

%竞技场积分榜 
handle_cast({score_list,PlayerId},State) ->
	%检测玩家是否第一次访问，并记录玩家第一次访问等级。防跳级依据。
	Arena_player_lv_dict = State#state.arena_player_lv_dict,
	case dict:is_key(PlayerId, Arena_player_lv_dict) of
		false-> %无记录，当天第一次请求
			HaveRecord = 0;
		true-> %有记录，当天已看过房间列表
			HaveRecord = 1
	end,
	case HaveRecord of
		0->Reply = {error,1};
		1->
			[Arena_player_lv] = dict:fetch(PlayerId, Arena_player_lv_dict),
			RoomLv = data_arena_new:get_room_lv(Arena_player_lv#arena_player_lv.lv),
			case RoomLv of
				1->
					Arena_dict = State#state.arena_1_dict;
				2->
					Arena_dict = State#state.arena_2_dict;
				3->
					Arena_dict = State#state.arena_3_dict
			end,
			case dict:is_key(PlayerId, Arena_dict) of
				false->Reply = {error,2};
				true->		
					%玩家竞技记录
					[Arena] = dict:fetch(PlayerId, Arena_dict),
					Arena_dict_list = dict:to_list(Arena_dict),
					Same_Room_Arena = [L||{_,[L]}<-Arena_dict_list,
											L#arena.room_lv=:=Arena#arena.room_lv,
											L#arena.room_id=:=Arena#arena.room_id],
					%%降序列表
					Sort_Same_Room_Arena = lists:sort(fun(A,B)-> 
						if
							A#arena.score>B#arena.score->true;
							A#arena.score=:=B#arena.score->
								if
									A#arena.kill_num>B#arena.kill_num -> true;
									true->false
								end;
							true->false
						end
					end,Same_Room_Arena),
					if
						length(Sort_Same_Room_Arena)>5->
							{Top5List,_} = lists:split(5,Sort_Same_Room_Arena);
						true->Top5List = Sort_Same_Room_Arena
					end,
					Reply = {ok,{Arena#arena.score,Arena#arena.continuous_kill,Arena#arena.anger,Arena#arena.kill_num,Arena#arena.assist_num,Arena#arena.kill_boss_num,Top5List}}
			end
	end,
	case Reply of
		{error,_}->void;
		{ok,{Score,Continuous_kill,Anger,Kill_Num,Assist_num,Kill_Boss_num,_Top5List}}->
			{ok, BinData} = pt_480:write(48004, [Score,Continuous_kill,Anger,Kill_Num,Assist_num,Kill_Boss_num,_Top5List]),
    		lib_unite_send:send_to_uid(PlayerId, BinData)
	end,
	{noreply, State};


handle_cast({set_time,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, Boss_time}, State) ->
	NewState = set_time_sub(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, Boss_time, State),
	{noreply, NewState};

handle_cast({set_status,Arena_Status}, State) ->
	case Arena_Status of
		0->
			NewState = State#state{
					  config_begin_hour=State#state.config_begin_hour,
					  config_begin_minute=State#state.config_begin_minute,
					  config_end_hour=State#state.config_end_hour,
					  config_end_minute=State#state.config_end_minute,
					  arena_stauts=Arena_Status
			};
		_->NewState = State#state{arena_stauts=Arena_Status}
	end,
	{noreply, NewState};

handle_cast({set_score,Type,Uid,KilledUidOrNPCTypeId, HitList}, State) ->
	%检测玩家是否第一次访问，并记录玩家第一次访问等级。防跳级依据。
	Arena_player_lv_dict = State#state.arena_player_lv_dict,
	case dict:is_key(Uid, Arena_player_lv_dict) of
		false-> %无记录，当天第一次请求
			HaveRecord = 0;
		true-> %有记录，当天已看过房间列表
			HaveRecord = 1
	end,
	case HaveRecord of
		0->
			{noreply, State};
		1->
			[Arena_player_lv] = dict:fetch(Uid, Arena_player_lv_dict),
			RoomLv = data_arena_new:get_room_lv(Arena_player_lv#arena_player_lv.lv),
			case RoomLv of
				1->
					Arena_room_dict = State#state.arena_room_1_dict,
					Arena_dict = State#state.arena_1_dict;
				2->
					Arena_room_dict = State#state.arena_room_2_dict,
					Arena_dict = State#state.arena_2_dict;
				3->
					Arena_room_dict = State#state.arena_room_3_dict,
					Arena_dict = State#state.arena_3_dict
			end,
			case Type of
				player->%%击杀玩家记分
					{NewArena_dict,NewArena_room_dict} = set_score_by_kill_player(Uid,
																				  KilledUidOrNPCTypeId,
																				  Arena_dict,
																				  Arena_room_dict,
																				  HitList
																				  );
				npc-> %%击杀NPC记分
					{NewArena_dict,NewArena_room_dict} = set_score_by_kill_npc(Uid,KilledUidOrNPCTypeId,Arena_dict,Arena_room_dict, State#state.boss_time);
				_->
					{NewArena_dict,NewArena_room_dict} = {Arena_dict,Arena_room_dict}
			end,
			case RoomLv of
				1->
					{noreply, State#state{
						arena_room_1_dict = NewArena_room_dict,
						arena_1_dict = NewArena_dict
						
					}};
				2->
					{noreply, State#state{
						arena_room_2_dict = NewArena_room_dict,
						arena_2_dict = NewArena_dict
						
					}};
				3->
					{noreply, State#state{
						arena_room_3_dict = NewArena_room_dict,
						arena_3_dict = NewArena_dict
					
					}}
			end
	end;

handle_cast({open_arena}, State) ->
	Arena_status = 1,
	NewState = #state{arena_stauts=Arena_status,
					  config_begin_hour= State#state.config_begin_hour,
					  config_begin_minute= State#state.config_begin_minute,
					  config_end_hour= State#state.config_end_hour,
					  config_end_minute= State#state.config_end_minute,
                      boss_time = State#state.boss_time},
	Exp_multiple = data_arena_new:get_arena_config(exp_multiple),
	{ok, BinData} = pt_480:write(48001, [Arena_status, Exp_multiple]),
	Apply_level = data_arena_new:get_arena_config(apply_level),
	lib_unite_send:send_to_all(Apply_level, 999,BinData),
    {noreply, NewState};

%%@param MonId 怪物资源ID
%%@param Scene 场景ID
%%@param X 坐标
%%@param X 坐标
%%@param Type 怪物战斗类型（0被动，1主动）
%%@param CopyId 房间号ID 为0时，普通房间，非0值切换房间。值相同，在同一个房间。
%%@param Lv 是否根据等级生成(0:不自动生成; 1,2..:自动生成)
%%@param Group 怪物阵营属性
handle_cast({call_boss,Boss_turn}, State) ->
	Room_1_KV_List = dict:to_list(State#state.arena_room_1_dict),
	Room_2_KV_List = dict:to_list(State#state.arena_room_2_dict),
	Room_3_KV_List = dict:to_list(State#state.arena_room_3_dict),
	Room_1_List = [V||{_K,[V]}<-Room_1_KV_List],
	Room_2_List = [V||{_K,[V]}<-Room_2_KV_List],
	Room_3_List = [V||{_K,[V]}<-Room_3_KV_List],
	Scene_id = data_arena_new:get_arena_config(scene_id),
    BossTime = State#state.boss_time,
	%% 中立boss的Id和出生点
	%Boss_Id = lists:nth(Boss_turn, data_arena_new:get_arena_config(boss_id)),
	%{Boss_position_x, Boss_position_y} = lists:nth(Boss_turn, data_arena_new:get_arena_config(boss_position)),
    {Boss_Id, Boss_position_x, Boss_position_y} = data_arena_new:get_boss_id_position(Boss_turn),
	
	New_Arena_room_1_dict = lists:foldl(fun(E, Arena_room_dict) ->
        case E#arena_room.killed_boss_turn+1 =:= Boss_turn andalso E#arena_room.boss_is_alive =:= 0 of 
            true ->
                CopyId = integer_to_list(E#arena_room.room_lv) ++ "_" ++ integer_to_list(E#arena_room.id),
                lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [Boss_Id]),
                lib_mon:sync_create_mon(Boss_Id, Scene_id, Boss_position_x, Boss_position_y, 0, CopyId, 1, []),
                %% 当前boss的刷新时间
                Next_boss_time = lists:nth(Boss_turn, BossTime),
                NewArenaRoom = E#arena_room{
                    next_boss_time = Next_boss_time,
                    boss_is_alive = 1
                    %boss_award = data_arena_new:get_boss_own(Boss_turn)
                    },
                %% 广播 
                %{ok, BinData} = pt_480:write(48012, [NewArenaRoom#arena_room.boss_award, 0]),
                %lib_unite_send:send_to_scene(Scene_id, CopyId, BinData),
                Temp_Arena_room_dict = dict:erase(E#arena_room.id, Arena_room_dict),
                New_Arena_room_dict = dict:append(E#arena_room.id, NewArenaRoom, Temp_Arena_room_dict),
                New_Arena_room_dict;
            false ->
                Arena_room_dict
        end
    end, State#state.arena_room_1_dict, Room_1_List),
	New_Arena_room_2_dict = lists:foldl(fun(E, Arena_room_dict) ->
        case E#arena_room.killed_boss_turn+1 =:= Boss_turn andalso E#arena_room.boss_is_alive =:= 0 of 
            true ->
                CopyId = integer_to_list(E#arena_room.room_lv) ++ "_" ++ integer_to_list(E#arena_room.id),
                lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [Boss_Id]),
                lib_mon:sync_create_mon(Boss_Id, Scene_id, Boss_position_x, Boss_position_y, 0, CopyId, 1, []),
                %% 下一个boss的刷新时间 
                case Boss_turn =:= 3 of 
                    true ->
                        Next_boss_time = 0;
                    false ->
                        Next_boss_time = lists:nth(Boss_turn+1, BossTime)
                end,
                NewArenaRoom = E#arena_room{
                    next_boss_time = Next_boss_time,
                    boss_is_alive = 1
                %    boss_award = data_arena_new:get_arena_config(Boss_turn)
                    },
                %{ok, BinData} = pt_480:write(48012, [NewArenaRoom#arena_room.boss_award, 0]),
                %lib_unite_send:send_to_scene(Scene_id, CopyId, BinData),
                Temp_Arena_room_dict = dict:erase(E#arena_room.id, Arena_room_dict),
                New_Arena_room_dict = dict:append(E#arena_room.id, NewArenaRoom, Temp_Arena_room_dict),
                New_Arena_room_dict;
            false ->
                Arena_room_dict
        end
    end, State#state.arena_room_2_dict, Room_2_List),
	New_Arena_room_3_dict = lists:foldl(fun(E, Arena_room_dict) ->
        case E#arena_room.killed_boss_turn+1 =:= Boss_turn andalso E#arena_room.boss_is_alive =:= 0 of 
            true ->
                CopyId = integer_to_list(E#arena_room.room_lv) ++ "_" ++ integer_to_list(E#arena_room.id),
                lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [Boss_Id]),
                lib_mon:sync_create_mon(Boss_Id, Scene_id, Boss_position_x, Boss_position_y, 0, CopyId, 1, []),
                %% 下一个boss的刷新时间 
                case Boss_turn =:= 3 of 
                    true ->
                        Next_boss_time = 0;
                    false ->
                        Next_boss_time = lists:nth(Boss_turn+1, BossTime)
                end,
                NewArenaRoom = E#arena_room{
                    next_boss_time = Next_boss_time, 
                    boss_is_alive = 0
                    },
                Temp_Arena_room_dict = dict:erase(E#arena_room.id, Arena_room_dict),
                New_Arena_room_dict = dict:append(E#arena_room.id, NewArenaRoom, Temp_Arena_room_dict),
                New_Arena_room_dict;
            false ->
                Arena_room_dict
        end
    end, State#state.arena_room_3_dict, Room_3_List),
    NewState = State#state{
        arena_room_1_dict = New_Arena_room_1_dict,
        arena_room_2_dict = New_Arena_room_2_dict,
        arena_room_3_dict = New_Arena_room_3_dict
    },
	{noreply, NewState};

handle_cast({end_arena,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute}, State) ->
	%%发送结束协议
	lib_arena_new:send_48010_to_all(),
	Arena_status = 2,
	NewState = State#state{arena_stauts=Arena_status},
	%%清理所有攻击怪和宝箱
	Npc_ids = data_arena_new:get_npc_type_id(),
    Box_ids = data_arena_new:get_arena_config(box_type),
	Scene_id = data_arena_new:get_arena_config(scene_id),
    lib_mon:clear_scene_mon_by_mids(Scene_id, [], 1, [Box_ids|Npc_ids]),
	%%处理玩家竞技场总积分
	Arena_1_KV_dict = dict:to_list(State#state.arena_1_dict),
	Arena_2_KV_dict = dict:to_list(State#state.arena_2_dict),
	Arena_3_KV_dict = dict:to_list(State#state.arena_3_dict),
	Arena_1_List = [V||{_K,[V]}<-Arena_1_KV_dict],
	Arena_2_List = [V||{_K,[V]}<-Arena_2_KV_dict],
	Arena_3_List = [V||{_K,[V]}<-Arena_3_KV_dict],
	%%发第一的传闻
	spawn(fun()->
		All_List = lists:append([Arena_1_List,Arena_2_List,Arena_3_List]),	
		All_List_Len = length(All_List),
		if
			0<All_List_Len->
				Sort_All_List = lists:sort(fun(A,B)-> 
					if
						B#arena.score=<A#arena.score->true;
						true->false	
					end
				end, All_List),
				if
					3=<All_List_Len->
						{Top_List,_} = lists:split(3, Sort_All_List);
					2=<All_List_Len->
						{Top_List,_} = lists:split(2, Sort_All_List);
					1=<All_List_Len-> %发送第一全服公告
						{Top_List,_} = lists:split(1, Sort_All_List);
					true->Top_List = []
				end,
				if
					1=<All_List_Len-> %发送第一全服公告
						First_Arena = lists:nth(1, Sort_All_List),
						lib_chat:send_TV({all},1,6,[5,First_Arena#arena.id,First_Arena#arena.contry,
													First_Arena#arena.nickname,First_Arena#arena.sex,
													First_Arena#arena.career,First_Arena#arena.image]);

					true->void
				end,
				Final_Top_List = [R#arena.id||R<-Top_List],
				%% 竞技场结束时，插入排前三的玩家
				%% List : 如[121, 12, 34]或[121, 34]
				spawn(fun()-> 
					lib_rank_activity:insert_arena_stat(Final_Top_List)
				end);
			true->void
		end
	end),
	%%开进程执行睡眠
	Multiple_all_data = mod_multiple:get_all_data(),
	spawn(fun() ->
		lists:foreach(fun(E)->
			[Arena_room] = dict:fetch(E#arena.room_id, State#state.arena_room_1_dict),
			%% {阵营名次,阵营名次加成积分,个人总积分}						  
			{Realm_no,Realm_no_score,Score} =lib_arena_new:account_score(Multiple_all_data,E,Arena_room),
			%% 这个更新先屏蔽			 
			lib_player:update_player_info(E#arena.id, [{arena,[E#arena.room_lv,E#arena.room_id,Score,E#arena.kill_num,E#arena.killed_num,E#arena.max_continuous_kill]}]),
			{ok, BinData} = pt_480:write(48011, [Arena_room#arena_room.green_score,	 
												 Arena_room#arena_room.red_score,
			  									 Arena_room#arena_room.green_numen_kill,
												 Arena_room#arena_room.red_numen_kill,
												 Realm_no,
												 E#arena.kill_num,
												 E#arena.assist_num,
												 E#arena.kill_boss_num,
												 E#arena.kill_numen_num,
												 E#arena.max_continuous_kill,
												 E#arena.kill_continuous_score,
												 E#arena.kill_numen_score+E#arena.kill_boss_score,
												 Realm_no_score,
												 Score
											      																					           												 										          
			]),
			lib_unite_send:send_to_uid(E#arena.id, BinData),
			timer:sleep(100)
		end, Arena_1_List)
	end),	
	spawn(fun() ->
		lists:foreach(fun(E)->
			[Arena_room] = dict:fetch(E#arena.room_id, State#state.arena_room_2_dict),						  
			{Realm_no,Realm_no_score,Score}=lib_arena_new:account_score(Multiple_all_data,E,Arena_room),			 
			lib_player:update_player_info(E#arena.id, [{arena,[E#arena.room_lv,E#arena.room_id,Score,E#arena.kill_num,E#arena.killed_num,E#arena.max_continuous_kill]}]),
			{ok, BinData} = pt_480:write(48011, [Arena_room#arena_room.green_score,	 
												 Arena_room#arena_room.red_score,
			  									 Arena_room#arena_room.green_numen_kill,
												 Arena_room#arena_room.red_numen_kill,
												 Realm_no,
												 E#arena.kill_num,
												 E#arena.assist_num,
												 E#arena.kill_boss_num,
												 E#arena.kill_numen_num,
												 E#arena.max_continuous_kill,
												 E#arena.kill_continuous_score,
												 E#arena.kill_numen_score+E#arena.kill_boss_score,
												 Realm_no_score,
												 Score
			]),
			lib_unite_send:send_to_uid(E#arena.id, BinData),
			timer:sleep(100)
		end, Arena_2_List)
	end),
	spawn(fun() ->
		lists:foreach(fun(E)->
			[Arena_room] = dict:fetch(E#arena.room_id, State#state.arena_room_3_dict),						  
			{Realm_no,Realm_no_score,Score}=lib_arena_new:account_score(Multiple_all_data,E,Arena_room),			 
			lib_player:update_player_info(E#arena.id, [{arena,[E#arena.room_lv,E#arena.room_id,Score,E#arena.kill_num,E#arena.killed_num,E#arena.max_continuous_kill]}]),
			{ok, BinData} = pt_480:write(48011, [Arena_room#arena_room.green_score,	 
												 Arena_room#arena_room.red_score,
			  									 Arena_room#arena_room.green_numen_kill,
												 Arena_room#arena_room.red_numen_kill,
												 Realm_no,
												 E#arena.kill_num,
												 E#arena.assist_num,
												 E#arena.kill_boss_num,
												 E#arena.kill_numen_num,
												 E#arena.max_continuous_kill,
												 E#arena.kill_continuous_score,
												 E#arena.kill_numen_score+E#arena.kill_boss_score,
												 Realm_no_score,
												 Score
			]),
			lib_unite_send:send_to_uid(E#arena.id, BinData),
			timer:sleep(100)
		end, Arena_3_List)
	end),
	NewState2 = set_time_sub(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, NewState#state.boss_time, NewState),
	
	%% 刷新每日竞技场排行榜
	mod_rank:refresh_arena_day(),
    	
	{noreply, NewState2};

handle_cast({change_boss_award, _CopyId, Mid}, State) ->
    [X,_Y,Z] = _CopyId,
    CopyId = list_to_integer([Z]),
    case list_to_integer([X]) of 
        1 ->
            Arena_room_dict = State#state.arena_room_1_dict;
        2 ->
            Arena_room_dict = State#state.arena_room_1_dict;
        _ ->
            Arena_room_dict = State#state.arena_room_1_dict
    end,
    Scene_id = data_arena_new:get_arena_config(scene_id),
    case dict:is_key(CopyId, Arena_room_dict) of 
        false -> {noreply, State};
        true ->
            [Arena_room] = dict:fetch(CopyId, State#state.arena_room_1_dict),
            New_boss_award = case Arena_room#arena_room.boss_award of 
                0 -> 
                    data_arena_new:get_boss_own(Mid);
                1 -> 2;
                2 -> 1
            end,
            New_Arena_room = Arena_room#arena_room{boss_award = New_boss_award},
            Temp_Arena_room_dict = dict:erase(CopyId, Arena_room_dict),
            New_Arena_room_dict = dict:append(CopyId, New_Arena_room, Temp_Arena_room_dict),
            {ok, BinData} = pt_480:write(48012, [New_boss_award, 0]),
            lib_unite_send:send_to_scene(Scene_id, _CopyId, BinData),
            case list_to_integer([X]) of
                1 ->
                    {noreply, State#state{arena_room_1_dict = New_Arena_room_dict}};
                2 ->
                    {noreply, State#state{arena_room_2_dict = New_Arena_room_dict}};
                _ ->
                    {noreply, State#state{arena_room_1_dict = New_Arena_room_dict}}
            end
    end;

%% 更新玩家怒气值
handle_cast({update_anger, PlayerId}, State) ->
    Arena_player_lv_dict = State#state.arena_player_lv_dict,
    case dict:is_key(PlayerId, Arena_player_lv_dict) of 
        false ->
            skip;
        true ->
            [Arena_player_lv] = dict:fetch(PlayerId, Arena_player_lv_dict),
            RoomLv = data_arena_new:get_room_lv(Arena_player_lv#arena_player_lv.lv),
            case RoomLv of 
                1 ->
                    Arena_dict = State#state.arena_1_dict;
                2 ->
                    Arena_dict = State#state.arena_2_dict;
                3 ->
                    Arena_dict = State#state.arena_3_dict
            end,
            case dict:is_key(PlayerId, Arena_dict) of 
                false ->
                    skip;
                true ->
                    [Arena] = dict:fetch(PlayerId, Arena_dict),
                    New_Arena = Arena#arena{anger = data_arena_new:get_arena_config(default_anger)},
                    Temp_Arena_dict = dict:erase(PlayerId, Arena_dict),
                    New_Arena_dict = dict:append(PlayerId, New_Arena, Temp_Arena_dict),
                    case RoomLv of 
                        1 ->
                            {noreply, State#state{arena_1_dict = New_Arena_dict}};
                        2 ->
                            {noreply, State#state{arena_2_dict = New_Arena_dict}};
                        3 ->
                            {noreply, State#state{arena_3_dict = New_Arena_dict}}
                    end
            end
    end;

handle_cast({add_anger_timer}, State) ->
    Arena_1_List = [{K,V}||{K, [V]} <- dict:to_list(State#state.arena_1_dict)],
    Arena_2_List = [{K,V}||{K, [V]} <- dict:to_list(State#state.arena_2_dict)],
    Arena_3_List = [{K,V}||{K, [V]} <- dict:to_list(State#state.arena_3_dict)],
    AddAnger = data_arena_new:get_arena_config(add_anger_timer_value),
    MaxAnger = data_arena_new:get_arena_config(max_anger),
    Arena_1_dict = handle_add_anger_timer(Arena_1_List, State#state.arena_1_dict, AddAnger, MaxAnger),
    Arena_2_dict = handle_add_anger_timer(Arena_2_List, State#state.arena_2_dict, AddAnger, MaxAnger),
    Arena_3_dict = handle_add_anger_timer(Arena_3_List, State#state.arena_3_dict, AddAnger, MaxAnger),
    NewState = State#state{
        arena_1_dict = Arena_1_dict,
        arena_2_dict = Arena_2_dict,
        arena_3_dict = Arena_3_dict
    },
    {noreply, NewState};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%%设置时间子方法
set_time_sub(Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute,Boss_time,State)->
	NewState = State#state{config_begin_hour=Config_Begin_Hour,
					  config_begin_minute=Config_Begin_Minute,
					  config_end_hour=Config_End_Hour,
					  config_end_minute=Config_End_Minute,
					  boss_time = Boss_time},
	NewState.


%% @spec: set_score_by_kill_player(Uid, NpcTypeId, Arena_dict, Arena_room_dict) -> {New_Arena_dict, New_Arena_room_dict}
%% 击杀玩家带来的变化
%% Uid          = int()         击杀玩家的玩家Id        
%% NpcTypeId    = int()         被击杀的怪物资源Id
%% Arena_dict   = dict()        竞技场玩家字典
%% Arena_room_dict = dict()     竞技场房间字典
%% Boss_time 	= list() 		创建boss的时间列表
%% @end
set_score_by_kill_npc(Uid, NpcTypeId, Arena_dict, Arena_room_dict, Boss_time) ->
    {{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
    NowTime = (Hour*60+Minute)*60 + Second,
    case dict:is_key(Uid, Arena_dict) of 
        false ->
            New_Arena_dict_2 = Arena_dict,
            New_Arena_room_dict = Arena_room_dict;
        true ->
            % 玩家竞技记录
            [Arena] = dict:fetch(Uid, Arena_dict),  
            %% {1:npc还是2:boss,个人加分,同阵营个人加分} 
            {Type, Player_Add, Others_Add} = data_arena_new:get_kill_bossnpc_score(NpcTypeId),
            case Type of
                1 ->    % npc
                    %1.处理个人
                    NewArena = Arena#arena{
                        kill_numen_num = Arena#arena.kill_numen_num+1,
                        kill_numen_score = Arena#arena.kill_numen_score+Player_Add,
                        score = Arena#arena.score+Player_Add
                    },
                    Temp_Arena_dict = dict:erase(Uid, Arena_dict),
                    New_Arena_dict = dict:append(Uid, NewArena, Temp_Arena_dict),
                    %2.处理阵营及其他玩家
                    case dict:is_key(NewArena#arena.room_id, Arena_room_dict) of
                        false ->   
                            New_Arena_room_dict = Arena_room_dict,
                            New_Arena_dict_2 = New_Arena_dict;
                        true ->
                            [Arena_room] = dict:fetch(NewArena#arena.room_id, Arena_room_dict),
                            %% 处理同阵营玩家加分
                            {New_Arena_dict_2, TotalAdd} = handle_same_people_by_npc(New_Arena_dict, NewArena#arena.room_id, NewArena#arena.realm, Others_Add),
                            case NewArena#arena.realm of 
                                1 ->
                                    New_Arena_room = Arena_room#arena_room{green_score = Arena_room#arena_room.green_score+TotalAdd+Player_Add,
                                        green_numen_kill = Arena_room#arena_room.green_numen_kill+1};
                                2 ->
                                    New_Arena_room = Arena_room#arena_room{red_score = Arena_room#arena_room.red_score+TotalAdd+Player_Add,
                                        red_numen_kill = Arena_room#arena_room.red_numen_kill+1}
                            end,
                            Temp_Arena_room_dict = dict:erase(NewArena#arena.room_id, Arena_room_dict),
                            New_Arena_room_dict = dict:append(NewArena#arena.room_id, New_Arena_room, Temp_Arena_room_dict)
                    end;
                2 ->    % 中立boss
                    %1.处理个人
                    NewArena = Arena#arena{
                        kill_boss_num = Arena#arena.kill_boss_num+1,
                        kill_boss_score = Arena#arena.kill_boss_score+Player_Add,
                        score = Arena#arena.score+Player_Add
                    },
                    Temp_Arena_dict = dict:erase(Uid, Arena_dict),
                    New_Arena_dict = dict:append(Uid, NewArena, Temp_Arena_dict),
                    %2.处理阵营及其他玩家
                    case dict:is_key(NewArena#arena.room_id, Arena_room_dict) of
                        false ->   
                            New_Arena_room_dict = Arena_room_dict,
                            New_Arena_dict_2 = New_Arena_dict;
                        true ->
                            [Arena_room] = dict:fetch(NewArena#arena.room_id, Arena_room_dict),
                            %% 处理同boss奖励阵营相同玩家加分
                            {New_Arena_dict_2, TotalAdd} = handle_same_people_by_boss(New_Arena_dict, NewArena#arena.room_id, Arena_room#arena_room.boss_award, Others_Add),    
                            %% 击杀玩家和boss是否同阵营
                            case NewArena#arena.realm =:= Arena_room#arena_room.boss_award of 
                                true ->
                                    Same_Total = TotalAdd+Player_Add,
                                    Diff_Total = 0;
                                false ->
                                    Same_Total = Player_Add,
                                    Diff_Total = TotalAdd
                            end,
                            case NewArena#arena.realm of 
                                1 ->
                                    Temp_Arena_room = Arena_room#arena_room{green_score = Arena_room#arena_room.green_score+Same_Total,
                                        red_score = Arena_room#arena_room.red_score+Diff_Total,
                                        killed_boss_turn = Arena_room#arena_room.killed_boss_turn+1,
                                        green_boss_kill = Arena_room#arena_room.green_boss_kill+1};
                                2 ->
                                    Temp_Arena_room = Arena_room#arena_room{red_score = Arena_room#arena_room.red_score+Same_Total,
                                        green_score = Arena_room#arena_room.green_score+Diff_Total,
                                        killed_boss_turn = Arena_room#arena_room.killed_boss_turn+1,
                                        red_boss_kill = Arena_room#arena_room.red_boss_kill+1}
                            end,
                            %% 更新下一个boss的掉落归属和生成时间
                            {IsCreateNow,{NewHour,NewMinute},Award} = case Temp_Arena_room#arena_room.killed_boss_turn =:= 3 of 
                                true -> % 三个boss已经杀完
                                    {0,{0,0},0};
                                false ->
                                    {Next_Hour,Next_Minute} = lists:nth(Temp_Arena_room#arena_room.killed_boss_turn+1, Boss_time),
                                    %% 正常的下一波中立boss的生成时间
                                    Next_boss_time = (Next_Hour*60+Next_Minute)*60,
                                    case NowTime >= Next_boss_time of 
                                        true -> % 已过下一波boss的生成时间，一分钟后生成
                                            %NextAward = data_arena_new:get_boss_own(Temp_Arena_room#arena_room.killed_boss_turn+1),
                                            NextAward = 0,
                                            {1, {Hour, Minute+1}, NextAward};
                                        false -> % 有默认定时器mgr生成
                                            %NextAward = data_arena_new:get_boss_own(Temp_Arena_room#arena_room.killed_boss_turn+1),
                                            NextAward = 0,
                                            {0, {Next_Hour,Next_Minute}, NextAward}
                                    end
                            end,
                            case IsCreateNow =:= 1 of 
                                true ->
                                    Boss_is_alive = 1;
                                false -> 
                                    Boss_is_alive = 0
                            end,
                            New_Arena_room = Temp_Arena_room#arena_room{
                                next_boss_time = {NewHour,NewMinute},
                                boss_award = Award,
                                boss_is_alive = Boss_is_alive
                            },

                            %% 创建下一轮boss
                            Scene_id = data_arena_new:get_arena_config(scene_id),
                            CopyId = integer_to_list(New_Arena_room#arena_room.room_lv) ++ "_" ++ integer_to_list(New_Arena_room#arena_room.id),

                            %% 创建宝箱
                            spawn(fun() ->
                                %% 取击杀boss的玩家的坐标
                                {_,_,Player_X,Player_Y} = lib_player:get_player_info(NewArena#arena.id, position_info),
                                Box_id = data_arena_new:get_arena_config(box_type),
                                [{Box_position_x_1,Box_position_y_1},{Box_position_x_2,Box_position_y_2},{Box_position_x_3,Box_position_y_3}] = data_arena_new:get_box_position(Player_X,Player_Y),
                                lib_mon:sync_create_mon(Box_id, Scene_id, Box_position_x_1, Box_position_y_1, 0, CopyId, 1,[{group,Temp_Arena_room#arena_room.boss_award}]),
                                lib_mon:sync_create_mon(Box_id, Scene_id, Box_position_x_2, Box_position_y_2, 0, CopyId, 1,[{group,Temp_Arena_room#arena_room.boss_award}]),        
                                lib_mon:sync_create_mon(Box_id, Scene_id, Box_position_x_3, Box_position_y_3, 0, CopyId, 1,[{group,Temp_Arena_room#arena_room.boss_award}])
                                %% 1分钟后清理宝箱
                                % timer:sleep(1000),
                                % lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [Box_id])
                            end),
                            spawn(fun() ->
                            	case IsCreateNow =:= 0 of
                            		true ->
                            			void;
                            		false ->
                            			
                            			%{Boss_position_x, Boss_position_y} = lists:nth(New_Arena_room#arena_room.killed_boss_turn+1, data_arena_new:get_arena_config(boss_position)),
                            			%BossId = lists:nth(New_Arena_room#arena_room.killed_boss_turn+1,data_arena_new:get_arena_config(boss_id)),
                                        {BossId, Boss_position_x, Boss_position_y} = data_arena_new:get_boss_id_position(New_Arena_room#arena_room.killed_boss_turn+1),
                            		 % 1分钟后创建
                            			timer:sleep(60*1000),
                            			lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [BossId]),
                            			lib_mon:sync_create_mon(BossId, Scene_id, Boss_position_x, Boss_position_y, 0, CopyId, 1, [])                		
                            	        %% 广播boss归属 
                                        %{ok, BinData} = pt_480:write(48012, [Award, 0]),
                                        %lib_unite_send:send_to_scene(Scene_id, CopyId, BinData)
                                end
                            end),
                            %% 广播boss倒计时
                            spawn(fun() -> 
                                BossCreateTime = (NewHour*60+NewMinute)*60,
                                LeftTime = BossCreateTime - NowTime,
                                case Temp_Arena_room#arena_room.killed_boss_turn =:= 3 of
                                    true ->
                                        {ok, BinData} = pt_480:write(48012, [3, 0]); 
                                    false ->
                                        {ok, BinData} = pt_480:write(48012, [0, LeftTime])
                                end,
                                lib_unite_send:send_to_scene(Scene_id, CopyId, BinData)
                            end),
                            Temp_Arena_room_dict = dict:erase(NewArena#arena.room_id, Arena_room_dict),
                            New_Arena_room_dict = dict:append(NewArena#arena.room_id, New_Arena_room, Temp_Arena_room_dict)
                    end
            end
    end,
    {New_Arena_dict_2, New_Arena_room_dict}.


%% @spec: set_score_by_kill_player(Uid, KilledUid, Arena_dict, Arena_room_dict, HitList) -> {New_Arena_dict, New_Arena_room_dict}
%% 击杀玩家带来的变化
%% Uid          = int()         击杀玩家的玩家Id        
%% KilledUid    = int()         被击杀玩家的Id
%% Arena_dict   = dict()        竞技场玩家字典
%% Arena_room_dict = dict()     竞技场房间字典
%% HitList      = list()        助攻者列表
%% @end
set_score_by_kill_player(Uid, KilledUid, Arena_dict, Arena_room_dict, HitList) ->
    NowTime = util:unixtime(),
    case dict:is_key(Uid, Arena_dict) andalso dict:is_key(KilledUid, Arena_dict) of 
        false -> 
            {Arena_dict, Arena_room_dict};
        true ->
            [Arena] = dict:fetch(Uid, Arena_dict),
            [KilledUidArena] = dict:fetch(KilledUid, Arena_dict),
            %ArenaSceneId = data_arena_new:get_arena_config(scene_id),
            %ArenaCopyId = integer_to_list(Arena#arena.room_lv) ++ "_" ++ integer_to_list(Arena#arena.room_id),
            %% 防止杀短时间内杀同一个人，需要判断杀人是否有效
            CDTime = data_arena_new:get_arena_config(cd_time),
            Killed = Arena#arena.killed,
            case dict:is_key(KilledUid, Killed) of 
                false ->
                    Is_Kill_Effect = true,
                    Is_Assist_Effect = true;
                true ->
                    KilledList = dict:fetch(KilledUid, Killed),
                    LastKilled = lists:last(KilledList),
                    Time = LastKilled#killed.time,
                    if 
                        NowTime - Time >= CDTime ->
                            Is_Kill_Effect = true,   % 杀人有效
                            Is_Assist_Effect = true; % 助攻有效
                        true ->
                            Is_Kill_Effect = false,   % 杀人无效
                            Is_Assist_Effect = false  % 助攻无效
                    end
            end,
            %% 杀人有效，处理胜利者和失败者以及所在阵营
            case Is_Kill_Effect of 
                true ->
                    %% 胜利者处理
                    NewKillNum = Arena#arena.kill_num+1,    %1.杀人数+1
                    %% {新的杀人积分，增加的积分}
                    {Kill_Score,Add_Kill_Score} = data_arena_new:get_kill_score(NewKillNum, Arena#arena.kill_score), %2.新的杀人积分
                    KilledElement = #killed{
                        uid = KilledUid,
                        time = NowTime 
                    },
                    NewKilled = dict:append(KilledUid, KilledElement, Killed),  %3.新的杀人字典
                    Redu_anger = data_arena_new:get_arena_config(del_anger),    %4.更新怒气值
                        if 
                            Redu_anger =< Arena#arena.anger ->
                                NewUidAnger = Arena#arena.anger - Redu_anger;
                            true ->
                                NewUidAnger = 0
                        end,
                    New_Continuous_kill = Arena#arena.continuous_kill+1,        %5.新的连斩数
                    if 
                        New_Continuous_kill =< Arena#arena.max_continuous_kill ->
                            New_Max_continuous_kill = Arena#arena.max_continuous_kill;  %6 新的最高连斩数
                        true ->
                            New_Max_continuous_kill = New_Continuous_kill
                    end,
                    %% {击杀连斩积分, 击杀连斩新增加的积分}
                    {Kill_Continuous_Score, Add_Continuous_Score} = 
                        data_arena_new:get_kill_continuous_score(KilledUidArena#arena.continuous_kill, KilledUidArena#arena.kill_continuous_score),  %7 击杀连斩积分加成  

                    %% 杀人带来的总积分 = 旧的积分+杀人增加积分+击杀连斩增加积分 
                    NewScore = Arena#arena.score + Add_Kill_Score +  Add_Continuous_Score,  %8.更新总积分        
                    %% 更新胜利者信息汇总
                    NewArena = Arena#arena{
                        kill_num = NewKillNum,      % 杀人数
                        killed = NewKilled,         % 杀人字典
                        anger = NewUidAnger,        % 怒气
                        continuous_kill = New_Continuous_kill,  % 连斩数
                        max_continuous_kill = New_Max_continuous_kill,  % 最高连斩数
                        kill_score = Kill_Score,   % 杀人积分
                        kill_continuous_score = Kill_Continuous_Score, %击杀连斩积分
                        score = NewScore
                    },

                    %% 处理被杀者
                    Max_anger = data_arena_new:get_arena_config(max_anger),
                    Add_anger = data_arena_new:get_arena_config(add_anger),
                    _NewAnger = KilledUidArena#arena.anger + Add_anger,         %1.增加怒气值
                    if 
                        _NewAnger =< Max_anger ->
                            NewAnger = _NewAnger;
                        true ->
                            NewAnger = Max_anger
                    end,
                    NewKilledNum = KilledUidArena#arena.killed_num + 1,           %2.被杀数+1
                    %% 更新被杀玩家信息
                    NewKilledUidArena = KilledUidArena#arena{
                        anger = NewAnger,
                        killed_num = NewKilledNum,
                        continuous_kill = 0                             %3.连斩数置 0
                    },
                    %% 更新玩家字典
                    Temp_Arena_dict = dict:erase(Uid, Arena_dict),
                    Temp_Arena_dict_2 = dict:erase(KilledUid, Temp_Arena_dict),
                    Temp_Arena_dict_3 = dict:append(Uid, NewArena, Temp_Arena_dict_2),
                    Temp_Arena_dict_4 = dict:append(KilledUid, NewKilledUidArena, Temp_Arena_dict_3),
                    %% 更新阵营积分--杀人者阵营
                    case dict:is_key(NewArena#arena.room_id, Arena_room_dict) of
                        false -> New_Arena_room_dict = Arena_room_dict;
                        true ->
                            [Arena_room] = dict:fetch(NewArena#arena.room_id,Arena_room_dict),
                            case NewArena#arena.realm of 
                                1 ->    % 天庭
                                    New_Arena_room = Arena_room#arena_room{green_score = Arena_room#arena_room.green_score+Add_Kill_Score};
                                2 ->    % 鬼域
                                    New_Arena_room = Arena_room#arena_room{red_score = Arena_room#arena_room.red_score+Add_Kill_Score}
                            end,
                            Temp_Arena_room_dict = dict:erase(NewArena#arena.room_id, Arena_room_dict),
                            New_Arena_room_dict = dict:append(NewArena#arena.room_id, New_Arena_room, Temp_Arena_room_dict)
                    end;
                false ->
                    Temp_Arena_dict_4 = Arena_dict,
                    New_Arena_room_dict = Arena_room_dict
            end,
            %%% 处理助攻列表,助攻列表只给玩家加分，不给阵营加分
            case Is_Assist_Effect of 
                true ->
                    New_Arena_dict = handle_assist_list(HitList, NowTime, Temp_Arena_dict_4);
                false ->
                    New_Arena_dict = Temp_Arena_dict_4
            end,
            {New_Arena_dict, New_Arena_room_dict}
    end.

get_sort_num(Sort_Same_Room_Arena,Uid,Num)->
	case Sort_Same_Room_Arena of
		[] -> Num;
		_->
			[H|T] = Sort_Same_Room_Arena,
			if
				3<Num -> Num;
				H#arena.id=:=Uid->Num+1;
				true->get_sort_num(T,Uid,Num+1)
			end
	end.

%%
%%@return {0,Reply} | {1, {Reply, New_Arena_room_dict,New_Arena_dict}}
goin_room_sub(RoomId,Room_max_num,PlayerId,Pid,NickName,Country,Sex,Career,Image,Player_lv,RoomLv,Arena_remain_time,Arena_dict,Arena_room_dict,BossTime)->
	case dict:is_key(RoomId, Arena_room_dict) of
		false->Reply = {4,0,0,0,0,0,0},{0,Reply};%不存在的房间号
		true->
			[TargetRoom] = dict:fetch(RoomId, Arena_room_dict),
			case lib_player:get_player_info(PlayerId, pk) of
				false-> Pk_status = 2;
				Pk -> Pk_status = Pk#status_pk.pk_status
			end,
            {PK_Result, _PK_ErrorCode, _PK_NewType, _PK_LTime, _PK_NewStatus1} = lib_player:change_pk_status(PlayerId, 6),
			if 
                %% 切换阵营
                PK_Result =:= error -> Reply = {8,0,0,0,0,0,0},{0,Reply};
				TargetRoom#arena_room.num<Room_max_num->%房间未满
					case dict:is_key(PlayerId, Arena_dict) of
						false-> %无记录，该玩家未报名
							%分配阵营(实力最弱的)
							Sort_arena_room = lib_arena_new:sort_arena_room_4_realm(TargetRoom),
							Realm = lists:nth(2, Sort_arena_room),
							case Realm of
								1->New_Arena_room = TargetRoom#arena_room{
										num = TargetRoom#arena_room.num+1,
										green_num = TargetRoom#arena_room.green_num+1
									};
								2->New_Arena_room = TargetRoom#arena_room{
										num = TargetRoom#arena_room.num+1,
										red_num = TargetRoom#arena_room.red_num+1	
									}					
							end,
							Temp_Arena_room_dict = dict:erase(RoomId, Arena_room_dict),
							New_Arena_room_dict = dict:append(RoomId,New_Arena_room,Temp_Arena_room_dict),
							Arena = #arena{
										id = PlayerId,
										pid = Pid,
										nickname=NickName,
										contry = Country,
										sex = Sex,
										career = Career,
										image = Image,
										player_lv = Player_lv,
										room_lv = RoomLv,
										room_id = RoomId,
										realm = Realm,
                                        anger = data_arena_new:get_arena_config(default_anger),
										pk_status = Pk_status,
										is_leave = 0
									},
                            %%  屏幕中间显示的时间倒计时{类型和时间}
                            {TimeType,BossLeftTime} = get_type_and_time(BossTime, New_Arena_room, Arena_remain_time),
							New_Arena_dict = dict:append(PlayerId,Arena,Arena_dict),
							Reply = {1,RoomLv,RoomId,Arena#arena.realm, TimeType, BossLeftTime,Arena_remain_time},
							{1, {Reply, New_Arena_room_dict,New_Arena_dict}};
						true-> %有记录，二次登入，直接进入
							[Arena] = dict:fetch(PlayerId, Arena_dict),
							if
								Arena#arena.room_lv/=RoomLv orelse Arena#arena.room_id/=RoomId->
									Reply = {6,0,0,0,0,0,0},{0,Reply};
								true->
                                    %%  屏幕中间显示的时间倒计时{类型和时间}
                                    {TimeType,BossLeftTime} = get_type_and_time(BossTime, TargetRoom, Arena_remain_time),
									Reply = {1,RoomLv,RoomId,Arena#arena.realm,TimeType,BossLeftTime,Arena_remain_time},
									NewArena = Arena#arena{pid=Pid,pk_status = Pk_status,is_leave = 0}, %更新PID
									Temp_Arena_dict = dict:erase(PlayerId, Arena_dict),
									New_Arena_dict = dict:append(PlayerId, NewArena, Temp_Arena_dict),
									{1, {Reply, Arena_room_dict,New_Arena_dict}}
							end
					end;											
				true->
					case dict:is_key(PlayerId, Arena_dict) of
						false-> %无记录，该玩家未报名
							Reply = {5,0,0,0,0,0,0},{0,Reply};
						true->
							[Arena] = dict:fetch(PlayerId, Arena_dict),
							if
								Arena#arena.room_lv/=RoomLv orelse Arena#arena.room_id/=RoomId->
									Reply = {6,0,0,0,0},{0,Reply};
								true->
                                    %%  屏幕中间显示的时间倒计时{类型和时间}
                                    {TimeType,BossLeftTime} = get_type_and_time(BossTime, TargetRoom, Arena_remain_time),
									Reply = {1,RoomLv,RoomId,Arena#arena.realm,TimeType,BossLeftTime,Arena_remain_time},
									NewArena = Arena#arena{pid=Pid,pk_status = Pk_status, is_leave = 0}, %更新PID
									Temp_Arena_dict = dict:erase(PlayerId, Arena_dict),
									New_Arena_dict = dict:append(PlayerId, NewArena, Temp_Arena_dict),
									{1, {Reply, Arena_room_dict,New_Arena_dict}}
							end
					end
			end
	end.

%% @spec handle_same_people_by_npc(Arena_dict, room_id, realm, Others_Add) -> {New_Arena_dict,total_add}
%% Arena_dict           = dict()            玩家字典
%% room_id              = int()             击杀boss的玩家所在的房间
%% realm                = int()             击杀boss的玩家的阵营
%% others_add           = int()             同阵营玩家增加的积分
%% @end
handle_same_people_by_npc(Arena_dict, RoomId, Realm, AddScore) ->
    Arena_list = dict:to_list(Arena_dict),
    %% 分离出同房间同阵营的场景玩家
    Same_realm_Arena = [{Uid, V} || {Uid, [V]} <-Arena_list,
                                    V#arena.room_id =:= RoomId,
                                    V#arena.realm =:= Realm,
                                    V#arena.is_leave =:= 0],
    handle_same_people_by_npc_2(Same_realm_Arena, Arena_dict, AddScore, 0).

handle_same_people_by_npc_2([], Arena_dict, _AddScore, TotalAdd) -> {Arena_dict, TotalAdd};
handle_same_people_by_npc_2([H|T], Arena_dict, AddScore, TotalAdd) ->
    case H of 
        {Uid, V} ->
            TempArena = V#arena{kill_numen_score = V#arena.kill_numen_score+AddScore,
                                score = V#arena.score + AddScore},
            Temp_Arena_dict = dict:erase(Uid, Arena_dict),
            New_Arena_dict = dict:append(Uid, TempArena, Temp_Arena_dict),
            handle_same_people_by_npc_2(T, New_Arena_dict, AddScore, TotalAdd+AddScore);
        _ ->
            handle_same_people_by_npc_2(T, Arena_dict, AddScore, TotalAdd)
    end.

%% @spec handle_same_people_by_boss(Arena_dict, room_id, realm, Others_Add) -> {New_Arena_dict,total_add}
%% Arena_dict           = dict()            玩家字典
%% room_id              = int()             击杀boss的玩家所在的房间
%% realm                = int()             击杀boss的玩家的阵营
%% others_add           = int()             同阵营玩家增加的积分
%% @end
handle_same_people_by_boss(Arena_dict, RoomId, Realm, AddScore) ->
    Arena_list = dict:to_list(Arena_dict),
    %% 分离出同房间同阵营的场景玩家
    Same_realm_Arena = [{Uid, V} || {Uid, [V]} <-Arena_list,
                                    V#arena.room_id =:= RoomId,
                                    V#arena.realm =:= Realm,
                                    V#arena.is_leave =:= 0],
    handle_same_people_by_boss_2(Same_realm_Arena, Arena_dict, AddScore, 0).

handle_same_people_by_boss_2([], Arena_dict, _AddScore, TotalAdd) -> {Arena_dict, TotalAdd};
handle_same_people_by_boss_2([H|T], Arena_dict, AddScore, TotalAdd) ->
    case H of 
        {Uid, V} ->
            TempArena = V#arena{kill_boss_score = V#arena.kill_boss_score+AddScore,
                                score = V#arena.score + AddScore},
            Temp_Arena_dict = dict:erase(Uid, Arena_dict),
            New_Arena_dict = dict:append(Uid, TempArena, Temp_Arena_dict),
            handle_same_people_by_boss_2(T, New_Arena_dict, AddScore, TotalAdd+AddScore);
        _ ->
            handle_same_people_by_boss_2(T, Arena_dict, AddScore, TotalAdd)
    end.

%% 处理助攻列表
% 处理助攻列表
handle_assist_list(HitList, NowTime, Arena_dict) ->
    AssistTime = data_arena_new:get_arena_config(assist_time),
    case HitList of 
        [{Uid, Time}|T] ->
            if 
                NowTime - Time =< AssistTime ->
                    case dict:is_key(Uid, Arena_dict) of 
                        true ->
                            [Uid_member] = dict:fetch(Uid, Arena_dict),
                            NewAssistNum = Uid_member#arena.assist_num + 1,
                   			{NewScore, AddScore} = data_arena_new:get_assist_score(NewAssistNum, Uid_member#arena.assist_score),
                            New_Uid_Member = Uid_member#arena{
                                assist_num = NewAssistNum,
                                assist_score = NewScore,
                                score = Uid_member#arena.score+AddScore
                            },
                            Temp_Arana_dict = dict:erase(Uid, Arena_dict),
                            New_Arena_dict = dict:append(Uid, New_Uid_Member, Temp_Arana_dict),
                            handle_assist_list(T, NowTime, New_Arena_dict);
                        false ->
                            handle_assist_list(T, NowTime, Arena_dict)
                    end;
                true ->
                    handle_assist_list(T, NowTime, Arena_dict)
            end;
        _ ->
            Arena_dict
    end.

handle_add_anger_timer([], Arena_dict, _AddAnger, _MaxAnger) -> Arena_dict;
handle_add_anger_timer([H|T], Arena_dict, AddAnger, MaxAnger) ->
    case H of 
        {Uid, V} ->
            NewAnger = case V#arena.anger+AddAnger >= MaxAnger of 
                true -> MaxAnger;
                false -> V#arena.anger+AddAnger
            end,
            TempArena = V#arena{anger = NewAnger},
            Temp_Arena_dict = dict:erase(Uid, Arena_dict),
            New_Arena_dict = dict:append(Uid, TempArena, Temp_Arena_dict),
            %% 发送48004协议
            spawn(fun() ->
                Arena_dict_list = dict:to_list(New_Arena_dict),
                Same_Room_Arena = [L || {_, [L]} <- Arena_dict_list,
                                                L#arena.room_lv =:= TempArena#arena.room_lv,
                                                L#arena.room_id =:= TempArena#arena.room_id],
                Sort_Same_Room_Arena = lists:sort(fun(A, B) ->
                    if 
                        A#arena.score > B#arena.score -> true;
                        A#arena.score =:= B#arena.score ->
                            if 
                                A#arena.kill_num > B#arena.kill_num -> true;
                                true -> false
                            end;
                        true -> false
                    end
                end, Same_Room_Arena),
                if 
                    length(Sort_Same_Room_Arena) > 5 ->
                        {Top5List, _} = lists:split(5, Sort_Same_Room_Arena);
                    true -> Top5List = Sort_Same_Room_Arena
                end,
                {ok, BinData} = pt_480:write(48004, [TempArena#arena.score, TempArena#arena.continuous_kill, TempArena#arena.anger, TempArena#arena.kill_num, TempArena#arena.assist_num, TempArena#arena.kill_boss_num, Top5List]),
                lib_unite_send:send_to_uid(Uid, BinData) end),
            handle_add_anger_timer(T, New_Arena_dict, AddAnger, MaxAnger);
        _ ->
            handle_add_anger_timer(T, Arena_dict, AddAnger, MaxAnger)
    end.

%% 取屏幕中间显示的倒计时和类型
get_type_and_time(BossTime, Arena_room, _RemainTime) ->
    {{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
    NowTime = (Hour*60+Minute)*60+Second,
    {NextHour,NextMinute} = Arena_room#arena_room.next_boss_time,
    Killed_Boss_turn = Arena_room#arena_room.killed_boss_turn,
    %% 下一个boss的实际刷新时间
    Next_Boss_Create_Time = (NextHour*60+NextMinute)*60,
    %% 正常的boss刷新时间
    [{Hour1,Minute1},{Hour2,Minute2},{Hour3,Minute3}] = BossTime,
    Create_boss_default_1 = (Hour1*60+Minute1)*60,
    _Create_boss_default_2 = (Hour2*60+Minute2)*60,
    _Create_boss_default_3 = (Hour3*60+Minute3)*60,
    Boss_award = Arena_room#arena_room.boss_award,
    if 
        Killed_Boss_turn =:= 0 andalso NowTime < Create_boss_default_1 -> % 还没到第一个boss的刷新时间
            Type = 0,
            Time = Create_boss_default_1 - NowTime;
        Killed_Boss_turn =:= 0 andalso NowTime >= Create_boss_default_1 -> % 第一个boss已刷新
            Type = Boss_award,
            Time = 0;
        Killed_Boss_turn =:= 1 andalso NowTime < Next_Boss_Create_Time-> % 第一个boss已死，第二个boss还没刷新
            Type = 0,
            Time = Next_Boss_Create_Time - NowTime;
        Killed_Boss_turn =:= 1 andalso NowTime >= Next_Boss_Create_Time  -> % 第二个boss已经刷新
            Type = Boss_award,
            Time = 0;
        Killed_Boss_turn =:= 2 andalso NowTime < Next_Boss_Create_Time -> % 第三个boss还没刷新 
            Type = 0,
            Time = Next_Boss_Create_Time - NowTime;
        Killed_Boss_turn =:= 2 andalso NowTime >= Next_Boss_Create_Time -> % 第三个boss已经刷新
            Type = Boss_award,
            Time = 0;
        Killed_Boss_turn =:= 3 ->   %三个boss都已死亡
            Type = 3,
            Time = 0
    end,
    {Type, Time}.



    