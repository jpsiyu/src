%%%--------------------------------------
%%% @Module  : pt_350
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.9
%%% @Description: 成就
%%%--------------------------------------

-module(pp_achieve).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("achieve.hrl").

%% 取成就列表
handle(35011, PS, get_info) ->
	BinData = mod_achieve:get_index_data(PS#player_status.achieve, PS#player_status.id),
	{ok, Bin} = pt_350:write(35011, BinData),
	lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 领取大类成长等级奖励
handle(35012, PS, AchieveType) ->
	case mod_achieve:fetch_award_by_type(PS, AchieveType) of
		{ok} ->
			{ok, BinData} = pt_350:write(35012, 1),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		{error, ErrorCode} ->
			{ok, BinData} = pt_350:write(35012, ErrorCode),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	end;

%% 领取成就奖励
handle(35021, PS, AchieveId) ->
	case mod_achieve:fetch_achieve_award(PS#player_status.achieve, PS#player_status.id, AchieveId) of
		{ok, TotalScore, Achieve, MaxLevel, Score} ->
			AddScore = Achieve#base_achieve.score,

			%% 增加绑定元宝,气血上限
			NewPS = PS#player_status{bgold = PS#player_status.bgold + AddScore, hp_lim = PS#player_status.hp_lim + AddScore},
			lib_player:update_player_high(NewPS),

			%% 获得绑定元宝日志
			log:log_produce(achieve, bgold, PS, NewPS, lists:concat(["AchieveId : ", AchieveId])),

            %% 发送属性变化通知
            lib_player:send_attribute_change_notify(NewPS, 4),

			{ok, BinData} = pt_350:write(35021, [1, TotalScore, MaxLevel, Achieve#base_achieve.type, Score]),
    		lib_server_send:send_to_sid(PS#player_status.sid, BinData),
			{ok, NewPS};
		{error, ErrorCode} ->
			{ok, BinData} = pt_350:write(35021, [ErrorCode, 0, 0, 0, 0]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	end;

%% 成就对比
handle(35022, PS, PlayerId) ->
	case mod_achieve:compare_data(PS#player_status.achieve, PS#player_status.id, PlayerId) of
		{ok, [PlayerScore, StatList]} ->
			{ok, BinData} = pt_350:write(35022, [1, PlayerScore, StatList]),
    		lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		{error, ErrorCode} ->
			{ok, BinData} = pt_350:write(35022, [ErrorCode, 0, []]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	end;

%% 错误处理
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_achieve no match", []),
	{error, "pp_achieve no match"}.