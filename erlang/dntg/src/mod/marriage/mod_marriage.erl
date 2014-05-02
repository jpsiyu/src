%%%------------------------------------
%%% @Module  : mod_marriage
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.24
%%% @Description: 结婚系统
%%%------------------------------------
-module(mod_marriage).
-behaviour(gen_server).
-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([
        get_marry_info/1,
        get_wedding_info/1,
        get_wedding_guest/4,
        get_all_guest/2,
        get_my_guest/2,
        is_guest/2,
        marry/2,
        wedding/4,
        cruise/1,
        insert_guest/3,
        get_all_wedding/0,
        get_all_cruise/0,
        get_all_after_wedding/0,
        meeting/1,
        update_marriage_info/1,
        update_marriage_player/2,
        delete_info/1,
        enter_wedding/2,
        quit_wedding/1,
        all_in_wedding/1,
        is_in_wedding/2,
        clear_info/0,
        set_marriage_task/1,
        get_marriage_task/1,
        get_marriage_task_player/1,
        apply_marry/1,
        set_npc/1,
        get_npc/1,
        add_mood/1,
        add_mood2/1,
        clear_mood/0,
        clear_mood2/0,
        check_mood/1,
        check_mood2/1,
        get_all_log/0,
        get_today_num/2,
        get_today_num2/2,
        set_propose/1,
        get_propose/1,
        set_mon_id/1,
        get_mon_id/0,
        add_send_line/1,
        get_send_line/0,
        set_divorce_response/1,
        get_divorce_response/1,
        clear_divorce_response/1,
        clear_marriage/1,
        deal_divorce/0,
        get_ordered_list/1,
        clear_wedding_cruise_list/0,
        set_overtime/0
    ]).
-include("marriage.hrl").
-include("server.hrl").
-include("scene.hrl").

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%% 获取玩家结婚信息
get_marry_info(PlayerId) ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_marry_info, PlayerId}).

%% 获取婚宴信息
get_wedding_info(WeddingId) ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_wedding_info, WeddingId}).

%% 获取婚宴宾客信息
get_wedding_guest(WeddingId, GuestId, MaleId, FeMaleId) ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_wedding_guest, WeddingId, GuestId, MaleId, FeMaleId}).

%% 获取婚宴所有宾客信息
get_all_guest(WeddingId, PlayerId) ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_all_guest, WeddingId, PlayerId}).

%% 获取婚宴中男/女方所有宾客信息
get_my_guest(WeddingId, InviteId) ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_my_guest, WeddingId, InviteId}).

%% 判断是否为婚宴嘉宾
is_guest(WeddingId, PlayerId) ->
	gen_server:call(misc:get_global_pid(?MODULE),{is_guest, WeddingId, PlayerId}).

%% 结婚，数据插入内存
marry(MaleId, FemaleId) ->
	gen_server:cast(misc:get_global_pid(?MODULE),{marry, MaleId, FemaleId}).

%% 预约婚宴，数据插入内存
wedding(MaleId, FemaleId, Level, WeddingTime) ->
	gen_server:cast(misc:get_global_pid(?MODULE),{wedding, MaleId, FemaleId, Level, WeddingTime}).

%% 预约巡游，数据插入内存
cruise(Info) ->
	gen_server:cast(misc:get_global_pid(?MODULE),{cruise, Info}).

%% 婚宴宾客
insert_guest(MarriageId, GuestId, InviteId) ->
	gen_server:cast(misc:get_global_pid(?MODULE),{insert_guest, MarriageId, GuestId, InviteId}).

%% 获取正在举办的婚宴信息
get_all_wedding() ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_all_wedding}).

%% 获取正在举办的巡游信息
get_all_cruise() ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_all_cruise}).

%% 获取未举办的婚宴信息
get_all_after_wedding() ->
	gen_server:call(misc:get_global_pid(?MODULE),{get_all_after_wedding}).

%% 迎接完新娘
meeting(Marriage) ->
	gen_server:cast(misc:get_global_pid(?MODULE),{meeting, Marriage}).

%% 更新结婚信息(婚礼)
update_marriage_info(Marriage) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{update_marriage_info, Marriage}).

%% 更新结婚信息(玩家)
update_marriage_player(Marriage, Sex) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{update_marriage_player, Marriage, Sex}).

%% 删除信息
delete_info(Marriage) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{delete_info, Marriage}).

%% 进入婚宴
enter_wedding(WeddingId, PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{enter_wedding, WeddingId, PlayerId}).

%% 退出婚宴
quit_wedding(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{quit_wedding, PlayerId}).

%% 婚宴所有在线
all_in_wedding(WeddingId) ->
    gen_server:call(misc:get_global_pid(?MODULE),{all_in_wedding, WeddingId}).

%% 是否在婚宴
is_in_wedding(WeddingId, PlayerId) ->
    gen_server:call(misc:get_global_pid(?MODULE),{is_in_wedding, WeddingId, PlayerId}).

%% 清除数据
clear_info() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{clear_info}).

%% 更新结婚任务信息
set_marriage_task(MarriageTask) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{set_marriage_task, MarriageTask}).

%% 获得结婚任务信息
get_marriage_task(WeddingId) ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_marriage_task, WeddingId}).

%% 获得结婚任务信息
get_marriage_task_player(PlayerId) ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_marriage_task_player, PlayerId}).

%% 申请结婚
apply_marry(Info) ->
    gen_server:call(misc:get_global_pid(?MODULE),{apply_marry, Info}).

%% 更新npc信息
set_npc(Info) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{set_npc, Info}).

%% 获得npc信息
get_npc(PlayerId) ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_npc, PlayerId}).

%% 增加气氛值
add_mood(Info) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{add_mood, Info}).

%% 增加气氛值
add_mood2(Info) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{add_mood2, Info}).

%% 清除气氛值
clear_mood() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{clear_mood}).

%% 清除气氛值
clear_mood2() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{clear_mood2}).

%% 检测气氛值，发送称号
check_mood(Info) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{check_mood, Info}).

%% 检测气氛值，发送称号
check_mood2(Info) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{check_mood2, Info}).

%% 姻缘日志
get_all_log() ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_all_log}).

%% 今天第几对
get_today_num(RegisterTime, WeddingTime) ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_today_num, RegisterTime, WeddingTime}).

%% 今天第几对
get_today_num2(RegisterTime, CruiseTime) ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_today_num2, RegisterTime, CruiseTime}).

%% 求婚
set_propose(Info) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{set_propose, Info}).

%% 求婚
get_propose(Info) ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_propose, Info}).

%% 设置婚车ID
set_mon_id(Id) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{set_mon_id, Id}).

%% 获得婚车ID
get_mon_id() ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_mon_id}).

%% 传送排队
add_send_line(Info) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{add_send_line, Info}).

%% 传送排队
get_send_line() ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_send_line}).

%% 协商离婚
set_divorce_response([PlayerId, Ans]) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{set_divorce_response, PlayerId, Ans}).

%% 协商离婚
get_divorce_response(PlayerId) ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_divorce_response, PlayerId}).

%% 协商离婚
clear_divorce_response(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{clear_divorce_response, PlayerId}).

%% 清除结婚信息
clear_marriage(Info) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{clear_marriage, Info}).

%% 处理离婚事务
deal_divorce() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{deal_divorce}).

%% 已被预约的喜宴或巡游时段
get_ordered_list(Type) ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_ordered_list, Type}).

%% 喜宴或巡游时段初始化（每日0点清空）
clear_wedding_cruise_list() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{clear_wedding_cruise_list}).

%% 喜宴或巡游时段超时（每小时整理）
set_overtime() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{set_overtime}).

init([]) ->
    init_wedding_cruise_list(),
    case db:get_all(<<"select id, male_id, female_id, register_time, wedding_time, wedding_type, wedding_card, cruise_time, cruise_type, divorce, divorce_time, apply_divorce_time, mark_sure_time from marriage">>) of
        [] -> skip;
        List ->
            init_marriage(List)
    end,
    case db:get_all(<<"select marriage_id, male_id, female_id, register_time, wedding_time, wedding_type, wedding_card, cruise_time, cruise_type from marriage_item">>) of
        [] -> skip;
        List2 ->
            init_marriage_item(List2)
    end,
    sort_log(),
    {ok, 0}.

%% call
%% 获取玩家结婚信息
handle_call({get_marry_info, PlayerId}, _From, State) ->
    Reply = case get({marriage, PlayerId}) of
        undefined -> no;
        Marriage when is_record(Marriage, marriage) -> Marriage;
        _Any -> no
    end,
	{reply, Reply, State};

%% 获取婚宴信息
handle_call({get_wedding_info, WeddingId}, _From, State) ->
    Reply = case get({marriage_info, WeddingId}) of
        undefined -> no;
        Marriage when is_record(Marriage, marriage) -> Marriage;
        _Any -> no
    end,
	{reply, Reply, State};

%% 获取婚宴宾客信息
handle_call({get_wedding_guest, WeddingId, GuestId, MaleId, FeMaleId}, _From, State) ->
    Reply = case get({marriage_guest, WeddingId, GuestId, MaleId}) =:= undefined andalso get({marriage_guest, WeddingId, GuestId, FeMaleId}) =:= undefined of
        true -> no;
        false -> yes
    end,
	{reply, Reply, State};

%% 获取婚宴所有宾客信息
handle_call({get_all_guest, WeddingId, PlayerId}, _From, State) ->
    Reply = list_deal2(get(), [], WeddingId, PlayerId),
	{reply, Reply, State};

%% 获取婚宴中男/女方所有宾客信息
handle_call({get_my_guest, WeddingId, InviteId}, _From, State) ->
    Reply = list_deal3(get(), [], WeddingId, InviteId),
	{reply, Reply, State};

%% 判断是否为婚宴嘉宾
handle_call({is_guest, WeddingId, PlayerId}, _From, State) ->
    Reply = list_deal7(get(), WeddingId, PlayerId),
	{reply, Reply, State};

%% 获取正在举办的婚宴信息
handle_call({get_all_wedding}, _From, State) ->
    Reply = list_deal1(get(), []),
	{reply, Reply, State};

%% 获取正在举办的巡游信息
handle_call({get_all_cruise}, _From, State) ->
    Reply = list_deal8(get(), []),
	{reply, Reply, State};

%% 获取未举办的婚宴信息
handle_call({get_all_after_wedding}, _From, State) ->
    Reply = list_deal5(get(), []),
	{reply, Reply, State};

%% 是否在婚宴
handle_call({is_in_wedding, WeddingId, PlayerId}, _From, State) ->
    Reply = case get({is_in_wedding, PlayerId}) of
        WeddingId ->
            true;
        _ ->
            false
    end,
	{reply, Reply, State};

%% 婚宴所有在线ID
handle_call({all_in_wedding, WeddingId}, _From, State) ->
    Reply = list_deal4(get(), [], WeddingId),
	{reply, Reply, State};

%% 获得结婚任务信息
handle_call({get_marriage_task, WeddingId}, _From, State) ->
    Reply = case get({marriage_task, WeddingId}) of
        undefined -> no;
        _Any -> _Any
    end,
	{reply, Reply, State};

%% 获得结婚任务信息
handle_call({get_marriage_task_player, PlayerId}, _From, State) ->
    Reply = case get({marriage_task_player, PlayerId}) of
        undefined -> no;
        _Any -> _Any
    end,
	{reply, Reply, State};

%% 申请结婚
handle_call({apply_marry, Info}, _From, State) ->
    [MaleId, FemaleId] = Info,
    case db:get_row(io_lib:format(<<"select id from marriage where male_id = ~p and divorce_time = 0 limit 1">>, [MaleId])) of
        [] ->
            case db:get_row(io_lib:format(<<"select id from marriage where female_id = ~p and divorce_time = 0 limit 1">>, [FemaleId])) of
                [] ->
                    Err = 0,
                    db:execute(io_lib:format(<<"insert into marriage set male_id = ~p, female_id = ~p">>, [MaleId, FemaleId]));
                _ ->
                    Err = 2
            end;
        _ ->
            Err = 1
    end,
    case Err of
        0 ->
            Id = case db:get_row(io_lib:format(<<"select id from marriage where male_id = ~p and divorce_time = 0 limit 1">>, [MaleId])) of
                [] -> 0;
                [_Id] -> _Id
            end,
            [NickName1, Sex1, _Lv1, Career1, _Realm1, _GuildId1, _Mount_limit1, _HusongNpc1, Image1|_] = lib_player:get_player_low_data(MaleId),
            [NickName2, Sex2, _Lv2, Career2, _Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2|_] = lib_player:get_player_low_data(FemaleId),
            Marriage = #marriage{
                id = Id,
                male_id = MaleId,
                female_id = FemaleId,
                male_name = NickName1,
                female_name = NickName2,
                male_career = Career1,
                female_career = Career2,
                male_sex = Sex1,
                female_sex = Sex2,
                male_image = Image1,
                female_image = Image2
            },
            put({marriage_info, Id}, Marriage),
            put({marriage, MaleId}, Marriage),
            put({marriage, FemaleId}, Marriage),
            Task = #marriage_task{
                id = Id,
                male_id = MaleId,
                female_id = FemaleId
            },
            put({marriage_task, Id}, Task),
            put({marriage_task_player, MaleId}, Task),
            put({marriage_task_player, FemaleId}, Task),
            Reply = Task;
        1 ->
            Reply = nomale;
        2 ->
            Reply = nofemale;
        _ ->
            Reply = no
    end,
	{reply, Reply, State};

%% 获得npc信息
handle_call({get_npc, PlayerId}, _From, State) ->
    Reply = case get({npc, PlayerId}) of
        undefined -> [];
        _Any -> _Any
    end,
	{reply, Reply, State};

%% 姻缘日志
handle_call({get_all_log}, _From, State) ->
    Reply = case get({all_log}) of
        undefined -> [];
        _Any -> _Any
    end,
	{reply, Reply, State};

%% 今天第几对
handle_call({get_today_num, RegisterTime, WeddingTime}, _From, State) ->
    List = case get({all_log}) of
        undefined -> [];
        _AnyList -> _AnyList
    end,
    Reply = list_deal6(List, RegisterTime, WeddingTime, 1, 1),
	{reply, Reply, State};

%% 今天第几对
handle_call({get_today_num2, RegisterTime, CruiseTime}, _From, State) ->
    List = case get({all_log}) of
        undefined -> [];
        _AnyList -> _AnyList
    end,
    Reply = list_deal62(List, RegisterTime, CruiseTime, 1, 1),
	{reply, Reply, State};

%% 求婚
handle_call({get_propose, Info}, _From, State) ->
    [Id1, Id2] = Info,
    Reply = case get({propose, Id1, Id2}) of
        undefined -> false;
        _ -> true
    end,
	{reply, Reply, State};

%% 获得婚车ID
handle_call({get_mon_id}, _From, State) ->
    Reply = case get(mon_id) of
        undefined -> 0;
        _Any -> _Any
    end,
	{reply, Reply, State};

%% 传送排队
handle_call({get_send_line}, _From, State) ->
    MonId = case get(mon_id) of
        undefined -> 0;
        _Any -> _Any
    end,
    Mon = mod_scene_agent:apply_call(102, lib_mon, lookup, [102, MonId]),
    [X, Y] = case is_record(Mon, ets_mon) of
        false ->
            [163, 222];
        true ->
            [Mon#ets_mon.x, Mon#ets_mon.y]
    end,
    List = list_deal9(get(), []),
    %% 每次传送20人
    ReplyList = lists:sublist(List, 20),
    Reply = {X, Y,ReplyList},
	{reply, Reply, State};

%% 协商离婚
handle_call({get_divorce_response, PlayerId}, _From, State) ->
    Reply = get({divorce_response, PlayerId}),
	{reply, Reply, State};

%% 已被预约的喜宴或巡游时段
handle_call({get_ordered_list, Type}, _From, State) ->
    Reply = case Type of
        1 ->
            [get_wedding_list_n(9), get_wedding_list_n(10), get_wedding_list_n(11), get_wedding_list_n(12), get_wedding_list_n(13), get_wedding_list_n(14), get_wedding_list_n(15), get_wedding_list_n(16), get_wedding_list_n(17), get_wedding_list_n(18), get_wedding_list_n(19), get_wedding_list_n(20), get_wedding_list_n(21)];
        _ ->
            [get_cruise_list_n(9), get_cruise_list_n(10), get_cruise_list_n(11), get_cruise_list_n(12), get_cruise_list_n(13), get_cruise_list_n(14), get_cruise_list_n(15), get_cruise_list_n(16), get_cruise_list_n(17), get_cruise_list_n(18), get_cruise_list_n(19), get_cruise_list_n(20), get_cruise_list_n(21)]
    end,
	{reply, Reply, State};

%% 默认返回
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% cast
%% 结婚，数据插入内存
handle_cast({marry, MaleId, FemaleId}, State) ->
    OldMarriage = case get({marriage, MaleId}) of
        _Marriage when is_record(_Marriage, marriage) ->
            _Marriage;
        _ ->
            #marriage{}
    end,
    RegisterTime = util:unixtime(),
    Marriage = OldMarriage#marriage{
        register_time = RegisterTime
    },
    Id = Marriage#marriage.id,
    put({marriage_info, Id}, Marriage),
    put({marriage, MaleId}, Marriage),
    put({marriage, FemaleId}, Marriage),
    [Realm1, NickName1, Sex1, Career1, Image1] = case lib_player:get_player_info(MaleId, marriage_sendtv) of
        false -> [0, " ", 0, 0, 0];
        _Any1 -> _Any1
    end,
    [Realm2, NickName2, Sex2, Career2, Image2] = case lib_player:get_player_info(FemaleId, marriage_sendtv) of
        false -> [0, " ", 0, 0, 0];
        _Any2 -> _Any2
    end,
    AllLog = case get({all_log}) of
        undefined -> [];
        _Any -> _Any
    end,
    Num = sort_marry(AllLog, 1, RegisterTime),
    lib_chat:send_TV({all}, 1, 2, [marry, 4, MaleId, Realm1, NickName1, Sex1, Career1, Image1, FemaleId, Realm2, NickName2, Sex2, Career2, Image2, Num]),
    put({marry_log, RegisterTime}, Marriage),
    sort_log(),
    {noreply, State};

%% 预约婚宴，数据插入内存
handle_cast({wedding, MaleId, FemaleId, Level, WeddingTime}, State) ->
    %% 婚宴信息
    WeddingCard = case Level of
        1 -> 10;
        2 -> 20;
        _ -> 30
    end,
    WeddingCandies = case Level of
        1 -> 5;
        2 -> 10;
        _ -> 15
    end,
    %% 判断内存是否有结婚数据
    case get({marriage, MaleId}) of
        undefined -> 
            skip;
        Marriage when is_record(Marriage, marriage) ->
            Marriage1 = Marriage#marriage{
                wedding_time = WeddingTime,
                wedding_order_time = util:unixtime(),
                wedding_type = Level,
                wedding_card = WeddingCard,
                wedding_candies = WeddingCandies
            },
            Marriage2 = Marriage1#marriage{
                wedding_card = WeddingCard div 2,
                wedding_candies = WeddingCandies
            },
            Id = Marriage#marriage.id,
            db:execute(io_lib:format(<<"delete from marriage_guest where marriage_id = ~p">>, [Id])),
            del_marriage_guest(get(), Id),
            put({marriage_info, Id}, Marriage1),
            put({marriage, MaleId}, Marriage2),
            put({marriage, FemaleId}, Marriage2),
            put({wedding_log, WeddingTime}, Marriage1),
            %% 已被预约的喜宴或巡游时段
            Hour = (WeddingTime - util:unixdate()) div 3600,
            put({wedding_list, Hour}, {Hour, 4}),
            sort_log();
        _Any -> 
            skip
    end,
    {noreply, State};

%% 预约巡游，数据插入内存
handle_cast({cruise, Info}, State) ->
    [MaleId, FemaleId, Level, CruiseTime] = Info,
    %% 婚宴信息
    CruiseCard = case Level of
        1 -> 1;
        2 -> 3;
        _ -> 5
    end,
    CruiseCandies = case Level of
        1 -> 5;
        2 -> 8;
        _ -> 10
    end,
    %% 判断内存是否有结婚数据
    case get({marriage, MaleId}) of
        undefined -> 
            skip;
        Marriage when is_record(Marriage, marriage) ->
            Marriage1 = Marriage#marriage{
                cruise_time = CruiseTime,
                cruise_order_time = util:unixtime(),
                cruise_type = Level,
                cruise_state = 1
            },
            Marriage2 = Marriage1#marriage{
                cruise_card = CruiseCard,
                cruise_candies = CruiseCandies,
                cruise_state = 1
            },
            Id = Marriage#marriage.id,
            put({marriage_info, Id}, Marriage1),
            put({marriage, MaleId}, Marriage2),
            put({marriage, FemaleId}, Marriage2),
            put({cruise_log, CruiseTime}, Marriage1),
            %% 已被预约的喜宴或巡游时段
            Hour = (CruiseTime - util:unixdate()) div 3600,
            put({cruise_list, Hour}, {Hour, 4}),
            sort_log();
        _Any -> 
            skip
    end,
    sort_log(),
    {noreply, State};

%% 婚宴宾客
handle_cast({insert_guest, MarriageId, GuestId, InviteId}, State) ->
    put({marriage_guest, MarriageId, GuestId, InviteId}, no),
    {noreply, State};

%% 迎接完新娘
handle_cast({meeting, Marriage}, State) ->
    Id = Marriage#marriage.id,
    put({marriage_info, Id}, Marriage#marriage{state = 2}),
    {noreply, State};

%% 更新结婚信息(婚礼)
handle_cast({update_marriage_info, Marriage}, State) ->
    Id = Marriage#marriage.id,
    put({marriage_info, Id}, Marriage),
    {noreply, State};

%% 更新结婚信息(玩家)
handle_cast({update_marriage_player, Marriage, Sex}, State) ->
    MaleId = Marriage#marriage.male_id,
    FemaleId = Marriage#marriage.female_id,
    case Sex of
        1 ->
            put({marriage, MaleId}, Marriage);
        _ ->
            put({marriage, FemaleId}, Marriage)
    end,
    {noreply, State};

%% 删除信息
handle_cast({delete_info, Marriage}, State) ->
    erase({marriage_info, Marriage#marriage.id}),
    erase({marriage, Marriage#marriage.male_id}),
    erase({marriage, Marriage#marriage.female_id}),
    erase({marriage_task, Marriage#marriage.id}),
    erase({marriage_task_player, Marriage#marriage.male_id}),
    erase({marriage_task_player, Marriage#marriage.female_id}),
    delete_log(get(), Marriage#marriage.id),
    sort_log(),
    {noreply, State};

%% 进入婚宴
handle_cast({enter_wedding, WeddingId, PlayerId}, State) ->
    put({is_in_wedding, PlayerId}, WeddingId),
    {noreply, State};

%% 退出婚宴
handle_cast({quit_wedding, PlayerId}, State) ->
    erase({is_in_wedding, PlayerId}),
    {noreply, State};

%% 清除数据
handle_cast({clear_info}, State) ->
    erase(),
    {noreply, State};

%% 更新结婚任务信息
handle_cast({set_marriage_task, MarriageTask}, State) ->
    put({marriage_task, MarriageTask#marriage_task.id}, MarriageTask),
    put({marriage_task_player, MarriageTask#marriage_task.male_id}, MarriageTask),
    put({marriage_task_player, MarriageTask#marriage_task.female_id}, MarriageTask),
    {noreply, State};

%% 更新npc信息
handle_cast({set_npc, Info}, State) ->
    Task = Info,
    Id1 = 30090,
    Id2 = 30091,
    Id3 = 30092,
    Id4 = 30093,
    Len = 4,
    Rand = util:rand(1, Len),
    XY1 = [{119, 257}, {10, 146}, {23, 170}, {78, 238}],
    %XY1 = [{115, 136}, {115, 136}, {115, 136}, {115, 136}],
    {X1, Y1} = lists:nth(Rand, XY1),
    XY2 = [{129, 34}, {33, 257}, {148, 262}, {216, 202}],
    %XY2 = [{116, 137}, {116, 137}, {116, 137}, {116, 137}],
    {X2, Y2} = lists:nth(Rand, XY2),
    XY3 = [{210, 48}, {26, 14}, {69, 84}, {159, 19}],
    %XY3 = [{117, 139}, {118, 139}, {118, 139}, {119, 139}],
    {X3, Y3} = lists:nth(Rand, XY3),
    XY4 = [{50, 116}, {222, 163}, {222, 81}, {131, 197}],
    %XY4 = [{114, 135}, {114, 135}, {114, 135}, {114, 135}],
    {X4, Y4} = lists:nth(Rand, XY4),
    put({npc, Task#marriage_task.male_id}, [{Id1, X1, Y1}, {Id2, X2, Y2}, {Id3, X3, Y3}, {Id4, X4, Y4}]),
    put({npc, Task#marriage_task.female_id}, [{Id1, X1, Y1}, {Id2, X2, Y2}, {Id3, X3, Y3}, {Id4, X4, Y4}]),
    {noreply, State};

%% 增加气氛
handle_cast({add_mood, Info}, State) ->
    [Value, Name, SceneId, CopyId] = Info,
    TotalValue = case get(wedding_mood) of
        undefined -> Value;
        _AnyValue -> _AnyValue + Value
    end,
    %io:format("TotalValue:~p~n", [TotalValue]),
    put(wedding_mood, TotalValue),
    {ok, BinData} = pt_271:write(27150, [TotalValue, Name]),
    lib_unite_send:send_to_scene(SceneId, CopyId, BinData),
    {noreply, State};

%% 增加气氛
handle_cast({add_mood2, Info}, State) ->
    [Value, Name, SceneId, CopyId, Type] = Info,
    TotalValue = case get(cruise_mood) of
        undefined -> Value;
        _AnyValue -> _AnyValue + Value
    end,
    %io:format("TotalValue:~p~n", [TotalValue]),
    put(cruise_mood, TotalValue),
    {ok, BinData} = pt_271:write(27121, [TotalValue, Name, Type]),
    lib_unite_send:send_to_scene(SceneId, CopyId, BinData),
    {noreply, State};

%% 清除气氛
handle_cast({clear_mood}, State) ->
    erase(wedding_mood),
    {noreply, State};

%% 清除气氛
handle_cast({clear_mood2}, State) ->
    erase(cruise_mood),
    {noreply, State};

%% 检测气氛值，发送称号
handle_cast({check_mood, Info}, State) ->
    [Id1, Id2] = Info,
    TotalValue = case get(wedding_mood) of
        undefined -> 0;
        _AnyValue -> _AnyValue
    end,
    Marriage = get({marriage, Id1}),
    %io:format("TotalValue:~p~n", [TotalValue]),
    WeddingType = Marriage#marriage.wedding_type,
    Value = case WeddingType of
        1 -> 200;
        2 -> 500;
        3 -> 1000
    end,
    case TotalValue >= Value of
        true ->
%%            DesignId = 201409,
%%            lib_designation:bind_design_in_server(Id1, DesignId, "", 1),
%%            lib_designation:bind_design_in_server(Id2, DesignId, "", 1);
              %% 改送时装变幻卷
              Title = data_marriage_text:get_marriage_text(26),
              Content = data_marriage_text:get_marriage_text(27),
              GoodsId = case WeddingType of
                  1 -> 611711;
                  2 -> 611712;
                  _ -> 611713
              end,
              lib_mail:send_sys_mail_bg([Id1, Id2], Title, Content, GoodsId, 2, 0, 0, 1, 0, 0, 0, 0);
        false ->
            GoodsId = 0
    end,
    %% 后台日志（喜宴日志）
    CostType = case WeddingType of
        1 -> 1;
        _ -> 2
    end,
    _CostMoney = case WeddingType of
        1 -> 299999;
        2 -> 1314;
        _ -> 3344
    end,
    DisCut = case lib_marriage:is_in_activity3() of
        true -> 0.8;
        false -> 1
    end,
    CostMoney = round(_CostMoney * DisCut),
    _WeddingMarriage = get({marriage_info, Marriage#marriage.id}),
    WeddingMarriage = case is_record(_WeddingMarriage, marriage) of
        true -> _WeddingMarriage;
        false -> #marriage{}
    end,
    spawn(fun() ->
                db:execute(io_lib:format(<<"insert into log_marriage2 set type = 1, order_time = ~p, hold_time = ~p, cost_type = ~p, cost_money = ~p, active_id = ~p, passive_id = ~p, activity_type = ~p, atm_value = ~p, gift_coin = ~p, gift_flower = ~p, atm_gift = ~p">>, [Marriage#marriage.wedding_order_time, Marriage#marriage.wedding_time, CostType, CostMoney, Id1, Id2, WeddingType, TotalValue, WeddingMarriage#marriage.male_coin + WeddingMarriage#marriage.female_coin, WeddingMarriage#marriage.male_gold + WeddingMarriage#marriage.female_gold, GoodsId]))
        end),
    erase(wedding_mood),
    {noreply, State};

%% 检测气氛值，发送称号
handle_cast({check_mood2, Info}, State) ->
    [Id1, Id2] = Info,
    TotalValue = case get(cruise_mood) of
        undefined -> 0;
        _AnyValue -> _AnyValue
    end,
    Marriage = get({marriage, Id1}),
    CruiseType = Marriage#marriage.cruise_type,
    %io:format("TotalValue:~p~n", [TotalValue]),
    Value = case CruiseType of
        1 -> 200;
        2 -> 500;
        3 -> 1000
    end,
    case TotalValue >= Value of
        true ->
%%            DesignId = 201409,
%%            lib_designation:bind_design_in_server(Id1, DesignId, "", 1),
%%            lib_designation:bind_design_in_server(Id2, DesignId, "", 1);
              %% 改送时装变幻卷
              case CruiseType of
                  1 -> 
                      Text1 = data_marriage_text:get_marriage_text(34),
                      Text2 = data_marriage_text:get_marriage_text(41),
                      Text3 = "200";
                  2 ->
                      Text1 = data_marriage_text:get_marriage_text(35),
                      Text2 = data_marriage_text:get_marriage_text(42),
                      Text3 = "500";
                  _ ->
                      Text1 = data_marriage_text:get_marriage_text(36),
                      Text2 = data_marriage_text:get_marriage_text(43),
                      Text3 = "1000"
              end,
              Title = data_marriage_text:get_marriage_text(37),
              Content = io_lib:format(data_marriage_text:get_marriage_text(38), [Text1, Text3, Text2]),
              GoodsId = case CruiseType of
                  1 -> 611907;
                  2 -> 611911;
                  _ -> 611912
              end,
              lib_mail:send_sys_mail_bg([Id1, Id2], Title, Content, GoodsId, 2, 0, 0, 1, 0, 0, 0, 0),
              lib_marriage_activity:activity_award2([Id1, Id2, CruiseType]);
        false ->
            GoodsId = 0
    end,
    %% 后台日志（喜宴日志）
    CostType = case CruiseType of
        1 -> 1;
        _ -> 2
    end,
    _CostMoney = case CruiseType of
        1 -> 299999;
        2 -> 1314;
        _ -> 3344
    end,
    DisCut = case lib_marriage:is_in_activity3() of
        true -> 0.8;
        false -> 1
    end,
    CostMoney = round(_CostMoney * DisCut),
    spawn(fun() ->
                db:execute(io_lib:format(<<"insert into log_marriage2 set type = 2, order_time = ~p, hold_time = ~p, cost_type = ~p, cost_money = ~p, active_id = ~p, passive_id = ~p, activity_type = ~p, atm_value = ~p, atm_gift = ~p">>, [Marriage#marriage.cruise_order_time, Marriage#marriage.cruise_time, CostType, CostMoney, Id1, Id2, CruiseType, TotalValue, GoodsId]))
        end),
    erase(cruise_mood),
    {noreply, State};

%% 求婚
handle_cast({set_propose, Info}, State) ->
    [Id1, Id2] = Info,
    put({propose, Id1, Id2}, yes),
    {noreply, State};

%% 设置婚车ID
handle_cast({set_mon_id, Id}, State) ->
    put(mon_id, Id),
    {noreply, State};

%% 传送排队
handle_cast({add_send_line, Info}, State) ->
    [Status] = Info,
    put({send_line, Status#player_status.id}, ok),
    {noreply, State};

%% 协商离婚
handle_cast({set_divorce_response, PlayerId, Ans}, State) ->
    put({divorce_response, PlayerId}, Ans),
    {noreply, State};

%% 协商离婚
handle_cast({clear_divorce_response, PlayerId}, State) ->
    erase({divorce_response, PlayerId}),
    {noreply, State};

%% 清除结婚信息
handle_cast({clear_marriage, Info}, State) ->
    [Id, MaleId, FemaleId] = Info,
    _Marriage = get({marriage_info, Id}),
    Marriage = case is_record(_Marriage, marriage) of
        true -> _Marriage;
        false -> #marriage{}
    end,
    erase({marriage_info, Id}),
    erase({marriage, MaleId}),
    erase({marriage, FemaleId}),
    put({divorce_log, util:unixtime()}, Marriage),
    sort_log(),
    {noreply, State};

%% 处理离婚事务
handle_cast({deal_divorce}, State) ->
    deal_all_divorce(get()),
    {noreply, State};

%% 喜宴或巡游时段初始化（每日0点清空）
handle_cast({clear_wedding_cruise_list}, State) ->
    init_wedding_cruise_list(),
    {noreply, State};

%% 喜宴或巡游时段超时（每小时整理）
handle_cast({set_overtime}, State) ->
    set_overtime0(),
    {noreply, State};

%% 默认返回
handle_cast(_Msg, State) ->
    {noreply, State}.

%% info
%% 默认返回
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% 初始化结婚信息
init_marriage([]) -> 
    skip;
init_marriage([H | T]) ->
    case H of
        %% Divorce: 0.未离婚 1.已离婚 2.已申请强制离婚
        [Id, MaleId, FemaleId, RegisterTime, WeddingTime, WeddingType, WeddingCard, CruiseTime, CruiseType, Divorce, DivorceTime, ApplyDivorceTime, MarkSureTime] ->
            [NickName1, Sex1, _Lv1, Career1, _Realm1, _GuildId1, _Mount_limit1, _HusongNpc1, Image1|_] = case lib_player:get_player_low_data(MaleId) of
                [] -> [<<>>, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
                _AnyData1 -> _AnyData1
            end,
            [NickName2, Sex2, _Lv2, Career2, _Realm2, _GuildId2, _Mount_limit2, _HusongNpc2, Image2|_] = case lib_player:get_player_low_data(FemaleId) of
                [] -> [<<>>, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
                _AnyData2 -> _AnyData2
            end,
            WeddingCandies = case WeddingType of
                1 -> 5;
                2 -> 10;
                _ -> 15
            end,
            ApplySex = case Divorce of
                11 -> 1;
                12 -> 2;
                _ -> 0
            end,
            Marriage1 = #marriage{
                id = Id,
                male_id = MaleId,
                female_id = FemaleId,
                register_time = RegisterTime,
                wedding_time = WeddingTime,
                wedding_type = WeddingType,
                wedding_card = WeddingCard,
                male_name = NickName1,
                female_name = NickName2,
                male_career = Career1,
                female_career = Career2,
                male_sex = Sex1,
                female_sex = Sex2,
                male_image = Image1,
                female_image = Image2,
                cruise_time = CruiseTime,
                cruise_type = CruiseType,
                apply_divorce_time = ApplyDivorceTime,
                apply_sex = ApplySex,
                mark_sure_time = MarkSureTime
            },
            %% 姻缘日志
            case RegisterTime of
                0 ->
                    skip;
                _ ->
                    put({marry_log, RegisterTime}, Marriage1)
            end,
            case WeddingTime of
                0 ->
                    skip;
                _ ->
                    put({wedding_log, WeddingTime}, Marriage1)
            end,
            case CruiseTime of
                0 ->
                    skip;
                _ ->
                    put({cruise_log, CruiseTime}, Marriage1)
            end,
            case Divorce of
                1 -> 
                    put({divorce_log, DivorceTime}, Marriage1);
                _ ->
                    skip
            end,
            Marriage2 = Marriage1#marriage{
                wedding_card = WeddingCard div 2,
                wedding_candies = WeddingCandies
            },
            case Divorce of
                %% 已离婚的数据直接跳过
                1 ->
                    skip;
                _ ->
                    %% 已被预约的喜宴或巡游时段
                    case WeddingTime >= util:unixdate() of
                        true ->
                            Hour1 = (WeddingTime - util:unixdate()) div 3600,
                            put({wedding_list, Hour1}, {Hour1, 4});
                        false ->
                            skip
                    end,
                    case CruiseTime >= util:unixdate() of
                        true ->
                            Hour2 = (CruiseTime - util:unixdate()) div 3600,
                            put({cruise_list, Hour2}, {Hour2, 4});
                        false ->
                            skip
                    end,
                    %% 结婚信息
                    put({marriage_info, Id}, Marriage1),
                    put({marriage, MaleId}, Marriage2),
                    put({marriage, FemaleId}, Marriage2),
                    init_marriage_task(Id, MaleId, FemaleId),
                    case db:get_all(io_lib:format(<<"select guest_id, invite_id from marriage_guest where marriage_id = ~p">>, [Id])) of
                        [] -> 
                            skip;
                        List ->
                            init_marriage_guest(List, Id)
                    end
            end;
        _ -> 
            skip
    end,
    init_marriage(T).

%% 初始化结婚任务信息
init_marriage_task(Id, MaleId, FemaleId) ->
    case db:get_row(io_lib:format(<<"select app_begin, task_flag, task_type, finish_task from marriage_task where id = ~p limit 1">>, [Id])) of
        [] -> 
            skip;
        [AppBegin, TaskFlag, TaskType, FinishTask] ->
            NewTaskType = case TaskType of
                2 -> 0;
                _AnyType -> _AnyType
            end,
            NewTaskFlag = case TaskFlag of
                5 -> 5;
                _ -> 1
            end,
            Task = #marriage_task{
                id = Id,
                male_id = MaleId,
                female_id = FemaleId,
                app_begin = AppBegin,
                task_flag = NewTaskFlag,
                task_type = NewTaskType,
                finish_task = FinishTask
            },
            put({marriage_task, Id}, Task),
            put({marriage_task_player, MaleId}, Task),
            put({marriage_task_player, FemaleId}, Task)
    end.

%% 初始化宾客信息
init_marriage_guest([], _MarriageId) -> skip;
init_marriage_guest([H | T], MarriageId) ->
    case H of
        [GuestId, InviteId] ->
            put({marriage_guest, MarriageId, GuestId, InviteId}, no);
        _ ->
            skip
    end,
    init_marriage_guest(T, MarriageId).

%% 初始化结婚道具的信息
init_marriage_item([]) -> 
    skip;
init_marriage_item([H | T]) ->
    case H of
        [Id, MaleId, FemaleId, _RegisterTime, WeddingTime, WeddingType, WeddingCard, CruiseTime, CruiseType] ->
            case get({marriage_info, Id}) of
                Marriage1 when is_record(Marriage1, marriage) -> 
                    NoData = false;
                _ ->
                    NoData = true,
                    Marriage1 = #marriage{}
            end,
            %% 已离婚，则不存在数据
            case NoData of
                true ->
                    skip;
                false ->
                    WeddingCandies = case WeddingType of
                        1 -> 5;
                        2 -> 10;
                        _ -> 15
                    end,
                    %% 姻缘日志
                    case WeddingTime of
                        0 ->
                            skip;
                        _ ->
                            put({wedding_log, WeddingTime}, Marriage1)
                    end,
                    case CruiseTime of
                        0 ->
                            skip;
                        _ ->
                            put({cruise_log, CruiseTime}, Marriage1)
                    end,
                    Marriage2 = Marriage1#marriage{
                        wedding_card = WeddingCard div 2,
                        wedding_candies = WeddingCandies
                    },
                    case Marriage1#marriage.wedding_time < WeddingTime of
                        true ->
                            Marriage11 = Marriage1#marriage{
                                wedding_time = WeddingTime,
                                wedding_type = WeddingType
                            },
                            Marriage22 = Marriage2#marriage{
                                wedding_time = WeddingTime,
                                wedding_type = WeddingType
                            };
                        false ->
                            Marriage11 = Marriage1,
                            Marriage22 = Marriage2
                    end,
                    case Marriage11#marriage.cruise_time < CruiseTime of
                        true ->
                            Marriage111 = Marriage11#marriage{
                                cruise_time = CruiseTime,
                                cruise_type = CruiseType
                            },
                            Marriage222 = Marriage22#marriage{
                                cruise_time = CruiseTime,
                                cruise_type = CruiseType
                            };
                        false ->
                            Marriage111 = Marriage11,
                            Marriage222 = Marriage22
                    end,
                    %% 已被预约的喜宴或巡游时段
                    case WeddingTime >= util:unixdate() of
                        true ->
                            Hour1 = (WeddingTime - util:unixdate()) div 3600,
                            put({wedding_list, Hour1}, {Hour1, 4});
                        false ->
                            skip
                    end,
                    case CruiseTime >= util:unixdate() of
                        true ->
                            Hour2 = (CruiseTime - util:unixdate()) div 3600,
                            put({cruise_list, Hour2}, {Hour2, 4});
                        false ->
                            skip
                    end,
                    %% 结婚信息
                    put({marriage_info, Id}, Marriage111),
                    put({marriage, MaleId}, Marriage222),
                    put({marriage, FemaleId}, Marriage222)
            end;
        _ -> 
            skip
    end,
    init_marriage_item(T).

list_deal1([], L) -> L;
list_deal1([H | T], L) ->
    case H of
        {{marriage_info, _Id}, Marriage} when is_record(Marriage, marriage) ->
            MaleId = Marriage#marriage.male_id,
            _WeddingTime = Marriage#marriage.wedding_time,
            case MaleId =/= 0 andalso util:unixtime() >= _WeddingTime - 10 * 60 andalso util:unixtime() =< _WeddingTime + 35 * 60 of
                true ->
                    list_deal1(T, [Marriage | L]);
                false ->
                    list_deal1(T, L)
            end;
        _ ->
            list_deal1(T, L)
    end.

list_deal2([], L, _WeddingId, _PlayerId) -> L;
list_deal2([H | T], L, WeddingId, PlayerId) ->
    case H of
        {{marriage_guest, WeddingId, GuestId, PlayerId}, no} ->
            list_deal2(T, [GuestId | L], WeddingId, PlayerId);
        _ ->
            list_deal2(T, L, WeddingId, PlayerId)
    end.

list_deal3([], L, _WeddingId, _InviteId) -> L;
list_deal3([H | T], L, WeddingId, InviteId) ->
    case H of
        {{marriage_guest, WeddingId, GuestId, InviteId}, no} ->
            list_deal3(T, [{WeddingId, GuestId, InviteId} | L], WeddingId, InviteId);
        _ ->
            list_deal3(T, L, WeddingId, InviteId)
    end.

list_deal4([], L, _WeddingId) -> L;
list_deal4([H | T], L, WeddingId) ->
    case H of
        {{is_in_wedding, Id}, WeddingId} ->
            list_deal4(T, [Id | L], WeddingId);
        _ ->
            list_deal4(T, L, WeddingId)
    end.

list_deal5([], L) -> L;
list_deal5([H | T], L) ->
    case H of
        {{marriage_info, _Id}, Marriage} when is_record(Marriage, marriage) ->
            MaleId = Marriage#marriage.male_id,
            _WeddingTime = Marriage#marriage.wedding_time,
            case MaleId =/= 0 andalso util:unixtime() =< _WeddingTime of
                true ->
                    list_deal5(T, [Marriage | L]);
                false ->
                    list_deal5(T, L)
            end;
        _ ->
            list_deal5(T, L)
    end.

list_deal6([], _MyRegisterTime, _MyWeddingTime, Num, TotalNum) -> [TotalNum, Num];
list_deal6([H | T], MyRegisterTime, MyWeddingTime, Num, TotalNum) ->
    case H of
        {wedding_log, WeddingTime, _Marriage} ->
            MaleId = _Marriage#marriage.male_id,
            case MaleId =/= 0 andalso WeddingTime >= util:unixdate() andalso WeddingTime < MyWeddingTime of
                true ->
                    NewNum = Num + 1;
                false ->
                    NewNum = Num
            end,
            case MaleId =/= 0 andalso WeddingTime > 0 andalso WeddingTime < MyWeddingTime of
                true ->
                    NewTotalNum = TotalNum + 1;
                false -> 
                    NewTotalNum = TotalNum
            end;
        _ ->
            NewTotalNum = TotalNum,
            NewNum = Num
    end,
    list_deal6(T, MyRegisterTime, MyWeddingTime, NewNum, NewTotalNum).

list_deal62([], _MyRegisterTime, _MyCruiseTime, Num, TotalNum) -> [TotalNum, Num];
list_deal62([H | T], MyRegisterTime, MyCruiseTime, Num, TotalNum) ->
    case H of
        {cruise_log, CruiseTime, _Marriage} ->
            MaleId = _Marriage#marriage.male_id,
            case MaleId =/= 0 andalso CruiseTime >= util:unixdate() andalso CruiseTime < MyCruiseTime of
                true ->
                    NewNum = Num + 1;
                false ->
                    NewNum = Num
            end,
            case MaleId =/= 0 andalso CruiseTime > 0 andalso CruiseTime < MyCruiseTime of
                true ->
                    NewTotalNum = TotalNum + 1;
                false -> 
                    NewTotalNum = TotalNum
            end;
        _ ->
            NewTotalNum = TotalNum,
            NewNum = Num
    end,
    list_deal62(T, MyRegisterTime, MyCruiseTime, NewNum, NewTotalNum).

list_deal7([], _WeddingId, _PlayerId) -> false;
list_deal7([H | T], WeddingId, PlayerId) ->
    case H of
        {{marriage_guest, WeddingId, PlayerId, _InviteId}, no} ->
            true;
        _ ->
            list_deal7(T, WeddingId, PlayerId)
    end.

list_deal8([], L) -> L;
list_deal8([H | T], L) ->
    case H of
        {{marriage_info, _Id}, Marriage} when is_record(Marriage, marriage) ->
            MaleId = Marriage#marriage.male_id,
            _CruiseTime = Marriage#marriage.cruise_time,
            case MaleId =/= 0 andalso util:unixtime() >= _CruiseTime - 5 * 60 andalso util:unixtime() =< _CruiseTime + 35 * 60 andalso Marriage#marriage.cruise_state =/= 3 of
                true ->
                    list_deal8(T, [Marriage | L]);
                false ->
                    list_deal8(T, L)
            end;
        _ ->
            list_deal8(T, L)
    end.

list_deal9([], L) -> L;
list_deal9([H | T], L) ->
    case H of
        {{send_line, Id}, _} ->
            erase({send_line, Id}),
            list_deal9(T, [Id | L]);
        _ ->
            list_deal9(T, L)
    end.

%% 姻缘日志处理
sort_log() ->
    sort_log2(get(), []).

sort_log2([], L) ->
    sort_log3(L);
sort_log2([H | T], L) ->
    case H of
        {{marry_log, RegisterTime}, Marriage} ->
            MaleId = Marriage#marriage.male_id,
            case MaleId =/= 0 andalso RegisterTime =/=0 of
                false ->
                    L2 = L;
                true ->
                    L2 = [{marry_log, RegisterTime, Marriage} | L]
            end;
        {{wedding_log, WeddingTime}, Marriage} ->
            MaleId = Marriage#marriage.male_id,
            case MaleId =/= 0 andalso WeddingTime =/=0 of
                false ->
                    L2 = L;
                true ->
                    L2 = [{wedding_log, WeddingTime, Marriage} | L]
            end;
        {{cruise_log, CruiseTime}, Marriage} ->
            MaleId = Marriage#marriage.male_id,
            case MaleId =/= 0 andalso CruiseTime =/=0 of
                false ->
                    L2 = L;
                true ->
                    L2 = [{cruise_log, CruiseTime, Marriage} | L]
            end;
        {{divorce_log, DivorceTime}, Marriage} ->
            MaleId = Marriage#marriage.male_id,
            case MaleId =/= 0 andalso DivorceTime =/=0 of
                false ->
                    L2 = L;
                true ->
                    L2 = [{divorce_log, DivorceTime, Marriage} | L]
            end;
        _ ->
            L2 = L
    end,
    sort_log2(T, L2).

sort_log3(L) ->
    L2 = lists:keysort(2, L),
    L3 = lists:reverse(L2),
    put({all_log}, L3).

sort_marry([], N, _NowTime) -> N;
sort_marry([H | T], N, NowTime) ->
    case H of
        {marry_log, RegisterTime, Marriage} ->
            case RegisterTime =/= 0 andalso Marriage#marriage.male_id =/= 0 andalso RegisterTime < NowTime of
                true ->
                    NewN = N + 1;
                false ->
                    NewN = N
            end;
        _ ->
            NewN = N
    end,
    sort_marry(T, NewN, NowTime).

delete_log([], _MarriageId) -> skip;
delete_log([H | T], MarriageId) ->
    case H of
        {{marry_log, RegisterTime}, Marriage} ->
            case Marriage#marriage.id =:= MarriageId of
                true -> 
                    erase({marry_log, RegisterTime});
                false ->
                    skip
            end;
        {{wedding_log, WeddingTime}, Marriage} ->
            case Marriage#marriage.id =:= MarriageId of
                true -> 
                    erase({wedding_log, WeddingTime});
                false ->
                    skip
            end;
        {{cruise_log, CruiseTime}, Marriage} ->
            case Marriage#marriage.id =:= MarriageId of
                true -> 
                    erase({cruise_log, CruiseTime});
                false ->
                    skip
            end;
        {{divorce_log, DivorceTime}, Marriage} ->
            case Marriage#marriage.id =:= MarriageId of
                true -> 
                    erase({divorce_log, DivorceTime});
                false ->
                    skip
            end;
        _ ->
            skip
    end,
    delete_log(T, MarriageId).

del_marriage_guest([], _MarriageId) -> skip;
del_marriage_guest([H | T], MarriageId) ->
    case H of
        {{marriage_guest, MarriageId, _GuestId, _InviteId}, _} ->
            erase({marriage_guest, MarriageId, _GuestId, _InviteId});
        _ ->
            skip
    end,
    del_marriage_guest(T, MarriageId).

%% 处理离婚事务
deal_all_divorce([]) -> skip;
deal_all_divorce([H | T]) ->
    case H of
        {{marriage_info, _WeddingId}, OldMarriage} -> 
            case util:unixtime() > OldMarriage#marriage.mark_sure_time + 3 * 24 * 60 * 60 andalso OldMarriage#marriage.mark_sure_time > 0 of
                true ->
                    Id = OldMarriage#marriage.id,
                    MaleId = OldMarriage#marriage.male_id,
                    FemaleId = OldMarriage#marriage.female_id,
                    %% 删除好友关系
                    case lib_player:get_player_info(MaleId, pid) of
                        %% 男方在线
                        Pid1 when is_pid(Pid1) ->
                            lib_relationship:delete_rela_for_divorce(Pid1, MaleId, FemaleId);
                        _ -> 
                            case lib_player:get_player_info(FemaleId, pid) of
                                %% 女方在线
                                Pid2 when is_pid(Pid2) ->
                                    lib_relationship:delete_rela_for_divorce(Pid2, FemaleId, MaleId);
                                %% 都不在线
                                _ -> 
                                    lib_relationship:delete_rela_for_divorce(0, MaleId, FemaleId)
                            end
                    end,
                    lib_player:update_player_info(MaleId, [{marriage, #status_marriage{}}]),
                    lib_player:update_player_info(FemaleId, [{marriage, #status_marriage{}}]),
                    _Marriage = get({marriage_info, Id}),
                    Marriage = case is_record(_Marriage, marriage) of
                        true -> _Marriage;
                        false -> #marriage{}
                    end,
                    erase({marriage_info, Id}),
                    erase({marriage, MaleId}),
                    erase({marriage, FemaleId}),
                    put({divorce_log, util:unixtime()}, Marriage),
                    sort_log(),
                    db:execute(io_lib:format(<<"update marriage set divorce = 1, divorce_time = ~p where id = ~p">>, [util:unixtime(), Id])),
                    db:execute(io_lib:format(<<"delete from marriage_mark where id = ~p">>, [MaleId])),
                    db:execute(io_lib:format(<<"delete from marriage_mark where id = ~p">>, [FemaleId])),
                    db:execute(io_lib:format(<<"delete from marriage_task where id = ~p">>, [Id])),
                    Title = data_marriage_text:get_marriage_text(44),
                    Content = data_marriage_text:get_marriage_text(45),
                    lib_mail:send_sys_mail_bg([MaleId, FemaleId], Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0);
                false ->
                    skip
            end;
        _ ->
            skip
    end,
    deal_all_divorce(T).

%% 喜宴或巡游时段初始化（每日0点清空）
init_wedding_cruise_list() ->
    init_wedding_cruise_list1(9), 
    init_wedding_cruise_list2(9).

init_wedding_cruise_list1(Hour) ->
    case Hour > 21 of
        true -> 
            skip;
        false ->
            {_Hour, _Min, _Sec} = time(),
            case {_Hour, _Min} > {Hour - 1, 45} of
                true ->
                    put({wedding_list, Hour}, {Hour, 3});
                false ->
                    case _Hour >= 19 of
                        true ->
                            put({wedding_list, Hour}, {Hour, 2});
                        false ->
                            put({wedding_list, Hour}, {Hour, 1})
                    end
            end,
            init_wedding_cruise_list1(Hour + 1)
    end.

init_wedding_cruise_list2(Hour) ->
    case Hour > 21 of
        true -> 
            skip;
        false ->
            {_Hour, _Min, _Sec} = time(),
            case {_Hour, _Min} > {Hour, 15} of
                true ->
                    put({cruise_list, Hour}, {Hour, 3});
                false ->
                    case _Hour >= 19 of
                        true ->
                            put({cruise_list, Hour}, {Hour, 2});
                        false ->
                            put({cruise_list, Hour}, {Hour, 1})
                    end
            end,
            init_wedding_cruise_list2(Hour + 1)
    end.

%% 喜宴或巡游时段超时（每小时整理）
set_overtime0() ->
    {_Hour, _Min, _Sec} = time(),
    set_overtime1(9),
    set_overtime2(9).

set_overtime1(Hour) ->
    {_Hour, _Min, _Sec} = time(),
    case Hour > 21 of
        true -> 
            skip;
        false ->
            case {_Hour, _Min} > {Hour - 1, 45} of
                true ->
                    case get({wedding_list, Hour}) of
                        {Hour, State} ->
                            case State of
                                4 ->
                                    skip;
                                _ ->
                                    put({wedding_list, Hour}, {Hour, 3})
                            end;
                        _ ->
                            skip
                    end;
                false ->
                    skip
            end,
            set_overtime1(Hour + 1)
    end.

set_overtime2(Hour) ->
    {_Hour, _Min, _Sec} = time(),
    case Hour > 21 of
        true -> 
            skip;
        false ->
            case {_Hour, _Min} > {Hour, 15} of
                true ->
                    case get({cruise_list, Hour}) of
                        {Hour, State} ->
                            case State of
                                4 ->
                                    skip;
                                _ ->
                                    put({cruise_list, Hour}, {Hour, 3})
                            end;
                        _ ->
                            skip
                    end;
                false ->
                    skip
            end,
            set_overtime2(Hour + 1)
    end.

get_wedding_list_n(N) ->
    case get({wedding_list, N}) of
        {N, State} ->
            {N, State};
        _ ->
            {N, 1}
    end.

get_cruise_list_n(N) ->
    case get({cruise_list, N}) of
        {N, State} ->
            {N, State};
        _ ->
            {N, 1}
    end.
