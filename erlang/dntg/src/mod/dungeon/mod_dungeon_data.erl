%%------------------------------------------------------------------------------
%% @Module  : mod_dungeon_data
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.8.6
%% @Description: 单个玩家的副本数据管理，在游戏线。
%%------------------------------------------------------------------------------

-module(mod_dungeon_data).
-behaviour(gen_server).
-include("dungeon.hrl").
-include("sql_rank.hrl").

-export([start_link/0, stop/0, init/1, 
		 handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


-export([
	     set_dungeon_log/2,       %% 设置副本日志.
         get_dungeon_log/1,       %% 获取副本日志.
         get_one_dungeon_log/3,   %% 获取副本日志(单个)
	     set_tower_reward/2,      %% 设置爬塔副本奖励.
         get_tower_reward/1,      %% 获取爬塔副本奖励.
		 online/2,                %% 上线读取配置.
		 get_total_count/3,       %% 获取进入副本总次数.
         increment_total_count/3, %% 更新进入副本总次数.
		 get_cooling_time/3,      %% 获取副本冷却时间.
		 get_total_score/3,       %% 获取副本总积分.
		 count_base_attribute/4,  %% 获取副本总积分得到的属性加成.
         set_cooling_time/3,      %% 更新副本冷却时间.
		 clear_cooling_time/3,    %% 清空副本冷却时间.
		 get_record_level/3,	  %% 获取副本通关等级.
         set_record_level/5,      %% 更新副本通关等级.
		 save_story_total_score/6,%% 保存剧情副本总积分.
		 get_gift_info/2,	      %% 获取副本通关礼包信息.
		 get_gift_state/3,        %% 获取副本通关礼包状态.
		 set_gift_state/4,	      %% 设置副本通关礼包状态.
	     start_auto_story/4,      %% 开始剧情副本挂机.
	     stop_auto_story/2,	      %% 停止剧情副本挂机.
		 get_auto_info/2,	      %% 获取剧情副本挂机信息.
		 is_auto_story/3,	      %% 是否在挂机中.
		 get_equip_energy_list_cast/2,  	%% cast获取装备副本列表
         get_equip_energy_list_call/2,      %% call获取装备副本列表
         get_equip_energy_is_gift/3,      %% call获取装备副本列表
		 set_equip_energy_list/3	%% 更新装备副本信息
]).

%% --------------------------------- 公共函数 ----------------------------------


%% 启动服务器
start_link() ->
	gen_server:start_link(?MODULE, [], []).

%% 停止服务器
stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

%% 设置副本日志.
set_dungeon_log(DungeonDataPid, DungeonLog)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid) of
	    false -> 
			skip;
	    true -> 
	        gen_server:cast(DungeonDataPid, {'set_dungeon_log', DungeonLog})
    end.

%% 获取副本日志.
get_dungeon_log(DungeonDataPid)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			[];
	    true -> 
	        gen_server:call(DungeonDataPid, 'get_dungeon_log')
    end.

%% 获取副本日志(单个).
get_one_dungeon_log(DungeonDataPid, PlayerId, DunId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
        false -> 
            [];
        true -> 
            gen_server:call(DungeonDataPid, {get_one_dungeon_log, PlayerId, DunId})
    end.

%% 设置爬塔副本奖励.
set_tower_reward(DungeonDataPid, TowerReward)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:call(DungeonDataPid, {'set_tower_reward', TowerReward})
    end.

%% 获取爬塔副本奖励.
get_tower_reward(DungeonDataPid)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			[];
	    true -> 
	        gen_server:call(DungeonDataPid, 'get_tower_reward')
    end.

%% 上线读取配置.
online(DungeonDataPid, PlayerId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			[];
	    true -> 
	        gen_server:cast(DungeonDataPid, {'online', PlayerId})
    end.

%% 更新进入副本总次数.
increment_total_count(DungeonDataPid, PlayerId, DungeonId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:cast(DungeonDataPid, {'increment_total_count', PlayerId, DungeonId})
    end.

%% 获取进入副本总次数.
get_total_count(DungeonDataPid, PlayerId, DungeonId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			0;
	    true -> 
	        gen_server:call(DungeonDataPid, {'get_total_count', PlayerId, DungeonId})
    end.

%% 更新副本冷却时间.
set_cooling_time(DungeonDataPid, PlayerId, DungeonId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:call(DungeonDataPid, {'set_cooling_time', PlayerId, DungeonId})
    end.

%% 清空副本冷却时间.
clear_cooling_time(DungeonDataPid, PlayerId, DungeonId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:call(DungeonDataPid, {'clear_cooling_time', PlayerId, DungeonId})
    end.

%% 获取副本冷却时间.
get_cooling_time(DungeonDataPid, PlayerId, DungeonId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			{0,0,0};
	    true -> 
	        gen_server:call(DungeonDataPid, {'get_cooling_time', PlayerId, DungeonId})
    end.

%% 获取副本总积分.
get_total_score(DungeonDataPid, PlayerId, DungeonId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			0;
	    true -> 
	        gen_server:call(DungeonDataPid, {'get_total_score', PlayerId, DungeonId})
    end.

%% %% 获取副本总积分得到的属性加成.
%% count_base_attribute(DungeonDataPid, PlayerId, DungeonId)->
%%     case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
%%      false -> 
%%          [0,0];
%%      true ->
%%          gen_server:call(DungeonDataPid, {'count_base_attribute', PlayerId, DungeonId})
%%     end.

%% 获取副本总积分得到的属性加成.
count_base_attribute(DungeonDataPid, PlayerId, DungeonId, Designation)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
        false -> 
            [0,0,0];
        true ->
            gen_server:call(DungeonDataPid, {'count_base_attribute', PlayerId, DungeonId, Designation})
    end.

%% 更新副本通关等级.
set_record_level(DungeonDataPid, PlayerId, DungeonId, RecordLevel, TotalTime)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:cast(DungeonDataPid, {'set_record_level', PlayerId, DungeonId, RecordLevel, TotalTime})
    end.

%% 保存剧情副本总积分.
save_story_total_score(DungeonDataPid, PlayerId, PlayerName, PlayerSex, PlayerCareer, DungeonId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:cast(DungeonDataPid, {'save_story_total_score', PlayerId, PlayerName, PlayerSex, PlayerCareer, DungeonId})
    end.

%% 获取副本通关等级.
get_record_level(DungeonDataPid, PlayerId, DungeonId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			0;
	    true -> 
	        gen_server:call(DungeonDataPid, {'get_record_level', PlayerId, DungeonId})
    end.

%% 是否在挂机中.
is_auto_story(DungeonDataPid, PlayerId, DungeonId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			0;
	    true -> 
	        gen_server:call(DungeonDataPid, {'is_auto_story', PlayerId, DungeonId})
    end.

%% 获取副本通关礼包信息.
get_gift_info(DungeonDataPid, PlayerId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:cast(DungeonDataPid, {'get_gift_info', PlayerId})
    end.

%% 查询副本通关礼包状态.
get_gift_state(DungeonDataPid, PlayerId, GiftId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:call(DungeonDataPid, {'get_gift_state', PlayerId, GiftId})
    end.

%% 设置副本通关礼包状态.
set_gift_state(DungeonDataPid, PlayerId, GiftId, GiftState)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:cast(DungeonDataPid, {'set_gift_state', PlayerId, GiftId, GiftState})
    end.

%% 开始剧情副本挂机.
start_auto_story(DungeonDataPid, PlayerId, DungeonId, AutoNum)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:cast(DungeonDataPid, {'start_auto_story', PlayerId, DungeonId, AutoNum})
    end.

%% 停止剧情副本挂机.
stop_auto_story(DungeonDataPid, PlayerId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:cast(DungeonDataPid, {'stop_auto_story', PlayerId})
    end.

%% 获取剧情副本挂机信息.
get_auto_info(DungeonDataPid, PlayerId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			skip;
	    true -> 
	        gen_server:cast(DungeonDataPid, {'get_auto_info', PlayerId})
    end.

%% 获取装备副本的数据
get_equip_energy_list_cast(DungeonDataPid, PlayerId)->
    %% io:format("~p ~p ~n", [?MODULE, ?LINE]),
	case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			[];
	    true -> 
	        gen_server:cast(DungeonDataPid, {'get_equip_energy_list_cast', PlayerId})
    end.

%% 获取装备副本的数据
get_equip_energy_list_call(DungeonDataPid, PlayerId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
        false -> 
            [];
        true -> 
            gen_server:call(DungeonDataPid, {'get_equip_energy_list_call', PlayerId})
    end.

%% 获取当前装备副本是否通关
get_equip_energy_is_gift(DungeonDataPid, PlayerId, DunId)->
    case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
        false -> 
            0;
        true -> 
            gen_server:call(DungeonDataPid, {'get_equip_energy_is_gift', PlayerId, DunId})
    end.

%% 更新装备副本的数据
set_equip_energy_list(DungeonDataPid, PlayerId, EquipLogList)->
	case is_pid(DungeonDataPid) andalso misc:is_process_alive(DungeonDataPid)of
	    false -> 
			[];
	    true -> 
	        gen_server:cast(DungeonDataPid, {'set_equip_energy_list', PlayerId, EquipLogList})
    end.

%% --------------------------------- 内部函数 ----------------------------------


%% 启动服务器.
init([]) ->
    {ok, ?MODULE}.

%% 获取副本日志.
handle_call('get_dungeon_log', _From, State) ->
	 case get("dungeon_log") of
		 undefined ->
		     {reply, [], State};
		 DungeonLog ->
		     {reply, [DungeonLog], State}
     end;


%% 获取副本日志(单个).
handle_call({get_one_dungeon_log, PlayerId, DunId}, _From, State) ->
     {reply, lib_dungeon_log:get(PlayerId, DunId), State};


%% 获取爬塔副本奖励.
handle_call('get_tower_reward', _From, State) ->
	 case get("tower_reward") of
		 undefined ->
		     {reply, [], State};
		 TowerReward ->
		     {reply, [TowerReward], State}
     end;

%% 设置爬塔副本奖励.
handle_call({'set_tower_reward', TowerReward}, _From, State) ->
	put("tower_reward", TowerReward),
	{reply, ok, State};

%% 获取进入副本总次数.
handle_call({'get_total_count', PlayerId, DungeonId}, _From, State) ->
	{reply, lib_dungeon_log:get_count(PlayerId, DungeonId), State};

%% 获取副本冷却时间.
handle_call({'get_cooling_time', PlayerId, DungeonId}, _From, State) ->
	{reply, lib_dungeon_log:get_cooling_time(PlayerId, DungeonId), State};

%% 获取副本总积分.
handle_call({'get_total_score', PlayerId, DungeonId}, _From, State) ->
	{reply, lib_story_dungeon:get_total_score(PlayerId, DungeonId), State};

%% 获取副本总积分得到的属性加成.
%% handle_call({'count_base_attribute', PlayerId, DungeonId}, _From, State) ->
%%  {reply, lib_story_dungeon:count_base_attribute(PlayerId, DungeonId), State};
handle_call({'count_base_attribute', PlayerId, DungeonId, Designation}, _From, State) ->
    {reply, lib_story_dungeon:count_base_attribute_desigenation(PlayerId, DungeonId, Designation), State};

%% 设置副本冷却时间.
handle_call({'set_cooling_time', PlayerId, DungeonId}, _From, State) ->
	lib_dungeon_log:set_cooling_time(PlayerId, DungeonId),
	{reply, ok, State};

%% 清空副本冷却时间.
handle_call({'clear_cooling_time', PlayerId, DungeonId}, _From, State) ->
	lib_dungeon_log:clear_cooling_time(PlayerId, DungeonId),
	{reply, ok, State};

%% 获取副本通关等级.
handle_call({'get_record_level', PlayerId, DungeonId}, _From, State) ->	
	{reply, lib_dungeon_log:get_record_level(PlayerId, DungeonId), State};

%% 获取副本通关礼包状态.
handle_call({'get_gift_state', PlayerId, GiftId}, _From, State) ->
	GiftState = lib_story_dungeon:get_gift_state(PlayerId, GiftId),
	{reply, {ok, GiftState}, State};

%% 是否在挂机中.
handle_call({'is_auto_story', PlayerId, DungeonId}, _From, State) ->	
	{reply, lib_auto_story_dungeon:is_auto_story(PlayerId, DungeonId), State};

%% 得到飞行副本难度.
handle_call({'fly_dun_get_level', PlayerId}, _From, State) ->
	Level = 
    case get("fly_dun_level") of
        undefined ->
			Sql1 = io_lib:format(?sql_select_rank_fly_dungeon,[PlayerId]),
			Level2 =
				case catch db:get_row(Sql1) of
					[Level3, _Star, _Time] ->
						Level3;
					_ ->
						1
				end,
			put("fly_dun_level", Level2),
			get("fly_dun_level");
        _Level -> 
			_Level
    end,

	{ok, BinData} = pt_610:write(61072, [Level]),
	lib_server_send:send_to_uid(PlayerId, BinData),
	{reply, Level, State};

 %% 获取装备副本列表.
handle_call({'get_equip_energy_list_call', PlayerId}, _From, State) ->
	EquipLogList = lib_equip_energy_dungeon:get_equip_energy_list_call(PlayerId),
	{reply, EquipLogList, State};


 %% 获取装备副本列表.
handle_call({'get_equip_energy_is_gift', PlayerId, DunId}, _From, State) ->
    EquipLogList = lib_equip_energy_dungeon:get_equip_energy_list_call(PlayerId),
    OneLog = lib_equip_energy_dungeon:get_one_dun_log_record(PlayerId, DunId, EquipLogList),
    IsGift = case OneLog of
                [] -> 0;
                _ ->  OneLog#dntk_equip_dun_log.is_kill_boss
             end,     
    {reply, IsGift, State};

%% 默认匹配
handle_call(Event, _From, State) ->
    catch util:errlog("mod_dungeon_data:handle_call not match: ~p", [Event]),
    {reply, ok, State}.

%% 设置进入副本总次数.
handle_cast({'increment_total_count', PlayerId, DungeonId}, State) ->
	lib_dungeon_log:increment(PlayerId, DungeonId),
	{noreply, State};

%% 设置副本日志.
handle_cast({'set_dungeon_log', DungeonLog}, State) ->
	put("dungeon_log", DungeonLog),
    {noreply, State};

%% 上线读取配置.
handle_cast({'online', PlayerId}, State) ->
	lib_dungeon_log:online(PlayerId),
    lib_equip_energy_dungeon:online(PlayerId),
	erlang:send_after(1*200, self(), {'auto_story_login_init', PlayerId}),
	{noreply, State};

%% 设置副本通关等级.
handle_cast({'set_record_level', PlayerId, DungeonId, RecordLevel, TotalTime}, State) ->
	lib_dungeon_log:set_record_level(PlayerId, DungeonId, RecordLevel, TotalTime),
	{noreply, State};

%% 保存剧情副本总积分.
handle_cast({'save_story_total_score', PlayerId, PlayerName, PlayerSex, PlayerCareer, DungeonId}, State) ->
	lib_story_dungeon:save_story_total_score(PlayerId, PlayerName, PlayerSex, PlayerCareer, DungeonId),
	{noreply, State};

%% 获取副本通关礼包信息.
handle_cast({'get_gift_info', PlayerId}, State) ->
	lib_story_dungeon:get_gift_info(PlayerId),
	{noreply, State};

%% 设置副本通关礼包状态.
handle_cast({'set_gift_state', PlayerId, GiftId, GiftState}, State) ->
	lib_story_dungeon:set_gift_state(PlayerId, GiftId, GiftState),
	{noreply, State};

%% 开始剧情副本挂机.
handle_cast({'start_auto_story', PlayerId, DungeonId, AutoNum}, State) ->
	lib_auto_story_dungeon:start_auto(PlayerId, DungeonId, AutoNum),
	lib_auto_story_dungeon:set_next_calc_time(self(), PlayerId),
	{noreply, State};

%% 停止剧情副本挂机.
handle_cast({'stop_auto_story', PlayerId}, State) ->
	lib_auto_story_dungeon:stop_auto(PlayerId),
	{noreply, State};

%% 获取剧情副本挂机信息.
handle_cast({'get_auto_info', PlayerId}, State) ->
	lib_auto_story_dungeon:get_auto_info(PlayerId),
    {noreply, State};

%% 更新装备副本的内存数据
handle_cast({'set_equip_energy_list', PlayerId, EquipLogList}, State)->
    erase(?DUNGEON_EQUIP_LOG_KEY(PlayerId)),
    put(?DUNGEON_EQUIP_LOG_KEY(PlayerId), EquipLogList),
    {noreply, State};

 %% 获取装备副本列表.
handle_cast({'get_equip_energy_list_cast', PlayerId}, State) ->
    %% io:format("~p ~p ~n", [?MODULE, ?LINE]),
    lib_equip_energy_dungeon:get_equip_energy_list_cast(PlayerId),
    {noreply, State};

%% 默认匹配
handle_cast(Event, State) ->
    catch util:errlog("mod_dungeon_data:handle_cast not match: ~p", [Event]),
    {noreply, State}.

%% 剧情副本自动挂机上线初始化.
handle_info({'auto_story_login_init', PlayerId}, State) ->
	lib_auto_story_dungeon:login_init(PlayerId),
	lib_auto_story_dungeon:set_next_calc_time(self(), PlayerId),	
    {noreply, State};

%% 剧情副本自动挂机结算.
handle_info({'calc_auto_story_dungeon', PlayerId}, State) ->
	lib_auto_story_dungeon:calc_auto(PlayerId),
	lib_auto_story_dungeon:set_next_calc_time(self(), PlayerId),
    {noreply, State};

%% 默认匹配
handle_info(Info, State) ->
    catch util:errlog("mod_dungeon_data:handle_info not match: ~p", [Info]),
    {noreply, State}.

%% 服务器停止.
terminate(_R, _State) ->
	%% 清除剧情副本自动挂机结算定时器.
    case get("calc_auto_story_dungeon")of
        undefined  ->
            skip;
        RefreshTimer ->
			if 
				is_reference(RefreshTimer) ->
					erlang:cancel_timer(RefreshTimer);
				true ->
					skip
			end
    end,
    ok.

%% 热代码替换.
code_change(_OldVsn, State, _Extra)->
    {ok, State}.
