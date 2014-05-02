%% --------------------------------------------------------
%% @Module:           |pp_guild_server
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-05
%% @Description:      |帮派处理借口包括帮派(补)
%% --------------------------------------------------------

-module(pp_guild_server).
-export([handle/4, handle/3]). 
-include("common.hrl").
-include("qlc.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("guild.hrl").
-include("buff.hrl").
%%=========================================================================
%% 接口函数
%%=========================================================================

%% 整合入口
handle(check, CMD, PlayerStatus, Info) -> 
	%% 暂时没有任何限制
	handle(CMD, PlayerStatus, Info).

%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 						帮派基础功能
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 查询自己的帮派神兽技能  
%% -----------------------------------------------------------------
handle(40401, PlayerStatus, _) ->
	[{LastSkillType, LastSKillLevel}, List] = lib_guild_ga:get_ga_skill(PlayerStatus),
	{_, _, _, {NextSkillType, NextSKillLevel}} = data_guild_ga_stage:get_skill_info(LastSkillType, LastSKillLevel),
	GuildInfo = PlayerStatus#player_status.guild,
	_GaStage = case GuildInfo#status_guild.guild_ga_stage > 10 orelse GuildInfo#status_guild.guild_ga_stage < 0 of
		  true ->
			  1;
		  false ->
			  GuildInfo#status_guild.guild_ga_stage
	end,
%% 	{_, _, DailyTimes, _} = data_guild_ga_stage:get_stage_info(GaStage),
	DailyTimes = lib_guild_ga:count_learn_times(GuildInfo#status_guild.guild_lv, GuildInfo#status_guild.guild_id),
	NowTimes = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 4040001),
	{ok, BinData} = pt_404:write(40401, [NowTimes, DailyTimes, NextSkillType, NextSKillLevel, List]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
	ok;

%% -----------------------------------------------------------------
%% 升级自己的帮派神兽技能  
%% -----------------------------------------------------------------
handle(40402, PlayerStatus, _) ->
	GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
	case GuildId =:= 0 of
		true ->
		    ok;
		false ->
			{Res, NewPs1} = lib_guild_ga:ga_skill_up(PlayerStatus),
			{ok, BinData} = pt_404:write(40402, [Res]),
			lib_server_send:send_one(NewPs1#player_status.socket, BinData),
			{ok, NewPs1}
	end;

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
handle(_Cmd, _Status, _Data) ->
    ?ERR("pp_guild no match", []),
    {error, "pp_guild no match"}.
