%%%--------------------------------------
%%% @Module  : pp_festival
%%% @Created : 
%%% @Description: 节日活动
%%%--------------------------------------

-module(pp_festival).
-include("server.hrl").
-include("unite.hrl").
-include("common.hrl").
-include("activity.hrl").
-export([handle/3, handle/4]).
	
%% 节日充值活动:类型1(获取基本信息)
handle(31500, PS, [Type]) ->
	Time0 = util:get_today_midnight(),
	Recharge1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, Time0, Time0 + 24 * 60 * 60),
	Recharge2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, Time0, Time0 + 24 * 60 * 60),
	TodayRecharge = Recharge1 + Recharge2,	
	case Type of
		1 ->
			GGlist = lib_activity_festival:get_base_info(PS#player_status.id),
			{ok, Bin} = pt_315:write(31500, [1, TodayRecharge, GGlist]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		_->
			{ok, Bin} = pt_315:write(31500, [0, TodayRecharge, []]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin)
	end,
	ok;

%% 节日充值活动:类型1(领取指定礼包)
handle(31501, PS, [Type, TimeS, GiftId]) ->
	Res = case Type of
			  1 ->
				  lib_activity_festival:send_fr_gift(PS, TimeS, GiftId);
			  _ ->
				  0
		  end,
	{ok, Bin} = pt_315:write(31501, [Res]),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin),
	{ok, PS};


%%===============================
%% 以下为圣诞祝福活动
%%===============================

%% 收到贺卡列表 
handle(31506, PS, _) ->
	CardList1 = lib_festival_card:get_festival_cardlist(PS),
	F = fun(Fcard) ->
			[Fcard#festivial_card.id, Fcard#festivial_card.is_read, Fcard#festivial_card.sender_id,
			  Fcard#festivial_card.sender_name,Fcard#festivial_card.animation_id, Fcard#festivial_card.gift_id,
			  Fcard#festivial_card.wish_msg,Fcard#festivial_card.send_time]
		end,
	CardList2 = lists:map(F, CardList1),
	{ok, Bin} = pt_315:write(31506, [length(CardList2), CardList2]),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 发送贺卡
handle(31507, PS, [ReceiveName, AnimationId, GiftId, WishMsg]) ->
	{Result, NewPS} = lib_festival_card:send_festivial_card(PS, [ReceiveName, AnimationId, GiftId, WishMsg]),
	{ok, Bin} = pt_315:write(31507, [Result]),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin),
	{ok, NewPS};

%% 阅读贺卡
handle(31508, PS, [CardId]) ->
	Result = lib_festival_card:read_festivial_card(PS#player_status.id, CardId),
	case Result of
		ok -> ErrorCode = 1;
		{error, ErrorCode} -> skip
	end,
%%	handle(31506, PS, []),
	{ok, Bin} = pt_315:write(31508, [ErrorCode]),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 删除贺卡
handle(31509, PS, [CardId]) ->
	lib_festival_card:delete_festivial_card(PS#player_status.id, CardId),
	{ok, Bin} = pt_315:write(31509, [1]),
	handle(31506, PS, []),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 收取礼物
handle(31510, PS, [CardId]) ->
	Result = lib_festival_card:recv_festivial_card_gift(PS, CardId),
	case Result of
		{ok, GiftId} -> 
			ErrorCode = 1,
			lib_player:refresh_client(PS#player_status.id, 2);
		{error, ErrorCode} -> GiftId =0, skip
	end,
	{ok, Bin} = pt_315:write(31510, [ErrorCode, GiftId]),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 单笔充值礼包
handle(31530, PS, _) ->
    %% GiftList = [{额度,礼包ID},...]
    GiftList = lib_activity_festival:get_single_recharge_gift_list(PS#player_status.id),
    [_, End] = data_recharge_award:get_single_recharge_award_time(),
    Now = util:unixtime(),
    _RemainTime = End - Now,
    RemainTime = case _RemainTime > 0 of
		     true -> _RemainTime;
		     false -> 0
		 end,
    {ok, Bin} = pt_315:write(31530, [GiftList, RemainTime]),
    lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 领取单笔充值礼包
handle(31531, PS, [GiftId]) ->
    Result = case lib_activity_festival:get_single_recharge_gift(PS,GiftId) of
		 {false, Error} -> Error;
		 true -> 1
	     end,
    {ok, Bin} = pt_315:write(31531, [Result, GiftId]),
    lib_server_send:send_to_sid(PS#player_status.sid, Bin);
    
%% 错误处理
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_activity_daily no match", []),
	{error, "pp_activity_daily no match"}.

%% 获取是否显示跨服鲜花榜图标
handle(unite, 31511, UniteStatus, _) ->
	Res = lib_activity_festival:kf_flower_time_check(),
	{ok, Bin} = pt_315:write(31511, [Res]),
%% 	io:format("Res ~p ~n", [Res]),
%% 	lib_unite_send:send_to_uid(UniteStatus#player_status.id, Bin);
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, Bin);

%% 获取跨服鲜花榜数据
handle(unite, 31512, UniteStatus, [SexX, Type]) ->
	Sex = case SexX of
			  0 ->
				  2;
			  1 ->
				  1
		  end,
	[Res, _, List] = lib_activity_festival:kf_flower_info_show(Sex, Type),
	{ok, Bin} = pt_315:write(31512, [Res, SexX, List]),
  	lib_activity_festival:kf_flower_info_send(0),
%% 	io:format("~nok, Bin ~p ~p ~p~n" , [Res, SexX, List]),
%% 	lib_unite_send:send_to_uid(UniteStatus#player_status.id, Bin);
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, Bin);

%%===============================
%% 以下为元宵放花灯活动
%%===============================

%% 元宵节花灯列表
handle(unite, 31513, UniteStatus, _) ->
	mod_activity_festival:send_lamp_to_player(UniteStatus#unite_status.id);

%% 元宵节花灯详细
handle(unite, 31514, UniteStatus, [LampId]) when is_integer(LampId) ->
	mod_activity_festival:lamp_info(UniteStatus#unite_status.id, LampId);	

%% 燃放元宵节花灯
handle(unite, 31515, UniteStatus, [LampType])
	when (is_integer(LampType) andalso LampType=<3 andalso  LampType>=1)->
	mod_activity_festival:fire_lamp(UniteStatus, LampType);

%% 邀请好友为花灯送祝福
handle(unite, 31516, UniteStatus, [FriendName, LampId]) when is_integer(LampId) ->
	mod_activity_festival:invite_wish_lamp(UniteStatus#unite_status.id, FriendName, LampId);

%% 花灯送祝福记录
handle(unite, 31517, UniteStatus, [LampId]) when is_integer(LampId)->
	mod_activity_festival:lamp_bewish_log(UniteStatus#unite_status.id, LampId);

%% 为花灯送祝福 
handle(unite, 31518, UniteStatus, [LampId]) when is_integer(LampId)->
	mod_activity_festival:wish_for_lamp(UniteStatus#unite_status.id, UniteStatus#unite_status.name, LampId);

%% 收获花灯 
handle(unite, 31519, UniteStatus, [LampId]) when is_integer(LampId)->
	mod_activity_festival:gain_lamp(UniteStatus#unite_status.id, LampId);

%% 错误处理
handle(_, _Cmd, _Status, _Data) ->
    ?DEBUG("pp_activity_daily 4 no match", []),
	{error, "pp_activity_daily 4 no match"}.
