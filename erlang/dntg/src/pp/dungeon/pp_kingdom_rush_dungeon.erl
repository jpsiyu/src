%%------------------------------------------------------------------------------
%% @Module  : pp_kingdom_rush_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.10.18
%% @Description: 皇家守卫军塔防副本协议处理
%%------------------------------------------------------------------------------


-module(pp_kingdom_rush_dungeon).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("dungeon.hrl").


%% 塔防副本—设置波数.
handle(61300, Status, Level) ->
    DungeonType = lib_dungeon:get_dungeon_type(Status#player_status.scene),	
    case DungeonType of
        ?DUNGEON_TYPE_KINGDOM_RUSH ->
			lib_kingdom_rush_dungeon:set_level(Status, Level);
        ?DUNGEON_TYPE_MULTI_KING ->
			lib_multi_king_dungeon:set_level(Status, Level);
		_ ->
			skip
	end;

%% 塔防副本—获取波数.
handle(61301, Status, _) ->
    DungeonType = lib_dungeon:get_dungeon_type(Status#player_status.scene),
    case DungeonType of
        ?DUNGEON_TYPE_KINGDOM_RUSH ->
			lib_kingdom_rush_dungeon:get_level(Status#player_status.copy_id);
        ?DUNGEON_TYPE_MULTI_KING ->
			lib_multi_king_dungeon:get_level(Status#player_status.copy_id);
		_ ->
			skip
	end;

%% 塔防副本—获取积分和经验.
handle(61302, Status, _) ->
    DungeonType = lib_dungeon:get_dungeon_type(Status#player_status.scene),
    case DungeonType of
        ?DUNGEON_TYPE_KINGDOM_RUSH ->
			lib_kingdom_rush_dungeon:get_score(Status#player_status.copy_id);
        ?DUNGEON_TYPE_MULTI_KING ->
			lib_multi_king_dungeon:get_score(Status#player_status.copy_id);
		_ ->
			skip
	end;

%% 塔防副本—提前召唤怪物.
handle(61303, _Status, _) ->
%%     DungeonType = lib_dungeon:get_dungeon_type(Status#player_status.scene),
%%     case DungeonType of
%%         ?DUNGEON_TYPE_KINGDOM_RUSH ->
%% 			lib_kingdom_rush_dungeon:call_mon(Status#player_status.copy_id);
%%         ?DUNGEON_TYPE_MULTI_KING ->
%% 			lib_multi_king_dungeon:call_mon(Status#player_status.copy_id);
%% 		_ ->
%% 			skip
%% 	end;
	ok;

%% 塔防副本—升级建筑.
handle(61304, Status, [MonAutoId, NextMonMid]) ->
    DungeonType = lib_dungeon:get_dungeon_type(Status#player_status.scene),
    case DungeonType of
        ?DUNGEON_TYPE_KINGDOM_RUSH ->
			lib_kingdom_rush_dungeon:upgrade_building(Status#player_status.copy_id, [MonAutoId, NextMonMid]);
        ?DUNGEON_TYPE_MULTI_KING ->
			lib_multi_king_dungeon:upgrade_building(Status#player_status.copy_id, 
													[Status#player_status.id,
													 Status#player_status.nickname,
													 MonAutoId, 
													 NextMonMid]);
		_ ->
			skip
	end;

%% 塔防副本—升级技能.
handle(61305, Status, [MonAutoId, SkillId, SkillLevel]) ->
    DungeonType = lib_dungeon:get_dungeon_type(Status#player_status.scene),
    case DungeonType of
        ?DUNGEON_TYPE_KINGDOM_RUSH ->
			lib_kingdom_rush_dungeon:upgrade_skill(Status#player_status.copy_id, [MonAutoId, SkillId, SkillLevel]);
        ?DUNGEON_TYPE_MULTI_KING ->
			lib_multi_king_dungeon:upgrade_skill(Status#player_status.copy_id, 
												 [Status#player_status.id,
												  Status#player_status.nickname,
												  MonAutoId, 
												  SkillId, 
												  SkillLevel]);
		_ ->
			skip
	end;

%% 塔防副本—获取建筑信息.
handle(61306, Status, _) ->
    DungeonType = lib_dungeon:get_dungeon_type(Status#player_status.scene),
    case DungeonType of
        ?DUNGEON_TYPE_KINGDOM_RUSH ->
			lib_kingdom_rush_dungeon:get_building(Status#player_status.copy_id);
        ?DUNGEON_TYPE_MULTI_KING ->
			lib_multi_king_dungeon:get_building(Status#player_status.copy_id);
		_ ->
			skip
	end;

handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_kingdom_rush_dungeon no match", []),
    {error, "pp_kingdom_rush_dungeon no match"}.