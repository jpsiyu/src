%%------------------------------------------------------------------------------
%% @Module  : lib_story_master
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.12.20
%% @Description: 剧情副本霸主
%%------------------------------------------------------------------------------


-module(lib_story_master).
-include("dungeon.hrl").
-include("sql_dungeon.hrl").


-export([
		load_story_masters/0,      %% 加载所有剧情副本霸主 -- 公共服务器.
		init_story_masters/0,      %% 没有霸主数据初始化一次.
		get_story_masters/1,       %% 获取剧情副本霸主 -- 公共服务器.
		set_story_masters/8,       %% 设置剧情副本霸主 -- 公共服务器.
		send_story_master_reward/0,%% 发送剧情副本霸主奖励 -- 公共服务器.
		get_player_name/1          %% 得到玩家的名字.
    ]).


%% 加载所有剧情副本霸主 -- 公共服务器.
load_story_masters() ->
    case db:get_all(?sql_select_all_story_masters) of
		[] ->
			%没有霸主数据初始化一次.
			init_story_masters();
        MastersList when is_list(MastersList) -> 
            FunInsert = 
				fun([Chapter, PlayerId, PlayerName, PlayerSex, PlayerCareer, Score, PassTime, RecordList]) ->
					RecordList2 = util:to_term(RecordList),
					RecordList3 = 
						case RecordList2 of
							[] -> 
								[];
							_ when is_list(RecordList2)->
								RecordList2;
							_ ->
								[]
						end,
                    ets:insert(?ETS_STORY_MASTER, 
							   #ets_story_master{
                            		chapter     = Chapter,
                            		player_id   = PlayerId,
									player_name = PlayerName,
                                    sex         = PlayerSex,
                                    career      = PlayerCareer,
									score       = Score,
                            		passtime    = PassTime,
									record_list = RecordList3})
                end,
            [FunInsert(Masters) || Masters <- MastersList]
    end.

%没有霸主数据初始化一次.
init_story_masters() ->	
	%1.定义获取霸主的函数.
	FunPlayerMaster = 
		fun(Chapter, SQL) ->
			case db:get_all(io_lib:format(SQL, [])) of
				[] ->
					skip;
				PlayerList ->
					case is_can_master(PlayerList, Chapter) of
						false -> 
							skip;
						{ok, PlayerId1, PlayerName, PlayerSex, PlayerCareer, Score1, PassTime1} ->
							case Score1 > 0 of
								true ->
									RecordList = get_record_list_db(PlayerId1, Chapter),
									%3.是否完成了全部章节.
								    case finish_chapter2(RecordList) of
								        true ->
											lib_story_master:set_story_masters(
												PlayerId1,
                                                util:bitstring_to_term(PlayerName), 
                                                PlayerSex, 
                                                PlayerCareer,
												Chapter, 
												Score1, 
												PassTime1, 
												RecordList);
								        false ->
											skip
								    end;
								false ->
									skip
							end
					end
			end
		end,	
	FunPlayerMaster(6, ?sql_select_player_story_dungeon6),
	FunPlayerMaster(5, ?sql_select_player_story_dungeon5),
	FunPlayerMaster(4, ?sql_select_player_story_dungeon4),
	FunPlayerMaster(3, ?sql_select_player_story_dungeon3),
	FunPlayerMaster(2, ?sql_select_player_story_dungeon2),
	FunPlayerMaster(1, ?sql_select_player_story_dungeon1).
	
%% 获取剧情副本霸主 -- 公共服务器.
get_story_masters(PlayerId) ->
	MasterList = ets:tab2list(?ETS_STORY_MASTER),
    MasterList2 = [{Master#ets_story_master.chapter,
					Master#ets_story_master.player_id,
					Master#ets_story_master.player_name,
                    Master#ets_story_master.sex,
                    Master#ets_story_master.career,
					Master#ets_story_master.record_list}
				    || Master <- MasterList],
	{ok, BinData} = pt_610:write(61014, MasterList2),
	lib_server_send:send_to_uid(PlayerId, BinData).

%% 设置剧情副本霸主 -- 公共服务器.
set_story_masters(PlayerId, PlayerName, PlayerSex, PlayerCareer, Chapter, Score, PassTime, RecordList) ->
	MasterList = ets:tab2list(?ETS_STORY_MASTER),

	%1.和本章霸主比较是否可以替换.
	IsSaveData =
		case lists:keyfind(Chapter, 2, MasterList) of
	        false  ->
				true;
	        _MasterData1 ->
				Score2 = _MasterData1#ets_story_master.score,
				PassTime2 = _MasterData1#ets_story_master.passtime,
				
				if Score > Score2 ->
					   true;
				   Score =:= Score2 andalso PassTime < PassTime2 ->
					   true;
				   true ->
					   false
				end					
		end,

	%2.保存霸主数据.
	case IsSaveData of
		false ->
			skip;
		true ->
			%1.检测玩家是否已经是霸主了.
			IsCanMaster = 			
				case lists:keyfind(PlayerId, 3, MasterList) of
			        false  ->
						true;
			        _MasterData2 ->
						Chapter2 = _MasterData2#ets_story_master.chapter,					
						if  %1.是低章节霸主就删掉.
							Chapter >= Chapter2 ->
								ets:delete(?ETS_STORY_MASTER, Chapter2),
								db:execute(io_lib:format(?sql_delete_story_masters, [Chapter2])),
								true;							   
						   true ->
							   false
						end					
				end,
		
			%2.替换霸主数据.
			case IsCanMaster of
				true ->
					%1.得到玩家名字.
					RecordList2 = util:term_to_string(RecordList),
					MasterData = [Chapter, PlayerId, PlayerName, PlayerSex, PlayerCareer, Score, PassTime, RecordList2],
					db:execute(io_lib:format(?sql_replace_story_masters, MasterData)),
                    ets:insert(?ETS_STORY_MASTER, 
                        #ets_story_master{
                            chapter     = Chapter,
                            player_id   = PlayerId,
                            player_name = PlayerName,
                            sex         = PlayerSex,
                            career      = PlayerCareer,
                            score       = Score,
                            passtime    = PassTime,
                            record_list = RecordList});
				false ->
					skip
			end			
	end.

%% 发送剧情副本霸主奖励 -- 公共服务器.
send_story_master_reward() ->
	MasterList = ets:tab2list(?ETS_STORY_MASTER),
	FunSend = 
		fun(Chapter, PlayerId) ->
		    GoodsId = data_story_dun_config:get_master_reward(Chapter),				
		    lib_mail:send_sys_mail_bg([PlayerId], 
									 data_dungeon_text:get_story_master_config(title1,0),
									 data_dungeon_text:get_story_master_config(content1, [Chapter]), 
									 GoodsId, 2, 0, 0, 1, 0, 0, 0, 0)
		end,
	[FunSend(Master#ets_story_master.chapter,
			 Master#ets_story_master.player_id)|| Master <- MasterList].

%% 是否完成了第几章函数.
finish_chapter2(RecordList) ->	
	FunFinishChapter = 
		fun({_PlayerId1, Score1, _PassTime1}) ->
			case Score1 >= 1 of
		        true -> true;
		        false -> false
		    end
		end,	
	DungeonIdList2 = lists:filter(FunFinishChapter, RecordList),
    case length(DungeonIdList2) =:= 10 of
        true ->
			true;
        false ->
			false
    end.

%% 得到一章的通关记录.
get_record_list_db(PlayerId, Chapter) ->
	FunGetRecordList = 
		fun(DungeonId, RecordList) ->
			case db:get_row(io_lib:format(?sql_dungeon_log_sel_type2, [PlayerId, DungeonId])) of				
				[] ->
					RecordList;
%% 				_Test -> io:format("Test=~p~n", [_Test]),
%% 					RecordList
		        [_DungeonId, Record_Level, PassTime] -> 
					RecordList ++ [{_DungeonId, Record_Level, PassTime}]
			end
		end,
	DungeonIdList = data_story_dun_config:get_chapter_dungeon_list(Chapter),
	lists:foldl(FunGetRecordList, [], DungeonIdList).

%% 得到玩家的名字.
get_player_name(PlayerId) ->
	case db:get_one(io_lib:format(?sql_select_nickname, [PlayerId])) of				
		null ->
			<<"">>;
		PlayerName ->
			PlayerName
	end.

%% 检测玩家是否可以霸主.
is_can_master([], _Chapter) ->
	false;
is_can_master([_Player|PlayerList], Chapter) ->
	MasterList = ets:tab2list(?ETS_STORY_MASTER),
	case _Player of
		Player when is_list(Player) ->
			[PlayerId, PlayerName, PlayerSex, PlayerCareer, _Score, _PassTime] = Player,
			%1.检测玩家是否已经是霸主了.			
			case lists:keyfind(PlayerId, 3, MasterList) of
		        false  ->
					{ok, PlayerId, PlayerName, PlayerSex, PlayerCareer, _Score, _PassTime};
		        _MasterData2 ->
					Chapter2 = _MasterData2#ets_story_master.chapter,					
					if
						Chapter < Chapter2 ->
							is_can_master(PlayerList, Chapter);
					   true ->
						   {ok, PlayerId, PlayerName, PlayerSex, PlayerCareer, _Score, _PassTime}
					end					
			end;			
		false ->
			false
	end.
