%%------------------------------------------------------------------------------
%% @Module  : lib_lian_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2013.1.10
%% @Description: 连连看副本逻辑
%%------------------------------------------------------------------------------


-module(lib_lian_dungeon).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("dungeon.hrl").
-include("king_dun.hrl").
-include("lian_dungeon.hrl").
-include("sql_rank.hrl").


%% 公共函数：外部模块调用.
-export([
		 init_create_mon/1,        %% 连连看副本开始刷怪.
		 get_score/1,              %% 连连看副本更新积分.
		 clear_mon/1,              %% 连连看副本清怪.
		 kill_npc/4,               %% 杀死怪物事件.
		 create_scene/2,           %% 创建副本场景.
		 create_mon/3,             %% 创建怪物.
         random_mon/2,             %% 随机创建怪物.
		 set_mon_info/1,           %% 设置怪物信息.
		 calc_score/1,             %% 计算积分.
		 get_lian_state/0,         %% 得到连连看副本状态.
		 set_lian_state/1,         %% 设置连连看副本状态.
		 save_lian_state/2,        %% 保存连连看副本状态.
		 send_score/3,             %% 发送积分和连斩.
	     send_mon_list/1,          %% 发送怪物列表.
         reward_mail/5             %% 邮件奖励.
]).


%% --------------------------------- 公共函数 ----------------------------------


%% 连连看副本开始刷怪.
init_create_mon(DungeonPid) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> DungeonPid ! 'lian_init_create_mon'
    end.

%% 连连看副本更新积分.
get_score(DungeonPid) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> DungeonPid ! 'lian_get_score'
    end.

%% 连连看副本清怪.
clear_mon(DungeonPid) ->
    case is_pid(DungeonPid) of
        false -> false;
        true -> DungeonPid ! 'lian_clear_mon'
    end.

%% 杀怪事件.
kill_npc([_KillMonId|_OtherIdList], MonAutoId, SceneId, State) ->
	LianDunState = get_lian_state(),
	
	%1.得到怪物的位置.
	Position = 
		if 
			MonAutoId == LianDunState#lian_dun_state.a1#lian_dun_mon.auto_id -> 1;
			MonAutoId == LianDunState#lian_dun_state.a2#lian_dun_mon.auto_id -> 2;
			MonAutoId == LianDunState#lian_dun_state.a3#lian_dun_mon.auto_id -> 3;
			MonAutoId == LianDunState#lian_dun_state.b1#lian_dun_mon.auto_id -> 4;
			MonAutoId == LianDunState#lian_dun_state.b2#lian_dun_mon.auto_id -> 5;
			MonAutoId == LianDunState#lian_dun_state.b3#lian_dun_mon.auto_id -> 6;
			MonAutoId == LianDunState#lian_dun_state.c1#lian_dun_mon.auto_id -> 7;
			MonAutoId == LianDunState#lian_dun_state.c2#lian_dun_mon.auto_id -> 8;
			MonAutoId == LianDunState#lian_dun_state.c3#lian_dun_mon.auto_id -> 9;
			true -> 0
		end,

	%2.随机创建一个怪物.
	case Position of
		0 ->
			skip;
		_ ->
			%1.是否为可攻击怪物.
			Mon1 = get_mon(Position),
			AddScore2 = 
				case Mon1#lian_dun_mon.type of
					%1.采集增加时间怪物.
					?LIAN_MON_ADD_TIME ->
						AddTime = data_lian_dungeon:get_config(extan_time),
						set_dungeon_time(State, SceneId, AddTime),
						1;
					
					%2.击杀攻击类型怪物.
					?LIAN_MON_ADD_SCORE ->
						data_lian_dungeon:get_config(add_score);
					_ ->
						1
				end,

			%1.清空连斩.
			save_lian_state(combo, 0),
			%2.增加积分.
			save_lian_state(add_score, AddScore2),
			send_notice(State),
			send_score(State, AddScore2, [Position]),
			RandomTime = data_lian_dungeon:get_config(random_mon_time),
		    _Ref = erlang:send_after(RandomTime, self(), {'lian_dun_random_mon', [Position], SceneId})
	end,
	State.

%% 创建副本场景.
create_scene(SceneId, State) ->	
	%1.修改副本场景ID.
    ChangeSceneId =  
		fun(DunScene) ->
	        case DunScene#dungeon_scene.sid =:= SceneId of
	            true -> 
					DunScene#dungeon_scene{id = SceneId};
	            false -> 
					DunScene
	        end
    	end,
    NewSceneList =  
		[ChangeSceneId(DunScene)|| DunScene<-State#dungeon_state.scene_list],
	
	%2.保存副本等级.
    NewState = State#dungeon_state{scene_list =NewSceneList, level = 1},	
    {SceneId, NewState}.

%% 创建怪物.
create_mon(Type, CopyId, Data) ->
	case Type of
		%1.初始化创建怪物.
		?INIT_CREATE_MON ->
			%1.创建怪物.
			[SceneId] = Data,
			MonList = make_init_mon(),
			NewMonList = create_init_mon(MonList, SceneId, CopyId, []),
			
			%2.保存怪物信息.
			CopyId!{'lian_dun_set_mon_info', NewMonList, false};
		
		%2.随机创建怪物.
		?RANDOM_CREATE_MON ->
			[MonList, SceneId] = Data,
			NewMonList = create_init_mon(MonList, SceneId, CopyId, []),
					
			%保存怪物信息.
			CopyId!{'lian_dun_set_mon_info', NewMonList, true};
	
		%3.删除怪物.
		?DELETE_MON ->
			[MonAutoIdList, SceneId] = Data,
            lib_mon:clear_scene_mon_by_ids(SceneId, [], 1, MonAutoIdList)
	end.

%% 随机创建怪物.
random_mon(SceneId, PositionList) ->
	
	%1.产生第一个怪物.
	MonRate1 = data_lian_dungeon:get_config(mon_rate),
	PositionList2 = util:list_shuffle(PositionList),
	[Position1|PositionList3] = PositionList2,
	Type1 = util:rand(?LIAN_MON_A, ?LIAN_MON_C),
	Type2 = 
		case length(PositionList) of
			1 ->
				MonData = get_mon(Position1),
				NowType = MonData#lian_dun_mon.type,
				case lists:member(NowType, [1,2,3]) of
					true ->
						get_mon_type2(Position1);
					false ->
						get_mon_type1(Type1, MonRate1)
				end;
			_ ->
				get_mon_type1(Type1, MonRate1)
		end,
	Mon1 = [{Position1, Type2}],
		   
	%2.产生其他怪物.
	MonList = 
		case PositionList3 of
			[] ->
				Mon1;
			_PositionList3 ->
				MonRate2 = 
					case lists:member(Type2, [1,2,3]) of
						true ->
							MonRate1;
						false ->
							lists:keydelete(Type2, 1, MonRate1)
					end,

				PositionList4 = make_random_mon(PositionList3, [], MonRate2),
				PositionList4 ++ Mon1
		end,
	
	%3.通知场景所在节点创建随机怪物.		
	CopyId = self(),
	CreateData = [MonList, SceneId],
    
    mod_scene_agent:apply_cast(SceneId, mod_mon_create, create_mon_lian_dungeon, 
        [[?RANDOM_CREATE_MON, CopyId, CreateData]]).

%% 设置怪物信息.
set_mon_info(LianMon) ->
	LianDunState = get_lian_state(),
	LianDunState2 = 
		case LianMon#lian_dun_mon.position of
			1 -> LianDunState#lian_dun_state{a1 = LianMon};
			2 -> LianDunState#lian_dun_state{a2 = LianMon};
			3 -> LianDunState#lian_dun_state{a3 = LianMon};
			4 -> LianDunState#lian_dun_state{b1 = LianMon};
			5 -> LianDunState#lian_dun_state{b2 = LianMon};
			6 -> LianDunState#lian_dun_state{b3 = LianMon};
			7 -> LianDunState#lian_dun_state{c1 = LianMon};
			8 -> LianDunState#lian_dun_state{c2 = LianMon};
			9 -> LianDunState#lian_dun_state{c3 = LianMon};
			_ -> LianDunState
		end,
	set_lian_state(LianDunState2).

%% 计算积分.
calc_score(State) ->
	%1.检测三个相同怪物.
	check_three(),
	
	%2.检测特殊怪物.
	check_special(),

	%3.清除删除的怪物和刷新新的怪物.
	CopyId = self(),
	SceneId = State#dungeon_state.begin_sid,
	LianDunState2 = get_lian_state(),
	DeleteList1 = LianDunState2#lian_dun_state.delete_list1,
	Len = length(DeleteList1),
	case Len of
		0 ->
			skip;
		_ ->
			save_lian_state(add_combo, 1),
			[AddScore, AddTimeCount] = add_score(),
			AddTime = data_lian_dungeon:get_config(extan_time),
			set_dungeon_time(State, SceneId, AddTime*AddTimeCount),
			save_lian_state(add_score, AddScore),
			send_notice(State),
			
			CreateData = [LianDunState2#lian_dun_state.delete_list1, SceneId],
			PositionList = LianDunState2#lian_dun_state.delete_list2,
			send_score(State, AddScore, PositionList),
			save_lian_state(clear_delete_list, []),
	
			%1.删除怪物.
            mod_scene_agent:apply_cast(SceneId, lib_lian_dungeon, create_mon, 
									   [?DELETE_MON, CopyId, CreateData]),
			
			RandomTime = data_lian_dungeon:get_config(random_mon_time),
		    _Ref = erlang:send_after(RandomTime, self(), {'lian_dun_random_mon', PositionList, SceneId})
	end.
	
%% 得到连连看副本状态.
get_lian_state() ->	
    case get("lian_dun_state") of
        undefined ->
			put("lian_dun_state", #lian_dun_state{}),
			get("lian_dun_state");
        State -> 
			State
    end.

%% 设置连连看副本状态.
set_lian_state(LianDunState) ->
	put("lian_dun_state", LianDunState).

%% 保存连连看副本状态.
save_lian_state(Type, Data) ->
	LianDunState = get_lian_state(),
	LianDunState2 = 
		case Type of
			%1.设置连斩.
			combo ->
				LianDunState#lian_dun_state{combo = Data};
			
			%2.增加连斩.
			add_combo ->
				OldCombo = LianDunState#lian_dun_state.combo,
				LianDunState#lian_dun_state{combo = OldCombo + Data};
			
			%3.设置消除怪物列表.
			delete_list ->
				DeletsList1 = LianDunState#lian_dun_state.delete_list1,
				DeletsList2 = LianDunState#lian_dun_state.delete_list2,
				case lists:member(Data#lian_dun_mon.auto_id, DeletsList1) of
					true ->
						LianDunState;
					false ->
						DeleteList12 = DeletsList1 ++ [Data#lian_dun_mon.auto_id],
						DeleteList22 = DeletsList2 ++ [Data#lian_dun_mon.position],
						LianDunState#lian_dun_state{delete_list1 = DeleteList12,
													delete_list2 = DeleteList22}
				end;
			
			%4.清空消除怪物列表.
			clear_delete_list ->
						LianDunState#lian_dun_state{delete_list1 = [],delete_list2 = []};

			%5.增加积分.
			add_score ->
				NewScore = LianDunState#lian_dun_state.score + Data,			
				LianDunState#lian_dun_state{score = NewScore};
			
			%6.设置关闭副本的定时器.
			close_dungeon_timer ->
				LianDunState#lian_dun_state{close_dungeon_timer = Data};

			%7.设置开始的时间.
			begin_time ->
				LianDunState#lian_dun_state{begin_time = Data};

			%8.设置增加的时间.
			extand_time ->
				LianDunState#lian_dun_state{extand_time = Data};

			%9.副本是否开始了.
			is_start ->
				LianDunState#lian_dun_state{is_start = Data};

			%10.发送传闻等级.
			send_tv ->
				LianDunState#lian_dun_state{send_tv = Data};
			
			%11.容错处理.
			_ ->
				LianDunState
		end,
	put("lian_dun_state", LianDunState2).

%% 发送积分和连斩.
send_score(State, Score, PositionList) ->
	LianDunState = get_lian_state(),
	Combo = LianDunState#lian_dun_state.combo,
	TotalScore = LianDunState#lian_dun_state.score,
	
	FunGetPosition = 
		fun(Position) ->
			LianMon = get_mon(Position),
			{X,Y} = data_lian_dungeon:get_mon_position(Position),
			{LianMon#lian_dun_mon.auto_id, X, Y}
		end,
	PositionList2 = [FunGetPosition(Position)|| Position<-PositionList],
	
    {ok, BinData} = pt_610:write(61041, [Score, TotalScore, Combo, PositionList2]),
	RoleList = State#dungeon_state.role_list,
    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData) || Role <- RoleList].

%% 发送怪物列表.
send_mon_list(State) ->
	FunGetMon = 
		fun(LianMon) ->
			LianMon#lian_dun_mon.auto_id
		end,
	LianMonList = get_mon_list(),
	MonList = [FunGetMon(LianMon2)||LianMon2<-LianMonList],

    {ok, BinData} = pt_610:write(61043, MonList),
	RoleList = State#dungeon_state.role_list,
    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData) || Role <- RoleList].

%% 邮件奖励.
reward_mail(DunState, PlayerId, PlayerPid, PlayerLevel, CombatPower) ->
	LianState = get_lian_state(),
	Score = LianState#lian_dun_state.score,
%%     {GoodsId, GoodsNum} = data_lian_dungeon:get_gift(Score),

	%2.发给玩家武魂值.			
	if Score > 0 ->
			gen_server:cast(PlayerPid, {'set_data', [{add_fbpt, Score}]});
	    true ->
			skip
	end,

%%     case GoodsId /= 0 of
%%         true ->
%% 			mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, 
%% 				[[PlayerId], 
%% 				 data_dungeon_text:get_lian_config(title1, []),
%% 				 data_dungeon_text:get_lian_config(content1, [Score]), 
%% 				 GoodsId, 2, 0, 0, GoodsNum, 0, 0, 0, 0]);
%%         false ->
%% 			mod_disperse:cast_to_unite(lib_mail, send_sys_mail,
%% 				[[PlayerId], 
%% 				 data_dungeon_text:get_lian_config(title2, []),
%% 				 data_dungeon_text:get_lian_config(content2, [Score])])
%%     end,
	log(DunState, PlayerId, PlayerLevel, CombatPower, Score, 0).


%% --------------------------------- 私有函数 ----------------------------------


%% 得到怪物列表.
get_mon_list() ->
	LianDunState = get_lian_state(),
	A1 = LianDunState#lian_dun_state.a1, 
	A2 = LianDunState#lian_dun_state.a2, 
	A3 = LianDunState#lian_dun_state.a3,
	B1 = LianDunState#lian_dun_state.b1, 
	B2 = LianDunState#lian_dun_state.b2, 
	B3 = LianDunState#lian_dun_state.b3,
	C1 = LianDunState#lian_dun_state.c1, 
	C2 = LianDunState#lian_dun_state.c2, 
	C3 = LianDunState#lian_dun_state.c3,
	[A1,A2,A3,B1,B2,B3,C1,C2,C3].

%% 得到怪物.
get_mon(Position) ->
	LianDunState = get_lian_state(),
	case Position of
		1 -> LianDunState#lian_dun_state.a1; 
		2 -> LianDunState#lian_dun_state.a2; 
		3 -> LianDunState#lian_dun_state.a3;
		4 -> LianDunState#lian_dun_state.b1; 
		5 -> LianDunState#lian_dun_state.b2; 
		6 -> LianDunState#lian_dun_state.b3;
		7 -> LianDunState#lian_dun_state.c1; 
		8 -> LianDunState#lian_dun_state.c2; 
		9 -> LianDunState#lian_dun_state.c3;
		_ -> #lian_dun_mon{}
	end.

%% 创建初始化怪物.
create_init_mon([], _SceneId, _CopyId, NewMonList) ->
	NewMonList;
create_init_mon([{Position, Type}|_MonList], SceneId, CopyId, NewMonList) ->
	MonId = data_lian_dungeon:get_mon(Type),
	{X, Y} = data_lian_dungeon:get_mon_position(Position),
	AutoId = 
		mod_mon_create:create_mon(MonId, 
									   SceneId, 
									   X, 
									   Y, 
									   0, 
									   CopyId, 
									   1, 
									  [{group, 2}]),
	Mon2 = #lian_dun_mon{auto_id = AutoId, type = Type, position = Position},
	NewMonList1 = NewMonList ++ [Mon2],
	create_init_mon(_MonList, SceneId, CopyId, NewMonList1).

%% 生成初始化怪物列表.
make_init_mon() ->
	%1.随机生成A行怪物.
	A1 = util:rand(1, 3),
	A2 = util:rand(1, 3),
	ListA1 = lists:delete(A1, [1,2,3]),
	ListA2 = lists:delete(A2, ListA1),
	[A3|_SkipA1] = ListA2,

	%2.随机生成B行怪物.
	B1 = util:rand(1, 3),
	B2 = util:rand(1, 3),
	ListB1 = lists:delete(B1, [1,2,3]),
	ListB2 = lists:delete(B2, ListB1),
	[B3|_SkipB1] = ListB2,

	%3.随机生成C行怪物.
	ListC1 = lists:delete(A1, [1,2,3]),
	ListC2 = lists:delete(B1, ListC1),
	[C1|_SkipC1] = ListC2,
	ListC3 = lists:delete(A2, [1,2,3]),
	ListC4 = lists:delete(B2, ListC3),
	[C2|_SkipC2] = ListC4,
	C3 = 
		if 
			((C1==1 andalso C2==1) orelse (A3==1 andalso B3==1)) == false -> 1;
			((C1==2 andalso C2==2) orelse (A3==2 andalso B3==2)) == false -> 2;
			((C1==3 andalso C2==3) orelse (A3==3 andalso B3==3)) == false -> 3;
			true -> 1
		end,
	[{1,A1},{2,A2},{3,A3},{4,B1},{5,B2},{6,B3},{7,C1},{8,C2},{9,C3}].

%% 产生随机怪物列表.
make_random_mon([], MonList, _MonRate) ->
	MonList;
make_random_mon([Position|_PositionList], MonList, MonRate) ->
	Type1 = util:rand(?LIAN_MON_A, ?LIAN_MON_C),
	Type2 = get_mon_type1(Type1, MonRate),
	MonRate2 = 
		case lists:member(Type2, [1,2,3]) of
			true ->
				MonRate;
			false ->
				lists:keydelete(Type2, 1, MonRate)
		end,
	NewMonList = MonList ++ [{Position, Type2}],
	make_random_mon(_PositionList, NewMonList, MonRate2).

%% 获取刷新怪物的类型
get_mon_type1(MonId, MonRate) ->
    %1.总概率.
    F = fun({_, R1}, Sum1) ->
        Sum1 + R1
    end,
    AllRate = lists:foldl(F, 0, MonRate),
    %2.随机刷新.
    M = util:rand(1, AllRate),
    F1 = fun({MonId0, R2}, [Sum2, MonId1]) ->
            case M > Sum2 andalso M =< Sum2 + R2 of
                true ->
                    [Sum2 + R2, MonId0];
                _ ->
                    [Sum2 + R2, MonId1]
            end
    end,
    [_, MonId2] = lists:foldl(F1, [0, 0], MonRate),
    %3.二次修正.
    case MonId2 of
        0 ->
            MonId;
        _ ->
            MonId2
    end.

%% 获取刷新怪物的类型
get_mon_type2(Position) ->
	Mon1 = get_mon(Position),
	Type1 = Mon1#lian_dun_mon.type,
	MonRateList = data_lian_dungeon:get_config(mon_rate2),
	MonRate = lists:keydelete(Type1, 1, MonRateList),

    %1.总概率.
    F = fun({_, R1}, Sum1) ->
        Sum1 + R1
    end,
    AllRate = lists:foldl(F, 0, MonRate),
    %2.随机刷新.
    M = util:rand(1, AllRate),
    F1 = fun({MonId0, R2}, [Sum2, MonId1]) ->
            case M > Sum2 andalso M =< Sum2 + R2 of
                true ->
                    [Sum2 + R2, MonId0];
                _ ->
                    [Sum2 + R2, MonId1]
            end
    end,
    [_, MonId2] = lists:foldl(F1, [0, 0], MonRate),
    %3.二次修正.
    case MonId2 of
        0 ->
            Type1;
        _ ->
            MonId2
    end.

%% 检测三个相同怪物.
check_three() ->
	[A1,A2,A3,B1,B2,B3,C1,C2,C3] = get_mon_list(),
	delete_three(A1, A2, A3),
	delete_three(B1, B2, B3),
	delete_three(C1, C2, C3),
	delete_three(A1, B1, C1),
	delete_three(A2, B2, C2),
	delete_three(A3, B3, C3).

%% 检测特殊怪物.
check_special() ->
	FunCheck = 
		fun(LianMon) ->
			case LianMon#lian_dun_mon.type of
				%1.消除所有怪物.
				?LIAN_MON_DEL_ALL ->
					[A1,A2,A3,B1,B2,B3,C1,C2,C3] = get_mon_list(),
					save_lian_state(delete_list, A1),
					save_lian_state(delete_list, A2),
					save_lian_state(delete_list, A3),
					save_lian_state(delete_list, B1),
					save_lian_state(delete_list, B2),
					save_lian_state(delete_list, B3),
					save_lian_state(delete_list, C1),
					save_lian_state(delete_list, C2),
					save_lian_state(delete_list, C3);
				
				%2.消除一行怪物.
				?LIAN_MON_DEL_ROW ->
					[A1, A2, A3] = data_lian_dungeon:get_row(LianMon#lian_dun_mon.position),
					Mon1 = get_mon(A1),
					Mon2 = get_mon(A2),
					Mon3 = get_mon(A3),
					save_lian_state(delete_list, Mon1),
					save_lian_state(delete_list, Mon2),
					save_lian_state(delete_list, Mon3);
				
				%3.消除一列怪物.
				?LIAN_MON_DEL_COLUMN ->
					[A1, A2, A3] = data_lian_dungeon:get_column(LianMon#lian_dun_mon.position),
					Mon1 = get_mon(A1),
					Mon2 = get_mon(A2),
					Mon3 = get_mon(A3),
					save_lian_state(delete_list, Mon1),
					save_lian_state(delete_list, Mon2),
					save_lian_state(delete_list, Mon3);
				
				%4.消除十字怪物.
				?LIAN_MON_DEL_CROSS ->
					[A1, A2, A3] = data_lian_dungeon:get_row(LianMon#lian_dun_mon.position),
					Mon1 = get_mon(A1),
					Mon2 = get_mon(A2),
					Mon3 = get_mon(A3),
					save_lian_state(delete_list, Mon1),
					save_lian_state(delete_list, Mon2),
					save_lian_state(delete_list, Mon3),
					[B1, B2, B3] = data_lian_dungeon:get_column(LianMon#lian_dun_mon.position),
					Mon4 = get_mon(B1),
					Mon5 = get_mon(B2),
					Mon6 = get_mon(B3),
					save_lian_state(delete_list, Mon4),
					save_lian_state(delete_list, Mon5),
					save_lian_state(delete_list, Mon6);
				
				_ ->
					skip
			end
		end,
	LianMonList = get_mon_list(),
	[FunCheck(LianMon)||LianMon<-LianMonList].

%% 删除三个相同怪物.
delete_three(Mon1, Mon2, Mon3) ->
	if Mon1#lian_dun_mon.type == Mon2#lian_dun_mon.type andalso
	   Mon2#lian_dun_mon.type == Mon3#lian_dun_mon.type ->
		   save_lian_state(delete_list, Mon1),
		   save_lian_state(delete_list, Mon2),
		   save_lian_state(delete_list, Mon3);
	   true ->
		   skip
	end.

%% 设置副本时间
set_dungeon_time(State, SceneId, AddTime) ->
	LianState = get_lian_state(),
	CloseTimer = LianState#lian_dun_state.close_dungeon_timer,
	BeginTime = LianState#lian_dun_state.begin_time,
	ExtandTime = LianState#lian_dun_state.extand_time,
	
	%1.重新算副本的关闭时间.
	erlang:cancel_timer(CloseTimer),
	DungeonData = data_dungeon:get(SceneId),
	ExtandTime2 = ExtandTime + AddTime,
	NewCloseTime = DungeonData#dungeon.time + BeginTime + ExtandTime2 - util:unixtime(),		
	CloseTimer2 = erlang:send_after((NewCloseTime+20)*1000, self(), dungeon_time_end),

	%2.保存数据.
	save_lian_state(close_dungeon_timer, CloseTimer2),
	save_lian_state(extand_time, ExtandTime2),

	%3.发送副本时间.
    {ok, BinData} = pt_610:write(61042, [AddTime, NewCloseTime]),
	RoleList = State#dungeon_state.role_list,
    [lib_server_send:send_to_uid(Role#dungeon_player.id, BinData) || Role <- RoleList].

%% 写日志.
log(DunState, PlayerId, PlayerLevel, CombatPower, Score, GoodsId) ->
	BeginTime = DunState#dungeon_state.time,
	LogoutType = DunState#dungeon_state.logout_type,
	log:log_lian_dungeon(PlayerId, 
						PlayerLevel, 
						Score,
						GoodsId,
						BeginTime,
						LogoutType, 
						CombatPower).

%% 发送副本传闻.
send_notice(State) ->
	LianState = get_lian_state(),
	TotalScore = LianState#lian_dun_state.score,
	SendTV = LianState#lian_dun_state.send_tv,
	FunSend = 
		fun(PlayerId) ->
			%1.检测是否发送传闻.
			IsSend = 
				if 
					TotalScore > 3000 andalso SendTV == 0 ->
						save_lian_state(send_tv, 1),
						{true, 0};
					TotalScore > 4000 andalso SendTV == 1 ->
						save_lian_state(send_tv, 2),
						{true, 1};
					TotalScore > 5000 andalso SendTV == 2 ->
						save_lian_state(send_tv, 3),
						{true, 2};				
					true ->
						false
				end,
			%2.发送传闻.
			case IsSend of
				{true, Level} ->
					case lib_player:get_player_info(PlayerId) of
		                PlayerStatus when is_record(PlayerStatus, player_status)-> 
							lib_chat:send_TV({all},0,2, ["getLLKScore", Level,
										 PlayerStatus#player_status.id,
										 PlayerStatus#player_status.realm,
										 PlayerStatus#player_status.nickname, 
										 PlayerStatus#player_status.sex, 
										 PlayerStatus#player_status.career, 
										 PlayerStatus#player_status.image,
										 TotalScore]);
		            _Other -> 
						skip
		            end;
				false ->
					skip
			end
		end,			
	RoleList = State#dungeon_state.role_list,
    [FunSend(Role#dungeon_player.id) || Role <- RoleList].

%% 增加积分.
add_score() ->
	FunAddScore = 
		fun(Position,[AddScore, AddTimeCount]) ->
			Mon1 = get_mon(Position),
			case Mon1#lian_dun_mon.type of
				%1.采集增加时间怪物.
				?LIAN_MON_ADD_TIME ->
					[AddScore, AddTimeCount+1];
				
				%2.击杀攻击类型怪物.
				?LIAN_MON_ADD_SCORE ->
					Score1 = data_lian_dungeon:get_config(add_score),
					[AddScore+Score1, AddTimeCount];

				_ ->
					[AddScore+5, AddTimeCount]
			end
		end,
	LianState = get_lian_state(),
	PositionList = LianState#lian_dun_state.delete_list2,
	lists:foldl(FunAddScore, [0,0], PositionList).
