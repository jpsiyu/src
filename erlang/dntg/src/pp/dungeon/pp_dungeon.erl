%%------------------------------------------------------------------------------
%% @Module  : pp_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.4.25
%% @Description: 副本协议处理
%%------------------------------------------------------------------------------


-module(pp_dungeon).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("goods.hrl").
-include("dungeon.hrl").
-include("designation.hrl").


%%离开副本场景
handle(61000, Status, _) ->	
    CopyId = Status#player_status.copy_id,
    PlayerId = Status#player_status.id,
    lib_dungeon:set_logout_type(CopyId, ?DUN_EXIT_CLICK_BUTTON),
    lib_dungeon:quit(CopyId, PlayerId, 4),
    lib_dungeon:clear(role, CopyId),
    case Status#player_status.hp =< 0 of
        true  -> {ok, Status#player_status{hp = round(Status#player_status.hp_lim/3)}};
        false -> skip
    end;
    
%%获取副本时间
handle(61001, Status, SceneId) ->
    case lib_dungeon:get_dungeon_time(SceneId, Status) of
        false ->
            skip;
        {true, Time, Count} ->
            %%发送给客户端副本结束时间
            {ok, BinData} = pt_610:write(61001, [Time, Count]),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end;

%% 特殊副本场景剩余时间
handle(61002, Status, SceneResId) -> 
    case lib_dungeon:get_scene_time(Status#player_status.copy_id, SceneResId) of
        false -> skip;
        {true, Time} ->  
            %%发送给客户端该场景结束时间
            {ok, BinData} = pt_610:write(61002, Time),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end;

%% 获取场景区域
handle(61003, _Status, _SceneId) ->
	ok;
    
%% 获取副本剩余次数
handle(61004, Status, DungeonId) ->
	{DungeonId2, Count, CountLim} = 
		lib_dungeon:get_dungeon_remain_num(Status#player_status.id, 
										   Status#player_status.dailypid,
										   DungeonId),	
	{ok, BinData} = pt_610:write(61004, [DungeonId2, Count, CountLim]),
	lib_server_send:send_one(Status#player_status.socket, BinData);
    
%% 获取所有副本剩余次数.
handle(61005, Status, []) ->
	CountList = lib_dungeon:get_dungeon_all_remain_num(Status#player_status.pid_dungeon_data,
													   Status#player_status.id,
													   Status#player_status.dailypid),
	TotalScore = mod_dungeon_data:get_total_score(Status#player_status.pid_dungeon_data,
													   Status#player_status.id,
													   Status#player_status.dailypid),
	{ok, BinData} = pt_610:write(61005, [TotalScore, CountList]),
	lib_server_send:send_one(Status#player_status.socket, BinData);
     
%% 获取怪物的击杀统计.
handle(61007, Status, SceneId) ->
    Return = 
		case lib_dungeon:get_kill_count(Status#player_status.copy_id, SceneId) of
			{true, MonList} ->  
				[1, MonList];
			 _ ->
				[0, []]
		end,  
   
    %%发送给客户端.
    {ok, BinData} = pt_610:write(61007, Return),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 获取所有副本累计次数.
handle(61008, Status, PlayerId) ->
	%目前只支持查询自己的副本累计次数.
	case PlayerId =:= Status#player_status.id of
		true ->
			lib_dungeon:get_total_count(Status#player_status.pid_dungeon_data, 
										Status#player_status.id);
		false ->
			skip
	end;

%% 获取剧情副本通关奖励.
handle(61009, Status, []) ->
	mod_dungeon_data:get_gift_info(Status#player_status.pid_dungeon_data,
							       Status#player_status.id);

%% 开始剧情副本挂机.
handle(61011, Status, [DungeonId, AutoNum]) ->
    case DungeonId == 0 orelse AutoNum < 0 orelse AutoNum > 10 of
		true ->
			{ok, BinData} = pt_610:write(61011, 0),
			lib_server_send:send_to_uid(Status#player_status.id, BinData);
		false ->
			%1.得到暂存仓库还有物品.
			Chapter = data_story_dun_config:get_chapter_id(DungeonId),
			CanAuto = lib_temp_bag:is_can_store(Status, Chapter),
			
			%2.判断操作间隔时间是否少于15秒.
			%NowTime  = util:unixtime(),
            %LastTime = case get("pp_start_auto_time") of
            %    undefined ->
            %        put("pp_start_auto_time", NowTime),
            %        0;
            %    LastTime1 ->
            %        LastTime1
            %end,
            %PassTime = case NowTime-LastTime >= 15 of
            %    true ->
            %        false;
            %    false ->
            %        true
            %end,

            %% 检查是否有足够的体力值挂机
            OnecePhysicalCost = lib_physical:get_scene_cost(DungeonId),
            AutoCost          = OnecePhysicalCost*AutoNum,
            IsEnoughPhysical  = lib_physical:is_enough_physical(Status, AutoCost),

            if 
                %%1.操作间隔时间少于15秒.
                %PassTime -> 
                %    {ok, BinData} = pt_610:write(61011, 0),
                %    lib_server_send:send_to_uid(Status#player_status.id, BinData);
                %%2.失败，暂存仓库还有物品.
                CanAuto == false -> 
                    {ok, BinData} = pt_610:write(61011, 3),
                    lib_server_send:send_to_uid(Status#player_status.id, BinData);
                IsEnoughPhysical == false ->  
                    {ok, BinData} = pt_610:write(61011, 4),
                    lib_server_send:send_to_uid(Status#player_status.id, BinData);       
                true ->
                    %put("pp_start_auto_time", NowTime),
                    %% 扣除体力值
                    {ok, NewStatus} = lib_physical:cost_physical(Status, AutoCost),
                    mod_dungeon_data:start_auto_story(
                        Status#player_status.pid_dungeon_data,
                        Status#player_status.id, 
                        DungeonId,
                        AutoNum),
                    {ok, NewStatus}
            end
	end;

%% 停止剧情副本挂机.
handle(61012, _Status, []) -> skip;
%%	NowTime = util:unixtime(),
%%    LastTime = 
%%        case get("pp_start_auto_time") of
%%            undefined ->
%%				put("pp_start_auto_time", NowTime),
%%                0;
%%            LastTime1 ->
%%                LastTime1
%%        end,
%%	case NowTime-LastTime >= 15 of
%%		true ->
%%			put("pp_start_auto_time", NowTime),
%%			mod_dungeon_data:stop_auto_story(
%%				Status#player_status.pid_dungeon_data,
%%				Status#player_status.id);
%%		false ->
%%			{ok, BinData} = pt_610:write(61012, 0),
%%			lib_server_send:send_to_uid(Status#player_status.id, BinData)
%%	end;

%% 获取剧情副本挂机信息.
handle(61013, Status, []) ->
	mod_dungeon_data:get_auto_info(Status#player_status.pid_dungeon_data,
							       Status#player_status.id);

%% 领取剧情副本通关奖励.
handle(61010, Status, GiftId) ->
    %% 判断背包是否已满
    GoodsPid = Status#player_status.goods#status_goods.goods_pid,
	DungeonDataPid = Status#player_status.pid_dungeon_data,
	PlayerId = Status#player_status.id,
	
	%%（0不能领取/1未领取/2已领取）.
	GiftState = 
		case mod_dungeon_data:get_gift_state(DungeonDataPid, PlayerId, GiftId) of
			{ok, GiftState1} -> 
				GiftState1;
			_Other1 ->
				0
		end,
	
	ReturnCode =
		if 
			GiftState =:= 1->
				case gen:call(GoodsPid, '$gen_call', {'fetch_gift', Status, GiftId}) of
					{ok, [ok, _NewPS]} ->
							mod_dungeon_data:set_gift_state(DungeonDataPid, 
															PlayerId, 
															GiftId, 
															2),
							1;
					{ok, [error, ErrorCode]} ->
						case ErrorCode of
							105 -> %背包格子不足.
								2;
							_Other2 ->
								0
						end
				end;
			true ->
				0
		end,
	
	{ok, BinData} = pt_610:write(61010, ReturnCode),
	lib_server_send:send_one(Status#player_status.socket, BinData);


%% 封魔称号查看
handle(61015, Status, _Data) ->
    List = lib_story_dungeon:get_story_designation(Status),
    {ok, BinData} = pt_610:write(61015, [List]),
    lib_server_send:send_one(Status#player_status.socket, BinData);


%% 封魔称号激活
handle(61016, Status, _Data) ->
    Result = lib_story_dungeon:set_story_designation(Status),
    %% io:format("~p ~p Result:~p~n", [?MODULE, ?LINE, Result]),
    {NewPS, Code}  = case Result of
                        {NewState, ErrorCode} -> {NewState, ErrorCode};
                        {NewState, _DesignId, IsDisplay, ErrorCode} ->
                            if
                                IsDisplay =:= 1 ->
%%                                     case lib_designation:set_display(NewState, DesignId) of
%%                                         {error, _ErrorCode} -> 
%%                                             %% io:format("~p ~p _ErrorCode:~p~n", [?MODULE, ?LINE, _ErrorCode]),
%%                                             {NewState, ErrorCode};
%%                                         {ok, NewPS1} -> {NewPS1, ErrorCode}
%%                                     end;
                                    {NewState, ErrorCode};
                                true ->
                                    {NewState, ErrorCode}
                            end
                     end,
    if
        Code =:= 1 ->
            NewPS2 = lib_player:count_player_attribute(NewPS),
            lib_player:send_attribute_change_notify(NewPS2, 4),
            NewPS2;
        true ->
            NewPS2 = NewPS
    end,
    {ok, BinData} = pt_610:write(61016, [Code]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    handle(61015, NewPS2, []),
    {ok, NewPS2};
   


%% 连连看副本开始刷怪.
handle(61040, Status, _) ->
    DungeonType = lib_dungeon:get_dungeon_type(Status#player_status.scene),
    case DungeonType of
        ?DUNGEON_TYPE_LIAN ->
			lib_lian_dungeon:init_create_mon(Status#player_status.copy_id);
		_ ->
			skip
	end;

%% 连连看副本更新积分.
handle(61041, Status, _) ->
    DungeonType = lib_dungeon:get_dungeon_type(Status#player_status.scene),
    case DungeonType of
        ?DUNGEON_TYPE_LIAN ->
			lib_lian_dungeon:get_score(Status#player_status.copy_id);
		_ ->
			skip
	end;

%% 连连看副本清怪.
handle(61044, Status, _) ->
    DungeonType = lib_dungeon:get_dungeon_type(Status#player_status.scene),
    case DungeonType of
        ?DUNGEON_TYPE_LIAN ->
			lib_lian_dungeon:clear_mon(Status#player_status.copy_id);
		_ ->
			skip
	end;

%% 新版钱多多副本副本信息
handle(61050, #player_status{id = Id, copy_id = DungeonPid} = _Status, []) -> 
    case is_pid(DungeonPid) of
        true -> gen_server:cast(DungeonPid, {'coin_dungeon_state', Id});
        false -> ok
    end;

%% 结束钱多多副本抽奖
handle(61052, #player_status{id = Id, copy_id = DungeonPid, pid = Pid} = _Status, []) -> 
    case is_pid(DungeonPid) of
        true -> 
            DungeonPid ! {'coin_create', Id, Pid},
            ok;
        false -> ok
    end;

%% 拾取金币倒计时结束
handle(61055, #player_status{copy_id = DungeonPid} = _Status, []) -> 
    case is_pid(DungeonPid) of
        true -> 
            DungeonPid ! 'coin_dungeon_next_level',
            ok;
        false -> ok
    end;
        
%% 活动副本得到积分.
handle(61060, Status, []) -> 
	DungeonPid = Status#player_status.copy_id,
	PlayerId = Status#player_status.id,	
    case is_pid(DungeonPid) of
        true -> 
			DungeonPid ! {'activity_dun_get_score', PlayerId},
            ok;
        false -> ok
    end;

%% 更新积分.
handle(61070, Status, []) ->
	DungeonPid = Status#player_status.copy_id,
	PlayerId = Status#player_status.id,	
    case is_pid(DungeonPid) of
        true -> 
			DungeonPid ! {'fly_dun_get_score', PlayerId},
            ok;
        false -> ok
    end;

%% 更新星星.
handle(61071, Status, []) ->
	DungeonPid = Status#player_status.copy_id,
	PlayerId = Status#player_status.id,	
    case is_pid(DungeonPid) of
        true -> 
			DungeonPid ! {'fly_dun_get_star', PlayerId},
            ok;
        false -> ok
    end;

%% 查询难度.
handle(61072, Status, []) ->
	DungeonDataPid = Status#player_status.pid_dungeon_data,
	PlayerId = Status#player_status.id,	
    case is_pid(DungeonDataPid) of
        true -> 
			gen_server:call(DungeonDataPid , {'fly_dun_get_level', PlayerId}),
            ok;
        false -> ok
    end;

%% 得到计时.
handle(61073, Status, []) ->	
	DungeonPid = Status#player_status.copy_id,
	PlayerId = Status#player_status.id,
	SceneId = Status#player_status.scene,
    case is_pid(DungeonPid) of
        true -> 
			DungeonPid ! {'fly_dun_get_time', PlayerId, SceneId},
            ok;
        false -> ok
    end;

%% 更新阴阳BOSS值.
handle(61074, Status, []) ->
	DungeonPid = Status#player_status.copy_id,
	PlayerId = Status#player_status.id,	
    case is_pid(DungeonPid) of
        true -> 
			DungeonPid ! {'fly_dun_get_yin_yang', PlayerId},
            ok;
        false -> ok
    end;

%% 获取情缘副本tips
handle(61100, Status, []) ->
    case mod_pet_dungeon:get_appoint_dungeon_tips(Status#player_status.copy_id) of
        [] -> skip;
        MonNameList -> 
            {ok, BinData} = pt_611:write(61100, MonNameList),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end;

%% 获取宠物副本想法信息
handle(61101, Status, []) ->
	mod_pet_dungeon:get_pet_dungeon_think(Status#player_status.copy_id);

%% 获取宠物副本配置信息
handle(61102, Status, []) ->
    {ok, BinData} = pt_611:write(61102, [20]),     
     lib_server_send:send_one(Status#player_status.socket, BinData);


%% erengy精力副本开启的列表信息
handle(61171, Status, _) ->
    mod_dungeon_data:get_equip_energy_list_cast(Status#player_status.pid_dungeon_data, Status#player_status.id);
    

%% 转盘抽取
handle(61173, Status, [DungeonId, Type]) ->
    if
        Type =:= 2 ->
            DunGiftRecord = data_equip_gift:get_gift(DungeonId),
            if
                DunGiftRecord =:= [] ->
                    {ok, BinData} = pt_611:write(61173, [6, [], 0, 0]),
                    lib_server_send:send_one(Status#player_status.socket, BinData),
                    {ok, Status};
                true ->
                    Gold = DunGiftRecord#dntk_equip_dun_config.gold,
                    if
                        Status#player_status.bgold < Gold ->
                            if
                                Status#player_status.bgold + Status#player_status.gold < Gold ->
                                    {ok, BinData} = pt_611:write(61173, [3, [], 0, 0]),
                                    lib_server_send:send_one(Status#player_status.socket, BinData),
                                    {ok, Status};
                                true ->
                                    NewStatus = lib_goods_util:cost_money(Status, Gold, silver_and_gold),
                                    %% 写消费日志
                                    About = lists:concat([NewStatus#player_status.id," gold equip extract goods ",
                                                          NewStatus#player_status.scene]),
                                    log:log_consume(equip_extraction_goods, gold, Status, NewStatus, About),
                                    lib_player:refresh_client(NewStatus),
                                    lib_equip_energy_dungeon:extraction_goods(NewStatus#player_status.copy_id, DungeonId, Type),
                                    {ok, NewStatus}
                            end;
                        true ->
                            NewStatus = lib_goods_util:cost_money(Status, Gold, bgold),
                            %% 写消费日志
                            About = lists:concat([NewStatus#player_status.id," gold equip extraction goods ",Status#player_status.scene]),
                            log:log_consume(equip_extraction_goods, bgold, Status, NewStatus, About),
                            lib_player:refresh_client(NewStatus),
                            lib_equip_energy_dungeon:extraction_goods(NewStatus#player_status.copy_id, DungeonId, Type),
                            {ok, NewStatus}
                    end
            end;
        Type =:= 1 ->
            lib_equip_energy_dungeon:extraction_goods(Status#player_status.copy_id, DungeonId, Type),
            {ok, Status};
        true ->
            {ok, BinData} = pt_611:write(61173, [4, [], 0, 0]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            {ok, Status}         
    end;

%%副本再来一次
handle(61174, Status, _) -> 
    CopyId = Status#player_status.copy_id,
    PlayerId = Status#player_status.id,
    lib_dungeon:set_logout_type(CopyId, ?DUN_EXIT_CLICK_BUTTON_TRY_AGAIN),
    lib_dungeon:quit(CopyId, PlayerId, 4),
    lib_dungeon:clear(role, CopyId);

%% 默认匹配
handle(_Cmd, _Status, _Data) ->
    util:errlog("~p ~p pp_dungeon no match:cmd:~p, data:~p~n", [?MODULE, ?LINE, _Cmd, _Data]),
    {error, "pp_dungeon no match"}.

