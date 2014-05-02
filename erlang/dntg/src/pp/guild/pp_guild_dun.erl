%%%------------------------------------
%%% @Module  : pp_guild_dun
%%% @Author  : hekai
%%% @Description: 
%%%------------------------------------

-module(pp_guild_dun).
-export([handle/3]).
-include("server.hrl").
-include("common.hrl").
-include("guild_dun.hrl").


%% 设置帮派活动开启时间
handle(40501, PS, [Week, Time]) ->
	lib_guild_dun:booking_dun(PS, Week, Time),
	ok;

%% 进入副本
handle(40503, PS, _) ->
	[PlayerId, GuildId]	= lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:enter_dun(PlayerId, PS#player_status.lv, PS#player_status.nickname, GuildId);

%% 退出副本
handle(40504, PS, _) ->
	[PlayerId, GuildId]	= lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:exit_dun(PlayerId, GuildId);

%% 关卡三怪物列表
handle(40505, PS, _) ->
	[PlayerId, GuildId]	= lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:dun_3_animal(PlayerId, GuildId);	

%% 关卡三答题
handle(40507, PS, [Num]) ->
	[PlayerId, GuildId]	= lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:answer_question(Num,PlayerId,GuildId);

%% 关卡三信息
handle(40508, PS, _) ->
	[PlayerId, GuildId]	= lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:dun_panel(3, GuildId, PlayerId);	

%% 关卡一信息
handle(40511, PS, _) ->
	[PlayerId, GuildId]	= lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:dun_panel(1, GuildId, PlayerId);	

%% 关卡一尸体列表
handle(40512, PS, _) ->
	[_PlayerId, GuildId] = lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:dun_1_die_list(GuildId);	

%% 关卡一提交完成
handle(40513, PS, _) ->
	[PlayerId, GuildId] = lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:finish_all_jump(PlayerId, GuildId);	

%% 关卡一是否中陷阱
handle(40514, PS, [X, Y]) ->
	[PlayerId, GuildId] = lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:jump_grid(PlayerId, PS#player_status.nickname, PS#player_status.lv, GuildId, X, Y);	

%% 关卡二信息
handle(40516, PS, _) ->
	[PlayerId, GuildId]	= lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:dun_panel(2, GuildId, PlayerId);	

%% 关卡二提交完成
handle(40517, PS, _) ->
	[PlayerId, GuildId] = lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:dun2_finish_escape(PlayerId, GuildId);	

%% 副本是否正在开启
handle(40519, PS, _) ->
	[PlayerId, GuildId] = lib_guild_dun:get_id_player_guild(PS), 
	mod_guild_dun:dun_is_open(PlayerId, GuildId);

%% 查询副本设置状态与时间
handle(40520, PS, _) ->
	[PlayerId, GuildId] = lib_guild_dun:get_id_player_guild(PS), 
	lib_guild_dun:get_start_time(PlayerId, GuildId);
handle(_Cmd, _Status, _Data) ->
    ?ERR("pp_guild_dun no match", []),
    {error, "pp_guild_dun no match"}.



