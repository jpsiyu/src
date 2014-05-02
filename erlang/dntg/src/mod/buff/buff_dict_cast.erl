%%%------------------------------------
%%% @Module  : buff_dict_cast
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.27
%%% @Description: handle_cast
%%%------------------------------------
-module(buff_dict_cast).
-export([handle_cast/2]).
-include("buff.hrl").

%% 根据主键Id删除
handle_cast({delete_id, Id}, Status) ->
    case get({ets_buff, Id}) of
        EtsBuff when is_record(EtsBuff, ets_buff) ->
            PlayerId = EtsBuff#ets_buff.pid,
            lib_player:update_player_info(PlayerId, [{del_player_buff, EtsBuff}]);
        _ ->
            skip
    end,
	erase({ets_buff, Id}),
    {noreply, Status};

%% 插入操作
handle_cast({insert_buff, EtsBuff}, Status) ->
	put({ets_buff, EtsBuff#ets_buff.id}, EtsBuff),
    lib_player:update_player_info(EtsBuff#ets_buff.pid, [{add_player_buff, EtsBuff}]),
    {noreply, Status};

%% 根据用户Id删除
handle_cast({match_delete, Pid}, Status) ->
	List = get_all_deal(get(), []),
	match_delete(Pid, List),
    lib_player:update_player_info(Pid, [{del_all_player_buff, no}]),
    {noreply, Status};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("buff_dict_cast:handle_cast not match: ~p", [Event]),
    {noreply, Status}.

%% 把[{1, L1}, {2, L2} ...]格式转换为[L1, L2 ...]，即去掉key，只取value
get_all_deal([], L2) -> L2;
get_all_deal([{H1, H2} | T], L2) -> 
	case H1 of
		{ets_buff, _Id} ->
			get_all_deal(T, [H2 | L2]);
		_ ->
			get_all_deal(T, L2)
	end.

match_delete(_Pid, []) -> skip;
match_delete(Pid, [H | T]) ->
	case H#ets_buff.pid =:= Pid of
		true ->	erase({ets_buff, H#ets_buff.id});
		false -> skip
	end,
	match_delete(Pid, T).
