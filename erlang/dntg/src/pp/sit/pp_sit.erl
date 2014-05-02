%% --------------------------------------------------------
%% @Module:           |pp_sit
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-03-22
%% @Description:      |打坐双修功能
%% --------------------------------------------------------
-module(pp_sit).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("unite.hrl").

%% 
handle(13101, Status, sit_down) ->
    Sit = Status#player_status.sit,
    Mou = Status#player_status.mount,
    case Sit#status_sit.sit_down =:= 0 of
        true ->
            case Mou#status_mount.mount > 0 of
                true ->
                    case pp_mount:handle(16003, Status, Mou#status_mount.mount) of
                        {ok, Status1} ->
                            NewStatus = lib_sit:sit_down(Status1),
                            {ok, NewStatus};
                        _ -> skip
                    end;
                false ->
                    NewStatus = lib_sit:sit_down(Status),
                    {ok, NewStatus}
            end;
        false -> skip
    end;

%% 打坐回复_加经验等
handle(13102, Status, sit_down_reply) ->
    Sit = Status#player_status.sit,
    case Sit#status_sit.sit_down > 0 of
        true ->
            NewStatus = lib_sit:sit_down_reply(Status),
            lib_player:send_attribute_change_notify(NewStatus, 0),
            Sit2 = NewStatus#player_status.sit,
            case Sit2#status_sit.sit_down =/= Sit#status_sit.sit_down 
                orelse NewStatus#player_status.hp =/= Status#player_status.hp 
                orelse NewStatus#player_status.mp =/= Status#player_status.mp 
                orelse Sit2#status_sit.sit_exp_time =/= Sit#status_sit.sit_exp_time
                orelse Sit2#status_sit.sit_llpt_time =/= Sit#status_sit.sit_llpt_time
                orelse Sit2#status_sit.sit_intimacy_time =/=Sit#status_sit.sit_intimacy_time of
                true -> {ok, hp_mp, NewStatus};
                false ->
                    {ok, NewStatus}
            end;
        false -> skip
    end;

%% 取消打坐
handle(13103, Status, sit_up) ->
    Sit = Status#player_status.sit,
    case Sit#status_sit.sit_down > 0 orelse Sit#status_sit.sit_role > 0 of
        true ->
            NewStatus = lib_sit:sit_up(Status),
            {ok, sit, NewStatus};
        false -> skip
    end;

%% 双修邀请
handle(13104, Status, PlayerId) ->
    case lib_sit:shuangxiu_invite(Status, PlayerId) of
        {fail, Res} ->
            {ok, BinData} = pt_131:write(13104, Res),
            lib_server_send:send_to_uid(Status#player_status.id, BinData);
        {ok, Player} ->
            {ok, BinData} = pt_131:write(13104, 1),
            lib_server_send:send_to_uid(Status#player_status.id, BinData),
            {ok, BinData2} = pt_131:write(13106, [1, Status#player_status.id, 0, Status#player_status.nickname]),
            lib_server_send:send_to_sid(Player#player_status_sit.sid, BinData2)
    end,
    {ok, Status};

%% 双修邀请回应
handle(13105, Status, [PlayerId, Flag]) ->
    case lib_player:get_player_info(PlayerId, lib_sit) of
        Player when is_record(Player, player_status_sit)->
            case Flag =:= 1 of
                false -> %% 拒绝
                    {ok, BinData} = pt_131:write(13105, [7, 0]),
                    lib_server_send:send_to_uid(Status#player_status.id, BinData),
                    {ok, BinData2} = pt_131:write(13106, [2, Status#player_status.id, 0, Status#player_status.nickname]),
                    lib_server_send:send_to_sid(Player#player_status_sit.sid, BinData2),
                    ok;
                true -> %% 接受
                    case lib_sit:shuangxiu_respond(Status, Player) of
                        {fail, Res} ->
                            {ok, BinData} = pt_131:write(13105, [Res, 0]),
                            lib_server_send:send_to_uid(Status#player_status.id, BinData),
                            ok;
                        {ok, NewStatus} ->
							Time_Left = 24*60*60 - Status#player_status.sit_time_today,
                            {ok, BinData} = pt_131:write(13105, [1, Time_Left]),
                            lib_server_send:send_to_uid(Status#player_status.id, BinData),
							{ok, BinData2} = pt_131:write(13106, [3, Status#player_status.id, Time_Left, Status#player_status.nickname]),
							lib_server_send:send_to_sid(Player#player_status_sit.sid, BinData2),
                            {ok, Bin} = pt_131:write(13107, [Player#player_status_sit.x, Player#player_status_sit.y, Player#player_status_sit.id, Player#player_status_sit.nickname, Status#player_status.id, Status#player_status.nickname]),
							lib_server_send:send_to_area_scene(Player#player_status_sit.scene, Player#player_status_sit.copy_id, Player#player_status_sit.x, Player#player_status_sit.y, Bin),
							{ok, NewStatus}
                    end
            end;
        _ -> %% 对方不在线，无法加入双修
            {ok, BinData} = pt_131:write(13105, [2, 0]),
            lib_server_send:send_to_uid(Status#player_status.id, BinData),
            ok
    end;

%% 离线挂机加速
handle(13108, Status, [UseType, Time]) ->
	Lv = Status#player_status.lv,
	XISHU = if
		Lv < 30 -> 40;
		Lv < 40 -> 18;
		Lv < 50 -> 14;
		true -> 10
	end,
	Cost_1 = (2000+2000*Lv)/XISHU + 100000,
	Time_Left = 24 * 60 * 60 - Status#player_status.sit_time_today,
	case Time_Left >= 60*60 of
		true ->
			case UseType of
				1 ->
					case (Status#player_status.coin+Status#player_status.bcoin) < Cost_1 of
						true ->
							{ok,DataBin} = pt_131:write(13108, [2, 0, 0]),
							lib_server_send:send_to_sid(Status#player_status.sid, DataBin);
						false ->
							%% 扣除铜币
							NewPlayerStatus_Step_1 = Status#player_status{sit_time_today = Status#player_status.sit_time_today + 60*60*Time},
							NewPlayerStatus = lib_goods_util:cost_money(NewPlayerStatus_Step_1, Cost_1, coin),
                            log:log_consume(offline_upspeed, coin, NewPlayerStatus_Step_1, NewPlayerStatus, ["offline_upspeed"]),
							Player_LV = NewPlayerStatus#player_status.lv,
							Exp = round(Player_LV * Player_LV / (Player_LV + 666) * 666 * 0.375 * 60 * 2),
							NewPlayerStatus_Exp = lib_player:add_exp(NewPlayerStatus, Exp),
							%% 更新用户信息_缓存
							%lib_player:update_player_info(NewPlayerStatus#player_status.id, NewPlayerStatus_Exp),
							{ok,DataBin} = pt_131:write(13108, [1, 24*60*60 - NewPlayerStatus_Exp#player_status.sit_time_today, Exp]),
							lib_server_send:send_to_sid(NewPlayerStatus_Exp#player_status.sid, DataBin),
							{ok, sit, NewPlayerStatus_Exp}
					end;
				2 ->
					CostGood = Cost_1/1000,
					case lib_goods_util:is_enough_money(Status, CostGood, gold) of
						true ->
							%% 扣除元宝
							NewPlayerStatus_Step_1 = Status#player_status{sit_time_today = Status#player_status.sit_time_today + 60*60*Time},
							NewPlayerStatus = lib_goods_util:cost_money(NewPlayerStatus_Step_1, CostGood, gold),
                            log:log_consume(offline_upspeed, gold, NewPlayerStatus_Step_1, NewPlayerStatus, ["offline_upspeed"]),
							Player_LV = NewPlayerStatus#player_status.lv,
							Exp = round(Player_LV * Player_LV / (Player_LV + 666) * 666 * 0.375 * 60 * 2),
							NewPlayerStatus_Exp = lib_player:add_exp(NewPlayerStatus, Exp),
							%% 更新用户信息_缓存
							%lib_player:update_player_info(NewPlayerStatus#player_status.id, NewPlayerStatus_Exp),
							{ok,DataBin} = pt_131:write(13108, [1, 24*60*60 - NewPlayerStatus_Exp#player_status.sit_time_today, Exp]),
							lib_server_send:send_to_sid(NewPlayerStatus_Exp#player_status.sid, DataBin),
							{ok, sit, NewPlayerStatus_Exp};
						false ->
							{ok,DataBin} = pt_131:write(13108, [3, 0, 0]),
							lib_server_send:send_to_sid(Status#player_status.sid, DataBin)
					end;
				_ ->
					{ok,DataBin} = pt_131:write(13108, [0, 0, 0]),
					lib_server_send:send_to_sid(Status#player_status.sid, DataBin)
			end;
		false ->
			{ok,DataBin} = pt_131:write(13108, [4, 0, 0]),
			lib_server_send:send_to_sid(Status#player_status.sid, DataBin)
	end;

%% 查询离线挂机信息
handle(13111, Status, query_offlineTime) ->
	Lv = Status#player_status.lv,
	%% 调用接口函数获取剩余离线时间
	Time1 = Status#player_status.offline_time, 
    Time = case Time1 > 12 of
               true -> 12;
               _ -> Time1
           end,
	Exp = Time*60*trunc(Lv*Lv*1.48),
	Offline_TB = util:ceil(Exp*1.25/Lv),
	Offline_YB = util:ceil(Exp/(2000*Lv)),
	{ok,DataBin} = pt_131:write(13111, [Time,Exp,Offline_TB,Offline_YB]),
	lib_server_send:send_to_sid(Status#player_status.sid, DataBin);

%% 兑换离线挂机经验
handle(13112, Status, [Type, GetTime]) ->
	NowTime = util:unixtime(),
	Lv = Status#player_status.lv,
	%%调用接口函数获取剩余离线时间
	Time1 = Status#player_status.offline_time, 
    Time = case Time1 > 12 of
               true -> 12;
               _ -> Time1
           end, 
	if
		Time < GetTime orelse 0 >= GetTime->
			Result=5,
			GetExp = 0,
			Reply = ok;
		true->
			Exp = GetTime*60*trunc(Lv*Lv*1.48),
			case Type of
				1->
					Result=1,
					GetExp = trunc(Exp*25/100),
					NStatus = Status#player_status{offline_time=0, last_logout_time=NowTime},
					lib_player:update_player_login_offline_time(Status#player_status.id, 0, NowTime),
                    %% 日志
                    lib_task_cumulate:exp_log(Status#player_status.id, 999, util:unixtime(), Status#player_status.lv, GetTime, GetExp, no),
					%%给玩家添加经验
					Reply = lib_player:add_exp(NStatus, GetExp);
				2->
					NeedTb = util:ceil(Exp*1.25/Lv),
					if
						NeedTb > (Status#player_status.coin + Status#player_status.bcoin)->
							Result=2,
							GetExp = 0,
							Reply = ok;
						true->
							Money = Status#player_status.bcoin - NeedTb,
							if
								Money>=0->
									%%扣除金钱
									NewPlayer_Status1 = lib_goods_util:cost_money(Status, NeedTb, bcoin),
									% 写消费日志
									About = lists:concat(["get sit offline exp lv=",Lv," time=",GetTime]),
									log:log_consume(get_sit_offline_exp, bcoin, Status, NewPlayer_Status1, About);
								true->
									GapMoney = NeedTb - Status#player_status.bcoin,
									%%扣除绑定金钱
									NewPlayer_Status0 = lib_goods_util:cost_money(Status, Status#player_status.bcoin, bcoin),
									% 写消费日志
									About0 = lists:concat(["get sit offline exp lv=",Lv," time=",GetTime]),
									log:log_consume(get_sit_offline_exp, bcoin, Status, NewPlayer_Status0, About0),
									%%扣除非绑定金钱
									NewPlayer_Status1 = lib_goods_util:cost_money(NewPlayer_Status0, GapMoney, coin),
									% 写消费日志
									About = lists:concat(["get sit offline exp lv=",Lv," time=",GetTime]),
									log:log_consume(get_sit_offline_exp, coin, NewPlayer_Status0, NewPlayer_Status1, About)
							end,
							%%清空对应时间
							NStatus = NewPlayer_Status1#player_status{offline_time = 0,last_logout_time = NowTime},
							lib_player:update_player_login_offline_time(NStatus#player_status.id, 0, NowTime),
							Result=1,
							GetExp = trunc(Exp*50/100),
                            %% 日志
                            lib_task_cumulate:exp_log(Status#player_status.id, 999, util:unixtime(), Status#player_status.lv, GetTime, GetExp, coin),
							%% 给玩家添加经验
							Reply = lib_player:add_exp(NStatus, GetExp)
					end;
				3->
					NeedYb = util:ceil(Exp/(2000*Lv)),
					if
						%%检测元宝
						NeedYb>Status#player_status.gold ->
							Result=3,
							GetExp = 0,
							Reply = ok;
						true->
							%% 扣除元宝
							NewPlayerStatus = lib_goods_util:cost_money(Status, NeedYb, gold),
							About = lists:concat(["get sit offline YB exp lv=",Lv," time=",GetTime]),
							log:log_consume(get_sit_offline_exp, gold, Status, NewPlayerStatus, About),
							%%清空对应时间
							NStatus = NewPlayerStatus#player_status{offline_time = 0, last_logout_time=NowTime},
							lib_player:update_player_login_offline_time(NewPlayerStatus#player_status.id, 0, NowTime),
							Result=1,
							GetExp = trunc(Exp*100/100),
                            %% 日志
                            lib_task_cumulate:exp_log(Status#player_status.id, 999, util:unixtime(), Status#player_status.lv, GetTime, GetExp, gold),
							%% 给玩家添加经验
							Reply = lib_player:add_exp(NStatus, GetExp)
					end;
				_->
					Result=4,
					GetExp = 0,
					Reply = ok
			end
	end,
	{ok,DataBin} = pt_131:write(13112, [Result,GetExp]),
	lib_server_send:send_to_sid(Status#player_status.sid, DataBin),
	case Result of
		1->
			handle(13111, Reply, query_offlineTime),
			lib_player:send_attribute_change_notify(Reply, 5),
			{ok,Reply};
		_-> void
	end;

handle(13113, Status, []) ->
	NowTime = util:unixtime(),
	lib_player:update_player_login_last_logout_time(Status#player_status.id,NowTime),
	New_Status = Status#player_status{last_logout_time=NowTime},
	{ok,New_Status};

%% 元魂珠party
handle(13114, UniteStatus, _) ->
    case data_sit:is_party_time() of
	false ->
	    Flag = 0,
	    Left = 0;
	true ->
	    [_,End] = data_sit:get_open_unixtime(),
	    Now = util:unixtime(),
	    _Left = End - Now,
	    {Flag,Left} = case _Left > 0 of
		       true -> {1,_Left};
		       false -> {0,0}
		   end
    end,
    {ok,DataBin} = pt_131:write(13114, [Flag, Left]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, DataBin);

handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_sit no match", []),
    {error, "pp_sit no match"}.

