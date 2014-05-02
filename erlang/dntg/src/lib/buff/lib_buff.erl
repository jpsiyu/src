%%%------------------------------------
%%% @Module  : buff_dict_cast
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2013.02.25
%%% @Description: lib_buff
%%%------------------------------------
-module(lib_buff).
-export([
        del_buff_by_id/3,
        match_two/3,
        match_two2/3,
        match_three/4,
        lookup_id/2
    ]).
-include("buff.hrl").

%% 根据唯一ID删除BUFF
del_buff_by_id([], _Id, BuffList) -> BuffList;
del_buff_by_id([H | T], Id, BuffList) ->
    case is_record(H, ets_buff) of
        true ->
            case H#ets_buff.id of
                Id -> 
                    lists:delete(H, BuffList);
                _ -> 
                    del_buff_by_id(T, Id, BuffList)
            end;
        false ->
            del_buff_by_id(T, Id, BuffList)
    end.

%% 根据Type匹配 
match_two([], _Type, List) -> List;
match_two([H | T], Type, List) ->
    case is_record(H, ets_buff) of
        true ->
            case H#ets_buff.type of
                Type ->
                    match_two(T, Type, [H | List]);
                _ ->
                    match_two(T, Type, List)
            end;
        false ->
            match_two(T, Type, List)
    end.

%% 根据AttributeId匹配 
match_two2([], _AttributeId, List) -> List;
match_two2([H | T], AttributeId, List) ->
    case is_record(H, ets_buff) of
        true ->
            case H#ets_buff.attribute_id of
                AttributeId ->
                    match_two2(T, AttributeId, [H | List]);
                _ ->
                    match_two2(T, AttributeId, List)
            end;
        false ->
            match_two2(T, AttributeId, List)
    end.

%% 根据Type和Attribute匹配
match_three([], _Type, _Attribute, List) -> List;
match_three([H | T], Type, Attribute, List) ->
    case is_record(H, ets_buff) of
        true ->
            case H#ets_buff.type =:= Type andalso H#ets_buff.attribute_id =:= Attribute of
                true ->
                    match_three(T, Type, Attribute, [H | List]);
                false ->
                    match_three(T, Type, Attribute, List)
            end;
        false ->
            match_three(T, Type, Attribute, List)
    end.

%% 根据唯一ID查找
lookup_id([], _BuffId) -> undefined;
lookup_id([H | T], BuffId) ->
    case is_record(H, ets_buff) of
        true ->
            case H#ets_buff.id of
                BuffId ->
                    H;
                _ ->
                    lookup_id(T, BuffId)
            end;
        false ->
            lookup_id(T, BuffId)
    end.
