%%%------------------------------------
%%% @Module  : mod_chat_forbid
%%% @Author  : hekai
%%% @Created : 2012.10.15
%%% @Description: 聊天禁言
%%%------------------------------------
-module(mod_chat_forbid).
-behaviour(gen_server).
-export([start/0, stop/0]).
-export([clear/0,               %% 每日清除
		record_personal_chat/2, %% 记录40级以下，玩家私聊
		inform_chat/2           %% 聊天举报
	]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).
-include("server.hrl").
-include("chat.hrl").

start() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

%% 每日清除
clear() ->
	gen_server:cast(misc:get_global_pid(?MODULE), {clear}).

%% 解除禁言
release_chat_forbid(Id) ->
	gen_server:cast(misc:get_global_pid(?MODULE), {release_chat_forbid, Id}).

%% 记录40级以下，玩家私聊
%% @param  自己ID
%% @param  私聊方Id
%% @return 该天私聊玩家个数
record_personal_chat(IdA, IdB) ->
	gen_server:call(misc:get_global_pid(?MODULE), {record_personal_chat, IdA, IdB}).

%% 聊天举报
%% @param  自己ID
%% @param  被举报玩家Id
%% @return 该天玩家B被举报次数
inform_chat(IdA, IdB) ->
	gen_server:call(misc:get_global_pid(?MODULE), {inform_chat, IdA, IdB}).


init([]) ->
	process_flag(trap_exit, true),
	{ok, []}.

handle_call({record_personal_chat, IdA, IdB}, _From, State) ->
	Uid = integer_to_list(IdA),
	UidKey = "per_chat_"++Uid,
	case get(UidKey) of
		undefined ->
			put(UidKey,[IdB]),
			Reply=1;
		Value ->
			Is_record = lists:member(IdB, Value),
			case Is_record of
				true ->
					Reply = length(Value);
				false ->
					Count = length(Value),
					case Count>?ALLOW_CHAT_NUM_1 of
						true -> Reply = Count;
						false ->
							NewValue = [IdB|Value],
							put(UidKey,NewValue),
							Reply = length(NewValue)
					end					
			end
	end,
	{reply, Reply, State};

handle_call({inform_chat, IdA, IdB}, _From, State) ->
	Uid = integer_to_list(IdB),
	UidKey = "inform_chat_"++Uid,
	case get(UidKey) of
		undefined ->
			put(UidKey,[IdA]),
			Reply=1;
		Value ->
			Is_record = lists:member(IdA, Value),
			case Is_record of
				true ->
					Reply = length(Value);
				false ->
					Count = length(Value),
					case Count>?ALLOW_INFORM_NUM of
						true -> Reply = Count;
						false ->       
							NewValue = [IdA|Value],
							put(UidKey,NewValue),
							Reply = length(NewValue)
					end
			end
	end,
	{reply, Reply, State};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_chat_forbid:handle_call not match: ~p~n", [Event]),
    {reply, ok, Status}.


%% 解除禁言
handle_cast({release_chat_forbid, Id}, State) ->	
	Uid = integer_to_list(Id),
	UidKey_1 = "per_chat_"++Uid,
	UidKey_2 = "inform_chat_"++Uid,
	put(UidKey_1, []),
	put(UidKey_2, []),
    {noreply, State};

%% 清除
handle_cast({clear}, State) ->	
	erase(),
    {noreply, State};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_chat_forbid:handle_cast not match: ~p~n", [Event]),
    {noreply, Status}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
    

