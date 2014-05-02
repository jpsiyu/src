%%%------------------------------------
%%% @Module  : mod_chat_agent
%%% @Author  : xyao
%%% @Created : 2012.07.25
%%% @Description: 聊天管理
%%%------------------------------------
-module(mod_chat_agent).
-behaviour(gen_server).
-export([start_link/0, 
		 get_online_num/0,
         get_scene_room_num/1,
         get_sid/2,
         insert/1,
         lookup/1,
		 match/2,
		 update_lv/2,
         delete/1
        ]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("unite.hrl").

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

get_online_num()->
	gen_server:call(?MODULE, {get_online_num, all}).

%% 获取指定场景人数
get_scene_room_num(Scene)->
	gen_server:call(?MODULE, {get_scene_room_num, Scene}).

%% 获取sid数据
get_sid(all, D) ->
    gen_server:call(?MODULE, {get_sid, all, D});
get_sid(scene, D) ->
    gen_server:call(?MODULE, {get_sid, scene, D});
get_sid(guild, D) ->
    gen_server:call(?MODULE, {get_sid, guild, D});
get_sid(realm, D) ->
    gen_server:call(?MODULE, {get_sid, realm, D});
get_sid(team, D) ->
    gen_server:call(?MODULE, {get_sid, team, D});
get_sid(group, D) ->
    gen_server:call(?MODULE, {get_sid, group, D}).

%% 插入数据
insert(EtsUnite) ->
    gen_server:cast(?MODULE, {insert, EtsUnite}).

%% 同步等级信息
update_lv(Id, NewLevel) ->
    gen_server:cast(?MODULE, {update, Id, NewLevel}).

%% 删除数据
delete(Id) ->
    gen_server:cast(?MODULE, {delete, Id}).

%% 查找数据
lookup(Id) ->
    gen_server:call(?MODULE, {lookup, Id}).

%% 多条件查找
%%　返回值由使用者自己定义
match(all_ids, Info) ->
	gen_server:call(?MODULE, {match, all_ids, Info});
match(all_ids_by_lv_gap, Info) ->
	gen_server:call(?MODULE, {match, all_ids_by_lv_gap, Info});
match(match_name, Info) ->
	gen_server:call(?MODULE, {match, match_name, Info});
match(find_partners, Info) ->
	gen_server:call(?MODULE, {match, find_partners, Info});
match(guild_id_pid_sid, Info) ->
	gen_server:call(?MODULE, {match, guild_id_pid_sid, Info});
match(guild_members_id_by_id, Info) ->
	gen_server:call(?MODULE, {match, guild_members_id_by_id, Info});
match(guild_members_id_by_name, Info) ->
	gen_server:call(?MODULE, {match, guild_members_id_by_name, Info});
match(get_scene_role_num, Info) ->
	gen_server:call(?MODULE, {match, get_scene_role_num, Info});
match(find_guild_friend, Info) ->
	gen_server:call(?MODULE, {match, find_guild_friend, Info});
match(Type, _Info) ->
	catch util:errlog("mod_chat_agent:match error Type [~p] is undefined ", [Type]),
	[].

init([]) ->
    process_flag(trap_exit, true),
    {ok, []}.

handle_call({get_online_num, all}, _From, State) ->
    Data = get(),
	Num = length([{K, V} || {K, V} <-Data, is_integer(K)]),
    {reply, Num, State};

%% 获取各个房间人数
handle_call({get_scene_room_num, Scene}, _From, State) ->
    Data = get(),
    F = fun({K, V}, Room) ->
        case is_integer(K) andalso V#ets_unite.scene =:= Scene of
            true ->
                [{1,D1},{2,D2},{3,D3},{4,D4},{5,D5},{6,D6},{7,D7},{8,D8},{9,D9},{10,D10}] = Room,
                if
                    V#ets_unite.copy_id =:= 1 ->
                        [{1,D1+1},{2,D2},{3,D3},{4,D4},{5,D5},{6,D6},{7,D7},{8,D8},{9,D9},{10,D10}];
                    V#ets_unite.copy_id =:= 2 ->
                        [{1,D1},{2,D2+1},{3,D3},{4,D4},{5,D5},{6,D6},{7,D7},{8,D8},{9,D9},{10,D10}];
                    V#ets_unite.copy_id =:= 3 ->
                        [{1,D1},{2,D2},{3,D3+1},{4,D4},{5,D5},{6,D6},{7,D7},{8,D8},{9,D9},{10,D10}];
                    V#ets_unite.copy_id =:= 4 ->
                        [{1,D1},{2,D2},{3,D3},{4,D4+1},{5,D5},{6,D6},{7,D7},{8,D8},{9,D9},{10,D10}];
                    V#ets_unite.copy_id =:= 5 ->
                        [{1,D1},{2,D2},{3,D3},{4,D4},{5,D5+1},{6,D6},{7,D7},{8,D8},{9,D9},{10,D10}];
                    V#ets_unite.copy_id =:= 6 ->
                        [{1,D1},{2,D2},{3,D3},{4,D4},{5,D5},{6,D6+1},{7,D7},{8,D8},{9,D9},{10,D10}];
                    V#ets_unite.copy_id =:= 7 ->
                        [{1,D1},{2,D2},{3,D3},{4,D4},{5,D5},{6,D6},{7,D7+1},{8,D8},{9,D9},{10,D10}];
                    V#ets_unite.copy_id =:= 8 ->
                        [{1,D1},{2,D2},{3,D3},{4,D4},{5,D5},{6,D6},{7,D7},{8,D8+1},{9,D9},{10,D10}];
                    V#ets_unite.copy_id =:= 9 ->
                        [{1,D1},{2,D2},{3,D3},{4,D4},{5,D5},{6,D6},{7,D7},{8,D8},{9,D9+1},{10,D10}];
                    true ->
                        [{1,D1},{2,D2},{3,D3},{4,D4},{5,D5},{6,D6},{7,D7},{8,D8},{9,D9},{10,D10+1}]
                end;
            false ->
                Room
        end
    end,
    Num = lists:foldl(F, [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}], Data),
    {reply, Num, State};

handle_call({get_sid, all, [MinLv, MaxLv]}, _From, State) ->
    Data = get(),
    Data1 = [ V#ets_unite.sid || {K, V} <-Data, is_integer(K),MinLv =< V#ets_unite.lv andalso V#ets_unite.lv =< MaxLv],
    {reply, Data1, State};

handle_call({get_sid, all, _D}, _From, State) ->
    Data = get(),
    Data1 = [ V#ets_unite.sid || {K, V} <-Data, is_integer(K)],
    {reply, Data1, State};

handle_call({get_sid, scene, [Scene, CopyId]}, _From, State) ->
    Data = get(),
    Data1 = [ V#ets_unite.sid || {K, V} <-Data, is_integer(K), V#ets_unite.scene =:= Scene andalso V#ets_unite.copy_id =:= CopyId ],
    {reply, Data1, State};

handle_call({get_sid, guild, D}, _From, State) ->
    Data = get(),
    Data1 = [ V#ets_unite.sid || {K, V} <-Data, is_integer(K), V#ets_unite.guild_id =:= D],
    {reply, Data1, State};

handle_call({get_sid, realm, D}, _From, State) ->
    Data = get(),
    Data1 = [ V#ets_unite.sid || {K, V} <-Data, is_integer(K), V#ets_unite.realm =:= D],
    {reply, Data1, State};

handle_call({get_sid, team, D}, _From, State) ->
    Data = get(),
    Data1 = [ V#ets_unite.sid || {K, V} <-Data, is_integer(K), V#ets_unite.team_id =:= D],
    {reply, Data1, State};

handle_call({get_sid, group, D}, _From, State) ->
    Data = get(),
    Data1 = [ V#ets_unite.sid || {K, V} <-Data, is_integer(K), V#ets_unite.group =:= D],
    {reply, Data1, State};

%% 查找数据
handle_call({lookup, Id}, _From, State) ->
    Data1 = case get(Id) of
        undefined ->
            [];
        Data ->
            [Data]
    end,
    {reply, Data1, State};

%%　多条件查找
%%　返回值由使用者自己定义
handle_call({match, Type, Info}, _From, State) ->
    Data = do_match(Type, Info),
%% 	io:format("Data : ~p~n", [Data]),
    {reply, Data, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({insert, EtsUnite}, State) ->
    put(EtsUnite#ets_unite.id, EtsUnite),
    {noreply, State};

handle_cast({update, Id, NewLevel}, State) ->
	case get(Id) of
        undefined ->
            skip;
        Data ->
            put(Data#ets_unite.id, Data#ets_unite{lv = NewLevel})
    end,
    {noreply, State};

handle_cast({delete, Id}, State) ->
    erase(Id),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% 内部函数:查询
do_match(Type, Info) ->
%% 	io:format("Data : ~p~n", [Type]),
	%% 获取所有的数据
	Data = get(),
	%% 查找
	case Type of
		all_ids_by_lv_gap -> %%所有符合等级段在线玩家
			[MinLv, MaxLv] = Info,
			[K || {K, V} <- Data, is_integer(K),V#ets_unite.lv >= MinLv andalso V#ets_unite.lv =< MaxLv];
		all_ids -> %%所有在线玩家
			[K || {K, _V} <- Data, is_integer(K)];
		match_name ->	%% 根据名字查找玩家信息
			[PlayerName] = Info,
%% 			io:format("~p~n", [Data]),
			D = lists:filter(fun({K, OneData}) ->
								 case is_integer(K) andalso OneData#ets_unite.name =:= util:make_sure_list(PlayerName) of
									 true ->
										 true;
									 false ->
										 false
								 end
						 end, Data),
			case D of
				[{_, OneEu}] ->
%% 					io:format("~p~n", [OneEu]),
					[OneEu];
				_ ->
					[]
			end;
		find_partners -> %% 仙侣筛选
			[LvLimit, Sex] = Info,
			lists:foldr(fun({K, OneData}, AccList) ->
								case is_integer(K) andalso OneData#ets_unite.lv >= LvLimit andalso OneData#ets_unite.sex == Sex andalso OneData#ets_unite.appointment =:= 0 of
									true ->
										[[OneData#ets_unite.id, OneData#ets_unite.name, OneData#ets_unite.lv, OneData#ets_unite.realm] | AccList];
									false ->
										AccList
								end
						 end, [], Data);
		find_guild_friend -> %% 仙侣筛选
			[GuildId] = Info,
			lists:foldr(fun({K, OneData}, AccList) ->
										case is_integer(K) andalso OneData#ets_unite.guild_id =:= GuildId of
											true ->
												[OneData#ets_unite.id | AccList];
											false ->
												AccList
										end
								 end, [], Data);
		guild_id_pid_sid -> %% 获取帮派成员ID,PID,SID
			case Info of
				[GuildId, GuildPosition] -> %% 条件/职位限制
					lists:foldr(fun({K, OneData}, AccList) ->
									case is_integer(K) andalso OneData#ets_unite.guild_id =:= GuildId andalso OneData#ets_unite.guild_position =:= GuildPosition of
										true ->
											[[OneData#ets_unite.id, OneData#ets_unite.pid, OneData#ets_unite.sid] | AccList];
										false ->
											AccList
									end
								end, [], Data);
				[GuildId] -> %% 条件/所有成员
%% 					io:format("GuildId ~p~n", [GuildId]),
					lists:foldr(fun({K, OneData}, AccList) ->
										case is_integer(K) andalso OneData#ets_unite.guild_id =:= GuildId of
											true ->
%% 												io:format("GuildId 2 ~p~n", [OneData#ets_unite.guild_id]),
												[[OneData#ets_unite.id, OneData#ets_unite.pid, OneData#ets_unite.sid] | AccList];
											false ->
%% 												io:format("OneData 2 ~p~n", [OneData]),
												AccList
										end
								 end, [], Data);
				_R ->
%% 					io:format("~p~n", [_R]),
					[]
			end;
		guild_members_id_by_id-> %% 帮派成员ID和SID
			[GuildId] = Info,
			lists:foldr(fun({K, OneData}, AccList) ->
								case is_integer(K) andalso  OneData#ets_unite.guild_id =:= GuildId of
									true ->
										case erlang:length(AccList) =:= 0 of
											true ->
												[OneData#ets_unite.id];
											false ->
												[OneData#ets_unite.id | AccList]
										end;
									false ->
										AccList
								end
						 end, [], Data);
		guild_members_id_by_name-> %% 帮派成员ID(通过名字)
			[GuildName] = Info,
			lists:foldr(fun({K, OneData}, AccList) ->
								case is_integer(K) andalso  OneData#ets_unite.guild_name == GuildName of
									true ->
										case erlang:length(AccList) =:= 0 of
											true ->
												[OneData#ets_unite.id];
											false ->
												[OneData#ets_unite.id | AccList]
										end;
									false ->
										AccList
								end
						 end, [], Data);
		get_scene_role_num -> %% 获取场景人数
			[SceneId, CopyId] = Info,
			Lthis = lists:foldr(fun({K, OneData}, AccList) ->
								case is_integer(K) andalso OneData#ets_unite.scene =:= SceneId andalso OneData#ets_unite.copy_id =:= CopyId of
									true ->
										case erlang:length(AccList) =:= 0 of
											true ->
												[OneData#ets_unite.id];
											false ->
												[OneData#ets_unite.id | AccList]
										end;
									false ->
										AccList
								end
						 end, [], Data),
			length(Lthis);
		_ ->
			[]
	end.
	
	
	
	
