%%%--------------------------------------
%%% @Module  : pp_marriage
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.24
%%% @Description:  结婚系统
%%%--------------------------------------

-module(pp_marriage).
-compile(export_all).
-include("common.hrl").
-include("server.hrl").
-include("unite.hrl").
-include("marriage.hrl").

%% 男方求婚
handle(27100, Status, [Content]) ->
    {Res, NewStatus} = lib_marriage:propose_check([Status, Content]),
    %io:format("Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27100, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, NewStatus};

%% 申请结婚(998做情缘任务，3000做情比金坚任务，6000可以直接登记)
handle(27101, Status, _Bin) ->
    Res = lib_marriage:register_marry(Status),
    %io:format("27101 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27101, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 查看结婚进度
handle(27102, Status, _Bin) ->
    {Res, AppNow, AppNeed, TaskFlag} = lib_marriage:check_marry_state(Status),
    %io:format("Marriage:~p~n", [Status#player_status.marriage]),
    %io:format("27102 state:~p~n", [[Res, AppNow, AppNeed, TaskFlag]]),
    %io:format("is_cruise:~p~n", [Status#player_status.marriage#status_marriage.is_cruise]),
    %io:format("Time1:~p, Time2:~p~n", [Status#player_status.marriage#status_marriage.wedding_time, Status#player_status.marriage#status_marriage.cruise_time]),
    {ok, BinData} = pt_271:write(27102, [Res, AppNow, AppNeed, TaskFlag]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 接任务
handle(27103, Status, _Bin) ->
    {Res, Task} = lib_marriage_task:get_task(Status),
    %io:format("27103 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27103, [Res, Task]),
    case Res of
        1 -> 
            lib_server_send:send_to_uid(Status#player_status.marriage#status_marriage.parner_id, BinData);
        _ -> 
            skip
    end,
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 交任务
handle(27104, Status, _Bin) ->
    Res = lib_marriage_task:finish_task(Status),
    case Res of
        1 ->
            ParnerId = Status#player_status.marriage#status_marriage.parner_id,
            {ok, BinData1} = pt_271:write(27108, [5]),
            lib_server_send:send_one(Status#player_status.socket, BinData1),
            lib_server_send:send_to_uid(ParnerId, BinData1);
        _ -> 
            skip
    end,
    %io:format("27104 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27104, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 获得情比金坚任务NPC坐标
handle(27105, Status, _Bin) ->
    NPCList = mod_marriage:get_npc(Status#player_status.id),
    %io:format("NPCList:~p~n", [NPCList]),
    Bin = pack_list2(NPCList),
    {ok, BinData} = pt_271:write(27105, Bin),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 领取情比金坚任务定情信物
handle(27106, Status, _Bin) ->
    Res = lib_marriage_task:get_task_thing(Status),
    case Res of
        1 -> 
            {ok, BinData1} = pt_271:write(27108, [3]),
            lib_server_send:send_one(Status#player_status.socket, BinData1);
        _ -> 
            skip
    end,
    %io:format("27106 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27106, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 上交情比金坚任务定情信物
handle(27107, Status, _Bin) ->
    Res = lib_marriage_task:handle_task_thing(Status),
    case Res of
        1 -> 
            {ok, BinData1} = pt_271:write(27108, [4]),
            lib_server_send:send_one(Status#player_status.socket, BinData1);
        _ -> 
            skip
    end,
    %io:format("27107 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27107, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 情比金坚任务状态
handle(27108, Status, _Bin) ->
    Res = Status#player_status.marriage#status_marriage.task#marriage_task.task_flag,
    %io:format("27108 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27108, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 任务
handle(27109, Status, _Bin) ->
    {Res, Rela} = lib_marriage:task_rela(Status),
    %io:format("27109 Res:~p, Rela:~p~n", [Res, Rela]),
    {ok, BinData} = pt_271:write(27109, [Res, Rela]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 放弃任务
handle(27110, Status, _Bin) ->
    Res = lib_marriage_task:giveup_task(Status),
    %io:format("27110 Res:~p~n", [Res]),
    case Res of
        1 ->
            ParnerId = Status#player_status.marriage#status_marriage.parner_id,
            {ok, BinData1} = pt_271:write(27108, [1]),
            lib_server_send:send_one(Status#player_status.socket, BinData1),
            lib_server_send:send_to_uid(ParnerId, BinData1);
        _ ->
            skip
    end,
    {ok, BinData} = pt_271:write(27110, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 女方回应求婚
handle(27112, Status, _Bin) ->
    {Res, NewStatus} = lib_marriage:register_check(Status),
    %io:format("Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27112, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, NewStatus};

%% 巡游预约(预约巡游等级和时间)
handle(27115, Status, [Level, Hour]) ->
    case util:unixtime() > Status#player_status.marriage#status_marriage.cruise_time + 1800 andalso Status#player_status.marriage#status_marriage.cruise_time =/= 0 of
        false ->
            %% 数据验证
            case Level >= 1 andalso Level =< 3 andalso Hour >= 9 andalso Hour =< 21 of
                true ->
                    {Res, NewStatus} = lib_marriage_cruise:cruise_check([Status, Level, Hour]);
                false ->
                    {Res, NewStatus} = {0, Status}
            end,
            %%    io:format("27115 Res:~p~n", [Res]),
            {ok, BinData} = pt_271:write(27115, [Res]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            {ok, NewStatus};
        %% 已完成巡游，使用道具预约
        true ->
            {ok, BinData} = pt_271:write(27190, [2, Level, Hour]),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end;

%% (公共线)巡游开始(服务器主动发，并每分钟发一次)
handle(27117, UniteStatus, _Bin) ->
    List = mod_marriage:get_all_cruise(),
    lib_marriage_cruise:send_resttime_for_one(List, UniteStatus);

%% 开始巡游
handle(27118, Status, _Bin) ->
    case lib_marriage:marry_state(Status#player_status.marriage) of
        %% 正在巡游则自己同步坐标
        8 -> 
            handle(27124, Status, no);
        _ ->
            Res = lib_marriage_cruise:cruise_start(Status),
            %%    io:format("27118 Res:~p~n", [Res]),
            {ok, BinData} = pt_271:write(27118, [Res]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            case Res of
                1 ->
                    ParnerId = Status#player_status.marriage#status_marriage.parner_id,
                    lib_server_send:send_to_uid(ParnerId, BinData);
                _ ->
                    skip
            end
    end;

%% 剩余数量
handle(27119, Status, [Type]) ->
    Res = lib_marriage_cruise:rest_num([Status, Type]),
%%    io:format("27119 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27119, [Type, Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 购买
handle(27120, Status, [Type, Num]) ->
    {Res, NewStatus, TotalNum} = lib_marriage_cruise:buy_num([Status, Type, Num]),
%%    io:format("27120 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27120, [Res, Type, TotalNum]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, NewStatus};

%% 爱的宣言
handle(27122, Status, [Content]) ->
    {Res, CardNum} = lib_marriage_cruise:cruise_card([Status, Content]),
    %io:format("27122 Res:~p, CardNum:~p~n", [Res, CardNum]),
    {ok, BinData} = pt_271:write(27122, [Res, CardNum]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 发送喜糖
handle(27123, Status, _Bin) ->
    {Res, Candies} = lib_marriage_cruise:cruise_candies(Status),
%%    io:format("27123 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27123, [Res, Candies]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 传送到婚车
handle(27124, Status, _Bin) ->
    Res = lib_marriage_cruise:send_to_car(Status),
%%    io:format("27124 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27124, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 拜堂预约(获得服务器当前时间)
handle(27130, Status, _Bin) ->
    Time = util:unixtime(),
    {ok, BinData} = pt_271:write(27130, [Time]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, Status};

%% 拜堂预约(预约婚礼等级和时间)
handle(27131, Status, [Level, Hour]) ->
    %io:format("Time:~p~n", [Status#player_status.marriage#status_marriage.wedding_time]),
    case util:unixtime() > Status#player_status.marriage#status_marriage.wedding_time + 1800 andalso Status#player_status.marriage#status_marriage.wedding_time =/= 0 of
        false ->
            %io:format("Time:~p~n", [Status#player_status.marriage#status_marriage.wedding_time]),
            %% 数据验证
            case Level >= 1 andalso Level =< 3 andalso Hour >= 9 andalso Hour =< 21 of
                true ->
                    {Res, NewStatus} = lib_marriage:wedding_check(Status, Level, Hour);
                false ->
                    {Res, NewStatus} = {0, Status}
            end,
            case Res of
                1 ->
                    {ok, BinData2} = pt_271:write(27131, [Res]),
                    lib_server_send:send_to_uid(Status#player_status.marriage#status_marriage.parner_id, BinData2);
                _ ->
                    skip
            end,
            %io:format("27131 Res:~p~n", [Res]),
            {ok, BinData} = pt_271:write(27131, [Res]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            {ok, NewStatus};
        %% 已完成婚宴，使用道具预约婚宴
        true ->
            {ok, BinData} = pt_271:write(27190, [1, Level, Hour]),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end;

%% 编辑喜帖并发送
handle(27132, Status, [Content, List]) ->
    %% 数据验证
    Marriage = mod_marriage:get_marry_info(Status#player_status.id),
    case is_record(Marriage, marriage) andalso is_list(List) of
        true ->
%%            _WeddingType = Marriage#marriage.wedding_type,
%%            case _WeddingType =/= 2 andalso _WeddingType =/= 3 of
%%                true ->
%%                    Res = 4;
%%                false ->
%%                    Res = lib_marriage:edit_send(Content, Status, List)
%%            end;
            Res = lib_marriage:edit_send(Content, Status, List);
        false -> 
            Res = 0
    end,
    %io:format("Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27132, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 可邀请宾客人数
handle(27133, Status, _Bin) ->
    %% 数据验证
    Marriage = mod_marriage:get_marry_info(Status#player_status.id),
    %io:format("Id:~p, Marriage:~p~n", [Status#player_status.id, Marriage]),
    case is_record(Marriage, marriage) of
        true ->
            %io:format("1~n"),
            MyId = Status#player_status.id,
            ParnerId = case Marriage#marriage.male_id of
                MyId -> Marriage#marriage.female_id;
                _ -> Marriage#marriage.male_id
            end,
            WeddingHour = (Marriage#marriage.wedding_time - util:unixdate()) div 3600,
            %io:format("Marriage:~p~n", [Marriage]),
            MaxGuest = Marriage#marriage.wedding_card,
            WeddingType = Marriage#marriage.wedding_type;
        false ->
            %io:format("2~n"),
            ParnerId = 0,
            WeddingHour = 0,
            MaxGuest = 0,
            WeddingType = 0
    end,
    case ParnerId of
        0 ->
            skip;
        _ ->
            [NickName, Sex, _Lv, Career, _Realm, _GuildId, _Mount_limit, _HusongNpc, Image|_] = lib_player:get_player_low_data(ParnerId),
%%             Image = lib_player:get_player_normal_image(ParnerId),
            List = mod_marriage:get_all_guest(Marriage#marriage.id, Status#player_status.id),
            %io:format("MaxGuest:~p~n", [MaxGuest]),
            %io:format("WeddingHour:~p~n", [WeddingHour]),
            Bin = pack_list(ParnerId, NickName, Career, Sex, Image, MaxGuest, WeddingHour, WeddingType, List),
            {ok, BinData} = pt_271:write(27133, Bin),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end;

%% (公共线)婚礼倒计时
handle(27135, _UniteStatus, _) ->
    %List1 = mod_marriage:get_all_wedding(),
    %lib_marriage:send_countdown(List1);
    ok;

%% (公共线)婚礼开始
handle(27136, _UniteStatus, _) ->
    %List2 = mod_marriage:get_all_wedding(),
    %lib_marriage:send_resttime(List2);
    ok;

%% 进入婚礼场景
handle(27137, Status, [WeddingId]) ->
    %% 数据验证
    case WeddingId >= 0 of
        true ->
            {Bin, NewStatus} = lib_marriage:enter_wedding(Status, WeddingId),
            {ok, BinData} = pt_271:write(27137, Bin),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            {ok, mount, NewStatus};
        false ->
            skip
    end;

%% (公共线)婚宴状态
handle(27138, UniteStatus, [WeddingId]) ->
    Marriage = mod_marriage:get_wedding_info(WeddingId),
    case is_record(Marriage, marriage) of
        true ->
            Res = Marriage#marriage.state,
            %io:format("27138 Res:~p~n", [Res]),
            {ok, BinData} = pt_271:write(27138, [Res]),
            lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData);
        false ->
            skip
    end;

%% 迎接新娘
handle(27139, Status, _) ->
    %% 数据验证
    Res = lib_marriage:meet(Status),
    %io:format("27139 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27139, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 跳完火盆，交任务
handle(27140, Status, _) ->
    Res = lib_marriage:finish_meet(Status),
    {ok, BinData} = pt_271:write(27140, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 开始拜堂
handle(27141, Status, _) ->
    %% 数据验证
    %% 把双方传送到拜堂地方
    Marriage = mod_marriage:get_marry_info(Status#player_status.id),
    Res = lib_marriage:ceremony(Status),
    case is_record(Marriage, marriage) of
        true ->
            case Res of
                1 ->
                    lib_scene:player_change_scene(Marriage#marriage.male_id, Status#player_status.scene, Status#player_status.copy_id, 40, 45, false),
                    lib_scene:player_change_scene(Marriage#marriage.female_id, Status#player_status.scene, Status#player_status.copy_id, 42, 43, false);
                _ -> skip
            end;
        false ->
            skip
    end,
    %io:format("27141 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27141, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% (公共线)亲密无双
handle(27142, UniteStatus, [ActionId]) ->
    %io:format("27142 ActionId:~p~n", [ActionId]),
    {ok, BinData} = pt_271:write(27142, [ActionId, UniteStatus#unite_status.id]),
    lib_unite_send:send_to_scene(UniteStatus#unite_status.scene, UniteStatus#unite_status.copy_id, BinData);

%% (公共线)贺礼信息
handle(27143, UniteStatus, [WeddingId]) ->
    Marriage = mod_marriage:get_wedding_info(WeddingId),
    case is_record(Marriage, marriage) of
        true ->
            {ok, BinData} = pt_271:write(27143, [Marriage#marriage.male_coin, Marriage#marriage.male_gold, Marriage#marriage.female_coin, Marriage#marriage.female_gold, "", 0, 0, 1]),
            lib_unite_send:send_to_scene(UniteStatus#unite_status.scene, UniteStatus#unite_status.copy_id, BinData);
        false ->
            skip
    end;

%% 赠送贺礼
handle(27144, Status, [WeddingId, Type, To]) ->
    {Res, NewStatus} = lib_marriage:send_money(Status, WeddingId, Type, To),
    {ok, BinData} = pt_271:write(27144, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, NewStatus};

%% (公共线)偷吻新娘
handle(27145, UniteStatus, _) ->
    Rand = util:rand(1, 100),
    %io:format("27145 Rand:~p~n", [Rand]),
    case Rand > 50 of
        true ->
            %io:format("27145 true~n"),
            {ok, BinData} = pt_271:write(27145, [1, UniteStatus#unite_status.id]);
        false ->
            %io:format("27145 false~n"),
            {ok, BinData} = pt_271:write(27145, [0, UniteStatus#unite_status.id])
    end,
    lib_unite_send:send_to_scene(UniteStatus#unite_status.scene, UniteStatus#unite_status.copy_id, BinData);

%% 退出场景
handle(27148, Status, _) ->
    lib_marriage:quit_wedding(Status);

%% 购买喜帖
handle(27149, Status, [Num]) ->
    case Num > 0 of
        true ->
            {Res, NewStatus} = lib_marriage:buy_card(Status, Num),
            {ok, BinData} = pt_271:write(27149, [Res, Num]),
            %io:format("Res:~p, Num:~p~n", [Res, Num]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            {ok, NewStatus};
        false ->
            skip
    end;

%% 姻缘日志
handle(27151, Status, [Num]) ->
    case Num > 0 of
        true ->
            AllLog = mod_marriage:get_all_log(),
            PerPage = 9,
            PageNum = length(AllLog) div PerPage + 1,
            %io:format("PageNum:~p~n", [PageNum]),
            case Num =< PageNum of
                true ->
                    First = PerPage * (Num - 1),
                    _AllLog = lists:reverse(AllLog),
                    AllLog2 = resort(_AllLog, [], 0),
                    %io:format("AllLog2:~p~n", [AllLog2]),
                    AllLog3 = lists:nthtail(First, AllLog2),
                    AllLog4 = lists:sublist(AllLog3, PerPage),
                    %AllLog5 = lists:reverse(AllLog4),
                    %io:format("~p~n", [[Num, PageNum, AllLog4]]),
                    Bin = pack_list3(Num, PageNum, AllLog4),
                    {ok, BinData1} = pt_271:write(27151, Bin),
                    lib_server_send:send_one(Status#player_status.socket, BinData1);
                false ->
                    skip
            end;
        false ->
            skip
    end;

%% 索要喜帖
handle(27152, Status, [WeddingId]) ->
    case WeddingId > 0 of
        true ->
            Res = lib_marriage:ask_card([Status, WeddingId]),
            {ok, BinData} = pt_271:write(27152, [Res]),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        false ->
            skip
    end;

%% 喜糖
handle(27154, Status, [Type]) ->
    {Res, Num} = lib_marriage:wedding_candies([Status, Type]),
%%    io:format("Res:~p, Num:~p~n", [Res, Num]),
    {ok, BinData} = pt_271:write(27154, [Type, Res, Num]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 闹洞房
handle(27155, Status, []) ->
    %N = util:rand(1, 100),
    %Res = if
    %    N < 30 -> %% 发送两个技能
            {ok, BinData1} = pt_130:write(13034, [1, [{1, 500005}, {1, 500006}]]),
            lib_server_send:send_one(Status#player_status.socket, BinData1),
    %        1;
    %    true -> 0
    %end,
    {ok, BinData} = pt_271:write(27155, 1),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    ok;

%% 拜堂传送(传送宾客) 
handle(27156, Status, _) ->
    MarriageSceneId = data_marriage:get_marriage_config(scene_id),
    case Status#player_status.scene =:= MarriageSceneId of
        true ->
            List = [{45, 38}, {47, 42}, {46, 45}, {44, 48}, {43, 49}, {40, 50}, {38, 49}, {36, 48}, {45, 48}, {43, 50}, {40, 52}, {36, 52}, {35, 49}, {46, 47}, {47, 44}, {48, 40}, {45, 36}],
            Len = length(List),
            Rand = util:rand(1, Len),
            {X, Y} = lists:nth(Rand, List),
            lib_scene:player_change_scene(Status#player_status.id, MarriageSceneId, 0, X, Y, false);
        false ->
            skip
    end;

%% 已被预约的喜宴或巡游时段
handle(27157, Status, [Type]) ->
    List = mod_marriage:get_ordered_list(Type),
    Time = case Type of
        1 ->
            case Status#player_status.marriage#status_marriage.wedding_time > util:unixtime() of
                true ->
                    (Status#player_status.marriage#status_marriage.wedding_time - util:unixdate()) div 3600;
                false ->
                    0
            end;
        _ ->
            case Status#player_status.marriage#status_marriage.cruise_time > util:unixtime() of
                true ->
                    (Status#player_status.marriage#status_marriage.cruise_time - util:unixdate()) div 3600;
                false ->
                    0
            end
    end,
    {ok, BinData} = pt_271:write(27157, [List, Time, Type]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 预约协议离婚
handle(27170, Status, _) ->
    {Res, Str} = lib_marriage_other:check_agree_divorce(Status),
    case Res of
        1 ->
            {ok, BinData2} = pt_271:write(27170, [Res, Str]),
            lib_server_send:send_to_uid(Status#player_status.marriage#status_marriage.parner_id, BinData2);
        _ ->
            skip
    end,
    %io:format("27170 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27170, [Res, Str]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 确认协议离婚
handle(27171, Status, [Ans]) ->
    %io:format("Ans:~p~n", [Ans]),
    case Ans =:= 1 orelse Ans =:= 2 of
        true ->
            {Res, Str} = lib_marriage_other:ensure_agree_divorce([Status, Ans]),
            %io:format("27171 Res:~p~n", [Res]),
            case Res =:= 1 orelse Res =:= 0 of
                true ->
                    {ok, BinData} = pt_271:write(27171, [Res, Str]),
                    lib_server_send:send_one(Status#player_status.socket, BinData),
                    lib_server_send:send_to_uid(Status#player_status.marriage#status_marriage.parner_id, BinData);
                false ->
                    skip
            end;
        false ->
            skip
    end;

%% 强制离婚
handle(27172, Status, _) ->
    {Res, Str, NewStatus} = lib_marriage_other:force_divorce(Status),
    %io:format("27172 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27172, [Res, Str]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, NewStatus};

%% 强制离婚状态
handle(27173, Status, _) ->
    Res = lib_marriage_other:force_divorce_state(Status),
    %io:format("27173 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27173, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 单人离婚
handle(27174, Status, _) ->
    {Res, Str} = lib_marriage_other:single_divorce(Status),
    %io:format("27174 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27174, [Res, Str]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 取消强制离婚
handle(27175, Status, _) ->
    {Res, Str} = lib_marriage_other:cancel_force_divorce(Status),
    %io:format("27175 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27175, [Res, Str]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 获得结婚纪念日信息
handle(27180, Status, _) ->
    {Res, Str, Array, Total, Now} = lib_marriage_other:get_mark_info(Status),
    %io:format("27180 Res:~p, Array:~p~n", [Res, Array]),
    {ok, BinData} = pt_271:write(27180, [Res, Str, Array, Total, Now]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 领取奖励
handle(27181, Status, [TaskId]) ->
    case TaskId >= 1 andalso TaskId =< 6 of
        true ->
            {Res, Str} = lib_marriage_other:get_mark_award(Status, TaskId),
            %io:format("27181 Res:~p~n", [Res]),
            {ok, BinData} = pt_271:write(27181, [Res, Str]),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        false ->
            skip
    end;

%% 使用道具 拜堂预约(预约婚礼等级和时间)
handle(27191, Status, [Level, Hour]) ->
    %% 数据验证
    case Level >= 1 andalso Level =< 3 andalso Hour >= 9 andalso Hour =< 21 of
        true ->
            {Res, NewStatus} = lib_marriage_activity:item_wedding(Status, Level, Hour);
        false ->
            {Res, NewStatus} = {0, Status}
    end,
    %io:format("27131 Res:~p~n", [Res]),
    case Res of
        1 ->
            {ok, BinData2} = pt_271:write(27191, [Res]),
            lib_server_send:send_to_uid(Status#player_status.marriage#status_marriage.parner_id, BinData2);
        _ ->
            skip
    end,
    {ok, BinData} = pt_271:write(27191, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, NewStatus};

%% 使用道具 巡游预约(预约巡游等级和时间)
handle(27192, Status, [Level, Hour]) ->
    %% 数据验证
    case Level >= 1 andalso Level =< 3 andalso Hour >= 9 andalso Hour =< 21 of
        true ->
            {Res, NewStatus} = lib_marriage_activity:item_cruise(Status, Level, Hour);
        false ->
            {Res, NewStatus} = {0, Status}
    end,
%%    io:format("27115 Res:~p~n", [Res]),
    {ok, BinData} = pt_271:write(27192, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, NewStatus};

handle(_Cmd, _LogicStatus, _Data) ->
    ?DEBUG("pp_marriage no match", []),
    {error, "pp_marriage no match"}.

pack_list(ParnerId, NickName, Career, Sex, Image, MaxGuest, WeddingHour, WeddingType, List) ->
    %% List1
    Fun1 = fun(Elem1) ->
            GuestId = Elem1,
            <<GuestId:32>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List]),
    Size1  = length(List),
    %NewNickName = list_to_binary(NickName),
    NewNickName = NickName,
    LenNickName2 = byte_size(NewNickName),
    <<ParnerId:32, LenNickName2:16, NewNickName/binary, Career:8, Sex:8, Image:32, MaxGuest:16, WeddingHour:8, WeddingType:8, Size1:16, BinList1/binary>>.

pack_list2(NPCList) ->
    %% List1
    Fun1 = fun(Elem1) ->
            {Id, X, Y} = Elem1,
            <<Id:32, X:16, Y:16>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- NPCList]),
    Size1  = length(NPCList),
    <<Size1:16, BinList1/binary>>.

pack_list3(Num, PageNum, AllLog) ->
    %% List1
    Fun1 = fun(Elem1) ->
            {Type, Time, Marriage, N} = Elem1,
            {{Year, Month, Day}, {Hour, Min, _Sec}} = util:seconds_to_localtime(Time),
            MonthStr = case Month < 10 of
                true -> lists:concat(["0", Month]);
                false -> Month
            end,
            DayStr = case Day < 10 of
                true -> lists:concat(["0", Day]);
                false -> Day
            end,
            HourStr = case Hour < 10 of
                true -> lists:concat(["0", Hour]);
                false -> Hour
            end,
            MinStr = case Min < 10 of
                true -> lists:concat(["0", Min]);
                false -> Min
            end,
            TimeStr = lists:concat([Year, "-", MonthStr, "-", DayStr, " ", HourStr, ":", MinStr]),
            TimeStr1 = pt:write_string(TimeStr),
            MaleName = pt:write_string(Marriage#marriage.male_name),
            FemaleName = pt:write_string(Marriage#marriage.female_name),
            WeddingType = Marriage#marriage.wedding_type,
            CruiseType = Marriage#marriage.cruise_type,
            case Type of
                marry_log ->
                    <<TimeStr1/binary, MaleName/binary, FemaleName/binary, 1:8, N:16, WeddingType:8>>;
                wedding_log ->
                    <<TimeStr1/binary, MaleName/binary, FemaleName/binary, 2:8, Hour:16, WeddingType:8>>;
                cruise_log ->
                    <<TimeStr1/binary, MaleName/binary, FemaleName/binary, 3:8, Hour:16, CruiseType:8>>;
                _ ->
                    <<TimeStr1/binary, MaleName/binary, FemaleName/binary, 4:8, Hour:16, 1:8>>
            end
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- AllLog]),
    Size1  = length(AllLog),
    <<Num:16, PageNum:16, Size1:16, BinList1/binary>>.

resort([], L, _N) -> L;
resort([H | T], L, N) ->
    case H of
        {marry_log, RegisterTime, Marriage} ->
            case RegisterTime =/=0 andalso Marriage#marriage.male_id =/=0 of
                false ->
                    NewN = N,
                    L2 = L;
                true ->
                    NewN = N + 1,
                    L2 = [{marry_log, RegisterTime, Marriage, NewN} | L]
            end;
        {wedding_log, WeddingTime, Marriage} ->
            case WeddingTime =/=0 andalso Marriage#marriage.male_id =/= 0 of
                false ->
                    NewN = N,
                    L2 = L;
                true ->
                    NewN = N,
                    L2 = [{wedding_log, WeddingTime, Marriage, 0} | L]
            end;
        {cruise_log, CruiseTime, Marriage} ->
            case CruiseTime =/=0 andalso Marriage#marriage.male_id =/= 0 of
                false ->
                    NewN = N,
                    L2 = L;
                true ->
                    NewN = N,
                    L2 = [{cruise_log, CruiseTime, Marriage, 0} | L]
            end;
        {divorce_log, DivorceTime, Marriage} ->
            case DivorceTime =/=0 andalso Marriage#marriage.male_id =/= 0 of
                false ->
                    NewN = N,
                    L2 = L;
                true ->
                    NewN = N,
                    L2 = [{divorce_log, DivorceTime, Marriage, 0} | L]
            end;
        _ ->
            NewN = N,
            L2 = L
    end,
    resort(T, L2, NewN).
