%%%------------------------------------
%%% @Module  : guild_rela_handle
%%% @Author  : wzh
%%% @Created : 2012.02.02
%%% @Description: 帮派间关系处理(for unite only)
%%%------------------------------------
-module(guild_rela_handle).
-include("guild.hrl").
-include("sql_guild.hrl"). 
-include("unite.hrl").
-include("server.hrl").  
-compile(export_all).

-define(F_SIGN, 1).         													%% 同盟标识
-define(E_SIGN, 2).         													%% 敌对标识
-define(F_LIMIT, 1).         													%% 同盟上限(最多10)
-define(E_LIMIT, 1).         													%% 敌对上限(最多10)

%% ------------------------------------------------------------- 对外部接口 -------------------------------------------------------
change_rela(UniteStatus, TGuildId, Type) ->
	SelfPositon = UniteStatus#unite_status.guild_position,
	SelfGuildId = UniteStatus#unite_status.guild_id,
	case SelfPositon =/= 1 of
		true ->
			0;
		false ->
			[Res, MCId, SCId, RelaDict, MGuildName, SGuildName] = case Type of
				0 ->
					[[A, B, C, D, E, F], TRelaDict] = guild_rela({make_normal, SelfGuildId, TGuildId}),
					case A =:= 1 of
						true ->
							TDictList = dict:to_list(TRelaDict),
							TFList = [TOneGuildIdF||{TOneGuildIdF, TTypeF} <- TDictList, TTypeF =:= ?F_SIGN],
							TEList = [TOneGuildIdE||{TOneGuildIdE, TTypeE} <- TDictList, TTypeE =:= ?E_SIGN],
							syn_server_guild(TGuildId, TFList, TEList),
							{ok, BinData2} = pt_403:write(40340, [1, TFList, TEList]),
    						lib_unite_send:send_to_guild(TGuildId, BinData2);
						false ->
							skip
					end,
					[A, B, C, D, E, F];
				1 ->
					[[A, B, C, D, E, F], TRelaDict] = guild_rela({make_friend, SelfGuildId, TGuildId}),
					case A =:= 1 of
						true ->
							TDictList = dict:to_list(TRelaDict),
							TFList = [TOneGuildIdF||{TOneGuildIdF, TTypeF} <- TDictList, TTypeF =:= ?F_SIGN],
							TEList = [TOneGuildIdE||{TOneGuildIdE, TTypeE} <- TDictList, TTypeE =:= ?E_SIGN],
							syn_server_guild(TGuildId, TFList, TEList),
							{ok, BinDataGuild2} = pt_403:write(40340, [1, TFList, TEList]),
    						lib_unite_send:send_to_guild(TGuildId, BinDataGuild2);
						false ->
							skip
					end,
					[A, B, C, D, E, F];
				2 ->
					guild_rela({make_enemy, SelfGuildId, TGuildId});
				_ ->
					[0, 0, 0, []]
			end,
			case MCId =:= 0 orelse SCId =:= 0 of
				true ->
					0;
				false ->
					case Res =:= 1 of
						true ->
							DictList = dict:to_list(RelaDict),
							FList = [OneGuildIdF||{OneGuildIdF, TypeF} <- DictList, TypeF =:= ?F_SIGN],
							EList = [OneGuildIdE||{OneGuildIdE, TypeE} <- DictList, TypeE =:= ?E_SIGN],
		            	    {ok, BinData41} = pt_403:write(40344, [Type, MGuildName]),
		            	    lib_unite_send:send_to_uid(SCId, BinData41),
						    {ok, BinData42} = pt_403:write(40344, [Type, SGuildName]),
		            	    lib_unite_send:send_to_uid(MCId, BinData42),
							{ok, BinDataGuild} = pt_403:write(40340, [1, FList, EList]),
    						lib_unite_send:send_to_guild(SelfGuildId, BinDataGuild),
%% 							io:format("~n~p  ~p~n", [FList, EList]),
							syn_server_guild(SelfGuildId, FList, EList),
							send_mail(SCId, Type, 1, MGuildName),
						    send_mail(MCId, Type, 2, SGuildName),
							%% 同步到玩家数据/场景数据
							Res;
						false ->
							Res
					end
			end
	end.

get_self_rela(GuildId) ->
	{Info, ErrorList} = guild_rela({self_rela, GuildId}),
	case ErrorList =:= [] of
		true ->
			skip;
		false ->
			DictList = dict:to_list(Info),
			FList = [OneGuildIdF||{OneGuildIdF, TypeF} <- DictList, TypeF =:= ?F_SIGN],
			EList = [OneGuildIdE||{OneGuildIdE, TypeE} <- DictList, TypeE =:= ?E_SIGN],
			{ok, BinDataGuild} = pt_403:write(40340, [1, FList, EList]),
			lib_unite_send:send_to_guild(GuildId, BinDataGuild),
			syn_server_guild(GuildId, FList, EList)
	end,
	Info.



guild_rela(Data) ->
	gen_server:call(mod_guild, {guild_rela, Data}).

%% ------------------------------------------------------------- 帮派内部入口 -----------------------------------------------------

%% 修改关系为普通
handle_call({make_normal, MGuildId, SGuildId}, Status) ->
	Info = case check_guild(MGuildId, Status) of
			   [0, _] ->
				   [[0, 0, 0, [], [], []], []];
			   [MCId, MGuildName] ->
				   case check_guild(SGuildId, Status) of
					   [0, _] ->
						   [[0, 0, 0, [], [], []], []];
					   [SCId, SGuildName] ->
						   Res = make_normal(MGuildId, SGuildId),
						   MRelaDict = get_rela_dict(MGuildId),
						   TRelaDict = get_rela_dict(SGuildId),
						   [[Res, MCId, SCId, MRelaDict, MGuildName, SGuildName], TRelaDict]
				   end
		   end,
    Info;
%% 修改关系为同盟
handle_call({make_friend, MGuildId, TGuildId}, Status) ->
	Info = case check_guild(MGuildId, Status) of
			   [0, _] ->
				   [[0, 0, 0, [], [], []], []];
			   [MCId, MGuildName] ->
				   case check_guild(TGuildId, Status) of
					   [0, _] ->
						   [[0, 0, 0, [], [], []], []];
					   [SCId, SGuildName] ->
						   %% 需要检查对方帮主是否在线
						   case mod_chat_agent:lookup(SCId) of
							   [Player] when is_record(Player, ets_unite)->
								   Res = make_friend(MGuildId, TGuildId),
								   MRelaDict = get_rela_dict(MGuildId),
								   TRelaDict = get_rela_dict(TGuildId),
						   		   [[Res, MCId, SCId, MRelaDict, MGuildName, SGuildName], TRelaDict];
							   _ ->
								   [[3, 0, 0, [], [], []], []]
						   end
				   end
		   end,
    Info;
%% 修改关系为敌对
handle_call({make_enemy, MGuildId, SGuildId}, Status) ->
	Info = case check_guild(MGuildId, Status) of
			   [0, _] ->
				   [0, 0, 0, [], [], []];
			   [MCId, MGuildName] ->
				   case check_guild(SGuildId, Status) of
					   [0, _] ->
						   [0, 0, 0, [], [], []];
					   [SCId, SGuildName] ->
						   Res = make_enemy(MGuildId, SGuildId),
						   RelaDict = get_rela_dict(MGuildId),
						   [Res, MCId, SCId, RelaDict, MGuildName, SGuildName]
				   end
		   end,
    Info;
%% 查询关系列表(自己帮派)
handle_call({self_rela, GuildId}, Status) ->
	InfoX = get_rela_dict(GuildId),
	InfoXY = dict:fetch_keys(InfoX),
	ErrorList = fix_error(InfoXY, [], GuildId, Status),
	Info = case ErrorList =:= [] of
		true ->
			InfoX;
		false ->
			get_rela_dict(GuildId)
	end,
    {Info, ErrorList};
%% 查询指定两个帮派的关系(主帮派,从帮派)
handle_call({relation, MGuildId, SGuildId}, _Status) ->
	Info = get_rela_between(MGuildId, SGuildId),
    Info;
%% 查询批量(主帮派, 从帮派列表)
handle_call({relations, MGuildId, SGuildList}, _Status) ->
	Info = get_rela_multi(MGuildId, SGuildList),
    Info;
%% 无匹配
handle_call(Event, _Status) ->
	catch util:errlog("guild_rela_handle not match: ~p", [Event]),
    ok.




%% ------------------------------------------------------------- 分割 -------------------------------------------------------
fix_error([], Old, _MGuildId, _Status)->
	Old;
fix_error(InfoXY, Old, MGuildId, Status)->
	[H|T] = InfoXY,
	case check_guild(H, Status) of
	   [0, _] ->
		   make_normal(MGuildId, H),
		   NewOld = [H|Old],
		   fix_error(T, NewOld, MGuildId, Status);
	   [_MCId, _MGuildName] ->
		   fix_error(T, Old, MGuildId, Status)
    end.

send_mail(Id, Type1, Type2, GuildName) ->
	Type = case Type1 of
		0 ->
			case Type2 of
				1 ->
					rela_normal_1;
				2 ->
					rela_normal_2
			end;
		1 ->
			rela_friend;
		2 ->
			case Type2 of
				1 ->
					rela_enemy_1;
				2 ->
					rela_enemy_2
			end
	end,
	[Title, Format] = data_guild_text:get_mail_text(Type),
	Content = io_lib:format(Format, [GuildName]),
	lib_mail:send_sys_mail_bg([Id], Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0).

syn_server_guild(GuildId, FList, EList) ->
	Ids = mod_chat_agent:match(guild_id_pid_sid, [GuildId]),
	[syn_server(Id, FList, EList)||[Id, _, _]<-Ids],
	ok.

syn_server(PlayerId, FList, EList) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {guild_rela, FList, EList});
        _ ->
            0
    end.

check_guild(GuildId, Status) ->
	case dict:find(GuildId, Status) of
		{ok, Value} ->
			[Value#ets_guild.chief_id, Value#ets_guild.name];
		_ ->
			[0, []]
	end.

make_normal(MGuildId, SGuildId) ->
	RDict = get_rela_dict(MGuildId),
	RDictNew = dict:erase(SGuildId, RDict),
	save_new_rela(MGuildId, RDictNew),
	case dict:find(SGuildId, RDict) of
		{ok, Value} ->
			case Value =:= 1 of
				true ->
					RDict2 = get_rela_dict(SGuildId),
					RDictNew2 = dict:erase(MGuildId, RDict2),
					save_new_rela(SGuildId, RDictNew2);
				false ->
					skip
			end;
		_ ->
			skip
	end,
	1.

make_friend(MGuildId, TGuildId) ->
	MRDict = get_rela_dict(MGuildId),
	TRDict = get_rela_dict(TGuildId),
	MDictList = dict:to_list(MRDict),
	TDictList = dict:to_list(TRDict),
	MList = [MOneGuildId||{MOneGuildId, MType} <- MDictList, MType =:= ?F_SIGN],
	TList = [TOneGuildId||{TOneGuildId, TType} <- TDictList, TType =:= ?F_SIGN],
	case length(MList) < ?F_LIMIT of
		false ->
			2;
		true ->
			case length(TList) < ?F_LIMIT of
				false ->
					5;
				true ->
					replace_rela(MGuildId, TGuildId, ?F_SIGN),
					replace_rela(TGuildId, MGuildId, ?F_SIGN),
					1
			end
	end.

make_enemy(MGuildId, SGuildId) ->
	RDict = get_rela_dict(MGuildId),
	case dict:find(SGuildId, RDict) of
		{ok, Value} ->
			case Value =/= 1 of
				true ->
					replace_rela(MGuildId, SGuildId, ?E_SIGN);
				false ->
					0
			end;
		_ ->
			replace_rela(MGuildId, SGuildId, ?E_SIGN)
	end.

replace_rela(MGuildId, SGuildId, Type) ->
	RDict = get_rela_dict(MGuildId),
	DictList = dict:to_list(RDict),
	ThisTypeList = [{OneGuildId, TypeOld}||{OneGuildId, TypeOld} <- DictList, TypeOld =:= Type],
	LengthLimit = case Type of
					  ?F_SIGN ->
						  ?F_LIMIT;
					  ?E_SIGN ->
						  ?E_LIMIT;
					  _ ->
						  0
				  end,
	case length(ThisTypeList) >= LengthLimit of
		true ->
			2;
		false ->
			DictNext = dict:store(SGuildId, Type, RDict),
			save_new_rela(MGuildId, DictNext),
			1
	end.
			
save_new_rela(MGuildId, RDict) ->
	put({rela, MGuildId}, RDict),
	DictList = dict:to_list(RDict),
	FList = [OneGuildIdF||{OneGuildIdF, TypeF} <- DictList, TypeF =:= ?F_SIGN],
	EList = [OneGuildIdE||{OneGuildIdE, TypeE} <- DictList, TypeE =:= ?E_SIGN],
	db_write(MGuildId, FList, EList),
	RDict.

get_rela_multi(MGuildId, SGuildList) ->
	[{SGuildId, get_rela_between(MGuildId, SGuildId)}||SGuildId <- SGuildList, SGuildId =/= 0].

get_rela_between(MGuildId, SGuildId) ->
	RDict = get_rela_dict(MGuildId),
	case dict:find(SGuildId, RDict) of
		{ok, Value} ->
			Value;
		_ ->
			0
	end.

get_rela_dict(GuildId) ->
	case get({rela, GuildId}) of
		undefined ->
			Dict = init_one(GuildId),
			Dict;
		Value ->
			Value
	end.

init_one(GuildId) ->
	case db_read(GuildId) of
		[GuildId, FriendList, EnemyList] ->
			make_new_one(GuildId, FriendList, EnemyList);
		_ ->
			db_write(GuildId, [], []),
			make_new_one(GuildId, [], [])
	end.

make_new_one(GuildId, FriendList, EnemyList) ->
	Dict0 = dict:new(),
	Dict1 = dict_loop(Dict0, FriendList, 1, ?F_LIMIT),
	Dict2 = dict_loop(Dict1, EnemyList, 2, ?E_LIMIT),
	put({rela, GuildId}, Dict2),
	Dict2.


dict_loop(Dict, _, _, 0) ->
	Dict;
dict_loop(Dict, [], _, _) ->
	Dict;
dict_loop(Dict, GList, Type, Num) ->
	[GuildId|T] = GList,
	NewDict = dict:store(GuildId, Type, Dict),
	dict_loop(NewDict, T, Type, Num - 1).

trans_to_flash(DbList)->
	case util:string_to_term(erlang:binary_to_list(DbList)) of
		 undefined ->
			 [];
		 Vl ->
			 Vl
	 end.

db_write(GuildId, FriendList, EnemyList) ->
	BinFriendList = case util:term_to_bitstring(FriendList) of
        <<"undefined">> -> <<"[]">>;
        V1 -> V1
    end,
	BinEnemyList = case util:term_to_bitstring(EnemyList) of
        <<"undefined">> -> <<"[]">>;
        V2 -> V2
    end,
	Sql = io_lib:format(?SQL_GUILD_RELA_REPLACE, [GuildId, BinFriendList, BinEnemyList]),
	db:execute(Sql).

db_read(GuildId) ->
	Sql = io_lib:format(?SQL_GUILD_RELA_SELECT, [GuildId]),
	case db:get_row(Sql) of
		[GuildId, FriendList, EnemyList] ->
			FriendListNew = trans_to_flash(FriendList),
			EnemyListNew = trans_to_flash(EnemyList),
			[GuildId, FriendListNew, EnemyListNew];
		_ ->
  			[]
	end.
  
%% get_40034_more {id, vip, name}
get_40034_more(GuildIdList, Status) ->
	loop_do(GuildIdList, Status, []).

loop_do([], _Status, Info)->
	Info;
loop_do(GuildIdList, Status, Info)->
	[GuildId|GuildIdListNext] = GuildIdList,
	VipInfo = case dict:find(GuildId, Status) of
		{_, V} ->
			case mod_guild_call:get_guild_member([V#ets_guild.chief_id, 1, Status]) of
				GuildMember when is_record(GuildMember, ets_guild_member) ->
					GuildMember#ets_guild_member.vip;
				_->
					0
			end;
		_ ->
			0
	end,
	RDict = get_rela_dict(GuildId),
%% 	Friend = dict:filter(fun(_, Value) -> Value =:= 1 end, RDict),
	GuildFriend = case lists:keyfind(1, 2, dict:to_list(RDict)) of
		{R0, _} ->
			case dict:find(R0, Status) of
				{_, VV} ->
					VV#ets_guild.name;
				_ ->
					<<>>
			end;
		_ ->
			<<>>
	end,	  
	InfoNext = [{GuildId, VipInfo, GuildFriend} | Info],
	loop_do(GuildIdListNext, Status, InfoNext).
	

%% 默认匹配异步调用(暂时未使用)
handle_cast(Event, Status) ->
    catch util:errlog("mod_guild:handle_cast not match: ~p", [Event]),
    {noreply, Status}.  
  
%% 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
%% ------------------------------------------------------------- E N D -------------------------------------------------------