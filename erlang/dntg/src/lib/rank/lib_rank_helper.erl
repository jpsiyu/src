%%%--------------------------------------
%%% @Module  : lib_rank_helper
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.13
%%% @Description :  排行榜处理其他
%%%--------------------------------------

-module(lib_rank_helper).
-include("server.hrl").
-include("rank.hrl").
-include("buff.hrl").
-export([
	world_add_buff/1,
	world_remove_buff/1,
	get_world_percent/1,
	get_flower_rank_name_and_value/3
]).

%% 显示世界等级经验加成buff图标
world_add_buff(PS) ->
	case private_show_worldlevel_buff(PS#player_status.lv, PS#player_status.world_level) of
		{true, WorldLevel} ->
			[WorldPercent, VipPercent] = private_worldlevel_exp_addition(PS, WorldLevel),
			WorldPercent2 = round(WorldPercent * 100),
			VipPercent2 = round(VipPercent * 100),
			{ok, Bin} = pt_130:write(13080, [1, WorldLevel, WorldPercent2, VipPercent2]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		_ ->
			skip
	end.

%% 移除世界等级经验加成buff图标
world_remove_buff(PS) ->
	case private_show_worldlevel_buff(PS#player_status.lv, PS#player_status.world_level) of
		{true, WorldLevel} ->
			[WorldPercent, VipPercent] = private_worldlevel_exp_addition(PS, WorldLevel),
			WorldPercent2 = round(WorldPercent * 100),
			VipPercent2 = round(VipPercent * 100),
			{ok, Bin} = pt_130:write(13080, [1, WorldLevel, WorldPercent2, VipPercent2]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin);
		_ ->
			{ok, Bin} = pt_130:write(13080, [0, 0, 0, 0]),
			lib_server_send:send_to_sid(PS#player_status.sid, Bin)
	end.

%% 获取世界等级经验加成值
get_world_percent(PS) ->
	case private_show_worldlevel_buff(PS#player_status.lv, PS#player_status.world_level) of
		{true, WorldLevel} ->
			[Add1, Add2] = private_worldlevel_exp_addition(PS, WorldLevel),
			Add1 + Add2;
		_ ->
			0
	end.

%% 获得鲜花榜魅力值前N的玩家的角色名和魅力值
%% @param int FlowerSex		性别：1男2女
%% @param int FlowerValue	魅力值达标要求数值
%% @param int FlowerLimit	欲获得记录数
get_flower_rank_name_and_value(FlowerSex, FlowerValue, FlowerLimit) ->
	RankType = case FlowerSex of
		1 -> ?RK_CHARM_DAY_HUHUA;
		_ -> ?RK_CHARM_DAY_FLOWER
	end,
	case lib_rank:pp_get_rank(RankType) of
		[] ->
			[];
		List ->
			[TargetList, _] = 
			lists:foldl(fun(Row, [TmpList, TmpNum]) -> 
				[_Id, Name, _Sex, _Career, _Realm, _Guild, Value, _Image] = Row,
				case Value >= FlowerValue andalso TmpNum < FlowerLimit of
					true ->
						[[[Name, Value] | TmpList], TmpNum + 1];
					_ ->
						[TmpList, TmpNum]
				end
			end, [[], 0], List),
			lists:reverse(TargetList)
	end.

%% 是否需要显示世界等级经验加成buff图标
private_show_worldlevel_buff(PlayerLevel, PlayerWorldLevel) ->
	{WorldLevel, _} = PlayerWorldLevel,

	%% 玩家等级大于等于40级
	NeedPlayerLevel = 40,
	%% 世界等级大于等于玩家等级5级
	NeedSpaceLevel = 5,
	case PlayerLevel >= NeedPlayerLevel andalso WorldLevel - PlayerLevel >= NeedSpaceLevel of
		true -> {true, WorldLevel};
		_ -> false
	end.

%% 获取世界等级经验加成值
%% @return [世界经验等级加成，vip加成]
private_worldlevel_exp_addition(PS, WorldLevel) ->
	%% vip等级加成系数
	VipPercent = data_vip_new:get_exp_add(PS#player_status.vip#status_vip.growth_lv),
	LevelValue = (WorldLevel - PS#player_status.lv - 4) * 0.125,
	VipValue = (WorldLevel - PS#player_status.lv - 4) * VipPercent,
	NewLevelValue = case LevelValue < 0 of
		true -> 0;
		_ -> LevelValue
	end,
	NewVipValue = case VipValue < 0 of
		true -> 0;
		_ -> VipValue
	end,
	[NewLevelValue, NewVipValue].
