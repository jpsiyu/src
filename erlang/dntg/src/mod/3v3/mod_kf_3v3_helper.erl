%%%--------------------------------------
%%% @Module : mod_kf_3v3_helper
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3帮手进程
%%%--------------------------------------

-module(mod_kf_3v3_helper).
-behaviour(gen_server).
-include("kf_3v3.hrl").
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 获取积分列表
get_score_rank(Platform, ServerNum, Node, Id, ModKf3v3State) ->
	gen_server:cast(?MODULE, {get_score_rank, Platform, ServerNum, Node, Id, ModKf3v3State}).

%% 查看单个玩家对阵日志
get_pk_log(Platform, ServerNum, Node, Id) ->
	gen_server:cast(?MODULE, {get_pk_log, Platform, ServerNum, Node, Id}).

%% 清除所有对阵日志
clear_pk_log() ->
	gen_server:cast(?MODULE, {clear_pk_log}).

%% 插入两个队伍pk完的对阵日志
%% @param Result		0都输,1表示A方赢,2表示B方赢
%% @param PlayerListA	A方人员列表，格式：[#bd_3v3_player, ...]
%% @param PlayerListB	B方人员列表，格式：[#bd_3v3_player, ...]
insert_pk_log(PlayerListA, PlayerListB) ->
	gen_server:cast(?MODULE, {insert_pk_log, PlayerListA, PlayerListB}).

%% 领取唯一队伍id
receive_team_no() ->
	gen_server:call(?MODULE, {receive_team_no}).

init([]) ->
	{ok, #helper_state{}}.

handle_call({receive_team_no}, _From, State) ->
	NewState = State#helper_state{
		team_no = State#helper_state.team_no + 1
	},
	{reply, NewState#helper_state.team_no, NewState};

handle_call(_Request, _From, State) ->
	Reply = ok,
	{reply, Reply, State}.

handle_cast({insert_pk_log, PlayerListA, PlayerListB}, State) ->
	%% A、B方对阵要显示的数据
	PlayerDataA = lists:map(fun(PlayerA) ->
		[
			PlayerA#bd_3v3_player.platform,
			PlayerA#bd_3v3_player.server_num,
			PlayerA#bd_3v3_player.id,
			PlayerA#bd_3v3_player.name,
			PlayerA#bd_3v3_player.country,
			PlayerA#bd_3v3_player.sex,
			PlayerA#bd_3v3_player.career,
			PlayerA#bd_3v3_player.lv,
			PlayerA#bd_3v3_player.combat_power
		]
	end, PlayerListA),
	PlayerDataB = lists:map(fun(PlayerB) -> 
		[
			PlayerB#bd_3v3_player.platform,
			PlayerB#bd_3v3_player.server_num,
			PlayerB#bd_3v3_player.id,
			PlayerB#bd_3v3_player.name,
			PlayerB#bd_3v3_player.country,
			PlayerB#bd_3v3_player.sex,
			PlayerB#bd_3v3_player.career,
			PlayerB#bd_3v3_player.lv,
			PlayerB#bd_3v3_player.combat_power
		]
	end, PlayerListB),

	InsertFun = fun(Player, [FState, Side]) -> 
		[PkWinOrLose | _] = Player#bd_3v3_player.pk_result,
		Data = if
			Side =:= 1 ->
				#bd_3v3_fight{
					result = PkWinOrLose,
					player_a = PlayerDataA,
					player_b = PlayerDataB
				};
			true ->
				#bd_3v3_fight{
					result = PkWinOrLose,
					player_a = PlayerDataB,
					player_b = PlayerDataA
				}
		end,
		Key = [Player#bd_3v3_player.platform, Player#bd_3v3_player.server_num, Player#bd_3v3_player.id],
		NewData = case dict:is_key(Key, FState#helper_state.pk_log_dict) of
			true ->
				case dict:fetch(Key, FState#helper_state.pk_log_dict) of
					List when is_list(List) ->
						[Data | List];
					_ ->
						[Data]
				end;
			_ ->
				[Data]
		end,

		NewFState = FState#helper_state{
			pk_log_dict = dict:store(Key, NewData, FState#helper_state.pk_log_dict)
		},
		[NewFState, Side]
	end,
	[NewState1, _] = lists:foldl(InsertFun, [State, 1], PlayerListA),
	[NewState2, _] = lists:foldl(InsertFun, [NewState1, 2], PlayerListB),

	{noreply, NewState2};

handle_cast({get_pk_log, Platform, ServerNum, Node, Id}, State) ->
	Logkey = [Platform, ServerNum, Id],
	ListData = case dict:is_key(Logkey, State#helper_state.pk_log_dict) of
		true ->
			case dict:fetch(Logkey, State#helper_state.pk_log_dict) of
				List when is_list(List) -> List;
				_ -> []
			end;
		_ -> []
	end,
	{ok, BinData} = pt_484:write(48405, ListData),
	mod_clusters_center:apply_cast(Node, lib_unite_send, cluster_to_uid, [Id, BinData]),

	{noreply, State};

handle_cast({clear_pk_log}, State) ->
	NewState = State#helper_state{
		pk_log_dict = dict:new()				   
	},
	{noreply, NewState};

handle_cast({get_score_rank, Platform, ServerNum, Node, Id, ModKf3v3State}, State) ->
	NowTime = util:unixtime(),

	[NewState, ScoreList] = case State#helper_state.score_dict of
		[CacheList, CacheTime] ->
			%% 缓存超过N分钟需要重新获取
			case NowTime - CacheTime > data_kf_3v3:get_config(top_score_cache) of
				true ->
					TopList = lib_kf_3v3:get_top_score_list(ModKf3v3State),
					[State#helper_state{score_dict = [TopList, NowTime]}, TopList];
				_ ->
					[State, CacheList]
			end;
		[] ->
			TopList = lib_kf_3v3:get_top_score_list(ModKf3v3State),
			[State#helper_state{score_dict = [TopList, NowTime]}, TopList]
	end,

	[NewTopList, NewMyPos, _] = 
	lists:foldl(fun(Rd, [TmpTopList, TmpMyPos, TmpPos]) ->
		WantMyPos = 
		case [Platform, ServerNum, Id] =:= [Rd#bd_3v3_rank.platform, Rd#bd_3v3_rank.server_num, Rd#bd_3v3_rank.id] of
			true -> TmpPos;
			_ -> TmpMyPos
		end,

		FPlatform = pt:write_string(Rd#bd_3v3_rank.platform),
		FServerNum = Rd#bd_3v3_rank.server_num,
		FId = Rd#bd_3v3_rank.id,
		FName = pt:write_string(Rd#bd_3v3_rank.name),
		FRealm = Rd#bd_3v3_rank.country,
		FSex = Rd#bd_3v3_rank.sex,
		FCareer = Rd#bd_3v3_rank.career,
		FPkNum = Rd#bd_3v3_rank.pk_num,
		FPkWinNum = Rd#bd_3v3_rank.pk_win_num,
		FScore = Rd#bd_3v3_rank.score,
		FLv = Rd#bd_3v3_rank.lv,
		FData = <<FPlatform/binary, FServerNum:16, FId:32, FName/binary, FRealm:8, FSex:8, FCareer:8, FPkNum:16, FPkWinNum:16, FScore:32, FLv:8>>,

		[[FData | TmpTopList], WantMyPos, TmpPos + 1]
	end, [[], 1, 1], ScoreList),
	NewTopList2 = lists:reverse(NewTopList),
	{ok, BinData} = pt_484:write(48414, [NewMyPos, NewTopList2]),
	mod_clusters_center:apply_cast(Node, lib_unite_send, cluster_to_uid, [Id, BinData]),

	{noreply, NewState};

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.
