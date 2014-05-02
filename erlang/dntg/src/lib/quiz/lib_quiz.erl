%%------------------------------------------------------------------------------
%% @Module  : lib_quiz
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.31
%% @Description: 答题服务逻辑处理
%%------------------------------------------------------------------------------

-module(lib_quiz).
-include("common.hrl").
-include("quiz.hrl").
-include("sql_quiz.hrl").
-include("server.hrl").
-include("unite.hrl").

%% 公共函数：外部模块调用.
-export([
            sign/1,                   %% 报名.
            answer/2,                 %% 答题.
			handle_use_scale/1,       %% 使用放大镜.
			handle_next_start_time/1, %% 下一题开始时间.
            get_sign_status/1,        %% 获得报名状态.
            cmd_start/0               %% 开启答题服务秘籍.

        ]).

%% 内部函数：答题服务本身调用.
-export([
		 start_quiz/0,          %% 开启答题服务秘籍.
         load_quiz/0,           %% 加载答题活动题库.
         load_quiz_base/0,      %% 加载基本题库.
		 load_quiz_other/1,     %% 加载答题主题题库.
         apply_quiz/2,          %% 答题报名.
         answer_quiz_first/4,   %% 答题1.
         answer_quiz/2,         %% 答题插入.
         deduct_magic/3,        %% 道具扣除.
         send_quiz/4,           %% 发题.
         judge_quiz/2,          %% 判题.
         judge/2,               %% 判题.
         normal_answer/3,       %% 普通答题.
         copy_eye_answer/3,     %% 写轮眼作答.
         scale_answer/3,        %% 放大镜作答.
         wrong/1,               %% 错.
         right/4,               %% 对.
         send_result/2,         %% 发送判题结果.
         pack_grade_rank/1,     %% 打包玩家的排行榜.
         get_all_member_id/0,   %% 获取活动玩家ID列表.
         random_quiz/1,         %% 随机题目.
		 random_quiz_other/1,   %% 随机题目（主题题库）. 
         get_score/3,           %% 得到积分.
         get_genius/1,          %% 得到文采.
         get_state_role/2,      %% 得到玩家的报名状态.
         send_to_all/1,         %% 发给全部玩家.
         send_to_uid/2,         %% 发给一个玩家.
         send_to_sign_member/1, %% 发给参加答题的玩家.
		 send_sign_tick/3,      %% 发送报名倒计时.
         send_to_end/0,         %% 发送答题结束..
         rewards_genius_exp/3,  %% 增加文采值.
		 send_award/4,          %% 答题活动结束，发送奖励.
		 rewards_x/1,           %% 奖励系数.
		 use_scale/1,           %% 使用放大镜.
		 next_start_time/1      %% 下一题开始时间.
]).


%% --------------------------------- 公共函数 ----------------------------------


%% 开启答题服务秘籍
cmd_start() ->
    mod_disperse:cast_to_unite(lib_quiz, start_quiz, []).
    
%% 报名
sign(PlayerStatus) ->
    Vip = PlayerStatus#player_status.vip,
    mod_disperse:call_to_unite(lib_quiz, apply_quiz, 
								[[PlayerStatus#player_status.id,
								  PlayerStatus#player_status.dailypid, 
								  PlayerStatus#player_status.nickname, 
								  PlayerStatus#player_status.realm, 
								  PlayerStatus#player_status.lv, 
								  Vip#status_vip.vip_type], 1]).

%% 获得报名状态
%% Return：[答题服务器状态（0关闭，1通告，2报名，3进行），是否报名， 总题数， 
%% 剩余注册时间， 剩余幸运星个数， 属于写轮眼个数， 剩余放大镜数]
get_sign_status(_PlayerStatus) ->
	Vip = _PlayerStatus#player_status.vip,
    mod_disperse:call_to_unite(lib_quiz, get_state_role, 
								[_PlayerStatus#player_status.id, 
								 Vip#status_vip.vip_type]).

%% 答题
answer(PlayerStatus, [Type,Option,_Time,Luck]) ->
    mod_disperse:cast_to_unite(lib_quiz, answer_quiz_first, 
								[PlayerStatus#player_status.id, Type,Option,Luck]).

%% 使用放大镜.
handle_use_scale(PlayerStatus) ->
    mod_disperse:cast_to_unite(lib_quiz, use_scale, 
								[PlayerStatus#player_status.id]).

%% 下一题开始时间.
handle_next_start_time(PlayerStatus) ->
    mod_disperse:cast_to_unite(lib_quiz, next_start_time, 
								[PlayerStatus#player_status.id]).


%% --------------------------------- 内部函数 ----------------------------------


%% 开启答题服务秘籍
start_quiz() ->
    timer_quiz:handle(ok),
    ok.
    
%% 加载答题活动题库
load_quiz() ->
	%1.加载题库.
    case db:get_all(?sql_select_base_subject) of
        {'EXIT', _} ->
            timeout;
        [] ->
            nodata;
        _AllData ->
            F = fun(R) ->
                [_Id,_A,B,_C,_D,_E,_F] = R,
                Id = _Id,
                Content = binary_to_list(_A),
                Correct = B,
                Option1 = binary_to_list(_C),
                Option2 = binary_to_list(_D),
                Option3 = binary_to_list(_E),
                Option4 = binary_to_list(_F),
                ets:insert(?ETS_QUIZ, #ets_quiz{
                                id = Id,
                                content= Content,
                                correct= Correct,
                                option1= Option1,
                                option2= Option2,
                                option3= Option3,
                                option4= Option4})
                end,
            lists:foreach(F, _AllData),
            ok
    end,
    %2.加载特殊题库.
    case db:get_all(?sql_select_base_subject_s) of
        {'EXIT', _} ->
            timeout;
        [] ->
            nodata;
        _AllData1 ->
            F1 = fun(R1) ->
                [_Id1,_A1,B1,_C1,_D1,_E1,_F1] = R1,
                Id1 = _Id1,
                Content1 = binary_to_list(_A1),
                Correct1 = B1,
                Option11 = binary_to_list(_C1),
                Option21 = binary_to_list(_D1),
                Option31 = binary_to_list(_E1),
                Option41 = binary_to_list(_F1),
               ets:insert(?ETS_QUIZ_S, #ets_quiz_s{
                                id = Id1,
                                content= Content1,
                                correct= Correct1,
                                option1= Option11,
                                option2= Option21,
                                option3= Option31,
                                option4= Option41})
                end,
            lists:foreach(F1, _AllData1),
            ok
    end.
    
%% 加载基本题库
load_quiz_base() ->
    case db:get_all(?sql_select_base_subject) of
        {'EXIT', _} ->
            timeout;
        [] ->
            nodata;
        _AllData ->
            F = fun(R) ->
                [_Id, _Content, _Correct, _Option1, _Option2, _Option3, _Option4] = R,
                Id = _Id,
                Content = binary_to_list(_Content),
                Correct = _Correct,
                Option1 = binary_to_list(_Option1),
                Option2 = binary_to_list(_Option2),
                Option3 = binary_to_list(_Option3),
                Option4 = binary_to_list(_Option4),
                ets:insert(?ETS_QUIZ, #ets_quiz{
                                id = Id,
                                content= Content,
                                correct= Correct,
                                option1= Option1,
                                option2= Option2,
                                option3= Option3,
                                option4= Option4})
                end,
            lists:foreach(F, _AllData),
            ok
    end.

%% 加载答题主题题库
load_quiz_other(SubjectType) ->
	%1.加载题库.
	Sql = io_lib:format(?sql_select_base_subject_other, [SubjectType]),    
    case db:get_all(Sql) of
        {'EXIT', _} ->
            timeout;
        [] ->
            nodata;
        _AllData ->
            F = fun(R) ->
                [_Id,_A,B,_C,_D,_E,_F] = R,
                Id = _Id,
                Content = binary_to_list(_A),
                Correct = B,
                Option1 = binary_to_list(_C),
                Option2 = binary_to_list(_D),
                Option3 = binary_to_list(_E),
                Option4 = binary_to_list(_F),
                ets:insert(?ETS_QUIZ_OTHER, #ets_quiz{
                                id = Id,
                                content= Content,
                                correct= Correct,
                                option1= Option1,
                                option2= Option2,
                                option3= Option3,
                                option4= Option4})
                end,
            lists:foreach(F, _AllData),
            ok
    end.

%% 答题报名
%% @ruturn:(0=已经报名，1=报名成功，2=等级不够，3=今天已经过参加答题, 4=答题服务还是开始).
apply_quiz(Data, _State) ->
    [Role_id, DailyPid, Name, Realm, Lv, Vip] = Data,	
    Error = 
	    case ets:lookup(quiz_process, 2) of
	        [_R] ->
				case gen_server:call(_R#quiz_process.pid, {get_state}) of
					{ok, 0} ->
						4;
					_Other ->
						case ets:lookup(?ETS_QUIZ_MEMBER, Role_id) of
							%1.还没报名.
					        [] ->
								Count = mod_daily:get_count(DailyPid, Role_id, 1027),
								if
									%1.当天已经参加答题.
									Count >= 1 ->
										3;
									true ->
									   mod_daily:increment(DailyPid, Role_id, 1027),
							           ets:insert(?ETS_QUIZ_MEMBER, #quiz_member{
							                 role_id = Role_id,
							                 name = Name,
							                 realm = Realm,
							                 lv = Lv,
							                 lucky = 3 + Vip,
							                 copy_eye = 3 + Vip,
							                 scale = 3 + Vip
							            }),
							            1
								end;
							%1.已经报名.
					        _ ->
					            0
						end
				end;
			_ ->
				4
		end,
    {ok, Error, 0, ?QUIZ_TOTAL_SUBJECT}.

%% 答题1
answer_quiz_first(RoleId, Type, Option, Luck) ->
    case ets:lookup(quiz_process, 2) of
        [R] ->
            gen_server:cast(R#quiz_process.pid, {answer, [RoleId, Type, Option, Luck]});
        _ ->
            ok
    end.

%% 答题插入
answer_quiz(Data, Time) ->
    [Role_id, Type, Option, Lucky] = Data,
    case deduct_magic(Role_id, Type, Lucky) of
        true ->
            ets:insert(?ETS_QUIZ_ANSWER, #quiz_answer{role_id = Role_id, 
				type = Type, option = Option, lucky = Lucky, time = Time});
        _ ->
            ets:insert(?ETS_QUIZ_ANSWER, #quiz_answer{role_id = Role_id, 
				type = 0, option = 0, lucky = Lucky, time = Time})
    end,
    Option.

%% 道具扣除
deduct_magic(RoleId, AnswerType, Luck) ->
    case ets:lookup(?ETS_QUIZ_MEMBER, RoleId) of
        [RoleMember] ->
            [Lucky, Copy_eye, Scale] = [RoleMember#quiz_member.lucky, 
										RoleMember#quiz_member.copy_eye, 
										RoleMember#quiz_member.scale],
            case AnswerType of
                %写轮眼
                1 ->
                    case Copy_eye > 0 of
                        true ->
                            ets:insert(?ETS_QUIZ_MEMBER, RoleMember#quiz_member{copy_eye = Copy_eye - 1}),
                            true;
                        _ ->
                            false
                    end;
                %放大镜
                2 ->
                    case Scale > 0 of
                        true ->
                            ets:insert(?ETS_QUIZ_MEMBER, RoleMember#quiz_member{scale = Scale - 1}),
                            true;
                        _ ->
                            false
                    end;
                %普通答题
                _ ->
                    %幸运星答题判断
                    case Luck =:= 1  of
                        true ->
                            case Lucky > 0 of
                                true -> %幸运星足够
                                    ets:insert(?ETS_QUIZ_MEMBER, RoleMember#quiz_member{lucky = Lucky - 1}),
                                    true;
                                _ ->
                                    false
                            end;
                        _ ->
                            true
                    end
            end;
        _ ->
            false
    end.

%% 发题
send_quiz(Turn, AllTurn, Type, SubjectType) ->
	Quiz = 
		if Turn =< 15 ->
		    random_quiz_other(0);
		true ->
			random_quiz(0)
		end,
    {_, _, Content, Correct, Option1, Option2, Option3, Option4} = Quiz,
	Count = 
		if 
			Option3 =:= "" -> 2;
			Option4 =:= "" -> 3;
			true -> 4
		end,
    {ok, BinData} = pt_490:write(49003, [Turn, Content, 
                                         [Option1, Option2, Option3, Option4], 
                                          AllTurn, Type, 
										 SubjectType, data_quiz_text:get_subject_type(SubjectType)]),
	%把题目发给所有人.
	%send_to_all(BinData),
	%把题目发给报名的人.
    send_to_sign_member(BinData),
    {Correct, Count}.


%% 判题
judge_quiz(RightOption, MaxSel) ->
    judge(ets:tab2list(?ETS_QUIZ_MEMBER), [RightOption, MaxSel]).

judge([], _) ->
    ok;
judge([T|H], [RightOption, MaxSel]) ->
    Answer = case ets:lookup(?ETS_QUIZ_ANSWER, T#quiz_member.role_id) of
        [_A] ->
            _A;
        _ ->
            []
    end,
    New_T = case Answer of
        % 弃答
        [] ->
            wrong(T);
        _ ->
            if
                %普通答题.
                Answer#quiz_answer.type =:= 0 ->
                    normal_answer(T, Answer, [RightOption, MaxSel]);
                %写轮眼(火眼金睛).
                Answer#quiz_answer.type =:= 1 ->
                    copy_eye_answer(T, Answer, [RightOption, MaxSel]);
                %放大镜.
                Answer#quiz_answer.type =:= 2 ->
                    scale_answer(T, Answer, [RightOption, MaxSel]);
                true ->
                    wrong(T)
            end
    end,
    ets:insert(?ETS_QUIZ_MEMBER, New_T),
    judge(H, [RightOption, MaxSel]).

%% 普通答题
normal_answer(T, Answer, [RightOption, _MaxSel]) ->
    case Answer#quiz_answer.option =:= RightOption of
        true ->
            AddScore = get_score(Answer#quiz_answer.time, Answer#quiz_answer.lucky, 0),
            AddGunuis = 1 + get_genius(T#quiz_member.continue + 1),
            right(T, AddScore, AddGunuis, RightOption);
        _ ->
            wrong(T)
    end.

%% 写轮眼作答(火眼金睛).
copy_eye_answer(T, Answer, [RightOption, _MaxSel]) ->
%%2012年7月10日策划做了修改：火眼金睛更改为：使用后，可直接选择正确答案.	
%%     case ets:lookup(?ETS_QUIZ_ANSWER, Answer#quiz_answer.option) of
%%         [_A] ->
%%             case _A#quiz_answer.option =:= RightOption of
%%                 true ->
                    AddScore = get_score(Answer#quiz_answer.time, Answer#quiz_answer.lucky, 1),
                    AddGunuis = 1 + get_genius(T#quiz_member.continue + 1),
                    right(T, AddScore, AddGunuis, RightOption).
%%                 _ ->
%%                     wrong(T)
%%             end;
%%         _ ->
%%             wrong(T)
%%     end.

%% 放大镜作答
scale_answer(T, Answer, [RightOption, _MaxSel]) ->
    case Answer#quiz_answer.option =:= RightOption of
        true ->
            AddScore = get_score(Answer#quiz_answer.time, Answer#quiz_answer.lucky, 2),
            AddGunuis = 1 + get_genius(T#quiz_member.continue + 1),
            right(T, AddScore, AddGunuis, RightOption);
        _ ->
            wrong(T)
    end.

%% 错
wrong(T) ->
    NowGenius = case T#quiz_member.genius - 1 < 0 of true -> 0; _ -> T#quiz_member.genius - 1 end,
    T#quiz_member{
     continue = 0,        % 置0
     genius = NowGenius,  % 扣1
     turn_genius = 0,     % 置0
     turn_option = 0
    }.

%% 对
right(T, AddScore, AddGunuis, TurnOption) ->
	Multiple = get("multiple"),
	NowScore = T#quiz_member.score + AddScore,
	NowExp = trunc(T#quiz_member.lv*T#quiz_member.lv*NowScore*2.5*Multiple),

    T#quiz_member{
     score = NowScore,
	 exp = NowExp, 
     continue = T#quiz_member.continue + 1,
     right = T#quiz_member.right + 1,
     genius = T#quiz_member.genius + AddGunuis,
     turn_genius = AddGunuis,
     turn_option = TurnOption
    }.

%% 发送判题结果
send_result([OP1, OP2, OP3, OP4], Correct) ->
	%1.获取答题的玩家.
    TempRank = ets:tab2list(?ETS_QUIZ_MEMBER),
	%2.排名.
    Fun = 
		fun(A, B) ->
        	A#quiz_member.score > B#quiz_member.score
    	end,
    Rank = lists:sort(Fun, TempRank),
	%3.得到前10名的玩家的排行榜.
    RankBin = pack_grade_rank(lists:sublist(Rank, 1, 10)),
	%4.发送给参加答题的玩家.
    F = 
		fun(Member, R) ->
	        Result = 
				case Member#quiz_member.turn_option =:= Correct of
		            true -> 1;
		            false -> 0
	        	end,
	        RoleId = Member#quiz_member.role_id,
	        ScaleNum = Member#quiz_member.scale,
	        CopyEyeNum = Member#quiz_member.copy_eye,
	        LuckNum = Member#quiz_member.lucky,
	        Continue = Member#quiz_member.continue,
	        Score = Member#quiz_member.score,
	        Genius = Member#quiz_member.genius,
	        TurnGenius = Member#quiz_member.turn_genius,
			Exp = Member#quiz_member.exp,
	        {ok,Bindata} = pt_490:write(49005, [Result, OP1, OP2, OP3, OP4, 
												ScaleNum, CopyEyeNum, LuckNum, 
												Continue, Score, R, Genius ,
												TurnGenius, Exp, Correct, RankBin]),
	        send_to_uid(RoleId, Bindata),
	        R + 1
    	end,
    lists:foldl(F, 1, Rank),
    ok.

%% 打包玩家的排行榜.
pack_grade_rank(RankList) ->
    Fun = fun(Elem) ->
        RoleId   = Elem#quiz_member.role_id,
        RoleName = list_to_binary(Elem#quiz_member.name),
        Realm    = Elem#quiz_member.realm,
        Grade    = Elem#quiz_member.score,
		Exp      = Elem#quiz_member.exp,
        NL = byte_size(RoleName),
        <<RoleId:32, NL:16, RoleName/binary, Realm:8, Grade:16, Exp:32>>
    end,
    BinList = list_to_binary([Fun(X) || X <- RankList]),
    Size  = length(RankList),
    <<Size:16, BinList/binary>>.
    
%% 获取活动玩家ID列表
get_all_member_id() ->
    ets:match(?ETS_QUIZ_MEMBER, #quiz_member{role_id = '$1', _ = '_'}).

%% 随机题目
random_quiz(_Max) ->
    List = ets:tab2list(?ETS_QUIZ),
    Max = length(List),
    M = util:rand(1, Max),
    case Max =< 30 of
        true ->
            load_quiz_base(),
            {1, 1, "竞技场可以获得？", 1, "A.积分", "B.美女", "C.帅哥", ""};
        _ ->
            lists:nth(M, List)
    end.

%% 随机题目（主题题库）
random_quiz_other(_Max) ->
    List = ets:tab2list(?ETS_QUIZ_OTHER),
    Max = length(List),
    M = util:rand(1, Max),
    case Max < 30 of
        true ->
            load_quiz_base(),
            {1, 1, "竞技场可以获得？", 1, "A.积分", "B.美女", "C.帅哥", ""};
        _ ->
            Subject = lists:nth(M, List),			
			ets:delete(?ETS_QUIZ_OTHER, Subject#ets_quiz.id),
			Subject
    end.

%% 得到积分.
get_score(Time, Lucky, Type) ->
    BaseScore = case Type =/= 0 of
        true ->
            5;
        false ->
            case Time of
                0 -> 15;
                1 -> 13;
                2 -> 10;
                3 -> 8;
                4 -> 7;
                5 -> 6;
                6 -> 5;
                7 -> 4;
                8 -> 3;
                Other ->
                    case Other >= 9 andalso Other =< 14 of
                        true ->
                            1;
                        false ->
                            0
                    end
            end
    end,
    case Lucky =:= 1 of
        true ->
            BaseScore * 2;
        false ->
            BaseScore
    end.


%% 得到积分.
get_genius(Continue) ->
    case Continue of
        3 ->
            1;
        10 ->
            2;
        20 ->
            4;
        30 ->
            8;
        _Other ->
            0
    end.

%% [答题服务器状态（0关闭，1通告，2报名，3进行），
%% 是否报名， 
%% 总题数， 
%% 剩余注册时间， 
%% 剩余幸运星个数， 
%% 属于写轮眼个数， 
%% 剩余放大镜数]
get_state_role(RoleId, _Vip) ->
    Date = case ets:lookup(?ETS_QUIZ_MEMBER, RoleId) of
        [RoleMember] ->
            [1, 1, ?QUIZ_TOTAL_SUBJECT, 0, 
			 RoleMember#quiz_member.lucky, 
			 RoleMember#quiz_member.copy_eye, 
			 RoleMember#quiz_member.scale];
        _ ->
			%%因为现在取消报名机制，所以查询到没有报名，要返回全部的道具数3给玩家..
            [1, 0, ?QUIZ_TOTAL_SUBJECT, 0, 0, 0, 0] %原来的返回
		    %[1, 1, ?QUIZ_TOTAL_SUBJECT, 0, 3+Vip, 3+Vip, 3+Vip]  %现在的返回
    end,
    {ok, Date}.


%% 发给全部玩家.
send_to_all(Bin) ->
    %lib_unite_send:send_to_unite_all(Bin).
	lib_unite_send:send_to_all(?QUIZ_START_LEVEL, 999, Bin).

%% 发给一个玩家.
send_to_uid(Id, Bin) ->
    lib_unite_send:send_to_uid(Id, Bin).

%% 发给参加答题的玩家.
send_to_sign_member(Bin) ->
	 Members = get_all_member_id(),     
	 Fun = 
		 fun([Id]) ->
	     	send_to_uid(Id,Bin)
	     end,
	 catch lists:foreach(Fun, Members),
	 ok.

%% 发送报名倒计时
send_sign_tick(Time, _Flag, SubjectType) ->    
	Subject = data_quiz_text:get_subject_type(SubjectType),
	if 
		%1.答题未开始.
		Time > ?QUIZ_TOTAL_ANSWER_TIME ->
		    {ok, BinData} = pt_490:write(49002, [Time-?QUIZ_TOTAL_ANSWER_TIME, 
												 0, SubjectType, Subject, Time]),
		    send_to_all(BinData),
			timer:sleep(5000),
			send_sign_tick(Time - 5, 0, SubjectType);
		
		%2.已经开始答题（答题最后一分钟不发报名了）.
		Time > 0 ->
			{ok, BinData} = pt_490:write(49002, [0, 1, SubjectType, Subject, Time]),
			send_to_all(BinData),
			timer:sleep(5000),
			send_sign_tick(Time - 5, 1, SubjectType);
		
		%3.答题结束.
		true ->
			ok
	end.

%% 发送答题结束.
send_to_end() ->
    {ok, BinData} = pt_490:write(49006, no),
    send_to_all(BinData).

%% 增加文采值
rewards_genius_exp(Id, Genius, Exp) ->
    case mod_chat_agent:lookup(Id) of
        [] ->
			%% 处理离线玩家答题活跃度
			catch lib_active:handle_offline(Id, 4),
            ok;
        [Player] ->
            lib_player:add_genius_by_id(Player#ets_unite.id, Genius, Exp),
			%% 活跃度：参与智力答题
			lib_player_unite:trigger_active(Id, [Id, 4, 0]),
			ok
    end.

%% 答题活动结束，发送奖励
send_award([],_,_,_) ->
    ok;
send_award([H|T], Rank, _Type, Multiple) ->
    %1.增加经验
    X = rewards_x(Rank),
    GetExp1 = trunc(H#quiz_member.lv*H#quiz_member.lv*H#quiz_member.score*X),
	
	%2.计算活动的倍数.
	GetExp = trunc(GetExp1*Multiple),
	
    %3.增加文采值
    _GetGenius = H#quiz_member.genius,
    rewards_genius_exp(H#quiz_member.role_id, _GetGenius, GetExp),
	
    %4.发送弹窗消息
    RanSend = Rank,
    ExpSend = GetExp,
    GenSend = H#quiz_member.score,
    {ok, BinData} = pt_490:write(49008, [RanSend, GenSend, ExpSend]),
    send_to_uid(H#quiz_member.role_id, BinData),
	
	%5.发放活动礼包.
	activity_rewsrds(H#quiz_member.role_id, Rank),
	
	%6.答题日志
	log:log_quiz(H#quiz_member.role_id, RanSend, GenSend, ExpSend),
    send_award(T, Rank+1, _Type, Multiple).

%%奖励系数
rewards_x(Rank) ->
    case Rank of
        1 ->
            1.5;
        2 ->
            1.4;
        3 ->
            1.3;
        4 ->
            1.2;
        5 ->
            1.2;
        6 ->
            1.1;
        7 ->
            1.1;
        8 ->
            1.1;
        9 ->
            1.1;
        10 ->
            1.1;
        _ ->
            1
    end.


%% 发放活动礼包.
activity_rewsrds(PlayerId, Rank) ->
	%1.得到礼包ID.
	GoodsId = 
		case data_activity_time:get_activity_time(5) of
			true ->
				if
					Rank =:= 1 ->
						534009;
					Rank =:= 2 ->
						534010;
					Rank =:= 3 ->
						534011;
					Rank >= 4 andalso Rank =< 6 ->
						534012;
					Rank >= 7 andalso Rank =< 10 ->
						534013;
					true -> 
						false
				end;
			false ->
				false
		end,
	
	%2.发送邮件.
	if GoodsId =:= false ->
		   skip;
	   true ->
		   lib_mail:send_sys_mail_bg([PlayerId], 
									 data_quiz:get_quiz_config(title1),
									 data_quiz:get_quiz_config(content1), 
									 GoodsId, 2, 0, 0, 1, 0, 0, 0, 0)
	end.

%% 使用放大镜.
use_scale(RoleId) ->
    case ets:lookup(quiz_process, 2) of
        [R] ->
            gen_server:call(R#quiz_process.pid, {use_scale, RoleId});
        _ ->
            ok
    end.

%% 下一题开始时间.
next_start_time(PlayerId) ->
    case ets:lookup(quiz_process, 2) of
        [R] ->
            gen_server:cast(R#quiz_process.pid, {next_start_time, PlayerId});
        _ ->
            ok
    end.
