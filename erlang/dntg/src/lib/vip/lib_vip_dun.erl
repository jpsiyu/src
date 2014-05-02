%%%---------------------------------------
%%% @Module  : lib_vip_dun
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2013-02-25
%%% @Description:  VIP副本
%%%---------------------------------------

-module(lib_vip_dun).
-export(
    [
        timing_clear/1,
        send_player_out/2,
        re_connect/2,
        vip_dun_logout_deal/2,
        enter_vip_dun/4,
        player_logout/2,
        get_vip_dun_info/2,
        flag/6,
        get_mon_time/2,
        get_questions/2,
        answer_question/3,
        select_right_answer/2,
        clear_wrong_answer/2,
        guessing_game/3,
        minus_skill/3,
        start_battle/3,
        end_battle/3,
        vip_dun_battle_award/3,
        kill_mon/2,
        send_goods_award/3,
        check_buy_num/2,
        buy_num/2,
        get_vip_dun_shop_list/2,
        get_call_shop_list/2,
        guessing_point/3,
        add_round/2,
        create_four_mon/4,
        update_boss_id/3,
        boss_die/3,
        goto/3,
        create_goods/4
    ]
).
-include("server.hrl").
-include("vip_dun.hrl").
-include("drop.hrl").
-include("def_goods.hrl").
-include("shop.hrl").

%% 定时清理
timing_clear(VipDunState) ->
    case is_record(VipDunState, vip_dun_state) of
        true ->
            PlayerDunList = dict:to_list(VipDunState#vip_dun_state.player_dun),
            %% 清理过期玩家副本信息
            clear_out(PlayerDunList),
            %% 发送boss谜语
            send_boss_talk(PlayerDunList);
        false ->
            skip
    end.

clear_out([]) -> skip;
clear_out([H | T]) ->
    case H of
        {PlayerId, PlayerDun} when is_record(PlayerDun, player_dun) ->
            NowTime = util:unixtime(),
            DunTime = data_vip_dun:get_vip_dun_config(dun_time),
            LeaveTime = data_vip_dun:get_vip_dun_config(leave_time),
            %% 踢出副本
            case NowTime - PlayerDun#player_dun.enter_time > DunTime orelse (NowTime - PlayerDun#player_dun.off_line_time > LeaveTime andalso PlayerDun#player_dun.off_line_time > 0) of
                true ->
                    spawn(fun() ->
                                case NowTime - PlayerDun#player_dun.enter_time > DunTime of
                                    %% 副本时间到后自动退出
                                    true ->

                                        db:execute(io_lib:format(<<"insert into log_vip_dun2 set player_id = ~p, player_lv = ~p, begin_time = ~p, end_time = ~p, exit_type = 2">>, [PlayerId, PlayerDun#player_dun.player_lv, PlayerDun#player_dun.enter_time, util:unixtime()]));
                                    %% 离线超过三分钟
                                    false ->
                                        db:execute(io_lib:format(<<"insert into log_vip_dun2 set player_id = ~p, player_lv = ~p, begin_time = ~p, end_time = ~p, exit_type = 3">>, [PlayerId, PlayerDun#player_dun.player_lv, PlayerDun#player_dun.enter_time, util:unixtime()]))
                                end
                        end),
                    rest_skill_mail(PlayerDun),
                    mod_vip_dun:send_player_out(PlayerId);
                false ->
                    skip
            end;
        _ ->
            skip
    end,
    clear_out(T).

send_boss_talk([]) -> skip;
send_boss_talk([H | T]) ->
    case H of
        {PlayerId, PlayerDun} when is_record(PlayerDun, player_dun) ->
            case PlayerDun#player_dun.talk_type > 0 of
                false ->
                    skip;
                true ->
                    Str = case PlayerDun#player_dun.talk_type of
                        1 -> data_vip_dun_text:get_vip_dun_text(4);
                        2 -> data_vip_dun_text:get_vip_dun_text(5);
                        3 -> data_vip_dun_text:get_vip_dun_text(6);
                        4 -> data_vip_dun_text:get_vip_dun_text(7)
                    end,
                    {ok, BinData} = pt_121:write(12103, [PlayerDun#player_dun.boss_id, Str]),
                    lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}])
            end;
        _ ->
            skip
    end,
    send_boss_talk(T).

%% 把玩家踢出副本
send_player_out(PlayerId, VipDunState) ->
    lib_player:update_player_info(PlayerId, [{vip_dun_clear_out, no}]),
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    NewAllPlayerDun = dict:erase(PlayerId, AllPlayerDun),
    VipDunState#vip_dun_state{
        player_dun = NewAllPlayerDun
    }.

%% 断线重连
re_connect(_PlayerStatus, VipDunState) ->
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    PlayerStatus = case _PlayerStatus#player_status.scene =:= SceneId of
        true -> 
            [LeaveScene, LeaveX, LeaveY] = data_vip_dun:get_vip_dun_config(leave),
            _PlayerStatus#player_status{
                scene = LeaveScene,
                copy_id = 0,
                x = LeaveX,
                y = LeaveY
            };
        false ->
            _PlayerStatus
    end,
    PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            CopyId = PlayerDun#player_dun.copy_id,
            AllCells = data_vip_dun:get_vip_dun_config(vip_dun_cell),
            Len = length(AllCells),
            NowNum = PlayerDun#player_dun.now_num,
            %% 兼容在换圈时掉线的情况
            {{X, Y}, _} = case NowNum > Len of
                true ->
                    lists:nth(1, AllCells);
                false ->
                    {PlayerDun#player_dun.now_xy, 0}
            end,
            NewPlayerStatus = PlayerStatus#player_status{
                scene = SceneId,
                copy_id = CopyId,
                x = X,
                y = Y
            },
            NewPlayerDun = PlayerDun#player_dun{
                off_line_time = 0
            },
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            NewVipDunState = VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            },
            [NewPlayerStatus, NewVipDunState];
        _ ->
            [PlayerStatus, VipDunState]
    end.

%% 下线处理
vip_dun_logout_deal(PlayerId, VipDunState) ->
    %PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            NewPlayerDun = PlayerDun#player_dun{
                off_line_time = util:unixtime()
            },
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.
    
    
%% 进入VIP副本
enter_vip_dun(PlayerId, PlayerLv, _StatusVip, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    MaxId = VipDunState#vip_dun_state.max_id + 1,
    %PlayerId = PlayerStatus#player_status.id,
    %% 掷骰子次数
    %StatusVip = PlayerStatus#player_status.vip,
    FlagNum = 8,
%%    VipType = StatusVip#status_vip.vip_type,
%%    FlagNum = case VipType of
%%        1 -> 3;
%%        2 -> 4;
%%        3 -> 
%%            GrowthLv = StatusVip#status_vip.growth_lv,
%%            case GrowthLv of
%%                0 -> 6;
%%                1 -> 7;
%%                2 -> 8;
%%                3 -> 9;
%%                4 -> 10;
%%                5 -> 11;
%%                6 -> 12;
%%                7 -> 13;
%%                8 -> 14;
%%                9 -> 15;
%%                _ -> 16
%%            end;
%%        _ -> 0
%%    end,
    %% 参与VIP副本次数
    case catch db:get_row(io_lib:format(<<"select dun_num from log_vip_dun where player_id = ~p limit 1">>, [PlayerId])) of
        [] ->
            DunNum = 1,
            db:execute(io_lib:format(<<"insert into log_vip_dun set player_id = ~p, dun_num = ~p, last_dun_time = ~p">>, [PlayerId, DunNum, util:unixtime()]));
        [_DunNum] ->
            DunNum = _DunNum + 1,
            db:execute(io_lib:format(<<"update log_vip_dun set dun_num = ~p, last_dun_time = ~p where player_id = ~p">>, [DunNum, util:unixtime(), PlayerId]));
        _ ->
            DunNum = 1
    end,
    AllCells = data_vip_dun:get_vip_dun_config(vip_dun_cell),
    {NowXY, NowState} = lists:nth(1, AllCells),
    PlayerDun = #player_dun{
        %skill_list = [1, 2, 3, 4],
        player_id = PlayerId,
        player_lv = PlayerLv,
        copy_id = MaxId,
        enter_time = util:unixtime(),
        flag_num = FlagNum,
        now_xy = NowXY,
        now_state = NowState,
        dun_num = DunNum
    },
    %% 传送
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    {X, Y} = NowXY,
    lib_mon:clear_scene_mon(SceneId, MaxId, 1),
    lib_scene:player_change_scene(PlayerId, SceneId, MaxId, X, Y, false),
    %% 更新数据
    NewAllPlayerDun = dict:store(PlayerId, PlayerDun, AllPlayerDun),
    VipDunState#vip_dun_state{
        max_id = MaxId,
        player_dun = NewAllPlayerDun
    }.

%% 退出VIP副本
player_logout(PlayerId, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    %PlayerId = PlayerStatus#player_status.id,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            rest_skill_mail(PlayerDun),
            %% 玩家点击退出按钮
            spawn(fun() ->
                        db:execute(io_lib:format(<<"insert into log_vip_dun2 set player_id = ~p, player_lv = ~p, begin_time = ~p, end_time = ~p, exit_type = 1">>, [PlayerId, PlayerDun#player_dun.player_lv, PlayerDun#player_dun.enter_time, util:unixtime()]))
                end),
            NewAllPlayerDun = dict:erase(PlayerId, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.


%% 获取VIP副本信息 
get_vip_dun_info(PlayerId, VipDunState) ->
    %PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            %% 所有格子列表
            AllCells = data_vip_dun:get_vip_dun_config(vip_dun_cell),
            Len = length(AllCells),
            NowNum = PlayerDun#player_dun.now_num,
            %io:format("NowNum:~p~n", [NowNum]),
            case NowNum > Len of
                %% 一圈未跑完
                false ->
                    send_45103(PlayerId, PlayerDun, [], 0),
                    VipDunState;
                true ->
                    NewNum = NowNum rem (Len + 1) + 1,
                    {NewXY, NewState} = lists:nth(NewNum, AllCells),
                    XYList = lists:sublist(AllCells, 2, NewNum - 1),
                    UnitTime = 1500,
                    SleepTime = (NewNum - 1) * UnitTime,
                    _NewPlayerDun = flag_state(NewState, PlayerDun, NewXY, NewNum, SleepTime),
                    %io:format("NewState:~p, NewXY:~p, NewNum:~p~n", [NewState, NewXY, NewNum]),
                    %% 更新信息
                    NewPlayerDun = _NewPlayerDun#player_dun{
                        flag_num = PlayerDun#player_dun.flag_num + 1
                    },
                    %io:format("XYList:~p~n", [XYList]),
                    send_45103(PlayerId, NewPlayerDun, XYList, 1),
                    NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
                    VipDunState#vip_dun_state{
                        player_dun = NewAllPlayerDun
                    }
            end;
        _ ->
            VipDunState
    end.

send_45103(PlayerId, PlayerDun, XYList, ForceMove) ->
    %% 副本剩余时间
    _RestTime = PlayerDun#player_dun.enter_time + data_vip_dun:get_vip_dun_config(dun_time) - util:unixtime(),
    RestTime = case _RestTime > 0 of
        true -> _RestTime;
        false -> 0
    end,
    %% 当前格子信息
    {NowX, NowY} = PlayerDun#player_dun.now_xy,
    NowState = PlayerDun#player_dun.now_state,
    %% 技能情况
    SkillList = PlayerDun#player_dun.skill_list,
    %% 剩余投掷次数
    RestNum = PlayerDun#player_dun.flag_num,
    %% 是否可掷
    FlagState = PlayerDun#player_dun.can_flag,
    %% 参与副本次数
    DunNum = PlayerDun#player_dun.dun_num,
    %% 购买骰子所需元宝
    NeedGold = data_vip_dun:get_vip_dun_buy_gold(PlayerDun#player_dun.buy_num + 1),
    Len = length(data_vip_dun:get_vip_dun_config(vip_dun_cell)) + 1,
    TotalNum = PlayerDun#player_dun.total_num,
    Round = TotalNum div Len + 1,
    {ok, BinData} = pt_451:write(45103, [RestTime, XYList, NowX, NowY, NowState, SkillList, RestNum, FlagState, DunNum, NeedGold, Round, ForceMove]),
    lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}]).

%% 掷骰子
flag(PlayerId, _PlayerLv, _SceneId, _CopyId, VipDunState, CheckNum) ->
    %PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            NewVipDunState = case PlayerDun#player_dun.flag_num =< 0 of
                %% 剩余次数为0
                true ->
                    FlagNum = 7,
                    VipDunState;
                false ->
                    case PlayerDun#player_dun.can_flag of
                        %% 当前状态不可掷骰子
                        2 ->
                            FlagNum = 0,
                            VipDunState;
                        _ ->
                            %% 所有格子列表
                            AllCells = data_vip_dun:get_vip_dun_config(vip_dun_cell),
                            Len = length(AllCells),
                            NowNum = PlayerDun#player_dun.now_num,
                            %% 兼容秘籍
                            FlagNum = case CheckNum of
                                0 -> util:rand(1, 6);
                                _ -> CheckNum
                            end,
                            NewNum = NowNum + FlagNum,
                            UnitTime = 1500,
                            SleepTime = 2000 + FlagNum * UnitTime,
                            %NewNum2 = NewNum rem (Len + 1),
                            %UnitTime = 1500,
                            %NewNum3 = case NewNum2 < NewNum of
                            %    true -> 
                            %        SleepTime = 2000 + UnitTime,
                            %        NewNum2 + 1;
                            %    false -> 
                            %        SleepTime = 2000 + FlagNum * UnitTime,
                            %        NewNum2
                            %end,
                            %{NewXY, NewState} = lists:nth(NewNum3, AllCells),
                            %SceneId = PlayerStatus#player_status.scene,
                            %CopyId = PlayerStatus#player_status.copy_id,
                            XYList = case NewNum > Len of
                                true ->
                                    %{X, Y} = NewXY,
                                    %spawn(fun() ->
                                    %            timer:sleep(3000),
                                    %            lib_scene:player_change_scene(PlayerId, SceneId, CopyId, X, Y, false)
                                    %    end),
                                    {NewXY, _NewState0} = lists:nth(Len, AllCells),
                                    _NewState = 0,
                                    lists:sublist(AllCells, NowNum + 1, Len - NowNum + 1);
                                false ->
                                    {NewXY, _NewState} = lists:nth(NewNum, AllCells),
                                    lists:sublist(AllCells, NowNum + 1, FlagNum)
                            end,
                            ARand = util:rand(1, 2),
                            NewState = case _NewState of
                                %% 猜拳格、瘟神格、赌神
                                5 ->
                                    case ARand of
                                        1 -> 5;
                                        _ -> 5
                                        %_ -> 11
                                    end;
                                8 ->
                                    case ARand of
                                        1 -> 8;
                                        _ -> 13
                                    end;
                                9 ->
                                    case PlayerDun#player_dun.skill_list =:= [] of
                                        true -> 9;
                                        false -> 12
                                    end;
                                _ ->
                                    _NewState
                            end,
                            _NewPlayerDun = flag_state(NewState, PlayerDun, NewXY, NewNum, SleepTime),
                            NewPlayerDun = _NewPlayerDun#player_dun{
                                total_num = PlayerDun#player_dun.total_num + FlagNum
                            },
                            %% 通知客户端更新
                            send_45103(PlayerId, NewPlayerDun, XYList, 0),
                            %% 更新数据
                            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
                            VipDunState#vip_dun_state{
                                player_dun = NewAllPlayerDun
                            }
                    end
            end,
            {ok, BinData} = pt_451:write(45105, [FlagNum]),
            lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}]),
            NewVipDunState;
        _ ->
            VipDunState
    end.

flag_state(NewState, PlayerDun, NewXY, NewNum, SleepTime) ->
    %% 0.传送格 1.出生格 2.战斗格 3.宝箱格 4.问答格 5.猜拳格 6.技能格 7.财神格 8.瘟神格(骰子数减一) 9.扫把星(下2次奖励减半) 10.陷阱层 11.赌神(压大小) 12.扫把星(扣除一个技能) 13.瘟神格(减少80%血量) 14.BOSS层
    PlayerId = PlayerDun#player_dun.player_id,
    PlayerLv = PlayerDun#player_dun.player_lv,
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    CopyId = PlayerDun#player_dun.copy_id,
    case NewState of
        %% 传送格
        0 ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 2;
        %% 1.出生格
        1 ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 1;
        %% 2.战斗格
        2 ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 2,
            MonTypeId1 = if
                PlayerLv =< 50 ->
                    data_vip_dun:get_vip_dun_config(mon_type_id1);
                PlayerLv =< 60 ->
                    data_vip_dun:get_vip_dun_config(mon_type_id2);
                PlayerLv =< 70 ->
                    data_vip_dun:get_vip_dun_config(mon_type_id3);
                true ->
                    data_vip_dun:get_vip_dun_config(mon_type_id4)
            end,
            MonType = 0,%0被动 1主动
            BroadCast = 1,%0不广播 1广播
            {MonX, MonY} = NewXY,
            spawn(fun() ->
                        timer:sleep(SleepTime),
                        lib_mon:async_create_mon(MonTypeId1, SceneId, MonX, MonY, MonType, CopyId, BroadCast, [])
                end);
        %% 3.宝箱格
        3 ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 1,
            MonTypeId2 = data_vip_dun:get_vip_dun_config(mon_type_id0),
            MonType = 0,%0被动 1主动
            BroadCast = 1,%0不广播 1广播
            {MonX, MonY} = NewXY,
            spawn(fun() ->
                        timer:sleep(SleepTime),
                        lib_mon:async_create_mon(MonTypeId2, SceneId, MonX, MonY, MonType, CopyId, BroadCast, [{auto_lv, 99}])
                end);
        %% 4.问答格
        4 ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            [Quiz, Section1, Section2, Section3, Section4, Correct] = rand_a_question(),
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 2;
        %% 5.猜拳格
        5 ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 2;
        %% 6.技能格
        6 ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            Skill = util:rand(1, 4),
            {ok, BinData2} = pt_451:write(45112, [Skill]),
            lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData2}]),
            SkillList = [Skill | PlayerDun#player_dun.skill_list],
            CanFlag = 1;
        %% 7.财神格
        7 ->
            Temp1 = integer_to_list(PlayerId) ++ "_" ++ integer_to_list(SceneId) ++ "_" ++ integer_to_list(632001),
            Temp2 = integer_to_list(PlayerId) ++ "_" ++ integer_to_list(SceneId) ++ "_" ++ integer_to_list(632002),
            Temp3 = integer_to_list(PlayerId) ++ "_" ++ integer_to_list(SceneId) ++ "_" ++ integer_to_list(632003),
            Temp4 = integer_to_list(PlayerId) ++ "_" ++ integer_to_list(SceneId) ++ "_" ++ integer_to_list(501204),
            mod_daily_dict:set_special_info(Temp1, 0),
            mod_daily_dict:set_special_info(Temp2, 0),
            mod_daily_dict:set_special_info(Temp3, 0),
            mod_daily_dict:set_special_info(Temp4, 0),
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 1;
        %% 8.瘟神格
        8 ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = case PlayerDun#player_dun.flag_num > 1 of
                true ->  PlayerDun#player_dun.flag_num - 2;
                false -> 0
            end,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 1;
        %% 9.扫把星
        9 ->
            HalfAward = 2 + 1,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 1;
        %% 11.赌神(压大小)
        11 ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 2;
        %% 12.扫把星(扣除一个技能)
        12 ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            [_H | _SkillList] = PlayerDun#player_dun.skill_list,
            SkillList = _SkillList,
            CanFlag = 1;
        %% 13.瘟神格(减少80%血量)
        13 ->
            case misc:get_player_process(PlayerId) of
                Pid when is_pid(Pid) ->
                    spawn(fun() ->
                                timer:sleep(SleepTime),
                                Pid ! {last_change_hp, 0, -0.8}
                        end);
                _ ->
                    skip
            end,
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 1;
        %% 14.BOSS层
        14 ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 2,
            BossId = data_vip_dun:get_vip_dun_config(mon_boss_id),
            MonType = 0,%0被动 1主动
            BroadCast = 1,%0不广播 1广播
            {MonX, MonY} = NewXY,
            spawn(fun() ->
                        timer:sleep(SleepTime),
                        BossUnitId = lib_mon:sync_create_mon(BossId, SceneId, MonX, MonY, MonType, CopyId, BroadCast, []),
                        mod_vip_dun:update_boss_id(PlayerId, BossUnitId)
                end);
        _ ->
            HalfAward = case PlayerDun#player_dun.half_award > 0 of
                true -> PlayerDun#player_dun.half_award - 1;
                false -> 0
            end,
            RestFlagNum = PlayerDun#player_dun.flag_num - 1,
            Quiz = "",
            Section1 = "",
            Section2 = "",
            Section3 = "",
            Section4 = "",
            Correct = 0,
            QuestionTime = 0,
            SkillList = PlayerDun#player_dun.skill_list,
            CanFlag = 1
    end,
    NewPlayerDun = PlayerDun#player_dun{
        half_award = HalfAward,
        quiz = Quiz,
        section1 = Section1,
        section2 = Section2,
        section3 = Section3,
        section4 = Section4,
        correct = Correct,
        question_time = QuestionTime,
        flag_num = RestFlagNum,
        can_flag = CanFlag,
        skill_list = SkillList,
        %total_num = PlayerDun#player_dun.total_num + FlagNum,
        now_num = NewNum,
        now_xy = NewXY,
        now_state = NewState
    },
    NewPlayerDun.

%% 杀怪用时
get_mon_time(PlayerId, VipDunState) ->
    %PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            case PlayerDun#player_dun.battle_start_time of
                0 ->
                    {ok, BinData} = pt_451:write(45106, [0]),
                    lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}]);
                _ ->
                    Time = util:unixtime() - PlayerDun#player_dun.battle_start_time,
                    Time2 = case Time > 0 of
                        true -> Time;
                        false -> 0
                    end,
                    {ok, BinData} = pt_451:write(45106, [Time2]),
                    lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}])
            end;
        _ ->
            skip
    end.

%% 获取题目
get_questions(PlayerId, VipDunState) ->
    %PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            case PlayerDun#player_dun.now_state =:= 4 andalso PlayerDun#player_dun.can_flag =:= 2 of
                false ->
                    VipDunState;
                true ->
                    Question = PlayerDun#player_dun.quiz,
                    Section1 = PlayerDun#player_dun.section1,
                    Section2 = PlayerDun#player_dun.section2,
                    Section3 = PlayerDun#player_dun.section3,
                    Section4 = PlayerDun#player_dun.section4,
                    NowTime = util:unixtime(),
                    QuestionTime = case PlayerDun#player_dun.question_time =:= 0 of
                        true -> 0;
                        false -> NowTime - PlayerDun#player_dun.question_time
                    end,
                    QuestimeTime2 = case QuestionTime > 0 of
                        true -> QuestionTime;
                        false -> 0
                    end,
                    {ok, BinData} = pt_451:write(45107, [Question, Section1, Section2, Section3, Section4, QuestimeTime2]),
                    lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}]),
                    NewTime = case PlayerDun#player_dun.question_time of
                        0 -> NowTime;
                        _ -> PlayerDun#player_dun.question_time
                    end,
                    NewPlayerDun = PlayerDun#player_dun{
                        question_time = NewTime
                    },
                    NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
                    VipDunState#vip_dun_state{
                        player_dun = NewAllPlayerDun
                    }
            end;
        _ ->
            VipDunState
    end.

%% 回答问题
answer_question(PlayerStatus, VipDunState, Answer) ->
    PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            Res = case Answer =:= PlayerDun#player_dun.correct of
                true ->
                    1;
                false ->
                    2
            end,
            Time = case PlayerDun#player_dun.question_time > 0 of
                true -> util:unixtime() - PlayerDun#player_dun.question_time;
                false -> 0
            end,
            Time2 = case Time > 0 of
                true -> Time;
                false -> 0
            end,
            {X, Y} = PlayerDun#player_dun.now_xy,
            spawn(fun() ->
                        timer:sleep(1000),
                        send_quiz_award(PlayerStatus, Res, Time2, PlayerDun#player_dun.half_award, X, Y)
                end),
            {ok, BinData} = pt_451:write(45108, [Res]),
            spawn(fun() ->
                        lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}])
                end),
            NewPlayerDun = PlayerDun#player_dun{
                can_flag = 1,
                quiz = "",
                section1 = "",
                section2 = "",
                section3 = "",
                section4 = "",
                correct = 0,
                question_time = 0
            },
            send_45103(PlayerStatus#player_status.id, NewPlayerDun, [], 0),
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.

%% 选择正确答案
select_right_answer(PlayerStatus, VipDunState) ->
    PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            case PlayerDun#player_dun.quiz =:= "" of
                %% 没有题目
                true ->
                    Res = 3,
                    NewPlayerDun = PlayerDun;
                false ->
                    case lists:member(3, PlayerDun#player_dun.skill_list) of
                        %% 没有该技能
                        false -> 
                            Res = 2,
                            NewPlayerDun = PlayerDun;
                        %% 成功使用技能
                        true ->
                            Res = 1,
                            Time = case PlayerDun#player_dun.question_time > 0 of
                                true -> util:unixtime() - PlayerDun#player_dun.question_time;
                                false -> 0
                            end,
                            Time2 = case Time > 0 of
                                true -> Time;
                                false -> 0
                            end,
                            {X, Y} = PlayerDun#player_dun.now_xy,
                            send_quiz_award(PlayerStatus, Res, Time2, PlayerDun#player_dun.half_award, X, Y),
                            %% 更新技能
                            NewSkillList = lists:delete(3, PlayerDun#player_dun.skill_list),
                            NewPlayerDun = PlayerDun#player_dun{
                                can_flag = 1,
                                skill_list = NewSkillList,
                                quiz = "",
                                section1 = "",
                                section2 = "",
                                section3 = "",
                                section4 = "",
                                correct = 0,
                                question_time = 0
                            }
                    end
            end,
            send_45103(PlayerStatus#player_status.id, NewPlayerDun, [], 0),
            {ok, BinData} = pt_451:write(45109, [Res]),
            lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}]),
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.

%% 去掉2个错误答题
clear_wrong_answer(PlayerId, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            case PlayerDun#player_dun.quiz =:= "" of
                %% 没有题目
                true ->
                    Res = 3,
                    Wrong1 = 0,
                    Wrong2 = 0,
                    NewPlayerDun = PlayerDun;
                false ->
                    case lists:member(4, PlayerDun#player_dun.skill_list) of
                        %% 没有该技能
                        false -> 
                            Res = 2,
                            Wrong1 = 0,
                            Wrong2 = 0,
                            NewPlayerDun = PlayerDun;
                        %% 成功使用技能
                        true ->
                            Res = 1,
                            %% 更新技能
                            NewSkillList = lists:delete(4, PlayerDun#player_dun.skill_list),
                            %% 去掉错误答案
                            L = [],
                            L1 = case PlayerDun#player_dun.section1 =:= "" of
                                true -> L;
                                false -> [1 | L]
                            end,
                            L2 = case PlayerDun#player_dun.section2 =:= "" of
                                true -> L1;
                                false -> [2 | L1]
                            end,
                            L3 = case PlayerDun#player_dun.section3 =:= "" of
                                true -> L2;
                                false -> [3 | L2]
                            end,
                            L4 = case PlayerDun#player_dun.section4 =:= "" of
                                true -> L3;
                                false -> [4 | L3]
                            end,
                            L5 = L4 -- [PlayerDun#player_dun.correct],
                            L6 = lists:sublist(L5, 1, 2),
                            case L6 of
                                [] -> 
                                    Wrong1 = 0,
                                    Wrong2 = 0;
                                [Wrong1] ->
                                    Wrong2 = 0;
                                [Wrong1, Wrong2] ->
                                    ok
                            end,
                            %% 更新答案
                            Section1 = case lists:member(1, [Wrong1, Wrong2]) of
                                true -> "";
                                false -> PlayerDun#player_dun.section1
                            end,
                            Section2 = case lists:member(2, [Wrong1, Wrong2]) of
                                true -> "";
                                false -> PlayerDun#player_dun.section2
                            end,
                            Section3 = case lists:member(3, [Wrong1, Wrong2]) of
                                true -> "";
                                false -> PlayerDun#player_dun.section3
                            end,
                            Section4 = case lists:member(4, [Wrong1, Wrong2]) of
                                true -> "";
                                false -> PlayerDun#player_dun.section4
                            end,
                            NewPlayerDun = PlayerDun#player_dun{
                                skill_list = NewSkillList,
                                section1 = Section1,
                                section2 = Section2,
                                section3 = Section3,
                                section4 = Section4
                            }
                    end
            end,
            {ok, BinData} = pt_451:write(45110, [Res, Wrong1, Wrong2]),
            lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}]),
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.

%% 猜拳
guessing_game(PlayerStatus, VipDunState, Answer) ->
    PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            case PlayerDun#player_dun.now_state =:= 5 andalso PlayerDun#player_dun.can_flag =:= 2 of
                false ->
                    Res = 4,
                    ComputeAnswer = 1,
                    NewPlayerDun = PlayerDun;
                %% 是否在猜拳时间
                true ->
                    ComputeAnswer = util:rand(1, 3),
                    Res = case ComputeAnswer =:= Answer of
                        %% 打平
                        true -> 3;
                        false ->
                            case (ComputeAnswer =:= 1 andalso Answer =:= 3) orelse (ComputeAnswer =:= 2 andalso Answer =:= 1) orelse (ComputeAnswer =:= 3 andalso Answer =:= 2) of
                                %% 失败
                                true -> 2;
                                %% 胜利
                                false -> 1
                            end
                    end,
                    %% 打平则可以重新猜拳
                    CanFlag = case Res of
                        3 ->
                            2;
                        _ ->
                            {X, Y} = PlayerDun#player_dun.now_xy,
                            spawn(fun() ->
                                        timer:sleep(3000),
                                        case Res of
                                            1 ->
                                                case PlayerDun#player_dun.half_award > 0 of
                                                    true ->
                                                        create_goods(lists:duplicate(5, 632000), PlayerStatus, X, Y);
                                                    false ->
                                                        create_goods([632001], PlayerStatus, X, Y)
                                                end;
                                            _ ->
                                                case PlayerDun#player_dun.half_award > 0 of
                                                    true ->
                                                        skip;
                                                    false ->
                                                        create_goods([632000], PlayerStatus, X, Y)
                                                end
                                        end
                                end),
                            1
                    end,
                    NewPlayerDun = PlayerDun#player_dun{
                        can_flag = CanFlag
                    }
            end,
            send_45103(PlayerStatus#player_status.id, NewPlayerDun, [], 0),
            %io:format("~p~n", [[Res, Answer, ComputeAnswer]]),
            {ok, BinData} = pt_451:write(45111, [Res, Answer, ComputeAnswer]),
            spawn(fun() ->
                        timer:sleep(2000),
                        lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}])
                end),
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.

%%%%% 外部调用接口 %%%%%

%% 开始打怪
start_battle(PlayerId, MonId, VipDunState) ->
    MonType1 = data_vip_dun:get_vip_dun_config(mon_type_id1),
    MonType2 = data_vip_dun:get_vip_dun_config(mon_type_id2),
    MonType3 = data_vip_dun:get_vip_dun_config(mon_type_id3),
    MonType4 = data_vip_dun:get_vip_dun_config(mon_type_id4),
    case lists:member(MonId, [MonType1, MonType2, MonType3, MonType4]) of
        false ->
            VipDunState;
        true ->
            AllPlayerDun = VipDunState#vip_dun_state.player_dun,
            case dict:find(PlayerId, AllPlayerDun) of
                {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
                    case PlayerDun#player_dun.now_state of
                        %% 在战斗格
                        2 ->
                            NewPlayerDun = PlayerDun#player_dun{
                                battle_start_time = util:unixtime()
                            },
                            {ok, BinData} = pt_451:write(45106, [1]),
                            lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}]);
                        _ ->
                            NewPlayerDun = PlayerDun
                    end,
                    NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
                    VipDunState#vip_dun_state{
                        player_dun = NewAllPlayerDun
                    };
                _ ->
                    VipDunState
            end
    end.

%% 结束打怪
end_battle(PlayerId, MonId, VipDunState) ->
    MonType1 = data_vip_dun:get_vip_dun_config(mon_type_id1),
    MonType2 = data_vip_dun:get_vip_dun_config(mon_type_id2),
    MonType3 = data_vip_dun:get_vip_dun_config(mon_type_id3),
    MonType4 = data_vip_dun:get_vip_dun_config(mon_type_id4),
    case lists:member(MonId, [MonType1, MonType2, MonType3, MonType4]) of
        false ->
            VipDunState;
        true ->
            AllPlayerDun = VipDunState#vip_dun_state.player_dun,
            case dict:find(PlayerId, AllPlayerDun) of
                {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
                    case PlayerDun#player_dun.now_state of
                        %% 在战斗格
                        2 ->
                            NewPlayerDun = PlayerDun#player_dun{
                                can_flag = 1,
                                battle_start_time = 0
                            },
                            %NewPlayerDun = PlayerDun,
                            %send_45103(PlayerId, NewPlayerDun, [], 0),
                            %% 通知客户端
                            case PlayerDun#player_dun.battle_start_time > 0 of
                                true ->
                                    Time = util:unixtime() - PlayerDun#player_dun.battle_start_time,
                                    Time2 = case Time > 0 of
                                        true -> Time;
                                        false -> 0
                                    end,
                                    {ok, BinData} = pt_451:write(45106, [0]),
                                    lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}]);
                                false ->
                                    Time2 = 0
                            end,
                            %{X, Y} = PlayerDun#player_dun.now_xy,
                            lib_player:update_player_info(PlayerId, [{vip_dun_battle_award, Time2}]),                            
                            spawn(fun() ->
                                        timer:sleep(1500),
                                        send_45103(PlayerId, NewPlayerDun, [{PlayerDun#player_dun.now_xy, 2}], 1)
                            %            %% 把玩家移回原格，发送奖励
                            %            %lib_player:update_player_info(PlayerId, [{vip_dun_send_back, [X, Y]}]),
                            %            lib_player:update_player_info(PlayerId, [{vip_dun_battle_award, Time2}]),
                            %            timer:sleep(1000),
                            %            %lib_player:update_player_info(PlayerId, [{vip_dun_battle_award, Time2}]),
                            %            lib_player:update_player_info(PlayerId, [{vip_dun_send_back, [X, Y]}])
                                end);
                        _ ->
                            NewPlayerDun = PlayerDun
                    end,
                    NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
                    VipDunState#vip_dun_state{
                        player_dun = NewAllPlayerDun
                    };
                _ ->
                    VipDunState
            end
    end.

%% 随机选择一道题目
rand_a_question() ->
    case db:get_all(<<"select content, option1, option2, option3, option4, correct from base_vip_dun">>) of
        [] ->
            ["random choose", "false", "true", "false", "false", 2];
        List when is_list(List) ->
            Len = length(List),
            Rand = util:rand(1, Len),
            lists:nth(Rand, List);
        _ ->
            ["random choose", "false", "false", "true", "false", 3]
    end.

%% 发送战斗奖励
vip_dun_battle_award(PlayerStatus, Time, VipDunState) ->
    PlayerId = PlayerStatus#player_status.id,
    PlayerLv = PlayerStatus#player_status.lv,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            {X, Y} = PlayerDun#player_dun.now_xy,
            %% 只有VIP半年卡才能获得VIP成长经验
            if
                PlayerLv =< 50 ->
                    if
                        Time =< 10 ->
                            create_goods(lists:duplicate(5, 632000), PlayerStatus, X, Y);
                        Time =< 20 ->
                            create_goods(lists:duplicate(3, 632000), PlayerStatus, X, Y);
                        true ->
                            create_goods(lists:duplicate(1, 632000), PlayerStatus, X, Y)
                    end;
                PlayerLv =< 60 ->
                    if
                        Time =< 10 ->
                            create_goods(lists:duplicate(8, 632000), PlayerStatus, X, Y);
                        Time =< 20 ->
                            create_goods(lists:duplicate(5, 632000), PlayerStatus, X, Y);
                        true ->
                            create_goods(lists:duplicate(2, 632000), PlayerStatus, X, Y)
                    end;
                PlayerLv =< 70 ->
                    if
                        Time =< 10 ->
                            create_goods([632000, 632001], PlayerStatus, X, Y);
                        Time =< 20 ->
                            create_goods(lists:duplicate(7, 632000), PlayerStatus, X, Y);
                        true ->
                            create_goods(lists:duplicate(3, 632000), PlayerStatus, X, Y)
                    end;
                true ->
                    if
                        Time =< 10 ->
                            create_goods([632001, 632000, 632000, 632000, 632000, 632000], PlayerStatus, X, Y);
                        Time =< 20 ->
                            create_goods(lists:duplicate(5, 632001), PlayerStatus, X, Y);
                        true ->
                            create_goods(lists:duplicate(5, 632000), PlayerStatus, X, Y)
                    end
            end;
        _ ->
            skip
    end.

%% 生成掉落
create_goods([], _PlayerStatus, _X, _Y) -> skip;
create_goods([GoodsTypeId | T], PlayerStatus, X, Y) ->
    PlayerId = PlayerStatus#player_status.id,
    _Platform = "",
    Platform = pt:write_string(_Platform),
    SerNum = 0,
    SceneId = PlayerStatus#player_status.scene,
    CopyId = PlayerStatus#player_status.copy_id,
    case GoodsTypeId of
        0 ->
            skip;
        _ ->
            %GoodsTypeId = 501204,
            GoodsNum = 1,
            ExpireTime = util:unixtime() + ?GOODS_DROP_EXPIRE_TIME,
            RandX = util:rand(1, 5) - 3 + X,
            RandY = util:rand(1, 5) - 3 + Y,
            DropId = mod_drop:get_drop_id(),
            GoodsDrop = #ets_drop{ 
                id = DropId,
                player_id = PlayerId,
                copy_id = CopyId,
                scene = SceneId,
                goods_id = GoodsTypeId,
                num = GoodsNum,
                broad = 1,
                expire_time = ExpireTime,
                x = RandX,
                y = RandY
            },
            mod_drop:add_drop(GoodsDrop),
            DropBin = [<<DropId:32, GoodsTypeId:32, GoodsNum:32, PlayerId:32, Platform/binary, SerNum:16>>],
            {ok, BinData} = pt_120:write(12017, [0, ?GOODS_DROP_EXPIRE_TIME, SceneId, DropBin, RandX, RandY]),
            lib_player:update_player_info(PlayerId, [{vip_dun_scene_send, BinData}])
    end,
    create_goods(T, PlayerStatus, X, Y).

%% 答题奖励
send_quiz_award(PlayerStatus, Res, Time, HalfAward, X, Y) ->
    %VipType = PlayerStatus#player_status.vip#status_vip.vip_type,
    case Res of
        %% 答对
        1 ->
            if
                Time =< 5 ->
                    case HalfAward > 0 of
                        true -> 
                            skip;
                        false ->
                            create_goods(lists:duplicate(1, 632001), PlayerStatus, X, Y)
                    end;
                Time =< 15 ->
                    case HalfAward > 0 of
                        true -> 
                            create_goods(lists:duplicate(2, 632000), PlayerStatus, X, Y);
                        false ->
                            create_goods(lists:duplicate(5, 632000), PlayerStatus, X, Y)
                    end;
                true ->
                    case HalfAward > 0 of
                        true -> 
                            create_goods(lists:duplicate(1, 632000), PlayerStatus, X, Y);
                        false ->
                            create_goods(lists:duplicate(3, 632000), PlayerStatus, X, Y)
                    end
            end;
        %% 答错
        _ ->
            case HalfAward > 0 of
                true -> 
                    skip;
                false ->
                    create_goods(lists:duplicate(1, 632000), PlayerStatus, X, Y)
            end
    end.

%% 减少技能数量
minus_skill(PlayerId, Skill, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            NewSkill = lists:delete(Skill, PlayerDun#player_dun.skill_list),
            NewPlayerDun = PlayerDun#player_dun{
                skill_list = NewSkill
            },
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.

get_rand_goods(GoodsTypeIdList) ->
    AllPro = count_all_pro(GoodsTypeIdList, 0),
    case AllPro < 0 of
        true -> 
            [];
        false ->
            RandNum = util:rand(1, AllPro),
            get_rand_num(GoodsTypeIdList, RandNum)
    end.

count_all_pro([], Count) -> Count;
count_all_pro([H | T], Count) ->
    case H of
        {_GoodsId, _GoodsNum, GoodsPro} ->
            count_all_pro(T, Count + GoodsPro);
        _ ->
            count_all_pro(T, Count)
    end.

get_rand_num([], _RandNum) -> [];
get_rand_num([H | T], RandNum) ->
    case H of
        {GoodsId, GoodsNum, GoodsPro} ->
            case GoodsPro >= RandNum of
                true -> 
                    lists:duplicate(GoodsNum, GoodsId);
                false -> 
                    get_rand_num(T, RandNum - GoodsPro)
            end;
        _ ->
            get_rand_num(T, RandNum)
    end.

%% 杀怪处理
kill_mon(PlayerStatus, MonId) ->
    PlayerId = PlayerStatus#player_status.id,
    MonTypeId1 = data_vip_dun:get_vip_dun_config(mon_type_id1),
    MonTypeId2 = data_vip_dun:get_vip_dun_config(mon_type_id2),
    MonTypeId3 = data_vip_dun:get_vip_dun_config(mon_type_id3),
    MonTypeId4 = data_vip_dun:get_vip_dun_config(mon_type_id4),
    MonTypeId5 = data_vip_dun:get_vip_dun_config(mon_type_id0),
    case lists:member(MonId, [MonTypeId1, MonTypeId2, MonTypeId3, MonTypeId4, MonTypeId5]) of
        true ->
            case MonId =:= MonTypeId5 of
                true ->
                    mod_vip_dun:send_goods_award(PlayerStatus, MonId);
                false ->
                    %spawn(fun() ->
                    %            timer:sleep(2000),
                    %            mod_vip_dun:send_goods_award(PlayerStatus, MonId)
                    %    end)
                    mod_vip_dun:send_goods_award(PlayerStatus, MonId)
            end;
        false ->
            skip
    end,
    MonBossId = data_vip_dun:get_vip_dun_config(mon_boss_id),
    MonMultiId1 = data_vip_dun:get_vip_dun_config(mon_multi_id1),
    MonMultiId2 = data_vip_dun:get_vip_dun_config(mon_multi_id2),
    MonMultiId3 = data_vip_dun:get_vip_dun_config(mon_multi_id3),
    MonMultiId4 = data_vip_dun:get_vip_dun_config(mon_multi_id4),
    case lists:member(MonId, [MonBossId, MonMultiId1, MonMultiId2, MonMultiId3, MonMultiId4]) of
        true ->
            mod_vip_dun:boss_die(PlayerId, MonId);
        false ->
            skip
    end.

%% 发送战斗/采集奖励
send_goods_award(PlayerStatus, MonId, VipDunState) ->
    PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            MonTypeId1 = data_vip_dun:get_vip_dun_config(mon_type_id1),
            MonTypeId2 = data_vip_dun:get_vip_dun_config(mon_type_id2),
            MonTypeId3 = data_vip_dun:get_vip_dun_config(mon_type_id3),
            MonTypeId4 = data_vip_dun:get_vip_dun_config(mon_type_id4),
            MonTypeId5 = data_vip_dun:get_vip_dun_config(mon_type_id0),
            case lists:member(MonId, [MonTypeId1, MonTypeId2, MonTypeId3, MonTypeId4, MonTypeId5]) of
                true ->
                    TotalNum = PlayerDun#player_dun.total_num,
                    GoodsTypeIdList = get_rand_goods(data_vip_dun_goods:get_vip_dun_goods_list(TotalNum)),
                    {X, Y} = PlayerDun#player_dun.now_xy,
                    create_goods(GoodsTypeIdList, PlayerStatus, X, Y),
                    NewPlayerDun = PlayerDun#player_dun{
                        can_flag = 1,
                        battle_start_time = 0
                    },
                    case MonId =:= MonTypeId5 of
                        true ->
                            send_45103(PlayerId, NewPlayerDun, [], 0);
                        false ->
                            skip
                    end,
                    NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
                    VipDunState#vip_dun_state{
                        player_dun = NewAllPlayerDun
                    };
                false ->
                    VipDunState
            end;
        _ ->
            VipDunState
    end.

%% 购买骰子次数
check_buy_num(PlayerId, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            lib_player:update_player_info(PlayerId, [{check_vip_dun_buy_num, PlayerDun#player_dun.buy_num + 1}]);
        _ ->
            skip
    end.

%% 购买骰子次数
buy_num(PlayerId, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            NewPlayerDun = PlayerDun#player_dun{
                flag_num = PlayerDun#player_dun.flag_num + 1,
                buy_num = PlayerDun#player_dun.buy_num + 1
            },
            %% 返回45113协议
            Res = 1,
            RestNum = NewPlayerDun#player_dun.flag_num,
            NextGold = data_vip_dun:get_vip_dun_buy_gold(NewPlayerDun#player_dun.buy_num + 1),
            {ok, BinData} = pt_451:write(45113, [Res, RestNum, NextGold]),
            lib_player:update_player_info(PlayerId, [{vip_dun_scene_send, BinData}]),
            %% 更新状态
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.

%% VIP副本商店
get_vip_dun_shop_list(PlayerStatus, VipDunState) ->
    PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            TotalNum = PlayerDun#player_dun.total_num,
            _GoodsList = data_vip_dun:get_vip_dun_shop_list(TotalNum),
            GoodsList = goods_deal(_GoodsList, []),
            %io:format("GoodsList:~p~n", [GoodsList]),
            Bin = pp_dungeon_secret_shop:pack(GoodsList, PlayerStatus#player_status.scene, PlayerId),
            {ok, BinData} = pt_612:write(61200, Bin),
            lib_player:update_player_info(PlayerId, [{vip_dun_scene_send, BinData}]);
        _ ->
            skip
    end.

%% call操作获取VIP副本商店列表
get_call_shop_list(PlayerId, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            TotalNum = PlayerDun#player_dun.total_num,
            data_vip_dun:get_vip_dun_shop_list(TotalNum);
        _ ->
            []
    end.

%% #base_secret_shop{} 转为{goods_id, price_type, price}
goods_deal([], L) -> L;
goods_deal([H | T], L) ->
    case is_record(H, base_dungeon_shop) of
        true -> 
            L1 = [{H#base_dungeon_shop.goods_id, 1, H#base_dungeon_shop.price, H#base_dungeon_shop.limit_num, H#base_dungeon_shop.order} | L];
        false -> 
            L1 = L
    end,
    goods_deal(T, L1).

%% 若结束时技能格未使用，每剩余一个技能加2个迷你成长丹
rest_skill_mail(PlayerDun) ->
    PlayerId = PlayerDun#player_dun.player_id,
    RestSkill = length(PlayerDun#player_dun.skill_list),
    case RestSkill > 0 of
        true ->
            GoodsId = 632000,
            GoodsNum = RestSkill * 2,
            Title = data_vip_dun_text:get_vip_dun_text(2),
            Content = io_lib:format(data_vip_dun_text:get_vip_dun_text(3), [RestSkill, GoodsNum]),
            lib_mail:send_sys_mail_bg([PlayerId], Title, Content, GoodsId, 2, 0, 0, GoodsNum, 0, 0, 0, 0);
        false ->
            skip
    end.

%% 赌神(猜大小)
guessing_point(PlayerStatus, Ans, VipDunState) ->
    PlayerId = PlayerStatus#player_status.id,
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            case PlayerDun#player_dun.now_state =:= 11 andalso PlayerDun#player_dun.can_flag =:= 2 of
                true ->
                    Point = util:rand(1, 6),
                    case (Point > 3 andalso Ans =:= 1) orelse (Point =< 3 andalso Ans =:= 2) of
                        true -> 
                            Res = 1;
                        false ->
                            Res = 2
                    end,
                    {X, Y} = PlayerDun#player_dun.now_xy,
                    %% 发送奖励
                    spawn(fun() ->
                                timer:sleep(3000),
                                case Res of
                                    1 ->
                                        case PlayerDun#player_dun.half_award > 0 of
                                            true ->
                                                create_goods(lists:duplicate(5, 632000), PlayerStatus, X, Y);
                                            false ->
                                                create_goods([632001], PlayerStatus, X, Y)
                                        end;
                                    _ ->
                                        case PlayerDun#player_dun.half_award > 0 of
                                            true ->
                                                skip;
                                            false ->
                                                create_goods([632000], PlayerStatus, X, Y)
                                        end
                                end
                        end),
                    {ok, BinData} = pt_451:write(45115, [Res, Point]),
                    lib_player:update_player_info(PlayerId, [{vip_dun_scene_send, BinData}]),
                    NewPlayerDun = PlayerDun#player_dun{
                        can_flag = 1
                    },
                    NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
                    VipDunState#vip_dun_state{
                        player_dun = NewAllPlayerDun
                    };
                false ->
                    %% 当前状态不能压大小
                    {ok, BinData} = pt_451:write(45115, [3, 0]),
                    lib_player:update_player_info(PlayerId, [{vip_dun_scene_send, BinData}]),
                    VipDunState
            end;
        _ ->
            VipDunState
    end.

%% 圈数加一(成功则传送玩家至第一格，失败则不做处理)
add_round(PlayerId, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            %% 所有格子列表
            AllCells = data_vip_dun:get_vip_dun_config(vip_dun_cell),
            Len = length(AllCells),
            NowNum = PlayerDun#player_dun.now_num,
            case NowNum > Len of
                %% 一圈未跑完
                false ->
                    VipDunState;
                true ->
                    NewNum = NowNum rem (Len + 1),
                    {NewXY, NewState} = lists:nth(NewNum, AllCells),
                    XYList = lists:sublist(AllCells, NowNum + 1, NewNum),
                    %% 更新信息
                    NewPlayerDun = PlayerDun#player_dun{
                        now_num = NewNum,
                        now_state = NewState,
                        now_xy = NewXY,
                        flag_num = PlayerDun#player_dun.flag_num + 1,
                        can_flag = 1
                    },
                    send_45103(PlayerId, NewPlayerDun, XYList, 0),
                    NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
                    VipDunState#vip_dun_state{
                        player_dun = NewAllPlayerDun
                    }
            end;
        _ ->
            VipDunState
    end.

%% BOSS格生成4个小怪
create_four_mon(PlayerId, X, Y, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            MonId1 = data_vip_dun:get_vip_dun_config(mon_multi_id1),
            MonId2 = data_vip_dun:get_vip_dun_config(mon_multi_id2),
            MonId3 = data_vip_dun:get_vip_dun_config(mon_multi_id3),
            MonId4 = data_vip_dun:get_vip_dun_config(mon_multi_id4),
            SceneId = data_vip_dun:get_vip_dun_config(scene_id),
            CopyId = PlayerDun#player_dun.copy_id,
            BroadCast = 1,
            %{X, Y} = PlayerDun#player_dun.now_xy,
            {X1, Y1} = {X + 2, Y + 2},
            {X2, Y2} = {X + 2, Y - 2},
            {X3, Y3} = {X - 2, Y + 2},
            {X4, Y4} = {X - 2, Y - 2},
            MonType = 0,
            lib_mon:async_create_mon(MonId1, SceneId, X1, Y1, MonType, CopyId, BroadCast, []),
            lib_mon:async_create_mon(MonId2, SceneId, X2, Y2, MonType, CopyId, BroadCast, []),
            lib_mon:async_create_mon(MonId3, SceneId, X3, Y3, MonType, CopyId, BroadCast, []),
            lib_mon:async_create_mon(MonId4, SceneId, X4, Y4, MonType, CopyId, BroadCast, []),
            Rand = util:rand(1, 4),
            NeedKill = case Rand of
                1 -> MonId1;
                2 -> MonId2;
                3 -> MonId3;
                _ -> MonId4
            end,
            Str = case Rand of
                1 -> data_vip_dun_text:get_vip_dun_text(4);
                2 -> data_vip_dun_text:get_vip_dun_text(5);
                3 -> data_vip_dun_text:get_vip_dun_text(6);
                4 -> data_vip_dun_text:get_vip_dun_text(7)
            end,
            {ok, BinData} = pt_121:write(12103, [PlayerDun#player_dun.boss_id, Str]),
            spawn(fun() ->
                        timer:sleep(1000),
                        lib_player:update_player_info(PlayerId, [{vip_dun_send, BinData}])
                end),
            %% 更新信息
            NewPlayerDun = PlayerDun#player_dun{
                talk_type = Rand,
                need_kill_mon = NeedKill
            },
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.

%% 更新BOSS的ID
update_boss_id(PlayerId, BossId, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            %% 更新信息
            NewPlayerDun = PlayerDun#player_dun{
                boss_id = BossId
            },
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.

%% BOSS死亡
boss_die(PlayerId, MonId, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            PlayerLv = PlayerDun#player_dun.player_lv,
            {X, Y} = PlayerDun#player_dun.now_xy,
            %% 判定是否正确
            GoodsList =case PlayerDun#player_dun.need_kill_mon of
                %% 正确击杀
                MonId ->
                    if
                        PlayerLv =< 60 ->
                            [632001] ++ lists:duplicate(5, 632000);
                        PlayerLv =< 70 ->
                            [632001] ++ lists:duplicate(10, 632000);
                        true ->
                            [632001, 632001] ++ lists:duplicate(5, 632000)
                    end;
                %% 错误击杀
                _ ->
                    if
                        PlayerLv =< 60 ->
                            lists:duplicate(3, 632000);
                        PlayerLv =< 70 ->
                            lists:duplicate(6, 632000);
                        true ->
                            [632001]
                    end
            end,
            NewPlayerDun = PlayerDun#player_dun{
                boss_id = 0,
                talk_type = 0,
                need_kill_mon = 0,
                can_flag = 1
            },
            %% 清怪
            SceneId = data_vip_dun:get_vip_dun_config(scene_id),
            CopyId = PlayerDun#player_dun.copy_id,
            lib_mon:clear_scene_mon(SceneId, CopyId, 1),
            %% 生成掉落
            lib_player:update_player_info(PlayerId, [{vip_dun_create_goods, [GoodsList, X, Y]}]),
            %send_45103(PlayerId, NewPlayerDun, [], 0),
            spawn(fun() ->
                        timer:sleep(1500),
                        send_45103(PlayerId, NewPlayerDun, [{PlayerDun#player_dun.now_xy, 14}], 1)
                        %% 把玩家移回原格，发送奖励
            %            timer:sleep(1000),
            %            lib_player:update_player_info(PlayerId, [{vip_dun_send_back, [X, Y]}])
                end),
            %% 更新信息
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.

%% 跳到第几格
goto(PlayerId, Num, VipDunState) ->
    AllPlayerDun = VipDunState#vip_dun_state.player_dun,
    case dict:find(PlayerId, AllPlayerDun) of
        {ok, PlayerDun} when is_record(PlayerDun, player_dun) ->
            AllCells = data_vip_dun:get_vip_dun_config(vip_dun_cell),
            Len = length(AllCells),
            {NewXY, NewState} = case Num > Len of
                true ->
                    lists:nth(Len, AllCells);
                false ->
                    lists:nth(Num, AllCells)
            end,
            NewNum = Num,
            _NewPlayerDun = flag_state(NewState, PlayerDun, NewXY, NewNum, 0),
            {X, Y} = NewXY,
            SceneId = data_vip_dun:get_vip_dun_config(scene_id),
            CopyId = PlayerDun#player_dun.copy_id,
            lib_scene:player_change_scene(PlayerId, SceneId, CopyId, X, Y, false),
            %% 更新信息
            NewPlayerDun = _NewPlayerDun#player_dun{
            },
            send_45103(PlayerId, NewPlayerDun, [], 0),
            NewAllPlayerDun = dict:store(PlayerId, NewPlayerDun, AllPlayerDun),
            VipDunState#vip_dun_state{
                player_dun = NewAllPlayerDun
            };
        _ ->
            VipDunState
    end.
