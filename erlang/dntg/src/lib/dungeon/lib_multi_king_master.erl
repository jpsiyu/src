%%------------------------------------------------------------------------------
%% @Module  : lib_multi_king_master
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.11.22
%% @Description: 多人皇家守卫军塔防副本霸主
%%------------------------------------------------------------------------------


-module(lib_multi_king_master).
-include("server.hrl").
-include("dungeon.hrl").
-include("king_dun.hrl").
-include("sql_dungeon.hrl").


%% 公共函数：外部模块调用.
-export([
		load_master/0,    %% 导入所有霸主.
		set_master/3,     %% 设置霸主数据.
		get_rank_master/0 %% 获取霸主排行榜.		
]).


%% --------------------------------- 公共函数 ----------------------------------

%% 导入所有霸主.
load_master() ->
    case db:get_all(?sql_select_rank_multi_king_dungeon) of
        MasterList when is_list(MasterList) ->
            FunLoad = 
				fun([Level, PlayerList, Time]) -> 
                    case util:bitstring_to_term(PlayerList) of 
                        undefined -> 
							[];
                        PlayerList2 -> 
                            [{Level, PlayerList2, Time}]
                    end
            end,
            MasterList2 = lists:flatmap(FunLoad, MasterList),
            put("MutilMaster", MasterList2);
        _ -> 
            put("MutilMaster", [])
    end.

%% 设置霸主数据.
set_master(PlayerIdList, Level, Time) ->
	%1.是否可以当霸主数据.
	IsMaster = is_master(Level, Time),
	case IsMaster of
		false ->
			skip;
		true ->
			%2.删除波数低的霸主数据.
			DeleteResult = delete_master(PlayerIdList, Level, Time),
			case DeleteResult of		 
				[] -> 
					%3.插入新数据.
					FunPlayer = 
						fun(PlayerId) ->
							PlayerName = lib_story_master:get_player_name(PlayerId),
							{PlayerId, PlayerName}
						end,
					PlayerList = [FunPlayer(PlayerId)||PlayerId<-PlayerIdList],
				    case util:term_to_bitstring(PlayerList) of
				        <<"undefined">> -> 
							skip;
				        PlayerList2 ->
							Sql = io_lib:format(?sql_insert_rank_multi_king_dungeon, 
									[Level, PlayerList2, Time]),
							catch db:execute(Sql)
				    end,			
		
					%4.重新导入数据.
					load_master();
		        _ ->
					skip
			end
	end.

%% 是否可以当霸主数据.
is_master(FinishLevel, FinishTime) ->
	case get("MutilMaster") of
		undefined ->
			true;
		MasterList ->
		    case lists:keyfind(FinishLevel, 1, MasterList) of
		        false -> 
					true;
		        {_Level, _PlayerList, Time} ->
					case FinishTime < Time of
						true -> true;
						false -> false
					end
			end
	end.

%% 删除波数低的霸主数据.
delete_master(PlayerIdList, FinishLevel, FinishTime) ->
    Len = length(PlayerIdList),
    FunDelete = 
		fun(Master) ->
			{Level, PlayerList2, Time} = Master,
            case Len == length(PlayerList2) of
                false -> 
					[];
                true ->
                    MasterIds = [element(1,Element)||Element<-PlayerList2],
                    case MasterIds -- PlayerIdList of
                    	[] ->
							Sql = io_lib:format(?sql_delete_rank_multi_king_dungeon, [Level]),
							if 
								FinishLevel > Level ->
								   catch db:execute(Sql),
								   [];
								FinishLevel == Level andalso Time > FinishTime ->
								   catch db:execute(Sql),
								   [];
								true->
									[Master]
							end;
                     	_ -> 
							[]
                     end
             end
    	end,
	case get("MutilMaster") of
		undefined ->
			[];
		MasterList ->
			lists:flatmap(FunDelete, MasterList)
	end.

%% 获取霸主排行榜.
get_rank_master() ->
	case get("MutilMaster") of
		undefined ->
			[];
		[] ->
			[];
		MasterList ->
		    FunGet = 
				fun({Level, PlayerList, Time}) ->
		            NameList = [Name||{_Id, Name}<- PlayerList],
		            [Level, NameList, Time]
		    	end,
		    [FunGet(Master)||Master<-MasterList]
	end.
