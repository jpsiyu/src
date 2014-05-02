%%------------------------------------------------------------------------------
%% @Module  : lib_story_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.12.20
%% @Description: 剧情副本逻辑
%%------------------------------------------------------------------------------


-module(lib_story_dungeon).
-include("dungeon.hrl").
-include("sql_dungeon.hrl").
-include("designation.hrl").
-include("server.hrl").

-export([
        get_total_score/2,        %% 获取副本总积分.
        count_base_attribute/2,   %% 获取副本总积分得到的属性加成..       
        get_gift_info/1,          %% 获取副本通关礼包信息.
        get_gift_state/2,         %% 获取副本通关礼包状态.
        set_gift_state/3,         %% 设置副本通关礼包状态.
        get_story_total_score/1,  %% 得到剧情副本总积分.
        save_story_total_score/5, %% 保存剧情副本总积分.
        get_story_designation/1,  %% 获取封魔称号信息
        set_story_designation/1,  %% 激活封魔称号
        count_base_attribute_desigenation/3, %%　获取副本总积分得到的属性加成
        kill_npc/4                %% 封魔录杀怪处理
    ]).

%%===============================================醉西游：封魔录加成============================================
%% 获取副本总积分.
get_total_score(RoleId, _DungeonId) ->
	ScoreList1 = get_story_total_score(RoleId),
	[_PlayerId, _Score1, _Time1, _Score2, _Time2, _Score3, 
	 _Time3, _Score4, _Time4, _Score5, _Time5, _Score6, _Time6] = ScoreList1,
	_Score1 + _Score2 + _Score3 + _Score4 + _Score5 + _Score6.

%% 获取副本总积分得到的属性加成.
count_base_attribute(RoleId, _DungeonId) ->
	ScoreList1 = get_story_total_score(RoleId),
	[_PlayerId, _Score1, _Time1, _Score2, _Time2, _Score3, 
	 _Time3, _Score4, _Time4, _Score5, _Time5, _Score6, _Time6] = ScoreList1,
	TotalScore = _Score1 + _Score2 + _Score3 + _Score4 + _Score5 + _Score6,
	data_story_dun_config:get_base_attribute(TotalScore).

%% 获取副本通关礼包信息.
get_gift_info(RoleId) ->	
	%1.定义查找礼包函数.
	FunFindGift = 
		fun(DungeonId) ->
			GiftId = data_story_dun_config:get_gift_id(DungeonId),
		    case lib_dungeon_log:get(RoleId, DungeonId) of
		        false -> 
					[{DungeonId, GiftId, 0}];
		        RD ->
					case RD#dungeon_log.gift of
						1 -> 
							[{DungeonId, GiftId, 1}];
						2 ->
							[{DungeonId, GiftId, 2}];						
						_Other ->
							[{DungeonId, GiftId, 0}]
					end
			end
		end,

	%2.检查发礼包的副本.
	GiftDungeonList = data_story_dun_config:get_config(gift_dungeon_list),
	GiftList = lists:flatmap(FunFindGift, GiftDungeonList),
	
	%3.发送给客户端.
    {ok, BinData} = pt_610:write(61009, GiftList),		
	lib_server_send:send_to_uid(RoleId, BinData).

%% 获取副本通关礼包状态.
get_gift_state(PlayerId, GiftId) ->
	
	%1.获取副本ID.
	GiftDungeonList = data_story_dun_config:get_config(gift_dungeon_list),
	DungeonId = data_story_dun_config:get_gift_dungeon_id(GiftId),
	DungeonId2 = 
	    case lists:member(DungeonId, GiftDungeonList) of
	        true ->
	            DungeonId;
	        _ ->
	            0
	    end,
	
	%2.返回是否可以领取.
    case lib_dungeon_log:get(PlayerId, DungeonId2) of
        false -> 
			0;
        RD ->
			case RD#dungeon_log.gift of
				1 -> 
					1;
				_Other ->
					0
			end
	end.

%% 设置副本通关礼包状态.
set_gift_state(PlayerId, GiftId, GiftState) ->
	
	%1.获取副本ID.
	GiftDungeonList = data_story_dun_config:get_config(gift_dungeon_list),
	DungeonId = data_story_dun_config:get_gift_dungeon_id(GiftId),
	DungeonId2 = 
	    case lists:member(DungeonId, GiftDungeonList) of
	        true ->
	            DungeonId;
	        _ ->
	            0
	    end,
	
	%2.返回是否可以领取.
    case lib_dungeon_log:get(PlayerId, DungeonId2) of
        false -> 
			0;
        RD ->
			%保存为已领取.
			lib_dungeon_log:save(RD#dungeon_log{gift = GiftState})
	end.

%% 得到剧情副本总积分.
get_story_total_score(PlayerId) ->
	case get("story_total_score") of
		undefined ->
			%% 第一次登录，插入初始记录
			case db:get_row(io_lib:format(?sql_select_story_score, [PlayerId])) of				
				[] ->
					{Score1, Time1} = calc_story_score(PlayerId, 1),
					{Score2, Time2} = calc_story_score(PlayerId, 2),
					{Score3, Time3} = calc_story_score(PlayerId, 3),
					{Score4, Time4} = calc_story_score(PlayerId, 4),
					{Score5, Time5} = calc_story_score(PlayerId, 5),
					{Score6, Time6} = calc_story_score(PlayerId, 6),
					PlayerScore = [PlayerId, Score1, Time1, Score2, Time2, 
								   Score3, Time3, Score4, Time4, Score5, Time5, Score6, Time6],
					db:execute(io_lib:format(?sql_replace_story_score, PlayerScore)),
					put("story_total_score", PlayerScore),
					PlayerScore;
				_ScoreList ->
					put("story_total_score", _ScoreList),
					_ScoreList
			end;
		_ScoreList ->
			_ScoreList
	end.

%% 保存剧情副本总积分.
save_story_total_score(PlayerId, PlayerName, PlayerSex, PlayerCareer, DungeonId) ->	
	%1.得到本章总积分.
	ScoreList1 = get_story_total_score(PlayerId),
	[_PlayerId, _Score1, _Time1, _Score2, _Time2, _Score3, 
	 _Time3, _Score4, _Time4, _Score5, _Time5, _Score6, _Time6] = ScoreList1,
	Chapter = data_story_dun_config:get_chapter_id(DungeonId),
	{Score, Time} = calc_story_score(PlayerId, Chapter),
	
	PlayerScore = 
		case Chapter of
			1 -> [_PlayerId, Score, Time, _Score2, _Time2, _Score3, _Time3, _Score4, _Time4, _Score5, _Time5, _Score6, _Time6];			
			2 -> [_PlayerId, _Score1, _Time1, Score, Time, _Score3, _Time3, _Score4, _Time4, _Score5, _Time5, _Score6, _Time6];
			3 -> [_PlayerId, _Score1, _Time1, _Score2, _Time2, Score, Time, _Score4, _Time4, _Score5, _Time5, _Score6, _Time6];
			4 -> [_PlayerId, _Score1, _Time1, _Score2, _Time2, _Score3, _Time3, Score, Time, _Score5, _Time5, _Score6, _Time6];
			5 -> [_PlayerId, _Score1, _Time1, _Score2, _Time2, _Score3, _Time3, _Score4, _Time4, Score, Time, _Score6, _Time6];
			6 -> [_PlayerId, _Score1, _Time1, _Score2, _Time2, _Score3, _Time3, _Score4, _Time4, _Score5, _Time5, Score, Time];
			_ -> ScoreList1
		end,

	%2.保存数据库和进程字典.
	db:execute(io_lib:format(?sql_replace_story_score, PlayerScore)),
	put("story_total_score", PlayerScore),	
	
	%3.当霸主.
    case finish_chapter(PlayerId, Chapter) of
        true ->
			%3.得到一章的通关记录.
			RecordList = get_record_list(PlayerId, Chapter),
			mod_disperse:cast_to_unite(lib_story_master,
									   set_story_masters,
									   [PlayerId, PlayerName, PlayerSex, PlayerCareer, Chapter, Score, Time, RecordList]);
        false ->
			skip
    end.
	
%% 计算第几章总积分函数.
calc_story_score(PlayerId, Chapter) ->	
	FunCalcScore = 
		fun(DungeonId2, {Score, Time}) ->
			case lib_dungeon_log:get(PlayerId, DungeonId2) of
		        false -> {Score, Time};
		        RD2 -> {Score+RD2#dungeon_log.record_level, Time+RD2#dungeon_log.pass_time}
		    end
		end,
	DungeonIdList = data_story_dun_config:get_chapter_dungeon_list(Chapter),
	lists:foldl(FunCalcScore, {0,0}, DungeonIdList).

%% 是否完成了第几章函数.
finish_chapter(PlayerId, Chapter) ->	
	FunFinishChapter = 
		fun(DungeonId2) ->
			case lib_dungeon_log:get(PlayerId, DungeonId2) of
		        false -> 
					false;
		        RD2 ->
					case RD2#dungeon_log.record_level >= 1 of
				        true ->
							true;
				        false ->
							false
				    end
		    end
		end,
	DungeonIdList = data_story_dun_config:get_chapter_dungeon_list(Chapter),	
	DungeonIdList2 = lists:filter(FunFinishChapter, DungeonIdList),
    ConfLen = length(DungeonIdList),
    FinLen = length(DungeonIdList2),
    case FinLen > 0 andalso ConfLen == FinLen of
        true ->
			true;
        false ->
			false
    end.

%% 得到一章的通关记录.
get_record_list(PlayerId, Chapter) ->
	FunGetRecordList = 
		fun(DungeonId, RecordList) ->
			case lib_dungeon_log:get(PlayerId, DungeonId) of
		        false -> RecordList;
		        Record -> RecordList ++ [{DungeonId,
										  Record#dungeon_log.record_level,
									      Record#dungeon_log.pass_time}]
		    end
		end,
	DungeonIdList = data_story_dun_config:get_chapter_dungeon_list(Chapter),
	lists:foldl(FunGetRecordList, [], DungeonIdList).


%%===============================================大闹天空：封魔录称号属性加成============================================
%% 获取封魔称号信息
get_story_designation(PS)->
    RoleId = PS#player_status.id,
    DunDataPid = PS#player_status.pid_dungeon_data,
    StoryDesignation = get_story_designation_db(RoleId),
    case StoryDesignation of
        [] ->
            %%　默认写死的开始两个称号
            [FDunId, SDunId] = data_story_dun_config:get_config(define_story_dun_id),
            FDun = mod_dungeon_data:get_one_dungeon_log(DunDataPid, RoleId, FDunId),
            SDun = mod_dungeon_data:get_one_dungeon_log(DunDataPid, RoleId, SDunId),
            DunList = dun_log_format([{FDunId, FDun}, {SDunId, SDun}], RoleId, []), 
            story_info_format(DunList, 0);
        [{DesignId, _Content, _EndTime}] ->
            DunId = data_story_dun_config:get_dun_id_by_designation(DesignId),
            FDun = mod_dungeon_data:get_one_dungeon_log(DunDataPid, RoleId, DunId),
            SDun = case DunId =:= lists:last(data_story_dun_config:get_config(dun_list)) of
                        true -> max;
                        false -> mod_dungeon_data:get_one_dungeon_log(DunDataPid, RoleId, DunId+1)
                   end,
            
            DunList = dun_log_format([{DunId, FDun}, {DunId+1, SDun}], RoleId, []), 
            story_info_format(DunList, DunId)
    end.
            
%% 称号信息封装
story_info_format(List, IsOpnDun)->
    Fun = fun({DunId, Name, RecordLevel}) ->
            DesignationId = data_story_dun_config:get_designation_id_by_dun(DunId),
            DesignationRecord = data_designation:get_by_id(DesignationId),
            DunName = pt:write_string(binary_to_list(Name)),
            DesignName = pt:write_string(binary_to_list(DesignationRecord#designation.name)),
            [Hp, Def, Att] = case data_story_attr:get_story_attr(DesignationId) of
                                 [] -> [0, 0, 0];
                                 [{hp, Hp1}, {def, Def1}, {att, Att1}] -> [Hp1, Def1, Att1]
                             end,
            if
                RecordLevel >= 3 ->
                    if
                        IsOpnDun =:= DunId ->
                            IsOpen = 2;
                        IsOpnDun =:= 0 ->
                            IsOpen = 1;
                        true ->
                            IsOpen = 1
                    end;
                true ->
                    IsOpen = 0
            end,
            <<DunId:32, DunName/binary, RecordLevel:8, DesignationId:32, DesignName/binary, Hp:32, Def:32, Att:32, IsOpen:8>>
        end,
    lists:map(Fun, List).
     

%% 激活称号
set_story_designation(PS) ->
    RoleId = PS#player_status.id,
    DunDataPid = PS#player_status.pid_dungeon_data,
    Designation = PS#player_status.designation,
    DisplayDesign = get_story_designation_ps(Designation),  %% 戴在头上的封魔称号
    {NewPS, IsDisplayer} = case DisplayDesign of
                [] -> {PS, 0};
                [{DisDesignId, _DisContent, _DisEndTime1}] ->
                    DisDunId = data_story_dun_config:get_dun_id_by_designation(DisDesignId),
                    case DisDunId =:= lists:last(data_story_dun_config:get_config(dun_list)) of
                        true -> {PS, 0};
                        false ->
                            case lib_designation:set_hide(PS, DisDesignId, inside) of
                                {error, _ErrorCode} -> 
                                    {PS, 0};
                                {ok, NewPS1, _SetType} -> 
                                    {NewPS1, 1}
                            end
                    end
            end,
    StoryDesignation = get_story_designation_db(RoleId),
    case StoryDesignation of
        [] ->
            %%　默认写死的第一个称号激活
            [FDunId, _SDunId] = data_story_dun_config:get_config(define_story_dun_id),
            FDun = mod_dungeon_data:get_one_dungeon_log(DunDataPid, RoleId, FDunId),
            StoryDesign =   case FDun of
                                [] -> skip;
                                false -> skip;
                                FDun ->
                                    case FDun#dungeon_log.record_level >= 3 of
                                        false -> 2;
                                        true ->
                                            activate_fengmo_desigenation(RoleId, FDunId)
                                    end
                            end,
            case StoryDesign of
                2 -> {NewPS, 2};
                4 -> {NewPS, 4};
                skip -> {NewPS, 0};
                {NewDesignId, _NewContent, _NewEndTime} -> {NewPS, NewDesignId, IsDisplayer, 1}
            end;
           
         [{DesignId, _Content, _EndTime}] ->
            DunId = data_story_dun_config:get_dun_id_by_designation(DesignId),
            case DunId =:= lists:last(data_story_dun_config:get_config(dun_list)) of
                true ->
                    {PS, 3};
                false -> 
                    NextDun = mod_dungeon_data:get_one_dungeon_log(DunDataPid, RoleId, DunId+1),
                    StoryDesign = case NextDun of
                                    [] -> skip;
                                    false -> skip;
                                    NextDun ->
                                        case NextDun#dungeon_log.record_level >= 3 of
                                            false -> 2;
                                            true ->
                                                activate_fengmo_desigenation(RoleId, DunId+1)
                                        end
                                  end,
                    case StoryDesign of
                        2 -> {NewPS, 2};
                        4 -> {NewPS, 4};
                        skip -> {NewPS, 0};
                        {NewDesignId, _NewContent, _NewEndTime} -> {NewPS, NewDesignId, IsDisplayer, 1}
                    end
            end
    end.

%% 更新封魔称号的数据
activate_fengmo_desigenation(RoleId, DunId)->
    DesignationId = data_story_dun_config:get_designation_id_by_dun(DunId),
    Designation = data_designation:get_by_id(DesignationId),
    case Designation of
        [] -> 4;
        Designation ->
            lib_designation:bind_design(RoleId, DesignationId, "", 0)
    end.

%% 计算属性封魔加成
count_base_attribute_desigenation(RoleId, _DungeonId, _Designation)->
    StoryDesignation = get_story_designation_db(RoleId), %% 获得玩家拥有的封魔称号
    case StoryDesignation of
        [] ->
            [0, 0, 0];
        [{DesignId, _Content, _EndTime}] ->
            case data_story_attr:get_story_attr(DesignId) of
                [] ->
                    [0, 0, 0];
                [{hp, Hp}, {def, Def}, {att, Att}] ->
                    [Hp, Def, Att]
            end         
    end.


%% 获得玩家拥有的封魔称号 (玩家带有封魔称号)               
get_story_designation_ps(Designation) ->   
    List = lists:map(fun({DesignId, _Content, _EndTime}) ->
                        case data_designation:get_by_id(DesignId) of
                            [] -> {};
                            DesignationRe ->
                                if
                                    DesignationRe#designation.type =:= 5 -> {DesignId, _Content, _EndTime};
                                    true -> {}
                                end
                        end
                     end, Designation),
    [D || D <- List, D=/={}].

%% 5是封魔录称号的类型
get_story_designation_db(RoleId) ->   
    List = lib_designation_ds:get_design_by_role_type(RoleId, 5),
    case List of
        [] -> [];
        [[_RoleId, _DesignType, DesignId]] -> [{DesignId, "", 0}]
    end.




%% 副本日志列表数据组装
dun_log_format([], _RoleId, TempList)->
    lists:reverse(TempList);
dun_log_format([{DunId, DunLog}|T], RoleId, TempList)->
    case DunLog of
        DunLog when is_record(DunLog, dungeon_log) ->
           {RoleId, DunId1} = DunLog#dungeon_log.id,
           Level = DunLog#dungeon_log.record_level,
           Dun = data_dungeon:get(DunId1),
           dun_log_format(T, RoleId, [{DunId1, Dun#dungeon.name, Level}|TempList]);
        max ->
            dun_log_format(T, RoleId, TempList);
        _Other ->
            if
                _Other =:= [] orelse _Other =:= false ->
                    Dun = data_dungeon:get(DunId),
                    case Dun of
                        [] ->
                            dun_log_format(T, RoleId, TempList);
                        Dun ->
                            case Dun#dungeon.type =:= ?DUNGEON_TYPE_STORY of
                                true -> 
                                    SeSQL = io_lib:format(?sql_dungeon_log_sel_type2, [RoleId, DunId]),
                                    DunLog1 = db:get_all(SeSQL),
                                    case DunLog1 of
                                        [] ->
                                            dun_log_format(T, RoleId, [{DunId, Dun#dungeon.name, 0}|TempList]);
                                        [[DunId, Level, _PTime]] ->
                                            dun_log_format(T, RoleId, [{DunId, Dun#dungeon.name, Level}|TempList])
                                    end;
                                _False ->
                                    dun_log_format(T, RoleId, TempList)
                            end
                    end;
                true ->
                    dun_log_format(T, RoleId, TempList)
            end
    end.
                            
                    
%%===============================================大闹天空：封魔录最后杀怪处理============================================  
kill_npc(_NpcIdList, _MonAutoId, _EventSceneId, DunState)->          
    [{PlayerId, _Pid, _DataPid}|_] = [{Role#dungeon_player.id, 
                                       Role#dungeon_player.pid, 
                                       Role#dungeon_player.dungeon_data_pid} || 
                                      Role <- DunState#dungeon_state.role_list],
    case lib_player:get_player_info(PlayerId) of
        PS when is_record(PS, player_status)->
            lib_dungeon:send_dungeon_record(DunState, PS, 7),
            DunState#dungeon_state{is_die = 2};
        %% 不在线
        _Other -> 
            DunState
    end.
    
    

