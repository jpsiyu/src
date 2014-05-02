%%%-----------------------------------
%%% @Module  : cache_op
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: ets表操作函数
%%%-----------------------------------
-module(cache_op).
-include("common.hrl").
-export([
        lookup/2,
        lookup_one/2,
        lookup_all/2,
        match_one/2,
        match_all/2,
        match/2,
        lookup10/2,
        match_object10/2,
        match10/2,
        insert10/2,
        delete10/2,
        lookup_unite/2,
        match_object_unite/2,
        match_unite/2,
        insert_unite/2,
        delete_unite/2,
        match_delete_unite/2,
        update_element_unite/3
    ]).
%%=========================================================================
%% 缓存操作函数
%%=========================================================================

%% -----------------------------------------------------------------
%% 通用函数
%% -----------------------------------------------------------------
lookup_one(Table, Key) ->
    Record = ets:lookup(Table, Key),
    if  Record =:= [] ->
            [];
        true ->
            [R] = Record,
            R
    end.

lookup_all(Table, Key) ->
    ets:lookup(Table, Key).

match_one(Table, Pattern) ->
    Record = ets:match_object(Table, Pattern),
    if  Record =:= [] ->
            [];
        true ->
            [R] = Record,
            R
    end.

match_all(Table, Pattern) ->
    ets:match_object(Table, Pattern).

match(Table, Pattern) ->
    Record = ets:match(Table, Pattern),
    if  Record =:= [] ->
            [];
        true ->
            Record     
    end.

lookup(Table, Key) ->
    ets:lookup(Table, Key).

%% 在游戏线10线上的ets表操作
lookup10(Table, Key) ->
    mod_disperse:call_by_line_id(mod_disperse:node_id(), 10, ets, lookup, [Table, Key]).

match_object10(Table, Pattern) ->
    mod_disperse:call_by_line_id(mod_disperse:node_id(), 10, ets, match_object, [Table, Pattern]).

match10(Table, Pattern) ->
    mod_disperse:call_by_line_id(mod_disperse:node_id(), 10, ets, match, [Table, Pattern]).

insert10(Tab, Object) ->
    mod_disperse:cast_by_line_id(mod_disperse:node_id(), 10, ets, insert, [Tab, Object]).

delete10(Tab, Key) ->
    mod_disperse:cast_by_line_id(mod_disperse:node_id(), 10, ets, delete, [Tab, Key]).

%% 在公共线上的ets表操作
lookup_unite(Table, Key) ->
    mod_disperse:call_by_line_id(mod_disperse:node_id(), ?UNITE, ets, lookup, [Table, Key]).

match_object_unite(Table, Pattern) ->
    mod_disperse:call_by_line_id(mod_disperse:node_id(), ?UNITE, ets, match_object, [Table, Pattern]).

match_unite(Table, Pattern) ->
    mod_disperse:call_by_line_id(mod_disperse:node_id(), ?UNITE, ets, match, [Table, Pattern]).

insert_unite(Tab, Object) ->
    mod_disperse:cast_by_line_id(mod_disperse:node_id(), ?UNITE, ets, insert, [Tab, Object]).

delete_unite(Tab, Key) ->
    mod_disperse:cast_by_line_id(mod_disperse:node_id(), ?UNITE, ets, delete, [Tab, Key]).

match_delete_unite(Tab, Key) ->
    mod_disperse:cast_by_line_id(mod_disperse:node_id(), ?UNITE, ets, match_delete, [Tab, Key]).

update_element_unite(Tab, Key, Arg) ->
    mod_disperse:cast_by_line_id(mod_disperse:node_id(), ?UNITE, ets, update_element, [Tab, Key, Arg]).
