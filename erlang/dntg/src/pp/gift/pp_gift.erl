%% ---------------------------------------------------------
%% Author:  HHL
%% Email:   
%% Created: 2014.4.28
%% Description: 在线奖励
%% --------------------------------------------------------
-module(pp_gift).
-export([handle/3, refresh/0]).
-include("gift.hrl").
-include("server.hrl").
-include("gift_online.hrl").

%% 获取已经获取的等级礼包列表
%% handle(36001, PS, _) ->
%% 	case get(handle_36001) of
%% 		undefined ->
%% 		   	private_handle_36001(PS);
%% 		Time ->
%% 			case Time + 10 > util:unixtime() of
%% 				true ->
%% 					skip;
%% 				_ ->
%% 					private_handle_36001(PS)
%% 			end
%% 	end;

%% %% 查询在线倒计时礼包数据 
%% handle(36002, PS, _) -> 
%% 	case lib_gift_online:get_online_award_info(PS) of
%% 	   {no} ->
%% 		    skip;
%% 	   {next, [GiftId, NeedTime, [GetNum, LastOffline, NeedTime]]} ->
%% 		    NowTime = util:unixtime(),
%% 		    CheckTime01 = util:unixtime(?SP_ONLINE_START_AT),
%% 		    CheckTime02 = util:unixtime(?SP_ONLINE_END_AT),
%% 			%% 看是否有下一个礼包
%% 			[Type, NowNum] = case NowTime > CheckTime01 andalso NowTime < CheckTime02 of
%% 					   true ->
%% 						   [1, GetNum+1];
%% 					   _ ->
%% 						   [0, 0]				  
%% 				   end,
%% %%  			io:format("NeedTime 1 ~p ~p ", [GiftId, NeedTime]),
%% 		    {ok, BinData} = pt_360:write(36002, [GiftId, NeedTime, Type, NowNum - 1]),
%% 			lib_server_send:send_to_sid(PS#player_status.sid, BinData),
%% 		    NewPS = PS#player_status{online_award = [GetNum, LastOffline, NeedTime]},
%% 		    {ok, NewPS};
%% 		_ ->
%% 			skip
%% 	end;

%% 领取在线倒计时礼包奖励				
%% handle(36003, PS, _) ->
%%    case lib_gift_online:fetch_online_award(PS) of
%% 		{[Result, GiftId, Needtime, Type, Num], NewPS} -> 
%% %%  			io:format("NeedTime 2 ~p ~p ", [GiftId, Needtime]),
%% 			{ok, BinData} = pt_360:write(36003, [Result, GiftId, Needtime, Type, Num - 1]),
%% 			lib_server_send:send_to_sid(PS#player_status.sid, BinData),
%% 			{ok, NewPS};
%% 		_ ->
%% 			skip
%% 	end;

%% %% [限时回馈礼包] 打开面板请求需要的数据
%% handle(36006, PS, _) ->
%% 	L = lib_gift_recharge:get_data(PS),
%% 	{ok, BinData} = pt_pt_360:write(36006, L),
%% 	lib_server_send:send_to_sid(PS#player_status.sid, BinData);

%% %% [限时回馈礼包] 领取礼包
%% handle(36007, PS, GiftId) ->
%% 	case lib_gift_recharge:fetch_gift(PS, GiftId) of
%% 		{ok, NewPS} ->
%% 			{ok, BinData} = pt_360:write(36007, 1),
%% 			lib_server_send:send_to_sid(PS#player_status.sid, BinData),
%% 			{ok, NewPS};
%% 		{error, ErrorCode} ->
%% 			{ok, BinData} = pt_360:write(36007, ErrorCode),
%% 			lib_server_send:send_to_sid(PS#player_status.sid, BinData);
%% 		_ ->
%% 			skip
%% 	end;
%% 
%% %% 取活动礼包列表
%% handle(31000, PlayerStatus, _) ->
%%     GiftList = lib_activity_gift:get_all(),
%%     {ok, BinData} = pt_310:write(31000, GiftList),
%%     lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
%% 
%% %% 活动礼包领取
%% handle(31002, PlayerStatus, [GiftId, Card]) ->
%%     G = PlayerStatus#player_status.goods,
%%     case gen:call(G#status_goods.goods_pid, '$gen_call', {'recv_gift', PlayerStatus, GiftId, Card}) of
%%         {ok, [NewPlayerStatus, Res]} ->
%%             {ok, BinData} = pt_310:write(31002, [Res, GiftId]),
%%             lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
%%             {ok, NewPlayerStatus};
%%         {'EXIT', _R} ->
%%             util:errlog("handle 31002 error ~p", [_R])
%%     end;
%% 
%% 取开服时间
handle(31100, PlayerStatus, _) ->
    Otime = util:get_open_time(),
    {ok, BinData} = pt_311:write(31100, Otime),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%% 
%% 
%% %% 100服活动 打开面板
%% handle(31020, PS, _) ->
%% 	lib_activity_100servers:get_data(PS);
%% 
%% %% 100服活动 领取奖励
%% handle(31021, PS, _) ->
%% 	case lib_activity_100servers:fetch_award(PS) of
%% 		{ok, GiftId} ->
%% 			{ok, BinData} = pt_310:write(31021, [GiftId, 1]),
%% 			lib_server_send:send_to_sid(PS#player_status.sid, BinData);
%% 		{error, Error} ->
%% 			{ok, BinData} = pt_310:write(31021, [0, Error]),
%% 			lib_server_send:send_to_sid(PS#player_status.sid, BinData)
%% 	end;


%%==============================================大闹天空=====================================
handle(36008, PS, _) ->
    [MinLv, MaxLv] = data_gift_config:get_config(lv_qj),
    if
        PS#player_status.lv < MinLv orelse PS#player_status.lv > MaxLv ->
            {ok, BinData} = pt_360:write(36008, [2, 0, []]),
            lib_server_send:send_to_sid(PS#player_status.sid, BinData);
        true -> 
            Record = lib_gift_online:get_online_gift_info(PS),
            OnlineTime = lib_gift_online:fetch_online_gift_info(Record, online_time),
            GiftList = lib_gift_online:fetch_online_gift_info(Record, gift_list),
            if
                OnlineTime =:= type_error orelse GiftList =:= type_error ->
                    {ok, BinData} = pt_360:write(36008, [0, 0, []]);
                true ->
                    {ok, BinData} = pt_360:write(36008, [1, OnlineTime, GiftList])
            end,
            lib_server_send:send_to_sid(PS#player_status.sid, BinData),
            {ok, PS#player_status{online_award = Record}}
    end;
    

%% 领取在线礼包
handle(36009, PS, [TypeId]) ->
    if
        TypeId > 0 andalso TypeId =< 13 ->
            case lib_gift_online:get_online_gift_op(PS, TypeId) of
                {ok, Code, NewPS} ->
                    pp_goods:handle(15010, NewPS, 4),
                    if
                        TypeId =:= 13 ->
                            handle(36008, NewPS, []),
                            {ok, BinData} = pt_360:write(36009, [Code, TypeId, 2]);
                        true ->
                            {ok, BinData} = pt_360:write(36009, [Code, TypeId, 2])
                    end,
                    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
                    {ok, NewPS};
                {fail, Code} -> 
                    {ok, BinData} = pt_360:write(36009, [Code, TypeId, 0]),
                    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
            end;
        true ->
            {ok, BinData} = pt_360:write(36009, [3, 0, 0]),
            lib_server_send:send_to_sid(PS#player_status.sid, BinData)
    end;

handle(Cmd, _PlayerStatus, _R) ->
    util:errlog("pp_gift handle ~p error~n", [Cmd]).



%%===========================================私有方法=======================================================
%% 活动礼包更新通知
%% 暂时没什么用
refresh() ->
    lib_activity_gift:init(),
    {ok, BinData} = pt_310:write(31001, 1),
    lib_server_send:send_to_all(BinData).

%% private_handle_36001(PS) ->
%% 	List = lib_gift:get_level_gift_list(PS#player_status.id),
%% 	put(handle_36001, util:unixtime()),
%%     {ok, BinData} = pt_360:write(36001, List),
%%     lib_server_send:send_one(PS#player_status.socket, BinData).
