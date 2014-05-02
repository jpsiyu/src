%%%--------------------------------------
%%% @Module  : pp_wubianhai
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.7.7
%%% @Description:  大闹天宫(无边海)
%%%--------------------------------------

-module(pp_wubianhai).
-compile(export_all).
-include("common.hrl").
-include("unite.hrl").
-include("server.hrl").

%% 进入 退出战场
handle(64002, PlayerStatus, [Res, _RoomLv, RoomId]) ->
	%io:format("recv 64002~n"),
	%% Res: 1进入  2退出
    %% 只分配10个房间
    MaxRoom = mod_exit:lookup_max_room(wubianhai),
    MaxRoom2 = case MaxRoom > 0 of
        true -> MaxRoom;
        false -> 1
    end,
    [Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute] = PlayerStatus#player_status.wubianhai_time,
    case (Res =:= 1 andalso RoomId >= 1 andalso RoomId =< MaxRoom2) orelse (Res =:= 2) of
        true ->
            case lib_wubianhai_new:is_opening(Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute) =:= true orelse Res =:= 2 of
                true ->
                    case Res of
                        1 -> 
                            [Error, ErrorData, NewStatus] = lib_wubianhai_new:execute_64002(PlayerStatus, Res, RoomId),
                            case Error of
                                1 -> WorldLv = mod_wubianhai_new:get_world_lv(),
                                    PhaseHp = data_wubianhai_new:get_phase_hp(WorldLv),
                                    PhaseAtt = 650;
                                _ -> PhaseHp = 0,
                                    PhaseAtt = 0
                            end;
                        _ -> 
                            PhaseHp = 0,
                            PhaseAtt = 0,
                            [Error, ErrorData, NewStatus] = lib_wubianhai_new:execute_64002(PlayerStatus, Res, RoomId)
                    end,
                    {ok, BinData} = pt_640:write(64002, [Error, 1, ErrorData]);
                false -> 
                    PhaseHp = 0,
                    PhaseAtt = 0,
                    NewStatus = PlayerStatus,
                    {ok, BinData} = pt_640:write(64002, [9, 1, ""])
            end;
        false -> 
            PhaseHp = 0,
            PhaseAtt = 0,
            NewStatus = PlayerStatus,
            {ok, BinData} = pt_640:write(64002, [6, 1, ""])
    end,
    %io:format("64002:~p~n", [BinData]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    NewStatus1 = NewStatus#player_status{wubianhai_buff = [PhaseHp, PhaseHp, PhaseAtt]},
    NewStatus2 = lib_player:count_player_attribute(NewStatus1),
    lib_player:send_attribute_change_notify(NewStatus2, 0),
    {ok, wubianhai, NewStatus2};

%% 任务信息
handle(64003, UniteStatus, _Bin) ->
    lib_wubianhai_new:execute_64003(UniteStatus);

%% 领取奖励
handle(64004, UniteStatus, Res) ->
    case Res >= 1 andalso Res =< 6 of
        true ->
            %io:format("recv 64004~n"),
            lib_wubianhai_new:execute_64004(UniteStatus, Res, UniteStatus#unite_status.scene);
        false -> 
            skip
    end;

%% 队伍进入南天门
handle(64009, PlayerStatus, [_RoomLv, RoomId]) ->
    MaxRoom = mod_exit:lookup_max_room(wubianhai),
    MaxRoom2 = case MaxRoom > 0 of
        true -> MaxRoom;
        false -> 1
    end,
    case RoomId >= 1 andalso RoomId =< MaxRoom2 of
        true ->
            %io:format("recv 64009~n"),
            [Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute] = PlayerStatus#player_status.wubianhai_time,
            case lib_wubianhai_new:is_opening(Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute) of
                true ->
                    [Error, ErrorData, NewStatus] = lib_wubianhai_new:execute_64009(PlayerStatus, RoomId),
                    case Error of
                        1 ->
                            WorldLv = mod_wubianhai_new:get_world_lv(),
                            PhaseHp = data_wubianhai_new:get_phase_hp(WorldLv),
                            PhaseAtt = 650;
                        _ ->
                            PhaseHp = 0,
                            PhaseAtt = 0
                    end,
                    {ok, BinData} = pt_640:write(64002, [Error, 1, ErrorData]);
                false -> 
                    PhaseHp = 0,
                    PhaseAtt = 0,
                    NewStatus = PlayerStatus,
                    {ok, BinData} = pt_640:write(64002, [9, 1, ""])
            end;
        false -> 
            PhaseHp = 0,
            PhaseAtt = 0,
            NewStatus = PlayerStatus,
            {ok, BinData} = pt_640:write(64002, [6, 1, ""])
    end,
    %io:format("64009:~p~n", [BinData]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    NewStatus1 = NewStatus#player_status{wubianhai_buff = [PhaseHp, PhaseHp, PhaseAtt]},
    NewStatus2 = lib_player:count_player_attribute(NewStatus1),
    lib_player:send_attribute_change_notify(NewStatus2, 0),
    {ok, wubianhai, NewStatus2};

%% 获取南天门房间信息
handle(64011, PlayerStatus, _Bin) ->
	%io:format("recv 64011~n"),
    [Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute] = PlayerStatus#player_status.wubianhai_time,
    %io:format("time:~p~n", [[Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute]]),
    case lib_wubianhai_new:is_opening(Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute) of
        true ->
            SceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
            List = mod_daily_dict:get_room(wubianhai, SceneId),
            AllNum = lists:foldl(fun({_, N},C)-> N+C end, 0, List),
			Limit = data_wubianhai_new:get_wubianhai_config(room_new_num),
            _Room = AllNum div Limit + 1,
            MaxRoom = mod_exit:lookup_max_room(wubianhai),
            %% 记录曾经开过的最大房间数
            Room = case MaxRoom > _Room of
                true -> MaxRoom;
                false -> 
                    mod_exit:insert_max_room(wubianhai, _Room),
                    _Room
            end,
			%NewList = lists:map(fun({Id, Num}) -> 
			%	<<1:8, Id:8, Num:16, Limit:16>>  
            %end, lists:sublist(List, Room)),
            RoomList = lists:sublist(List, Room),
            Bin = pack2(RoomList),
			{ok, BinData} = pt_640:write(64011, Bin);
        false -> 
            Bin = pack2([]),
            {ok, BinData} = pt_640:write(64011, Bin)
    end,
	%io:format("64011:~p~n", [BinData]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

handle(_Cmd, _LogicStatus, _Data) ->
    ?DEBUG("pp_wubianhai no match", []),
    {error, "pp_wubianhai no match"}.

pack(List1, BossRefresh, RestTime, RoomId, List2) ->
	%% List1
    Fun1 = fun(Elem1) ->
				{Id1, Wupin, CNum, ANum, KillName, NowKill, KillNum, GetAward, AwardWupin, Exp, Lilian, MonId, MonX, MonY} = Elem1,
				Wupin1 = list_to_binary(Wupin),
				WL     = byte_size(Wupin1),
				KillName1 = list_to_binary(KillName),
				KL        = byte_size(KillName1),
				AwardWupin1 = list_to_binary(AwardWupin),
				WL1     = byte_size(AwardWupin1),
				<<Id1:32, WL:16, Wupin1/binary, CNum:16, ANum:16, KL:16, KillName1/binary, NowKill:16, KillNum:16, GetAward:8, WL1:16, AwardWupin1/binary, Exp:32, Lilian:32, MonId:32, MonX:16, MonY:16>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List1]),
    Size1  = length(List1),
	%% List2
	Fun2 = fun(Elem2) ->
				<<Elem2:32>>
    end,
    BinList2 = list_to_binary([Fun2(X) || X <- List2]),
    Size2  = length(List2),
    <<Size1:16, BinList1/binary, BossRefresh:32, RestTime:32, RoomId:8, Size2:16, BinList2/binary>>.


pack1(Error, AwardList) ->
	%% List1
    Fun1 = fun(Elem1) ->
				<<Elem1:32>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- AwardList]),
    Size1  = length(AwardList),
    <<Error:8, Size1:16, BinList1/binary>>.

pack2(RoomList) ->
    MaxNum = data_wubianhai_new:get_wubianhai_config(room_max_num),
	%% List1
    Fun1 = fun(Elem1) ->
                {RoomId, NowNum} = Elem1,
                case NowNum > MaxNum of
                    true -> <<1:8, RoomId:8, MaxNum:16, MaxNum:16>>;
                    false -> <<1:8, RoomId:8, NowNum:16, MaxNum:16>>
                end
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- RoomList]),
    Size1  = length(RoomList),
    <<Size1:16, BinList1/binary>>.
