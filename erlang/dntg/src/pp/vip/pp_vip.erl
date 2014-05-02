%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-22
%% Description: vip功能
%% --------------------------------------------------------
-module(pp_vip).
-export([handle/3]).
-include("server.hrl").
-include("buff.hrl").
-include("scene.hrl").
-include("task.hrl").
-include("shop.hrl").

% vip任务传送
handle(45001, _PlayerStatus, [Type,Id, Scene, X, Y]) ->
    %%     io:format("45001 type = ~p, ID = ~p~n", [Type, Id]),
    case lib_marriage:marry_state(_PlayerStatus#player_status.marriage) of
        %% 巡游中无法传送
        8 ->
            NewPlayerStatus = _PlayerStatus,
            Error = 8,
            LeftTimes = 0;
        _ ->
            %检测vip是否到期
            PlayerStatus = lib_vip:check_vip(_PlayerStatus),
            Pk = PlayerStatus#player_status.pk,

            %获取要传送地图场景数据.
            PresentScene = 
            case Type of
                0 ->
                    case data_scene:get(Id) of
                        [] -> 
                            #ets_scene{};
                        SceneData ->
                            SceneData
                    end; 
                _ ->
                    #ets_scene{}
            end,
			case lib_scene:is_blocked(Id, X, Y) of
				true ->
					NewPlayerStatus = PlayerStatus,
                    Error = 10,
                    LeftTimes = 0;
				false ->
            case PresentScene#ets_scene.type =:= ?SCENE_TYPE_BOSS 
                andalso Pk#status_pk.pk_status =/= 2
                andalso Pk#status_pk.pk_status =/= 3 of
                %1.进入BOSS地图判断是否为国家模式.
                true ->
                    NewPlayerStatus = PlayerStatus,
                    Error = 6,
                    LeftTimes = 0;
                _ ->
                    %副本地图无法传送
                    case lib_scene:is_dungeon_scene(PlayerStatus#player_status.scene) of
                        true ->
                            NewPlayerStatus = PlayerStatus,
                            Error = 2,
                            LeftTimes = 0;
                        _ ->
                            %% 不同国家不能传送进去
                            case (_PlayerStatus#player_status.realm =:= 1 andalso lists:member(Scene, [180, 200])) orelse (_PlayerStatus#player_status.realm =:= 2 andalso lists:member(Scene, [160, 200])) orelse (_PlayerStatus#player_status.realm =:= 3 andalso lists:member(Scene, [160, 180])) of
                                true ->
                                    NewPlayerStatus = PlayerStatus,
                                    Error = 2,
                                    LeftTimes = 0;
                                false ->
                                    %% 不能传送到监狱
                                    %% 不能传送到VIP挂机场景
                                    VipScene = data_vip_new:get_config(scene_id),
                                    VipScene2 = data_vip_new:get_config(scene_id2),
                                    VipScene3 = data_vip_new:get_config(scene_id3),
                                    AbScene = [998, VipScene, VipScene2, VipScene3],
                                    AbSceneType = [?SCENE_TYPE_CLUSTERS],
                                    case lists:member(Id, AbScene) =:= true orelse lists:member(Scene, AbScene) =:= true orelse lists:member(lib_scene:get_res_type(Id), AbSceneType) =:= true orelse lists:member(lib_scene:get_res_type(Scene), AbSceneType) =:= true of
                                        true ->
                                            NewPlayerStatus = PlayerStatus,
                                            Error = 2,
                                            LeftTimes = 0;
                                        false ->
                                            %% 是否在监狱不能传送
                                            case mod_gjpt:is_in_prison(PlayerStatus) of
                                                true -> 
                                                    NewPlayerStatus = PlayerStatus,
                                                    Error = 2,
                                                    LeftTimes = 0;
                                                false ->
                                                    %% 进入统一验证判断
                                                    case lib_player:is_transferable(PlayerStatus) of
                                                        true ->
                                                            case Type of
                                                                0 ->
                                                                    {ok, NewPlayerStatus, Error, LeftTimes} = lib_vip:vip_task_transport(scene, PlayerStatus, Id);
                                                                1 ->
                                                                    {ok, NewPlayerStatus, Error, LeftTimes} = lib_vip:vip_task_transport(npc, PlayerStatus, Id);
                                                                2 ->
                                                                    {ok, NewPlayerStatus, Error, LeftTimes} = lib_vip:vip_task_transport(mon, PlayerStatus, Id);
                                                                3 ->
                                                                    %杀戮传送
                                                                    {ok, NewPlayerStatus, Error, LeftTimes} = lib_vip:killer_transport(PlayerStatus, Scene, X, Y);
                                                                _ ->
                                                                    NewPlayerStatus = PlayerStatus,
                                                                    Error = 2,
                                                                    LeftTimes = 0
                                                            end;
                                                        false ->
                                                            NewPlayerStatus = PlayerStatus,
                                                            Error = 9,
                                                            LeftTimes = 0
                                                    end
                                            end
                                    end
                            end
                    end
            end
			end
    end,
    {ok, BinData} = pt_450:write(45001, [Error, LeftTimes]),
    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
    case Error of
        0 ->
            {ok, NewPlayerStatus};
        _ ->
            ok
    end;

% vip场景传送
handle(45002, PlayerStatus, [SceneId]) ->
    {ok, NewPlayerStatus, Error} = lib_vip:vip_scene_transport(PlayerStatus, SceneId),
    {ok, BinData} = pt_450:write(45002, [Error]),
    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
    case Error of
        0 ->
            {ok, NewPlayerStatus};
        _ ->
            ok
    end;

%% 查看vip信息
handle(45003, PlayerStatus, _) ->
    Vip = PlayerStatus#player_status.vip,
    case Vip#status_vip.vip_type>0 of
        true ->
            Now = util:unixtime(),
            LeftTime = Vip#status_vip.vip_end_time - Now,
            case LeftTime > 0 of
                true ->
                    {ok, BinData} = pt_450:write(45003, [LeftTime]),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
                false ->
                    NewPlayerStatus = PlayerStatus#player_status{vip=Vip#status_vip{vip_type=0,vip_end_time=0}},
                    lib_player:send_attribute_change_notify(NewPlayerStatus, 2),
                    %VIP广播
                   {ok, Bin} = pt_120:write(12202, [NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.platform, NewPlayerStatus#player_status.server_num]),
                   lib_server_send:send_to_scene(NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.copy_id, Bin),
                   {ok,NewPlayerStatus}
            end;
        false ->
            ok
    end;

%% 检测vip是否到期
handle(45006, PlayerStatus, _) ->
    NewPlayerStatus = lib_vip:check_vip(PlayerStatus),
    {ok, NewPlayerStatus};

%福利面板
handle(45007, PlayerStatus, _) ->
	%io:format("recv:45007~n"),

    F1 = case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 1301) =:= 0 of 
             true -> 
                 0; 
             _ -> 
                 1 
         end,
    F2 = case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 1302) =:= 0 of 
             true -> 0; 
             _ -> 1 
         end,
    F3 = case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 1303) =:= 0 of 
             true -> 0; 
             _ -> 1 
         end,
    Time0 = case lib_buff:match_three(PlayerStatus#player_status.player_buff, 7, 18, []) of
	%Time0 = case lib_player:get_player_buff(PlayerStatus#player_status.id, 7, 18) of
    [BuffInfo]  ->
         case BuffInfo#ets_buff.end_time - util:unixtime() > 0 of
             true ->
                 BuffInfo#ets_buff.end_time - util:unixtime();
             _ ->
                 0
         end;
     _ ->
         0
    end,
    F4 = case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 1304) =:= 0 of 
             true -> 
				Time = Time0,
				0; 
             _ -> 
				 case mod_vip:lookup_pid(PlayerStatus#player_status.id) of
		 			undefined -> 
						%% 服务器重启
						Time = Time0,
						2;
		 			EtsVipBuff ->
						_RestTime = EtsVipBuff#ets_vip_buff.rest_time,
						_State = EtsVipBuff#ets_vip_buff.state,
						case _State of
							2 -> Time = _RestTime;
							_ -> Time = Time0
						end,
						_State
	 			end
         end,
     Vip = PlayerStatus#player_status.vip,
     Time1 = case Vip#status_vip.vip_end_time - util:unixtime() > 0 of
         true ->
             Vip#status_vip.vip_end_time - util:unixtime();
         _ ->
             0
     end,
    {ok, BinData} = pt_450:write(45007, [F1, F2, F3, F4, Time, Time1]),
	%io:format("45007:~p,F4:~p~n", [BinData, F4]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%领取福利
handle(45008, PlayerStatus, [Type]) ->
	%io:format("recv:45008~n"),
    {Error, NewPlayerStatus} = lib_vip:get_vip_reward(PlayerStatus, Type),
    {ok, BinData} = pt_450:write(45008, [Error]),
    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
    %pp_login_gift:handle(31204, PlayerStatus, no),
	%io:format("45008:~p~n", [BinData]),
    {ok, NewPlayerStatus};

%购买vip升级卡(卡为绑定)
handle(45009, PlayerStatus, _) ->
	%io:format("recv:45009~n"),
    Vip = PlayerStatus#player_status.vip,
	VipType = Vip#status_vip.vip_type,
    case VipType of
        1 ->
            GoodsTypeId = 631102; %% 月卡
        2 ->
            GoodsTypeId = 631202; %% 半年卡
        _ ->
            GoodsTypeId = 0
    end,
    case VipType > 3 of
        true ->
            {Res, NewPlayerStatus} = {6, PlayerStatus};
        false ->
            {Res, NewPlayerStatus} = mod_other_call:pay_vip_upgrade_card(PlayerStatus, GoodsTypeId)
    end,
	lib_player:refresh_client(PlayerStatus#player_status.id, 2),
    {ok, BinData} = pt_450:write(45009, [Res]),
    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
	%io:format("45009:~p~n", [BinData]),
    {ok, NewPlayerStatus};

%祝福冻结
handle(45011, PlayerStatus, _) ->
	%io:format("recv:45011~n"),
    {Error, NewPlayerStatus} = lib_vip:freeze(PlayerStatus),
    {ok, BinData} = pt_450:write(45011, [Error]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	%io:format("45011:~p~n", [BinData]),
    case is_record(NewPlayerStatus, player_status) of
        true ->
            handle(45018, NewPlayerStatus, no),
            {ok, NewPlayerStatus};
        false ->
            skip
    end;

%祝福解冻
handle(45010, PlayerStatus, _) ->
	%io:format("recv:45010~n"),
    {Time, NewPlayerStatus} = lib_vip:unfreeze(PlayerStatus),
	%io:format("Time:~p~n", [Time]),
    {ok, BinData} = pt_450:write(45010, [Time]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	%io:format("45010:~p~n", [BinData]),
    case is_record(NewPlayerStatus, player_status) of
        true ->
            handle(45018, NewPlayerStatus, no),
            {ok, NewPlayerStatus};
        false ->
            skip
    end;

%进入VIP挂机场景
handle(45012, PlayerStatus, _) ->
    %io:format("recv:45012~n"),
    SceneId = PlayerStatus#player_status.scene,
    case lib_scene:get_data(SceneId) of
        S when is_record(S, ets_scene) ->
            SceneType = S#ets_scene.type;
        _ ->
            SceneType = 9
    end,
    case lib_player:is_transferable(PlayerStatus) =:= true andalso (SceneType =:= ?SCENE_TYPE_NORMAL orelse SceneType =:= ?SCENE_TYPE_NORMAL) of
        false ->
            Error = 2;   %% 失败，不允许切换场景
        true ->
            case PlayerStatus#player_status.lv >= 20 of
                true ->
                    Error = lib_vip:goin_room(PlayerStatus);
                %% 20级以下玩家不能进入
                false ->
                    Error = 2
            end
    end,
    %io:format("Time:~p~n", [Time]),
    {ok, BinData} = pt_450:write(45012, [Error]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    %io:format("45012:~p~n", [BinData]),
    {ok, PlayerStatus};

%退出VIP挂机场景
handle(45013, PlayerStatus, _) ->
	%io:format("recv:45013~n"),
    Error = lib_vip:out_room(PlayerStatus),
	%io:format("Time:~p~n", [Time]),
    {ok, BinData} = pt_450:write(45013, [Error]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	%io:format("45013:~p~n", [BinData]),
    {ok, PlayerStatus};

%今天是否可领开服7天礼包
handle(45014, PlayerStatus, _) ->
	%io:format("recv:45014~n"),
    %% 开服前七天发送
    case util:check_open_day(7) of
        true ->
            %% 判断今天是否已领取
            case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 10007) =:= 0 of
                true ->
                    Vip = PlayerStatus#player_status.vip,
                    case Vip#status_vip.vip_type >= 1 andalso Vip#status_vip.vip_type =< 3 of
                        true -> 
                            Error = 1;
                        false -> 
                            Error = 0
                    end;
                false -> 
                    Error = 0
            end;
        false ->
            Error = 0
    end,
    {ok, BinData} = pt_450:write(45014, [Error]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	%io:format("45014:~p~n", [BinData]),
    {ok, PlayerStatus};

%领取开服7天礼包
handle(45015, PlayerStatus, _) ->
	%io:format("recv:45015~n"),
    %% 开服前七天发送
    case util:check_open_day(7) of
        true ->
            %% 判断今天是否已领取
            case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 10007) =:= 0 of
                true ->
                    Vip = PlayerStatus#player_status.vip,
                    case Vip#status_vip.vip_type >= 1 andalso Vip#status_vip.vip_type =< 3 of
                        true -> 
                            %% 判断背包是否已满
                            GoodsPid = PlayerStatus#player_status.goods#status_goods.goods_pid,
                            CellNum = gen_server:call(GoodsPid, {'cell_num'}),
                            case CellNum =< 0 of 
                                true -> 
                                    Error = 4;
                                false ->
                                    GiftId = lists:nth(Vip#status_vip.vip_type, data_vip_new:get_config(week_vip_gift)),
                                    gen:call(GoodsPid, '$gen_call', {'give_more_bind', [], [{GiftId, 1}]}),
                                    mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 10007),
                                    pp_login_gift:handle(31204, PlayerStatus, no),
                                    Error = 1
                            end;
                        false -> 
                            Error = 5
                    end;
                false -> 
                    Error = 2
            end;
        false ->
            Error = 3
    end,
    {ok, BinData} = pt_450:write(45015, [Error]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	%io:format("45015:~p~n", [BinData]),
    {ok, PlayerStatus};

%查询VIP信息(新)
handle(45016, PlayerStatus, _) ->
    GrowthExp = case PlayerStatus#player_status.vip#status_vip.vip_type of
        3 -> PlayerStatus#player_status.vip#status_vip.growth_exp;
        _ -> 0
    end,
    NextExp = data_vip_new:get_next_exp(GrowthExp),
    GrowthLv = PlayerStatus#player_status.vip#status_vip.growth_lv,
    _RestTime = PlayerStatus#player_status.vip#status_vip.vip_end_time - util:unixtime(),
    RestTime = case _RestTime > 0 of
        true -> _RestTime;
        false -> 0
    end,
    DailyAdd = data_vip_new:add_growth_exp(GrowthExp),
    {ok, BinData} = pt_450:write(45016, [GrowthExp, NextExp, GrowthLv, RestTime, DailyAdd]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    ok;

%立即开通VIP
handle(45017, PlayerStatus, [Type]) ->
    %% 数据检测
    %% 1.周VIP 2.月VIP 3.半年VIP
    case lists:member(Type, [1, 2, 3]) of
        false ->
             skip;
        true ->
            NowType = PlayerStatus#player_status.vip#status_vip.vip_type,
            case NowType of
                %% 失败，VIP体验卡不能升级
                4 ->
                    NewPlayerStatus = PlayerStatus,
                    Res = 2,
                    Str = data_vip_text:get_vip_error(7);
                _ ->
                    case NowType > Type of
                        %% 失败，不能覆盖当前等级VIP
                        true ->
                            NewPlayerStatus = PlayerStatus,
                            Res = 2,
                            Str = data_vip_text:get_vip_error(8);
                        false ->
                            _NeedGold = data_vip_new:get_up_cost(NowType, Type),
                            LimitGoodsList = mod_disperse:call_to_unite(lib_shop, get_limit_list, [PlayerStatus#player_status.id]),
                            NeedGold = lib_vip:check_limit_shop(PlayerStatus, Type, LimitGoodsList, _NeedGold),
                            case PlayerStatus#player_status.gold >= NeedGold of
                                %% 失败，元宝不足
                                false ->
                                    NewPlayerStatus = PlayerStatus,
                                    Res = 2,
                                    Str = data_vip_text:get_vip_error(9);
                                true ->
                                    NewPlayerStatus = lib_vip:new_up_vip(PlayerStatus, Type, NeedGold),
                                    lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
                                    Res = 1,
                                    Str = data_vip_text:get_vip_error(10)
                            end
                    end
            end,
            {ok, BinData} = pt_450:write(45017, [Res, Str]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            %% 刷新客户端
            case Res of
                1 ->
                    handle(45016, NewPlayerStatus, no);
                _ ->
                    skip
            end,
            {ok, NewPlayerStatus}
    end;

%查询VIP福利领取信息
handle(45018, PlayerStatus, _) ->
    Vip = PlayerStatus#player_status.vip,
    NowType = Vip#status_vip.vip_type,
    GrowthLv = Vip#status_vip.growth_lv,
    %% 周礼包
    WeekAward1 = data_vip_new:get_week_award1(NowType),
    WeekAward2 = data_vip_new:get_week_award2(NowType),
    %% 绑定元宝、绑定铜币、VIP礼包、祝福剩余时间
    BindGold1 = lib_vip:date_bingold(NowType),
    BindGold2 = case NowType of
        3 ->
            data_vip_new:get_bind_gold(GrowthLv);
        _ ->
            0
    end,
    BindGold3 = data_vip_new:get_bind_gold(GrowthLv + 1),
    BindCoin1 = lib_vip:date_bincoin(NowType),
    BindCoin2 = case NowType of
        3 ->
            data_vip_new:get_bind_coin(GrowthLv);
        _ ->
            0
    end,
    BindCoin3 = data_vip_new:get_bind_coin(GrowthLv + 1),
%%     VipExpNum = case NowType of
%%         3 -> data_vip_new:get_daily_exp(GrowthLv) + 1;
%%         0 -> 0;
%%         _ -> 1
%%     end,
    VipExpNum = data_vip_new:get_daily_qixuebao(NowType),
%%     VipLilianNum = case NowType of
%%         3 -> data_vip_new:get_daily_lilian(GrowthLv) + 1;
%%         0 -> 0;
%%         _ -> 1
%%     end,
    VipLilianNum = data_vip_new:get_daily_qianghuashi(NowType),
    BlessType = case NowType of
        0 -> 0;
        1 -> 1;
        2 -> 2;
        3 -> 3;
        _ -> 1
    end,
%%     WeekState = case PlayerStatus#player_status.vip#status_vip.vip_type of
%%         3 ->
%%             %% 0级不可领
%%             case GrowthLv of
%%                 0 -> 2;
%%                 _ ->
%%                     case PlayerStatus#player_status.vip#status_vip.get_award of
%%                         %% 未领
%%                         0 -> 
%%                             0;
%%                         %% 已领
%%                         _ -> 1
%%                     end
%%             end;
%%         %% 非半年VIP不可领
%%         _ -> 2
%%     end,
    WeekState = case PlayerStatus#player_status.vip#status_vip.get_award of
        %% 未领
        0 -> 
            0;
        %% 已领
        _ -> 1
    end,
    %% 每日福利
    DailyState = case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12000) of
        %% 未领
        0 -> 
            _RestTime1 = 0,
            _RestTime2 = 0,
            case NowType of
                %% 非VIP不可领
                0 -> 3;
                _ -> 0
            end;
        _ ->
            case mod_vip:lookup_pid(PlayerStatus#player_status.id) of
                %% 找不到，冻结
                undefined -> 
                    _RestTime1 = lib_vip:attr_time(NowType),
                    _RestTime2 = lib_vip:attr_time(NowType),
                    1;
                EtsVipBuff ->
                    _RestTime1 = EtsVipBuff#ets_vip_buff.rest_time,
                    _RestTime2 = EtsVipBuff#ets_vip_buff.buff#ets_buff.end_time - util:unixtime(),
                    EtsVipBuff#ets_vip_buff.state
            end
    end,
    List1 = [WeekAward1, BindGold1 + BindGold2, BindCoin1 + BindCoin2, VipLilianNum, VipExpNum, BlessType],
    List2 = case NowType of
        3 ->
            [WeekAward2, BindGold1 + BindGold3, BindCoin1 + BindCoin3, VipLilianNum, VipExpNum, BlessType];
        %% 当玩家处于周卡月卡，在VIP福利领取界面增加半年卡每日福利和VIP等级1的周礼包预览
        _ ->
            [data_vip_new:get_week_award1(3), lib_vip:date_bingold(3), lib_vip:date_bincoin(3), data_vip_new:get_daily_qianghuashi(3), data_vip_new:get_daily_qixuebao(3), 3]
    end,
    RestTime1 = case _RestTime1 > 0 of
        true -> _RestTime1;
        false -> 0
    end,
    RestTime2 = case _RestTime2 > 0 of
        true -> _RestTime2;
        false -> 0
    end,
    RestTime = case DailyState of
        0 -> 0;
        3 -> 0;
        2 -> RestTime1;
        1 -> RestTime2;
        _ -> 0
    end,
    %io:format("DailyState:~p~n", [DailyState]),
    NextWeekDay = lib_vip_info:get_next_week_day(),
    {ok, BinData} = pt_450:write(45018, [List1, List2, WeekState, DailyState, RestTime, NextWeekDay]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%领取VIP周礼包
handle(45019, PlayerStatus, _) ->
%%     Err = case PlayerStatus#player_status.vip#status_vip.growth_lv of
%%         0 ->
%%             %% VIP成长等级为0，不满足领取条件
%%             Str = data_vip_text:get_vip_error(3),
%%             0;
%%         _Lv ->
%%             %% 是否已领取
%%             case PlayerStatus#player_status.vip#status_vip.get_award of
%%                 %% 未领取
%%                 0 ->
%%                     case _Lv =< 2 of
%%                         true ->
%%                             %% VIP成长等级为1、2级时需要本周登录1天以上才可领取
%%                             case PlayerStatus#player_status.vip#status_vip.login_num >= 1 of
%%                                 %% 可领取
%%                                 true -> 
%%                                     GoodsPid = PlayerStatus#player_status.goods#status_goods.goods_pid,
%%                                     case gen:call(GoodsPid, '$gen_call', {'cell_num'}) of
%%                                         {ok, CellNum} -> ok;
%%                                         _ -> CellNum = 0
%%                                     end,
%%                                     case CellNum > 0 of
%%                                         true ->
%%                                             Str = data_vip_text:get_vip_error(0),
%%                                             1;
%%                                         false ->
%%                                             Str = data_vip_text:get_vip_error(6),
%%                                             0
%%                                     end;
%%                                 %% 未达到领取条件
%%                                 false -> 
%%                                     Str = data_vip_text:get_vip_error(3),
%%                                     0
%%                             end;
%%                         false ->
%%                             %% 可领取
%%                             GoodsPid = PlayerStatus#player_status.goods#status_goods.goods_pid,
%%                             case gen:call(GoodsPid, '$gen_call', {'cell_num'}) of
%%                                 {ok, CellNum} -> ok;
%%                                 _ -> CellNum = 0
%%                             end,
%%                             case CellNum > 0 of
%%                                 true ->
%%                                     Str = data_vip_text:get_vip_error(0),
%%                                     1;
%%                                 false ->
%%                                     Str = data_vip_text:get_vip_error(6),
%%                                     0
%%                             end
%%                     end;
%%                 1 ->
%%                     %% 已领取
%%                     Str = data_vip_text:get_vip_error(5),
%%                     2
%%             end
%%     end,

    %% 是否已领取
    Err = case PlayerStatus#player_status.vip#status_vip.get_award of
        %% 未领取
        0 ->
            %% VIP成长等级为1、2级时需要本周登录1天以上才可领取
            case PlayerStatus#player_status.vip#status_vip.login_num >= 1 of
                %% 可领取
                true -> 
                    GoodsPid = PlayerStatus#player_status.goods#status_goods.goods_pid,
                    case gen:call(GoodsPid, '$gen_call', {'cell_num'}) of
                        {ok, CellNum} -> ok;
                        _ -> CellNum = 0
                    end,
                    case CellNum > 0 of
                        true ->
                            Str = data_vip_text:get_vip_error(0),
                            1;
                        false ->
                            Str = data_vip_text:get_vip_error(6),
                            0
                    end;
                %% 未达到领取条件
                false -> 
                    Str = data_vip_text:get_vip_error(3),
                    0
            end;
        1 ->
            %% 已领取
            Str = data_vip_text:get_vip_error(5),
            2
    end,
    NewPlayerStatus = case Err of
        %% 成功领取，发送奖励
        1 ->
            %% 修改数据库
            {_Year, NowWeekNum} = calendar:iso_week_number(),
            db:execute(io_lib:format(<<"update vip_info set get_award = 1, weeknum = ~p where id = ~p">>, [NowWeekNum, PlayerStatus#player_status.id])),
            %% 发送礼包到背包中
            GoodsPid2 = PlayerStatus#player_status.goods#status_goods.goods_pid,
            GoodsId = data_vip_new:get_week_award1(PlayerStatus#player_status.vip#status_vip.vip_type),
            GoodsNum = 1,
            gen:call(GoodsPid2, '$gen_call', {'give_more_bind', [], [{GoodsId, GoodsNum}]}),
            Vip = PlayerStatus#player_status.vip,
            NewVip = Vip#status_vip{
                get_award = 1
            },
            PlayerStatus#player_status{
                vip = NewVip
            };
        _ ->
            PlayerStatus
    end,
    case Err of
        1 -> lib_player:update_player_info(PlayerStatus#player_status.id, [{refresh_45018, no}]);
        _ -> skip
    end,
    %io:format("Err:~p~n", [Err]),
    {ok, BinData} = pt_450:write(45019, [Err, Str]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    {ok, NewPlayerStatus};

%% 领取每日福利
handle(45020, PlayerStatus, _) ->
    Vip = PlayerStatus#player_status.vip,
    NowType = Vip#status_vip.vip_type,
    GrowthLv = Vip#status_vip.growth_lv,
    case NowType of
        %% 失败，非VIP不能领取VIP每日福利
        0 ->
            Res = 0,
            Str = data_vip_text:get_vip_error(11),
            NewPlayerStatus2 = PlayerStatus;
        _ ->
            case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12000) of
                %% 未领
                0 -> 
                    mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12000),
                    %% 领取VIP礼包
                    handle(45008, PlayerStatus, [3]),
                    %% 领取VIP祝福
                    handle(45008, PlayerStatus, [4]),
                    mod_daily:set_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 1301, 1),
                    mod_daily:set_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 1302, 1),
                    mod_daily:set_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 1303, 1),
                    mod_daily:set_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 1304, 1),
                    pp_login_gift:handle(31204, PlayerStatus, no),
                    BindGold1 = lib_vip:date_bingold(NowType),
                    BindGold2 = case NowType of
                        3 -> data_vip_new:get_bind_gold(GrowthLv);
                        _ -> 0
                    end,
                    BindGold = BindGold1 + BindGold2,
                    BindCoin1 = lib_vip:date_bincoin(NowType),
                    BindCoin2 = case NowType of
                        3 -> data_vip_new:get_bind_coin(GrowthLv);
                        _ -> 0
                    end,
                    BindCoin = BindCoin1 + BindCoin2,
                    NewPlayerStatus1 = lib_goods_util:add_money(PlayerStatus, BindGold, bgold),
                    log:log_produce(vip, bgold, PlayerStatus, NewPlayerStatus1, "vip bgold"),
                    NewPlayerStatus2 = lib_goods_util:add_money(NewPlayerStatus1, BindCoin, coin),
                    log:log_produce(vip, coin, NewPlayerStatus1, NewPlayerStatus2, "vip coin"),
                    Res = 1,
                    Str = data_vip_text:get_vip_error(0);
                %% 失败，已领取
                _ ->
                    Res = 0,
                    Str = data_vip_text:get_vip_error(1),
                    NewPlayerStatus2 = PlayerStatus
            end
    end,
    case Res of
        1 -> lib_player:update_player_info(PlayerStatus#player_status.id, [{refresh_45018, no}]);
        _ -> skip
    end,
    {ok, BinData} = pt_450:write(45020, [Res, Str]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    {ok, NewPlayerStatus2};

%% 为好友开通VIP
handle(45021, PlayerStatus, [Type, NickName]) ->
    %% 数据验证
    case lists:member(Type, [1, 2, 3]) of
        true ->
            %% 根据玩家名称获得玩家ID
            RoleId = case mod_disperse:call_to_unite(lib_vip, get_role_id, [NickName]) of
                _RoleId when is_integer(_RoleId) ->
                    _RoleId;
                _ ->
                    0
            end,
            case RoleId of
                %% 失败，没有该玩家信息
                0 ->
                    Res = 0,
                    Str = data_vip_text:get_vip_error(12),
                    NewPlayerStatus = PlayerStatus;
                _ ->
                    NeedGold = data_vip_new:get_up_cost(0, Type),
                    case PlayerStatus#player_status.gold >= NeedGold of
                        %% 失败，元宝不足
                        false ->
                            Res = 0,
                            Str = data_vip_text:get_vip_error(9),
                            NewPlayerStatus = PlayerStatus;
                        %% 成功
                        true ->
                            NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, NeedGold, gold),
                            GoodsId = case Type of
                                1 -> 631001;
                                2 -> 631101;
                                _ -> 631201
                            end,
                            log:log_consume(pay_vip_upgrade, gold, PlayerStatus, NewPlayerStatus, GoodsId, 1, ["pay_vip_for_friend"]),
                            Title = data_vip_text:get_vip_text(2),
                            TypeText = case Type of
                                1 -> data_vip_text:get_vip_text(4);
                                2 -> data_vip_text:get_vip_text(5);
                                _ -> data_vip_text:get_vip_text(6)
                            end,
                            Content = io_lib:format(data_vip_text:get_vip_text(3), [util:make_sure_list(PlayerStatus#player_status.nickname), util:make_sure_list(TypeText)]),
                            GoodsNum = 1,
                            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[RoleId], Title, Content, GoodsId, 2, 0, 0, GoodsNum, 0, 0, 0, 0]),
                            Res = 1,
                            Str = data_vip_text:get_vip_error(10)
                    end
            end,
            {ok, BinData} = pt_450:write(45021, [Res, Str]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            {ok, NewPlayerStatus};
        false ->
            skip
    end;


%% 获取VIP摇奖信息
handle(45022, PlayerStatus, _Bin) ->
    GrowthLv = PlayerStatus#player_status.vip#status_vip.growth_lv,
    %List1 = data_vip_new:get_now_award_list(GrowthLv),
    List1 = case mod_daily:get_special_info(PlayerStatus#player_status.dailypid, all_vip_shake) of
        _List1 when is_list(_List1) ->
            _List1;
        _ ->
            _List1 = lib_vip:get_rand_award_list(PlayerStatus),
            mod_daily:set_special_info(PlayerStatus#player_status.dailypid, all_vip_shake, _List1),
            _List1
    end,
    List2 = case mod_daily:get_special_info(PlayerStatus#player_status.dailypid, vip_shake) of
        _List2 when is_list(_List2) ->
            _List2;
        _ ->
            []
    end,
    %io:format("List1:~p~n", [List1]),
    NeedGold =  mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12002) + 1,
    MaxNum = data_vip_new:get_max_shake_num(GrowthLv),
    NowNum = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12003),
    _RestNum = MaxNum - NowNum,
    RestNum = case _RestNum > 0 of
        true -> _RestNum;
        false -> 0
    end,
    {ok, BinData} = pt_450:write(45022, [List1, List2, NeedGold, RestNum]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    ok;

%% 摇奖
handle(45023, PlayerStatus, _Bin) ->
    GrowthLv = case PlayerStatus#player_status.vip#status_vip.vip_type of
        3 -> PlayerStatus#player_status.vip#status_vip.growth_lv;
        _ -> 0
    end,
    MaxNum = data_vip_new:get_max_shake_num(GrowthLv),
    case GrowthLv of
        %% 失败，0级不能进行摇奖
        999 ->
            Res = 0,
            Str = data_vip_text:get_vip_error(13),
            GoodsId = 0,
            GoodsNum = 0;
        _ ->
            case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12003) >= MaxNum of
                %% 失败，当前VIP成长等级摇奖次数已完
                true ->
                    Res = 0,
                    Str = data_vip_text:get_vip_error(21),
                    GoodsId = 0,
                    GoodsNum = 0;
                %% 成功
                false ->
                    List1 = case mod_daily:get_special_info(PlayerStatus#player_status.dailypid, all_vip_shake) of
                        _List1 when is_list(_List1) ->
                            _List1;
                        _ ->
                            _List1 = lib_vip:get_rand_award_list(PlayerStatus),
                            mod_daily:set_special_info(PlayerStatus#player_status.dailypid, all_vip_shake, _List1),
                            _List1
                    end,
                    AllGoods = List1,
                    %AllGoods = lib_vip:combine_list(data_vip_new:get_now_award_list(GrowthLv), data_vip_new:get_award_pro(GrowthLv), []),
                    ShakeGoods = case mod_daily:get_special_info(PlayerStatus#player_status.dailypid, vip_shake) of
                        _List when is_list(_List) ->
                            _List;
                        _ ->
                            []
                    end,
                    GoodsList = AllGoods -- ShakeGoods,
                    case GoodsList of
                        %% 失败，今天摇奖次数已完
                        [] ->
                            Res = 0,
                            Str = data_vip_text:get_vip_error(14),
                            GoodsId = 0,
                            GoodsNum = 0;
                        _ ->
                            NeedGold =  mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12002) + 1,
                            GoodsTypeId = data_vip_new:get_config(gold_goods_id),
                            case mod_other_call:get_goods_num(PlayerStatus, GoodsTypeId, 0) >= NeedGold of
                                %% 失败，金币数不足
                                false ->
                                    Res = 0,
                                    Str = data_vip_text:get_vip_error(15),
                                    GoodsId = 0,
                                    GoodsNum = 0;
                                true ->
                                    GoodsPid = PlayerStatus#player_status.goods#status_goods.goods_pid,
                                    case gen:call(GoodsPid, '$gen_call', {'cell_num'}) of
                                        {ok, Cell} ->
                                            case Cell > 0 of
                                                true ->
                                                    {GoodsId, GoodsNum, GoodsPro, Type} = lib_vip:rand_award(GoodsList),
                                                    case GoodsId of
                                                        %% 失败，获取摇奖概率失败
                                                        0 ->
                                                            Res = 1,
                                                            Str = data_vip_text:get_vip_error(10);
                                                        %% 成功
                                                        _ ->
                                                            %% 扣除物品
                                                            lib_player:update_player_info(PlayerStatus#player_status.id, [{use_goods, {GoodsTypeId, NeedGold}}]),
                                                            mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12002),
                                                            mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12003),
                                                            mod_daily:set_special_info(PlayerStatus#player_status.dailypid, vip_shake, [{GoodsId, GoodsNum, GoodsPro, Type} | ShakeGoods]),
                                                            %% 发物品
                                                            gen:call(GoodsPid, '$gen_call', {'give_more_bind', [], [{GoodsId, GoodsNum}]}),
                                                            Res = 1,
                                                            Str = data_vip_text:get_vip_error(10),
                                                            handle(45022, PlayerStatus, no)
                                                    end;
                                                %% 失败，背包容量不足
                                                false ->
                                                    Res = 0,
                                                    Str = data_vip_text:get_vip_error(16),
                                                    GoodsId = 0,
                                                    GoodsNum = 0
                                            end;
                                        _ ->
                                            Res = 0,
                                            Str = data_vip_text:get_vip_error(16),
                                            GoodsId = 0,
                                            GoodsNum = 0
                                    end
                            end
                    end
            end
    end,
    {ok, BinData} = pt_450:write(45023, [Res, Str, GoodsId, GoodsNum]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    ok;

%% 清空摇奖
handle(45024, PlayerStatus, _Bin) ->
    GrowthLv = PlayerStatus#player_status.vip#status_vip.growth_lv,
    case GrowthLv of
        %% 失败，0级不能进行该操作
        0 ->
            Res = 0,
            _Str = data_vip_text:get_vip_error(17);
        _ ->
            ShakeGoods = case mod_daily:get_special_info(PlayerStatus#player_status.dailypid, vip_shake) of
                _List when is_list(_List) ->
                    _List;
                _ ->
                    []
            end,
            case ShakeGoods of
                %% 失败，无需清空摇奖物品
                %[] ->
                no ->
                    Res = 0,
                    _Str = data_vip_text:get_vip_error(18);
                _ ->
                    mod_daily:set_special_info(PlayerStatus#player_status.dailypid, vip_shake, []),
                    mod_daily:set_special_info(PlayerStatus#player_status.dailypid, all_vip_shake, no),
                    mod_daily:set_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12002, 0),
                    Res = 1,
                    _Str = data_vip_text:get_vip_error(10),
                    handle(45022, PlayerStatus, no)
            end
    end,
    Str = "",
    {ok, BinData} = pt_450:write(45024, [Res, Str]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    ok;

%% VIP续费
%% Time: 单位时间(半年卡：月；月卡：15天；周卡：1天)
%% AutoBuy: 是否自动购买 1.是 2.否
handle(45050, PlayerStatus, [Time, AutoBuy]) ->
    %% 数据检测
    case Time > 0 andalso lists:member(AutoBuy, [1, 2]) of
        true ->
            StatusVip = PlayerStatus#player_status.vip,
            VipType = StatusVip#status_vip.vip_type,
            case lists:member(VipType, [1, 2, 3]) andalso StatusVip#status_vip.vip_end_time > util:unixtime() of
                %% 失败，只有周VIP、月VIP和半年VIP用户才能进行续费
                false ->
                    Res = 2,
                    Str = data_vip_text:get_vip_error(22),
                    NewPlayerStatus = PlayerStatus;
                true ->
                    case VipType of
                        1 ->
                            PerNum = 3,
                            PerTime = 7 * 24 * 60 * 60;
                        2 ->
                            PerNum = 6,
                            PerTime = 15 * 24 * 60 * 60;
                        _ ->
                            PerNum = 10,
                            PerTime = 30 * 24 * 60 * 60
                    end,
                    TotalNum = PerNum * Time,
                    TotalTime = PerTime * Time,
                    GoodsTypeId = 631003,
                    BackNum = mod_other_call:get_goods_num(PlayerStatus, GoodsTypeId, 0),
                    case BackNum >= TotalNum of
                        true ->
                            %% 物品消耗日志
                            lib_player:update_player_info(PlayerStatus#player_status.id, [{use_goods, {GoodsTypeId, TotalNum}}]),
                            log:log_goods_use(PlayerStatus#player_status.id, GoodsTypeId, TotalNum),
                            NewPlayerStatus = PlayerStatus#player_status{
                                vip = StatusVip#status_vip{
                                    vip_end_time = StatusVip#status_vip.vip_end_time + TotalTime
                                }
                            },
                            lib_player:refresh_client(PlayerStatus#player_status.id, 2),
                            NewEndTime = StatusVip#status_vip.vip_end_time + TotalTime,
                            db:execute(io_lib:format(<<"update player_vip set vip_time = ~p where id = ~p">>, [NewEndTime, PlayerStatus#player_status.id])),
                            Res = 1,
                            Str = io_lib:format(data_vip_text:get_vip_error(26), [data_vip_text:get_vip_type_text(VipType), PerTime div (24 * 60 * 60)]);
                        %% 背包物品不足
                        false ->
                            case AutoBuy of
                                1 ->
                                    GoodsType = data_shop:get_by_goods(1, 2, GoodsTypeId),
                                    case is_record(GoodsType, ets_shop) of
                                        true ->
                                            PerPrice = GoodsType#ets_shop.new_price,
                                            LessNum = TotalNum - BackNum,
                                            TotalPrice = PerPrice * LessNum,
                                            case PlayerStatus#player_status.gold >= TotalPrice of
                                                true ->
                                                    _NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, TotalPrice, gold),
                                                    %% 元宝消耗日志
                                                    log:log_consume(goods_pay, gold, PlayerStatus, _NewPlayerStatus, GoodsTypeId, LessNum, "pay for good"),
                                                    %% 物品消耗日志
                                                    lib_player:update_player_info(PlayerStatus#player_status.id, [{use_goods, {GoodsTypeId, BackNum}}]),
                                                    log:log_goods_use(PlayerStatus#player_status.id, GoodsTypeId, TotalNum),
                                                    NewPlayerStatus = _NewPlayerStatus#player_status{
                                                        vip = StatusVip#status_vip{
                                                            vip_end_time = StatusVip#status_vip.vip_end_time + TotalTime
                                                        }
                                                    },
                                                    lib_player:refresh_client(PlayerStatus#player_status.id, 2),
                                                    NewEndTime = StatusVip#status_vip.vip_end_time + TotalTime,
                                                    db:execute(io_lib:format(<<"update player_vip set vip_time = ~p where id = ~p">>, [NewEndTime, PlayerStatus#player_status.id])),
                                                    Res = 1,
                                                    Str = io_lib:format(data_vip_text:get_vip_error(26), [data_vip_text:get_vip_type_text(VipType), PerTime div (24 * 60 * 60)]);
                                                %% 失败，元宝不足
                                                false ->
                                                    Res = 2,
                                                    Str = data_vip_text:get_vip_error(25),
                                                    NewPlayerStatus = PlayerStatus
                                            end;
                                        %% 失败，找不到该物品
                                        false ->
                                            Res = 2,
                                            Str = data_vip_text:get_vip_error(24),
                                            NewPlayerStatus = PlayerStatus
                                    end;
                                %% 不自动购买
                                %% 失败，背包物品不足
                                _ ->
                                    Res = 2,
                                    Str = data_vip_text:get_vip_error(23),
                                    NewPlayerStatus = PlayerStatus
                            end
                    end
            end,
            {ok, BinData} = pt_450:write(45050, [Res, Str]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            case Res of
                1 -> handle(45016, NewPlayerStatus, no);
                _ -> skip
            end,
            {ok, NewPlayerStatus};
        false ->
            skip
    end;

%% 一键全摇奖
handle(45051, PlayerStatus, _Bin) ->
    GrowthLv = case PlayerStatus#player_status.vip#status_vip.vip_type of
        3 -> PlayerStatus#player_status.vip#status_vip.growth_lv;
        _ -> 0
    end,
    MaxNum = data_vip_new:get_max_shake_num(GrowthLv),
    case GrowthLv of
        %% 失败，0级不能进行摇奖
        999 ->
            Res = 0,
            Str = data_vip_text:get_vip_error(13),
            GoodsIdList = [];
        _ ->
            NowNum = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12003),
            case NowNum >= MaxNum of
                %% 失败，当前VIP成长等级摇奖次数已完
                true ->
                    Res = 0,
                    Str = data_vip_text:get_vip_error(21),
                    GoodsIdList = [];
                %% 成功
                false ->
                    List1 = case mod_daily:get_special_info(PlayerStatus#player_status.dailypid, all_vip_shake) of
                        _List1 when is_list(_List1) ->
                            _List1;
                        _ ->
                            _List1 = lib_vip:get_rand_award_list(PlayerStatus),
                            mod_daily:set_special_info(PlayerStatus#player_status.dailypid, all_vip_shake, _List1),
                            _List1
                    end,
                    AllGoods = List1,
                    %AllGoods = lib_vip:combine_list(data_vip_new:get_now_award_list(GrowthLv), data_vip_new:get_award_pro(GrowthLv), []),
                    ShakeGoods = case mod_daily:get_special_info(PlayerStatus#player_status.dailypid, vip_shake) of
                        _List when is_list(_List) ->
                            _List;
                        _ ->
                            []
                    end,
                    GoodsList = AllGoods -- ShakeGoods,
                    case GoodsList of
                        %% 失败，今天摇奖次数已完
                        [] ->
                            Res = 0,
                            Str = data_vip_text:get_vip_error(14),
                            GoodsIdList = [];
                        _ ->
                            NeedGold =  mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12002) + 1,
                            RestNum = MaxNum - NowNum,
                            AllNeedGold = ((NeedGold + (NeedGold + RestNum - 1)) * RestNum) div 2,
                            GoodsTypeId = data_vip_new:get_config(gold_goods_id),
                            case mod_other_call:get_goods_num(PlayerStatus, GoodsTypeId, 0) >= AllNeedGold of
                                %% 失败，金币数不足
                                false ->
                                    Res = 0,
                                    Str = data_vip_text:get_vip_error(15),
                                    GoodsIdList = [];
                                true ->
                                    NeedCell = RestNum,
                                    GoodsPid = PlayerStatus#player_status.goods#status_goods.goods_pid,
                                    case gen:call(GoodsPid, '$gen_call', {'cell_num'}) of
                                        {ok, Cell} ->
                                            case Cell >= NeedCell of
                                                true ->
                                                    GetGoodsList = lib_vip:get_rand_awards(GoodsList, NeedCell, []),
                                                    case GetGoodsList of
                                                        %% 失败，获取摇奖概率失败
                                                        [] ->
                                                            Res = 1,
                                                            Str = data_vip_text:get_vip_error(10),
                                                            GoodsIdList = [];
                                                        %% 成功
                                                        _ ->
                                                            %% 扣除物品
                                                            lib_player:update_player_info(PlayerStatus#player_status.id, [{use_goods, {GoodsTypeId, AllNeedGold}}]),
                                                            mod_daily:set_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12002, MaxNum),
                                                            mod_daily:set_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 12003, MaxNum),
                                                            mod_daily:set_special_info(PlayerStatus#player_status.dailypid, vip_shake, ShakeGoods ++ GetGoodsList),
                                                            SendGoodsList = lib_vip:trans_send_list(GetGoodsList, []),
                                                            %% 发物品
                                                            gen:call(GoodsPid, '$gen_call', {'give_more_bind', [], SendGoodsList}),
                                                            Res = 1,
                                                            Str = data_vip_text:get_vip_error(10),
                                                            GoodsIdList = lib_vip:trans_goods_id_list(GetGoodsList, [])
                                                    end;
                                                %% 失败，背包容量不足
                                                false ->
                                                    Res = 0,
                                                    Str = data_vip_text:get_vip_error(16),
                                                    GoodsIdList = []
                                            end;
                                        _ ->
                                            Res = 0,
                                            Str = data_vip_text:get_vip_error(16),
                                            GoodsIdList = []
                                    end
                            end
                    end
            end
    end,
    %io:format("GoodsIdList:~p~n", [GoodsIdList]),
    {ok, BinData} = pt_450:write(45051, [Res, Str, GoodsIdList]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    case Res of
        1 -> handle(45022, PlayerStatus, no);
        _ -> skip
    end,
    ok;

%% VIP升级
handle(45052, PlayerStatus, _) ->
    Vip = PlayerStatus#player_status.vip,
    case lists:member(Vip#status_vip.vip_type, [1, 2]) andalso Vip#status_vip.vip_end_time > util:unixtime() of
        true ->
            [WeekCardNum, MonthCardNum, YearCardNum] = get_card_info(PlayerStatus),
            _AlreadyVipDay = WeekCardNum * 7 + MonthCardNum * 30 + YearCardNum * 180,
            _RestVipDay = (Vip#status_vip.vip_end_time - util:unixtime()) div (24 * 3600),
            RestVipDay = case _RestVipDay > 0 of
                true -> _RestVipDay;
                false -> 0
            end,
            _AlreadyVipDay2 = _AlreadyVipDay - RestVipDay,
            AlreadyVipDay = case _AlreadyVipDay2 > 0 of
                true -> _AlreadyVipDay2;
                false -> 0
            end,
            MinusCardNum1 = (AlreadyVipDay div 7) + 1,
            MinusCardNum2 = RestVipDay div 7 * 3,
            TotalCardNum = case Vip#status_vip.vip_type of
                1 -> 12;
                2 -> 60
            end,
            _NowNeedCardNum = TotalCardNum - MinusCardNum1 - MinusCardNum2,
            NowNeedCardNum = case _NowNeedCardNum > 0 of
                true -> _NowNeedCardNum;
                false -> 0
            end,
            GoodsTypeId = 631003,
            BackNum = mod_other_call:get_goods_num(PlayerStatus, GoodsTypeId, 0),
            NeedCardNum = NowNeedCardNum,
            case BackNum >= NeedCardNum of
                %% 背包的续费卡足够
                true ->
                    %% 物品消耗日志
                    lib_player:update_player_info(PlayerStatus#player_status.id, [{use_goods, {GoodsTypeId, NeedCardNum}}]),
                    log:log_goods_use(PlayerStatus#player_status.id, GoodsTypeId, NeedCardNum),
                    NewType = Vip#status_vip.vip_type + 1,
                    VipTime = case NewType of
                        2 -> 30 * 24 * 3600;
                        3 -> 180 * 24 * 3600
                    end,
                    NewEndTime = util:unixtime() + VipTime,
                    NewPlayerStatus = PlayerStatus#player_status{
                        vip = Vip#status_vip{
                            vip_type = NewType,
                            vip_end_time = NewEndTime
                        }
                    },
                    VipUpGoodsId = case NewType of
                        2 -> 631102;
                        3 -> 631202
                    end,
                    log:log_consume(pay_vip_upgrade, gold, PlayerStatus, NewPlayerStatus, VipUpGoodsId, 1, ["pay_vip_upgrade"]),
                    %% Vip等级同步到公共线
                    lib_player:update_unite_info(NewPlayerStatus#player_status.unite_pid, [{vip, NewType}]),
                    lib_player:refresh_client(PlayerStatus#player_status.id, 2),
                    db:execute(io_lib:format(<<"update player_vip set vip_type = ~p, vip_time = ~p where id = ~p">>, [NewType, NewEndTime, PlayerStatus#player_status.id])),
                    %VIP广播
                    {ok, Bin} = pt_122:write(12203, [PlayerStatus#player_status.id, PlayerStatus#player_status.platform, PlayerStatus#player_status.server_num, NewType]),
                    lib_server_send:send_to_scene(PlayerStatus#player_status.scene, PlayerStatus#player_status.copy_id, Bin),
                    %世界传闻 格式:"vip" + viptype + id + name + sex + career + image + realm
                    lib_chat:send_TV({all},0,1, ["vip",
                            NewType,
                            PlayerStatus#player_status.id, 
                            PlayerStatus#player_status.nickname, 
                            PlayerStatus#player_status.sex, 
                            PlayerStatus#player_status.career, 
                            PlayerStatus#player_status.image, 
                            PlayerStatus#player_status.realm]),
                    mod_disperse:cast_to_unite(lib_guild, change_vip, [PlayerStatus#player_status.id, NewType]),
                    %%新服vip礼包奖励
                    Sec = data_vip_new:get_vip_time(NewType),
                    NewPlayerStatus1 = lib_vip:send_vip_bag(NewPlayerStatus, NewType, Sec),
                    V = NewPlayerStatus1#player_status.vip,
                    LeftTime = V#status_vip.vip_end_time - util:unixtime(),
                    {ok, BinData} = pt_450:write(45003, [LeftTime]),
                    lib_server_send:send_one(NewPlayerStatus1#player_status.socket, BinData),
                    pp_vip:handle(45007, NewPlayerStatus1, 0),
                    %% 是否可领取开服7天礼包
                    pp_vip:handle(45014, NewPlayerStatus1, no),
                    erase(vip_up_info),
                    Res = 1,
                    Str = data_vip_text:get_vip_error(28);
                %% 背包的续费卡不足够
                false ->
                    BuyNum = NeedCardNum - BackNum,
                    GoodsType = data_shop:get_by_goods(1, 2, GoodsTypeId),
                    PerPrice = GoodsType#ets_shop.new_price,
                    TotalPrice = PerPrice * BuyNum,
                    case PlayerStatus#player_status.gold >= TotalPrice of
                        %% 自动购买续费卡
                        true ->
                            _NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, TotalPrice, gold),
                            %% 消费接口
                            lib_activity:add_consumption(vipup, PlayerStatus, TotalPrice), 
                            %% 元宝消耗日志
                            log:log_consume(goods_pay, gold, PlayerStatus, _NewPlayerStatus, GoodsTypeId, BuyNum, "pay for good"),
                            %% 物品消耗日志
                            lib_player:update_player_info(PlayerStatus#player_status.id, [{use_goods, {GoodsTypeId, BackNum}}]),
                            log:log_goods_use(PlayerStatus#player_status.id, GoodsTypeId, NeedCardNum),
                            NewType = Vip#status_vip.vip_type + 1,
                            VipTime = case NewType of
                                2 -> 30 * 24 * 3600;
                                3 -> 180 * 24 * 3600
                            end,
                            NewEndTime = util:unixtime() + VipTime,
                            NewPlayerStatus = _NewPlayerStatus#player_status{
                                vip = Vip#status_vip{
                                    vip_type = NewType,
                                    vip_end_time = NewEndTime
                                }
                            },
                            VipUpGoodsId = case NewType of
                                2 -> 631102;
                                3 -> 631202
                            end,
                            log:log_consume(pay_vip_upgrade, gold, PlayerStatus, NewPlayerStatus, VipUpGoodsId, 1, ["pay_vip_upgrade"]),
                            %% Vip等级同步到公共线
                            lib_player:update_unite_info(NewPlayerStatus#player_status.unite_pid, [{vip, NewType}]),
                            lib_player:refresh_client(PlayerStatus#player_status.id, 2),
                            db:execute(io_lib:format(<<"update player_vip set vip_type = ~p, vip_time = ~p where id = ~p">>, [NewType, NewEndTime, PlayerStatus#player_status.id])),
                            %VIP广播
                            {ok, Bin} = pt_122:write(12203, [PlayerStatus#player_status.id, PlayerStatus#player_status.platform, PlayerStatus#player_status.server_num, NewType]),
                            lib_server_send:send_to_scene(PlayerStatus#player_status.scene, PlayerStatus#player_status.copy_id, Bin),
                            %世界传闻 格式:"vip" + viptype + id + name + sex + career + image + realm
                            lib_chat:send_TV({all},0,1, ["vip",
                                    NewType,
                                    PlayerStatus#player_status.id, 
                                    PlayerStatus#player_status.nickname, 
                                    PlayerStatus#player_status.sex, 
                                    PlayerStatus#player_status.career, 
                                    PlayerStatus#player_status.image, 
                                    PlayerStatus#player_status.realm]),
                            mod_disperse:cast_to_unite(lib_guild, change_vip, [PlayerStatus#player_status.id, NewType]),
                            %%新服vip礼包奖励
                            Sec = data_vip_new:get_vip_time(NewType),
                            NewPlayerStatus1 = lib_vip:send_vip_bag(NewPlayerStatus, NewType, Sec),
                            V = NewPlayerStatus1#player_status.vip,
                            LeftTime = V#status_vip.vip_end_time - util:unixtime(),
                            {ok, BinData} = pt_450:write(45003, [LeftTime]),
                            lib_server_send:send_one(NewPlayerStatus1#player_status.socket, BinData),
                            pp_vip:handle(45007, NewPlayerStatus1, 0),
                            %% 是否可领取开服7天礼包
                            pp_vip:handle(45014, NewPlayerStatus1, no),
                            erase(vip_up_info),
                            Res = 1,
                            Str = data_vip_text:get_vip_error(28);
                        %% 失败，元宝不足
                        false ->
                            Res = 0,
                            Str = data_vip_text:get_vip_error(29),
                            NewPlayerStatus1 = PlayerStatus
                    end
            end;
        %% 失败，只有周卡和月卡用户可以升级VIP
        false ->
            Res = 0,
			Str = data_vip_text:get_vip_error(27),
            NewPlayerStatus1 = PlayerStatus
    end,
    {ok, BinData2} = pt_450:write(45052, [Res, Str]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData2),
    handle(45053, NewPlayerStatus1, no),
    handle(45016, NewPlayerStatus1, no),
    {ok, NewPlayerStatus1};

%% VIP升级信息
handle(45053, PlayerStatus, _) ->
    Vip = PlayerStatus#player_status.vip,
    case lists:member(Vip#status_vip.vip_type, [1, 2]) of
        false ->
            skip;
        true ->
            [WeekCardNum, MonthCardNum, YearCardNum] = get_card_info(PlayerStatus),
            _AlreadyVipDay = WeekCardNum * 7 + MonthCardNum * 30 + YearCardNum * 180,
            _RestVipDay = (Vip#status_vip.vip_end_time - util:unixtime()) div (24 * 3600),
            RestVipDay = case _RestVipDay > 0 of
                true -> _RestVipDay;
                false -> 0
            end,
            _AlreadyVipDay2 = _AlreadyVipDay - RestVipDay,
            AlreadyVipDay = case _AlreadyVipDay2 > 0 of
                true -> _AlreadyVipDay2;
                false -> 0
            end,
            %io:format("~p~n", [[WeekCardNum, MonthCardNum, YearCardNum, _RestVipDay]]),
            MinusCardNum1 = (AlreadyVipDay div 7) + 1,
            MinusCardNum2 = RestVipDay div 7 * 3,
            %% 价格
            GoodsTypeId = 631003,
            GoodsType = data_shop:get_by_goods(1, 2, GoodsTypeId),
            PerPrice = GoodsType#ets_shop.new_price,
            TotalCardNum = case Vip#status_vip.vip_type of
                1 -> 12;
                2 -> 60
            end,
            _NowNeedCardNum = TotalCardNum - MinusCardNum1 - MinusCardNum2,
            NowNeedCardNum = case _NowNeedCardNum > 0 of
                true -> _NowNeedCardNum;
                false -> 0
            end,
            NowCost = PerPrice * NowNeedCardNum,
            TotalCost = PerPrice * TotalCardNum,
            SaveCost = TotalCost - NowCost,
            %io:format("45053:~p~n", [[AlreadyVipDay, MinusCardNum1, RestVipDay, MinusCardNum2, NowCost, SaveCost]]),
            {ok, BinData} = pt_450:write(45053, [AlreadyVipDay, MinusCardNum1, RestVipDay, MinusCardNum2, NowCost, SaveCost]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData)
    end;

%% 查看首冲礼包领取情况
handle(45062, PlayerStatus, _) ->
    Vip = PlayerStatus#player_status.vip,
    case is_list(Vip#status_vip.vip_bag_flag) of
        true ->
            ZhouKa = case lists:member(1, Vip#status_vip.vip_bag_flag) of
                         true -> 1;
                         false -> 0
                     end,
            YueKa = case lists:member(2, Vip#status_vip.vip_bag_flag) of
                         true -> 1;
                         false -> 0
                    end,
            BanNianKa = case lists:member(3, Vip#status_vip.vip_bag_flag) of
                         true -> 1;
                         false -> 0
                        end,
            {ok, BinData} = pt_450:write(45062, [ZhouKa, YueKa, BanNianKa]),
            %%io:format("ZhouKa:~p YueKa:~p BanNianKa:~p", [ZhouKa,YueKa,BanNianKa]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        false ->
            {ok, BinData} = pt_450:write(45062, [0, 0, 0]),
            %%io:format("ZhouKa:~p YueKa:~p BanNianKa:~p", [0,0,0]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData)
    end;

handle(_Cmd, _PlayerStatus, _Bin) ->
    util:errlog("pp_vip handdle ~p error~n", [_Cmd]),
    {ok, no_match}.

%% 玩家已使用的VIP卡数量
get_card_info(PlayerStatus) ->
    case get(vip_up_info) of
        undefined ->
            case db:get_row(io_lib:format(<<"select count(id) from log_goods_use where role_id = ~p and goods_id = ~p limit 1">>, [PlayerStatus#player_status.id, 631001])) of
                [WeekCardNum1] ->
                    ok;
                _ ->
                    WeekCardNum1 = 0
            end,
            case db:get_row(io_lib:format(<<"select count(id) from log_goods_use where role_id = ~p and (goods_id = ~p or goods_id = ~p) limit 1">>, [PlayerStatus#player_status.id, 631101, 631102])) of
                [MonthCardNum1] ->
                    ok;
                _ ->
                    MonthCardNum1 = 0
            end,
            case db:get_row(io_lib:format(<<"select count(id) from log_goods_use where role_id = ~p and (goods_id = ~p or goods_id = ~p) limit 1">>, [PlayerStatus#player_status.id, 631201, 631202])) of
                [YearCardNum1] ->
                    ok;
                _ ->
                    YearCardNum1 = 0
            end,
            ConsumeType = data_goods:get_consume_type(pay_vip_upgrade),
            case db:get_row(io_lib:format(<<"select count(id) from log_consume_gold where player_id = ~p and goods_id = ~p and consume_type = ~p limit 1">>, [PlayerStatus#player_status.id, 631001, ConsumeType])) of
                [WeekCardNum2] ->
                    ok;
                _ ->
                    WeekCardNum2 = 0
            end,
            case db:get_row(io_lib:format(<<"select count(id) from log_consume_gold where player_id = ~p and (goods_id = ~p or goods_id = ~p) and consume_type = ~p limit 1">>, [PlayerStatus#player_status.id, 631101, 631102, ConsumeType])) of
                [MonthCardNum2] ->
                    ok;
                _ ->
                    MonthCardNum2 = 0
            end,
            case db:get_row(io_lib:format(<<"select count(id) from log_consume_gold where player_id = ~p and (goods_id = ~p or goods_id = ~p) and consume_type = ~p limit 1">>, [PlayerStatus#player_status.id, 631201, 631202, ConsumeType])) of
                [YearCardNum2] ->
                    ok;
                _ ->
                    YearCardNum2 = 0
            end,
            WeekCardNum = WeekCardNum1 + WeekCardNum2,
            MonthCardNum = MonthCardNum1 + MonthCardNum2,
            YearCardNum = YearCardNum1 + YearCardNum2,
            put(vip_up_info, [WeekCardNum, MonthCardNum, YearCardNum]),
            [WeekCardNum, MonthCardNum, YearCardNum];
        [WeekCardNum, MonthCardNum, YearCardNum] ->
            [WeekCardNum, MonthCardNum, YearCardNum]
    end.
