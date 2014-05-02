%%------------------------------------------------------------------------------
%% @Module  : lib_activity_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2013.3.5
%% @Description: 活动副本逻辑
%%------------------------------------------------------------------------------


-module(lib_activity_dungeon).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").


%% 公共函数：外部模块调用.
-export([
		 kill_npc/4,   %% 杀死怪物事件.
		 get_score/1   %% 得到积分.
]).


%% --------------------------------- 公共函数 ----------------------------------


%% 杀怪事件.
kill_npc([KillMonId|_OtherIdList], _MonAutoId, _SceneId, State) ->
	%1.检测增加积分.
	check_add_score(KillMonId, State),
	State.

%% 得到积分.
get_score(PlayerId) ->
	NewTotalScore = 
		case get(PlayerId) of
			undefined ->
				0;
			TotalScore ->
				TotalScore
		end,
	{ok, BinData} = pt_610:write(61060, [0, NewTotalScore]),
	lib_server_send:send_to_uid(PlayerId, BinData).

%% 检测增加积分.
check_add_score(MonId, State) ->
	Score = data_activity_dun_config:get_mon_score(MonId),
	case Score of
		undefined ->
			skip;
		_ ->
			%1.增加积分.
			RoleList = State#dungeon_state.role_list,
			[add_score(Role#dungeon_player.id, 
					   Role#dungeon_player.pid, 
					   Score) || Role <- RoleList]
	end.

%% 增加积分.
add_score(PlayerId, PlayerPid, Score) ->
	%1.计算总积分.
	NewTotalScore = 
		case get(PlayerId) of
			undefined ->
				Score;
			TotalScore ->
				TotalScore + Score
		end,
	put(PlayerId, NewTotalScore),

	%2.发给玩家副本积分.
	if Score > 0 ->
			gen_server:cast(PlayerPid, {'set_data', [{add_fbpt, Score}]});
	    true ->
			skip
	end,

	{ok, BinData} = pt_610:write(61060, [Score, NewTotalScore]),
	lib_server_send:send_to_uid(PlayerId, BinData).

