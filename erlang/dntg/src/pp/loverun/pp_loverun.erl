%%%--------------------------------------
%%% @Module  : pp_loverun
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.8.21
%%% @Description:  爱情长跑
%%%--------------------------------------

-module(pp_loverun).
-compile(export_all).
-include("common.hrl").
-include("server.hrl").
-include("unite.hrl").

%% 活动剩余时间
handle(34300, UniteStatus, _Bin) ->
    %io:format("recv 34300 : ~p~n", [time()]),
    [{Year1, Month1, Day1}, {Year2, Month2, Day2}] = data_loverun_time:get_loverun_time(activity_date),
    case date() >= {Year1, Month1, Day1} andalso date() =< {Year2, Month2, Day2} of
        false -> 
            Time = 0;
        true ->
            %% 记录活动开始时间
            [BeginHour, BeginMin, EndHour, EndMin, ApplyTime] = UniteStatus#unite_status.loverun_data,
            case lib_loverun:is_opening(BeginHour, BeginMin, EndHour, EndMin, ApplyTime) of
                true ->
                    case UniteStatus#unite_status.lv >= 38 of
                        true ->
                            {Hour, Min, Sec} = time(),
                            %% 做个容错处理
                            case misc:whereis_name(global, mod_loverun) of
                                _Pid when is_pid(_Pid) ->
                                    {_BeginTime, _BeginMin, EndTime, EndMin} = {BeginHour, BeginMin, EndHour, EndMin},
                                    Time0 = (EndTime * 60 * 60 + EndMin * 60) - (Hour * 60 * 60 + Min * 60 + Sec),
                                    case Time0 > 0 of
                                        true -> Time = Time0;
                                        false -> Time = 0
                                    end;
                                _Other -> Time = 0
                            end;
                        false -> Time = 0
                    end;
                false -> 
                    Time = 0
            end
    end,
    {ok, BinData} = pt_343:write(34300, [Time]),
    %io:format("send 34300 : ~p~n", [time()]),
	lib_unite_send:send_to_uid(UniteStatus#unite_status.id, BinData);

%% 领取道具
handle(34301, _Status, _Bin) -> 
    skip;

%% 获取房间信息
handle(34302, Status, _Bin) ->
    %io:format("recv 34302 : ~p~n", [time()]),
    %% 记录活动开始时间
    [BeginHour, BeginMin, EndHour, EndMin, ApplyTime] = Status#player_status.loverun_data,
    case lib_loverun:is_opening(BeginHour, BeginMin, EndHour, EndMin, ApplyTime) of
        true ->
            SceneId = data_loverun:get_loverun_config(scene_id),
            List = mod_daily_dict:get_room(loverun, SceneId),
            AllNum = lists:foldl(fun({_, N},C)-> N+C end, 0, List),
			Limit = data_loverun:get_loverun_config(room_new_num),
            _Room = AllNum div Limit + 1,
            MaxRoom = mod_exit:lookup_max_room(loverun),
            %% 记录曾经开过的最大房间数
            Room = case MaxRoom > _Room of
                true -> MaxRoom;
                false -> 
                    mod_exit:insert_max_room(loverun, _Room),
                    _Room
            end,
            RoomList = lists:sublist(List, Room),
            %io:format("RoomList:~p~n", [RoomList]),
            Bin = pack(RoomList),
			{ok, BinData} = pt_343:write(34302, Bin);
        false -> 
            Bin = pack([]),
            {ok, BinData} = pt_343:write(34302, Bin)
    end,
    %io:format("send 34302 : ~p~n", [time()]),
	lib_server_send:send_one(Status#player_status.socket, BinData);

%% 进入、退出场景
handle(34303, Status, [Res, RoomId]) ->
    %io:format("recv 34303 : ~p~n", [time()]),
    %% 记录活动开始时间
    [BeginHour, BeginMin, EndHour, EndMin, ApplyTime] = Status#player_status.loverun_data,
	%% Res: 1进入  2退出
    %% 只分配10个房间
    MaxRoom = mod_exit:lookup_max_room(loverun),
    MaxRoom2 = case MaxRoom > 0 of
        true -> MaxRoom;
        false -> 1
    end,
    case (Res =:= 1 andalso RoomId >= 1 andalso RoomId =< MaxRoom2) orelse (Res =:= 2) of
        true ->
            case Status#player_status.lv >= 38 of
                true ->
                    case lib_loverun:is_opening(BeginHour, BeginMin, EndHour, EndMin, ApplyTime) =:= true orelse Res =:= 2 of
                        true ->
                            case Res of
                                1 -> 
                                    {Error, _NewStatus} = lib_loverun:login(Status, RoomId);
                                _ -> 
                                    erase({begin_end_time}),
                                    _NewStatus = Status,
                                    Error = lib_loverun:logout(Status)
                            end,
                            %io:format("Error:~p~n", [Error]),
                            {ok, BinData} = pt_343:write(34303, [Error, RoomId]);
                        false -> 
                            _NewStatus = Status,
                            {ok, BinData} = pt_343:write(34303, [2, 1])
                    end;
                false -> 
                    _NewStatus = Status,
                    {ok, BinData} = pt_343:write(34303, [8, 1])
            end;
        false -> 
            _NewStatus = Status,
            {ok, BinData} = pt_343:write(34303, [4, 1])
    end,
    %io:format("send 34303 : ~p~n", [time()]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 开始长跑
handle(34304, Status, _) ->
    MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),
    NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
    ParnerInfo = case length(NewMemberIdList) of
        1 ->
            [ParnerId] = NewMemberIdList,
            case lib_player:get_player_info(ParnerId, loverun) of
                false -> ["", 0, 0, 0];
                Any -> Any
            end;
        _ ->
            ["", 0, 0, 0]
    end,
    %% cast处理
    catch mod_loverun:execute_34304(Status, MemberIdList, ParnerInfo);

%% 使用道具
handle(34305, _Status, [_GoodsId, _PlayerId]) ->
    skip;

%% 提交任务
handle(34306, Status, _) ->
    MemberIdList = lib_team:get_mb_ids(Status#player_status.pid_team),
    NewMemberIdList = lists:delete(Status#player_status.id, MemberIdList),
    ParnerInfo = case length(NewMemberIdList) of
        1 ->
            [ParnerId] = NewMemberIdList,
            case lib_player:get_player_info(ParnerId, loverun) of
                false -> ["", 0, 0, 0];
                Any -> Any
            end;
        _ ->
            ["", 0, 0, 0]
    end,
    %% cast处理
    catch mod_loverun:execute_34306(Status, MemberIdList, ParnerInfo);

%% 任务状态
handle(34309, Status, _) ->
    %io:format("recv 34309 : ~p~n", [time()]),
    Err = Status#player_status.loverun_state,
    {ok, BinData} = pt_343:write(34309, [Err]),
    %io:format("send 34309:~p~n", [time()]),
	lib_server_send:send_one(Status#player_status.socket, BinData);

%% 活动开始的剩余时间  用公共线
handle(34310, Status, _) ->
    %io:format("recv 34310 : ~p~n", [time()]),
    {_Hour, _Min, _Sec} = time(),
    %% 记录活动开始时间
    [_BeginHour, _BeginMin, _EndHour, _EndMin, ApplyTime] = Status#unite_status.loverun_data,
    RestTime = case _Min >= _BeginMin of
        true -> (ApplyTime - (_Min - _BeginMin)) * 60 - _Sec;
        false -> (ApplyTime - (60 + _Min - _BeginMin)) * 60 - _Sec
    end,
    %io:format("all:~p~n", [[_BeginHour, _BeginMin, _EndHour, _EndMin, ApplyTime]]),
    RestTime2 = case RestTime > 0 of
        true -> RestTime;
        false -> 0
    end,
    %io:format("RestTime2:~p~n", [RestTime2]),
    {ok, BinData} = pt_343:write(34310, [RestTime2]),
    %io:format("send 34310 : ~p~n", [time()]),
	lib_unite_send:send_one(Status#unite_status.socket, BinData);

%% 已完成长跑的玩家信息(所有)  用公共线
handle(34311, Status, _) ->
    catch mod_loverun:get_all_finish_data(Status);

%% 距离上一波开跑已过去的时间(秒) 游戏线
handle(34312, Status, _) ->
    %io:format("recv 34312 : ~p~n", [time()]),
    {_Hour, _Min, _Sec} = time(),
    %% 记录活动开始时间
    [_BeginHour, _BeginMin, _EndHour, _EndMin, ApplyTime] = Status#player_status.loverun_data,
    PassTime = case _Min >= _BeginMin of
        true -> (_Min - _BeginMin - ApplyTime) * 60 + _Sec;
        false -> (60 + _Min - _BeginMin - ApplyTime) * 60 + _Sec
    end,
    PassTime2 = case PassTime > 0 of
        true -> PassTime;
        false -> 0
    end,
    {ok, BinData} = pt_343:write(34312, [PassTime2]),
    %io:format("send 34312 : ~p~n", [time()]),
	lib_server_send:send_one(Status#player_status.socket, BinData);

%% 玩家定时获得经验(10秒) 游戏线
handle(34313, Status, _) ->
    %io:format("recv 34313 : ~p~n", [time()]),
    %% 记录活动开始时间
    [BeginHour, BeginMin, EndHour, EndMin, ApplyTime] = Status#player_status.loverun_data,
    %% 判断是否在活动时间内
    case lib_loverun:is_opening(BeginHour, BeginMin, EndHour, EndMin, ApplyTime) of
        true ->
            %% 判断是否在场景内
            LoverunSceneId = data_loverun:get_loverun_config(scene_id),
            case Status#player_status.scene =:= LoverunSceneId of
                true -> Exp = lib_loverun:get_exp(Status#player_status.id, Status#player_status.lv);
                false -> Exp = 0
            end;
        false -> 
            Exp= 0
    end,
    %% 加经验
    case Exp > 0 of
        true ->
            Exp2 = round(Exp),
            NewStatus = lib_player:add_exp(Status, Exp2, 0, 0);
        false -> 
            Exp2 = round(Exp),
            NewStatus = Status
    end,
    %io:format("Exp:~p~n", [Exp2]),
    {ok, BinData} = pt_343:write(34313, [Exp2]),
    %io:format("send 34313 : ~p~n", [time()]),
	lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, NewStatus};

%% 传送到伴侣身边 游戏线
handle(34314, Status, _) ->
    LoverunSceneId = data_loverun:get_loverun_config(scene_id),
    case Status#player_status.scene =:= LoverunSceneId andalso Status#player_status.parner_id =/= 0 of
        true ->
            lib_player:update_player_info(Status#player_status.parner_id, [{send_to_loverun_parner, Status#player_status.id}]);
        false ->
            skip
    end;

handle(_Cmd, _LogicStatus, _Data) ->
    ?DEBUG("pp_loverun no match", []),
    {error, "pp_loverun no match"}.

pack0(Err, List) ->
    Fun1 = fun(Elem1) ->
            {GoodsId, GoodsNum} = Elem1,
            <<GoodsId:32, GoodsNum:16>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List]),
    Size1  = length(List),
    <<Err:8, Size1:16, BinList1/binary>>.

pack(RoomList) ->
    MaxNum = data_loverun:get_loverun_config(room_max_num),
	%% List1
    Fun1 = fun(Elem1) ->
                {RoomId, NowNum} = Elem1,
                case NowNum > MaxNum of
                    true -> <<RoomId:8, MaxNum:16, MaxNum:16>>;
                    false -> <<RoomId:8, NowNum:16, MaxNum:16>>
                end
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- RoomList]),
    Size1  = length(RoomList),
    <<Size1:16, BinList1/binary>>.
