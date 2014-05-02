%%%--------------------------------------
%%% @Module  : pp_target
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.2
%%% @Description: 目标
%%%--------------------------------------

-module(pp_target).
-include("server.hrl").
-include("common.hrl").
-include("target.hrl").
-export([handle/3]).

%% 获取目标数据
handle(34101, PS, get_info) ->
	lib_target:refresh_client(PS);

%% 领取奖励
handle(34102, PS, TargetId) ->
	case mod_target:fetch_gift_award(PS#player_status.status_target, PS, TargetId) of
		{ok, NewPS, GiftId} ->
			{ok, BinData} = pt_341:write(34102, [TargetId, GiftId, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData),
			{ok, NewPS};
		{error, ErrorCode} ->
			{ok, BinData} = pt_341:write(34102, [TargetId, 0, ErrorCode]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	end;

%% 领取达到指定等级后弹出来的小窗奖励
%% 有宠物，好友，坐骑奖励
handle(34106, PS, GiftId) ->
	if
		is_integer(GiftId) ->
			%% 检查是否可领取
			case lib_target:check_level_award(PS, GiftId) of
				{ok, endaction} ->
					{ok, BinData} = pt_341:write(34106, [GiftId, 1]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData);

				%% 检查通过，下面继续领取礼包操作
				{ok, fetchgift} ->
					G = PS#player_status.goods,
					case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
						{ok, [ok, NewPS]} ->
							{ok, BinData} = pt_341:write(34106, [GiftId, 1]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData),
							lib_gift:trigger_finish(PS#player_status.id, GiftId),
							{ok, NewPS};
						{ok, [error, ErrorCode]} ->
							{ok, BinData} = pt_341:write(34106, [GiftId, ErrorCode]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData)
					end;

				{error, ErrorCode} ->
					{ok, BinData} = pt_341:write(34106, [GiftId, ErrorCode]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			end;

		true ->
			{ok, BinData} = pt_341:write(34106, [GiftId, 2]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	end;

%% 错误处理
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_target no match", []),
	{error, "pp_target no match"}.
