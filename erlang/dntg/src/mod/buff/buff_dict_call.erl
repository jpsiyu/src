%%%------------------------------------
%%% @Module  : buff_dict_call
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.27
%%% @Description: handle_call
%%%------------------------------------
-module(buff_dict_call).
-export([handle_call/3]).
-include("buff.hrl").

%% 全部buff，返回List
handle_call(get_all, _From, Status) ->
	Reply = get_all_deal(get(), []),
    {reply, Reply, Status};

%% 匹配操作(1个参数)
handle_call({match_one, Pid}, _From, Status) ->
	List = get_all_deal(get(), []),
	Reply = match_one(List, Pid, []),
    {reply, Reply, Status};

%% 匹配操作(2个参数)
handle_call({match_two, Pid, Type}, _From, Status) ->
	List = get_all_deal(get(), []),
	Reply = match_two(List, Pid, Type, []),
    {reply, Reply, Status};

%% 匹配操作(2个参数)
handle_call({match_two2, Pid, AttributeId}, _From, Status) ->
	List = get_all_deal(get(), []),
	Reply = match_two2(List, Pid, AttributeId, []),
    {reply, Reply, Status};

%% 匹配操作(3个参数)
handle_call({match_three, Pid, Type, AttributeId}, _From, Status) ->
	List = get_all_deal(get(), []),
	Reply = match_three(List, Pid, Type, AttributeId, []),
    {reply, Reply, Status};

%% 查询操作
handle_call({lookup_id, Id}, _From, Status) ->
	Reply = get({ets_buff, Id}),
    {reply, Reply, Status};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("buff_dict_call:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.

%% 把[{1, L1}, {2, L2} ...]格式转换为[L1, L2 ...]，即去掉key，只取value
get_all_deal([], L2) -> L2;
get_all_deal([{H1, H2} | T], L2) -> 
	case H1 of
		{ets_buff, _Id} ->
			get_all_deal(T, [H2 | L2]);
		_ ->
			get_all_deal(T, L2)
	end.

match_one([], _Pid, L2) -> L2;
match_one([H | T], Pid, L2) ->
	case H#ets_buff.pid =:= Pid of
		true -> match_one(T, Pid, [H | L2]);
		false -> match_one(T, Pid, L2)
	end.

match_two([], _Pid, _Type, L2) -> L2;
match_two([H | T], Pid, Type, L2) ->
	case H#ets_buff.pid =:= Pid andalso H#ets_buff.type =:= Type of
		true -> match_two(T, Pid, Type, [H | L2]);
		false -> match_two(T, Pid, Type, L2)
	end.

match_two2([], _Pid, _AttributeId, L2) -> L2;
match_two2([H | T], Pid, Attribute, L2) ->
	case H#ets_buff.pid =:= Pid andalso H#ets_buff.attribute_id =:= Attribute of
		true -> match_two2(T, Pid, Attribute, [H | L2]);
		false -> match_two2(T, Pid, Attribute, L2)
	end.

match_three([], _Pid, _Type, _AttributeId, L2) -> L2;
match_three([H | T], Pid, Type, AttributeId, L2) ->
	case H#ets_buff.pid =:= Pid andalso H#ets_buff.type =:= Type andalso H#ets_buff.attribute_id =:= AttributeId of
		true -> match_three(T, Pid, Type, AttributeId, [H | L2]);
		false -> match_three(T, Pid, Type, AttributeId, L2)
	end.
